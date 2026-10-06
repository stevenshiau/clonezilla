#!/bin/bash
# Test for ocs-scan-disk device scanning and parsing logic,
# verifying that drive models with double quotes (e.g. 2.5" SSDs)
# and drives without serials do not trigger xargs errors or field corruption.

set -e

echo "=== Running ocs-scan-disk Tests ==="

TMP_DIR="$(mktemp -d /tmp/test-ocs-scan-disk.XXXXXX)"
trap 'rm -rf "$TMP_DIR"' EXIT

MOCK_BIN="$TMP_DIR/bin"
mkdir -p "$MOCK_BIN"

# Create mock udevadm
cat <<'EOF' > "$MOCK_BIN/udevadm"
#!/bin/bash
if [[ "$*" == *"/dev/sda"* ]]; then
  echo "ID_PATH=pci-0000:00:1f.2-ata-1.0"
elif [[ "$*" == *"/dev/sdb"* ]]; then
  echo "ID_PATH=pci-0000:00:1f.2-ata-2.0"
elif [[ "$*" == *"/dev/sdf"* ]]; then
  echo "ID_PATH=pci-0000:00:1f.2-ata-6.0"
else
  echo "ID_PATH=N/A"
fi
EOF
chmod +x "$MOCK_BIN/udevadm"

# Create mock lsblk
cat <<'EOF' > "$MOCK_BIN/lsblk"
#!/bin/bash
if [[ "$*" == *"-J"* ]]; then
  cat <<'JSON'
{
   "blockdevices": [
      {
         "name": "sda",
         "type": "disk",
         "size": "238.5G",
         "model": "SAMSUNG SSD SM841 2.5\" 256GB",
         "serial": "S12LNSAD821986"
      },
      {
         "name": "sdb",
         "type": "disk",
         "size": "9.1T",
         "model": "WDC WD100EFAX-68",
         "serial": null
      },
      {
         "name": "sdf",
         "type": "disk",
         "size": "465.8G",
         "model": "ST3500413AS",
         "serial": "Z2AGN00X"
      }
   ]
}
JSON
elif [[ "$*" == *"-P"* ]]; then
  echo 'NAME="sda" TYPE="disk" SIZE="238.5G" MODEL="SAMSUNG SSD SM841 \x22 256GB" SERIAL="S12LNSAD821986"'
  echo 'NAME="sdb" TYPE="disk" SIZE="9.1T" MODEL="WDC WD100EFAX-68" SERIAL=""'
  echo 'NAME="sdf" TYPE="disk" SIZE="465.8G" MODEL="ST3500413AS" SERIAL="Z2AGN00X"'
else
  # Plain format
  echo 'sda disk 238.5G SAMSUNG SSD SM841 2.5" 256GB S12LNSAD821986'
  echo 'sdb disk 9.1T WDC WD100EFAX-68 '
  echo 'sdf disk 465.8G ST3500413AS Z2AGN00X'
fi
EOF
chmod +x "$MOCK_BIN/lsblk"

echo "--- Test 1: Testing ocs-scan-disk with jq path ---"
ORIG_PATH="$PATH"
export PATH="$MOCK_BIN:$ORIG_PATH"

OUTPUT_STDOUT="$TMP_DIR/stdout1.txt"
OUTPUT_STDERR="$TMP_DIR/stderr1.txt"

bin/ocs-scan-disk > "$OUTPUT_STDOUT" 2> "$OUTPUT_STDERR"

if [ -s "$OUTPUT_STDERR" ]; then
  echo "FAIL: Unexpected stderr output in jq path:"
  cat "$OUTPUT_STDERR"
  exit 1
fi

echo "Verifying stdout output in jq path..."
cat "$OUTPUT_STDOUT"

# Verify sda (Samsung 2.5" SSD): model truncated to 15 chars, serial preserved
if ! grep -E "^sda\s+disk\s+238.5G\s+SAMSUNG SSD SM8\s+S12LNSAD821986\s+pci-0000:00:1f.2-ata-1.0" "$OUTPUT_STDOUT" >/dev/null; then
  echo "FAIL: sda line not formatted as expected in jq path!"
  exit 1
fi

# Verify sdb (no serial): serial column should be empty, not populated with last word of model
if ! grep -E "^sdb\s+disk\s+9.1T\s+WDC WD100EFAX-6\s+pci-0000:00:1f.2-ata-2.0" "$OUTPUT_STDOUT" >/dev/null; then
  echo "FAIL: sdb line not formatted as expected in jq path!"
  exit 1
