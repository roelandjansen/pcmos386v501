	include	page.inc
	title	SEARCH	- search for specified target in file(s)

	subttl	SEARCH	Development Specification

;-----------------------------------------------------------------------;
;									;
;		     Development Specification				;
;									;
;									;
; Program Name:	SEARCH.COM		  Assigned to: Martin Stitt	;
; Module Name:	SEARCH			  Assign date: 07/29/86		;
; Entry	Points:	SEARCH			  Completed:  8/8/86		;
; Entry	From:	MOS command processor					;
; Entry	Method:								;
; Purpose:								;
; Refer	To:								;
; Last Update:								;
;									;
; fill in description here !!!!!!!					;
;-----------------------------------------------------------------------;
; JSM	05/19/87	Added /i switch for case insensitivity		;
;-----------------------------------------------------------------------;
; JRB   11/30/88        Added error exit code if search string not      ;
;                       found for any file                              ;
;-----------------------------------------------------------------------;
; BWR	11/30/89	Marked messages for foreign language		;
;			translation.					;
;-----------------------------------------------------------------------;
	subttl	SEARCH	macros,	equates, data
	page

;mos function calls
prnchr	equ	2
prnstr	equ	9
openfil	equ	3dh
readfil	equ	3fh
writfil	equ	40h
closfil	equ	3eh
quit	equ	4ch

stdin	equ	0000
stdout	equ	0001
stderr	equ	0002

true	equ	0ffh
false	equ	0

cr	equ	13
lf	equ	10

True?	MACRO	testflag
	cmp	testflag,true
	ENDM

MOS	MACRO	fn
	mov	ah,fn
	int	21h
	endm

PushRegSet	MACRO
	push ax
	push bx
	push cx
	push dx
	push di
	push si
	push bp
	push ds
	push es
	ENDM

PopRegSet	MACRO
	pop es
	pop ds
	pop bp
	pop si
	pop di
	pop dx
	pop cx
	pop bx
	pop ax
	ENDM

Dchar	MACRO	char		; display the charactor	'char'
	mov	dl,char		; The char parameter may also be a registor
	MOS	prnchr		; or memory reference.
	ENDM

ToUpper	MACRO	char		; convert char to upper
	LOCAL	notlower
	cmp	char,'a'
	jb	notlower
	cmp	char,'z'
	ja	notlower
	sub	char,'a' - 'A'	;; character is really lower case, convert
notlower:
	ENDM

Ljcxz	MACRO	jmpdest		; Long jumps
	LOCAL	lp1,lp2
	jcxz	lp1
	jmp	lp2
lp1:	jmp	jmpdest
lp2:
	ENDM

Lje	MACRO	jmpdest
	LOCAL	lp1,lp2
	je	lp1
	jmp	lp2
lp1:	jmp	jmpdest
lp2:
	ENDM

Ljne	MACRO	jmpdest
	LOCAL	lp1,lp2
	jne	lp1
	jmp	lp2
lp1:	jmp	jmpdest
lp2:
	ENDM

Ljc	MACRO	jmpdest
	LOCAL	lp1,lp2
	jc	lp1
	jmp	lp2
lp1:	jmp	jmpdest
lp2:
	ENDM

Ljg	MACRO	jmpdest
	LOCAL	lp1,lp2
	jg	lp1
	jmp	lp2
lp1:	jmp	jmpdest
lp2:
	ENDM

	subttl	main code for SEARCH
	page

	include search.pub

codeseg	SEGMENT

	ORG	0100h
	ASSUME	CS:CODESEG,ES:CODESEG,DS:CODESEG

start:
	jmp	EntryPnt

;		vars for BinToDec

w10000	dw	10000
w10	dw	10

;		vars for main routine

ermsg1	db	"Invalid number of operands        ",cr,lf,"$" ;@@XLAT
ermsg2	db	'Invalid command form         ',cr,lf,"$" ;@@XLAT
ermsg4	db	"Invalid operand $           " ;@@XLAT
ermsg5	db	"Cannot find file    $               " ;@@XLAT
ermsg6	db	"Access not allowed  $          " ;@@XLAT
ermsg7	db	"Handle not valid    ",cr,lf,"$" ;@@XLAT
ermsg8	db	"Access Code not valid            ",cr,lf,"$" ;@@XLAT
ermsg9	db	'Not enough memory available    ',cr,lf ;@@XLAT
erm9ln	db	$ - ermsg9
taglin	db	cr,lf,"---------- $"

