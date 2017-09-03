	page 62,132

;********************************************************************************
;*				                                             	*
;*                           ENQ/DEQ Support for MOS                         	*
;*                            Written by: Joe Owen                            	*
;*                                   03/25/87                                	*
;*                                                                            	*
;********************************************************************************
;*                                                                            	*
;* Version 2.0:                                                		       	*
;* (A) 10/27/87  Joe Owen -- Modified to save and use original INT 38 vector. 	*
;*									      	*
;* 02/20/89	SAH	Converted INT 38h to INT SERVICES		      	*
;*									      	*
;* 11/28/89	BWR	Marked messages for foreign language translation.	*
;*										*
;********************************************************************************

	include options.inc

code	segment	para	public	'code'
	assume	cs:code, ds:nothing, es:nothing, ss:nothing

begin	equ	this byte
	dd	-1
	dw	8000h		; this is a character device
	dw	stratg		; pointer to strategy routine
	dw	interupt	;    "     " interrupt   "
	db	'$$INT7F '

request	dd	0		; area to store request by MOS

stratg	proc	far
	mov	word ptr [request],bx
	mov	word ptr [request+2],es
	ret
stratg	endp

interupt proc	far
	push	es
	push	bx
	les	bx,[request]
	cmp	byte ptr es:[bx+2],0
	jne	i1
	push	ds
	push	bp
	push	di
	push	si
	push	dx
	push	cx
	push	ax
	lds	si,es:[bx+18]	; point to command line
	call	init
	les	bx,[request]
	mov	es:[bx+14],dx
	mov	es:[bx+16],ds
	pop	ax
	pop	cx
	pop	dx
	pop	si
	pop	di
	pop	bp
	pop	ds
i1:
	mov	word ptr es:[bx+3],0100h	; store result status
	pop	bx
	pop	es
	ret
interupt endp
aborted	equ	this byte
	page

zeroseg	segment at 0
	org	SERVICES*4		; INT 38H vector
vint38	dw	2 dup(?)	
	org	07Fh*4			; Bios INT 7F vector
vint7F	dw	2 dup(?)
zeroseg	ends

oldint38 dw	2 dup(?)

MOSWAIT	PROC	NEAR
	push	bx
	push	ax

	mov	ah,07			; new mos calls
	mov	al,02			; 8-14-87 JWO
	mov	bx,02
	pushf
	cli
	call	dword ptr [oldint38]

	pop	ax
	pop	bx
	ret

MOSWAIT	ENDP

zero	dw	0

;******************************************************************************
;*									                                          *
;*				INT 7FH Logic				                                  *
;*									                                          *
;* Upon entry to the int 7Fh logic AH contains the function code, AL may      *
;* contain parameters, BX is a resource number. Status code is returned in    *
;* AL.       								                                  *
;*									                                          *
;******************************************************************************

int7F	label near
	jmp	start
	db	'I7F'		; id bytes

start:
	sti
	push	ax		; [bp+16]
	push	bx		; [bp+14]
	push	cx		; . . .
	push	dx		; 
	push	si		; . . .
	push	di		;
	push	es		; . . .
	push	ds		; [bp+2]
	push	bp		; [bp+0]

	mov	bp,sp		; bp will be used 
	mov	bx,cs		; setup the ds register
	mov	ds,bx

	assume	ds:code,es:nothing,ss:nothing

	cmp	ah,0			; no functions lower than 0
	jl	ENQERR
	cmp	ah,1			; (or higher than 1)
	jg	ENQERR
	xor	bx,bx
	mov	bl,ah
	shl	bx,1
	jmp	[FUNCTABLE+bx]
	
FUNCTABLE	LABEL	WORD
	DW	ENQ			; 0 = ENQ (unconditional or not)
	DW	DEQ			; 1 = DEQ

ENQ	LABEL	NEAR
	mov	bx,ss:[bp+14]		; user BX
	cmp	bx,0
	je	ENQERR
	mov	ax,bx
	call	GETASKID		; THE MYSTERY CALL!(dx returns task ID)
ENQ1:
	call	SCANTABLE
	jnz	DOENQ
	cmp	[ENQTABLE+bx+2],dx	; see if we own it
	jne	ENQCONF
	jmp	SHORT ENQDONE
