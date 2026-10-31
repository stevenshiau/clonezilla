#!/bin/bash
# Standalone test for NTFS partition mounting across kernel generations in Clonezilla

set -e

echo "=== Running NTFS Mount Logic Tests ==="

MOCK_DIR=$(mktemp -d)
trap 'rm -rf "$MOCK_DIR"' EXIT

# Source ocs-functions from workspace
export DRBL_SCRIPT_PATH="/usr/share/drbl"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
. "$SCRIPT_DIR/scripts/sbin/ocs-functions"

# -------------------------------------------------------------
# Test 1: Modern in-kernel read-write ntfs driver (Kernel 7.1+)
# -------------------------------------------------------------
echo "[Test 1] Testing modern in-kernel read-write ntfs driver priority..."
(
  TEST_DIR=$(mktemp -d)
  trap 'rm -rf "$TEST_DIR"' EXIT

  MOCK_BIN="$TEST_DIR/bin"
  mkdir -p "$MOCK_BIN"
  export PATH="$MOCK_BIN:$PATH"

  CALL_LOG="$TEST_DIR/calls.log"

  cat <<EOF > "$MOCK_BIN/modinfo"
#!/bin/bash
if [ "\$1" = "-F" ] && [ "\$2" = "description" ] && [ "\$3" = "ntfs" ]; then
  echo "NTFS read-write filesystem driver"
  exit 0
fi
exit 1
EOF
  chmod +x "$MOCK_BIN/modinfo"

  cat <<EOF > "$MOCK_BIN/mount"
#!/bin/bash
echo "mount \$*" >> "$CALL_LOG"
exit 0
EOF
  chmod +x "$MOCK_BIN/mount"

  cat <<EOF > "$MOCK_BIN/mountpoint"
#!/bin/bash
exit 0
EOF
  chmod +x "$MOCK_BIN/mountpoint"

  cat <<EOF > "$MOCK_BIN/mktemp"
#!/bin/bash
# Simulate successful write file creation
target="\$1"
file="\${target%XXXXXX}123456"
touch "\$file"
echo "\$file"
exit 0
EOF
  chmod +x "$MOCK_BIN/mktemp"

  MNT_DIR="$TEST_DIR/mnt"
  mkdir -p "$MNT_DIR"

  out=$(mount_ntfs_partition "/dev/nvme0n1p2" "$MNT_DIR" "noatime")
  if [[ "$out" != *"in-kernel ntfs read-write driver"* ]]; then
    echo "FAIL: Expected 'in-kernel ntfs read-write driver' in output, got: $out"
    exit 1
  fi

  if ! grep -q "mount -i -t ntfs -o noatime /dev/nvme0n1p2 $MNT_DIR" "$CALL_LOG"; then
    echo "FAIL: Expected 'mount -i -t ntfs' call in log, got:"
    cat "$CALL_LOG"
    exit 1
  fi
  echo "  PASS: Modern in-kernel read-write ntfs prioritized and invoked with -i flag."
)

# -------------------------------------------------------------
# Test 2: In-kernel ntfs3 driver priority (Kernel 5.15 - 6.x)
# -------------------------------------------------------------
echo "[Test 2] Testing in-kernel ntfs3 driver priority when ntfs is legacy/absent..."
(
  TEST_DIR=$(mktemp -d)
  trap 'rm -rf "$TEST_DIR"' EXIT

  MOCK_BIN="$TEST_DIR/bin"
  mkdir -p "$MOCK_BIN"
  export PATH="$MOCK_BIN:$PATH"

  CALL_LOG="$TEST_DIR/calls.log"

  cat <<EOF > "$MOCK_BIN/modinfo"
#!/bin/bash
if [ "\$1" = "-F" ] && [ "\$2" = "description" ] && [ "\$3" = "ntfs" ]; then
  # Legacy read-only driver description
  echo "NTFS 1.2/3.x driver"
  exit 0
elif [ "\$1" = "ntfs3" ]; then
  echo "NTFS3 driver"
  exit 0
fi
exit 1
EOF
  chmod +x "$MOCK_BIN/modinfo"

  cat <<EOF > "$MOCK_BIN/modprobe"
#!/bin/bash
if [ "\$1" = "ntfs3" ]; then
  exit 0
fi
exit 1
EOF
  chmod +x "$MOCK_BIN/modprobe"

  cat <<EOF > "$MOCK_BIN/mount"
#!/bin/bash
echo "mount \$*" >> "$CALL_LOG"
exit 0
EOF
  chmod +x "$MOCK_BIN/mount"

  cat <<EOF > "$MOCK_BIN/mountpoint"
#!/bin/bash
exit 0
EOF
  chmod +x "$MOCK_BIN/mountpoint"

  cat <<EOF > "$MOCK_BIN/mktemp"
#!/bin/bash
target="\$1"
file="\${target%XXXXXX}123456"
touch "\$file"
echo "\$file"
exit 0
EOF
  chmod +x "$MOCK_BIN/mktemp"

  MNT_DIR="$TEST_DIR/mnt"
  mkdir -p "$MNT_DIR"

  out=$(mount_ntfs_partition "nvme0n1p2" "$MNT_DIR" "noatime")
  if [[ "$out" != *"in-kernel ntfs3 driver"* ]]; then
    echo "FAIL: Expected 'in-kernel ntfs3 driver' in output, got: $out"
    exit 1
  fi

  if ! grep -q "mount -i -t ntfs3 -o noatime /dev/nvme0n1p2 $MNT_DIR" "$CALL_LOG"; then
    echo "FAIL: Expected 'mount -i -t ntfs3' call in log, got:"
    cat "$CALL_LOG"
    exit 1
  fi
  echo "  PASS: In-kernel ntfs3 driver prioritized when ntfs is legacy."
)

