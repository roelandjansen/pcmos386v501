	include page.inc
	title	mosinit - mos initialization module

	extrn	bugerror:near		; defined to turn stack overflow on

features equ	0600h			; special memman features bits
dftck	equ	16			; 16k default for cache
dftcbk	equ	2			; 2k default for cache unit of buffering
tmpck	equ	16			; 8 cache elements to start
tmpcbk	equ	2			; 2k buffers to start

comment ^===============================================================
		       development specification

 program name:	$$mos.com		assigned to: david morrow
 module name:	mosinit 		assign date: 01/16/86
 entry points:	mosinit 		completed:
 entry from:	logic from boot sector
 entry method:	jmp
 calls: 	mosddint, mosheman, mositask, mosint21 (file i/o)
 purpose:	mos kernel initialization
 refer to:	multilink module mlinit.inc
 last update:	08/18/1992
========================================================================

the code section mosinit is located at the tail end of the mos
kernel, which is contained in the file named $$mos.com on the
boot disk.  it is actually entered by way of a jmp instruction
at the very beginning of the kernel, which in turn is entered
from the bootstrap logic.

mosinit performs the following tasks:

(0) relocate the entire kernel to the end of available ram,
    referring to the bios-computed memory size at 0040:0013.

(1) point ss:sp to the stack in the foreground tcb, which is
    allocated right after the scb at the front of the mos
    kernel.  set up a temporary heap.

(2) set up mos interrupt vectors.  call mosddint to initialize
    the internal device drivers.  set up a temporary disk buffer
    for config.sys i/o.

(3) use int 21 to perform required file i/o: read the entire
    config.sys file from the root directory, saving all
    parameters into a temporary work area.  parameters of
    immediate interest are memdev=, heapsize=, buffers=, and
    freemem.  other parameters must also be saved, for future
    reference.

(4) if memdev (the memory-management device driver) was
    specified, load it into low memory (at address 1000h) and
    initialize it.  note that the mos kernel was loaded to high
    ram to reserve space for this driver.  if "direct mapping"
    is supported and freemem was not specified, set up a
    reasonable default free memory area between c0000 and dffff.

(5) relocate the mos kernel.  if there is a freemem area large
    enough, put the kernel there.  otherwise, move it down just
    above the retained portion of the memory-management driver
    (or at 01000h if there was none).  do not relocate the
    memory-management driver.

(6) referring to freemem and buffers, allocate the disk buffers
    overlaying mosinit (as relocated by step 5) with the disk
    buffers.  of course, mosinit must not do anything that will
    cause the disk buffers to be written into.

(7) referring to freemem and heapsize, allocate the heap.  the
    default location is just above (after) the disk buffers.

(8) load all other user-specified drivers into the heap.
    initialize them as they are loaded.

(9) plug various interrupt vectors.

(10) call mositask to initiate the foreground task.

(11) exit to the foreground task (the command processor).

=======================================================================

mjs 1/26/87	initialized ds:si to point to autoexec string as
		startup batch file name

mjs 02/24/87	cooking modes. removed all references to mosmiman
		since that module is no longer a device driver.
		also, put the memory management driver into
		binary mode before reading the 4 byte address.

sah 05/18/87	freemem=no allowed in config.sys

sah 06/25/87	correct last line in config.sys (check for ctrl-z)

rbr 06/26/87	removed temporary default resident memman driver.
		fixed scummy interrupt vector relocation for compaq.

sah 07/08/87	added code to copy freemem information into scbbuff
		for later use mos.com utility program. added code to
		set end segment in scbmosend.

mjs 07/21/87	modified allocation order into freemem, included the
		module $$shell.sys in what can be relocated, added
		the config.sys parm: vtype

sah 07/23/87	actual addition of vtype in config.sys

sah 07/27/87	added initialization of far call to int 38 for
		reseting beforing execing application

jsm 07/31/87	call mosint21 directly instead of using real int 21h
		calls (to detour around device drivers).

jsm 08/06/87	remove extrn reference to pgm1 (unused).

rbr 08/24/87	allow extra byte after 'Z0Z0Z' for serialization.
		seems we were trashing first byte of init code.

sah 10/20/87	added demo message and options.inc addtion

sah 10/21/87	added conditional assembly of mosdebug support

sah 10/26/87	change demo message

sah 11/06/87	added call to initmcb so that mcb's will be initialize
		before executing the initialization sequence for the
		the device drivers in the config.sys.  this solves a
		problem with the micro-bernoulli box

jsm 11/18/87	added call to inidvars to solve the other problem
		with the micro-bernoulli box, which was inadequate
		simulation of the dos variable table.

mjs 11/24/87	irma support.  added code to initialize 40:80 and 40:82
		which show the start and end of the keyboard buffer.

rbr 1/11/88	change load address of memdev driver from 00800 to
		00700, but do not write over 007f0-007ff.

sah 01/18/88	change scbseg and zero segment accesses to use macros
		mgetscb and mgetzero.  optimize group segment handling
		during config.sys parameter execution - faster and
		tighter.  change copyright to include 1988
		corrected non-memory management case handling of 7f:000
		area and made major changes to config.sys command
		processing which assured that es --> grp, this save both
		time and more critically space.

sah 01/21/88	change master context init logic for 1024 bytes for
		interupt table which is move out the context table but
		is still part of the context area.

sah 01/22/88	change scbseg to mo2seg (mos 2nd code segment)

sah 01/23/88	added code so if memdev is invalid system will not lock

sah 01/25/88	changes so that device=memdev driver will not lock up
		system (by checking device header for $$memdev)  also
		corrected a bug in display bad device name to the user

mjs 2/8/88	added code to enable trapping on ports 43, 42 and 40 for
		the timer/counter chip.  this trapping is always used
		rather than being switched on or off per task as the
		initioptbl procedure does.

sah/rbr 02/12/88 added code for initialization of no1seg for mos's new
		method of inter-segment calls

rbr 02/15/88	new logo screen.  overlap initialization with logo
		display time for faster boot.  make the segment address
		for grp point to the memory allocated for it, and not
		below it (i.e., no more bff0)  ; add "declare" calls.

sah 02/17/88	286 declare calls for video areas
		286 declare calls for disk buffers
		286 declare calls for command processor's code segment
		made sure that command processor's code segment has
		has bits 0 and 1 set

sah/rbr 02/21/88 move ddt code to mo2 group.

sah 02/29/88	made scbfar38 point to vector in vector table so that
		device drivers like lanlink can access it.

mjs 3/7/88	removed int2f from the plugtable.  putting an int2f
		handler in mosnxtsk - a simple one to indicate that
		the share tsr is loaded - for apps like rm\cobol that
		look for share.
		allocate a block from the smp and record its segment
		in scbidqp.  this is for port specific irq reservations.

rbr 03/11/88	fixed incorrect declarations for video ram, disk
		buffers, and command processor segment.  added
		declarations of disk buffer data areas.

rbr 03/12/88	support for grpseg1, grpseg2, so the mgetscbx macros
		can load the grp segment address relative to cs.

sah 03/31/88	initialize scbmapxxx routines to point to mapxxx so that
		external video drivers like sunriver driver can access
		this routines.

rbr 04/18/88	put mos kernel on an "RPL3" boundary in the case where
		it is loaded just after the memman driver. see	;041888.

