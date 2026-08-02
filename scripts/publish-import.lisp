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

(defun publish-built (reg namespace skip-catalog publish-ql-deps deps-dist-url
                      registry-host spec result)
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
    (format t "~&Published ~a/~a/~a:~a~%"
            registry-host namespace
            (cl-repository-packager/build-matrix:package-spec-name spec)
            tag)))

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
