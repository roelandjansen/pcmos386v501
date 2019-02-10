###############################################################################
#
#       MAKEFILE FOR:           PC-MOS utility programs
#
#       Creation date:          11/15/89
#
#       Revision date:          10/10/91
#
#       Programmer:             The Software Link, Inc
#
#       ----------------------  >> Revision Log <<  --------------------------
#
# Date          Prog    Description of Revision
# ----          ----    -----------------------
# 11/15/89      BWR     Cleanup and verification that the makefile
#                       checks for ALL dependencies.
#
# 1/8/90        BWR     Added a few missing file dependencies as
#                       suggested by MJS.
#
# 1/12/90       SAH     Added INIT.COM and place moxcpcor.com           
#                       into this make file
#
# 1/15/90       BWR     Builds $$SHELL.SYS instead of MOXCPCOR.COM
#
# 3/01/90       BWR     COMPFILE build must now include reference to
#                       C applications library UTIL.LIB
#
# 3/09/90       BWR     Added builds for HELPGEN.EXE
#
# 4/4/90        BWR     $$SHELL.SYS is now part of the "ALL" target.
#                       It is built as __SHELL.SYS because of the
#                       make utilitie's use of the '$' as a macro
#                       symbol.  (All the device drivers are similarly
#                       named.)  Simply rename after building.
#
# 4/18/90       BWR     Dependencies for SPOOL.COM are changed.
#
# 4/25/90       BWR     Added build for ED.EXE
#
# 5/03/90       BWR     ED.EXE now builds in LARGE model.
#
# 05/04/90      mjs     added macros.inc dependency to verify
#
# 05/17/90      mjs     add dependency to macros.inc to mos.asm
#
# 6/6/90        BWR     Command processor builds as $$SHELL.SYS instead
#                       of __SHELL.SYS
#
# 7/2/90        BWR     MAKE still having trouble with $$ macro on
#                       $$SHELL.SYS.  Builds __SHELL.SYS as before.  We'll
#                       just have to rename the file after the build.
#
# 7/25/90       BWR     C programs now built to use RSACLIB.
#
# 8/2/90        BWR     Added HELP.EXE to the build.
#
# 08/13/90      MJS     make addtask.com dependent on macros.inc
#
# 02/26/91      BWR     Fixed some missing dependencies.
#                       Also ... IMPORT and EXPORT are now C utilities
#                       and must be obtained from MOS utility directory.
#                       They each have their own respective MAKEFILES
#                       and are no longer part of this build file.
#
# 03/25/91	mjs	removed moxcpcor's dependency on xifmacs.inc
#
# 04/17/91      BWR     Build for ED.EXE split out into its own make
#                       group because ED is being split into modules.
#
# 10/10/91	SAH	added depencies on pilds.inc and llrec.inc for
#			new serial.sys driver
#
# mjs 12/16/91	dlg mods:
#		  format.asm depends on dskstruc.inc, macros.inc, fmcommon.inc
#		  format.asm doesn't depend on version.inc anymore
#		  msys.asm depends on dskstruc.inc, macros.inc, fmcommon.inc
#
# mjs 12/31/91	verify.asm depends on dskstruc.inc
#
# SAH 01/02/92	Remove changes so that _386.sys does not depend on moxmem.inc
#
# SAH 03/04/92  Added Arnet driver to dependences
#
# SAH 05/05/92	Added Serinfo.com 
#
# cbk 05/19/92  changed print.com
#
###############################################################################
#
# Default rules for this makefile.
#
.asm.com : 
        public $<
        masm $*;
        del $*.pub
        link $*;
        del $*.obj
        exe2bin $* $*.com
        del $*.exe

.asm.sys :
        public $<
        masm $*;
        del $*.pub
        link $*;
        del $*.obj
        exe2bin $* $*.sys
        del $*.exe

.asm.obj :
        public $<
        masm $*;
        del $*.pub

.asm.exe :
        public $<
        masm $*;
        link $*;
        del $*.pub
        del $*.obj

