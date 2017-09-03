	include page.inc
	title	DIRMAP - display the tree structure of a disk

	subttl  DIRMAP Development Specification

;-----------------------------------------------------------------------;
;									;
;                    Development Specification				;
;									;
;									;
; Program Name: DIRMAP.COM               Assigned to: Martin Stitt	;
; Module Name:  DIRMAP                   Assign date: 11/20/86		;
; Entry Points: DIRMAP                   Completed:  			;
; Entry From:   MOS command processor 					;
; Entry Method: EXEC							;
; Purpose:      							;
; Refer To:     							;
; Last Update:           						;
;									;
;	display the tree structure of a disk				;
;									;
;-----------------------------------------------------------------------;
; MJS 4/24/88	Added /a option to show files with archive bit set	;
;-----------------------------------------------------------------------;
; SAH 02/21/89	MASM 5.10 Compatibility 				;
;-----------------------------------------------------------------------;
; BWR 11/27/89  Messages marked for foreign language translation.       :
;-----------------------------------------------------------------------;

	subttl	DIRMAP macros, equates, data
	page

;	Standard handles

StdIn	equ	0000
StdOut	equ	0001
StdErr	equ	0002

;	Dos calls

WritFil	equ	40h
ParsFil	equ	29h
Quit	equ	4ch
SetDta	equ	1ah
GetDrv	equ	19h
GetDir	equ	47h
ChDir	equ	3bh
GetCoun	equ	38h
FndFrst	equ	4eh
FndNext	equ	4fh

;	Misc equ's

True	equ	0ffh
False	equ	0	

CR	equ	13
LF	equ	10
EOF	equ	1ah
Tab	equ	9
Bell	equ	7
BS	equ	8
Bslash	equ	'\'
Fslash	equ	'/'
DtaAddr equ	80h


True?	MACRO	testflag
	cmp	testflag,true
	ENDM

ResFlg	MACRO	flag
	mov	BYTE PTR flag,False
	ENDM

SetFlg	MACRO	flag
	mov	BYTE PTR flag,True
	ENDM

MOS	MACRO	fn
	mov	ah,fn
	int	21h
	endm

Lje	MACRO	jmpdest
	LOCAL	ppp1
	jne	ppp1
	jmp	jmpdest
ppp1:
	ENDM

Ljne	MACRO	jmpdest
	LOCAL 	ppp1
	je	ppp1
	jmp	jmpdest
ppp1:
	ENDM

Ljz	MACRO	jmpdest
	LOCAL 	ppp1
	jnz	ppp1
	jmp	jmpdest
ppp1:
	ENDM

Ljnz	MACRO	jmpdest
	LOCAL 	ppp1
	jz	ppp1
	jmp	jmpdest
ppp1:
	ENDM

Lja	MACRO	jmpdest
	LOCAL	ppp1
	jna	ppp1
	jmp	jmpdest
ppp1:
	ENDM

Ljc	MACRO	jmpdest
	LOCAL 	ppp1
	jnc	ppp1
	jmp	jmpdest
ppp1:
	ENDM

CODESEG SEGMENT PARA

SegStart equ	$

	ASSUME CS:CODESEG,DS:CODESEG,ES:CODESEG
	ORG 100H

include dirmap.pub

Start:
	jmp	EntryPnt

;--------------------------- VARIABLES -------------------------;

VolMsg1	db	CR,LF,'  The DISK ID for drive  ',0 ;@@XLAT
VolMsg2	db	'  is  ',0 ;@@XLAT
VolMsg3	db	' is not set       ',0 ;@@XLAT

Header	db	'   Directory                                           ' ;@@XLAT
	db	'        Files    Bytes',CR,LF ;@@XLAT
	db	'  ===========                                          '
	db	'        =====  ======= ',CR,LF,0

DelimSet db	';,= ',9,0	; set of delimiters

