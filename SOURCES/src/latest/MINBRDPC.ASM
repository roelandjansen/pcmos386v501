	include page.inc
	title	minbrdpc.asm
	subttl	minbrdpc.asm - intel inboard 386/pc device driver
comment ^===============================================================
		     development specification

 program name:	minbrdpc.sys		   assigned to: martin stitt
 module name:	minbrdpc		   assign date: 12/01/89
 entry points:	strat/intr		   completed:	12/11/89
 entry from:	todriver
 entry method:	device driver call
 purpose:	controls the intel inboard 386/pc under mos
 refer to:	n/a
 last update:	12/11/89

=======================================================================

 note: this module works in conjunction with the mispeed.com utility

 usage:  device=minbrdpc.sys [/cw=nn] [/hw=nn] [/fw=nn]

  where:
    /cw specifies the current (or default) number of wait states
    /hw specifies the number of wait states for hard disk calls
    /fw specifies the number of wait states for floppy disk calls

 in	all cases, nn represents an even number from 0 to 30 (inclusive)

 this driver must be used in conjunction with the $386.sys memdev driver.

 future additions
 ================
 balk if previously loaded (check rom pointer)
 balk if try to load task specific - convert to api in future
   (check mos version before using this api feature)
 support copy of ega rom bios to fast ram

=======================================================================

======================================================================^

cseg	segment word public 'code'
	assume	cs:cseg,ds:nothing,es:nothing,ss:nothing

include minbrdpc.pub

	org	0h
	dd	-1
	dw	1100000000000000b	; char,ioctrl
	dw	strat
	dw	intr
	db	'MINBPC  '

devhdr	dd	2 dup(0)		; header pointer

wait_state_port equ	670h	; wait state control port address
speed_bits	equ	1eh		; per intel doc

ram_enable db	1			; per reverse engineering inbrdpc.sys
hdwt	db	0			; wait states for hard disk calls
fdwt	db	16			; wait states for floppy disk calls
curwt	db	0			; current wait state value
orig13	dd	?			; original int13 vector
origboot dw	?,?			; original far jmp address for boot

rqhin struc				; structure for init
in_rhlen	db	?
in_unit 	db	?
in_command	db	?
in_status	dw	?
in_fill1	db	8 dup(?)
in_units	db	?
in_endres	dd	?
in_parmbpb	dd	?
rqhin ends

rqhrw struc				; structure for reads and writes
rw_rhlen	db	?
rw_unit 	db	?
rw_command	db	?
rw_status	dw	?
rw_fill1	db	8 dup(?)
rw_media	db	?
rw_dataptr	dd	?
rw_datasize	dw	?
rw_strtsct	dw	?
rw_volptr	dd	?
rqhrw ends

funtbl	dw	init			; 0  init
	dw	nullfun 		; 1  media check
	dw	nullfun 		; 2  build bpb
	dw	ioctlrd 		; 3  i/o control input
	dw	nullfun 		; 4  input (read)
	dw	nullfun 		; 5  nondestructive input no wait
	dw	nullfun 		; 6  input status
	dw	nullfun 		; 7  input flush
	dw	nullfun 		; 8  output (write)
	dw	nullfun 		; 9  output with verify
	dw	nullfun 		; 10 output status
	dw	nullfun 		; 11 output flush
	dw	ioctlwrt		; 12 i/o control output
maxfun	equ	($-funtbl)/2

;======================== device driver routines =======================


	subttl strat - enque ptr to device driver request header
	page
;======================================================================
; .func: strat - enque ptr to device driver request header
;
; input:
;	es:bx -> device request header
;
; output:
;
; comments:
;
; .calls: 
; .reads: 
; .writes: 
;
; .endfn
;======================================================================
	assume	ds:nothing,es:nothing,ss:nothing
strat:
	mov	word ptr [devhdr],bx
	mov	word ptr [devhdr+2],es
	retf


	subttl intr - process device driver commands
	page
;======================================================================
; .func: intr - process device driver commands
;
; input:
;
; output:
;
; comments:
;
; .calls: 
; .reads: 
; .writes: 
;
; .endfn
;======================================================================
	assume	ds:nothing,es:nothing,ss:nothing
intr:
	push	ax
	push	bx
	push	cx
	push	dx
	push	si
	push	di
	push	bp
	push	es
	push	ds
	push	cs
	pop	ds
	assume	ds:cseg
	les	bx,[devhdr]
	mov	al,es:[bx].in_command
	cmp	al,maxfun
	ja	itr1
	xor	ah,ah
	lea	si,funtbl
	shl	ax,1
	add	si,ax
	call	[si]			; execute appropriate routine
	jmp	short	itr2
