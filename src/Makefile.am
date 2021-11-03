# virt-top
# Copyright (C) 2007-2021 Red Hat Inc., Richard W.M. Jones
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.

CLEANFILES = *~ *.bak *.orig *.rej
CLEANFILES += *.cmi *.cmo *.cma *.cmx *.cmxa dll*.so *.a *.annot

EXTRA_DIST = \
	.depend \
	collect.ml \
	collect.mli \
	csv_output.ml \
	csv_output.mli \
	dummy.c \
	main.ml \
	opt_calendar.ml \
	opt_csv.ml \
	opt_gettext.ml \
	opt_xml.ml \
	redraw.ml \
	redraw.mli \
	screen.ml \
	screen.mli \
	stream_output.ml \
	stream_output.mli \
	top.ml \
	top.mli \
	types.ml \
	types.mli \
	utils.ml \
	utils.mli \
	version.ml \
	virt-top.pod

OCAMLPACKAGES = -package unix,curses,str,libvirt

if HAVE_PKG_GETTEXT
OCAMLPACKAGES  += -package gettext-stub
endif

BOBJS = \
	version.cmo \
	opt_gettext.cmo \
	utils.cmo \
	types.cmo \
	collect.cmo \
	screen.cmo \
	redraw.cmo \
	csv_output.cmo \
	stream_output.cmo \
	top.cmo
if HAVE_PKG_XML_LIGHT
BOBJS += opt_xml.cmo
OCAMLPACKAGES += -package xml-light
endif
if HAVE_PKG_CSV
BOBJS += opt_csv.cmo
OCAMLPACKAGES += -package csv
endif
if HAVE_PKG_CALENDAR
BOBJS += opt_calendar.cmo
OCAMLPACKAGES += -package calendar
endif
BOBJS += main.cmo

XOBJS = $(BOBJS:.cmo=.cmx)

OCAMLFLAGS = -g -warn-error +C+D+E+F+L+M+P+S+U+V+Y+Z+X-3 -ccopt '@CFLAGS@'
OCAMLLIBS =

bin_PROGRAMS = virt-top

virt_top_SOURCES = dummy.c

if !HAVE_OCAMLOPT
OBJECTS = $(BOBJS)
else
OBJECTS = $(XOBJS)
endif

virt_top_DEPENDENCIES = $(OBJECTS)
virt_top_LINK = \
	../ocaml-link.sh -cclib '$(OCAMLLIBS)' -- \
	  $(OCAMLFIND) $(OCAMLBEST) $(OCAMLFLAGS) $(OCAMLPACKAGES) \
	  $(OBJECTS) -o $@

.mli.cmi:
	$(OCAMLFIND) ocamlc $(OCAMLFLAGS) $(OCAMLPACKAGES) -c $< -o $@
.ml.cmo:
	$(OCAMLFIND) ocamlc $(OCAMLFLAGS) $(OCAMLPACKAGES) -c $< -o $@
.ml.cmx:
	$(OCAMLFIND) ocamlopt $(OCAMLFLAGS) $(OCAMLPACKAGES) -c $< -o $@

# Dependencies.
.depend: $(srcdir)/*.ml $(srcdir)/*.mli
	../ocaml-dep.sh $^
-include .depend

# Manual page.
if HAVE_PERLDOC

virt-top.1: virt-top.pod
	pod2man -u --section 1 -c "Virtualization Support" \
		--release "$(PACKAGE_NAME)-$(PACKAGE_VERSION)" \
		$< > $@

virt-top.txt: virt-top.pod
	pod2text $< > $@

CLEANFILES += virt-top.1 virt-top.txt

endif
