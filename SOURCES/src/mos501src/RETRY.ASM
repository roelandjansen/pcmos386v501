	include page.inc
	title	patch410.asm 
	subttl	patch410.asm - generic patch driver for pc-mos 4.10
comment ^===============================================================

 Only for MOSADM Retry Fix for MOS 4.10   (Target Data)

 If you pulled this off the version control system and wondering 
 what it is.  It's a fix for custumer in 4.10 and should be ignored
 I place it on the PVCS system primarily for historic purposes

		     development specification

 program name:	retry.sys		   assigned to: Stewart Hyde
 module name:	retry.asm		   assign date: 04/15/92
 entry points:	strat/intr		   completed:	04/15/92
 entry from:	todriver
 entry method:	device driver call
 purpose:	patches in repairs to mos 4.10
 refer to:	n/a
 last update:	04/15/92

=======================================================================

SAH 02/21/92    Version 2.03 - corection for mosint17 so that we have
	        Infinite retry on printer.
		This driver uses offset 12e9h to 12ech of MOS's patch area

======================================================================^

	include macros.inc
.xlist
	include options.inc

;!!!! start of 'keep together' section

	include mosregs.inc

;!!!! end of 'keep together' section


	include mospsp.inc
	include mostfb.inc

tcb	segment at 0
	include mostcb.inc
tcb	ends

scbx	segment at 0
	assume cs:scbx
	org	240h			; hard code for 4.10
	include mosscbdf.inc
	org	212ch
i16old  dd	?			; orginal int 16 
scbx	ends
.list


bios	segment at 40h			; define bios variables

	org	17h
ikbstat db	?			; keyboard status byte
	org	1ah
ikbhead dw	?			; keyboard queue head pointer
ikbtail dw	?			; 40:1c tail pointer
ikbbuff dw	10 dup (?)

	org	49h
biomode db	?
biocols db	?
	db	?
biopgln dw	?
biopgst dw	?
biocpos dw	8 dup(?)
bioctyp dw	?
biopage db	?
biocrt	dw	?
bio3x8	db	?
biopal	db	?

bios	ends

mbseg	segment at 1111h

mbtype	db	?			; m for memory block, z for last block
mbowner dw	?			; owner psp address
mbsize	dw	?			; size of block

mbseg	ends


code	segment para
	assume	cs:code, ds:nothing, es:nothing, ss:nothing
begin:
	dd	-1
	dw	8000h			; this is a character device
	dw	stratg			; pointer to strategy routine
	dw	interupt		;   "     " interrupt	"
	db	'_RETRY  '

request dd	0		; area to store request by mos

stratg:
	mov	word ptr cs:[request],bx
	mov	word ptr cs:[request+2],es
	retf

interupt:
	pushset bx,es
	les	bx,cs:[request]
	cmp	byte ptr es:[bx+2],0
	jne	i1
	call	init
i1:
	popset	bx,es
	retf

far_call_opcode	equ 09ah
far_jmp_opcode	equ 0eah

wkey	equ	1			; wait for keystroke

numpad_lo equ	71			; lowest keycode from numeric pad
numpad_hi equ	83			; highest keycode from numeric pad

k_f1	equ	59			; function key 1
k_f2	equ	60			; function key 2

kbs_rshf equ	01h			; right shift pressed
kbs_lshf equ	02h			; left shift pressed
kbs_shf  equ	03h			; any shift key pressed
kbs_ctl  equ	04h			; ctrl key pressed
kbs_alt  equ	08h			; alt key pressed
kbs_scrl equ	10h			; scroll locked
kbs_num  equ	20h			; numpad locked
kbs_cap  equ	40h			; caps locked
kbs_ins  equ	80h			; insert state

