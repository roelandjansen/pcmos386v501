	include page.inc
	title pipe.sys - intertask communications device driver
comment ^===============================================================
		       development specification

 program name:	_pipe.sys		assigned to: stewart hyde
 module name:	_pipe.asm		assign date: 11/08/88
 entry points:	n/a			completed:
 entry from:	n/a
 entry method:	n/a
 calls:		n/a
 purpose:	intertask communications
 refer to:	n/a
 last update:	11/08/88

=======================================================================

sah 07/12/87	converted 80+ calls to int 38h 00+

mjs 8/16/87	added flag wrtflag to manage case where get a cntrl-c 
		during an operation to the pipe.  push'ed and pop'ed 
		rhseg and rhoff around the calls to int 38 since 
		calling	suspend from within a device driver makes 
		the driver re-enterable by another task.

sah 09/24/87	added /n option to indicated that you want the pipe not
		to wait - instead return eof

sah 01/28/88	converted int 38 calls to direct calls to avoid
		conficts with software which take int 38 vector.

mjs 11/08/88	complete overhaul

sah 02/20/89	converted int 38 to int services

bwr 11/30/89	marked messages for foreign language translation.

mjs 03/22/91	corrected display of buffer size when a size of less
		than 10 bytes is specified by removing the default
		value of 64 from the dvsize string.

======================================================================^

include _pipe.pub

call38	macro
	pushf
	call	dword ptr [far38]
	endm

scbs	segment at	7777h
	assume cs:scbs
	.xlist
	include mosscbdf.inc
	include options.inc
	.list
scbs	ends

	include devreqh.inc		; device request header structure

mainseg segment para
	assume cs:mainseg,ds:mainseg
begin:
	page

;==== device header

devheadr:
	dd    -1			; pointer to next driver
	dw	0c800h			; attribute
	dw	strategy		; ptr to strategy routine
	dw	interupt		; ptr to interrupt routine
devname db    'PIPE0   $'		; device name

	even

; note the following 5 bytes must stay in their present order

parmblk:
bsize	dw	64			; buffer capacity (in bytes) default is 64 bytes
bcount	dw	0			; number of bytes currently available in the buffer
eof	db	0			; non-zero means eof

; end of 5 byte fixed area

binput	dw	offset buffer		; tail ptr of circular buffer - read from here when
					; copying data from pipe to a caller's buffer
boutput dw	offset buffer		; head ptr of circular buffer - write to here when
					; copying data from a caller's buffer to the pipe
update	db	0			; non-zero means buffer been updated

pipenw	db	0			; nonzero to indicate that task should not suspend
					; but return eof when empty
far38	dw	2 dup (?)		; far vector call to mosint38

;=== function table ================

funtab	label	word
	dw	init			; 0  init
	dw	nullproc		; 1  media check
	dw	nullproc		; 2  build bpb
	dw	ioctlin 		; 3  i/o control input
	dw	input			; 4  input (read)
	dw	ndinput 		; 5  nondestructive input no wait
	dw	instatus		; 6  input status
	dw	flush			; 7  input flush
	dw	output			; 8  output (write)
	dw	output			; 9  output with verify
	dw	outstat 		; 10 output status
	dw	flush			; 11 output flush
	dw	ioctlout		; 12 i/o control output
	dw	donestat		; 13 open call
	dw	close			; 14 close call
	dw	donestat		; 15 removable media

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
	assume	ds:nothing,es:nothing,ss:nothing
strategy proc far
	retf
strategy endp

;======================================================================
;,fs
; interupt
;
; in:	in the request header
;
; out:	in the request header
;
;,fe
;=====================================================================
	assume	ds:nothing,es:nothing,ss:nothing
