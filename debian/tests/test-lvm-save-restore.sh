#!/bin/bash
# Comprehensive test suite for LVM Save, Restore (Unicast), and Local Cloning (d2d).
#
# Covers:
# 1. save_logv: Multi-VG, Multi-LV, swap metadata, thin-pool container exclusion, image_save calls.
# 2. restore_logv (unicast): Multi-VG restoration, thin pool repair, swap formatting, data restore.
# 3. restore_logv (d2d): Shadow VG multi-VG cloning, Partclone execution, source protection, final vgrename.
# 4. Whole-disk PV cloning in d2d mode (clean_mbr_gpt_part_table, shadow VG, Partclone).
# 5. Error handling and FORCE_TO_USE_DD fallback.

echo "=== Running Comprehensive LVM Save, Restore & Cloning Tests ==="

TMP_DIR="$(mktemp -d /tmp/test-lvm-sr-XXXXXX)"
trap 'rm -rf "$TMP_DIR"' EXIT

MOCK_BIN="$TMP_DIR/bin"
mkdir -p "$MOCK_BIN"
export PATH="$MOCK_BIN:$PATH"

export ACTION_LOG="$TMP_DIR/action.log"
touch "$ACTION_LOG"

# Mock core LVM binaries
cat << 'EOF' > "$MOCK_BIN/ocs-lvm2-start"
#!/bin/bash
exit 0
EOF
chmod +x "$MOCK_BIN/ocs-lvm2-start"

cat << 'EOF' > "$MOCK_BIN/ocs-lvm2-stop"
#!/bin/bash
exit 0
EOF
chmod +x "$MOCK_BIN/ocs-lvm2-stop"

cat << 'EOF' > "$MOCK_BIN/pvcreate"
#!/bin/bash
echo "pvcreate $*" >> "$ACTION_LOG"
exit 0
EOF
chmod +x "$MOCK_BIN/pvcreate"

cat << 'EOF' > "$MOCK_BIN/vgcfgrestore"
#!/bin/bash
echo "vgcfgrestore $*" >> "$ACTION_LOG"
# Create mock block devices for target VG if they are shadow VGs or restored VGs
for arg in "$@"; do
  if [[ "$arg" =~ ^(vg_system|vg_data|vg_system_ocs_tgt|vg_data_ocs_tgt|vg_wholedisk_ocs_tgt)$ ]]; then
    mkdir -p "/dev/$arg"
    touch "/dev/$arg/root" "/dev/$arg/thin_vm" "/dev/$arg/pool0" "/dev/$arg/swap" "/dev/$arg/db" "/dev/$arg/data_lv" 2>/dev/null || true
  fi
done
exit 0
EOF
chmod +x "$MOCK_BIN/vgcfgrestore"

cat << 'EOF' > "$MOCK_BIN/vgcfgbackup"
#!/bin/bash
echo "vgcfgbackup $*" >> "$ACTION_LOG"
# Write a valid dummy LVM config to the file specified with -f
out_f=""
vg_name=""
while [ $# -gt 0 ]; do
  case "$1" in
    -f) out_f="$2"; shift 2 ;;
    *) vg_name="$1"; shift ;;
  esac
done
if [ -n "$out_f" -a -n "$vg_name" ]; then
  cat << CFG > "$out_f"
$vg_name {
	id = "orig-uuid-$vg_name"
	physical_volumes {
		pv0 {
			id = "pv-uuid-$vg_name"
			device = "/dev/sda2"
		}
	}
	logical_volumes {
		root {
			id = "lv-root-$vg_name"
		}
	}
}
CFG
fi
exit 0
EOF
chmod +x "$MOCK_BIN/vgcfgbackup"

cat << 'EOF' > "$MOCK_BIN/vgchange"
#!/bin/bash
echo "vgchange $*" >> "$ACTION_LOG"
exit 0
EOF
chmod +x "$MOCK_BIN/vgchange"

