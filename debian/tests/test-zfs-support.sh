#!/bin/bash
# Test suite for ZFS filesystem support in Clonezilla (saving, restoring, and cloning).
set -e

echo "=== Running Clonezilla ZFS Support Tests ==="

TMP_DIR="$(mktemp -d /tmp/test-zfs-XXXXXX)"
trap 'rm -rf "$TMP_DIR"' EXIT

MOCK_BIN="$TMP_DIR/bin"
mkdir -p "$MOCK_BIN"
export ORIGINAL_PATH="$PATH"
export PATH="$MOCK_BIN:$PATH"

export ACTION_LOG="$TMP_DIR/action.log"
touch "$ACTION_LOG"
export ocs_log_dir="$TMP_DIR"

# -----------------------------------------------------------------------------
# TEST 1: Verify zfs is present in partclone_support_fs in conf/drbl-ocs.conf
# -----------------------------------------------------------------------------
echo "--- Test 1: Checking partclone_support_fs configuration ---"
# Clear any prior value and source conf/drbl-ocs.conf
unset partclone_support_fs
. conf/drbl-ocs.conf

if [[ " $partclone_support_fs " != *" zfs "* ]]; then
  echo "FAIL: 'zfs' not found in partclone_support_fs in conf/drbl-ocs.conf"
  echo "partclone_support_fs is: '$partclone_support_fs'"
  exit 1
fi
echo "PASS: 'zfs' is in partclone_support_fs: $partclone_support_fs"

# -----------------------------------------------------------------------------
# TEST 2: ocs-get-dev-info detection of zfs / zfs_member
# -----------------------------------------------------------------------------
echo "--- Test 2: Testing ocs-get-dev-info filesystem detection for ZFS ---"

# Mock udevadm
cat << 'EOF' > "$MOCK_BIN/udevadm"
#!/bin/bash
echo "ID_SERIAL_SHORT=mock-serial-short"
echo "ID_SERIAL=mock-serial-long"
exit 0
EOF
chmod +x "$MOCK_BIN/udevadm"

# Mock lsblk returning zfs_member
cat << 'EOF' > "$MOCK_BIN/lsblk"
#!/bin/bash
if [[ "$*" == *"/dev/sda1"* ]]; then
  echo '{
   "blockdevices": [
      {
         "name": "/dev/sda1",
         "type": "part",
         "size": "50G",
         "fstype": "zfs_member",
         "uuid": "1234567890abcdef",
         "partuuid": "mock-partuuid-zfs",
         "ptuuid": "mock-ptuuid-zfs",
         "partlabel": "zfs-pool-part",
         "label": "tank"
      }
   ]
}'
else
  echo '{"blockdevices": []}'
fi
exit 0
EOF
chmod +x "$MOCK_BIN/lsblk"

# Mock blkid returning TYPE="zfs_member"
cat << 'EOF' > "$MOCK_BIN/blkid"
#!/bin/bash
if [[ "$*" == *"/dev/sda1"* ]]; then
  if [[ "$*" == *"-o export"* ]]; then
    echo "DEVNAME=/dev/sda1"
    echo "UUID=1234567890abcdef"
    echo "TYPE=zfs_member"
    echo "LABEL=tank"
    echo "PARTUUID=mock-partuuid-zfs"
  else
    echo '/dev/sda1: UUID="1234567890abcdef" LABEL="tank" TYPE="zfs_member" PARTUUID="mock-partuuid-zfs"'
  fi
else
  exit 1
fi
exit 0
EOF
chmod +x "$MOCK_BIN/blkid"

FS_OUTPUT="$(sbin/ocs-get-dev-info /dev/sda1 fs)"
if [[ "$FS_OUTPUT" != "zfs" ]]; then
  echo "FAIL: ocs-get-dev-info returned '$FS_OUTPUT', expected 'zfs' when blkid has TYPE=zfs_member"
  exit 1
fi
echo "PASS: ocs-get-dev-info correctly mapped blkid TYPE=zfs_member to 'zfs'"

# Test fallback when blkid fails but lsblk returns zfs_member
cat << 'EOF' > "$MOCK_BIN/blkid"
#!/bin/bash
exit 1
EOF
chmod +x "$MOCK_BIN/blkid"

FS_OUTPUT_FALLBACK="$(sbin/ocs-get-dev-info /dev/sda1 fs)"
if [[ "$FS_OUTPUT_FALLBACK" != "zfs" ]]; then
  echo "FAIL: ocs-get-dev-info fallback returned '$FS_OUTPUT_FALLBACK', expected 'zfs'"
  exit 1
