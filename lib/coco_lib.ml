(* CoCo Parser and Interpreter *)

include Token
include Scanner

(* ---- AST types ---- *)

type value =
  | VInt of int
  | VFloat of float
  | VBool of bool
  | VVoid
type value =
  | VInt of int
  | VFloat of float
  | VBool of bool
  | VVoid

let show_value = function
  | VInt n -> Printf.sprintf "(VInt %d)" n
  | VFloat f -> Printf.sprintf "(VFloat %f)" f
  | VBool b -> Printf.sprintf "(VBool %b)" b
  | VVoid -> "VVoid"
;;

let pp_value fmt v = Format.fprintf fmt "%s" (show_value v)

type expr =
  | ELit of value
  | EVar of string
  | ENot of expr
  | EBin of expr * Token.t * expr
  | ECall of string * expr list

type assign_op =
  | A_ASSIGN
  | A_ADD
  | A_SUB
  | A_MUL
  | A_DIV
  | A_MOD
  | A_POW
type unary_op =
  | U_INC
  | U_DEC

type stmt =
  | SAssign of string * assign_op * expr
  | SUnary of string * unary_op
  | SCall of string * expr list
  | SIf of expr * stmt list * stmt list
  | SWhile of expr * stmt list
  | SRepeat of stmt list * expr

(* ---- Parser ---- *)

let parse tokens =
  let arr = Array.of_list tokens in
  let i = ref 0 in
  let peek () = arr.(!i) in
  let adv () =
    let t = arr.(!i) in
    incr i;
    t
  in
  let expect tok =
    if peek () = tok
    then ignore (adv ())
    else
      failwith
        (Printf.sprintf
           "expected %s, got %s"
           (to_string tok)
           (to_string (peek ())))
  in
  let accept tok =
    if peek () = tok
    then (
      ignore (adv ());
      true)
    else false
  in
  let is_id () =
    match peek () with
    | Id _ -> true
    | _ -> false
  in
  let is_type () =
    match peek () with
    | Int | Bool | Float | Void -> true
    | _ -> false
  in

  let rec rel_expr () =
    let e = add_expr () in
    match peek () with
    | Eq | Neq | Lt | Le | Gt | Ge ->
      let op = adv () in
      EBin (e, op, add_expr ())
    | _ -> e
  and add_expr () =
    let rec loop e =
      match peek () with
      | Add | Sub | Or ->
        let op = adv () in
        loop (EBin (e, op, mult_expr ()))
      | _ -> e
    in
    loop (mult_expr ())
  and mult_expr () =
    let rec loop e =
      match peek () with
      | Mul | Div | Mod | And ->
        let op = adv () in
        loop (EBin (e, op, pow_expr ()))
      | _ -> e
    in
    loop (pow_expr ())
  and pow_expr () =
    let e = unary () in
    if peek () = Pow
    then (
      ignore (adv ());
      EBin (e, Pow, pow_expr ()))
    else e
  and unary () =
    match peek () with
    | Not ->
      ignore (adv ());
      ENot (unary ())
    | Sub ->
      ignore (adv ());
      begin match peek () with
      | IntVal n ->
        ignore (adv ());
        ELit (VInt (-n))
      | FloatVal f ->
        ignore (adv ());
        ELit (VFloat (-.f))
      | _ -> EBin (ELit (VInt 0), Sub, unary ())
      end
    | _ -> primary ()
  and primary () =
    match peek () with
    | IntVal n ->
      ignore (adv ());
      ELit (VInt n)
    | FloatVal f ->
      ignore (adv ());
      ELit (VFloat f)
    | True ->
      ignore (adv ());
      ELit (VBool true)
    | False ->
      ignore (adv ());
      ELit (VBool false)
    | Id s ->
      ignore (adv ());
      if accept Lbrack
      then (
        ignore (rel_expr ());
        expect Rbrack);
      EVar s
    | Lparen ->
      ignore (adv ());
      let e = rel_expr () in
      expect Rparen;
      e
    | Call ->
      ignore (adv ());
      let name =
        match peek () with
        | Id s ->
          ignore (adv ());
          s
        | _ -> failwith "expected id"
      in
      expect Lparen;
      let args =
        if accept Rparen
        then []
        else (
          let a = rel_expr () in
          let rec loop acc =
            if accept Comma
            then loop (rel_expr () :: acc)
            else List.rev (a :: acc)
          in
          let args = loop [] in
          expect Rparen;
          args)
      in
      ECall (name, args)
    | _ -> failwith "expected expression"
  in

  let rec statement () =
    match peek () with
    | Id name ->
      ignore (adv ());
      if accept Lbrack
      then (
        ignore (rel_expr ());
        expect Rbrack;
        let op =
          match adv () with
          | Assign -> A_ASSIGN
          | AddAssign -> A_ADD
          | SubAssign -> A_SUB
          | MulAssign -> A_MUL
          | DivAssign -> A_DIV
          | ModAssign -> A_MOD
          | PowAssign -> A_POW
          | _ -> failwith "unexpected assign op"
        in
        ignore (rel_expr ());
        SAssign (name, op, ELit VVoid))
      else if accept Inc
      then SUnary (name, U_INC)
      else if accept Dec
      then SUnary (name, U_DEC)
      else (
        let op =
          match adv () with
          | Assign -> A_ASSIGN
          | AddAssign -> A_ADD
          | SubAssign -> A_SUB
          | MulAssign -> A_MUL
          | DivAssign -> A_DIV
          | ModAssign -> A_MOD
          | PowAssign -> A_POW
          | _ -> failwith "unexpected assign op"
        in
        SAssign (name, op, rel_expr ()))
    | Call ->
      ignore (adv ());
      let name =
        match peek () with
        | Id s ->
          ignore (adv ());
          s
        | _ -> failwith "id"
      in
      expect Lparen;
      let args =
        if accept Rparen
        then []
        else (
          let a = rel_expr () in
          let rec loop acc =
            if accept Comma
            then loop (rel_expr () :: acc)
            else List.rev (a :: acc)
          in
          let args = loop [] in
          expect Rparen;
          args)
      in
      SCall (name, args)
    | If ->
      ignore (adv ());
      expect Lparen;
      let c = rel_expr () in
      expect Rparen;
      expect Then;
      let th = stat_seq () in
      let el = if accept Else then stat_seq () else [] in
      expect Fi;
      SIf (c, th, el)
    | While ->
      ignore (adv ());
      expect Lparen;
      let c = rel_expr () in
      expect Rparen;
      expect Do;
      let b = stat_seq () in
      expect Od;
      SWhile (c, b)
    | Repeat ->
      ignore (adv ());
      let b = stat_seq () in
      expect Until;
      expect Lparen;
      let c = rel_expr () in
      expect Rparen;
      SRepeat (b, c)
    | Return ->
      ignore (adv ());
      ignore (rel_expr ());
      SCall ("return", [])
    | _ -> failwith "expected statement"
  and stat_seq () =
    let stmts = ref [] in
    stmts := statement () :: !stmts;
    expect Semi;
    while
      match peek () with
      | Id _ | Call | If | While | Repeat | Return -> true
      | _ -> false
    do
      stmts := statement () :: !stmts;
      expect Semi
    done;
    List.rev !stmts
  in

  (* Skip declarations, parse main body *)
  expect Main;
  while is_type () && not (peek () = Void) do
    ignore (adv ());
    while accept Lbrack do
      ignore (rel_expr ());
      expect Rbrack
    done;
    while is_id () || accept Comma do
      if is_id () then ignore (adv ())
    done;
    expect Semi
  done;
  while accept Func do
    if is_id () then ignore (adv ());
    expect Lparen;
    while not (accept Rparen) do
      if accept Comma
      then ()
      else begin
        if is_type () then ignore (adv ());
        while accept Lbrack do
          expect Rbrack
        done;
        if is_id () then ignore (adv ())
      end
    done;
    expect Colon;
    if is_type () then ignore (adv ());
    expect Lbrace;
    while not (accept Rbrace) do
      ignore (statement ());
      expect Semi
    done;
    expect Semi
  done;
  expect Lbrace;
  let body = stat_seq () in
  expect Rbrace;
  expect Dot;
  body
