;;; arb-mode.el --- Major mode for the arb language (arb) -*- lexical-binding: t; -*-

;; Copyright (c) 2026 MenkeTechnologies

;; Author: MenkeTechnologies
;; URL: https://github.com/MenkeTechnologies/emacs-arb
;; Version: 0.1.0
;; Package-Requires: ((emacs "27.1"))
;; Keywords: languages, arb

;; This file is not part of GNU Emacs.

;;; Commentary:

;; A major mode for arb, the pipe-native TUI/web dashboard language on
;; fusevm/JIT: pipe a stream in and arb builds a dynamic ratatui TUI or a
;; served web page from a declarative, Tcl/Tk-flavored spec.  It is a
;; jq/xpath/css/yq superset with a uniform query over any format.  This mode
;; targets the `arb' binary and provides:
;;
;;   - filetype detection for `*.arb' files and arb shebangs
;;   - syntax highlighting: keywords, input sources, directives, widget
;;     verbs, 154 query verbs, widget paths (.a.b.c), `-flags',
;;     /regex/ literals, single- and double-quoted strings, numbers,
;;     `#' comments
;;   - brace-aware indentation
;;   - run the buffer through `arb' (`arb-run-buffer', C-c C-c)
;;   - language-server integration via `arb --lsp' (eglot + lsp-mode)
;;   - eldoc + completion-at-point for arb query verbs and widgets
;;
;; arb's builtin surface (inputs, directives, widgets, and query verbs) is
;; small and fixed by the language, so the keyword lists are plain
;; `regexp-opt' lists in this file.  Verb / widget signatures used for eldoc
;; and completion live in `arb-stdlib.el'.

;;; Code:

(require 'arb-stdlib)

;; Optional integrations — referenced only inside `with-eval-after-load' blocks,
;; declared here so the byte-compiler stays quiet when they are absent.
(defvar eglot-server-programs)
(defvar lsp-language-id-configuration)
(declare-function make-lsp-client "lsp-mode")
(declare-function lsp-register-client "lsp-mode")
(declare-function lsp-stdio-connection "lsp-mode")
(declare-function lsp-activate-on "lsp-mode")

(defgroup arb nil
  "Major mode for the arb language (arb)."
  :group 'languages
  :prefix "arb-")

