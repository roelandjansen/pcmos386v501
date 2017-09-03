	include page.inc
	title	genmbr - generate mbrbuf.inc
comment ^===============================================================
		    development specification

 program name:	genmbr.exe		assigned to: mjs
 module name:	genmbr			assign date: 12/16/91
 entry points:	genmbr			completed: 12/16/91
 entry from:	exec
 entry method:	exec
 calls:		n/a
 purpose:	generate mbrbuf.inc for hdsetup.c
 refer to:	n/a
 last update:	04/01/92

=======================================================================

mjs 04/01/92	dlg mods: created this module.

=======================================================================^

dgroup	group	_DATA,_BSS

_TEXT	segment para public 'CODE'
        assume  cs:_TEXT,ds:nothing,es:nothing,ss:stack
start:
	jmp	begin

;======================================================================
;,fs
; byte2hex
;
; in:	al = byte to be converted
;	ds:si -> buffer in which to write result
;
; out:	buffer at ds:si contains two ascii characters
;
;,fe
;======================================================================
	assume	ds:dgroup,es:nothing
byte2hex:
	push	ax
	push	bx
	push	si
	lea	bx,[hex_table]
	push	ax
	shr	al,1
	shr	al,1
	shr	al,1
	shr	al,1
	xlat	hex_table
	mov	[si],al
	pop	ax
	and	al,0fh
	xlat	hex_table
	mov	[si+1],al
	pop	si
	pop	bx
	pop	ax
	ret

;==== main code

begin:
	mov	ax,_data
	mov	ds,ax
	assume	ds:dgroup
	mov	ax,bootseg
	mov	es,ax
	assume	es:bootseg
	mov	ah,9
	mov	dx,offset start_str
	int	21h
	xor	bx,bx
	mov	cx,512/8
xx1:
	push	cx
	mov	si,offset lbuf+6
	mov	cx,8
xx3:
	mov	al,es:[bx]
	inc	bx
	call	byte2hex
	add	si,6
	loop 	xx3
	mov	ah,9
	mov	dx,offset lbuf
	int	21h
	mov	ah,9
	mov	dx,offset eol_str
	pop	cx
	cmp	cx,1
	jne	xx5
	inc	dx
xx5:
	int	21h
	loop 	xx1
	mov	ah,9
	mov	dx,offset final_str
	int	21h
	mov	al,0			; errorlevel 0
terminate:
	mov	ah,4ch
	int	21h

_TEXT	ends

_DATA	segment para public 'DATA'


start_str db	'byte mbr_buf[] = {',13,10,'$'

lbuf	  db	'    0xHH, 0xHH, 0xHH, 0xHH, 0xHH, 0xHH, 0xHH, 0xHH$'

eol_str   db	',',13,10,'$'

final_str db	'};',13,10,'$'


hex_table 	db	'0123456789ABCDEF'


_DATA	ends

_BSS	segment para public 'BSS'
_BSS	ends

STACK	segment para stack 'STACK'
	db	1024 dup('stack')
stack_top label word
STACK	ends

	include	mbr.inc

	end	start

