#!/bin/bash
# Test for ocs-get-dev-info logic, specifically handling nested partitions returned by lsblk

set -e

echo "=== Running ocs-get-dev-info nested partition test ==="

# Create mock bin directory
MOCK_DIR="/tmp/mock-dev-info-bin"
rm -rf "$MOCK_DIR"
mkdir -p "$MOCK_DIR"

# Write mock lsblk
cat <<'EOF' > "$MOCK_DIR/lsblk"
#!/bin/bash
if [[ "$*" == *"/dev/sda4"* ]]; then
  echo '{
   "blockdevices": [
      {
         "name": "/dev/sda",
         "type": "disk",
         "children": [
            {
               "name": "/dev/sda4",
               "type": "part",
               "size": "9.1T",
               "fstype": "btrfs",
               "uuid": "mock-uuid-1234",
               "partuuid": "mock-partuuid-5678",
               "ptuuid": "mock-ptuuid-abcd",
               "partlabel": "mock-partlabel",
               "label": "mock-label"
            }
         ]
      }
   ]
}'
else
  echo '{"blockdevices": []}'
fi
EOF
chmod +x "$MOCK_DIR/lsblk"

# Write mock blkid
cat <<'EOF' > "$MOCK_DIR/blkid"
#!/bin/bash
if [[ "$*" == *"/dev/sda4"* ]]; then
  if [[ "$*" == *"-o export"* ]]; then
    echo "DEVNAME=/dev/sda4"
    echo "UUID=mock-uuid-1234"
    echo "TYPE=btrfs"
    echo "PARTUUID=mock-partuuid-5678"
  else
    echo "/dev/sda4: UUID=\"mock-uuid-1234\" TYPE=\"btrfs\" PARTUUID=\"mock-partuuid-5678\""
  fi
else
  exit 1
fi
EOF
chmod +x "$MOCK_DIR/blkid"

# Write mock udevadm
cat <<'EOF' > "$MOCK_DIR/udevadm"
#!/bin/bash
echo "ID_SERIAL_SHORT=mock-serial-short"
echo "ID_SERIAL=mock-serial-long"
EOF
chmod +x "$MOCK_DIR/udevadm"

# Add mock directory to PATH
export ORIGINAL_PATH="$PATH"
export PATH="$MOCK_DIR:$PATH"

# Run ocs-get-dev-info to test
echo "Running ocs-get-dev-info query..."
SIZE=$(sbin/ocs-get-dev-info /dev/sda4 size)
UUID=$(sbin/ocs-get-dev-info /dev/sda4 uuid)
LABEL=$(sbin/ocs-get-dev-info /dev/sda4 label)
PARTUUID=$(sbin/ocs-get-dev-info /dev/sda4 partuuid)
PARTLABEL=$(sbin/ocs-get-dev-info /dev/sda4 partlabel)
FS=$(sbin/ocs-get-dev-info /dev/sda4 fs)

echo "Results:"
echo "SIZE: '$SIZE'"
echo "UUID: '$UUID'"
echo "LABEL: '$LABEL'"
echo "PARTUUID: '$PARTUUID'"
echo "PARTLABEL: '$PARTLABEL'"
echo "FS: '$FS'"

# Clean up path and files
export PATH="$ORIGINAL_PATH"
rm -rf "$MOCK_DIR"

# Validate results
if [[ "$SIZE" != "9.1T" ]]; then
  echo "FAIL: SIZE is '$SIZE', expected '9.1T'"
  exit 1
fi
if [[ "$UUID" != "mock-uuid-1234" ]]; then
  echo "FAIL: UUID is '$UUID', expected 'mock-uuid-1234'"
  exit 1
fi
if [[ "$LABEL" != "mock-label" ]]; then
  echo "FAIL: LABEL is '$LABEL', expected 'mock-label'"
  exit 1
fi
if [[ "$PARTUUID" != "mock-partuuid-5678" ]]; then
  echo "FAIL: PARTUUID is '$PARTUUID', expected 'mock-partuuid-5678'"
  exit 1
fi
if [[ "$PARTLABEL" != "mock-partlabel" ]]; then
  echo "FAIL: PARTLABEL is '$PARTLABEL', expected 'mock-partlabel'"
  exit 1
fi
if [[ "$FS" != "btrfs" ]]; then
  echo "FAIL: FS is '$FS', expected 'btrfs'"
  exit 1
fi

echo "PASS: All nested partition fields parsed successfully!"
exit 0
