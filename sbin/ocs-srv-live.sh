#!/bin/bash
# Author: Steven Shiau <steven _at_ nchc org tw>
# License: GPL
# Description: Program to start Clonezilla SE on DRBL live.

DRBL_SCRIPT_PATH="${DRBL_SCRIPT_PATH:-/opt/drbl/}"

. $DRBL_SCRIPT_PATH/sbin/drbl-conf-functions

# Load the config in ocs-live.conf. This is specially for DRBL/Clonezilla live. It will overwrite some settings of /opt/drbl/conf/drbl-ocs.conf, such as $DIA...
[ -e "/etc/ocs/ocs-live.conf" ] && . /etc/ocs/ocs-live.conf

# Settings
# try IP from 192.168."100".254
private_IP_alias_eth_def="100"

# functions
USAGE() {
    echo "To start, restart or stop Clonezilla server edition service in DRBL Live environment."
    echo "Usage:"
    echo "$0 {start|stop|restart}"
    echo "start   Start Clonezilla server edition service now"
    echo "stop    Stop Clonezilla server edition service service now"
    echo "restart Restart Clonezilla server edition service service now"
    echo "Example: To start Clonezilla server edition service service in this DRBL Live server"
    echo "$0 start"
}

#################
##### MAIN ######
#################
check_if_root

#
ask_and_load_lang_set
#
if [ $# -ne 1 ]; then
  USAGE
  exit 1
fi

switch=$1

#
if ! is_boot_from_live; then
  [ "$BOOTUP" = "color" ] && $SETCOLOR_FAILURE
  echo "This command $0 is used in DRBL Live environment only!"
  [ "$BOOTUP" = "color" ] && $SETCOLOR_NORMAL
  echo "$msg_program_stop"
  exit 1
fi

case "$switch" in
   "start"|"restart")
     # start drbl live first, which will setup drbl environment
     echo "Checking if DRBL related sevices are started or not..."
     # dhcpd is for isc-dhcp-server (from Squeeze), dhcpd3 is for dhcp3-server (< squeeze).
     dhcpd_pid="$(LC_ALL=C pidof dhcpd || LC_ALL=C pidof dhcpd3)"
     tftpd_pid="$(LC_ALL=C pidof in.tftpd)"
     unfsd_pid="$(LC_ALL=C pidof unfsd)"
     nfsd_pid="$(LC_ALL=C pidof nfsd)"
     if [ -z "$dhcpd_pid" -o -z "$tftpd_pid" ] || [ -z "$unfsd_pid" -a -z "$nfsd_pid" ]; then
       if [ "$ocs_batch_mode" = "on" ]; then
         echo "$msg_delimiter_star_line"
         echo "$msg_drbl_env_is_not_ready_now_config"
         echo $msg_this_might_take_several_minutes
         echo -n $msg_press_enter_to_continue
         read
         echo "$msg_delimiter_star_line"
       fi
       # Check if $ocsroot is a mountpoint or not, if not, we have to mount it.
       prepare_ocsroot_opt=""
       if ! mountpoint $ocsroot &>/dev/null; then
         echo "Directory $ocsroot is not a mount point. Will try to mount $ocsroot..."
         prepare_ocsroot_opt="--prepare-ocsroot"
       fi	        
       drbl-live.sh $prepare_ocsroot_opt --skip-pause-in-the-end --no-prompt-drbl-live start
     fi

     echo "$msg_delimiter_star_line"
     echo "$msg_drbl_env_is_ready"
     echo "$msg_delimiter_star_line"
     sleep 1
     dcs clonezilla-start

     echo "$msg_delimiter_star_line"
     [ "$BOOTUP" = "color" ] && $SETCOLOR_WARNING
     echo "$msg_do_not_close_window_until_clone_finish"
     [ "$BOOTUP" = "color" ] && $SETCOLOR_NORMAL
     /bin/bash
     ;;
   "stop")
     drbl-ocs stop
     echo "$msg_delimiter_star_line"
     echo -n $msg_press_enter_to_continue
     read < /dev/stdin
     ;;
esac
