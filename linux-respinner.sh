#!/bin/sh

# Copyright (c) 2018 by Philip Collier, <webmaster@mofolinux.com>
# mofo-updater is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 3 of the License, or
# (at your option) any later version. There is NO warranty; not even for
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

Encoding=UTF-8

# Run this script to extract the iso contents and set up the chroot
# environment or make changes and rebuild a bootable live linux iso file.
# Define the user, working directory, original iso file
# and new iso file for the respun distro

# system username
SYSUSER=winston

# partition being used
PART=data1

# working directory
SYSDIR=churchill

# original iso file name
ISONAME=mylinux-orig

# respin iso file name
NEWISO=mylinux-latest

#----------DO NOT EDIT BELOW THIS LINE----------

extract() {
#apt update
#apt install -y squashfs-tools genisoimage syslinux-utils
cd /media/$SYSUSER/$PART/$SYSDIR
mkdir mnt
mkdir utils
mount -o loop /isodevice/isofiles/$ISONAME.iso mnt
mkdir extract-cd
sudo rsync --exclude=/casper/filesystem.squashfs -a mnt/ extract-cd
unsquashfs mnt/casper/filesystem.squashfs
mv squashfs-root edit
cp /sbin/initctl /media/$SYSUSER/$PART/$SYSDIR/utils/initctl
umount mnt
rm -rf /media/$SYSUSER/$PART/$SYSDIR/mnt
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
echo '\nChrooting...'
chroot /media/$SYSUSER/$PART/$SYSDIR/edit chroot-manager enter
umount /media/$SYSUSER/$PART/$SYSDIR/edit/run
umount /media/$SYSUSER/$PART/$SYSDIR/edit/proc
umount /media/$SYSUSER/$PART/$SYSDIR/edit/dev
rm -ff /media/$SYSUSER/$PART/$SYSDIR/edit/etc/hosts
rm -rf /media/$SYSUSER/$PART/$SYSDIR/edit/root/.[^.]*
rm -rf /media/$SYSUSER/$PART/$SYSDIR/edit/tmp/.[^.]*
rm -rf /media/$SYSUSER/$PART/$SYSDIR/edit/var/cache/apt/.[^.]*
rm -rf /media/$SYSUSER/$PART/$SYSDIR/edit/var/cache/fontconfig/.[^.]*
rm -rf /media/$SYSUSER/$PART/$SYSDIR/edit/var/lib/apt/lists/.[^.]*
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
mkisofs -U -A $NEWISO -V $NEWISO -volset $NEWISO -J -joliet-long -r -v -T -o ../$NEWISO.iso -b isolinux/isolinux.bin -c isolinux/boot.cat -no-emul-boot -boot-load-size 4 -boot-info-table -eltorito-alt-boot -e boot/grub/efi.img -no-emul-boot .
cd ../
isohybrid $NEWISO.iso
echo '\n Computing MD5 and SHA1 sums for the iso file...'
echo 'md5sum: ' > $NEWISO-md5sum.txt
md5sum $NEWISO.iso >> $NEWISO-md5sum.txt
echo 'sha1sum: ' >> $NEWISO-md5sum.txt
sha1sum $NEWISO.iso >> $NEWISO-md5sum.txt
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
#chown -R root:root /media/$SYSUSER/$PART/$SYSDIR/edit/opt
#chown -R root:root /media/$SYSUSER/$PART/$SYSDIR/edit/usr/local
#chown -R root:root /media/$SYSUSER/$PART/$SYSDIR/edit/etc/skel
#chmod -R 666 /media/$SYSUSER/$PART/$SYSDIR/edit/opt
#chmod -R 755 /media/$SYSUSER/$PART/$SYSDIR/edit/usr/local/*bin
#chmod 4755 /media/$SYSUSER/$PART/$SYSDIR/edit/usr/bin/sudo
#find /media/$SYSUSER/$PART/$SYSDIR/edit/opt -name "*.sh" -exec chmod 777 {} \;
#find /media/$SYSUSER/$PART/$SYSDIR/edit/etc/skel -type d -exec chmod 777 {} \;
#find /media/$SYSUSER/$PART/$SYSDIR/edit/etc/skel -type f -exec chmod 644 {} \;
#find /media/$SYSUSER/$PART/$SYSDIR/edit/usr/local -type d -exec chmod 777 {} \;
#find /media/$SYSUSER/$PART/$SYSDIR/edit/usr/local -type f -exec chmod 644 {} \;
#find /media/$SYSUSER/$PART/$SYSDIR/edit/usr/local -name "*.txt" -exec chmod 666 {} \;
#find /media/$SYSUSER/$PART/$SYSDIR/edit/usr/local -name "*.conf" -exec chmod 666 {} \;
#find /media/$SYSUSER/$PART/$SYSDIR/edit/usr/local -name "*.sh" -exec chmod 777 {} \;
#chmod 4755 /media/$SYSUSER/$PART/$SYSDIR/edit/usr/bin/sudo
rm -rf /media/$SYSUSER/$PART/$SYSDIR/edit/etc/apt/sources.list.d/*.save
rm -rf /media/$SYSUSER/$PART/$SYSDIR/edit/home/.[^.]*
rm -rf /media/$SYSUSER/$PART/$SYSDIR/edit/root/.[^.]*
rm -rf /media/$SYSUSER/$PART/$SYSDIR/edit/tmp/.[^.]*
rm -rf /media/$SYSUSER/$PART/$SYSDIR/edit/var/cache/apt/.[^.]*
rm -rf /media/$SYSUSER/$PART/$SYSDIR/edit/var/cache/fontconfig/.[^.]*
rm -rf /media/$SYSUSER/$PART/$SYSDIR/edit/var/crash/.[^.]*
rm -rf /media/$SYSUSER/$PART/$SYSDIR/edit/var/lib/apt/lists/.[^.]*
rm -rf /media/$SYSUSER/$PART/$SYSDIR/edit/var/log/.[^.]*
rm -rf /media/$SYSUSER/$PART/$SYSDIR/edit/var/tmp/.[^.]*
cd /media/$SYSUSER/$PART/$SYSDIR/edit/usr/local
find . -name "*.pyc" -print0 | xargs -0 rm -rf
cd /media/$SYSUSER/$PART/$SYSDIR/edit/opt
find . -name "*.pyc" -print0 | xargs -0 rm -rf
cd /media/$SYSUSER/$PART/$SYSDIR
}

ans=$(zenity  --list --height 340 --width 470 --text "LiveCD Respinner Script" \
--radiolist  --column "Pick" --column "Action" TRUE "Do Nothing" \
FALSE "Extract Isofile Contents" \
FALSE "Enter the Chroot Environment" \
FALSE "Create New Iso File" \
FALSE "Extract Initrd Contents" \
FALSE "Repack Initrd Contents" \
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

	elif [  "$ans" = "Distro Cleanup Actions" ]; then
		cleanup

	fi