WorkBuf	db	128 dup(?)	; general purpose buffer
Dchar	db	?		; used by the DispChar procedure
CounBuf	db	34 dup(?)	; buffer for get country table

	db	7 dup(?)	; extension for PrsFCB
PrsFCB	db	?		; FCB for the Parse procedure
FCBname db	36 dup(?)	

SaveDir	db	80 dup(?)
StkLvl	db	0
SrchStr	db	80 dup(?)
FindStr	db	80 dup (?)
Tally	dw	2 dup (?)	; for sum of file sizes
Fopt	db	?		; flag for /f option
Blanks	db	'   ',0		; indenting blanks for /f display
Aopt	db	?		; flag for /a option

;--------------------------- SUBROUTINES -------------------------;

;-----------------------------------------------------------------------;
;                             BasicDisp					;
;        display asciiz string, address in dx, handle in bx		;
;-----------------------------------------------------------------------;

BasicDisp PROC
	push	si
	push 	cx
	push	ax
	mov	si,dx
	call	FindLen
	MOS	WritFil
	pop	ax
	pop	cx
	pop	si
	ret
BasicDisp ENDP

;-----------------------------------------------------------------------;
;                             DispStr					;
;                   display asciiz string, address in dx                ;
;-----------------------------------------------------------------------;

DispStr PROC
	push	bx
	mov	bx,StdOut
	call	BasicDisp
	pop	bx
	ret
DispStr ENDP

;-----------------------------------------------------------------------;
;			DispErr						;
;		      Display a string to StdErr			;
;-----------------------------------------------------------------------;

DispErr PROC
	push	bx
	mov	bx,StdErr
	call	BasicDisp
	pop	bx
	ret
DispErr ENDP

;-----------------------------------------------------------------------;
;			DispEOL						;
;                    Send a crlf pair to the display			;
;-----------------------------------------------------------------------;
EOLmsg	db CR,LF,0

DispEOL	PROC  NEAR
	push	dx
	lea	dx,[EOLmsg]
	call	DispStr
	pop	dx
	ret

DispEOL	ENDP

;-----------------------------------------------------------------------;
;                              FindEnd                                  ;
;    supply address in DS:SI, searches for 0, DS:SI points to 0         ;
;-----------------------------------------------------------------------;

FindEnd PROC
	push	ax
Fe1:
	cld
	lodsb
	or	al,al
	jnz	Fe1
	dec	si
	pop	ax
	ret
FindEnd	ENDP

;-----------------------------------------------------------------------;
;                              FindLen                                  ;
;  supply address in DS:SI, returns length in cx (not including the 0)  ;
;-----------------------------------------------------------------------;

FindLen PROC
	push	dx
	push	si
	mov	dx,si
	call	FindEnd
	sub	si,dx
	mov	cx,si
	pop	si
	pop	dx
	ret
FindLen	ENDP

;-----------------------------------------------------------------------;
;			DispChar					;
;                    Send a char in dl to the display			;
;-----------------------------------------------------------------------;

DispChar PROC  NEAR	; emulate MOS function #2
	push	ax
	push	bx
	push	cx
	push	dx
	mov	[Dchar],dl
	lea	dx,[Dchar]
	mov	bx,StdOut
	mov	cx,1
	MOS	WritFil
	cmp	ax,1
	Ljne	Error3	; disk full
	pop	dx
	pop	cx
	pop	bx
	pop	ax
	ret
DispChar ENDP

;-----------------------------------------------------------------------;
;			       DispBlanks				;
;		Send blanks to the StdOut device.  CX is the count	;
;-----------------------------------------------------------------------;

DispBlanks PROC
	push	ax
	push	dx
	mov	dl,' '
Db1:
	call	DispChar
	loop	Db1
	pop	dx
	pop	ax
	ret
DispBlanks ENDP

;-----------------------------------------------------------------------;
;                            SetDtaAddr					;
;                Initializes the DTA address to DtaAddr			;
;-----------------------------------------------------------------------;

