	include page.inc
	title	moxcpcor - find specified target in file(s)
	subttl	moxcpcor development specification
comment ^===============================================================
	     development specification

program name:	moxcpcor.com		assigned to: martin stitt
module name:	moxcpcor		assign date: 08/07/86
entry points:	moxcpcor		completed:
entry from:	mos
entry method:
purpose:
refer to:
last update:	08/04/92

=======================================================================

rbr 06/28/87	recognize ps/2 model 80 as having cmos

sah 07/07/87	added patch area to command processor
		and fix version check to ignore subsection

sah 07/20/87	added mos internal critical error handling
		ah=ffh	smp to small to load exe header

mjs 07/22/87	changed to org 0,  changed the first jump to
		jmp	core_entry to accomodate changes to mosinit which
		permit $$shell.sys to relocate to freemem

jsm 07/24/87	changed error number handling in critical error
		so that it displays reasonable messages for file and
		record locking errors.

sah07/27/87	reset int 38 to mosint38 to avoid conficts with apps
		like first choice

rbr 08/07/87	improve clock setting to handle ps/2 model 30.

mjs 8/16/87	added lf to delimset to accomodate 'command <pipe'
		initialized origin/out.  insured that parmbuf was
		converted back to an asciiz string when treating as an
		internal command.  converted ce38, ce39 and ce40 to
		subroutines and modified the code at ce29 to call
		ce38/39 to manage the 'command <pipe (or file)' case.
		modified code at ex10 to open a output redirection
		file in a manner which will work with the pipe driver.

sah 08/31/87	move setting int 38 (to resolve conflics with first
		choice) to after the external program is exec. so that
		internal commands can use int 38 (like copy)

sah 09/15/87	corrected bug with handling of %string% case where
		trying to replace %2\%1string (computer associates)

mjs 10/1/87	modify special entry into int24 to accept a pointer
		to a string.  this special entry was first established
		in order for exec to report insufficient smp with a pop
		up critical error window.  have now generalized to make
		usable by providing a pointer to a string rather than
		having special error numbers and coding the strings
		into this module.  this was done to support a pop up
		warning to say that a mos useirq should be done.

mjs 10/15/87	corrected sah's correction of bug with handling a string
		of the type %1\%2.
		added the %a batch variable to allow testing of the
		task id number.

sah 10/20/87	added fe special int 24 command so it doesn't display
		the press any key to continue message (for demo)

sah 10/23/87	move scbfar38 resetting to mosfun00, because of jsm
		addition of int 38 function 15 to terminate

sah 10/26/87	add reboot message to time out for demo version

mjs 11/25/87	fixed bug where would crash if did cntrl-c during a
		command using 'except' or 'only'.

mjs 12/16/87	clipper has a shell function which passes exec the wrong
		length for the command tail.  (its probably not their
		fault - the microsoft ms-dos programmer's Reference is
		misprinted/mistaken about the length.)	anyway, under
		dos, it doesn't cause a problem but had to modify MOS
		to be flexible enough to accomodate the proper way and
		the other way.
		if a batch file had the parameter:   %1x%2   mos was
		treating it as an environment string  %1x% followed by
		a trailing 2.  under dos, i found that you simply cannot
		have an environment string start with a number - only
		alpha.
		if a nested batch file did not have a crlf on its last
		line, it would not un-nest properly.  fixed by resetting
		the flag bateflg in the bateof logic

mjs 1/5/87	moved exec from code in ram to moxcpcor's code segment.
		mos's exec restores ss:sp so having the call in data ram
		was no longer necessary  also, was interfereing with
		sidekick's un-install function and protected mode does
		not allow mixed code and data.	also, need to refresh
		the internal copy of the path string before using it,
		just in case novell's login program has altered it.
		the patch $$shell1.pat was developed to implement this
		fix in release 2.10 of mos

mjs 2/9/88	changed/added messages related to the overhaul of the
		rename command.  added baeeflg to the stack of saved
		vars for batch file nesting to finally, properly fix
		the problem when a batch file calls another from its
		last line and there is no crlf on that last line.

sah 03/02/88	corrected bug with switch command made sure wordten is
		initialized - i falsely assume that data area was
		ok to put constants in them

sah 05/09/88	update copyright to include 1988

sah 05/12/88	change int 38 calls to use simulated int 38 calls by
		to an simulated int 38 call retrievd from scbfar38
		scb was retrived by doing a function 34h int 21 and
		deriving the start offset by the fact that 34h points
		to scbimos. (dataflex)

sah 07/15/88	corrected errorlevel handling, we should key current
		error level when processing internal commands

sah 08/22/88	correct my latest correction (07/15/88) for mos's specs
		by skiping cls on errorlevels

rkg 11/03/88	changes to facilitate foreign language translation

sah 11/28/88	allocated enviroment area for seperated mcb memory
		allocation.  by using map /d utility i found out that
		this is the way dos is doing it and it appears that
		sections of novell code depends on the fact that the
		command processors enviroment area be allocated
		seperately. until novell changes mosnet.com program so
		it does not depend on enviroment being in command
		processers data segment, use must to envsize of atleast
		440k or mosnet.com will lock up.

mjs 12/02/88	overhauled the code to initialize the environment.

rkg 12/05/88	changed critical error messages to variable length via
		minlen which returns length of aciiz less trailing ' 's

mjs 12/09/88	modified command parsing to skip preceeding control
		characters to accomodate the "command<pipe" case.

rkg 02/28/89	correct status returns from internal commands (errlvl)

sah 03/21/89	remove 386 reference, include 1989 in copyright for
		production.

sah 03/27/89	added special fd int 24 handler for making smoother
		protection exceptions from int 06 handler.

mjs 05/24/89	ptr141 changes marked with  ;!!  (for patch making).
		modified initial state of the dot command to be dot
		off.  fix problem with blank lines being inserted into
		a file produced with redirection. (ptr141)  added the
		inopen and outopen flags to handle redirction throughout
		multiple cycles of a for command. (ptr141)  added tests
		of the forscnt counter after the exec call and in the
		cmfl logic to prevent any redirection files from being
		closed prematurely. (ptr141)  removed a pop ds after
		the label prstat for rkg.

rkg 05/26/89	clear display before displaying new printer status.
		also check if key is available before pending on key

mjs 06/21/89	added code to manage the $compat$ environment variable.
		also put in fix at ce28 for "command /c x > nul"

sah 06/30/89	corrected message display for critical error, rkg's
		12/05/88 updated appears to have crash a register
		value which was being use to set drive.

sah 07/06/89	added code to change vector for int 23 to point to code
		in	data segment so that we can be compatible with tsr
		management utilities like load and unload

mjs 07/24/89	converted the command line parsing logic and the batch
		file processing logic to action charts.  cleaned up and
		restructured the logic.  corrected handling of ..\..\
		and a @ sign in front of a command line.  corrected
		handling of  command /cformat a:
		note: for a better understanding of the xif macros used
		in this file, see the comments in xifmacs.inc.
		note: for a better understanding of the logic in this
		module, see the file moxcpcor.cht in c:\mos.dir\cht.dir
		of the server.	this version of moxcpcor.asm was
		produced directly from flitering the action chart
		characters from moxcpcor.cht.

mjs 07/25/89	insure that a return code of 0 is set when the
		int21fun4c call is done at the end of command/c
		processing.

sah 08/14/89	corrected ctrl-c problem which generated the memory
		chain allocation lockup.  the problem was that error
		cleanup logic need ds to point to dataseg.

mjs 10/10/89	corrected register misuse problem in the int24 handler.
		this was making some critical errors show the wrong
		message in the pop up window.

mjs 11/02/89	modified issue of eol when exiting - skip if in /c mode.
		this prevents an extra newline on the console when
		using something like 'system("dir >nul");'

bwr 11/29/89	marked messages for foreign language translation.

mjs 12/19/90	changed "xif flags != zr"  to  "xif flags == nz"  to
		conform with new xifmacs.inc.

sah 01/10/90	made demo code always present, no need for moxcpcoe.com

mjs 01/18/90	added logic around the exec call to maintain the intd4
		vector in spite of the fact that the ibm basic interpreter
		leaves it pointing to garbage.

mjs 01/31/90	added logic around the exec of an external command
		to preserve/restore the intd4 vector when ibm's BASIC
		interpreter is used.
		converted the greater portion of this module to action
		chart format.

bwr 04/12/90	parmbuf now being cleared prior to command-line input
		at console in order to clear-up problems with some
		parse routines' inability to deal with junk left-over
		in	the buffer from previous command.

bwr 04/26/90	command processor now executes hidden files.  also, the
		invalid kcommand note "What?" has been changed to
		"Invalid command".

sah 05/01/90	change copyright to include 1990

mjs 07/23/90	corrected dot logic so if dot is on and someone enters
		an internal command without a dot, search externally
		first, then internally.

sah 08/03/90	corrections for legal size tray, rkg's additions
		cause problems problems because ptrdisp routine could
		not find end of list

bwr 11/9/90	corrected a problem with the cd command.  when the
		dot command mode was set to "on", the command cd\ (with
		no spaces) caused an "invalid command" error message.
		this was due to the logic not searching internal
		command tables upon failure to parse the command
		as an external filename.

bwr 11/15/90	whoops ... that last change caused an undesirable
		side-effect.  the cd\ command worked ok, but you could
		no longer execute a program by using its pathed name.
		back to the drawing board, so to speak.  this fix
		appears to have corrected the problem without the
		accompanying side-effect.

sah 11/19/90	corrected a problem with mos wait in loop batch file,
		doing a control-c from command /c of that batch file
		will cause the code to jump out in space because int 23
		jmp code was not initialize correctly.

sah 03/08/91	updated copyright to include 1991

bwr 3/21/91	fixed i/o redirection problem in which output file
		of zero length was created on a command that errored
		out.  ptr # 547

mjs 03/25/91	when a mistaken command was entered and output
		redirection was used, bwr's new logic deleted the
		zero length file but a handle was still left open.
		corrected the open handle problem by removing 
		the call to resetredir at bc.  the cmfl logic needs
		to see the ovrout flag set so it can do the right
		cleanup.
		added a new line to the bootmsg string to report
		the version number of $$shell.sys.  numbered this
		version as 4.12

mjs 05/01/91	added memory check to insure that an exec of 
		command.com done when only a little tpa is left 
		will be detected before memory beyond the tpa is used.
		numbered this version 4.13.

SAH 06/24/91	version 4.14, skip update date and time from CMOS if
		not task 0 or not /P 

mjs 07/02/91	version 4.15, corrected problem with ext logic after 
		ext19.  was causing improper i21f4e calls before and 
		after an exec.

mjs 07/16/91	version 4.16, corrected problem with open mode for 
		copy command.  actual code change was in moxcpint.  
		this file is updated because it contains the version
		number.

SAH 09/10/91    Version 4.17, corrected problem with Great Plains
RSR		install batch file. Need to convert tabs into spaces

SAH 12/18/91	Version 4.18, added %u to command processor which displays
		user id

RSR 02/03/92    Version 4.19, added functionality to NOT restore the
                screen if a graphics mode was present.

mjs 03/03/92	version 4.20, modified critical error logic to test
		the new tcbcacer flag to detect a flushing error.
		the kernel will no longer set the flshflg bit.  it
		will also always make a normal int24 call for a cache
		flushing error.  this was done to accomdate unisys u.k.
		a version of $$shell.sys was made using current
		server source as of this date except the 4.10 version
		of version.inc was used.

mjs 03/03/92	version 5.01.  no net change except that the internal
		version number was set to 5.01.  this was done to make
		sure that the 4.20 version (prepared for MOS 4.10) is
		uniquely identifiable.

mjs 03/07/92	make the environment segment pointer within the 
		parent psp point to the master environemnt.  this 
		is necessary for novell's login.exe when the dos 
		version number is above 3.2

SAH 04/16/92	Corrections for Access denied message when aborting 
		from a critical error.

================ 5.01 kernel ends here ====================================

SAH 08/04/92    Version 5.02 Well appears that Great Plains is playing 
                DOS Specific stuff....IE  shelling command.com with 
                "/E:384 /C file", So I made our shell support this command.

SAH 08/04/92    Version 5.03 when bruce made the changes for Reserved task
		he used bit 2 of INT 17h status to indicated reserve area
		INT 17h marks this as reserved (as in later use).  Well
 		with a disconnected printer or some strange LPT device that
		happens to toggle that device bit 2 could be active while
		bits 1 and bit 5 are not.... since MOSINT17 returns 13h
		to indicated reserved status, It would be best that command
		processor checks for 13h to display the reserved message.

mjs 08/12/92	version 5.04.  only change to this module is the 
		version number.  in moxcpsub, modifed getsetclass to
		use the new id4f31 function to read and set tcbcdft.
		this is so llpro can hook the function and manage
		copy/c across the network.
		also, corrected bug in signon (moxcppls) where the wrong
		segment override was used to reset tcb%rs0a and tcb%rs3f.
		patched into release 5.01 by updat501.sys version 1.08.

======================================================================^
	page
	subttl	moxcpcor macros, equates, data

include options.inc
include moxcpdat.inc
include macros.inc

double_quote	equ	'"'
pipe_bar	equ	'|'

cmd	group	codeseg

tcb	segment at	0beach
include mostcb.inc
tcb	ends

codeseg segment para
	assume cs:codeseg,ds:dataseg,es:dataseg
	org 0h

include moxcpcor.pub			; public defs (at least mosscbdf.pub)
include moxcpsxt.inc			; external declarations for moxcpsub

extrn cmdtbl : near
extrn plustbl : near
extrn ccommand : near
extrn cecho : near
extrn cdir : near
extrn cchdir : near
extrn cif : near
extrn ccls : near
extrn cda9 : near
extrn tim9 : near
extrn conly: near
extrn cexcept : near

include mosscbex.inc

;--------------------------- start of code -----------------------------

start:
	jmp	core_entry

; string constants and messages.

delimset db	';,= ',9,10,0		; set of delimiters
pthstr	 db	'PATH',0		; used to search the environment
prmstr	 db	'PROMPT',0
comspc	 db	'COMSPEC',0
cpatstr  db	'$COMPAT$',0
comstr	 db	'COM'
exestr	 db	'EXE'
batstr	 db	'BAT'
autoexec db	'AUTOEXEC.BAT',0
startbat db	'STARTBAT',0
nobat	 db	'Cannot find startup batch file:     ',0  ;@@xlat
termmsg  db	'End batch processing? (Y/N) $        ',0  ;@@xlat
yesmsg	 db	'Yes   '		;@@xlat
nomsg	 db	'No    '		;@@xlat
bootmsg  db	cr,lf
	 db	'(c) Copyright 1987-1992 The Software Link, Incorporated',cr,lf  ;@@xlat
	 db	'All rights reserved worldwide ',cr,lf  ;@@xlat
	 db	'$$SHELL.SYS version 5.04 ',cr,lf,0  ;@@xlat
dayofwk  db	'SunMonTueWedThuFriSat' ;@@xlat
versmsg  db	'PC-MOS Version ',0	;@@xlat
smlcms	 db	'COMMAND'
	 db	'.COM'			; this string added for initprogname
pausmsg  db	'Press any key to continue . . .           ',0	;@@xlat
isonstr  db	' set to on      ',0	;@@xlat
isoffstr db	' set to off     ',0	;@@xlat
echostr  db	'.ECHO',0
brkstr	 db	'.BREAK',0
verstr	 db	'.WVER',0
dotstr	 db	'.DOT',0
onstr	 db	'ON'
offstr	 db	'OFF'
prmstrg  db	'PROMPT='
pthstrg  db	'PATH=',0
volmsg1  db	cr,lf,'DISKID  ',0	;@@xlat
volmsg2  db	' is  ',0		;@@xlat
volmsg3  db	'NOT FOUND  ',0 	;@@xlat

;--------------------------- error message strings  -------------------------

errmsg1  db	'Invalid Command or Filename     ',0  ;@@xlat
errmsg2  db	'Invalid command form   ',0  ;@@xlat
errmsg3  db	'Invalid drive identifier   ',0  ;@@xlat
errmsg4  db	'Error creating file          ',0  ;@@xlat
errmsg5  db	'Error in I/O redirection    ',0  ;@@xlat
errmsg6  db	'Cannot find file        ',0  ;@@xlat
errmsg7  db	'Invalid directory name    ',0	;@@xlat
errmsg8  db	'Cannot open any more files      ',0  ;@@xlat
errmsg9  db	'Access not allowed       ',0  ;@@xlat
errmsg10 db	'Unspecified device failure  ',0  ;@@xlat
errmsg11 db	'Directory/file name too long  ',0  ;@@xlat
errmsg12 db	'Not enough memory available    ',0  ;@@xlat
errmsg13 db	'Invalid operand     ',0;@@xlat
errmsg14 db	'Invalid number of operands     ',0  ;@@xlat
errmsg15 db	'Directory name exists or     ',cr,lf  ;@@xlat
	 db	'contains invalid characters  ',0  ;@@xlat
