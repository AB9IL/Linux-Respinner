#!/bin/bash
Encoding=UTF-8
[[ $EUID -ne 0 ]] && echo "You must be root to run this script." && exit

# Multifunction Linux Distro Respinner Script v0.80.
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
#
#>>>  THIS VERSION FOR                                 <<<
#>>>  Debian 12 or any Ubuntu before or after 20.10    <<<
#>>>  For Ubuntu, be sure to set UBURELEASE variable!! <<<

#apt update
#apt install -y squashfs-tools genisoimage syslinux-utils xorriso fzf fd-find
# define variables:
export WKDIR="$(readlink -f "$(dirname "$0")")"
export BUILDDATE="$(date -u "+%Y%m%e")"
export RELEASEDATE="$(date -u "+%Y/%m/%d")"
export SYSUSER="$(logname)" # your username as builder of the respin
export CHROOTDNS='1.1.1.1' # DNS to use during chroot operation
export SYSDIR='respun-rhino' # the working directory of the respin project
export ISONAME="Rhino-Linux-2023.4-amd64.iso" # the filename for the iso to be extracted
export ISOCONTENTS='extract-cd' # directory containing the extracted iso contents
export VERSION='0.1.0' # version number of the respun distro
export UBURELEASE='2023.4' # Release Year.Month for Ubuntu distros (e.g. 23.10)
export UBUCODE='rhino' # Ubuntu or Debian codename
export MINTRELEASE=''
export MINTCODE='' # Mint codename
export DISTRIBID='Ubuntu' # LinuxMint or Ubuntu or Debian
export DISTRIBRELEASE=$UBURELEASE # variable for Mint or Ubuntu release
export DISTRIBCODE=$UBUCODE # variable for Mint or Ubuntu codename
export NEWISO="$SYSDIR-latest" # filename for the new iso derived from directory name
export DISTRONAME='Respun Rhino' # plain language name for the respun distro
export DISTROURL='https://example.com' # url for the respin's web page
export FLAVOUR='Rhino' # /etc/casper.conf flavour
export HOST='rhino' # /etc/casper.conf host in the respun distro
export USERNAME='user' # /etc/casper.conf user in the respun distro
export ARCH='amd64'
export RFSCONTENTS='edit' # directory containing the distro root filesystem
export ISOINFO="$DISTRONAME $VERSION - Release $ARCH ($BUILDDATE)" # data for the .disk/info file in the respun iso
export PROCNUM=4 # processor cores to use for filesystem extraction / compression
#---DO NOT EDIT BELOW THIS LINE------------------------------------------------
[[ $(echo "$UBURELEASE > 20.04" | bc -l) -eq 1 ]] && UBUAGE="new" || UBUAGE="old" # set distro age for Ubuntu Rhino distros
[[ "$UBUCODE" == "rhino" ]] && UBUAGE="zero" # set distro age for Ubuntu Rhino distros
[[ "$DISTRIBID" == "Debian"  ]] && export MBR_FILE='isohdpfx.bin' # Proper mbr data for Debian isos
[[ "$DISTRIBID" == "Debian"  ]] || export MBR_FILE='mbr.img' # Proper mbr data for Mint or Ubuntu isos
[[ "$DISTRIBID" == "Debian"  ]] || export EFI_FILE='efi.img' # efi from original Ubuntu 20.10+ iso

