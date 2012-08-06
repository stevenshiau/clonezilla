#!/bin/bash
# Steven Shiau <steven _at_ nchc org tw)
PKG="clonezilla"
SPEC_FILE="$PKG.spec"

set -e
#
[ ! -f "$SPEC_FILE" ] && echo "Can NOT find spec file $SPEC_FILE" && exit 1

#
VER=`grep ^Version $SPEC_FILE |sed -e "s/\t/ /g" -e "s/ \+/ /g" |cut  -d":" -f2 |tr -d " "`
echo "VER: $VER"

#
TARBALL=$PKG-$VER.tar.bz2

# check
[ ! -f "$TARBALL" ] && echo "Can NOT find file $TARBALL! Did you forget to update the rdate in file $PKG.spec ? Program Stop!!!" && exit 1

# mkdir for build
rm -rf debforge
mkdir debforge
tar -xvjf $TARBALL -C debforge/
cp -a debian debforge/$PKG-$VER/
cd debforge/$PKG-$VER
debuild --no-tgz-check --no-lintian