# -------------------------------------------------------------
# Test 3: Fallback to ntfs-3g when in-kernel drivers unavailable
# -------------------------------------------------------------
echo "[Test 3] Testing fallback to ntfs-3g..."
(
  TEST_DIR=$(mktemp -d)
  trap 'rm -rf "$TEST_DIR"' EXIT

  MOCK_BIN="$TEST_DIR/bin"
  mkdir -p "$MOCK_BIN"
  export PATH="$MOCK_BIN:$PATH"

  CALL_LOG="$TEST_DIR/calls.log"

  cat <<EOF > "$MOCK_BIN/modinfo"
#!/bin/bash
exit 1
EOF
  chmod +x "$MOCK_BIN/modinfo"

  cat <<EOF > "$MOCK_BIN/modprobe"
#!/bin/bash
exit 1
EOF
  chmod +x "$MOCK_BIN/modprobe"

  cat <<EOF > "$MOCK_BIN/ntfs-3g"
#!/bin/bash
echo "ntfs-3g \$*" >> "$CALL_LOG"
exit 0
EOF
  chmod +x "$MOCK_BIN/ntfs-3g"

  cat <<EOF > "$MOCK_BIN/mountpoint"
#!/bin/bash
exit 0
EOF
  chmod +x "$MOCK_BIN/mountpoint"

  MNT_DIR="$TEST_DIR/mnt"
  mkdir -p "$MNT_DIR"

  out=$(mount_ntfs_partition "/dev/sdb1" "$MNT_DIR" "noatime")
  if [[ "$out" != *"using ntfs-3g"* ]]; then
    echo "FAIL: Expected 'using ntfs-3g' in output, got: $out"
    exit 1
  fi

  if ! grep -q "ntfs-3g /dev/sdb1 $MNT_DIR -o noatime" "$CALL_LOG"; then
    echo "FAIL: Expected ntfs-3g call in log, got:"
    cat "$CALL_LOG"
    exit 1
  fi
  echo "  PASS: Gracefully falls back to ntfs-3g."
)

