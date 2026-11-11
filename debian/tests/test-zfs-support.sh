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

# -----------------------------------------------------------------------------
# TEST 10: gen_chksum_for_files_in_dev skips ZFS partition
# -----------------------------------------------------------------------------
echo "--- Test 10: Testing gen_chksum_for_files_in_dev skips ZFS partition ---"
export OCS_LOGFILE="$TMP_DIR/ocs.log"
touch "$OCS_LOGFILE"

cat << 'EOF' > "$MOCK_BIN/mount"
#!/bin/bash
echo "mount executed: $*" >> "$ACTION_LOG"
exit 1
EOF
chmod +x "$MOCK_BIN/mount"

cat << 'EOF' > "$MOCK_BIN/ocs-get-dev-info"
#!/bin/bash
dev="$1"
field="$2"
if [ "$field" = "filesystem" ] || [ "$field" = "fs" ]; then
  case "$dev" in
    /dev/sda1|/dev/nvme0n1p2|/dev/nvme0n1p4)
      echo "zfs"
      exit 0
      ;;
    /dev/nvme0n1p1)
      echo "vfat"
      exit 0
      ;;
    /dev/nvme0n1p3)
      echo "swap"
      exit 0
      ;;
    /dev/sdd1)
      echo "zfs_member"
      exit 0
      ;;
  esac
fi
exit 1
EOF
chmod +x "$MOCK_BIN/ocs-get-dev-info"

CHKSUM_TEST_DIR="$TMP_DIR/img_chksum"
mkdir -p "$CHKSUM_TEST_DIR"

rc_gen=0
gen_chksum_for_files_in_dev /dev/nvme0n1p2 "$CHKSUM_TEST_DIR" || rc_gen=$?
if [ "$rc_gen" -ne 0 ]; then
  echo "FAIL: gen_chksum_for_files_in_dev returned non-zero ($rc_gen) on ZFS partition!"
  exit 1
fi

if grep -q "mount executed.*/dev/nvme0n1p2" "$ACTION_LOG"; then
  echo "FAIL: gen_chksum_for_files_in_dev attempted to mount ZFS partition /dev/nvme0n1p2!"
  cat "$ACTION_LOG"
  exit 1
fi

if ! grep -q "ZFS file-level checksum generation requires zfs tools and kernel module, hence skip creating checksum file for partition /dev/nvme0n1p2" "$OCS_LOGFILE"; then
  echo "FAIL: gen_chksum_for_files_in_dev did not log expected skip notice for /dev/nvme0n1p2!"
  cat "$OCS_LOGFILE"
  exit 1
fi
echo "PASS: gen_chksum_for_files_in_dev gracefully skipped ZFS partition without mount attempt"

# -----------------------------------------------------------------------------
# TEST 11: inspect_chksum_for_files_in_dev skips ZFS partition
# -----------------------------------------------------------------------------
echo "--- Test 11: Testing inspect_chksum_for_files_in_dev skips ZFS partition ---"
rc_inspect=0
inspect_chksum_for_files_in_dev /dev/nvme0n1p2 "$CHKSUM_TEST_DIR" || rc_inspect=$?
if [ "$rc_inspect" -ne 0 ]; then
  echo "FAIL: inspect_chksum_for_files_in_dev returned non-zero ($rc_inspect) on ZFS partition!"
  exit 1
fi

if grep -q "mount executed.*/dev/nvme0n1p2" "$ACTION_LOG"; then
  echo "FAIL: inspect_chksum_for_files_in_dev attempted to mount ZFS partition /dev/nvme0n1p2!"
  cat "$ACTION_LOG"
  exit 1
fi

if ! grep -q "ZFS file-level checksum inspection requires zfs tools and kernel module, hence skip inspecting checksum for partition /dev/nvme0n1p2" "$OCS_LOGFILE"; then
  echo "FAIL: inspect_chksum_for_files_in_dev did not log expected skip notice for /dev/nvme0n1p2!"
  cat "$OCS_LOGFILE"
  exit 1
