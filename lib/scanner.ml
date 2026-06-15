type t =
  { src : string
  ; pos : int
  }

let init src = { src; pos = 0 }

let peek st =
  if st.pos < String.length st.src then Some st.src.[st.pos] else None
;;
let adv st = st.src.[st.pos], { st with pos = st.pos + 1 }

let eat p st =
  let start = st.pos in
  let rec loop st =
    match peek st with
    | Some c when p c -> loop (snd (adv st))
    | _ -> st
  in
  let st' = loop st in
  String.sub st.src start (st'.pos - start), st'
;;

let rec skip_ws st =
  match peek st with
  | Some (' ' | '\t' | '\n' | '\r') -> skip_ws (snd (adv st))
  | _ -> st
;;

let rec next st =
  let len = String.length st.src in
  let st = skip_ws st in
  if st.pos >= len
  then None, st
  else (
    let c = st.src.[st.pos] in
    if (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z')
    then (
      let s, st =
        eat
          (fun c ->
             (c >= 'a' && c <= 'z')
             || (c >= 'A' && c <= 'Z')
             || (c >= '0' && c <= '9')
             || c = '_')
          st
      in
      ( Some
          (try List.assoc s Token.kw with
           | Not_found -> Token.Id s)
      , st ))
    else if
      (c >= '0' && c <= '9')
      || (c = '-'
          && st.pos + 1 < len
          && st.src.[st.pos + 1] >= '0'
          && st.src.[st.pos + 1] <= '9')
    then (
      let s, st =
        eat (fun c -> (c >= '0' && c <= '9') || c = '.' || c = '-') st
      in
      if String.contains s '.'
      then Some (Token.FloatVal (float_of_string s)), st
      else Some (Token.IntVal (int_of_string s)), st)
    else if c = '/'
    then (
      let _, st = adv st in
      match peek st with
      | Some '/' ->
        let _, st = eat (fun c -> c <> '\n') st in
        next st
      | Some '=' -> Some Token.DivAssign, snd (adv st)
      | Some '*' ->
        let _, st = adv st in
        let rec skip_block st =
          if st.pos >= len
          then st
          else (
            let c, st = adv st in
            if c = '*' && peek st = Some '/'
            then snd (adv st)
            else skip_block st)
        in
        next (skip_block st)
      | _ -> Some Token.Div, st)
    else (
      let _, st = adv st in
      let tok, st =
        match c with
        | '(' -> Token.Lparen, st
        | ')' -> Token.Rparen, st
        | '{' -> Token.Lbrace, st
        | '}' -> Token.Rbrace, st
        | '[' -> Token.Lbrack, st
        | ']' -> Token.Rbrack, st
        | ',' -> Token.Comma, st
        | ':' -> Token.Colon, st
        | ';' -> Token.Semi, st
        | '.' -> Token.Period, st
        | '+' ->
          begin match peek st with
          | Some '=' -> Token.AddAssign, snd (adv st)
          | Some '+' -> Token.Inc, snd (adv st)
          | _ -> Token.Add, st
          end
        | '-' ->
          begin match peek st with
          | Some '=' -> Token.SubAssign, snd (adv st)
          | Some '-' -> Token.Dec, snd (adv st)
          | _ -> Token.Sub, st
          end
        | '*' ->
          begin match peek st with
          | Some '=' -> Token.MulAssign, snd (adv st)
          | _ -> Token.Mul, st
          end
        | '%' ->
          begin match peek st with
          | Some '=' -> Token.ModAssign, snd (adv st)
          | _ -> Token.Mod, st
          end
        | '^' ->
          begin match peek st with
          | Some '=' -> Token.PowAssign, snd (adv st)
          | _ -> Token.Pow, st
          end
        | '=' ->
          begin match peek st with
          | Some '=' -> Token.Eq, snd (adv st)
          | _ -> Token.Assign, st
          end
        | '!' ->
          begin match peek st with
          | Some '=' -> Token.Neq, snd (adv st)
          | _ -> failwith "stray !"
          end
        | '<' ->
          begin match peek st with
          | Some '=' -> Token.Le, snd (adv st)
          | _ -> Token.Lt, st
          end
        | '>' ->
          begin match peek st with
          | Some '=' -> Token.Ge, snd (adv st)
          | _ -> Token.Gt, st
          end
        | _ -> failwith (Printf.sprintf "unexpected char: %c" c)
      in
      Some tok, st))
;;

let scan src =
  let rec loop st acc =
    match next st with
    | None, _ -> List.rev @@ (Token.Eof :: acc)
    | Some tok, st -> loop st (tok :: acc)
  in
  loop (init src) []
;;
