IF I386+CHARGE+GIZMO
	.286c
ENDIF

comment ^============================================================

$$memdev driver for the at gizmo, charge or all card
copyright 1985, 1986, 1987 the software link, incorporated

note: emulex version accomodates the fact that this hard disk
uses dma and requires a full 64k staging buffer. also beware
that it requires a hardware interrupt line (irq5 recommended).

ps/2 also requires hard disk dma staging.

====================================================================

rbr 05/06/87	added parmiop, for efficiency.

rbr 05/06/87	stage format operations to disk drives using dma.

rbr 05/07/87	always stage format and verify operations,
		regardless of buffer addresses. this was done
		because the pc/xt bios can generate dma overrun
		errors without just cause.

rbr 06/13/87	made 1st 2k read-only.  fixed garbage in idt
		added support for all's Charge Card; fixed crash
		on irq8-irqf while running in native mode.

rbr 06/28/87	added doinaxd, dooutaxd to handle in/out on ax
		increased iopbm for i/o addresses up to 37ff
		these were needed for the ps/2 model 80.
		also added /p, /x, /e options for ps/2, xt, and
		emulex hard disks, respectively.

rbr 06/30/87	implement request handler function 0 to reboot.
		relocate data area used by esdi fixed disk bios.

rbr 07/05/87	revised testing for extended memory to avoid
		crashing the wyse 386 (which seems to not like
		16-bit reads/writes to nonexistent ram).

rbr 07/19/87	modifications to support int 38h. also changed
		int 38h function 11h (allocate) to return an
		error condition if there is not enough memory.

rbr 07/27/87	fix mmadrtab value for charge card.

sah 08/06/87	added conditional assembly of code which allows
		tracing of memory managements request header
		this code is include by making rhtrace true

rbr 08/08/87	added logic to preserve the original "et" bit in
		cr0, so that the 80387, if present, will be
		correctly supported.

sah 08/19/87	after testing for memory, made sure that memory
		was zero-out. this was a problem with turbo-c
		because it assume that the memory was clear. yes
		it is hard to believe but it is true.

rbr 08/21/87	corrections for new all card.

rbr 09/10/87	fix "alias" function (int 38h function 13h)

rbr 09/14/87	establish idt entry for all interrupts.

sah 09/30/87	allow for /t option with /p, /x or /e options
		this requires that /t be before /p....

sah/jrb 11/12/87 allow for port outs and in to return to mos
		int 06 handler, mos never got it because 386
		driver iret back to where it ok its exception

mjs 11/16/87	added new feature bit (10h) to control type of
		context switching done because of a
		conflict with ps/2's and I/O addressing

rbr 01/17/88	added "/maaaa,nnnn" option to declare a disjoint
		section of pre-initialized extended memory  ; this
		is used if you need to be able to boot up without
		trashing data saved on a nonvolatile ramdisk in
		extended memory.

rbr 01/17/88	memdev driver load address changed from 00800
		to 00700.  this is because $286.sys needs to be
		loaded there, and we want to be consistent.
		modified mosinit is now requried.

sah 01/22/88	check if cpu is 386 for 386 version of driver

rbr 03/07/88	don't croak on HLT.  Some BIOSes use it.

rbr 03/13/88	corrections to hlt stuff; dma fix.

rbr 04/22/88	minor addition to support the all chargecard ii.

rbr 06/21/88	added ivtable and supporting logic for $386.sys.

rbr 06/30/88	added parmpfa as a scratch area pointer for mos.

sah 07/12/88	added upper 60k support bit

rbr 07/13/88	added help for maxspeed driver in phymap

rbr 07/25/88	added ivtable support for chargecard & gizmo

rbr 07/28/88	modify usage of 386 page table for upper 60k use

rbr 08/03/88	added /i and /c options ; removed /m option; also
		do automatic /c if no extended memory.

sah 08/21/88	turn off nmi during 386 memory check

rbr 09/21/88	fix quattro putting itself into native mode.

sah 10/26/88	fix lockups if machines don't have extended memory
		for the non-386 machines.

sah 11/01/88	correction to 08/21/88 fix for non-386's

sah 11/01/88	added /m option for 32k dma buffer

rbr 12/02/88	preserve es during non-386 physical remaps.

rbr 12/12/88	fix native mode memory management to account for
		new relationship between "handle" and address
		also fixed ivtable usage in native mode apps.

mjs 12/29/88	added pushf/cli...popf protection to the phymap proc
		for the gizmo and allcard.  not having this in the gizmo
		case was causing a crash with maxspeed.  in the allcard
		case, i just noticed this protection was missing.

sah 02/02/89	made hex-dec conversion use 5 digits and move messages
		to end of source. this is needed for machine with more
		than 15meg.

mjs 03/21/89	added list base mapping call and a block move call
		which takes advantage of the 386's 32 bit move string
		capability.  access to this block move routine will be
		made through a far pointer int the scb.
 ***** note:	any changes made to the vremap, vunmap or vphymap
		routines should be echoed into the appropriate sections
		of the vlistmap procedure as well.
		added calls to allow the 386's debug registers to be
		read and written.

mjs 06/06/89	modified response to int38 calls for native mode
		services to also responsd to intd4.  all points are
		tagged with the string "extsv".
		added /s option to gizmo and charge drivers to force
		the context remapping feature bit on.  this should allow
		some irq handling improvements on non-ps2 286 machines.

sah 06/21/89	added code into 386.sys int 13 routine to disable io
		protection to timer ports 40,42, and 43 when original
		bios is being called.  this was causing our disk io to
		be about 3 times slower than with this fix on writes

mjs 06/29/89	modify vreboot to make a warm boot by default

rbr 07/13/89	support upper-60k for gizmo & chargecard

rbr 07/17/89	oops, make that just chargecard - gizmo wraps at 1mb

sah 09/08/89	corrections for compaq 386s, allocated esdi buffer if
		needed before dma buffer.

mjs 09/12/89	corrected an instruction within makegdte.  this was
		causing data to be corrupted when an app used int38
		function 1001 to switch to native mode.
		the instruction: and cx,0ffffh	dw 00ffh  was used with
		the intention of producing:  and ecx,00ffffffh.
		when masm saw the and cx,0ffffh, it produced 83 e1 ff
		which is for a sign extended operand.  this left the
		dw 00ffh sitting in the code as whatever instruction
		that happens to be.  fixed by explicitly encoding:
		db 81h,0e1h  dw 0ffffh,00ffh..

bwr 11/30/89	marked messages for foreign language translation.

mjs 02/01/90	reworked the 386 initialization logic to build the
		page directory and page table within extended memory.
		established two use16 and two use32 segments to make
		it possible to use 386 mnemonics.
		reworked all logic which needed to access the page
		table to run in native mode.

SAH 02/28/90	Corrections for IBM Model 70 486, made sure that IRQ 1
		is mask out during INIT, It appears that Model 70 486
		Keyboard control is sensitive to turning Address 20 line
		On so that we can access above 1 meg.

mjs 03/27/90	removed sah's modification for timer port trapping
		(06/21/89).   due to the recursion of int13's caused
		by mosint13, this logic wasn't actually effective.  when
		a recursive call occured the timer trapping bits would
		get cleared and stay that way.	implemented a new version
		of this logic within mosint13

SAH 04/09/90	Corrections to oversight of MJS 02/01/90 Modications with
		code logic to copy ESDI bios area into low memory. This
		cause Charge.sys driver to lock up because its init code
		was being rewritten with ESDI Bios data

SAH 04/30/90	Removing setting value at 80c00000, now handle by
		MOSINIT2 via INT 15 call so it will work 386sx machines

mjs 05/04/90	corrected native mode initialization where the int2 vector
		is saved, changed and restored.  a mistake here was
		preventing the new 386 memdev from running with the
		intel inboard on a pc.

mjs 06/18/90	changed function number of the list based remapping
		call from 0a to 0d.  this is to prevent a conflict
		with function 0a, 0b and 0c within 286.sys.

mjs 06/25/90	corrected problems with list based remapping call.

mjs 12/11/90	corrected problem with $386.sys on 20 mhz compaqs with
		series 1 maxspeed boards.

mjs 12/13/90	converted dma staging logic to use a smaller buffer and
		break up the read or write so it will fit in the buffer.
		added the /d=nn parameter to allow buffer sizing.  can
		still use /p, /m, /e, etc. 

		added logic to support a native mode nmi handler.  this
		was done for display automation.

mjs 01/03/91	added api function 10h to support the restoration of
		the previous nmi handler.  display automation needs
		this so they can abort the loading of their driver
		when they detect equipment problems.

mjs 01/07/91	added version number and release date to boot messages

mjs 03/19/91	added api function 11h, netbios block copy.
		also, changed gdtzero to g=1 (granularity bit = 1).

mjs 04/22/91	added cs: overrides so the charge, gizmo and all versions
		would assemble.
		added vblkcpy support to the charge and gizmo drivers.

mjs 06/05/91	modified the code that determines when a disk operation
		should be staged.  instead of checking only the starting
		page of the buffer, must check the ending page.  
		otherwise, buffers which include the 640k boundary
		can cause problems in the foreground when the 'f'
		option of vtype is used.

SAH 06/05/91	Added /L option to disable checking of memory at upper 15 Meg
		for Compaq machines. This was causing a lock up on Club Hawk
		386.

mjs 07/01/91	version 4.14, reset idt after loadall.  was causing
		llpro to lock up on 286 machines.

SAH 01/02/92	Remove 386 driver from this source
=======================================================================^

include xifmacs.inc


; use these guys to simplify register saving and restoring

pushset macro	p1,p2,p3,p4,p5,p6,p7,p8,p9,p10,p11,p12,p13,p14
	irp	@@push,<p1,p2,p3,p4,p5,p6,p7,p8,p9,p10,p11,p12,p13,p14>
	ifnb	<@@push>
	push	@@push
	endif
	endm
	endm

; couldn't get irp to work for this one

popset	macro	p1,p2,p3,p4,p5,p6,p7,p8,p9,p10,p11,p12,p13,p14
	ifnb	<p14>
	pop	p14
	endif
	ifnb	<p13>
	pop	p13
	endif
	ifnb	<p12>
	pop	p12
	endif
	ifnb	<p11>
	pop	p11
	endif
	ifnb	<p10>
	pop	p10
	endif
	ifnb	<p9>
	pop	p9
	endif
	ifnb	<p8>
	pop	p8
	endif
	ifnb	<p7>
	pop	p7
	endif
	ifnb	<p6>
	pop	p6
	endif
	ifnb	<p5>
	pop	p5
	endif
	ifnb	<p4>
	pop	p4
	endif
	ifnb	<p3>
	pop	p3
	endif
	ifnb	<p2>
	pop	p2
	endif
	ifnb	<p1>
	pop	p1
	endif
	endm


; other assembly-time options

rhtrace equ	false			; if request header tracing
trace	equ	false			; if int1 trace code is to be included

; mos-dependent equates

scbtcbpc equ   19			; scb offset to current tcb address
tcbid	equ   16			; tcb offset to task id
tcbncadr equ   18			; tcb offset to nca address

IF ALLCARD

	page
mmuseg	segment at 0ef00h
mmueab	db    ? 			; bit 0 of alternate and current map numbers

	org   0400h

;			input			 output
mmureg0  db    ?  ; reason for nmi	    enable nmi; sys vs user mode
mmureg1  db    ?  ; nmi/user/mmu indicate   enable mmu; set # maps
mmureg2  db    ?  ; bits 1-4 of alt map #   bits 1-4 of alt map #
mmureg3  db    ?  ; bits 1-4 of cur map #   bits 1-4 of cur map #
mmureg4  db    ?  ; which page caused nmi   which events to cause nmi
mmureg5  db    ?  ; unused		    select if cur or alt map
mmureg6  db    ?  ; clear halt interrupt    unused
mmureg7  db    ?  ; clear nmi interrupt     interrupt vector modifier

	org   0800h

mmupar	db    256 dup(?)		; page address registers
	org   0c00h
mmupdr	db    256 dup(?)		; page descriptor registers
mmuseg	ends

ENDIF

	page
;--------------------------------------------------------------------
;			  main segment
;--------------------------------------------------------------------

mmgrp	group	res16,res32,init16,init32


;======================== 16 bit resident code =========================

res16  segment para public 'CODE'
	assume cs:mmgrp,ds:mmgrp

begin label near

	public mmbeg
mmbeg:

; device header

devheadr:
	 dd    -1			; pointer to next driver
	 dw	8000h			; attribute: indicate character device
stratvec dw    strategy 		; ptr to strategy routine
intervec dw    interupt 		; ptr to interrupt routine
devname  db    '$$MEMDEV'		; device name
endhead:

; transfer to relocated driver

tostrat db	0eah			; far jump opcode
	dw	strategy,0
tointer db	0eah
	dw	interupt,0
relomin equ	$-begin 		; minimum relocation in bytes

; miscellaneous constants

foption db	0			; flag for /f option
zero	 dw    0
wordten  dw    10

	page
;--------------------------------------------------------------------
;		      device function vectors
;--------------------------------------------------------------------
	even
