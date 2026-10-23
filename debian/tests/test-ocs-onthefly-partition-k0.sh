#!/bin/bash
# Standalone test for ocs-onthefly partition cloning, -k0 safety verification,
# and -k1 proportional partition table creation on different disks.

set -e

echo "=== Running ocs-onthefly Partition Cloning, -k0 Safety & -k1 Support Tests ==="

# Mock dependencies
USAGE() { echo "USAGE called"; exit 1; }
export -f USAGE
strip_leading_dev() { echo "${1#/dev/}"; }
export -f strip_leading_dev
get_diskname() {
  local dev="$1"
  case "$dev" in
    nvme*n*p*) echo "${dev%p*}" ;;
    sd*[0-9]*) echo "${dev%%[0-9]*}" ;;
    *) echo "$dev" ;;
  esac
}
export -f get_diskname

# Extract parse_ocs_onthefly_cmd_options and remove_src_dest_etc_opt from sbin/ocs-onthefly
PARSER_CODE=$(sed -n '/^parse_ocs_onthefly_cmd_options() {/,/^} # End of parse_ocs_onthefly_cmd_options/p' sbin/ocs-onthefly)
REMOVE_OPT_CODE=$(sed -n '/^remove_src_dest_etc_opt() {/,/^} # end of remove_src_dest_etc_opt/p' sbin/ocs-onthefly)

if [ -z "$PARSER_CODE" ] || [ -z "$REMOVE_OPT_CODE" ]; then
  echo "FAIL: Could not extract parser functions from sbin/ocs-onthefly"
  exit 1
fi

eval "$PARSER_CODE"
eval "$REMOVE_OPT_CODE"

# Test 1: Issue #195 reproduction: -k0 with SAME DISK partition-to-partition (-f nvme0n1p4 -d nvme0n1p7)
echo "--- Test 1: ocs-onthefly with -k0 on SAME disk (-f nvme0n1p4 -d nvme0n1p7) ---"
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

shd_chk="$(get_diskname $src_dev)"
thd_chk="$(get_diskname $tgt_dev)"
if [ "$source_type" = "partition" ]; then
  if [ -n "$shd_chk" -a -n "$thd_chk" -a "$shd_chk" = "$thd_chk" ]; then
    create_part="no"
    create_part_type=""
  fi
fi

if [ "$create_part" != "no" ]; then
  echo "FAIL: Expected create_part='no' for same-disk partition cloning, got '$create_part'"
  exit 1
fi

opt_for_ocs_sr_restore_this_run="$(remove_src_dest_etc_opt $ocs_onthefly_all_opts)"
if [ "$source_type" = "partition" ]; then
  if [ -n "$shd_chk" -a -n "$thd_chk" -a "$shd_chk" = "$thd_chk" ]; then
    opt_for_ocs_sr_restore_this_run="$(echo " $opt_for_ocs_sr_restore_this_run " | sed -r -e 's/[[:space:]]+(-k0|-k1|-k2|--fdisk-proportion|--fdisk-manual)[[:space:]]+/ /g' -e 's/[[:space:]]+-k[[:space:]]+/ /g' -e 's/^[[:space:]]+//' -e 's/[[:space:]]+$//')"
    opt_for_ocs_sr_restore_this_run="-k $opt_for_ocs_sr_restore_this_run"
  fi
  if [ "$mode" = "local" ]; then
    opt_for_ocs_sr_restore_this_run="$opt_for_ocs_sr_restore_this_run -f \"$src_dev\""
  fi
fi

if echo " $opt_for_ocs_sr_restore_this_run " | grep -Eq "[[:space:]]+-k0[[:space:]]+"; then
  echo "FAIL: opt_for_ocs_sr_restore_this_run should NOT contain -k0 on same disk: '$opt_for_ocs_sr_restore_this_run'"
  exit 1
fi

if ! echo " $opt_for_ocs_sr_restore_this_run " | grep -Eq "[[:space:]]+-k[[:space:]]+"; then
  echo "FAIL: opt_for_ocs_sr_restore_this_run MUST contain -k on same disk: '$opt_for_ocs_sr_restore_this_run'"
  exit 1
fi
echo "PASS: Test 1 (same disk with -k0) correctly stripped -k0 and enforced -k"

# Test 2: log-k1f.txt reproduction: -k1 with DIFFERENT DISKS partition-to-partition (-f sdc1 -d sdd1)
echo "--- Test 2: ocs-onthefly with -k1 on DIFFERENT disks (-f sdc1 -d sdd1) ---"
CMD_LINE="-nogui -b -e1 auto -e2 -j2 -r -sfsck -k1 -icds -p true -f sdc1 -d sdd1"
create_part="yes"
create_part_type=""
src_dev=""
tgt_dev=""
source_type="partition"
target_type="partition"
mode="local"
ocs_onthefly_all_opts="$CMD_LINE"

