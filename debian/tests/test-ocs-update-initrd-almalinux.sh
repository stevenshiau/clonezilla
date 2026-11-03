#!/bin/bash
# Test script for ocs-update-initrd with AlmaLinux 10.2 Btrfs layout and NVMe storage.
# Tests that ocs-update-initrd discovers the AlmaLinux 10.2 Btrfs root subvolume (/root)
# and invokes dracut with -N (--no-hostonly) to ensure all storage drivers (e.g. nvme)
# are included in the generated initramfs.

set -e

echo "=== Running ocs-update-initrd AlmaLinux 10.2 Btrfs tests ==="

TEST_DIR="/tmp/test_ocs_update_initrd_almalinux"
rm -rf "$TEST_DIR"
mkdir -p "$TEST_DIR"

MOCK_NVME0N1P1="$TEST_DIR/nvme0n1p1"
MOCK_NVME0N1P2="$TEST_DIR/nvme0n1p2"
MOCK_NVME0N1P3="$TEST_DIR/nvme0n1p3"

setup_almalinux10() {
  rm -rf "$MOCK_NVME0N1P1" "$MOCK_NVME0N1P2" "$MOCK_NVME0N1P3"
  mkdir -p "$MOCK_NVME0N1P1/EFI/almalinux"
  touch "$MOCK_NVME0N1P1/EFI/almalinux/grub.cfg"

  # AlmaLinux 10.2 Btrfs layout in nvme0n1p3: subvolume /root
  local root_subvol="$MOCK_NVME0N1P3/root"
  mkdir -p "$root_subvol/boot"
  mkdir -p "$root_subvol/etc"
  mkdir -p "$root_subvol/usr/bin"
  mkdir -p "$root_subvol/bin"

  # Kernel and initramfs in /boot
  local kver="6.12.0-211.73.1.el10_2.x86_64_v2"
  touch "$root_subvol/boot/vmlinuz-$kver"
  touch "$root_subvol/boot/initramfs-$kver.img"

  # OS release
  cat <<'EOF' > "$root_subvol/etc/os-release"
NAME="AlmaLinux"
VERSION="10.2 (Seafoam Lion)"
ID="almalinux"
ID_LIKE="rhel centos fedora"
VERSION_ID="10.2"
PRETTY_NAME="AlmaLinux 10.2 (Seafoam Lion)"
EOF

  cat <<'EOF' > "$root_subvol/etc/fstab"
UUID=8a50c3b3-c7c4-48cc-b19a-1bb40be0ab13 / btrfs subvol=root,compress=zstd:1 0 0
UUID=FF76-216C /boot/efi vfat defaults 0 2
/dev/mapper/almalinux-home /home ext4 defaults 1 2
EOF

  # Mock dracut executable in /usr/bin/dracut
  cat <<'EOF' > "$root_subvol/usr/bin/dracut"
#!/bin/bash
echo "mock-dracut called with args: $*" >> /tmp/mock_dracut_execution.log
EOF
  chmod +x "$root_subvol/usr/bin/dracut"
}

run_test_scenario() {
  local test_name="$1"
  local cmd_args="$2"

  echo "--- Test Scenario: $test_name ---"
  rm -f /tmp/mock_dracut_execution.log /tmp/mock_ocs_update_initrd.log

  cat <<RUNNER_EOF > "$TEST_DIR/run_test.sh"
#!/bin/bash
set -e

# Mock mount
mount() {
  echo "mount \$*" >> /tmp/mock_ocs_update_initrd.log
  if [[ "\$1" == "--bind" ]]; then
    return 0
  fi
  local args=("\$@")
  local dest_pnt="\${args[-1]}"
  local src_dev="\${args[-2]}"
  mkdir -p "\$dest_pnt"
  if [[ "\$src_dev" == *nvme0n1p1 ]]; then
    cp -r "$MOCK_NVME0N1P1"/* "\$dest_pnt/" 2>/dev/null || true
  elif [[ "\$src_dev" == *nvme0n1p2 ]]; then
    cp -r "$MOCK_NVME0N1P2"/* "\$dest_pnt/" 2>/dev/null || true
  elif [[ "\$src_dev" == *nvme0n1p3 ]]; then
    cp -r "$MOCK_NVME0N1P3"/* "\$dest_pnt/" 2>/dev/null || true
  fi
}
export -f mount

unmount_wait_and_try() {
  echo "unmount_wait_and_try \$*" >> /tmp/mock_ocs_update_initrd.log
}
export -f unmount_wait_and_try

rmdir() {
  if [[ "\$1" == /tmp/root_reinst.* || "\$1" == /tmp/hd_* ]]; then
    rm -rf "\$1" 2>/dev/null || true
  else
    command rmdir "\$@" 2>/dev/null || true
  fi
}
export -f rmdir

chroot() {
  echo "chroot \$*" >> /tmp/mock_ocs_update_initrd.log
  local mnt="\$1"
  shift
  if [[ "\$1" == "ls" ]]; then
    [ -d "\$mnt" ] && return 0 || return 127
  elif [[ "\$1" == /initrd-sh-* ]]; then
    local sh_path="\$mnt/\$1"
    local dracut_line
    dracut_line="\$(grep -E "^dracut" "\$sh_path" 2>/dev/null)"
    echo "mock-dracut called with args: \$dracut_line" >> /tmp/mock_dracut_execution.log
    return 0
  else
    return 0
  fi
}
export -f chroot

ocs-get-dev-info() {
  local dev="\$1"
  if [[ "\$dev" == *nvme0n1p1 ]]; then
    echo "filesystem vfat"
  elif [[ "\$dev" == *nvme0n1p2 ]]; then
    echo "type lvm"
  elif [[ "\$dev" == *nvme0n1p3 ]]; then
    echo "filesystem btrfs"
  else
    echo "filesystem ext4"
  fi
}
export -f ocs-get-dev-info

bash /root/clonezilla/sbin/ocs-update-initrd $cmd_args
RUNNER_EOF

  chmod +x "$TEST_DIR/run_test.sh"
  set +e
  bash "$TEST_DIR/run_test.sh"
  local rc=$?
  set -e

  if [ "$rc" -ne 0 ]; then
    echo "FAIL: $test_name failed with exit code $rc"
    cat /tmp/mock_ocs_update_initrd.log 2>/dev/null || true
    return 1
  fi

  if ! grep -q "mock-dracut called with args:" /tmp/mock_dracut_execution.log 2>/dev/null; then
    echo "FAIL: dracut was not executed in $test_name!"
    cat /tmp/mock_ocs_update_initrd.log 2>/dev/null || true
    return 1
  fi

  # Verify -N option was passed to dracut
  if ! grep -q -- "dracut -N" /tmp/mock_dracut_execution.log 2>/dev/null; then
    echo "FAIL: dracut was not called with -N option in $test_name!"
    cat /tmp/mock_dracut_execution.log 2>/dev/null || true
    return 1
  fi

  echo "PASS: $test_name (dracut called with -N)"
  return 0
}

setup_almalinux10
run_test_scenario "AlmaLinux 10.2 Btrfs layout (auto discovery)" '-p "nvme0n1p1 nvme0n1p2 nvme0n1p3" auto'

run_test_scenario "AlmaLinux 10.2 Btrfs layout (explicit /dev/nvme0n1p3)" '/dev/nvme0n1p3'

rm -rf "$TEST_DIR" /tmp/mock_dracut_execution.log /tmp/mock_ocs_update_initrd.log

echo "=== All AlmaLinux 10.2 Btrfs tests passed successfully ==="
exit 0
