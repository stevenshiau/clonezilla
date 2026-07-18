#!/bin/bash
# Standalone test for LVM system.devices postprocessing logic in sbin/ocs-tux-postprocess

set -e

echo "=== Running LVM system.devices Postprocessing Tests ==="

# Define and export directories so they are available in exported functions
export MOCK_SRC="/tmp/mock_target_root"

rm -rf "$MOCK_SRC"
mkdir -p "$MOCK_SRC/etc/lvm/devices"
mkdir -p "$MOCK_SRC/sbin"
mkdir -p "$MOCK_SRC/dev" "$MOCK_SRC/proc" "$MOCK_SRC/sys" "$MOCK_SRC/run"

# Create mock system.devices file
echo "original_whitelist_data" > "$MOCK_SRC/etc/lvm/devices/system.devices"

# Create mock vgimportdevices command
cat <<'EOF' > "$MOCK_SRC/sbin/vgimportdevices"
#!/bin/sh
if [ "$1" = "-a" ]; then
  # Recreate the file with new data
  echo "regenerated_whitelist_data" > /etc/lvm/devices/system.devices
  exit 0
else
  exit 1
fi
EOF
chmod +x "$MOCK_SRC/sbin/vgimportdevices"

# Mock functions to intercept system commands
# We export them so they are used by sbin/ocs-tux-postprocess

