;;; aho-jump.el --- A dumb xref backend     -*- lexical-binding: t -*-

;; Copyright (c) 2023 Mario Rodas <marsam@users.noreply.github.com>

;; Author: Mario Rodas <marsam@users.noreply.github.com>
;; URL: https://github.com/emacs-pe/aho-jump.el
;; Keywords: tools convenience
;; Version: 0.1
;; Package-Requires: ((emacs "28.1"))

;; This file is NOT part of GNU Emacs.

;;; License:

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; Aho Jump is a `xref' backend based on `dumb-jump' [1].
;;
;;     (add-hook 'xref-backend-functions #'aho-jump-xref-activate)
;;
;; [1]: https://github.com/jacktasia/dumb-jump

;; -------------------------------------------------------------------
;; Israel is committing genocide of the Palestinian people.
;;
;; The population in Gaza is facing starvation, displacement and
;; annihilation amid relentless bombardment and suffocating
;; restrictions on life-saving humanitarian aid.
;;
;; As of March 2025, Israel has killed over 50,000 Palestinians in the
;; Gaza Strip – including 15,600 children – targeting homes,
;; hospitals, schools, and refugee camps.  However, the true death
;; toll in Gaza may be at least around 41% higher than official
;; records suggest.
;;
;; The website <https://databasesforpalestine.org/> records extensive
;; digital evidence of Israel's genocidal acts against Palestinians.
;; Save it to your bookmarks and let more people know about it.
;;
;; Silence is complicity.
;; Protest and boycott the genocidal apartheid state of Israel.
;;
;;
;;                  From the river to the sea, Palestine will be free.
;; -------------------------------------------------------------------

