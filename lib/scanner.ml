open Parser

type t = input

let init = make

(* ===== §2.1 Whitespace (skipped between tokens) ===== *)

let is_ws c = c = ' ' || c = '\t' || c = '\n' || c = '\r'
let skip_ws =
  let* _ = take_while is_ws in
  succeed ()
;;

(* ===== §2.3 Identifiers ===== *)

(* letter = "a".."z" | "A".."Z" *)
let is_letter c = (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z')
let letter = satisfy is_letter

let is_digit c = c >= '0' && c <= '9'
let digit = satisfy is_digit

(* ident = letter { "_" | letter | digit } *)
let ident_str =
  let* first = letter in
  let underscore = char '_' in
  let* rest = many (underscore <|> letter <|> digit) in
  first :: rest |> List.to_seq |> String.of_seq |> succeed
;;

(* id_or_kw : ident_str → Token.t, checking §2.4 keyword table *)
let id_or_kw =
  let* name = ident_str in
  try succeed (List.assoc name Token.kw) with
  | Not_found -> succeed (Token.Id name)
;;

(* ===== §2.6 Literals ===== *)

(* integer_lit = ["-"] digit { digit } *)
let integer_lit_str =
  let* neg = optional (char '-') in
  let* digits = take_while1 is_digit in
  succeed
    (match neg with
     | Some _ -> "-" ^ digits
     | None -> digits)
;;

let integer_lit =
  let* s = integer_lit_str in
  succeed (Token.IntVal (int_of_string s))
;;

(* float_lit = integer_lit "." digit { digit } *)
(* §2.6: a float missing the fractional part (e.g. "-17.") is an ERROR *)
let float_lit =
  let* int_part = integer_lit_str in
  let* _ = char '.' in
  (let* frac = take_while1 (fun c -> c >= '0' && c <= '9') in
   let s = int_part ^ "." ^ frac in
   succeed (Token.FloatVal (float_of_string s)))
  <|> succeed Token.Error
;;

(* bool_lit = "true" | "false"     -- produced via keyword table in id_or_kw *)

(* literal = float_lit | integer_lit *)
let literal = float_lit <|> integer_lit

(* ===== §2.2 Comments ===== *)

(* line_comment = "//" { char ≠ '\n' } *)
let is_newline c = c = '\n'
let line_comment =
  let* _ = str "//" in
  let* _ = take_while (Fun.negate is_newline) in
  let* _ = optional @@ char '\n' in
  succeed ()
;;

(* block_comment = "/*" { char } "*/" *)
let block_comment =
  let* _ = str "/*" in
  let* _ = take_until "*/" in
  let* _ = optional @@ str "*/" in
  succeed ()
;;

(* comment = line_comment | block_comment *)
let comment = line_comment <|> block_comment

(* ===== §2.5 / §3.5 Operators ===== *)

let op2 s tok = str s |> map @@ Fun.const tok
let op1 c tok = char c |> map @@ Fun.const tok

(* rel_op = "==" | "!=" | "<" | "<=" | ">" | ">=" *)
let rel_op =
  first_of
    [ op2 "==" Token.Eq
    ; op2 "!=" Token.Neq
    ; op2 "<=" Token.Le
    ; op1 '<' Token.Lt
    ; op2 ">=" Token.Ge
    ; op1 '>' Token.Gt
    ]
;;

(* add_op = "+" | "-" *)
let add_op = first_of [ op1 '+' Token.Add; op1 '-' Token.Sub ]

(* mult_op = "*" | "/" | "%" *)
let mult_op =
  first_of [ op1 '*' Token.Mul; op1 '/' Token.Div; op1 '%' Token.Mod ]
;;

(* pow_op = "^" *)
let pow_op = op1 '^' Token.Pow

(* assign_op = "=" | "+=" | "-=" | "*=" | "/=" | "%=" | "^=" *)
let assign_op =
  first_of
    [ op2 "+=" Token.AddAssign
    ; op2 "-=" Token.SubAssign
    ; op2 "*=" Token.MulAssign
    ; op2 "/=" Token.DivAssign
    ; op2 "^=" Token.PowAssign
    ; op2 "%=" Token.ModAssign
    ; op1 '=' Token.Assign
    ]
;;

(* unary_op = "++" | "--" *)
let unary_op = first_of [ op2 "++" Token.Inc; op2 "--" Token.Dec ]

(* operator : ordered so multi-char and comment-introducing ops are tried first *)
let operator = first_of [ rel_op; unary_op; assign_op; add_op; mult_op; pow_op ]

(* ===== §2.5 Delimiters ===== *)

(* delimiter = "(" | ")" | "{" | "}" | "[" | "]" | "," | ":" | ";" | "." *)
let delimiter =
  first_of
    [ op1 '(' Token.Lparen
    ; op1 ')' Token.Rparen
    ; op1 '{' Token.Lbrace
    ; op1 '}' Token.Rbrace
    ; op1 '[' Token.Lbrack
    ; op1 ']' Token.Rbrack
    ; op1 ',' Token.Comma
    ; op1 ':' Token.Colon
    ; op1 ';' Token.Semi
    ; op1 '.' Token.Period
    ]
;;

(* ===== Top-level token ===== *)

(* token = id_or_kw | literal | operator | delimiter *)
let token = first_of [ id_or_kw; literal; operator; delimiter ]

let next_p = skip_ws *> many (comment *> skip_ws) *> token

(* ===== Scanner interface ===== *)
let next st =
  match next_p.run st with
  | st, Ok t -> Some t, st
  | _, Error _ -> None, st
;;

let scan src =
  let rec loop st acc =
    match next st with
    | None, _ -> Token.Eof :: acc
    | Some tok, st -> loop st @@ (tok :: acc)
  in
  loop (make src) [] |> List.rev
;;
