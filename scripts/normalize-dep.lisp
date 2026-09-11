;;;; Shared by publish-import.lisp and test-normalize-dep.lisp.
;;;; OCI depends-on is install metadata for every consumer OS — keep
;;;; (:feature EXPR DEP) when EXPR mentions a platform/impl, regardless of
;;;; the publish host's *features* (so Linux CI still records winhttp).
;;;; Drop opt-in backend flags (:usocket-iolib) and impl contribs that are
;;;; never on ghcr.io/egao1980/cl-systems (iolib, sb-bsd-sockets).

(defparameter *platform-features*
  '(:windows :win32 :unix :linux :darwin :bsd :macos :os-windows
    :sbcl :ecl :ccl :clozure :abcl :clisp :allegro :cormanlisp :lispworks
    :cmu :cmucl :scl :mcl :mocl :genera :mezzano :clasp :openmcl))

(defparameter *non-oci-deps*
  '("iolib" "sb-bsd-sockets" "sb-posix" "sb-rotate-byte" "sb-introspect" "sb-cltl2"))

(defun feature-expr-platform-p (expr)
  (cond
    ((and (symbolp expr) (member expr *platform-features* :test #'string-equal)) t)
    ((and (consp expr) (member (first expr) '(:and :or :not) :test #'eq))
     (some #'feature-expr-platform-p (rest expr)))
    (t nil)))

(defun drop-non-oci (normalized)
  (let ((name (if (consp normalized) (car normalized) normalized)))
    (when (and name (not (member name *non-oci-deps* :test #'string-equal)))
      normalized)))

(defun normalize-dep* (dep)
  (drop-non-oci
   (cond
     ((null dep) nil)
     ((stringp dep) (string-downcase dep))
     ((and (symbolp dep) (not (null dep)))
      (string-downcase (symbol-name dep)))
     ((and (consp dep) (eq (first dep) :version) (>= (length dep) 3))
      (let ((name (normalize-dep* (second dep))))
        (when name
          (if (consp name)
              name
              (cons name (string (third dep)))))))
     ((and (consp dep) (eq (first dep) :feature) (>= (length dep) 3))
      (when (feature-expr-platform-p (second dep))
        (normalize-dep* (third dep))))
     ((and (consp dep) (eq (first dep) :require))
      nil)
     ((consp dep)
      (normalize-dep* (or (find-if #'stringp dep)
                          (find-if (lambda (x) (and (symbolp x) x (not (keywordp x)))) dep)
                          (third dep)
                          (second dep))))
     (t nil))))
