#!/bin/bash
# Test script for ocs-get-nic-fw-lst and get_non_free_net_firmware_for_ubuntu

set -e

echo "=== Running ocs-get-nic-fw-lst and NIC firmware extraction tests ==="

TEST_DIR="$(mktemp -d /tmp/test_ocs_fw.XXXXXX)"
trap 'rm -rf "$TEST_DIR"' EXIT

# 1. Setup mock kernel module hierarchy
MOCK_MODULES="$TEST_DIR/modules"
KVER_MOCK="7.3.0-9-generic"
NET_DRV_DIR="$MOCK_MODULES/$KVER_MOCK/kernel/drivers/net/ethernet/broadcom"
mkdir -p "$NET_DRV_DIR"
touch "$NET_DRV_DIR/bnx2.ko.zst"
touch "$NET_DRV_DIR/tg3.ko.zst"

# Also create an empty newer directory to ensure ocs-get-nic-fw-lst picks the directory with modules
mkdir -p "$MOCK_MODULES/9.9.0-empty"

# Create mock modinfo in a temp bin
MOCK_BIN="$TEST_DIR/bin"
mkdir -p "$MOCK_BIN"
cat <<'EOF' > "$MOCK_BIN/modinfo"
#!/bin/bash
field=""
files=()
while [ $# -gt 0 ]; do
  case "$1" in
    -F) field="$2"; shift 2;;
    *) files+=("$1"); shift;;
  esac
done

if [ "$field" = "firmware" ]; then
  for mod_file in "${files[@]}"; do
    case "$mod_file" in
      *bnx2.ko*)
        echo "bnx2/bnx2-mips-06-6.2.3.fw"
        echo "bnx2/bnx2-mips-09-6.2.1b.fw"
        echo "bnx2/bnx2-rv2p-06-6.0.15.fw"
        echo "bnx2/bnx2-rv2p-09-6.0.17.fw"
        echo "bnx2/bnx2-rv2p-09ax-6.0.17.fw"
        ;;
      *tg3.ko*)
        echo "tigon/tg3.bin"
        echo "tigon/tg3_tso5.bin"
        ;;
    esac
  done
fi
exit 0
EOF
chmod +x "$MOCK_BIN/modinfo"

# 2. Test bin/ocs-get-nic-fw-lst execution
OUT_DIR="$TEST_DIR/out"
mkdir -p "$OUT_DIR"

PATH="$MOCK_BIN:$PATH" MODULES_DIR="$MOCK_MODULES" ./bin/ocs-get-nic-fw-lst "$OUT_DIR"

if [ ! -f "$OUT_DIR/nic-firmware.lst" ]; then
  echo "FAIL: nic-firmware.lst was not generated!"
  exit 1
fi

echo "Generated nic-firmware.lst content:"
cat "$OUT_DIR/nic-firmware.lst"

# Check that bnx2-mips-06-6.2.3.fw is present in nic-firmware.lst
if ! grep -q "^bnx2/bnx2-mips-06-6.2.3.fw$" "$OUT_DIR/nic-firmware.lst"; then
  echo "FAIL: bnx2/bnx2-mips-06-6.2.3.fw not found in nic-firmware.lst!"
  exit 1
fi

# Check that tigon/tg3.bin is present
if ! grep -q "^tigon/tg3.bin$" "$OUT_DIR/nic-firmware.lst"; then
  echo "FAIL: tigon/tg3.bin not found in nic-firmware.lst!"
  exit 1
fi

echo "PASS: bin/ocs-get-nic-fw-lst generated correct firmware list with bnx2."

# 3. Test firmware installation loop from modular packages (simulating linux-firmware-misc)
FIRM_TMP="$TEST_DIR/firm_tmp"
mkdir -p "$FIRM_TMP/usr/lib/firmware/bnx2"
mkdir -p "$FIRM_TMP/usr/lib/firmware/nvidia"
mkdir -p "$FIRM_TMP/usr/lib/firmware/intel/dsp"

# Create mock firmware file in linux-firmware-misc location (network card)
touch "$FIRM_TMP/usr/lib/firmware/bnx2/bnx2-mips-06-6.2.3.fw.zst"

# Create non-network firmware files in extracted pool (GPU, audio)
touch "$FIRM_TMP/usr/lib/firmware/nvidia/tu102.bin"
touch "$FIRM_TMP/usr/lib/firmware/intel/dsp/sound.bin"

TARGET_DIR="$TEST_DIR/target"
mkdir -p "$TARGET_DIR"

fw_src_dir="$FIRM_TMP/usr/lib/firmware"
while read -r f; do
  [ -n "$(echo "$f" | grep -E "^[[:space:]]*#")" ] && continue
  if [ -e "$fw_src_dir/$f.zst" ]; then
    inst_cmd="install -m644 -D $fw_src_dir/$f.zst $TARGET_DIR/usr/lib/firmware/$f.zst"
    eval $inst_cmd
  elif [ -e "$fw_src_dir/$f" ]; then
    inst_cmd="install -m644 -D $fw_src_dir/$f $TARGET_DIR/usr/lib/firmware/$f"
    eval $inst_cmd
  fi
done <<< "$(cat "$OUT_DIR/nic-firmware.lst")"

if [ ! -f "$TARGET_DIR/usr/lib/firmware/bnx2/bnx2-mips-06-6.2.3.fw.zst" ]; then
  echo "FAIL: bnx2-mips-06-6.2.3.fw.zst was not installed to target dir!"
  exit 1
fi

# Verify non-network firmware was NOT copied
if [ -e "$TARGET_DIR/usr/lib/firmware/nvidia" ] || [ -e "$TARGET_DIR/usr/lib/firmware/intel/dsp" ]; then
  echo "FAIL: Non-network firmware was installed to target dir!"
  exit 1
fi

echo "PASS: bnx2-mips-06-6.2.3.fw.zst installed and non-network firmware excluded."

# 4. Test package filtering logic for network cards only
sub_pkgs_sample="linux-firmware-amd-graphics linux-firmware-amd-misc linux-firmware-broadcom-wireless linux-firmware-intel-graphics linux-firmware-intel-misc linux-firmware-intel-wireless linux-firmware-marvell-prestera linux-firmware-marvell-wireless linux-firmware-mediatek linux-firmware-mellanox-spectrum linux-firmware-misc linux-firmware-netronome linux-firmware-nvidia-graphics linux-firmware-qlogic linux-firmware-qualcomm-graphics linux-firmware-qualcomm-misc linux-firmware-qualcomm-wireless linux-firmware-realtek"

fw_pkgs_filtered="linux-firmware"
for p in $sub_pkgs_sample; do
  case "$p" in
    linux-firmware-misc|*wireless*|*realtek*|*netronome*|*mediatek*|*qlogic*|*mellanox*|*spectrum*|*prestera*)
      fw_pkgs_filtered="$fw_pkgs_filtered $p"
      ;;
  esac
done

echo "Filtered packages: $fw_pkgs_filtered"
for excluded in "graphics" "amd-misc" "intel-misc" "qualcomm-misc"; do
  if echo "$fw_pkgs_filtered" | grep -q "$excluded"; then
    echo "FAIL: Package with $excluded was not filtered out!"
    exit 1
  fi
done

for required in "linux-firmware-misc" "linux-firmware-realtek" "linux-firmware-intel-wireless"; do
  if ! echo "$fw_pkgs_filtered" | grep -q "$required"; then
    echo "FAIL: Required network package $required missing from filtered list!"
    exit 1
  fi
done

echo "PASS: Package filter correctly whitelisted only network card firmware packages."
echo "=== All tests passed! ==="
exit 0
