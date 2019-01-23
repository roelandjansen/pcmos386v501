comment ^==============================================================

bwr 04/01/91	added long jump macros for the following signed
		operations:
		 ljl -   long jump on <.
		 ljg -   long jump on >.
		 ljle -  long jump on <=.
		 ljge -  long jump on >=.

mjs 09/23/92	mosinit overhaul.
		added new macros: fcall, fjmp, ldseg.
		moved lproc macros to here from mosregs.inc.

======================================================================^

;==== macros for intersegment far calls, jumps and loads

mseg		equ	1	; mos segment
m2seg		equ	2	; mo2 segment
iseg		equ	3	; init segment
gseg		equ	4	; grp segment
zseg		equ	5	; zero segment
bseg		equ	6	; bios segment

FAR_CALL_OPCODE		equ	09ah
FAR_JMP_OPCODE		equ	0eah
MOVAX_OPCODE		equ	0b8h

fcall	macro	p1, p2
local	segpt
	db	FAR_CALL_OPCODE
	dw	p2
segpt	dw	?
fcseg	segment
	db	segment_num		;; current segment #
	db	p1			;; target segment #
	dw	segpt			;; offset of point needing filled in
fcseg	ends
	endm

fjmp	macro	p1, p2
local	segpt
	db	FAR_JMP_OPCODE
	dw	p2
segpt	dw	?
fcseg	segment
	db	segment_num		;; current segment #
	db	p1			;; target segment #
	dw	segpt			;; offset of point needing filled in
fcseg	ends
	endm

; usage: ldseg ds,gseg

ldseg	macro	p1, p2
local	segpt
	push	ax
	db	MOVAX_OPCODE
segpt	dw	?
	mov	p1,ax
	pop	ax
fcseg	segment
	db	segment_num		;; current segment #
	db	p2			;; target segment #
	dw	segpt			;; offset of point needing filled in
fcseg	ends
	endm
	
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

;================= local stack macros (lproc)

if 0 eq 0			; fake out periscope PUBLIC.COM
				;   (we don't want these public)

OVERFLOW   equ	0800H		; field the flags register
DIRECTION  equ	0400H
INTERRUPT  equ	0200H
SINGLESTEP equ	0100H
SIGN	   equ	0080H
ZERO	   equ	0040H
AUXILLIARY equ	0010H
PARITY	   equ	0004H
CARRY	   equ	0001H

TIP	equ	(word ptr [bp+0])
TCS	equ	(word ptr [bp+2])
TFLAG	equ	(word ptr [bp+4])
TDS	equ	(word ptr [bp+6])
TES	equ	(word ptr [bp+8])
TDI	equ	(word ptr [bp+10])
TSI	equ	(word ptr [bp+12])
TBP	equ	(word ptr [bp+14])
; word ptr [bp+16] reserved
TBX	equ	(word ptr [bp+18])
TBL	equ	(byte ptr [bp+18])
TBH	equ	(byte ptr [bp+19])
TDX	equ	(word ptr [bp+20])
TDL	equ	(byte ptr [bp+20])
TDH	equ	(byte ptr [bp+21])
TCX	equ	(word ptr [bp+22])
TCL	equ	(byte ptr [bp+22])
TCH	equ	(byte ptr [bp+23])
TAX	equ	(word ptr [bp+24])
TAL	equ	(byte ptr [bp+24])
TAH	equ	(byte ptr [bp+25])
TSTACK	equ	(dword ptr [bp+26])
TSP	equ	(word ptr [bp+26])
TSS	equ	(word ptr [bp+28])
; word ptr [bp+30] reserved

endif

	subttl	macros for defining reentrant procedures with local variables
	page

lproc	macro	name
name	proc	near
	push	bp		;; save "standard" bp
	mov	bp,sp
	db	83h,0ech,lt&name ; sub sp,lt&name
	push	bp		;; save stack pointer before allocation
lsize = 0
	endm

; close a procedure frame (throw away local variables)
lendp	macro	name
	pop	sp		;; this was pushed as bp
	pop	bp		;; restore "standard" bp
	ret
lt&name equ	(lsize and 1)+lsize	;; round it to an even number
name	endp
	endm

; allocate space in this procedure stack frame for one byte of local storage
lbyte	macro	name
	local	lb
lsize = lsize + 1
lb	equ	0+lsize
ldef	<name>
name	equ	(byte ptr [bp-lb])
	endm

; allocate space in this procedure stack frame for one word of local storage
lword	macro	name
	local	lw

lsize = (lsize and 1) + lsize	;; round size to even number
lsize = lsize + 2
lw	equ	0+lsize
ldef	<name>
name	equ	(word ptr [bp-lw])
	endm

; allocate space in this procedure stack frame for one dword of local storage
ldword	macro	name
	local	ld

lsize = (lsize and 1) + lsize	;; round size to even number
lsize = lsize + 4
ld	equ	0+lsize
ldef	<name>
name	equ	(dword ptr [bp-ld])
	endm

; allocate space in this procedure stack frame for len bytes of local storage
lstring macro	name,len
	local	ls

lsize = (lsize and 1) + lsize	;; round size to even number
lsize = lsize + len
ls	equ	0+lsize
ldef	<name>
name	equ	(byte ptr [bp-ls])
	endm

; def a local variable defined with above
ldef	macro	name
ifdef ??&name
if ??&name ne 0
	%out	ldef nesting error with &name
endif
endif
??&name  = 1
	endm

; undef a local variable defined with above
lundef	macro	name
ifdef ??&name
if ??&name ne 1
	%out	lundef nesting error with &name
endif
else
	%out	lundef nesting error with &name
endif
??&name = 0
name	equ	(far ptr [bx][si])
	endm


MSetPsp macro	reg
	mov	[TCBPSP],reg
	mov	[TCBOLDPSP],reg
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