extract_ubuntu() {
    mkdir mnt
    [[ -d "utils" ]] || mkdir utils
    [[ -d "$ISOCONTENTS" ]] || mkdir $ISOCONTENTS
    [[ -d "$RFSCONTENTS" ]] || mkdir $RFSCONTENTS
    case "$UBUAGE" in
    new)
        # Extract the hybrid MBR template
        dd if="$ISONAME" bs=1 count=432 of="${WKDIR}"/utils/"$MBR_FILE"
        # Extract EFI partition image
        skip=$(/sbin/fdisk -l "$ISONAME" | grep -F '.iso2 ' | awk '{print $2}')
        size=$(/sbin/fdisk -l "$ISONAME" | grep -F '.iso2 ' | awk '{print $4}')
        dd if="$ISONAME" bs=512 skip="$skip" count="$size" of="${WKDIR}"/utils/"$EFI_FILE"
        ;;
    old)
        # Extract the hybrid MBR template
        dd if="$ISONAME" bs=1 count=512 of="${WKDIR}"/utils/"$MBR_FILE"
        ;;
    esac
    #
    mount -o loop $ISONAME mnt
    rsync -avhc --inplace \
        mnt/ ${ISOCONTENTS}/
    find ${ISOCONTENTS}/casper -type f -iname "*.squashfs" \
        -exec unsquashfs -p $PROCNUM -f -d $RFSCONTENTS {} \;
    umount mnt
    rm -rf mnt
    # copy certain files to utils
    (cat $RFSCONTENTS/sbin/initctl > utils/initctl) &
    (cat $RFSCONTENTS/etc/skel/.bashrc > utils/.bashrc) &
    (cat $RFSCONTENTS/etc/skel/.bash_misc > utils/.bash_misc) &
    (cat $RFSCONTENTS/etc/skel/.bash_aliases > utils/.bash_aliases) &
    (cat $RFSCONTENTS/etc/skel/.config/dconf/user > utils/user) &
    (cat $RFSCONTENTS/etc/skel/.inputrc > utils/.inputrc) &
    (cat $RFSCONTENTS/etc/skel/.nanorc > utils/.nanorc) &
    (cat $RFSCONTENTS/etc/skel/.profile > utils/.profile) &
    (cat $RFSCONTENTS/etc/skel/.tmux.conf > utils/.tmux.conf) &
    (cat $RFSCONTENTS/etc/skel/.wgetrc > utils/.wgetrc) &
    (cat $RFSCONTENTS/etc/skel/.xinitrc > utils/.xinitrc) &
    (cat $RFSCONTENTS/etc/skel/.Xresources > utils/.Xresources) &
    wait
    ([[ -d "$RFSCONTENTS/etc/skel/.local/" ]] && rsync -avhc --inplace --delete \
        $RFSCONTENTS/etc/skel/.local/ utils/.local/) &
    ([[ -d "$RFSCONTENTS/etc/skel/.tmux/" ]] && rsync -avhc --delete \
        $RFSCONTENTS/etc/skel/.tmux/ utils/.tmux/) &
    write_scripts
}

extract_debian() {
    mkdir mnt
    [[ -d "utils" ]] || mkdir utils
    [[ -d "$ISOCONTENTS" ]] || mkdir $ISOCONTENTS
    [[ -d "$RFSCONTENTS" ]] || mkdir $RFSCONTENTS
    dd if="$ISONAME" bs=1 count=432 of=utils/"$MBR_FILE"
    mount -o loop $ISONAME mnt
    rsync -avhc --inplace \
        mnt/ ${ISOCONTENTS}/
    find ${ISOCONTENTS}/live -type f -iname "*.squashfs" \
        -exec unsquashfs -p $PROCNUM -f -d $RFSCONTENTS {} \;
    umount mnt
    rm -rf mnt
    # copy certain files to utils
    (cat $RFSCONTENTS/sbin/initctl > utils/initctl) &
    (cat $RFSCONTENTS/etc/skel/.bashrc > utils/.bashrc) &
    (cat $RFSCONTENTS/etc/skel/.bash_misc > utils/.bash_misc) &
    (cat $RFSCONTENTS/etc/skel/.bash_aliases > utils/.bash_aliases) &
    (cat $RFSCONTENTS/etc/skel/.config/dconf/user > utils/user) &
    (cat $RFSCONTENTS/etc/skel/.inputrc > utils/.inputrc) &
    (cat $RFSCONTENTS/etc/skel/.nanorc > utils/.nanorc) &
    (cat $RFSCONTENTS/etc/skel/.profile > utils/.profile) &
    (cat $RFSCONTENTS/etc/skel/.tmux.conf > utils/.tmux.conf) &
    (cat $RFSCONTENTS/etc/skel/.wgetrc > utils/.wgetrc) &
    (cat $RFSCONTENTS/etc/skel/.xinitrc > utils/.xinitrc) &
    (cat $RFSCONTENTS/etc/skel/.Xresources > utils/.Xresources) &
    wait
    ([[ -d "$RFSCONTENTS/etc/skel/.local/" ]] && rsync -avhc --inplace --no-whole-file --delete \
        $RFSCONTENTS/etc/skel/.local/ utils/.local/) &
    ([[ -d "$RFSCONTENTS/etc/skel/.tmux/" ]] && rsync -avhc --inplace --no-whole-file --delete \
        $RFSCONTENTS/etc/skel/.tmux/ utils/.tmux/) &
    write_scripts
}

