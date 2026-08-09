#!/bin/bash
# Standalone test for ocs-console-font-size fontconfig toggling logic.

set -e

echo "=== Running Fontconfig Toggling Logic Tests ==="

export DRBL_SCRIPT_PATH="."
# Ensure /etc/drbl/drbl-ocs.conf is mocked or exists so sourcing ocs-functions doesn't fail
if [ ! -e "/etc/drbl/drbl-ocs.conf" ]; then
  mkdir -p /etc/drbl
  touch /etc/drbl/drbl-ocs.conf
fi
. scripts/sbin/ocs-functions

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
  local fontwidth_ fontheight_
  local font_parsed_
  font_parsed_="$(parse_console_font_size "$fontsize_")"
  fontwidth_="$(echo "$font_parsed_" | awk '{print $1}')"
  fontheight_="$(echo "$font_parsed_" | awk '{print $2}')"

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

# Test Case 1: Large font (16x32 - width x height)
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

# Test Case 2: Large font (32x16 - height x width)
echo "Testing with large font 32x16..."
test_adjust_fontconfig_for_fbterm "32x16"

if [ -e "$MOCK_ETC_FONTS/conf.d/70-force-bitmaps.conf" ]; then
  echo "FAIL: 70-force-bitmaps.conf should have been removed for 32x16 font size!"
  exit 1
fi

if [ ! -e "$MOCK_ETC_FONTS/conf.d/70-no-bitmaps.conf" ]; then
  echo "FAIL: 70-no-bitmaps.conf should have been created/linked for 32x16 font size!"
  exit 1
fi

# Test Case 3: Large font (32 - single value)
echo "Testing with large font 32 (single value)..."
test_adjust_fontconfig_for_fbterm "32"

if [ -e "$MOCK_ETC_FONTS/conf.d/70-force-bitmaps.conf" ]; then
  echo "FAIL: 70-force-bitmaps.conf should have been removed for 32 single font size!"
  exit 1
fi

if [ ! -e "$MOCK_ETC_FONTS/conf.d/70-no-bitmaps.conf" ]; then
  echo "FAIL: 70-no-bitmaps.conf should have been created/linked for 32 single font size!"
  exit 1
fi

# Test Case 4: Normal font (8x16)
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
