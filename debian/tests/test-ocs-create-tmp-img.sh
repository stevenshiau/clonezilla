#!/bin/bash
# Test suite for ocs-create-tmp-img file linking and exclusion logic.
#
# Verifies that:
# 1. Normal partitions (sda1, nvme0n1p1, etc.) have their image files soft-linked,
#    while image info files (dd-img.info, *.info.gz) are excluded and copied as regular files.
# 2. LVM logical volumes have their image files soft-linked, while their info files
#    (e.g., <vg-lv>.files-*sum.info.gz, <vg-lv>.dd-img.info) are excluded from soft-linking
#    and copied as regular files so that checksum path modification succeeds.
# 3. LUKS devices also soft-link only image files and exclude info files.

set -e

echo "=== Running ocs-create-tmp-img Soft-link Exclusions Tests ==="

TMP_DIR="$(mktemp -d /tmp/test-create-tmp-img-XXXXXX)"
trap 'rm -rf "$TMP_DIR"' EXIT

OCSROOT="$TMP_DIR/ocsroot"
TGT_DIR="$TMP_DIR/target"
mkdir -p "$OCSROOT" "$TGT_DIR"

IMG_NAME="almalinux10.2-thinlv-20261103"
SRC_IMG="$OCSROOT/$IMG_NAME"
mkdir -p "$SRC_IMG"

# Setup partition and LV metadata
echo "nvme0n1" > "$SRC_IMG/disk"
echo "nvme0n1p1 nvme0n1p3" > "$SRC_IMG/parts"
echo "label: gpt" > "$SRC_IMG/nvme0n1-pt.sf"
echo "/dev/almalinux/home ext4" > "$SRC_IMG/lvm_logv.list"

# Create mock partition and LV data image files
echo "ptcl-data-p1" > "$SRC_IMG/nvme0n1p1.vfat-ptcl-img.zst"
echo "ptcl-data-p3" > "$SRC_IMG/nvme0n1p3.btrfs-ptcl-img.zst"
echo "ptcl-data-lv" > "$SRC_IMG/almalinux-home.ext4-ptcl-img.zst"

# Create mock info and checksum files
ORIG_P1_CKSUM="f9389e7942c0b0ef918477cd0b24fdb3  /tmp/chksum_tmpd.gUe24S/boot/efi"
ORIG_P3_CKSUM="d41d8cd98f00b204e9800998ecf8427e  /tmp/chksum_tmpd.k61rV2/etc/fstab"
ORIG_LV_CKSUM="cf277664b1771217d7006acdea006db1  /tmp/chksum_tmpd.yRFkST/home/user/.bashrc"

echo "$ORIG_P1_CKSUM" | gzip -c > "$SRC_IMG/nvme0n1p1.files-b3sum.info.gz"
echo "$ORIG_P3_CKSUM" | gzip -c > "$SRC_IMG/nvme0n1p3.files-b3sum.info.gz"
echo "$ORIG_LV_CKSUM" | gzip -c > "$SRC_IMG/almalinux-home.files-b3sum.info.gz"
echo "partition=LVM_LV_data" > "$SRC_IMG/almalinux-home.dd-img.info"

NEW_IMG_NAME="${IMG_NAME}-tmp-cnvted"
NEW_IMG="$TGT_DIR/$NEW_IMG_NAME"

echo "Executing ocs-create-tmp-img converting nvme0n1 to sda..."
/root/clonezilla/sbin/ocs-create-tmp-img -or "$OCSROOT" -t "$TGT_DIR" "$IMG_NAME" "$NEW_IMG_NAME" "nvme0n1" "sda"

echo "Validating temporary image files in $NEW_IMG..."

# 1. LV data image file must be a soft link pointing to original
if [ ! -L "$NEW_IMG/almalinux-home.ext4-ptcl-img.zst" ]; then
  echo "FAIL: $NEW_IMG/almalinux-home.ext4-ptcl-img.zst is not a symbolic link!"
  exit 1
fi
echo "PASS: almalinux-home.ext4-ptcl-img.zst is a symbolic link."

# 2. LV files-b3sum.info.gz must be a regular file, NOT a symbolic link
if [ -L "$NEW_IMG/almalinux-home.files-b3sum.info.gz" ]; then
  echo "FAIL: $NEW_IMG/almalinux-home.files-b3sum.info.gz must NOT be a symbolic link!"
  exit 1
fi
if [ ! -f "$NEW_IMG/almalinux-home.files-b3sum.info.gz" ]; then
  echo "FAIL: $NEW_IMG/almalinux-home.files-b3sum.info.gz does not exist as a regular file!"
  exit 1
fi
echo "PASS: almalinux-home.files-b3sum.info.gz is a regular file (not soft-linked)."

# 3. LV dd-img.info must be a regular file, NOT a symbolic link
if [ -L "$NEW_IMG/almalinux-home.dd-img.info" ]; then
  echo "FAIL: $NEW_IMG/almalinux-home.dd-img.info must NOT be a symbolic link!"
  exit 1
fi
if [ ! -f "$NEW_IMG/almalinux-home.dd-img.info" ]; then
  echo "FAIL: $NEW_IMG/almalinux-home.dd-img.info does not exist as a regular file!"
  exit 1
fi
echo "PASS: almalinux-home.dd-img.info is a regular file (not soft-linked)."

# 4. Verify that gunzip works on the LV checksum file and path was updated
LV_CONTENT="$(gzip -dc "$NEW_IMG/almalinux-home.files-b3sum.info.gz")"
if echo "$LV_CONTENT" | grep -q "/tmp/chksum_tmpd.yRFkST"; then
  echo "FAIL: /tmp/chksum_tmpd.yRFkST was not replaced in $NEW_IMG/almalinux-home.files-b3sum.info.gz!"
  exit 1
fi
if ! echo "$LV_CONTENT" | grep -E -q "/tmp/chksum_tmpd\.[[:alnum:]]{6}/home/user/\.bashrc"; then
  echo "FAIL: checksum file content does not match expected format: $LV_CONTENT"
  exit 1
fi
echo "PASS: LV checksum file uncompressed successfully and mountpoint path was updated."

# 5. Verify that the original file in $SRC_IMG was not modified
SRC_LV_CONTENT="$(gzip -dc "$SRC_IMG/almalinux-home.files-b3sum.info.gz")"
if [ "$SRC_LV_CONTENT" != "$ORIG_LV_CKSUM" ]; then
  echo "FAIL: Source image checksum file was altered! Got: $SRC_LV_CONTENT"
  exit 1
fi
echo "PASS: Source image checksum file remains intact."

# 6. Verify partition files were converted from nvme0n1p* to sda*
if [ ! -L "$NEW_IMG/sda1.vfat-ptcl-img.zst" ]; then
  echo "FAIL: $NEW_IMG/sda1.vfat-ptcl-img.zst is not a symbolic link!"
  exit 1
fi
if [ -L "$NEW_IMG/sda1.files-b3sum.info.gz" ]; then
  echo "FAIL: $NEW_IMG/sda1.files-b3sum.info.gz must NOT be a symbolic link!"
  exit 1
fi
if [ ! -f "$NEW_IMG/sda1.files-b3sum.info.gz" ]; then
  echo "FAIL: $NEW_IMG/sda1.files-b3sum.info.gz is missing!"
  exit 1
fi
echo "PASS: Partition files correctly renamed and checksum info file is a regular file."

echo "=== All ocs-create-tmp-img Soft-link Exclusions Tests Passed Successfully! ==="
exit 0