errmsg16 db	'Invalid directory name    ',cr,lf  ;@@xlat
	 db	'or directory contains files          ',0  ;@@xlat
errmsg17 db	'No more space for environment   ',0  ;@@xlat
errmsg18 db	'New file already exists or   ',cr,lf  ; #210 ;@@xlat
	 db	'Access denied!   ',0	;@@xlat
errmsg19 db	'Cannot find Batch file       ',0  ;@@xlat
errmsg20 db	'Place disk with batch file in drive          ',0  ;@@xlat
errmsg21 db	'Cannot find label        ',0  ;@@xlat
errmsg22 db	'ON or OFF must be specified     ',0  ;@@xlat

errmsg23 db	'Write protect       ',0; 19 ;@@xlat
errmsg24 db	'Unit not known    ',0	; 20 ;@@xlat
errmsg25 db	'Not ready    ',0	; 21 ;@@xlat
errmsg26 db	'Invalid command   ',0	; 22 ;@@xlat
errmsg27 db	'Data  ',0		; 23 ;@@xlat
errmsg28 db	'Request header ',0	;	24 ;@@xlat
errmsg29 db	'Search  ',0		; 25 ;@@xlat
errmsg30 db	'Unknown disk     ',0	; 26 ;@@xlat
errmsg31 db	'Cannot find sector      ',0  ; 27 ;@@xlat
errmsg32 db	'Printer needs paper   ',0  ; 28 ;@@xlat
errmsg33 db	'Write    ',0		; 29 ;@@xlat
errmsg34 db	'Read   ',0		; 30 ;@@xlat
errmsg35 db	'File lock conflict          ',0  ; 32 ;@@xlat
errmsg36 db	'Record lock conflict         ',0  ; 33 ;@@xlat
errmsg37 db	'Wrong disk    ',0	; 34 ;@@xlat
errmsg38 db	'SMP full; FCB open    ',0  ; 35 ;@@xlat
errmsg39 db	'SMP full; record lock      ',0  ; 36 ;@@xlat
errmsg39x db	'Critical error block   ',0  ; 37   ;jrbu ;@@xlat
errmsg40 db	'Binary reads from a device not allowed           ',0  ; #215 ;@@xlat
errmsg41 db	'Copying a file onto itself not allowed              ',0  ; #216 ;@@xlat
errmsg42 db	'New file content lost before copy complete                       ',0  ; #217 ;@@xlat
errmsg43 db	'No more space on disk         ',0  ; #218 ;@@xlat
errmsg44 db	'.Return without .Call   ',0  ; #219 ;@@xlat
errmsg45 db	'Class change on a device not allowed                  ',0  ; #220 ;@@xlat
errmsg46 db	'Must use /M to move across directories                            ',0	; #221 ;@@xlat
errmsg47 db	'Requested Task not currently active on system      ',0  ; 37 ;@@xlat
errmsg48 db	' ',0			; #222	free$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
errmsg49 db	'Access denied!   ',cr,lf  ; #223 ;@@xlat
	 db	'New directory may already exist, or           ',cr,lf	;@@xlat
	 db	'Existing directory may be in use, or             ',cr,lf  ;@@xlat
	 db	'Globals not allowed       ',0	;@@xlat
errmsg50 db	'Cannot rename across drives                    ',0  ; #224 ;@@xlat

; the following table is used by the subroutine reporterror

emsgmac macro	p1, p2
	db	p1
	dw	offset cmd:&p2
	endm

emsgtbl label byte
	emsgmac 15,errmsg3
	emsgmac 2,errmsg6
	emsgmac 3,errmsg7
	emsgmac 4,errmsg8
	emsgmac 5,errmsg9
	emsgmac 31,errmsg10
	emsgmac 8,errmsg12
	emsgmac 19,errmsg23
	emsgmac 20,errmsg24
	emsgmac 21,errmsg25
	emsgmac 22,errmsg26
	emsgmac 23,errmsg27
	emsgmac 24,errmsg28
	emsgmac 25,errmsg29
	emsgmac 26,errmsg30
	emsgmac 27,errmsg31
	emsgmac 28,errmsg32
	emsgmac 29,errmsg33
	emsgmac 30,errmsg34
	emsgmac 32,errmsg35
	emsgmac 33,errmsg36
	emsgmac 34,errmsg37
	emsgmac 35,errmsg38
	emsgmac 36,errmsg39
	emsgmac 37,errmsg39x

; internal error codes
	emsgmac 200,errmsg1
	emsgmac 201,errmsg2
	emsgmac 202,errmsg5
	emsgmac 203,errmsg4
	emsgmac 204,errmsg11
	emsgmac 205,errmsg13
	emsgmac 206,errmsg14
	emsgmac 207,errmsg15
	emsgmac 208,errmsg16
	emsgmac 209,errmsg17
	emsgmac 210,errmsg18
	emsgmac 211,errmsg19
	emsgmac 212,errmsg20
	emsgmac 213,errmsg21
	emsgmac 214,errmsg22
	emsgmac 215,errmsg40
	emsgmac 216,errmsg41
	emsgmac 217,errmsg42
	emsgmac 218,errmsg43
	emsgmac 219,errmsg44
	emsgmac 220,errmsg45
	emsgmac 221,errmsg46
	emsgmac 222,errmsg48
	emsgmac 223,errmsg49
	emsgmac 224,errmsg50
	emsgmac 37,errmsg47

	db	0			; end of list marker

;=========== subprocedures

;======================================================================
;,fs
; low_mem
;
; in:	none
;
; out:	none
;
;,fe
;=====================================================================
low_mem proc near
	mov	al,8			; insuffienct memory
	call	reporterror
	true?	[popt]
	je	$
	mos	quit
low_mem endp

;======================================================================
;,fs
; bcd_to_binary 
;
; in:	ax = bcd number.
;
; out:	ax = binary equivalent.
;
;,fe
;=====================================================================
bcd_to_binary proc near
	push	bx
	mov	bl, al
	and	bl, 0fh
	shr	al, 1
	shr	al, 1
	shr	al, 1
	shr	al, 1
	mov	bh, 10
	mul	bh			;fix this!
	xor	bh, bh
	add	ax, bx
	pop	bx
	ret
bcd_to_binary	endp

;======================================================================
;,fs
; dotpath
;
; in:	ds:si -> string containing path.
;
; out:	al = 1 - path begins with ".\"
;	     2 - path begins with "..\"
;	     0 - otherwise.
;
;,fe
;=====================================================================
dotpath proc near
	xor	al, al
	cmp	byte ptr [si], '.'
	jne	dtp_exit
	inc	al
	cmp	byte ptr [si+1], '\'
	je	dtp_exit
	xor	al, al
	cmp	byte ptr [si+1], '.'
	jne	dtp_exit
	cmp	byte ptr [si+2], '\'
	jne	dtp_exit
	mov	al, 2
dtp_exit:
	ret
dotpath endp

;======================================================================
;,fs
; scan_cmd_table 
;
; in:	ds:bx -> command list
;	prsfcb holds name to search for
;
; out:	zr if match
;	 [cmdaddr] = address of command
;	nz if no match
;	 ax = errorcode
;
;,fe
;=====================================================================
scan_cmd_table proc near
	push	si
	push	di
	push	es
	push	cs
	pop	es

; search the command list pointed to by the bx register.  expect the
; name to be in prsfcb.

sct1:
	lea	si,prsfcb+1
	mov	di,bx
	add	bx,11
	cmp	word ptr es:[di], 0
	je	sct2
	mov	cx,4
	cld
	repe	cmpsw
	jnz	sct1

; get the flag which says whether or not this command should set
; or clear the errorlevel.
;
sct2:
	mov	al,es:[di+2]
	mov	[dointerr],al
	mov	ax,es:[di]

; set flags on address.  save address of command.

	pop	es
	pop	di
	pop	si
	or	ax,ax
	mov	[cmdaddr],ax
	ret
scan_cmd_table	endp

;======================================================================
;,fs
; shift_over_dot 
;
; in:	ds:si -> string starting with a dot.
;
; out:	ds:si -> start of modified string.
;
;,fe
;=====================================================================
shift_over_dot proc near
	push	si
	mov	assumint, 1		; search internally first.
	lea	cx, linebuf-1
	add	cx, lbufsize
	sub	cx, si			; calc size of remainder of linebuf
	cld
	mov	di, si
	inc	si
	rep	movsb			; shift linebuf back over the period
	pop	si			; si points to start of file name
	ret
shift_over_dot	endp

;======================================================================
;,fs
; bad_cmd
;
; in:	none
;
; out:	none
;
;,fe
;=====================================================================
bad_cmd proc near
	call	resetredir
	call	chainclr
	mov	al,200			; bad command or file name
	call	reporterror
	ret
bad_cmd endp

version label	byte
	include version.inc
vermsg	db	13,10,'Improper MOS Version',13,10,'$'

;----------------------- $$shell.sys entry point --------------------------

core_entry:

	mov	ax,offset [dataend]
	call	bytes2para
	mov	bx,ds:[2]
	mov	cx,ds
	sub	bx,cx
	cmp	bx,ax
	jae	cpc50
	call	low_mem
cpc50:


	lea	sp,[stacktop]		; initialize stack pointer
	sti
	mov	ah,30h
	mov	bx,ax
	mov	cx,ax
	mov	dx,ax
	int	21h
	cmp	ax, word ptr version
	je	cpc1

; if the version of the o/s is incorrect, report that fact and
; lock the system up here.

	mov	dx,offset vermsg
	mov	ax, cs
	mov	ds, ax
	mov	ah,9			; report wrong version and hang
	int	21h
	jmp	$
cpc1:

; the following is done because we can not assume that the int 38
; vector is pointing to scbfar38.

	push	es
	mov	ah,34h
	int	21h
	assume	es:nothing
	sub	bx,offset scbinmos
	movdd	[farcall38],es:[bx+scbfar38],ax
	pop	es
	assume	es:dataseg
	call	settcbseg
	call	settcbidnum
	resflg	[batch] 		; init flags
	resflg	[copt]
	resflg	[popt]
	resflg	[forend]
	setflg	[echostat]		; set echo on for console
	setflg	[batecdf]		; set echo on as default for batch files
	resflg	[copyfix1]
	resflg	[copyfix2]
	resflg	[copyfix3]
	resflg	[copyfix4]
	resflg	[copyfix5]
	resflg	[signfix1]
	resflg	[forfspec]
	resflg	[ovrout]
	resflg	[ovrin]
	resflg	[inopen]
	resflg	[outopen]
	setflg	[nodot] 		; default to dot off
	resflg	[batnonest]		; default to nested batch files
	resflg	[nointerr]		; default to internal cmds set errlvl
	resflg	[dointerr]
	mov	al,es:[18h]
	mov	[origin],al		; record original stdin and stdout
	mov	al,es:[19h]		; system handles
	mov	[origout],al
	mov	byte ptr [bkattr],7
	mov	byte ptr [directc],0
	mov	byte ptr [forscnt],0
	mov	byte ptr [batparms],0
	mov	byte ptr [extrbuf],0
	mov	byte ptr [parmbuf],0
	mov	byte ptr [batnest],0
	mov	word ptr [batend],0
	mov	byte ptr [errlvl],0
	mov	word ptr [forstke],0
	mov	word ptr [cforstkl],0
	mov	word ptr [tempseg],0
	mov	byte ptr [wactive],'N'	; window not active
	mov	word ptr [wordten],10	; sah save constant for switch
	mov	word ptr [envsize],128/16  ; default envsize value
;
	push	ds
	pop	es
	mov	si,80h			; read parameter length from psp
	mov	cl,byte ptr [si]
	cmp	cl,0
	lje	cpc3
	inc	si
	xor	ch,ch
	mov	di,offset [linebuf]
	call	copystr 		; copy the parameter line into linebuf
	mov	byte ptr [di],0
rescan:
	mov	si,offset [linebuf]
cpc4:
	xor	cx,cx
	mov	al,fslash
	call	scanstr 		; check for a /c option
	jz	cpc6
	mov	si,offset [linebuf]	; check for /p option
	xor	ah,ah
	mov	al,'P'
	call	getoption
	jnz	cpc7
	setflg	[popt]
cpc7:
	jmp	cpc3
cpc6:
	inc	si
	cld
	lodsb
	call	low2upper
	cmp	al,'E'
	jne	cpc6e
	mov	di,si
	lodsb
	cmp	al,':'
	jne	cpc4			; if not /E:xxxx then syntax error
	call	str2numdw		; convert it
	or	dx,dx
	jc	cpc4			; oops bad parameter
	call	bytes2para		; calc # of paragraphs
	mov	[envsize],ax
	mov	si,di
	mov	word ptr [si-2],2020h	; blank out the option in parmbuf
cpc6dloop:
	lodsb
	cmp	al,' '
	je	cpc6dexit
	cmp	al,'/'
	je	cpc6dexit
	mov	byte ptr ds:[si-1],' '
	jmp	short cpc6dloop
cpc6dexit:
	dec	si
	jmp	short rescan
cpc6e:
	cmp	al,'C'
	ljne	cpc4
	setflg	[copt]			; found a /c
	mov	word ptr [si-2],2020h	; blank out the option in parmbuf
	jmp	short rescan
cpc3:

;
; SAH 06/24/91 Move code below testing command line, check if /P is use and
; if /P is used and task is task 0 then update date and time

	cmp	[popt],true
	jne	cpc2
	cmp	[tcbidnum],0		; is this task 0
	jne	cpc2

; set the clock if an at class machine
; rod substituted the following code (8/7/87) to go thru the bios,
; generally to be less hardware-dependent and specifically to be
; compatible with the ps/2 model 30.

	xor	cx,cx
	mov	ah,04h			; get rtc date
	int	1ah
	or	ch,ch
	jz	cpc2
	xor	ah,ah
	mov	al,dl			; convert day of month
	call	bcd_to_binary
	mov	dl,al
	mov	al,dh			; convert month
	call	bcd_to_binary
	mov	dh,al
	mov	al,cl			; convert year
	call	bcd_to_binary
	mov	cl,al
	mov	al,ch			; convert century
	call	bcd_to_binary
	mov	bl,100
	mul	bl
	xor	ch,ch
	add	cx,ax
	mos	setdate
	mov	ah,02h			; get rtc time
	int	1ah
	xor	ah,ah
	mov	al,dh			; convert seconds
	call	bcd_to_binary
	mov	dh,al
	mov	al,cl			; convert minutes
	call	bcd_to_binary
	mov	cl,al
	mov	al,ch			; convert hours
	call	bcd_to_binary
	mov	ch,al
	xor	dl,dl
	mos	settime
cpc2:

; if at parent shell level, init var used to maintain intd4 in spite
; of the vector glomming done by the ibm basic interpreter

	push	es
	cmp	[popt],true
	jne	cpc9
	xor	ax,ax
	mov	es,ax
	movdd	[d4_parent],es:[0d4h*4],ax
	jmp	short cpc10
cpc9:

; if not at the parent level, need to search back and find the parent
; shell level.	set the current d4_parent vector from the same field
; within the actual parent.

	push	ds
	call	findparent
	pop	ds
	mov	bx,offset d4_parent
	movdd	[d4_parent],es:[bx],ax
cpc10:
	pop	es

; calc paragraphs for data and stack area and shrink the memory allocated
; for command.com to just what's needed.

	mov	ax,offset [dataend]
	call	bytes2para
	mov	bx,ax
	mos	modmem
	call	memcheck
	jnc	cpc12
	call	low_mem
cpc12:

; allocate mcb block for the environment and initialize it with data

	push	ds
	mov	ds,ds:[2ch]		; measure the size of the initial environment
	call	getenvsize		; returns paragraphs in ax
	pop	ds
	cmp	ax,[envsize]		; put the larger of ax or envsize into ax
	jnb	cpc13

	mov	ax,[envsize]
cpc13:
	mov	[envpara],ax		; record allocated size of enviroment
	mov	bx,ax
	mos	getmem			; allocate mcb for enviroment
	call	memcheck
	jnc	cpc14
	call	low_mem
cpc14:
	mov	[envaddr],ax

; now that an mcb block has been allocated for the new master environment,
; initialize it with the strings from the initial environment

	push	ds
	push	es
	mov	ds,ds:[2ch]		; make ds:si -> initial environment
	assume	ds:nothing
	xor	si,si
	mov	es,ax
	assume	es:nothing
	xor	di,di			; init es:di to point to position in
	xor	cx,cx			; memory for stock environment
	cld
