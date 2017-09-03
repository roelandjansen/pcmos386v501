#======================================================================
#
#	makefile for:	export.exe
#	creation date:	12/13/92
#	revision date:	12/13/92
#	programmer:	mjs
#
#======================================================================
#
# mjs 12/13/92	created this module
#
# mjs 02/01/93	expasm.asm no longer depends on mostcb.inc.
#		as a result, no longer need the -Dmdir switch
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

export.exe : export.obj expasm.obj
  tlink $(tl_dbg_option) $(bdir)c0s export expasm,export,export /m, $(bdir)cs $(udir)ulib

export.obj : export.c ulib.h asmtypes.h
  bcc -c $(bcc_dbg_option) $*.c
  
expasm.obj : expasm.asm
  masm expasm;
