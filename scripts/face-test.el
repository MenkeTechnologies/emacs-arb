;;; face-test.el --- Assert arb-mode font-lock faces -*- lexical-binding: t; -*-

;; Loads arb-mode, fontifies a sample, and asserts the face applied at the
;; first occurrence of each probe token. Run:
;;   emacs --batch -L . -l scripts/face-test.el

;;; Code:

(require 'arb-mode)

(defvar arb-face-test--sample
  (concat
   "# cpu dashboard\n"
   "text  .t -label \"cpu\"\n"
   "gauge .g -max 100\n"
   "source .t { in.json | field status | where(is5xx) | tally }\n"
   "source .g { in | match /ERROR/ | count }\n"
   "fn pct(v, m): v / m * 100\n"
   "out { field code | grep /^5/ }\n"
   "bind q quit\n")
  "A small but representative arb spec exercising each highlight category.")

(defun arb-face-test--face-of (token)
  "Return the face text-property at the start of the first whole-symbol TOKEN.
Case-sensitive and symbol-bounded so e.g. \"in\" does not match \"field\"."
  (goto-char (point-min))
  (let ((case-fold-search nil))
    (if (re-search-forward (concat "\\_<" (regexp-quote token) "\\_>") nil t)
        (let ((face (get-text-property (match-beginning 0) 'face)))
          (if (listp face) (car face) face))
      'NOT-FOUND)))

(defun arb-face-test--face-at (regexp)
  "Return the face at the start of the first match of REGEXP, or NOT-FOUND."
  (goto-char (point-min))
  (if (re-search-forward regexp nil t)
      (let ((face (get-text-property (match-beginning 0) 'face)))
        (if (listp face) (car face) face))
    'NOT-FOUND))

(let ((checks
       '(("text"    . arb-widget-face)
         ("gauge"   . arb-widget-face)
         ("source"  . font-lock-keyword-face)
         ("out"     . font-lock-keyword-face)
         ("bind"    . font-lock-keyword-face)
         ("fn"      . font-lock-keyword-face)
         ("where"   . font-lock-builtin-face)
         ("field"   . font-lock-builtin-face)
         ("tally"   . font-lock-builtin-face)
         ("count"   . font-lock-builtin-face)
         ("quit"    . font-lock-type-face)
         ("pct"     . font-lock-function-name-face)))
      (failed 0))
  (with-temp-buffer
    (insert arb-face-test--sample)
    (arb-mode)
    (font-lock-ensure)
    (dolist (probe checks)
      (let* ((token (car probe))
             (want (cdr probe))
             (got (arb-face-test--face-of token))
             (ok (eq got want)))
        (unless ok (setq failed (1+ failed)))
        (princ (format "%s  %-10s want=%-28s got=%s\n"
                       (if ok "PASS" "FAIL") token want got))))
    ;; Input source: in.json -> type face.
    (let ((got (arb-face-test--face-at "in\\.json")) (want 'font-lock-type-face))
      (unless (eq got want) (setq failed (1+ failed)))
      (princ (format "%s  %-10s want=%-28s got=%s\n"
                     (if (eq got want) "PASS" "FAIL") "in.json" want got)))
    ;; Widget path: .t -> widget-path face.
    (let ((got (arb-face-test--face-at "\\.t\\b")) (want 'arb-widget-path-face))
      (unless (eq got want) (setq failed (1+ failed)))
      (princ (format "%s  %-10s want=%-28s got=%s\n"
                     (if (eq got want) "PASS" "FAIL") "<path .t>" want got)))
    ;; Option flag: -label -> flag face.
    (let ((got (arb-face-test--face-at "-label")) (want 'arb-flag-face))
      (unless (eq got want) (setq failed (1+ failed)))
      (princ (format "%s  %-10s want=%-28s got=%s\n"
                     (if (eq got want) "PASS" "FAIL") "-label" want got)))
    ;; Double-quoted string.
    (let ((got (arb-face-test--face-at "\"cpu\"")) (want 'font-lock-string-face))
      (unless (eq got want) (setq failed (1+ failed)))
      (princ (format "%s  %-10s want=%-28s got=%s\n"
                     (if (eq got want) "PASS" "FAIL") "<string>" want got)))
    ;; Comment.
    (let ((got (arb-face-test--face-at "dashboard")) (want 'font-lock-comment-face))
      (unless (eq got want) (setq failed (1+ failed)))
      (princ (format "%s  %-10s want=%-28s got=%s\n"
                     (if (eq got want) "PASS" "FAIL") "<comment>" want got))))
  (princ (if (zerop failed) "\nALL FACE CHECKS PASSED\n" (format "\n%d CHECK(S) FAILED\n" failed)))
  (kill-emacs (if (zerop failed) 0 1)))

;;; face-test.el ends here
