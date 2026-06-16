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
  | Period
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
  | Error

let to_string =
  let tsv a b = a ^ "\t" ^ b in
  function
  | And -> "and"
  | Or -> "or"
  | Not -> "not"
  | Pow -> "^"
  | Mul -> "*"
  | Div -> "/"
  | Mod -> "%"
  | Add -> "ADD"
  | Sub -> "SUB"
  | Eq -> "EQUAL_TO"
  | Neq -> "NOT_EQUAL_TO"
  | Lt -> "LESS_THAN"
  | Le -> "LESS_EQUAL"
  | Gt -> "GREATER_THAN"
  | Ge -> "GREATER_EQUAL"
  | Assign -> "ASSIGN"
  | AddAssign -> "ADD_ASSIGN"
  | SubAssign -> "SUB_ASSIGN"
  | MulAssign -> "MUL_ASSIGN"
  | DivAssign -> "DIV_ASSIGN"
  | ModAssign -> "MOD_ASSIGN"
  | PowAssign -> "POW_ASSIGN"
  | Inc -> "UNI_INC"
  | Dec -> "UNI_DEC"
  | Void -> "void"
  | Bool -> "bool"
  | Int -> "INT"
  | Float -> "FLOAT"
  | True -> "true"
  | False -> "false"
  | Lparen -> "OPEN_PAREN"
  | Rparen -> "CLOSE_PAREN"
  | Lbrace -> "OPEN_BRACE"
  | Rbrace -> "CLOSE_BRACE"
  | Lbrack -> "OPEN_BRACK"
  | Rbrack -> "CLOSE_BRACK"
  | Comma -> "COMMA"
  | Colon -> "COLON"
  | Semi -> "SEMICOLON"
  | Period -> "PERIOD"
  | If -> "IF"
  | Then -> "THEN"
  | Else -> "ELSE"
  | Fi -> "FI"
  | While -> "WHILE"
  | Do -> "DO"
  | Od -> "OD"
  | Repeat -> "REPEAT"
  | Until -> "UNTIL"
  | Call -> "CALL"
  | Return -> "RETURN"
  | Main -> "MAIN"
  | Func -> "FUNC"
  | IntVal n -> tsv "INT_VAL" @@ string_of_int n
  | FloatVal f -> tsv "FLOAT_VAL" @@ string_of_float f
  | Id s -> tsv "IDENT" s
  | Eof -> "EOF"
  | Error -> "ERROR"
;;

let show t = to_string t
let pp fmt t = Format.fprintf fmt "%s" (show t)

let kw =
  [ "and", And
  ; "or", Or
  ; "not", Not
  ; "void", Void
  ; "bool", Bool
  ; "int", Int
  ; "float", Float
  ; "true", True
  ; "false", False
  ; "if", If
  ; "then", Then
  ; "else", Else
  ; "fi", Fi
  ; "while", While
  ; "do", Do
  ; "od", Od
  ; "repeat", Repeat
  ; "until", Until
  ; "call", Call
  ; "return", Return
  ; "main", Main
  ; "function", Func
  ]
;;
