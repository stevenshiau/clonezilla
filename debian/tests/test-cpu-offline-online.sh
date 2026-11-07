#!/bin/bash
# Standalone test for cpu_offline and cpu_online hooks in initrd

set -e

echo "=== Running CPU Offline/Online Initrd Tests ==="

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

# -------------------------------------------------------------
# Test 1: Skip when neither ocs_1_cpu_udev nor maxcpus=1 is set
# -------------------------------------------------------------
echo "[Test 1] Testing skip when no trigger parameter is present..."
(
  TEST_DIR=$(mktemp -d)
  trap 'rm -rf "$TEST_DIR"' EXIT

  CMDLINE_FILE="$TEST_DIR/cmdline"
  echo "BOOT_IMAGE=/live/vmlinuz boot=live quiet" > "$CMDLINE_FILE"

  export CMDLINE_FILE
  export SYS_DIR="$TEST_DIR/sys"
  mkdir -p "$SYS_DIR/devices/system/cpu"

  OUT_OFF=$(sh "$SCRIPT_DIR/setup/files/ocs/live-hook/udev/cpu_offline")
  if [ -n "$OUT_OFF" ]; then
    echo "FAIL: Expected no output from cpu_offline when parameter missing, got: $OUT_OFF"
    exit 1
  fi

  OUT_ON=$(sh "$SCRIPT_DIR/setup/files/ocs/live-hook/udev/cpu_online")
  if [ -n "$OUT_ON" ]; then
    echo "FAIL: Expected no output from cpu_online when parameter missing, got: $OUT_ON"
    exit 1
  fi

  echo "  PASS: cpu_offline and cpu_online cleanly skipped."
)

# -------------------------------------------------------------
# Test 2: Detect already single CPU (e.g. booted with maxcpus=1)
# -------------------------------------------------------------
echo "[Test 2] Testing maxcpus=1 detection when already single CPU..."
(
  TEST_DIR=$(mktemp -d)
  trap 'rm -rf "$TEST_DIR"' EXIT

  CMDLINE_FILE="$TEST_DIR/cmdline"
  echo "BOOT_IMAGE=/live/vmlinuz boot=live maxcpus=1" > "$CMDLINE_FILE"

  SYS_DIR="$TEST_DIR/sys"
  mkdir -p "$SYS_DIR/devices/system/cpu"
  echo "0" > "$SYS_DIR/devices/system/cpu/online"

  MOCK_UDEV_CONF="$TEST_DIR/etc/udev/udev.conf"
  mkdir -p "$TEST_DIR/etc/udev"

  export CMDLINE_FILE
  export SYS_DIR
  export UDEV_CONF="$MOCK_UDEV_CONF"

  OUT_OFF=$(sh "$SCRIPT_DIR/setup/files/ocs/live-hook/udev/cpu_offline")
  if [[ "$OUT_OFF" != *"already running on single CPU"* ]]; then
    echo "FAIL: Expected 'already running on single CPU', got: $OUT_OFF"
    exit 1
  fi

  # Check that udev.conf received children_max=1
  if ! grep -q "^children_max=1" "$MOCK_UDEV_CONF"; then
    echo "FAIL: Expected children_max=1 in udev.conf"
    exit 1
  fi

  echo "  PASS: Correctly detected single CPU and configured udev children_max=1."
)

# -------------------------------------------------------------
# Test 3: Offlining SMP CPUs when ocs_1_cpu_udev is enabled
# -------------------------------------------------------------
echo "[Test 3] Testing offlining SMP CPUs with ocs_1_cpu_udev..."
(
  TEST_DIR=$(mktemp -d)
  trap 'rm -rf "$TEST_DIR"' EXIT

  CMDLINE_FILE="$TEST_DIR/cmdline"
  echo "BOOT_IMAGE=/live/vmlinuz boot=live ocs_1_cpu_udev" > "$CMDLINE_FILE"

  SYS_DIR="$TEST_DIR/sys"
  mkdir -p "$SYS_DIR/devices/system/cpu/cpu0"
  mkdir -p "$SYS_DIR/devices/system/cpu/cpu1"
  mkdir -p "$SYS_DIR/devices/system/cpu/cpu2"
  echo "0-2" > "$SYS_DIR/devices/system/cpu/online"
  echo "1" > "$SYS_DIR/devices/system/cpu/cpu1/online"
  echo "1" > "$SYS_DIR/devices/system/cpu/cpu2/online"

  export CMDLINE_FILE
  export SYS_DIR
  export UDEV_CONF="$TEST_DIR/etc/udev/udev.conf"
  mkdir -p "$TEST_DIR/etc/udev"

  # Background watcher to simulate kernel updating cpu/online to "0" after echo 0
  (
    while true; do
      c1=$(cat "$SYS_DIR/devices/system/cpu/cpu1/online" 2>/dev/null || echo 1)
      c2=$(cat "$SYS_DIR/devices/system/cpu/cpu2/online" 2>/dev/null || echo 1)
      if [ "$c1" = "0" ] && [ "$c2" = "0" ]; then
        echo "0" > "$SYS_DIR/devices/system/cpu/online"
      fi
      sleep 0.05
    done
  ) &
  WATCHER_PID=$!
  trap "kill $WATCHER_PID 2>/dev/null || true; rm -rf '$TEST_DIR'" EXIT

  OUT_OFF=$(sh "$SCRIPT_DIR/setup/files/ocs/live-hook/udev/cpu_offline")
  kill $WATCHER_PID 2>/dev/null || true

  if [[ "$OUT_OFF" != *"done!"* ]]; then
    echo "FAIL: Expected 'done!' from cpu_offline, got: $OUT_OFF"
    exit 1
  fi

  if [ "$(cat "$SYS_DIR/devices/system/cpu/cpu1/online")" != "0" ] || [ "$(cat "$SYS_DIR/devices/system/cpu/cpu2/online")" != "0" ]; then
    echo "FAIL: cpu1 or cpu2 was not set to 0"
    exit 1
  fi

  echo "  PASS: cpu1 and cpu2 offlined successfully."
)

