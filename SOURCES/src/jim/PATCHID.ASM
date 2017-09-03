	include page.inc
	title	mositask - initialize new task

comment ^===============================================================
		    development specification

 program name:	patchid.com		assigned to: martin stitt
 module name:	patchid.asm		assign date: 08/26/90
 entry points:	cs:100			completed:   08/28/90
 entry from:	exec
 entry method:	exec
 calls:		
 purpose:	report patches to 4.10+ kernel
 refer to:	
 last update:	

=======================================================================

PURPOSE
=======

Beginning with release 4.10, patches to the MOS kernel will be 
assigned names which include sequential patch numbers.  For example,
410_P1.PAT, 410_P2.PAT, etc.  

The PATCHID.COM utility reads a user's $$MOS.SYS file, locates
the patch list within it and reports the numbers of the patches
which have been applied.  This patch list is new to version 4.10.


HOW TO USE
==========

Presuming that the file $$MOS.SYS is located within the root
directory of the current drive, simply enter:

PATCHID

If the $$MOS.SYS file is located elsewhere, supply the complete
drive, path and filename.ext:

PATCHID A:\$$MOS.SYS

NOTE
====

Just in case your customer's kernel was patched with patches
410_P1.PAT, 410_P2.PAT or 410_P3.PAT before they were corrected on
08/28/90, you should have them run 410_P4.PAT before running
PATCHID.COM.  This fourth patch will correct any errors introduced by
the use of an old copy of one of these first three patches.


=======================================================================

mjs 09/18/90	added display of version number of the patchid program

mjs 11/05/90	increased stack size to 1000 bytes to appease $acl.sys.
		bumped version number up to 1.01

======================================================================^

code	segment	para	public	'code'
	assume	cs:code, ds:code, es:code
	org	0100H
start:
	jmp	begin

	include	patchid.pub

	include macros.inc

; equates

alloc_request	equ	1000h - 1	; initial buffer request size
nw_margin	equ	32		; reduction to read size so can
					; ignore wrap around considerations
min_buf		equ	512		; minimum acceptable buffer size
carry_blk_size	equ	128		; size of block to be carried around
max_table_size	equ	256		; amount to read when find patch table

; data

alloc_bytes	dw	?		; actual buffer size
handle		dw	?		; file handle
adj_once	db	0		; controls read_request adjustment
eof		db	0		; flags the current read as the last
read_ofs	dw	?		; point to load file data
file_ofs	dw	?,?		; lseek offset within file
buffer_seg	dw	?		; segment of buffer for file data
read_request	dw	?		; size of block to be read from file
read_actual	dw	?		; bytes actually read from file
state		db	?		; used to track ranges of patch #s
patch_num	db	?		; used to track ranges of patch #s
start_num	db	?		; used to track ranges of patch #s
dispr_once	db	0		; used by disp_range for seperators
wordten		dw	10		; used by word2dec

; reference strings and misc messages

dflt_fname	db	'\$$mos.sys',0
patch_str	db	'[PATCH]'
pstr_len	equ	$-patch_str
pl_msg		db	'Your kernel is at patch level $           '  ;@@xlat
patch_msg	db	'Patches applied:       ',13,10,13,10,'$'  ;@@xlat
empty_msg	db	'None    ',13,10,'$'  ;@@xlat
crlf_str	db	13,10,'$'
dec_buf		db	'   $'
sep_str		db	', $'
thru_str	db	' through$        ' ;@@xlat
copyright	db	'(c) Copyright 1990 The Software Link, Incorporated',13,10,'$'  ;@@xlat
version		db	'PATCHID.COM version 1.01',13,10,'$' ;@@xlat

; error messages

err_lead	db	13,10,'Error - $          ' ;@@xlat
lowmem_err	db	'Insufficient memory            ',13,10,'$'  ;@@xlat
badmem_err	db	'Memory chain corrupt            ',13,10,'$'  ;@@xlat
open_err	db	'Opening source file              ',13,10,'$'  ;@@xlat
read_err	db	'Reading source file              ',13,10,'$'  ;@@xlat
lseek_err	db	'Seeking in source file              ',13,10,'$'  ;@@xlat
nomatch_err	db	'Patch list not found           ',13,10,'$'  ;@@xlat
close_err	db	'Closing source file              ',13,10,'$'  ;@@xlat
badtabl_err	db	'Bad table format               ',13,10,'$'  ;@@xlat


	subttl disp_str - send cs:dx string to standard output
	page
