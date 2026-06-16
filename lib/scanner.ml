open Parser

type t = input

let init = make

let is_letter c = (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z')
let is_digit c = c >= '0' && c <= '9'

let skip_ws =
  let* _ = take_while (fun c -> c = ' ' || c = '\t' || c = '\n' || c = '\r') in
  succeed ()
;;

let identifier =
  let* first = satisfy is_letter in
  let* rest = take_while (fun c -> is_letter c || is_digit c || c = '_') in
  let name = String.make 1 first ^ rest in
  try succeed (List.assoc name Token.kw) with
  | Not_found -> succeed (Token.Id name)
;;

let number =
  let* first =
    char '-' *> satisfy is_digit
    |> map (fun d -> "-" ^ String.make 1 d)
    <|> (satisfy is_digit |> map (String.make 1))
  in
  let* rest = take_while (fun c -> is_digit c || c = '.') in
  let s = first ^ rest in
  match String.index_opt s '.' with
  | Some i when i = String.length s - 1 -> succeed Token.Error
  | Some _ -> succeed (Token.FloatVal (float_of_string s))
  | None -> succeed (Token.IntVal (int_of_string s))
;;

let line_comment =
  let* _ = str "//" in
  let* _ = take_while (fun c -> c <> '\n') in
  succeed ()
;;

let block_comment =
  let* _ = str "/*" in
  let* _ = take_until "*/" in
  let* _ = optional (str "*/") in
  succeed ()
;;

let div_ops =
  str "/=" |> map (Fun.const (Token.DivAssign))
  <|> line_comment
  <|> block_comment
  <|> (char '/' |> map (Fun.const Token.Div))
;;

let op2 s tok = str s |> map (fun _ -> Some tok)
let op1 c tok = char c |> map (fun _ -> Some tok)

let operators =
  first_of
    [ op2 "+=" Token.AddAssign
    ; op2 "++" Token.Inc
    ; op1 '+' Token.Add
    ; op2 "-=" Token.SubAssign
    ; op2 "--" Token.Dec
    ; op1 '-' Token.Sub
    ; op2 "*=" Token.MulAssign
    ; op1 '*' Token.Mul
    ; op2 "%=" Token.ModAssign
    ; op1 '%' Token.Mod
    ; op2 "^=" Token.PowAssign
    ; op1 '^' Token.Pow
    ; op2 "==" Token.Eq
    ; op1 '=' Token.Assign
    ; op2 "!=" Token.Neq
    ; op2 "<=" Token.Le
    ; op1 '<' Token.Lt
    ; op2 ">=" Token.Ge
    ; op1 '>' Token.Gt
    ]
;;

let delimiters =
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

let token =
  identifier
  |> map (fun t -> Some t)
  <|> (number |> map (fun t -> Some t))
  <|> div_ops
  <|> operators
  <|> delimiters
  <|> satisfy (Fun.const true) *> succeed (Some Token.Error)
;;

let rec next st =
  let st' = fst (skip_ws.run st) in
  if st'.pos >= String.length st'.src
  then None, st'
  else (
    match token.run st' with
    | st'', Ok None -> next st''
    | st'', Ok (Some tok) -> Some tok, st''
    | _, Error _ -> None, st')
;;

let scan src =
  let rec loop st acc =
    match next st with
    | None, _ -> List.rev (Token.Eof :: acc)
    | Some tok, st -> loop st (tok :: acc)
  in
  loop (make src) []
;;