# -------------------------------------------------------------
# Test 4: Timeout safety in cpu_offline
# -------------------------------------------------------------
echo "[Test 4] Testing timeout safety in cpu_offline when a CPU refuses to offline..."
(
  TEST_DIR=$(mktemp -d)
  trap 'rm -rf "$TEST_DIR"' EXIT

  CMDLINE_FILE="$TEST_DIR/cmdline"
  echo "boot=live ocs_1_cpu_udev" > "$CMDLINE_FILE"

  SYS_DIR="$TEST_DIR/sys"
  mkdir -p "$SYS_DIR/devices/system/cpu/cpu1"
  echo "1" > "$SYS_DIR/devices/system/cpu/cpu1/online"
  echo "0-1" > "$SYS_DIR/devices/system/cpu/online"

  export CMDLINE_FILE
  export SYS_DIR
  export UDEV_CONF="$TEST_DIR/etc/udev/udev.conf"
  mkdir -p "$TEST_DIR/etc/udev"

  # Fast timeout test: replace timeout with short value
  START_TIME=$(date +%s)
  OUT_OFF=$(sed 's/timeout=50/timeout=3/' "$SCRIPT_DIR/setup/files/ocs/live-hook/udev/cpu_offline" | sh)
  END_TIME=$(date +%s)

  if [[ "$OUT_OFF" != *"timeout reached"* ]]; then
    echo "FAIL: Expected 'timeout reached' message, got: $OUT_OFF"
    exit 1
  fi

  ELAPSED=$((END_TIME - START_TIME))
  if [ "$ELAPSED" -gt 3 ]; then
    echo "FAIL: Timeout took too long: ${ELAPSED}s"
    exit 1
  fi

  echo "  PASS: cpu_offline safely timed out without hanging."
)

# -------------------------------------------------------------
# Test 5: Re-enabling CPUs in cpu_online with udev settle and wait
# -------------------------------------------------------------
echo "[Test 5] Testing cpu_online re-enabling all offline CPUs..."
(
  TEST_DIR=$(mktemp -d)
  trap 'rm -rf "$TEST_DIR"' EXIT

  CMDLINE_FILE="$TEST_DIR/cmdline"
  echo "boot=live maxcpus=1" > "$CMDLINE_FILE"

  SYS_DIR="$TEST_DIR/sys"
  mkdir -p "$SYS_DIR/devices/system/cpu/cpu0"
  mkdir -p "$SYS_DIR/devices/system/cpu/cpu1"
  mkdir -p "$SYS_DIR/devices/system/cpu/cpu2"
  echo "0" > "$SYS_DIR/devices/system/cpu/cpu1/online"
  echo "0" > "$SYS_DIR/devices/system/cpu/cpu2/online"

  MOCK_BIN="$TEST_DIR/bin"
  mkdir -p "$MOCK_BIN"
  export PATH="$MOCK_BIN:$PATH"

  SETTLE_LOG="$TEST_DIR/settle.log"
  cat <<EOF > "$MOCK_BIN/udevadm"
#!/bin/sh
echo "udevadm \$*" >> "$SETTLE_LOG"
exit 0
EOF
  chmod +x "$MOCK_BIN/udevadm"

  export CMDLINE_FILE
  export SYS_DIR

  OUT_ON=$(sh "$SCRIPT_DIR/setup/files/ocs/live-hook/udev/cpu_online")

  if [[ "$OUT_ON" != *"cpu1, cpu2, done!"* ]] && [[ "$OUT_ON" != *"cpu1"* ]]; then
    echo "FAIL: Expected CPUs to be enabled, got: $OUT_ON"
    exit 1
  fi

  if [ "$(cat "$SYS_DIR/devices/system/cpu/cpu1/online")" != "1" ] || [ "$(cat "$SYS_DIR/devices/system/cpu/cpu2/online")" != "1" ]; then
    echo "FAIL: cpu1 or cpu2 was not set back to 1"
    exit 1
  fi

  if ! grep -q "udevadm settle" "$SETTLE_LOG"; then
    echo "FAIL: udevadm settle was not called before bringing CPUs online"
    exit 1
  fi

  echo "  PASS: cpu_online settled udev and restored all CPUs."
)

# -------------------------------------------------------------
# Test 6: Verify drbl-ocs.conf boot parameter configuration
# -------------------------------------------------------------
echo "[Test 6] Testing drbl-ocs.conf boot parameters..."
(
  grep -E "^supp_boot_param_ocs_live_extra=.*maxcpus=1" "$SCRIPT_DIR/conf/drbl-ocs.conf" || {
    echo "FAIL: maxcpus=1 missing from supp_boot_param_ocs_live_extra"
    exit 1
  }

  grep -E "^supp_boot_param_ocs_live_extra=.*udev\.children-max=1" "$SCRIPT_DIR/conf/drbl-ocs.conf" || {
    echo "FAIL: udev.children-max=1 missing from supp_boot_param_ocs_live_extra"
    exit 1
  }

  echo "  PASS: drbl-ocs.conf contains maxcpus=1 and udev.children-max=1."
)

echo "PASS: All CPU Offline/Online Initrd Tests passed successfully!"
exit 0
