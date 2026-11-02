#!/bin/bash
# Standalone test for robust jq query selection in ocs-functions on partitions, duplicates, and bare disks.

set -e

echo "=== Running get_disk_or_part_hardware_info robust jq selection tests ==="

# Load scripts/sbin/ocs-functions first so we can test its functions
. scripts/sbin/ocs-functions

# Mock JSON input file
JSON_FILE="/tmp/mock-blkinfo.json"

# Write mock block device JSON info
cat <<'EOF' > "$JSON_FILE"
[
  {
    "name": "sda1",
    "type": "part",
    "size": "100G",
    "model": "Generic_Disk",
    "fstype": "ext4",
    "serial": "123456",
    "label": "MyPartition",
    "id_path_tag": "pci-0000-sda"
  },
  {
    "name": "sde1",
    "type": "part",
    "size": "32G",
    "model": "Ventoy_USB",
    "fstype": "exfat",
    "serial": "ventoy-usb-serial",
    "label": "Ventoy",
    "id_path_tag": "pci-0000-usb-sde"
  },
  {
    "name": "sde1",
    "type": "dm",
    "size": "32G",
    "model": "Ventoy_USB",
    "fstype": "exfat",
    "serial": "ventoy-usb-serial",
    "label": "Ventoy",
    "id_path_tag": "pci-0000-usb-sde"
  },
  {
    "name": "nvme0n3",
    "type": "disk",
    "size": "35G",
    "model": "VMware_NVMe",
    "fstype": "ext4",
    "serial": "nvme-serial-7",
    "label": "BareDiskFS",
    "id_path_tag": "pci-0000-nvme"
  },
  {
    "name": "vg-lv",
    "type": "dm",
    "size": "10G",
    "model": "LVM_Volume",
    "fstype": "xfs",
    "serial": "lvm-serial-9",
    "label": "LVMVolume",
    "id_path_tag": "pci-0000-lvm"
  }
]
EOF

# Mock helper functions in ocs-functions that get_disk_or_part_hardware_info calls
is_supported_dev() {
  return 0
}

# we want get_diskname to return the correct parent disk name
get_diskname() {
  local dev="$1"
  if [[ "$dev" == "sda1" ]]; then
    echo "sda"
  elif [[ "$dev" == "sde1" ]]; then
    echo "sde"
  elif [[ "$dev" == "nvme0n3" ]]; then
    echo "nvme0n3"
  elif [[ "$dev" == "vg-lv" ]]; then
    echo "vg-lv"
  fi
}

# --- TEST 1: Standard Partition sda1 ---
echo "TEST 1: Standard partition sda1..."
is_partition() {
  # Treat sda1 as a partition
  return 0
}

get_disk_or_part_hardware_info "sda1" "default" "$JSON_FILE"
echo "DEV_MODEL for sda1: '$DEV_MODEL'"
# Format expected: size|fstype|In_diskmodel|label|id_path_tag|serial
if [[ "$DEV_MODEL" != "100G|ext4|In_No_disk_model|MyPartition|No_ID_path|No_serial_no" ]]; then
  echo "FAIL: Unexpected sda1 DEV_MODEL: '$DEV_MODEL'"
  exit 1
fi
echo "PASS: sda1 successfully parsed."

# --- TEST 2: Ventoy-style Duplicate sde1 ---
echo "TEST 2: Ventoy-style duplicate sde1..."
is_partition() {
  # Treat sde1 as partition
  return 0
}

get_disk_or_part_hardware_info "sde1" "default" "$JSON_FILE"
echo "DEV_MODEL for sde1: '$DEV_MODEL'"
# Format expected: size|fstype|In_diskmodel|label|id_path_tag|serial
if [[ "$DEV_MODEL" != "32G|exfat|In_No_disk_model|Ventoy|No_ID_path|No_serial_no" ]]; then
  echo "FAIL: Unexpected sde1 DEV_MODEL: '$DEV_MODEL'"
  exit 1
fi
echo "PASS: sde1 successfully parsed and resolved duplicate."

# --- TEST 3: Bare Disk nvme0n3 (Treated as Partition by Clonezilla because it has filesystem) ---
echo "TEST 3: Bare disk nvme0n3 (treated as partition)..."
is_partition() {
  # Treat nvme0n3 as a partition (Clonezilla's behavior for whole disk with FS)
  return 0
}

