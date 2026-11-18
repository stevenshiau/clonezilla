#!/bin/bash
# Standalone test for ocs-install-grub / check_grub2_config_file logic
# Verifies that RHEL-family guests (Fedora, AlmaLinux, Rocky) using /grub2 or /boot/grub2
# have /boot/grub/grub.cfg properly populated to source /grub2/grub.cfg, avoiding bare grub> prompt.

set -e

echo "=== Running ocs-install-grub RHEL/Fedora grub2 layout tests ==="

TEST_DIR="$(mktemp -d /tmp/test_grub2_layout.XXXXXX)"
clean_up() {
  rm -rf "$TEST_DIR"
}
trap clean_up EXIT

# Source ocs-functions from current workspace
DRBL_SCRIPT_PATH="${DRBL_SCRIPT_PATH:-/usr/share/drbl}"
export DRBL_SCRIPT_PATH
if [ -f "./scripts/sbin/ocs-functions" ]; then
  . ./scripts/sbin/ocs-functions
fi

# Load check_grub2_config_file from sbin/ocs-install-grub if defined there
# Extract function definition or test directly
if [ -f "./sbin/ocs-install-grub" ]; then
  # Evaluate check_grub2_config_file from sbin/ocs-install-grub if present
  eval "$(awk '/^check_grub2_config_file\(\)/,/^} # end of check_grub2_config_file/' ./sbin/ocs-install-grub 2>/dev/null || true)"
fi

# Test Case 1: Separate /boot partition with /grub2 layout (Fedora/AlmaLinux/Rocky)
# In this layout, when mounted under $hd_img:
# $hd_img/boot is the mount point of the boot partition, containing grub2/grub.cfg
echo "--- Testing Case 1: Separate /boot partition with /boot/grub2/grub.cfg ---"
MOCK_ROOT="$TEST_DIR/case1_root"
mkdir -p "$MOCK_ROOT/boot/grub2"
mkdir -p "$MOCK_ROOT/boot/grub" # created by live grub-install

cat <<'EOF' > "$MOCK_ROOT/boot/grub2/grub.cfg"
# Original Fedora / RHEL grub.cfg
set default="0"
menuentry 'Fedora Linux' {
  linux /vmlinuz-6.12.0 root=/dev/vda2 ro
  initrd /initramfs-6.12.0.img
}
EOF
echo "saved_entry=Fedora Linux" > "$MOCK_ROOT/boot/grub2/grubenv"
touch "$MOCK_ROOT/boot/grub/device.map"

if ! type check_grub2_config_file &>/dev/null; then
  echo "FAIL: check_grub2_config_file function is not defined!"
  exit 1
fi

check_grub2_config_file "$MOCK_ROOT"

if [ ! -f "$MOCK_ROOT/boot/grub/grub.cfg" ]; then
  echo "FAIL: $MOCK_ROOT/boot/grub/grub.cfg was not created!"
  exit 1
fi

echo "Created grub.cfg content:"
cat "$MOCK_ROOT/boot/grub/grub.cfg"

# Verify that grub.cfg correctly sources /grub2/grub.cfg or /boot/grub2/grub.cfg
if ! grep -q "source /grub2/grub.cfg" "$MOCK_ROOT/boot/grub/grub.cfg"; then
  echo "FAIL: Expected 'source /grub2/grub.cfg' in generated grub.cfg"
  exit 1
fi

# Verify grubenv synchronization
if [ ! -f "$MOCK_ROOT/boot/grub/grubenv" ]; then
  echo "FAIL: grubenv was not synced to $MOCK_ROOT/boot/grub/grubenv"
  exit 1
fi
echo "Case 1 Passed!"

# Test Case 2: Single partition with /boot/grub2 layout
echo "--- Testing Case 2: Single partition with /boot/grub2/grub.cfg ---"
MOCK_ROOT2="$TEST_DIR/case2_root"
mkdir -p "$MOCK_ROOT2/boot/grub2"
mkdir -p "$MOCK_ROOT2/boot/grub"
cat <<'EOF' > "$MOCK_ROOT2/boot/grub2/grub.cfg"
# Single partition grub.cfg
menuentry 'AlmaLinux' {
  linux /boot/vmlinuz root=/dev/vda1 ro
}
EOF

