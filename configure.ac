# virt-top
# Copyright (C) 2007-2021 Red Hat Inc., Richard W.M. Jones
#
# This library is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public
# License as published by the Free Software Foundation; either
# version 2 of the License, or (at your option) any later version.
#
# This library is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public
# License along with this library; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301  USA

dnl Process this file with autoconf to produce a configure script.

AC_INIT([virt-top],[1.1.0])
AM_INIT_AUTOMAKE([foreign])
AC_CONFIG_MACRO_DIR([m4])

AC_PROG_INSTALL

dnl Enable GNU stuff.
AC_USE_SYSTEM_EXTENSIONS

dnl Check for basic C environment.
AC_PROG_CC_STDC
AC_PROG_CPP
AC_C_PROTOTYPES
test "x$U" != "x" && AC_MSG_ERROR([Compiler not ANSI compliant])
AM_PROG_CC_C_O

dnl Check support for 64 bit file offsets.
AC_SYS_LARGEFILE

dnl Check for basic OCaml environment & findlib.
AC_PROG_OCAML
if test "$OCAMLC" = "no"; then
    AC_MSG_ERROR([You must install the OCaml compiler])
fi

AM_CONDITIONAL([HAVE_OCAMLOPT],[test "$OCAMLBEST" = "opt"])

AC_PROG_FINDLIB
if test "x$OCAMLFIND" = "xno"; then
    AC_MSG_ERROR([OCaml findlib is required])
fi

dnl Use ocamlfind to find the required packages ...

dnl Check for required OCaml packages.
AC_CHECK_OCAML_PKG(unix)
if test "x$OCAML_PKG_unix" = "xno"; then
    AC_MSG_ERROR([Cannot find required OCaml package 'unix'])
fi

AC_CHECK_OCAML_PKG(libvirt)
if test "x$OCAML_PKG_libvirt" = "xno"; then
    AC_MSG_ERROR([Cannot find required OCaml package 'libvirt'])
fi

AC_CHECK_OCAML_PKG(curses)
if test "x$OCAML_PKG_curses" = "xno"; then
    AC_MSG_ERROR([Cannot find required OCaml package 'curses'])
fi

dnl Check for optional OCaml packages.
AC_CHECK_OCAML_PKG(calendar)
AC_CHECK_OCAML_PKG(gettext)
AC_CHECK_OCAML_PKG(xml-light)

AM_CONDITIONAL([HAVE_PKG_CALENDAR], [test "x$OCAML_PKG_calendar" != "xno"])
AM_CONDITIONAL([HAVE_PKG_GETTEXT],  [test "x$OCAML_PKG_gettext" != "xno"])
AM_CONDITIONAL([HAVE_PKG_XML_LIGHT],[test "x$OCAML_PKG_xml_light" != "xno"])

dnl Check if ocamlc/ocamlopt -runtime-variant _pic works.  It was
dnl added in OCaml >= 4.03, but in theory might be disabled by
dnl downstream distros.
OCAML_RUNTIME_VARIANT_PIC_OPTION=""
if test "x$OCAMLC" != "xno"; then
    AC_MSG_CHECKING([if OCaml ‘-runtime-variant _pic’ works])
    rm -f conftest.ml contest
    echo 'print_endline "hello world"' > conftest.ml
    if $OCAMLOPT conftest.ml -runtime-variant _pic -o conftest >&5 2>&5 ; then
        AC_MSG_RESULT([yes])
        OCAML_RUNTIME_VARIANT_PIC_OPTION="-runtime-variant _pic"
    else
        AC_MSG_RESULT([no])
    fi
    rm -f conftest.ml contest
fi
AC_SUBST([OCAML_RUNTIME_VARIANT_PIC_OPTION])

dnl Check for optional perldoc (for building manual pages).
AC_CHECK_PROG([HAVE_PERLDOC], perldoc, perldoc)
AM_CONDITIONAL([HAVE_PERLDOC], [test "x$HAVE_PERLDOC" = "xperldoc"])

dnl Check for recommended ocaml-gettext tool.
AC_CHECK_PROG([OCAML_GETTEXT], ocaml-gettext, ocaml-gettext)
AM_CONDITIONAL([HAVE_OCAML_GETTEXT],[test "x$OCAML_GETTEXT" = "xocaml-gettext"])

dnl Check for GNU gettext tools (optional).
AC_CHECK_PROG([XGETTEXT],[xgettext],[xgettext],[no])
AC_CHECK_PROG([MSGCAT],[msgcat],[msgcat],[no])
AC_CHECK_PROG([MSGFMT],[msgfmt],[msgfmt],[no])
AC_CHECK_PROG([MSGMERGE],[msgmerge],[msgmerge],[no])

dnl Check they are the GNU gettext tools.
AC_MSG_CHECKING([msgfmt is GNU tool])
if $MSGFMT --version >/dev/null 2>&1 && $MSGFMT --version | grep -q 'GNU gettext
'; then
    msgfmt_is_gnu=yes
else
    msgfmt_is_gnu=no
fi
AC_MSG_RESULT([$msgfmt_is_gnu])
AM_CONDITIONAL([HAVE_GNU_GETTEXT],
    [test "x$XGETTEXT" != "xno" && test "x$MSGCAT" != "xno" && test "x$MSGFMT" != "xno" && test "x$MSGMERGE" != "xno" && test "x$msgfmt_is_gnu" != "xno"])

dnl Check for gettext.
AM_GNU_GETTEXT([external])

dnl Write gettext modules for the programs.
dnl http://www.le-gall.net/sylvain+violaine/documentation/ocaml-gettext/html/reference-manual/ch03s04.html
AC_MSG_NOTICE([creating src/opt_gettext.ml])
rm -f src/opt_gettext.ml
echo "(* This file is generated automatically by ./configure. *)" > src/opt_gettext.ml
if test "x$OCAML_PKG_gettext" != "xno"; then
    # Gettext module is available, so use it.
    cat <<EOT >>src/opt_gettext.ml
module Gettext = Gettext.Program (
  struct
    let textdomain = "virt-top"
    let codeset = None
    let dir = None
    let dependencies = [[]]
  end
) (GettextStub.Native)
EOT
else
    # No gettext module is available, so fake the translation functions.
    cat <<EOT >>src/opt_gettext.ml
module Gettext = struct
  external s_ : string -> string = "%identity"
  external f_ : ('a -> 'b, 'c, 'd) format -> ('a -> 'b, 'c, 'd) format
    = "%identity"
  let sn_ : string -> string -> int -> string
    = fun s p n -> if n = 1 then s else p
  let fn_ : ('a -> 'b, 'c, 'd) format -> ('a -> 'b, 'c, 'd) format -> int
      -> ('a -> 'b, 'c, 'd) format
    = fun s p n -> if n = 1 then s else p
end
EOT
fi

dnl Summary.
echo "------------------------------------------------------------"
echo "Thanks for downloading" $PACKAGE_STRING
echo "------------------------------------------------------------"

dnl Produce output files.
AC_CONFIG_HEADERS([config.h])
AC_CONFIG_FILES([ocaml-dep.sh],  [chmod +x,-w ocaml-dep.sh])
AC_CONFIG_FILES([ocaml-link.sh], [chmod +x,-w ocaml-link.sh])
AC_CONFIG_FILES([Makefile
	po/Makefile
	src/Makefile
	src/version.ml
	])
AC_OUTPUT
