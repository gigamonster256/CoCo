open Ast
open Symbol_table

(* ===== Formatting helpers ===== *)

let indent n = String.make (2 * n) ' '

let line n s = indent n ^ s

let node header children =
  match children with
  | [] -> header
  | _ -> header ^ "\n" ^ String.concat "\n" children
;;

let child n s = line n s

(* ===== Operator/builtin tables ===== *)

let binop_name = function
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
;;

let assign_op_name = function
  | AddAssign -> "Addition"
  | SubAssign -> "Subtraction"
  | MulAssign -> "Multiplication"
  | DivAssign -> "Division"
  | ModAssign -> "Modulo"
  | PowAssign -> "Power"
  | SimpleAssign -> assert false
;;

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

let format_sig params ret = "(" ^ params ^ ")->" ^ ret

let ret_to_string = function
  | Some t -> string_of_base_type t
  | None -> "void"
;;

(* ===== Expressions ===== *)

let rec pp_expr env n e =
  match e with
  | Binary (l, op, r) ->
    node
      (binop_name op)
      [ child (n + 1) (pp_expr env (n + 1) l)
      ; child (n + 1) (pp_expr env (n + 1) r)
      ]
  | Not e -> node "LogicalNot" [ child (n + 1) (pp_expr env (n + 1) e) ]
  | Literal (IntLit i) -> Printf.sprintf "IntegerLiteral[%d]" i
  | Literal (FloatLit f) -> Printf.sprintf "FloatLiteral[%f]" f
  | Literal (BoolLit b) -> Printf.sprintf "BoolLiteral[%b]" b
  | Var d -> pp_designator env n d
  | Call (name, args) -> pp_call env n name args

and pp_call env n name args =
  let sig_str =
    match builtin_sig name with
    | Some (params, ret) -> format_sig params ret
    | None ->
      (match resolve_call env name args with
       | Some s -> format_sig (String.concat "," s.params) (ret_to_string s.ret)
       | None -> "(?)->?")
  in
  let header = Printf.sprintf "FunctionCall[%s:%s]" name sig_str in
  let arg_list =
    if args = []
    then child (n + 1) "ArgumentList"
    else
      child (n + 1) "ArgumentList"
      ^ "\n"
      ^ String.concat
          "\n"
          (List.map (fun a -> child (n + 2) (pp_expr env (n + 2) a)) args)
  in
  node header [ arg_list ]

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
        (if i = 0 then "" else indent (n + i))
        ^ "ArrayIndex\n"
        ^ build (i + 1) rest
        ^ "\n"
        ^ indent (n + i + 1)
        ^ pp_expr env (n + i + 1) idx
    in
    build 0 rev_idxs)
;;

(* ===== Statements ===== *)

let rec pp_stmt env n s =
  let assignment d rhs_lines =
    node "Assignment" (child (n + 1) (pp_designator env (n + 1) d) :: rhs_lines)
  in
  let compound_assign d op_name e =
    assignment
      d
      [ child (n + 1) op_name
      ; child (n + 2) (pp_designator env (n + 2) d)
      ; child (n + 2) (pp_expr env (n + 2) e)
      ]
  in
  let inc_dec d op_name =
    assignment
      d
      [ child (n + 1) op_name
      ; child (n + 2) (pp_designator env (n + 2) d)
      ; child (n + 2) "IntegerLiteral[1]"
      ]
  in
  let stmt_seq lvl stmts =
    child lvl "StatementSequence"
    ^ "\n"
    ^ String.concat
        "\n"
        (List.map (fun s -> child (lvl + 1) (pp_stmt env (lvl + 1) s)) stmts)
  in
  match s with
  | Assign (d, AssignValue (SimpleAssign, e)) ->
    assignment d [ child (n + 1) (pp_expr env (n + 1) e) ]
  | Assign (d, AssignValue (op, e)) -> compound_assign d (assign_op_name op) e
  | Assign (d, UnaryAssign Inc) -> inc_dec d "Addition"
  | Assign (d, UnaryAssign Dec) -> inc_dec d "Subtraction"
  | ExprStmt e -> pp_expr env n e
  | If (cond, then_body, else_body) ->
    let base =
      [ child (n + 1) (pp_expr env (n + 1) cond); stmt_seq (n + 1) then_body ]
    in
    let extra =
      match else_body with
      | Some stmts -> [ stmt_seq (n + 1) stmts ]
      | None -> []
    in
    node "IfStatement" (base @ extra)
  | While (cond, body) ->
    node
      "WhileStatement"
      [ child (n + 1) (pp_expr env (n + 1) cond); stmt_seq (n + 1) body ]
  | Repeat (body, cond) ->
    node
      "RepeatStatement"
      [ stmt_seq (n + 1) body; child (n + 1) (pp_expr env (n + 1) cond) ]
  | Return e ->
    (match e with
     | Some e ->
       node "ReturnStatement" [ child (n + 1) (pp_expr env (n + 1) e) ]
     | None -> "ReturnStatement")
;;

(* ===== Declarations ===== *)

let pp_decl n (td, names) =
  let ty = string_of_type_decl td in
  String.concat
    "\n"
    (List.map
       (fun name ->
          line n (Printf.sprintf "VariableDeclaration[%s:%s]" name ty))
       names)
;;

let declare_vars env vars =
  List.iter
    (fun (td, names) ->
       let ty = string_of_type_decl td in
       List.iter (fun name -> add_var env name ty) names)
    vars
;;

let stmts_block env n stmts =
  line n "StatementSequence"
  ^ "\n"
  ^ String.concat
      "\n"
      (List.map (fun s -> line (n + 1) (pp_stmt env (n + 1) s)) stmts)
;;

let decls_block n vars =
  line n "DeclarationList"
  ^ "\n"
  ^ String.concat "\n" (List.map (pp_decl (n + 1)) vars)
;;

let pp_func_body env n (vars, stmts) =
  push_scope env;
  declare_vars env vars;
  let result =
    (if vars = [] then "" else decls_block n vars ^ "\n")
    ^ stmts_block env n stmts
  in
  pop_scope env;
  result
;;

let pp_func_decl env n (name, params, ret, body) =
  push_scope env;
  List.iter
    (fun (pt, pname) -> add_var env pname (string_of_param_type pt))
    params;
  let params_str =
    params
    |> List.map (fun (pt, _) -> string_of_param_type pt)
    |> String.concat ","
  in
  let header =
    Printf.sprintf
      "FunctionDeclaration[%s:%s]"
      name
      (format_sig params_str (ret_to_string ret))
  in
  let result =
    line n header
    ^ "\n"
    ^ line (n + 1) "FunctionBody"
    ^ "\n"
    ^ pp_func_body env (n + 2) body
  in
  pop_scope env;
  result
;;

(* ===== Top-level ===== *)

let pp_computation ((vars, funcs, stmts) as comp) =
  let env = Symbol_table.build comp in
  let section pp_items items =
    if items = []
    then ""
    else "\n" ^ line 1 "DeclarationList" ^ "\n" ^ pp_items items
  in
  let vars_section =
    section (fun vs -> String.concat "\n" (List.map (pp_decl 2) vs)) vars
  in
  let funcs_section =
    section
      (fun fs -> String.concat "\n" (List.map (pp_func_decl env 2) fs))
      funcs
  in
  let stmts_section =
    "\n"
    ^ line 1 "StatementSequence"
    ^ "\n"
    ^ String.concat "\n" (List.map (fun s -> line 2 (pp_stmt env 2 s)) stmts)
  in
  "Computation[main:()->void]" ^ vars_section ^ funcs_section ^ stmts_section
;;
