#======================================================================
#
#       makefile for:   export.exe, hdsetup.exe, and install.exe
#
#======================================================================
#
#======================================================================
# required switches:
#
# -Dbdir=c:\borlandc\lib\ (substitute your borland lib directory)
#
# optional switches:
#
# -Dudir=..\ulib\    (substitute your ulib directory for 'd:\ulib\')
# -Dmdir=..\latest\  (substitute your MOS source directory)
#
# -Ddebug       (to produce a version of hdsetup.exe with debugging info)
#
# required libraries:
#
# ulib.lib needs to be generated before these programs can be built
#

!if $(debug)
bcc_dbg_option=-v
tl_dbg_option=/v
!endif

!if !$d(udir)
udir=..\ulib\\
!endif


!if !$d(mdir)
mdir=..\latest\\

!endif

# Even though this is required, we'll try the default
# iff the user fails to provide their borland library path

!if !$d(bdir)
bdir=c:\borlandc\lib\\

!endif

all : export.exe hdsetup.exe install.exe

export.exe : export.obj expasm.obj
  tlink $(tl_dbg_option) $(bdir)c0s export expasm,export,export /m, $(bdir)cs $(udir)ulib

export.obj : export.c ulib.h asmtypes.h
  bcc -c $(bcc_dbg_option) $*.c

expasm.obj : expasm.asm
  masm expasm;

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

install.exe : install.obj insasm.obj
  tlink $(tl_dbg_option) $(bdir)c0s install insasm,install,,$(bdir)cs $(udir)ulib

install.obj : install.c insasm.h vidattr.h asmtypes.h \
              dskstruc.h  ulib.h summary.h
  bcc -c $(bcc_dbg_option) $*.c

insasm.obj : insasm.asm
  masm insasm;

