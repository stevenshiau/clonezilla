#!/bin/bash
# Standalone test for gen_checksums_for_img_if_assigned and check_checksums_for_img in Clonezilla

set -e

echo "=== Running Image Checksum Generation Tests ==="

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
export DRBL_SCRIPT_PATH="/usr/share/drbl"
. "$SCRIPT_DIR/conf/drbl-ocs.conf"
. "$SCRIPT_DIR/scripts/sbin/ocs-functions"

TMP_TEST_DIR=$(mktemp -d /tmp/test-gen-cksum.XXXXXX)
trap 'rm -rf "$TMP_TEST_DIR"' EXIT

export OCS_LOGFILE="$TMP_TEST_DIR/ocs.log"
touch "$OCS_LOGFILE"

# Populate test image directory with typical Clonezilla image files
IMG_DIR="$TMP_TEST_DIR/sample-img"
mkdir -p "$IMG_DIR"

echo "disk=sda" > "$IMG_DIR/disk"
echo "parts=sda1 sda2" > "$IMG_DIR/parts"
echo "label=test" > "$IMG_DIR/sda-pt.sf"
echo "file with spaces content" > "$IMG_DIR/file with spaces.txt"
mkdir -p "$IMG_DIR/subdir_to_ignore"
echo "ignored" > "$IMG_DIR/subdir_to_ignore/dummy.txt"

for i in {1..5}; do
  head -c 1024 /dev/urandom > "$IMG_DIR/sda1.ext4-img.a$i"
done

# -------------------------------------------------------------
# Test 1: Single checksum algorithm (MD5SUMS)
# -------------------------------------------------------------
echo "[Test 1] Testing single checksum generation (MD5SUMS)..."
(
  gen_md5sum="yes"
  gen_sha1sum="no"
  gen_b2sum="no"
  gen_b3sum="no"

  gen_checksums_for_img_if_assigned "$IMG_DIR"

  if [ ! -f "$IMG_DIR/MD5SUMS" ]; then
    echo "FAIL: MD5SUMS was not generated!"
    exit 1
  fi

  # Check that subdir files are not in MD5SUMS
  if grep -q "subdir_to_ignore" "$IMG_DIR/MD5SUMS"; then
    echo "FAIL: Subdirectory was erroneously included in MD5SUMS!"
    exit 1
  fi

  # Check that MD5SUMS does not contain itself
  if grep -q "MD5SUMS" "$IMG_DIR/MD5SUMS"; then
    echo "FAIL: MD5SUMS contains itself!"
    exit 1
  fi

  # Verify with check_checksums_for_img
  check_md5sum="yes"
  check_checksums_for_img "$IMG_DIR"
  echo "  PASS: MD5SUMS generated and verified successfully."
)

# -------------------------------------------------------------
# Test 2: B3SUM generation (with RAYON_NUM_THREADS protection)
# -------------------------------------------------------------
echo "[Test 2] Testing B3SUMS generation and verification..."
(
  gen_md5sum="no"
  gen_sha1sum="no"
  gen_b2sum="no"
  gen_b3sum="yes"

  gen_checksums_for_img_if_assigned "$IMG_DIR"

  if [ ! -f "$IMG_DIR/B3SUMS" ]; then
    echo "FAIL: B3SUMS was not generated!"
    exit 1
  fi

  check_b3sum="yes"
  check_checksums_for_img "$IMG_DIR"
  echo "  PASS: B3SUMS generated and verified successfully."
)

# -------------------------------------------------------------
# Test 3: Multiple checksum algorithms simultaneously (SHA1 and B2)
# -------------------------------------------------------------
echo "[Test 3] Testing multiple checksum algorithms (SHA1SUMS and B2SUMS)..."
(
  gen_md5sum="no"
  gen_sha1sum="yes"
  gen_b2sum="yes"
  gen_b3sum="no"

  gen_checksums_for_img_if_assigned "$IMG_DIR"

  if [ ! -f "$IMG_DIR/SHA1SUMS" ] || [ ! -f "$IMG_DIR/B2SUMS" ]; then
    echo "FAIL: SHA1SUMS or B2SUMS was not generated!"
    exit 1
  fi

  check_sha1sum="yes"
  check_b2sum="yes"
  check_checksums_for_img "$IMG_DIR"
  echo "  PASS: Multiple checksums generated and verified successfully."
)

# -------------------------------------------------------------
# Test 4: Spaces in filenames are preserved and verified
# -------------------------------------------------------------
echo "[Test 4] Testing spaces in filenames..."
(
  if ! grep -q "file with spaces.txt" "$IMG_DIR/MD5SUMS"; then
    echo "FAIL: file with spaces.txt not found in MD5SUMS!"
    exit 1
  fi
  (cd "$IMG_DIR" && md5sum -c MD5SUMS > /dev/null 2>&1)
  echo "  PASS: Files with spaces in names handled cleanly."
)

# -------------------------------------------------------------
# Test 5: Return code 5 when no checksum is assigned
# -------------------------------------------------------------
echo "[Test 5] Testing return code when no checksum is assigned..."
(
  gen_md5sum="no"
  gen_sha1sum="no"
  gen_b2sum="no"
  gen_b3sum="no"

  ret=0
  gen_checksums_for_img_if_assigned "$IMG_DIR" || ret=$?

  if [ "$ret" -ne 5 ]; then
    echo "FAIL: Expected return code 5, got $ret"
    exit 1
  fi
  echo "  PASS: Correctly returned 5 when no checksum was assigned."
)

echo "=== All Image Checksum Generation Tests Passed! ==="