funtab	label word
	dw	mmgrp:init
	dw	mediachk
	dw	buildbpb
	dw	ioctlin
	dw	input
	dw	ndinput
	dw	instatus
	dw	inflush
	dw	output
	dw	outputv
	dw	oustatus
	dw	ouflush
	dw	ioctlout

	org	 0100h			; skip to location 00800

IF GIZMO+CHARGE

;==== loadall data area at 00800 - initially for real mode

lastart	label	byte
	db	6 dup(0)	; unused
lamsw	dw	0fff0h		; Machine Status Word
	db	14 dup(0)	; unused
latr	dw	0		; Task Register 
laflags	dw	0002h		; Flags Register
laip	dw	0		; Instruction Pointer
laldt	dw	0		; ldt Selector
lads	dw	0		; ds Selector
lass	dw	0		; ss Selector
lacs	dw	0		; cs Selector
laes	dw	0		; es Selector
ladi	dw	0		; di
lasi	dw	0		; si
labp	dw	0		; bp
lasp	dw	0		; sp
labx	dw	0		; bx
ladx	dw	0		; dx
lacx	dw	0		; cx
laax	dw	0		; ax

laesdc	db	3 dup(0)	; es base address
	db	11110010b	;  p=1,dpl=11,1,e=0,d=0,w=1,a=0
	dw	0ffffh		;  limit
lacsdc	db	3 dup(0)	; cs base address
	db	10010010b	;  p=1,dpl=00,1,e=0,d=0,w=1,a=0
	dw	0ffffh		;  limit
lassdc	db	3 dup(0)	; ss base address
	db	10010010b	;  p=1,dpl=00,1,e=0,d=0,w=1,a=0
	dw	0ffffh		;  limit
ladsdc	db	3 dup(0)	; ds base address
	db	11110010b	;  p=1,dpl=11,1,e=0,d=0,w=1,a=0
	dw	0ffffh		;  limit

lagdtr	dw	0		; gdtr base 
	db	0,0
      	dw	0		; limit
laldtdc dw	0		; ldt base address
	db	0		;  64k beyond gdt
	db	00000010b	;  p=0,dpl=00,0,type=ldt
	dw	0		;  limit
laidtr	dw	0		; idtr base 
	db	0,0
      	dw	256*4-1		; limit
latssdc	dw	0		; tss base address
	db	0
	db	00000001b	;  p=0,dpl=00,0,type=avtss
	dw	0		;  limit

lalen	equ	$-lastart


ENDIF


;======================================================================
;,fs
; strategy
;
; in:	es:bx -> request header
;
; out:	none
;
;,fe
;=====================================================================
strategy:
	mov	cs:[rhseg],es
	mov	cs:[rhoff],bx
	retf

;======================================================================
;,fs
; interupt
;
; in:	request header pointer in [rhseg]:[rhoff]
;
; out:	request header updated
;
;,fe
;=====================================================================
interupt:
	push	bp
	push	es
	push	ds
	push	di
	push	si
	push	dx
	push	cx
	push	bx
	push	ax
	push	cs			; init ds register
	pop	ds
	les	bx,dword ptr [rhoff]	; load rh pointer
	mov	al,es:[bx+2]		; get command code byte
	mov	ah,0
	shl	ax,1
	mov	di,ax
	jmp	[di+funtab]
donestat:
	les	bx,dword ptr [rhoff]
	or	word ptr es:[bx+03],0100h  ; "done" status
exit:
	clc
	pop	ax
	pop	bx
	pop	cx
	pop	dx
	pop	si
	pop	di
	pop	ds
	pop	es
	pop	bp
	retf
ddabort:
	mov	word ptr [devname],'\\'
	les	bx,dword ptr [rhoff]
	mov	word ptr es:[bx+14],offset mmgrp:endhead
	mov	word ptr es:[bx+16],cs
	or	word ptr es:[bx+3],8001h; error unknow unit
	jmp	exit

	page
;--------------------------------------------------------------------
;			device functions
;--------------------------------------------------------------------
input:
	les	bx,dword ptr es:[bx+14] ; address the buffer
	mov	word ptr es:[bx],offset mmgrp:parms
	mov	es:[bx+2],cs
	les	bx,dword ptr [rhoff]
	mov	word ptr es:[bx+18],4	; 4 bytes transferred
	jmp	donestat
output:
outputv:
ioctlin:
ioctlout:
	mov	word ptr es:[bx+18],0	; no data transferred
ndinput:
instatus:
inflush:
oustatus:
ouflush:
mediachk:
buildbpb:
	or	word ptr es:[bx+03],8102h  ; indicate device not ready
	jmp	donestat

	page

;==== int 13 vector table

	even
int13tab label word
	dw	i13pass 	; 00  reset disk
	dw	i13pass 	; 01  get status
	dw	i13nread	; 02  read sectors
	dw	i13nwrit	; 03  write sectors
	dw	i13verfy	; 04  verify sectors
	dw	i13fmt		; 05  format track
	dw	i13fmt		; 06  format track with bad sector flags
	dw	i13pass 	; 07  format drive
	dw	i13pass 	; 08  get drive parameters
	dw	i13pass 	; 09  init drive pair characteristics
	dw	i13lread	; 0a  read long  (516 bytes per sector)
	dw	i13lwrit	; 0b  write long (516 bytes per sector)
	dw	i13pass 	; 0c  seek
	dw	i13pass 	; 0d  alternate disk reset
	dw	i13sread	; 0e  read sector buffer  (only 1 sector)
	dw	i13swrit	; 0f  write sector buffer (only 1 sector)
	dw	i13pass 	; 10  test drive ready
	dw	i13pass 	; 11  recalibrate
	dw	i13pass 	; 12  controller ram diagnostic
	dw	i13pass 	; 13  drive diagnostic
	dw	i13pass 	; 14  controller internal diagnostic
	dw	i13pass 	; 15  read dasd type
	dw	i13pass 	; 16  get change line status
	dw	i13pass 	; 17  set dasd type for format
	dw	i13pass 	; 18  reset disk    \
	dw	i13pass 	; 19  get status     \	emulex hard disk
	dw	i13nread	; 1a  read sectors   /
	dw	i13nwrit	; 1b  write sectors /


	subttl entinr13 - int13 intercept entry for dma staging
	page
;======================================================================
;,fs
; entinr13 - int13 intercept entry for dma staging
;
; this logic is always used for floppy disks.  it is used for hard
; disks when certain switch options are specified.
;
; in:	int13 entry registers
;
; out:	int13 exit registers
;
;,fe
;=====================================================================
entinr13:
	sti
	pushf
	cmp	dl,80h			; ***** exit if dma not used *****
dmajump label word			; this is nop'ed out if hard disk uses dma
	jae	fastex13
	cmp	ah,1bh			; boundary check
	ja	fastex13
	mov	cs:[usercx],cx
	mov	cs:[userdx],dx
	cmp	ah,6			; formats are very dma boundary sensitive
	ja	i13not46
	cmp	ah,4			; stupidly enough, so are verifies!
	jae	stage
i13not46:
	mov	dx,bx			; compute starting seg address
	mov	cl,4
	shr	dx,cl
	mov	cx,es
	add	dx,cx


; for function 2 and 3, form sectors to be written in ax
; (ax << 9) would convert sectors into total bytes
; (ax >> 4) would convert total bytes into paragraphs
; therefore, using (ax << 5) which will produce the same results unless
; the entry al value was > 7f.
; adding the number of paragraphs for the write to the current value in
; dx.  the current dx value comes from  ((ofs>>4) + segment)
; this should produce a number which represents the highest end of the 
; memory involved in the transfer.

	cmp	ah,2
	je	i13xx1
	cmp	ah,3
	jne	i13xx2
i13xx1:
	push	ax
	xor	ah,ah
	mov	cx,5
	shl	ax,cl
	add	dx,ax
	pop	ax
i13xx2:


	cmp	dh,cs:[dmabank] 	; below switched partitions?
	jae	stage			; no, go do staging
	mov	cx,cs:[usercx]		; yes, resume normally
	mov	dx,cs:[userdx]
fastex13:
	popf
	call	call13
	jmp	farret13
stage:
	pop	cs:[userflag]
	push	di
	push	si
	push	ds
	mov	si,cs
	mov	ds,si
	mov	[userax],ax
	mov	[origcmd],ah
	mov	[userbx],bx
	mov	[useres],es
	xor	bh,bh
	mov	bl,ah
	shl	bx,1
	jmp	word ptr [int13tab+bx]

i13pass:
	mov	ax,[userax]
	mov	bx,[userbx]
	mov	cx,[usercx]
	mov	dx,[userdx]
	mov	es,[useres]
	push	[userflag]
	popf
	pop	ds
	pop	si
	pop	di
	jmp	dword ptr cs:[oldint13]


	subttl advance_sect - calc new cyl, head, sect for +sect
	page
;======================================================================
;,fs
; advance_sect - calc new cyl, head, sect for +sect
;
; accepts cylinder, head and sector information in int13 call format
; and derives the new cylinder, head and sector values for advancing
; a certain number of sectors.
; 
;             ÚÄ 			             Ä¿
;  	      ³  q1/r1 = (cur_sect + add_sect) / spt  ³ 
; cur_cyl  -> ³  ÚÄ if(r1 == 0)		              ³ -> new_cyl
; cur_head -> ³  ³ r1 = spt			      ³ -> new_head
; cur_sect -> ³  ³ q1--			              ³ -> new_sect
; add_sect -> ³  ÀÄ 				      ³ 
; heads	   -> ³  cur_sect = r1			      ³ 
; spt	   -> ³  q2/r2 = (cur_head + q1) / heads      ³ 
; 	      ³  cur_head = r2			      ³ 
; 	      ³  cur_cyl += q2			      ³ 
; 	      ÀÄ				     ÄÙ
; 
; in:	al = # of sectors to advance (add_sect)
;	ch = cylinder # (high 2 bits in cl) (cur_cyl)
;	cl = sector # (plus high bits of cylinder #) (cur_sect)
;	dh = head # (cur_head)
;	bh = total # of heads (heads)
;	bl = sectors per track (spt)
;
; out:	ch = cylinder # (high 2 bits in cl) (new_cyl)
;	cl = sector # (plus high bits of cylinder #) (new_sect)
;	dh = head # (new_head)
;	
;,fe
;=====================================================================
advance_sect:
	pushset ax,bx,si,di
	xor	ah,ah			; ax = add_sect
	mov	si,cx
	and	si,3fh			; si = cur_sect 
	rol	cl,1
	rol	cl,1
	and	cl,3
	xchg	ch,cl			; cx = cur_cyl
	add	ax,si			; ax = (cur_sect + add_sect)
	mov	si,bx
	and	si,0ffh			; si = spt
	mov	di,dx
	xor	dx,dx
	div	si
	or	dx,dx
	jnz	ads1			; if (rem == 0)
	mov	dx,si			; r1 = spt
	dec	ax			; q1--
ads1:
	xchg	di,dx			; di = cur_sect
	xchg	dh,dl
	mov	si,dx
	xchg	dh,dl
	and	si,0ffh			; si = cur_head
	add	ax,si			; ax = (cur_head + q1)
	mov	bl,bh
	xor	bh,bh			; bx = heads
	mov	si,dx
	xor	dx,dx
	div	bx
	mov	bl,dl			; new_head = r2
	mov	dx,si
	mov	dh,bl			; dh = new_head, dl preserved
	add	cx,ax			; cx = new_cyl = cur_cyl + q2
	xchg	ch,cl
	ror	cl,1
	ror	cl,1			; hi 2 bits of cyl # to cl hi bits
	mov	ax,di
	or	cl,al			; cl (b0 - b5) = new_sect
	popset ax,bx,si,di
	ret


	subttl rw_piece - read into staging buffer & copy to caller's buffer
	page
;======================================================================
;,fs
; rw_piece - read into staging buffer & copy to caller's buffer
; 
; in:	al = entry al for int13 call
;	[origcmd] = orig ah value
;	di = offset for data within caller's buffer
;	[usercx] = entry cx for int13 call
;	[userdx] = entry dx for int13 call
;	[useres] = entry es for int13 call
;	[buffaddr] = segment for read
;	[bps] = bytes per sector
;
; out:	[userax] = exit ax from int13 call
;	[userflag] = exit flags from int13 call
;	di = next offset in caller's buffer (invalid if int13 error)
;	crashes ax,bx,cx,dx,si,es
;
;,fe
;=====================================================================
rw_piece:
	mov	ah,[origcmd]
	cmp	ah,2			; doing a read?
	je	r_piece
	cmp	ah,0ah
	je	r_piece
	cmp	ah,0eh
	je	r_piece
	cmp	ah,1ah
	je	r_piece
	jmp	w_piece			; must be write

;==== read piece

r_piece:
	push	ax
	mov	es,[buffaddr]
	mov	bx,0
	mov	cx,[usercx]
	mov	dx,[userdx]
	push	di
	call	call13u 		; call original int 13 bios
	pop	di
	pushf
	pop	[userflag]		; save returned flags and ax
	mov	[userax],ax
	test	ah,80h			; time out?
	pop	ax			; recover entry al
	jnz	i13rskp2		; yes, not safe to move data
	xor	ah,ah			; calc # of bytes to move
	mov	cx,[bps]
	mul	cx			; presuming dx must be 0
	mov	cx,ax
	mov	es,[useres]		; move data to user area
	mov	si,0
	push	ds
	mov	ds,[buffaddr]
	shr	cx,1
	cld
	rep	movsw
	pop	ds
