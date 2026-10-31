#!/bin/bash
# Standalone test for get_existing_disk_image and get_existing_parts_image in Clonezilla

set -e

echo "=== Running Image Search Optimization Tests ==="

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
export DRBL_SCRIPT_PATH="/usr/share/drbl"
. "$SCRIPT_DIR/conf/drbl-ocs.conf"
. "$SCRIPT_DIR/scripts/sbin/ocs-functions"

TMP_TEST_DIR=$(mktemp -d /tmp/test-img-search.XXXXXX)
export TMP_TEST_DIR
trap 'rm -rf "$TMP_TEST_DIR"' EXIT

export imagedir="$TMP_TEST_DIR/repo"
mkdir -p "$imagedir"

export OCS_LOGFILE="$TMP_TEST_DIR/ocs.log"
touch "$OCS_LOGFILE"

# Mock dialog program $DIA
DIA_MOCK="$TMP_TEST_DIR/mock_dia.sh"
cat <<'EOF' > "$DIA_MOCK"
#!/bin/bash
# Shift past dialog title/menu/width/height flags to get the first menu tag
shift 9
first_item="$1"
# Echo the selected item to stderr (like dialog does for the selected tag)
echo "$first_item" >&2
exit 0
EOF
chmod +x "$DIA_MOCK"
export DIA="$DIA_MOCK"

ANS_TMP="$TMP_TEST_DIR/ans.tmp"

# Create test images:
# 1. Standard disk image (disk: sda, sda-pt.parted.compact)
mkdir -p "$imagedir/disk-img-standard"
echo "sda" > "$imagedir/disk-img-standard/disk"
cat <<'EOF' > "$imagedir/disk-img-standard/sda-pt.parted.compact"
Model: Test Disk (scsi)
Disk /dev/sda: 256GB
Sector size (logical/physical): 512B/512B
EOF

# 2. Multi-disk image (disk: sda nvme0n1)
mkdir -p "$imagedir/disk-img-multi"
echo "sda nvme0n1" > "$imagedir/disk-img-multi/disk"
cat <<'EOF' > "$imagedir/disk-img-multi/sda-pt.parted.compact"
Disk /dev/sda: 500GB
EOF
cat <<'EOF' > "$imagedir/disk-img-multi/nvme0n1-pt.parted.compact"
Disk /dev/nvme0n1: 1000GB
EOF

# 3. Partition-only image (parts: sda1 sda2, no disk file)
mkdir -p "$imagedir/parts-img-only"
echo "sda1 sda2" > "$imagedir/parts-img-only/parts"

# 4. Checksum image (parts + *sum.info file)
mkdir -p "$imagedir/checksum-img"
echo "sda1" > "$imagedir/checksum-img/parts"
touch "$imagedir/checksum-img/sda1.files-md5sum.info.gz"

# 5. Pseudo image (should be skipped by get_existing_disk_image)
mkdir -p "$imagedir/pseudo-img"
echo "sda" > "$imagedir/pseudo-img/disk"
touch "$imagedir/pseudo-img/00-pseudo-img-note.txt"

# 6. Encrypted image simulation
mkdir -p "$imagedir/enc-img"
echo "sda" > "$imagedir/enc-img/disk"
echo "time_of_img=2026-1031-1200" > "$imagedir/enc-img/ecryptfs.info"
echo "disk_of_img=sda" >> "$imagedir/enc-img/ecryptfs.info"
echo "disks_size_all_of_img=_500GB" >> "$imagedir/enc-img/ecryptfs.info"

# 7. Non-image file and empty folder
touch "$imagedir/random-file.iso"
mkdir -p "$imagedir/empty-directory"

# -------------------------------------------------------------
# Test 1: get_existing_disk_image finds disk images and ignores others
# -------------------------------------------------------------
echo "[Test 1] Testing get_existing_disk_image..."
(
  get_existing_disk_image "$ANS_TMP"

  chosen="$(cat "$ANS_TMP")"
  if [ -z "$chosen" ]; then
    echo "FAIL: No disk image was selected!"
    exit 1
  fi
  echo "  PASS: get_existing_disk_image successfully discovered images and selected: $chosen"
)

