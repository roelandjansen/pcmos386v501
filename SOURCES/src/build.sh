#!/bin/sh -eu

REV="$(dosemu --version | grep Revision | cut -d " " -f 2)"
if [ -z "$REV" ] || [ "$REV" -lt 3684 ]; then
    echo "At least dosemu2 revision 3684 is required (see dosemu --version)."
    exit 1
fi

dosemu -td -K ./MAKEMOS.BAT -U 2 'path=%D\bin;%O'
