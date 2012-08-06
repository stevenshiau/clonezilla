# License: GPL
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY, to the extent permitted by law; without
# even the implied warranty of MERCHANTABILITY or FITNESS FOR A
# PARTICULAR PURPOSE.
#
SHELL := /bin/bash
prefix = /${DESTDIR}
maindir = /opt/drbl/

all:
	@echo "No need to compile..."

install:
	install -d ${prefix}/$(maindir)/{bin,sbin,conf,samples}
	install -d ${prefix}/$(maindir)/setup/files/{ocs,gparted}
	install scripts/* ${prefix}/$(maindir)/sbin/
	install bin/* ${prefix}/$(maindir)/bin/
	cp -ar files/ocs/* ${prefix}/$(maindir)/setup/files/ocs/
	cp -ar files/gparted/* ${prefix}/$(maindir)/setup/files/gparted/
	install -m 644 conf/drbl-ocs.conf ${prefix}/$(maindir)/conf/
	install samples/* ${prefix}/$(maindir)/samples
