#!/bin/sh -eu
REV="$(dosemu --version | grep Revision | cut -d " " -f 2)"
if [ -z "$REV" ] || [ "$REV" -lt 3684 ]; then
    echo "At least dosemu2 revision 3684 is required (see dosemu --version)."
    exit 1
fi

# need to remove uppercase *.SYS files as dosemu will create the
# lowercase ones, they may collide
rm -f kernel/*.SYS
rm -f mos5src/*.SYS
dosemu -td -K ./MAKEMOS.BAT -U 2 'path=%D\bin;%O'
# MOS does not understand files with recent dates so set the old one
S_DATE="Jan 29 1993"
touch -d "$S_DATE" mos5src/*.sys
