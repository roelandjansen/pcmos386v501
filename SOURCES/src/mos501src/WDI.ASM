	page	95,132
mainseg	segment	para
	assume	cs:mainseg,ds:mainseg

include wdi.pub

;-------------------------------------------------------------------;
;  Format for the Write Disk Image (WDI) command is:                ;
;                                                                   ;
;  WDI filename [UU]						    ;
;								    ;
;  Where UU is number of users for system disk			    ;
;								    ;
;  Update 07/26/90 SAH for PC-MOS 4.10 Production Serialization	    ;
;-------------------------------------------------------------------;		

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
	org	0200h
stackloc dw	0		; top of stack

filename db	65 dup(0)		; name of input file
msgserno db	13,10,'Starting serial number (8 characters)? $'
inserno  db	9,0,'???????'
msgdrive db	13,10,'Drive to write (A, B, or X to exit)? $'
msgwerr	 db	13,10,10,'Write error, diskette rejected!',13,10,'$'
msgrerr	 db	13,10,'Error reading input file!',13,10,'$'
msgcrlf	 db	13,10,'$'
msgdot	 db	0fah,'$'
SerMsg	 db	'Creating 3 1/2 PC-MOS Serial #'
Users	 db	0,0			; # of users on system
	 db	'-'
SerVal	 db	'12345678.',13,10,'$'


SavCyl	 db	0			; save cylinder for serial # inplant
SavOff	 dw	0			; save offset for serial # implant

Search	 db	'[MOS]',0		; search for this


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
getop1:
	lodsb
	cmp	al,20h
	jbe	getop1x
	stosb
	jmp	getop1
getop1x:
	dec	si

	call	findnb			; position to second operand
	jb	endops
	lea	di,Users
	movsw				; move Users to storage area
endops:
	mov	ax,ds			; compute I/O buffer address
	mov	bx,offset progend+15
	mov	cl,4
	shr	bx,cl
	add	ax,bx
	add	ax,0fffh
	and	ax,0f000h
	mov	[buffaddr],ax

	cmp	word ptr [Users],0	; check if serializing
	je	getserx			; no, skip
getserno:
	mov	dx,offset msgserno	; ask for serial number
	call	writemsg
	mov	dx,offset inserno
	call	readmsg
	cmp	[inserno+1],8		; must be 8 characters
	jne	getserno
	lea	si,[inserno+2]
	lea	di,SerVal
	mov	cx,4
	rep	movsw
	mov	dx,offset msgcrlf
	call	writemsg

getserx:
	mov	ax,3d00h		; open file for input
	mov	dx,offset filename
	int	21h
	jnc	$+5
jrerror:
	jmp	rerror
	mov	[handle],ax

nextdisk label	near
	mov	dx,offset msgdrive	; ask which drive
	call	writemsg
	mov	ah,01h			; get keyboard character with echo
	int	21h
	and	al,0dfh			; convert to upper case
	cmp	al,'X'
	jne	$+5
	jmp	alldone
	cmp	al,'A'
	jb	nextdisk
	cmp	al,'B'
	ja	nextdisk
	mov	[drive],0
	jb	gotdrive
	mov	[drive],1
gotdrive:
	mov	ah,06h			; drain keyboard buffer
	mov	dl,0ffh
	int	21h
	jnz	gotdrive

	mov	dx,offset msgcrlf
	call	writemsg

	mov	ax,word ptr [Users]
	or	ax,ax
	jz	SkipUsers
	lea	dx,SerMsg
	call	writemsg
SkipUsers:

	mov	[cylinder],0		; start at cylinder 0
	mov	[retries],3

	mov	ah,0			; reset diskette controller
	int	13h

;;	mov	ah,18h			; set media type
;;	mov	dl,[drive]
;;	mov	ch,NOTRACKS-1
;;	mov	cl,NOSECS
;;	int	13h

nextcyl label	near

	mov	ah,3fh			; read next cylinder
	mov	bx,[handle]
	mov	cx,NOSECS*2*512
	push	ds
	mov	ds,[buffaddr]
	mov	dx,1000h
	int	21h
	pop	ds
	jc	jrerror
	cmp	ax,cx
	jne	jrerror

	cmp	word ptr [Users],0
	je	NoUsers
	cmp	[Savcyl],0
	je	UserSearch
	mov	cl,[cylinder]
	cmp	cl,[SavCyl]
	jne	NoUsers
	mov	di,[SavOff]
	jmp	short SetOffset
