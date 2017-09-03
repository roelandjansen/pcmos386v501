	include page.inc
	title pipe.sys - intertask communications device driver

;-----------------------------------------------------------------------;
;		       Development Specification			;
;									;
; Program Name: _pipe.sys		Assigned to: Stewart Hyde	;
; Module Name:	_pipe.asm		Assign date: 11/08/88		;
; Entry Points: n/a			Completed:			;
; Entry From:	n/a							;
; Entry Method: n/a							;
; Calls:	n/a							;
; Purpose:	intertask communications				;
; Refer to:	n/a							;
; Last Update:	11/08/88						;
;-----------------------------------------------------------------------;
; 07/12/87 sah	converted 80+ calls to int 38h 00+			;
;-----------------------------------------------------------------------;
; 8/16/87 mjs	Added flag wrtflag to manage case where get a ^c during ;
;		an operation to the pipe.  Push'ed and pop'ed rhseg	;
;		and rhoff around the calls to int 38 since calling	;
;		suspend from within a device driver makes the driver	;
;		re-enterable by another task.				;
;-----------------------------------------------------------------------;
; 09/24/87 sah	added /n option to indicated that you want the pipe not ;
;		to wait - instead return eof				;
;-----------------------------------------------------------------------;
; 01/28/88 sah	converted int 38 calls to direct calls to avoid 	;
;		conficts with software which take int 38 vector.	;
;-----------------------------------------------------------------------;
; mjs 11/08/88	complete overhaul					;
;-----------------------------------------------------------------------;
; SAH 02/20/89	Converted INT 38 to INT SERVICES			;
;-----------------------------------------------------------------------;
; BWR 11/30/89	Marked messages for foreign language translation.	;
;-----------------------------------------------------------------------;
	include _pipe.pub

call38	macro
	pushf
	call	dword ptr [far38]
	endm

scbs	segment at	7777h
	assume cs:scbs
	.xlist
	include mosscbdf.inc
	include	options.inc
	.list
scbs	ends

	include	devreqh.inc	; device request header structure

mainseg segment para
	assume cs:mainseg,ds:mainseg
begin:
	page

;=== Device header ===================

devheadr:
	dd    -1		; pointer to next driver
	dw    0c800h		; attribute
	dw    strategy		; ptr to strategy routine
	dw    interupt		; ptr to interrupt routine
devname db    'PIPE0   $'	; device name

;=== Variables =======================

	even

; NOTE the following 5 bytes must stay in their present order

parmblk:
bsize	dw	64	; buffer capacity (in bytes) default is 64 bytes
bcount	dw	0	; number of bytes currently available in the buffer
eof 	db	0	; non-zero means eof

; end of 5 byte fixed area

binput	dw	offset buffer	; tail ptr of circular buffer - read from here when 
				; copying data from pipe to a caller's buffer
boutput dw	offset buffer	; head ptr of circular buffer - write to here when
				; copying data from a caller's buffer to the pipe
update	db	0		; non-zero means buffer been updated

pipenw	db	0	; nonzero to indicate that task should not suspend
			; but return eof when empty
far38	dw	2 dup (?)	; far vector call to mosint38

;=== Function table ================

funtab	label	word
	dw	init		; 0  Init 
	dw	nullproc	; 1  Media check
	dw	nullproc	; 2  Build BPB
	dw	ioctlin 	; 3  I/O control input
	dw	input		; 4  Input (read)
	dw	ndinput 	; 5  Nondestructive input no wait
	dw	instatus	; 6  Input status
	dw	flush 		; 7  Input flush
	dw	output		; 8  Output (write)
	dw	output	 	; 9  Output with verify
	dw	outstat		; 10 Output status
	dw	flush 		; 11 Output flush
	dw	ioctlout	; 12 I/O control output 		
	dw	donestat	; 13 Open call
	dw	close		; 14 Close call
	dw	donestat	; 15 Removable media

;- STRATEGY ------------------------------------------------------------;
; entry parms:	es:bx -> request header					;
; exit parms: 	none							;
;-----------------------------------------------------------------------;
	assume	ds:nothing,es:nothing,ss:nothing
strategy:
	retf

