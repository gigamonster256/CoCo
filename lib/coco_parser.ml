open Token

type state =
  { tokens : Token.t array
  ; mutable pos : int
  }

let make tokens = { tokens = Array.of_list tokens; pos = 0 }

let peek st =
  if st.pos < Array.length st.tokens then st.tokens.(st.pos) else Eof
;;

let advance st =
  let t = peek st in
  if t <> Eof then st.pos <- st.pos + 1;
  t
;;

let expect st tok =
  let t = advance st in
  if t <> tok
  then
    failwith
      (Printf.sprintf "Expected %s but got %s" (Token.show tok) (Token.show t))
;;

let consume_if st tok =
  if peek st = tok
  then (
    advance st |> ignore;
    true)
  else false
;;

(* ---- Operator predicates ---- *)

let is_rel_op = function
  | Eq | Neq | Lt | Le | Gt | Ge -> true
  | _ -> false
;;
let is_add_op = function
  | Add | Sub | Or -> true
  | _ -> false
;;
let is_mult_op = function
  | Mul | Div | Mod | And -> true
  | _ -> false
;;

let is_assign_op = function
  | Assign
  | AddAssign
  | SubAssign
  | MulAssign
  | DivAssign
  | ModAssign
  | PowAssign -> true
  | _ -> false
;;

let is_unary_op = function
  | Inc | Dec -> true
  | _ -> false
;;

let can_start_expr = function
  | IntVal _ | FloatVal _ | True | False | Not | Lparen | Call | Id _ -> true
  | _ -> false
;;

(* ---- Token → AST conversions ---- *)

let rel_op_of = function
  | Eq -> Ast.Eq
  | Neq -> Ast.Neq
  | Lt -> Ast.Lt
  | Le -> Ast.Le
  | Gt -> Ast.Gt
  | Ge -> Ast.Ge
  | t -> failwith (Printf.sprintf "not a rel op: %s" (Token.show t))
;;

let add_op_of = function
  | Add -> Ast.Add
  | Sub -> Ast.Sub
  | Or -> Ast.Or
  | t -> failwith (Printf.sprintf "not an add op: %s" (Token.show t))
;;

let mult_op_of = function
  | Mul -> Ast.Mul
  | Div -> Ast.Div
  | Mod -> Ast.Mod
  | And -> Ast.And
  | t -> failwith (Printf.sprintf "not a mult op: %s" (Token.show t))
;;

let assign_op_of = function
  | Assign -> Ast.SimpleAssign
  | AddAssign -> Ast.AddAssign
  | SubAssign -> Ast.SubAssign
  | MulAssign -> Ast.MulAssign
  | DivAssign -> Ast.DivAssign
  | ModAssign -> Ast.ModAssign
  | PowAssign -> Ast.PowAssign
  | t -> failwith (Printf.sprintf "not an assign op: %s" (Token.show t))
;;

let unary_op_of = function
  | Inc -> Ast.Inc
  | Dec -> Ast.Dec
  | t -> failwith (Printf.sprintf "not a unary op: %s" (Token.show t))
;;

(* ---- Helpers ---- *)

let comma_sep p st =
  let rec loop acc =
    let x = p st in
    if peek st = Comma
    then (
      advance st |> ignore;
      loop (x :: acc))
    else List.rev (x :: acc)
  in
  loop []
;;

let base_type st =
  match advance st with
  | Bool -> Ast.Bool
  | Int -> Ast.Int
  | Float -> Ast.Float
  | t -> failwith (Printf.sprintf "Expected type but got %s" (Token.show t))
;;

let void_or_type st =
  if peek st = Void
  then (
    advance st |> ignore;
    None)
  else Some (base_type st)
;;

(* ---- Expression parsers (mutually recursive) ---- *)

(* groupExpr = literal | designator | "not" relExpr | relation | funcCall *)
let rec group_expr st =
  match peek st with
  | IntVal n ->
    advance st |> ignore;
    Ast.Literal (Ast.IntLit n)
  | FloatVal f ->
    advance st |> ignore;
    Ast.Literal (Ast.FloatLit f)
  | True ->
    advance st |> ignore;
    Ast.Literal (Ast.BoolLit true)
  | False ->
    advance st |> ignore;
    Ast.Literal (Ast.BoolLit false)
  | Not ->
    advance st |> ignore;
    Ast.Not (rel_expr st)
  | Lparen -> relation st
  | Call -> func_call st
  | Id _ -> Ast.Var (designator st)
  | t ->
    failwith (Printf.sprintf "Expected expression but got %s" (Token.show t))

