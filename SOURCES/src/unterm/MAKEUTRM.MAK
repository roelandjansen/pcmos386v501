#######################################################################
#
# makefile for:		unterm terminal driver
#
#######################################################################

all:	unterm.sys

unterm.sys:	unterm.asm  page.inc  mostcb.inc  mosscbdf.inc  \
			seriomac.inc  jmpmacro.inc  int14.inc  isrsub.inc \
			macros.inc vidchk.inc biosload.inc biosres.inc
		public unterm
		masm unterm;
        	del unterm.pub
		link unterm;
		del unterm.obj
		exe2bin unterm unterm.sys
		del unterm.exe
