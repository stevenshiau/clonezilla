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

  export CMDLINE_FILE
  export SYS_DIR

  OUT_OFF=$(sh "$SCRIPT_DIR/setup/files/ocs/live-hook/udev/cpu_offline")
  if [[ "$OUT_OFF" != *"already running on single CPU"* ]]; then
    echo "FAIL: Expected 'already running on single CPU', got: $OUT_OFF"
    exit 1
  fi

  echo "  PASS: Correctly detected single CPU and exited immediately with 0 delay."
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

  # Background watcher to simulate kernel updating cpu/online to "0" after echo 0
  (
    while true; do
      c1=$(cat "$SYS_DIR/devices/system/cpu/cpu1/online" 2>/dev/null || echo 1)
      c2=$(cat "$SYS_DIR/devices/system/cpu/cpu2/online" 2>/dev/null || echo 1)
      if [ "$c1" = "0" ] && [ "$c2" = "0" ]; then
        echo "0" > "$SYS_DIR/devices/system/cpu/online"
      fi
      sleep 0.02
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
# Test 4: Fast timeout safety in cpu_offline
# -------------------------------------------------------------
echo "[Test 4] Testing fast timeout safety in cpu_offline without long boot delays..."
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

  START_TIME=$(date +%s)
  OUT_OFF=$(sh "$SCRIPT_DIR/setup/files/ocs/live-hook/udev/cpu_offline")
  END_TIME=$(date +%s)

  if [[ "$OUT_OFF" != *"proceeding"* ]]; then
    echo "FAIL: Expected proceeding message upon timeout, got: $OUT_OFF"
    exit 1
  fi

  ELAPSED=$((END_TIME - START_TIME))
  if [ "$ELAPSED" -gt 2 ]; then
    echo "FAIL: Timeout took too long (${ELAPSED}s), expected <= 2s"
    exit 1
  fi

  echo "  PASS: cpu_offline safely timed out in ${ELAPSED}s without hanging."
)

# -------------------------------------------------------------
# Test 5: Fast non-blocking CPU re-enabling in cpu_online
# -------------------------------------------------------------
echo "[Test 5] Testing cpu_online non-blocking CPU wake-up..."
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

  export CMDLINE_FILE
  export SYS_DIR

  OUT_ON=$(sh "$SCRIPT_DIR/setup/files/ocs/live-hook/udev/cpu_online")

  if [[ "$OUT_ON" != *"cpu1, cpu2, done!"* ]] && [[ "$OUT_ON" != *"cpu1"* ]]; then
    echo "FAIL: Expected CPUs to be enabled, got: $OUT_ON"
    exit 1
  fi

  # Give brief moment for background subshell to write
  sleep 0.1
  if [ "$(cat "$SYS_DIR/devices/system/cpu/cpu1/online")" != "1" ] || [ "$(cat "$SYS_DIR/devices/system/cpu/cpu2/online")" != "1" ]; then
    echo "FAIL: cpu1 or cpu2 was not set back to 1"
    exit 1
  fi

  echo "  PASS: cpu_online woke up all CPUs asynchronously without blocking boot."
)

# -------------------------------------------------------------
# Test 6: Verify drbl-ocs.conf does not bottleneck udev workers
# -------------------------------------------------------------
echo "[Test 6] Verifying drbl-ocs.conf does not contain system-wide udev bottleneck..."
(
  if grep -E "^supp_boot_param_ocs_live_extra=.*udev\.children-max=1" "$SCRIPT_DIR/conf/drbl-ocs.conf"; then
    echo "FAIL: udev.children-max=1 found in supp_boot_param_ocs_live_extra (this causes system-wide boot slowdown)"
    exit 1
  fi

  echo "  PASS: drbl-ocs.conf free of udev.children-max bottleneck."
)

echo "PASS: All CPU Offline/Online Initrd Tests passed successfully!"
exit 0