;;; Code:
(require 'xref)

(defgroup aho-jump nil
  "Jump to project definitions."
  :prefix "aho-jump-"
  :group 'tools)

(defcustom aho-jump-rg-executable "rg"
  "Path to ripgrep (rg) executable."
  :type '(file :must-match t)
  :group 'aho-jump)

(defvar aho-jump-languages
  '(((bash-ts-mode sh-mode) . sh)
    ((c-mode c-ts-mode) . c)
    ((c++-mode c++-ts-mode) . c++)
    ((emacs-lisp-mode) . elisp)
    ((java-mode java-ts-mode) . java)
    ((just-mode just-ts-mode) . just)
    ((kotlin-mode kotlin-ts-mode) . kotlin)
    ((go-mode go-ts-mode) . go)
    ((lean4-mode lean-ts-mode) . lean)
    ((lisp-mode) . lisp)
    ((lua-mode lua-ts-mode) . lua)
    ((makefile-mode) . makefile)
    ((markdown-mode markdown-ts-mode) . markdown)
    ((nix-mode nix-ts-mode) . nix)
    ((org-mode) . org)
    ((python-mode python-ts-mode) . python)
    ((rust-ts-mode rust-mode) . rust)
    ((sml-mode sml-ts-mode) . sml)
    ((sql-mode sql-ts-mode) . sql)
    ((scheme-mode) . scheme)
    ((racket-mode) . racket)
    ((swift-mode swift-ts-mode) . swift)
    ((terraform-mode terraform-ts-mode) . terraform)
    ((typst-mode typst-ts-mode) . typst)
    ((js-mode js-ts-mode) . javascript)
    ((tsx-ts-mode typescript-ts-mode typescript-mode) . typescript)
    ((zig-mode zig-ts-mode) . zig))
  "How `aho-jump' guesses the language to use.")

(defvar aho-jump-regexp-alist
  '((sh nil
        "\\b%i=[^=]"                    ; Variable
        "\\b%i\\s*\\(")                 ; Function
    (c nil
       "\\b%i\\s*=[^=]"                                  ; Variable
       "^\\s*#define\\s+%i\\b"                           ; Directive
       "(^|[_[:alnum:]]+\\s+(\\*\\s*)?)\\b%i\\s*\\("     ; Function
       "(struct|enum|union)\\s+%i\\s+\\{"                ; Enum, Union
       "typedef\\s+(\\w|[(*]|\\s)+%i(\\)|\\s)*\\(")      ; Struct
    (c++ c
         "class\\s+%i\\b")              ; Class
    (lean nil
          "(class|def|inductive|theorem)\\s+%i\\b") ; Definition
    (elisp nil
           "\\\(cl-def[^ ]+\\s+%i($|[^[:punct:]])" ; Struct, Type, etc
           "\\\((defclass|defcustom|defun|defmacro|defvar|setq)\\s+%i($|[^[:punct:]])") ; Variable, Class, Function
    (java nil
          "\\b%i\\s*=[^=]+"                         ; Variable
          "(class|enum|interface|record)\\s+%i\\b"  ; Class, Interface
          "^\\s*([\\w\\[\\]]+\\s+){1,3}%i\\s*\\\(") ; Method
    (just nil
          "\\b%i\\s*:="                 ; Variable
          "^%i[^:_-]*:")                ; Recipe
    (kotlin nil
            "(val|var)\\s+%i\\b"                 ; Variable
            "fun\\s+(<[^>]+>\\s+)?%i\\b"         ; Function
            "typealias\\s+%i\\b"                 ; Type alias
            "(class|interface|object)\\s+%i\\b") ; Class, Interface, Object
    (go nil
        "\\b%i\\s+(\\w+\\s+)?=[^=]" "\\b%i\\s*:=" ; Variable
        "type\\s+%i\\s+(interface|struct)" ; Type
        "func\\s+%i\\b" "func\\s+\\\([^\\\)]+\\\)\\s+%i\\b") ; Function
    (lisp nil
          "\\\(def[^ ]+\\s+%i($|[^[:punct:]])") ; Variable, Function, Macro, etc
    (lua nil
         "\\b%i\\s*=[^=]"               ; Variable
         "function\\s+%i\\s*\\\(")      ; Function
    (makefile nil
              "^\\s*%i:"                ; Target
              "^\\s*%i\\s*[!+:?]?=")    ; Variable
    (markdown nil
              "\\bid\\s*=\\s*\"%i\""    ; ID
              "^\\[\\^%i\\]:"           ; Footnote
              "\\{#%i\\}")              ; Heading ID
    (nix nil
         "\\s%i\\s*=($|[^=])")          ; Variable
    (org nil
         "^\\s*:CUSTOM_ID:\\s*%i\\b"            ; ID
         "^\\s*#\\+(?i)name(?-i):\\s*%i\\b") ; Named block
    (python nil
            "\\b%i\\b[^=]*[:=][^=]"      ; Variable
            "def\\s+%i\\b\\s*\\\("       ; Function
            "class\\s+%i\\b\\s*[:\\\(]") ; Class
    (rust nil
          "const\\s+%i\\b"                         ; Constant
          "static\\s+(mut\s+)?%i\\b"               ; Static
          "let\\s+(.+)?(mut\s+)?%i\\b(.+)="        ; Variable
          "fn\\s+%i\\b"                            ; Function
          "impl\\s+(.+)?%i\\b"                     ; Implementation
          "macro_rules!\\s+%i\\b"                  ; Macro
          "(enum|mod|struct|trait|type)\\s+%i\\b") ; Enum, Trait, etc
    (sml nil
         "(fun|val)\\s+%i(\\s|\\()"                     ; Function
         "^\\s*(functor|funsig)\\s+%i\\s*\\("           ; Functor
         "^\\s*exception\\s+%i(\\s|$)"                  ; Signature
         "^\\s*(datatype|abstype)(\\s+'\\w+)?\\s+%i\\b" ; Datatype
         "^\\s*signature\\s+%i\\s+="                    ; Signature
         "^\\s*structure\\s+%i\\s+[=:]")                ; Structure
    (sql nil
         "(?i)create\\s+table(\\s+if\\s+not\\s+exists)?(?-i)\\s+%i\\b" ; Table
         "(?i)create\\s+(or\\s+replace\\s+)?(function|type|procedure|view)(?-i)\\s+%i\\b") ; Function, Type, View
    (scheme nil
            "\\\(define[^ ]*\\s+%i($|[^[:punct:]])" ; Variable, Macro
            "\\\(define[^ ]*\\s+\\(\\s*%i($|\\\)|[^[:punct:]])") ; Function
    (swift nil
           "(let|var)\\s+%i\\b"                     ; Variable
           "func\\s+%i\\b"                          ; Function
           "typealias\\s+%i\\b"                     ; Function
           "(class|enum|struct|protocol)\\s+%i\\b") ; Enum, Class, Struct
    (racket scheme
            "\\\((class|struct)\\s+%i($|[^[:punct:]])") ; Class, Struct
    (typst nil
           "<%i>" "#label\\\(\"%i\"\\\)" ; Label
           "#let\s+%i(\\\(|[^-])")       ; Variable
    (terraform nil
               "^%i\\s*="                                 ; tfvars
               "(variable|module|output)\\s+\"%i\""       ; Variable
               "(data|resource|ephemeral)\\s+\"[^\"]+\"\\s+\"%i\"") ; Data
    (javascript nil
                "(const|let|var)\\s+%i\\b"                ; Variable
                "(async|function)\\s+%i\\s*\\\("          ; Function
                "\\b%i\\s*[=:]\\s*\\\([^\\\)]*\\\)\\s+=>" ; Arrow Function
                "class\\s+%i\\b")                         ; Class
    (typescript javascript
                "type\\s+%i\\b"         ; Type
                "interface\\s+%i\\b")   ; Interface
    (zig nil
         "(const|var)\\s+%i\\b"         ; Variable
         "fn\\s+%i\\b"))                ; Function
  "Alist of languages with its identifier regexes.

An entry should be of the form:

   LANGUAGE PARENT-LANGUAGE *REGEXES

LANGUAGE is the symbol used to identify the language used, it should be
present in `aho-jump-languages'.  PARENT-LANGUAGE is the LANGUAGE from
which regexes can be inherited.  REGEXES hold the patterns to match when
looking for a identifier.  Each REGEX must have the specification `%i'
which later is going to be replaced with the identifier name.")

(defvar aho-jump-rg-default-args '("--case-sensitive" "--column" "--color=never" "--no-heading" "--no-messages" "--line-number" "--max-columns=80" "--max-columns-preview")
  "Default arguments passed to ripgrep.")

(defun aho-jump-mode-language (&optional mode)
  "Return the supported language associated to major MODE."
  (alist-get (or mode major-mode) aho-jump-languages nil nil (lambda (modes needle) (provided-mode-derived-p needle modes))))

(defun aho-jump-regexp-args (identifier regexes)
  "Build the IDENTIFIER with REGEXES patterns."
  (cl-loop for regexp in regexes
           collect "--regexp"
           collect (format-spec regexp `((?i . ,identifier)))))

(defun aho-jump-command-args (identifier language)
  "Execute the ripgrep command for IDENTIFIER and LANGUAGE."
  (pcase-let*
      ((`(,parent . ,regexes) (alist-get language aho-jump-regexp-alist))
       (regexes (append (cdr (alist-get parent aho-jump-regexp-alist)) regexes)))
    (append aho-jump-rg-default-args
            (aho-jump-regexp-args identifier regexes)
            (aho-jump-language-args language))))

