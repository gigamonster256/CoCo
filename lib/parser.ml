type input =
  { src : string
  ; pos : int
  }
type 'a t = { run : input -> input * ('a, string) result }

let make src = { src; pos = 0 }

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

let str s =
  let len = String.length s in
  { run =
      (fun input ->
        if String.length input.src < len
        then input, Error ("Expected '" ^ s ^ "' but got end of input")
        else if String.sub input.src input.pos len = s
        then { input with pos = input.pos + len }, Ok s
        else
          ( input
          , Error
              ("Expected '"
               ^ s
               ^ "' but got '"
               ^ String.sub input.src input.pos len
               ^ "'") ))
  }
;;

let char c =
  { run =
      (fun input ->
        if input.pos < String.length input.src && input.src.[input.pos] = c
        then { input with pos = input.pos + 1 }, Ok c
        else input, Error ("Expected '" ^ Char.escaped c ^ "'"))
  }
;;

let digit =
  { run =
      (fun input ->
        match String.get input.src input.pos with
        | c when c >= '0' && c <= '9' ->
          { input with pos = input.pos + 1 }, Ok c
        | _ -> input, Error "Expected a digit")
  }
;;

let many p =
  let rec loop acc input =
    match p.run input with
    | input', Ok v -> loop (v :: acc) input'
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
