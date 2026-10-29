#!/bin/bash
# test-dd-compression.sh: Verify that dd mode (-q1 / FORCE_TO_USE_DD="yes")
# properly supports compression formats (e.g. zstd, xz, lz4, zxc, kanzi)
# without erroneously falling back to gzip.
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

echo "=== Running Clonezilla dd Mode Compression Tests ==="

TMP_DIR=$(mktemp -d /tmp/test-dd-comp.XXXXXX)
trap 'rm -rf "$TMP_DIR"' EXIT

# Mock DRBL environment and source required Clonezilla files
export DRBL_SCRIPT_PATH="$REPO_DIR"
export OCS_LOGFILE="$TMP_DIR/ocs.log"
touch "$OCS_LOGFILE"

source "$REPO_DIR/conf/drbl-ocs.conf"
source "$REPO_DIR/scripts/sbin/ocs-functions"

# -------------------------------------------------------------
# Test 1: Verify zstd compression in dd mode (FORCE_TO_USE_DD="yes")
# -------------------------------------------------------------
echo "[Test 1] Testing zstd in dd mode (FORCE_TO_USE_DD='yes', USE_PARTCLONE='no')..."
(
  mkdir -p "$TMP_DIR/bin_zstd"
  echo '#!/bin/sh' > "$TMP_DIR/bin_zstd/zstd"
  chmod +x "$TMP_DIR/bin_zstd/zstd"
  export PATH="$TMP_DIR/bin_zstd:$PATH"

  IMG_CLONE_CMP="zstd -c -T0 -3"
  USE_PARTCLONE="no"
  FORCE_TO_USE_DD="yes"
  VOL_LIMIT=0
  check_ocs_input_params >/dev/null 2>&1
  if [[ "$IMG_CLONE_CMP" != *"zstd"* ]]; then
    echo "FAIL: Expected zstd to be kept in dd mode, got: $IMG_CLONE_CMP"
    exit 1
  fi
)
echo "  PASS: zstd is preserved in dd mode."

# -------------------------------------------------------------
# Test 2: Verify xz compression in dd mode
# -------------------------------------------------------------
echo "[Test 2] Testing xz in dd mode..."
(
  mkdir -p "$TMP_DIR/bin_xz"
  echo '#!/bin/sh' > "$TMP_DIR/bin_xz/xz"
  chmod +x "$TMP_DIR/bin_xz/xz"
  export PATH="$TMP_DIR/bin_xz:$PATH"

  IMG_CLONE_CMP="xz -c -3"
  USE_PARTCLONE="no"
  FORCE_TO_USE_DD="yes"
  VOL_LIMIT=0
  check_ocs_input_params >/dev/null 2>&1
  if [[ "$IMG_CLONE_CMP" != *"xz"* ]]; then
    echo "FAIL: Expected xz to be kept in dd mode, got: $IMG_CLONE_CMP"
    exit 1
  fi
)
echo "  PASS: xz is preserved in dd mode."

# -------------------------------------------------------------
# Test 3: Verify lz4 compression in dd mode
# -------------------------------------------------------------
echo "[Test 3] Testing lz4 in dd mode..."
(
  mkdir -p "$TMP_DIR/bin_lz4"
  echo '#!/bin/sh' > "$TMP_DIR/bin_lz4/lz4"
  chmod +x "$TMP_DIR/bin_lz4/lz4"
  export PATH="$TMP_DIR/bin_lz4:$PATH"

  IMG_CLONE_CMP="lz4 -c -T0 -1"
  USE_PARTCLONE="no"
  FORCE_TO_USE_DD="yes"
  VOL_LIMIT=0
  check_ocs_input_params >/dev/null 2>&1
  if [[ "$IMG_CLONE_CMP" != *"lz4"* ]]; then
    echo "FAIL: Expected lz4 to be kept in dd mode, got: $IMG_CLONE_CMP"
    exit 1
  fi
)
echo "  PASS: lz4 is preserved in dd mode."

# -------------------------------------------------------------
# Test 4: Verify zxc compression in dd mode
# -------------------------------------------------------------
echo "[Test 4] Testing zxc in dd mode..."
(
  mkdir -p "$TMP_DIR/bin_zxc"
  echo '#!/bin/sh' > "$TMP_DIR/bin_zxc/zxc"
  chmod +x "$TMP_DIR/bin_zxc/zxc"
  export PATH="$TMP_DIR/bin_zxc:$PATH"

  IMG_CLONE_CMP="zxc -c -T0 -3"
  USE_PARTCLONE="no"
  FORCE_TO_USE_DD="yes"
  VOL_LIMIT=0
  check_ocs_input_params >/dev/null 2>&1
  if [[ "$IMG_CLONE_CMP" != *"zxc"* ]]; then
    echo "FAIL: Expected zxc to be kept in dd mode, got: $IMG_CLONE_CMP"
    exit 1
  fi
)
echo "  PASS: zxc is preserved in dd mode."