SetDtaAddr PROC
	push	ax
	push	dx
	mov	dx,DtaAddr
	MOS	SetDta
	pop	dx
	pop	ax
	ret
SetDtaAddr ENDP

;-----------------------------------------------------------------------;
;			Parse						;
;	ds:si is advanced as the parsing pointer.  PrsFCB is data area	;
;-----------------------------------------------------------------------;

Parse PROC
	push	cx
	push	di
	xor	ax,ax	; initialize the FCB to 0's
	lea	di,[PrsFCB]
	mov	cx,12
	cld
	rep	stosb
	lea	di,[PrsFCB]
	mov	al,0fh	; control byte
	MOS	Parsfil
	or	al,al	; set flags on al
	pop	di
	pop	cx
	ret
Parse ENDP

;-----------------------------------------------------------------------;
;                                CopyStr                                ;
;  source DS:SI, dest ES:DI.  For CX = 0 xfer until find 0 (0 xfered)   ;
;  For CX <> 0, use CX as byte count 					;
;-----------------------------------------------------------------------;

CopyStr PROC  NEAR
	push 	ax
	push	cx
	jcxz	Cs1
	cld
	rep	movsb
	jmp	Cs3
Cs1:
	cld
	lodsb
	stosb
	or	al,al
	jnz	Cs1
Cs3:
	pop	cx
	pop	ax
	ret

CopyStr ENDP

;-----------------------------------------------------------------------;
;				WriteDrv				;
;     ds:si points to data area	and al=0 means use current drive.	;
;  al<>0 means use al as drive #.  On return, si points	to 0 on	end of	;
;    drive string of form:  'd:\',0					;
;-----------------------------------------------------------------------;

WriteDrv PROC
	push	ax
	push	di
	mov	di,si
	or	al,al		; if al	= 0, read current drive
	jnz	Wd1		; else al=1 for	A, al=2	for B, etc
	MOS	GetDrv
	inc	al
Wd1:
	add	al,64
	cld
	stosb
	mov	al,':'
	stosb
	mov	al,Bslash
	stosb
	xor	al,al
	stosb
	mov	si,di
	dec	si
	pop	di
	pop	ax
	ret
WriteDrv ENDP

;-----------------------------------------------------------------------;
;			     WriteDrvPth				;
; ds:si	points to storage area,	al=0 for defualt drive,	else al=1 for A	;
; al=2 for B, etc.  The	storage	area is	left with the full drive/path	;
;-----------------------------------------------------------------------;

WriteDrvPth PROC
	push	ax
	push	dx
	push	si
	call	WriteDrv
	mov	dl,al
	MOS	GetDir
	pop	si
	pop	dx
	pop	ax
	ret
WriteDrvPth ENDP

;-----------------------------------------------------------------------;
;				TestSet					;
;	supply char in al and string in	si, e flag set if match		;
;-----------------------------------------------------------------------;

TestSet	PROC
	push	ax
	push	si
	dec	si
Ts2:
	inc	si
	cmp	BYTE PTR [si],0
	je	Ts3
	cmp	al,BYTE	PTR [si]
	je	Ts1
	jmp	Ts2
Ts3:
	xor	al,al
	cmp	al,1
Ts1:
	pop	si
	pop	ax
	ret
TestSet	ENDP

;-----------------------------------------------------------------------;
;				TestDelims				;
;	supply char in al to check for inclusion in DelimSet		;
;-----------------------------------------------------------------------;

TestDelims PROC
	push	si
	lea	si,[DelimSet]
	call	TestSet
	pop	si
	ret
TestDelims ENDP

;-----------------------------------------------------------------------;
;				PassDelims				;
;	check for delims at ds:si, on return ds:si points to 1st	;
;	char that isn't	a delim, and the char is in al			;
;-----------------------------------------------------------------------;

PassDelims PROC
Pd1:
	cld
	lodsb
	call	TestDelims
	je	Pd1
	dec	si
	ret
PassDelims ENDP

