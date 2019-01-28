	include page.inc
	title	mosclock - mos device driver system clock
comment ^===============================================================
		    development specification

 program name:	$$mos.sys		assigned to: m stitt
 module name:	mosclock		assign date: 12/5/86
 entry points:	n/a			completed:
 entry from:	n/a
 entry method:	n/a
 calls:		n/a
 purpose:	mos clock device driver.
 refer to:	n/a
 last update:	08/18/1992
========================================================================

note: I am making this driver behave normally with respect to bytes
requested and bytes returned.  pc-dos is quirky in this regard.  when
i open dos's CLOCK$ driver and read 6 bytes, I get 11 bytes where the
first byte is repeated 6 times.	if i request to read only 1 byte, i
get the normal 6 byte set.  if we find any applications who are
depending on this, will need to make changes.

=======================================================================

mjs 10/9/87	fixed problem with clock driver not automaticlly
		advancing the date for all tasks.  changed day counter
		in tcb (tcbcday) to a system global variable within
		the clock driver called curday.

sah 01/20/88	change scbseg and zero seg to mgetxxxx macro
		optimize mosint1a for smaller size and faster speed

sah\rbr 02/20/88 move ddt segment to mo2 group

sah 06/12/91	corrections for wordperfect office, also optimized
		code so that it will be smaller.

sah 03/19/92	stackbiasing corrections for int 1ah and lanlink pro

================ 5.01 Kernel Ends Here ====================================

mjs 08/18/92	clean up segment declarations

mjs 08/26/92	delete reference to scbfree

======================================================================^

.xlist
;	include mosddclk.asm
	include group.inc
	include macros.inc
	include mosregs.inc

tcb	segment at 1234h
	include mostcb.inc
tcb	ends

gdata	segment
	include mosscbex.inc
gdata	ends
.list

irq	segment

	dw	1ah*4			; offset for this interrupt
origtim dd	?			; save prior value
	dw	0			; we don't save changes, we leave them alone
	dw	mos:mosint1a		; initial value is here
	dw	0			; don't change back if application changes it

irq	ends

;======================================================== mos segment
if 0 eq 0
segment_num = 1
endif
mosseg	segment
	assume	cs:mos,ds:grp,es:nothing,ss:tcb
	extrn	mosend:byte, sbios:word
	extrn	mossaver:near, mosrestore:near

	public	mosstdclk
	org	0h
mosstdclk label byte
	dd	-1
	dw	1000000000001000b	; char, clock$
	dw	mos:constrat
	dw	mos:conintr
	db	'CLOCK$  '		; standard console device

; function table

funtbl	dw	cinit			; 0  init
	dw	donfun			; 1  media check
	dw	donfun			; 2  build bpb
	dw	errfun			; 3  i/o control input
	dw	input			; 4  input (read)
	dw	errfun			; 5  nondestructive input no wait
	dw	donfun			; 6  input status
	dw	errfun			; 7  input flush
	dw	output			; 8  output (write)
	dw	outver			; 9  output with verify
	dw	donfun			; 10 output status
	dw	donfun			; 11 output flush
	dw	donfun			; 12 i/o control output

curday	dw	0

	assume	cs:mos,ds:nothing,ss:nothing,es:nothing

	subttl mosint1a -- intercept sequence for int 1a
	page
;======================================================================
;,fs
; mosint1a -- intercept sequence for int 1a
;
; in:	
;
; out:	
;
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:nothing
mosint1a proc far
	push	ds
	mgetscb ds
	assume	ds:grp
	mov	ds,[scbtcbpc]
	assume	ds:tcb
	push	word ptr [tcbstkp]
	sub	word ptr [tcbstkp],128
	call	mossaver
	call	mosrestore
	pop	word ptr [tcbstkp]
	mgetscb ds
	assume	ds:grp
	or	ah,ah
	jnz	mia2
	pushf
	call	[origtim]		; simulate int
	or	al,al
	jz	mia1
	inc	[curday]
mia1:
	pop	ds
	assume	ds:nothing
	iret
mia2:
	assume	ds:grp
	pushf
	call	[origtim]		; simulate int
	pop	ds
	assume	ds:nothing
	iret