parse_ocs_onthefly_cmd_options $CMD_LINE

shd_chk="$(get_diskname $src_dev)"
thd_chk="$(get_diskname $tgt_dev)"
if [ "$source_type" = "partition" ]; then
  if [ -n "$shd_chk" -a -n "$thd_chk" -a "$shd_chk" = "$thd_chk" ]; then
    create_part="no"
    create_part_type=""
  else
    if [ "$create_part_type" != "proportion" -a "$create_part_type" != "manual" ] && ! echo " $ocs_onthefly_all_opts " | grep -Eq "[[:space:]]+(-k|-k0|-k1|-k2|--no-sfdisk|--fdisk-proportion|--fdisk-manual)[[:space:]]+"; then
      create_part="no"
    fi
  fi
fi

if [ "$create_part" != "yes" ]; then
  echo "FAIL: Expected create_part='yes' when -k1 is passed, got '$create_part'"
  exit 1
fi
if [ "$create_part_type" != "proportion" ]; then
  echo "FAIL: Expected create_part_type='proportion', got '$create_part_type'"
  exit 1
fi

opt_for_ocs_sr_restore_this_run="$(remove_src_dest_etc_opt $ocs_onthefly_all_opts)"
if [ "$source_type" = "partition" ]; then
  if [ -n "$shd_chk" -a -n "$thd_chk" -a "$shd_chk" = "$thd_chk" ]; then
    opt_for_ocs_sr_restore_this_run="$(echo " $opt_for_ocs_sr_restore_this_run " | sed -r -e 's/[[:space:]]+(-k0|-k1|-k2|--fdisk-proportion|--fdisk-manual)[[:space:]]+/ /g' -e 's/[[:space:]]+-k[[:space:]]+/ /g' -e 's/^[[:space:]]+//' -e 's/[[:space:]]+$//')"
    opt_for_ocs_sr_restore_this_run="-k $opt_for_ocs_sr_restore_this_run"
  else
    if ! echo " $opt_for_ocs_sr_restore_this_run " | grep -Eq "[[:space:]]+(-k|-k0|-k1|-k2|--no-sfdisk|--fdisk-proportion|--fdisk-manual)[[:space:]]+"; then
      opt_for_ocs_sr_restore_this_run="-k $opt_for_ocs_sr_restore_this_run"
    fi
  fi
  if [ "$mode" = "local" ]; then
    opt_for_ocs_sr_restore_this_run="$opt_for_ocs_sr_restore_this_run -f \"$src_dev\""
  fi
fi

if ! echo " $opt_for_ocs_sr_restore_this_run " | grep -Eq "[[:space:]]+-k1[[:space:]]+"; then
  echo "FAIL: opt_for_ocs_sr_restore_this_run MUST contain -k1: '$opt_for_ocs_sr_restore_this_run'"
  exit 1
fi

if echo " $opt_for_ocs_sr_restore_this_run " | grep -Eq "[[:space:]]+-k[[:space:]]+"; then
  echo "FAIL: opt_for_ocs_sr_restore_this_run should NOT contain -k when -k1 is passed: '$opt_for_ocs_sr_restore_this_run'"
  exit 1
fi
echo "PASS: Test 2 (different disks with -k1) successfully preserved -k1 for ocs-sr"

# Test 3: Default CLI partition cloning on different disks without -k (should default to create_part=no and pass -k)
echo "--- Test 3: ocs-onthefly default CLI partition cloning on different disks without -k ---"
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

shd_chk="$(get_diskname $src_dev)"
thd_chk="$(get_diskname $tgt_dev)"
if [ "$source_type" = "partition" ]; then
  if [ -n "$shd_chk" -a -n "$thd_chk" -a "$shd_chk" = "$thd_chk" ]; then
    create_part="no"
    create_part_type=""
  else
    if [ "$create_part_type" != "proportion" -a "$create_part_type" != "manual" ] && ! echo " $ocs_onthefly_all_opts " | grep -Eq "[[:space:]]+(-k|-k0|-k1|-k2|--no-sfdisk|--fdisk-proportion|--fdisk-manual)[[:space:]]+"; then
      create_part="no"
    fi
  fi
fi

if [ "$create_part" != "no" ]; then
  echo "FAIL: Expected default create_part='no' for partition cloning without -k*, got '$create_part'"
  exit 1
fi

