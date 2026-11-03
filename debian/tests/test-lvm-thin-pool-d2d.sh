#!/bin/bash
# Standalone unit test for Issue #198:
# Preventing thin pool wiping and source disk destruction during local device-to-device (d2d) cloning.

set -e

echo "=== Running LVM Thin Pool d2d Protection Tests ==="

TMP_DIR="$(mktemp -d /tmp/test-lvm-tp-XXXXXX)"
trap 'rm -rf "$TMP_DIR"' EXIT

MOCK_BIN="$TMP_DIR/bin"
mkdir -p "$MOCK_BIN"
export PATH="$MOCK_BIN:$PATH"

export ACTION_LOG="$TMP_DIR/action.log"
touch "$ACTION_LOG"

cat << 'EOF' > "$MOCK_BIN/lvs"
#!/bin/bash
if [[ "$*" == *"segtype pve"* ]]; then
  echo "  data thin-pool"
  echo "  root linear"
  echo "  vm-100-disk-0 thin"
elif [[ "$*" == *"pool_lv,lv_size pve"* ]]; then
  echo "  vm-100-disk-0 data 10737418240B"
elif [[ "$*" == *"lv_size pve"* && "$*" == *"data_tdata"* ]]; then
  echo "  53687091200B"
elif [[ "$*" == *"lv_size pve"* && "$*" == *"data_tmeta"* ]]; then
  echo "  536870912B"
elif [[ "$*" == *"chunk_size pve"* && "$*" == *"data"* ]]; then
  echo "  65536B"
elif [[ "$*" == *"segtype"* && "$*" == *"root"* ]]; then
  echo "  linear"
elif [[ "$*" == *"segtype"* && "$*" == *"vm-100-disk-0"* ]]; then
  echo "  thin"
elif [[ "$*" == *"segtype"* && "$*" == *"data"* ]]; then
  echo "  thin-pool"
elif [[ "$*" == *"segtype"* && "$*" == *"swap"* ]]; then
  echo "  linear"
fi
exit 0
EOF
chmod +x "$MOCK_BIN/lvs"

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

cat << 'EOF' > "$MOCK_BIN/pvcreate"
#!/bin/bash
echo "pvcreate $*" >> "$ACTION_LOG"
exit 0
EOF
chmod +x "$MOCK_BIN/pvcreate"

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

cat << 'EOF' > "$MOCK_BIN/vgrename"
#!/bin/bash
echo "vgrename $*" >> "$ACTION_LOG"
exit 0
EOF
chmod +x "$MOCK_BIN/vgrename"

cat << 'EOF' > "$MOCK_BIN/vgchange"
#!/bin/bash
echo "vgchange $*" >> "$ACTION_LOG"
exit 0
EOF
chmod +x "$MOCK_BIN/vgchange"

# Setup pseudo image files
export target_dir_fullpath="$TMP_DIR/img"
mkdir -p "$target_dir_fullpath"
echo "pve /dev/sdb3 fake-uuid" > "$target_dir_fullpath/lvm_vg_dev.list"
cat << 'EOF' > "$target_dir_fullpath/lvm_logv.list"
/dev/pve/root ext4
/dev/pve/vm-100-disk-0 ext4
/dev/pve/swap swap
EOF
cat << 'EOF' > "$target_dir_fullpath/lvm_pve.conf"
pve {
	id = "fake-vg-uuid-1111-2222-3333-4444"
	physical_volumes {
		pv0 {
			id = "fake-uuid"
			device = "/dev/sda3"
		}
	}
}
EOF

mkdir -p /dev/pve
touch /dev/pve/root /dev/pve/vm-100-disk-0 /dev/pve/data /dev/pve/swap

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

do_d2d_local_restore() {
  echo "do_d2d_local_restore $*" >> "$ACTION_LOG"
  return 0
}
export -f do_d2d_local_restore

do_unicast_stdin_restore() {
  echo "do_unicast_stdin_restore $*" >> "$ACTION_LOG"
  return 0
}
export -f do_unicast_stdin_restore

# Test 1: d2d mode with shadow VG and Partclone
echo "--- Test 1: restore_logv in d2d mode with shadow VG and Partclone ---"
> "$ACTION_LOG"

cat << 'EOF' > "$MOCK_BIN/vgs"
#!/bin/bash
if [[ "$*" == *"pve_ocs_tgt"* ]]; then
  if grep -q "vgcfgrestore.*pve_ocs_tgt" "$ACTION_LOG"; then
    exit 0
  else
    exit 1
  fi
fi
# pve source VG exists
exit 0
EOF
chmod +x "$MOCK_BIN/vgs"

cat << 'EOF' > "$MOCK_BIN/vgcfgrestore"
#!/bin/bash
echo "vgcfgrestore $*" >> "$ACTION_LOG"
mkdir -p /dev/pve_ocs_tgt
touch /dev/pve_ocs_tgt/root /dev/pve_ocs_tgt/vm-100-disk-0 /dev/pve_ocs_tgt/data /dev/pve_ocs_tgt/swap
exit 0
EOF
chmod +x "$MOCK_BIN/vgcfgrestore"

restore_logv "sdb3" "d2d" "ld2d"

# 1. Source disk must NEVER be modified (Issue #198 safety check)
if grep -E "lvremove.*(^|[[:space:]])pve/" "$ACTION_LOG"; then
  echo "FAIL: lvremove was called on source VG pve! Source thin pool was destroyed."
  cat "$ACTION_LOG"
  exit 1
fi

if grep -E "lvcreate.*(^|[[:space:]])pve/" "$ACTION_LOG"; then
  echo "FAIL: lvcreate was called on source VG pve! Source thin pool was modified."
  cat "$ACTION_LOG"
  exit 1