mjs 04/28/88	modified the register call to ddtmc to pass es:bx
		pointing to scbmapvmf.	modified the initialization
		of the port specific irq reservation table to be done
		with interrupts disabled.

rdg 04/28/88	modified config.sys processing (pccnty) to use mos
		fun38 to validate requested country code.

jrb 05/13/88	handle device=d:\path\$cache.sys case

rbr 05/14/88	fixed some glitches whereby we were not always alloca-
		ting contiguous extended memory for stuff in freemem,
		causing the 286 driver to get confused.  part of this
		fix was to allocate space for the cache descriptor
		list before allocating cache memory.

mjs 6/21/88	added code to setup the new interrupt management scheme
		when a memory driver which supports an actual interrupt
		vector table is used.  added code to set the actual
		int8 vector to lidtint08.

mjs 7/2/88	took out mmparm struc and added 'inlude macros.inc' for
		access to the common mmparm struc.

rdg 07/06/88	gated access to the console device drivers to prevent
		corruption of the serial data stream being sent to a
		terminal by changing the calls to the console device
		driver from a call dword ptr [si] to call ddtcallf

sah 07/12/88	clean up source so that it could be more readable

mjs 7/14/88	added to lidt initialization code to include int9.
		also, cleaned out dead code.

sah 07/14/88	initialize scbmo2end to be segment location of grp+mo2
		converted calls to relomos to relojoin where relojoin
		will call relogrp to relocate the grp segment and new
		relomos to relocate mos segment and jump into it.
		major changes to relocation so that mos can work in non
		adjacent segments. added logic to support mos loaded at
		fff8h.	move system psp into grp segment.

sah 07/29/88	added code for lidt only version of memman driver

jrb 07/29/88	changed first and last timer parameters to cache=
		config.sys command to seconds instead of ticks
		if both cache= and device=$cache.sys are present,
		display error messsage and ignore device=$cache.sys
		'Both CACHE= and DEVICE=$CACHE.SYS commands encountered'
		'DEVICE=$CACHE.SYS ignored'

sah 08/01/88	additions for lidt driver with highmemory support

sah 08/06/88	added init segment and move config.sys and master
		security password processing into init segment
		transfer all routines in init segment to source module
		mosinit2. also move standard devices and cache init into
		mosinit2.

rkg 08/07/88	public necessary symbols for mosinit2

mjs 10/21/88	remove all calls to linkdrv and modify all calls to
		mosddint to account for a new entry parameter.

sah 11/01/88	one line fix for intersegment call to finddm

mjs 11/16/88	modified tsl to save and restore 32 bit registers when
		running on a 386 machine.

sah 12/04/88	move bootdrv into scb (renamed to scbbootdrv)

sah 03/14/89	corrected a problem in relomos where init segment +
		mos segment was greater than 64k bytes and was causing
		nos to crash on boot up.

sah 07/18/89	turn off breaking during main initialization time

bwr 11/28/89	marked messages for foreign language translations.

sah 12/08/89	conditional assemble 286 driver logic out.

sah 12/18/89	changes for split smp.

sah 01/10/90	made demo code always be include and patch it out if
		demo version version is not intended to be use. see
		mosinit2

sah 01/22/90	converted reg32 to into scb variable.

mjs 05/22/90	set new var: scbinit, to indicate end of init process

mjs 05/25/90	initialize scbirqbnk

mjs 03/26/91	moved cnfbuf structure to moscnf.inc since both mosint
		and mosinit2 use it.
		added logic to change 40:13 when device drivers are
		being loaded.  this is necessary because sysload/periscope
		does an int12 to see what part of the high base memory
		it can use.

mjs 03/28/91	add line to reset the tcbtslnst counter to 0 after
		the call to mositask sets it to 1.  (llnetbios)

================ 5.01 Kernel Ends Here ====================================

mjs 08/18/92	clean up segment declarations

=======================================================================^

.xlist
;	include mosinit.pub
	include options.inc
	include group.inc
	include macros.inc
	include moscdb.inc		; needed in relocation of heap
	include mosbdb.inc		; needed to set up disk buffers
	include mosregs.inc
	include	moscnf.inc
	include mospsp.inc

tcb	segment at 1234h
	include mostcb.inc
tcb	ends

gdata	segment
	include mosscbex.inc
gdata	ends
.list

gdata	segment
	extrn	fgtcboff:near,ddtmctcb:word,mcsnow:byte,gend:byte
	extrn	initpsp:byte
gdata	ends

callmos macro
	pushf				;; simulate int 21h
	cli
	push	cs
	call	mosint21
	endm

callinit macro	addr
	mov	word ptr cs:[sinitaddr], offset addr
	call	cainit
	endm

irq	segment
	extrn	irqstart:byte, irqend:byte
irq	ends

poll	segment
	extrn	pollstart:byte, pollend:byte
poll	ends

; the cnfbuf segment is used to define the structure of the config.sys
; data and the pointers used during its processing.  the segment will
; actually reside in the system heap.  the ddtable is used to save
; pointers to the device driver filenames since they are not loaded
; until after the buffers and buffaddr commands are found.

;======================================================== ddt segment
if 0 eq 0
segment_num = 2
endif
ddt	segment
	extrn	mo1seg:word,mcterm:near,mo2end:byte
	extrn	grpseg2:word
ddt	ends

;======================================================== mos segment
if 0 eq 0
segment_num = 1
endif
mosseg	segment
	assume	cs:mos,ds:nothing,es:nothing,ss:nothing

	public	mosinit

	extrn	sbios:word, sinit:word, sinitaddr:word
	extrn	mo2seg:word, scbfree:word, mosddint:near, mosheman:near
	extrn	mositask:near, scbstdcon:near, scbstdblk:near
	extrn	mosend:byte, mosint21:near, hex2asc:near
	extrn	mosint13:near, mosint23:near, lidtint08:near, lidtstub8:near
	extrn	mapvmf:far, mapvsf:far
	extrn	mosint38:near, initmcb:near, inidvars:near
	extrn	doesc:near, savtable:word, mmret:near, scanguts:near
	extrn	scbstdhd:byte, bootseg:word, mosstdclk:byte
	extrn	mosoldfn:near, mosstart:far,lidtstub9:near
	extrn	grpseg1:word, ddtcallf:near, initcall:far

if	mdebug eq 1
	extrn	dec2asc:near, mosdebug:near
endif

; status display messages (if bit0=1 in debug)

if	 mdebug eq 1

dbmsg1	 db	'Disk buffers located from      '  ;@@xlat
dbdata1  db	'     to  '		;@@xlat
dbdata2  db	'    ',13,10,10,'$'
dbmsg2	 db	'SMP located from    '	;@@xlat
dbdata3  db	'     to  '		;@@xlat
dbdata4  db	'    ',13,10,'$'
msgrlo	 db	26,26,8,8,'MOS relocated to        '  ;@@xlat
msgrlo1  db	'    , MO2 -> '
msgrlo1a db	'    , GRP -> '
msgrlo2  db	'    ',13,10,'$'
msgmmer  db	13,10,'MEMDEV init error: code in BL ',13,10,'$'  ;@@xlat
msgmmclz db	13,10,'MEMDEV close error: code in BX ',13,10,'$'  ;@@xlat
msgdm	 db	'DMPATCH -> 0000 0000 0000 0000 0000 0000 0000 0000'
	 db	' 0000 0000',13,10