;--------------------------------------------------------------------;
;			     Bin2Dec				     ;
;	      DX/AX=source, BX=end-of-target, CX=length		     ;
;--------------------------------------------------------------------;

Bin2Dec	PROC  NEAR
	push	si
	push	di
	push	cx
	xor	di,di
	mov	si,cx
	cmp	si,4		; is it	real long?
	jle	btdloop1	; no, skip
	div	[w10000]	; yes, do it piecemeal
	mov	cx,4
	mov	di,ax
	mov	ax,dx
	xor	dx,dx
btdloop1:
	div	[w10]
	add	dl,'0'
	mov	[bx],dl
	dec	bx
	xor	dx,dx
	loop	btdloop1

	mov	ax,di
	xchg	cx,si
	sub	cx,4
	jg	btdloop1

	pop	cx
btdloop2:
	inc	bx
	dec	cx
	jz	btdret
	cmp	BYTE PTR [bx],'0'
	jne	btdret
	mov	BYTE PTR [bx],' '
	jmp	btdloop2
btdret:
	pop	di
	pop	si
	ret

;		vars for Bin2Dec

w10000	dw	10000
w10	dw	10

Bin2Dec	ENDP

;-----------------------------------------------------------------------;
;				PutGlobal				;
;	add a global file spec to the buffer addressed by di		;
;-----------------------------------------------------------------------;

PutGlobal PROC
	push	ax
	push	cx
	mov	al,Bslash
	cld
	cmp	BYTE PTR [di-1],al
	je	Tr15
	stosb
Tr15:
	mov	al,'?'
	mov	cx,8
	rep	stosb
	mov 	al,'.'
	stosb
	mov	al,'?'
	mov	cx,3
	rep	stosb
	xor	al,al
	stosb
	pop	cx
	pop	ax
	ret
PutGlobal ENDP

;-----------------------------------------------------------------------;
;				GetOption				;
;   ds:si points to string, supply char	(uppercase) in al, ah=0	means	;
;   find option, ah=1 means find any /.	 Returns zr for	find		;
;   If searching for an	option (ah=0) and find it, it will be blanked	;
;   out	in the buffer							;
;-----------------------------------------------------------------------;
GetOption PROC
	push	ax
	push	bx
	push	cx
	push	dx
	push	si
	mov	bl,al
	mov	dl,0

	mov	dh,1		; set up for NZ	flag
Gop1:
	xor	cx,cx
	mov	al,'/'
	call	ScanStr
	jne	Gop2		; no options found this	pass
	cmp	ah,1
	je	Gop3		; if ah=1 (ZR flag will	be set)	return
	inc	si
	cld
	lodsb
	call	Low2Upper
	cmp	al,bl		; is it	the supplied char?
	jne	Gop1
	mov	WORD PTR [si-2],2020h  ; blank out the option 
	xor	dx,dx		       ; set up	for ZR flag
	jmp	Gop1		       ; to simplify later parsing
Gop2:
	cmp	dl,dh		; set ZR or NZ depending on dl,dh
Gop3:
	pop	si
	pop	dx
	pop	cx
	pop	bx
	pop	ax
	ret
GetOption ENDP

;-----------------------------------------------------------------------;
;				Low2Upper				;
;		Convert	charactor in reg al to upper case		;
;-----------------------------------------------------------------------;
Low2Upper PROC

	cmp	al,'a'
	jae	Lu1
	ret
Lu1:
	cmp	al,'z'
	jbe	Lu2
	ret
Lu2:
	sub	al,32
	ret
Low2Upper ENDP

;-----------------------------------------------------------------------;
;				ScanStr					;
;	 Supply	pointer	in ds:si, char in al.  If cx = 0, will scan	;
;   until find a 0 (for	asciiz), if cx > 0, will scan that many	bytes.	;
;   on return, z flag means ds:si points to target, nz flag for	fail	;
;-----------------------------------------------------------------------;

