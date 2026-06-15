open Coco_lib

let show_token = function
  | Token.And -> "And"
  | Or -> "Or"
  | Not -> "Not"
  | Pow -> "^"
  | Mul -> "*"
  | Div -> "/"
  | Mod -> "%"
  | Add -> "+"
  | Sub -> "-"
  | Eq -> "=="
  | Neq -> "!="
  | Lt -> "<"
  | Le -> "<="
  | Gt -> ">"
  | Ge -> ">="
  | Assign -> "="
  | AddAssign -> "+="
  | SubAssign -> "-="
  | MulAssign -> "*="
  | DivAssign -> "/="
  | ModAssign -> "%="
  | PowAssign -> "^="
  | Inc -> "++"
  | Dec -> "--"
  | Void -> "void"
  | Bool -> "bool"
  | Int -> "int"
  | Float -> "float"
  | True -> "true"
  | False -> "false"
  | Lparen -> "("
  | Rparen -> ")"
  | Lbrace -> "{"
  | Rbrace -> "}"
  | Lbrack -> "["
  | Rbrack -> "]"
  | Comma -> ","
  | Colon -> ":"
  | Semi -> ";"
  | Dot -> "."
  | If -> "if"
  | Then -> "then"
  | Else -> "else"
  | Fi -> "fi"
  | While -> "while"
  | Do -> "do"
  | Od -> "od"
  | Repeat -> "repeat"
  | Until -> "until"
  | Call -> "call"
  | Return -> "return"
  | Main -> "main"
  | Func -> "function"
  | IntVal n -> Printf.sprintf "INT(%d)" n
  | FloatVal f -> Printf.sprintf "FLOAT(%f)" f
  | Id s -> Printf.sprintf "ID(%s)" s
  | Eof -> "EOF"
;;

let tokens_of src =
  let ts = Scanner.scan src in
  List.iter (fun t -> print_endline (show_token t)) ts
;;

let%expect_test "scan operators - maximal munch" =
  tokens_of "*^/%and+-or==!=<<=>>==+=-=*=/=%=^=++--";
  [%expect
    {|
    *
    ^
    /
    %
    And
    +
    -
    Or
    ==
    !=
    <
    <=
    >
    >=
    =
    +=
    -=
    *=
    /=
    %=
    ^=
    ++
    --
    EOF
    |}]
;;

let%expect_test "scan keywords" =
  tokens_of
    "main function if then else fi while do od repeat until call return void bool int float true false";
  [%expect
    {|
    main
    function
    if
    then
    else
    fi
    while
    do
    od
    repeat
    until
    call
    return
    void
    bool
    int
    float
    true
    false
    EOF
    |}]
;;

let%expect_test "scan identifiers with keyword substrings" =
  tokens_of "iffy elsest whileist int_47 main1 palvoidous gaulint returnist";
  [%expect
    {|
    ID(iffy)
    ID(elsest)
    ID(whileist)
    ID(int_47)
    ID(main1)
    ID(palvoidous)
    ID(gaulint)
    ID(returnist)
    EOF
    |}]
;;

let%expect_test "scan integer literals" =
  tokens_of "0 42 -17 1337";
  [%expect
    {|
    INT(0)
    INT(42)
    INT(-17)
    INT(1337)
    EOF
    |}]
;;

let%expect_test "scan float literals" =
  tokens_of "3.14 -0.605 2.50 24.323";
  [%expect
    {|
    FLOAT(3.140000)
    FLOAT(-0.605000)
    FLOAT(2.500000)
    FLOAT(24.323000)
    EOF
    |}]
;;

let%expect_test "scan delimiters and punctuation" =
  tokens_of "(){}[],:;.";
  [%expect
    {|
    (
    )
    {
    }
    [
    ]
    ,
    :
    ;
    .
    EOF
    |}]
;;

let%expect_test "scan line comments" =
  tokens_of "main // this is a comment\nint // another\nx;";
  [%expect
    {|
    main
    int
    ID(x)
    ;
    EOF
    |}]
;;

let%expect_test "scan block comments" =
  tokens_of "main /* block\ncomment */ int x;";
  [%expect
    {|
    main
    int
    ID(x)
    ;
    EOF
    |}]
;;

let%expect_test "scan full program header" =
  tokens_of "main int x, y; float z; { }.";
  [%expect
    {|
    main
    int
    ID(x)
    ,
    ID(y)
    ;
    float
    ID(z)
    ;
    {
    }
    .
    EOF
    |}]
;;

let%expect_test "scan assignment operators" =
  tokens_of "x = 1; x += 2; x -= 3; x *= 4; x /= 5; x %= 6; x ^= 7;";
  [%expect
    {|
    ID(x)
    =
    INT(1)
    ;
    ID(x)
    +=
    INT(2)
    ;
    ID(x)
    -=
    INT(3)
    ;
    ID(x)
    *=
    INT(4)
    ;
    ID(x)
    /=
    INT(5)
    ;
    ID(x)
    %=
    INT(6)
    ;
    ID(x)
    ^=
    INT(7)
    ;
    EOF
    |}]
;;

let%expect_test "scan if while repeat return call" =
  tokens_of
    "if (x) then y; fi; while (a) do b; od; repeat c; until (d); return; call f();";
  [%expect
    {|
    if
    (
    ID(x)
    )
    then
    ID(y)
    ;
    fi
    ;
    while
    (
    ID(a)
    )
    do
    ID(b)
    ;
    od
    ;
    repeat
    ID(c)
    ;
    until
    (
    ID(d)
    )
    ;
    return
    ;
    call
    ID(f)
    (
    )
    ;
    EOF
    |}]
;;

let%expect_test "scan boolean expressions" =
  tokens_of "true and false or not true";
  [%expect
    {|
    true
    And
    false
    Or
    Not
    true
    EOF
    |}]
;;

let%expect_test "scan ++ and -- unary" =
  tokens_of "x++; y--;";
  [%expect
    {|
    ID(x)
    ++
    ;
    ID(y)
    --
    ;
    EOF
    |}]
;;

let%expect_test "scan negative number edge case" =
  tokens_of "-5 - 3";
  [%expect
    {|
    INT(-5)
    -
    INT(3)
    EOF
    |}]
;;

let%expect_test "scan function declaration with params" =
  tokens_of "function add(int a, int b) : int { return a + b; };";
  [%expect
    {|
    function
    ID(add)
    (
    int
    ID(a)
    ,
    int
    ID(b)
    )
    :
    int
    {
    return
    ID(a)
    +
    ID(b)
    ;
    }
    ;
    EOF
    |}]
;;

let%expect_test "scan array types and indexing" =
  tokens_of "int[5] arr; arr[0] = 1; int[2][3] matrix;";
  [%expect
    {|
    int
    [
    INT(5)
    ]
    ID(arr)
    ;
    ID(arr)
    [
    INT(0)
    ]
    =
    INT(1)
    ;
    int
    [
    INT(2)
    ]
    [
    INT(3)
    ]
    ID(matrix)
    ;
    EOF
    |}]
;;

let%expect_test "scan relational operators with mixed types" =
  tokens_of "1 == 2; 3.14 != 0.0; true == false; a < b; x >= 10;";
  [%expect
    {|
    INT(1)
    ==
    INT(2)
    ;
    FLOAT(3.140000)
    !=
    FLOAT(0.000000)
    ;
    true
    ==
    false
    ;
    ID(a)
    <
    ID(b)
    ;
    ID(x)
    >=
    INT(10)
    ;
    EOF
    |}]
;;