fi
if grep -E "^sdb.*WD100EFAX-68" "$OUTPUT_STDOUT" >/dev/null; then
  echo "FAIL: sdb incorrectly leaked model word into serial column!"
  exit 1
fi

# Verify sdf: serial should not leak into model column
if ! grep -E "^sdf\s+disk\s+465.8G\s+ST3500413AS\s+Z2AGN00X\s+pci-0000:00:1f.2-ata-6.0" "$OUTPUT_STDOUT" >/dev/null; then
  echo "FAIL: sdf line not formatted as expected in jq path!"
  exit 1
fi

echo "PASS: Test 1 (jq path) passed successfully!"

echo "--- Test 2: Testing ocs-scan-disk with fallback (non-jq) path ---"
OUTPUT_STDOUT_FALLBACK="$TMP_DIR/stdout2.txt"
OUTPUT_STDERR_FALLBACK="$TMP_DIR/stderr2.txt"

# Run with jq masked out
bash -c '
enable -n type 2>/dev/null || true
type() {
  if [ "$1" = "jq" ]; then return 1; fi
  builtin type "$@"
}
export -f type
bin/ocs-scan-disk
' > "$OUTPUT_STDOUT_FALLBACK" 2> "$OUTPUT_STDERR_FALLBACK"

if [ -s "$OUTPUT_STDERR_FALLBACK" ]; then
  echo "FAIL: Unexpected stderr output in fallback path:"
  cat "$OUTPUT_STDERR_FALLBACK"
  exit 1
fi

echo "Verifying stdout output in fallback path..."
cat "$OUTPUT_STDOUT_FALLBACK"

# Verify sda (Samsung 2.5" SSD): model truncated to 15 chars, serial preserved
if ! grep -E "^sda\s+disk\s+238.5G\s+SAMSUNG SSD SM8\s+S12LNSAD821986\s+pci-0000:00:1f.2-ata-1.0" "$OUTPUT_STDOUT_FALLBACK" >/dev/null; then
  echo "FAIL: sda line not formatted as expected in fallback path!"
  exit 1
fi

# Verify sdb (no serial): serial column should be empty
if ! grep -E "^sdb\s+disk\s+9.1T\s+WDC WD100EFAX-6\s+pci-0000:00:1f.2-ata-2.0" "$OUTPUT_STDOUT_FALLBACK" >/dev/null; then
  echo "FAIL: sdb line not formatted as expected in fallback path!"
  exit 1
fi
if grep -E "^sdb.*WD100EFAX-68" "$OUTPUT_STDOUT_FALLBACK" >/dev/null; then
  echo "FAIL: sdb incorrectly leaked model word into serial column in fallback path!"
  exit 1
fi

# Verify sdf: serial should not leak into model column
if ! grep -E "^sdf\s+disk\s+465.8G\s+ST3500413AS\s+Z2AGN00X\s+pci-0000:00:1f.2-ata-6.0" "$OUTPUT_STDOUT_FALLBACK" >/dev/null; then
  echo "FAIL: sdf line not formatted as expected in fallback path!"
  exit 1
fi

echo "PASS: Test 2 (fallback path) passed successfully!"

echo "--- Test 3: Testing ocs-scan-disk with empty device list ---"
cat <<'EOF' > "$MOCK_BIN/lsblk"
#!/bin/bash
if [[ "$*" == *"-J"* ]]; then
  echo '{"blockdevices": []}'
else
  echo ''
fi
EOF
chmod +x "$MOCK_BIN/lsblk"

OUTPUT_STDOUT_EMPTY="$TMP_DIR/stdout3.txt"
OUTPUT_STDERR_EMPTY="$TMP_DIR/stderr3.txt"

bin/ocs-scan-disk > "$OUTPUT_STDOUT_EMPTY" 2> "$OUTPUT_STDERR_EMPTY"

if [ -s "$OUTPUT_STDERR_EMPTY" ]; then
  echo "FAIL: Unexpected stderr output for empty device list:"
  cat "$OUTPUT_STDERR_EMPTY"
  exit 1
fi

# Check that no bogus empty device row with N/A is output between separator lines
table_rows=$(sed -n '/======/,/======/p' "$OUTPUT_STDOUT_EMPTY" | grep -v '======' | (grep -v 'NAME.*TYPE' || true))
if [ -n "$table_rows" ]; then
  echo "FAIL: Found unexpected rows in empty device table: '$table_rows'"
  exit 1
fi

echo "PASS: Test 3 (empty device list) passed successfully!"

export PATH="$ORIG_PATH"

echo "=== All ocs-scan-disk Tests Passed Successfully! ==="
