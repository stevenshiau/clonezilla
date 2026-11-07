#!/bin/bash
# Standalone test for NVMe PCI order sorting in initrd

set -e

echo "=== Running NVMe PCI Order Sorting Tests ==="

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

# -------------------------------------------------------------
# Test 1: Test add_cpu_offline_online_in_initrd hook installation
# -------------------------------------------------------------
echo "[Test 1] Testing add_cpu_offline_online_in_initrd script installation order..."
(
  TEST_DIR=$(mktemp -d)
  trap 'rm -rf "$TEST_DIR"' EXIT

  MOCK_LIVE_HOOK="$TEST_DIR/live-hook-dir/udev"
  mkdir -p "$MOCK_LIVE_HOOK"
  cp "$SCRIPT_DIR/setup/files/ocs/live-hook/udev/cpu_offline" "$MOCK_LIVE_HOOK/"
  cp "$SCRIPT_DIR/setup/files/ocs/live-hook/udev/cpu_online" "$MOCK_LIVE_HOOK/"
  cp "$SCRIPT_DIR/setup/files/ocs/live-hook/udev/nvme_pci_sort" "$MOCK_LIVE_HOOK/"

  MOCK_INITRD_TOP="$TEST_DIR/etc/initramfs-tools/scripts/init-top"
  MOCK_INITRD_PREMOUNT="$TEST_DIR/etc/initramfs-tools/scripts/init-premount"
  mkdir -p "$MOCK_INITRD_TOP" "$MOCK_INITRD_PREMOUNT"

  # Load functions from ocs-live-hook-functions with mock paths
  export DRBL_SCRIPT_PATH="."
  export MOCK_BASE_DIR="$TEST_DIR"

  # Create a wrapper function that uses mock destination directories
  eval "$(sed 's|/live-hook-dir|'"$TEST_DIR"'/live-hook-dir|g; s|/etc/initramfs-tools|'"$TEST_DIR"'/etc/initramfs-tools|g' "$SCRIPT_DIR/setup/files/ocs/live-hook/ocs-live-hook-functions" | sed -n '/^add_cpu_offline_online_in_initrd() {/,/^} # end of add_cpu_offline_online_in_initrd/p')"

  add_cpu_offline_online_in_initrd

  if [ ! -f "$MOCK_INITRD_TOP/01_cpu_offline" ]; then
    echo "FAIL: Expected $MOCK_INITRD_TOP/01_cpu_offline to exist"
    exit 1
  fi

  if [ ! -f "$MOCK_INITRD_PREMOUNT/01_nvme_pci_sort" ]; then
    echo "FAIL: Expected $MOCK_INITRD_PREMOUNT/01_nvme_pci_sort to exist"
    exit 1
  fi

  if [ ! -f "$MOCK_INITRD_PREMOUNT/02_cpu_online" ]; then
    echo "FAIL: Expected $MOCK_INITRD_PREMOUNT/02_cpu_online to exist"
    exit 1
  fi

  echo "  PASS: 01_nvme_pci_sort is installed before 02_cpu_online in init-premount."
)

# -------------------------------------------------------------
# Test 2: Skip when ocs_1_cpu_udev is not in kernel cmdline
# -------------------------------------------------------------
echo "[Test 2] Testing skip when ocs_1_cpu_udev is not enabled..."
(
  TEST_DIR=$(mktemp -d)
  trap 'rm -rf "$TEST_DIR"' EXIT

  CMDLINE_FILE="$TEST_DIR/cmdline"
  echo "BOOT_IMAGE=/live/vmlinuz boot=live quiet" > "$CMDLINE_FILE"

  export CMDLINE_FILE
  export SYS_DIR="$TEST_DIR/sys"
  mkdir -p "$SYS_DIR/bus/pci/devices"

  OUTPUT=$(sh "$SCRIPT_DIR/setup/files/ocs/live-hook/udev/nvme_pci_sort")
  if [ -n "$OUTPUT" ]; then
    echo "FAIL: Expected no output when ocs_1_cpu_udev is not on cmdline, got: $OUTPUT"
    exit 1
  fi
  echo "  PASS: Script skipped cleanly when boot parameter is missing."
)

