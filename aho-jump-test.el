;;; aho-jump-test.el --- Tests for aho-jump -*- lexical-binding: t -*-

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
          "main () {"
          "char main = NULL;"
          "int main(int *arg) const {"
          "unsigned long long int main = 123;"
          "struct main {"
          "typedef int (*main)(int)"
          "static int main(int argc, char **argv) {"
          "static char* main(const char* soname) {"
          "static char **main(const char* soname) {"
          "static char** main(const char* soname) {"
          "typedef struct node main;"
          "int main;"
          "intmax_t main;"
          "char *main;"
          "int main[10];"
          "int (*main)(int);"
          "struct main __attribute__((packed)) {")
  :no-match ("if (main == 0)"
             "if( main() ) {"
             "union main var;"
             "int *mainptr;"
             "int mymain = 1;"
             "main2();"
             "static char* main2(const char* soname) {"
             "main()"
             "--main=1"
             "# main = 1"
             "// main = 1"
             "/* main = 1 */"
             "msg = \"main = 1\""
             "msg = 'main = 1'"
             "\tmain (old_buffer);"
             "other->main = config().main;"
             "struct main x = {0};"
             "return main;"
             "x = *main(p);"
             "if (main (overlay_limit) < main (proplimit))"
             "main (AREF (vector, 5)),"))

(aho-jump-test-match c++
  :match ("class main : public std::vector<int> {"
          "constexpr float main(float x, int n) {"
          "namespace main {"
          "namespace foo::main {"
          "template <typename T> concept main = requires(T t) { t.foo(); };"
          "struct main : public base {"
          "struct main final : public base {"
          "enum class main : int {"
          "using main = std::vector<int>;"
          "std::string main;"
          "std::vector<int> main;"
          "std::map<std::string, std::vector<int>> main;"
          "extern thread_local std::function<bool()> main;"
          "thread_local std::function<bool()> main;"
          "static thread_local std::string main;"
          "extern thread_local std::atomic_unsigned_lock_free::value_type main;"
          "std::atomic_unsigned_lock_free::value_type main;"
          "std::vector<int> main(int x) { return {}; }"
          "int foo::main(int x) { return x; }"
          "template <typename T> void main (T x) { }")
  :no-match ("namespace main2 {}"
             "enum class main2 : int {"
             "other->main = config().main;"
             "foo::main = 5;"
             "foo::main;"
             "std::atomic_unsigned_lock_free::main = 5;"
             "void foo(int main, int x);"
             "x = foo::main(y);"))

(aho-jump-test-match javascript
  :match ("let main = 123;"
          "const main: number = 123;"
          "function main() {"
          "async main(foo: number): Promise<void> {"
          "const main = () => {"
          "export class main {}"
          "function* main() {"
          "const main = async () => {}"
          "export default function main() {"
          "main = (x) => x"
          "obj.main = () => {}"
          "main: (props) => {}"
          "main(obj) {")
  :no-match ("if (main === 123) {"
             "function Main() {"
             "const main2 = () => {}"
             "const b = (a: A, main: B) => {"
             "const f = (main: B) => {"
             "main(obj);"
             "main(obj).then(() => {})"
             "msg = \"main = (x) => x\""
             "msg = \"main() {\""
             "foo(main = (x) => x)"
             "// main = (x) => x"))

(aho-jump-test-match typescript
  :match ("const main: React.FC<Props> = (props) => {"
          "enum main { A }"
          "namespace main {}"
          "type main = string"
          "interface main {}")
  :no-match ("type main2 = string"
             "interface mainAlias {}"
             "type main,"
             "import { type main } from 'package';"))

(aho-jump-test-match python
  :match ("main = 123"
          "main := 123"
          "main: Any = None"
          "a, main = 1, 2"
          "(a, main) = 1, 2"
          "(main, b) = 1, 2"
          "x = 1; a, main = 2"
          "class main: ..."
          "class main(Protocol[T]): ..."
          "def main[T](x: T) -> T: ..."
          "class main[T]: ...")
  :no-match ("if main == 123:"
             "if main:"
             "d[\"main\"]: 1"
             "d['main']: 1"
             "main(id=id)"
             "\"--main=unstable\""
             "f\"{main}\", other=x"
             "main: str,"
             "with http_server(app, main=main) as httpd:"
             "foo(app, main=2)"
             "def http_server(app: web.Application, main: int = 0, ssl_context: ssl.SSLContext | None = None):"
             "def foo(app, main: int = 0):"
             "def foo(main: int = 0):"
             "# main = 1"
             "// main = 1"
             "/* main = 1 */"
             "msg = `main = 1`"))

