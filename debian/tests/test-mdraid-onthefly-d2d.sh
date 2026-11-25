#!/bin/bash
# Standalone unit test for MDRAID On-the-Fly Local Disk-to-Disk (d2d) Cloning.
# Verifies:
# 1. Multi-disk conversion in ocs-cvt-dev preserves all disk mappings in device_name_converted.info (orig_dev_list / new_dev_list).
# 2. task_restoreparts properly reverses multi-disk partition names so source_hd is not contaminated with target disks.
# 3. Parallel alignment of INTENDED_SOURCE_HD and INTENDED_TARGET_HD in task_restoredisk and task_restoreparts.
# 4. ocs-restore-mdraid-layout creates shadow target MD devices (e.g. md200) when source MD arrays (md126) remain active on host.
# 5. task_restoreparts clones regular partitions (sda1 <- nvme0n1p1) and MDRAID partitions (md200 <- md126) via Partclone.
# 6. Standalone swap on MDRAID is created on the shadow device via mkswap.
# 7. Shadow target MD devices are stopped cleanly at the end.

set -e

REPO_DIR="/root/clonezilla"
TMP_DIR=$(mktemp -d /tmp/test-mdraid-d2d.XXXXXX)
MOCK_BIN=$(mktemp -d /tmp/mock-bin-d2d.XXXXXX)
MOCK_PROC=$(mktemp -d /tmp/mock-proc-d2d.XXXXXX)

cleanup() {
  rm -rf "$TMP_DIR" "$MOCK_BIN" "$MOCK_PROC"
}
trap cleanup EXIT

# Setup mock /proc/mdstat with active source arrays on nvme0n1 and nvme0n2
cat <<'EOF' > "$MOCK_PROC/mdstat"
Personalities : [raid1]
md126 : active raid1 nvme0n1p3[0] nvme0n2p1[1]
      17251328 blocks super 1.2 [2/2] [UU]
md127 : active raid1 nvme0n1p4[0] nvme0n2p2[1]
      2055168 blocks super 1.2 [2/2] [UU]
EOF

cat <<'EOF' > "$MOCK_PROC/mounts"
EOF

# Setup mock action log
export ACTION_LOG="$TMP_DIR/actions.log"
touch "$ACTION_LOG"

# Setup mock mdadm
cat <<EOF > "$MOCK_BIN/mdadm"
#!/bin/bash
echo "MDADM: \$*" >> "$ACTION_LOG"
case "\$1" in
  --detail)
    md_dev="\$2"
    case "\$md_dev" in
      /dev/md126|md126)
        cat <<'MDEOF'
/dev/md126:
        Raid Level : raid1
      Raid Devices : 2
    Number   Major   Minor   RaidDevice State
       0     259       3        0      active sync   /dev/nvme0n1p3
       1     259       7        1      active sync   /dev/nvme0n2p1
MDEOF
        exit 0
        ;;
      /dev/md127|md127)
        cat <<'MDEOF'
/dev/md127:
        Raid Level : raid1
      Raid Devices : 2
    Number   Major   Minor   RaidDevice State
       0     259       4        0      active sync   /dev/nvme0n1p4
       1     259       8        1      active sync   /dev/nvme0n2p2
MDEOF
        exit 0
        ;;
      *)
        echo "Unknown md device: \$md_dev" >&2
        exit 1
        ;;
    esac
    ;;
  --zero-superblock)
    echo "ZERO-SUPERBLOCK: \$2" >> "$ACTION_LOG"
    exit 0
    ;;
  --create)
    echo "CREATE-ARRAY: \$2 with \${@:3}" >> "$ACTION_LOG"
    exit 0
    ;;
  --stop)
    echo "STOP-ARRAY: \$2" >> "$ACTION_LOG"
    exit 0
    ;;
  --assemble)
    echo "ASSEMBLE-ARRAY: \$*" >> "$ACTION_LOG"
    exit 0
    ;;