# -------------------------------------------------------------
# Test 2: get_existing_disk_image with rest-unenc excludes encrypted image
# -------------------------------------------------------------
echo "[Test 2] Testing get_existing_disk_image in rest-unenc mode..."
(
  # Override DIA to inspect full list
  DIA_INSPECT="$TMP_TEST_DIR/mock_dia_inspect.sh"
  cat <<EOF > "$DIA_INSPECT"
#!/bin/bash
echo "\$@" > "$TMP_TEST_DIR/dia_args.txt"
echo "\$8" >&2
exit 0
EOF
  chmod +x "$DIA_INSPECT"
  export DIA="$DIA_INSPECT"

  get_existing_disk_image "$ANS_TMP" "rest-unenc"

  args="$(cat "$TMP_TEST_DIR/dia_args.txt")"
  if grep -q "enc-img" <<< "$args"; then
    echo "FAIL: Encrypted image enc-img was included in rest-unenc mode!"
    exit 1
  fi

  if ! grep -q "disk-img-standard" <<< "$args"; then
    echo "FAIL: Standard disk image was missing in rest-unenc mode!"
    exit 1
  fi

  if grep -q "pseudo-img" <<< "$args"; then
    echo "FAIL: Pseudo image was included in disk image list!"
    exit 1
  fi

  if grep -q "parts-img-only" <<< "$args"; then
    echo "FAIL: Partition-only image was erroneously included in disk image list!"
    exit 1
  fi
  echo "  PASS: rest-unenc mode correctly filters out encrypted, pseudo, and partition-only images."
)

# -------------------------------------------------------------
# Test 3: get_existing_parts_image finds partition images
# -------------------------------------------------------------
echo "[Test 3] Testing get_existing_parts_image..."
(
  DIA_INSPECT="$TMP_TEST_DIR/mock_dia_inspect.sh"
  export DIA="$DIA_INSPECT"

  get_existing_parts_image "$ANS_TMP"

  args="$(cat "$TMP_TEST_DIR/dia_args.txt")"
  if ! grep -q "parts-img-only" <<< "$args"; then
    echo "FAIL: parts-img-only was missing in parts image list!"
    exit 1
  fi

  if ! grep -q "disk-img-standard" <<< "$args"; then
    echo "FAIL: disk-img-standard was missing in parts image list!"
    exit 1
  fi
  echo "  PASS: get_existing_parts_image correctly discovered all valid image directories."
)

# -------------------------------------------------------------
# Test 4: get_existing_parts_image with checksum mode
# -------------------------------------------------------------
echo "[Test 4] Testing get_existing_parts_image in checksum mode..."
(
  DIA_INSPECT="$TMP_TEST_DIR/mock_dia_inspect.sh"
  export DIA="$DIA_INSPECT"

  get_existing_parts_image "$ANS_TMP" "checksum"

  args="$(cat "$TMP_TEST_DIR/dia_args.txt")"
  if ! grep -q "checksum-img" <<< "$args"; then
    echo "FAIL: checksum-img was missing in checksum mode!"
    exit 1
  fi

  if grep -q "disk-img-standard" <<< "$args"; then
    echo "FAIL: Image without checksum files was erroneously included in checksum mode!"
    exit 1
  fi
  echo "  PASS: checksum mode correctly filters only images containing checksum files."
)

# -------------------------------------------------------------
# Test 5: to_filename, to_dev_name, and to_sysblock_name builtins
# -------------------------------------------------------------
echo "[Test 5] Testing to_filename, to_dev_name, and to_sysblock_name..."
(
  res_fn="$(to_filename "cciss/c0d0")"
  if [ "$res_fn" != "cciss-c0d0" ]; then
    echo "FAIL: Expected 'cciss-c0d0', got: '$res_fn'"
    exit 1
  fi

  res_dev="$(to_dev_name "cciss!c0d0")"
  if [ "$res_dev" != "cciss/c0d0" ]; then
    echo "FAIL: Expected 'cciss/c0d0', got: '$res_dev'"
    exit 1
  fi

  res_sys="$(to_sysblock_name "cciss/c0d0")"
  if [ "$res_sys" != "cciss!c0d0" ]; then
    echo "FAIL: Expected 'cciss!c0d0', got: '$res_sys'"
    exit 1
  fi
  echo "  PASS: Path and device string transformations verified."
)

echo "=== All Image Search Optimization Tests Passed! ==="
