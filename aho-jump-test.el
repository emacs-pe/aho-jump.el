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
(require 'ert)
(require 'ert-x)
(require 'aho-jump)

(defsubst aho-jump-test-send-buffer (&rest args)
  "Send current buffer contents to ripgrep passing ARGS."
  (apply #'call-process-region (point-min) (point-max) aho-jump-rg-executable t t nil args))

(defmacro aho-jump-test-match (language &rest args)
  "Create ert test for LANGUAGE with ARGS."
  (declare (indent 1))
  `(progn
     (when-let* ((lines ',(plist-get args :match)))
       (ert-deftest ,(intern (format "match-refs-%s" language)) ()
         :tags '(match ,language)
         (dolist (line lines)
           (ert-with-test-buffer (:name (format "match-%s ｢ %s ｣" ',language line))
             (insert line)
             (should (zerop (apply #'aho-jump-test-send-buffer (aho-jump-command-args ,(or (plist-get args :identifier) "main") ',language))))
             (should (string-suffix-p (concat line "\n") (buffer-string)))))))


     (when-let* ((lines ',(plist-get args :no-match)))
       (ert-deftest ,(intern (format "not-match-refs-%s" language)) ()
         :tags '(not-match ,language)
         (dolist (line lines)
           (ert-with-test-buffer (:name (format "no-match-%s ｢ %s ｣" ',language line))
             (insert line)
             (should (= 1 (apply #'aho-jump-test-send-buffer (aho-jump-command-args ,(or (plist-get args :identifier) "main") ',language))))
             (should (zerop (buffer-size)))))))))

(aho-jump-test-match c
  :match ("int main(){"
          "typedef struct main {"
          "char *main = NULL;"
          "int main(int *arg) const {"
          "unsigned long long int main = 123;"
          "struct main {"
          "typedef int (*main)(int)")
  :no-match ("if (main == 0)"
             "if( main() ) {"
             "union main var;"))

(aho-jump-test-match c++
  :match ("class main : public std::vector<int> {"
          "constexpr float main(float x, int n) {"
          "int main(int *arg) const {"))

(aho-jump-test-match javascript
  :match ("let main = 123;"
          "const main: number = 123;"
          "function main() {"
          "async main () {"
          "async main(foo: number): Promise<void> {"
          "const main = () => {"
          "export class main {}")
  :no-match ("if (main === 123) {"
             "function Main() {"))

(aho-jump-test-match typescript
  :match ("const main: React.FC<Props> = (props) => {"))

(aho-jump-test-match python
  :match ("main = 123"
          "main := 123"
          "main: Any = None"
          "class main: ..."
          "class main(Protocol[T]): ...")
  :no-match ("if main == 123:"))

(aho-jump-test-match rust
  :match ("let main = 123;"
          "let main: Vec<u32> = Vec::new();"
          "let mut main: Vec<u32> = Vec::new();"
          "let (mut a, mut main): (u32, usize) = (1, 2);"
          "if let Some(main) = foo() {"
          "fn main(value: i32) {"
          "static mut main: i32 = 123;"
          "macro_rules! main {"
          "pub mod main {"
          "impl main {"
          "impl abc::main {"
          "impl std::io::Read for abc::main {")
  :no-match ("macro_rules! maint {"))

(aho-jump-test-match sh
  :match ("main () {"
          "function main() {"
          "local main=123"
          "declare -r main=123")
  :no-match ("local localmain=123"
             "if [[ $main == 123 ]]; then"))

(aho-jump-test-match scheme
  :match ("(define main 123)"
          "(define (main)"
          "(define* main 123)"               ; Guile
          "(define-public main"              ; Guile
          "(define* (main #:key (source #f)" ; Guile
          "(define-record-type main"         ; SRFI-9
          "(define-syntax main"
          "(define (main str . args)")
  :no-match ("(define main' 123)"
             "(define main-number 123)"
             "(define (main-alist store)"))

(aho-jump-test-match racket
  :match ("(struct main (id))")
  :no-match ("(struct main-point (x y))"))

(aho-jump-test-match sml
  :match ("fun main msg ="
          "fun main (msg, i) ="
          "val main : bool"
          "signature main ="
          "datatype main"
          "datatype 'a main"
          "functor main("
          "exception main of string"
          "structure main :> sig"
          "val main : 'a chan -> unit")
  :no-match ("fun main' msg ="
             "val main' = ref n"))

(aho-jump-test-match sql
  :match ("CREATE TABLE main ("
          "Create Table If Not Exists main ("
          "create function main(i int)"
          "CREATE VIEW main ("
          "create type main"
          "CREATE OR REPLACE TYPE main AS TABLE OF VARCHAR2(15);" ; Oracle
          "CREATE OR REPLACE function main (i integer)"
          "CREATE PROCEDURE main(a integer, b integer)"
          "CREATE FUNCTION main(i int)")
  :no-match ("CREATE TABLE Main ("))

(aho-jump-test-match lean
  :match ("def main := 123"
          "theorem main : 0 = 1 := Eq.refl 0"))

(aho-jump-test-match lisp
  :match ("(defvar main"
          "(defmacro main (id))"
          "(defclass main"
          "(defstruct main"
          "(define-symbol-macro main")
  :no-match ("(defparameter main-"
             "(defun main-point (x y))"))

(aho-jump-test-match elisp
  :match ("(defvar main 123)"
          "(defclass main"
          "(cl-deftype main (&optional bits)"
          "(cl-defmacro main (id))"
          "(defun main (id)"          )
  :no-match ("(defcustom main-foo 123"
             "(defclass main?"))

(aho-jump-test-match go
  :match ("var main = 123"
          "var main int = 123"
          "main := 123"
          "type main struct {"
          "type main interface {"
          "func main(url string) (string, error)"
          "func (c *Config) main(database string) *Client {")
  :no-match ("if main == 123 {"))

(aho-jump-test-match java
  :match ("public class main implements Fruit"
          "int[] main = {1, 2, 3};"
          "private static final Set<String> main = "
          "public static void main(String[] args) {")
  :no-match ("if main == 123:"))

(aho-jump-test-match just
  :match ("alias main := lint"
          "export main := '123'"
          "main: build"
          "main *OPTIONS: (build OPTIONS)")
  :no-match ("main-test: build"
             "install *main: (build main)"))

(aho-jump-test-match kotlin
  :match ("fun main(args: Array<String>) {"
          "val main: Int = 7"
          "enum class main(val value: Int) {"
          "typealias main = (Int, String, Any) -> Unit"
          "interface main<in T> {"
          "fun <T> main(list: List<T>, threshold: T): List<String>"))

(aho-jump-test-match lua
  :match ("main = 123"
          "main = function ()"
          "function main ()")
  :no-match ("if main === 123"
             "tmain = function()"))

(aho-jump-test-match nix
  :match (" main = 123;"
          " main =")
  :no-match (" tmain = 123;"
             " t-main = 123"
             "if main == null then"))

(aho-jump-test-match makefile
  :match ("main  = 123"
          "main := 123"
          "main: build")
  :no-match ("mainflags = 123"))

(aho-jump-test-match typst
  :match ("#let main = 123"
          "#let main(x, y) = x + y"
          "= Heading #label(\"main\")")
  :no-match ("#let main-radius = 123"
             "if main == 123 {"))

(aho-jump-test-match terraform
  :match ("variable \"main\" {"
          "main = \"t2.large\""))

(aho-jump-test-match swift
  :match ("let main: Double = 0"
          "func main(_ str: String) -> String {"
          "enum main: CaseIterable {"
          "typealias main = Int")
  :no-match ("if main == 123"))

(aho-jump-test-match org
  :match ("#+name: main"
          "#+Name:  main"
          ":CUSTOM_ID: main"))

(aho-jump-test-match zig
  :match ("var main: i32 = 1;"
          "pub fn main() void {"))

(provide 'aho-jump-test)
;;; aho-jump-test.el ends here