cpc15:
	call	copystr 		; copy until find a double 0
	cmp	byte ptr [si],0
	jne	cpc15
	xor	al,al			; write the 2nd 0
 	stosb
	pop	es
	assume	es:dataseg
	pop	ds
	assume	ds:dataseg		; set prompt and path strings from

; make the environment segment pointer within the parent psp point 
; to the master environemnt.  this is necessary for novell's login.exe
; when the dos version number is above 3.2

	push	ax
	mov	ax,[envaddr]
	mov	ds:[2ch],ax
	pop	ax
	call	initprmpth		; the stock environment
	mov	byte ptr [extrcnt],0
	call	initprogname		; init the name in the tcb for mos map

; the following code was adder to initialize int 23 vector to code
; in data segement to jmp [$$shell.sys] : int 23 so that we can
; be compatible with tsr management programs like load and unload
; which dataease uses to mark and release tsr from memory

	push	di
	mov	di,offset [far23hnl]
	cld
	mov	al,0eah
	cld
	stosb
	mov	ax,offset [contbrk]
	stosw
	mov	ax,cs
	stosw
	pop	di
	cmp	[copt],false		; don't alter vectors or psp when /c
	jne	cpc17
	call	setvects		; update the vectors for 22-24h
	mov	si,0eh
	mov	ax,offset [far23hnl]
	mov	[si],ax
	mov	[si+2],ds
	mov	si,12h
	mov	ax,offset [criterr]
	mov	[si],ax
	mov	[si+2],cs
	push	es
	push	ax
	mov	ah,02h			; get scb address
	call	sim38			;sah simulate int 38 call
	pop	ax
	cmp	word ptr es:[bx+scbcin24+2],0
	jne	cpc18
	mov	word ptr es:[bx+scbcin24],ax
	mov	word ptr es:[bx+scbcin24+2],cs
cpc18:
	pop	es
	mov	si,10
	mov	ax,[si] 		; save terminate address (ip)
	mov	word ptr [pspterm],ax
	add	si,2
	mov	ax,[si] 		; save terminate address (cs)
	mov	word ptr [pspterm+2],ax
	mov	[si],cs 		; reset terminate address (cs)
	sub	si,2
	mov	ax,offset [cb3]
	mov	[si],ax 		; reset term addr (ip)
	mov	si,22
	mov	ax,[si] 		; save segment of parent
	mov	[pspparnt],ax
	mov	[si],ds 		; reset to my psp segment
	cmp	[popt],true
	jne	cpc19
	mov	si,38h
	mov	ax,offset [cb3] 	; set real terminate address
	mov	[si],ax
	mov	[si+2],cs
cpc19:
cpc17:
	mov	si,80h			; read parameter length from psp
	mov	cl,byte ptr [si]	; to decide where to go from here
	cmp	cl,0
	lje	cpc20
	cmp	[copt],true		; if a /c option, process the command
	jne	cpc21
	mov	si,offset [linebuf]
	mov	al,cr
	call	scanstr 		; replace the cr with a 0
	jnz	cpc22
	mov	byte ptr [si],0
cpc22:
	jmp	processlbuf
cpc21:
	cmp	[popt],true		; if /p option, process autoexec
	ljne	cpc24

; check for startup batch file

	push	cs
	pop	ds
	mov	si,offset [startbat]
	mov	di,offset [workbuf]
	xor	cx,cx
	call	copystr 		; put startbat in workbuf to
	push	es			; prep for envsearch.
	pop	ds
	call	envsearch		; search the environment
	ljc	cpc25			; no startbat string, must be bkg task
	mov	si,offset [attmpt1]
	xor	al,al
	call	writedrvpth
	call	findend
	mov	di,si
	mov	ds,[envaddr]
	assume	ds:nothing
	mov	si,bx
	mov	[attptr],offset [attmpt1]
	push	cx
	xor	cx,cx
	call	copystr 		; copy batch file name into attmpt1
	pop	cx
	mov	di,cx
	mov	si,cx
	call	findend
	inc	si
	xor	cx,cx
cpc26:
	cmp	byte ptr [si],0 	; copy remainder of environment back
	je	cpc27
	mov	ax,es			; over the string to be removed
	mov	es,[envaddr]
	call	copystr
	mov	es,ax
	jmp	cpc26
cpc27:
	mov	byte ptr ds:[di],0
	xor	bx,bx
	cmp	byte ptr [bx],0 	; manage null environment
	jne	cpc28
	mov	byte ptr [bx+1],0
cpc28:
	push	es
	pop	ds
	assume	ds:dataseg
	mov	si,offset [attmpt1]
	call	findend
	mov	di,si
	cld
	mov	al,'.'
	stosb
	mov	al,'B'
	stosb
	mov	al,'A'
	stosb
	mov	al,'T'
	stosb
	xor	al,al
	stosb
	mov	dx,offset [attmpt1]
	push	es
	pop	ds
	mos	fndfrst 		; see if the startup batch file exists
	jc	cpc29
	mov	si,offset [linebuf]
	mov	[mlstrt],si
	mov	byte ptr [extrbuf],0
	jmp	et22
cpc29:
	cmp	[tcbidnum],0
	je	cpc30
	mov	dx,offset [nobat]	; for bg, report that the startup
	call	csdispstr		; could not be found
	mov	dx,offset [attmpt1]
	call	dispstr
	call	dispeol
	jmp	cpc25
cpc30:					;else

; in fg, prompt for date and time

	setflg	[nullparm]		; keep cda9 and tim9 from looking
	call	dispeol 		; at the parm line for data
	call	cda9			; prompt for date
	call	dispeol
	call	tim9			; prompt for time
cpc24:
cpc20:
cpc25:
	call	dispeol
	mov	dx,offset cs:[bootmsg]
	call	csdispstr		; issue the sign on message
	call	dispeol
	call	dispver
	call	dispeol
	call	dispeol
issueprompt:
	mov	byte ptr [bkattr],7
	cmp	[echostat],true
	jne	cpc32
	call	dispprompt		; decode the prompt string and display
cpc32:

; remove any residual junk from parmbuf.  some parsing routines in
; command processor not able to deal with left-over junk even though
; a zero terminator is placed at the end of string.

	push	ax
	push	cx
	push	di
	mov	di, offset parmbuf
	mov	cx, 64
	xor	ax, ax
	rep	stosw
	pop	di
	pop	cx
	pop	ax

;--------------------------------------------------------------------------
; read the command line at the console from the user.
;
;    notice that the si register is placed 2 bytes before linebuf.  the
; two bytes are for int21 function 0a and have been allocated in moxcpdat,
; so no corruption will take place as it might seem here.  this is only
; done so "linebuf" can be referenced repeatedly without having to
; constantly adjust si forward 2 bytes to get at the command string.
;
;--------------------------------------------------------------------------
get_command_line:
	mov	si, offset linebuf
	mov	mlstrt, si		;save the start location for later.
	sub	si, 2
	mov	byte ptr [si], 128	;command can be up to 128 chars long.
	mov	dx, si
	mos	0ah			;read input line from console.
	mov	al, [si+1]		;get line length.
	xor	ah, ah
	add	si, ax
	add	si, 2
	mov	byte ptr [si], 0	;make command line asciiz.
	call	chkecho 		;is echo on or off?
	jz	processlbuf
	call	dispeol 		;display end-of-line. (cr/lf)
processlbuf:
	cmp	byte ptr linebuf, 0	;blank command-line?
	lje	ee4
	lea	si, linebuf		;si=>command line.
	cld

; dispose of any whitespace or delimeters at the beginning of the
; command line.

cpc34:
	lodsb
	call	testdelims		;is this a delimeter?
	jz	cpc34			;if so, skip it.
	cmp	al, 0			;end of line?
	lje	ee4			;if so, treat like blank line.
	dec	si			;point at start of command.
	mov	mlstrt, si		;save for re-use later.

; count chaining characters (skipping ones in double quotes) to determine
; if command chaining is being done.  (pipes and the like).

	resflg	chainflg		;reset chain flag.
	resflg	pipefile		;reset pipe flag.
	mov	byte ptr chaincnt, 0	;clear chain-count.
	mov	byte ptr quotlvl, 0	;set quote-level to 0.
cpc36:
	cld
	lodsb
	cmp	al, 0			;at end of line yet?
	je	plb250			;yes, jump out of loop.
	cmp	al, double_quote	;keep track of quote level.
	jne	cpc38
	not	quotlvl 		;reverse flag setting.
	jmp	short cpc36

; if this character is a piping symbol '|' and we're not inside
; a quoted string, then increment the chain counter.

cpc38:
	cmp	al, pipe_bar		;pipe symbol?
	jne	cpc36			;no, go for next char.
	cmp	quotlvl, 0		;yes.  are we in quotes?
	jne	cpc36			;if we are, don't count it.
	inc	chaincnt		;count chain character. (pipe)
	jmp	short cpc36		;go get the next char.

plb250:
	cmp	chaincnt, 0		;were there any piped commands?
	je	pcmd			;if not, go process command.
	setflg	chainflg		;yes.  set flag.
	mov	pipestat ,0

; process the command.

pcmd:
	resflg	specdrv
	resflg	specpath
	resflg	cpflg
	resflg	skipproc
	mov	byte ptr cmddrv, 0
	mov	byte ptr extrcnt, 0
	mov	word ptr cmdaddr, 0

; start at beginning of command line again.

	mov	si, mlstrt
	mov	assumint, 1		;internal command search first.
	call	passdelims		;find first non-delimeter.
	mov	bx, si
	xor	bp, bp
	cmp	al, '.' 		;internal dotted command?
	jne	cpc44
	inc	si			;skip past a dot if found and use
	mov	bp,1			;bp to indicate that a skip was done.
cpc44:
	call	parse			;decompose a pathed command.
	push	bx			;save current pointer to command line.
	mov	bx, offset cmdtbl	;internal command?
	call	scan_cmd_table		;was it found in the first table?
	jnz	cpc45
	mov	bx, offset plustbl	;check 2nd table.
	call	scan_cmd_table
	jnz	cpc45
	pop	bx			;get pointer back.
	mov	si, bx
; an internal command does not exist for this command.

	call	finddelim		;find the first delimeter.
	mov	dl, [si]		;save the delimeter
	mov	byte ptr [si], 0	;overwrite with a 0 for findfname.
	mov	di,si			;save its location
	mov	si,bx			;bx: original ptr to command.
	call	findfname
	mov	[di], dl		;restore the delimiter
	cmp	byte ptr [si], '.'
	jne	cpc52b
	call	shift_over_dot		;yep.  remove it.
	jmp	short cpc52b

; at this point an internal command was issued.

cpc45:
	xor	bp, bp			; cancel no match flag
	pop	bx
	mov	si, bx
cpc52:
	cmp	byte ptr [si], '.'
	jne	cpc52a
	call	shift_over_dot
	jmp	short cpc52b
cpc52a:

; if no dot was specified and "dot on", and the command is internal,
; then look externally first.

	cmp	nodot, 0
	jne	cpc52b
	cmp	cmdaddr, 0
	je	cpc52b
	mov	[assumint], 0
cpc52b:

; bx -> start of string, si -> start of file name portion
; if (bx <> si) - must be a d:\path search external only (set assumint = 1)
; if (bx = si) and (assumint = 1) - search internally first
; if (bx = si) and (assumint = 0) - search external first, then internal
;
; if bp != 0 and bx != si then they put a dot in front of the path.
; check for .\ and ..\ special cases.  if neither, then jump to bc
; (bad command)

	cmp	bx, si
	lje	cpc53
	cmp	bp, 0
	je	cpc54
	xchg	bx, si
	call	dotpath
	xchg	bx, si
	cmp	al, 0
	lje	bc
cpc54:
	mov	[assumint], 1		;assume an internal command.
	mov	si,bx
	mov	[begsi],si		;save beginning position.
	mov	di,offset [extrbuf]
	cld
cpc55:
	call	dotpath 		;check for .\ and ..\
	cmp	al, 0
	je	cpc56
	cmp	al, 1
	je	cpc57
	mov	al,'.'
	call	writeebuf
	inc	si
cpc57:
	mov	al,'.'
	call	writeebuf
	inc	si
	mov	al,'\'
	call	writeebuf
	inc	si
	mov	[begsi],si
	jmp	cpc55
cpc56:
	cmp	byte ptr [si], '\'
	jne	cpc58
	inc	si
	call	parse
	jmp	cpc62
cpc58:
	cmp	word ptr [si+1], '\:'
	jne	cpc61
	call	parse
	mov	bl,byte ptr [prsfcb]	; save drive spec
	inc	si
	call	parse			; parse past the bslash
	mov	byte ptr [prsfcb],bl	; restore the original drive spec
	jmp	cpc62
cpc61:
	call	parse
cpc62:
	jz	cpc64
	cmp	al, 1
	jne	cpc65
	call	bad_cmd
	jmp	eec
cpc65:
	mov	al,15			; invalid drive specification
	call	reporterror
	jmp	eec
cpc64:
	cmp	byte ptr [prsfcb+1], 0
	jne	cpc66
	cmp	byte ptr [prsfcb], 0	;check for a drive spec.
	je	cpc67
	mov	byte ptr [cmdtype],2	; mark as just a drive spec (ie 'a:')
	jmp	exc
cpc67:
	mov	al,[si]
	cmp	al, 0
	lje	eec
	call	testdelims
	ljz	eec
	mov	byte ptr [cmdtype], 1	; in case jump to plb600 is taken
	cmp	al, '\'
	lje	plb600
	cmp	al, '|'
	je	cpc68
	call	bad_cmd
	jmp	eec
cpc68:
	mov	al,201			; syntax error
	call	reporterror
	jmp	eec
cpc66:
	cmp	byte ptr [prsfcb], 0
	je	cpc69
	setflg	[specdrv]
	mov	al,byte ptr [prsfcb]
	add	al,64			; convert drive # to letter
	mov	[cmddrv],al
cpc69:
	jmp	cpc70
cpc53:
	cmp	byte ptr [assumint], 0
	jne	cpc72
	mov	[begsi],si		; external, then internal
	call	parse			; advance si to end of name
	push	si
	mov	di,offset [savename]	; save the internal name for
	lea	si,[prsfcb+1]		; later recovery if fail an
	mov	cx,8			; external search and need to
	call	copystr 		; cycle back around to ??? (ce13)
	pop	si
	mov	[savesi],si
	mov	di,offset [extrbuf]	; init pointer for call writeebuf
	jmp	cpc70
cpc72:
	mov	[begsi],si
	call	parse
ce13:					; non-structured entry !!!!!!
	mov	bx,offset [cmdtbl]
	call	scan_cmd_table
	jnz	cpc74
	mov	bx,offset [plustbl]
	call	scan_cmd_table
	jnz	cpc74
	cmp	[assumint], 2		;if fail internal search after
	lje	bc			;external, then --> bc.  else search
					;externally.
	mov	di,offset [extrbuf]
	mov	si,[begsi]
	call	parse
	jmp	cpc70
cpc74:

; is the command "COMMAND" ?

	cmp	ax, offset cs:[ccommand]
	ljne	cpc75

; copy the parameter portion of "linebuf" (after "COMMAND") to parmbuf.
; check for a drive / path specification while copying.

	xor	dx,dx			; reset flags.	dl = skip, dh = foundc
	xor	cl,cl			; cl = dsspec
	mov	di,offset [parmbuf]
cpc76:
	cld
	lodsb
	cmp	al, 0
	je	cpc77
	cmp	al, '|'
	jne	@f
	cmp	dh, 0ffh
	jne	cpc77
@@:
	cmp	al, '/'
	jne	cpc78
	cmp	dl, 0ffh
	je	cpc78
@@:
	cld
	stosb
	lodsb
	cmp	al, 0
	je	cpc77
	cmp	al, '|'
	jne	@f
	cmp	dh, 0ffh
	jne	cpc77
@@:
	call	low2upper
	cmp	al, 'C' 		;check for /c option
	jne	cpc79
	mov	dl,0ffh 		; skip further testing for drive/path
	mov	dh,0ffh 		; skip further testing for /c's
	jmp	cpc80
cpc79:
	cmp	al, 'P' 		;check for /p option.
	jne	cpc80
	mov	dl,0ffh 		; skip further testing for drive/path
cpc80:
	jmp	cpc85
cpc78:
	call	testdelims
	jz	cpc85
	cmp	al, '<'
	jne	cpc86
	call	ce38			; process the input redirection spec
	jmp	cpc85
cpc86:
	cmp	al, '>' 		; check for '>'
	jne	cpc88
	call	ce39			; process the output redirection spec
	jmp	cpc85
