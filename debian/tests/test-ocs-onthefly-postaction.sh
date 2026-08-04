#!/bin/bash
# Standalone test for ocs-onthefly postaction and variable preservation logic when sourcing ocs-vars

set -e

echo "=== Running ocs-onthefly Postaction and Variable Preservation Tests ==="

# Mock ocs-sr so it doesn't try to run actual restore commands
ocs-sr() {
  echo "Mock ocs-sr executed with args: $*"
  return 0
}
export -f ocs-sr

# Mock global variables required by local_dev_clone
export OCS_LOGFILE="/tmp/ocs-onthefly-test.log"
export msg_delimiter_star_line="*****************************************************"
export hd_src_tmp="/tmp"
export d2d_psuedo_img="d2d-pseudo"
export target_hd="sda"
export tgt_dev="sda"

# Clean up any existing test files
rm -f "$OCS_LOGFILE"
mkdir -p /var/lib/clonezilla

# Create a mock ocs-vars that contains postaction=true and empties other onthefly-specific vars
# but sets do_ntfs_512to4k_fix_flag=yes
cat <<EOF > /var/lib/clonezilla/ocs-vars
ocs_cmd="ocs-sr"
ocs_sr_type="ld2d_restoredisk"
ocs_sr_dev="sda"
target_dir=""
target_hd=""
ocs_sr_img_name="d2d-pseudo"
ocs_sr_mode=""
do_ntfs_512to4k_fix_flag="yes"
do_ntfs_4kto512_fix_flag="no"
source_type=""
mode=""
ocs_onthefly_mode=""
src_dev=""
tgt_dev=""
ocs_user_mode=""
postaction="true"
EOF

# Extract local_dev_clone function from sbin/ocs-onthefly
# We look for the function definition and match lines until the end of function marker
FUNCTION_CODE=$(sed -n '/^local_dev_clone() {/,/^} # end of local_dev_clone/p' sbin/ocs-onthefly)

if [ -z "$FUNCTION_CODE" ]; then
  echo "FAIL: Could not extract local_dev_clone function from sbin/ocs-onthefly"
  exit 1
fi

# Load the extracted function into our shell session
eval "$FUNCTION_CODE"

# Initialize our onthefly-specific variables to test values
postaction="choose"
source_type="disk"
mode="local"
ocs_onthefly_mode="ask"
src_dev="nvme0n1"
tgt_dev="sda"
ocs_user_mode="beginner"

# Run the function
local_dev_clone

# Assertions
echo "Verifying that variables are correctly preserved..."
if [ "$postaction" != "choose" ]; then
  echo "FAIL: Expected postaction='choose', but got '$postaction'"
  exit 1
fi

if [ "$source_type" != "disk" ]; then
  echo "FAIL: Expected source_type='disk', but got '$source_type'"
  exit 1
fi

if [ "$mode" != "local" ]; then
  echo "FAIL: Expected mode='local', but got '$mode'"
  exit 1
fi

if [ "$ocs_onthefly_mode" != "ask" ]; then
  echo "FAIL: Expected ocs_onthefly_mode='ask', but got '$ocs_onthefly_mode'"
  exit 1
fi

if [ "$src_dev" != "nvme0n1" ]; then
  echo "FAIL: Expected src_dev='nvme0n1', but got '$src_dev'"
  exit 1
fi

if [ "$tgt_dev" != "sda" ]; then
  echo "FAIL: Expected tgt_dev='sda', but got '$tgt_dev'"
  exit 1
fi

if [ "$ocs_user_mode" != "beginner" ]; then
  echo "FAIL: Expected ocs_user_mode='beginner', but got '$ocs_user_mode'"
  exit 1
fi

echo "Verifying that new flags are correctly read from ocs-vars..."
if [ "$do_ntfs_512to4k_fix_flag" != "yes" ]; then
  echo "FAIL: Expected do_ntfs_512to4k_fix_flag='yes', but got '$do_ntfs_512to4k_fix_flag'"
  exit 1
fi

if [ "$do_ntfs_4kto512_fix_flag" != "no" ]; then
  echo "FAIL: Expected do_ntfs_4kto512_fix_flag='no', but got '$do_ntfs_4kto512_fix_flag'"
  exit 1
fi

# Clean up
rm -f /var/lib/clonezilla/ocs-vars
rm -f "$OCS_LOGFILE"

echo "PASS: All postaction and variable preservation assertions passed successfully!"
exit 0
