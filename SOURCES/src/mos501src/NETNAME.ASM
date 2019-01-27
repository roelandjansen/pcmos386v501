	include page.inc
	title	NETNAME - provide NETBIOS with a machine name

;-----------------------------------------------------------------------;
; JSM 3/03/87	Converted MultiLink NETNAME to MOS NETNAME		;
;-----------------------------------------------------------------------;
; JSM 4/20/87	Fixed NetBIOS id string & added message if user		;
;		successfully changed netname.				;
;-----------------------------------------------------------------------;
; SAH 11/23/87	Change to version 2.00					;
;		Also remove dos check and mos subversion check		;
;-----------------------------------------------------------------------;
; JSM 12/02/87	Print decent error message if NETBIOS returns 07eh,	;
;		which will be interpreted as "not enough adapters."	;
;-----------------------------------------------------------------------;
; SAH 02/21/89	Masm 5.10 Compatibility 				;
;-----------------------------------------------------------------------;
; BWR 11/30/89	Marked messages for foreign language translation.	;
;-----------------------------------------------------------------------;
	.xlist
	include NETNAME.PUB
	.list

STACKSZ	equ	400h		; bytes in program stack

code	segment
	assume	cs:code,ds:code,es:code,ss:code
	org	0100h
start:	jmp	name0

	db	0dh,'NETNAME v4.00',0dh,0ah
	db	'(c) Copyright 1987, 1988, 1989 The Software Link, Incorporated',1ah ;@@XLAT

version	label	byte
	include	version.inc

; netbios command block to add a unique name and wait for command completion
ncb	db	30h
	db	25 dup(0)
nstr1	db	16 dup(0)
	db	22 dup(0)

nomem	db	0dh,0ah,'Not enough memory for NETNAME$      ' ;@@XLAT
mosvrs	db	0dh,0ah,'Improper MOS version$' ;@@XLAT
nonet	db	0dh,0ah,'NETBIOS driver must be loaded before NETNAME is run$              ' ;@@XLAT

mosid	db	'NETBIOS'		;could be MOSNETBIOS or LLNETBIOS
idlen	equ	$-mosid

dupnam	db	0dh,0ah
nstr2	db	'                is being used$     ' ;@@XLAT
namful	db	0dh,0ah,'Too many names are active$' ;@@XLAT
cmdful	db	0dh,0ah,'Too many network commands are active$' ;@@XLAT
tskful	db	0dh,0ah,'Too many tasks are using NETBIOS$' ;@@XLAT
already db	0dh,0ah,'   User name is  ' ;@@XLAT
nstr3	db	'                $'
termlin	db	0dh,0ah,'$'
unspec	db	0dh,0ah,'NETBIOS error  ' ;@@XLAT
unnum	db	'00$'
noname	db	0dh,0ah,'Use NETNAME to specify a user name for NETBIOS ' ;@@XLAT
	db	'programs                   ',0dh,0ah,0ah ;@@XLAT
	db	'     NETNAME YOURNAME',0dh,0ah,0ah ;@@XLAT
	db	'specifies YOURNAME as the user name$' ;@@XLAT
invnam	db	0dh,0ah,'Invalid name specified         ',0dh,0ah ;@@XLAT
	db	'A name can have up to 15 characters with no spaces$       ' ;@@XLAT
notadd	db	0dh,0ah,'No name was added          ',0dh,0ah,'$' ;@@XLAT

name0:
	mov	bx,offset endall
	add	bx,STACKSZ	; put SP here
	add	bx,0fh		; round up to nearest paragraph
	and	bx,not 0fh
	dec	bx
	dec	bx
	mov	sp,bx		; put sp at max - 2
	inc	bx
	inc	bx
	mov	cl,4
	shr	bx,cl		; convert to paragraphs

	push	cs
	pop	es
	mov	ah,4ah		; shrink program block
	int	21h
	jnc	name1
	mov	dx,offset nomem	; say "not enough memory"
	jmp	namex		; exit with error
name1:
	mov	ax,3000h	; get MOS version this time
	mov	bx,ax
	mov	cx,ax
	mov	dx,ax
	int	21h

	cmp	ax,word ptr [version]
	je	name2