cpc88:
	cmp	dl, 0			; if not already in skip mode.
	jne	cpc85
	mov	dl,0ffh 		; set the skip flag
	mov	cl,0ffh 		; set the dsspec flag
	mov	[cppntr],di		; record the location of the string
cpc85:
	cld
	stosb
	jmp	cpc76
cpc77:
	xor	al,al
	cld
	stosb				; write ending marker
	push	cx
	dec	di
	sub	di,offset [parmbuf]
	mov	cx,di
	mov	[parmlen],cl		; set parmlen
	pop	cx
	cmp	cl, 0			; if cl==ff, found a path spec.
	jne	cpc91
	setflg	[cpflg]
cpc91:
	mov	byte ptr [cmdtype],3	; mark as 'COMMAND'
	jmp	exc
cpc75:
	mov	byte ptr [cmdtype],0	; code for internal command
	push	si
	mov	si,offset [parmbuf]	; convert parmbuf back to asciiz string
	mov	cx,128			; (the ending 0 may have been converted
	mov	al,cr			; to a cr for external command search)
	call	scanstr
	jnz	cpc92
	mov	byte ptr [si],0
cpc92:
	pop	si
	jmp	ppl
cpc70:
	mov	byte ptr [cmdtype],1	; cmdtype = 1 for an external
cpc93:
	mov	cx,si
	mov	bx,[begsi]		; copy the name from linebuf
	sub	cx,bx			; to extrbuf
cpc95:
	mov	al,[bx]
	call	writeebuf
	inc	bx
	loop	cpc95
	mov	al,[si]
	cmp	al, 0
	je	cpc97
	cmp	al, '|'
	je	cpc94
	cmp	al, '\'
	jne	cpc97
plb600: 				; non-structured entry !!!!!!
	setflg	[specpath]
	mov	al, bslash
	call	writeebuf
	inc	si
	mov	[begsi], si
	cmp	byte ptr [si], 0	; was path concatenated to command?
	je	cpc97
	call	parse
	jz	cpc98
	call	bad_cmd
	jmp	eec
cpc98:
	cmp	byte ptr [prsfcb+1], 0
	je	@f
	cmp	byte ptr [prsfcb], 0
	je	cpc93
@@:
	call	bad_cmd
	jmp	eec
cpc94:
	inc	si			; mlstrt as the start of the next
	mov	[mlstrt],si		; command of the chain
cpc97:
	xor	al,al
	call	writeebuf		; write an end of string marker

;--------------------------- process parameter line  -------------- (ppl) --

; check for any redirection specs, extracting any that are found into
; the appropriate buffer (inbuf or outbuf)

ppl:
	mov	dx,offset cs:[cecho]
	cmp	dx, cmdaddr
	jne	pp2
	mov	si,[mlstrt]		; when the command is echo, si must be
	call	passdelims		; adjusted so the parameter starts just
	call	skipdot
	add	si,4			; after echo, even for 'echo.abc'
	jmp	pp1

;======================================================================
;,fs
; skipdot
;
; in:	si -> parm
;	al = current char
;
; out:	if (al == '.') si++;
;
;,fe
;=====================================================================
skipdot proc near
	cmp	al,'.'
	jne	skd1
	inc	si
skd1:
	ret
skipdot endp

pp2:
	mov	dx,offset cs:[cdir]
	cmp	dx, cmdaddr
	jne	pp3
	mov	si,[mlstrt]		; when the command is dir, si must be
	call	passdelims		; adjusted so the parameter starts just
	call	skipdot
	add	si,3			; after dir, even for 'dir.com'
	jmp	short pp1
pp3:
	mov	dx,offset cs:[cchdir]
	cmp	dx, cmdaddr
	jne	pp1
	mov	si,[mlstrt]		; when the command is chdir, si must be
	call	passdelims		; adjusted so the parameter starts just
	call	skipdot 		; after cd or chdir
	add	si,2			; 'cd'

; if no dot and failed the external search, don't need to pass through
; here again after a successful internal search

pp1:
	mov	di,offset [parmbuf]
	true?	[skipproc]
	ljne	pp1a
	mov	al,[parmlen]
	xor	ah,ah
	add	di,ax
	mov	byte ptr [di],0 	; insure parmbuf ends with a 0 again
	jmp	ex1
pp1a:
	mov	word ptr [di-1],0	; init parmlen and parmbuf to 0
	mov	byte ptr [quotlvl],0
	cld
	lodsb
	cmp	al,0
	lje	exc
	cmp	al,'|'
	jne	ce34
	mov	[mlstrt],si		; if find a chaining char, update mlstrt to
	jmp	exc			; the start of the next command
ce34:
	cmp	al,'"'			; double quote
	jne	ce35
	not	byte ptr [quotlvl]
ce37:
	cld
	stosb				; write char to parmbuf
	lodsb
	jmp	ce34
ce35:
	cmp	al,0
	je	ce36
	cmp	byte ptr [quotlvl],0
	jnz	ce37
	cmp	al,'|'
	je	ce33			; found a chaining charactor
	cmp	al,'>'
	jne	ce39x
	call	ce39			; found an output redirection spec
	lodsb
	jmp	ce34
ce39x:
	cmp	al,'<'
	jne	ce37
	call	ce38			; found an input redirection spec
	lodsb
	jmp	ce34
ce33:
	mov	[mlstrt],si
ce36:
	xor	al,al
	cld
	stosb				; write a 0 on the end of parmbuf
	dec	di
	sub	di,offset [parmbuf]
	mov	cx,di
	mov	[parmlen],cl		; set parmlen
	jmp	exc

; this code converted from inline to subroutine on 8/15/87  mjs
; to support  'command <fred' type cases

; process an input redirection spec
; si points to parameter in linebuf (at the <)

ce38:
	setflg	[ovrin]
	push	di
	mov	di,offset [inbuf]
	mov	byte ptr [incnt],0
	mov	dl,1			; flag to indicate call writeinbuf
	call	ce40
	pop	di
	ret

; process an output redirection spec
; si points to parameter in linebuf (at the >)

ce39:
	setflg	[ovrout]
	resflg	[appflg]
	push	di
	mov	di,offset [outbuf]
	mov	byte ptr [outcnt],0
	mov	dl,0			; flag to indicate call writeoutbuf
	mov	al,[si]
	cmp	al,'>'			; if find a >>, set the append flag
	jne	ce39a
	setflg	[appflg]
	inc	si
ce39a:
	call	ce40
	pop	di
	ret

; copy the file spec to outbuf or inbuf based on reg dl
; si points to parameter in linebuf (after the < or >)

ce40:
	xor	bp,bp			; used as a flag to include the first
	cld				; period in a redirection spec
	lodsb
	call	testdelims
	je	ce40			; based on reg dl
ce41:
	cmp	al,0
	je	ce42
	cmp	al,'|'
	je	ce42
	cmp	dl,1
	jne	ce43
	call	writeinbuf
ce44:
	cld
	lodsb
	call	testdelims
	jne	ce41
	cmp	al,'.'			; if the delim is a period, and it is the
	jne	ce42			; first period, keep going.
	or	bp,bp
	jnz	ce42
	inc	bp
	jmp	ce41
ce43:
	call	writeoutbuf
	jmp	ce44
ce42:
	mov	byte ptr [di],0
	dec	si			; mjs 08/20/87
	ret

;------------------ command execution processing  ----------------- (exc) --

exc:
	cmp	byte ptr [extrcnt],ebufmax
	jna	exc001
	call	bad_cmd
	jmp	eec
exc001:
	true?	[chainflg]
	ljne	ex1
	cmp	[pipestat],0		; set up for chaining
	je	ex2
	cmp	[pipestat],1
	lje	ex7
	cmp	[pipestat],2
	lje	ex8
	cmp	[oldpstat],1
	jne	ex6
	mov	bx,[pfhandl2]		; pipestat must be 3, for the last command
	jmp	ex20			; of a chain
ex6:
	mov	bx,[pfhandl1]
ex20:
	call	redirin
	ljc	ex5
	call	resetout		; restore standard output to the console
	ljc	ex5
ex1:					; entry point when [skipproc] is true
	cmp	[cmdtype],2
	ljne	ex21			; the command was to change the default drive
	mov	dl,byte ptr [prsfcb]	; (ie 'A:') so get the drive letter
	dec	dl			; from the fcb
	mos	setdrv
	jmp	cmfl
ex2:					; pipestat = 0, first command of a chain
	setflg	[pipefile]
	mov	si,offset [pfname1]
	xor	al,al
	call	writedrv
	mov	si,offset [pfname2]
	call	writedrv
	mov	dx,offset [pfname1]
	xor	cx,cx			; normal attribute
	mos	unqfil			; create a unique file
	jc	ex3
	mov	[pfhandl1],ax		; save the handle
	mov	dx,offset [pfname2]
	mos	unqfil
	jc	ex4
	mov	[pfhandl2],ax		; create a 2nd unique file
	mov	bx,[pfhandl1]
	call	redirout		; redirect standard output to the 2nd file
	jc	ex5
	jmp	ex1
ex4:
	mov	bx,[pfhandl1]		; close and delete pipe file #1
	mos	closfil
	mov	dx,offset [pfname1]
	mos	delfil
ex3:
	mov	al,203			; file creation error
	call	reporterror
	resflg	[chainflg]
	resflg	[pipefile]
	jmp	eec
ex5:
	resflg	[ovrout]
	resflg	[ovrin]
	call	resetredir
	mov	al,202			; redirection error
	call	reporterror
	jmp	eec
ex7:					; pipestat = 1
	mov	bx,[pfhandl1]
	call	redirin 		; redirect standard input to the 1st file
	jc	ex5
	mov	bx,[pfhandl2]
	call	resetpipe
	jc	ex5
	call	redirout		; redirect standard output to the 2nd file
	jc	ex5
	jmp	ex1
ex8:					; pipestat = 2
	mov	bx,[pfhandl2]
	call	redirin 		; redirect standard input to the 2nd file
	jc	ex5
	mov	bx,[pfhandl1]
	call	resetpipe
	jc	ex5
	call	redirout		; redirect standard output to the 1st file
	jc	ex5
	jmp	ex1

; if no dot and failed the external search, don't need to pass through
; here again after a successful internal search.  the skipproc flag
; controls this.

ex21:
	true?	[skipproc]
	lje	ex14
	true?	[ovrin] 		; was an input redirection file spec found?
	jne	ex9			; if yes, open the file and redirect
	true?	[inopen]		; skip if already open
	je	ex9
	cmp	byte ptr [incnt],inmax
	lja	ex23
	call	resetin 		; to override chaining (if in use)
	mov	si,offset [inbuf]	; does the file spec end with a colon?
	call	findend 		; if yes, remove it.
	cmp	byte ptr [si-1],':'
	jne	exn1
	mov	byte ptr [si-1],0
exn1:
	mov	al,01000010b		; deny none, read and write
	mov	dx,offset [inbuf]
	mos	openfil 		; open the file for input redirection
	ljc	ex5
	mov	[ovrih],ax
	setflg	[inopen]		; record that its already open - in case we
	mov	bx,ax			; recurse through here (if, for, etc).
	call	redirin
	ljc	ex5
ex9:
	true?	[ovrout]		; was an output redirecton file spec found?
	ljne	ex14			; if yes, create or open the file and redirect.
	true?	[outopen]		; skip if already open
	lje	ex14
	cmp	byte ptr [outcnt],outmax
	lja	ex23
	call	resetout
	mov	si,offset [outbuf]	; does the file spec end with a colon?
	call	findend 		; if yes, remove it.
	cmp	byte ptr [si-1],':'
	jne	exn2
	mov	byte ptr [si-1],0
exn2:
	true?	[appflg]		; if a >> was found, open the file for
	jne	ex10			; appending.
	mov	dx,offset [outbuf]
	mov	al,01000010b		; deny none, read and write
	mos	openfil
	jnc	ex12
	cmp	ax,2			; error code for file not found
	je	ex10
	jmp	ex5
ex27:
	mov	al,31			; general failure
	call	reporterror
	jmp	eec
ex23:
	mov	al,204			; path/file name too long
	call	reporterror
	jmp	eec

; to work with pipe	(e.g.  dir >pipebuf)
; open the file
; if error -> ex10a to create it as before
; if a device, put handle in ax and -> ex13
; truncate the file, put handle in ax, -> ex13

ex10:
	mov	dx,offset [outbuf]
	mov	ax,3d41h		; deny none, write access
	int	21h
	jc	ex10a
	mov	bx,ax
	mov	ax,4400h		; see if the target is a device
	int	21h
	test	dx,80h
	mov	ax,bx			; handle in ax, just like return from 3c call
	jnz	ex13
	mov	ax,4000h		; truncate the file
	xor	cx,cx
	push	bx
	int	21h
	pop	ax
	jmp	ex13			; handle in ax, just like return from 3c call
ex10a:
	mov	dx,offset [outbuf]	; create a new file for redirected output
	xor	cx,cx
	mos	cretfil
	ljc	ex5
ex13:
	mov	[ovroh],ax
	setflg	[outopen]		; record that its already open - in case we
	mov	bx,ax			; recurse through here (if, for, etc).
	call	redirout
	jmp	ex14
ex12:
	push	ax			; for append, move the r/w pointer to the end.
	mov	bx,ax
	mov	al,2
	xor	cx,cx
	xor	dx,dx
	mos	lseek
	pop	ax
	jc	ex27
	jmp	ex13
ex14:
	cmp	byte ptr [cmdtype],0	; is the command an internal one?
	jne	ex28			; jump if not.
	setflg	[nullparm]		; test for null parmbuf
	cmp	byte ptr [parmlen],0
	je	ex29
	mov	si,offset [parmbuf]	; internal commands use the nullparm flag
	call	passdelims		; to detect whether parameters were entered.
	or	al,al
	jz	ex29
	resflg	[nullparm]
ex29:
	mov	dx,offset [conly]	; if the command to be executed is +only
	cmp	dx, cmdaddr		; or +except, don't set the claim bits
	jz	ex29a			; this is to manage multiple except/only
	mov	dx,offset [cexcept]	; commands which start a batch file
	cmp	dx, cmdaddr		; which contains cancel commands
	jz	ex29a
	xor	al,al			; internal command
	call	setclaim		; process any +except/+only list(s) that
	xor	al,al			; may exist
	call	getsetpre
	mov	al,1
	call	getsetact
ex29a:
	true?	[nointerr]		; don't clear errorlevel if
	je	ex29aa			; this flag is set
	true?	[dointerr]
	jne	ex29aa			; only clear errorlevel if the
	mov	[errlvl],0		; command is marked for same
ex29aa:
	jmp	cmdaddr 		; execute internal command
ex28:
	cmp	byte ptr [cmdtype],1	; is the command an external one?
	lje	ext
	resflg	[specpath]		; cmdtype must be 3, prep for 'COMMAND'
	mov	byte ptr [extrcnt],0
	mov	di,offset [extrbuf]
	true?	[cpflg] 		; true if no drive\path spec
	je	ex18
	mov	si,[cppntr]		; make si point to the start of the drive/path
	cld				; spec in parmbuf
ex15:
	lodsb
	call	testdelims		; copy the drive\path spec into extrbuf
	je	ex16
	cmp	al,fslash
	je	ex16
	cmp	al,0
	je	ex16
	cmp	al,bslash
	jne	ex17
	setflg	[specpath]
ex17:
	call	writeebuf
	jmp	ex15
ex16:
	cmp	byte ptr [di-1],':'	; if the drive\path spec doesn't end in
	je	ex18			; in a colon, make sure it ends with a \
	cmp	byte ptr [di-1],bslash
	je	ex18
	mov	al,bslash
	call	writeebuf
ex18:					; search the environment for a comspec string
	push	cs			; use the name on the right side of the = as
	pop	ds			; the name for the new shell
	push	di
	mov	si,offset [comspc]
	mov	di,offset [workbuf]
	xor	cx,cx
	call	copystr 		; put the string comspec in workbuf to prepare
	push	es			; for an environment search.
	pop	ds
	pop	di
	call	envsearch		; search the environment
	jc	ex18a
	mov	ds,[envaddr]
	jmp	ex18b
ex18a:					; if don't find a comspec string,
	push	cs			; stuff the string command in extrbuf
	pop	ds
	mov	si,offset [smlcms]
	mov	cx,8
	cld
ex18c:
	lodsb
	call	writeebuf
	loop	ex18c
	push	es
	pop	ds
	jmp	ex18d
ex18b:
	mov	bp,di			; save starting location of new string
