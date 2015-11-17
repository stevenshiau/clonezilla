###Where is the corresponding DRBL client directory in the server ?

It's in /tftpboot/nodes/$IP, where IP is the client's IP address, like /tftpboot/nodes/192.168.0.1.
There are directories:
dev etc root var
under /tftpboot/nodes/$IP.
For common root directory it's in /tftpboot/node_root, where all clients share this same one directory. 

###How can I append the Linux kernel boot time parameters to the DRBL clients ?

You can modify the
/tftpboot/nbi_img/pxelinux.cfg/default
It's almost similar to grub syntax. And if you are familiar with syslinux, it's the same thing.
Say, if you want to append "vga=791" for client, you can find the "label drbl", and modify or append the "append" like

append initrd=initrd-pxe.img ramdisk_size=12288 devfs=nomount drblthincli=off selinux=0 vga=791


###How can I debug in the PXE initrd when clients boot ?

In the early stage in PXE initrd when client boots, there is NO log file. However, you can try to debug by:
1. edit /usr/lib/mkpxeinitrd-net/initrd-skel/linuxrc
or
"/usr/lib/mkpxeinitrd-net/initrd-skel/linuxrc/udhcpc-post"
insert some code to debug, or just put a shell (/bin/sh) so you can enter the shell.
2. run "mknic-nbi" to generate the PXE initrd.
3. reboot the client, then you can see some logs or enter the shell. 

###How can I start a DRBL client service (e.g. cron, sysklogd, klogd...) in the server ?

Only some necessary services of DRBL client are on, so if you need more services, like cron, sysklogd, klogd..., then:
In DRBL server, take service "cron" as an example, run:
drbl-client-service cron on
Then
(1) Reboot the clients, or
(2) Run: drbl-doit -u root "/etc/init.d/cron start"
if clients are already on.

###How can I run vmplayer in the DRBL client machine ?

 Here we take vmware-player 1.0.0-19317 as an example, and this method only works in the CPU arch matches each other in the server and client:
0. Make sure client's kernel is same with server, i.e.
For server, "uname -r"
For client, "cat /tftpboot/nbi_img/kernel_version_in_initrd.txt"
These two must match each other.
The CPU arch must be the same, too.
For server, "uname -m"
For client, "cat /tftpboot/nbi_img/client_kernel_arch.txt"
These two must match each other.
If not, you have to run "drblsrv -i" again, and let kernel of
client is same with that of server, or reinstall the kernel in the server to make it same with that in client.
1. wget http://download3.vmware.com/software/vmplayer/VMware-player-1.0.1-19317.i386.rpm
Or get the in http://www.vmware.com 2. sudo rpm -Uvh VMware-player-1.0.1-19317.i386.rpm
3. sudo vmware-config.pl
4. sudo dcs, then choose "others" -> re_deploy
or
run "drblpush -i" again.
5. Just in case, remove the file /etc/vmware/not_configured in every client by:
sudo drbl-rm-host /etc/vmware/not_configured
6. sudo drbl-client-service vmware on
7. If client is already on, you can run
sudo drbl-doit "/etc/init.d/vmware start"
or
reboot the client
8. login client, run vmplayer
The principle is: (a) The client must have the modules "vmmon" and "vmnet" that vmware need, and they exist in the client's kernel modules. For example, in CentOS 4.2, they exist in /tftpboot/node_root/lib/modules/2.6.9-22.0.1.EL/misc.
(b) The file "/tftpboot/nodes/$IP/etc/vmware/not_configured" should not exist if well configured (by vmware-config.pl).

###Is it possible to run a script on the client after Clonezilla finishes cloning ?

Yes, but not from dcs. You have to use drbl-ocs like this:
drbl-ocs -l 0 startdisk restore -p "mount -t ntfs /dev/hda1 /mnt; chntpwd...; reboot -f -n"
For more info, check "drbl-ocs --help". 

###When I reboot the DRBL client in Ubuntu Breezy Linux, it hangs, What should I do ?

This is a kernel problem, check this for more details:
http://ubuntuforums.org/showthread.php?t=85379
Maybe "reboot=h" will work for you, you can try to put it in /tftpboot/nbi_img/pxelinux.cfg/default like this:
```bash
label drbl
MENU DEFAULT
# MENU HIDE
MENU LABEL Clonezilla: unicast restore to primary IDE HD partition 1 (hda1)
# MENU PASSWD
kernel vmlinuz-pxe
append initrd=initrd-pxe.img ramdisk_size=12288 devfs=nomount drblthincli=off selinux=0 reboot=h
```

###How can I put my own kernel for DRBL clients ?

Ex: The kernel you compiled yourself: name is 2.6.11-1.steven with CPU arch i686.
a. Put these files to DRBL server
1. 3 filres in /boot
System.map-2.6.11-1.steven
config-2.6.11-1.steven
vmlinuz-2.6.11-1.steven
2. put the kernel and modules in /lib/modules, like:
/lib/modules/2.6.11-1.steven
b. depmod -a 2.6.11-1.steven
c. mknic-nbi -k 2.6.11-1.steven -i i686
-k: specifly the kernel name
-i: specify the CPU arch for DRBL clients, such as i386/i586/i686

Now you can boot the client to use the i686 kenrel 2.6.11-1.steven.

###How can I create module for some hardware, like Nvidia, ATI VGA card, to use in client ?

1. If the client uses different kernel with that of server, install the kernel in the server which client is using. Here we take 2.6.12-10-686 as an example.
If you do not know the kernel name and CPU arch, run
cat /tftpboot/nbi_img/kernel_version_in_initrd.txt
cat /tftpboot/nbi_img/client_kernel_arch.txt
to get that.
2. Boot the server to the kernel 2.6.12-10-686
3. Compile and install the module for your hardware, such as download the necessary source from NVidia or ATI website
4. Run
mknic-nbi -k 2.6.12-10-686 -i i686
5. Boot the client, the client now will have the compiled modules.

###How can I share the printer in the server to clients ?

Take Fedora Core 3 as an example:
Assume the DRBL server IP address is 192.168.0.254,
1. Installed the driver and setup the local printer in DRBL server (such as via LPT PORT), and config the CUPS to share the printer (Note: in Fedora Core 3, the default setting of CUPS is DENY ALL, so remember to open that to clents in /etc/cups/cupsd.conf).
2. In DRBL server, config the CUPS network printer, which means set the local printer as network printer. The path is CUPS ipp://192.168.0.254/printers/epsonc60 (You can find the string in /etc/cups/cupsd.conf), and set the network printer as the default printer. Here epsonc60 is just an example, so use yours.
3. Run "drblpush -i" again
4. Boot the client, you will see the network printer, which is the default printer.
PS. Some more hints and discussions are available here Thanks to Robert Arkiletian and Moody for sharing that. 

How can I insert bios flash program and firmware to the freedos so that I can upgrade the BIOS in client ?

