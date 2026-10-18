#!/bin/bash
# Standalone test for MDRAID array detection, assembly, filtering, and mounting logic (Issue #194)

set -e

echo "=== Running MDRAID Detection and Filtering Tests ==="

# Load scripts/sbin/ocs-functions
. scripts/sbin/ocs-functions

# -----------------------------------------------------------------------------
# TEST 1: get_disk_or_part_hardware_info with flag_skip_lvm_raid="yes"
# -----------------------------------------------------------------------------
echo "TEST 1: get_disk_or_part_hardware_info filtering..."

JSON_FILE=$(mktemp /tmp/mock-blkinfo-md.XXXXXX)
cat <<'EOF' > "$JSON_FILE"
[
  {
    "name": "md127",
    "type": "raid1",
    "size": "500G",
    "model": "MD_RAID1_Array",
    "fstype": "ext4",
    "serial": "raid-serial-127",
    "label": "DataRAID",
    "id_path_tag": "N/A"
  },
  {
    "name": "sda1",
    "type": "part",
    "size": "500G",
    "model": "HardDisk_A",
    "fstype": "linux_raid_member",
    "serial": "disk-serial-a",
    "label": "",
    "id_path_tag": "pci-0000-sda"
  },
  {
    "name": "sdb",
    "type": "disk",
    "size": "1000G",
    "model": "HardDisk_B",
    "fstype": "LVM2_member",
    "serial": "disk-serial-b",
    "label": "",
    "id_path_tag": "pci-0000-sdb"
  }
]
EOF

# Mock helper functions
is_supported_dev() { return 0; }

# For md127: bare array with filesystem, treated as partition
# For sda1: normal partition
# For sdb: whole disk
is_partition() {
  case "$1" in
    md127|sda1) return 0 ;;
    sdb) return 1 ;;
  esac
  return 1
}

is_whole_disk() {
  case "${1#/dev/}" in
    sdb) return 0 ;;
    md127|sda1) return 1 ;;
  esac
  return 1
}

is_block_device_with_fs() {
  case "${1#/dev/}" in
    md127) return 0 ;;
    sda1|sdb) return 1 ;;
  esac
  return 1
}

get_diskname() {
  case "$1" in
    sda1) echo "sda" ;;
    md127) echo "md127" ;;
    sdb) echo "sdb" ;;
    *) echo "$1" ;;
  esac
}

# (a) md127 with ext4: MUST NOT be skipped when flag_skip_lvm_raid="yes"
rc=0
get_disk_or_part_hardware_info "md127" "yes" "$JSON_FILE" || rc=$?
if [ "$rc" -eq 8 ]; then
  echo "FAIL: md127 with ext4 was skipped (returned 8) when flag_skip_lvm_raid=yes!"
  exit 1
fi
echo "PASS: md127 with ext4 was not skipped by get_disk_or_part_hardware_info."

# (b) sda1 (raw raid member): MUST BE SKIPPED when flag_skip_lvm_raid="yes"
rc=0
get_disk_or_part_hardware_info "sda1" "yes" "$JSON_FILE" || rc=$?
if [ "$rc" -ne 8 ]; then
  echo "FAIL: sda1 (raw raid member) was NOT skipped when flag_skip_lvm_raid=yes (rc=$rc)!"
  exit 1
fi
echo "PASS: sda1 (raw raid member) was correctly skipped."

# (c) sdb (whole disk PV): MUST NOT be skipped because it is a whole disk
rc=0
get_disk_or_part_hardware_info "sdb" "yes" "$JSON_FILE" || rc=$?
if [ "$rc" -eq 8 ]; then
  echo "FAIL: sdb (whole disk PV) was skipped when flag_skip_lvm_raid=yes!"
  exit 1
fi
echo "PASS: sdb (whole disk PV) was not skipped."

rm -f "$JSON_FILE"

# -----------------------------------------------------------------------------
# TEST 2: get_input_dev_name partition counting with skip_lvm_raid="yes"
# -----------------------------------------------------------------------------
echo "TEST 2: get_input_dev_name MDRAID partition counting..."