;- INTERUPT ------------------------------------------------------------;
; entry parms:	in the request header					;
; exit parms: 	in the request header					;
;-----------------------------------------------------------------------;
	assume	ds:nothing,es:nothing,ss:nothing
interupt:
	push	es
	push	ds
	push	di
	push	si
	push	dx
	push	cx
	push	bx
	push	ax
	mov	ax, cs		; init ds register
	mov	ds, ax
	assume	ds:mainseg
	xor	ax, ax
	mov	al,es:rqhcmd[bx]; get command code byte
	shl	ax,1
	mov	di,ax
	call	[di+funtab]	; function returns status in AX
	or	ax, RQSDONE
	mov	es:rqhstat[bx], ax
	pop	ax
	pop	bx
	pop	cx
	pop	dx
	pop	si
	pop	di
	pop	ds
	pop	es
	retf


nullproc:
	mov	ax, 8102h	; indicate device not ready
	ret

donestat:
	mov	ax, 0100h	; "done" status
	ret


;===================== FUNCTION HANDLING CODE ============================

;- IOCTLIN -------------------------------------------------------------;
; entry parms:	es:bx -> request header					;
;		ds -> mainseg						;
; exit parms: 	parmblk copied to user's buffer				;
;									;
; NOTES:								;
; ioctlin - copies 5 bytes to user's data area from parmblk		;
; allows reading of the total size of the buffer, the current size and	;
; the state of the end of buffer flag.					;
;-----------------------------------------------------------------------;
	assume	ds:mainseg,es:nothing,ss:nothing
ioctlin:
	push	es
	les	di, es:rqhbuff[bx]	; get address to store parameters
	lea	si, parmblk
	mov	cx,5
	cld
	rep	movsb
	pop	es
	mov	es:rqhlen[bx],5		; pointer parameter block size
	xor	ax, ax
	ret

;- INPUT ---------------------------------------------------------------;
; entry parms:	es:bx -> request header					;
;		ds -> mainseg						;
; exit parms: 	none							;
;									;
; NOTES:								;
; pipe input routine - transfer up to max of count character		;
; to caller from circular buffer.  this routine will only send		;
; what it can send.							;
;-----------------------------------------------------------------------;
	assume	ds:mainseg,es:nothing,ss:nothing

input:
	mov	cx, es:rqhlen[bx]	; cx = request count
	push	es
	les	di, es:rqhbuff[bx]	; pointer to caller's buffer

inputlup:
	call	inputmov	; move chars to caller
	call	inputmov	; decrementing CX

	jcxz	inputxit	; read plenty

	test	[pipenw], -1
	jnz	inputeof

; test EOF just in case it was set by an iocntl call or a close by 
; the writer - if yes, don't suspend on an empty buffer.

	test	[eof], -1
	jnz	inputeof

; suspend until more data is written into the buffer

	push	es
	push	bx		; save offset to request packet
	mov	ax, cs		; segment of poll routine
	mov	es, ax
	mov	ax,0780h	; poll wait
	lea	bx, pollin
	call38			; call int 38 vector
	pop	bx
	pop	es
	jmp	inputlup

; enter here if the caller's request has not been fulfilled, the pipe buffer
; is empty and don't want to call suspend because the /n option is in effect
; or EOF is not 0.  basically, stuff a cntrl-z in the caller's buffer,
; set the return count and return

inputeof:
	mov	al, 1Ah		; store a ^Z
	stosb
	mov	[eof], 0	; reset eof flag

inputxit:
	pop	es				; restore reqhdr seg
	sub	di, word ptr es:rqhbuff[bx]	; calc chars moved
	mov	es:rqhlen[bx], di		; store in parms
	xor	ax, ax
	ret


;	INPUTMOV moves from pipe buffer to user buffer. Moves from
;	input to output OR input to end of buffer.  Therefore call twice
;	to move all chars.
;	Enter:	ES:DI => pointer to user buffer
;		CX = count of chars to move
;	Exits:	CX update
;		Input pointer updated

inputmov:
	mov	si, [binput]	; get input ptr
	push	cx		; save requested length
	cmp	cx, [bcount]	; smaller of request and available
	jb	inmovcntg
	mov	cx, [bcount]
