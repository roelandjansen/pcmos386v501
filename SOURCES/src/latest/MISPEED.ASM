	include page.inc
	title	mispeed.asm
	subttl	mispeed.asm - intel inboard 386/pc speed control utility
comment ^===============================================================
		     development specification

 program name: mispeed.com		   assigned to: martin stitt
 module name:	mispeed 		   assign date: 12/01/89
 entry points: mispeed 		   completed: 12/11/89
 entry from:	command processor
 entry method: exec
 purpose:	control speed of intel inboard 386/pc under mos
 refer to:	n/a
 last update:	12/11/89

=======================================================================

 note: this module requires the minbrdpc.sys device driver be loaded

 usage:  mispeed n

  where n is:
    1 for 30 wait states (slowest)
    2 for 16 wait states
    3 for 8 wait states
    4 for 0 wait states (fastest)
    ? for status information

=======================================================================

======================================================================^

include mispeed.pub

code	segment para	public	'code'
	assume	cs:code, ds:code, es:code
	org	0100h
start:
	jmp	begin

waittable	db	30		; slowest, 30 wait states
		db	16		; medium slow, 16 wait states
		db	8		; medium fast, 8 wait states
		db	0		; full bore, 0 wait states

progid	db	13,10,'MISPEED - speed control utility for the Intel Inboard PC              '	;@@xlat
	db	13,10,'(c) Copyright 1989 The Software Link, Incorporated',13,10,'$'  ;@@xlat
noparm	db	13,10,'Parameter not supplied                   ',13,10,'$'  ;@@xlat
invparm db	13,10,'Invalid parameter                 ',13,10,'$'  ;@@xlat
parmdoc db	13,10,'Parameter format:  MISPEED n      ',13,10  ;@@xlat
	db	13,10,'  where n is:        '  ;@@xlat
	db	13,10,'    1 for 30 wait states (slowest)          '  ;@@xlat
	db	13,10,'    2 for 16 wait states               '  ;@@xlat
	db	13,10,'    3 for 8 wait states                '  ;@@xlat
	db	13,10,'    4 for 0 wait states (fastest)           '  ;@@xlat
	db	13,10,'    ? for status information                 '  ;@@xlat
	db	13,10,'$'
sethead db	13,10,'Setting the Inboard to $                  '  ;@@xlat
settail db	' wait states              ',13,10,'$'	;@@xlat
set1	db	'30$'			;@@xlat
set2	db	'16$'			;@@xlat
set3	db	'8$'			;@@xlat
set4	db	'0$'			;@@xlat
whatdid dw	set1
	dw	set2
	dw	set3
	dw	set4

delimset db	',',20h,0		; default set of delimiters

minbpc_name	db	'minbpc',0	; the device name within minbrdpc.sys

nominbpc	db	13,10,'MINBRDPC.SYS not found                 ',13,10,'$'  ;@@xlat
badioctl	db	13,10,'Error from IOCTL call to MINBRDPC.SYS            ',13,10,'$'  ;@@xlat

statbuf 	db	3 dup(?); for status info from the dd
dispbuf 	db	'   ',13,10,'$'  ; convert the wait states into here

stathd1 db	13,10,'Current wait states:$                  '  ;@@xlat
stathd2 db	13,10,'Hard disk wait states:$                  '  ;@@xlat
stathd3 db	13,10,'Floppy disk wait states:$                  '  ;@@xlat
crlf	db	13,10,'$'


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
	jmp	short tst1		; keep trying
tst2:
	xor	al,al			; if exit the loop to here,
	cmp	al,1			; set the nz flag - no match
tst3:
	pop	si
	pop	ax
	ret


	subttl testdelims - test for whitespace
	page
;======================================================================
; .func: testdelims - test for whitespace
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


	subttl passdelims - advance ds:si past whitespace
	page
;======================================================================
; .func: passdelims - advance ds:si past whitespace
;
; input:
;	ds:si -> string to parse
;
; output:
;	ds:si -> first non-delimiter found in string
;	al = character found
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
passdelims:
	cld
psd1:
	lodsb
	call	testdelims
	je	psd1 
	dec	si
	ret


	subttl word2dec - convert string to number
	page