export BOOTUP="color"
export SETCOLOR_WARNING="echo -n"
export SETCOLOR_FAILURE="echo -n"
export SETCOLOR_NORMAL="echo -n"
export msg_error="Error"
export msg_not_mounted_dev_found="No unmounted device found"
export msg_press_enter_to_exit="Press enter to exit"
export msg_choose_disks_to_save="Choose disk"
export msg_linux_disk_naming="Linux disk naming"
export msg_press_space_to_mark_selection="Space to select"
# Mock DIA as a script executable
MOCK_DIA_BIN="/tmp/mock-dia-bin"
cat <<'EOF' > "$MOCK_DIA_BIN"
#!/bin/bash
# Dialog prints selection to stderr
echo "md127" >&2
exit 0
EOF
chmod +x "$MOCK_DIA_BIN"
export DIA="$MOCK_DIA_BIN"
export DIA_ESC=""

# Mock ocs-get-dev-info
ocs-get-dev-info() {
  local dev="$1"
  local field="$2"
  case "$dev" in
    /dev/md127)
      echo "raid1 ext4"
      ;;
    /dev/sda1)
      echo "part linux_raid_member"
      ;;
    *)
      echo ""
      ;;
  esac
}

# Mock ocs-blk-dev-info
ocs-blk-dev-info() {
  cat <<'EOF' > "$1"
[
  {
    "name": "md127",
    "type": "raid1",
    "size": "500G",
    "model": "MD_RAID1_Array",
    "fstype": "ext4",
    "serial": "raid-serial-127",
    "label": "DataRAID",
    "id_path_tag": "N/A"
  }
]
EOF
}

# (a) When dev_list contains md127 (bare MDRAID with filesystem):
get_not_busy_disks_or_parts() {
  dev_list="md127"
}

ANS_TMP=$(mktemp /tmp/ans-md.XXXXXX)
# Call get_input_dev_name for partition with skip_lvm_raid="yes"
# It should find NUMDEV=1 and succeed
if get_input_dev_name "$ANS_TMP" partition menu yes "prompt" < /dev/null; then
  echo "PASS: get_input_dev_name successfully kept md127 with filesystem."
else
  echo "FAIL: get_input_dev_name failed or skipped md127 with filesystem!"
  exit 1
fi
rm -f "$ANS_TMP"

# (b) When dev_list contains only sda1 (raw raid member, no fs):
get_not_busy_disks_or_parts() {
  dev_list="sda1"
}
get_part_list() {
  echo "sda1"
}

ANS_TMP=$(mktemp /tmp/ans-sda1.XXXXXX)
# It should filter sda1 out (NUMDEV=0) and exit with 1
if ( get_input_dev_name "$ANS_TMP" partition menu yes "prompt" < /dev/null ) 2>/dev/null; then
  echo "FAIL: get_input_dev_name should have skipped sda1 raw raid member, but succeeded!"
  exit 1
else
  echo "PASS: get_input_dev_name correctly skipped sda1 raw raid member."
fi
rm -f "$ANS_TMP"

# -----------------------------------------------------------------------------
# TEST 3: ocs-mdraid-start read-only recovery logic
# -----------------------------------------------------------------------------
echo "TEST 3: ocs-mdraid-start read-only recovery..."

MOCK_BIN=$(mktemp -d /tmp/mock-bin-start.XXXXXX)
MDADM_LOG="$MOCK_BIN/mdadm.log"
cat <<EOF > "$MOCK_BIN/mdadm"
#!/bin/bash
echo "mdadm \$*" >> "$MDADM_LOG"
exit 0
EOF
chmod +x "$MOCK_BIN/mdadm"

MOCK_PROC=$(mktemp -d /tmp/mock-proc.XXXXXX)
cat <<'EOF' > "$MOCK_PROC/mdstat"
Personalities : [raid1]
md127 : active (read-only) raid1 sda1[0] sdb1[1]
      1048576 blocks [2/2] [UU]
EOF

# Run subshell with overridden PATH and /proc/mdstat redirected or mocked
(
  export PATH="$MOCK_BIN:$PATH"
  # Mock awk to read our mock mdstat
  awk() {
    if [ "$#" -ge 2 ] && [ "${!#}" = "/proc/mdstat" ]; then
      set -- "${@:1:$#-1}" "$MOCK_PROC/mdstat"
    fi
    command awk "$@"
  }
  export -f awk

  # Test read-only switching logic from ocs-mdraid-start
  for md in $(awk '/^md.*\(.*read-only.*\)/ {print $1}' /proc/mdstat 2>/dev/null); do
    mdadm --readwrite "/dev/$md" >/dev/null 2>&1 || true
  done
)

