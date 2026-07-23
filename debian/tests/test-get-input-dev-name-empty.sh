#!/bin/bash
# Standalone test for get_input_dev_name empty and fallback logic in scripts/sbin/ocs-functions

set -e

echo "=== Running get_input_dev_name Empty and Fallback Tests ==="

# Load scripts/sbin/ocs-functions first so we can override its functions later
. scripts/sbin/ocs-functions

# Mock environment and required variables
export BOOTUP="color"
export SETCOLOR_WARNING="echo -n"
export SETCOLOR_FAILURE="echo -n"
export SETCOLOR_NORMAL="echo -n"
export msg_error="Error"
export msg_not_mounted_dev_found="No unmounted device found"
export msg_press_enter_to_exit="Press enter to exit"
export msg_no_partition_table_need_to_create="No partition table was found"
export msg_enter_another_shell_for_fdisk="Enter another shell for fdisk"
export msg_press_enter_to_continue="..."
export ocs_sr_type="restoreparts"

# Mock 'read' globally first so nothing blocks
read() {
  echo "Mock read called"
}

# Mock ocs-functions variables / functions we depend on
get_not_busy_disks_or_parts() {
  # Mock to return empty list of unmounted partitions
  dev_list=""
}

is_supported_dev() {
  return 0
}

is_partition() {
  return 0
}

# Mock /bin/bash globally using PATH
mkdir -p /tmp/mock-bin
cat <<'EOF' > /tmp/mock-bin/bash
#!/bin/sh
echo "Mock bash executed"
exit 0
EOF
chmod +x /tmp/mock-bin/bash

export ORIGINAL_PATH="$PATH"
export PATH="/tmp/mock-bin:$PATH"

# TEST 1: When partition list is empty (blank target disk)
# get_part_list should return empty, so the fallback /bin/bash partitioning block should be triggered.
# We redirect stdin from /dev/null so that any "read" command returns immediately.
get_part_list() {
  echo ""
}

ANS_TMP=$(mktemp /tmp/ans-mock.XXXXXX)

echo "Testing get_input_dev_name with empty partition list (should trigger fallback bash and exit 1)..."
# We run get_input_dev_name in a subshell because it exits on failure
if ( get_input_dev_name "$ANS_TMP" partition menu yes "prompt" < /dev/null ) 2>/dev/null; then
  echo "FAIL: Expected get_input_dev_name to exit with error, but it succeeded!"
  exit 1
else
  echo "PASS: get_input_dev_name exited with error as expected."
fi

# TEST 2: When partition list is not empty (but target partitions are all busy/unusable)
# get_part_list returns something, so it should NOT trigger fdisk bash fallback, and exit with error.
get_part_list() {
  echo "sda1"
}

echo "Testing get_input_dev_name with non-empty partition list (should NOT trigger fdisk bash fallback)..."
if ( get_input_dev_name "$ANS_TMP" partition menu yes "prompt" < /dev/null ) 2>/dev/null; then
  echo "FAIL: Expected get_input_dev_name to exit with error because NUMDEV is 0, but it succeeded!"
  exit 1
else
  echo "PASS: get_input_dev_name exited with error as expected."
fi

# Clean up
export PATH="$ORIGINAL_PATH"
rm -rf /tmp/mock-bin
rm -f "$ANS_TMP"

echo "All tests passed successfully!"
exit 0
