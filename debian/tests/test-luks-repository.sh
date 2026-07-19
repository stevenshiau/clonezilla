#!/bin/bash
# Standalone test for LUKS repository support in Clonezilla

set -e

echo "=== Running LUKS Repository Support Tests ==="

# Create a temporary directory for mocks
MOCK_DIR=$(mktemp -d)
trap 'rm -rf "$MOCK_DIR"' EXIT

# Create a mock cmdline file
MOCK_CMDLINE="$MOCK_DIR/cmdline"
echo "ocs_repository=\"dev://$MOCK_DIR/sda1\"" > "$MOCK_CMDLINE"

# Create a mock block device to satisfy [ -b ] check
mknod "$MOCK_DIR/sda1" b 1 1

# Create standard var clonezilla directory for state tagging
mkdir -p /var/lib/clonezilla
rm -f /var/lib/clonezilla/ocs-live-repository

# 1. Mock commands on PATH
export PATH="$MOCK_DIR:$PATH"

# Create mock cryptsetup
cat <<EOF > "$MOCK_DIR/cryptsetup"
#!/bin/bash
echo "Mock cryptsetup called with: \$*" >> /tmp/mock_cryptsetup_calls
if [ "\$1" = "isLuks" ] && [ "\$2" = "$MOCK_DIR/sda1" ]; then
  exit 0
elif [ "\$1" = "luksOpen" ] && [ "\$2" = "$MOCK_DIR/sda1" ] && [ "\$3" = "ocs_reporoot_luks" ]; then
  exit 0
elif [ "\$1" = "close" ] && [ "\$2" = "ocs_reporoot_luks" ]; then
  exit 0
fi
exit 1
EOF
chmod +x "$MOCK_DIR/cryptsetup"

# Create mock drbl-uriparse
cat <<EOF > "$MOCK_DIR/drbl-uriparse"
#!/bin/bash
# Simply parses URI schema or path
if [ "\$2" = "path" ]; then
  echo "$MOCK_DIR/sda1"
elif [ "\$2" = "scheme" ]; then
  echo "dev"
fi
EOF
chmod +x "$MOCK_DIR/drbl-uriparse"

# Create mock ocs-get-dev-info
cat <<EOF > "$MOCK_DIR/ocs-get-dev-info"
#!/bin/bash
if [ "\$1" = "$MOCK_DIR/sda1" ] && [ "\$2" = "filesystem" ]; then
  echo "crypto_LUKS"
elif [ "\$1" = "/dev/mapper/ocs_reporoot_luks" ] && [ "\$2" = "filesystem" ]; then
  echo "ext4"
fi
EOF
chmod +x "$MOCK_DIR/ocs-get-dev-info"

# Create mock mount
cat <<'EOF' > "$MOCK_DIR/mount"
#!/bin/bash
echo "Mock mount called with: $*" >> /tmp/mock_mount_calls
exit 0
EOF
chmod +x "$MOCK_DIR/mount"

# Create mock findmnt
cat <<'EOF' > "$MOCK_DIR/findmnt"
#!/bin/bash
exit 1
EOF
chmod +x "$MOCK_DIR/findmnt"

# 2. Export mock functions to bypass checks in subshells
check_if_root() {
  return 0
}
export -f check_if_root

ask_and_load_lang_set() {
  return 0
}
export -f ask_and_load_lang_set

prepare_mnt_point_ocsroot() {
  return 0
}
export -f prepare_mnt_point_ocsroot

check_if_ocsroot_a_mountpoint() {
  return 0
}
export -f check_if_ocsroot_a_mountpoint

# Clear previous test call records
rm -f /tmp/mock_cryptsetup_calls /tmp/mock_mount_calls

# 3. Execute ocs-live-repository using our mock cmdline and skip checks
# We mock ocs-live-repository environment by sourcing ocs-functions mocks
export DRBL_SCRIPT_PATH="/usr/share/drbl"
export ocsroot="/home/partimag"
export ocsroot_def_mnt_opt="noatime,nodiratime"
export ocs_repository="dev://$MOCK_DIR/sda1"
export ocsroot_src="local_dev"

echo "Running ocs-live-repository to verify automated LUKS unlocking..."
bash sbin/ocs-live-repository -c "$MOCK_CMDLINE" -s

# 4. Verify results
if [ ! -f /tmp/mock_cryptsetup_calls ]; then
  echo "Error: cryptsetup was never called!"
  exit 1
fi

echo "Verifying cryptsetup calls..."
cat /tmp/mock_cryptsetup_calls

grep -q "isLuks $MOCK_DIR/sda1" /tmp/mock_cryptsetup_calls
grep -q "luksOpen $MOCK_DIR/sda1 ocs_reporoot_luks" /tmp/mock_cryptsetup_calls

if [ ! -f /tmp/mock_mount_calls ]; then
  echo "Error: mount was never called!"
  exit 1
fi

echo "Verifying mount calls..."
cat /tmp/mock_mount_calls

grep -q "Mock mount called with: -t auto -o .* /dev/mapper/ocs_reporoot_luks /home/partimag" /tmp/mock_mount_calls

echo "=== LUKS Repository Support Tests Passed Successfully! ==="
rm -f /tmp/mock_cryptsetup_calls /tmp/mock_mount_calls
