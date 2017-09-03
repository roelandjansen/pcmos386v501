	include PAGE.INC
	title	MOSDEVS - MOS device drivers: LPTs, COMs, and NUL
;-----------------------------------------------------------------------;
;		       Development Specification			;
;									;
; Program Name: MOS.COM			Assigned to: Martin Stitt	;
; Module Name:	MOSDEVS			Assign date: 01/12/87		;
; Entry Points: n/a			Completed:   			;
; Entry From:	n/a							;
; Entry Method:	n/a							;
; Calls:	n/a							;
; Purpose:	Provide device drivers for LPT1, LPT2, LPT3, PRN	;
;		COM, AUX, and NUL.					;
; Refer to:	n/a							;
; Last Update:	01/12/87						;
;-----------------------------------------------------------------------;
;    07/10/87 SAH Added code out device out to retries up to 256times   ;
;-----------------------------------------------------------------------;
;    01/20/88 SAH Change SCBSEG and ZERO seg to MGetXXX macros		;
;-----------------------------------------------------------------------;
; sah\rdr 02/20/88 Move DDT Segment to MO2 Group			;
;-----------------------------------------------------------------------;
; mjs 10/21/88	Reordered the headers in here to accomodate the 	;
;		corrections done in mosddint for device drivers with	;
;		more than one header per file.  Also trimmed out	;
;		unnecessary code.					;
;-----------------------------------------------------------------------;
; mjs 03/03/89	Modified error testing after the int17, function 3 call	;
;		to ignore a bad return status if the # of chars printed	;
;		as returned by cx is equal to the request count.	;
;-----------------------------------------------------------------------;
; RKG 05/15/89	Correct error testing after printing			;
;     05/22/89	Correct lpt count on errors				;
;-----------------------------------------------------------------------;

	include GROUP.INC
	include macros.inc
	include	mosdevs.pub

	subttl	group segments and include block definitions
	page

;-----------------------------------------------------------------------;
; access to partition saved registers					;
;-----------------------------------------------------------------------;
	include	MOSREGS.INC

.xlist	
tcb	segment at 1234h
	include	MOSTCB.INC	; TCB definition
tcb	ends

gdata	segment	word public 'data'
gdata	ends
.list

irq	segment	byte public 'data'
irq	ends

poll	segment	byte public 'data'
poll	ends

ddt     segment word public 'code2'
ddt     ends

	page
mosseg	segment	word public 'code1'
	assume	cs:mos,ds:grp,es:nothing,ss:tcb

	extrn	mosend:byte, scbfree:word, sbios:word

	public scbcom24

	subttl	device headers
	page

header	macro	p1,p2,p3,p4

scb&p1	label	dword
	dw	mos:scb&p2
	dw	0
	dw	1000000000000000b	; Char device
	dw	mos:devstrat
	dw	mos:p3&intr
	db	p4
	endm

		org	0H

header	com24,com23,com24,'COM24   '
header	com23,com22,com23,'COM23   '
header	com22,com21,com22,'COM22   '
header	com21,com20,com21,'COM21   '
header	com20,com19,com20,'COM20   '
header	com19,com18,com19,'COM19   '
header	com18,com17,com18,'COM18   '
header	com17,com16,com17,'COM17   '
header	com16,com15,com16,'COM16   '
header	com15,com14,com15,'COM15   '
header	com14,com13,com14,'COM14   '
header	com13,com12,com13,'COM13     '
header	com12,com11,com12,'COM12   '
header	com11,com10,com11,'COM11   '
header	com10,com9,com10,'COM10   '
header	com9,com8,com9,'COM9    '
header	com8,com7,com8,'COM8    '
header	com7,com6,com7,'COM7    '
header	com6,com5,com6,'COM6    '
header	com5,com4,com5,'COM5    '
header	com4,com3,com4,'COM4    '
header	com3,com2,com3,'COM3    '
header	com2,aux,com2,'COM2    '
header	aux,com1,com1,'AUX     '
header	com1,lpt3,com1,'COM1    '
header	lpt3,lpt2,lp3,'LPT3    '
header	lpt2,prn,lp2,'LPT2    '
header	prn,lpt1,lp1,'PRN     '
header	lpt1,nul,lp1,'LPT1    '