kbc_e1	 equ	01h			; e1 prefix last
kbc_e0	 equ	02h			; e0 prefix last
kbc_rctl equ	04h			; right control key pressed
kbc_ralt equ	08h			; right alt key pressed
kbc_101  equ	10h			; 101/102 keyboard installed
kbc_us	 equ	20h			; us driver wanted
kbc_keyb equ	0c0h			; type of keyboard installed

sbios	dw	40h
zeroseg dw	0

mos_seg dw	?			; location of mos segment
mo2_seg dw	?			; location of mo2 segment
scb_seg dw	?			; location of scb segment



;======================================================================
; fix for version 2.03 - added Infinite Retry support to MOSINT17
;
; This fix will only work with new MOSADM RETRY command.
;======================================================================

assume   ss:tcb
;
; following procedure is use to check for infinete retry and if so
; call tsl so task will suspend for a while and then return so that
; the remaining of INT 17h logic continues
;

InfRetry proc	near
	push	ax
	push	cx
	mov	ax,1
	or	bx,bx
	jz	InfRetryCont
	mov	cl,bl
	shr	ax,cl
InfRetryCont:
	test	al,[tcbiretry]
	jz	IRetryOut
	mov	[tcbslcnt],0
	pushf
	db	far_call_opcode			; jmp far xxxx:12e9h
	dw	12e9h
Seg203a	dw	?				; MOS's segment
	popf
IRetryOut:
	pop	cx
	pop	ax
	ret
InfRetry endp

;
; The following code is inserted into patch area at offset
; It is use as method to call TSL from patch410.sys device driver
;

FarCallTsl proc	 far
	   db	0e8h			;
	   dw	0b7c9h			; call TSL
	   ret
FarCallTsl endp
CallTslLen equ   ($-FarCallTsl)

fix203a	proc	near
	cmp	[tcbtocx],-1		; test timed out
	jne	i17w_ok
	mov	ax,1
	or	bx,bx			; LPT0?
	jz	i17w_cont
	mov	cl,bl
	shr	ax,cl	      		; mask correct port in
i17w_cont:	
	test	al,[tcbiretry]
	jz	i17w_ok
;
; far jump to 17w_loop at offset bc28h
;
	db	far_jmp_opcode			; jmp far xxxx:bc28h
	dw	0bc28h
Seg203b	dw	?				; MOS's segment

i17w_ok:
	db	far_jmp_opcode			; jmp far xxxx:bc58h
	dw	0bc58h
Seg203c	dw	?				; MOS's segment
fix203a endp

fix203b proc	far
	cmp	ah,90h
	je	fix203b1
	call	InfRetry
	jnz	fix203b2
	mov	ah,11h
fix203b1:
	db	far_jmp_opcode			; jmp far xxxx:bb4eh
	dw	0bb4eh
Seg203d	dw	?				; MOS's segment
fix203b2:
	db	far_jmp_opcode			; jmp far xxxx:bb3bh
	dw	0bb3bh
Seg203e	dw	?				; MOS's segment

fix203b endp

;======================================================================
	subttl	initialization
	page
	
	assume	ds:nothing,es:nothing,ss:nothing

end_res label	byte
	nop

instmsg 	db	13,10,'Retry.sys driver installed            ',13,10,'$'  ;@@xlat
notmosmsg	db	13,10,'Retry.sys must only be used with PC-MOS version 4.10                 ',7,7,13,10,'$'  ;@@xlat
notsmpmsg	db	13,10,'Retry.sys must be loaded globally                ',7,7,13,10,'$'	;@@xlat


InitSeg		dw	0		; segment for INIT segment



	page
;======================================================================
;.fs
; install203 - Correctly handles Infinite retry on printer
;
; in:	ax -> mos segment
;	es -> scb segment
;
; out:	ax -> mos segment
;
;.fe
;
; Note: This patch can be disable with -I
;=====================================================================^
	assume	ds:nothing,es:scbx,ss:nothing