nopt	db	0		; /n option flag
copt	db	0		; /c option flag
vopt	db	0		; /v option flag
iopt	db	0		; /i option flag
targlen	db	?		; length of search target
targbuf	db	125 dup(?)	; buffer to store search target
fnambuf	db	126 dup(?)	; buffer to store file names
				; allow	extra byte for 0  (ASCIIZ format)
rbufadr	dw	?		; pointer to main 4k buffer
fnamlen	db	?		; length of entire contents of file name buffer
fnampnt	dw	?		; pointer for file name	buffer
oldfnpt	dw	?		; temporary storage for	file name buffer pointe
fhandle	dw	?		; storage for file handle number
mtchcnt	dd	?		; counter for number of	target matches
linecnt	dd	?		; counter for number of	lines passed
mastlim	dw	?		; master limit counter for scanning readbuf
linstrt	dw	?		; holds	readbuf's pointer (bx) when the start
				; of a line is found.
lsoml	dw	?		; holds	the value of mastlim when the start of
				; a line is found.
mtchflg	db	?		; flag to record when a	match has been found
shftflg	db	?		; flag to indicate when	a shift	has been done
				; from the latter part of readbuf into shtfbuf
sbc	dw	?		; count	of bytes to be moved to	shftbuf
lastbuf	db	?		; flag to indicate when	the contents of	readbuf
				; are the last of the file.
dresult	db	8 dup(?)	; buffer to hold the result created by the 
	db	"$"		; BinToDec procedure.
tchar	db	?		; holds	char for DispChr routine
usestd	db	?		; flag to indicate the standard	input should be
				; used becuase no file name was	given
exit_code db    0               ; set to 1 if string not found for any file
is_match  db    false           ; set true for each file if a match occurred
                                ;     in that file

;-----------------------------------------------------------------------;
;		     Send a crlf pair to the display			;
;									;
;-----------------------------------------------------------------------;

DispEOL	PROC  NEAR
	push	dx
	mov	dl,cr
	MOS	prnchr
	mov	dl,lf
	MOS	prnchr
	pop	dx
	ret
DispEOL	ENDP

;--------------------------------------------------------------------;
;		      Binary-to-decimal	routine			     ;
;	      DX/AX=source, BX=end-of-target, CX=length		     ;
;--------------------------------------------------------------------;

BinToDec PROC  NEAR
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
BinToDec ENDP

;-----------------------------------------------------------------------;
;		   Convert binary to decimal and display.		;
;			 supply	number in DX:AX				;
;-----------------------------------------------------------------------;

DispNum	PROC  NEAR
	lea	bx,[dresult + 7h]
	mov	cx,8
	call	bintodec	; convert
	lea	bx,[dresult]
	mov	cx,9
Dn1:
	mov	al,[bx]		; strip	off leading blanks
	inc	bx


	dec	cx
	cmp	al,' '
	je	Dn1
	dec	bx
	mov	dx,bx
	call	DispStr		; display
	ret
DispNum	ENDP

;-----------------------------------------------------------------------;
;		   Display a string (without a $ on the	end)		;
;	   start of string address in ds:dx, byte length in cx		;
;-----------------------------------------------------------------------;

DispStr	PROC  NEAR
	push	bx
	mov	bx,stdout
	MOS	writfil
	pop	bx
	ret
DispStr	ENDP

	subttl	procedure to open a file and search for	target
	page

;-----------------------------------------------------------------------;
;		    Open a file	and search for target			;
;			 procedure: OpenSearch				;
;-----------------------------------------------------------------------;

;
;   Local subprocedures	for OpenSearch
;

IncLC  PROC  NEAR		; increment the	line counter
	add	WORD PTR [linecnt],1
	adc	WORD PTR [linecnt + 2],0
	ret
IncLC  ENDP

IncMC  PROC  NEAR		; increment the	match counter
	add	WORD PTR [mtchcnt],1
	adc	WORD PTR [mtchcnt + 2],0
	ret
IncMC  ENDP

DispFn PROC  NEAR		; display a file name
	PushRegSet
	mov	bx,[oldfnpt]	; recover starting location of file name
	xor	cx,cx
Df1:
	cmp	BYTE PTR [bx],0	; count	bytes until end	of name
	je	Df2
	inc	cx
	inc	bx
	jmp	Df1
Df2:
	mov	dx,[oldfnpt]	; display 
	call	DispStr
	PopRegSet
	ret
DispFn ENDP

