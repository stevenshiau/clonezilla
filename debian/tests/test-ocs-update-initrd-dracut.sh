#!/bin/bash
# Standalone test for ocs-update-initrd / do_run_update_initrd_from_restored_os dracut path logic.
# Note: This test mocks the restored OS root partition filesystem (where the dracut binary resides),
# NOT the inside of the initrd file itself. Modern initrd images (like Fedora 44) do not contain
# the dracut builder tool itself, but the restored OS filesystem does.

set -e

echo "=== Running ocs-update-initrd dracut detection tests ==="

# We need to mock a restored OS root partition structure and the mount, chroot commands.
# Let's define the paths
export MOCK_MOUNT_PNT="/tmp/mock_restored_os_mount"
export MOCK_ROOT_DIR="/tmp/mock_restored_os_root"

rm -rf "$MOCK_MOUNT_PNT" "$MOCK_ROOT_DIR"
mkdir -p "$MOCK_MOUNT_PNT"
mkdir -p "$MOCK_ROOT_DIR"

# Clean up previous logs if any
rm -f /tmp/mock_restored_os_test_log

# Mock the mount command
mount() {
  echo "Mock mount called: $*" >> /tmp/mock_restored_os_test_log
  if [[ "$1" == "--bind" ]]; then
    # Do nothing for bind mounts in test
    return 0
  fi
  
  # When mounting the root partition: $1 is device (e.g., /dev/mocksda2), $2 is $mnt_pnt
  local src_dev="$1"
  local dest_pnt="$2"
  
  if [[ "$dest_pnt" == */boot/ || "$dest_pnt" == */boot ]]; then
    # When mounting boot, copy contents of mock boot directory
    mkdir -p "$dest_pnt"
    cp -r "$MOCK_ROOT_DIR"/boot/* "$dest_pnt/" 2>/dev/null || true
  else
    # Copy files from our mock restored OS root to the temp mount point
    cp -r "$MOCK_ROOT_DIR"/* "$dest_pnt/"
  fi
}
export -f mount

# Mock unmount_wait_and_try
unmount_wait_and_try() {
  echo "Mock unmount_wait_and_try called: $*" >> /tmp/mock_restored_os_test_log
}
export -f unmount_wait_and_try

# Mock chroot
chroot() {
  echo "Mock chroot called: $*" >> /tmp/mock_restored_os_test_log
  local mnt="$1"
  shift
  if [[ "$1" == "ls" ]]; then
    if [ -d "$mnt" ]; then
      return 0
    else
      return 127
    fi
  elif [[ "$1" == "mount" ]]; then
    return 0
  elif [[ "$1" == "umount" ]]; then
    return 0
  elif [[ "$1" == "sh" && "$2" == "-c" ]]; then
    local cmd_expr="$3"
    cmd_expr="${cmd_expr// \/usr\/bin/ $mnt/usr/bin}"
    cmd_expr="${cmd_expr// \/usr\/sbin/ $mnt/usr/sbin}"
    cmd_expr="${cmd_expr// \/sbin/ $mnt/sbin}"
    sh -c "$cmd_expr"
    return $?
  elif [[ "$1" == /initrd-sh-* ]]; then
    echo "Mock running initrd script: $1" >> /tmp/mock_restored_os_test_log
    cat "$mnt/$1" >> /tmp/mock_restored_os_test_log
    return 0
  else
    # default fallback
    "$@"
  fi
}
export -f chroot

# Mock rmdir to cleanly remove mock directories
rmdir() {
  if [[ "$1" == /tmp/root_reinst.* ]]; then
    rm -rf "$1"
  else
    command rmdir "$@"
  fi
}
export -f rmdir

# Mock other functions
copy_error_log() {
  echo "Mock copy_error_log called" >> /tmp/mock_restored_os_test_log
}
export -f copy_error_log

# Load functions
. scripts/sbin/ocs-functions

# Helper to setup a base layout
setup_base_layout() {
  local extra_path="$1" # e.g. "" or "/root"
  local dracut_bin_dir="$2" # e.g. "usr/sbin" or "usr/bin" or "sbin"
  
  rm -rf "$MOCK_ROOT_DIR"
  mkdir -p "$MOCK_ROOT_DIR"
  
  local target_root="$MOCK_ROOT_DIR"
  if [ -n "$extra_path" ]; then
    target_root="$MOCK_ROOT_DIR/$extra_path"
  fi
  
  mkdir -p "$target_root/$dracut_bin_dir"
  mkdir -p "$target_root/boot"
  
  # Create a mock kernel file in boot
  touch "$target_root/boot/vmlinuz-7.1.13-200.fc44.x86_64"
  # Create a mock initramfs file in boot
  touch "$target_root/boot/initramfs-7.1.13-200.fc44.x86_64.img"
  
  # Create a mock dracut script
  local dracut_path="$target_root/$dracut_bin_dir/dracut"
  cat <<'EOF' > "$dracut_path"
#!/bin/bash
# Mock dracut containing string --tmpdir
echo "mock-dracut-output --tmpdir"
EOF
  chmod +x "$dracut_path"
}

# Case 1: dracut in /usr/sbin/dracut (Fedora 44 / CentOS >= 7 style)
setup_base_layout "" "usr/sbin"
echo "--- Running Case 1: dracut in /usr/sbin/dracut ---"
set +e
do_run_update_initrd_from_restored_os "/dev/mocksda1" "/dev/mocksda2"
rc_case1=$?
set -e

# Case 2: dracut in /usr/bin/dracut
setup_base_layout "" "usr/bin"
echo "--- Running Case 2: dracut in /usr/bin/dracut ---"
set +e
do_run_update_initrd_from_restored_os "/dev/mocksda1" "/dev/mocksda2"
rc_case2=$?
set -e

# Case 3: dracut in /sbin/dracut (CentOS 6 style)
setup_base_layout "" "sbin"
echo "--- Running Case 3: dracut in /sbin/dracut ---"
set +e
do_run_update_initrd_from_restored_os "/dev/mocksda1" "/dev/mocksda2"
rc_case3=$?
set -e

# Clean up
rm -rf "$MOCK_MOUNT_PNT" "$MOCK_ROOT_DIR"
rm -rf /tmp/root_reinst.*

echo "=== Test Results Summary ==="
echo "Case 1 (/usr/sbin/dracut): Exit code $rc_case1"
echo "Case 2 (/usr/bin/dracut): Exit code $rc_case2"
echo "Case 3 (/sbin/dracut): Exit code $rc_case3"

# Verify correctness
# Before the fix: Case 1 should FAIL (exit code 1), Case 2 and 3 should PASS (exit code 0).
# After the fix: Case 1, 2, and 3 should ALL PASS (exit code 0).

if [ "$rc_case2" -ne 0 ] || [ "$rc_case3" -ne 0 ]; then
  echo "FAIL: Case 2 or Case 3 failed!"
  exit 1
fi

if [ "$rc_case1" -ne 0 ]; then
  echo "Case 1 failed as expected under old code (or if fix is missing)."
  # In our final test suite, we want ALL cases to pass.
  # So if this is running as part of validation, we want Case 1 to pass!
  # We will fail here if Case 1 is not fixed yet.
  exit 1
else
  echo "PASS: Case 1 (/usr/sbin/dracut) passed!"
fi

# Verify that dracut was called with -N (--no-hostonly)
if ! grep -q -- "dracut -N" /tmp/mock_restored_os_test_log; then
  echo "FAIL: dracut was not called with -N (--no-hostonly) option!"
  exit 1
else
  echo "PASS: Verified dracut invoked with -N option."
fi

echo "=== All Tests Passed Successfully ==="
exit 0
