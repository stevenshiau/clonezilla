#!/bin/bash
# Steven Shiau <steven _at_ clonezilla org)

# Settings
PKG="clonezilla"

set -e

#
VER="$(LC_ALL=C head -n 1 debian/changelog  | grep -i "^${PKG}" | grep -E -o "\(.*\)" | sed -r -e "s/\(//g" -e "s/\)//g" | cut -d"-" -f1)"
[ -z "$VER" ] && echo "No version found in debian/changelog! Program terminated!"
echo "VER: $VER"

#
TARBALL=${PKG}-${VER}.tar.xz
TARBALL_ORIG=${PKG}_${VER}.orig.tar.xz

# check
[ ! -f "$TARBALL" ] && echo "Can NOT find file $TARBALL! Program Stop!!!" && exit 1

# mkdir for build
rm -rf debforge
mkdir debforge
(cd debforge; ln -fs ../$TARBALL $TARBALL_ORIG)
tar -xJf $TARBALL -C debforge/
cp -a debian debforge/$PKG-$VER/
cd debforge/$PKG-$VER
debuild
rm -f $TARBALL_ORIG
