	page	95,132

;-------------------------------------------------------------------;
; GETSER - Retrives serial # for Duplicator in Production.	    ;
; 								    ;
; Created Aug 9, 1990 for MOS 4.10 Production by Stewart Hyde.	    ;
;								    ;
; This program is use to scan 360 disk and display the following    ;
;        Head (0-1)						    ;
;        Track (0-39) in Duplicator terms, cyliinder in Bios Terms  ;
;	 Cylinder (1-9) in Duplicator terms, Track in Bios Terms    ;
;	 Offset (0-511)						    ;
;								    ;
;-------------------------------------------------------------------;
; RSR 10-23-90  Added code to check for other mos products using    ;
;               the string SeRiAl. 				    ;	
;-------------------------------------------------------------------;	

mainseg	segment	para
	assume	cs:mainseg,ds:mainseg


	org	0100h
begin	label	near
	jmp	start

true            equ     1
false           equ     0

CR		equ	13
LF		equ	10


Choosemsg db	'Serial number finder, Version 1.1',CR,LF
	  db	CR,LF,CR,LF
	  db	'Select Product',CR,LF
	  db	CR,LF
	  db	'1) PC-MOS 4.1',CR,LF
	  db	'2) Any other (Current) TSL product',CR,LF
	  db	CR,lF
	  db	'Selection:$'
Chooseer  db	'     Please type 1 or 2',CR,LF
          db	'Selection:$'

putdisk	  db	CR,LF,CR,LF,'Put the 360K 5 1/4 disk in drive A: and hit any key.$'

putmos	  db	CR,LF,CR,LF,'Put the 360K PCMOS 5 1/4 disk in drive A: and hit any key.$'

filename  db	65 dup(0)		; name of input file
msgrerr	  db	13,10,10,'Diskette read error!',13,10,'$'
msgwerr	  db	13,10,'Error writing output file!',13,10,'$'
msgcrlf	  db	13,10,'$'
msgdot	  db	0fah,'$'
msgsearch db	13,10,13,10
	  db	'Searching for Head,Cylinder,Track and Offset'
	  db	13,10,'$'
MsgFound  db	13,10
	  db	'Serial # Found!',13,10,10
	  db	'Head:         '
VHead	  db	'x.',13,10
	  db	 'Track:       '
VCyl	  db	 '00.',13,10  
	  db	 'Cylinder:    '
VTRack	  db	 'x.',13,10
	  db	 'Offset:      '
VOff	  db	 '000.',13,10,10,'$'	

	 even
buffaddr dw	0
cylinder db	0
drive	 db	0
retries	 db	3

SavCyl	 db	0			; save cylinder for serial # inplant
SavOff	 dw	0			; save offset for serial # implant

SearchMos db	'Y'

Search	 db	'X0X0X',0		; search for this
Search1  db	'SeRiAl',0		;search for this

start	label	near
	mov	dx,offset choosemsg
	mov	ah,9
	int	21h
	jmp	getit

redo:
	mov	dx,offset chooseer
	mov	ah,9
	int	21h

getit:
	xor	ax,ax
	int	16h
	cmp	al,'1'
	je	cont

	cmp	al,'2'
	jne	redo
	mov	[SearchMOS],'N'
	mov	dx,offset putdisk
	jmp	cont1
	
cont:
	mov	dx,offset putmos
cont1:
	mov	ah,9
	int 	21h
	xor	ax,ax
	int 	16h
	mov	dx,offset msgsearch
	mov	ah,9
	int	21h

	mov	ax,ds			; compute I/O buffer address
	mov	bx,offset progend+15
	mov	cl,4
	shr	bx,cl
	add	ax,bx
	add	ax,0fffh
	and	ax,0f000h
	mov	[buffaddr],ax
	push	es
	mov	es,ax
	xor	di,di
	mov	cx,9*512
	xor	ax,ax
	rep	stosw
	pop	es

	mov	dx,offset msgcrlf
	mov	ah,9
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

	mov	ax,0209h		; read 9 sectors on head 0
	mov	bx,0
	mov	dh,0
	int	13h
	jnc	gothead0
	dec	[retries]		; allow timeout for motor startup
	jnz	nextcyl
	jmp	rerror
gothead0:
	mov	ax,0209h		; read 9 sectors on head 1
	mov	bx,9*512
	mov	dh,1
	int	13h
	jc	rerror


	mov	ah,09h			; write a period for each cylinder
	mov	dx,offset msgdot
	int	21h

	call	SearchIT
	
;	jnc	found
   
					;RSR - I took this out so it would
					;search the entire disk for the
					;string 10/23/90

	inc	[cylinder]
	cmp	[cylinder],40
	jb	nextcyl
found:
	

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

alldone	label	near
	int	20h

SearchIT proc	near
	push	ds
	mov	cx,18*512
	mov	ds,[buffaddr]
	cld
	xor	di,di
BadSearch:
	mov	si,di
SearchLoop:
	mov	bx,offset Search
	cmp	byte ptr cs:[SearchMos],'Y'
	je	SearchA
	mov	bx,offset Search1
SearchA:
	lodsb
	dec	cx
	jnz	SearchCheck
	jmp	NotToday
SearchCheck:
	cmp	al,byte ptr cs:[bx]  		
	jne	SearchLoop
	mov	di,si
	lodsw
	cmp	ax,word ptr cs:[bx+1]		 
	jne	BadSearch
	lodsw
	cmp	ax,word ptr cs:[bx+3]		 
	jne	BadSearch
	dec	di
	pop	ds
	mov	[SavOff],di
	mov	al,[cylinder]
	mov	[SavCyl],al
	clc
	mov	al,'0'
	cmp	di,9*512
	jb	SHead0
	inc	al
SHead0:
	mov	[VHead],al
	mov	al,[SavCyl]
	mov	[VCyl],'0'
SCylLoop:
	cmp	al,10
	jb	SCyl1
	inc	[VCyl]
	sub	al,10
	jmp	short SCylLoop
SCyl1:
	add	al,'0'
	mov	[VCyl+1],al
	mov	ax,[SavOff]
	and	ax,511
	mov	word ptr [Voff],'00'
	mov	byte ptr [Voff+2],'0'
SOffLoop:
	cmp	ax,100
	jb	Soff1
	inc	[VOff]
	sub	ax,100	
	jmp	short SoffLoop
Soff1:
	cmp	ax,10
	jb	Soff2
	inc	[VOff+1]
	sub	ax,10
	jmp	short Soff1
Soff2:
	add	al,'0'
	mov	[VOff+2],al
	mov	ax,[SavOff]
	cmp	[VHead],'0'
	je	STrack
	sub	ax,9*512
STRack:
	mov	al,ah
	shr	al,1
	inc	al
	add	al,'0'
	mov	[VTrack],al	

	mov	dx,offset MsgFound
	mov	ah,9
	int	21h


	ret
NotToday:
	pop	ds
	stc
	ret
SearchIT endp


progend	label	near

mainseg	ends
	end	begin

