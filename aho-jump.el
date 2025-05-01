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
  :type '(string :tag "Ripgrep executable"))

(defcustom aho-jump-summary-max-length 80
  "Maximum length for match summary to display."
  :type '(choice (const :tag "No limit" nil) (natnum :tag "Maximum length")))

(defvar aho-jump-languages
  '(((bash-ts-mode sh-mode) . sh)
    ((c-mode c-ts-mode) . c)
    ((c++-mode c++-ts-mode) . c++)
    ((csharp-mode csharp-ts-mode) . csharp)
    ((dart-mode dart-ts-mode) . dart)
    ((emacs-lisp-mode) . elisp)
    ((elixir-mode elixir-ts-mode) . elixir)
    ((java-mode java-ts-mode) . java)
    ((just-mode just-ts-mode) . just)
    ((julia-mode julia-ts-mode) . julia)
    ((kotlin-mode kotlin-ts-mode) . kotlin)
    ((go-mode go-ts-mode) . go)
    ((haskell-mode haskell-ts-mode) . haskell)
    ((lean4-mode lean-ts-mode) . lean)
    ((lisp-mode) . lisp)
    ((lua-mode lua-ts-mode) . lua)
    ((makefile-mode) . makefile)
    ((markdown-mode markdown-ts-mode) . markdown)
    ((nix-mode nix-ts-mode) . nix)
    ((caml-mode tuareg-mode ocaml-ts-mode neocaml-base-mode) . ocaml)
    ((org-mode) . org)
    ((perl-mode perl-ts-mode) . perl)
    ((php-mode php-ts-mode) . php)
    ((python-mode python-ts-mode) . python)
    ((ruby-mode ruby-ts-mode enh-ruby-mode) . ruby)
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
        "(?:^|[^\\s\\w\"'.=:(\\[#/`*-])\\s*%i=[^=]"   ; Variable
        "(?:^|[^\\s\\w\"'.=:(\\[#/`*-])\\s*%i\\s*\\(" ; Function
        "^\\s*function\\s+%i\\b"        ; Brace-style function
        "(?:^|[^\\s\\w\"'.=:(\\[#/`*-])\\s*(?:local|declare|typeset|readonly|export)\\s+(?:-\\w+\\s+)*%i(?:[= ]|$)") ; Declaration
    (c nil
       "^[^(]*[^.\\s=:(\\[#/\"'\\`>*-]\\s*\\b%i\\s*=[^=]" ; Variable
       "^\\s*#define\\s+%i\\b"                            ; Directive
       "\\*%i\\s*\\)\\s*\\([^)]*\\)(?:$|[^,)])" ; Function pointer
       "^\\s*%i\\s*\\([^)]*\\)\\s*\\{"          ; Bare function
       "(?:^|[;{}>])\\s*(?:\\w[\\w:<>]*\\**\\s+)+\\**\\s*(?:\\w+::)*%i\\s*\\(" ; Typed function
       "(?:struct|enum|union)\\s+%i(?:\\s+(?:__\\w+\\s*\\([^;]*\\)[^;{]*|final))?(?:\\s*:\\s*[^;{]*)?\\s*\\{" ; Enum, Union, Struct
       "^\\s*(?:(?:auto|const|extern|inline|register|restrict|static|volatile|thread_local|constexpr|mutable|unsigned|signed|short|long|char|int|float|double|void|struct|enum|union|typedef)\\b\\s*)*(?:(?:auto|const|extern|inline|register|restrict|static|volatile|thread_local|constexpr|mutable|unsigned|signed|short|long|char|int|float|double|void|struct|enum|union|typedef)\\b|[A-Z_]\\w*|\\w+_t|\\w+(?:::\\w+)+(?:<[^;]*>)?)\\s+[\\w*\\s]*\\b%i\\s*[\\[,;=]") ; Declaration
    (c++ c
         "using\\s+%i\\s*="              ; Type alias
         "namespace\\s+(?:\\w+::)*%i\\b" ; Namespace
         "(?:class|concept|enum\\s+(?:class|struct))\\s+%i\\b") ; Class, Concept, Enum class
    (csharp nil
            "\\bnamespace\\s+(?:[\\w.]+\\s*\\.\\s*)*%i\\b" ; Namespace
            "(?:^|[;{}])\\s*(?:public|private|protected|internal)\\s+(?:(?:static|virtual|override|async|sealed|readonly|const)\\s+)*\\w+(?:<[^>]*>)?\\s+%i\\s*(?:[({=;]|$)" ; Method, Property, Field
            "\\b(?:class|interface|struct|enum|record)\\s+%i\\b") ; Class, Interface, Struct, Enum, Record
    (dart nil
          "\\b(?:final|var|const|late)\\s+%i\\b" ; Variable
          "\\b(?:void|int|double|num|bool|dynamic|[A-Z]\\w*)\\s+%i\\s*\\(" ; Typed function
          "(?:^|[^\\s\\w\"'.=:({\\[#/`*-])\\s*%i\\s*\\([^)]*\\)\\s*(?:async\\s*)?\\{" ; Function, Method
          "\\b(?:abstract\\s+)?(?:class|enum|mixin|extension|typedef)\\s+%i\\b") ; Class, Enum, Mixin, Extension, Typedef
    (lean nil
          "(?:abbrev|axiom|class|def|inductive|instance|lemma|opaque|structure|theorem)\\s+%i\\b") ; Definition
    (elisp nil
           "\\((?:cl-def[^ ]+|def[a-z-]+|setq)\\s+(?:\\(\\s*)?%i(?:$|[\\s)])" ; Variable, Class, Function, Mode
           "\\(def[a-z-]+\\s+'%i(?:$|[\\s)])") ; Quoted name (defalias, define-error, etc.)
    (elixir nil
            "\\bdef(?:p|macro|module|protocol|impl)?\\s+%i\\b") ; Function, Macro, Module, Protocol, Implementation
    (java nil
          "(?:^|[^\\s\"'.=:({\\[#/`*-])\\s*\\b%i\\s*=[^=]" ; Variable
          "(?:class|enum|interface|record)\\s+%i\\b" ; Class, Interface
          "(?:\\w[\\w\\[\\]<>,.]*\\s+)+%i\\s*\\(")   ; Method
    (just nil
          "\\b%i\\s*:="                 ; Variable
          "^%i\\b[^:_-]*:")             ; Recipe
    (julia nil
           "\\b(?:function|macro|module|const|struct)\\s+%i\\b" ; Function, Macro, Module, Constant, Struct
           "\\b(?:abstract|primitive)\\s+type\\s+%i\\b" ; Abstract, Primitive type
           "(?:^|[^\\s\\w\"'.=:({\\[#/`*-])\\s*%i\\s*(?:\\([^)]*\\))?\\s*=[^=]") ; Variable, Shorthand function
    (kotlin nil
            "(?:(?:^|[^\\s(])\\s*(?:val|var)|fun(?:\\s*<[^>]+>)?)\\s+(?:\\w+\\.\\s*)*%i\\b" ; Variable, Function
            "(?:typealias|class|interface|object)\\s+%i\\b") ; Type alias, Class, Interface, Object
    (go nil
        "(?:^|[^\\s\"'.=:({\\[#/`*-])\\s*\\b%i\\b\\s*(?::=|\\w*\\s*=[^=])" ; Variable
        "type\\s+%i(?:\\[[^\\]]*\\])?\\s+(?:interface|struct\\b|=)" ; Type
        "^(?:var|const)\\s+%i\\b"            ; Declaration
        "func\\s+(?:\\([^)]+\\)\\s+)?%i\\b") ; Function
    (haskell nil
            "\\b%i\\s*::"               ; Type signature
            "^%i\\s*=(?:[^=]|$)"        ; Binding
            "\\b(?:data|newtype|type|class|instance|module)\\s+%i\\b") ; Data, Type, Class, Instance, Module
    (lisp nil
          "\\(def[^ ]+\\s+%i(?:$|[\\s)])") ; Variable, Function, Macro, etc
    (lua nil
         "(?:^|[^\\s\"'.=:({\\[#/`*-])\\s*\\b%i\\s*=[^=]"  ; Variable
         "function\\s+(?:[\\w.:]+\\s*[.:]\\s*)?%i\\s*\\(") ; Function
    (makefile nil
              "^\\s*define\\s+%i\\b"    ; Define
              "^\\s*(?:(?:export|override)\\s+)?%i\\s*(?:[!+:?]?=|:)") ; Target, Variable
    (markdown nil
              "^\\[(?:\\^%i|%i)\\]:"    ; Footnote, reference link
              "(?:\\bid\\s*=\\s*\"%i\"|\\{#%i\\})") ; ID, Heading ID
    (nix nil
         "(?:^|[^\\s\\w\"'.=:(\\[#/`*-])\\s*%i\\s*=(?:$|[^=])" ; Variable
         "inherit\\s+(?:\\([^)]*\\)\\s+)?%i\\b") ; Inherit
    (ocaml nil
           "\\blet\\s+(?:rec\\s+)?%i\\b" ; Let
           "\\b(?:type|module|class|exception|val|method|external)\\s+%i\\b") ; Type, Module, Class, Exception, Val, Method, External
    (org nil
         "^\\s*(?::CUSTOM_ID:\\s*%i\\b|#\\+(?i:name):\\s*%i\\b)") ; ID, Named block
    (perl nil
          "(?:^|[^\\s\\w\"'.=:({\\[#/`*-])\\s*\\$%i\\s*=[^=]" ; Variable
          "\\b(?:my|our|local|state)\\s+\\$%i\\b" ; Declaration
          "\\bsub\\s+%i\\b"                       ; Subroutine
          "\\bpackage\\s+(?:\\w+::)*%i\\b")       ; Package
    (php nil
         "\\bconst\\s+%i\\b"                  ; Constant
         "\\bfunction\\s+(?:&\\s*)?%i\\s*\\(" ; Function
         "(?:^|[^\\s\\w\"'.=:({\\[#/`*>-])\\s*\\$%i\\s*=[^=]" ; Variable
         "\\b(?:public|private|protected|var|static)\\s+\\$%i\\b" ; Property
         "\\b(?:abstract\\s+)?(?:class|interface|trait|enum)\\s+%i\\b") ; Class, Interface, Trait, Enum
    (python nil
            "\\b%i\\s*:=[^=]"                             ; Walrus
            "\\(\\s*[^()\\[\\]]*%i\\b[^()\\[\\]]*\\)\\s*=[^=]" ; Tuple target
            "(?:^|;)\\s*(?:[^()\\[\\]{\"'.=:,#/`*-]*,\\s*)+%i\\b[^.=:(\\[]*=[^=]" ; Tuple target, bare
            "(?:^|[^\\s\\w\"'.=:({\\[#/`*,-])\\s*%i\\b[^.=:(\\[]*=[^=]" ; Variable
            "(?:^|[^\\s\\w\"'.=:({\\[#/`*,-])\\s*%i\\s*:[^=].*[^,\\s]\\s*$" ; Annotation
            "(?:def|class)\\s+%i(?:\\[[^\\]]*\\])?\\s*[:(]") ; Function, Class
    (rust nil
          "impl\\s+[^{;]*%i\\b"                   ; Implementation
          "let\\s+[^=:]*\\b%i\\b[^=]*="           ; Variable
          "(?:const|static(?:\\s+mut)?)\\s+%i\\b" ; Constant, Static
          "(?:fn|enum|mod|struct|trait|type|union|macro_rules!)\\s+%i\\b") ; Function, Enum, Trait, etc
    (sml nil
         "(?:fun|val)\\s+(?:rec\\s+)?%i[\\s(]" ; Function, Value
         "\\b(?:exception|functor|funsig|signature|structure|datatype|abstype|type)(?:\\s+'\\w+)?\\s+%i\\b") ; Functor, Exception, Datatype, Signature, Structure, Type
    (sql nil
         "(?i:create\\s+table(?:\\s+if\\s+not\\s+exists)?)\\s+(?:[\\w.]+\\s*\\.\\s*)?%i\\b" ; Table
         "(?i:create\\s+(?:or\\s+replace\\s+)?(?:function|type|procedure|view|index|trigger|sequence|materialized\\s+view))\\s+(?:[\\w.]+\\s*\\.\\s*)?%i\\b") ; Function, Type, View
    (scheme nil
            "\\(define[^ ]*\\s+(?:\\(\\s*)?%i(?:$|[\\s)])") ; Variable, Macro, Function
    (swift nil
           "(?:let|var)\\s+%i\\b"          ; Variable
           "func\\s+(?:\\w+\\.\\s*)*%i\\b" ; Function
           "(?:typealias|class|enum|struct|protocol|actor)\\s+%i\\b") ; Type alias, Enum, Class, Struct, Actor
    (racket scheme
            "\\((?:class|struct)\\s+%i(?:$|[\\s)])") ; Class, Struct
    (ruby nil
          "(?:^|[^\\s\\w\"'.=:({\\[#/`*-])\\s*%i\\s*=[^=]" ; Variable
          "\\b(?:def|class|module)\\s+(?:\\w+\\.\\s*|\\w+::)*%i\\b") ; Method, Class, Module
    (typst nil
           "#let\\s+%i[^-]"               ; Variable
           "(?:<%i>|#label\\(\"%i\"\\))") ; Label
    (terraform nil
               "(?:^%i\\s*=|(?:variable|module|output)\\s+\"%i\")" ; tfvars, Variable
               "(?:data|resource|ephemeral)\\s+\"[^\"]+\"\\s+\"%i\"") ; Data
    (javascript nil
                "(?:const|let|var|class)\\s+%i\\b" ; Variable, Class
                "(?:function\\*?|async)\\s+%i\\s*\\(" ; Function
                "(?:^|[^\\s\\w\"'.=:(\\[#/`*-])\\s*%i\\s*\\([^)]*\\)\\s*\\{" ; Method
                "(?:^|[^\\s\\w\"'\\`=:(\\[/-])\\s*%i\\s*[=:]\\s*(?:async\\s+)?\\([^\\\\)]*\\)\\s+=>") ; Arrow Function
    (typescript javascript
                "(?:type|interface|enum|namespace)\\s+%i\\b(?:$|\\s*(?:[={<]|extends\\b|implements\\b))") ; Type, Interface, Enum, Namespace
    (zig nil
         "(?:const|var|fn)\\s+%i\\b"))  ; Variable, Function
  "Alist of languages with its identifier regexes.

