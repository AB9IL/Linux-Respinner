**Linux-Respinner**

A script to respin and maintain Debian / Ubuntu / Linux Mint ISO file releases.

Usage:

1) Place in a working directory on a medium large enough to hold the original iso file, the extracted iso contents, and a working linux filesystem (in total, about four times the size if the original iso file).
2) Edit the paths and username in the script.
3) Make the script executable.
4) Run as root in a terminal; use the proper argument.
5) Extract the iso file contents and exit the script.
6) Restart the respinner script, with "chroot" argument.
5) When in the chroot environment, update, install, or remove software.
6) To leave the chroot, execute "exit" and let the script clean up and quit.
7) Restart the script again, choosing the "makedisk" argument.

