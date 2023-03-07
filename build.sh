#!/bin/bash
# Place this script one level above the directories containing the distro files.
# The builds will run in sequence.
# define the non-root user
username="$(logname)"
export username
# Partition holding distro files
partition="MEDIA_2"
export partition
# Destination for completed builds
#destination="MEDIA_1"
# list of directories holding linux projects
export dirs="rockdove"
#dirs="alphabird catbird mofolinux rockdove skywavelinux-gnome skywavelinux-i3wm"
#dirs="alphabird catbird mofolinux skywavelinux-gnome skywavelinux-i3wm"

construct(){
	(cd ${1}
	echo -e "\n\n   Starting work in ${1}   \n\n"
    [[ -f "${1}-latest.iso" ]] && \
    echo "Move ${1}-latest.iso to ${1}-latest.stable.iso" && \
    mv ${1}-latest.iso ${1}-latest.stable.iso
	./multifunction.sh makedisk
	echo -e "\n\n...Finished work in ${1}...\n\n"
    )
}

make_copy(){
    ([[ -f /media/"$(logname)"/${2}/distros/${1}/${1}-latest.iso ]] || exit 1
    # kill the loop if error
    trap 'echo "Exited!"; exit;' INT TERM
    MAX_RETRIES=50
    x=0
    # Set initial return value to failure
    false
    while [[ $? -ne 0 ]] && [[ $x -lt $MAX_RETRIES ]]; do
        ((x++))
        echo -e "\n\n...Copying $project-latest.iso --isofiles-- Pass $x...\n\n"
		rsync -avhc --inplace --no-whole-file --info=progress2 \
		/media/"$(logname)"/${2}/distros/${1}/${1}-latest.iso \
        /isodevice/isofiles/${1}-latest.iso;
        #/media/$username/$destination/isofiles/$project-latest.iso;
	sha256sum	/media/"$(logname)"/${2}/distros/${1}/${1}-latest.iso \
        /isodevice/isofiles/${1}-latest.iso;
    done
    [[ $x -eq $MAX_RETRIES ]] &&  echo -e "\n\nRetry limit reached\n\n"
    )
}

clear
for project in $dirs
do
    export project
	construct "$project" #&
done
echo -e "\n\n...Builds complete.  Now writing to the boot drive and backup...\n\n"

#wait

for project in $dirs
do
    export project
    make_copy "$project" "$partition" #&
done

#wait

echo -e "\n\n   File copy tasks completed.  Enjoy your new Linux!  \n\n"
