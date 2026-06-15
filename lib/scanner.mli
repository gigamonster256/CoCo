type t

val init : string -> t
val next : t -> Token.t option * t
val scan : string -> Token.t list