cat << 'EOF' > "$MOCK_BIN/vgrename"
#!/bin/bash
echo "vgrename $*" >> "$ACTION_LOG"
exit 0
EOF
chmod +x "$MOCK_BIN/vgrename"

cat << 'EOF' > "$MOCK_BIN/lvremove"
#!/bin/bash
echo "lvremove $*" >> "$ACTION_LOG"
exit 0
EOF
chmod +x "$MOCK_BIN/lvremove"

cat << 'EOF' > "$MOCK_BIN/lvcreate"
#!/bin/bash
echo "lvcreate $*" >> "$ACTION_LOG"
exit 0
EOF
chmod +x "$MOCK_BIN/lvcreate"

cat << 'EOF' > "$MOCK_BIN/mkswap"
#!/bin/bash
echo "mkswap $*" >> "$ACTION_LOG"
exit 0
EOF
chmod +x "$MOCK_BIN/mkswap"

cat << 'EOF' > "$MOCK_BIN/partclone.ext4"
#!/bin/bash
echo "partclone.ext4 $*" >> "$ACTION_LOG"
exit 0
EOF
chmod +x "$MOCK_BIN/partclone.ext4"

cat << 'EOF' > "$MOCK_BIN/partclone.xfs"
#!/bin/bash
echo "partclone.xfs $*" >> "$ACTION_LOG"
exit 0
EOF
chmod +x "$MOCK_BIN/partclone.xfs"

cat << 'EOF' > "$MOCK_BIN/partclone.btrfs"
#!/bin/bash
echo "partclone.btrfs $*" >> "$ACTION_LOG"
exit 0
EOF
chmod +x "$MOCK_BIN/partclone.btrfs"

cat << 'EOF' > "$MOCK_BIN/partclone.dd"
#!/bin/bash
echo "partclone.dd $*" >> "$ACTION_LOG"
exit 0
EOF
chmod +x "$MOCK_BIN/partclone.dd"

# Mock pvscan for save_logv
cat << 'EOF' > "$MOCK_BIN/pvscan"
#!/bin/bash
echo "  PV /dev/sda2   VG vg_system   lvm2 [20.00 GiB / 5.00 GiB free]"
echo "  PV /dev/sda3   VG vg_data     lvm2 [50.00 GiB / 10.00 GiB free]"
exit 0
EOF
chmod +x "$MOCK_BIN/pvscan"

# Mock pvdisplay for save_logv
cat << 'EOF' > "$MOCK_BIN/pvdisplay"
#!/bin/bash
dev="$1"
if [ "$dev" = "/dev/sda2" ]; then
  echo "  PV Name               /dev/sda2"
  echo "  VG Name               vg_system"
  echo "  PV UUID               pv-uuid-system-1234"
elif [ "$dev" = "/dev/sda3" ]; then
  echo "  PV Name               /dev/sda3"
  echo "  VG Name               vg_data"
  echo "  PV UUID               pv-uuid-data-5678"
fi
exit 0
EOF
chmod +x "$MOCK_BIN/pvdisplay"

# Mock lvscan for save_logv
cat << 'EOF' > "$MOCK_BIN/lvscan"
#!/bin/bash
echo "  ACTIVE            '/dev/vg_system/root' [10.00 GiB] inherit"
echo "  ACTIVE            '/dev/vg_system/swap' [2.00 GiB] inherit"
echo "  ACTIVE            '/dev/vg_system/pool0' [5.00 GiB] inherit"
echo "  ACTIVE            '/dev/vg_system/thin_vm' [3.00 GiB] inherit"
echo "  ACTIVE            '/dev/vg_data/db' [40.00 GiB] inherit"
exit 0
EOF
chmod +x "$MOCK_BIN/lvscan"

