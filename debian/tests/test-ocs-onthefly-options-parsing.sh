#!/bin/bash
# Standalone test for ocs-onthefly options parsing to verify new options are parsed and preserved.

set -e

echo "=== Running ocs-onthefly Options Parsing Tests ==="

# Mock dependencies
USAGE() {
  echo "USAGE called"
}
export -f USAGE

# Extract parse_ocs_onthefly_cmd_options function from sbin/ocs-onthefly
PARSER_CODE=$(sed -n '/^parse_ocs_onthefly_cmd_options() {/,/^} # End of parse_ocs_onthefly_cmd_options/p' sbin/ocs-onthefly)

if [ -z "$PARSER_CODE" ]; then
  echo "FAIL: Could not extract parse_ocs_onthefly_cmd_options from sbin/ocs-onthefly"
  exit 1
fi

# Load the extracted function
eval "$PARSER_CODE"

# Extract remove_src_dest_etc_opt function from sbin/ocs-onthefly
REMOVE_OPT_CODE=$(sed -n '/^remove_src_dest_etc_opt() {/,/^} # end of remove_src_dest_etc_opt/p' sbin/ocs-onthefly)

if [ -z "$REMOVE_OPT_CODE" ]; then
  echo "FAIL: Could not extract remove_src_dest_etc_opt from sbin/ocs-onthefly"
  exit 1
fi

# Load the extracted function
eval "$REMOVE_OPT_CODE"

# Test 1: Default value
echo "Testing default value of use_ocs_alias_blkdev..."
# Initialize variables
use_ocs_alias_blkdev="no"
ONTHEFLY_NET_PIPE_DEFAULT="netcat"
ONTHEFLY_NET_PIPE=""
reverse_connection="no"
STATUS=""
SOURCE_IP=""

parse_ocs_onthefly_cmd_options

if [ "$use_ocs_alias_blkdev" != "no" ]; then
  echo "FAIL: Expected default use_ocs_alias_blkdev='no', but got '$use_ocs_alias_blkdev'"
  exit 1
fi

# Test 2: Option -uoab
echo "Testing -uoab option..."
use_ocs_alias_blkdev="no"
ONTHEFLY_NET_PIPE=""
reverse_connection="no"
STATUS=""
SOURCE_IP=""

parse_ocs_onthefly_cmd_options -uoab

if [ "$use_ocs_alias_blkdev" != "yes" ]; then
  echo "FAIL: Expected use_ocs_alias_blkdev='yes' with -uoab, but got '$use_ocs_alias_blkdev'"
  exit 1
fi

# Test 3: Option --use-ocs-alias-blkdev
echo "Testing --use-ocs-alias-blkdev option..."
use_ocs_alias_blkdev="no"
ONTHEFLY_NET_PIPE=""
reverse_connection="no"
STATUS=""
SOURCE_IP=""

parse_ocs_onthefly_cmd_options --use-ocs-alias-blkdev

if [ "$use_ocs_alias_blkdev" != "yes" ]; then
  echo "FAIL: Expected use_ocs_alias_blkdev='yes' with --use-ocs-alias-blkdev, but got '$use_ocs_alias_blkdev'"
  exit 1
fi

# Test 4: Preserving -uoab through remove_src_dest_etc_opt
echo "Testing that -uoab is preserved when stripping source/destination options..."
all_opts="-uoab -f sda -d sdb -v"
clean_opts=$(remove_src_dest_etc_opt $all_opts)

if [[ "$clean_opts" != *"-uoab"* ]]; then
  echo "FAIL: Expected clean_opts to preserve '-uoab', but got '$clean_opts'"
  exit 1
fi

if [[ "$clean_opts" != *"-v"* ]]; then
  echo "FAIL: Expected clean_opts to preserve '-v', but got '$clean_opts'"
  exit 1
fi

if [[ "$clean_opts" == *"-f"* || "$clean_opts" == *"-d"* ]]; then
  echo "FAIL: Expected clean_opts to strip out '-f' and '-d', but got '$clean_opts'"
  exit 1
fi

# Test 5: Option -sro, --source-read-only, --source-dev-armour
echo "Testing -sro, --source-read-only, --source-dev-armour options..."
source_dev_armour="disable"
parse_ocs_onthefly_cmd_options -sro
if [ "$source_dev_armour" != "enable" ]; then
  echo "FAIL: Expected source_dev_armour='enable' with -sro, but got '$source_dev_armour'"
  exit 1
fi

source_dev_armour="disable"
parse_ocs_onthefly_cmd_options --source-read-only
if [ "$source_dev_armour" != "enable" ]; then
  echo "FAIL: Expected source_dev_armour='enable' with --source-read-only, but got '$source_dev_armour'"
  exit 1
fi

source_dev_armour="disable"
parse_ocs_onthefly_cmd_options --source-dev-armour
if [ "$source_dev_armour" != "enable" ]; then
  echo "FAIL: Expected source_dev_armour='enable' with --source-dev-armour, but got '$source_dev_armour'"
  exit 1
fi

# Test 6: Option -nsro, --no-source-read-only, --disable-source-dev-armour
echo "Testing -nsro, --no-source-read-only, --disable-source-dev-armour options..."
source_dev_armour="enable"
parse_ocs_onthefly_cmd_options -nsro
if [ "$source_dev_armour" != "disable" ]; then
  echo "FAIL: Expected source_dev_armour='disable' with -nsro, but got '$source_dev_armour'"
  exit 1
fi

source_dev_armour="enable"
parse_ocs_onthefly_cmd_options --skip-source-read-only
if [ "$source_dev_armour" != "disable" ]; then
  echo "FAIL: Expected source_dev_armour='disable' with --skip-source-read-only, but got '$source_dev_armour'"
  exit 1
fi

source_dev_armour="enable"
parse_ocs_onthefly_cmd_options --disable-source-dev-armour
if [ "$source_dev_armour" != "disable" ]; then
  echo "FAIL: Expected source_dev_armour='disable' with --disable-source-dev-armour, but got '$source_dev_armour'"
  exit 1
fi

echo "PASS: All ocs-onthefly options parsing assertions passed successfully!"
exit 0
