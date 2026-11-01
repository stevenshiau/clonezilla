#!/bin/bash
# test-gen-chksum-files-in-dev.sh: Verify that gen_chksum_for_files_in_dev
# efficiently generates file checksums in parallel, handles spaces in filenames,
# produces valid compressed checksum info files, and correctly interoperates
# with inspect_chksum_for_files_in_dev.
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

echo "=== Running Clonezilla gen_chksum_for_files_in_dev Tests ==="

TMP_DIR="$(mktemp -d /tmp/test-gen-chksum.XXXXXX)"
trap 'rm -rf "$TMP_DIR"' EXIT

MOCK_BIN="$TMP_DIR/bin"
mkdir -p "$MOCK_BIN"

# Mock mount and umount to simulate partition filesystem
export MOCK_MOUNT_DATA="$TMP_DIR/mock_data"
mkdir -p "$MOCK_MOUNT_DATA"

export MOUNT_RECORD="$TMP_DIR/mount_records"
mkdir -p "$MOUNT_RECORD"

cat <<'EOF' > "$MOCK_BIN/mount"
#!/bin/bash
if [ -n "$CALL_LOG" ]; then
  echo "mount $*" >> "$CALL_LOG"
fi
args=("$@")
dev="${args[-2]}"
target_dir="${args[-1]}"
dev_key="$(basename "$dev")"
echo "$target_dir" > "$MOUNT_RECORD/$dev_key"
mkdir -p "$target_dir"
cp -a "$MOCK_MOUNT_DATA/." "$target_dir/" 2>/dev/null || true
exit 0
EOF
chmod +x "$MOCK_BIN/mount"

cat <<'EOF' > "$MOCK_BIN/mountpoint"
#!/bin/bash
exit 0
EOF
chmod +x "$MOCK_BIN/mountpoint"

export DEV_FS_DIR="$TMP_DIR/dev_fs"
mkdir -p "$DEV_FS_DIR"

cat <<'EOF' > "$MOCK_BIN/ocs-get-dev-info"
#!/bin/bash
dev="$1"
req="$2"
dev_base="$(basename "$dev")"
if [ "$req" = "filesystem" ] || [ "$req" = "fs" ]; then
  if [ -f "$DEV_FS_DIR/$dev_base" ]; then
    cat "$DEV_FS_DIR/$dev_base"
    exit 0
  fi
fi
exit 0
EOF
chmod +x "$MOCK_BIN/ocs-get-dev-info"

cat <<'EOF' > "$MOCK_BIN/ntfs-3g"
#!/bin/bash
if [ -n "$CALL_LOG" ]; then
  echo "ntfs-3g $*" >> "$CALL_LOG"
fi
dev="$1"
target_dir="$2"
dev_key="$(basename "$dev")"
echo "$target_dir" > "$MOUNT_RECORD/$dev_key"
mkdir -p "$target_dir"
cp -a "$MOCK_MOUNT_DATA/." "$target_dir/" 2>/dev/null || true
exit 0
EOF
chmod +x "$MOCK_BIN/ntfs-3g"