ALL:    adddev.com  addtask.com  dirmap.com  alias.com  class.com  debug.com \
        dirmap.com  diskcopy.com  diskid.com  filemode.com  \
        format.com  keymap.com  monitor.com serinfo.com \
        more.com mos.com  mosadm.com  mosdd7f.sys  moxcptsk.com  msys.com  \
        netname.com  print.com  remdev.com  remtask.com  search.com \
        setmouse.com  spool.com  verify.exe  _286n.sys  _386.sys  _all.sys \
        _charge.sys  _ems.sys  _gizmo.sys  _kbbe.sys  _kbcf.sys  _kbdk.sys \
        _kbfr.sys _kbgr.sys  _kbit.sys  _kbla.sys  _kbnl.sys  _kbno.sys \
        _kbpo.sys  _kbsf.sys  _kbsg.sys  _kbsp.sys  _kbsv.sys  _kbuk.sys \
        _mouse.sys  _netbios.sys  _pipe.sys  _ramdisk.sys  _serial.sys \
        init.com   __shell.sys _arnet.sys filter.com  patchid.com \
        minbrdpc.sys  mispeed.com compfile.exe helpgen.exe \
	vidpatch.com ed.exe

############ General purpose publics #############

mostcb.pub : mostcb.inc
        public mostcb.inc

mosscbdf.pub : mosscbdf.inc
        public mosscbdf.inc

mboot.pub : mboot.inc
        public mboot.inc

############ General purpose publics #############

verschk.inc : version.inc

moxutil.obj : moxutil.asm moxutl.inc


adddev.com:     adddev.asm page.inc options.inc macros.inc version.inc

addtask.com:    addtask.asm page.inc options.inc mostcb.inc mosscbdf.inc \
                version.inc macros.inc

alias.com:      alias.asm moxutil.obj page.inc moxutl.inc version.inc
        public alias
        masm alias;
        del alias.pub
        link alias + moxutil;
        exe2bin alias alias.com
        del alias.obj
        del alias.exe

class.com:      class.asm page.inc mostcb.inc mosscbdf.inc options.inc \
                version.inc

#******************************************************************************
#       MOS Debugger.
#******************************************************************************
debug.com:      debug.obj debugman.obj debugcon.obj debugext.obj \
                debugtra.obj debugsup.obj debugend.obj
        link debug +debugman +debugcon +debugext +debugtra +debugsup \
        +debugend/m;
        exe2bin debug debug.com
        del debug.exe

debug.obj:      debug.asm page.inc options.inc mostcb.inc mostcb.pub \
                version.inc

debugman.obj:   debugman.asm page.inc debugmac.inc

debugcon.obj:   debugcon.asm page.inc

debugext.obj:   debugext.asm page.inc

debugtra.obj:   debugtra.asm page.inc debugmac.inc

debugsup.obj:   debugsup.asm page.inc

debugend.obj:   debugend.asm page.inc

#******************************************************************************

dirmap.com:     dirmap.asm version.inc page.inc options.inc

diskcopy.com:   diskcopy.asm page.inc copyrit.inc verschk.inc

diskid.com:     diskid.asm page.inc verschk.inc

filemode.com:   filemode.asm page.inc version.inc

filter.com:     filter.asm page.inc

format.com:     format.asm page.inc options.inc mboot.pub dskstruc.inc \
                mboot.inc macros.inc fmcommon.inc

;hdsetup.com:    hdsetup.asm page.inc mbrdef.inc mbr.inc

keymap.com:     keymap.asm page.inc

minbrdpc.sys:   minbrdpc.asm page.inc

mispeed.com:    mispeed.asm page.inc

monitor.com:    monitor.asm page.inc options.inc mostfb.inc mosscbdf.inc \
                mostcb.inc version.inc

more.com:       more.asm page.inc version.inc

mos.com:        mos.asm mostcb.inc mosscbdf.inc mostfb.inc options.inc \
                genmouse.inc version.inc moxmos.inc macros.inc

mosadm.com:     mosadm.asm page.inc mostcb.inc mosscbdf.inc mostfb.inc \
                options.inc genmouse.inc version.inc moxmos.inc

