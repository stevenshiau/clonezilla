### What is Clonezilla?

Clonezilla is a partition and disk imaging/cloning program similar to [True Image®][true-image] or [Norton Ghost®][norton-ghost]. It helps you to do system deployment, bare metal backup and recovery. Two types of Clonezilla are available, [Clonezilla live][clonezilla-live] and [Clonezilla SE (server edition)][clonezilla-server]. Clonezilla live is suitable for single machine backup and restore. While Clonezilla SE is for massive deployment, it can clone many (40 plus!) computers simultaneously. Clonezilla saves and restores only used blocks in the harddisk. This increases the clone efficiency. With some high-end hardware in a 42-node cluster, a multicast restoring at rate 8 GB/min was reported.

### Features:

- Free (GPL) Software.
- Filesystem supported: ext2, ext3, ext4, reiserfs, reiser4, xfs, jfs, btrfs of GNU/Linux, FAT12, FAT16, FAT32, NTFS of MS Windows, HFS+ of Mac OS, UFS of FreeBSD, NetBSD, and OpenBSD, minix of Minix, and VMFS3 and VMFS5 of VMWare ESX. Therefore you can clone GNU/Linux, MS windows, Intel-based Mac OS, FreeBSD, NetBSD, OpenBSD, Minix and VMWare ESX, no matter it's 32-bit (x86) or 64-bit (x86-64) OS. For these file systems, only used blocks in partition are saved and restored. For unsupported file system, sector-to-sector copy is done by dd in Clonezilla.
- LVM2 (LVM version 1 is not) under GNU/Linux is supported.
- Boot loader, including grub (version 1 and version 2) and syslinux, could be reinstalled.
- Both [MBR][mbr] and [GPT][gpt] partition format of hard drive are supported. Clonezilla live also can be booted on a [BIOS][bios] or [uEFI][uefi] machine.
- Unattended mode is supported. Almost all steps can be done via commands and options. You can also use a lot of [boot parameters][boot-parameters] to customize your own imaging and cloning.
- One image restoring to multiple local devices is supported.
- Multicast is supported in Clonezilla SE, which is suitable for massively clone. You can also remotely use it to save or restore a bunch of computers if PXE and Wake-on-LAN are supported in your clients.
- The image file can be on local disk, ssh server, samba server, or NFS server.
- Based on [Partclone][partclone] (default), [Partimage][partimage] (optional), [ntfsclone][ntfsclone] (optional), or dd to image or clone a partition. However, Clonezilla, containing some other programs, can save and restore not only partitions, but also a whole disk.
- By using another free software [drbl-winroll][drbl-winroll], which is also developed by us, the hostname, group, and SID of cloned MS windows machine can be automatically changed. 

### Minimum System Requirements for Clonezilla live:

- X86 or x86-64 processor
- 196 MB of system memory (RAM)
- Boot device, e.g. CD/DVD Drive, USB port, PXE, or hard drive 

### Limitations:


- The destination partition must be equal or larger than the source one.
- Differential/incremental backup is not implemented yet.
- Online imaging/cloning is not implemented yet. The partition to be imaged or cloned has to be unmounted.
- Software RAID/fake RAID/firmware RAID is not supported by default. It can be done manually only.
- Due to the image format limitation, the image can not be explored or mounted. You can _NOT_ recovery single file from the image. However, you still have workaround to make it, read [this][read-the-content-of-an-image].
- Recovery Clonezilla live with multiple CDs or DVDs is not implemented yet. Now all the files have to be in one CD or DVD if you choose to create the recovery iso file. 

### License:

- Clonezilla itself is licensed under the GNU General Public License (GPL) Version 2. However, to run Clonezilla, a lot of free and open source software, e.g. the Linux kernel, a mininal GNU/Linux OS, are required. 

### Which Clonezilla Shall I Use ?

- [Clonezilla Live][clonezilla-live]: Clonezilla live allows you to use CD/DVD or USB flash drive to boot and run clonezilla (Unicast only)
- [Clonezilla SE][clonezilla-server]: Clonezilla SE is included in DRBL, therefore a DRBL server must first be set up in order to use Clonezilla to do massively clone (unicast, broadcast and multicast are supported) 


[true-image]:http://www.wikiwand.com/en/Acronis_True_Image
[norton-ghost]:http://www.wikiwand.com/en/Ghost_%28software%29
[clonezilla-live]:http://clonezilla.org/clonezilla-live.php
[clonezilla-server]:http://clonezilla.org/clonezilla-SE/

[mbr]:http://www.wikiwand.com/en/Master_boot_record
[gpt]:http://www.wikiwand.com/en/GUID_Partition_Table
[bios]:http://www.wikiwand.com/en/BIOS
[uefi]:http://www.wikiwand.com/en/Unified_Extensible_Firmware_Interface
[boot-parameters]:http://clonezilla.org/fine-print-live-doc.php?path=clonezilla-live/doc/99_Misc/00_live-boot-parameters.doc
[partclone]:http://partclone.org
[partimage]:http://www.partimage.org
[ntfsclone]:http://www.linux-ntfs.org/
[drbl-winroll]:http://drbl-winroll.sourceforge.net/
[read-the-content-of-an-image]:http://drbl.org/faq/fine-print.php?path=./2_System/43_read_ntfsimg_content.faq#43_read_ntfsimg_content.faq
