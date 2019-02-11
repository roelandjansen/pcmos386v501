	include page.inc
	title	mosinit2 - mos initialization module init segment
comment ^===============================================================
		development specification

 program name:	$$mos.com		assigned to: stewart hyde
 module name:	mosinit2		assign date: 08/06/88
 entry points:	mosinit2		completed:   10/06/88
 entry from:	mosinit
 entry method:	far call
 calls: 	mosheman, mosint21 (file i/o)
 purpose:	mos kernel initialization (disposalable init segment)
 refer to:	multilink module mlinit.inc
 last update:	08/18/1992
========================================================================

the cnfbuf segment is used to define the structure of the config.sys
data and the pointers used during its processing.  the segment will
actually reside in the system heap.  the ddtable is used to save
pointers to the device driver filenames since they are not loaded
until after the buffers and buffaddr commands are found.

========================================================================

mjs 10/21/88	remove all calls to linkdrv and modify all calls to
		mosddint to account for a new entry parameter.

sah 11/01/88	one line fix for intersegment jump to hperr

mjs 11/14/88	modified allocation of smp when loading config.sys
		device drivers.  must reserve some space so that bdb's
		and cdb's can be allocated.

sah 11/21/88	initialize scbtcbps, scbtcbvs and scbtcbvr to value
		contain in scbtcbpc.  this was necessary because when
		rework context and interupt logic to be not dependent
		on interupts being disable (also video dirty checks
		in interupts) a device driver isr would not be call
		during init time.  this is why novell driver was locking
		up during init becuase it appears that its int 8
		intercept is dependend on being called during init time

mjs 11/30/88	remove a tab code that was embedded in a string of
		blanks which is used to overwrite the crlf codes when
		the tilde character is detected in the config.sys
		processing logic.  [ya, i know its a runon sentence]

sah 12/04/88	move bootdrv to scb (renamed to scbbootdrv)

sah 02/13/89	made init code call initstation to initialize tcbstation
		before calling device drivers. this is necessary so that
		tcbstation can be correctly setup during config.sys time
		this is necessary for proper initialization of srterm

sah 02/21/89	made initp9 set mos services interupt if not set 38h

sah 02/24/89	removed logic for clearing 40:96 which is necessary with
		with microsoft word and the enhanced keyboards.

sah 03/02/89	slight correction to 02/21/89 so that my scbfar38 fix
		will be included even if services equals 38h

mjs 04/16/89	modify error handling after call to mosddint.

sah 07/26/89	initialization of scborg38 which is used in context
		handling of scbfar38

mjs 08/01/89	included xifmacs.inc.  converted readcnf to action chart
		and	fixed a bug in that routine.  reworked the
		managemet of the length of a device driver's parameter
		so that it can be greater than 256 chars.

mjs 10/19/89	moved the setting of scbfar38 so that it occurs before
		the call to initp8 (within initpc).  when device drivers
		are initialized, scbfar38 must be updated from relocation.

sah 11/01/89	copy serial # inplanted in init code to scbsmsg so that
		it can be later display to user.

bwr 11/28/89	marked messages for foreign language translation.

sah 12/08/89	conditional assemble 286 driver logic out.

sah 12/11/89	allocated command processor earlier, better freemem
		allocation.

sah 12/15/89	changes for split smp.

sah 01/10/90	changes for single version of code, dynamic # of users

mjs 01/17/90	moved setting of scborg38 to be where the master
		context is saved.  this var is actually part of the
		master context and must be set from scbfar38 after
		all device drivers have been loaded.  this must be done
		just in case a driver (e.g. lansat.sys) hooks scbfar38.

sah 02/06/90	added lidt support for int 74h (ps/2 mice)

mjs 03/07/90	added config.sys parsing logic for  disksw=n  to disable
		the int15 disk busy task switching feature.

sah 03/08/90	corrections for 6 digit serial #'s

sah 03/21/90	round up on smp reporting at end of initialization.

sah 04/04/90	added code to display error message if file can't be loaded
		into smp instead of locking up the system

sah 04/10/90	improve allocation by allocating smp #2 before command
		processor if larger and smp #2 is not indented to be
		loaded low with ldevice command.

sah 04/11/90	corrections for allocation smp for device drivers for split
		smp case, did not reserved space for cdb's and bdb's since
		these can be allocated out of the other smp

sah 04/12/90	if smpsize < 8k, force it to 8k so that mos will load

mjs 04/24/90	corrected problem with master password locking up the
		system.  after the call to ddtmc to register the master
		console, the return value in the es register was being
		lost.  as a result, the tcbkeyrdy pointer was garbage.

sah 04/25/90	corrections for lockup during disksw command.

sah 04/27/90	corrections for methods of undoing compaq's ega
		rom so that it work on compaq 386s (or other similar
		386sx machines).  this information was provided by
		compaq for best method of getting this job done.

mjs 05/17/90	initialize irq2 through 7 for lidt support

mjs 05/25/90	initialize scbirqbnk

mjs 06/08/90	modify init of irq's 2 through 7 to lidt mode.  must
		not	modify these vectors until after device drivers
		have been loaded by initp8.  otherwise, if an irq
		does occur, the bios handler will be in control and
		it will set the 8259 mask bit to prevent further
		irq's from coming through.

sah 06/08/90	changes for 10 digit serial #'s

mjs 07/17/90	parse the kbrate config.sys statement.	initialize the
		keyboard rate control logic.

sah 07/20/90	added patch table for controlling patches in future
		patch.com utility program. (4.10 will support this feature)

sah 07/26/90	change access keys so they are place into options.inc for
		easy changing between releases

mjs 08/02/90	convert kbrate control to use set_kbrate.  this function
		calls the bios int16fun0305 instead of doing the i/o
		directly.  ami 33 mhz machines required this (or much
		more detailed direct i/o).

sah 08/28/90	corrections for sysloading periscope in config.sys.
		config.sys needs to be transfer to offical heap so
		that when periscope does int 12h and initialize the
		memory it will not write over our config.sys data area

sah 08/30/90	move tranfer of freemem locations to before calling
		initp8 so that device drivers can verify that they
		don't have conflict with freemem areas

mjs 09/16/90	move point where scbfar21 is set to before init8.
		this was required to fix disk manager's dmdrvr.bin
		version 4.20 since it made an int21fun4b03 call
		during its init to load the xbios.ovl overlay file.
		this is only done when a drive has > 1024 cylinders.

sah 11/01/90	remove ems check, ems context switching is only use
		on ems 4.0 designed for mos.

sah 11/19/90	if no memory management, use default vtype

sah 01/22/91	corrections for device driver will be supported by
		undocumented dos techniques

sah 03/18/91	initialize scbioptr to point to io protection table
		for faster io protection access.

mjs 03/26/91	moved cnfbuf structure to moscnf.inc since both mosint
		and mosinit2 use it.
		increase max # of device= statements supported to 80
		add limit checking to logic which records device=
		statements.
		added logic to change 40:13 when device drivers are
		being loaded.  this is necessary because sysload/periscope
		does an int12 to see what part of the high base memory
		it can use.
		removed sah's changes of 08/28/90

SAH 03/28/91	Added KBBIOS config.sys command, also added a 512 byte
		patch area for INIT code, since all of init code goes
		away, we are suffuring anything by doing this

SAH 06/13/91	Change so that 'EXE' style device drivers can be loaded
	  	at config.sys time.  This was done for Adaptec SCII
		controller's device driver

SAH 09/11/91    Added code to initialize scbi10old before loading device
		drivers.  Also added lastdrive command in config.sys

SAH 09/23/91	Correction for 09/11/91 fix, needed to added a GRP override
		before accessing i10old

RBR 10/10/91    Corrections for CD-ROM exe device driver

mjs 12/16/91	dlg mods:  added a bootstrap segment with an "include
		mboot.inc".  added an "include dskstruc.inc" because
		mboot.inc needs the structure definitions in that file. 
		this was all done because the logic above the dftpart label
		needs to reference the [drive] field within the partition
		boot record.  previously, this access was done through a
		hard-coded offset.

SAH 01/14/92	Display error message and do not allow VTYPE f option if
		base memory is not a multible of 64k

SAH 03/17/92	Set SCB4013 to value at 40:13,   also change setting
		of tcbendad to a calculation from SCB4013.

SAH 03/23/92	Added DOSVER= config.sys command

SAH 03/26/92	opps, need to make sure DOSVER is not the same as the
		version of MOS

================ 5.01 kernel ends here ====================================

mjs 08/08/92	when scbgfbpf is reset within initpc, must also reset
		scbgfbpl.  otherwise, the tests that compare these
		two in mosliman could be confused.

mjs 08/18/92	clean up segment declarations

=======================================================================^

.xlist
;	include mosinit2.pub
	include options.inc
	include group.inc
	include macros.inc
	include mosregs.inc
	include	dskstruc.inc
	include moscdb.inc
	include mosbdb.inc
	include	moscnf.inc
	include mospsp.inc

bootstrap segment at 0
	include	mboot.inc
bootstrap ends

tcb	segment at 1234h
	include mostcb.inc
tcb	ends

gdata	segment
	include mosscbex.inc
gdata	ends
.list

gdata	segment
	extrn	fgtcboff:near,ddtmctcb:word,mcsnow:byte,gend:byte
	extrn	initpsp:byte, trueboot:byte
gdata	ends

features equ	0600h			; special memman features bits
dftck	equ	16			; 16k default for cache
dftcbk	equ	2			; 2k default for cache unit of buffering
tmpck	equ	16			; 8 cache elements to start
tmpcbk	equ	2			; 2k buffers to start
dftcwpcnt equ	60			; 65% default of cache available for write buffering
dftcbits equ	4			; 4k bits bit map default
tmpcbits equ	4			; 4k bit map to start

cfmos	macro	addr
	mov	word ptr cs:[imosaddr], offset	addr
	call	camos
	endm

irq	segment
	extrn	irqstart:byte, irqend:byte
	extrn   i10old:dword
irq	ends

poll	segment
	extrn	pollstart:byte, pollend:byte
poll	ends

;======================================================== ddt segment
if 0 eq 0
segment_num = 2
endif
ddt	segment
	extrn	mo1seg:word,mcterm:near,mo2end:byte
	extrn	grpseg2:word		;031288
	extrn	lidtint09:near
ddt	ends

;======================================================== mos segment
if 0 eq 0
segment_num = 1
endif
mosseg	segment
	assume	cs:mos,ds:nothing,es:nothing,ss:nothing

	extrn	gseglen:word, mapvmf:near, mapvsf:near, scanguts:near
	extrn	sbios:word, sinit:word, sinitaddr:word, curmode:byte
	extrn	ifar21:near, mosheman:near, dispmos:near, mosddint:near
	extrn	updfree:near, drverr:near, initstation:near, scbnul:word
	extrn	mosend:byte, mosint21:near, hex2asc:near, hperr:near
	extrn	grpseg1:word, cnfseg:word, mosaddr:word, scbfree:word
	extrn	dmlist:word, dmpatch:word, dmbuffr:word, mosstdclk:near
	extrn	scbstdcon:near, scbcom24:near ,smthere:byte, tmpheap:word
	extrn	scbstdblk:near, scbstdhd:near, tmphpsiz:word, patdemo2:near
	extrn	ddtcallf:near, dmflags:byte, mosaddr:word, initmcb:near
	extrn	inidvars:near, cpres:byte, bugopen:byte, bugshell:near
	extrn	mosoldfn:near, initp7:near, clobber:byte, lidtint08:near
	extrn	mosaddr:word, minterr:near, patdemo1:near,mosdemo1:near
	extrn	savtable:word, mosint23:near, mosint38:near
	extrn	mmlseg:word, mmsegmt:word, ldmmdev:near, mmdevice:byte
	extrn	smperr:near, clearsm:near, lidtstub8:near, lidtstub9:near
	extrn	lidtint74:near, lidtstub74:near, regr13pri:near
	extrn	lidtst_af:near, lidt0a:near, lidt0b:near, lidt0c:near
	extrn	lidt0d:near, lidt0e:near, lidt0f:near, irqbank:near
	extrn	set_kbrate:near, og4013:word, dd4013:word

mosseg	ends

;======================================================== init segment
if 0 eq 0
segment_num = 3
endif
initseg	segment
	assume	cs:init,ds:nothing,es:nothing,ss:nothing
	extrn	initend:byte, imosaddr:word, mscall:far
	extrn	initmos:word, initmo2:word, initgrp:word

	public	incall, exit13


	db	'PATCH_INIT'
	db	512	dup (0)		; 256 byte INIT code patch area

cnfsize  dw	0			; size of cnfbuf in paragraphs
first	db	0			; used when initializing device drivers
cnfile	 db	'CONFIG.SYS',0
errcomm db	'Invalid command in CONFIG.SYS : $  '  ;@@xlat
errbufr db	'BUFFERS= command ignored, use CACHE= command instead       '  ;@@xlat
imsgcrlf db	13,10,'$'
errcnty db	'Invalid COUNTRY code specified.           ',13,10,'$'	;@@xlat
msgnone db	'No CONFIG.SYS file available.    ',13,10,'$'  ;@@xlat
msgfile db	'File error processing CONFIG.SYS,   error type # '  ;@@xlat
errno	db	'00',13,10,'$'
msgdevc db	'Too many device drivers.                      '  ;@@xlat
	db	13,10,'$'
msgvtyp db	'Invalid VTYPE, using default.                      '  ;@@xlat
	db	13,10,'$'
msgcache db	'Invalid CACHE parameter, using default.                      ',13,10,'$'  ;@@xlat
igncach1 db	'Both CACHE= and DEVICE=$       '  ;@@xlat
igncach2 db	'CACHE.SYS commands encountered   ',13,10  ;@@xlat
	db	'DEVICE=$'
igncach3 db	'CACHE.SYS ignored        ',13,10,'$'  ;@@xlat
msgfree db	'FREEMEM command ignored; only 5 allowed.      ',13,10,'$'  ;@@xlat
msgifm	 db	'Invalid FREEMEM -              '  ; pointers must be atleast ;@@xlat
msgifm1  db	'    ,' 		;  4k apart and 'end' must be
msgifm2  db	'    ',13,10,'$'	;  greater than 'start'
msgmm1	db	'Invalid MEMDEV driver    ',13,10,'$'  ;@@xlat
devfile db	'Cannot find device driver : $      '  ;@@xlat
devnotmm db	'Use MEMDEV command for driver : $             '  ;@@xlat
devmsg	db	'  File error #'	; these 2 lines must stay ;@@xlat
devno	db	'00 processing DEVICE = $         '  ;	together ;@@xlat
devnsmp db	'Not Enough SMP for DEVICE = $          '  ;@@xlat
xcmsg	db	'% of cache available for write buffering',0dh,0ah,'$'	;@@xlat
xcbitmsg db	'K bits reserved for cache bit map',0dh,0ah,'$'  ;@@xlat
msgdsksw db	'Disk busy task switching disabled        ',13,10,'$'  ;@@xlat
msgdsker db	'DISKSW parameter error           ',13,10,'$'  ;@@xlat
msgkbrter db	'KBRATE parameter error           ',13,10,'$'  ;@@xlat
msgkbbios db	'KBBIOS parameter error           ',13,10,'$'  ;@@xlat
msgldrive db	'LASTDRIVE parameter error          ',13,10,'$'  ;@@xlat
msgdosver db	'DOSVER parameter error (3.0 - 5.0)         ',13,10,'$'   ;@@xlat

; the following is a value which is search by setuser.com to locate
; locations in mos's INIT code to plug in values

scandb	db	'[MOS]' 		; this is what program will search for
	dw	offset scandb		; offset to [mos] - use as reference
	dw	offset hserial		; offset in mos init code to hidden serial #
	dw	offset rserial		; offset in mos init code to real hidden serial #
	dw	offset enbedded 	; offset to mos serial # (10 digit)


; the following is a 80 byte table which is use to control patches
; the planned is for a future patch.com utility program will place an
; entry in this table which indicates which patch has been patch to
; kernel by patch.com scripts.	the label [patch] will make it easy to find
; this patch area by the patch program

	db	'[PATCH]'
	dw	80			; this indicates size of patch area
	db	'0'			; patch level (0 means initial release)
	db	80 dup (0)		; 80 bytes (non-zero means patch)

; the following int vectors are pointed to an iret

plugtbl db	04h,07h,2ah,2bh,2ch,2dh
	db	30h,31h,32h,33h,34h,35h,36h,37h,39h,3ah,3bh,3ch,3dh,3eh,3fh
	db	0ffh			; terminator

	include  moslogo.inc		; other stuff in moslogo.old

icnfhdl dw	0			; handle for config during init code
icnfsiz	dw	0			; size of device driver loaded
icharsav db	0			; character save value
lowdev	db	0			; non-zero means - load device driver low
lowcount dw	0			; # of drivers loaded in low memory
smp1dev dw	0			; smp #1 device drivers size
smp2dev dw	0			; smp #2 device drivers size

wordten dw	10

include	serial.inc			; generated serial number file
;enbedded db	'X0X0X0X0X0'

msgheap  label	byte			;021588
msgheap1 db	5 dup (' '), 'K SMP #1 allocated; $ '  ;021588 ;@@xlat
msgheap2 db	5 dup (' '), 'K of SMP #1 allocated to device drivers.',13,10,'$'  ;021588 ;@@xlat

msg2heap	 label	byte		;021588
msg2heap1 db	5 dup (' '), 'K SMP #2 allocated; $ '  ;021588 ;@@xlat
msg2heap2 db	5 dup (' '), 'K of SMP #2 allocated to device drivers.',13,10,'$'  ;021588 ;@@xlat

hvalues db	4 dup (0)		; 4 values use internal to calculate
					; internal serial #

hserial db	'0123'			; storage area to store hidden serial #
					; for comparision, also use a secondary
					; area to store un-used hidden serial #

msgleng dw	msgonl			; lenght of logo message to display to user


special db	'40444854750000000'	; special added number for telephone
					; # - currently not use and set to
					; tsl's phone #


crmsg	equ	$
y = 0
	irpc	x,<(c) Copyright 1987 The Software Link Incorporated >
	db	('&x' xor 0abh)-y
y = y + 1
	endm
	irpc	x,<All rights reserved worldwide.>
	db	('&x' xor 0abh)-y
y = y + 1
	endm
crend	equ	$
crlen	equ	crend-crmsg

idispmos proc	near
	assume	cs:init
	cfmos	dispmos
	ret
idispmos endp


	 assume cs:init, ds:nothing,es:nothing,ss:nothing
;======================================================================
;,fs
; these routines processe config.sys commands for cacheing
;
;
; pccache
;
; the cache command has the following syntax:
;
; cache=k,n,f,l,a,b,...,c
;
; k = size to reserve for cache in k (default is 16k)
; n = unit of buffering in k (default is 2k)
; f = ticks from first write to flush (default is 0)
; l = ticks from last write to flush (default is 0)
;   0 for both f & l for write-through
;   else 0 for f means only flush l ticks after last write
;   else 0 for l means only flush f ticks after first write
;   else flush f ticks after first write or l ticks after last write
;     whichever comes first
; a,b,...,c drives to cache (default is cache all drives)
;
;
; pcbufr
;
; the buffers command is retained for compatibility.  it is ignored and
;   a message is displayed saying so
;
; buffers=n
;
;
; cachesys
;
; the device=$cache.sys command is interpreted for compatibility.  the
; size parameter is regarded as allowing the cache to be that much
; larger
;
; device=$cache.sys k l
;
; k = size of cache in k
; l = location to map cache buffer (ignored)
;,fe
;======================================================================

;======================================================================
;,fs
; bps2k
;
; convert bytes per sector to the minimum number of k required
; to hold a sector
;
; in:	ds -> grp
;	[scbbufsz]
;
; out:	ax = min k
;
;,fe
;=====================================================================
	assume ds:grp,es:nothing,ss:nothing
bps2k proc near
	push	cx
	mov	ax,[scbbufsz]		; convert the maximum bytes/sector
	add	ax,1023 		; factor to the minimum number of k
	mov	cl,10			; required to hold a sector.
	shr	ax,cl			; mink = (b/s + 1023)/1024
	pop	cx
	ret
bps2k endp 

;======================================================================
;,fs
; getdfcbk
;
; return the default uob size from the larger of dftcbk
; or bps2k's return value
;
; in:	ds -> grp
;
; out:	ax = default uob size
;
;,fe
;=====================================================================
	assume ds:grp,es:nothing,ss:nothing
getdfcbk proc near
	call	bps2k
	cmp	ax,dftcbk
	ja	def005
	mov	ax,dftcbk
def005:
	ret
getdfcbk endp

;======================================================================
;,fs
; 
;
; skip to first comma or non-blank, then, if comma, to first following
;   non- blank
;
; in:	ds:si -> string
;
; out:	al = 0 if end-of-line encountered
;
;,fe
;=====================================================================
	assume	ds:nothing,es:nothing,ss:nothing
findcomma proc near
	lodsb
	cmp	al,0dh
	je	fend
	cmp	al,0ah
	je	fend
	cmp	al,' '
	jbe	findcomma
	cmp	al,','
	jne	fend
foundc:
	lodsb
	cmp	al,0dh
	je	fend
	cmp	al,0ah
	je	fend
	cmp	al,' '
	jbe	foundc
fend:
	dec	si
	ret
findcomma endp 

;======================================================================
;,fs
; getnum
;
; return decimal number parameter
; skip leading spaces & return bx = number
;
; in:	ds:si -> ascii string
;
; out:	?
;
;,fe
;=====================================================================
	assume	ds:nothing,es:nothing,ss:nothing
getnum proc near
	push	bx
	xor	bx,bx			; value starts 0
	mov	ah,bh
getn0:					; skip leading blanks
	lodsb
	cmp	al,0dh
	je	getny
	cmp	al,0ah
	je	getny
	cmp	al,' '
	jbe	getn0
	cmp	al,','
	je	getny
	dec	si
getn1:
	lodsb
	cmp	al,0dh
	je	getnx
	cmp	al,0ah
	je	getnx
	cmp	al,'0'
	jb	getnx			; terminating char is skipped (maybe is 'K' or ' ')
	cmp	al,'9'
	ja	getnx
	sub	al,'0'
	mov	cx,bx
	shl	bx,1
	shl	bx,1
	add	bx,cx
	shl	bx,1
	add	bx,ax
	jmp	getn1
getnx:
	pop	ax			; throw away default
	push	bx
getny:
	pop	bx
	dec	si
	ret
getnum endp 

;======================================================================
;,fs
; scan_slash  
;
; in:	ds:si -> string
;
; out:	?
;
;,fe
;=====================================================================
	assume	ds:nothing,es:nothing,ss:nothing
scan_slash proc near
	lodsb
	cmp	al,'/'
	je	ssldone
	cmp	al,0ah
	je	ssldone
	cmp	al,0dh
	jne	scan_slash
ssldone:
	ret
scan_slash endp 

;======================================================================
;,fs
; chk_bps
;
; check for the /bps= option
; if fail, return ax != 0
; if ok, sets scbbufsz and blanks the parm out of the buffer
; if no /bps= parm, return ax = 0
;
; in:	
;
; out:	
;
;,fe
;=====================================================================
	assume	ds:nothing,es:grp,ss:nothing
chk_bps proc near
	push	si			; save the initial pointer
	push	di			; scratch storage
	mov	di,si
bpsloop1:
	mov	si,di			; restore si from save
	call	scan_slash
	mov	di,si			; save si for next iteration
	cmp	al,'/'
	jne	notbps
	lodsw
	and	ax,not 2020h		; capitalize
	cmp	ax,'PB'
	jne	bpsloop1
	lodsw
	and	al,not 20h		; capitalize
	cmp	ax,'=S'
	jne	bpsloop1
	mov	di,si
	sub	di,5			; point di to the /
	call	getnum
	mov	ax,512-1		; validate - must be on 512 boundary
	and	ax,bx
	jnz	badbps
	mov	[scbbufsz],bx
	dec	di