interupt proc far
	push	es
	push	ds
	push	di
	push	si
	push	dx
	push	cx
	push	bx
	push	ax
	mov	ax,cs			; init ds register
	mov	ds,ax
	assume	ds:mainseg
	xor	ax,ax
	mov	al,es:rqhcmd[bx]	; get command code byte
	shl	ax,1
	mov	di,ax
	call	[di+funtab]		; function returns status in ax
	or	ax,rqsdone
	mov	es:rqhstat[bx],ax
	pop	ax
	pop	bx
	pop	cx
	pop	dx
	pop	si
	pop	di
	pop	ds
	pop	es
	retf
interupt endp 


nullproc:
	mov	ax,8102h		; indicate device not ready
	ret
donestat:
	mov	ax,0100h		; "done" status
	ret

;======================================================================
;,fs
; ioctlin
;
; copies 5 bytes to user's data area from parmblk
; allows reading of the total size of the buffer, the current size and
; the state of the end of buffer flag.
;
; in:	es:bx -> request header
;	ds -> mainseg
;
; out:	parmblk copied to user's buffer
;
;,fe
;=====================================================================
	assume	ds:mainseg,es:nothing,ss:nothing
ioctlin proc near
	push	es
	les	di,es:rqhbuff[bx]	; get address to store parameters
	lea	si,parmblk
	mov	cx,5
	cld
	rep	movsb
	pop	es
	mov	es:rqhlen[bx],5 	; pointer parameter block size
	xor	ax,ax
	ret
ioctlin endp 

;======================================================================
;,fs
; input
;
; pipe input routine - transfer up to max of count character
; to caller from circular buffer.  this routine will only send
; what it can send.
;
; in:	es:bx -> request header
;	ds -> mainseg
;
; out:	none
;
;,fe
;=====================================================================
	assume	ds:mainseg,es:nothing,ss:nothing
input proc near
	mov	cx,es:rqhlen[bx]	; cx = request count
	push	es
	les	di,es:rqhbuff[bx]	; pointer to caller's buffer

inputlup:
	call	inputmov		; move chars to caller
	call	inputmov		; decrementing cx
	jcxz	inputxit		; read plenty
	test	[pipenw],-1
	jnz	inputeof

; test eof just in case it was set by an iocntl call or a close by
; the writer - if yes, don't suspend on an empty buffer.

	test	[eof],-1
	jnz	inputeof

; suspend until more data is written into the buffer

	push	es
	push	bx			; save offset to request packet
	mov	ax,cs			; segment of poll routine
	mov	es,ax
	mov	ax,0780h		; poll wait
	lea	bx,pollin
	call38				; call int 38 vector
	pop	bx
	pop	es
	jmp	inputlup

; enter here if the caller's request has not been fulfilled, the pipe buffer
; is empty and don't want to call suspend because the /n option is in effect
; or eof is not 0.  basically, stuff a cntrl-z in the caller's buffer,
; set the return count and return

inputeof:
	mov	al,1ah 			; store a ^z
	stosb
	mov	[eof],0			; reset eof flag

inputxit:
	pop	es			; restore reqhdr seg
	sub	di,word ptr es:rqhbuff[bx]  ; calc chars moved
	mov	es:rqhlen[bx],di	; store in parms
	xor	ax,ax
	ret
input endp 

;======================================================================
;,fs
; inputmov
;
; inputmov moves from pipe buffer to user buffer. moves from
; input to output or input to end of buffer.  therefore call twice
; to move all chars.
;
; in:	es:di -> pointer to user buffer
; 	cx = count of chars to move
;	ds -> mainseg
;
; out:	cx updated
;	input pointer updated
;
;,fe
;=====================================================================
	assume	ds:mainseg,es:nothing,ss:nothing
inputmov proc near
	mov	si,[binput]		; get input ptr
	push	cx			; save requested length
	cmp	cx,[bcount]		; smaller of request and available
	jb	inmovcntg
	mov	cx,[bcount]
