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

SUBDIRS = src po

EXTRA_DIST = \
	.gitignore \
	HACKING

dist-hook: po/POTFILES po/POTFILES-ml

po/POTFILES: configure.ac
	rm -f $@ $@-t
	find . -name '*.c' | \
	grep -v '/$(PACKAGE_NAME)-$(PACKAGE_VERSION)/' | \
	LC_ALL=C sort > $@-t
	mv $@-t $@

po/POTFILES-ml: configure.ac
	rm -f $@ $@-t
	find . -name '*.ml' | \
	grep -v '/$(PACKAGE_NAME)-$(PACKAGE_VERSION)/' | \
	LC_ALL=C sort > $@-t
	mv $@-t $@

# Commit everything in current directory to HEAD, and set commit
# message to current version (only for maintainer).

maintainer-commit:
	git commit -a -m "Version $(VERSION)."

# Tag HEAD with current version (only for maintainer).

maintainer-tag:
	git tag -a "v$(VERSION)" -m "Version $(VERSION)" -f

# Maintainer only: check no files are missing from EXTRA_DIST rules,
# and that all generated files have been included in the tarball.
# (Note you must have done 'make dist')

maintainer-check-extra-dist:
	zcat $(PACKAGE_NAME)-$(VERSION).tar.gz | tar tf - | sort | \
	  sed 's,^$(PACKAGE_NAME)-$(VERSION)/,,' > tarfiles
	git ls-files | sort > gitfiles
	comm -13 tarfiles gitfiles > comm-out
	@echo Checking for differences between EXTRA_DIST and git ...
	cat comm-out
	[ ! -s comm-out ]
	rm tarfiles gitfiles comm-out
	@echo PASS: EXTRA_DIST tests
