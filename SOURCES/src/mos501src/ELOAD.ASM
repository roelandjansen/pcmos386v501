	title	ELOAD - MOS 32-Bit Application Loader
	include	page.inc
	
;--------------------------------------------------------------------;
;              PC-MOS/386 Loader for 32-bit Applications             ;
;--------------------------------------------------------------------;
;								     ;
;  This program is designed to be assembled and linked using 386ASM  ;
;  and 386LINK from Phar Lap Software, Inc.  Use the following:      ;
;								     ;
;	386asm  eload  						     ;
;	386link eload -8086 -map con				     ;
;								     ;
;--------------------------------------------------------------------;

;------------------------- Revision Log --------------------------------;
;									;
; Prog	Date		Description of Revision. 			;
; ----  ----		------------------------			;
; BWR	10/27/89	Marked messages for foreign language		;
;			translations.  Also added the .386 pseudo-op	;
;			to permit assembly under MASM version 5.1	;
;									;
;-----------------------------------------------------------------------;
.386

dataseg segment para public use32 'data'

	db	'(c) Copyright 1987 The Software Link, Incorporated ' ;@@XLAT

	even
faroff	dd	0
farseg	dw	0

prgname	db	14 dup(0)		; program name
inhand	dw	0			; input file handle

;---------------------------- EXP Header ----------------------------;

exphead	label	word 
expsig	dw	0		; 'MP' indicates exp format
expfs1	dw	0		; filesize mod 512
expfs2	dw	0		; nbr 512-byte blocks to contain file
expnri	dw	0		; nbr relocation items - always zero
expofp	dw	0		; offset in file to start of program
expmin	dw	0		; minimum data size in 4k pages
expmax	dw	0		; maximum data size in 4k pages 
expesp	dd	0		; initial value for ESP
expsum	dw	0		; negated sum of all words in the file
expeip	dd	0		; initial value for EIP
expofr	dw	0		; offset to first relocation item - always 0
expovn	dw	0		; overlay number
explen	equ	$-exphead	; header size = 1ch

;---------------------------- Messages ------------------------------;

msgopen db	13,10,'Cannot find specified file!        ',13,10 ;@@XLAT
msgopenl equ	$-msgopen
msgform db	13,10,'Specified file is not an EXP file!   ',13,10 ;@@XLAT
msgforml equ	$-msgform
msgmem	db	13,10,'Insufficient extended memory!              ',13,10 ;@@XLAT
msgmeml	equ	$-msgmem
msgio	db	13,10,'I/O error! ',13,10 ;@@XLAT
msgiol  equ	$-msgio
msg386	db	13,10,'System error!   ',13,10 ;@@XLAT
msg386l	equ	$-msg386
msgsyn  db	13,10,'Syntax error! ',13,10 ;@@XLAT
msgsynl equ	$-msgsyn

dataseg ends

;----------------------------- Stack --------------------------------;

stakseg segment para stack use32 'stack'
	db	128 dup('Stak')	; 512 bytes of stack space
stakseg ends

	page
;--------------------------------------------------------------------;
;                              Begin                                 ;
;--------------------------------------------------------------------;

mainseg segment	para public use32 'code'
	assume  cs:mainseg,ds:dataseg,ss:stakseg

;---------- The following section runs in Virtual 8086 Mode ---------;

entry	label	near
	xor	eax,eax		; init fs to zero
	mov	fs,ax
	mov	ax,ds
	mov	gs,ax		; init gs to point to psp
	add	al,10h		; and bump ds,es to point to data segment
	adc	ah,0
	mov	ds,ax
	mov	es,ax
	mov	ah,10h		; go to native mode
	mov	al,01h
	mov	dx,cs		; tell MOS the NCA's segment address
	mov	ch,1024/256	; tell MOS the NCA's length
	mov	cl,0 
	jmp	start+2		; +2 compensates for the fact that the
				;   assembler doesn't know that this 
				;   instruction executes in 16-bit mode

	org	entry+1024 	; make room for the NCA

start	label	near
	int	38h		; execute switch to native mode

;------------------- We are now in Native Mode ----------------------;

	mov	esi,81h			; locate program name
	call	findnb			;   it's the first nonblank parm
	cmp	al,20h			; error if there is none
	jb	errsyn
	mov	edi,offset prgname	; extract it to work area
	call	extract
	cmp	al,'.'
	jne	noext
	stosb
	call	extract
	jmp	short gotext
noext:
	mov	dword ptr [edi],'pxe.'
	add	edi,4
gotext:
	dec	esi			; point to delimeter character
	cmp	[prgname+13],0		; check if length is reasonable
	jne	errsyn

;------- Shift PSP parameters left to get rid of program name -------;

	push	ds
	push	es

	mov	ax,gs
	mov	ds,ax
	mov	es,ax

	mov	eax,esi			; adjust parms length
	sub	al,81h
	sub	byte ptr ds:[80h],al

	xor	ecx,ecx			; shift program name out of parms
	mov	cl,byte ptr ds:[80h]
	inc	cl
	mov	edi,81h
	cld
	rep	movsb

	pop	es
	pop	ds

