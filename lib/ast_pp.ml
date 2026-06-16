open Ast
open Symbol_table

let indent n = String.make (2 * n) ' '

let builtin_sig = function
  | "printInt" -> Some ("int", "void")
  | "printFloat" -> Some ("float", "void")
  | "printBool" -> Some ("bool", "void")
  | "println" -> Some ("", "void")
  | "readInt" -> Some ("", "int")
  | "readFloat" -> Some ("", "float")
  | "readBool" -> Some ("", "bool")
  | _ -> None
;;

let rec pp_expr env n e =
  match e with
  | Binary (l, op, r) ->
    let name =
      match op with
      | Add -> "Addition"
      | Sub -> "Subtraction"
      | Mul -> "Multiplication"
      | Div -> "Division"
      | Mod -> "Modulo"
      | Pow -> "Power"
      | And -> "LogicalAnd"
      | Or -> "LogicalOr"
      | Eq -> "Relation[==]"
      | Neq -> "Relation[!=]"
      | Lt -> "Relation[<]"
      | Le -> "Relation[<=]"
      | Gt -> "Relation[>]"
      | Ge -> "Relation[>=]"
    in
    name
    ^ "\n"
    ^ indent (n + 1)
    ^ pp_expr env (n + 1) l
    ^ "\n"
    ^ indent (n + 1)
    ^ pp_expr env (n + 1) r
  | Not e -> "LogicalNot\n" ^ indent (n + 1) ^ pp_expr env (n + 1) e
  | Literal lit ->
    (match lit with
     | IntLit i -> "IntegerLiteral[" ^ string_of_int i ^ "]"
     | FloatLit f -> "FloatLiteral[" ^ string_of_float f ^ "]"
     | BoolLit b -> "BoolLiteral[" ^ string_of_bool b ^ "]")
  | Var d -> pp_designator env n d
  | Call (name, args) ->
    let sig_str =
      match builtin_sig name with
      | Some (params, ret) ->
        let params_str = if params = "" then "" else params in
        "(" ^ params_str ^ ")->" ^ ret
      | None ->
        (match resolve_call env name args with
         | Some s ->
           let params_str = String.concat "," s.params in
           "("
           ^ params_str
           ^ ")->"
           ^
             (match s.ret with
             | Some t -> string_of_base_type t
             | None -> "void")
         | None -> "(?)->?")
    in
    "FunctionCall["
    ^ name
    ^ ":"
    ^ sig_str
    ^ "]\n"
    ^ indent (n + 1)
    ^ "ArgumentList"
    ^
    if args <> []
    then
      "\n"
      ^ String.concat
          "\n"
          (List.map (fun a -> indent (n + 2) ^ pp_expr env (n + 2) a) args)
    else ""

and pp_designator env n d =
  let name =
    match lookup_var env d.name with
    | Some ty -> d.name ^ ":" ^ ty
    | None -> d.name ^ ":?"
  in
  if d.indices = []
  then name
  else (
    let count = List.length d.indices in
    let rev_idxs = List.rev d.indices in
    let rec build i = function
      | [] -> indent (n + count) ^ name
      | idx :: rest ->
        let inner = build (i + 1) rest in
        (if i = 0 then "" else indent (n + i))
        ^ "ArrayIndex\n"
        ^ inner
        ^ "\n"
        ^ indent (n + i + 1)
        ^ pp_expr env (n + i + 1) idx
    in
    build 0 rev_idxs)
;;

