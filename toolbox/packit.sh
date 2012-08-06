#!/bin/sh -x
PKG="clonezilla"
RPMBUILD="${HOME}/rpmbuild/"
SPEC_FILE="$PKG.spec"

#
[ ! -f "$SPEC_FILE" ] && echo "Can NOT find spec file $SPEC_FILE" && exit 1

# Create the changelog file
mkdir -p doc
#
[ -f "doc/ChangeLog.txt" ] && rm -f doc/ChangeLog.txt
line_begin="$(grep -n "%changelog" $SPEC_FILE | awk -F":" '{print $1}')"
line_eng="$(wc -l $SPEC_FILE | awk -F" " '{print $1}')"
lines=$(($line_eng - $line_begin))
cat <<EOF > doc/ChangeLog.txt
Clonezilla, the opensource clone system
Author: Steven Shiau <steven _at_ nchc org tw>, Blake, Kuo-Lien Huang (klhaung _at_ gmail com), Ceasar Sun (ceasar _at_ nchc org tw), Jazz Wang (jazz _at_ nchc org tw) and Thomas Tsai (thomas _at_ nchc org tw)
License: GPL
http://clonezilla.org
http://clonezilla.nchc.org.tw

EOF

tail -n $lines $SPEC_FILE >> doc/ChangeLog.txt

#
VER=`grep ^Version $SPEC_FILE |sed -e "s/\t/ /g" -e "s/ \+/ /g" |cut  -d":" -f2 |tr -d " "`
echo "VER: $VER"

td="$PKG-$VER"
#check if necessary files exist...
[ -f $SPEC_FILE ] || exit 0
[ -d "$td" ] && rm -rf $td
# Clean stale files in debian
rm -rf $PKG/debian/{drbl,tmp}
mkdir -p $td
rsync -a Makefile clonezilla.spec conf doc samples sbin bin scripts setup $td/

tar cvjf $td.tar.bz2 --owner=root --group=root $td
rm -rf $td
[ -f $TARBALL ] || exit 0