mosint1a endp

	subttl constrat - console strategy routine
	page
;======================================================================
;,fs
; constrat - console strategy routine
;
; this routine is the console drivers strategy routine, it just
; queues the dword pointer to the request header.
;
; in:	es:bx points to the device request header.
;	ss -> tcb
;
; out:	the request header pointer is saved.
;
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:tcb
constrat proc	far
	mov	[tcbchdr],bx		; save pointer in active tcb
	mov	[tcbchdr+2],es
	ret
constrat endp

	subttl conintr - console interrupt routine
	page
;======================================================================
;,fs
; conintr - console interrupt routine
;
; this is the console device drivers interrupt routine which will
; process mos's requested function.
;
; in:	ss -> tcb
;
; out:	
;
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:tcb
conintr proc	far
	push	ax
	push	bx
	push	cx
	push	dx
	push	es
	push	ds
	push	di
	push	si
	push	bp
	push	cs
	pop	ds			; use is calling routines
	assume	ds:mos
	les	bx,dword ptr [tcbchdr]	; get request header pointer
	mov	al,es:[bx+2]		; get command code
	cmp	al,12			; check for invalid call
	ja	err1			; yes, exit with error
	xor	ah,ah
	lea	bx,funtbl
	shl	ax,1
	add	bx,ax
	call	[bx]			; execute appropriate routine
rexit:
	pop	bp
	pop	si
	pop	di
	pop	ds
	pop	es
	pop	dx
	pop	cx
	pop	bx
	pop	ax
	ret
err1:
	les	bx,dword ptr [tcbchdr]	; get request header pointer
	mov	word ptr es:[bx+3],8103h; return 'Unknown Command'
	jmp	rexit
conintr endp

	subttl	donfun - this function handle also all successful functs
donfun	proc	near
	les	bx,dword ptr [tcbchdr]	; get pointer to rh
	mov	word ptr es:[bx+3],100h ; return with 'DONE'
	ret
donfun	endp

	subttl	errfun - this function handle also all unsuccessful functs
errfun	proc	near
	les	bx,dword ptr [tcbchdr]	; get pointer to rh
	mov	word ptr es:[bx+3],8103h; return 'Done, error #3'
	ret
errfun	endp

	subttl bigcomp -- compare doubleword
	page
;======================================================================
;,fs
; bigcomp -- compare doubleword
;
; in:	ax:dx = 1st dword
;	di:si = 2nd dword
;
; out:	cy indicates dx:ax < si:di
;
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:nothing
bigcomp proc				; subroutine used by the input sequence
	cmp	dx,si
	jb	bc1
	jne	bc2
	cmp	ax,di
	jb	bc1
bc2:
	clc
	ret
bc1:
	stc				; set cy to indicate dx:ax < si:di
	ret
bigcomp endp

	subttl input -- input read function
	page
;======================================================================
;,fs
; input -- input read function
;
; in:	ss -> tcb
;	ds -> mos
;
; out:	
;
;,fe
;======================================================================
	assume	ds:mos,es:nothing,ss:tcb
input	proc	near
	les	bx,dword ptr [tcbchdr]	; get pointer to rh
	mov	bp,es:[bx+14]		; get offset transfer addrs
	mov	ax,es:[bx+16]		; get seg transfer addrs
	mov	es,ax
	xor	ah,ah
	int	1ah			; get timer tick count
	mov	ax,[curday]		; mjs 10/9/87
	mov	es:[bp],ax		; xfer day count to user's buffer
	mov	ax,dx
	mov	dx,cx

; convert timer tick (dx:ax) to hour/min/sec/hund

	mov	cx,8
inp4:
	sal	ax,1
	rcl	dx,1			; multiply ticks by 256 for more precision
	loop	inp4			; in the division steps
	xor	cx,cx
	mov	si,100h
	mov	di,75dh
	call	bigcomp
	jc	inp2			; if ax:dx < si:di then skip subtract loop
inp3:
	sub	ax,75dh 		; subtract ticks per hour (x256) to get hours
	sbb	dx,100h 		; hex 100075d
	inc	cx
	mov	si,100h
	mov	di,75dh
	call	bigcomp
	jnc	inp3
