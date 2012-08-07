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

all: 
	@echo "No need to compile..."

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
	cp -a doc samples prerun postrun scripts/sbin $(DESTDIR)/$(SHAREDIR)/

	# install config files
	install -d $(DESTDIR)/etc/drbl/
	cp -a conf/* $(DESTDIR)/etc/drbl/