bpsloop2:
	dec	si
	mov	byte ptr [si],' '	; blank parm out of buffer
	cmp	si,di
	jne	bpsloop2
notbps:
	xor	ax,ax
	jmp	short bpsz
badbps:
	mov	ax,1
bpsz:
	pop	di
	pop	si
	ret
chk_bps endp 

	subttl	pccache
	page
;======================================================================
;,fs
; pccache
;
; parse cache= command
;
; in:	
;
; out:	
;
;,fe
;=====================================================================
	assume	ds:nothing,es:nothing,ss:nothing
pccache proc near
	push	es
	mov	es,cs:[initgrp]
	assume	ds:nothing,es:grp
	call	findeq			; find =
	or	al,al
	jnz	pcc0			; end of line
pcc00:
	jmp	badcache
pcc0:
	dec	si
	call	chk_bps 		;mjs@
	or	ax,ax			;mjs@
	jne	pcc00			;mjs@
	mov	bx,[scbck]
	call	getnum
	mov	[scbck],bx		; k to reserve for cache
	mov	bx,[scbcbk]
	and	word ptr [scbcd+2],not 8000h  ; default cache on for all drives
	call	findcomma
	call	getnum
	or	bx,bx
	jz	pcc0a
	cmp	bx,[scbck]
	ja	pcc0a			; bigger than cache is unacceptable
	push	ax
	push	ds
	push	es
	pop	ds
	call	bps2k			; get min # of k to hold a sector.
	pop	ds
	cmp	bx,ax			; a uob must be able to hold
	pop	ax			; a sector  (oh really??!!).
	jae	pcc0b
pcc0a:
	jmp	badcache
pcc0b:
	mov	[scbcbk],bx		; size of a cache element in k
	mov	bx,[scbcwf]
	call	findcomma
	call	getnum
	cmp	bx,1800 		; jrb document at 1800 seconds
	ja	badcache
	mov	ax,bx
	mov	bx,182
	mul	bx
	mov	bx,10
	div	bx
	mov	[scbcwf],ax		; ticks from first write to flush (0 is ok)
	mov	bx,[scbcwl]
	call	findcomma
	call	getnum
	cmp	bx,1800 		; jrb document as 1800 seconds
	ja	badcache
	mov	ax,bx
	mov	bx,182
	mul	bx
	mov	bx,10
	div	bx
	mov	[scbcwl],ax		; ticks from last write to flush (0 is ok)
pcc1:
	call	findcomma
	cmp	al,0dh
	je	okcache
	cmp	al,0ah
	je	okcache 		; end of line
	lodsb
	and	al,not 20h		; capitalize drive letter
	cmp	al,'A'
	jb	badcache
	cmp	al,'Z'
	ja	badcache
	sub	al,'A'
	mov	bl,al
	xor	bh,bh
	shr	bx,1
	shr	bx,1
	shr	bx,1
	mov	cl,al
	and	cl,7
	mov	al,1
	shl	al,cl
	or	scbcd[bx],al		; drive to be included from cacheing
	jmp	pcc1
okcache:
	cmp	[scbcsysk],0
	je	okc1
	call	igncacherr
okc1:
	pop	es
	ret
badcache:
	mov	[scbcwf],0
	mov	[scbcwl],0
	mov	[scbck],dftck
	push	ds
	push	es
	pop	ds
	call	getdfcbk
	pop	ds
	mov	[scbcbk],ax
	mov	word ptr [scbcd],0
	mov	word ptr [scbcd+2],8000h; (cache off on all drives)
	push	ds
	push	cs
	pop	ds
	assume	ds:nothing
	lea	dx,msgcache		; display error message
	mov	ah,9
	cfmos	ifar21
	pop	ds
	pop	es
	ret
pccache endp 

;======================================================================
;,fs
; igncacherr
;
; in:	
;
; out:	
;
;,fe
;=====================================================================
	assume	ds:nothing,es:nothing,ss:nothing
igncacherr proc near
	push	ds
	push	cs
	pop	ds
	lea	dx,igncach1		; 'both specified, ignore device='
	mov	ah,9
	cfmos	ifar21
	mov	dl,'$'
	mov	ah,2
	cfmos	ifar21
	lea	dx,igncach2		; 'both specified, ignore device='
	mov	ah,9
	cfmos	ifar21
	mov	dl,'$'
	mov	ah,2
	cfmos	ifar21
	lea	dx,igncach3		; 'both specified, ignore device='
	mov	ah,9
	cfmos	ifar21
	pop	ds
	ret
igncacherr endp

	subttl	cachesys
	page
;======================================================================
;,fs
; cachesys  
;
; called from device= as special case for compatibility w/ $cache.sys
; enter ds:si -> device name specified in device= command
; set cache length if $cache.sys and return z, else return nz
;
; in:	
;
; out:	
;
;,fe
;=====================================================================
	assume	ds:nothing,es:nothing,ss:nothing

cnm	db	'$CACHE.SYS'
cln	equ	$-cnm

cachesys proc near
	push	es
	push	di
	push	si
	push	cx
	push	cs
	pop	es
	lea	di,[cnm]
	mov	ch,0			;jrbt
	add	si,cx			;jrbt
	mov	cx,cln
	sub	si,cx			;jrbt -> start of $cache.sys if present
	repe cmpsb
	jne	csysx			; z flag clear for device=
	call	getnum
	push	ds
	or	bx,bx
	jnz	csys1
	push	cs
	pop	ds
	assume	ds:nothing
	lea	dx,msgcache		; display error message
	mov	ah,9
	cfmos	ifar21
	jmp	csys3
csys1:
	mov	ds,cs:[initgrp]
	assume	ds:grp
	cmp	[scbck],0
	je	csys2
	call	igncacherr
	jmp	csys3
csys2:
	mov	[scbcsysk],bx
	and	word ptr [scbcd+2],not 8000h  ; default cache on for all drives
csys3:
	assume	ds:nothing
	cmp	al,al			; set z flag for device=
	pop	ds
csysx:
	pop	cx
	pop	si
	pop	di
	pop	es
	ret
cachesys endp 

;======================================================================
;,fs
; pcbufr
;
; this routine will process the buffers command.  this is the number of
; disk buffers requested.  it is retained for compatibility but is
; ignored with a message saying it's ingored.
;
; in:	ds -> cnfbuf
;	es -> grp
;
; out:	
;
;,fe
;=====================================================================
	assume	ds:cnfbuf,es:grp,ss:nothing
pcbufr proc near
	push	ds
	push	cs
	pop	ds
	assume	ds:init
	lea	dx,errbufr		; tell user command ignored
	mov	ah,9
	cfmos	ifar21
	pop	ds
	ret
pcbufr	endp

rserial db	'1234'			; real hidden serial # use in cross check

	subttl procnfg - process config.sys file
	page
;======================================================================
;,fs
; procnfg - process config.sys file
;
; this routine will read the config.sys file into the system heap and
; parse the commands.  the actually processing for most of the commands
; will occur later, this routine will simply set the appropriate
; variables.
;
; upon exit the scb variables scbhpadr, scbhpsiz, cnfbuffr,
; cnfbufno, and mosaddr will be set according to the values read
; in the config.sys file.
;
; updated 01/18/88 sah - all calls to command processing now make
; sure that es points to grp and this will save both time and
; space by not having to load a segment register with the scb
; segment for each command.  this also makes the code much easier
; to understand for future reference.
;
; in:	ds -> grp
;
; out:	
;
;,fe
;=====================================================================
	assume	ds:nothing,es:nothing,ss:nothing

funtable db	5,'BREAK'
	 dw	offset init:pcbrek
	db	7,'BUFFERS'
	dw	offset	init:pcbufr
	db	7,'COUNTRY'
	dw	offset	init:pccnty

if	mdebug eq 1

	db	6,'DBPORT'
	dw	offset	init:pcdprt
	db	5,'DEBUG'
	dw	offset	init:pcdebg
endif

	db	6,'DESNOW'
	dw	offset	init:pcdsno
	db	6,'DEVICE'
	dw	offset	init:pcdevc
	db	7,'LDEVICE'
	dw	offset	init:pcldevc
	db	4,'8087'
	dw	offset	init:pc8087
	db	5,'80287'
	dw	offset	init:pc8087
	db	5,'80387'
	dw	offset	init:pc8087
	db	7,'FREEMEM'
	dw	offset	init:pcfree
	db	5,'SLICE'
	dw	offset	init:pcslic
	db	7,'SMPSIZE'
	dw	offset	init:pcheps
	db	6,'MEMDEV'
	dw	offset	init:pcmmdv
	db	5,'MMVID'
	dw	offset	init:pcmmvd
	db	3,'REM'
	dw	offset	init:pcrem
	db	5,'SHELL'
	dw	offset	init:pcshel
	db	8,'USERFILE'
	dw	offset init:pcuser
	db	5,'VTYPE'
	dw	offset init:pcvtype
	db	5,'CACHE'
	dw	offset init:pccache
	db	6,'DISKSW'
	dw	offset init:pcdisksw
	db	6,'KBRATE'
	dw	offset init:pckbrate
	db	6,'KBBIOS'
	dw	offset init:pckbbios
	db	9,'LASTDRIVE'
	dw	offset init:pcldrive
	db	6,'DOSVER'
	dw	offset init:pcdosver
	db	0,0,0,0

	page
;-----------------------------------------------------------------------

	public	procnfg
procnfg proc	near
	assume	ds:grp
	push	ds
	call	readcnf 		; read config.sys file into memory
	jz	$+5			; got one, process it
	jmp	endcomm 		; end of config parms process defaults

; command loop, process commands one by one

	push	ds			; make es point to group
	pop	es
	lea	si,cnffile		; point to start of config file
	mov	ds,[initmos]
	assume	ds:mos
	mov	ds,[cnfseg]		; address config buffer in heap
	assume	ds:cnfbuf
commlp:
	call	getcomm 		; point ds:si to next command in file
	cmp	al,1			; any more commands?
	jne	$+5			; yes, process the next one
	jmp	endcomm 		; that's all, no more commands
	cmp	al,2			; is this one valid?
	je	errfun			; no, bad command
	lea	di,funtable		; table of available routines
	xor	ah,ah
funloop:
	mov	al,cs:[di]		; get entry string length
	or	al,al			; end of table
	jz	errfun
	cmp	al,cl			; same size as entered?
	jnz	nextfun 		; no, try next one
	push	es			; save grp segment for call later
	push	di			; save pointer to size byte
	inc	di			; point to funtable string
	push	si			; save start of parm pointer
	push	cx
	push	cs
	pop	es
	repe cmpsb			; is this the right function?
	pop	cx
	pop	si
	pop	di
	pop	es			; get grp segment
	jnz	nextfun 		; no, not yet
	add	di,ax			; point to routine vector
	inc	di
	call	cs:[di] 		; process this command
	jmp	commlp			; next command in file
nextfun:
	add	di,ax
	add	di,3			; point past address of fun
	jmp	funloop 		; try next guy
errfun:
	push	cs
	pop	ds
	assume	ds:init
	push	ds
	lea	dx,errcomm		; tell user invalid command in config.sys
	call	idispmos		;021588
	mov	ds,[initmos]
	assume	ds:mos
	mov	ds,[cnfseg]
	assume	ds:cnfbuf
	call	prntln			; print line at ds:si up to cr,lf
	pop	ds
	assume	ds:init
	lea	dx,imsgcrlf		; do cr and lf
	call	idispmos		;021588
	mov	ds,[initmos]
	assume	ds:mos
	mov	ds,[cnfseg]
	assume	ds:cnfbuf
	jmp	commlp			; do next command in file
endcomm:
	pop	ds
	assume	ds:grp
	ret				; exit procnfg, use all defaults
procnfg endp

;======================================================================
;,fs
; pcbrek
;
; this routine will process the break command.	this is ignored by mos
;
; in:	
;
; out:	
;
;,fe
;=====================================================================
	assume	ds:cnfbuf,es:grp,ss:nothing
pcbrek	proc	near
	ret				; end sub, ignore command
pcbrek	endp

;======================================================================
;,fs
; pccnty
;
; this routine will process the country command.  this value is simply
; stored in the scb variable scbcntry.
;
; in:	
;
; out:	
;
;,fe
;=====================================================================
	assume	ds:cnfbuf,es:grp,ss:nothing
pccnty	proc	near
	mov	al,1			; get decimal number
	xor	ah,ah			; blank is a valid terminator
	call	getparm 		; get country number
	mov	bx,ax			; country code to bx too		;42888
	or	ah,ah			; is it a 16 bit country code		;42888
	jz	$+4			; jump if no				;42888
	mov	al,0ffh 		; show country code in bx		;42888
	mov	ah,038h 		; set country code			;42888
	mov	dx,0ffffh		; show this is a set only		;42888
	cfmos	ifar21			; let mos validate the country code	;42888
	jc	cntyerr 		; go show his mistake			;42888
	ret				; end sub
cntyerr:				;42888
	push	cs
	pop	ds
	assume	ds:init 		;42888
	lea	dx,errcnty		; tell user invalid country in config.sy;42888
	call	idispmos		; display on console			;42888
	mov	ds,[initmos]
	assume	ds:mos
	mov	ds,[cnfseg]		; point ds back to config.sys buffer	;42888
	assume	ds:cnfbuf		;42888
	ret				; finished processing country		;42888
pccnty	endp

if	mdebug eq 1

;======================================================================
;,fs
; pcdprt
;
; this routine processes the dbport command.  this command allows us to
; select a serial port or an alternate video monitor to display debug
; info to.
;
; in:	
;
; out:	
;
;,fe
;=====================================================================
	assume	ds:cnfbuf,es:grp,ss:nothing
pcdprt	proc	near
	mov	al,2			; get hex number
	xor	ah,ah			; blank is a valid terminator
	call	getparm 		; get port number (and maybe baud divisor)
	mov	[scbdbprt],ax		; set debug port address
	cmp	ax,0b000h		; is this a video address?
	je	pcdend			; yes
	cmp	ax,0b800h		; is this a video address?
	je	pcdend			; yes
	cmp	ax,4			; is this an lpt device?
	jbe	pcdend			; yes, skip serial init

; set port to 19,200 baud and 8,1,n

	push	dx
	mov	dx,ax
	cli				; no interrupts at this time please...
	add	dx,3			; point to lcr
	mov	al,83h			; set dlab=1, 8 data, 1 stop, and no parity
	out	dx,al
	sub	dx,3
	or	cx,cx			; was a baud divisor specified?
	jnz	nobdvsr 		; yes, use the given one
	mov	cx,6			; 19,200 default
nobdvsr:
	mov	ax,cx
	out	dx,al			; set divisor lsb
	xchg	al,ah
	inc	dx
	out	dx,al			; set divisor msb
	add	dx,2			; point to lcr
	mov	al,03h			; set dlab=0, 8 data, 1 stop, and no parity
	out	dx,al
	sti
	mov	cx,3			; make sure the damn terminal screen clears!
	add	dx,2			; lsr
clrtlp:
	in	al,dx
	test	al,20h			; is tx hold empty?
	jz	clrtlp			; no wait
	sub	dx,5			; point to tx reg
	mov	al,26			; ctrl-z to clear terminal screen
	out	dx,al
	add	dx,5			; lsr
	loop	clrtlp
	pop	dx
pcdend:
	ret
pcdprt	endp

;======================================================================
;,fs
; pcdebg
;
; this routine processes the debug command.  this command allows us to
; selectively induce status and debugging messages to appear.
;
; in:	
;
; out:	
;
;,fe
;=====================================================================
	assume	ds:cnfbuf,es:grp,ss:nothing
pcdebg	proc	near
	mov	al,2			; get hex number
	xor	ah,ah			; blank is a valid terminator
	call	getparm 		; get device program name
	mov	[scbdebug],ax		; set debug to desired level
	ret
pcdebg	endp

endif

;======================================================================
;,fs
; pcdsno
;
; this routine processes the desnow command.  this command allows us to
; selectively activate the code to clear snow from some color monitors
;
; in:	
;
; out:	
;
;,fe
;=====================================================================
	assume	ds:cnfbuf,es:grp,ss:nothing
pcdsno	proc	near
	xor	al,al			; get string
	xor	ah,ah			; blank is a valid terminator
	call	getparm 		; get device program name
	mov	grp:[mcsnow],0		; default to no
	cmp	word ptr [si],'EY'	; is desnow=yes
	jne	pcdsne
	mov	grp:[mcsnow],1		; no snow code on
pcdsne:
	ret
pcdsno	endp

;======================================================================
;,fs
; pcdevc
;
; this routine will process the device command.  the pointers to the
; device names in the file buffer will be queued for later retrieval
; since they must be loaded into the heap and the heap does not exist
; as of yet.
;
; in:	
;
; out:	
;
;,fe
;=====================================================================
	assume	ds:cnfbuf,es:grp,ss:nothing
pcdevc	proc	near
	cmp	[ddnum],ddrecs*ddrecsiz
	jne	pcdevc0
	push	ds
	push	cs
	pop	ds
	mov	dx,offset init:msgdevc
	call	idispmos
	pop	ds
	jmp	short pcdevcx
pcdevc0:
	mov	cs:[lowdev],0		; don't load device driver low
	jmp	short devcomm
pcldevc:
	mov	cs:[lowdev],-1		; load device driver low in memory
	inc	cs:[lowcount]		; increment counter
devcomm:
	xor	al,al			; get string
	xor	ah,ah			; blank is a valid terminator
	call	getparm 		; get device program name
	mov	bx,offset cnfbuf:ddtable ; point to queue space
	add	bx,[ddnum]		; offset number of driver
	mov	[bx],si 		; save pointer to driver
	mov	[bx+2],cl		; save length also
	call	cachesys		;jrbr is it $cache.sys?
	jz	pcdevcx 		;jrbr yes, so we took care of it
	add	[ddnum],ddrecsiz	; set up for next time
	xor	al,al			; get string
	mov	ah,1			; blank is not a valid terminator
	push	bx			; save 'ddtable' pointer
	call	getparm 		; get device program name
	pop	bx
	mov	al,[bx+2]		; get name length in ax
	xor	ah,ah
	sub	cx,ax			; calc length of just parms
	mov	[bx+3],cx		; save length of parms as well
	mov	al,cs:[lowdev]
	mov	[bx+5],al		; store style of device driver into record
pcdevcx:
	ret
pcdevc	endp

;======================================================================
;,fs
; pc8087
;
; this routine processes the 8087 (80287, 80387) command to tell the
; system to save the state of the numberic coprocessor.
;
; in:	
;
; out:	
;
;,fe
;=====================================================================
	assume	ds:cnfbuf,es:grp,ss:nothing
pc8087	proc	near
	xor	al,al			; get string
	xor	ah,ah			; blank is a valid terminator
	call	getparm 		; get device program name
	mov	[scbsw87],'N'
	cmp	word ptr [si],'EY'	; is 8087=yes
	jne	pc87x
	mov	[scbsw87],'Y'		; flag save of ncp state
pc87x:
	ret
pc8087	endp

;======================================================================
;,fs
; pcfree
;
; this routine processes the freemem command.  this command may be
; encountered up to 5 times.  the information is saved into the
; data management tables and used later to relocated mos, disk buffers
; or the heap.
;
; in:	
;
; out:	
;
;,fe
;=====================================================================
	assume	ds:cnfbuf,es:grp,ss:nothing
pcfree	proc	near
	push	si
	call	findeq
	or	al, al
	je	freeyes
	cmp	al,'N'			; freemem=n
	je	freeno
	cmp	al,'n'
	jne	freeyes
freeno:
	pop	si
	mov	ax, -1			; reset freemem statements
	push	ds
	mov	ds,[initmos]
	assume	ds:mos
	mov	[dmpatch], ax
	mov	[dmpatch+2],ax
	mov	[dmlist], 0
	pop	ds
	assume	ds:cnfbuf
	ret
freeyes:
	pop	si
	mov	al,2			; get hex number
	xor	ah,ah			; blank is a valid terminator
	call	getparm 		; get mos load address
	push	ds
	mov	ds,cs:[initmos]
	assume	ds:mos
	push	bx
	cmp	[dmlist],5*4		; max of 5 times
	je	freeerr
	mov	bx,[dmlist]		; get table index
	mov	[dmpatch+bx],ax 	; save start value
	mov	[dmpatch+bx+2],cx	; save end value
	add	[dmlist],4		; update pointer
freex:
	pop	bx
	pop	ds
	assume	ds:cnfbuf
	ret				; end sub
freeerr:
	push	cs
	pop	ds
	assume	ds:mos
	lea	dx,msgfree
	call	idispmos		;021588
	jmp	freex
pcfree	endp

;======================================================================
;,fs
; findeq
;
; in:	
;
; out:	
;
;,fe
;=====================================================================
	assume	ds:nothing,es:nothing,ss:nothing
findeq	proc	near
feqlp:
	lodsb
	cmp	al,'='			; is it equals
	je	feq1
	cmp	al,0ah
	je	feq2
	cmp	al,0dh
	je	feq2
	jmp	feqlp
feq1:
	lodsb
	cmp	al,' '
	je	feq1
	cmp	al,0d
	jne	feq3
feq2:
	xor	al,al			; mark as bad special case
feq3:
	ret
findeq	endp

;======================================================================
;,fs
; pcheps
;
; this routine processes the smpsize command.  this simply sets the
; scb variable scbhpsiz for use later during heap allocation.
;
; in:	
;
; out:	
;
;,fe
;=====================================================================
	assume	ds:cnfbuf,es:grp,ss:nothing
pcheps	proc	near
	mov	al,1			; get dec number
	xor	ah,ah			; blank is a valid terminator
	call	getparm 		; get size of heap
	push	dx
	mov	dx,ax
	add	dx,cx			; add size of heap #2
	cmp	dx,8			; minimum size of 8k allow
	jae	hminok			; yes..large enough
	mov	ax,8			; force smp #1 to 8
	xor	cx,cx			; force smp #2 to 0
hminok:
	cmp	dx,440			; maximum of 440k allow
	jb	oksmps
	mov	ax,440			; give em 440k
	xor	cx,cx
oksmps:
	pop	dx
	push	cx
	mov	cl,6
	shl	ax,cl			; calc # para's
	mov	[scbhpsiz],ax		; set heap size
	pop	ax
	shl	ax,cl			; calc # para's
	mov	[scbhp2siz],ax		; set heap # 2 size
	ret				; end sub
pcheps	endp

;======================================================================
;,fs
; pcmmdv
;
; this routine processes the memdev command.  this is the memory
; management device.  save the pointers to the name and length so that
; the driver may be loaded before any other driver.
;
; in:	
;
; out:	
;
;,fe
;=====================================================================
	assume	ds:cnfbuf,es:grp,ss:nothing
pcmmdv	proc	near
	mov	[mmdev1],-1		; assume no memman wanted
	xor	al,al			; get string
	mov	ah,0			; blank is a valid terminator
	call	getparm 		; get device program name
	cmp	byte ptr ds:[si],'*'	; flag for no driver?
	je	pcmmdv2 		; yes
	mov	[mmdev1],si		; save pointer to driver
pcmmdv2:
	mov	[mmdev2],cl		; save length also
	xor	al,al			; get string
	mov	ah,1			; blank is not a valid terminator
	call	getparm 		; get device program name
	sub	cl,[mmdev2]		; calc length of parms only
	mov	[mmdev2+1],cl		; save length of parms also
	ret
pcmmdv	endp

;======================================================================
;,fs
; pcmmvd
;
; this routine processes the mmvid command.  this command allows us to
; turn off video memory management for debugging or what ever.
;
; in:	
;
; out:	
;
;,fe
;=====================================================================
	assume	ds:cnfbuf,es:grp,ss:nothing