inmovcntg:
	lea	dx,buffer		; get end of buffer
	add	dx,[bsize]
	mov	ax,dx			; saved for pointer update
	sub	ax,si			; number of contingous chars
	cmp	cx,ax
	jb	inmovmov
	mov	cx,ax			; minimum of request and contiguous
inmovmov:
	mov	ax,cx			; save chars moving
	jcxz	inmovnul
	rep	movsb
inmovnul:
	pop	cx			; length requested
	sub	cx,ax			; less chars moved
	cmp	si,dx			; at end of buffer
	jne	inmovupd
	lea	si,buffer		; yes reset to start of buffer
inmovupd:
	mov	[binput],si		; update input pointer
	sub	[bcount],ax		; and buffered char count
	ret
inputmov endp 

;======================================================================
;,fs
; pollin
;
; wake up if eof gets set or some data is put in the buffer.
;
; in:	none
;
; out:	ax = 0 to wake up
;
;,fe
;=====================================================================
	assume	ds:nothing,es:nothing,ss:nothing
pollin proc near
	xor	ax,ax			; wake return
	test	[eof],-1
	jnz	pollinx
	test	[bcount],-1
	jnz	pollinx
	mov	al,2			; stay asleep
pollinx:
	retf
pollin endp 

;======================================================================
;,fs
; ndinput 
;
; non-destructive input routine - check if characters are ready
; for input.  returns busy if not.
;
; in:	es:bx -> request header
;	ds -> mainseg
;
; out:	none
;
;,fe
;=====================================================================
	assume	ds:mainseg,es:nothing,ss:nothing
ndinput proc near
	mov	ax,rqsbusy		; flag busy if no chars
	test	[bcount],-1
	jz	ndinpxit
	mov	si,[binput]		; return first byte
	mov	al,[si]
	mov	es:rqhunit[bx],al	; return byte
	xor	ax,ax
ndinpxit:
	ret
ndinput endp 

;======================================================================
;,fs
; instatus
;
; if this driver were to return a busy status if the buffer is empty
; this would just make mos suspend until some data is available before
; calling the input fuction.  since the input function is already
; setup to do this, a non-busy status is returned.
;
; in:	es:bx -> request header
;	ds -> mainseg
;
; out:	none
;
;,fe
;=====================================================================
	assume	ds:mainseg,es:nothing,ss:nothing
instatus proc near
	xor	ax,ax			; indicate device ready
	ret
instatus endp 

;======================================================================
;,fs
; flush
;
; in:	es:bx -> request header
;	ds -> mainseg
;
; out:	none
;
;,fe
;=====================================================================
	assume	ds:mainseg,es:nothing,ss:nothing
flush proc near
	lea	dx,buffer
	mov	[binput],dx
	mov	[boutput],dx
	xor	ax,ax
	mov	[bcount],ax		; clear count
	mov	[eof],al		; and eof flag
	jmp	donestat
flush endp 

;======================================================================
;,fs
; output
;
; pipe output routine - transfer up to max of count character
; from caller to circular buffer.  this routine will only get
; what it can hold in its buffer.
;
; in:	es:bx -> request header
;	ds -> mainseg
;
; out:	none
;
;,fe
;=====================================================================
	assume	ds:mainseg,es:nothing,ss:nothing
output proc near
	mov	cx,es:rqhlen[bx]	; cx = request count
	push	ds
	push	es
	mov	ax,ds
	lds	si,es:rqhbuff[bx]	; pointer to caller's buffer
	mov	es,ax
	assume	ds:nothing,es:mainseg	; es => our buffer  ds => user buffer
outputlup:
	call	outputmov		; move chars to caller
	call	outputmov		; decrementing cx
	jcxz	outputxit		; read plenty

; suspend until more data is read from the buffer

	push	bx			; save offset to request packet
					; es == cs for poll routine
	mov	ax,0780h		; poll wait
	lea	bx,pollout
	call38				; call int 38 vector
	pop	bx
	jmp	outputlup
