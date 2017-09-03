	include PAGE.INC
	title	MOSCLOCK - MOS device driver system clock

;-----------------------------------------------------------------------;
;									;
;		Development Specification				;
;									;
;									;
; Program Name: $$MOS.SYS		Assigned to: M Stitt		;
; Module Name:	MOSCLOCK		Assign date: 12/5/86		;
; Entry Points: n/a			Completed:   			;
; Entry From:	n/a							;
; Entry Method:	n/a							;
; Calls:	n/a							;
; Purpose:	MOS CLOCK device driver.				;
; Refer to:	n/a							;
; Last Update:								;
;									;
;									;
;	NOTE: I am making this driver behave normally with respect to	;
;	bytes requested and bytes returned.  PC-DOS is quirky in this 	;
;	regard.  When I open DOS's CLOCK$ driver and read 6 bytes, I 	;
;	get 11 bytes where the first byte is repeated 6 times.  If I 	;
;	request to read only 1 byte, I get the normal 6 byte set.	;
;	If we find any applications who are depending on this, will	;
;	need to make changes.						;
;									;
;-----------------------------------------------------------------------;
; MJS 10/9/87	fixed problem with clock driver not automaticlly 	;
;		advancing the date for all tasks.  Changed day counter 	;
;		in tcb (tcbcday) to a system global variable within 	;
;		the clock driver called curday.				;
;-----------------------------------------------------------------------;
; SAH 01/20/88  Change SCBSEG and ZERO seg to MGetXXXX macro		;
;		Optimize MOSINT1A for smaller size and faster speed	;
;-----------------------------------------------------------------------;
; sah\rdr 02/20/88 Move DDT Segment to MO2 Group			;
;-----------------------------------------------------------------------;

	include GROUP.INC
	.xlist
	page
;-----------------------------------------------------------------------;
; access to partition saved registers					;
;-----------------------------------------------------------------------;
	include	MOSREGS.INC

tcb	segment at 1234h
	include	MOSTCB.INC	; TCB definition
tcb	ends

gdata	segment	word public 'data'
	include	MOSSCBEX.INC	; specify all SCB items as external
gdata	ends
	.list

irq	segment	byte public 'data'

	dw	1Ah*4		; offset for this interrupt
origtim	dd	?		; save prior value
	dw	0		; we don't save changes, we leave them alone
	dw	mos:MOSINT1A	; initial value is here
	dw	0		; don't change back if application changes it

irq	ends

poll	segment	byte public 'data'
poll	ends

ddt     segment word public 'code2'
ddt     ends

	page
mosseg	segment	word public 'code1'
	assume	cs:mos,ds:grp,es:nothing,ss:tcb
	extrn	mosend:byte, scbfree:word, sbios:word

;	include	mosddclk.pub
	public	mosstdclk

mos10	macro
	pushf
	push	cs
	call	mosint10
	endm

;----------------------- Device Header ---------------------------------;

		org	0H
mosstdclk label	byte

	dd	-1
	dw	1000000000001000B	; Char, CLOCK$
	dw	mos:constrat
	dw	mos:conintr
	db	'CLOCK$  '		; Standard CONsole device



;----------------------- Function table --------------------------------;

funtbl	dw	init		; 0  Init
	dw	medck		; 1  Media check
	dw	bldbpb		; 2  Build BPB
	dw	ioctli		; 3  I/O control input
	dw	input		; 4  Input (read)
	dw	ndinput		; 5  Nondestructive input no wait
	dw	instat		; 6  Input status
	dw	inflsh		; 7  Input flush
	dw	output		; 8  Output (write)
	dw	outver		; 9  Output with verify
	dw	outstat		; 10 Output status
	dw	outflsh		; 11 Output flush
	dw	ioctlo		; 12 I/O control output


curday	dw	0	; MJS 10/9/87

	assume	cs:mos,ds:nothing,ss:nothing,es:nothing

MosInt1a:		; intercept sequence for Int 1A
	push	ds
	MGetSCB ds
	assume  ds:grp
	or	ah,ah
	jnz	Mia2
	pushf
	call	[origtim]	; Simulate INT
	or	al,al
	jz	Mia1

;SAH	mov	ds,[scbtcbpc]	; gain addressability to MOS data
;SAH	assume	ds:tcb
	inc	[curday]	; MJS 10/9/87
;	inc	[tcbcday]
Mia1:
	pop	ds
	assume	ds:nothing
	iret
Mia2:
	assume  ds:grp
	pushf
	call	[origtim]	; Simulate INT
	pop	ds
	assume	ds:nothing
	iret

	subttl	CONSTRAT - Console strategy routine
	page
