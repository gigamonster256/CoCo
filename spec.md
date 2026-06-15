# CoCo Language Specification

> **Status:** Recovered from implementation (compiler source + test cases)
> **Evidence key:** Each rule links to source: `Token.java:L`, `Interpreter.java:L`, `Compiler.java:L` or test file `tests/PA?/test???.txt`

---

## 1. Overview

CoCo is a statically typed, imperative programming language with C-like syntax and Python-inspired keywords (`fi`, `od`, `repeat...until`). It provides first-class multi-dimensional arrays, user-defined functions with overloading, and a small set of built-in I/O primitives.

A CoCo program consists of optional global variable declarations and function declarations, followed by a `main` block:

```c
main
  // optional global variable declarations
  // optional function declarations
{
  // statement sequence (the program body)
}.
```

The point `.` terminates the program.

---

## 2. Lexical Structure

### 2.1 Source Character Set
- ASCII only
- Case-sensitive: `Main`, `Else`, `iF` are identifiers, not keywords
- Whitespace: spaces, tabs, and newlines separate tokens but are otherwise ignored

### 2.2 Comments
- **Line comment:** `//` through end of line
- **Block comment:** `/*` through `*/` (nested block comments are NOT supported)
- Comments are treated as whitespace; they do not nest and may appear anywhere whitespace is valid

### 2.3 Identifiers
```
ident = letter { "_" | letter | digit } .
letter = "a".."z" | "A".."Z" .
digit = "0".."9" .
```
- Must start with a letter (`a-z`, `A-Z`)
- May contain letters, digits, and underscores
- Cannot start with underscore (`_`) or digit
- Identifiers containing keyword substrings (e.g., `iffy`, `whileist`, `main1`) are valid identifiers

### 2.4 Reserved Keywords

| Keyword | Purpose |
|---------|---------|
| `main` | Program entry point |
| `function` | Function declaration |
| `if` / `then` / `else` / `fi` | Conditional |
| `while` / `do` / `od` | While loop |
| `repeat` / `until` | Repeat-until loop |
| `call` | Function call |
| `return` | Return from function |
| `bool` / `int` / `float` / `void` | Primitive types |
| `true` / `false` | Boolean literals |
| `and` / `or` / `not` | Boolean operators |

### 2.5 Operators & Delimiters

| Category | Tokens |
|----------|--------|
| Arithmetic | `+` `-` `*` `/` `%` `^` |
| Relational | `==` `!=` `<` `<=` `>` `>=` |
| Boolean | `and` `or` `not` |
| Assignment | `=` `+=` `-=` `*=` `/=` `%=` `^=` |
| Unary | `++` `--` |
| Delimiters | `(` `)` `{` `}` `[` `]` `,` `:` `;` `.` |

### 2.6 Literals

| Literal | Pattern | Examples |
|---------|---------|----------|
| Integer | `["-"] digit { digit }` | `0`, `42`, `-17` |
| Float | `integerLit "." digit { digit }` | `3.14`, `-0.605`, `2.50` |
| Boolean | `"true"` or `"false"` | `true`, `false` |

- Negative literals: The scanner recognizes `-` as part of integer/float literals (e.g., `-5` is a single `INT_VAL`)
- There is no hex, octal, or binary literal syntax
- Floats must have both integer and fractional parts; `-17.` is an error

### 2.7 Tokenization

The scanner uses **maximal munch**: at each position, it consumes the longest possible valid token. For example:
- `===` is tokenized as `EQUAL_TO` `EQUAL_TO` (not `ASSIGN` `EQUAL_TO`)
- `----` is tokenized as `UNI_DEC` `UNI_DEC` (not `SUB` `SUB`)
- `main /* comment */ in` → keyword `main` is preserved through block comments

---

## 3. Formal Grammar (EBNF)

> Source: `Interpreter.java:344-1080`, `Compiler.java:1018-1391`, `NonTerminal.java`