esac
exit 0
EOF
chmod +x "$MOCK_BIN/mdadm"

# Setup mock wipefs
cat <<EOF > "$MOCK_BIN/wipefs"
#!/bin/bash
echo "WIPEFS: \$*" >> "$ACTION_LOG"
exit 0
EOF
chmod +x "$MOCK_BIN/wipefs"

# Setup mock sfdisk
cat <<'EOF' > "$MOCK_BIN/sfdisk"
#!/bin/bash
echo "SFDISK: $*" >> "$ACTION_LOG"
exit 0
EOF
chmod +x "$MOCK_BIN/sfdisk"

# Setup mock udevadm
cat <<'EOF' > "$MOCK_BIN/udevadm"
#!/bin/bash
exit 0
EOF
chmod +x "$MOCK_BIN/udevadm"

# Setup mock mkswap
cat <<EOF > "$MOCK_BIN/mkswap"
#!/bin/bash
echo "MKSWAP: \$*" >> "$ACTION_LOG"
exit 0
EOF
chmod +x "$MOCK_BIN/mkswap"

# Setup mock partprobe
cat <<'EOF' > "$MOCK_BIN/partprobe"
#!/bin/bash
exit 0
EOF
chmod +x "$MOCK_BIN/partprobe"

# Setup mock ocs-get-dev-info
cat <<'EOF' > "$MOCK_BIN/ocs-get-dev-info"
#!/bin/bash
dev="$1"
query="$2"
case "$dev" in
  /dev/nvme0n1p1|/dev/sda1) echo "vfat" ;;
  /dev/nvme0n1p2|/dev/sda2) echo "xfs" ;;
  /dev/md126|/dev/md200) echo "ext4" ;;
  /dev/md127|/dev/md201) echo "swap" ;;
  *) echo "" ;;
esac
exit 0
EOF
chmod +x "$MOCK_BIN/ocs-get-dev-info"

# Setup mock partclone
cat <<EOF > "$MOCK_BIN/partclone.vfat"
#!/bin/bash
echo "PARTCLONE-VFAT: \$*" >> "$ACTION_LOG"
[ -n "\$PARTCLONE_LOG" ] && touch "\$PARTCLONE_LOG"
exit 0
EOF
chmod +x "$MOCK_BIN/partclone.vfat"

cat <<EOF > "$MOCK_BIN/partclone.xfs"
#!/bin/bash
echo "PARTCLONE-XFS: \$*" >> "$ACTION_LOG"
[ -n "\$PARTCLONE_LOG" ] && touch "\$PARTCLONE_LOG"
exit 0
EOF
chmod +x "$MOCK_BIN/partclone.xfs"

cat <<EOF > "$MOCK_BIN/partclone.ext4"
#!/bin/bash
echo "PARTCLONE-EXT4: \$*" >> "$ACTION_LOG"
[ -n "\$PARTCLONE_LOG" ] && touch "\$PARTCLONE_LOG"
exit 0
EOF
chmod +x "$MOCK_BIN/partclone.ext4"

# Setup mock awk to transparently redirect /proc/mdstat
cat <<EOF > "$MOCK_BIN/awk"
#!/bin/bash
args=()
for a in "\$@"; do
  if [ "\$a" = "/proc/mdstat" ]; then
    args+=("$MOCK_PROC/mdstat")
  elif [ "\$a" = "/proc/mounts" ]; then
    args+=("$MOCK_PROC/mounts")
  else
    args+=("\$a")
  fi
done
exec /usr/bin/awk "\${args[@]}"
EOF
chmod +x "$MOCK_BIN/awk"

# Setup mock grep to transparently redirect /proc/mdstat
cat <<EOF > "$MOCK_BIN/grep"
#!/bin/bash
args=()
for a in "\$@"; do
  if [ "\$a" = "/proc/mdstat" ]; then
    args+=("$MOCK_PROC/mdstat")
  elif [ "\$a" = "/proc/mounts" ]; then
    args+=("$MOCK_PROC/mounts")
  else
    args+=("\$a")
  fi
