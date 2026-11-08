#!/bin/bash
# Test EFI NVRAM Windows Boot Manager Optional Data (BL_WINDOWS_LOAD_OPTIONS) handling and deduplication

set -e

echo "=== Running EFI NVRAM Windows Boot Manager Tests ==="

# Set mock environment
MOCK_DIR="/tmp/mock-efi-test-bin"
rm -rf "$MOCK_DIR"
mkdir -p "$MOCK_DIR"

export ORIGINAL_PATH="$PATH"
export PATH="$MOCK_DIR:$PATH"
export OCS_LOGFILE="/tmp/ocs-efi-test.log"
touch "$OCS_LOGFILE"

# Source Clonezilla functions
. scripts/sbin/ocs-functions

WIN_TXT="/root/clonezilla/efibootmgr-win.txt"
if [ ! -f "$WIN_TXT" ]; then
  echo "FAIL: $WIN_TXT not found!"
  exit 1
fi

# -------------------------------------------------------------
# TEST 1: hex_to_bin function
# -------------------------------------------------------------
echo "--- Test 1: Testing hex_to_bin ---"
TEST_HEX="57494e444f5753000100000088000000780000004200430044004f0042004a004500430054003d007b00390064006500610038003600320063002d0035006300640064002d0034006500370030002d0061006300630031002d006600330032006200330034003400640034003700390035007d00000061000100000010000000040000007fff0400"
TEST_BIN="/tmp/test_win_opt.bin"
rm -f "$TEST_BIN"

hex_to_bin "$TEST_HEX" "$TEST_BIN"
if [ ! -s "$TEST_BIN" ]; then
  echo "FAIL: hex_to_bin failed to create binary file!"
  exit 1
fi

BIN_SIZE=$(wc -c < "$TEST_BIN" | tr -d ' ')
if [ "$BIN_SIZE" -ne 136 ]; then
  echo "FAIL: Expected binary size 136, got $BIN_SIZE"
  exit 1
fi

SIG_HEX=$(head -c 8 "$TEST_BIN" | xxd -p | tr -d '\n')
if [ "$SIG_HEX" != "57494e444f575300" ]; then
  echo "FAIL: Signature mismatch in decoded binary: $SIG_HEX"
  exit 1
fi
rm -f "$TEST_BIN"
echo "PASS: Test 1 (hex_to_bin) passed successfully."

# -------------------------------------------------------------
# TEST 2: get_efi_hd_boot_entry_info opt_data extraction
# -------------------------------------------------------------
echo "--- Test 2: Testing opt_data extraction from saved NVRAM file ---"
# Query Boot0005 (bare entry)
OPT_0005=$(get_efi_hd_boot_entry_info -b 0005 "$WIN_TXT" opt_data)
if [ -n "$OPT_0005" ]; then
  echo "FAIL: Boot0005 should have empty opt_data, got: '$OPT_0005'"
  exit 1
fi

# Query Boot000F (entry with Windows BL_WINDOWS_LOAD_OPTIONS)
OPT_000F=$(get_efi_hd_boot_entry_info -b 000F "$WIN_TXT" opt_data)
if [ -z "$OPT_000F" ]; then
  echo "FAIL: Boot000F should have non-empty opt_data!"
  exit 1
fi
if [[ "$OPT_000F" != 57494e444f575300* ]]; then
  echo "FAIL: Boot000F opt_data does not start with WINDOWS signature!"
  exit 1
fi

# Query with -p ';' and verify field positions
PARSED_TABLE=$(get_efi_hd_boot_entry_info -a -p ';' "$WIN_TXT" label uuid boot_file opt_data)
# Check Boot0005 line: field 4 should be empty
LINE_0005=$(echo "$PARSED_TABLE" | grep -F "b946bc85-2ffd-4305-b12b-a75d5bd83a2d" | head -n 1)
BF4_0005=$(echo "$LINE_0005" | awk -F";" '{print $4}' | tr -d ' ')
if [ -n "$BF4_0005" ]; then
  echo "FAIL: First entry field 4 should be empty, got '$BF4_0005'"
  exit 1
fi

# Check Boot000F line: field 4 should be the hex payload
LINE_000F=$(echo "$PARSED_TABLE" | grep -F "57494e444f575300" | head -n 1)
BF4_000F=$(echo "$LINE_000F" | awk -F";" '{print $4}' | tr -d ' ')
if [[ "$BF4_000F" != 57494e444f575300* ]]; then
  echo "FAIL: Field 4 of Boot000F line does not contain expected hex data!"
  exit 1
fi

# Check boot_num filtering with existing vs nonexistent UUID
BNUMS_EXIST=$(get_efi_hd_boot_entry_info -d b946bc85-2ffd-4305-b12b-a75d5bd83a2d "$WIN_TXT" boot_num)
if [[ "$BNUMS_EXIST" != *"0005"* || "$BNUMS_EXIST" != *"000F"* || "$BNUMS_EXIST" != *"0011"* ]]; then
  echo "FAIL: boot_num with matching UUID did not return expected boot numbers! Got: '$BNUMS_EXIST'"
  exit 1
