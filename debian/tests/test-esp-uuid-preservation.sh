#!/bin/bash
# Test file system UUID preservation for ESP FAT partitions during clone/restore

set -e

echo "=== Running ESP UUID Preservation Tests ==="

# Create mock bin directory
MOCK_DIR="/tmp/mock-esp-uuid-bin"
rm -rf "$MOCK_DIR"
mkdir -p "$MOCK_DIR"

# Log files for capturing mock execution arguments
MKFS_VFAT_LOG="/tmp/mock_mkfs_vfat_calls.log"
rm -f "$MKFS_VFAT_LOG"

# Write mock blkid
cat <<'EOF' > "$MOCK_DIR/blkid"
#!/bin/bash
# Check if we are querying UUID
if [[ "$*" == *"-s UUID"* ]]; then
  if [[ "$*" == *"/dev/sda1"* ]]; then
    echo "1234-ABCD"
  elif [[ "$*" == *"/tmp/esp_part_img."* ]]; then
    echo "FEDC-5678"
  else
    echo "9999-8888"
  fi
else
  # Generic fallback for other blkid queries (like TYPE)
  echo 'TYPE="vfat"'
fi
EOF
chmod +x "$MOCK_DIR/blkid"

# Write mock mkfs.vfat
cat <<'EOF' > "$MOCK_DIR/mkfs.vfat"
#!/bin/bash
echo "mkfs.vfat called with args: $*" >> /tmp/mock_mkfs_vfat_calls.log
EOF
chmod +x "$MOCK_DIR/mkfs.vfat"

# Write mock mount & umount
cat <<'EOF' > "$MOCK_DIR/mount"
#!/bin/bash
exit 0
EOF
chmod +x "$MOCK_DIR/mount"

cat <<'EOF' > "$MOCK_DIR/umount"
#!/bin/bash
exit 0
EOF
chmod +x "$MOCK_DIR/umount"

# Write mock sfdisk
cat <<'EOF' > "$MOCK_DIR/sfdisk"
#!/bin/bash
echo "/dev/sda1 : type=C12A7328-F81F-11D2-BA4B-00A0C93EC93B,"
EOF
chmod +x "$MOCK_DIR/sfdisk"

# Export original PATH and prepend MOCK_DIR
export ORIGINAL_PATH="$PATH"
export PATH="$MOCK_DIR:$PATH"

# Load the ocs-functions script
# To prevent real/drbl files from failing to load, we stub out external sourcing or configs
# since we are running in a standalone test.
# Let's mock functions and set required global variables before sourcing.
export OCS_LOGFILE="/tmp/ocs-test.log"
touch "$OCS_LOGFILE"

# Source the functions
. scripts/sbin/ocs-functions

# Override helper functions that we don't want to run fully
clean_filesystem_header_in_dev() { :; }
check_if_dev_busy() { :; }
get_disk_from_part() { echo "sda"; }
gen_proc_partitions_map_file() {
  partition_table="$(mktemp /tmp/parttable-ocs.XXXXXX)"
  echo "sdb1" > "$partition_table"
}
is_partclone_support_fs() {
  return 0
}
inform_kernel_partition_table_changed() {
  :
}

# --- TEST 1: local_partition_to_partiton_clone ---
echo "--- Testing Test 1: local_partition_to_partiton_clone ---"
# Set necessary environment
export FORCE_TO_USE_DD="no"
export USE_PARTCLONE_IN_OCS_ONTHEFLY="yes"
export do_ntfs_512to4k_fix_flag="yes"
export do_ntfs_4kto512_fix_flag="no"
# Set the part variable to match what sfdisk returns
export part="/dev/sda1"

# Call the clone function under set +e since Clonezilla functions are not designed for set -e
set +e
local_partition_to_partiton_clone vfat /dev/sda1 /dev/sdb1
set -e

# --- TEST 2: do_unicast_stdin_restore ---
echo "--- Testing Test 2: do_unicast_stdin_restore ---"
# Prepare image directory and files
IMAGE_DIR="/tmp/mock_image_dir"
rm -rf "$IMAGE_DIR"
mkdir -p "$IMAGE_DIR"

# Touch dummy files to satisfy is_partclone_image check
partclone_support_fs="vfat"
touch "$IMAGE_DIR/sda1.vfat-ptcl-img"
echo "/dev/sdb1 : type=C12A7328-F81F-11D2-BA4B-00A0C93EC93B," > "$IMAGE_DIR/sda-pt.sf"

# Stub out unicast_restore_by_partclone to simulate restoring the raw file
unicast_restore_by_partclone() {
  # $part contains the temporary file name. Let's create it and mock its UUID via blkid.
  # Our mock blkid will return FEDC-5678 if the file starts with /tmp/esp_part_img.
  touch "$part"
  rc=0
}

# Call the restore function under set +e since Clonezilla functions are not designed for set -e
set +e
do_unicast_stdin_restore "$IMAGE_DIR" "sda1" /dev/sdb1
set -e

# Clean up path
export PATH="$ORIGINAL_PATH"
rm -rf "$MOCK_DIR" "$IMAGE_DIR"

# Verify mock logs
echo "Verifying test outcomes..."
if [ ! -f "$MKFS_VFAT_LOG" ]; then
  echo "FAIL: mkfs.vfat log not created!"
  exit 1
fi

cat "$MKFS_VFAT_LOG"

if ! grep -q "\-i 1234ABCD /dev/sdb1" "$MKFS_VFAT_LOG"; then
  echo "FAIL: local_partition_to_partiton_clone did not preserve the UUID '1234ABCD'!"
  exit 1
fi

if ! grep -q "\-i FEDC5678 /dev/sdb1" "$MKFS_VFAT_LOG"; then
  echo "FAIL: do_unicast_stdin_restore did not preserve the UUID 'FEDC5678'!"
  exit 1
fi

echo "=== PASS: All ESP UUID Preservation Tests Passed Successfully! ==="
rm -f "$MKFS_VFAT_LOG"
exit 0
