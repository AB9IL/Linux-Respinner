#!/bin/bash
Encoding=UTF-8

# Multifunction Linux Distro Respinner Script v0.50.
# Copyright (c) 2022 by Philip Collier, github.com/AB9IL
# Multifunction Linux Distro Respinner setup is free software; you can
# redistribute it and/or modify it under the terms of the GNU General Public
# License as published by the Free Software Foundation; either version 3 of
# the License, or (at your option) any later version. There is NO warranty;
# not even for MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
# Run this script as root to extract the iso contents,
# set up the chroot environment, or build a respun iso file.
# Boot into the iso you will respin.  Create the working directory
# (sysdir) and copy the original iso into it.  Set the variables
# before running this script.  Change SYSUSER and PART to match the
# current username and partition to match your currently running
# system, or the paths will be incorrect.
#>>>  THIS VERSION FOR        <<<
#>>>  UBUNTU 20.10 AND LATER  <<<
# define variables:
export BUILDDATE="$(date -u "+%Y%m%e")"
export SYSUSER=$(whoami) # your username as builder of the respin
export CHROOTDNS='9.9.9.9' # DNS to use during chroot operation
export SYSDIR='respunlinux' # the working directory of the respin project
export ISONAME='respunlinux-backup.iso' # the filename for the iso to be extracted
export ISOCONTENTS='extract-cd' # directory containing the extracted iso contents
export MBR_FILE='mbr.img' # mbr from original iso
export EFI_FILE='efi.img' # efi from original iso
export VERSION='0.1.0' # version number of the respun distro
export ISOINFO='Respun Linux 0.1.0 - Release amd64 ($BUILDDATE)' # data for the .disk/info file in the respun iso
export UBURELEASE='22.04' # Release Year.Month for Ubuntu distros
export UBUCODE='jammy' # Ubuntu codename
export MINTRELEASE=''
export MINTCODE='' # Mint codename
export DISTRIBID='Ubuntu' # LinuxMint or Ubuntu
export DISTRIBRELEASE=$UBURELEASE # variable for Mint or Ubuntu release
export DISTRIBCODE=$UBUCODE # variable for Mint or Ubuntu codename
export NEWISO="$SYSDIR-latest" # filename for the new iso
export DISTRONAME='Respun Linux' # plain language name for the respun distro
export DISTROURL='https://respunlinux.com' # url for the respin's web page
export FLAVOUR='respun' # /etc/casper.conf flavour
export HOST='respun' # /etc/casper.conf host in the respun distro
export USERNAME='user' # /etc/casper.conf user in the respun distro
export ARCH='amd64'
export RFSCONTENTS='edit' # directory containing the distro root filesystem

#---DO NOT EDIT BELOW THIS LINE------------------------------------------------

