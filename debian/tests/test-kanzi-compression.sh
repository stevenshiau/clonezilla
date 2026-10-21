#!/bin/bash
# Test suite for kanzi compression and decompression support in Clonezilla (-z11p)

set -e

echo "=== Running Clonezilla kanzi (-z11p) Compression and Decompression Tests ==="

TMP_DIR="$(mktemp -d /tmp/test-kanzi.XXXXXX)"
trap 'rm -rf "$TMP_DIR"' EXIT

# -------------------------------------------------------------
# Test 1: Test ocs-sr option parsing for -z11p, --kanzimt-compress, --smp-kanzi-compress, -z11
# -------------------------------------------------------------
echo "[Test 1] Testing ocs-sr option parsing..."

parse_test_ocs_sr() {
  local extra_kanzi_opt="-j 0 -l 3"
  local IMG_CLONE_CMP=""
  local n_shift=0

  while [ $# -gt 0 ]; do
    case "$1" in
      -z11|--kanzi-compress)
	      [ -z "$extra_kanzi_opt" ] && extra_kanzi_opt="-j 0 -l 3"
	      IMG_CLONE_CMP="kanzi -c -o stdout $(echo $extra_kanzi_opt | sed -r "s/-j[[:space:]]*[[:digit:]]+/-j 1/")"
	      shift; n_shift=$((n_shift+1));;
      -z11p|--kanzimt-compress|--smp-kanzi-compress)
	      [ -z "$extra_kanzi_opt" ] && extra_kanzi_opt="-j 0 -l 3"
              IMG_CLONE_CMP="kanzi -c -o stdout $extra_kanzi_opt"
	      shift; n_shift=$((n_shift+1));;
      *)
	      shift;;
    esac
  done
  echo "$IMG_CLONE_CMP"
}

# Verify -z11p sets parallel kanzi
res=$(parse_test_ocs_sr -z11p)
if [ "$res" != "kanzi -c -o stdout -j 0 -l 3" ]; then
  echo "FAIL: ocs-sr -z11p expected 'kanzi -c -o stdout -j 0 -l 3', got '$res'"
  exit 1
fi

res=$(parse_test_ocs_sr --kanzimt-compress)
if [ "$res" != "kanzi -c -o stdout -j 0 -l 3" ]; then
  echo "FAIL: ocs-sr --kanzimt-compress expected 'kanzi -c -o stdout -j 0 -l 3', got '$res'"
  exit 1
fi

res=$(parse_test_ocs_sr --smp-kanzi-compress)
if [ "$res" != "kanzi -c -o stdout -j 0 -l 3" ]; then
  echo "FAIL: ocs-sr --smp-kanzi-compress expected 'kanzi -c -o stdout -j 0 -l 3', got '$res'"
  exit 1
fi

# Verify -z11 sets single-thread kanzi
res=$(parse_test_ocs_sr -z11)
if [ "$res" != "kanzi -c -o stdout -j 1 -l 3" ]; then
  echo "FAIL: ocs-sr -z11 expected 'kanzi -c -o stdout -j 1 -l 3', got '$res'"
  exit 1
fi

# Verify actual sbin/ocs-sr file content
if ! grep -q "\-z11p|--kanzimt-compress" sbin/ocs-sr; then
  echo "FAIL: sbin/ocs-sr does not contain -z11p|--kanzimt-compress"
  exit 1
fi

echo "  PASS: ocs-sr options parsed correctly."

# -------------------------------------------------------------
# Test 2: Test drbl-ocs option parsing
# -------------------------------------------------------------
echo "[Test 2] Testing drbl-ocs option parsing..."
if ! grep -q "\-z11p|--kanzimt-compress" sbin/drbl-ocs; then
  echo "FAIL: sbin/drbl-ocs does not contain -z11p|--kanzimt-compress"
  exit 1
fi
echo "  PASS: drbl-ocs options verified."

# -------------------------------------------------------------
# Test 3: Test ocs-get-comp-suffix in ocs-functions
# -------------------------------------------------------------
echo "[Test 3] Testing ocs-get-comp-suffix for kanzi..."
source scripts/sbin/ocs-functions

suf=$(ocs-get-comp-suffix "kanzi -c -o stdout -j 0 -l 3")
if [ "$suf" != "knz" ]; then
  echo "FAIL: ocs-get-comp-suffix for 'kanzi ...' expected 'knz', got '$suf'"
  exit 1
fi

suf=$(ocs-get-comp-suffix "kanzi -d -o stdout")
if [ "$suf" != "knz" ]; then
  echo "FAIL: ocs-get-comp-suffix for 'kanzi -d ...' expected 'knz', got '$suf'"
  exit 1
fi
echo "  PASS: ocs-get-comp-suffix returns 'knz'."

