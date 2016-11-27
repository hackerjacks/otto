val try_finally : (unit -> 'a) -> (unit -> unit) -> 'a

val read_all_lines : string -> string list

val remove_extension : string -> string

module type Monad = sig
  type 'a t
  val return : 'a -> 'a t
  val bind : 'a t -> ('a -> 'b t) -> 'b t
  val fmap : 'a t -> ('a -> 'b) -> 'b t
  val join : 'a t t -> 'a t
  val coerce : 'a t -> 'a

  val (>>=) : 'a t -> ('a -> 'b t) -> 'b t
  val (>>>) : 'a t -> ('a -> 'b) -> 'b t
  val (?!) : 'a t -> 'a
end

module type ONCE = sig
  type 'a t

  val make : unit -> 'a t
  val is_val : 'a t -> bool
  val coerce : 'a t -> 'a
  val set : 'a -> 'a t -> unit
end

module Once : ONCE

module Maybe : Monad with type 'a t = 'a option
