**Linux-Respinner**

A script to respin and maintain Debian / Ubuntu / Linux Mint ISO file releases.

These scripts are exactly what I use to remaster both Ubuntu and Debian, debloating and customizing the software for various specialty live environments.

Crack open your favorite livecd and set up your own browser, bookmarks, desktop, or window manager. The official releases are great, but the bottom line with Linux is that you can make a distro into just about anything you want.

Usage:

1) Place in a working directory on a medium large enough to hold the original iso file, the extracted iso contents, and a working linux filesystem (in total, about four times the size of the original iso file).
2) Edit the paths, username, and other items at the top of the script.
3) The DISTRIBID variable is critically important! Must be set to "Debian" or "Ubuntu" type of iso.
4) Make the script executable.
5) Run as root in a terminal; use the "extractiso" argument to rip the iso data.
6) Restart the respinner script, with "chroot" argument.
7) When in the chroot environment, update, install, or remove software.
8) You can also add or delete files directly in the root file system directory.
9) To leave the chroot, execute "exit" and let the script clean up and quit.
10) Restart the script again, choosing the "makedisk" argument.

The other scripts (build, fixfiles, group-update) are tools for updating or fixing issues en masse, on multiple linux respin projects.

