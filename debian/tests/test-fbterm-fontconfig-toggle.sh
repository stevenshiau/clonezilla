#!/bin/bash
# Standalone test for ocs-console-font-size fontconfig toggling logic.

set -e

echo "=== Running Fontconfig Toggling Logic Tests ==="

# Set up temporary mock directories
MOCK_ETC_FONTS="$(mktemp -d /tmp/mock_etc_fonts.XXXXXX)"
mkdir -p "$MOCK_ETC_FONTS/conf.d"
mkdir -p "$MOCK_ETC_FONTS/conf.avail"

# Pre-populate 70-force-bitmaps.conf in conf.avail
echo "force-bitmaps-avail" > "$MOCK_ETC_FONTS/conf.avail/70-force-bitmaps.conf"
# Pre-populate 70-no-bitmaps.conf in conf.avail
echo "no-bitmaps-avail" > "$MOCK_ETC_FONTS/conf.avail/70-no-bitmaps.conf"

# Mimic the active state (by default, Clonezilla forces bitmap fonts)
ln -s "$MOCK_ETC_FONTS/conf.avail/70-force-bitmaps.conf" "$MOCK_ETC_FONTS/conf.d/70-force-bitmaps.conf"

# Define the function under test, substituting the hardcoded /etc/fonts with our mock directory
test_adjust_fontconfig_for_fbterm() {
  local fontsize_="$1"
  local fontheight_=""
  fontheight_="$(echo "$fontsize_" | cut -d'x' -f2)"

  if [ -n "$fontheight_" ]; then
    if [ "$fontheight_" -gt 16 ]; then
      echo "Large console font height ($fontheight_) detected. Adjusting fontconfig to use scalable fonts for fbterm CJK..."
      # Disable forcing of bitmap fonts
      if [ -e "$MOCK_ETC_FONTS/conf.d/70-force-bitmaps.conf" ]; then
        rm -f "$MOCK_ETC_FONTS/conf.d/70-force-bitmaps.conf"
      fi
      # Disable bitmap fonts entirely in Fontconfig so fallback uses TrueType (scalable) Unifont
      if [ -e "$MOCK_ETC_FONTS/conf.avail/70-no-bitmaps.conf" ]; then
        ln -sf "$MOCK_ETC_FONTS/conf.avail/70-no-bitmaps.conf" "$MOCK_ETC_FONTS/conf.d/70-no-bitmaps.conf"
      else
        # If the file does not exist, create our own custom no-bitmaps configuration
        cat <<-FNT_END >"$MOCK_ETC_FONTS/conf.d/70-no-bitmaps.conf"
<?xml version="1.0"?>
<!DOCTYPE fontconfig SYSTEM "fonts.dtd">
<fontconfig>
  <selectfont>
    <rejectfont>
      <pattern>
        <patelt name="scalable"><bool>false</bool></patelt>
      </pattern>
    </rejectfont>
  </selectfont>
</fontconfig>
FNT_END
      fi
    else
      echo "Normal console font height ($fontheight_) detected. Restoring default fontconfig with bitmap fonts enabled..."
      # Remove no-bitmaps configuration
      if [ -e "$MOCK_ETC_FONTS/conf.d/70-no-bitmaps.conf" ]; then
        rm -f "$MOCK_ETC_FONTS/conf.d/70-no-bitmaps.conf"
      fi
      # Enable forcing of bitmap fonts
      if [ -e "$MOCK_ETC_FONTS/conf.avail/70-force-bitmaps.conf" ]; then
        ln -sf "$MOCK_ETC_FONTS/conf.avail/70-force-bitmaps.conf" "$MOCK_ETC_FONTS/conf.d/70-force-bitmaps.conf"
      fi
    fi
  fi
}

# Test Case 1: Large font (16x32)
echo "Testing with large font 16x32..."
test_adjust_fontconfig_for_fbterm "16x32"

if [ -e "$MOCK_ETC_FONTS/conf.d/70-force-bitmaps.conf" ]; then
  echo "FAIL: 70-force-bitmaps.conf should have been removed for large font height!"
  exit 1
fi

if [ ! -e "$MOCK_ETC_FONTS/conf.d/70-no-bitmaps.conf" ]; then
  echo "FAIL: 70-no-bitmaps.conf should have been created/linked for large font height!"
  exit 1
fi

# Test Case 2: Normal font (8x16)
echo "Testing with normal font 8x16..."
test_adjust_fontconfig_for_fbterm "8x16"

if [ -e "$MOCK_ETC_FONTS/conf.d/70-no-bitmaps.conf" ]; then
  echo "FAIL: 70-no-bitmaps.conf should have been removed for normal font height!"
  exit 1
fi

if [ ! -e "$MOCK_ETC_FONTS/conf.d/70-force-bitmaps.conf" ]; then
  echo "FAIL: 70-force-bitmaps.conf should have been restored/linked for normal font height!"
  exit 1
fi

# Clean up mock directories
rm -rf "$MOCK_ETC_FONTS"

echo "=== All Fontconfig Toggling Logic Tests Passed Successfully! ==="
