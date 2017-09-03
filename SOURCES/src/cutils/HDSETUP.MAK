#======================================================================
#
#	makefile for:	hdsetup
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
# -Dmdir=d:\         (substitute your mos directory for 'd:\')
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

hdsetup.exe  : hdsetup.obj
  tlink $(tl_dbg_option) $(bdir)c0s hdsetup,hdsetup,,$(bdir)cs $(udir)ulib

hdsetup.obj  : hdsetup.c vidattr.h asmtypes.h dskstruc.h ulib.h \
	       mbrbuf.inc summary.h
  bcc -c $(bcc_dbg_option) $*.c

mbrbuf.inc : genmbr.exe
  genmbr > mbrbuf.inc

genmbr.exe : genmbr.obj
  tlink genmbr,genmbr;

genmbr.obj : genmbr.asm $(mdir)mbr.inc
  masm /I$(mdir) genmbr;