UserSearch:
	push	ds
	mov	cx,NOSECS*2*512
	mov	ds,[buffaddr]
	cld
	mov	di,1000h
BadSearch:
	mov	si,di
SearchLoop:
	lodsb
	dec	cx
	jz	NotToday
	cmp	al,byte ptr cs:[Search]  		; is it	'['
	jne	SearchLoop
	mov	di,si
	lodsw
	cmp	ax,word ptr cs:[Search+1]		 ; is it 'MO'
	jne	BadSearch
	lodsw
	cmp	ax,word ptr cs:[Search+3]		  ; is it 'S]'
	jne	BadSearch	
	lodsw					  ; get scan offset
	mov	cx,ax
	lodsw					  ; ignore
	lodsw					  ; ignore	
	lodsw					  ; get offset
	sub	di,cx
	add	di,ax
	dec	di
	pop	ds
	mov	[SavOff],di
	mov	al,[cylinder]
	mov	[SavCyl],al
	jmp	short SetOffset
NotToday:
	pop	ds
	jmp	short NoUsers

SetOffset:
	push	es
	mov	es,[buffaddr]
	mov	ax,word ptr [Users]
	stosw
	lea	si,[SerVal]
	mov	cx,4
	rep	movsw
	pop	es

NoUsers:
	mov	ch,[cylinder]		; cylinder number
	mov	cl,1			; always indicate sector 1
	mov	dl,[drive]		; diskette drive number
	mov	es,[buffaddr]		; buffer segment address
fretry:
	mov	dh,0			; format head 0
	call	format
	jnc	head0ok
	dec	[retries]		; allow for motor startup delay
	jnz	fretry
	jmp	werror
head0ok:
	mov	ah,03h			; write NOSECS sectors on head 0
	mov	al,NOSECS
	mov	bx,1000h
	mov	dh,0
	int	13h
	jc	werror

	mov	dh,1			; format head 1
	call	format
	jc	werror

	mov	ah,03h			; write NOSECS sectors on head 1
	mov	al,NOSECS
	mov	bx,1000h+(NOSECS*512)
	mov	dh,1
	int	13h
	jc	werror

	mov	dx,offset msgdot	; write a period for each cylinder
	call	writemsg

	inc	[cylinder]
	cmp	[cylinder],NOTRACKS
	jae	$+5
	jmp	nextcyl

DoNext:
	mov	ax,4200h		; lseek to beginning of file
	mov	bx,[handle]
	xor	cx,cx
	xor	dx,dx
	int	21h
	jc	rerror

	mov	si,offset SerVal+7	; bump serial number
bsnloop:
	inc	byte ptr ds:[si]
	cmp	byte ptr ds:[si],3ah
	jne	bsnout
	mov	byte ptr ds:[si],'0'
	dec	si
	jmp	bsnloop
bsnout:
	jmp	nextdisk

werror	label	near
	mov	dx,offset msgwerr
	call	writemsg
	jmp	nextdisk

rerror	label	near
	mov	dx,offset msgrerr
	call	writemsg
	jmp	alldone

writemsg proc	near
	mov	ah,9
	int	21h
	ret
writemsg endp

readmsg	proc	near
	mov	ah,0ah
	int	21h
	ret
readmsg	endp

findnb	proc	near
	mov	al,ds:[si]
	cmp	al,20h
	je	$+3
	ret
	inc	si
	jmp	findnb
findnb	endp

format	proc	near
	xor	di,di
	mov	ax,0201h		; sector 1, 512 bytes/sector
formloop:
	mov	es:[di],ch		; store c,h,r,n for each sector
	mov	es:[di+1],dh
	mov	es:[di+2],ax
	add	di,4
	inc	al
	cmp	al,NOSECS
	jbe	formloop
	xor	bx,bx			; now format the track
	mov	ah,05h
	mov	al,NOSECS
	int	13h
	ret				; caller must check carry!
format	endp

alldone	label	near
	mov	ah,3eh
	mov	bx,[handle]
	int	21h
	int	20h

progend	label	near

mainseg	ends
	end	begin
