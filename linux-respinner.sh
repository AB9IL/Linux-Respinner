#!/bin/sh
Encoding=UTF-8

# Multifunction Linux Distro Respinner Script v0.10.
# Copyright (c) 2018 by Philip Collier, <webmaster@ab9il.net>
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
#
# define variables:

# SYSUSER: your username as builder of the respin
SYSUSER=winston

# CHROOTDNS: DNS to use during chroot operation
CHROOTDNS='9.9.9.9'

# PART: the partition where the respin project is located
PART=data1

# SYSDIR: the working directory of the respin project
SYSDIR=churchill

# ISONAME: the filename for the iso to be extracted
ISONAME=respunlinux-orig

# ISOINFO: data for the .disk/info file in the respun iso
ISOINFO='RespunLinux - Release amd64 (20190215)'

# UBURELEASE=Release Year.Month for Ubuntu distros
UBURELEASE=18.04

# UBUCODE=Ubuntu codename
UBUCODE=bionic

# MINTCODE=Mint codename
MINTCODE=

# NEWISO: filename for the new iso
NEWISO=respunlinux-latest

# DISTRONAME: plain language name for the respun distro
DISTRONAME="Respun Linux"

# DISTROURL: url for the respin's web page
DISTROURL="https://respunlinux.com"

# FLAVOUR: /etc/casper.conf flavour
FLAVOUR=Respun

# HOST: /etc/casper.conf host in the respun distro
HOST=respun

# USERNAME: /etc/casper.conf user in the respun distro
USERNAME=user

# VERSION: version number of the respun distro
VERSION=0.8

#--------------------DO NOT EDIT BELOW THIS LINE--------------------

