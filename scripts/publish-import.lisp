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

;;; Packager 0.8.0 workarounds (until newer packager OCI tag):
;;; - normalize-dep crashes on (:feature (:and …) dep)
;;; - discover-provided-systems uses *read-eval* nil → #. in .asd yields no systems
;;; - resolve-system-name errors even when PKG_SYSTEM is explicit

(defun feature-expr-p (expr)
  (cond
    ((null expr) t)
    ((eq expr t) t)
    ((symbolp expr) (and (member expr *features* :test #'eq) t))
    ((and (consp expr) (eq (first expr) :and))
     (every #'feature-expr-p (rest expr)))
    ((and (consp expr) (eq (first expr) :or))
     (some #'feature-expr-p (rest expr)))
    ((and (consp expr) (eq (first expr) :not) (rest expr))
     (not (feature-expr-p (second expr))))
    (t nil)))

(defun normalize-dep* (dep)
  (cond
    ((null dep) nil)
    ((stringp dep) (string-downcase dep))
    ((and (symbolp dep) (not (null dep)))
     (string-downcase (symbol-name dep)))
    ((and (consp dep) (eq (first dep) :version) (>= (length dep) 3))
     (let ((name (normalize-dep* (second dep))))
       (when name (cons name (string (third dep))))))
    ((and (consp dep) (eq (first dep) :feature) (>= (length dep) 3))
     (when (feature-expr-p (second dep))
       (normalize-dep* (third dep))))
    ((and (consp dep) (member (first dep) '(:require :feature) :test #'eq))
     nil)
    ((consp dep)
     (normalize-dep* (or (find-if #'stringp dep)
                         (find-if (lambda (x) (and (symbolp x) x (not (keywordp x)))) dep)
                         (third dep)
                         (second dep))))
    (t nil)))

(setf (fdefinition 'cl-repository-packager/asdf-plugin:normalize-dep)
      #'normalize-dep*)

(defun discover-provided-systems* (source-dir)
  "Like packager discover, but allow #. in .asd (split-sequence etc.)."
  (let ((names nil)
        (*read-eval* t)
        (*package* (find-package :cl-user)))
    (dolist (asd-path (directory (merge-pathnames "*.asd"
                                                  (uiop:ensure-directory-pathname source-dir))))
      (handler-case
          (with-open-file (s asd-path :direction :input :if-does-not-exist nil)
            (when s
              (loop for form = (read s nil :eof)
                    until (eq form :eof)
                    when (and (listp form)
                              (symbolp (first form))
                              (string-equal "DEFSYSTEM" (symbol-name (first form)))
                              (second form))
                      do (let ((name (etypecase (second form)
                                       (string (second form))
                                       (symbol (string-downcase (symbol-name (second form)))))))
                           (pushnew name names :test #'string=)))))
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

(defun publish-built (reg namespace skip-catalog publish-ql-deps deps-dist-url
                      registry-host spec result)
  (ensure-oci-safe-spec spec)
  (let ((tag (or (cl-repository-packager/build-matrix:package-spec-version spec)
                 (cl-repository-packager/build-matrix:package-spec-revision spec)
                 "latest")))
    (cl-repository-packager/source-adapter:ensure-dependencies-published
     spec registry-host namespace
     :publish-missing nil
     :recursive nil
     :publish-ql-dependencies publish-ql-deps
     :deps-dist-url deps-dist-url
     :skip-catalog skip-catalog)
    (cl-repository-packager/publisher:publish-package
     reg namespace tag result spec :skip-catalog skip-catalog)
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

(defun publish-github-entry (reg namespace skip-catalog publish-ql-deps deps-dist-url
                             registry-host name ref system-name)
  (multiple-value-bind (spec result cleanup-fn)
      (cl-repository-packager/source-adapter:build-package-from-github
       name :ref ref :system-name system-name)
    (unwind-protect
         (publish-built reg namespace skip-catalog publish-ql-deps deps-dist-url
                        registry-host spec result)
      (when cleanup-fn (funcall cleanup-fn)))))

(defun publish-git-entry (reg namespace skip-catalog publish-ql-deps deps-dist-url
                          registry-host url ref system-name)
  (multiple-value-bind (source-dir revision cleanup-fn)
      (cl-repository-packager/source-adapter:clone-git-source url :ref ref)
    (unwind-protect
         (multiple-value-bind (spec result)
             (cl-repository-packager/source-adapter:build-package-from-source
              source-dir :system-name system-name
                         :source-url url :revision revision)
           (publish-built reg namespace skip-catalog publish-ql-deps deps-dist-url
                          registry-host spec result))
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
  (let ((system-name (resolve-pkg-system qlfile)))
    (when publish-ql-deps
      (ql:quickload :cl-repository-ql-exporter :silent t))
    (multiple-value-bind (reg registry-url)
        (make-registry registry)
      (declare (ignore registry-url))
      (format t "~%Publishing import from ~a (system=~a) → ~a/~a~%"
              qlfile system-name registry namespace)
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
                                     deps-dist-url registry name ref system-name)
               (incf published))
              ((string= kind "git")
               (publish-git-entry reg namespace skip-catalog publish-ql-deps
                                  deps-dist-url registry name ref system-name)
               (incf published))
              ((string= kind "ql")
               (format t "~&Skipping ql entry (expect already in registry): ~a~%"
                       (getf entry :raw)))
              (t
               (format t "~&Warning: unsupported entry: ~a~%" (getf entry :raw))))))
        (when (zerop published)
          (error "No github/git entries published from ~a" qlfile))
        (format t "~&Done: ~d package~:p from ~a~%" published qlfile)))))