inmovcntg:
	lea	dx, buffer	; get end of buffer
	add	dx, [bsize]
	mov	ax, dx		; saved for pointer update
	sub	ax, si		; number of contingous chars
	cmp	cx, ax
	jb	inmovmov
	mov	cx, ax		; minimum of request and contiguous

inmovmov:
	mov	ax, cx		; save chars moving
	jcxz	inmovnul
	rep movsb
inmovnul:
	pop	cx		; length requested
	sub	cx, ax		; less chars moved

	cmp	si, dx		; at end of buffer
	jne	inmovupd
	lea	si, buffer	; yes reset to start of buffer
inmovupd:
	mov	[binput], si	; update input pointer
	sub	[bcount], ax	; and buffered char count
	ret


;- POLLIN --------------------------------------------------------------;
; entry parms:	none							;
; exit parms: 	ax = 0 to wake up					;
;									;
; NOTES: wake up if EOF gets set or some data is put in the	;
; buffer.								;
;-----------------------------------------------------------------------;
	assume	ds:nothing,es:nothing,ss:nothing
pollin:
	xor	ax, ax		; wake return
	test	[eof], -1
	jnz	pollinx
	test	[bcount], -1
	jnz	pollinx

	mov	al, 2		; stay asleep
pollinx:
	retf

;- NDINPUT -------------------------------------------------------------;
; entry parms:	es:bx -> request header					;
;		ds -> mainseg						;
; exit parms: 	none							;
;									;
; NOTES:								;
; non-destructive input routine - check if characters are ready		;
; for input.  returns busy if not.					;
;-----------------------------------------------------------------------;
	assume	ds:mainseg,es:nothing,ss:nothing
ndinput:
	mov	ax, RQSBUSY	; flag busy if no chars
	test	[bcount], -1
	jz	ndinpxit

	mov	si, [binput]			; return first byte
	mov	al, [si]
	mov	es:rqhunit[bx], al		; return byte
	xor	ax, ax
ndinpxit:
	ret
	

;- INSTATUS ------------------------------------------------------------;
; entry parms:	es:bx -> request header					;
;		ds -> mainseg						;
; exit parms: 	none							;
;									;
; NOTES:								;
; if this driver were to return a busy status if the buffer is empty	;
; this would just make MOS suspend until some data is available before 	;
; calling the input fuction.  since the input function is already	;
; setup to do this, a non-busy status is returned.			;
;-----------------------------------------------------------------------;
	assume	ds:mainseg,es:nothing,ss:nothing
instatus:
	xor	ax, ax		; indicate device ready
	ret


;- FLUSH ---------------------------------------------------------------;
; entry parms:	es:bx -> request header					;
;		ds -> mainseg						;
; exit parms: 	none							;
;-----------------------------------------------------------------------;
	assume	ds:mainseg,es:nothing,ss:nothing
flush:
	lea	dx, buffer
	mov	[binput], dx
	mov	[boutput], dx
	xor	ax,ax
	mov	[bcount], ax	; clear count
	mov	[eof], al	; and EOF flag
	jmp	donestat

;- OUTPUT --------------------------------------------------------------;
; entry parms:	es:bx -> request header					;
;		ds -> mainseg						;
; exit parms: 	none							;
;									;
; NOTES:								;
; pipe output routine - transfer up to max of count character		;
; from caller to circular buffer.  this routine will only get		;
; what it can hold in its buffer.					;
;-----------------------------------------------------------------------;
	assume	ds:mainseg,es:nothing,ss:nothing

output:
	mov	cx, es:rqhlen[bx]	; cx = request count
	push	ds
	push	es
	mov	ax, ds
	lds	si, es:rqhbuff[bx]	; pointer to caller's buffer
	mov	es, ax
	assume	ds:nothing,es:mainseg	; ES => our buffer  DS => user buffer

outputlup:
	call	outputmov	; move chars to caller
	call	outputmov	; decrementing CX

	jcxz	outputxit	; read plenty

; suspend until more data is read from the buffer

	push	bx		; save offset to request packet
				; ES == CS for poll routine
	mov	ax,0780h	; poll wait
	lea	bx, pollout
	call38			; call int 38 vector
	pop	bx
	jmp	outputlup