(defcustom arb-executable "arb"
  "Path to the arb executable, used to run buffers and for the language server."
  :type 'string
  :group 'arb)

(defcustom arb-indent-offset 4
  "Number of spaces per indentation level in `arb-mode'."
  :type 'integer
  :group 'arb)

(defface arb-widget-face
  '((t :inherit font-lock-builtin-face :weight bold))
  "Face for arb widget verbs (text, table, gauge, bars, ...)."
  :group 'arb)

(defface arb-widget-path-face
  '((t :inherit font-lock-variable-name-face :weight bold))
  "Face for arb widget/control paths (.a, .a.b.c, ...)."
  :group 'arb)

(defface arb-flag-face
  '((t :inherit font-lock-constant-face))
  "Face for arb option flags (-label, -max, -cols, ...)."
  :group 'arb)

;;; Keyword categories.  arb's surface is small, so plain `regexp-opt'
;;; lists are well under Emacs' regexp-size limit.

(defconst arb--keywords
  '("fn" "var" "let" "if" "elif" "else" "for" "while" "match" "case"
    "when" "return" "break" "continue" "do" "and" "or" "not" "in"
    "import" "save" "as" "spawn" "send" "out" "every"
    "true" "false" "nil")
  "arb keywords, declarators, and value constants.")

(defconst arb--directives
  '("source" "bind" "configure" "grid" "import" "out" "search"
    "timeout" "expect")
  "arb top-level directives.")

(defconst arb--widgets
  '("text" "tail" "table" "list" "gauge" "spark" "bars" "histo" "chart"
    "select" "input" "tabs" "block" "frame" "grid" "slider" "check"
    "facet" "filter")
  "arb widget verbs (the \"Tk\" register).")

(defconst arb--actions
  '("alert" "beep" "exec" "flash" "quit" "set")
  "arb trigger actions.")

(defconst arb--verbs
  arb-builtin-function-names
  "arb query-pipeline verbs (from `arb-stdlib').")

;;; Font-lock.

(defconst arb-font-lock-keywords
  `(;; Input sources: in.json in.csv ... (bare `in' is covered by keywords).
    ("\\_<in\\.[a-z]+" . font-lock-type-face)
    ;; Keywords, declarators, and constants.
    (,(regexp-opt arb--keywords 'symbols) . font-lock-keyword-face)
    ;; Directives (source / bind / grid / out / ...).
    (,(regexp-opt arb--directives 'symbols) . font-lock-keyword-face)
    ;; Widget verbs (own bold face).
    (,(regexp-opt arb--widgets 'symbols) . 'arb-widget-face)
    ;; Trigger actions.
    (,(regexp-opt arb--actions 'symbols) . font-lock-type-face)
    ;; Query verbs (space-form, so matched as standalone symbols).
    (,(regexp-opt arb--verbs 'symbols) . font-lock-builtin-face)
    ;; Option flags: -label -max -cols -color ...
    ("\\_<-[a-z][a-z-]*\\_>" . 'arb-flag-face)
    ;; Widget / control paths: .a, .a.b.c
    ("\\.[A-Za-z_][A-Za-z0-9_]*\\(?:\\.[A-Za-z_][A-Za-z0-9_]*\\)*"
     . 'arb-widget-path-face)
    ;; Function definitions: `fn name(' / `fn name:' — highlight the name.
    ("\\_<fn\\_>[ \t]+\\([A-Za-z_][A-Za-z0-9_]*\\)"
     (1 font-lock-function-name-face)))
  "Font-lock keywords for `arb-mode'.
Strings, comments, and numbers are handled by the syntax table and by
`prog-mode' font-lock; /regex/ literals are recognized via
`arb-syntax-propertize-function'.")

;;; Syntax table.

(defvar arb-mode-syntax-table
  (let ((st (make-syntax-table)))
    (modify-syntax-entry ?# "<" st)     ; line comment start
    (modify-syntax-entry ?\n ">" st)    ; comment end
    (modify-syntax-entry ?_ "_" st)     ; symbol constituent
    (modify-syntax-entry ?\" "\"" st)   ; double-quoted string
    (modify-syntax-entry ?\' "\"" st)   ; single-quoted string
    (modify-syntax-entry ?\\ "\\" st)   ; escape
    (modify-syntax-entry ?/ "." st)     ; regex delimiter (see propertize)
    st)
  "Syntax table for `arb-mode'.")

;;; /regex/ literals — only in operand position (after `~', `(', `,', `{',
;;; `=', `!', `&', `|', `:', `;', or line start, optionally following one of
;;; the regex-taking verbs), so a path `.a/b' or a division is not mistaken
;;; for the start of a regex.  Marked as generic string; an optional trailing
;;; `i' flag is left as a plain symbol.

(defun arb-syntax-propertize-function (start end)
  "Apply `syntax-table' text properties for /regex/ literals between START and END.
A regex is recognized only in operand position (after `~', `(', `,', `{',
`=', `!', `&', `|', `:', `;', or line start, optionally following one of the
regex-taking verbs match/grep/grepv/reject/replace/extract/grepf/expect), so
a division is not misread.  Both the opening and closing `/' are marked as
generic-string delimiters (class \"|\")."
  (goto-char start)
  (funcall
   (syntax-propertize-rules
    ("\\(?:^\\|[=(,{!&|~?:;]\\|\\_<\\(?:match\\|grep\\|grepv\\|reject\\|replace\\|extract\\|grepf\\|expect\\)\\_>\\)[ \t]*\\(/\\)\\(?:\\\\.\\|\\[\\(?:\\\\.\\|[^]\n]\\)*\\]\\|[^/\n\\]\\)+\\(/\\)"
     (1 (let ((ppss (save-excursion (syntax-ppss (match-beginning 1)))))
          (unless (or (nth 3 ppss) (nth 4 ppss))
            (string-to-syntax "|"))))
     (2 (let ((ppss (save-excursion (syntax-ppss (match-beginning 1)))))
          (unless (or (nth 3 ppss) (nth 4 ppss))
            (string-to-syntax "|"))))))
   start end))

;;; Indentation — brace-aware.

(defun arb-indent-line ()
  "Indent the current line for `arb-mode'."
  (interactive)
  (let ((indent 0)
        (offset arb-indent-offset))
    (save-excursion
      (beginning-of-line)
      (let ((closes-block (looking-at-p "[ \t]*[)}]")))
        (when (zerop (forward-line -1))
          (while (and (looking-at-p "[ \t]*$") (zerop (forward-line -1))))
          (setq indent (current-indentation))
          ;; A line opening a block/paren (ignoring a trailing comment)
          ;; bumps the next line one level deeper.
          (when (looking-at-p ".*[({][ \t]*\\(#.*\\)?$")
            (setq indent (+ indent offset))))
        (when closes-block
          (setq indent (max 0 (- indent offset))))))
    (if (<= (current-column) (current-indentation))
        (indent-line-to indent)
      (save-excursion (indent-line-to indent)))))

;;; Run / compile — run the current buffer's spec through arb.

(defun arb-run-buffer ()
  "Run the current buffer's arb spec through `arb' via `compile'.
The buffer must be visiting a file; it is passed as a positional spec file."
  (interactive)
  (unless buffer-file-name
    (user-error "Buffer is not visiting a file; save it first"))
  (when (and (buffer-modified-p) (y-or-n-p "Save buffer before running? "))
    (save-buffer))
  (require 'compile)
  (compile (format "%s %s"
                   (shell-quote-argument arb-executable)
                   (shell-quote-argument buffer-file-name))))

(defvar arb-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "C-c C-c") #'arb-run-buffer)
    map)
  "Keymap for `arb-mode'.")

;;; eldoc + completion for query verbs / widgets.

(defun arb-eldoc-function (&rest _)
  "Return the eldoc signature for the arb verb at point, or nil."
  (let ((sym (thing-at-point 'symbol t)))
    (and sym (arb-stdlib-signature sym))))

(defun arb-completion-at-point ()
  "`completion-at-point-functions' entry: complete arb verb / widget names."
  (let ((bounds (bounds-of-thing-at-point 'symbol)))
    (when bounds
      (list (car bounds) (cdr bounds) arb-builtin-function-names
            :exclusive 'no))))

;;; LSP integration — eglot (built in since Emacs 29) and lsp-mode, both
;;; optional and configured lazily.  arb is launched with ONLY `--lsp'
;;; (an appended `--stdio' is rejected by the binary).

(with-eval-after-load 'eglot
  (add-to-list 'eglot-server-programs
               `(arb-mode . (,arb-executable "--lsp"))))

(with-eval-after-load 'lsp-mode
  (add-to-list 'lsp-language-id-configuration '(arb-mode . "arb"))
  (when (fboundp 'lsp-register-client)
    (lsp-register-client
     (make-lsp-client
      :new-connection (lsp-stdio-connection
                       (lambda () (list arb-executable "--lsp")))
      :activation-fn (lsp-activate-on "arb")
      :server-id 'arb-lsp))))

;;;###autoload
(define-derived-mode arb-mode prog-mode "Arb"
  "Major mode for editing arb source, targeting the arb interpreter.

\\{arb-mode-map}"
  :syntax-table arb-mode-syntax-table
  (setq-local font-lock-defaults '(arb-font-lock-keywords))
  (setq-local syntax-propertize-function #'arb-syntax-propertize-function)
  (setq-local comment-start "# ")
  (setq-local comment-start-skip "#+[ \t]*")
  (setq-local comment-end "")
  (setq-local indent-line-function #'arb-indent-line)
  (setq-local indent-tabs-mode nil)
  (setq-local tab-width arb-indent-offset)
  (add-hook 'completion-at-point-functions #'arb-completion-at-point nil t)
  (if (boundp 'eldoc-documentation-functions)
      (add-hook 'eldoc-documentation-functions #'arb-eldoc-function nil t)
    (setq-local eldoc-documentation-function #'arb-eldoc-function)))

;;;###autoload
(add-to-list 'auto-mode-alist '("\\.arb\\'" . arb-mode))

;;;###autoload
(add-to-list 'interpreter-mode-alist '("arb" . arb-mode))

(provide 'arb-mode)
;;; arb-mode.el ends here