;======================================================================
; .func: disp_str - send cs:dx string to standard output
;
; input:
;	cs:dx -> $ terminated string
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
disp_str:
	pushset ax,ds
	mov	ax,cs
	mov	ds,ax
	mov	ah,9
	int	21h
	popset ax,ds
	ret


	subttl crlf - send a newline to standard out
	page
;======================================================================
; .func: crlf - send a newline to standard out
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
crlf:
	push	dx
	mov	dx,offset crlf_str
	call	disp_str
	pop	dx
	ret


	subttl word2dec - convert a word to a decimal number
	page
;======================================================================
; .func: word2dec - convert a word to a decimal number
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
word2dec:
	push	cx
xx1:
	div	cs:[wordten]		; divide by 10
	add	dl,'0'			; make ascii digit from remainder
	mov	[bx],dl			; and write in buffer
	dec	bx			; writing right to left
	xor	dx,dx			; setup for next cycle
	loop 	xx1			; do cx digits
	pop	cx
xx3:
	inc	bx
	dec	cx			; parse forward through the 
	jz	xx4 
	cmp	byte ptr [bx],'0' 
	jne	xx4 
	mov	byte ptr [bx],' '	; leading zeros
	jmp	short xx3
xx4:
	ret


	subttl disp_range - display patch numbers found in table
	page
;======================================================================
; .func: disp_range - display patch numbers found in table
;
; input:
;	al = starting number
;	bl = ending number
;
; output:
;
; comments:
;	if not the first call
;	  displays a comma and space
;	if al == bl
;	  displays one #
;	else
;	  if al+1 == bl
;	    displays #, #
;	  else
;	    displays  # through #
;
; .calls: 
; .reads: 
; .writes: 
;
; .endfn
;======================================================================
	assume	ds:nothing,es:nothing,ss:nothing
disp_range:
	pushset ax,bx,cx,dx,ds
	mov	dx,cs
	mov	ds,dx
	pushset ax,bx
	cmp	[dispr_once],0 
	je	xx5 
	mov	dx,offset sep_str
	call	disp_str
xx5:
	mov	[dispr_once],1
	xor	dx,dx
	xor	ah,ah
	mov	cx,3
	mov	bx,offset dec_buf+2
	call	word2dec
	popset ax,bx
	inc	al
	cmp	bl,al 
	jna	xx6 
	mov	dx,offset dec_buf
	call	disp_str
	mov	dx,offset thru_str
	call	disp_str
	mov	al,bl
	xor	ah,ah
	xor	dx,dx
	mov	cx,3
	mov	bx,offset dec_buf+2
	call	word2dec
xx6:
	cmp	al,bl 
	jne	xx7 
	mov	dx,offset dec_buf
	call	disp_str
	mov	dx,offset sep_str
	call	disp_str
	mov	al,bl
	xor	ah,ah
	xor	dx,dx
	mov	cx,3
	mov	bx,offset dec_buf+2
	call	word2dec
xx7:
	mov	dx,offset dec_buf
	call	disp_str
	popset ax,bx,cx,dx,ds
	ret



;*********************** MAIN CODE ********************

	assume	cs:code, ds:code, es:code
begin:
	mov	sp,offset stack_top
	call	crlf
	mov	dx,offset version
	call	disp_str
	mov	dx,offset copyright
	call	disp_str
	call	crlf

; shrink back

	mov	bx,offset end_prog
	shr	bx,1
	shr	bx,1
	shr	bx,1
	shr	bx,1
	mov	ah,4ah
	int	21h

; if parm, use for full filespec - else, just use $$mos.sys

	cld
	mov	dx,offset dflt_fname
	mov	cl,ds:[80h]
	xor	ch,ch
	cmp	cx,0 
	je	xx11 
	mov	bx,81h
	mov	si,bx
	add	bx,cx
	mov	byte ptr [bx],0
