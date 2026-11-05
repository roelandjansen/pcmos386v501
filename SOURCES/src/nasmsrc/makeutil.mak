###############################################################################
#
#       MAKEFILE FOR:           PC-MOS utility programs
#
###############################################################################
#
# Default rules for this makefile.
#
more.com:       more.s version.inc
	nasm -f bin more.s -l more.lst -o more.com

filter.com:	filter.s version.inc
	nasm -f bin filter.s -l filter.lst -o filter.com