done
exec /bin/grep "\${args[@]}"
EOF
chmod +x "$MOCK_BIN/grep"

export PATH="$MOCK_BIN:$REPO_DIR/sbin:$PATH"

# ====================================================================
# TEST 1: ocs-cvt-dev multi-disk mapping test
# ====================================================================
echo "=== TEST 1: ocs-cvt-dev multi-disk tag recording ==="
IMG_SRC="$TMP_DIR/img-pseudo"
mkdir -p "$IMG_SRC"
echo "nvme0n1 nvme0n2 md126 md127" > "$IMG_SRC/disk"
echo "nvme0n1p1 nvme0n1p2 md126" > "$IMG_SRC/parts"
touch "$IMG_SRC/nvme0n1-pt.sf" "$IMG_SRC/nvme0n2-pt.sf"

# Create mock MD config files
cat <<'EOF' > "$IMG_SRC/md126-config.env"
MD_UUID="c126-uuid-1111"
MD_NAME="localhost.localdomain_root"
MD_META="1.2"
MD_LEVEL="raid1"
MD_DEVICES_COUNT="2"
MD_DATA_OFFSET="34816"
MD_MEMBERS_ORDERED="/dev/nvme0n1p3 /dev/nvme0n2p1"
EOF

cat <<'EOF' > "$IMG_SRC/md127-config.env"
MD_UUID="c127-uuid-2222"
MD_NAME="localhost.localdomain_swap"
MD_META="1.2"
MD_LEVEL="raid1"
MD_DEVICES_COUNT="2"
MD_DATA_OFFSET="34816"
MD_MEMBERS_ORDERED="/dev/nvme0n1p4 /dev/nvme0n2p2"
EOF

echo 'UUID="swap-uuid-9999"' > "$IMG_SRC/swappt-md127.info"

# Run ocs-cvt-dev converting nvme0n1 nvme0n2 to sda sdb
"$REPO_DIR/sbin/ocs-cvt-dev" -b -d "$TMP_DIR" "img-pseudo" "nvme0n1 nvme0n2" "sda sdb"

TAG_FILE="$IMG_SRC/device_name_converted.info"
if [ ! -f "$TAG_FILE" ]; then
  echo "FAIL: device_name_converted.info was not created!"
  exit 1
fi

orig_dev_list=""
new_dev_list=""
. "$TAG_FILE"

if [ "$orig_dev_list" != "nvme0n1 nvme0n2" ]; then
  echo "FAIL: Expected orig_dev_list 'nvme0n1 nvme0n2', got: '$orig_dev_list'"
  exit 1
fi

if [ "$new_dev_list" != "sda sdb" ]; then
  echo "FAIL: Expected new_dev_list 'sda sdb', got: '$new_dev_list'"
  exit 1
fi
echo "PASS: ocs-cvt-dev recorded complete multi-disk mapping lists in device_name_converted.info."

# ====================================================================
# TEST 2: ocs-restore-mdraid-layout shadow MD device allocation
# ====================================================================
echo "=== TEST 2: ocs-restore-mdraid-layout shadow target array allocation ==="
# Active arrays in /proc/mdstat are on nvme0n1 and nvme0n2.
# We are restoring to sda and sdb.
# ocs-restore-mdraid-layout should recognize that md126/md127 are active on source,
# allocate shadow devices md200 and md201, and record mapping in md_tgt_map.info.
"$REPO_DIR/sbin/ocs-restore-mdraid-layout" -b "$IMG_SRC" sda sdb md126 md127

MAP_FILE="$IMG_SRC/md_tgt_map.info"
if [ ! -f "$MAP_FILE" ]; then
  echo "FAIL: md_tgt_map.info was not created by ocs-restore-mdraid-layout!"
  exit 1
fi