fi
echo "PASS: ocs-get-dev-info correctly mapped lsblk fstype=zfs_member to 'zfs' on blkid fallback"

# -----------------------------------------------------------------------------
# TEST 3: is_partclone_support_fs with zfs and zfs_member
# -----------------------------------------------------------------------------
echo "--- Test 3: Testing is_partclone_support_fs logic ---"
. scripts/sbin/ocs-functions

# Subshell with a clean PATH lacking partclone.zfs
NO_ZFS_BIN="$TMP_DIR/no_zfs_bin"
mkdir -p "$NO_ZFS_BIN"
if ( PATH="$NO_ZFS_BIN:/bin:/usr/bin" is_partclone_support_fs zfs ); then
  echo "FAIL: is_partclone_support_fs returned 0 when partclone.zfs does not exist!"
  exit 1
fi
echo "PASS: is_partclone_support_fs correctly returned 1 when partclone.zfs is missing"

# Create mock partclone.zfs
cat << 'EOF' > "$MOCK_BIN/partclone.zfs"
#!/bin/bash
echo "partclone.zfs $*" >> "$ACTION_LOG"
prev=""
for arg in "$@"; do
  if [ "$prev" = "-L" -o "$prev" = "--logfile" ]; then
    touch "$arg"
  fi
  prev="$arg"
done
exit 0
EOF
chmod +x "$MOCK_BIN/partclone.zfs"

if ! is_partclone_support_fs zfs; then
  echo "FAIL: is_partclone_support_fs returned 1 for zfs when partclone.zfs exists!"
  exit 1
fi
echo "PASS: is_partclone_support_fs returned 0 for zfs when partclone.zfs exists"

if ! is_partclone_support_fs zfs_member; then
  echo "FAIL: is_partclone_support_fs returned 1 for zfs_member!"
  exit 1
fi
echo "PASS: is_partclone_support_fs returned 0 for zfs_member due to normalization"

# -----------------------------------------------------------------------------
# TEST 4: save_part_by_partclone for zfs
# -----------------------------------------------------------------------------
echo "--- Test 4: Testing save_part_by_partclone for zfs ---"
export OCS_LOGFILE="$TMP_DIR/ocs.log"
touch "$OCS_LOGFILE"
export PARTCLONE_LOG="$TMP_DIR/partclone.log"
export PARTCLONE_SAVE_OPT=""
export target_dir="$TMP_DIR/image"
mkdir -p "$target_dir"

disk_full_test() { return 0; }
export -f disk_full_test
get_partclone_image_info() { return 0; }
export -f get_partclone_image_info
root_over_nfs() { echo "no"; }
export -f root_over_nfs
ocs_log_rotate() { return 0; }
export -f ocs_log_rotate

source_dev="/dev/sda1"
tgt_dir="$target_dir"
tgt_file="sda1"
VOL_LIMIT="0"
comp_suf="zst"
compress_prog_opt="cat"

# Run save_part_by_partclone zfs
save_part_by_partclone zfs

if ! grep -q "partclone.zfs.*-c -s /dev/sda1" "$ACTION_LOG"; then
  echo "FAIL: save_part_by_partclone zfs did not execute partclone.zfs with -c and -s /dev/sda1!"
  cat "$ACTION_LOG"
  exit 1
fi
echo "PASS: save_part_by_partclone correctly called partclone.zfs in clone mode (-c)"

# -----------------------------------------------------------------------------
# TEST 5: is_partclone_image for zfs images
# -----------------------------------------------------------------------------
echo "--- Test 5: Testing is_partclone_image for zfs image recognition ---"
touch "$target_dir/sda1.zfs-ptcl-img.zst"

if ! is_partclone_image "$target_dir" "sda1"; then
  echo "FAIL: is_partclone_image failed to recognize sda1.zfs-ptcl-img.zst!"
  exit 1
fi
echo "PASS: is_partclone_image successfully recognized sda1.zfs-ptcl-img.zst"

# -----------------------------------------------------------------------------
# TEST 6: unicast_restore_by_partclone for zfs
# -----------------------------------------------------------------------------
echo "--- Test 6: Testing unicast_restore_by_partclone for zfs ---"
target_d="$target_dir"
img_file="sda1"
part="/dev/sda1"
unzip_stdin_cmd="cat"
unzip_cmd_error="/dev/null"
partclone_img_info_tmp="$TMP_DIR/ptcl_tmp.log"
PARTCLONE_RESTORE_OPT=""

unicast_restore_by_partclone

if ! grep -q "partclone.zfs.*-s - -r -o /dev/sda1" "$ACTION_LOG"; then
  echo "FAIL: unicast_restore_by_partclone did not execute partclone.zfs in restore mode (-r)!"
  cat "$ACTION_LOG"
  exit 1