outputxit:
	pop	es				; restore reqhdr seg
	pop	ds
	assume	ds:mainseg, es:nothing
;	sub	si, word ptr es:rqhtail[bx]	; calc chars moved
;	mov	word ptr es:rqhline[bx], si	; store in parms
	xor	ax, ax
	mov	[update], -1			; flag data written
	ret


;	OUTPUTMOV moves from user buffer to pipe buffer. Moves from
;	output to input OR output to end of buffer.  Therefore call twice
;	to move all chars.
;	Enter:	DS:SI => pointer to user buffer
;		CX = count of chars to move
;	Exits:	CX update
;		Output pointer updated

	assume	ds:nothing, es:mainseg
outputmov:
	push	cx		; save requested length
	mov	ax, [bsize]
	sub	ax, [bcount]	; smaller of request and available
	cmp	cx, ax
	jb	outmovcntg
	mov	cx, ax		; use size available
outmovcntg:
	mov	di, [boutput]	; get output ptr
	lea	dx, buffer	; get end of buffer
	add	dx, [bsize]
	mov	ax, dx		; save for pointer update
	sub	ax, di		; number of contingous chars
	cmp	cx, ax
	jb	outmovmov
	mov	cx, ax		; minimum of request and contiguous

outmovmov:
	mov	ax, cx		; save chars moving
	jcxz	outmovnul
	rep movsb
outmovnul:
	pop	cx		; length requested
	sub	cx, ax		; less chars moved

	cmp	di, dx		; test at end of buffer
	jne	outmovupd
	lea	di, buffer
outmovupd:
	mov	[boutput], di	; update output pointer
	add	[bcount], ax	; and buffered char count
	ret


;- POLLOUT -------------------------------------------------------------;
; entry parms:	none							;
; exit parms: 	ax = 0 to wake up					;
;									;
; NOTES: stay suspended as long as the buffer is full			;
;-----------------------------------------------------------------------;
	assume	ds:nothing,es:nothing,ss:nothing

pollout:
	mov	ax, [bsize]
	cmp	ax, [bcount]		; full?
	mov	ax, 0
	ja	polloutx		; more room - wake up
	mov	al, 2			; sleep
polloutx:
	retf


;- OUTSTAT -------------------------------------------------------------;
; entry parms:	es:bx -> request header					;
;		ds -> mainseg						;
; exit parms: 	none							;
;									;
; NOTES:								;
; if this driver were to return a busy status if the buffer is full 	;
; this would just make MOS suspend until some room is available before 	;
; calling the output fuction.  since the output function is already	;
; setup to do this, a non-busy status is returned.			;
;-----------------------------------------------------------------------;
	assume	ds:mainseg,es:nothing,ss:nothing
outstat:
	xor	ax, ax
	ret


;- IOCTLOUT ------------------------------------------------------------;
; entry parms:	es:bx -> request header					;
;		ds -> mainseg						;
; exit parms: 	none							;
;									;
; NOTES: allow EOF to be set						;
;-----------------------------------------------------------------------;
	assume	ds:mainseg,es:nothing,ss:nothing
ioctlout:
	push	es
	les	si, es:rqhbuff[bx]	; get pointer to EOF value
	mov	al, es:[si]
	mov	[eof],al
	pop	es			; restore reqhdr seg
	mov	es:rqhlen[bx],5		; pointer return ??
	xor	ax, ax
	ret


;- CLOSE ---------------------------------------------------------------;
; entry parms:	es:bx -> request header					;
;		ds -> mainseg						;
; exit parms: 	none							;
;									;
; NOTES: when the pipe device is closed and any data was written then	;
; set EOF.								;
;-----------------------------------------------------------------------;
	assume	ds:mainseg,es:nothing,ss:nothing
close:
	xor	ax, ax		; get/clear update flag
	xchg	al, [update]
	or	[eof], al	; keep EOF set on consecutive closes
	xor	ax, ax
	ret


;======================= DATA BUFFER ALLOCATION HERE ====================

buffer	label	byte

message db'MOS Pipe v4.00',13,10
	db   'Pipe $'
