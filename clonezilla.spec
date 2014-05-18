Summary:	Opensource Clone System (ocs), clonezilla
Name:		clonezilla
Version:	3.10.11
Release:	drbl1
License:	GPL
Group:		Development/Clonezilla
Source0:	%{name}-%{version}.tar.bz2
URL:		http://clonezilla.org
BuildArch:	noarch
BuildRoot:	%{_tmppath}/%{name}-%{version}-root
Requires:	bash, perl, drbl >= 2.8.25, partimage >= 0.6.7, psmisc, udpcast, partclone >= 0.2.70, ntfsprogs >= 1.13.1

%description
Clonezilla, based on DRBL, partclone, and udpcast, allows you to do bare metal backup and recovery. Two types of Clonezilla are available, Clonezilla live and Clonezilla SE (Server Edition). Clonezilla live is suitable for single machine backup and restore. While Clonezilla SE is for massive deployment, it can clone many (40 plus!) computers simultaneously.
For more info, check http://clonezilla.org, http://clonezilla.nchc.org.tw.

%prep
%setup -q -n clonezilla-%{version}

%build
make all

%install
make install DESTDIR=$RPM_BUILD_ROOT/

%clean
[ -d "$RPM_BUILD_ROOT" ] && rm -rf $RPM_BUILD_ROOT

%post

%files
%defattr(-,root,root)
/usr/sbin/*
/usr/bin/*
/usr/share/drbl/*
/usr/share/clonezilla/*
/etc/drbl/*

%changelog
* Sun May 18 2014 Steven Shiau <steven _at_ nchc org tw> 3.10.11-drbl1
- Bug fixed: The boot media should not be mounted again as read-write mode in ocs-live-save. Otherwise when rebooting, due to the squashfsfs are mounted, it can not be unmounted.

* Sat May 17 2014 Steven Shiau <steven _at_ nchc org tw> 3.10.10-drbl1
- Accepting -b|-batch|--batch options for ocs-restore-mdisks. A typo in the USAGE message was fixed.

* Thu May 15 2014 Steven Shiau <steven _at_ nchc org tw> 3.10.9-drbl1
- Packages, lsof, psmisc, dnsutils, wget, ftp, bzip2, zip, unzip, w3m and gsmartcontrol were added in GParted live.
- Startup page of netsurf was assigned to GParted live manual.

* Fri May 02 2014 Steven Shiau <steven _at_ nchc org tw> 3.10.8-drbl1
- Adding support for utopic in create-ubuntu-live, and dropping the support for lucid and quantal.

* Fri May 02 2014 Steven Shiau <steven _at_ nchc org tw> 3.10.7-drbl1
- Bug fixed: 1-2-mdisks failed to reinstall grub due to ocs-restore-mbr does not honor the temp $ocsroot variable.

* Thu May 01 2014 Steven Shiau <steven _at_ nchc org tw> 3.10.6-drbl1
- Bug fixed: Restoring an LVM partition prevents any following non-LVM partitions from being restored. Thanks to Ian Horton for the patch.

* Sat Apr 26 2014 Steven Shiau <steven _at_ nchc org tw> 3.10.5-drbl1
- Bug fixed: two extra grub 2.02 modules gfxterm_background and gfxterm_menu are added now when creating bootx64.efi and bootxia32.efi by gl-gen-grub2-efi-bldr. Otherwise the backgroud won't be shown. Thanks to Ady (ady-sf _at_ hotmail com) for reporting this issue.

* Fri Apr 25 2014 Steven Shiau <steven _at_ nchc org tw> 3.10.4-drbl1
- Bug fixed: live-boot was upgraded to 4.x. Setting "--cache-indices" of live-config as true so that live-boot won't be upgraded after filesystem.squashfs is created.

* Wed Apr 23 2014 Steven Shiau <steven _at_ nchc org tw> 3.10.3-drbl1
- Adding program set-netboot-1st-efi-nvram.
- Applying set-netboot-1st-efi-nvram after update-efi-nvram-boot-entry.

* Thu Apr 10 2014 Steven Shiau <steven _at_ nchc org tw> 3.10.2-drbl1
- Packages screen, rsync, iputils-ping, telnet, traceroute and bc were added in GParted live.

* Fri Apr 04 2014 Steven Shiau <steven _at_ nchc org tw> 3.10.1-drbl1
- The create-*-live files were broken due to the apt version 1.0 and live-boot/live-config 4.x alpha in the Sid repository. No more using aptitude for create-drbl-live. All of them are in apt now.

* Fri Mar 28 2014 Steven Shiau <steven _at_ nchc org tw> 3.9.49-drbl1
- Bug fixed: ssh service was not working in Saucy's clonezilla SE client mode.

* Sat Mar 22 2014 Steven Shiau <steven _at_ nchc org tw> 3.9.48-drbl1
- Bug fixed: autoproductname should filter the characters "()[]{}". Thanks to Coudy* for reporting this issue (https://sourceforge.net/p/clonezilla/bugs/193/).

* Wed Mar 19 2014 Steven Shiau <steven _at_ nchc org tw> 3.9.47-drbl1
- The paramger "ocs_prompt_mode" takes effect when saving an image.

* Tue Mar 18 2014 Steven Shiau <steven _at_ nchc org tw> 3.9.46-drbl1
- Suppress all the space of time got in get_img_create_time because it might be used in dialog prompt.
- Bug fixed: two extra grub 2.02 modules gfxterm_background and gfxterm_menu are added now when creating bootx64.efi and bootxia32.efi by ocs-gen-grub2-efi-bldr. Otherwise the backgroud won't be shown.

* Mon Mar 17 2014 Steven Shiau <steven _at_ nchc org tw> 3.9.45-drbl1
- A better way to get image created time was implemented.

* Mon Mar 17 2014 Steven Shiau <steven _at_ nchc org tw> 3.9.44-drbl1
- Bug fixed: in cmd mode, an extra line was added in the confirmation messages before restorinig an image.

* Mon Mar 17 2014 Steven Shiau <steven _at_ nchc org tw> 3.9.43-drbl1
- Image creating date will be shown in the prompt before restoring an image.

* Sun Mar 16 2014 Steven Shiau <steven _at_ nchc org tw> 3.9.42-drbl1
- Bug fixed: after drbl service has been started, if clonezilla SE is started, the image repository should be mounted in DRBL live.

* Sat Mar 15 2014 Steven Shiau <steven _at_ nchc org tw> 3.9.41-drbl1
- The content of "iso_sort.txt" should be a two-column list, separated by "TAB", not space, in the function gen_iso_sort_file of ocs-functions.

* Fri Mar 14 2014 Steven Shiau <steven _at_ nchc org tw> 3.9.40-drbl1
- Sync the parse_cmdline_option of gl-functions with drbl-functions.
- The ocs_prerun* and ocs_postrun* boot parameters are sorted with "-V", not "-n".

* Fri Mar 14 2014 Steven Shiau <steven _at_ nchc org tw> 3.9.39-drbl1
- The info to be shown in the TUI mod of countdown_or_confirm_before_restore was improved. More info will be shown.
- Variable "messages_shown_preference" in drbl.conf was moved to drbl-ocs.conf and renamed as "ocs_prompt_mode".
- A boot parameter "ocs_prompt_mode" was added so that it can be used to control the prompt mode (TUI or CMD).

* Wed Mar 12 2014 Steven Shiau <steven _at_ nchc org tw> 3.9.38-drbl1
- Menu of KMS mode for live system will always shown by ocs-live-boot-menu.

* Wed Mar 12 2014 Steven Shiau <steven _at_ nchc org tw> 3.9.37-drbl1
- Package xnetcardconfig was removed from create-drbl-live-by-pkg because it's no more in Debian repository and not used in DRBL live.

* Fri Mar 07 2014 Steven Shiau <steven _at_ nchc org tw> 3.9.36-drbl1
- Sorting the isolinux.bin and boot.cat when creating iso file by genisoimage. Thanks to Ady <ady-sf _at_ hotmail com> for this suggestion.

* Thu Mar 06 2014 Steven Shiau <steven _at_ nchc org tw> 3.9.35-drbl1
- Force to quit plymouthd when Clonezilla client is in select_in_client mode.

* Wed Mar 05 2014 Steven Shiau <steven _at_ nchc org tw> 3.9.34-drbl1
- An option "-s|--semi-batch" was added to the sample file gen-rec-usb. It can be used to confirm only once, not every major step. Thanks to ilovecats for this suggestion.

* Mon Feb 24 2014 Steven Shiau <steven _at_ nchc org tw> 3.9.33-drbl1
- Using -z1p instead of -z2p when saving image in the sample file gen-rec-usb.
- The way "scale=0" was not used in ocs-expand-mbr-pt. A better method is used.
- Bug fixed: toram menu for grub should use toram=filesystem.squashfs instead of toram so that it's consistent with that of syslinux.

* Fri Feb 21 2014 Steven Shiau <steven _at_ nchc org tw> 3.9.32-drbl1
- Sync the parse_cmdline_option of gl-functions with drbl-functions.
- Bug fixed: the linking part in function ocs-live-env-prepare of ocs-functions should be kept. We should just remove the remount,rw part. Besides, the checking mechanism for linking or not has been changed to find the image. Thanks to ilovecats for reporting this issue.

* Fri Feb 21 2014 Steven Shiau <steven _at_ nchc org tw> 3.9.31-drbl1
- The boot media should not be mounted again as read-write mode in function ocs-live-env-prepare of ocs-functions. Otherwise when rebooting, due to the squashfsfs are mounted, it can not be unmounted. Thanks to ilovecats for reporting this.
- The example "clone-multiple-usb-example.sh" was removed. Because it's in the main menu already. 
- An example gen-rec-usb was added. It could be used to create a recovery USB flash drive directly from the machine.

* Thu Feb 20 2014 Steven Shiau <steven _at_ nchc org tw> 3.9.30-drbl1
- An option -q was added to ocs-live-dev so that it can be used to use the existing image on the recovery device.

* Tue Feb 18 2014 Steven Shiau <steven _at_ nchc org tw> 3.9.29-drbl1
- The mechanism to run scripts S[0-9][0-9]* and K[0-9][0-9]* in a directory has been improved. "$script" instead of ". $script" should be used otherwise in some cases the rest of scripts won't be run.

* Mon Feb 17 2014 Steven Shiau <steven _at_ nchc org tw> 3.9.28-drbl1
- Bug fixed: Packages.bz2 on Debian repository is no more. Use Packages.gz in ocs-live-hook-functions.
- Disable remove_grpck_opt_p in ocs-live-hook because the issue was fixed in passwd 1:4.1.5.1-1.
- Package libc6-i386 should be excluded when running "deborphan -n" in ocs-live-hook-functions.

* Mon Feb 17 2014 Steven Shiau <steven _at_ nchc org tw> 3.9.27-drbl1
- Package libc6-i386 was added in all AMD64 version of live system.

* Mon Feb 17 2014 Steven Shiau <steven _at_ nchc org tw> 3.9.26-drbl1
- The /lib32 dir will be kept in the amd32 version of live system.

* Mon Feb 17 2014 Steven Shiau <steven _at_ nchc org tw> 3.9.25-drbl1
- Function get_live_boot_param of ocs-functions will give the result "quiet_opt".
- Program ocs-live-dev and ocs-iso should also honor the boot parameter "quiet" when creating a recovery iso/zip.

* Sun Feb 16 2014 Steven Shiau <steven _at_ nchc org tw> 3.9.24-drbl1
- Bug fixed: Batch mode option passed to makeboot.sh in ocs-live-dev was wrong.

* Sun Feb 16 2014 Steven Shiau <steven _at_ nchc org tw> 3.9.23-drbl1
- Program ocs-live-dev was improved to directly put image and unattended mode of boot parameters to a USB device. Thanks to ilovecats for this idea.

- An option "-b" was added so that ocs-live-dev can be run in batch mode.

* Sun Feb 09 2014 Steven Shiau <steven _at_ nchc org tw> 3.9.22-drbl1
- Function parse_cmdline_option of gl-functions was updated to accept more characters, including "[", "]", and ";".
- The correspoing files which using parse_cmdline_option were updated, too.

* Thu Feb 06 2014 Steven Shiau <steven _at_ nchc org tw> 3.9.21-drbl1
- Function parse_cmdline_option of gl-functions was updated to accept pipe sign (|). Thanks to Fuchs (fusi1939 _at_ users sf net) for this suggestion.

* Tue Feb 04 2014 Steven Shiau <steven _at_ nchc org tw> 3.9.20-drbl1
- Function get_latest_kernel_ver_in_repository was updated so that correct linux kernel version for Ubuntu trusty could be got due to new kernel package linux-image-3.13.0-6-lowlatency is shown.

* Mon Feb 03 2014 Steven Shiau <steven _at_ nchc org tw> 3.9.19-drbl1
- Bug fixed: xz format for old image format (e.g. sda1.aa) was not detected (https://sourceforge.net/p/clonezilla/bugs/191/). Thanks to peter green for reporting this issue.
- Bug fixed: There is a typo for the destination partition for 2nd confirmation for local partition to local partition (https://sourceforge.net/p/clonezilla/discussion/Open_discussion/thread/b99ab9e6/). Thanks to Tweed for reporting this bug.

* Tue Jan 21 2014 Steven Shiau <steven _at_ nchc org tw> 3.9.18-drbl1
- Boot parameter "noeject" should be added for those USB stick booting config in create-drbl-live.

* Mon Jan 20 2014 Steven Shiau <steven _at_ nchc org tw> 3.9.17-drbl1
- The "syslinux" and "isolinux" dirs of Clonezilla/DRBL/GParted live have been unified as one dir "syslinux". Thanks to Ady (ady-sf _at_ hotmail com) for this suggestion.

* Sun Jan 19 2014 Steven Shiau <steven _at_ nchc org tw> 3.9.16-drbl1
- When "-p choose" of ocs-sr or ocs-onthefly is used, the default item of dialog menu is entering command line prompt now.
- The option "--rsyncable" was added for gzip/pigz when saving an image (https://sourceforge.net/p/clonezilla/discussion/Open_discussion/thread/8d5f80a6). Thanks to lucatrv for providing this idea. 

* Sat Jan 18 2014 Steven Shiau <steven _at_ nchc org tw> 3.9.15-drbl1
- Parameter "ocs_postmode_prompt" instead of "messages_shown_preference" for the post action (reboot/poweroff/cmd/...) mode. If command line mode instead of TUI mode is desired, now we can use "ocs_postmode_prompt=cmd" in the boot parameters. This will work for both ocs-sr and ocs-onthefly.
- Deprecated function run_post_cmd_when_clonezilla_live_end of ocs-functions was removed.
- The output of command run_post_cmd_when_clone_end in ocs-onthefly is recoreded in log file, too.

* Fri Jan 17 2014 Steven Shiau <steven _at_ nchc org tw> 3.9.14-drbl1
- Program partclone.restore is replaced by partclone.$fs in ocs-onthefly because partclone.restore will be deprecated in the future.

* Thu Jan 16 2014 Steven Shiau <steven _at_ nchc org tw> 3.9.13-drbl1
- Packages.gz instead of Packages.bzip2 is used in get_latest_kernel_ver_in_repository since bzip2 one is changed to xz in Debian Sid, but Ubuntu still uses gzip and bzip2.

* Thu Jan 16 2014 Steven Shiau <steven _at_ nchc org tw> 3.9.12-drbl1
- Pixz is used in ocs-onthefly local to remote cloning. An option to use xz as filter program was added, too.

- Switch back to lbzip2 (http://sourceforge.net/p/clonezilla/discussion/Open_discussion/thread/141facdc/?limit=50#b0a0).

* Wed Jan 15 2014 Steven Shiau <steven _at_ nchc org tw> 3.9.11-drbl1
- Bug fixed: the grub dir name is called "grub2" for Fedora >=18, that causes check_grub_partition function failed to locate the grub partition.

* Mon Jan 13 2014 Steven Shiau <steven _at_ nchc org tw> 3.9.10-drbl1
- Bug fixed: boot parameters of toram was accidentally removed previously.

* Sat Jan 11 2014 Steven Shiau <steven _at_ nchc org tw> 3.9.9-drbl1
- Bug fixed: If drbl_mode is none, we should not make drbl as client's default boot menu when running "drbl-ocs stop".

* Fri Jan 10 2014 Steven Shiau <steven _at_ nchc org tw> 3.9.8-drbl1
- Bug fixed: "noeject" is not required in the TORAM part of isolinux.cfg and syslinux.cfg.  Thanks to Ady <ady-sf _at_ hotmail com> for this bug report.

* Thu Jan 09 2014 Steven Shiau <steven _at_ nchc org tw> 3.9.7-drbl1
- Boot parameters ocs_daemonon and ocs_daemonoff for Ubuntu-based Clonezilla live failed due to upstart is not compatable with sysvinit command like "/etc/init.d/$i start".

* Mon Jan 06 2014 Steven Shiau <steven _at_ nchc org tw> 3.9.6-drbl1
- The output of blkid will be saved in the image dir as blkid.list.

* Sun Dec 29 2013 Steven Shiau <steven _at_ nchc org tw> 3.9.5-drbl1
- An initial value for next_step in function get_live_boot_param in ocs-functions was added.

* Sat Dec 28 2013 Steven Shiau <steven _at_ nchc org tw> 3.9.4-drbl1
- Bug fixed: next_step should be local variable in function get_live_boot_param in ocs-functions.

* Thu Dec 26 2013 Steven Shiau <steven _at_ nchc org tw> 3.9.3-drbl1
- An option "-y|--syslinux-ver" was added to the create-*-live, ocs-iso and ocs-live-dev so that when live system is created syslinux version can be assigned.

* Tue Dec 24 2013 Steven Shiau <steven _at_ nchc org tw> 3.9.2-drbl1
- All the install_grub_hd in ocs-onthefly and ocs-makeboot was replaced by ocs-install-grub.

* Mon Dec 23 2013 Steven Shiau <steven _at_ nchc org tw> 3.9.1-drbl1
- Comments in ocs-cvtimg-comp were updated.
- The install_grub_hd function in ocs-functions was extracted as a program "ocs-install-grub" so that it's easier to be run separately.
- Program ocs-update-initrd was added so it's can be run separately for P2V for CentOS 5 (not finished yet).

* Wed Dec 18 2013 Steven Shiau <steven _at_ nchc org tw> 3.8.30-drbl1
- If parallel compression programs are not found, ocs-cvtimg-comp will find the normal compression programs to do that.

* Sun Dec 15 2013 Steven Shiau <steven _at_ nchc org tw> 3.8.29-drbl1
- Prompt in ocs-restore-mbr was updated.

* Sun Dec 15 2013 Steven Shiau <steven _at_ nchc org tw> 3.8.28-drbl1
- The codes about restoring MBR was extracted as another program ocs-restore-mbr so it's easier to be used separately.

* Thu Dec 12 2013 Steven Shiau <steven _at_ nchc org tw> 3.8.27-drbl1
- Adding option "-nogui" for ocs-cvtimg-comp.
- Adding exit code in ocs-chkimg.

* Wed Dec 11 2013 Steven Shiau <steven _at_ nchc org tw> 3.8.26-drbl1
- Make ocs-sr's dialog menu index text shorter (convert-img-compression -> cvt-img-compression)
- Bug fixed: partition itself containing LV does not have to be checked in ocs-chkimg.
- The incomplete converted image file created by ocs-cvtimg-comp should be removed.

* Wed Dec 11 2013 Steven Shiau <steven _at_ nchc org tw> 3.8.25-drbl1
- Part of codes in ocs-sr were moved as a function check_and_fix_vol_limit_if_required in ocs-functions.
- Bug fixed: ocs-cvtimg-comp failed to remove the linked split files.

* Tue Dec 10 2013 Steven Shiau <steven _at_ nchc org tw> 3.8.24-drbl1
- Function ocs-get-comp-suffix of ocs-functions was improved to covert more commands.
- Bug fixed: ocs-cvtimg-comp failed to run in command line mode with source and destination image names assigned.

* Tue Dec 10 2013 Steven Shiau <steven _at_ nchc org tw> 3.8.23-drbl1
- Program ocs-cvtimg-comp should check if the image format is for ntfsclone, partimage, and dd. For the first 2 format, exit, and for the last one, just copy files.

* Tue Dec 10 2013 Steven Shiau <steven _at_ nchc org tw> 3.8.22-drbl1
- A menu about image compression converting in ocs-sr was added.

* Tue Dec 10 2013 Steven Shiau <steven _at_ nchc org tw> 3.8.21-drbl1
- Adding ETA and percentage for ocs-chkimg.

* Mon Dec 09 2013 Steven Shiau <steven _at_ nchc org tw> 3.8.20-drbl1
- Functions and comments in ocs-cvtimg-comp were updated.

* Mon Dec 09 2013 Steven Shiau <steven _at_ nchc org tw> 3.8.19-drbl1
- Temp files split_error* should be removed when program is quit (ocs-functions).
- An option "-sc" was added to skip checking the converted image for ocs-cvtimg-comp.

* Mon Dec 09 2013 Steven Shiau <steven _at_ nchc org tw> 3.8.18-drbl1
- Bug fixed: program ocs-chkimg failed to check missing partition image file.
- An option -n|--no-cvt-dev (do not convert the device name) was added to create-ocs-tmp-img.
- Function get_target_dir_name_when_saving was updated with one more option, get_target_dir_name_when_converting_img was added, and get_image_cat_zip_cmd of ocs-functions will give gloable variable img_comp_format, too.
- A new program ocs-cvtimg-comp was added so that it can be used to convert the compression of an image.

* Sat Dec 07 2013 Steven Shiau <steven _at_ nchc org tw> 3.8.17-drbl1
- Switched to use pixz instead of pxz for -z5p.

* Wed Dec 05 2013 Steven Shiau <steven _at_ nchc org tw> 3.8.16-drbl1
- Bug fixed: the dir of EFI in live zip file should be mode 755, not read-only.

* Wed Nov 27 2013 Steven Shiau <steven _at_ nchc org tw> 3.8.15-drbl1
- Somehow the boot parameter "ip=frommedia" made Ubuntu-based Clonezilla live's vmlinuz boot slowly. Because "ip=" is accepted by live-boot with same function and it's shorter, use it.
- When creating recovery zip file, if image is included, use "-0", i.e., not to compress it.
- When a recovery iso/zip file is created, Clonezilla should honor the original splash mechanism.

* Mon Nov 25 2013 Steven Shiau <steven _at_ nchc org tw> 3.8.14-drbl1
- Comments in program ocs-lang-kbd-conf were updated.
- Bug fixed: Ubuntu-based Clonezilla live failed to make preset keyboard-layout work. Thanks to m-tm (m-tm _at_ gmx de) for this bug report, and Michael Vinzenz for tests.

* Mon Nov 25 2013 Steven Shiau <steven _at_ nchc org tw> 3.8.13-drbl1
- Bug fixed: boot parameter "noprompt" was replaced by "noeject" in live-boot version 3. We should use that in Clonezilla.

* Tue Nov 19 2013 Steven Shiau <steven _at_ nchc org tw> 3.8.12-drbl1
- Some output messages of ocs-run were suppressed for DRBL client.

* Mon Nov 18 2013 Steven Shiau <steven _at_ nchc org tw> 3.8.11-drbl1
- Bug fixed: the method to detect if signed-shim exists or not in efi-binary-hook was wrong.

* Mon Nov 18 2013 Steven Shiau <steven _at_ nchc org tw> 3.8.10-drbl1
- Bug fixed: the option "--extra-boot-param" of create-drbl-live-by-pkg failed to accept multiple boot parameters.

* Sun Nov 17 2013 Steven Shiau <steven _at_ nchc org tw> 3.8.9-drbl1
- Unused codes in function decide_live_kernel_related_pkgs_from_debian of ocs-functions was updated.

* Mon Nov 11 2013 Steven Shiau <steven _at_ nchc org tw> 3.8.8-drbl1
- Bug fixed: ocs-iso and ocs-live-dev failed to parse multiple options for "-n".

* Sun Nov 10 2013 Steven Shiau <steven _at_ nchc org tw> 3.8.7-drbl1
- A better way to disable auto start service of upstart is used now in Clonezilla live.

* Fri Nov 08 2013 Steven Shiau <steven _at_ nchc org tw> 3.8.6-drbl1
- Making Ubuntu-based Clonezilla live use "splash" in the boot parameters.

* Fri Nov 08 2013 Steven Shiau <steven _at_ nchc org tw> 3.8.5-drbl1
- Adding a language and keyboard configuration mechamism to work with plymouth.

* Tue Nov 05 2013 Steven Shiau <steven _at_ nchc org tw> 3.8.4-drbl1
- Bug fixed: wrong path for new location of mbr.bin.

* Wed Oct 30 2013 Steven Shiau <steven _at_ nchc org tw> 3.8.3-drbl1
- Variable lh_ver_required in drbl-ocs.conf is set as 3.0.5-1.
- Bug fixed: i386 arch of Ubuntu-based Clonezilla did not support uEFI boot (non-secure).

* Mon Oct 28 2013 Steven Shiau <steven _at_ nchc org tw> 3.8.2-drbl1
- Bug fixed: ldlinux.c32, libcom32.c32, libutil.c32 were not put in /isolinux/.

* Sun Oct 27 2013 Steven Shiau <steven _at_ nchc org tw> 3.8.1-drbl1
- Supporting syslinux/isolinux 6.

* Tue Oct 22 2013 Steven Shiau <steven _at_ nchc org tw> 3.7.16-drbl1
- The boot parameter "vmwgfx.blacklist=yes" was updated with  vmwgfx.enable_fbdev=no.

* Mon Oct 14 2013 Steven Shiau <steven _at_ nchc org tw> 3.7.15-drbl1
- Removing packages sysklogd, ttf-arphic-newsung, and x-ttcidfont-conf from the packages list of create-drbl-live-by-pkg. Force to add zenity, switch to lightdm instead of gdm3 which is too heavy when version 3.8 was included in Debian Sid.

* Mon Oct 14 2013 Steven Shiau <steven _at_ nchc org tw> 3.7.14-drbl1
- Removing codes about /etc/environment because it's not used in Wheezy+ anymore.

* Sun Oct 13 2013 Steven Shiau <steven _at_ nchc org tw> 3.7.13-drbl1
- Improvement: adding slash in the sshfs command to avoid a remote issue. Thanks to Baird Ramsey and Richard Freeman (https://sourceforge.net/p/clonezilla/bugs/171/).
- Bug fixed: some service, e.g. ssh, is not disabled successfully when live system was created.

* Fri Oct 11 2013 Steven Shiau <steven _at_ nchc org tw> 3.7.12-drbl1
- Service "ipmievd" should not be started automatically in DRBL live.

* Fri Oct 11 2013 Steven Shiau <steven _at_ nchc org tw> 3.7.11-drbl1
- Some codes were rewritten so "set -e" won't just exit in some cases.

* Fri Oct 11 2013 Steven Shiau <steven _at_ nchc org tw> 3.7.10-drbl1
- Bug fixed: create-gparted-live failed to include .disk file in the generated zip file.

* Thu Oct 10 2013 Steven Shiau <steven _at_ nchc org tw> 3.7.9-drbl1
- Bug fixed: $LIVE_MEDIA variable instead of /live/image should be used in ocs-live-bug-report.
- Variables lh_ver_required and debootstrap_ver_required in drbl-ocs.conf were updated.

* Thu Oct 10 2013 Steven Shiau <steven _at_ nchc org tw> 3.7.8-drbl1
- A language variable was added in the dialog prompt of ocs-onthefly so it's easier to customize.

* Thu Oct 10 2013 Steven Shiau <steven _at_ nchc org tw> 3.7.7-drbl1
- Prompts in create-ubuntu-live were updated.
- Bug fixed: create-drbl-live failed to include .disk file in the generated zip file.

* Tue Oct 08 2013 Steven Shiau <steven _at_ nchc org tw> 3.7.6-drbl1
- A language variable was added in the dialog prompt of ocs-sr so it's easier to customize.

* Sun Oct 06 2013 Steven Shiau <steven _at_ nchc org tw> 3.7.5-drbl1
- Removing the /etc/resolv.conf in efi-binary-hook. It's not required for live build version 3.

* Thu Oct 03 2013 Steven Shiau <steven _at_ nchc org tw> 3.7.4-drbl1
- Bug fixed: Czech locale name is cs_CZ, NOT cz_CZ (https://bugzilla.gnome.org/show_bug.cgi?id=708589).

* Wed Oct 02 2013 Steven Shiau <steven _at_ nchc org tw> 3.7.3-drbl1
- Bug fixed: In DRBL live, /tftpboot/node_root/bin/hostname was deconfigured by chroot_hostname. We have to move /tftpboot/node_root/bin/hostname.distrib as /tftpboot/node_root/bin/hostname. It was hostname.orig but now in live build 3 it has been changed as hostname.distrib.

* Tue Oct 01 2013 Steven Shiau <steven _at_ nchc org tw> 3.7.2-drbl1
- Bug fixed: some source files list of live system were not moved to source directory after create-*-live is run.

* Sun Sep 29 2013 Steven Shiau <steven _at_ nchc org tw> 3.7.1-drbl1
- Swithing to use Debian live packages (live-build, live-boot, live-config) version 3 for creating Clonezilla/DRBL/GParted live.

* Thu Sep 26 2013 Steven Shiau <steven _at_ nchc org tw> 3.6.20-drbl1
- Removing packages xorg-docs-core, xfonts-100dpi, xfonts-75dpi, and xfonts-scalable in gparted-live-hook.

* Thu Sep 26 2013 Steven Shiau <steven _at_ nchc org tw> 3.6.19-drbl1
- Only xorg instead of individual X packages is listed in create-gparted-live. Let the Debian dependence decide that.
- Updating some settings in create-drbl-live-*.

* Wed Sep 25 2013 Steven Shiau <steven _at_ nchc org tw> 3.6.18-drbl1
- Package localepurge has to be installed after debconf-set-selections preseeds the config in live hook.

* Wed Sep 25 2013 Steven Shiau <steven _at_ nchc org tw> 3.6.17-drbl1
- Option "-h" was added to ocs-put-signed-grub2-efi-bldr and ocs-gen-grub2-efi-bldr.
- Using debconf-set-selections instead of debconf-communicate in preseeding localepurge.

* Tue Sep 24 2013 Steven Shiau <steven _at_ nchc org tw> 3.6.16-drbl1
- "zh_TW" was removed in locale_to_keep_for_no_X of ocs-live-hook.conf since only zh_TW.UTF-8 is used.

* Tue Sep 24 2013 Steven Shiau <steven _at_ nchc org tw> 3.6.15-drbl1
- The function set_localepurge in ocs-live-hook-functions was updated to fit localepurge 0.7.3. It's because the new feature "localepurge/use-dpkg-feature" has to be configured otherwise localepurge won't run.

* Tue Sep 24 2013 Steven Shiau <steven _at_ nchc org tw> 3.6.14-drbl1
- Updating the grub.cfg created by ocs-live-boot-menu by setting gfxmode=auto, removing load_video and faekbios.

* Mon Sep 23 2013 Steven Shiau <steven _at_ nchc org tw> 3.6.13-drbl1
- Help message was added in get-latest-ocs-live-ver.
- The options of genisoimage in ocs-iso was rearranged.
- Rearranging the options for genisoimage in create-drbl-live and create-gparted-live so that isolinux 5.10 could boot on some real machine. Besides, not all included files are used with -graft-points. This is the key point for the workaround.

* Sun Sep 22 2013 Steven Shiau <steven _at_ nchc org tw> 3.6.12-drbl1
- Programs ocs-devsort and ocs-socket were added with help messages.

* Sat Sep 21 2013 Steven Shiau <steven _at_ nchc org tw> 3.6.11-drbl1
- Help messages were added in ocs-langkbdconf-bterm and ocsmgrd.

* Sat Sep 21 2013 Steven Shiau <steven _at_ nchc org tw> 3.6.10-drbl1
- Stale files ocs-help, ocs-live-help and ocs-create-gpt were removed.
- Help message was added in ocs-live-final-action.
- Usage prompt were added in ocs-live-general, ocs-live-save, and ocs-live-restore.

* Sat Sep 21 2013 Steven Shiau <steven _at_ nchc org tw> 3.6.9-drbl1
- More comments were added in the file /boot/grub/grub.cfg of live CD/USB files.

* Fri Sep 20 2013 Steven Shiau <steven _at_ nchc org tw> 3.6.8-drbl1
- Program ocs-put-signed-grub2-efi-bldr should also put grub efi modules.

* Fri Sep 20 2013 Steven Shiau <steven _at_ nchc org tw> 3.6.7-drbl1
- When /EFI/boot/bootx64.efi does not exist in the template iso, those EFI related files won't be included in the created live files.

* Thu Sep 19 2013 Steven Shiau <steven _at_ nchc org tw> 3.6.6-drbl1
- An extra dir /boot/grub/ was added so that the signed grubx64.efi from ubuntu could read the grub.cfg.

* Thu Sep 19 2013 Steven Shiau <steven _at_ nchc org tw> 3.6.5-drbl1
- Programs ocs-iso and ocs-live-dev should allow only one of bootx64.efi and bootx86.efi under /EFI/boot when checking if generating grub.cfg.

* Thu Sep 19 2013 Steven Shiau <steven _at_ nchc org tw> 3.6.4-drbl1
- Hook file efi-binary-hook failed to create files in correct path for Ubuntu-based Clonezilla live.

* Thu Sep 19 2013 Steven Shiau <steven _at_ nchc org tw> 3.6.3-drbl1
- Programs ocs-iso and ocs-live-dev should allow only one of bootx64.efi and bootx86.efi under /EFI/boot.

* Thu Sep 19 2013 Steven Shiau <steven _at_ nchc org tw> 3.6.2-drbl1
- Bug fixed: ocs-put-signed-grub2-efi-bldr run in efi-binary-hook should use chroot environment, not running OS.
- An option "-c" was added to ocs-put-signed-grub2-efi-bldr.

* Wed Sep 18 2013 Steven Shiau <steven _at_ nchc org tw> 3.6.1-drbl1
- Forcing to add grub-efi-ia32-bin and grub-efi-amd64-bin when downloading in ocs-gen-grub2-efi-bldr. Otherwise somehow in some cases they won't be downloaded.
- The signed EFI 1st and 2nd stage files from Ubuntu are used for secure booting in Ubuntu-based Clonezilla live. While for Debian-based one, we still follow the distribution, i.e. do not support uEFI secure boot.

* Fri Sep 10 2013 Steven Shiau <steven _at_ nchc org tw> 3.5.37-drbl1
- Put the extra boot prompt in the 1st line of help text for syslinux/pxelinux boot menu.

* Fri Sep 10 2013 Steven Shiau <steven _at_ nchc org tw> 3.5.36-drbl1
- An option "-r" was added in ocs-live-boot-menu so that we can add more prompt in the boot menu.

* Thu Sep 09 2013 Steven Shiau <steven _at_ nchc org tw> 3.5.35-drbl1
- The lvm2 service is disabled in GParted live (https://bugzilla.gnome.org/show_bug.cgi?id=702461).

* Mon Sep 09 2013 Steven Shiau <steven _at_ nchc org tw> 3.5.34-drbl1
- If ocs_prep_ocsroot_ask_dir is not "no" in prep-ocsroot, we just mount the partition as $ocsroot. Otherwise it's a little confusing.

* Sun Sep 08 2013 Steven Shiau <steven _at_ nchc org tw> 3.5.33-drbl1
- An extra ":" in the dialog prompt was removed from ocs-onthefly.

* Sun Sep 08 2013 Steven Shiau <steven _at_ nchc org tw> 3.5.32-drbl1
- Bug fixed: if somehow grub boot is found, while root does not exist, the boot mounting point should be unmounted before function test_run_grub2_from_restored_os or test_run_grub1_from_restored_os is exited in ocs-functions.
- The steps in program ocs-onthefly was refined so it's simplified and easier to read.

* Sat Sep 07 2013 Steven Shiau <steven _at_ nchc org tw> 3.5.31-drbl1
- Postrun opton in program "clonezilla" should be passed to ocs-onthefly.
- If the disk partition on destination disk is created, no need to ask one more confirmation when running ocs-onthefly.

* Sat Sep 07 2013 Steven Shiau <steven _at_ nchc org tw> 3.5.30-drbl1
- Removing the duplicated question mark after $msg_are_u_sure_u_want_to_continue.
- Making the interactive menu could be optionally shown for "ocs-onthefly -x".

* Fri Sep 06 2013 Steven Shiau <steven _at_ nchc org tw> 3.5.29-drbl1
- Two more optional TUI prompts were added in ocs-function.

* Thu Sep 05 2013 Steven Shiau <steven _at_ nchc org tw> 3.5.28-drbl1
- A better mechanism to get font size for KMS console was implemented.

* Wed Sep 04 2013 Steven Shiau <steven _at_ nchc org tw> 3.5.27-drbl1
- Comments about using local clonezilla live copy for iso_url_for_pxe_ocs_live_default was added in drbl-ocs.conf.
- Using variable for the dialog title in program "clonezilla" and ocs-sr.
- Only when "$ocs_sr_extra_restore_mode" is not "no" the other menus about restoring image (1-2-mdisk, check image...) will be shown in ocs-sr interactive mode.
- Removing the duplicated 'select the mode' prompt in ocs-sr interactive mode.
- Variable messages_shown_preference is used in confirm_continue_no_default_answer function of ocs-functions.

* Mon Sep 02 2013 Steven Shiau <steven _at_ nchc org tw> 3.5.26-drbl1
- The small font size in KMS mode has been improved.

* Sun Sep 01 2013 Steven Shiau <steven _at_ nchc org tw> 3.5.25-drbl1
- The extra ":' in function get_input_dev_name of ocs-functions was removed.
- The procedure about mounting local device as image repository in prep-ocsroot was improved.

* Sat Aug 31 2013 Steven Shiau <steven _at_ nchc org tw> 3.5.24-drbl1
- The prompt about inserting USB flash drive when mounting image repository was improved.

* Tue Aug 27 2013 Steven Shiau <steven _at_ nchc org tw> 3.5.23-drbl1
- The disabled service in upstart (/etc/init/) is named as *.conf.ocs-disabled instead of previous .conf.disabled.

* Mon Aug 26 2013 Steven Shiau <steven _at_ nchc org tw> 3.5.22-drbl1
- Giving more specific error messages when searching the unmounted partitions in get_input_dev_name.

* Mon Aug 26 2013 Steven Shiau <steven _at_ nchc org tw> 3.5.21-drbl1
- Bug fixed: ocs-srv-live should hide client's DRBL PXE boot menu.

* Sun Aug 25 2013 Steven Shiau <steven _at_ nchc org tw> 3.5.20-drbl1
- Variable clonezilla_client_menu_label_prefix is used in ocs-functions.

* Sat Aug 24 2013 Steven Shiau <steven _at_ nchc org tw> 3.5.19-drbl1
- A dummy file /etc/ocs/ocs-live.conf is put during DRBL live is created.
- Program ocs-srv-live supports 2nd mode in the parameters.
- A control variable ocs_prep_ocsroot_ask_dir was added in prep-ocsroot.
- Two control variables, ocs_net_show_pppoe and ocs_net_show_enter_shell, were added in ocs-live-netcfg.
- A control variable ocs_fsck_src_part was added in ocs-onthefly.

* Tue Aug 20 2013 Steven Shiau <steven _at_ nchc org tw> 3.5.18-drbl1
- Bug fixed: the mode in $live_auto_login_id_home/Desktop/Display.desktop for DRBL live should be 755.

* Mon Aug 19 2013 Steven Shiau <steven _at_ nchc org tw> 3.5.17-drbl1
- Skipping xfce4 panel question when 1st login in DRBL live.

* Thu Aug 15 2013 Steven Shiau <steven _at_ nchc org tw> 3.5.16-drbl1
- Options "-f -f" is used for ntfsresize in ocs-resize-part. Thanks to Jerome Charaoui for this suggestion (https://sourceforge.net/p/clonezilla/bugs/185/).

* Tue Aug 13 2013 Steven Shiau <steven _at_ nchc org tw> 3.5.15-drbl1
- Program ocs-expand-mbr-pt will keep linux swap. Thanks to Fabien Voland for this suggestion.

* Sat Aug 10 2013 Steven Shiau <steven _at_ nchc org tw> 3.5.14-drbl1
- Bug fixed: function get_latest_kernel_ver_in_repository in ocs-functions failed to get correct kernel version number in Debian repository when linux kernel package name like linux-image-3.10-2-rt-686-pae-dbg exists.

* Sat Aug 10 2013 Steven Shiau <steven _at_ nchc org tw> 3.5.13-drbl1
- Program drbl-ocs-live-prep now supports Clonezilla live iso from local path, e.g. file:///usr/share/iso/clonezilla-live-2.1.2-35-amd64.iso. Thanks to Chris S for this suggestion.

* Wed Aug 07 2013 Steven Shiau <steven _at_ nchc org tw> 3.5.12-drbl1
- SD card device (/dev/mmcblk0) is supported.
- Bug fixed: partclone.log should not be appended to clonezilla log right after partclone is run in the background in local disk to remote disk mode.

* Sun Jul 28 2013 Steven Shiau <steven _at_ nchc org tw> 3.5.11-drbl1
- Moved the dir /EFI-imgs in live CD/USB under the dir /EFI/, and renamed it as images (so now it's /EFI/images/).
- An option "sec=ntlm" was added in prep-ocsroot. Thanks to Jack and Dave Higton for reporting this issue.
- Cancel action in prep-ocsroot should work now.
- Use default DNS server 8.8.8.8 in ocs-live-netcfg.

* Fri Jul 26 2013 Steven Shiau <steven _at_ nchc org tw> 3.5.10-drbl1
- Adding saucy support in create-ubuntu-live.

* Fri Jul 26 2013 Steven Shiau <steven _at_ nchc org tw> 3.5.9-drbl1
- Bug fixed: ocs-onthefly local disk to remote disk failed to update the EFI nvram on remote machine.

* Fri Jul 26 2013 Steven Shiau <steven _at_ nchc org tw> 3.5.8-drbl1
- Bug fixed: the reference image option was not passed to update-efi-nvram-boot-entry after image is restored.
- Bug fixed: ocs-onthefly should not run update-efi-nvram-boot-entry when cloning disks locally.
- By default the lable name saved in efi-nvram.data will be used when running update-efi-nvram-boot-entry.

* Thu Jul 25 2013 Steven Shiau <steven _at_ nchc org tw> 3.5.7-drbl1
- Two more functions get_efi_hd_boot_entry_info and get_part_uuid_in_harddrive were addded in ocs-functions.
- File containing the output of "efibootmgr -v" will be saved as efi-nvram.data in image dir.
- By default Clonezilla will try to use the label saved from EFI NVRAM when updating the EFI NVRAM after the the image is restored on destination machine.

* Wed Jul 24 2013 Steven Shiau <steven _at_ nchc org tw> 3.5.6-drbl1
- Rename function get_latest_kernel_in_repository in create-ubuntu-live as get_latest_kernel_ver_in_repository, and move it to ocs-functions so it can be reused.

* Wed Jul 24 2013 Steven Shiau <steven _at_ nchc org tw> 3.5.5-drbl1
- Using the warning color for skipping running update-efi-nvram-boot-entry on Mac machine.
- Program update-nvram-efi-boot-entry was renamed as update-efi-nvram-boot-entry.
- Add more files (/EFI/redhat/grub.efi and /EFI/opensuse/grubx64.efi) in check lists of update-efi-nvram-boot-entry..

* Tue Jul 23 2013 Steven Shiau <steven _at_ nchc org tw> 3.5.4-drbl1
- Formating the output of update-nvram-efi-boot-entry.

* Tue Jul 23 2013 Steven Shiau <steven _at_ nchc org tw> 3.5.3-drbl1
- A program update-nvram-efi-boot-entry was added for updating the booting device in EFI NVRAM. Thanks to Les Mikesell (lesmikesell _at_ gmail com), Laszlo Ersek (lacos _at_ caesar elte hu) and Peter Sun (PeterSun _at_ ememory com tw) for reporting this issue.
- An option "-iefi" was added in in the restoring dialog menu.

* Tue Jul 16 2013 Steven Shiau <steven _at_ nchc org tw> 3.5.2-drbl1
- More info will be shown in the output for ocs-chkimg.

* Wed Jul 03 2013 Steven Shiau <steven _at_ nchc org tw> 3.5.1-drbl1
- Bug fixed: *sda-img.info should not be included in the partition image to be restored.
- Modification of ocs-functions and ocs-onthefly was done according to the changes in partclone 0.2.66.

* Sun Jun 30 2013 Steven Shiau <steven _at_ nchc org tw> 3.4.12-drbl1
- Bug fixed: sdap1 is not the partition of sda disk. Thanks to julienb35 for supporting this issue. Ref: https://sourceforge.net/p/clonezilla/bugs/179/
- The disk size info will be shown when selecting the images during restoring.

* Sat Jun 22 2013 Steven Shiau <steven _at_ nchc org tw> 3.4.11-drbl1
- A summary of ocs-chkimg will be shown after image is checked.  Thanks to Elke Moritz <moritz _at_ linuxtag org> for this suggestion.

* Tue Jun 19 2013 Steven Shiau <steven _at_ nchc org tw> 3.4.10-drbl2
- Required partclone version was updated to 0.2.62 due to a jfs bug has been fixed.

* Sun Jun 16 2013 Steven Shiau <steven _at_ nchc org tw> 3.4.10-drbl1
- Bug fixed: to keep the mechanism remove_start_stop_daemon_diverts working for live-build v2.x and v3.x, we have to set_start_stop_daemon_diverts after remove_start_stop_daemon_diverts in ocs-live-hook.

* Mon Jun 10 2013 Steven Shiau <steven _at_ nchc org tw> 3.4.9-drbl1
- Bug fixed: the start-stop-daemon divert mechanism in live-hook failed.

* Mon Jun 10 2013 Steven Shiau <steven _at_ nchc org tw> 3.4.8-drbl1
- Bug fixed: the /sbin/start-stop-daemon in the chroot should be removed before running dpkg-divert.

* Mon Jun 10 2013 Steven Shiau <steven _at_ nchc org tw> 3.4.7-drbl1
- Function remove_cdebootstrap-helper-diverts was renamed as remove_start_stop_daemon_diverts in the live-hook directory.

* Mon Jun 10 2013 Steven Shiau <steven _at_ nchc org tw> 3.4.6-drbl1
- Bug fixed: the reverted file for /sbin/start-stop-daemon is /sbin/start-stop-daemon.distrib for live-build v3.x. We have to reverted back before running "drblpush -i" when creating DRBL live.

* Thu Jun 06 2013 Steven Shiau <steven _at_ nchc org tw> 3.4.5-drbl1
- Bug fixed: A better method was implemented to detect the finishing of live-config in S00ocs-start.

* Wed Jun 05 2013 Steven Shiau <steven _at_ nchc org tw> 3.4.4-drbl1
- Bug fixed: S00ocs-start failed to deal with upstart services with same index number.

* Sun May 26 2013 Steven Shiau <steven _at_ nchc org tw> 3.4.3-drbl1
- Bug fixed: an error command in ocs-resize-part was fixed.

* Sun May 26 2013 Steven Shiau <steven _at_ nchc org tw> 3.4.2-drbl1
- Comments and coding about -k1/-k2 and -r in ocs-onthefly was improved.
- Command ntfsfix will be run before resizing a NTFS partition if option "-icds" is assigned.

* Sat May 25 2013 Steven Shiau <steven _at_ nchc org tw> 3.4.1-drbl1
- The option "-m" of partclone (v 0.2.61) is deprecated, and now "-z" is used.
- If the option "-icds" is used, option "-C" of partclone will be enabled, too.

* Thu May 16 2013 Steven Shiau <steven _at_ nchc org tw> 3.3.48-drbl1
- An option -vb|--vga-blacklist was added to ocs-live-boot-menu for enabling VGA card blacklist in boot parameters. By default no blacklists will be added.
- Still enable VGA blacklists for DRBL and Clonezilla live, while disable that for GParted live.

* Thu May 16 2013 Steven Shiau <steven _at_ nchc org tw> 3.3.47-drbl1
- VGA card blacklists in boot parameters were removed.

* Wed May 15 2013 Steven Shiau <steven _at_ nchc org tw> 3.3.46-drbl1
- Bug fixed: Option -icds of ocs-sr and ocs-onthefly should be passed to ocs-expand-mbr-pt. Thanks to Jerome Charaoui for reporting this issue (http://sourceforge.net/p/clonezilla/bugs/175/).

* Tue May 14 2013 Steven Shiau <steven _at_ nchc org tw> 3.3.45-drbl1
- Comments in ocs-functions were updated.

* Mon May 13 2013 Steven Shiau <steven _at_ nchc org tw> 3.3.44-drbl1
- Bug fixed: get_mkswap_uuid_cmd in ocs-functions failed to detect mkswap command for util-linux >= 2.20.

* Wed May 06 2013 Steven Shiau <steven _at_ nchc org tw> 3.3.43-drbl1
- Bug fixed: ocs-lvm2-stop did not load function disable_lvm2_udevd_rules from drbl-functions.
- Bug fixed: Function reduce_multipath_dev should use its own temp file.

* Mon May 06 2013 Steven Shiau <steven _at_ nchc org tw> 3.3.42-drbl1
- Using variable sys_pxelinux_v5p_required_c32 instead of sys_pxelinux_required_c32 for related programs.

* Mon May 06 2013 Steven Shiau <steven _at_ nchc org tw> 3.3.41-drbl1
- Functioin disable_lvm2_udevd_rules is used in ocs-lvm2-stop.

* Mon Apr 29 2013 Steven Shiau <steven _at_ nchc org tw> 3.3.40-drbl1
- Bug fixed: cnvt-ocs-dev failed to convert GPT disk names.

* Thu Apr 25 2013 Steven Shiau <steven _at_ nchc org tw> 3.3.39-drbl1
- Bug fixed: cnvt-ocs-dev did not change the file name correctly.

* Wed Apr 24 2013 Steven Shiau <steven _at_ nchc org tw> 3.3.38-drbl1
- Making created live iso/zip file work for syslinux/isolinux 5.01.

* Wed Apr 24 2013 Steven Shiau <steven _at_ nchc org tw> 3.3.37-drbl1
- Bug fixed: cnvt-ocs-dev failed to convert cciss-related device. Thanks to Andy Smith <a.smith _at_ ldex co uk> for reporting this issue.

* Sat Apr 20 2013 Steven Shiau <steven _at_ nchc org tw> 3.3.36-drbl1
- Package f2fs-tools was added for GParted live in create-gparted-live.

* Wed Apr 17 2013 Steven Shiau <steven _at_ nchc org tw> 3.3.35-drbl1
- Bug fixed: when first menu (start_clonezilla or enter_shell) was cancelled, it still continued.

* Wed Apr 10 2013 Steven Shiau <steven _at_ nchc org tw> 3.3.34-drbl1
- The sample file "custom-ocs-1" was updated.

* Tue Apr 09 2013 Steven Shiau <steven _at_ nchc org tw> 3.3.33-drbl1
- Bug fixed: ocs-live-run-menu failed to get final action when not in jfbterm or bterm mode.

* Tue Apr 09 2013 Steven Shiau <steven _at_ nchc org tw> 3.3.32-drbl1
- The sample file "custom-ocs-1" was updated.
- Bug fixed: Programs ocs-iso and ocs-live-dev were not updated to reflect the new file name of Ubuntu-based Clonezilla live with "-i386" in the file name.

* Tue Apr 09 2013 Steven Shiau <steven _at_ nchc org tw> 3.3.31-drbl1
- Some comments about "--retries-until-drop 50" for udp-sender was added in drbl-ocs.conf.
- The options "-j" of ocs-iso and ocs-live-dev were reverted because we need this option when using Clonezilla live environment to create Clonezilla live otherwise the template iso won't be assigned.

* Thu Apr 04 2013 Steven Shiau <steven _at_ nchc org tw> 3.3.30-drbl1
- Bug fixed: "Press ENTER to continue" message after poweroff/reboot command is issued was not shown.

* Wed Apr 03 2013 Steven Shiau <steven _at_ nchc org tw> 3.3.29-drbl1
- Dialog menu prompt about final action of Clonezilla live was improved.

* Wed Apr 03 2013 Steven Shiau <steven _at_ nchc org tw> 3.3.28-drbl1
- Dialog menu is used in the final action of Clonezilla live.

* Tue Apr 02 2013 Steven Shiau <steven _at_ nchc org tw> 3.3.27-drbl1
- The MAC address of network card will be shown when prompted in ocs-live-netcfg.

* Mon Apr 01 2013 Steven Shiau <steven _at_ nchc org tw> 3.3.26-drbl1
- Improving PXE client's boot parameter when using "select_in_client" mode.

* Fri Mar 29 2013 Steven Shiau <steven _at_ nchc org tw> 3.3.25-drbl1
- Bug fixed: when using "select_in_client" mode, the postrun action should be passed to PXE clients.

* Fri Mar 29 2013 Steven Shiau <steven _at_ nchc org tw> 3.3.24-drbl1
- Bug fixed: the implemented method in is_spawned_by_drbl_ocs wrongly parsed clonezilla live case.

* Fri Mar 29 2013 Steven Shiau <steven _at_ nchc org tw> 3.3.23-drbl1
- Typo in drbl-ocs.conf fixed.

* Wed Mar 27 2013 Steven Shiau <steven _at_ nchc org tw> 3.3.22-drbl1
- Bug fixed: GParted live an DRBL live were not isohybrided. Thanks to cvbn for reporting this issue.
- When running select-in-client mode on Clonezilla SE, job finished message will be sent, too.

* Wed Mar 27 2013 Steven Shiau <steven _at_ nchc org tw> 3.3.21-drbl1
- Bug fixed: fluxbox menu key function failed to start in GParted live.

* Tue Mar 26 2013 Steven Shiau <steven _at_ nchc org tw> 3.3.20-drbl1
- Bug fixed: Clonezilla SE client did not report the clonezilla job message when drbl-ocs is run with "-y1" option.

* Mon Mar 25 2013 Steven Shiau <steven _at_ nchc org tw> 3.3.19-drbl1
- Bug fixed: When using Clonezilla live as Clonezilla SE's client, the option "-y1" won't work for select-in-client mode.
- Message msg_etherboot_5_4_is_required in ocs-functions was disabled.

* Thu Mar 14 2013 Steven Shiau <steven _at_ nchc org tw> 3.3.18-drbl1
- The progress bar of resize2fs was turned on in ocs-resize-part.

* Thu Mar 14 2013 Steven Shiau <steven _at_ nchc org tw> 3.3.17-drbl1
- Bug fixed: ocs-onthefly failed to use with optioin "-k1" (http://sourceforge.net/projects/clonezilla/forums/forum/663168/topic/6933289). Thanks to Sebastien for reporting this issue.

* Wed Mar 13 2013 Steven Shiau <steven _at_ nchc org tw> 3.3.16-drbl1
- Prompt about skipping re-installing grub 1 in ocs-functions was improved.
- Bug fixed: Program ocs-tux-postprocess should search LV, too.

* Mon Mar 11 2013 Steven Shiau <steven _at_ nchc org tw> 3.3.15-drbl1
- Program grub-install won't be run for grub1 on ext4 file system when grub-install is from Debian.

* Mon Mar 11 2013 Steven Shiau <steven _at_ nchc org tw> 3.3.14-drbl1
- Typo in ocs-tux-postprocess was fixed.

* Mon Mar 11 2013 Steven Shiau <steven _at_ nchc org tw> 3.3.13-drbl1
- Bug fixed: for cloning partition mode, "-g auto" should not be turned on by default. 
- Program ocs-tux-postprocess was modified to process partition, not disk. It will be more specific when using with disk or partition restoring/cloning.
- Bug fixed: no ocs-update-syslinux process in ocs-onthefly.

* Tue Mar 05 2013 Steven Shiau <steven _at_ nchc org tw> 3.3.12-drbl1
- Improvement: Minix slice and sub-partition won't be imaged twice.

* Fri Mar 01 2013 Steven Shiau <steven _at_ nchc org tw> 3.3.11-drbl1
- Minix support was enabled since partclone 0.2.49 now works for minix.

* Tue Feb 25 2013 Steven Shiau <steven _at_ nchc org tw> 3.3.10-drbl1
- Bug fixed: ocs-chkimg failed to check the swap partition of cciss devices.

* Tue Feb 25 2013 Steven Shiau <steven _at_ nchc org tw> 3.3.9-drbl1
- Minor improvement in function install_grub_hd.
- Bug fixed: grub2-install failed to install the correct path in some cases.

* Fri Feb 21 2013 Steven Shiau <steven _at_ nchc org tw> 3.3.8-drbl1
- Bug fixed: duplicated function get_partition_list in ocs-functions was removed.
- Bug fixed: local part to local part clone failed.

* Fri Feb 21 2013 Steven Shiau <steven _at_ nchc org tw> 3.3.7-drbl1
- Bug fixed: failed to locate grub partition on cciss disk.

* Sun Feb 17 2013 Steven Shiau <steven _at_ nchc org tw> 3.3.6-drbl1
- An option -srel|--save-restore-error-log to force saving error log in the image dir was added in ocs-sr and drbl-ocs. By default we do not save that in the image dir when restoring. Only when saving it will be saved in the image dir. Thanks to futuremonkey for this suggestion.

* Wed Feb 13 2013 Steven Shiau <steven _at_ nchc org tw> 3.3.5-drbl1
- Bug fixed: multipath restoring for LVM failed due to do loop problem.

* Tue Feb 12 2013 Steven Shiau <steven _at_ nchc org tw> 3.3.4-drbl1
- Option "-m 1024" is used in ocs-onthefly, too.

* Mon Feb 11 2013 Steven Shiau <steven _at_ nchc org tw> 3.3.3-drbl1
- Using the variable sys_pxelinux_required_c32 definied in drbl.conf for ocs-update-syslinux.

* Sun Feb 10 2013 Steven Shiau <steven _at_ nchc org tw> 3.3.2-drbl1
- Adding "-m 1024" option to partclone. Thanks to Ingo Wolf <Ingo.Wolf _at_ gmx de> for this suggestion.

* Thu Feb 07 2013 Steven Shiau <steven _at_ nchc org tw> 3.3.1-drbl1
- Bug fixed: for Syslinux 5, 3 more files are required in ocs-update-syslinux, i.e. ldlinux.c32, libcom32.c32, libutil.c32

* Tue Feb 05 2013 Steven Shiau <steven _at_ nchc org tw> 3.3.0-drbl1
- The patches from Ceasar Sun for Fedora 17/18 were applied.

* Tue Jan 22 2013 Steven Shiau <steven _at_ nchc org tw> 3.2.17-drbl1
- Program fail-mbr.bin from partclone instead the one from drbl is used from now on.

* Tue Jan 22 2013 Steven Shiau <steven _at_ nchc org tw> 3.2.16-drbl1
- Bug fixed: ocs-onthefly failed to run disk to remote disk cloning.

* Sun Jan 20 2013 Steven Shiau <steven _at_ nchc org tw> 3.2.15-drbl1
- The size of a partition will be got from lsblk first in ocs-get-part-info if program lsblk exists.
- The options of ocs-resize-part have been changed. No more separating them as "ocs-resize-part sda 1", now using "ocs-resize-part /dev/sda1" so that we can use that for dm in the future.
- The output file Info-lsblk.txt has been renamed to blkdev.list with formatted output.
- Using file system info from lsblk (blkdev.list) since it's much easier to use than the output of parted if it's device mapper devices.

* Thu Jan 17 2013 Steven Shiau <steven _at_ nchc org tw> 3.2.14-drbl1
- Adding Xen disk (/dev/xvd[a-z]) in the support device.
- Adding one more info file "Info-lsblk.txt", lsblk output.

* Mon Jan 14 2013 Steven Shiau <steven _at_ nchc org tw> 3.2.13-drbl1
- Using the mapping file instead of /proc/partitions in ocs-chnthn-functions, ocs-functions and ocs-restore-mdisks.
- Using the get_disk_list in ocs-chnthn.

* Fri Jan 11 2013 Steven Shiau <steven _at_ nchc org tw> 3.2.12-drbl1
- Commets about using blkid to get file system was added in ocs-get-part-info.
- Bug fixed: drbl-ocs-live-prep failed to identify the new, different arch of iso for the alternative testing Clonezilla live on the repository.

* Thu Jan 10 2013 Steven Shiau <steven _at_ nchc org tw> 3.2.11-drbl1
- Bug fixed: failed to parse cciss/c0d0's partition number. It should be nothing.

* Wed Jan 09 2013 Steven Shiau <steven _at_ nchc org tw> 3.2.10-drbl1
- Bug fixed: Typos in ocs-chkimg and ocs-functions were fixed.

* Wed Jan 09 2013 Steven Shiau <steven _at_ nchc org tw> 3.2.9-drbl1
- Function active_proc_partitions was moved to ocs-functions from drbl-functions.
- Bug fixed: Swap partition of cciss partition was not saved and restored.

* Wed Jan 09 2013 Steven Shiau <steven _at_ nchc org tw> 3.2.8-drbl1
- Program create-ocs-tmp-img has been improved to be multipath compatible.

* Wed Jan 09 2013 Steven Shiau <steven _at_ nchc org tw> 3.2.7-drbl1
- Bug fixed: ocs-get-part-info failed to identify the cciss partition type.
- Bug fixed: failed to identify logical partitioin in ocs-expand-mbr-pt.
- Program cnvt-ocs-dev has been improved to be multipath compatible.

* Tue Jan 08 2013 Steven Shiau <steven _at_ nchc org tw> 3.2.6-drbl1
- All "hsv" related codes of Clonezilla were converted to multipath compatible.
- The multipath codes from Miracle Linux were merged.

* Sat Jan 05 2013 Steven Shiau <steven _at_ nchc org tw> 3.2.5-drbl1
- Put the output of restore_hidden_data_after_MBR to log file, too.

* Sat Jan 05 2013 Steven Shiau <steven _at_ nchc org tw> 3.2.4-drbl1
- Typo fixed: "Unmouted" -> "Unmounted" in ocs-functions. Thanks to Peter Bratton <peter _at_ bratton ca> for reporting this.
- Part of the LVM codes from Miracle Linux were merged.

* Thu Jan 03 2013 Steven Shiau <steven _at_ nchc org tw> 3.2.3-drbl1
- Bug fixed: Getting default gateway was not working in function network_config_if_necessary of ocs-functions.

* Thu Jan 03 2013 Steven Shiau <steven _at_ nchc org tw> 3.2.2-drbl1
- Using "route -n" instead of "route" to find the default gateway in function network_config_if_necessary of ocs-functions.

* Thu Jan 03 2013 Steven Shiau <steven _at_ nchc org tw> 3.2.1-drbl1
- Two log files were separated from clonezilla.log: ocs-netcfg.log and ocs-mount.log.

* Thu Jan 03 2013 Steven Shiau <steven _at_ nchc org tw> 3.2.0-drbl1
- Removing packages exfat-utils and exfat-fuse create-gparted-live.
- If udevadm exists, use it to get the disk serial number. Thanks to Miracle Linux for this idea.
- Define the OCS_LOGFILE variable in drbl-ocs.conf.
- The variable DRBL_SCRIPT_PATH in gparted-live-hook was removed. It's not used when creating GParted live.
- Function parse_cmdline_option in gl-functions was updated to be the same as that in drbl-functions.
- File ocs-devsort from Miracle Linux was added.
- Part of the modifications from Miracle Linux were merged, including using functions get_diskname, get_part_number... and logging the screen output in /var/log/clonezilla.log.

* Mon Dec 24 2012 Steven Shiau <steven _at_ nchc org tw> 3.1.38-drbl1
- Using functions to decide if GPT or MBR disk in ocs-onthefly.

* Mon Dec 24 2012 Steven Shiau <steven _at_ nchc org tw> 3.1.37-drbl1
- Using functions to decide if GPT or MBR disk in ocs-functions.

* Sun Dec 23 2012 Steven Shiau <steven _at_ nchc org tw> 3.1.36-drbl1
- Adding packages exfat-utils, exfat-fuse and tcplay in create-gparted-live.
- Bug fixed: EFI booting for DRBL live did not really work.

* Sat Dec 22 2012 Steven Shiau <steven _at_ nchc org tw> 3.1.35-drbl1
- Package grub-pc instead of grub is put in the packages list of create-gparted-live.
- Program create-gparted-live now supports creating amd64 release.

* Sat Dec 22 2012 Steven Shiau <steven _at_ nchc org tw> 3.1.34-drbl1
- Bug fixed: EFI booting for GParted live did not really work.

* Thu Dec 20 2012 Steven Shiau <steven _at_ nchc org tw> 3.1.33-drbl1
- Bug fixed: Usage prompt for "-f" in create-debian-live was not updated.
- Option "-f" was added to create-ubuntu-live so that amd64 version of Clonezilla live could be created.

* Thu Dec 20 2012 Steven Shiau <steven _at_ nchc org tw> 3.1.32-drbl1
- If the hidden data size won't be saved, a note file should be saved in the image dir.

* Wed Dec 19 2012 Steven Shiau <steven _at_ nchc org tw> 3.1.31-drbl1
- Bug fixed: install_grub_hd should not run for GPT disk.
- If the hidden data size after MBR is larger than $hidden_data_after_mbr_limit (definited in drbl-ocs.conf), it won't be saved.

* Sun Dec 16 2012 Steven Shiau <steven _at_ nchc org tw> 3.1.30-drbl1
- Bug fixed: No more using "Something went wrong" message, instead more precise messages will be given.
- Module floppy was added in the blacklist in Clonezilla live and DRBL live. The floppy is normally useless but if it exists, it might cause the disk detection delay. If floppy is required, a user still can run "modprobe floppy" to load it.

* Sun Dec 09 2012 Steven Shiau <steven _at_ nchc org tw> 3.1.29-drbl1
- Bug fixed: typos in the prompt were fixed.
- Bug fixed: To avoid the OS does not know the partition changes, a command "partprobe" was added in prep-ocsroot after local disk is inserted. Thanks to neikalo for reporting this issue (https://sourceforge.net/tracker/index.php?func=detail&aid=3592776&group_id=115473&atid=671650).
- Bug fixed: To avoid grub1 on ext4 issue, running the grub-install from the restored OS should be try first. If fails, then using the grub1 on the running OS.

* Wed Dec 05 2012 Steven Shiau <steven _at_ nchc org tw> 3.1.28-drbl1
Bug fixed: partition table should be initialized before using function check_mbr_disk_size_gt_2TiB.

* Wed Dec 05 2012 Steven Shiau <steven _at_ nchc org tw> 3.1.27-drbl1
- Bug fixed: converting the checking mechanism of 2 TiB as function and using that all before writing MBR partition table on a hard disk.

* Tue Dec 04 2012 Steven Shiau <steven _at_ nchc org tw> 3.1.26-drbl1
- Bug fixed: MBR partition table should not be larger than 2 TiB (2.2 TB). A checking mechanism was added in ocs-expand-mbr-pt to avoid going on.

* Sat Dec 01 2012 Steven Shiau <steven _at_ nchc org tw> 3.1.25-drbl1
- Bug fixed: the description for the option "-r" of ocs-sr and ocs-onthefly was polished. Thanks to auroracore.
- Updtaed the lh_ver_required in drbl-ocs.conf, and since we no more using cdebootstrap to create Clonezilla/DRBL/GParted live, variable should change to debootstrap_ver_required instead of cdebootstrap_ver_required.

* Fri Nov 30 2012 Steven Shiau <steven _at_ nchc org tw> 3.1.24-drbl1
- Bug fixed: the -k option of ocs-iso and ocs-live-dev should be updated since now keyboard layout boot parameter from live-config is used.
- Bug fixed: the batch_mode on the server is nothing to do with that on the client in the program ocs-onthefly. Thanks to kevluck373 for reporting this issue (https://sourceforge.net/projects/clonezilla/forums/forum/663168/topic/6188724).
- The options "-j" and "-n" of ocs-iso and ocs-live-dev were removed because we won't put the template iso on the repository anymore.
- No more using template iso from reporitory, now we use clonezilla live iso when running ocs-iso or ocs-live-dev to create a recovery iso or zip.

* Wed Nov 28 2012 Steven Shiau <steven _at_ nchc org tw> 3.1.23-drbl1
- Locale ca_ES will be generated when creating Clonezilla live.

* Sat Nov 24 2012 Steven Shiau <steven _at_ nchc org tw> 3.1.22-drbl1
- Bug fixed: for Debian live 3.x, the filesystem.squashfs is in /lib/live/image.

* Fri Nov 23 2012 Steven Shiau <steven _at_ nchc org tw> 3.1.21-drbl1
- Bug fixed: the for loop for searching files /lib/udev/rules.d/*.drblsave should test if file really exists before going on.

* Fri Nov 23 2012 Steven Shiau <steven _at_ nchc org tw> 3.1.20-drbl1
- Bug fixed: the date tag of image name for autohostname should be consistent with that of autoname.
- Help messages about autoproductname were added.
- Another partition table file was added in image dir. It's easier for human to read.

* Tue Nov 20 2012 Steven Shiau <steven _at_ nchc org tw> 3.1.19-drbl1
- Bug fixed: ocs-lvm2-stop did not work on Ubuntu Linux due to the udevd rules 85-lvm2.rules from Ubuntu.

* Thu Nov 08 2012 Steven Shiau <steven _at_ nchc org tw> 3.1.18-drbl1
- Suppress the stderr messages of ocs-lvm2-start and ocs-lvm2-stop.

* Sun Nov 04 2012 Steven Shiau <steven _at_ nchc org tw> 3.1.17-drbl1
- Bug fixed: uEFI booting of Quantal-based Clonezilla failed due to grub 2.x has no "pci.mod", so we should not list it.

* Mon Oct 29 2012 Steven Shiau <steven _at_ nchc org tw> 3.1.16-drbl1
- Bug fixed: for live-config v3.x, the last file in /lib/live/config/ is 9990-hooks, not 999-hooks. S00ocs-start should honor 9990-hooks, too.

* Mon Oct 29 2012 Steven Shiau <steven _at_ nchc org tw> 3.1.15-drbl1
- Bug fixed: the filesystem.squashfs is in /lib/live/image/ when created by live-build 3.x.

* Sun Oct 28 2012 Steven Shiau <steven _at_ nchc org tw> 3.1.14-drbl1
- Bug fixed: autohostname failed to append the time tag for the image name. Thanks to dennisd248 for reporthing this bug.

* Wed Oct 24 2012 Steven Shiau <steven _at_ nchc org tw> 3.1.13-drbl1
- Bug fixed: the *.mod files for grub2 are not fixed in the path /boot/grub/. It could be in /boot/grub/i386-pc/. Function install_grub_hd failed in this case.

* Mon Oct 22 2012 Steven Shiau <steven _at_ nchc org tw> 3.1.12-drbl1
- Bug fixed: Prompts in create-ubuntu-live were out-of-date. They are updated so there is no problem to create Raring-based Clonezilla live.

* Fri Sep 28 2012 Steven Shiau <steven _at_ nchc org tw> 3.1.11-drbl1
- Bug fixed: variable DRBL_SCRIPT_PATH was not defined correctly in live-hook files 

* Fri Sep 28 2012 Steven Shiau <steven _at_ nchc org tw> 3.1.10-drbl1
- Bug fixed: the install_grub_hd in ocs-live-dev should skip checking the boot loader on the USB flash drive, because it might be new, empty one.

* Wed Sep 26 2012 Steven Shiau <steven _at_ nchc org tw> 3.1.9-drbl1
- Typo fixed in ocs-live-boot-menu.

* Wed Sep 26 2012 Steven Shiau <steven _at_ nchc org tw> 3.1.8-drbl1
- To avoid the KMS and vmwgfx conflict issue (http://bugs.debian.org/cgi-bin/bugreport.cgi?bug=686939), some blacklist boot parameters were added.

* Mon Sep 24 2012 Steven Shiau <steven _at_ nchc org tw> 3.1.7-drbl1
- Bug fixed: integer too large won't work in bash if command, changed to bc in ocs-sr.

* Mon Sep 24 2012 Steven Shiau <steven _at_ nchc org tw> 3.1.6-drbl1
- Bug fixed: the VOL_LIMIT for spliting image file could not larger than 20000000000000. Ref: https://sourceforge.net/tracker/?func=detail&atid=671650&aid=3567350&group_id=115473
- Bug fixed: saving mode should enable ncurse interface by default, too. Otherwise it's confusing.

* Sat Sep 08 2012 Steven Shiau <steven _at_ nchc org tw> 3.1.5-drbl1
- A KMS mode in the boot menu was added.

* Fri Sep 07 2012 Steven Shiau <steven _at_ nchc org tw> 3.1.4-drbl1
- Bug fixed: when vga=normal, locales was not set in /etc/ocs/ocs-live.conf.

* Wed Sep 05 2012 Steven Shiau <steven _at_ nchc org tw> 3.1.3-drbl1
- Using drbl-run-parts instead of run-parts. This will be more straightforward.

* Mon Aug 27 2012 Steven Shiau <steven _at_ nchc org tw> 3.1.2-drbl1
- A reserved image name "autoproductname" was added so that Clonezilla can use that to save and restore image based on the manufacture and product name got from dmidecode.

* Sun Aug 26 2012 Steven Shiau <steven _at_ nchc org tw> 3.1.1-drbl1
- Removing the vague "Something went wrong" prompts.

* Sat Aug 25 2012 Steven Shiau <steven _at_ nchc org tw> 3.1.0-drbl1
- Using drbl-sl instead of calling drbl-SL.sh now.
- Using drbl-live instead of calling drbl-live.sh now. 
- File ocs-srv-live.sh was renamed as ocs-srv-live.
- Adding the interpreter's magic number for ocs-functions, and ocs-chnthn-functions to avoid lintian's warning.
- Bug fixed: an extra "{" in the end of MC_HxEd was removed.
 
* Mon Aug 20 2012 Steven Shiau <steven _at_ nchc org tw> 3.0.10-drbl1
- Boot parameter "nolocales" was removed from Clonezilla live since now "locales=" is used by default.
- Prompt msg_client_job_are_logged_in was updated. Thanks to René Mérou for asking.

* Fri Aug 17 2012 Steven Shiau <steven _at_ nchc org tw> 3.0.9-drbl1
- Tidy the boot parameters of Clonezilla live by modifying ocs-iso and ocs-live-dev.

* Wed Aug 15 2012 Steven Shiau <steven _at_ nchc org tw> 3.0.8-drbl1
- Boot parameter "ocs_lang" in Clonezilla live is now replaced by "locales" from live-config.
- Boot parameter "ocs_live_keymap" Clonezilla live is now replaced by "keyboard-layouts" from live-config.
- Boot parameters "echo_ocs_prerun" and "echo_ocs_postrun" were added. This can be used to disable echoing the ocs_prerun and ocs_postrun command.

* Wed Aug 15 2012 Steven Shiau <steven _at_ nchc org tw> 3.0.7-drbl1
- Bug fixed: The description using space key to mark the selection for disk to disk clone is not required. Thanks to sabrehagen (https://sourceforge.net/tracker/?func=detail&atid=671650&aid=3552271&group_id=115473).

* Mon Aug 13 2012 Steven Shiau <steven _at_ nchc org tw> 3.0.6-drbl1
- Comments about isohybriding template iso and clonezilla/drbl/gparted iso were added.

* Sun Aug 12 2012 Steven Shiau <steven _at_ nchc org tw> 3.0.5-drbl1
- Using /usr/share/drbl instead of /usr/share/drbl/ so that no "//" in the PATH.

* Thu Aug 09 2012 Steven Shiau <steven _at_ nchc org tw> 3.0.4-drbl1
- Bug fixed: system PATH in live CD should include /sbin and /usr/sbin

* Thu Aug 09 2012 Steven Shiau <steven _at_ nchc org tw> 3.0.3-drbl1
- Using file GPL instead of COPYING in live CD root dir.

* Wed Aug 08 2012 Steven Shiau <steven _at_ nchc org tw> 3.0.2-drbl1
- Bug fixed: drbl.conf and drbl-ocs.conf are not in $DRBL_SCRIPT_PATH/conf/ anymore.

* Wed Aug 08 2012 Steven Shiau <steven _at_ nchc org tw> 3.0.1-drbl1
- Adding experimental branch option in create-*-live, and remove unnecessary branch list.

* Tue Aug 07 2012 Steven Shiau <steven _at_ nchc org tw> 3.0.0-drbl1
- Clonezilla version 3. New files arch so it's easier to be packaged in Debian.

* Thu Aug 02 2012 Steven Shiau <steven _at_ nchc org tw> 2.6.21-1drbl
- The function get_live_autologin_account of gl-functions will now search the files in /etc/sudoers.d/, too.

* Sat Jul 28 2012 Steven Shiau <steven _at_ nchc org tw> 2.6.20-1drbl
- Bug fixed: leafpad in the fluxbox menu should not run with a terminal in GParted live.

* Sat Jul 28 2012 Steven Shiau <steven _at_ nchc org tw> 2.6.19-1drbl
- The man pages will be kept in GParted live (https://bugzilla.gnome.org/show_bug.cgi?id=680503).
- Packages leafpad and pcmanfm were added in GParted live (https://bugzilla.gnome.org/show_bug.cgi?id=680504).

* Fri Jul 27 2012 Steven Shiau <steven _at_ nchc org tw> 2.6.18-1drbl
- Do not remove libfreetype6 when creating Clonezilla live. It's required by fontconfig.

* Fri Jul 27 2012 Steven Shiau <steven _at_ nchc org tw> 2.6.17-1drbl
- Bug fixed: failed to multicast restore an EFI disk. 

* Wed Jul 25 2012 Steven Shiau <steven _at_ nchc org tw> 2.6.16-1drbl
- The command to save an image will be saved in the image dir as file Info-saved-by-cmd.txt.
- Adding package "man" in GParted live, and keeping the /usr/share/man files.

* Sat Jul 21 2012 Steven Shiau <steven _at_ nchc org tw> 2.6.15-1drbl
- Adding "sleep 5" after showning the warning about genisoimage not supporting "-efi-boot" option.

* Sat Jul 14 2012 Steven Shiau <steven _at_ nchc org tw> 2.6.14-1drbl
- The function get_live_autologin_account of ocs-functions will now search the files in /etc/sudoers.d/, too.

* Thu Jul 12 2012 Steven Shiau <steven _at_ nchc org tw> 2.6.13-1drbl
- Bug fixed: linux-image-extra version was not assigned correctly in Ubuntu-based (12.10 pre-release) Clonezilla live.

* Thu Jul 12 2012 Steven Shiau <steven _at_ nchc org tw> 2.6.12-1drbl
- Package linux-image-extra was added in Ubuntu-based (12.10 pre-release) Clonezilla live.

* Tue Jul 10 2012 Steven Shiau <steven _at_ nchc org tw> 2.6.11-1drbl
- File system exfat was added in partclone support file system.

* Mon Jul 09 2012 Steven Shiau <steven _at_ nchc org tw> 2.6.10-1drbl
- Netsurf icon was added on idesktop of GParted live.

* Mon Jul 09 2012 Steven Shiau <steven _at_ nchc org tw> 2.6.9-1drbl
- Comment was added in front of "Menu :RootMenu".

* Mon Jul 09 2012 Steven Shiau <steven _at_ nchc org tw> 2.6.8-1drbl
- Bug fixed: "Menu :RootMenu" not "menu :RootMenu".

* Thu Jul 05 2012 Steven Shiau <steven _at_ nchc org tw> 2.6.7-1drbl
- "menu :RootMenu" will be appended to fluxbox's keys file in GParted live. Ref: https://bugzilla.gnome.org/show_bug.cgi?id=578842#c8

* Sun Jul 01 2012 Steven Shiau <steven _at_ nchc org tw> 2.6.6-1drbl
- Bug fixed: gl_lang taken from locales should be without ".UTF-8".

* Sun Jul 01 2012 Steven Shiau <steven _at_ nchc org tw> 2.6.5-1drbl
- Function show_deprecated_ocs_gl_lang_and_keymap was added in gl-functions.
- Separating the functions to show the deprecated messages for keybord and lang in Clonezilla/DRBL live and GParted live.

* Sat Jun 30 2012 Steven Shiau <steven _at_ nchc org tw> 2.6.4-1drbl
- Make the output of S03prep-drbl-clonezilla and S03prep-gparted-live better for reading.

* Sat Jun 30 2012 Steven Shiau <steven _at_ nchc org tw> 2.6.3-1drbl
- Showing deprecated messages about boot parameters ocs_live_keymap, ocs_lang, gl_kbd, gl_lang, and keyb.

* Fri Jun 29 2012 Steven Shiau <steven _at_ nchc org tw> 2.6.2-1drbl
- Bug fixed: wrong variables in S03prep-drbl-clonezilla and S03prep-gparted-live.

* Fri Jun 29 2012 Steven Shiau <steven _at_ nchc org tw> 2.6.1-1drbl
- Comments were added in ocs-live-hook to mention about ocs_live_keymap is deprecated.
- In DRBL/Clonezilla live, ocs_lang will honor the live-config boot parameter "locales", and live-config boot parameters "keyboard-layouts" or "live-config.keyboard-layouts" will be honored, too. From now on ocs_live_keymap is deprecated.
- In GParted live, gl_lang will honor the live-config boot parameter "locales", and live-config boot parameters "keyboard-layouts" or "live-config.keyboard-layouts" will be honored, too. From now on "keyb" is deprecated.

* Wed Jun 20 2012 Steven Shiau <steven _at_ nchc org tw> 2.5.42-1drbl
- A better mechanism was implemented to decide the restored OS is using grub 1 or 2. Thanks to Robert Weir for reporting this issue on Fedora 17 restoring.

* Mon Jun 18 2012 Steven Shiau <steven _at_ nchc org tw> 2.5.41-1drbl
- Command "sleep 1" was added before running gdisk after sgdisk -l.

* Wed Jun 13 2012 Steven Shiau <steven _at_ nchc org tw> 2.5.40-1drbl
- Bug fixed: no grub config head data in ocs-gen-grub2-efi-bldr.
- Booting on uEFI machine is supported in ocs-iso and ocs-live-dev.

* Tue Jun 12 2012 Steven Shiau <steven _at_ nchc org tw> 2.5.39-1drbl
- Improvement: if somehow protective MBR does not exist in GPT disk, we will create it.

* Thu Jun 07 2012 Steven Shiau <steven _at_ nchc org tw> 2.5.38-1drbl
- Bug fixed: (another one) when mounting partition in install_grub_hd, swap and extended partition should be skipped otherwise mount command might hang.

* Thu Jun 07 2012 Steven Shiau <steven _at_ nchc org tw> 2.5.37-1drbl
- Bug fixed: when mounting partition in install_grub_hd, swap and extended partition should be skipped otherwise mount command might hang.

* Sun May 20 2012 Steven Shiau <steven _at_ nchc org tw> 2.5.36-1drbl
- Force to add net-tools in packages list of create-gparted-live.

* Sat May 19 2012 Steven Shiau <steven _at_ nchc org tw> 2.5.35-1drbl
- Adding gptsync in packages list of create-gparted-live.

* Fri May 18 2012 Steven Shiau <steven _at_ nchc org tw> 2.5.34-1drbl
- Bug fixed: Putting cifs as one of the network filesystem in prep-ocsroot.

* Sat May 05 2012 Steven Shiau <steven _at_ nchc org tw> 2.5.33-1drbl
- Adding Ubuntu Quantal support in create-ubuntu-live.

* Tue Apr 17 2012 Steven Shiau <steven _at_ nchc org tw> 2.5.32-1drbl
- Allowing to enter command line prompt to create partition table when blank destination disk is found in restoreparts mode.

* Tue Apr 10 2012 Steven Shiau <steven _at_ nchc org tw> 2.5.31-1drbl
- "autohostname" was improved when no FQDN was found.

* Tue Apr 10 2012 Steven Shiau <steven _at_ nchc org tw> 2.5.30-1drbl
- Bug fixed: missing option -bt|--bootstrap for create-drbl-live-by-pkg.

* Sun Apr 08 2012 Steven Shiau <steven _at_ nchc org tw> 2.5.29-1drbl
- An option to use "autohostname" to create the image name was added.  Thanks to tererecool (David Bauer) for this idea.

* Sat Apr 07 2012 Steven Shiau <steven _at_ nchc org tw> 2.5.28-1drbl
- Bug fixed: Non-free firmware doc should not be removed by function dirty_hacking_rm_files_for_ocs_live.

* Sat Apr 07 2012 Steven Shiau <steven _at_ nchc org tw> 2.5.27-1drbl
- Non-free firmware doc will be included in Ubuntu-based Clonezilla live, too.

* Fri Apr 06 2012 Steven Shiau <steven _at_ nchc org tw> 2.5.26-1drbl
- More non-free firmware, e.g. ipw2200, will be included in Ubuntu-based Clonezilla live. Thanks to Shinobi (iam_shinobi _at_ yahoo com) for this suggestion.

* Thu Apr 05 2012 Steven Shiau <steven _at_ nchc org tw> 2.5.25-1drbl
- Vmfs5 supported by partclone was enabled in drbl-ocs.conf, because partclone 0.2.46 has supported it.

* Wed Apr 04 2012 Steven Shiau <steven _at_ nchc org tw> 2.5.24-1drbl
- Typo fixed in the previous grpck workaround.

* Wed Apr 04 2012 Steven Shiau <steven _at_ nchc org tw> 2.5.23-1drbl
- A workaround was added to avoid grpck error during booting. Ref: http://bugs.debian.org/cgi-bin/bugreport.cgi?bug=638263

* Sun Mar 18 2012 Steven Shiau <steven _at_ nchc org tw> 2.5.22-1drbl
- A function get_not_busy_disks_or_parts was added in ocs-functions so it can be reused. 
- A researved name "all" is used for finding all the devices in the system or in the image. Thanks to matthiaswe for this idea.

* Wed Mar 07 2012 Steven Shiau <steven _at_ nchc org tw> 2.5.21-1drbl
- Adding packages wicd and xvnc4viewe in drbl-live.

* Mon Mar 05 2012 Steven Shiau <steven _at_ nchc org tw> 2.5.20-1drbl
- Adding packages "tree" and "cifs-utils" for gparted live in create-gparted-live.
- The image of a partition saved by dd won't be treated as a broken one in ocs-chkimg.
- The grub4 on ext4 warning will be shown again if grub1 is not run successfully.

* Thu Mar 01 2012 Steven Shiau <steven _at_ nchc org tw> 2.5.19-1drbl
- Adding package samba-common-bin in create-drbl-live-by-pkg.

* Mon Feb 27 2012 Steven Shiau <steven _at_ nchc org tw> 2.5.18-1drbl
- Enabling startpar for DRBL live server.

* Sun Feb 26 2012 Steven Shiau <steven _at_ nchc org tw> 2.5.17-1drbl
- Allowing cancellation when selecting a dir name for local image repository. Closed https://sourceforge.net/tracker/?func=detail&atid=671650&aid=3491047&group_id=115473

* Sat Feb 25 2012 Steven Shiau <steven _at_ nchc org tw> 2.5.16-1drbl
- A warning message about grub 1 on ext4 partition will be shown.

* Thu Feb 23 2012 Steven Shiau <steven _at_ nchc org tw> 2.5.15-1drbl
- Replacing dillo with netsurf, and adding nilfs-tools in create-gparted-live.

* Mon Feb 20 2012 Steven Shiau <steven _at_ nchc org tw> 2.5.14-2drbl
- Switch to use "lrzip -q -d -o -" instead of "lrzcat -q" so that in order version of lrzip can be used. Closed https://sourceforge.net/tracker/index.php?func=detail&aid=3487541&group_id=115473&atid=671650.

* Sat Feb 11 2012 Steven Shiau <steven _at_ nchc org tw> 2.5.13-2drbl
- Update the requires for drbl 1.11.2.

* Fri Feb 10 2012 Steven Shiau <steven _at_ nchc org tw> 2.5.13-1drbl
- An option to start over while keeping the mounted image repository was added.

* Thu Feb 09 2012 Steven Shiau <steven _at_ nchc org tw> 2.5.12-1drbl
- Using btrfs instead of btrfsctl in ocs-resize-part.

* Mon Feb 06 2012 Steven Shiau <steven _at_ nchc org tw> 2.5.11-1drbl
- The prompt in ocs-update-syslinux was updated.
- Force the kernel to re-read the partition table after sgdisk --zap-all the disk.

* Fri Feb 05 2012 Steven Shiau <steven _at_ nchc org tw> 2.5.10-1drbl
- Command fsck with options will be shown before running.

* Thu Feb 02 2012 Steven Shiau <steven _at_ nchc org tw> 2.5.9-1drbl
- The descriptions about grub2 and grub1 in functions of prepare_grub2_files_if_required and prepare_grub1_files_if_required of ocs-functions were updated.
- Option -fsck-src-part-y was added for running fsck with option -y.

* Wed Jan 25 2012 Steven Shiau <steven _at_ nchc org tw> 2.5.8-1drbl
- A better way to purge grub1 or grub2 related packages was implemented in the functions of prepare_grub1_files_if_required and prepare_grub2_files_if_required.

* Wed Jan 25 2012 Steven Shiau <steven _at_ nchc org tw> 2.5.7-2drbl
- LVM on RAID device CCISS was improved. Thanks to Gianluca Bellina <Gianluca.Bellina _at_ acision com> for the bug report.

* Wed Jan 25 2012 Steven Shiau <steven _at_ nchc org tw> 2.5.7-1drbl
- "sudo" was added before "sgdisk -z /dev/sdx" prompt. Thanks to drobb for this suggestion.
- The required packages of grub 1 and 2 were updated when Clonezilla/DRBL/GParted live are created.

* Mon Jan 23 2012 Steven Shiau <steven _at_ nchc org tw> 2.5.6-1drbl
- Disable apt languages and translations when creating Clonezilla/GParted live. This could reduce apt repository issue.

* Mon Jan 23 2012 Steven Shiau <steven _at_ nchc org tw> 2.5.5-1drbl
- Package discover1 was removed from the packages list in create-drbl-live-by-pkg.

* Mon Jan 23 2012 Steven Shiau <steven _at_ nchc org tw> 2.5.4-1drbl
- Disable apt languages and translations when creating DRBL live. This could reduce apt repository issue.

* Sat Jan 21 2012 Steven Shiau <steven _at_ nchc org tw> 2.5.3-1drbl
- A better mechanism was implemented in ocs-update-syslinux. Only when the files to be updated are found on the system "syslinux -i" will be run.

* Fri Jan 20 2012 Steven Shiau <steven _at_ nchc org tw> 2.5.2-1drbl
- The usage of ocs-sr and drbl-ocs were updated. "ask_user" and "autoname" were added.
- An option to use "autoname" to create the image name was added.  Thanks to encephalophone (Mike) for the patch.
- An option (-icds, --ignore-chk-dsk-size-pt) to skip checking skip checking destination disk size before creating the partition table on it was added. Thanks to Sartoratti Lorenzo for reporting this issue.

* Wed Jan 18 2012 Steven Shiau <steven _at_ nchc org tw> 2.5.1-1drbl
- VMFS3 and VMFS5 support are separated, no more mixed because partclone.fstype from 0.2.45 now can tell them. Since vmfs5 support is still buggy, disable it in drbl-ocs.conf.

* Mon Jan 16 2012 Steven Shiau <steven _at_ nchc org tw> 2.4.37-1drbl
- A better mechanism was implemented to keep the MS Windows boot reserved partition size when option "-k1" is chosed.
- GPT partition table info will also be dumped in plain text file when saving an image so that it's easier to read.

* Sat Jan 14 2012 Steven Shiau <steven _at_ nchc org tw> 2.4.36-1drbl
- A better mechanism to deal with UFS partition in a GPT table when saving FreeBSD 9.0.

* Wed Jan 11 2012 Steven Shiau <steven _at_ nchc org tw> 2.4.35-1drbl
- Make checking MBR/GPT partition table earlier in saveparts.

* Tue Jan 10 2012 Steven Shiau <steven _at_ nchc org tw> 2.4.34-1drbl
- The mismatched GPT and MBR partition table on a disk will be detected.

* Wed Jan 05 2012 Steven Shiau <steven _at_ nchc org tw> 2.4.33-1drbl
- An option to create source tarball was added in create-drbl-live-by-pkg.
- Git was added in the packages list in create-drbl-live-by-pkg.

* Thu Dec 29 2011 Steven Shiau <steven _at_ nchc org tw> 2.4.32-1drbl
- Precise was added as a support version in create-ubuntu-live.

* Thu Dec 29 2011 Steven Shiau <steven _at_ nchc org tw> 2.4.31-1drbl
- Overlayfs was added as memory disk in prep-ocsroot.

* Thu Dec 22 2011 Steven Shiau <steven _at_ nchc org tw> 2.4.30-1drbl
- Minor update for the prompt message in ocs-update-syslinux.

* Thu Dec 22 2011 Steven Shiau <steven _at_ nchc org tw> 2.4.29-1drbl
- A better method to update syslinux related files on restored partition was implemented in ocs-update-syslinux. This should make the restored VMWare ESXi 5 bootable.

* Wed Dec 21 2011 Steven Shiau <steven _at_ nchc org tw> 2.4.28-1drbl
- Bug fixed: grub2 boot menu background for EFI booting of DRBL live was added.
- Minor typo fixed when restoring an image.

* Tue Dec 20 2011 Steven Shiau <steven _at_ nchc org tw> 2.4.27-1drbl
- Package grandr was replaced by lxrandr in DRBL live since it's no more in Debian repository for i386.
- If xfce4 display setting program is found in DRBL live, use it for desktop icon app instead of lxrandr.

* Tue Dec 20 2011 Steven Shiau <steven _at_ nchc org tw> 2.4.26-1drbl
- Bug fixed: if block should not be nothing in create-drbl-live.

* Tue Dec 20 2011 Steven Shiau <steven _at_ nchc org tw> 2.4.25-1drbl
- Bug fixed: no grub2 boot menu for EFI booting of DRBL live.

* Tue Dec 20 2011 Steven Shiau <steven _at_ nchc org tw> 2.4.24-1drbl
- Bug fixed: some files were not copied to systems during gparted-live-hook.

* Tue Dec 20 2011 Steven Shiau <steven _at_ nchc org tw> 2.4.23-1drbl
- Files gl-mountstick.sh, resize-windows.txt and gl-packages were removed since they are not used in GParted live anymore.
- Packages pppoeconf, ethtool, whiptail and lshw were added for GParted live.
- Program gl-live-netcfg was added to make it easier for users to configure network.
- Minor improvement for ocs-live-netcfg.

* Sun Dec 18 2011 Steven Shiau <steven _at_ nchc org tw> 2.4.22-1drbl
- File grandr.xpm was renamed as lxrandr.xpm.

* Sat Dec 17 2011 Steven Shiau <steven _at_ nchc org tw> 2.4.21-1drbl
- Package grandr was replaced by lxrandr in GParted live since it's no more in Debian repository for i386.
- An icon on desktop for dillo was added for GParted live.
- Package netbase was added in GParted live.
- The fluxbox menu for GParted live was updated.

* Sat Dec 03 2011 Steven Shiau <steven _at_ nchc org tw> 2.4.20-1drbl
- The font color of grub2 for Clonezilla live was changed.
- Bug fixed: the option "-g auto" failed for restored OS Fedora 16 has been fixed. It's due to different grub2 boot dir (/boot/grub2 instead of /boot/grub).
- Switch to include grub-pc (grub2) instead of grub-legacy (grub1) for Debian-based Clonezilla/DRBL/GParted live.

* Wed Nov 30 2011 Steven Shiau <steven _at_ nchc org tw> 2.4.19-1drbl
- Option -z7|--lrzip-compress was added for Clonezilla to use lrzip to compress image.

* Thu Nov 10 2011 Steven Shiau <steven _at_ nchc org tw> 2.4.18-1drbl
- Program ocs-onthefly was improved to make the destination disk info more clear.

* Thu Nov 10 2011 Steven Shiau <steven _at_ nchc org tw> 2.4.17-1drbl
- Parameter job_before_quit was added for functions confirm_continue_no_default_answer and confirm_continue_or_default_quit in ocs-functions.
- Program ocs-onthefly was improved to give better info before starting cloning and repartitioning the disk. 
- An option "-pa|--postaction" was added to ocs-onthefly so it could be assigned to reboot or shutdown the machine after cloning. Thanks to flyfoxuk for this idea.

* Mon Nov 07 2011 Steven Shiau <steven _at_ nchc org tw> 2.4.16-1drbl
- Before creating partition table on the destination disk, Clonezilla will check if the size is big enough. If not, quit.
- Besides the *.c32 and *.bin files, those *.com and memdisk will be updated by ocs-update-syslinux.

* Mon Nov 07 2011 Steven Shiau <steven _at_ nchc org tw> 2.4.15-1drbl
- The output log for each disk creating will be in /tmp/ when running ocs-restore-mdisks.
- By default we do not separate fdisk actions in ocs-restore-mdisks.

* Sun Nov 06 2011 Steven Shiau <steven _at_ nchc org tw> 2.4.14-1drbl
- Use function get_sort_V_opt in ocs-tux-postprocess.
- A program "ocs-update-syslinux" to update syslinux and its related files on a FAT partition was added.
- An option "-ius|--ius" was added to ocs-sr and ocs-onthefly so that we can skip updating syslinux after restoring. By default it will be done if a FAT partition with ldlinux.sys is found.
- The option to fsck the source partition will be shown in beginner mode of ocs-onthefly.

* Thu Nov 03 2011 Steven Shiau <steven _at_ nchc org tw> 2.4.13-1drbl
- Deprecated files gl-win and gl-info of GParted live were removed. Ref: https://bugzilla.gnome.org/show_bug.cgi?id=662726
- Package dillo was added for GParted live. Ref: https://bugzilla.gnome.org/show_bug.cgi?id=662723
- Use 2 as the gap sectors in ocs-expand-mbr-pt. Otherwise the option "-k1" of clonezilla might create a wrong partition table.

* Wed Nov 02 2011 Steven Shiau <steven _at_ nchc org tw> 2.4.12-1drbl
- Keep the good distance between grandr icon and GParted icon on GParted live desktop.

* Wed Nov 02 2011 Steven Shiau <steven _at_ nchc org tw> 2.4.11-1drbl
- Minor update in the output messages in ocs-functions.
- The deprecated icon "info" on GParted live desktop was removed.

* Mon Oct 31 2011 Steven Shiau <steven _at_ nchc org tw> 2.4.10-1drbl
- Program opoen-iscsi was added in GParted live.
- Timezone info will be shown in the file "clonezilla-img" in the image dir.
- The option -fsck-src-part will be prompted when saving, no matter it's beginner or expert mode.

* Fri Oct 28 2011 Steven Shiau <steven _at_ nchc org tw> 2.4.9-1drbl
- The "ask_user" option was added in the prompt in recovery-iso-zip dialogs.
- Btrfs file system resize was added in ocs-resize-part.

* Sat Oct 22 2011 Steven Shiau <steven _at_ nchc org tw> 2.4.8-1drbl
- A better prompt about destination disks info was added in ocs-restore-mdisks.

* Fri Oct 21 2011 Steven Shiau <steven _at_ nchc org tw> 2.4.7-1drbl
- A function check_if_any_image_exists was added in ocs-functions to identify the clonezilla image. It's used to ocs-sr.
- A file "clonezilla-img" to tag an Clonezilla image was added in the image dir.
- Restore related menu, i.e. restoredisk and restoreparts, will only be shown when images exist in image repository.

* Fri Oct 21 2011 Steven Shiau <steven _at_ nchc org tw> 2.4.6-1drbl
- Function get_part_vol_name should show nothing when no file system on a partition. No any error or warning message should be shown in stdin. 
- Prompt to insert USB device in the beginning of ocs-restore-mdisks.

* Thu Oct 20 2011 Steven Shiau <steven _at_ nchc org tw> 2.4.5-1drbl
- The rerun commands will be saved as a script in /tmp/ when running ocs-restore-mdisks.
- Bug fixed: ocs_user_mode should not be asked twice in ocs-sr -> 1-2-mdisks.

* Thu Oct 20 2011 Steven Shiau <steven _at_ nchc org tw> 2.4.4-1drbl
- Reuse confirm_continue_no_default_answer in ocs-functions.
- Prompt was updated in ocs-restore-mdisks.

* Thu Oct 20 2011 Steven Shiau <steven _at_ nchc org tw> 2.4.3-1drbl
- Function confirm_continue_no_default_answer was added in ocs-functions.
- No default answer to continue in ocs-restore-mdisks.

* Thu Oct 20 2011 Steven Shiau <steven _at_ nchc org tw> 2.4.2-1drbl
- Put "wait" command in the end of ocs-restore-mdisks so it won't enter shell before the jobs are done.
- The converted images by ocs-restore-mdisks are put in /tmp/.

* Thu Oct 20 2011 Steven Shiau <steven _at_ nchc org tw> 2.4.1-1drbl
- Improvement: now we can assign the parameters of ocs-sr in ocs-restore-mdisks.
- The mode "1-2-mdisks" (one image to be restored to multiple disks) was added in Clonezilla main menu.

* Thu Oct 20 2011 Steven Shiau <steven _at_ nchc org tw> 2.3.77-1drbl
- Give warning color (yellow) instead of error color (red) when destination disk is the same as source one in cnvt-ocs-dev.
- A program (restore-mdisks) to restore an image to multiple destination disks were added.

* Tue Oct 18 2011 Steven Shiau <steven _at_ nchc org tw> 2.3.76-1drbl
- Bug fixed: dialog failed when volume name containing a white space.

* Tue Oct 18 2011 Steven Shiau <steven _at_ nchc org tw> 2.3.75-1drbl
- The required files of grub2, e.g. fonts file, will also be copied to /EFI/boot in ocs-gen-grub2-efi-bldr.
- The grub.cfg for EFI booting was improved.

* Mon Oct 17 2011 Steven Shiau <steven _at_ nchc org tw> 2.3.74-1drbl
- Set grub_prefux as "/EFI/boot" when running grub-mkimage in program ocs-gen-grub2-efi-bldr. Grub2 module "gfxterm" was added, too.

* Mon Oct 17 2011 Steven Shiau <steven _at_ nchc org tw> 2.3.73-1drbl
- Package cpufrequtils was added in GParted live packages list.
- The volume name of DOS and NTFS partition will be shown before restoring. Thanks to LittleLight Lee <littlelight _at_ gmail com> for this suggestion.

* Sat Oct 15 2011 Steven Shiau <steven _at_ nchc org tw> 2.3.72-1drbl
- Program gl-gen-grub2-efi-bldr was improved to make the bootia32.efi/bootx64.efi work with the partition table of MBR instead of only GPT.

* Sat Oct 15 2011 Steven Shiau <steven _at_ nchc org tw> 2.3.71-1drbl
- Bug fixed: grub.cfg and wallpaper image were not included in the iso version of GParted live.

* Sat Oct 15 2011 Steven Shiau <steven _at_ nchc org tw> 2.3.70-1drbl
- Wallpaper image was added in the EFI grub2 boot menu of GParted live.

* Sat Oct 15 2011 Steven Shiau <steven _at_ nchc org tw> 2.3.69-1drbl
- Wallpaper image was added in the EFI grub2 boot menu of Clonezilla live.

* Fri Oct 14 2011 Steven Shiau <steven _at_ nchc org tw> 2.3.68-1drbl
- Program ocs-gen-grub2-efi-bldr was improved to make the bootia32.efi/bootx64.efi work with the partition table of MBR instead of only GPT.

* Wed Oct 12 2011 Steven Shiau <steven _at_ nchc org tw> 2.3.67-1drbl
- The nfs version 3 option will be specific in prep-ocsroot when mounting a NFS2/3 server. Thanks to darstra for this bug report.

* Tue Oct 11 2011 Steven Shiau <steven _at_ nchc org tw> 2.3.66-1drbl
- A typo in the comment of ocs-live-general was fixed.
- Option "-r" was on by default in ocs-onthefly.

* Mon Oct 03 2011 Steven Shiau <steven _at_ nchc org tw> 2.3.65-1drbl
- The prompt about not to expand the "system reserved partition" is highlighted in ocs-expand-mbr-pt.

* Mon Oct 03 2011 Steven Shiau <steven _at_ nchc org tw> 2.3.64-1drbl
- Version sorting for partitions list will be used if supported in ocs-tux-postprocess.
- Bug fixed: ocs-expand-mbr-pt failed to deal with partition number larger than 10, and the calculation to expand logical drivers was wrong.

* Mon Sep 12 2011 Steven Shiau <steven _at_ nchc org tw> 2.3.63-1drbl
- Bug fixed: Function parse_cmdline_option in gl-functions was improved. Make the parsing for gl_lang="" correct.

* Thu Sep 08 2011 Steven Shiau <steven _at_ nchc org tw> 2.3.62-1drbl
- Function parse_cmdline_option in gl-functions was improved to accept the /proc/cmdline parsed by grub2 1.99. Now it works for 3 cases in /proc/cmdline: E.g. (1) ocs_prerun="sleep 5" (2) ocs_prerun=\"sleep 5\" and (3) "ocs_prerun=sleep 5".

* Wed Aug 31 2011 Steven Shiau <steven _at_ nchc org tw> 2.3.61-1drbl
- More prompts were added about removing Linux udev hardware record.
- Option "-irhr, --irhr" was added in ocs-onthefly. This option allows us to skip removing Linux udev hardware record after a disk is cloned.

* Wed Aug 31 2011 Steven Shiau <steven _at_ nchc org tw> 2.3.60-1drbl
- More prompts were added about removing Linux udev hardware record.

* Wed Aug 31 2011 Steven Shiau <steven _at_ nchc org tw> 2.3.59-1drbl
- Option "-icrc, --icrc" was added in the usage manual of ocs-sr.
- Option "-irhr, --irhr" was added in ocs-sr. This option allows us to skip removing Linux udev hardware record after an image is restored.

* Fri Aug 05 2011 Steven Shiau <steven _at_ nchc org tw> 2.3.58-1drbl
- German language files were added. Thanks to Michael Vinzenz <michael.vinzenz _at_ scalaris com>.

* Wed Jun 27 2011 Steven Shiau <steven _at_ nchc org tw> 2.3.57-1drbl
- Bug fixed: sgdisk failed to reload a GPT table if no inital GPT table on a new disk.

* Wed Jun 27 2011 Steven Shiau <steven _at_ nchc org tw> 2.3.56-1drbl
- Program create-ubuntu-live supports Oneiric now.

* Tue Jun 26 2011 Steven Shiau <steven _at_ nchc org tw> 2.3.55-1drbl
- The URL for GParted project was updated to be "http://gparted.org".

* Thu Jun 23 2011 Steven Shiau <steven _at_ nchc org tw> 2.3.54-1drbl
- Remove the option "-b1024" for pbzip2 since the unit is 100K, -b1024 will use 1024*100K per thread, and this might cause system to crash due to out of memory for multiple cores. Without the option -b, the default value will be used. Thanks to Telligent for the bug report (https://sourceforge.net/tracker/?func=detail&atid=671650&aid=3324096&group_id=115473).

* Thu Jun 23 2011 Steven Shiau <steven _at_ nchc org tw> 2.3.53-1drbl
- Improve the sfdisk failure process.

* Wed Jun 22 2011 Steven Shiau <steven _at_ nchc org tw> 2.3.52-1drbl
- A better method was implemented to check the exit status of sfdisk. Otherwise if the partition table creation goes wrong, the program won't stop.

* Wed Jun 22 2011 Steven Shiau <steven _at_ nchc org tw> 2.3.51-1drbl
- Force to use LC_ALL=C when chroot to run grub-install.

* Sun Jun 19 2011 Steven Shiau <steven _at_ nchc org tw> 2.3.50-1drbl
- Language file pt_BR was added, so the corresponding parts were updated. Thanks to Marcos Pereira da Silva Cruz <marcospcruz _at_ gmail com>.

* Sat Jun 18 2011 Steven Shiau <steven _at_ nchc org tw> 2.3.49-1drbl
- Big fixed: after start over in Clonezilla live, nfs mount won't work.

* Thu Jun 09 2011 Steven Shiau <steven _at_ nchc org tw> 2.3.48-1drbl
- Enable XZ compression for filesystem.squashfs.

* Wed Jun 08 2011 Steven Shiau <steven _at_ nchc org tw> 2.3.47-1drbl
- Program prep-ocsroot was improved to make mounting cifs and sshfs with an account name including white space.

* Mon May 30 2011 Steven Shiau <steven _at_ nchc org tw> 2.3.46-1drbl
- An option (-o|--create-source-tarball) was added to create-ubuntu-live.

* Mon May 30 2011 Steven Shiau <steven _at_ nchc org tw> 2.3.45-1drbl
- Source files list in /var/lib/apt/lists will be removed when clonezilla/drbl/gparted live is created.
- Program create-gparted-live will create EFI booting files, too. 
- An option (-o|--create-source-tarball) was added to create-(debian|drbl|gparted-live).

* Wed May 25 2011 Steven Shiau <steven _at_ nchc org tw> 2.3.44-1drbl
- Bug fixed: create-drbl-live syntax error.

* Tue May 24 2011 Steven Shiau <steven _at_ nchc org tw> 2.3.43-1drbl
- "nomodeset" was added in the ocs-live-boot-menu for vga=normal. It's a must otherwise if KMS is on, vga=normal is useless.
- Package "partimage" was removed from the package list in create-gparted-live. The option "-k" of create-gparted-live can be used to add the packages.

* Tue May 24 2011 Steven Shiau <steven _at_ nchc org tw> 2.3.42-1drbl
- Suppress the error messages when removing /live/image dir. In some cases it should not be removed.

* Mon May 23 2011 Steven Shiau <steven _at_ nchc org tw> 2.3.41-1drbl
- Bug fixed: syslinux/isolinux files did not exist in /opt/drbl/pkg/syslinux, and this made recovery-iso-zip fail. Thanks to cbeazer for this bug report.

* Sun May 15 2011 Steven Shiau <steven _at_ nchc org tw> 2.3.40-1drbl
- Use XZ initrd for DRBL and GParted live, too.
- Mlterm was replaced by lxterminal in GParted live, since lxterminal is smaller, and be used in many distributions.
- Ssh service in GParted live is off by default.

* Thu May 12 2011 Steven Shiau <steven _at_ nchc org tw> 2.3.39-1drbl
- When kernel supports XZ initrd, we use it in Clonezilla/DRBL/GParted live.

* Tue May 10 2011 Steven Shiau <steven _at_ nchc org tw> 2.3.38-1drbl
- The option "-comp xz -Xbcj x86" was used for mksquashfs when creating Natty-based Clonezilla live. This xz compression instead of gzip method made the Clonezilla live iso or zip file smaller by ~ 33 MB.

* Tue May 10 2011 Steven Shiau <steven _at_ nchc org tw> 2.3.37-1drbl
- Package ssh added in create-gparted-live.
- Put wheezy in ocs-functions for create-*-live.
- The tmp dir /tmp/ocs-iso.* will be cleaned after use.
- Program create-debian-live was improved so that the amd64 image can be created on an i386 Debian server, and vice versa.

* Fri May 06 2011 Steven Shiau <steven _at_ nchc org tw> 2.3.36-1drbl
- The syslinux.exe should be the same version with that in isolinux in Clonezilla|DRBL|GParted live.

* Thu May 05 2011 Steven Shiau <steven _at_ nchc org tw> 2.3.35-1drbl
- Reverted to use live-initramfs, not live-boot, in lb_config of create-ubuntu-live.

* Wed May 04 2011 Steven Shiau <steven _at_ nchc org tw> 2.3.34-1drbl
- Use live-boot instead of live-initramfs for lb_config in create-(debian|drbl|gparted|ubuntu)-live.

* Wed May 04 2011 Steven Shiau <steven _at_ nchc org tw> 2.3.33-1drbl
- Put wheezy in create-(debian|drbl|gparted)-live.

* Tue May 03 2011 Steven Shiau <steven _at_ nchc org tw> 2.3.32-1drbl
- ocs-sr --help will show some more options about saving an image. (https://sourceforge.net/tracker/?func=detail&atid=671650&aid=3295392&group_id=115473).

* Mon May 02 2011 Steven Shiau <steven _at_ nchc org tw> 2.3.31-1drbl
- Output messages of ocs-chkimg were improved with the image name shown.

* Fri Apr 29 2011 Steven Shiau <steven _at_ nchc org tw> 2.3.30-1drbl
- Bug fixed: The last action in live-config is umountfs, not login in live-config 2.0.15-drbl1. Therefore /etc/ocs/ocs-live.d/S00ocs-start was modified (Ubuntu-based Clonezilla live).
- Bug fixed: halt should not be run before live-boot in Ubuntu-based Clonezilla live.

* Thu Apr 28 2011 Steven Shiau <steven _at_ nchc org tw> 2.3.29-1drbl
- Function parse_cmdline_option of gl-functions was updated to allow "@" because it is required by sshfs.

* Thu Apr 28 2011 Steven Shiau <steven _at_ nchc org tw> 2.3.28-1drbl
- To avoid the postrun won't be run, "set -e" was removed in ocs-live-run-menu.

* Wed Apr 27 2011 Steven Shiau <steven _at_ nchc org tw> 2.3.27-1drbl
- Suppress the error messages if no K* service in stop-drbl-live and stop-ocs-live.

* Wed Apr 27 2011 Steven Shiau <steven _at_ nchc org tw> 2.3.26-1drbl
- The pre-run and post-run of Clonezilla live were moved from the service in rc2.d to the shell after login. This would allow interactive command work (e.g. sshfs mount with password input).

* Thu Apr 21 2011 Steven Shiau <steven _at_ nchc org tw> 2.3.25-1drbl
- Since the issue of "hang on exit" of jfbterm has been fixed, we turn on jfbterm in Ubuntu-based Clonezilla live.

* Wed Apr 20 2011 Steven Shiau <steven _at_ nchc org tw> 2.3.24-1drbl
- Bug fixed: no grub.cfg was created.

* Wed Apr 20 2011 Steven Shiau <steven _at_ nchc org tw> 2.3.23-1drbl
- "ntfs" module was added for grub EFI boot loader.
- When an empty bootia32.efi or bootx64.efi is created, it should be removed.
- Only grub.cfg will be used for EFI booting, no more bootia32.conf and bootx86.conf.

* Tue Apr 19 2011 Steven Shiau <steven _at_ nchc org tw> 2.3.22-1drbl
- Disable the background photo for grub efi in Clonezilla live.

* Tue Apr 19 2011 Steven Shiau <steven _at_ nchc org tw> 2.3.21-1drbl
- "png" module was added for grub EFI boot loader.
- Rename the dir /EFI/BOOT/ as /EFI/boot/, and add the grub efi config file grub.cfg.

* Tue Apr 19 2011 Steven Shiau <steven _at_ nchc org tw> 2.3.20-1drbl
- EFI is included in the Clonezilla live now.

* Tue Apr 19 2011 Steven Shiau <steven _at_ nchc org tw> 2.3.19-1drbl
- Bug fixed: EFI/BOOT should not be inside filesystem.squashfs.

* Tue Apr 19 2011 Steven Shiau <steven _at_ nchc org tw> 2.3.18-1drbl
- "toram=filesystem.squashfs" was added for locales menu in ocs-live-boot-menu.
- The "gPXE" part is replaced by "iPXE".
- A better method to download unifont.bgf was implemented in ocs-live-hook.
- The grub2 boot loader for EFI was added.
- "unifont.bgf" part in create-gparted-live was removed, since we do not use it anymore.

* Thu Apr 14 2011 Steven Shiau <steven _at_ nchc org tw> 2.3.17-1drbl
- An workaround was added to make unfs3 work with nfs-common which is started first in drbl live.

* Thu Apr 14 2011 Steven Shiau <steven _at_ nchc org tw> 2.3.16-1drbl
- Put canonical_hostname_prep before check_portmap_nfs_common_daemon is run in prep-ocsroot, otherwise the rpcbind and unfs3 won't work correctly.

* Thu Apr 14 2011 Steven Shiau <steven _at_ nchc org tw> 2.3.15-1drbl
- "jfbterm" instead of "bterm" is used when asking VGA config in DRBL live.

* Thu Apr 14 2011 Steven Shiau <steven _at_ nchc org tw> 2.3.14-1drbl
- Bug fixed: failed to remove unfs3 service in drbl live hook.

* Thu Apr 14 2011 Steven Shiau <steven _at_ nchc org tw> 2.3.13-1drbl
- "insserv", if found, is used to remove service in ocs-live-hook-functions
- "jfbterm" instead of "bterm" is used when asking language and keymap in DRBL live.
- "unfs3" service should be removed in drbl live hook.

* Wed Apr 13 2011 Steven Shiau <steven _at_ nchc org tw> 2.3.12-1drbl
- The sigle service in /etc/rc1.d of Debian DRBL clients is force to S99single.

* Tue Apr 12 2011 Steven Shiau <steven _at_ nchc org tw> 2.3.11-1drbl
- Force to use LC_ALL=C in the mount command of prep-ocsroot. A workaround to avoid sshfs "Read: connection reset by peer" or "remote host has disconnected" issue. Thanks to Greg Trounson <gregt _at_ maths otago ac nz> for reporting this issue and providing testing environment.

* Mon Apr 11 2011 Steven Shiau <steven _at_ nchc org tw> 2.3.10-1drbl
- NFS option "nofsc" was removed from drbl live, since it does not solve the "Stale NFS file handle" issue in drbl live.

* Mon Apr 11 2011 Steven Shiau <steven _at_ nchc org tw> 2.3.9-1drbl
- Spec file was updated for the corresponding source tarball. 

* Thu Apr 07 2011 Steven Shiau <steven _at_ nchc org tw> 2.3.8-31
- "nofsc" instead of "noac" was used for DRBL live clients.

* Wed Apr 06 2011 Steven Shiau <steven _at_ nchc org tw> 2.3.8-30
- "noac" was added in udhcpc-post and init.drbl for DRBL live.

* Wed Apr 06 2011 Steven Shiau <steven _at_ nchc org tw> 2.3.8-29
- Package mlterm was replaced by xfce4-terminal in create-drbl-live-by-pkg.
- "noac" wad added to workaround the unfs3 "Stale NFS file handle" in DRBL live.
- The workaround method "sync_and_active_exec_files" in ocs-functinos was disabled.

* Wed Apr 06 2011 Steven Shiau <steven _at_ nchc org tw> 2.3.8-28
- A typo (Mouting) in prep-ocsroot was fixed.
- Required hal service was removed from "start-drbl-live" and "stop-drbl-live" in drbl-live. Since now hal is no more a service.

* Mon Apr 04 2011 Steven Shiau <steven _at_ nchc org tw> 2.3.8-27
- Either portmap or rpcbind service will be started in prep-ocsroot.

* Sun Apr 03 2011 Steven Shiau <steven _at_ nchc org tw> 2.3.8-26
- "Requires" in clonezilla.spec file was updated.

* Sat Apr 02 2011 Steven Shiau <steven _at_ nchc org tw> 2.3.8-25
- "Requires" in clonezilla.spec file was updated.

* Sun Mar 27 2011 Steven Shiau <steven _at_ nchc org tw> 2.3.8-24
- Revert to use boot parameter "nomodeset", otherwise KMS will take effect, and the framebuffer mode parameter (vga=788...) will be ended. Thanks to NJ_Dude for reporting this issue.

* Fri Mar 25 2011 Steven Shiau <steven _at_ nchc org tw> 2.3.8-23
- The default boot parameter "nomodeset" was removed from Clonezilla live.

* Wed Mar 23 2011 Steven Shiau <steven _at_ nchc org tw> 2.3.8-22
- The existing image dir will only be removed after the first confirmation, not before it.
- Bug fixed: the grep segfault when checking unknown file system if supported by partclone.
- Perl temp file (e.g. .nfs0000000096af2bf70000000f) existing in image dir is avoided.

* Sun Mar 20 2011 Steven Shiau <steven _at_ nchc org tw> 2.3.8-21
- Function get_bsd_swap_partition in ocs-functions was improved to process multiple BSD slices.
- The partitions list are not sorted any more in the function get_known_partition_proc_format in ocs-functions.
- Program ocs-get-part-info was improved to tell ufs partition and BSD slice.
- Program dd is used to save BSD slice info. This will avoid duplicating save for BSD slice and the 1st partition inside it.

* Wed Mar 16 2011 Steven Shiau <steven _at_ nchc org tw> 2.3.8-20
- Typo fixed: The term "slice" and "partition" of BSD system in ocs-functions and ocs-chkimg were not used correctly.

* Sun Mar 13 2011 Steven Shiau <steven _at_ nchc org tw> 2.3.8-19
- The mechanism to skip the vmkcore of BSD swap slice was improved.

* Sat Mar 12 2011 Steven Shiau <steven _at_ nchc org tw> 2.3.8-18
- Typo fixed: -uS instead of -us for sfdisk in function get_bsd_swap_slice.

* Sat Mar 12 2011 Steven Shiau <steven _at_ nchc org tw> 2.3.8-17
- The function get_bsd_swap_slice was added in ocs-functions.
- Program ocs-chkimg will skip checking BSD swap slice, since there is no need to do that, and the false alarm can be ignored.

* Fri Mar 11 2011 Steven Shiau <steven _at_ nchc org tw> 2.3.8-16
- The mechanism to inform kernel the partition table change was improved. This makes the FreeBSD slices restoring work.
- Program get-latest-ocs-live-ver was improved to sort and get only one output.
- The function get_part_id_from_sf_format was added in ocs-functions.
- Program ocs-chkimg was improved to skip checking VMware VMKCORE partition, since there is no need to do that, and the false alarm can be ignored.
- Some of the settings of ocs-onthefly were moved to drbl-ocs.conf.
- By default we use partclone.dd to replace dd in ocs now. A flag was added in drbl-ocs.conf so it can be switched easily.

* Wed Mar 09 2011 Steven Shiau <steven _at_ nchc org tw> 2.3.8-15
- Package mkswap-uuid was removed from Requires. Since modern mkswap has supported that.

* Sat Mar 05 2011 Steven Shiau <steven _at_ nchc org tw> 2.3.8-14
- Recompiled, since deb are not the same versin.

* Sat Mar 05 2011 Steven Shiau <steven _at_ nchc org tw> 2.3.8-13
- Change the dependence as ntfsprogs instead of drbl-ntfsprogs.

* Fri Mar 04 2011 Steven Shiau <steven _at_ nchc org tw> 2.3.8-12
- Highlight description about the disk and partition info before writing GPT/MBR partition table.
- The GPT file saved by sgdisk will be checked in ocs-chkimg.
- Now Clonezilla requires partimage, no more drbl-partimage.

* Wed Mar 02 2011 Steven Shiau <steven _at_ nchc org tw> 2.3.8-11
- By default, sgdisk is used for GPT in ocs-onthefly.

* Tue Mar 01 2011 Steven Shiau <steven _at_ nchc org tw> 2.3.8-10
- Option "-batch" instead of "-b" in ocs-sr and ocs-onthefly is used by default. This will avoid the problem when using in the boot prameters, init will honor it.

* Mon Feb 28 2011 Steven Shiau <steven _at_ nchc org tw> 2.3.8-9
- Package xserver-xorg was listed as a must in create-gparted-live.
- Bug fixed: a workaround was added to make setxkbmap work.

* Mon Feb 28 2011 Steven Shiau <steven _at_ nchc org tw> 2.3.8-8
- Bug fixed: ocs-get-part-info failed to remove temp file in /tmp.

* Sun Feb 27 2011 Steven Shiau <steven _at_ nchc org tw> 2.3.8-7
- Program gdisk was used to save and restore GPT partition table.

* Wed Feb 23 2011 Steven Shiau <steven _at_ nchc org tw> 2.3.8-6
- ocs-chnthn and ocs-chnthn-functions were improved by Ceasar Sun.

* Sun Feb 20 2011 Steven Shiau <steven _at_ nchc org tw> 2.3.8-5
- Bug fixed: Cannot skip "Check image" was fixed. Thanks to nj-dude for reporting this bug.

* Sat Feb 19 2011 Steven Shiau <steven _at_ nchc org tw> 2.3.8-4
- A prompt was added, and it is about not checking swap info when the image is for a whole disk in ocs-chkimg.

* Fri Feb 18 2011 Steven Shiau <steven _at_ nchc org tw> 2.3.8-3
- The name of the cheked image is shown after the image is checked.

* Fri Feb 18 2011 Steven Shiau <steven _at_ nchc org tw> 2.3.8-2
- A variable typo fixed in ocs-chkimg.

* Fri Feb 18 2011 Steven Shiau <steven _at_ nchc org tw> 2.3.8-1
- When an image is saved, an option to run ocs-chkimg was added.
- An option to check if the image is restorable was added in the wizard.
- The image time info format shown on the dialog menu is improved.

* Wed Feb 16 2011 Steven Shiau <steven _at_ nchc org tw> 2.3.7-71
- A mode "check" was added in get_existing_partitions_from_img of ocs-functions.
- Program ocs-chkimg was added. It can be used to check the image of Clonezilla.

* Thu Feb 10 2011 Steven Shiau <steven _at_ nchc org tw> 2.3.7-70
- Minor prompt update in ocs-resize-part.
- Minor note was added in ocs-live-hook-functions.

* Sun Feb 06 2011 Steven Shiau <steven _at_ nchc org tw> 2.3.7-69
- The virtual block device (/dev/vd[a-z]) support was added. Thanks to Cyril Roos for providing patch.
- Bug fixed: failing to use ntfs-3g to mount ntfs file system in ocs-chnthn.

* Sat Feb 05 2011 Steven Shiau <steven _at_ nchc org tw> 2.3.7-68
- Option "noatime" and "nodiratime" are used when mounting file system in prep-ocsroot. Thanks to Petr for this suggestion.

* Fri Feb 04 2011 Steven Shiau <steven _at_ nchc org tw> 2.3.7-67
- If error occurs, program ocs-onthefly will show errors in red and wait for key input then continue.
- The previous generated iso will be cleaned before a new one is created again in ocs-iso.

* Sat Jan 29 2011 Steven Shiau <steven _at_ nchc org tw> 2.3.7-66
- Use "Default-Stop 0 6" for stop-ocs-live and start-drbl-live services.

* Thu Jan 27 2011 Steven Shiau <steven _at_ nchc org tw> 2.3.7-65
- A new boot parameter "ocs_postrun" was added for Clonezilla live and DRBL live.

* Sun Jan 16 2011 Steven Shiau <steven _at_ nchc org tw> 2.3.7-64
- An example IP address instead of real IP address got from the machine was used in the drbl-live-hook, because the real one is useless and it will be automatically updated when DRBL live is booted on the server machine.

* Sat Jan 15 2011 Steven Shiau <steven _at_ nchc org tw> 2.3.7-63
- Bug fixed: start-stop-daemon in DRBL live was not real one.

* Wed Jan 12 2011 Steven Shiau <steven _at_ nchc org tw> 2.3.7-62
- An option -s|--server-ip was added to drbl-ocs-live-prep.

* Sun Jan 09 2011 Steven Shiau <steven _at_ nchc org tw> 2.3.7-61
- Use Clonezilla live as the clonezilla-related OS in drbl live.
- Bug fixed: drbl-ocs-live-prep failed to remove the tmp dir.

* Fri Jan 07 2011 Steven Shiau <steven _at_ nchc org tw> 2.3.7-60
- Program create-gparted-live was modified to put the correct background file for isolinux.
- Bug fixed: "ocs-live-dev -s -d /dev/sda1" failed to copy files to the ouput dev (/dev/sda1), it was using files linked. Thanks to Asou Y.S. Chang for this bug report.
- An option -d|--dark-bg was added for ocs-live-boot-menu.

* Wed Jan 05 2011 Steven Shiau <steven _at_ nchc org tw> 2.3.7-59
- Gsplash.png was updated. Thanks to Linda Temple and Curtis Gedak.

* Sat Dec 25 2010 Steven Shiau <steven _at_ nchc org tw> 2.3.7-58
- The function exclude_umount_live_mnt_point_in_umountfs is obsolete. We let live-config to do this. Ref: http://lists.debian.org/debian-live/2010/12/msg00191.html

* Thu Dec 23 2010 Steven Shiau <steven _at_ nchc org tw> 2.3.7-57
- Bug fixed: Force to unmount image repository before rebooting/shutdowning Clonezilla live. Thanks to Manuel Borchers for reporting this.

* Sat Dec 18 2010 Steven Shiau <steven _at_ nchc org tw> 2.3.7-56
- Bug fixed: only -q1 was added, no -q, -q2 in ocs-onthefly.

* Fri Dec 17 2010 Steven Shiau <steven _at_ nchc org tw> 2.3.7-55
- Option to force to do sector by sector copy for ocs-onthefly was added.

* Thu Dec 16 2010 Steven Shiau <steven _at_ nchc org tw> 2.3.7-54
- Two variables were added in drbl-ocs.conf: ocs_live_username & ocs_live_passwd. They will be used to send the command to Clonezilla live clients of Clonezilla SE.

* Wed Dec 15 2010 Steven Shiau <steven _at_ nchc org tw> 2.3.7-53
- Bug fixed: If no Clonezilla live section is found in pxelinux config file, we should not add or remove the options.
- GParted icon gparted.xpm was updated.

* Mon Dec 13 2010 Steven Shiau <steven _at_ nchc org tw> 2.3.7-52
- An option to use alternative Clonezilla live was added in drbl-ocs-live-prep.

* Sun Dec 12 2010 Steven Shiau <steven _at_ nchc org tw> 2.3.7-51
- Package mount-gtk was removed in GParted live. It can not be used to mount the device by selection, one still has to know the device name.

* Sat Dec 11 2010 Steven Shiau <steven _at_ nchc org tw> 2.3.7-50
- Bug fixed: grub-pc and grub-legacy debs were not put in /root/pkg/grub/.

* Sat Dec 11 2010 Steven Shiau <steven _at_ nchc org tw> 2.3.7-49
- By default we install grub-legacy in GParted live, and put grub-pc and grub-legacy debs in /root/pkg/grub/.

* Thu Dec 09 2010 Steven Shiau <steven _at_ nchc org tw> 2.3.7-48
- Program ocs-langkbdconf-bterm was updated to use drbl-kbdchooser.
- Bug fixed: drbl-ocs failed to find the correct kernel and initrd for Clonezilla live mode in Clonezilla SE.

* Wed Dec 08 2010 Steven Shiau <steven _at_ nchc org tw> 2.3.7-47
- Bug fixed: get-latest-ocs-live-ver failed to get the version from the new HTML layout of sourceforge download page.

* Tue Dec 07 2010 Steven Shiau <steven _at_ nchc org tw> 2.3.7-46
- A more specific message was added for restoring image of partition to different partition device. Thanks to odoyle81 for this.

* Tue Nov 30 2010 Steven Shiau <steven _at_ nchc org tw> 2.3.7-45
- Some minor codes cleanup.

* Tue Nov 30 2010 Steven Shiau <steven _at_ nchc org tw> 2.3.7-44
- A typo fixed in ocs-functions.
- The option "-j2" was not working when using restoreparts. Thanks to dzundam for this bug report.
- Another example custom-ocs-2 was added. It can be used to save and restore dual boot systems.

* Mon Nov 29 2010 Steven Shiau <steven _at_ nchc org tw> 2.3.7-43
- Package hicolor-icon-theme was added in create-gparted-live.

* Thu Nov 25 2010 Steven Shiau <steven _at_ nchc org tw> 2.3.7-42
- Package mount-gtk was added in create-gparted-live.
- Package dhcp*-client* was listed instead of dhcp-client in create-gparted-live.
- Put natty in create-ubuntu-live.

* Sat Nov 06 2010 Steven Shiau <steven _at_ nchc org tw> 2.3.7-41
- Set vga=normal instead of vga=788 in create-gparted-live.

* Fri Nov 05 2010 Steven Shiau <steven _at_ nchc org tw> 2.3.7-40
- Remove boot parameter "nomodeset" in create-gparted-live.

* Sat Oct 30 2010 Steven Shiau <steven _at_ nchc org tw> 2.3.7-39
- The boot parameter ocs_live_extra_param can not be deprecated. We still need that for ocs-live-restore. It's still a better way to separate command options and link the embedded image.
- Program ocs-live-restore was improved to make it allow shutdown the machine when using Clonezilla recovery iso/zip with "-p poweroff".

* Fri Oct 29 2010 Steven Shiau <steven _at_ nchc org tw> 2.3.7-38
- A better mechanism was implemented in ocs-live-run-menu so boot parameter ocs_live_extra_param can be deprecated, i.e. we can put all in a line in boot parameter ocs_live_run.
- Bug fixed: A bug about failing restoring swap parition on GPT disk. Thanks to Bill Marohn <bmarohn _at_ digitiliti com> for this bug report.

* Wed Oct 20 2010 Steven Shiau <steven _at_ nchc org tw> 2.3.7-37
- The files of x11-common won't be removed otherwise the error messages will be shown by startpar during Clonezilla live booting.

* Wed Oct 20 2010 Steven Shiau <steven _at_ nchc org tw> 2.3.7-36
- ocs-live-run-menu will be started only when S99ocs-end is done.

* Fri Oct 15 2010 Steven Shiau <steven _at_ nchc org tw> 2.3.7-35
- More prompts were added in drbl-ocs-live-prep.
- Minor update (prdownloads.sf.net -> downloads.sf.net) in drbl-ocs-live-prep.
- Minor update for create-ubuntu-live.

* Wed Oct 13 2010 Steven Shiau <steven _at_ nchc org tw> 2.3.7-34
- Function parse_cmdline_option in drbl-functions/gl-functions was updated to allow "=" and ",". Thanks to Jacobo Vilella Vilahur for this bug report (https://sourceforge.net/tracker/?func=detail&atid=671650&aid=3081655&group_id=115473).

* Mon Oct 04 2010 Steven Shiau <steven _at_ nchc org tw> 2.3.7-33
- Bug fixed: get-latest-ocs-live-ver was unable to get the latest one.

* Sun Oct 03 2010 Steven Shiau <steven _at_ nchc org tw> 2.3.7-32
- Bug fixed: failed to use the grub deb package in /opt/drbl/pkg/grub.

* Sun Oct 03 2010 Steven Shiau <steven _at_ nchc org tw> 2.3.7-31
- The grub 1 and 2 deb files were moved to /opt/drbl/pkg/grub instead of /root. Otherwise DRBL live client won't have that.

* Sat Oct 02 2010 Steven Shiau <steven _at_ nchc org tw> 2.3.7-30
- A workaround was added to avoid "sed command not found" error in drbl live.

* Thu Sep 30 2010 Steven Shiau <steven _at_ nchc org tw> 2.3.7-29
- Live-build 2.0.0-1 puts "config" instead of "live-config" in the boot parameters, so now "config" will be detected in ocs-functions, too.

* Mon Sep 27 2010 Steven Shiau <steven _at_ nchc org tw> 2.3.7-28
- The private DNS name server won't be built-in in dhcpd.conf when creating drbl live.
- A new boot parameter "ocs_client_no_per_NIC" was added for DRBL live. It is used to assign the DRBL clients' number.
- Bug fixed: ocs-srv-live.sh should detect dhcpd, not only dhcpd3.

* Sat Sep 25 2010 Steven Shiau <steven _at_ nchc org tw> 2.3.7-27
- Now the X will be run as normal login account in GParted live. This is due to the change of live-config, so we follow that.

* Fri Sep 24 2010 Steven Shiau <steven _at_ nchc org tw> 2.3.7-26
- Sudo was added for live-config/scripts/config/012-xinit after booting GParted live.

* Thu Sep 23 2010 Steven Shiau <steven _at_ nchc org tw> 2.3.7-25
- Package name dhcp3-client was replaced by dhcp-client in create-gparted-live.

* Thu Sep 23 2010 Steven Shiau <steven _at_ nchc org tw> 2.3.7-24
- Program etherboot will not be included when creating drbl live (another part).

* Thu Sep 23 2010 Steven Shiau <steven _at_ nchc org tw> 2.3.7-23
- Program etherboot will not be included when creating drbl live.

* Wed Sep 08 2010 Steven Shiau <steven _at_ nchc org tw> 2.3.7-22
- The file system header will be cleaned only when the image of the partition exists. It will not be cleaned before testing existence.
- Program drbl-ocs-live-prep was implemented to use a better way to get the latest stable Clonezilla live iso (get-latest-ocs-live-ver).
- The processes in /ocs/ocs-live.d/ in ubuntu-based clonezilla live will be started only after live-config is done.

* Fri Sep 03 2010 Steven Shiau <steven _at_ nchc org tw> 2.3.7-21
- A program get-latest-ocs-live-ver was added to parse the latest Clonezilla live on the sourceforge repository.
- Use "lb" instead of "lh" since no more "lh" command in live-build 2.0~a25-1 or later.

* Thu Sep 02 2010 Steven Shiau <steven _at_ nchc org tw> 2.3.7-20
- The utils dir is included in GParted live iso file. With this, we can put the files of GParted live iso on an USB stick and make it bootable with some commands.

* Thu Sep 02 2010 Steven Shiau <steven _at_ nchc org tw> 2.3.7-19
- When using the grub2 in the restored OS failed, the plan B (grub2 from Clonezilla live) will be used.

* Wed Sep 01 2010 Steven Shiau <steven _at_ nchc org tw> 2.3.7-18
- Both gl_debug and gl-debug are the same boot parameters for GParted live debug mode.

* Tue Aug 31 2010 Steven Shiau <steven _at_ nchc org tw> 2.3.7-17
- The .xinitrc and .bashrc of GParted live will be created during booting, no more in the live hook.

* Mon Aug 30 2010 Steven Shiau <steven _at_ nchc org tw> 2.3.7-16
- Verbose messages will be shown when using dhclient to lease IP address in Clonezilla live.

* Mon Aug 30 2010 Steven Shiau <steven _at_ nchc org tw> 2.3.7-15
- File system btrfs support was added in drbl-ocs.conf. From partclone 0.2.14 btrfs is supported (experimental). 

* Sun Aug 29 2010 Steven Shiau <steven _at_ nchc org tw> 2.3.7-14
- A better description was added when the image restoring of a partition fails.

* Fri Aug 27 2010 Steven Shiau <steven _at_ nchc org tw> 2.3.7-13
- Small English Grammatical Errors were fixed. Thanks to Mike Taylor (https://sourceforge.net/tracker/?func=detail&atid=671650&aid=3054348&group_id=115473).
- A bug about failing to run batch mode in drbl-ocs was fixed. Thanks to Mike Taylor (https://sourceforge.net/tracker/?func=detail&atid=671650&aid=3054348&group_id=115473).

* Fri Aug 27 2010 Steven Shiau <steven _at_ nchc org tw> 2.3.7-12
- Package usplash and usplash-theme-clonezilla won't be included when creating Debian-based Clonezilla live, since usplash is no more in Sid.

* Thu Aug 26 2010 Steven Shiau <steven _at_ nchc org tw> 2.3.7-11
- Option "--force" was added for grub-install (grub2).
- Russian language file settings were added in ocs-live-hook.conf.

* Thu Aug 19 2010 Steven Shiau <steven _at_ nchc org tw> 2.3.7-10
- Not to force to use the iso-hybrid option when using live-build to create lenny or lucid based clonezilla live.

* Mon Aug 16 2010 Steven Shiau <steven _at_ nchc org tw> 2.3.7-9
- A backup plan for testing lzip image format was added. Thanks to Scaz for this bug report (https://sourceforge.net/tracker/?func=detail&atid=671650&aid=3022428&group_id=115473).
- Force to use the iso-hybrid option for live-build.

* Sun Aug 08 2010 Steven Shiau <steven _at_ nchc org tw> 2.3.7-8
- Make sudo as the required package when creating gparted live. In case it is not included by the live-build.

* Sun Aug 08 2010 Steven Shiau <steven _at_ nchc org tw> 2.3.7-7
- Variable lh_ver_required in drbl-ocs.conf was changed to be "2.0~a19-1drbl". Ready for live-build.

* Fri Aug 06 2010 Steven Shiau <steven _at_ nchc org tw> 2.3.7-6
- A better way to deal with live-config boot parameter was used.

* Thu Aug 05 2010 Steven Shiau <steven _at_ nchc org tw> 2.3.7-5
- "live-config" was added in the boot parameter for the live system so that we can use live-initramfs 2.0.

* Tue Aug 03 2010 Steven Shiau <steven _at_ nchc org tw> 2.3.7-4
- The color of icon fonts was set as red so that they can be shown on new fluxbox in GParted live.

* Sun Aug 01 2010 Steven Shiau <steven _at_ nchc org tw> 2.3.7-3
- Forget about removing dir /usr/share/zoneinfo/ in ocs-live-hook-functions. This might break live-config.

* Wed Jul 28 2010 Steven Shiau <steven _at_ nchc org tw> 2.3.7-2
- Remove the workaround in ocs-functions which converts VMFS_volume_member as vmfs when using blkid to detect the file system.
- File system VMFS_volume_member was added in partclone_support_fs in drbl-ocs.conf.

* Tue Jul 27 2010 Steven Shiau <steven _at_ nchc org tw> 2.3.7-1
- Program ocs-live-dev was improved to save the space and the time when copying files. Thanks to Orgad Shaneh for this idea.
- File system jfs was added in the file system list of partclone in drbl-ocs.conf.

* Tue Jul 20 2010 Steven Shiau <steven _at_ nchc org tw> 2.3.6-43
- Bug fixed: create-drbl-live should not exit if gpxe/drbl-etherboot not installed.

* Sun Jul 18 2010 Steven Shiau <steven _at_ nchc org tw> 2.3.6-42
- S03prep-drbl-clonezilla for drbl-live.d was patched with ocs-live-run-menu started automatically when X not existing in the system. Thanks to Orgad Shaneh for this patch.

* Wed Jun 26 2010 Steven Shiau <steven _at_ nchc org tw> 2.3.6-41
- Bug fixed: an extra shift should not exist in create-gparted-live and create-drbl-by-pkg.

* Sat Jun 26 2010 Steven Shiau <steven _at_ nchc org tw> 2.3.6-40
- Put packages console-data console-setup console-common kbd as the required ones since live-helper changed to depend on keyboard-configuration which is not the one we need.

* Sat Jun 26 2010 Steven Shiau <steven _at_ nchc org tw> 2.3.6-39
- Boot parameter "nomodeset" was added in GParted live.

* Fri Jun 25 2010 Steven Shiau <steven _at_ nchc org tw> 2.3.6-38
- We change client_no_per_NIC to 50 from 100. As some errors were reported by requested by hcj and he can only successfully used DRBL live to multicast restore an image to 50 machines.

* Fri Jun 25 2010 Steven Shiau <steven _at_ nchc org tw> 2.3.6-37
- By default we change client_no_per_NIC to 100 from 40. As requested by hcj and he has successfully used DRBL live to multicast restore an image to 62 machines.

* Wed Jun 23 2010 Steven Shiau <steven _at_ nchc org tw> 2.3.6-36
- Bug fixed: Accidently a charactor was removed in ocs-live-boot-menu in 2.3.6-35.

* Wed Jun 23 2010 Steven Shiau <steven _at_ nchc org tw> 2.3.6-35
- By default "nomodeset" is used in the boot parameters. This will make sure the VGA framebuffer mode is correct.
- Default to use VGA 800x600 for Clonezilla live. Since most of the netbook does not support 1024x768, and 800x600 is the common one for most of the computers, and it's good enough for Clonezilla live. Thanks for swdotnet for suggesting this.

* Tue Jun 22 2010 Steven Shiau <steven _at_ nchc org tw> 2.3.6-34
- Program create-drbl-live-by-pkg was improved with option -c.

* Mon Jun 21 2010 Steven Shiau <steven _at_ nchc org tw> 2.3.6-33
- Packages tango-icon-theme and hicolor-icon-theme were added in the xfce required packages list for drbl live.
- LXDE packages list was added in create-drbl-live-by-pkg (Not finished).

* Mon Jun 21 2010 Steven Shiau <steven _at_ nchc org tw> 2.3.6-32
- Functions get_ocs_live_autologin_account and get_ocs_live_auto_login_id_home were renamed to be get_live_autologin_account and get_live_auto_login_id_home so that they can be used in more general way.
- Variables ocs_live_autologin_account and ocs_live_auto_login_id_home were renamed to be live_autologin_account and live_auto_login_id_home so that they can be used in more general way.
- Files copied to autologin account will be done during booting of DRBL live, no more in drbl-live-hook.
- Parallel start (startpar) was disabled in DRBL live, otherwise gdm will be started before start-drbl-live is done.
- Force to make start-drbl-live run before gdm3, but after dus and hal.

* Fri Jun 18 2010 Steven Shiau <steven _at_ nchc org tw> 2.3.6-31
- More tryes to make service start-drbl-live work in drbl-live.

* Fri Jun 18 2010 Steven Shiau <steven _at_ nchc org tw> 2.3.6-30
- Service start-drbl-live should be started before gdm3 in drbl live.

* Fri Jun 18 2010 Steven Shiau <steven _at_ nchc org tw> 2.3.6-29
- Service start-drbl-live was changed to be started in runlevel 2.

* Thu Jun 17 2010 Steven Shiau <steven _at_ nchc org tw> 2.3.6-28
- Bug fixed: an extra shift should not exist in create-drbl-live. Thanks to Orgad Shaneh for this bug report (http://sourceforge.net/tracker/?func=detail&atid=671650&aid=3016950&group_id=115473).

* Tue Jun 15 2010 Steven Shiau <steven _at_ nchc org tw> 2.3.6-27
- Ubuntu Maverick support was added in create-ubuntu-live.

* Tue Jun 08 2010 Steven Shiau <steven _at_ nchc org tw> 2.3.6-26
- Minor updates in ocs-functions.
- Program prep-ocsroot was improved to work with sshfs/cifs path with space.
- Program ocs-iso is able to create the recovery iso larger than 4.5 GB. Thanks to Zoltan Kerenyi Nagy for reporting this issue.

* Tue Jun 01 2010 Steven Shiau <steven _at_ nchc org tw> 2.3.6-25
- Make start-gparted-live work with innserv.

* Mon May 31 2010 Steven Shiau <steven _at_ nchc org tw> 2.3.6-24
- start-ocs-live and start-drbl-live were improved to work with insserv and upstart.

* Sun May 30 2010 Steven Shiau <steven _at_ nchc org tw> 2.3.6-23
- start-ocs-live and start-drbl-live were improved to work with insserv.

* Sun May 30 2010 Steven Shiau <steven _at_ nchc org tw> 2.3.6-22
- start-ocs-live and start-drbl-live were improved to work with insserv.

* Sun May 30 2010 Steven Shiau <steven _at_ nchc org tw> 2.3.6-21
- S99start-ocs-live was improved to work with insserv.

* Sun May 30 2010 Steven Shiau <steven _at_ nchc org tw> 2.3.6-20
- Bug fixed: Programs ocs-iso and ocs-live-dev were improved to include only Clonezilla-related files. Other files in /live/image/ won't be included.

* Fri May 21 2010 Steven Shiau <steven _at_ nchc org tw> 2.3.6-19
- A workaround function canonical_hostname_prep was used in prep-ocsroot to avoid NFS statd/lockd issue.

* Wed May 19 2010 Steven Shiau <steven _at_ nchc org tw> 2.3.6-18
- Disable the volatile repository when creating clonezilla/drbl/gparted live.

* Mon May 17 2010 Steven Shiau <steven _at_ nchc org tw> 2.3.6-17
- A better mechanism for running vgcfgbackup to save the LVM configuration was implemented. It will avoid triggering NFS lockd.

* Tue May 11 2010 Steven Shiau <steven _at_ nchc org tw> 2.3.6-16
- Boot parameter "nomodeset" was added with vga=normal to avoid using framebuffer mode in safe graphic mode for drbl/clonezilla live.

* Mon May 10 2010 Steven Shiau <steven _at_ nchc org tw> 2.3.6-15
- Due to a problem about lbzip2, we swtich back to use pbzip2 for parallel bzip2 compresstion and decompression.

* Sun May 09 2010 Steven Shiau <steven _at_ nchc org tw> 2.3.6-14
- RPM spec file was updated.

* Wed May 05 2010 Steven Shiau <steven _at_ nchc org tw> 2.3.6-13
- Comments in clone-multiple-usb-example.sh were updated.
- "--language en" was changed as "-l en_US.UTF-8" in ocs-functions.
- Bug fixed: select-in-client mode with Clonezila-live based Clonezilla SE failure was fixed.

* Tue May 04 2010 Steven Shiau <steven _at_ nchc org tw> 2.3.6-12
- '/proc/devices: fopen failed: no such file or directory is device mapper missing from kernel? Clonezilla is done, no error reported.' error in Ubuntu-based clonezilla live was fixed. Thanks to orographic for this bug report.
- Examples were updated in drbl-ocs-live-prep.

* Sun May 02 2010 Steven Shiau <steven _at_ nchc org tw> 2.3.6-11
- The prompt to run ocs-sr command does not need to have double quotation marks ("") in the command options. Remove them to avoid confusing.
- An option -a|--client-arch to assign the CPU arch for Clonezilla SE client was added in drbl-ocs-live-prep.
- drbl-ocs-live-prep supports local clonezilla iso file, and support to use nfsroot when using drbl-SL.sh to deploy Clonezilla live on Clonezilla SE.
- Package discover and dmraid were added in gparted live.

* Thu Apr 29 2010 Steven Shiau <steven _at_ nchc org tw> 2.3.6-10
- Package "discover1" was removed in the packages list in create-gparted-live since it does not exist on Sid/Squeeze. Thanks to Scott Hsiao for this bug report.

* Tue Apr 26 2010 Steven Shiau <steven _at_ nchc org tw> 2.3.6-9
- Functions get_ocs_live_autologin_account and get_ocs_live_auto_login_id_home were added in ocs-functions.
- The exec of ocs-live-run-menu in ~user/.bash_profile will be commented after clonezilla job is done in drbl-ocs-live mode. This will avoid it's run again if just a logout.

* Tue Apr 26 2010 Steven Shiau <steven _at_ nchc org tw> 2.3.6-8
- More boot parameters (vga and video) will be removed in pxelinux config when running dcs to start clonezilla-live based Clonezilla SE service.
- drbl-ocs-live-prep was improved to allow assigning clonezilla live iso URL with command line option.

* Mon Apr 26 2010 Steven Shiau <steven _at_ nchc org tw> 2.3.6-7
- Minor update for the comments in drbl-ocs-live-prep.

* Mon Apr 26 2010 Steven Shiau <steven _at_ nchc org tw> 2.3.6-6
- An variable iso_url_for_pxe_ocs_live was added in drbl-ocs.conf so that clonezilla-live based client works better.
- Program drbl-ocs-live-prep was added so that it's easier to put and configure clonezilla live on DRBL server.
- Modules uvesafb, vesafb and fbcon should not be listed in /etc/modules for Clonezilla live.

* Tue Apr 20 2010 Steven Shiau <steven _at_ nchc org tw> 2.3.6-5
- A prompt message was minor updated in ocs-functions.
- Some preseed values were added in drbl-ocs.conf so that clonezilla-live based client works better.
- Files in /etc/update-motd.d/ of Clonezilla live will be removed to avoid lsb-release pacakge is required. Otherwise ~ 5 MB size will be need.
- Command clear won't be in ~user/.bash_profile (S03prep-drbl-clonezilla) in Clonezilla live if the mode is Clonezilla-live based Clonezilla SE.

* Tue Apr 20 2010 Steven Shiau <steven _at_ nchc org tw> 2.3.6-4
- More config variables were added in drbl-ocs.conf so that clonezilla-live based client works better.

* Mon Apr 19 2010 Steven Shiau <steven _at_ nchc org tw> 2.3.6-3
- Dirs /lib32 and /usr/lib32 will be removed in amd64 version of Clonezilla live. This makes the created file smaller about 30 MB.

* Wed Apr 14 2010 Steven Shiau <steven _at_ nchc org tw> 2.3.6-2
- Bug fixed: ocsmgrd failed to hide the clonezilla live menu after cloning.

* Wed Apr 14 2010 Steven Shiau <steven _at_ nchc org tw> 2.3.6-1
- This release supports Clonezilla-live based client to do clonezilla job.
- Typos in ocs-function were fixed.
- A comment was added in drbl-ocs.
- Variable diskless_client_os was added in drbl-ocs.conf. This will be used as a flag for NFSroot-based or Clonezilla-live-based system in Clonezilla SE.

* Tue Apr 13 2010 Steven Shiau <steven _at_ nchc org tw> 2.3.5-33
- The function to parse boot parameter ocs_server=$IP then notify ocsmgrd was added in ocs-function.

* Mon Apr 12 2010 Steven Shiau <steven _at_ nchc org tw> 2.3.5-32
- Bug fixed: Wrong keymap name for setxkbmap in GParted live.

* Mon Apr 12 2010 Steven Shiau <steven _at_ nchc org tw> 2.3.5-31
- Merge boot parameter gl_kaymap and keyb. Now only "keyb" is required.

* Sun Apr 11 2010 Steven Shiau <steven _at_ nchc org tw> 2.3.5-30
- Gave up - polymouth with framebuffer text mode is still very unstable.
- Bug fixed: service ssh and etc were not disabled for Karmic-based and Lucid-based Clonezilla live.

* Sun Apr 11 2010 Steven Shiau <steven _at_ nchc org tw> 2.3.5-29
- More tests for using polymouth in ubuntu-based Clonezilla live.

* Sun Apr 11 2010 Steven Shiau <steven _at_ nchc org tw> 2.3.5-28
- More tests for using polymouth in ubuntu-based Clonezilla live.

* Sun Apr 11 2010 Steven Shiau <steven _at_ nchc org tw> 2.3.5-27
- More tests for using polymouth in ubuntu-based Clonezilla live.

* Sun Apr 11 2010 Steven Shiau <steven _at_ nchc org tw> 2.3.5-26
- Make polymouth of ubuntu-based Clonezilla live work.

* Sat Apr 03 2010 Steven Shiau <steven _at_ nchc org tw> 2.3.5-25
- Force to sort the partitions list got from /proc/partitions.

* Mon Mar 29 2010 Steven Shiau <steven _at_ nchc org tw> 2.3.5-24
- Bug fixed: Suppress and avoid the error message when getting data from EDD.

* Wed Mar 24 2010 Steven Shiau <steven _at_ nchc org tw> 2.3.5-23
- Bug fixed: Boot parameter keyb should be honored in GParted live.

* Wed Mar 24 2010 Steven Shiau <steven _at_ nchc org tw> 2.3.5-22
- Bug fixed: Boot parameter keyb should be honored in GParted live.

* Tue Mar 16 2010 Steven Shiau <steven _at_ nchc org tw> 2.3.5-21
- Make create-ubuntu-live work with live helper 2.0~a9-1drbl1.

* Mon Mar 15 2010 Steven Shiau <steven _at_ nchc org tw> 2.3.5-20
- Delay umount the Windows partition when removeing hibernation ans page files. since the mounted partition was not aware so fast. This should fix this "partition busy error": https://sourceforge.net/projects/drbl/forums/forum/394007/topic/3559920

* Sat Mar 13 2010 Steven Shiau <steven _at_ nchc org tw> 2.3.5-19
- Delay umount the testing grub partition, since on OpenSuSE 11.2, the mounted ntfs partition was not aware so fast. This should fix this "ntfsfixboot I/O error issue": https://sourceforge.net/projects/drbl/forums/forum/394007/topic/3559920

* Wed Mar 10 2010 Steven Shiau <steven _at_ nchc org tw> 2.3.5-18
- A better file nameing was done for the log files in /var/log/clonezilla/.

* Tue Mar 09 2010 Steven Shiau <steven _at_ nchc org tw> 2.3.5-17
- Bug fixed: extra "=" was added in -quiet and -splash options of ocs-live-boot-menu. Thanks to Orgad Shaneh for this bug report (https://sourceforge.net/tracker/?func=detail&atid=671650&aid=2965604&group_id=115473).
- clonezilla-jobs.log will be put in /var/log/clonezilla/ now, and it will be kept as the file name based on time after the clone job is done.

* Mon Mar 08 2010 Steven Shiau <steven _at_ nchc org tw> 2.3.5-16
- Service "mdadm" will be removed in Ubuntu-based Clonezilla live.

* Mon Mar 08 2010 Steven Shiau <steven _at_ nchc org tw> 2.3.5-15
- Some improvements in the hook scripts when creating clonezilla/drbl live.

* Mon Mar 08 2010 Steven Shiau <steven _at_ nchc org tw> 2.3.5-14
- Using "get_pkg_from_dbn_which_ocs_live_need" was a bad idea. Forget about that.

* Mon Mar 08 2010 Steven Shiau <steven _at_ nchc org tw> 2.3.5-13
- get_pkg_from_dbn_which_ocs_live_need was moved to ocs-live-hook-functions from ocs-functions.
- Bug fixed: we should check if the package available in live hook instead of the running system when creating Clonezilla live.

* Fri Mar 05 2010 Steven Shiau <steven _at_ nchc org tw> 2.3.5-12
- Improve create-ubuntu-live, ocs-cnvt-usb-zip-to-dsk, ocs-iso, ocs-live-dev, create-ocs-tmp-img, ocs-makeboot, create-drbl-live, ocs-onthefly and create-gparted-live to avoid potential "rm -rf" error.
- A function get_pkg_from_dbn_which_ocs_live_need was added to check the packages available for creating drbl/clonezilla live system.

* Wed Mar 03 2010 Steven Shiau <steven _at_ nchc org tw> 2.3.5-11
- Avoid to use "rm -rf" when dealing with temp mount point.

* Mon Mar 01 2010 Steven Shiau <steven _at_ nchc org tw> 2.3.5-10
- Bug fixed: when failing to umount the partition in ocs-rm-win-swap-hib, we should not remove the whoile dir.

* Mon Mar 01 2010 Steven Shiau <steven _at_ nchc org tw> 2.3.5-9
- Bug fixed: boot parameters ocs_sr_save_extra_opt and ocs_sr_restore_extra_opt was not honored by ocs-sr again.

* Mon Mar 01 2010 Steven Shiau <steven _at_ nchc org tw> 2.3.5-8
- Bug fixed: boot parameters ocs_sr_save_extra_opt and ocs_sr_restore_extra_opt was not honored by ocs-sr.

* Sun Feb 28 2010 Steven Shiau <steven _at_ nchc org tw> 2.3.5-7
- Boot parameters ocs_sr_save_extra_opt and ocs_sr_restore_extra_opt will be honored by ocs-sr.

* Sat Feb 27 2010 Steven Shiau <steven _at_ nchc org tw> 2.3.5-6
- Bug fixed: ocsroot_src was not parsed in S03prep-drbl-clonezilla.

* Sat Feb 27 2010 Steven Shiau <steven _at_ nchc org tw> 2.3.5-5
- Boot parameter "ocsroot_src" is honored by clonezilla live.

* Sat Feb 27 2010 Steven Shiau <steven _at_ nchc org tw> 2.3.5-4
- By default we put "nosplash" in the live boot menu.
- Boot parameter "ocs_batch_mode" and "ocs_live_type" are honored by drbl/clonezilla live now.

* Fri Feb 26 2010 Steven Shiau <steven _at_ nchc org tw> 2.3.5-3
- Typos fixed in create-drbl-live and create-gparted-live.
- Bug fixed: boot parameter ocs_se_restore_save_opt should be ocs_se_save_extra_opt.

* Thu Feb 25 2010 Steven Shiau <steven _at_ nchc org tw> 2.3.5-2
- The boot parameter "limit_pxe_drbl_client", which can be "yes" or "no, will honored in drbl live.
- Remove this: In ocs-srv-live.sh we will force dhcp server to lease IP address to PXE or DRBL client. Since it has been done in drbl-live.sh.
- Programs ocs-srv-live.sh, drbl-live.sh, and dcs will load the settings of /etc/ocs/ocs-live.conf if it exists.

* Thu Feb 25 2010 Steven Shiau <steven _at_ nchc org tw> 2.3.5-1
- The complete options added to param_2_be_parsed in drbl-live.d/S03prep-drbl-clonezilla should be: dcs_choose_client ocs_user_mode dcs_input_img_name ocs_postmode dcs_img_vol_limit ocs_se_restore_save_opt dcs_cast_mode dcs_mcast_type ocs_se_restore_extra_opt

* Thu Feb 25 2010 Steven Shiau <steven _at_ nchc org tw> 2.3.4-87
- Program ocs-get-part-info was improved to use partclone.fstype so that vmfs can be detected.

* Thu Feb 25 2010 Steven Shiau <steven _at_ nchc org tw> 2.3.4-86
- In ocs-srv-live.sh we will force dhcp server to lease IP address to PXE or DRBL client.
- The boot parameter "dcs_mcast_type", which can be one of these values: "clients+time-to-wait", "time-to-wait", or "clients-to-wait" will honored in dcs.
- "dcs_choose_client dcs_input_img_name dcs_cast_mode dcs_mcast_type ocs_se_restore_save_opt ocs_se_restore_extra_opt" was added to param_2_be_parsed in drbl-live.d/S03prep-drbl-clonezilla. 

* Thu Feb 25 2010 Steven Shiau <steven _at_ nchc org tw> 2.3.4-85
- Comment the usage assing_default_dns_server in drbl-live-hook since it won't work.

* Thu Feb 25 2010 Steven Shiau <steven _at_ nchc org tw> 2.3.4-84
- Some minor improvements in drbl live so it can be used in an unattended mode.

* Tue Feb 23 2010 Steven Shiau <steven _at_ nchc org tw> 2.3.4-83
- S00ocs-start and S99ocs-end were added in ocs-live.d for tag purpose.

* Tue Feb 23 2010 Steven Shiau <steven _at_ nchc org tw> 2.3.4-82
- Plymouth is not stable in Lucid, and since tehre is no way to use boot parameter to disable it, so force to remove the files of plymouth in the function dirty_hacking_rm_files_for_ocs_live in ocs-live-hook-functions.

* Tue Feb 23 2010 Steven Shiau <steven _at_ nchc org tw> 2.3.4-81
- Instead of setting CRYPTDISKS_ENABLE=No, We just remove the start services of cryptdisks-udev.conf and cryptdisks-enable.conf in Lucid Clonezilla live.

* Tue Feb 23 2010 Steven Shiau <steven _at_ nchc org tw> 2.3.4-80
- Bug fixed: When a partition is mounted after ocs-sr saving started (seldom case), the image files on /home/partimag will be all removed (https://sourceforge.net/tracker/?func=detail&atid=671650&aid=2956592&group_id=115473). Thanks to Chris Cooper for this bug report.

* Mon Feb 22 2010 Steven Shiau <steven _at_ nchc org tw> 2.3.4-79
- A workaround for VMWare ESX grub was added. For grub 1, if grub.conf exists, but menu.lst not, Clonezilla will try to link grub.conf as menu.lst.
- An option "-x" to add boot parameters for drbl live was added in create-drbl-live-by-pkg.

* Mon Feb 22 2010 Steven Shiau <steven _at_ nchc org tw> 2.3.4-78
- VMFS supported is improved. Now it works if the blkid can identify the partition as VMFS_volume_member.

* Sun Feb 21 2010 Steven Shiau <steven _at_ nchc org tw> 2.3.4-77
- Packages usplash and usplash-theme-clonezilla were removed in the packages list in create-ubuntu-live, because in Lucid usplash will conflict with plymouth.
- More files in the packages libcairo2 and ttf-dejavu-core will be removed in the function dirty_hacking_rm_files_for_ocs_live in ocs-live-hook-functions.

* Sat Feb 20 2010 Steven Shiau <steven _at_ nchc org tw> 2.3.4-76
- Bug fixed: create-gparted-live failed to create due to set -e checking.

* Sat Feb 20 2010 Steven Shiau <steven _at_ nchc org tw> 2.3.4-75
- Bug fixed: kernel/net should not be removed in gparted-live-hook otherwise nfs won't be supported.

* Sat Feb 20 2010 Steven Shiau <steven _at_ nchc org tw> 2.3.4-74
- Comment in ocs-functions was updated.
- Due to a output display bug in partclone.dd when restoring, it is not used to save an image. We still use dd to save and restore the image.

* Sat Feb 20 2010 Steven Shiau <steven _at_ nchc org tw> 2.3.4-73
- Disable starting crypto disk in Clonezilla live. Since we won't need on booting and it causes an issue (https://bugs.launchpad.net/puredyne-live/+bug/485858).
- An option -bt|--bootstrap was added to programs create-(ubuntu|debian|gparted|drbl)-live so that cdebootstrap or debootstrap can be selected.

* Thu Feb 18 2010 Steven Shiau <steven _at_ nchc org tw> 2.3.4-72
- An option (-f) was added in create-(debian|gparted|drbl)-live so that we can assign the linux kernel arch.
- lbzip2 was used as a default parallel bzip2 program since pbzip2 1.0.5 has an issue about memory usage.

* Wed Feb 17 2010 Steven Shiau <steven _at_ nchc org tw> 2.3.4-71
- Minor update about the prompt in ocs-resize-part.

* Wed Feb 17 2010 Steven Shiau <steven _at_ nchc org tw> 2.3.4-70
- Function ocs-functions was improved in coding about running partprobe, sfdisk -R.

* Tue Feb 16 2010 Steven Shiau <steven _at_ nchc org tw> 2.3.4-69
- Force to info kernel that the partition table has been changed after partition file system is restored. This makes BSD system restoring work.

* Tue Feb 16 2010 Steven Shiau <steven _at_ nchc org tw> 2.3.4-68
- Filesystem ufs was added in the partclone supported file system in drbl-ocs.conf.

* Tue Feb 16 2010 Steven Shiau <steven _at_ nchc org tw> 2.3.4-67
- Filesystem vmfs was added in the partclone supported file system in drbl-ocs.conf.

* Tue Feb 16 2010 Steven Shiau <steven _at_ nchc org tw> 2.3.4-66
- Lzma compression option was changed to be "-3" by default.
- Option -z5|-z5p (for xz|pxz) and -z6|-z6p (for lzip|plzip) were added in ocs-sr and drbl-ocs.

* Tue Feb 09 2010 Steven Shiau <steven _at_ nchc org tw> 2.3.4-65
- "nosplash" was appended in failsafe mode and safe graphic mode so that Clonezilla usplash won't be started by default. Thanks to tt232474 for this bug report.
- create-debian-live, create-ubuntu-live, create-gparted-live and create-drbl-live were improved to work with live-helper.

* Sat Feb 06 2010 Steven Shiau <steven _at_ nchc org tw> 2.3.4-64
- Bug fixed: ocs-functions was not source in create-debian-live and create-ubuntu-live.

* Sat Feb 06 2010 Steven Shiau <steven _at_ nchc org tw> 2.3.4-63
- A function decide_live_kernel_related_pkgs_from_debian was added in ocs-functions so it can be used commonly in create-{debian,gparted,drbl}-live.

* Wed Feb 03 2010 Steven Shiau <steven _at_ nchc org tw> 2.3.4-62
- Bug fixed: Failed to create clonezilla/gparted/drbl live with squeeze (create-debian-live/create-gparted-live/create-drbl-live).

* Tue Feb 02 2010 Steven Shiau <steven _at_ nchc org tw> 2.3.4-61
- Now both syslinux and isolinux will be included in GParted/DRBL live iso and zip file. This will avoid confusing.

* Wed Jan 27 2010 Steven Shiau <steven _at_ nchc org tw> 2.3.4-60
- A workaround was added in prep-ocsroot to ensure module nfs will be loaded when mounting nfs4 server. 

* Thu Jan 21 2010 Steven Shiau <steven _at_ nchc org tw> 2.3.4-59
- Bug fixed: syslinux should be listed in the exclude list to avoid genisoimage failing due to duplication.

* Thu Jan 21 2010 Steven Shiau <steven _at_ nchc org tw> 2.3.4-58
- "edd=on" was added in boot parameter for Clonezilla live. Thanks to Orgad Shaneh for this suggestion.
- Now both syslinux and isolinux will be included in clonezilla live iso and zip file. This will avoid confusing.

* Sat Jan 16 2010 Steven Shiau <steven _at_ nchc org tw> 2.3.4-57
- A workaround to avoid mountpoint false alram for cifs (https://bugs.launchpad.net/ubuntu/+source/linux/+bug/486667) in prep-ocsroot was added.

* Fri Jan 15 2010 Steven Shiau <steven _at_ nchc org tw> 2.3.4-56
- A workaround in ocs-run to avoid rc-sysinit is started too early in upstart >= 0.6.3.

* Fri Jan 15 2010 Steven Shiau <steven _at_ nchc org tw> 2.3.4-55
- A minor typo in ocs-functions was fixed.

* Thu Dec 31 2009 Steven Shiau <steven _at_ nchc org tw> 2.3.4-54
- Option -k was added in create-drbl-live-by-pkg. A bug about specifying drbl live branch was fixed.

* Wed Dec 30 2009 Steven Shiau <steven _at_ nchc org tw> 2.3.4-53
- Minor updates in ocs-live-run-menu.

* Wed Dec 30 2009 Steven Shiau <steven _at_ nchc org tw> 2.3.4-52
- A typo in ocs-live-hook-functions was fixed.
- Enable cache-indices in create-(debian|drbl|gparted|ubuntu)-live. By doing this, "apt-get upgrade" won't be run in lh_chroot_sources after hook since we might assign older package version when building.

* Wed Dec 30 2009 Steven Shiau <steven _at_ nchc org tw> 2.3.4-51
- Disable the command "apt-get dist-upgrade" in ocs-live-hook. It's not required command.

* Tue Dec 29 2009 Steven Shiau <steven _at_ nchc org tw> 2.3.4-50
- Bug fixed: the 2 instances of ocs_live_run running in tty1 and ttyS0 issue was fixed. Now by default ocs_live_run will only be run on tty1 only. No more both on tty1 and ttyS0. If you want to use ttyS0, for example, add live-getty and console=ttyS0,38400n81 in the boot parameter. Ref: https://sourceforge.net/projects/clonezilla/forums/forum/663168/topic/3499579. Thanks to lukas666 for this bug report.
- If "live-getty console=$tty,38400n81" are assigned in the boot parameters, ocs_live_run_tty will honor $tty, even other value is assigned to ocs_live_run_tty in boot parameter.

* Mon Dec 28 2009 Steven Shiau <steven _at_ nchc org tw> 2.3.4-49
- Commentes were added in ocs-functions.

* Mon Dec 28 2009 Steven Shiau <steven _at_ nchc org tw> 2.3.4-48
- Bug fixed: for the for loop, only when /root/grub*.deb exists we will install it.

* Mon Dec 28 2009 Steven Shiau <steven _at_ nchc org tw> 2.3.4-47
- Bug fixed: failed to download grub 1 deb in ubuntu-based Clonezilla live.

* Mon Dec 28 2009 Steven Shiau <steven _at_ nchc org tw> 2.3.4-46
- Commentes were added in ocs-functions.

* Sun Dec 27 2009 Steven Shiau <steven _at_ nchc org tw> 2.3.4-45
- Commentes were added in drbl-ocs.conf.

* Sun Dec 27 2009 Steven Shiau <steven _at_ nchc org tw> 2.3.4-44
- Variable test_run_grub2_from_restored_os can be assingedn in drbl-ocs.conf.

* Sun Dec 27 2009 Steven Shiau <steven _at_ nchc org tw> 2.3.4-43
- Bug fixed: i386 version of OS running grub-install for the x86-64 restored OS was fixed. Thanks to John Ouzts <jouzts _at_ gmail com> and Lukasz I. <physik _at_ poczta onet pl> for tihs bug report.
- Packages grub-pc and grub-legacy deb will be downloaded and put in /root/ when clonezilla live is created.

* Sat Dec 26 2009 Steven Shiau <steven _at_ nchc org tw> 2.3.4-42
- Upstart files ttyS4 and ttyS4.conf were removed, since most of the computers only have ttyS[0-3].

* Sat Dec 26 2009 Steven Shiau <steven _at_ nchc org tw> 2.3.4-41
- More serial console config files, i.e. ttyS[1-4] were added for Clonezilla live.

* Fri Dec 25 2009 Steven Shiau <steven _at_ nchc org tw> 2.3.4-40
- Typo in S03prep-drbl-clonezilla was fixed.

* Fri Dec 25 2009 Steven Shiau <steven _at_ nchc org tw> 2.3.4-39
- The boot parameter "noswap" was added to Clonezilla live by default.

* Fri Dec 25 2009 Steven Shiau <steven _at_ nchc org tw> 2.3.4-38
- Bug fixed: ocs-live-general should also honor $ocs_live_run_tty.

* Thu Dec 24 2009 Steven Shiau <steven _at_ nchc org tw> 2.3.4-37
- A workaround was added to avoid uvesafb failing to load in Ubuntu 10.04 (alpha) based Clonezilla live.
- A boot parameter ocs_live_run_tty was added so that we can use that to control the ocs_live_run on the specific tty.

* Tue Dec 22 2009 Steven Shiau <steven _at_ nchc org tw> 2.3.4-36
- Bug fixed: Options -gm|--gen-md5sum, -gs|--gen-sha1sum, -cm|--check-md5sum, -cs|--check-sha1sum were not shown in the (ocs-sr|drbl-ocs) --help messages. Thanks to Juergen Chiu for this bug report.

* Sun Dec 20 2009 Steven Shiau <steven _at_ nchc org tw> 2.3.4-35
- Bug fixed: When multicast restoring, swap partition was not recreated. Thanks to username8 for this bug report.

* Mon Dec 14 2009 Steven Shiau <steven _at_ nchc org tw> 2.3.4-34
- Comments were added in ocs-run.

* Mon Dec 14 2009 Steven Shiau <steven _at_ nchc org tw> 2.3.4-33
- Lucid support was added in create-ubuntu-live.

* Wed Dec 09 2009 Steven Shiau <steven _at_ nchc org tw> 2.3.4-32
- Bug fixed: the typo in the workaround to run "mount -a -t nfs" was fixed. Thanks to martinr88 for this bug report.

* Wed Dec 09 2009 Steven Shiau <steven _at_ nchc org tw> 2.3.4-31
- A workaround to avoid upstart bug with NFS (https://bugs.launchpad.net/ubuntu/+source/mountall/+bug/461133) was added in ocs-run.

* Wed Dec 09 2009 Steven Shiau <steven _at_ nchc org tw> 2.3.4-30
- Bug fixed: -o0 was not working for multicast restoring. Thanks to Yung-Jen Yu for this bug report.

* Fri Dec 04 2009 Steven Shiau <steven _at_ nchc org tw> 2.3.4-29
- Package mdadm was added in GParted live packages list.

* Thu Dec 03 2009 Steven Shiau <steven _at_ nchc org tw> 2.3.4-28
- Do not force to remove package gettext-base otherwise grub-related packages will be removed when creating gparted live.

* Wed Nov 25 2009 Steven Shiau <steven _at_ nchc org tw> 2.3.4-27
- Make s19ocs-run to wait for some more secs in Ubuntu 9.10 before clonezilla is run.

* Mon Nov 23 2009 Steven Shiau <steven _at_ nchc org tw> 2.3.4-26
- The created device.map will be removed after grub-install is run.
- Bug fixed: S19ocs-run should wait for udevd to be started before it is run in Ubuntu 9.10. Thanks to jeff-aptimize for this bug report.

* Fri Nov 20 2009 Steven Shiau <steven _at_ nchc org tw> 2.3.4-25
- Package fsarchiver was added in the package lists for GParted live.

* Tue Nov 17 2009 Steven Shiau <steven _at_ nchc org tw> 2.3.4-24
- Bug fixed: For non-interactive mode, we should also unmount LVM and swap partition. Thanks to gsusterman for this bug report (https://sourceforge.net/tracker/?func=detail&atid=671650&aid=2896823&group_id=115473).

* Thu Nov 12 2009 Steven Shiau <steven _at_ nchc org tw> 2.3.4-23
- Programs create-debian-live, create-drbl-live and create-gparted-live work with kernel 2.6.31 of sid now.

* Thu Nov 12 2009 Steven Shiau <steven _at_ nchc org tw> 2.3.4-22
- The lspci results will be saved when saving an image. Thanks to Acty Chen for this idea.

* Sun Nov 08 2009 Steven Shiau <steven _at_ nchc org tw> 2.3.4-21
- An option to ignore CRC checking of partclone was added.

* Thu Nov 05 2009 Steven Shiau <steven _at_ nchc org tw> 2.3.4-20
- By default we use VOL_LIMIT_DEFAULT="1000000" in drbl-ocs.conf.

* Thu Nov 05 2009 Steven Shiau <steven _at_ nchc org tw> 2.3.4-19
- Use "--batch" instead of "-b" and "--no-force-dma-on" instead of "-a"  in the boot parameters of Clonezilla SE's client when running drbl-ocs.
- Bug fixed: To avoid a problem in the /sbin/init from upstart 0.6.3 or later, we do not use VOL_LIMIT_DEFAULT="0" anymore, otherwise it will make the Ubuntu 9.10 shutdown immediately after booting when saving an image.

* Tue Nov 03 2009 Steven Shiau <steven _at_ nchc org tw> 2.3.4-18
- Bug fixed: thunar-volman should not be installed, because it will automatically mount some partitions after a partition table is creataed, then make clonezilla fail to restore a disk image.

* Tue Nov 03 2009 Steven Shiau <steven _at_ nchc org tw> 2.3.4-17
- Bug fixed: Since grub-legacy is used in DRBL live, we should not check if package "grub" is installed or not when running drblsrv-offline in hook.

* Tue Nov 03 2009 Steven Shiau <steven _at_ nchc org tw> 2.3.4-16
- Force to install grub-legacy for Debian Sid or Squeeze in create-drbl-live.

* Tue Nov 03 2009 Steven Shiau <steven _at_ nchc org tw> 2.3.4-15
- Package ipmitool was added in DRBL live (create-drbl-live-by-pkg). Thanks for the suggestion from zug.
- Bug fixed: Typos in the boot menu of GParted live were fixed.

* Mon Nov 02 2009 Steven Shiau <steven _at_ nchc org tw> 2.3.4-14
- By default in uvesafb we use bpp 16 for 640x480/800x600 uvesafb mode, and 32 for 1024x768 mode. This will make it brighter in virtualbox.
- Clonezilla usplash theme is included in ubuntu-based Clonezilla live.
- S07arm-wol was added in Clonezilla live startup so the wake on LAN mode can be on standby.

* Thu Oct 29 2009 Steven Shiau <steven _at_ nchc org tw> 2.3.4-13
- Clonezilla usplash theme is included in Debian-based Clonezilla live.

* Wed Oct 28 2009 Steven Shiau <steven _at_ nchc org tw> 2.3.4-12
- Bug fixed: A bug about using tar to create recovery iso zip was fixed. Thanks to wellurs for this bug report.
- Bug fixed: A bug about scripts in $OCS_PRERUN_DIR won't run was fixed. Thanks to gsusterman for this bug report.
- Bug fixed: A bug about creating recovery iso/zip with images not in /home/partimag not working was fixed. Thanks to dersucker for this bug report.

* Mon Oct 26 2009 Steven Shiau <steven _at_ nchc org tw> 2.3.4-11
- Packages usplash and usplash-theme-debian were added in create-debian-live.

* Mon Oct 26 2009 Steven Shiau <steven _at_ nchc org tw> 2.3.4-10
- Pacakge usplash and usplash-theme-ubuntu were added in create-ubuntu-live. Now we can use "quiet splash" as the boot parameter in Ubuntu-based clonezilla live.
- ocs-live-boot-menu was improved to group some clonezilla modes.
- A workaround to force to add crc32c module for Clonezilla live was added, this is required for bnx2x module.
- Two options (-a, -q) were added in ocs-live-boot-menu so that we can assign "splash" or "quiet" in the boot parameter.

* Wed Oct 21 2009 Steven Shiau <steven _at_ nchc org tw> 2.3.4-9
- Bug fixed: only mountall-net.conf should be disabled in ubuntu-based of Clonezilla live.

* Wed Oct 21 2009 Steven Shiau <steven _at_ nchc org tw> 2.3.4-8
- Bug fixed: mountall.conf and mountall-net.conf should be disabled in ubuntu-based of Clonezilla live.

* Thu Oct 15 2009 Steven Shiau <steven _at_ nchc org tw> 2.3.4-7
- Some more network drivers were added in Clonezilla live initramfs module lists (extra_module_list_in_initramfs="atl1 atl1c atl2 bnx2 bnx2x") in ocs-live-hook.conf. PXE booting Clonezilla live might need that.

* Sun Oct 10 2009 Steven Shiau <steven _at_ nchc org tw> 2.3.4-6
- Minor updates in create-gparted-live.

* Fri Oct 09 2009 Steven Shiau <steven _at_ nchc org tw> 2.3.4-5
- Bug fixed: The account user did not have password in GParted live.

* Thu Oct 08 2009 Steven Shiau <steven _at_ nchc org tw> 2.3.4-4
- Bug fixed: We can not remove /usr/lib/gconv/, since some program, e.g. mtools 4.10 need that in GParted live.

* Thu Oct 08 2009 Steven Shiau <steven _at_ nchc org tw> 2.3.4-3
- gparted-live-hook and drbl-live-hook were updated to include /lib/udev/cdrom_id in the initramfs.

* Mon Oct 05 2009 Steven Shiau <steven _at_ nchc org tw> 2.3.4-2
- Now ubuntu-based Clonezilla live honors the boot parameter like "video=uvesafb:mode_option=1024x768" instead of "mode_option=1024x768" anymore.

* Sun Oct 04 2009 Steven Shiau <steven _at_ nchc org tw> 2.3.4-1
- Make create-debian-live and create-gpated-live work with recent Sid.
- Force to use grub-legacy when creating Clonezilla live with Sid or Squeeze.
- The program create-ubuntu-live now uses live-ubuntu-(stable|testing|unstable|experimental) branches from drbl-core instead of live-(stable|testing|unstable|experimental).
- No more creating /etc/modprobe.d/options before running "modprobe uvesafb", now we just run "modprobe uvesafb mode_option=..." when entering uvesafb mode in Ubuntu-based Clonezilla live.

* Fri Oct 02 2009 Steven Shiau <steven _at_ nchc org tw> 2.3.3-96
- Variable $ocsroot instead of /home/partimag is used in the sample programs custom-ocs and custom-ocs-1.

* Thu Sep 24 2009 Steven Shiau <steven _at_ nchc org tw> 2.3.3-95
- Sample program custom-ocs and custom-ocs-1 were updated.
- Bug fixed: ocs-iso and ocs-live-dev failed to check if customized file exists or not.

* Fri Sep 18 2009 Steven Shiau <steven _at_ nchc org tw> 2.3.3-94
- File system xfs is turned on in partclone support fs in drbl-ocs.conf.

* Tue Sep 15 2009 Steven Shiau <steven _at_ nchc org tw> 2.3.3-93
- Bug fixed: Partition is not unmounted after grub-install is run.

* Mon Sep 14 2009 Steven Shiau <steven _at_ nchc org tw> 2.3.3-92
- Package gdisk is included in GParted live.
- Make create-debian-live, create-gparted-live and create-drbl-live work with Debian Sid (not fully tested).

* Sat Sep 12 2009 Steven Shiau <steven _at_ nchc org tw> 2.3.3-91
- partclone.xfs is buggy. partimage is now used to save XFS partition.

* Thu Sep 10 2009 Steven Shiau <steven _at_ nchc org tw> 2.3.3-90
- Some better way to deal with upstart <= 0.6.3 or newer version in ocs-live-hook.

* Thu Sep 10 2009 Steven Shiau <steven _at_ nchc org tw> 2.3.3-89
- Comments were added in ocs-live-hook.

* Wed Sep 09 2009 Steven Shiau <steven _at_ nchc org tw> 2.3.3-88
- Bug fixed: Wrong path when append atl2 modules in the initrd1 of clonezilla live.

* Wed Sep 09 2009 Steven Shiau <steven _at_ nchc org tw> 2.3.3-87
- Kernel module "atl2" is included in the initrd1 of Clonezilal live. Thanks to giner for this suggestion. Ref: https://sourceforge.net/tracker/?func=detail&atid=671650&aid=2854969&group_id=115473

* Tue Sep 08 2009 Steven Shiau <steven _at_ nchc org tw> 2.3.3-86
- Forget about removing /tftpboot/node_root/{lib, usr} when creating DRBL live, since squashfs file system will remove duplicated files, so the size make no big differences, and will those dirs kept, the RAM size required should be smaller.

* Mon Sep 07 2009 Steven Shiau <steven _at_ nchc org tw> 2.3.3-85
- When creating DRBL live, remove /tftpboot/node_root/{lib, usr}, since when drblpush is run, they will be rebuild. However, the DRBL server might need more RAM to run it. Thanks to Orgad Shaneh for the inspiration. Ref: https://sourceforge.net/forum/forum.php?thread_id=3336278&forum_id=675794

* Sun Sep 06 2009 Steven Shiau <steven _at_ nchc org tw> 2.3.3-84
- Option "-g auto" will only take effect when the boot loader in the MBR on the disk if found as GRUB. Help messages of "-g auto" is updated, too.

* Fri Sep 04 2009 Steven Shiau <steven _at_ nchc org tw> 2.3.3-83
- Bug fixed: grub failed to be identified as "grub-install.unsupported" in SuSE.
- BUg fixed: Failed to run grub2 from restored OS if the grub partition and root partition is in the same partition.

* Fri Sep 04 2009 Steven Shiau <steven _at_ nchc org tw> 2.3.3-82
- If grub2 is found in the restored OS, Clonezilla will try to use the grub exec program in the restored OS to reinstall it in the MBR.
- Programs ocs-iso and ocs-live-dev were improved, especially to exclude some dirs from template iso/dir in case it will conflict. Thanks to Andrew Bloxom.

* Tue Sep 01 2009 Steven Shiau <steven _at_ nchc org tw> 2.3.3-81
- Keep the fs driver in the kernel when creating GParted live.

* Tue Sep 01 2009 Steven Shiau <steven _at_ nchc org tw> 2.3.3-80
- The module exportfs is required for aufs, therefore we should not remove it when creating GParted live.
- The package xdialog was replaced by zenity (gdialog) since xdialog is no more in squeeze.
- Use function to get Xdialog or gdialog in GParted live.

* Mon Aug 31 2009 Steven Shiau <steven _at_ nchc org tw> 2.3.3-79
- Program create-ubuntu-live now supports Karmic (with live-initramfs 1.157.2-5drbl).
- The option "-g auto" will be skipped when grub2 is found in the restored OS.

* Sun Aug 30 2009 Steven Shiau <steven _at_ nchc org tw> 2.3.3-78
- ttyS0.conf for upstart >= 0.6.3 will be copied in Ubunbu-based Clonezilla live.

* Sun Aug 30 2009 Steven Shiau <steven _at_ nchc org tw> 2.3.3-77
- By default we disable starting open-iscsi service when Clonezilla live boots, since we only need program. 
- The patched rc-sysinit.conf for Ubuntu 9.10's upstart will be applied when creating Ubuntu-based Clonezilla live.

* Fri Aug 28 2009 Steven Shiau <steven _at_ nchc org tw> 2.3.3-76
- Program create-debian-live is ready for squeeze, however, due to the bug http://bugs.debian.org/cgi-bin/bugreport.cgi?bug=539354, no user can be added by live-initramfs during boot, i.e. the created Debian live won't be able to login automatically in the console.

* Fri Aug 28 2009 Steven Shiau <steven _at_ nchc org tw> 2.3.3-75
- Program ocs-iso was improved to print more error messages if something goes wrong.
- By default "-r" option is on for clonezilla.

* Wed Aug 26 2009 Steven Shiau <steven _at_ nchc org tw> 2.3.3-74
- ocs-live-dev will try to use symbolic link instead of copying image to working dir.

* Wed Aug 12 2009 Steven Shiau <steven _at_ nchc org tw> 2.3.3-73
- Bug fixed: Parallel bzip2 was not run with correct parameters.
- Bug fixed: Parallel pigz was not run with correct parameters (-b 1024k is not correct, it's -b 1024).

* Mon Aug 10 2009 Steven Shiau <steven _at_ nchc org tw> 2.3.3-72
- A bug about writting fail-mbr.bin was fixed: https://sourceforge.net/forum/message.php?msg_id=7536248
- An option to mount NFSv4 server was added to prep-ocsroot. Thanks to Ingo for this idea (https://sourceforge.net/tracker/index.php?func=detail&aid=2830283&group_id=115473&atid=671653).
- An option -fsck-src-part|--fsck-src-part was added for ocs-sr, ocs-onthefly and drbl-ocs.
- Parallel decompression by pigz and pbzip2 were added.
- Since the FAT issue in partclone was fixed in version 0.1.1-16, now we use partclone to save or restore FAT partition.

* Mon Jul 27 2009 Steven Shiau <steven _at_ nchc org tw> 2.3.3-71
- Bug fixed: if the hostname of MS windows is on FAT32 partition, ocs-chnthn failed to change that.

* Mon Jul 27 2009 Steven Shiau <steven _at_ nchc org tw> 2.3.3-70
- An issue about checking fuse module for ntfs-3g was fixed in ocs-chnthn-functions. Thanks to Bill Gurley for the bug report.

* Fri Jul 24 2009 Steven Shiau <steven _at_ nchc org tw> 2.3.3-69
- Package vim-tiny was added for GParted live. Thanks to Jojo de Leon for this suggestion.

* Thu Jul 16 2009 Steven Shiau <steven _at_ nchc org tw> 2.3.3-68
- genisoimage instead of mkisofs is used in both create-gparted-live and create-drbl-live. Thanks Orgad Shaneh for this bug report.

* Wed Jul 15 2009 Steven Shiau <steven _at_ nchc org tw> 2.3.3-67
- Because there is an issue when restoring FAT file system by partclone, a workaround to avoid using partclone to save FAT filesystem was added.

* Tue Jul 14 2009 Steven Shiau <steven _at_ nchc org tw> 2.3.3-66
- Feature added: 1st-disk keyword will work for multicast clone, too. Ref: https://sourceforge.net/tracker/?func=detail&atid=671650&aid=2817447&group_id=115473
- Patches from https://sourceforge.net/tracker/?func=detail&atid=671653&aid=2818368&group_id=115473 were applied. Thanks to Orgad Shaneh.
- A typo in the prompt in ocs-onthefly was fixed.
- Package smartmontools was added in GParted live packages lists.

* Wed Jul 01 2009 Steven Shiau <steven _at_ nchc org tw> 2.3.3-65
- An option "--rescue" was added in ocs-onthefly for partclone.

* Wed Jul 01 2009 Steven Shiau <steven _at_ nchc org tw> 2.3.3-64
- Bug fixed: When doing disk to disk clone, swap parititon was not created on the target disk. Thanks to Patrick Verner for reporting this bug.
- Bug fixed: S09config-X for DRBL live failed to use the language setting.

* Tue Jun 30 2009 Steven Shiau <steven _at_ nchc org tw> 2.3.3-63
- A comment was added when disable compcache when creating Clonezilla live.
- Language file is used in the X configuring program in DRBL live.

* Mon Jun 29 2009 Steven Shiau <steven _at_ nchc org tw> 2.3.3-62
- Bug fixed: Ubuntu-based Clonezilla live will show kernel panic in PXE booting in small memory machine. Thanks to Adam Walker for bug report (https://sourceforge.net/support/tracker.php?aid=2813538).

* Sun Jun 28 2009 Steven Shiau <steven _at_ nchc org tw> 2.3.3-61
- Dir utils containing syslinux programs, makeboot.sh, and makeboot.bat were added DRBL live iso file.

* Sat Jun 27 2009 Steven Shiau <steven _at_ nchc org tw> 2.3.3-60
- Bug fixed: ocs-iso failed to create recovery iso in Clonezilla live env. Thanks to wohtohai for this bug report.

* Fri Jun 26 2009 Steven Shiau <steven _at_ nchc org tw> 2.3.3-59
- More prompt was added in ocs-live-dev.

* Fri Jun 26 2009 Steven Shiau <steven _at_ nchc org tw> 2.3.3-58
- Disable the function that LC_ALL and LANG will be kept in /etc/default/locale and /etc/environment when ocs-langkbdconf-bterm is run in Clonezilla live. Since most of the cases, e.g. for Chinese, the terminal won't show the characters, unless it's in bterm/jfbterm.
- Now utils dir (syslinux.exe, syslinux, makeboot.bat and makeboot.sh) is included in Clonezilla live iso file.

* Fri Jun 26 2009 Steven Shiau <steven _at_ nchc org tw> 2.3.3-57
- Clonezilla RPM Spec file was updated to force to depend on drbl >= 1.9.4-41.
- Program ocs-live-dev was improved so it can be run without downloading syslinux if it's run in Clonezilla live environment.

* Fri Jun 26 2009 Steven Shiau <steven _at_ nchc org tw> 2.3.3-56
- Bug fixed: LC_ALL and LANG should be written to /etc/default/locale and /etc/environment by S05kbd-conf, not ocs-langkbdconf-bterm, otherwise if we assign ocs_lang in boot parameter, it won't work. Besides, we do the same thing in S05kbd-conf of Clonezilla live.
- A boot parameter "drbl_live_noconfx" was added so that we can skip configureing X.

* Fri Jun 26 2009 Steven Shiau <steven _at_ nchc org tw> 2.3.3-55
- LC_ALL and LANG will be kept in /etc/default/locale and /etc/environment when ocs-langkbdconf-bterm is run.

* Thu Jun 25 2009 Steven Shiau <steven _at_ nchc org tw> 2.3.3-54
- Bug fixed: The dir /etc/ocs will be created in S03prep-drbl-clonezilla in DRBL live.

* Thu Jun 25 2009 Steven Shiau <steven _at_ nchc org tw> 2.3.3-53
- Bug fixed: ocs-live-bug-report should not be run in non-Clonezilla-live environment.
- The boinc-client is turned off when creating drbl live.
- The custom-ocs function was added in DRBL live, just ad Clonezilla live does. Thanks to Orgad Shaneh. 
- The prompt about broadcast and multicast will be separated. No more using multicast only.
- X config will only be run when X program exists in DRBL live. Thanks to Orgad Shaneh.
- Comments in ocs-functions were updated.
- All the blkid commands now are run with "-c /dev/null" to avoid the cached data.
- Package swfdec-mozilla was added in the packages lists in create-drbl-live-by-pkg.
- The files in drbl-live.d are almost the same with those existing files in ocs-live.d, i.e. we reuse the boot parameters of Clonezilla live. Thanks to Orgad Shaneh for this suggestion.

* Sun Jun 21 2009 Steven Shiau <steven _at_ nchc org tw> 2.3.3-52
- Package xnetcardconfig was added in drbl live packages list.
- VOL_LIMIT_DEFAULT is set as 2000 in drbl live. Thanks to Ming-Kult Tsai for this idea.

* Thu Jun 18 2009 Steven Shiau <steven _at_ nchc org tw> 2.3.3-51
- Bug fixed: Failed to save partition image.

* Wed Jun 17 2009 Steven Shiau <steven _at_ nchc org tw> 2.3.3-50
- When verbose option of clonezilla is on, partclone will use "-d" option.
- Partclone is now run with -L to assing the log file.

* Wed Jun 17 2009 Steven Shiau <steven _at_ nchc org tw> 2.3.3-49
- Package acpi, laptop-detect, acpi-support and hotkey-setup were added in the list in create-drbl-live-by-pkg. Thanks to Louie Chen.

* Tue Jun 16 2009 Steven Shiau <steven _at_ nchc org tw> 2.3.3-48
- The tips and tricks on the startup after logining xfce is disabled now.

* Tue Jun 16 2009 Steven Shiau <steven _at_ nchc org tw> 2.3.3-47
- Program create-drbl-live-by-pkg was polished with more packages included.

* Tue Jun 16 2009 Steven Shiau <steven _at_ nchc org tw> 2.3.3-46
- Bug fixed: Failed to set default mode (640x480) for vesa booting console in DRBL live.

* Mon Jun 15 2009 Steven Shiau <steven _at_ nchc org tw> 2.3.3-45
- gpxe was added in the drbl live boot menu.
- Default to use 640x480 for vesa booting console in DRBL live.

* Mon Jun 15 2009 Steven Shiau <steven _at_ nchc org tw> 2.3.3-44
- Bug fixed: account user passwd not added correctly in drbl-live.

* Mon Jun 15 2009 Steven Shiau <steven _at_ nchc org tw> 2.3.3-43
- "LANG=C" is replaced with "LC_ALL=C" for all the scripts.

* Mon Jun 15 2009 Steven Shiau <steven _at_ nchc org tw> 2.3.3-42
- create-drbl-live-by-pkg was updated to include Japanese fonts.

* Mon Jun 15 2009 Steven Shiau <steven _at_ nchc org tw> 2.3.3-41
- Minor updates for drbl and clonezilla live.

* Mon Jun 15 2009 Steven Shiau <steven _at_ nchc org tw> 2.3.3-40
- Minor updates for drbl live.
- Bug fixed: Failed to run S09config-X in drbl live booting.
- No more language menu shown in syslinux/isolinux boot menus in drbl live.

* Mon Jun 15 2009 Steven Shiau <steven _at_ nchc org tw> 2.3.3-39
- Since jfbterm exits with segfault, we force to use bterm in DRBL live rcS.d when choosing language and keymap.

* Sun Jun 14 2009 Steven Shiau <steven _at_ nchc org tw> 2.3.3-38
- Bug fixed: wrong path for drbl-live.d in drbl-live-hook.

* Sun Jun 14 2009 Steven Shiau <steven _at_ nchc org tw> 2.3.3-37
- A better method to config drbl live when booting was added.

* Sat Jun 13 2009 Steven Shiau <steven _at_ nchc org tw> 2.3.3-36
- Function get_live_boot_param was polished again.
- Typos in ocs-live-hook were fixed.
- An option "-n" was added for command clonezilla.

* Fri Jun 12 2009 Steven Shiau <steven _at_ nchc org tw> 2.3.3-35
- Bug fixed: boot parameter parsing failed in function get_live_boot_param.

* Fri Jun 12 2009 Steven Shiau <steven _at_ nchc org tw> 2.3.3-34
- Sample files were updated about how to run the command to create customized Clonezilla live. Thanks to BGraham.
- Since newer mkswap supports -U, we will use it if this option is found instead of mkswap-uuid.
- A message was added before program clonezilla exit. Thanks to Patrick Verner.
- Bug fixed: boot parameter like "union=unionfs-fuse" was not able to be parsed corectly in function get_live_boot_param.
- Bug fixed: /var/log/partclone.log should not be removed when job is done.

* Mon Jun 08 2009 Steven Shiau <steven _at_ nchc org tw> 2.3.3-33
- Bug fixed: wrong path of fail-mbr.bin.

* Mon Jun 08 2009 Steven Shiau <steven _at_ nchc org tw> 2.3.3-32
- The patch to improve fault tolerance was added (https://sourceforge.net/tracker/?func=detail&atid=671653&aid=2793248&group_id=115473). Thanks to Orgad Shaneh.

* Sun Jun 07 2009 Steven Shiau <steven _at_ nchc org tw> 2.3.3-31
- Bug fixed: parted failed to find the disk size when no partition table, another method was added to get the disk size.
- Bug fixed: if lzma is not available, we should switch to gzip.

* Thu May 28 2009 Steven Shiau <steven _at_ nchc org tw> 2.3.3-30
- Use command name partclone.ntfsfixboot instead of partclone.ntfsreloc.
- Program ocs-live was slightly updated.
- Bug fixed: "nolocales" boot parameter should be assigned by ocs-iso or ocs-live-dev, not in the ocs-live-boot-menu.
- An option for using rescue mode of partclone when saving an image was added.

* Tue May 26 2009 Steven Shiau <steven _at_ nchc org tw> 2.3.3-29
- Function get_live_media_mnt_point in ocs-functions was improved to use flexible quashfs file name instead of fixed one "filesystem.squashfs".

* Tue May 26 2009 Steven Shiau <steven _at_ nchc org tw> 2.3.3-28
- Copyright of year in Clonezilla live boot menu was updated.

* Mon May 25 2009 Steven Shiau <steven _at_ nchc org tw> 2.3.3-27
- Parameters live_media_path_chklist and live_sys_files_dir_list in drbl-ocs.conf were improved.

* Mon May 25 2009 Steven Shiau <steven _at_ nchc org tw> 2.3.3-26
- "clonezilla.org" is used instead of "clonezilla.sourceforge.net" in the boot menu of Clonezilla live.
- The sample file "custom-ocs" was improved to be more flexible. Not only for saving the image to ntfs partition.
- Program ocs-live-general was slightly improved to suppress the error message when /etc/ocs/ocs-live.conf does not existing.
- Boot parameter "toram=filesystem.squashfs" is used for ToRAM option in live.
- Newer partclone is used, which has fixed some minor bugs, and a newer version of ntfsbootfix (was ntfsreloc) is updated.

* Fri May 22 2009 Steven Shiau <steven _at_ nchc org tw> 2.3.3-25
- Applied the patch file for edd_id_map_by_capacity. (https://sourceforge.net/support/tracker.php?aid=2794791). Thanks to Orgad Shaneh. 

* Sun May 17 2009 Steven Shiau <steven _at_ nchc org tw> 2.3.3-24
- Bug fixed: when there is image existing in the recovery Clonezilla live USB, we have remove the link file $ocsroot.

* Sun May 17 2009 Steven Shiau <steven _at_ nchc org tw> 2.3.3-23
- Bug fixed: when there is image existing in the recovery Clonezilla live USB, we do not have to link /live/image/$ocsroot to $ocsroot.
- Function rep_whspc_w_udrsc is used in some files.

* Sat May 09 2009 Steven Shiau <steven _at_ nchc org tw> 2.3.3-22
- Bug fixed: We should only group memtest and freedos when both of them exist in ocs-live-boot-menu.

* Wed May 06 2009 Steven Shiau <steven _at_ nchc org tw> 2.3.3-21
- Function install_grub_hd in ocs-functions was improved. It's easier to understand now.
- The created iso of gparted live and drbl live will be "isohybrided".
- Force to ask inputting y/n option for most of the questions in ocs-onthefly.
- Program ocs-live-bug-report was added so it's easier for user to report bug.

* Mon May 04 2009 Steven Shiau <steven _at_ nchc org tw> 2.3.3-20
- ocs-functions was slightly updated.
- kexec service won't be run by default on DRBL/Clonezilla live. This will suppress the error message when reboot.
- Bug fixed: When doing multicast restoring, grub was not run.
- Bug fixed: --use-partclone-ntfsclone is no more, we should use --use-partclone in drbl-ocs.

* Fri May 01 2009 Steven Shiau <steven _at_ nchc org tw> 2.3.3-19
- Bug fixed: With "-g auto", we should try to find the grub config partition on the restored disk, not all the disk(s) on the system. Otherwise if there are more than 2 disks, grub-install might be skipped.

* Tue Apr 28 2009 Steven Shiau <steven _at_ nchc org tw> 2.3.3-18
- Prompt was polished.
- An option to enter command line to manually configure network settings was added in ocs-live-netcfg.

* Tue Apr 28 2009 Steven Shiau <steven _at_ nchc org tw> 2.3.3-17
- Put save tasks and restore tasks in order. The mode of Clonezilla will be shown when inputting data or choosing parameters. Thanks to the suggestion from aikenann _at_ gmail com.
- Warning messages of sfdisk are suppressed when running on GPT device.
- ocs-onthefly was improved to make it work with dual boot (linux/mac osx) on mac machine.

* Tue Apr 28 2009 Steven Shiau <steven _at_ nchc org tw> 2.3.3-16
- Minor bug fixed: typo in "sfdisk -R" backup plan.
- Bug fixed: Wrong return code 1 was sent in drbl-ocs. Thanks to Jesus Feliz Fernandez for the bug report, and Louie Chen for the bug fix.

* Mon Apr 27 2009 Steven Shiau <steven _at_ nchc org tw> 2.3.3-15
- "sfdisk -R" is used as a backup plane for partprobe after GPT partition table is created.
- Disk to disk clone for Intel-based Mac OS is supported now.

* Sun Apr 26 2009 Steven Shiau <steven _at_ nchc org tw> 2.3.3-14
- create-drbl-live was improved to work with kernel 2.6.29.

* Sat Apr 25 2009 Steven Shiau <steven _at_ nchc org tw> 2.3.3-13
- create-gparted-live was improved to work with squashfs in mainline kernel (2.6.29).
- Mounting HFS+ partition with "-o force" was added as an option in ocs-preproot. Thanks to Max Hales for this suggestion.
- When inputting image name or device name is cancelled, an option to exit was added. Thanks to Sam Russo.
- The interactive mode of ocs-onthefly will prompt the command and options so it's easier to be run in the command line prompt again.

* Fri Apr 24 2009 Steven Shiau <steven _at_ nchc org tw> 2.3.3-12
- Output messages of ocs-sr were slightly modified.
- Start sector in the meta data of NTFS partition will be changed by partclone.ntfsreloc after restoring. Thanks to Curtis Gedak for the info and the testing results from Ceasar Sun.

* Thu Apr 23 2009 Steven Shiau <steven _at_ nchc org tw> 2.3.3-11
- Bug fixed: some output messages should not shown when running ocs-live-dev with -d option.

* Thu Apr 23 2009 Steven Shiau <steven _at_ nchc org tw> 2.3.3-10
- Submenu of syslinux/isolinux is used for memtest, freedos and network boot (in ocs-live-boot-menu).
- File system ext4dev was listed in the support fs list in drbl-ocs.conf
- Bug fixed: ocs-live-dev failed to use grub to create a bootable Clonezilla live device.

* Thu Apr 23 2009 Steven Shiau <steven _at_ nchc org tw> 2.3.3-9
- The command to create Clonezilla live iso and zip was added, and it will be saved to the file Clonezilla-Live-Version.

* Thu Apr 23 2009 Steven Shiau <steven _at_ nchc org tw> 2.3.3-8
- Improvement: If edd_id failed, another method will be tried. If option "-e" is chosen, the CHS value from image file will be used with partclone.ntfsreloc if edd info is not available.

* Wed Apr 22 2009 Steven Shiau <steven _at_ nchc org tw> 2.3.3-7
- Bug fixed: multicast clone restoration failed with new format image file.

* Mon Apr 20 2009 Steven Shiau <steven _at_ nchc org tw> 2.3.3-6
- Clonezilla image dir will be created when booting (in S03prep-drbl-clonezilla) so it can be mounted in  ocs_prerun directly.

* Sun Apr 19 2009 Steven Shiau <steven _at_ nchc org tw> 2.3.3-5
- Comment in ocs-functions was updated.

* Sun Apr 19 2009 Steven Shiau <steven _at_ nchc org tw> 2.3.3-4
- A minor prompt in ocs-sr was updated.
- Ext4 was added in the support lists in ocs-resize-part.
- NTFS support is turned on for partclone. Option -q2 is the default option, and ntfsclone will be replaced by partclone if -q2 is selected.
- Partclone is used for ocs-onthefly by default now.
- S06pre-run was improved to accept boot parameters ocs_prerun[[:digit:]]. E.g. ocs_prerun, ocs_prerun1, ocs_prerun2...
- A new variable extra_lzma_opt was added in drbl-ocs.conf.
- Option -z4 (lzma) was added for drbl-ocs, ocs-sr, and used in ocs-functions.
- New file name format for the image of partition was added. E.g. partiton sda1 was saved by partclone.ext4 with gzip compression is: sda1.ext4-ptcl-img.gz.

* Mon Apr 13 2009 Steven Shiau <steven _at_ nchc org tw> 2.3.3-3
- S06pre-run was improved to work with shell scropt or execution command.

* Sat Apr 11 2009 Steven Shiau <steven _at_ nchc org tw> 2.3.3-2
- create-debian-live was improved to work with squashfs in mainline kernel (2.6.29).

* Fri Apr 10 2009 Steven Shiau <steven _at_ nchc org tw> 2.3.3-1
- Package gpart was added in the package lists in create-gparted-live. Thanks to Juan Pablo for this idea.
- A minor typo was fixed in ocs-functions.
- Ext4 was listed on the partclone support filesystem in drbl-ocs.conf
- Option -um|--user-mode was added in drbl-ocs.
- Beginner/expert mode was added.
- When multi CPU/core is available, -z1p (pigz) will be used when saving in Clonezilla live.

* Mon Apr 06 2009 Steven Shiau <steven _at_ nchc org tw> 2.3.2-80
- Bugs fixed: (1) ocs-iso removed required files when using toram function and exit abnormally. (2) Script to re-create recovery iso/zip file was not in the mode 755.

* Fri Apr 03 2009 Steven Shiau <steven _at_ nchc org tw> 2.3.2-79
- Packages hal, dmsetup, dmraid and kpartx were moved to the list in drbl.conf.

* Fri Apr 03 2009 Steven Shiau <steven _at_ nchc org tw> 2.3.2-78
- Packages dmsetup, dmraid and kpartx were added in the packages list in create-gparted-live.

* Wed Apr 01 2009 Steven Shiau <steven _at_ nchc org tw> 2.3.2-77
- The permission to run will be checked in Forcevideo.
- Bug fixed: If any single file larger than 4 GB, ocs-iso failed to create the recovery iso.

* Tue Mar 31 2009 Steven Shiau <steven _at_ nchc org tw> 2.3.2-76
- Bug fixed: Duplicated prompts of packages output when saving image.

* Tue Mar 31 2009 Steven Shiau <steven _at_ nchc org tw> 2.3.2-75
- -j2 and -j3 were merged to be a single parameter -j2. Thanks to Orgad Shaneh for this idea.

* Mon Mar 30 2009 Steven Shiau <steven _at_ nchc org tw> 2.3.2-74
- Bug fixed: when doing partition to partition clone, if no file system is identified, we should use dd to clone it, not skip it.

* Mon Mar 30 2009 Steven Shiau <steven _at_ nchc org tw> 2.3.2-73
- Bug fixed: partclone.ntfsclone was not run if the NTFS boot partition is not the 1st one on the target disk.

* Sun Mar 29 2009 Steven Shiau <steven _at_ nchc org tw> 2.3.2-72
- The mode of run-again script file for recovery-iso-zip will be 755.
- Bug fixed: Failed to create Clonezilla live recovery iso on USB flash drive version of Clonezilla live.

* Sun Mar 29 2009 Steven Shiau <steven _at_ nchc org tw> 2.3.2-71
- The prompt to use space key to mark the selections was added for most of the checklist type of dialog.

* Fri Mar 20 2009 Steven Shiau <steven _at_ nchc org tw> 2.3.2-70
- Forcevideo was improved to work with some higher resolution modes. Thanks to pstein for this idea.
- Boot parameter "noprompt" was append to "To RAM" menu now. Thanks to mybugaccount mybugaccount (mybugaccount _at_ users sourceforge net).
- The optiont "-V" of ntfsclone will be check if available before it is run. Thanks to Olivier Korn (olivier_korn _at_ users sourceforge net) for this bug report.

* Thu Mar 19 2009 Steven Shiau <steven _at_ nchc org tw> 2.3.2-69
- Bug fixed: grub-install was not run due to the function changed in the previous release.

* Thu Mar 19 2009 Steven Shiau <steven _at_ nchc org tw> 2.3.2-68
- Minor bug about running grub-install was fixed.

* Thu Mar 19 2009 Steven Shiau <steven _at_ nchc org tw> 2.3.2-67
- Now "-g auto" option will run grub-install only when the grub config partition is on the restored partitions list.
- Package vim-common list was moved from create-gparted-live to drbl.conf.

* Wed Mar 18 2009 Steven Shiau <steven _at_ nchc org tw> 2.3.2-66
- ocs-live-dev will use tar instead of zip when recovery file is larger than 2 GB. Thanks to Frank (frank28 _at_ users sourceforge net) for this bug report.
- A better way to deal with EXTRA_SFDISK_OPT environmental variable.

* Mon Mar 16 2009 Steven Shiau <steven _at_ nchc org tw> 2.3.2-65
- Prompts were added for EDD option.
- A prompt to use space key to mark the selection was added for checklist dialog.
- Bug fixed: Duplicated "-p true" was used when runing "ocs-sr -x".

* Mon Mar 16 2009 Steven Shiau <steven _at_ nchc org tw> 2.3.2-64
- Now option -e2 will work only for non-grub boot loader (was for MS boot loader, but it's not easy to decide).

* Sun Mar 15 2009 Steven Shiau <steven _at_ nchc org tw> 2.3.2-63
- The option for -e2 (to use the CHS from EDD when running sfdisk) will also be used with ocs-expand-mbr-pt.

* Fri Mar 14 2009 Steven Shiau <steven _at_ nchc org tw> 2.3.2-62
- vim-common (for /usr/bin/xdd) was added for gparted live. Since xdd is required for NTFS moves and copies.
- An option -e2 (to use the CHS from EDD when running sfdisk) was added in ocs-sr and ocs-onthefly. Thanks to Orgad Shaneh for this idea.

* Sun Mar 08 2009 Steven Shiau <steven _at_ nchc org tw> 2.3.2-61
- Three more options (-g|--drbl-repo-url, -m|--mirror-url, -s|--mirror-security-url) were added in create-*-live so that we can assign the repository.
- Variables debian_mirror_url_def, debian_mirror_security_url_def, DRBL_REPOSITORY_URL_def and DRBL_GPG_KEY_URL are moved from create-*-live to drbl-ocs.conf.

* Sat Mar 07 2009 Steven Shiau <steven _at_ nchc org tw> 2.3.2-60
- Separate the variables as locale_to_keep_for_no_X and locale_to_keep_for_X for clonezilla live and drbl live.

* Sat Mar 07 2009 Steven Shiau <steven _at_ nchc org tw> 2.3.2-59
- Font size of desktop icons was changed to smaller in gparted live.
- More locales files were kept when create-*-live.
- drbl-live-hook was updated to add nolock for unfs3 client.

* Fri Feb 27 2009 Steven Shiau <steven _at_ nchc org tw> 2.3.2-58
- Bug fixed: Failed to list partition of Mac OS when saving an image. Thanks to Steve Poe <Steve.Poe _at_ demandtec com>.

* Thu Feb 26 2009 Steven Shiau <steven _at_ nchc org tw> 2.3.2-57
- Bug fixed: Failed to overwrite LVM disk when creating partition table in restoring disk image.

* Tue Feb 24 2009 Steven Shiau <steven _at_ nchc org tw> 2.3.2-56
- Verbose flag was set when -v is on in create-*-live.
- create-ubuntu-live was improved to work with jaunty which now uses libc6 instead of belocs-locales-bin.
- Function get_live_boot_param in ocs-functions was updated to search live.cfg for boot parameters of Clonezilla live.
- Bug fixed: drbl-ocs.conf was not copied to include dir for hooking when creating ubuntu-based clonezilla live.

* Thu Feb 12 2009 Steven Shiau <steven _at_ nchc org tw> 2.3.2-55
- Bug fixed: "--bootstrap cdebootstrap" should be used in create-debian-live.

* Thu Feb 12 2009 Steven Shiau <steven _at_ nchc org tw> 2.3.2-54
- A function to check live helper and cdebootstrap version required when creating clonezilla/gparted/drbl was added.

* Thu Feb 12 2009 Steven Shiau <steven _at_ nchc org tw> 2.3.2-53
- Bug fixed: prerun/postrun dirs of clonezilla live were not created.

* Thu Feb 12 2009 Steven Shiau <steven _at_ nchc org tw> 2.3.2-52
- creaet-*-live were updated for live helper 1.0.3.

* Wed Feb 11 2009 Steven Shiau <steven _at_ nchc org tw> 2.3.2-51
- Use udev data instead of lshw to get the serial no of harddrive. It's faster.

* Sat Jan 31 2009 Steven Shiau <steven _at_ nchc org tw> 2.3.2-50
- gparted-live-hook was updated to keep man dir.
- create-gparted-live was updated to use working dir as tmp dir.

* Fri Jan 30 2009 Steven Shiau <steven _at_ nchc org tw> 2.3.2-49
- Bug fixed: Getting /dev/sda1 info failed in ocs-onthefly. Thanks to Justin Miranda, aidan (aidanmcg33) and Jean-Francois Nifenecker for this bug report.

* Thu Jan 29 2009 Steven Shiau <steven _at_ nchc org tw> 2.3.2-48
- Bug fixed: Getting /dev/sda1 info failed in prep-ocsroot when mouting local device as clonezilla image home. Thanks to Patrick Babinger and stupidkid <stupidkid.lin _at_ gmail com> for this bug report.

* Tue Jan 27 2009 Steven Shiau <steven _at_ nchc org tw> 2.3.2-47
- Suppress the error messages of lshw since it's not available in OpenSuSE.

* Mon Jan 26 2009 Steven Shiau <steven _at_ nchc org tw> 2.3.2-46
- Bug fixed: Writting Info-packages in the clonezilla image dir was broken in clonezilla box mode.

* Sat Jan 24 2009 Steven Shiau <steven _at_ nchc org tw> 2.3.2-45
- Minor updates about ocs-functions.

* Sat Jan 24 2009 Steven Shiau <steven _at_ nchc org tw> 2.3.2-44
- Bug fixed: ocs-get-part-info input parameters was wrongly parsed.
- Make collecting hardware info faster. Do not duplicate scan.

* Sat Jan 24 2009 Steven Shiau <steven _at_ nchc org tw> 2.3.2-43
- Bug fixed: LVM might use ID=83 in partition table, therefore we should not parse it based on partition ID. (https://sourceforge.net/tracker2/?func=detail&atid=671650&aid=2528606&group_id=115473)

* Tue Jan 20 2009 Steven Shiau <steven _at_ nchc org tw> 2.3.2-42
- Dirs $OCS_PRERUN_DIR and $OCS_POSTRUN_DIR will be created when creating clonezilla live.
- Function get_live_media_mnt_point will search boot parameter live-media-path, too.
- Function get_RawCHS_of_HD_from_sfdisk was added and will be used as a backup plan for partclone.ntfsreloc (https://sourceforge.net/forum/message.php?msg_id=6181406). Thanks to Orgad Shaneh.

* Sat Jan 17 2009 Steven Shiau <steven _at_ nchc org tw> 2.3.2-41
- Option -j2 and -j3 for saving or restoring hidden data were added in drbl-ocs and ocs-sr.
- Option -j2 for cloning hidden data was added in ocs-onthefly.

* Fri Jan 16 2009 Steven Shiau <steven _at_ nchc org tw> 2.3.2-40
- Bug fixed: nogui was not working for partclone when running ocs-sr -x.

* Fri Jan 16 2009 Steven Shiau <steven _at_ nchc org tw> 2.3.2-39
- Bug fixed: An extra shift existed in ocs-live-dev.

* Fri Jan 16 2009 Steven Shiau <steven _at_ nchc org tw> 2.3.2-38
- Minor updates about prompt in ocs-functions.

* Thu Jan 15 2009 Steven Shiau <steven _at_ nchc org tw> 2.3.2-37
- Minor updates for ocs-resize-part.
- A new option "-u UNIT" was added to ocs-get-part-info.
- Functions to save and resore hidden data between MBR and 1st partition were added for ocs-sr and ocs-onthefly (https://sourceforge.net/forum/message.php?msg_id=5471665). Thanks to Alberto (arbouzas), david adamo and jess (jessdk).
- Bugs fixed: ocs-iso and ocs-live-dev were fixed (ID: 2465945). Thanks to Orgad Shaneh.
- Bugs fixed: ocs-live-dev was broken for -m (https://sourceforge.net/forum/message.php?msg_id=6099180). Thanks to lucsmitty (gregs).
- Bug fixed: Some parameters after inputed again did not work when running "ocs-sr -x".
- Spanish language files were added. Thanks to Juan Ramón Martínez <jrmc77 _at_ terra es>.
- es_ES.UTF-8 was added in ocs-live-hook.conf.
- The function to get CHS from EDD was added. Thanks to Orgad Shaneh, Antorz and Louie Chen.

* Sun Jan 11 2009 Steven Shiau <steven _at_ nchc org tw> 2.3.2-36
- Bug fixed: Disk size was not shown correctly when locales is zh_TW before restoring an image to a disk.
- The partition to be run ntfsreloc should be boot partition, not the one has ntldr. Since Windows 7 does not have that file.

* Sat Jan 10 2009 Steven Shiau <steven _at_ nchc org tw> 2.3.2-35
- Instead of remove /usr/share/man/man1 dir and files, we only remove files so that later when using clonezilla live, apt-get install package won't exit due to no /usr/share/man/man1 so postrun fails.
- Add batch mode option for ocs-resize-part of ocs-onthefly.
- LSB tag was added to ocs-run.

* Wed Jan 07 2009 Steven Shiau <steven _at_ nchc org tw> 2.3.2-34
- ocs-get-part-info was improved so that it can parse more than one index.
- Bug fixed: When choosing partition, extended or swap should not be listed (due to the command of "file -Ls" won't show any "extended" info about a partition in Debian Lenny. We switch to use ocs-get-part-info instead of file).

* Tue Jan 06 2009 Steven Shiau <steven _at_ nchc org tw> 2.3.2-33
- Since the bug of partclone.fat12 was fixed. the support for fat12 for partclone in drbl-ocs.conf was added in the list.
- "-e1 auto" option was added to ocs-onthefly so ntfsreloc can be run with this option.
- Option -V of ntfsclone restoring is on in ocs-onthefly.
- Bug fixed: When chosing partition, extended or swap should not be listed.

* Mon Dec 29 2008 Steven Shiau <steven _at_ nchc org tw> 2.3.2-32
- Turn off ntfs-3g mounting warning in prep-ocsroot.

* Sun Dec 28 2008 Steven Shiau <steven _at_ nchc org tw> 2.3.2-31
- Bug fixed: "exit 1" should not be used in S08pre-run of GParted live. We should use "return 1".

* Fri Dec 26 2008 Steven Shiau <steven _at_ nchc org tw> 2.3.2-30
- More prompt before running partclone.ntfsreloc.
- Since partclone.fat12 is buggy, the support for fat12 for partclone in drbl-ocs.conf is removed from the list.
- Before restoring or saving, user must enter y/yes/n/no. It can not be nothing.

* Thu Dec 25 2008 Steven Shiau <steven _at_ nchc org tw> 2.3.2-29
- An option -z2p for parallel bzip2 was added.

* Wed Dec 24 2008 Steven Shiau <steven _at_ nchc org tw> 2.3.2-28
- clone-multiple-usb-example.sh was updated. Thanks to Alvin Su.
- Two functions (check_ntfs_boot_partition, run_ntfsreloc_part) were added in ocs-functions so we can relocate NTFS CHS.
- An option -e1|--change-geometry was added to ocs-sr and drbl-ocs.

* Mon Dec 22 2008 Steven Shiau <steven _at_ nchc org tw> 2.3.2-27
- If batch mode is on, we won't find the serial no of harddrive.
- Program create-ocs-tmp-img was improved with some options and more prompt.
- Language file it_IT was added, so ocs-live.conf was modified, too.
- An example "clone-multiple-usb-example.sh" to clone an image to several USB flash drives was added.

* Wed Dec 17 2008 Steven Shiau <steven _at_ nchc org tw> 2.3.2-26
- When restoring partitions only, we should not restore swap partition. Thanks to Samwise Foxburr for this bug report.

* Tue Dec 09 2008 Steven Shiau <steven _at_ nchc org tw> 2.3.2-25
- live hook files will be copied recursively for those create-*-live.
- ttyS0 for Ubuntu upstart will be copied to Ubuntu-based clonezilla live.

* Mon Dec 09 2008 Steven Shiau <steven _at_ nchc org tw> 2.3.2-24
- parse_cmdline_option in gl-functions was updated.
- GParted live will honor gp_prerun boot parameter.
- Show serial no of disk when saving parts. Thanks to Eric Lu.

* Tue Dec 02 2008 Steven Shiau <steven _at_ nchc org tw> 2.3.2-23
- Now we can use custom-ocs with an image included in ocs-iso and ocs-live-dev. Thanks to Orgad Shaneh for this idea.

* Mon Dec 01 2008 Steven Shiau <steven _at_ nchc org tw> 2.3.2-22
- create-debian-live was improved so that it works for Etch with kernel 2.6.18 again.
- -u|--include-dir option was added to ocs-iso and ocs-live-dev.
- Clonezilla now will honor the boot parameter ocs_pre_run, and it will be run during booting.
- Both ocs-debug and ocs_debug in the boot parameters will be honored by clonezilla.

* Sun Nov 30 2008 Steven Shiau <steven _at_ nchc org tw> 2.3.2-21
- Bugs fixed: Failing to run custom-os was fixed in ocs-iso and ocs-live-dev.

* Sun Nov 30 2008 Steven Shiau <steven _at_ nchc org tw> 2.3.2-20
- Customized ocs option was updated in ocs-iso and ocs-live-dev. Thanks to Orgad Shaneh.
- S03prep-drbl-clonezill was improved so that custom-ocs will be put in normal drbl path (/opt/drbl/sbin/). Thanks to Orgad Shaneh.

* Thu Nov 27 2008 Steven Shiau <steven _at_ nchc org tw> 2.3.2-19
- MC_HxEd for GParted live was added. See http://gparted-forum.surf4.info/viewtopic.php?pid=10421#p10421 for more details. Thanks to cmdr for providing this GPL program.

* Thu Nov 27 2008 Steven Shiau <steven _at_ nchc org tw> 2.3.2-18
- A promput about required packages was added in create-debian-live.
- create-ubuntu-live was updated to work for Jaunty.
- Bug fixed: locales list in ocs-live-hook.conf without comma. Thanks to Orgad Shaneh.

* Sat Nov 22 2008 Steven Shiau <steven _at_ nchc org tw> 2.3.2-17
- Remove the prompt about Eee PC in 640x480 mode in Clonezilla live boot menu.

* Sat Nov 22 2008 Steven Shiau <steven _at_ nchc org tw> 2.3.2-16
- Package cryptsetup was added in create-gparted-live. Thanks to Bodo P. Schmitz for this idea.
- Bug fixed: When creating recovery iso/zip using "ocs-sr -x", the reboot/shudown/none option was asked twice. Thanks to Jean-Francois Nifenecker.

* Wed Nov 12 2008 Steven Shiau <steven _at_ nchc org tw> 2.3.2-15
- Bug fixed: If a dir name begining with "-", we should exclude it in prep-ocsroot.

* Wed Nov 12 2008 Steven Shiau <steven _at_ nchc org tw> 2.3.2-14
- Force to add partimage in GParted live.

* Mon Nov 10 2008 Steven Shiau <steven _at_ nchc org tw> 2.3.2-13
- The command about grep was put with LANG=C in S03prep-drbl-clonezilla.

* Wed Nov 05 2008 Steven Shiau <steven _at_ nchc org tw> 2.3.2-12
- Add time command when running md5sum or sha1sum.

* Mon Nov 03 2008 Steven Shiau <steven _at_ nchc org tw> 2.3.2-11
- Bug fixed: If a dir name with space (https://sourceforge.net/forum/message.php?msg_id=5561709), we should exclude it in prep-ocsroot, the previous workaround won't work, since if the name is changed, it won't be mounted.

* Mon Nov 03 2008 Steven Shiau <steven _at_ nchc org tw> 2.3.2-10
- Bug fixed: If a dir name with space (https://sourceforge.net/forum/message.php?msg_id=5561709), we should workaround it in prep-ocsroot. Thanks to Mark Wolfgruber.

* Fri Oct 31 2008 Steven Shiau <steven _at_ nchc org tw> 2.3.2-9
- drbl.sf.net was replaced by drbl.name, and clonezilla.sf.net was replaced by clonezilla.org.

* Fri Oct 31 2008 Steven Shiau <steven _at_ nchc org tw> 2.3.2-8
- S05kbd-conf about serial console was improved.

* Fri Oct 31 2008 Steven Shiau <steven _at_ nchc org tw> 2.3.2-7
- Two variables ntfsclone_save_extra_opt_def and ntfsclone_restore_extra_opt_def were added in drbl-ocs.conf so that user can add his/her extra options for ntfsclone.
- "--rescue" will be added if "-ntfs-ok" option is selected. Thanks to Stephen Anderson for this idea (https://sourceforge.net/forum/message.php?msg_id=5540867).
- S05kbd-conf about serial console was improved.

* Thu Oct 30 2008 Steven Shiau <steven _at_ nchc org tw> 2.3.2-6
- When local_dev is chosen in prep-ocsroot, it won't list the clonezilla image dirs as options if exists.
- Clonezilla live can be started on tty1 or ttyS0.

* Sat Oct 25 2008 Steven Shiau <steven _at_ nchc org tw> 2.3.2-5
- Do not sort all the partititon list got from /proc/partition in ocs-functions. Other the order will be like: sda1 sda10 sda11 sda12 sda2 sda3...
- ocs-onthefly was slightly polished, especially for prompts.

* Thu Oct 23 2008 Steven Shiau <steven _at_ nchc org tw> 2.3.2-4
- The help message about -r|--resize-partition was updated.  Thanks to nikolay kasatkin.
- Do not use sort when searching partitions in /proc/partitions, since it will make the order to be like: "sda1 sda10 sda11 sda12 sda13 sda2 sda3 sda4 sda5 sda6 sda7 sda8 sda9" instead of in order. Ref: https://sourceforge.net/forum/message.php?msg_id=5478495. Thanks to Donut.

* Wed Oct 22 2008 Steven Shiau <steven _at_ nchc org tw> 2.3.2-3
- Bug fixed: if exit is chosen when running "ocs-sr -x", ocs-sr should quit quietly.

* Wed Oct 22 2008 Steven Shiau <steven _at_ nchc org tw> 2.3.2-2
- zh_CN.UTF-8 was listed locale_to_keep in ocs-live-hook.conf.

* Wed Oct 22 2008 Steven Shiau <steven _at_ nchc org tw> 2.3.2-1
- Forcevideo was updated with dpkg-reconfigure xserver-xorg support for older X.
- syslinux.exe will be downloaded from internet, not from drbl pkg anymore.
- The function to mount first level dir on local device was added.
- A sample program gen-netcfg was added so that it can be used as a startup service for cloned system to be assigned static network configuration according to MAC address.

* Mon Oct 20 2008 Steven Shiau <steven _at_ nchc org tw> 2.3.1-82
- Hardware and software info will be saved in clonezilla image for ref only.

* Sun Oct 19 2008 Steven Shiau <steven _at_ nchc org tw> 2.3.1-81
- Bug fixed: checksums was not created when saving parts. Thanks to Louie Chie.

* Sun Oct 19 2008 Steven Shiau <steven _at_ nchc org tw> 2.3.1-80
- Bug fixed: /lib/udev/cdrom_id mechanism should not be done in Debian-based Clonezilla live.

* Sun Oct 19 2008 Steven Shiau <steven _at_ nchc org tw> 2.3.1-79
- Bug fixed: /lib/udev/cdrom_id in Ubuntu-based clonezilla live initramfs was missing.

* Sat Oct 18 2008 Steven Shiau <steven _at_ nchc org tw> 2.3.1-78
- ocs-live-hook was updated for making Clonezilla live tftp from busybox work.
- Bug fixed: previous converted image will be removed before being created again in create-ocs-tmp-img. md5sums and sha1sums function updated in ocs-functions.

* Fri Oct 17 2008 Steven Shiau <steven _at_ nchc org tw> 2.3.1-77
- ocs-functions was modified to avoid lshw to be run twice.
- When restoring an image, we should ask image name and target dev first, then advanced params.
- Two options were added for Clonezilla: generate/check MD5SUMS and SHA1SUMS.

* Wed Oct 15 2008 Steven Shiau <steven _at_ nchc org tw> 2.3.1-76
- Bug fixed: Since ubuntu 8.10 won't load uvesafb, we should load module uvesafb when there is mode_option option in boot parameters (For Ubuntu-based Clonezilla live).

* Wed Oct 15 2008 Steven Shiau <steven _at_ nchc org tw> 2.3.1-75
- Forcevideo was rolled back to original one. i.e. instead of appending, a fresh xorg.conf is created.

* Tue Oct 14 2008 Steven Shiau <steven _at_ nchc org tw> 2.3.1-74
- psmouse was forced to be loaded in gparted/drbl/clonezilla live.

* Tue Oct 14 2008 Steven Shiau <steven _at_ nchc org tw> 2.3.1-73
- S03prep-gparted-live, S05kbd-conf and S07choose-lang were updated to suppress some error messages.
- xserver-xorg-input-evdev was added when creating gparted live.
- Forcevideo was updated to append the config in xorg.conf, not overwrite it.

* Tue Oct 14 2008 Steven Shiau <steven _at_ nchc org tw> 2.3.1-72
- prep-ocsroot was polished, and an option ""-s|--skip-ocsroot-mountpoint-chk" was added. 
- ocs-srv-live.sh was polished.

* Sun Oct 12 2008 Steven Shiau <steven _at_ nchc org tw> 2.3.1-71
- Use "-b 1024k" for mksquashfs in those create-*-live. This will make live media file smaller.
- create-ubuntu-live was updated with more prompt.
- Bug fixed: ocs-live-dev -s -d /dev/$partition failed. Thanks to cashboxhung, and Olaf for reporting this bug.

* Sat Oct 11 2008 Steven Shiau <steven _at_ nchc org tw> 2.3.1-70
- Prompt was updated in gparted live before entering X.

* Sat Oct 11 2008 Steven Shiau <steven _at_ nchc org tw> 2.3.1-69
- Packages ifupdown and dhcp3-client was added in gparted live.
- When purging locales in create gparted/clonezilla/drbl live, do not be verbose.
- New mechanism to start gparted live: rc2.d/S99start-gparted-live. Two more boot parameters gl_numlk and gl_capslk were added to control numlock and scrlock.

* Wed Oct 08 2008 Steven Shiau <steven _at_ nchc org tw> 2.3.1-68
- Bug fixed: ocs-expand-mbr-pt failed to process large disk, i.e. e.g. size=291563622 list in the *-sda.pt, where no space after "=".
- A new option "-z1p" was added so that we can use parallel gzip program (pigz) to compress the image.
- Machine product name will be shown before restoring an image.

* Tue Oct 07 2008 Steven Shiau <steven _at_ nchc org tw> 2.3.1-67
- An option was added: -j1|--dump-mbr-in-the-end. This option allows us to use dd to dump the MBR (total 512 bytes, i.e. 446 bytes (executable code area) + 64 bytes (table of primary partitions) + 2 bytes (MBR signature; # 0xAA55) = 512 bytes) _after_ disk image was restored. This is an insurance for some hard drive has different numbers of cylinder, head and sector between image was saved and restored. Thanks to Luis F. Gimilio for this idea.

* Sun Oct 05 2008 Steven Shiau <steven _at_ nchc org tw> 2.3.1-66
- ocs-functions was updated with patched ntfsclone (support -V, --ignore-bitmap-check). Now the messages when saving and restoring ntfs will be more verbose.

* Sun Oct 05 2008 Steven Shiau <steven _at_ nchc org tw> 2.3.1-65
- Bug fixed: "sudo -i ocs-live-run-menu" was appended twice in ~user/.bash_profile when S03prep-drbl-clonezilla was run again.

* Sat Oct 04 2008 Steven Shiau <steven _at_ nchc org tw> 2.3.1-64
- Comments were added in prep-ocsroot about the webdav won't work for Clonezilla live.
- grub is included for gparted live packages list.
- Force to remove some X programs in Clonezilla live since jfbterm only need unifont.pcf.gz. This will reduce the size of lenny-based Clonezilla 6 MB. Thanks to Louie Chen.

* Fri Oct 03 2008 Steven Shiau <steven _at_ nchc org tw> 2.3.1-63
- Bug fixed: S03prep-drbl-clonezilla failed.

* Fri Oct 03 2008 Steven Shiau <steven _at_ nchc org tw> 2.3.1-62
- To make usercrypted boot parameter work in Clonezilla live, we have to remove preseed user. However, for gparted live and drbl live, we still preseed user. Maybe change that in the future.

* Fri Oct 03 2008 Steven Shiau <steven _at_ nchc org tw> 2.3.1-61
- Since live-initramfs 1.139.1-3 (1.139.1-4drbl, too) uses UID=1000 for default account "user", the corresponding settings were changed.
- 4 more boot parameters were added for Clonezilla live: ocs_daemonon ocs_daemonoff ocs_numlk ocs_capslk. Ex. for the first 2 parameters, ocs_daemonon="ssh", then ssh service will be turned on when booting. For the last 2 parameters, use "on" or "off", e.g. ocs_numlk=on to turn on numberlock when booting.

* Tue Sep 30 2008 Steven Shiau <steven _at_ nchc org tw> 2.3.1-60
- Bug fixed: COPY file checking bug. (#2134230 closed). Thanks to Orgad Shaneh.

* Sun Sep 28 2008 Steven Shiau <steven _at_ nchc org tw> 2.3.1-59
- Bug fixed: confused vesa/uvesa modes fixed again in ocs-live-boot-menu (#2115605 closed). ///NOTE/// Some options of ocs-live-boot-menu were changed. Thanks to Orgad Shaneh.
- A new program ocs-cnvt-usb-zip-to-dsk was added so that it's easier to convert DRBL/Clonezilla live zip file to raw disk image or vmdk image.

* Mon Sep 22 2008 Steven Shiau <steven _at_ nchc org tw> 2.3.1-58
- More info when running create-drbl-live.

* Sun Sep 21 2008 Steven Shiau <steven _at_ nchc org tw> 2.3.1-57
- A special word "1st-disk" was added to drbl-ocs so that we can assign the target disk as 1st available disk from /proc/partitions. ///NOTE/// This option only works for unicast, not for multicast/broadcast (#2115612 closed). Thanks to Orgad Shaneh.

* Fri Sep 19 2008 Steven Shiau <steven _at_ nchc org tw> 2.3.1-56
- 2 parameters (-a|--packages, -c|--categories) were added in create-debian-live and create-ubuntu-live.
- Prompt in ocs-functions was updated.
- A new variable $debian_pkgs_for_gparted is used now in create-gparted-live and create-drbl-live.
- create-drbl-live-by-pkg was updated with better options.

* Fri Sep 19 2008 Steven Shiau <steven _at_ nchc org tw> 2.3.1-55
- create-drbl-live-by-pkg was updated with syslogd added.

* Fri Sep 19 2008 Steven Shiau <steven _at_ nchc org tw> 2.3.1-54
- Bug fixed: "/" problem with perl for some cases. Thanks to Will Esselink for reporting this bug.

* Thu Sep 18 2008 Steven Shiau <steven _at_ nchc org tw> 2.3.1-53
- Typos fixed in ocs-functions and ocs-live-boot-menu (#2115623 closed). Thanks to Orgad Shaneh.
- Bug fixed: confused vesa/uvesa modes fixed in ocs-live-boot-menu (#2115605 closed). ///NOTE/// Some options of ocs-live-boot-menu were changed. Thanks to Orgad Shaneh.
- Bug fixed: -j option of ocs-iso and ocs-live-dev did not work (#2115594 closed). Thanks to Orgad Shaneh.

* Wed Sep 17 2008 Steven Shiau <steven _at_ nchc org tw> 2.3.1-52
- Prompt message was updated in ocs-functions.

* Wed Sep 17 2008 Steven Shiau <steven _at_ nchc org tw> 2.3.1-51
- Bug fixed: Wrong prompt message about clonezilla image dir when saving image.
- Two variables were added in drbl-ocs.conf: udp_sender_extra_opt_default and udp_receiver_extra_opt_default. Thanks to Mike Taylor for this idea. Ref: https://sourceforge.net/forum/message.php?msg_id=5281039
- Prompts about image split were updated.

* Tue Sep 16 2008 Steven Shiau <steven _at_ nchc org tw> 2.3.1-50
- Bug fixed: recovery_iso_zip menu will only be shown when there is image in $ocsroot.

* Mon Sep 15 2008 Steven Shiau <steven _at_ nchc org tw> 2.3.1-49
- Prompt in create-drbl-live was updated.
- Package hfsprogs was added in GParted live. Thanks to Curtis Gedak.

* Sat Sep 13 2008 Steven Shiau <steven _at_ nchc org tw> 2.3.1-48
- Bug fixed: /usr/share/zoneinfo/UTC should be kept when creating GParted live.

* Sat Sep 13 2008 Steven Shiau <steven _at_ nchc org tw> 2.3.1-47
- Grandr icon position on idesktop was shifted in gparted live.

* Fri Sep 12 2008 Steven Shiau <steven _at_ nchc org tw> 2.3.1-46
- Minor changes when loading drbl/clonezilla related functions in create-*-live.
- webdav function was added in prep-ocsroot, however, it's not shown by default, since davfs2 from Etch was broken.

* Thu Sep 11 2008 Steven Shiau <steven _at_ nchc org tw> 2.3.1-45
- resize (-r) is turned off by default in ocs-onthefly.
- Default to use VGA 1024x768 for Clonezilla live.  Thanks to Scott Ochiltree for this suggestion.
- Suppress MD starting failure messages in DRBL/Clonezilla live. Thanks to Scott Ochiltree for this suggestion.

* Thu Sep 11 2008 Steven Shiau <steven _at_ nchc org tw> 2.3.1-44
- Bug fixed: /usr/share/zoneinfo/UTC should be kept when creating Clonezilla live. Thanks to Spiros Georgaras for reporting this bug.
- "ocs-debug" is used instead of "ocs-break" to enter command line prompt after live-initramfs is run.

* Tue Sep 09 2008 Steven Shiau <steven _at_ nchc org tw> 2.3.1-43
- Bug fixed: -a option of ocs-live-dev was used twice. Remove one of them.

* Mon Sep 08 2008 Steven Shiau <steven _at_ nchc org tw> 2.3.1-42
- Some files not fitting current gparted live environment were removed.
- Bug fixed: command "file -Ls" comes with Debian lenny does not show extended partition with any word "extended", therefore we added parted to check the partiton.

* Sat Sep 06 2008 Steven Shiau <steven _at_ nchc org tw> 2.3.1-41
- Live-helper now uses --categories instead of --section. Changed that in create-ubuntu-live. Thanks to Louie Chen.

* Tue Sep 02 2008 Steven Shiau <steven _at_ nchc org tw> 2.3.1-40
- eeepc-acpi was removed from extra_module_list in ocs-live-hook.conf
- Force to remove /etc/udev/rules.d/*persistent-net.rules in clonezilla/drbl/gparted live (just in case, although live helper has done that).

* Tue Sep 02 2008 Steven Shiau <steven _at_ nchc org tw> 2.3.1-39
- Some debian extra modules (atl2...) will be installed in drbl/clonezilla/gparted live.

* Sun Aug 31 2008 Steven Shiau <steven _at_ nchc org tw> 2.3.1-38
- ocs-live-boot-menu was not really updated.

* Sun Aug 31 2008 Steven Shiau <steven _at_ nchc org tw> 2.3.1-37
- mode_option instead of mode is used in ocs-live-boot-menu.

* Sun Aug 31 2008 Steven Shiau <steven _at_ nchc org tw> 2.3.1-36
- Kernel 2.6.27 ueses mode_option instead of mode for uvesafb.

* Sun Aug 31 2008 Steven Shiau <steven _at_ nchc org tw> 2.3.1-35
- Bug fixed: Only one kernel can be assigned in create-ubuntu-live.
- gl-kbd-conf was added for gparted live.
- Language and keyboard (gl_lang, gl_kbd) options can be assigned in kernel param for gparted live. The boot parameter gl_batch can be used to skip waiting for pressing enter. An example: "gl_lang=en_US gl_kbd=en gl_batch"
- Bug fixed: S03prep-drbl-clonezilla might fail if param is in the end of line.

* Thu Aug 28 2008 Steven Shiau <steven _at_ nchc org tw> 2.3.1-34
- Comments in drbl-ocs.conf were updated.

* Fri Aug 22 2008 Steven Shiau <steven _at_ nchc org tw> 2.3.1-33
- Bug fixed: The function exclude_umount_live_mnt_point_in_umountfs in ocs-live-hook-functions was updated to avoid the warning about /sys/fs/fuse/connections not mounted when rebooting/halting in Ubuntu-based clonezilla live.
- Bug fixed: Since we use nolocales in boot parameter, we have to preseed the LANG=en_US.UTF-8 in /etc/default/locale and /etc/environment so that whiptail in en_US.UTF-8 won't be distorted.

* Thu Aug 21 2008 Steven Shiau <steven _at_ nchc org tw> 2.3.1-32
- Use flavour=minimal for ubuntu-based clonezilla live. This will make the image ~ 8 MB smaller.
- Comments in create-debian-live was updated.

* Thu Aug 21 2008 Steven Shiau <steven _at_ nchc org tw> 2.3.1-31
- Some files were updated since locales maybe not in a archive file, it can be a dir tree in /usr/lib/locales. They are: gl-choose-lang, ocs-run, ocs-live-hook-functions, S05kbd-conf, ocs-langkbdconf-bterm and ocs-live-run-menu.

* Thu Aug 21 2008 Steven Shiau <steven _at_ nchc org tw> 2.3.1-30
- Bug fixed: && was missing in create-ubuntu-live.

* Wed Aug 20 2008 Steven Shiau <steven _at_ nchc org tw> 2.3.1-29
- Bug fixe: zh_TW was added in the locale_to_keep so that drbl live supports zh_TW better. Thanks to Louie Chen.
- A program create-drbl-live-by-pkg was added so that it's easier to create drbl live with different desktop environment (xfce, gnoem, kde).
- Now the supported locales (zh_TW, ja_JP, fr_FR) will be kept in the created iso/zip, it's not necesssary to be generated before running clonezilla live. An extra boot parameter "nolocales" was added so that the prebuilt locales won't be wiped by live initramfs.

* Fri Aug 15 2008 Steven Shiau <steven _at_ nchc org tw> 2.3.1-28
- Skip the keystroke waiting before running ocs-live-netcfg in clonezilla live. Thanks to Freyr Gunnar lafsson.

* Tue Aug 12 2008 Steven Shiau <steven _at_ nchc org tw> 2.3.1-27
- Bug fixed: When swap busy, "ocs-sr -x" failed in restoring image.

* Sat Aug 09 2008 Steven Shiau <steven _at_ nchc org tw> 2.3.1-26
- We'd better not to remove /usr/lib/gconv/ when creating debian live template for Clonezilla live since if we want to create debian live in Clonezilla live, in /usr/bin/lh_binary_syslinux it will run: iconv -f utf-8 -t latin1. Without /usr/lib/gconv/ lh_binary_syslinux will fail. This will increase the size of clonezilla live about 2 MB.

* Fri Aug 08 2008 Steven Shiau <steven _at_ nchc org tw> 2.3.1-25
- Bug fixed: check both kernel and device exist in ocs-function for cciss-related device: /proc/driver/cciss and /dev/cciss; /proc/driver/cpqarray and /dev/ida; /proc/driver/rd and /dev/ra.

* Wed Aug 06 2008 Steven Shiau <steven _at_ nchc org tw> 2.3.1-24
- Bug fixed: create-cciss-mapping was started by ocs-functions if /dev/ida/ or /dev/rd/ exists.

* Tue Aug 05 2008 Steven Shiau <steven _at_ nchc org tw> 2.3.1-23
- Bug fixed: a typo fixed in create-cciss-mapping.

* Tue Aug 05 2008 Steven Shiau <steven _at_ nchc org tw> 2.3.1-22
- create-cciss-mapping now supports /dev/cciss/, /dev/ida/, and /dev/rd/.

* Tue Aug 05 2008 Steven Shiau <steven _at_ nchc org tw> 2.3.1-21
- Example file custom-ocs-1 was polished.
- Bug fixed: We should keep more kernel driver modules in GParted live, especially acpi...

* Mon Aug 04 2008 Steven Shiau <steven _at_ nchc org tw> 2.3.1-20
- Bug fixed: Assigned file name of clonezilla live should be used in the customized iso/zip boot menu, too.

* Mon Aug 04 2008 Steven Shiau <steven _at_ nchc org tw> 2.3.1-19
- An example was added (custom-ocs-1), which can be used to restore an image from samba server.
- create-ocs-tmp-img will put the converted image in /tmp so it won't fail in readonly filesystem (e.g. CD) or FAT-based filesystem (e.g. samba).

* Mon Aug 04 2008 Steven Shiau <steven _at_ nchc org tw> 2.3.1-18
- Append /opt/drbl/sbin and /opt/drbl/bin in Clonezilla live system PATH.

* Mon Aug 04 2008 Steven Shiau <steven _at_ nchc org tw> 2.3.1-17
- Directory /etc/ocs should not created in ocs-live-dev in Clonezilla live..
- Directory /pkg is only creatd when custom-ocs is used in Clonezilla live.
- samples/custom-ocs was updated.
- Check specified_lang in cnvt-ocs-dev.
- Option -t|--ocsroot-resource-type was added in prep-ocsroot.

* Sun Aug 03 2008 Steven Shiau <steven _at_ nchc org tw> 2.3.1-16
- Force to use a complete busybox in initramfs of ubuntu-based clonezilla instead the one busybox-initramfs.

* Wed Jul 30 2008 Steven Shiau <steven _at_ nchc org tw> 2.3.1-15
- fb_term can be assigned in drbl-ocs.conf.

* Wed Jul 30 2008 Steven Shiau <steven _at_ nchc org tw> 2.3.1-14
- Bug fixed: bterm was not used in Ubuntu-based clonezilla live.

* Wed Jul 30 2008 Steven Shiau <steven _at_ nchc org tw> 2.3.1-13
- Function ask_language_if_supported_with_bterm in ocs-functions also respect TERM = jfbterm.
- ocs-kbdconf-bterm is renamed to be ocs-langkbdconf-bterm.
- ocs-kbdconf-bterm, ocs-live-run-menu and S05kbd-conf now support both bterm and jfbterm. However, we force to use bterm in Ubuntu-based clonezilla live since jfbterm does not work in Ubuntu intrepid.
- S02cmdline was added so that we can put ocs-break as a kernel parameter to enter command prompt before running S03prep-drbl-clonezilla.
- Will try to run "apt-get -y autoremove" in ocs-live-hook-functions.
- ocs-dbn-kbdconf was removed since it's no more necessary.

* Tue Jul 29 2008 Steven Shiau <steven _at_ nchc org tw> 2.3.1-12
- The main program to start clonezilla live "S99start-ocs-live" now is in rc2.d instead of rcS.d.

* Tue Jul 29 2008 Steven Shiau <steven _at_ nchc org tw> 2.3.1-11
- uvesafb option is supported in ocs-iso, ocs-live-dev and ocs-live-boot-menu.
- If uvesafb is found, reload it again in S03prep-drbl-clonezilla.

* Tue Jul 29 2008 Steven Shiau <steven _at_ nchc org tw> 2.3.1-10
- Prompt was updated in ocs-live-dev.
- Bug fixed: Something went wrong when replacing parameters of ocs-live.conf in S03prep-drbl-clonezilla.
- create-ubuntu-live was updated for Ubuntu intrepid (not finished).

* Tue Jul 29 2008 Steven Shiau <steven _at_ nchc org tw> 2.3.1-9
- Bug fixed: S03prep-drbl-clonezilla failed to parse something like ocs_live_extra_param="-g auto -c -r -k1 -r -p reboot restoredisk etch-lvm-partclone-hda hda" in /proc/cmdline.

* Tue Jul 29 2008 Steven Shiau <steven _at_ nchc org tw> 2.3.1-8
- The command to create recovery iso/zip will be saved in a temp file for later use.
- ocs-live-dev uses $ocsroot as a working dir instead of /tmp to avoid the shortage of disk space when running in clonezilla live.
- Bug fixed: Output filename of ocs-live-dev with image embedded was wrong.
- Module uvesafb was added in the initrd for ubuntu live since in intrepid uvesafb has replaced vesafb.

* Mon Jul 28 2008 Steven Shiau <steven _at_ nchc org tw> 2.3.1-7
- Comments in ocs-iso were updated.
- Bugs fixed: ocs-iso and ocs-live-dev failed to estimate the output file size if the template is the boot media.
- Put all drbl/clonezilla related packages in squashfs when using create-ubuntu-live.

* Sun Jul 27 2008 Steven Shiau <steven _at_ nchc org tw> 2.3.1-6
- USAGE of ocs-iso was updated.
- Bug fixed: Failed to update /etc/ocs/ocs-live.conf from /proc/cmdline in S03prep-drbl-clonezilla.
- Bug fixed: ocs-iso should put ocs-related parameters in isolinux boot menu.

* Fri Jul 25 2008 Steven Shiau <steven _at_ nchc org tw> 2.3.1-5
- Bug fixed: ocs_lang should be nothing in the beginning of ocs-live.conf.

* Fri Jul 25 2008 Steven Shiau <steven _at_ nchc org tw> 2.3.1-4
- Bug fixed: keymap in ocs-live.conf should not be setting by default for clonezilla live.
- Use PKG_FROM_DRBL_FOR_CLONEZILLA_LIVE in create-debian-live.

* Fri Jul 25 2008 Steven Shiau <steven _at_ nchc org tw> 2.3.1-3
- Bug fixed: /etc/ocs-live.conf should be created in live hook for clonezilla live.

* Fri Jul 25 2008 Steven Shiau <steven _at_ nchc org tw> 2.3.1-2
- Bug fixed: /proc/cmdline should be parsed and the settings should be saved in /etc/ocs/ocs-live.conf.

* Fri Jul 25 2008 Steven Shiau <steven _at_ nchc org tw> 2.3.1-1
- Bug fixed: ocs-kbdconf-bterm appends ocs_lang more than once in ocs-live.conf.
- Now all the clonezilla files are in the filesystem.squashfs for Clonezilla live.
- ocs-iso (ocs-live-dev not ready yet) can use the existing live media to create recovery CD/USB, or download the template iso from repository.

* Thu Jul 24 2008 Steven Shiau <steven _at_ nchc org tw> 2.3.0-31
- Bug fixed: Failed to parse linux-image version in create-ubuntu-live if nothing in $debian-updates.
- Not only hfs+ but also "hfsplus" were listed in partclone_support_fs in drbl-ocs.conf.

* Thu Jul 17 2008 Steven Shiau <steven _at_ nchc org tw> 2.3.0-30
- Bug fixed: language should be zh_TW.UTF-8 instead of tw.UTF-8 in ocs-iso and ocs-live-dev.
- The function to create recovery Clonezilla live iso/zip was added in ocs-sr.

* Sun Jul 13 2008 Steven Shiau <steven _at_ nchc org tw> 2.3.0-29
- In OpenSuSE 10.3/11.0 or later, we will use the command "grub-install.unsupported" instead of the "grub-install" to install grub after cloning.

* Sat Jul 12 2008 Steven Shiau <steven _at_ nchc org tw> 2.3.0-28
- Bug fixed: suppress the /cow not found error message when rebooting/halting in gparted live.

* Sat Jul 12 2008 Steven Shiau <steven _at_ nchc org tw> 2.3.0-27
- Bug fixed: Because Live helper does not deal with the umountfs service when shutdowning/rebooting, we deal with that in gparted live.

* Sat Jul 12 2008 Steven Shiau <steven _at_ nchc org tw> 2.3.0-26
- Bug fixed: uncompressed partclone image was not able to be identified before being restored.

* Sat Jul 12 2008 Steven Shiau <steven _at_ nchc org tw> 2.3.0-25
- Bug fixed: filesystem fat is supported by partclone so it should be able to be restored.

* Fri Jul 11 2008 Steven Shiau <steven _at_ nchc org tw> 2.3.0-24
- create-ubuntu-live was updated for intrepid. However, due to this "grep bug" https://bugs.launchpad.net/bugs/241990, the created Intrepid live won't work with Clonezilla.
- "fat 12 fat16 fat32 vfat" was added in partclone_support_fs in drbl-ocs.conf.
- Bug fixed: ocs-get-part-info should tell if the vfat is fat12 or not.


* Thu Jun 19 2008 Steven Shiau <steven _at_ nchc org tw> 2.3.0-23
- /var/lib/apt/lists/lock in clonezilla/drbl/gparted live should be removed. Thanks to Louie Chen.

* Thu Jun 19 2008 Steven Shiau <steven _at_ nchc org tw> 2.3.0-22
- Forcevideo and gparted-live-hook were updated due to some changes in Debian Lenny.

* Wed Jun 18 2008 Steven Shiau <steven _at_ nchc org tw> 2.3.0-21
- Bug fixed: "-e" option was broken. Thanks to Orgad Shaneh for this bug report.

* Sat Jun 14 2008 Steven Shiau <steven _at_ nchc org tw> 2.3.0-20
- When the rate report goes wrong, ask for pressing enter to continue.

* Sat Jun 14 2008 Steven Shiau <steven _at_ nchc org tw> 2.3.0-19
- Bug fixed: Failed to parse the log file of partclone to get the rate when TUI output was used.
- Bug fixed: We should not feed swap of LV in multicast clone.

* Fri Jun 13 2008 Steven Shiau <steven _at_ nchc org tw> 2.3.0-18
- Default to turn on TUI output for partclone.

* Thu Jun 12 2008 Steven Shiau <steven _at_ nchc org tw> 2.3.0-17
- 1024x768 resolution option was added in Clonezilla live. Thanks to Scott Ochiltree for this idea.
- Bug fixed: Because Live helper does not deal with the umountfs service when shutdowning/rebooting, we deal with that in Clonezilla live by modifying /etc/init.d/umountfs. Thanks to Scott Ochiltree.
- Bug fixed: LV was not restored due to the variable target_dir was not changed to target_dir_full in restore_logv.

* Fri Jun 06 2008 Steven Shiau <steven _at_ nchc org tw> 2.3.0-16
- Some comments in ocs-functions and ocs-sr were updated.

* Thu Jun 05 2008 Steven Shiau <steven _at_ nchc org tw> 2.3.0-15
- Bug fixed: ocs-functions was not able to list the size of cciss disk size.
- Remove the verbose output messages in cnvt-ocs-dev and create-ocs-tmp-img.
- The function to restore image to different disk/partition name was added.

* Thu May 29 2008 Steven Shiau <steven _at_ nchc org tw> 2.3.0-14
- Improvement: Use --menu instead of --radiolist in ocs-onthefly as much as possible.

* Thu May 29 2008 Steven Shiau <steven _at_ nchc org tw> 2.3.0-13
- Bug fixed: typo in create-ocs-tmp-img was fixed.

* Tue May 27 2008 Steven Shiau <steven _at_ nchc org tw> 2.3.0-12
- Bug fixed: Wrong path and dir when using saveparts in ocs-sr.
- If -ntfs-ok is assigned, use --force for ntfsclone.

* Tue May 27 2008 Steven Shiau <steven _at_ nchc org tw> 2.3.0-11
- Bug fixed: minor typos corrected in ocs-functions.
- New feature: now ocs-sr will prompt the command to run ocs-sr again when using "ocs-sr -x".

* Mon May 26 2008 Steven Shiau <steven _at_ nchc org tw> 2.3.0-10
- Bug fixed: Another ocsmgrd log file was not listed when running drbl-ocs.
- Bug fixed: swap partition maybe in LV only (cnvt-ocs-dev), therefore check if it exists before rename it.
- A program create-ocs-tmp-img was added to create a Clonezilla image, all the partition/LV image files are linked. It is intended to be used to restore the image to other disk.
- Force to load LVM2 module dm-mod in ocs-lvm2-start.

* Sun May 25 2008 Steven Shiau <steven _at_ nchc org tw> 2.3.0-9
- Exe files of partclone were renamed as partclone.$FS, so ocs-functions and ocs-onthefly were updated.

* Sat May 24 2008 Steven Shiau <steven _at_ nchc org tw> 2.3.0-8
- Do not load system locale setting since we already force to use en_US in ocs-run. This will also fix the bug: http://sourceforge.net/forum/message.php?msg_id=4975138 (/etc/rc1.d/S19ocs-run: line 58: ocs-sr command not found). Thanks to Xandraius.
- Bug fixed: ocsmgrd log file was not listed when running drbl-ocs.

* Thu May 22 2008 Steven Shiau <steven _at_ nchc org tw> 2.3.0-7
- Forcevideo and gl-choose-lang were updated for GParted live.

* Tue May 20 2008 Steven Shiau <steven _at_ nchc org tw> 2.3.0-6
- Improve the selection using "menu" of dialog when mounting local dev as /home/partimage in prep-ocsroot.
- Remove X configure in drbl-live-hook. A package grandr was added.

* Mon May 19 2008 Steven Shiau <steven _at_ nchc org tw> 2.3.0-5
- grandr was added in GParted live (create-gparted-live).

* Mon May 19 2008 Steven Shiau <steven _at_ nchc org tw> 2.3.0-4
- Bug fixed: live-hook/ocs-live.conf is renamed as live-hook/ocs-live-hook.conf, should change that in gparted live hook.
- Forcevideo was updated to avoid the message: "md5sum: /etc/X11/xorg.conf: No such file or directory".
- Packages gconf2-common gconf2 libgconf2-4 should not be removed n gparted-live-hook since grandr need them.

* Mon May 19 2008 Steven Shiau <steven _at_ nchc org tw> 2.3.0-3
- Some comments and prompts were updated in ocs-live-dev.
- live-hook/ocs-live.conf is renamed as live-hook/ocs-live-hook.conf to avoid confusion.
- Keep locales for ja_JP.UTF-8 and fr_FR.UTF-8 in drbl/clonezilla live.
- Use full path command to run with bterm in ocs-live-run-menu.

* Fri May 16 2008 Steven Shiau <steven _at_ nchc org tw> 2.3.0-2
- Bug fixed: S19ocs-run should use "clonezilla" instead of "ocs".

* Thu May 15 2008 Steven Shiau <steven _at_ nchc org tw> 2.3.0-1
- /usr/share/locale/* are kept in Clonezilla live and GParted live now.
- File kbdconf-bterm was renamed as ocs-kbdconf-bterm.
- Fine tune the programs: ocs-live-run-menu, drbl-langchooser, S05kbd-conf, ocs-kbdconf-bterm
- File resize_part was renamed as ocs-resize-part.
- File makeboot.sh was renamed as ocs-makeboot.
- File get_part_info was renamed as ocs-get-part-info.
- File ocs was renamed as clonezilla since ocs will conflict with other package.
- Files lvm2-start.sh and lvm2-stop.sh were moved from package drbl and renamed as ocs-lvm2-start and ocs-lvm2-stop, respectively.
- File socket.pl was moved from package drbl here and renamed as ocs-socket.
- File drbl-chnthn is renamed as ocs-chnthn.
- File drbl-chnthn-functions is renamed as ocs-chnthn-functions.
- Bug fixed: extra shift was removed in --extra-boot-param in ocs-iso. Thanks to Orgad Shaneh.
- Typo fixed: Was 640x640 in ocs-live-boot-menu. Thanks to Orgad Shaneh.

* Tue May 13 2008 Steven Shiau <steven _at_ nchc org tw> 2.2.5-14
- Japanese and French languages options were added.
- ocs-functions was updated due to program langchooser was renamed as drbl-langchooser.

* Sun May 11 2008 Steven Shiau <steven _at_ nchc org tw> 2.2.5-13
- Bug fixed: ocs-onthefly failed to clone disk hda to disk hdb remotely.
- Bug fixed: ocs-onthefly should not automatically create swap partition. 

* Sat May 10 2008 Steven Shiau <steven _at_ nchc org tw> 2.2.5-12
- Bug fixed: harddisk serial number might be shown with white space for IDE device, which made dialog/whiptail fail.

* Fri May 09 2008 Steven Shiau <steven _at_ nchc org tw> 2.2.5-11
- Parameters of ocs-onthefly were modified to be the same with ocs-sr, i.e. -k/-k1/-k2, and -r.
- By default, we back to use partimage instead of partclone in ocs-onthefly due to some problems with xfs.
- xfs and jfs growing functions were added in resize_part.

* Wed May 07 2008 Steven Shiau <steven _at_ nchc org tw> 2.2.5-10
- Bug fixed: harddisk serial number might be shown with white space, which made dialog/whiptail fail.

* Wed May 07 2008 Steven Shiau <steven _at_ nchc org tw> 2.2.5-9
- ocs-onthefly was updated with language files.

* Wed May 07 2008 Steven Shiau <steven _at_ nchc org tw> 2.2.5-8
- Some codes about mounting iSCSI dev were added in prep-ocsroot, however, not ready.
- gPXE boot option was added in Clonezilla live boot menu.
- Put makr " for cifs usename in prep-ocsroot.
- ocs-onthefly was improved by adding a function to clone small disk to larger one.
- Bug fixed: ocs-onthefly failed to clone 2nd and the rest of LV remotely, due to the file descriptor problem.
- Bug fixed: LVM multicast restoring failed for partclone image.  
- Use file descriptor 3 for LV restoring in ocs-functions.

* Fri May 02 2008 Steven Shiau <steven _at_ nchc org tw> 2.2.5-7
- create-gparted-live was updated for GParted 0.3.7: hal package was added. Default to use lenny since gparted 0.3.7 requires hal-lock which does not exist in Etch.
- Network drivers were kept in GParted live.

* Tue Apr 29 2008 Steven Shiau <steven _at_ nchc org tw> 2.2.5-6
- Harddisk serial number was added in the info list.

* Sun Apr 27 2008 Steven Shiau <steven _at_ nchc org tw> 2.2.5-5
- Bug fixed: Dialog log menu problem in ocs-onthefly.

* Sun Apr 27 2008 Steven Shiau <steven _at_ nchc org tw> 2.2.5-4
- Update some descriptions in ocs-sr and ocs-onthefly.

* Sun Apr 27 2008 Steven Shiau <steven _at_ nchc org tw> 2.2.5-3
- Use update-rc.d instead of copying files into /etc/rcS.d/ directly.

* Fri Apr 25 2008 Steven Shiau <steven _at_ nchc org tw> 2.2.5-2
- *-pt.parted was not converted in cnvt-ocs-dev.
- ocs-expand-mbr-pt was refined, with -b|--batch option added.
- Function usage was added in create-cciss-mapping.

* Thu Apr 24 2008 Steven Shiau <steven _at_ nchc org tw> 2.2.5-1
- resize partition was moved to before grub install.
- A new program ocs-expand-mbr-pt was added to expand partition table of target disk. Now it's possible to clone small disk to larger disk proportionally (-k1 option) with filesystem matchs partition size.

* Tue Apr 22 2008 Steven Shiau <steven _at_ nchc org tw> 2.2.4-61
- Bug fixed: When checking swap or Solaris partition (ID=82), should not detected the local partition. Use the parted output info instead.

* Mon Apr 21 2008 Steven Shiau <steven _at_ nchc org tw> 2.2.4-60
- ocs-related-srv was updated for Mandriva 2008.1, since now the service is nfs-common instead of nfslock.
- Minor changed in ocs-functions.

* Sun Apr 20 2008 Steven Shiau <steven _at_ nchc org tw> 2.2.4-59
- Prompt in Forcevideo-drbl-live was updated.

* Sat Apr 19 2008 Steven Shiau <steven _at_ nchc org tw> 2.2.4-58
- A script to config X was added for drbl live (Forcevideo-drbl-live).

* Sat Apr 19 2008 Steven Shiau <steven _at_ nchc org tw> 2.2.4-57
- keymap and X config were added in rcS.d in drbl live.

* Fri Apr 18 2008 Steven Shiau <steven _at_ nchc org tw> 2.2.4-56
- Bug fixed: In DRBL live, /tftpboot/node_root/bin/hostname was deconfigured by lh_chroot_hostname. We have to move /tftpboot/node_root/bin/hostname.orig as /tftpboot/node_root/bin/hostname.

* Thu Apr 17 2008 Steven Shiau <steven _at_ nchc org tw> 2.2.4-55
- -G has higher (from partition table) priority than -g (from kernel) for sfdisk to dump harddrive geometry in ocs-functions (https://sourceforge.net/forum/message.php?msg_id=4902424). Thanks to Orgad Shaneh for this idea.
- Bug fixed: When /home/partimag is sshfs, the prompt message in prep-ocsroot was not correct in clonezilla live.

* Mon Apr 14 2008 Steven Shiau <steven _at_ nchc org tw> 2.2.4-54
- By default we turn on batch mode for resize_part in ocs-functions.
- Do not put EtchAndAHalf in the apt sources.list in those create-*-live.
- In DRBL live, /lib/udev/vol_id is linked to /sbin/vol_id.

* Sun Apr 13 2008 Steven Shiau <steven _at_ nchc org tw> 2.2.4-53
- Prompt message was updated in prep-ocsroot.
- Rewrite some parts of ftpfs to test curlftpfs in prep-ocsroot. ftpfs is still disabled in prep-ocsroot.
- Those files create-*-live (Etch based) now can use kernel 2.6.24-etchnhalf.1 and aufs.

* Sun Apr 13 2008 Steven Shiau <steven _at_ nchc org tw> 2.2.4-52
- Make those log files size 0 but keep them in those live images, otherwise if we clean them, some daemon will complain.

* Fri Apr 11 2008 Steven Shiau <steven _at_ nchc org tw> 2.2.4-51
- A dummy file /var/log/dmesg was preseeded to avoid some daemon complaining.
- Sleep 1 sec before gparted is started in gparted live.
- Bug fixed: When swap partitions number > 2, and in /dev/[hs]d10 or more, restorartion failed. Thanks to frankiehung for reporting this bug.

* Wed Apr 09 2008 Steven Shiau <steven _at_ nchc org tw> 2.2.4-50
- "noprompt" was added for live USB.
- create-*-live now all use live-initramfs instead of casper.
- All the auto login accounts in gparted/clonezilla/drbl live are "user" now. No more "casper" or "ubuntu". Since it's confusing to use acccount "casper" while it's live-initramfs, not casper.

* Tue Apr 08 2008 Steven Shiau <steven _at_ nchc org tw> 2.2.4-49
- GParted live maintainer is listed in boot menu in gparted live.
- Hints were updated in create-ubuntu-live.

* Mon Apr 07 2008 Steven Shiau <steven _at_ nchc org tw> 2.2.4-48
- /lib/modules/$KVER/lib should not be removed in gparted live hook, in Lenny we need lib/zlib_*/ for isofs. Thanks to Louie Chen.

* Mon Apr 07 2008 Steven Shiau <steven _at_ nchc org tw> 2.2.4-47
- Show more steps in Forcevideo for gparted live.

* Sun Apr 06 2008 Steven Shiau <steven _at_ nchc org tw> 2.2.4-46
- create-gparted-live, create-debian-live, create-drbl-live and create-ubuntu-live now are based on live-helper 1.0-a42.

* Sat Apr 05 2008 Steven Shiau <steven _at_ nchc org tw> 2.2.4-45
- hardy_release_kernel_ver_def="2.6.24-14" in create-ubuntu-live.
- For lenny, mksquashfs dropped -nolzma, so rm this opton in create-gparted-live.
- Set numberlock on when booting for drbl/clonezilla/gparted live.

* Tue Apr 01 2008 Steven Shiau <steven _at_ nchc org tw> 2.2.4-44
- Bug fixed: /usr/sbin and /sbin should be in the PATH in gparted live.

* Sun Mar 29 2008 Steven Shiau <steven _at_ nchc org tw> 2.2.4-43
- Use a smaller font ttf-arphic-newsung instead of ttf-arphic-uming in create-gparted-live.
- An option of port for sshfs was added in prep-ocsroot. Thanks to Rob Wynne for this idea.
- Allow nonempty mountpoint in sshfs in clonezilla.

* Fri Mar 28 2008 Steven Shiau <steven _at_ nchc org tw> 2.2.4-42
- mtools, pciutils, discover1, xresprobe and mdetect were added in gparted live.

* Thu Mar 27 2008 Steven Shiau <steven _at_ nchc org tw> 2.2.4-41
- Use live-initramfs instead of casper in create-gparted-live.
- Bug fixed: keymap was not set in X as system keymap in gparted live.

* Wed Mar 26 2008 Steven Shiau <steven _at_ nchc org tw> 2.2.4-40
- Bug fixed: https://sourceforge.net/forum/message.php?msg_id=4861197. Thanks to Francisco Gonzalez and Rob Wynne for reporting this bug.
- Bug fixed: swappt-*.info was not converted by cnvt-ocs-dev.

* Mon Mar 24 2008 Steven Shiau <steven _at_ nchc org tw> 2.2.4-39
- Bug fixed: S99start-ocs-live was missed in /etc/rcS.d/ in clonezilla live.

* Mon Mar 24 2008 Steven Shiau <steven _at_ nchc org tw> 2.2.4-38
- Bug fixed: regression in create-ubuntu-live.
- Bug fixed: space missed in ocs-live-hook-functions.

* Sun Mar 23 2008 Steven Shiau <steven _at_ nchc org tw> 2.2.4-37
- GParted locales are kept in filesystem.squashfs in gparted live.
- Language and keymap selection were included in gparted live.
- Some Asian fonts were added in gparted live.

* Fri Mar 21 2008 Steven Shiau <steven _at_ nchc org tw> 2.2.4-36
- create-gparted-live is ready for Lenny-based. Thanks to Louie Chen.

* Fri Mar 21 2008 Steven Shiau <steven _at_ nchc org tw> 2.2.4-35
- Bug fixed: sda10, sda11... were not mapped for the partition /dev/cciss/c0d0p10... Thanks to Bob Dingman for this bug report.
- --includes "$ocs_live_script_dir" was removed in lh_config param in create-debian-live, create-drbl-live and create-gparted-live since we copy it config/chroot_local-includes.
- /doc is excluded in those create-*-live and ocs-iso/ocs-live-dev.
- Live hook files are in /chroot/live-hook-dir instead of / in chroot.
- ocs-srv-live-hook was renamed as drbl-live-hook.
- create-gparted-live is ready for Lenny-based. Thanks to Louie Chen.

* Wed Mar 19 2008 Steven Shiau <steven _at_ nchc org tw> 2.2.4-34
- Set LH_MEMTEST=disabled, i.e. no memtest from debian or ubuntu when creating drbl/clonezilla live, we will use the one from drbl since it's newer.

* Wed Mar 19 2008 Steven Shiau <steven _at_ nchc org tw> 2.2.4-33
- An option dirty_hacking_remove_files_for_ocs_live was added in ocs-live.conf so that when we create clonezilla live template those man/doc files can be removed. By default we will remove man/doc files in Clonezilla live now.

* Wed Mar 19 2008 Steven Shiau <steven _at_ nchc org tw> 2.2.4-32
- A function gen_proc_partitions_map_file was added in ocs-functions and it was refined.

* Tue Mar 18 2008 Steven Shiau <steven _at_ nchc org tw> 2.2.4-31
- zh_TW boot menu for syslinux was removed in gparted live.
- ocs-functions was updated with more prompts when target disk is not found.
- More info about disk or partition were added before saving or restoring an image.

* Mon Mar 17 2008 Steven Shiau <steven _at_ nchc org tw> 2.2.4-30
- Install xserver-xorg-video-all in gparted live.
- Typos fixed: makeboot.exe should be makeboot.bat in the prompt of create-drbl-live and ocs-live-dev.
- A parameter -s was added to ocs-live-boot-menu.

* Sat Mar 15 2008 Steven Shiau <steven _at_ nchc org tw> 2.2.4-29
- memtest from drbl instead of debian repository is included in gparted live now.

* Sat Mar 15 2008 Steven Shiau <steven _at_ nchc org tw> 2.2.4-28
- Bug fixed: /opt/drbl/setup/files/gparted was not included.

* Sat Mar 15 2008 Steven Shiau <steven _at_ nchc org tw> 2.2.4-27
- Set hardy_release_kernel_ver_def="2.6.24-12" in create-ubuntu-live.
- Some files to create gparted live were added (not finished).
- ocs-live-boot-menu can create menus for drbl live, clonezilla live and gparted live now.

* Sun Mar 09 2008 Steven Shiau <steven _at_ nchc org tw> 2.2.4-26
- Umount chroot/dev/pts before create ubuntu live.
- create-drbl-live is based on live helper now.
- syslinux related files are in /syslinux now for clonezilla live or drbl live zip.

* Thu Mar 06 2008 Steven Shiau <steven _at_ nchc org tw> 2.2.4-25
- Bug fixed: Restoring cciss dev was broken.

* Wed Mar 05 2008 Steven Shiau <steven _at_ nchc org tw> 2.2.4-24
- Show "Clonezilla live version" instead of "Version" in clonezilla live boot menu.

* Wed Mar 05 2008 Steven Shiau <steven _at_ nchc org tw> 2.2.4-23
- Prompt to insert USB flash drive in prep-ocsroot if clonezilla image home is in local dev.

* Wed Mar 05 2008 Steven Shiau <steven _at_ nchc org tw> 2.2.4-22
- Bug fixed: For aufs, prep-ocsroot should show it's writable RAM disk.

* Wed Mar 05 2008 Steven Shiau <steven _at_ nchc org tw> 2.2.4-21
- release_kernel_ver will be automatically get from repository.
- Two parameters (-m|--mirror-url, -s|--mirror-security-url) were added in create-ubuntu-live.
- Bug fixed: /opt/drbl/sbin/ocs-live-run-menu permission shoud be checked by sudo in ocs-live-hook-functions.
- Now ocs-live-dev will use syslinux.exe and makeboot.bat from DRBL, no more downloading and no more makeboot.exe.

* Mon Mar 03 2008 Steven Shiau <steven _at_ nchc org tw> 2.2.4-20
- hardy_release_kernel_ver="2.6.24-11" in create-ubuntu-live.
- A new option "-x, --extra-boot-param" was added in ocs-iso and ocs-live-dev.

* Sun Mar 02 2008 Steven Shiau <steven _at_ nchc org tw> 2.2.4-19
- -t|--batch was added in create-ubuntu-live.
- Bug fixed: On Ubuntu 7.10 with newer mkisofs, recovery CD was buggy without extra / in ocs-iso.

* Wed Feb 27 2008 Steven Shiau <steven _at_ nchc org tw> 2.2.4-18
- Prompt messages in Clonezilla live boot menu were updated.
- More prompt about [sh]d[a-z] descriptions in clonezilla dialog were added.
- hardy_release_kernel_ver="2.6.24-10" in create-ubuntu-live.

* Sat Feb 23 2008 Steven Shiau <steven _at_ nchc org tw> 2.2.4-17
- memtest in clonezilla live now is from DRBL, not Debian.
- ocs-iso and ocs-live-dev were refined.

* Fri Feb 22 2008 Steven Shiau <steven _at_ nchc org tw> 2.2.4-16
- Bug fixed: When "ocs-iso -s" or "ocs-live-dev -c -s" was run in Clonezilla live, etherboot and freedos image were not copied. Thanks to Spiros Georgaras.
- Suppress the error messages if /etc/live.conf can not be grepped in function update_build_system_in_etc_live_conf in ocs-live-hook-functions.

* Wed Feb 20 2008 Steven Shiau <steven _at_ nchc org tw> 2.2.4-15
- Descriptions in the boot menu were modified.

* Wed Feb 20 2008 Steven Shiau <steven _at_ nchc org tw> 2.2.4-14
- Descriptions in the boot menu were modified.

* Wed Feb 20 2008 Steven Shiau <steven _at_ nchc org tw> 2.2.4-13
- Set hardy_release_kernel_ver="2.6.24-8" in create-ubuntu-live.
- Show more info when chosing disk or partition in savedisk or saveparts.
- Add more specific descriptions and an option for 640x480 VGA mode in ocs-live-boot-menu.

* Sun Feb 17 2008 Steven Shiau <steven _at_ nchc org tw> 2.2.4-12
- LVM2 will be forced to start when running grub-install if /root is in LVM2 LV.

* Thu Feb 14 2008 Steven Shiau <steven _at_ nchc org tw> 2.2.4-11
- Bug fixed: If clonezilla image is on Samba disk, LVM restoration will fail. Thanks to Thanks to Gerald HERMANT <ghermant _at_ astrel fr> for reporting this bugs.

* Sun Feb 10 2008 Steven Shiau <steven _at_ nchc org tw> 2.2.4-10
- create-ubuntu-live was updated for newer kernel in Ubuntu 8.04 beta.
- -k is checked when restoreparts in ocs-sr and dcs.
- Partitioin will be checked if it exists before restoring image on it.

* Fri Feb 08 2008 Steven Shiau <steven _at_ nchc org tw> 2.2.4-9
- Prompt was updated in create-ubuntu-live.

* Mon Feb 04 2008 Steven Shiau <steven _at_ nchc org tw> 2.2.4-8
- create-ubuntu-live can use live-helper_1.0~a37 from Debian Sid now.
- By default, we create hardy live in create-ubuntu-live.

* Sat Feb 02 2008 Steven Shiau <steven _at_ nchc org tw> 2.2.4-7
- create-ubuntu-live was updated for hostanme.
- Secondary GPT will be saved and restored.

* Thu Jan 31 2008 Steven Shiau <steven _at_ nchc org tw> 2.2.4-6
- Clonezilla live ubuntu based now uses generic kernel instead of i386 (create-ubuntu-live).
- The content of file parts in clonezilla image is used for disk restoration instead of the results from [hs]dx-pt.sf (ocs-functions).
- Use set command instead of toggle of parted in ocs-create-gpt.
- ocs-create-gpt was updated for partition name with spaces.
- Use dd to backup and restore GPT in ocs-functions instead of parted, since GUID in GPT is unique.

* Thu Jan 24 2008 Steven Shiau <steven _at_ nchc org tw> 2.2.4-5
- Comments in ocs-onthefly was updated.
- If $LIVE_MEDIA is not found, not exit, just warning in ocs-functions. Since it's maybe run in ocs-onthefly.
- When saving partitions, the partition from which disk will be shown in ocs-sr.

* Wed Jan 23 2008 Steven Shiau <steven _at_ nchc org tw> 2.2.4-4
- More mechanism was added in ocs-create-gpt.

* Sun Jan 20 2008 Steven Shiau <steven _at_ nchc org tw> 2.2.4-3
- drbl.conf was put into hook dir in create-ubuntu-live.
- An /etc/fstab will be touched in ocs-live-hook for debian/ubuntu live.
- Variable BUILD_SYSTEM in /etc/live.conf in chroot will be updated in hooks.
- create-ubuntu-live was updated so that it's possible to run for hardy.
- Typo fixed: For NFS mount, "Mount Samba server" was fixed as "Mount NFS server" in prep-ocsroot.
- Bug fixed: Custom LiveCD failed in some case. (https://sourceforge.net/forum/message.php?msg_id=4706371) Thanks to ser_kan and micahboggs.
- A New program ocs-create-gpt was added.
- Codes to deal with gpt partition was added in ocs-functions.

* Sun Jan 05 2008 Steven Shiau <steven _at_ nchc org tw> 2.2.4-2
- Partclone was installed when creating debian/ubuntu template for clonezilla-live.
- Only when /sbin/start-stop-daemon.REAL exists, we will run apt-get -y --purge remove cdebootstrap-helper-diverts.

* Sun Jan 05 2008 Steven Shiau <steven _at_ nchc org tw> 2.2.4-1
- An experimental option -q2 for clonezilla was added (Priority: ntfsclone, partclone > partimage > dd).
- An global variable partclone_support_fs was added in drbl-ocs.conf.
- Partclone was added for hfs+, reiser4, ext2, ext3 and reiserfs. Now we can clone Intel Mac efficiently.
- An helper file ocs-rm-win-swap-hib was added to clean swap and hibernation files in M$ windows system before saving. Thanks to Kristof Vansant for this idea.
- Two more options -t1|--restore-raw-mbr and -rm-win-swap-hib|--rm-win-swap-hib were added for drbl-ocs and ocs-sr.

* Sun Dec 30 2007 Steven Shiau <steven _at_ nchc org tw> 2.2.3-18
- ocs-functions was polished. More functions were used.
- ocs-run was polished.
- Some codes related about partclone (especially clone.hfsp) were added in ocs-functions. By default it won't run.

* Sat Dec 29 2007 Steven Shiau <steven _at_ nchc org tw> 2.2.3-17
- Clonezilla version number is shown in the boot menu. Thanks to evilmrb for this idea.
- Help messages in create-ubuntu-live were updated.

* Fri Dec 28 2007 Steven Shiau <steven _at_ nchc org tw> 2.2.3-16
- Test /etc/modprobe.d/blacklist-framebuffer before modifying it.
- append username=ubuntu in create-ubuntu-live. Thanks to Louie Chen.

* Fri Dec 28 2007 Steven Shiau <steven _at_ nchc org tw> 2.2.3-15
- Prompt in create-ubuntu-live was updated.
- A comment was added for /etc/initramfs-tools/modules in live-initramfs.
- To avoid this bug: https://bugs.launchpad.net/ubuntu/+source/initramfs-tools/+bug/129910 in clonezilla live.

* Thu Dec 27 2007 Steven Shiau <steven _at_ nchc org tw> 2.2.3-14
- Bug fixed: For clonezilla live based on Ubuntu, modules fbcon and vesafb should be included in live-initramfs if they are modules (especially in Ubuntu).

* Wed Dec 26 2007 Steven Shiau <steven _at_ nchc org tw> 2.2.3-13
- Bug fixed: LVM device file was not converted by cnvt-ocs-dev.
- create-ubuntu-live should be ready for Ubuntu 7.10 with some bug fixed packages in live-experimental in DRBL repository.

* Tue Dec 25 2007 Steven Shiau <steven _at_ nchc org tw> 2.2.3-12
- Improvement: add more param for failsafe mode in ocs-live-boot-menu.
- Since if the template iso for clonezilla live is built from Ubuntu, we have to force to add username=ubuntu in the isolinux.cfg. Otherwise boot will fail.

* Mon Dec 24 2007 Steven Shiau <steven _at_ nchc org tw> 2.2.3-11
- Bug fixed: empty dir $ocsroot will be removed first if we want to make a link in the "dirname $ocsroot".

* Mon Dec 24 2007 Steven Shiau <steven _at_ nchc org tw> 2.2.3-10
- Test if /etc/event.d exists or not before modifying them in ocs-live-hook-function.
- Improvement: live helper from sid using /live instead of /casper for system files. ocs-iso and ocs-live-dev will automatically find the path.
- Now live boot param will be parsed from template iso so that ocs-iso/ocs-live-dev can assign the right boot param (Ex: boot=live union=aufs).

* Sat Dec 22 2007 Steven Shiau <steven _at_ nchc org tw> 2.2.3-9
- The filename of kernel and initrd are searched, not fixed in Clonezilla live.
- Apply the solution from https://bugs.launchpad.net/ubuntu/+source/upstart/+bug/65230 to fix the bug about login start too early in ubuntu live.
- Bug fixed: LIVE_MEDIA initial value should be none.

* Fri Dec 21 2007 Steven Shiau <steven _at_ nchc org tw> 2.2.3-8
- Better codes for finding $LIVE_MEDIA in clonezilla live.
- Put S99start-ocs-live in rcS.d instead of rc2.d because of Ubuntu in Clonezilla live.

* Fri Dec 21 2007 Steven Shiau <steven _at_ nchc org tw> 2.2.3-7
- S[0-9][0-9]* scripts were updated with $LIVE_MEDIA mechanism in clonezilla live.

* Thu Dec 20 2007 Steven Shiau <steven _at_ nchc org tw> 2.2.3-6
- Bug fixed: "run-parts $OCS_PRERUN_DIR" should be run in task_preprocessing in  ocs-functions.

* Thu Dec 20 2007 Steven Shiau <steven _at_ nchc org tw> 2.2.3-5
- Bug fixed: *_Packages under /var/lib/apt/lists/ are removed in the last in live hook.

* Thu Dec 20 2007 Steven Shiau <steven _at_ nchc org tw> 2.2.3-4
- Bug fixed: kernel & initrd are in /casper now in ocs-live-dev.
- Bug fixed: memtest, fdos menu were not on created clonezilla live.
- Prompt was updated in prep-ocsroot.
- Use "dpkg-reconfigure console-data" instead of kbd-config.
- Put most of the boot-related images in /casper in clonezilla live.
- Improvement: vmlinuz and initrd in /boot in filesystem.squashfs are not necessary for Live CD and USB stick, so removed. This will reduce file size by about 7 MB. Thanks to Louie Chen.

* Tue Dec 18 2007 Steven Shiau <steven _at_ nchc org tw> 2.2.3-3
- live-package related codes are removed.
- Bug fixed: initrd1.img instead of initrd1.gz in drbl-ocs.conf.

* Tue Dec 18 2007 Steven Shiau <steven _at_ nchc org tw> 2.2.3-2
- kernel & initrd name should be vmlinuz1 and initrd1.gz in clonezilla live.

* Tue Dec 18 2007 Steven Shiau <steven _at_ nchc org tw> 2.2.3-1
- Bug fixed: create-debian-live was broken for kernel in live-experimental. Now it should work for live-helper.

* Tue Dec 18 2007 Steven Shiau <steven _at_ nchc org tw> 2.2.2-7
- Bug fixed: drbl branch was not correct set in create-ubuntu-live.
- Switch to use live helper instead of live package. Thanks to Louie Chen for providing patches.

* Sun Dec 16 2007 Steven Shiau <steven _at_ nchc org tw> 2.2.2-6
- create-ubuntu-live was added (not finished).
- ocs-live-hook-functions was updated with create-ubuntu-live.

* Wed Dec 12 2007 Steven Shiau <steven _at_ nchc org tw> 2.2.2-5
- Bug fixed: start over was broken in clonezilla live.

* Wed Dec 12 2007 Steven Shiau <steven _at_ nchc org tw> 2.2.2-4
- Help messages about -q1|--force-to-use-dd was added.
- Bug fixed: large number of disks and partitions will be listed and can be scrolled down. Thanks to simon (selisha) for reporting this bug. 

* Sun Dec 09 2007 Steven Shiau <steven _at_ nchc org tw> 2.2.2-3
- Show verbose messages when search data and swap partitions.

* Sun Dec 09 2007 Steven Shiau <steven _at_ nchc org tw> 2.2.2-2
- Update clonezilla.spec for drbl dep.

* Sat Dec 08 2007 Steven Shiau <steven _at_ nchc org tw> 2.2.2-1
- A new option was added in Clonezilla: -q1 (--force-to-use-dd) was added. Therefore now we can force to use dd to save any filesystem. Thanks to Justin Fitzhugh from mozilla.com for this idea.

* Fri Dec 07 2007 Steven Shiau <steven _at_ nchc org tw> 2.2.1-54
- A new mechanism is added so that the partition in GPT format can be read, i.e. use the /proc/partitions instead of the output from "sfdisk -d".

* Fri Nov 23 2007 Steven Shiau <steven _at_ nchc org tw> 2.2.1-53
- Bug fixed: hfs+ is not supported by partimage. Function is_partimage_support_fs in ocs-functions was buggy about that. Thanks to Justin Fitzhugh from mozilla.com.

* Tue Nov 13 2007 Steven Shiau <steven _at_ nchc org tw> 2.2.1-52
- Unmount Clonezilla home when starting over in clonezilla live. Thanks to João Santos.
- If ntfsclone_extra_opt is assigned, show the warning.
- Bug fixed: -live-kernel-pkg was an invalid option for create-drbl-live. Thanks to Louie Chen.

* Sun Nov 11 2007 Steven Shiau <steven _at_ nchc org tw> 2.2.1-51
- ocs-srv-live.sh updated with newer drbl-live.sh, i.e. --no-prompt-drbl-live is used when running drbl-live.sh.

* Fri Nov 09 2007 Steven Shiau <steven _at_ nchc org tw> 2.2.1-50
- update spec file.

* Fri Nov 09 2007 Steven Shiau <steven _at_ nchc org tw> 2.2.1-49
- prompt in prep-ocsroot updated.

* Fri Nov 09 2007 Steven Shiau <steven _at_ nchc org tw> 2.2.1-48
- update the comments in /etc/ocs/ocs-live.conf created by ocs-iso and ocs-live-dev.
- bug fixed: partition id=82 will be tested if it's really a swap partition or Solars filesystem.
- now it's possible to force to save ntfs filesystem even if it's dirty if user want to do that.

* Mon Nov 05 2007 Steven Shiau <steven _at_ nchc org tw> 2.2.1-47
- make NICs up before using lshw in ocs-live-netcfg.

* Mon Nov 05 2007 Steven Shiau <steven _at_ nchc org tw> 2.2.1-46
- warning messages of $msg_option_k_is_not_chosen_part_table_will_be_recreated" is only shown in restoreparts.

* Mon Nov 05 2007 Steven Shiau <steven _at_ nchc org tw> 2.2.1-45
- prompt partition table is recreated if -k is not chosen when restoring in clonezilla live.

* Mon Nov 05 2007 Steven Shiau <steven _at_ nchc org tw> 2.2.1-44
- sort the network device in ocs-live-netcfg.
- prompt partition table is recreated if -k is not chosen when restoring.

* Sun Nov 04 2007 Steven Shiau <steven _at_ nchc org tw> 2.2.1-43
- prompt updated.

* Sun Nov 04 2007 Steven Shiau <steven _at_ nchc org tw> 2.2.1-42
- prompt updated.

* Sun Nov 04 2007 Steven Shiau <steven _at_ nchc org tw> 2.2.1-41
- update prompt when clone is finished in clonezilla live.

* Sun Nov 04 2007 Steven Shiau <steven _at_ nchc org tw> 2.2.1-40
- "--fast" was added for gzip compression in clonezilla.
- show ethx link status and model in ocs-live-netcfg. Thanks to Les Mikesell for this idea.
- if network is not configured, ocs-live-netcfg will ask if run again.

* Sun Nov 04 2007 Steven Shiau <steven _at_ nchc org tw> 2.2.1-39
- Prompt the message to reboot/shutdown properly in clonezilla live.

* Thu Nov 01 2007 Steven Shiau <steven _at_ nchc org tw> 2.2.1-38
- bug fixed: The option to back to main menu of clonezilla was not working.

* Thu Nov 01 2007 Steven Shiau <steven _at_ nchc org tw> 2.2.1-37
- update dialog title in get image name function.

* Thu Nov 01 2007 Steven Shiau <steven _at_ nchc org tw> 2.2.1-36
- add an option to back to main menu when clonezilla live finishes.

* Wed Oct 31 2007 Steven Shiau <steven _at_ nchc org tw> 2.2.1-35
- update prompts. 

* Wed Oct 31 2007 Steven Shiau <steven _at_ nchc org tw> 2.2.1-34
- provide a chance to run ntfsfix in clonezilla. 
- show-ocs-live-save-ro-prompt is removed from ocs-functions and ocs-live-help.
- rewrite the prompt for clonezilla live when user want to re-run it again.

* Tue Oct 30 2007 Steven Shiau <steven _at_ nchc org tw> 2.2.1-33
- update custom-ocs.

* Mon Oct 29 2007 Steven Shiau <steven _at_ nchc org tw> 2.2.1-32
- add --no-restore-mbr when restoring in custom-ocs.
- highlight the warning after clonezilla server edition is started in drbl live.
- assign language en_US for drblsrv/drblpush in ocs-srv-live-hook.

* Fri Oct 26 2007 Steven Shiau <steven _at_ nchc org tw> 2.2.1-31
- update prompt for chkdsk in ocs-functions and add ntfsfix in prep-ocsroot. Thanks to João Santos. 

* Fri Oct 26 2007 Steven Shiau <steven _at_ nchc org tw> 2.2.1-30
- put -o force in the end of command ntfs-3g in prep-ocsroot.

* Fri Oct 19 2007 Steven Shiau <steven _at_ nchc org tw> 2.2.1-29
- update prompt in ocs-live-netcfg.
- enter shell instead of closing windows after clonezilla starts in ocs-srv-live.sh. This will avoid udp-sender process is killed by terminal.

* Thu Oct 18 2007 Steven Shiau <steven _at_ nchc org tw> 2.2.1-28
- drbl-live.sh is run with --prepare-ocsroot in ocs-srv-live.sh.

* Thu Oct 18 2007 Steven Shiau <steven _at_ nchc org tw> 2.2.1-27
- minor change: drbl-live.sh is run with --skip-pause-in-the-end in ocs-srv-live.sh. 

* Thu Oct 18 2007 Steven Shiau <steven _at_ nchc org tw> 2.2.1-26
- bug fixed: language file en was forced to load in ocs-srv-live.sh.

* Thu Oct 18 2007 Steven Shiau <steven _at_ nchc org tw> 2.2.1-25
- ocs-srv-live.sh is polished.
- Clonezilla server icon is put in desktop of DRBL live.

* Wed Oct 17 2007 Steven Shiau <steven _at_ nchc org tw> 2.2.1-24
- minor bug fixed in ocs-srv-live-hook.

* Wed Oct 17 2007 Steven Shiau <steven _at_ nchc org tw> 2.2.1-23
- Network card menu won't appear in German in ocs-live-netcfg.
- A mechanism was added to replace kernel mode nfs by unfs or not.
- Remove BuildRequires in clonezilla.spec.

* Tue Oct 16 2007 Steven Shiau <steven _at_ nchc org tw> 2.2.1-22
- portmap and nfs-common are started in drbl/clonezilla live if not started (prep-ocsroot).
- ocs-srv-live.sh was added.

* Mon Oct 15 2007 Steven Shiau <steven _at_ nchc org tw> 2.2.1-21
- Those .desktop files are moved to /opt/drbl/setup/files/misc/desktop-icons/drbl-live (ocs-srv-live-hook).

* Sat Oct 13 2007 Steven Shiau <steven _at_ nchc org tw> 2.2.1-20
- Before using dhclient in ocs-live-netcfg, we create /etc/resolv.conf to suppress the warning. Since /etc/resolv.conf is removed when Debian Live is created by live package.
- in ocs-srv-live-hook, we clean the template node and tarballs: (1) save the space (2) if user uses different subnet for NIC, the template directory (Ex: /tftpboot/nodes/192.168.100.1) and tarball are useless. Since we will re-run drblpush in drbl-live.sh after drbl live boots. They will be created again.

* Fri Oct 12 2007 Steven Shiau <steven _at_ nchc org tw> 2.2.1-19
- --not-add-start-drbl-srvi was used in ocs-srv-live-hook.

* Fri Oct 12 2007 Steven Shiau <steven _at_ nchc org tw> 2.2.1-18
- more options were added in ocs-live-netcfg.

* Thu Oct 11 2007 Steven Shiau <steven _at_ nchc org tw> 2.2.1-17
- 4 params can be assigned as kernel params in Clonezilla live: (1) ocs_lang (for language, ex: en, tw.UTF-8) & ocs_live_keymap (For keyboard, Ex: none) (2) ocs_sr_opt (to be run with ocs-sr) and ocs_onthefly_opt (to be run with ocs-onthefly) in clonezilla live. If one of them is assigned, clonezilla will run ocs-sr or ocs-onthefly according to the param. i.e. the normal interactive mode of clonezilla live won't be run. For example, you can put the following in the boot param: ocs_lang=en ocs_live_keymap=NONE ocs_sr_opt="-g auto -c restoredisk IMAGE1 hda", so when clonezilla live boot, it will use English environment, default (US) keyboard layout, and restore IMAGE1 into hda. Here the IMAGE1 should exist in the clonezilla live media.

* Tue Oct 09 2007 Steven Shiau <steven _at_ nchc org tw> 2.2.1-16
- prep-ocsroot should be run when -o|--normal-menu is used with ocs-iso and ocs-live-dev.

* Tue Oct 09 2007 Steven Shiau <steven _at_ nchc org tw> 2.2.1-15
- add -o|--normal-menu so that even if a clonezilla image is inserted in clonezilla live restored iso, the menu of ocs-sr can show menu of save mode.

* Tue Oct 09 2007 Steven Shiau <steven _at_ nchc org tw> 2.2.1-14
- polish the echo message.
- when -g auto is used, if the partition is ntfs, skip that partition.

* Mon Oct 08 2007 Steven Shiau <steven _at_ nchc org tw> 2.2.1-13
- A patched partimage (from Thomas Tsai) will work for non-32768 blocks per group in ext2/ext3. Therefore the check mechanism check_blocks_per_group_of_ext2_3 is commented.

* Mon Oct 08 2007 Steven Shiau <steven _at_ nchc org tw> 2.2.1-12
- Add another checking mechanism by parted to check if the created partiton is ok or not, since sfdisk with -f won't return correct code (ocs-functions). The existing partition table in disk will also be checked by parted before saving the clonezilla image. Thanks to Barny Sanchez for reporting this bug.
- A mechanism is added to check if the blocks per group in ext2/3 is 32768 or not. If not, show error messages then exit. Ref: http://sourceforge.net/forum/forum.php?thread_id=1833628&forum_id=663168

* Sun Oct 07 2007 Steven Shiau <steven _at_ nchc org tw> 2.2.1-11
- just create 1 client for each ethernet port in drbl live. The cient number is assigned in ocs-live.conf and is applied to drbl-live.sh (it is run to start drbl service after the live cd is booted).

* Sun Oct 07 2007 Steven Shiau <steven _at_ nchc org tw> 2.2.1-10
- set the mlterm bg/fg color in drbl live xfce branch.

* Sat Oct 06 2007 Steven Shiau <steven _at_ nchc org tw> 2.2.1-9
- bug fixed: only with clonezilla installed, we can load variable $DEBIAN_ISO_ETC_PATH_DEF in ocs-srv-live-hook.
- auto login accounts are created in drbl-live.sh instead of ocs-srv-live-hook.

* Fri Oct 05 2007 Steven Shiau <steven _at_ nchc org tw> 2.2.1-8
- clean unnecessary codes in ocs-srv-live-hook.

* Fri Oct 05 2007 Steven Shiau <steven _at_ nchc org tw> 2.2.1-7
- update ocs-live-netcfg. Make dialog look better.
- create the directories $OCS_PRERUN_DIR and $OCS_POSTRUN_DIR in ocs-iso and ocs-live-dev.
- update ocs-srv-live-hook and ocs-live.conf for drbl live. 1 NIC should be able to run DRBL server.
- do not write network config file in drbl live.

* Fri Sep 28 2007 Steven Shiau <steven _at_ nchc org tw> 2.2.1-6
- preset loopback network setting in ocs-live-hook.

* Thu Sep 20 2007 Steven Shiau <steven _at_ nchc org tw> 2.2.1-5
- update comments in ocs-live-netcfg.

* Thu Sep 20 2007 Steven Shiau <steven _at_ nchc org tw> 2.2.1-4
- use more locale outputs in ocs-live-netcfg.

* Thu Sep 20 2007 Steven Shiau <steven _at_ nchc org tw> 2.2.1-3
- format the "space key" hint again.

* Thu Sep 20 2007 Steven Shiau <steven _at_ nchc org tw> 2.2.1-2
- minor change of message in ocs-live-netcfg.
- add a hint to use space key to mark the selection in dcs.

* Wed Sep 19 2007 Steven Shiau <steven _at_ nchc org tw> 2.2.1-1
- typos fixed in comments in ocs-functions.
- A network config program: ocs-netconf added.
- The network config can be done in prep-ocsroot also.
- Bug fixed: swap partition in lvm was not parsed correctly in ocs-onthefly.
- Remove "No network" option in the boot menu in clonezilla live, since now the network setup is done when it's necessary (like sshfs, nfs...).
- The image name is shown in the boot menu when ocs-iso/ocs-live-dev is run with image built in iso/zip.

* Fri Sep 14 2007 Steven Shiau <steven _at_ nchc org tw> 2.2.0-8
- Bug fixed: Another cciss mapping bug fixed.

* Fri Sep 14 2007 Steven Shiau <steven _at_ nchc org tw> 2.2.0-7
- Bug fixed: cciss mapping was fixed.

* Wed Sep 12 2007 Steven Shiau <steven _at_ nchc org tw> 2.2.0-6
- another sample script is added: create-1P-pt-sf, which will automatically create a partition with size = disk size, and the partition ID is ntfs (7).
- minor bug fixed in create-2P-pt-sf.

* Wed Sep 05 2007 Steven Shiau <steven _at_ nchc org tw> 2.2.0-5
- bug fixed: when mounting samba server as clonezilla home, the path should contain only / instead of //. Thanks to Jun-Ye Sun.

* Thu Aug 30 2007 Steven Shiau <steven _at_ nchc org tw> 2.2.0-4
- found_grub_partition should be initialized as nonthing in ocs-functions.

* Wed Aug 29 2007 Steven Shiau <steven _at_ nchc org tw> 2.2.0-3
- bug fixed for grub-install with cciss include (ocs-functions).

* Wed Aug 29 2007 Steven Shiau <steven _at_ nchc org tw> 2.2.0-2
- use "file -Ls" instead of "file" only when finding the image type in ocs-functions.

* Mon Aug 27 2007 Steven Shiau <steven _at_ nchc org tw> 2.2.0-1
- update Makefile for mkswap-uuid.
- bug fixed about clonezilla.spec.
- extract mkswap-uuid from clonezilla, make it as a standalone package.
- remove ocs-srv-reset and related action.
- a sample program is added: create-2P-pt-sf. Put it in /opt/drbl/share/ocs/prerun/ and used with -o0 -k -r, then it can auto create 2 partitions, the size of 1st partition is total disk size - 3 GB, the 2nd partition is swap with 3 GB.

* Mon Aug 27 2007 Steven Shiau <steven _at_ nchc org tw> 2.1.9-2
- add e2fsprogs-devel (uuid/uuid.h), glibc-devel (sys/user.h) and glibc-kernheaders (asm/page.h) in BuildRequires in rpm spec file.

* Mon Aug 27 2007 Steven Shiau <steven _at_ nchc org tw> 2.1.9-1
- cciss raid card is supported. Thanks to Ron Kelley <rkelley _at_ employees org> for providing idea and patches.
- remove unnecessary include files and other junk/extra files in mkswap-uuid.

* Fri Aug 24 2007 Steven Shiau <steven _at_ nchc org tw> 2.1.8-3
- add -y for e2fsck before resizing ext2/3 filesystem.

* Thu Aug 23 2007 Steven Shiau <steven _at_ nchc org tw> 2.1.8-2
- support samba domain in prep-ocsroot.
- update language files.
- add option -o0/-o1 for --run-prerun-dir and --run-postrun-dir.
- move "run prerun" and "run postrun" right after confirmation instead of before it.

* Wed Aug 15 2007 Steven Shiau <steven _at_ nchc org tw> 2.1.8-1
- ocs-function does not need scsi_info_drbl and ide_info_drbl anymore.
- checkInodeForDevice is not required since partimage 0.6.6 can run batchly now.

* Tue Aug 14 2007 Steven Shiau <steven _at_ nchc org tw> 2.1.7-5
- use variables savedisk_preset and saveparts_preset from drbl-ocs.conf in dcs.

* Thu Aug 09 2007 Steven Shiau <steven _at_ nchc org tw> 2.1.7-4
- HALT_REBOOT_OPT="" instead of HALT_REBOOT_OPT="-f -n" in drbl-ocs.conf, since  without a normal soft-shutdown, wake-on-LAN might fail. Thanks to Dave Haakenhout for reporting this bug.

* Thu Aug 09 2007 Steven Shiau <steven _at_ nchc org tw> 2.1.7-3
- add -p when making directory in ocs-functions.

* Fri Aug 03 2007 Steven Shiau <steven _at_ nchc org tw> 2.1.7-2
- add warning about file name limitation with run-parts in postrun

* Fri Aug 03 2007 Steven Shiau <steven _at_ nchc org tw> 2.1.7-1
- bug fixed: $drblroot/$node_ip/etc/ocs/ is created if it's full drbl/clonezilla mode so that the ocs_param.conf will exist in client. It's easier to debug clonezilla in client.

* Wed Aug 01 2007 Steven Shiau <steven _at_ nchc org tw> 2.1.6-10
- comment ftpfs in prep-ocsroot, since curlftpfs is not stable with partimage/ntfsclone.

* Thu Jul 19 2007 Steven Shiau <steven _at_ nchc org tw> 2.1.6-9
- use shorter directory name /images instead of /work/smb (for samba) or /home/partimage (for ftpfs) in prep-ocsroot.
- add option -b in resize_part.

* Wed Jul 18 2007 Steven Shiau <steven _at_ nchc org tw> 2.1.6-8
- update language files. Add more comments about GNU/Linux device name to M$ windows device names.

* Wed Jul 18 2007 Steven Shiau <steven _at_ nchc org tw> 2.1.6-7
- bug fixed: device description was wrong when running prep-ocsroot in Clonezilla live (booting from CD).
- use --menu instead of --radiolist in most of the dialog programs.
- no more using basename and dirname in drbl-ocs.conf.
- debian iso template url and filename can be assigned in ocs-iso and ocs-live-dev.
- add ftpfs in prep-ocsroot.

* Tue Jul 03 2007 Steven Shiau <steven _at_ nchc org tw> 2.1.6-6
- add option -ntfs-ok|--ntfs-ok for drbl-ocs and ocs-sr. With this option, we can force to save the partition or aviod the false alarm caused by ntfsresize.

* Sat Jun 30 2007 Steven Shiau <steven _at_ nchc org tw> 2.1.6-5
- Bug fixed: Disable kudzu to telinit 3 also if it's in rc1.d for clonezilla (ocs-related-srv)

* Fri Jun 29 2007 Steven Shiau <steven _at_ nchc org tw> 2.1.6-4
- Bug fixed: Disable kudzu to telinit 5 if it's in rc1.d for clonezilla (ocs-related-srv)
- Add comments in /etc/ocs-live.conf created by ocs-iso or ocs-live-deb.
- Default to enter command prompt when running "run_post_cmd_when_clone_end choose" after clone. Thanks to Ron Kelley (rkelleyrtp) for this suggestion.

* Wed Jun 27 2007 Steven Shiau <steven _at_ nchc org tw> 2.1.6-3
- format the zh_TW.* language variable in clonezilla live (ocs-iso and ocs-live-deb).

* Tue Jun 26 2007 Steven Shiau <steven _at_ nchc org tw> 2.1.6-2
- bug fixed: get_existing_partitions_from_img should not skip mounted partition in the server, since it's nothing to do with that in clients (ocs-functions). Thanks to cyleen2345 _at_ yahoo com tw for reporting this bug.

* Tue Jun 26 2007 Steven Shiau <steven _at_ nchc org tw> 2.1.6-1
- add an option so that a custom-ocs file can be put in clonezilla live.
- a sample program custom-ocs which backup or restore /dev/hda1 to/from /dev/hda5 is in /opt/drbl/sample/custom-ocs.

* Mon Jun 11 2007 Steven Shiau <steven _at_ nchc org tw> 2.1.5-21
- bug fixed: "-s" should not be used as OCS_OPT, which will make debian/ubuntu fail to enter clonezilla mode (select in client). Thanks to kibidouil for reporting this bug.

* Tue Jun 05 2007 Steven Shiau <steven _at_ nchc org tw> 2.1.5-20
- bug fixed: extra dir in /tftpboot/nodes/ should not be created in ocs-functions.

* Tue Jun 05 2007 Steven Shiau <steven _at_ nchc org tw> 2.1.5-19
- Bug fixed: If image is uncompressed and ocsroot is on M$ windows samba server, clonezlla will fail to identify the image format. Thanks to <ericj.tw _at_ gmail.com> for reporting this bug.

* Mon Jun 04 2007 Steven Shiau <steven _at_ nchc org tw> 2.1.5-18
- rpcbind is replaced by portmap (in ocs-related-srv).

* Fri Jun 01 2007 Steven Shiau <steven _at_ nchc org tw> 2.1.5-17
- bug fixed: vfat is added in partimage_support_fs in drbl-ocs.conf. Thanks to Remi Turboult for reportiing this bug.

* Tue May 29 2007 Steven Shiau <steven _at_ nchc org tw> 2.1.5-16
- add an option to use backports repository and an option to assign kernel package in create-debian-repo.

* Fri May 25 2007 Steven Shiau <steven _at_ nchc org tw> 2.1.5-15
- bug fixed: Unable to put the ocs_opt in pxelinux menu file when using Clonezilla box mode and choosing only part of the clients (except 1st one in the list) to save or restore. Thank Dave Haakenhout for reporting this bug. 

* Mon May 21 2007 Steven Shiau <steven _at_ nchc org tw> 2.1.5-14
- bug fixed: when more than 10 partitions, ocs-onthefly failed.

* Mon May 21 2007 Steven Shiau <steven _at_ nchc org tw> 2.1.5-13
- bug fixed: In Ubuntu 6.10, when saving a disk with 10 or more partitions, it will faild. Due to the output sfdisk with 10 or more partitions is not in the standard format. Thanks to Tom Ed (vi0lam0n) for identifying this bug: https://sourceforge.net/forum/message.php?msg_id=4289601

* Mon May 21 2007 Steven Shiau <steven _at_ nchc org tw> 2.1.5-12
- load /etc/ocs/ocs-live.conf to set DIA in ocs-onthefly.

* Mon May 21 2007 Steven Shiau <steven _at_ nchc org tw> 2.1.5-11
- bug fixed: disk to remote disk clone failed in ocs-onthefly.
- bug fixed: resize should only run in the target partition instead of all partitions in ocs-onthefly.

* Fri May 18 2007 Steven Shiau <steven _at_ nchc org tw> 2.1.5-10
- minor bug fixed: create-debian-live prompt.
- umount $output_dev after some commands (like sfdisk -R $output_dev_hd, which will cause gnome/kde to auto mount the partition for USB flash drive) in makeboot.sh.
- use memtest instead of memtest86, since if it's USB stick with FAT filesystem, will be unable to load the memtest file.

* Tue May 15 2007 Steven Shiau <steven _at_ nchc org tw> 2.1.5-9
- add an option not to start network connection in clonezilla live (ocs-live-boot-menu)
- increase the timeout as 30 secs in clonezilla live boot menu.

* Mon May 14 2007 Steven Shiau <steven _at_ nchc org tw> 2.1.5-8
- bug fixed: when disk to disk clone in ocs-onthefly, the "-g auto" should only guess the disk in target disk.
- add an experimental branch in create-debian-live.
- update function ask_time_or_clients_to_wait in ocs-functions.

* Mon May 07 2007 Steven Shiau <steven _at_ nchc org tw> 2.1.5-7
- update prompt when using dd to do local clone for LVM.

* Sun May 06 2007 Steven Shiau <steven _at_ nchc org tw> 2.1.5-6
- rewrite part of ocs-functions with those partition_table related.
- Major bug fixed: grub-install fails if there is a separate boot partition. Now we will mount root partition if there is a separate boot partition before running grub-install (ocs-functions). This only failed in FC6 and CentOS 5.0 or later version (maybe), now no more.
- Use better detection in function find_ocsroot_dev_description() in prep-ocsroot.

* Thu May 03 2007 Steven Shiau <steven _at_ nchc org tw> 2.1.5-5
- update ocs-live-boot-menu, pxemenu will be only created if image exists

* Thu May 03 2007 Steven Shiau <steven _at_ nchc org tw> 2.1.5-4
- update ocs-iso and ocs-live-dev to suppress the error message when copying freedos image.

* Thu May 03 2007 Steven Shiau <steven _at_ nchc org tw> 2.1.5-3
- update ocs-live-dev to suppress the error message when querying drbl-etherboot file.

* Thu May 03 2007 Steven Shiau <steven _at_ nchc org tw> 2.1.5-2
- suppress the error message when querying drbl-etherboot file list in ocs-iso.
- keep opt/drbl/{doc,setup,etc} in create_live_media_opt_drbl_tarball

* Tue May 01 2007 Steven Shiau <steven _at_ nchc org tw> 2.1.5-1
- bug fixed: check_if_input_device_exist should exit if input dev is nothing (ocs-functions).
- ocs-live-save is renamed as ocs-live-general.
- add -x (interactive mode) in ocs-onthefly. 
- MAJOR BUG FIXED: when a stale ocs_opt in pxelinux.cfg/default, drbl-ocs will fail to overwrite the stale ocs_opt if run it again.
- now use /opt/drbl/sbin/ocs to be the default program when choose to use "select-in-client" in clonezilla-start.
- bug fixed: batch mode failed in ocs-sr -b ... Thanks to Alexander Scholler <alexander.scholler _at_ augsburg de>

* Wed Apr 18 2007 Steven Shiau <steven _at_ nchc org tw> 2.1.4-7
- wait for enter press before showing df -h result in prep-ocsroot in skip.
- bug fixed: when ocs_lang is en, LANG should be exported as en_US.UTF-8, otherwise there is zh_TW fonts in dialog (ocs-live-run-menu).
- wait for press enter before exit when ntfs filesystem is found corrupt before saving.

* Fri Apr 13 2007 Steven Shiau <steven _at_ nchc org tw> 2.1.4-6
- do not run reboot/shutdown in ocs-live-restore or ocs-live-save, run them after bterm is done, i.e. in text console. (ocs-live-run-menu)
- do not set root's passwd in drbl/clonezilla live, just follow Debian live. (This can be changed in ocs-live.conf).

* Thu Apr 12 2007 Steven Shiau <steven _at_ nchc org tw> 2.1.4-5
- comment the root_passwd_def to avoid confusion in ocs-live.conf.

* Thu Apr 12 2007 Steven Shiau <steven _at_ nchc org tw> 2.1.4-4
- update prep-ocsroot to provide more infomation.

* Wed Apr 11 2007 Steven Shiau <steven _at_ nchc org tw> 2.1.4-3
- add -l|--drbl-live-branch option for create-drbl-live and create-debian-live.
- add warning message about mounting NTFS partition by ntfs-3g.
- rename ocs-minimal-hook as ocs-live-hook.
- rename dir live-chroot as live-hook.
- now the root passwd of drbl/clonezilla live can be assigned in ocs-live.conf, random password is also supported.

* Tue Apr 10 2007 Steven Shiau <steven _at_ nchc org tw> 2.1.4-2
- /opt/drbl/setup/files/ocs/ocs.d/S30ocs-live-menu is renamed to /opt/drbl/sbin/ocs-live-run-menu
- ocs.d/ is renamed as ocs-live.d/
- now clonezilla live is run in casper login shell (only in tty1) instead of rc2.d/S99ocs-live-run. Therefore we can use different vt (ctrl-alt-f[2-6] to diagnose or whatever you want.

* Mon Apr 09 2007 Steven Shiau <steven _at_ nchc org tw> 2.1.4-1
- bug fixed: /home/casper/Desktop owner should be casper in drbl live.
- typos ms_choose_* fixed as msg_choose_*.
- we can choose to skip lvm in get_input_dev_name in ocs-functions.
- ocs-live and prep-ocsroot is added for clonezilla-live, now with ocs-live it's much easier to mount device/sshfs/smbfs as /home/partimag.
- update ocs-live-hook-functions, using fset to set the flag seen for localepurge.
- update create-debian-live and create-drbl-live to work with stable etch.
- option "-i|--assign-version-no" is added in create-drbl-live, ocs-iso and ocs-live-dev to set DRBL/Clonezilla live version no.
- rename output file name clonezilla-live-usb-*.zip as "clonezilla-live-*.zip in ocs-live-dev.
- ocs-live-save is added to replace ocs-live-save-for-r[ow].

* Fri Apr 06 2007 Steven Shiau <steven _at_ nchc org tw> 2.1.3-6
- show message if UUID and LABEL of swap dev are not found when saving image.
- add turn_off_swap_and_LVM2 before choosing dev to save in ocs-sr.

* Wed Apr 04 2007 Steven Shiau <steven _at_ nchc org tw> 2.1.3-5
- add clean_filesystem_header_in_partition in ocs-functions and ocs-onthefly.

* Tue Apr 03 2007 Steven Shiau <steven _at_ nchc org tw> 2.1.3-4
- bug fixed: blkid might have 2 TYPE: SEC_TYPE="ext2" TYPE="ext3" (get_part_info)
- better method to parse UUID and LABEL for swap dev (ocs-functions)
- add check_partimage_partition_integrity before saving partimage partition.

* Tue Apr 03 2007 Steven Shiau <steven _at_ nchc org tw> 2.1.3-3
- bug fixed: for some version of nc, it's necessary to add -d when receiving data (ocs-onthefly).
- speedup get_part_info.

* Mon Apr 02 2007 Steven Shiau <steven _at_ nchc org tw> 2.1.3-2
- use functions to process LVM clone over network (not ready yet) in ocs-onthefly.

* Thu Mar 29 2007 Steven Shiau <steven _at_ nchc org tw> 2.1.3-1
- not only 1-6, a, b, -b are reserved, but also 0, 7-9, single and s when used for image name.
- bug fixed: ocs-onthefly is broken (LVM support not yet).
- update some prompt in ocs-functions.
- use function to deal with UUID/Label of swap.
- remove function resize_partition in ocs-functions, which is obsolete for a long time, now we use $DRBL_SCRIPT_PATH/sbin/resize_part. 
- use global variable partimage_support_fs in drbl-ocs.conf and ocs-functions.
- bug fixed: it's drbl-partimage, not partimage in required in clonezilla.spec.
- bug fixed: get_part_info can get the filesystem info about LVM now.
- bug fixed: swap LV should not saved with dd, just UUID/Label is saved.
- use function image_save for LVM.

* Fri Mar 23 2007 Steven Shiau <steven _at_ nchc org tw> 2.1.2-31
- bug fixed: /etc/exports should be kept before "apt-get --purge remove nfs-kernel-server" in DRBL live.

* Thu Mar 22 2007 Steven Shiau <steven _at_ nchc org tw> 2.1.2-30
- fix the prompt in ocs-live-save-for-ro. If mount point is a symbolic, not dir, sshfs will complain it's nonempty. Although this is for readonly device (CD), but if user choose to use "toram", then it becomes in the RAM, which is writable (ocs-functions).

* Thu Mar 22 2007 Steven Shiau <steven _at_ nchc org tw> 2.1.2-29
- remove LANG=C.UTF setting in ocs-live-save-for-r[ow].

* Thu Mar 22 2007 Steven Shiau <steven _at_ nchc org tw> 2.1.2-28
- force to create en_US.UTF-8 in ocs-live-hook-functions.

* Thu Mar 22 2007 Steven Shiau <steven _at_ nchc org tw> 2.1.2-27
- force to create locale en_US.UTF-8 if it does not exist in ocs-run, S05kbd-conf, and S30ocs-live-menu.

* Wed Mar 21 2007 Steven Shiau <steven _at_ nchc org tw> 2.1.2-26
- bug fixed: when nfs-kernel-server is removed, --purge is used in ocs-srv-live-hook.

* Wed Mar 21 2007 Steven Shiau <steven _at_ nchc org tw> 2.1.2-25
- bug fixed: unifont can be downloaded correctly in drbl live.

* Wed Mar 21 2007 Steven Shiau <steven _at_ nchc org tw> 2.1.2-24
- add xfs, jfs, fuse moduels for drbl live clients.
- use more variables from drbl.conf in ocs-srv-live-hook.
- boot title renamed as "DRBL Live" instead of "DRBL server live".

* Tue Mar 20 2007 Steven Shiau <steven _at_ nchc org tw> 2.1.2-23
- use variable live_pkg_hook_dir to be prepared for live-helper in drbl-ocs.conf.
- bug fixed: mlterm installation should be done before drblpush in ocs-srv-live-hook.
- do not remove xterm, now we use update-alternatives to set x-terminal-emulator as mlterm.
- add toram option in boot menu for DRBL/Clonezilla live (ocs-live-boot-menu).

* Sun Mar 18 2007 Steven Shiau <steven _at_ nchc org tw> 2.1.2-22
- remove unnecessary file fdos_1440.img in drbl live zip.
- reorg /opt/drbl/setup/files/ocs/live-chroot/, add ocs-live.conf and ocs-live-hook-functions.
- put more info in DRBL-Live-Version inside live CD/zip.
- unifont.bgf now is in /opt/drbl/lib in DRBL and Clonezilla live (was in /opt/lib/).
- unifont.bgf will be downloaded and put in /opt/drbl/lib in DRBL live.

* Fri Mar 16 2007 Steven Shiau <steven _at_ nchc org tw> 2.1.2-21
- each ethernet card provide 40 clients in DRBL live.
- force to load xfs and jfs so that gparted can grow filesystem in gparted in DRBL Live.
- use debconf-communicate to set localepurge in drbl live (ocs-srv-live-hook).

* Wed Mar 14 2007 Steven Shiau <steven _at_ nchc org tw> 2.1.2-20
- some minor bugs fixed.

* Wed Mar 14 2007 Steven Shiau <steven _at_ nchc org tw> 2.1.2-19
- add freedos in DRBL/Clonezilla live boot menu.
- update DEBIAN_ISO_URL in drbl-ocs.conf

* Tue Mar 13 2007 Steven Shiau <steven _at_ nchc org tw> 2.1.2-18
- live-package changed, we have to use code name "testing" instead of "etch", otherwise GPG from DRBL won't be added. The problem is in /usr/share/make-live/scripts/14chroot.sh, it will add apt key for testing and unstable, not etch or sid.

* Tue Mar 13 2007 Steven Shiau <steven _at_ nchc org tw> 2.1.2-17
- add casper-getty in boot param for DRBL live.
- Since account casper works, remove account drbl in DRBL live.
- use boot menu "failsafe mode" instead of "safe mode" in Clonezilla live.
- add locale boot menu (zh_TW) in DRBL live.
- account casper and root password set should be before drblsrv -i and drblpush -i in ocs-srv-live-hook.
- create-ocs-srv-live can create iso or zip file for CD and USB flash drive, respectively.

* Sat Mar 10 2007 Steven Shiau <steven _at_ nchc org tw> 2.1.2-16
- bug fixed: now casper account can be added when drbl live boots.

* Sat Mar 10 2007 Steven Shiau <steven _at_ nchc org tw> 2.1.2-15
- use memtest from drbl, instead of debian live.
- create-ocs-srv-live now also create drbl live zip file.

* Sat Mar 10 2007 Steven Shiau <steven _at_ nchc org tw> 2.1.2-14
- update http url for drbl live.
- add option -t -u in create-ocs-srv-live.

* Fri Mar 09 2007 Steven Shiau <steven _at_ nchc org tw> 2.1.2-13
- use ocs-live-boot-menu -m $image_file for all live creating programs.
- add codes about drbl boot menu in create-ocs-srv-live

* Fri Mar 09 2007 Steven Shiau <steven _at_ nchc org tw> 2.1.2-12
- bug fixed: assign -l 0 for ocs-live-boot-menu in live-hook.

* Fri Mar 09 2007 Steven Shiau <steven _at_ nchc org tw> 2.1.2-11
- we can assign drbl branch in create-ocs-srv-live.
- add "clonezilla live (safe mode)" in ocs-live-boot-menu for clonezilla live.
- use variable VGA_MODE_DEF instead of VGA_MODE in drbl-ocs.conf
- add -e|--title for ocs-live-boot-menu. 

* Thu Mar 08 2007 Steven Shiau <steven _at_ nchc org tw> 2.1.2-10
- use local label "Local operating system in harddrive (if available)"

* Thu Mar 08 2007 Steven Shiau <steven _at_ nchc org tw> 2.1.2-9
- ocs-live reads language setting from /etc/ocs/ocs-live.conf if exists (ocs-functions).
- use /opt/drbl/setup/files/ocs/ocs.d. instead of single file (ocs-iso, ocs-live-deb).
- add a localboot menu in clonezilla live.

* Wed Mar 07 2007 Steven Shiau <steven _at_ nchc org tw> 2.1.2-8
- Use user space nfs service to overcome squashfs + kernel nfs problem in Clonezilla server live (create-ocs-srv-live). This also has a benefit, the mounted /home/partimage is ready to be seen by client.

* Tue Mar 06 2007 Steven Shiau <steven _at_ nchc org tw> 2.1.2-7
- create-ocs-srv-live is added to create DRBL/Clonezilla server live based on Debian live (not successful yet, squashfs 3.2 is required).

* Sun Mar 04 2007 Steven Shiau <steven _at_ nchc org tw> 2.1.2-6
- bug fixed: wrongly clean /usr/share/make-live/hooks/minimal in create-debian-live
- rename minimal_hook as ocs_minimal_hook so it's easier to be identified.

* Sat Mar 03 2007 Steven Shiau <steven _at_ nchc org tw> 2.1.2-5
- add usage about ntfs-3g mount message in show-general-ocs-live-prompt (ocs-functions).
- change create-debian-live to respect the variable setting PKG_FROM_DBN_MINIMAL_NEED and PKG_FROM_DBN_WHICH_OCS_LIVE_NEED in drbl.conf

* Thu Mar 01 2007 Steven Shiau <steven _at_ nchc org tw> 2.1.2-4
- update prompts in ocs-live-dev.
- update ntfs-3g mount prompts in Clonezlla live.

* Thu Mar 01 2007 Steven Shiau <steven _at_ nchc org tw> 2.1.2-3
- add -d|--debug option for ocs-run so that it's easier to debug.
- bug fixed: if $ocs_root is in the same disk, it should be excluded when running ocs-sr -x.
- use function trigger_dd_status_report in ocs-functions for dd clone.

* Wed Feb 28 2007 Steven Shiau <steven _at_ nchc org tw> 2.1.2-2
- show filesystem before saving it.
- show partition size when using dd to save or restore.

* Mon Feb 26 2007 Steven Shiau <steven _at_ nchc org tw> 2.1.2-1
- Add dd to save and restore unknown filesystem. Therefore BSD* can be cloned.

* Sun Feb 24 2007 Steven Shiau <steven _at_ nchc org tw> 2.1.1-7
- update comment in ocs-functions.
- clonezilla now accepts image name like "2007-2-24-img", not only "2007-02-24-img", by using "$(echo $tgt_img_name | grep -E "(^|[[:space:]]+)([1-6ab]|-b)($|[[:space:]]+)")" instead of "$(echo $tgt_img_name | grep -Ew "([1-6ab]|-b)")" in ocs-functions.

* Tue Feb 20 2007 Steven Shiau <steven _at_ nchc org tw> 2.1.1-6
- update prompt in ocs-live-dev.
- check if target_dir and target_parts nothing in function task_restoreparts (ocs-functions).

* Sun Feb 18 2007 Steven Shiau <steven _at_ nchc org tw> 2.1.1-5
- update/add doc/COPYING in clonezilla/utils/

* Sun Feb 18 2007 Steven Shiau <steven _at_ nchc org tw> 2.1.1-4
- Clonezilla now can save and restore LABEL/UUID of swap device (partition or LV). This will avoid that cloned GNU/Linux fails to use UUID/LABEL based swap partition in /etc/fstab.

* Sat Feb 17 2007 Steven Shiau <steven _at_ nchc org tw> 2.1.1-3
- turn on HAVE_UUID_UUID_H in config.h for mkswap-uuid.

* Sat Feb 17 2007 Steven Shiau <steven _at_ nchc org tw> 2.1.1-2
- bug fixed: mkswap-uuid crashes when using -U.

* Sat Feb 17 2007 Steven Shiau <steven _at_ nchc org tw> 2.1.1-1
- add mkswap-uuid (patch file created by Jazz Wang <jazz _at_ nchc org tw>).
- re-org dir arch.

* Fri Feb 16 2007 Steven Shiau <steven _at_ nchc org tw> 2.1.0-19
- update hints in ocs-functions.
- add a program cv-ocsimg-v1-to-v2 to be used for conversion.
- add --broadcast for drbl-ocs, this can avoid some multicast block problem in network switch.

* Sun Feb 04 2007 Steven Shiau <steven _at_ nchc org tw> 2.1.0-18
- bug fixed: use cat /proc/partitions instead of cp -a to create the partition table file, which is broken in OpenSuSe 10.2.

* Sat Feb 03 2007 Steven Shiau <steven _at_ nchc org tw> 2.1.0-17
- put settings in drbl-ocs.conf instead of in ocs-iso and ocs-live-deb.
- if unifont.bgf is found in working directory, just copy it instead of downloading it again in ocs-iso and ocs-live-deb.

* Sat Feb 03 2007 Steven Shiau <steven _at_ nchc org tw> 2.1.0-16
- typo about LVM restoring fixed in ocs-functions.

* Fri Feb 02 2007 Steven Shiau <steven _at_ nchc org tw> 2.1.0-15
- bug fixed: duplicate save in LVM
- use pipe to stdout in partimage then gzip/bzip2/lzip in save_logv().

* Tue Jan 30 2007 Steven Shiau <steven _at_ nchc org tw> 2.1.0-14
- bug fixed: ocs-iso is broken when running makeboot.sh.

* Tue Jan 30 2007 Steven Shiau <steven _at_ nchc org tw> 2.1.0-13
- default to use root as (hd0,0), and root=/dev/sda1 for usb flash drive in grub config (makeboot.sh).

* Tue Jan 30 2007 Steven Shiau <steven _at_ nchc org tw> 2.1.0-12
- check some necessary programs (syslinux, grub-install) in makeboot.sh.
- use variable ocs_logo_img_syslinux instead of ocs_logo_img in ocs-live-dev and ocs-iso.
- grub menu use color background as default. menus are added. Thanks to Louie Chen.
- bug fixed: -l should not be used twice in ocs-live-dev.
- add --no-floppy for grub-install if it's availalbe (ocs-function).

* Sat Jan 27 2007 Steven Shiau <steven _at_ nchc org tw> 2.1.0-11
- if -p true after cloning, do not show the command prompt.
- bug fixed: unnecessary space when checking LVM in ocs-funtions. Thanks to Sam Soffa for reporting this bug.

* Fri Jan 26 2007 Steven Shiau <steven _at_ nchc org tw> 2.1.0-10
- clonezilla live save and restore both support English/Chinese.
- use syslinux/isolinux boot menu in clonezilla live, a clonezilla live background png file is added.
- bug fixed: only selected target partitions will be resized if the resize flag is on.

* Wed Jan 24 2007 Steven Shiau <steven _at_ nchc org tw> 2.1.0-9
- back to use "0" for not split, we do not want to have extra name (hda1.aa) by default.

* Tue Jan 23 2007 Steven Shiau <steven _at_ nchc org tw> 2.1.0-8
- add warning for reserved iamge name 1-6, a, b, -b in ocs-functions.
- bug fixed: since now we use split instead of the split function in partimage, VOL_LIMIT should not be 0 in drbl-ocs.conf. Default to set it as 100GB.

* Tue Jan 23 2007 Steven Shiau <steven _at_ nchc org tw> 2.1.0-7
- run localepurge in create-debian-live, now template iso is 10 MB smaller.

* Tue Jan 23 2007 Steven Shiau <steven _at_ nchc org tw> 2.1.0-6
- bug fixed: ocs_live_run="$DRBL_SCRIPT_PATH/sbin/ocs-live-save-for-rw" instead of ocs-live-save-for-ro

* Tue Jan 23 2007 Steven Shiau <steven _at_ nchc org tw> 2.1.0-5
- add no warranty notice. 
- simply scripts for minimal in create-debian-live.

* Mon Jan 22 2007 Steven Shiau <steven _at_ nchc org tw> 2.1.0-4
- move create-debian-live from drbl.
- now create-debian-live puts /etc/rc2.d/S99ocs-run to run /live_medis/ocs/ scrpts.
- move ocs-live-save-for-rw ocs-live-save-for-ro ocs-live-restore from /opt/drbl/setup/files/ocs to /opt/drbl/sbin/
- clonezilla live now supports Traditional Chinese when restoring and saving.

* Fri Jan 19 2007 Steven Shiau <steven _at_ nchc org tw> 2.1.0-3
- ocs-iso and ocs-live-dev are updated with new URL http://opensource.nchc.org.tw/clonezilla-live/ 

* Fri Jan 19 2007 Steven Shiau <steven _at_ nchc org tw> 2.1.0-2
- update prompt is ocs-functions.
- ocs-live-dev=ocs-live-dev+makeboot.sh, now ocs-live-dev can release a zip file for USB stick, later user can download it and make his/her USB stick bootable with FAT16/FAT32 under M$ windows.

* Thu Jan 18 2007 Steven Shiau <steven _at_ nchc org tw> 2.1.0-1
- default to use -p choose in ocs-sr -x.
- use ocs-live-save-for-ro & ocs-live-save-for-rw for ocs-iso and ocs-live-dev, respectively.
- use gzip/bzip2/lzop and split to do compression and split, not the functions in partimage. The split volume file name is like hda1.aa, hda1.ab, hda1.ac...

* Wed Jan 17 2007 Steven Shiau <steven _at_ nchc org tw> 2.0.1-25
- bug fixed: When using pipe stdout in partimage, --volume=0 is a must. Otherwise it will create a file like stdout.000.
- bug fixed: it's not always /home/partimag in the live media. Therefore replace /home/partimag by $ocsroot in ocs-live-restore ocs-live-save, now when creating iso or live device by ocs-iso or ocs-live-dev, we will put all images into $ocsroot in the target media.
- add -b|--boot-loader in ocs-live-dev.
- bug fixed: if target dev is /dev/sda2, grub-install put wrong config.
- bug fixed: now split volume from ntfsclone can be used in multicast restore.

* Tue Jan 16 2007 Steven Shiau <steven _at_ nchc org tw> 2.0.1-24
- remove -p choose in ocs-live-restore, since now default in ocs-sr -x, we will use -p choose.
- use tarball opt_drbl.tgz to save space and avoid FAT no symbolic link.
- ocs-sr -x will only list unmounted partition/disk when saving (ocs-functions).
- add VOL_LIMIT_IN_INTERACTIVE="2000" in drbl-ocs.conf.
- remove tsize param in ocs-iso.
- add ocs-live-dev to put Debian live CD + DRBL/Clonezilla programs in USB pendrive.
- now clonezilla can split images in ntfsclone.

* Sun Jan 14 2007 Steven Shiau <steven _at_ nchc org tw> 2.0.1-23
- bug fixed: when estimating the size in ocs-iso, we should follow symbolic link (du -L).
- update usage and comment in ocs-iso.

* Sat Jan 13 2007 Steven Shiau <steven _at_ nchc org tw> 2.0.1-22
- add -f|--on-the-fly to let ocs-iso to write output to CD/DVD writer directly instead of ISO file. Thanks to Louie Chen for providing the method.

* Sat Jan 13 2007 Steven Shiau <steven _at_ nchc org tw> 2.0.1-21
- add an option HALT_REBOOT_OPT in drbl-ocs.conf so that we can control to use force halt/reboot or normal force/reboot.
- add LC_ALL=C before perl in ocs-functions, get_part_info, cnvt-ocs-dev, drbl-chnthn-functions, and ocs-onthefly.
- S05kbd-config can load loadkey from /etc/ocs/ocs-live.conf

* Fri Jan 12 2007 Steven Shiau <steven _at_ nchc org tw> 2.0.1-20
- sync before reboot client.

* Fri Jan 12 2007 Steven Shiau <steven _at_ nchc org tw> 2.0.1-19
- add PATH and update prompts in ocs-live-save.

* Fri Jan 12 2007 Steven Shiau <steven _at_ nchc org tw> 2.0.1-18
- ocs-live-restore and ocs-live-save are added in /opt/drbl/setup/files/ocs.
- now by running "ocs-iso -s", we can create an iso without clonezilla image. This iso can be use to saved image.

* Fri Jan 12 2007 Steven Shiau <steven _at_ nchc org tw> 2.0.1-17
- add -p choose in ocs-live.

* Fri Jan 12 2007 Steven Shiau <steven _at_ nchc org tw> 2.0.1-16
- show estimated target iso file, and will give warnning message when > 4.7GB.
- validate template iso file by MD5SUM, clean tmp dir if HUP in ocs-iso.
- ocs-iso will check if file is too large so that mkisofs can not handle that.
- ocs-iso will give short volume ID if image name is over 32 characters.

* Thu Jan 11 2007 Steven Shiau <steven _at_ nchc org tw> 2.0.1-15
- update usage message in ocs-iso.
- put checkInodeForDevice, ide_info_drbl and scsi_info_drbl in /opt/drbl/sbin/

* Thu Jan 11 2007 Steven Shiau <steven _at_ nchc org tw> 2.0.1-14
- umount tmp dir before exit 1 (ocs-iso).
- clean temp isolinux (ocs-iso).

* Thu Jan 11 2007 Steven Shiau <steven _at_ nchc org tw> 2.0.1-13
- update ocs-iso, shorter tag.

* Thu Jan 11 2007 Steven Shiau <steven _at_ nchc org tw> 2.0.1-12
- update usage message in ocs-iso.

* Thu Jan 11 2007 Steven Shiau <steven _at_ nchc org tw> 2.0.1-11
- bug fixed: help message should be shown before downloading debian live cd for clonezilla (ocs-iso).

* Thu Jan 11 2007 Steven Shiau <steven _at_ nchc org tw> 2.0.1-10
- add exit for "ocs-sr -x", and ocs-sr can be save-only or restore-only.
- new function: a file /opt/drbl/sbin/ocs-iso is added to put clonezilla image into debian-live iso. Therefore we can restore clonezilla image by debian live CD/DVD, DRBL server is not alway necessary for restoring image now.

* Wed Jan 10 2007 Steven Shiau <steven _at_ nchc org tw> 2.0.1-9
- variable POST_RUN_DIR is changed to OCS_POSTRUN_DIR, another OCS_PRERUN_DIR is added in drbl-ocs.conf. Now clonezilla also supports pre-run some scripts in $OCS_PRERUN_DIR before clonezilla starts.
- drbl-ocs, ocs-sr supports -d[0-4].

* Tue Jan 09 2007 Steven Shiau <steven _at_ nchc org tw> 2.0.1-8
- bug fixed: now the variable is drbl_mode instead of drbl_ssi_mode

* Fri Jan 05 2007 Steven Shiau <steven _at_ nchc org tw> 2.0.1-7
- add -y2|--always-restore-default-drbl in clonezilla.
- if en_US.utf8 or en_US.UTF-8 is found, set it as LANG in ocs-run to avoid dialog distoration.

* Fri Jan 05 2007 Steven Shiau <steven _at_ nchc org tw> 2.0.1-6
- the pxelinux config file created by ocsmgrd is based on original default, so now menus are shown.

* Thu Jan 04 2007 Steven Shiau <steven _at_ nchc org tw> 2.0.1-5
- add re_put_ocs_related_srv_in_client_rc1d="no" in drbl-ocs.conf, and use that in ocs-functions.

* Wed Jan 03 2007 Steven Shiau <steven _at_ nchc org tw> 2.0.1-4
- use tune-clientdir-opt instead of turn-drbl-ssi-mode in ocs-functions.
- do not use "shift 3" in drbl-ocs, use shift 3 times. Otherwise in some case, it will fail.

* Wed Jan 03 2007 Steven Shiau <steven _at_ nchc org tw> 2.0.1-3
- hide label Clonezilla when clonezilla is stopped.

* Tue Jan 02 2007 Steven Shiau <steven _at_ nchc org tw> 2.0.1-2
- separate drbl and clonezilla in pxelinux menu, use clonezilla block for clonezilla only. Do not touch drbl block now.

* Tue Jan 02 2007 Steven Shiau <steven _at_ nchc org tw> 2.0.1-1
- update the comments in ocs-srv-reset.
- use "both" for ocs_client_trig_type in drbl-ocs.conf and ocs-functions.
- add an option to keep ocs related serivces in client.
- this version should work without modifying files in client's system files when clonezilla start, just change the ocs_opt in kernel bootparam, and clonezilla client can work..

* Tue Jan 02 2007 Steven Shiau <steven _at_ nchc org tw> 2.0.0-9
- use ocs-srv-reset in ocs-functions.
- suppress the output message of ocs-srv-reset.

* Tue Jan 02 2007 Steven Shiau <steven _at_ nchc org tw> 2.0.0-8
- rewrite funtion ocs_inittab as $node_ip instead of inittab (ocs-functions).
- let modules loading be run in ocs-sr instead of S19ocs-run.
- use ocs-related-srv in ocs-functions.
- use --language en instead of --language 0 to avoid init 0 problem.
- /etc/ocs/clonezilla.conf is not necessary any more
- use service ocs-run in client to do save/restore, and ocs-srv-reset in server to reset the server when client boot or shutdown.

* Fri Dec 29 2006 Steven Shiau <steven _at_ nchc org tw> 2.0.0-7
- put run_post_cmd_when_clone_end "$postrun" inside ocs-sr instead of S19ocs-run.
- bug fixed: some files are not modified in cnvt-ocs-dev

* Thu Dec 28 2006 Steven Shiau <steven _at_ nchc org tw> 2.0.0-6
- bug fixed: mcast-port should not repeat in S19ocs-run.

* Thu Dec 28 2006 Steven Shiau <steven _at_ nchc org tw> 2.0.0-5
- drbl-ocs also can choose only the disk we want to restore when there are more than 2 disks in an saved image

* Thu Dec 28 2006 Steven Shiau <steven _at_ nchc org tw> 2.0.0-4
- rewrite parameters parsing mechanism in ocs-functions.
- -x|--interactive is added to ocs-sr.
- add -p|--mcast-port in ocs-sr, and use that in ocs-functions.
- we can choose only the disk we want to restore when there are more than 2 disks in an saved image.

* Tue Dec 26 2006 Steven Shiau <steven _at_ nchc org tw> 2.0.0-3
- bug fixed: dialog can not run normally when disk containing 2 disks.
- bug fixed: when 2 disks are chosen to restore, only the first is restored, and unicast/multicast in a mess.

* Tue Dec 26 2006 Steven Shiau <steven _at_ nchc org tw> 2.0.0-2
- bug fixed: when saving hda & hdb, the input name ""hda"" ""hdb"" created by dialog is not accpted.
- bug fixed: when hda and hdb are selected, only partitions hdb* are saved.
- make cnvt-ocs-dev compatible with clonezilla 2.0 image format

* Tue Dec 26 2006 Steven Shiau <steven _at_ nchc org tw> 2.0.0-1
- support multiple harddrives. From 2.0, the clonezilla image format is different from that in clonzilla 1.x. Now we use something like hda-mbr, hda-pt.sf, hda-chs.sf (was mbr, pt.sf, and chs.sf). The image data (hda1, hda1.ntfs-img...) remains the same format with that in clonezilla 1.x.
- bug fixed: when restoring "hda1 hda3" in restoreparts, only hda1 is restored.

* Mon Dec 25 2006 Steven Shiau <steven _at_ nchc org tw> 1.5.1-7
- update USAGE in cnvt-ocs-dev.
- drbl-ocs and ocs-functions should keep "MENU PASSWD" for label block "local" in pxelinux config file when -y0/-y1 is set.

* Sun Dec 24 2006 Steven Shiau <steven _at_ nchc org tw> 1.5.1-6
- use language file for some prompts.
- default to turn on -c (confirm) before saving in select-in-client mode.
- prevent input dev is empty when saving image, dialog will ask again.
- a file cnvt-ocs-dev is added to convert the image from hda to sda or vice versa.

* Sat Dec 23 2006 Steven Shiau <steven _at_ nchc org tw> 1.5.1-5
- add check_DIA_set_ESC to let drbl-ocs and ocs-sr can use dialog/whiptail/Xdialog if necessary.
- rewrite the postrun mechanism as function in ocs-functions.
- merge some code in S19ocs-run to ocs-function so that ocs-sr can process postrun and other commands.
- ocs-function honors -y0/-y1 in select-in-client mode.

* Thu Dec 21 2006 Steven Shiau <steven _at_ nchc org tw> 1.5.1-4
- check if inputted image name is using reserved name in task_save*()

* Thu Dec 21 2006 Steven Shiau <steven _at_ nchc org tw> 1.5.1-3
- add an option to poweroff when clone finishes in select-in-client mode.

* Thu Dec 21 2006 Steven Shiau <steven _at_ nchc org tw> 1.5.1-2
- rewrite the countdown and confirm mechanism due to default to turn on -c (confirm) option when using select-in-client mode.
- check if reserved image name (ask_user) is inputted.
- rewrite drbl-ocs, no more a lot of $1/$2/$3/$4, put them in variables in the beginning.

* Wed Dec 20 2006 Steven Shiau <steven _at_ nchc org tw> 1.5.1-1
- now ocs-sr can assign ocsroot in command line (-or|--ocsroot DIR).
- bug fixed: when restore parts, the imagename is ask_user, it will fail due to wrong variable then wrong path. 
- now we can use dialog to interactivly input the parameters in ocs-sr.
- add "-p choose" in ocs-function.

* Sat Dec 16 2006 Steven Shiau <steven _at_ nchc org tw> 1.5.0-4
- ps -eo uid,ucmd output format is different in different dists, some with extra space in the beginning. Now is_spawned_by_drbl_ocs should work for all dists.

* Thu Dec 14 2006 Steven Shiau <steven _at_ nchc org tw> 1.5.0-3
- add echo "$msg_win_fail_with_Missing_OS"

* Thu Dec 14 2006 Steven Shiau <steven _at_ nchc org tw> 1.5.0-2
- add check_if_source_dev_busy() in ocs-functions.
- before create partition, we will check if it's in drbl client or not. If not, show warning messages.
- bug fixed: when non-existing partitions are inputted, it will be filtered.
- check if the partition is busy before creating partitions.
- add function is_spawned_by_drbl_ocs and use that in ocs-functions to decide some action for ocs-sr.

* Tue Dec 12 2006 Steven Shiau <steven _at_ nchc org tw> 1.5.0-1
- rewrite drbl-ocs and ocs-functions as drbl-ocs, ocs-sr and ocs-functions. This will be easier to use ocs-sr in client or partition umounted machine.
- 1step_ocs_restore.sh is removed, not maintained anymore.

* Sat Dec 09 2006 Steven Shiau <steven _at_ nchc org tw> 1.4.3-30
- update the help messages of drbl-ocs.
- add a function turn_off_swap_and_LVM2 to be reused.
- if drbl-ocs task save/restore is ran not in DRBL client, we won't notify the ocsmgrd.

* Mon Dec 04 2006 Steven Shiau <steven _at_ nchc org tw> 1.4.3-29
- update prompts in ocs-functions.

* Sun Dec 03 2006 Steven Shiau <steven _at_ nchc org tw> 1.4.3-28
- add more hints and checking mechanism for ntfsclone save & restore.

* Fri Dec 01 2006 Steven Shiau <steven _at_ nchc org tw> 1.4.3-27
- bug fixed in drbl-chnthn-functions: different parted gives different outputs, the ntfs/vfat partition is not found in Ubuntu 6.10. 

* Wed Nov 22 2006 Steven Shiau <steven _at_ nchc org tw> 1.4.3-26
- Sleep 5 before reboot/poweroff when clone finishes.
- add options " -ns, --ntfs-progress-in-server" in drbl-ocs, so that we can save the ntfsclone progress tmp file in the server, therefore the progress can be check in the server (Default in to be put in local /tmp/, which is local tmpfs)

* Fri Nov 17 2006 Steven Shiau <steven _at_ nchc org tw> 1.4.3-25
- "exec </dev/console >/dev/console 2>&1" in S19ocs-run is only when runlevel=1.

* Thu Nov 16 2006 Steven Shiau <steven _at_ nchc org tw> 1.4.3-24
- we just accept those image name is alpha, digit, _ and -.
- bug fixed: uncompressed ntfsclone image now can be restored. Thanks to Guy Carpenter <guyc _at_ atgis com au> for reporting and identifying this bug.

* Mon Oct 30 2006 Steven Shiau <steven _at_ nchc org tw> 1.4.3-23
- some typos fixed.

* Fri Oct 27 2006 Steven Shiau <steven _at_ nchc org tw> 1.4.3-22
-  estimate delay times as 30 secs + others for time_to_pause_before_mail, i.e. =$((30+$SLEEP_TIME_AFTER_PART_CLONED+$NOTIFY_OCS_SERVER_TIME_LIMIT)) (ocs-functions).

* Fri Oct 20 2006 Steven Shiau <steven _at_ nchc org tw> 1.4.3-21
- bug fixed: time_to_pause_before_mail should add $SLEEP_TIME_AFTER_PART_CLONED

* Thu Oct 19 2006 Steven Shiau <steven _at_ nchc org tw> 1.4.3-20
- use $ocs_lock_dir/clonezilla.lock instead of $drbl_syscfg/clonezilla.lock (ocs_lock_dir is /var/lock/clonezilla).

* Thu Oct 19 2006 Steven Shiau <steven _at_ nchc org tw> 1.4.3-19
- use $drbl_syscfg/clonezilla.lock instead of $ocsroot/clonezilla.lock

* Thu Oct 05 2006 Steven Shiau <steven _at_ nchc org tw> 1.4.3-18
- add -j0, and change the default action to create partition by sfdisk. Since the dd method will have problem in different CHS harddisk.

* Wed Oct 04 2006 Steven Shiau <steven _at_ nchc org tw> 1.4.3-17
- mail client not only mutt, but also mail, mailx in ocs-functions.

* Sun Sep 24 2006 Steven Shiau <steven _at_ nchc org tw> 1.4.3-16
- when multicast restoring finishes, root will get a report via email if mutt is installed in clonezilla server.

* Fri Sep 22 2006 Steven Shiau <steven _at_ nchc org tw> 1.4.3-15
- To avoid there is no input output in rc running, we add exec </dev/console >/dev/console 2>&1 in S19ocs-run. Thanks to Scott James Remnant (keybuk).
- report image name when clone finishes.

* Wed Sep 20 2006 Steven Shiau <steven _at_ nchc org tw> 1.4.3-14
- require drbl >= 1.7.4-13.
- change #!/bin/sh to #/bin/bash in the scripts.

* Tue Sep 19 2006 Steven Shiau <steven _at_ nchc org tw> 1.4.3-13
- clonezilla can not be multi-image, so it will be a mess if just stop some clients. Therefore if "$LIST_HOST" = "on", we still stop all the clonezilla process.
- bug fixed: when in drbl ssi mode or clonezilla box mode, if hosts is selected, default_skeleton is removed by "drbl-ocs stop" in gen_ssi_files.
- bug fixed: when in drbl ssi mode or clonezilla box mode, if hosts is selected,, self process won't be killed by turn-drbl-ssi-mode.

* Sun Sep 10 2006 Steven Shiau <steven _at_ nchc org tw> 1.4.3-12
- the return code tested by -ne 0 instead of -gt 0 when saving image with ntfsclone.

* Wed Sep 06 2006 Steven Shiau <steven _at_ nchc org tw> 1.4.3-11
- bug fixed: with parted-17.1-15, the flag can be got in get_part_info.

* Tue Sep 05 2006 Steven Shiau <steven _at_ nchc org tw> 1.4.3-10
- bug fixed: parted-17.1-15 in FC5 updates has new format. Modify get_part_info. Thanks to Dave Haakenhout for the bug report.
- update the Usage function in drbl-ocs.

* Mon Sep 04 2006 Steven Shiau <steven _at_ nchc org tw> 1.4.3-9
- bug fixed: unable to find LVM in Mandriva 2006 or CentOS 4.3

* Thu Aug 24 2006 Steven Shiau <steven _at_ nchc org tw> 1.4.3-8
- update the footer in drbl-chnthn-functions.

* Thu Aug 24 2006 Steven Shiau <steven _at_ nchc org tw> 1.4.3-7
- add arm-wol as a necessary service in clonezilla (runlevel 1)
- add option --mcast-iface so that user can assign the multicast seed ethernet port.

* Wed Aug 23 2006 Steven Shiau <steven _at_ nchc org tw> 1.4.3-6
- create $POST_RUN_DIR if it does not exist.

* Wed Aug 23 2006 Steven Shiau <steven _at_ nchc org tw> 1.4.3-5
- bug fixed: WIN_HOSTNAME_PREFIX is missing in drbl-ocs.conf.

* Wed Aug 23 2006 Steven Shiau <steven _at_ nchc org tw> 1.4.3-4
- default not to assign ntfs-3g, so drbl-chnthn will try to use ntfsmount then ntfs-3g. 

* Wed Aug 23 2006 Steven Shiau <steven _at_ nchc org tw> 1.4.3-3
- add option -o|--run-post-dir in drbl-ocs so that we can run-parts files in /opt/drbl/ocs/postrun.
- add -hn0, -hn1 in drbl-ocs so that we can directly change M$ windows hostname via ntfs-3g

* Sun Aug 13 2006 Steven Shiau <steven _at_ nchc org tw> 1.4.3-2
- add the credit and thank to Chris Macaulay in drbl-chnthn.

* Sat Aug 12 2006 Steven Shiau <steven _at_ nchc org tw> 1.4.3-1
- add scripts drbl-chnthn and drbl-chnthn-functions, which are developed by Ceasar Sun, so that we can change the hostname of M$ windows XP/2K when cloning is finished.

* Thu Jul 27 2006 Steven Shiau <steven _at_ nchc org tw> 1.4.2-5
- sign the rpm with gpg.

* Mon Jul 17 2006 Steven Shiau <steven _at_ nchc org tw> 1.4.2-4
- fix the typo bug again.

* Mon Jul 17 2006 Steven Shiau <steven _at_ nchc org tw> 1.4.2-3
- fix the typo bug.

* Mon Jul 17 2006 Steven Shiau <steven _at_ nchc org tw> 1.4.2-2
- use better variable name in create_partiton in ocs-functions.
- Make kernel re-read the partiton table of target hardisk before clone.

* Sat Jul 15 2006 Steven Shiau <steven _at_ nchc org tw> 1.4.2-1
- update echo prompt for grub-install.
- add a mechanism to check if disk and parts files are empty.
- rename some functions so it's easier to be identified.
- now by default we directly use dd to dump partition table in target harddisk from saved image file "mbr".
- add the option "--create-part-by-sfdisk" in drbl-ocs, 
- when restoring MBR, only dd the first 446 bytes instead of 512 bytes.

* Mon Jun 26 2006 Steven Shiau <steven _at_ nchc org tw> 1.4.1-18
- avoid the sleep time too short compared with mcast_max_wait_time.
- add recommended max wait time when run drbl-ocs.

* Mon Jun 26 2006 Steven Shiau <steven _at_ nchc org tw> 1.4.1-17
- if -z3 is assigned and the partition is not NTFS, we use partimage with -z0 then stdout pipe to lzop to save the image.
- change SLEEP_TIME_AFTER_PART_CLONED to 15 from 10, and use random time to avoid request udpcast server at same time when 1st partiton clone finishes.
- bug fixed: if -z3 is chosen, the 2nd partition will be save without compression.

* Tue Jun 13 2006 Steven Shiau <steven _at_ nchc org tw> 1.4.1-16
- change report message "fail" -> ***FAIL***

* Tue Jun 13 2006 Steven Shiau <steven _at_ nchc org tw> 1.4.1-15
- split -y option to -y0 and -y1 so that the default PXE menu can be assigned in dcs.

* Tue Jun 13 2006 Steven Shiau <steven _at_ nchc org tw> 1.4.1-14
- bug fixed: now we will try to create uniq countdown time for each client when clone finishes.

* Tue Jun 13 2006 Steven Shiau <steven _at_ nchc org tw> 1.4.1-13
- add prompt before start multicast ntfsclone.

* Mon Jun 12 2006 Steven Shiau <steven _at_ nchc org tw> 1.4.1-12
- add statistics report.
- let image and device name inputted be more flexible.

* Sat Jun 10 2006 Steven Shiau <steven _at_ nchc org tw> 1.4.1-11
- update the help with -x|--full-duplex in drbl-ocs.

* Sat Jun 10 2006 Steven Shiau <steven _at_ nchc org tw> 1.4.1-10
- change variable NTFSCLONE_CMP to IMG_CLONE_CMP.
- change function to image_save from partimage_save.
- if disk or partition info file is not able to be written when clone finishing, show it and wait for user to confirm.
- correct variable typos: updcast_stderr -> udpcast_stderr.
- create a testing block in ocs-function to use partimage stdout with lzop with fat.

* Tue Jun 06 2006 Steven Shiau <steven _at_ nchc org tw> 1.4.1-9
- update some prompts.

* Mon Jun 05 2006 Steven Shiau <steven _at_ nchc org tw> 1.4.1-8
- image name "hda1" without ".000" is supported, since if partimage --volume=0, the image name is "hda1" instead of "hda1.000"
- set VOL_LIMIT_DEFAULT="0" in drbl-ocs.conf

* Sun Jun 04 2006 Steven Shiau <steven _at_ nchc org tw> 1.4.1-7
- Add ntfsclone image save statistics report.

* Sun Jun 04 2006 Steven Shiau <steven _at_ nchc org tw> 1.4.1-6
- Add ntfsclone restoration statistics report.
- For better security, chmod 600 for ntfsclone saved image file.

* Wed May 31 2006 Steven Shiau <steven _at_ nchc org tw> 1.4.1-5
- use filesystem as DEV_MODEL message when saving image.

* Wed May 31 2006 Steven Shiau <steven _at_ nchc org tw> 1.4.1-4
- add an option -a|--no-force-dma-on so that HD DMA is not always be turn on, since some new machine will have problem if DMA is forced on.
- udpcast verbose message is shown when -v is specificed in drbl-ocs.
- -nogui|--nogui are the same option.

* Tue May 30 2006 Steven Shiau <steven _at_ nchc org tw> 1.4.1-3
- add more prompt for ntfsclone when saving image in client.
- fix the bug when host is specified, some unrelated host will be chosen, too.
- other minor changes.
- bug fixed: unicast with lzop fails.

* Tue May 30 2006 Steven Shiau <steven _at_ nchc org tw> 1.4.1-2
- fix the bug that fails in multicast restore partitions.

* Mon May 29 2006 Steven Shiau <steven _at_ nchc org tw> 1.4.1-1
- add multicast restoration example in drbl-ocs Usage.
- update the comments in ocs-funtion.
- add option -x|--full-duplex in drbl-ocs.
- rewrite the code to use function udp_send_part_img to do the real job so that we can reuse the function both in normal partitions and LVM LVs.
- add a script get_part_info to get the partition info (start, end, size, type, filesystem and flag).
- option to use ntfsclone to save a partition.
- change the variable MULTICAST_ADDR to MULTICAST_ALL_ADDR.
- add lzop support for ntfsclone.

* Wed May 10 2006 Steven Shiau <steven _at_ nchc org tw> 1.4.0-3
- remove some unnecessary files.

* Mon May 8 2006 Steven Shiau <steven _at_ nchc org tw> 1.4.0-2
- change function name get_existing_part_image to get_existing_parts_image so it can be used in dcs.

* Mon May 8 2006 Steven Shiau <steven _at_ nchc org tw> 1.4.0-1
- support LVM2 (LVM1 not yet).
- remove the function to save & restore hda1, since we can use save & restore partitions.
- rewrite the code, all save/restore (unicast/multicast partition/disk) are based on partitions save/restore.
- add option to give parameters "$mcast_wait_time", "$n_clients" and "$mcast_max_wait_time", so now the multicast start can be batch mode, EX: /opt/drbl/sbin/drbl-ocs -l 0 -g auto -b --clients-to-wait 5 --max-time-to-wait 100 startdisk multicast_restore d5, or /opt/drbl/sbin/drbl-ocs -l 0 -g auto -b --clients-to-wait 1 --max-time-to-wait 100 startparts multicast_restore p5 "hda1 hda3"

* Fri May 5 2006 Steven Shiau <steven _at_ nchc org tw> 1.3.9-12
- show warning message and skip it when trying to save LVM partition.

* Mon May 1 2006 Steven Shiau <steven _at_ nchc org tw> 1.3.9-11
- set the drbl-ocs.conf mode as 644.

* Sat Apr 29 2006 Steven Shiau <steven _at_ nchc org tw> 1.3.9-10
- only if it's in clonezilla box, we will run gen_ssi_files when ocs stops.

* Sat Apr 29 2006 Steven Shiau <steven _at_ nchc org tw> 1.3.9-9
- fix the bug when "-y" is on, no /etc/ocs directory to put clonezill.conf

* Thu Apr 20 2006 Steven Shiau <steven _at_ nchc org tw> 1.3.9-8
- when DEV_MODEL is not available, use "No_description" instead of exiting in ocs-funtions.

* Fri Apr 7 2006 Steven Shiau <steven _at_ nchc org tw> 1.3.9-7
- move restoring the MBR data after partimage restoring.

* Sun Mar 26 2006 Steven Shiau <steven _at_ nchc org tw> 1.3.9-6
- fix typo: /dev/partition -> /dev/$partition.

* Sun Mar 12 2006 Steven Shiau <steven _at_ nchc org tw> 1.3.9-5
- check_distribution_name should be run in clonezilla server, not in client.

* Sun Mar 12 2006 Steven Shiau <steven _at_ nchc org tw> 1.3.9-4
- bug fixed, /etc/drbl/drbl_deploy.conf should be read in clonezilla server only, not in client.

* Thu Mar 9 2006 Steven Shiau <steven _at_ nchc org tw> 1.3.9-3
- polish drbl-ocs.

* Wed Mar 8 2006 Steven Shiau <steven _at_ nchc org tw> 1.3.9-2
- fix some minor bugs.
- add a mechanism to randomly sleep before notifying clonezilla server, so clients will not notify server at almost same time.
- if device.map exists, remove it to avoid some problem when run "-g auto".

* Mon Mar 6 2006 Steven Shiau <steven _at_ nchc org tw> 1.3.9-1
- add loading drbl_deploy.conf to know if it's in clonezilla_box_mode.
- If it's clonezilla_box_mode, clean dhcpd leases.
- clonezilla box mode is ready.

* Sat Mar 04 2006 Steven Shiau <steven _at_ nchc org tw> 1.3.8-2
- add or remove runlevel 1 to pxelinux kernel append parameter.
- abolish /etc/ocs/config, just get the ocs server IP from client's IP and the port from drbl-ocs.conf.
- fix the bug that in DRBL SSI mode, client fails to notify ocs server when finishing cloning.

* Thu Mar 02 2006 Steven Shiau <steven _at_ nchc org tw> 1.3.8-1
- support sis900 etherboot-pxe local boot.
- add drbl single system image support. (Not ready yet)

* Tue Jan 31 2006 Steven Shiau <steven _at_ nchc org tw> 1.3.7-3
- now the default action is not to restart NFS service.

* Sun Jan 29 2006 Steven Shiau <steven _at_ nchc org tw> 1.3.7-2
- add require drbl version.

* Sun Jan 29 2006 Steven Shiau <steven _at_ nchc org tw> 1.3.7-1
- Client will send MAC address when clone finishes, a "01-MAC" file will always be created in /tftpboot/nbi_img/pxelinux.cfg/. This will be better when range is used in dhcpd.conf, since now we can force client to boot local OS by MAC address.
- Check if the target HD exists or not before process it.

* Fri Jan 20 2006 Steven Shiau <steven _at_ nchc org tw> 1.3.6-29
- remove the "clean_cylinder_boundary_warning $sfdisk_partition_layout_file" in create_partition() of ocs-functions. It will make pt.sf empty when all the clients are run almost the same time.

* Mon Jan 09 2006 Steven Shiau <steven _at_ nchc org tw> 1.3.6-28
- bug fixed, OS_Version is global variable, so just run check_distribution_name should to get OS_Version.
- use $FULL_OS_Version in pxelinux menu.

* Tue Jan 03 2006 Steven Shiau <steven _at_ nchc org tw> 1.3.6-27
- let MBR clone before sfdisk in ocs-onthefly.
- add clean_cylinder_boundary_warning to clean the warning in pt.sf in ocs-function and drbl-ocs..

* Sat Dec 24 2005 Steven Shiau <steven _at_ nchc org tw> 1.3.6-26
- "-g auto" will be ok for /dev/sda in drbl-ocs.

* Fri Dec 23 2005 Steven Shiau <steven _at_ nchc org tw> 1.3.6-25
- only clean the stalled partimage and netcat process when mode is network in ocs-onthefly.
     
* Thu Dec 22 2005 Steven Shiau <steven _at_ nchc org tw> 1.3.6-24
- it's netcat, not nc, when killing nc/netcat process in SuSE.

* Thu Dec 22 2005 Steven Shiau <steven _at_ nchc org tw> 1.3.6-23
- update some description in resize_part. 

* Wed Dec 21 2005 Steven Shiau <steven _at_ nchc org tw> 1.3.6-22
- Since the results of "parted /dev/xxx p" are different in OpenSuSE 10.0 and FC in resize_part, fix that.

* Tue Dec 20 2005 Steven Shiau <steven _at_ nchc org tw> 1.3.6-21
- parted is in /usr/sbin/parted, not /sbin/parted, so use PATH in resize_part now.

* Fri Dec 16 2005 Steven Shiau <steven _at_ nchc org tw> 1.3.6-20
- add an option to use HD CHS value or not.

* Fri Dec 16 2005 Steven Shiau <steven _at_ nchc org tw> 1.3.6-19
- add partition resize function to solve the small partition image restored to larger partition problem.

* Wed Dec 14 2005 Steven Shiau <steven _at_ nchc org tw> 1.3.6-18
- now $ocsroot is not necessary in ocs-onthefly.

* Tue Dec 13 2005 Steven Shiau <steven _at_ nchc org tw> 1.3.6-17
- For ocs-onthefly:
- use nc to send and receive pt.sf, mbr
- use nc to notify source machine the job.
- default to gzip data before pipe to nc.

* Mon Dec 12 2005 Steven Shiau <steven _at_ nchc org tw> 1.3.6-16
- We should not add "-q 0" for FC3 or ealier version, there is no -q option. nc will quit when EOF.

* Sun Dec 11 2005 Steven Shiau <steven _at_ nchc org tw> 1.3.6-15
- add -i|--filter prompt for client to run in ocs-onthefly.
- check filter program exists or not in ocs-onthefly.

* Sun Dec 11 2005 Steven Shiau <steven _at_ nchc org tw> 1.3.6-14
- checkInodeForDevice should be done only in clone_client in ocs-onthefly.
- put "-q 0" for netcat in DRBL Debian ocs-onthefly, otherwise the default is wait forever.

* Sat Dec 10 2005 Steven Shiau <steven _at_ nchc org tw> 1.3.6-13
- update some comments in drbl-ocs.

* Fri Dec 9 2005 Steven Shiau <steven _at_ nchc org tw> 1.3.6-12
- we have to remove " (comes with checklist in dialog) so that for loop will work in drbl-ocs, so change target_parts="$(cat $ANS_TMP)" to target_parts="$(cat $ANS_TMP | tr -d \")". This is specially for FC.

* Fri Dec 9 2005 Steven Shiau <steven _at_ nchc org tw> 1.3.6-11
- use command "netcat" instead of "nc" in SuSE.

* Thu Dec 8 2005 Steven Shiau <steven _at_ nchc org tw> 1.3.6-10
-  clean partimage and nc process before start it.

* Tue Dec 6 2005 Steven Shiau <steven _at_ nchc org tw> 1.3.6-9
- fix a bug for unable to do partition no. > 1 clone over network in ocs-onthefly.
- create swap partiton if exists i ocs-onthefly.

* Thu Nov 24 2005 Steven Shiau <steven _at_ nchc org tw> 1.3.6-8
- support different lang for ocs-onthefly.

* Thu Nov 24 2005 Steven Shiau <steven _at_ nchc org tw> 1.3.6-7
- add clone over network in ocs-onthefly.
- increase SLEEP_TIME_AFTER_PART_CLONED="10" from 5

* Sun Nov 13 2005 Steven Shiau <steven _at_ nchc org tw> 1.3.6-6
- extract some functions as ocs-functions so that drbl-ocs and ocs-onthefly can use them.
- delete some unnecessary codes in ocs-onthefly.

* Fri Nov 11 2005 Steven Shiau <steven _at_ nchc org tw> 1.3.6-5
- set the default save volume size as 500GiB in drbl-ocs.conf so that in most of cases when restoring it will be faster.

* Wed Nov 09 2005 Steven Shiau <steven _at_ nchc org tw> 1.3.6-4
- use another method so that the compressed image (not uncompressed) is transferred when multicast.

* Sun Nov 06 2005 Steven Shiau <steven _at_ nchc org tw> 1.3.6-3
- It seems in partiamge 0.6.5-beta2, when using --debug=0 to save NTFS partition, partimage will crash. However, 0.6.5-beta1 works without this problem.  To avoid this, we set debug_level=1 as default value in /opt/drbl/conf/drbl-ocs.conf

* Sun Nov 06 2005 Steven Shiau <steven _at_ nchc org tw> 1.3.6-2
- update some notes.

* Sun Nov 06 2005 Steven Shiau <steven _at_ nchc org tw> 1.3.6-1
- fix the bug for 2nd or later partition waiting time.
- Many thanks to Christian Treczoks for providing "dd skip=1" method, so now partimage_stdin and size record in the image directory are not necessary.
- use /opt/drbl/conf/drbl-ocs.conf.
- add an option -i|--image-size so that we can assign image volume size.

* Thu Oct 27 2005 Steven Shiau <steven _at_ nchc org tw> 1.3.5-22
- force to set LANG=C so that we can read yes/no of dialog when saving/restoring image in client.

* Wed Oct 26 2005 Steven Shiau <steven _at_ nchc org tw> 1.3.5-21
- support clonezilla restore server mode (always-restore)
- change the option --input-name-in-client to --select-img-in-client

* Mon Oct 24 2005 Steven Shiau <steven _at_ nchc org tw> 1.3.5-20
- add loading system locale to avoid the dialog distortion.

* Thu Oct 13 2005 Steven Shiau <steven _at_ nchc org tw> 1.3.5-19
- make "--ttl 1" as an option in drbl-ocs.

* Fri Oct 07 2005 Steven Shiau <steven _at_ nchc org tw> 1.3.5-18
- update partimage_stdin, since Blake released a new version for partimage_stdin, support -z0/-bzip2.
- change the path partimage_stdin from /sbin to /usr/bin.
- make the partimage_stdin use the flag partimage_stdin_comp_flag (-z0/-gz/-bz2) in drbl-ocs.
- turn on the flags -z0/-z1/-z2 in drbl-ocs.

* Wed Oct 05 2005 Steven Shiau <steven _at_ nchc org tw> 1.3.5-17
- use get-nic-devs to get netdevices, which gives more general network device name.

* Sat Oct 02 2005 Steven Shiau <steven _at_ nchc org tw> 1.3.5-16
- show "-bz2 is not implemented yet" in partimage_stdin usage.
- comment the "Options for saving:" (-z0, -z1) in usage in drbl-ocs, since now only gzip format image (-z1) works in unicast/multicast restoring.
- fix the bug for unable to make partimage no-gui.

* Sat Oct 01 2005 Steven Shiau <steven _at_ nchc org tw> 1.3.5-15
- refine grep command when mapping the image file size.
- use cat and stdin input for partimage restore to avoid the bug of split images file "Can't read block 0 from image (0)"

* Fri Sep 30 2005 Steven Shiau <steven _at_ nchc org tw> 1.3.5-14
- fix a bug, output_HD_CHS should be run when saveparts.

* Fri Sep 30 2005 Steven Shiau <steven _at_ nchc org tw> 1.3.5-13
- add a function "check_if_input_device_exist" in drbl-ocs.
- remove sync_server and multicast_addr, since sync_server is not necessary when using udpcast, and we only use 224.0.0.1 as the multicast address.
- remove some unnecessary codes, like sync_server, task_notify_connect().
- check if the input devices exist or not.

* Mon Sep 26 2005 Steven Shiau <steven _at_ nchc org tw> 1.3.5-12
- update description in drbl-ocs.

* Sat Sep 24 2005 Steven Shiau <steven _at_ nchc org tw> 1.3.5-11
- format the output of HD CHS to chs.sf.
- add function to load HD CHS value.

* Fri Sep 23 2005 Steven Shiau <steven _at_ nchc org tw> 1.3.5-10
- use routing table for multicast, otherwise it will fail in some situation in Debian.
- use 224.0.0.1 for multicast only

* Sat Sep 17 2005 Steven Shiau <steven _at_ nchc org tw> 1.3.5-9
- change /bin/sh to /bin/bash for shell scripts.
- make "clients+time-to-wait" as default one.

* Fri Sep 09 2005 Steven Shiau <steven _at_ nchc org tw> 1.3.5-8
- fix a bug, we should not remove all start service (except S*single) in rc1.d. Keep what they are. We just remove those services added by "drbl-ocs start".
- do not mix nfs in all distributions, since nfs is server for RH-like, while it's client program in SuSE.

* Tue Sep 06 2005 Steven Shiau <steven _at_ nchc org tw> 1.3.5-7
- fixed a typo variable.
- add an option (-u) so that user can choose restoring image in client.
- add options -k and -t so that we can skip sfdisk and MBR restoring in client.

* Sun Aug 28 2005 Steven Shiau <steven _at_ nchc org tw> 1.3.5-6
- Modify some codes so that drbl-ocs works in SuSE.

* Sun Aug 28 2005 Steven Shiau <steven _at_ nchc org tw> 1.3.5-5
- remove the switch -x when using gethostip.pl

* Sat Aug 27 2005 Steven Shiau <steven _at_ nchc org tw> 1.3.5-4
- use /opt/drbl/bin/gethostip.pl instead of the statically linked gethostip.static.

* Sat Aug 27 2005 Steven Shiau <steven _at_ nchc org tw> 1.3.5-3
- use /opt/drbl/bin/gethostip.static since some necessary pxelinux files is already included in syslinux, and gethostip is compiled as gethostip.static.

* Fri Aug 26 2005 Steven Shiau <steven _at_ nchc org tw> 1.3.5-2
- update some checking for SuSE.

* Wed Aug 03 2005 Steven Shiau <steven _at_ nchc org tw> 1.3.5-1
- use the socket.pl (perl script) instead of binary program socket.

* Mon Jul 18 2005 Steven Shiau <steven _at_ nchc org tw> 1.3.4-14
- fixed some bugs which went wrong in Debian.

* Fri Jul 15 2005 Steven Shiau <steven _at_ nchc org tw> 1.3.4-13
- initial release for DRBL for Debian.

* Sun Jun 19 2005 Steven Shiau <steven _at_ nchc org tw> 1.3.4-12
- add OS_Version tag in force_pxe_clients_boot_drbl

* Tue Jun 14 2005 Steven Shiau <steven _at_ nchc org tw> 1.3.4-11
- fix a bug, should not put RETRUN for trap.
- add -s for parted so that it never prompts quesion.

* Mon Jun 06 2005 Steven Shiau <steven _at_ nchc org tw> 1.3.4-10
- add code to stop mkswapfile in case drbl-ocs is not run in init 1.

* Wed Jun 01 2005 Steven Shiau <steven _at_ nchc org tw> 1.3.4-9
- add more one echo for sfdisk.

* Wed Jun 01 2005 Steven Shiau <steven _at_ nchc org tw> 1.3.4-8
- bug fixed, OCS_OPT should not have -f.

* Wed Jun 01 2005 Steven Shiau <steven _at_ nchc org tw> 1.3.4-7
- remove useless -f parse.

* Thu May 26 2005 Steven Shiau <steven _at_ nchc org tw> 1.3.4-6
- set the default values, we want to make sfdisk --force.

* Tue May 03 2005 Steven Shiau <steven _at_ nchc org tw> 1.3.4-5
- when multicast mode is cancel, stop the program.

* Tue May 03 2005 Steven Shiau <steven _at_ nchc org tw> 1.3.4-4
- add a mode clients+time-to-wait for multicast restoring.

* Sat Apr 30 2005 Steven Shiau <steven _at_ nchc org tw> 1.3.4-3
- Make clonezilla require drbl >= 1.3.10-9

* Fri Apr 29 2005 Steven Shiau <steven _at_ nchc org tw> 1.3.4-2
- Stop LVM before creating partition so that the HD will not be occupied

* Sat Apr 23 2005 Steven Shiau <steven _at_ nchc org tw> 1.3.4-1
- Since drbl-setup, drbl-script and drbl-gdm are merged to a single package "drbl", now clonezilla only depends on drbl.

* Sun Apr 17 2005 Steven Shiau <steven _at_ nchc org tw> 1.3.3-11
- add traps code to avoid leaving junk temp files in /tmp

* Fri Apr 15 2005 Steven Shiau <steven _at_ nchc org tw> 1.3.3-10
- update messages when starting ocs.

* Fri Apr 15 2005 Steven Shiau <steven _at_ nchc org tw> 1.3.3-9
- move some codes to function.
- prompt more messages when starting ocs.

* Wed Apr 13 2005 Steven Shiau <steven _at_ nchc org tw> 1.3.3-8
- rename ocs_clients_job.log as clonezilla-jobs.log and print the info when ocsmgrd starts.

* Tue Apr 12 2005 Steven Shiau <steven _at_ nchc org tw> 1.3.3-7
- add "unicast" description in pxe menu
- add "sleep 5" after udp-receiver to let the udp-receivers to finish their jobs then start the next ones.

* Sun Apr 10 2005 Steven Shiau <steven _at_ nchc org tw> 1.3.3-6
- make drbl-ocs accepts language option

* Tue Apr 05 2005 Steven Shiau <steven _at_ nchc org tw> 1.3.3-5
- fix bug for unable to show startdisk/startparts in client's pxe menu.

* Tue Apr 05 2005 Steven Shiau <steven _at_ nchc org tw> 1.3.3-4
- show image name in client's pxe menu when restoring mode is used.

* Tue Apr 05 2005 Steven Shiau <steven _at_ nchc org tw> 1.3.3-3
- add code to change PXE menu label when mode drbl is switch to clonezilla.

* Thu Mar 31 2005 Steven Shiau <steven _at_ nchc org tw> 1.3.3-2
- fix the bug for unable to set reboot when client finished cloning.

* Thu Mar 31 2005 Steven Shiau <steven _at_ nchc org tw> 1.3.3-1
- use udpcast to send and receive multicast data.
- ocsmgrd now only generate PXE config file, no more dealing with time_to_wait and client_to_wait

* Wed Mar 30 2005 Steven Shiau <steven _at_ nchc org tw> 1.3.2-22
- use system call and lockfile from procmail instead of perl module IO::LockedFile
- change $ocsroot/ocsmgrd.lock to $ocsroot/clonezilla.lock

* Sat Mar 26 2005 Steven Shiau <steven _at_ nchc org tw> 1.3.2-21
- show message when calculating image file size.
- bug fixed,

* Thu Mar 24 2005 Steven Shiau <steven _at_ nchc org tw> 1.3.2-20
- correct typos.

* Thu Mar 24 2005 Steven Shiau <steven _at_ nchc org tw> 1.3.2-19
- correct typos.

* Thu Mar 24 2005 Steven Shiau <steven _at_ nchc org tw> 1.3.2-18
- Do not put absolute path in mcastSender and mcastListener

* Wed Mar 23 2005 Steven Shiau <steven _at_ nchc org tw> 1.3.2-17
- do not put absolute path of parted.

* Tue Mar 22 2005 Steven Shiau <steven _at_ nchc org tw> 1.3.2-16
- change the way to run parted, otherwise might fail.

* Tue Mar 22 2005 Steven Shiau <steven _at_ nchc org tw> 1.3.2-15
- use parted to get partition description instead of file.

* Sat Mar 19 2005 Steven Shiau <steven _at_ nchc org tw> 1.3.2-14
- change "gunzip < $gzipped_image | wc -c" to "zcat $gzipped_image | wc -c".
- change the VOL_LIMIT to 600 from 2000 to avoid the gzip file bug (> 2 GB).

* Wed Feb 24 2005 Steven Shiau <steven _at_ nchc org tw> 1.3.2-13
- change "Program stop" to "Program terminated".

* Tue Feb 22 2005 Steven Shiau <steven _at_ nchc org tw> 1.3.2-12
- partimage 0.6.4 can not accept volume > 2000, so set it as 2000.

* Sat Feb 19 2005 Steven Shiau <steven _at_ nchc org tw> 1.3.2-11
- add function kill_ocsmgrd_daemon so that it's easier to clean stale ocsmgrd before start it.
- check if root in ocsmgrd before run itself.

* Fri Feb 18 2005 Steven Shiau <steven _at_ nchc org tw> 1.3.2-10
- bug fixed, clean the stale $ihost/etc/ocs/config before appending it.
- ocsmgrd will show countdown secs.

* Fri Feb 18 2005 Steven Shiau <steven _at_ nchc org tw> 1.3.2-9
- remove global setting LC_ALL=C in drbl-ocs, otherwise dialog in console will be distored.

* Fri Feb 18 2005 Steven Shiau <steven _at_ nchc org tw> 1.3.2-8
- fix the bug for ocsmgrd to output "01-".$PXECFG_MACFN.

* Thu Feb 17 2005 Steven Shiau <steven _at_ nchc org tw> 1.3.2-7
- "-c" in drbl-ocs should work only when restoring

* Wed Feb 16 2005 Steven Shiau <steven _at_ nchc org tw> 1.3.2-6
- use --no-list-host when calling drbl-client-switch without any specific host in drbl-ocs.

* Mon Feb 14 2005 Steven Shiau <steven _at_ nchc org tw> 1.3.2-5
- fixed the bug - the HOST_OPT1 "$HOST_OPT2" does NOT work when drbl-client-switch run without "-h $IP_LIST"
- ocsmgrd can work with 01-MAC style pxelinux config file.

* Mon Feb 14 2005 Steven Shiau <steven _at_ nchc org tw> 1.3.2-4
- add "-h|--hosts IP_LIST" option, now instead of all DRBL clients, we can assign some mode for some clients by IP address, like: -h "192.168.0.1 192.168.0.2".

* Thu Jan 27 2005 Steven Shiau <steven _at_ nchc org tw> 1.3.2-3
- add perl-IO-LockedFile in Requires.

* Wed Jan 26 2005 Steven Shiau <steven _at_ nchc org tw> 1.3.2-2
- correct some typos.

* Wed Jan 26 2005 Steven Shiau <steven _at_ nchc org tw> 1.3.2-1
- add alias starthda1 for start, will use starthda1 for all the doc in the future.

* Wed Jan 26 2005 Steven Shiau <steven _at_ nchc org tw> 1.3.1-5
- Bugs fixed.

* Wed Jan 26 2005 Steven Shiau <steven _at_ nchc org tw> 1.3.1-4
- Bugs fixed.

* Wed Jan 26 2005 Steven Shiau <steven _at_ nchc org tw> 1.3.1-3
- use the new method for hda1 start/task_restore/task_multicastrestore. Now put the images into a directory.

* Wed Jan 26 2005 Steven Shiau <steven _at_ nchc org tw> 1.3.1-2
- Bugs fixed.

* Tue Jan 25 2005 Steven Shiau <steven _at_ nchc org tw> 1.3.1-1
- Add startparts to save/restore some partitions only.
- Adopt Blake's multicast funtion so that it can process time-to-wait or client-to-wait.

* Wed Dec 29 2004 Steven Shiau <steven _at_ nchc org tw> 1.2.3-4
- add ocs-onthefly.
- turn of the partimage debug by default.

* Sat Dec 11 2004 Steven Shiau <steven _at_ nchc org tw> 1.2.3-3
- change the volume to 4.5 GB.

* Tue Dec 7 2004 Steven Shiau <steven _at_ nchc org tw> 1.2.3-2
- fix the bug when saving SATA

* Wed Nov 18 2004 Steven Shiau <steven _at_ nchc org tw> 1.2.3-1
- use drbl-conf-functions in drbl-ocs.

* Fri Nov 6 2004 Steven Shiau <steven _at_ nchc org tw> 1.2.2-1drbl
- add -m|--module and -s|--skip-hw-detect for drbl-ocs
- add kudzu/harddrake service default
- rewrite some codes, now use ocsmgrd.lock (no more /home/pargimag/ocsmgrd) and /opt/drbl/sbin/drbl-ocs (no more copy and run in /sbin/drbl-ocs in client)

* Wed Nov 3 2004 Steven Shiau <steven _at_ nchc org tw> 1.2.1-4drbl
- add active_proc_partitions so that SCSI devices can be found in drbl-ocs.

* Wed Nov 3 2004 Steven Shiau <steven _at_ nchc org tw> 1.2.1-3drbl
- harddisk search bug fixed!

* Tue Nov 2 2004 Steven Shiau <steven _at_ nchc org tw> 1.2.1-2drbl
- add -M for partimage, it's important when /proc/partitions is devfs style, we can ignore the MBR

* Tue Nov 2 2004 Steven Shiau <steven _at_ nchc org tw> 1.2.1-1drbl
- now drbl-ocs can deal with devfs style format in /proc/partitions
- requires drbl-setup > 1.3.1 for its drbl-functions
- works for /dev/sdx

* Fri Oct 22 2004 Steven Shiau <steven _at_ nchc org tw> 1.1-23drbl
- Add a function to detect grub root partition, now "auto" can be the parameter, i.e. drbl-ocs -g auto...

* Thu Oct 14 2004 Steven Shiau <steven _at_ nchc org tw> 1.1-22drbl
- Now drbl-ocs can deal the /boot directory in another partition for "drbl-ocs -g xxx"

* Sat Sep 18 2004 Steven Shiau <steven _at_ nchc org tw> 1.1-21drbl
- It seems sometimes reboot or shutdown will stop to continue when the cloning finishs... So we force to run reboot or shutdown three times in the end of clone.

* Mon Aug 23 2004 Steven Shiau <steven _at_ nchc org tw> 1.1-20drbl
- fix the bug for failing to change inittab and inittab.org in clients....

- add code to restore the inittab so that if ocsmgr fails to get the message, the client will not clone again.
* Tue Jul 20 2004 Steven Shiau <steven _at_ nchc org tw> 1.1-19drbl
- rewrite notify_ocsmgrd as function.
- add code to restore the inittab so that if ocsmgr fails to get the message, the client will not clone again.

* Fri Apr 23 2004 Steven Shiau <steven _at_ nchc org tw> 1.1-18drbl
- the ethernet port for multicast is detected and echoed in drbl-ocs.

* Thu Apr 22 2004 Steven Shiau <steven _at_ nchc org tw> 1.1-17drbl
- fix bug for checking n_clients when it's not in multicast mode, 
- make clonezilla/checkInodeForDevice.c as static link.
- add batch mode, NIC and swtich notes when using multicast.

* Thu Apr 15 2004 Steven Shiau <steven _at_ nchc org tw> 1.1-16drbl
- fix bug for multicast, sync_server should be assigned runtime in client.
- multicast default gateway should listen on one ethernet port.

* Mon Apr 08 2004 Steven Shiau <steven _at_ nchc org tw> 1.1-15drbl
- fix the bugs for multicast ocs, we can NOT remove the files mcastListener mcastSender partimage_stdin in dir $drbl_common_root/sbin in drbl-ocs script.

* Mon Mar 16 2004 Steven Shiau <steven _at_ nchc org tw> 1.1-14drbl
- add colorful and some warning outputs for drbl-ocs.

* Fri Mar 12 2004 Steven Shiau <steven _at_ nchc org tw> 1.1-13drbl
- add parted script "resize_part" into drbl-ocs, with -r|--resize_partition option

* Fri Mar 12 2004 Steven Shiau <steven _at_ nchc org tw> 1.1-12drbl
- add parted script "resize_part" to resize reiserfs and fat partition.

* Wed Mar 3 2004 Steven Shiau <steven _at_ nchc org tw> 1.1-11drbl
- FC1 seems to lack of envronment variable TERM, so set it in drbl-ocs as linux

* Wed Mar 3 2004 Steven Shiau <steven _at_ nchc org tw> 1.1-10drbl
- mv drbl-client-switch to drbl-script

* Tue Mar 2 2004 Steven Shiau <steven _at_ nchc org tw> 1.1-9drbl
- use static link. 

* Mon Mar 1 2004 Steven Shiau <steven _at_ nchc org tw> 1.1-8drbl
- fix the bug in drbl-client-switch, failed to run mdk-9.2-netinstall.

* Mon Feb 16 2004 Steven Shiau <steven _at_ nchc org tw> 1.1-7drbl
- fix the bug grub-install in drbl-ocs.

* Thu Feb 12 2004 Steven Shiau <steven _at_ nchc org tw> 1.1-6drbl
- fix the bug for SAVE_OPT in drbl-ocs.

* Thu Feb 12 2004 Steven Shiau <steven _at_ nchc org tw> 1.1-5drbl
- fix the filename dhcpd.conf typos in drbl-ocs.

* Thu Feb 12 2004 Steven Shiau <steven _at_ nchc org tw> 1.1-4drbl
- add save options for drbl-ocs.

* Tue Feb 10 2004 Steven Shiau <steven _at_ nchc org tw> 1.1-3drbl
- add verbose mode.

* Tue Feb 10 2004 Steven Shiau <steven _at_ nchc org tw> 1.1-2drbl
- use killall ocsmgrd in drbl-ocs.

* Mon Feb 09 2004 Steven Shiau <steven _at_ nchc org tw> 1.1-1drbl
- Clonezilla with multicast function.

* Thu Feb 05 2004 Steven Shiau <steven _at_ nchc org tw> 1.0-14drbl
- change hdparm -d1 /dev/hda to "turn_on_hd_dma /dev/hda" in drbl-ocs.

* Thu Feb 05 2004 Steven Shiau <steven _at_ nchc org tw> 1.0-13drbl
- add multicast function to drbl-ocs.

* Wed Feb 04 2004 Steven Shiau <steven _at_ nchc org tw> 1.0-12drbl
- force not to check the filesystem when save partition to server. It seems that some ext3 partitions are not friendly to the file system checking of partimage.

* Fri Jan 02 2004 Steven Shiau <steven _at_ nchc org tw> 1.0-11drbl
- fix the bug related to the variable changed in /etc/sysconfig/dhcpd.

* Sat Nov 30 2003 Steven Shiau <steven _at_ nchc org tw> 1.0-10drbl
- add "no PXE only" note for local mode for drbl-client-switch.

* Sat Nov 29 2003 Steven Shiau <steven _at_ nchc org tw> 1.0-9drbl
- add wake on lan in 1-step restoring schedule script.

* Sat Nov 29 2003 Steven Shiau <steven _at_ nchc org tw> 1.0-8drbl
- add restore schedule script.

* Sat Nov 29 2003 Steven Shiau <steven _at_ nchc org tw> 1.0-7drbl
- force to check if sfdisk exits with 0 or not.

* Sat Nov 29 2003 Steven Shiau <steven _at_ nchc org tw> 1.0-6drbl
- add clonezilla mode to the drbl-client-switch.

* Sat Nov 8 2003 Steven Shiau <steven _at_ nchc org tw> 1.0-5drbl
- support network install redhat via pxe/etherboot.

* Wed Oct 1 2003 Steven Shiau <steven _at_ nchc org tw> 1.0-3drbl
- add more functions for drbl-client-switch

* Wed Sep 25 2003 Steven Shiau <steven _at_ nchc org tw> 1.0-1drbl
- Release the clonezilla for RedHat Linux.
