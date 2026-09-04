#!/bin/bash
# Standalone test for ocs-live-boot-menu EFI GOP built-in detection logic.

set -e

echo "=== Running grub2-efi GOP Built-in Detection Tests ==="

# Create mock live system directory layout
MOCK_LIVE_DIR="$(mktemp -d /tmp/mock_live.XXXXXX)"
MOCK_BOOT_GRUB="$MOCK_LIVE_DIR/boot/grub"
MOCK_EFI_BOOT="$MOCK_LIVE_DIR/EFI/boot"

mkdir -p "$MOCK_BOOT_GRUB"
mkdir -p "$MOCK_EFI_BOOT"

clean_up() {
  rm -rf "$MOCK_LIVE_DIR"
}
trap clean_up EXIT

# Helper function to run the boot menu generator
run_boot_menu_generator() {
  # We run sbin/ocs-live-boot-menu directly from current project root
  # We pass basic minimum options to avoid any failure in other checks
  ./sbin/ocs-live-boot-menu \
    -l en_US \
    -f 1024x768 \
    -b graphic \
    -k /live/vmlinuz \
    -i /live/initrd.img \
    --title "Clonezilla Live Test" \
    grub2-efi \
    "$MOCK_BOOT_GRUB/"
}

# Test Case 1: No grubx64.efi exists in the live system.
# It should default to writing "insmod efi_gop"
echo "Testing Case 1: No grubx64.efi exists..."
rm -f "$MOCK_EFI_BOOT"/grub*.efi "$MOCK_EFI_BOOT"/boot*.efi "$MOCK_BOOT_GRUB"/grub*.efi

run_boot_menu_generator >/dev/null

if ! grep -q "^insmod efi_gop" "$MOCK_BOOT_GRUB/grub.cfg"; then
  echo "FAIL: Expected 'insmod efi_gop' to be active, but got:"
  grep -A 2 -B 2 "efi_gop" "$MOCK_BOOT_GRUB/grub.cfg" || echo "(not found)"
  exit 1
fi
echo "Case 1 Passed!"

# Test Case 2: grubx64.efi exists, but does NOT contain "efi_gop"
# It should default to writing "insmod efi_gop"
echo "Testing Case 2: grubx64.efi exists without efi_gop built-in..."
echo "dummy executable data without g_o_p" > "$MOCK_EFI_BOOT/grubx64.efi"

run_boot_menu_generator >/dev/null

if ! grep -q "^insmod efi_gop" "$MOCK_BOOT_GRUB/grub.cfg"; then
  echo "FAIL: Expected 'insmod efi_gop' to be active when module is missing in loader, but got:"
  grep -A 2 -B 2 "efi_gop" "$MOCK_BOOT_GRUB/grub.cfg" || echo "(not found)"
  exit 1
fi
echo "Case 2 Passed!"

# Test Case 3: grubx64.efi exists and contains "efi_gop"
# It should comment out "insmod efi_gop"
echo "Testing Case 3: grubx64.efi exists with efi_gop built-in..."
# Write dummy binary/text containing 'efi_gop' string
echo "dummy binary content with built-in module efi_gop inside" > "$MOCK_EFI_BOOT/grubx64.efi"

run_boot_menu_generator >/dev/null

if ! grep -q "^# insmod efi_gop" "$MOCK_BOOT_GRUB/grub.cfg"; then
  echo "FAIL: Expected '# insmod efi_gop' to be commented out, but got:"
  grep -A 2 -B 2 "insmod efi_gop" "$MOCK_BOOT_GRUB/grub.cfg" || echo "(not found)"
  exit 1
fi
echo "Case 3 Passed!"

# Test Case 4: Other architecture loaders like bootaa64.efi exists and contains "efi_gop"
# It should comment out "insmod efi_gop"
echo "Testing Case 4: bootaa64.efi exists with efi_gop built-in..."
rm -f "$MOCK_EFI_BOOT/grubx64.efi"
echo "dummy arm64 binary content with efi_gop" > "$MOCK_EFI_BOOT/bootaa64.efi"

run_boot_menu_generator >/dev/null

if ! grep -q "^# insmod efi_gop" "$MOCK_BOOT_GRUB/grub.cfg"; then
  echo "FAIL: Expected '# insmod efi_gop' to be commented out for arm64 loader, but got:"
  grep -A 2 -B 2 "insmod efi_gop" "$MOCK_BOOT_GRUB/grub.cfg" || echo "(not found)"
  exit 1
fi
echo "Case 4 Passed!"

echo "=== All grub2-efi GOP Built-in Detection Tests Passed Successfully! ==="