;-----------------------------------------------------------------------;
;	This routine is the console drivers strategy routine, it just	;
;	queues the DWORD pointer to the request header.			;
;									;
;  On Entry:								;
;	ES:BX points to the device request header.			;
;									;
;  On Exit:								;
;	The request header pointer is saved.				;
;									;
;	The pointer tcbchdr is set in the current tasks TCB.		;
;	No global procedures called					;
;	No registers are changed					;
;-----------------------------------------------------------------------;
constrat proc	far

	assume	cs:mos,ds:nothing,es:nothing,ss:tcb

	mov	[tcbchdr],bx		; Save pointer in active TCB
	mov	[tcbchdr+2],es
	ret

constrat endp

	subttl	CONINTR - Console interrupt routine
	page
;-----------------------------------------------------------------------;
;	This is the console device drivers interrupt routine which will	;
;	process MOS's requested function.				;
;									;
;	No parms passed							;
;	Return values							;
;	Global data affected						;
;	Global procedures called					;
;	What registers are changed					;
;-----------------------------------------------------------------------;
conintr	proc	far

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

	les	bx,dword ptr [tcbchdr]	; Get Request Header pointer
	mov	al,es:[bx+2]		; Get command code
	cmp	al,12		; Check for invalid call
	ja	err1		; Yes, exit with error
	xor	ah,ah
	lea	bx,funtbl
	shl	ax,1
	add	bx,ax
	call	[bx]		; Execute appropriate routine
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
	les	bx,dword ptr [tcbchdr]	 ; Get Request Header pointer
	mov	word ptr es:[bx+3],8103H ; Return 'Unknown Command'
	jmp	rexit

conintr	endp

	subttl	MEDCK - Media Check
	page
;-----------------------------------------------------------------------;
;	This routine processes the Media Check call (=1)		;
;									;
;	No parms passed							;
;	Return values are set in the Request Header			;
;	No global data affected						;
;	No global procedures called					;
;	ES:BX used to point to RH					;
;-----------------------------------------------------------------------;
medck	proc	near

	les	bx,dword ptr [tcbchdr]	; Get pointer to RH
	mov	word ptr es:[bx+3],100H	; Return with 'DONE'
	ret

medck	endp

	subttl	BLDBPB - Build BIOS Parm Block
	page
;-----------------------------------------------------------------------;
;	This routine processes the Build BIOS Parameter Block call (=2)	;
;									;
;	No parms passed							;
;	Return values are set in the Request Header			;
;	No global data affected						;
;	No global procedures called					;
;	ES:BX used to point to RH					;
;-----------------------------------------------------------------------;
bldbpb	proc	near

	les	bx,dword ptr [tcbchdr]	; Get pointer to RH
	mov	word ptr es:[bx+3],100H	; Return 'Done'
	ret

bldbpb	endp

	subttl	IOCTLI - I/O Control Input
	page
;-----------------------------------------------------------------------;
;	This routine processes the IOCTL Input call (=3)		;
;									;
;	No parms passed							;
;	Return values are set in the Request Header			;
;	No global data affected						;
;	No global procedures called					;
;	ES:BX used to point to RH					;
;-----------------------------------------------------------------------;
ioctli	proc	near

	les	bx,dword ptr [tcbchdr]	 ; Get pointer to RH
	mov	word ptr es:[bx+3],8103H ; Return 'Done, error #3'
	ret

ioctli	endp

	subttl	INPUT - Input read
	page
;-----------------------------------------------------------------------;
;	This routine processes the input read call (=4)			;
;									;
;	No parms passed							;
;	Return values are set in the Request Header			;
;	No global data affected						;
;	No global procedures called					;
;	ES:BX used to point to RH					;
;-----------------------------------------------------------------------;

bigcomp proc		; subroutine used by the input sequence
	cmp	dx,si
	jb	bc1
	jne	bc2
	cmp	ax,di
	jb	bc1
bc2:
	clc
	ret
bc1:
	stc		; set CY to indicate dx:ax < si:di
	ret
bigcomp endp




input	proc	near
	les	bx,dword ptr [tcbchdr]	; Get pointer to RH
	mov	bp,es:[bx+14]		; Get offset transfer addrs
	mov	ax,es:[bx+16]	; Get seg transfer addrs
	mov	es,ax
	xor	ah,ah
	int	1ah		; get timer tick count
	mov	ax,[curday]	; MJS 10/9/87
