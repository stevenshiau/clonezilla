#!/bin/bash
# Standalone test for Clonezilla hybrid source write-blocking armour mechanism
# Tests standard disks/partitions, MDRAID arrays, LVM volume groups, re-entrancy, and conflict guards.

set -e

echo "=== Running Hybrid Source Device Armour Tests ==="

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
export DRBL_SCRIPT_PATH="/usr/share/drbl"
. "$SCRIPT_DIR/scripts/sbin/ocs-functions"

# -----------------------------------------------------------------------------
# Test 1: Standard disk and partition write-blocking via blockdev --setro / --setrw
# -----------------------------------------------------------------------------
echo "[Test 1] Testing standard disk and partition write-blocking..."
(
  TEST_DIR=$(mktemp -d /tmp/test-sro-std.XXXXXX)
  trap 'rm -rf "$TEST_DIR"' EXIT

  MOCK_BIN="$TEST_DIR/bin"
  mkdir -p "$MOCK_BIN"
  export PATH="$MOCK_BIN:$PATH"

  CALL_LOG="$TEST_DIR/calls.log"
  touch "$CALL_LOG"

  export OCS_SRC_RO_STATE_FILE="$TEST_DIR/state_file"
  export OCS_SRC_RO_DEPTH=0
  export source_dev_armour="enable"
  export rm_win_swap_hib="no"
  export fsck_src_part_auto="no"
  export fsck_src_part_intr="no"
  export rm_ntfs_vol_dirty_flag="no"

  # Mock lsblk
  cat <<'EOF' > "$MOCK_BIN/lsblk"
#!/bin/bash
case "$*" in
  *sda*)
    echo "/dev/sda"
    echo "/dev/sda1"
    echo "/dev/sda2"
    ;;
  *)
    exit 1
    ;;
esac
EOF
  chmod +x "$MOCK_BIN/lsblk"

  # Mock blockdev: sda and sda1 are rw (getro -> 0), sda2 is already ro (getro -> 1)
  cat <<EOF > "$MOCK_BIN/blockdev"
#!/bin/bash
echo "blockdev \$*" >> "$CALL_LOG"
case "\$1" in
  --getro)
    case "\$2" in
      /dev/sda2) echo "1" ;;
      *) echo "0" ;;
    esac
    ;;
  --setro|--setrw)
    exit 0
    ;;
esac
EOF
  chmod +x "$MOCK_BIN/blockdev"

  enable_source_dev_armour "sda"

  # Verify blockdev --getro was checked for all partitions
  if ! grep -q "blockdev --getro /dev/sda" "$CALL_LOG"; then
    echo "FAIL: Expected blockdev --getro /dev/sda"
    exit 1
  fi

  # Verify blockdev --setro was called on /dev/sda and /dev/sda1
  if ! grep -q "blockdev --setro /dev/sda" "$CALL_LOG"; then
    echo "FAIL: Expected blockdev --setro /dev/sda"
    exit 1
  fi
  if ! grep -q "blockdev --setro /dev/sda1" "$CALL_LOG"; then
    echo "FAIL: Expected blockdev --setro /dev/sda1"
    exit 1
  fi

  # Verify sda2 (which was already read-only) did NOT get recorded or setro
  if grep -q "blockdev --setro /dev/sda2" "$CALL_LOG"; then
    echo "FAIL: Device already read-only (/dev/sda2) should not have been setro"
    exit 1
  fi

  # Verify state file records /dev/sda and /dev/sda1
  if ! grep -q "DEV /dev/sda$" "$OCS_SRC_RO_STATE_FILE"; then
    echo "FAIL: /dev/sda missing from state file"
    exit 1
  fi
  if ! grep -q "DEV /dev/sda1$" "$OCS_SRC_RO_STATE_FILE"; then
    echo "FAIL: /dev/sda1 missing from state file"
    exit 1
  fi

  # Verify is_recorded_source_armour_dev and backward-compat alias
  if ! is_recorded_source_armour_dev "/dev/sda"; then
    echo "FAIL: is_recorded_source_armour_dev /dev/sda should return 0"
    exit 1
  fi
  if ! is_recorded_source_ro_dev "sda1"; then
    echo "FAIL: is_recorded_source_ro_dev sda1 should return 0"
    exit 1
  fi
  if is_recorded_source_armour_dev "/dev/sdb"; then
    echo "FAIL: is_recorded_source_armour_dev /dev/sdb should return 1"
    exit 1
  fi

  # Test disable_source_dev_armour
  disable_source_dev_armour

  if ! grep -q "blockdev --setrw /dev/sda" "$CALL_LOG"; then
    echo "FAIL: Expected blockdev --setrw /dev/sda upon restoration"
    exit 1
  fi
  if ! grep -q "blockdev --setrw /dev/sda1" "$CALL_LOG"; then
    echo "FAIL: Expected blockdev --setrw /dev/sda1 upon restoration"
    exit 1
  fi
  if grep -q "blockdev --setrw /dev/sda2" "$CALL_LOG"; then
    echo "FAIL: Device previously ro (/dev/sda2) must NOT be setrw"
    exit 1
  fi
  if [ -f "$OCS_SRC_RO_STATE_FILE" ]; then
    echo "FAIL: State file should be removed after disable_source_dev_armour"
    exit 1
  fi

  echo "  PASS: Standard disk and partition write-blocking and restoration verified."
)