inp2:
	mov	es:[bp+3],cl		; store hours
	xor	cx,cx
	mov	si,4h
	mov	di,4463h
	call	bigcomp
	jc	inp5			; if ax:dx < si:di then skip subtract loop
inp6:
	sub	ax,4463h		; subtract ticks per minute (x256) to get
	sbb	dx,4h			; minutes. hex 44463
	inc	cx
	mov	si,4h
	mov	di,4463h
	call	bigcomp
	jnc	inp6
inp5:
	mov	es:[bp+2],cl		; store minutes
	mov	cx,1234h		; ticks per minute (at 256x rate)
	div	cx
	mov	es:[bp+5],al		; store seconds
	mov	ax,dx
	xor	dx,dx
	mov	cx,47
	div	cx
	mov	es:[bp+4],al		; store hundreths of seconds
	les	bx,dword ptr [tcbchdr]	; get pointer to rh
	mov	word ptr es:[bx+3],100h ; return 'Done'
	ret
input	endp

	subttl output - output write
	page
;======================================================================
;,fs
; output - output write
;
; in:	ss -> tcb
;	ds -> mos
;
; out:	
;
;,fe
;======================================================================
	assume	ds:mos,es:nothing,ss:tcb
outver	label	near
output	proc	near
	les	bx,dword ptr [tcbchdr]	; get pointer to rh
	mov	bp,es:[bx+14]		; get offset transfer addrs
	mov	ax,es:[bx+16]		; get seg transfer addrs
	mov	es,ax
	xor	ch,ch
	mov	ax,47
	mov	cl,es:[bp+4]		; get hundreths of seconds
	mul	cx
	add	ax,0ffh
	adc	dx,0
	and	ax,0ff00h
	mov	si,dx
	mov	di,ax
	xor	ch,ch
	mov	ax,1234h
	mov	cl,es:[bp+5]		; get seconds
	mul	cx
	add	ax,0ffh
	adc	dx,0
	and	ax,0ff00h
	add	di,ax
	adc	si,dx
	xor	ax,ax
	xor	dx,dx
	xor	ch,ch
	mov	cl,es:[bp+2]		; get minutes
	jcxz	ot4
ot3:
	add	ax,4463h
	adc	dx,4
	loop	ot3
ot4:
	add	ax,0ffh
	adc	dx,0
	and	ax,0ff00h
	add	di,ax
	adc	si,dx
	xor	ax,ax
	xor	dx,dx
	xor	ch,ch
	mov	cl,es:[bp+3]		; get hours
	jcxz	ot1
ot2:
	add	ax,75dh
	adc	dx,100h
	loop	ot2
ot1:
	add	ax,0ffh
	adc	dx,0
	and	ax,0ff00h
	add	ax,di
	adc	dx,si
	mov	cx,8
ot5:
	sar	dx,1
	rcr	ax,1
	loop	ot5
	cmp	dx,18h
	jne	ot6
	cmp	ax,0afh
	jna	ot6
	mov	ax,0afh
ot6:
	mov	cx,dx
	mov	dx,ax
	mov	ah,01
	int	1ah			; set the clock count

	mov	ax,es:[bp]		; set day counter
	mov	[curday],ax		; mjs 10/9/87
	les	bx,dword ptr [tcbchdr]	; get pointer to rh
	mov	word ptr es:[bx+3],100h ; return 'Done'
	ret
output	endp

endres	label	byte

	subttl cinit - init driver
	page
;======================================================================
;,fs
; cinit - init driver
;
; in:	ss -> tcb
;	ds -> mos
;
; out:	
;
;,fe
;======================================================================
	assume	ds:mos,es:nothing,ss:tcb
cinit	proc	near
	xor	cx,cx			; reset the timer count
	xor	dx,dx
	mov	ah,01
	int	1ah
	mov	bx,[tcbchdr]		; get request header pointer
	mov	es:[bx+14],offset endres; set ending address of driver
	mov	es:[bx+16],cs
	mov	word ptr es:[bx+3],100h ; return with 'DONE'
	ret				; end of init
cinit	endp

mosseg	ends
	end

