#!/bin/bash
# Place this script one level above the directories containing the distro files.
# Run the working system from a separate drive / sdcard / flashdrive...
username="$(logname)"
# Partition holding distro files
partition='MEDIA_2'
# list of directories holding linux projects
dirs='alphabird catbird mofolinux rockdove skywavelinux-gnome skywavelinux-i3wm starling'
#dirs='starling'
#dirs='bluejay starling'
# path and filename of source file or directory
#OBJECT0=/root/radiostreams
#OBJECT1=/root/Desktop/selenized.vim
#OBJECT2=/usr/local/sbin/networkmanager_dmenu/root/Desktop
#OBJECT3=/etc/i3status.conf/root/Desktop
#COMMAND2="chown root:root $SOURCE_OBJECT1"
# a group of files to copy to each system to the same folder
group=""
group2=""
group3=""
dtops=""
dotties=""
scripts=""
#
for project in $dirs; do
echo -e "\nWorking in ${project}... \n"

## Massive fix for Neovim
#  rsync -avhc --inplace /home/user/.config/nvim/init.lua /media/${username}/${partition}/distros/${project}/edit/etc/skel/.config/nvim/init.lua
#  rsync -avhc --inplace /home/user/.config/nvim/init.lua /media/${username}/${partition}/distros/${project}/livecd-setup/apps/neovim/skel/.config/nvim/init.lua
#  rsync -avhc --inplace /home/user/.config/nvim/lua/colors.lua /media/${username}/${partition}/distros/${project}/edit/etc/skel/.config/nvim/lua/colors.lua
#  rsync -avhc --inplace /home/user/.config/nvim/lua/colors.lua /media/${username}/${partition}/distros/${project}/livecd-setup/apps/neovim/skel/.config/nvim/lua/colors.lua
#  rsync -avhc --inplace /home/user/.config/nvim/lua/basic.lua /media/${username}/${partition}/distros/${project}/edit/etc/skel/.config/nvim/lua/basic.lua
#  rsync -avhc --inplace /home/user/.config/nvim/lua/basic.lua /media/${username}/${partition}/distros/${project}/livecd-setup/apps/neovim/skel/.config/nvim/lua/basic.lua
#
#  rsync -avhc --inplace /root/.config/nvim/init.lua /media/${username}/${partition}/distros/${project}/utils/nvim-root/init.lua
#  rsync -avhc --inplace /root/.config/nvim/init.lua /media/${username}/${partition}/distros/${project}/edit/root/.config/nvim/init.lua
#  rsync -avhc --inplace /root/.config/nvim/init.lua /media/${username}/${partition}/distros/${project}/livecd-setup/apps/neovim/nvim-root/init.lua
#  rsync -avhc --inplace /root/.config/nvim/lua/basic.lua /media/${username}/${partition}/distros/${project}/utils/nvim-root/lua/basic.lua
#  rsync -avhc --inplace /root/.config/nvim/lua/basic.lua /media/${username}/${partition}/distros/${project}/edit/root/.config/nvim/lua/basic.lua
#  rsync -avhc --inplace /root/.config/nvim/lua/basic.lua /media/${username}/${partition}/distros/${project}/livecd-setup/apps/neovim/nvim-root/lua/basic.lua
#
#  rsync -avhc --inplace /root/.config/nvim/lua/colors.lua /media/${username}/${partition}/distros/${project}/utils/nvim-root/lua/colors.lua
#  rsync -avhc --inplace /root/.config/nvim/lua/colors.lua /media/${username}/${partition}/distros/${project}/edit/root/.config/nvim/lua/colors.lua
#  rsync -avhc --inplace /root/.config/nvim/lua/colors.lua /media/${username}/${partition}/distros/${project}/livecd-setup/apps/neovim/nvim-root/lua/colors.lua
#
#   #
#   # copy some scripts into the projects' sbin directories
#   for script in $scripts;do
#      cp /root/${script} \
#      /media/${username}/${partition}/distros/${project}/edit/usr/local/sbin/${script}
#      cp /root/${script} \
#      /media/${username}/${partition}/distros/${project}/livecd-setup/apps/scripts-testing/${script}
#   done
#
#   for launcher in $dtops;do
#      cp /root/${launcher} \
#      /media/$username/$partition/distros/$project/edit/etc/skel/.local/share/applications/${launcher}
#      cp /root/${launcher} \
#      /media/$username/$partition/distros/$project/utils/.local/share/applications/${launcher}
#      cp /root/${launcher} \
#      /media/$username/$partition/distros/$project/livecd-setup/apps/launchers/${launcher}
#   done
#
#    rm  /media/${username}/${partition}/distros/${project}/edit/usr/local/sbin/dl_vpngate.py
#    rm  /media/${username}/${partition}/distros/${project}/livecd-setup/apps/scripts-testing/dl_vpngate.py
#
#
#   for file in $dotties;do
#      cp /root/${file} \
#      /media/$username/$partition/distros/$project/edit/etc/skel/${file}
#      cp /root/${file} \
#      /media/$username/$partition/distros/$project/utils/${file}
#      cp /root/${file} \
#      /media/$username/$partition/distros/$project/livecd-setup/apps/dotfiles/${file}
#   done
#
#   # copy some files into the projects' various directories
#   for file in $group;do
#      cp /root/${file} \
#      /media/${username}/${partition}/distros/${project}/edit/etc/skel/.config/${file}
#   done
#
#   # copy a working script into the distros
#   myworkingscripts="sshuttle-controller tor-remote"
#   for workingscript in $myworkingscripts;do
#      cp /usr/local/sbin/${workingscript} \
#      /media/${username}/${partition}/distros/${project}/edit/usr/local/sbin/${workingscript}
#      cp /usr/local/sbin/${workingscript} \
#      /media/${username}/${partition}/distros/${project}/livecd-setup/apps/scripts-testing/${workingscript}
#   done
#
#   # fix permissions...
#   for file in $group;do
#      chmod 755 /media/${username}/${partition}/distros/${project}/edit/usr/local/sbin/${file}
#      chmod +x /media/${username}/${partition}/distros/${project}/livecd-setup/apps/scripts-testing/${file}
#   done
#
#   move files
#    mv /media/${username}/${partition}/distros/${project}/edit/etc/skel/Music/radiostreams \
#        /media/${username}/${partition}/distros/${project}/edit/etc/skel/.config/radiostreams
#    mv /media/${username}/${partition}/distros/${project}/edit/etc/skel/Music/sdr-stream-bookmarks \
#        /media/${username}/${partition}/distros/${project}/edit/etc/skel/.config/sdr-stream-bookmarks
#    mv /media/${username}/${partition}/distros/${project}/edit/etc/skel/Documents/tw_alltopics \
#        /media/${username}/${partition}/distros/${project}/edit/etc/skel/.config/tw_alltopics
#
#     rm /media/${username}/${partition}/distros/${project}/edit/usr/share/applications/software-properties-gtk.desktop
#     rm /media/${username}/${partition}/distros/${project}/edit/usr/share/applications/software-properties-livepatch.desktop
#
#   # move some files to the another folder
#   for file in $group2;do
#      cp /root/${file} \
#      /media/${username}/${partition}/distros/${project}/edit/etc/skel/.config/${file}
#   done
#   #
#     cp /root/run-rofi /media/${username}/${partition}/distros/${project}/edit/usr/sbin/run-rofi
#     cp /root/run-rofi /media/${username}/${partition}/distros/${project}/livecd-setup/apps/scripts-testing/run-rofi
#     cp /root/run-rofi /media/${username}/${partition}/distros/${project}/livecd-setup/apps/rofi/run-rofi
#     cp /root/config.rasi /media/${username}/${partition}/distros/${project}/edit/etc/skel/.config/rofi/config.rasi
#      chown root:root /media/${username}/${partition}/distros/${project}/edit/etc/skel/.config/rofi/config.rasi
#
#   # move some files to the another folder
#   for file in $group3;do
#      cp /root/${file} \
#      /media/${username}/${partition}/distros/${project}/edit/etc/skel/Music/${file}
#   done
#   # copy some files to somewhere
#   for file in $group;do
#      cp /root/${file} \
#      /media/${username}/${partition}/distros/${project}/edit/usr/sbin/${file}
#   done
#
#     file="sdr-stream"
#     cp /root/"$file" \
#     /media/${username}/${partition}/distros/${project}/edit/usr/local/sbin/"$file"
#
#     file="sdr-stream-bookmarks"
#     cp /root/"$file" \
#     /media/${username}/${partition}/distros/${project}/edit/etc/skel/.config/"$file"
#
#     file=""
#     cp /root/"$file" \
#     /media/${username}/${partition}/distros/${project}/edit/etc/skel/.config/"$file"
#
#   # create a directory for root nvim config
#   mkdir /media/${username}/${partition}/distros/${project}/utils/nvim-root
#   rsync -avhc --inplace --delete \
#   /media/$username/$partition/distros/$project/livecd-setup/apps/neovim/nvim-root/ \
#   /media/${username}/${partition}/distros/${project}/utils/nvim-root/
#
# rsync directories
#   rsync -avhc --inplace --delete \
#      /usr/local/src/dyatlov/ \
#      /media/${username}/${partition}/distros/${project}/edit/usr/local/src/dyatlov/
#
#   rsync -avhc --inplace --delete \
#      /usr/local/src/ccat/ \
#      /media/${username}/${partition}/distros/${project}/edit/usr/local/src/ccat/
#
#   rsync -avhc --inplace --delete \
#      /root/plugins/ \
#      /media/${username}/${partition}/distros/${project}/edit/etc/skel/.tmux/plugins/
#
#   rsync -avhc --inplace --delete \
#      /usr/local/sbin/ventoy/ \
#      /media/${username}/${partition}/distros/${project}/edit/usr/local/sbin/ventoy/
#
#   rsync -avhc --inplace --delete \
#      /usr/local/sbin/ventoy/ \
#      /media/${username}/${partition}/distros/${project}/livecd-setup/apps/ventoy/
#
#   rsync -avhc --inplace --delete \
#      /etc/xdg/nvim/ \
#      /media/$username/$partition/distros/$project/edit/etc/xdg/nvim/
#   rsync -avhc --inplace --delete \
#      /etc/xdg/nvim/ \
#      /media/$username/$partition/distros/$project/livecd-setup/apps/neovim/nvim-root/
#
#   rsync -avhc --inplace --delete \
#      /usr/lib/surfraw/ \
#      /media/$username/$partition/distros/$project/edit/usr/lib/surfraw/
#
#   rsync -avhc --inplace --delete \
#      /usr/share/fonts/truetype/NeonGlow \
#      /media/$username/$partition/distros/$project/edit/usr/share/fonts/truetype/NeonGlow
#
# rsync then copy a symlink, preserving its attributes
#   rsync -avhc --inplace --delete \
#      /usr/local/src/lazygit/ \
#      /media/$username/$partition/distros/$project/edit/usr/local/src/lazygit/
#   cp -a /usr/local/bin/lazygit /media/$username/$partition/distros/$project/edit/usr/local/bin/lazygit
#
# Backup working neovims to the livecd-setup archives
#   rsync -avhc --inplace --delete \
#   /media/$username/$partition/distros/$project/edit/opt/nvim/ \
#   /media/$username/$partition/distros/$project/livecd-setup/apps/neovim/nvim/
#   chown -R root:root /media/$username/$partition/distros/$project/livecd-setup/apps/neovim/nvim
#
# edit files
#   echo '$exe source ~/.xinitrc' >> /media/$username/$partition/distros/$project/livecd-setup/apps/i3/etc/i3/config
#   echo '$exe source ~/.xinitrc' >> /media/$username/$partition/distros/$project/livecd-setup/apps/i3/etc/skel/.config/i3/config
#   echo '$exe source ~/.xinitrc' >> /media/$username/$partition/distros/$project/backup/etc/i3/config
#   echo '$exe source ~/.xinitrc' >> /media/$username/$partition/distros/$project/backup/etc/skel/.config/i3/config
#   echo '$exe source ~/.xinitrc' >> /media/$username/$partition/distros/$project/edit/etc/i3/config
#   echo '$exe source ~/.xinitrc' >> /media/$username/$partition/distros/$project/edit/etc/skel/root/Desktop.config/i3/config
#   echo '' > /media/$username/$partition/distros/$project/backup/etc/skel/.config/sshuttle/sshu/root/Desktopttle.conf
#   echo '' > /media/$username/$partition/distros/$project/backup/etc/skel/.config/sshuttle/sshuttle.conf
#   echo '' > /media/$username/$partition/distros/$project/backup/etc/skel/.config/sshuttle/sshuttle.conf
#   cd /media/$username/$partition/distros/$project/utils/.local/share/applications
#   sed -i 's/" connected "/" connected primary "/g' .xinitrc/root/Desktop
#   cd /media/$username/$partition/distros/$project/utils//root/Desktop
#   sed -i 's/" connected "/" connected primary "/g' .xinitrc
#
#   sed -i "s/alias usb-creator='/alias usb-creator='sudo /g" \
#   /media/$username/$partition/distros/$project/livecd-setup/apps/dotfiles/.bash_aliases
#
#   sed -i "s/alias usb-creator='/alias usb-creator='sudo /g" \
#   /media/$username/$partition/distros/$project/utils/.bash_aliases
#
#   sed -i "s/alias usb-creator='/alias usb-creator='sudo /g" \
#   /media/$username/$partition/distros/$project/backup/etc/skel/.bash_aliases
#
#   sed -i "s/alias usb-creator='/alias usb-creator='sudo /g" \
#   /media/$username/$partition/distros/$project/edit/etc/skel/.bash_aliases
#
# Copy a dotfile into the distro backup:
#   cp /media/$username/$partition/distros/$project/utils/.bash_aliases \
#   /media/$username/$partition/distros/$project/livecd-setup/apps/dotfiles/.bash_aliases
#
# change permissions and edit a file
#   cd /media/$username/$partition/distros/$project/livecd-setup/apps/neovim/colors; chown root:root *; chmod 644 *
#   sed -i 's/background_color = "151515"/background_color = "000000"/g' jellybeans.vim
#   cd /media/$username/$partition/distros/$project/backup/usr/share/nvim/runtime/colors; chown root:root *; chmod 644 *
#   sed -i 's/background_color = "151515"/background_color = "000000"/g' jellybeans.vim
#   cd /media/$username/$partition/distros/$project/edit/usr/share/nvim/runtime/colors; chown root:root *; chmod 644 *
#   sed -i 's/background_color = "151515"/background_color = "000000"/g' jellybeans.vim
# make directories
#   mkdir -p /media/$username/$partition/distros/$project/backup/etc/xdg/nvim
#   mkdir -p /media/$username/$partition/distros/$project/edit/etc/xdg/nvim
#
# remove directories
#
#   rm -rf /media/$username/$partition/distros/$project/edit/etc/xdg/nvim
#   rm -rf /media/$username/$partition/distros/$project/edit/var/lib/lightdm
#   rm -rf /media/$username/$partition/distros/$project/backup/opt/nvim/plugged/asyncomplete-emmet.vim
#   rm -rf /media/$username/$partition/distros/$project/edit/opt/nvim/plugged/asyncomplete-emmet.vim
#   rm -rf /media/$username/$partition/distros/$project/livecd-setup/apps/neovim/nvim/plugged/asyncomplete-emmet.vim
#
#   rm -rf /media/$username/$partition/distros/$project/backup/opt/nvim/plugged/asyncomplete-gocode.vim
#   rm -rf /media/$username/$partition/distros/$project/edit/opt/nvim/plugged/asyncomplete-gocode.vim
#   rm -rf /media/$username/$partition/distros/$project/livecd-setup/apps/neovim/nvim/plugged/asyncomplete-gocode.vim
#
# delete apps
#   rm /media/$username/$partition/distros/$project/utils/.local/share/applications/ssh.desktop
#   rm /media/$username/$partition/distros/$project/edit/etc/skel/.local/share/applications/ssh.desktop
#   rm /media/$username/$partition/distros/$project/edit/usr/local/sbin/ezssh
#
# copy files
#   cp /etc/systemd/system/startup-items.service \
#   /media/$username/$partition/distros/$project/edit/etc/systemd/system/startup-items.service
#
#   cp /root/chroot-manager \
#   /media/$username/$partition/distros/$project/edit/usr/sbin/chroot-manager
#   cp /root/chroot-manager \
#   /media/$username/$partition/distros/$project/livecd-setup/apps/scripts-testing/chroot-manager
#
#
# replace directory contents
#   rm -rf /media/$username/$partition/distros/$project/edit/usr/local/sbin/ventoy/*
#   cp -r /usr/local/sbin/ventoy/* \
#   /media/$username/$partition/distros/$project/edit/usr/local/sbin/ventoy/
#
# copy, rsync, or move files or directories
#
#   cp /etc/chrony/chrony.conf \
#   /media/$username/$partition/distros/$project/edit/etc/chrony/chrony.conf
#
#   rsync -avhc --delete --inplace \
#   /root/aria2/ \
#   /media/$username/$partition/distros/$project/edit/etc/skel/.config/aria2/
#   rsync -avhc --delete --inplace \
#   /root/aria2/ \
#   /media/$username/$partition/distros/$project/livecd-setup/apps/aria2/
#
#   chown root:root /root/aria2.conf
#   cp /root/aria2.conf \
#   /media/$username/$partition/distros/$project/edit/etc/skel/.config/aria2/aria2.conf
#   cp /root/aria2.conf \
#   /media/$username/$partition/distros/$project/livecd-setup/apps/aria2/aria2.conf
#
#   mkdir -p /media/$username/$partition/distros/$project/edit/etc/skel/.config/aria2p
#   mkdir -p /media/$username/$partition/distros/$project/livecd-setup/apps/aria2p
#
#   rsync -avhc --delete --inplace \
#   /root/aria2p/ \
#   /media/$username/$partition/distros/$project/edit/etc/skel/.config/aria2p/
#   rsync -avhc --delete --inplace \
#   /root/aria2p/ \
#   /media/$username/$partition/distros/$project/livecd-setup/apps/aria2p/
#
# rsync themes and icons
#   rsync -avhc --delete --inplace \
#       /usr/share/themes/Obsidian-2/ \
#       /media/$username/$partition/distros/$project/edit/usr/share/themes/Obsidian-2/
#
#   rsync -avhc --delete --inplace \
#       /usr/share/icons/Obsidian/ \
#       /media/$username/$partition/distros/$project/edit/usr/share/icons/Obsidian/
#
#   rsync -avhc --delete --inplace \
#       /usr/share/icons/Obsidian-Aqua/ \
#       /media/$username/$partition/distros/$project/edit/usr/share/icons/Obsidian-Aqua/
#
#
#   rsync -avhc --delete --inplace \
#       /media/user/MEDIA_2/distros/catbird/livecd-setup/themes/iconpack-obsidian/ \
#       /media/$username/$partition/distros/$project/livecd-setup/themes/iconpack-obsidian/
#
#   rsync -avhc --delete --inplace \
#       /media/user/MEDIA_2/distros/catbird/livecd-setup/themes/theme-obsidian-2/ \
#       /media/$username/$partition/distros/$project/livecd-setup/themes/theme-obsidian-2/
#
#   cp /root/linux-clone \
#   /media/$username/$partition/distros/$project/edit/usr/local/sbin/linux-clone
#
#   cp /root/globe-icon.png \
#   /media/$username/$partition/distros/$project/edit/usr/share/pixmaps/globe-icon.png
#
#   rm /media/$username/$partition/distros/$project/edit/usr/share/pixmaps/world-map-icon.png
#
#   cp /usr/share/rofi/themes/system.rasi \
#   /media/$username/$partition/distros/$project/edit/usr/share/rofi/themes/system.rasi
#
#   cp /usr/bin/i3-scratchpad-show-or-create.sh \
#   /media/$username/$partition/distros/$project/edit/usr/bin/i3-scratchpad-show-or-create.sh
#   cp /usr/bin/i3-scratchpad-show-or-create.sh \
#   /media/user/MEDIA_2/distros/catbird/livecd-setup/apps/i3/i3-scratchpad-show-or-create.sh
#
#   cp /root/.nanorc \
#   /media/$username/$partition/distros/$project/edit/etc/skel/.nanorc
#   cp /root/.nanorc \
#   /media/$username/$partition/distros/$project/livecd-setup/apps/dotfiles/.nanorc
#
#   cp /root/00-font-remover.sh \
#   /media/$username/$partition/distros/$project/livecd-setup/00-font-remover.sh
#   cp /root/01-nerdfont-installer.sh \
#   /media/$username/$partition/distros/$project/livecd-setup/01-nerdfont-installer.sh
#
# backup and deploy dotfiles (edit first in ../utils)
#   cp /media/$username/$partition/distros/$project/utils/.bash_misc \
#   /media/$username/$partition/distros/$project/edit/etc/skel/.bash_misc
#   cp /media/$username/$partition/distros/$project/utils/.bash_misc \
#   /media/$username/$partition/distros/$project/livecd-setup/apps/dotfiles/.bash_misc
#
#   cp /media/$username/$partition/distros/$project/utils/.profile \
#   /media/$username/$partition/distros/$project/edit/etc/skel/.profile
#   cp /media/$username/$partition/distros/$project/utils/.profile \
#   /media/$username/$partition/distros/$project/livecd-setup/apps/dotfiles/.profile
#
#   cp /media/$username/$partition/distros/$project/utils/.xinitrc \
#   /media/$username/$partition/distros/$project/edit/etc/skel/.xinitrc
#   cp /media/$username/$partition/distros/$project/utils/.xinitrc \
#   /media/$username/$partition/distros/$project/livecd-setup/apps/dotfiles/.xinitrc
#
# copy an xserver config from live system into the projects
#   cp /etc/X11/xorg.conf.d/99-screen-resolution.conf \
#   /media/$username/$partition/distros/$project/edit/etc/X11/xorg.conf.d/99-screen-resolution.conf
#
#   cp /root/blacklist-intel_vbtn.conf \
#   /media/$username/$partition/distros/$project/edit/etc/modprobe.d/blacklist-intel_vbtn.conf
#
#   cp /root/Desktop/config \
#   /media/$username/$partition/distros/$project/backup/etc/skel/.config/newsboat
#   cp /root/Desktop/config \
#   /media/$username/$partition/distros/$project/edit/etc/skel/.config/newsboat
#   cp /root/Desktop/config \
#   /media/$username/$partition/distros/$project/livecd-setup/apps/newsboat
#
# change the i3 config
#   # in /etc...
#    cp /root/Desktop/config \
#    /media/$username/$partition/distros/$project/livecd-setup/apps/i3/etc/i3/config
#    cp /root/Desktop/config \
#    /media/$username/$partition/distros/$project/edit/etc/i3/config
#   # in /etc/skel...
#    cp /root/Desktop/config \
#    /media/$username/$partition/distros/$project/livecd-setup/apps/i3/etc/skel/.config/i3/config
#    cp /root/Desktop/config \
#    /media/$username/$partition/distros/$project/edit/etc/skel/.config/i3/config
#
#    cp /etc/i3status.conf \
#    /media/$username/$partition/distros/$project/backup/etc/i3status.conf
#    cp /etc/i3status.conf \
#    /media/$username/$partition/distros/$project/edit/etc/i3status.conf
#    cp /etc/i3status.conf \
#    /media/$username/$partition/distros/$project/livecd-setup/apps/i3/etc/i3status.conf
#
# copy the distro i3 configs to the livecd-setup folders
#    cp /media/$username/$partition/distros/$project/edit/etc/skel/.config/i3/config \
#    /media/$username/$partition/distros/$project/livecd-setup/apps/i3/etc/skel/.config/i3/config
#    cp /media/$username/$partition/distros/$project/edit/etc/i3/config \
#    /media/$username/$partition/distros/$project/livecd-setup/apps/i3/etc/i3/config
#
#   rsync -avhc --inplace --no-whole-file --delete \
#   /opt/nvim/ \
#   /media/$username/$partition/distros/$project/livecd-setup/apps/neovim/nvim/
#
#   rsync -avhc --inplace --no-whole-file --delete \
#   /opt/nvim/ \
#   /media/$username/$partition/distros/$project/edit/opt/nvim/
#
#   rsync -avhc --inplace --no-whole-file --delete \
#   /opt/nvim/ \
#   /media/$username/$partition/distros/$project/backup/opt/nvim/
#
#   rsync -avhc --inplace --no-whole-file --delete \
#   /etc/xdg/nvim/ \
#   /media/$username/$partition/distros/$project/edit/etc/xdg/nvim/
#
#   rsync -avhc --inplace --no-whole-file --delete \
#   /etc/xdg/nvim/ \
#   /media/$username/$partition/distros/$project/livecd-setup/apps/neovim/nvim-root/
#
echo -e "\nFinished in ${project}... \n"
done
