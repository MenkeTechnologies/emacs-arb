```
███████╗███╗   ███╗ █████╗  ██████╗███████╗       █████╗ ██████╗ ██████╗
██╔════╝████╗ ████║██╔══██╗██╔════╝██╔════╝      ██╔══██╗██╔══██╗██╔══██╗
█████╗  ██╔████╔██║███████║██║     ███████╗█████╗███████║██████╔╝██████╔╝
██╔══╝  ██║╚██╔╝██║██╔══██║██║     ╚════██║╚════╝██╔══██║██╔══██╗██╔══██╗
███████╗██║ ╚═╝ ██║██║  ██║╚██████╗███████║      ██║  ██║██║  ██║██████╔╝
╚══════╝╚═╝     ╚═╝╚═╝  ╚═╝ ╚═════╝╚══════╝      ╚═╝  ╚═╝╚═╝  ╚═╝╚═════╝
```

[![CI](https://github.com/MenkeTechnologies/emacs-arb/actions/workflows/ci.yml/badge.svg)](https://github.com/MenkeTechnologies/emacs-arb/actions/workflows/ci.yml)
[![Docs](https://img.shields.io/badge/docs-05d9e8.svg)](https://menketechnologies.github.io/emacs-arb/)
[![Report](https://img.shields.io/badge/report-ff2a6d.svg)](https://menketechnologies.github.io/emacs-arb/report.html)
[![Emacs](https://img.shields.io/badge/emacs-27.1%2B-39ff14.svg)](https://www.gnu.org/software/emacs/)
[![License: MIT](https://img.shields.io/badge/License-MIT-d300c5.svg)](https://opensource.org/licenses/MIT)

### `[EMACS MAJOR MODE // NEON FONT-LOCK // PIPE DASHBOARDS // RUN + LSP]`

> *"Open a `.arb`. Widgets, query verbs, and the whole pipeline spec light up."*

Emacs major mode (`arb-mode`) for **arb**, the pipe-native TUI/web dashboard language on **[fusevm](https://github.com/MenkeTechnologies/fusevm)/JIT** — pipe a stream in and **[arb](https://github.com/MenkeTechnologies/arb)** builds a dynamic ratatui TUI or a served web page from a declarative, Tcl/Tk-flavored spec (a jq/xpath/css/yq superset). Font-lock for keywords, input sources, directives, widget verbs, 154 query verbs, widget paths, `-flags`, and `/regex/` literals; filetype detection; brace-aware indentation; run a buffer through `arb`; eldoc + completion for verbs and widgets; and LSP via `arb --lsp` (eglot + lsp-mode).

### [`Read the Docs`](https://menketechnologies.github.io/emacs-arb/) &middot; [`Engineering Report`](https://menketechnologies.github.io/emacs-arb/report.html) · [`arb`](https://github.com/MenkeTechnologies/arb) · [`vim-arb`](https://github.com/MenkeTechnologies/vim-arb) · [`vscode-arb`](https://github.com/MenkeTechnologies/vscode-arb)

---

## [0x00] OVERVIEW

**emacs-arb** is the Emacs major mode for **arb** (the `arb` engine). It provides:

- **Filetype detection** — `*.arb` files (`auto-mode-alist`) and arb shebangs (`interpreter-mode-alist`).
- **Syntax highlighting** — font-lock for arb keywords and constants, the 10 input sources (`in`, `in.json`, `in.csv`, …), the 9 directives (`source`, `bind`, `grid`, …), the 19 widget verbs (`text`, `table`, `gauge`, …), the 154 query verbs (`field`, `where`, `tally`, `sma`, …), widget/control paths (`.a.b.c`), `-flags`, `/regex/` literals, single- and double-quoted strings, `#` comments, and numbers.
- **Indentation** — brace-aware `indent-line-function`.
- **Run** — `arb-run-buffer` (`C-c C-c`) runs the buffer's spec through `arb` via `compile`.
- **eldoc + completion** — one-line signatures and `completion-at-point` for arb verbs and widgets.
- **Language server** — `arb --lsp` via **eglot** (built in since Emacs 29) and **lsp-mode**.

arb's builtin surface (inputs, directives, widgets, and query verbs) is small and fixed by the language, so the keyword lists are plain `regexp-opt` lists in `arb-mode.el` — no generated hash-table stdlib is needed (that machinery only exists in the sibling `emacs-stryke` because stryke's ~10,493 builtins overflow Emacs' regexp compiler). Verb / widget signatures for eldoc / completion live in `arb-stdlib.el`, authored from arb's own LSP completion corpus.

`arb --lsp` is launched with **only** `--lsp` — an appended `--stdio` is rejected by the binary, so neither client is configured to add one.

Created by **[MenkeTechnologies](https://github.com/MenkeTechnologies)**.

---

## [0x01] FEATURE MATRIX

| Capability | Status |
|---|---|
| Filetype detection — `*.arb` | **Implemented** — `auto-mode-alist` |
| Filetype detection — shebang | **Implemented** — `interpreter-mode-alist` (`arb`) |
| Syntax highlighting | **Implemented** — font-lock for keywords, inputs, directives, widgets, verbs, paths, flags, regex |
| Comments | **Implemented** — `#` line comments via syntax table |
| Strings | **Implemented** — single- and double-quoted via syntax table |
| `/regex/` literals | **Implemented** — `syntax-propertize` (operand position only) |
| Indentation | **Implemented** — brace-aware `arb-indent-line` |
| Run buffer | **Implemented** — `arb-run-buffer` (`C-c C-c`) via `compile` |
| eldoc | **Implemented** — verb / widget signatures |
| Completion | **Implemented** — `completion-at-point` over verbs / widgets |
| Language server (eglot) | **Implemented** — `arb --lsp` |
| Language server (lsp-mode) | **Implemented** — registered client |
| Config | `arb-executable`, `arb-indent-offset` |

> The `arb` binary must be on `$PATH` to run buffers and for the language server. Build **[arb](https://github.com/MenkeTechnologies/arb)** (`cargo install --path .`).

---

## [0x02] INSTALL

### Manual

```elisp
;; clone, then:
(add-to-list 'load-path "/path/to/emacs-arb")
(require 'arb-mode)
```

### use-package + built-in VC

```elisp
(use-package arb-mode
  :mode "\\.arb\\'"
  :vc (:url "https://github.com/MenkeTechnologies/emacs-arb"))
```

Open any `.arb` file — it lights up. Press `C-c C-c` to run it through `arb`. With eglot, run `M-x eglot` to start the language server (or `(add-hook 'arb-mode-hook #'eglot-ensure)`).

---

## [0x03] SYNTAX // FACES

| Token group | Face |
|---|---|
| Keywords / constants (`fn` `let` `if` `for` `match` `spawn` `out` `true` `nil`) | `font-lock-keyword-face` |
| Directives (`source` `bind` `grid` `search` `timeout` `expect`) | `font-lock-keyword-face` |
| Input sources (`in` `in.json` `in.csv` `in.html` `in.yaml`) | `font-lock-type-face` |
| Widget verbs (`text` `table` `gauge` `bars` `spark` `chart` `select`) | `arb-widget-face` |
| Query verbs (`field` `where` `tally` `sort_by` `percentile` `sma`) | `font-lock-builtin-face` |
| Actions (`alert` `beep` `exec` `flash` `quit`) | `font-lock-type-face` |
| Widget / control paths (`.a` `.a.b.c`) | `arb-widget-path-face` |
| Option flags (`-label` `-max` `-cols` `-color`) | `arb-flag-face` |
| Function names (`fn NAME`) | `font-lock-function-name-face` |
| Strings / comments / `/regex/` | via syntax table + `syntax-propertize` |

---

## [0x04] RUN

`arb-run-buffer` (bound to `C-c C-c`) runs the current buffer's spec through `arb FILE` using Emacs' `compile`, so output, errors, and `next-error` navigation land in the `*compilation*` buffer. The executable is `arb-executable` (default `"arb"`). arb reads its stream from stdin; pipe a producer into Emacs' inferior process or run headless from a shell for live data.

---

## [0x05] LANGUAGE SERVER

`arb-mode` registers `arb --lsp` for both clients (lazily, so neither is a hard dependency):

- **eglot** (Emacs 29+): `M-x eglot` in a `.arb` buffer.
- **lsp-mode**: `M-x lsp`.

The executable is `arb-executable` (default `"arb"`); change it for a custom path. The server is launched with `--lsp` only — no `--stdio` is appended (the binary rejects it).

---

## [0x06] LAYOUT

```
emacs-arb/
├── arb-mode.el             # major mode: syntax table, font-lock, indent, run, LSP, eldoc, completion
├── arb-stdlib.el           # verb / widget signatures (eldoc + completion)
├── scripts/face-test.el    # fontifies a sample and asserts faces
├── tests/face-test.sh      # byte-compile + face assertions wrapper
└── tests/*.sh              # README / docs / workflow validators
```

---

## [0x07] LICENSE

MIT © **[MenkeTechnologies](https://github.com/MenkeTechnologies)**
