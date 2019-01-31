	title	makeuser.asm - PC-MOS Serial # creator
;-----------------------------------------------------------------------;
;		development specification				;
;									;
; Program name: MAKEUSER.ASM	Assigned to: Stewart Hyde		;
; Module name:	MAKEUSER	Assign Date: 01/10/90			;
; Entry points: 		Completed:   01/10/90			;
; Entry from:	command processor					;
; Entry method: makeuser serial,count 					;
; Calls:								;
; Purpose:	Creates Serial # for PC-MOS 4.10 or higher		;
; Refer to:	Stewart Hyde (MOSINIT2.ASM)				;
; Last Update:	07/29/90						;
;									;
; This program is not to be distribute 					;
;-----------------------------------------------------------------------;
; SAH 03/02/90	Corrections for Serial # (6 digits)			;
;-----------------------------------------------------------------------;
; SAH 04/26/90  Corrections so that output could be used for production ;
;-----------------------------------------------------------------------;
; SAH 06/07/90  Corrections for 10 digit serial # 			;
;-----------------------------------------------------------------------;
; SAH 07/26/90   Change so that it use ACCESSKEY's from OPTIONS.INC	;
;     07/29/90   Changes for Production of 4.10 in productions, allows  ;
;		 printing of ACCESS ID sheet.			        ;
;-----------------------------------------------------------------------;

STDERR	equ	2
STDPRN	equ	4

cgroup	group	cseg
cseg	segment	public word 'CODE'

	include options.inc

	assume	cs:cgroup,ds:cgroup,es:nothing,ss:nothing

	org	100h
start:
	jmp	begin

msg	db	13,10
	db	'PC-MOS Serial # Creator Version 1.00 (900729) - '
	db	'For Internal Use Only',13,10
	db	'Copyright 1990 The Software Link, Incorporated',13,10,10
	db	'This program is to be used internally by the ',13,10
	db	'The Software Link and is not to be distributed!',13,10,10
msglen	equ	($-msg)

msgndoc	db	'MAKEUSER.DOC not found in current directory or path!',13,10,'$'
msgbdoc	db	'MAKEUSER.DOC is not valid!',13,10,'$'
msgbad	db	'Invalid Serial # given!',13,10,'$'
msgnbad db	'Invalid Count Given!',13,10,'$'
msgsyn	db	'Invalid Syntax:',13,10
	db	'MAKEUSER 0123456789 [,] [count]  [/I]',13,10
	db	'	   /I is use to inquire on access id.',13,10,10,'$'

NamePath db	'MAKEUSER.DOC',0

DataPath db	'MAKEUSER.DOC',0
	 db	60 dup (0)

SlashI	db	'N'			; default is off	
serial	db	'1199999998,$'
hidden	db	'0123',13,10,'$'
count	dw	50			; defaults to 50
ten	dw	10			; constant

SerOffset dw	0			; offset to serial # replacement
ACOffset  dw	0			; offset to AC replacement

CrLf	 db	13,10
PageFeed db	12

Special db	'40444854750000000'

hvalues db	4 dup (0)

;
; The following is code algorithm use to generated hidden serial #, Identical
; routine is place into PC-MOS kernel for use in comparing serial #'s at
; init and making sure that user has valid serial #
;
; Please note that 4th position will always be generated as a number.  This
; is done for legal reasons, so that there is no way a word could be 
; generated which might offend someone.
;

MakeHidden proc	near
	push	ax
	push	bx
	push	cx
	push	bp

;
;	init values to so some random but fix numbers
;  	routine keep attract of 4 internal counters for making
;       hidden serial #'s
;

	mov	word ptr [hvalues],ACCESSKEY1
	mov	word ptr [hvalues+2],ACCESSKEY2

;
;	add to values, values of 10 serial characters, looping back to 
;	begin for final 4 characters
;

	mov	bp,si		; save start offset for second round
	mov	cx,10
	xor	bx,bx