An entry should be of the form:

   LANGUAGE PARENT-LANGUAGE *REGEXES

LANGUAGE is the symbol used to identify the language used, it should be
present in `aho-jump-languages'.  PARENT-LANGUAGE is the LANGUAGE from
which regexes can be inherited.  REGEXES hold the patterns to match when
looking for a identifier.  Each REGEX must have the specification `%i'
which later is going to be replaced with the identifier name.")

(defvar aho-jump-rg-default-args '("--case-sensitive" "--column" "--color=never" "--no-heading" "--no-messages" "--line-number")
  "Default arguments passed to ripgrep.")

(defun aho-jump-mode-language (&optional mode)
  "Return the supported language associated to major MODE."
  (alist-get (or mode major-mode) aho-jump-languages nil nil (lambda (modes needle) (provided-mode-derived-p needle modes))))

(defun aho-jump-regexp-alist-regexes (language)
  "Return the identifier regexes for LANGUAGE, including inherited parents."
  (named-let walk ((language language)
                   (seen (list language)))
    (pcase (assq language aho-jump-regexp-alist)
      (`(,_ ,parent . ,regexps)
       (if (memq parent seen)
           (user-error "Cyclic parent in `aho-jump-regexp-alist': %S" parent)
         (append (walk parent (cons parent seen)) regexps)))
      (_ nil))))