CheckVopt PROC	NEAR		; check	for /v option


	True?	[mtchflg]
	je	Cv1
	True?	[vopt]
	jne	Cv2
	call	DispMatch
Cv2:
	ret
Cv1:
	mov	[mtchflg],false
	ret
CheckVopt  ENDP

DispMatch PROC	NEAR		; display a line in which a match was found.
	xor	al,al		; the last byte	found will be returned in
	cmp	[lsoml],0	; register al (used to check for an lf)
	je	Dm5
	True?	[copt]		; test for /c and /n options
	Lje	Dm1
	True?	[nopt]
	jne	Dm2
	Dchar	'['		; display the line number
	mov	ax,WORD	PTR [linecnt]
	mov	dx,WORD	PTR [linecnt + 2]
	call	DispNum
	Dchar	']'
Dm2:
	mov	ax,[lsoml]	; recover master limit and buffer pointer
	mov	[mastlim],ax	; values at start of line
	mov	bx,[linstrt]
Dm3:
	mov	al,[bx]
	cmp	al,lf		; line feed? (EOL marker)
	je	Dm4
	cmp	al,1ah		; EOF marker?
	je	Dm4
	True?	[copt]		; skip display if counting (/c option)
	je	Dm6
	Dchar	al
Dm6:
	inc	bx		; update pointer and counter
	dec	[mastlim]
	jnz	Dm3
	inc	[mastlim]
	True?	[copt]
	je	Dm5		; skip display if counting (/c option)
	call	DispEOL
	ret
Dm1:
	Call	IncMC
	jmp	Dm2

Dm4:
	True?	[copt]
	je	Dm5
	Call DispEOL
Dm5:
	ret
DispMatch  ENDP

;
;	End of local subroutines
;	Start of OpenSearch procedure
;

OpenSearch  PROC  NEAR
	PushRegSet


	mov	[shftflg],false
        mov     [is_match],false
	xor	ax,ax
	mov	WORD PTR [mtchcnt],ax	      ;	init match counter to 0
	mov	WORD PTR [mtchcnt + 2],ax
	mov	WORD PTR [linecnt + 2],ax     ;	init line counter to 1
	inc	ax
	mov	WORD PTR [linecnt],ax
	True?	[usestd]	; skip file open if using std input
	je	Gd4
	mov	al,0a0h		; access code for read,	deny write
	MOS	openfil		; open file and	record handle
	Ljc	ErrorHandler
	mov	[fhandle],ax
	True?	[copt]
	je	GetData
	lea	dx,taglin	; display line of -'s and file name
	MOS	prnstr
	call	DispFn
	call	DispEOL

GetData:
	mov	bx,[fhandle]
	jmp	Gd5
Gd4:
	mov	bx,stdin	; handle for std input
Gd5:
	mov	dx,rbufadr
	mov	cx,4096
	MOS	readfil		; read a 4k buffer full
	Ljc	ErrorHandler
	cmp	ax,0		; when 0 bytes are read, done with this	file
	Lje	EndOfFile
	cmp	ax,4096		; test for last	buffer of file
	jne	$+5
	jmp	Gd2
	mov	[lastbuf],true

Gd3:
	mov	[mtchflg],false
	mov	bx,rbufadr	; init bx as pointer to	readbuf
	True?	[shftflg]
	Ljne	Gd1		; test to see if a shift was done.
	sub	bx,[sbc]	; if yes, then modify buffer pointer
	add	ax,[sbc]	; and master limit by the shift	count
	mov	[shftflg],false

Gd1:
	mov	[mastlim],ax	; Save returned	byte count as master limit
	mov	[lsoml],ax	; and record limit value at start line.
	mov	[linstrt],bx	; Record offset	at start of current line.

TestByte:
	mov	al,[bx]		; read a byte from the buffer

Tb1:
	cmp	al,1ah		; EOF marker?
	Lje	EndOfFile
	cmp	al,lf		; EOL marker?
	Lje	NewLine
	True?	[iopt]
	jne	Tb2		; if exact match
	ToUpper	al
Tb2:
	cmp	al,BYTE	PTR [targbuf]  ; first char of target?
	Lje	MatchTest

UpdatePtrs:
	inc	bx		; advance pointer for read buffer
	dec	[mastlim]	; dec master limit
	jnz	TestByte
	call	CheckVopt	; if truncating	a line because the end of the


	True?	[usestd]
	Lje	GetData		; don't IncLC if acting as a filter
	call	IncLC		; buffer was reached, check for	/v option 
	jmp	GetData		; processing and increment the line counter

