open Ast

type func_sig =
  { params : string list
  ; ret : base_type option
  }

type t =
  { mutable scopes : (string * string) list list
  ; mutable funcs : (string * func_sig list) list
  }

let empty () = { scopes = []; funcs = [] }

let push_scope env = env.scopes <- [] :: env.scopes

let pop_scope env =
  match env.scopes with
  | _ :: rest -> env.scopes <- rest
  | [] -> failwith "pop empty scope"
;;

let add_var env name ty =
  match env.scopes with
  | scope :: rest -> env.scopes <- ((name, ty) :: scope) :: rest
  | [] -> env.scopes <- [ [ name, ty ] ]
;;

let add_func env name params_ty ret_ty =
  let sigs =
    try List.assoc name env.funcs with
    | Not_found -> []
  in
  let new_sig = { params = params_ty; ret = ret_ty } in
  env.funcs <- (name, new_sig :: sigs) :: List.remove_assoc name env.funcs
;;

let lookup_var env name =
  let rec search = function
    | [] -> None
    | scope :: rest ->
      (try Some (List.assoc name scope) with
       | Not_found -> search rest)
  in
  search env.scopes
;;

let resolve_call env name args =
  try
    let candidates = List.assoc name env.funcs in
    let arg_count = List.length args in
    let by_count =
      List.filter (fun s -> List.length s.params = arg_count) candidates
    in
    if arg_count = 0
    then (
      match by_count with
      | [] -> None
      | s :: _ -> Some s)
    else (
      match by_count with
      | [] -> None
      | [ s ] -> Some s
      | _ :: _ :: _ ->
        let arg_types =
          List.map
            (fun e ->
               match e with
               | Literal (IntLit _) -> "int"
               | Literal (FloatLit _) -> "float"
               | Literal (BoolLit _) -> "bool"
               | Var d ->
                 (match lookup_var env d.name with
                  | Some t -> t
                  | None -> "?")
               | _ -> "?")
            args
        in
        let rec find = function
          | [] -> Some (List.hd by_count)
          | s :: rest ->
            if List.for_all2 (fun a p -> a = p || a = "?") arg_types s.params
            then Some s
            else find rest
        in
        find by_count)
  with
  | Not_found -> None
;;

let string_of_param_type (bt, n) =
  let base =
    match bt with
    | Bool -> "bool"
    | Int -> "int"
    | Float -> "float"
  in
  if n = 0 then base else base ^ String.make n '[' ^ String.make n ']'
;;

let string_of_type_decl (bt, dims) =
  let base =
    match bt with
    | Bool -> "bool"
    | Int -> "int"
    | Float -> "float"
  in
  let rec loop acc = function
    | [] -> String.concat "" (List.rev acc)
    | d :: ds -> loop (("[" ^ string_of_int d ^ "]") :: acc) ds
  in
  base ^ loop [] dims
;;

let string_of_base_type = function
  | Bool -> "bool"
  | Int -> "int"
  | Float -> "float"
;;

let build (cvars, cfuncs, _cstmts) =
  let env = empty () in
  push_scope env;
  List.iter
    (fun (td, names) ->
       let ty = string_of_type_decl td in
       List.iter (fun name -> add_var env name ty) names)
    cvars;
  List.iter
    (fun (name, params, ret, _body) ->
       let param_tys =
         List.map (fun (pt, _) -> string_of_param_type pt) params
       in
       add_func env name param_tys ret)
    cfuncs;
  env
;;
