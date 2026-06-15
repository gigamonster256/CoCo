type t =
  | And
  | Or
  | Not
  | Pow
  | Mul
  | Div
  | Mod
  | Add
  | Sub
  | Eq
  | Neq
  | Lt
  | Le
  | Gt
  | Ge
  | Assign
  | AddAssign
  | SubAssign
  | MulAssign
  | DivAssign
  | ModAssign
  | PowAssign
  | Inc
  | Dec
  | Void
  | Bool
  | Int
  | Float
  | True
  | False
  | Lparen
  | Rparen
  | Lbrace
  | Rbrace
  | Lbrack
  | Rbrack
  | Comma
  | Colon
  | Semi
  | Dot
  | If
  | Then
  | Else
  | Fi
  | While
  | Do
  | Od
  | Repeat
  | Until
  | Call
  | Return
  | Main
  | Func
  | IntVal of int
  | FloatVal of float
  | Id of string
  | Eof

val to_string : t -> string
val kw : (string * t) list
