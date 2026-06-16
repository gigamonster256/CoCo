type base_type =
  | Bool
  | Int
  | Float

type type_decl = base_type * int list

type param_type = base_type * int

type binop =
  | Add
  | Sub
  | Mul
  | Div
  | Mod
  | Pow
  | And
  | Or
  | Eq
  | Neq
  | Lt
  | Le
  | Gt
  | Ge

type unary_post =
  | Inc
  | Dec

type assign_op =
  | SimpleAssign
  | AddAssign
  | SubAssign
  | MulAssign
  | DivAssign
  | ModAssign
  | PowAssign

type literal =
  | IntLit of int
  | FloatLit of float
  | BoolLit of bool

type designator =
  { name : string
  ; indices : expr list
  }

and expr =
  | Binary of expr * binop * expr
  | Not of expr
  | Literal of literal
  | Var of designator
  | Call of string * expr list

and statement =
  | Assign of designator * assign_rhs
  | ExprStmt of expr
  | If of expr * statement list * statement list option
  | While of expr * statement list
  | Repeat of statement list * expr
  | Return of expr option

and assign_rhs =
  | AssignValue of assign_op * expr
  | UnaryAssign of unary_post

type var_decl = type_decl * string list

type param_decl = param_type * string

type func_body = var_decl list * statement list

type func_decl = string * param_decl list * base_type option * func_body

type computation = var_decl list * func_decl list * statement list