;	mov	ax,[tcbcday]	; ref day count after 1a call
	mov	es:[bp],ax	; xfer day count to user's buffer
	mov	ax,dx
	mov	dx,cx

;	convert timer tick (dx:ax) to hour/min/sec/hund

	mov	cx,8
Inp4:
	sal	ax,1
	rcl	dx,1		; multiply ticks by 256 for more precision
	loop	Inp4		; in the division steps
	xor	cx,cx
	mov	si,100h
	mov	di,75dh
	call	bigcomp
	jc	Inp2		; if ax:dx < si:di then skip subtract loop
Inp3:
	sub	ax,75dh		; subtract ticks per hour (X256) to get hours
	sbb	dx,100h		; hex 100075D   
	inc	cx
	mov	si,100h
	mov	di,75dh
	call	bigcomp
	jnc	Inp3
Inp2:
	mov	es:[bp+3],cl	; store hours
	xor	cx,cx
	mov	si,4h
	mov	di,4463h
	call	bigcomp
	jc	Inp5		; if ax:dx < si:di then skip subtract loop
Inp6:
	sub	ax,4463h	; subtract ticks per minute (X256) to get 
	sbb	dx,4h		; minutes. hex 44463
	inc	cx
	mov	si,4h
	mov	di,4463h
	call	bigcomp
	jnc	Inp6
Inp5:
	mov	es:[bp+2],cl	; store minutes
	mov	cx,1234h	; ticks per minute (at 256x rate)
	div	cx
	mov	es:[bp+5],al	; store seconds

	mov	ax,dx
	xor	dx,dx
	mov	cx,47
	div	cx
	mov	es:[bp+4],al	; store hundreths of seconds
	les	bx,dword ptr [tcbchdr]	; Get pointer to RH
	mov	word ptr es:[bx+3],100H	; Return 'Done'
	ret
input	endp

	subttl	NDINPUT - Nondestructive input no wait
	page
;-----------------------------------------------------------------------;
;	This routine processes the nondestructive input no wait call	;
;	(=5)								;
;									;
;	No parms passed							;
;	Return values are set in the Request Header			;
;	No global data affected						;
;	No global procedures called					;
;	ES:BX used to point to RH					;
;-----------------------------------------------------------------------;
ndinput	proc	near

	les	bx,dword ptr [tcbchdr]	 ; Get pointer to RH
	mov	word ptr es:[bx+3],8103H ; Return 'Done, error #3'
	ret

ndinput	endp

	subttl	INSTAT - Input status
	page
;-----------------------------------------------------------------------;
;	This routine processes the Input Status call (=6)		;
;									;
;	No parms passed							;
;	Return values are set in the Request Header			;
;	No global data affected						;
;	No global procedures called					;
;	ES:BX used to point to RH					;
;-----------------------------------------------------------------------;
instat	proc	near

	les	bx,dword ptr [tcbchdr]	; Get pointer to RH
	mov	word ptr es:[bx+3],100H	; Return 'Done'
	ret

instat	endp

	subttl	INFLSH - Input Flush
	page
;-----------------------------------------------------------------------;
;	This routine processes the Input Flush call (=7)		;
;									;
;	No parms passed							;
;	Return values are set in the Request Header			;
;	No global data affected						;
;	No global procedures called					;
;	ES:BX used to point to RH					;
;-----------------------------------------------------------------------;
inflsh	proc	near

	les	bx,dword ptr [tcbchdr]	 ; Get pointer to RH
	mov	word ptr es:[bx+3],8103H ; Return 'Done, error #3'
	ret

inflsh	endp

	subttl	OUTPUT - Output write
	page
;-----------------------------------------------------------------------;
;	This routine processes the Output write call (=8)		;
;									;
;	No parms passed							;
;	Return values are set in the Request Header			;
;	No global data affected						;
;	No global procedures called					;
;	ES:BX used to point to RH					;
;-----------------------------------------------------------------------;

output	proc	near
	les	bx,dword ptr [tcbchdr]	; Get pointer to RH
	mov	bp,es:[bx+14]		; Get offset transfer addrs
	mov	ax,es:[bx+16]	; Get seg transfer addrs
	mov	es,ax
	xor	ch,ch
	mov	ax,47
	mov	cl,es:[bp+4]	; get hundreths of seconds
	mul	cx
	add	ax,0ffh
	adc	dx,0
	and	ax,0ff00h
	mov	si,dx
	mov	di,ax
	xor	ch,ch
	mov	ax,1234h
	mov	cl,es:[bp+5]	; get seconds
	mul	cx
	add	ax,0ffh
	adc	dx,0
	and	ax,0ff00h
	add	di,ax
	adc	si,dx
	xor	ax,ax
	xor	dx,dx
	xor	ch,ch
	mov	cl,es:[bp+2]	; get minutes
	jcxz	Ot4