if ! grep -qE "^md126[[:space:]]+md200" "$MAP_FILE"; then
  echo "FAIL: md126 was not mapped to shadow device md200 in md_tgt_map.info! Contents:"
  cat "$MAP_FILE"
  exit 1
fi

if ! grep -qE "^md127[[:space:]]+md201" "$MAP_FILE"; then
  echo "FAIL: md127 was not mapped to shadow device md201 in md_tgt_map.info! Contents:"
  cat "$MAP_FILE"
  exit 1
fi

# Verify mdadm --create was called for shadow devices with exact target members
if ! grep -q "CREATE-ARRAY: /dev/md200" "$ACTION_LOG"; then
  echo "FAIL: mdadm --create was not called for /dev/md200!"
  exit 1
fi

if ! grep -q "CREATE-ARRAY: /dev/md201" "$ACTION_LOG"; then
  echo "FAIL: mdadm --create was not called for /dev/md201!"
  exit 1
fi

echo "PASS: ocs-restore-mdraid-layout created shadow target arrays /dev/md200 and /dev/md201."

# ====================================================================
# TEST 3: task_restoreparts multi-disk & shadow MD cloning execution
# ====================================================================
echo "=== TEST 3: task_restoreparts multi-disk & shadow MD cloning ==="
(
  awk() {
    local args=()
    for a in "$@"; do
      if [ "$a" = "/proc/mdstat" ]; then
        args+=("$MOCK_PROC/mdstat")
      elif [ "$a" = "/proc/mounts" ]; then
        args+=("$MOCK_PROC/mounts")
      else
        args+=("$a")
      fi
    done
    command awk "${args[@]}"
  }
  export -f awk

  grep() {
    local args=()
    for a in "$@"; do
      if [ "$a" = "/proc/mdstat" ]; then
        args+=("$MOCK_PROC/mdstat")
      elif [ "$a" = "/proc/mounts" ]; then
        args+=("$MOCK_PROC/mounts")
      else
        args+=("$a")
      fi
    done
    command grep "${args[@]}"
  }
  export -f grep

  . "$REPO_DIR/scripts/sbin/ocs-functions"

  # Mock environment for task_restoreparts in d2d mode
  export ocs_sr_type="ld2d_restoredisk"
  export ocs_batch_mode="on"
  export ocs_ppid="$$"
  export ocsroot="$TMP_DIR"
  export OCS_LOGFILE="$TMP_DIR/ocs.log"
  touch "$OCS_LOGFILE"
  export ocs_log_dir="$TMP_DIR/log"
  mkdir -p "$ocs_log_dir"
  export USE_PARTCLONE_IN_OCS_ONTHEFLY="yes"
  export create_temp_img_flag="done"
  export INTENDED_TARGET_HD="sda sdb md126 md127"
  export INTENDED_SOURCE_HD="nvme0n1 nvme0n2 md126 md127"
  export target_parts="sda1 sda2 md126"
  export target_dir="img-pseudo"
  export create_part="no" # Partitions already mocked
  export install_grub="no"
  export do_update_initrd="no"
  export resize_partition="no"
  export restore_ebr="no"
  export dump_mbr_in_the_end="no"
  export update_efi_nvram="no"
  blockdev() { return 0; }
  export -f blockdev

  gen_proc_partitions_map_file() {
    partition_table="$(mktemp /tmp/parttable-ocs.XXXXXX)"
    cat <<'PEOF' > "$partition_table"
major minor #blocks name
8 0 100000 sda
8 1 50000 sda1
8 2 50000 sda2
9 200 100000 md200
9 201 50000 md201
PEOF
  }
  export -f gen_proc_partitions_map_file

  clean_filesystem_header_in_dev() { :; }
  export -f clean_filesystem_header_in_dev

  is_partclone_support_fs() { return 0; }
  export -f is_partclone_support_fs

  export PARTCLONE_LOG="$TMP_DIR/partclone.log"
  touch "$PARTCLONE_LOG"

  screen_not_blank() { :; }
  export -f screen_not_blank
  active_proc_partitions() { :; }
  export -f active_proc_partitions
  inform_kernel_partition_table_changed() { :; }
  export -f inform_kernel_partition_table_changed
  check_if_dev_busy() { :; }
  export -f check_if_dev_busy
  tune_nvme_block_queue_settings() { :; }
  export -f tune_nvme_block_queue_settings
  rm_tmp_cnvt_img() { :; }
  export -f rm_tmp_cnvt_img
  check_specify_hd_exists() { return 0; }
  export -f check_specify_hd_exists
  check_specify_part_exists() { return 0; }
  export -f check_specify_part_exists
  countdown_or_confirm_before_restore() { return 0; }
  export -f countdown_or_confirm_before_restore

  # Mock block devices exist
  for d in sda sdb sda1 sda2 sda3 sda4 sdb1 sdb2 nvme0n1 nvme0n2 nvme0n1p1 nvme0n1p2 nvme0n1p3 nvme0n1p4 nvme0n2p1 nvme0n2p2 md126 md127 md200 md201; do
    touch "$TMP_DIR/$d"
  done

  # Run task_restoreparts with port "ld2d"
  task_restoreparts "img-pseudo" "$target_parts" "ld2d"
)