name1a:
	lea	dx,mosvrs	; say "wrong version number"
	mov	ah,09h
	int	21h
	mov	ax,4C02h
	int	21h		; exit with error
name2:
	lea	dx,nonet
	xor	ax,ax
	mov	es,ax
	les	di,dword ptr es:[5ch*4]
	mov	ax,es
	or	ax,di
	jz	namex		;MOSNETBI not loaded
	lea	si,mosid
	mov	cx,idlen
	sub	di,cx
	repe	cmpsb
	jne	namex		;MOSNETBI not loaded
	push	cs
	pop	es
	lea	dx,nstr3
	mov	ax,5e00h
	int	21h
	mov	nstr3+15,'$'	;if previous call succeeded
	lea	dx,already
	or	ch,ch
	jnz	namex
	call	getnam
	jnz	namex
	lea	bx,ncb
	int	5ch
	or	al,al
	jz	namez
	lea	dx,dupnam
	cmp	al,0dh
	je	namex
	lea	dx,dupnam
	cmp	al,16h
	je	namex
	lea	dx,namful
	cmp	al,0eh
	je	namex
	lea	dx,tskful		;JSM 12/02/87
	cmp	al,7eh			;JSM 12/02/87
	je	namex			;JSM 12/02/87
	lea	dx,cmdful
	cmp	al,22h
	je	namex
	lea	di,unnum
	call	hexbyt
	lea	dx,unspec
namex:	push	cs
	pop	ds
	mov	ah,09h
	int	21h
	lea	dx,notadd
	mov	ah,09h
	int	21h
	mov	ax,4c01h
	int	21h

namez:
	lea	dx,already
	push	cs
	pop	ds
	mov	ah,09h
	int	21h
	lea	dx,termlin
	mov	ah,09h
	int	21h
	mov	ax,4c00h
	int	21h

	subttl	getnam - retrieve new name from the command buffer
	page

getnam: push	cs
	pop	ds
	push	cs
	pop	es
	mov	ah,0ffh
	lea	dx,noname
	mov	si,80h
	lodsb
	mov	cl,al
	xor	ch,ch
	jcxz	getnmx
getnm1: lodsb
	cmp	al,' '
	ja	getnm2
	loop	getnm1
	jmp	getnmx
getnm2: dec	si
	lea	di,nstr1
	lea	dx,invnam
getnm3: lodsb
	cmp	al,' '
	jbe	getnm4
	cmp	di,offset nstr1+15
	je	getnmx
	call	caps
	stosb
	loop	getnm3
getnm4: mov	al,' '
	lea	cx,nstr1+15
	sub	cx,di
	rep stosb
	lea	si,nstr1
	lea	di,nstr2
	mov	cx,15
	rep movsb
	lea	si,nstr1
	lea	di,nstr3
	mov	cx,15
	rep movsb
	xor	ah,ah
getnmx: or	ah,ah
	ret

	subttl	caps - for all chars > ' ', hexbyt - convert al to hex ascii
	page


; this capitalizes the same way pcdos does file names
capstbl db	80H,9AH,90H,83H,8EH,85H,8FH,80H,88H,89H,8AH,8BH,8CH,8DH,8EH,8FH
	db	90H,92H,92H,93H,99H,95H,96H,97H,98H,99H,9AH,9BH,9CH,9DH,9EH,9FH
	db	0A0H,0A1H,0A2H,0A3H,0A4H

caps:	cmp	al,'a'
	jb	caps1
	cmp	al,'z'
	jbe	caps2
	cmp	al,80h
	jb	caps1
	cmp	al,0e5h
	je	caps3
	cmp	al,165
	jae	caps1
	push	bx
	lea	bx,capstbl-80H
	xlat	capstbl
	pop	bx
caps1:
	ret
caps2:
	sub	al,'a'-'A'
	ret
caps3:
	mov	al,05h
	ret
	
hexbyt: push	ax
	shr	al,1
	shr	al,1
	shr	al,1
	shr	al,1
	call	hexdig
	pop	ax
hexdig: and	al,0fh
	cmp	al,10
	jb	hexdg1
	add	al,7
hexdg1: add	al,'0'
	stosb
	ret

endall	label	byte

code	ends

	end	start