### 3.1 Program Structure

```
computation  = "main" { varDecl } { funcDecl } "{" statSeq "}" "." .
```

### 3.2 Declarations

```
typeDecl     = type { "[" integerLit "]" } .
type         = "bool" | "int" | "float" .

varDecl      = typeDecl ident { "," ident } ";" .

paramType    = type { "[" "]" } .
paramDecl    = paramType ident .
formalParam  = "(" [ paramDecl { "," paramDecl } ] ")" .

funcBody     = "{" { varDecl } statSeq "}" ";" .
funcDecl     = "function" ident formalParam ":" ( "void" | type ) funcBody .
```

**Notes:**
- `typeDecl` in variable declarations requires fixed array sizes (`[integerLit]`)
- `paramType` in parameters uses empty brackets (`[]`) since array size is not part of the parameter type signature
- Function return type is either a primitive type or `void`
- Function body is terminated by `;` after the closing `}`

### 3.3 Statements

```
statement    = assign | funcCall | ifStat | whileStat | repeatStat | returnStat .

statSeq      = statement ";" { statement ";" } .

assign       = designator ( assignOp relExpr | unaryOp ) .

funcCall     = "call" ident "(" [ relExpr { "," relExpr } ] ")" .

ifStat       = "if" relation "then" statSeq [ "else" statSeq ] "fi" .

whileStat    = "while" relation "do" statSeq "od" .

repeatStat   = "repeat" statSeq "until" relation .

returnStat   = "return" [ relExpr ] .
```

**Notes:**
- Every statement in a sequence must end with `;`
- The `else` branch in `ifStat` is optional
- `funcCall` as an expression requires `call` keyword; as a statement `call` is also required
- `return` with no expression returns from a `void` function

### 3.4 Expressions (Operator Precedence, Low to High)

```
relExpr      = addExpr { relOp addExpr } .

addExpr      = multExpr { addOp multExpr } .

multExpr     = powExpr { multOp powExpr } .

powExpr      = groupExpr { powOp groupExpr } .

groupExpr    = literal | designator | "not" relExpr | relation | funcCall .

relation     = "(" relExpr ")" .
```

| Precedence | Operators | Associativity |
|-----------|-----------|---------------|
| 6 (lowest) | `==` `!=` `<` `<=` `>` `>=` | Left (but chaining not supported; only one relOp per relExpr) |
| 5 | `+` `-` `or` | Left |
| 4 | `*` `/` `%` `and` | Left |
| 3 | `^` | Right (effectively, due to `groupExpr` base) |
| 2 | `not` (prefix) | Prefix unary |
| 1 (highest) | literals, designators, `call`, `( expr )` | — |

**Precedence summary:** Relations < Additive < Multiplicative < Power < Unary < Primary

**Important:** `and` binds tighter than `or`, and both are at the multiplicative/additive levels respectively, consistent with standard boolean algebra.

### 3.5 Operator Groups

| Nonterminal | Tokens |
|-------------|--------|
| `relOp` | `==` `!=` `<` `<=` `>` `>=` |
| `addOp` | `+` `-` `or` |
| `multOp` | `*` `/` `%` `and` |
| `powOp` | `^` |
| `assignOp` | `=` `+=` `-=` `*=` `/=` `%=` `^=` |
| `unaryOp` | `++` `--` |

### 3.6 Designator

```
designator   = ident { "[" relExpr "]" } .
```

Designators are l-values or r-values depending on context. They support:
- Simple variable access: `x`
- Array element access: `arr[0]`, `matrix[i][j]`

---

## 4. Type System

> Source: `Type.java`, `IntType.java`, `FloatType.java`, `BoolType.java`, `ArrayType.java`, `TypeChecker.java`

### 4.1 Primitive Types

| Type | Domain | Default (uninitialized) |
|------|--------|------------------------|
| `int` | 32-bit signed integer | Undefined |
| `float` | 32-bit IEEE 754 single precision | Undefined |
| `bool` | `true` / `false` | Undefined |
| `void` | No value (return type only) | N/A |