i13rskp2:
	ret

;==== write piece

w_piece:
	push	ax
	xor	ah,ah			; calc # of bytes to move
	mov	cx,[bps]
	mul	cx			; presuming dx must be 0
	mov	cx,ax
	pop	ax
	mov	es,[buffaddr]
	push	ds
	mov	ds,[useres]		; move data to user area
	mov	si,di
	mov	di,0
	shr	cx,1
	cld
	rep	movsw
	mov	di,si
	pop	ds
	mov	bx,0
	mov	cx,[usercx]
	mov	dx,[userdx]
	push	di
	call	call13u 		; call original int 13 bios
	pop	di
	pushf
	pop	[userflag]		; save returned flags and ax
	mov	[userax],ax
	ret


	subttl fixbps - fetch bps from diskette parms table for floppy operations
	page
;======================================================================
;,fs
; fixbps - fetch bps from diskette parms table for floppy operations
; 
; in:	[userdx] (dl) = drive number
;
; out:	bx = bps (read from diskette parm table for dl < 80)
;
;,fe
;======================================================================
fixfbps:
	cmp	byte ptr [userdx],80h	; hard disk?
	jae	fxf1			; yes, skip
	pushset	cx,si,es
	mov	es,[zero]
	les	si,dword ptr es:[0078h] ; address diskette parm table
	mov	cl,es:[si+3]		; load bytes/sector indicator
	mov	bx,128
	shl	bx,cl			; bx is now correct bytes/sector
	popset	cx,si,es
fxf1:
	ret


	subttl call13u, call13 - call the rom bios int13 handler
	page
;======================================================================
;,fs
; call13u, call13 - call the rom bios int13 handler
;
; in:	int13 entry registers
;	 (if call call13u, [userflag] is put into flags register)
;
; out:	int13 exit registers
;
;,fe
;======================================================================
call13u proc	near
	push	word ptr [userflag]
	popf
call13:
	cli
	pushf
	call	dword ptr cs:[oldint13]
	ret
call13u endp


	subttl 
	page
;======================================================================
;,fs
; i13nread, i13lread, i13sread, i13nwrit, i13lwrit, i13swrit
; 
; process dma read and write requests
;
; in:	al = # of sectors to read
;	[userax], [userbx], [usercx], [userdx], [useres],
;	[userflag] and [origcmd] set from int13 entry values
;
; out:	[userax], [userbx], [usercx], [userdx], [useres] and
;	[userflag] set for int13 exit values
;
;,fe
;======================================================================
i13nread:
i13nwrit:
	mov	bx,512
	jmp	short i13read
i13lread:
i13lwrit:
	mov	bx,516
	jmp	short i13read
i13sread:
i13swrit:
	mov	al,1
	mov	bx,512
i13read:
i13write:

; al is now the number of sectors requested
; bx is bps

	mov	[origsects],al
	call	fixfbps			; fix bps for floppys
	mov	[bps],bx
	mov	ax,[buffsize]
	xor	dx,dx
	div	bx
	mov	[buffsects],ax		; using word for 64k/128 case
	mov	di,[userbx]
	mov	byte ptr [heads],0
	mov	al,[origsects]

; al is now the number of sectors requested
; [buffsects] is the max number of sectors which can fit within buffsize
; di is the starting offset within the caller's buffer

read_loop:
	xor	ah,ah
	cmp	ax,[buffsects]		; if request > available
	ja	mult_pieces		; must do in multiple pieces
	call	rw_piece		; do in one piece
	jmp	i13rexit
mult_pieces:
	mov	dx,[userdx]

; since int13fun08 is not supported for diskettes on all machines
; (e.g. Compaq 16Mhz 386) we cannot easily know the spt and heads
; values.  rather than try to determine the media, the following
; logic simply presumes that no update of the head or cylinder
; will be required.

	cmp	dl,80h			; skip int13fun08 call for diskette
	jb	mp1
	cmp	byte ptr [heads],0	; already made the call? 
	jne	mp1
	mov	ah,8
	push	di
	call	call13	 		; call original int 13 bios
	pop	di
	inc	dh
	mov	[heads],dh		; advance_sect needs these
	and	cl,3fh
	mov	[spt],cl
mp1:
	mov	ax,[userax]
	mov	cl,byte ptr [buffsects]  ; hi word must be 0 anyway
	sub	al,cl
	mov	[remainsects],al
	mov	al,cl
	push	ax
	call	rw_piece		; read a buffer full
	pop	ax
	push	[userflag]		; if error, get out now
	popf
	jc	i13rexit
	mov	cx,[usercx]
	mov	dx,[userdx]
	cmp	dl,80h			; use simple/dumb method for diskette
	jb	mp2
	mov	bh,[heads]
	mov	bl,[spt]		; adjust cx and dx for next piece
	call	advance_sect
	mov	[userdx],dx
	jmp	short mp3
mp2:
	mov	bl,cl			; simple/dump sector advance (diskette)
	and	bl,0c0h
	and	cl,3fh
	add	cl,al
	or	cl,bl
mp3:
	mov	[usercx],cx
	mov	al,[remainsects]	; update accounting
	mov	byte ptr [userax],al
	or	al,al
	jz	i13rexit		; any more?
	jmp	read_loop
i13rexit:
	mov	al,[origsects]
	mov	byte ptr [userax],al
	jmp	i13exit


	subttl 
	page
;======================================================================
;,fs
; i13fmt, i13verfy
; 
; process format and verify operations
;
; in:	[userax], [userbx], [usercx], [userdx], [useres],
;	[userflag] and [origcmd] set from int13 entry values
;
; out:	[userax], [userbx], [usercx], [userdx], [useres] and
;	[userflag] set for int13 exit values
;
;,fe
;======================================================================
i13fmt:
	mov	al,1
	mov	bx,512
	cmp	byte ptr [userdx],80h	; hard disk?
	jae	skipflop		; yes, skip
	mov	es,[zero]
	les	si,dword ptr es:[0078h]	; address diskette parm table
	mov	cl,es:[si+3]		; load bytes/sector indicator
	mov	bx,128
	shl	bx,cl			; bx is now correct bytes/sector
skipflop:
	xor	ah,ah
	mul	bx
	jc	i13error
	cmp	ax,[buffsize]		; check if too big for buffer
	ja	i13error
	push	ds
	mov	cx,ax
	shr	cx,1
	mov	es,[buffaddr]		; move data from user buffer
	mov	di,0
	mov	si,[userbx]
	mov	ds,[useres]
	cld
	rep	movsw
	pop	ds

;==== entry point for verify

i13verfy:
	mov	es,[buffaddr]
	mov	bx,0
	mov	ax,[userax]		; setup int 13
	mov	cx,[usercx]
	mov	dx,[userdx]
	call	call13u 		; call original int 13 bios
	pushf
	pop	[userflag]		; save returned flags and ax
	mov	[userax],ax

;==== common exit handler

i13exit:
	mov	ax,[userax]
	mov	bx,[userbx]
	mov	cx,[usercx]
	mov	dx,[userdx]
	mov	es,[useres]
	push	[userflag]
	popf
	pop	ds
	pop	si
	pop	di
farret13:
	retf	2

;==== common error handler for buffer overflow

i13error:
	or	byte ptr [userflag],01h	; set carry for failed operation
	mov	word ptr [userax],0bb00h ; indicate undefined error in ah
	jmp	i13exit


;======================================================================
;,fs
; rhentry
;
; this function must be reentrant and must not change the
; state of the interrupt enable flag.
;
; all entry registers except bp must be passed through to the 
; subfunction.  all subfunction exit registers except bp must be 
; passed back to the caller.
;
; in:	ah = sub-function #
;	other registers depend on function being called
;
; out:	depends on function being called
;
;,fe
;=====================================================================
	assume	ds:nothing,es:nothing,ss:nothing
rhentry:

IF RHTRACE
	call	rhdebug 		; display request handler debugging
ENDIF

	cmp	ah,rhtablen/2		; invalid function codes are ignored
	jae	rhe1
	push	bx
	push	bp
	mov	bp,sp
	mov	bx,offset mmgrp:rhe2
	push	bx
	mov	bl,ah
	xor	bh,bh
	shl	bx,1
	push	cs:[rhtable+bx]
	mov	bx,[bp+2]
	mov	bp,[bp]
	ret
rhe2:
	pop	cs:[pop_junk]		; balance the stack without changing
	pop	cs:[pop_junk]		; any registers, including flags
rhe1:
	retf

pop_junk dw	?

	even
rhtable label	word
	dw	vreboot 		; ah=0
	dw	valloc			; ah=1
	dw	vrelease		; ah=2
	dw	vremap			; ah=3
	dw	vunmap			; ah=4
	dw	vphymap 		; ah=5
	dw	vprotect		; ah=6
	dw	vunprot 		; ah=7
	dw	vsetiop 		; ah=8
	dw	vclriop 		; ah=9
	dw	3 dup(?)		; 0a,0b,0c - reserved for _286.asm
	dw	vlistmap		; ah=0d
	dw	vdrvstat		; ah=0e
	dw	vsetnmi 		; ah=0f
	dw	vclrnmi 		; ah=10
	dw	vblkcpy 		; ah=11

rhtablen equ	$-rhtable

IF RHTRACE
;======================================================================
;,fs
; rhdebug
;
; request handler debugging (if rhtrace is true)
;
; in:	
;
; out:	
;
;,fe
;=====================================================================
rhmsg	db	'MEMDEV Request '	;@@xlat
rhax	db	'    H  BX= '
rhbx	db	'    H  CX= '
rhcx	db	'    H  ES= '
rhes	db	'    H',13,10,'$'
hextab	db	'0123456789ABCDEF'
rhpause db	0

rhdebug proc	near
	push	ax
	push	bx
	push	cx
	push	dx
	push	ds
	push	si
	push	cs
	pop	ds
	push	cx
	push	bx
	mov	bx,offset mmgrp:rhax+3	; convert ax to hex
	call	bin2hex
	pop	ax			; pushed as bx
	mov	bx,offset mmgrp:rhbx+3	; convert bx to hex
	call	bin2hex
	pop	ax			; pushed as cx
	mov	bx,offset mmgrp:rhcx+3	; convert cx to hex
	call	bin2hex
	mov	ax,es
	mov	bx,offset mmgrp:rhes+3	; convert es to hex
	call	bin2hex
	mov	dx,cs:[portaddr]
	mov	si,offset mmgrp:rhmsg	; point to message
rhdblp:
	lodsb
	cmp	al,'$'			; are we at the end
	je	rhdbend
	mov	ah,al
rhdbout:
	add	dl,5
	in	al,dx
	sub	dl,5
	test	al,20h
	jz	rhdbout
	jmp	$+2
	mov	al,ah
	out	dx,al
	jmp	rhdblp
rhdbend:
	mov	dx,mmgrp:[portaddr]
	add	dl,5
	in	al,dx
	sub	dl,5
	test	al,01h
	jz	rhdbskip
	xor	mmgrp:[rhpause],1
	in	al,dx
rhdbskip:
	cmp	mmgrp:[rhpause],1
	je	rhdbend
	pop	si
	pop	ds
	pop	dx
	pop	cx
	pop	bx
	pop	ax
	ret
rhdebug endp

;======================================================================
;,fs
; bin2hex
;
; in:	ds:bx -> end of destination buffer
;	ax = word to convert
;
; out:	none
;
;,fe
;=====================================================================
	assume	ds:nothing,es:nothing,ss:nothing
bin2hex proc	near
	push	ax
	push	bx
	push	cx
	push	si
	mov	dl,4
b2hexl1:
	mov	si,ax
	and	si,000fh
	mov	cl,mmgrp:[hextable+si]
	mov	[bx],cl
	mov	cl,4
	shr	ax,cl
	dec	bx
	dec	dl
	jg	b2hexl1
	pop	si
	pop	cx
	pop	bx
	pop	ax
	ret
bin2hex endp

ENDIF


;======================================================================
;,fs
; vreboot - memdev api function 00h
;
; in:	none
;
; out:	none
;
;,fe
;=====================================================================
	assume	ds:nothing,es:nothing,ss:nothing
vreboot:
	push	cs
	pop	ds
	assume	ds:mmgrp
	cli
	mov	ss,mmgrp:[buffaddr]	; use staging buffer for our stack
	mov	sp,256

IF GIZMO
	mov	es,mmgrp:[mmadroff]	; switch to transparent mode
	mov	byte ptr es:[0],0
ENDIF

IF ALLCARD
	mov	es,mmgrp:[mmusegad]
	assume es:mmuseg
	mov	[mmureg1],00h		; 4 maps, mmu disabled
	mov	es,cs:[mmuintad]
	assume es:nothing
	mov	byte ptr es:[0],00h	; turn off access to mmu memory
ENDIF

IF CHARGE
	mov	dx,3370h
	mov	al,00h			; disable mapping writes and mapping
	out	dx,al
