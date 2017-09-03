;	Externs, equates, macros, and segment definitions for
;	MOXUTIL.

include options.inc

ifndef	IN_MOXUTIL

;	globally accessible entry points from MOXUTIL

	extrn	BasicDisp:	near	; write asciiz string to handle
	extrn	DispStr:	near	; write asciiz string to STDOUT
	extrn	DispErr:	near	; write asciiz string to STDERR
	extrn	DispEol:	near	; write CR LF string to STDOUT
	extrn	FindEnd:	near	; find end of asciiz string
	extrn	FindLen:	near	; return length of asciiz string
	extrn	DispChar:	near	; write character to STDOUT
	extrn	Low2Upper:	near	; convert char to upper case
	extrn	Parse:		near	; parse a file name into an FCB
	extrn	Str2NumDW:	near	; convert decimal ASCII to long word
	extrn	Bin2Dec:	near	; convert longword to decimal ASCII
	extrn	Bytes2Para:	near	; convert bytes to paragraphs
	extrn	GetParm:	near	; parse parameter out of parse block
	extrn	PassSpace:	near	; skip spaces in parse block
	extrn	Byte2Hex:	near	; convert a byte to ASCII hex
	extrn	Word2Hex:	near	; convert word to ASCII hex

endif

;	Standard handles

StdIn	equ	0000
StdOut	equ	0001
StdErr	equ	0002

;	Dos calls

OpenFil	equ	3dh
ClosFil	equ	3eh
ReadFil	equ	3fh
WritFil	equ	40h
ParsFil	equ	29h
Quit	equ	4ch
FreeMem equ	49h
ModMem	equ	4ah
GetMem	equ	48h
IOCtrl	equ	44h

;	Interupt 38 calls

GFTCB	equ	000h
ITask	equ	001h


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
Escape	equ	27


True?	MACRO	testflag
	cmp	testflag,True
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

MOS38   MACRO	fn
	mov	ah,fn
	int	SERVICES
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