Install203 proc	near
	mov	[seg203a],ax
	mov	[seg203b],ax
	mov	[seg203c],ax
	mov	[seg203d],ax
	mov	[seg203e],ax
	
	push	ax
	push	es
	pushf
	cli
	cld
	mov	es,ax
	push	ds
	push	cs
	pop	ds
	mov	si,offset FarCallTsl
	mov	di,12e9h
	mov	cx,CallTslLen
	rep	movsb
	pop	ds

	mov	di,0bc52h
	mov	al,far_jmp_opcode
	stosb
	mov	ax,offset fix203a
	stosw
	mov	ax,cs
	stosw

	mov	di,0bb47h
	mov	al,far_jmp_opcode
	stosb
	mov	ax,offset fix203b
	stosw
	mov	ax,cs
	stosw

	popf
	pop	es
	pop	ax
	ret
Install203 endp

	subttl ismos - test for mos
	page
;======================================================================
;.fs
; ismos - test for mos
;
; verify that this program is running under the pc-mos operating system
; before mos specific system calls are made.
;
; in:	none
;
; out:	nz flag if the os is mos
;	zr flag if not
;
;.fe
;=====================================================================^
	assume	ds:nothing,es:nothing,ss:nothing
ismos	proc	near
	pushset ax,bx,cx,dx
	mov	ax,3000h
	mov	bx,ax			; set ax == bx == cx == dx
	mov	cx,ax			; to read the mos version #
	mov	dx,ax
	int	21h
	push	ax
	mov	ax,3099h		; now insure ax is different
	int	21h			; to read the dos version #
	pop	bx
	cmp	bx,ax			; if bx != ax then mos
	popset	ax,bx,cx,dx
	ret
ismos	endp

	subttl init - initialize this device driver
	page
;======================================================================
;fs
; init - initialize this device driver
;
; verify mos is the os, then dynamically patch the kernel
;
; in:	none
;
; out:	none
;
;.fe
;=====================================================================^
	assume	ds:nothing,es:nothing,ss:nothing
init	proc	near
	pushset ax,bx,cx,dx,si,di,bp,ds,es
	mov	ax,cs
	mov	ds,ax
	assume	cs:code,ds:code,es:nothing

; make sure this is mos

	call	ismos
	jnz	yesmos
	mov	dx,offset notmosmsg
	xor	cx,cx
	jmp	initx
yesmos:

; make sure this is version 4.10

	mov	ax,3000h
	mov	bx,ax			; set ax == bx == cx == dx
	mov	cx,ax			; to read the mos version #
	mov	dx,ax
	int	21h
	cmp	ax,0a04h
	je	is410
	mov	dx,offset notmosmsg
	xor	cx,cx
	jmp	initx
is410:

; make sure this driver is loaded within the smp

	mov	dx,cs
	mov	ah,25h
	int	services
	or	ax,ax
	jnz	in_smp
	mov	dx,offset notsmpmsg
	xor	cx,cx
	jmp	initx
in_smp:

; setup es -> scb for later use within interrupt disabled section
; note: its ok to use the intd4fun02 method since this driver will
; not be used with any version after 4.10

	mov	ah,02
	int	services
	assume	es:nothing
	mov	[scb_seg],es

; use es->scb right now to fetch the mos segment

	mov	ax,es:[scbmosadr]
	mov	[mos_seg],ax

; derive the mo2 segment value

	mov	[mo2_seg],es
	add	[mo2_seg],230h		; version specific value !!

; install the patches


	call	Install203		; Infinite LPT Retry (Ver 2.03)

; display load message and return driver's ending point

	mov	dx,offset instmsg
	mov	cx,offset end_res
initx:
	mov	ah,9
	int	21h
	les	bx,cs:[request]
	mov	es:[bx+14],cx
	mov	es:[bx+16],cs
	mov	word ptr es:[bx+3],0100h
	popset	ax,bx,cx,dx,si,di,bp,ds,es
	ret
init	endp

code	ends
	end	begin