mosdd7f.sys:    mosdd7f.asm options.inc

moxcptsk.com:   moxcptsk.asm page.inc mosscbdf.inc

msys.com:       msys.asm page.inc mboot.inc dskstruc.inc macros.inc fmcommon.inc

netname.com:    netname.asm page.inc version.inc

patchid.com:    patchid.asm page.inc macros.inc

print.com:      print.asm page.inc options.inc copyrit.inc
	public print
	copy ismos.def _osmos.def
	masm print;
	del print.pub
	link print;
	del print.obj
	exe2bin print print.com
	del print.exe
	del _osmos.def

remdev.com:     remdev.asm page.inc options.inc

remtask.com:    remtask.asm page.inc mostcb.inc mosscbdf.inc moxutl.inc \
                moxutil.obj version.inc
        public remtask
        masm remtask;
        del remtask.pub
        link remtask+moxutil;
        del remtask.obj
        exe2bin remtask remtask.com
        del remtask.exe

search.com:     search.asm page.inc version.inc

serinfo.com:    serinfo.asm

setmouse.com:   setmouse.asm page.inc

spool.com:      spool.asm page.inc options.inc mostcb.inc copyrit.inc \
                verschk.inc
                        masm spool;
                        link spool;
                        exe2bin spool spool.com
                        del spool.exe

verify.exe:     verify.asm page.inc options.inc macros.inc dskstruc.inc

_286n.sys:      _286n.asm page.inc

_386.sys:       _386.asm page.inc 

_all.sys:       _all.asm page.inc moxmem.inc

_charge.sys:    _charge.asm page.inc moxmem.inc

_ems.sys:       _ems.asm page.inc

_gizmo.sys:     _gizmo.asm page.inc moxmem.inc


_kbbe.sys:      moskbbe.asm page.inc moskbfor.inc moskbinz.inc
        masm moskbbe,$*;
        link $*;
        exe2bin $* $*.sys
        del $*.obj
        del $*.exe

_kbcf.sys:      moskbcf.asm page.inc moskbfor.inc moskbinz.inc
        masm moskbcf,$*;
        link $*;
        exe2bin $* $*.sys
        del $*.obj
        del $*.exe

_kbdk.sys:      moskbdk.asm page.inc moskbfor.inc moskbinz.inc
        masm moskbdk,$*;
        link $*;
        exe2bin $* $*.sys
        del $*.obj
        del $*.exe

_kbfr.sys:      moskbfr.asm page.inc moskbfor.inc moskbinz.inc
        masm moskbfr,$*;
        link $*;
        exe2bin $* $*.sys
        del $*.obj
        del $*.exe

_kbgr.sys:      moskbgr.asm page.inc moskbfor.inc moskbinz.inc
        masm moskbgr,$*;
        link $*;
        exe2bin $* $*.sys
        del $*.obj
        del $*.exe

_kbit.sys:      moskbit.asm page.inc moskbfor.inc moskbinz.inc
        masm moskbit,$*;
        link $*;
        exe2bin $* $*.sys
        del $*.obj
        del $*.exe

_kbla.sys:      moskbla.asm page.inc moskbfor.inc moskbinz.inc
        masm moskbla,$*;
        link $*;
        exe2bin $* $*.sys
        del $*.obj
        del $*.exe

_kbnl.sys:      moskbnl.asm page.inc moskbfor.inc moskbinz.inc
        masm moskbnl,$*;
        link $*;
        exe2bin $* $*.sys
        del $*.obj
        del $*.exe

_kbno.sys:      moskbno.asm page.inc moskbfor.inc moskbinz.inc
        masm moskbno,$*;
        link $*;
        exe2bin $* $*.sys
        del $*.obj
        del $*.exe

_kbpo.sys:      moskbpo.asm page.inc moskbfor.inc moskbinz.inc
        masm moskbpo,$*;
        link $*;
        exe2bin $* $*.sys
        del $*.obj
        del $*.exe