get_disk_or_part_hardware_info "nvme0n3" "default" "$JSON_FILE"
echo "DEV_MODEL for nvme0n3: '$DEV_MODEL'"
# Format expected: size|fstype|In_diskmodel|label|id_path_tag|serial
if [[ "$DEV_MODEL" != "35G|ext4|In_VMware_NVMe|BareDiskFS|pci-0000-nvme|nvme-serial-7" ]]; then
  echo "FAIL: Unexpected nvme0n3 DEV_MODEL: '$DEV_MODEL'"
  exit 1
fi
echo "PASS: nvme0n3 successfully parsed as a partition despite being type 'disk' in JSON."

# --- TEST 4: LVM logical volume vg-lv (Treated as Partition by Clonezilla because it has filesystem) ---
echo "TEST 4: LVM logical volume vg-lv..."
is_partition() {
  # Treat vg-lv as a partition
  return 0
}

get_disk_or_part_hardware_info "vg-lv" "default" "$JSON_FILE"
echo "DEV_MODEL for vg-lv: '$DEV_MODEL'"
# Format expected: size|fstype|In_diskmodel|label|id_path_tag|serial
if [[ "$DEV_MODEL" != "10G|xfs|In_LVM_Volume|LVMVolume|pci-0000-lvm|lvm-serial-9" ]]; then
  echo "FAIL: Unexpected vg-lv DEV_MODEL: '$DEV_MODEL'"
  exit 1
fi
echo "PASS: vg-lv successfully parsed as partition despite being type 'dm' in JSON."

# --- TEST 5: Whole disk with empty filesystem field (nvme0n1 and sda from old-ok.txt) ---
echo "TEST 5: Whole disk with empty filesystem (nvme0n1 and sda)..."
cat <<'EOF' >> "$JSON_FILE"
EOF
python3 -c '
import json
with open("'"$JSON_FILE"'", "r") as f:
    data = json.load(f)
data.extend([
    {"name": "nvme0n1", "type": "disk", "size": "64G", "model": "VMware Virtual NVMe Disk", "fstype": "", "logical_block_size": "512", "id_path_tag": "pci-0000_0b_00_0-nvme-1", "serial": "VMware NVME 0000"},
    {"name": "nvme0n2", "type": "disk", "size": "35G", "model": "VMware Virtual NVMe Disk", "fstype": "ext4", "logical_block_size": "512", "id_path_tag": "pci-0000_0b_00_0-nvme-7", "serial": "VMware NVME 0000"},
    {"name": "sda", "type": "disk", "size": "64G", "model": "VMware Virtual SATA Hard Drive", "fstype": "", "logical_block_size": "512", "id_path_tag": "pci-0000_02_04_0-ata-1_0", "serial": "00000000000000000001"}
])
with open("'"$JSON_FILE"'", "w") as f:
    json.dump(data, f)
'

is_partition() {
  return 1
}

get_disk_or_part_hardware_info "nvme0n1" "default" "$JSON_FILE"
echo "DEV_MODEL for nvme0n1: '$DEV_MODEL'"
if [[ "$DEV_MODEL" != "64G|VMware_Virtual_NVMe_Disk|pci-0000_0b_00_0-nvme-1|block:512|VMware_NVME_0000" ]]; then
  echo "FAIL: Unexpected nvme0n1 DEV_MODEL: '$DEV_MODEL'"
  exit 1
fi
echo "PASS: nvme0n1 matches old-ok.txt format exactly."

get_disk_or_part_hardware_info "sda" "default" "$JSON_FILE"
echo "DEV_MODEL for sda: '$DEV_MODEL'"
if [[ "$DEV_MODEL" != "64G|VMware_Virtual_SATA_Hard_Drive|pci-0000_02_04_0-ata-1_0|block:512|00000000000000000001" ]]; then
  echo "FAIL: Unexpected sda DEV_MODEL: '$DEV_MODEL'"
  exit 1
fi
echo "PASS: sda matches old-ok.txt format exactly."

# --- TEST 6: Whole disk with filesystem field (nvme0n2 from old-ok.txt) ---
echo "TEST 6: Whole disk with filesystem field (nvme0n2)..."
get_disk_or_part_hardware_info "nvme0n2" "default" "$JSON_FILE"
echo "DEV_MODEL for nvme0n2: '$DEV_MODEL'"
if [[ "$DEV_MODEL" != "35G|ext4|VMware_Virtual_NVMe_Disk|pci-0000_0b_00_0-nvme-7|block:512|VMware_NVME_0000" ]]; then
  echo "FAIL: Unexpected nvme0n2 DEV_MODEL: '$DEV_MODEL'"
  exit 1
fi
echo "PASS: nvme0n2 matches old-ok.txt format exactly."

# Clean up
rm -f "$JSON_FILE"

echo "=== All robust selection tests passed successfully! ==="
exit 0