;;

(* ---- Interpreter ---- *)

let string_of_value = function
  | VInt n -> string_of_int n
  | VFloat f -> Printf.sprintf "%.2f" f
  | VBool b -> string_of_bool b
  | VVoid -> "void"
;;

let rec eval env e =
  match e with
  | ELit v -> v
  | EVar n ->
    (try List.assoc n !env with
     | Not_found -> VInt 0)
  | ENot e ->
    (match eval env e with
     | VBool b -> VBool (not b)
     | _ -> failwith "not: expected bool")
  | EBin (l, op, r) -> binop (eval env l) op (eval env r)
  | ECall (n, args) -> builtin n (List.map (eval env) args)

and binop a op b =
  let fail_op () = failwith "type error in binop" in
  match a, b with
  | VInt x, VInt y ->
    begin match op with
    | Add -> VInt (x + y)
    | Sub -> VInt (x - y)
    | Mul -> VInt (x * y)
    | Div -> VInt (x / y)
    | Mod -> VInt (x mod y)
    | Pow -> VInt (int_of_float (Float.pow (float_of_int x) (float_of_int y)))
    | Eq -> VBool (x = y)
    | Neq -> VBool (x <> y)
    | Lt -> VBool (x < y)
    | Le -> VBool (x <= y)
    | Gt -> VBool (x > y)
    | Ge -> VBool (x >= y)
    | _ -> fail_op ()
    end
  | VFloat x, VFloat y ->
    begin match op with
    | Add -> VFloat (x +. y)
    | Sub -> VFloat (x -. y)
    | Mul -> VFloat (x *. y)
    | Div -> VFloat (x /. y)
    | Mod -> VFloat (Float.rem x y)
    | Pow -> VFloat (Float.pow x y)
    | Eq -> VBool (x = y)
    | Neq -> VBool (x <> y)
    | Lt -> VBool (x < y)
    | Le -> VBool (x <= y)
    | Gt -> VBool (x > y)
    | Ge -> VBool (x >= y)
    | _ -> fail_op ()
    end
  | VBool x, VBool y ->
    begin match op with
    | And -> VBool (x && y)
    | Or -> VBool (x || y)
    | Pow -> VBool (x <> y)
    | Eq -> VBool (x = y)
    | Neq -> VBool (x <> y)
    | _ -> fail_op ()
    end
  | _ -> fail_op ()