xx9:
	lodsb
	cmp	al,' ' 
	je	xx9 
	cmp	al,9 
	je	xx9 
	cmp	al,0 
	je	xx11 
	dec	si
	mov	dx,si
xx9a:
	lodsb
	cmp	al,' '
	je	xx9b
	cmp	al,0
	je	xx9b
	cmp	al,9
	jne	xx9a
xx9b:
	mov	byte ptr [si-1],0
xx11:

; open source file

	mov	ax,3d00h
	int	21h
	jnc	xx12 
	mov	dx,offset open_err
	jmp 	xx13
xx12:
	mov	[handle],ax

; allocate block for file data

	mov	bx,alloc_request
	mov	ax,bx
	shl	ax,1
	shl	ax,1
	shl	ax,1
	shl	ax,1
	mov	[alloc_bytes],ax
	mov	ah,48h
	int	21h
	jnc	xx16 
	cmp	ax,8 
	je	xx15 
	mov	dx,offset badmem_err
	jmp 	xx13
xx15:
	mov	[alloc_bytes],0
	cmp	bx,(min_buf/16) 
	jnae	xx16 
	mov	cx,bx
	shl	cx,1
	shl	cx,1
	shl	cx,1
	shl	cx,1
	mov	[alloc_bytes],cx
	mov	ah,48h
	int	21h
xx16:
	cmp	[alloc_bytes],min_buf 
	jnb	xx17 
	mov	dx,offset lowmem_err
	jmp 	xx13
xx17:
	mov	[buffer_seg],ax

; back off a bit from the end of the buffer so no worry of wrap-around
; and zero fill the area so a partial match at eob will fail for sure

	sub	[alloc_bytes],nw_margin
	mov	di,[alloc_bytes]
	mov	es,[buffer_seg]
	assume	es:nothing
	mov	cx,nw_margin
	xor	al,al
	cld
	rep	stosb

; prepare for the file read/scan loop

	mov	ax,[alloc_bytes]
	mov	[read_request],ax
	mov	ax,ds
	mov	es,ax
	assume	es:code
xx18:

; record the current file offset

	mov	bx,[handle]
	mov	ax,4201h
	xor	cx,cx
	xor	dx,dx
	int	21h
	jnc	xx20 
	mov	dx,offset lseek_err
	jmp 	xx13
xx20:
	mov	[file_ofs],ax
	mov	[file_ofs+2],dx

; read a block from the $$mos.sys file

	mov	dx,[read_ofs]
	mov	cx,[read_request]
	mov	ah,3fh
	mov	bx,[handle]
	mov	ds,[buffer_seg]
	assume	ds:nothing
	int	21h
	jnc	xx21 
	mov	dx,offset read_err
	jmp 	xx13
xx21:
	mov	bx,cs
	mov	ds,bx
	assume	ds:code
	mov	[read_actual],ax

; if the actual # of bytes read is 0 - all done

	cmp	ax,0 
	jne	xx22 
	mov	dx,offset nomatch_err
	jmp 	xx13
xx22:

; if the actual # of bytes read is less than the request,
; set eof to indicate this is the last block of data

	mov	es,[buffer_seg]
	assume	es:nothing
	cmp	[read_request],ax 
	jna	xx23 
	mov	[eof],1

; to insure no accidental matches, zero the remainder
; of the buffer - the part after the partial read data

	mov	di,[read_ofs]
	add	di,[read_actual]
	mov	cx,[alloc_bytes]
	sub	cx,di
	xor	al,al
	rep	stosb
xx23:

; scan for the patch area identification string

	mov	cx,ax
	xor	di,di
	cld
	mov	al,[patch_str]
xx24:
	repne scasb
	jnz	xx26 
	push	cx
	push	di
	mov	si,offset patch_str+1
	mov	cx,pstr_len-1
	rep	cmpsb
	jnz	xx27 
	add	sp,2			; throw away saved di
	pop	cx
	jmp 	xx19
xx27:
	pop	di
	pop	cx