msgdm2	 db	'DMBUFFR -> 0000 0000 0000 0000 0000 0000 0000 0000'
	 db	' 0000 0000',13,10,'$'
endif

	public	dmlist,dmflags,dmpatch,dmbuffr
	public	cnfseg,gseglen,curmode,cpres
	public	smthere,mosaddr
	public	tmpheap,tmphpsiz
	public	mmdevice,mmsegmt,mmlseg,og4013,dd4013

og4013	dw	0			; original 40:13 value
dd4013	dw	0			; value for 40:13 with load drivers
smthere db	'N'			; set to y when startup screen displayed
mmdevice db	'$$MEMDEV',0		; memman driver name
msgcrlf db	13,10,'$'
msgmm3	db	'00000k of $ '		;@@xlat
msgmm4	db	'00000k memory used.     ',13,10,'$'  ;@@xlat
	even
retadr	dw	0			; return address storage for call's
cnfseg	dw	0			; segment address of config file buffer
cnfhdl	dw	0			; file handle for config and loading drivers
tmpheap  dw	0			; address of temporary heap
tmphpsiz dw	1000h			; default to 64k
mosaddr dw	0			; mos segment (may not be executing there)
mosolda dw	0			; mos original cs load address
mmsegmt dw	0			; used in initp4
mmlseg	dw	7fh			; memman loading address (constant)
charsav db	0			; save space for char in device statements
curmode db	0			; save area for video modes
dbset	db	'N'			; flag for allocating disk buffers (initp6)
dmlist	dw	0			; pointer to next 'dmpatch' entry to use
dmpatch dw	5 dup (0,0)		; list of freemem values given by user
	dw	0			; terminator
dmbuffr dw	5 dup (0,0)		; list of freemem used by mos

autoex	db	'AUTOEXEC',0		; autoexec ascii string
cpres	db	'$$shell.sys',0 	; standard name for the command processor

tonewcs db	'Y'			; set to n if relomos to not change cs

dmflags db	00h			; bit 0	= mos is relocated into high mem
					; bit 1	= smp is relocated before kernel
					; bit 2	= mos relocated smp in freemem space
					; bit 3	= inside initp5
					; bit 4	= special memman driver


	public	dtimeout
dtimeout db	'   This 60 minute demo session has expired.$      '  ;@@xlat

;    everything from here on is overlaid by disk buffers and smp

	public	clobber 		; shouldn't clobber be after the even??
clobber label	byte
	even
gseglen dw	0			; to contain grp size in paragraphs
msgmmnf db	'Cannot find MEMDEV driver       ',13,10,'$'  ;@@xlat
msgmm2	db	'Error loading MEMDEV driver          ',13,10,'$'  ;@@xlat

	subttl mosinit - mos initialization
	page
;======================================================================
;,fs
; mosinit - mos initialization
;
; this module will do the majority of the mos initialization
; including setup of device drivers (operating system internal as
; well as user defined), processing of the config.sys file,
; allocation of the disk buffers, allocation of the heap, and the
; initiation of the foreground task.
;
; in:	none
;
; out:	not returned from, exits to fg task
;
;,fe
;=====================================================================
	assume	ds:nothing,es:nothing,ss:nothing
mosinit proc	near

; this little section will allow us to boot with or without periscope
; active.  if periscope is found to be active then it is invoked.

	xor	ax,ax
	mov	es,ax
	les	si,es:[2*4]		; check for periscope active or not
	cmp	word ptr es:[si],0b450h
	jne	noperis
	int	2			; activate periscope
noperis:
	mov	es,cs:[sinit]
	assume	es:init
	mov	es:[initmos],cs 	; set addressability to mos
	mgetscb ds
	assume	ds:grp
	mov	es:[initgrp],ds 	; set addressability to grp
	mov	ax,cs:[mo2seg]
	mov	es:[initmo2],ax 	; set addressability to mo2
	pushf
	xor	ax,ax
	push	ax
	popf				; try to put zero in flags
	pushf
	pop	ax
	and	ax,0f000h
	cmp	ax,0f000h
	je	no386
	mov	ax,0f000h		; try to but 1's in high bits
	push	ax
	popf
	pushf
	pop	ax
	and	ax,0f000h
	je	no386
	mov	[scbreg32],'Y'		; set flag for 32 bit operations
no386:
	popf
	callinit initpa 		; call init code segment
	mgetscb ds
	assume	cs:mos,ds:grp,es:nothing,ss:nothing
	mov	[mosolda],cs		; save current cs for move of resident mm
	call	initp1			; set stack in fg's TCB
	assume	ss:tcb
	mov	byte ptr [tcbbrk],0ffh	; make sure that break is off
	mov	ax,[scbvidad]		; these 2 lines via phone from jrb
	mov	[tcbvidw2],ax
	lea	ax,doesc		; esc seq processing routine in console drvr
	mov	[tcb$er],ax		; set it
	lea	ax,tcb$eb		; esc buffer
	mov	[tcb$ebp],ax		; buffer pointer to start of buffer
	push	es
	mov	es,[sinit]		; point to init segment
	assume	es:init
	push	ds			; set up mos's kernel
	mov	ds,[mo2seg]		; get mos 2nd code segment
	mov	es:[initmo2],ds 	; setup pointer to mos 2nd segment in init
	mov	es:[initmos],cs 	; setup pointer to mos 1st segment in init
	assume	ds:mo2
	mov	[mo1seg],cs		; set mo1seg value
	pop	ds
	assume	ds:grp
	mov	es:[initgrp],ds 	; setup pointer to mos grp segment in init
	pop	es
	assume	es:nothing
	call	initp0			; move mos to top of memory
	mov	[mosaddr],cs		; set address to current segment
	mov	[scbmosadr],cs		; set for ddtmc
	callinit initpb 		; set aux,con,prn and smp allocation test
	call	initp5			; relocate mos (if required or requested)
	callinit initpc 		; after final relocation setup
	mgetscb ds
	assume	es:nothing,cs:mos,ds:grp
	mov	es,[scbtcbpf]		; get pointer to fg tcb
	lea	sp,tcbstack-100h	; room for mositask to work
	push	cs
	pop	ds
	assume	ds:mos
	lea	si,[autoex]
	call	mositask		; set up fg and load task command processor
	jnc	setfgcnt		; continue with fg setup

; error with task 0 itask

	cmp	al,2			; file not found (command processor)?
	je	nocpfnd 		; yes
	cmp	al,3			; path not found?
	je	nocpfnd
	call	bugerror
	db	'  MOSITASK failure    ',0  ;@@xlat
nocpfnd:
	call	bugerror
	db	'  Command processor cannot be found   ',0  ;@@xlat
setfgcnt:

; the call to mositask will have set this counter to 1.  for the
; foreground task, must compensate and get it back to 0.

	mov	[tcbtslnst],0

; note: the tcbsp value must be saved since a call to the os will
; think that this is a recursive call and change it.

	push	[tcbsp]

; calc and display % heap used

	callinit dispsmp
	mgetscb ds
	assume	ds:grp

; if 286 driver is present, set the dynamic area

