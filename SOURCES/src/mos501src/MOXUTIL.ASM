	page	62,132
	title	MOXUTIL - utility functions for MOS utilities

	subttl  MOXUTIL Development Specification

;-----------------------------------------------------------------------;
;									;
;                    Development Specification				;
;									;
;									;
; Program Name: various MOS utilities      Assigned to: Jeffrey Mayo	;
; Module Name:  MOXUTIL                    Assign date: 12/09/86	;
; Entry Points: see publics declarations   Completed:   12/10/86	;
; Entry From:   MOS utility programs					; 
; Entry Method: near calls						;
; Purpose: 	support routines for MOS utility programs		;
; Refer To:	ADDTASK, REMTASK, etc.					; 
; Last Update:  12/10/86 						;
;									;
;-----------------------------------------------------------------------;

	subttl	MOXUTIL macros, equates, data
	page


grp	group	moss,gdata	; use gdata to define any global data.

moss	segment	word public 'code'
	assume cs:grp;ds:grp;es:grp
moss	ends

gdata	segment word public 'code'
gdata	ends

IN_MOXUTIL equ	0		; define to eliminate external declarations
				; in moxutil.inc

include	moxutl.inc

;--------------------------- VARIABLES -------------------------;

gdata	segment

Dchar	db	?	; used by the DispChar procedure

Fill	db	?	; fill to maintain word alignment

gdata	ends

	subttl	MOXUTIL global/external entry points
	page

moss	segment

;	external entry points

	extrn	ErrorW:near		; error handler for utilities
					; used by BasicDisp and DispChar

;	public entry points

	public	BasicDisp		; write asciiz string to handle
	public	DispStr			; write asciiz string to STDOUT
	public	DispErr			; write asciiz string to STDERR
	public	DispEol			; write CR LF string to STDOUT
	public	FindEnd			; find end of asciiz string
	public	FindLen			; return length of asciiz string
	public	DispChar		; write character to STDOUT
	public	Low2Upper		; convert char to upper case
	public	Parse			; parse a file name into an FCB
	public	Str2NumDW		; convert decimal ASCII to long word
	public	Bin2Dec			; convert longword to decimal ASCII
	public	Bytes2Para		; convert bytes to paragraphs
	public	GetParm			; parse parameter out of parse block
	public	PassSpace		; skip spaces in parse block
	public	Byte2Hex		; convert a byte to ASCII hex
	public	Word2Hex		; convert word to ASCII hex

	subttl MOXUTIL string display routines
	page
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
	Ljc	ErrorW
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

	subttl	MOXUTIL string handling routines
	page

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
	Ljc	ErrorW
	cmp	ax,1
;	Ljne	Ecl1	; disk full
	pop	dx
	pop	cx
	pop	bx
	pop	ax
	ret
DispChar ENDP

;-----------------------------------------------------------------------;
;			Low2Upper					;
;		Convert charactor in reg al to upper case		;
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
;		               Str2NumDW				;
;    converts the numeric string at ds:si to a value in dx:ax, the 	;
;    CY flag will be set for errors or overflow out of dx:ax		;
;-----------------------------------------------------------------------;

Str2NumDW PROC
	push	bx
	push	cx
	push	di
	push	bp
	xor	ah,ah
	xor	dx,dx
	cld
	lodsb		; get the first digit
	cmp	al,'0'
	jb	Sn2
	cmp	al,'9'
	ja	Sn2
	sub	al,48	; convert from ascii to numeric
	mov	bp,ax	; save intermeadiate value in bp:si
	xor	di,di
Sn1:
	lodsb		; get next digit
	cmp	al,'0'
	jb	Sn3
	cmp	al,'9'
	ja	Sn3
	sub	al,48	; if 0-9, convert and mul the previous
	xchg	ax,bp	; value in bp:di by 10
	xchg	dx,di

	sal	ax,1	; multiply by 10 by the equation
	rcl	dx,1	; 10X = 8X * 2X
	jc	Sn4
	mov	bx,ax
	mov	cx,dx
	sal	ax,1
	rcl	dx,1
	jc	Sn4
	sal	ax,1
	rcl	dx,1
	jc	Sn4
	add	ax,bx
	adc	dx,cx
	jc	Sn4

	xchg	ax,bp
	xchg	dx,di
	add	bp,ax	; add the new digit to the tally
	adc	di,dx
	jc	Sn4
	jmp	Sn1
