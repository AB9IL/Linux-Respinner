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
SYSUSER=$(whoami) # your username as builder of the respin
CHROOTDNS='9.9.9.9' # dns while in the chroot
SYSDIR=pemmican  # working directory of the respin project
ISONAME=pemmican-latest # filename for the iso to be extracted
ISOCONTENTS='extract-cd' # directory containing the extracted iso contents
MBR_FILE=mbr.img # mbr from recent iso, (dd if="$ISONAME" bs=1 count=512 of=mbr.img)
ISOINFO='Pemmican Linux 1.0 - Release amd64 (20200330)' # data for the .disk/info file in the respun iso
UBURELEASE=16.04 # Release Year.Month for Ubuntu distros
UBUCODE=xenial # Ububtu codename
MINTCODE=sylvia # Mint codename
NEWISO=pemmican-latest # filename for the new iso
DISTRONAME="Pemmican Linux" # plain language name for the respun distro
DISTROURL="https://pemmicanlinux.com" # url for the respin's web page
FLAVOUR=Pemmican #  /etc/casper.conf flavour in the respun distro
HOST=pemmican #  /etc/casper.conf host in the respun distro
USERNAME=user # /etc/casper.conf user in the respun distro
VERSION=1b0 # version number of the respun distro
ARCH='amd64'

#DO NOT EDIT BELOW THIS LINE
#---------------------------------------------------------------

extract() {
#apt update
#apt install -y squashfs-tools genisoimage syslinux-utils xorriso
mkdir mnt
mkdir utils
mkdir $ISOCONTENTS
mount -o loop $ISONAME mnt
rsync -avhc --inplace --no-whole-file --exclude=/casper/filesystem.squashfs  mnt/ $ISOCONTENTS
unsquashfs -f mnt/casper/filesystem.squashfs
mv squashfs-root edit
#cp /sbin/initctl utils/initctl
umount mnt
rm -rf mnt
echo '#!/bin/sh
Encoding=UTF-8

enter(){
echo "Mounting directories..."
mount -t proc none /proc
mount -t sysfs none /sys
mount -t dev none /dev
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
umount /dev
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
 esac
' > utils/chroot-manager
chmod +x utils/chroot-manager
cp utils/chroot-manager edit/usr/sbin/chroot-manager
echo '#!/bin/bash

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
echo "Task finished; look in $HOME for the files."
}

case "$1" in
	-h*|-H*)
		if [[ "$2" -ne "0" || -z "$2" ]]; then
			echo "usage: build-bootfiles <kernel>"
			exit
		fi
	;;
	*)
		create
	;;
esac
' > utils/build-bootfiles
chmod +x utils/build-bootfiles
cp utils/build-bootfiles edit/usr/sbin/build-bootfiles
}