MHLoop:
	lodsb
	add	byte ptr [hvalues+bx],al
	inc	bx
	cmp	bx,4
	jb	MHskip
	xor	bx,bx
MHSkip:
	loop	MHLoop

	mov	cx,16
	xor	bx,bx
	lea	si,Special
MSpec:
	lodsb
	add	al,cl
	add 	byte ptr [hvalues+bx],al
	inc	bx
	cmp	bx,3	
	jb	MSpecNext
	xor	bx,bx
MSpecNext:
	loop	MSpec				

;
;       revisited the 10 characters with the following formala. 
; 	count = corrent buffer position value (always rotating) mod 32
;       for count times, add (value+37) to value in circular buffer
;	 	each time rotating buffer pointer by 1

	mov	si,bp
	mov	cx,10
	xor	bx,bx
MHLoop1:
	lodsb
	push	cx
	push	bx
	inc	bx
	cmp	bx,4
	jb	MHLoop1a
	xor	bx,bx
MHLoop1a:
	mov	cl,byte ptr [hvalues+bx]
	pop	bx
	and	cx,7
MHLoop2:
	add	byte ptr [hvalues+bx],al
	add	al,ACCESSKEY3			; add a random number
	inc	bx
	cmp	bx,4
	jb	MHskip2
	xor	bx,bx
MHSkip2:
	loop	MHLoop2
	pop	cx
	loop	MHLoop1

;
; for each of 4 internal values calculate hidden serial # in ascii 
; format.
;
; if this is 4th position
; 	ascii value if (store value) mod 10 + '0'
; else
;	x = (store value) mod 36
;	if x < 26 then
;		ascii value = (x + 'A')
;	else
;		ascii value = ((x - 26) + '0')
;

	mov	cx,4
	lea	si,hvalues
MCLoop:
	lodsb
	cmp	cx,3   		; protect against nasty words for legal
	jne	MCLoop2		; reasons
MCLp:
	cmp	al,10		; always make 4th digit a number
	jb	MCLow
	sub	al,10
	jmp	MCLp
MCLoop2:
	cmp	al,36
	jb	MCSkip
	sub	al,36
	jmp	short MCLoop2
MCSkip:
	cmp	al,26
	jae	MCHigh
	add	al,'A'
	jmp	short MCSet
MCHigh:
	sub	al,26
MCLow:
	add	al,'0'
MCSet:
	stosb
	loop	MCLoop

	pop	bp
	pop	cx
	pop	bx
	pop	ax
	ret

MakeHidden endp

LoadText  proc	near
;
;
;	  Next we will initialized FileTab to table of all spaces
;	  this is so when we reformat file image it would all be
;	  space out
;
	  push	cs
	  pop	es
	  mov	di,offset FileTab
	  mov	cx,80*60/2
	  mov	ax,2020h		; all spaces
	  rep	stosw
;
;	  we must also file space folling FileTab with
;	  0's so that load can be corrected terminated
;		
	  xor	ax,ax
	  mov	cx,80*60/2
	  rep	stosw
;

