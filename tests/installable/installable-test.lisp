(defpackage #:cl-stack-systems-installable
  (:use #:cl #:rove))

(in-package #:cl-stack-systems-installable)

;;; One row per import: (system smoke-form). SMOKE runs after
;;; (asdf:load-system SYSTEM) in the child image; T means "loads" is the check.
;;;   alexandria  control: an import that works today
;;;   jose        #75: cl-json and assoc-utils were missing, so sync failed
;;;   cl-json, assoc-utils  #75: the two imports jose needs
;;;   the rest    #76: libraries python-to-cl recommends, not in cl-systems

(defun cl-repo-available-p ()
  (ignore-errors
   (plusp (length (uiop:run-program '("sh" "-c" "command -v cl-repo")
                                    :output :string)))))

(defun output-tail (output)
  (let* ((lines (remove "" (uiop:split-string output :separator '(#\Newline))
                        :test #'string=))
         (keep (remove-if-not (lambda (l)
                                (or (search "Error" l) (search "not in the registry" l)
                                    (search "not found in any registry" l)))
                              lines)))
    (format nil "~{~a~^ | ~}" (last (or keep lines) 3))))

(defun check-import (system smoke)
  "`cl-repo sbcl` in a fresh project depending on SYSTEM: sync, load, SMOKE.
   → (values ok-p exit-code output-tail)"
  (let ((dir (uiop:ensure-directory-pathname
              (merge-pathnames (format nil "cl-stack-systems-installable/~a/" system)
                               (uiop:temporary-directory)))))
    (uiop:delete-directory-tree dir :validate t :if-does-not-exist :ignore)
    (ensure-directories-exist dir)
    (with-open-file (s (merge-pathnames "installable-check.asd" dir)
                       :direction :output :if-exists :supersede)
      (format s "(defsystem \"installable-check\" :depends-on (~s))~%" system))
    (multiple-value-bind (out err code)
        (uiop:run-program (list "cl-repo" "sbcl" "--non-interactive"
                                "--eval" (format nil "(asdf:load-system ~s)" system)
                                "--eval" smoke
                                "--eval" "(format t \"~&IMPORT-OK~%\")")
                          :directory dir :input nil
                          :output :string :error-output :output
                          :ignore-error-status t)
      (declare (ignore err))
      (values (and (eql code 0) (search "IMPORT-OK" out) t)
              code
              (output-tail out)))))

(deftest-parametrize import-installs-and-loads
    ((system smoke)
     :ids ("alexandria" "jose" "cl-json" "assoc-utils"
           "lparallel" "cl-csv" "3bmd" "cl-redis" "opticl" "function-cache" "cl-smtp"
           "cl-pdf" "cl-typesetting" "cl-excel" "legit" "machine-state" "lquery" "clss"
           "check-it" "parcom" "cl-progress-bar")
     ("alexandria" "(assert (equal (alexandria:flatten '(1 (2))) '(1 2)))")
     ;; #75, from the jose README: HS256 round trip.
     ("jose" "(let* ((key (ironclad:ascii-string-to-byte-array \"my$ecret\")) (token (jose:encode :hs256 key '((\"hello\" . \"world\"))))) (assert (equal (jose:decode :hs256 key token) '((\"hello\" . \"world\")))))")
     ;; #75: jose's two missing dependencies on their own.
     ("cl-json" "(assert (string= (cl-json:encode-json-to-string '((:a . 1))) \"{\\\"a\\\":1}\"))")
     ("assoc-utils" "(assert (equal 1 (assoc-utils:aget '((\"a\" . 1)) \"a\")))")
     ;; #76, first tier.
     ("lparallel" "(let ((lparallel:*kernel* (lparallel:make-kernel 2))) (unwind-protect (assert (equal (lparallel:pmap 'list #'1+ '(1 2 3)) '(2 3 4))) (lparallel:end-kernel :wait t)))")
     ("cl-csv" "(assert (equal (cl-csv:read-csv (format nil \"a,b~%1,2~%\")) '((\"a\" \"b\") (\"1\" \"2\"))))")
     ("3bmd" "(assert (search \"<h1>\" (with-output-to-string (s) (3bmd:parse-string-and-print-to-stream \"# hi\" s))))")
     ("cl-redis" "t")
     ("opticl" "(let ((img (opticl:make-8-bit-gray-image 2 2 :initial-element 7))) (assert (= 7 (aref img 1 1))))")
     ("function-cache" "(progn (function-cache:defcached cached-square (x) (* x x)) (assert (= 9 (cached-square 3))) (assert (= 9 (cached-square 3))))")
     ("cl-smtp" "t")
     ("cl-pdf" "t")
     ("cl-typesetting" "t")
     ("cl-excel" "t")
     ("legit" "t")
     ("machine-state" "(assert (plusp (machine-state:machine-cores)))")
     ("lquery" "(assert (equal '(\"hi\") (coerce (lquery:$ (initialize (plump:parse \"<p class=a>hi</p>\")) \"p.a\" (text)) 'list)))")
     ("clss" "(assert (= 1 (length (clss:select \"p\" (plump:parse \"<p>x</p>\")))))")
     ("check-it" "(assert (integerp (check-it:generate (check-it:generator (integer)))))")
     ("parcom" "(assert (equal \"a\" (parcom:parse (parcom:char #\\a) \"a\")))")
     ("cl-progress-bar" "t"))
  (if (not (cl-repo-available-p))
      (skip "cl-repo is not on PATH")
      (multiple-value-bind (ok-p code tail) (check-import system smoke)
        (ok ok-p (format nil "~a: cl-repo sbcl exit ~a~@[: ~a~]"
                         system code (and (not ok-p) tail))))))
