#!/bin/sh -x
PKG="clonezilla"
RPMBUILD="${HOME}/rpmbuild/"
SPEC_FILE="$PKG.spec"

set -e
#
[ ! -f "$SPEC_FILE" ] && echo "Can NOT find spec file $SPEC_FILE" && exit 1

#
VER=`grep ^Version $SPEC_FILE |sed -e "s/\t/ /g" -e "s/ \+/ /g" |cut  -d":" -f2 |tr -d " "`
RELEASE=`grep ^Release $SPEC_FILE |sed -e "s/\t/ /g" -e "s/ \+/ /g" |cut  -d":" -f2 |tr -d " "`
echo "VER, RELEASE: $VER, $RELEASE"

TARBALL="$PKG-$VER.tar.xz"
#check if necessary files exist...
[ -f $SPEC_FILE ] || exit 0
[ -f $TARBALL ] || exit 0

echo "Prepare the necessary files..."
#clean old file
[ -d ~/rpmbuild/SOURCES/$PKG-$VER ] && rm -rf ~/rpmbuild/SOURCES/$PKG-$VER
[ -d ~/rpmbuild/BUILD/$PKG-$VER ] && rm -rf ~/rpmbuild/BUILD/$PKG-$VER

mkdir -p ~/rpmbuild/SOURCES/$PKG-$VER

# extract the source tarball
# clean the tmp directory

# package the tar ball
cp $TARBALL ~/rpmbuild/SOURCES/$PKG-$VER/

echo "We are ready to build rpm file now..."

# build it
rpmbuild -ba $SPEC_FILE

# clean the RPMS.drbl directory
[ -d RPMS.drbl-test ] && rm -rf RPMS.drbl-test
mkdir -p RPMS.drbl-test

# cp them to directory rpms 
cp -fa $TARBALL RPMS.drbl-test
cp -fv doc/ChangeLog.txt RPMS.drbl-test
cp -fv $RPMBUILD/SRPMS/$PKG-$VER-$RELEASE.src.rpm $RPMBUILD/RPMS/$PKG-$VER-$RELEASE.*.rpm RPMS.drbl-test

#clean the used file
[ -d ~/rpmbuild/SOURCES/$PKG-$VER ] && rm -rf ~/rpmbuild/SOURCES/$PKG-$VER
[ -d ~/rpmbuild/BUILD/$PKG-$VER ] && rm -rf ~/rpmbuild/BUILD/$PKG-$VER