# Mock lvs for queries
cat << 'EOF' > "$MOCK_BIN/lvs"
#!/bin/bash
cmd="$*"
if [[ "$cmd" == *"segtype"* ]]; then
  if [[ "$cmd" == *"/pool0"* || "$cmd" == *"vg_system/pool0"* || "$cmd" == *"vg_system_ocs_tgt/pool0"* ]]; then
    echo "  thin-pool"
  elif [[ "$cmd" == *"/thin_vm"* || "$cmd" == *"vg_system/thin_vm"* || "$cmd" == *"vg_system_ocs_tgt/thin_vm"* ]]; then
    echo "  thin"
  elif [[ "$cmd" == *"-o lv_name,segtype vg_system"* || "$cmd" == *"-o lv_name,segtype vg_system_ocs_tgt"* ]]; then
    echo "  pool0 thin-pool"
    echo "  root linear"
    echo "  swap linear"
    echo "  thin_vm thin"
  elif [[ "$cmd" == *"-o lv_name,segtype vg_data"* || "$cmd" == *"-o lv_name,segtype vg_data_ocs_tgt"* ]]; then
    echo "  db linear"
  else
    echo "  linear"
  fi
elif [[ "$cmd" == *"pool_lv,lv_size"* ]]; then
  echo "  thin_vm pool0 3221225472B"
elif [[ "$cmd" == *"lv_size"* && "$cmd" == *"pool0_tdata"* ]]; then
  echo "  5368709120B"
elif [[ "$cmd" == *"lv_size"* && "$cmd" == *"pool0_tmeta"* ]]; then
  echo "  536870912B"
elif [[ "$cmd" == *"chunk_size"* && "$cmd" == *"pool0"* ]]; then
  echo "  65536B"
else
  echo "  linear"
fi
exit 0
EOF
chmod +x "$MOCK_BIN/lvs"

# Mock vgs
cat << 'EOF' > "$MOCK_BIN/vgs"
#!/bin/bash
# In d2d mode, shadow VGs do not exist initially until vgcfgrestore is run
if [[ "$*" == *"ocs_tgt"* ]]; then
  vg_query="$1"
  if grep -q "vgcfgrestore.*$vg_query" "$ACTION_LOG" 2>/dev/null; then
    exit 0
  else
    exit 1
  fi
fi
# In unicast mode, if testing fresh restore, VGs do not exist initially
if [ "$VGS_EXIST_MODE" = "no" ]; then
  exit 1
fi
# Default: source VGs exist
exit 0
EOF
chmod +x "$MOCK_BIN/vgs"

# Mock file command for filesystem identification in save_logv
file() {
  local dev="$2"
  case "$dev" in
    */root) echo "$dev: Linux rev 1.0 ext4 filesystem data (ext4)" ;;
    */swap) echo "$dev: Linux/i386 swap file (swap)" ;;
    */thin_vm) echo "$dev: SGI XFS filesystem data (xfs)" ;;
    */db) echo "$dev: BTRFS Filesystem (btrfs)" ;;
    *) echo "$dev: data" ;;
  esac
}
export -f file

# Export test environment variables
export target_dir_fullpath="$TMP_DIR/img"
mkdir -p "$target_dir_fullpath"
export OCS_LOGFILE="$TMP_DIR/ocs.log"
export source_hd="sda"
export target_hd="sdb"
export USE_PARTCLONE_IN_OCS_ONTHEFLY="yes"
export partclone_support_fs="ext4 ext3 ext2 xfs btrfs ntfs fat32 vfat dd"

. scripts/sbin/ocs-functions

# Mock helper functions
clean_filesystem_header_in_dev() {
  echo "clean_filesystem_header_in_dev $*" >> "$ACTION_LOG"
  return 0
}
export -f clean_filesystem_header_in_dev

clean_mbr_gpt_part_table() {
  echo "clean_mbr_gpt_part_table $*" >> "$ACTION_LOG"
  return 0
}
export -f clean_mbr_gpt_part_table

image_save() {
  echo "image_save $*" >> "$ACTION_LOG"
  local lv="$1"
  local fn="$3"
  touch "$target_dir_fullpath/${fn}.ext4-ptcl-img.gz" 2>/dev/null || true
  return 0
}
export -f image_save