let rec pp_stmt env n s =
  match s with
  | Assign (d, AssignValue (SimpleAssign, e)) ->
    "Assignment\n"
    ^ indent (n + 1)
    ^ pp_designator env (n + 1) d
    ^ "\n"
    ^ indent (n + 1)
    ^ pp_expr env (n + 1) e
  | Assign (d, AssignValue (AddAssign, e)) ->
    "Assignment\n"
    ^ indent (n + 1)
    ^ pp_designator env (n + 1) d
    ^ "\n"
    ^ indent (n + 1)
    ^ "Addition\n"
    ^ indent (n + 2)
    ^ pp_designator env (n + 2) d
    ^ "\n"
    ^ indent (n + 2)
    ^ pp_expr env (n + 2) e
  | Assign (d, AssignValue (SubAssign, e)) ->
    "Assignment\n"
    ^ indent (n + 1)
    ^ pp_designator env (n + 1) d
    ^ "\n"
    ^ indent (n + 1)
    ^ "Subtraction\n"
    ^ indent (n + 2)
    ^ pp_designator env (n + 2) d
    ^ "\n"
    ^ indent (n + 2)
    ^ pp_expr env (n + 2) e
  | Assign (d, AssignValue (MulAssign, e)) ->
    "Assignment\n"
    ^ indent (n + 1)
    ^ pp_designator env (n + 1) d
    ^ "\n"
    ^ indent (n + 1)
    ^ "Multiplication\n"
    ^ indent (n + 2)
    ^ pp_designator env (n + 2) d
    ^ "\n"
    ^ indent (n + 2)
    ^ pp_expr env (n + 2) e
  | Assign (d, AssignValue (DivAssign, e)) ->
    "Assignment\n"
    ^ indent (n + 1)
    ^ pp_designator env (n + 1) d
    ^ "\n"
    ^ indent (n + 1)
    ^ "Division\n"
    ^ indent (n + 2)
    ^ pp_designator env (n + 2) d
    ^ "\n"
    ^ indent (n + 2)
    ^ pp_expr env (n + 2) e
  | Assign (d, AssignValue (ModAssign, e)) ->
    "Assignment\n"
    ^ indent (n + 1)
    ^ pp_designator env (n + 1) d
    ^ "\n"
    ^ indent (n + 1)
    ^ "Modulo\n"
    ^ indent (n + 2)
    ^ pp_designator env (n + 2) d
    ^ "\n"
    ^ indent (n + 2)
    ^ pp_expr env (n + 2) e
  | Assign (d, AssignValue (PowAssign, e)) ->
    "Assignment\n"
    ^ indent (n + 1)
    ^ pp_designator env (n + 1) d
    ^ "\n"
    ^ indent (n + 1)
    ^ "Power\n"
    ^ indent (n + 2)
    ^ pp_designator env (n + 2) d
    ^ "\n"
    ^ indent (n + 2)
    ^ pp_expr env (n + 2) e
  | Assign (d, UnaryAssign Inc) ->
    "Assignment\n"
    ^ indent (n + 1)
    ^ pp_designator env (n + 1) d
    ^ "\n"
    ^ indent (n + 1)
    ^ "Addition\n"
    ^ indent (n + 2)
    ^ pp_designator env (n + 2) d
    ^ "\n"
    ^ indent (n + 2)
    ^ "IntegerLiteral[1]"
  | Assign (d, UnaryAssign Dec) ->
    "Assignment\n"
    ^ indent (n + 1)
    ^ pp_designator env (n + 1) d
    ^ "\n"
    ^ indent (n + 1)
    ^ "Subtraction\n"
    ^ indent (n + 2)
    ^ pp_designator env (n + 2) d
    ^ "\n"
    ^ indent (n + 2)
    ^ "IntegerLiteral[1]"
  | ExprStmt e -> pp_expr env n e
  | If (cond, then_body, else_body) ->
    "IfStatement\n"
    ^ indent (n + 1)
    ^ pp_expr env (n + 1) cond
    ^ "\n"
    ^ indent (n + 1)
    ^ "StatementSequence\n"
    ^ String.concat
        "\n"
        (List.map (fun s -> indent (n + 2) ^ pp_stmt env (n + 2) s) then_body)
    ^
      (match else_body with
      | Some stmts ->
        "\n"
        ^ indent (n + 1)
        ^ "StatementSequence\n"
        ^ String.concat
            "\n"
            (List.map (fun s -> indent (n + 2) ^ pp_stmt env (n + 2) s) stmts)
      | None -> "")
  | While (cond, body) ->
    "WhileStatement\n"
    ^ indent (n + 1)
    ^ pp_expr env (n + 1) cond
    ^ "\n"
    ^ indent (n + 1)
    ^ "StatementSequence\n"
    ^ String.concat
        "\n"
        (List.map (fun s -> indent (n + 2) ^ pp_stmt env (n + 2) s) body)
  | Repeat (body, cond) ->
    "RepeatStatement\n"
    ^ indent (n + 1)
    ^ "StatementSequence\n"
    ^ String.concat
        "\n"
        (List.map (fun s -> indent (n + 2) ^ pp_stmt env (n + 2) s) body)
    ^ "\n"
    ^ indent (n + 1)
    ^ pp_expr env (n + 1) cond
  | Return e ->
    "ReturnStatement"
    ^
      (match e with
      | Some e -> "\n" ^ indent (n + 1) ^ pp_expr env (n + 1) e
      | None -> "")
;;

let pp_decl n (td, names) =
  let ty = string_of_type_decl td in
  String.concat
    "\n"
    (List.map
       (fun name -> indent n ^ "VariableDeclaration[" ^ name ^ ":" ^ ty ^ "]")
       names)
;;

let pp_func_body env n (vars, stmts) =
  push_scope env;
  List.iter
    (fun (td, names) ->
       let ty = string_of_type_decl td in
       List.iter (fun name -> add_var env name ty) names)
    vars;
  let decls =
    if vars <> []
    then
      indent n
      ^ "DeclarationList\n"
      ^ String.concat "\n" (List.map (fun vd -> pp_decl (n + 1) vd) vars)
      ^ "\n"
    else ""
  in
  let result =
    decls
    ^ indent n
    ^ "StatementSequence\n"
    ^ String.concat
        "\n"
        (List.map (fun s -> indent (n + 1) ^ pp_stmt env (n + 1) s) stmts)
  in
  pop_scope env;
  result
;;

let pp_func_decl env n (name, params, ret, body) =
  push_scope env;
  List.iter
    (fun (pt, pname) -> add_var env pname (string_of_param_type pt))
    params;
  let ret_str =
    match ret with
    | Some t -> string_of_base_type t
    | None -> "void"
  in
  let params_str =
    List.map (fun (pt, _) -> string_of_param_type pt) params
    |> String.concat ","
  in
  let result =
    indent n
    ^ "FunctionDeclaration["
    ^ name
    ^ ":("
    ^ params_str
    ^ ")->"
    ^ ret_str
    ^ "]\n"
    ^ indent (n + 1)
    ^ "FunctionBody\n"
    ^ pp_func_body env (n + 2) body
  in
  pop_scope env;
  result
;;

let pp_computation ((vars, funcs, stmts) as comp) =
  let env = Symbol_table.build comp in
  let vars_section =
    if vars <> []
    then
      "\n  DeclarationList\n"
      ^ String.concat "\n" (List.map (fun vd -> pp_decl 2 vd) vars)
    else ""
  in
  let funcs_section =
    if funcs <> []
    then
      "\n  DeclarationList\n"
      ^ String.concat "\n" (List.map (fun fd -> pp_func_decl env 2 fd) funcs)
    else ""
  in
  let stmts_section =
    "\n  StatementSequence\n"
    ^ String.concat "\n" (List.map (fun s -> indent 2 ^ pp_stmt env 2 s) stmts)
  in
  "Computation[main:()->void]" ^ vars_section ^ funcs_section ^ stmts_section
;;
