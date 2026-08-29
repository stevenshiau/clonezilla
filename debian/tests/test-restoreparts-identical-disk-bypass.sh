#!/bin/bash
# Standalone test for identical-disk bypass logic in create_temp_image_for_different_target_dev_name_if_necessary

set -e

echo "=== Running Identical Disk Bypass Logic Tests ==="

# Source ocs-functions helper
DRBL_SCRIPT_PATH="${DRBL_SCRIPT_PATH:-/usr/share/drbl}"
# Stub basic configurations so they don't fail if files don't exist
check_if_root() { :; }
export -f check_if_root
ask_and_load_lang_set() { :; }
export -f ask_and_load_lang_set

# Source ocs-functions from scripts/sbin
. scripts/sbin/ocs-functions

# Test Case 1: Restoring nvme0n1p3 when image is from nvme0n1 (identical disk)
# Should return 3 (do nothing, skip conversion)
target_hd=""
target_parts="nvme0n1p3"
dsksname_from_img="nvme0n1"
source_part=""
BOOTUP=""
ocs_batch_mode="on"

echo "Running Test Case 1: Restoring nvme0n1p3 from nvme0n1 image..."
ret1=0
create_temp_image_for_different_target_dev_name_if_necessary || ret1=$?

if [ "$ret1" -eq 3 ]; then
  echo "PASS: Correctly bypassed conversion (returned 3) for identical base disks."
else
  echo "FAIL: Expected return code 3, got $ret1"
  exit 1
fi

# Test Case 2: Restoring nvme0n1p3 when image is from nvme0n2 (different disks)
# Should try to convert and NOT return 3
# To prevent the function from actually trying to run ocs-create-tmp-img,
# we can mock ocs-create-tmp-img by stubbing it.
# Let's create a temporary mock bin directory in PATH.
MOCK_BIN="/tmp/mock-bypass-bin"
rm -rf "$MOCK_BIN"
mkdir -p "$MOCK_BIN"
cat <<'EOF' > "$MOCK_BIN/ocs-create-tmp-img"
#!/bin/bash
echo "Mock ocs-create-tmp-img called"
exit 0
EOF
chmod +x "$MOCK_BIN/ocs-create-tmp-img"

export ORIGINAL_PATH="$PATH"
export PATH="$MOCK_BIN:$PATH"

target_hd=""
target_parts="nvme0n1p3"
dsksname_from_img="nvme0n2"
source_part=""
ocsroot="/tmp"
target_dir="mock-img"

echo "Running Test Case 2: Restoring nvme0n1p3 from nvme0n2 image..."
ret2=0
create_temp_image_for_different_target_dev_name_if_necessary || ret2=$?

export PATH="$ORIGINAL_PATH"
rm -rf "$MOCK_BIN"

if [ "$ret2" -ne 3 ]; then
  echo "PASS: Correctly attempted conversion (did not return 3) for different base disks."
else
  echo "FAIL: Expected conversion attempt (non-3 return code), but got $ret2"
  exit 1
fi

# Test Case 3: Restoring partition with identical source_part and target_parts
# But they may have formatting/whitespace differences, e.g. source_part="sda3", target_parts="sda3 "
# Should return 3 (bypass conversion because partitions are identical)
target_hd=""
target_parts="sda3 "
dsksname_from_img="sda"
source_part="sda3"
BOOTUP=""
ocs_batch_mode="on"

echo "Running Test Case 3: Restoring sda3 from sda3 (with trailing space)..."
ret3=0
create_temp_image_for_different_target_dev_name_if_necessary || ret3=$?

if [ "$ret3" -eq 3 ]; then
  echo "PASS: Correctly bypassed conversion (returned 3) for identical partition and target_parts."
else
  echo "FAIL: Expected return code 3, got $ret3"
  exit 1
fi

echo "=== All Identical Disk Bypass Logic Tests Passed Successfully! ==="
exit 0
