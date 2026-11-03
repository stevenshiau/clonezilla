#!/bin/bash
# Standalone unit test for Shadow VG LVM Cloning with Partclone in d2d mode.
# Verifies:
# 1. Multi-PV shadow VG config creation (gen_lvm_uuid, create_shadow_vg_conf)
# 2. Partclone execution per LV (used block cloning, avoiding PV dd)
# 3. Swap LV initialization with original UUID/LABEL
# 4. Unknown filesystem fallback to partclone.dd on LV (not whole PV)
# 5. Proper deactivation and vgrename using device filter

set -e

echo "=== Running Shadow VG LVM d2d Cloning Tests ==="

TMP_DIR="$(mktemp -d /tmp/test-lvm-shadow-XXXXXX)"
trap 'rm -rf "$TMP_DIR"' EXIT

MOCK_BIN="$TMP_DIR/bin"
mkdir -p "$MOCK_BIN"
export PATH="$MOCK_BIN:$PATH"

export ACTION_LOG="$TMP_DIR/action.log"
touch "$ACTION_LOG"

cat << 'EOF' > "$MOCK_BIN/pvcreate"
#!/bin/bash
echo "pvcreate $*" >> "$ACTION_LOG"
exit 0
EOF
chmod +x "$MOCK_BIN/pvcreate"

cat << 'EOF' > "$MOCK_BIN/vgcfgrestore"
#!/bin/bash
echo "vgcfgrestore $*" >> "$ACTION_LOG"
exit 0
EOF
chmod +x "$MOCK_BIN/vgcfgrestore"

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

cat << 'EOF' > "$MOCK_BIN/partclone.dd"
#!/bin/bash
echo "partclone.dd $*" >> "$ACTION_LOG"
exit 0
EOF
chmod +x "$MOCK_BIN/partclone.dd"

cat << 'EOF' > "$MOCK_BIN/ocs-lvm2-stop"
#!/bin/bash
exit 0
EOF
chmod +x "$MOCK_BIN/ocs-lvm2-stop"

cat << 'EOF' > "$MOCK_BIN/ocs-lvm2-start"
#!/bin/bash
exit 0
EOF
chmod +x "$MOCK_BIN/ocs-lvm2-start"

cat << 'EOF' > "$MOCK_BIN/vgs"
#!/bin/bash
# Report that shadow VGs do not exist yet before vgcfgrestore
if [[ "$*" == *"ocs_tgt"* ]]; then
  if grep -q "vgcfgrestore.*$1" "$ACTION_LOG" 2>/dev/null; then
    exit 0
  else
    exit 1
  fi
fi
# Source VGs exist
exit 0
EOF
chmod +x "$MOCK_BIN/vgs"

cat << 'EOF' > "$MOCK_BIN/lvs"
#!/bin/bash
# None of these LVs are thin pools
exit 0
EOF
chmod +x "$MOCK_BIN/lvs"

# Setup environment
export target_dir_fullpath="$TMP_DIR/img"
mkdir -p "$target_dir_fullpath"
export OCS_LOGFILE="$TMP_DIR/ocs.log"
export source_hd="sda"
export target_hd="sdb"
export USE_PARTCLONE_IN_OCS_ONTHEFLY="yes"
export partclone_support_fs="ext4 ext3 ext2 xfs btrfs ntfs fat32 vfat dd"

. scripts/sbin/ocs-functions

clean_filesystem_header_in_dev() {
  echo "clean_filesystem_header_in_dev $*" >> "$ACTION_LOG"
  return 0
}
export -f clean_filesystem_header_in_dev

# Test A: Unit test create_shadow_vg_conf with multi-PV setup
echo "--- Test A: create_shadow_vg_conf with multi-PV setup ---"
cat << 'EOF' > "$target_dir_fullpath/lvm_multi.conf"
myvg {
	id = "ORIG-VG-UUID-1111-2222-3333-4444"
	seqno = 2
	format = "lvm2"
	status = ["RESIZEABLE", "READ", "WRITE"]
	flags = []
	extent_size = 8192
	max_lv = 0
	max_pv = 0
	metadata_copies = 0

	physical_volumes {
		pv0 {
			id = "PV0-ORIG-UUID"
			device = "/dev/sda2"
		}
		pv1 {
			id = "PV1-ORIG-UUID"
			device = "/dev/sda3"
		}
	}

	logical_volumes {
		root {
			id = "LV0-UUID"
		}
	}
}
EOF

cat << 'EOF' > "$TMP_DIR/pv_map.txt"
myvg /dev/sdb2 PV0-ORIG-UUID PV0-NEW-UUID-9999
myvg /dev/sdb3 PV1-ORIG-UUID PV1-NEW-UUID-8888
EOF

create_shadow_vg_conf "$target_dir_fullpath/lvm_multi.conf" "$TMP_DIR/lvm_myvg_ocs_tgt.conf" "myvg" "myvg_ocs_tgt" "" "$TMP_DIR/pv_map.txt"

if ! grep -q "^myvg_ocs_tgt {" "$TMP_DIR/lvm_myvg_ocs_tgt.conf"; then
  echo "FAIL: VG name was not changed to myvg_ocs_tgt!"
  cat "$TMP_DIR/lvm_myvg_ocs_tgt.conf"
  exit 1
fi

if grep -q "ORIG-VG-UUID-1111-2222-3333-4444" "$TMP_DIR/lvm_myvg_ocs_tgt.conf"; then
  echo "FAIL: Original VG UUID was not replaced with fresh UUID!"
  cat "$TMP_DIR/lvm_myvg_ocs_tgt.conf"
  exit 1