itr1:
	mov	ax,8013h
itr2:
	les	bx,[devhdr]
	mov	es:[bx].in_status,ax
	pop	ds
	pop	es
	pop	bp
	pop	di
	pop	si
	pop	dx
	pop	cx
	pop	bx
	pop	ax
	retf


	subttl nullfun - null function handler
	page
;======================================================================
; .func: nullfun - null function handler
;
; input:
;	es:bx -> request header
;
; output:
;	ax = status
;
; comments:
;
; .calls: 
; .reads: 
; .writes: 
;
; .endfn
;======================================================================
	assume	cs:cseg,ds:cseg,es:nothing,ss:nothing
nullfun:
	mov	ax,0100h
	ret


	subttl set_wait - change the board's wait state value
	page
;======================================================================
; .func: set_wait - change the board's wait state value
;
; input:
;	al = wait state count (e.g. 0, 8, 16, 30)
;
; output:
;
; comments:
;
; .calls: 
; .reads: 
; .writes: 
;
; .endfn
;======================================================================
	assume	ds:nothing,es:nothing,ss:nothing
set_wait:
	push	ax
	push	dx
	mov	dx,wait_state_port
	not	al			; per intel doc
	and	al,speed_bits
	or	al,[ram_enable] 	; enable high speed ram for rom
	out	dx,al
	pop	dx
	pop	ax
	ret


	subttl intr13 - the int13 intercept handler
	page
;======================================================================
; .func: intr13 - the int13 intercept handler
;
; input:
;	int13 call registers
;
; output:
;	registers resulting from int13 call
;
; comments:
;	intercept int13 calls so more wait states can be programmed
;
; .calls: 
; .reads: 
; .writes: 
;
; .endfn
;======================================================================
	assume	ds:nothing,es:nothing,ss:nothing
intr13:
	push	ax
	cmp	dl,80h
	jnae	i13x1
	mov	al,cs:[hdwt]		; if hard disk
	jmp	short	i13x2
i13x1:
	mov	al,cs:[fdwt]		; must be floppy
i13x2:
	cmp	al,cs:[curwt]
	jna	i13x4
	call	set_wait		; wait state count is greater
i13x4:
	pop	ax
	pushf
	cli
	call	dword ptr cs:[orig13]	; call the original int13
	pushf
	push	ax
	mov	al,cs:[curwt]		; restore the original wait
	call	set_wait		; state count
	pop	ax
	popf
	retf 2


	subttl intrboot - intercept for reboot
	page
;======================================================================
; .func: intrboot - intercept for reboot
;
; input:
;
; output:
;
; comments:
;	intercept a jmp far f000:fff0 so a reboot happens at 30 wait states
;
; .calls: 
; .reads: 
; .writes: 
;
; .endfn
;======================================================================
	assume	ds:nothing,es:nothing,ss:nothing
intrboot:
	mov	cs:[ram_enable],0	; get rid of fast ram
	mov	al,30
	call	set_wait		; slow way down for the reboot
	jmp	dword ptr cs:[origboot]


	subttl ioctlrd - ioctl read function
	page
;======================================================================
; .func: ioctlrd - ioctl read function
;
; input:
;	es:bx -> request header
;
; output:
;	ax = status
;
; comments:
;
; .calls: 
; .reads: 
; .writes: 
;
; .endfn
;======================================================================
	assume	cs:cseg,ds:cseg,es:nothing,ss:nothing
ioctlrd:
	mov	ax,800ch
	cmp	es:[bx].rw_datasize,3
	jb	icr1
	les	bx,es:[bx].rw_dataptr	; get pointer to caller's buffer
	mov	al,cs:[curwt]
	mov	es:[bx],al		; report current wait value
	mov	al,cs:[hdwt]		; and the disk wait values
	mov	es:[bx+1],al
	mov	al,cs:[fdwt]
	mov	es:[bx+2],al
	mov	ax,0100h
icr1:
	ret


	subttl ioctlwrt - ioctl write function
	page
;======================================================================
; .func: ioctlwrt - ioctl write function
;
; input:
;	es:bx -> request header
;
; output:
;	ax = status
;
; comments:
;	handle a wait state change from the mispeed.com utility
;
; .calls: 
; .reads: 
; .writes: 
;
; .endfn
;======================================================================
	assume	cs:cseg,ds:cseg,es:nothing,ss:nothing