ScanStr	PROC
	push	ax
	push	cx
	push	di
	push	es
	push	ds

	pop	es
	cld
	mov	di,si
	jcxz	Ss1		; cx = 0, scan until find a 0
	repne	scasb
	mov	si,di
Ss2:
	pushf
	dec	si
	popf
	pop	es
	pop	di
	pop	cx
	pop	ax
	ret
Ss1:
	mov	ah,al
Ss3:
	lodsb
	cmp	al,0
	je	Ss4
	cmp	al,ah
	jne	Ss3
	jmp	Ss2
Ss4:
	xor	al,al
	cmp	al,1		; set not zero flag
	jmp	Ss2
ScanStr	ENDP


InitWorkBuf PROC
	lea	di,[WorkBuf]
	mov	cx,40
	cld
	mov	ax,2020h	; init WorkBuf to blanks
	rep	stosw
	ret
InitWorkBuf ENDP


Search PROC
	mov	WORD PTR [Tally],0
	mov	WORD PTR [Tally+2],0	; init file size tally
	xor	bp,bp		; use bp as a file counter

	lea	dx,[FindStr]
	xor	cx,cx
	MOS	FndFrst
	jc	Tr6
Tr17:
	inc	bp
	mov	si,DtaAddr+26	; offset of low word of file size
	mov	ax,[si]
	add	[Tally],ax
	mov	ax,[si+2]
	adc	[Tally+2],ax	; sum up file sizes
	MOS	FndNext
	jnc	Tr17	
Tr6:
	mov	ax,bp
	xor	dx,dx
	lea	bx,[WorkBuf+67]
	mov	cx,4
	call	Bin2Dec
	mov	ax,[Tally]
	mov	dx,[Tally+2]
	lea	bx,[WorkBuf+76]
	mov	cx,8
	call	Bin2Dec
	mov	word ptr [WorkBuf+77],0a0dh
	lea	dx,[WorkBuf]
	mov	cx,79
	mov	bx,StdOut
	MOS 	WritFil
	cmp	ax,79
	Ljne	Error3
	True?	[Aopt]
	je	Tr19c
	True?	[Fopt]		; was the /f option specified ?
	jne	Tr23
Tr19c:
	call	DispEOL
	lea	dx,[FindStr]
	xor	cx,cx
	MOS	FndFrst
	jc	Tr18
Tr19:
	True?	[Aopt]
	jne	Tr19a
	test	byte ptr ds:[DtaAddr+21],20h	; check archive bit
	jz	Tr19b
Tr19a:
	lea	dx,[Blanks]
	call	DispStr
	mov	dx,DtaAddr+30	; display file names
	call	DispStr
	call	DispEOL
Tr19b:
	MOS	FndNext
	jnc	Tr19
Tr18:
	call	DispEOL
Tr23:
	ret
Search ENDP

;--------------------------- START OF CODE -------------------------;

EntryPnt:

	jmp	Vrchk1		; skip around the data
version	label	byte
	include	version.inc

vermsg	db	13,10,'Improper MOS Version.  ',13,10,'$' ;@@XLAT

Vrchk1:
	mov	ah,30h
	mov	bx,ax		; read the MOS version number
	mov	cx,ax
	mov	dx,ax
	int	21h
	cmp	ax,word ptr [version]
;	jne	Vrchk2			; MJS 12/17/87  only check major #
;	cmp	bx,word ptr [version+2]
	je	Vrchk3
Vrchk2:
	lea	dx,[vermsg]	; report mismatch
	push	cs
	pop	ds
	mov	ah,9
	int	21h
	mov	al,2		; errorlevel 2
	mov	ah,4ch		; and terminate
	int	21h
Vrchk3:

	call	SetDtaAddr
	mov	bx,80h
	mov	al,[bx]		; get the parameter line length
	or	al,al
	jne	Tr12
Tr21:
	lea	si,[SrchStr]
	call	WriteDrv	; make 'd:\',0 in SrchStr (with default drive)
	jmp	Tr13
