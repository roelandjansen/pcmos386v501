usage:

- use dd to create a bootable 3.5" disk image
- start a vmware server/workstation vm with floppy disk and select this image
  the supplied img file itself can be used to boot from under vmware.
- use the HDSETUP command to partition the hard drive
- use the MSYS command to install the boot sector

folders:
- "v4" contains images of v4.1 floppies
- "v501" contains images of patched v5.01 floppies from shipmos, 31-07-2012 fixed
- "template" contains templates used for creating floppy images, either by script or hand
