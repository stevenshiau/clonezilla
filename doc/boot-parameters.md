The boot parameters for Clonezilla live [Kernel boot
parameters](https://wiki.ubuntu.com/Kernel/KernelBootParameters) are
text strings which are interpreted by the system to change specific
behaviors and enable or disable certain features. Different boot loaders
use different config files for the boot parameters:

1.  For Clonezilla live booting from CD on a MBR machine,
    [isolinux](http://www.syslinux.org/) is the boot loader. Therefore
    the config file is /syslinux/isolinux.cfg.

2.  For Clonezilla live booting from USB flash drive on a MBR machine,
    [syslinux](http://www.syslinux.org/) is the boot loader. Therefore
    the config file is /syslinux/syslinux.cfg.

3.  For Clonezilla live booting from PXE on a MBR machine,
    [pxelinux](http://www.syslinux.org/) is the boot loader. The config
    file is on the PXE server, and is configured by the system
    administrator. it could be something like
    /tftpboot/nbi\_img/pxelinux.cfg/default, or different file.

4.  For Clonezilla live booting from a uEFI machine,
    [grub2](http://en.wikipedia.org/wiki/GNU_GRUB) is used. Therefore
    the config file is /EFI/boot/grub.cfg.

We now describe the kernel boot parameters related to Clonezilla live.
If you want to modify the boot parameters, make sure you edit the right
config file.

Clonezilla live is based on [Debian live](http://live.debian.net/) with
clonezilla installed. Therefore there are 2 kinds of boot parameters:

1.  Boot parameters from Debian live-boot and live-config. You can refer
    to the [manual of
    live-boot](/tmp/clonezilla-live/boot-parameters/live-boot.php) and
    [manual of
    live-config.](/tmp/clonezilla-live/boot-parameters/live-config.php).

2.  Boot parameters specially for Clonezilla. All of them are named as
    "ocs\_\*", e.g. ocs\_live\_run, ocs\_live\_extra\_param,
    ocs\_live\_batch.

    -   ocs\_live\_run is the main program to run in Clonezilla live to
        save or restore. or other command. Available program:
        ocs-live-general, ocs-live-restore or any command you write.\
        e.g. ocs\_live\_run="ocs-live-general"\
        //NOTE// You might have to use "sudo" command inside your own
        script, or you can assign it like: ocs\_live\_run="sudo bash
        /my-clonezilla"

    -   ocs\_live\_extra\_param will be used only when
        ocs\_live\_run=ocs-live-restore (not for ocs-live-general or any
        other), then it will be passed to ocs-sr. Therefore these
        parameters are actually those of ocs-sr.\
        e.g. ocs\_live\_extra\_param="--batch -c restoredisk sarge-r5
        hda"

    -   To preset the keyboard layout, use "keyboard-layouts" from
        [live-config](http://live.debian.net/manual/3.x/html/live-manual.en.html#customizing-locale-and-language).\
        e.g. keyboard-layouts=NONE (won't change the default layout,
        which is US keyboard)\
        keyboard-layouts=fr (French keyboard)\
        //NOTE// The ocs\_live\_keymap used in Clonezilla live 1.x is
        deprecated. The following description is only for reference.\
        ocs\_live\_keymap is for keymap used in Clonezilla live. Man
        install-keymap for more details.\
        e.g. ocs\_live\_keymap="NONE" (won't change the default layout)\
        ocs\_live\_keymap="/usr/share/keymaps/i386/azerty/fr-latin9.kmap.gz"
        (French keyboard)

    -   batch mode or not (yes/no), if no, will run interactively.\
        e.g. ocs\_live\_batch="no"

    -   To preset the language, use "locales" from
        [live-config](http://live.debian.net/manual/3.x/html/live-manual.en.html#customizing-locale-and-language).\
        e.g. locales=en\_US.UTF-8\
        //NOTE// The "ocs\_lang" used in Clonezilla live 1.x is
        deprecated.

    -   To preset the font name and font size for KMS mode, use
        "ocs\_fontface" and "ocs\_fontsize".\
        e.g. ocs\_fontface="TerminusBold"\
        ocs\_fontsize="24x12"\
        Check file /etc/default/console-setup and the console-setup(5)
        manual page on Debian or Ubuntu system.

    -   ocs\_debug (or ocs-debug) is for you to enter command line
        prompt before any clonezilla-related action is run. This is
        easier for you to debug.

    -   ocs\_daemonon, ocs\_daemonoff, ocs\_numlk, ocs\_capslk.\
        Ex. for the first 2 parameters, ocs\_daemonon="ssh", then ssh
        service will be turned on when booting. For the last 2
        parameters, use "on" or "off", e.g. ocs\_numlk=on to turn on
        numberlock when booting.

    -   ocs\_prerun, ocs\_prerun1, ocs\_prerun2... is for you to run a
        command before Clonezilla is started. E.g.
        ocs\_prerun="/live/image/myscript.sh". If you have more commands
        to run, you can assign them in the order: ocs\_prerun=...,
        ocs\_prerun1=..., ocs\_prerun2=.... If more than 10 parameters,
        remember to use ocs\_prerun01, ocs\_prerun02..., ocs\_prerun11
        to make it in order.

    -   ocs\_postrun, ocs\_postrun1, ocs\_postrun2... is for you to run
        a command after Clonezilla job is done, E.g.
        ocs\_postrun="/live/image/myscript.sh". If you have more
        commands to run, you can assign them in the order:
        ocs\_postrun=..., ocs\_postrun1=..., ocs\_postrun2=.... If more
        than 10 parameters, remember to use ocs\_postrun01,
        ocs\_postrun02..., ocs\_postrun11 to make it in order.

    -   echo\_ocs\_prerun and echo\_ocs\_postrun are used to echo the
        commands of prerun and postrun. By default the command assigned
        in ocs\_prerun or ocs\_postrun will be echoed. By using "no" the
        command won't be echoed. This is useful when you want to hide
        some commands.\
        e.g. echo\_ocs\_prerun="no" (Will not show the commands assigned
        in boot parameter "ocs\_prerun").

    -   ocs\_live\_run\_tty. This option allows you to specify the tty
        where \$ocs\_live\_run is run. By default \$ocs\_live\_run is
        run on /dev/tty1 only. If you want to use ttyS0, for example,
        add live-getty and console=ttyS0,38400n81 in the boot
        parameter.\
        //NOTE//

        -   If "live-getty console=ttyS0,38400n81" are assigned in the
            boot parameters, ocs\_live\_run\_tty will honor ttyS0, even
            other value is assigned to ocs\_live\_run\_tty in boot
            parameter.

        -   It's recommended to assign locales and keyboard-layouts in
            the boot parameters too.

    -   ip, this option allows you to specify the network parameters for
        network card. In Clonezilla live a patched live-initramfs is
        used, which is different from the original live-initramfs so
        that you can assign DNS server, too. Its format is: ip=ethernet
        port,IP address, netmask, gateway, DNS. E.g. If you want to
        assing eth0 with IP address 10.0.100.1, netmask 255.255.255.0,
        gateway 10.0.100.254, DNS server 8.8.8.8, you can assign the
        following in the boot parameter:\
        ip=eth0:10.0.100.1:255.255.255.0:10.0.100.254:8.8.8.8\
        If more than one network card, you can use "," to separate them,
        e.g.:\
        ip=eth0:10.0.100.1:255.255.255.0:10.0.100.254:8.8.8.8,eth1:192.168.120.1:255.255.255.0:192.168.120.254::

    -   Besides, two parameters could be used to assign the network card
        for PXE booting, "live-netdev" (yes, not ocs\_live\_netdev) and
        "nicif" can be used when using PXE booting,

        -   For "live-netdev", you can force to assign the network
            device by its ethernet device name on GNU/Linux, e.g. eth0,
            eth1, to get filesystem.squashfs. This is useful when there
            are two or more NICs are linked. E.g. live-netdev="eth1"
            allows you to force the live-initramfs to use eth1 to fetch
            the root file system filesystem.squashfs.

        -   For "nicif", you can force to assign the network device by
            its MAC address, e.g. 00:aa:bb:cc:dd:ee, to get
            filesystem.squashfs. This is useful when there are two or
            more NICs are linked. E.g. nicif="00:aa:bb:cc:dd:ee", allows
            you to force the live-initramfs to use the ethernet card
            with MAC address "00:aa:bb:cc:dd:ee" to fetch the root file
            system filesystem.squashfs.

You can find some examples about using these boot parameters in the
[Clonezilla Live Doc](/tmp/clonezilla-live-doc.php).

* * * * *