ENDIF

IF GIZMO+CHARGE
	db	0fh,01h,0eh		; sidt instruction
	dw	offset mmgrp:idtr
	xor	ax,ax			; reset idt location to 0
	mov	mmgrp:[idtr+2],ax
	mov	byte ptr mmgrp:[idtr+4],al
	db	0fh,01h,1eh		; lidt instruction
	dw	offset mmgrp:idtr
ENDIF

	cmp	mmgrp:[foption],0
	jne	fullboot
	mov	ax,40h
	mov	es,ax
	mov	word ptr es:[72h],1234h
fullboot:

	db	0eah			; direct intersegment jump
	dw	0fff0h,0f000h		;   into bios reset code


;======================================================================
;,fs
; valloc - memdev api function 01h
;
; if the allocation request cannot be satisfied, the largest
; available block is returned. the variable parmused is dynami-
; cally maintained to indicate how much extended memory is used.
;
; in:	cx = number of banks desired
;
; out:	ax = 0 if successful, 1 if less allocated than requested
;	bx = starting bank number
;	cx = actual number of banks allocated
;	other registers are preserved
;
;,fe
;=====================================================================
	assume	ds:nothing,es:nothing,ss:nothing

IF GIZMO+ALLCARD+CHARGE

valloc	proc  near			; cx is # banks requested
	push	si
	push	di
	push	dx
	xor	bx,bx
	xor	ax,ax
	mov	mmgrp:[trash1],ax	; tracks position of biggest block
	mov	mmgrp:[trash2],ax	; tracks size	 of biggest block
	mov	mmgrp:[trash3],ax	; default return code
valloop1:
	cmp	bx,parlimit		; check for limit
	jae	valnofit
	call	addrmap 		; address bx'TH PARMAP BIT IN DI:DL
	test	byte ptr mmgrp:[parmap+di],dl
	jnz	valavail		; jump if page is available
	inc	bx			; bump index
	jmp	short valloop1
valavail:
	xor	ax,ax			; ax counts pages found
	mov	si,bx			; si saves starting index
valloop2:
	call	addrmap
	test	byte ptr mmgrp:[parmap+di],dl ; test the entry
	jz	valnotav		; jump if not available
	inc	ax
	inc	bx			; bump index
	cmp	ax,cx			; got enough?
	jae	valgotit		; yes, jump
	cmp	bx,parlimit		; check for limit
	jb	valloop2
valnotav:
	cmp	ax,mmgrp:[trash2]	; is this biggest so far?
	jna	valloop1
	mov	mmgrp:[trash2],ax	; yes, save size & page number
	mov	mmgrp:[trash1],si
	jmp	valloop1
valnofit:
	mov	word ptr mmgrp:[trash3],1  ; return code for ax
	mov	ax,mmgrp:[trash2]	; biggest chunk will have to do
	mov	si,mmgrp:[trash1]
valgotit:
	mov	cx,ax			; number of banks
	mov	bx,si			; starting bank number
	or	ax,ax
	jz	valdone
valloop3:
	call	addrmap
	xor	byte ptr mmgrp:[parmap+di],dl ; flag it busy
	inc	bx
	dec	ax
	jnz	valloop3
	mov	bx,si
valdone:
	add	mmgrp:[parmused],cx	; keep running tally
	mov	ax,mmgrp:[trash3]	; return code
	pop	dx
	pop	di
	pop	si
	ret
valloc	endp

;======================================================================
;,fs
; addrmap
;
; in:	
;
; out:	
;
;,fe
;=====================================================================
	assume	ds:nothing,es:nothing,ss:nothing
addrmap  proc  near
	push	cx
	mov	dl,01h
	mov	cl,bl
	and	cl,07h
	shl	dl,cl
	mov	di,bx
	mov	cl,3
	shr	di,cl
	pop	cx
	ret
addrmap endp

ENDIF


;======================================================================
;,fs
; vrelease - memdev api function 02h
;
; parmused is maintained.
;
; in:	bx = starting bank number to release
;	cx = number of banks
;
; out:	ax = 0 if no errors
;	     1 if releasing unallocated blocks, or if cx=0
;	bx,cx destroyed
;
;,fe
;=====================================================================
	assume	ds:nothing,es:nothing,ss:nothing

IF GIZMO+ALLCARD+CHARGE

vrelease proc  near
	push	di
	push	dx
	mov	ax,1
	or	cx,cx
	jz	vrelexit
vreloop1:
	call	addrmap
	test	byte ptr mmgrp:[parmap+di],dl ; test the entry
	jnz	vrelexit		; error if not allocated
	or	byte ptr mmgrp:[parmap+di],dl
	dec	word ptr mmgrp:[parmused]
	inc	bx
	loop	vreloop1
	xor	ax,ax
vrelexit:
	pop	dx
	pop	di
	ret
vrelease endp

ENDIF

;======================================================================
;,fs
; maint_dmabank
;
; in:	
;
; out:	
;
;,fe
;=====================================================================
	assume	ds:nothing,es:nothing,ss:nothing
maint_dmabank:
	cmp	bl,mmgrp:[dmabank]	; maintain lowest remapped bank
	jae	vremcont
	or	bl,bl
	jz	vremcont
	mov	mmgrp:[dmabank],bl
vremcont:
	ret


;======================================================================
;,fs
; vremap - memdev api function 03h
;
; !! any changes made to this routine should be echoed into vlistmap
;
; in:	bx = starting handle # to map into meg0
;	cx = number of banks
;	es = segment address (must be multiple of granule size)
;
; out:	ax = 0
;
;,fe
;=====================================================================
	assume	ds:nothing,es:nothing,ss:nothing
vremap	proc  near
	push	bx
	push	cx
	pushf				; save interrupt flag state
	cli				; insure no irq's
	mov	ax,bx
	mov	bx,es
	mov	bl,bh
	xor	bh,bh
	call	maint_dmabank

; at this point:  ax = page # relative to parspace (handle)
;		  bx = page frame # within 1st meg
;		  cx = # of pages to remap

	call	remap
	xor	ax,ax
	popf				; restore interrupt flag state
	pop	cx
	pop	bx
	ret
vremap	endp


;======================================================================
;,fs
; vunmap - memdev api function 04h
;
; !! any changes made to this routine should be echoed into vlistmap
;
; in:	cx = number of banks
;	es = segment address (must be multiple of granule size)
;
; out:	ax = 0
;
;,fe
;=====================================================================
	assume	ds:nothing,es:nothing,ss:nothing
vunmap	proc  near
	push	es
	push	bx
	push	cx
	pushf				; save interrupt flag state
	cli				; insure no irq's
	mov	ax,es
	mov	al,ah
	xor	ah,ah

; at this point:  ax = starting page frame # to be unmapped
;		  cx = number of frames to identity map

	call	selfmap
	xor	ax,ax
	popf				; restore interrupt flag state
	pop	cx
	pop	bx
	pop	es
	ret
vunmap	endp


;======================================================================
;,fs
; vphymap - memdev api function 05h
;
; !! any changes made to this routine should be echoed into vlistmap
;
; in:	bx = starting physical bank number to map into meg0
;	cx = number of banks
;	es = segment address (must be multiple of granule size)
;
; out:	ax = 0
;
;,fe
;=====================================================================
	assume	ds:nothing,es:nothing,ss:nothing
vphymap	proc  near
	pushf				; save interrupt flag state
	cli				; insure no irq's
	push	bx
	push	cx
	mov	ax,bx
	mov	bx,es
	mov	bl,bh
	xor	bh,bh

; at this point:  ax = page # to be remapped
;		  bx = page frame # to remap into
;		  cx = number of pages

	call	phymap
	pop	cx
	pop	bx
	popf				; restore interrupt flag state
	xor	ax,ax
	ret
vphymap  endp


;======================================================================
;,fs
; vprotect - memdev api function 06h
;
; if an attempt is made to write on protected memory, an int 6 is
; generated, with the cs and ip values saved on the stack pointing
; to the offending instruction. in addition, parm6ec is set to 0,
; and the doubleword at parm6adr is set to the 32-bit address to
; which the write was attempted.
;
; in:	bx = starting physical bank number, 
;		or else starting handle + 0110h
;	cx = number of banks
;
; out:	ax = 0 if no errors
;	bx,cx destroyed
;
;,fe
;=====================================================================
	assume	ds:nothing,es:nothing,ss:nothing
vprotect:
	ret


;======================================================================
;,fs
; vunprot - memdev api function 07h
;
; in:	bx = starting physical bank number,
;		or else starting handle + 0110h
;	cx = number of banks
;
; out:	ax = 0 if no errors
;	bx,cx destroyed
;
;,fe
;=====================================================================
	assume	ds:nothing,es:nothing,ss:nothing
vunprot:
	ret


;======================================================================
;,fs
; vsetiop - memdev api function 08h
;
;  byte 0, bit 0 of the 128-byte bit map corresponds to i/o address
;  000; byte 127, bit 7 corresponds to 3ff. a zero bit allows i/o
;  to its port address; a 1 bit causes an int 6 to be generated if
;  i/o is attempted.  when the int 6 occurs, the cs and ip values
;  saved on the stack point to the offending instruction.  parm6ec
;  indicates the type of instruction, as follows:
;      3 - in al,xx
;      4 - in ax,xx
;      5 - out xx,al
;      6 - out xx,ax
;      7 - in al,dx
;      8 - in ax,dx
;      9 - out dx,al
;     10 - out dx,ax
;  in addition, the word at parm6adr is set to the 4 bytes of code
;  starting at cs:ip.
;
; in:	es:bx = pointer to 128-byte bit map (i/o addr 0-3ff)
;
; out:	ax = 0
;	bx,cx destroyed
;
;,fe
;=====================================================================
	assume	ds:nothing,es:nothing,ss:nothing
vsetiop  proc  near
	ret
vsetiop  endp


;======================================================================
;,fs
; vclriop - memdev api function 09h
;
; this is a shortcut method of clearing the entire permission map.
;
; in:	none
;
; out:	ax = 0
;	bx,cx destroyed
;
;,fe
;=====================================================================
	assume	ds:nothing,es:nothing,ss:nothing
vclriop  proc  near
	ret
vclriop  endp


;======================================================================
;,fs
; vlistmap - memdev api function 0Dh
;
; list record format:
;
;  +0	action code	word	0 skip, 3 remap, 4 unmap, 5 phymap
;  +2	segment 	word
;  +4	1st bank #	word	(n/a for unmap)
;  +6	1st page count	word
;  +8	2nd bank #	word	** these 2nd bank # and page count
;  +10	2nd page count	word	** fields are only for the remap case.
;
; in:	es:di -> list of mapping instructions and data
;	cx = number of records in list
;
; out:	none
;
;,fe
;=====================================================================
	assume	ds:nothing,es:nothing,ss:nothing
vlistmap:
	pushf				; save current interrupt flag state
	cli				; insure no irq's

; do an initial scan of the list for remap entries and let
; maint_dmabank see each of the meg0 page numbers (high byte of segment)

	push	cx
	push	di
vlm1:
	cmp	word ptr es:[di],3
	jne	vlm3
	mov	bl,es:[di+3]		; get high byte of segment
	call	maint_dmabank
vlm3:
	add	di,12			; advance to next list entry
	loop	vlm1
	pop	di
	pop	cx

	push	ax
	push	bx
	push	cx
	push	dx
	push	di
vlm6:
	push	cx
	mov	cx,es:[di+6]		; get 1st page count
	mov	dx,es:[di+2]		; get segment
	mov	ax,es:[di]		; decode command
	case ax == 3 else vlm8		; remap command
	mov	ax,es:[di+4]		; get 1st starting page #
	mov	bl,dh
	xor	bh,bh
	add	dh,cl			; calc segment for next hdl/pgcnt
	call	remap
	mov	cx,es:[di+10]		; get 2nd page count
	or	cx,cx
	jz	vlm9
	mov	ax,es:[di+8]		; get 2nd starting page #
	mov	bl,dh			; adjusted segment in dx
	xor	bh,bh
	call	remap
vlm9:
	jmp	vlm10

vlm8:	case ax == 4 else vlm11 	; unmap command
	mov	ax,es:[di+2]		; get segment
	mov	al,ah
	xor	ah,ah
	call	selfmap
	jmp	vlm10

vlm11:	case ax == 5 else vlm12 	; phymap command
	mov	ax,es:[di+4]		; get starting bank #
	mov	bx,es:[di+2]		; get segment
	mov	bl,bh
	xor	bh,bh
	call	phymap
twolbl vlm12 vlm10
	add	di,12
	pop	cx
	loop	vlm6
	pop	di
	pop	dx
	pop	cx
	pop	bx
	pop	ax
	popf				; restore interrupt flag state
	ret


	subttl vdrvstat - return driver status information
	page