ex18e:
	mov	al,[bx] 		; read a char from the comspec string
	call	writeebuf		; and write it in extrbuf
	inc	bx
	or	al,al
	jnz	ex18e
	push	es
	pop	ds
	true?	[cpflg] 		; true if no drive\path spec given
	je	ex18d
	mov	si,bp			; check for a drive\path spec in the comspec
	call	findfname		; string
	cmp	si,bp
	je	ex18d			; no drive\path in comspec string
	mov	di,bp
	call	findlen 		; when there are drive\path specs in both
	inc	cx			; the 'command' line and in the comspec string
	cld				; make the first override the second by
	rep	movsb			; copying the file name back over its path
ex18d:
	cmp	byte ptr [extrcnt],ebufmax
	lja	bc
	resflg	[specdrv]
	cmp	byte ptr [extrbuf+1],':'
	jne	ext
	setflg	[specdrv]

;-------------------- external command execution  --------------- (ext) ----

ext:
	mov	si,offset [extrbuf]
	xor	cx,cx
	call	str2upper
	mov	si,offset [parmbuf]	; initialize parmbuf for external
	call	findend
	mov	byte ptr [si],cr
	mov	ax,[envaddr]		; initiaize parameter block for
	mov	word ptr [execprm],ax	; exec call
	mov	si,offset [parmlen]
	mov	word ptr [execprm+2],si
	mov	word ptr [execprm+4],ds
	mov	si,offset [fcb1]
	mov	word ptr [execprm+6],si
	mov	word ptr [execprm+8],ds
	mov	si,offset [fcb2]
	mov	word ptr [execprm+10],si
	mov	word ptr [execprm+12],ds
	mov	si,offset [parmbuf]
ext1:
	mov	di,offset [fcb1]	; parse command tail into the default
	xor	al,al			; fcb's control byte
	mos	parsfil
	cmp	byte ptr [si],bslash
	jne	ext3
	inc	si
	jmp	short	ext1
ext3:
	mov	di,offset [fcb2]
	xor	al,al
	mos	parsfil
	cmp	byte ptr [si],bslash
	jne	ext2
	inc	si
	jmp	short	ext1
ext2:

; need to refresh the internal copy of the path string before using it,
; just in case novell's login program has altered it.  the patch
; $$shell1.pat was developed to implement this fix in release 2.10 of mos

	push	ds
	call	initprmpth
	pop	ds
	mov	si,offset [pathstr]	; init pathptr to manage parsing
	mov	[pathptr],si		; the pathstring copied from the
	mov	si,offset [extrbuf]	; environment
	mov	byte ptr [usedr2],0
	cmp	[specdrv],true
	jne	ext4
	mov	al,byte ptr [extrbuf]	; extract the specified drive letter
	add	si,2
	jmp	short	ext5
ext4:					;else				; when no drive is spec'ed in the
	mos	getdrv			; command read the current drive
	add	al,65			; and convert to a letter
ext5:
	mov	[usedr1],al
	mov	bp,si			; record starting point
	mov	dx,0ffffh		; init slash pointer
ext7:
	cld
	lodsb
	cmp	al,0
	je	ext8
	cmp	al,bslash
	jne	ext9
	mov	dx,si
ext9:
	jmp	short	ext7
ext8:
	cmp	dx,0ffffh
	jne	ext10
	mov	byte ptr [extpath],0	; when no backslash was found,
	call	copycmdname		; just copy the contents of extrbuf
	jmp	short	ext11		; into cmdname
ext10:					;else
	mov	si,dx			; if a backslash was found, dx points
	mov	di,offset [cmdname]	; to the next charactor
	cld
	mov	cx,9
ext13:
	lodsb
	stosb				; copy the command name into the
	cmp	al,0			; cmdname buffer
	je	ext14
	cmp	al,'.'
	je	ext14
	loop	ext13
ext14:
	cmp	al,0
	je	ext15
	dec	di
	xor	al,al
	stosb
ext15:
	mov	si,bp			; recover starting point
	sub	dx,si
	cmp	dx,63
	lja	bc
	mov	cx,dx
	mov	di,offset [extpath]	; copy the path name into the
	call	copystr 		; extpath buffer
	xor	al,al
	stosb				; write the 0 on the end
ext11:
	call	formpath		; develop a full drive\path\file
	ljc	bc			; name spec
	mov	byte ptr [ipass],1
ext16:
	mov	si,offset attmpt1
	cmp	byte ptr [ipass],1
	je	ext18
	mov	si,offset [attmpt2]
ext18:
	mov	[attptr],si
	call	findend
	sub	si,3			; prepare the string at attptr for
	mov	di,si			; search using find first/next by
	cld				; putting three ?'s on the end
	mov	al,'?'
	stosb
	stosb
	stosb
	resflg	[fndexe]		; search for the external file
	resflg	[fndbat]
	call	setdtaaddr		; try to find a com file first,
	mov	ah, 4eh 		; find first file.
	mov	cx, 2			; normal and hidden
	mov	dx,[attptr]		; but flag any exe or bat files
	int	21h
	ljc	ext19
ext20:
	mov	si,dtaaddr+30
	call	parse			; parse the returned string from the
	lea	si,[prsfcb+9]		; dta to locate the extension and
	mov	bp,si			; convert it to uppercase
	mov	cx,3
	mov	ax,es
	push	cs
	pop	es
	mov	di,offset es:[comstr]	; is it com?
	cld
	repe	cmpsb
	ljne	ext22
	mov	es,ax
	mov	si,offset cs:[comstr]
	call	et44			; put com on the end of the string
	jmp	ext23
ext22:
	mov	cx,3
	mov	di,offset es:[exestr]	; is it exe?
	mov	si,bp
	repe	cmpsb
	ljne	ext24
	setflg	[fndexe]
	jmp	short ext25
ext24:					;else
	mov	cx,3
	mov	si,bp
	mov	di,offset es:[batstr]	; is it bat?
	repe	cmpsb
	ljne	ext27
	setflg	[fndbat]
ext27:
ext25:
	mov	es,ax
	mov	ah, 4fh 		;find next file
	int	21h
	jnc	ext20			; the external
	cmp	[fndexe],true		; was an exe file found?
	jne	ext28
	mov	si,offset cs:[exestr]
	call	et44			; put exe on the end of the string
	jmp	short	ext23
ext28:
	cmp	[fndbat],true		; if not bat, goto error logic
	ljne	ext19
	mov	si,offset cs:[batstr]
	call	et44			; put bat on the end of the string
	jmp	et22
ext23:

; enter here when find a com or exe file

	xor	al,al
	call	setclaim		; process any +except/+only list(s)
	mov	al,1			; that may exist
	xor	si,si
	call	getsetact		; reset tcbactseg
	mov	si,[attptr]
	call	findfname
	call	setprogname
	xor	al,al			; copy kybd save buff to lcl storage
	call	getsetsbuf		; and null out tcb%rs0a/3f

; to maintain the intd4 vector in spite of the fact that the ibm
; basic interpreter leaves it pointing to garbage when its done with
; it, this logic saves the current d4 vector when not running at
; the parent shell level.  just in case this command shell level was
; entered from within the basic interpreter (e.g. shell), the intd4
; vector is reset if its found to be dirty from basic.

	cmp	[popt],true		; if not at the parent shell level
	je	ext29
	push	es
	xor	ax,ax
	mov	es,ax
	assume	es:nothing
	cli				; save the current d4 vector value
	movdd	[d4_child],es:[0d4h*4],ax  ; for later restoration
	sti
	call	d4_dirt_chk
	jz	ext30			; if d4 is basic dirty
	cli
	movdd	es:[0d4h*4],[d4_parent],ax  ; copy d4_parent to intd4
	sti
ext30:
	pop	es
	assume	es:dataseg
ext29:

; make the exec call (finally!)

	mov	ax,4b00h
	mov	dx,[attptr]
	mov	bx,offset [execprm]
	int	21h
	assume	ds:nothing, es:nothing
	push	ss
	pop	es
	assume	es:dataseg
	push	ss
	pop	ds
	assume	ds:dataseg
	pushf
	push	ax

; more logic to compensate for the basic interpreter's vector glomming.
; if at the parent shell level and intd4 is dirty from basic, reset
; it.  otherwise, refresh the reference copy - just in case intd4 has
; just been legitamately changed by a tsr or adddev.
; when not at a parent shell level, and intd4 is dirty from basic,
; restore it from the saved value before exec.	this way, exiting
; back into basic from a shell statement will leave intd4 as basic
; needs it.
; in the event that someone adddev's a driver which intercepts d4 and
; has done this from a non-parent shell level, the intd4 vector will
; be left alone for now.  when the non-parent shell exits back to the
; parent, the new intd4 vector will be copied into d4_parent.
; although you shouldn't install tsr's from a non-parent shell level,
; if someone does, the intd4 vector will also be managed.

	push	es
	xor	ax,ax
	mov	es,ax
	assume	es:nothing
	cmp	[popt],true		; if at parent shell level
	jne	ext31
	call	d4_dirt_chk
	cli
	jz	ext32			; if d4 is basic dirty
	movdd	es:[0d4h*4],[d4_parent],ax  ; copy d4_parent to intd4
	jmp	short	ext33
ext32:					;else				; copy intd4 to d4_parent
	movdd	[d4_parent],es:[0d4h*4],ax  ; to keep up with legitmate changes
ext33:
	jmp	short	ext35
ext31:					;else				; not at the parent shell level
	call	d4_dirt_chk		; if d4 is basic dirty, copy d4_child
	jz	ext37			; to intd4 to restore the environment
	cli				; expected by the basic interpreter
	movdd	es:[0d4h*4],[d4_child],ax
ext37:
ext35:
	sti
	pop	es
	assume	es:dataseg
	call	setvects
	call	initprogname
	mov	al,1			; restore kybd save buff from local
	call	getsetsbuf		; storage and null out tcb%rs3f

; reset any redirection which may be in effect

	cmp	byte ptr [forscnt],0
	jne	ext38
	cmp	[ovrout],true
	jne	ext39
	mov	bx,stdout
	mos	closfil
	resflg	[ovrout]
	resflg	[outopen]
	mov	bx,[ovroh]
	mos	closfil
ext39:
	cmp	[ovrin],true
	jne	ext40
	mov	bx,stdin
	mos	closfil
	resflg	[ovrin]
	resflg	[inopen]
	mov	bx,[ovrih]
	mos	closfil
ext40:
	call	resetredir
	jnc	ext41
	pop	ax
	popf
	mov	al,202			; redirection error
	call	reporterror
	jmp	eec
ext41:
ext38:
	pop	ax
	popf				; get flags from exec function
	jc	ext42
	mos	getret
	mov	[errlvl],al		; store return code for errorlevel
	cmp	ah,0
	je	ext43
	cmp	ah,3
	je	ext43
	call	chainclr		; must have exited via control break
	call	forclr			; or critical error abort
	call	batclr
ext43:
	jmp	cmfl			; all done, gone, bye
ext42:
	mov	byte ptr [errlvl],0
	cmp	ax,2			; test for 'workable' errors
	je	ext19
	cmp	ax,3
	je	ext19
	cmp	ax,5
	je	ext19
	cmp	ax,8			; if not 'insufficient memory'
	je	ext44
	mov	al,31			; then report general failure
ext44:
	call	reporterror
	jmp	cmfl
ext19:

; when the exec error was 2,3 or 5, try again with attmpt2 if it is not
; null and ipass=1, else jump to et24 to check for another path

	cmp	byte ptr [ipass],1
	jne	et24
	cmp	byte ptr [attmpt2],0
	je	et24
	mov	byte ptr [ipass],2
	jmp	ext16
et24:					; !!!!!!!! non-structured entry
	cmp	[specpath],true
	lje	notextcmd

; if a path was not spec'ed in the command, form another attempt

	mov	si,[pathptr]
	mov	[begsi],si
	cld
	lodsb
	cmp	al,0
	lje	notextcmd
	lodsb
	cmp	al,':'
	je	ext46
	dec	si
	dec	si
	mov	byte ptr [extpdr],0
	jmp	short ext47
ext46:
	mov	al,[si-2]
	mov	[extpdr],al
	mov	[begsi],si
ext47:
	lodsb
	cmp	al,0
	jne	ext50
	mov	bx,si
	dec	bx
	mov	[pathptr],bx
	jmp	short	ext49
ext50:
	cmp	al,3bh			; 3bh == ';'
	jne	ext47
	mov	[pathptr],si
ext49:
	sub	si,[begsi]
	dec	si
	cmp	si,63
	lja	bc
	mov	cx,si
	mov	si,[begsi]
	mov	di,offset [extpath]
	call	copystr
	xor	al,al
	stosb
	cmp	byte ptr [extpdr],0
	je	ext51
	mov	al,[extpdr]
	mov	[usedr1],al
	mov	byte ptr [usedr2],0
	jmp	short	ext52
ext51:
	mos	getdrv
	add	al,65			; convert drive # into letter
	mov	[usedr1],al
	cmp	al,[cmddrv]
	je	ext54
	mov	al,[cmddrv]
	mov	[usedr2],al
	jmp	short	ext55
ext54:
	mov	byte ptr [usedr2],0
ext55:
ext52:
	call	formpath
	ljc	bc
	mov	byte ptr [ipass],1
	jmp	ext16
et44:
	push	si
	mov	si,[attptr]
	call	findend
	sub	si,3
	mov	di,si
	pop	si
	push	ds
	push	cs
	pop	ds
	mov	cx,3
	call	copystr
	pop	ds
	ret


;======================================================================
;,fs
; d4_dirt_chk
;
; see if the intd4 vector looks like its been changed by the 
; ibm basic interpreter.
;
; in:	es -> 0
;
; out:	nz if d4 is dirty
;
;,fe
;=====================================================================
d4_dirt_chk proc near
	push	ax
	push	bx
	push	cx
	mov	ax,es:[0d4h*4+2]	; use segment of intd4 as reference
	mov	bx,0d0h*4+2		; check c0 through df for same seg
	mov	cx,20h
ext57:
	cmp	ax,es:[bx]
	jne	ext58
	add	bx,4
	loop	ext57
ext58:
	or	cx,cx			; set flags on loop counter
	pop	cx
	pop	bx
	pop	ax
	ret
d4_dirt_chk endp 


;============================ batch procedures ==========================

;======================================================================
;,fs
; openbat
;
; in:	none
;
; out:	none
;
;,fe
;=====================================================================
openbat proc near
	push	ax
	push	bx
	push	dx
opb1:
	push	si
	xor	al,al
	call	getsetact		; temporarily suspend any +except/+only
	mov	[tempseg],si		; list(s) which may be active
	xor	si,si
	mov	al,1
	call	getsetact
	pop	si
	mov	dx,[batptr]
	mov	al,0a0h 		; deny write, read access
	mos	openfil 		; use this mode to allow simultaneous
	pushf				; reads of a batch file from >1 task
	push	ax
	push	si
	mov	si,[tempseg]		; restore original tcbactseg
	mov	word ptr [tempseg],0
	mov	al,1
	call	getsetact
	pop	si
	pop	ax
	popf
	jnc	opb2

; when have an error trying to re-open the batch file, check media type
; to know which message to use

	mov	al,8			; read fixed\removable status
	mov	bx,[batptr]
	mov	bl,[bx] 		; read drive letter
	sub	bl,64			; and convert to 1 for a, 2 for b, etc
	mos	ioctrl
	cmp	al,0
	je	opb3
	mov	al,211
	call	reporterror		; 'Batch file missing'
	jmp	baterr
opb3:
	mov	al,212			; 'Insert disk with batch file'
	call	reporterror
	call	pausesubr		; wait for a key, then try again
	call	dispeol
	jmp	opb1
opb2:
	mov	[bathandl],ax		; save the handle for future calls
	pop	dx
	pop	bx
	pop	ax
	ret
openbat endp 

;======================================================================
;,fs
; closebat
;
; in:	none
;
; out:	none
;
;,fe
;=====================================================================
closebat:
	push	ax
	push	bx
	mov	bx,[bathandl]
	mos	closfil
	pop	bx
	pop	ax
	ret

;======================================================================
;,fs
; btdelim
;
; parse past a batch line's delimiters
;
; in:	ds:si -> buffer to be parsed.
;
; out:	si points to delim or end of buffer
;	al = stop character
;
;,fe
;=====================================================================

btdelset db	'\;,= ',9,10,0		; set of delims for batch parameter parsing

btdelim proc near
	cld
btd1:
	lodsb
	push	si
	mov	si,offset cmd:[btdelset]
	call	testset
	pop	si
	jz	btd2
	or	al,al
	cmp	al,0
	je	btd2
	jmp	btd1
btd2:
	dec	si
	ret
btdelim endp