output_swap_partition_uuid_label() {
  echo "output_swap_partition_uuid_label $*" >> "$ACTION_LOG"
  local lv="$1"
  local out_file="$2"
  cat << SWP > "$out_file"
UUID="swap-uuid-fixed"
LABEL="SWAP_LABEL"
SWP
  return 0
}
export -f output_swap_partition_uuid_label

do_unicast_stdin_restore() {
  echo "do_unicast_stdin_restore $*" >> "$ACTION_LOG"
  return 0
}
export -f do_unicast_stdin_restore

# Create dummy source devices in /dev
mkdir -p /dev/vg_system /dev/vg_data
touch /dev/vg_system/root /dev/vg_system/swap /dev/vg_system/pool0 /dev/vg_system/thin_vm
touch /dev/vg_data/db

# ==============================================================================
# TEST 1: save_logv - Saving Multi-VG, Multi-LV, Thin Pool, and Swap
# ==============================================================================
echo "--- Test 1: save_logv with multiple VGs, LVs, thin pool and swap ---"
> "$ACTION_LOG"

save_logv "sda2 sda3"

# 1. Verify PV parse config generated
if [ ! -f "$target_dir_fullpath/lvm_vg_dev.list" ]; then
  echo "FAIL: lvm_vg_dev.list was not created!"
  exit 1
fi

if ! grep -q "vg_system /dev/sda2 pv-uuid-system-1234" "$target_dir_fullpath/lvm_vg_dev.list"; then
  echo "FAIL: vg_system entry missing from lvm_vg_dev.list!"
  cat "$target_dir_fullpath/lvm_vg_dev.list"
  exit 1
fi

if ! grep -q "vg_data /dev/sda3 pv-uuid-data-5678" "$target_dir_fullpath/lvm_vg_dev.list"; then
  echo "FAIL: vg_data entry missing from lvm_vg_dev.list!"
  cat "$target_dir_fullpath/lvm_vg_dev.list"
  exit 1
fi

# 2. Verify LV parse config generated
if [ ! -f "$target_dir_fullpath/lvm_logv.list" ]; then
  echo "FAIL: lvm_logv.list was not created!"
  exit 1
fi

if ! grep -q "/dev/vg_system/root" "$target_dir_fullpath/lvm_logv.list"; then
  echo "FAIL: root LV missing from lvm_logv.list!"
  exit 1
fi

if ! grep -q "/dev/vg_system/thin_vm" "$target_dir_fullpath/lvm_logv.list"; then
  echo "FAIL: thin_vm LV missing from lvm_logv.list!"
  exit 1
fi

if ! grep -q "/dev/vg_data/db" "$target_dir_fullpath/lvm_logv.list"; then
  echo "FAIL: db LV missing from lvm_logv.list!"
  exit 1
fi

# Thin pool container should be excluded from lvm_logv.list
if grep -q "pool0" "$target_dir_fullpath/lvm_logv.list"; then
  echo "FAIL: thin-pool container pool0 should NOT be in lvm_logv.list!"
  cat "$target_dir_fullpath/lvm_logv.list"
  exit 1
fi

# 3. Verify VG configs backed up
if [ ! -f "$target_dir_fullpath/lvm_vg_system.conf" ] || [ ! -f "$target_dir_fullpath/lvm_vg_data.conf" ]; then
  echo "FAIL: lvm_vg_system.conf or lvm_vg_data.conf missing!"
  exit 1
fi

# 4. Verify swap metadata saved
if [ ! -f "$target_dir_fullpath/swappt-vg_system-swap.info" ]; then
  echo "FAIL: Swap info file swappt-vg_system-swap.info was not created!"
  exit 1
fi

# 5. Verify image_save called for data LVs, but NOT for swap or thin pool container
if ! grep -q "image_save /dev/vg_system/root" "$ACTION_LOG"; then
  echo "FAIL: image_save was not called for root LV!"
  exit 1
fi

if ! grep -q "image_save /dev/vg_system/thin_vm" "$ACTION_LOG"; then
  echo "FAIL: image_save was not called for thin_vm LV!"
  exit 1
fi

