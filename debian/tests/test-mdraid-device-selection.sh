#!/bin/bash
# Standalone test for MDRAID device selection during save and restore (Issue #199)
# Verifies that operations on non-RAID disks do not save or recreate unrelated MDRAID arrays.

set -e

REPO_DIR="/root/clonezilla"
TMP_DIR=$(mktemp -d /tmp/repro-mdraid-199.XXXXXX)
MOCK_BIN=$(mktemp -d /tmp/mock-bin-199.XXXXXX)
MOCK_PROC=$(mktemp -d /tmp/mock-proc-199.XXXXXX)

cleanup() {
  rm -rf "$TMP_DIR" "$MOCK_BIN" "$MOCK_PROC"
}
trap cleanup EXIT

# Setup mock /proc/mdstat with md0 on sdb1..sdg1
cat <<'EOF' > "$MOCK_PROC/mdstat"
Personalities : [raid5]
md0 : active raid5 sdb1[0] sdc1[1] sdd1[2] sde1[3] sdf1[4] sdg1[5]
      5000000 blocks super 1.0 level 5, 512k chunk, algorithm 2 [6/6] [UUUUUU]
EOF

cat <<'EOF' > "$MOCK_PROC/mounts"
EOF

# Setup mock mdadm
cat <<EOF > "$MOCK_BIN/mdadm"
#!/bin/bash
echo "MDADM: \$*" >> "$TMP_DIR/mdadm.log"
if [ "\$1" = "--detail" ]; then
  cat <<'MDEOF'
/dev/md0:
           Version : 1.0
     Creation Time : Tue Jan  1 00:00:00 2026
        Raid Level : raid5
        Array Size : 5000000 (4.77 GiB 5.12 GB)
     Used Dev Size : 1000000 (976.56 MiB 1024.00 MB)
      Raid Devices : 6
     Total Devices : 6
       Persistence : Superblock is persistent

             State : clean 
    Active Devices : 6
   Working Devices : 6
    Failed Devices : 0
     Spare Devices : 0

            Layout : left-symmetric
        Chunk Size : 512K

Consistency Policy : resync

              Name : rescue:0
              UUID : 12345678:9abcdef0:12345678:9abcdef0
            Events : 100

    Number   Major   Minor   RaidDevice State
       0       8       17        0      active sync   /dev/sdb1
       1       8       33        1      active sync   /dev/sdc1
       2       8       49        2      active sync   /dev/sdd1
       3       8       65        3      active sync   /dev/sde1
       4       8       81        4      active sync   /dev/sdf1
       5       8       97        5      active sync   /dev/sdg1
MDEOF
  exit 0
fi
if [ "\$1" = "--examine" ]; then
  echo "Data Offset : 2048 sectors"
  exit 0
fi
if [ "\$1" = "--zero-superblock" ]; then
  echo "ZERO-SUPERBLOCK: \$2" >> "$TMP_DIR/wiped.log"
  exit 0
fi
exit 0
EOF
chmod +x "$MOCK_BIN/mdadm"

# Setup mock awk to transparently redirect /proc/mdstat and /proc/mounts
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

# Setup mock grep to transparently redirect /proc/mdstat and /proc/mounts
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

# Setup mock sfdisk
cat <<'EOF' > "$MOCK_BIN/sfdisk"
#!/bin/bash
exit 0
EOF
chmod +x "$MOCK_BIN/sfdisk"

# Setup mock wipefs
cat <<EOF > "$MOCK_BIN/wipefs"
#!/bin/bash
echo "WIPEFS: \$*" >> "$TMP_DIR/wiped.log"
exit 0
EOF
chmod +x "$MOCK_BIN/wipefs"

# Setup mock udevadm
cat <<'EOF' > "$MOCK_BIN/udevadm"
#!/bin/bash
exit 0
EOF
chmod +x "$MOCK_BIN/udevadm"

export PATH="$MOCK_BIN:$REPO_DIR/sbin:$PATH"