# -------------------------------------------------------------
# Test 4: Legacy read-only ntfs fails write check, falls back to ntfs-3g
# -------------------------------------------------------------
echo "[Test 4] Testing legacy read-only ntfs mount failure and fallback..."
(
  TEST_DIR=$(mktemp -d)
  trap 'rm -rf "$TEST_DIR"' EXIT

  MOCK_BIN="$TEST_DIR/bin"
  mkdir -p "$MOCK_BIN"
  export PATH="$MOCK_BIN:$PATH"

  CALL_LOG="$TEST_DIR/calls.log"

  cat <<EOF > "$MOCK_BIN/modprobe"
#!/bin/bash
if [ "\$1" = "ntfs" ]; then
  exit 0
fi
exit 1
EOF
  chmod +x "$MOCK_BIN/modprobe"

  # modinfo fails, simulating built-in legacy driver or missing modinfo
  cat <<EOF > "$MOCK_BIN/modinfo"
#!/bin/bash
exit 1
EOF
  chmod +x "$MOCK_BIN/modinfo"

  cat <<EOF > "$MOCK_BIN/mount"
#!/bin/bash
echo "mount \$*" >> "$CALL_LOG"
exit 0
EOF
  chmod +x "$MOCK_BIN/mount"

  cat <<EOF > "$MOCK_BIN/umount"
#!/bin/bash
echo "umount \$*" >> "$CALL_LOG"
exit 0
EOF
  chmod +x "$MOCK_BIN/umount"

  cat <<EOF > "$MOCK_BIN/mountpoint"
#!/bin/bash
exit 0
EOF
  chmod +x "$MOCK_BIN/mountpoint"

  cat <<EOF > "$MOCK_BIN/mktemp"
#!/bin/bash
# Simulate read-only filesystem where mktemp fails
exit 1
EOF
  chmod +x "$MOCK_BIN/mktemp"

  cat <<EOF > "$MOCK_BIN/ntfs-3g"
#!/bin/bash
echo "ntfs-3g \$*" >> "$CALL_LOG"
exit 0
EOF
  chmod +x "$MOCK_BIN/ntfs-3g"

  MNT_DIR="$TEST_DIR/mnt"
  mkdir -p "$MNT_DIR"

  out=$(mount_ntfs_partition "/dev/sda1" "$MNT_DIR" "noatime")

  # Verify umount was called on the failed read-only mount
  if ! grep -q "umount $MNT_DIR" "$CALL_LOG"; then
    echo "FAIL: Expected umount to be called when write test fails, got:"
    cat "$CALL_LOG"
    exit 1
  fi

  # Verify fallback to ntfs-3g
  if ! grep -q "ntfs-3g /dev/sda1 $MNT_DIR -o noatime" "$CALL_LOG"; then
    echo "FAIL: Expected fallback to ntfs-3g, got:"
    cat "$CALL_LOG"
    exit 1
  fi
  echo "  PASS: Unmounted read-only driver and successfully fell back to ntfs-3g."
)

# -------------------------------------------------------------
# Test 5: Read-only mount option (ro) skips write check
# -------------------------------------------------------------
echo "[Test 5] Testing read-only mount option (ro)..."
(
  TEST_DIR=$(mktemp -d)
  trap 'rm -rf "$TEST_DIR"' EXIT

  MOCK_BIN="$TEST_DIR/bin"
  mkdir -p "$MOCK_BIN"
  export PATH="$MOCK_BIN:$PATH"

  CALL_LOG="$TEST_DIR/calls.log"

  cat <<EOF > "$MOCK_BIN/modprobe"
#!/bin/bash
if [ "\$1" = "ntfs" ]; then
  exit 0
fi
exit 1
EOF
  chmod +x "$MOCK_BIN/modprobe"

  cat <<EOF > "$MOCK_BIN/modinfo"
#!/bin/bash
if [ "\$3" = "ntfs" ]; then
  echo "NTFS 1.2/3.x driver"
  exit 0
fi
exit 1
EOF
  chmod +x "$MOCK_BIN/modinfo"

  cat <<EOF > "$MOCK_BIN/mount"
#!/bin/bash
echo "mount \$*" >> "$CALL_LOG"
exit 0
EOF
  chmod +x "$MOCK_BIN/mount"

  cat <<EOF > "$MOCK_BIN/mountpoint"
#!/bin/bash
exit 0
EOF
  chmod +x "$MOCK_BIN/mountpoint"

  cat <<EOF > "$MOCK_BIN/mktemp"
#!/bin/bash
# Should NOT be called for ro mounts
echo "ERROR: mktemp should not be called for ro mounts!" >> "$CALL_LOG"
exit 1
EOF
  chmod +x "$MOCK_BIN/mktemp"

  MNT_DIR="$TEST_DIR/mnt"
  mkdir -p "$MNT_DIR"

  out=$(mount_ntfs_partition "/dev/sda1" "$MNT_DIR" "ro,noatime")
  if [[ "$out" != *"using in-kernel ntfs driver"* ]]; then
    echo "FAIL: Expected 'using in-kernel ntfs driver' in output, got: $out"
    exit 1
  fi

  if grep -q "ERROR: mktemp" "$CALL_LOG"; then
    echo "FAIL: mktemp was called for read-only mount"
    exit 1
  fi
  echo "  PASS: Read-only mount succeeds without write check."
)