ioctlwrt:
	les	bx,es:[bx].rw_dataptr	; presumes one byte - the wait state
	mov	al,es:[bx]		; count.
	mov	cs:[curwt],al		; update the current value
	call	set_wait		; make the adjustment
	mov	ax,0100h
	ret

end_resident	label	byte
	nop				; to appease periscope

	subttl writestr - output string through int10
	page
;======================================================================
; .func: writestr - output string through int10
;
; input:
;	ds:si -> asciiz string
;
; output:
;
; comments:
;
; .calls: 
; .reads: 
; .writes: 
;
; .endfn
;======================================================================
	assume	ds:nothing,es:nothing,ss:nothing
writestr:
	push	ax
	push	bx
	push	si
	wrtloop:
wrt1:
	lodsb				; get char to write
	cmp	al,0
	je	wrt2
	mov	ah,14			; tty
	xor	bh,bh			; page 0
	int	10h
	jmp	short	wrt1
wrt2:
	pop	si
	pop	bx
	pop	ax
	ret

inbrd_romram	equ	5f0h		; high speed ram to replace the pc's
					; rom bios is initally addressed at
					; the top 64k of the 6th meg.

; the map_seg value must be on a 4k boundary
; the map_pages count must go into 16 evenly (16*4k = 64k, total copy amt)

; presumption: even on a mono system, the cga buffer are should not be
; given as freemem.

map_seg 	equ	0b800h	; using the cga area
map_pages	equ	4		; 16k

memptr	dd	0			; far pointer to memman functions
memman	db	'$$MEMDEV',0		; memman device name

initmsg db	13,10,'MINBRDPC.SYS - PC-MOS driver for Intel Inboard 386/PC              '  ;@@xlat
	db	13,10,'(c) Copyright 1989 The Software Link, Incorporated',13,10,0  ;@@xlat
nomemdev db	13,10,'Error - MINBRDPC.SYS requires the $386.SYS memdev           ',13,10,0  ;@@xlat
badparm  db	13,10,'Error - Invalid parameter              ',13,10,0  ;@@xlat
nspbios  db	13,10,'Error - non-standard BIOS             ',13,10,0	;@@xlat
noload	 db	13,10,'MINBRDPC.SYS not loaded          ',13,10,0  ;@@xlat

delimset db	',',20h,0		; default set of delimiters


	subttl testset - test al for inclusion within a set
	page
;======================================================================
; .func: testset - test al for inclusion within a set
;
; input:
;	ds:si -> asciiz string of test characters
;	al = character to test
;
; output:
;	zr if a match
;
; comments:
;	this routine cannot be used to test for a 0.
;	ax, ds and si are preserved.
;
; .calls: 
; .reads: 
; .writes: 
;
; .endfn
;======================================================================
	assume	ds:nothing,es:nothing,ss:nothing
testset:
	push	ax
	push	si
	dec	si
tst1:
	inc	si
	cmp	byte ptr [si],0
	je	tst2
	cmp	al,[si]
	je	tst3
	jmp	short	tst1		; keep trying
tst2:
	xor	al,al			; if exit the loop to here,
	cmp	al,1			; set the nz flag - no match
tst3:
	pop	si
	pop	ax
	ret


	subttl testdelims - check for whitespace
	page
;======================================================================
; .func: testdelims - check for whitespace
;
; input:
;	al = character to check against delimset
;
; output:
;	zr if a match
;
; comments:
;	a new delimset string can be declared if newdelim exists
;	al is preserved.  calls testset.
;
; .calls: 
; .reads: 
; .writes: 
;
; .endfn
;======================================================================
	assume	ds:nothing,es:nothing,ss:nothing
testdelims:
	push	si
	push	ds
	lea	si,[delimset]
	push	cs
	pop	ds
	call	testset
	pop	ds
	pop	si
	ret


	subttl dec2word - convert a decimal # to binary
	page
;======================================================================
; .func: dec2word - convert a decimal # to binary
;
; input:
;	ds:si -> string to convert
;
; output:
;	nc if no error
;	  ax = binary value
;	  ds:si -> first char after parameter
;	cy if error
;	  ax = 3  (rc_gerr)
;	  si undefined
;
; comments:
;	suitable as a type checking procedure for the parsing engine.
;
; .calls: 
; .reads: 
; .writes: 
;
; .endfn
;======================================================================
	assume	ds:nothing,es:nothing,ss:nothing
dec2word:
	push	cx
	push	dx
	xor	ax,ax			; ax will contain the result
	mov	ch,ah
	mov	cl,[si]
	cmp	cl,'0'
	jb	d2w1
	cmp	cl,'9'
	ja	d2w1
