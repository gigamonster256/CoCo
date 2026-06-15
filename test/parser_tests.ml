open CoCo

let test prog = run prog

let%expect_test "parse hello world" =
  print_string (test "main { call printInt(1); call println(); }.");
  [%expect
    {| 1
 |}]
;;

let%expect_test "parse variable assignment" =
  print_string (test "main { x = 42; call printInt(x); call println(); }.");
  [%expect
    {| 42
 |}]
;;

let%expect_test "parse integer arithmetic" =
  print_string
    (test
       "main { call printInt(1 + 2); call printInt(5 - 3); call printInt(4 * 7); call printInt(10 / 3); call printInt(10 % 3); call printInt(2 ^ 8); call println(); }.");
  [%expect
    {| 3 2 28 3 1 256
 |}]
;;

let%expect_test "parse operator precedence" =
  print_string
    (test
       "main { call printInt(1 + 2 * 3); call printInt((1 + 2) * 3); call printInt(2 ^ 3 + 1); call println(); }.");
  [%expect
    {| 7 9 9
 |}]
;;

let%expect_test "parse compound assignment" =
  print_string
    (test
       "main { x = 10; x += 5; call printInt(x); x -= 3; call printInt(x); x *= 2; call printInt(x); x /= 4; call printInt(x); x %= 5; call printInt(x); call println(); }.");
  [%expect
    {| 15 12 24 6 1
 |}]
;;

let%expect_test "parse increment decrement" =
  print_string
    (test
       "main { x = 5; x++; call printInt(x); x--; call printInt(x); call println(); }.");
  [%expect
    {| 6 5
 |}]
;;

let%expect_test "parse if then else" =
  print_string
    (test
       "main { a = 10; b = 20; if (a < b) then call printInt(1); else call printInt(0); fi; call println(); }.");
  [%expect
    {| 1
 |}]
;;

let%expect_test "parse if with false condition" =
  print_string
    (test
       "main { if (false) then call printInt(1); else call printInt(0); fi; call println(); }.");
  [%expect
    {| 0
 |}]
;;

let%expect_test "parse nested if" =
  print_string
    (test
       "main { x = 5; if (x > 0) then if (x > 10) then call printInt(2); else call printInt(1); fi; else call printInt(0); fi; call println(); }.");
  [%expect
    {| 1
 |}]
;;

let%expect_test "parse while loop" =
  print_string
    (test
       "main { i = 0; while (i < 5) do call printInt(i); i++; od; call println(); }.");
  [%expect
    {| 0 1 2 3 4
 |}]
;;

let%expect_test "parse repeat until" =
  print_string
    (test
       "main { i = 0; repeat call printInt(i); i++; until (i >= 5); call println(); }.");
  [%expect
    {| 0 1 2 3 4
 |}]
;;

let%expect_test "parse boolean expressions" =
  print_string
    (test
       "main { call printBool(true and true); call printBool(true or false); call printBool(not false); call println(); }.");
  [%expect
    {| true true true
 |}]
;;

let%expect_test "parse boolean precedence" =
  print_string
    (test
       "main { call printBool(false or false and true or false); call printBool(true and (false or true)); call println(); }.");
  [%expect
    {| false true
 |}]
;;

let%expect_test "parse float arithmetic" =
  print_string
    (test
       "main { call printFloat(3.14 + 2.86); call printFloat(10.0 / 3.0); call println(); }.");
  [%expect
    {| 6.00 3.33
 |}]
;;

let%expect_test "parse comparisons" =
  print_string
    (test
       "main { call printBool(1 == 2); call printBool(3 != 4); call printBool(5 < 6); call printBool(7 <= 7); call printBool(8 > 9); call printBool(10 >= 10); call println(); }.");
  [%expect
    {| false true true true false true
 |}]
;;

let%expect_test "parse boolean comparisons" =
  print_string
    (test
       "main { call printBool(true == false); call printBool(true != false); call println(); }.");
  [%expect
    {| false true
 |}]
;;

let%expect_test "parse negative numbers" =
  print_string
    (test
       "main { call printInt(-5 + 10); call printInt(-3 * 4); call println(); }.");
  [%expect
    {| 5 -12
 |}]
;;

let%expect_test "parse fibonacci iterative" =
  print_string
    (test
       "main { n = 10; a = 0; b = 1; i = 0; while (i < n) do call printInt(a); tmp = a + b; a = b; b = tmp; i++; od; call println(); }.");
  [%expect
    {| 0 1 1 2 3 5 8 13 21 34
 |}]
;;

let%expect_test "parse complex expression" =
  print_string (test "main { call printInt(1 + 2 * 3 ^ 4); call println(); }.");
  [%expect
    {| 163
 |}]
;;

let%expect_test "parse syntax error - unknown function" =
  print_string (test "main { call foo(); }.");
  [%expect {| Error: unknown function: foo with 0 args |}]
;;

let%expect_test "parse syntax error - missing semicolon" =
  print_string (test "main { x = 1 call printInt(x); }.");
  [%expect {| Error: expected ;, got call |}]
;;
