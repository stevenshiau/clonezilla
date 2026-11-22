#!/bin/bash
# Test script for ocs-update-initrd with separate /boot partition and MDRAID root device (/dev/md127).
# Reproduces the scenario from log-update-initrd.txt:
#   - nvme0n2p1: EFI system partition
#   - nvme0n2p2: separate /boot partition (xfs) containing grub2 and kernels (vmlinuz-*, initramfs-*)
#   - md127: MDRAID root filesystem (xfs) containing /boot mountpoint, /etc/os-release, /etc/fstab, dracut
# Verifies that ocs-update-initrd correctly identifies /dev/nvme0n2p2 as the boot partition,
# recognizes that /dev/nvme0n2p2 is a separate /boot partition (not the root partition),
# discovers /dev/md127 as the root filesystem, mounts /dev/nvme0n2p2 on /boot inside the root filesystem,
# and successfully generates the initramfs using dracut with -N.

set -e

echo "=== Running ocs-update-initrd MDRAID root with separate /boot tests ==="

export TEST_DIR="/tmp/test_ocs_update_initrd_mdraid"
rm -rf "$TEST_DIR"
mkdir -p "$TEST_DIR"

MOCK_NVME0N2P1="$TEST_DIR/nvme0n2p1"
MOCK_NVME0N2P2="$TEST_DIR/nvme0n2p2"
MOCK_MD127="$TEST_DIR/md127"

setup_mock_devices() {
  rm -rf "$MOCK_NVME0N2P1" "$MOCK_NVME0N2P2" "$MOCK_MD127"
  mkdir -p "$MOCK_NVME0N2P1/EFI/redhat"

  # Separate /boot partition in nvme0n2p2
  mkdir -p "$MOCK_NVME0N2P2/grub2"
  touch "$MOCK_NVME0N2P2/grub2/grub.cfg"
  local kver="6.12.0-124.40.1.el10_1.x86_64"
  touch "$MOCK_NVME0N2P2/vmlinuz-$kver"
  touch "$MOCK_NVME0N2P2/initramfs-$kver.img"

  # MDRAID root filesystem in md127
  mkdir -p "$MOCK_MD127/boot"
  mkdir -p "$MOCK_MD127/etc"
  mkdir -p "$MOCK_MD127/usr/bin"
  mkdir -p "$MOCK_MD127/bin"

  cat <<'EOF' > "$MOCK_MD127/etc/os-release"
NAME="Red Hat Enterprise Linux"
VERSION="10.0 (Coughlan)"
ID="rhel"
VERSION_ID="10.0"
PRETTY_NAME="Red Hat Enterprise Linux 10.0"
EOF

  cat <<'EOF' > "$MOCK_MD127/etc/fstab"
/dev/md127 / xfs defaults 0 0
/dev/nvme0n2p2 /boot xfs defaults 0 0
/dev/nvme0n2p1 /boot/efi vfat defaults 0 0
EOF

  cat <<'EOF' > "$MOCK_MD127/usr/bin/dracut"
#!/bin/bash
echo "mock-dracut called with args: $*" >> /tmp/mock_dracut_execution.log
EOF
  chmod +x "$MOCK_MD127/usr/bin/dracut"
}

run_test_scenario() {
  local test_name="$1"
  local cmd_args="$2"

  echo "--- Test Scenario: $test_name ---"
  rm -f /tmp/mock_dracut_execution.log /tmp/mock_ocs_update_initrd.log

  cat <<RUNNER_EOF > "$TEST_DIR/run_test.sh"
#!/bin/bash
set -e

mount() {
  echo "mount \$*" >> /tmp/mock_ocs_update_initrd.log
  if [[ "\$1" == "--bind" ]]; then
    return 0
  fi
  local args=("\$@")
  local dest_pnt="\${args[-1]}"
  local src_dev="\${args[-2]}"
  mkdir -p "\$dest_pnt"
  if [[ "\$src_dev" == *nvme0n2p1 ]]; then
    cp -r "$MOCK_NVME0N2P1"/* "\$dest_pnt/" 2>/dev/null || true
  elif [[ "\$src_dev" == *nvme0n2p2 ]]; then
    cp -r "$MOCK_NVME0N2P2"/* "\$dest_pnt/" 2>/dev/null || true
  elif [[ "\$src_dev" == *md127 ]]; then
    cp -r "$MOCK_MD127"/* "\$dest_pnt/" 2>/dev/null || true
  fi
}
export -f mount

unmount_wait_and_try() {
  echo "unmount_wait_and_try \$*" >> /tmp/mock_ocs_update_initrd.log
  if [[ -d "\$1" && "\$1" == /tmp/* ]]; then
    rm -rf "\$1"/* 2>/dev/null || true
  fi
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
    # Must have root filesystem (e.g. /etc/os-release), otherwise cannot chroot
    if [ -f "\$mnt/etc/os-release" ]; then
      return 0
    else
      return 127
    fi
  elif [[ "\$1" == "mount" ]]; then
    # Mounting separate /boot in chroot
    local boot_dev="\$2"
    local boot_mnt="\$3"
    mkdir -p "\$mnt/\$boot_mnt"
    cp -r "$MOCK_NVME0N2P2"/* "\$mnt/\$boot_mnt/" 2>/dev/null || true
    return 0
  elif [[ "\$1" == "umount" ]]; then
    return 0
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
  if [[ "\$dev" == *nvme0n2p1 ]]; then
    echo -e "part\nvfat"
  elif [[ "\$dev" == *nvme0n2p2 ]]; then
    echo -e "part\nxfs"
  elif [[ "\$dev" == *md127 ]]; then
    echo -e "raid1\nxfs"
  else
    echo -e "part\next4"
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

  echo "PASS: $test_name (dracut called with -N on MDRAID root)"
  return 0
}

setup_mock_devices
run_test_scenario "MDRAID root /dev/md127 with separate /boot on NVMe (/dev/nvme0n2p2)" '-p "nvme0n2p1 nvme0n2p2 md127" auto'

rm -rf "$TEST_DIR" /tmp/mock_dracut_execution.log /tmp/mock_ocs_update_initrd.log

echo "=== All MDRAID separate /boot tests passed successfully ==="
exit 0
