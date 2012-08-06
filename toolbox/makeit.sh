#!/bin/sh -x
rm -rf debforge RPMS.drbl-test
./packit.sh
./make-rpm.sh
./make-deb.sh