;======================================================================
;,fs
; vdrvstat - memdev api function 0Eh
;
; return driver status information
;
; in:	bx == 0  (so signature is meaningful)
;
; out:	ax = highest function number supported
;	bx = fa05 (signature)
;	cx = feature bits
;	      b0  - 1 means the memdev is $386.sys - 386 cpu or above
;	      b1  - 1 means protected mode nmi support is active (/n)
;	      b2  - 1 means
;	      b3  - 1 means
;	      b4  - 1 means
;	      b5  - 1 means
;	      b6  - 1 means
;	      b7  - 1 means
;	      b8  - 1 means
;	      b9  - 1 means
;	      b10 - 1 means
;	      b11 - 1 means
;	      b12 - 1 means
;	      b13 - 1 means
;	      b14 - 1 means
;	      b15 - 1 means
;
;	dx = feature bits
;	      b0  - 1 means
;	      b1  - 1 means
;	      b2  - 1 means
;	      b3  - 1 means
;	      b4  - 1 means
;	      b5  - 1 means
;	      b6  - 1 means
;	      b7  - 1 means
;	      b8  - 1 means
;	      b9  - 1 means
;	      b10 - 1 means
;	      b11 - 1 means
;	      b12 - 1 means
;	      b13 - 1 means
;	      b14 - 1 means
;	      b15 - 1 means
;
;,fe
;=====================================================================
	assume	ds:nothing,es:nothing,ss:nothing
vdrvstat:
	mov	bx,0fa05h		; signature
	mov	ax,rhtablen/2-1 	; return highest function supported
	mov	cx,mmgrp:[dvstat1]
	mov	dx,mmgrp:[dvstat2]
	ret


	subttl vsetnmi - establish a new protected mode nmi handler
	page
;======================================================================
;,fs
; vsetnmi - memdev api function 0Fh
;
; establish a new protected mode nmi handler
;
; in:	bx:cx = cs:ip of new nmi handler (16 bit seg:ofs format)
;
; out:	ax = 0 if successful
;	 bx:cx = 32 bit offset of previous handler
;	 dx = code selector of previous handler
;	 di = data selector of previous handler
;	ax == 1 if failed due to insufficient memory in gdt table
;	 bx, cx, dx and di undefined
;
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:nothing
vsetnmi:
	ret


	subttl vclrnmi - restore previous protected mode nmi handler
	page
;======================================================================
;,fs
; vclrnmi - memdev api function 10h
;
; restore previous protected mode nmi handler
;
; in:	bx:cx = 32 bit offset of previous handler
;	dx = code selector of previous handler
;	di = data selector of previous handler
;
; out:	none
;
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:nothing
vclrnmi:
	ret


;======================================================================
;==== support logic for vblkcpy
;======================================================================

;==== local storage macros

; invoke the definit macro at the start of a block of defbyte,
; defword and defdword macros 

definit	macro
bpofs = 0
	endm


; define a byte of local storage

defb1	macro	bname,ofs
bname	equ	byte ptr [bp+ofs]
	endm

defbyte macro	bname
defb1	bname,%bpofs
bpofs = bpofs + 1
	endm


; define a word of local storage

defw1	macro	wname,ofs
wname	equ	word ptr [bp+ofs]
	endm

defword macro	wname
defw1	wname,%bpofs
bpofs = bpofs + 2
	endm


; define a doubleword of local storage

defd1	macro	dname,ofs
dname	equ	dword ptr [bp+ofs]
	endm

defdword macro	dname
defd1	dname,%bpofs
bpofs = bpofs + 4
	endm


; define a buffer of local storage

defbf1	macro	bname,ofs
bname	equ	byte ptr [bp+ofs]
	endm

defbuf	macro	bname,blen
defbf1	bname,%bpofs
bpofs = bpofs + blen
	endm


; invoke loc_start at the beginning of the function to establish 
; the stack frame.

loc_start macro
	push	bp
	sub	sp,bpofs+2
	mov	bp,sp
defw1	caller_bp,%(bpofs+2)
	endm


; invoke loc_end at the end of the function to delete the stack
; frame and preserve the exit flags.

loc_end	macro 
	pushf
	pop	[bp+bpofs]
	add	sp,bpofs
	popf
	pop	bp
	endm

;==== macros bytes to pages and pages to bytes calculations

;==== NOTE: this section is specific to 4096 bytes per page !!!

pg_size	equ	4096	; # of bytes in one page 

; convert a byte count to a number of pages, truncating any partial amounts
; shifts right by 12 for a 4k bytes/page system
; don't waste time shifting 0 
; expects the phyaddr in dx:ax

b2pt	macro
	local	skip
	push	ax
	or	ax,dx
	pop	ax
	jz	skip
	mov	al,ah			; byte swap to shift by 8
	mov	ah,dl			; quickly
	mov	dl,dh
	xor	dh,dh
	shr	dx,1			; four double word shifts
	rcr	ax,1			; witout looping overhead
	shr	dx,1			; for a fast shift by 4
	rcr	ax,1
	shr	dx,1
	rcr	ax,1
	shr	dx,1
	rcr	ax,1
skip:
	endm


; convert a page count to a number of bytes
; shifts left by 12 for a 4k bytes/page system
; don't waste time shifting 0 
; expects the phyaddr in dx:ax

p2b	macro
	local	skip
	push	ax
	or	ax,dx
	pop	ax
	jz	skip
	mov	dh,dl			; byte swap to shift by 8
	mov	dl,ah			; quickly
	mov	ah,al
	xor	al,al
	shl	ax,1			; four double word shifts			
	rcl	dx,1			; witout looping overhead
	shl	ax,1			; for a fast shift by 4
	rcl	dx,1
	shl	ax,1
	rcl	dx,1
	shl	ax,1
	rcl	dx,1
skip:
	endm


; truncate a phyaddr to the next lowest page boundary
; does a logical and with ~fff for a 4k bytes/page system 
; expects the phyaddr in dx:ax

tphy	macro
	and	ax,not 0fffh
	endm


; convert a meg0 phyaddr to a page frame number and an offset within
; the page

; in:	dx:si = phyaddr within meg0
;
; out:	dx = page frame number
;	si = offset within the page

phy2pgo	macro
	push	ax
	mov	ax,si
	and	ax,0fffh		; make ax be offset within page
	shl	si,1
	rcl	dx,1
	shl	si,1
	rcl	dx,1
	shl	si,1
	rcl	dx,1
	shl	si,1
	rcl	dx,1			; dx now holds the page number
	mov	si,ax			; si now holds the offset 
	pop	ax
	endm

;==== end of section which is specific to 4096 bytes per page !!!