outputxit:
	pop	es			; restore reqhdr seg
	pop	ds
	assume	ds:mainseg,es:nothing
	xor	ax,ax
	mov	[update],-1		; flag data written
	ret
output endp 

;======================================================================
;,fs
; inputmov
;
; outputmov moves from user buffer to pipe buffer. moves from
; output to input or output to end of buffer.  therefore call twice
; to move all chars.
;
; in:	ds:si -> pointer to user buffer
; 	cx = count of chars to move
;	es -> mainseg
;
; out:	cx updated
;	input pointer updated
;
;,fe
;=====================================================================
	assume	ds:nothing,es:mainseg
outputmov proc near
	push	cx			; save requested length
	mov	ax,[bsize]
	sub	ax,[bcount]		; smaller of request and available
	cmp	cx,ax
	jb	outmovcntg
	mov	cx,ax			; use size available
outmovcntg:
	mov	di,[boutput]		; get output ptr
	lea	dx,buffer		; get end of buffer
	add	dx,[bsize]
	mov	ax,dx			; save for pointer update
	sub	ax,di			; number of contingous chars
	cmp	cx,ax
	jb	outmovmov
	mov	cx,ax			; minimum of request and contiguous
outmovmov:
	mov	ax,cx			; save chars moving
	jcxz	outmovnul
	rep	movsb
outmovnul:
	pop	cx			; length requested
	sub	cx,ax			; less chars moved
	cmp	di,dx			; test at end of buffer
	jne	outmovupd
	lea	di,buffer
outmovupd:
	mov	[boutput],di		; update output pointer
	add	[bcount],ax		; and buffered char count
	ret
outputmov endp 

;======================================================================
;,fs
; pollout
;
; stay suspended as long as the buffer is full
;
; in:	none
;
; out:	ax = 0 to wake up
;
;,fe
;=====================================================================
	assume	ds:nothing,es:nothing,ss:nothing
pollout proc near
	mov	ax,[bsize]
	cmp	ax,[bcount]		; full?
	mov	ax,0
	ja	polloutx		; more room - wake up
	mov	al,2			; sleep
polloutx:
	retf
pollout endp 

;======================================================================
;,fs
; outstat
;
; if this driver were to return a busy status if the buffer is full
; this would just make mos suspend until some room is available before
; calling the output fuction.  since the output function is already
; setup to do this, a non-busy status is returned.
;
; in:	es:bx -> request header
;	ds -> mainseg
;
; out:	none
;
;,fe
;=====================================================================
	assume	ds:mainseg,es:nothing,ss:nothing
outstat proc near
	xor	ax,ax
	ret
outstat endp 

;======================================================================
;,fs
; ioctlout
;
; allow eof to be set
;
; in:	es:bx -> request header
;	ds -> mainseg
;
; out:	none
;
;,fe
;=====================================================================
	assume	ds:mainseg,es:nothing,ss:nothing
ioctlout proc near
	push	es
	les	si,es:rqhbuff[bx]	; get pointer to eof value
	mov	al,es:[si]
	mov	[eof],al
	pop	es			; restore reqhdr seg
	mov	es:rqhlen[bx],5 	; pointer return ??
	xor	ax,ax
	ret
ioctlout endp 

;======================================================================
;,fs
; close
;
; when the pipe device is closed and any data was written then
; set eof.
;
; in:	es:bx -> request header
;	ds -> mainseg
;
; out:	none
;
;,fe
;=====================================================================
	assume	ds:mainseg,es:nothing,ss:nothing
close proc near
	xor	ax,ax			; get/clear update flag
	xchg	al,[update]
	or	[eof],al		; keep eof set on consecutive closes
	xor	ax,ax
	ret
close endp 

;======================= data buffer allocation here ====================

buffer	label	byte

message db'MOS Pipe v4.11',13,10
	db	'Pipe $'