Tr12:
	mov	si,81h
	xor	ah,ah
	add	si,ax
	mov	BYTE PTR [si],0	; convert the psp parm line into asciiz format
	ResFlg	[Fopt]
	mov	si,81h
	mov	al,'F'
	xor	ah,ah
	call	GetOption
	Ljne	Tr20
	SetFlg	[Fopt]
Tr20:
	ResFlg	[Aopt]
	mov	si,81h
	mov	al,'A'
	xor	ah,ah
	call	GetOption
	Ljne	Tr20a
	SetFlg	[Aopt]
Tr20a:
	mov	ah,1
	call	GetOption
	Lje	Error4		; invalid parameter

	call	PassDelims
	or	al,al
	jz	Tr21		; is the parm null now ?
	lea	di,[SrchStr]
	xor	cx,cx
	call	CopyStr		; copy the parameter line into SrchStr

	; MJS 12/17/87
	lea	si,[srchstr]
	call	findend
	dec	si
mPd1:
	std
	lodsb
	call	TestDelims
	je	mPd1
	mov	byte ptr [si+2],0
	cld
	; end MJS 12/17/87

	lea	si,[SrchStr]
	call	Parse
	cmp	al,0ffh
	Lje	Error2		; invalid drive	spec
	lea	si,[SaveDir]
	mov	al,BYTE PTR [PrsFCB]
	call	WriteDrvPth	; setup	SaveDir	with full path for restoration
	or	al,al
	jz	Tr16
	lea	si,[SrchStr]
	call	PassDelims
	add	si,2
	push	si
	call	PassDelims
	pop	si
	or	al,al
	jnz	Tr16
	mov	BYTE PTR [si],Bslash
	mov	BYTE PTR [si+1],0
Tr16:
	lea	dx,[SrchStr]
	MOS	ChDir		; attempt to chdir the supplied	string
	Ljc	Error1		; not a valid path

	lea	si,[SrchStr]	; if a valid path, reform the string
	mov	al,BYTE PTR [PrsFCB]
	call	WriteDrvPth	; read current directory 
	lea	dx,[SaveDir]
	MOS	ChDir		; restore previous directory
Tr13:
	mov	BYTE PTR [StkLvl],0
	mov	dl,BYTE PTR [SrchStr]
	sub	dl,64		; convert drive letter to number
	mov	cl,dl		; save dl
	lea	dx,[VolMsg1] ; display 'Volume in drive ' message
	call	DispStr
	mov	dl,cl
	add	dl,64
	call	DispChar	; display drive	letter
	mov	dl,cl
	lea	di,[PrsFCB-7]
	cld
	mov	al,0ffh		; init the FCB
	stosb
	xor	al,al
	mov	cx,5
	rep	stosb
	mov	al,8		; set attribute	for label
	stosb
	mov	al,dl		; get drive # 
	stosb
	mov	al,'?'
	mov	cx,11
	rep	stosb
	xor	al,al
	mov	cx,25
	rep	stosb
	lea	dx,[PrsFCB-7]
	mov	ah,11h		; old search for first call
	int	21h
	or	al,al
	jnz	Gv1		; no label found
	lea	dx,[VolMsg2]
	call	DispStr
	mov	dx,bx		; display the label from the DTA
	add	dx,8
	mov	bx,StdOut
	mov	cx,11
	MOS	WritFil
	cmp	ax,11
	Ljne	Error3		; disk full
	jmp	Gv2
Gv1:
	lea	dx,[VolMsg3]
	call	DispStr
Gv2:
	call	DispEOL
	call	DispEOL
	lea	dx,[Header]
	call	DispStr		; display column headings

