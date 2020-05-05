#!/bin/sh -eu

REV="$(dosemu --version | grep Revision | cut -d " " -f 2)"
if [ -z "$REV" ] || [ "$REV" -lt 4901 ]; then
    echo "At least dosemu2 revision 4901 is required (see dosemu --version)."
    exit 1
fi

BOOTDIR="SOURCES/src/latest"

[ -f "$BOOTDIR"/'$$mos.sys' ] || (echo "Run ./build.sh first!" && exit 1)

dosemu --Fdrive_c "$BOOTDIR"
