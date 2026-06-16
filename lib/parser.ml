type input = { src : string }
type 'a t = { run : input -> input * ('a, string) result }

let make src = { src }

let fail msg = { run = (fun input -> input, Error msg) }
let succeed v = { run = (fun input -> input, Ok v) }
let pure = succeed

let map f m =
  { run =
      (fun input ->
        let input, res = m.run input in
        match res with
        | Ok v -> input, Ok (f v)
        | Error e -> input, Error e)
  }
;;

let bind m f =
  { run =
      (fun input ->
        let input, res = m.run input in
        match res with
        | Ok v -> (f v).run input
        | Error e -> input, Error e)
  }
;;
let ( >>= ) = bind
let ( let* ) = bind
let ( let+ ) m f = map f m

let pair p1 p2 =
  let* v1 = p1 in
  let* v2 = p2 in
  succeed (v1, v2)
;;
let ( <*> ) = pair
let ( and* ) = pair

let ( and+ ) = ( and* )

let ( *> ) p1 p2 =
  let* _ = p1 in
  p2
;;

let ( <* ) p1 p2 =
  let+ v = p1
  and+ _ = p2 in
  v
;;

let ( <|> ) p1 p2 =
  { run =
      (fun input ->
        match p1.run input with
        | input', Ok v -> input', Ok v
        | _, Error e1 ->
          (match p2.run input with
           | input', Ok v -> input', Ok v
           | _, Error e2 -> input, Error (e1 ^ " or " ^ e2)))
  }
;;

let first_of = function
  | [] -> fail "No parsers provided"
  | p :: ps -> List.fold_left ( <|> ) p ps
;;

let str prefix =
  { run =
      (fun input ->
        if String.starts_with ~prefix input.src
        then (
          let len = String.length prefix in
          ( { src = String.sub input.src len (String.length input.src - len) }
          , Ok prefix ))
        else input, Error ("Expected '" ^ prefix ^ "'"))
  }
;;

let char c =
  { run =
      (fun input ->
        try
          if String.get input.src 0 = c
          then
            { src = String.sub input.src 1 (String.length input.src - 1) }, Ok c
          else input, Error ("Expected '" ^ Char.escaped c ^ "'")
        with
        | Invalid_argument _ -> input, Error "unexpected end of input")
  }
;;

let satisfy pred =
  { run =
      (fun input ->
        try
          if String.get input.src 0 |> pred
          then
            ( { src = String.sub input.src 1 (String.length input.src - 1) }
            , Ok (String.get input.src 0) )
          else input, Error "Unexpected character"
        with
        | Invalid_argument _ -> input, Error "unexpected end of input")
  }
;;

let many p =
  let rec loop acc input =
    match p.run input with
    | input, Ok v -> loop (v :: acc) input
    | _ -> input, Ok (List.rev acc)
  in
  { run = loop [] }
;;

let at_least n p =
  let rec loop acc input =
    if List.length acc >= n
    then input, Ok (List.rev acc)
    else (
      match p.run input with
      | input', Ok v -> loop (v :: acc) input'
      | _ ->
        input, Error ("Expected at least " ^ string_of_int n ^ " occurrences"))
  in
  { run = loop [] }
;;

let many1 l = at_least 1 l

let take_while pred =
  { run =
      (fun input ->
        try
          let len = String.length input.src in
          let rec loop pos =
            if pos < len && pred input.src.[pos] then loop (pos + 1) else pos
          in
          let stop = loop 0 in
          let consumed = stop in
          ( { src = String.sub input.src consumed (len - consumed) }
          , Ok (String.sub input.src 0 consumed) )
        with
        | Invalid_argument _ -> input, Error "unexpected end of input")
  }
;;

let take_while1 pred =
  let* s = take_while pred in
  if String.length s > 0
  then succeed s
  else fail "Expected at least one character satisfying the predicate"
;;

let at_most n p =
  let rec loop acc input =
    if List.length acc >= n
    then input, Ok (List.rev acc)
    else (
      match p.run input with
      | input', Ok v -> loop (v :: acc) input'
      | _ -> input, Ok (List.rev acc))
  in
  { run = loop [] }
;;

let backtrack p =
  { run =
      (fun input ->
        match p.run input with
        | _, Error e -> input, Error e
        | ok -> ok)
  }
;;

let optional p =
  { run =
      (fun input ->
        match (backtrack p).run input with
        | input', Ok v -> input', Ok (Some v)
        | _ -> input, Ok None)
  }
;;

let maximal_munch prefix rest =
  let* p = prefix in
  let* r = optional rest in
  succeed (p, r)
;;

let take_until s =
  { run =
      (fun input ->
        let src = input.src in
        let src_len = String.length src in
        let s_len = String.length s in
        if s_len = 0
        then input, Ok ""
        else (
          let rec find pos =
            if pos + s_len > src_len
            then None
            else if String.sub src pos s_len = s
            then Some pos
            else find (pos + 1)
          in
          match find 0 with
          | Some idx ->
            ( { src = String.sub src idx (src_len - idx) }
            , Ok (String.sub src 0 idx) )
          | None -> input, Error ("Could not find '" ^ s ^ "'")))
  }
;;