Sn3:
	mov	ax,bp
	mov	dx,di
	clc
Sn4:
	pop	bp
	pop	di
	pop	cx
	pop	bx
	ret
Sn2:
	stc
	jmp	Sn4
Str2NumDW ENDP

;--------------------------------------------------------------------;
;                            Bin2Dec                                 ;
;             DX/AX=source, BX=end-of-target, CX=length              ;
;--------------------------------------------------------------------;

;		constants for Bin2Dec

w10000	dw	10000
w10	dw	10

Bin2Dec PROC  NEAR
	push	si
	push	di
	push	cx
	mov	si,cx
	cmp	si,4	; is it real long?
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

Bin2Dec ENDP

;-----------------------------------------------------------------------;
;			Bytes2Para					;
;          Convert the number of bytes in ax to paragraphs in ax	;
;-----------------------------------------------------------------------;

Bytes2Para PROC
	push 	cx
	add	ax,15	; round up to next whole paragraph
	mov	cl,4
	shr	ax,cl	; divide by 16
	pop	cx
	ret
Bytes2Para ENDP

	subttl	MOXUTIL parameter parsing routines
	page
;-----------------------------------------------------------------------;
;			Parse						;
;	ds:si is advanced as the parsing pointer.  es:di is data area	;
;-----------------------------------------------------------------------;

Parse PROC
	push	cx
	push	di
	xor	ax,ax		; initialize the FCB to 0's
	mov	cx,12
	cld
	rep	stosb
	pop	di
	push	di		; get FCB pointer back
	mov	al,0fh		; control byte
	MOS	Parsfil
	or	al,al		; set flags on al
	pop	di
	pop	cx
	ret
Parse ENDP

;-----------------------------------------------------------------------;
;		                GetParm					;
;      ds:si shoud point to the parsing location.  es:di should point   ;
;      to the FCB for parsing.  CY for syntax error			;
;      value returns in ax						;
;-----------------------------------------------------------------------;

GetParm PROC
	xor	dx,dx
	call	Parse
	cmp	BYTE PTR [di+1],0	; value OK?
	clc
	mov	ax,0
	je	Gp1
	push	si
	mov	si,di		; put FCB name in si for parse
	call	Str2NumDW
	pop	si
Gp1:
	ret
GetParm	ENDP


;-----------------------------------------------------------------------;
; 		                PassSpace				;
;     advances the pointer ds:si past any spaces			;
;-----------------------------------------------------------------------;

PassSpace PROC
	cld
Ps1:
	lodsb
	cmp	al,' '
	je	Ps1
	dec	si
	ret
PassSpace ENDP

	subttl	MOXUTIL debug routines
	page

;---------------- SUBROUTINES FOR DEVELOPMENT ONLY  --------------------;

; $$$$$$$$$ can kill these when remove dump

;-----------------------------------------------------------------------;
;		              Byte2Hex					;
;	supply byte in al, es:di pointing to data area for hex chars	;
;	to be written							;
;-----------------------------------------------------------------------;

HexTbl	db	'0123456789ABCDEF'

Nib2Hex PROC		; used internally by Byte2Hex
	push	bx
	and	al,0fh
	lea	bx,cs:[HexTbl]
	xlat	cs:[HexTbl]
	pop	bx
	ret	

Nib2Hex ENDP

Byte2Hex PROC
	push	ax
	push	cx
	cld
	mov	ah,al
	mov	cl,4
	shr	al,cl
	call	Nib2Hex
	stosb
	mov	al,ah
	call	Nib2Hex
	stosb
	pop	cx
	pop	ax
	ret
Byte2Hex ENDP

;-----------------------------------------------------------------------;
;		                  Word2Hex				;
;   supply word in ax, pointer in es:di					;
;-----------------------------------------------------------------------;

Word2Hex PROC
	push	ax
	xchg	al,ah
	call	Byte2Hex
	mov	al,ah
	call	Byte2Hex
	pop	ax
	ret
Word2Hex ENDP

moss	ends

	END