and builtin name args =
  match name, args with
  | "printInt", [ VInt n ] -> VInt n
  | "return", _ -> VVoid
  | _ -> VVoid
;;

let run source =
  try
    let tokens = Scanner.scan source in
    let stmts = parse tokens in
    let env = ref [] in
    let buf = Buffer.create 256 in

    let rec exec stmts =
      List.iter
        (fun s ->
           match s with
           | SAssign (n, A_ASSIGN, e) ->
             let v = eval env e in
             env := (n, v) :: List.remove_assoc n !env
           | SAssign (n, A_ADD, e) ->
             let old =
               try List.assoc n !env with
               | Not_found -> VInt 0
             in
             let v = binop old Add (eval env e) in
             env := (n, v) :: List.remove_assoc n !env
           | SAssign (n, A_SUB, e) ->
             let old =
               try List.assoc n !env with
               | Not_found -> VInt 0
             in
             let v = binop old Sub (eval env e) in
             env := (n, v) :: List.remove_assoc n !env
           | SAssign (n, A_MUL, e) ->
             let old =
               try List.assoc n !env with
               | Not_found -> VInt 0
             in
             let v = binop old Mul (eval env e) in
             env := (n, v) :: List.remove_assoc n !env
           | SAssign (n, A_DIV, e) ->
             let old =
               try List.assoc n !env with
               | Not_found -> VInt 0
             in
             let v = binop old Div (eval env e) in
             env := (n, v) :: List.remove_assoc n !env
           | SAssign (n, A_MOD, e) ->
             let old =
               try List.assoc n !env with
               | Not_found -> VInt 0
             in
             let v = binop old Mod (eval env e) in
             env := (n, v) :: List.remove_assoc n !env
           | SAssign (n, A_POW, e) ->
             let old =
               try List.assoc n !env with
               | Not_found -> VInt 0
             in
             let v = binop old Pow (eval env e) in
             env := (n, v) :: List.remove_assoc n !env
           | SUnary (n, U_INC) ->
             let old =
               try List.assoc n !env with
               | Not_found -> VInt 0
             in
             let v = binop old Add (VInt 1) in
             env := (n, v) :: List.remove_assoc n !env
           | SUnary (n, U_DEC) ->
             let old =
               try List.assoc n !env with
               | Not_found -> VInt 0
             in
             let v = binop old Sub (VInt 1) in
             env := (n, v) :: List.remove_assoc n !env
           | SCall (n, args) ->
             let vs = List.map (eval env) args in
             output_call buf n vs
           | SIf (c, th, el) ->
             begin match eval env c with
             | VBool true -> exec th
             | VBool false -> exec el
             | _ -> failwith "if: expected bool"
             end
           | SWhile (c, b) ->
             let rec loop () =
               match eval env c with
               | VBool true ->
                 exec b;
                 loop ()
               | VBool false -> ()
               | _ -> failwith "while: expected bool"
             in
             loop ()
           | SRepeat (b, c) ->
             let rec loop () =
               exec b;
               match eval env c with
               | VBool true -> ()
               | VBool false -> loop ()
               | _ -> failwith "until: expected bool"
             in
             loop ())
        stmts
    and output_call buf name args =
      match name, args with
      | "printInt", [ VInt n ] ->
        Buffer.add_string buf (string_of_int n);
        Buffer.add_char buf ' '
      | "printInt", [ v ] ->
        Buffer.add_string buf (string_of_value v);
        Buffer.add_char buf ' '
      | "printFloat", [ VFloat f ] ->
        Buffer.add_string buf (Printf.sprintf "%.2f " f)
      | "printFloat", [ v ] ->
        Buffer.add_string buf (string_of_value v);
        Buffer.add_char buf ' '
      | "printBool", [ VBool b ] ->
        Buffer.add_string buf (string_of_bool b);
        Buffer.add_char buf ' '
      | "printBool", [ v ] ->
        Buffer.add_string buf (string_of_value v);
        Buffer.add_char buf ' '
      | "println", [] -> Buffer.add_char buf '\n'
      | "readInt", [] -> ()
      | "readFloat", [] -> ()
      | "readBool", [] -> ()
      | "return", _ -> ()
      | n, a ->
        failwith
          ("unknown function: "
           ^ n
           ^ " with "
           ^ string_of_int (List.length a)
           ^ " args")
    in
    exec stmts;
    Buffer.contents buf
  with
  | Failure msg -> "Error: " ^ msg
  | e -> "Error: " ^ Printexc.to_string e
;;