echo "=== TEST 1: get_md_devices_from_disk_or_part resolution ==="
(
  # Override /proc/mdstat in subshell
  awk() {
    local args=()
    for a in "$@"; do
      if [ "$a" = "/proc/mdstat" ]; then
        args+=("$MOCK_PROC/mdstat")
      else
        args+=("$a")
      fi
    done
    command awk "${args[@]}"
  }
  export -f awk
  . "$REPO_DIR/scripts/sbin/ocs-functions"

  # 1a. Query for unrelated disk sda -> should return empty
  res_sda="$(get_md_devices_from_disk_or_part "sda")"
  if [ -n "$res_sda" ]; then
    echo "FAIL: Expected empty MD devices for sda, got: $res_sda"
    exit 1
  fi
  echo "PASS: get_md_devices_from_disk_or_part correctly returned empty for unrelated sda."

  # 1b. Query for member disk sdb -> should return md0
  res_sdb="$(get_md_devices_from_disk_or_part "sdb")"
  if [ "$res_sdb" != "md0" ]; then
    echo "FAIL: Expected md0 for sdb, got: $res_sdb"
    exit 1
  fi
  echo "PASS: get_md_devices_from_disk_or_part correctly returned md0 for member disk sdb."

  # 1c. Query for member partition sdc1 -> should return md0
  res_part="$(get_md_devices_from_disk_or_part "/dev/sdc1")"
  if [ "$res_part" != "md0" ]; then
    echo "FAIL: Expected md0 for /dev/sdc1, got: $res_part"
    exit 1
  fi
  echo "PASS: get_md_devices_from_disk_or_part correctly returned md0 for member partition sdc1."

  # 1d. Query for array directly md0 -> should return md0
  res_md="$(get_md_devices_from_disk_or_part "/dev/md0")"
  if [ "$res_md" != "md0" ]; then
    echo "FAIL: Expected md0 for /dev/md0, got: $res_md"
    exit 1
  fi
  echo "PASS: get_md_devices_from_disk_or_part correctly returned md0 when queried directly."
)

echo "=== TEST 2: ocs-save-mdraid-layout device filtering ==="
IMG_SDA="$TMP_DIR/img-sda"
mkdir -p "$IMG_SDA"

# 2a. Save when target disk is sda (unrelated) -> must NOT save md0
"$REPO_DIR/sbin/ocs-save-mdraid-layout" "$IMG_SDA" sda
if [ -f "$IMG_SDA/md0-config.env" ]; then
  echo "FAIL: md0-config.env was saved for unrelated disk sda!"
  exit 1
fi
echo "PASS: ocs-save-mdraid-layout did not save md0 when sda was specified."

# 2b. Save when target disk is sdb (member) -> must save md0
IMG_SDB="$TMP_DIR/img-sdb"
mkdir -p "$IMG_SDB"
"$REPO_DIR/sbin/ocs-save-mdraid-layout" "$IMG_SDB" sdb
if [ ! -f "$IMG_SDB/md0-config.env" ]; then
  echo "FAIL: md0-config.env was NOT saved when member disk sdb was specified!"
  exit 1
fi
echo "PASS: ocs-save-mdraid-layout correctly saved md0 when sdb was specified."

echo "=== TEST 3: ocs-mdraid-stop device filtering ==="
# 3a. ocs-mdraid-stop with unrelated disk nvme0n1 -> should NOT stop md0
rm -f "$TMP_DIR/mdadm.log"
"$REPO_DIR/sbin/ocs-mdraid-stop" nvme0n1
if grep -q "MDADM: --stop /dev/md0" "$TMP_DIR/mdadm.log" 2>/dev/null; then
  echo "FAIL: ocs-mdraid-stop stopped md0 when nvme0n1 was targeted!"
  exit 1
fi
echo "PASS: ocs-mdraid-stop preserved unrelated md0."

# 3b. ocs-mdraid-stop with member disk sdb -> SHOULD stop md0
"$REPO_DIR/sbin/ocs-mdraid-stop" sdb
if grep -q "MDADM: --stop /dev/md0" "$TMP_DIR/mdadm.log"; then
  echo "PASS: ocs-mdraid-stop correctly stopped md0 when sdb was targeted."