;------------------ Open program file and get header ----------------;

	mov	ax,3d40h		; open deny none, read access
	mov	edx,offset prgname
	int	21h
	jc	erropen			; error if cannot open
	mov	[inhand],ax

	mov	ah,3fh			; read header
	mov	bx,[inhand]
	mov 	ecx,explen
	mov	edx,offset exphead
	int	21h
	jc	errform			; error if read fails

	cmp	[expsig],'PM'		; check if 'MP' signature
	jne	errform

;------------------ Allocate extended memory for code ---------------;

	xor	ebx,ebx			; must compute length in ebx
	mov	bx,[expfs2]		; number of 512-byte blocks
	add	ebx,7			; convert to 4k pages
	shr	ebx,3
	add	bx,[expmin]		; add minimum data requirements
	shl	ebx,12			; convert to bytes

	mov	ah,11h			; allocate 
	int	38h			; returns selector in es
	jc	errmem			; jump if allocation error

;--------------------- Read program into memory ---------------------;

	mov	ax,4200h		; move file i/o pointer
	xor	ecx,ecx
	mov	cx,[expofp]
	mov	bx,[inhand]
	int	21h
	jc	errio

	mov	ah,3fh			; read the stuff
	xor	edx,edx
	xor	ecx,ecx
	mov	cx,[expfs2]
	shl	ecx,9
	push	ds
	push	es
	pop	ds
	int	21h
	pop	ds
	jc	errio

	mov	ah,3eh			; close the handle
	mov	bx,[inhand]
	int	21h

;------------- Set up registers and enter the application -----------;

;	The EXP format does not provide relocation values for segregs,
;	therefore we assume that CS=DS=ES=SS = start of program.
;	We will also point FS to absolute 0, and GS to the PSP.

	mov	bx,es			; load new ss/esp 
	mov	ss,bx
	mov	esp,[expesp]

	mov	ax,1302h		; get alias for code selector in ax
	mov	bx,es
	int	38h
	jc	err386

	mov	edx,[expeip]		; build address for indirect far call
	mov	[faroff],edx
	mov	[farseg],ax

	push	es			; ds,es must point to program segment
	pop	ds

	xor	eax,eax			; clean the slate
	mov	ebx,eax
	mov	ecx,eax
	mov	edx,eax
	mov	esi,eax
	mov	edi,eax
	mov	ebp,eax

	push	es
	call	fword ptr gs:[faroff+100h]

;-------------------- Return from the application -------------------;

	pop	es

	push	ax			; save their return code 
	mov	ah,12h			; release program memory
	int	38h
	pop	ax

	mov	ah,4ch 			; return to command processor
	int	21h

	page
;--------------------------------------------------------------------;
;			Some Subroutines			     ;
;--------------------------------------------------------------------;

findnb	proc	near		; find next nonblank character
	cld
	lods	byte ptr gs:[esi]
	cmp	al,20h
	je	findnb
	dec	esi
	ret
findnb	endp

extract	proc	near		; copy until next delimeter
	lods	byte ptr gs:[esi]
	cmp	al,20h
	jbe	extret
	cmp	al,'.'
	je	extret
	cmp	al,'/'
	je	extret
	stosb
	jmp	extract
extret:
	ret
extract endp

	page
;--------------------------------------------------------------------;
;                           Termination                              ;
;--------------------------------------------------------------------;

release label	near
	mov	ah,12h			; release selector in es
	int	38h

termin8 label	near
	mov	ax,4c00h		; exit back to MOS
	int	21h

;------------------------ Error Termination -------------------------;

errsyn	label	near			; syntax error
	mov	ah,40h			; write error message
	mov	bx,1			; to standard output
	mov	ecx,msgsynl
	lea	edx,[msgsyn]
	int	21h
	jmp	termin8

erropen	label	near			; open error
	mov	ah,40h			; write error message
	mov	bx,1			; to standard output
	mov	ecx,msgopenl
	lea	edx,[msgopen]
	int	21h
	jmp	termin8

errform	label	near			; signature error
	mov	ah,40h			; write error message
	mov	bx,1			; to standard output
	mov	ecx,msgforml
	lea	edx,[msgform]
	int	21h
	jmp	termin8

errmem	label	near			; signature error
	mov	ah,40h			; write error message
	mov	bx,1			; to standard output
	mov	ecx,msgmeml
	lea	edx,[msgmem]
	int	21h
	jmp	release

errio	label	near			; signature error
	mov	ah,40h			; write error message
	mov	bx,1			; to standard output
	mov	ecx,msgiol
	lea	edx,[msgio]
	int	21h
	jmp	release

err386	label	near			; signature error
	mov	ah,40h			; write error message
	mov	bx,1			; to standard output
	mov	ecx,msg386l
	lea	edx,[msg386]
	int	21h
	jmp	release

mainseg ends
	end	entry

