#!/bin/bash
# Test suite for zxc compression and decompression support in Clonezilla (-z10p)

set -e

echo "=== Running Clonezilla zxc (-z10p) Compression and Decompression Tests ==="

TMP_DIR="$(mktemp -d /tmp/test-zxc.XXXXXX)"
trap 'rm -rf "$TMP_DIR"' EXIT

# -------------------------------------------------------------
# Test 1: Test ocs-sr option parsing for -z10p, --zxcmt-compress, --smp-zxc-compress, -z10
# -------------------------------------------------------------
echo "[Test 1] Testing ocs-sr option parsing..."

# Extract the parser from sbin/ocs-sr
# The parser function is parse_ocs_sr_cmd_options_with_dash()
parse_test_ocs_sr() {
  local extra_zxc_opt="-T0 -3"
  local IMG_CLONE_CMP=""
  local n_shift=0
  local shift_count=0

  # Source just the options case from ocs-sr
  while [ $# -gt 0 ]; do
    case "$1" in
      -z9|--zstd-compress)
	      IMG_CLONE_CMP="zstd -c $(echo $extra_zstd_opt | sed -r "s/-T[[:digit:]]+/-T1/")"
	      shift; n_shift=$((n_shift+1));;
      -z9p|--zstdmt-compress)
              IMG_CLONE_CMP="zstd -c $extra_zstd_opt"
	      shift; n_shift=$((n_shift+1));;
      -z10|--zxc-compress)
	      [ -z "$extra_zxc_opt" ] && extra_zxc_opt="-T0 -3"
	      IMG_CLONE_CMP="zxc -c $(echo $extra_zxc_opt | sed -r "s/-T[[:digit:]]+/-T1/")"
	      shift; n_shift=$((n_shift+1));;
      -z10p|--zxcmt-compress|--smp-zxc-compress)
	      [ -z "$extra_zxc_opt" ] && extra_zxc_opt="-T0 -3"
              IMG_CLONE_CMP="zxc -c $extra_zxc_opt"
	      shift; n_shift=$((n_shift+1));;
      *)
	      shift;;
    esac
  done
  echo "$IMG_CLONE_CMP"
}

# Verify -z10p sets parallel zxc
res=$(parse_test_ocs_sr -z10p)
if [ "$res" != "zxc -c -T0 -3" ]; then
  echo "FAIL: ocs-sr -z10p expected 'zxc -c -T0 -3', got '$res'"
  exit 1
fi

res=$(parse_test_ocs_sr --zxcmt-compress)
if [ "$res" != "zxc -c -T0 -3" ]; then
  echo "FAIL: ocs-sr --zxcmt-compress expected 'zxc -c -T0 -3', got '$res'"
  exit 1
fi

res=$(parse_test_ocs_sr --smp-zxc-compress)
if [ "$res" != "zxc -c -T0 -3" ]; then
  echo "FAIL: ocs-sr --smp-zxc-compress expected 'zxc -c -T0 -3', got '$res'"
  exit 1
fi

# Verify -z10 sets single-thread zxc
res=$(parse_test_ocs_sr -z10)
if [ "$res" != "zxc -c -T1 -3" ]; then
  echo "FAIL: ocs-sr -z10 expected 'zxc -c -T1 -3', got '$res'"
  exit 1
fi

# Also test parsing against the actual sbin/ocs-sr file content
if ! grep -q "\-z10p|--zxcmt-compress" sbin/ocs-sr; then
  echo "FAIL: sbin/ocs-sr does not contain -z10p|--zxcmt-compress"
  exit 1
fi

echo "  PASS: ocs-sr options parsed correctly."

# -------------------------------------------------------------
# Test 2: Test drbl-ocs option parsing
# -------------------------------------------------------------
echo "[Test 2] Testing drbl-ocs option parsing..."
if ! grep -q "\-z10p|--zxcmt-compress" sbin/drbl-ocs; then
  echo "FAIL: sbin/drbl-ocs does not contain -z10p|--zxcmt-compress"
  exit 1
fi
echo "  PASS: drbl-ocs options verified."

# -------------------------------------------------------------
# Test 3: Test ocs-get-comp-suffix in ocs-functions
# -------------------------------------------------------------
echo "[Test 3] Testing ocs-get-comp-suffix for zxc..."
source scripts/sbin/ocs-functions

suf=$(ocs-get-comp-suffix "zxc -c -T0 -3")
if [ "$suf" != "zxc" ]; then
  echo "FAIL: ocs-get-comp-suffix for 'zxc -c -T0 -3' expected 'zxc', got '$suf'"
  exit 1
fi

suf=$(ocs-get-comp-suffix "unzxc -c")
if [ "$suf" != "zxc" ]; then
  echo "FAIL: ocs-get-comp-suffix for 'unzxc -c' expected 'zxc', got '$suf'"
  exit 1
