#!/bin/bash
# Standalone test for ocs-sr to verify that PARTCLONE_D2D_OPT and PARTCLONE_D2D_OPT_DD are correctly updated with -N when nogui is off.

set -e

echo "=== Running ocs-sr D2D ncurses Option Tests ==="

# Mock ocs-functions variables / functions we depend on
export BOOTUP="color"
export SETCOLOR_WARNING="echo -n"
export SETCOLOR_FAILURE="echo -n"
export SETCOLOR_NORMAL="echo -n"
export msg_delimiter_star_line="*****************************************************"

# Mock required functions so we can parse options in ocs-sr without failures
check_ocs_input_params() {
  return 0
}
export -f check_ocs_input_params

# Define dummy variables that ocs-sr expects
export PARTIMAGE_SAVE_OPT_INIT=""
export PARTIMAGE_RESTORE_OPT_INIT=""
export PARTCLONE_SAVE_OPT_INIT=""
export PARTCLONE_RESTORE_OPT_INIT=""
export PARTCLONE_SAVE_OPT_DD_INIT=""
export PARTCLONE_RESTORE_OPT_DD_INIT=""
export PARTCLONE_D2D_OPT="-a3 -z 10485760"
export PARTCLONE_D2D_OPT_DD="-z 16777216"

# We extract the initialization and nogui setup block of sbin/ocs-sr
SETUP_CODE=$(sed -n '/# Set\/Reset init values/,/ignore_crc/{p; /ignore_crc/{n;p}}' sbin/ocs-sr)

# Run the test case 1: When nogui is "off" (the default for TUI mode)
echo "Test 1: When nogui='off' (ncurses TUI mode is enabled)..."
nogui="off"
PARTCLONE_SAVE_OPT=""
PARTCLONE_RESTORE_OPT=""
PARTCLONE_SAVE_OPT_DD=""
PARTCLONE_RESTORE_OPT_DD=""
PARTCLONE_D2D_OPT="-a3 -z 10485760"
PARTCLONE_D2D_OPT_DD="-z 16777216"
rescue_mode="off"
do_partclone_crc_check="yes"

eval "$SETUP_CODE"

echo "Checking if -N was added to PARTCLONE_D2D_OPT..."
if [[ "$PARTCLONE_D2D_OPT" != *"-N"* ]]; then
  echo "FAIL: Expected -N in PARTCLONE_D2D_OPT, got '$PARTCLONE_D2D_OPT'"
  exit 1
fi

echo "Checking if -N was added to PARTCLONE_D2D_OPT_DD..."
if [[ "$PARTCLONE_D2D_OPT_DD" != *"-N"* ]]; then
  echo "FAIL: Expected -N in PARTCLONE_D2D_OPT_DD, got '$PARTCLONE_D2D_OPT_DD'"
  exit 1
fi

echo "PASS: -N successfully added to both D2D options when nogui is off!"

# Run the test case 2: When nogui is "on" (GUI is disabled/suppressed)
echo "Test 2: When nogui='on' (ncurses TUI mode is disabled)..."
nogui="on"
PARTCLONE_SAVE_OPT=""
PARTCLONE_RESTORE_OPT=""
PARTCLONE_SAVE_OPT_DD=""
PARTCLONE_RESTORE_OPT_DD=""
PARTCLONE_D2D_OPT="-a3 -z 10485760"
PARTCLONE_D2D_OPT_DD="-z 16777216"
rescue_mode="off"
do_partclone_crc_check="yes"

eval "$SETUP_CODE"

echo "Checking if -N is NOT in PARTCLONE_D2D_OPT..."
if [[ "$PARTCLONE_D2D_OPT" == *"-N"* ]]; then
  echo "FAIL: Unexpected -N in PARTCLONE_D2D_OPT when nogui is on!"
  exit 1
fi

echo "Checking if -N is NOT in PARTCLONE_D2D_OPT_DD..."
if [[ "$PARTCLONE_D2D_OPT_DD" == *"-N"* ]]; then
  echo "FAIL: Unexpected -N in PARTCLONE_D2D_OPT_DD when nogui is on!"
  exit 1
fi

echo "PASS: -N was NOT added to D2D options when nogui is on!"

echo "All ocs-sr D2D ncurses option tests passed successfully!"
exit 0