# -------------------------------------------------------------
# Test 3: Skip when fewer than 2 NVMe controllers exist
# -------------------------------------------------------------
echo "[Test 3] Testing skip when only 1 NVMe controller exists..."
(
  TEST_DIR=$(mktemp -d)
  trap 'rm -rf "$TEST_DIR"' EXIT

  CMDLINE_FILE="$TEST_DIR/cmdline"
  echo "boot=live ocs_1_cpu_udev" > "$CMDLINE_FILE"

  SYS_DIR="$TEST_DIR/sys"
  mkdir -p "$SYS_DIR/bus/pci/devices/0000:01:00.0"
  echo "0x010802" > "$SYS_DIR/bus/pci/devices/0000:01:00.0/class"

  export CMDLINE_FILE
  export SYS_DIR

  OUTPUT=$(sh "$SCRIPT_DIR/setup/files/ocs/live-hook/udev/nvme_pci_sort")
  if [ -n "$OUTPUT" ]; then
    echo "FAIL: Expected no output for single NVMe controller, got: $OUTPUT"
    exit 1
  fi
  echo "  PASS: Single NVMe controller skipped (already nvme0)."
)

# -------------------------------------------------------------
# Test 4: Detect when devices are already in PCI order
# -------------------------------------------------------------
echo "[Test 4] Testing skip when controllers are already in PCI order..."
(
  TEST_DIR=$(mktemp -d)
  trap 'rm -rf "$TEST_DIR"' EXIT

  CMDLINE_FILE="$TEST_DIR/cmdline"
  echo "boot=live ocs_1_cpu_udev" > "$CMDLINE_FILE"

  SYS_DIR="$TEST_DIR/sys"
  mkdir -p "$SYS_DIR/bus/pci/devices/0000:01:00.0/nvme/nvme0"
  echo "0x010802" > "$SYS_DIR/bus/pci/devices/0000:01:00.0/class"

  mkdir -p "$SYS_DIR/bus/pci/devices/0000:02:00.0/nvme/nvme1"
  echo "0x010802" > "$SYS_DIR/bus/pci/devices/0000:02:00.0/class"

  export CMDLINE_FILE
  export SYS_DIR

  OUTPUT=$(sh "$SCRIPT_DIR/setup/files/ocs/live-hook/udev/nvme_pci_sort")
  if [[ "$OUTPUT" != *"already in PCI order"* ]]; then
    echo "FAIL: Expected 'already in PCI order' message, got: $OUTPUT"
    exit 1
  fi
  echo "  PASS: Detected that NVMe controllers are already sorted."
)