enterchroot() {
    #get prerequisites if needed
    printf '\nGetting prerequisites...'
    #apt install -y squashfs-tools genisoimage syslinux-utils xorriso
    printf '\nBinding directories...'
    mount --bind /run ${WKDIR}/${RFSCONTENTS}/run
    mount --bind /dev ${WKDIR}/${RFSCONTENTS}/dev
    mount --bind /dev/pts ${WKDIR}/${RFSCONTENTS}/dev/pts
    mount --bind /proc ${WKDIR}/${RFSCONTENTS}/proc
    mount --bind /sys ${WKDIR}/${RFSCONTENTS}/sys
    (cp /etc/hosts $RFSCONTENTS/etc/hosts) &
    (mkdir $RFSCONTENTS/run/systemd/resolve) &
    [[ "$DISTRIBID" == "Debian" ]] || \
    (echo 'nameserver '${CHROOTDNS}'' > $RFSCONTENTS/run/systemd/resolve/resolv.conf) &
    [[ "$DISTRIBID" == "Debian" ]] || \
    (echo 'nameserver '${CHROOTDNS}'' > $RFSCONTENTS/run/systemd/resolve/stub-resolv.conf) &
    [[ "$DISTRIBID" == "Debian" ]] && \
        (echo 'nameserver '${CHROOTDNS}'' > $RFSCONTENTS/etc/resolv.conf) &
    printf '\nChrooting...'
    chroot edit chroot-manager enter
    cd $WKDIR || exit
    umount ${WKDIR}/${RFSCONTENTS}/run
    umount ${WKDIR}/${RFSCONTENTS}/dev/pts
    umount ${WKDIR}/${RFSCONTENTS}/dev
    umount ${WKDIR}/${RFSCONTENTS}/proc
    umount ${WKDIR}/${RFSCONTENTS}/sys
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

make_ubuntu_disk() {
    printf '\nCreate %s.iso!' $NEWISO
    printf '\nJumping above root directory, moving files...\n'
    cleanup
    cd $WKDIR || exit
    mkdir -p $RFSCONTENTS/root/.config/dconf
    mkdir -p $RFSCONTENTS/var/cache/apt/{archives,partial}
    touch $RFSCONTENTS/var/cache/apt/archives/lock
    tee $RFSCONTENTS/etc/skel/.bashrc $RFSCONTENTS/root/.bashrc < utils/.bashrc > /dev/null
    tee $RFSCONTENTS/etc/skel/.bash_misc $RFSCONTENTS/root/.bash_misc < utils/.bash_misc > /dev/null
    tee $RFSCONTENTS/etc/skel/.bash_aliases $RFSCONTENTS/root/.bash_aliases < utils/.bash_aliases > /dev/null
    tee $RFSCONTENTS/etc/skel/.profile $RFSCONTENTS/root/.profile < utils/.profile > /dev/null
    tee $RFSCONTENTS/etc/skel/.xinitrc $RFSCONTENTS/root/.xinitrc < utils/.xinitrc > /dev/null
    tee $RFSCONTENTS/etc/skel/.Xresources $RFSCONTENTS/root/.Xresources < utils/.Xresources > /dev/null
    tee $RFSCONTENTS/etc/skel/.nanorc $RFSCONTENTS/root/.nanorc < utils/.nanorc > /dev/null
    tee $RFSCONTENTS/etc/skel/.wgetrc $RFSCONTENTS/root/.wgetrc < utils/.wgetrc > /dev/null
    tee $RFSCONTENTS/etc/skel/.inputrc $RFSCONTENTS/root/.inputrc < utils/.inputrc > /dev/null
    tee $RFSCONTENTS/etc/skel/.fzf.bash $RFSCONTENTS/root/.fzf.bash < utils/.fzf.bash > /dev/null
    tee $RFSCONTENTS/etc/skel/.tmux.conf $RFSCONTENTS/root/.tmux.conf < utils/.tmux.conf > /dev/null
    cp -f utils/initctl $RFSCONTENTS/sbin/initctl
    (rsync -avhc --inplace --delete \
        $RFSCONTENTS/etc/xdg/nvim/ $RFSCONTENTS/root/.config/nvim/) &
    (rsync -avhc --inplace --delete \
        $RFSCONTENTS/etc/skel/.config/dconf/ $RFSCONTENTS/root/.config/dconf/) &
    (rsync -avhc --inplace --delete \
        $RFSCONTENTS/etc/skel/.config/rofi/ $RFSCONTENTS/root/.config/rofi/) &
    (rsync -avhc --inplace --delete \
        $RFSCONTENTS/etc/skel/.config/gtk-3.0/ $RFSCONTENTS/root/.config/gtk-3.0/) &
    (rsync -avhc --inplace --delete \
        $RFSCONTENTS/etc/skel/.config/gtk-4.0/ $RFSCONTENTS/root/.config/gtk-4.0/) &
    (rsync -avhc --inplace --delete \
        $RFSCONTENTS/etc/skel/.config/qt5ct/ $RFSCONTENTS/root/.config/qt5ct/) &
    (rsync -avhc --inplace --delete \
        $RFSCONTENTS/etc/skel/.tmux/ $RFSCONTENTS/root/.tmux/) &
    (fd . $RFSCONTENTS/usr/local/share/html/ \
        -tf -e html -x sed -i "s|<p>Version: .*; Release Date: .*</p>|<p>Version: ${VERSION}; Release Date: ${RELEASEDATE}</p>|") &
    wait

cd $WKDIR || exit
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

(echo -e ${DISTRONAME}' '${VERSION}' \\n \\l\n' > $RFSCONTENTS/etc/issue) &

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

case "$UBUAGE" in
    old)
        (echo -e '#define DISKNAME  '${DISTRONAME}' '${VERSION}'
#define TYPE  binary
#define TYPEbinary  1
#define ARCH  amd64
#define ARCHamd64  1
#define DISKNUM  1
#define DISKNUM1  1
#define TOTALNUM  0
#define TOTALNUM0  1' > $ISOCONTENTS/README.diskdefines) &
    ;;
esac

(echo -e ${ISOINFO} > $ISOCONTENTS/.disk/info) &

(echo -e ${DISTROURL} > $ISOCONTENTS/.disk/release_notes_url) &

#regenerate manifest
printf '\nRegenerating manifest...'
chmod +w $ISOCONTENTS/casper/filesystem.manifest;
chroot edit dpkg-query -W --showformat='${Package} ${Version}\n' | \
    tee $ISOCONTENTS/casper/filesystem.manifest $NEWISO-build.log

case "$UBUAGE" in
    old)
        cp $ISOCONTENTS/casper/filesystem.manifest $ISOCONTENTS/casper/filesystem.manifest-desktop;
        sed -i '/ubiquity/d;
                /casper/d;
                /discover/d;
                /laptop-detect/d;
                /os-prober/d' $ISOCONTENTS/casper/filesystem.manifest-desktop
        ;;
esac

#compress filesystem
printf '\nCompressing filesystem for %s.iso...\n' $NEWISO
rm $ISOCONTENTS/casper/filesystem.squashfs
mksquashfs $RFSCONTENTS $ISOCONTENTS/casper/filesystem.squashfs \
    -comp xz \
    -b 1048576 \
    -processors $PROCNUM
echo -e $(du -sx --block-size=1 edit | cut -f1) | \
    tee $ISOCONTENTS/casper/filesystem.size

#update checksums
(cd $ISOCONTENTS
printf '\nUpdating sha512 sums...'
echo "The file sha512sum.txt contains the sha512 checksums of all files on this medium.

You can verify them automatically with the 'verify-checksums' boot parameter,
or, manually with: 'sha512sum -c sha512sum.txt'." > sha512sum.README
rm md5sum.txt MD5SUMS sha256sum.txt sha512sum.txt
grep -v isolinux/boot.cat <(fd -tf -x sha512sum) | \
    tee sha512sum.txt ../$NEWISO-build.log 2>&1)

cd $WKDIR || exit
#remove the old iso file
printf '\nIf exists, delete the old %s.iso...\n' $NEWISO
[[ -f "$NEWISO.iso" ]] && rm -f $NEWISO.iso

#create iso image
printf '\nCreating %s.iso...\n' $NEWISO
# do not change the order of the xorriso options
# do not remove repeated xorriso options
case "$UBUAGE" in
    zero)
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
            -c '/isolinux/boot.cat' \
            -b '/isolinux/isolinux.bin' \
            -no-emul-boot \
            -boot-load-size 4 \
            -boot-info-table \
            --grub2-boot-info \
            -eltorito-alt-boot \
            -e '--interval:appended_partition_2:::' \
            -no-emul-boot \
            $ISOCONTENTS | tee -a $NEWISO-build.log 2>&1
        ;;
    new)
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
            $ISOCONTENTS | tee -a $NEWISO-build.log 2>&1
        ;;
        old)
            xorrisofs -v \
            -J -J -joliet-long \
            -full-iso9660-filenames \
            -input-charset utf-8 \
            -rational-rock \
            -volset "$FLAVOUR$VERSION-$ARCH" \
            -volid "$FLAVOUR$VERSION-$ARCH" \
            -o $NEWISO.iso \
            -isohybrid-mbr utils/$MBR_FILE \
            -eltorito-boot /isolinux/isolinux.bin \
            -eltorito-catalog /isolinux/boot.cat \
            -no-emul-boot \
            -boot-load-size 4 \
            -boot-info-table \
            -eltorito-alt-boot \
            -e /boot/grub/efi.img \
            -no-emul-boot \
            -isohybrid-gpt-basdat \
            $ISOCONTENTS | tee -a $NEWISO-build.log 2>&1
        ;;