fi

if grep -E "mkswap.*(^|[[:space:]])/dev/pve/" "$ACTION_LOG"; then
  echo "FAIL: mkswap was called on source LV /dev/pve/swap in d2d mode!"
  cat "$ACTION_LOG"
  exit 1
fi

# 2. Target shadow VG must be created and thin pool repaired safely on target
if ! grep -q "vgcfgrestore.*pve_ocs_tgt" "$ACTION_LOG"; then
  echo "FAIL: vgcfgrestore was not called for shadow VG pve_ocs_tgt!"
  cat "$ACTION_LOG"
  exit 1
fi

if ! grep -q "lvremove.*pve_ocs_tgt/vm-100-disk-0" "$ACTION_LOG"; then
  echo "FAIL: lvremove was not called on shadow VG pve_ocs_tgt!"
  cat "$ACTION_LOG"
  exit 1
fi

if ! grep -q "lvcreate.*pve_ocs_tgt/data" "$ACTION_LOG"; then
  echo "FAIL: lvcreate thin-pool was not called on shadow VG pve_ocs_tgt!"
  cat "$ACTION_LOG"
  exit 1
fi

if ! grep -q "mkswap.*/dev/pve_ocs_tgt/swap" "$ACTION_LOG"; then
  echo "FAIL: mkswap was not called on target shadow LV /dev/pve_ocs_tgt/swap!"
  cat "$ACTION_LOG"
  exit 1
fi

# 3. LVs must be cloned with Partclone (not dd on the PV)
if ! grep -q "partclone.ext4.*-s /dev/pve/root -O /dev/pve_ocs_tgt/root" "$ACTION_LOG"; then
  echo "FAIL: partclone.ext4 was not called for root LV!"
  cat "$ACTION_LOG"
  exit 1
fi

if ! grep -q "partclone.ext4.*-s /dev/pve/vm-100-disk-0 -O /dev/pve_ocs_tgt/vm-100-disk-0" "$ACTION_LOG"; then
  echo "FAIL: partclone.ext4 was not called for thin LV vm-100-disk-0!"
  cat "$ACTION_LOG"
  exit 1
fi

# 4. Target shadow VG must be renamed back to original VG name with device filter
if ! grep -q "vgrename.*pve_ocs_tgt pve" "$ACTION_LOG"; then
  echo "FAIL: vgrename was not called to finalize target VG name!"
  cat "$ACTION_LOG"
  exit 1
fi
echo "PASS: Test 1 (d2d mode): Shadow VG created, thin pool safely repaired on target, LVs cloned via Partclone, and VG renamed."

# Test 2: unicast mode (image restore) with thin pool
echo "--- Test 2: restore_logv in unicast mode (restoring from image) ---"
> "$ACTION_LOG"

cat << 'EOF' > "$MOCK_BIN/vgs"
#!/bin/bash
# In image restore mode, VG does not exist initially on target machine
exit 1
EOF
chmod +x "$MOCK_BIN/vgs"

restore_logv "sdb3" "unicast" ""

if ! grep -q "vgcfgrestore" "$ACTION_LOG"; then
  echo "FAIL: vgcfgrestore was not called in unicast mode!"
  cat "$ACTION_LOG"
  exit 1
fi

if ! grep -q "lvremove -y -f pve/vm-100-disk-0" "$ACTION_LOG"; then
  echo "FAIL: lvremove for thin LV was not called in unicast mode!"
  cat "$ACTION_LOG"
  exit 1
fi

if ! grep -q "lvremove -y -f pve/data" "$ACTION_LOG"; then
  echo "FAIL: lvremove for thin pool was not called in unicast mode!"
  cat "$ACTION_LOG"
  exit 1
fi

if ! grep -q "lvcreate -y --type thin-pool" "$ACTION_LOG"; then
  echo "FAIL: lvcreate thin-pool was not called in unicast mode!"
  cat "$ACTION_LOG"
  exit 1
fi

if ! grep -q "lvcreate -y -V.*--thin -n vm-100-disk-0" "$ACTION_LOG"; then
  echo "FAIL: lvcreate thin LV was not called in unicast mode!"
  cat "$ACTION_LOG"
  exit 1
fi

if ! grep -q "mkswap.*/dev/pve/swap" "$ACTION_LOG"; then
  echo "FAIL: mkswap was not called for swap LV in unicast mode!"
  cat "$ACTION_LOG"
  exit 1
fi
echo "PASS: Test 2 (unicast mode): vgcfgrestore, thin pool repair, and mkswap were properly executed."

# Test 3: unicast mode with pre-existing VG (vgcfgrestore skipped)
echo "--- Test 3: restore_logv in unicast mode with pre-existing VG ---"
> "$ACTION_LOG"

cat << 'EOF' > "$MOCK_BIN/vgs"
#!/bin/bash
# Pre-existing VG exists on target machine
exit 0
EOF
chmod +x "$MOCK_BIN/vgs"

restore_logv "sdb3" "unicast" ""

if grep -q "vgcfgrestore" "$ACTION_LOG"; then
  echo "FAIL: vgcfgrestore should have been skipped for pre-existing VG!"
  cat "$ACTION_LOG"
  exit 1
fi

if grep -q "lvremove" "$ACTION_LOG" || grep -q "lvcreate" "$ACTION_LOG"; then
  echo "FAIL: thin pool repair was called on pre-existing VG where vgcfgrestore was skipped!"
  cat "$ACTION_LOG"
  exit 1
fi
echo "PASS: Test 3: Pre-existing VG in unicast mode was protected from thin pool repair."

echo "=== All LVM Thin Pool Protection Tests Passed Successfully! ==="
