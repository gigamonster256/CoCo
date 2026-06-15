let scan src =
  let len = String.length src in
  let i = ref 0 in
  let ts = ref [] in
  let peek () = if !i < len then Some src.[!i] else None in
  let adv () = let c = src.[!i] in incr i; c in
  let eat p =
    let b = Bytes.create 32 in
    let j = ref 0 in
    while (match peek () with Some c when p c -> true | _ -> false) do
      Bytes.set b !j (adv ()); incr j
    done;
    Bytes.sub_string b 0 !j
  in
  let push tok = ts := tok :: !ts in
  let rec skip_ws () =
    match peek () with
    | Some (' '|'\t'|'\n'|'\r') -> ignore (adv ()); skip_ws ()
    | _ -> ()
  in
  let rec next () =
    skip_ws ();
    match peek () with
    | None -> push Token.Eof
    | Some c when (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') ->
      let s = eat (fun c -> (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') || (c >= '0' && c <= '9') || c = '_') in
      push (try List.assoc s Token.kw with Not_found -> Token.Id s)
    | Some c when (c >= '0' && c <= '9') || (c = '-' && !i+1 < len && src.[!i+1] >= '0' && src.[!i+1] <= '9') ->
      let s = eat (fun c -> (c >= '0' && c <= '9') || c = '.' || c = '-') in
      if String.contains s '.' then
        push (Token.FloatVal (float_of_string s))
      else
        push (Token.IntVal (int_of_string s))
    | Some '/' ->
      ignore (adv ());
      begin match peek () with
      | Some '/' -> ignore (eat (fun c -> c <> '\n')); next ()
      | Some '=' -> ignore (adv ()); push Token.DivAssign
      | Some '*' ->
        ignore (adv ());
        let rec skip_block () =
          if !i >= len then ()
          else if adv () = '*' && (match peek () with Some '/' -> true | _ -> false) then
            ignore (adv ())
          else skip_block ()
        in
        skip_block (); next ()
      | _ -> push Token.Div
      end
    | Some c ->
      ignore (adv ());
      let k = match c with
        | '(' -> Token.Lparen | ')' -> Token.Rparen | '{' -> Token.Lbrace | '}' -> Token.Rbrace
        | '[' -> Token.Lbrack | ']' -> Token.Rbrack | ',' -> Token.Comma | ':' -> Token.Colon
        | ';' -> Token.Semi | '.' -> Token.Dot
        | '+' -> (match peek () with Some '=' -> ignore (adv ()); Token.AddAssign | Some '+' -> ignore (adv ()); Token.Inc | _ -> Token.Add)
        | '-' -> (match peek () with Some '=' -> ignore (adv ()); Token.SubAssign | Some '-' -> ignore (adv ()); Token.Dec | _ -> Token.Sub)
        | '*' -> (match peek () with Some '=' -> ignore (adv ()); Token.MulAssign | _ -> Token.Mul)
        | '%' -> (match peek () with Some '=' -> ignore (adv ()); Token.ModAssign | _ -> Token.Mod)
        | '^' -> (match peek () with Some '=' -> ignore (adv ()); Token.PowAssign | _ -> Token.Pow)
        | '=' -> (match peek () with Some '=' -> ignore (adv ()); Token.Eq | _ -> Token.Assign)
        | '!' -> (match peek () with Some '=' -> ignore (adv ()); Token.Neq | _ -> failwith "stray !")
        | '<' -> (match peek () with Some '=' -> ignore (adv ()); Token.Le | _ -> Token.Lt)
        | '>' -> (match peek () with Some '=' -> ignore (adv ()); Token.Ge | _ -> Token.Gt)
        | _ -> failwith (Printf.sprintf "unexpected char: %c" c)
      in
      push k
  in
  while !i < len do next () done;
  List.rev (Token.Eof :: !ts)