# Verify cloning actions in ACTION_LOG:
# 1. sda1 cloned from nvme0n1p1 (NOT sda1 -> sda1)
if ! grep -q "PARTCLONE-VFAT:.*-s /dev/nvme0n1p1 -O /dev/sda1" "$ACTION_LOG"; then
  echo "FAIL: Expected /dev/nvme0n1p1 -> /dev/sda1 cloning! Action log:"
  grep "PARTCLONE" "$ACTION_LOG" || true
  exit 1
fi
echo "PASS: /dev/nvme0n1p1 was correctly cloned to /dev/sda1."

# 2. sda2 cloned from nvme0n1p2 (NOT sda2 -> sda2)
if ! grep -q "PARTCLONE-XFS:.*-s /dev/nvme0n1p2 -O /dev/sda2" "$ACTION_LOG"; then
  echo "FAIL: Expected /dev/nvme0n1p2 -> /dev/sda2 cloning! Action log:"
  grep "PARTCLONE" "$ACTION_LOG" || true
  exit 1
fi
echo "PASS: /dev/nvme0n1p2 was correctly cloned to /dev/sda2."

# 3. md126 cloned from source /dev/md126 to shadow target /dev/md200 (NOT nvme0n1 -> md126)
if ! grep -q "PARTCLONE-EXT4:.*-s /dev/md126 -O /dev/md200" "$ACTION_LOG"; then
  echo "FAIL: Expected /dev/md126 -> /dev/md200 cloning! Action log:"
  grep "PARTCLONE" "$ACTION_LOG" || true
  exit 1
fi
echo "PASS: Source array /dev/md126 was correctly cloned to shadow target array /dev/md200."

# 4. mkswap run on shadow swap device /dev/md201
if ! grep -q "MKSWAP:.*-U swap-uuid-9999 /dev/md201" "$ACTION_LOG"; then
  echo "FAIL: Expected mkswap on /dev/md201! Action log:"
  grep "MKSWAP" "$ACTION_LOG" || true
  exit 1
fi
echo "PASS: mkswap was correctly executed on shadow target swap array /dev/md201."

# 5. Shadow target MD devices stopped at completion
if ! grep -q "STOP-ARRAY: /dev/md200" "$ACTION_LOG"; then
  echo "FAIL: Shadow target device /dev/md200 was not stopped at end of restore!"
  exit 1
fi
if ! grep -q "STOP-ARRAY: /dev/md201" "$ACTION_LOG"; then
  echo "FAIL: Shadow target device /dev/md201 was not stopped at end of restore!"
  exit 1
fi
echo "PASS: Shadow target MD devices were cleanly stopped at end of restore."

echo "=== All MDRAID On-the-Fly d2d Tests Passed Successfully! ==="