if	code286
	test	[scbmmfea],08h		; "declare" call supported?
	jz	mmsetdax		; no, skip
	mov	ah,0bh			; yes, set dynamic area
	mov	bx,[tcbbegad]
	mov	cx,[tcbendad]
	sub	cx,bx
	call	[scbmmsub]
mmsetdax:
endif

if	mdebug eq 1

	cmp	[scbmmfg],'Y'		; memman active
	jne	skipmm			; no

; display memman message

	push	ds
	lds	bx,[scbmmptr]
	assume	ds:nothing
	mov	ax,[bx+pamrused]	; total 4k blocks allocated
	mov	bx,[bx+parmtot] 	; total 4k blocks
	push	cs
	pop	ds
	assume	ds:mos
	push	bx			; temp save
	lea	bx,msgmm3
	call	dofstr
	pop	ax
	lea	bx,msgmm4
	call	dofstr
	pop	ds
	assume	ds:grp
skipmm:
endif

	mov	byte ptr [tcbbrk],00h	; make sure breaking is on

; add terminal driver to device driver list

	assume	es:nothing
	pop	[tcbsp] 		; ok to restore now, no more switches
	mov	sp,[tcbsp]
	pop	ax			; throw away first scbnoswt save
	mov	[scbinit],1		; indicate done with init
	cmp	[scbreg32],'Y'
	je	min386a
	popf
	pop	ax
	pop	bx
	pop	cx
	pop	dx
	pop	si
	pop	di
	pop	bp
	jmp	min386b
min386a:
	db	66h
	popf
	db	66h
	pop	ax
	db	66h
	pop	bx
	db	66h
	pop	cx
	db	66h
	pop	dx
	db	66h
	pop	si
	db	66h
	pop	di
	db	66h
	pop	bp
	db	0fh,0a1h		; pop	fs
	db	0fh,0a9h		; pop	gs
	db	66h
	pop	sp			; esp
min386b:
	pop	es
	pop	ds

; enter fg's command processor (really enter the ntrTSK routine)
; (we have now finished all mosinit)

	ret

	even
	assume ds:nothing,es:nothing
	public	bugshell, bugopen
bugshell proc  near
	call	bugerror
	db	"Error:  "		;@@xlat
bugopen db	'opening $$SHELL.SYS        ',0
bugshell endp

	subttl updfree - update scbfree
	page
;======================================================================
;,fs
; updfree - update scbfree
;
; update scbfree in both the local and relocated locations
;
; in:	new value for scbfree in ax
;
; out:	none
;
;,fe
;=====================================================================
	assume	ds:nothing,es:nothing,ss:nothing
public	updfree
updfree proc	near
	push	ds
	push	es
	mgetscb ds
	assume	ds:grp
	mov	[scbfree],ax
	mov	es,[scbmosadr]		; set in relocated mos also (for mositask)
	assume	cs:nothing,es:mos
	mov	es:[scbfree],ax
	pop	es
	pop	ds
	assume	cs:mos,ds:nothing,es:nothing
	ret
updfree endp

if	mdebug eq 1

	subttl mosstat - display system information
	page
;======================================================================
;,fs
; mosstat - display system information
;
; in:
;
; out:
;
;,fe
;=====================================================================
mosstat proc	near
	push	ax
	push	bx
	push	si
	call	clearsm
	push	ax
	push	ds			; for mosdebug
	push	dx			; "     "
	push	cs
	pop	ds
	assume	ds:mos
	lea	bx,dmpatch
	lea	dx,msgdm+11		; data management info
	call	dmhex			; format dm pointers
	lea	bx,dmbuffr
	lea	dx,msgdm2+11
	call	dmhex
	lea	dx,msgdm
	xor	al,al			; no frill display
	call	mosdebug
	pop	si
	pop	bx
	pop	ax
	ret
dmhex	label	near			; format ascii of dm table values
	xor	si,si
dmhexlp:
	mov	ax,[bx+si]		; get dm pointer
	call	hex2asc
	add	dx,5			; next loc in ascii string
	add	si,2			; next dm pointer
	cmp	si,2*10 		; end of table yet?
	jb	dmhexlp
	ret
mosstat endp

	subttl dofstr - print formated string
	page
;======================================================================
;,fs
; dofstr - print formated string
;
; convert ax value to ascii decimal and print string pointed to by
; ds:bx without leading spaces.
;
; in:	ax = 16-bit value
;	ds:bx -> 5 byte area to store ascii string result
;
; out:	
;
;,fe
;=====================================================================
	assume	ds:nothing, es:nothing, ss:nothing
dofstr	proc	near
	shl	ax,1			; calc total k
	shl	ax,1
	mov	dx,bx
	call	dec2asc
clrspc:
	cmp	byte ptr [bx],' '
	jne	dostrx
	inc	bx
	jmp	clrspc
dostrx:
	mov	dx,bx
	call	dispmos
	ret
dofstr	endp

endif

	subttl initp0 - relocate mos to top of memory
	page
;======================================================================
;,fs
; initp0 - relocate mos to top of memory
;
; in:	ds -> grp
;
; out:	none
;
;,fe
;=====================================================================
	assume	ds:nothing,es:nothing,ss:nothing