# -----------------------------------------------------------------------------
# Test 2: MDRAID integration (native readonly before blockdev ro and start-skipping)
# -----------------------------------------------------------------------------
echo "[Test 2] Testing MDRAID native read-only integration..."
(
  TEST_DIR=$(mktemp -d /tmp/test-sro-md.XXXXXX)
  trap 'rm -rf "$TEST_DIR"' EXIT

  MOCK_BIN="$TEST_DIR/bin"
  mkdir -p "$MOCK_BIN"
  export PATH="$MOCK_BIN:$PATH"

  CALL_LOG="$TEST_DIR/calls.log"
  touch "$CALL_LOG"

  export OCS_SRC_RO_STATE_FILE="$TEST_DIR/state_file"
  export OCS_SRC_RO_DEPTH=0
  export source_dev_armour="enable"
  export rm_win_swap_hib="no"
  export fsck_src_part_auto="no"
  export fsck_src_part_intr="no"
  export rm_ntfs_vol_dirty_flag="no"

  # Mock /proc/mdstat with active rw array md127 on sda1 and sdb1
  MOCK_PROC="$TEST_DIR/proc"
  mkdir -p "$MOCK_PROC"
  cat <<'EOF' > "$MOCK_PROC/mdstat"
Personalities : [raid1]
md127 : active raid1 sda1[0] sdb1[1]
      1048576 blocks [2/2] [UU]
EOF

  # Setup mock awk to transparently redirect /proc/mdstat
  cat <<EOF > "$MOCK_BIN/awk"
#!/bin/bash
args=()
for a in "\$@"; do
  if [ "\$a" = "/proc/mdstat" ]; then
    args+=("$MOCK_PROC/mdstat")
  else
    args+=("\$a")
  fi
done
exec /usr/bin/awk "\${args[@]}"
EOF
  chmod +x "$MOCK_BIN/awk"

  # Setup mock grep to transparently redirect /proc/mdstat
  cat <<EOF > "$MOCK_BIN/grep"
#!/bin/bash
args=()
for a in "\$@"; do
  if [ "\$a" = "/proc/mdstat" ]; then
    args+=("$MOCK_PROC/mdstat")
  else
    args+=("\$a")
  fi
done
exec /usr/bin/grep "\${args[@]}"
EOF
  chmod +x "$MOCK_BIN/grep"

  # Mock mdadm
  cat <<EOF > "$MOCK_BIN/mdadm"
#!/bin/bash
echo "mdadm \$*" >> "$CALL_LOG"
case "\$1" in
  --detail)
    echo "       0       8        1        0      active sync   /dev/sda1"
    echo "       1       8       17        1      active sync   /dev/sdb1"
    ;;
  --readonly|--readwrite)
    exit 0
    ;;
esac
EOF
  chmod +x "$MOCK_BIN/mdadm"

  # Mock blockdev
  cat <<EOF > "$MOCK_BIN/blockdev"
#!/bin/bash
echo "blockdev \$*" >> "$CALL_LOG"
case "\$1" in
  --getro) echo "0" ;;
  *) exit 0 ;;
esac
EOF
  chmod +x "$MOCK_BIN/blockdev"

  # Mock lsblk
  cat <<'EOF' > "$MOCK_BIN/lsblk"
#!/bin/bash
case "$*" in
  *sda*)
    echo "/dev/sda"
    echo "/dev/sda1"
    ;;
  *md127*)
    echo "/dev/md127"
    ;;
  *)
    exit 1
    ;;