DOENQ:
	xor	ax,ax
	call	SCANTABLE
	jnz	ENQCONF
	mov	ax,ss:[bp+14]
	mov	[ENQTABLE+bx],ax
	mov	[ENQTABLE+bx+2],dx	; dx still has task ID
	cmp	bx,[ENQTUSED]
	jb	ENQDONE
	add	[ENQTUSED],4
ENQDONE:
	mov	BYTE PTR ss:[bp+16],0
	jmp 	EXIT
ENQCONF:
	cmp	BYTE PTR ss:[bp+16],0	; is it unconditional?
	jne	CONF1
	call	MOSWAIT			; yes, go call MOS WAIT
	jmp	ENQ1
CONF1:
	mov	BYTE PTR ss:[bp+16],1	; return RESOURCE BUSY
	jmp 	EXIT
ENQERR:
	mov	BYTE PTR ss:[bp+16],2	; return ERROR
	jmp 	EXIT

DEQ	LABEL	NEAR
	mov 	ax,ss:[bp+14]		; user BX
	call	SCANTABLE
	jnz	ENQERR
	mov	[ENQTABLE+bx],0		; clear table
	mov	[ENQTABLE+bx+2],0
	add	bx,4
	cmp	bx,[ENQTUSED]		; last entry
	jb	DEQINMID
TBLENTRY:
	or	bx,bx
	jz	TBLZERO
	sub	bx,4
	cmp	[ENQTABLE+bx],0
	je	TBLENTRY
	add	bx,4
TBLZERO:
	mov	[ENQTUSED],bx
DEQINMID:
	mov	BYTE PTR ss:[bp+16],0
	jmp	EXIT
EXIT:
	pop	bp
	pop	ds
	pop	es
	pop	di
	pop	si
	pop	dx
	pop	cx
	pop	bx
	pop	ax
	iret

;******************************************************************************
;*                                                                            *
;*                               Scan ENQ Table                               *
;*                                                                            *
;******************************************************************************
ENQTABLE LABEL	WORD
	DW	300 dup(0)		; 150 entries
ENQTLEN	EQU	$-ENQTABLE
ENQTUSED DW	0			; Number of entries currently (dynamic)

SCANTABLE	PROC	NEAR
	xor	bx,bx
SNQTLOOP:
	cmp	ax,[ENQTABLE+bx]	; check if match
	je	SNQTBACK
	add	bx,4
	cmp	bx,[ENQTUSED]		; have we used entries past here yet?
	jbe	SNQTLOOP
	cmp	bx,ENQTLEN		; Table full?
	jb	SNQTBACK		; No
	cmp	bx,ENQTLEN+1		; Set flags (NE) for return
SNQTBACK:
	ret
SCANTABLE	ENDP

;******************************************************************************
;*                                                                            *
;*                           MOS GET TASK ID ROUNTINE                         *
;*                                                                            *
;******************************************************************************

TASKID	EQU	16

GETASKID PROC	NEAR
	push	ax
	push	bx
	push	es

	mov	ah,04			; new mos calls
	mov	bx,0ffffh		; 8-14-87 JWO
	pushf
	cli
	call	dword ptr [oldint38]

	mov	dx,es:[TASKID]
	pop	es
	pop	bx
	pop	ax
	ret

GETASKID 	ENDP

;******************************************************************************
;*				Initialization				      *
;******************************************************************************
	assume	ds:nothing,es:nothing,ss:nothing

init:
	jmp	setup

instmsg db	'MOS ENQ/DEQ request handler v4.00              ',13,10,'$' ;@@XLAT

setup:
	lea	dx,instmsg
	call	print_msg
set_vect:

	mov	es,[zero]
	mov	cx,es:[vint38]
	mov	cs:[oldint38],cx
	mov	cx,es:[vint38+2]
	mov	cs:[oldint38+2],cx

	mov	es,[zero]
	lea	bx,int7F
	mov	es:[vint7F],bx
	mov	es:[vint7F+2],cs

good_finish:
	lea	bx,init
	add	bx,15
	mov	cl,4
	shr	bx,cl
	mov	dx,cs
	add	bx,dx
	mov	ds,bx
	xor	dx,dx
	ret	

;******************************************************************************
;*                                SUBROUTINES                                 *
;******************************************************************************

print_msg	proc	near
	push	ds
	push	cs
	pop	ds			; make ds point to cs
	mov	ah,9
	int	21h
	pop	ds			; restore ds
	ret
print_msg	endp

code	ends
	end

