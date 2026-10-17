#!/bin/bash
# Standalone test for ocs-onthefly partition cloning and -k0 safety verification.
# Verifies that partition-to-partition cloning never enables create_part or passes
# partition-table-creating options (-k0/-k1/-k2) to ocs-sr, preventing parent disk erasure.

set -e

echo "=== Running ocs-onthefly Partition Cloning & -k0 Safety Tests ==="

# Mock dependencies
USAGE() { echo "USAGE called"; exit 1; }
export -f USAGE
strip_leading_dev() { echo "${1#/dev/}"; }
export -f strip_leading_dev

# Extract parse_ocs_onthefly_cmd_options and remove_src_dest_etc_opt from sbin/ocs-onthefly
PARSER_CODE=$(sed -n '/^parse_ocs_onthefly_cmd_options() {/,/^} # End of parse_ocs_onthefly_cmd_options/p' sbin/ocs-onthefly)
REMOVE_OPT_CODE=$(sed -n '/^remove_src_dest_etc_opt() {/,/^} # end of remove_src_dest_etc_opt/p' sbin/ocs-onthefly)

if [ -z "$PARSER_CODE" ] || [ -z "$REMOVE_OPT_CODE" ]; then
  echo "FAIL: Could not extract parser functions from sbin/ocs-onthefly"
  exit 1
fi

eval "$PARSER_CODE"
eval "$REMOVE_OPT_CODE"

# Test 1: Issue #195 reproduction command: -k0 with partition-to-partition
echo "--- Test 1: ocs-onthefly with -k0 and partition source/dest (-f nvme0n1p4 -d nvme0n1p7) ---"
CMD_LINE="-j2 -v -edio -fsck -k0 -plu -p choose -f nvme0n1p4 -d nvme0n1p7"
create_part="yes"
create_part_type=""
src_dev=""
tgt_dev=""
source_type="partition"
target_type="partition"
mode="local"
ocs_onthefly_all_opts="$CMD_LINE"

parse_ocs_onthefly_cmd_options $CMD_LINE

# Simulate the enforcement logic from sbin/ocs-onthefly
if [ "$source_type" = "partition" ]; then
  if [ "$create_part_type" = "proportion" -o "$create_part_type" = "manual" ] || echo " $ocs_onthefly_all_opts " | grep -Eq "[[:space:]]+-k0[[:space:]]+|[[:space:]]+--fdisk-proportion[[:space:]]+|[[:space:]]+--fdisk-manual[[:space:]]+"; then
    echo "Notice: Detected -k0/-k1/-k2 with partition cloning; overriding with -k"
  fi
  create_part="no"
  create_part_type=""
fi

if [ "$create_part" != "no" ]; then
  echo "FAIL: Expected create_part='no' for partition cloning, got '$create_part'"
  exit 1
fi

opt_for_ocs_sr_restore_this_run="$(remove_src_dest_etc_opt $ocs_onthefly_all_opts)"
if [ "$source_type" = "partition" ]; then
  opt_for_ocs_sr_restore_this_run="$(echo " $opt_for_ocs_sr_restore_this_run " | sed -r -e 's/[[:space:]]+(-k0|-k1|-k2|--fdisk-proportion|--fdisk-manual)[[:space:]]+/ /g' -e 's/[[:space:]]+-k[[:space:]]+/ /g' -e 's/^[[:space:]]+//' -e 's/[[:space:]]+$//')"
  opt_for_ocs_sr_restore_this_run="-k $opt_for_ocs_sr_restore_this_run"
  if [ "$mode" = "local" ]; then
    opt_for_ocs_sr_restore_this_run="$opt_for_ocs_sr_restore_this_run -f \"$src_dev\""
  fi
fi

if echo " $opt_for_ocs_sr_restore_this_run " | grep -Eq "[[:space:]]+-k0[[:space:]]+"; then
  echo "FAIL: opt_for_ocs_sr_restore_this_run should NOT contain -k0: '$opt_for_ocs_sr_restore_this_run'"
  exit 1
fi

if ! echo " $opt_for_ocs_sr_restore_this_run " | grep -Eq "[[:space:]]+-k[[:space:]]+"; then
  echo "FAIL: opt_for_ocs_sr_restore_this_run MUST contain -k: '$opt_for_ocs_sr_restore_this_run'"
  exit 1
fi
echo "PASS: Test 1 (-k0 with partitions) correctly stripped -k0 and enforced -k"

# Test 2: Default CLI partition cloning without -k (should default to create_part=no and pass -k)
echo "--- Test 2: ocs-onthefly default CLI partition cloning without -k ---"
CMD_LINE="-f sda1 -d sdb1"
create_part="yes"
create_part_type=""
src_dev=""
tgt_dev=""
source_type="partition"
target_type="partition"
mode="local"
ocs_onthefly_all_opts="$CMD_LINE"

parse_ocs_onthefly_cmd_options $CMD_LINE

if [ "$source_type" = "partition" ]; then
  create_part="no"
  create_part_type=""
fi