devmsg1 db' with ' ;@@XLAT
dvsize	db'   64 byte buffer installed.  ',13,10,'$' ;@@XLAT
nwmsg	db '    NOWAIT Option in Effect   ',13,10,'$' ;@@XLAT
ten	dw	10	; constant

; initialization code - discarded later

;- INIT ----------------------------------------------------------------;
; entry parms:	es:bx -> request header					;
;		ds -> mainseg						;
; exit parms: 	end offset of driver set in request header		;
;-----------------------------------------------------------------------;
	assume	ds:mainseg,es:nothing,ss:nothing
init:
	cld
	push	bx		; save reqhdr pointer
	push	es

; save int 38 vector

	mov	ah,2
	int	SERVICES
	mov	ax,word ptr es:[bx+scbfar38]
	mov	[far38],ax
	mov	ax,word ptr es:[bx+scbfar38+2]
	mov	[far38+2],ax

; get command pararmeters

	pop	es		; restore reqhdr pointer
	pop	bx

	push	ds
	lds	si, es:dizline[bx]	; get command parameter
	assume	ds:nothing
	push	si

pscan1:
	lodsb			; get next byte
	cmp	al,0Dh		; is this the end
	je	pscan2
	cmp	al,'/'		; is this a /
	jne	pscan1
	lodsb
	cmp	al,'N'		; is this /n for nowait?
	jne	pscan1

	mov	[pipenw], al	; set nowait option
	mov	word ptr [si-2], '  '	; blank out '/N'
pscan2:
	pop	si

scan1:
	lodsb			; scan for first space
	cmp	al,0Dh
	je	finishe
	cmp	al,' '
	jne	scan1

scan2:
	lodsb			; scan til first non-space
	cmp	al,0Dh
	je	finishe
	cmp	al,' '
	je	scan2

	mov	cx, 8		; maximum chars in devname
	lea	di, devname
	dec	si
scan4:				; first parm is device name
	lodsb
	cmp	al,' '
	je	scan5
	cmp	al,','
	je	scan5
	cmp	al,0Dh
	je	scan5
	jcxz	scan4		; skip store if no room in devname
	mov	cs:[di],al
	inc	di
	dec	cx
	jmp	scan4

scan5:				; blank remainder of devname
	jcxz	scan6
	mov	byte ptr cs:[di], ' '
	inc	di
	loop	scan5

scan6:				; next parm is pipe size
	lodsb
	cmp	al,0Dh
finishe:je	finish
	cmp	al,','
	je	scan6
	cmp	al,' '
	je	scan6		; skip intervening spaces

scansize:
	xor	dx, dx		; zero out value
	mov	cx, 5		; maximum digits

sizeloop:
	cmp	al, '0'
	jb	scan7
	cmp	al, '9'
	ja	scan7

	and	ax, 0Fh		; get digit value
	push	ax
	mov	al, 10
	mul	dx		; previous * 10
	pop	dx
	add	dx, ax		; plus this digit

	lodsb			; next digit
	loop	sizeloop

scan7:
	cmp	dx, 1
	jb	sizedef
	cmp	dx, 16384
	ja	sizedef
	jmp	sizedone
sizedef:
	mov	dx, 64		; use default size
sizedone:
	mov	[bsize], dx	; store buffer size

	lea	di, dvsize+5
	mov	ax, dx
sizedisp:
	xor	dx, dx		; display number scanned
	div	[ten]
	or	dl, '0'
	dec	di
	mov	cs:[di], dl
	or	ax, ax
	jnz	sizedisp	

finish:
	pop	ds
	assume	ds:mainseg
	lea	cx, buffer+15
	add	cx,[bsize]		;adjust size
	and	cx,0fff0h
	mov	word ptr es:diztail[bx], cx
	mov	word ptr es:diztail+2[bx], cs
	mov	ah,9
	lea	dx, message
	int	21h
	lea	dx, devname
	int	21h
	lea	dx, devmsg1
	int	21h

	test	[pipenw], -1
	jz	finwait
	lea	dx, nwmsg
	int	21h

finwait:
	xor	ax, ax		; completed function
	ret


mainseg ends
	end	begin