scbnul	label	dword

	dd	-1
	dw	1000000000000100b	; Char device
	dw	mos:devstrat
	dw	mos:nulintr
	db	'NUL     '

	subttl	DEVSTRAT - strategy routine for printers, com, aux and nul
	page
;-----------------------------------------------------------------------;
;	This routine is the device drivers strategy routine, it just	;
;	queues the DWORD pointer to the request header.			;
;									;
;  On Entry:								;
;	ES:BX points to the device request header.			;
;									;
;  On Exit:								;
;	The request header pointer is saved.				;
;									;
;	The pointer TCBDEVHDR is set in the current tasks TCB.		;
;	No global procedures called					;
;	No registers are changed					;
;-----------------------------------------------------------------------;

devstrat proc	far
	mov	[tcbdevhdr],bx		; Save pointer in active TCB
	mov	[tcbdevhdr+2],es
	ret
devstrat endp

	subttl	intr handlers
	page
;-----------------------------------------------------------------------;
; intr handlers for each supported device.				;
;									;
; entry parms: none							;
;									;
; exit parms: tcbdnum is set to identify the device to be processed.	;
;-----------------------------------------------------------------------;

lp1intr:	
	mov	[tcbdnum],1
	jmp	devsintrx
lp2intr:	
	mov	[tcbdnum],2
	jmp	devsintrx
lp3intr:
	mov	[tcbdnum],3
	jmp	devsintrx
com1intr:
	mov	[tcbdnum],4
	jmp	devsintrx
com2intr:
	mov	[tcbdnum],5
	jmp	devsintrx
com3intr:
	mov	[tcbdnum],6
	jmp	devsintrx
com4intr:
	mov	[tcbdnum],7
	jmp	devsintrx
com5intr:
	mov	[tcbdnum],8
	jmp	devsintrx
com6intr:
	mov	[tcbdnum],9
	jmp	devsintrx
com7intr:
	mov	[tcbdnum],10
	jmp	devsintrx
com8intr:
	mov	[tcbdnum],11
	jmp	devsintrx
com9intr:
	mov	[tcbdnum],12
	jmp	devsintrx
com10intr:
	mov	[tcbdnum],13
	jmp	devsintrx
com11intr:
	mov	[tcbdnum],14
	jmp	devsintrx
com12intr:
	mov	[tcbdnum],15
	jmp	devsintrx
com13intr:
	mov	[tcbdnum],16
	jmp	devsintrx
com14intr:
	mov	[tcbdnum],17
	jmp	devsintrx
com15intr:
	mov	[tcbdnum],18
	jmp	devsintrx
com16intr:
	mov	[tcbdnum],19
	jmp	devsintrx
com17intr:
	mov	[tcbdnum],20
	jmp	devsintrx
com18intr:
	mov	[tcbdnum],21
	jmp	devsintrx
com19intr:
	mov	[tcbdnum],22
	jmp	devsintrx
com20intr:
	mov	[tcbdnum],23
	jmp	devsintrx
com21intr:
	mov	[tcbdnum],24
	jmp	devsintrx
com22intr:
	mov	[tcbdnum],25
	jmp	devsintrx
com23intr:
	mov	[tcbdnum],26
	jmp	devsintrx
com24intr:
	mov	[tcbdnum],27
	jmp	devsintrx
nulintr:
	mov	[tcbdnum],0
devsintrx:
	call	devsintr
	retf

;------------------------ Function table  -------------------------------;

funtbl	dw	init		; 0  Init
	dw	devstub		; 1  Media check
	dw	devstub		; 2  Build BPB
	dw	devstub		; 3  I/O control input
	dw	input		; 4  Input (read)
	dw	devstub		; 5  Nondestructive input no wait
	dw	devstub		; 6  Input status
	dw	devstub		; 7  Input flush
	dw	output		; 8  Output (write)
	dw	devstub		; 9  Output with verify
	dw	devstub		; 10 Output status
	dw	devstub		; 11 Output flush
	dw	devstub		; 12 I/O control output

	subttl	DEVSINTR - main interrupt routine
	page