extract() {
    #apt update
    #apt install -y squashfs-tools genisoimage syslinux-utils xorriso
    # Extract the hybrid MBR template
    dd if="$ISONAME" bs=1 count=432 of="utils/mbr.img"
    # Extract EFI partition image
    skip=$(/sbin/fdisk -l "$ISONAME" | grep -F '.iso2 ' | awk '{print $2}')
    size=$(/sbin/fdisk -l "$ISONAME" | grep -F '.iso2 ' | awk '{print $4}')
    dd if="$ISONAME" bs=512 skip="$skip" count="$size" of="utils/efi.img"
    #
    mkdir mnt
    mkdir utils
    (cat /sbin/initctl > utils/initctl) &
    (cat $HOME/.bashrc > utils/.bashrc) &
    (cat $HOME/.bash_misc > utils/.bash_misc) &
    (cat $HOME/.bash_aliases > utils/.bash_aliases) &
    (cat $HOME/.config/dconf/user > utils/user) &
    (cat $HOME/.inputrc > utils/.inputrc) &
    (cat $HOME/.nanorc > utils/.nanorc) &
    (cat $HOME/.profile > utils/.profile) &
    (cat $HOME/.tmux.conf > utils/.tmux.conf) &
    (cat $HOME/.wgetrc > utils/.wgetrc) &
    (cat $HOME/.xinitrc > utils/.xinitrc) &
    (cat $HOME/.Xresources > utils/.Xresources) &
    wait
    ([[ -d "$HOME/.mozilla/" ]] && rsync -avhc --inplace --no-whole-file --delete \
        $HOME/.mozilla/ utils/.mozilla/) &
    ([[ -d "$HOME/.local/" ]] && rsync -avhc --inplace --no-whole-file --delete \
        $HOME/.local/ utils/.local/) &
    ([[ -d "$HOME/.tmux/" ]] && rsync -avhc --inplace --no-whole-file --delete \
        $HOME/.tmux/ utils/.tmux/) &
    mkdir $ISOCONTENTS
    mount -o loop $ISONAME mnt
    rsync -avhc --inplace --no-whole-file \
        mnt/ ${ISOCONTENTS}/
    find ${ISOCONTENTS}/casper -type f -iname "*.squashfs" \
        -exec unsquashfs -p 4 -f -d edit {} \;
    umount mnt
    rm -rf mnt
    printf '#!/bin/bash
    Encoding=UTF-8

enter(){
    printf "\nMounting directories...\n"
    export TERM="linux"
    export HOME="/root"
    export LC_ALL=C.UTF-8
    export LANG=C.UTF-8
    dbus-uuidgen > /var/lib/dbus/machine-id
    dpkg-divert --local --rename --add /sbin/initctl
    ln -s /bin/true /sbin/initctl
    printf "\nMoving to system root directory...\n"
    cd
    /bin/bash
    leave
}

leave(){
    printf "\nCleaning up before chroot exit...\n"
    rm /var/lib/dbus/machine-id
    rm /sbin/initctl
    dpkg-divert --rename --remove /sbin/initctl
    rm -rf /var/cache/apt/.[^.]*
    rm -rf /var/lib/apt/lists/.[^.]*
    rm -rf /var/cache/fontconfig/.[^.]*
    rm -rf /etc/apt/sources.list.d/*.save
    rm -rf /root/.[^.]*
    rm -rf /tmp/.[^.]*
    rm -rf /var/tmp/.[^.]*
    rm -f /etc/hosts
    rm /etc/machine-id
    apt autoremove --purge
    apt clean
    pyclean /usr/lib
    pyclean /usr/local/lib
    vers=(8 9 10 11)
    for ver in "${vers[@]}";do
        python3."$ver" -m pip cache purge
    done
    printf "\nExiting chroot...\n"
    exit
}

case $1 in
    enter)
        enter
        ;;
    leave)
        leave
        ;;
    **)
        printf "Manage entry and exit of the chroot environment.\n\n

Usage: %s (enter|leave)" "$0"
        ;;
esac
' > $RFSCONTENTS/usr/sbin/chroot-manager
chmod +x $RFSCONTENTS/usr/sbin/chroot-manager
printf '#!/bin/bash

kernel="$1"

create(){
    # Create vmlinuz and initrd files for bootable hybrid livecds.
    echo "Creating files for kernel "$kernel"...
    This will take a few minutes."
    depmod -a -v -w $kernel
    update-initramfs -c -k $kernel ; sync
    #gzip -dc /boot/initrd.img-$kernel | lzma -7 > ~/initrd.lz
    cp /boot/initrd.img-$kernel ~/initrd
    cp /boot/vmlinuz-$kernel ~/vmlinuz
    rm -f /vmlinuz
    rm -f /initrd.img
    ln -s /boot/vmlinuz-$kernel /vmlinuz
    ln -s /boot/initrd.img-$kernel /initrd.img
    update-grub
    printf "Task finished; look in $HOME for the files."
}

case "$1" in
    -h*|-H*)
        [[ "$2" -ne "0" || -z "$2" ]] && \
            printf "usage: build-bootfiles <kernel>";
            exit
        ;;
    *)
        create
        ;;
esac
' > $RFSCONTENTS/usr/sbin/build-bootfiles
chmod +x $RFSCONTENTS/usr/sbin/build-bootfiles
}

enterchroot() {
    #get prerequisites
    printf '\nGetting prerequisites...'
    apt install -y squashfs-tools genisoimage syslinux-utils xorriso
    printf '\nBinding directories...'
    (mount -o bind /run $RFSCONTENTS/run) &
    (mount --bind /dev $RFSCONTENTS/dev) &
    (mount --bind /proc $RFSCONTENTS/proc) &
    (mount --bind /sys $RFSCONTENTS/sys) &
    (cp /etc/hosts $RFSCONTENTS/etc/hosts) &
    (mkdir $RFSCONTENTS/run/systemd/resolve) &
    (echo 'nameserver '${CHROOTDNS}'' > $RFSCONTENTS/run/systemd/resolve/resolv.conf) &
    (echo 'nameserver '${CHROOTDNS}'' > $RFSCONTENTS/run/systemd/resolve/stub-resolv.conf) &
    printf '\nChrooting...'
    chroot edit chroot-manager enter
    (umount $RFSCONTENTS/run) &
    (umount $RFSCONTENTS/dev) &
    (umount $RFSCONTENTS/proc) &
    (umount $RFSCONTENTS/sys) &
    (rm -f $RFSCONTENTS/etc/hosts) &
    (rm -rf $RFSCONTENTS/root/.[^.]*) &
    (rm -rf $RFSCONTENTS/run/systemd/resolve/.[^.]*) &
    (rm -rf $RFSCONTENTS/tmp/.[^.]*) &
    (rm -rf $RFSCONTENTS/var/cache/apt/.[^.]*) &
    (rm -rf $RFSCONTENTS/var/cache/fontconfig/.[^.]*) &
    (rm -rf $RFSCONTENTS/var/cache/man/.[^.]*) &
    (rm -rf $RFSCONTENTS/var/lib/apt/lists/.[^.]*) &
    (rm -rf $RFSCONTENTS/etc/apt/*.save) &
    (rm -rf $RFSCONTENTS/etc/apt/sources.list.d/*.save) &
}

makedisk() {
    printf '\nCreate %s.iso!' $NEWISO
    printf '\nJumping above root directory, moving files...\n'
    cleanup
    mkdir -p $RFSCONTENTS/root/.config/dconf
    mkdir -p $RFSCONTENTS/var/cache/apt/{archives,partial}
    touch $RFSCONTENTS/var/cache/apt/archives/lock
    tee $RFSCONTENTS/etc/skel/.bashrc $RFSCONTENTS/root/.bashrc < utils/.bashrc > /dev/null
    tee $RFSCONTENTS/etc/skel/.bash_misc $RFSCONTENTS/root/.bash_misc < utils/.bash_misc > /dev/null
    tee $RFSCONTENTS/etc/skel/.bash_aliases $RFSCONTENTS/root/.bash_aliases < utils/.bash_aliases > /dev/null
    tee $RFSCONTENTS/etc/skel/.config/dconf/user $RFSCONTENTS/root/.config/dconf/user < utils/user > /dev/null
    tee $RFSCONTENTS/etc/skel/.profile $RFSCONTENTS/root/.profile < utils/.profile > /dev/null
    tee $RFSCONTENTS/etc/skel/.xinitrc $RFSCONTENTS/root/.xinitrc < utils/.xinitrc > /dev/null
    tee $RFSCONTENTS/etc/skel/.Xresources $RFSCONTENTS/root/.Xresources < utils/.Xresources > /dev/null
    tee $RFSCONTENTS/etc/skel/.nanorc $RFSCONTENTS/root/.nanorc < utils/.nanorc > /dev/null
    tee $RFSCONTENTS/etc/skel/.wgetrc $RFSCONTENTS/root/.wgetrc < utils/.wgetrc > /dev/null
    cp -f utils/.inputrc $RFSCONTENTS/etc/skel/.inputrc
    cp -f utils/.inputrc-root $RFSCONTENTS/root/.inputrc
    cp -f $RFSCONTENTS/etc/skel/.fzf.bash $RFSCONTENTS/root/.fzf.bash
    cp -f $RFSCONTENTS/etc/skel/.tmux.conf $RFSCONTENTS/root/.tmux.conf
    (rsync -avhc --inplace --no-whole-file --delete \
        $RFSCONTENTS/etc/skel/.config/rofi/ $RFSCONTENTS/root/.config/rofi/) &
    (rsync -avhc --inplace --no-whole-file --delete \
        $RFSCONTENTS/etc/skel/.config/gtk-3.0/ $RFSCONTENTS/root/.config/gtk-3.0/) &
    (rsync -avhc --inplace --no-whole-file --delete \
        $RFSCONTENTS/etc/skel/.config/gtk-4.0/ $RFSCONTENTS/root/.config/gtk-4.0/) &
    (rsync -avhc --inplace --no-whole-file --delete \
        $RFSCONTENTS/etc/skel/.config/qt5ct/ $RFSCONTENTS/root/.config/qt5ct/) &
    (rsync -avhc --inplace --no-whole-file --delete utils/.mozilla/ $RFSCONTENTS/etc/skel/.mozilla/) &
    (rsync -avhc --inplace --no-whole-file --delete utils/.local/ $RFSCONTENTS/root/.local/) &
    (rsync -avhc --inplace --no-whole-file --delete utils/.local/ $RFSCONTENTS/etc/skel/.local/) &
    (rsync -avhc --inplace --no-whole-file --delete $RFSCONTENTS/etc/skel/.tmux/ $RFSCONTENTS/root/.tmux/) &
    wait

#set distro identity
printf '\nSetting distro identity...'
(echo -e '# This file should go in /etc/casper.conf
# Supported variables are:
# USERNAME, USERFULLNAME, HOST, BUILD_SYSTEM, FLAVOUR

export USERNAME="'${USERNAME}'"
export USERFULLNAME="Live session user"
export HOST="'${HOST}'"
export BUILD_SYSTEM="Ubuntu"

# USERNAME and HOSTNAME as specified above will not be honoured and will be set to
# flavour string acquired at boot time, unless you set FLAVOUR to any
# non-empty string.

export FLAVOUR="'${FLAVOUR}'"' > $RFSCONTENTS/etc/casper.conf) &

(echo -e ${DISTRONAME}' '${VERSION}' \\n \l' > $RFSCONTENTS/etc/issue) &

(echo -e ${DISTRONAME}' '${VERSION}'' > $RFSCONTENTS/etc/issue.net) &

(echo -e 'DISTRIB_ID='${DISTRIBID}'
DISTRIB_RELEASE='${DISTRIBRELEASE}'
DISTRIB_CODENAME='${DISTRIBCODE}'
DISTRIB_DESCRIPTION="'${DISTRONAME}' '${VERSION}'"' > $RFSCONTENTS/etc/lsb-release) &

(echo -e '
The programs included with the '${DISTRONAME}' system are free software;
the exact distribution terms for each program are described in the
individual files in /usr/share/doc/*/copyright.

'${DISTRONAME}' comes with ABSOLUTELY NO WARRANTY, to the extent permitted by
applicable law.
' > $RFSCONTENTS/etc/legal) &

# VERSION_CODENAME must be either MINTCODE or UBUCODE
(echo -e 'NAME="'${DISTRONAME}'"
VERSION="'${VERSION}'"
ID=ubuntu
ID_LIKE=debian
PRETTY_NAME="'${DISTRONAME}'"
VERSION_ID="'${VERSION}'"
HOME_URL="'${DISTROURL}'"
SUPPORT_URL="'${DISTROURL}'"
BUG_REPORT_URL="'${DISTROURL}'"
PRIVACY_POLICY_URL="'${DISTROURL}'"
VERSION_CODENAME="'${UBUCODE}'"
UBUNTU_CODENAME="'${UBUCODE}'"' > $RFSCONTENTS/usr/lib/os-release) &

(echo -e '#!/bin/sh
#
#    10-help-text - print the help text associated with the distro
#    Copyright (C) 2009-2010 Canonical Ltd.
#
#    Authors: Dustin Kirkland <kirkland@canonical.com>,
#             Brian Murray <brian@canonical.com>
#
#    This program is free software; you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation; either version 2 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License along
#    with this program; if not, write to the Free Software Foundation, Inc.,
#    51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.

echo "* Support:  '${DISTROURL}'"' > $RFSCONTENTS/etc/update-motd.d/10-help-text;
chmod +x $RFSCONTENTS/etc/update-motd.d/10-help-text) &

(echo -e ${ISOINFO} > $ISOCONTENTS/.disk/info) &

(echo -e ${DISTROURL} > $ISOCONTENTS/.disk/release_notes_url) &

#regenerate manifest
printf '\nRegenerating manifest...'
chmod +w $ISOCONTENTS/casper/filesystem.manifest;
chroot edit dpkg-query -W --showformat='${Package} ${Version}\n' | \
    tee $ISOCONTENTS/casper/filesystem.manifest $NEWISO-build.log

#compress filesystem
printf '\nCompressing filesystem for %s.iso...\n' $NEWISO
rm $ISOCONTENTS/casper/filesystem.squashfs
mksquashfs edit $ISOCONTENTS/casper/filesystem.squashfs \
    -comp xz \
    -b 1048576 \
    -processors 8
echo -e $(du -sx --block-size=1 edit | cut -f1) | \
    tee $ISOCONTENTS/casper/filesystem.size

#update md5sums
#filename MD5SUMS for linux Mint, md5sum.txt for Ubuntu derivatives
cd $ISOCONTENTS
# printf '\nUpdating md5 sums...'
# rm md5sum.txt
# grep -v isolinux/boot.cat <(find -type f | xargs -n1 -P0 -I {} md5sum) | \
#    tee md5sum.txt ../$NEWISO-build.log 2>&1
cd ../

#remove the old iso file
printf '\nIf exists, delete the old %s.iso...\n' $NEWISO
[[ -f "$NEWISO.iso" ]] && rm -f $NEWISO.iso

#create iso image
printf '\nCreating %s.iso...\n' $NEWISO
# do not change the order of the xorriso options
# do not remove repeated xorriso options
xorrisofs -v \
    -r -joliet-long -l \
    -volset "$FLAVOUR$VERSION-$ARCH" \
    -volid "$FLAVOUR$VERSION-$ARCH" \
    -o $NEWISO.iso \
    -iso-level 3 \
    -partition_offset 16 \
    --grub2-mbr utils/"$MBR_FILE" \
    --mbr-force-bootable \
    -append_partition 2 28732ac11ff8d211ba4b00a0c93ec93b utils/"$EFI_FILE" \
    -appended_part_as_gpt \
    -iso_mbr_part_type a2a0d0ebe5b9334487c068b6b72699c7 \
    -c '/boot.catalog' \
    -b '/boot/grub/i386-pc/eltorito.img' \
    -no-emul-boot \
    -boot-load-size 4 \
    -boot-info-table \
    --grub2-boot-info \
    -eltorito-alt-boot \
    -e '--interval:appended_partition_2:::' \
    -no-emul-boot \
    $ISOCONTENTS 2>&1

    # log iso information
    echo -e '\nComputing the SHA256 sum:' | tee $NEWISO-build.log 2>&1
    sha256sum $NEWISO.iso | tee -a $NEWISO-build.log 2>&1
    echo -e '\nBoot record information:'
    fdisk -lu $NEWISO.iso | tee -a $NEWISO-build.log 2>&1
    echo -e 'Boot catalog and image paths:'
    xorriso -indev $NEWISO.iso -toc -pvd_info | tee -a $NEWISO-build.log 2>&1
    echo -e '\n'${NEWISO}' creation finished'
}

extractinitrd() {
    cd initrd-rebuild

#For initrd.gz from an apt-get upgrade in chroot
#gzip -dc ../initrd.gz | cpio -id

#For initrd.gz in the iso file
#gzip -dc ../$ISOCONTENTS/casper/initrd.gz | cpio -id

#For initrd.lz in the iso file
lzma -dc -S .lz ../$ISOCONTENTS/casper/initrd.lz | cpio -id
cd ../
}

repackinitrd() {
    cd initrd-rebuild
    find . | cpio --quiet --dereference -o -H newc | lzma -7 > ../$ISOCONTENTS/casper/initrd-new.lz
    cd ../
}

cleanup() {
    printf '\nCleaning up...\n'
    umount $RFSCONTENTS/dev
    (chown -R man:root $RFSCONTENTS/var/cache/man) &
    (cd "$RFSCONTENTS/usr/local"; fd -H -e txt -e conf -e db -e md -e html -x chmod 666) &
    (cd "$RFSCONTENTS/usr/local/sbin"; fd -H  -e py -e sh -x chmod 755) &
    (cd "$RFSCONTENTS/usr/local/etc"; fd -H -tf -x chmod 666) &
    (cd "$RFSCONTENTS/var/cache"; fd -H -e db -e TAG -x chmod 664) &
    (cd "$RFSCONTENTS/var/log"; fd -H -td -x chmod 755) &
    (cd "$ISOCONTENTS/isolinux"; fd -H -tf -x chmod 644) &
    (cd "$RFSCONTENTS/etc/apt/sources.list.d"; fd -H -e save -x rm) &
    (cd "$RFSCONTENTS/var/crash"; fd -H -tf -x rm) &
    (cd "$RFSCONTENTS/var/lib/apt"; fd -H -tf -x rm) &
    (cd "$RFSCONTENTS/var/log"; fd -H -tf -x rm) &
    (cd "$RFSCONTENTS/var/tmp"; fd -H -tf -x rm) &
    (python3 -m pyclean /usr) &
    (python3 -m pyclean /opt) &
    (python3 -m pyclean utils) &
    (cd "$ISOCONTENTS"; fd -H TRANS.TBL -x rm) &
    (cd "$RFSCONTENTS"; fd -H -e dpkg-old -e dpkg-dist -x rm) &
    (cd "$RFSCONTENTS/tmp"; fd -H -tf -x rm) &
    (cd "$RFSCONTENTS/home/"; fd -H . -x rm -rf) &
    (cd "$RFSCONTENTS/root/"; fd -H . -x rm -rf) &
    (cd "$RFSCONTENTS/tmp/"; fd -H . -x rm -rf) &
    (rm -rf utils/.mozilla/firefox/bookmarkbackups/.[^.]*) &
    (rm -rf utils/.mozilla/firefox/*.default/storage/{permanent,temporary}) &
    printf '\nSetting some permissions...\n'
    (chmod 4755 $RFSCONTENTS/usr/bin/pkexec) &
    (chmod 4755 $RFSCONTENTS/usr/bin/sudo) &
    (chown root:messagebus $RFSCONTENTS/usr/lib/dbus-1.0/dbus-daemon-launch-helper) &
    (chmod u+s $RFSCONTENTS/usr/lib/dbus-1.0/dbus-daemon-launch-helper) &
    printf 'Waiting to finish cleanup and permissions...\n'
    wait
}

syncHTML() {
    # rsync the html folder (READMEs and info for the distro users)
    rsync -avhc --inplace --no-whole-file --delete /usr/local/share/html/ utils/html/
    chown -R root:root utils/html
    rsync -avhc --inplace --no-whole-file --delete utils/html/ backup/usr/local/share/html/
}

makebackup(){
    echo -e '\nCopying '${NEWISO}'.iso to '${NEWISO}'.bak.iso...\n'
    cp -fp $NEWISO.iso $NEWISO.bak.iso
    echo -e '\nBackup job complete...'
}

copydconf(){
    yes | cp -f /home/$SYSUSER/.config/dconf/user utils/user
}


case "$1" in
    chroot)
        enterchroot
        ;;
    makedisk)
        makedisk
        ;;
    backup)
        makebackup
        ;;
    extractiso)
        extract
        ;;
    extractinit)
        extractinitrd
        ;;
    repackinit)
        repackinitrd
        ;;
    synchtml)
        syncHTML
        ;;
    syncdconf)
        copydconf
        ;;
    cleanup)
        cleanup
        ;;
    *)
        echo "$0 <command>

    chroot      Enter a chroot environment
    makedisk    Create a new iso file based on edited filesystem
    backup      Create a backup of the iso file
    extractiso  Extract filesystem from iso file
    extractinit Extract contents of initrd file
    repackinit  Rebuild initrd from extracted contents
    synchtml    sync the iso /usr/local/share/html to live system
    syncdconf   sync the iso dconf to live system
    cleanup     clean cruft and set permissions in the iso filesystem

        " >&2
        exit 3
        ;;
esac