esac
EOF
  chmod +x "$MOCK_BIN/lsblk"

  enable_source_dev_armour "sda"

  # Verify mdadm --readonly was called on /dev/md127
  if ! grep -q "mdadm --readonly /dev/md127" "$CALL_LOG"; then
    echo "FAIL: Expected mdadm --readonly /dev/md127 before blockdev setro"
    exit 1
  fi

  # Verify order: mdadm --readonly /dev/md127 MUST occur before blockdev --setro /dev/sda1
  md_ro_line=$(grep -n "mdadm --readonly /dev/md127" "$CALL_LOG" | head -n 1 | cut -d: -f1)
  bdev_ro_line=$(grep -n "blockdev --setro /dev/sda1" "$CALL_LOG" | head -n 1 | cut -d: -f1)
  if [ -n "$md_ro_line" ] && [ -n "$bdev_ro_line" ] && [ "$md_ro_line" -ge "$bdev_ro_line" ]; then
    echo "FAIL: mdadm --readonly must be called before member blockdev --setro to avoid RAID drive fault drop!"
    exit 1
  fi

  # Verify ocs-mdraid-start skips switching md127 back to read-write while protected
  START_LOG="$TEST_DIR/start.log"
  MDADM_LOG="$START_LOG" bash "$SCRIPT_DIR/sbin/ocs-mdraid-start" >/dev/null 2>&1 || true

  # Test disable_source_dev_armour restores mdadm --readwrite
  disable_source_dev_armour

  if ! grep -q "mdadm --readwrite /dev/md127" "$CALL_LOG"; then
    echo "FAIL: Expected mdadm --readwrite /dev/md127 upon disable_source_dev_armour"
    exit 1
  fi

  echo "  PASS: MDRAID native read-only coordination verified."
)

# -----------------------------------------------------------------------------
# Test 3: LVM integration (native read-only activation and LV write-blocking)
# -----------------------------------------------------------------------------
echo "[Test 3] Testing LVM native read-only integration..."
(
  TEST_DIR=$(mktemp -d /tmp/test-sro-lvm.XXXXXX)
  trap 'rm -rf "$TEST_DIR"' EXIT

  MOCK_BIN="$TEST_DIR/bin"
  mkdir -p "$MOCK_BIN"
  export PATH="$MOCK_BIN:$PATH"

  CALL_LOG="$TEST_DIR/calls.log"
  touch "$CALL_LOG"

  export OCS_SRC_RO_STATE_FILE="$TEST_DIR/state_file"
  export OCS_SRC_RO_DEPTH=0
  export source_dev_armour="enable"
  export rm_win_swap_hib="no"
  export fsck_src_part_auto="no"
  export fsck_src_part_intr="no"
  export rm_ntfs_vol_dirty_flag="no"

  # Mock lsblk
  cat <<'EOF' > "$MOCK_BIN/lsblk"
#!/bin/bash
case "$*" in
  *sda*)
    echo "/dev/sda"
    echo "/dev/sda2"
    ;;
  *)
    exit 1
    ;;
esac
EOF
  chmod +x "$MOCK_BIN/lsblk"

  # Mock pvs
  cat <<'EOF' > "$MOCK_BIN/pvs"
#!/bin/bash
case "$*" in
  *sda2*) echo "vg_data" ;;
  *) echo "" ;;
esac
EOF
  chmod +x "$MOCK_BIN/pvs"

  # Mock vgchange
  cat <<EOF > "$MOCK_BIN/vgchange"
#!/bin/bash
echo "vgchange \$*" >> "$CALL_LOG"
exit 0
EOF
  chmod +x "$MOCK_BIN/vgchange"

  # Mock lvs
  cat <<'EOF' > "$MOCK_BIN/lvs"
#!/bin/bash
echo "/dev/vg_data/lv_app"
EOF
  chmod +x "$MOCK_BIN/lvs"

  # Mock blockdev
  cat <<EOF > "$MOCK_BIN/blockdev"
#!/bin/bash
echo "blockdev \$*" >> "$CALL_LOG"
case "\$1" in
  --getro) echo "0" ;;
  *) exit 0 ;;