# -------------------------------------------------------------
# Test 5: Re-bind out-of-order NVMe controllers in PCI order
# -------------------------------------------------------------
echo "[Test 5] Testing re-binding out-of-order NVMe controllers in PCI order..."
(
  TEST_DIR=$(mktemp -d)
  trap 'rm -rf "$TEST_DIR"' EXIT

  CMDLINE_FILE="$TEST_DIR/cmdline"
  echo "boot=live ocs_1_cpu_udev" > "$CMDLINE_FILE"

  SYS_DIR="$TEST_DIR/sys"
  PCI_DEV_DIR="$SYS_DIR/bus/pci/devices"
  PCI_DRV_DIR="$SYS_DIR/bus/pci/drivers/nvme"
  mkdir -p "$PCI_DRV_DIR"
  echo "1" > "$SYS_DIR/bus/pci/drivers_autoprobe"

  # Device A at 0000:01:00.0 was probed as nvme1 (wrong order!)
  mkdir -p "$PCI_DEV_DIR/0000:01:00.0/nvme/nvme1"
  echo "0x010802" > "$PCI_DEV_DIR/0000:01:00.0/class"
  touch "$PCI_DRV_DIR/0000:01:00.0"

  # Device B at 0000:02:00.0 was probed as nvme0 (wrong order!)
  mkdir -p "$PCI_DEV_DIR/0000:02:00.0/nvme/nvme0"
  echo "0x010802" > "$PCI_DEV_DIR/0000:02:00.0/class"
  touch "$PCI_DRV_DIR/0000:02:00.0"

  # Create mock bin for modprobe, udevadm
  MOCK_BIN="$TEST_DIR/bin"
  mkdir -p "$MOCK_BIN"
  export PATH="$MOCK_BIN:$PATH"

  cat <<'EOF' > "$MOCK_BIN/modprobe"
#!/bin/sh
exit 0
EOF
  chmod +x "$MOCK_BIN/modprobe"

  cat <<'EOF' > "$MOCK_BIN/udevadm"
#!/bin/sh
exit 0
EOF
  chmod +x "$MOCK_BIN/udevadm"

  # Use named pipes to record all writes to unbind and bind
  UNBIND_LOG="$TEST_DIR/unbind.log"
  BIND_LOG="$TEST_DIR/bind.log"
  touch "$UNBIND_LOG" "$BIND_LOG"
  mkfifo "$PCI_DRV_DIR/unbind" "$PCI_DRV_DIR/bind"

  # Reader for unbind
  (
    while true; do
      if read -r line < "$PCI_DRV_DIR/unbind"; then
        echo "$line" >> "$UNBIND_LOG"
      fi
    done
  ) &
  UNBIND_PID=$!

  # Reader for bind: logs bind action and populates sysfs state
  (
    while true; do
      if read -r line < "$PCI_DRV_DIR/bind"; then
        echo "$line" >> "$BIND_LOG"
        bdf=$(echo "$line" | xargs)
        if [ -n "$bdf" ] && [ -d "$PCI_DEV_DIR/$bdf" ]; then
          mkdir -p "$PCI_DEV_DIR/$bdf/nvme/nvme_active"
          echo "live" > "$PCI_DEV_DIR/$bdf/nvme/nvme_active/state"
          touch "$PCI_DEV_DIR/$bdf/nvme/nvme_active/nvme_activen1"
        fi
      fi
    done
  ) &
  BIND_PID=$!

  trap "kill $UNBIND_PID $BIND_PID 2>/dev/null || true; rm -rf '$TEST_DIR'" EXIT

  export CMDLINE_FILE
  export SYS_DIR

  OUTPUT=$(sh "$SCRIPT_DIR/setup/files/ocs/live-hook/udev/nvme_pci_sort")

  kill $UNBIND_PID $BIND_PID 2>/dev/null || true

  # Check that unbind received both devices
  UNBOUND=$(cat "$UNBIND_LOG")
  if [[ "$UNBOUND" != *"0000:01:00.0"* ]] || [[ "$UNBOUND" != *"0000:02:00.0"* ]]; then
    echo "FAIL: Expected both devices to be unbound, got: $UNBOUND"
    exit 1
  fi

  # Check that bind received devices in strict PCI order: 0000:01:00.0 THEN 0000:02:00.0
  BOUND_FIRST=$(head -n 1 "$BIND_LOG" | xargs)
  BOUND_SECOND=$(tail -n 1 "$BIND_LOG" | xargs)

  if [ "$BOUND_FIRST" != "0000:01:00.0" ]; then
    echo "FAIL: Expected first bound device to be 0000:01:00.0, got: $BOUND_FIRST"
    exit 1
  fi

  if [ "$BOUND_SECOND" != "0000:02:00.0" ]; then
    echo "FAIL: Expected second bound device to be 0000:02:00.0, got: $BOUND_SECOND"
    exit 1
  fi

  # Check that drivers_autoprobe was restored to 1
  AUTOPROBE_VAL=$(cat "$SYS_DIR/bus/pci/drivers_autoprobe" | xargs)
  if [ "$AUTOPROBE_VAL" != "1" ]; then
    echo "FAIL: Expected drivers_autoprobe to be restored to 1, got: $AUTOPROBE_VAL"
    exit 1
  fi

  echo "  PASS: Controllers were unbound and bound sequentially in strict PCI order (0000:01:00.0 then 0000:02:00.0)."
)

