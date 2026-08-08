#!/bin/bash
# Standalone test for fbterm font size parsing and option construction.

set -e

echo "=== Running fbterm Font Size Logic Tests ==="

test_fbterm_font_opts() {
  local FONTSIZE="$1"
  local fontwidth=""
  local fontheight=""
  local font_opts=""

  fontwidth="$(echo "$FONTSIZE" | cut -d'x' -f1)"
  fontheight="$(echo "$FONTSIZE" | cut -d'x' -f2)"

  if [ -n "$fontwidth" -a -n "$fontheight" ]; then 
    font_opts="--font-width=$fontwidth --font-height=$fontheight --font-size=$fontheight"
  fi

  echo "$font_opts"
}

# Test case 1: 16x32
echo "Testing FONTSIZE=16x32..."
opts=$(test_fbterm_font_opts "16x32")
expected="--font-width=16 --font-height=32 --font-size=32"
if [ "$opts" != "$expected" ]; then
  echo "FAIL: Expected '$expected', got '$opts'"
  exit 1
fi

# Test case 2: 14x28
echo "Testing FONTSIZE=14x28..."
opts=$(test_fbterm_font_opts "14x28")
expected="--font-width=14 --font-height=28 --font-size=28"
if [ "$opts" != "$expected" ]; then
  echo "FAIL: Expected '$expected', got '$opts'"
  exit 1
fi

# Test case 3: 8x16
echo "Testing FONTSIZE=8x16..."
opts=$(test_fbterm_font_opts "8x16")
expected="--font-width=8 --font-height=16 --font-size=16"
if [ "$opts" != "$expected" ]; then
  echo "FAIL: Expected '$expected', got '$opts'"
  exit 1
fi

# Test case 4: Empty FONTSIZE
echo "Testing empty FONTSIZE..."
opts=$(test_fbterm_font_opts "")
expected=""
if [ "$opts" != "$expected" ]; then
  echo "FAIL: Expected empty options, got '$opts'"
  exit 1
fi

echo "=== All fbterm Font Size Logic Tests Passed Successfully! ==="
