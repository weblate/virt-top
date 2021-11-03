(* 'top'-like tool for libvirt domains.
   (C) Copyright 2007-2021 Richard W.M. Jones, Red Hat Inc.
   http://libvirt.org/

   This program is free software; you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation; either version 2 of the License, or
   (at your option) any later version.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with this program; if not, write to the Free Software
   Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
*)

(* CSV output functions. *)

open Printf

open Utils
open Collect

module C = Libvirt.Connect

let chan = ref None

let csv_set_filename filename = chan := Some (open_out filename)

(* This code is adapted from OCaml CSV, published under the LGPLv2+
 * which is compatible with the license of virt-top.
 *)

let nl = Bytes.make 1 '\n'
let comma = Bytes.make 1 ','
let quote = Bytes.make 1 '"'
let output_newline chan = output chan nl 0 1
let output_comma chan = output chan comma 0 1
let output_quote chan = output chan quote 0 1

let is_space_or_tab c = c = ' ' || c = '\t'

let must_escape = Array.make 256 false
let () =
  List.iter (fun c -> must_escape.(Char.code c) <- true)
            ['\"'; '\\';  '\000'; '\b'; '\n'; '\r'; '\t'; '\026']

let must_quote chan s len =
  let quote = ref (is_space_or_tab (String.unsafe_get s 0)
                   || is_space_or_tab (String.unsafe_get s (len - 1))) in
  let n = ref 0 in
  for i = 0 to len-1 do
    let c = String.unsafe_get s i in
    if c = ',' || c = '\n' || c = '\r' then quote := true
    else if c = '"' then (
      quote := true;
      incr n
    )
  done;
  if !quote then !n else -1

let write_escaped chan field =
  let len = String.length field in
  if len > 0 then (
    let n = must_quote chan field len in
    if n < 0 then
      output chan (Bytes.unsafe_of_string field) 0 len
    else (
      let field =
        if n <= 0 then Bytes.unsafe_of_string field
        else (* There are some quotes to escape *)
          let s = Bytes.create (len + n) in
          let j = ref 0 in
          for i = 0 to len - 1 do
            let c = String.unsafe_get field i in
            if c = '"' then (
              Bytes.unsafe_set s !j '"'; incr j;
              Bytes.unsafe_set s !j '"'; incr j
            )
            else (Bytes.unsafe_set s !j c; incr j)
          done;
          s
      in
      output_quote chan;
      output chan field 0 (Bytes.length field);
      output_quote chan
    )
  )

let save_out chan = function
  | [] -> output_newline chan
  | [f] ->
     write_escaped chan f;
     output_newline chan
  | f :: tl ->
     write_escaped chan f;
     List.iter (
       fun f ->
         output_comma chan;
         write_escaped chan f
     ) tl;
     output_newline chan

let csv_write row =
  match !chan with
  | None -> ()                  (* CSV output not enabled *)
  | Some chan ->
     save_out chan row;
     (* Flush the output to the file immediately because we don't
      * explicitly close the channel.
      *)
     flush chan

(* Write CSV header row. *)
let write_csv_header (csv_cpu, csv_mem, csv_block, csv_net) block_in_bytes =
  csv_write (
    [ "Hostname"; "Time"; "Arch"; "Physical CPUs";
      "Count"; "Running"; "Blocked"; "Paused"; "Shutdown";
      "Shutoff"; "Crashed"; "Active"; "Inactive";
      "%CPU";
      "Total hardware memory (KB)";
      "Total memory (KB)"; "Total guest memory (KB)";
      "Total CPU time (ns)" ] @
      (* These fields are repeated for each domain: *)
    [ "Domain ID"; "Domain name"; ] @
    (if csv_cpu then [ "CPU (ns)"; "%CPU"; ] else []) @
    (if csv_mem then [ "Mem (bytes)"; "%Mem";] else []) @
    (if csv_block && not block_in_bytes
       then [ "Block RDRQ"; "Block WRRQ"; ] else []) @
    (if csv_block && block_in_bytes
       then [ "Block RDBY"; "Block WRBY"; ] else []) @
    (if csv_net then [ "Net RXBY"; "Net TXBY" ] else [])
  )

(* Write summary data to CSV file. *)
let append_csv (_, _, _, _, _, node_info, hostname, _) (* setup *)
               (csv_cpu, csv_mem, csv_block, csv_net)
               block_in_bytes
               { rd_doms = doms;
                 rd_printable_time = printable_time;
                 rd_nr_pcpus = nr_pcpus; rd_total_cpu = total_cpu;
                 rd_totals = totals } (* state *) =
  (* The totals / summary fields. *)
  let (count, running, blocked, paused, shutdown, shutoff,
       crashed, active, inactive,
       total_cpu_time, total_memory, total_domU_memory) = totals in

  let percent_cpu = 100. *. total_cpu_time /. total_cpu in

  let summary_fields = [
    hostname; printable_time; node_info.C.model; string_of_int nr_pcpus;
    string_of_int count; string_of_int running; string_of_int blocked;
    string_of_int paused; string_of_int shutdown; string_of_int shutoff;
    string_of_int crashed; string_of_int active; string_of_int inactive;
    sprintf "%2.1f" percent_cpu;
    Int64.to_string node_info.C.memory;
    Int64.to_string total_memory; Int64.to_string total_domU_memory;
    Int64.to_string (Int64.of_float total_cpu_time)
  ] in

  (* The domains.
   *
   * Sort them by ID so that the list of relatively stable.  Ignore
   * inactive domains.
   *)
  let doms = List.filter_map (
    function
    | _, Inactive -> None		(* Ignore inactive domains. *)
    | name, Active rd -> Some (name, rd)
  ) doms in
  let cmp (_, { rd_domid = rd_domid1 }) (_, { rd_domid = rd_domid2 }) =
    compare rd_domid1 rd_domid2
  in
  let doms = List.sort cmp doms in

  let string_of_int64_option = map_default Int64.to_string "" in

  let domain_fields = List.map (
    fun (domname, rd) ->
      [ string_of_int rd.rd_domid; domname ] @
	(if csv_cpu then [
	   string_of_float rd.rd_cpu_time; string_of_float rd.rd_percent_cpu
	 ] else []) @
        (if csv_mem then [
            Int64.to_string rd.rd_mem_bytes; Int64.to_string rd.rd_mem_percent
         ] else []) @
	(if csv_block then
           if block_in_bytes then [
	     string_of_int64_option rd.rd_block_rd_bytes;
	     string_of_int64_option rd.rd_block_wr_bytes;
	   ] else [
	     string_of_int64_option rd.rd_block_rd_reqs;
	     string_of_int64_option rd.rd_block_wr_reqs;
           ]
         else []) @
	(if csv_net then [
	   string_of_int64_option rd.rd_net_rx_bytes;
	   string_of_int64_option rd.rd_net_tx_bytes;
	 ] else [])
  ) doms in
  let domain_fields = List.flatten domain_fields in

  csv_write (summary_fields @ domain_fields)