extract() {
#apt update
#apt install -y squashfs-tools genisoimage syslinux-utils
cd /media/$SYSUSER/$PART/$SYSDIR
mkdir mnt
mkdir utils
mkdir extract-cd
mount -o loop /media/$SYSUSER/$PART/$SYSDIR/$ISONAME.iso mnt
rsync --exclude=/casper/filesystem.squashfs -a mnt/ extract-cd
unsquashfs mnt/casper/filesystem.squashfs
mv squashfs-root edit
#cp /sbin/initctl /media/$SYSUSER/$PART/$SYSDIR/utils/initctl
umount mnt
rm -rf /media/$SYSUSER/$PART/$SYSDIR/mnt
echo '#!/bin/sh
Encoding=UTF-8

enter(){
echo "Mounting directories..."
mount -t proc none /proc
mount -t sysfs none /sys
mount -t devpts none /dev/pts
export HOME=/root
export LC_ALL=C
dbus-uuidgen > /var/lib/dbus/machine-id
dpkg-divert --local --rename --add /sbin/initctl
ln -s /bin/true /sbin/initctl
echo "Moving to system root directory..."
cd
/bin/bash
leave
}

leave(){
echo "Cleaning up before chroot exit..."
apt autoremove --purge
apt clean
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
umount /proc || umount -lf /proc
umount /sys
umount /dev/pts
echo "Exiting chroot..."
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
 echo "Usage: $0 (enter|leave)"
     ;;
 esac' > /media/$SYSUSER/$PART/$SYSDIR/utils/chroot-manager
chmod +x /media/$SYSUSER/$PART/$SYSDIR/utils/chroot-manager
cp /media/$SYSUSER/$PART/$SYSDIR/utils/chroot-manager /media/$SYSUSER/$PART/$SYSDIR/edit/usr/sbin/chroot-manager
}

enterchroot() {
#get prerequisites
echo '\nGetting prerequisites...'
apt install -y squashfs-tools genisoimage syslinux-utils
cd /media/$SYSUSER/$PART/$SYSDIR
echo '\nBinding directories...'
mount -o bind /run/ /media/$SYSUSER/$PART/$SYSDIR/edit/run
mount --bind /dev /media/$SYSUSER/$PART/$SYSDIR/edit/dev
mount --bind /proc /media/$SYSUSER/$PART/$SYSDIR/edit/proc
cp /etc/hosts /media/$SYSUSER/$PART/$SYSDIR/edit/etc/hosts
mkdir /media/$SYSUSER/$PART/$SYSDIR/edit/run/systemd/resolve
echo 'nameserver '${CHROOTDNS}'' > /media/$SYSUSER/$PART/$SYSDIR/edit/run/systemd/resolve/stub-resolv.conf
echo '\nChrooting...'
chroot /media/$SYSUSER/$PART/$SYSDIR/edit chroot-manager enter
umount /media/$SYSUSER/$PART/$SYSDIR/edit/run
umount /media/$SYSUSER/$PART/$SYSDIR/edit/proc
umount /media/$SYSUSER/$PART/$SYSDIR/edit/dev
rm -f /media/$SYSUSER/$PART/$SYSDIR/edit/etc/hosts
rm -rf /media/$SYSUSER/$PART/$SYSDIR/edit/root/.[^.]*
rm -rf /media/$SYSUSER/$PART/$SYSDIR/edit/tmp/.[^.]*
rm -rf /media/$SYSUSER/$PART/$SYSDIR/edit/var/cache/apt/.[^.]*
rm -rf /media/$SYSUSER/$PART/$SYSDIR/edit/var/cache/fontconfig/.[^.]*
rm -rf /media/$SYSUSER/$PART/$SYSDIR/edit/var/lib/apt/lists/.[^.]*
rm -rf /media/$SYSUSER/$PART/$SYSDIR/edit/etc/apt/*.save
rm -rf /media/$SYSUSER/$PART/$SYSDIR/edit/etc/apt/sources.list.d/*.save
}

makedisk() {
echo '\n Jumping above root directory, moving files...\n'
cleanup
mkdir /media/$SYSUSER/$PART/$SYSDIR/edit/root/.config
mkdir /media/$SYSUSER/$PART/$SYSDIR/edit/root/.config/dconf
mkdir /media/$SYSUSER/$PART/$SYSDIR/edit/var/cache/apt/archives
mkdir /media/$SYSUSER/$PART/$SYSDIR/edit/var/cache/apt/archives/partial
touch /media/$SYSUSER/$PART/$SYSDIR/edit/var/cache/apt/archives/lock
cp -f /media/$SYSUSER/$PART/$SYSDIR/utils/initctl /media/$SYSUSER/$PART/$SYSDIR/edit/sbin/initctl
cp -f /media/$SYSUSER/$PART/$SYSDIR/utils/.bashrc /media/$SYSUSER/$PART/$SYSDIR/edit/root/.bashrc
cp -f /media/$SYSUSER/$PART/$SYSDIR/utils/.bashrc /media/$SYSUSER/$PART/$SYSDIR/edit/etc/skel/.bashrc
cp -f /media/$SYSUSER/$PART/$SYSDIR/utils/user /media/$SYSUSER/$PART/$SYSDIR/edit/root/.config/dconf/user
cp -f /media/$SYSUSER/$PART/$SYSDIR/utils/user /media/$SYSUSER/$PART/$SYSDIR/edit/etc/skel/.config/dconf/user

#set distro identity
echo '# This file should go in /etc/casper.conf
# Supported variables are:
# USERNAME, USERFULLNAME, HOST, BUILD_SYSTEM, FLAVOUR

export USERNAME="'${USERNAME}'"
export USERFULLNAME="Live session user"
export HOST="'${HOST}'"
export BUILD_SYSTEM="Ubuntu"

# USERNAME and HOSTNAME as specified above will not be honoured and will be set to
# flavour string acquired at boot time, unless you set FLAVOUR to any
# non-empty string.

export FLAVOUR="'${FLAVOUR}'"' > /media/$SYSUSER/$PART/$SYSDIR/edit/etc/casper.conf

echo ${DISTRONAME}' '${VERSION}' \\n \l' > /media/$SYSUSER/$PART/$SYSDIR/edit/etc/issue

echo ${DISTRONAME}' '${VERSION} > /media/$SYSUSER/$PART/$SYSDIR/edit/etc/issue.net

echo 'DISTRIB_ID=Ubuntu
DISTRIB_RELEASE="'${UBURELEASE}'"
DISTRIB_CODENAME="'${UBUCODE}'"
DISTRIB_DESCRIPTION="'${DISTRONAME}' '${VERSION}'"' > /media/$SYSUSER/$PART/$SYSDIR/edit/etc/lsb-release

echo '
The programs included with the '${DISTRONAME}' system are free software;
the exact distribution terms for each program are described in the
individual files in /usr/share/doc/*/copyright.

'${DISTRONAME}' comes with ABSOLUTELY NO WARRANTY, to the extent permitted by
applicable law.
' > /media/$SYSUSER/$PART/$SYSDIR/edit/etc/legal

echo 'NAME="'${DISTRONAME}'"
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
UBUNTU_CODENAME="'${UBUCODE}'"' > /media/$SYSUSER/$PART/$SYSDIR/edit/usr/lib/os-release

echo '#!/bin/sh
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

printf "\n * Support:  '${DISTROURL}'\n"' > /media/$SYSUSER/$PART/$SYSDIR/edit/etc/update-motd.d/10-help-text
chmod +x /media/$SYSUSER/$PART/$SYSDIR/edit/etc/update-motd.d/10-help-text

echo '#define DISKNAME  '${DISTRONAME}' '${VERSION}'
#define TYPE  binary
#define TYPEbinary  1
#define ARCH  amd64
#define ARCHamd64  1
#define DISKNUM  1
#define DISKNUM1  1
#define TOTALNUM  0
#define TOTALNUM0  1' > /media/$SYSUSER/$PART/$SYSDIR/extract-cd/README.diskdefines

echo ${ISOINFO} > /media/$SYSUSER/$PART/$SYSDIR/extract-cd/.disk/info

echo ${DISTROURL} > /media/$SYSUSER/$PART/$SYSDIR/extract-cd/.disk/release_notes_url

#regenerate manifest
echo '\n Regenerating manifest...'
chmod +w extract-cd/casper/filesystem.manifest
chroot edit dpkg-query -W --showformat='${Package} ${Version}\n' | tee extract-cd/casper/filesystem.manifest
cp extract-cd/casper/filesystem.manifest extract-cd/casper/filesystem.manifest-desktop
sed -i '/ubiquity/d' extract-cd/casper/filesystem.manifest-desktop
sed -i '/casper/d' extract-cd/casper/filesystem.manifest-desktop

#compress filesystem
echo '\n Compressing filesystem...\n'
rm extract-cd/casper/filesystem.squashfs
mksquashfs edit extract-cd/casper/filesystem.squashfs -comp xz
printf $(du -sx --block-size=1 edit | cut -f1) | tee extract-cd/casper/filesystem.size

#update md5sums
echo '\n Updating md5 sums...'
cd extract-cd
rm md5sum.txt
find -type f -print0 | xargs -0 md5sum | grep -v isolinux/boot.cat | tee md5sum.txt

#create iso image
echo '\n Creating the iso...'
mkisofs -input-charset utf-8 -U -A $NEWISO -V $NEWISO -volset $NEWISO -J -joliet-long -r -v -T -o ../$NEWISO.iso -b isolinux/isolinux.bin -c isolinux/boot.cat -no-emul-boot -boot-load-size 4 -boot-info-table -eltorito-alt-boot -e boot/grub/efi.img -no-emul-boot .
cd ../
isohybrid $NEWISO.iso
echo '\n Computing the SHA256 sum for the iso file...'
echo 'sha256sum: ' > $NEWISO-sha256sum.txt
sha256sum $NEWISO.iso >> $NEWISO-sha256sum.txt
echo '\n iso creation finished'
}

extractinitrd() {
cd initrd-rebuild

#For initrd.gz from an apt-get upgrade in chroot
#gzip -dc ../initrd.gz | cpio -id

#For initrd.gz in the iso file
#gzip -dc ../extract-cd/casper/initrd.gz | cpio -id

#For initrd.lz in the iso file
lzma -dc -S .lz ../extract-cd/casper/initrd.lz | cpio -id
}

repackinitrd() {
cd initrd-rebuild
find . | cpio --quiet --dereference -o -H newc | lzma -7 > ../extract-cd/casper/initrd-new.lz
}

cleanup() {
echo '\n Setting permissions, cleaning up...\n'
umount /media/$SYSUSER/$PART/$SYSDIR/edit/dev
find /media/$SYSUSER/$PART/$SYSDIR/extract-cd/isolinux -type f -exec chmod 644 {} \;
find /media/$SYSUSER/$PART/$SYSDIR/edit/etc/apt/sources.list.d -name "*.save" -type f -exec rm -f {} \;
find /media/$SYSUSER/$PART/$SYSDIR/edit/home -type f -exec rm -f {} \;
find /media/$SYSUSER/$PART/$SYSDIR/edit/root -type f -exec rm -f {} \;
find /media/$SYSUSER/$PART/$SYSDIR/edit/tmp -type f -exec rm -f {} \;
find /media/$SYSUSER/$PART/$SYSDIR/edit/var/crash -type f -exec rm -f {} \;
find /media/$SYSUSER/$PART/$SYSDIR/edit/var/lib/apt -type f -exec rm -f {} \;
find /media/$SYSUSER/$PART/$SYSDIR/edit/var/log -type f -exec rm -f {} \;
find /media/$SYSUSER/$PART/$SYSDIR/edit/var/tmp -type f -exec rm -f {} \;
find /media/$SYSUSER/$PART/$SYSDIR/edit/usr/local -name "*.py[co]" -o -name __pycache__ -exec rm -rf {} \;
cd /media/$SYSUSER/$PART/$SYSDIR
}

syncfolders() {
# rsync the html folder
rsync -av --delete /usr/local/share/html/ /media/$SYSUSER/$PART/$SYSDIR/edit/usr/local/share/html/

# rsync the mozilla folder (firefox)
rm -rf /home/$SYSUSER/.mozilla/firefox/bookmarkbackups/.[^.]*
rm -rf /home/$SYSUSER/.mozilla/firefox/*.default/storage/{default,permanent,temporary}
rsync -av --delete /home/$SYSUSER/.mozilla/ /media/$SYSUSER/$PART/$SYSDIR/edit/etc/skel/.mozilla/
}

copydconf(){
yes | cp -f /home/$SYSUSER/.config/dconf/user /media/$SYSUSER/$PART/$SYSDIR/utils/user
}

ans=$(zenity  --list --height 340 --width 470 --text "LiveCD Respinner Script" \
--radiolist  --column "Pick" --column "Action" TRUE "Do Nothing" \
FALSE "Extract Isofile Contents" \
FALSE "Enter the Chroot Environment" \
FALSE "Create New Iso File" \
FALSE "Extract Initrd Contents" \
FALSE "Repack Initrd Contents" \
FALSE "Sync Mozilla and HTML folders" \
FALSE "Sync current dconf/user file" \
FALSE "Distro Cleanup Actions" );

	if [  "$ans" = "Do Nothing" ]; then
		exit

	elif [  "$ans" = "Extract Isofile Contents" ]; then
		extract

	elif [  "$ans" = "Enter the Chroot Environment" ]; then
		enterchroot

	elif [  "$ans" = "Create New Iso File" ]; then
		makedisk

	elif [  "$ans" = "Extract Initrd Contents" ]; then
		extractinitrd

	elif [  "$ans" = "Repack Initrd Contents" ]; then
		repackinitrd

	elif [  "$ans" = "Sync Mozilla and HTML folders" ]; then
		syncfolders

	elif [  "$ans" = "Sync current dconf settings" ]; then
		copydconf

	elif [  "$ans" = "Distro Cleanup Actions" ]; then
		cleanup

	fi
