	include page.inc
	title	mosdevs - mos device drivers: lpts, coms, and nul
comment ^==============================================================
		       development specification

 program name:	mos.com 		assigned to: martin stitt
 module name:	mosdevs 		assign date: 01/12/87
 entry points:	n/a			completed:
 entry from:	n/a
 entry method:	n/a
 calls:		n/a
 purpose:	provide device drivers for lpt1, lpt2, lpt3, prn
		com, aux, and nul.
 refer to:	n/a
 last update:	08/18/1992
========================================================================

sah 07/10/87	added code out device out to retries up to 256times

sah 01/20/88	change scbseg and zero seg to mgetxxx macros

sah\rdr 02/20/88 move ddt segment to mo2 group

mjs 10/21/88	reordered the headers in here to accomodate the
		corrections done in mosddint for device drivers with
		more than one header per file.	also trimmed out
		unnecessary code.

mjs 03/03/89	modified error testing after the int17, function 3 call
		to ignore a bad return status if the # of chars printed
		as returned by cx is equal to the request count.

rkg 05/15/89	correct error testing after printing

rkg 05/22/89	correct lpt count on errors

sah 10/08/90	correct problems with dbase iv printing, return invalid
		function from input status check.  need to investigate
		and completely implement functions to dos 3.2 specs.

sah 12/27/90	corrections for 33mhz 486, removed serial init logic
		which was causing mos to lock on this machine because
		faulty logic was causing 8259 to be mask out.

sah 01/22/91	corrections for device driver will be supported by
		undocumented dos techniques

sah 03/25/91	corrected problem with peachtree complete iii print to
		screen function.  application could not handle our int
		17h function 3, so i fix this problem by making logic
		use function 1 if mos detects that int 17 vector is not
		pointing to mosint17

bwr 04/17/91	added code to enforce new hold on com ports.