if ! grep -q "image_save /dev/vg_data/db" "$ACTION_LOG"; then
  echo "FAIL: image_save was not called for db LV!"
  exit 1
fi

if grep -q "image_save /dev/vg_system/swap" "$ACTION_LOG"; then
  echo "FAIL: image_save was erroneously called for swap LV!"
  exit 1
fi

if grep -q "image_save /dev/vg_system/pool0" "$ACTION_LOG"; then
  echo "FAIL: image_save was erroneously called for thin pool container pool0!"
  exit 1
fi

echo "PASS: Test 1: save_logv successfully saved metadata, configs, swap info, and data LVs."

# ==============================================================================
# TEST 2: restore_logv - Unicast Image Restore with Multiple VGs
# ==============================================================================
echo "--- Test 2: restore_logv in unicast mode (restoring from saved image) ---"
> "$ACTION_LOG"
export VGS_EXIST_MODE="no"

# Prepare target partitions in lvm_vg_dev.list (as transformed by ocs-cvt-dev during restore)
cat << 'EOF' > "$target_dir_fullpath/lvm_vg_dev.list"
vg_system /dev/sdb2 pv-uuid-system-1234
vg_data /dev/sdb3 pv-uuid-data-5678
EOF

restore_logv "sdb2 sdb3" "unicast" ""

# 1. Verify PV creation with preserved UUID and restorefile
if ! grep -q "pvcreate.*--uuid pv-uuid-system-1234.*--restorefile.*/dev/sdb2" "$ACTION_LOG"; then
  echo "FAIL: pvcreate was not called with preserved UUID for /dev/sdb2!"
  cat "$ACTION_LOG"
  exit 1
fi

if ! grep -q "pvcreate.*--uuid pv-uuid-data-5678.*--restorefile.*/dev/sdb3" "$ACTION_LOG"; then
  echo "FAIL: pvcreate was not called with preserved UUID for /dev/sdb3!"
  cat "$ACTION_LOG"
  exit 1
fi

# 2. Verify vgcfgrestore called for both VGs
if ! grep -q "vgcfgrestore.*vg_system" "$ACTION_LOG" || ! grep -q "vgcfgrestore.*vg_data" "$ACTION_LOG"; then
  echo "FAIL: vgcfgrestore was not called for both restored VGs!"
  cat "$ACTION_LOG"
  exit 1
fi

# 3. Verify thin pool repair called on vg_system/pool0
if ! grep -q "lvcreate.*--type thin-pool.*vg_system/pool0" "$ACTION_LOG"; then
  echo "FAIL: thin pool repair was not executed for pool0 in unicast mode!"
  cat "$ACTION_LOG"
  exit 1
fi

# 4. Verify swap formatting with preserved UUID/label
if ! grep -q "mkswap -L SWAP_LABEL -U swap-uuid-fixed /dev/vg_system/swap" "$ACTION_LOG"; then
  echo "FAIL: mkswap was not called with preserved options for /dev/vg_system/swap!"
  cat "$ACTION_LOG"
  exit 1
fi

# 5. Verify do_unicast_stdin_restore called for all data LVs
if ! grep -q "do_unicast_stdin_restore.*vg_system-root /dev/vg_system/root" "$ACTION_LOG"; then
  echo "FAIL: do_unicast_stdin_restore was not called for root LV!"
  exit 1
fi

if ! grep -q "do_unicast_stdin_restore.*vg_data-db /dev/vg_data/db" "$ACTION_LOG"; then
  echo "FAIL: do_unicast_stdin_restore was not called for db LV!"
  exit 1
fi

echo "PASS: Test 2: restore_logv unicast mode restored PVs, VGs, thin pools, swap, and LV data."

# ==============================================================================
# TEST 3: restore_logv - Multi-VG Local Device-to-Device (d2d) Cloning
# ==============================================================================
echo "--- Test 3: restore_logv in d2d mode with multiple VGs and Partclone ---"
> "$ACTION_LOG"
export VGS_EXIST_MODE="yes"

restore_logv "sdb2 sdb3" "d2d" "ld2d"