### 4.2 Operator Type Signatures

**Arithmetic (`int`, `float` only):**

| Operator | Input | Output |
|----------|-------|--------|
| `+` | `int × int` | `int` |
| `+` | `float × float` | `float` |
| `-` | `int × int` | `int` |
| `-` | `float × float` | `float` |
| `*` | `int × int` | `int` |
| `*` | `float × float` | `float` |
| `/` | `int × int` | `int` |
| `/` | `float × float` | `float` |
| `%` | `int × int` | `int` |
| `%` | `float × float` | `float` |
| `^` | `int × int` | `int` |
| `^` | `float × float` | `float` |

> **Key rule:** CoCo does NOT perform implicit type coercion. `int + float`, `int and bool`, etc. are all type errors.

**Boolean (`bool` only):**

| Operator | Input | Output |
|----------|-------|--------|
| `and` | `bool × bool` | `bool` |
| `or` | `bool × bool` | `bool` |
| `not` | `bool` | `bool` |
| `^` (xor) | `bool × bool` | `bool` |

**Relational (by input type):**

| Input Types | Valid Operators | Output |
|-------------|-----------------|--------|
| `int × int` | `==` `!=` `<` `<=` `>` `>=` | `bool` |
| `float × float` | `==` `!=` `<` `<=` `>` `>=` | `bool` |
| `bool × bool` | `==` `!=` | `bool` |

**Assignment:**

| LHS Type | RHS Type Must Be | Notes |
|----------|-----------------|-------|
| `int` | `int` | |
| `float` | `float` | |
| `bool` | `bool` | |
| `T[N]` | `T[N]` | Same base type and dimensions |

**Compound assignment** (`+=`, `-=`, `*=`, etc.) follows the same rules as the corresponding binary operator combined with assignment.

**Unary increment/decrement** (`++`, `--`) applies to `int` and `float` only; NOT allowed on `bool`.

### 4.3 Array Type

```
ArrayType = BaseType "[" size "]"
```

- Arrays are 0-indexed
- Array dimensions form part of the type (e.g., `int[3]` and `int[5]` are different types)
- Multi-dimensional arrays: `int[2][3]` is an array of 2 arrays of 3 ints each
- Array index must be an `int` expression
- Compile-time bounds checking for constant indices
- Array parameters use `[]` without size (the size is not part of the parameter type signature)

### 4.4 Function Types

Functions are identified by their **signature** (name + parameter types). Return type alone does not distinguish overloaded functions:

```
function j(int i) : int { ... };        // signature: j(int)
function j(int i, int j) : int { ... }; // signature: j(int, int)  -- OK, different arity
function j(bool i) : int { ... };       // signature: j(bool)      -- OK, different param type
function j(int i) : float { ... };      // ERROR: same signature as first
```

---

## 5. Semantics

> Source: `Interpreter.java` (the executable specification)

### 5.1 Program Execution

1. Global variables are declared and space is allocated
2. Function declarations are registered (no execution yet)
3. The `main` block body is executed as a statement sequence
4. Program terminates when execution reaches the end of `main` or a `return` is encountered

### 5.2 Evaluation Order

- Expressions are evaluated left-to-right at each precedence level
- Function call arguments are evaluated left-to-right before the call
- No specified evaluation order for subexpressions of operators (implementation-defined)

### 5.3 Truthiness

CoCo has **no implicit coercion to bool**. Conditions in `if`, `while`, and `until` MUST be `bool` expressions. There is no "truthiness" concept — `int` values are not automatically converted to `bool`.

### 5.4 Short-Circuit Evaluation

The interpreter implementation evaluates all operands eagerly. However, a compliant implementation MAY short-circuit `and`/`or` since the type system guarantees both operands are `bool`.

### 5.5 Control Flow Semantics