enterchroot() {
#get prerequisites
echo '\nGetting prerequisites...'
apt install -y squashfs-tools genisoimage syslinux-utils xorriso
echo '\nBinding directories...'
mount -o bind /run/ edit/run
mount --bind /dev edit/dev
mount --bind /proc edit/proc
cp /etc/hosts edit/etc/hosts
mkdir edit/run/systemd/resolve
echo 'nameserver '${CHROOTDNS}'' > edit/run/systemd/resolve/resolv.conf
echo 'nameserver '${CHROOTDNS}'' > edit/run/systemd/resolve/stub-resolv.conf
echo '\nChrooting...'
chroot edit chroot-manager enter
umount edit/run
umount edit/proc
umount edit/dev
rm -f edit/etc/hosts
rm -rf edit/root/.[^.]*
rm -rf edit/run/systemd/resolve/.[^.]*
rm -rf edit/tmp/.[^.]*
rm -rf edit/var/cache/apt/.[^.]*
rm -rf edit/var/cache/fontconfig/.[^.]*
rm -rf edit/var/cache/man/.[^.]*
rm -rf edit/var/lib/apt/lists/.[^.]*
rm -rf edit/etc/apt/*.save
rm -rf edit/etc/apt/sources.list.d/*.save
}

makedisk() {
echo '\n Create '${NEWISO}'.iso!'
echo '\n Jumping above root directory, moving files...\n'
cleanup
mkdir edit/root/.config
mkdir edit/root/.config/dconf
mkdir edit/root/.config/compton
mkdir edit/root/.config/i3
mkdir edit/var/cache/apt/archives
mkdir edit/var/cache/apt/archives/partial
mkdir edit/var/cache/apt/archives/lightdm
mkdir edit/var/cache/apt/archives/lightdm/dmrc
touch edit/var/cache/apt/archives/lock
cp -f utils/initctl edit/sbin/initctl
cp -f utils/.bashrc edit/etc/skel/.bashrc
cp -f edit/etc/skel/.bashrc edit/root/.bashrc
cp -f utils/user edit/etc/skel/.config/dconf/user
cp -f edit/etc/skel/.config/dconf/user edit/root/.config/dconf/user
cp -f utils/.Xresources edit/etc/skel/.Xresources
cp -f edit/etc/skel/.Xresources edit/root/.Xresources
cp -f utils/.nanorc edit/etc/skel/.nanorc
cp -f edit/etc/skel/.nanorc edit/root/.nanorc
cp -f utils/.wgetrc edit/etc/skel/.wgetrc
cp -f edit/etc/skel/.wgetrc edit/root/.wgetrc
cp -f utils/.inputrc edit/etc/skel/.inputrc
cp -f edit/etc/skel/.inputrc edit/root/.inputrc
cp -f edit/etc/skel/.fzf.bash edit/root/.fzf.bash
cp -f edit/etc/skel/.tmux.conf edit/root/.tmux.conf
rsync -avhc --inplace --no-whole-file --delete utils/nvim/ edit/root/.config/nvim/
rsync -avhc --inplace --no-whole-file --delete utils/nvim/ edit/etc/skel/.config/nvim/
rsync -avhc --inplace --no-whole-file --delete utils/.mozilla/ edit/etc/skel/.mozilla/
rsync -avhc --inplace --no-whole-file --delete utils/.local/ edit/root/.local/
rsync -avhc --inplace --no-whole-file --delete utils/.local/ edit/etc/skel/.local/
rsync -avhc --inplace --no-whole-file --delete edit/etc/skel/.tmux/ edit/root/.tmux/
rsync -avhc --inplace --no-whole-file --delete edit/etc/skel/.config/ edit/root/.config/compton/
rsync -avhc --inplace --no-whole-file --delete edit/etc/skel/.config/ edit/root/.config/i3/

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

export FLAVOUR="'${FLAVOUR}'"' > edit/etc/casper.conf

echo ${DISTRONAME}' '${VERSION}' \\n \l' > edit/etc/issue

echo ${DISTRONAME}' '${VERSION} > edit/etc/issue.net

echo 'DISTRIB_ID='${DISTRIBID}'
DISTRIB_RELEASE='${DISTRIBRELEASE}'
DISTRIB_CODENAME='${DISTRIBCODE}'
DISTRIB_DESCRIPTION="'${DISTRONAME}' '${VERSION}'"' > edit/etc/lsb-release

echo '
The programs included with the '${DISTRONAME}' system are free software;
the exact distribution terms for each program are described in the
individual files in /usr/share/doc/*/copyright.

'${DISTRONAME}' comes with ABSOLUTELY NO WARRANTY, to the extent permitted by
applicable law.
' > edit/etc/legal

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
UBUNTU_CODENAME="'${UBUCODE}'"' > edit/usr/lib/os-release

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

printf "\n * Support:  '${DISTROURL}'\n"' > edit/etc/update-motd.d/10-help-text
chmod +x edit/etc/update-motd.d/10-help-text

echo '#define DISKNAME  '${DISTRONAME}' '${VERSION}'
#define TYPE  binary
#define TYPEbinary  1
#define ARCH  amd64
#define ARCHamd64  1
#define DISKNUM  1
#define DISKNUM1  1
#define TOTALNUM  0
#define TOTALNUM0  1' > $ISOCONTENTS/README.diskdefines

echo ${ISOINFO} > $ISOCONTENTS/.disk/info

echo ${DISTROURL} > $ISOCONTENTS/.disk/release_notes_url

#regenerate manifest
echo '\n Regenerating manifest...'
chmod +w $ISOCONTENTS/casper/filesystem.manifest
chroot edit dpkg-query -W --showformat='${Package} ${Version}\n' | \
tee $ISOCONTENTS/casper/filesystem.manifest $NEWISO-build.log
cp $ISOCONTENTS/casper/filesystem.manifest $ISOCONTENTS/casper/filesystem.manifest-desktop
sed -i '/ubiquity/d' $ISOCONTENTS/casper/filesystem.manifest-desktop
sed -i '/casper/d' $ISOCONTENTS/casper/filesystem.manifest-desktop
sed -i '/discover/d' $ISOCONTENTS/casper/filesystem.manifest-desktop
sed -i '/laptop-detect/d' $ISOCONTENTS/casper/filesystem.manifest-desktop
sed -i '/os-prober/d' $ISOCONTENTS/casper/filesystem.manifest-desktop

#compress filesystem
echo '\n Compressing filesystem...\n'
rm $ISOCONTENTS/casper/filesystem.squashfs
mksquashfs edit $ISOCONTENTS/casper/filesystem.squashfs -comp xz
printf $(du -sx --block-size=1 edit | cut -f1) | \
tee $ISOCONTENTS/casper/filesystem.size

#update md5sums
#filename MD5SUMS for linux Mint, md5sum.txt for Ubuntu derivatives
cd $ISOCONTENTS
echo '\n Updating md5 sums...'
rm md5sum.txt
find -type f -print0 | xargs -0 md5sum | grep -v isolinux/boot.cat | \
tee md5sum.txt ../$NEWISO-build.log 2>&1
cd ../

#remove the old iso file
echo '\n If exists, delete the old '${NEWISO}'.iso...'
rm -f $NEWISO.iso

#create iso image
echo '\n Creating '${NEWISO}'.iso...'
cd $ISOCONTENTS
# do not change the order of the xorriso options
# do not remove repeated xorriso options
xorrisofs -v \
	-J -J -joliet-long \
	-full-iso9660-filenames \
	-input-charset utf-8 \
	-rational-rock \
	-volset "$FLAVOUR$VERSION-$ARCH" \
	-volid "$FLAVOUR$VERSION-$ARCH" \
	-o ../$NEWISO.iso \
	-isohybrid-mbr ../utils/$MBR_FILE \
	-eltorito-boot isolinux/isolinux.bin \
	-eltorito-catalog isolinux/boot.cat \
	-no-emul-boot \
	-boot-load-size 4 \
	-boot-info-table \
	-eltorito-alt-boot \
	-e boot/grub/efi.img \
	-no-emul-boot \
	-isohybrid-gpt-basdat \
	.
cd ../
echo '\n Computing the SHA256 sum:' | tee $NEWISO-build.log 2>&1
sha256sum $NEWISO.iso | tee -a $NEWISO-build.log 2>&1
echo '\n Boot record information:'
fdisk -lu $NEWISO.iso | tee -a $NEWISO-build.log 2>&1
echo 'Boot catalog and image paths:'
xorriso -indev $NEWISO.iso -toc -pvd_info | tee -a $NEWISO-build.log 2>&1
echo '\n '${NEWISO}' creation finished'
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
echo '\n Setting permissions, cleaning up...\n'
umount edit/dev
chown -R man:root edit/var/cache/man
find edit/usr/local -name "*.txt" -exec chmod 666 {} \;
find edit/usr/local -name "*.conf" -exec chmod 666 {} \;
find edit/usr/local -name "*.db" -exec chmod 666 {} \;
find edit/usr/local -name "*.md" -exec chmod 666 {} \;
find edit/usr/local -name "*.html" -exec chmod 666 {} \;
find edit/usr/local/sbin -name "*.py" -exec chmod 755 {} \;
find edit/usr/local/sbin -name "*.sh" -exec chmod 755 {} \;
find edit/usr/local/etc -type f -exec chmod 666 {} \;
find edit/var/cache -name "*.db" -exec chmod 664 {} \;
find edit/var/cache -name "*.TAG" -exec chmod 664 {} \;
find edit/var/log -type d -exec chmod 755 {} \;
find $ISOCONTENTS/isolinux -type f -exec chmod 644 {} \;
find edit/etc/apt/sources.list.d -name "*.save" -type f -exec rm -f {} \;
find edit/home -type f -exec rm -f {} \;
find edit/root -type f -exec rm -f {} \;
find edit/tmp -type f -exec rm -f {} \;
find edit/var/crash -type f -exec rm -f {} \;
find edit/var/lib/apt -type f -exec rm -f {} \;
find edit/var/log -type f -exec rm -f {} \;
find edit/var/tmp -type f -exec rm -f {} \;
find edit/usr/local -name "*.py[co]" -o -name __pycache__ -exec rm -rf {} \;
find edit/opt -name "*.py[co]" -o -name __pycache__ -exec rm -rf {} \;
find $ISOCONTENTS -name "TRANS.TBL" -exec rm -rf {} \;
find edit -name "*.dpkg-old" -exec rm -rf {} \;
find edit -name "*.dpkg-dist" -exec rm -rf {} \;
chmod 4755 edit/usr/bin/pkexec
chmod 4755 edit/usr/bin/sudo
chown root:messagebus edit/usr/lib/dbus-1.0/dbus-daemon-launch-helper
chmod u+s edit/usr/lib/dbus-1.0/dbus-daemon-launch-helper
rmdir edit/tmp/*
}

syncHTML() {
# rsync the html folder
rsync -avhc --inplace --no-whole-file --delete /usr/local/share/html/ utils/html/
chown -R root:root utils/html
rsync -avhc --inplace --no-whole-file --delete utils/html/ backup/usr/local/share/html/
}

syncMozilla() {
# rsync the mozilla folder (firefox)
rm -rf /home/$SYSUSER/.mozilla/firefox/bookmarkbackups/.[^.]*
rm -rf /home/$SYSUSER/.mozilla/firefox/*.default/storage/{default,permanent,temporary}
rsync -avhc --inplace --no-whole-file --delete /home/$SYSUSER/.mozilla/ utils/.mozilla/
chown -R root:root utils/.mozilla
rsync -avhc --inplace --no-whole-file --delete utils/.mozilla/ backup/etc/skel/.mozilla/
}

makebackup(){
echo '\n Copying '${NEWISO}'.iso to '${NEWISO}'.bak.iso...\n'
cp -fp $NEWISO.iso $NEWISO.bak.iso
echo 'Backup job complete...'
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
	syncmozilla)
		syncMozilla
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
	echo "Usage: multifunction.sh <command>

			chroot		Enter a chroot environment
			makedisk	Create a new iso file based on edited filesystem
			backup		Create a backup of the iso file
			extractiso	Extract filesystem from iso file
			extractinit	Extract contents of initrd file
			repackinit	Rebuild initrd from extracted contents
			syncmozilla	sync the iso Mozilla directory to live system
			synchtml	sync the iso /usr/local/share/html to live system
			syncdconf	sync the iso dconf to live system
			cleanup		clean cruft and set permissions in the iso filesystem

" >&2
	exit 3
	;;
esac