else
  echo "FAIL: ocs-mdraid-stop did not stop md0 when sdb was targeted!"
  exit 1
fi

echo "=== TEST 4: ocs-restore-mdraid-layout target protection ==="
# Prepare image directory with md0-config.env pointing to sdb1..sdg1
IMG_RESTORE="$TMP_DIR/img-restore"
mkdir -p "$IMG_RESTORE"
cp "$IMG_SDB/md0-config.env" "$IMG_RESTORE/"

# 4a. Restore targeting nvme0n1 -> must NOT wipe sdb1..sdg1 or recreate md0
rm -f "$TMP_DIR/wiped.log"
"$REPO_DIR/sbin/ocs-restore-mdraid-layout" -b "$IMG_RESTORE" nvme0n1
if [ -f "$TMP_DIR/wiped.log" ] && grep -qE "(sdb|sdc|sdd|sde|sdf|sdg)" "$TMP_DIR/wiped.log"; then
  echo "FAIL: Member disks were wiped during restore to nvme0n1!"
  cat "$TMP_DIR/wiped.log"
  exit 1
fi
echo "PASS: ocs-restore-mdraid-layout skipped md0 and did not touch sdb..sdg when restoring to nvme0n1."

echo "=== TEST 5: task_restoredisk auto-append protection ==="
(
  export ocsroot="$TMP_DIR"
  export target_dir="img-restore"
  export OCS_LOGFILE="$TMP_DIR/ocs.log"
  export target_hd="nvme0n1"

  # Run auto-append logic
  if [ -n "$(ls "$ocsroot/$target_dir"/*-config.env 2>/dev/null)" ]; then
    for env_f in "$ocsroot/$target_dir"/*-config.env; do
      [ -e "$env_f" ] || continue
      md_dev="$(basename "$env_f" -config.env)"
      md_members="$(awk -F= '/^MD_MEMBERS_ORDERED=/ {gsub(/"/, "", $2); print $2}' "$env_f" 2>/dev/null)"
      md_belongs_to_target="no"
      if [ -z "$md_members" ]; then
        [ -n "$(echo "$target_hd" | grep -Ew "$md_dev")" ] && md_belongs_to_target="yes"
      else
        for mm in $md_members; do
          [ "$mm" = "missing" ] && continue
          mm_kname="$(basename "$mm")"
          mm_disk="$(echo "$mm_kname" | sed -r -e 's/p?[0-9]+$//')"
          for thd in $target_hd; do
            thd="${thd#/dev/}"
            if [ "$mm_disk" = "$thd" ] || [ "$mm_kname" = "$thd" ] || [ "$md_dev" = "$thd" ]; then
              md_belongs_to_target="yes"
              break 2
            fi
          done
        done
      fi
      if [ "$md_belongs_to_target" = "yes" ]; then
        if [ -z "$(echo $target_hd | grep -Ew "$md_dev")" ]; then
          target_hd="$target_hd $md_dev"
        fi
      fi
    done
  fi

  if echo "$target_hd" | grep -q "md0"; then
    echo "FAIL: md0 was unexpectedly appended to target_hd: $target_hd"
    exit 1
  fi
  echo "PASS: task_restoredisk did not append md0 to target_hd (target_hd is '$target_hd')."
)

echo "=== TEST 6: MD disk to MD disk cloning ==="
# In MD-to-MD cloning:
# Source array md0 is cloned to existing active target array md1
# Add md1 to mock /proc/mdstat
cat <<'EOF' > "$MOCK_PROC/mdstat"
Personalities : [raid1] [raid5]
md0 : active raid5 sdb1[0] sdc1[1] sdd1[2] sde1[3] sdf1[4] sdg1[5]
      5000000 blocks super 1.0 level 5, 512k chunk, algorithm 2 [6/6] [UUUUUU]
md1 : active raid1 sdh1[0] sdi1[1]
      2000000 blocks super 1.2 [2/2] [UU]
EOF

# Setup image directory with converted md1-config.env and md1-pt.sf
IMG_MD1="$TMP_DIR/img-md1"
mkdir -p "$IMG_MD1"
cat <<'EOF' > "$IMG_MD1/md1-config.env"
MD_UUID=11111111:22222222:33333333:44444444
MD_NAME=rescue:1
MD_META=1.0
MD_LEVEL=raid5
MD_DEVICES_COUNT=6
MD_CHUNK=512
MD_LAYOUT=left-symmetric
MD_DATA_OFFSET=
MD_MEMBERS_ORDERED="/dev/sdb1 /dev/sdc1 /dev/sdd1 /dev/sde1 /dev/sdf1 /dev/sdg1"
EOF
echo "# partition table of md1" > "$IMG_MD1/md1-pt.sf"

# Track sfdisk calls
cat <<EOF > "$MOCK_BIN/sfdisk"
#!/bin/bash
echo "SFDISK: \$*" >> "$TMP_DIR/sfdisk.log"
exit 0
EOF
chmod +x "$MOCK_BIN/sfdisk"

# 6a. ocs-mdraid-stop md1 should NOT stop active target md1
rm -f "$TMP_DIR/mdadm.log"
"$REPO_DIR/sbin/ocs-mdraid-stop" md1
if grep -q "MDADM: --stop /dev/md1" "$TMP_DIR/mdadm.log" 2>/dev/null; then
  echo "FAIL: ocs-mdraid-stop stopped active target array md1!"
  exit 1
fi
echo "PASS: ocs-mdraid-stop did not stop active target array md1."

# 6b. ocs-restore-mdraid-layout -b "$IMG_MD1" md1 should restore internal partitions without wiping members or running mdadm --create
rm -f "$TMP_DIR/wiped.log" "$TMP_DIR/sfdisk.log"
"$REPO_DIR/sbin/ocs-restore-mdraid-layout" -b "$IMG_MD1" md1
if [ -f "$TMP_DIR/wiped.log" ]; then
  echo "FAIL: Wiped devices during MD-to-MD restore!"
  cat "$TMP_DIR/wiped.log"
  exit 1
fi
if grep -q "MDADM: --create /dev/md1" "$TMP_DIR/mdadm.log" 2>/dev/null; then
  echo "FAIL: Attempted mdadm --create on already active md1!"
  exit 1
fi
if grep -q "SFDISK: --force /dev/md1" "$TMP_DIR/sfdisk.log" 2>/dev/null; then
  echo "PASS: ocs-restore-mdraid-layout correctly applied internal partition table to active md1 without recreating array."
else
  echo "FAIL: Internal partition table was not applied to /dev/md1!"
  exit 1
fi

echo "=== TEST 7: MD v1.x superblock padding sanitization (Issue with Rocky Linux / older kernels) ==="
MEMBER_IMG="$TMP_DIR/test_member_pad.img"
# Create 16K image file
perl -e '
  my $f = $ARGV[0];
  open my $fh, ">", $f or die $!;
  print $fh ("\x00" x 16384);
  seek($fh, 4096, 0);

  # Superblock at offset 4096
  my $sb = "\x00" x 260;
  substr($sb, 0, 4, pack("V", 0xa92b4efc)); # magic
  substr($sb, 4, 4, pack("V", 1));          # major_version
  substr($sb, 220, 4, pack("V", 2));        # max_dev = 2
  substr($sb, 224, 4, pack("V", 512));      # logical_block_size = 512 (non-zero padding)

  sub calc_csum {
    my ($data) = @_;
    my ($max_dev) = unpack("x220 V", $data);
    my $size = 256 + $max_dev * 2;
    substr($data, 216, 4, "\x00\x00\x00\x00");
    my $newcsum = 0;
    my $off = 0;
    while ($off + 4 <= $size) {
      $newcsum += unpack("V", substr($data, $off, 4));
      $off += 4;
    }
    if ($off + 2 <= $size) {
      $newcsum += unpack("v", substr($data, $off, 2));
    }
    my $csum = ($newcsum & 0xffffffff) + ($newcsum >> 32);
    $csum = ($csum & 0xffffffff) + ($csum >> 32);
    return $csum;
  }

  my $csum = calc_csum($sb);
  substr($sb, 216, 4, pack("V", $csum));
  print $fh $sb;
  close $fh;
' "$MEMBER_IMG"

# Source ocs-restore-mdraid-layout's sanitize_md_superblock logic or run directly
perl -e '
  my ($dev_path) = @ARGV;
  open my $dev, "+<", $dev_path or exit 1;

  sub calc_csum {
    my ($data) = @_;
    my ($max_dev) = unpack("x220 V", $data);
    my $size = 256 + $max_dev * 2;
    substr($data, 216, 4, "\x00\x00\x00\x00");
    my $newcsum = 0;
    my $off = 0;
    while ($off + 4 <= $size) {
      $newcsum += unpack("V", substr($data, $off, 4));
      $off += 4;
    }
    if ($off + 2 <= $size) {
      $newcsum += unpack("v", substr($data, $off, 2));
    }
    my $csum = ($newcsum & 0xffffffff) + ($newcsum >> 32);
    $csum = ($csum & 0xffffffff) + ($csum >> 32);
    return $csum;
  }

  my @offsets = (4096, 0);
  seek($dev, 0, 2);
  my $dev_size = tell($dev);
  if ($dev_size && $dev_size >= 16384) {
    my $v10_offset = ($dev_size & ~4095) - 8192;
    push @offsets, $v10_offset if $v10_offset > 0;
  }

  my $sanitized = 0;
  for my $sb_offset (@offsets) {
    seek($dev, $sb_offset, 0) or next;
    my $buf;
    my $n = read($dev, $buf, 4096);
    next unless defined($n) && $n >= 256;

    my $magic = unpack("V", substr($buf, 0, 4));
    next unless $magic == 0xa92b4efc;

    my $major = unpack("V", substr($buf, 4, 4));
    next unless $major == 1;

    my ($max_dev) = unpack("x220 V", $buf);
    my $sb_size = 256 + $max_dev * 2;
    next if $n < $sb_size;

    my $pad3 = substr($buf, 224, 32);
    if ($pad3 ne ("\x00" x 32)) {
      substr($buf, 224, 32, "\x00" x 32);
      my $new_csum = calc_csum($buf);
      substr($buf, 216, 4, pack("V", $new_csum));
      seek($dev, $sb_offset, 0);
      print $dev substr($buf, 0, $sb_size);
      $sanitized = 1;
    }
  }
  close $dev;
  exit($sanitized ? 0 : 1);
' "$MEMBER_IMG"

# Verify pad3 is now all zeros and checksum is valid
perl -e '
  my ($dev_path) = @ARGV;
  open my $dev, "<", $dev_path or die $!;
  seek($dev, 4096, 0);
  my $buf;
  read($dev, $buf, 260) == 260 or die $!;
  close $dev;

  sub calc_csum {
    my ($data) = @_;
    my ($max_dev) = unpack("x220 V", $data);
    my $size = 256 + $max_dev * 2;
    substr($data, 216, 4, "\x00\x00\x00\x00");
    my $newcsum = 0;
    my $off = 0;
    while ($off + 4 <= $size) {
      $newcsum += unpack("V", substr($data, $off, 4));
      $off += 4;
    }
    if ($off + 2 <= $size) {
      $newcsum += unpack("v", substr($data, $off, 2));
    }
    my $csum = ($newcsum & 0xffffffff) + ($newcsum >> 32);
    $csum = ($csum & 0xffffffff) + ($csum >> 32);
    return $csum;
  }

  my $pad3 = substr($buf, 224, 32);
  die "pad3 is not zeroed" unless $pad3 eq ("\x00" x 32);
  my $stored_csum = unpack("V", substr($buf, 216, 4));
  my $expected_csum = calc_csum($buf);
  die "Checksum mismatch" unless $stored_csum == $expected_csum;
  print "PASS: Superblock pad3 successfully zeroed and checksum matches for older kernel compatibility.\n";
' "$MEMBER_IMG"

echo "=== All MDRAID Device Selection and Filtering Tests Passed Successfully! ==="
exit 0