;	display statistics for first directory

	call	InitWorkBuf	; init to blanks
	lea	si,[SrchStr]
	lea	di,[WorkBuf]
	xor	cx,cx
	call	CopyStr
	mov	BYTE PTR [di-1],' '	; MJS 12/17/87
	lea	si,[SrchStr]
	lea	di,[FindStr]
	xor	cx,cx
	call	CopyStr
	dec	di
	call	PutGlobal
	call	Search

	lea	si,[SrchStr]	; update SrchStr for next level
	call	FindEnd
	mov	di,si
	mov	al,Bslash
	cld
	cmp	BYTE PTR [di-1],al
	je	Tr1
	stosb

	; MJS 12/17/87
	xor	al,al
	stosb
	; end MJS 12/17/87


Tr1:
	lea	si,[SrchStr]
	lea	di,[FindStr]
	xor	cx,cx
	call	CopyStr
	dec	di
	call	PutGlobal
	lea	dx,[FindStr]
	mov	cx,10h
	MOS	FndFrst
	Ljc	Tr3
Tr10:
	mov	bx,DtaAddr+21	; offset of file's attribute in DTA
	test	BYTE PTR [bx],10h	; is it a subdir?
	jnz	Tr4
Tr2:
	MOS	FndNext
	Ljc	Tr3
	jmp	Tr10
Tr4:

	mov	si,DtaAddr+30	; offset of file name
	cmp	BYTE PTR [si],'.'
	Lje	Tr2
	call	InitWorkBuf	; init to blanks

	lea	si,[SrchStr]
	lea	di,[FindStr]
	xor	cx,cx
	call	CopyStr
	dec	di
	mov	si,DtaAddr+30	; put found name after path
	xor	cx,cx
	call	CopyStr
	push	di
	lea	di,[WorkBuf]
	lea	si,[FindStr]	; copy new string to WorkBuf
	call	CopyStr
	mov	BYTE PTR [di-1],' '
	pop	di
	dec	di
	call	PutGlobal	; put global on end of FindStr

	inc	BYTE PTR [StkLvl]	; save DTA to stack
	mov	si,DtaAddr
	mov	cx,22
	cld
Tr7:
	lodsw
	push	ax
	loop	Tr7
	lea	si,[SrchStr]	; update SrchStr for next level
	call	FindEnd
	mov	di,si
	mov	al,Bslash
	cld
	cmp	BYTE PTR [di-1],al
	je	Tr11
	stosb
Tr11:
	mov	si,DtaAddr+30	; offset of file name
	xor	cx,cx
	call	CopyStr
	dec 	di
	mov	al,Bslash
	stosb
	xor	al,al
	stosb
	call	Search
	jmp	Tr1
Tr3:
	cmp	BYTE PTR [StkLvl],0
	Lje	CleanExit

	dec	BYTE PTR [StkLvl]
	mov	di,DtaAddr+42
	mov	cx,22
	std
Tr8:
	pop	ax
	stosw
	loop	Tr8
	lea	si,[SrchStr]
	call	FindEnd
	sub	si,2
	std
Tr9:
	lodsb
	cmp	al,Bslash
	jne	Tr9
	mov	BYTE PTR [si+2],0
	jmp	Tr2

;--------------------------- ERROR HANDLERS -------------------------;

Ermsg1	db	'Invalid directory name    ',0 ;@@XLAT

Error1:
	lea	dx,[Ermsg1]
	jmp	ShowError

Ermsg2	db	'Invalid drive identifier ',0 ;@@XLAT

Error2:
	lea	dx,[Ermsg2]
	jmp	ShowError

Ermsg3	db	'No more space on disk         ',0 ;@@XLAT

Error3:
	lea	dx,[Ermsg3]
	jmp	ShowError

Ermsg4	db	'Invalid operand     ',0 ;@@XLAT

Error4:
	lea	dx,[Ermsg4]
	jmp	ShowError

ShowError:
	call	DispErr
DirtyExit:
	mov	al,2		; errorlevel 2
	jmp	Done
CleanExit:
	xor	al,al		; errorlevel 0
Done:
	push	ax
	call	DispEOL
	pop	ax
	MOS	Quit

EndOfProg LABEL BYTE

CODESEG ENDS
	END	START

