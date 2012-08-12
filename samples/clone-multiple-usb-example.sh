#!/bin/bash
# Author: Steven Shiau <steven _at_ nchc org tw>
# License: GPL

# This example shows how to clone an image to 5 USB flash drives in a same machine by using Clonezilla live.
# Thanks to T. C. Lin <tclin _at_ mail dfes tpc edu tw> for this idea and testing, and Alvin Su for debuging.

# For more details, please refer to:
# http://drbl.sourceforge.net/faq/fine-print.php?path=./2_System/98_one_image_to_multiple_disks.faq#98_one_image_to_multiple_disks.faq

# ///WARNING/// This program is really dangerous! You have to know what you are doing!

# ********************************************
# ****************READ ME First **************
# ********************************************
# First we assume we have saved the source USB flash drive (/dev/sdb) as an image called "myusbimg", then we can create another 4 temp images using linking by:
#  create-ocs-tmp-img -t /home/partimag myusbimg myusbimg_sdc sdb sdc
#  create-ocs-tmp-img -t /home/partimag myusbimg myusbimg_sdd sdb sdd
#  create-ocs-tmp-img -t /home/partimag myusbimg myusbimg_sde sdb sde
#  create-ocs-tmp-img -t /home/partimag myusbimg myusbimg_sdf sdb sdf
#

# Settings:
# To avoid mistake, we comment the target disks first. You have to uncomment it to make the following work.
# dsk="sdc sdd sde sdf"
grub_part_no="4"  # e.g. The grub partition, /dev/sdc4
image_name="myusbimg"

# Load functions and config file
DRBL_SCRIPT_PATH="${DRBL_SCRIPT_PATH:-/usr/share/drbl}"

. $DRBL_SCRIPT_PATH/sbin/drbl-conf-functions
. /etc/drbl/drbl-ocs.conf
. $DRBL_SCRIPT_PATH/sbin/ocs-functions

# Create partition table first. If we do not do this first, sfdisk will wait for the lock file to be released, so the 2nd clone won't start in any case.
for i in $dsk; do
  [ -z "$(grep -Ew "$i" /proc/partitions)" ] && continue
  echo "Creating the partition table for $i..."
  sfdisk --force /dev/$i < $ocsroot/${image_name}_${i}/${i}-pt.sf
done

for i in $dsk; do
  [ -z "$(grep -Ew "$i" /proc/partitions)" ] && continue
  echo "Restoring image for disk $i..."
  # use -k to skip sfdisk.
  ocs-sr -g /dev/${i}${grub_part_no} -k -nogui -b -r -p true restoredisk "${image_name}_${i}" "$i" &
done
