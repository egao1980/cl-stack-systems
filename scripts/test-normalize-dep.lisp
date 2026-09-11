;;;; sbcl --script scripts/test-normalize-dep.lisp
(require :asdf)
(load (merge-pathnames "normalize-dep.lisp" *load-pathname*))

(defun check (label got expected)
  (unless (equal got expected)
    (error "~a: got ~s expected ~s" label got expected))
  (format t "ok ~a~%" label))

(check "string" (normalize-dep* "Alexandria") "alexandria")
(check "symbol" (normalize-dep* :cffi) "cffi")
(check "version" (normalize-dep* '(:version "uiop" "3.1.1")) '("uiop" . "3.1.1"))
(check "windows feature" (normalize-dep* '(:feature :windows "winhttp")) "winhttp")
(check "not-windows feature" (normalize-dep* '(:feature (:not :windows) "cl+ssl")) "cl+ssl")
(check "or-feature" (normalize-dep* '(:feature (:or :win32 :windows) "winhttp")) "winhttp")
(check "and-not-ssl" (normalize-dep* '(:feature (:and (:not :windows) (:not :dexador-no-ssl)) "cl+ssl"))
      "cl+ssl")
(check "windows flexi" (normalize-dep* '(:feature :windows "flexi-streams")) "flexi-streams")
(check "require dropped" (normalize-dep* '(:require :sb-posix)) nil)
(check "usocket-iolib dropped" (normalize-dep* '(:feature :usocket-iolib :iolib)) nil)
(check "iolib name dropped" (normalize-dep* :iolib) nil)
(check "sb-bsd-sockets dropped"
       (normalize-dep* '(:feature (:and (:or :sbcl :ecl :clasp) (:not :usocket-iolib))
                         :sb-bsd-sockets))
       nil)

(let* ((dexador-deps
        '("fast-http" "quri" "fast-io" "babel" "trivial-gray-streams" "trivial-garbage"
          "chunga" "cl-ppcre" "cl-cookie" "trivial-mimes" "chipz" "cl-base64" "usocket"
          (:feature :windows "winhttp")
          (:feature :windows "flexi-streams")
          (:feature (:and (:not :windows) (:not :dexador-no-ssl)) "cl+ssl")
          "bordeaux-threads" "alexandria" (:version "uiop" "3.1.1")))
       (flat (remove nil (mapcar #'normalize-dep* dexador-deps)))
       (names (mapcar (lambda (d) (if (consp d) (car d) d)) flat)))
  (check "dexador keeps winhttp" (and (member "winhttp" names :test #'string=) t) t)
  (check "dexador keeps flexi-streams" (and (member "flexi-streams" names :test #'string=) t) t)
  (check "dexador keeps cl+ssl" (and (member "cl+ssl" names :test #'string=) t) t))

(format t "~&All normalize-dep* tests passed.~%")
(uiop:quit 0)
