#!/bin/bash
# Standalone test for ocs-console-font-size get_resolution logic.

set -e

echo "=== Running get_resolution Logic Tests ==="

MOCK_SYS_DIR="$(mktemp -d /tmp/mock_sys.XXXXXX)"
mkdir -p "$MOCK_SYS_DIR/class/graphics/fb0"

# Mock get_resolution function under test, using our mock sys directory
test_get_resolution() {
  local res=""
  if [ -f "$MOCK_SYS_DIR/class/graphics/fb0/mode" ]; then
      res=$(cat "$MOCK_SYS_DIR/class/graphics/fb0/mode" | head -n1 | cut -d: -f2 | cut -d'p' -f1 | cut -d'-' -f1)
  fi
  if [ -z "$res" ] && [ -f "$MOCK_SYS_DIR/class/graphics/fb0/modes" ]; then
      res=$(cat "$MOCK_SYS_DIR/class/graphics/fb0/modes" | head -n1 | cut -d: -f2 | cut -d'p' -f1 | cut -d'-' -f1)
  fi
  if [ -z "$res" ] && [ -n "$MOCK_FBSET_MODE" ]; then
      res="$MOCK_FBSET_MODE"
  fi
  if [ -n "$res" ]; then
      echo "$res"
  else
      echo "Unable to detect resolution" >&2
      exit 1
  fi
}

# Test Case 1: Only fb0/mode exists (standard Case A: U:1920x1080p-60)
echo "Testing Case 1: fb0/mode with standard DRM format..."
echo "U:1920x1080p-60" > "$MOCK_SYS_DIR/class/graphics/fb0/mode"
res=$(test_get_resolution)
if [ "$res" != "1920x1080" ]; then
  echo "FAIL: Expected 1920x1080, got '$res'"
  exit 1
fi
rm -f "$MOCK_SYS_DIR/class/graphics/fb0/mode"

# Test Case 2: fb0/mode with no prefix, no refresh (Case B: 1024x768)
echo "Testing Case 2: fb0/mode with simple resolution format..."
echo "1024x768" > "$MOCK_SYS_DIR/class/graphics/fb0/mode"
res=$(test_get_resolution)
if [ "$res" != "1024x768" ]; then
  echo "FAIL: Expected 1024x768, got '$res'"
  exit 1
fi
rm -f "$MOCK_SYS_DIR/class/graphics/fb0/mode"

# Test Case 3: fb0/mode with bpp suffix but no prefix/p (Case C: 1280x1024-32)
echo "Testing Case 3: fb0/mode with bpp format..."
echo "1280x1024-32" > "$MOCK_SYS_DIR/class/graphics/fb0/mode"
res=$(test_get_resolution)
if [ "$res" != "1280x1024" ]; then
  echo "FAIL: Expected 1280x1024, got '$res'"
  exit 1
fi
rm -f "$MOCK_SYS_DIR/class/graphics/fb0/mode"

# Test Case 4: fb0/mode is missing, but fb0/modes exists (Case D: fallback)
echo "Testing Case 4: fb0/mode is missing, fallback to fb0/modes..."
echo "U:800x600p-57" > "$MOCK_SYS_DIR/class/graphics/fb0/modes"
res=$(test_get_resolution)
if [ "$res" != "800x600" ]; then
  echo "FAIL: Expected 800x600, got '$res'"
  exit 1
fi
rm -f "$MOCK_SYS_DIR/class/graphics/fb0/modes"

# Test Case 5: fb0/mode and modes are missing, fallback to fbset
echo "Testing Case 5: fallback to fbset mock..."
export MOCK_FBSET_MODE="1600x1200"
res=$(test_get_resolution)
if [ "$res" != "1600x1200" ]; then
  echo "FAIL: Expected 1600x1200, got '$res'"
  exit 1
fi

rm -rf "$MOCK_SYS_DIR"
echo "=== All get_resolution Logic Tests Passed Successfully! ==="
