;;; Publish source-only OCI packages for one imports/*/qlfile.
;;; Env:
;;;   PKG_QLFILE        path to qlfile (required)
;;;   PKG_SYSTEM        ASDF system to publish (default: import dir name,
;;;                     or contents of sibling `system` file)
;;;   OCI_REGISTRY      default ghcr.io
;;;   OCI_NAMESPACE     default egao1980/cl-systems
;;;   GITHUB_ACTOR / GITHUB_TOKEN
;;;   SKIP_CATALOG      default true
;;;   PUBLISH_QL_DEPS   default false — ql-export unresolved deps
;;;   DEPS_DIST_URL     Quicklisp dist URL for ql-export fallback

(require :asdf)
(asdf:initialize-source-registry
 '(:source-registry
   (:tree (:home ".local/share/cl-systems/"))
   :inherit-configuration))
(load (merge-pathnames "quicklisp/setup.lisp" (user-homedir-pathname)))
(ql:quickload '(:cl-repository-packager :cl-oci-client) :silent t)

(defun env (name &optional default)
  (or (uiop:getenv name) default))

;;; Packager 0.16.0 workarounds:
;;; - discover-provided-systems uses *read-eval* nil → #. in .asd yields no systems
;;; - resolve-system-name errors even when PKG_SYSTEM is explicit
;;; OCI depends-on is install metadata for every consumer OS. Do NOT filter
;;; (:feature …) against the *publish host* *features* — Linux CI would drop
;;; (:feature :windows "winhttp") from dexador (and keep Linux-only cl+ssl).
(load (merge-pathnames "normalize-dep.lisp" (or *load-pathname* *compile-file-pathname*)))

(setf (fdefinition 'cl-repository-packager/asdf-plugin:normalize-dep)
      #'normalize-dep*)

(defun asd-prelude-form-p (form)
  "Forms that must be EVALed before later #. reader macros in the same .asd
   (e.g. Postmodern cl-postgres.asd: defparameter *string-file* then #.*string-file*)."
  (and (consp form)
       (symbolp (first form))
       (member (symbol-name (first form))
               '("DEFPACKAGE" "IN-PACKAGE" "DEFPARAMETER" "DEFVAR" "DEFCONSTANT"
                 "DEFUN" "DEFMACRO" "EVAL-WHEN" "SETF" "SETQ" "PSETF" "PSETQ"
                 "PROGN" "LET" "LET*" "LOCALLY")
               :test #'string-equal)))

(defun discover-provided-systems* (source-dir)
  "Like packager discover, but allow #. in .asd (split-sequence, clingon, …).
   Bind *LOAD-PATHNAME* / *LOAD-TRUENAME* so #.(uiop:read-file-string
   (uiop:subpathname *load-pathname* …)) works when READ-ing the .asd.
   Also EVAL prelude forms so Postmodern-style `#.*string-file*` works."
  (let ((names nil)
        (*read-eval* t)
        (*package* (find-package :cl-user)))
    (dolist (asd-path (directory (merge-pathnames "*.asd"
                                                  (uiop:ensure-directory-pathname source-dir))))
      (handler-case
          (with-open-file (s asd-path :direction :input :if-does-not-exist nil)
            (when s
              (let* ((truename (ignore-errors (truename asd-path)))
                     (*load-pathname* asd-path)
                     (*load-truename* (or truename asd-path)))
                (loop for form = (read s nil :eof)
                      until (eq form :eof)
                      do (cond
                           ((and (listp form)
                                 (symbolp (first form))
                                 (string-equal "DEFSYSTEM" (symbol-name (first form)))
                                 (second form))
                            (let ((name (etypecase (second form)
                                          (string (second form))
                                          (symbol (string-downcase (symbol-name (second form)))))))
                              (pushnew name names :test #'string=)))
                           ((asd-prelude-form-p form)
                            (eval form)))))))
        (error () nil)))
    (nreverse names)))

(setf (fdefinition 'cl-repository-packager/asdf-plugin:discover-provided-systems)
      #'discover-provided-systems*)

(defun resolve-system-name* (source-dir explicit-system-name)
  (let ((systems (discover-provided-systems* source-dir)))
    (cond
      (explicit-system-name
       (unless (or (null systems)
                   (member explicit-system-name systems :test #'string=))
         (error "Requested system ~a not found. Available systems: ~{~a~^, ~}"
                explicit-system-name systems))
       explicit-system-name)
      ((null systems)
       (error "No .asd systems found in source directory: ~a" source-dir))
      ((= (length systems) 1)
       (first systems))
      (t
       (error "Multiple systems found (~{~a~^, ~}). Please pass --system." systems)))))

(setf (fdefinition 'cl-repository-packager/source-adapter::resolve-system-name)
      #'resolve-system-name*)

(defun oci-annotation-string (value)
  "OCI annotation values MUST be strings (GHCR → MANIFEST_INVALID otherwise).
   ASDF :author can be a list (esrap); coerce + collapse whitespace."
  (cond
    ((null value) nil)
    ((stringp value)
     (let ((s (string-trim '(#\Space #\Tab #\Newline #\Return) value)))
       (when (plusp (length s))
         (with-output-to-string (out)
           (loop for c across s
                 do (write-char (if (member c '(#\Newline #\Return #\Tab)) #\Space c)
                                out))))))
    ((and (consp value) (every #'stringp value))
     (oci-annotation-string (format nil "~{~a~^, ~}" value)))
    (t (oci-annotation-string (princ-to-string value)))))

(defun test-system-name-p (name)
  "Skip *-test(s) / */test(s) provides — GHCR nested paths like esrap/tests are hostile."
  (let ((n (string-downcase (string name))))
    (or (search "/test" n)
        (search "-test" n)
        (search ".test" n))))

