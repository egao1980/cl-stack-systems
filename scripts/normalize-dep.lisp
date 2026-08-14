;;;; Shared by publish-import.lisp and test-normalize-dep.lisp.
;;;; OCI depends-on is install metadata for every consumer OS — keep
;;;; (:feature EXPR DEP) regardless of the publish host's *features*.

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
     (normalize-dep* (third dep)))
    ((and (consp dep) (eq (first dep) :require))
     nil)
    ((consp dep)
     (normalize-dep* (or (find-if #'stringp dep)
                         (find-if (lambda (x) (and (symbolp x) x (not (keywordp x)))) dep)
                         (third dep)
                         (second dep))))
    (t nil)))