;======================================================================
;,fs
; replc_parm
; 
; parm xferred into linebuf and tail concatonated back
;
; in:	ds:bp -> parm in batparms buffer
;	si = length of batparms entry
;	es:di -> parm's target location in linebuf
;	[attmpt1] holds linebuf's tail
;
; out:	none
;
;,fe
;=====================================================================
replc_parm proc near
	mov	cx,di
	sub	cx,offset [linebuf]
	mov	dx,cx			; calc present length of linebuf
	add	cx,si
	cmp	cx,128
	ja	bat060
	mov	si,bp
	xor	cx,cx
	call	copystr 		; copy the parm from batparms
	dec	di			; to linebuf
	mov	bp,di
	sub	di,offset [linebuf]
	mov	si,offset [attmpt1]
	call	findlen
	inc	cx			; inc to account for the zero
	add	cx,di
	cmp	cx,128
	ja	bat070
	xor	cx,cx			; ok to copy back entire string in
	mov	di,bp			; workbuf copy string back from
	mov	si,offset [attmpt1]	; attmpt1 and continue searching
	call	copystr 		; for % signs
	mov	si,bp
	ret
bat060:
	mov	cx,127
	sub	cx,dx			; calc truncated length for parameter
	mov	si,bp
	jmp	bat080
bat070:
	mov	cx,127			; calc amount of string in workbuf
	sub	cx,di			; which can be copied back
	mov	di,bp
	mov	si,offset [attmpt1]
bat080:
	call	copystr
	inc	si
	mov	byte ptr [si],0
	mov	bp,si
	ret
replc_parm endp 

;======================================================================
;,fs
; replc_envparm
;
; searches the environment for a replacement string and makes
; the replacement.
;
; in:	ds:si -> string
;	bx = length of string
;
; out:	none
;
;,fe
;=====================================================================
replc_envparm proc near
	push	ax
	push	bx
	push	cx
	push	si
	push	di
	push	bp
	mov	bp,si			; save si when find a %
	mov	di,si
	inc	si
	xor	cx,cx
	call	copystr 		; shift remainder back over %
	mov	cx,bx			; length of string in bx
	cmp	cx,0
	je	rce1
	mov	di,offset [workbuf]
	mov	si,bp
	call	copystr
	mov	byte ptr [di],0 	; copy the string to workbuf
	mov	di,offset [attmpt1]
	xor	cx,cx
	call	copystr 		; copy remainder of linebuf to attmpt1
	mov	si,offset [workbuf]	; convert the string to upper case
	xor	cx,cx
	call	str2upper
	call	envsearch		; look for string in the environment
	jnc	rce2
	mov	byte ptr [workbuf],0	; mark as null if don't find
	jmp	short rce3
rce2:					;else
	mov	si,bx
	mov	di,offset [workbuf]	; copy the right side of the
	xor	cx,cx			; string to workbuf
	mov	ds,[envaddr]
	call	copystr
	push	es
	pop	ds
rce3:
	mov	di,bp
	mov	si,offset [workbuf]	; calc length of replacement string
	mov	bp,si
	call	findlen
	mov	si,cx
	call	replc_parm
rce1:
	pop	bp
	pop	di
	pop	si
	pop	cx
	pop	bx
	pop	ax
	ret
replc_envparm endp 

;======================================================================
;,fs
; clean_exon
;
; clean up any +only/+except lists
;
; in:	none
;
; out:	none
;
;,fe
;=====================================================================
clean_exon proc near
clx1:
	xor	al,al
	call	getsetact
	cmp	si,0
	jne	clx3
	ret
clx3:
	push	es
	mov	es,si
	assume	es:nothing
clx4:

; flush all blocks with inbat not set or, if bp = 0, flush all blocks

	xor	di,di
	cmp	bp,0
	je	clx6
	test	byte ptr es:[di],1
	jz	clx6
clx7:
	xor	di,di
	test	byte ptr es:[di],1
	jz	clx2
	mov	ax,[batend]
	cmp	word ptr es:[di+3],ax
	cmp	word ptr es:[di+3],ax
	jne	clx2
	mov	si,es:[di+1]		; get next pointer
	mos	freemem
	call	memcheck
	cmp	si,0
	je	clx5
	mov	es,si
	jmp	clx7
clx6:
	mov	si,es:[di+1]		; get next pointer
	mos	freemem
	call	memcheck
	cmp	si,0
	je	clx5
	mov	es,si
	jmp	clx4
clx5:
	mov	al,1			; pointers
	call	getsetact
	call	getsetpre
	pop	es
	assume	es:dataseg
	jmp	clx1
clx2:
	mov	si,es
	mov	al,1
	call	getsetpre
	call	getsetact
	pop	es
	assume	es:dataseg
	ret
clean_exon endp 

;==================== start of main batch processing code =================
;&mbt

et22:
	mov	al,00100000b		; deny write, read only
	mov	dx,[attptr]
	mos	openfil 		; open as a batch file
	ljc	et24
	mov	[batptr],dx
	mov	[bathandl],ax
	call	resetredir		; cancel any redirection and chaining
	call	chainclr
	mov	si,offset [parmbuf]	; convert parmbuf back to an asciiz
	mov	cx,128			; string since the ending 0 was
	mov	al,cr			; converted to a cr for the external
	call	scanstr 		; command search
	mov	byte ptr [si],0
	call	dispeol
	cmp	[batch],false
	jne	mbt1
	setflg	[batch] 		; first batch file, no nesting
	jmp	mbt2
mbt1:					;else

; when starting a new batch file from within a batch file, must save
; data on the bat stack so the current batch file can be resumed.

	cmp	[batnonest],false	; don't nest if this flag is set
	jne	mbt4
	mov	bp,[batend]		; save current value for batend
	mov	ax,blksize		; initial value for byte count tally
	call	fixbatparms
	mov	si,offset [batparms]
	call	findlen 		; calc length of batparms
	add	ax,cx
	inc	ax			; to account for the 0 on the end
	mov	si,offset [batoldnm]	; of batparms
	call	findlen 		; calc length of batoldnm
	add	ax,cx
	inc	ax
	call	bytes2para		; calc paragraph size for the block
	mov	bx,ax
	mos	getmem
	call	memcheck
	jnc	mbt5
	mov	al,8			; insufficient memory to nest deeper
	call	reporterror
	call	closebat		; close the batch file
	jmp	baterr
mbt5:
	mov	[batend],ax		; update the end pointer to the list of
	push	es			; blocks on the stack
	mov	es,ax
	mov	di,blkback
	cld				; get the initial value for batend and
	mov	ax,bp			; write it in the stack block as a
	stosw				; back link.
	xor	al,al			; a descriptor of 0 is written in
	stosb				; the stack block to mark this block
	mov	al,[bateflg]		;  as being for a new batch file.
	stosb				; (a desc of 1 is for a +call block)
	mov	ax,word ptr [batline]	; save the r/w pointer
	stosw
	mov	ax,word ptr [batline+2]
	stosw
	mov	al,[batecho]		; save the current echo state
	stosb
	mov	ax,[batforse]		; save the state of the for stack
	stosw
	mov	si,offset [batparms]	; save batparms (%0-%9)
	xor	cx,cx
	call	copystr
	mov	si,offset [batoldnm]	; save the current batch file's name
	call	copystr
	pop	es
	inc	byte ptr [batnest]
mbt4:
mbt2:
	mov	al,1			; process any +except/+only list(s)
	call	setclaim		; that may exist
	xor	al,al
	call	getsetpre
	mov	al,1
	call	getsetact
	mov	ax,[forstke]		; update batforse to the level of the
	mov	[batforse],ax		; for stack at start of this file.
	cmp	byte ptr [forscnt],0
	cmp	byte ptr [forscnt],0	; if a for invoked this batch file
	je	mbt6
	call	forpush 		; then save status and clear any
	mov	byte ptr [forscnt],0	; for command in progress
mbt6:
	mov	si,offset [extrbuf]	; create new batparms string
	mov	di,offset [batparms]	; copy in value for %0
	xor	cx,cx
	call	copystr
	mov	byte ptr [di-1],' '	; make sure there's a delim
	mov	si,offset [parmbuf]
	call	passdelims
	call	copystr 		; copy in data for %1-%9
	call	updbattbl		; update the table of pointers
	mov	si,[batptr]
	mov	di,offset [batoldnm]
	mov	[batptr],di		; from now on, use batoldnm for
	call	copystr 		; the file name save the name in case
	mov	al,[batecdf]		; of more nesting
	mov	[batecho],al		; set the echo state from the default
	resflg	[bateflg]
	jmp	bat220			; non-structured jump !!!!!!!!!
mbt7:
batresume:
	cmp	[bateflg],true
	lje	bateof
	call	openbat 		; open the batch file
	mov	bx,[bathandl]
	mov	dx,word ptr [batline]
	mov	cx,word ptr [batline+2]
	xor	al,al
	mos	lseek			; get batline and seek the next line
	ljc	bater1
bat220: 				; non-structured entry point !!!!!
	call	readbatline		; read a line from the batch file
	pushf				; into linebuf
	call	closebat		; close the batch file
	popf
	ljnz	bateof
	mov	si,offset [linebuf]	; process linebuf for @ signs
	call	passdelims
	resflg	[bat@line]
	cmp	al,'@'			; when find a line beginning with
	jne	mbt9
	mov	byte ptr [si],' '	; an @ sign, flag that this line
	setflg	[bat@line]		; shouldn't be echoed
mbt9:
	mov	si,offset [linebuf]	; process linebuf for % signs
mbt10:
	xor	cx,cx
	mov	al,'%'
	call	scanstr
	ljnz	mbt11
	mov	bp,si			; save si when find a %
	call	btdelim 		; advance si to next delim or end
	mov	bx,si			; of string
	mov	si,bp
	inc	si
	mov	al,'%'
	call	scanstr
	jnz	mbt12
	mov	ax,bp
	inc	ax			; if find 2nd one right after 1st,
	cmp	si,ax			;  skip to bat240
	je	mbt12
	mov	di,si
	inc	di			; if delim after % then have a %str%
	cmp	bx,si			; case, else its a %str case
	jbe	mbt12
	mov	bx,ax
	cmp	byte ptr [bx],'0'
	jnae	xx00d5
	cmp	byte ptr [bx],'9'
	jbe	mbt12
xx00d5:
	mov	si,di
	dec	di			; shift remainder of linebuf
	mov	bx,di			; back over second %
	sub	bx,bp
	dec	bx			; calc length of string
	xor	cx,cx
	call	copystr
	mov	si,bp
	call	replc_envparm
	jmp	mbt10
mbt12:
	mov	si,bp
	mov	di,si
	inc	si     
	xor	cx,cx
	call	copystr 		; shift remainder back over %
	mov	si,bp
	cld
	lodsb				; check the char after the % sign
	push	si
	mov	di,offset [attmpt1]
	xor	cx,cx
	call	copystr 		; copy remainder of linebuf to attmpt1
	pop	si
	call	low2upper
	cmp	al,'A'
	jne	mbt13
	xor	dx,dx
	mov	ax,[tcbidnum]
	cmp	ax,0
	je	mbt14
	mov	bx,10			; convert id number into filename
	div	bx
mbt14:
	add	dl,'0'
	add	al,'0'
	mov	byte ptr [workbuf],al
	mov	byte ptr [workbuf+1],dl
	mov	byte ptr [workbuf+2],0
	mov	di,bp
	mov	bp,offset [workbuf]
	mov	si,3
	call	replc_parm
	jmp	mbt10
mbt13:
;
; SAH 12/18/91 Added %u variable to display current user
;
	cmp	al,'U'
	jne	mbtnum		; not %u than skip
	push	ax
	push	bx
	push	es
	mov	ah,04h		; verified that task exists
	mov	bx,-1		; get current task
	call	sim38		; SAH simulate INT 38 call
	assume  es:tcb
	mov	ax,word ptr [tcbuser]
	mov	word ptr [workbuf],ax
	mov	ax,word ptr [tcbuser+2]
	mov	word ptr [workbuf+2],ax
	mov	byte ptr [workbuf+4],0
	pop	es
	assume  es:nothing
	pop	bx
	pop	ax
	mov	di,bp
	mov	bp,offset [workbuf]
	mov	si,5
	call	replc_parm
	jmp	mbt10
mbtnum:
;
; if '0'-'9', replace with battabl parm
;
	cmp	al,'0'
	ljb	mbt10
	cmp	al,'9'
	lja	mbt10
	xor	ah,ah
	sub	al,48			; convert ascii 0-9 to binary 0-9
	mov	bx,offset [battabl]	; get base of table
	add	bx,ax			; add double the parm # as an offset
	add	bx,ax
	mov	di,bp
	mov	si,[bx] 		; get pointer of parm
	mov	bp,si
	call	findend
	sub	si,bp
	inc	si			; calc length of parameter (incl 0)
	call	replc_parm
	jmp	mbt10
mbt11:
bat270:
	mov	si,offset [linebuf]	; process linebuf for &str parameters
mbt15:
	xor	cx,cx
	mov	al,'&'
	call	scanstr
	ljnz	mbt16
	mov	bp,si			; save si when find a &
	call	finddelim
	mov	cx,si
	push	cx
	mov	di,offset [attmpt1]
	xor	cx,cx
	call	copystr 		; copy remainder of linebuf to attmpt1
	pop	cx
	mov	si,bp
	dec	cx
	sub	cx,si			; calc length (not counting the &)
	inc	si
	mov	di,offset [workbuf]
	call	copystr
	mov	byte ptr [di],0 	; copy the string to workbuf
	mov	si,offset [workbuf]	; convert the string to upper case
	xor	cx,cx
	call	str2upper
	call	envsearch		; look for string in the environment
	jnc	mbt17
	mov	si,bp
	inc	si
	jmp	mbt15
mbt17:
	push	bp
	mov	si,bx
	mov	di,offset [workbuf]	; copy the right side of string
	xor	cx,cx			; to workbuf
	mov	ds,[envaddr]
	call	copystr
	push	es
	pop	ds
	mov	di,bp
	mov	si,offset [workbuf]	; calc length of replacement string
	mov	bp,si
	call	findlen
	mov	si,cx
	call	replc_parm
	pop	si			; push'ed as bp
	jmp	mbt15
mbt16:
	mov	si,offset [linebuf]	; skip labels
	call	passdelims
	cmp	al,':'
	lje	mbt7
	mov	si,offset [linebuf]
	mov	[mlstrt],si
	call	dispplbuf		; depending on batecho,
	jmp	processlbuf		; display a prompt

;========================== batch file closeout ======================

bateof: 				; restore the for stack to its state
btc1:
	mov	ax,[batforse]		; when this batch file was started
	cmp	ax,[forstke]
	je	btc2
	call	forpop
	jmp	btc1
btc2:
	mov	ax,[batend]
	cmp	ax,0
	lje	btc3
	dec	byte ptr [batnest]
	push	es
btc4:
	mov	es,ax			; make es point to the top of the
	mov	al,es:[blkdesc] 	; bat stack check for any
	cmp	al,0			; +call/+return blocks and pop all off
	ljne	btc6
	mov	bp,1
	call	clean_exon		; clean up any +except/+only lists
	mov	ax,es:[blkback] 	; recover the data from the bat stack
	mov	[batend],ax		; restore batend
	mov	al,es:[blkeflg]
	mov	[bateflg],al
	mov	ax,es:[blkline]
	mov	word ptr [batline],ax	; restore batline
	mov	ax,es:[blkline+2]
	mov	word ptr [batline+2],ax
	mov	al,es:[blkecho]
	mov	[batecho],al		; restore batecho
	mov	ax,es:[blkfor]
	mov	[batforse],ax		; restore batforse
	mov	si,blkparm		; restore batparms
	push	ds
	mov	ax,es
	mov	ds,ax
	pop	es			; swap es and ds for copy
	mov	di,offset [batparms]
	xor	cx,cx
	call	copystr
	mov	di,offset [batoldnm]
	call	copystr 		; restore the file name into attmpt1
	push	ds
	mov	ax,es
	mov	ds,ax
	pop	es			; swap es and ds back again
	mos	freemem 		; free the bat stack block
	call	memcheck
	pop	es
	jnc	btc7
	resflg	[batch]
	mov	al,32			; general failure
	call	reporterror
	jmp	baterr
btc7:
	call	updbattbl		; update table of pointers for batparms
	jmp	eec
btc6:
	mov	bx,es:[blkback]
	mos	freemem
	call	memcheck
	xchg	bx,ax
	cmp	ax,0
	ljne	btc4
	pop	es
	mov	[batend],0
btc3:
	mov	bp,1
	call	clean_exon		; clean up any +except/+only lists
	resflg	[batch]
	jmp	eec

;===================== batch file error processing =====================

bater1:
	resflg	[batch]
	mov	al,31			; general failure
	call	reporterror
	call	closebat		; close the batch file
