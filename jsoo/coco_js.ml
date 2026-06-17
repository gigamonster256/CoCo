open Js_of_ocaml

let pp_tokens tokens =
  tokens |> List.map (fun t -> Coco.Token.show t ^ "\n") |> String.concat ""
;;

let run source =
  let s = Js.to_string source in
  try
    let tokens = Coco.Scanner.scan s in
    let ast = Coco.Coco_parser.parse tokens in
    let result = Coco.Ast_pp.pp_computation ast in
    Js.string result
  with
  | Failure msg -> Js.string ("Parse error: " ^ msg)
  | e -> Js.string ("Error: " ^ Printexc.to_string e)
;;

let tokenize source =
  let s = Js.to_string source in
  try
    let tokens = Coco.Scanner.scan s in
    Js.string (pp_tokens tokens)
  with
  | Failure msg -> Js.string ("Lex error: " ^ msg)
  | e -> Js.string ("Error: " ^ Printexc.to_string e)
;;

let () =
  let export name f =
    Js.Unsafe.set Js.Unsafe.global name (Js.wrap_callback f)
  in
  export "cocoRun" run;
  export "cocoTokenize" tokenize
;;
