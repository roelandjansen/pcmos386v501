#======================================================================
#
#	makefile for:	ulib.lib
#	creation date:	01/31/92
#	revision date:	05/21/92
#	programmer:	mjs
#
#======================================================================
#
# mjs 05/21/92	added data for ulexptab.obj/.c
# jts 06/30/18  added code for variable ccomp to allow selection of
#               c compiler (bcc|tcc)
#               commented out dead code for ulib.xxx and genndx.bat
#               since extract command is not available
#
#======================================================================
#
# this make file uses the ulib.xxx file as a flag to control the
# rebuilding of the extracted text index for ulib.  when any implicit
# rule fires, the ulib.xxx file is deleted.  this will force the
# command body for the rule with the ulib.xxx target to be executed.
# this execution will run the genlbndx batch file and then create
# a new copy of ulib.xxx.
#
# the genlbndx batch file is required since the extract command that
# is run from this batch file requires the '#' character as one
# of its parameters.
#
#======================================================================
# 
# required switches:
#
# -Dcdir=d:\cutils   (substitute your cutils directory for 'd:\cutils')
# -Dccomp=bcc        (substitute your compiler bcc or tcc)
#

#==== implicit rules

.c.obj:
    $(ccomp) -c -I$(cdir) $&.c
    tlib ulib -+$&.obj
#    del ulib.xxx

.asm.obj:
    masm /mx /z $&;
    tlib ulib -+$&.obj
#    del ulib.xxx

#==== the main target

ulib.xxx :	ulbeep.obj   ulstr2v.obj  ulclrbox.obj uldrwbox.obj \
		ulsetvpt.obj uldrwhbr.obj uldrwvbr.obj uldspdec.obj \
		ulsetatr.obj ulscrlup.obj ulsetcur.obj ulgetkey.obj \
		ulchar2v.obj ulgetkst.obj ulscrldn.obj ulgetcur.obj \
		ulsvrswn.obj ulmessag.obj ulfilbox.obj ulopclwn.obj \
		ulcls.obj    ulview.obj   ulifkey.obj  uleatkey.obj \
		ulgetstr.obj ulgetxy.obj  ulgetcho.obj ulanyfil.obj \
		ulremfil.obj ulexptab.obj ultrdir.obj  ultrdirl.obj \
		ulwalktr.obj ulismos.obj  ulmkpth.obj  ulfsize.obj  \
		ulwrlbl.obj  ulrdlbl.obj  ulformt.obj  ulqualt.obj

#    genndx
#    echo x>ulib.xxx

#==== c dependencies

ulbeep.obj	: ulbeep.c	$(cdir)\ulib.h
ulstr2v.obj	: ulstr2v.c	$(cdir)\ulib.h
ulclrbox.obj	: ulclrbox.c	$(cdir)\ulib.h
ulcls.obj	: ulcls.c	$(cdir)\ulib.h
uldrwbox.obj	: uldrwbox.c	$(cdir)\ulib.h
ulfilbox.obj	: ulfilbox.c	$(cdir)\ulib.h
ulsetvpt.obj	: ulsetvpt.c	$(cdir)\ulib.h
uldrwhbr.obj	: uldrwhbr.c	$(cdir)\ulib.h
uldrwvbr.obj	: uldrwvbr.c	$(cdir)\ulib.h
uldspdec.obj	: uldspdec.c	$(cdir)\ulib.h
ulsetatr.obj	: ulsetatr.c	$(cdir)\ulib.h
ulscrlup.obj	: ulscrlup.c	$(cdir)\ulib.h
ulsetcur.obj	: ulsetcur.c	$(cdir)\ulib.h
ulgetcur.obj	: ulgetcur.c	$(cdir)\ulib.h
ulgetkey.obj	: ulgetkey.c	$(cdir)\ulib.h
uleatkey.obj	: uleatkey.c	$(cdir)\ulib.h
ulifkey.obj	: ulifkey.c	$(cdir)\ulib.h
ulchar2v.obj	: ulchar2v.c	$(cdir)\ulib.h
ulgetkst.obj	: ulgetkst.c	$(cdir)\ulib.h
ulscrldn.obj	: ulscrldn.c	$(cdir)\ulib.h
ulmessag.obj	: ulmessag.c	$(cdir)\ulib.h
ulopclwn.obj	: ulopclwn.c	$(cdir)\ulib.h
ulview.obj	: ulview.c	$(cdir)\ulib.h
ulgetstr.obj	: ulgetstr.c	$(cdir)\ulib.h
ulgetxy.obj	: ulgetxy.c	$(cdir)\ulib.h
ulgetcho.obj	: ulgetcho.c	$(cdir)\ulib.h
ulanyfil.obj	: ulanyfil.c	$(cdir)\ulib.h
ulremfil.obj	: ulremfil.c	$(cdir)\ulib.h
ulexptab.obj	: ulexptab.c	$(cdir)\ulib.h
ultrdir.obj	: ultrdir.c	$(cdir)\ulib.h
ultrdirl.obj	: ultrdirl.c	$(cdir)\ulib.h
ulwalktr.obj	: ulwalktr.c	$(cdir)\ulib.h
ulismos.obj	: ulismos.c	$(cdir)\ulib.h
ulmkpth.obj	: ulmkpth.c	$(cdir)\ulib.h
ulfsize.obj	: ulfsize.c	$(cdir)\ulib.h
ulwrlbl.obj	: ulwrlbl.c	$(cdir)\ulib.h
ulrdlbl.obj	: ulrdlbl.c	$(cdir)\ulib.h
ulformt.obj	: ulformt.c	$(cdir)\ulib.h
ulqualt.obj	: ulqualt.c	$(cdir)\ulib.h

#==== asm dependencies

ulsvrswn.obj	: ulsvrswn.asm