Ot3:
	add	ax,4463h
	adc	dx,4
	loop	Ot3
Ot4:
	add	ax,0ffh
	adc	dx,0
	and	ax,0ff00h
	add	di,ax
	adc	si,dx
	xor	ax,ax
	xor	dx,dx
	xor	ch,ch
	mov	cl,es:[bp+3]	; get hours
	jcxz	Ot1
Ot2:
	add	ax,75dh
	adc	dx,100h
	loop	Ot2
Ot1:
	add	ax,0ffh
	adc	dx,0
	and	ax,0ff00h
	add	ax,di
	adc	dx,si
	mov	cx,8
Ot5:
	sar	dx,1
	rcr	ax,1
	loop	Ot5
	cmp	dx,18h
	jne	Ot6
	cmp	ax,0afh
	jna	Ot6
	mov	ax,0afh
Ot6:
	mov	cx,dx
	mov	dx,ax
	mov	ah,01
	int	1ah		; set the clock count

	mov	ax,es:[bp]	; set day counter
	mov	[curday],ax	; MJS 10/9/87
;	mov	[tcbcday],ax
	les	bx,dword ptr [tcbchdr]	; Get pointer to RH
	mov	word ptr es:[bx+3],100H	; Return 'Done'
	ret
output	endp


	subttl	OUTVER - Output with Verify
	page
;-----------------------------------------------------------------------;
;	This routine processes the Output with verify call (=9)		;
;									;
;	No parms passed							;
;	Return values are set in the Request Header			;
;	No global data affected						;
;	No global procedures called					;
;	ES:BX used to point to RH					;
;-----------------------------------------------------------------------;
outver	proc	near

	jmp	output			; Same as OUTPUT

outver	endp

	subttl	OUTSTAT - Output status
	page
;-----------------------------------------------------------------------;
;	This routine processes the Output status call (=10)		;
;									;
;	No parms passed							;
;	Return values are set in the Request Header			;
;	No global data affected						;
;	No global procedures called					;
;	ES:BX used to point to RH					;
;-----------------------------------------------------------------------;
outstat	proc	near

	les	bx,dword ptr [tcbchdr]	; Get pointer to RH
	mov	word ptr es:[bx+3],100H	; Return 'Done' & 'Not Busy'
	ret

outstat	endp

	subttl	OUTFLSH - Output flush
	page
;-----------------------------------------------------------------------;
;	This routine processes the Output flush call (=11)		;
;									;
;	No parms passed							;
;	Return values are set in the Request Header			;
;	No global data affected						;
;	No global procedures called					;
;	ES:BX used to point to RH					;
;-----------------------------------------------------------------------;
outflsh	proc	near

	les	bx,dword ptr [tcbchdr]	; Get pointer to RH
	mov	word ptr es:[bx+3],100H	; Return 'Done'
	ret

outflsh	endp

	subttl	IOCTLO - I/O Control Output
	page
;-----------------------------------------------------------------------;
;	This routine processes the IOCTL Output call (=12)		;
;									;
;	No parms passed							;
;	Return values are set in the Request Header			;
;	No global data affected						;
;	No global procedures called					;
;	ES:BX used to point to RH					;
;-----------------------------------------------------------------------;
ioctlo	proc	near

	les	bx,dword ptr [tcbchdr]	; Get pointer to RH
	mov	word ptr es:[bx+3],100H	; Return 'Done'
	ret

ioctlo	endp

endres	label	byte

	subttl	INIT - Init driver
	page
;-----------------------------------------------------------------------;
;	This routine will initialize the clock device driver.		;
;									;
;	No Parms passed							;
;	No Return values						;
;	No Global data affected						;
;	No Global procedures called					;
;	What registers are changed					;
;-----------------------------------------------------------------------;
	assume	cs:mos,ds:mos,es:nothing
init	proc	near

	xor	cx,cx		; reset the timer count
	xor	dx,dx
	mov	ah,01
	int	1ah
		
	mov	bx,[tcbchdr]	; Get Request Header pointer
	lea	dx,endres
	mov	es:[bx+14],dx	; Set ending address of driver
	mov	es:[bx+16],cs
	mov	word ptr es:[bx+3],100H	; Return with 'DONE'
	ret				; End of INIT

init	endp

mosseg	ends
	end
                                                                                                       