max_sc	dw	1000h	; max sub-chunk size 
			;  (max # of bytes to xfer with interrupts off) 


;======================================================================
;,fs
; mso2abs - convert a seg/sel:ofs address to a phyaddr
;
; in:	dx:ax = the seg/sel:ofs type address to convert
;
; out:	dx:ax = the corresponding physical address
;
;,fe
;=====================================================================
	assume ds:nothing,es:nothing,ss:nothing
mso2abs:

;$$$$ if(protected mode) call internal memdev function

soa1:					; non-protected mode logic
	push	bx
	mov	bx,ax
	mov	ax,dx
	xor	dx,dx
	shl	ax,1
	rcl	dx,1
	shl	ax,1
	rcl	dx,1
	shl	ax,1
	rcl	dx,1
	shl	ax,1
	rcl	dx,1
	add	ax,bx
	adc	dx,0
	pop	bx
	ret

;======================================================================
;,fs
; copygt_low
;
; in:	si = task hdl
; 	bx = ofs within task page
;	dx:di = phyaddr of global buffer
;	cx = bytes to copy
;	ax = direction flag (0 for g->t, 1 for t->g)
;
; out:	ax != 0 if error
;
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:nothing
copygt_low:

IF GIZMO+CHARGE
	pushf
	cli				; no reentrance while setting
	push	bx			; up the loadall structure
	push	cx
	push	dx
	push	si
	push	di
	push	bp
	push	ds
	push	es
	add	si,si
	mov	si,mmgrp:[parspace+si]
	shl	si,4
	or	ax,ax
	jnz	cpt1

; when ax == 0, need ds:si -> global buffer, es:di -> task buffer

	mov	mmgrp:[laes],0f000h	; making es as harmless as possible
	mov	word ptr mmgrp:[laesdc+1],si  ; set up es descriptor cache
	mov	byte ptr mmgrp:[laesdc],0
	mov	si,di
	mov	di,bx

; dx:si is now phyaddr of global buffer.  must xlate to an absolute
; physical address which will still be effective when the gizmo is
; in transparent mode.

	phy2pgo
	mov	bx,dx
	add	bx,dx
	mov	bx,mmgrp:[partrack+bx]
	shl	bx,4
	mov	mmgrp:[lads],0f000h	; making ds as harmless as possible
	mov	word ptr mmgrp:[ladsdc+1],bx  ; set up ds descriptor cache
	mov	byte ptr mmgrp:[ladsdc],0
     	jmp	short cpt2
cpt1:

; else, when ax != 0, need ds:si -> task buffer, es:di -> global buffer

	mov	mmgrp:[lads],0f000h	; making ds as harmless as possible
	mov	word ptr mmgrp:[ladsdc+1],si  ; set up ds descriptor cache
	mov	byte ptr mmgrp:[ladsdc],0
	mov	si,bx

; dx:di is now phyaddr of global buffer.  must xlate to an absolute
; physical address which will still be effective when the gizmo is
; in transparent mode.

	xchg	si,di
	phy2pgo
	xchg	si,di
	mov	bx,dx
	add	bx,dx
	mov	bx,mmgrp:[partrack+bx]
	shl	bx,4
	mov	mmgrp:[laes],0f000h	; making es as harmless as possible
	mov	word ptr mmgrp:[laesdc+1],bx  ; set up es descriptor cache
	mov	byte ptr mmgrp:[laesdc],0
cpt2:
	mov	mmgrp:[lacx],cx
	mov	mmgrp:[lasi],si
	mov	mmgrp:[ladi],di
	mov	mmgrp:[ladx],ss
	mov	ax,ss
	mov	mmgrp:[lass],ax
	mov	bl,ah
	shr	bl,4
	shl	ax,4
	mov	word ptr mmgrp:[lassdc+0],ax
	mov	byte ptr mmgrp:[lassdc+2],bl
	mov	mmgrp:[lasp],sp
	mov	ax,cs
	mov	mmgrp:[lacs],ax
	mov	bl,ah
	shr	bl,4
	shl	ax,4
	mov	word ptr mmgrp:[lacsdc+0],ax
	mov	byte ptr mmgrp:[lacsdc+2],bl
	mov	mmgrp:[laip],offset aemcont
	pushf
	pop	mmgrp:[laflags]

IF GIZMO
	mov	es,cs:[mmadroff]	; switch to transparent mode
	mov	byte ptr es:[0],0	; note stack might not be addressable!
ENDIF

IF CHARGE
	mov	dx,3370h
	mov	al,20h			; enable mapping writes, disable mapping
	out	dx,al
ENDIF

	db	0fh,05h			; loadall
aemcont:
	cld
	shr	cx,1
	rep	movsw
	jnc	cpt5
	movsb
	mov	ss,dx
cpt5:
	test	byte ptr mmgrp:[parmfeat+1],04h  ; requires feature bit
	jz	cpt5a
	mov	ax,cs
	mov	ds,ax
	db	0fh,01h,1eh		; lidt instruction
	dw	offset mmgrp:idtr
cpt5a:

IF GIZMO
	mov	es,cs:[mmadron]
	mov	byte ptr es:[0],0	; switch back to mapped mode
ENDIF

IF CHARGE
	mov	dx,3370h
	mov	al,10h			; disable mapping writes, enable mapping
	out	dx,al
ENDIF

	xor	ax,ax
	pop	es
	pop	ds
	pop	bp
	pop	di
	pop	si
	pop	dx
	pop	cx
	pop	bx
	popf

ENDIF
	ret


; this org must remain to insure that no dynamic data is located within
; the first page of meg0.  on 386 systems, the first page is remapped.
; some gizmo and charge systems will also do this.

; !!!!!!!!!! only needed if vblkcpy is not eating up code space

;	org	900h			; 70:900 = 1000


	subttl vblkcpy - protected mode block copy
	page
;======================================================================
;,fs
; vblkcpy - memdev api function 11h
;
; protected mode block copy 
; always does an upwards copy
;
; in:	bx:bp = address of start of handle/page count array	(hp_base)
;	al = (b0 - b6) # of hp array entries			(hp_ele)
;	     (b7) copy direction flag				(dir_flag)
;	      0xxxxxxx - move from global to task buffer
;	      1xxxxxxx - move from task to global buffer   
;	dx = seg/sel corresponding to first task page 		(beg_ad)
;	ds:si == seg/sel:ofs of task buffer 			(task_ptr)
;	es:di = seg/sel:ofs of global buffer 			(glob_ptr)
;	cx = total bytes to copy 				(xfer_bytes)
;
; out:	ax == 0 if no error
;	ax = 1 when entry cx == 0
;	ax = 2 when total pages in array < pgs1
;	ax = 3 for array bounds error
;	ax = 4 for invalid handle
;
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:nothing

;==== stack variables for copygt

definit
defdword hp_base;	; address of start of handle/page count array
defword  hp_ele;	; # of hp array entries (currently 4)
defword  dir_flag;	; operation code, 0 for g->t, 1 for t->g
defword  xfer_cnt;	; total # of bytes to copy
defdword phy_b		; phyaddr of tcbbegad
defdword phy_t		; phyaddr of task_ptr
defdword phy_g		; phyaddr of glob_ptr
defword  pgs1		; # of pages from pb to pd (inclusive) 
defword  pgs2		; # of pages remaining within current section     
defword  task_hdl	; handle of page containing copy point      
defword  task_hofs	; offset into page for copy point
defword  hp_base2	; offset of page # portion of hp array 
defword  ndx		; index into hp_array

;==== end of stack variables

vblkcpy proc near
	loc_start
	push	bx
	push	cx
	push	dx
	push	si
	push	di
	push	ds
	push	es
	cmp	cx,0
	jne	cgt1
	mov	ax,1
	jmp 	cgt2
cgt1:
	push	ds
	push	cs
	pop	ds
	assume	ds:mmgrp

; record entry paramters in stack based vars

	mov	[xfer_cnt],cx
	xor	ah,ah
	push	ax
	and	al,7fh
	mov	[hp_ele],ax
	pop	ax
	and	al,80h
	rol	al,1
	mov	[dir_flag],ax
	mov	ax,[caller_bp]
	mov	word ptr [hp_base],ax
	mov	word ptr [hp_base+2],bx

; dx = [tcbbegad], convert to phyaddr and record in pb

	xor	ax,ax
	call	mso2abs
	mov	word ptr [phy_b],ax
	mov	word ptr [phy_b+2],dx

; es:di -> global buffer, convert to phyaddr and record in pgb

	mov	dx,es
	mov	ax,di
	call	mso2abs
	mov	word ptr [phy_g],ax
	mov	word ptr [phy_g+2],dx

; ds:si -> task buffer, convert to phyaddr in dx:ax
; calc pages to traverse,         pgs1 = b2pt(phy_t - phy_b)
; calc offset within task page,   task_hofs = phy_t - tphy(phy_t)

	pop	dx			; pushed as ds
	mov	ax,si
	call	mso2abs
	mov	si,ax
	sub	ax,word ptr [phy_b]
	sbb	dx,word ptr [phy_b+2]
	b2pt
	mov	[pgs1],ax
	mov	ax,si
	tphy
	sub	si,ax
	mov	[task_hofs],si

; derive ptr to page count entries 

	mov	ax,[hp_ele]
	shl	ax,1
	add	ax,word ptr [hp_base]
	mov	[hp_base2],ax

; tally # of pages to pass

	mov	bx,ax			; make es:bx -> page count entries
	mov	es,word ptr [hp_base+2]
	xor	si,si			;ndx
	xor	ax,ax			;w2
	xor	di,di			;w3
	xor	dx,dx			;w1
cgt3:
	mov	di,ax
	add	ax,es:[bx+si]
	cmp	ax,[pgs1]
	ja	cgt4			; done when satisfy pgs1
	add	si,2
	inc	dx
	cmp	dx,[hp_ele]
	jb	cgt3
	mov	ax,2
	jmp 	cgt2
cgt4:
	mov	[ndx],si

; at this point, di is a tally of the pages in all sections
; previous to the current one (the one addressed by ndx).

	mov	ax,[pgs1]
	sub	ax,di			; calc # of pages into section
	mov	dx,es:[bx+si]		; calc # of pages remaining in section
	sub	dx,ax
	dec	dx
	mov	[pgs2],dx
	mov	bx,word ptr [hp_base]	; derive first task handle */
	add	ax,es:[bx+si]
	mov	[task_hdl],ax
cgt5:
	mov	cx,[xfer_cnt]
	cmp	cx,[max_sc]		
	jna	cgt7			; derive amount to transfer
	mov	cx,[max_sc]		; in this cycle
cgt7:
	mov	di,pg_size
	sub	di,[task_hofs]		; calc bytes remaining in task page
	mov	ax,[pgs2]
	xor	dx,dx
	p2b
	add	ax,di			; calc total bytes remaining in section
	adc	dx,0
	or	dx,dx			; limit to remainder in section
	jnz	cgt8
	or	ax,ax
	jz	cgt8
	cmp	ax,cx
	jnb	cgt8
	mov	cx,ax
cgt8:
	push	di			; save # of bytes remaining in task page
	mov	ax,[dir_flag]
	mov	di,word ptr [phy_g]
	mov	dx,word ptr [phy_g+2]
	mov	bx,[task_hofs]
	mov	si,[task_hdl]
	call	copygt_low
	pop	di
	or	ax,ax
	jz	cgt10
	mov	ax,4
	jmp 	cgt2
cgt10:
	sub	[xfer_cnt],cx		; update accounting
	jnz	cgt11			; done yet?
	xor	ax,ax
	jmp 	cgt2
cgt11:
	cmp	cx,di
	jnae	cgt12			; if just xferred more than remainder in page
	mov	ax,cx			; calc how much more
	sub	ax,di
	mov	di,ax
	xor	dx,dx
	b2pt				; calc pages to advance
	inc	ax
	cmp	ax,[pgs2]
	jna	cgt13			; if not enough pages remaining in section
	add	[ndx],2			; advance to next section
	mov	si,[ndx]
	mov	ax,[hp_ele]
	shl	ax,1
	cmp	si,ax
	jne	cgt14
	mov	ax,2
	jmp 	cgt2
cgt14:
	mov	bx,word ptr [hp_base]	; es still set
	mov	ax,es:[bx+si]
	mov	[task_hdl],ax
	mov	bx,[hp_base2]
	mov	ax,es:[bx+si]
	dec	ax
	mov	[pgs2],ax
	mov	[task_hofs],0
	jmp	short cgt15
cgt13:
	add	[task_hdl],ax		; advance within current section
	sub	[pgs2],ax
	mov	ax,di
	tphy
	sub	di,ax
	mov	[task_hofs],di
cgt15:
	jmp	short cgt17
cgt12:
	add	[task_hofs],cx		; advance within current page
cgt17:
	add	word ptr [phy_g],cx
	adc	word ptr [phy_g+2],0	; update global pointer 	
	jmp 	cgt5
cgt2:
	pop	es
	pop	ds
	pop	di
	pop	si
	pop	dx
	pop	cx
	pop	bx
	loc_end
	ret
vblkcpy endp 



;====================== low level mapping routines ==================

	assume	ds:nothing,es:nothing,ss:nothing

;--------------------------------------------------------------------
;	remapping routine.  bx is starting logical page number,
;	ax is starting physical page (ah is megabytes), cx is
;	number of pages to be mapped.	remember that a page is
;	4k bytes (1000 hex) in length.
;--------------------------------------------------------------------

IF ALLCARD

; at this point:  ax = page # relative to parspace (handle)
;		  bx = page frame # within 1st meg
;		  cx = # of pages to remap

remap	proc  near
	push	es
	push	di
	push	si
	push	bp
	push	ds
	mov	di,cs
	mov	ds,di
	pushf				; save interrupt mask
	cld
	mov	es,cs:[mmusegad]
	mov	di,offset mmuseg:mmupar
	add	di,bx
	mov	si,offset mmgrp:parspace
	add	si,ax
	mov	bp,cx			; save length
	cli
	mov	es:[mmureg1],00h	; disable mmu
	rep	movsb
	mov	cx,bp
	mov	di,offset mmuseg:mmupdr
	add	di,bx
	mov	si,offset mmgrp:pdrspace
	add	si,ax
	rep	movsb
	mov	es:[mmureg1],08h	; enable mmu
	popf
	pop	ds
	pop	bp
	pop	si
	pop	di
	pop	es
	ret
remap	endp

	page
;--------------------------------------------------------------------
;			self-mapping routine
;--------------------------------------------------------------------

; at this point:  ax = starting page frame # to be unmapped
;		  cx = number of frames to identity map

selfmap  proc  near
	mov	ah,0
	mov	bx,ax

; at this point:  ax = page # to be remapped
;		  bx = page frame # to remap into
;		  cx = number of pages

phymap:
	push	es
	pushf
	cli
	mov	es,cs:[mmusegad]
	assume	es:mmuseg
	or	ah,0e0h
	mov	es:[mmureg1],00h	; disable mmu
smaploop:
	mov	es:[mmupar+bx],al	; set par
	mov	es:[mmupdr+bx],ah	; set pdr
	inc	ax
	inc	bl
	loop	smaploop
	mov	es:[mmureg1],08h	; enable mmu
	popf
	pop	es
	ret
	assume	es:nothing
selfmap  endp

ENDIF

IF GIZMO

; at this point:  ax = page # relative to parspace (handle)
;		  bx = page frame # within 1st meg
;		  cx = # of pages to remap

remap	proc  near
	push	es
	push	di
	push	si
	push	ds
	mov	di,cs
	mov	ds,di
	mov	di,bx
	add	di,bx			; two bytes per entry
	mov	si,offset mmgrp:parspace
	add	si,ax
	add	si,ax
	push	cx
	push	si
	push	di
	cld

; update the gizmo's table

	pushf				; save interrupt mask
	cli
	mov	es,cs:[mmadroff]	; switch to transparent mode
	mov	byte ptr es:[0],0	; note stack might not be addressable!
	mov	es,cs:[mmadrtab]
	rep	movsw
	mov	es,cs:[mmadron]
	mov	byte ptr es:[0],0	; switch back to mapped mode
	popf				; stack may now be used

; update the tracking table

	mov	cx,cs
	mov	es,cx
	pop	di
	pop	si
	pop	cx
	add	di,offset mmgrp:partrack
	rep	movsw
	pop	ds
	pop	si
	pop	di
	pop	es
	ret
remap	endp

	page
;--------------------------------------------------------------------
;			self-mapping routine
;--------------------------------------------------------------------

; at this point:  ax = starting page frame # to be unmapped
;		  cx = number of frames to identity map

selfmap  proc  near
	mov	ah,0
	mov	bx,ax

; at this point:  ax = page # to be remapped
;		  bx = page frame # to remap into
;		  cx = number of pages

phymap:
	push	es
	pushf
	shl	bx,1
	push	ax
	push	bx
	push	cx
	cli
	mov	es,cs:[mmadroff]
	mov	byte ptr es:[0],0	; switch to transparent mode

; note that we must not use the stack after disabling mapping!!!

	mov	es,cs:[mmadrtab]

; update the gizmo's table

smaploop:
	mov	es:[bx],ax
	inc	ax
	inc	bx
	inc	bx
	loop	smaploop
	mov	es,cs:[mmadron]
	mov	es:[0],cl		; switch to mapped mode

; update the tracking table

	mov	cx,cs
	mov	es,cx
	pop	cx
	pop	bx
	pop	ax
	popf
	add	bx,offset mmgrp:partrack
smaploop2:
	mov	es:[bx],ax
	inc	ax
	inc	bx
	inc	bx
	loop	smaploop2
	pop	es
	ret
selfmap endp

ENDIF

IF CHARGE

; at this point:  ax = page # relative to parspace (handle)
;		  bx = page frame # within 1st meg
;		  cx = # of pages to remap

remap:
	push	es
	push	di
	push	si
	push	ds
	mov	di,cs
	mov	ds,di
	mov	di,bx
	add	di,bx			; two bytes per entry
	mov	si,offset mmgrp:parspace
	add	si,ax
	add	si,ax
	mov	es,cs:[mmadrtab]
	push	cx
	cld
	pushf				; save interrupt mask
	cli
	call	remapguts

; any remapping to meg0 page0 must be echoed to meg1 page0
; (unless the /C switch was used to reset the feature bit)

	test	byte ptr cs:[parmfeat+1],2
	jz	cgrm1
	or	di,di
	jnz	cgrm1
	mov	di,2*100h
	mov	cx,1
	call	remapguts
cgrm1:

; update the tracking table

	popf				; stack may now be used
	mov	cx,cs
	mov	es,cx
	pop	cx
	add	di,offset mmgrp:partrack
	rep	movsw
	pop	ds
	pop	si
	pop	di
	pop	es
	ret

remapguts:
	push	ax
	push	dx
	push	si
	push	di
	mov	dx,3370h
	mov	al,30h			; enable mapping writes
	out	dx,al
	rep	movsw
	mov	al,10h			; disable mapping writes
	out	dx,al
	pop	di
	pop	si
	pop	dx
	pop	ax
	ret

	page
;--------------------------------------------------------------------
;			self-mapping routine
;--------------------------------------------------------------------

; at this point:  ax = starting page frame # to be unmapped
;		  cx = number of frames to identity map


selfmap:
	mov	ah,0
	mov	bx,ax
	call	phymap
	ret


; at this point:  ax = page # to be remapped
;		  bx = page frame # to remap into
;		  cx = number of pages


phymap:
	push	es
	push	dx
	push	si
	mov	si,ax
	mov	es,cs:[mmadrtab]
	shl	bx,1
	push	cx
	pushf
	cli				; no stack usage while mapping is off!
	call	phymguts

; any remapping to meg0 page0 must be echoed to meg1 page0
; (unless the /C switch was used to reset the feature bit)

	test	cs:[parmfeat+1],2
	jz	cgrm2
	or	bx,bx
	jnz	cgrm2
	mov	bx,2*100h
	mov	cx,1
	call	phymguts
cgrm2:
	popf

; update the tracking table

	mov	cx,cs
	mov	es,cx
	pop	cx
	add	bx,offset mmgrp:partrack
cgrm3a:
	mov	es:[bx],si
	inc	si
	inc	bx
	inc	bx
	loop	cgrm3a
	pop	si
	pop	dx
	pop	es
	ret

phymguts:
	push	bx
	push	si
	mov	dx,3370h
	mov	al,20h			; enable mapping writes, disable mapping
	out	dx,al
cgrm3:
	mov	es:[bx],si
	inc	si
	inc	bx
	inc	bx
	loop	cgrm3
	mov	al,10h			; disable mapping writes, enable mapping
	out	dx,al
	pop	si
	pop	bx
	ret

ENDIF


IF GIZMO+CHARGE

	page
;--------------------------------------------------------------------
;		    turn on address bit 20 gate
;--------------------------------------------------------------------
bit20on  proc  near
	push	ax
	cli
	call	clr8042
	mov	al,0d1h
	out	64h,al
	call	clr8042
	mov	al,0dfh
	out	60h,al
	call	clr8042
skip8042:
	pop	ax
	ret
bit20on  endp

clr8042  proc  near
clr8042l:
	in	al,064h 		; read status port
	and	al,02h			; loop until buffer empty
	jnz	clr8042l
	ret
clr8042  endp

ENDIF

	page
;--------------------------------------------------------------------
;		     binary-to-decimal routine
;--------------------------------------------------------------------
bintodec proc  near
	push	cx
btdloop1:
	div	word ptr [wordten]	; dx:ax is source integer
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




IF GIZMO+CHARGE

;--------------------------------------------------------------------
;	     interrupt vector table and related items
;	the idt may be located anywhere in real or extended memory
;--------------------------------------------------------------------
	align 16			; align for ease of debugging

ivtable dw	256 dup(0,0)
idtr	dw	0,0,0			; used by sidt and lidt instructions

; jump table entries are entered via the new idt. cs will have a
; value equal to the offset into the interrupt table divided by 16
; e.g., for interrupt 21h cs will be 0008 and entry will be to the
; second jmp in the table (which goes to dword ptr cs:[4]). the
; reason, of course, for using different cs values is so that we
; don't waste 1280 bytes just for a jump table. Note that the jump
; table must reside within the first 64k of ram.

jtable	label	word
	jmp	dword ptr cs:[00]
	jmp	dword ptr cs:[04]
	jmp	dword ptr cs:[08]
	jmp	dword ptr cs:[12]
ENDIF

	page
;--------------------------------------------------------------------
;		   parameters available to user
;--------------------------------------------------------------------

;=========== note: the following variables must stay in order =========

	even
parms	label word
parmrhad dw    2 dup(0) 		; address of request handler
parmfeat label word			; special features:
					;   8000h = all memory is managed
					;   4000h = i/o trapping supported
					;   2000h = write protection supported
					;   1000h = use memory mapping for cxt switch
					;   0800h = "declare" supported ($286.sys only)
					;   0400h = ivtable support
					;   0200h = upper 60k supported (fff8:1080)
IF ALLCARD
	dw	9000h
ENDIF
IF GIZMO
	dw	8400h			; gizmo h/w forces address wrap at 1mb
ENDIF
IF CHARGE
	dw	8600h
ENDIF

parmgran dw    4096,0			; granularity is 4k per page
parmtot  dw    0,0			; total extended memory (pages)
parmused dw    0,0			; used	extended memory (pages)
parm6ec  dw    0			; error code for int 6
;		0 - writing to protected memory
;		1 - operation exception
;		2 - protection exception (not due to i/o or write protection)
;		3 - in al,xx
;		4 - in ax,xx
;		5 - out xx,al
;		6 - out xx,ax
;		7 - in al,dx
;		8 - in ax,dx
;		9 - out dx,al
;		10 - out dx,ax

parm6adr dw    0,0			; address or i/o instruction for int 6
parmscb  dw    01fch,0			; scb address - filled in by mos
	dw	0,0

IF GIZMO+CHARGE
parmaiv dw	offset mmgrp:ivtable
ELSE
	dw	0
ENDIF

parmpfa dw	0			; address of 4k page frame in staging buffer

;========================= end of fixed area =========================

	page

; dma staging buffer parameters

	even
oldint13	dd	0		; original int13 vector
buffaddr	dw	0		; disk staging buffer seg address
buffsize	dw	18*512		; disk staging buffer size
origsects	db	0		; initial request sectors
remainsects	db	0		; remaining sectors to process
buffsects	dw	0		; # of sectors which can fit in buffer
origcmd		db	0		; int13 command being processed
heads		db	0		; total heads for drive
spt		db	0		; sectors per track
bps		dw	0		; bytes per sector
userax		dw	0		; entry/exit ax
userbx		dw	0		; entry/exit bx
usercx		dw	0		; entry/exit cx
userdx		dw	0		; entry/exit dx
useres		dw	0		; entry/exit es
userflag	dw	0		; entry/exit flags

; assorted data

rhoff		dw	0		; request header pointer
rhseg		dw	0		; this must immediately follow rhoff!
meg0old 	dw	0080h		; original nbr meg0 banks
meg0new 	dw	0080h		; final number meg0 banks
dmabank 	db	0ffh,0		; bank above which disk staging needed
mysegadr	dw	0		; segment address of this driver
workaddr	dw	0d000h,0	; address of initialization work area
videoadr	dw	0b000h		; seg address of video ram
trash1		dw	-1		; scratch areas
trash2		dw	-1
trash3		dw	-1
dvstat1 	dw	0		; used by function 14
dvstat2 	dw	0		; used by function 14

;--------------------------------------------------------------------
;		  allcard-specific data areas
;--------------------------------------------------------------------

IF ALLCARD
parlimit equ	0400h			; up to 4mb supported
mmusegad dw	0ef00h
mmuintad dw	0ffffh
parspace db	parlimit dup(0) 	; values for page address regs
pdrspace db	parlimit dup(0e0h)	; values for page descriptor regs
parmap	 db	parlimit/8 dup(0)	; bit map of reserved banks
pdrtran  db	0e0h,0f1h,0f2h,0f6h,0fah,0feh,0f3h,0f7h,0fbh,0ffh
ENDIF

;--------------------------------------------------------------------
;		    gizmo-specific data areas
;--------------------------------------------------------------------

IF GIZMO
parlimit equ	08a0h			; support up to 8mb + 640k
mmadron  dw	0f800h			; ff00 if contel machine
mmadroff dw	0fc00h
mmadrtab dw	0fe00h
parspace dw	parlimit dup(0) 	; register table
parmap	 db	parlimit/8 dup(0)	; bit map of reserved banks
partrack dw	256 dup(0)		; mapping state tracking table
					; (for api function 11h)
ENDIF

;--------------------------------------------------------------------
;		   charge-specific data areas
;--------------------------------------------------------------------

IF CHARGE
parlimit equ	0800h			; support up to 8mb
mmadrtab dw	0fe00h
parspace dw	parlimit dup(0) 	; register table
parmap	 db	parlimit/8 dup(0)	; bit map of reserved banks
partrack dw	256 dup(0)		; mapping state tracking table
					; (for api function 11h)
ENDIF

res16  ends


;======================== 32 bit resident code =========================

	.386p
res32	segment para public 'CODE' use32
assume	cs:mmgrp,ds:nothing,es:nothing,ss:nothing,fs:nothing,gs:nothing
res32	ends


;======================== 16 bit initialization code ===================

	.286
init16	segment para public 'CODE'
	assume	cs:mmgrp,ds:mmgrp

	even
progend  label byte			; end of retained code


; The following 512 bytes is necessary for when esdi bios needs to
; be relocated.  The space is necessary because of
; MJS's modifications for 386 driver and conflicts with ESDI bios
; relocation logic would copy bios information into INIT code.

	db	1024	dup (0)

msgodm	db	'  nnnK RAM found in first megabyte;    ',13,10,'$'  ;@@xlat
ermsize db	'Insufficient RAM available!  ',13,10,'$'  ;@@xlat
mmpar_bad db	13,10,'MEMDEV parameter error, load aborted              ',07,13,10,'$'  ;@@xlat

	subttl dectobin - decimal-to-binary conversion routine
	page
;======================================================================
;,fs
; dectobin - decimal-to-binary conversion routine
;
; in:	es:bx -> parameter to convert
;
; out:	ax = converted value
;	es:bx -> char just after parameter
;	crashes dx
;
;,fe
;======================================================================
dectobin:
	xor	ax,ax			; ax will contain the result
dtbloop:				; es:bx is source address
	mov	dl,es:[bx]
	cmp	dl,'0'
	jb	dtbwrap
	cmp	dl,'9'
	ja	dtbwrap
	push	dx
	mul	[wordten]
	pop	dx
	and	dx,000fh
	add	ax,dx
	inc	bx
	jmp	dtbloop
dtbwrap:
	ret



	subttl pass_space - advance es:bx past blanks
	page
;======================================================================
;,fs
; pass_space - advance es:bx past blanks
;
; in:	es:bx -> string
;
; out:	al = stop char
;	es:bx -> stop char
;
;,fe
;======================================================================
pass_space:
	mov	al,es:[bx]
	cmp	al,' '
	jne	pass_done
	inc	bx
	jmp	short pass_space
pass_done:
	ret


	subttl find_space - advance es:bx to 1st space or eol
	page
;======================================================================
;,fs
; find_space - advance es:bx to 1st space or eol
;
; in:	es:bx -> string
;
; out:	al = 1st space found or eol marker
;	es:bx -> stop char
;
;,fe
;======================================================================
find_space:
	mov	al,es:[bx]
	cmp	al,0dh
	je	find_done
	cmp	al,' '
	je	find_done
	inc	bx
	jmp	short find_space
find_done:
	ret


	subttl parse - parse the parameter line
	page
;======================================================================
;,fs
; parse - parse the parameter line
;
; in:	data in [rhoff]
;
; out:	ax != 0 if error
;	global vars set from parameters found
;
;,fe
;======================================================================
parse:
	les	bx,dword ptr [rhoff]
	les	bx,dword ptr es:[bx+18] ; get parameter pointer
	call	find_space		; parse past the memdev name
	call	pass_space		; find 1st parameter
	cmp	al,0dh
	jne	sw_a
	jmp	swdone
sw_a:
	cmp	al,'/'
	je	sw_loop

; if first thing found isn't a slash, presume its a new meg0new value

	call	dectobin		; get the number in ax
	cmp	ax,64			; range must be reasonable
	jb	badparm
	cmp	ax,704
	ja	badparm
	mov	cl,2
	add	ax,3			; round up to 4k
	shr	ax,cl			; convert from kbytes to 4k banks
	mov	[meg0new],ax
	dec	bx
sw_hunt:
	inc	bx
	call	pass_space		; find next parameter
	cmp	al,0dh
	jne	sw_b
	jmp	swdone
sw_b:
	cmp	al,'/'			; if not eol, should be a switch
	je	sw_loop
badparm:
	jmp	sw_synerr

; at this point, es:bx -> '/'  so check for switch options

sw_loop:
	inc	bx
	mov	al,es:[bx]		; scan for a slash
	cmp	al,'D'			; /d=nn for custom staging buffer
	jne	sw_not_d
	cmp	byte ptr es:[bx+1],'='
	jne	badparm
	add	bx,2
	call	dectobin		; get the number in ax
	dec	bx			; leave bx -> last char of parm
	cmp	ax,64			; range must be reasonable
	ja	badparm
	je	sw_max
	cmp	ax,4			; must have >= 4k for parmpfa use
	jb	badparm							   
	mov	cl,10			; * 1024
	shl	ax,cl
	jmp	short swdma
sw_not_d:
	cmp	al,'P'			; ps/2 needs 16k dma buffer
	jne	sw_not_p
	mov	ax,4000h
	jmp	short swdma
sw_not_p:
	cmp	al,'M'			; midrange 32k buffer
	jne	sw_not_m
	mov	ax,8000h
	jmp	short swdma
sw_not_m:
	cmp	al,'E'			; emulex needs 64k dma buffer
	jne	sw_not_e
sw_max:
	mov	ax,0ffffh
	jmp	short swdma
sw_not_e:
	cmp	al,'X'			; xt needs 9k dma buffer
	jne	sw_not_x
	mov	ax,18*512
swdma:
	mov	[buffsize],ax
	mov	[dmajump],9090h 	; nop out conditional jump
	jmp	sw_hunt
sw_not_x:

	cmp	al,'I'			; /i for "simple" interrupt management
	jne	sw_not_i
	and	byte ptr [parmfeat+1],not 04h
	jmp	sw_hunt
sw_not_i:
	cmp	al,'C'			; /c for "conventional" memory
	jne	sw_not_c
	and	byte ptr [parmfeat+1],not 02h
	jmp	sw_hunt
sw_not_c:

IF GIZMO+CHARGE
	cmp	al,'S'			; /s for "switch with context mapping"
	jne	sw_not_s
	or	byte ptr [parmfeat+1],10h
	jmp	sw_hunt
sw_not_s:
ENDIF	 
	cmp	al,'F'			; /f for full reboot (skip warm boot)
	jne	sw_not_f
	mov	[foption],1
	jmp	sw_hunt
sw_not_f:

; when reach this point, report syntax error

sw_synerr:
	mov	dx,offset mmgrp:mmpar_bad
	mov	ah,9
	int	21h
	mov	ax,1
	ret
swdone:
	xor	ax,ax
	ret


	subttl init - device driver initialization logic
	page
;======================================================================
;,fs
; init - device driver initialization logic
;
; in:	none
;
; out:	all sorts of stuff setup
;
;,fe
;======================================================================
init:
	mov	dx,offset mmgrp:loadmsg0
	mov	ah,9
	int	21h
	mov	ah,2
	mov	dl,'$'
	int	21h
	mov	dx,offset mmgrp:loadmsg
	mov	ah,9
	int	21h
; Make sure that we save correct Interupt mask from port 21h
; and make sure that we mask out IRQ 1, on IBM Model 70 486,
; Turning on bit 20 cause an unwanted IRQ 1 to be issued

	in	al,21h
	mov	[p21bits],al		; save current state for later
	or	al,2			; disable INT 9 during INIT
	out	21h,al

; get video ram address

	mov	es,[zero]
	mov	ax,es:[0410h]		; get equip_flag
	and	al,30h
	cmp	al,30h			; monochrome card?
	je	skipcolr		; yes, skip
	mov	[videoadr],0b800h	; no, set address for color card
	jmp	donevid
skipcolr:
donevid:

; determine original base memory size

	mov	es,[zero]
	mov	ax,es:[0413h]		; get default value
	mov	bx,ax
	add	ax,3			; model 80 is 639k
	shr	ax,1
	shr	ax,1			; convert to a multiple of 4k
	mov	[meg0old],ax
	mov	[meg0new],ax
	mov	[parmused],ax
	mov	[dmabank],al		; for dma logic
	mov	ax,bx
	xor	dx,dx			; put old meg0 size in message
	mov	bx,offset mmgrp:msgodm+4
	mov	cx,5
	call	bintodec
	call	parse			; parse the parameter line
	or	ax,ax
	jz	parseok
	jmp	ddabort
parseok:

	page
;--------------------------------------------------------------------
;		    initialize all-card mapping
;--------------------------------------------------------------------

IF ALLCARD
	xor	si,si
	mov	ax,0e000h
	mov	cx,[meg0old]		; plug meg0 table entries
iparlop0:
	mov	[parspace+si],al
	mov	[pdrspace+si],ah
	inc	ax
	inc	si
	loop	iparlop0
	mov	ax,0100h		; now plug for meg1 and beyond
	xor	bx,bx
iparlop1:
	mov	bl,ah
	mov	bl,[pdrtran+bx]
	mov	[parspace+si],al
	mov	[pdrspace+si],bl
	inc	ax
	inc	si
	cmp	si,parlimit
	jb	iparlop1
	mov	es,[mmuintad]
	mov	byte ptr es:[0],03h	; allow access to mmu memory
	mov	es,[mmusegad]
	assume es:mmuseg
	mov	[mmureg0],03h		; nmi enable; system mode
	mov	[mmureg1],00h		; 4 maps, mmu disabled
	mov	[mmureg3],00h		; use current map #0
	mov	[mmureg5],08h		; select current map (i.e., not alt)
	mov	[mmueab],00h		; extended address bit
	xor	ax,ax
	mov	cx,256
	call	selfmap
	mov	[mmureg1],08h		; enable mmu
ENDIF

;--------------------------------------------------------------------
;	     initialize gizmo or charge-card mapping
;--------------------------------------------------------------------

IF GIZMO+CHARGE
	call	bit20on 		; turn on address bit 20 gate
	xor	bx,bx
	xor	ax,ax
	mov	cx,[meg0old]		; plug meg0 table entries
iparlop0:
	mov	[parspace+bx],ax
	mov	[partrack+bx],ax
	inc	ax
	inc	bx
	inc	bx
	loop	iparlop0
	mov	ax,0100h		; page 256 is 1mb boundary
iparlop1:
	mov	[parspace+bx],ax
	inc	ax
	inc	bx
	inc	bx
	cmp	bx,parlimit*2
	jb	iparlop1
IF CHARGE				; init chargecard ii
	mov	dx,3170h		;  we must write to "dummy"
	mov	al,00h			;  address 31xx in order to use
	out	dx,al			;  "required" address 33xx.
ENDIF					;
	xor	ax,ax
	mov	cx,256
	call	selfmap
ENDIF

; save/set disk i/o vector

	mov	es,[zero]
	mov	ax,es:[004ch]		; save int 13h vector
	mov	word ptr [oldint13],ax
	mov	ax,es:[004eh]
	mov	word ptr [oldint13+2],ax
	mov	es:[004eh],cs		; set new int 13h vector
	mov	word ptr es:[004ch],offset mmgrp:entinr13

; init some more pointers

	mov	[mysegadr],cs
	mov	[parmrhad+0],offset mmgrp:rhentry
	mov	[parmrhad+2],cs

; write old memory size

	mov	ah,9
	mov	dx,offset mmgrp:msgodm
	int	21h

; non-386 extended memory initialization


; save original nmi vector

	mov	ax,es:[0008h]
	mov	word ptr [oldnmi],ax
	mov	ax,es:[000ah]
	mov	word ptr [oldnmi+2],ax

; set nmi vector to an iret during memory check

	mov	word ptr es:[0008h], offset mmgrp:newnmi
	mov	word ptr es:[000ah],cs

	mov	dx,[meg0old]		; initialize all meg1 ram
initlop1:
	mov	bx,[workaddr+1] 	; use 4k address space at d0000
	mov	ax,dx
	mov	cx,0001h		; init 1 bank (4k) at a time
	call	remap
	mov	es,[workaddr]
	mov	ax,7777h
	mov	es:[0],ax
	cmp	es:[0],ax
	jne	izdone			; exit if no ram there
	xor	di,di
	xor	ax,ax
	mov	cx,2048 		; 2k words = 4k bytes
	cld
	rep	stosw
	cmp	es:[0],ax
	jne	izdone			; exit if no ram there
	inc	dx
	cmp	dx,parlimit
	jb	initlop1
izdone:
	mov	[parmtot],dx		; save amount of ram found
	mov	bx,[meg0old]		; flag available banks
	mov	cx,[parmtot]
	sub	cx,bx
	or	cx,cx			; if no extended memory found
	jz	izskip			; skip map table initialization

; following 8 lines added 7/13/89 rbr

IF CHARGE
	test	byte ptr [parmfeat+1],02h  ; reserving 64k at 1mb boundary?
	jz	izfloop 		; no, skip
	add	bx,16			; yes, then reserve it
	add	[parmused],16
	sub	cx,16
	jbe	izskip
ENDIF

izfloop:
	call	addrmap
	or	[parmap+di],dl
	inc	bx
	loop	izfloop
izskip:

; reset nmi vector to orginal nmi vector

	xor	ax,ax
	mov	es,ax
	mov	ax,word ptr [oldnmi]
	mov	es:[0008h],ax
	mov	ax,word ptr [oldnmi+2]
	mov	es:[000ah],ax

; extended memory is initialized

	xor	ax,ax
	mov	cx,256
	call	selfmap 		; reinitialize meg0 mapping

; write total memory size

	mov	ax,[parmtot]		; compute kbytes of total memory
	shl	ax,1
	shl	ax,1
	xor	dx,dx
	mov	bx,offset mmgrp:msgem+4
	mov	cx,5
	call	bintodec
	mov	ah,9
	mov	dx,offset mmgrp:msgem
	int	21h

	page

; change dos partition size if required

	mov	cx,[meg0new]
	sub	cx,[meg0old]
	je	noresize
	jl	shrink
	call	valloc			; get banks to extend base ram
	or	al,al
	jz	$+5
	jmp	errsize
	mov	ax,bx			; map them in
	mov	bx,[meg0old]
	call	remap
	jmp	short noresize
shrink:
	neg	cx			; free up banks
	mov	bx,[meg0new]
	call	vrelease
noresize:
	mov	es,[zero]		; set bios ram size in kilobytes
	mov	ax,[meg0new]
	shl	ax,1
	shl	ax,1
	mov	es:[0413h],ax

	page
;--------------------------------------------------------------------
;	move extended bios data area if needed.
;--------------------------------------------------------------------
	mov	ax,offset mmgrp:progend
	add	ax,15
	mov	cl,4
	shr	ax,cl
	mov	dx,cs
	add	ax,dx			; buffer begin paragraph address

; move data area used by ibm esdi bios

	push	es
	mov	es,[zero]
	mov	dx,es:[040eh]
	cmp	dx,9fc0h		; data area at 9fc0:0000?
	jne	mieskip
	mov	es:[040eh],ax		; yes, replace its address
	mov	es,ax			;   and move its data to the new area
	push	ds
	mov	ds,dx			; source address
	xor	si,si
	xor	di,di
	mov	cx,512			; length is 1k
	cld
	rep	movsw
	pop	ds
	add	ax,0040h		; bump ending segment by 1k
mieskip:
	pop	es
;--------------------------------------------------------------------
;	compute buffer location - must not cross 64k boundary
;--------------------------------------------------------------------
	mov	bx,[buffsize]
	mov	cl,4
	shr	bx,cl
	add	bx,ax			; buffer end
	push	ax
	and	ax,0f000h
	and	bx,0f000h
	cmp	ax,bx
	pop	ax
	je	bufadrok		; jump if segment not crossed
	add	ax,0fffh		; bump to next segment
	and	ax,0f000h
bufadrok:
	mov	[buffaddr],ax
	mov	dx,ax			; put parmpfa in parms area
	add	dx,00ffh
	xor	dl,dl
	mov	[parmpfa],dx
	les	bx,dword ptr [rhoff]
	mov	dx,[buffsize]		; compute end of buffer
	mov	cl,4
	shr	dx,cl
	inc	dx
	add	ax,dx

; set end address of this driver

	mov	word ptr es:[bx+14],0	; set this driver's end address
	mov	word ptr es:[bx+16],ax

; protect dma channel 2

; write message

	mov	es,[zero]
	mov	ax,es:[0413h]		; new mos size in kbytes
	xor	dx,dx
	mov	bx,offset mmgrp:msgndm+4
	mov	cx,5
	call	bintodec
	mov	ah,9
	mov	dx,offset mmgrp:msgndm
	int	21h

; replace interrupt vector table if 80286

IF GIZMO+CHARGE
	test	byte ptr [parmfeat+1],04h  ; requires feature bit
	jz	bidend
	db	0fh,01h,0eh		; sidt instruction
	dw	offset mmgrp:idtr
	mov	ax,cs			; compute new idtr contents
	mov	bl,ah
	shl	ax,4
	shr	bl,4
	add	ax,offset mmgrp:ivtable
	adc	bl,0
	mov	[idtr+2],ax
	mov	byte ptr [idtr+4],bl
	xor	si,si			; si indexes the idt
	mov	ax,cs			; get absolute address of jtable in ax
	shl	ax,4
	add	ax,offset mmgrp:jtable
	xor	dx,dx			; dx is code segment value
bidloop1:
	mov	cx,4			; cx is number of times
bidloop2:
	mov	[ivtable+si],ax 	; plug offset mmgrp:into idt entry
	mov	[ivtable+2+si],dx	; segment portion
	add	ax,5
	add	si,4
	loop	bidloop2
	inc	dx
	sub	ax,5*4+10h
	cmp	si,256*4
	jb	bidloop1
	db	0fh,01h,1eh		; lidt instruction
	dw	offset mmgrp:idtr
bidend:
ENDIF

; initialization completed
	jmp	short donemm

; write error messages

errsize:
	mov	ah,9
	mov	dx,offset mmgrp:ermsize
	int	21h

; Make sure that we restore Interupt Masks back to original masks

donemm:
	mov	al,[p21bits]		; get original mask
	out	21h,al			; out to 8259
	jmp	donestat

; the following is use during 386 memory test to turn off
; nmi by setting to int 2 to an iret.	this needed because
; if an inboard 386 /pc is used, the pc bios will come up
; with parity error when 386 driver check for memory above 1 meg

p21bits db	0		; save area for Port 21
oldnmi	dd	0			; storage for original nmi vector
newnmi:
	iret				; just make it an iret
msgem	db    'nnnnnK total RAM found;      ',13,10,'$'  ;@@xlat
msgndm	db    '  nnnK allocated to first megabyte.   ',13,10,13,10,'$'	;@@xlat

loadmsg0 db	'Loading $'
IF GIZMO
loadmsg	db	'GIZMO.SYS  version 4.15  (920102)',13,10,'$'	;@@xlat
ENDIF
IF CHARGE
loadmsg	db	'CHARGE.SYS  version 4.15  (910102)',13,10,'$'	;@@xlat
ENDIF
IF ALLCARD
loadmsg	db	'ALL.SYS  version 4.15  (910102)',13,10,'$'	;@@xlat
ENDIF

init16 ends

;======================== 32 bit initialization code ===================

	.386p
init32	segment para public 'CODE' use32
	assume	cs:mmgrp

init32	ends
	end   begin

