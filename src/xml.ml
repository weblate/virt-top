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

module D = Libvirt.Domain

external get_blk_net_devs : string -> string array * string array
  = "get_blk_net_devs"

let parse_device_xml dom =
  try
    let xml = D.get_xml_desc dom in
    let blkdevs, netifs = get_blk_net_devs xml in
    Array.to_list blkdevs, Array.to_list netifs
  with
  | Invalid_argument _
  | Libvirt.Virterror _ -> [], [] (* ignore transient errors *)