pcmmvd	proc	near
	xor	al,al			; get string
	xor	ah,ah			; blank is a valid terminator
	call	getparm
	and	[scbmmmod],7fh		; assume memman video on (initp4 will xor)
	cmp	word ptr [si],'ON'	; is mmvid=no?
	jne	pcmmve			; no
	or	[scbmmmod],80h		; turn off memman video (initp4 will xor)
pcmmve:
	ret
pcmmvd	endp

;======================================================================
;,fs
; pcrem
;
; remark command will only display line of config.sys that it is on
; on entry si points to start of command line
;
; in:	
;
; out:	
;
;,fe
;=====================================================================
	assume	ds:cnfbuf,es:grp,ss:nothing
pcrem	proc	near
	xor	al,al			; get string
	mov	ah,1			; blank is not a valid terminator
	call	getparm
	call	prntln			; print line of config file to screen
	ret
pcrem	endp

;======================================================================
;,fs
; pcslic
;
; the slice command allows the setting of the default time slice for
; starting a task with.  a value of 0 disables time slicing.  the
; default is 1 (set in initp1).
;
; in:	
;
; out:	
;
;,fe
;=====================================================================
	assume	ds:cnfbuf,es:grp,ss:nothing
pcslic	proc	near
	mov	al,1			; get decimal number
	xor	ah,ah			; blank is a valid terminator
	call	getparm
	cmp	ax,255			; if over max then set to max
	jbe	pcslc2
	mov	ax,255
pcslc2:
	mov	[scbslice],al
	ret
pcslic	endp

;======================================================================
;,fs
; pcshel
;
; this routine processes the shell command.  this drive, path and file
; name will be stored in the scb variable scbshell for later mos
; reference as the command processor.
;
; in:	
;
; out:	
;
;,fe
;=====================================================================
	assume	ds:cnfbuf,es:grp,ss:nothing
pcshel	proc	near
	xor	al,al			; get string
	xor	ah,ah			; blank is a valid terminator
	call	getparm 		; get name of alternate command shell
	lea	di,scbshell
	cld
	push	si			; save file pointer
	rep	movsb			; move file name to scb area
	pop	si
	xor	al,al
	stosb				; terminate path name with 0
	ret				; end sub
pcshel	endp

;======================================================================
;,fs
; pcuser
;
; this routine processes the userfile command.	this drive, path and
; file will be stored in the scb variable scbusrf for signon
; reference as the userfile
; note path has to be fully expanded so signon can find it accurately
; regardless of current drive or directory or task
;
; in:	
;
; out:	
;
;,fe
;=====================================================================
	assume	ds:cnfbuf,es:grp,ss:nothing
pcuser	proc	near
	xor	al,al			; get string
	xor	ah,ah			; blank is a valid terminator
	call	getparm 		; get name of alternate command shell
	push	si
	lea	di,scbusrf+3		; past drive:\
	cmp	cx,2
	jb	pcusr1			; if < 2 chars then param can't include drive
	mov	ax,[si]
	cmp	ah,':'
	jne	pcusr1			; ne if drive not included
	add	si,2
	sub	cx,2
	mov	es:[di-3],ax		; replace drive: if included in parameter
pcusr1:
	jcxz	pcusr2
	cmp	byte ptr [si],'\'
	jne	pcusr2			; ne if \ not included in path
	dec	cx			; else skip it (it's already provided in
	inc	si			;   scbusrf)
pcusr2:
	cmp	cx,63+1+12		; path + \ + file name
	jbe	pcusr3
	mov	cx,63+1+12		; ain't gonna crash my scb
pcusr3:
	cld
	rep	movsb			; move file name to scb area
	xor	al,al
	stosb				; terminate path name with 0
	pop	si
	ret				; end sub
pcuser	endp

;======================================================================
;,fs
; pcvtype
;
; this routine processes the vtype command in the config.sys where it
; has the following syntax:
;		vtype=n[f]
; where f is option parameter to fill the foreground memory to limited
; where n is the vtype having the following definitions
;
;	vtype	     foreground   task      video save
;       --------     ----------   -----     ----------
;	default      base	  a0000 	16k
;	  1	     b0000(f)	  b0000 	16k
;	  2	     b0000(f)	  b0000 	 4k
;	  3	     b4000(f)	  b4000 	16k
;	  4	     b8000(f)	  b8000 	16k
;	  5	     b0000(f)	  b0000 	32k
;
; in:	
;
; out:	
;
;,fe
;=====================================================================
	assume	ds:cnfbuf,es:grp,ss:nothing
pcvtype proc	near
	call	findeq			; find =
	or	al,al
	jz	pcvbad
	cmp	al,'1'			; range 1 - 4
	jb	pcvbad
	cmp	al,'5'			;#jrb
	ja	pcvbad
	mov	ah,al			; save in ah to construct value
	sub	ah,'0'			; make it binary
	lodsb				; check for fill option
	cmp	al,'F'
	je	pcvfill
	cmp	al,'f'
	jne	pcvset
pcvfill:
;
; SAH 01/14/92: if base memory is not multible of 64k don't allow memory
; to be filled
;
	push	ax
	push	bx
	push	ds
	xor	ax,ax
	mov	ds,ax
	mov	ax,ds:[413h]		; get base size
	mov	bx,ax
	and	bx,0fc0h
	cmp	ax,bx
	pop	ds
	pop	bx
	pop	ax
	jne	pcvbad
;
	or	ah,80h			; set high bit to indicate fill
pcvset:
	mov	[scbvtype],ah		; save this value
	ret
pcvbad:
	push	ds
	push	cs
	pop	ds
	lea	dx,msgvtyp		; display error message
	call	idispmos		;021588
	pop	ds
	ret
pcvtype endp

;======================================================================
;,fs
; pcdisksw
;
; pcdisksw - specify disksw=n in config.sys if the int15 disk busy
; task switching feature is to be suppressed.
;
; in:	
;
; out:	
;
;,fe
;=====================================================================
	assume	ds:cnfbuf,es:grp,ss:nothing
pcdisksw proc near
	push	si
	call	findeq
	or	al, al
	je	dskswerr
	cmp	al,'N'
	je	dskswno
	cmp	al,'n'
	jne	dskswerr
dskswno:
	mov	[scbi15tsl],'N' 	; turn off disk wait task switching
	push	ds
	push	cs
	pop	ds
	lea	dx,msgdsksw
	call	idispmos
	pop	ds
	jmp	short dskswx
dskswerr:
	mov	dx,offset msgdsker
	push	ds
	push	cs
	pop	ds
	call	idispmos
	pop	ds
dskswx:
	pop	si
	ret
pcdisksw endp 

;======================================================================
;,fs
; pckbrate
;
; kbrate - control keyboard speed rate control logic.
; form:
;   kbrate=n	 (the literal letter "n")  to disable rate control
;
; in:	
;
; out:	
;
;,fe
;=====================================================================
	assume	ds:cnfbuf,es:grp,ss:nothing
pckbrate proc near
	push	si
	call	findeq
	or	al, al
	je	kbrter
	cmp	al,'N'
	je	kbrtno
	cmp	al,'n'
	jne	kbrter
kbrtno:
	mov	[scbkbrate],0ffh	; turn off rate control
	jmp	short kbrtx
kbrter:
	mov	dx,offset msgkbrter
	push	ds
	push	cs
	pop	ds
	call	idispmos
	pop	ds
kbrtx:
	pop	si
	ret
pckbrate endp

;======================================================================
;,fs
; pckbbios
;
; kbbios - control 40:17 support
; form:
;   kbbios=n	 (the literal letter "n")  to disable 40:17 support
;
; in:	
;
; out:	
;
;,fe
;=====================================================================
	assume	ds:cnfbuf,es:grp,ss:nothing
pckbbios proc near
	push	si
	call	findeq
	or	al, al
	je	kbbser
	cmp	al,'N'
	je	kbbsno
	cmp	al,'n'
	jne	kbbser
kbbsno:
	mov	[scbkbbios],'N'		; turn off bios control
	jmp	short kbbsx
kbbser:
	mov	dx,offset msgkbbios
	push	ds
	push	cs
	pop	ds
	call	idispmos
	pop	ds
kbbsx:
	pop	si
	ret
pckbbios endp

;======================================================================
;,fs
; pcldrive
;
; lastdrive - lastdrive support in config.sys
; form:
;   lastdrive= drive letter
;
; in:	
;
; out:	
;
;,fe
;=====================================================================
	assume	ds:cnfbuf,es:grp,ss:nothing
pcldrive proc near
	push	si
	call	findeq
	or	al, al
	je	ldriverr
	and	al,0dfh
	cmp	al,'A'
	jb	ldriverr	
	cmp	al,'Z'
	ja	ldriverr
	sub	al,'A'-1
	mov	[scbldrive],al		; set lastdrive
	jmp	short ldexit
ldriverr:
	mov	dx,offset msgldrive
	push	ds
	push	cs
	pop	ds
	call	idispmos
	pop	ds
ldexit:
	pop	si
	ret
pcldrive endp

;======================================================================
;,fs
; pcdosver
;
; dosver - sets defualt dos version
; form:
;   dosver= dos version (3.0 - 5.0)
;
; in:	
;
; out:	
;
;,fe
;=====================================================================
	assume	ds:cnfbuf,es:grp,ss:nothing
pcdosver proc near
	push	bx
	push	si
	call	findeq
	or	al, al
	je	dvererr
	xor	bx,bx
	cmp	al,'3'
	jb	dvererr
	cmp	al,'5'
	ja	dvererr
	mov	bl,al
	sub	bl,'0'
	lodsb
	cmp	al,'.'
	jne	dvererr
	lodsb
	cmp	al,'0'
	jb	dvererr
	cmp	al,'9'
	ja	dvererr
	sub	al,'0'
	xor	ah,ah
	mul	[wordten]
	mov	bh,al
	lodsb
	cmp	al,'0'
	jb	dvset
	cmp	al,'9'
	ja	dvset
	sub	al,'0'
	add	bh,al
dvset:	
	cmp	bx,[scbversn+2]			    ; can't be version of mos
	je	dvererr
	mov	[scbdosver],bx
	jmp	short dvexit
	
dvererr:
	mov	dx,offset msgdosver
	push	ds
	push	cs
	pop	ds
	call	idispmos
	pop	ds
dvexit:
	pop	si
	pop	bx
	ret
pcdosver endp


	subttl getcomm - get next command from file
	page
;======================================================================
;,fs
; getcomm - get next command from file
;
; this routine will parse a command from a line in the config.sys
; file.  the command will be set to all uppercase.  if the 1st
; non-blank character is a semi-colon (;) then the line is
; ignored.
;
; in:	ds -> cnfbuf (segment)
;	si points somewhere in previous line of the config file
;
; out:	al = exit code: 0 - ok, 1 - no command available
;			2 - bad command
;	ds:si points to the 1st character of the command.
;	cx length of the command
;	the command is all uppercase
;
;,fe
;=====================================================================
	assume	ds:cnfbuf,es:nothing,ss:nothing
getcomm proc	near
	dec	si			; adjust for loop

; skip to end of previous line

fcrlf1:
	inc	si
	cmp	byte ptr [si],0ah
	je	fcrlf2
	cmp	byte ptr [si],0dh
	jne	fcrlf1

; skip past all empty lines and comments and blank lines

fcrlf2:
	inc	si
	cmp	byte ptr [si],0dh
	je	fcrlf2
	cmp	byte ptr [si],0ah
	je	fcrlf2
	cmp	byte ptr [si],' '
	je	fcrlf2
	cmp	byte ptr [si],09h
	je	fcrlf2
	cmp	byte ptr [si],1ah	; eof?
	je	nocomm			; yes, no command available
	cmp	byte ptr [si],3bh	; comment?
	jne	fcrlf4			; no, must be the start of a command

; skipping a comment

fcrlf3:
	inc	si
	cmp	byte ptr [si],0dh
	je	fcrlf2
	cmp	byte ptr [si],0ah
	je	fcrlf2
	jmp	fcrlf3

; here we have the true and real beginning of a true and real command

fcrlf4:
	xor	cx,cx			; valid character count
falpha:
	cmp	byte ptr [si],'='	; check for end of command identifier
	je	verify1 		; ok, got a command
	cmp	byte ptr [si],0dh	; check for end of line
	je	badcomm 		; yes, conclusion: must be a bad command
	cmp	byte ptr [si],0ah
	je	badcomm 		; or lf also is bad
	inc	si			; point to next char
	inc	cx			; up character count
	jmp	falpha			; search through line for '='
nocomm:
	mov	al,1			; no more commands return code
	ret				; end of getcomm
verify1:
	dec	si			; point to char before '='
	cmp	byte ptr [si],' '	; blank?
	jne	verify2
	dec	cx			; don't count blanks
	jmp	verify1 		; take out all trailing blanks
verify2:
	inc	si			; point back past end of command
	sub	si,cx			; point to start of command
	call	upper			; convert to upper case
	xor	al,al
	ret
badcomm:
	mov	al,1
	or	cx,cx			; anything found?
	jnz	$+3
	ret				; return with no command code
	sub	si,cx			; point to start of line for error processing
	mov	al,2			; bad command code
	ret				; end of getcomm
getcomm endp

	subttl getparm - get config command parameters
	page
;======================================================================
;,fs
; getparm - get config command parameters
;
; this routine will retrieve a config command's parameters,
; either in string or numerical format.
;
; in:	ds -> cnfbuf (segment)
;	si points to the '=' in the command or just prior to it
;	al = processing code:	0 - process as string
;				1 - process as decimal number
;				2 - process as hexadecimal number
;	ah = 0 if a blank is a string terminator
;	ah<>0 if a blank is not a string terminator (and don't advance
;		past the '=' , i.e. parse the rest of the same line)
;
; out:	if string ds:si points to start of parm, cx = length (if string)
;	if number ax = value 1, cx = value 2
;
;,fe
;=====================================================================
	assume	ds:cnfbuf,es:nothing,ss:tcb
lproc	getparm
lword	num1
lword	place
	mov	[num1],0		; init
	mov	[place],10		; init
	xor	cx,cx
	dec	si			; set up for search
	or	ah,ah			; continue parse on same line?
	jz	geteq			; no, this is a fresh line
	inc	si			; correct for starting position
	jmp	blknoend		; continue on
geteq:
	inc	si
	cmp	byte ptr [si],'='	; start yet?
	je	pasblk			; e means we've found it
	cmp	byte ptr [si],0dh	; else check for end of line signals
	je	endstr			; (cr or lf finishes it also)
	cmp	byte ptr [si],0ah
	jne	geteq			; advance until '='
	jmp	endstr
pasblk:
	inc	si			; point past undesirables
	cmp	byte ptr [si],' '	; blanks?
	je	pasblk			; yes, skip it
	cmp	byte ptr [si],09	; tabs?
	je	pasblk			; yes, skip it
getstring:
	or	ah,ah			; is a blank a valid terminator?
	jnz	blknoend		; no, not here
	cmp	byte ptr [si],' '	; blanks?
	je	endstr			; yes, a blank terminates string
blknoend:
	cmp	byte ptr [si],0dh	; cr?
	je	endstr			; yes, a cr terminates string
	cmp	byte ptr [si],0ah	; so does a lf
	je	endstr
	cmp	byte ptr [si],1ah	; cntrl-z (last line in config.sys)
	je	endstr
	inc	si
	inc	cx
	jmp	getstring
endstr:
	sub	si,cx			; point to start of string
	call	upper			; all uppercase for strings and hex numbers
	or	al,al			; process as string?
	jne	$+5			; no, number
	jmp	getprmx 		; end getparm for strings
	cmp	al,2			; process as hex?
	jne	nohex
	mov	word ptr [place],16	; set hex place holder value
nohex:
	mov	cx,ax			; cx holds number type flag
	dec	cx			; cx=0 if dec, or =1 for hex
	xor	ax,ax			; ax will hold running total
	xor	bh,bh			; clear high byte for adds in 'addlp'
	xor	dl,dl			; init digit counter
addlp:
	inc	dl
	cmp	dl,5			; only count the 1st 4 digits
	je	endnum			; ok we got 4 digits
	mov	bl,[si] 		; get next number
	cmp	bl,'0'			; check if in range
	jb	endnum			; nothing more to number
	cmp	bl,'9'			; check if in range
	ja	chkhex			; process if hexadecimal
	sub	bl,'0'			; make binary
cntlp:
	push	dx
	mul	[place] 		; last number gets moved one place holder
	pop	dx
	add	ax,bx			; add in new number
	inc	si			; point to next character
	jmp	addlp			; next
chkhex:
	or	cx,cx			; is this a hex number
	je	endnum			; no, exit no more numbers
	cmp	bl,'A'			; check range
	jb	endnum			; out of range
	cmp	bl,'F'
	ja	endnum
	sub	bl,55			; calc hex equivalent
	jmp	cntlp			; continue in loop
endnum:
	mov	bl,[si]
	inc	si			; next char
	cmp	bl,13			; is this the end of this line
	je	strtrm
	cmp	bl,10
	je	strtrm
	cmp	bl,','			; is there a 2nd number?
	je	do2nd			; yes, get that one
	jmp	endnum			; ignore any other junk
strtrm:
	mov	cx,ax
	mov	ax,[num1]		; get 1st number into ax
	or	ax,ax			; was there a second number?
	jz	$+5			; no
	jmp	getprmx 		; end of getparm for numbers, 2
	mov	ax,cx			; get 1st back for return
	xor	cx,cx			; clear 2nd number
	jmp	getprmx 		; end of getparm for numbers, 1
do2nd:
	mov	[num1],ax		; temp save 1st number
	xor	ax,ax
	xor	dl,dl			; reset digit counter
	jmp	addlp			; process 2nd number
getprmx:
lundef	num1
lundef	place
lendp	getparm

	subttl readcnf - read config.sys file into memory
	page
;======================================================================
;,fs
; readcnf - read config.sys file into memory
;
; this subroutine will open and read the entire config.sys
; file into a buffer starting at first available space.  this
; routine will also issue 2 error messages, one if no config.sys
; file is found and the second if any file error occurs.
; this routine will also concat any lines that end with a '~'
;
; in:	ds -> grp
;
; out:	the zf will be set if the config.sys file was successfully read
;
;,fe
;=====================================================================
	assume	ds:grp,es:nothing,ss:nothing
readcnf proc near
	push	ds
	push	cs
	pop	ds			; address local data for mos call
	assume	ds:init
	mov	ax,3d00h		; open file for reading
	lea	dx,cnfile
	cfmos ifar21
	pop	ds
	assume	ds:grp
	ljc	cnferr
	mov	[icnfhdl],ax		; save handle
	mov	bx,ax
	mov	ax,4202h		; lseek to eof (determine file size)
	xor	cx,cx			; offset 0
	xor	dx,dx
	cfmos ifar21
	ljc	cnferr
	push	ax
	mov	ax,4200h		; lseek back to beginning of file
	xor	cx,cx			; offset 0
	xor	dx,dx
	mov	bx,[icnfhdl]
	cfmos ifar21
	pop	cx			; get # bytes to read
	ljc	cnferr
	mov	dx,cx			; # bytes in config.sys file
	add	dx,5			; room for file terminator (ours) + leading and trailing cr, lf
	add	dx,0fh			; round up to next para boundary
	shr	dx,1			; calc # para's needed
	shr	dx,1
	shr	dx,1
	shr	dx,1
	xor	ah,ah			; allocate block on heap
	add	dx,ddtlen		; room for dd pointer table and prefix
	mov	cs:[cnfsize],dx
	cfmos mosheman			; use heap storage
	or	al,al			; any errors?
	jz	cnfhpok
ihperr:
	push	word ptr cs:[initmos]
	mov	ax, offset mos:hperr
	push	ax
	retf
cnfhpok:
	push	ds
	mov	ds,[initmos]
	assume	ds:mos
	mov	[cnfseg],es		; seg address of config data
	pop	ds
	assume	ds:grp
	mov	di,offset cnfbuf:ddnum	; start of data in 'cnfbuf' segment
	xor	al,al			; init data area to 0
	push	cx			; save file size
	mov	cx,ddinitcnt
	cld
	rep	stosb			; init to 0s
	pop	cx			; get file size back
	mov	bx,[icnfhdl]
	push	ds
	mov	ds,[initmos]
	assume	ds:mos
	mov	ds,[cnfseg]		; address buffer area in heap
	assume	ds:cnfbuf
	lea	dx,cnffile		; load config.sys file after dd pointer table
	add	dx,2			; room for inserted cr,lf
	mov	di,dx			; save offset of buffer
	mov	ax,0a0dh		; put in a false cr,lf for 1st call
	mov	[di-2],ax		;  to getcomm
	mov	ax,3f00h		; read file
	cfmos ifar21			; read config.sys into buffer space
	jnc	cnfgotit
	pop	ds
	assume	ds:grp
	jmp	cnferr
cnfgotit:
	assume	ds:cnfbuf
	push	di
	add	di,ax			; point to end of file using bytes read
	mov	word ptr [di],0a0dh	; ensure trailing cr, lf
	mov	byte ptr [di+2],1ah	; ensure file terminator
	pop	di
	mov	cx,ax			; size
	mov	ah,3eh			; close config.sys file
	mov	bx,[icnfhdl]		; file handle
	cfmos ifar21
	pop	ds
	assume	ds:grp
	ljc	cnferr

; resolve ~ lines (continuation lines) cx=len, es:di-> start of config

	push	ds
	push	es
	pop	ds
	assume	ds:cnfbuf
	push	si
cntscn:
	mov	al,'~'
	repne scasb			; scan for continuation character
	jnz	nocnt			; exit loop if none found
	mov	si,di			; di now points past the ~
	dec	si			; make si point to the ~

; parse past all whitespace

skpcnt:
	cmp	byte ptr [di],' '
	je	skpxx
	cmp	byte ptr [di],9
	jne	xx1
skpxx:
	dec	cx			; update count
	inc	di			; skip this char
	jmp	skpcnt
xx1:
	cmp	word ptr [di],0d0ah
	je	skpyy
	cmp	word ptr [di],0a0dh
	jne	cntscn
skpyy:
	mov	word ptr [di],'  '	; clear out line terminator
	sub	cx,2
	add	di,2
	mov	byte ptr [si],' '	; clear ~ from buffer
	jmp	cntscn
nocnt:
	pop	si
	xor	al,al			; set zf for return
	pop	ds
	assume	ds:grp
	ret
cnferr:
	push	ds
	push	cs
	pop	ds
	assume	ds:init
	lea	dx,msgfile
	cmp	al,2			; is it a 'File not found' error?
	jnz	errnext
	lea	dx,msgnone		; yes, no config.sys file to process
errnext:
	aam
	add	ax,3030h		; ascii
	xchg	al,ah
	mov	word ptr [errno],ax	; include error number in message
	call	idispmos
	pop	ds
	assume	ds:grp
	or	ah,ah			; clear zf for return flag
	ret
readcnf endp 

;======================================================================
;,fs
; upper
;
; this subroutine will translate a string pointed to by ds:si of length
; cx to upper case.  all registers preserved.
;
; in:	
;
; out:	
;
;,fe
;=====================================================================
	assume	ds:nothing,es:nothing,ss:nothing
upper proc near
	or	cx,cx			; check for 0 length string
	jnz	$+3
	ret				; exit here
	push	ax
	push	cx
	push	si
upnext:
	mov	al,[si] 		; get character
	cmp	al,'a'
	jb	donext
	cmp	al,'z'
	ja	donext
	sub	al,' '			; make it upper case
	mov	[si],al
donext:
	inc	si
	loop	upnext
	pop	si
	pop	cx
	pop	ax
	ret
upper endp

	subttl prntln - print line to crt
	page
