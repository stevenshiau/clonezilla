#!/bin/bash
# Standalone unit test for disable_stdin_non_blocking_mode and interactive scripts.

set -e

echo "=== Running disable_stdin_non_blocking_mode Tests ==="

DRBL_SCRIPT_PATH="${DRBL_SCRIPT_PATH:-/usr/share/drbl}"
. /root/clonezilla/scripts/sbin/ocs-functions

# Test 1: Verify disable_stdin_non_blocking_mode clears O_NONBLOCK flag on stdin
echo "Testing disable_stdin_non_blocking_mode flag clearing..."
python3 -c "
import os, fcntl, subprocess

test_script = '''
DRBL_SCRIPT_PATH=\"/usr/share/drbl\"
. /root/clonezilla/scripts/sbin/ocs-functions

# Check that STDIN is currently non-blocking
perl -e 'use POSIX qw(fcntl_h); exit((fcntl(STDIN, F_GETFL, 0) & O_NONBLOCK) ? 0 : 1)'
if [ \$? -ne 0 ]; then
    echo \"FAIL: STDIN was expected to have O_NONBLOCK set\"
    exit 1
fi

# Call disable_stdin_non_blocking_mode
disable_stdin_non_blocking_mode

# Verify that O_NONBLOCK is now cleared
perl -e 'use POSIX qw(fcntl_h); exit((fcntl(STDIN, F_GETFL, 0) & O_NONBLOCK) ? 1 : 0)'
if [ \$? -ne 0 ]; then
    echo \"FAIL: disable_stdin_non_blocking_mode failed to clear O_NONBLOCK\"
    exit 1
fi
'''

r, w = os.pipe()
flags = fcntl.fcntl(r, fcntl.F_GETFL)
fcntl.fcntl(r, fcntl.F_SETFL, flags | os.O_NONBLOCK)

proc = subprocess.Popen(['bash', '-c', test_script], stdin=r, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
stdout, stderr = proc.communicate()
if proc.returncode != 0:
    print('STDOUT:', stdout.decode())
    print('STDERR:', stderr.decode())
    exit(1)
"
echo "PASS: disable_stdin_non_blocking_mode cleared O_NONBLOCK on stdin as expected."

# Test 2: Verify run_ocs_sr_again_prompt executes read cleanly without EAGAIN
echo "Testing run_ocs_sr_again_prompt with non-blocking stdin..."
python3 -c "
import os, fcntl, subprocess

test_script = '''
DRBL_SCRIPT_PATH=\"/usr/share/drbl\"
. /root/clonezilla/scripts/sbin/ocs-functions

ocs_sr_mode=\"interactive\"
ocs_batch_mode=\"off\"
OCS_OPTS=\"-g auto\"
ocs_sr_type=\"restoredisk\"
BOOTUP=\"\"
OCS_LOGFILE=\"/dev/null\"
msg_run_drbl_ocs_again_cmd=\"run again\"
msg_ocs_sr_again_command_saved_filename=\"saved filename\"
msg_delimiter_star_line=\"*\"
msg_press_enter_to_continue=\"Press Enter to continue...\"

# Source the function definition from sbin/ocs-sr
FUNC_CODE=\$(sed -n '/^run_ocs_sr_again_prompt() {/,/^} # end of run_ocs_sr_again_prompt/p' /root/clonezilla/sbin/ocs-sr)
eval \"\$FUNC_CODE\"

# Call run_ocs_sr_again_prompt with simulated Enter keypress
run_ocs_sr_again_prompt \"test-img\" \"sda\"
'''

r, w = os.pipe()
flags = fcntl.fcntl(r, fcntl.F_GETFL)
fcntl.fcntl(r, fcntl.F_SETFL, flags | os.O_NONBLOCK)
# Send newline so read can consume it once blocking mode is restored
os.write(w, b'\n')

proc = subprocess.Popen(['bash', '-c', test_script], stdin=r, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
stdout, stderr = proc.communicate()
if proc.returncode != 0 or b'read error' in stderr:
    print('STDOUT:', stdout.decode())
    print('STDERR:', stderr.decode())
    exit(1)
"
echo "PASS: run_ocs_sr_again_prompt executed without read errors."

# Test 3: Verify all modified sbin scripts contain disable_stdin_non_blocking_mode
echo "Testing presence of disable_stdin_non_blocking_mode in all targeted scripts..."
TARGET_SCRIPTS=(
  /root/clonezilla/sbin/clonezilla
  /root/clonezilla/sbin/ocs-sr
  /root/clonezilla/sbin/ocs-onthefly
  /root/clonezilla/sbin/ocs-live
  /root/clonezilla/sbin/ocs-prep-repo
  /root/clonezilla/sbin/drbl-ocs
  /root/clonezilla/sbin/ocs-live-feed-img
  /root/clonezilla/sbin/ocs-live-get-img
  /root/clonezilla/sbin/ocs-srv-live
  /root/clonezilla/sbin/ocs-live-restore
  /root/clonezilla/sbin/ocs-live-save
  /root/clonezilla/sbin/ocs-live-general
  /root/clonezilla/sbin/ocs-live-repository
  /root/clonezilla/sbin/ocs-live-netcfg
  /root/clonezilla/sbin/ocs-chkimg
  /root/clonezilla/sbin/ocs-restore-mdisks
  /root/clonezilla/sbin/ocs-cvtimg-comp
  /root/clonezilla/sbin/ocs-cvtimg-enc
  /root/clonezilla/sbin/ocs-clean-disk-part-fs
  /root/clonezilla/sbin/ocs-purge-mdraid-layout
)

for script in "${TARGET_SCRIPTS[@]}"; do
  if ! grep -q "disable_stdin_non_blocking_mode" "$script"; then
    echo "FAIL: $script does not contain disable_stdin_non_blocking_mode"
    exit 1
  fi
done
echo "PASS: All targeted scripts contain disable_stdin_non_blocking_mode."

echo "=== All disable_stdin_non_blocking_mode Tests Passed Successfully! ==="
