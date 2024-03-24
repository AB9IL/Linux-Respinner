# Linux-Respinner

Scripts to respin and maintain Debian / Ubuntu / Linux Mint ISO file releases.

These scripts are exactly what I use to remaster and customize Ubuntu and Debian iso files, debloating and configuring the Linux for various specialty live environments.

Crack open your favorite livecd and set up a more perfect choice of web browser, bookmarks, desktop, or window manager. The official releases are great, but the bottom line with Linux is that you can make a distro into just about anything you want.

## Dependencies:

```
fd-find fzf genisoimage squashfs-tools syslinux-utils xorriso
```

## Usage (multifunction.sh):

```
multifunction.sh <task>
```

1. Place in a working directory on a medium large enough to hold the original iso file, the extracted iso contents, and a working linux filesystem (in total, about four times the size of the original iso file).
2. Edit the variables at the top of the script to set paths, username, and other items.
3. The DISTRIBID variable is critically important! Must be set to "Debian", "Ubuntu", "Mint", or "Rhino""" type of iso.
4. The UBUCODE variable is also important. Set to "focal", "lunar", as appropriate. For Rhino Linux, "rhino" is correct.
5. Make the script executable.
6. Run as root in a terminal; use the "extractiso" argument to rip the iso data.
7. Restart the respinner script, with "chroot" argument.
8. When in the chroot environment, update, install, or remove software.
9. You can also add or delete files directly in the root file system directory.
10. To leave the chroot, execute "exit" and let the script clean up and quit.
11. Restart the script again, choosing the "makedisk" argument.

## Usage (group-update):

```
group-update
```

1. Select the desired task from the menu (apt update, extract iso content, build a new iso, etc)
2. Manually edit the project dirs to activate for the current task.
3. Manually edit the function for directly fixing files with no chroot environment.
4. Manually edit the function for executing discrete tasks within the chroot environment.
5. For safety, comment out the project dirs, discrete tasks, and file fixes when you finish a set of tasks.

The group-update script is a centralized management tool for one or many iso respin projects. Edit the variables near the beginning of the script, especially to set paths and "dirs" for the project directories. Set paths as needed for copying deb packages, kernel files, or other items into your projects, or to delete any items.

**In each project directory, place _multifunction.sh_ and the original distro iso which will be extracted and respun. The group-update script will cd into each project and execute multifunction.sh for its various tasks.**