# -------------------------------------------------------------
# Test 5: Verify kanzi compression in dd mode
# -------------------------------------------------------------
echo "[Test 5] Testing kanzi in dd mode..."
(
  mkdir -p "$TMP_DIR/bin_kanzi"
  echo '#!/bin/sh' > "$TMP_DIR/bin_kanzi/kanzi"
  chmod +x "$TMP_DIR/bin_kanzi/kanzi"
  export PATH="$TMP_DIR/bin_kanzi:$PATH"

  IMG_CLONE_CMP="kanzi -c -o stdout -j 0 -l 3"
  USE_PARTCLONE="no"
  FORCE_TO_USE_DD="yes"
  VOL_LIMIT=0
  check_ocs_input_params >/dev/null 2>&1
  if [[ "$IMG_CLONE_CMP" != *"kanzi"* ]]; then
    echo "FAIL: Expected kanzi to be kept in dd mode, got: $IMG_CLONE_CMP"
    exit 1
  fi
)
echo "  PASS: kanzi is preserved in dd mode."

# -------------------------------------------------------------
# Test 6: Verify fallback to gzip if compressor is not installed even in dd mode
# -------------------------------------------------------------
echo "[Test 6] Testing missing compressor fallback to gzip in dd mode..."
(
  # Test with zxc (which is not installed in the test environment)
  IMG_CLONE_CMP="zxc -c -T0 -3"
  USE_PARTCLONE="no"
  FORCE_TO_USE_DD="yes"
  VOL_LIMIT=0
  check_ocs_input_params >/dev/null 2>&1
  if [[ "$IMG_CLONE_CMP" != *"gzip"* ]]; then
    echo "FAIL: Expected missing compressor to fall back to gzip, got: $IMG_CLONE_CMP"
    exit 1
  fi
)
echo "  PASS: Missing compressor correctly falls back to gzip in dd mode."

# -------------------------------------------------------------
# Test 7: Verify fallback to gzip when NEITHER partclone NOR dd is selected (partimage mode)
# -------------------------------------------------------------
echo "[Test 7] Testing partimage mode fallback (USE_PARTCLONE='no', FORCE_TO_USE_DD='no')..."
(
  mkdir -p "$TMP_DIR/bin_zstd2"
  echo '#!/bin/sh' > "$TMP_DIR/bin_zstd2/zstd"
  chmod +x "$TMP_DIR/bin_zstd2/zstd"
  export PATH="$TMP_DIR/bin_zstd2:$PATH"

  IMG_CLONE_CMP="zstd -c -T0 -3"
  USE_PARTCLONE="no"
  FORCE_TO_USE_DD="no"
  VOL_LIMIT=0
  check_ocs_input_params >/dev/null 2>&1
  if [[ "$IMG_CLONE_CMP" != *"gzip"* ]]; then
    echo "FAIL: Expected partimage mode to fall back to gzip, got: $IMG_CLONE_CMP"
    exit 1
  fi
)
echo "  PASS: Non-partclone and non-dd mode correctly falls back to gzip."

# -------------------------------------------------------------
# Test 8: Verify ocs-sr command-line option -q1 with -z9p
# -------------------------------------------------------------
echo "[Test 8] Testing ocs-sr option parsing with -q1 and -z9p..."
(
  # Test option parsing directly
  FORCE_TO_USE_DD="no"
  USE_PARTCLONE=""
  IMG_CLONE_CMP=""
  
  # Source parsing functions and simulate ocs-sr option processing
  extra_zstd_opt="-T0 -3"
  set -- -q1 -z9p
  while [ $# -gt 0 ]; do
    case "$1" in
      -q1|--force-to-use-dd)
        FORCE_TO_USE_DD="yes"
        shift;;
      -z9p|--zstdmt-compress)
        IMG_CLONE_CMP="zstd -c $extra_zstd_opt"
        shift;;
      *)
        shift;;
    esac
  done

  if [ "$FORCE_TO_USE_DD" != "yes" ]; then
    echo "FAIL: FORCE_TO_USE_DD should be yes"
    exit 1
  fi

  # Mock zstd binary
  mkdir -p "$TMP_DIR/bin_zstd3"
  echo '#!/bin/sh' > "$TMP_DIR/bin_zstd3/zstd"
  chmod +x "$TMP_DIR/bin_zstd3/zstd"
  export PATH="$TMP_DIR/bin_zstd3:$PATH"

  VOL_LIMIT=0
  check_ocs_input_params >/dev/null 2>&1
  if [[ "$IMG_CLONE_CMP" != *"zstd"* ]]; then
    echo "FAIL: Expected zstd to remain after check_ocs_input_params, got: $IMG_CLONE_CMP"
    exit 1
  fi
)
echo "  PASS: ocs-sr -q1 -z9p keeps zstd after check_ocs_input_params."

echo "=== All dd Mode Compression Tests Passed Successfully! ==="