mjs 05/24/91	modified testing of printer status to use timeout bit
		rather than just check for ah == 90.  this is more like
		how dos/bios works, is more flexible (e.g. the state of 
		the ack bit doesn't upset testing) and is less sensitive
		to false errors.

SAH 07/11/91	Corrections for barres (barcode printing software). 
		made sure that SI is save during loop  made for
		peachtree Complete correction.

================ 5.01 Kernel Ends Here ====================================

mjs 08/18/92	clean up segment declarations

mjs 08/26/92	delete reference to scbfree

======================================================================^

.xlist
;	include mosdevs.pub
	include group.inc
	include macros.inc
	include mosdevs.pub
	include mosregs.inc

tcb	segment at 1234h
	include mostcb.inc
tcb	ends
.list

;======================================================== mos segment
if 0 eq 0
segment_num = 1
endif
mosseg	segment
	assume	cs:mos,ds:nothing,es:nothing,ss:nothing

	extrn	mosend:byte, sbios:word
	extrn	mosint17:near
	extrn	reserve_com_port:near

	public scbcom24

	subttl	device headers
	page

header	macro	p1,p2,p3,p4

scb&p1	label	dword
	dw	mos:scb&p2
	dw	0
	dw	1000000000000000b	; char device
	dw	mos:devstrat
	dw	mos:p3&intr
	db	p4
	endm

	org	0h

header	com24,	com23,	com24,	'COM24   '
header	com23,	com22,	com23,	'COM23   '
header	com22,	com21,	com22,	'COM22   '
header	com21,	com20,	com21,	'COM21   '
header	com20,	com19,	com20,	'COM20   '
header	com19,	com18,	com19,	'COM19   '
header	com18,	com17,	com18,	'COM18   '
header	com17,	com16,	com17,	'COM17   '
header	com16,	com15,	com16,	'COM16   '
header	com15,	com14,	com15,	'COM15   '
header	com14,	com13,	com14,	'COM14   '
header	com13,	com12,	com13,	'COM13   '
header	com12,	com11,	com12,	'COM12   '
header	com11,	com10,	com11,	'COM11   '
header	com10,	com9,	com10,	'COM10   '
header	com9,	com8,	com9,	'COM9    '
header	com8,	com7,	com8,	'COM8    '
header	com7,	com6,	com7,	'COM7    '
header	com6,	com5,	com6,	'COM6    '
header	com5,	com4,	com5,	'COM5    '
header	com4,	com3,	com4,	'COM4    '
header	com3,	com2,	com3,	'COM3    '
header	com2,	aux,	com2,	'COM2    '
header	aux,	com1,	com1,	'AUX     '
header	com1,	lpt3,	com1,	'COM1    '
header	lpt3,	lpt2,	lp3,	'LPT3    '
header	lpt2,	prn,	lp2,	'LPT2    '
header	prn,	lpt1,	lp1,	'PRN     '

scblpt1 label	dword
	dd	-1
	dw	1000000000000000b	; char device
	dw	mos:devstrat
	dw	mos:lp1intr
	db	'LPT1    '

public	scbnul
scbnul	label	dword
	dd	-1
	dw	1000000000000100b	; char device
	dw	mos:devstrat
	dw	mos:nulintr
	db	'NUL     '

	subttl devstrat - strategy routine for printers, com, aux and nul
	page
;======================================================================
;,fs
; devstrat - strategy routine for printers, com, aux and nul
;
; this routine is the device drivers strategy routine, it just
; queues the dword pointer to the request header.
;
; in:	ss -> tcb
;	es:bx points to the device request header.
;
; out:	the request header pointer is saved.
;
;,fe
;=====================================================================
	assume	ds:nothing,es:nothing,ss:tcb
devstrat proc	far
	mov	[tcbdevhdr],bx		; save pointer in active tcb
	mov	[tcbdevhdr+2],es
	ret
devstrat endp

	subttl intr handlers
	page
;======================================================================
;,fs
; 
; intr handlers for each supported device.
;
; in:	ss -> tcb
;
; out:	tcbdnum is set to identify the device to be processed.
;
;,fe
;=====================================================================
	assume	ds:nothing,es:nothing,ss:tcb
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
	jmp	short devsintrx
com10intr:
	mov	[tcbdnum],13
	jmp	short devsintrx
com11intr:
	mov	[tcbdnum],14
	jmp	short devsintrx
com12intr:
	mov	[tcbdnum],15
	jmp	short devsintrx
com13intr:
	mov	[tcbdnum],16
	jmp	short devsintrx
com14intr:
	mov	[tcbdnum],17
	jmp	short devsintrx
com15intr:
	mov	[tcbdnum],18
	jmp	short devsintrx
com16intr:
	mov	[tcbdnum],19
	jmp	short devsintrx
com17intr:
	mov	[tcbdnum],20
	jmp	short devsintrx
com18intr:
	mov	[tcbdnum],21
	jmp	short devsintrx
com19intr:
	mov	[tcbdnum],22
	jmp	short devsintrx
com20intr:
	mov	[tcbdnum],23
	jmp	short devsintrx
com21intr:
	mov	[tcbdnum],24
	jmp	short devsintrx
com22intr:
	mov	[tcbdnum],25
	jmp	short devsintrx
com23intr:
	mov	[tcbdnum],26
	jmp	short devsintrx
com24intr:
	mov	[tcbdnum],27
	jmp	short devsintrx
nulintr:
	mov	[tcbdnum],0
devsintrx:
	call	devsintr
	retf

; function table

funtbl	dw	vinit			; 0  init
	dw	devstub 		; 1  media check
	dw	devstub 		; 2  build bpb
	dw	devstub 		; 3  i/o control input
	dw	input			; 4  input (read)
	dw	devstub 		; 5  nondestructive input no wait
	dw	deverr			; 6  input status
	dw	devstub 		; 7  input flush
	dw	output			; 8  output (write)
	dw	devstub 		; 9  output with verify
	dw	devstub 		; 10 output status
	dw	devstub 		; 11 output flush
	dw	devstub 		; 12 i/o control output

	subttl	devsintr - main interrupt routine
	page
;======================================================================
;,fs
; devsintr - main interrupt routine
;
; this is the main device driver interrupt routine which will
; process mos's requested function.
;
; in:	ss -> tcb
;
; out:	
;
;,fe
;=====================================================================
	assume	ds:nothing,es:nothing,ss:tcb
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
	pop	ds			; for call to routine
	assume	ds:mos
	les	bx,dword ptr [tcbdevhdr]; get request header pointer
	mov	al,es:[bx+2]		; get command code
	cmp	al,12			; check for invalid call
	ja	err1			; yes, exit with error
	xor	ah,ah
	lea	bx,funtbl
	shl	ax,1
	add	bx,ax
	call	[bx]			; execute appropriate routine
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
	les	bx,dword ptr [tcbdevhdr] ; get request header pointer
	mov	word ptr es:[bx+3],8013h ; return 'Unknown Command'
	jmp	rexit
devsintr endp

	subttl	devstub - for functions not handled
	page
;======================================================================
;,fs
; devstub - for functions not handled
;
; in:	ds -> mos (this code segment)
;	ss -> tcb
;
; out:	
;
;,fe
;=====================================================================
	assume	ds:mos,es:nothing,ss:tcb
devstub proc near
	les	bx,dword ptr [tcbdevhdr] ; get pointer to rh
	mov	word ptr es:[bx+3],0100h ; return with 'DONE'
	ret
devstub endp 

	subttl	deverr - for functions not handled
	page
;======================================================================
;,fs
; deverr - for functions not handled
;
; in:	ds -> mos (this code segment)
;	ss -> tcb
;
; out:	
;
;,fe
;=====================================================================
	assume	ds:mos,es:nothing,ss:tcb
deverr proc near 
	les	bx,dword ptr [tcbdevhdr] ; get pointer to rh
	mov	word ptr es:[bx+3],8103h ; return with 'DONE'
	ret
deverr endp

	subttl input - input read
	page
;======================================================================
;,fs
; input - input read
;
; this routine processes the input read call (=4)
;
; in:	ds -> mos (this code segment)
;	ss -> tcb
;
; out:	
;
;,fe
;=====================================================================
	assume	ds:mos,es:nothing,ss:tcb
input proc near
	cmp	[tcbdnum],0		; nul device ?
	je	donul
	cmp	[tcbdnum],3
	ja	docom
donul:
	les	bx,dword ptr [tcbdevhdr] ; get pointer to rh
	mov	word ptr es:[bx+3],100h ; return 'Done'
	ret
docom:
	mov	dl,[tcbdnum]
	xor	dh,dh
	sub	dx,4			; set dx for com number
	les	bx,dword ptr [tcbdevhdr] ; get pointer to rh
	mov	cx,es:[bx+18]		; get byte count
	mov		di,es:[bx+14]	; get offset of user buffer
	mov	ax,es:[bx+16]		; get segment of user buffer
	mov	es,ax			; es:di addresses user buffer
	cld
	push	di			; save di for bytes sent accounting
in1a:
	mov	ah,2
	int	14h			; read a char from the com port
	test	ah,80h
	jnz	in1b			; jmp if error
	stosb				; write the char to the users buffer
	loop	in1a
					; normal end of loop - calc bytes sent
	les	bx,dword ptr [tcbdevhdr] ; get pointer to rh
	mov	word ptr es:[bx+3],100h ; return 'Done'
	jmp	short in1c
in1b:					; error handling
	les	bx,dword ptr [tcbdevhdr] ; get pointer to rh
	mov	word ptr es:[bx+3],800bh ; return read error
in1c:
	pop	cx
	sub	di,cx
	mov		word ptr es:[bx+18],di ; return bytes sent
	ret
input endp

	subttl out17 - output a string ds:si to lptx
	page
;======================================================================
;,fs
; out17 - output a string ds:si to lptx
;
; this routine processes a string int 17 output
;
; in:	ds -> mos (this code segment)
;	ss -> tcb
;	cx = count
;	dx = lpt port
;	ds:si -> string to passed
;
; out:	cx = number of characters sent
;	ah = printer status
;
;,fe
;=====================================================================
	assume	ds:mos,es:nothing,ss:tcb
out17 proc near
	push	ds
	mgetzero ds
	assume	ds:nothing

; check to see if int 17h points to mosint17

	cmp	word ptr ds:[17h*4],offset mosint17
	jne	tsr17
	mov	ax,cs
	cmp	word ptr ds:[17h*4+2],ax
	je	mos17
tsr17:

; int 17h != mosint17, use function 1 instead

	pop	ds
	assume	ds:mos
	push	bx
	push	si
	xor	bx,bx			; no characters printed yet
	mov	ah,90h			; indicate ok
	or	cx,cx			; no characters
	jz	tsr17end
tsr17lp:
	lodsb
	xor	ah,ah
	push	bx
	push	si			; save SI (Barres will crash it)
	int	17h			; print character
	pop	si			; restore SI
	pop	bx
	test	ah,1			; test timeout bit
	jne	tsr17end
	inc	bx			; indicate character ok, up count
	loop	tsr17lp
tsr17end:
	mov	cx,bx
	pop	si
	pop	bx
	ret
mos17:

; int 17h = mosint17, ok to use function 3

	pop	ds
	mov	ah,3			; use string printing function
	int	17h			; send char to the printer
	ret
out17 endp

	subttl output - output write
	page
;======================================================================
;,fs
; output - output write
;
; this routine processes the output write call (=8)
;
; in:	ds -> mos (this code segment)
;	ss -> tcb
;
; out:	
;
;,fe
;=====================================================================
	assume	ds:mos,es:nothing,ss:tcb
output proc near
	cmp	[tcbdnum],0		; nul device ?
	jne	notnul
	les	bx,dword ptr [tcbdevhdr] ; get pointer to rh
	mov	word ptr es:[bx+3],100h ; return 'Done'
	ret
notnul:
	mov	dl,[tcbdnum]
	xor	dh,dh
	cmp	dl,3			; printing or com'ing ?
	ja	setcomdx
	dec	dx			; set dx for printer number
	jmp	short dxset
setcomdx:
	sub	dx,4			; set dx for com number
dxset:
	les	bx,dword ptr [tcbdevhdr] ; get pointer to rh
	mov	cx,es:[bx+18]		; get byte count
	mov	si,es:[bx+14]		; get offset of user buffer
	mov	ax,es:[bx+16]		; get segment of user buffer
	mov	ds,ax			; ds:si addresses user buffer
	cld
	push	si			; save si for bytes sent accounting
	cmp	[tcbdnum],3
	ja	ot1f			; printing or com'ing ?
	call	out17			; send string out....
	add	si, cx			; for length calc
	cmp	cx,es:[bx+18]		; if get an error but all bytes sent
	je	loopend 		; then don't want to retry
	inc	si			; past char that erred
	jmp	ot1b			; jmp to error handler
ot1f:

; is the com port held by another task?  if so, exit immediately with
; an error.

	call	reserve_com_port
	jc	ot1b
	lodsb				; read a byte from user's buffer
	push	cx
	mov	cx, 256 		; loop 256 times (it should be an error)
oteloop:
	push	ax
	push	cx
	mov	ah,1
	int	14h			; send char to the com port
	pop	cx
	test	ah,80h
	jz	oteok
	pop	ax
	loop	oteloop 		; loop for retries
	pop	cx
	jmp	short ot1b		; jmp if error
oteok:
	pop	ax
	pop	cx
	loop	ot1f
loopend:				; normal end of loop
	les	bx,dword ptr [tcbdevhdr] ; get pointer to rh
	mov	word ptr es:[bx+3],100h ; return 'Done'
	jmp	outend
ot1b:					; error handling
	les	bx,dword ptr [tcbdevhdr] ; get pointer to rh
	mov	word ptr es:[bx+3],8002h ; return 'error'
	dec	si
outend:
	pop	cx
	sub	si,cx			; calc bytes sent
	mov		word ptr es:[bx+18],si ; return bytes sent
	ret
output endp

endres	label	byte

	subttl vinit - init driver
	page
;======================================================================
;,fs
; vinit - init driver
;
; this routine will initialize the device drivers.
;
; in:	ds -> mos (this code segment)
;	ss -> tcb
;
; out:	
;
;,fe
;=====================================================================
	assume	ds:mos,es:nothing,ss:tcb
vinit proc near
	int	11h			; read equipment list
	and	ax,0c000h
	rol	ax,1
	rol	ax,1
	mov	[tcbpcnt],al		; store number of printers
	mov	cx,ax
	xor	dx,dx
	jcxz	vinit3			; no printers
vinit1:
	mov	ah,1			; initialize each one
	int	17h
	inc	dx
	loop	vinit1
vinit3:
	mov	bx,[tcbdevhdr]		; get request header pointer
	lea	dx,endres
	mov	es:[bx+14],dx		; set ending address of driver
	mov	es:[bx+16],cs
	mov	word ptr es:[bx+3], 100h ;return done.
	ret				; end of init
vinit endp

mosseg	ends
	end

