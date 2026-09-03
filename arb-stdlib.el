;;; arb-stdlib.el --- arb query-verb + widget signatures + docs -*- lexical-binding: t; -*-

;; Copyright (c) 2026 MenkeTechnologies

;; Author: MenkeTechnologies
;; URL: https://github.com/MenkeTechnologies/emacs-arb
;; Version: 0.1.0
;; Package-Requires: ((emacs "27.1"))
;; Keywords: languages, arb

;; This file is not part of GNU Emacs.

;;; Commentary:

;; Verb / widget metadata for `arb-mode'.  arb's builtin surface — input
;; sources, 154 query verbs, widget verbs, and directives — is small and
;; fixed by the language, so it is authored here by hand rather than
;; generated.  The one-line synopses mirror the descriptions arb ships in
;; its own LSP completion corpus.  This table powers:
;;
;;   - `eldoc' signatures in the echo area (one-line synopsis)
;;   - `completion-at-point' over verb / widget names

;;; Code:

(defconst arb-builtin-functions
  '(;; Input sources
    ("in"        . "in  — begin the pipeline, reading the raw stdin stream line by line")
    ("in.json"   . "in.json  — begin the pipeline reading stdin as JSON lines")
    ("in.csv"    . "in.csv  — treat stdin as CSV: the header row keys each data row into a JSON object")
    ("in.tsv"    . "in.tsv  — treat stdin as TSV: a tab-separated header + rows into JSON objects")
    ("in.xml"    . "in.xml  — read stdin as XML (marker; use with find)")
    ("in.html"   . "in.html  — read stdin as HTML (use with sel/find/attr/text)")
    ("in.yaml"   . "in.yaml  — parse stdin as YAML (--- multi-doc), one JSON line per document")
    ("in.toml"   . "in.toml  — parse stdin as one TOML document, emitted as a JSON object line")
    ("in.logfmt" . "in.logfmt  — read stdin as logfmt (key=value markers)")
    ;; Query: selection / projection
    ("field"     . "field NAME  — replace each line with a selected field (whitespace column or JSON key path)")
    ("fields"    . "fields N M ...  — project multiple 1-based whitespace columns, space-joined, in order")
    ("pick"      . "pick a b c  — project a JSON object to the named keys, keeping order; missing keys dropped")
    ("keys"      . "keys  — flatten a JSON object's keys into one line each")
    ("vals"      . "vals  — flatten a JSON object's values into one line each")
    ("each"      . "each  — flatten JSON-array lines into one line per element")
    ("flatten"   . "flatten  — emit each element of JSON-array lines, one level deeper than each")
    ("entries"   . "entries  — expand each JSON object into one key/value object line per key (jq to_entries)")
    ("cut"       . "cut DELIM N  — split each line by DELIM and keep the Nth (1-based) field")
    ("map"       . "map EXPR  — replace each line with an expression's value (field-aware; x = line-as-number)")
    ("where"     . "where PRED  — keep lines whose numeric value / field predicate holds")
    ;; Query: filter
    ("match"     . "match /RE/  — keep lines matching the regex")
    ("grep"      . "grep /RE/  — keep lines matching the regex")
    ("grepv"     . "grepv /RE/  — drop lines matching the regex")
    ("reject"    . "reject /RE/  — drop lines matching the regex")
    ("grepf"     . "grepf FIELD /RE/  — keep lines whose FIELD (JSON key or 1-based column) matches the regex")
    ("contains"  . "contains STR  — keep lines containing a literal substring")
    ("starts"    . "starts PREFIX  — keep lines starting with a literal prefix")
    ("ends"      . "ends SUFFIX  — keep lines ending with a literal suffix")
    ("has"       . "has KEY  — keep only JSON-object lines that contain KEY")
    ("over"      . "over N  — keep numeric lines strictly greater than N")
    ("under"     . "under N  — keep numeric lines strictly less than N")
    ("between"   . "between LO HI  — keep numeric lines x where LO <= x <= HI inclusive")
    ("nonempty"  . "nonempty  — drop empty or whitespace-only lines")
    ("numeric"   . "numeric  — keep only lines that parse as a number")
    ("uniq"      . "uniq  — drop duplicate lines globally, keeping the first occurrence")
    ("dedup"     . "dedup  — collapse runs of adjacent identical lines to one (classic uniq)")
    ("unique_by" . "unique_by FIELD  — keep the first record per distinct FIELD value")
    ;; Query: order / slice
    ("sort"      . "sort  — sort the lines; -n sorts numerically, -r reverses")
    ("sort_by"   . "sort_by FIELD  — stable-sort JSON records by FIELD (numeric if all parse, else lexicographic)")
    ("group_by"  . "group_by FIELD  — group lines by FIELD into one JSON-array line per value")
    ("count_by"  . "count_by FIELD  — group JSON records by FIELD and count; value->count sorted desc")
    ("min_by"    . "min_by FIELD  — emit the single record whose numeric FIELD is smallest")
    ("max_by"    . "max_by FIELD  — emit the single record whose numeric FIELD is largest")
    ("rev"       . "rev  — reverse the order of the lines")
    ("first"     . "first  — keep only the first line")
    ("last"      . "last  — keep only the last line")
    ("nth"       . "nth N  — keep only the Nth line (1-based)")
    ("index"     . "index N  — keep only the Nth line (1-based); out-of-range yields no lines")
    ("take"      . "take N  — keep the first N lines")
    ("drop"      . "drop N  — drop the first N lines")
    ("tailn"     . "tailn N  — keep only the last N lines")
    ("slice"     . "slice A B  — keep lines from index A to B inclusive (1-based)")
    ("sample"    . "sample N  — keep every Nth line (1-based)")
    ("enumerate" . "enumerate  — prefix each line with its 1-based index and a tab")
    ;; Query: text transform
    ("upper"     . "upper  — uppercase each line")
    ("lower"     . "lower  — lowercase each line")
    ("trim"      . "trim  — strip leading and trailing whitespace from each line")
    ("title"     . "title  — title-case each line")
    ("replace"   . "replace /RE/ TO  — regex replace-all per line; TO may use $1 captures")
    ("extract"   . "extract /RE/  — emit the first regex match per line (group 1 if any); drop non-matches")
    ("split"     . "split DELIM  — explode each line by the literal DELIM into one part per line")
    ("substr"    . "substr A B  — character substring [A,B) 0-based, clamped to the line length")
    ("chars"     . "chars  — explode each line into one output line per Unicode character")
    ("words"     . "words  — split each line on whitespace and emit one word per line")
    ("join"      . "join SEP  — collapse all lines into one, joined by SEP (default a space)")
    ("repeat"    . "repeat N  — replace each line with its content repeated N times")
    ("pad"       . "pad N  — right-pad each line with spaces to a minimum width N")
    ("lpad"      . "lpad N  — left-pad each line with spaces to a minimum width N")
    ("append"    . "append STR  — suffix every line with a literal string")
    ("prepend"   . "prepend STR  — prefix every line with a literal string")
    ("flip"      . "flip  — reverse the Unicode characters of each line")
    ("basename"  . "basename  — path basename: the part after the last /")
    ("dirname"   . "dirname  — path dirname: the part before the last /")
    ;; Query: encode / decode
    ("b64"       . "b64  — base64-encode each line")
    ("b64d"      . "b64d  — base64-decode each line; invalid lines pass through")
    ("hex"       . "hex  — lowercase hex-encode each line, two hex digits per UTF-8 byte")
    ("unhex"     . "unhex  — decode a hex string to UTF-8; on error the line passes through")
    ("urlenc"    . "urlenc  — percent-encode each line (RFC 3986)")
    ("urldec"    . "urldec  — percent-decode each line to UTF-8")
    ;; Query: JSON object edit
    ("set"       . "set K V  — set key K to string value V in each JSON object line")
    ("del"       . "del K  — remove key K from each JSON object line")
    ("rename"    . "rename OLD NEW  — rename JSON object key OLD to NEW")
    ("default"   . "default K V  — set string key K to V only when K is absent")
    ("merge"     . "merge  — reduce all JSON object lines into one object (later keys win)")
    ("add"       . "add  — reduce a JSON array line to one value (sum numbers, else concat strings)")
    ;; Query: numeric transform
    ("floor"     . "floor  — floor each numeric line")
    ("ceil"      . "ceil  — round each numeric line up to the nearest integer")
    ("round"     . "round  — round each numeric line to the nearest integer")
    ("abs"       . "abs  — absolute value of each numeric line")
    ("clamp"     . "clamp LO HI  — clamp each numeric line into the inclusive range [LO, HI]")
    ("commafy"   . "commafy  — group a numeric line's integer part with thousands separators")
    ("bytes"     . "bytes  — humanize a byte count (1024-based): 1536 -> 1.5 KB")
    ("duration"  . "duration  — humanize seconds: 3661 -> 1h 1m")
    ("len"       . "len  — replace each line with its character count")
    ("wc"        . "wc  — replace each line with its word count")
    ("cumsum"    . "cumsum  — running cumulative total of the numeric series")
    ("delta"     . "delta  — consecutive differences of the numeric series")
    ("sma"       . "sma N  — simple moving average over a trailing window of N (length-preserving)")
    ("ewma"      . "ewma A  — exponentially-weighted moving average, smoothing factor A in (0,1]")
    ;; Query: aggregate / reduce (scalars)
    ("count"     . "count  — reduce to the current line count (scalar)")
    ("distinct"  . "distinct  — reduce to the count of distinct lines (scalar)")
    ("rate"      . "rate  — reduce to lines-per-second over the elapsed window (scalar)")
    ("tally"     . "tally  — group identical lines and count them, sorted by count desc then key asc")
    ("sum"       . "sum  — sum of lines parsed as numbers (scalar)")
    ("min"       . "min  — minimum of numeric lines (scalar)")
    ("max"       . "max  — maximum of numeric lines (scalar)")
    ("avg"       . "avg  — mean of numeric lines (scalar)")
    ("range"     . "range  — max minus min of numeric lines (scalar)")
    ("product"   . "product  — product of numeric lines (scalar)")
    ("median"    . "median  — median of numeric lines (scalar)")
    ("stddev"    . "stddev  — population standard deviation of numeric lines (scalar)")
    ("percentile" . "percentile N  — Nth percentile (0-100) of numeric values, linear interpolation")
    ("p50"       . "p50  — 50th percentile (median) of the numeric values (scalar)")
    ("p90"       . "p90  — 90th percentile of the numeric values (scalar)")
    ("p95"       . "p95  — 95th percentile of the numeric values (scalar)")
    ("p99"       . "p99  — 99th percentile of the numeric values, for latency tails (scalar)")
    ("bins"      . "bins N  — bucket numeric lines into N equal-width ranges -> (range, count) pairs")
    ("calc"      . "calc EXPR  — reduce to a scalar from an arithmetic expression over the line count (x)")
    ("apply"     . "apply .name  — splice in the pipeline typed into input .name (megafilter/map)")
    ;; Query: HTML / CSS
    ("find"      . "find SEL  — parse stream as HTML, emit the outer HTML of each element matching SEL")
    ("sel"       . "sel { CSS }  — parse stream as HTML, emit each CSS match's text (or -attr value)")
    ("attr"      . "attr NAME  — from element fragments, emit each element's named attribute")
    ;; Widgets (the "Tk" register)
    ("text"      . "text .t -label L  — show the last stream line / scalar result in a bordered pane")
    ("tail"      . "tail .t -limit N  — scrolling list of the newest lines that fit (tail -f)")
    ("list"      . "list .t -limit N  — scrollable list of stream lines in a bordered pane")
    ("gauge"     . "gauge .g -max N -label L  — render a scalar as a progress bar filled to value/max")
    ("bars"      . "bars .b -label L -top N  — horizontal bar chart of tally/count pairs")
    ("histo"     . "histo .h -top N  — bar chart of value-distribution pairs")
    ("spark"     . "spark .s  — compact braille sparkline of the numeric series")
    ("chart"     . "chart .c  — braille line chart of the numeric series with auto-scaled axes")
    ("table"     . "table .t -cols \"a,b,c\"  — columnar table of records; -cols sets headers")
    ("tabs"      . "tabs .t -tabs {a b}  — tab bar; first tab selected")
    ("block"     . "block .b -title T -border  — bordered container box rendering its bound content")
    ("frame"     . "frame .f  — framed container rendering its bound stream content")
    ("input"     . "input .i -placeholder P  — editable text field spliced into pipelines via apply .name")
    ("select"    . "select .s -prompt P -header H  — interactive fuzzy-select over the stream")
    ("filter"    . "filter .f  — labelled filter control driving where match(.name) / apply")
    ("facet"     . "facet .f -opts ... / -field F  — multi-select driving where <field> in .name")
    ("slider"    . "slider .s -min -max -step  — numeric control driving where <field> < .name")
    ("check"     . "check .c -label L  — boolean toggle; its value is a \"0\"/\"1\" string")
    ;; Directives
    ("source"    . "source .t { in | ... }  — attach a query pipeline (body starts with in) as a widget's data source")
    ("bind"      . "bind KEY ACTION  — bind a control key to an action (set|quit|beep|alert|flash|exec, or a { } block)")
    ("search"    . "search .s { ... }  — attach a select widget's fuzzy-match key pipeline")
    ("expect"    . "expect /RE/ ACTION  — fire an action when a stream line matches the regex")
    ("timeout"   . "timeout Ns ACTION  — fire an action when the stream is idle for a duration")
    ("out"       . "out { ... }  — apply a query pipeline to the stream and write it to stdout (modify a pipe)")
    ("grid"      . "grid .w -row R -col C -span N  — place a widget in the layout grid")
    ("configure" . "configure / .w configure -opts  — merge new opts into an already-declared widget")
    ("import"    . "import NAME  — inline a module (stdlib preset or user .arb file) into the spec")
    ;; Actions
    ("quit"      . "quit  — quit the TUI")
    ("beep"      . "beep  — ring the terminal bell")
    ("alert"     . "alert MSG  — flash a message in the status bar for a few seconds")
    ("exec"      . "exec CMD  — run a shell command, fire-and-forget; never blocks the loop")
    ("flash"     . "flash .w -color C  — tint a widget's border/accent for a few seconds"))
  "Alist of arb verb / widget / directive name -> one-line signature/synopsis.
Authored from arb's LSP completion corpus; not generated (arb's builtin
surface is small and fixed).")

(defconst arb-builtin-function-names
  (mapcar #'car arb-builtin-functions)
  "List of arb verb / widget / directive names (keys of `arb-builtin-functions').")

(defun arb-stdlib-signature (name)
  "Return the one-line signature string for verb/widget NAME, or nil."
  (cdr (assoc name arb-builtin-functions)))

(provide 'arb-stdlib)
;;; arb-stdlib.el ends here