cat <<'EOF' > "$MOCK_BIN/umount"
#!/bin/bash
args=("$@")
target="${args[-1]}"
dev_key="$(basename "$target")"
if [ -f "$MOUNT_RECORD/$dev_key" ]; then
  mnt_dir="$(cat "$MOUNT_RECORD/$dev_key")"
  if [ -d "$mnt_dir" ]; then
    rm -rf "$mnt_dir"/* "$mnt_dir"/.[!.]* "$mnt_dir"/..?* 2>/dev/null || true
  fi
  rm -f "$MOUNT_RECORD/$dev_key"
elif [ -d "$target" ]; then
  rm -rf "$target"/* "$target"/.[!.]* "$target"/..?* 2>/dev/null || true
fi
exit 0
EOF
chmod +x "$MOCK_BIN/umount"

export PATH="$MOCK_BIN:$PATH"
export DRBL_SCRIPT_PATH="$REPO_DIR"

source "$REPO_DIR/conf/drbl-ocs.conf"
source "$REPO_DIR/scripts/sbin/ocs-functions"

export ocs_log_dir="$TMP_DIR/log"
mkdir -p "$ocs_log_dir"
export OCS_LOGFILE="$TMP_DIR/ocs.log"
touch "$OCS_LOGFILE"

# -------------------------------------------------------------
# Test 1: Verify b3sum generation and inspection with spaces
# -------------------------------------------------------------
echo "[Test 1] Testing b3sum checksum generation and inspection..."
(
  chksum_cmd_for_files_in_dev="b3sum"
  mkdir -p "$MOCK_MOUNT_DATA/etc" "$MOCK_MOUNT_DATA/var/log"
  echo "clonezilla test 1" > "$MOCK_MOUNT_DATA/etc/fstab"
  echo "log data" > "$MOCK_MOUNT_DATA/var/log/syslog"
  echo "spaced filename content" > "$MOCK_MOUNT_DATA/etc/file with spaces.conf"

  TGT_IMG="$TMP_DIR/img_b3sum"
  mkdir -p "$TGT_IMG"

  gen_chksum_for_files_in_dev "/dev/nvme0n1p2" "$TGT_IMG"
  rc=$?
  if [ "$rc" -ne 0 ]; then
    echo "FAIL: gen_chksum_for_files_in_dev failed with exit code $rc"
    exit 1
  fi

  EXPECTED_FILE="$TGT_IMG/nvme0n1p2.files-b3sum.info.gz"
  if [ ! -f "$EXPECTED_FILE" ]; then
    echo "FAIL: Expected checksum file $EXPECTED_FILE was not created"
    exit 1
  fi

  LINE_COUNT="$(zcat "$EXPECTED_FILE" | wc -l)"
  if [ "$LINE_COUNT" -ne 3 ]; then
    echo "FAIL: Expected 3 lines in checksum file, got $LINE_COUNT"
    exit 1
  fi

  # Run inspect_chksum_for_files_in_dev to verify format compatibility
  inspect_chksum_for_files_in_dev "/dev/nvme0n1p2" "$TGT_IMG"
  rc_inspect=$?
  if [ "$rc_inspect" -ne 0 ]; then
    echo "FAIL: inspect_chksum_for_files_in_dev failed with exit code $rc_inspect"
    exit 1
  fi
)
echo "  PASS: b3sum checksum generated and inspected successfully."

# -------------------------------------------------------------
# Test 2: Verify md5sum checksum generation and inspection
# -------------------------------------------------------------
echo "[Test 2] Testing md5sum checksum generation and inspection..."
(
  chksum_cmd_for_files_in_dev="md5sum"
  TGT_IMG="$TMP_DIR/img_md5sum"
  mkdir -p "$TGT_IMG"

  gen_chksum_for_files_in_dev "/dev/sda1" "$TGT_IMG"
  rc=$?
  if [ "$rc" -ne 0 ]; then
    echo "FAIL: gen_chksum_for_files_in_dev with md5sum failed with exit code $rc"
    exit 1
  fi

  EXPECTED_FILE="$TGT_IMG/sda1.files-md5sum.info.gz"
  if [ ! -f "$EXPECTED_FILE" ]; then
    echo "FAIL: Expected checksum file $EXPECTED_FILE was not created"
    exit 1
  fi

  inspect_chksum_for_files_in_dev "/dev/sda1" "$TGT_IMG"
  rc_inspect=$?
  if [ "$rc_inspect" -ne 0 ]; then
    echo "FAIL: inspect_chksum_for_files_in_dev with md5sum failed with exit code $rc_inspect"
    exit 1
  fi
)
echo "  PASS: md5sum checksum generated and inspected successfully."

# -------------------------------------------------------------
# Test 3: Verify handling of empty device / no files
# -------------------------------------------------------------
echo "[Test 3] Testing empty partition (0 regular files)..."
(
  rm -rf "$MOCK_MOUNT_DATA"/*
  chksum_cmd_for_files_in_dev="b3sum"
  TGT_IMG="$TMP_DIR/img_empty"
  mkdir -p "$TGT_IMG"

  gen_chksum_for_files_in_dev "/dev/sdb1" "$TGT_IMG"
  rc=$?
  if [ "$rc" -ne 0 ]; then
    echo "FAIL: gen_chksum_for_files_in_dev on empty partition failed with exit code $rc"
    exit 1
  fi

  EXPECTED_FILE="$TGT_IMG/sdb1.files-b3sum.info.gz"
  if [ ! -f "$EXPECTED_FILE" ]; then
    echo "FAIL: Expected checksum file $EXPECTED_FILE was not created"
    exit 1
  fi

  LINE_COUNT="$(zcat "$EXPECTED_FILE" | wc -l)"
  if [ "$LINE_COUNT" -ne 0 ]; then
    echo "FAIL: Expected 0 lines in empty checksum file, got $LINE_COUNT"
    exit 1
  fi
)
echo "  PASS: Empty partition handled cleanly without errors."

# -------------------------------------------------------------
# Test 4: NTFS filesystem with modern in-kernel ntfs priority
# -------------------------------------------------------------
echo "[Test 4] Testing NTFS filesystem with in-kernel ntfs driver priority..."
(
  echo "ntfs" > "$DEV_FS_DIR/sdc1"
  mkdir -p "$MOCK_MOUNT_DATA/Windows/System32"
  echo "ntfs system file" > "$MOCK_MOUNT_DATA/Windows/System32/ntoskrnl.exe"

  # Mock modinfo to report read-write in-kernel ntfs
  cat <<'EOF' > "$MOCK_BIN/modinfo"
#!/bin/bash
if [ "$1" = "-F" ] && [ "$2" = "description" ] && [ "$3" = "ntfs" ]; then
  echo "NTFS read-write filesystem driver"
  exit 0
fi
exit 1
EOF
  chmod +x "$MOCK_BIN/modinfo"

  cat <<'EOF' > "$MOCK_BIN/modprobe"
#!/bin/bash
if [ "$1" = "ntfs" ]; then
  exit 0
fi
exit 1
EOF
  chmod +x "$MOCK_BIN/modprobe"

  export CALL_LOG="$TMP_DIR/calls_test4.log"
  touch "$CALL_LOG"

  chksum_cmd_for_files_in_dev="b3sum"
  TGT_IMG="$TMP_DIR/img_test4"
  mkdir -p "$TGT_IMG"

  gen_chksum_for_files_in_dev "/dev/sdc1" "$TGT_IMG"
  rc=$?
  if [ "$rc" -ne 0 ]; then
    echo "FAIL: gen_chksum_for_files_in_dev failed for NTFS in-kernel ntfs with exit code $rc"
    exit 1
  fi

  if ! grep -q "mount -i -t ntfs -o ro /dev/sdc1" "$CALL_LOG"; then
    echo "FAIL: Expected 'mount -i -t ntfs -o ro /dev/sdc1' in calls log, got:"
    cat "$CALL_LOG"
    exit 1
  fi

  # Inspect checksum
  inspect_chksum_for_files_in_dev "/dev/sdc1" "$TGT_IMG"
  rc_inspect=$?
  if [ "$rc_inspect" -ne 0 ]; then
    echo "FAIL: inspect_chksum_for_files_in_dev failed for NTFS in-kernel ntfs with exit code $rc_inspect"
    exit 1
  fi

  ntfs_mount_count=$(grep -c "mount -i -t ntfs -o ro /dev/sdc1" "$CALL_LOG")
  if [ "$ntfs_mount_count" -ne 2 ]; then
    echo "FAIL: Expected 2 in-kernel ntfs mount calls (gen + inspect), got $ntfs_mount_count"
    cat "$CALL_LOG"
    exit 1
  fi
)
echo "  PASS: In-kernel ntfs driver prioritized and invoked with -i flag for gen and inspect."

# -------------------------------------------------------------
# Test 5: NTFS filesystem with in-kernel ntfs3 driver priority
# -------------------------------------------------------------
echo "[Test 5] Testing NTFS filesystem with in-kernel ntfs3 priority when ntfs is absent..."
(
  echo "ntfs" > "$DEV_FS_DIR/sdd1"
  mkdir -p "$MOCK_MOUNT_DATA/Windows"
  echo "ntfs3 data" > "$MOCK_MOUNT_DATA/Windows/win.ini"

  # ntfs fails, ntfs3 succeeds
  cat <<'EOF' > "$MOCK_BIN/modinfo"
#!/bin/bash
if [ "$1" = "ntfs3" ] || [ "$3" = "ntfs3" ]; then
  echo "NTFS3 driver"
  exit 0
fi
exit 1
EOF
  chmod +x "$MOCK_BIN/modinfo"

  cat <<'EOF' > "$MOCK_BIN/modprobe"
#!/bin/bash
if [ "$1" = "ntfs3" ]; then
  exit 0
fi
exit 1
EOF
  chmod +x "$MOCK_BIN/modprobe"

  export CALL_LOG="$TMP_DIR/calls_test5.log"
  touch "$CALL_LOG"

  chksum_cmd_for_files_in_dev="b3sum"
  TGT_IMG="$TMP_DIR/img_test5"
  mkdir -p "$TGT_IMG"

  gen_chksum_for_files_in_dev "/dev/sdd1" "$TGT_IMG"
  rc=$?
  if [ "$rc" -ne 0 ]; then
    echo "FAIL: gen_chksum_for_files_in_dev failed for NTFS in-kernel ntfs3 with exit code $rc"
    exit 1
  fi

  if ! grep -q "mount -i -t ntfs3 -o ro /dev/sdd1" "$CALL_LOG"; then
    echo "FAIL: Expected 'mount -i -t ntfs3 -o ro /dev/sdd1' in calls log, got:"
    cat "$CALL_LOG"
    exit 1
  fi

  inspect_chksum_for_files_in_dev "/dev/sdd1" "$TGT_IMG"
  rc_inspect=$?
  if [ "$rc_inspect" -ne 0 ]; then
    echo "FAIL: inspect_chksum_for_files_in_dev failed for NTFS in-kernel ntfs3 with exit code $rc_inspect"
    exit 1
  fi

  ntfs3_mount_count=$(grep -c "mount -i -t ntfs3 -o ro /dev/sdd1" "$CALL_LOG")
  if [ "$ntfs3_mount_count" -ne 2 ]; then
    echo "FAIL: Expected 2 in-kernel ntfs3 mount calls (gen + inspect), got $ntfs3_mount_count"
    cat "$CALL_LOG"
    exit 1
  fi
)
echo "  PASS: In-kernel ntfs3 driver prioritized when ntfs is unavailable."

# -------------------------------------------------------------
# Test 6: NTFS filesystem falling back to ntfs-3g
# -------------------------------------------------------------
echo "[Test 6] Testing NTFS filesystem fallback to ntfs-3g when kernel drivers are absent..."
(
  echo "ntfs" > "$DEV_FS_DIR/sde1"
  mkdir -p "$MOCK_MOUNT_DATA/Users"
  echo "user data" > "$MOCK_MOUNT_DATA/Users/user.txt"

  cat <<'EOF' > "$MOCK_BIN/modinfo"
#!/bin/bash
exit 1
EOF
  chmod +x "$MOCK_BIN/modinfo"

  cat <<'EOF' > "$MOCK_BIN/modprobe"
#!/bin/bash
exit 1
EOF
  chmod +x "$MOCK_BIN/modprobe"

  export CALL_LOG="$TMP_DIR/calls_test6.log"
  touch "$CALL_LOG"

  chksum_cmd_for_files_in_dev="b3sum"
  TGT_IMG="$TMP_DIR/img_test6"
  mkdir -p "$TGT_IMG"

  gen_chksum_for_files_in_dev "/dev/sde1" "$TGT_IMG"
  rc=$?
  if [ "$rc" -ne 0 ]; then
    echo "FAIL: gen_chksum_for_files_in_dev failed for ntfs-3g with exit code $rc"
    exit 1
  fi

  if ! grep -q "ntfs-3g /dev/sde1 " "$CALL_LOG"; then
    echo "FAIL: Expected 'ntfs-3g /dev/sde1' in calls log, got:"
    cat "$CALL_LOG"
    exit 1
  fi

  inspect_chksum_for_files_in_dev "/dev/sde1" "$TGT_IMG"
  rc_inspect=$?
  if [ "$rc_inspect" -ne 0 ]; then
    echo "FAIL: inspect_chksum_for_files_in_dev failed for ntfs-3g with exit code $rc_inspect"
    exit 1
  fi

  ntfs3g_mount_count=$(grep -c "ntfs-3g /dev/sde1 " "$CALL_LOG")
  if [ "$ntfs3g_mount_count" -ne 2 ]; then
    echo "FAIL: Expected 2 ntfs-3g mount calls (gen + inspect), got $ntfs3g_mount_count"
    cat "$CALL_LOG"
    exit 1
  fi
)
echo "  PASS: Gracefully falls back to ntfs-3g for gen and inspect."

# -------------------------------------------------------------
# Test 7: Non-NTFS filesystem (e.g. ext4) uses generic mount
# -------------------------------------------------------------
echo "[Test 7] Testing non-NTFS filesystem (ext4) uses generic mount..."
(
  echo "ext4" > "$DEV_FS_DIR/sdf1"
  mkdir -p "$MOCK_MOUNT_DATA/home"
  echo "linux data" > "$MOCK_MOUNT_DATA/home/linux.txt"

  export CALL_LOG="$TMP_DIR/calls_test7.log"
  touch "$CALL_LOG"

  chksum_cmd_for_files_in_dev="b3sum"
  TGT_IMG="$TMP_DIR/img_test7"
  mkdir -p "$TGT_IMG"

  gen_chksum_for_files_in_dev "/dev/sdf1" "$TGT_IMG"
  rc=$?
  if [ "$rc" -ne 0 ]; then
    echo "FAIL: gen_chksum_for_files_in_dev failed for ext4 with exit code $rc"
    exit 1
  fi

  if ! grep -q "mount -o ro /dev/sdf1" "$CALL_LOG"; then
    echo "FAIL: Expected 'mount -o ro /dev/sdf1' in calls log, got:"
    cat "$CALL_LOG"
    exit 1
  fi

  if grep -q "\-t ntfs" "$CALL_LOG" || grep -q "ntfs-3g" "$CALL_LOG"; then
    echo "FAIL: NTFS mount drivers invoked for ext4 filesystem!"
    cat "$CALL_LOG"
    exit 1
  fi
)
echo "  PASS: Non-NTFS partitions safely use generic mount without invoking NTFS drivers."

echo "=== All gen_chksum_for_files_in_dev tests PASSED ==="