;======================================================================
;,fs
; prntln - print line to crt
;
; in:	ds:si points to a line terminated by a lf
;
; out:	none
;
;,fe
;=====================================================================
	assume	ds:nothing,es:nothing,ss:nothing
prntln	proc	near
	push	ax
	push	dx
	push	si
	push	si			; save string pointer
	mov	al,0ah			; end of line marker
	dec	si
prnlp:
	inc	si
	cmp	[si],al 		; end of line?
	jne	prnlp
	inc	si			; point past lf
	mov	ax,[si] 		; save value here
	mov	word ptr [si],'$'*256+0dh  ; put in string terminator + cr
	pop	dx			; get string pointer (was si)
	push	ax
	call	idispmos		;021588
	pop	word ptr [si]		; put back what was there
	pop	si
	pop	dx
	pop	ax
	ret				; end of prntln
prntln	endp

	subttl getmpsw - get master password if needed
	page
;======================================================================
;,fs
; getmpsw - get master password if needed
;
; test for existence of the file 'boot:\$$MASTER.SYS'
; if present, then request the master password from the user and
; store it in scbkey
;
; in:	none
;
; out:	scbkey set with master password to use
;
;,fe
;=====================================================================
	assume	ds:nothing,es:nothing,ss:nothing

usrpath db	'\$$MASTER.SYS',0
usrmsg	db	0dh,0ah,'Enter Master Password: $'  ;@@xlat
usrpsw	db	6 dup(0)

public	getmpsw
getmpsw proc	near
	push	es
	push	ds
	mov	dx,cs
	mov	ds,dx
	lea	dx,[usrpath]
	mov	ah,4eh			; read-only access
	mov	cx,0086h		; find it even if system or hidden or secure
	cfmos	ifar21
	jnc	gmpsw1
	pop	ds
	pop	es
	ret

; since the file exists, then security exists

gmpsw1:
	lea	dx,usrmsg		; 'Enter Master Password: '
	mov	ah,09h
	cfmos	ifar21
	mov	di,ds
	mov	es,di
	lea	di,[usrpsw]		; clear password buffer to 0's (representing
	xor	ax,ax			; spaces)
	stosw
	stosw
	stosw
	lea	di,[usrpsw]

