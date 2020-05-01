#!/bin/sh -eu

REV="$(dosemu --version | grep Revision | cut -d " " -f 2)"
if [ -z "$REV" ] || [ "$REV" -lt 3684 ]; then
    echo "At least dosemu2 revision 3684 is required (see dosemu --version)."
    exit 1
fi

BOOTDIR="SOURCES/src/latest"

[ -f "$BOOTDIR"/'$$mos.sys' ] || (echo "Run ./build.sh first!" && exit 1)

if [ ! -f "$BOOTDIR"/COMMAND.COM ]; then
    unzip SHIPMOS/SHIPMOS.ZIP COMMAND.COM -d "$BOOTDIR" || \
            (echo "Unable to extract command.com, unzip not installed?" && \
            exit 1)
fi

dosemu --Fdrive_c "$BOOTDIR"
