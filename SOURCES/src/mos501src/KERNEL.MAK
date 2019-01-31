###############################################################################
#
#	MAKEFILE FOR:		PC-MOS Kernel (Main Version and Eval)
#
#	Creation date:		21-Dec-89
#
#	Revision date:		09-Jan-90
#
#	Programmer:		B. W. Roeser
#
#	----------------------  >> Revision Log <<  --------------------------
#
# Date		Prog	Description of Revision
# ----		----	-----------------------
# 1/8/90	BWR	Syntax correction.
# 1/12/90	SAH	Serialization corrections	 
# 1/19/90	SAH	Added MOSINT15 to make
# 1/23/90	SAH	Added MOSMISC to make
# 1/23/90	BWR	Added dependency to new include file ERRCODES.INC
# 02/09/90      SAH     Added MOSINT74 to make
# 05/17/90	mjs	add dependency to macros.inc to mosrtask.asm 
#			and mossaver.asm
# 03/26/91	mjs	mosinit and mosinit2 depend on moscnf.inc
# 04/0391	mjs	mosddint no longer depends on xifmacs.inc 
#
# mjs 12/16/91	dlg mods:
#		  mosinit2.asm depends on dskstruc.inc, mboot.inc
#		  mosfront.asm depends on dskstruc.inc
#		  mosddblf.asm depends on dskstruc.inc, macros.inc
#		  mosddint.asm depends on dskstruc.inc
#		  mosfutl3.asm depends on dskstruc.inc
#		  mosddblk.asm depends on dskstruc.inc
#		  mostemp.asm depends on dskstruc.inc
#		  mosfun44.asm depends on errcodes.inc
#		  mosfun39.asm depends on errcodes.inc, mospsp.inc
#		  mosfutil.asm depends on dskstruc.inc
#
# 03/23/92	mjs	mosfun00.asm no longer depends on xifmacs.inc
#			mosfun00.asm now depends on macros.inc
#			mosint16.asm no longer depends on xifmacs.inc
#
###############################################################################
#
.asm.obj:
	public $<
	masm $*;
	del $*.pub

OBJECTS = mosfront.obj mosliman.obj mosheman.obj mosint74.obj \
	  mosddint.obj mosddcon.obj mosddblk.obj mosint21.obj \
	  mosfun00.obj mosfun39.obj mosfutil.obj mostemp.obj  \
	  mosfun0f.obj mosint13.obj mosdebug.obj mosmisc.obj \
	  mosint10.obj mosint16.obj mosddtmc.obj mosinit.obj \
	  mosint38.obj moscntxt.obj mosddblf.obj mosint28.obj \
	  mosddclk.obj mosrtask.obj mosdevs.obj  mosint17.obj \
	  mosfun01.obj mosmiman.obj mositask.obj mosint15.obj \
	  mosback.obj  mosfun44.obj mosfutl3.obj mosfutl2.obj \
	  mosfutl4.obj mosint06.obj mossaver.obj mosnxtsk.obj \

COMMON = mosint13 +mosddblk +mosddblf +mosliman +mosheman +mosddint \
	 +mosint15 +mosddcon +mosint21 +mosfun00 +mosfun01 +mosfun0f \
	 +mosfun39 +mosfun44 +mosfutil +mostemp +mossaver +mosint28 \
	 +mosdebug +mosmiman +mosint38 +moscntxt +mosddclk +mosrtask \
	 +mosdevs +mosint06 +mosint10 +mosint16 +mosint17 +mosddtmc \
	 +mosnxtsk +mosmisc +mosfutl2 +mosfutl3 +mosfutl4 +mosint74 \
	 +mositask +mosinit

#==============================================================================
#	Build the version of $$MOS.SYS
#==============================================================================
$$$$mos.sys : $(OBJECTS) mosinit2.obj
	link mosfront +$(COMMON) +mosinit2 +mosback/m/se:512, \
	$$$$mos.sys;
	debug $$$$mos.sys <exe2bin.dat
	ts $$$$mos.map/s