esac
EOF
  chmod +x "$MOCK_BIN/blockdev"

  enable_source_dev_armour "sda"

  # Verify vgchange was called with read-only flag (-r)
  if ! grep -q "vgchange -a y -r vg_data" "$CALL_LOG"; then
    echo "FAIL: Expected vgchange -a y -r vg_data in log, got:"
    cat "$CALL_LOG"
    exit 1
  fi

  # Verify blockdev --setro was called on the Logical Volume
  if ! grep -q "blockdev --setro /dev/vg_data/lv_app" "$CALL_LOG"; then
    echo "FAIL: Expected blockdev --setro /dev/vg_data/lv_app in log"
    exit 1
  fi

  disable_source_dev_armour

  if ! grep -q "blockdev --setrw /dev/vg_data/lv_app" "$CALL_LOG"; then
    echo "FAIL: Expected blockdev --setrw /dev/vg_data/lv_app upon restoration"
    exit 1
  fi

  echo "  PASS: LVM native read-only coordination verified."
)

# -----------------------------------------------------------------------------
# Test 4: Re-entrancy guard (nested task_savedisk -> task_saveparts)
# -----------------------------------------------------------------------------
echo "[Test 4] Testing re-entrancy depth handling..."
(
  TEST_DIR=$(mktemp -d /tmp/test-sro-reentrant.XXXXXX)
  trap 'rm -rf "$TEST_DIR"' EXIT

  MOCK_BIN="$TEST_DIR/bin"
  mkdir -p "$MOCK_BIN"
  export PATH="$MOCK_BIN:$PATH"

  CALL_LOG="$TEST_DIR/calls.log"
  touch "$CALL_LOG"

  export OCS_SRC_RO_STATE_FILE="$TEST_DIR/state_file"
  export OCS_SRC_RO_DEPTH=0
  export source_dev_armour="enable"
  export rm_win_swap_hib="no"
  export fsck_src_part_auto="no"
  export fsck_src_part_intr="no"
  export rm_ntfs_vol_dirty_flag="no"

  cat <<EOF > "$MOCK_BIN/blockdev"
#!/bin/bash
echo "blockdev \$*" >> "$CALL_LOG"
case "\$1" in
  --getro) echo "0" ;;
  *) exit 0 ;;
esac
EOF
  chmod +x "$MOCK_BIN/blockdev"

  # First invocation (e.g. task_savedisk)
  enable_source_dev_armour "/dev/sda"
  if [ "$OCS_SRC_RO_DEPTH" -ne 1 ]; then
    echo "FAIL: Expected depth 1, got $OCS_SRC_RO_DEPTH"
    exit 1
  fi

  # Nested invocation (e.g. task_saveparts inside task_savedisk)
  enable_source_dev_armour "/dev/sda1"
  if [ "$OCS_SRC_RO_DEPTH" -ne 2 ]; then
    echo "FAIL: Expected depth 2, got $OCS_SRC_RO_DEPTH"
    exit 1
  fi

  # First release (task_saveparts finishes)
  disable_source_dev_armour
  if [ "$OCS_SRC_RO_DEPTH" -ne 1 ]; then
    echo "FAIL: Expected depth 1 after first release, got $OCS_SRC_RO_DEPTH"
    exit 1
  fi
  # Devices must still remain read-only!
  if grep -q "blockdev --setrw" "$CALL_LOG"; then
    echo "FAIL: Devices should NOT be restored while depth > 0!"
    exit 1
  fi

  # Final release (task_savedisk finishes)
  disable_source_dev_armour
  if [ "$OCS_SRC_RO_DEPTH" -ne 0 ]; then
    echo "FAIL: Expected depth 0 after final release, got $OCS_SRC_RO_DEPTH"
    exit 1
  fi
  if ! grep -q "blockdev --setrw /dev/sda" "$CALL_LOG"; then
    echo "FAIL: Expected blockdev --setrw after final release"
    exit 1
  fi

  echo "  PASS: Re-entrancy depth handling correctly preserves read-only locks."
)

