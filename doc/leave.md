##About Clonezilla Live

Clonezilla Live is a small bootable GNU/Linux distribution for x86/amd64 (x86-64) based computers. Clonezilla SE (Server Edition) has been developed from 2004, and it is used to deploy many computers simultaneously. It is an extremely useful tool, however, it does have several limitations. In order to use it, you must first prepare a DRBL server AND the machine to be deployed must boot from a network (e.g. PXE/iPXE). To address these limitations, we have combined [Debian Live][debian-live] with Clonezilla as "Clonezilla Live," a software that can be used to easily image and clone individual machines. The primary benefit of Clonezilla Live is that it eliminates the need to set up a DRBL server ahead of time and the need for the computer being deployed to boot from a network. Clonezilla Live can be used to image or clone individual computers using a CD/DVD or USB flash drive. Though the image size is limited by the boot media's storage capacity, this problem can be eliminated by using a network filesystem such as sshfs or samba.

##How to install Clonezilla Live?

To install Clonezilla live, the basic steps are to download pre-build Clonezilla Live then put it in a boot media (CD, USB flash drive or USB hard drive). Two types of files are available, iso and zip. The former one is for CD, the latter is for USB flash drive. Besides, you can put Clonezilla live on hard drive or PXE server, too.

1 For CD/DVD:

[Download an ISO file for CD/DVD][download]. Then you can burn the iso file to a CD/DVD with any burnning program, such [K3b][k3b] on GNU/Linux or [InfraRecorder][infrarecorder] on MS Windows, and remeber to [choose "Burn Image" to burn the ISO file on the CD][choose]. The CD can then be used to boot the machine you want to image or clone.

2 For USB flash drive, USB hard drive or hard drive:

To put Clonezilla live on a USB flash drive or USB hard drive, check this [doc][clz-harddrive].

3 For PXE server:

To put Clonezilla live on a PXE server and boot your client via PXE, check this [doc][live-pxe].

4 If you are interested in creating the Clonezilla live iso or zip file from scratch, check this [doc][live-from-scratch].

## How to use Clonezilla live?

Please refer to this [doc][usage] for more details. 

## Accounts

In Clonezilla live, two accounts are available: (1) account "user" with sudo privilege, password is "live", (2) administration account "root", no password. Therefore you can not login as root, the only way to get root privilege is to login as user, and run "sudo -i" or "sudo su -" to become root.
For better security, it is recommended to change the passwords of user and root by command "passwd" before you allow remote access. When Clonezilla live boots, the ssh service is NOT automatically started, and the setting in /etc/hosts.deny does NOT block any connection. If you want to remotely ssh login into your Clonezilla live, you have to start ssh service by "service ssh start".

[debian-live]:http://live.debian.net/
[download]:http://clonezilla.org/downloads.php
[k3b]:http://k3b.plainblack.com/
[infrarecorder]:http://infrarecorder.org/
[choose]:https://help.ubuntu.com/community/BurningIsoHowto
[clz-harddrive]:http://clonezilla.org/livehd.php
[live-pxe]:http://clonezilla.org/livepxe.php
[live-from-scratch]:http://clonezilla.org/create_clonezilla_live_from_scratch.php
[usage]:http://clonezilla.org/clonezilla-usage/clonezilla-live-usage.php