fi
echo "PASS: unicast_restore_by_partclone correctly called partclone.zfs in restore mode (-r)"

# -----------------------------------------------------------------------------
# TEST 7: local_partition_to_partiton_clone (device-to-device cloning)
# -----------------------------------------------------------------------------
echo "--- Test 7: Testing local_partition_to_partiton_clone for zfs ---"
export USE_PARTCLONE_IN_OCS_ONTHEFLY="yes"
export FORCE_TO_USE_DD="no"
export PARTCLONE_D2D_OPT="-a3"

tune_nvme_block_queue_settings() { return 0; }
export -f tune_nvme_block_queue_settings
clean_filesystem_header_in_dev() { return 0; }
export -f clean_filesystem_header_in_dev

local_partition_to_partiton_clone zfs /dev/sda1 /dev/sdb1

if ! grep -q "partclone.zfs.*-b -s /dev/sda1 -O /dev/sdb1" "$ACTION_LOG"; then
  echo "FAIL: local_partition_to_partiton_clone did not call partclone.zfs with -b -s /dev/sda1 -O /dev/sdb1!"
  cat "$ACTION_LOG"
  exit 1
fi
echo "PASS: local_partition_to_partiton_clone correctly ran partclone.zfs dev-to-dev (-b)"

# Also test when input is zfs_member (normalization)
local_partition_to_partiton_clone zfs_member /dev/sda1 /dev/sdc1

if ! grep -q "partclone.zfs.*-b -s /dev/sda1 -O /dev/sdc1" "$ACTION_LOG"; then
  echo "FAIL: local_partition_to_partiton_clone did not normalize zfs_member to zfs!"
  cat "$ACTION_LOG"
  exit 1
fi
echo "PASS: local_partition_to_partiton_clone normalized zfs_member to zfs"

# -----------------------------------------------------------------------------
# TEST 8: Network on-the-fly cloning (feed and receive)
# -----------------------------------------------------------------------------
echo "--- Test 8: Testing network onthefly feed and receive for zfs ---"
export ONTHEFLY_NET_PIPE="netcat"
export NC_CMD="true"
export NC_PORT="9000"
export NC_LOCAL_PORT_OPT=""
export NC_QUIT_OPT=""
export NC_CLIENT_EXTRA_OPT=""
export SOURCE_IP="127.0.0.1"
export reverse_connection="yes"
export reverse_connection_timeout="1"
export reverse_connection_retry_interval="1"
net_filter_comp="cat"
net_filter_decomp="cat"
netpipe_cli_cmd="cat"

# Test feed_dev_in_onthefly_server with reverse_connection="yes" (runs synchronously without backgrounding)
feed_dev_in_onthefly_server zfs /dev/sda1

if ! grep -q "partclone.zfs.*-c -s /dev/sda1 -o -" "$ACTION_LOG"; then
  echo "FAIL: feed_dev_in_onthefly_server did not run partclone.zfs with -c -s /dev/sda1 -o -!"
  cat "$ACTION_LOG"
  exit 1
fi
echo "PASS: feed_dev_in_onthefly_server fed zfs partition with partclone.zfs"

# Test onthefly_receive_partition_from_server_then_write
onthefly_receive_partition_from_server_then_write zfs /dev/sdb1

if ! grep -q "partclone.zfs.*-s - -r -o /dev/sdb1" "$ACTION_LOG"; then
  echo "FAIL: onthefly_receive_partition_from_server_then_write did not run partclone.zfs with -s - -r -o /dev/sdb1!"
  cat "$ACTION_LOG"
  exit 1
fi
echo "PASS: onthefly_receive_partition_from_server_then_write restored zfs stream with partclone.zfs"

# -----------------------------------------------------------------------------
# TEST 9: fsck_partition bypass for zfs
# -----------------------------------------------------------------------------
echo "--- Test 9: Testing fsck_partition skips offline fsck for zfs ---"
cat << 'EOF' > "$MOCK_BIN/fsck"
#!/bin/bash
echo "fsck executed: $*" >> "$ACTION_LOG"
exit 1
EOF
chmod +x "$MOCK_BIN/fsck"

fsck_partition zfs /dev/sda1

if grep -q "fsck executed.*sda1" "$ACTION_LOG"; then
  echo "FAIL: fsck_partition attempted offline fsck on zfs partition!"
  cat "$ACTION_LOG"
  exit 1
fi
echo "PASS: fsck_partition safely skipped offline fsck on zfs partition"

echo "=== All ZFS Support Tests Passed Successfully! ==="
exit 0