d2w2:
	mov	cl,[si] 		; bx is source address
	cmp	cl,'0'
	jb	d2w3
	cmp	cl,'9'
	ja	d2w3
	mov	dx,10
	mul	dx
	cmp	dx,0
	jne	d2w1
	sub	cl,'0'
	add	ax,cx
	inc	si
	jmp	short	d2w2
d2w3:

; check for a proper end of paramter: a delimiter or end of line code

	cmp	cl,13
	je	d2w4
	push	ax
	mov	al,cl
	call	testdelims
	pop	ax
	jnz	d2w1
d2w4:
	clc
	jmp	short	d2w5
d2w1:
	stc
	mov	ax,3			; rc_gerr
d2w5:
	pop	dx
	pop	cx
	ret


	subttl parse_parms - parse the parameter line
	page
;======================================================================
; .func: 
;
; input:
;	ds:si -> parameter line - terminated with a cr, uppercase
;
; output:
;	cy if error
;
; comments:
;
; .calls: 
; .reads: 
; .writes: 
;
; .endfn
;======================================================================
	assume	ds:nothing,es:nothing,ss:nothing
parse_parms:
	cld
prs1:
	lodsb
	cmp	al,' '
	je	prs1
	cmp	al,13
	je	prs3
	cmp	al,'/'
	jne	prs4
	lodsb
	cmp	al,'H'
	je	prs5
	cmp	al,'F'
	je	prs5
	cmp	al,'C'
	je	prs5
	jmp	short	prs4
prs5:
	mov	bl,al			; save for later
	lodsw
	cmp	ax,'=W'
	jne	prs4
	call	dec2word
	jc	prs4
	cmp	ax,30
	ja	prs4
	test	ax,1
	jnz	prs4
	cmp	bl,'H'
	jne	prs6
	mov	cs:[hdwt],al
	jmp	short	prs7
prs6:
	cmp	bl,'F'
	jne	prs8
	mov	cs:[fdwt],al
	jmp	short	prs7
prs8:					; must be for the current wait value
	mov	cs:[curwt],al
prs7:
	jmp	short	prs1		; recycle to top of loop
prs4:
	stc
prs3:
	ret


	subttl getmdev - get pointer to memdev data area
	page
;======================================================================
; .func: getmdev - get pointer to memdev data area
;
; input:
;	ds:si -> pointer to load memman address into
;
; output:
;	nc if no error, pointer initialized
;	cy if error, pointer indeterminate
;
; comments:
;
; .calls: 
; .reads: 
; .writes: 
;
; .endfn
;======================================================================
	assume	ds:nothing,es:nothing,ss:nothing
getmdev:
	push	ax
	push	bx
	push	cx
	push	dx
	push	es
	push	ds
	push	cs
	pop	ds
	mov	dx,offset [memman]
	mov	ax,3d02h		; open driver
	int	21h
	pop	ds
	jc	gmd1
	mov	bx,ax
	mov	ax,4400h
	int	21h
	xor	dh,dh
	or	dl,20h			; binary mode
	mov	ax,4401h
	int	21h
	mov	ah,3fh			; read first 4 bytes
	mov	cx,4
	mov	dx,si
	int	21h
	jc	gmd1
	push	bx
	les	bx,[si] 		; get pointer from data list
	mov	ax,es:[bx]
	mov	word ptr [si],ax
	mov	ax,es:[bx+2]
	mov	word ptr [si+2],ax
	pop	bx
	mov	ah,3eh
	int	21h
	jmp	short	gmd2		; take the current flags out
gmd1:
	stc
gmd2:
	pop	es
	pop	dx
	pop	cx
	pop	bx
	pop	ax
	ret


	subttl blk_copy - copy a block of memory
	page
;======================================================================
; .func: blk_copy - copy a block of memory
;
; input:
;	ax:si -> source string
;	bx:di -> destination string
;	cx = # of bytes to copy
;	direction flag set up or down as needed
;
; output:
;	si and di pointing just past the end of their strings
;	ax, bx and cx are preserved
;
; comments:
;
; .calls: 
; .reads: 
; .writes: 
;
; .endfn
;======================================================================
	assume	ds:nothing,es:nothing,ss:nothing
blk_copy:
	push	bx
	push	cx
	push	ds
	push	es
	cld
	mov	ds,ax
	mov	es,bx
	xor	bx,bx			; clear flag
	shr	cx,1			; convert bytes to words
					;setc bl			; record odd byte
	db	0fh,92h,0c3h
	shr	cx,1			; convert words to double words
					;setc bh			; record odd word
	db	0fh,92h,0c7h
	db	66h
	rep	movsw			; 32 bit move
	cmp	bh,0
	je	blc1
	movsw				; move an odd word