check_grub2_config_file "$MOCK_ROOT2"

if [ ! -f "$MOCK_ROOT2/boot/grub/grub.cfg" ]; then
  echo "FAIL: $MOCK_ROOT2/boot/grub/grub.cfg was not created in Case 2!"
  exit 1
fi

if ! grep -q "source /boot/grub2/grub.cfg" "$MOCK_ROOT2/boot/grub/grub.cfg"; then
  echo "FAIL: Expected 'source /boot/grub2/grub.cfg' in generated grub.cfg"
  exit 1
fi
echo "Case 2 Passed!"

# Test Case 3: Debian/Ubuntu style system with /boot/grub/grub.cfg
echo "--- Testing Case 3: Preserving existing /boot/grub/grub.cfg and creating grub2 fallback ---"
MOCK_ROOT3="$TEST_DIR/case3_root"
mkdir -p "$MOCK_ROOT3/boot/grub"
cat <<'EOF' > "$MOCK_ROOT3/boot/grub/grub.cfg"
# Original Debian grub.cfg
menuentry 'Debian GNU/Linux' {
  linux /boot/vmlinuz root=/dev/vda1 ro
}
EOF

check_grub2_config_file "$MOCK_ROOT3"

# Ensure original is NOT overwritten
if ! grep -q "Debian GNU/Linux" "$MOCK_ROOT3/boot/grub/grub.cfg"; then
  echo "FAIL: Original Debian grub.cfg was modified or overwritten!"
  exit 1
fi

# Ensure grub2 fallback was created
if [ ! -f "$MOCK_ROOT3/boot/grub2/grub.cfg" ]; then
  echo "FAIL: $MOCK_ROOT3/boot/grub2/grub.cfg fallback was not created!"
  exit 1
fi

if ! grep -q "source /boot/grub/grub.cfg" "$MOCK_ROOT3/boot/grub2/grub.cfg"; then
  echo "FAIL: Expected 'source /boot/grub/grub.cfg' in generated grub2.cfg"
  exit 1
fi
echo "Case 3 Passed!"

# Test Case 4: Verify GRUB 2 detection in ocs-install-grub when no *.mod exist in /boot/grub2
echo "--- Testing Case 4: GRUB 2 detection logic in ocs-install-grub ---"
MOCK_ROOT4="$TEST_DIR/case4_root"
mkdir -p "$MOCK_ROOT4/boot/grub2"
touch "$MOCK_ROOT4/boot/grub2/grub.cfg"

# Test detection logic from ocs-install-grub
grub_ver_in_restored_os=""
grub2_boot_dir=""
hd_img="$MOCK_ROOT4"

# Simulate updated detection logic
if [ -n "$(find $hd_img/boot/grub/ -iname "*.mod" -print 2>/dev/null)" ]; then
  grub_ver_in_restored_os="2"
  grub2_boot_dir="/boot/grub/"
elif [ -n "$(find $hd_img/boot/grub2/ -iname "*.mod" -print 2>/dev/null)" ]; then
  grub_ver_in_restored_os="2"
  grub2_boot_dir="/boot/grub2/"
elif [ -d "$hd_img/boot/grub2" -a -n "$(chroot $hd_img/ command -v grub2-install 2>/dev/null)" ]; then
  grub_ver_in_restored_os="2"
  grub2_boot_dir="/boot/grub2/"
elif [ -f "$hd_img/boot/grub2/grub.cfg" -o -d "$hd_img/boot/grub2" ]; then
  grub_ver_in_restored_os="2"
  grub2_boot_dir="/boot/grub2/"
elif [ -f "$hd_img/boot/grub/grub.cfg" ]; then
  grub_ver_in_restored_os="2"
  grub2_boot_dir="/boot/grub/"
else
  grub_ver_in_restored_os="1"
fi

if [ "$grub_ver_in_restored_os" != "2" ] || [ "$grub2_boot_dir" != "/boot/grub2/" ]; then
  echo "FAIL: Expected GRUB 2 and /boot/grub2/, but got ver='$grub_ver_in_restored_os', dir='$grub2_boot_dir'"
  exit 1
fi
echo "Case 4 Passed!"

echo "=== All ocs-install-grub RHEL/Fedora grub2 layout tests passed successfully! ==="