(defun bm-sym (name)
  "Internal build-matrix symbol (author/make-annotations not always exported in 0.12.0)."
  (or (find-symbol name :cl-repository-packager/build-matrix)
      (error "missing build-matrix symbol ~a" name)))

(defun bm-slot (spec slot-name)
  (slot-value spec (bm-sym slot-name)))

(defun (setf bm-slot) (value spec slot-name)
  (setf (slot-value spec (bm-sym slot-name)) value))

(defun make-annotations* (spec)
  "Like packager make-annotations, but stringify author/description (OCI requires strings)."
  (setf (bm-slot spec "AUTHOR") (oci-annotation-string (bm-slot spec "AUTHOR")))
  (setf (bm-slot spec "DESCRIPTION") (oci-annotation-string (bm-slot spec "DESCRIPTION")))
  (let ((provides (bm-slot spec "PROVIDES")))
    (when provides
      (setf (bm-slot spec "PROVIDES") (remove-if #'test-system-name-p provides))))
  (funcall (get 'make-annotations* 'orig) spec))

(let ((make-ann (bm-sym "MAKE-ANNOTATIONS")))
  (setf (get 'make-annotations* 'orig) (fdefinition make-ann))
  (setf (fdefinition make-ann) #'make-annotations*))

(defun manual-package-spec (system-name source-dir)
  "Fallback when auto-package-spec still fails (complex .asd metadata)."
  (let* ((system (asdf:find-system system-name nil))
         (deps (when system
                 (remove nil (mapcar #'normalize-dep*
                                     (asdf:system-depends-on system)))))
         (provides (or (discover-provided-systems* source-dir)
                       (list system-name))))
    (make-instance 'cl-repository-packager/build-matrix:package-spec
      :name system-name
      :version (or (and system (asdf:component-version system)) "latest")
      :source-dir (uiop:ensure-directory-pathname source-dir)
      :license (ignore-errors (asdf:system-licence system))
      :description (ignore-errors (asdf:system-description system))
      :author (let ((a (ignore-errors (asdf:system-author system))))
                (typecase a
                  (string a)
                  (cons (format nil "~{~a~^, ~}" a))
                  (t nil)))
      :depends-on deps
      :provides provides)))

(let ((orig (fdefinition 'cl-repository-packager/asdf-plugin:auto-package-spec)))
  (setf (fdefinition 'cl-repository-packager/asdf-plugin:auto-package-spec)
        (lambda (system-name)
          (handler-case
              (let ((spec (funcall orig system-name)))
                (setf (cl-repository-packager/build-matrix:package-spec-depends-on spec)
                      (remove nil (cl-repository-packager/build-matrix:package-spec-depends-on spec)))
                spec)
            (error (e)
              (format t "~&auto-package-spec failed (~a); using manual fallback~%" e)
              (manual-package-spec
               system-name
               (asdf:system-source-directory (asdf:find-system system-name))))))))

(defun strip-comment (line)
  (let ((pos (position #\# line)))
    (if pos (subseq line 0 pos) line)))

(defun whitespace-char-p (c)
  (member c '(#\Space #\Tab #\Newline #\Return)))

(defun split-ws (s)
  (loop for start = 0 then (position-if-not #'whitespace-char-p s :start end)
        while start
        for end = (or (position-if #'whitespace-char-p s :start start) (length s))
        collect (subseq s start end)
        while (< end (length s))))

(defun parse-qlfile (path)
  (with-open-file (in path :direction :input)
    (loop for line = (read-line in nil nil)
          while line
          for content = (string-trim '(#\Space #\Tab #\Newline #\Return)
                                     (strip-comment line))
          when (> (length content) 0)
            collect (let* ((tokens (split-ws content))
                           (kind (string-downcase (first tokens))))
                      (list :kind kind
                            :name (second tokens)
                            :ref (third tokens)
                            :raw content)))))

(defun make-registry (registry-host)
  (let* ((registry-url (if (string= registry-host "ghcr.io")
                           (format nil "https://~a" registry-host)
                           (format nil "http://~a" registry-host)))
         (auth (cl-oci-client/auth:make-auth-config
                :username (env "GITHUB_ACTOR")
                :password (env "GITHUB_TOKEN"))))
    (values (cl-oci-client/registry:make-registry registry-url :auth auth)
            registry-url)))

(defun oci-safe-name (name)
  "GHCR paths cannot contain '+'; map cl+ssl → cl-plus-ssl."
  (with-output-to-string (out)
    (loop for c across name
          do (if (char= c #\+)
                 (write-string "-plus-" out)
                 (write-char c out)))))

(defvar *oci-package-name* nil
  "Preferred OCI package name (import directory), overriding ASDF system name.")

(defun ensure-oci-safe-spec (spec)
  "Use import-dir / sanitized name for OCI; drop '+' from provide aliases."
  (let* ((orig (cl-repository-packager/build-matrix:package-spec-name spec))
         (safe (or *oci-package-name* (oci-safe-name orig)))
         (provides (cl-repository-packager/build-matrix:package-spec-provides spec)))
    (setf (cl-repository-packager/build-matrix:package-spec-name spec) safe)
    ;; Alias pushes also hit GHCR paths — never leave '+' in provide names.
    (setf (cl-repository-packager/build-matrix:package-spec-provides spec)
          (remove-duplicates
           (mapcar #'oci-safe-name (append (list orig safe) provides))
           :test #'string=))
    spec))

(defun pin-as-oci-version (ref)
  "Map qlfile/git pin to a consumer-friendly OCI tag.
   v0.24.1 → 0.24.1; bare semver kept; branch/SHA pins → NIL (use ASDF/revision)."
  (cond
    ((null ref) nil)
    ((zerop (length ref)) nil)
    ((and (>= (length ref) 2)
          (char-equal (char ref 0) #\v)
          (digit-char-p (char ref 1)))
     (subseq ref 1))
    ((and (digit-char-p (char ref 0))
          (every (lambda (c) (or (digit-char-p c) (char= c #\.))) ref)
          (find #\. ref))
     ref)
    (t nil)))

(defun sibling-version-file (qlfile)
  "Optional imports/<name>/version — force the package version (tag, tarball
   prefix, annotations) when .asd omits or lags :version."
  (let ((path (merge-pathnames "version" (uiop:pathname-directory-pathname qlfile))))
    (when (probe-file path)
      (let ((v (string-trim '(#\Space #\Tab #\Newline #\Return)
                            (uiop:read-file-string path))))
        (when (plusp (length v)) v)))))

(defun apply-oci-version (spec &key pin env-version version-file)
  "Prefer PKG_VERSION, then imports/*/version, then version-looking qlfile pin,
   else leave packager default. Needed for systems like cffi that omit :version."
  (let ((ver (or env-version version-file (pin-as-oci-version pin))))
    (when ver
      (format t "~&; oci: forcing package version ~a (was ~a / rev ~a)~%"
              ver
              (cl-repository-packager/build-matrix:package-spec-version spec)
              (cl-repository-packager/build-matrix:package-spec-revision spec))
      (setf (cl-repository-packager/build-matrix:package-spec-version spec) ver)))
  spec)

(defun ensure-dependencies-published* (spec registry-host namespace
                                       &key publish-ql-deps deps-dist-url skip-catalog)
  "Retry dependency visibility (parallel matrix races), then warn-and-continue.
   Consumers may QL-fallback unpublished leftovers; STRICT_DEPS=true re-signals."
  (let* ((attempts (max 1 (or (parse-integer (or (env "DEP_ENSURE_ATTEMPTS") "8")
                                            :junk-allowed t)
                              8)))
         (strict (string-equal "true" (env "STRICT_DEPS" "false")))
         (last-error nil))
    (dotimes (i attempts)
      (handler-case
          (progn
            (cl-repository-packager/source-adapter:ensure-dependencies-published
             spec registry-host namespace
             :publish-missing nil
             :recursive nil
             :publish-ql-dependencies publish-ql-deps
             :deps-dist-url deps-dist-url
             :skip-catalog skip-catalog)
            (return-from ensure-dependencies-published* t))
        (error (e)
          (setf last-error e)
          (format t "~&; deps ensure attempt ~a/~a failed: ~a~%"
                  (1+ i) attempts e)
          (unless (= (1+ i) attempts)
            (sleep (* 10 (1+ i)))))))
    (when strict
      (error last-error))
    (format t "~&; WARNING: proceeding with unpublished deps (~a). ~
Consumers may QL-fallback until those imports land.~%"
            last-error)
    nil))

(defun publish-built (reg namespace skip-catalog publish-ql-deps deps-dist-url
                      registry-host spec result)
  (ensure-oci-safe-spec spec)
  (let ((tag (or (cl-repository-packager/build-matrix:package-spec-version spec)
                 (cl-repository-packager/build-matrix:package-spec-revision spec)
                 "latest")))
    (ensure-dependencies-published*
     spec registry-host namespace
     :publish-ql-deps publish-ql-deps
     :deps-dist-url deps-dist-url
     :skip-catalog skip-catalog)
    (let* ((attempts (max 1 (or (parse-integer (or (env "PUBLISH_ATTEMPTS") "5")
                                              :junk-allowed t)
                                5)))
           (last-error nil))
      (dotimes (i attempts)
        (handler-case
            (progn
              (cl-repository-packager/publisher:publish-package
               reg namespace tag result spec :skip-catalog skip-catalog)
              (setf last-error nil)
              (return))
          (error (e)
            (setf last-error e)
            (format t "~&; publish attempt ~a/~a failed: ~a~%" (1+ i) attempts e)
            (unless (= (1+ i) attempts)
              (sleep (* 15 (1+ i)))))))
      (when last-error (error last-error)))
    (format t "~&Published ~a/~a/~a:~a (provides ~{~a~^, ~})~%"
            registry-host namespace
            (cl-repository-packager/build-matrix:package-spec-name spec)
            tag
            (cl-repository-packager/build-matrix:package-spec-provides spec))))

(defun resolve-pkg-system (qlfile)
  "ASDF system name: PKG_SYSTEM, else sibling `system` file, else import dir name."
  (or (env "PKG_SYSTEM")
      (let ((system-file (merge-pathnames "system" (uiop:pathname-directory-pathname qlfile))))
        (when (probe-file system-file)
          (string-trim '(#\Space #\Tab #\Newline #\Return)
                       (uiop:read-file-string system-file))))
      (let* ((dir (uiop:pathname-directory-pathname qlfile))
             (name (first (last (pathname-directory dir)))))
        (when (stringp name) name))))

(defun provided-system-p (name provided)
  (member (string-downcase (string name)) provided :test #'string=))

(defun flatten-external-depends-on (root-name provided)
  "Walk ASDF depends-on from ROOT-NAME. Recurse into PROVIDED (same-tarball
   secondaries such as http2/client); collect everything else. Without this,
   auto-package-spec on an umbrella system advertises secondaries as if they
   were registry packages."
  (let ((provided (mapcar (lambda (s) (string-downcase (string s))) provided))
        (seen (make-hash-table :test #'equal))
        (out nil))
    (labels ((walk (name)
               (let ((key (string-downcase (string name))))
                 (when (gethash key seen)
                   (return-from walk))
                 (setf (gethash key seen) t)
                 (let ((sys (asdf:find-system key nil)))
                   (unless sys
                     (return-from walk))
                   (dolist (raw (asdf:system-depends-on sys))
                     (let ((norm (normalize-dep* raw)))
                       (when norm
                         (let ((dn (if (consp norm) (car norm) norm)))
                           (if (provided-system-p dn provided)
                               (walk dn)
                               (pushnew norm out :test #'equal))))))))))
      (walk root-name)
      (nreverse out))))

(defun rewrite-same-tarball-depends (spec source-dir resolved)
  "Replace umbrella → secondary depends-on with flattened external deps."
  (let* ((provides (or (cl-repository-packager/build-matrix:package-spec-provides spec)
                       (discover-provided-systems* source-dir)
                       (list resolved)))
         (external (flatten-external-depends-on resolved provides)))
    (when (or external
              (find-if (lambda (dep)
                         (let ((n (if (consp dep) (car dep) dep)))
                           (and n (provided-system-p n provides))))
                       (cl-repository-packager/build-matrix:package-spec-depends-on spec)))
      (format t "~&; oci: flattened depends-on → ~s~%" external)
      (setf (cl-repository-packager/build-matrix:package-spec-depends-on spec) external)))
  spec)

(defun build-spec-from-source (source-dir system-name source-url revision)
  "Spec only — then APPLY-OCI-VERSION + BUILD-PACKAGE.
   Packager ≥0.16.0 also accepts `:version` on BUILD-PACKAGE-FROM-SOURCE;
   we still split here so PKG_VERSION / imports/*/version / pin coalesce
   via APPLY-OCI-VERSION before the build (same fix as cl-stack#174)."
  (let ((resolved (cl-repository-packager/source-adapter::resolve-system-name
                   source-dir system-name)))
    (asdf:initialize-source-registry
     `(:source-registry (:tree ,(namestring source-dir)) :inherit-configuration))
    (asdf:clear-system resolved)
    (let ((spec (cl-repository-packager/asdf-plugin:auto-package-spec resolved)))
      (rewrite-same-tarball-depends spec source-dir resolved)
      (setf (cl-repository-packager/build-matrix:package-spec-source-url spec) source-url)
      (setf (cl-repository-packager/build-matrix:package-spec-revision spec) revision)
      spec)))

(defun publish-entry-from-source (reg namespace skip-catalog publish-ql-deps deps-dist-url
                                  registry-host source-dir revision
                                  &key system-name source-url pin version-file)
  (let ((spec (build-spec-from-source source-dir system-name source-url revision)))
    (apply-oci-version spec :pin pin :env-version (env "PKG_VERSION")
                       :version-file version-file)
    (publish-built reg namespace skip-catalog publish-ql-deps deps-dist-url
                   registry-host spec
                   (cl-repository-packager/build-matrix:build-package spec))))

(defun publish-github-entry (reg namespace skip-catalog publish-ql-deps deps-dist-url
                             registry-host name ref system-name &key version-file)
  (let ((repo-url (cl-repository-packager/source-adapter:github-repo-url name)))
    (multiple-value-bind (source-dir revision cleanup-fn)
        (cl-repository-packager/source-adapter:clone-git-source repo-url :ref ref)
      (unwind-protect
           (publish-entry-from-source
            reg namespace skip-catalog publish-ql-deps deps-dist-url
            registry-host source-dir revision
            :system-name system-name
            :source-url (format nil "https://github.com/~a"
                                (cl-repository-packager/source-adapter:normalize-github-repo name))
            :pin ref :version-file version-file)
        (when cleanup-fn (funcall cleanup-fn))))))

(defun publish-git-entry (reg namespace skip-catalog publish-ql-deps deps-dist-url
                          registry-host url ref system-name &key version-file)
  (multiple-value-bind (source-dir revision cleanup-fn)
      (cl-repository-packager/source-adapter:clone-git-source url :ref ref)
    (unwind-protect
         (publish-entry-from-source
          reg namespace skip-catalog publish-ql-deps deps-dist-url
          registry-host source-dir revision
          :system-name system-name :source-url url
          :pin ref :version-file version-file)
      (when cleanup-fn (funcall cleanup-fn)))))

(let* ((qlfile (env "PKG_QLFILE"))
       (registry (env "OCI_REGISTRY" "ghcr.io"))
       (namespace (string-downcase (env "OCI_NAMESPACE" "egao1980/cl-systems")))
       (skip-catalog (string-equal "true" (env "SKIP_CATALOG" "true")))
       (publish-ql-deps (string-equal "true" (env "PUBLISH_QL_DEPS" "false")))
       (deps-dist-url (env "DEPS_DIST_URL"
                           "https://beta.quicklisp.org/dist/quicklisp.txt")))
  (unless (and qlfile (probe-file qlfile))
    (error "PKG_QLFILE missing or not found: ~a" qlfile))
  (let* ((system-name (resolve-pkg-system qlfile))
         (version-file (sibling-version-file qlfile))
         (*oci-package-name*
          (or (env "PKG_OCI_NAME")
              (let* ((dir (uiop:pathname-directory-pathname qlfile))
                     (name (first (last (pathname-directory dir)))))
                (when (stringp name) name)))))
    (when publish-ql-deps
      (ql:quickload :cl-repository-ql-exporter :silent t))
    (multiple-value-bind (reg registry-url)
        (make-registry registry)
      (declare (ignore registry-url))
      (format t "~%Publishing import from ~a (system=~a oci=~a) → ~a/~a~%"
              qlfile system-name *oci-package-name* registry namespace)
      (let ((entries (parse-qlfile qlfile))
            (published 0))
        (when (null entries)
          (error "No entries in ~a" qlfile))
        (dolist (entry entries)
          (let ((kind (getf entry :kind))
                (name (getf entry :name))
                (ref (getf entry :ref)))
            (cond
              ((string= kind "github")
               (publish-github-entry reg namespace skip-catalog publish-ql-deps
                                     deps-dist-url registry name ref system-name
                                     :version-file version-file)
               (incf published))
              ((string= kind "git")
               (publish-git-entry reg namespace skip-catalog publish-ql-deps
                                  deps-dist-url registry name ref system-name
                                  :version-file version-file)
               (incf published))
              ((string= kind "ql")
               (format t "~&Skipping ql entry (expect already in registry): ~a~%"
                       (getf entry :raw)))
              (t
               (format t "~&Warning: unsupported entry: ~a~%" (getf entry :raw))))))
        (when (zerop published)
          (error "No github/git entries published from ~a" qlfile))
        (format t "~&Done: ~d package~:p from ~a~%" published qlfile)))))
