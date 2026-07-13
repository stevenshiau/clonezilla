#!/bin/bash

# Standalone test for ARM64 CJK/fbterm support in get_fb_term and ocs-lang-kbd-conf

set -e

echo "=== Running ARM64 CJK/fbterm Support Tests ==="

# Mock commands & environment
export DRBL_SCRIPT_PATH="."
# Create mock config files if needed or mock functions
mkdir -p /tmp/mock_etc/ocs
touch /tmp/mock_etc/ocs/ocs-live.conf

# We mock type to return success/failure for various term binaries
# Creating mock binaries in a temporary PATH is extremely robust and standard.
MOCK_BIN_DIR=$(mktemp -d)
export PATH="$MOCK_BIN_DIR:$PATH"

# Let's mock uname
uname() {
  if [ "$1" = "-m" ]; then
    echo "aarch64"
  else
    /bin/uname "$@"
  fi
}
export -f uname

# Let's create dummy fbterm and jfbterm binaries in our mock bin dir
touch "$MOCK_BIN_DIR/fbterm"
touch "$MOCK_BIN_DIR/jfbterm"
touch "$MOCK_BIN_DIR/bterm"
chmod +x "$MOCK_BIN_DIR/fbterm" "$MOCK_BIN_DIR/jfbterm" "$MOCK_BIN_DIR/bterm"

# Load functions
. scripts/sbin/ocs-functions

# Test 1: get_fb_term on aarch64 should NOT pick jfbterm even if it exists.
# It should pick fbterm first.
fb_term=""
get_fb_term
echo "Test 1: Default on aarch64 (fbterm, jfbterm, bterm exist) -> selected fb_term: $fb_term"
if [ "$fb_term" != "fbterm" ]; then
  echo "FAIL: Expected fbterm on aarch64, got $fb_term"
  exit 1
fi

# Test 2: If only jfbterm and bterm exist on aarch64, it should NOT pick jfbterm; it should pick bterm.
rm -f "$MOCK_BIN_DIR/fbterm"
fb_term=""
get_fb_term
echo "Test 2: Only jfbterm and bterm exist on aarch64 -> selected fb_term: $fb_term"
if [ "$fb_term" != "bterm" ]; then
  echo "FAIL: Expected bterm on aarch64, got $fb_term"
  exit 1
fi

# Test 3: If fb_term is preset to jfbterm on aarch64, it should fallback.
fb_term="jfbterm"
# With fbterm mock deleted, and bterm mock existing, it should fall back to bterm.
get_fb_term
echo "Test 3: preset fb_term=jfbterm on aarch64 -> fell back to: $fb_term"
if [ "$fb_term" != "bterm" ]; then
  echo "FAIL: Expected fallback to bterm, got $fb_term"
  exit 1
fi

# Clean up
rm -rf "$MOCK_BIN_DIR"
echo "=== All Tests Passed Successfully! ==="