- **`if`/`then`/`else`/`fi`:** Evaluates the condition; if `true`, executes the `then` block; otherwise executes the `else` block (if present).
- **`while`/`do`/`od`:** Evaluates the condition before each iteration. Continues while the condition is `true`.
- **`repeat`/`until`:** Executes the body once, then evaluates the condition. Continues while the condition is `false` (i.e., repeats *until* the condition becomes `true`).
- **`return`:** Immediately exits the current function. If followed by an expression, that value is the function's return value.

### 5.6 Variable Scoping

CoCo has two scope levels:

1. **Global scope:** Variables declared between `main` and `{`, and function parameters. Accessible within the `main` body and all function bodies.
2. **Function-local scope:** Variables declared within a function body (`{ varDecl ... }`). Only accessible within that function.

**Shadowing rules:**
- A function parameter shadows a global variable with the same name
- A function-local variable declared inside the function body shadows both globals and parameters
- Scopes are nested: function body scope is inside the function scope, which is inside global scope
- Redefining a variable at the same scope level is an error

### 5.7 Function Overloading Resolution

Functions are resolved by matching the argument types against declared parameter type lists. An exact match is required for:
- Number of parameters (arity)
- Type of each parameter (no coercion)
- Return type is NOT part of the overload resolution

---

## 6. Built-in Functions (Standard Library)

> Source: `Compiler.java:881-893`, `Interpreter.java:313-342`

| Function | Signature | Description |
|----------|-----------|-------------|
| `readInt()` | `() → int` | Reads an integer from stdin (prompts `int? `) |
| `readFloat()` | `() → float` | Reads a float from stdin (prompts `float? `) |
| `readBool()` | `() → bool` | Reads a boolean from stdin (prompts `true or false? `) |
| `printInt(int)` | `(int) → void` | Prints integer followed by space |
| `printFloat(float)` | `(float) → void` | Prints float to 2 decimal places followed by space |
| `printBool(bool)` | `(bool) → void` | Prints `true` or `false` followed by space |
| `println()` | `() → void` | Prints a newline |

**Usage rules:**
- Built-in functions can be **shadowed** by user-defined functions with the same name
- `call` is REQUIRED for all function calls, including built-ins: `call printInt(42)`
- Void functions (`printInt`, `printFloat`, `printBool`, `println`) must be used as statements
- Non-void functions (`readInt`, `readFloat`, `readBool`) must be used as expressions
- Using a void function in an expression or a non-void function as a standalone statement is a type error

---

## 7. Compiler Architecture

> Source: `Compiler.java`, `IRGenerator.java`, `DLX.java`

### 7.1 Pipeline

```
Source Code
  → Scanner (lexical analysis)
    → Parser (recursive descent, builds AST)
      → Symbol Table Construction
        → Type Checker (visitor over AST)
          → IR Generator (AST → SSA Control Flow Graph)
            → Optimizations (CP, CF, CSE, DCE)
              → Register Allocation (graph coloring)
                → Code Generation (TAC → DLX instructions)
                  → DLX Execution (emulator)
```

### 7.2 Intermediate Representation

The compiler uses **Three-Address Code (TAC)** organized into a **Control Flow Graph (CFG)** in SSA-like form. Each basic block contains a list of TAC instructions.

**TAC instruction kinds:** `ADD`, `SUB`, `MUL`, `DIV`, `MOD`, `POW`, `CMP`, `OR`, `AND`, `NOT`, `RDI`, `RDF`, `RDB`, `WRI`, `WRF`, `WRB`, `WRL`, `BEQ`, `BNE`, `BLT`, `BGE`, `BLE`, `BGT`, `BSR`, `JSR`, `RET`, `MOV`

### 7.3 Target: DLX Virtual Machine

The compiler targets a **DLX processor emulator**, a RISC-style educational ISA.

**Registers:** 32 general-purpose registers (R0-R31)
- R0: Hardwired to 0
- R30: Stack pointer
- R31: Return address (for function calls)