fi
echo "PASS: inspect_chksum_for_files_in_dev gracefully skipped ZFS partition without mount attempt"

# -----------------------------------------------------------------------------
# TEST 12: dev-fs.list processing loop skips zfs and zfs_member partitions
# -----------------------------------------------------------------------------
echo "--- Test 12: Testing dev-fs.list loop skips zfs and zfs_member partitions ---"
cat << 'EOF' > "$MOCK_BIN/mount"
#!/bin/bash
echo "mount executed: $*" >> "$ACTION_LOG"
args=("$@")
target_dir="${args[-1]}"
dev_arg="${args[-2]}"
dev_name="$(basename "$dev_arg")"
if [[ "$*" == *"/dev/nvme0n1p2"* ]] || [[ "$*" == *"/dev/nvme0n1p4"* ]] || [[ "$*" == *"/dev/sdd1"* ]]; then
  echo "ERROR: Attempted mount of ZFS partition!" >> "$ACTION_LOG"
  exit 1
fi
echo "$target_dir" > "$TMP_DIR/mounted_$dev_name"
mkdir -p "$target_dir"
echo "dummy vfat file" > "$target_dir/efi.bin"
exit 0
EOF
chmod +x "$MOCK_BIN/mount"

cat << 'EOF' > "$MOCK_BIN/umount"
#!/bin/bash
args=("$@")
target="${args[-1]}"
dev_name="$(basename "$target")"
if [ -f "$TMP_DIR/mounted_$dev_name" ]; then
  mnt="$(cat "$TMP_DIR/mounted_$dev_name")"
  rm -rf "$mnt"/* "$mnt"/.[!.]* "$mnt"/..?* 2>/dev/null || true
  rm -f "$TMP_DIR/mounted_$dev_name"
elif [ -d "$target" ]; then
  rm -rf "$target"/* "$target"/.[!.]* "$target"/..?* 2>/dev/null || true
fi
exit 0
EOF
chmod +x "$MOCK_BIN/umount"

DEV_FS_LIST="$CHKSUM_TEST_DIR/dev-fs.list"
cat << 'EOF' > "$DEV_FS_LIST"
# <Device name>   <File system>   <Size>
# File system is got from ocs-get-dev-info. It might be different from that of blkid or parted.
/dev/nvme0n1p1 vfat 953M
/dev/nvme0n1p2 zfs 1.8G
/dev/nvme0n1p4 zfs 13.8G
/dev/nvme0n1p3 swap 3.5G
EOF

chksum_cmd_for_files_in_dev="b3sum"
> "$OCS_LOGFILE"
while read dev_ x_fs y; do
  [ "$dev_" = "#" ] && continue
  [ "$x_fs" = "swap" -o "$x_fs" = "MS_Reserved_Partition" ] && continue
  if [ "$x_fs" = "zfs" -o "$x_fs" = "zfs_member" ]; then
    if ! is_zfs_kernel_supported; then
      [ "$BOOTUP" = "color" ] && $SETCOLOR_WARNING
      echo "ZFS file-level checksum generation requires zfs tools and kernel module, hence skip creating checksum file for partition $dev_." | tee --append ${OCS_LOGFILE}
      [ "$BOOTUP" = "color" ] && $SETCOLOR_NORMAL
      continue
    fi
  fi
  gen_chksum_for_files_in_dev "$dev_" "$CHKSUM_TEST_DIR"
done < "$DEV_FS_LIST"

if ! grep -q "ZFS file-level checksum generation requires zfs tools and kernel module, hence skip creating checksum file for partition /dev/nvme0n1p2" "$OCS_LOGFILE"; then
  echo "FAIL: dev-fs.list loop did not log skip notice for /dev/nvme0n1p2!"
  cat "$OCS_LOGFILE"
  exit 1
fi

if ! grep -q "ZFS file-level checksum generation requires zfs tools and kernel module, hence skip creating checksum file for partition /dev/nvme0n1p4" "$OCS_LOGFILE"; then
  echo "FAIL: dev-fs.list loop did not log skip notice for /dev/nvme0n1p4!"
  cat "$OCS_LOGFILE"
  exit 1
fi

if grep -q "ERROR: Attempted mount of ZFS partition" "$ACTION_LOG"; then
  echo "FAIL: Mount was erroneously attempted on ZFS partition in dev-fs.list!"
  cat "$ACTION_LOG"
  exit 1
fi

if [ ! -f "$CHKSUM_TEST_DIR/nvme0n1p1.files-b3sum.info.gz" ]; then
  echo "FAIL: Checksum file for /dev/nvme0n1p1 was not created!"
  exit 1
fi

if [ -f "$CHKSUM_TEST_DIR/nvme0n1p2.files-b3sum.info.gz" ] || [ -f "$CHKSUM_TEST_DIR/nvme0n1p4.files-b3sum.info.gz" ]; then
  echo "FAIL: Checksum file was unexpectedly created for ZFS partition!"
  exit 1
fi
echo "PASS: dev-fs.list processing loop correctly processed vfat and skipped ZFS partitions"

# -----------------------------------------------------------------------------
# TEST 13: zfs_member normalization in checksum functions
# -----------------------------------------------------------------------------
echo "--- Test 13: Testing zfs_member normalization in checksum functions ---"
rc_member_gen=0
gen_chksum_for_files_in_dev /dev/sdd1 "$CHKSUM_TEST_DIR" || rc_member_gen=$?
if [ "$rc_member_gen" -ne 0 ]; then
  echo "FAIL: gen_chksum_for_files_in_dev returned non-zero ($rc_member_gen) for zfs_member!"
  exit 1
fi

rc_member_inspect=0
inspect_chksum_for_files_in_dev /dev/sdd1 "$CHKSUM_TEST_DIR" || rc_member_inspect=$?
if [ "$rc_member_inspect" -ne 0 ]; then
  echo "FAIL: inspect_chksum_for_files_in_dev returned non-zero ($rc_member_inspect) for zfs_member!"
  exit 1
fi
echo "PASS: zfs_member normalized to zfs and skipped cleanly in gen and inspect checksum functions"

# -----------------------------------------------------------------------------
# TEST 14: Full ZFS checksum generation when ZFS tools and kernel are supported
# -----------------------------------------------------------------------------
echo "--- Test 14: Testing full ZFS checksum generation with mock zpool & zfs ---"
cat << 'EOF' > "$MOCK_BIN/zpool"
#!/bin/bash
echo "zpool $*" >> "$ACTION_LOG"
cmd="$1"
shift
case "$cmd" in
  status)
    exit 0
    ;;
  import)
    altroot=""
    while [ $# -gt 0 ]; do
      case "$1" in
        -R)
          altroot="$2"
          shift 2
          ;;
        *)
          shift
          ;;
      esac
    done
    if [ -n "$altroot" ]; then
      mkdir -p "$altroot/etc" "$altroot/home/user"
      echo "zfs system config" > "$altroot/etc/zfs_test.conf"
      echo "zfs user data" > "$altroot/home/user/document.txt"
      echo "$altroot" > "$TMP_DIR/zfs_altroot"
    fi
    exit 0
    ;;
  export)
    if [ -f "$TMP_DIR/zfs_altroot" ]; then
      altroot="$(cat "$TMP_DIR/zfs_altroot")"
      if [ -d "$altroot" ]; then
        rm -rf "$altroot"/* "$altroot"/.[!.]* "$altroot"/..?* 2>/dev/null || true
      fi
      rm -f "$TMP_DIR/zfs_altroot"
    fi
    exit 0
    ;;
  *)
    exit 0
    ;;
esac
EOF
chmod +x "$MOCK_BIN/zpool"

cat << 'EOF' > "$MOCK_BIN/zfs"
#!/bin/bash
echo "zfs $*" >> "$ACTION_LOG"
exit 0
EOF
chmod +x "$MOCK_BIN/zfs"

# Mock blkid for nvme0n1p2 and nvme0n1p4
cat << 'EOF' > "$MOCK_BIN/blkid"
#!/bin/bash
for arg in "$@"; do
  if [[ "$arg" == *"/dev/nvme0n1p2"* ]]; then
    if [[ "$*" == *"-s UUID"* ]]; then
      echo "11669959192160078484"
    elif [[ "$*" == *"-s LABEL"* ]]; then
      echo "bpool"
    elif [[ "$*" == *"-s TYPE"* ]]; then
      echo "zfs_member"
    else
      echo '/dev/nvme0n1p2: LABEL="bpool" UUID="11669959192160078484" TYPE="zfs_member"'
    fi
    exit 0
  elif [[ "$arg" == *"/dev/nvme0n1p4"* ]]; then
    if [[ "$*" == *"-s UUID"* ]]; then
      echo "17969138287380862017"
    elif [[ "$*" == *"-s LABEL"* ]]; then
      echo "rpool"
    elif [[ "$*" == *"-s TYPE"* ]]; then
      echo "zfs_member"
    else
      echo '/dev/nvme0n1p4: LABEL="rpool" UUID="17969138287380862017" TYPE="zfs_member"'
    fi
    exit 0
  fi
done
exit 1
EOF
chmod +x "$MOCK_BIN/blkid"

ZFS_TGT_IMG="$TMP_DIR/img_zfs_full"
mkdir -p "$ZFS_TGT_IMG"

chksum_cmd_for_files_in_dev="b3sum"
rc_zfs_gen=0
gen_chksum_for_files_in_dev /dev/nvme0n1p2 "$ZFS_TGT_IMG" || rc_zfs_gen=$?
if [ "$rc_zfs_gen" -ne 0 ]; then
  echo "FAIL: gen_chksum_for_files_in_dev failed for ZFS with exit code $rc_zfs_gen!"
  exit 1
fi

EXPECTED_ZFS_CHKSUM="$ZFS_TGT_IMG/nvme0n1p2.files-b3sum.info.gz"
if [ ! -f "$EXPECTED_ZFS_CHKSUM" ]; then
  echo "FAIL: Expected ZFS checksum file $EXPECTED_ZFS_CHKSUM was not created!"
  exit 1
fi

ZFS_FILE_COUNT="$(LC_ALL=C zcat "$EXPECTED_ZFS_CHKSUM" | wc -l)"
if [ "$ZFS_FILE_COUNT" -ne 2 ]; then
  echo "FAIL: Expected 2 files in ZFS checksum file, got $ZFS_FILE_COUNT!"
  zcat "$EXPECTED_ZFS_CHKSUM"
  exit 1
fi

if ! grep -q "zpool import -f -o readonly=on -R" "$ACTION_LOG"; then
  echo "FAIL: zpool import was not called with readonly=on and -R!"
  cat "$ACTION_LOG"
  exit 1
fi

if ! grep -q "zpool export -f" "$ACTION_LOG"; then
  echo "FAIL: zpool export was not called to clean up pool!"
  cat "$ACTION_LOG"
  exit 1
fi
echo "PASS: Full ZFS checksum generation succeeded with 2 files indexed and clean pool export"

# -----------------------------------------------------------------------------
# TEST 15: Full ZFS checksum inspection when ZFS tools and kernel are supported
# -----------------------------------------------------------------------------
echo "--- Test 15: Testing full ZFS checksum inspection with mock zpool & zfs ---"
rc_zfs_inspect=0
inspect_chksum_for_files_in_dev /dev/nvme0n1p2 "$ZFS_TGT_IMG" || rc_zfs_inspect=$?
if [ "$rc_zfs_inspect" -ne 0 ]; then
  echo "FAIL: inspect_chksum_for_files_in_dev failed for ZFS with exit code $rc_zfs_inspect!"
  exit 1
fi
echo "PASS: Full ZFS checksum inspection verified all files and exported pool cleanly"

# -----------------------------------------------------------------------------
# TEST 16: dev-fs.list loop executes full ZFS checksum generation when supported
# -----------------------------------------------------------------------------
echo "--- Test 16: Testing dev-fs.list loop processes ZFS when tools are supported ---"
> "$OCS_LOGFILE"
while read dev_ x_fs y; do
  [ "$dev_" = "#" ] && continue
  [ "$x_fs" = "swap" -o "$x_fs" = "MS_Reserved_Partition" ] && continue
  if [ "$x_fs" = "zfs" -o "$x_fs" = "zfs_member" ]; then
    if ! is_zfs_kernel_supported; then
      [ "$BOOTUP" = "color" ] && $SETCOLOR_WARNING
      echo "ZFS file-level checksum generation requires zfs tools and kernel module, hence skip creating checksum file for partition $dev_." | tee --append ${OCS_LOGFILE}
      [ "$BOOTUP" = "color" ] && $SETCOLOR_NORMAL
      continue
    fi
  fi
  gen_chksum_for_files_in_dev "$dev_" "$ZFS_TGT_IMG"
done < "$DEV_FS_LIST"

if [ ! -f "$ZFS_TGT_IMG/nvme0n1p2.files-b3sum.info.gz" ]; then
  echo "FAIL: dev-fs.list loop did not create checksum file for /dev/nvme0n1p2!"
  exit 1
fi

if [ ! -f "$ZFS_TGT_IMG/nvme0n1p4.files-b3sum.info.gz" ]; then
  echo "FAIL: dev-fs.list loop did not create checksum file for /dev/nvme0n1p4!"
  exit 1
fi
echo "PASS: dev-fs.list processing loop successfully generated checksums for all ZFS partitions"

# -----------------------------------------------------------------------------
# TEST 17: Safe mount detection and directory stubs cleanup
# -----------------------------------------------------------------------------
echo "--- Test 17: Testing safe mount detection and directory stubs cleanup ---"
STUB_MNT="$TMP_DIR/stub_mnt_test"
mkdir -p "$STUB_MNT/boot" "$STUB_MNT/ROOT/ubuntu"
echo "ocs_stub_pool" > "/tmp/.ocs_zfs_imported_sdd1"

# 17a: umount_zfs_partition cleans up empty directory stubs when unmounted
umount_zfs_partition /dev/sdd1 "$STUB_MNT"
if [ -d "$STUB_MNT/boot" ] || [ -d "$STUB_MNT/ROOT" ]; then
  echo "FAIL: umount_zfs_partition did not clean up empty dataset directory stubs!"
  exit 1
fi
rmdir "$STUB_MNT"
if [ -d "$STUB_MNT" ]; then
  echo "FAIL: STUB_MNT could not be removed after umount_zfs_partition!"
  exit 1
fi

# 17b: clean_temp_mount_dir refuses cleanup when a mount is detected
MNT_CHECK_DIR="$TMP_DIR/mnt_check_test"
mkdir -p "$MNT_CHECK_DIR/submount"
touch "$MNT_CHECK_DIR/submount/important_user_file.txt"

# Mock mountpoint returning 0 (mounted)
cat << 'EOF' > "$MOCK_BIN/mountpoint"
#!/bin/bash
exit 0
EOF
chmod +x "$MOCK_BIN/mountpoint"
hash -r

> "$OCS_LOGFILE"
rc_clean=0
clean_temp_mount_dir "$MNT_CHECK_DIR" || rc_clean=$?
if [ "$rc_clean" -eq 0 ]; then
  echo "FAIL: clean_temp_mount_dir succeeded when directory was reported as mounted!"
  exit 1
fi

if [ ! -f "$MNT_CHECK_DIR/submount/important_user_file.txt" ]; then
  echo "FAIL: clean_temp_mount_dir deleted content from mounted directory!"
  exit 1
fi

if ! grep -q "still mounted. Skipping removal to prevent data loss" "$OCS_LOGFILE"; then
  echo "FAIL: Did not log warning when mountpoint was detected!"
  cat "$OCS_LOGFILE"
  exit 1
fi

# Restore real mountpoint check (returning 1 for unmounted directory)
rm -f "$MOCK_BIN/mountpoint"
hash -r

# 17c: When unmounted, clean_temp_mount_dir safely cleans up empty stubs without rm -rf
EMPTY_STUBS_DIR="$TMP_DIR/empty_stubs_dir"
mkdir -p "$EMPTY_STUBS_DIR/boot/efi" "$EMPTY_STUBS_DIR/home"
clean_temp_mount_dir "$EMPTY_STUBS_DIR"
if [ -d "$EMPTY_STUBS_DIR" ]; then
  echo "FAIL: clean_temp_mount_dir failed to remove unmounted directory with empty stubs!"
  exit 1
fi

echo "PASS: Mount safety check and empty dataset stub cleanup verified successfully"

# -----------------------------------------------------------------------------
# TEST 18: Informative notice on unreadable files and permanent ZFS pool errors
# -----------------------------------------------------------------------------
echo "--- Test 18: Testing notices on unreadable files and ZFS pool errors ---"
cat << 'EOF' > "$MOCK_BIN/zpool"
#!/bin/bash
echo "zpool $*" >> "$ACTION_LOG"
cmd="$1"
shift
case "$cmd" in
  status)
    echo "errors: Permanent errors have been detected in the following files:"
    echo "    /home/user/corrupt.sqlite"
    exit 0
    ;;
  import)
    altroot=""
    while [ $# -gt 0 ]; do
      case "$1" in
        -R)
          altroot="$2"
          shift 2
          ;;
        *)
          shift
          ;;
      esac
    done
    if [ -n "$altroot" ]; then
      mkdir -p "$altroot/home/user"
      echo "good file" > "$altroot/home/user/good.txt"
      echo "bad file" > "$altroot/home/user/corrupt.sqlite"
      echo "$altroot" > "$TMP_DIR/zfs_altroot"
    fi
    exit 0
    ;;
  export)
    if [ -f "$TMP_DIR/zfs_altroot" ]; then
      altroot="$(cat "$TMP_DIR/zfs_altroot")"
      if [ -d "$altroot" ]; then
        rm -rf "$altroot"/* "$altroot"/.[!.]* "$altroot"/..?* 2>/dev/null || true
      fi
      rm -f "$TMP_DIR/zfs_altroot"
    fi
    exit 0
    ;;
  *)
    exit 0
    ;;
esac
EOF
chmod +x "$MOCK_BIN/zpool"

# Create a mock checksum command that simulates EIO on corrupt.sqlite
cat << 'EOF' > "$MOCK_BIN/mock_chksum_with_err"
#!/bin/bash
for f in "$@"; do
  if [[ "$f" == *"corrupt.sqlite"* ]]; then
    echo "mock_chksum_with_err: $f: Input/output error (os error 5)" >&2
    exit 1
  fi
  echo "mockhash  $f"
done
exit 0
EOF
chmod +x "$MOCK_BIN/mock_chksum_with_err"

ZFS_ERR_IMG="$TMP_DIR/img_zfs_err"
mkdir -p "$ZFS_ERR_IMG"

chksum_cmd_for_files_in_dev="mock_chksum_with_err"
> "$OCS_LOGFILE"
gen_chksum_for_files_in_dev /dev/nvme0n1p2 "$ZFS_ERR_IMG" || true

if ! grep -q "Warning: Some files in /dev/nvme0n1p2 could not be read when generating checksums" "$OCS_LOGFILE"; then
  echo "FAIL: Did not log warning about unreadable files in /dev/nvme0n1p2!"
  cat "$OCS_LOGFILE"
  exit 1
fi

if ! grep -q "check pool status with: zpool status -v" "$OCS_LOGFILE"; then
  echo "FAIL: Did not log guidance to run 'zpool status -v'!"
  cat "$OCS_LOGFILE"
  exit 1
fi

if ! grep -q "Permanent data errors were detected in ZFS pool" "$OCS_LOGFILE"; then
  echo "FAIL: Did not detect and log permanent ZFS pool errors!"
  cat "$OCS_LOGFILE"
  exit 1
fi
echo "PASS: Correctly reported unreadable files warning and ZFS pool permanent errors notice"

echo "=== All ZFS Support Tests Passed Successfully! ==="
exit 0