Take Asus A8V-MX (client's motherboard) as an example (use the freedos 1.0-8drbl or later version provided by DRBL):
In server:
1. Download
bios firmware:
wget http://dlsvr01.asus.com/pub/ASUS/mb/socket939/A8V-MX/A8V-MX-0503.zip
and flash program:
wget http://dlsvr01.asus.com/pub/ASUS/mb/socket939/A8V-MX/AFUDOS217.zip

2. unzip them:
unzip A8V-MX-0503.zip
unzip AFUDOS217.zip

3. put them into a directory:
mkdir bios
mv AFUDOS.exe A8V-MX-ASUS-0503.ROM bios

4. As root, run insert-file-fdos.sh to put them into the freedos image in /tftpboot/nbi_img/:
insert-file-fdos.sh bios
Then a modified freedos image "/tftpboot/nbi_img/fdos1440_drbl.img" is created.

In client:
5. Now you can PXE boot the client into freedos, and the programs you put are in A:\DRBL\BIOS. You can follow your BIOS manual to upgrade the bios.

###How to get Japanese (Chinene, Korean) input method in English environment ?

Take Fedora Core 4 as an example:
Find a user, say it's john, login as John
0. cd ~/
1. mkdir -p ~/.xinput.d
2. ln -s /etc/X11/xinit/xinput.d/scim ~/.xinput.d/default

To apply this setting to all users,
0. login in the server as root
1. cd ~john/.xinput.d
2. drbl-cp-user -d .xinput.d default

If in the future, you want to remove the directory .xinput.d for every user, run
drbl-rm-user .xinput.d

If you want to make new user can apply this, you can try to add that setting in /etc/skel in the server like this:
0. in server, as root
1. cd /etc/skel
2. mkdir -p ~/.xinput.d
3. ln -s /etc/X11/xinit/xinput.d/scim ~/.xinput.d/default

Therefore, if you add new user later, that file will be automatically copied. 

###How can I hide the mounted NFS icons in my KDE desktop environment ?

In KDE desktop, right click mouse -> configure desktop -> behavior -> device icons -> uncheck "Mounted NFS Share"

If you want to modify the config file for user, just edit the file in his/her home directory:
~/.kde/share/config/kdesktoprc
[Media]
exclude=media/hdd_mounted,media/nfs_mounted,media/floppy5_unmounted,media/hdd_unmounted

To edit the system file, this one:
/usr/share/config/kdesktoprc
...
[Media]
enabled=true
exclude=media/hdd_mounted,media/floppy5_unmounted,media/floppy_unmounted,media/hdd_unmounted/nfs_mounted,media

###What the differences between Full DRBL, Full Clonezilla, DRBL SSI and Clonezilla Box modes ?

|                                                        | Full DRBL | Full Clonezilla | DRBL SSI | Clonezilla Box | 
| ------------------------------------------------------ |:---------------------------:| --------:|----------------|
| /etc, /var of clients                                  | NFS-based | NFS-based       | tmpfs-based | tmpfs-based |
| modified files in /etc and /var of client after reboot | kept      | kept            | gone     | gone           |
| extra space in server per client                       | ~ 50 MB   | ~ 50 MB         | 0        | 0              |
| max client no per ethernet card in server              | 253       | 253             | 253      | 253            |

###How can I make a common directory where clients on any box can read, copy and delete files freely ?

You can make a directory in server, say /home/share and open its mode to everyone like this:
1. mkdir /home/share
2. chmod a+rwx /home/share
If you want the file created by some user and can only be deleted by that user, you have to add this:
3. chmod o+t /home/share
i.e. make it directory "sticky", like dir /tmp/

Then every clients can use the directory /home/share.

###How can I make a local apt mirror in my Debian or Ubuntu DRBL server and use that as an apt repository ?

1. Use the mirror tools to mirror the files in the server, such as:
a. mkdir -p /opt/apt/drbl-core
b. cd /opt/apt/drbl-core; lftp -e "o ftp://linux.nchc.org.tw/dists/drbl-core/ && mirror -e dists && mirror -e pool && quit"

2. edit /etc/apt/sources.list, add a line like this:

deb file:/opt/apt/drbl-core/drbl-core drbl stable

3. Follow the standard installation procedure to finish it.

###How can I hide the mounted NFS share icons in KDE desktop ?

To apply to the whole system, you can modify
/usr/share/config/kdesktoprc
```
[Media]
enabled=true
exclude=media/hdd_mounted,media/floppy5_unmounted,media/floppy_unmounted,media/hdd_unmounted/nfs_mounted,media
append
```
To
```
[Media]
enabled=true
exclude=media/hdd_mounted,media/floppy5_unmounted,media/floppy_unmounted,media/hdd_unmounted/nfs_mounted,media
```
I.e. append the nfs_mounted,media, then those new login user won't have NFS share icons. But those already user, you can ask them to modify manually by:
1. right click in the desktop -> configure desktop -> behavior -> device icons -> uncheck "mounted NFS share"
Or you can modify their ~/.kde/share/config/kdesktoprc as the above.

###How can I debug the clonezilla if it fails ?

0. use dcs to switch the mode you want, like clonezilla-start -> save disk, then you will got a complete drbl-ocs command like:
"drbl-ocs --clients-to-wait 1 -x -z3 -l en startdisk save".
1. in server, run "dcs" -> remote-linux-txt
2. boots the client
3. When client shows the text mode login prompt, in server, run the above command you got, this time, add two extra parameters:"-p true -nogui", like: "drbl-ocs -p true -nogui -v --clients-to-wait 1 -x -z3 -l en startdisk save".
4. login client
5. in client, run "bash -x /etc/rc1.d/S19ocs-run -d start" to get the verbose messages when runing clonezilla. 

###I have some clients which mainboard include NIC, the mainboard supports RPL. How to make the clients to support PXE?

Usually the machine supports RPL can be changed to PXE in the BIOS or NIC firmware. For example, the Realtek 8139 NIC, you can press "SHIFT+F10" when booting, then you can change that. An example is shown here:
http://www.embeddedpc.net/doc/eBox_Boot_ROM_setup_manual.pdf
However, some very old NIC does only have RPL only, then the only solution is to use etherboot or buy a PXE NIC.

###When I use clonezilla to clone MS windows, there is no any problem when saving an image from template machine. However, after the image is restored to another machine, it fails to boot, the error message is "Missing Operating System" or just a blinking underscore. What's going on ?

Usually this is because GNU/Linux and M$ windows interpret the CHS (cylinder, head, sector) value of harddrive differently. Some possible solutions:

    Maybe you can change the IDE harddrive setting in BIOS, try to use LBA instead of auto mode.
    Try to choose both
    [*] -j0 Use dd to create partition table instead of sfdisk
    and
    [*] -t1 Client restores the prebuilt MBR from syslinux (For Windows only)
    when you restore the image.
    Try to choose
    [*] -t1 Client restores the prebuilt MBR from syslinux (For Windows only)
    and *uncheck*
    [ ] -g auto Reinstall grub in client disk MBR (only if grub config exists)
    [ ] -r Try to resize the filesystem to fit partition size
    when you restore the image. You can refer to this discussion. Thanks to Alex Mckenzie for posting this on the forum.
    You can try to boot the machine with MS Windows 9x bootable floppy, and in the DOS command prompt, run: "fdisk /mbr".
    You can try to boot the machine with MS Windows XP/Vista/7 installation CD, enter recovery mode (by pressing F10 key in MS XP, for example), then in the console, run "fixmbr" to fix it. Maybe another command "fixboot" will help, too. For more info, refer to this doc
    Use ntfsfixboot to fix it. This program is included in Clonezila live and its name is partclone.ntfsfixboot, and you can use it to adjust FS geometry on NTFS partitions. By default this should be done by Clonezilla with the option -e1 and -e2 checked. If not, you can force to do that again. For more info, please run "partclone.ntfsfixboot --help" or refer to http://sourceforge.net/projects/ntfsfixboot/.
    Use ntfsreloc to adjust FS geometry on NTFS partitions. For more info, refer to http://www.linux-ntfs.org/doku.php?id=contrib:ntfsreloc. //NOTE// ntfsreloc is an older version of partclone.ntfsfixboot.
    If you get error messages like "0xc0000225, 0xc00000e", and something about Winload.exe, refer to this.
    Some more discussions are available here. 
    
###How can I calibrate the clock of clients ?

You have to install and turn on the ntp server. Take Ubuntu as an example,
1. install ntp service in the server by "apt-get install ntp"
2. re-deploy clients by dcs -> others -> re-deploy
3. turn on the ntp server for client by "drbl-client-service ntp on"
Then everytime when client boot, the service will query the ntp server to calibrate time.

###A message "tftp: client does not accept options" appears in syslog file in server , shall I do someting ?

Do not worry. This is common when you use PXE clients. For more info, check here:http://syslinux.zytor.com/archives/2003-June/002093.html

###Why Clonezilla can _NOT_ image from a large drive to a smaller drive? Any workaround?

It's not easy to implement such a feature, since Clonezilla now is a partition "imaging" tool, by "imaging", it means clonezilla actually does not know the files themself, clonezilla just knows where the used blocks are. Because of this reason, the target partiton size must be equal or larger than the original one so that clonezilla can restore the used blocks on that partition. If the target partitioin size is smaller, then it will go wrong.
Unless Clonezilla has file-based function in the future. Maybe...
If you really still want to make this, check the doc here, this forum or the program fsarchiver. 

###I am trying to restore an image of a 300 Gb drive (with 30 Gb of data) onto a 250 Gb drive, but it gives me an error that the output drive partition doesn't have enough space to fit the image. Is there any way to restore it anyway?

No. Clonezilla is an image-based program, which means the target partition size must be equal or larger than the original one.
However, it's can be done by using GParted (especially GParted live) to resize the source partition, then use Clonezilla to clone partition (not clone disk, i.e. use the option "restoreparts". That also means you have to manually create the partition table on the target disk, and the target partition size must be equal or larger than the source parition). Remember to backup important data before you resize a partition. 

###How can I restore the image from small harddisk to larger one ?

Clonezilla is NOT able to restore the image from LARGE harddisk to smaller one, but it CAN restore the image from small harddisk to larger one. Three choices are available. Here they are:
Choice (1).
0. Save the image in the Clonezilla server.
1. Do a normal restoration to target machine by clonezilla.
2. When clone is finished, use gparted to resize or move the partition. You can install gparted in the DRBL server, then boot the client into remote-linux-gra (dcs -> remote-linux-gra) mode, login client as root, run gparted to do that. Or you can use gparted LiveCD or LiveUSB to do that. A gparted-clonezilla dual boot live CD is available, for more info, check http://gparted.free.fr/GParted-Clonezilla/ or http://www.icewalkers.com/jump.php?AID=2917&src=home.
Choice (2).
0. Save the image in the Clonezilla server.
1. Prepare a partition table (manually created by fdisk in the target machine, then use "sfdisk -d /dev/hda > pt.sf", or you can manually edit that file if you are familiar with that), and backup /home/partimag/$IMA_NAME/pt.sf, then overwrite the /home/partimag/$IMA_NAME/pt.sf.
2. Now use dcs -> clonezilla-start -> clonezilla-restore-disk in server, remember to choose option -r (Resize the partition when restoration finishes).
3. boot the client,
Choice (3).
0. Save the image in the Clonezilla server.
1. Boot the target machine as remote-linux-txt (dcs -> remote-linux-txt).
2. Login in as root in the target machine, use fdisk to create the partitions you want. Remember every partition size should be larger than that in the image file.
3. Now use dcs -> clonezilla-start -> clonezilla-restore-disk in server, remember to choose option -k (Do NOT create partition in target harddisk in client), and option -r (Resize the partition when restoration finishes).
4. boot the client,
That's all. The above scenario I am assuming you are cloning M$ windows (ntfs or fat) or Linux ext2/ext3, since that resize action need ntfsresize, parted and resize2fs. These programs are already in DRBL environment. For other file systems, such as reiserfs, xfs or jfs, you have to install those resize programs in the server, and maybe manually resize is necessary after clone.

###What's the difference between clonezilla and G4L or G4U ?

If file system is supported (ext2, ext3, reiserfs, xfs, jfs, fat, ntfs), only used blocks in harddisk are saved and restored. This increase the clone efficiency. For unsupported file system, sector-to-sector copy is done by dd in Clonezilla. This is different from G4U or G4L. 

###How can I change the yum repository in OpenSuSE/SuSe before I run drblsrv ?

1. Remove all *.repo in /etc/yum.repos.d/ to avoid confusion,
rm -f /etc/yum.repos.d/*
2. Edit the *.repo in /usr/share/drbl/setup/yum-repos/, change opensuse*.repo or drbl*.repo. For example, for OpenSuSE 10.2, you can modify /usr/share/drbl/setup/yum-repos/opensuse-updates-10.2.repo as the following:
```
[updates]
name=OpenSuSE $releasever updates packages
baseurl=http://ftp.twaren.net/Linux/SuSE/update/$releasever/
enabled=1
gpgcheck=1
```
and /usr/share/drbl/setup/yum-repos/opensuse-10.2.repo as:
```
[base]
name=OpenSuSE $releasever packages
baseurl=http://ftp.twaren.net/Linux/OpenSuSE/distribution/$releasever/repo/oss/suse/
enabled=1
gpgcheck=1
```

###If my client computer only supports RPL instead of PXE, can it work with DRBL ?

Yes, if your network card is supported by etherboot. The following explains how to use a RPL client in DRBL environment in Debian.
1. Setup a DRBL server with everything ready
2. apt-get install rpld
3. edit /etc/rpld.conf, make it like:

```
HOST
{
ethernet = 44:4d:50:00:01:8e; // This is the mac address of the client

FILE
{
path = "/tftpboot/nbi_img/rtl8139.zrom";
load = 0x1000;
};
execute = 0x1006;
};
```

rtl8139.zrom can be found from http://www.rom-o-matic.org.
If it's not Realtek chipset, replace the right one for your NIC of client.
4. Edit /etc/default/rpld, make it like:
START_RPLD=yes
(actually 4 is not necessary if you manually start rpld)
5. Find the network card connecting to clients, for example, eth1, then start rpld by
/usr/sbin/rpld -i eth1

###How can I assign the kernel to let client use that ?

 Two methods are available when you install DRBL, one is to use the running kernel in the server, the other one is to use the kernel package (rpm or deb):
(1)drblsrv-offline -s `uname -r`
This means you will let client use the same kernel which DRBL server is running.
(2)To use some kernel rpm or deb to let client use, you have to download the kernel package first, for example, download kernel-2.6.18-8.1.4.el5.i686.rpm from any rpm repository, then:
drblsrv-offline -k kernel-2.6.18-8.1.4.el5.i686.rpm
The kernel you specify for client to use must comply with the CPU arch of client. If you are not sure, you can try to use i586 kernel. However, you will lose the optimization.
For more options about drblsrv-offline, you can run "drblsrv-offline -h" to show that.

###I am sure that the GNU/Linux I have is compatible with the GNU/Linux distribution which DRBL supports, how can I install drbl on that ?

Yes, the only difference is in step <2b> when you install DRBL. You can use drblsrv-offline to make it. For example, Scientific Linux 5.0 is compatible with Fedora or CentOS, you can make it by:
a. Follow the installation doc in the website, in step <2a>, install DRBL rpm package drbl-current.rpm
b. cp /usr/share/drbl/setup/yum-repos/drbl.repo /etc/yum.repos.d/
c. It is recommended to turn on GPG key checking, i.e. set
gpgcheck=1
in /etc/yum.repos.d/sl.repo and /etc/yum.repos.d/sl-security.repo
d. Run "drblsrv-offline -r" to see which required packagesshould be installed in DRBL server.
e. yum install dhcp tftp-server nfs-utils ypserv ypbind yp-tools mkinitrd ntp firstboot iptables wget dialog initscripts rsync parted tcpdump bc grub dos2unix curl lftp openssh-server openssh-clients coreutils gzip bzip2 nc file ethtool net-tools syslinux
yum install mkpxeinitrd-net clonezilla drbl-partimage drbl-ntfsprogs drbl-chntpw drbl-lzop udpcast drbl-etherboot freedos
yum install lvm2 ntfs-3g
f. drblsrv-offline -s `uname -r`
This command means you will let client use the same running kernel in the DRBL server. If you want to assign some kernel rpm to let client use, you have to download the kernel rpm first, for example, kernel-2.6.18-8.1.4.el5.i686.rpm, then run:
drblsrv-offline -k kernel-2.6.18-8.1.4.el5.i686.rpm
The kernel you specify for client to use must comply with the CPU arch of client. If you are not sure, try to use i586 kernel is a good idea. However, you will lost the optimization.
For more options about drblsrv-offline, you can run "drblsrv-offline -h" to show that.
g. drblpush -i
You might see some warning messages, but normally it's fine to live with that. 

###I put a script file like "myscript.sh" in /usr/share/drbl/prerun/drbl, /usr/share/drbl/postrun/drbl, and I check the option "-o0/--run-prerun-dir", or "-o1/--run-postrun-dir", but mscript.sh is not run. Why ?

This is the file name issue, and it normally happens in Deiban or Ubuntu, and won't be in RedHat-like distributions. The main reason is, in DRBL/Clonezilla, the programs in /usr/share/drbl/prerun/drbl, /usr/share/drbl/postrun/drbl are run by the program "run-parts". The file name for run-parts in Debian only accepts that the names must consist entirely of upper and lower case letters, digits, underscores, and hyphens. Therefore your file name has an illegal character ".", therefore run-parts won't run it.
BTW, you can test it by:
run-parts --test /usr/share/drbl/postrun/drbl
For more info, check this:
http://www.debian.org/News/weekly/2002/45/index.de.html

###How can I add a package, say ncpfs, in Clonezilla live ?

Please refer to http://drbl.org/faq/index.php#path=./2_System&entry=46_create_clonezilla_live_from_scratch.faq

###How can I create my own custom script to run in clonezilla live ?

Refer to http://clonezilla.org/clonezilla-live/#Advanced_mode

###What if I have 2 or more squashfs files (filesystem.squashfs) in my system, how can I assign clonezilla live to boot ?

This normally happens when you put a clonezilla live or Debian live in your harddisk, and use clonezilla live CD/USB to boot the system. You can add boot parameter (Ex. bootfrom=/dev/hdc) when booting your clonezilla live. i.e.
1. Boot clonezilla live,
2. In isolinux boot menu, when you see "press [TAB] to edit options", press Tab key.
3. Append the boot parameter, for example, your Clonezilla live CD is /dev/hdc, then you can force live-initramfs to use the file system in /dev/hdc by appending "bootfrom=/dev/hdc", make it like:
vmlinuz1 initrd=initrd1.img boot=live union=aufs vga=788 bootfrom=/dev/hdc

###How can I compile a kernel module on DRBL server so that it can be used for DRBL clients ?

In this example, we assume that the server is running kernel 2.6.30-bpo.1-686-bigmem, and client is running kernel 2.6.32-bpo.2-686 (You can get the client's kernel version number by running: "cat /tftpboot/nbi_img/kernel_version_in_initrd.txt" on the server). We want to compile a kernel module for a network card which can be used on the client.

    Install the kernel 2.6.32-bpo.2-686 on the drbl server if it's not installed. Normally you need to install kernel headers, too
    Get the driver source code for the network card
    Boot the server so it runs the kernel 2.6.32-bpo.2-686
    Compile the driver of the network card, and make install to the system (/lib/modules/2.6.32-bpo.2-686/) (You might need to read the doc from your network vendor about how to compile and install it on the system.)
    Run "mknic-nbi -k 2.6.32-bpo.2-686". This command will update the network boot initrd for the clients. 

You should be able to boot your DRBL client via PXE. 

###How can I compile a kernel module in the DRBL client so that I can use it for DRBL clients ?

1. Make sure the client's IP address where you want to compile, you can get the ip address by:
/sbin/ifconfig -a
In this case, we take 192.168.120.1 for example.
2. In DRBL server, edit /etc/exports, find the following:
/tftpboot/node_root 192.168.120.1(ro,sync,async,no_root_squash,subtree_check)
Modify it, change ro to be rw like this:
/tftpboot/node_root 192.168.120.1(rw,sync,async,no_root_squash,subtree_check)
3. Reload your nfs service, like
/etc/init.d/nfs-kernel-server reload (in Debian-like system)
or
/etc/init.d/nfs reload (in RedHat-like system)
4. Now you can start to compile the module in you DRBL client, and install that in the system (make, make install...).
5. ///NOTE/// When you finish the compilation and installation, before rebooting the client, remember to restore the /etc/exports in the server, i.e. change rw to ro as you have done in step 2, and run step 3 to make it work. If you do not do it, you might mess the system up.

###How can I mirror drbl packages ?

Since rsync serice is not available in free.nchc.org.tw, lftp is recommended. You can use the following script to mirror that. Remember to change the settings.
```bash
#!/bin/sh
# Settings
URL="ftp://free.nchc.org.tw/drbl-core"
local_mirror_dir="/var/www/drbl-core"
[ ! -d $local_mirror_dir ] && mkdir -p $local_mirror_dir

# start mirror...
lftp -e "o $URL && lcd $local_mirror_dir/ && mirror -e --exclude old --exclude legacy --exclude RPMS.drbl-legacy --exclude SRPMS.drbl-legacy && quit"
```

###There is an existing DHCP service in my environment, so it's impossible for me to use the dhcp service comes with DRBL server. Any solution ?

Basically there are 4 solutions:

    Use different port to run DHCP service in DRBL server, this won't conflict with your existing DHCP service. This can be done after you install and configure your DRBL server. Here we take Debian as an example. Make sure your DRBL is version 1.9.0-35 or later:
        Edit your /etc/dhcp3/dhcpd.conf in drbl server, add these two lines:
        local-port 1067;
        remote-port 1068;
        Then restart dhcp service like this:
        /etc/init.d/dhcp3-server restart
        Run this command on DRBL server:
        mknic-nbi --udhcpc-port 1068
        Create Etherboot boot floppy or iso file, which will be used to boot the clients. Use this website http://www.rom-o-matic.net, choose network card and the type you want to create, and the most important is to choose "3. (optional) To customize ROM configuration press:", then check "ALTERNATE_DHCP_PORTS_1067_1068". You will get a dsk for iso file which you can put in the floppy or CD to boot it.
        For more details, refer to this discussion. 
    Another solution is to provide static IP addresses to your DRBL clients by locking them with MAC address. The can be done when you run drblpush to configure your DRBL environment. By doing this, the DHCP service in DRBL server will only provide IP address to your specifiy clients.
    If you still need to provide floating IP address to your DRBL cient, you can try to use DRBL 1.8.0-15 or newer version. By
        Uncommenting the 'allow members of "DRBL-Client";' in /etc/dhcp3/dhcpd.conf, the DHCP service in DRBL server will only provide IP address to PXE, Etherboot or DRBL client.
        Adding 'deny members of "DRBL-Client";' and the following

        class "DRBL-Client" { 
        match if 
        (substring(option vendor-class-identifier, 0, 9) = "PXEClient") or 
        (substring(option vendor-class-identifier, 0, 9) = "Etherboot") or 
        (substring(option vendor-class-identifier, 0, 10) = "DRBLClient"); 
        } 

        in your real DHCP server dhcp config file. 
    For more info, you can refer to this discussion (Thanks to Mr 626) about the settings.
    This mechanism won't affect your existing DHCP service. However, you have to make sure all the PXE or Etherboot clients are DRBL clients.
    You can merge the dhcpd.conf in DRBL server with your existing DHCP services. Then remove the DHCP service in DRBL server. Please refer to this forum. Thanks to Karly De Baere.
    Install dnsmasq. From version 2.49, dnsmasq provides proxy DHCP function. For more details, you can refer to this forum. Thanks to kasatkin for providing this info.

There are some other possibilities to solve this problem. If you need some example, you can refer to this discussion:
https://sourceforge.net/p/drbl/discussion/DRBL_for_Redhat/thread/47eeed7d
Thanks to Nikolay Kasatkin. 

###I have a weird problem when restoring an image. I always got an error message "Can't read the following volume file: ... /stdin.001".

Most of the cases, the reason of the problem is when it saved:
(1) If the image is saved by lzo (-z3 option), and you put the image in the network-based directory, maybe you can try to use gzip to save it (-z1). Lzo need good quality network.
(2) If you are restoring a local image (not in network-based directory), and the image is saved from an ext3 partition of Fedora linux, for example. This is the limitation of partimage. The "Blocks per group" of ext2/3 is always 32768 in partimage. However, in Fedora linux, sometimes this is always true.
Check this for more info: https://sourceforge.net/p/clonezilla/discussion/Clonezilla_live/thread/e87b2148 You can use upgrade to drbl 1.8.1 with drbl-partimage 0.6.7_beta2 or later. This bug was fixed in partimage 0.6.7_beta2. Another choice is you can choose to use "-q2" (use Partclone) when saving the image.
(3) Maybe you hit the kernel/hardware issue, you can try to change to different kernel.

###How can I remaster Clonezilla iso file ?

There are many tools that you can use them to remaster Clonezilla iso, for example:
1. http://littlesvr.ca/isomaster/
2. A script provide by Casual J. Programmer (Works for Clonezilla live version earlier than 1.2.0-1)
http://www.freewebs.com/casualprogrammer/Downloads/editCZCD
You can use that to mount Clonezilla live iso as filesystem, and copy the contents to a r/w location. There any part of the Live-CD can be modified, then made into a new iso image to burn to CD. Thanks to Casual for providing this program.
3. A script provide by Gervasio Susterman (gervasio.susterman _at_ imm gub uy). This one works for Clonezilla live version 1.2.0-1 or later.
You can use that to mount Clonezilla live iso as filesystem, and copy the contents to a r/w location. There any part of the Live-CD can be modified, then made into a new iso image to burn to CD. Thanks to Gervasio Susterman for providing this program. For more info, please refer to this discussion.

###How can I put the kickstart file for netinstall GNU/Linux ?

0. Make sure you already put the netinstall in your DRBL server. If not, run "drbl-netinstall -i all" followed by "generate-pxe-menu". Then use dcs to switch the netinstall.
1. Put your kickstart file in your http or ftp server, in the example, we put ks.cfg in apache server 192.168.120.254.
2. Take CentOS 5.1 as an example, edit /tftpboot/nbi_img/pxelinux.cfg/default, put "ks=http://192.168.120.254/ks.cfg" like this:
```bash
label netinstall-CentOS-5.1-i386
# MENU DEFAULT
# MENU HIDE
MENU LABEL CentOS 5.1 i386 installation via network
# MENU PASSWD
kernel vmlinuz-netinstall-CentOS-5.1-i386
append initrd=initrd-netinstall-CentOS-5.1-i386.img ramdisk_size=65535 ks=http://192.168.120.254/ks.cfg
```

###How can I configure FreeBSD network installation in DRBL server ?

Take FreeBSD 7.0 as an example, and here we assume the client IP address is 192.168.120.2:
1. Download FreeBSD 7.0 boot ISO:
wget ftp://ftp.twaren.net/BSD/FreeBSD/releases/i386/ISO-IMAGES/7.0/7.0-RELEASE-i386-bootonly.iso
2. mount -o loop 7.0-RELEASE-i386-bootonly.iso /mnt
3. mkdir /pxeroot/
4. cp -a /mnt/boot /pxeroot/
cp /mnt/boot/pxeboot /tftpboot/nbi_img/FreeBSD-7.0-pxeboot.0
(You must have the file end with .0, since this tells pxelinux that it is a PXE image)
Add the following in /pxeboot/boot/loader.conf:
```
vfs.root.mountfrom="ufs:/dev/md0c"
```
which means that the later booting process will use a ramdisk as root instead of NFS.
5. append the following in /tftpboot/nbi_img/pxelinux.cfg/default
```
label FreeBSD 7.0 netinstall
# MENU DEFAULT
# MENU HIDE
MENU LABEL FreeBSD 7.0 netinstall
# MENU PASSWD
kernel FreeBSD-7.0-pxeboot.0
```
6. Append one line by edit /etc/exports:
```
/pxeroot/ 192.168.120.2(ro,sync,async,no_root_squash,subtree_check)
```
then restart nfs service (Ex. /etc/init.d/nfs-kernel-server restart)

PS. If you want to assign different PXE root, you can set an option in dhcpd.conf like this:
option root-path "/freebsd7.0-pxeroot/";
Remember to modify /etc/exports and put the files in the corresponding dir.
Ref: http://www.hack.org/mc/freebsd-x60.html; http://www.fefe.de/netboot/how-to-netboot-installer.html 

###How can I restore those *.ntfs-img.* images into a partition manually ?

Say if your image is /home/partimag/YOURIMAGE/, and the image is /home/partimag/YOURIMAGE/hda1.ntfs-img.aa, hda1.ntfs-img.ab..., and you want to restore the image to /dev/hda2.
Before you do it, make sure the partition size of /dev/hda2 is equal to or larger than the original partition size of hda1 image.
Now you can run:
"file /home/partimag/YOURIMAGE/hda1.ntfs-img.aa"
to see it's gzip, bzip or lzop image. Say it's gzip, then you can run
cat /home/partimag/YOURIMAGE/hda1.ntfs-img.* | gzip -d -c | ntfsclone --restore-image -o /dev/hda2 - 

###Is that possible I can read the content of an image (e.g. sda1.ext4-ptcl-img.gz.*) created by Clonezilla ?

Yes, but it's not straightforward. Here you are:

    Method 1: Use Clonezilla live to restore the image to a virtual machine (e.g. VMWare workstation or Virtual Box). Then mount the restored partition to read the contents.
    Method 2:
        Prepare a large disk in Linux
        Say if your image is /home/partimag/YOURIMAGE/, if the image is like /home/partimag/YOURIMAGE/*-ptcl-img.* (e.g. /home/partimag/YOURIMAGE/sda1.ext4-ptcl-img.gz.aa), follow this to restore the image.
        If the the image is like /home/partimag/YOURIMAGE/sda1.ntfs-img.aa, sda1.ntfs-img.ab..., run
        "file /home/partimag/YOURIMAGE/sda1.ntfs-img.aa"
        to see it's gzip, bzip or lzop image. Say it's gzip, then you can run
        cat /home/partimag/YOURIMAGE/sda1.ntfs-img.* | gzip -d -c | ntfsclone --restore-image -o sda1.img -
        Then you will have a "sda1.img" which you can mount it by
        mount -o loop -t ntfs sda1.img /mnt
        Then all the files are in /mnt/
        You can do the similar thing for the ext3, ext4 or reiserfs file system.
    Method 3: Use the tool partclone-utils to mount the image directly. (//NOTE// This program is not maintained by Clonezilla team. However, it will be included in the future release of partclone when the new release, e.g. 0.2 is released.). The example to use partclone-utils to mount the image, and still you need to prepare enough disk space for that:
        Boot Clonezilla live
        Mount the image repository, as normal usage when restoring. However, do not restore the image. Here we just need to read the image
        The following commands have to be run as root (administrator). Therefore run "sudo -i" to become root. Say if your image is /home/partimag/YOURIMAGE/, if the image is like /home/partimag/YOURIMAGE/sda1.ext4-ptcl-img.gz*, from the file name you know its file system is ext4, and is gzipped. You can run
        cat /home/partimag/YOURIMAGE/sda1.ext4-ptcl-img.gz.aa* | gzip -d -c > /home/partimag/my-sda1-img
        This command will generate a single uncompressed image file "my-sda1-img" in the dir /home/partimag/.
        modprobe nbd
        imagemount -d /dev/nbd0 -f /home/partimag/my-sda1-img
        mount -t ext4 /dev/nbd0 /mnt
        Now you have all the files in the dir /mnt/.
        When everything is done, you can:
        umount /mnt/
        pkill imagemount
    
###Is there any way I can save image to CD-RW or DVD-RW directly ?

 Yes, check this for more details: https://sourceforge.net/p/clonezilla/discussion/Clonezilla_live/thread/2cef8368 
 
 ###Is that possible I can put clonezilla live in my harddrive which already has an OS installed ?

Please refer to http://clonezilla.org/livehd.php

###When I use Clonezilla server edition to do a multicast clone, the client machines just keep waiting, any hint ?

Normally you can find the clues in the log files (/var/log/messages or /var/log/daemon.log) about udpcast in your DRBL server. Try to find the keyword "udpcast" in the log files to see the status and why it won't start.
Basically there are some possibilities, and some hints about this issue:

    The network switch has blocked multicast packets. In this case, you have to enable that in your network switch, or check the "-brdcst" in the advanced parameters when you start multicast clonezilla. Thanks to Jean-Philippe Menil for providing this hint about how to check your network switch for multicast function. On the other hand, an unmanaged network switch is another good choice in this case.
    There are more than one network switches in your DRBL environment, and you did not link those switches with cables. If not, do that.
    Your server has more than one network interface and the interface that DRBL has choosen for multicast (udpcast) traffic is not the one you need (eg. eth0 instead of eth1). You can point this in your /var/log files looking for 'udpcast'. It should say something like : udpcast[29960]: Starting transfer: file[] pipe[] port[2232] if[eth0] participants[3].
    You can also point this with a 'ps | grep udp-sender' command that will show the interface used by udp-sender process. It should says something like : udp-sender --full-duplex --min-clients 3 --max-wait 300 --interface eth0 --nokbd --mcast-all-addr 224.0.0.1 --portbase 2232 --ttl 1
    To fix this, edit your drbl-ocs.conf file (/etc/drbl/drbl-ocs.conf) and add a this new variable : eth_for_multicast="eth1" (if eth1 is the interface you need drbl to use).
    You assign the number of clients, but maybe some of them fail to join the multicast clone due to some reason, say, the hardware problem. Check your clients to see if all of them in the same status.
    Make sure your firewall in the DRBL server does NOT block the multicast packets.
    Some buggy network driver for NIC on your server might cause this problem. Try to compile the latest driver or use the latest GNU/Linux as your DRBL server might avoid this problem.
    Make sure you do not create a shortcut to run "dcs", since there are some background programs need to be run, if you use shortcut to run dcs, when dcs is done, the shortcut is finished, and all other background programs will be killed, too. Therefore multicast clone won't work. It's recommended to run dcs in a terminal, If you really want to use shortcut for dcs, remember to check "run in terminal" option when you create such a shortcut.
    Try diffrent kernels both for your Clonzilla SE server and cllients if you can. E.g. Mark Sargent mentioned that his server is running the kernel "Linux Ubuntu 2.6.24-24-Server #1 SMP i686 GNU/Linux" from Ubuntu 8.04, and it was not working very well with multicast clone. After he upgraded the whole system to Ubuntu 8.10 with newer kernel, it's working.
    Make sure the power supply for the machines is powerful enough. Thanks to labiauf for sharing this. For more info, please check this discussion.
    ... 
    
###How can I create Clonezilla live from scratch?

http://clonezilla.org/create_clonezilla_live_from_scratch.php

###I'd like to translate DRBL/Clonezilla to other language, how can I help ?

Thanks for that if you'd like to help this. However, please keep in mind that you will be bothered everytime before a new version is release. :)

    Please download DRBL tarball fie: http://free.nchc.org.tw/drbl-core/src/. It is recommended to use the one in the unstable branch if it is available.
    Untar it by something like: tar jvzf drbl-1.9.1-29.tar.bz2 (please find the latest one).
    You will find two files:
        lang/bash/en_US: For DRBL/Clonezilla both
        lang/perl/en_US: For setting up a DRBL server (Clonezilla SE) 

So far we haven't use gettext for locales. What you have to do now is just to translate those 2 files (remember to use unicode) and save them as your locale name, e.g. ja_JP for Japanese. Then post it in the mailing list or email to steven _at_ nchc org tw or steven_shiau _at_ users sourceforge net.
We will include them in the future release if you finish that.
///Please note///If you want to use editor on MS windows to edit the above files, please use plain text editor, e.g. http://notepad-plus.sourceforge.net to edit them. Do _not_ use MS office to edit that then save that as plain text file, it will put some extra characters and can not be read correctly on Unix system. 

###How can I config my DRBL clients to use Active Directory authentication ?

Setup DRBL server by "drblsrv -i" and "drblpush -i" as mentioned in http://drbl.org/one4all/ normally.

Append "compat winbind" to any client's nsswitch.conf, say /tftpboot/nodes/192.168.100.1/etc/nsswitch.conf

Run "drbl-cp-hosts /tftpboot/nodes/192.168.100.1/etc/nsswitch.conf /etc/"

Run "drbl-client-service samba on"

Run "drbl-client-service winbind on" Ref: https://sourceforge.net/p/drbl/discussion/Help/thread/b6db0c00 

###How about the unique license key for each MS windows machine after I clone them ?

MS provides a program sysprep:
http://technet.microsoft.com/en-us/library/bb457073.aspx
It allows you to reenter the license key. Of course, you have to do it one by one. 

###I have a class B subnet, the range is 172.16.0.1 - 172.16.31.254, how can I configre DRBL to fit this range ?

By default, DRBL only allows you to do range: 172.16.0.1 - 172.16.0.254. However, you still can make it by the following:

    When run drblpush, select DRBL SSI mode and Clonezilla box mode, this will save the disk space, otherwise drblpush will generate a lot of files, take a huge space. Or just run this command::

       drblpush -i -r 1 -z 1 (Then accept all the default values)

    Modify /etc/dhcpd.conf (or /etc/dhcp3/dhcpd.conf) as:

    subnet 172.16.0.0 netmask 255.255.0.0 {
    	option subnet-mask  255.255.0.0;
    	option routers 172.16.0.2;
    	next-server 172.16.0.2;

    	pool {
                    # allow members of "DRBL-Client";
    		range 172.16.0.1 172.16.31.254;
    	}
    }

    Modify /etc/exports, append the following:

    /tftpboot/node_root 172.16.*.*(ro,sync,async,no_root_squash,subtree_check)
    /usr 172.16.*.*(ro,sync,async,no_root_squash,subtree_check)
    /opt 172.16.*.*(ro,sync,async,no_root_squash,subtree_check)
    /home 172.16.*.*(rw,sync,async,no_root_squash,no_subtree_check)
    /var/spool/mail 172.16.*.*(rw,sync,async,root_squash,no_subtree_check)

    4. Run "drbl-all-service restart" to restart the services. 
    
###What's the difference between multicast, broadcast and unicast function in Clonezilla SE ?

 This description was modified from the doc of udpcast, which is used in Clonezilla for multicast or broadcast:
The multicast function allows sending the data only to those receivers that requested it. Ethernet cards of machines which don't participate in the transmission automatically block out the packets at the hardware level. Moreover, network switches are able to selectively transmit the packets only to those network ports to which receivers are connected. Both features thus allow a much more efficient operation than broadcast.

Therefore if your switch does not block multicast packets, it's better to use multicast function.

###How can I run Clonezilla live using serial console ?

 Yes, from Clonezilla live 1.2.1-11 or later, you can append the following to the boot parameters:

live-getty console=ttyS0,38400n81

Then Clonezilla live will shown in the serial console ttyS0.

###How can I compile and put an extra module on Clonezilla live ?

0. Boot clonezilla live, enter command line prompt
1. sudo su -
2. Configure network by "ocs-live-netcfg"
3. Change /etc/apt/sources.list if necessary. You can use a mirror site near you so that it's faster to download the required package.
4. apt-get update
5. apt-get install linux-headers-`uname -r` build-essential
6. Then you can start to compile your module. Once the kernel module is ready, you can follow this to use some parameters to use that. Please refer to 2nd example.

###Is that possible I can save Clonezilla image on a rewritable CD/DVD directly when using Clonezilla live ?

Yes, with UDF format, you can mount rewritable CD/DVD as Clonezilla home.

    Prepare a UDF format CD/DVD, if it's a new CD/DVD, you can format it in Clonezilla live command prompt by (Take CD/DVD device name /dev/sr0 as an example):
    Run command "sudo su -" to become root, then
    dvd+rw-format -force=full /dev/sr0
    (Replace /dev/sr0 with your CD-ROM device name).
    Edit /etc/default/udftools, add your CD-ROM device name:
    DEVICES="/dev/sr0"
    Run command "dpkg-reconfigure udftools", it will show:
    /dev/pktcdvd/0=/dev/sr0
    mkudffs --lvid="dvd-clonezilla" --udfrev=0x0150 /dev/pktcdvd/0
    mount -t udf -o rw,noatime /dev/pktcdvd/0 /home/partimag/ 

Now the clonezilla image home is ready, you can continue to run "ocs-sr -x" to save the image. 

###How much space do I need when saving an image ?

 This really depends. It depends on the data on a partition, and the compression algorithm you choose.
Normally if you choose to use gzip, and the partition is an OS (GNU/Linux, MS Windows) partition, the space required is about 1/3.
E.g. For 45 GB data used on a 100 GB harddrive, you will need about 15 GB space to save the image.

###Why stable and testing Clonezilla live are based on Debian, but alternative one is based on Ubuntu ?

The reasons to do so are:

    We want a "free" Clonezilla live, so all the packages are from main of Debian, no non-free in stable or testing Clonezilla live.
    However, the all free version of Clonezilla live sometimes could not support the latest hardware. Therefore we provide another option, i.e. alternative Clonezilla live based on Ubuntu Linux. It includes non-free firmware, and also supports uEFI secure boot (AMD64 version only).

The differences between stable/testing and alternative branches: 

###How can I make Clonezilla SE (DRBL) server as a RIS server, too ?

Thanks to Max Bash for sharing his experience. Now you can refer to this forum about how to make Clonezilla SE (DRBL) server as a RIS server: https://sourceforge.net/p/clonezilla/discussion/Clonezilla_server_edition/thread/f51c6eff

###How to add MAC addresses of new clients in DRBL ?

This depends on which mode you are using.

    Clonezilla box mode, this is easier.
    Edit dhcpd.conf, follow the format to add MAC addresses of clients, then run "dcs", choose "more", then "gen_3N_conf", or this command "drbl-3n-conf generate".
    Full Clonezilla mode, this is more complicated.
    It's easier to do that in the following way:
    1. copy the existing /etc/drbl/macadr-eth*.txt in a working dir, e.g.
    cd ~/
    cp /etc/drbl/macadr-eth1.txt .
    (If you have more macadr-eth*.txt, you have to decide you want to connect which clients to which file)

    2. Append your new MAC addresses of clients in macadr-eth1.txt by an editor, e.g. vim or gedit or whatever text file editor (not OpenOffice.org...).

    3. Run "drblpush -i" again. This time choose not to collect the MAC addresses of clients, and when it asks about the MAC addresses list file, input macadr-eth1.txt for those clients connecting to eth1 on DRBL server, and macadr-eth2.txt for those clients connecting to eth2 on DRBL server...

    4.Once "drblpush -i" is finished, the new clients are added.

    Of course you can manually edit dhcpd.conf, and run some other commands (e.g. drbl-gen-client-files) to generate new clients' DIR in /tftpboot/nodes/. However, this will require more knowledge and steps.
    
###Is there a way to make a hardware independent image with CloneZilla?

Not really. But there are some hints:

    For GNU/Linux image, it's very possible, you have to pay attention to the kernel-hardware support issue. Try to use generic kernel and install as many drivers as possible in your source machine. Then the created image will support hardware better.
    For MS windows, you have to install sysprep from MS in your windows of source machine before grabbing it as an image. Then the created image will rescan the hardware and ask for the license key.
    For more info, please refer to this forum. Thanks to Steve Holmes for sharing this.
    
###Is that possible I can hack my buggy PXE bootrom ?

https://sourceforge.net/p/drbl/discussion/Open_discussion/thread/c0545e8f

###I got a "tftp timeout" error on my DRBL client...

To fix this, first you have to check the log files (/var/log/messages, /var/log/daemon.log, /var/log/syslog) on DRBL server to see if any related message about tftp. Some hints to fix it:

    There are two or more DHCP services on the same network subnet which your DRBL clients connect. Make sure there is only one, either to isolate them or disable them, only keep the DHCP service on DRBL server.
    The TCP wrapper settings (/etc/hosts.deny and /etc/hosts.allow) have blocked the connection, so you have to modify /etc/hosts.allow and /etc/hosts.deny to allow your clients to access DRBL server.
    The SELinux on DRBL server has blocked tftp service, so the tftp service was not started successfully. Either to enable tftp in SELinux, or you can just disable SELinux completely.
    The network switch has blocked tftp UDP packets... You have to tune the configuration of network switch.
    Stale ARP table cache problem on your network switch or DRBL server. Shutdown them, unplug the power cable. Wait for a few minutes, then boot them.
    Try to run "drbl-all-service restart" to restart all the DRBL-related services.
    ... 
    
###lonezilla live gives me "kernel panic" or can not detect my hard drive, network card... Any solution ?

If the stable version of Clonezilla live gives you an error "kernel panic" when booting, or it does not scan the hardware and list it when you want to clone, maybe you can give testing (Debian based) or experimental (latest Ubuntu based) Clonezilla live a try. It might comes with newer kernel so maybe it improves. You can download them on: 


###Does Clonezilla support RAID ?

Clonezilla does support hardware RAID, if your RAID device is seen as /dev/sda, /dev/sdb, /dev/hda, /dev/hdb, /dev/cciss/c0d0... on GNU/Linux. Clonezilla does support this.
On the other hand, if it's Linux software RAID, no, Clonezilla does not support that. 

###How can I enable sudo privilege for an account on clients ?

You had to manually edit the sudoers file on drbl server:
visudo /etc/sudoers
Append the account in it. Take account "john" as an example:

john        ALL=(ALL) ALL

Then run "drblpush -i".
BTW, on Ubuntu Linux, the root account is not really usable (i.e. you can not login on console) until you assign it a password on the server. The default is no password.
Thanks to lophat at users.sourceforge.net for providing this hint.
Ref: https://sourceforge.net/p/drbl/discussion/DRBL_for_Debian/thread/c1bc4061 

###Using multicast clone on Clonezilla SE, for one client the speed is fast, but more than one, it's very slow. Any idea ?

Normally when imaging one client machine, say the rate is 1000 MB/min, with more than one, the rate should be still similar to 1000 MB/min. If this is not your case, please check:

    The network switch. Make sure it works well for multicast packets. Try to replace a different brand of switch then test it again. We do have experience with some of the 24-port gigabits switch with very poor performance when multicast restoring (~150 MB/min). With another 8 gigabits switch, it works very well (~2 GB/min).
    Make sure all your clients have flawless network cards and hard drives. Due to the multicast mechanism, if one of your clients has buggy network card or hard drive, it will make all the machines clone slowly.
    Make sure your GNU/Linux uses the right kernel module for your network card. For example, someone reported that on his Clonezilla SE server, the system always uses kernel module r8169 for his network card when booting. However, module r8101 is the right one. Therefore he has to "rmmod r8169" then "modprobe r8101".
    Some weird cases... Some repored that if LAN boot is on in the machine's BIOS, even it's not power-on, that client still bothers the multicast clone. He has to unplug that client machine. BTW, the client machine comes with Intel(R) 82567LM Gigabit network card. Ref: http://groups.google.com.tw/group/drbl/browse_thread/thread/d87fbe17afea174c?hl=zh-TW (Chinese)
    ...
    If all the above does not apply, maybe you can try to tune the config on your Clonezilla SE, by modifying this file "/etc/drbl/drbl-ocs.conf", change
    udp_sender_extra_opt_default=""
    as
    udp_sender_extra_opt_default="--max-bitrate 150m"


###How can I restore those *-ptcl-img.* images into a file manually ?

 Say if your image is /home/partimag/YOURIMAGE/, and the image is /home/partimag/YOURIMAGE/sda2.ntfs-ptcl-img.gz.aa, sda2.ntfs-ptcl-img.gz.ab..., and you want to restore the image to a file sda2.img which you can mount later.
Before you do it, make sure the disk space is big enough for you to store this image file "sda2.img".
Now you can run:
"file /home/partimag/YOURIMAGE/sda2.ntfs-ptcl-img.gz.aa"
to see it's gzip, bzip or lzop image. Say it's gzip, then you can run

    cd /home/partimag/YOURIMAGE/
    cat dir/sda2.ntfs-ptcl-img.gz.* | gzip -d -c | partclone.ntfs -C --restore_raw_file -s - -o sda2.img 

(There is a bug about this mode for partclone 0.2.66 to 0.2.69. You should use partclone version >= 0.2.70 for this purpose.)
Now you can mount the file sda2.img by:

mount -o loop sda2.img /mnt

and all the files are in the dir /mnt/. 

###What are the differences between partclone and ntfsclone ?

Basically partclone.ntfs and ntfsclone are the same. Both of them are based on the libntfs. However, partclone.ntfs has some improvements:

    CRC checking info is stored.
    TUI (Terminal User Interface) output is available for partclone.
    partclone can do partition clone directly. E.g.

    partclone.ntfs -b -s /dev/sda1 -O /dev/sdb1

    For ntfsclone, no such option allows you to do so, then you have to pipe.
    More messages are shown when running partclone. 

So that's why we switched to partclone.ntfs. BTW, we sent the patch file (part 4 in the above) to linux-ntfs project, but so far we do not see it will be included or not. 

###How to use DRBL with existing Altiris setup ?

https://sourceforge.net/p/drbl/discussion/DRBL_for_Debian/thread/8b12292f

###After I restored an image to my Macbook, it fails to boot. Any method to make it boot again?

 Please refer to https://sourceforge.net/p/clonezilla/discussion/Clonezilla_live/thread/114fa7dc form. The key is to do an Option boot - hold down the option key on power up. It displays the hard drive. Selected it. Thanks to Ray (sunnydaze) for sharing this. 

###How can I modify the contents of initrd.img from Clonezilla live?

The file initrd.img from the Clonezilla live is not a ext2 file system, it's cpio format. Therefore you can not mount it, instead you have to do something like this:

The initrd.img maybe in gzip format, or in xz format. You can use command "file initrd.img" to know the foramt.

(1) mkdir ~/tmp/initrd; cd ~/tmp/initrd

(2) for gzip format, run: zcat initrd.img | cpio -idm
    for xz format, run: xzcat initrd.img | cpio -idm

Then you can edit the files in ~/tmp/initrd. After that, you can use the following command to pack it as new initrd.img:

(3) cd ~/tmp/initrd

(4) For gzip format, run: find . | cpio --quiet -o -H newc | gzip -9 > ../initrd.img
    For xz format, run: find . | cpio --quiet -o -H newc | xz -c -9 --check=crc32 >  ../initrd.img

Then the new one is in ~/tmp/initrd.img

###How can I use the recovery-iso-zip function if I use PXE to boot Clonezilal live?

When you boot Clonezilla Live with PXE, and use Recovery-iso-zip tool, you will get this error:

No system files from template live iso are found ! Something went wrong!

To save the space, we do not put vmlinuz1 and initrd1.img in "/live/image/live" directory. That's why you got this error.
If you want to make it, you have to copy the vmlinuz1 and initrd1.img to /live/image/live. For more info about how to make it, you can refer to this discussion.

###How can I modify the settings of DRBL SSI mode? e.g. the bash prompt?

DRBL SSI mode uses template tarballs (/tftpboot/node_root/drbl_ssi/template*.tgz) for clients, so if you want to modify the setting, you can make it:

    For example, take client 192.168.100.1 as the template, you can modify /tftpboot/nodes/192.168.100.1/etc/bash.bashrc
    Once you have finished that, run:

    drbl-gen-ssi-files -t 192.168.100.1

    Here we force to use 192.168.100.1 as the template. //NOTE// if you run drbl-gen-ssi-files without "-t" option, it will use the first one available in /tftpboot/nodes/, which might be different from the one you have modified. 
    
    
###What are the compression options in Clonezilla? What are the differences?

In the Clonezilla, the compression opitons are:

    -z0, --no-compress Don't compress when saving: very fast but very big image file (NOT compatible with multicast restoring!!!)
    -z1, --gzip-compress Compress using gzip when saving: fast and small image file (default)
    -z1p, --smp-gzip-compress Compress using parallel gzip program (pigz) when saving: fast and small image file, good for multi-core or multi-CPU machine
    -z2, --bz2-compress Compress using bzip2 when saving: slow but smallest image file
    -z2p, --smp-bzip2-compress Compress using parallel bzip2 program (pbzip2) when saving: faster and smallest image file, good for multi-core or multi-CPU machine
    -z3, --lzo-compress Compress using lzop when saving: similar to the size by gzip, but faster than gzip.
    -z4, --lzma-compress Compress using lzma when saving: slow but smallest image file, faster decompression than bzip2. 

In the above optioins, "-z0" is the same with "--no-compress", and so on...
You can refer to some benchmark report about the speed and time for gzip, bzip2, lzo, and lzma... e.g.

###I'd like to customize the Clonezilla boot menu, any doc I can refer?

Clonezilla live or Clonzilla SE uses syslinux, isolinux or pxelinux as the boot loader by default. You can refer to syslinux webiste for more detials. For the simple menu doc, you can refer to this doc which is from the tarball of syslinux. 

http://www.syslinux.org/wiki/index.php/The_Syslinux_Project

http://drbl.org/faq/2_System/files/syslinux-pxelinux-simple-menu.txt

###I have more than 1 network card on my DRBL client, how can I force the client to use the specific network card, i.e. with priority, to connect to DRBL server when booting in the initramfs?

You can make it by running the following command on the DRBL server:

mknic-nbi --netdev "eth1 eth0"

to force the client to use eth1 first, then eth0.
For more info, please run: mknic-nbi --help

###How can I add a program in the main file system of Clonezilla live, i.e. in the file "filesystem.squashfs"?

The follow describes how to build a filesystem.squashfs on Debian Squeeze (6.x). The example here we have is to add a program "ms-sys".

    Follow http://ms-sys.sourceforge.net/, you can compile ms-sys binary code for lenny ("make", "gcc", and "gettext" packages are required to compile ms-sys), say "~/ms-sys-2.3.0" is its source path.
    Add Debian backports repository to Debian Linux and install new version squashfs-tools. i.e.
    Add the follow line into /etc/apt/sources.list:

    deb http://backports.debian.org/debian-backports squeeze-backports main

    Update repository and install squashfs-tools:

    $ sudo apt-get update; sudo apt-get -t squeeze-backports install squashfs-tools

    It should install a backports version of squashfs-tools which supports XZ compression, and you can use the follow command to confirm:
    $ dpkg -l squashfs-tools
    Download Clonezilla live 2.0.1-1 zip file, then uncompress clonezilla-live-2.0.1-1-i686-pae.zip and extract the original filesystem.squashfs

    $ mkdir ~/zip-tmp ~/squashfs-tmp
    $ unzip clonezilla-live-2.0.1-1-i686-pae.zip -d ~/zip-tmp
    $ cp ~/zip-tmp/live/filesystem.squashfs ~/squashfs-tmp
    $ cd ~/squashfs-tmp; sudo unsquashfs filesystem.squashfs
    (it will extract filesystem.squashfs to directory "squashfs-root" )

    Copy ms-sys binary files into relative path of squashfs-root:

    $ sudo cp ~/ms-sys-2.3.0/bin/ms-sys squashfs-root/usr/local/bin

    Rebuild the new filesystem.squashfs and replace the original one ,then rebuild clonezilla-live zip file with a XZ-compressed filesystem.squashfs:

    $ sudo mksquashfs squashfs-root filesystem.squashfs.new -b 1024k -comp xz -Xbcj x86 -e boot
    $ sudo cp filesystem.squashfs.new ~/zip-tmp/live/filesystem.squashfs
    $ cd ~/zip-tmp ; sudo zip -r ../clonezilla-live.new.zip ./*

    Now you have clonezilla-live.new.zip with ms-sys included. 
    
###I knew the network card of my DRBL client is supported by the kernel, however it fails to load the module during PXE booting. What can I do?

The problem maybe on the initrd system can not identify your networt card of client machine correctly while it is trying to load the kernel modules.
If you are sure the module for the network, say, it's "tg3", then you can run the following command on the server to force the module to be loaded during booting:

mknic-nbi --modules "tg3"

Some discussions about this on the forum are available here. 
https://sourceforge.net/p/clonezilla/discussion/Clonezilla_server_edition/thread/8faf9cff

###When I save an image, I see messages like "{ DriveReady Error }" or "{ DriveReady DataRequest Error }", what can I do?

Normally when you see messages like:

hda: possible failed opcode: 0xc8
dma_instr: status=0x41 { DriveReady Error }
hda: task_pio_intr: status=0x49 { DriveReady DataRequest Error }
io_all: errno = Input/output error(5)

It means that your hard drive has hardware issues, e.g. bad blocks. You'd better to copy important data before you continue to use it. If you want to use Clonezilla to save the image, you can try to enter expert mode, choose "-q2" and "-rescue" (the rest of options can be default ones) so that it can use the rescue mode of partclone to save the image for you. However, this does not mean it always work. Good luck! 

###How can I re-registering the individual MS Office installations with their own keys after the system is restored by Clonezilla?

https://sourceforge.net/p/clonezilla/discussion/Open_discussion/thread/3a22e086

###I got the error message "invalid or corrupt kernel image" when I boot clonezilla live CD, any hints?


    Run md5sum or sha1sum check before you burn the iso file on a CD. This will help you to make sure the copy you have is the same with the one on the download site.
    Use vritual machine, e.g. virtualbox, qemu, kvm, or vmware (or whatever you have) to test the ISO file you have downloaded.
    Try the CD on different machine. This will help you to make sure if it's a hardware (CD, CD drive, or other parts) issue.
    If you still have problem, try to diffent boot media, e.g USB flash drive to boot Clonezilla live. You can refer to this. 

https://help.ubuntu.com/community/HowToMD5SUM

http://clonezilla.org/clonezilla-live/#make

###I got an error "0xc00000e" after my MS Windows 7 image was restored. Any solution?

If you get error "0xc00000e : Can't run WINLOAD.EXE" after restoring a Windows7 image...

    Boot with the Windows7 DVD
    Choose the Repair option
    Reboot the repaired Windows7
    Remove all entries in the Registry HKLM\System\MountedDevices\ except Default
    Reboot with CloneZilla to make a new image
    Restore the new image: You should now be able to boot Windows7 

For more info, please refer to this discussion. Thanks to Gilles for sharing this.
Another way to solve this issue is to enable AHCI in Win7 before the clonezilla. You can refer to:

    http://www.sevenforums.com/tutorials/61869-ahci-enable-windows-7-vista.html
    http://support.microsoft.com/kb/922976
    Set HKEY_LOCAL_MACHINE\System\CurrentControlSet\Services\Msahci to "0".

For more info, please refer to this discussion. Thanks to Stormy for sharing this. 

http://www.sevenforums.com/tutorials/61869-ahci-enable-windows-7-vista.html

http://support.microsoft.com/kb/922976

https://sourceforge.net/p/clonezilla/discussion/Help/thread/158aa4fe

https://sourceforge.net/p/clonezilla/discussion/Help/thread/64bc0842/?limit=25#4b93

###How can I create Clonezilla live iso file from clonezilla live zip file?

On a GNU/Linux system, download Clonezilla live zip file (version 1.2.3-28, 20100121-karmic or later, please). Here we take cloneizlla-live-2.2.2-32-i686-pae.zip as an example. Then run the following commands:

    mkdir /tmp/zip2iso
    unzip clonezilla-live-2.2.2-32-i686-pae.zip -d /tmp/zip2iso/
    cd /tmp/zip2iso/
    genisoimage -A 'Clonezilla live CD' -f -r -hide-rr-moved -hide-joliet-trans-tbl -J -l -allow-limited-size -b syslinux/isolinux.bin -c syslinux/boot.cat -no-emul-boot -boot-load-size 4 -boot-info-table -eltorito-alt-boot -efi-boot EFI/images/efiboot.img -no-emul-boot ./ > /tmp/clonezilla-live.iso 

Then the created iso file clonezilla-live.iso is in the dir /tmp/. 

###What do these restore options (-g auto, -t, -t1, -j1, -j2, -k, -k1, -j0, -r...) actually do?


    -g auto (default: checked): "Reinstall grub in client disk MBR (only if grub config exists)" This option will check if a grub boot loader exists in the MBR, if it exists, and a grub config file (/boot/grub/grub.cfg or /boot/grub/menu.lst) is found in restored partition(s), grub-install command will be run to reinstall grub boot loader.
    -t (default: unchecked): "Client does not restore the MBR" By default Clonezilla will clone or restore the MBR by dd, i.e.

    dd if=$IMAGE_DIR/$HARDDRIVE-mbr of=/dev/$HARDDRIVE bs=446 count=1

    If option "-t" is checked, this dd command won't be run.
    -t1 (default: unchecked): "Client restores the prebuilt MBR from syslinux (for Windows only)" If this option is checked, Clonezilla will dump a pre-build mbr file called mbr.bin (it's from syslinux) to the destination disk by:

    cat mbr.bin > /dev/$HARDDRIVE

    -j1 (default: unchecked): "Write MBR (512 B) again after image is restored. Not OK for partition table differ from that of the image" In some cases, sfdisk uses different CHS values to create the partition table (due to different kernels have different CHS values of hard drive), and it will make the restore OS fail to boot. With this option checked, a command:

    dd if=$IMAGE_DIR/$HARDDRIVE-mbr of=/dev/$HARDDRIVE bs=446 count=1

    will be run again after all the partitions are restored.
    -j2 (default: checked): "Clone the hidden data between MBR and 1st partition" Some vendor put some hidden data in the space between MBR and 1st partition. e.g. IBM thinkpad uses this for function key F11 to trigger the recovery action. Without this hidden data, F11 won't work.
    -k (default: checked for restoredisk, and unchecked for restoreparts): "Do NOT create a partition table on the target disk" By default Clonezilla will create the partition table in the destination disk. If a partition table exists on the destination disk, and you do not want Clonezilla to overwrite it, you can check this option.
    -k1 (not default value): "Create partition table proportionally (OK for MBR format, not GPT)" By using this option, clonezilla will try to create the partition table on the destination disk proportionally. E.g. a 100 GB source disk with 2 partitions 20 GB and 80 GB, when -k1 option is checked, if the destination disk is 200 GB, the partitions created on the destination disk will be 40 GB and 160 GB.
    -j0 (default: unchecked): "Use dd to create partition" By default Clonezilla will use sfdisk to create the partition table. However, due to the CHS value might be different, the created partition table maybe won't work for some OSes, and it makes the restored OS fail to boot. With this option checked, you can force Clonezilla to use dd to dump the binary image data from the source disk or image.
    -r (default: checked): "Try to resize the filesystem to fit partition size". When this option is checked, the file system size on a partition will be tuned to fit the size of partition. E.g. on a 100 GB partition, the file system size might be only 60 GB (There is no need that the file system size must be equal to the partition size), with "-r" checked, clonezilla will try to use file system utils, e.g. "e2fsck" (for ext2/3/4), "resize_reiserfs" (for reiserfs), "ntfsresize" (for ntfs) to resize the file system size to fit the partition size. In this example, the file system size will be resized to be 100 GB. This option only deals with the file system size on a parttiion, so it's nothing to do with partition size. It's different from the option "-k1", which deals with the partition size.
    -e1 auto (default: checked): "Automatically adjust filesystem geometry for a NTFS boot partition if exists". When a NTFS exists, and its the boot loader partition for MS windows, clonezilla will try to use partclone.ntfsfixboot to set geometry and location parameters in NTFS filesystem, so it can boot. For more info, please check ntfsfixboot website.
    -e2 (default: checked): "sfdisk uses CHS of hard drive from EDD (for non-grub boot loader)". When sfdisk creates the partition table on the destination disk, the CHS (cylinder, head, sector) number is read from EDD, not that from kernel. This is for non-grub boot loader, especially the boot loader of MS Windows. This option will not take effect if the boot loader on the destination disk is grub. 

###I got an error message like "FS has been mounted 3234324234 times without being checked" in Clonezilla live. What can I do?

Enter expert mode, check the option "-fsck-src-part". 

###I have put some prerun and postrun scripts in DRBL server, but it does not work. What happends?

Some hints:

    If you are using DRBL SSI or Clonezilla box mode, after you put the files in
    /tftpboot/node_root/opt/drbl/share/ocs/prerun
    and
    /tftpboot/node_root/opt/drbl/share/ocs/postrun

    Remember to run /opt/drbl/sbin/drbl-gen-ssi-files to update the SSI files. It's can be done by running "/opt/drbl/sbin/dcs" -> more -> gen-template-files. Make sure you put the files in the correct template dir (i.e. the first one in /tftpboot/nodes/) before you run /opt/drbl/sbin/drbl-gen-ssi-files. Or you can use /opt/drbl/sbin/drbl-gen-ssi-files -t $IP_ADDRESS" to specify the template machine ($IP_ADDRESS means the dir /tftpbpot/nodes/$IP_ADDRESS).
    Remember to check this faq, too. 
    
http://drbl.org/faq/fine-print.php?path=./2_System/31_prerun_postrun_not_working.faq#31_prerun_postrun_not_working.faq

###I sent you an email directly from my sourceforge account, but I did not get any response. Why?

 We tried to answer every question if we can. Most of the cases are, you did not configured your email account on your sourceforge account correctly. Most of the time when we reply to account like: xxx@users.sourceforge.net, we get a rejected email:

```
The Postfix program
(xxx@users.sourceforge.net): host mx.sourceforge.net[216.34.181.68]
    said: 550 unknown user (in reply to RCPT TO command)
```

So please make sure you have configured your email account _ON_ _SOURCEFORGE_ _ACCOUNT_ _PAGE_ correctly.
BTW, it's recommended to post your questions or problems on forum or mailing list instead of sending a mail to the developer directly. 

###Why Clonezilla does not use fsarchiver as the engine?

https://sourceforge.net/p/clonezilla/discussion/Open_discussion/thread/295770be

###After I restore the MS windows image, I got error messages about "0xc0000225, 0xc00000e", and something about Winload.exe, any hint?

https://sourceforge.net/p/clonezilla/discussion/Help/thread/5fe31e4a

###Any workaround that I can save and restore RAID 1 (mirrored) disk by Clonezilla?

https://sourceforge.net/p/clonezilla/discussion/Clonezilla_live/thread/1cb258d2

###Is there any method I can brodcast messages to DRBL clients?

Yes, you can make that with some scripts. Thanks to Tim Shelley (tim_j_shelley _at_ hotmail com) for sharing this:
"It's a script we use to open dialogs on client machines to all logged in users. I'm sure when you look at the script there maybe be better ways to do what I've done but I guess thats the fun of putting out into the public domain :). The drblmessage.sh relies on another script - msg.sh which I have also included. It's the one that runs on the client machine to launch zenity.
Of course the messaging script can be easily modified to send messages to specific clients rather than all of them.
I've only run this on Ubuntu 9.04, so I'm not sure if it will work on other Linux platforms. I'd also like to thank the DRBL community who helped me alot with this."
You can download script files here. 

http://drbl.org/faq/2_System/files/96_broadcast_messages_to_drbl_clients/

###How can I restore an image to multiple hard drives simultaneously?

http://clonezilla.org/show-live-doc-content.php?topic=clonezilla-live/doc/03_One_image_to_multiple_disks

###Do I have to have a destination drive already formatted before trying to restore an image on it?

No. Clonezilla will create the file system for you, i.e. everything on the destination disk will be overwritten, no matter it's an unformatted disk, or a formatted disk with data on that. //NOTE// Before using Clonezilla, remember to back up the important data on the destination disk if you have.

###Is there any method I can resize my LVM device?

https://sourceforge.net/p/clonezilla/discussion/Clonezilla_live/thread/2afd71b8

https://sourceforge.net/p/clonezilla/discussion/Help/thread/24772ef0

###Is that possible I can clone the MS Windows partition to different order of partition on another disk?

https://sourceforge.net/p/clonezilla/discussion/Clonezilla_live/thread/bef0d41e

###How can I restore an image of a partition to different partition, e.g. restore the image of /dev/sda5 to /dev/sda6?

Normally Clonezilla only allows you to restore the image to the same partition, i.e. if it's saved from /dev/sda5, you can only restore that to /dev/sda5. If you really want to restore it to different partition, e.g. /dev/sda6, you can:

    Create the partition /dev/sda6, and make sure the size is equal or larger than the /dev/sda5 which you save the source image.
    Make a copy of image dir, here we use the image "my-image" as an example, e.g.

        cp -a /home/partimag/my-image /home/partimage/my-image-new
        

    Now we have to change some files in /home/partimage/my-image-new,
        Rename all the files /home/partimag/my-image-new/sda5* as /home/partimag/my-image-new/sda6*, e.g.

                mv /home/partimag/my-image-new/sda5.ext4-ptcl-img.gz.aa /home/partimag/my-image-new/sda6.ext4-ptcl-img.gz.aa
                mv /home/partimag/my-image-new/sda5.ext4-ptcl-img.gz.ab /home/partimag/my-image-new/sda6.ext4-ptcl-img.gz.ab
                ...
                

            
        Modify the content of /home/partimage/my-image-new/parts, replace "sda5" with "sda6". 

    //Hint// In the above steps, if you want to save time and disk space, you can create the dir /home/partimage/my-image-new, copy the small files from /home/partimag/my-image, and use symbolic link (ln -fs) to link the sda5* files as sda6*.
    Now you can use the menu "restoreparts" to restore the image of partition "sda6" from my-image-new to /dev/sda6, i.e. to use the new created image "my-image-new" instead of original "my-image". 
    
### Is Clonezilla compatible with "WD Advanced Format" disk?

Clonezilla is not 100% compatible with "WD Advanced Format" (4096-byte) disk.
It works for the following cases:
"WD Advanced Format" disk to "WD Advanced Format" disk
"WD Advanced Format" disk to 512-byte disk disk But it won't work for 512-byte disk to "WD Advanced Format" disk.
If you want to clone 512-byte disk to "WD Advanced Format" disk, after using Clonezilla to clone it, you have to use the tool "wd align" from WD to tune that on the destination disk, or manually tune the partition table on GNU/Linux. 

###How can I can provide PXE service on a MS windows machine?

https://sourceforge.net/p/clonezilla/discussion/Help/thread/2091127e

###How can I use LDAP instead of NIS/YP in DRBL server?

https://sourceforge.net/p/drbl/discussion/DRBL_for_Debian/thread/907df845

###How can I skip the prompt "Please remove the disc, close the the tray (if any) and press ENTER to continue" when rebooting or shutdowning the Clonezilla live?

You can add "noeject" (was "noprompt" for Clonezilla live <= 2.1.*) in the boot parameters. For more info, please check this. 

###Is that possible to run Clonezilla-live using windows 2008 & wds?

drbl.org/faq/fine-print.php?path=./2_System/107_MS_WDS_with_Clonezilla_live.faq#107_MS_WDS_with_Clonezilla_live.faq

### I got an error message "extfsclone.c: bitmap free count err, free:...", any idea?

You should make sure the file system integrity is OK before you save it as an image, i.e. the file system is unmounted cleanly. If you want to check and repair the file system, you can run "fsck" on GNU/Linux or 'chkdsk /f', 'chkdsk /p /r' on MS Windows. For GNU/Linux file system, e.g. ext4, reiserfs, you can also enter expert mode of Clonezilla, then check option "-fsck-src-part" when you save an image. 

###I have some Broadcom gigabits NICs, and it is not supported by Clonezilla live, why? How to support it?

If you use Debian-based Clonezilla live, it does not support Broadcom gigabit NICs since they need non-free firmware.
On the other hand, Ubuntu-based Clonezilla live, e.g. 20110323-maverick or 20110510-natty, does include those non-free firmware. Therefore it can support your Broadcom NICs.

### After I did a disk-to-disk clone, my MS Windows in the source disk fails to boot. Why?

Clonezilla actually won't modify anything on the source disk. The reason after cloning your MS Windows fails to boot might be due to the destination disk is not removed from the same machine.
When you do a disk to disk clone, once you finish the cloning, you should remove the source disk or target disk. Then you can boot the MS windows. You should not keep them coexist on the same machine. This is nothing to do with Clonezilla. Clonezilla does clone the OS for you. The problem is on the restored OS. Especially for MS Windows, you give the OS 2 identical hard drives on the same machine. This will confuse your MS windows, and it is an OS which is sensitive to the hardware... Say, it might find the root file system on the destination hard drive, however, the hardware is apparently different, then MS Windows gives you BSOD. Therefore, to avoid this issue, remember to remove either source disk or destination one from the machine. 


### 
Possible solutions when connection drops or CRC-error message with Clonezilla.

    If you have network connection drops or CRC-error message, this workaround might work for you. i.e. Use ethtool to limit the speed and other tunings, e.g.

    ethtool -s eth0 speed 100 duplex half autoneg off
    edit "/etc/drbl/drbl-ocs.conf", change udp_sender_extra_opt_default="" as udp_sender_extra_opt_default="--max-bitrate 150m"
    uncheck -x option in restore disk under advance options 

For more info, please check here and here.
Thanks to Koen Wybo (koen.wybo _at_ telenet be) and fuddy2for sharing them.

###After restoring, grub2 complains "error: no argument specified". Why?

By default when an image is restored, Clonezilla will try to re-run grub-install from the restored GNU/Linux. If it fails, e.g. you are using i686 version of Clonezilla live, while the restored GNU/Linux is amd64 (x86-64) OS, it will fail. Then Clonezilla will use the grub2 comes with Clonezilla live to run grub-install. The version could be imcompatible. E.g. for older version of grub, the syntax is like:
search --no-floppy --fs-uuid --set 857d5af9-23cd-4d9b-908b-cc075e566738
On the other hand, the newer one is:
search --no-floppy --fs-uuid --set=root 857d5af9-23cd-4d9b-908b-cc075e566738
To solve this issue, you can:

    Boot the restored GNU/Linux
    Enter the command line
    Run the following command as root:
    grub-install /dev/sdx
    (Replace /dev/sdx with your harddrive, normally it's /dev/sda. You have to make sure the correct disk name otherwise you might write the boot loader on the wrong disk, and it might fail to boot.) 

Then you can reboot the restored GNU/Linux again, and this warning message should be gone.
//NOTE// You can not run "update-grub" or "update-grub2" to replace the command "grub-install", because update-grub or update-grub2 will only update the config file of grub (/boot/grub/grub.cfg or /boot/grub2/grub.cfg). It won't update the boot loader. 

### Is that possible I can restore a MS Windows image to different hardware?

Yes. However, you have to install "sysprep" in the MS Windows before you take an image for the whole disk. For sysprep, please check here. http://www.wikiwand.com/en/Sysprep

### I got a message "This disk contains mismatched GPT and MBR partition". What's that?

You might have installed an OS with GPT partition table, and later overwrite the disk by installing another OS with MBR partition table. The MBR partition table editor, e.g. fdisk, sfdisk, or cdisk does not know GPT, so it overwrite part of the GPT partition table, but did not clean the rest completely. Therefore that's why you got such a message.
If you are sure your running OS is using MBR partition table, not GPT one, you can run
sudo sgdisk -z /dev/sdx
(Replace /dev/sdx with your disk name, e.g. /dev/sda for the 1st hard drive) to clean the GPT partition table, while keep the MBR partition table. //NOTE// Use the above command carefully. It might destroy everything on the harddrive.

###When I restored an image to the same, original SSD disk, Clonezilla complained the destination disk is too small. What's wrong?

https://sourceforge.net/p/clonezilla/discussion/Clonezilla_live/thread/0e9ffb51

###I got an error message like "extfsclone.c: FS was not cleanly unmounted" or ".extfsclone.c: bitmap free count err, free:..." when saving an image? Any hints?

As the error message metnioned, it is because the file system was not cleanly umounted. Normally this is because the machine was not shutdowned correctly. To solve this, you could select "-fsck-src-part-y" when saving an image.. Of course, an alternation solution is, you can manually run "fsck" command on GNU/Linux to fix the file system integrity. 

http://clonezilla.org/clonezilla-live/doc/01_Save_disk_image/images/ocs-10-check-source-fs.png

###Is that possible I can restore to smaller HDD when the image was taken from bigger one?

If you are sure the used data blocks on the source disk are within the disk boundary of destination one, yes, it's possible to make that with the options "-k1" and "-icds" enabled in the expert mode. 

http://clonezilla.org/clonezilla-live/doc/02_Restore_disk_image/advanced/09-advanced-param.php