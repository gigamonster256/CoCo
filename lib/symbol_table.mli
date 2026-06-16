type func_sig =
  { params : string list
  ; ret : Ast.base_type option
  }

type t

val empty : unit -> t
val push_scope : t -> unit
val pop_scope : t -> unit
val add_var : t -> string -> string -> unit
val add_func : t -> string -> string list -> Ast.base_type option -> unit
val lookup_var : t -> string -> string option
val resolve_call : t -> string -> Ast.expr list -> func_sig option

val string_of_param_type : Ast.base_type * int -> string
val string_of_type_decl : Ast.base_type * int list -> string
val string_of_base_type : Ast.base_type -> string

val build : Ast.computation -> t