(* relation = "(" relExpr ")" *)
and relation st =
  expect st Lparen;
  let e = rel_expr st in
  expect st Rparen;
  e

(* designator = ident { "[" relExpr "]" } *)
and designator st =
  let name =
    match advance st with
    | Id s -> s
    | t ->
      failwith (Printf.sprintf "Expected identifier, got %s" (Token.show t))
  in
  let rec loop acc =
    if peek st = Lbrack
    then (
      advance st |> ignore;
      let idx = rel_expr st in
      expect st Rbrack;
      loop (idx :: acc))
    else List.rev acc
  in
  { Ast.name; indices = loop [] }

(* funcCall = "call" ident "(" [ relExpr { "," relExpr } ] ")" *)
and func_call st =
  expect st Call;
  let name =
    match advance st with
    | Id s -> s
    | t ->
      failwith
        (Printf.sprintf "Expected identifier after call, got %s" (Token.show t))
  in
  expect st Lparen;
  let args = if peek st = Rparen then [] else comma_sep rel_expr st in
  expect st Rparen;
  Ast.Call (name, args)

(* powExpr = groupExpr { powOp groupExpr } *)
and pow_expr st =
  let lhs = group_expr st in
  let rec loop lhs =
    if peek st = Pow
    then (
      advance st |> ignore;
      loop (Ast.Binary (lhs, Ast.Pow, group_expr st)))
    else lhs
  in
  loop lhs

(* multExpr = powExpr { multOp powExpr } *)
and mult_expr st =
  let lhs = pow_expr st in
  let rec loop lhs =
    if is_mult_op (peek st)
    then (
      let op = mult_op_of (advance st) in
      loop (Ast.Binary (lhs, op, pow_expr st)))
    else lhs
  in
  loop lhs

(* addExpr = multExpr { addOp multExpr } *)
and add_expr st =
  let lhs = mult_expr st in
  let rec loop lhs =
    if is_add_op (peek st)
    then (
      let op = add_op_of (advance st) in
      loop (Ast.Binary (lhs, op, mult_expr st)))
    else lhs
  in
  loop lhs

(* relExpr = addExpr { relOp addExpr } *)
and rel_expr st =
  let lhs = add_expr st in
  let rec loop lhs =
    if is_rel_op (peek st)
    then (
      let op = rel_op_of (advance st) in
      loop (Ast.Binary (lhs, op, add_expr st)))
    else lhs
  in
  loop lhs
;;

(* ---- Statement parsers (mutually recursive) ---- *)

(* statement = assign | funcCall | ifStat | whileStat | repeatStat | returnStat *)
let rec statement st =
  match peek st with
  | If -> if_stat st
  | While -> while_stat st
  | Repeat -> repeat_stat st
  | Return -> return_stat st
  | Call -> Ast.ExprStmt (func_call st)
  | Id _ -> assign st
  | t ->
    failwith (Printf.sprintf "Expected statement but got %s" (Token.show t))

(* assign = designator ( assignOp relExpr | unaryOp ) *)
and assign st =
  let d = designator st in
  let tok = peek st in
  if is_assign_op tok
  then (
    let op = assign_op_of (advance st) in
    let rhs = rel_expr st in
    Ast.Assign (d, Ast.AssignValue (op, rhs)))
  else if is_unary_op tok
  then Ast.Assign (d, Ast.UnaryAssign (unary_op_of (advance st)))
  else
    failwith
      (Printf.sprintf "Expected assign/unary op, got %s" (Token.show tok))

(* ifStat = "if" relation "then" statSeq [ "else" statSeq ] "fi" *)
and if_stat st =
  expect st If;
  let cond = relation st in
  expect st Then;
  let then_body = stat_seq st [ Else; Fi ] in
  let else_body =
    if consume_if st Else then Some (stat_seq st [ Fi ]) else None
  in
  expect st Fi;
  Ast.If (cond, then_body, else_body)