# -------------------------------------------------------------
# Test 6: Verify hexadecimal PCI address sorting (e.g., 01, 0a, 10)
# -------------------------------------------------------------
echo "[Test 6] Testing hex PCI address ordering (0000:01:00.0, 0000:0a:00.0, 0000:10:00.0)..."
(
  TEST_DIR=$(mktemp -d)
  trap 'rm -rf "$TEST_DIR"' EXIT

  CMDLINE_FILE="$TEST_DIR/cmdline"
  echo "boot=live ocs_nvme_pci_sort" > "$CMDLINE_FILE"

  SYS_DIR="$TEST_DIR/sys"
  PCI_DEV_DIR="$SYS_DIR/bus/pci/devices"
  PCI_DRV_DIR="$SYS_DIR/bus/pci/drivers/nvme"
  mkdir -p "$PCI_DRV_DIR"
  echo "1" > "$SYS_DIR/bus/pci/drivers_autoprobe"

  # Create out of order controllers: 0000:10:00.0 has nvme0, 0000:0a:00.0 has nvme1, 0000:01:00.0 has nvme2
  for bdf in "0000:01:00.0" "0000:0a:00.0" "0000:10:00.0"; do
    mkdir -p "$PCI_DEV_DIR/$bdf/nvme/nvme_wrong"
    echo "0x010802" > "$PCI_DEV_DIR/$bdf/class"
    touch "$PCI_DRV_DIR/$bdf"
  done

  # Create mock bin
  MOCK_BIN="$TEST_DIR/bin"
  mkdir -p "$MOCK_BIN"
  export PATH="$MOCK_BIN:$PATH"

  cat <<'EOF' > "$MOCK_BIN/modprobe"
#!/bin/sh
exit 0
EOF
  chmod +x "$MOCK_BIN/modprobe"

  cat <<'EOF' > "$MOCK_BIN/udevadm"
#!/bin/sh
exit 0
EOF
  chmod +x "$MOCK_BIN/udevadm"

  BIND_LOG="$TEST_DIR/bind.log"
  touch "$BIND_LOG"
  mkfifo "$PCI_DRV_DIR/unbind" "$PCI_DRV_DIR/bind"

  # Dummy reader for unbind
  (
    while true; do
      read -r _ < "$PCI_DRV_DIR/unbind" || true
    done
  ) &
  UNBIND_PID=$!

  # Reader for bind
  (
    while true; do
      if read -r line < "$PCI_DRV_DIR/bind"; then
        echo "$line" >> "$BIND_LOG"
        bdf=$(echo "$line" | xargs)
        if [ -n "$bdf" ] && [ -d "$PCI_DEV_DIR/$bdf" ]; then
          mkdir -p "$PCI_DEV_DIR/$bdf/nvme/nvme_active"
          echo "live" > "$PCI_DEV_DIR/$bdf/nvme/nvme_active/state"
          touch "$PCI_DEV_DIR/$bdf/nvme/nvme_active/nvme_activen1"
        fi
      fi
    done
  ) &
  BIND_PID=$!

  trap "kill $UNBIND_PID $BIND_PID 2>/dev/null || true; rm -rf '$TEST_DIR'" EXIT

  export CMDLINE_FILE
  export SYS_DIR

  OUTPUT=$(sh "$SCRIPT_DIR/setup/files/ocs/live-hook/udev/nvme_pci_sort")

  kill $UNBIND_PID $BIND_PID 2>/dev/null || true

  BOUND_ORDER=$(cat "$BIND_LOG" | tr '\n' ' ' | xargs)
  EXPECTED_ORDER="0000:01:00.0 0000:0a:00.0 0000:10:00.0"

  if [ "$BOUND_ORDER" != "$EXPECTED_ORDER" ]; then
    echo "FAIL: Expected bind order '$EXPECTED_ORDER', but got: '$BOUND_ORDER'"
    exit 1
  fi

  echo "  PASS: Hex PCI addresses sorted correctly: $BOUND_ORDER."
)

echo "PASS: All NVMe PCI order sorting tests passed successfully!"
exit 0
