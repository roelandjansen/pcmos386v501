#======================================================================
#
#	makefile for:	install
#	creation date:	04/01/92
#	revision date:	04/01/92
#	programmer:	mjs
#
#======================================================================
#
# mjs 04/01/92	dlg mods: created this module.
# 
#======================================================================
# required switches:
#
# -Dudir=d:\ulib\    (substitute your ulib directory for 'd:\ulib\')
# -Dbdir=c:\bc\lib\  (substitute your borland lib directory for 'c:\bc\lib\')
#
# optional switches:
#
# -Ddebug	(to produce a version of hdsetup.exe with debugging info)
#

!if $(debug)
bcc_dbg_option=-v
tl_dbg_option=/v
!endif

install.exe : install.obj insasm.obj
  tlink $(tl_dbg_option) $(bdir)c0s install insasm,install,,$(bdir)cs $(udir)ulib

install.obj : install.c insasm.h vidattr.h asmtypes.h \
	      dskstruc.h  ulib.h summary.h
  bcc -c $(bcc_dbg_option) $*.c

insasm.obj : insasm.asm 
  masm insasm;