# 1. Source disk protection: source VGs must NEVER be modified
if grep -E "lvremove.*(^|[[:space:]])(vg_system|vg_data)/" "$ACTION_LOG"; then
  echo "FAIL: lvremove was called on source VG in d2d mode!"
  cat "$ACTION_LOG"
  exit 1
fi

if grep -E "mkswap.*(^|[[:space:]])/dev/(vg_system|vg_data)/" "$ACTION_LOG"; then
  echo "FAIL: mkswap was called on source LV in d2d mode!"
  cat "$ACTION_LOG"
  exit 1
fi

# 2. Fresh PV UUIDs created on target partitions
if ! grep -q "pvcreate.*-ff --yes --uuid.*--zero y /dev/sdb2" "$ACTION_LOG"; then
  echo "FAIL: pvcreate was not called with fresh UUID on /dev/sdb2!"
  cat "$ACTION_LOG"
  exit 1
fi

if ! grep -q "pvcreate.*-ff --yes --uuid.*--zero y /dev/sdb3" "$ACTION_LOG"; then
  echo "FAIL: pvcreate was not called with fresh UUID on /dev/sdb3!"
  cat "$ACTION_LOG"
  exit 1
fi

# 3. Shadow VGs restored
if ! grep -q "vgcfgrestore.*vg_system_ocs_tgt" "$ACTION_LOG" || ! grep -q "vgcfgrestore.*vg_data_ocs_tgt" "$ACTION_LOG"; then
  echo "FAIL: Shadow VGs were not restored with vgcfgrestore!"
  cat "$ACTION_LOG"
  exit 1
fi

# 4. Thin pool safely repaired on shadow VG
if ! grep -q "lvcreate.*--type thin-pool.*vg_system_ocs_tgt/pool0" "$ACTION_LOG"; then
  echo "FAIL: Thin pool was not repaired on target shadow VG vg_system_ocs_tgt!"
  cat "$ACTION_LOG"
  exit 1
fi

# 5. Swap formatted on shadow target LV
if ! grep -q "mkswap -L SWAP_LABEL -U swap-uuid-fixed /dev/vg_system_ocs_tgt/swap" "$ACTION_LOG"; then
  echo "FAIL: mkswap was not called on target shadow LV /dev/vg_system_ocs_tgt/swap!"
  cat "$ACTION_LOG"
  exit 1
fi

# 6. Partclone executed for each data LV
if ! grep -q "partclone.ext4.*-b -s /dev/vg_system/root -O /dev/vg_system_ocs_tgt/root" "$ACTION_LOG"; then
  echo "FAIL: partclone.ext4 was not called for root LV!"
  cat "$ACTION_LOG"
  exit 1
fi

if ! grep -q "partclone.xfs.*-b -s /dev/vg_system/thin_vm -O /dev/vg_system_ocs_tgt/thin_vm" "$ACTION_LOG"; then
  echo "FAIL: partclone.xfs was not called for thin_vm LV!"
  cat "$ACTION_LOG"
  exit 1
fi

if ! grep -q "partclone.btrfs.*-b -s /dev/vg_data/db -O /dev/vg_data_ocs_tgt/db" "$ACTION_LOG"; then
  echo "FAIL: partclone.btrfs was not called for db LV!"
  cat "$ACTION_LOG"
  exit 1
fi

# 7. Finalization: both shadow VGs deactivated and renamed to original VG names with device filter
if ! grep -q "vgrename.*devices.*filter.*vg_system_ocs_tgt vg_system" "$ACTION_LOG"; then
  echo "FAIL: vgrename was not called with device filter for vg_system!"
  cat "$ACTION_LOG"
  exit 1
fi

if ! grep -q "vgrename.*devices.*filter.*vg_data_ocs_tgt vg_data" "$ACTION_LOG"; then
  echo "FAIL: vgrename was not called with device filter for vg_data!"
  cat "$ACTION_LOG"
  exit 1
fi

echo "PASS: Test 3: restore_logv d2d mode successfully cloned all LVs via Partclone and finalized shadow VGs."