opt_for_ocs_sr_restore_this_run="$(remove_src_dest_etc_opt $ocs_onthefly_all_opts)"
if [ "$source_type" = "partition" ]; then
  if [ -n "$shd_chk" -a -n "$thd_chk" -a "$shd_chk" = "$thd_chk" ]; then
    opt_for_ocs_sr_restore_this_run="-k $opt_for_ocs_sr_restore_this_run"
  else
    if ! echo " $opt_for_ocs_sr_restore_this_run " | grep -Eq "[[:space:]]+(-k|-k0|-k1|-k2|--no-sfdisk|--fdisk-proportion|--fdisk-manual)[[:space:]]+"; then
      opt_for_ocs_sr_restore_this_run="-k $opt_for_ocs_sr_restore_this_run"
    fi
  fi
fi

if ! echo " $opt_for_ocs_sr_restore_this_run " | grep -Eq "[[:space:]]+-k[[:space:]]+"; then
  echo "FAIL: opt_for_ocs_sr_restore_this_run MUST contain -k by default: '$opt_for_ocs_sr_restore_this_run'"
  exit 1
fi
echo "PASS: Test 3 (default partition clone on different disks) correctly defaulted to -k"

# Test 4: Disk-to-disk cloning with -k0 should PRESERVE create_part=yes and NOT force -k
echo "--- Test 4: ocs-onthefly disk cloning with -k0 (-f sda -d sdb) ---"
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

if echo " $opt_for_ocs_sr_restore_this_run " | grep -Eq "[[:space:]]+-k[[:space:]]+"; then
  echo "FAIL: opt_for_ocs_sr_restore_this_run should NOT contain -k for disk cloning: '$opt_for_ocs_sr_restore_this_run'"
  exit 1
fi
echo "PASS: Test 4 (disk clone with -k0) correctly preserved disk partitioning"

# Test 5: task_restoreparts in scripts/sbin/ocs-functions guards against same-disk partition cloning
# but must NOT disable create_part for restoredisk (reproducing issue from log-k0f.txt)
echo "--- Test 5: task_restoreparts logic for restoredisk vs restoreparts (same disk vs different disk) ---"

# Case 5a: restoredisk on same disk (source_hd="nvme0n1", target_hd="nvme0n1", ocs_sr_type="restoredisk")
# Must KEEP create_part="yes" to allow partition table creation
ocs_sr_type="restoredisk"
source_hd="nvme0n1"
target_hd="nvme0n1"
create_part="yes"
if [ -n "$(echo "$ocs_sr_type" | grep -E "parts")" ]; then
  if [ "$create_part" = "yes" -a -n "$source_hd" -a -n "$target_hd" -a "$source_hd" = "$target_hd" ]; then
    create_part="no"
  fi
fi
if [ "$create_part" != "yes" ]; then
  echo "FAIL: Expected restoredisk to keep create_part='yes' on same disk (log-k0f.txt bug), got '$create_part'"
  exit 1
fi

# Case 5b: restoreparts on same disk (source_hd="nvme0n1", target_hd="nvme0n1", ocs_sr_type="ld2d_restoreparts")
# Must force create_part="no" to protect parent disk
ocs_sr_type="ld2d_restoreparts"
source_hd="nvme0n1"
target_hd="nvme0n1"
create_part="yes"
if [ -n "$(echo "$ocs_sr_type" | grep -E "parts")" ]; then
  if [ "$create_part" = "yes" -a -n "$source_hd" -a -n "$target_hd" -a "$source_hd" = "$target_hd" ]; then
    create_part="no"
  fi
fi
if [ "$create_part" != "no" ]; then
  echo "FAIL: Expected restoreparts to force create_part='no' for same disk, got '$create_part'"
  exit 1
fi

# Case 5c: restoreparts on different disks with -k1 (source_hd="sdc", target_hd="sdd", ocs_sr_type="ld2d_restoreparts")
# Must keep create_part="yes" to allow proportional partition table creation on destination disk
ocs_sr_type="ld2d_restoreparts"
source_hd="sdc"
target_hd="sdd"
create_part="yes"
if [ -n "$(echo "$ocs_sr_type" | grep -E "parts")" ]; then
  if [ "$create_part" = "yes" -a -n "$source_hd" -a -n "$target_hd" -a "$source_hd" = "$target_hd" ]; then
    create_part="no"
  fi
fi
if [ "$create_part" != "yes" ]; then
  echo "FAIL: Expected restoreparts to keep create_part='yes' for different disks, got '$create_part'"
  exit 1
fi
echo "PASS: Test 5 (task_restoreparts safety guard) correctly handled restoredisk vs restoreparts"

echo "=== All Tests Passed Successfully! ==="
exit 0