xx26:
	cmp	cx,0 
	jne	xx24 

; if the last read_actual was less than the read_request, no more

	cmp	[eof],0 
	je	xx28 
	mov	dx,offset nomatch_err
	jmp 	xx13
xx28:

; copy last carry_blk_size bytes to start of buffer

	mov	si,[read_ofs]
	add	si,[read_request]
	sub	si,carry_blk_size
	xor	di,di
	mov	cx,carry_blk_size
	mov	ds,[buffer_seg]
	assume	ds:nothing
	rep	movsb

; after the first read/scan, adjust request size and 
; position for sucessive cycles 

	mov	ax,cs
	mov	ds,ax
	mov	es,ax
	assume	ds:code,es:code
	cmp	[adj_once],0 
	jne	xx29 
	sub	[read_request],carry_blk_size
	mov	[read_ofs],carry_blk_size
	mov	[adj_once],1
xx29:
	jmp 	xx18
xx19:

; calc file offset of end of string and lseek

	mov	ax,cs
	mov	ds,ax
	mov	es,ax
	assume	ds:code,es:code
	mov	dx,[file_ofs]
	mov	cx,[file_ofs+2]
	sub	di,[read_ofs]
	add	dx,di
	adc	cx,0
	mov	bx,[handle]
	mov	ax,4200h
	int	21h
	jnc	xx30 
	mov	dx,offset lseek_err
	jmp 	xx13
xx30:

; read the table into the start of the buffer

	xor	dx,dx
	mov	cx,max_table_size
	mov	ah,3fh
	mov	bx,[handle]
	mov	ds,[buffer_seg]
	assume	ds:nothing
	int	21h
	jnc	xx31 
	mov	dx,offset read_err
	jmp 	xx13
xx31:

; validate the table

	mov	si,3
	mov	cx,[si-3]		; fetch the # of bytes in the table
xx32:
	lodsb
	cmp	al,0 
	je	xx34 
	cmp	al,'Y' 
	je	xx34 
	mov	dx,offset badtabl_err
	jmp 	xx13
xx34:
	loop 	xx32

; report the table's contents to the user

	mov	si,3
	mov	dx,offset pl_msg
	call	disp_str
	assume	ds:nothing
	mov	dl,[si-1]
	mov	ah,2
	int	21h
	call	crlf
	call	crlf
	mov	dx,offset patch_msg
	call	disp_str
	mov	[patch_num],1
	mov	[state],0
	mov	cx,[si-3]		; fetch the # of bytes in the table
	xor	di,di			; once flag
xx35:
	lodsb
	cmp	[state],0 
	jne	xx37 
	cmp	al,'Y' 
	jne	xx38 
	mov	di,1
	mov	[state],1
	mov	al,[patch_num]
	mov	[start_num],al
xx38:
	jmp	short xx41
xx37:
	cmp	al,0 
	jne	xx41 
	mov	[state],0
	mov	al,[start_num]
	mov	bl,[patch_num]
	dec	bl
	call	disp_range
xx41:
	inc	[patch_num]
	loop 	xx35
	mov	ax,cs
	mov	ds,ax
	assume	ds:code
	cmp	[state],1 
	jne	xx42 
	mov	al,[start_num]
	mov	bl,[patch_num]
	dec	bl
	call	disp_range
xx42:
	cmp	di,0 
	jne	xx43 
	mov	dx,offset empty_msg
	call	disp_str
xx43:

; close up - all finished

	mov	bx,[handle]
	mov	ah,3eh
	int	21h
	jnc	xx44 
	mov	dx,offset close_err
	jmp 	xx13
xx44:

;==== normal termination handler

	mov	al,0			; errorlevel 0
	jmp	short xx45
xx13:

;==== error termination handler

	push	dx
	mov	dx,offset err_lead
	call	disp_str
	pop	dx
	call	disp_str
	mov	al,1

xx45:

;==== final termination handler

	call	crlf
	mov	ah,4ch
	int	21h


	even

	db	1000 dup(0)
stack_top label byte

	align 16

end_prog label byte


code	ends
	end	start