;-----------------------------------------------------------------------;
;	This is the main device driver interrupt routine which will	;
;	process MOS's requested function.				;
;									;
;	No parms passed							;
;	Return values							;
;	Global data affected						;
;	Global procedures called					;
;	What registers are changed					;
;-----------------------------------------------------------------------;

devsintr proc near	
	push	ax
	push	bx
	push	cx
	push	dx
	push	si
	push	di
	push	es
	push	ds
	push	cs
	pop	ds		; for call to routine		
	assume	ds:mos
	les	bx,dword ptr [tcbdevhdr]	; Get Request Header pointer
	mov	al,es:[bx+2]			; Get command code
	cmp	al,12		; Check for invalid call
	ja	err1		; Yes, exit with error
	xor	ah,ah
	lea	bx,funtbl
	shl	ax,1
	add	bx,ax
	call	[bx]		; Execute appropriate routine
rexit:
	pop	ds
	pop	es
	pop	di
	pop	si
	pop	dx
	pop	cx
	pop	bx
	pop	ax
	ret
err1:
	les	bx,dword ptr [tcbdevhdr]	; Get Request Header pointer
	mov	word ptr es:[bx+3],8013H	; Return 'Unknown Command'
	jmp	rexit
devsintr endp

	subttl	devstub - for functions not handled
	page
;-----------------------------------------------------------------------;
; devstub - for functions not handled					;
;									;
;	No parms passed							;
;	Return values are set in the Request Header			;
;	No global data affected						;
;	No global procedures called					;
;	ES:BX used to point to RH					;
;-----------------------------------------------------------------------;

devstub:
	les	bx,dword ptr [tcbdevhdr]	; Get pointer to RH
	mov	word ptr es:[bx+3],100H		; Return with 'DONE'
	ret

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

input	proc	near
	cmp	[tcbdnum],0	; nul device ?
	je	donul
	cmp	[tcbdnum],3
	ja	docom
donul:
	les	bx,dword ptr [tcbdevhdr]	; Get pointer to RH
	mov	word ptr es:[bx+3],100H		; Return 'Done'
	ret
docom:
	mov	dl,[tcbdnum]
	xor	dh,dh
	sub	dx,4		; set dx for com number			
	les	bx,dword ptr [tcbdevhdr]	; Get pointer to RH
	mov	cx,es:[bx+18]	; get byte count
	mov 	di,es:[bx+14]	; get offset of user buffer
	mov	ax,es:[bx+16]	; get segment of user buffer
	mov	es,ax		; es:di addresses user buffer
	cld
	push	di		; save di for bytes sent accounting
in1a:
	mov	ah,2
	int	14h		; read a char from the com port	
	test	ah,80h
	jnz	in1b		; jmp if error
	stosb			; write the char to the users buffer
	loop	in1a
				; normal end of loop - calc bytes sent
	les	bx,dword ptr [tcbdevhdr]	; Get pointer to RH
	mov	word ptr es:[bx+3],100H		; Return 'Done'
	jmp	in1c
in1b:				; error handling
	les	bx,dword ptr [tcbdevhdr]	; Get pointer to RH
	mov	word ptr es:[bx+3],800bH	; Return read error
in1c:
	pop	cx		
	sub	di,cx
	mov 	word ptr es:[bx+18],di		; return bytes sent
	ret
input	endp

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
	cmp	[tcbdnum],0	; nul device ?
	jne	notnul
	les	bx,dword ptr [tcbdevhdr]	; Get pointer to RH
	mov	word ptr es:[bx+3],100H		; Return 'Done'
	ret
notnul:
	mov	dl,[tcbdnum]
	xor	dh,dh
	cmp	dl,3		; printing or com'ing ?
	ja	setcomdx
	dec	dx		; set dx for printer number
	jmp	dxset
setcomdx:
	sub	dx,4		; set dx for com number			
dxset:
	les	bx,dword ptr [tcbdevhdr]	; Get pointer to RH
	mov	cx,es:[bx+18]	; get byte count
	mov 	si,es:[bx+14]	; get offset of user buffer
	mov	ax,es:[bx+16]	; get segment of user buffer
	mov	ds,ax		; ds:si addresses user buffer
	cld
	push	si		; save si for bytes sent accounting
	cmp	[tcbdnum],3
	ja	ot1f		; printing or com'ing ?
	mov	ah,3		; use string printing function
	int	17h		; send char to the printer
