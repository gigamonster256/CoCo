type t =
  | And | Or | Not
  | Pow | Mul | Div | Mod | Add | Sub
  | Eq | Neq | Lt | Le | Gt | Ge
  | Assign | AddAssign | SubAssign | MulAssign | DivAssign | ModAssign | PowAssign
  | Inc | Dec
  | Void | Bool | Int | Float
  | True | False
  | Lparen | Rparen | Lbrace | Rbrace | Lbrack | Rbrack
  | Comma | Colon | Semi | Dot
  | If | Then | Else | Fi | While | Do | Od | Repeat | Until
  | Call | Return | Main | Func
  | IntVal of int | FloatVal of float | Id of string
  | Eof

let to_string = function
  | And -> "and" | Or -> "or" | Not -> "not" | Pow -> "^" | Mul -> "*"
  | Div -> "/" | Mod -> "%" | Add -> "+" | Sub -> "-"
  | Eq -> "==" | Neq -> "!=" | Lt -> "<" | Le -> "<=" | Gt -> ">" | Ge -> ">="
  | Assign -> "=" | AddAssign -> "+=" | SubAssign -> "-=" | MulAssign -> "*="
  | DivAssign -> "/=" | ModAssign -> "%=" | PowAssign -> "^="
  | Inc -> "++" | Dec -> "--"
  | Void -> "void" | Bool -> "bool" | Int -> "int" | Float -> "float"
  | True -> "true" | False -> "false"
  | Lparen -> "(" | Rparen -> ")" | Lbrace -> "{" | Rbrace -> "}"
  | Lbrack -> "[" | Rbrack -> "]" | Comma -> "," | Colon -> ":"
  | Semi -> ";" | Dot -> "."
  | If -> "if" | Then -> "then" | Else -> "else" | Fi -> "fi"
  | While -> "while" | Do -> "do" | Od -> "od"
  | Repeat -> "repeat" | Until -> "until"
  | Call -> "call" | Return -> "return" | Main -> "main" | Func -> "function"
  | IntVal n -> string_of_int n
  | FloatVal f -> string_of_float f
  | Id s -> s
  | Eof -> "EOF"

let kw = [
  "and",And; "or",Or; "not",Not; "void",Void; "bool",Bool;
  "int",Int; "float",Float; "true",True; "false",False;
  "if",If; "then",Then; "else",Else; "fi",Fi;
  "while",While; "do",Do; "od",Od; "repeat",Repeat; "until",Until;
  "call",Call; "return",Return; "main",Main; "function",Func;
]