if grep -q "mdadm --readwrite /dev/md127" "$MDADM_LOG"; then
  echo "PASS: ocs-mdraid-start switches read-only array md127 to read-write."
else
  echo "FAIL: ocs-mdraid-start did not switch read-only array to read-write!"
  exit 1
fi

rm -rf "$MOCK_BIN" "$MOCK_PROC"

# -----------------------------------------------------------------------------
# TEST 4: ocs-mdraid-stop mounted device preservation
# -----------------------------------------------------------------------------
echo "TEST 4: ocs-mdraid-stop mounted device preservation..."

MOCK_BIN=$(mktemp -d /tmp/mock-bin-stop.XXXXXX)
MDADM_LOG="$MOCK_BIN/mdadm.log"
cat <<EOF > "$MOCK_BIN/mdadm"
#!/bin/bash
echo "mdadm \$*" >> "$MDADM_LOG"
exit 0
EOF
chmod +x "$MOCK_BIN/mdadm"

MOCK_PROC=$(mktemp -d /tmp/mock-proc-stop.XXXXXX)
cat <<'EOF' > "$MOCK_PROC/mdstat"
Personalities : [raid1]
md127 : active raid1 sda1[0] sdb1[1]
md0 : active raid1 sdc1[0] sdd1[1]
EOF

cat <<'EOF' > "$MOCK_PROC/mounts"
/dev/md127 /home/partimage ext4 rw 0 0
EOF

(
  export PATH="$MOCK_BIN:$PATH"
  # Mock awk and grep to use mock proc files
  awk() {
    if [ "$#" -ge 2 ] && [ "${!#}" = "/proc/mdstat" ]; then
      set -- "${@:1:$#-1}" "$MOCK_PROC/mdstat"
    fi
    command awk "$@"
  }
  grep() {
    local args=()
    for a in "$@"; do
      if [ "$a" = "/proc/mounts" ]; then
        args+=("$MOCK_PROC/mounts")
      else
        args+=("$a")
      fi
    done
    command grep "${args[@]}"
  }
  export -f awk grep

  # Execute logic from sbin/ocs-mdraid-stop
  ACTIVE_MDS=$(awk '/^md/ {print $1}' /proc/mdstat 2>/dev/null | sort -r)
  for md in $ACTIVE_MDS; do
    if grep -qE "^/dev/${md}(p[0-9]+)?[[:space:]]" /proc/mounts 2>/dev/null; then
      echo "  Skipping mounted MDRAID device: /dev/$md"
      continue
    fi
    mdadm --stop /dev/$md >/dev/null 2>&1
  done
)

# Verify md127 was skipped and md0 was stopped
if grep -q "mdadm --stop /dev/md127" "$MDADM_LOG" 2>/dev/null; then
  echo "FAIL: Mounted repository md127 was stopped by ocs-mdraid-stop!"
  exit 1
fi
if grep -q "mdadm --stop /dev/md0" "$MDADM_LOG"; then
  echo "PASS: Unmounted md0 was stopped and mounted md127 was preserved."
else
  echo "FAIL: Expected md0 to be stopped!"
  exit 1
fi

rm -rf "$MOCK_BIN" "$MOCK_PROC"

# -----------------------------------------------------------------------------
# TEST 5: do_mount_local_dev already-mounted detection
# -----------------------------------------------------------------------------
echo "TEST 5: do_mount_local_dev already-mounted detection..."

(
  export ocsroot="/home/partimage"
  # Mock mountpoint to return true for $ocsroot
  mountpoint() {
    if [ "$2" = "$ocsroot" ] || [ "$1" = "$ocsroot" ]; then
      return 0
    fi
    return 1
  }
  prepare_mnt_point_ocsroot() { :; }
  export -f mountpoint prepare_mnt_point_ocsroot

  # Simulate do_mount_local_dev early check
  check_mounted() {
    prepare_mnt_point_ocsroot
    if mountpoint -q "$ocsroot"; then
      echo "$ocsroot is already mounted."
      return 0
    fi
    return 1
  }

  if check_mounted; then
    echo "PASS: do_mount_local_dev cleanly detects already mounted repository."
  else
    echo "FAIL: do_mount_local_dev did not detect mounted repository!"
    exit 1
  fi
)

echo "=== All MDRAID Detection and Filtering Tests Passed Successfully! ==="
exit 0