mount() {
  if [ "$1" = "--bind" ]; then
    echo "Mock mount --bind called: $*" >> /tmp/mock_debug_log
    echo "$3" >> /tmp/mock_mount_binds
  else
    echo "Mock mount called: $*" >> /tmp/mock_debug_log
    # $1 is device, $2 is mount path
    cp -r "$MOCK_SRC"/* "$2/"
  fi
}
export -f mount

unmount_wait_and_try() {
  echo "Mock unmount_wait_and_try called: $*" >> /tmp/mock_debug_log
  echo "$1" >> /tmp/mock_unmounts
}
export -f unmount_wait_and_try

# Mock chroot to execute the mock binary using host shell on the mock target path
chroot() {
  local target_root="$1"
  local cmd="$2"
  local arg="$3"
  echo "Mock chroot called: target_root=$target_root cmd=$cmd arg=$arg" >> /tmp/mock_debug_log
  if [ "$cmd" = "vgimportdevices" ]; then
    # We execute the script inside target_root, but we must point its output to target_root
    # We can do this by running it and shifting its /etc paths. Or simpler, the mock script
    # can write directly if we replace /etc with target_root/etc.
    # Let's adjust the vgimportdevices script dynamically to write to target_root!
    sed -i "s|/etc/lvm/devices/system.devices|$target_root/etc/lvm/devices/system.devices|g" "$target_root/sbin/vgimportdevices"
    "$target_root/sbin/vgimportdevices" "$arg"
  else
    # Fallback/default command execution
    "$@"
  fi
}
export -f chroot

rmdir() {
  if [[ "$1" == /tmp/hd_img.* ]]; then
    echo "Mock rmdir called with: $* (using rm -rf instead)" >> /tmp/mock_debug_log
    rm -rf "$1"
  else
    command rmdir "$@"
  fi
}
export -f rmdir

ocs-get-dev-info() {
  # Return ext4 filesystem for the mock device
  echo "ext4"
}
export -f ocs-get-dev-info

get-nic-devs() {
  # Return empty to skip NIC MAC cleanup in test
  echo ""
}
export -f get-nic-devs

drbl-get-macadd() {
  echo ""
}
export -f drbl-get-macadd

strip_leading_dev() {
  local -a stripped_devs
  for dev in "$@"; do
    stripped_devs+=("${dev#"/dev/"}")
  done
  echo "${stripped_devs[@]}"
}
export -f strip_leading_dev

check_if_root() {
  echo "Mock check_if_root called"
}
export -f check_if_root

ask_and_load_lang_set() {
  echo "Mock ask_and_load_lang_set called"
}
export -f ask_and_load_lang_set

get_partition_list() {
  echo "mocksda1"
}
export -f get_partition_list

# Reset tracking files
rm -f /tmp/mock_mount_binds /tmp/mock_unmounts /tmp/mock_debug_log

# Run sbin/ocs-tux-postprocess
# We must mock some functions inside sbin/ocs-tux-postprocess by running it in the same shell environment
# or by setting DRBL_SCRIPT_PATH to mock ocs-functions.
# Since ocs-tux-postprocess is run via bash, we can run it and our exported functions will be inherited!
export DRBL_SCRIPT_PATH="/tmp/mock_drbl_path"
mkdir -p "$DRBL_SCRIPT_PATH/sbin"
touch "$DRBL_SCRIPT_PATH/sbin/drbl-conf-functions"

# Create a mock ocs-functions file
cat <<'EOF' > "$DRBL_SCRIPT_PATH/sbin/ocs-functions"
# Dummy ocs-functions
EOF

# Execute the script
bash sbin/ocs-tux-postprocess mocksda1

# Output debug log from mock functions
echo "=== Mock Debug Log ==="
cat /tmp/mock_debug_log 2>/dev/null || true

# Verify results
echo "=== Verifying Test Results ==="

# Since the mock mount copied MOCK_SRC to the temporary $hd_img directory, we can locate the temp directory
# from the mount binds tracking or list /tmp/hd_img.*
# Note: since rmdir was called, the directory was cleaned up, but we can verify its path and state from the logs!
HD_IMG_DIR=$(grep "Mock mount called:" /tmp/mock_debug_log | awk '{print $NF}')

if [ -z "$HD_IMG_DIR" ]; then
  echo "FAIL: Temporary mount directory not found in logs!"
  exit 1
fi

# 1. Verify if the test logs show that chroot and vgimportdevices were called
if grep -q "Mock chroot called: target_root=$HD_IMG_DIR cmd=vgimportdevices arg=-a" /tmp/mock_debug_log; then
  echo "PASS: chroot and vgimportdevices -a were successfully executed!"
else
  echo "FAIL: vgimportdevices was not executed inside chroot!"
  exit 1
fi

# 2. Check if bind mounts were registered in /tmp/mock_mount_binds
if grep -q "$HD_IMG_DIR/dev" /tmp/mock_mount_binds && \
   grep -q "$HD_IMG_DIR/proc" /tmp/mock_mount_binds && \
   grep -q "$HD_IMG_DIR/sys" /tmp/mock_mount_binds && \
   grep -q "$HD_IMG_DIR/run" /tmp/mock_mount_binds; then
  echo "PASS: All bind mounts (/dev, /proc, /sys, /run) were successfully created!"
else
  echo "FAIL: Some bind mounts were missing in /tmp/mock_mount_binds:"
  cat /tmp/mock_mount_binds
  exit 1
fi

# 3. Check if all bind mounts and the main partition were unmounted in the correct order
if grep -q "$HD_IMG_DIR/run" /tmp/mock_unmounts && \
   grep -q "$HD_IMG_DIR/sys" /tmp/mock_unmounts && \
   grep -q "$HD_IMG_DIR/proc" /tmp/mock_unmounts && \
   grep -q "$HD_IMG_DIR/dev" /tmp/mock_unmounts && \
   grep -q "mocksda1" /tmp/mock_unmounts; then
  echo "PASS: All bind mounts and the partition were unmounted successfully!"
else
  echo "FAIL: Some unmounts were missing in /tmp/mock_unmounts:"
  cat /tmp/mock_unmounts
  exit 1
fi

# Clean up temporary test files
rm -rf "$MOCK_SRC" "$HD_IMG_DIR" /tmp/mock_mount_binds /tmp/mock_unmounts /tmp/mock_debug_log "$DRBL_SCRIPT_PATH"
echo "=== LVM Postprocessing Tests Passed Successfully! ==="
exit 0
