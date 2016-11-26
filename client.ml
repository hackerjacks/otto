open Errable
open Comm

type config = {
  remote_port : int; (* Base port the C&C server is running on *)
  remote_ip : Message.ip; (* IP of the C&C server *)
  test_dir : string; (* Directory in which to download files and run tests *)
}

(* Pulls tests from the C&C server, runs them, and responds to the server with
 * a summary of the test results. *)
module type Client = sig
  type t

  (* make initializes a new client *)
  val make : config -> t errable

  (* main runs the client until the testing server goes down or
   * broadcasts the fact that there are no more tests to run. *)
  val main : t -> unit errable

  (* Frees any resources held by a client. *)
  val close : t -> t

end

module ClientImpl : Client = struct
  type t = {
    remote_port : int;
    remote_ip : Message.ip;
    test_dir : string;
    sub : SubCtxt.t;          (* For subscribing to the heartbeat *)
    hb_resp : RespCtxt.t;     (* For responding to the heartbeat *)
    pull : PullCtxt.t;        (* For pulling tests *)
    file_req : ReqCtxt.t;     (* For getting files to grade *)
    return : ReqCtxt.t        (* For returning graded results *)
  }

  let make conf =
    let o = {
      remote_port = conf.remote_port;
      remote_ip   = conf.remote_ip;
      test_dir    = conf.test_dir;
      sub         = SubCtxt.make {port = conf.remote_port;
                                  remote_ip = conf.remote_ip};
      pull        = PullCtxt.make {port = conf.remote_port + 1;
                                  remote_ip = conf.remote_ip};
      file_req    = ReqCtxt.make {port = conf.remote_port + 2;
                                  remote_ip = conf.remote_ip};
      return      = ReqCtxt.make {port = conf.remote_port + 3;
                                  remote_ip = conf.remote_ip};
      hb_resp     = RespCtxt.make {port = conf.remote_port + 4}
    } in
    o

  (* execute pulled commands and returns unit if successful, and raises failure
   * otherwise. A command execution is 'successful' if its exit code is 0 *)
  let execute commands =
    let exit_codes = List.map Sys.command commands in
    let sum = List.fold_left (+) 0 exit_codes in
    if sum = 0 then () else failwith "failed to execute pulled commands"

  let rec convert_files files =
    failwith "unimplemented"
    (* TODO: takes in FileCrawler.files and turns them into
     * actual files in the current working directory *)

  (* Helper to make a new directory named netid containing all needed files *)
  let make_test_dir netid files =
    mkdir netid Oo770; (* not sure about the permissions *)
    chdir netid;
    convert_files files;
    ()

  (* Helper to extract all lines from an open in_channel *)
  let rec get_results channel acc =
    try
      let new_acc = acc ^ (read_line channel) in
      get_results channel new_acc
    with
      | _ -> acc

  (* Helper to set up and run tests for a given assignment *)
  let run_tests netid files commands =
    let old = Unix.dup Unix.stdout in
    let new_out = open_out netid in
    Unix.dup2 (Unix.descr_of_out_channel new_out) Unix.stdout;
    let cur = getcwd () in
    make_test_dir netid files;
    execute (!commands);
    chdir cur;
    let results_in = open_in netid in
    let results = get_results results_in "" in
    close_in results_in;
    flush stdout;
    Unix.dup2 old Unix.stdout;
    results

  let timeout t (u : unit) = failwith "unimplemented"
  (* TODO: helper function to implement timing out *)
  (* This should be run in its own thread during execute *)
  (* The thread should then be killed at the end of execute *)

  (* TODO: helper function for receiving and responding to heartbeats *)
  (* This will also be responsible for checking when grading is done *)
  (* When it is, it should set the value at [done] to true *)
  let hb_handler c done (u : unit) =
    failwith "unimplemented"

  let main c =
    (* TODO: set up a thread running the heartbeat check function *)
    let done = ref false in
    let hb = Async.run_in_background (hb_handler c done) in

    let rec main_loop c done =
      let netid = ref "" in
      let timeout = ref -1 in
      let commands = ref [] in
      let do_on_pull m = match (Message.unmarshal m) with
        | TestSpec(key,t,cmds) -> netid:=key; timeout:=t; commands:=cmds
        | _ -> raise Comm.Invalid_ctxt
      in
      let () = PullCtxt.connect do_on_pull c.pull in
      (*---------- everything for pull up to here ----------*)
      let files = ref [] in
      let req_mes = FileReq (!netid) in
      match (Message.unmarshal (ReqCtxt.send req_mes c.file_req)) with
      | Err e ->  Err e
      | Ok f  ->  files := f;
                  let results = run_tests (!netid) (!files) (!commands) in
                  let res_mes = TestCompletion (!netid, results) in
                  let ack = ReqCtxt.send res_mes c.return) in
                  if (!done) then () else main_loop c done
    in main_loop c false

  let close c =
    let s = SubCtxt.close c.sub in
    let h = RespCtxt.close c.hb_resp in
    let p = PullCtxt.close c.pull in
    let f = ReqCtxt.close c.file_req in
    let r = ReqCtxt.close c.return in
    let o = {
      remote_port = c.remote_port;
      remote_ip   = c.remote_ip;
      test_dir    = c.test_dir;
      sub         = s;
      pull        = p;
      file_req    = f;
      return      = r;
      hb_resp     = h
    } in
    o


end
