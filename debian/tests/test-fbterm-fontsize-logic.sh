#!/bin/bash
# Standalone test for fbterm font size parsing and option construction.

set -e

echo "=== Running fbterm Font Size Logic Tests ==="

export DRBL_SCRIPT_PATH="."
# Ensure /etc/drbl/drbl-ocs.conf is mocked or exists so sourcing ocs-functions doesn't fail
if [ ! -e "/etc/drbl/drbl-ocs.conf" ]; then
  mkdir -p /etc/drbl
  touch /etc/drbl/drbl-ocs.conf
fi
. scripts/sbin/ocs-functions

# Test case 1: 16x32 (width x height)
echo "Testing FONTSIZE=16x32..."
opts=$(get_fbterm_font_opts "16x32")
expected="--font-width=16 --font-height=32 --font-size=32"
if [ "$opts" != "$expected" ]; then
  echo "FAIL: Expected '$expected', got '$opts'"
  exit 1
fi

# Test case 2: 32x16 (height x width)
echo "Testing FONTSIZE=32x16..."
opts=$(get_fbterm_font_opts "32x16")
expected="--font-width=16 --font-height=32 --font-size=32"
if [ "$opts" != "$expected" ]; then
  echo "FAIL: Expected '$expected', got '$opts'"
  exit 1
fi

# Test case 3: 14x28
echo "Testing FONTSIZE=14x28..."
opts=$(get_fbterm_font_opts "14x28")
expected="--font-width=14 --font-height=28 --font-size=28"
if [ "$opts" != "$expected" ]; then
  echo "FAIL: Expected '$expected', got '$opts'"
  exit 1
fi

# Test case 4: 28x14
echo "Testing FONTSIZE=28x14..."
opts=$(get_fbterm_font_opts "28x14")
expected="--font-width=14 --font-height=28 --font-size=28"
if [ "$opts" != "$expected" ]; then
  echo "FAIL: Expected '$expected', got '$opts'"
  exit 1
fi

# Test case 5: 8x16
echo "Testing FONTSIZE=8x16..."
opts=$(get_fbterm_font_opts "8x16")
expected="--font-width=8 --font-height=16 --font-size=16"
if [ "$opts" != "$expected" ]; then
  echo "FAIL: Expected '$expected', got '$opts'"
  exit 1
fi

# Test case 6: 16 (single value)
echo "Testing FONTSIZE=16..."
opts=$(get_fbterm_font_opts "16")
expected="--font-width=8 --font-height=16 --font-size=16"
if [ "$opts" != "$expected" ]; then
  echo "FAIL: Expected '$expected', got '$opts'"
  exit 1
fi

# Test case 7: 32 (single value)
echo "Testing FONTSIZE=32..."
opts=$(get_fbterm_font_opts "32")
expected="--font-width=16 --font-height=32 --font-size=32"
if [ "$opts" != "$expected" ]; then
  echo "FAIL: Expected '$expected', got '$opts'"
  exit 1
fi

# Test case 8: Empty FONTSIZE
echo "Testing empty FONTSIZE..."
opts=$(get_fbterm_font_opts "")
expected=""
if [ "$opts" != "$expected" ]; then
  echo "FAIL: Expected empty options, got '$opts'"
  exit 1
fi

echo "=== All fbterm Font Size Logic Tests Passed Successfully! ==="