; get 6-char user input master password
; nothing is echoed
; backspace removes last character entered
; escape removes all characters entered
; enter accepts all characters entered
; 0 - 9 and a through z (case doesn't matter) are acceptable characters
; all other keys, escape and backspace with no characters entered or
;   acceptable characters with 6 characters already entered will beep

gmpsw2:
	mov	ah,06h
	mov	dl,0ffh
	cfmos	ifar21
	jz	gmpsw2
	or	al,al
	jnz	gmpsw3
	mov	ah,06h			; function key (or at least extended code) hit
	mov	dl,0ffh
	cfmos	ifar21
	jmp	gmpsw8

; some character key or control key hit (ascii or extended ascii)

gmpsw3:
	cmp	al,0dh
	je	gmpsw9			; finished when carriage return
	cmp	al,08h
	jne	gmpsw4

; backspace hit - back up one char

	cmp	di,offset init:usrpsw
	je	gmpsw8
	dec	di
	mov	byte ptr [di],0
	jmp	gmpsw2
gmpsw4:
	cmp	al,1bh
	jne	gmpsw6

; escape hit - backspace to beginning if not at beginning

	cmp	di,offset init:usrpsw
	je	gmpsw8
gmpsw5:
	dec	di
	mov	byte ptr [di],0
	cmp	di,offset init:usrpsw
	jne	gmpsw5
	jmp	gmpsw2
gmpsw6:

; some password key hit (most likely)
; it's ok if we're not at the end of the buffer and it's a 0-9 or A-Z
; translate keys to base 37 digit as described below

	cmp	di,offset init:usrpsw+6
	je	gmpsw8
	cmp	al,'0'
	jb	gmpsw8
	cmp	al,'9'
	jbe	gmpsw7
	cmp	al,'A'
	jb	gmpsw8
	cmp	al,'Z'
	jbe	gmpsw6a
	cmp	al,'a'
	jb	gmpsw8
	cmp	al,'z'
	ja	gmpsw8
	sub	al,'a'-'A'
gmpsw6a:
	sub	al,'A'-('9'+1)
gmpsw7:
	sub	al,'0'-1
	stosb
	jmp	gmpsw2

; beep for invalid keys

gmpsw8:
	mov	ah,06h
	mov	dl,07h
	cfmos	ifar21
	jmp	gmpsw2

; display new-line

gmpsw9:
	mov	dl,0dh
	mov	ah,06h
	cfmos	ifar21
	mov	dl,0ah
	mov	ah,06h
	cfmos	ifar21

; translate password to binary
; treat password as a 6-digit, base 37 number and convert it to binary
; the first char entered is the least significant digit
; each char not entered is a space
; space is 0
; 0 - 9 is 1 - 10
; a - z is 11 - 36

	lea	di,[usrpsw]
	xor	ax,ax
	xor	dx,dx
	mov	bx,37			; ' ' + '0'-'9' + 'A'-'Z' is 37 possibilities
	mov	cx,6			; 6 bytes long
gmpsw10:
	mov	si,ax			; multiply dx:ax by 37 giving dx:ax
	mov	ax,dx
	mul	bx
	xchg	ax,si
	mul	bx
	add	dx,si
	add	al,byte ptr [di]	; add next digit
	inc	di
	adc	ah,0
	adc	dx,0
	loop	gmpsw10
	mov	ds,cs:[initgrp]
	assume	ds:grp
	mov	word ptr [scbkey],ax	; store the key
	mov	word ptr [scbkey+2],dx
	pop	ds
	pop	es
	ret
getmpsw endp

	subttl initp2 - init internal device drivers
	page
;======================================================================
;,fs
; initp2 - init internal device drivers
;
; initialize internal device drivers: disk drivers and character
; drivers con, aux, prn, nul, clk
; note that this routine is called two times, the first time to set up
; device i/o for any memman driver to use (this is when a temporary
; heap is used), and the second time to establish the permenant home
; of the standard drivers.
;
; in:	ds -> grp
;
; out:	none
;
;,fe
;=====================================================================
	assume	ds:grp,es:nothing,ss:nothing
public	initp2
initp2	proc	near
	push	es
	mov	es,[initmos]
	assume	es:mos
	push	[mosaddr]		; use correct driver
	pop	es
	lea	bx,scbstdcon		; init standard in and out (console device)
	call	dodrvr
	push	[mosaddr]		; use correct driver
	pop	es
	lea	bx,mosstdclk		; init standard clk
	call	dodrvr
	push	[mosaddr]		; use correct driver
	pop	es	 
	lea	bx,scbcom24		; init devices in mosdevs.asm
	call	dodrvr
	push	[mosaddr]		; use correct driver
	pop	es
	lea	bx,scbstdblk		; init standard disk driver
	call	dodrvr
	push	[mosaddr]		; use correct driver
	pop	es
	lea	bx,scbstdhd		; init standard hard disk driver
	call	dodrvr
	mov	[first],2
	pop	es
	assume	es:nothing
	ret
initp2	endp

	subttl dodrvr - init driver at es:bx
	page
;======================================================================
;,fs
; dodrvr - init driver at es:bx
;
; in:	ds -> grp
;	es:bx -> driver
;
; out:	
;
;,fe
;=====================================================================
	assume	ds:grp,es:nothing,ss:nothing
dodrvr	proc	near
	mov	al,[first]		; 0 for first pass, 2 for second
	cfmos	mosddint
	or	al,al			; any errors?
	jz	$+5			; no
	jmp	idrverr 		; yes, driver init error
	ret
dodrvr	endp

	subttl opendev - open std devices
	page
;======================================================================
;,fs
; opendev - open std devices
;
; this routine will open all of the standard devices (handles 0-4)
; the system psp is also setup for use to init all new tasks.
; the standard devices are opened in the following order for dos psp
; handle table compatibility: aux,con,prn.  the handle table is then
; set to 01,01,01,00,02.
;
; in:	
;
; out:	
;
;,fe
;=====================================================================
	assume	ds:grp,es:nothing,ss:tcb

stdcon	db	'CON',0
stdaux	db	'AUX',0
stdprn	db	'PRN',0

public	opendev
opendev proc	near
	push	ds
	push	cs
	pop	ds
	assume	ds:init
	lea	dx,stdaux		; name for stdaux (handle 3, system 0)
	mov	ax,3d01h		; open for write
	push	[tcbpsp]
	mov	[tcbpsp],0		; set mos as owner of device
	cfmos	ifar21			; call mos
	jnc	opndv1
	pop	[tcbpsp]
	jmp	idrverr 		; yes, driver init error
opndv1:
	lea	dx,stdcon		; name for stdcon (handles 0,1,2, system 1)
	mov	ax,3d02h		; open for read and write
	cfmos	ifar21			; call mos
	jnc	opndv2
	pop	[tcbpsp]
	jmp	idrverr 		; yes, driver init error
opndv2:
	lea	dx,stdprn		; name for stdprn (handle 4, system 2)
	mov	ax,3d01h		; open for write
	cfmos	ifar21			; call mos
	pop	[tcbpsp]
	jnc	opndv3
	jmp	idrverr 		; yes, driver init error
opndv3:
	push	es
	mov	es,[tcbpsp]		; address system psp
	assume	es:pspseg
	les	di,[psppntr]		; get pointer to handle table
	mov	byte ptr es:[di+0],01	; set handle for stdin
	mov	byte ptr es:[di+1],01	; set handle for stdout
	mov	byte ptr es:[di+2],01	; set handle for stderr
	mov	byte ptr es:[di+3],00	; set handle for stdaux
	mov	byte ptr es:[di+4],02	; set handle for stdprn
	pop	es
	assume	es:nothing
	pop	ds
	assume	ds:nothing
	ret
opendev endp

idrverr:
	push	word ptr cs:[initmos]
	mov	bx, offset mos:drverr
	push	bx
	retf

	subttl	tempcache
	page
;======================================================================
;,fs
; tempcache
;
; establish temporary buffering during startup
; this persists until mos is relocated to final resting place, when
;   initcache must be called before any further disk i/o
;
; in:	ax = segment address to start
;
; out:	
;
;,fe
;=====================================================================
	assume	ds:nothing,es:nothing,ss:nothing
public	tempcache
tempcache proc	near
	push	ds

; default config.sys parameters

	mov	ds,[initgrp]
	assume	ds:grp
	mov	[scbck],tmpck		; 4 - 1k buffers to start
	mov	[scbcbk],tmpcbk 	; 1 k buffers to start
	mov	[scbcbits],tmpcbits
	mov	[scbcwf],0		; write-through
	mov	[scbcwl],0
	mov	word ptr [scbcd],0	; init cache off for all drives
	mov	word ptr [scbcd+2],8000h; config.sys turns on selected drives
	call	initcache

; prepare parameters for config.sys

	mov	[scbcsysk],0		; no k for device=$cache.sys yet
	mov	[scbck],0		; 0k of cache (to determine if it's been set)
	push	ax			;mjs@
	call	getdfcbk		;mjs@
	mov	[scbcbk],ax		;mjs@ default unit of bufering
	pop	ax			;mjs@
	mov	[scbcbits],dftcbits
	pop	ds
	assume	ds:nothing
	ret
tempcache endp

	subttl	initcache
	page
;======================================================================
;,fs
; initcache
;
; initialize caching according to current parameters of:
;
; in:	scbck - cache=k
;	scbcsysk - device=$cache.sys m
;	scbcd - bit map of drives to be cached
;
; out:	scbcuob - para size of unit of buffering
;	scbcnum - # cache buffers
;
;,fe
;=====================================================================
	assume	ds:nothing,es:nothing,ss:nothing
public initcache
initcache:
	push	es
	push	ds
	mov	es,[initmos]
	assume	es:mos
	mov	ds,[initgrp]
	assume	ds:grp
	cmp	[scbck],0
	jne	initc1			; ne if cache= was specified
	mov	ax,[scbcsysk]
	mov	[scbck],ax
	or	ax,ax			; nz if device=$cache.sys was specified
	jnz	initc1
	mov	[scbck],dftck		; default k if nothing was specified
initc1:
	xor	dx,dx
	mov	ax,[scbck]		; + total k for cache
	div	[scbcbk]		; k for each cache element
	cmp	ax,4096
	jb	initc2a 		; no more than 64k in cache descriptor list
	mov	ax,4096
initc2a:
	mov	[scbcnum],ax		; number of cache elements to be allocated
	mov	[scbcclr],ax
	mov	dx,[scbcbits]
	mov	cl,3			; log2(1024/8/16) = 10-3-4 = 3
	shl	dx,cl			; # paras in bit map
	mov	[scbcbmsz],dx
	add	ax,dx

; allocate cache descriptor list

	xor	bx,bx			; finddm - allocate if found
	call	sfinddm
	mov	[scbcbmap],ax
	or	ax,ax
	jnz	initc5
	mov	ax,[scbfree]
	mov	[scbcbmap],ax
	add	ax,[scbcbmsz]
	add	ax,[scbcnum]
	cfmos	updfree
initc5:
	mov	ax,[scbcbmap]
	add	ax,[scbcbmsz]
	mov	[scbclst],ax

; clear cache bit map to 0's

	push	es
	mov	es,[scbcbmap]
	xor	di,di
	mov	cx,[scbcbmsz]
	shl	cx,1			; convert from paras to words
	shl	cx,1
	shl	cx,1
	xor	ax,ax
	rep	stosw
	pop	es
	test	[scbmmfea],80h
	jnz	initc2

; allocate cache, non-memory-managed

	mov	ax,[scbcbk]		; k for each cache element
	mov	cl,6
	shl	ax,cl
	mov	[scbcuob],ax		; paragraph size of each cache element
	mul	[scbcnum]
	mov	cx,[scbfree]
	mov	[scbchdl],cx		; start segment of cache
	add	ax,cx
	cfmos	updfree
	jmp	initc4
initc2:

; allocate cache, memory-managed

	mov	ax,[scbcnum]		;051488
	mul	[scbcbk]
	shr	ax,1
	shr	ax,1
	or	ax,ax
	jnz	initc2b
	inc	ax
initc2b:
	mov	cx,ax
	mov	ah,1
	call	[scbmmsub]
	mov	[scbchdl],bx
	shl	cx,1
	shl	cx,1
	mov	ax,cx
	xor	dx,dx
	div	[scbcbk]
	cmp	ax,[scbcnum]		;jrbw (if memman gives us more than we asked
	ja	initc3			;jrbw for, we still only want what we have
					;jrbw allowed for)
	mov	[scbcnum],ax		; number of cache elements actually allocated
	mov	[scbcclr],ax
	or	ax,ax
	jnz	initc3

; couldn't get it from memman - reset to defaults and try non-memman code

	push	ax			;mjs@
	call	getdfcbk		;mjs@
	mov	[scbcbk],ax		;mjs@
	mov	[scbck],dftck
	mov	[scbcsysk],0
	mov	word ptr [scbcd],0
	mov	word ptr [scbcd+2],8000h; cache off for all drives
	push	cx			;mjs@
	push	dx			;mjs@
	xor	dx,dx			;mjs@
	mov	cx,ax			;mjs@
	mov	ax,dftck		;mjs@ calc  dftck/dftcbk
	div	cx			;mjs@
	pop	dx			;mjs@
	pop	cx			;mjs@
	mov	[scbcnum],ax
	pop	ax
	mov	[scbcclr],ax
	jmp	initc2			;jrbw leave descriptors over-allocated
initc3:
	mov	cl,6
	mov	ax,[scbcbk]
	shl	ax,cl
	mov	[scbcuob],ax		; paragraph size of cache element
initc4:

; init cache descriptor list

	mov	bx,[scbclst]		; cache descriptor list start segment
	mov	[scbcupf],0
	mov	cx,[scbcnum]
	push	ds
	mov	ds,bx
	assume	ds:nothing
	xor	ax,ax
	mov	bx,ax
	mov	di,ax

; initing descriptors for good areas of disk

initl1:
	mov	[bx].cstatus,0		; mark unused but good
	mov	[bx].cnumsct,0
	mov	[bx].cuseprv,si
	mov	[bx].clocnxt,-1
	mov	[bx].clocprv,-1
	mov	si,bx
	add	bx,16
	mov	[si].cusenxt,bx
	loop	initl1
	mov	[si].cusenxt,di
	mov	[di].cuseprv,si
	pop	ds
	assume	ds:grp

; init scb parameters pointing into cache list

	mov	[scbccur],0		; nothing current
	mov	ax,[scbcwf]		; config.sys version of write-delay
	mov	[scbcwrf],ax		; write-delay set as needed
	mov	ax,[scbcwl]		; config.sys version of write-delay
	mov	[scbcwrl],ax		; write-delay set as needed

	mov	ax,[scbcwsys]		; from config.sys
initl1a:
	cmp	ax,100
	jbe	initl1b
	mov	ax,100
initl1b:
	mul	[scbcnum]
	mov	cx,100
	div	cx
	mov	[scbcwmax],ax
	mov	[scbcwnum],0

; init head of location list for each bdb
;   (remaining bdb parameters are set in mosddint during setbdb)

	mov	ax,[scbbdbpf]
initl2:
	or	ax,ax
	jz	initl3
	mov	ds,ax
	assume	ds:bdb
	mov	[bdbclpf],-1
	mov	ax,[bdbnext]
	jmp	initl2
initl3:
	pop	ds
	pop	es
	assume	ds:nothing,es:nothing
	ret

camos	proc	near
	push	ax
	push	ds
	mov	ds,cs:[initmos]
	assume	ds:mos
	mov	ax,cs:[imosaddr]
	mov	[sinitaddr],ax
	pop	ds
	pop	ax
	call	dword ptr cs:[mscall]
	ret
camos	endp

incall	proc	far
	call	cs:[imosaddr]
	ret
incall endp

	subttl prereadcmd - pre-read command processor to get size
	page
;======================================================================
;,fs
; prereadcmd - pre-read command processor to get size
;
; this procedure is use to maximize freemem by pre-reading command processor
; size via function 42 and setting scbcpsiz, and later before allocation
; cache areas, we will allocate command processor area in freemem
;
; in:	
;
; out:	
;
;,fe
;=====================================================================
	assume	ds:nothing,es:nothing,ss:nothing
prereadcmd proc near
	push	cx
	push	ds
	mov	ds,[initgrp]
	assume	ds:grp
	mov	[scbcpsiz],00h		; clear size
	mov	ds,cs:[initmos]
	assume	ds:mos
	lea	dx,[cpres]		; string "$$shell.sys",0
	mov	ax,3d00h
	cfmos	ifar21
	jc	preexit
	mov	bx,ax
	xor	cx,cx
	xor	dx,dx
	mov	ax,4202h		; get end of file for lenght
	cfmos	ifar21
	push	ax
	mov	ah,3eh			; close file
	cfmos	ifar21
	pop	ax
	add	ax,0fh			; round up to next paragraph
	shr	ax,1
	shr	ax,1			; convert return count to paragraphs
	shr	ax,1
	shr	ax,1
	mov	ds,[initgrp]
	assume	ds:grp
	mov	[scbcpsiz],ax		; save size in scb for later
preexit:
	pop	ds
	pop	ax
	ret
prereadcmd endp 

	subttl chkcompaq - check to see if compaq 386 style ega rom
	page
;======================================================================
;,fs
; chkcompaq - check to see if compaq 386 style ega rom
;
; this procedure will check for compaq's EGA rom and if
; found it will alter int 10, 1f and 43 vectors to c000
; and unprotects e000. this is done through int 15 function 87
; call so that it works on both the 386 and 386sx processors
; (since 386sx cannot access more than 16 meg.)
;
; in:	
;
; out:	
;
;,fe
;=====================================================================
	assume	ds:nothing,es:nothing,ss:nothing

low_address	dw	05555h
high_address	dw	0aaaah
new_8c0000	dw	000ffh		; attribute for clear protect
					; and free 128k use by bios

gdt		label	byte
dummy_des	dq	0
des_for_gdt	dq	0

des_source	label	byte
sseg_limit	dw	2
slow_address	dw	0
shigh_address	db	0
saccess_rights	db	92h
		db	0
saddress_24_31	db	0

des_dest	label	byte
dseg_limit	dw	2
dlow_address	dw	0
dhigh_address	db	0c0h
daccess_rights	db	92h
		db	0
daddress_24_31	db	80h

des_prot_code	dq	0
des_prot_stack	dq	0

compaqid	db	'03COMPAQ'


chkcompaq proc	near
	push	ax
	push	bx
	push	cx
	push	dx
	push	si
	push	di
	push	ds
	push	es

; check to see if we are on a compaq with a compaq ega\vga

	push	cs
	pop	ds
	mov	ax,0f000h
	mov	es,ax
	mov	di,0ffe8h
	mov	si,offset compaqid
	mov	cx,8
	rep	cmpsb			; search for '03COMPAQ'
	jne	notcompaq
	mov	cx,0e000h		; shadow ram segment
	xor	ax,ax
	mov	es,ax
	cmp	cx,word ptr es:[10h*4+2]; is segment e000h
	jne	contcompaq
	cmp	cx,word ptr es:[1fh*4+2]; is segment e000h
	jne	contcompaq
	cmp	cx,word ptr es:[43h*4+2]; is segment e000h
	je	okcompaq
	jmp	short contcompaq
notcompaq:
	jmp	donecompaq
okcompaq:

; at this point we have determine that we are on a compaq 386
; machine with a compaq ega\vga on it
; now reset vectors 10, 1f and 43 to c000

	mov	cx,0c000h
	mov	word ptr es:[10h*4+2],cx
	mov	word ptr es:[1fh*4+2],cx
	mov	word ptr es:[43h*4+2],cx

; now for the fun part, use int 15 function 87 change
; 080c000h so that we can disable write protection and
; recovered the 128k extended memory use by bios

contcompaq:
	mov	ax,ds
	mov	bx,0010h
	mul	bx			; current segment x 16 = flat address
	mov	bx,offset new_8c0000
	add	ax,bx
	jnc	nocarry
	inc	dx
nocarry:
	mov	[slow_address],ax
	mov	[shigh_address],dl
	mov	[saddress_24_31],dh
	mov	[low_address],ax
	mov	[high_address],dx
	mov	cx,1
	push	cs
	pop	es
	mov	si,offset gdt
	mov	ah,87h
	int	15h			; bios write unprotect shadow ram
donecompaq:
	pop	es
	pop	ds
	pop	di
	pop	si
	pop	dx
	pop	cx
	pop	bx
	pop	ax
	ret
chkcompaq endp


	subttl initpa - general propose #1 init main code move to init segment
	page
;======================================================================
;,fs
; initpa - general propose #1 init main code move to init segment
;
; this contains portions of former mosinit main code which is now
; to init segment for reduction of mos segment for future transfer
; of code from mo2 to mos segment. (for total reduction in system
; memory required by the kernal
;
; in:	
;
; out:	
;
;,fe
;=====================================================================
	assume	ds:grp,es:nothing,ss:nothing
public	initpa
initpa	proc	near
;
; initially  init scb4013 to value at 40:13 so that calclim will
; work correctly with out memmory management
;
	xor	ax,ax
	mov	es,ax
	mov	ax,word ptr es:[413h]
	mov	[scb4013],ax
;
	mov	es,[initmos]
	assume	es:mos
	mov	ax,offset grp:gend+255	;rs1
	mov	al,0			;rs1
	mov	cl,4			;rs1
	shr	ax,cl			;rs1
	mov	[gseglen],ax		;rs1
	assume	ds:nothing,es:nothing
	call	chkcompaq		; undo compaq's EGA Rom
	mov	ds,[initgrp]
	assume	ds:grp

; place scbversn into scbdosver

	mov	ax,[scbversn]
	mov	[scbdosver],ax

; sah 07/14/88 calculate scbmo2end

	mov	es,[initmos]
	assume	es:mos
	mov	ax,offset mo2:mo2end+255
	xor	al,al
	mov	cl,4
	shr	ax,cl
	add	ax,[gseglen]		; add size of group
	mov	cx,ds
	add	ax,cx			; add start of group
	mov	[scbmo2end],ax

; following flag check if vna is installed on system
; if so sets flag in scb to indicated that it is

	push	ds
	push	es
	mov	cx,cs
	mov	es,cx
	mov	di,offset crmsg
	mov	si,0cc0h
	mov	cl,4
	shl	si,cl
	mov	ds,si
	cld
	mov	cx,offset crend
	sub	cx,di
	xor	bh,bh
	xor	si,si
regs1:
	lodsb
	xor	al,0abh
	sub	al,crlen
	add	al,cl
	sub	al,es:[di]
	inc	di
	or	bh,al
	loop	regs1

; if bh is zero than copyright is ok

	mov	ds,[initgrp]
	assume	ds:grp
	or	bh,bh			; is vna installed
	jnz	notvna
	mov	[scbvnasys],'Y' 	; yes so set flag
notvna:
	pop	es
	pop	ds

; initialize lowlevel memory mapping far calls

	mov	word ptr [scbmapvmf],offset mapvmf  ; set vma far routine
	mov	word ptr [scbmapvmf+2],es
	mov	word ptr [scbmapvsf],offset mapvsf  ; set vsa far routine
	mov	word ptr [scbmapvsf+2],es
	mov	word ptr [scbscang],offset scanguts  ; init scancode vector
	mov	word ptr [scbscang+2],es
	mov	word ptr [scbirqbnk],offset irqbank  ; init scancode vector
	mov	word ptr [scbirqbnk+2],es
	mov	es,[scbboot]		; address boot sector info
	assume	es:nothing
	mov	al,es:[drive]		; get drive id
	test	al,80h			; hard drive?
	jz	doflpy			; no

; booting from hard drive, get which partition from the info
; set by our master boot record (byte at top of memory is the
; partition #)

	and	al,7fh			; set mos drive id
	add	al,2			; start hard drives at c
	push	es
	push	ax
	int	12h			; get memory size
	mov	cl,6			; calc from k to paragraphs
	shl	ax,cl
	dec	ax
	mov	es,ax
	pop	ax			; get drive
	cmp	byte ptr es:[0fh],4	; is this a valid entry?
	jae	dftpart 		; no, skip it, try to boot from 1st part.
	add	al,byte ptr es:[0fh]	; calc drive letter to use
dftpart:
	pop	es			; original back
doflpy:

; note: the current al value is not really the final scbbootdrv value.
; for the case where the boot partition chosen (in a multi-boot situation)
; is 2, 3 or 4 and extended partitions are in use, the trueboot array
; will have to be used to derive the actual value.  the trueboot array
; is setup by the init logic of mosddblf.  it is applied to scbbootdrv
; after the first call to initp2.

	push	es
	mov	es,[initmos]
	assume	es:mos
	mov	[scbbootdrv],al 	; set drive for later file reads
	mov	[scbvidad],0b800h	; set default screen to color address
	mov	[scbdbprt],0b800h	; set default debugging port also
	mov	[scbvidpg],4		;#jrb 16k screen buffer
	mov	ah,15			; video state
	int	10h			; non-mos int 10h
	mov	[curmode],al		; save for later init of out int 10h stuff
	cmp	al,7			; is it mono?
	jnz	docolor 		; no
	mov	[scbvidad],0b000h	; yes, set seg address to monochrome
	mov	[scbdbprt],0b000h	; set default debugging port also
	mov	[scbvidpg],1		;#jrb 4k screen buffer (adjusted later if
					;#jrb	hercules card)
docolor:
;
; we will first need to transfer inplanted serial # into serial # for display
; what we do is transfer first 2 digits and add a dash, then remain 8 digits
;
	push	ds
	push	es
	mov	ax,cs
	mov	ds,ax
	mov	es,ax
	mov	si,offset enbedded+17
	mov	di,offset mossmsg+12
	sub	si,17
	sub	di,12
	cld
	movsw
	mov	al,'-'
	stosb
	mov	cx,4
	rep	movsw
	pop	es
	pop	ds
	mov	dx,125h 		; these values are use to fake some on out
	mov	bx,34h			; persons trying to changer serial #'s
	call	checkserial		; we are checking to make serial # is ok
	pop	es

; we will copy version # inplanted in init segment logo into scb
; variable scbsmsg so that it can later be display to use when
; system is running.

	push	ds
	push	ds
	pop	es
	push	cs
	pop	ds
	mov	si, offset mossmsg
	mov	di, offset scbsmsg
	cld
	mov	cx,11			; serial # is 11 bytes for display
	rep	movsb
	pop	ds
	ret
initpa	endp
	assume ds:nothing, es:nothing

	subttl initpb - general propose #2 init main code move to init segment
	page
;======================================================================
;,fs
; initpb - general propose #2 init main code move to init segment
;
; this contains portions of former mosinit main code which is now
; to init segment for reduction of mos segment for future transfer
; of code from mo2 to mos segment. (for total reduction in system
; memory required by the kernal
;
; in:	
;
; out:	
;
;,fe
;=====================================================================
	assume	ds:grp,es:nothing,ss:tcb
public	initpb
initpb	proc	near
	call	init1a			; set up temporary heap
	mov	[ddtmctcb],ss		; record tcb of master console (for mosint09)
	mov	ax,40h
	mov	es,ax
	mov	word ptr es:[1ah],200h
	mov	word ptr es:[1ch],200h
	mov	word ptr es:[80h],200h
	mov	word ptr es:[82h],280h
	call	initp9			; set mos interrupt vectors
	mov	word ptr [tcbddpf],-1
	mov	word ptr [tcbddpf+2],-1

; set up for master console driver
; note: that as of 1/2/87 the driver is located in grp
; init terminal driver

	mov	word ptr [tcbcondd],offset mo2:mcterm
	push	[initmo2]		;rs1
	pop	word ptr [tcbcondd+2]	;rs1
	push	ds
	push	ss
	pop	ds
	assume	ds:tcb
	mov	[tcbscrdd],ss
	mov	[tcbnxtdd],0
	xor	ax,ax
	lea	si,tcbcondd
	mov	[si+6],ax
	mov	word ptr [si+4],ax
	mov	word ptr [si+8],ax
	push	es
	mov	es,[initgrp]
	assume	es:grp
	lea	bx,[scbmapvmf]
	cfmos	ddtcallf		; check for busy and then call	;r8188
	mov	word ptr [tcbkeyrdy],bx
	mov	word ptr [tcbkeyrdy+2],es
	pop	es
	assume	es:nothing
	or	[tcbvram],al		; set if master console
	mov	[tcbscln],4096		; 4096 bytes for screen
	test	al,40h			; graphics?
	jz	nogrph
	mov	[tcbscln],16384 	; 16k video buffer
nogrph:
	test	al,10h			;#jrb see if herc (flag is tested below)
	push	es
	mov	es,[initmos]
	assume	es:mos
	mov	al,[curmode]
	pop	es
	assume	es:nothing
	mov	[tcbomode],al		; record it as fg original mode
	pop	ds
	assume	ds:grp
	jz	noherc			;#jrb here's where the herc flag is tested
	mov	[scbvidpg],16		;#jrbd 16 pages for physical screen if herc
noherc: 				;#jrb
	xor	ah,ah
	int	10h			; set mode (this clears the screen)

; write sign-on screen

	push	es
	push	cs
	pop	es
	lea	bp,msgon
	mov	ax,[scbversn+2] 	; get mos version number
	push	ax
	xor	ah,ah			; calc major #
	aam
	add	ax,3030h		; ascii
	cmp	ah,'0'			; clear any leading 0
	jne	sgonlz
	mov	ah,' '
sgonlz:
	xchg	al,ah
	mov	word ptr es:[msgonrn],ax;021588
	pop	ax
	xchg	al,ah			; calc minor #
	xor	ah,ah
	aam
	add	ax,3030h
	xchg	al,ah
	mov	word ptr es:[msgonrn+3],ax  ;021588
	mov	ax,[scbversn+4] 	; get type
	mov	byte ptr es:[msgonrn+5],al  ;021588
	mov	cx,cs:[msgleng] 	; get lenght of message
	xor	dx,dx			; start at tos
	mov	bx,0007h		;021588
	mov	ax,1301h		; string write
	int	10h

; setup tcbstation before processing config.sys, this is necessary
; for terminal drivers which need to determined what kind of master
; console is on the system. for example sunriver (srterm.sys) needs
; to detect is station is either and ega or vga to provide approviated
; driver execution.

	push	ss
	pop	es
	assume	es:tcb
	cfmos	initstation		; call mositask routine to init tcbstation
	mov	es,[initmos]
	assume	es:mos
	mov	es:[smthere],'Y'	;021588  indicate logo on the screen
	pop	es
	call	tempcache		;jrbr setup temporary buffering during startup
	call	initp2			; init internal device drivers

; now that mosddblf has been initialized, we know the true correspondence
; between partitions and drive letters.  if the value within scbbootdrv
; is for a hard disk partition past c: ([scbbootdrv] > 2) then 
; translate it into an index into the trueboot array to get the true
; boot drive number

	push	es
	mov	es,[initgrp]
	assume	es:grp
	cmp	[scbbootdrv],2
	jbe	tbt1
	push	bx
	mov	bl,[scbbootdrv]
	xor	bh,bh
	sub	bl,3
	mov	bl,[trueboot+bx]
	mov	[scbbootdrv],bl
	pop	bx
tbt1:
	pop	es

; initialize system psp data area
; system psp has been move to grp segment so it nolonger conflicts with
; mos loading in fff8 segment

	mov	es,[initgrp]
	lea	ax,grp:initpsp		; start with system psp
	shr	ax,1			; calc segment address
	shr	ax,1
	shr	ax,1
	shr	ax,1
	mov	bx,es
	add	ax,bx			; calc segment address of system psp
	mov	[tcbpsp],ax		; set as fgs psp for now
	mov	es,ax
	assume	es:pspseg
	mov	[pspterm],20cdh 	; set int 20
	mov	[pspfarc],0cdh		; int 21
	mov	[pspfarc+1],021h	; "
	mov	[pspfarc+2],0cbh	; retf
	mov	[psphdls],14h		; set size of handle table
	mov	word ptr [psppntr],18h	; offset of psp handle table
	mov	word ptr [psppntr+2],ax ; set segment of psp handle pointer
	mov	[pspcmd],13		; set terminating cr in command line
	cld
	mov	cx,[psphdls]
	les	di,[psppntr]		; get pointer to handle table
	mov	ax,0ffh
	rep	stosb
	push	es
	mov	es,[initgrp]
	assume	es:grp
	mov	dl,[scbbootdrv] 	; sah move up here for segment addressability
	mov	es,[initmos]
	assume	es:mos
	mov	ax,[tmpheap]
	add	ax,[tmphpsiz]		; calc end of memory
	pop	es
	assume	es:pspseg
	mov	[tcbendad],ax
	mov	[pspmem],ax		; set top of memory
	add	[scbshell],dl		; calc ascii of drive id
	add	[scbusrf],dl		; ascii put in userfile path as default
	mov	ah,0eh
	cfmos	ifar21			; set default drive
	call	opendev 		; open std devices
	lea	ax,init:msgon
	mov	[tcbdta],ax		; yes, this is cheating
	mov	[tcbdta+2],cs
	call	getmpsw 		; get master password if needed
	mov	grp:[mcsnow],0		; default to no desnowing
	call	procnfg 		; (initp3) read and process config.sys file
	call	prereadcmd		; pre-read command processor size
	assume	ds:grp,ss:tcb
	call	initp4			; process freemem and memdev commands

;jrbr no disk i/o from here until below where initcache is called and scbcseg
;jrbr	is initialized (initp4 has set scbmmfea enabling mm in the cache, but
;jrbr	the temporary start-up cacheing is initialized for no mm)
;jrbr note the actual start of the no disk i/o critical section occurs in
;jrbr	mminit which is called by initp4
;@@@@@@@@@@@@ clear open handles and close devices
; note: this must be done before mos relocation (initp5)
; clear std tfbs from old heap

	mov	bx,3			; aux
	mov	ah,3eh
	cfmos	ifar21
	mov	bx,0			; con
	mov	ah,3eh
	cfmos	ifar21
	mov	bx,4			; prn
	mov	ah,3eh
	cfmos	ifar21
	call	calcspace		; calculate space requirements
	push	ds
	mov	ds,[initmos]
	assume	ds:mos
	test	[dmflags],02h		; is smp to be relocated in freemen
	pop	ds
	assume	ds:grp
	jz	skipsmp
	call	initsmp 		; attempt to allocate smp in fremem
skipsmp:
;
; 	setup tcbendad from value by calcuating from scb4013
;
	mov	ax,[scb4013]
	shr	ax,1
	shr	ax,1
	mov	ah,al
	xor	al,al
	mov	[tcbendad],ax	
	ret
initpb	endp

	subttl initpc - general propose #3 init main code move to init segment
	page
;======================================================================
;,fs
; initpc - general propose #3 init main code move to init segment
;
; this contains portions of former mosinit main code which is now
; to init segment for reduction of mos segment for future transfer
; of code from mo2 to mos segment. (for total reduction in system
; memory required by the kernal
;
; in:	
;
; out:	
;
;,fe
;=====================================================================
	assume	ds:grp,es:nothing,ss:tcb
public	initpc
initpc	proc	near
	mov	ax,[scbtcbpc]		; sah (fix need for novell ipx)
	mov	[scbtcbps],ax		; sah initialize switch variables
	mov	[scbtcbvs],ax		; sah so that device drivers isrs
	mov	[scbtcbvr],ax		; sah can be correctly treated
	push	es
	mov	es,[initmos]
	assume	es:mos
	mov	ax,[scbfree]
	cfmos	updfree

if	code286
	test	[scbmmfea],08h		;021588  "declare" call supported?
	jz	mmdecx			;021588  no, skip
	mov	[scb286dec],'Y' 	;021588
	mov	ah,0ah			;021588  declare mos group as code
	mov	bx,[mosaddr]		;021588
	mov	cl,1			;021588
	call	[scbmmsub]		;021588
	mov	ah,0ah			;021588  declare mo2 as code
	mov	bx,[initmo2]		;021588
	mov	cl,1			;021588
	call	[scbmmsub]		;021588
	mov	ah,0ah			;021588  declare grp as data
	mov	bx,ds			;021588
	mov	cl,0			;021588
	call	[scbmmsub]		;021588
	mov	ah,0ah			;021588  declare tcb as data
	mov	bx,ss			;021588
	mov	cl,0			;021588
	call	[scbmmsub]		;021588

; set scb pointer for memman driver

mmdecx: 				;021588
endif

	test	[dmflags],10h		; special version of memman
	jnz	mmset100
	cmp	[scbmmfg],'Y'		; only if have mm
	jne	min100
mmset100:
	lea	ax,scbtcbpf		; get pointer to start of scb
	push	es
	push	di
	les	di,scbmmptr		; get pointer to memman data area
	mov	es:[di+parmscb],ax
	mov	es:[di+parmscb+2],ds
	pop	di
	pop	es
min100:
	mov	ax,[scbfree]
	cfmos	updfree
	test	[dmflags],04h		; has smp already been allocated
	pop	es
	assume	es:nothing
	jnz	min110			; yes...so skip allocation call
	call	initsmp 		; allocate smp
min110:

; test for smp #2 > cp allocation

	mov	[scbcpseg],00h
	cmp	[lowcount],0		; if ldevice then allocate command
	jne	docpal
	mov	ax,[scbhp2siz]		; test to see if heap #2 > cp
	cmp	ax,[scbcpsiz]
	ja	skipcpal		; skip command processor allocation
docpal:

; allocate freemem space for command processor

	mov	ax,[scbcpsiz]
	or	ax,ax
	jz	skipcpal
	mov	di,ax
	call	finddm			; find a block in dm large enough for it
	or	ax,ax			; find one?
	jz	skipcpal		; yes, we can move $$shell.sys to freemem
	mov	[scbcpseg],ax		; record location for command.com to enter
skipcpal:

; allocate space for secondary heap 

	cmp	[scbhp2siz],0		; skip secondary heap
	je	skipheap2
	mov	di,[scbhp2siz]
	cmp	[lowcount],0		; any low device allocate
	jne	dolow			; if so force second heap in low memory
	mov	ax,di
	call	finddm			; find a block in dm large enough for it
	or	ax,ax
	jz	dolow			; if non find must allocate heap down low
	mov	[scbhp2adr],ax		; save address
	jmp	short setuphp2		; setup heap # 2
dolow:

; we must allocate space in task memory for heap, this means that
; we either could not find space in highmem or user specified
; ldevice commands

	call	getscbfree
	mov	[scbhp2adr],ax
	add	ax,di
	cfmos	updfree
setuphp2:

; initialize heap #2

	mov	es,[scbhp2adr]
	mov	dx,di
	mov	ah,0feh
	cfmos	mosheman
skipheap2:

; attempt to allocated command processor 

	cmp	[scbcpseg],0		; command processor allocated
	jne	skipcpal2		; yes skip allocation
	mov	ax,[scbcpsiz]
	or	ax,ax
	jz	skipcpal2
	mov	di,ax
	call	finddm			; find a block in dm large enough for it
	or	ax,ax			; find one?
	jz	skipcpal2		; yes, we can move $$shell.sys to freemem
	mov	[scbcpseg],ax		; record location for command.com to enter
skipcpal2:

; enable trapping for the timer/counter chip 

	test	[scbmmfea],40h
	jz	min170a
	push	ds
	lds	si,[scbioptr]		; get pointer to memman data
	assume	ds:nothing
	or	byte ptr [si+8],00001101b  ; 43, 42, 40  mjs 1/19/88
	pop	ds
	assume	ds:grp
min170a:
	call	initcache		;jrbr allocate everything for cacheing

; allocate video save area 

	assume	ds:grp
	mov	bh,[scbvtype]
	and	bh,7fh			; mask off high bit
	mov	ax,2048 		;#jrb 32k in paras for hercules (vtype 5)
	cmp	bh,5			;#jrb
	je	min190			;#jrb
	mov	ax,1024 		;#jrb
	cmp	bh,2			; vtype=2 means only reserve 4k for video save
	jne	min190
	mov	ax,256			; # of paras for 4k
min190:
	mov	cl,ah			;#jrb
	xor	ch,ch			;#jrb
	mov	[scbmastp],cx		;#jrb remember max pages allowed in video save
	test	[scbmmfea],80h		;#jrb is full mapping supported?
	jnz	$+5			;#jrb yes
	jmp	min180			;#jrb if not, skip reservation of video save area
	mov	cx,ax			; save for later
	mov	bx,1			; tell finddm not to allocate
	call	sfinddm 		; can we use freemem for the video save area?
	or	ax,ax
	jnz	min200
	call	getscbfree		; mov	  ax,[scbfree]
	add	ax,000ffh
	and	ax,0ff00h		; round up to next 4k boundry
	mov	[scbmastv],ax
	add	ax,cx
	cfmos	updfree 		; set scbfree past video save area
	jmp	min180
min200:
	mov	[scbmastv],ax		; yes, we can put video save area in freemem
min180:

; allocate cache area area 

	test	[scbmmfea],80h		; is full mapping supported?
	jnz	$+5			; yes
	jmp	min180j 		; if not, skip reservation of cache map area
	mov	bx,[scbcuob]		; unit of cache buffer in para's
	or	bl,bl
	jz	min18j2 		; already in units of 4k
	test	bl,40h
	jnz	min18j1 		; nz if odd k
	add	bx,(2+3)*(1024/16)	; if even k, could start at 2nd k in page +
	jmp	min18j2 		;   rounding up to next higher 4k page
min18j1:
	add	bx,(3+3)*(1024/16)	; else odd, could start at 3rd k in
					;   page + rounding up to next higher 4k page
min18j2:
	mov	bl,0			; / ( 4096 / 16 ) * ( 4096 / 16 )
					; = max paras needed to map (rounded to 4k)
	mov	ax,bx
	mov	cl,ah
	mov	ch,0
min190j:
	mov	[scbcsegp],cx
	mov	cx,ax			; save for later
	mov	bx,1			; tell finddm not to allocate
	call	sfinddm 		; can we use freemem for the cache map area
	or	ax,ax
	jnz	min200j
	call	getscbfree		; no, have to use lower memory
	add	ax,000ffh
	and	ax,0ff00h		; round up to next 4k boundry
	mov	[scbcseg],ax
	add	ax,cx
	cfmos	updfree 		; set scbfree past cache map area
	jmp	min180j
min200j:
	mov	[scbcseg],ax		; yes, we can put cache map area
min180j:

;jrbr disk i/o is ok from here on
;jrbr cache is now set up according to config.sys, writes are delayed if
;jrbr	requested, drives are cached as specified, etc.

; allocate smp block for port specific irq reservations 

	xor	ah,ah
	mov	dx,25			; paragraphs for 6 irqs * 32 words each
	cfmos	mosheman		; plus 1 para for the header
	assume	es:nothing
	or	al,al
	jz	min180a
	jmp	ihperr
min180a:
	mov	bx,es
	inc	bx			; advance past the header
	cli				; no irq's until table is ready
	mov	[scbidqp],bx
	mov	es,bx
	mov	cx,6*32
	xor	ax,ax
	xor	di,di
	cld
	rep	stosw			; init the table to 0's
	sti

; declare vital workspace 

if	code286
	cmp	[scb286dec],'Y' 	; 286 declare calls supported
	jne	no286a			; no...skip
	mov	ah,0ah
	xor	cl,cl
	mov	bx,[scbmastv]		; declare master video area
	call	[scbmmsub]
	mov	ah,0ah
	xor	cl,cl
	mov	bx,[scbcseg]		; declare cache uob mapping area
	call	[scbmmsub]
	mov	ah,0ah
	xor	cl,cl
	mov	bx,[scbvidad]		; declare video card's RAM area
	call	[scbmmsub]
	mov	ah,0ah
	xor	cl,cl
	mov	bx,[scbhpadr]		; declare smp
	call	[scbmmsub]
	mov	ah,0ah
	xor	cl,cl
	mov	bx,[scbclst]		; declare cache descriptor list segment
	call	[scbmmsub]

; declare at sector offsets into scbcseg for cacheing
; sectors presumed no smaller than 512 bytes

	mov	cx,[scbcsegp]		;jrbw
	shl	cx,1			; 4096 byte pages -> 512 byte sectors
	shl	cx,1
	shl	cx,1
	mov	bx,[scbcseg]		;jrbw
do286cb:
	push	cx
	add	bx,512/16
	mov	ah,0ah
	xor	cl,cl
	call	[scbmmsub]
	pop	cx
	loop	do286cb
endif

; initialize a bunch of vars 

no286a:
	mov	[tcbtfbpf],0		; clear any active tfbs
	mov	[tcbcdbpf],0		; clear pointer to cdb
	mov	[tcbcdbpc],0		; clear pointer to cdb
	mov	[tcbndriv],0		; clear # of drives
	mov	[scbdrivs],0		; clear any count of drives for re-init
	mov	[scbbdbpf],0		; clear pointer to 1st block device
	mov	[scbbdbpl],0		; clear pointer to last block device
	mov	[scbgfbpf],0		; clear any active gfbs
	mov	[scbgfbpl],0		; clear any active gfbs
	mov	word ptr [scbstdin],0	; clear any standard device pointers
	mov	word ptr [scbstdin+2],0
	mov	word ptr [scbstdout],0
	mov	word ptr [scbstdout+2],0
	mov	word ptr [scbstdnul],0
	mov	word ptr [scbstdnul+2],0
	mov	word ptr [scbstdclk],0
	mov	word ptr [scbstdclk+2],0
	mov	word ptr [scbstdprn],0
	mov	word ptr [scbstdprn+2],0
	mov	word ptr [scbstdaux],0
	mov	word ptr [scbstdaux+2],0
	mov	ah,3			; get % heap used so far
	cfmos	mosheman
	push	word ptr [scbhpalc]	; save heap allocations
	push	word ptr [scbhp1alc]
	call	initp2			; re-init internal device drivers
					;  (we now have a real heap to use)

; clear any handle info from system psp

	push	es
	mov	es,[tcbpsp]		; address system psp
	assume	es:pspseg
	mov	cx,[psphdls]		; # of handles
	les	di,[psppntr]		; get pointer to handle table
	mov	ax,0ffh
	rep	stosb

; the following is necessary for micro-bernoulli

	mov	ax,[tcbpsp]		; sah get system psp
	dec	ax			; sah decrement 1 for mcb
	push	ss
	pop	es			; sah es -> tcb
	cfmos	initmcb 		; sah initialize
	cfmos	inidvars		; jsm 11/18/87 initialize dos variable table
	pop	es
	assume	es:nothing
okhere:

; initial vector 30 to far jump to mosoldfn

	push	es
	xor	ax, ax
	mov	es, ax			; point to zero segment
	mov	byte ptr es:[0c0h], 0eah
	mov	word ptr es:[0c1h], offset mosoldfn
	mov	ax, [scbmosadr]
	mov	word ptr es:[0c3h], ax
	mov	ax,es:[38h*4]		;sah 02/29/88
	mov	word ptr [scbfar38],ax	;sah set scbfar38 to dword
	mov	bx,es:[38h*4+2] 	;sah at vector 38h just in
	mov	word ptr [scbfar38+2],bx;sah case device drivers
	mov	es,[scbtcbpc]
	assume	es:tcb
	mov	word ptr [tcbtsk38],ax	; set tcb copy for context
	mov	word ptr [tcbtsk38+2],bx; set tcb copy for context
	pop	es
	assume	es:nothing

; re-open std devices so references are in real heap

	call	opendev 		; open std devices
	mov	ds,[initgrp]
	assume	ds:grp
	mov	dl,[scbbootdrv]
	mov	ah,0eh
	cfmos	ifar21			; set default drive

; copy freemem information into scb for later use

	push	ds
	push	es
	mov	ds,[initmos]		; access mos as source
	mov	es,[initgrp]
	mov	cx, 10			; 10 words
	lea	si, dmpatch
	mov	di, offset scbbuff
	cld
	rep	movsw
	pop	es
	pop	ds

; since some device drivers call int21fun4b03, must init scbfar21
; before calling initp8.  (e.g. disk manager's dmdrvr.bin version 4.20)

	mov	word ptr [scbfar21], offset mosint21
	mov	ax, [scbmosadr]
	mov	word ptr [scbfar21+2], ax
	call	initp8			; load and process device drivers

; sah 01/18/91 make sure we setup scbdrv to point to nul device

	push	es
	mov	es,[scbmosadr]
	assume	es:mos

; place top of driver list into nul driver

	mov	ax,word ptr [scbdrvr]
	mov	word ptr [scbnul],ax
	mov	ax,word ptr [scbdrvr+2]
	mov	word ptr [scbnul+2],ax

; place	nul driver as top of driver of list

	mov	word ptr [scbdrvr],offset scbnul
	mov	word ptr [scbdrvr+2],es

; sah 08/28/90	freed the heap space allocated above so
; since resources are nolonger necessary

	mov	es,[initmos]
	cmp	[cnfseg],0
	je	skipcnf2		; skip if no cnfbuf segment
	mov	es,[cnfseg]
	mov	ah,1			; free the heap
	cfmos mosheman			; use heap storage
skipcnf2:
	pop	es
	assume	es:nothing

; after done with initp8, establish lidt control of irq2 through 7
; if lidt is available.  must wait until after chkdint has been
; run so dd irq reservations and routing will work properly

	test	[scbmmfea],04h		; is ivtable supported?
	jz	ivt1x
	mov	ax,ds
	call	set_act_27		; set actual interrupt vector(s)
ivt1x:
	mov	ah,3			; get % heap used so far
	cfmos	mosheman
	mov	ax,[scbhp1alc]
	pop	bx			; get heap allocations for smp #1
	sub	ax,bx
	mov	bx,[scbhpalc]		; get heap allocations for smp #1 and #2
	pop	cx
	sub	bx,cx
	mov	[smp1dev],ax		; save value for lator calculations
	sub	bx,ax
	mov	[smp2dev],bx		; save value for lator calculations
	mov	ds,[initmos]
	assume	ds:mos

; load command processor 

	lea	dx,[cpres]		; string "$$shell.sys",0
	mov	ax,3d00h
	cfmos	ifar21
	assume	cs:init,ds:nothing
	jnc	min130
	cfmos	bugshell
min130:
	mov	bx,ax
	mov	ds,[initmos]
	assume	ds:mos
	mov	ds,[scbfree]
	xor	dx,dx			; load into low memory initially
	mov	cx,0ffffh
	mov	ah,3fh
	cfmos	ifar21
	jnc	min140
	mov	cx,2
	push	ds
	pop	es
	push	cs
	pop	ds
	lea	si,bugread
	lea	di,bugopen
	rep	movsw
	cfmos	bugshell
bugread db	'read'			;@@xlat
min140:
	mov	dx,ax			; save count of bytes read
	mov	ah,3eh
	cfmos	ifar21
	jnc	min150
	mov	cx,2
	push	ds
	pop	es
	push	cs
	pop	ds
	lea	si,bugclos
	lea	di,bugopen
	rep	movsw
	cfmos	bugshell
bugclos db	'clos'			;@@xlat
min150:
	mov	ax,dx
	add	ax,0fh			; round up to next paragraph
	shr	ax,1
	shr	ax,1			; convert return count to paragraphs
	shr	ax,1
	shr	ax,1
	mov	ds,[initgrp]
	assume	ds:grp
	cmp	[scbcpseg],00h		; if command processor space already allocated
	jne	cpisset
	mov	[scbcpsiz],ax		; record size for mos info display
	mov	di,ax
	call	finddm			; find a block in dm large enough for it
	or	ax,ax			; find one?
	jz	min160			; yes, we can move $$shell.sys to freemem
	mov	[scbcpseg],ax		; record location for command.com to enter
cpisset:
	mov	ax,[scbcpseg]
	mov	cx,dx
	xor	si,si
	xor	di,di
	push	ds
	push	es
	mov	es,ax
	mov	ds,[initmos]
	assume	ds:mos
	mov	ds,[scbfree]
	assume	ds:nothing
	rep	movsb			; move $$shell.sys up to freemem
	pop	es
	pop	ds
	jmp	min170
min160:
	call	getscbfree		; mov	ax,[scbfree]
	assume	ds:grp
	mov	[scbcpseg],ax		; record location for command.com to enter
	add	ax,di
	cfmos	updfree 		; point scbfree past $$shell.sys
min170:

if	code286
	cmp	[scb286dec],'Y' 	; 286 declare calls supported
	jne	no286b			; no...skip
	mov	bx,[scbcpseg]
	mov	ah,0ah
	mov	cl,0			; declare command processor as data
	call	[scbmmsub]
no286b:
endif

if	mdebug eq 1

	test	[scbdebug],1		; check for init debug status on
	jz	nohpdb			; no
	cfmos	mosstat 		; output initialized system info if debug on
nohpdb:
endif
					;	set up end segment address in scbmosend
	mov	ax, [scbmosadr]
	add	[scbmosend], ax

; reset tcbcmap to clear any access privilages used to get at the
; config.sys file

	push	es
	mov	es,[scbtcbpc]
	assume	es:tcb
	lea	di,tcbcmap
	mov	cx,(26*2+7)/8
	xor	al,al
	cld
	rep	stosb
	pop	es
	assume	es:nothing

; the following is condition code which will check if vna is installed
; if not it will display a message and lock the system.

if	vnahard eq 1
	push	ds
	cmp	byte ptr [scbvnasys],'Y'
	je	vnainstall
	lea	dx,novna-123
	pop	ds
	push	cs
	pop	ds
	mov	ah,9
	add	dx,123
	int	21h
	cli
	jmp	$

vnainstall:
	pop	ds
endif

; set up master memory context for savcntxt and rstcntxt

	push	dx			; save 4b passed back size of res
	push	ds
	mov	ds,[initmos]
	assume	ds:mos
	lea	bx,savtable+4		; start with word size
	xor	ax,ax
cntxtlp:
	cmp	word ptr [bx],-1
	je	cntxtle 		; end of table
	add	ax,[bx] 		; sum all word save counts
	add	bx,6
	jmp	cntxtlp
cntxtle:
	add	ax,ax			; # bytes total
	add	ax,1024 		; sah add 1024 bytes for interupt table
	mov	dx,ax			; calc size heap block needed
	add	dx,2			; room for size counter
	add	dx,0fh			; round up
	shr	dx,1			; calc # para's needed
	shr	dx,1
	shr	dx,1
	shr	dx,1
	xor	ah,ah			; allocate block
	inc	dx			; room for prefix
	cfmos	mosheman
	assume	es:nothing
	or	al,al
	jz	cntxok
	pop	ax			; clear entry ds
	pop	ax			; clear dx res size
	jmp	ihperr
cntxok:
	mov	ax,es
	inc	ax			; skip prefix
	push	ds
	mov	ds,[initgrp]
	assume	ds:grp
	mov	[scbcntxt],ax		; set pointer to master context
	mov	[scbctxsz],dx		; record size for mositask when it
	pop	ds			; needs to allocate smp blocks for
	assume	ds:mos			; the non mm situation
	mov	es,ax
	assume	es:nothing
	xor	di,di
	cld

; save current memory state as master context

	lea	bx,savtable		; bx scans table
	xor	si,si
	mov	ds,si			; set ds to 0000
	mov	cx,512
	rep	movsw
	jmp	short slpntry
savloop:
	rep	movsw			; fast move
	add	bx,6			; next table entry
slpntry:
	push	es
	mov	es,[initmos]		; must be in mos segment
	lds	si,dword ptr es:[bx]	; ds:si is the source
	assume	ds:nothing
	mov	cx,es:[bx+4]		; number of words to move
	pop	es
	and	si,7fffh
	cmp	si,7fffh		; end of loop?
	jne	savloop 		; no
	pop	ds
	assume	ds:nothing
	pop	dx			; get res size of command processor
	mov	ds,[initgrp]
	assume	ds:grp
	mov	ax,word ptr [scbfar38]	; treat scborg38 as part of
	mov	word ptr [scborg38],ax	; the master context
	mov	ax,word ptr [scbfar38+2]
	mov	word ptr [scborg38+2],ax

; init fg task

	mov	al,[scbslice]		; default time slice for all tasks
	or	al,al
	jnz	setslice		; if slice is not zero
	mov	al,1			; if slice is zero
setslice:
	mov	[tcbslice],al		; set slice for foreground task
	push	es
	mov	es,[scbmosadr]		; set in relocated mos also (for mositask)
	assume	es:mos
	add	es:[scbfree],dx
	pop	es
	ret
initpc	endp

	page
	subttl initsmp - initialize final smp
;======================================================================
;,fs
; initsmp - initialize final smp
;
; initialize final heap.  this can be call from either before after
; mos is finally relocated in initp5 or after mos is finally relocated
;
; in:	
;
; out:	
;
;,fe
;=====================================================================
	assume	ds:grp,es:nothing,ss:nothing
initsmp proc	near
	push	es
	mov	es,[initmos]
	assume	es:mos
	mov	ax,[scbhpsiz]		; get space needed for heap

if	code286
	add	ax,3			;051488 extra 48 bytes for 286 alignment
endif

	call	finddm			; find a block in dm large enough for it
	or	ax,ax			; find one?
	jnz	ismp1			; yes, put heap in dm
	test	[dmflags],02h		; is smp to be allocated before initp5
	jnz	ismp2			; yes skip regualar memory allocation
	mov	ax,[scbfree]		; no, use regular memory
	pop	es
	assume	es:nothing
	cfmos	initp7			; init real heap
	inc	ax			; sah 02/17/88
	cfmos	updfree 		; update scbfree (both copies)
	push	es
	jmp	short ismp2
ismp1:
	assume	es:mos
	or	[dmflags],04h		; indicated that smp is in freemem
	pop	es
	assume	es:nothing
	cfmos	initp7			; init real heap
	push	es
ismp2:
	mov	es,[initmos]
	assume	es:mos
	and	[dmflags],not 02h	; completed first past
	pop	es
	assume	es:nothing
	ret
initsmp endp

	page
	subttl calcspace - calculate space requirements
;======================================================================
;,fs
; calcspace - calculate space requirements
;
; calucate space requirements for optimized relocation of system
; resources.  the following is current method of optimization being use
;
;  if memman highmem bit is set
;    kernelsize = sizeof (grp + mo2)
;  else
;    kernelsize = sizeof (grp + mo2 + mos)
;  if smpsize > kernel size
;    set bit to indicated that smp is attempt first
;
; in:	
;
; out:	bits in dmflags:
;	 bit 0 if memmem highmem bit is set
;	 bit 1 if smp to be allocated first
;
;,fe
;=====================================================================
	assume	ds:nothing,es:nothing,ss:nothing
calcspace proc	near
	push	ax
	push	bx
	push	ds
	push	es
	mov	es,[initmos]
	assume	es:mos
	mov	ds,[initgrp]
	assume	ds:grp
	test	[scbmmfea],02h		; does memman support highmem
	jz	calcs0
	or	[dmflags],01h		; indicate condition for later use
calcs0:
	mov	bx,ds			; get grp
	mov	ax,[scbmo2end]		; get end of grp and mo2
	sub	ax,bx
	add	ax,000ffh		; round off to 4k
	and	ax,0ff00h
	lea	bx,clobber+15
	shr	bx,1
	shr	bx,1
	shr	bx,1
	shr	bx,1
	mov	[scbmosend],bx		; save value
	test	[dmflags],01h		; is highmem set
	jnz	calcs1
	push	ax
	add	bx,000ffh
	and	bx,0ff00h		; round off to 4k
	pop	ax
	add	ax,bx			; add mos size to grp & mo2
calcs1:

if	code286
	sub	ax,3			; adjust for the 286 (see initsmp above
endif

	cmp	ax,[scbhpsiz]		; is kernel > smp
	jae	calcs2
	or	[dmflags],02		; set bit to indicate that smp first
calcs2:
	pop	es
	pop	ds
	assume	ds:nothing
	pop	bx
	pop	ax
	ret
calcspace endp

;======================================================================
;,fs
; getscbfree
;
; in:	
;
; out:	
;
;,fe
;=====================================================================
	assume	ds:nothing,es:nothing,ss:nothing
getscbfree proc near
	push	ds
	mov	ds,[initmos]
	assume	ds:mos
	mov	ax,[scbfree]
	pop	ds
	assume	ds:nothing
	ret
getscbfree endp

	subttl init1a - init temporary heap
	page
;======================================================================
;,fs
; init1a - init temporary heap
;
; initialize a temporary heap for use during config.sys file i/o and
; temporary data storage.  this heap and all that is in it will later
; be relocated to its permanent home.  the heap is allocated in the
; top of memory as reported by the bios int 12.
;
; in:	ds -> grp
;
; out:	a temporary heap is put in the top of available memory
;
;,fe
;=====================================================================
	assume	ds:grp,es:nothing,ss:nothing
init1a	proc	near
	int	12h			; get mem size
	mov	cl,6			; calc from k to paragraphs
	shl	ax,cl
	mov	es,[initmos]
	assume	es:mos
	sub	ax,[tmphpsiz]		; temp heap space
	mov	[tmpheap],ax		; save for later use in real heap allocation
	mov	dx,[tmphpsiz]		; size in para's
	mov	es,ax			; heap starting address
	assume	es:nothing
	mov	ah,0ffh 		; init heap
	cfmos	mosheman
	ret
init1a	endp

	subttl initp9 - init mos interrupt vectors
	page
;======================================================================
;,fs
; initp9 - init mos interrupt vectors
;
; this routine will initialize all of the mos interrupt vectors using
; the tables defined in the irq segment.  see mos development specs
; for a detailed description of the irq segment.
;
; in:	ds -> grp
;
; out:	the specified vectors are set in page zero.
;
;,fe
;=====================================================================
	assume	ds:grp,es:nothing,ss:nothing
initp9	proc	near
	xor	bx,bx
	mov	es,bx
	assume	es:nothing

; point list of unused vectors to iret

	push	es
	push	ds
	push	dx
	mov	dx,[initmos]
	push	cs
	pop	ds
	assume	ds:init
	lea	si,plugtbl
	lea	ax,mosint23
pluglp:
	mov	bl,[si]
	cmp	bl,-1			; list terminator?
	je	plugx			; yep
	xor	bh,bh
	shl	bx,1
	shl	bx,1			; calc vector offset
	cli
	mov	es:[bx],ax		; set new offset
	mov	es:[bx+2],dx		; assume the usual	(es --> mos)
	sti
	inc	si
	jmp	pluglp
plugx:
	pop	dx
	pop	ds
	pop	es
	assume	ds:grp,es:nothing

; now plug mos vectors

	lea	si,irqstart		; start of table for irqs to be pluged
irqlp:
	mov	bx,[si] 		; get interrupt to set
	cmp	bx,-1			; end of table?
	je	endirqlp		; yes, exit
	mov	ax,es:[bx]		; get current offset
	mov	[si+2],ax		; save old vector in table
	mov	ax,es:[bx+2]		; get seg
	mov	[si+4],ax		; save seg
	mov	ax,[si+8]		; get offset for new vector from table
	cli
	mov	es:[bx],ax		; set new offset
	mov	ax,[initmos]		; get mos for below
	mov	es:[bx+2],ax		; assume mos segment	(ax --> mos)
	sti
	add	si,0ch			; point to next table entry
	jmp	irqlp			; while interrupt number <> 0ffffh
endirqlp:
	mov	es:[1eh*4+2],ds 	;rs1  disk parms use grp


; reset scbfar38 to mosint38

	mov	ax,[initmos]
	mov	word ptr [scbfar38+2],ax
	mov	word ptr [scbfar38], offset mosint38

; the following will set mos services interupt if and only if
; interupt services is not 38h


if	services ne 38h
	mov	es:[services*4+2],ax	; save segment of mos services
	mov	word ptr es:[services*4], offset mosint38
endif

	ret				; end initp9
initp9	endp

	subttl initp4 - process memdev and freemem
	page
;======================================================================
;,fs
; initp4 - process memdev and freemem
;
; this routine will process the memdev command by 1st loading the
; specified memdev driver, 2nd initialize the driver, and finally
; retrieve the information that mos needs from the driver.  this
; routine will also setup the 'Data Management' pointers that are
; specified with the freemem command.  if no freemem commands are found
; then the upper memory pages will be searched for free space.
; the 'Data Management' pointers are used to relocate mos, the system
; heap and the disk buffers up into high unused memory pages.
;
; in:	mmdev1 and mmdev2 point to the name of the memdev file
;
; out:	mmsegmt -> free memory segment after driver, 0 if no driver
;	memdev driver loaded at absolute address 1000h
;
;,fe
;=====================================================================
	assume	ds:nothing,es:nothing,ss:nothing
initp4	proc	near
	assume	ds:nothing
	mov	ds,initgrp
	assume	ds:grp
	jmp	short do13jnk

; since some memdev drivers intercept int 13 for disk staging
; we need a non-relocated int 13 vector for mos.  the following
; code is place at absolute address 0700h just before the memdev
; driver.  in this way mos can be relocated and the segment value
; below can be changed to point to mos.  the vector that the driver
; picks up will not be invalidated when mos is moved.

	assume	es:mos
real13	dw	offset mos:regr13pri	; this will be at offset 0 in seg
	dw	0			; this is the mos segment
	jmp	dword ptr cs:[0]	; jump to relocated mosint13
	db	16-($-real13) dup (00h) ;011188
do13jnk:
	mov	es,[initmos]
	assume	es:mos
	mov	ax,[mmlseg]
	mov	es,ax			; put at absolute 'mmlseg:0'
	push	ax			; save value for below
	push	ds
	mov	di,cs
	mov	ds,di
	assume	ds:nothing, es:nothing
	xor	di,di
	lea	si,real13		; int 13 redirecter
	mov	cx,9			; was 16
	rep	movsb
	pop	ds
	assume	ds:grp
	mov	ax,[initmos]
	mov	es:[2],ax		; set segment value
	xor	ax,ax			; set new vector
	mov	es,ax
	assume	es:nothing
	mov	word ptr es:[13h*4],4
	pop	ax
	mov	word ptr es:[13h*4+2],ax; point to redirector

; now process memdev

	cfmos	ldmmdev 		; load memman driver
	jc	exit4p			; error in driver or loading
	call	mminit			; set up memman data areas
	jc	exit4p			; error in driver or loading
;
; save value at SCB4013 into scb4013 for later use by Calclim in mositask
;
	mov	ds,[InitGRP]
	push	es
	xor	ax,ax
	mov	es,ax
	mov	ax,word ptr es:[413h]
	mov	[scb4013],ax
	pop	es
			     

; no disk i/o from here until initcache is called and
; scbcseg is initialized
; note the actual start of the no disk i/o critical section is in mminit

; if have i/o trapping, and the kbrate=n statement was not found within
; config.sys, time to setup the keyboard rate control logic.

	test	[scbmmfea],40h
	jz	kbrt1
	cmp	[scbkbrate],0ffh	; kybd rate control active?
	je	kbrt1
	mov	ax,0f000h
	mov	es,ax
	mov	al,es:[0fffeh]		; fetch the machine id byte
	cmp	al,0fch 		; running on an at?
	je	kbrt2
	cmp	al,0fah 		; running on a ps/2 25 or 30?
	je	kbrt2
	cmp	al,0f8h 		; ps/2 model 70 or 80?
	jne	kbrt3
kbrt2:

; program the keyboard with the defalut repeat rate

	mov	bl,[scbkbrate]
	cfmos	set_kbrate

; establish trapping for port 60

	push	ds
	lds	si,[scbioptr]
	assume	ds:nothing
	or	byte ptr [si+12],00000001b
	pop	ds
	assume	ds:grp
	jmp	short kbrt1
kbrt3:

; mark kybd rate control as inactive

	mov	[scbkbrate],0ffh
kbrt1:
	test	[scbmmfea],80h		; is full mapping supported?
	jz	exit4p			; no, skip
	call	fmsrch			; if no freemem given try and find some
	call	dmadjst 		; make any adjustments to dm pointers
exit4p:
	push	ds
	mov	ds,[initmos]
	assume	ds:mos
	test	[dmflags],10h		; special version of driver
	jnz	exit13a
	cmp	[mmsegmt],0		; driver loaded?
	jne	initp4e 		; yes
exit13a:
	pop	ds
	assume	ds:grp
	cmp	[scbvtype],0		; vtype specified
	je	exit13			; no...continue on
	mov	[scbvtype],0		; turn vtype off
	push	ds
	push	cs
	pop	ds
	lea	dx,msgvtyp		; display error message
	call	idispmos		;021588
	pop	ds
exit13:
	push	ds
	mov	ds,[initmos]
	assume	ds:mos
	xor	ax,ax			; no, point int 13 back to mos
	mov	es,ax
	assume	es:nothing
	mov	ax,offset regr13pri
	mov	word ptr es:[13h*4],ax
	mov	word ptr es:[13h*4+2],ds
initp4e:
	pop	ds
	ret
initp4	endp

	subttl mminit - initialize memman data areas
	page
;======================================================================
;,fs
; mminit - initialize memman data areas
;
; this routine will open the driver and ask it for a pointer to its
; data areas that will be used by mos.	the data will be moved to the
; scb for easy access by all.
;
; in:	none
;
; out:	cf = 0 if no error, scbmmxxx variables will be set
;
;,fe
;=====================================================================
	assume	ds:nothing,es:nothing,ss:nothing
mminit	proc	near
	push	ax
	push	bx
	push	cx
	push	dx
	push	ds
	push	es
	mov	ds,[initmos]		; address local data (mos)
	assume	ds:mos
	lea	dx,mmdevice
	mov	ax,3d02h		; open device for read/write
	cfmos	ifar21
	jnc	$+5
	jmp	ermemdev		; no memory management device
	mov	bx,ax			; handle
	mov	[icnfhdl],bx

; added 2/23/87 mjs, memman device must be set to raw mode so
; 1ah can be part of the address without terminating the read.

	mov	ax,4400h
	cfmos	ifar21			; set this device to raw mode
	and	dx,00ffh
	or	dx,20h
	mov	ax,4401h
	cfmos	ifar21
	mov	ah,3fh
	mov	cx,4			; read 4 bytes (get pointer)
	push	ds
	mov	ds,[initgrp]
	assume	ds:grp
	lea	dx,scbmmptr		; buffer address (double word)
	cfmos	ifar21
	pop	ds
	assume	ds:mos

;jrbr no disk i/o from here until initcache is called and
;jrbr	scbcseg is initialized
;jrbr note that this is actually the start of the no disk i/o critical section

	jnc	mmdevok
ermemdev:
	push	ds
	push	cs
	pop	ds
	lea	dx,msgmm1		; tell 'Invalid driver'
	call	idispmos		;021588
	pop	ds
	mov	bx,[icnfhdl]
	mov	ah,3eh			; close device
	cfmos	ifar21
	call	exit13
	mov	word ptr [mmsegmt],0
	stc				; set error flag for return
	jmp	mminite 		; exit
mmdevok:
	mov	bx,[icnfhdl]
	mov	ah,3eh			; close device
	cfmos	ifar21
	mov	es,[initgrp]
	assume	ds:mos,es:grp
	push	ds
	push	si
	push	di
	lea	di,scbmmsub		; move memman info to our data area
	lds	si,[scbmmptr]
	cld
	mov	cx,14			; move 14 words
	rep	movsw

; check for support of an actual interrupt vector table

	test	[scbmmfea],04h		; is ivtable supported?
	jz	ivt1
	mov	ax,es
	call	set_actual		; set actual interrupt vector(s)
ivt1:
	pop	di
	pop	si
	pop	ds			; our data seg back
	assume	ds:mos,es:grp

; test for special version of memman driver which does not
; do any mapping.

	mov	ax,word ptr [scbmmfe2]
	or	ax,ax
	jz	mmnovid 		; skip men stuff if no bits
	and	ax, not features
	jnz	mmnorm			; ok...normal driver
	or	[dmflags],10h		; mark bit for special driver
	jmp	short mmnovid
mmnorm:

; setup pointer to io protection table for kernel to use

	push	si
	push	ds
	lds	si,[scbmmptr]
	assume	ds:nothing
	lds	si,dword ptr [si].parmiop  ; get ptr to iop table
	mov	ax,ds
	pop	ds
	assume	ds:mos
	mov	word ptr [scbioptr],si
	mov	word ptr [scbioptr+2],ax
	pop	si
	mov	[scbmmfg],'Y'		; set using a mem man flag
	test	[scbmmfea],80h		; full mapping supported
	jz	mmnovid
	xor	[scbmmmod],80h		; flag that video mm used (toggle since,
					;  config logic may have set it to no, see
					;  mmvid= command)
mmnovid:
	assume	es:nothing
	clc				; set no errors flag
mminite:
	pop	es
	pop	ds
	pop	dx
	pop	cx
	pop	bx
	pop	ax
	ret
mminit	endp

	subttl fmsrch - free memory search
	page
;======================================================================
;,fs
; fmsrch - free memory search
;
; this routine will search the upper memory pages for unused space
;
; in:	none
;
; out:	
;
;,fe
;=====================================================================
	assume	ds:nothing,es:nothing,ss:nothing
fmsrch	proc	near
	push	ax
	push	bx
	push	cx
	push	si
	push	di
	push	ds
	push	es
	mov	ds,[initmos]
	assume	ds:mos
	cmp	[dmpatch],0		; is any area set by user?
	je	$+5			; no, try and find some
	jmp	srmemend		; use just what they specified
	mov	bx,0c000h		; start search here
	cld
	xor	si,si
srmemlp:				; search memory loop
	mov	es,bx			; next 4k block
	assume	es:nothing
	mov	ax,0ffh 		; init
	mov	cx,1000h		; scan 4k
	xor	di,di
srcklp:
	add	ah,es:[di]		; calc checksum
	and	al,es:[di]
	inc	di			; check 4k
	loop	srcklp
	or	al,al			; code would probably be 0
	jnz	use4k			; use this space
	xor	di,di			; init for loop 2
	xor	al,al			; init "        "
	mov	cx,1000h		; scan 4k
srcklp2:
	add	al,es:[di]		; calc checksum
	inc	di			; check 4k
	loop	srcklp2
	cmp	al,ah			; is checksum the same
	jne	use4k			; yes, do not use this space
	or	al,al
	jnz	next4k
use4k:					; if here then use the 4k
	mov	word ptr es:[0],1234h	; put in test value for ram
	cmp	word ptr es:[0],1234h	; is it there?
	je	next4k			; yes, can't use this space
	cmp	[si+dmpatch+2],bx	; is this a continuation?
	je	blckcnt 		; yes, part of a larger block
	cmp	[si+dmpatch+2],0	; is this the 1st block found?
	je	nonxtyet		; yes, don't update table pointer
	add	si,4			; set next pointer
	cmp	si,6*4			; only 5 entries allowed in table
	je	srmemend
nonxtyet:
	mov	[si+dmpatch],bx 	; no, start of new block
blckcnt:				; set new end of block address
	inc	bh			; next 4k
	mov	[si+dmpatch+2],bx	; set end of block address
	dec	bh
next4k:
	mov	es:[0],ax		; put original value back
	inc	bh			; next 4k block
	cmp	bh,0f0h 		; end of usable range?
	jne	srmemlp 		; not yet
srmemend:
	pop	es
	pop	ds
	pop	di
	pop	si
	pop	cx
	pop	bx
	pop	ax
	ret
fmsrch	endp

	subttl dmadjst - data management adjustments
	page
;======================================================================
;,fs
; dmadjst - data management adjustments
;
; this routine will adjust the 'Data Management' pointers (freemem) to
; a 4k boundary.
;
; in:	none
;
; out:	the data management pointers are adjusted.
;
;,fe
;=====================================================================
	assume	ds:nothing,es:nothing,ss:nothing
dmadjst proc	near
	push	ax
	push	bx
	push	cx
	push	si
	push	di
	push	ds
	push	es
	mov	ds,[initmos]
	assume	ds:mos
	xor	si,si			; si used as index
dmaloop:				; adjustment loop
	mov	ax,[si+dmpatch] 	; get starting segment address
	or	ax,ax			; is one specified?
	jnz	$+5			; yes, now check for end segment
	jmp	dmaexit 		; no, end adjustment of data man.
	mov	bx,[si+dmpatch+2]	; get ending segment address
	or	bx,bx			; is one specified?
	jnz	$+5			; yes
	jmp	dmabad			; no, end adjustment of data man.
	add	ax,0ffh 		; round start up to next 4k boundary
	and	ax,0ff00h		; "  "	"
	and	bx,0ff00h		; round end down to 4k
	cmp	ax,bx			; check for start greater than end
	jae	dmabad			; error, end adjustment
	mov	[si+dmpatch],ax 	; save new start value
	mov	[si+dmpatch+2],bx	; save new end value
	add	si,4			; next data management pointer
	jmp	dmaloop 		; adjust all specifed areas
dmabad: 				; invalid memory pointers
	mov	ax,[si+dmpatch] 	; get bad freemem start
	push	ds
	push	cs
	pop	ds
	lea	dx,msgifm1		; put in error message
	cfmos	hex2asc
	pop	ds
	mov	ax,[si+dmpatch+2]	; get bad freemem end
	push	ds
	push	cs
	pop	ds
	lea	dx,msgifm2		; put in error message
	cfmos	hex2asc
	lea	dx,msgifm		; tell user 'Invalid FREEMEM values'
	call	idispmos
	pop	ds
	mov	[si+dmpatch],0ffffh	; nul out use of this entry
	mov	[si+dmpatch+2],0ffffh	; "     "	"       "
	add	si,4			; next data management pointer
	jmp	dmaloop 		; adjust all specifed areas
dmaexit:
	push	ds
	pop	es			; address locally
	assume	es:nothing
	lea	si,dmpatch		; move dm data to work area
	lea	di,dmbuffr		; this is the work area
	mov	cx,10
	cld
	rep	movsw
	pop	es
	pop	ds
	pop	di
	pop	si
	pop	cx
	pop	bx
	pop	ax
	ret
dmadjst endp

	subttl setdint - save irqs before device load
	page
;======================================================================
;,fs
; setdint - save irqs before device load
;
; save the irq vectors 0a - 0f in some heap space to be checked later
;
; in:	
;
; out:	es -> heap block
;
;,fe
;=====================================================================
	assume	ds:nothing,es:nothing,ss:nothing
public	setdint
setdint proc	near
	push	ax
	push	dx

; 4 bytes/vector rounded to next seg, plus heap prefix

	mov	dx,((((0fh-0ah+1)*4)+15)/16)+1
	mov	ah,0			; allocate block
	cfmos	mosheman
	assume	es:nothing
	or	al,al
	jz	intsavok
	jmp	ihperr
intsavok:
	pop	dx
	pop	ax
	push	cx
	push	si
	push	di
	push	ds
	xor	cx,cx
	mov	ds,cx
	assume	ds:nothing
	mov	si,0ah*4
	mov	di,10h			; skip heap prefix (i.e. no crashing system)
	mov	cx,(0fh-0ah+1)*2	; 2 words/vector
	cld
	rep	movsw
	pop	ds
	pop	di
	pop	si
	pop	cx
	ret
setdint endp

	subttl chkdint - check irqs for use by device
	page
;======================================================================
;,fs
; chkdint - check irqs for use by device
;
; this routine will check the current irqs 0a - 0f for use by the
; newly loaded device driver.  if the driver is found to be using a
; vector then the address of that vector will be set as the "original"
; int in the irq segment and the appropriate scbidqx will be set to
; prevent the use of this vector by applications.
;
; in:	es -> heap block where preload irq address reside
;
; out:	heap block pointed to by es is deallocted.
;	if any vectors used by driver then appropriate info set.
;
;,fe
;=====================================================================
	assume	ds:nothing,es:nothing,ss:nothing
public	chkdint
chkdint proc	near
	push	ax
	push	bx
	push	cx
	push	si
	push	di
	push	ds
	xor	cx,cx
	mov	ds,cx
	assume	ds:nothing
	mov	di,10h			; skip heap prefix
	mov	si,0ah*4
	mov	cx,(0fh-0ah+1)*2	; 2 words/vector
	cld
cntcmp:
	or	cx,cx
	jnz	$+5
	jmp	dintx			; nothing more to check
	repe cmpsw			; check for irqs used by driver
	jne	$+5
	jmp	dintx			; none, exit

; vector found to be used by device driver just loaded

	test	si,02			; did seg miscompare?
	jz	badoffst		; no, the offset did
	dec	cx			; skip seg
badoffst:
	and	si,0fffch		; force pointer to offset
	and	di,0fffch		; also test pointer
	mov	bx,si
	shr	bx,1			; calc int #
	sub	bx,0ah*2		; calc offset into idq table
	push	ds
	mov	ds,[initgrp]
	assume	ds:grp
	mov	[scbidq2+bx],-1 	; flag irq used by device driver

; set original vector to this one in the irq segment table entry

	push	es
	xor	bx,bx
	mov	es,bx
	assume	es:nothing
	lea	bx,irqstart
sirqlp:
	cmp	si,[bx] 		; is this the right entry?
	je	sirqx			; yes, exit
	add	bx,0ch			; next entry
	jmp	sirqlp
sirqx:
	add	bx,2			; point to original irq routine save space
	mov	ax,es:[si]
	cli
	mov	[bx],ax
	mov	ax,es:[si+2]
	mov	[bx+2],ax
	sti
	pop	es
	pop	ds
	assume	es:nothing,ds:nothing
	add	si,4			; next vector
	add	di,4			; also test pointer
	jmp	cntcmp			; continue to check the rest of the vectors
dintx:
	mov	ah,1			; deallocate heap block
	cfmos	mosheman
	or	al,al
	jz	dealok
	push	word ptr cs:[initmos]
	mov	ax,offset mos:smperr
	push	ax
	retf
dealok:
	pop	ds
	assume	ds:nothing
	pop	di
	pop	si
	pop	cx
	pop	bx
	pop	ax
	ret
chkdint endp

	subttl initp8 - load and init device drivers
	page
;======================================================================
;,fs
; initp8 - load and init device drivers
;
; load and initialize device drivers from config.sys file
;
; in:	
;
; out:	
;
;,fe
;=====================================================================
	assume	ds:grp,es:nothing,ss:nothing
	public  initp8
initp8	proc	near
	mov	ax,offset grp:i10old
	mov	word ptr [scbi10old],ax
	mov	ax,ds
	mov	word ptr [scbi10old+2],ax
	or	[scbsmplow],2		; indicate loading device drivers
	push	ds
	assume	ds:nothing
	mov	ds,[initmos]
	assume	ds:mos

; record the original 40:13 value for restoration after all drivers
; have been loaded.  then set 40:13 to the value in dd4013.  this
; prevents drivers like sysload/periscope from overwriting mos
; in the high end of the 640k base memory.

	mov	ax,40h
	mov	es,ax
	assume	es:nothing
	push	es
	mov	ax,es:[13h]
	mov	[og4013],ax
	mov	ax,[dd4013]
	mov	es:[13h],ax

; any config.sys file read?

	cmp	[cnfseg],0
	je	initp8e
	mov	ds,[cnfseg]		; address config data
	assume	ds:cnfbuf
	mov	cx,[ddnum]		; get device driver counter (set in procnfg)
	or	cx,cx			; any drivers to load?
	jnz	initp81
	jmp	initp8e 		; no, exit
initp81:
	xor	bx,bx			; init table pointer

; load loop to load driver and init it

ldloop:
	push	cx			; save count of drivers left to load
	mov	cl,byte ptr [bx+ddtable+5]
	mov	[lowdev],cl
	assume	ds:cnfbuf
	mov	si,word ptr [bx+ddtable]; get pointer to driver name
	mov	cl,[bx+ddtable+2]	; get length of name string
	mov	di,word ptr [bx+ddtable+3]  ; get length of parm string
	add	bx,ddrecsiz		; point to next table entry
	push	bx			; save current driver table pointer
	call	setdint 		; save current irq vectors
	push	es			; save heap block pointer
	call	loaddrv 		; load device driver into heap and init it
	mov	ax,es			; es=ax= segment of loaded driver
	pop	es			; heap block pointer back
	call	chkdint 		; check for driver using irq vectors
	pop	bx			; restore device string pointer
	pop	cx			; restore driver count
	sub	cx,ddrecsiz		; load and init all drivers
	jnz	ldloop
initp8e:
	pop	es			; make es -> 40 again
	assume	es:nothing
	pop	ds
	assume	ds:grp

; restore 40:13

	push	ds
	mov	ds,[initmos]
	assume	ds:mos
	mov	ax,[og4013]
	mov	es:[13h],ax
	pop	ds
	assume	ds:grp
	and	[scbsmplow], not 2	; indicate not loading drivers
	ret
initp8	endp


	subttl ExeDevice - check and adjust 'EXE' style device drivers
	page
;======================================================================
;,fs
; ExeDevice - check and adjust 'EXE' style device drivers
;
; in:	ds -> cnfbuf (config data segment)
; out:	es = segment of driver
;
;out:	ds -> cnfbuf (config data segment)
;	es = segment of driver
;
;,fe
;=====================================================================
	assume ds:nothing,es:nothing,ss:tcb
ExeDevice proc	near
	push	si
	push	di
	push	ds
	push	es
;
;	first we must test to see if file is EXE
;
	cmp	word ptr es:[0],5a4dh
	jne	skipexe
;
;	Now we must go through relocation table and relocate exe items
;	for device driver
;
	mov	ax,es
	mov	cx,es:[6]
	jcxz	skiprel
	mov	si,es:[18h]
looprel:

;old;	push	si
;old;	lds	si,dword ptr es:[si]
;old;	add	word ptr ds:[si],ax		
;old;	pop	si
	
	mov	di,ax			;new; seg address of header
	add	di,es:[8]		;new; plus header length in paragraphs
	add	di,es:[si+2]		;new; plus seg portion of relo item
	mov	ds,di			;new; gives target segment
	mov	di,es:[si]		;new; target offset
	add	word ptr ds:[di],ax	;new;

	add	si,4
	loop	looprel		
skiprel:	
;
;	Once Relocated, we can strip header off by moving actual code
;	to start of exe header
;
	cld
	xor	si,si
	xor	di,di
	mov	cx,[icnfsiz]		; get size of file image
	add	ax,word ptr es:[8]	; add size of header
	mov	ds,ax
	rep	movsb		
;
skipexe:

	pop	es
	pop	ds
	pop	di
	pop	si
	ret
ExeDevice endp	

	subttl loaddrv - load and init device driver
	page
;======================================================================
;,fs
; loaddrv - load and init device driver
;
; in:	ds -> cnfbuf (config data segment)
;	si -> driver name
;	cl = length of name string
;	di = length of parms string
;
; out:	es = segment of driver
;	zf=1 if driver loaded and inited ok
;	device driver pointer list is updated to include driver
;
;,fe
;=====================================================================
	assume ds:cnfbuf,es:nothing,ss:tcb
loaddrv proc	near
	xor	ch,ch			; clear parm length
	mov	bp,cx			; save for later
	push	si			; save start of string pointer
	add	si,cx			; point to end of string
	xor	al,al
	xchg	byte ptr [si],al	; terminate with 0 (for asciiz)
	mov	bx,si			; save pointer for restoral
	mov	[icharsav],al		; save char for restoral
	pop	si			; restore starting pointer
	mov	dx,si			; pointer for dos call
	mov	ax,3d00h		; open file for reading only
	cfmos ifar21
	ljc	deverr
	mov	[icnfhdl],ax		; save handle
	mov	al,[icharsav]
	mov	byte ptr [bx],al	; restore char where we put terminator

; sah 12/18/89 modifications for split-smp support, if drive is going to
; be loaded in low memory must ser scbsmplow to non zero

	push	ds
	mov	ds,[initgrp]
	assume	ds:grp
	mov	al,[lowdev]
	or	al,al
	jz	skiplow
	or	[scbsmplow],1
skiplow:
	pop	ds
	assume	ds:cnfbuf

; mjs 11/14/88	when allocating the space in the smp to load in a device
; driver, must reserve enough room for any bdb's and cdb's that mosddint
; might need to allocate.

; sah  04/11/90 please note that reserved room for bdb's and cdb's is not
; done for split-smp case, since bdb's and CDB's will come out of the other
; smp on system.

	xor	ah,ah			; allocate block on heap
	mov	dx,0ffffh		; find out how much available
	cfmos mosheman			; should get error, dx has

; check to see if we have split smp

	push	ds
	mov	ds,[initgrp]
	assume	ds:grp
	cmp	[scbhp2siz],0		; is smp split?
	pop	ds
	assume	ds:cnfbuf
	jne	skipalt 		; yes then allocated it all the way
	push	bx			; available size
	push	dx
	mov	ax,bdblen+0fh		; calc paragraphs per bdb
	shr	ax,1
	shr	ax,1
	shr	ax,1
	shr	ax,1
	mov	bx,cdblen+0fh		; calc paragraphs per cdb
	shr	bx,1
	shr	bx,1
	shr	bx,1
	shr	bx,1
	add	ax,bx
	mov	bx,26			; reserve enough space for 26 bdb's
	mul	bx			; and cdb's (worst case when a
	pop	dx			; diskless workstation links to a
	pop	bx			; network with drives a - z)
	sub	dx,ax
skipalt:
	xor	ah,ah			; alloc all smp (minus reserved area)
	cfmos mosheman			; es now has addr of block (prefix too)
	dec	dx			; not to include prefix
	push	dx			; save block size (in bytes)

; sah 12/18/89 must reset scbsmplow

	push	ds
	mov	ds,[initgrp]
	assume	ds:grp
	and	[scbsmplow], not 1
	pop	ds
	assume	ds:cnfbuf

; determine file size for read into heap

	mov	ax,4202h		; lseek to eof (determine file size)
	mov	bx,[icnfhdl]		; get handle
	xor	cx,cx			; offset 0
	xor	dx,dx
	cfmos ifar21
	jnc	initp82
	pop	dx			; discard heap block size
	jmp	deverr
initp82:
	push	ax			; save size of file
	mov	ax,4200h		; lseek back to beginning of file
	mov	bx,[icnfhdl]
	xor	cx,cx			; offset 0
	xor	dx,dx
	cfmos ifar21
	pop	cx			; get # bytes to read
	jnc	initp83
	pop	dx			; discard heap block size
	jmp	deverr
initp83:
	pop	dx			; get heap block size
	push	cx			; save file size for read
	mov	[icnfsiz],cx		; Save File Size
	add	cx,0fh			; round up to next seg boundary
	shr	cx,1			; calc # segs file needs
	shr	cx,1
	shr	cx,1
	shr	cx,1
	cmp	cx,dx			; is block large enough for driver?
	pop	cx			; (get file read size back)
	jna	dsizeok

; updated 04/04/90 stewart hyde
; the following was added so that if we calculated that requested
; device driver will not be fit into smp then we will display
; error message to the user and close up allocation for device driver

	mov	ah,1
	cfmos mosheman			; free up heap allocated
	mov	ah,3eh
	mov	bx,[icnfhdl]
	cfmos ifar21			; close file
	mov	dx,offset devnsmp
	push	ds
	push	cs
	pop	ds
	jmp	devdisp
dsizeok:
	mov	dx,10h			; start load just after prefix area
	mov	ax,es			; heap block address
	mov	bx,[icnfhdl]		; handle
	push	ds
	mov	ds,ax			; set address of heap block
	mov	ah,3fh			; read in file
	cfmos ifar21			; read file into heap block
	pop	ds
	ljc	deverr

; file is read in, now init it.

	cfmos 	clearsm			; clear screen for driver's init msg
	mov	ax,es
	inc	ax			; set data area segment boundary
	mov	es,ax

; check if device= memdev driver

	push	ds
	push	si
	push	di
	push	cx
	mov	ds,[initmos]
	mov	cx,8
	lea	si,mmdevice
	mov	di,0ah
	repe cmpsb
	pop	cx
	pop	di
	pop	si
	pop	ds
	jnz	drvnotmm
	mov	ax,es
	dec	ax
	mov	es,ax
	mov	ah,1
	cfmos mosheman
	mov	ax,di
	lea	dx,devnotmm
	jmp	devnext
drvnotmm:
	call	ExeDevice		; Handle EXE device drivers
	xor	bx,bx
	mov	dx,si			; pass pointer to parms after '='
	push	si			; save string pointer
	mov	ax,di			; get parms length
	add	ax,bp			; and filename length
	add	si,ax			; point to end of string
	add	si,2			; point past cr, lf
	xor	al,al
	xchg	[si],al 		; terminate with 0 (for asciiz)
	mov	[icharsav],al		; save char for restoral
	xor	al,al			; link into scbdrvr list
	cfmos mosddint
	push	ax
	mov	al,[icharsav]
	mov	[si],al 		; restore char
	pop	ax
	pop	si			; string pointer back
	cmp	al,0
	jz	devcls			; any errors during init of driver?
	cmp	al,0ffh
	lje	deverr			; if error status from dd
	jmp	ihperr
devcls:
	mov	ah,3eh
	mov	bx,[icnfhdl]
	cfmos ifar21			; close file
	xor	al,al			; return with zf=1
	ret
deverr:
	lea	dx,devmsg
	cmp	al,2
	jne	devnext 		; file not found error?
	lea	dx,devfile		; yes
devnext:
	cmp	al,0ffh
	jne	devnx2
	mov	ax,'FF'
	jmp	devnx3
devnx2:
	aam
	add	ax,3030h		; ascii
	xchg	al,ah
devnx3:
	push	ds
	push	cs
	pop	ds			; address locally
	assume	ds:init
	mov	word ptr [devno],ax	; include error number in message
devdisp:
	call	idispmos
	pop	ds
	assume	ds:cnfbuf

; display erroneous driver path and name to user

	mov	di,bp
	add	di,si			; point to end of string
	mov	byte ptr [di],0 	; set string terminator
	push	si
develp:
	lodsb
	cmp	al,0
	je	deveend
	mov	dl,al
	mov	ah,2
	cfmos ifar21
	jmp	develp
deveend:
	pop	si
	lea	dx,imsgcrlf
	push	ds
	push	cs
	pop	ds
	assume	ds:init
	call	idispmos
	pop	ds
	assume	ds:cnfbuf
	mov	ah,3eh			; close file
	mov	bx,[icnfhdl]
	cfmos ifar21
	or	ah,ah			; return with zf=0
	ret
loaddrv	endp

	subttl set_actual - set up actual vector table
	page
;======================================================================
;,fs
; set_actual - set up actual vector table
;
; this routine will initialize the actual vector table when a memory
; management driver is used which supports this feature.
;
; in:	ax -> grp
;
; out:	none
;
;,fe
;=====================================================================
	assume	ds:nothing,es:nothing,ss:nothing
public	set_actual
set_actual:
	pushset ax,bx,cx,dx,si,di,ds,es
	mov	es,ax
	assume	es:grp

; setup the new int8 vector and re-plug the one in the 0:0 table

	mov	bx,8*4
	mov	di,offset mos:lidtint08
	mov	cx,offset mos:lidtstub8
	mov	dx,[scbmosadr]
	mov	ax,dx
	call	set_act2

; setup the new int9 vector and re-plug the one in the 0:0 table

	mov	bx,9*4
	mov	di,offset mo2:lidtint09
	mov	cx,offset mos:lidtstub9
	mov	dx,[initmo2]
	call	set_act2		; ax preserved from above

; setup the new int 74h vector and re-plug the one in the 0:0 table

	mov	bx,74h*4
	mov	di,offset mos:lidtint74
	mov	cx,offset mos:lidtstub74
	mov	dx,[scbmosadr]
	call	set_act2		; ax preserved from above
	popset	ax,bx,cx,dx,si,di,ds,es
	ret

	subttl set_act_27 - setup irq2 through 7
	page
;======================================================================
;,fs
; set_act_27 - setup irq2 through 7
;
; in:	ax -> grp
;
; out:	
;
;,fe
;=====================================================================
	assume	ds:nothing,es:nothing,ss:nothing
set_act_27:
	pushset ax,bx,cx,dx,si,di,ds,es
	mov	es,ax
	assume	es:grp
	mov	dx,[scbmosadr]
	mov	ax,dx
	mov	cx,offset mos:lidtst_af ; use this same stub for each
	mov	bx,0ah*4
	mov	di,offset mos:lidt0a
	call	set_act2
	add	bx,4
	mov	di,offset mos:lidt0b
	call	set_act2
	add	bx,4
	mov	di,offset mos:lidt0c
	call	set_act2
	add	bx,4
	mov	di,offset mos:lidt0d
	call	set_act2
	add	bx,4
	mov	di,offset mos:lidt0e
	call	set_act2
	add	bx,4
	mov	di,offset mos:lidt0f
	call	set_act2
	popset	ax,bx,cx,dx,si,di,ds,es
	ret

	subttl	set_act2
	page
;======================================================================
;,fs
; set_act2
;
; in:	bx = vector offset
;	ax:cx = value for 0:vector
;	dx:di = value for real vector
;	es -> grp
;
; out:	si, and ds are crashed
;
;,fe
;=====================================================================
	assume	ds:nothing,es:nothing,ss:nothing
set_act2:
	assume	ds:nothing,es:grp
	xor	si,si
	mov	ds,si
	mov	[bx],cx
	mov	[bx+2],ax
	push	ax
	push	bx
	lds	si,[scbmmptr]
	add	bx,[si+parmaiv] 	; get offset within seg 70h of ivtable
	mov	ax,70h
	mov	ds,ax
	mov	[bx],di
	mov	[bx+2],dx
	pop	bx
	pop	ax
	ret

	subttl finddm - find free data management block
	page
;======================================================================
;,fs
; finddm - find free data management block
;
; this subroutine will find a block of freemem of atleast the size
; requested and if found memman memory will be paged in.
;
; in:	ax = size of block in para's
;	bx = 0 - call dmalloc	bx <> 0 - skip call to dmalloc and
;	align the block on a 4k boundry
;
; out:	ax = 0 if no block large enough, else seg address of block
;	'dmbuffer' is updated to reflect that the block has been taken
;
;,fe
;=====================================================================
	assume	ds:nothing,es:nothing,ss:nothing
public	finddm
finddm	proc	near
	push	bx
	xor	bx,bx
	call	sfinddm
	pop	bx
	ret
sfinddm:
	push	cx
	push	dx
	push	si
	push	di
	push	ds
	push	bx
	mov	ds,[initmos]
	assume	ds:mos
	mov	cx,ax
	xor	si,si			; si used as index
findlp: 				; relocation loop
	mov	ax,[si+dmbuffr] 	; get starting segment address
	or	ax,ax			; is one specified?
	jnz	$+5			; yes, now check for end segment
	jmp	finddme 		; no block large enough found
	mov	bx,[si+dmbuffr+2]	; get ending segment address
	sub	bx,ax			; calc size of space (in para's)
	cmp	cx,bx			; is it large enough for mos
	jbe	findyes 		; yes, move it to it!
findagain:
	add	si,4			; try next memory space
	jmp	findlp
findyes:
	mov	dx,cx			; record requested size
	pop	bx
	push	bx
	or	bx,bx			; if entry bx <> 0, skip call to dmalloc and
	jz	allook1 		; check for 4k boundry alignment
	test	ax,0ffh
	jz	allook
	mov	dx,ax
	and	dx,0ff00h
	add	dx,0100h		; adjust up to next boundry
	mov	di,dx
	sub	dx,ax			; calc make up amount
	add	dx,cx			; new size for block
	mov	bx,[si+dmbuffr+2]	; get ending segment address
	sub	bx,ax			; calc size of space (in para's)
	cmp	dx,bx			; will it still fit?
	ja	findagain
	mov	ax,di
	jmp	short allook
allook1:
	mov	bx,dx			; size needed (in para's)
	call	dmalloc 		; allocate and page in memory
	jnc	allook			; allocation ok
	xor	ax,ax			; tell no block found
	jmp	short finddme		; error in allocation
allook:
	add	[si+dmbuffr],dx 	; update dm memory pointer
finddme:
	pop	bx
	pop	ds
	assume	ds:nothing
	pop	di
	pop	si
	pop	dx
	pop	cx
	ret
finddm	endp

	subttl intvrst - reset int vectors
	page
;======================================================================
;,fs
; intvrst - reset int vectors
;
; this routine will reset the segment of the mos interrupt vectors
; using the tables defined in the irq segment.	this routine is called
; after the second mos relocation in order for the int vectors to point
; into the correct segment.  see mos development specs for a detailed
; description of the irq segment.  if a segment value equal to the
; segment of the memman driver is found then the mos address will not
; be reset.
;
; in:	ax = new segment value to use
;	ds -> grp
;
; out:	the specified vectors are set in page zero.
;
;,fe
;=====================================================================
	assume	ds:grp,es:nothing,ss:nothing
public	intvrst
intvrst proc	near
	push	bx
	push	cx
	push	dx			; used to hold memman segment
	push	si
	push	di
	push	es
	mov	[ddtmctcb],ss		; record tcb of master console (for mosint09)
	mov	dx,word ptr [scbmmptr+2]; get memman segment
	xor	bx,bx
	mov	es,bx
	assume	es:nothing
	lea	si,irqstart		; start of table for irqs to be plugged
rstlp:
	mov	bx,[si] 		; get interrupt to set
	cmp	bx,-1			; end of table?
	jne	$+5
	jmp	endrstlp		; yes, exit
	cmp	word ptr es:[bx+2],dx	; did memdev set this one?
	je	rstskip 		; yes, skip it
	mov	es:[bx+2],ax		; set new mos seg
	add	si,0ch			; point to next table entry
	jmp	rstlp			; while interrupt number <> 0ffffh
rstskip:
	cmp	bx,13h*4		; only int 13 should be effected now
	jne	interr			; if not int 13 give internal error
	add	si,0ch			; point to next table entry
	jmp	rstlp			; while interrupt number <> 0ffffh
interr:
	push	cs
	pop	ds
	mov	ax,bx
	shr	ax,1			; calc vector number from offset
	shr	ax,1
	push	word ptr cs:[initmos]
	mov	bx, offset minterr
	push	bx
	retf
endrstlp:

; now reset all vectors pointing to iret

	push	ds
	push	cs
	pop	ds
	assume	ds:init
	lea	si,plugtbl
plugrst:
	mov	bl,[si]
	cmp	bl,-1			; list terminator?
	je	plgrstx 		; yep
	xor	bh,bh
	shl	bx,1
	shl	bx,1			; calc vector offset
	mov	es:[bx+2],ax		; new seg value
	inc	si
	jmp	plugrst
plgrstx:
	pop	ds
	assume	ds:grp

if	services ne 38h
	mov	word ptr es:[services*4+2],ax  ; set mos services vector
endif

	mov	es:[1eh*4+2],ds 	;rs1  disk parms use grp
	pop	es
	pop	di
	pop	si
	pop	dx
	pop	cx
	pop	bx
	ret
intvrst endp

	subttl dmalloc
	page
;======================================================================
;,fs
; dmalloc
;
; initialize and allocate any 'Data Management' memory areas
;
; in:	ax = starting address for buffer
;	bx = size in para's
;	si = dm buffer pointer
;
; out:	cf=1 if error occured, cf=0 if allocation ok
;
;,fe
;=====================================================================
	assume	ds:nothing,es:nothing,ss:nothing
dmalloc proc	near
	assume	ds:nothing
	push	ax			; save starting address for block
	push	bx			; save # para's needed
	push	cx
	push	ds
	push	es			; sah save es because this routine trashes it
	mov	ds,[initgrp]
	assume	ds:grp

; calc # of pages

	mov	cx,bx			; mjs 6/5/87
	xor	ah,ah			;051488  compute number of bytes left in bank
	neg	al			;051488
	sub	cx,ax			;051488  subtract it from amount required
	jbe	dmallok 		;051488  exit if no more needed
	add	cx,0ffh 		; calc # 4k pages needed
	xor	cl,cl
	xchg	ch,cl
	mov	ah,1
	call	[scbmmsub]		; allocate cx pages
	or	ax,ax			; any banks allocated?
	jz	dmgood			; yes, no errors
	mov	ah,2			; release any that was allocated
	call	[scbmmsub]		; release cx pages starting with bx handle
	jmp	dmalloe
dmgood:
	mov	es,[initmos]
	assume	es:mos
	mov	ax,[si+dmbuffr] 	; get starting segment (same as ax)
	add	ax,0ffh 		; round up to next 4k page
	and	ax,0ff00h
	mov	es,ax
	assume	es:nothing
	mov	ah,3			; remap bx handle, cx pages to es address
	call	[scbmmsub]		; map requested range
dmallok:
	clc				; set ok allocation flag
	jmp	dmalloe2
dmalloe:
	stc				; set error in allocation flag
dmalloe2:
	pop	es
	pop	ds
	pop	cx
	pop	bx			; size back
	pop	ax			; start address back
	ret				; end of dmalloc
dmalloc endp

	subttl dispsmp
	page
;======================================================================
;,fs
; dispsmp
;
; in:	
;
; out:	
;
;,fe
;=====================================================================
	assume	ds:nothing,es:nothing,ss:nothing
public	dispsmp
dispsmp proc	near
	push	es
	push	cs
	pop	ds
	assume	ds:init
	mov	ah,3			; get % heap used by drivers
	cfmos	mosheman
	mov	es,[initgrp]
	assume	es:grp
	mov	ax,[scbhp1alc]
	call	smpadj
	lea	bx,msgheap1+4
	call	bintodec
	mov	ax,[smp1dev]
	call	smpadj
	lea	bx,msgheap2+4
	call	bintodec
	lea	dx,msgheap		; display total heap used
	call	adjmsg
	call	idispmos		;021588
	lea	dx,msgheap2
	call	idispmos		;021588
	cmp	[scbhp2siz],0
	je	sdispsmp
	mov	ax,[scbhpalc]
	sub	ax,[scbhp1alc]
	call	smpadj
	lea	bx,msg2heap1+4
	call	bintodec
	mov	ax,[smp2dev]
	call	smpadj
	lea	bx,msg2heap2+4
	call	bintodec
	lea	dx,msg2heap		; display total heap used
	call	adjmsg
	call	idispmos		;021588
	lea	dx,msg2heap2
	call	idispmos		;021588
sdispsmp:
	pop	es
	ret
dispsmp endp

	subttl bintodec
	page
;======================================================================
;,fs
; bintodec
;
; in:	
;
; out:	
;
;,fe
;=====================================================================
	assume	ds:init,es:nothing,ss:nothing
bintodec proc near
	push	cx
btdloop1:
	div   [wordten] 		; dx:ax is source integer
	add	dl,'0'			; cx is length of target
	mov	[bx],dl 		; bx is end of target
	dec	bx
	xor	dx,dx
	loop	btdloop1
	pop	cx
btdloop2:
	inc	bx
	dec	cx
	jz	btdret
	cmp	byte ptr [bx],'0'
	jne	btdret
	mov	byte ptr [bx],' '
	jmp	btdloop2
btdret:
	ret
bintodec endp

	subttl smpadj
	page
;======================================================================
;,fs
; smpadj
;
; the following routine is use to adjust smp value from paragraphs to k
;
; in:	
;
; out:	
;
;,fe
;=====================================================================
	assume	ds:nothing,es:nothing,ss:nothing
smpadj proc near
	add	ax,01fh 		; make sure we round value up value
	mov	cx,6
	shr	ax,cl
	mov	cx,4
	xor	dx,dx
	ret
smpadj	endp


	subttl adjmsg
	page
;======================================================================
;,fs
; adjmsg
;
; the following msg is use to strip the blanks off front of message
;
; in:	
;
; out:	
;
;,fe
;=====================================================================
	assume	ds:nothing,es:nothing,ss:nothing
adjmsg proc near
	mov	bx,dx
amsg1:
	cmp	byte ptr [bx],' '
	jne	amsg2
	inc	bx
	jmp	short amsg1
amsg2:
	mov	dx,bx
	ret
adjmsg	endp


	subttl checkserial
	page
;======================================================================
;,fs
; checkserial
;
; this routine is use to validate a user # with hidden
; serial code and if serial # is not validated correctly then assume that
; serial # will process demo code.  if number is validate then we will
; derived the 2 bytes at scbmuser for mositask to use in calculating the
; the maximun # of users and also run the code to patch out the demo logic
;
; in:	
;
; out:	
;
;,fe
;=====================================================================
	assume	ds:nothing,es:nothing,ss:nothing
checkserial proc near
	call	validserial		; is serial # valid

ifdef	relcode
	jc	doeval
else
	nop
	nop
endif

	call	setmusers		; set values for maximun # of users
	mov	word ptr cs:[msgleng],msgonlx	; set demo lenght
	mov	byte ptr cs:[mossdemo],10  ; terminate with linefeed
	assume	ds:nothing,es:nothing
	push	ds
	mov	ds,cs:[initmos]
	assume	ds:mos
	mov	byte ptr [mosdemo1],0cfh  ; assemble iret at mosdemo1
	mov	ds,cs:[initgrp]
	assume	ds:grp
	mov	di,offset scbsmsg+19
	sub	di,8
	mov	byte ptr ds:[di],'$'
	pop	ds
	ret
doeval:
	assume	ds:nothing,es:nothing
	push	ds
	push	es
	mov	ds,cs:[initmos]
	assume	ds:mos
	mov	byte ptr [patdemo1],0ebh   ; place jmp short
	mov	word ptr [patdemo2],9090h  ; place 2 no-ops to make code
	mov	ds,cs:[initgrp]		   ; act as demo code
	assume	ds:grp			   ; at offset patdemo1 of mosseg
	mov	si,offset scbmuser+27
	sub	si,27
	mov	byte ptr ds:[si],68h	; set default to max users
	mov	byte ptr ds:[si+1],0fch
	pop	es
	pop	ds
	ret
checkserial endp

	subttl validserial
	page
;======================================================================
;,fs
; validserial
;
; in:	
;
; out:	
;
;,fe
;=====================================================================
	assume	ds:nothing,es:nothing,ss:nothing
validserial proc near
	push	si
	push	di
	push	ds
	push	es
	mov	ax,cs
	mov	ds,ax
	mov	es,ax
	mov	si,offset enbedded+32	; ds:si has location of serial # in logo
	mov	di,offset hserial+19	; es:di has storage location for hidden
					; serial # to be computed
	sub	si,32
	sub	di,19			; this is fake out hackers
	push	di
	call	makehidden
	pop	di
	mov	si,offset rserial+36
	sub	si,36
	cld
	mov	ax,word ptr cs:[si]
	cmp	ax,word ptr cs:[di]
	jne	vsdoeval
	mov	ax,word ptr cs:[si+2]
	cmp	ax,word ptr cs:[di+2]
	jne	vsdoeval
	clc
	jmp	short vsexit
vsdoeval:
	stc
vsexit:
	pop	es
	pop	ds
	pop	di
	pop	si
	ret
validserial endp

	subttl makehidden
	page
;======================================================================
;,fs
; makehidden
; 
; the following is code algorithm use to generated hidden serial #, identical
; routine is place into makeuser for use in comparing serial #'s
; please note that 4th position will always be generated as a number.  this
; is done for legal reasons, so that there is no way a word could be
; generated which might offend someone.
;
; in:	
;
; out:	
;
;,fe
;=====================================================================
	assume	ds:nothing,es:nothing,ss:nothing
makehidden proc near
	push	ax
	push	bx
	push	cx
	push	bp

; init values to so some random but fix numbers
; routine keep attract of 4 internal counters for making
; hidden serial #'s

	mov	word ptr [hvalues],accesskey1
	mov	word ptr [hvalues+2],accesskey2

; add to values, values of 10 serial characters, looping back to
; begin for final 4 characters

	mov	bp,si			; save start offset for second round
	mov	cx,10
	xor	bx,bx
mhloop:
	lodsb
	add	byte ptr [hvalues+bx],al
	inc	bx
	cmp	bx,4
	jb	mhskip
	xor	bx,bx
mhskip:
	loop	mhloop

	mov	cx,16
	xor	bx,bx
	lea	si,special
mspec:
	lodsb
	add	al,cl
	add		byte ptr [hvalues+bx],al
	inc	bx
	cmp	bx,3
	jb	mspecnext
	xor	bx,bx
mspecnext:
	loop	mspec

; revisited the 10 characters with the following formala.
; count = corrent buffer position value (always rotating) mod 32
; for count times, add (value+37) to value in circular buffer
; 	each time rotating buffer pointer by 1

	mov	si,bp
	mov	cx,10
	xor	bx,bx
mhloop1:
	lodsb
	push	cx
	push	bx
	inc	bx
	cmp	bx,4
	jb	mhloop1a
	xor	bx,bx
mhloop1a:
	mov	cl,byte ptr [hvalues+bx]
	pop	bx
	and	cx,7
mhloop2:
	add	byte ptr [hvalues+bx],al
	add	al,accesskey3		; add a random number
	inc	bx
	cmp	bx,4
	jb	mhskip2
	xor	bx,bx
mhskip2:
	loop	mhloop2
	pop	cx
	loop	mhloop1

; for each of 4 internal values calculate hidden serial # in ascii
; format.
;
; if this is 4th position
;	ascii value if (store value) mod 10 + '0'
; else
;	x = (store value) mod 36
;	if x < 26 then
;		ascii value = (x + 'A')
;	else
;		ascii value = ((x - 26) + '0')

	mov	cx,4
	lea	si,hvalues
mcloop:
	lodsb
	cmp	cx,3			; protect against nasty words for legal
	jne	mcloop2 		; reasons
mclp:
	cmp	al,10			; always make 4th digit a number
	jb	mclow
	sub	al,10
	jmp	mclp
mcloop2:
	cmp	al,36
	jb	mcskip
	sub	al,36
	jmp	short mcloop2
mcskip:
	cmp	al,26
	jae	mchigh
	add	al,'A'
	jmp	short mcset
mchigh:
	sub	al,26
mclow:
	add	al,'0'
mcset:
	stosb
	loop	mcloop
	pop	bp
	pop	cx
	pop	bx
	pop	ax
	ret
makehidden endp

	subttl setmusers
	page
;======================================================================
;,fs
; setmusers
;
; this routine is use to set scbmuser and scbmuser+1 from the
; serial # inside code. this code is designed in such a way to make it
; hard on some one (even with assembly knowledge from debugging mos and
; changing the # of it supports.  it is designed to be call as follows.
;
;	mov	dx,125h    (these values are use to fake some on out
;	mov	bx,34h
;	call	setmusers
;
; the values 125h and 34h are use internally by routine to set the values
; for scbmuser and scbmuser+1
;
; please note: all access to scbmuser, scbmuser+1 and mossmsg are offset
; by values to confuser the onlook. this will also cause programs like
; source not to be able to cross reference these values.
;
; in:	
;
; out:	
;
;,fe
;=====================================================================
	assume	ds:nothing,es:nothing,ss:nothing
setmusers proc	near
	  push	si
	  push	di
	  push	es
	  mov	si,offset mossmsg+34h
	  sub	si,bx
	  mov	ax,word ptr cs:[si]
	  sub	ax,'00'
	  mov	dx,100			; max value for number of users
	  xchg	ah,al			; xchg low and high values
	  cmp	ax,0205h		; >= 25 or so then set max
	  jae	setmhigh
	  xor	dx,dx
	  mov	dl,al
setmloop:
	  or	ah,ah
	  jz	setmhigh
	  add	dx,10
	  dec	ah
	  jmp	short setmloop
setmhigh:

; dx now contain # of users on system

	  mov	ax,100h
	  sub	ax,bx			; 100 - 34h - # (inside bx)
	  sub	ax,dx
	  shl	dx,1
	  add	dx,bx			; 2*# + 34h (inside bx)
	  mov	es,[initgrp]
	  assume ds:grp
	  mov	di,offset scbmuser+34h
	  sub	di,bx
	  cld
	  stosb
	  mov	al,dl
	  stosb

	  pop	es
	  pop	di
	  pop	si
	  ret
setmusers endp

if	vnahard  eq 1
novna	db	13,10
	db	'This version of PC-MOS/386 requires VNA hardware.  '  ;@@xlat
	db	13,10,'$'
endif

initseg ends
	end