# -------------------------------------------------------------
# Test 6: ocs-live-repository integration with NTFS filesystem
# -------------------------------------------------------------
echo "[Test 6] Testing ocs-live-repository integration with NTFS partition..."
(
  TEST_DIR=$(mktemp -d)
  trap 'rm -rf "$TEST_DIR"' EXIT

  MOCK_BIN="$TEST_DIR/bin"
  mkdir -p "$MOCK_BIN"
  export PATH="$MOCK_BIN:$PATH"

  CALL_LOG="$TEST_DIR/calls.log"
  touch "$CALL_LOG"
  mkdir -p /var/lib/clonezilla
  rm -f /var/lib/clonezilla/ocs-live-repository

  MOCK_CMDLINE="$TEST_DIR/cmdline"
  echo "ocs_repository=\"dev://$TEST_DIR/nvme0n1p3\"" > "$MOCK_CMDLINE"
  mknod "$TEST_DIR/nvme0n1p3" b 1 1

  cat <<EOF > "$MOCK_BIN/drbl-uriparse"
#!/bin/bash
if [ "\$2" = "path" ]; then
  echo "$TEST_DIR/nvme0n1p3"
elif [ "\$2" = "scheme" ]; then
  echo "dev"
fi
EOF
  chmod +x "$MOCK_BIN/drbl-uriparse"

  cat <<EOF > "$MOCK_BIN/ocs-get-dev-info"
#!/bin/bash
if [ "\$2" = "filesystem" ]; then
  echo "ntfs"
fi
EOF
  chmod +x "$MOCK_BIN/ocs-get-dev-info"

  cat <<EOF > "$MOCK_BIN/modinfo"
#!/bin/bash
if [ "\$1" = "-F" ] && [ "\$2" = "description" ] && [ "\$3" = "ntfs" ]; then
  echo "NTFS read-write filesystem driver"
  exit 0
fi
exit 1
EOF
  chmod +x "$MOCK_BIN/modinfo"

  cat <<EOF > "$MOCK_BIN/mount"
#!/bin/bash
echo "mount \$*" >> "$CALL_LOG"
exit 0
EOF
  chmod +x "$MOCK_BIN/mount"

  cat <<EOF > "$MOCK_BIN/mountpoint"
#!/bin/bash
exit 0
EOF
  chmod +x "$MOCK_BIN/mountpoint"

  cat <<EOF > "$MOCK_BIN/findmnt"
#!/bin/bash
exit 1
EOF
  chmod +x "$MOCK_BIN/findmnt"

  cat <<EOF > "$MOCK_BIN/mktemp"
#!/bin/bash
target="\$1"
file="\${target%XXXXXX}123456"
touch "\$file"
echo "\$file"
exit 0
EOF
  chmod +x "$MOCK_BIN/mktemp"

  check_if_root() { return 0; }
  ask_and_load_lang_set() { return 0; }
  prepare_mnt_point_ocsroot() { return 0; }
  check_if_ocsroot_a_mountpoint() { return 0; }
  export -f check_if_root ask_and_load_lang_set prepare_mnt_point_ocsroot check_if_ocsroot_a_mountpoint

  MOCK_DRBL="$TEST_DIR/drbl"
  mkdir -p "$MOCK_DRBL"
  if [ -d "/usr/share/drbl" ]; then
    cp -a /usr/share/drbl/* "$MOCK_DRBL/"
  fi
  mkdir -p "$MOCK_DRBL/sbin"
  cp -a "$SCRIPT_DIR/scripts/sbin/"* "$MOCK_DRBL/sbin/"
  export DRBL_SCRIPT_PATH="$MOCK_DRBL"

  export ocsroot="$TEST_DIR/partimag"
  export ocsroot_def_mnt_opt="noatime"
  export ocs_repository="dev://$TEST_DIR/nvme0n1p3"
  export ocsroot_src="local_dev"
  mkdir -p "$ocsroot"

  repo_ret=0
  bash "$SCRIPT_DIR/sbin/ocs-live-repository" -f -c "$MOCK_CMDLINE" -s > "$TEST_DIR/repo.out" 2>&1 || repo_ret=$?
  if [ $repo_ret -ne 0 ]; then
    echo "ocs-live-repository exited with code $repo_ret. Output:"
    cat "$TEST_DIR/repo.out"
  fi

  if ! grep -q "mount -i -t ntfs -o noatime $TEST_DIR/nvme0n1p3" "$CALL_LOG"; then
    echo "FAIL: Expected 'mount -i -t ntfs' via mount_ntfs_partition in ocs-live-repository, got:"
    cat "$CALL_LOG"
    cat "$TEST_DIR/repo.out"
    exit 1
  fi
  echo "  PASS: ocs-live-repository seamlessly mounts NTFS repository using prioritized in-kernel driver."
)

echo "=== All NTFS Mount Logic Tests Passed! ==="