fi

if ! grep -q "PV0-NEW-UUID-9999" "$TMP_DIR/lvm_myvg_ocs_tgt.conf"; then
  echo "FAIL: PV0 new UUID not found!"
  cat "$TMP_DIR/lvm_myvg_ocs_tgt.conf"
  exit 1
fi

if ! grep -q "device = \"/dev/sdb2\"" "$TMP_DIR/lvm_myvg_ocs_tgt.conf"; then
  echo "FAIL: PV0 device was not updated to /dev/sdb2!"
  cat "$TMP_DIR/lvm_myvg_ocs_tgt.conf"
  exit 1
fi

if ! grep -q "PV1-NEW-UUID-8888" "$TMP_DIR/lvm_myvg_ocs_tgt.conf"; then
  echo "FAIL: PV1 new UUID not found!"
  cat "$TMP_DIR/lvm_myvg_ocs_tgt.conf"
  exit 1
fi

if ! grep -q "device = \"/dev/sdb3\"" "$TMP_DIR/lvm_myvg_ocs_tgt.conf"; then
  echo "FAIL: PV1 device was not updated to /dev/sdb3!"
  cat "$TMP_DIR/lvm_myvg_ocs_tgt.conf"
  exit 1
fi
echo "PASS: Test A: Multi-PV shadow VG config successfully transformed."

# Test B: Full restore_logv d2d cloning with ext4, xfs, swap, and unknown fs
echo "--- Test B: restore_logv d2d cloning across multiple filesystems ---"
> "$ACTION_LOG"

cat << 'EOF' > "$target_dir_fullpath/lvm_vg_dev.list"
data_vg /dev/sdb2 orig-pv-uuid-1
EOF

cat << 'EOF' > "$target_dir_fullpath/lvm_logv.list"
/dev/data_vg/root ext4
/dev/data_vg/home xfs
/dev/data_vg/myswap swap
/dev/data_vg/custom rawfs
EOF

cat << 'EOF' > "$target_dir_fullpath/lvm_data_vg.conf"
data_vg {
	id = "data-vg-uuid-orig"
	physical_volumes {
		pv0 {
			id = "orig-pv-uuid-1"
			device = "/dev/sda2"
		}
	}
}
EOF

mkdir -p /dev/data_vg
touch /dev/data_vg/root /dev/data_vg/home /dev/data_vg/myswap /dev/data_vg/custom

# Mock swap info file
cat << 'EOF' > "$target_dir_fullpath/swappt-data_vg-myswap.info"
UUID="swap-uuid-9999"
LABEL="SWAPSPACE"
EOF

restore_logv "sdb2" "d2d" "ld2d"

# Verify PV creation on target
if ! grep -q "pvcreate.*-ff --yes --uuid.*--zero y /dev/sdb2" "$ACTION_LOG"; then
  echo "FAIL: pvcreate was not run with fresh UUID on /dev/sdb2!"
  cat "$ACTION_LOG"
  exit 1
fi

# Verify shadow VG restoration
if ! grep -q "vgcfgrestore.*data_vg_ocs_tgt" "$ACTION_LOG"; then
  echo "FAIL: vgcfgrestore was not run for shadow VG data_vg_ocs_tgt!"
  cat "$ACTION_LOG"
  exit 1
fi

# Verify ext4 LV cloned via partclone.ext4
if ! grep -q "partclone.ext4.*-b -s /dev/data_vg/root -O /dev/data_vg_ocs_tgt/root" "$ACTION_LOG"; then
  echo "FAIL: root LV was not cloned via partclone.ext4!"
  cat "$ACTION_LOG"
  exit 1
fi

# Verify xfs LV cloned via partclone.xfs
if ! grep -q "partclone.xfs.*-b -s /dev/data_vg/home -O /dev/data_vg_ocs_tgt/home" "$ACTION_LOG"; then
  echo "FAIL: home LV was not cloned via partclone.xfs!"
  cat "$ACTION_LOG"
  exit 1
fi

# Verify swap LV formatted via mkswap on shadow target LV with original label & uuid
if ! grep -q "mkswap -L SWAPSPACE -U swap-uuid-9999 /dev/data_vg_ocs_tgt/myswap" "$ACTION_LOG"; then
  echo "FAIL: mkswap was not run on target shadow swap LV with original label and UUID!"
  cat "$ACTION_LOG"
  exit 1
fi

# Verify unsupported rawfs fell back to partclone.dd on the specific LV (not the PV partition!)
if ! grep -q "partclone.dd.*-s /dev/data_vg/custom -O /dev/data_vg_ocs_tgt/custom" "$ACTION_LOG"; then
  echo "FAIL: custom LV did not fall back to partclone.dd!"
  cat "$ACTION_LOG"
  exit 1
fi

# Verify finalization: deactivation and vgrename back to original name using target device filter
if ! grep -q "vgchange -an data_vg_ocs_tgt" "$ACTION_LOG"; then
  echo "FAIL: data_vg_ocs_tgt was not deactivated before renaming!"
  cat "$ACTION_LOG"
  exit 1
fi

if ! grep -q "vgrename.*devices.*filter.*data_vg_ocs_tgt data_vg" "$ACTION_LOG"; then
  echo "FAIL: vgrename was not run with device filter to finalize VG name!"
  cat "$ACTION_LOG"
  exit 1
fi

echo "PASS: Test B: All LVs cloned correctly via Partclone and finalized."
echo "=== All Shadow VG LVM d2d Cloning Tests Passed Successfully! ==="