#==============================================================================
#	Build the EVALUATION version of $$MOS.SYS
#==============================================================================
$$$$eval.sys : $(OBJECTS) mosini2e.obj
	link mosfront +$(COMMON) +mosini2e +mosback/m/se:512, \
	$$$$eval.sys;
	debug $$$$eval.sys <exe2bin.dat
	ts $$$$eval.map/s

#==============================================================================
#	Routines common to R&D Development version of MOS
#==============================================================================

mosinit2.obj : 	mosinit2.asm mosregs.inc mostcb.inc moscdb.inc mosbdb.inc \
		 mosscbex.inc mospsp.inc  options.inc group.inc \
		 moslogo.inc macros.inc moscnf.inc dskstruc.inc mboot.inc

#==============================================================================
#	Routines common to EVALUATION version of the MOS kernel.
#==============================================================================

mosini2e.obj : 	mosinit2.asm mosregs.inc mostcb.inc moscdb.inc mosbdb.inc \
		 mosscbex.inc mospsp.inc  options.inc group.inc \
		 moslogo.inc moscnf.inc

	       public mosinit2
	       masm mosinit2,$*/DRELCODE=YES;
	       del mosinit2.pub
				
#==============================================================================
#	Routines common to ALL versions of the MOS kernel.
#==============================================================================

mositask.obj :	mositask.asm mostcb.inc moscdb.inc mosscbex.inc mosbdb.inc \
		options.inc group.inc mostcb.pub macros.inc

mosfutil.obj : 	mosfutil.asm mosregs.inc mostcb.inc moscdb.inc mosgfb.inc \
		mostfb.inc mosrlb.inc mosbdb.inc mosscbex.inc options.inc \
		group.inc macros.inc dskstruc.inc

mosfutl2.obj : 	mosfutl2.asm mosregs.inc mostcb.inc moscdb.inc mosgfb.inc \
		mostfb.inc mosrlb.inc mosbdb.inc mosscbex.inc options.inc \
		group.inc macros.inc 

mosfutl3.obj : 	mosfutl3.asm mosregs.inc mostcb.inc moscdb.inc mosgfb.inc \
		mostfb.inc mosrlb.inc mosbdb.inc mosscbex.inc options.inc \
		group.inc macros.inc dskstruc.inc

mosfutl4.obj : 	mosfutl4.asm mosregs.inc mostcb.inc moscdb.inc mosgfb.inc \
		mostfb.inc mosrlb.inc mosbdb.inc mosscbex.inc options.inc \
		group.inc macros.inc 

mosfun39.obj : 	mosfun39.asm mosregs.inc mostcb.inc moscdb.inc mosgfb.inc \
		mostfb.inc mosrlb.inc mosbdb.inc mosscbex.inc options.inc \
		group.inc errcodes.inc mospsp.inc

mosfun44.obj : 	mosfun44.asm mosregs.inc mostcb.inc moscdb.inc mosgfb.inc \
		mostfb.inc mosrlb.inc mosbdb.inc mosscbex.inc options.inc \
		group.inc macros.inc errcodes.inc

mosfun00.obj : 	mosfun00.asm errcodes.inc mosregs.inc mostcb.inc moscdb.inc \
		mostfb.inc moxspldt.inc mosbdb.inc mospsp.inc mosscbex.inc \
		options.inc group.inc macros.inc

mosfun01.obj :	mosfun01.asm mosregs.inc mostcb.inc mostfb.inc \
		mosscbex.inc options.inc group.inc macros.inc

mosfront.obj : 	mosfront.asm mostcb.inc mosscbdf.inc version.inc mboot.inc \
		options.inc group.inc dskstruc.inc macros.inc

mosback.obj  : 	mosback.asm options.inc group.inc

mosmisc.obj  : 	mosmisc.asm mostcb.inc mosscbex.inc options.inc group.inc \
		macros.inc

mosheman.obj : 	mosheman.asm options.inc group.inc macros.inc

mosliman.obj : 	mosliman.asm mostcb.inc moscdb.inc mosgfb.inc mosrlb.inc \
		mosbdb.inc mostfb.inc mosscbex.inc options.inc group.inc