blc1:
	cmp	bl,0
	je	blc2
	movsb				; move an odd byte
blc2:
	pop	es
	pop	ds
	pop	cx
	pop	bx
	ret


	subttl init - initialize the driver
	page
;======================================================================
; .func: init - initialize the driver
;
; input:
;	es:bx -> request header, ds -> cseg
;
; output:
;
; comments:
;
; .calls: 
; .reads: 
; .writes: 
;
; .endfn
;======================================================================
	assume	cs:cseg,ds:cseg,es:nothing,ss:nothing
init:
	mov	si,offset initmsg	; report load
	call	writestr
	mov	si,offset [memptr]
	call	getmdev
	jnc	ini1
	mov	si,offset nomemdev
	call	writestr
	jmp		ini2
ini1:
	lds	si,es:[bx].in_parmbpb	; get a pointer to the parameter line
	cld
ini3:
	lodsb
	cmp	al,' '
	je	ini3a
	cmp	al,13
	jne	ini3
ini3a:
	dec	si
	call	parse_parms
	push	cs
	pop	ds
	jnc	ini5
	mov	si,offset badparm
	call	writestr
	jmp		ini2
ini5:
	mov	ax,0f000h
	mov	es,ax
	cmp	byte ptr es:[0fff0h],0eah
	je	ini6
	mov	si,offset nspbios
	call	writestr
	jmp		ini2
ini6:

; going to keep interrupts off for this entire copy operation.	if an
; int8 intercept does some direct video to b800, would corrupt our new
; rom image.  not going to ruin the show to miss a few irq0's during boot.

	cli
	mov	bx,inbrd_romram 	; starting physical bank number
	xor	si,si			; offset into the f000 segment
	cld
	mov	dx,64/4 		; total number of pages to copy
ini7:
	mov	ax,map_seg
	mov	es,ax
	assume	es:nothing		; setup for the phymap function
	mov	cx,map_pages
	mov	ah,5
	call	[memptr]		; remap the inboard's RAM
	add	bx,map_pages		; calc next starting bank number
	push	bx			; and save for next iteration
	mov	ax,map_pages
	mov	cl,12
	shl	ax,cl			; convert pages to bytes
	mov	cx,ax
	mov	ax,0f000h		; source segment in ax
	mov	bx,map_seg		; dest segment in bx
	xor	di,di			; offset within dest segment
	call	blk_copy		; do the copy
	pop	bx
	sub	dx,map_pages		; done yet?
	jnz	ini7

; at this point, the last set of pages in mapped into the transfer
; area.  determine the location of the rom boot address within this
; ram image (at f000:fff0 in the rom image) and make it point to
; the reboot intercept handler within this driver.

	mov	bx,map_pages
	mov	cl,12
	shl	bx,cl			; convert pages to bytes
	sub	bx,15			; make si point to the far jmp's
	mov	ax,map_seg		; operand at rom address f000:fff0
	mov	es,ax
	mov	ax,es:[bx]
	mov	cs:[origboot],ax	; save current far address
	mov	ax,es:[bx+2]
	mov	cs:[origboot+2],ax
	mov	word ptr es:[bx],offset intrboot  ; change to point to this driver
	mov	word ptr es:[bx+2],cs
	mov	cx,map_pages		; unmap the transfer area
	mov	ah,4
	call	[memptr]
	sti				; irq's can breathe now
	xor	ax,ax
	mov	es,ax
	cli
	mov	ax,es:[13h*4]
	mov	word ptr [orig13],ax
	mov	ax,es:[13h*4+2]
	mov	word ptr [orig13+2],ax
	mov	word ptr es:[13h*4],offset intr13
	mov	es:[13h*4+2],cs
	sti
	mov	al,cs:[curwt]		; enable ram and set to fastest
	call	set_wait		; operating speed (0 wait states)
	mov	dx,offset end_resident	; supply data for a normal
	mov	ax,100h 		; termination
	jmp	short	ini9
ini2:
	mov	si,offset noload
	call	writestr
	mov	dx,0			; don't allocate any memory
	mov	ax,800ch		; indicate general failure
ini9:
	les	bx,[devhdr]		; return the driver's ending point
	mov	word ptr es:[bx].in_endres,dx
	mov	word ptr es:[bx].in_endres+2,cs
	ret
cseg	ends
	end