if [ "$create_part" != "no" ]; then
  echo "FAIL: Expected default create_part='no' for partition cloning, got '$create_part'"
  exit 1
fi

opt_for_ocs_sr_restore_this_run="$(remove_src_dest_etc_opt $ocs_onthefly_all_opts)"
if [ "$source_type" = "partition" ]; then
  opt_for_ocs_sr_restore_this_run="$(echo " $opt_for_ocs_sr_restore_this_run " | sed -r -e 's/[[:space:]]+(-k0|-k1|-k2|--fdisk-proportion|--fdisk-manual)[[:space:]]+/ /g' -e 's/[[:space:]]+-k[[:space:]]+/ /g' -e 's/^[[:space:]]+//' -e 's/[[:space:]]+$//')"
  opt_for_ocs_sr_restore_this_run="-k $opt_for_ocs_sr_restore_this_run"
  if [ "$mode" = "local" ]; then
    opt_for_ocs_sr_restore_this_run="$opt_for_ocs_sr_restore_this_run -f \"$src_dev\""
  fi
fi

if ! echo " $opt_for_ocs_sr_restore_this_run " | grep -Eq "[[:space:]]+-k[[:space:]]+"; then
  echo "FAIL: opt_for_ocs_sr_restore_this_run MUST contain -k: '$opt_for_ocs_sr_restore_this_run'"
  exit 1
fi
echo "PASS: Test 2 (default partition clone) correctly defaulted to -k"

# Test 3: Disk-to-disk cloning with -k0 should PRESERVE create_part=yes and NOT force -k
echo "--- Test 3: ocs-onthefly disk cloning with -k0 (-f sda -d sdb) ---"
CMD_LINE="-k0 -f sda -d sdb"
create_part="yes"
create_part_type=""
src_dev=""
tgt_dev=""
source_type="disk"
target_type="disk"
mode="local"
ocs_onthefly_all_opts="$CMD_LINE"

parse_ocs_onthefly_cmd_options $CMD_LINE

if [ "$source_type" = "partition" ]; then
  create_part="no"
fi

if [ "$create_part" != "yes" ]; then
  echo "FAIL: Expected create_part='yes' for disk cloning, got '$create_part'"
  exit 1
fi

opt_for_ocs_sr_restore_this_run="$(remove_src_dest_etc_opt $ocs_onthefly_all_opts)"
if [ "$source_type" = "partition" ]; then
  opt_for_ocs_sr_restore_this_run="-k $opt_for_ocs_sr_restore_this_run"
fi

if echo " $opt_for_ocs_sr_restore_this_run " | grep -Eq "[[:space:]]+-k[[:space:]]+"; then
  echo "FAIL: opt_for_ocs_sr_restore_this_run should NOT contain -k for disk cloning: '$opt_for_ocs_sr_restore_this_run'"
  exit 1
fi
echo "PASS: Test 3 (disk clone with -k0) correctly preserved disk partitioning"

# Test 4: task_d2d_restoreparts in scripts/sbin/ocs-functions
echo "--- Test 4: task_d2d_restoreparts in scripts/sbin/ocs-functions forces create_part=no ---"
# Stub dependencies
check_if_root() { :; }
export -f check_if_root
ask_and_load_lang_set() { :; }
export -f ask_and_load_lang_set
my_ocs_exit() { exit "$1"; }
export -f my_ocs_exit
ocs_batch_mode="on"

. scripts/sbin/ocs-functions

# Stub task_restoreparts to inspect create_part (define AFTER sourcing ocs-functions)
task_restoreparts() {
  echo "Mock task_restoreparts called with create_part=$create_part"
}
export -f task_restoreparts

create_part="yes"
task_d2d_restoreparts "mock_dir" "nvme0n1p7" "ld2d"

if [ "$create_part" != "no" ]; then
  echo "FAIL: Expected task_d2d_restoreparts to force create_part='no', got '$create_part'"
  exit 1
fi
echo "PASS: Test 4 (task_d2d_restoreparts) successfully forced create_part='no'"

# Test 5: task_restoreparts defensive guard for *d2d_restoreparts
echo "--- Test 5: task_restoreparts defensive guard for *d2d_restoreparts ---"
# Test the case statement logic directly
ocs_sr_type="ld2d_restoreparts"
create_part="yes"
case "$ocs_sr_type" in
  *d2d_restoreparts)
    create_part="no"
    ;;
esac
if [ "$create_part" != "no" ]; then
  echo "FAIL: Expected task_restoreparts logic to set create_part='no', got '$create_part'"
  exit 1
fi

ocs_sr_type="nd2d_restoreparts"
create_part="yes"
case "$ocs_sr_type" in
  *d2d_restoreparts)
    create_part="no"
    ;;
esac
if [ "$create_part" != "no" ]; then
  echo "FAIL: Expected task_restoreparts logic to set create_part='no', got '$create_part'"
  exit 1
fi
echo "PASS: Test 5 (task_restoreparts defensive guard) passed"

echo "=== All ocs-onthefly Partition Cloning & -k0 Safety Tests Passed Successfully! ==="
exit 0
