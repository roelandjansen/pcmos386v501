#!/bin/sh -eu

REV="$(dosemu --version | grep Revision | cut -d " " -f 2)"
if [ -z "$REV" ] || [ "$REV" -lt 3684 ]; then
    echo "At least dosemu2 revision 3684 is required (see dosemu --version)."
    exit 1
fi

# dosemu seems to change sytax every few years
if [ "$REV" -ge 5709 ]; then
    ARGS="-K .:SOURCES\\src -E MAKEMOS.BAT"
else
    ARGS="-K SOURCES/src/MAKEMOS.BAT -U 2"
fi

dosemu -td -ks $ARGS 'path=%D\bin;%O'