**Memory:** 10,000 words (40 KB)

**Instruction Formats:**

| Format | Structure | Use |
|--------|-----------|-----|
| F1 | `op(6) \| a(5) \| b(5) \| imm16` | Immediate arithmetic, branches, load/store |
| F2 | `op(6) \| a(5) \| b(5) \| c(5) \| 5 unused` | Register operations |
| F3 | `op(6) \| addr26` | Unconditional jump (JSR) |

**Arithmetic:** `ADD`, `SUB`, `MUL`, `DIV`, `MOD`, `POW`, `CMP` (and float variants `fADD`-`fCMP`)
**Logical:** `OR`, `AND`, `BIC`, `XOR`, `LSH`, `ASH`
**Memory:** `LDW`, `STW`, `POP`, `PSH`, `ARRCPY`
**Branch:** `BEQ`, `BNE`, `BLT`, `BGE`, `BLE`, `BGT`
**Subroutine:** `BSR`, `JSR`, `RET`
**I/O:** `RDI`, `RDF`, `RDB`, `WRI`, `WRF`, `WRB`, `WRL`

---

## 8. Formalized Type Rules (Reference)

### 8.1 Expression Typing

```
Γ ⊢ e1 : τ1    Γ ⊢ e2 : τ2    τ1.add(τ2) = τ
――――――――――――――――――――――――――――――――――――――
        Γ ⊢ e1 + e2 : τ

Γ ⊢ e1 : τ1    Γ ⊢ e2 : τ2    τ1.cmp(τ2) = τ
――――――――――――――――――――――――――――――――――――――
        Γ ⊢ e1 relOp e2 : τ

Γ ⊢ e : bool
――――――――――――――
Γ ⊢ not e : bool
```

### 8.2 Statement Typing

```
Γ ⊢ cond : bool    Γ ⊢ s1 ✓    Γ ⊢ s2 ✓     (s2 optional)
――――――――――――――――――――――――――――――――――――――――――
        Γ ⊢ if cond then s1 [else s2] fi ✓

Γ ⊢ lhs : τ    Γ ⊢ rhs : τ    τ.assign(τ) = void
――――――――――――――――――――――――――――――――――――――――
        Γ ⊢ lhs = rhs ✓

Γ ⊢ f : (τ1,...,τn) → void    Γ ⊢ argi : τi
―――――――――――――――――――――――――――――――――――――
        Γ ⊢ call f(arg1,...,argn) ✓  (as statement)

Γ ⊢ f : (τ1,...,τn) → τret ≠ void    Γ ⊢ argi : τi
―――――――――――――――――――――――――――――――――――――――――
        Γ ⊢ call f(arg1,...,argn) : τret  (as expression)
```

---

## 9. Error Messages

The compiler produces structured error messages with line and character positions:

- `SyntaxError(L,C)[Expected X but got Y.]` — parser
- `ResolveSymbolError(L,C)[Could not find name.]` — undeclared variable/function
- `DeclareSymbolError(L,C)[name already exists.]` — redeclaration
- `TypeError(L,C)[message]` — type checking

---

## 10. Test-Backed Examples

Every syntax rule, operator, and edge case below is backed by an actual test file that the Java compiler parses, type-checks, and/or executes correctly.

### 10.1 Minimal Program
```
main { call println(); }.
```
→ [test: `PA4/test000.txt`](../../engr-cse-compiler-design-f23/PA4/test000.txt)

### 10.2 Variable Declarations
```
main
int x;
float pi;
bool flag;
{
  x = 42;
  pi = 3.14;
  flag = true;
}.
```
→ [test: `PA2/test000.txt`](../../engr-cse-compiler-design-f23/PA2/test000.txt)