Gd2:
	mov	[lastbuf],false
	push	bx
	mov	bx,[rbufadr]
	add	bx,4095
	cmp	BYTE PTR [bx],1ah    ; check for an EOF	mark at	the 
	pop	bx
	Ljne	Gd3			; end of a full	buffer
	mov	[lastbuf],true
	jmp	Gd3

NewLine:
	call	CheckVopt	; process /v option
	call	IncLC		; advance line counter
	True?	[lastbuf]
	je	Nl1		; if this is the last buffer, don't even
	cmp	[mastlim],1	; check	for a buffer shifting situation
	Lje	GetData
	cmp	[mastlim],256	; the EOL marker found is too near the end of
	jl	Copy2ShftBuf	; the buffer, shift remaining contents into
				; shftbuf and read in the next 4k block
Nl1:
	inc	bx		; record the starting point of the next	line
	mov	[linstrt],bx	; linstrt = buffer pointer + 1
	dec	bx
	mov	ax,[mastlim]	; record the limit counter at new line 
	dec	ax		; lsoml	= ml - 1
	mov	[lsoml],ax
	jmp	UpdatePtrs

Copy2ShftBuf:
	mov	ax,[mastlim]	; shift	the latter part	of readbuf around
	dec	ax		; to shftbuf.
	mov	[sbc],ax	; sbc =	ml - 1
	inc	bx
	mov	si,bx		; reg si = readbuf pointer
	mov	di,[rbufadr]
	sub	di,ax		; reg di = readbuf - sbc
	mov	dx,ds
	mov	es,dx
	cld
	mov	cx,ax		; move sbc bytes
	rep movsb
	mov	[shftflg],true
	jmp	GetData		; get a	new 4k buffer full

EndOfFile:
	True?	[copt]
	jne	Ef1		; if the /c option was used
	True?	[usestd]
	je	Ef2
	lea	dx,taglin	; display line of -'s and file name
	MOS	prnstr		; followed by count of matches
	call	DispFn
	Dchar	':'
	Dchar	' '
Ef2:
	mov	ax,WORD	PTR [mtchcnt]
	mov	dx,WORD	PTR [mtchcnt + 2]
	call	DispNum

Ef1:
	True?	[usestd]
	je	CleanOut
	mov	bx,[fhandle]	; close	file
	MOS	closfil
	Ljc	ErrorHandler
CleanOut:
        cmp     [is_match],true
        je      GetOut          ; and carry is clear
        mov     [exit_code],2   ; flag not found
        clc
GetOut:
	PopRegSet		; end of search	for this file
	ret

MatchTest:
	mov	al,[targlen]	; test for full	match of target	in readbuf
	xor	ah,ah
	cmp	ax,[mastlim]	; if target length is greater than preset
	Ljg	UpdatePtrs	; value	of master limit, can't have a match.
	cmp	al,1		; if target is only one	char, already have
	je	FoundMatch	; a match.
	lea	si,targbuf
	mov	dx,ax
	dec	dx
	True?	[iopt]
	je	Mt2		; if inexact match

Mt1:
	inc	bx		; test for full	match
	inc	si
	dec	[mastlim]
	mov	al,[bx]
	cmp	al,BYTE	PTR [si]
	Ljne	Tb1
	dec	dx
	jnz	Mt1
	jmp	FoundMatch

Mt2:
	inc	bx		; test for full	match
	inc	si
	dec	[mastlim]
	mov	al,[bx]		; convert file chars to upper case
	cmp	al,'a'
	jb	Mt3		; if not lower case
	cmp	al,'z'
	ja	Mt3		; if not lower case
	sub	al,'a' - 'A'	; convert lower to upper case
Mt3:
	cmp	al,BYTE	PTR [si]
	Ljne	Tb1
	dec	dx
	jnz	Mt2

FoundMatch:
        mov     [is_match],true ; (cause mtchflg appears to be cleared each
                                ;  buffer read)
	mov	[mtchflg],true
	True?	[vopt]		; if /v	option was used, skip display call
	Lje	UpdatePtrs
	call	DispMatch	; display the matching line
	cmp	al,lf
	Lje	NewLine
	cmp	al,1ah
	Lje	EndOfFile
	jmp	UpdatePtrs