initp0	proc	near
	assume	ds:grp
	int	12h			; get mem size
	mov	cl,6			; calc from k to paragraphs
	shl	ax,cl
	sub	ax,[tmphpsiz]		; leave room for temporary heap
	sub	ax,tmpck*(1024/16)+tmpck/tmpcbk  ;jrbr temporary cache size
	lea	bx,mosend+15		; "     "	 mos code (what we'er moving)
	shr	bx,1
	shr	bx,1
	shr	bx,1
	shr	bx,1
	sub	ax,bx			; leave room for dbb (prefix)
	sub	ax,[gseglen]		; account for mo2 length
	mov	bx,offset init:initend+15
	shr	bx,1
	shr	bx,1
	shr	bx,1
	shr	bx,1
	sub	ax,bx			; account for init segment

; set dd4013 to reflect the memory used by mos.  this is to prevent
; sysload/periscope and other device drivers from thinking that
; the upper part of the 640 memory is entirely free.

	mov	cl,6
	mov	bx,ax
	shr	bx,cl
	dec	bx
	mov	[dd4013],bx

; move mos and return here (in new seg)

	mov	es,ax
	call	relojoin
	ret
initp0	endp

	subttl initp1 - init stack in fg tcb
	page
;======================================================================
;,fs
; initp1 - init stack in fg tcb
;
; in:	ds -> grp
;
; out:	none
;
;,fe
;=====================================================================
	assume	ds:nothing,es:nothing,ss:nothing
initp1	proc	near
	assume	ds:grp
	lea	ax,mmret		; far ret in mositask
	mov	word ptr [scbmmsub],ax	; init memman entry point to retf
	mov	word ptr [scbmmsub+2],cs
	pop	[retadr]		; save return address of call
	lea	bx,fgtcboff		; address fg's TCB (on paragraph alignment)
	mov	ax,ds			; this assumes that ds --> grp
	shr	bx,1
	shr	bx,1
	shr	bx,1
	shr	bx,1
	add	ax,bx			; fg tcb segment
	lea	bx,tcbstack
	cli				; by convention
	mov	ss,ax
	assume	ss:tcb			; currently addressing fg's TCB
	mov	sp,bx
	sti
	mov	[tcbslice],1		; give fg a time slice to run in
	mov	[tcbstkp],bx
	mov	[scbtcbpc],ax
	mov	[scbtcbpf],ax		; set 1st and last tcb pointer to fg
	mov	[scbpripf],ax
	mov	[scbtcbpl],ax
	mov	[scbtcbpv],ax		; set visible task
	mov	[scbslice],1		; default to 1 time slice/task
	mov	byte ptr [fgtcboff+0],'H'  ; fake a heap entry
	mov	byte ptr [fgtcboff+1],'T'  ; set fg block type to tcb
	jmp	[retadr]		; back to calling routine
initp1	endp

	subttl ldmmdev - load and init memdev
	page
;======================================================================
;,fs
; ldmmdev - load and init memdev
;
; this routine will load the specified memdev program to the 'mmlseg'
; address and initialize the driver.
;
; in:	ds -> grp
;	mmdev1 and mmdev2 point to the name of the memdev file
;
; out:	mmsegmt -> free memory segment after driver, 0 if no driver
;	cf = 0 if no errors
;
;,fe
;=====================================================================
	assume	ds:nothing,es:nothing,ss:nothing
public	ldmmdev
ldmmdev proc	near
	assume	ds:grp
	push	ax
	push	bx
	push	cx
	push	dx
	push	ds
	cmp	[cnfseg],0		; any config.sys file read?
	je	mmnocnf
	mov	ds,[cnfseg]		; address config.sys data
	assume	ds:cnfbuf
	mov	si,[mmdev1]		; get pointer to memdev file name
	or	si,si			; any memdev specified?
	jnz	mmyes			; yes
mmnocnf:
	stc				; set error flag for return
	jmp	ldmmend 		; no memdev given, skip this stuff
mmyes:
	assume	ds:cnfbuf
	cmp	si,-1			; specified no memman?
	jne	mmyes2			; no, continue load
	stc				; return error of no mm
	jmp	ldmmend
mmyes2:
	mov	cl,[mmdev2]		; get name length
	xor	ch,ch
	push	si			; save start of string pointer
	add	si,cx			; point to end of string
	mov	di,cx			; save length for error routines
	xor	al,al
	xchg	byte ptr [si],al	; terminate with 0 (for asciiz)
	mov	bx,si			; save pointer for restoral
	mov	[charsav],al		; save char for restoral
	pop	si			; restore starting pointer
	mov	dx,si			; pointer for dos call
	mov	ax,3d00h		; open file for reading only
	callmos
	jnc	$+5			; no errors
	jmp	mmerr			; device not found
	mov	[cnfhdl],ax		; save handle
	mov	al,[charsav]
	mov	byte ptr [bx],al	; restore char where we put terminator
	mov	ax,0070h		; memdev driver starts at 00700
	mov	bx,[cnfhdl]		
	push	ds			
	mov	ds,ax			
	mov	es,ax			
	mov	cx,256-16		; load 00700-007ef
	xor	dx,dx			
	mov	ah,3fh			
	callmos 			
	mov	cx,16			; throw away next 16 bytes
	mov	dx,256			
	mov	ah,3fh			
	callmos 			
	mov	cx,0ffffh		; now read the rest
	mov	dx,256			
	mov	ah,3fh			
	callmos 			
	pop	ds			
	jnc	$+5			
	jmp	mmerr			

; file is read in, now init it.

mmdeflt:
	call	clearsm 		; clear logo from the screen
	xor	bx,bx			; es set above, on read
	mov	dx,si			; pass pointer to parms after '='
	push	si			; save string pointer
	add	si,di			; point to end of string
	mov	al,[mmdev2+1]		; get length of parms
	xor	ah,ah
	add	si,ax			; point to end of string
	add	si,2			; point past cr, lf
	xor	al,al
	xchg	[si],al 		; terminate with 0 (for asciiz)
	mov	[charsav],al		; save char for restoral
	xor	al,al			; link into scbdrvr list
	call	mosddint
	mov	[mmsegmt],dx		; new available free segment
	push	ax
	mov	al,[charsav]
	mov	[si],al 		; restore char
	pop	ax
	pop	si			; string pointer back
	or	al,al			; any errors during init of driver?
	jz	mmcls			; no

; error during init of memdev

if	mdebug eq 1

	call	clearsm
	push	ax
	push	ds
	push	dx
	push	cs
	pop	ds
	assume	ds:mos
	lea	dx,msgmmer		; memman error
	mov	bx,ax			; bl has error code from mosddint
	mov	al,3			; get reg dump and do 'Abort or Ignore'
	call	mosdebug
	assume	ds:cnfbuf
	jnc	mmcls			; ignore selected
endif

	jmp	ldmmend 		; do not load memman driver (or use)
mmcls:
	mov	ah,3eh
	mov	bx,[cnfhdl]
	callmos 			; close file
	jc	$+5			; error
	jmp	ldmmend

if	mdebug eq 1

	call	clearsm
	push	ax
	push	ds
	push	dx
	push	cs
	pop	ds
	assume	ds:mos
	lea	dx,msgmmclz		; memman closing error
	mov	bx,ax			; bl has error code from mosddint
	mov	al,3			; get reg dump and do 'Abort or Ignore'
	call	mosdebug
	assume	ds:cnfbuf
	jnc	ldmmend 		; ignore selected (attempt to use memman)
endif

	jmp	ldmmend 		; abort, do not use memman driver
mmerr	label	near
	lea	dx,msgmmnf		; not found msg
	cmp	al,2			; file not found?
	je	mmdonf
	lea	dx,msgmm2		; error loading message
mmdonf:
	push	cs
	pop	ds			; address local message
	assume	ds:mos
	call	dispmos
	stc				; set error flag for return
ldmmend:
	pop	ds
	assume	ds:grp			; restored from entry value
	pop	dx
	pop	cx
	pop	bx
	pop	ax
	ret
ldmmdev endp

	subttl initp5 - relocate mos if needed
	page
;======================================================================
;,fs
; initp5 - relocate mos if needed
;
; relocate mos to its permanent home.  if a memman driver is present
; that supports direct mapping calls and there is a freemem area large
; enough then mos will be relocated to high memory.  if a memman driver
; is present that does not support direct mapping calls or no freemem
; area is large enough then mos will be relocated to just after the
; memman driver.  if no memman driver is present then mos will be
; relocated to the lowest possible segment (70:0 for grp).
; the device driver list is also changed to reflect the relocation of
; mos for the internal device drivers.
; updated 07/14/88 to support seperate allocations of grp+mo2 
; and mos segements and usage of highmem address at fff8 segement
;
; in:	ds -> grp
;
; out:	mos relocated as outlined above
;
;,fe
;=====================================================================
	assume	ds:nothing,es:nothing,ss:nothing
initp5	proc	near
	assume	ds:grp, es:nothing
	or	[dmflags],08		; indicated inside initp5
	mov	ax,cs			; set up for continued execution in this seg
	push	ax
	lea	ax,initp5r
	push	ax
	mov	ax,[mmsegmt]		; did we load a memman driver?
	or	ax,ax
	jnz	ckdmap			; yes driver loaded, check for direct mapping

; no memman driver loaded, relocate mos to lowest possible address

	mov	ax,cs			; mos segment
	sub	ax,[mo2seg]		; calc size of mos 2nd code segment
	add	ax,[gseglen]		; add in grp length
	add	ax,70h			; put grp at boot load location of 60:100
	mov	es,ax
	call	relojoin		; do normal relocation (to lowest address)

; note: do not reset int 13 redirector as with memman relocation
; since int 13 vector was set back when driver not loaded

	jmp	coninit
ckdmap:
	test	[dmflags],01h		; support high mem bit
	jnz	relommhh
	test	[scbmmfea],80h		; is full mapping supported?
	jnz	$+5			; yes
	jmp	relomm1 		; memman without direct mapping calls

; relocate to freemem space (if large enough)

	mov	[scbfree],ax
	push	ax			; save 'mosaddr'
	mov	ax,cs			; calc # para's needed for MOS
	sub	ax,[mo2seg]		; ax = # para's for MOS 2nd code segment
	add	ax,[gseglen]		; add in grp length
	mov	bx,[scbmosend]		; get paragraphs
	add	ax,bx

if	code286 eq 1
	sub	ax,105h 		; subtract the 108h and add 3 paragraphs
else
	sub	ax,108h 		; subtract the 108h
endif

	callinit finddm 		; find data management block large enough
	or	ax,ax			; find one?
	jz	relommhm
	jmp	relomm3

; at this point we can not put grp+mo2+mos into into one contigious area
; or that we support the highmem bit

; relocate grp and mo2 first

relommhh:
	mov	[scbfree],ax
	push	ax

relommhm:
	pop	ax			; discard 'mosaddr'
	mov	ax,[scbmo2end]		; get end of grp and mo2

if	code286
	add	ax,3			; adjust size for the 286
endif

	mov	bx,ds
	sub	ax,bx
	mov	bx,ax			; save size for later
	callinit finddm
	or	ax,ax
	jz	nogrp

if	code286
	or	al,3			; for the 286 driver
endif

	mov	es,ax
	call	relogrp
	jmp	short relommms
nogrp:
	mov	es,[scbfree]
	mov	ax,ds
	mov	bx,[scbmo2end]
	sub	bx,ax
	add	[scbfree],bx
	call	relogrp
relommms:

; now is the time to relocated mos segment

	test	[dmflags],01h		; highmem style
	jz	normmos
	mov	ax,0fff8h		; set segment to fff8h
	mov	es,ax
	jmp	short dorelo2		; and jump into relocation logic

; highmem is not support, so try normal memory management

normmos:
	mov	ax,[scbmosend]

if	code286
	add	ax,3			; adjust size for 286
endif

	mov	bx,ax
	callinit finddm
	or	ax,ax
	jz	nomos

if	code286
	or	al,3			; for the 286 driver
endif

	mov	es,ax
dorelo:
	mov	ax,es
	sub	ax,108h 		; adjust for the high mem
	mov	es,ax
dorelo2:
	mov	[mosaddr],es		; save new address for later use in mosinit
	mov	[tonewcs],'N'		; don't change cs
	call	relomos
	jmp	short relommrj
nomos:
	mov	es,[scbfree]
	mov	ax,[scbmosend]
	add	[scbfree],ax
	jmp	short dorelo
relomm3:

; relocate mos to memman memory space up high (c000+)

if	code286
	or	al,3			; seg address must end in binary 11
endif

	mov	bx,cs
	sub	bx,[mo2seg]		; calc space needed for mos 2nd code segment
	add	ax,bx			; grp is 1st in new location
	add	ax,[gseglen]		; add in grp length
	mov	es,ax			; yes, relocate to data management space
	mov	[tonewcs],'N'		; don't change CS
	pop	bx			; discard 'mosaddr'
	call	relojoin
relommrj:
	mov	ax,es			; ax is new mos code segment
	mov	es,es:[mmlseg]		; address memdev load segment
	mov	es:[2],ax		; new int 13 segment in redirector
	add	sp,4			; discard int5pr "resume" address
	callinit intvrst		; set new int segment values
	jmp	initp5a 		; process driver chain

; relocate to just above memman driver

relomm1:
	mov	ax,cs			; mos segment
	sub	ax,[mo2seg]		; calc difference to grp segment
	sub	ax,10h			; grp addressed from 100h
	add	ax,[gseglen]		; add in grp length
	add	ax,[mmsegmt]		; load mos just after memman driver

if	code286
	or	al,3			; in case of 286 driver
endif

	mov	es,ax
	call	relojoin
	push	bx
	mov	bx,es
	mov	ax,[mmlseg]		; memman load segment
	mov	es,ax
	mov	es:[2],bx		; set new int 13 segment in redirecter
	pop	bx

coninit:

; continue mosinit in old segment (rest of mos is relocated)

; when mos is moved down low and cs is also down low, update dd4013
; so device drivers see the full memory if they do an int12
; (done primarily to support sysloading periscope).
    
	push	ax
	int	12h
	mov	[dd4013],ax
	pop	ax

; get seg that mos moved to continue at 'initp5r' in old seg

	mov	ax,cs
	retf
initp5r:
	callinit intvrst		; reset int vectors to seg in ax

; mosinit now executing in high (system) memory with ds and ss
; pointing into relocated mos in low memory.  this allows us to
; overlay the mosinit code with the disk buffers and heap.

	lea	bx,clobber+15
	shr	bx,1
	shr	bx,1
	shr	bx,1
	shr	bx,1
	add	ax,bx			; calc mosinit seg in low memory
	mov	[scbfree],ax		; set in this seg
	call	updfree
initp5a:

; process chain of device drivers (set new segment values)

	mov	bx,[mosaddr]		; get new location of mos
	mov	ax,cs			; get current location of mos
	push	ds
	pop	es			; start load from scb driver list pointer
	lea	si,[scbdrvr]		; "     "	"       "
drvlstlp:
	cmp	word ptr es:[si+2],-1	; is this the last one?
	je	initp5e 		; yes
	cmp	word ptr es:[si+2],ax	; is this pointer to be relocated?
	jne	nolstchg		; no, no change to this pointer
	mov	es:[si+2],bx		; set pointer to new mos segment
nolstchg:
	les	si,dword ptr es:[si]	; point to next driver
	jmp	drvlstlp		; process entire driver list
initp5e:
	ret
initp5	endp

	subttl relojoin - relocate grp+mo2 and mos together
	page
;======================================================================
;,fs
; relojoin - relocate grp+mo2 and mos together
;
; relocates grp+mo2 segment and mos segment in one contigious space
; calls relogrp to relocate grp and mo2 segment
; calculates where mos segment should be from grp
; calls relomos to relocate mos and jump into that segment
;
; in:	ds -> grp
;	es -> new segment for mos
;
; out:	
;
;,fe
;=====================================================================
	assume	ds:grp,es:nothing,ss:nothing
relojoin proc	near
	push	ax
	push	bx
	push	es			; save new mos location

;  calculate where new grp should be

	mov	bx,[scbmo2end]		; end of mo2seg
	mov	ax,ds			; start of grp
	sub	bx,ax			; calculate difference
	mov	ax,es			; new cs
	sub	ax,bx			; subtract difference
	mov	es,ax			; should be new grp

; relocated grp and mo2 segments

	call	relogrp 		; relocate the grp and mo2 segments first
	test	[dmflags],08h		; are we in initp5
	jz	rj2
	pop	ax
	sub	ax,108h 		; adjust by 1080h bytes
	mov	[mosaddr],ax		; update mosaddr for new cs
	push	ax
rj2:
	pop	es			; get new mos location

; relocate mos segment

	call	relomos 		; relocate the mos segment and jump
	pop	bx			; into newly created segment
	pop	ax
	ret
relojoin endp

	subttl relogrp - relocate grp and mo2 segments
	page
;======================================================================
;,fs
; relogrp - relocate grp and mo2 segments
;
; relocates the grp and mo2 segment and data referring to these segments
; will be alter for the new segment. mos segment is not relocated during
; this call because it is now possiable that grp and mo2 segments be
; seperated from mos segment.
;
; in:	ds -> grp
;	es = new segment location of grp
;	ss -> tcb stack
;
; out:	ds -> points to new grp segment (via mgetscb)
;
;,fe
;=====================================================================
	assume	ds:grp,es:nothing,ss:tcb
relogrp proc	near
	push	ax
	push	cx
	push	si
	push	di
	mov	si,es
	mov	di,ds
	sub	si,di			; calc distance of move
	mov	ax,[mo2seg]		; get current mo2 pointer
	cli				; for the duration of the move
	add	[mo2seg],si		; adjust data segment pointer
	push	ds
	mov	ds,ax			; get segment of mos 2nd code (before reloc)
	assume	ds:mo2
	add	cs:[grpseg1],si
	add	ds:[grpseg2],si
	mov	ds,cs:[sbios]		; adjust scbseg at 40:03fah
	add	ds:[03fah],si
	mov	ds,cs:[sinit]		; point to init segment
	assume	ds:init
	add	ds:[initgrp],si 	; adjust grp pointer in init
	add	ds:[initmo2],si 	; adjust mo2 pointer in init
	pop	ds
	assume	ds:grp
	add	[scbtcbpc],si		; "     TCB pointers
	add	[scbtcbpf],si
	add	[scbpripf],si
	add	[scbtcbpl],si
	add	[scbtcbpv],si
	add	[scbmo2end],si
	add	word ptr [tcbcondd+2],si
	add	[tcbscrdd],si
	add	word ptr [tcbkeyrdy+2],si
	test	[dmflags],10h		; special version of driver
	jnz	mmspec1
	cmp	[scbmmfg],'Y'		; if no mm loaded then just
	jne	nommsetting		; skip actaul seting of vector
mmspec1:
	test	[scbmmfea],04h		; using actual vector table?
	jz	nommsetting
	mov	ax,ds
	callinit set_actual		; update modified vectors
nommsetting:
	cmp	[tcbpsp],0		; on 1st call this will not be inited
	je	skprlpsp
	push	es
	mov	es,[tcbpsp]
	assume	es:pspseg
	add	word ptr [psppntr+2],si ; set segment of psp handle pointer
	pop	es
	add	[tcbpsp],si		; "     master PSP pointer
skprlpsp:
	push	si			; save adjustment (for lack of a better name)

; move stack and scb data area

	push	es
	mgetscb es
	mov	cx,offset grp:gend+15	; round up move to include next seg
	sub	cx,100h 		; grp starts at offset 100h
	shr	cx,1			; calc word count
	cld
	mov	si,100h 		; ds already addresses current scb data
	mov	di,si
	rep	movsw			; move scb data and stack
	assume	ds:nothing, es:nothing
	pop	di			; saved es
	pop	si

; but first move the stack segment - since ss at init is in grp

	mov	di,ss
	add	di,si			; make the stack adjustment
	mov	ss,di

; now move the mo2 segment (later we will seperated this too)

	mov	es,[mo2seg]		; new location for mo2 group
	mov	di,es			; compute old location to ds
	sub	di,si
	mov	ds,di
	mov	cx,offset mo2:mo2end+15 ; size of move will be size of mo2
	shr	cx,1			; # words
	xor	si,si
	xor	di,di
	rep	movsw

; make ds new grp segment always (calling routines depend on this)

	mgetscb ds
	sti
	pop	di
	pop	si
	pop	cx
	pop	ax
	ret				; back to caller (now in new segment)
relogrp endp

	subttl relomos - relocate mos
	page
;======================================================================
;,fs
; relomos - relocate mos
;
; relocate mos to specified segment and resume its execution in the new
; location.  the segment registers and the mos variables 'mo2seg',
; 'scbtcbxx' and 'scbfree' will be adjusted up or down by the same
; amount as the mos code.  since the stack is located in the fg tcb it
; will be moved as well.
;
; the segment registers ds and ss are adjusted the amount of the
; move (e.g. if mos is moved from 2000h to 3000h each segment
; register will be incremented by 1000h). no other registers
; changed, mos is simply residing in a new location.
; the variables scbseg, scbfree and scbtcbxx will be updated.
;
; in:	cs -> mos
;	ds -> grp
;	es = new segment location for mos segment
;
; out:	cs, ss and ds segment registers adjusted to reflect move
;	scbseg, scbfree, scbtcbxx updated
;
;,fe
;=====================================================================
	assume	ds:grp,es:nothing,ss:nothing
relomos proc	near
	push	ax
	push	cx
	push	si
	push	di
	push	ds
	mov	si,es
	mov	di,cs
	sub	si,di			; calc distance of move
	mov	ax,[mo2seg]		; get current mo2 pointer
	cli				; for the duration of the move
	push	ds
	mov	ds,ax			; get segment of mos 2nd code (before reloc)
	assume	ds:mo2
	add	[mo1seg],si		; adjust mos 2nd code seg pointer to mos
	pop	ds
	assume	ds:grp

; if in initp5 don't adjust MOS segment pointer to INIT code

	test	[dmflags],08h
	jnz	relonin1
	push	ds
	mov	ds,[sinit]
	assume	ds:init
	add	[initmos],si		; adjust mos seg point in init segment
	pop	ds
	assume	ds:grp
	add	[sinit],si
relonin1:
	add	[scbmosadr],si
	add	word ptr [scbscang+2],si
	add	word ptr [scbmapvmf+2],si
	add	word ptr [scbmapvsf+2],si
	add	word ptr [scbirqbnk+2],si
	test	[dmflags],10h		; special version of memman
	jnz	mmcase
	cmp	[scbmmfg],'Y'		; if no mm loaded then just
	je	mmcase			; update pointer to retf
	add	word ptr [scbmmsub+2],si; (otherwise, mm driver doesn't move)
	jmp	nonmmcase
mmcase:
	test	[scbmmfea],04h		; using actual vector table?
	jz	nonmmcase
	mov	ax,ds
	callinit set_actual		; update modified vectors
nonmmcase:
	push	si			; save adjustment (for lack of a better name)

; move mos code area

	xor	si,si
	xor	di,di
	push	cs
	pop	ds
	assume	ds:mos
	cmp	[tonewcs],'Y'
	jne	relonin2
	mov	cx,offset mos:mosend+15 ; size of move will be size of mos

; if inside initp5 don't addjust for INIT

	test	[dmflags],08h
	jnz	reloncs
	add	cx,offset init:initend+15  ; including init segment
	jnc	reloncs

; the following code corrects a condition where the size of mosseg
; + the size of init segment is greater than 64k bytes thus causing
; cx to be incorrect and causing mos to crash at init time

	shr	cx,1
	push	ds
	push	es
	push	cx
	mov	cx,8000h		; move the first 64k of memory into
	rep	movsw			; to new area
	mov	cx,ds
	add	cx,1000h		; adjust segment pointers so to point
	mov	ds,cx			; the memory start + 64k
	mov	cx,es
	add	cx,1000h
	mov	es,cx
	pop	cx
	rep	movsw			; now move the remaining data
	pop	es
	pop	ds
	jmp	short rmmove		; continue on with init code
relonin2:
	mov	cx,offset mos:clobber+15
reloncs:
	test	[dmflags],08h		; inside initp5
	jz	rmno5
	mov	si,1080h		; adjust for highmem allocations
	mov	di,si
	sub	cx,si
rmno5:
	shr	cx,1			; # of words
	rep	movsw
rmmove:
	pop	si			; adjustment back (still can't think of one)
	cmp	[tonewcs],'Y'		; check if cs to be changed
	jne	reent
	push	es			; new cs
	lea	di,reent
	push	di			; new ip
reentrf label	near
	retf				; enter new segment
reent:					; reentry point
	assume	ds:nothing
	mgetscb ds
	assume	ds:grp
	sti

; output debugging info

if	mdebug eq 1

	test	[scbdebug],1		; init status?
	jz	relondb 		; no debug info
	call	clearsm
	push	ax
	push	ds
	push	dx
	push	cs
	pop	ds
	assume	ds:mos
	mov	ax,es
	lea	dx,msgrlo1
	call	hex2asc
	mov	ax,[mo2seg]
	lea	dx,msgrlo1a
	call	hex2asc 		; translate 'MO2' segment
	push	ds
	mgetscb ds
	mov	ax,ds
	pop	ds
	lea	dx,msgrlo2
	call	hex2asc 		; translate 'grp' address
	lea	dx,msgrlo
	xor	al,al			; no frill display
	call	mosdebug
endif

relondb:
	pop	ds
	pop	di
	pop	si
	pop	cx
	pop	ax
	ret				; back to caller (now in new segment)
relomos endp

	subttl initp7 - init 'REAL' heap
	page
;======================================================================
;,fs
; initp7 - init 'REAL' heap
;
; allocate the heap according to the size given by heapsize.  the
; temporary heap is discarded.
;
; in:	ds -> grp
;	ax = segment address to start heap after mos
;
; out:	ax = next free memory segment
;
;,fe
;=====================================================================
	assume	ds:grp,es:nothing,ss:nothing
	public	initp7
initp7	proc	near

if	code286
	or	al,3
endif

	mov	es,ax			; default start at end of disk buffers
	assume	es:nothing
	mov	[scbhpadr],ax		; set heap address
	mov	dx,[scbhpsiz]		; get size of heap
	add	ax,dx
	push	ax			; save next free seg for exit
	mov	ah,0ffh 		; init heap at seg es of size dx para's
	call	mosheman		; do it to it!

if	mdebug eq 1

	test	[scbdebug],1		; init debug stuff on?
	jz	no7db			; no, skip it
	mov	ax,[scbhpadr]		; get heap address
	pop	bx			; get ending address
	push	bx			; save for exit
	call	clearsm
	push	ax
	push	ds
	push	cs
	pop	ds			; address messages
	assume	ds:mos
	push	dx			; save for mosdebug
	lea	dx,dbdata3		; data space for address
	call	hex2asc 		; translate ax value to ascii at ds:si
	lea	dx,dbdata4
	mov	ax,bx
	call	hex2asc 		; ending address
	lea	dx,dbmsg2		; debug message for disk buffers
	xor	al,al			; no frills display
	call	mosdebug		; note: this clears ds and dx from stack
	assume	ds:grp
endif

no7db:
	pop	ax			; get next free seg value for exit
	ret
initp7	endp


;-----------------------------------------------------------------------
; error routines
;-----------------------------------------------------------------------

; heap error processing device driver

	public	hperr			; use in mosinit2
hperr:
	call	bugerror
	db	'4. '
	db	'System Memory Pool depleted               ',13,10  ;@@xlat
	db	'Need larger SMPSIZE= in CONFIG.SYS           ',0  ;@@xlat

	public	smperr			; use in mosinit2
smperr:
	call	bugerror
	db	'SMP corruption during device driver loading       ',0	; mjs 3/7/88 ;@@xlat

	public drverr
drverr:
	add	mos:[drverno],al	; set error number in message
	call	bugerror
	db	'3  '
	db	' Error during init or open of standard drivers - error type      '  ;@@xlat
drverno db	'0',0

	public	minterr
minterr:
	lea	dx,inteno		; put vector number in message
	call	hex2asc
	call	bugerror
	db	'3 MEMDEV interrupt #'	;@@xlat
inteno	db	'xxxx conflict' 	;@@xlat


	subttl dispmos - display startup message
	page
;======================================================================
;,fs
; dispmos - display startup message
;
; in:	
;
; out:	
;
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:nothing
public	dispmos
dispmos proc near
	call	clearsm 		; clear startup message
	mov	ah,9
	callmos
	ret
dispmos endp

	subttl clearsm - clear the startup message
	page
;======================================================================
;,fs
; clearsm - clear the startup message
;
; in:	
;
; out:	
;
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:nothing
public	clearsm
clearsm proc near

if	0 eq 1				; don't clear the screen

	cmp	cs:[smthere],'Y'	; is startup msg on screen?
	jne	csmret			; no, exit
	mov	cs:[smthere],'N'
	push	ax
	push	bx
	push	cx
	push	dx
	mov	ah,6			; scroll window
	mov	al,0			; blank entire window
	xor	cx,cx			; upper left
	mov	dx,184fh		; lower right
	mov	bh,7			; normal attr
	int	10h			; clear screen
	mov	ah,2			; set cursor position
	xor	dx,dx			; home
	xor	bh,bh			; page 0
	int	10h
	pop	dx
	pop	cx
	pop	bx
	pop	ax
csmret:
endif
	ret
clearsm endp

; the following are a qroup of far calls which can call from init segment
; to call routines in the mos segment via far calls from macro cfmos

	assume	ds:nothing,es:nothing,ss:nothing
cainit	proc	near
	push	ax
	push	ds
	mov	ds,cs:[sinit]
	assume	ds:init
	mov	ax,cs:[sinitaddr]
	mov	[imosaddr],ax
	pop	ds
	pop	ax
	call	dword ptr cs:[initcall]
	ret
cainit	endp

public	moscall
moscall proc	far
	call	cs:[sinitaddr]
	ret
moscall endp

	public	ifar21
ifar21	proc	near
	callmos
	ret
ifar21	endp

mosinit endp
mosseg	ends

;======================================================== init segment
if 0 eq 0
segment_num = 3
endif
initseg	segment
	assume	cs:init,ds:nothing,es:nothing,ss:nothing
	extrn	initend:byte, imosaddr:word, dispsmp:near
	extrn	initmos:word, initmo2:word, initgrp:word, initpc:near
	extrn	initp2:near, opendev:near, initpa:near, initpb:near
	extrn	set_actual:near, intvrst:near, finddm:near
initseg ends

	end

