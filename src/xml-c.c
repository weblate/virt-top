/* 'top'-like tool for libvirt domains.
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
*/

#include <config.h>

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include <caml/alloc.h>
#include <caml/fail.h>
#include <caml/memory.h>
#include <caml/mlvalues.h>

#include <libxml/xpath.h>
#include <libxml/xpathInternals.h>

/* xpathobj contains a list of dev attributes, return the list
 * as an OCaml array of strings.
 */
static value
get_devs (xmlDocPtr doc, xmlXPathObjectPtr xpathobj)
{
  CAMLparam0 ();
  CAMLlocal2 (rv, nodev);
  const xmlNodeSetPtr nodes = xpathobj->nodesetval;
  size_t i, nr_nodes;
  xmlNodePtr node;
  char *str;
  xmlAttrPtr attr;

  if (nodes == NULL || nodes->nodeNr == 0)
    rv = caml_alloc (0, 0);
  else {
    /* Count the nodes that contain data. */
    nr_nodes = 0;
    for (i = 0; i < nodes->nodeNr; ++i) {
      node = nodes->nodeTab[i];
      if (node->type != XML_ATTRIBUTE_NODE)
        continue;
      nr_nodes++;
    }

    rv = caml_alloc (nr_nodes, 0);
    nr_nodes = 0;
    for (i = 0; i < nodes->nodeNr; ++i) {
      node = nodes->nodeTab[i];
      if (node->type != XML_ATTRIBUTE_NODE)
        continue;
      attr = (xmlAttrPtr) node;
      str = (char *) xmlNodeListGetString (doc, attr->children, 1);
      nodev = caml_copy_string (str);
      free (str);
      Store_field (rv, nr_nodes, nodev);
      nr_nodes++;
    }
  }

  CAMLreturn (rv);
}

/* external get_blk_net_devs : string -> string array * string array */
value
get_blk_net_devs (value xmlv)
{
  CAMLparam1 (xmlv);
  CAMLlocal3 (rv, blkdevs, netifs);
  xmlDocPtr doc;
  xmlXPathContextPtr xpathctx;
  xmlXPathObjectPtr xpathobj;
  const char *expr;

  /* For security reasons, call xmlReadMemory (not xmlParseMemory) and
   * pass XML_PARSE_NONET.
   */
  doc = xmlReadMemory (String_val (xmlv), caml_string_length (xmlv),
                       NULL, NULL, XML_PARSE_NONET);
  if (doc == NULL)
    caml_invalid_argument ("xmlReadMemory: unable to parse XML");

  xpathctx = xmlXPathNewContext (doc);
  if (xpathctx == NULL)
    caml_invalid_argument ("xmlXPathNewContext: unable to create new context");

  expr = "//devices/disk/target/@dev";
  xpathobj = xmlXPathEvalExpression (BAD_CAST expr, xpathctx);
  if (xpathobj == NULL)
    caml_invalid_argument (expr);

  blkdevs = get_devs (doc, xpathobj);
  xmlXPathFreeObject (xpathobj);

  expr = "//devices/interface/target/@dev";
  xpathobj = xmlXPathEvalExpression (BAD_CAST expr, xpathctx);
  if (xpathobj == NULL)
    caml_invalid_argument (expr);

  netifs = get_devs (doc, xpathobj);
  xmlXPathFreeObject (xpathobj);

  xmlXPathFreeContext (xpathctx);
  xmlFreeDoc (doc);

  rv = caml_alloc (2, 0);
  Store_field (rv, 0, blkdevs);
  Store_field (rv, 1, netifs);
  CAMLreturn (rv);
}
