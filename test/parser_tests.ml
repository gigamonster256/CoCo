open Coco

let%expect_test "parse word" =
  let input = "hello world" |> Parser.make in
  let hello = Parser.str "hello" in
  let result = hello.run input in
  match result with
  | _, Ok v ->
    print_endline ("Parsed: " ^ v);
    [%expect {| Parsed: hello |}]
  | _, Error e ->
    print_endline ("Error: " ^ e);
    [%expect.unreachable]
;;

let%expect_test "error missing word" =
  let input = "goodbye world" |> Parser.make in
  let hello = Parser.str "hello" in
  let result = hello.run input in
  match result with
  | _, Ok v ->
    print_endline ("Parsed: " ^ v);
    [%expect.unreachable]
  | _, Error e ->
    print_endline ("Error: " ^ e);
    [%expect {| Error: Expected 'hello' |}]
;;

let%expect_test "succeed" =
  let input = "anything" |> Parser.make in
  let p = Parser.succeed "success!" in
  let result = p.run input in
  match result with
  | _, Ok v ->
    print_endline ("Parsed: " ^ v);
    [%expect {| Parsed: success! |}]
  | _, Error e ->
    print_endline ("Error: " ^ e);
    [%expect.unreachable]
;;

let%expect_test "fail" =
  let input = "anything" |> Parser.make in
  let p = Parser.fail "failure!" in
  let result = p.run input in
  match result with
  | _, Ok v ->
    print_endline ("Parsed: " ^ v);
    [%expect.unreachable]
  | _, Error e ->
    print_endline ("Error: " ^ e);
    [%expect {| Error: failure! |}]
;;

let%expect_test "<|> first" =
  let input = "world" |> Parser.make in
  let p1 = Parser.str "hello" in
  let p2 = Parser.str "world" in
  let parser = Parser.( <|> ) p1 p2 in
  let result = parser.run input in
  match result with
  | _, Ok v ->
    print_endline ("Parsed: " ^ v);
    [%expect {| Parsed: world |}]
  | _, Error e ->
    print_endline ("Error: " ^ e);
    [%expect.unreachable]
;;

let%expect_test "<|> second" =
  let input = "hello" |> Parser.make in
  let p1 = Parser.str "hello" in
  let p2 = Parser.str "world" in
  let parser = Parser.( <|> ) p1 p2 in
  let result = parser.run input in
  match result with
  | _, Ok v ->
    print_endline ("Parsed: " ^ v);
    [%expect {| Parsed: hello |}]
  | _, Error e ->
    print_endline ("Error: " ^ e);
    [%expect.unreachable]
;;

let%expect_test "<|> both fail" =
  let input = "goodbye" |> Parser.make in
  let p1 = Parser.str "hello" in
  let p2 = Parser.str "world" in
  let parser = Parser.( <|> ) p1 p2 in
  let result = parser.run input in
  match result with
  | _, Ok v ->
    print_endline ("Parsed: " ^ v);
    [%expect.unreachable]
  | _, Error e ->
    print_endline ("Error: " ^ e);
    [%expect {| Error: Expected 'hello' or Expected 'world' |}]
;;

let%expect_test "first_of first" =
  let input = "hello" |> Parser.make in
  let p1 = Parser.str "hello" in
  let p2 = Parser.str "world" in
  let p3 = Parser.str "!" in
  let parser = Parser.first_of [ p1; p2; p3 ] in
  let result = parser.run input in
  match result with
  | _, Ok v ->
    print_endline ("Parsed: " ^ v);
    [%expect {| Parsed: hello |}]
  | _, Error e ->
    print_endline ("Error: " ^ e);
    [%expect.unreachable]
;;

let%expect_test "first_of second" =
  let input = "world" |> Parser.make in
  let p1 = Parser.str "hello" in
  let p2 = Parser.str "world" in
  let p3 = Parser.str "!" in
  let parser = Parser.first_of [ p1; p2; p3 ] in
  let result = parser.run input in
  match result with
  | _, Ok v ->
    print_endline ("Parsed: " ^ v);
    [%expect {| Parsed: world |}]
  | _, Error e ->
    print_endline ("Error: " ^ e);
    [%expect.unreachable]
;;

let%expect_test "first_of third" =
  let input = "!" |> Parser.make in
  let p1 = Parser.str "hello" in
  let p2 = Parser.str "world" in
  let p3 = Parser.str "!" in
  let parser = Parser.first_of [ p1; p2; p3 ] in
  let result = parser.run input in
  match result with
  | _, Ok v ->
    print_endline ("Parsed: " ^ v);
    [%expect {| Parsed: ! |}]
  | _, Error e ->
    print_endline ("Error: " ^ e);
    [%expect.unreachable]
;;

let%expect_test "first_of all fail" =
  let input = "goodbye" |> Parser.make in
  let p1 = Parser.str "hello" in
  let p2 = Parser.str "world" in
  let p3 = Parser.str "!" in
  let parser = Parser.first_of [ p1; p2; p3 ] in
  let result = parser.run input in
  match result with
  | _, Ok v ->
    print_endline ("Parsed: " ^ v);
    [%expect.unreachable]
  | _, Error e ->
    print_endline ("Error: " ^ e);
    [%expect {| Error: Expected 'hello' or Expected 'world' or Expected '!' |}]
;;

let%expect_test "optional missing" =
  let input = "anything" |> Parser.make in
  let parser = Parser.optional (Parser.str "hello") in
  let result = parser.run input in
  match result with
  | _, Ok (Some v) ->
    print_endline ("Parsed: " ^ v);
    [%expect.unreachable]
  | _, Ok None ->
    print_endline ("Parsed: " ^ "None");
    [%expect {| Parsed: None |}]
  | _, Error e ->
    print_endline ("Error: " ^ e);
    [%expect.unreachable]
;;

let%expect_test "optional present" =
  let input = "hello" |> Parser.make in
  let parser = Parser.optional (Parser.str "hello") in
  let result = parser.run input in
  match result with
  | _, Ok (Some v) ->
    print_endline ("Parsed: " ^ v);
    [%expect {| Parsed: hello |}]
  | _, Ok None ->
    print_endline ("Parsed: " ^ "None");
    [%expect.unreachable]
  | _, Error e ->
    print_endline ("Error: " ^ e);
    [%expect.unreachable]
;;

let char c t = Parser.char c |> Parser.map @@ Fun.const t
let equals = char '=' Token.Eq
let less_than = char '<' Token.Lt

let maximal p1 p2 m =
  Parser.maximal_munch p1 p2
  |> Parser.map (function
    | _, Some _ -> m
    | m, None -> m)
;;
let leq = maximal less_than equals Token.Le
