###############################################################################
#
#       MAKEFILE FOR:           PC-MOS Serial generation and registration
#
###############################################################################
#
# Default rules for this makefile.
#

ALL:    sngen.exe snreg.com

#
#  Utility programs written in C.
#
sngen.exe: sngen.c
        cl sngen.c
	sngen.exe
	del sngen.exe
	del sngen.obj

snreg.com: snreg.asm
	public snreg
	masm snreg;
	del snreg.pub
	link snreg;
	del snreg.obj
	exe2bin snreg snreg.com
	del snreg.exe
	regist.bat
	del snreg.com
	del regist.bat
