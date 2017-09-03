PAGE 90, 132
;
;****************************************************************************
;
;       MODULE NAME:    MACROS.INC        
;
;       TASK NAME:      none
;
;       PROJECT:        PC-MOS
;
;       CREATION DATE:  ????
;
;       REVISION DATE:  4/1/91
;
;       AUTHOR:         Martin Stitt
;
;       DESCRIPTION:    Useful Macro definitions
;
;
;               (C) Copyright 1991, The Software Link Inc.
;                       All Rights Reserved
;
;****************************************************************************
;
;       USAGE:          INCLUDE MACROS.INC
;
;****************************************************************************
;                       >> Revision Log <<
;
; DATE          PROG    DESCRIPTION OF REVISION
; ----          ----    -----------------------
; 4/1/91        BWR     Added lonj jump macros for the following SIGNED
;                       operations.
;
;                       LJL -   Long jump on <.
;                       LJG -   Long jump on >.
;                       LJLE -  Long jump on <=.
;                       LJGE -  Long jump on >=.
;
;****************************************************************************
	
;=============== long jump macros ================

jmpnc	macro	adr
	local	notjmp
	jc	notjmp
	jmp	adr
notjmp:
	endm

jmpnb	macro	adr
	jmpnc	adr
	endm

jmpae	macro	adr
	jmpnc	adr
	endm

jmpa	macro	adr
	local	notjmp
	jna	notjmp
	jmp	adr
notjmp:
	endm

jmpnbe	macro	adr
	jmpa	adr
	endm

jmpna	macro	adr
	local	notjmp
	ja	notjmp
	jmp	adr
notjmp:
	endm

jmpbe	macro	adr
	jmpna	adr
	endm

jmpc	macro	adr
	local	notjmp
	jnc	notjmp
	jmp	adr
notjmp:
	endm

jmpb	macro	adr
	jmpc	adr
	endm

jmpnae	macro	adr
	jmpc	adr
	endm

jmpz	macro	adr
	local	notjmp
	jnz	notjmp
	jmp	adr
notjmp:
	endm

jmpe	macro	adr
	jmpz	adr
	endm

jmpnz	macro	adr
	local	notjmp
	jz	notjmp
	jmp	adr
notjmp:
	endm

jmpne	macro	adr
	jmpnz	adr
	endm

jmps	macro	adr
	local	notjmp
	jns	notjmp
	jmp	adr
notjmp:
	endm

jmpm	macro	adr
	jmps	adr
	endm

jmpns	macro	adr
	local	notjmp
	js	notjmp
	jmp	adr
notjmp:
	endm

jmpp	macro	adr
	jmpns	adr
	endm

ljl     macro   jmpdest
        local   ppp1
        jge     ppp1
        jmp     jmpdest
ppp1:
        endm

ljg     macro   jmpdest
        local   ppp1
        jle     ppp1
        jmp     jmpdest
ppp1:
        endm

ljle    macro   jmpdest
        local   ppp1
        jg      ppp1
        jmp     jmpdest
ppp1:
        endm

ljge    macro   jmpdest
        local   ppp1
        jl      ppp1
        jmp     jmpdest
ppp1:
        endm

lje	macro	jmpdest
	local	ppp1
	jne	ppp1
	jmp	jmpdest
ppp1:
	endm

ljne	macro	jmpdest
	local	ppp1
	je	ppp1
	jmp	jmpdest
ppp1:
	endm

ljz	macro	jmpdest
	local	ppp1
	jnz	ppp1
	jmp	jmpdest
ppp1:
	endm

ljnz	macro	jmpdest
	local	ppp1
	jz	ppp1
	jmp	jmpdest
ppp1:
	endm

ljc	macro	jmpdest
	local	ppp1
	jnc	ppp1
	jmp	jmpdest
ppp1:
	endm

ljnc	macro	jmpdest
	local	ppp1
	jc	ppp1
	jmp	jmpdest
ppp1:
	endm

lja	macro	jmpdest
	local	ppp1
	jbe	ppp1
	jmp	jmpdest
ppp1:
	endm

ljb	macro	jmpdest
	local	ppp1
	jae	ppp1
	jmp	jmpdest
ppp1:
	endm


;=============== misc macros =====================

domos	macro
	pushf			; simulate an int 21h
	push	cs
	call	mosint21
	endm

fastmove macro
	local	mv
	shr	cx,1
	rep movsw
	jnc	mv
	movsb
mv:
	endm

jnext	macro			;; perform jmp $+2
	local	nxt
	jmp	short nxt
nxt:
	endm

; use this guy to move a double word.

movdd	macro	dest, src, freereg
	mov	freereg,word ptr src
	mov	word ptr dest,freereg
	mov	freereg,word ptr src&[2]
	mov	word ptr dest&[2],freereg
	endm

; use these guys to simplify register saving and restoring

pushset	macro	p1,p2,p3,p4,p5,p6,p7,p8,p9,p10,p11,p12,p13,p14
	irp	@@push,<p1,p2,p3,p4,p5,p6,p7,p8,p9,p10,p11,p12,p13,p14>
	ifnb	<@@push>
	push	@@push
	endif
	endm
	endm

; couldn't get irp to work for this one

popset	macro	p1,p2,p3,p4,p5,p6,p7,p8,p9,p10,p11,p12,p13,p14
	ifnb	<p14>
	pop	p14
	endif
	ifnb	<p13>
	pop	p13
	endif
	ifnb	<p12>
	pop	p12
	endif
	ifnb	<p11>
	pop	p11
	endif
	ifnb	<p10>
	pop	p10
	endif
	ifnb	<p9>
	pop	p9
	endif
	ifnb	<p8>
	pop	p8
	endif
	ifnb	<p7>
	pop	p7
	endif
	ifnb	<p6>
	pop	p6
	endif
	ifnb	<p5>
	pop	p5
	endif
	ifnb	<p4>
	pop	p4
	endif
	ifnb	<p3>
	pop	p3
	endif
	ifnb	<p2>
	pop	p2
	endif
	ifnb	<p1>
	pop	p1
	endif
	endm

;=============== common structures ================

; mjs 6/30/88  put this here since it is accessed by a number of modules

mmparm	 struc
parmrhad dw	?,?	; address of request handler
parmfeat dw	?	; feature bits
parmgran dw	?,?	; granularity
parmtot  dw	?,?	; total extended memory (pages)
parmused dw	?,?	; used extended memory (pages)
parm6ec  dw	?	; error code for int 6
parm6adr dw	?,?	; address or i/o instruction for int 6
parmscb  dw	?,?	; scb address - filled in by mos
parmiop  dw	?,?	; address of i/o permission bit map
parmaiv  dw	?	; offset to ivtable
parmpfa dw	?	; segment of 4k aligned page frame for coalesce
parmcpy	dw	?,?	; pointer to 386 block copy routine
mmparm	 ends

; irq reservation logic control values
; accessed by mosnxtsk, mosinit2, mos, mosint38

irq_no_res	equ	0	; no reservation
irq_nps_res	equ	2	; non-port specific reservation
irq_ps_res	equ	4	; port specific reservation
irq_auto_res	equ	6	; automatic reservation