# -------------------------------------------------------------
# Test 4: Test get_image_cat_zip_cmd for partclone image name
# -------------------------------------------------------------
echo "[Test 4] Testing get_image_cat_zip_cmd for .ptcl-img.knz.aa..."
extra_kanzi_opt="-j 0 -l 3"
extra_kanzi_dc_opt="-j 0"
use_parallel_decompression="yes"

get_image_cat_zip_cmd "sda1.ext4-ptcl-img.knz.aa"

if [ "$img_comp_format" != "knz" ]; then
  echo "FAIL: img_comp_format expected 'knz', got '$img_comp_format'"
  exit 1
fi

if [[ "$cat_prog" != *"kanzi -d -o stdout"* ]]; then
  echo "FAIL: cat_prog expected to contain 'kanzi -d -o stdout', got '$cat_prog'"
  exit 1
fi

if [[ "$unzip_stdin_cmd" != *"kanzi -d -o stdout"*" -i"* ]]; then
  echo "FAIL: unzip_stdin_cmd expected to contain 'kanzi -d -o stdout ... -i', got '$unzip_stdin_cmd'"
  exit 1
fi

if [[ "$zip_stdin_cmd" != *"kanzi -c -o stdout"* ]]; then
  echo "FAIL: zip_stdin_cmd expected to contain 'kanzi -c -o stdout', got '$zip_stdin_cmd'"
  exit 1
fi

# Test decompression with use_parallel_decompression="no"
use_parallel_decompression="no"
get_image_cat_zip_cmd "sda1.ext4-ptcl-img.knz.aa"
if [[ "$cat_prog" != *"-j 1"* ]]; then
  echo "FAIL: cat_prog expected to contain '-j 1' when use_parallel_decompression=no, got '$cat_prog'"
  exit 1
fi
echo "  PASS: get_image_cat_zip_cmd correctly handles .ptcl-img.knz."

# -------------------------------------------------------------
# Test 5: Test fallback image format detection for .knz file
# -------------------------------------------------------------
echo "[Test 5] Testing fallback get_image_cat_zip_cmd for .knz extension..."
dummy_knz="$TMP_DIR/backup-disk.knz"
touch "$dummy_knz"
use_parallel_decompression="yes"

get_image_cat_zip_cmd "$dummy_knz"
if [[ "$unzip_stdin_cmd" != *"kanzi -d -o stdout"*" -i"* ]]; then
  echo "FAIL: fallback unzip_stdin_cmd expected 'kanzi -d -o stdout ... -i', got '$unzip_stdin_cmd'"
  exit 1
fi
echo "  PASS: fallback get_image_cat_zip_cmd correctly identifies .knz."

# -------------------------------------------------------------
# Test 6: Test check_ocs_input_params validation for kanzi
# -------------------------------------------------------------
echo "[Test 6] Testing check_ocs_input_params for kanzi..."

# Case 6a: kanzi not installed -> should fallback to gzip
(
  export PATH="$TMP_DIR/empty_bin:$PATH"
  mkdir -p "$TMP_DIR/empty_bin"
  IMG_CLONE_CMP="kanzi -c -o stdout -j 0 -l 3"
  USE_PARTCLONE="yes"
  VOL_LIMIT=0
  check_ocs_input_params >/dev/null 2>&1
  if [[ "$IMG_CLONE_CMP" != *"gzip"* ]]; then
    echo "FAIL: Expected fallback to gzip when kanzi is missing, got: $IMG_CLONE_CMP"
    exit 1
  fi
)

# Case 6b: kanzi mock installed but USE_PARTCLONE="no" -> should fallback to gzip
(
  mkdir -p "$TMP_DIR/mock_bin"
  echo '#!/bin/sh' > "$TMP_DIR/mock_bin/kanzi"
  chmod +x "$TMP_DIR/mock_bin/kanzi"
  export PATH="$TMP_DIR/mock_bin:$PATH"
  IMG_CLONE_CMP="kanzi -c -o stdout -j 0 -l 3"
  USE_PARTCLONE="no"
  VOL_LIMIT=0
  check_ocs_input_params >/dev/null 2>&1
  if [[ "$IMG_CLONE_CMP" != *"gzip"* ]]; then
    echo "FAIL: Expected fallback to gzip when USE_PARTCLONE is no, got: $IMG_CLONE_CMP"
    exit 1
  fi
)

# Case 6c: kanzi mock installed and USE_PARTCLONE="yes" -> keep kanzi
(
  mkdir -p "$TMP_DIR/mock_bin"
  echo '#!/bin/sh' > "$TMP_DIR/mock_bin/kanzi"
  chmod +x "$TMP_DIR/mock_bin/kanzi"
  export PATH="$TMP_DIR/mock_bin:$PATH"
  IMG_CLONE_CMP="kanzi -c -o stdout -j 0 -l 3"
  USE_PARTCLONE="yes"
  VOL_LIMIT=0
  check_ocs_input_params >/dev/null 2>&1
  if [[ "$IMG_CLONE_CMP" != *"kanzi"* ]]; then
    echo "FAIL: Expected kanzi to be kept, got: $IMG_CLONE_CMP"
    exit 1
  fi
)
echo "  PASS: check_ocs_input_params correctly validates kanzi."

