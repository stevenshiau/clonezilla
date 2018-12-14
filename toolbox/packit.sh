#!/bin/bash
# generate the ChangeLog.txt and create the tarball

# Settings
PKG="clonezilla"
FILES_DIRS="Makefile clonezilla.spec conf doc samples sbin bin scripts setup prerun postrun" 
SPEC_FILE="$PKG.spec"

set -e
#
VER="$(LC_ALL=C head -n 1 debian/changelog  | grep -i "^${PKG}" | grep -E -o "\(.*\)" | sed -r -e "s/\(//g" -e "s/\)//g" | cut -d"-" -f1)"
[ -z "$VER" ] && echo "No version found in debian/changelog! Program terminated!"
echo "VER: $VER"
RPM_VER=`grep ^Version $SPEC_FILE |sed -e "s/\t/ /g" -e "s/ \+/ /g" |cut  -d":" -f2 |tr -d " "`
echo "RPM VER: $RPM_VER"
if [ "$VER" != "$RPM_VER" ]; then
  echo "Versions do not match!"
  echo "Program terminated!"
  exit 1
fi

# Create the ChangeLog file
cat <<EOF > doc/ChangeLog.txt
Clonezilla, the opensource clone system.
Authors: Steven Shiau <steven _at_ clonezilla org>, Blake, Kuo-Lien Huang (klhaung _at_ gmail com), Ceasar Sun (ceasar _at_ clonezilla org), Jazz Wang (jazz _at_ clonezilla org) and Thomas Tsai (thomas _at_ clonezilla org)
License: GPL
https://clonezilla.org

EOF

cat debian/changelog >> doc/ChangeLog.txt

td="${PKG}-${VER}"

#
[ -d "$td" ] && rm -rf $td
mkdir -p $td
# Clean stale files in debian
cp -ar $FILES_DIRS $td/

echo $VER > $td/doc/VERSION
tar cJf $td.tar.xz --owner=root --group=root $td
rm -rf $td
