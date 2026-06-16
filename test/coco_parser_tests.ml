open Coco

let parse_string src = Coco_parser.parse (Scanner.scan src)

let%expect_test "parse minimal program" =
  let src = "main { call println(); }." in
  let vars, funcs, stmts = parse_string src in
  Printf.printf
    "vars=%d funcs=%d stmts=%d\n"
    (List.length vars)
    (List.length funcs)
    (List.length stmts);
  [%expect {| vars=0 funcs=0 stmts=1 |}]
;;

let%expect_test "parse with global vars" =
  let src =
    {|
main
  int x;
  float pi;
  bool flag;
{
  x = 42;
  pi = 3.14;
  flag = true;
}.
|}
  in
  let vars, funcs, stmts = parse_string src in
  Printf.printf
    "vars=%d funcs=%d stmts=%d\n"
    (List.length vars)
    (List.length funcs)
    (List.length stmts);
  [%expect {| vars=3 funcs=0 stmts=3 |}]
;;

let%expect_test "parse if-else" =
  let src =
    {|
main {
  if (x > 0) then
    call printInt(1);
  else
    call printInt(-1);
  fi;
  call println();
}.
|}
  in
  let _, _, stmts = parse_string src in
  Printf.printf "stmts=%d\n" (List.length stmts);
  [%expect {| stmts=2 |}]
;;

let%expect_test "parse while loop" =
  let src =
    {|
main {
  i = 0;
  while (i < 10) do
    call printInt(i);
    i++;
  od;
  call println();
}.
|}
  in
  let _, _, stmts = parse_string src in
  Printf.printf "stmts=%d\n" (List.length stmts);
  [%expect {| stmts=3 |}]
;;

let%expect_test "parse repeat-until" =
  let src =
    {|
main {
  a = 0;
  b = 10;
  repeat
    a++;
  until (a > b);
}.
|}
  in
  let _, _, stmts = parse_string src in
  Printf.printf "stmts=%d\n" (List.length stmts);
  [%expect {| stmts=3 |}]
;;

let%expect_test "parse function declarations" =
  let src =
    {|
main
function j(int i) : int { return i; };

function j(int i, int j) : int { return i + j; };

function j(bool i) : int { return 1; };

{
  c = call j(1);
  c = call j(1, 2);
  c = call j(true);
}.
|}
  in
  let vars, funcs, stmts = parse_string src in
  Printf.printf
    "vars=%d funcs=%d stmts=%d\n"
    (List.length vars)
    (List.length funcs)
    (List.length stmts);
  [%expect {| vars=0 funcs=3 stmts=3 |}]
;;

let%expect_test "parse arrays" =
  let src =
    {|
main
  int[3] arr1;
  int[2][2] arr2;
{
  arr1[0] = -1;
  arr2[1][0] = 2;
  call printInt(arr2[1][0]);
  call println();
}.
|}
  in
  let vars, _, stmts = parse_string src in
  Printf.printf "vars=%d stmts=%d\n" (List.length vars) (List.length stmts);
  [%expect {| vars=2 stmts=4 |}]
;;

let%expect_test "parse prefix not and boolean ops" =
  let src =
    {|
main {
  x = true;
  y = false;
  z = not x;
  w = x and y;
  v = x or y;
  u = x ^ y;
  call println();
}.
|}
  in
  let _, _, stmts = parse_string src in
  Printf.printf "stmts=%d\n" (List.length stmts);
  [%expect {| stmts=7 |}]
;;

let%expect_test "parse arithmetic expressions" =
  let src =
    {|
main {
  a = 1 + 2 * 3;
  b = (1 + 2) * 3;
  c = a ^ 2;
  d = a % 2;
  e = a / 2;
  call println();
}.
|}
  in
  let _, _, stmts = parse_string src in
  Printf.printf "stmts=%d\n" (List.length stmts);
  [%expect {| stmts=6 |}]
;;

let%expect_test "parse comparison operators" =
  let src =
    {|
main {
  a = 1 == 2;
  b = 1 != 2;
  c = 1 < 2;
  d = 1 <= 2;
  e = 1 > 2;
  f = 1 >= 2;
  call println();
}.
|}
  in
  let _, _, stmts = parse_string src in
  Printf.printf "stmts=%d\n" (List.length stmts);
  [%expect {| stmts=7 |}]
;;

let%expect_test "parse compound assignment" =
  let src =
    {|
main {
  x += 5;
  y -= 3;
  z *= 2;
  a /= 2;
  b %= 3;
  call println();
}.
|}
  in
  let _, _, stmts = parse_string src in
  Printf.printf "stmts=%d\n" (List.length stmts);
  [%expect {| stmts=6 |}]
;;

let%expect_test "parse void function" =
  let src =
    {|
main
function greet(bool loud) : void {
  if (loud) then
    call printInt(42);
  fi;
  return;
};

{
  call greet(true);
  call println();
}.
|}
  in
  let _, funcs, stmts = parse_string src in
  Printf.printf "funcs=%d stmts=%d\n" (List.length funcs) (List.length stmts);
  [%expect {| funcs=1 stmts=2 |}]
;;

let%expect_test "parse return with expression" =
  let src =
    {|
main
function add(int a, int b) : int { return a + b; };

{
  call printInt(call add(1, 2));
  call println();
}.
|}
  in
  let _, funcs, stmts = parse_string src in
  Printf.printf "funcs=%d stmts=%d\n" (List.length funcs) (List.length stmts);
  [%expect {| funcs=1 stmts=2 |}]
;;

let%expect_test "parse array parameter" =
  let src =
    {|
main
function sum(int[] arr, int n) : int {
  return arr[0];
};

{ call println(); }.
|}
  in
  let _, funcs, _ = parse_string src in
  Printf.printf "funcs=%d\n" (List.length funcs);
  [%expect {| funcs=1 |}]
;;

let%expect_test "parse nested if" =
  let src =
    {|
main {
  if (a > 0) then
    if (b > 0) then
      call printInt(1);
    else
      call printInt(0);
    fi;
  fi;
  call println();
}.
|}
  in
  let _, _, stmts = parse_string src in
  Printf.printf "stmts=%d\n" (List.length stmts);
  [%expect {| stmts=2 |}]
;;

let%expect_test "scan and parse test001.txt" =
  let src =
    In_channel.with_open_text "scanner/test001.txt" In_channel.input_all
  in
  let vars, funcs, stmts = parse_string src in
  Printf.printf
    "vars=%d funcs=%d stmts=%d\n"
    (List.length vars)
    (List.length funcs)
    (List.length stmts);
  [%expect {| vars=1 funcs=2 stmts=9 |}]
;;
