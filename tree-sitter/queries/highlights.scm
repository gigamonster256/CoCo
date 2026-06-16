; Keywords
[
  "main"
  "function"
  "if"
  "then"
  "else"
  "fi"
  "while"
  "do"
  "od"
  "repeat"
  "until"
  "call"
  "return"
] @keyword

; Types
[
  "bool"
  "int"
  "float"
  "void"
] @type.builtin

; Boolean operators
[
  "and"
  "or"
  "not"
] @keyword.operator

; Boolean literals
[
  "true"
  "false"
] @boolean

; Literals
(integer_literal) @number
(float_literal) @number

; Comments
(comment) @comment

; Punctuation
[
  "(" ")"
  "{" "}"
  "[" "]"
  ";"
  "."
  ","
  ":"
] @punctuation.delimiter

; Operators
[
  "=" "+=" "-=" "*=" "/=" "%=" "^="
  "++" "--"
  "+" "-" "*" "/" "%" "^"
  "==" "!=" "<" "<=" ">" ">="
] @operator

; Identifiers in declarations
(variable_declaration name: (identifier) @variable)
(parameter_declaration name: (identifier) @variable.parameter)
(function_declaration name: (identifier) @function)
(function_call name: (identifier) @function.call)
(designator name: (identifier) @variable)