# ==============================================================================
# TEST 4: Whole-disk PV cloning in d2d mode
# ==============================================================================
echo "--- Test 4: Whole-disk PV cloning in d2d mode ---"
> "$ACTION_LOG"

cat << 'EOF' > "$target_dir_fullpath/lvm_vg_dev.list"
vg_wholedisk /dev/sdb pv-uuid-wd-1111
EOF

cat << 'EOF' > "$target_dir_fullpath/lvm_logv.list"
/dev/vg_wholedisk/data_lv ext4
EOF

cat << 'EOF' > "$target_dir_fullpath/lvm_vg_wholedisk.conf"
vg_wholedisk {
	id = "orig-uuid-wholedisk"
	physical_volumes {
		pv0 {
			id = "pv-uuid-wd-1111"
			device = "/dev/sda"
		}
	}
	logical_volumes {
		data_lv {
			id = "lv-wd-data"
		}
	}
}
EOF

mkdir -p /dev/vg_wholedisk
touch /dev/vg_wholedisk/data_lv

restore_logv "sdb" "d2d" "ld2d"

# 1. Verify clean_mbr_gpt_part_table was called for whole disk
if ! grep -q "clean_mbr_gpt_part_table /dev/sdb" "$ACTION_LOG"; then
  echo "FAIL: clean_mbr_gpt_part_table was not called for whole-disk PV /dev/sdb!"
  cat "$ACTION_LOG"
  exit 1
fi

# 2. Verify shadow VG restoration and Partclone
if ! grep -q "vgcfgrestore.*vg_wholedisk_ocs_tgt" "$ACTION_LOG"; then
  echo "FAIL: vgcfgrestore was not called for vg_wholedisk_ocs_tgt!"
  cat "$ACTION_LOG"
  exit 1
fi

if ! grep -q "partclone.ext4.*-b -s /dev/vg_wholedisk/data_lv -O /dev/vg_wholedisk_ocs_tgt/data_lv" "$ACTION_LOG"; then
  echo "FAIL: partclone.ext4 was not called for whole-disk data_lv!"
  cat "$ACTION_LOG"
  exit 1
fi

# 3. Verify final rename
if ! grep -q "vgrename.*vg_wholedisk_ocs_tgt vg_wholedisk" "$ACTION_LOG"; then
  echo "FAIL: vgrename was not called for vg_wholedisk!"
  cat "$ACTION_LOG"
  exit 1
fi

echo "PASS: Test 4: Whole-disk PV cloning successfully executed."

# ==============================================================================
# TEST 5: Error Handling and FORCE_TO_USE_DD fallback
# ==============================================================================
echo "--- Test 5: Error handling and FORCE_TO_USE_DD fallback ---"
> "$ACTION_LOG"

# 5.1 Test FORCE_TO_USE_DD on clone_lv_to_lv
export FORCE_TO_USE_DD="yes"
clone_lv_to_lv "ext4" "/dev/vg_wholedisk/data_lv" "/dev/vg_wholedisk_ocs_tgt/data_lv"

if ! grep -q "partclone.dd.*-s /dev/vg_wholedisk/data_lv -O /dev/vg_wholedisk_ocs_tgt/data_lv" "$ACTION_LOG"; then
  echo "FAIL: FORCE_TO_USE_DD did not trigger partclone.dd on LV!"
  cat "$ACTION_LOG"
  exit 1
fi
export FORCE_TO_USE_DD="no"

# 5.2 Test missing PV config in restore_logv
rm -f "$target_dir_fullpath/lvm_vg_dev.list"
set +e
restore_logv "sdb" "d2d" "ld2d"
rc=$?
set -e
if [ $rc -eq 0 ]; then
  echo "FAIL: restore_logv should have failed with missing lvm_vg_dev.list!"
  exit 1
fi

echo "PASS: Test 5: Fallback to partclone.dd and error handling verified."
echo "=== All Comprehensive LVM Save, Restore & Cloning Tests Passed Successfully! ==="