baterr:
	lea	sp,[stacktop]		; reset the stack pointer
	resflg	[batch]
	xor	bp,bp			; flush all +except/+only blocks
	call	clean_exon

; restore the for stack to its state when last at the command line

bfe1:
	mov	ax,[cforstkl]
	cmp	ax,[forstke]
	je	bfe2
	call	forpop
	jmp	bfe1
bfe2:

; entry point for contbrk sequence and for terminate address

bat_cbrk:

	mov	ax,[batend]		; flush the bat stack completely
	mov	[batend],0
bfe3:
	cmp	ax,0
	lje	eec
	push	es
	mov	es,ax
	xor	si,si
	mov	bx,es:[si]		; get the backlink
	mos	freemem
	call	memcheck
	pop	es
	jc	bfe4
	mov	ax,bx
	jmp	bfe3
bfe4:
	mov	al,32
	call	reporterror
	jmp	eec

;--------------------------- command followup  -------------------- (cmfl) --

cmfl:
	resflg	[dointerr]		; keep reporterr from setting errlvl
cmf1:
	xor	al,al			; process +except/+only list(s)
	call	getsetact
	or	si,si
	jz	cmf1a			; if tcbactseg=0, no list(s) exist
	push	es
	mov	es,si
	assume	es:nothing
cmf1d:
	xor	di,di
	test	byte ptr es:[di],1	; check the inbat flag
	jnz	cmf1b
	mov	si,es:[di+1]		; get next pointer
	mos	freemem
	call	memcheck
	or	si,si
	jz	cmf1c
	mov	es,si
	jmp	short cmf1d
cmf1c:
	mov	al,1
	call	getsetact
	call	getsetpre
	pop	es
	assume	es:dataseg
	jmp	short cmf1
cmf1b:
	mov	si,es
	mov	al,1
	call	getsetpre
	call	getsetact
	pop	es
	assume	es:dataseg
cmf1a:
	cmp	byte ptr [forscnt],0	; don't close down redirection
	ljne	cm2			; until done with for command
	true?	[ovrout]		; if output redirection was done, reset to
	jne	cm1			; normal and close the handle
	resflg	[ovrout]
	resflg	[outopen]
	mov	bx,stdout
	mos	closfil
	call	resetout
	ljc	ex5

; if nothing was written to the output file, delete it.

	mov	al, 1			; find file-pointer position.
	mov	bx, ovroh
	xor	cx, cx
	xor	dx, dx
	mos	lseek
	or	ax, dx			; if non-zero, keep the file.
	jnz	cmf1a_010

; the file is zero length.  close it, then delete it.

	mov	bx, ovroh
	mos	closfil
	ljc	ex5
	mov	dx, offset outbuf
	mos	delfil
	ljc	ex5
	jmp	short cm1
cmf1a_010:
	mov	bx, ovroh
	mos	closfil 		; handle still in bx.
	ljc	ex5
cm1:
	true?	[ovrin] 		; if input redirection was done, reset to
	jne	cm2			; normal and close the handle
	resflg	[ovrin]
	resflg	[inopen]
	mov	bx,stdin
	mos	closfil
	call	resetin
	ljc	ex5
	mov	bx,[ovrih]
	mos	closfil
	ljc	ex5
cm2:
	true?	[chainflg]		; if chaining is being done, prepare for the
	ljne	eec			; next command in the sequence.
	cmp	byte ptr [pipestat],0
	je	cm4
	cmp	byte ptr [pipestat],2
	je	cm4
	cmp	byte ptr [pipestat],1
	je	cm3
	call	resetredir
	jmp	eec
cm4:
	mov	bx,[pfhandl1]
	call	updpipe
	ljc	ex5
	mov	al,1
	call	updpstat
	jmp	cm5
cm3:
	mov	bx,[pfhandl2]
	call	updpipe
	ljc	ex5
	mov	al,2
	call	updpstat
cm5:
	dec	[chaincnt]
	ljnz	pcmd			; recycle to process command
	mov	byte ptr [pipestat],3
	jmp	pcmd

;--------------------- end of execution control  ------------- (eec) -------

eec:
	cmp	byte ptr [forscnt],0
	je	eec3
	resflg	[forstop]
	call	getforcmd		; if the for in do command is still active
	true?	[forstop]		; get the next command.  if forstop is set,
	je	eec3			; then ignore linebuf
	call	chkecho
	jz	eec2
	true?	[batch]
	je	eec2
	call	dispeol
eec2:
	call	dispplbuf
	jmp	processlbuf		; update linebuf from forsbuf and execute
eec3:
	true?	[forend]
	jne	eec1
	resflg	[forend]		; the command just done was the last of a
	true?	[batch] 		; for set so un-nest the for stack
	je	eec4
	cmp	word ptr [forstke],0
	je	eec1
eec5:
	call	forpop
	jmp	eec			; recycle to eec to provide for nesting of
eec4:					; for commands.
	mov	ax,[batforse]
	cmp	ax,[forstke]
	jne	eec5
eec1:
	call	chainclr		; reset chaining.
	true?	[batch] 		; if batch is true, resume batch file processin
	lje	batresume
	true?	[copt]			; skip the eol if in /c mode to keep
	je	ee2			; from messing up c's system()
	call	dispeol
ee2:
	true?	[copt]			; if the command was from a /c option, quit,
	ljne	issueprompt		; else recycle to the command prompt.
	xor	al,al
	mos	quit
ee4:					; for null line entry
	true?	[batch]
	lje	batresume
	jmp	ee2
notextcmd:
	cmp	[assumint],1
	lje	bc
	mov	[assumint], 2
	lea	di,[prsfcb+1]		; restore the internal command name
	mov	si,offset [savename]
	mov	cx,8
	call	copystr
	mov	si,[savesi]
	setflg	[skipproc]
	jmp	ce13			; non-structured jump !!!!!!!!

;---------------------- bad command (what?) ----------------- (bc) -------

bc:
	call	chainclr
	mov	al,200			; bad command or file name
	call	reporterror
	jmp	cmfl

;---------------------- control c   int 23h handler ---------- (contbrk) ---


;======================================================================
;,fs
; cb4part
;
; process the copyfix flags.  if abort via int 23 ro 24h
; during a copy or type command, the copyfix flags indicate that cleanup
; is needed.
;
; in:	
;
; out:	
;
;,fe
;=====================================================================
cb4part proc near
	true?	[copyfix1]
	jne	cb8
	resflg	[copyfix1]
	xor	al,al			; if copyfix1 is true, turn off verification
	mos	setverf
cb8:
	true?	[copyfix2]
	jne	cb9
	resflg	[copyfix2]		; if copyfix2 is true, release the memory block
	mov	ax,[copyseg]
	mov	es,ax
	mos	freemem
	call	memcheck
	push	ds
	pop	es
cb9:
	true?	[copyfix3]		; if # 3 is true, restore default
	jne	cb9a			; output class
	mov	dl,[origclass]
	mov	al,1
	call	getsetclass
	resflg	[copyfix3]
cb9a:
	true?	[copyfix4]		; if #4 is true, close the source
	jne	cb9b			; handle
	mov	bx,[srchndl]
	mos	closfil
	resflg	[copyfix4]
cb9b:
	true?	[copyfix5]		; is there a directory entry to be
	jne	cb9c			; deleted because of a full disk?
	resflg	[copyfix5]
	mov	bx,[trghndl]
	or	bx,bx
	jz	cb9d			; close the file if got that far
	mos	closfil
cb9d:
	mov	dx,offset [attmpt1]
	mos	delfil
cb9c:
	ret
cb4part endp

;======================================================================
;,fs
; cb4
;
; in:	
;
; out:	
;
;,fe
;=====================================================================
cb4 proc near				; clean up
	xor	al,al			; process +except/+only list(s)
	call	getsetact		; delete any and all blocks
	or	si,si
	jnz	cb4b			; if tcbactseg=0, no list(s) exist
	mov	si,[tempseg]
	or	si,si
	jz	cb4a
cb4b:
	push	es
	mov	es,si
	assume	es:nothing
cb4d:
	mov	si,es:[1]		; get next pointer	mjs 11/25/87
	mos	freemem
	call	memcheck
	or	si,si
	jz	cb4c
	mov	es,si
	jmp	cb4d
cb4c:
	mov	al,1
	call	getsetact
	call	getsetpre
	mov	[tempseg],si
	pop	es
	assume	es:dataseg
cb4a:
	resflg	[forfspec]
	cmp	word ptr [forstke],0
	lje	cb5
	call	forpop			; remove all data on the for stack
	jmp	cb4a
cb5:
	mov	byte ptr [forscnt],0
	call	cb4part
	true?	[ovrout]		; if output redirection was done, reset to
	jne	cb5a			; normal and close the handle
	resflg	[ovrout]
	resflg	[outopen]
	mov	bx,stdout
	mos	closfil
	mov	bx,[ovroh]
	mos	closfil
cb5a:
	true?	[ovrin] 		; if input redirection was done, reset to
	jne	cb5b			; normal and close the handle
	resflg	[ovrin]
	resflg	[inopen]
	mov	bx,stdin
	mos	closfil
	mov	bx,[ovrih]
	mos	closfil
cb5b:
	call	resetredir		; reset redirection just in case
					; user aborts from a critical error
	ret
cb4 endp

;----------------------- main code for int 23h handler -------------------

contbrk:
	sti				; restart interrupts
	push	ax
	push	bx
	push	cx
	push	dx
	push	si
	push	di
	push	bp
	push	es
	push	ds
	call	findparent
	mov	[directc],0
	true?	[batch] 		; set directc=1 so the terminate handler will
	jne	cb12			; know to prompt 'Terminate Batch Job?'
	mov	[directc],1
cb12:
	pop	ds
	pop	es
	pop	bp			; this ^c handler always does a retf with cy
	pop	di			; to force a termination
	pop	si
	pop	dx
	pop	cx
	pop	bx
	pop	ax
	stc
	db	0cbh			; code for a ret far

;------------------------ terminate entry point ------------------------

cb3:
	call	findparent		; find ds and es segment values
	mov	ax,es
	mov	ss,ax			; reset stack
	lea	sp,[stacktop]
	call	cleansign		; clean up signon information
	cmp	[wactive],'Y'		; is critical window active ?
	jne	cb3a
	push	cs			; ds & es assume to point to data segment
	pop	ds			; ds points to	code segment for constants
	call	restorewindow		; restore window and cursor
	push	es
	pop	ds			; ds points to	data segment
cb3a:
	call	resetredir
	resflg	[chainflg]
	resflg	[pipefile]
	call	dispeol
	cmp	[directc],0		; entered via ^c during a batch file ?
	lje	cb13a
	mov	[directc],0
cb10:
	call	dispeol
cb1:
	mov	dx,offset cs:[termmsg]	; disp msg 'Terminate batch job? (Y/N)'
	call	csdispmsg
	mov	al,6
	mov	dl,0ffh
	mos	getkey			; use this call to clear the buffer
cb6:
	mos	7			; loop until key press
	or	al,al			; extended key code?
	jnz	cb2
	mos	7			; get the extended code out of the buffer
	jmp	cb10			; don't want any key with extended code
cb2:
	mov	dl,al
	call	dispchar
	call	dispeol
	call	low2upper
	cmp	al,[yesmsg]
	je	cb13a
	cmp	al,[nomsg]
	jne	cb1
	call	cb4part 		; do partial cleanup
	jmp	batresume
cb13a:
	call	cb4
	true?	[batch]
	ljne	issueprompt
	resflg	[batch]
	call	cb4			; clean up
	jmp	bat_cbrk		; terminate the batch job

;-------------- critical error handler	int 24h ------------ (criterr) ------

;======================================================================
;,fs
; disp02
;
; in:	si -> string
;	cx = string length
;
; out:	none
;
;,fe
;=====================================================================
disp02 proc near
	push	ax
	cld
dsp1:
	lodsb
	call	wchar
	loop	dsp1
	pop	ax
	ret
disp02 endp

;======================================================================
;,fs
; ip12
;
; in:	
;
; out:	
;
;,fe
;=====================================================================
ip12 proc near
	push	ax
	push	ds
	call	findparent		; get data segment
	assume	ds:dataseg
	mov	al,[crit24al]		; get drive passed by int 24
	pop	ds
	add	al,'A'
	call	wchar
	mov	al,':'
	call	wchar
	pop	ax
	ret
ip12 endp

;======================================================================
;,fs
; dispwindow
;
; this subroutine will save the screen area defined in scndata	- also will
; display borders or window
;
; in:	ds assumed to point to code segment for constants
;	es assumed to point to data segment
;
; out:	
;
;,fe
;=====================================================================
dispwindow proc near
	push	ax
	push	bx
	push	cx
	push	dx
	push	si
	push	di
	push	bp
	mov	byte ptr es:[wactive],	'Y'  ; window is	active
	xor	bh,bh			; all page 0
	mov	ah, 3
	int	10h			; get cursor
	mov	es:[cursor],dx		; save it
	mov	dh,rt			; row upper right
	mov	dl,ct			; col
	mov	di,offset scrndata	; put their screen here
saveline:
	mov	ah,2			; set cursor pos
	int	10h
	mov	ah,8			; read char/attr
	int	10h
	stosw				; save in data area
	inc	dl			; next column position
	cmp	dl,cb			; end of line yet?
	jna	saveline		; do the whole line
	mov	dl,ct			; reset to start of next line
	inc	dh			; next row
	cmp	dh,rb			; last row yet?
	jna	saveline		; do all rows
	mov	dh,rt			; row upper right
	mov	dl,ct			; col
	mov	si,offset window	; our display screen
	mov	cx,1			; just writing one at a time
writline:
	mov	ah,2			; set cursor pos
	int	10h
	lodsb				; get char for our screen
	mov	bl,color		; white on blue
	mov	ah,9			; write char/attr
	int	10h
	inc	dl			; next column position
	cmp	dl,cb			; end of line yet?
	jna	writline		; do the whole line
	mov	dl,ct			; reset to start of next line
	inc	dh			; next row
	cmp	dh,rb			; last row yet?
	jna	writline		; do all rows
	pop	bp
	pop	di
	pop	si
	pop	dx
	pop	cx
	pop	bx
	pop	ax
	ret				; that's it all saved, back to you...
dispwindow endp

;======================================================================
;,fs
; restorewindow
;
; restores window and cursor of original screen before int 24
;
; in:	ds assumed to point to code segment for constants
;	es assumed to point to data segment
;
; out:	
;
;,fe
;=====================================================================
restorewindow proc near
	push	ax
	push	bx
	push	cx
	push	dx
	push	 si
	push	 di
	push	bp
	mov	byte ptr es:[wactive],	'N'  ; window not active
	mov	dh,rt			; row upper right
	mov	dl,ct			; col
	mov	si,offset scrndata	; get their screen from here
	mov	ah,0fh
	int	10h
        cmp     al,4
        jb      restx
        cmp     al,7
        jne     restskip
restx:
	mov	cx,1			; just writing one at a time
restline:
	mov	ah,2			; set cursor pos
	int	10h
	mov	ax, word ptr es:[si]	; get char & attribute
	inc	si
	inc	si
	mov	bl,ah			; attr goes in 'BL'
	mov	ah,9			; write char/attr
	int	10h
	inc	dl			; next column position
	cmp	dl,cb			; end of line yet?
	jna	restline		; do the whole line
	mov	dl,ct			; reset to start of next line
	inc	dh			; next row
	cmp	dh,rb			; last row yet?
	jna	restline		; do all rows
	mov	dx, es:[cursor]
	mov	ah,0fh
	int	10h
	mov	ah,2
	int	10h
restskip:
	pop	bp
	pop	di
	pop	si
	pop	dx
	pop	cx
	pop	bx
	pop	ax
	ret
restorewindow endp