;
;	 generate filename by getting path from PSP (Same as ARG[0] in
;	 C) (Code came from MJS's HOMEPATH)
;	 
	push	ds
	push	es
	mov	es,cs:[2ch]	; get segment of envorinment
	xor	di,di
	xor	al,al
gp1:
	mov	cx,0ffffh
	repne	scasb			; find the end of each environment 
	cmp	byte ptr es:[di],0	; string and until find the end of
	jne	gp1			; the last one
	add	di,3
	mov	bx,di		; save starting of the homepath string
	mov	cx,0ffffh
	repne	scasb		; and then find its end
	std
	mov	al,'\'
	mov	cx,0ffffh
	repne	scasb		; scan back to find the last backslash
	add	di,2		; and compensate di
	sub	di,bx
	mov	cx,di		; calculate length of desired portion
	mov	si,bx		; make ds:si point to the environment string
	mov	ax,es
	mov	ds,ax
	mov	ax,cs
	mov	es,ax
	mov	di,offset DataPath
	cld
	rep	movsb		; copy the environment string to the caller's
cloop:
	cmp	byte ptr es:[di],'\'
	je	cexit
	dec	di
	jmp	short cloop
cexit:
	inc	di
	push	cs
	pop	ds
	mov	si,offset NamePath
	mov	cx,13
	rep	movsb
	pop	es
	pop	ds	

;
;	 Now load doc file into memory
;
	 mov	dx,offset DataPath
	 mov	ax,3d00h
	 int	21h	
	 mov	dx,offset msgndoc
	 jnc	OkLoad
	 jmp	LTError
OkLoad:
	 mov	bx,ax
	 mov	dx,offset FileTab+80*60
	 mov	ah,3fh
	 mov	cx,80*60
	 int	21h  
	 mov	ah,3eh
	 int	21h		
	 
	 xor	cx,cx		; set line counter to 0
	 xor	bx,bx		; set line position to 0
	 mov	si,offset FileTab+80*60
	 mov	di,offset FileTab
TranLoop:
	 lodsb
	 or	al,al
	 jz	TranExit
	 cmp	al,0dh
	 jne	NotRet
	 add	di,80
	 inc	cx
	 cmp	cx,60
	 jae	TranExit
	 jmp	short TranLoop
NotRet:
	 cmp	al,0ah
	 jne	NotLF
	 xor	bx,bx
	 jmp	short TranLoop
NotLF:
	  cmp	al,09h
	  jne	NotTab
	  and	bx,0f8h
	  add	bx,8
	  jmp	short TranLoop
NotTab:
	  cmp	al,26
	  je	TRanExit
	  cmp	bx,80
	  jae	TranLoop
	  mov	byte ptr cs:[di+bx],al
	  inc	bx
	  jmp	short TranLoop
TranExit:
	  mov	dx,offset msgbdoc
	  mov	si,offset FileTab
	  xor	cx,cx
CKLoop:
	  lodsb
	  inc	cx
	  cmp	al,'['
	  jne	NotAK
	  cmp	word ptr ds:[si],'NS'
	  jne	NotSN
	  mov	ax,si
	  dec	ax
	  mov	[SerOffset],ax

NotSN:
	  cmp	word ptr ds:[si],'KA'
	  jne	NotAK
	  mov	ax,si
	  dec	ax
	  mov	[ACOffset],ax
	   				  
NotAK:
	  cmp	SerOffset,0
	  je	CheckIt		  	   
	  cmp	ACOffset,0
	  jne	CheckDone
CheckIt:
	  cmp	cx,80*60
	  jae	LTError
	  jmp	CKLoop
CheckDone: 
	  clc
	  ret
;
;	  if error return carry set, dx has message
;		
LTError:
	  stc
	  ret
LoadText  endp


PrintIT	   proc	near
	   push	ax
	   push	bx
	   push cx
	   push  dx
   	   push  si
	   push  di
	     			
	   push	es

	   push	cs
	   pop	es
;
;	   First we must transfer serial offset into 
;	   message	
;

	   mov	si,offset Serial
	   mov  di,SerOffset
	   movsw
	   mov	al,'-'
	   stosb
	   mov	cx,4
	   rep	movsw
	   mov	si,offset Hidden
	   mov	di,ACOffset
	   movsw
	   movsw
;
;	   Now print it	
;

	   mov	cx,60
	   mov	dx,offset FileTab
	   mov	bx,STDPRN
PrintLP:
	   push	cx
	   push	dx
	   mov	ah,40h
	   mov	cx,80
	   int	21h
	   mov	dx,offset CrLF
	   mov	cx,2 
	   mov	ah,40h
	   int	21h
	   pop	dx
	   pop	cx
	   add	dx,80
	   loop	PrintLP				

	   mov	dx,offset PageFeed
	   mov	ah,40h
	   mov	cx,1
           int	21h 

	   pop	es		   
	   pop	di
	   pop	si
	   pop	dx
	   pop	cx
	   pop	bx	 
	   pop	ax
			
	   ret	
PrintIT	   endp

;
; The following procedure is use to get parameters from user and place the
; serial # and optional the # of serial #'s to generate 
;
; serial # must be in the following format
;	XX-YYYYYY where
;	  X is a digit  (0 - 9)
;         Y is a apha or digit (A - Z or 1 - 9)

getparms proc	near
;
;	First thing we will do is scan for a '/I'   to indicate
;	inquirey mode	


	mov	si,81h
	cld
SSlashLP:
	lodsb
	cmp	al,13
	je	SSlashSkip
	cmp	al,'/'
	jne	SSlashLP
	lodsb
	cmp	al,'i'
	je	SSLashI
	cmp	al,'I'
	jne	SSLashLP
SSLashI:
         mov	[SLashI],'Y'	
	 mov	word ptr [si-2],2020h
SSLashSkip:
	 mov	si,81h


	lea	di,serial
gplp:
	lodsb
	cmp	al,' '
	je	gplp
	dec	si
	mov	cx,10
serloop:
	lodsb
	cmp	al,'0'
	jb	ser1
	cmp	al,'9'
	jbe	setser
ser1:
	and	al,0dfh
	cmp	al,'A'
	jb	badserial
	cmp	al,'Z'
	ja	badserial
setser:
	stosb
	loop	serloop
     	lodsb
	cmp	al,13		; using default
	je	gpend
      	cmp	al,' '
	je	gpnumber
	cmp	al,','
	jne     badserial
gpnumber:
	lodsb
	cmp	al,' '
	je	gpnumber
	cmp	al,','
	je	gpnumber
	cmp	al,13
	je	badnum
	xor	dx,dx
numloop:
	xor	ah,ah
	cmp	al,'0'
	jb	badnum
	cmp	al,'9'
	ja	badnum
	sub	al,'0'
	add	dx,ax
	lodsb
	cmp	al,13
	je	oknum
	cmp	al,' '
	je	oknum
	push	ax
	mov	ax,dx
	mul	[ten]
	mov	dx,ax
	pop	ax
	jmp	short numloop
badserial:
	mov	dx,offset msgbad
	stc
	ret	
badnum:
	mov	dx,offset msgnbad
	stc
	ret
oknum:
	mov	[count],dx
gpend:	
	clc
	ret
getparms endp

;
; Start of main code
;

begin:
	mov	ax,cs
	mov	ds,ax
	mov	es,ax
	lea	dx,msg
	mov	bx,STDERR
	mov	ah,40h
	mov	cx,msglen
	int	21h
	call	GetParms	; get parameters from command line
	jc	badparms
	cmp	[SlashI],'Y'
	je	mnoload
	call	LoadText	; load in text to send to printer, format it	
	jc	badparms
mnoload:
	mov	cx,[count]
mloop:
	push	cx
	lea	si,serial
	lea	di,hidden
	call	MakeHidden
	lea	dx,serial
	mov	ah,9
	int	21h
	lea	dx,hidden
	mov	ah,9
	int	21h
	cmp	[SlashI],'Y'
	je	SkipPrn
	call	PrintIT
SkipPrn:
	mov	si,offset serial+9
sloop:
	mov	al,byte ptr ds:[si]
	cmp	al,'-'
	je	send
	mov	ah,al
	inc	al
	cmp	ah,'9'
	jne	sskip
	mov	al,'0'
sskip:
	mov	byte ptr ds:[si],al
	cmp	al,'0'
	jne	send
	dec	si
	jmp	short sloop
send:
	pop	cx
	loop	mloop
	mov	ax,4c00h
	int	21h
badparms:
	mov	ah,9
	int	21h
	mov	ax,4c01h
	int	21h

;
;	The following is a storage location for FileTab, with is a table
;   	of 60 line of 80 characters each, This data will is not use if
;	/I is include in command line for Inquirely
;
FileTab	label	near

cseg	ends
	end	start