devmsg1 db' with '			;@@xlat
dvsize	db'      byte buffer installed.  ',13,10,'$'  ;@@xlat
nwmsg	db '    NOWAIT Option in Effect   ',13,10,'$'  ;@@xlat
ten	dw	10			; constant

;======================================================================
;,fs
; init
;
; in:	es:bx -> request header
;	ds -> mainseg
;
; out:	none
;
;,fe
;=====================================================================
	assume	ds:mainseg,es:nothing,ss:nothing
init proc near
	cld
	push	bx			; save reqhdr pointer
	push	es

; save int 38 vector

	mov	ah,2
	int	services
	mov	ax,word ptr es:[bx+scbfar38]
	mov	[far38],ax
	mov	ax,word ptr es:[bx+scbfar38+2]
	mov	[far38+2],ax

; get command pararmeters

	pop	es			; restore reqhdr pointer
	pop	bx
	push	ds
	lds	si,es:dizline[bx]	; get command parameter
	assume	ds:nothing
	push	si
pscan1:
	lodsb				; get next byte
	cmp	al,0dh			; is this the end
	je	pscan2
	cmp	al,'/'			; is this a /
	jne	pscan1
	lodsb
	cmp	al,'N'			; is this /n for nowait?
	jne	pscan1
	mov	[pipenw],al		; set nowait option
	mov	word ptr [si-2],'  '	; blank out '/N'
pscan2:
	pop	si
scan1:
	lodsb				; scan for first space
	cmp	al,0dh
	je	finishe
	cmp	al,' '
	jne	scan1
scan2:
	lodsb				; scan til first non-space
	cmp	al,0dh
	je	finishe
	cmp	al,' '
	je	scan2
	mov	cx,8			; maximum chars in devname
	lea	di,devname
	dec	si
scan4:					; first parm is device name
	lodsb
	cmp	al,' '
	je	scan5
	cmp	al,','
	je	scan5
	cmp	al,0dh
	je	scan5
	jcxz	scan4			; skip store if no room in devname
	mov	cs:[di],al
	inc	di
	dec	cx
	jmp	scan4
scan5:					; blank remainder of devname
	jcxz	scan6
	mov	byte ptr cs:[di],' '
	inc	di
	loop	scan5
scan6:					; next parm is pipe size
	lodsb
	cmp	al,0dh
finishe:je	finish
	cmp	al,','
	je	scan6
	cmp	al,' '
	je	scan6			; skip intervening spaces
scansize:
	xor	dx,dx			; zero out value
	mov	cx,5			; maximum digits
sizeloop:
	cmp	al,'0'
	jb	scan7
	cmp	al,'9'
	ja	scan7
	and	ax,0fh 			; get digit value
	push	ax
	mov	al,10
	mul	dx			; previous * 10
	pop	dx
	add	dx,ax			; plus this digit
	lodsb				; next digit
	loop	sizeloop
scan7:
	cmp	dx,1
	jb	sizedef
	cmp	dx,16384
	ja	sizedef
	jmp	sizedone
sizedef:
	mov	dx,64			; use default size
sizedone:
	mov	[bsize],dx		; store buffer size

	lea	di,dvsize+5
	mov	ax,dx
sizedisp:
	xor	dx,dx			; display number scanned
	div	[ten]
	or	dl,'0'
	dec	di
	mov	cs:[di],dl
	or	ax,ax
	jnz	sizedisp
finish:
	pop	ds
	assume	ds:mainseg
	lea	cx,buffer+15
	add	cx,[bsize]		;adjust size
	and	cx,0fff0h
	mov	word ptr es:diztail[bx],cx
	mov	word ptr es:diztail+2[bx],cs
	mov	ah,9
	lea	dx,message
	int	21h
	lea	dx,devname
	int	21h
	lea	dx,devmsg1
	int	21h
	test	[pipenw],-1
	jz	finwait
	lea	dx,nwmsg
	int	21h
finwait:
	xor	ax,ax			; completed function
	ret
init endp 

mainseg ends
	end	begin