;	and	ah,00111001b	; mask off unused bits of status byte	R890515
;	xor	ah,00010000b	; invert not busy and printer select bits
;	jz	loopend		; zr if no error			R890515
	add	si, cx		; for length calc			R890515
	cmp	cx,es:[bx+18]	; if get an error but all bytes sent
	je	loopend		; then don't want to retry
	inc	si		; past char that erred 			R890522
	jmp	ot1b		; jmp to error handler
ot1f:
	lodsb			; read a byte from user's buffer
	push    cx
	mov	cx, 256		; loop 256 times (it should be an error)
oteloop:
	push    ax    
	push    cx
	mov	ah,1
	int	14h		; send char to the com port
	pop     cx
	test	ah,80h
	jz      oteok
	pop	ax
	loop    oteloop		; loop for retries
	pop	cx
	jmp	ot1b		; jmp if error
oteok:
	pop	ax
	pop	cx
	loop	ot1f
loopend:			; normal end of loop
	les	bx,dword ptr [tcbdevhdr]	; Get pointer to RH
	mov	word ptr es:[bx+3],100H		; Return 'Done'
	jmp	outend
ot1b:				; error handling
	les	bx,dword ptr [tcbdevhdr]	; Get pointer to RH
	mov	word ptr es:[bx+3],8002H	; Return 'error'
	dec	si
outend:
;	MAKING Printer and Console results similar shortens code	R890515
;	cmp	[tcbdnum],3	
;	ja	ot1g		; if not printing - jmp to ot1g to calc
;	mov	si,cx		; bytes sent - else just use the return
;	pop	cx		; value from int 17 (in CX)
;	jmp	ot1h
;ot1g:
	pop	cx
	sub	si,cx		; calc bytes sent
;ot1h:
	mov 	word ptr es:[bx+18],si		; return bytes sent
	ret
output	endp

endres	label	byte

	subttl	INIT - Init driver
	page
;-----------------------------------------------------------------------;
;	This routine will initialize the device drivers.		;
;									;
;	Parms passed							;
;	Return values							;
;	Global data affected						;
;	Global procedures called					;
;	What registers are changed					;
;-----------------------------------------------------------------------;

init	proc	near
	int	11h		; read equipment list
	and	ax,0c000h
	rol	ax,1
	rol	ax,1
	mov	[tcbpcnt],al	; store number of printers
	mov 	cx,ax
	xor	dx,dx
	jcxz	init3		; no printers
init1:
	mov	ah,1		; initialize each one
	int	17h
	inc	dx
	loop	init1
init3:
	int	11h		; read equipment list
	shr	ah,1
	and	ah,7		; ah = number of serial ports
	mov 	cl,ah
	xor	ch,ch
	mov	dx,03f8h	; hex address of com1
	jcxz	init4		; no com ports
init2:	

; init each port to 19.2kb, no parity, 1 stop, 8 data

	push	dx
	mov	dx,ax
	cli			; No interrupts at this time please...
	add	dx,3		; Point to LCR
	mov	al,83H		; Set DLAB=1, 8 data, 1 stop, and no parity
	out	dx,al
	sub	dx,3
	mov	ax,6		; 19,200
	out	dx,al		; Set divisor LSB
	xchg	al,ah
	inc	dx
	out	dx,al		; Set divisor MSB
	add	dx,2		; Point to LCR
	mov	al,03H		; Set DLAB=0, 8 data, 1 stop, and no parity
	out	dx,al		;
	sti
	sub	dx,3		; Point to TX reg
	mov	al,26		; CTRL-Z to clear terminal screen
	out	dx,al
	jmp	$+2
	out	dx,al		; Make sure screen is cleared
	jmp	$+2
	out	dx,al		; Make REAL sure!
	pop	dx
	sub	dx,10h
	loop	init2
init4:
	mov	bx,[tcbdevhdr]	; Get Request Header pointer
	lea	dx,endres
	mov	es:[bx+14],dx		; Set ending address of driver
	mov	es:[bx+16],cs		;
	mov	word ptr es:[bx+3],10H	; Return with 'DONE'
	ret				; End of INIT
init	endp

mosseg	ends
	end