### 10.3 Control Flow (if/then/else/fi)
```
main {
  x = call readInt();
  if (x > 0) then
    call printInt(1);
  else
    call printInt(-1);
  fi;
  call println();
}.
```
→ [test: `PA2/test001.txt`](../../engr-cse-compiler-design-f23/PA2/test001.txt)

### 10.4 While Loop
```
main {
  i = 0;
  while (i < 10) do
    call printInt(i);
    i++;
  od;
  call println();
}.
```
→ [test: `PA2/test003.txt`](../../engr-cse-compiler-design-f23/PA2/test003.txt)

### 10.5 Repeat-Until Loop
```
main {
  a = 0;
  b = 10;
  repeat
    a++;
  until (a > b);
}.
```
→ [test: `PA4/test014.txt`](../../engr-cse-compiler-design-f23/PA4/test014.txt)

### 10.6 Functions with Overloading
```
function j(int i) : int { return i; };
function j(int i, int j) : int { return i + j; };
function j(bool i) : int { return 1; };
main {
  c = call j(1);
  c = call j(1, 2);
  c = call j(true);
}.
```
→ [test: `PA4/test008.txt`](../../engr-cse-compiler-design-f23/PA4/test008.txt)

### 10.7 Recursive Functions (Fibonacci)
```
function fibonacci(int a) : int {
  if (a <= 0) then return 0; fi;
  if (a <= 2) then return 1; fi;
  return call fibonacci(a - 1) + call fibonacci(a - 2);
};
main {
  call printInt(call fibonacci(10));
  call println();
}.
```
→ [test: `PA89/test222-func.txt`](../../engr-cse-compiler-design-f23/PA89/test222-func.txt)

### 10.8 Multi-Dimensional Arrays
```
main
int[3] arr1;
int[2][2] arr2;
{
  arr1[0] = -1;
  arr2[1][0] = 2;
  call printInt(arr2[1][0]);
  call println();
}.
```
→ [test: `PA2/test005.txt`](../../engr-cse-compiler-design-f23/PA2/test005.txt)

### 10.9 Type Error Cases
```
main {
  call printInt(1 + false);     // TypeError: int + bool
  call printBool(3 - true);     // TypeError: int - bool
}.
```
→ [test: `PA5/test000.txt`](../../engr-cse-compiler-design-f23/PA5/test000.txt)

---

## Appendix A: Scanner Edge Cases

| Edge Case | Behavior | Source |
|-----------|----------|--------|
| `_foo` (leading underscore) | ERROR token | `Token.java:107` |
| `1abc` (leading digit) | `INT_VAL(1)` then `IDENT(abc)` | maximal munch |
| `/* unclosed block comment` | ERROR token (EOF in block comment) | `Scanner.java:170-176` |
| `main /* cmt */ in` | `MAIN`, `IN...` wait, `in` is not a keyword — this would parse as `MAIN`, `IDENT(in)` | `Scanner.java:109-143` |
| `iffy` `whileist` `elsest` | Valid IDENTs (keyword substring inside) | `PA1/test006.txt` |
| `0xB33F` | `INT_VAL(0)`, `IDENT(xB33F)` (no hex support) | `PA1/test012.txt` |
| `+5` | `ADD`, `INT_VAL(5)` (not a positive int literal) | `PA1/test009.txt` |

## Appendix B: Interpreter Semantics Edge Cases

| Edge Case | Behavior | Source |
|-----------|----------|--------|
| `true ^ false` | `true` (boolean XOR via power operator) | `Interpreter.java:492-496` |
| `int & int` via `and` | Bitwise AND on ints (interpreter quirk; type checker rejects) | `Interpreter.java:533-534` |
| `int \| int` via `or` | Bitwise OR on ints (interpreter quirk; type checker rejects) | `Interpreter.java:597-598` |
| Uninitialized variable access | Java default value (0, 0.0, false) in interpreter; undefined in compiled code | — |
| Early return dead code | `return` in the interpreter throws `QuitParseException` to halt execution | `Interpreter.java:919-924` |