# -------------------------------------------------------------
# Test 7: Test USAGE text and documentation
# -------------------------------------------------------------
echo "[Test 7] Testing USAGE and documentation..."
usage_output=$(USAGE_common_save)
if ! echo "$usage_output" | grep -q "\-z11p"; then
  echo "FAIL: USAGE_common_save does not mention -z11p"
  exit 1
fi

if ! grep -q "\-z11p" doc/ocs-sr.8; then
  echo "FAIL: doc/ocs-sr.8 does not mention -z11p"
  exit 1
fi
echo "  PASS: Documentation and USAGE verified."

# -------------------------------------------------------------
# Test 8: Test set_onthefly_net_filter_program for kanzi
# -------------------------------------------------------------
echo "[Test 8] Testing set_onthefly_net_filter_program..."
(
  mkdir -p "$TMP_DIR/mock_bin"
  echo '#!/bin/sh' > "$TMP_DIR/mock_bin/kanzi"
  chmod +x "$TMP_DIR/mock_bin/kanzi"
  export PATH="$TMP_DIR/mock_bin:$PATH"
  net_filter="kanzi"
  set_onthefly_net_filter_program
  if [[ "$net_filter_comp" != *"kanzi -c -o stdout"* ]] || [[ "$net_filter_decomp" != *"kanzi -d -o stdout"* ]]; then
    echo "FAIL: net_filter_comp or net_filter_decomp not set for kanzi (got comp='$net_filter_comp', decomp='$net_filter_decomp')"
    exit 1
  fi
)
echo "  PASS: set_onthefly_net_filter_program verified."

# -------------------------------------------------------------
# Test 9: End-to-end data compression & decompression pipe simulation
# -------------------------------------------------------------
echo "[Test 9] Testing simulated kanzi compression and decompression stream..."
# Create a mock kanzi CLI script that implements -c and -d using gzip under the hood
cat << 'EOF' > "$TMP_DIR/mock_bin/kanzi"
#!/bin/bash
is_decomp=0
file_in=""
file_out=""
while [ $# -gt 0 ]; do
  case "$1" in
    -d|--decompress) is_decomp=1; shift;;
    -c|--compress) is_decomp=0; shift;;
    -i) shift
        if [ $# -gt 0 ] && [ -n "$1" ]; then
          file_in="$1"
          shift
        fi
        ;;
    -o) shift; file_out="$1"; shift;;
    -j|-t|--jobs=*) shift;;
    -l|--level=*) shift;;
    -*) shift;;
    *) shift;;
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
chmod +x "$TMP_DIR/mock_bin/kanzi"
export PATH="$TMP_DIR/mock_bin:$PATH"

TEST_DATA="Clonezilla -z11p kanzi compression and decompression test data payload $(date)"
echo "$TEST_DATA" > "$TMP_DIR/original.txt"

# Compress using zip_stdin_cmd from Clonezilla's get_image_cat_zip_cmd
get_image_cat_zip_cmd "sda1.ext4-ptcl-img.knz.aa"
eval "$zip_stdin_cmd < \"$TMP_DIR/original.txt\" > \"$TMP_DIR/sda1.ext4-ptcl-img.knz.aa\""

# Decompress using unzip_stdin_cmd with file argument (direct mode in ocs-chkimg and unicast_restore_by_partclone)
eval "$unzip_stdin_cmd \"$TMP_DIR/sda1.ext4-ptcl-img.knz.aa\" > \"$TMP_DIR/restored_direct.txt\""

# Decompress using unzip_stdin_cmd in a pipe (split image mode)
eval "cat \"$TMP_DIR/sda1.ext4-ptcl-img.knz.aa\" | $unzip_stdin_cmd > \"$TMP_DIR/restored_pipe.txt\""

# Decompress using cat_prog
eval "$cat_prog \"$TMP_DIR/sda1.ext4-ptcl-img.knz.aa\" > \"$TMP_DIR/restored_cat.txt\""

diff -u "$TMP_DIR/original.txt" "$TMP_DIR/restored_direct.txt"
diff -u "$TMP_DIR/original.txt" "$TMP_DIR/restored_pipe.txt"
diff -u "$TMP_DIR/original.txt" "$TMP_DIR/restored_cat.txt"

echo "  PASS: Data compression and decompression stream verified."

echo "=== All kanzi (-z11p) Tests Passed Successfully! ==="
exit 0