esac

    # log iso information
    echo -e '\nComputing the SHA256 sum:' | tee -a $NEWISO-build.log 2>&1
    sha256sum $NEWISO.iso | tee -a $NEWISO-build.log 2>&1
    echo -e '\nBoot record information:'
    fdisk -lu $NEWISO.iso | tee -a $NEWISO-build.log 2>&1
    echo -e 'Boot catalog and image paths:'
    xorriso -indev $NEWISO.iso -toc -pvd_info | tee -a $NEWISO-build.log 2>&1
    echo -e '\n'${NEWISO}' creation finished'
}

make_debian_disk() {
    printf '\nCreate %s.iso!' $NEWISO
    printf '\nJumping above root directory, moving files...\n'
    cleanup
    cd $WKDIR || exit
    mkdir -p $RFSCONTENTS/root/.config/dconf
    mkdir -p $RFSCONTENTS/var/cache/apt/{archives,partial}
    touch $RFSCONTENTS/var/cache/apt/archives/lock
    tee $RFSCONTENTS/etc/skel/.bashrc $RFSCONTENTS/root/.bashrc < utils/.bashrc > /dev/null
    tee $RFSCONTENTS/etc/skel/.bash_misc $RFSCONTENTS/root/.bash_misc < utils/.bash_misc > /dev/null
    tee $RFSCONTENTS/etc/skel/.bash_aliases $RFSCONTENTS/root/.bash_aliases < utils/.bash_aliases > /dev/null
    tee $RFSCONTENTS/etc/skel/.profile $RFSCONTENTS/root/.profile < utils/.profile > /dev/null
    tee $RFSCONTENTS/etc/skel/.xinitrc $RFSCONTENTS/root/.xinitrc < utils/.xinitrc > /dev/null
    tee $RFSCONTENTS/etc/skel/.Xresources $RFSCONTENTS/root/.Xresources < utils/.Xresources > /dev/null
    tee $RFSCONTENTS/etc/skel/.nanorc $RFSCONTENTS/root/.nanorc < utils/.nanorc > /dev/null
    tee $RFSCONTENTS/etc/skel/.wgetrc $RFSCONTENTS/root/.wgetrc < utils/.wgetrc > /dev/null
    tee $RFSCONTENTS/etc/skel/.inputrc $RFSCONTENTS/root/.inputrc < utils/.inputrc > /dev/null
    tee $RFSCONTENTS/etc/skel/.fzf.bash $RFSCONTENTS/root/.fzf.bash < utils/.fzf.bash > /dev/null
    tee $RFSCONTENTS/etc/skel/.tmux.conf $RFSCONTENTS/root/.tmux.conf < utils/.tmux.conf > /dev/null
    cp -f utils/initctl $RFSCONTENTS/sbin/initctl
    (rsync -avhc --inplace --delete \
        $RFSCONTENTS/etc/xdg/nvim/ $RFSCONTENTS/root/.config/nvim/) &
    (rsync -avhc --inplace --delete \
        $RFSCONTENTS/etc/skel/.config/dconf/ $RFSCONTENTS/root/.config/dconf/) &
    (rsync -avhc --inplace --delete \
        $RFSCONTENTS/etc/skel/.config/rofi/ $RFSCONTENTS/root/.config/rofi/) &
    (rsync -avhc --inplace --delete \
        $RFSCONTENTS/etc/skel/.config/gtk-3.0/ $RFSCONTENTS/root/.config/gtk-3.0/) &
    (rsync -avhc --inplace --delete \
        $RFSCONTENTS/etc/skel/.config/gtk-4.0/ $RFSCONTENTS/root/.config/gtk-4.0/) &
    (rsync -avhc --inplace --delete \
        $RFSCONTENTS/etc/skel/.config/qt5ct/ $RFSCONTENTS/root/.config/qt5ct/) &
    (rsync -avhc --inplace --delete \
        $RFSCONTENTS/etc/skel/.tmux/ $RFSCONTENTS/root/.tmux/) &
    (fd . $RFSCONTENTS/usr/local/share/html/ \
        -tf -e html -x sed -i "s|<p>Version: .*; Release Date: .*</p>|<p>Version: ${VERSION}; Release Date: ${RELEASEDATE}</p>|") &
    wait

cd $WKDIR || exit
#set distro identity
printf '\nSetting distro identity...'

(echo -e '
## live-config has got the impression it should reset xfce4-panel's settings, after we've set them.
LIVE_CONFIG_NOCOMPONENTS=xfce4-panel
## Set our user and host names.
LIVE_HOSTNAME='${HOST}'
LIVE_USERNAME='${USERNAME}'
LIVE_USER_FULLNAME="Debian live user"' > $RFSCONTENTS/etc/live/config.conf) &

(echo -e ${DISTRONAME}' '${VERSION}' \\n \\l\n' > $RFSCONTENTS/etc/issue) &

(echo -e ${DISTRONAME}' '${VERSION}'' > $RFSCONTENTS/etc/issue.net) &

(echo -e '
The programs included with the '${DISTRONAME}' system are free software;
the exact distribution terms for each program are described in the
individual files in /usr/share/doc/*/copyright.

'${DISTRONAME}' comes with ABSOLUTELY NO WARRANTY, to the extent permitted by
applicable law.' > $RFSCONTENTS/etc/legal) &

# VERSION_CODENAME must be either MINTCODE or UBUCODE
(echo -e 'PRETTY_NAME="'${DISTRONAME}' '${VERSION}' ('${UBUCODE}')"
NAME="'${DISTRONAME}'"
VERSION_ID="'${VERSION}'"
VERSION="'${VERSION}'"
VERSION_CODENAME="'${UBUCODE}'"
ID=debian
ID_LIKE=debian
HOME_URL="'${DISTROURL}'"
SUPPORT_URL="'${DISTROURL}'"
BUG_REPORT_URL="'${DISTROURL}'"
PRIVACY_POLICY_URL="'${DISTROURL}'"' > $RFSCONTENTS/usr/lib/os-release) &

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
wait

#compress filesystem
printf '\nCompressing filesystem for %s.iso...\n' $NEWISO
rm $ISOCONTENTS/live/filesystem.squashfs
mksquashfs $RFSCONTENTS $ISOCONTENTS/live/filesystem.squashfs \
    -comp xz \
    -b 1048576 \
    -processors $PROCNUM
# echo -e $(du -sx --block-size=1 edit | cut -f1) | \
#    tee $ISOCONTENTS/live/filesystem.size

#update checksums
(cd $ISOCONTENTS
printf '\nUpdating sha512 sums...'
echo "The file sha512sum.txt contains the sha512 checksums of all files on this medium.

You can verify them automatically with the 'verify-checksums' boot parameter,
or, manually with: 'sha512sum -c sha512sum.txt'." > sha512sum.README
rm md5sum.txt MD5SUMS sha256sum.txt sha512sum.txt
grep -v isolinux/boot.cat <(fd -tf -x sha512sum) | \
    tee sha512sum.txt ../$NEWISO-build.log 2>&1)

cd $WKDIR || exit
#remove the old iso file
printf '\nIf exists, delete the old %s.iso...\n' $NEWISO
[[ -f "$NEWISO.iso" ]] && rm -f $NEWISO.iso

#create iso image
printf '\nCreating %s.iso...\n' $NEWISO
# do not change the order of the xorriso options
# do not remove repeated xorriso options

xorrisofs -v \
    -R -r -J -joliet-long \
    -full-iso9660-filenames \
    -cache-inodes \
    -iso-level 3 \
    -isohybrid-mbr utils/$MBR_FILE \
    -partition_offset 16 \
    -A "$ISOCONTENTS" \
    -p "$DISTROURL" \
    -publisher "$DISTROURL" \
    -V "$DISTRONAME-$BUILDDATE" \
    -b isolinux/isolinux.bin \
    -c isolinux/boot.cat \
    -no-emul-boot \
    -boot-load-size 4 \
    -boot-info-table \
    -eltorito-alt-boot \
    -e boot/grub/efi.img \
    -no-emul-boot \
    -isohybrid-gpt-basdat \
    -isohybrid-apm-hfsplus \
    -o $NEWISO.iso \
     $ISOCONTENTS | tee -a $NEWISO-build.log 2>&1

    # log iso information
    echo -e '\nComputing the SHA256 sum:' | tee -a $NEWISO-build.log 2>&1
    sha256sum $NEWISO.iso | tee -a $NEWISO-build.log 2>&1
    echo -e '\nBoot record information:'
    fdisk -lu $NEWISO.iso | tee -a $NEWISO-build.log 2>&1
    echo -e 'Boot catalog and image paths:'
    xorriso -indev $NEWISO.iso -toc -pvd_info | tee -a $NEWISO-build.log 2>&1
    echo -e '\n'${NEWISO}' creation finished'
}

write_scripts() {
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
    nala clean
    vers=(8 9 10 11 12)
    for ver in "${vers[@]}";do
        python3."$ver" -m pip cache purge
    done
    printf "\nExiting chroot...\n"
    umount /run
    umount /proc || umount -lf /proc
    umount /sys
    umount /dev
    umount /dev/pts
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
# make script copy "initrd.img" for Debian isos
[[ "$DISTRIBID" == "Debian" ]] && sed -i 's|~/initrd|initrd.img|' $RFSCONTENTS/usr/sbin/build-bootfiles
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
    cd $WKDIR || exit
    printf '\nCleaning up...\n'
    umount $RFSCONTENTS/dev
    (chown -R man:root $RFSCONTENTS/var/cache/man) &
    (fd -H -e TBL . "$ISOCONTENTS" -x rm) &
    (fd -H -e txt -e conf -e db -e md -e html . "$RFSCONTENTS/usr/local" -x chmod 666) &
    (fd -H -e py -e sh . "$RFSCONTENTS/usr/local/sbin" -x chmod 755) &
    (fd -H -tf . "$RFSCONTENTS/usr/local/etc" -x chmod 666) &
    (fd -H -e db -e TAG . "$RFSCONTENTS/var/cache" -x chmod 664) &
    (fd -H -td . "$RFSCONTENTS/var/log" -x chmod 755) &
    (fd -H -tf . "$ISOCONTENTS/isolinux" -x chmod 644) &
    (fd -H -e save . "$RFSCONTENTS/etc/apt/sources.list.d" -x rm) &
    [[ "$DISTRIBID" == "Debian" ]] || (fd -H -tf . "$RFSCONTENTS/var/crash" -x rm) &
    (fd -H -tf . "$RFSCONTENTS/var/lib/apt" -x rm) &
    (fd -H -tf . "$RFSCONTENTS/var/log" -x rm) &
    (fd -H -tf . "$RFSCONTENTS/var/tmp" -x rm) &
    (fd -H -e dpkg-old -e dpkg-dist . "$RFSCONTENTS" -x rm) &
    (fd -H -tf . "$RFSCONTENTS/tmp" -x rm) &
    (fd -H . "$RFSCONTENTS/home" -x rm -rf) &
    (fd -H . "$RFSCONTENTS/root" -x rm -rf) &
    (fd -H . "$RFSCONTENTS/tmp" -x rm -rf) &
    printf '\nSetting some permissions...\n'
    (chmod 4755 $RFSCONTENTS/usr/bin/pkexec) &
    (chmod 4755 $RFSCONTENTS/usr/bin/sudo) &
    (chown root:messagebus $RFSCONTENTS/usr/lib/dbus-1.0/dbus-daemon-launch-helper) &
    (chmod u+s $RFSCONTENTS/usr/lib/dbus-1.0/dbus-daemon-launch-helper) &
    printf 'Waiting to finish cleanup and permissions...\n'
    wait
}

makebackup(){
    echo -e '\nCopying '${NEWISO}'.iso to '${NEWISO}'.bak.iso...\n'
    cp -fp $NEWISO.iso $NEWISO.bak.iso
    echo -e '\nBackup job complete...'
}


case "$1" in
    chroot)
        enterchroot
        ;;
    makedisk)
        [[ "$DISTRIBID" == "Debian" ]] && make_debian_disk
        [[ "$DISTRIBID" == "Ubuntu" ]] && make_ubuntu_disk
        [[ "$DISTRIBID" == "LinuxMint" ]] && make_ubuntu_disk
        ;;
    backup)
        makebackup
        ;;
    extractiso)
        [[ "$DISTRIBID" == "Debian" ]] && extract_debian
        [[ "$DISTRIBID" == "Ubuntu" ]] && extract_ubuntu
        [[ "$DISTRIBID" == "LinuxMint" ]] && extract_ubuntu
        ;;
    extractinit)
        extractinitrd
        ;;
    repackinit)
        repackinitrd
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
    cleanup     clean cruft and set permissions in the iso filesystem

        " >&2
        exit 3
        ;;
esac
