exception Invalid_ctxt
exception Timeout

open Errable

type server_config =
  {
    port : int
  }

type client_config =
  {
    port : int;
    remote_ip : Message.ip
  }

(* A module representing a requester in the requester-responder
 * paradigm. *)
module type RequesterContext = sig
  type 'a t
  constraint 'a = [> `Req]

  (* [make init] creates a requester context *)
  val make : client_config -> 'a t
  (* [send mess t] sends a message using an initialized context t.
   * it should block until it receives a response or errors out. *)
  val send : Message.mes -> 'a t -> Message.mes errable

  (* [close t] frees whatever resources were opened in making the context *)
  val close : 'a t -> 'a t
end

(* Represents a responder in the requester-responder paradigm *)
module type ResponderContext = sig
  type 'a t
  constraint 'a = [> `Rep]

  (* [make init] creates a responder context *)
  val make : server_config -> 'a t

  (* [serve f t] blocks and serves a function with [f] as the method of
   *  responding to requests. *)
  val serve : (Message.mes -> (Message.mes -> unit) -> unit) -> 'a t -> unit

  (* [close t] frees whatever resources were opened in making the context *)
  val close : 'a t -> 'a t
end

(* Represents a publisher in the pub/sub paradigm. A publisher broadcasts
 * a message to all its subscribers *)
module type PublisherContext = sig
  type 'a t
  constraint 'a = [> `Pub]

  (* [make init] creates a publisher context *)
  val make : server_config -> 'a t

  (* [send m t] broadcasts [m] via context [t] to any subscribers *)
  val send : Message.mes -> 'a t -> unit

  (* [close t] frees whatever resources were opened in making the context *)
  val close : 'a t -> 'a t
end

(* Represents a subscriber in the pub/sub paradigm. A subscriber
 * receives all events broadcast by a publisher after the subscriber
 * connects to the publisher. *)
module type SubscriberContext = sig
  type 'a t
  constraint 'a = [> `Sub]

  (* [make init] creates a subscriber context *)
  val make : client_config -> 'a t

  (* [connect f t] connects to a publisher and calls f when the publisher
   * sends a message *)
  val connect : (Message.mes -> unit) -> 'a t -> unit

  (* [close t] frees whatever resources were opened in making the context *)
  val close : 'a t -> 'a t
end

(* Represents a pusher in the push/pull paradigm.
 * Broadcasts a message to a puller whose identity is known *)
module type PusherContext = sig
  type 'a t
  constraint 'a = [> `Push]

  (* [make init] creates a pusher context *)
  val make : server_config -> 'a t

  (* [push m t] broadcasts a message [m] to a certain puller [t] *)
  val push : Message.mes -> 'a t -> unit

  (* [close t] frees whatever resources were opened in making the context *)
  val close : 'a t -> 'a t
end

(* Represents a puller in the push/pull paradigm. All pullers
 * compete to receive any events broadcast by a pusher while the
 * pullers are connected to the pusher. *)
module type PullerContext = sig
  type 'a t
  constraint 'a = [> `Pull]

  (* [make init] creates a pullers context *)
  val make : client_config -> 'a t

  (* [connect f t] connects to a pusher and calls f when the pusher
   * sends a message *)
  val connect : (Message.mes -> unit) -> 'a t -> unit

  (* [close t] frees whatever resources were opened in making the context *)
  val close : 'a t -> 'a t
end



module ReqCtxt : RequesterContext
module RespCtxt : ResponderContext
module PubCtxt : PublisherContext
module SubCtxt : SubscriberContext
module PushCtxt : PusherContext
module PullCtxt : PullerContext