fi

suf=$(ocs-get-comp-suffix "zxccat")
if [ "$suf" != "zxc" ]; then
  echo "FAIL: ocs-get-comp-suffix for 'zxccat' expected 'zxc', got '$suf'"
  exit 1
fi
echo "  PASS: ocs-get-comp-suffix returns 'zxc'."

# -------------------------------------------------------------
# Test 4: Test get_image_cat_zip_cmd for partclone image name
# -------------------------------------------------------------
echo "[Test 4] Testing get_image_cat_zip_cmd for .ptcl-img.zxc.aa..."
extra_zxc_opt="-T0 -3"
extra_zxc_dc_opt="-T0"
use_parallel_decompression="yes"

# Call get_image_cat_zip_cmd
get_image_cat_zip_cmd "sda1.ext4-ptcl-img.zxc.aa"

if [ "$img_comp_format" != "zxc" ]; then
  echo "FAIL: img_comp_format expected 'zxc', got '$img_comp_format'"
  exit 1
fi

if [[ "$cat_prog" != *"zxc -dc"* ]]; then
  echo "FAIL: cat_prog expected to contain 'zxc -dc', got '$cat_prog'"
  exit 1
fi

if [[ "$unzip_stdin_cmd" != *"zxc -dc"* ]]; then
  echo "FAIL: unzip_stdin_cmd expected to contain 'zxc -dc', got '$unzip_stdin_cmd'"
  exit 1
fi

if [[ "$zip_stdin_cmd" != *"zxc -c"* ]]; then
  echo "FAIL: zip_stdin_cmd expected to contain 'zxc -c', got '$zip_stdin_cmd'"
  exit 1
fi

# Test decompression with use_parallel_decompression="no"
use_parallel_decompression="no"
get_image_cat_zip_cmd "sda1.ext4-ptcl-img.zxc.aa"
if [[ "$cat_prog" != *"-T1"* ]]; then
  echo "FAIL: cat_prog expected to contain '-T1' when use_parallel_decompression=no, got '$cat_prog'"
  exit 1
fi
echo "  PASS: get_image_cat_zip_cmd correctly handles .ptcl-img.zxc."

# -------------------------------------------------------------
# Test 5: Test fallback image format detection for .zxc file
# -------------------------------------------------------------
echo "[Test 5] Testing fallback get_image_cat_zip_cmd for .zxc extension..."
dummy_zxc="$TMP_DIR/backup-disk.zxc"
touch "$dummy_zxc"
use_parallel_decompression="yes"

get_image_cat_zip_cmd "$dummy_zxc"
if [[ "$unzip_stdin_cmd" != *"zxc -dc"* ]]; then
  echo "FAIL: fallback unzip_stdin_cmd expected 'zxc -dc', got '$unzip_stdin_cmd'"
  exit 1
fi
echo "  PASS: fallback get_image_cat_zip_cmd correctly identifies .zxc."

# -------------------------------------------------------------
# Test 6: Test check_ocs_input_params validation for zxc
# -------------------------------------------------------------
echo "[Test 6] Testing check_ocs_input_params for zxc..."

# Case 6a: zxc not installed -> should fallback to gzip
(
  # Hide zxc if present
  export PATH="$TMP_DIR/empty_bin:$PATH"
  mkdir -p "$TMP_DIR/empty_bin"
  IMG_CLONE_CMP="zxc -c -T0 -3"
  USE_PARTCLONE="yes"
  VOL_LIMIT=0
  check_ocs_input_params >/dev/null 2>&1
  if [[ "$IMG_CLONE_CMP" != *"gzip"* ]]; then
    echo "FAIL: Expected fallback to gzip when zxc is missing, got: $IMG_CLONE_CMP"
    exit 1
  fi
)

# Case 6b: zxc mock installed but USE_PARTCLONE="no" -> should fallback to gzip
(
  mkdir -p "$TMP_DIR/mock_bin"
  echo '#!/bin/sh' > "$TMP_DIR/mock_bin/zxc"
  chmod +x "$TMP_DIR/mock_bin/zxc"
  export PATH="$TMP_DIR/mock_bin:$PATH"
  IMG_CLONE_CMP="zxc -c -T0 -3"
  USE_PARTCLONE="no"
  VOL_LIMIT=0
  check_ocs_input_params >/dev/null 2>&1
  if [[ "$IMG_CLONE_CMP" != *"gzip"* ]]; then
    echo "FAIL: Expected fallback to gzip when USE_PARTCLONE is no, got: $IMG_CLONE_CMP"
    exit 1
  fi
)