(aho-jump-test-match rust
  :match ("let main = 123;"
          "let main: Vec<u32> = Vec::new();"
          "let mut main: Vec<u32> = Vec::new();"
          "let (mut a, mut main): (u32, usize) = (1, 2);"
          "if let Some(main) = foo() {"
          "fn main(value: i32) {"
          "static mut main: i32 = 123;"
          "static main: i32 = 1;"
          "const main: i32 = 1;"
          "macro_rules! main {"
          "pub mod main {"
          "impl main {"
          "impl std::io::Read for abc::main {"
          "union main {")
  :no-match ("macro_rules! maint {"
             "union main2 {"
             "fn main2() {}"
             "let poll_main = || main_flag.load();"
             "let pkgs: main<String> ="))

(aho-jump-test-match sh
  :match ("main () {"
          "function main {"
          "local main=123"
          "declare -r main=123"
          "export main=1"
          "readonly main")
  :no-match ("local localmain=123"
             "if [[ $main == 123 ]]; then"
             "echo main"
             "function main2 {"
             "--main=1"
             "-main=1"
             "msg = \"main() {\""
             "msg = \"main = 1\""))

(aho-jump-test-match scheme
  :match ("(define main 123)"
          "(define (main)"
          "(define* main 123)"               ; Guile
          "(define-public main"              ; Guile
          "(define* (main #:key (source #f)" ; Guile
          "(define-record-type main"         ; SRFI-9
          "(define-syntax main"
          "(define main)")
  :no-match ("(define main' 123)"
             "(define main-number 123)"
             "(define (main-alist store)"
             "(define main2 123)"))

(aho-jump-test-match racket
  :match ("(struct main (id))"
          "(struct main)")
  :no-match ("(struct main-point (x y))"
             "(struct main2)"))

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
          "val rec main = fn x => x"
          "type main = int"
          "type 'a main = 'a list")
  :no-match ("fun main' msg ="
             "val main' = ref n"
             "type main2 = int"))

(aho-jump-test-match sql
  :match ("CREATE TABLE main ("
          "Create Table If Not Exists main ("
          "CREATE VIEW main ("
          "create type main"
          "CREATE OR REPLACE TYPE main AS TABLE OF VARCHAR2(15);" ; Oracle
          "CREATE OR REPLACE function main (i integer)"
          "CREATE PROCEDURE main(a integer, b integer)"
          "CREATE FUNCTION main(i int)"
          "CREATE INDEX main ON users(id)"
          "CREATE TRIGGER main BEFORE INSERT ON users"
          "CREATE SEQUENCE main START WITH 1"
          "CREATE MATERIALIZED VIEW main AS SELECT 1"
          "CREATE TABLE schema.main (id int)")
  :no-match ("CREATE TABLE Main ("
             "SELECT main FROM users"))

(aho-jump-test-match lean
  :match ("def main := 123"
          "theorem main : 0 = 1 := Eq.refl 0"
          "lemma main : 0 = 1 := by simp"
          "structure main where"
          "opaque main : Nat"
          "abbrev main := 1"
          "instance main : Add Nat where"))

(aho-jump-test-match lisp
  :match ("(defvar main"
          "(defmacro main (id))")
  :no-match ("(defparameter main-"
             "(defun main-point (x y))"))

(aho-jump-test-match elisp
  :match ("(defvar main"
          "(defvar main)"
          "(cl-deftype main (&optional bits)"
          "(defalias 'main 'foo)"
          "(setq main 1)"
          "(cl-defstruct (main (:constructor make-main))")
  :no-match ("(defcustom main-foo 123"
             "(defclass main?"
             "(defun main2 (x))"
             "(setq 'main 1)"))

