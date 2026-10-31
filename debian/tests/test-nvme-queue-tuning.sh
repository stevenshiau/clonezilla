#!/bin/bash
# Standalone test for NVMe block queue tuning (readahead and scheduler) in Clonezilla

set -e

echo "=== Running NVMe Block Queue Tuning Tests ==="

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
export DRBL_SCRIPT_PATH="/usr/share/drbl"
. "$SCRIPT_DIR/scripts/sbin/ocs-functions"

# -------------------------------------------------------------
# Test 1: Single NVMe device and partition tuning
# -------------------------------------------------------------
echo "[Test 1] Testing queue tuning on single NVMe disk and partition..."
(
  TEST_DIR=$(mktemp -d)
  trap 'rm -rf "$TEST_DIR"' EXIT

  MOCK_BIN="$TEST_DIR/bin"
  mkdir -p "$MOCK_BIN"
  export PATH="$MOCK_BIN:$PATH"

  CALL_LOG="$TEST_DIR/calls.log"
  touch "$CALL_LOG"

  # Mock blockdev
  cat <<EOF > "$MOCK_BIN/blockdev"
#!/bin/bash
echo "blockdev \$*" >> "$CALL_LOG"
exit 0
EOF
  chmod +x "$MOCK_BIN/blockdev"

  check_if_nvme_ssd() {
    case "$1" in
      *nvme*) return 0 ;;
      *)      return 1 ;;
    esac
  }
  export -f check_if_nvme_ssd

  tune_nvme_block_queue_settings "/dev/nvme0n1p2"

  if ! grep -q "blockdev --setra 8192 /dev/nvme0n1" "$CALL_LOG"; then
    echo "FAIL: Expected 'blockdev --setra 8192 /dev/nvme0n1' in log, got:"
    cat "$CALL_LOG"
    exit 1
  fi
  echo "  PASS: Readahead set to 8192 (4MB) for base disk /dev/nvme0n1."
)

# -------------------------------------------------------------
# Test 2: Non-NVMe disk is ignored
# -------------------------------------------------------------
echo "[Test 2] Testing that non-NVMe devices are not modified..."
(
  TEST_DIR=$(mktemp -d)
  trap 'rm -rf "$TEST_DIR"' EXIT

  MOCK_BIN="$TEST_DIR/bin"
  mkdir -p "$MOCK_BIN"
  export PATH="$MOCK_BIN:$PATH"

  CALL_LOG="$TEST_DIR/calls.log"
  touch "$CALL_LOG"

  cat <<EOF > "$MOCK_BIN/blockdev"
#!/bin/bash
echo "blockdev \$*" >> "$CALL_LOG"
exit 0
EOF
  chmod +x "$MOCK_BIN/blockdev"

  cat <<EOF > "$MOCK_BIN/lsblk"
#!/bin/bash
echo "1"
exit 0
EOF
  chmod +x "$MOCK_BIN/lsblk"

  SYS_DIR="$TEST_DIR/sys/block/sda/queue"
  mkdir -p "$SYS_DIR"
  echo "mq-deadline [bfq] none" > "$SYS_DIR/scheduler"

  MOCK_DEV="$TEST_DIR/dev"
  mkdir -p "$MOCK_DEV"
  mknod "$MOCK_DEV/sda" b 1 1
  mknod "$MOCK_DEV/sda1" b 1 1

  tune_nvme_block_queue_settings "/dev/sda1"

  if [ -s "$CALL_LOG" ]; then
    echo "FAIL: blockdev was called on non-NVMe disk:"
    cat "$CALL_LOG"
    exit 1
  fi
  echo "  PASS: Non-NVMe disk correctly skipped without changes."
)

# -------------------------------------------------------------
# Test 3: Multiple devices and partition format handling
# -------------------------------------------------------------
echo "[Test 3] Testing multiple devices and bare name handling..."
(
  TEST_DIR=$(mktemp -d)
  trap 'rm -rf "$TEST_DIR"' EXIT

  MOCK_BIN="$TEST_DIR/bin"
  mkdir -p "$MOCK_BIN"
  export PATH="$MOCK_BIN:$PATH"

  CALL_LOG="$TEST_DIR/calls.log"
  touch "$CALL_LOG"

  cat <<EOF > "$MOCK_BIN/blockdev"
#!/bin/bash
echo "blockdev \$*" >> "$CALL_LOG"
exit 0
EOF
  chmod +x "$MOCK_BIN/blockdev"

  # Override check_if_nvme_ssd to accept nvme devices
  check_if_nvme_ssd() {
    case "$1" in
      *nvme*) return 0 ;;
      *)      return 1 ;;
    esac
  }
  export -f check_if_nvme_ssd

  tune_nvme_block_queue_settings "nvme0n1p1" "/dev/nvme1n1p2" "sda1"

  if ! grep -q "blockdev --setra 8192 /dev/nvme0n1" "$CALL_LOG"; then
    echo "FAIL: Missing blockdev call for nvme0n1"
    exit 1
  fi

  if ! grep -q "blockdev --setra 8192 /dev/nvme1n1" "$CALL_LOG"; then
    echo "FAIL: Missing blockdev call for nvme1n1"
    exit 1
  fi

  if grep -q "sda" "$CALL_LOG"; then
    echo "FAIL: Unexpected call for sda"
    exit 1
  fi
  echo "  PASS: Multiple NVMe devices tuned and non-NVMe devices filtered out."
)

# -------------------------------------------------------------
# Test 4: Integration with get_partclone_direct_io_opt
# -------------------------------------------------------------
echo "[Test 4] Testing automatic tuning in get_partclone_direct_io_opt..."
(
  TEST_DIR=$(mktemp -d)
  trap 'rm -rf "$TEST_DIR"' EXIT

  MOCK_BIN="$TEST_DIR/bin"
  mkdir -p "$MOCK_BIN"
  export PATH="$MOCK_BIN:$PATH"

  CALL_LOG="$TEST_DIR/calls.log"
  touch "$CALL_LOG"

  cat <<EOF > "$MOCK_BIN/blockdev"
#!/bin/bash
echo "blockdev \$*" >> "$CALL_LOG"
exit 0
EOF
  chmod +x "$MOCK_BIN/blockdev"

  check_if_nvme_ssd() {
    case "$1" in
      *nvme*) return 0 ;;
      *)      return 1 ;;
    esac
  }
  export -f check_if_nvme_ssd

  enable_dio="no"
  get_partclone_direct_io_opt read "/dev/nvme0n1p1"

  if ! grep -q "blockdev --setra 8192 /dev/nvme0n1" "$CALL_LOG"; then
    echo "FAIL: get_partclone_direct_io_opt did not tune queue settings when enable_dio=no"
    exit 1
  fi
  echo "  PASS: Queue settings tuned automatically before partclone transfers."
)

echo "=== All NVMe Block Queue Tuning Tests Passed! ==="