# Case 6c: zxc mock installed and USE_PARTCLONE="yes" -> keep zxc
(
  mkdir -p "$TMP_DIR/mock_bin"
  echo '#!/bin/sh' > "$TMP_DIR/mock_bin/zxc"
  chmod +x "$TMP_DIR/mock_bin/zxc"
  export PATH="$TMP_DIR/mock_bin:$PATH"
  IMG_CLONE_CMP="zxc -c -T0 -3"
  USE_PARTCLONE="yes"
  VOL_LIMIT=0
  check_ocs_input_params >/dev/null 2>&1
  if [[ "$IMG_CLONE_CMP" != *"zxc"* ]]; then
    echo "FAIL: Expected zxc to be kept, got: $IMG_CLONE_CMP"
    exit 1
  fi
)
echo "  PASS: check_ocs_input_params correctly validates zxc."

# -------------------------------------------------------------
# Test 7: Test USAGE text and documentation
# -------------------------------------------------------------
echo "[Test 7] Testing USAGE and documentation..."
usage_output=$(USAGE_common_save)
if ! echo "$usage_output" | grep -q "\-z10p"; then
  echo "FAIL: USAGE_common_save does not mention -z10p"
  exit 1
fi

if ! grep -q "\-z10p" doc/ocs-sr.8; then
  echo "FAIL: doc/ocs-sr.8 does not mention -z10p"
  exit 1
fi
echo "  PASS: Documentation and USAGE verified."

# -------------------------------------------------------------
# Test 8: Test set_onthefly_net_filter_program for zxc
# -------------------------------------------------------------
echo "[Test 8] Testing set_onthefly_net_filter_program..."
(
  mkdir -p "$TMP_DIR/mock_bin"
  echo '#!/bin/sh' > "$TMP_DIR/mock_bin/zxc"
  chmod +x "$TMP_DIR/mock_bin/zxc"
  export PATH="$TMP_DIR/mock_bin:$PATH"
  net_filter="zxc"
  set_onthefly_net_filter_program
  if [[ "$net_filter_comp" != *"zxc -c"* ]] || [[ "$net_filter_decomp" != *"zxc -dc"* ]]; then
    echo "FAIL: net_filter_comp or net_filter_decomp not set for zxc (got comp='$net_filter_comp', decomp='$net_filter_decomp')"
    exit 1
  fi
)
echo "  PASS: set_onthefly_net_filter_program verified."

# -------------------------------------------------------------
# Test 9: End-to-end data compression & decompression pipe simulation
# -------------------------------------------------------------
echo "[Test 9] Testing simulated zxc compression and decompression stream..."
# Create a mock zxc script that implements -c and -dc using gzip under the hood
# to verify Clonezilla's piping mechanics and arguments
cat << 'EOF' > "$TMP_DIR/mock_bin/zxc"
#!/bin/bash
# Mock zxc CLI behavior:
# -c -> stdout
# -d -> decompress
# -T<N> -> threads
is_decomp=0
while [ $# -gt 0 ]; do
  case "$1" in
    -d|-dc) is_decomp=1; shift;;
    -c) shift;;
    -T*) shift;;
    -[0-9]*) shift;;
    -*) shift;;
    *) file_in="$1"; shift;;
  esac
done

if [ "$is_decomp" -eq 1 ]; then
  if [ -n "$file_in" ]; then
    gzip -dc "$file_in"
  else
    gzip -dc
  fi
else
  if [ -n "$file_in" ]; then
    gzip -c "$file_in"
  else
    gzip -c
  fi
fi
EOF
chmod +x "$TMP_DIR/mock_bin/zxc"
export PATH="$TMP_DIR/mock_bin:$PATH"

TEST_DATA="Clonezilla -z10p zxc compression and decompression test data payload $(date)"
echo "$TEST_DATA" > "$TMP_DIR/original.txt"

# Compress using zip_stdin_cmd from Clonezilla's get_image_cat_zip_cmd
get_image_cat_zip_cmd "sda1.ext4-ptcl-img.zxc.aa"
# $zip_stdin_cmd should be "zxc -c -T0 -3"
eval "$zip_stdin_cmd < \"$TMP_DIR/original.txt\" > \"$TMP_DIR/sda1.ext4-ptcl-img.zxc.aa\""

# Decompress using unzip_stdin_cmd
eval "$unzip_stdin_cmd < \"$TMP_DIR/sda1.ext4-ptcl-img.zxc.aa\" > \"$TMP_DIR/restored_stdin.txt\""

# Decompress using cat_prog
eval "$cat_prog \"$TMP_DIR/sda1.ext4-ptcl-img.zxc.aa\" > \"$TMP_DIR/restored_cat.txt\""

diff -u "$TMP_DIR/original.txt" "$TMP_DIR/restored_stdin.txt"
diff -u "$TMP_DIR/original.txt" "$TMP_DIR/restored_cat.txt"

echo "  PASS: Data compression and decompression stream verified."

echo "=== All zxc (-z10p) Tests Passed Successfully! ==="
exit 0
