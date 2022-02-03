# Makefile
#
# License: GPL
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY, to the extent permitted by law; without
# even the implied warranty of MERCHANTABILITY or FITNESS FOR A
# PARTICULAR PURPOSE.
#
SHELL := bash -e
DESTDIR =
SHAREDIR = /usr/share/drbl/

all:	ocs-sbin 
	@echo "No need to compile..."

ocs-sbin:
	(cd sbin; ln -fs ocs-prep-repo prep-ocsroot)
	(cd sbin; ln -fs ocs-cvt-dev cnvt-ocs-dev)

build:
	@echo "Nothing to build."

install:
	# install exec files
	install -d ${DESTDIR}/usr/
	cp -a sbin bin ${DESTDIR}/usr/

	# install setup dir
	install -d $(DESTDIR)/$(SHAREDIR)/
	cp -a setup $(DESTDIR)/$(SHAREDIR)/

	# install other shared files
	cp -a samples prerun postrun scripts/sbin $(DESTDIR)/$(SHAREDIR)/
	install -d $(DESTDIR)/usr/share/clonezilla/
	cp -a doc $(DESTDIR)/usr/share/clonezilla/
	# erase an extra COPYING
	rm -f $(DESTDIR)/usr/share/clonezilla/doc/COPYING

	# install config files
	install -d $(DESTDIR)/etc/drbl/
	cp -a conf/* $(DESTDIR)/etc/drbl/
