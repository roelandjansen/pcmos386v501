;-----------------------------------------------------------------------;
; MOSREGS.INC - define locations of application's saved registers       ;
;									;
; the saved registers for the current partition are accessed using the	;
; labels below.  the parentheses mean you can override the type 	;
; attribute if you need to						;
;									;
; these can be used as if they were memory locations			;
;									;
;	mov	ax,[TBP]						;
;	mov	[TBP],ax						;
;									;
; are both valid instructions which do what you would think whenever	;
; the registers are set up in their default configuration (i.e. SS	;
; is pointing to the TCB for the current partition and BP has the value ;
; which was set by MOSSAVER)						;
;-----------------------------------------------------------------------;
; SAH	07/29/87	Macros MGetPsp and MSetPsp have been added to	;
;			speed up optimization - this macros do the same ;
;			function as functions 50 and 51 but not the	;
;			overhead. Kept as macro to insured no problems	;
;			in changes of functions 50 or 51 if any 	;
;-----------------------------------------------------------------------;
; SAH  01/04/87 	Macros MGetGRP and MGetGRP2 have been added so	;
;			that we can get SCBSEG (GRP) from 0040:03FC.	;
;			Macros MGetZERO and MGetZERO2 have add for zero ;
;			ZERO segment.  These macros have been added for ;
;			converting kernal to 286 Protected MODE driver. ;
;-----------------------------------------------------------------------;
; SAH\RBR 02/11/88	Created new callmosX macros for inter-segment	;
;			calls						;
;-----------------------------------------------------------------------;
; SAH 12/14/89		Remove stack checking logic			;
;-----------------------------------------------------------------------;
; SAH 02/01/90		Corrections for LanLink psp and changes for	;
;			windows/2.11 so LanLink does not have to be 	;
;			patch.						;
;-----------------------------------------------------------------------;

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


	; The following macro is used to call code in the MOS segment from
	; MOSFUTIL, MOSFUN39, MOSFUN0F, and MOSMIMAN.  See MOS2 in MOSFUTL2
	; for explanation.

callmos1 macro	adr
	ifndef	caller1
	extrn	caller1:near
	endif
	call	caller1
	dw	offset mos:adr
	endm

	; The following macro is used to call code in the MO2 segment 
	; (MOSFUTIL, MOSFUN39, MOSFUN0F, and MOSMIMAN) from the MOS segment.
	; See MOS2 in MOSFUTL2 for explanation.

callmos2 macro	adr
	ifndef	caller2
	extrn	caller2:near
	endif
	call	caller2
	dw	offset mo2:adr
	endm

;   PSP optimization Macro's instead of internal INT 21 calls for speed

MGetPsp macro	reg
	mov	reg,[TCBPSP]
	endm

MSetPsp macro	reg
	mov	[TCBPSP],reg
	mov	[TCBOLDPSP],reg
	endm


;   Macros for geting SCBSEG and ZERO segments

MGetSCB macro	reg
	ifndef	grpseg1
	extrn	grpseg1:word
	endif
	mov	reg,cs:[grpseg1]		; address GRP
	endm

MGetSCB2 macro	reg		
	ifndef	grpseg2
	extrn	grpseg2:word
	endif
	mov	reg,cs:[grpseg2]		; address GRP
	endm

MGetZERO macro	reg
	mov	reg,cs:[sbios]			; get bios segment
	mov	reg,reg&:[03fch]		; get ZERO seg from abs loc
	endm

MGetZERO2 macro reg
	mov	reg,cs:[sbios2] 		; get bios segment
	mov	reg,reg&:[03fch]		; get ZERO seg from abs loc
	endm