# -----------------------------------------------------------------------------
# Test 5: Conflicting options handling
# -----------------------------------------------------------------------------
echo "[Test 5] Testing conflicting options handling..."
(
  TEST_DIR=$(mktemp -d /tmp/test-sro-conflict.XXXXXX)
  trap 'rm -rf "$TEST_DIR"' EXIT

  export OCS_SRC_RO_STATE_FILE="$TEST_DIR/state_file"
  export OCS_SRC_RO_DEPTH=0

  # Case A: explicit source_dev_armour="enable" + rm_win_swap_hib="yes" -> error
  export source_dev_armour="enable"
  export rm_win_swap_hib="yes"
  export fsck_src_part_auto="no"
  export fsck_src_part_intr="no"
  export rm_ntfs_vol_dirty_flag="no"

  set +e
  enable_source_dev_armour "/dev/sda"
  rc=$?
  set -e
  if [ "$rc" -eq 0 ]; then
    echo "FAIL: Expected error return code when combining source_dev_armour=enable and rm_win_swap_hib=yes"
    exit 1
  fi

  # Case B: auto mode (source_dev_armour="auto") + rm_win_swap_hib="yes" -> skip without error
  export source_dev_armour="auto"
  export rm_win_swap_hib="yes"
  export OCS_SRC_RO_DEPTH=0

  enable_source_dev_armour "/dev/sda"
  if [ -f "$OCS_SRC_RO_STATE_FILE" ]; then
    echo "FAIL: Should have skipped armour in auto mode when write actions requested"
    exit 1
  fi

  # Case C: disabled mode (source_dev_armour="disable") -> skip
  export source_dev_armour="disable"
  export rm_win_swap_hib="no"
  export OCS_SRC_RO_DEPTH=0

  enable_source_dev_armour "/dev/sda"
  if [ -f "$OCS_SRC_RO_STATE_FILE" ]; then
    echo "FAIL: Should not create state file when source_dev_armour=disable"
    exit 1
  fi

  echo "  PASS: Conflicting options correctly handled."
)

# -----------------------------------------------------------------------------
# Test 6: source_dev_armour configuration variable support
# -----------------------------------------------------------------------------
echo "[Test 6] Testing source_dev_armour variable (enable vs disable vs auto)..."
(
  TEST_DIR=$(mktemp -d /tmp/test-sro-armour.XXXXXX)
  trap 'rm -rf "$TEST_DIR"' EXIT

  MOCK_BIN="$TEST_DIR/bin"
  mkdir -p "$MOCK_BIN"
  export PATH="$MOCK_BIN:$PATH"

  CALL_LOG="$TEST_DIR/calls.log"
  touch "$CALL_LOG"

  export OCS_SRC_RO_STATE_FILE="$TEST_DIR/state_file"
  export OCS_SRC_RO_DEPTH=0
  export rm_win_swap_hib="no"
  export fsck_src_part_auto="no"
  export fsck_src_part_intr="no"
  export rm_ntfs_vol_dirty_flag="no"

  cat <<EOF > "$MOCK_BIN/blockdev"
#!/bin/bash
echo "blockdev \$*" >> "$CALL_LOG"
case "\$1" in
  --getro) echo "0" ;;
  *) exit 0 ;;
esac
EOF
  chmod +x "$MOCK_BIN/blockdev"

  # Case A: source_dev_armour="disable" should bypass write blocking completely
  export source_dev_armour="disable"
  enable_source_dev_armour "/dev/sda"
  if [ -f "$OCS_SRC_RO_STATE_FILE" ]; then
    echo "FAIL: State file created when source_dev_armour=disable"
    exit 1
  fi
  if grep -q "blockdev --setro" "$CALL_LOG"; then
    echo "FAIL: blockdev --setro should not be called when source_dev_armour=disable"
    exit 1
  fi

  # Case B: source_dev_armour="enable" should enforce write blocking
  export source_dev_armour="enable"
  enable_source_dev_armour "/dev/sda"
  if [ ! -f "$OCS_SRC_RO_STATE_FILE" ]; then
    echo "FAIL: State file not created when source_dev_armour=enable"
    exit 1
  fi
  if ! grep -q "blockdev --setro /dev/sda" "$CALL_LOG"; then
    echo "FAIL: Expected blockdev --setro /dev/sda when source_dev_armour=enable"
    exit 1
  fi
  disable_source_dev_armour

  echo "  PASS: source_dev_armour variable controls write-blocking successfully."
)

