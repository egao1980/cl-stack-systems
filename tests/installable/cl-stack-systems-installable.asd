;;; Run from this directory: cl-repo test
;;; Each test makes a fresh cl-repo project that depends on one import and
;;; runs `cl-repo sbcl` in it (sync from ghcr.io/egao1980/cl-systems, load,
;;; smoke form). Needs cl-repo on PATH and network access to GHCR.
(defsystem "cl-stack-systems-installable"
  :description "Rove checks that cl-systems imports install and load through cl-repo"
  :license "MIT"
  :depends-on ("rove")
  :components ((:file "installable-test"))
  :perform (test-op (o c)
             (unless (symbol-call :rove :run c)
               (error "tests failed for ~A" (component-name c)))))