fi

BNUMS_NONEXIST=$(get_efi_hd_boot_entry_info -d 00000000-0000-0000-0000-000000000000 "$WIN_TXT" boot_num)
if [ -n "$BNUMS_NONEXIST" ]; then
  echo "FAIL: boot_num with nonexistent UUID should be empty! Got: '$BNUMS_NONEXIST'"
  exit 1
fi

# Check lowercase \efi\ opt_data extraction
MOCK_LOWERCASE_FILE="/tmp/mock_lowercase_nvram.txt"
cat <<'EOF_LOWER' > "$MOCK_LOWERCASE_FILE"
Boot0001* Windows  HD(1,GPT,b946bc85-2ffd-4305-b12b-a75d5bd83a2d,0x800,0x32000)/\efi\microsoft\boot\bootmgfw.efi57494E444F575300112233
EOF_LOWER
OPT_LOWER=$(get_efi_hd_boot_entry_info -b 0001 "$MOCK_LOWERCASE_FILE" opt_data)
rm -f "$MOCK_LOWERCASE_FILE"
if [[ "$OPT_LOWER" != "57494E444F575300112233" ]]; then
  echo "FAIL: opt_data from lowercase \\efi\\ path not extracted properly! Got: '$OPT_LOWER'"
  exit 1
fi

echo "PASS: Test 2 (opt_data extraction) passed successfully."

# -------------------------------------------------------------
# TEST 3: Deduplication logic in clean_unused_uefi_boot_entry_in_nvram
# -------------------------------------------------------------
echo "--- Test 3: Testing deduplication prioritizing entries with opt_data ---"
MOCK_CALLS_LOG="/tmp/mock_efibootmgr_deleted.log"
rm -f "$MOCK_CALLS_LOG"

# Write mock efibootmgr
cat <<'EOF' > "$MOCK_DIR/efibootmgr"
#!/bin/bash
WIN_TXT="/root/clonezilla/efibootmgr-win.txt"
if [[ "$*" == *"-B"* ]]; then
  # Record which bootnum was deleted
  bnum=$(echo "$*" | sed -r -e 's/.*-b[[:space:]]+([0-9a-fA-F]+).*/\1/')
  echo "DELETED $bnum" >> "/tmp/mock_efibootmgr_deleted.log"
  exit 0
fi
cat "$WIN_TXT"
EOF
chmod +x "$MOCK_DIR/efibootmgr"

# Run deduplication logic
dup_bf_fp="$(get_efi_hd_boot_entry_info -a nvram boot_file_full_path | sort | uniq -d)"
boot_order="$(LC_ALL=C efibootmgr | grep -iE "^BootOrder:" | awk -F" " '{print $2}' | tr -d ' ')"

for id in $dup_bf_fp; do
  all_boot_num="$(LC_ALL=C efibootmgr -v | grep -F "$id" | awk -F" " '{print $1}' | sed -r -e "s/^Boot//g" -e "s/\*$//g")"
  all_boot_num="$(echo $all_boot_num)"

  boot_nums_with_opt=""
  boot_nums_without_opt=""
  for ib in $all_boot_num; do
    entry_line="$(LC_ALL=C efibootmgr -v | grep -E "^Boot${ib}\*?[[:space:]]")"
    opt_part="$(echo "$entry_line" | sed -r -e 's#^.*(\\|/)[Ee][Ff][Ii](\\|/)[^ )]*\.[Ee][Ff][Ii]\)?##' -e 's#^[[:space:]]+##' -e 's#[[:space:]]+$##')"
    if [ -n "$opt_part" ]; then
      boot_nums_with_opt="$boot_nums_with_opt $ib"
    else
      boot_nums_without_opt="$boot_nums_without_opt $ib"
    fi
  done
  boot_nums_with_opt="$(echo $boot_nums_with_opt)"
  boot_nums_without_opt="$(echo $boot_nums_without_opt)"

  if [ -n "$boot_nums_with_opt" ]; then
    candidates="$boot_nums_with_opt"
  else
    candidates="$boot_nums_without_opt"
  fi

  entry_to_keep=""
  if [ -n "$boot_order" ]; then
    IFS=',' read -r -a bo_arr <<< "$boot_order"
    for bo_item in "${bo_arr[@]}"; do
      for cand in $candidates; do
        if [ "$bo_item" = "$cand" ]; then
          entry_to_keep="$cand"
          break 2
        fi
      done
    done
  fi
  if [ -z "$entry_to_keep" ]; then
    entry_to_keep="$(echo $candidates | awk '{print $1}')"
  fi

  boot_nums_2_be_removed=""
  for ib in $all_boot_num; do
    if [ "$ib" != "$entry_to_keep" ]; then
      boot_nums_2_be_removed="$boot_nums_2_be_removed $ib"
    fi
  done
  boot_nums_2_be_removed="$(echo $boot_nums_2_be_removed)"
  for ib in $boot_nums_2_be_removed; do
    efibootmgr -b $ib -B
  done