ErrorHandler:
	cmp	ax,5
	je	Erh1
	cmp	ax,6
	je	Erh2
	cmp	ax,12
	je	Erh3
	lea	dx,ermsg5	; assume error code 2, file not	found
	MOS	prnstr
Erh4:
	call	DispFn
	call	DispEOL
	stc
	jmp	Getout

Erh1:
	lea	dx,ermsg6	; access denied
	MOS	prnstr
	jmp	Erh4		; display name 

Erh2:
	lea	dx,ermsg7	; invalid handle
	MOS	prnstr
	stc
	jmp	GetOut

Erh3:
	lea	dx,ermsg8	; invalid access code
	MOS	prnstr
	stc
	jmp	GetOut

OpenSearch  ENDP

	subttl	main procedure,	extract, analyze and process parameters
	page

;--------------------------------------------------------------------;
;			   Main	procedure			     ;
;			for MOS	SEARCH command			     ;
;--------------------------------------------------------------------;

EntryPnt:

	jmp	Vrchk1		; skip around the data
version	label	byte
	include	version.inc

vermsg	db	13,10,'Improper MOS Version.',13,10,'$' ;@@XLAT

Vrchk1:
	mov	ah,30h
	mov	bx,ax		; read the MOS version number
	mov	cx,ax
	mov	dx,ax
	int	21h
	cmp	ax,word ptr [version]
	jne	Vrchk2
	cmp	bx,word ptr [version+2]
	je	Vrchk3
	jmp	short vrchk3	; no version check
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

;
; develop a paragraph count of available memory	from the end of	this program
; to the end of	total free memory.  Report and exit if not enough room for
; this program's buffer needs
;
	lea	bx,EndOfProg 
	test	bx,0fh
	pushf
	mov	cl,4
	shr	bx,cl		; calc paragraphs for offset
	popf
	jz	SkipInc
	inc	bx

SkipInc:
	mov	ax,cs
	add	bx,ax		; add to paragraphs in segment
	int	12h		; read number of Kbytes	total memory
	mov	cl,6
	shl	ax,cl		; convert to paragraphs
	sub	ax,bx		; and find free	paragraphs
	cmp	ax,273		; need 273 paragraphs for 4k buffer
	jae	EnoughMem
	lea	dx,ermsg9	; not enough memory 
	mov	bx,stderr	; report and quit
	mov	cl,erm9ln
	xor	ch,ch
	MOS	writfil
	mov	al,2		; errorlevel 2
	MOS	quit

EnoughMem:
	lea	ax,EndOfProg	; initialize start of buffer pointer 
	add	ax,292		; to 292 bytes past the	end of the program
	mov	[rbufadr],ax	; to allow room	for the	shift buffer
	mov	bx,80h
	mov	cl,[bx]		; get parameter	line length in cx
	xor	ch,ch
	Ljcxz	ReportER1
	inc	bx

FindNonBlank:
	mov	al,[bx]		; read a char from parameter line
	cmp	al,' '
	jne	FoundNB
	inc	bx
	loop	FindNonBlank


	jmp	ReportER1	; found	end of line before a non blank

FoundNB:
	cmp	al,34		; test for "   (start of target)
	je	TargetStart
	cmp	al,47		; test for a /	(start of option)
	je	ScanOptions
	jmp	ReportER2	; syntax error,	first char not " or /

TargetStart:
	True?	[copt]		; if /c	is used, ignore	/n
	jne	F1
	mov	al,false
	mov	[nopt],al
F1:
	dec	cx
	Ljcxz	ReportER2
	inc	bx
	lea	di,targbuf	; set up pointer to target buffer
	xor	dx,dx		; init target length counter

ScanTarget:
	mov	al,[bx]		; read char from parameter line
	cmp	al,34		; test for "  (end of target)
	je	TargetEnd
	mov	[di],al		; put char in target buffer
	inc	di
	inc	dx
	inc	bx
	loop	ScanTarget
	jmp	ReportER2

TargetEnd:
	cmp	dx,0		; just exit for	a null target
	Lje	CleanExit
	mov	[targlen],dl	; store	target length
	dec	cx
	inc	bx
	jmp	FnameSrch	; search for file name

ScanOptions:
	dec	cx		; process options (/c /n /v /i)
	Ljcxz	ReportER1
	inc	bx
	mov	al,[bx]		; ignore a / followed by a space
	cmp	al,' '
	je	Recycle
	ToUpper	al
	cmp	al,'N'		; decode options
	je	SetNopt
	cmp	al,'C'
	je	SetCopt
	cmp	al,'V'
	je	SetVopt
	cmp	al,'I'
	je	SetIopt

	PushRegSet		; report invalid parameter 
	lea	dx,ermsg4
	MOS	prnstr
	PopRegSet
	push	dx
	Dchar	al
	Call	DispEOL


	pop	dx