;======================================================================
; .func: word2dec - convert string to number
;
; input:
;	dx:ax is source integer
;	cx is length of target string
;	ds:bx -> end of target buffer area (location of 1's digit
;
; output:
;	buffer contains ascii string
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

wordten dw	10

word2dec:
	push	cx
w2d1:
	div	cs:[wordten]		; divide by 10
	add	dl,'0'			; make ascii digit from remainder
	mov	[bx],dl 		; and write in buffer
	dec	bx			; writing right to left
	xor	dx,dx			; setup for next cycle
	loop		w2d1		; do cx digits
	pop	cx
w2d3:
	inc	bx
	dec	cx			; parse forward through the
	jz	w2d4 
	cmp	byte ptr [bx],'0' 	; buffer and blank out
	jne	w2d4 
	mov	byte ptr [bx],' '	; leading zeros
	jmp	short w2d3
w2d4:
	ret


	subttl dumpstatus - read and display status info from driver
	page
;======================================================================
; .func: dumpstatus - read and display status info from driver
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
dumpstatus:
	xor	ah,ah
	xor	dx,dx
	mov	al,[statbuf]
	mov	bx,offset dispbuf+2
	mov	cx,2
	call	word2dec
	mov	dx,offset stathd1
	mov	ah,9
	int	21h
	mov	dx,offset dispbuf
	mov	ah,9
	int	21h
	xor	ah,ah
	xor	dx,dx
	mov	al,[statbuf+1]
	mov	bx,offset dispbuf+2
	mov	cx,2
	call	word2dec
	mov	dx,offset stathd2
	mov	ah,9
	int	21h
	mov	dx,offset dispbuf
	mov	ah,9
	int	21h
	xor	ah,ah
	xor	dx,dx
	mov	al,[statbuf+2]
	mov	bx,offset dispbuf+2
	mov	cx,2
	call	word2dec
	mov	dx,offset stathd3
	mov	ah,9
	int	21h
	mov	dx,offset dispbuf
	mov	ah,9
	int	21h
	mov	dx,offset crlf
	mov	ah,9
	int	21h
	ret


;*********************** main code ********************

	assume	cs:code, ds:code, es:code
begin:
	mov	bp,1			; set showdoc flag
	mov	dx,offset progid
	mov	ah,9
	int	21h
	mov	al,ds:[80h]
	mov	dx,offset noparm
	cmp	al,0 
	jne	main15
	jmp	main1 
main15:
	xor	ah,ah
	add	ax,81h
	mov	si,ax
	mov	byte ptr [si],0 	; convert the psp parm to asciiz
	mov	si,81h
	call	passdelims
	cmp	al,0 
	jne	main16
	jmp	main1 
main16: 
	mov	dx,offset invparm	; at this point, found some parameter
	mov	ah,al			; save parm character
	inc	si
	call	passdelims
	cmp	al,0 
	jne	main1 
	mov	al,ah
	xor	ah,ah
	cmp	al,'?' 
	jne	main2 
	xor	si,si			; use si = 0 as a signal
	jmp	short main3
main2:
	sub	ax,'1'
	cmp	ax,3 
	ja	main1 
	mov	si,offset waittable
	add	si,ax			; make si point to the wait value
main3:
	mov	bp,0			; clear showdoc flag
	push	ax
	mov	dx,offset minbpc_name
	mov	ax,3d00h
	int	21h
	jnc	main5 
	pop	ax
	mov	dx,offset nominbpc
	jmp	short main1
main5:
	mov	bx,ax
	cmp	si,0 
	jne	main6 
	mov	ax,4402h
	mov	dx,offset statbuf	; yes, read status
	mov	cx,3
	jmp	short main7
main6:
	mov	ax,4403h		; no, write speed
	mov	dx,si			; use ioctl write to send the
	mov	cx,1			; new wait state value to the dd
main7:
	int	21h
	jnc	main9 
	pop	ax
	mov	dx,offset badioctl	; if can't make ioctl, don't bother
	jmp	short main1		; trying to close
main9:
	mov	ah,3eh
	int	21h
	pop	bx			; pushed as ax
	cmp	si,0 
	jne	main10 
	call	dumpstatus
	jmp	short main11
main10:
	mov	dx,offset sethead	; tell'em what we did
	mov	ah,9
	int	21h
	add	bx,bx			; convert to word index
	mov	dx,[bx+whatdid]
	mov	ah,9
	int	21h
	mov	dx,offset settail
	mov	ah,9
	int	21h
main11:
	xor	ax,ax			; set good errorlevel
	jmp	short main13
main1:
	mov	ah,9			; error handler, entry with
	int	21h			; dx -> error message
	cmp	bp,1 
	jne	main14 
	mov	dx,offset parmdoc
	mov	ah,9
	int	21h
main14:
	mov	al,1			; set errorlevel
main13:
	mov	ah,4ch
	int	21h
code	ends
	end	start