;======================================================================
;,fs
; windlocate
;
; locates cursor at specified related cordinates of window
; where (0,0) is (rt,ct)	(top row, top column of window
;
; in:	
;
; out:	
;
;,fe
;=====================================================================
windlocate proc near
	push	ax
	push	bx
	push	si
	push	di
	push	bp
	add	dh,rt
	add	dl,ct
	mov	ah,0fh
	int	10h
	mov	ah,2
	int	10h
	pop	bp
	pop	di
	pop	si
	pop	bx
	pop	ax
	ret
windlocate endp

;======================================================================
;,fs
; wchar
;
; this routine writes character in al with color (equate)
; at current cursor position and cursor	is incremented
;
; in:	
;
; out:	
;
;,fe
;=====================================================================
wchar proc near
	push	ax
	push	bx
	push	cx
	push	dx
	push	si
	push	di
	push	bp
	push	es
	push	ax
	mov	ah,0fh
	int	10h
	mov	ah,3
	int	10h			; get cursor
	pop	ax
	mov	bl,color
	mov	ah,9			;d1 write char/attr
	mov	cx,1			;d1 one char
	int	10h
	inc	dl			;d1 next col
	mov	ah,0fh
	int	10h
	mov	ah,2
	int	10h			;d1 set new position
	pop	es
	pop	bp
	pop	di
	pop	si
	pop	dx
	pop	cx
	pop	bx
	pop	ax
	ret
wchar	endp

;======================================================================
;,fs
; wstr
;
; this routine writes a string at ds:dx terminated with color
; (equate) and cursor is increment.  assumes that string will
; fit in window and that it only works on one line at a time
;
; in:	
;
; out:	
;
;,fe
;=====================================================================
wstr proc near
	push	ax
	push	bx
	push	cx
	push	dx
	push	bp
	push	si
	push	di
	push	es
	mov	si,dx
	mov	ah,0fh
	int	10h
	mov	ah,3
	int	10h			; get cursor
wsloop	label	near
	cld
	lodsb
	cmp	al,'$'
	je	wsdone
	mov	bl,color
	mov	ah,9			;d1 write char/attr
	mov	cx,1			;d1 one char
	int	10h
	inc	dl			;d1 next col
	mov	ah,0fh
	int	10h
	mov	ah,2
	int	10h			;d1 set new position
	jmp	wsloop
wsdone	label	near
	pop	es
	pop	di
	pop	si
	pop	bp
	pop	dx
	pop	cx
	pop	bx
	pop	ax
	ret
wstr	endp

;   critical error window display defination

window	db	'ษออออออออออออออออออออออออออออออออออออออออออออออออออออออออออป'
	db	'บ       C R I T I C A L   E R R O R   D E T E C T E D      บ'	;@@xlat
	db	'วฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤถ'
	db	'บ                                                          บ'
	db	'บ                                                          บ'
	db	'บ                                                          บ'
	db	'บ                                                          บ'
	db	'ศออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผ'

ipmsg1	db	'Error:  $'		;@@xlat
ipmsg2	db	' reading $       '	;@@xlat
ipmsg3	db	' writing $      '	;@@xlat
ipmsg4	db	' flushing $     '	;jrbr ;@@xlat
ipmsg6	db	'Press any key to continue.$        '  ;@@xlat
ipmsg7	db	'Enter A to abort or R to retry         $          '  ;@@xlat
ipmsg8	db	'File Allocation table corrupted, drive $       '  ;@@xlat
ipmsg9	db	' while$  '		;@@xlat
ipmsgfd db	'Press <RETURN> to restart task or <ESC> to terminate$         '  ;@@xlat
ipmsgfd2 db	'Press <ESC> to terminate program$          '  ;@@xlat
ipmsgclr db	'                                                    $'

ipdemo	db	'Please reboot to start again.$           '  ;@@xlat

;----------------------------------------------------------------------

criterr:				; enter here from int 24h
	sti
	push	bx
	push	cx
	push	dx
	push	di
	push	si			; [bp+8] is orig si
	push	bp			; [bp+6] is orig bp
	push	ds
	push	es
	push	ax			; [bp] is orig ax
	mov	bp,sp
	push	ax
	call	findparent
	assume	ds:dataseg
	mov	[crit24al],al		; save drive
	push	cs
	pop	ds			; ds point's to constants
	assume	ds:codeseg
	call	dispwindow		; save window and display mine
	pop	ax
	cmp	ah,0fdh 		; is this special fd handler
	je	isint24 		; for protection exceptions
	cmp	ah, 0feh		; is this a special internal error
	jae	isint24 		; was ffh was equal
	jmp	notint24
isint24:
	push	ax			; save special code
	push	dx
	mov	dx,0404h		; locate
	call	windlocate
	pop	dx
	push	ds
	mov	ds,bx
	call	wstr
	pop	ds
	pop	ax			; get save special code

; the following is special logic which is use when mos has aborted
; out of a task because of a protection exception from int 06

	cmp	ah,0fdh 		; is this int 06 special handler
	jne	notfd
	mov	dx,0504h
	call	windlocate
	push	es
	mov	es,cx			; tcb is pass in cx
	assume	es:tcb
	mov	dx,offset ipmsgfd2	; indicate normal message
	cmp	[tcbid],0		; check if running task 0
	je	fddisp
	mov	dx,offset ipmsgfd	; indicate message for task 0
fddisp:
	pop	es
	assume	es:dataseg
	call	wstr			; write message out to user
fdloop:
	xor	ax,ax			; get a key using the bios
	int	16h
	cmp	al,27			; esc? means to terminate task
	je	donefd
	cmp	al,0dh			; return means to restart task
	jne	fdloop
	push	es
	mov	es,cx
	assume	es:tcb
	cmp	[tcbid],0		; can't restart task 0, so
	je	skipfd			; jusy terminate
	mov	[tcbcamon],0ffh 	; indicate that task need to be
skipfd: 				; restarted
	pop	es
	assume	es:dataseg
donefd:
	jmp	ip20			; exit out int 24 handle
notfd:
	cmp	ah,0feh
	jne	notfe			; not no press any key code
	mov	dx,050ch
	call	windlocate
	mov	dx,offset [ipdemo]	; display message about reboot
	call	wstr
	cli
	jmp	$			; hard lock
notfe:
	mov	dx,0504h
	call	windlocate
	mov	dx,offset [ipmsg6]
	call	wstr
	xor	ax,ax
	int	16h			; must call bios
	xor	ax,ax			; error out with ignore
	jmp	ip20
notint24:
	mov	dx, 0404h		; window logical cordinates of (4,4)
	call	windlocate		; locate in window
	test	ah,80h			; if bit 7 is set, device error,
	jz	ip2			; else disk error
	push	ds
	mov	ds,[bp+6]
	mov	ax,word ptr [si+4]
	test	ah,80h
	pop	ds
	jnz	ip2
	mov	dx,offset [ipmsg8]	; fat error
	call	wstr			; write string
	call	ip12			; drive 'al'
	jmp	ip14a
ip2:
	push	bx
	push	bp
	push	si
	push	di
	push	es
	mos	59h			; get extended error code
	pop	es
	pop	di
	pop	si
	pop	bp
	pop	bx
	cmp	ax,19
	jae	ip3
ip4:
	mov	al,31			; map the return code into the
	jmp	short ip5		; error message table
ip3:
	cmp	ax,31
	jbe	ip31			; if the error # must be translated
	cmp	ax,37
	ja	ip4			; if the # doesn't map properly
	jmp	short ip5		; if the # need not be translated
ip31:
	mov	al,19
	xor	ah,ah
	add	ax,di
ip5:
	mov	ah,al
	mov	si,offset [emsgtbl]
	cld
ip6:
	lodsb				; search error message table
	cmp	al,0			; for a match
	je	ip4
	cmp	al,ah
	je	ip7
	inc	si
	inc	si
	jmp	ip6
ip7:
	mov	dx,0404h		; logical window (4,6)
	call	windlocate
	mov	dx,offset [ipmsg1]	; 'Error: '
	call	wstr
	mov	si,[si]
	call	minlen
	call	disp02			; display the error message
	mov	dx,offset [ipmsg9]
	call	wstr			; ' while'
	mov	bx,[bp] 		; get the original ax
	test	bh,1
	jz	ip8
	mov	dx,offset [ipmsg3]	; writing
	push	es
	mov	es, [tcbseg]
	assume	es:tcb
	cmp	[tcbcacer],0		; is flushing flag set?
	pop	es
	assume	es:dataseg
	jz	ip9
	mov	dx,offset [ipmsg4]
	jmp	short ip9
ip8:
	mov	dx,offset [ipmsg2]	; reading
ip9:
	call	wstr
	test	bh,80h			; if bit 7=0, disk error
	jz	ip10
	mov	cx,8
	mov	si,[bp+8]		; get original si
	add	si,10
	push	ds
	mov	ds,[bp+6]		; get original bp
	call	disp02			; display device name
	pop	ds
	jmp	ip11
ip10:
	call	ip12			; drive 'al'
ip11:
	test	bh,30h
	ljz	ip14a
	push	es
	mov	es, [tcbseg]
	assume	es:tcb
	mov	al, [tcbdnum]		; get device in error
	mov	ah, [tcbcrit24] 	; and really critical flag
	pop	es
	assume	es:dataseg
	mov	[crit24], ah
	mov	[devnum], al
ip15:
	mov	dx,0504h		; logical window (5,4)
	call	windlocate
	mov	dx,offset [ipmsg7]	; abort, retry, ignore prompt
	call	wstr
ip16:
	cmp	[crit24], 0		; check if parallel printer error
	jnz	ip16c
ip16a:
	mov	dx,0606h		; logical window (6,6)
	call	windlocate
	mov	dx,offset ipmsgclr	; clear previous printer status
	call	wstr
	mov	dx,0606h		; display new printer status
	call	windlocate
	call	ptrstat 		; get printer's status
	xor	ah, 90h 		; now error status
	call	ptrdisp 		; display printer error status
	mov	dx,0530h		; place cursor for key input
	call	windlocate
	mov	ah, 7			; wait for time or a key
	mov	al, 3			; wake on timer or keystroke
	mov	bx, 90			; wait upto 5 seconds
	pushf
	call	[farcall38]		; simulate an int 38
	test	al, 1			; awakened from keystroke
	jnz	ip16b			; use keyboard input
	call	ptrstat 		; test printer is fixed
	cmp	ah, 90h 		; good printer status
	mov	al, 'R'
	je	ip19			; handle as retry
	jmp	ip16a			; loop until key or printer clears
ip16b:
	mos	0bh			; test key waiting
	or	al, al
	jz	ip16a			; no key there yet
	mos	8			; get the key
	jmp	ip16d
ip16c:
	mov	dx,0530h		; place cursor for key input
	call	windlocate
	mov	al,8
	mov	dl,0ffh
	mos	getkey			; use this call to clear the buffer
ip16d:
	or	al,al			; extended key code?
	jnz	ip17
	mos	8			; get extended code from buffer
	xor	al,al			; convert extended codes to null
ip17:
	call	low2upper
	cmp	al,'A'			; decode the key entered.
	jne	ip18a
	call	wchar			; send a to screen
	jmp	ip14
ip18a:
	cmp	al,'R'
	jne	ip18b
	call	wchar			; send r to screen
	jmp	ip19
ip18b:
	cmp	al,'I'
	ljne	ip15
	call	wchar			; send i to screen
	xor	al,al			; al=0 for ignore.
ip20:
	push	ax			; save ax for return
	push	ds
	call	findparent
	pop	ds
	call	restorewindow		; restore window and cursor
	pop	ax
	add	sp,2			; throw away the original ax
	pop	es
	pop	ds			; return to the point of the
	assume	ds:dataseg		; int 24h call
	pop	bp
	pop	si
	pop	di
	pop	dx
	pop	cx
	pop	bx
	iret
ip14a:
	mov	dx,0504h		; logical window (5,6)
	call	windlocate
	mos	8			; get a key and abort (lp14)
ip14:
	mov	al,2			; al=2 for abort
	jmp	ip20
ip19:
	mov	al,1			; al=1 for retry
	jmp	ip20

;--------------------------- error cleanup -------------------------

ecl1:
	mov	al,218			; disk full
	jmp	short eclean
ecl2:
	mov	al,8			; insufficient memory
	jmp	short eclean
ecl3:
	mov	al,5			; access denied
eclean:
	call	findparent		; make sure we have access to parent
	lea	sp,[stacktop]
	call	reporterror
	call	chainclr
	call	resetredir
	true?	[ovrout]		; if output redirection was done, reset to
	jne	ecm1			; normal and close the handle
	resflg	[ovrout]
	resflg	[outopen]
	mov	bx,stdout
	mos	closfil
	mov	bx,[ovroh]
	mos	closfil
ecm1:
	true?	[ovrin] 		; if input redirection was done, reset to
	jne	ecm2			; normal and close the handle
	resflg	[ovrin]
	resflg	[inopen]
	mov	bx,stdin
	mos	closfil
	mov	bx,[ovrih]
	mos	closfil
ecm2:
	call	forclr
	call	batclr
	call	dispeol
	true?	[copt]
	ljne	issueprompt
	mos	quit

;======================================================================
;,fs
; minlen	
;
; returns minimum length of string
; calls findlen then decrements for trailing spaces
; returns 1 for a string of spaces
;
; in:	ds:si -> asciiz string
;
; out:	cx = length of string - trailing spaces
;
;,fe
;=====================================================================
minlen proc near
	call	findlen 		; get length of string
	push	si			; save address
	add	si,cx			; points to terminating null
	jcxz	minlenxit
minlenlup:
	dec	si
	cmp	byte ptr[si],' '	; trailing space?
	loope	minlenlup		; loop for all spaces
	inc	cx			; correct last loop decr
minlenxit:
	pop	si
	ret
minlen endp 

; printer critical error strings

ptrdtsk db	'  0$'			; display task reserving printer
ptrdmor db	", $"
ptrdtbl db	20h, 20h, "Out-of-paper$       ", 0  ;@@xlat
ptrdres db	02h, 03h, "Reserved by task $     ", 0	;@@xlat
	db	10h, 10h, "Off line$         ", 0  ;@@xlat
	db	08h, 08h, "I/O error$        ", 0  ;@@xlat
	db	-1,  -1,  "Not ready$        ", 0  ;@@xlat
ten	db	10			; for task number conversion

;======================================================================
;,fs
; ptrstat 
;
; obtains printer status for int 24 auto retry code
; 
;
; in:	[tcbdnum] contains printer to stat
;
; out:	ah = printer status
;	al = printer number
;
;,fe
;=====================================================================
	assume	ds:codeseg, es:dataseg
ptrstat proc near
	push	dx
	xor	dx, dx			; get printer number of critical error
	mov	dl, [devnum]
	mov	al, dl
	mov	ah, 2			; get printer status
	int	17h
	pop	dx
	ret

; ptrdisp displays printer status in critical error window
; enter:	window and cursor initialized
;	ah = error bits from printer status call
;	al = printer number

ptrdisp:
	cmp	ah,13h 			; MOSINT17 reports back 13h on reserved
	je	ptrdsp0			; test printer reserved by another task
	call	ptresvd 		; setup task number and seconds
ptrdsp0:				; display why printer not reserved
	mov	bx, offset ptrdtbl	; table contains bit/message
ptrdlup:
	cmp	byte ptr [bx],-1	; end of list
	je	ptrdxit
	test	ah, [bx]		; was this an error
	jz	ptrdnxt			
	cmp	ah,13h			; was this the true reserve error
	je	ptrdgot			
	cmp	byte ptr [bx],2	     	; no...if reserved bit set, ignore
	jne	ptrdgot			;      reserve error	
ptrdnxt:
	inc	bx			; get to next error
	cmp	byte ptr [bx-1], 0
	jnz	ptrdnxt
	jmp	short ptrdlup
ptrdgot:
	mov	al, [bx+1]		; turn off some error bits
	not	al
	and	ah, al
	lea	dx, [bx+2]		; get message address
	call	wstr			; write message in window
	cmp	dx, offset ptrdres+2
	jne	ptrdtst 		; test if messages needs task number
	mov	dx, offset ptrdtsk
	call	wstr
ptrdtst:
	or	ah, ah			; any errors left
	jz	ptrdxit 		; exit if no more errors
	mov	dx, offset ptrdmor
	call	wstr			; else display ', '
	jmp	short ptrdnxt
ptrdxit:
	ret
ptrstat endp 

;======================================================================
;,fs
; ptresvd
;
; get and format the task number that has printer
;
; in:	al = physical printer number (0-2)
;
; out:	
;
;,fe
;=====================================================================
ptresvd proc near
	push	ax
	push	bx
	push	cx
	push	ds
	mov	ds, [scbseg]
	mov	ah, scbhldlen
	mul	ah
	mov	bx, ax			; find task holding printer
	add	bx, [scboff]
	mov	ax, ds:scbhldtask[bx]
	pop	ds
	mov	cx, 3
	lea	bx, [ptrdtsk+2] 	; convert to ascii string
ptreslup:
	xor	ah, ah
	div	[ten]
	or	ah, '0'
	mov	[bx], ah		; store digit in display string
	dec	bx
	or	al, al			; anything left?
	loopnz	ptreslup
ptrespc:
	cmp	bx, offset ptrdtsk
	jbe	ptresxit		; space remainder of display
	mov	byte ptr [bx], ' '
	dec	bx
	jmp	ptrespc
ptresxit:
	pop	cx
	pop	bx
	pop	ax
	ret
ptresvd endp 

codeseg ends
	end	start

