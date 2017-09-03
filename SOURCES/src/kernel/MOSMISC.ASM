	include PAGE.INC
	title	MOStemp.ASM - temp MOS module
	extrn bugerror:near

;-----------------------------------------------------------------------;
;									;
;		Development Specification				;
;									;
;									;
; Program Name: MOSMISC.ASM 		Assigned to: Stewart Hyde	;
; Module Name:	MOSMISC 		Assign date: 01/22/90		;
; Entry Points: n/a			Completed:   01/22/90		;
; Entry From:	n/a							;
; Entry Method: n/a							;
; Calls:	n/a							;
; Purpose:	provide misc utility routines for PC-MOS		;
; Refer to:	n/a							;
; Last Update:	01/22/90						;
;-----------------------------------------------------------------------;
	include GROUP.INC

.xlist
	include MOSREGS.INC
	
tcb	segment at 1234h
	include MOSTCB.INC	; TCB definition
tcb	ends

gdata	segment para public 'data'
	include MOSSCBEX.INC	; specify all SCB items as external
gdata	ends
.list

irq	segment byte public 'data'
irq	ends

poll	segment byte public 'data'
poll	ends

ddt     segment word public 'code2'
	assume	cs:mo2,ds:nothing,es:nothing,ss:nothing

;-----------------------------------------------------------------------;
; WordMov - This procedure is use to take advantage of 386/486 32 bit	;
;	     instructions if processor is present			;
;									;
;-----------------------------------------------------------------------;
	public	WordMov
WordMov proc	near
	pushf			; some replacement might depend on carry
	push	ds
	MGetSCB2 ds
	assume  ds:grp
	cmp	[SCBREG32],'Y'	   		; 386/486 CPU
	pop	ds
	assume  ds:nothing
	jne	Wrd16
	cmp	cx,4
	jb	Wrd16
;
;	Handle the Block Move on 386/486 CPUs
;
	shr	cx,1
	db	66h
	rep	movsw		; 32 bit move
	jnc	Skp32
	movsw			; move final word
Skp32:
	popf
	ret
;
;	Handle the block copy on a 8088/286 CPU's
;
Wrd16:
	rep	movsw
	popf
	ret
WordMov endp

ddt     ends

	page
mosseg	segment para public 'code1'
	assume	cs:mos,ds:grp,es:nothing,ss:tcb

;-----------------------------------------------------------------------;
; WordMove - This procedure is use to take advantage of 386/486 32 bit	;
;	     instructions if processor is present			;
;									;
;-----------------------------------------------------------------------;
	public	WordMove
WordMove proc	near
	pushf			; some replacement might depend on carry
	push	ds
	MGetSCB ds
	assume  ds:grp
	cmp	[SCBREG32],'Y'	   		; 386/486 CPU
	pop	ds
	assume  ds:nothing
	jne	Word16
	cmp	cx,4
	jb	Word16
;
;	Handle the Block Move on 386/486 CPUs
;
	shr	cx,1
	db	66h
	rep	movsw		; 32 bit move
	jnc	Skip32
	movsw			; move final word
Skip32:
	popf
	ret
;
;	Handle the block copy on a 8088/286 CPU's
;
Word16:
	rep	movsw
	popf
	ret
WordMove endp

mosseg	ends
	end