done

# Verify that Boot0005 (bare) and Boot000F (duplicate) were deleted, and Boot0011 (active Windows entry) was kept
if [ ! -f "$MOCK_CALLS_LOG" ]; then
  echo "FAIL: efibootmgr -B was not invoked!"
  exit 1
fi

DELETED_ENTRIES=$(cat "$MOCK_CALLS_LOG")
echo "Deleted entries:"
echo "$DELETED_ENTRIES"

if ! grep -q "DELETED 0005" "$MOCK_CALLS_LOG"; then
  echo "FAIL: Boot0005 (bare entry) should have been deleted!"
  exit 1
fi
if ! grep -q "DELETED 000F" "$MOCK_CALLS_LOG"; then
  echo "FAIL: Boot000F (duplicate entry) should have been deleted!"
  exit 1
fi
if grep -q "DELETED 0011" "$MOCK_CALLS_LOG"; then
  echo "FAIL: Boot0011 (first in BootOrder with opt_data) should NOT have been deleted!"
  exit 1
fi
echo "PASS: Test 3 (deduplication) passed successfully."

# -------------------------------------------------------------
# TEST 4: Windows boot entry creation with -@ opt_data_bin
# -------------------------------------------------------------
echo "--- Test 4: Testing boot entry creation with Windows Load Options ---"
MOCK_CREATE_LOG="/tmp/mock_efibootmgr_created.log"
rm -f "$MOCK_CREATE_LOG"

cat <<'EOF' > "$MOCK_DIR/efibootmgr"
#!/bin/bash
WIN_TXT="/root/clonezilla/efibootmgr-win.txt"
if [[ "$*" == *"-c"* ]]; then
  echo "CREATE ARGS: $*" >> "/tmp/mock_efibootmgr_created.log"
  # If -@ argument was provided, inspect the binary file
  while [ $# -gt 0 ]; do
    if [ "$1" = "-@" ]; then
      bin_f="$2"
      if [ -f "$bin_f" ]; then
        sig=$(head -c 7 "$bin_f")
        sz=$(wc -c < "$bin_f" | tr -d ' ')
        echo "OPT_FILE_EXISTS size=$sz sig=$sig" >> "/tmp/mock_efibootmgr_created.log"
      fi
      break
    fi
    shift
  done
  exit 0
fi
cat "$WIN_TXT"
EOF
chmod +x "$MOCK_DIR/efibootmgr"

# Simulate update loop for Windows Boot Manager
label="Windows Boot Manager"
disk_="/dev/sda"
esp_no="1"
esp_boot_f="\\EFI\\Microsoft\\Boot\\bootmgfw.efi"
opt_data=""
win_bcd_payload_def="57494e444f5753000100000088000000780000004200430044004f0042004a004500430054003d007b00390064006500610038003600320063002d0035006300640064002d0034006500370030002d0061006300630031002d006600330032006200330034003400640034003700390035007d00000061000100000010000000040000007fff0400"

if echo "$esp_boot_f" | grep -iq "bootmgfw\.efi"; then
  if ! echo "$opt_data" | grep -iqE '^57494e444f575300'; then
    opt_data="$win_bcd_payload_def"
  fi
fi

opt_data_arg=""
opt_data_bin=""
if [ -n "$opt_data" ] && echo "$opt_data" | grep -iqE '^[0-9a-fA-F]+$'; then
  opt_data_bin="$(mktemp /tmp/opt_data.XXXXXX)"
  if hex_to_bin "$opt_data" "$opt_data_bin" && [ -s "$opt_data_bin" ]; then
    opt_data_arg="-@ $opt_data_bin"
  else
    rm -f "$opt_data_bin"
    opt_data_bin=""
  fi
fi

cmd_update_add_boot_entry="efibootmgr -c -d ${disk_} -p ${esp_no} -L \"$label\" -l \"$esp_boot_f\" $opt_data_arg"
eval "$cmd_update_add_boot_entry"

# Ensure binary file existed during creation but was cleaned up
[ -n "$opt_data_bin" -a -e "$opt_data_bin" ] && rm -f "$opt_data_bin"

CREATE_OUTPUT=$(cat "$MOCK_CREATE_LOG")
echo "$CREATE_OUTPUT"

if ! grep -q "OPT_FILE_EXISTS size=136" "$MOCK_CREATE_LOG"; then
  echo "FAIL: efibootmgr did not receive valid 136-byte Windows Load Options file!"
  exit 1
fi
echo "PASS: Test 4 (creation with -@) passed successfully."

# Clean up
export PATH="$ORIGINAL_PATH"
rm -rf "$MOCK_DIR" "$MOCK_CALLS_LOG" "$MOCK_CREATE_LOG" "$OCS_LOGFILE"

echo "=== All EFI NVRAM Windows Boot Manager Tests Passed! ==="
exit 0
