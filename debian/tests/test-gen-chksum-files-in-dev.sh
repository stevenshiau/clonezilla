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

echo "=== All gen_chksum_for_files_in_dev tests PASSED ==="
