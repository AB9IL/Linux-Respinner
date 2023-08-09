#!/bin/bash
# Place this script one level above the directories containing the distro files.
# Run the working system from a separate drive / sdcard / flashdrive...

# exit if not root
[[ $EUID -ne 0 ]] && echo "You must be root to run this script." && exit

# define the non-root user
username="$(logname)"

# Partition holding distro files
partition='MEDIA_2'

# Script working directory (one level above project directories)
export WKDIR="$(readlink -f "$(dirname "$0")")"

# name of the projects' root file system directories
export RFSCONTENTS="edit"

# list of directories holding linux respin projects
#export dirs='troutlinux'
#export dirs='troutlinux grunionlinux carplinux salmonlinux crayfishlinux'
#export dirs='troutlinux grunionlinux'
export dirs='troutlinux crayfishlinux'


# a group of files to copy to each system to the same folder
for project in $dirs; do
echo -e "\nWorking in ${project}... \n"
# copy or move files

# make backups of nvim configs
# rsync -avhc --inplace --delete ${WKDIR}/${project}/edit/etc/skel/.config/nvim/lua/ \
#     ${WKDIR}/${project}/livecd-setup/apps/neovim/skel/.config/nvim/lua/
#
# move lf config to /etc/lf
# rsync -avhc --inplace --delete /etc/lf/ \
#     ${WKDIR}/${project}/edit/etc/lf/
# rm -rf ${WKDIR}/${project}/edit/etc/skel/.config/lf
#
echo -e "\nFinished in ${project}... \n"
done