_kbsf.sys:      moskbsf.asm page.inc moskbfor.inc moskbinz.inc
        masm moskbsf,$*;
        link $*;
        exe2bin $* $*.sys
        del $*.obj
        del $*.exe

_kbsg.sys:      moskbsg.asm page.inc moskbfor.inc moskbinz.inc
        masm moskbsg,$*;
        link $*;
        exe2bin $* $*.sys
        del $*.obj
        del $*.exe

_kbsp.sys:      moskbsp.asm page.inc moskbfor.inc moskbinz.inc
        masm moskbsp,$*;
        link $*;
        exe2bin $* $*.sys
        del $*.obj
        del $*.exe

_kbsv.sys:      moskbsv.asm page.inc moskbfor.inc moskbinz.inc
        masm moskbsv,$*;
        link $*;
        exe2bin $* $*.sys
        del $*.obj
        del $*.exe

_kbuk.sys:      moskbuk.asm page.inc moskbfor.inc moskbinz.inc
        masm moskbuk,$*;
        link $*;
        exe2bin $* $*.sys
        del $*.obj
        del $*.exe


_mouse.sys:     _mouse.asm page.inc options.inc mosregs.inc xifmacs.inc \
                mostcb.inc mosscbdf.inc genmouse.inc

_netbios.sys:   _netbios.asm page.inc options.inc mostcb.inc mosscbdf.inc

_pipe.sys:      _pipe.asm page.inc mosscbdf.inc options.inc devreqh.inc

_ramdisk.sys:   _ramdisk.asm page.inc

_serial.sys:    _serial.asm page.inc options.inc serial.def jmpmacro.inc \
                seriomac.inc int14.inc isrsub.inc pilds.inc llrec.inc
        copy serial.def _serial.def
        public _serial.asm
        masm _serial;
        del _serial.pub
        link _serial;
        exe2bin _serial _serial.sys
        del _serial.obj
        del _serial.exe
        del _serial.def


_arnet.sys:    _arnet.asm page.inc options.inc jmpmacro.inc 
        public _arnet.asm
        masm _arnet;
        del _arnet.pub
        link _arnet;
        exe2bin _arnet _arnet.sys
        del _arnet.obj
        del _arnet.exe

init.com:       init.asm

vidpatch.com:   vidpatch.asm

#******************************************************************************
#       MOS Command processor - $$shell.sys
#******************************************************************************


__shell.sys : moxcpcor.obj moxcpint.obj moxcppls.obj moxcpsub.obj
        link moxcpcor+moxcpint+moxcppls+moxcpsub;
        exe2bin moxcpcor __shell.sys
        del moxcpcor.exe

moxcpcor.obj : moxcpcor.asm options.inc moxcpdat.inc mostcb.inc \
               moxcpsxt.inc mosscbex.inc version.inc
        public moxcpcor
        public moxcpdat.inc
        type moxcpdat.pub >> moxcpcor.pub
        masm moxcpcor;
        del moxcpcor.pub
        del moxcpdat.pub

moxcpsub.obj :  moxcpsub.asm  page.inc  moxcpdat.inc  mosscbex.inc \
                mostcb.inc
        public moxcpsub
        masm moxcpsub;
        del moxcpsub.pub

moxcpint.obj :  moxcpint.asm moxcpdat.inc moxcpsxt.inc
        public moxcpint
        masm moxcpint;
        del moxcpint.pub

moxcppls.obj :  moxcppls.asm  page.inc  moxcpdat.inc  mosscbdf.inc \
                moxcpsxt.inc
        public moxcppls
        masm moxcppls;
        del moxcppls.pub
#
#  Utility programs written in C.  (And Pascal, temporarily)
#
compfile.exe: compfile.c
        cl -c compfile.c
        link compfile/e,,,rsasmall

helpgen.exe: helpgen.c
        cl -c helpgen.c
        link helpgen/e,,,rsasmall

ed.exe: ed.c
	cl -c -AL ed.c
	link ed,,,rsalarge

help.exe: help.pas help.inc
        tpc help