(cl-defgeneric aho-jump-language-args (language)
  "Return the arguments for LANGUAGE.")

(cl-defmethod aho-jump-language-args ((_language (eql 'sh)))
  "Return the arguments for Sh."
  (list "--type=sh"))

(cl-defmethod aho-jump-language-args ((_language (eql 'c)))
  "Return the arguments for C."
  (list "--type=c"))

(cl-defmethod aho-jump-language-args ((_language (eql 'c++)))
  "Return the arguments for C++."
  (list "--type=cpp"))

(cl-defmethod aho-jump-language-args ((_language (eql 'elisp)))
  "Return the arguments for Emacs Lisp."
  (list "--type=elisp"))

(cl-defmethod aho-jump-language-args ((_language (eql 'go)))
  "Return the arguments for Go."
  (list "--type=go"))

(cl-defmethod aho-jump-language-args ((_language (eql 'java)))
  "Return the arguments for Java."
  (list "--type=java"))

(cl-defmethod aho-jump-language-args ((_language (eql 'just)))
  "Return the arguments for Just."
  (list "--type-add=just:*.just" "--type-add=just:[Jj]ustfile" "--type=just"))

(cl-defmethod aho-jump-language-args ((_language (eql 'kotlin)))
  "Return the arguments for Kotlin."
  (list "--type=kotlin"))

(cl-defmethod aho-jump-language-args ((_language (eql 'lean)))
  "Return the arguments for Lean."
  (list "--type=lean"))

(cl-defmethod aho-jump-language-args ((_language (eql 'lisp)))
  "Return the arguments for Common Lisp."
  (list "--type-add=commonlisp:*.{lisp,lsp}" "--type=commonlisp"))

(cl-defmethod aho-jump-language-args ((_language (eql 'lua)))
  "Return the arguments for Lua."
  (list "--type=lua"))

(cl-defmethod aho-jump-language-args ((_language (eql 'makefile)))
  "Return the arguments for Makefile."
  (list "--type=make"))

(cl-defmethod aho-jump-language-args ((_language (eql 'markdown)))
  "Return the arguments for Markdown."
  (list "--type=markdown"))

(cl-defmethod aho-jump-language-args ((_language (eql 'nix)))
  "Return the arguments for Nix."
  (list "--type=nix"))

(cl-defmethod aho-jump-language-args ((_language (eql 'org)))
  "Return the arguments for Org mode."
  (list "--type=org"))

(cl-defmethod aho-jump-language-args ((_language (eql 'python)))
  "Return the arguments for Python."
  (list "--type=python"))

(cl-defmethod aho-jump-language-args ((_language (eql 'rust)))
  "Return the arguments for Rust."
  (list "--type=rust"))

(cl-defmethod aho-jump-language-args ((_language (eql 'sml)))
  "Return the arguments for Standard ML."
  (list "--type=sml"))

(cl-defmethod aho-jump-language-args ((_language (eql 'sql)))
  "Return the arguments for SQL."
  (list "--type=sql"))

(cl-defmethod aho-jump-language-args ((_language (eql 'scheme)))
  "Return the arguments for Scheme."
  (list "--type-add=scheme:*.{scm,ss,sch,guile}" "--type=scheme"))

(cl-defmethod aho-jump-language-args ((_language (eql 'racket)))
  "Return the arguments for Racket."
  (list "--type=racket"))

(cl-defmethod aho-jump-language-args ((_language (eql 'swift)))
  "Return the arguments for Swift."
  (list "--type=swift"))

(cl-defmethod aho-jump-language-args ((_language (eql 'typst)))
  "Return the arguments for Typst."
  (list "--type=typst"))

(cl-defmethod aho-jump-language-args ((_language (eql 'terraform)))
  "Return the arguments for Terraform."
  (list "--type-add=terraform:*.{tf,tfvars}" "--type=terraform"))

(cl-defmethod aho-jump-language-args ((_language (eql 'javascript)))
  "Return the arguments for JavaScript."
  (list "--type=js"))

(cl-defmethod aho-jump-language-args ((_language (eql 'typescript)))
  "Return the arguments for TypeScript."
  (list "--type=typescript"))

(cl-defmethod aho-jump-language-args ((_language (eql 'zig)))
  "Return the arguments for Zig."
  (list "--type=zig"))

(cl-defmethod xref-backend-definitions ((_backend (eql aho-jump)) identifier)
  "Find definitions of IDENTIFIER."
  (let* ((process-file-side-effects)
         (language (aho-jump-mode-language major-mode))
         (args (aho-jump-command-args identifier language))
         (default-directory (if-let* ((project (project-current)))
                                (expand-file-name (file-name-as-directory (project-root project)))
                              default-directory)))
    (with-temp-buffer
      (pcase (apply #'process-file aho-jump-rg-executable nil '(t t) nil args)
        (1 nil)                         ; Identifier not found
        ((or 0 2)                       ; Ignore soft errors (code=2)
         (goto-char (point-min))
         (cl-loop while (re-search-forward "^\\([^: \n\t]+\\):\\([0-9]+\\):\\([0-9]+\\):\\(.+\\)$" nil t)
                  with ident-re = (format "\\<%s\\>" (regexp-quote identifier))
                  for file = (match-string 1)
                  for line = (string-to-number (match-string 2))
                  for summary = (match-string 4)
                  for column = (or (string-match-p ident-re summary) (string-to-number (match-string 3)))
                  for location = (xref-make-file-location (expand-file-name file) line column)
                  collect (xref-make-match summary location (length identifier))))
        (status
         (goto-char (point-min))
         (error "`%s' exited with status %s: %s" aho-jump-rg-executable status (buffer-substring (point) (line-end-position))))))))

(cl-defmethod xref-backend-apropos ((_backend (eql aho-jump)) pattern)
  "Find all symbols that match PATTERN string."
  (xref-backend-definitions 'aho-jump pattern))

(cl-defmethod xref-backend-identifier-completion-table ((_backend (eql aho-jump)))
  "Return the completion table for identifiers."
  nil)

;;;###autoload
(defun aho-jump-xref-activate ()
  "Activate the aho-jump xref backend."
  (and (aho-jump-mode-language) 'aho-jump))

(provide 'aho-jump)
;;; aho-jump.el ends here