(defun aho-jump-regexp-args (identifier regexes)
  "Build the IDENTIFIER with REGEXES patterns."
  (cl-loop for regexp in regexes
           collect "--regexp"
           collect (format-spec regexp `((?i . ,(regexp-quote identifier))))))

(defun aho-jump-command-args (identifier language)
  "Return the ripgrep arguments for IDENTIFIER and LANGUAGE."
  (if-let* ((regexes (aho-jump-regexp-alist-regexes language)))
      (append aho-jump-rg-default-args
              (and aho-jump-summary-max-length
                   (list (format "--max-columns=%d" aho-jump-summary-max-length) "--max-columns-preview"))
              (aho-jump-regexp-args identifier regexes)
              (aho-jump-language-args language))
    (user-error "No regexps defined for language `%S' in `aho-jump-regexp-alist'" language)))

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

(cl-defmethod aho-jump-language-args ((_language (eql 'csharp)))
  "Return the arguments for C#."
  (list "--type=cs"))

(cl-defmethod aho-jump-language-args ((_language (eql 'dart)))
  "Return the arguments for Dart."
  (list "--type=dart"))

(cl-defmethod aho-jump-language-args ((_language (eql 'elisp)))
  "Return the arguments for Emacs Lisp."
  (list "--type=elisp"))

(cl-defmethod aho-jump-language-args ((_language (eql 'elixir)))
  "Return the arguments for Elixir."
  (list "--type=elixir"))

(cl-defmethod aho-jump-language-args ((_language (eql 'go)))
  "Return the arguments for Go."
  (list "--type=go"))

(cl-defmethod aho-jump-language-args ((_language (eql 'haskell)))
  "Return the arguments for Haskell."
  (list "--type=haskell"))

(cl-defmethod aho-jump-language-args ((_language (eql 'java)))
  "Return the arguments for Java."
  (list "--type=java"))

(cl-defmethod aho-jump-language-args ((_language (eql 'just)))
  "Return the arguments for Just."
  (list "--type-add=just:*.just" "--type-add=just:[Jj]ustfile" "--type=just"))

(cl-defmethod aho-jump-language-args ((_language (eql 'julia)))
  "Return the arguments for Julia."
  (list "--type=julia"))

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

(cl-defmethod aho-jump-language-args ((_language (eql 'ocaml)))
  "Return the arguments for OCaml."
  (list "--type=ocaml"))

(cl-defmethod aho-jump-language-args ((_language (eql 'org)))
  "Return the arguments for Org mode."
  (list "--type=org"))

(cl-defmethod aho-jump-language-args ((_language (eql 'perl)))
  "Return the arguments for Perl."
  (list "--type=perl"))

(cl-defmethod aho-jump-language-args ((_language (eql 'php)))
  "Return the arguments for PHP."
  (list "--type=php"))

(cl-defmethod aho-jump-language-args ((_language (eql 'python)))
  "Return the arguments for Python."
  (list "--type=python"))

(cl-defmethod aho-jump-language-args ((_language (eql 'ruby)))
  "Return the arguments for Ruby."
  (list "--type=ruby"))

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

(cl-defgeneric aho-jump-xref-exclude-regexp (language identifier)
  "Return a regexp to match lines to exclude for LANGUAGE and IDENTIFIER.")

(cl-defmethod aho-jump-xref-exclude-regexp (_language _identifier)
  "By default no match is excluded."
  nil)

(cl-defmethod aho-jump-xref-exclude-regexp ((_language (eql 'c)) identifier)
  "Regexp to exclude C expression keywords followed by IDENTIFIER."
  (concat "\\b\\(?:alignof\\|goto\\|return\\|sizeof\\|typeof\\|_Alignof\\)[ \t]+" identifier))

(cl-defmethod aho-jump-xref-exclude-regexp ((_language (eql 'c++)) identifier)
  "Regexp to exclude C++ expression keywords followed by IDENTIFIER."
  (concat "\\b\\(?:alignof\\|co_return\\|delete\\|goto\\|return\\|sizeof\\|throw\\|typeof\\)[ \t]+" identifier))

(cl-defmethod aho-jump-xref-exclude-regexp ((_language (eql 'java)) identifier)
  "Regexp to exclude Java expression keywords followed by IDENTIFIER."
  (concat "\\b\\(?:return\\|throw\\)[ \t]+" identifier))

(cl-defmethod xref-backend-definitions ((_backend (eql aho-jump)) identifier)
  "Find definitions of IDENTIFIER."
  (unless (executable-find aho-jump-rg-executable)
    (user-error "Cannot find the ripgrep executable `%s'.  Adjust `aho-jump-rg-executable' if it is not on `exec-path'" aho-jump-rg-executable))
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
                  with exclude-re = (aho-jump-xref-exclude-regexp language ident-re)
                  for file = (match-string 1)
                  for line = (string-to-number (match-string 2))
                  for summary = (match-string 4)
                  for column = (or (string-match-p ident-re summary) (1- (string-to-number (match-string 3))))
                  for location = (xref-make-file-location (expand-file-name file) line column)
                  unless (and exclude-re (string-match-p exclude-re summary))
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