Recycle:
	inc	bx		; advance pointer to continue parsing
	dec	cx		; parameter line
	Ljcxz	CleanExit
	jmp	FindNonBlank

SetNopt:
	mov	[nopt],true	; found	/n
	jmp	Recycle

SetCopt:
	mov	[copt],true	; found	/c
	jmp	Recycle

SetVopt:
	mov	[vopt],true	; found	/v
	jmp	Recycle

SetIopt:
	mov	[iopt],true	; found	/i
	jmp	Recycle

FnameSrch:

;-----------------------------------------------------------------------;
;   Transfer remainder of parameter line (file names) to fnambuf	;
;  Then	extract	each one, open the file	and search it for the target	;
;-----------------------------------------------------------------------;
	mov	[usestd],false
	Ljcxz	Filter		; no file name,	act as a filter
	xor	dl,dl		; init byte counter
	lea	di,fnambuf	; init pointer 
	mov	[fnampnt],di

SkipBlanks:			; skip over initial leading blanks
	mov	al,[bx]
	cmp	al,' '
	je	Fn1

XfertoBuf:
	mov	[di],al
	inc	bx		; inc buffer pointers
	inc	di
	inc	dl		; inc byte counter
	loop	Fn2
	mov	[fnamlen],dl	; store	count of all file names
	jmp	Recycle2

Filter:				; act as a filter when no file name supplied
	mov	[usestd],true
	call	OpenSearch
	jnc	$+5
	jmp	DirtyExit
	jmp	CleanExit

Fn1:				; part of initial blank	skipping
	inc	bx
	dec	cx
	Ljcxz	Filter		; no file name,	act as a filter
	jmp	SkipBlanks

Fn2:
	mov	al,[bx]		; get another byte from	parameter line
	jmp	XfertoBuf

Recycle2:
	mov	cl,[fnamlen]	; init counter with remaining bytes in fnambuf
	xor	ch,ch
	Ljcxz	CleanExit	; last file name, all done


	mov	bx,[fnampnt]	; point	to next	file name in buffer

StripBlank:
	cmp	BYTE PTR [bx],' '  ; move past any leading blanks
	jne	FindEnd
	inc	bx
	loop	StripBlank
	jmp	CleanExit

FindEnd:			; search for end of file name
	mov	[fnampnt],bx

Fe1:
	cmp	BYTE PTR [bx],' '
	je	EndofName
	inc	bx
	loop	Fe1

EndofName:
	mov	BYTE PTR [bx],0	  ; set	up for ASCIIZ format
	mov	dx,[fnampnt]	; recover pointer to start of file name
	mov	[oldfnpt],dx	; and save for file error handler
	inc	bx
	jcxz	UpTarg
	dec	cx

UpTarg:
	True?	[iopt]		; ignore case?
	jne	Fn3		; if exact case match
	lea	si,[targbuf]	; the target string
	mov	di,si
	mov	cl,[targlen]
	xor	ch,ch		; string's length
	cld			; for string instructions
Up10:
	lodsb
	ToUpper	al
	mov	[di],al
Up20:
	inc	di
	loop	Up10		; next character

Fn3:
	mov	[fnampnt],bx	; update var for next file name	extraction
	mov	[fnamlen],cl	; update count of bytes	remaining in fnambuf
	call	OpenSearch	; open the file	and search it for the target
	jc	DirtyExit
	jmp	Recycle2


	subttl	error routines
	page


;-----------------------------------------------------------------------;
;		       Error reporting routines				;
;									;
;-----------------------------------------------------------------------;

ReportER1:
	lea	dx,ermsg1	; invalid number of parameters
F2:
	MOS	prnstr
	mov	al,2
	jmp	ExitFind

ReportER2:
	lea	dx,ermsg2	; syntax error
	jmp	F2

CleanExit:
        mov     al,[exit_code]  ; depending on search results
	jmp	ExitFind
DirtyExit:
	mov	al,2		; errorlevel 2

ExitFind:
	push	ax
	call	DispEOL
	pop	ax
	MOS	quit		; terminate program, return to MOS

EndOfProg  LABEL  BYTE

codeseg	ENDS

	END	start

