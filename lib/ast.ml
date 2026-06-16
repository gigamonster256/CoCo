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

(** designator = ident { "[" relExpr "]" } *)
type designator =
  { name : string
  ; indices : expr list
  }

and expr =
  | Binary of expr * binop * expr
  (** relExpr / addExpr / multExpr / powExpr *)
  | Not of expr
  (** "not" relExpr *)
  | Literal of literal
  (** bool / int / float literal *)
  | Var of designator
  (** variable or array access *)
  | Call of string * expr list
  (** "call" ident "(" args ")" *)

and statement =
  | Assign of designator * assign_rhs
  (** designator assignOp relExpr | designator unaryOp *)
  | ExprStmt of expr
  (** expression used as statement (e.g., call stmt) *)
  | If of expr * statement list * statement list option
  (** if relExpr then statSeq [else statSeq] fi *)
  | While of expr * statement list
  (** while relExpr do statSeq od *)
  | Repeat of statement list * expr
  (** repeat statSeq until relExpr *)
  | Return of expr option
  (** return [relExpr] *)

and assign_rhs =
  | AssignValue of assign_op * expr
  (** x = e, x += e, etc. *)
  | UnaryAssign of unary_post
  (** x++, x-- *)

(** varDecl = typeDecl ident { "," ident } ";" *)
type var_decl = type_decl * string list

(** paramDecl = paramType ident *)
type param_decl = param_type * string

(** funcBody = "{" { varDecl } statSeq "}" ";" *)
type func_body = var_decl list * statement list

(** funcDecl = "function" ident formalParam ":" ( "void" | type ) funcBody *)
type func_decl = string * param_decl list * base_type option * func_body

(** computation = "main" { varDecl } { funcDecl } "{" statSeq "}" "." *)
type computation = var_decl list * func_decl list * statement list