(* whileStat = "while" relation "do" statSeq "od" *)
and while_stat st =
  expect st While;
  let cond = relation st in
  expect st Do;
  let body = stat_seq st [ Od ] in
  expect st Od;
  Ast.While (cond, body)

(* repeatStat = "repeat" statSeq "until" relation *)
and repeat_stat st =
  expect st Repeat;
  let body = stat_seq st [ Until ] in
  expect st Until;
  Ast.Repeat (body, relation st)

(* returnStat = "return" [ relExpr ] *)
and return_stat st =
  expect st Return;
  let e = if can_start_expr (peek st) then Some (rel_expr st) else None in
  Ast.Return e

(* statSeq = statement ";" { statement ";" } *)
and stat_seq st terminators =
  if List.mem (peek st) terminators
  then []
  else (
    let s = statement st in
    expect st Semi;
    s :: stat_seq st terminators)
;;

(* ---- Declaration parsers ---- *)

(* typeDecl = type { "[" integerLit "]" } *)
let type_decl st =
  let bt = base_type st in
  let rec loop acc =
    if peek st = Lbrack
    then (
      advance st |> ignore;
      let size =
        match advance st with
        | IntVal n -> n
        | t ->
          failwith
            (Printf.sprintf
               "Expected integer in array dim, got %s"
               (Token.show t))
      in
      expect st Rbrack;
      loop (size :: acc))
    else List.rev acc
  in
  bt, loop []
;;

(* paramType = type { "[" "]" } *)
let param_type st =
  let bt = base_type st in
  let rec loop acc =
    if peek st = Lbrack
    then (
      advance st |> ignore;
      expect st Rbrack;
      loop (acc + 1))
    else acc
  in
  bt, loop 0
;;

(* paramDecl = paramType ident *)
let param_decl st =
  let pt = param_type st in
  let name =
    match advance st with
    | Id s -> s
    | t ->
      failwith (Printf.sprintf "Expected parameter name, got %s" (Token.show t))
  in
  pt, name
;;

(* formalParam = "(" [ paramDecl { "," paramDecl } ] ")" *)
let formal_param st =
  expect st Lparen;
  let params = if peek st = Rparen then [] else comma_sep param_decl st in
  expect st Rparen;
  params
;;

(* varDecl = typeDecl ident { "," ident } ";" *)
let var_decl st =
  let td = type_decl st in
  let names =
    comma_sep
      (fun st ->
         match advance st with
         | Id s -> s
         | t ->
           failwith
             (Printf.sprintf "Expected variable name, got %s" (Token.show t)))
      st
  in
  expect st Semi;
  td, names
;;

let var_decls st =
  let can_start = function
    | Bool | Int | Float -> true
    | _ -> false
  in
  let rec loop acc =
    if can_start (peek st) then loop (var_decl st :: acc) else List.rev acc
  in
  loop []
;;

(* funcBody = "{" { varDecl } statSeq "}" ";" *)
let func_body st =
  expect st Lbrace;
  let vars = var_decls st in
  let body = stat_seq st [ Rbrace ] in
  expect st Rbrace;
  expect st Semi;
  vars, body
;;

(* funcDecl = "function" ident formalParam ":" ( "void" | type ) funcBody *)
let func_decl st =
  expect st Func;
  let name =
    match advance st with
    | Id s -> s
    | t ->
      failwith (Printf.sprintf "Expected function name, got %s" (Token.show t))
  in
  let params = formal_param st in
  expect st Colon;
  let ret = void_or_type st in
  let body = func_body st in
  name, params, ret, body
;;

let func_decls st =
  let rec loop acc =
    if peek st = Func then loop (func_decl st :: acc) else List.rev acc
  in
  loop []
;;

(* ---- Top-level ---- *)

(* computation = "main" { varDecl } { funcDecl } "{" statSeq "}" "." *)
let computation st =
  expect st Main;
  let vars = var_decls st in
  let funcs = func_decls st in
  expect st Lbrace;
  let body = stat_seq st [ Rbrace ] in
  expect st Rbrace;
  expect st Period;
  vars, funcs, body
;;

(* ---- Public API ---- *)

let parse tokens =
  let st = make tokens in
  let result = computation st in
  if peek st <> Eof
  then
    failwith
      (Printf.sprintf
         "Unexpected token after program end: %s"
         (Token.show (peek st)));
  result
;;