(aho-jump-test-match go
  :match ("var main = 123"
          "var main int = 123"
          "main := 123"
          "type main struct {"
          "type main interface {"
          "type main = string"
          "type main[T any] struct {"
          "const main = iota"
          "func main(url string) (string, error)"
          "func (c *Config) main(database string) *Client {")
  :no-match ("if main == 123 {"
             "type mainMap map[string]int"
             "main2 = 1"
             "let main2 = 1"
             "--main=1"
             "// main = 1"
             "/* main = 1 */"
             "msg = `main = 1`"
             "obj.main = 1"))

(aho-jump-test-match java
  :match ("public class main implements Fruit"
          "int[] main = {1, 2, 3};"
          "private static final Set<String> main = "
          "public static void main(String[] args) {"
          "@Override public String main() {"
          "record main(int x) {}"
          "public <T> T main(T value) {"
          "void main(String... args) {"
          "Map<String, Integer> main() {")
  :no-match ("if main == 123:"
             "x < main (to);"
             "--main=1"
             "# main = 1"
             "// main = 1"
             "/* main = 1 */"
             "obj.main = 1"))

(aho-jump-test-match just
  :match ("alias main := lint"
          "main: build"
          "main *OPTIONS: (build OPTIONS)")
  :no-match ("main-test: build"
             "install *main: (build main)"
             "main2: build"))

(aho-jump-test-match kotlin
  :match ("fun main(args: Array<String>) {"
          "val main: Int = 7"
          "enum class main(val value: Int) {"
          "typealias main = (Int, String, Any) -> Unit"
          "interface main<in T> {"
          "fun <T> main(list: List<T>, threshold: T): List<String>"
          "fun String.main(args: Array<String>) {"
          "fun <T> String.main(list: List<T>): List<String>"
          "val String.main: Int")
  :no-match ("fun main2() {}"))

(aho-jump-test-match lua
  :match ("main = 123"
          "function main ()"
          "function M.main()"
          "function M:main()")
  :no-match ("if main === 123"
             "tmain = function()"
             "function main-point()"
             "--main=1"
             "// main = 1"
             "/* main = 1 */"))

(aho-jump-test-match nix
  :match (" main = 123;"
          " main ="
          "inherit main;"
          "inherit (pkgs) main;")
  :no-match (" tmain = 123;"
             " t-main = 123"
             "if main == null then"
             "inherit main2;"
             "# main = 1"
             "--main=1"
             "msg = \"main = 1\""
             "obj.main = 1"
             "xmain = 1"
             "foo(main=1)"))

(aho-jump-test-match makefile
  :match ("main  = 123"
          "main := 123"
          "main: build"
          "export main := 123"
          "override main = 123"
          "define main")
  :no-match ("mainflags = 123"
             "mainflags: build"))

(aho-jump-test-match markdown
  :match ("<h1 id=\"main\">"
          "[^main]: footnote text"
          "[main]: https://example.com"
          "{#main}")
  :no-match ("[main](https://example.com)"
             "the main thing"))

(aho-jump-test-match typst
  :match ("#let main = 123"
          "#let main(x, y) = x + y"
          "= Heading #label(\"main\")")
  :no-match ("#let main-radius = 123"
             "if main == 123 {"))

(aho-jump-test-match terraform
  :match ("variable \"main\" {"
          "main = \"t2.large\""
          "output \"main\" {"
          "module \"main\" {"
          "resource \"aws_instance\" \"main\" {"))

(aho-jump-test-match swift
  :match ("let main: Double = 0"
          "func main(_ str: String) -> String {"
          "enum main: CaseIterable {"
          "typealias main = Int"
          "func String.main() -> String"
          "actor main {")
  :no-match ("if main == 123"
             "func main2() {}"))

(aho-jump-test-match org
  :match ("#+name: main"
          "#+Name:  main"
          ":CUSTOM_ID: main"))

(aho-jump-test-match zig
  :match ("var main: i32 = 1;"
          "pub fn main() void {"
          "pub const main: i32 = 1;"))

(provide 'aho-jump-test)
;;; aho-jump-test.el ends here