mosrtask.obj : 	mosrtask.asm mosregs.inc mostcb.inc moscdb.inc mosgfb.inc \
		mostfb.inc mosrlb.inc mosscbex.inc options.inc macros.inc

mosmiman.obj : 	mosmiman.asm mostcb.inc moscdb.inc mosgfb.inc mostfb.inc \
		mosrlb.inc mosbdb.inc mosscbex.inc options.inc

mosint06.obj : 	mosint06.asm mosregs.inc mostcb.inc mosscbex.inc options.inc \
		group.inc macros.inc

mosint10.obj : 	mosint10.asm mosregs.inc mostcb.inc mosscbex.inc options.inc \
		group.inc macros.inc

mosint16.obj : 	mosint16.asm mosregs.inc mostcb.inc mosscbex.inc options.inc \
		group.inc macros.inc

mosint17.obj : 	mosint17.asm mosscbex.inc mostcb.inc moxspldt.inc options.inc \
		group.inc macros.inc

mosint28.obj : 	mosint28.asm mosregs.inc mostcb.inc mosscbex.inc options.inc \
		group.inc macros.inc

mosddtmc.obj : 	mosddtmc.asm mosregs.inc mostcb.inc mosscbex.inc options.inc \
		group.inc macros.inc

mosint15.obj : 	mosint15.asm mosregs.inc mostcb.inc mosscbex.inc options.inc \
		group.inc macros.inc

mosnxtsk.obj : 	mosnxtsk.asm mosregs.inc mostcb.inc mosscbex.inc options.inc \
		group.inc macros.inc

mosint74.obj : 	mosint74.asm mosregs.inc mostcb.inc mosscbex.inc options.inc \
				group.inc macros.inc

moscntxt.obj : 	moscntxt.asm mostcb.inc mosscbex.inc options.inc group.inc \
		macros.inc

mosddblk.obj : 	mosddblk.asm options.inc group.inc dskstruc.inc macros.inc

mosddclk.obj : 	mosddclk.asm mosscbex.inc mostcb.inc options.inc group.inc \
		macros.inc

mosddblf.obj : 	mosddblf.asm options.inc group.inc dskstruc.inc macros.inc

mosdevs.obj  : 	mosdevs.asm mostcb.inc options.inc group.inc macros.inc

mosddint.obj : 	mosddint.asm mosregs.inc mostcb.inc moscdb.inc mosbdb.inc \
		mosscbex.inc options.inc group.inc macros.inc dskstruc.inc

mosdebug.obj : 	mosdebug.asm mosregs.inc mosscbex.inc mostcb.inc options.inc \
		group.inc macros.inc

mosint21.obj : 	mosint21.asm mosregs.inc mostcb.inc mosbdb.inc mosscbex.inc \
		options.inc group.inc macros.inc

mosddcon.obj : 	mosddcon.asm mostcb.inc options.inc group.inc macros.inc

mosint13.obj : 	mosint13.asm mosscbex.inc options.inc group.inc mosregs.inc \
		macros.inc mostcb.inc

mossaver.obj : 	mossaver.asm mosregs.inc mostcb.inc mosscbex.inc options.inc \
		group.inc macros.inc

mosfun0f.obj : 	mosfun0f.asm mosregs.inc mostcb.inc moscdb.inc mosgfb.inc \
		mostfb.inc mosrlb.inc mosbdb.inc mosscbex.inc options.inc \
		group.inc macros.inc 

mosint38.obj : 	mosint38.asm mosregs.inc mostfb.inc mosgfb.inc mostcb.inc \
		mosscbex.inc moscdb.inc mosbdb.inc options.inc group.inc \
		macros.inc

mostemp.obj  : 	mostemp.asm mosregs.inc mostcb.inc moscdb.inc mosgfb.inc \
		mostfb.inc mosrlb.inc mosbdb.inc mosscbex.inc options.inc \
		group.inc dskstruc.inc macros.inc

mosinit.obj : 	mosinit.asm mosregs.inc mosscbex.inc options.inc \
		group.inc mostcb.inc macros.inc moscnf.inc

mostcb.pub : mostcb.inc
		public mostcb.inc

mosscbdf.pub : mosscbdf.inc
 		public mosscbdf.inc
