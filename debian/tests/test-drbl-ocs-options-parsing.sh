#!/bin/bash
# Standalone test for drbl-ocs options parsing to verify new options are parsed and stored in OCS_OPT.

set -e

echo "=== Running drbl-ocs Options Parsing Tests ==="

# Mock dependencies
USAGE() {
  echo "USAGE called"
}
export -f USAGE

# We will extract the variables initialization and parsing loop from sbin/drbl-ocs
# The loop starts with OCS_OPT= and ends with done (marking the end of the while loop)
PARSER_CODE=$(sed -n '/^OCS_OPT=/,/^done/p' sbin/drbl-ocs)

if [ -z "$PARSER_CODE" ]; then
  echo "FAIL: Could not extract options parser from sbin/drbl-ocs"
  exit 1
fi

test_parse() {
  local args=("$@")
  # Initialize variables like drbl-ocs does
  local OCS_OPT=""
  local nfs_restart="no"
  local always_restore="no"
  local pxe_menu_default_mode=""
  local mcast_loop="1"
  local udp_sender_extra_opt=""
  local USE_NTFSCLONE="no"
  local FORCE_TO_USE_DD="no"
  local only_access_by_owner="yes"
  local create_part="yes"
  local restore_mbr="yes"
  local restore_prebuild_mbr="no"
  local rm_win_swap_hib="no"
  local chk_img_restoreable_mod_save="yes"
  local chk_img_restoreable_mod_restore="yes"
  local chk_img_restoreable_on_srv="yes"

  # Load/evaluate the parser code with arguments
  # Set positional parameters to our args
  set -- "${args[@]}"
  eval "$PARSER_CODE"

  echo "$OCS_OPT"
}

# Test 1: Test basic direct-io option (-edio and --enable-direct-io)
echo "Testing -edio..."
res=$(test_parse -edio)
if [[ "$res" != *"-edio"* ]]; then
  echo "FAIL: -edio not added to OCS_OPT (got: $res)"
  exit 1
fi

res=$(test_parse --enable-direct-io)
if [[ "$res" != *"-edio"* ]]; then
  echo "FAIL: --enable-direct-io not mapped to -edio in OCS_OPT (got: $res)"
  exit 1
fi

# Test 2: Test save mtdblock and mmcblk options
echo "Testing mtdblock/mmcblk saving options..."
res=$(test_parse -smtd -smmcb)
if [[ "$res" != *"-smtd"* || "$res" != *"-smmcb"* ]]; then
  echo "FAIL: -smtd or -smmcb not added to OCS_OPT (got: $res)"
  exit 1
fi

res=$(test_parse --save-mtdblock --save-mmcblk)
if [[ "$res" != *"-smtd"* || "$res" != *"-smmcb"* ]]; then
  echo "FAIL: --save-mtdblock or --save-mmcblk not mapped properly (got: $res)"
  exit 1
fi

# Test 3: Test restore mtdblock and mmcblk options
echo "Testing mtdblock/mmcblk restoring options..."
res=$(test_parse -rmtd -rmmcb)
if [[ "$res" != *"-rmtd"* || "$res" != *"-rmmcb"* ]]; then
  echo "FAIL: -rmtd or -rmmcb not added to OCS_OPT (got: $res)"
  exit 1
fi

# Test 4: Test ocs alias blkdev option
echo "Testing -uoab..."
res=$(test_parse -uoab)
if [[ "$res" != *"-uoab"* ]]; then
  echo "FAIL: -uoab not added to OCS_OPT (got: $res)"
  exit 1
fi

# Test 5: Test decrypt bitlocker option
echo "Testing -dblk..."
res=$(test_parse -dblk yes)
if [[ "$res" != *"-dblk yes"* ]]; then
  echo "FAIL: -dblk yes not added to OCS_OPT (got: $res)"
  exit 1
fi

# Test 6: Test reencrypt luks option
echo "Testing -reluks..."
res=$(test_parse -reluks)
if [[ "$res" != *"-reluks"* ]]; then
  echo "FAIL: -reluks not added to OCS_OPT (got: $res)"
  exit 1
fi

# Test 7: Test enable luks option
echo "Testing -luks..."
res=$(test_parse -luks yes)
if [[ "$res" != *"-luks yes"* ]]; then
  echo "FAIL: -luks yes not added to OCS_OPT (got: $res)"
  exit 1
fi

# Test 8: Test gocryptfs and ecryptfs options
echo "Testing gocryptfs/ecryptfs options..."
res=$(test_parse -goc -pe mypass -pfg mypassfile)
if [[ "$res" != *"-goc"* || "$res" != *"-pe mypass"* || "$res" != *"-pfg mypassfile"* ]]; then
  echo "FAIL: -goc, -pe, or -pfg not mapped properly (got: $res)"
  exit 1
fi

echo "PASS: All options parsed and verified successfully!"
exit 0
