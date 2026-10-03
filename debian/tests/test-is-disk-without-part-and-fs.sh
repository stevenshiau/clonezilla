#!/bin/bash
# Standalone unit test for is_disk_without_part_and_fs() in scripts/sbin/ocs-functions

set -e

echo "=== Running is_disk_without_part_and_fs Unit Tests ==="

# Source ocs-functions
. scripts/sbin/ocs-functions

TMP_DIR="$(mktemp -d /tmp/test-ocs-disk-XXXXXX)"
trap 'rm -rf "$TMP_DIR"' EXIT

# Create a mock bin directory in PATH
MOCK_BIN="$TMP_DIR/bin"
mkdir -p "$MOCK_BIN"
export ORIGINAL_PATH="$PATH"
export PATH="$MOCK_BIN:$PATH"

CALL_STATE="$TMP_DIR/call_state"

# Test 1: Variable scoping test - verify part_no does not leak into caller scope
echo "Testing variable scope isolation for part_no..."
part_no="initial_sentinel_value"
rc_test=0

# Create mock lsblk that outputs disk and part
cat <<'EOF' > "$MOCK_BIN/lsblk"
#!/bin/bash
echo "disk"
echo "part"
EOF
chmod +x "$MOCK_BIN/lsblk"

is_disk_without_part_and_fs /dev/sda || rc_test=$?

if [ "$part_no" != "initial_sentinel_value" ]; then
  echo "FAIL: part_no leaked into caller scope! Value was: '$part_no'"
  exit 1
fi
echo "PASS: part_no remains '$part_no' and did not leak into caller scope."

# Test 2: Disk with partitions (is_disk_without_part_and_fs should return 1)
echo "Testing disk with partition..."
test2_rc=0
is_disk_without_part_and_fs /dev/sda || test2_rc=$?
if [ "$test2_rc" -eq 1 ]; then
  echo "PASS: Correctly reported that disk with partition is not empty (rc=$test2_rc)."
else
  echo "FAIL: Expected return code 1, got $test2_rc"
  exit 1
fi

# Test 3: Disk genuinely without partitions and without fs (should return 0)
echo "Testing empty disk without partitions or filesystem..."
cat <<'EOF' > "$MOCK_BIN/lsblk"
#!/bin/bash
echo "disk"
EOF
cat <<'EOF' > "$MOCK_BIN/partprobe"
#!/bin/bash
echo "partprobe $*" >> "$CALL_STATE_FILE"
EOF
cat <<'EOF' > "$MOCK_BIN/udevadm"
#!/bin/bash
echo "udevadm $*" >> "$CALL_STATE_FILE"
EOF
chmod +x "$MOCK_BIN/partprobe" "$MOCK_BIN/udevadm"
export CALL_STATE_FILE="$CALL_STATE"
: > "$CALL_STATE"

# Stub is_whole_disk and is_block_device_with_fs for mock isolation
is_whole_disk() { return 0; }
is_block_device_with_fs() { return 1; }

test3_rc=0
is_disk_without_part_and_fs /dev/sdb || test3_rc=$?

if [ "$test3_rc" -eq 0 ]; then
  echo "PASS: Correctly identified disk without partition and fs (rc=0)."
else
  echo "FAIL: Expected return code 0, got $test3_rc"
  exit 1
fi

# Verify partprobe and udevadm were called
if grep -q "partprobe /dev/sdb" "$CALL_STATE" && grep -q "udevadm settle --timeout=5" "$CALL_STATE"; then
  echo "PASS: partprobe and udevadm settle were called on zero partition count."
else
  echo "FAIL: partprobe or udevadm settle was not called as expected. Calls recorded:"
  cat "$CALL_STATE"
  exit 1
fi

# Test 4: Race condition recovery - lsblk reports 0 on first call, 1 part on retry
echo "Testing race condition retry logic..."
: > "$CALL_STATE"
export COUNT_FILE="$TMP_DIR/lsblk_count"
echo 0 > "$COUNT_FILE"

cat <<'EOF' > "$MOCK_BIN/lsblk"
#!/bin/bash
read -r c < "$COUNT_FILE"
c=$((c + 1))
echo "$c" > "$COUNT_FILE"
if [ "$c" -eq 1 ]; then
  echo "disk"
else
  echo "disk"
  echo "part"
fi
EOF

test4_rc=0
is_disk_without_part_and_fs /dev/nbd0 || test4_rc=$?

if [ "$test4_rc" -eq 1 ]; then
  echo "PASS: Race resolved on retry - disk correctly recognized as having partition (rc=1)."
else
  echo "FAIL: Expected return code 1 after retry, got $test4_rc"
  exit 1
fi

if grep -q "partprobe /dev/nbd0" "$CALL_STATE" && grep -q "udevadm settle --timeout=5" "$CALL_STATE"; then
  echo "PASS: Retry triggered partprobe and udevadm settle."
else
  echo "FAIL: Retry did not trigger partprobe and udevadm settle properly."
  exit 1
fi

echo "=== All is_disk_without_part_and_fs Unit Tests Passed Successfully! ==="