# -----------------------------------------------------------------------------
# Test 7: Multipath and sysfs holders/slaves compound device traversal
# -----------------------------------------------------------------------------
echo "[Test 7] Testing multipath expansion and sysfs compound device traversal..."
(
  TEST_DIR=$(mktemp -d /tmp/test-sro-mpath.XXXXXX)
  trap 'rm -rf "$TEST_DIR"' EXIT

  MOCK_BIN="$TEST_DIR/bin"
  mkdir -p "$MOCK_BIN"
  export PATH="$MOCK_BIN:$PATH"

  CALL_LOG="$TEST_DIR/calls.log"
  touch "$CALL_LOG"

  export OCS_SRC_RO_STATE_FILE="$TEST_DIR/state_file"
  export OCS_SRC_RO_DEPTH=0
  export source_dev_armour="enable"
  export rm_win_swap_hib="no"
  export fsck_src_part_auto="no"
  export fsck_src_part_intr="no"
  export rm_ntfs_vol_dirty_flag="no"

  # Mock expand_multipath_dev: when given mpatha, expands to sda and sdb
  expand_multipath_dev() {
    case "$*" in
      *mpatha*) echo "sda sdb mpatha" ;;
      *) echo "$*" ;;
    esac
  }
  export -f expand_multipath_dev

  cat <<EOF > "$MOCK_BIN/blockdev"
#!/bin/bash
echo "blockdev \$*" >> "$CALL_LOG"
case "\$1" in
  --getro) echo "0" ;;
  *) exit 0 ;;
esac
EOF
  chmod +x "$MOCK_BIN/blockdev"

  enable_source_dev_armour "mpatha"

  # Verify all paths and aggregate multipath device were set read-only
  if ! grep -q "blockdev --setro /dev/sda" "$CALL_LOG"; then
    echo "FAIL: Multipath path /dev/sda was not set read-only"
    exit 1
  fi
  if ! grep -q "blockdev --setro /dev/sdb" "$CALL_LOG"; then
    echo "FAIL: Multipath path /dev/sdb was not set read-only"
    exit 1
  fi
  if ! grep -q "blockdev --setro /dev/mpatha" "$CALL_LOG"; then
    echo "FAIL: Aggregate device /dev/mpatha was not set read-only"
    exit 1
  fi

  disable_source_dev_armour

  echo "  PASS: Multipath and compound device paths are fully protected."
)

# -----------------------------------------------------------------------------
# Test 8: eMMC hardware boot partition write-protection (force_ro=1)
# -----------------------------------------------------------------------------
echo "[Test 8] Testing eMMC hardware boot partition force_ro protection..."
(
  TEST_DIR=$(mktemp -d /tmp/test-sro-emmc.XXXXXX)
  trap 'rm -rf "$TEST_DIR"' EXIT

  MOCK_BIN="$TEST_DIR/bin"
  mkdir -p "$MOCK_BIN"
  export PATH="$MOCK_BIN:$PATH"

  CALL_LOG="$TEST_DIR/calls.log"
  touch "$CALL_LOG"

  export OCS_SRC_RO_STATE_FILE="$TEST_DIR/state_file"
  export OCS_SRC_RO_DEPTH=0
  export source_dev_armour="enable"
  export rm_win_swap_hib="no"
  export fsck_src_part_auto="no"
  export fsck_src_part_intr="no"
  export rm_ntfs_vol_dirty_flag="no"

  # Create mock sysfs force_ro file
  export SYSFS_PATH="$TEST_DIR/sys"
  MOCK_SYS="$TEST_DIR/sys/class/block/mmcblk0boot0"
  mkdir -p "$MOCK_SYS"
  echo "0" > "$MOCK_SYS/force_ro"

  cat <<EOF > "$MOCK_BIN/blockdev"
#!/bin/bash
echo "blockdev \$*" >> "$CALL_LOG"
case "\$1" in
  --getro) echo "0" ;;
  *) exit 0 ;;
esac
EOF
  chmod +x "$MOCK_BIN/blockdev"

  enable_source_dev_armour "mmcblk0boot0"

  # Check if force_ro was changed to 1
  force_ro_val=$(cat "$MOCK_SYS/force_ro")
  if [ "$force_ro_val" != "1" ]; then
    echo "FAIL: Expected force_ro=1, got $force_ro_val"
    exit 1
  fi

  disable_source_dev_armour

  # Check if force_ro was restored to 0
  force_ro_val=$(cat "$MOCK_SYS/force_ro")
  if [ "$force_ro_val" != "0" ]; then
    echo "FAIL: Expected force_ro restored to 0, got $force_ro_val"
    exit 1
  fi

  echo "  PASS: eMMC hardware boot partition write protection verified."
)

echo "=== All Hybrid Source Device Armour Tests Passed Successfully! ==="
exit 0
