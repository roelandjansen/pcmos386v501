	page	95,132
mainseg	segment	para
	assume	cs:mainseg,ds:mainseg

;-------------------------------------------------------------------;
;  The parameters NOTRACKS and NOSECS need to be changed according  ;
;  to the type of diskette that is being duplicated:                ;
;                   ;---------------------------;                   ;
;                   ;  360K   1.2M  720K  1.44M ;                   ;
;                   ;                           ;                   ;
NOTRACKS equ	80  ;   40     80    80    80   ; Tracks per side   ;
NOSECS	 equ	18  ;    9     15     9    18   ; Sectors per track ;
;                   ;---------------------------;                   ;
;-------------------------------------------------------------------;

	org	0100h
begin	label	near
	jmp	start
	db	'Copyright 1991 The Software Link, Incorporated'
	org	200h
stackloc dw	0		; stack starts here

filename db	65 dup(0)		; name of input file
msgrerr	 db	13,10,10,'Diskette read error!',13,10,'$'
msgwerr	 db	13,10,'Error writing output file!',13,10,'$'
msgcrlf	 db	13,10,'$'
msgdot	 db	0fah,'$'

	 even
handle	 dw	0
buffaddr dw	0
cylinder db	0
drive	 db	0
retries	 db	3

start	label	near
	mov	sp,offset stackloc
	mov	si,81h
	call	findnb			; position si to first non-blank
	mov	di,offset filename	; and copy operand to work area
	cld
getloop:
	lodsb
	cmp	al,20h
	jbe	glout
	stosb
	jmp	getloop
glout:
	mov	ax,ds			; compute I/O buffer address
	mov	bx,offset progend+15
	mov	cl,4
	shr	bx,cl
	add	ax,bx
	add	ax,0fffh
	and	ax,0f000h
	mov	[buffaddr],ax

	mov	ah,3ch			; create output file
	mov	cx,0
	mov	dx,offset filename
	int	21h
	jnc	$+5
	jmp	werror
	mov	[handle],ax

	mov	ah,09h			; write cr,lf
	mov	dx,offset msgcrlf
	int	21h

	mov	[cylinder],0		; start at cylinder 0
	mov	[retries],3

	mov	ah,0			; reset diskette controller
	int	13h

nextcyl label	near
	mov	es,[buffaddr]		; prepare to read data
	mov	ch,[cylinder]
	mov	cl,1
	mov	dl,[drive]

	mov	ah,02h			; read head 0
	mov	al,NOSECS
	mov	bx,0
	mov	dh,0
	int	13h

	jnc	gothead0
	dec	[retries]		; allow timeout for motor startup
	jnz	nextcyl
	jmp	rerror
gothead0:
	mov	ah,02h			; read head 1
	mov	al,NOSECS
	mov	bx,NOSECS*512
	mov	dh,1
	int	13h
	jc	rerror

	mov	ah,40h			; write next cylinder's worth
	mov	bx,[handle]
	mov	cx,NOSECS*2*512
	push	ds
	mov	ds,[buffaddr]
	xor	dx,dx
	int	21h
	pop	ds
	jc	werror
	cmp	ax,cx
	jne	werror

	mov	ah,09h			; write a period for each cylinder
	mov	dx,offset msgdot

	int	21h

	inc	[cylinder]
	cmp	[cylinder],NOTRACKS
	jb	nextcyl

	jmp	alldone

werror	label	near
	mov	dx,offset msgwerr
	mov	ah,9
	int	21h
	jmp	alldone

rerror	label	near
	mov	dx,offset msgrerr
	mov	ah,9
	int	21h
	jmp	alldone

findnb	proc	near
	cmp	byte ptr ds:[si],20h
	je	$+3
	ret
	inc	si
	jmp	findnb
findnb	endp

alldone	label	near
	mov	ah,3eh
	mov	bx,[handle]
	int	21h
	int	20h

progend	label	near

mainseg	ends
	end	begin
