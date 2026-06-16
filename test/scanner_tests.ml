open Coco

let show_tokens ts = List.iter (fun t -> print_endline (Token.show t)) ts

let scanner_test src =
  let src = In_channel.with_open_text ("scanner/" ^ src) In_channel.input_all in
  let tokens = Scanner.scan src in
  show_tokens tokens
;;

let%expect_test "skip whitespace" =
  let a, r = Scanner.skip_ws.run ("     hello" |> Parser.make) in
  match r with
  | Ok () ->
    print_endline a.src;
    [%expect {| hello |}]
  | Error e ->
    print_endline ("Error: " ^ e);
    [%expect.unreachable]
;;
let%expect_test "skip comment" =
  let a, r =
    Scanner.comment.run ("// this is a comment\nhello" |> Parser.make)
  in
  match r with
  | Ok () ->
    print_endline a.src;
    [%expect {| hello |}]
  | Error e ->
    print_endline ("Error: " ^ e);
    [%expect.unreachable]
;;

let%expect_test "scan empty file" =
  "" |> Scanner.scan |> show_tokens;
  [%expect {| EOF |}]
;;

let%expect_test "scan whitespace only" =
  " \t\n\r" |> Scanner.scan |> show_tokens;
  [%expect {| EOF |}]
;;

let%expect_test "scan comment only" =
  "// this is a comment" |> Scanner.scan |> show_tokens;
  [%expect {| EOF |}]
;;

let%expect_test "block comment only" =
  "/* this is a block comment */" |> Scanner.scan |> show_tokens;
  [%expect {| EOF |}]
;;

let%expect_test "scan test000.txt" =
  scanner_test "test000.txt";
  [%expect
    {|
    EQUAL_TO
    EQUAL_TO
    UNI_DEC
    UNI_DEC
    EOF
    |}]
;;

let%expect_test "scan test001.txt" =
  scanner_test "test001.txt";
  [%expect
    {|
    MAIN
    INT
    IDENT	input
    COMMA
    IDENT	myvar
    SEMICOLON
    FUNC
    IDENT	getSumToNIter
    OPEN_PAREN
    INT
    IDENT	n
    CLOSE_PAREN
    COLON
    INT
    OPEN_BRACE
    INT
    IDENT	i
    COMMA
    IDENT	j
    SEMICOLON
    IDENT	i
    ASSIGN
    INT_VAL	0
    SEMICOLON
    IDENT	j
    ASSIGN
    INT_VAL	1
    SEMICOLON
    WHILE
    OPEN_PAREN
    IDENT	j
    LESS_EQUAL
    IDENT	n
    CLOSE_PAREN
    DO
    IDENT	i
    ASSIGN
    IDENT	i
    ADD
    IDENT	j
    SEMICOLON
    IDENT	j
    UNI_INC
    SEMICOLON
    OD
    SEMICOLON
    RETURN
    IDENT	i
    SEMICOLON
    CLOSE_BRACE
    SEMICOLON
    FUNC
    IDENT	getSumToNRecur
    OPEN_PAREN
    INT
    IDENT	n
    CLOSE_PAREN
    COLON
    INT
    OPEN_BRACE
    IF
    OPEN_PAREN
    IDENT	n
    EQUAL_TO
    INT_VAL	1
    CLOSE_PAREN
    THEN
    RETURN
    INT_VAL	1
    SEMICOLON
    FI
    SEMICOLON
    RETURN
    CALL
    IDENT	getSumToNRecur
    OPEN_PAREN
    IDENT	n
    SUB
    INT_VAL	1
    CLOSE_PAREN
    ADD
    IDENT	n
    SEMICOLON
    CLOSE_BRACE
    SEMICOLON
    OPEN_BRACE
    IDENT	input
    ASSIGN
    CALL
    IDENT	readInt
    OPEN_PAREN
    CLOSE_PAREN
    SEMICOLON
    IDENT	myvar
    ASSIGN
    CALL
    IDENT	getSumToNIter
    OPEN_PAREN
    IDENT	input
    CLOSE_PAREN
    SEMICOLON
    CALL
    IDENT	printInt
    OPEN_PAREN
    IDENT	input
    CLOSE_PAREN
    SEMICOLON
    CALL
    IDENT	printInt
    OPEN_PAREN
    IDENT	myvar
    CLOSE_PAREN
    SEMICOLON
    CALL
    IDENT	println
    OPEN_PAREN
    CLOSE_PAREN
    SEMICOLON
    IDENT	myvar
    ASSIGN
    CALL
    IDENT	getSumToNRecur
    OPEN_PAREN
    IDENT	input
    CLOSE_PAREN
    SEMICOLON
    CALL
    IDENT	printInt
    OPEN_PAREN
    IDENT	input
    CLOSE_PAREN
    SEMICOLON
    CALL
    IDENT	printInt
    OPEN_PAREN
    IDENT	myvar
    CLOSE_PAREN
    SEMICOLON
    CALL
    IDENT	println
    OPEN_PAREN
    CLOSE_PAREN
    SEMICOLON
    CLOSE_BRACE
    PERIOD
    EOF
    |}]
;;

let%expect_test "scan test003.txt" =
  scanner_test "test003.txt";
  [%expect
    {|
    MAIN
    FLOAT
    IDENT	positiveFloat
    ASSIGN
    FLOAT_VAL	24.323
    SEMICOLON
    INT
    IDENT	positiveInteger
    ASSIGN
    INT_VAL	13
    SEMICOLON
    FLOAT
    IDENT	negativeFloat
    ASSIGN
    FLOAT_VAL	-25.65
    SEMICOLON
    INT
    IDENT	negativeInteger
    ASSIGN
    INT_VAL	-14
    SEMICOLON
    FLOAT
    IDENT	incorrectNumber
    ASSIGN
    ERROR
    EOF
    |}]
;;
