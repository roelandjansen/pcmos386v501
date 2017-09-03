	include page.inc
	title	patch410.asm
	subttl	patch410.asm - generic patch driver for pc-mos 4.10
comment ^===============================================================
		     development specification

 program name:	patch410.sys		   assigned to: martin stitt
 module name:	fux16410		   assign date: 10/08/90
 entry points:	strat/intr		   completed:	10/15/90
 entry from:	todriver
 entry method:	device driver call
 purpose:	patches in repairs to mos 4.10
 refer to:	n/a
 last update:	10/29/90

=======================================================================

sah  10/25/90	version 1.01 - added correction to correct problem with
		with int 21h function 67h.  also change driver so that
		initialization is more modular.

mjs 10/29/90	version 1.02 - added correction logic to mosint13
		for passport and other situations where a large
		number of sectors is read or written with one call.

mjs 12/11/90	version 1.03 - modified mosint13 correction logic 
		(introduced in ver 1.02) to not use int13fun08 for
		diskette operations.

======================================================================^

	include	macros.inc
.xlist
	include options.inc
	include	mosregs.inc
	include mospsp.inc

tcb	segment at 0
	include	mostcb.inc
tcb	ends

scbx	segment at 0
	assume cs:scbx
	include mosscbdf.inc
scbx	ends
.list

bios	segment at 40h			; define bios variables

	org	17h
ikbstat db	?			; keyboard status byte
	org	1ah
ikbhead dw	?			; keyboard queue head pointer
ikbtail dw	?			; 40:1c tail pointer
ikbbuff dw	10 dup (?)

bios	ends


code	segment	para
	assume	cs:code, ds:nothing, es:nothing, ss:nothing
begin:
	dd	-1
	dw	8000h			; this is a character device
	dw	stratg			; pointer to strategy routine
	dw	interupt		;   "     " interrupt   "
	db	'_PTCH410'

request	dd	0		; area to store request by mos

stratg:
	mov	word ptr cs:[request],bx
	mov	word ptr cs:[request+2],es
	retf

interupt:
	pushset	bx,es
	les	bx,cs:[request]
	cmp	byte ptr es:[bx+2],0
	jne	i1
	call	init
i1:
	popset	bx,es
	retf


wkey	equ	1			; wait for keystroke

numpad_lo equ	71			; lowest keycode from numeric pad
numpad_hi equ	83			; highest keycode from numeric pad

k_f1	equ	59			; function key 1
k_f2	equ	60			; function key 2

kbs_rshf equ	01h			; right shift pressed
kbs_lshf equ	02h			; left shift pressed
kbs_shf	 equ	03h			; any shift key pressed
kbs_ctl	 equ	04h			; ctrl key pressed
kbs_alt	 equ	08h			; alt key pressed
kbs_scrl equ	10h			; scroll locked
kbs_num	 equ	20h			; numpad locked
kbs_cap	 equ	40h			; caps locked
kbs_ins	 equ	80h			; insert state

kbc_e1	 equ	01h			; e1 prefix last
kbc_e0	 equ	02h			; e0 prefix last
kbc_rctl equ	04h			; right control key pressed
kbc_ralt equ	08h			; right alt key pressed
kbc_101	 equ	10h			; 101/102 keyboard installed
kbc_us	 equ	20h			; us driver wanted
kbc_keyb equ    0c0h			; type of keyboard installed

sbios	dw	40h

mos_seg	dw	?			; location of mos segment


;==== code to dynamically patch into mosint16

	assume	ds:tcb,es:bios
m16f0k:
	mov	[tcbkbcnt],0		; put off dis mode when get a key
	mov	dx,[tcbibase]
	add	dx,[tcbibsiz]
	dec	dx
	mov	si,[ikbhead]		; if head = tail, then there's no key yet
	lods	ikbbuff
	cmp	si,dx
	jb	m16f0ta			; wrap to begining on overflow
	mov	si,[tcbibase]
m16f0ta:
	mov	[ikbhead],si
	cmp	[tah],10h
	jne	m16f0tb
	cmp	al,0f0h
	jne	m16f0tx
	xor	al,al
	jmp	short m16f0tx
m16f0tb:
	call	do_exceptns
	jnz	m16f0tx
	cmp	ah,84h

;!!	lja	m16f0
	ja	m16f0_local

	cmp	al,0f0h

;!!	lje	m16f0
	je	m16f0_local

	cmp	ax,1c00h		; discard alt-enter (non-numpad enter)
;!!	lje	m16f0
	je	m16f0_local
	cmp	al,0e0h
	jne	m16f0tx
	xor	al,al
m16f0tx:
	mov	[tax],ax

;!!!	jmp	m16exit
	jmp	m16f1x

m16f0_local:
	db	0eah			; far jump opcode
m16f0l	dw	?,?

	assume	ds:nothing,es:nothing,ss:nothing
do_exceptns:
	cmp	ax,00e0h
	je	doex4
	cmp	ax,00f0h
	je	doex4
	cmp	ax,0e00dh
	jne	doex1
	mov	ax,1c0dh
	jmp	short doex4
doex1:
	cmp	ax,0e00ah
	jne	doex2
	mov	ax,1c0ah
	jmp	short doex4
doex2:
	cmp	ax,0e02fh
	jne	doex3
	mov	ax,352fh
	jmp	short doex4
doex3:
	cmp	ax,ax			; set zr flag - ax not processed
	jmp	short doex5
doex4:
	push	ax
	xor	ax,ax
	cmp	ax,1			; set nz flag - ax processed
	pop	ax
doex5:
	ret


	subttl m16f1 - return key status in z flag
	page
;======================================================================
	assume	ds:tcb,es:nothing,ss:nothing

; restore interrupts on return and default no key ready

m16f1:
	or	[tflag],interrupt or zero
	mov	ax, bios
	mov	es,ax
	assume	es:bios
	mov	si,[ikbhead]		; any keys ready?
	cmp	si,[ikbtail]
	jne	m16f1s			; yes, so return key and ready status

;!!	push	cs
;!!	call	near ptr csynch 	; physical cursor sync on each terminal
	db	9ah			; far call opcode
csynl	dw	?,?

   	test	[tcbloop],1		; is disable mode set ?
	ljz	m16f1x			; no, its not so just exit
	inc	[tcbkbcnt]		; advance disable counter
	mov	al,[tcbkbmax]
	cmp	al,[tcbkbcnt]		; maxed out yet?
	lja	m16f1x			; not yet so exit normally
	mov	ax,ss			; get tcb for timparm
	mov	es,ax
	mov	cl,4			; bit position in tcbwtflg for wrap flag
	mov	ax,[tcbkbtck]

;!!	call	timparm 		; setup time out data
	db	9ah			; far call opcode
timpl	dw	?,?

	mov	[tcbkbax],ax
	mov	[tcbkbcx],cx

;!!	mov	word ptr [tcbpoll],offset mos:kbpoll01	; looper wait
	mov	word ptr [tcbpoll],0a127h

	push	ax
	mov	ax,cs:[mos_seg]
	mov	word ptr [tcbpoll+2],ax
	pop	ax
	and	[tcbwait],not 06h	; clear bits 2,1
	or	[tcbwait],01h		; set bit 0
	or	[tcbstat],wkey		;jrb signal waiting for key

;!!	call	suspend
	db	9ah			; far call opcode
suspl	dw	?,?

	jmp	m16f1

; character is ready return status and key codes

m16f1s:
	lods	ikbbuff
	cmp	[tah],1
	je	m16f1a
	cmp	al,0f0h
	jne	m16f1w
	xor	al,al
	jmp	short m16f1w
m16f1a:
	call	do_exceptns
	jnz	m16f1w
	cmp	ax,1c00h		; discard alt-enter (non-numpad enter)
	je	m16f1b
	cmp	ah,84h
	ja	m16f1b
	cmp	al,0f0h
	jne	m16f1c
m16f1b:
	mov	dx,[tcbibase]
	add	dx,[tcbibsiz]
	dec	dx
	cmp	si,dx
	jb	m16f1d			; wrap to begining on overflow
	mov	si,[tcbibase]
m16f1d:
	mov	[ikbhead],si
	jmp	m16f1
m16f1c:
	cmp	al,0e0h
	jne	m16f1w
	xor	al,al
m16f1w:
	mov	[tax],ax		; store keycodes for restore to pop
	and	[tflag],not zero	; setup return status
m16f1x:

;!!	jmp	m16exit
	db	0eah			; far jump opcode
m16exl	dw	?,?





;-----------------------------------------------------------------------
;		scan code to key scan code translation
;-----------------------------------------------------------------------
;
;	enter:	al = scan code
;		ds -> tcb
;		es -> grp
;	exits:	dx = function
;		if dx = 0
;			ax = -1
;				ignore scan code
;			ax <> -1 and bx = -1
;				buffer ax = key code  (normal case)
;			ax <> -1 and bx <> -1
;				buffer bx, then ax (accent shift failed)
;		else dx <> 0
;			dx = 1 process a shift prtsc
;			dx = 2 process a cntrl-break
;			dx = 3 process a ctrl-alt-del
;
;	destroys	ax, bx, cx, dx, si, es, ds
;----------------------------------------------------------------------
	assume cs:code, ds:tcb
translat:
	mov	cl,al			; cl retains scan code
	mov	ch,[tcbkshft]
	mov	bx,ds
	mov	es,bx			; tcb goes to es, code in ds
	mov	bx,cs
	mov	ds,bx
	assume	ds:code,es:tcb
	mov	si,offset basetbl	; presume base table
	xor	dl,dl			; use for extended numpad flag
	test	ch,kbs_alt		; alt key highest priority.
	jz	scg020
	mov	si,offset alttbl
	jmp	short scg045
scg020:
	test	ch,kbs_ctl
	jz	scg030
	mov	si,offset ctrltbl
	jmp	short scg045
scg030:

; if the scancode is from a numeric key (or extended cursor key)
;  if extended cursor key, exit (keep base table)
;  else if numlock and shift both down or both up, exit (keep base table)
;  else use shift table

	cmp	al,numpad_lo
	jnae	scg040
	cmp	al,numpad_hi
	jnbe	scg040
	cmp	[tcblscan],0e0h
	je	scg045
	test	ch,kbs_num
	jz	scg032
	test	ch,kbs_shf
	jnz	scg045
scg032:
	test	ch,kbs_num
	jnz	scg034
	test	ch,kbs_shf
	jz	scg045
scg034:
	mov	si,offset shfttbl
	jmp	short scg045
scg040:
	test	ch,kbs_shf
	jz	scg045
	mov	si,offset shfttbl
scg045:

; si -> correct key table
; al, cl = scan code
; ch = shift state

	mov	dl,[tcblscan]
	mov	[tcblscan],cl
	mov	bx,-1			; initialize auxiliary return
	cmp	al,0e0h
	je	scg080
	cmp	al,0e1h
	je	scg080
	and	al,7fh
	add	al,al			; get index into table
	xor	ah,ah
	add	si,ax			; table + 2 * scan
	mov	ax,[si]			; get translated code from table
	mov	bx,ax			; setup for special function here
	cmp	dl,0e0h
	jne	scg045d			; if last scancode == e0
	cmp	ax,35f0h		; and if alt-slash (alt-pad-/)
	jne	scg045e
	mov	ax,0a400h		; xlate to a400
	jmp	short scg045a
scg045e:
	cmp	ax,1c0dh
	je	scg045c			; if pad-enter, or
	cmp	ax,1c0ah
	je	scg045c			; if pad-cntrl-enter, or
	cmp	ax,352fh
	jne	scg045b			; if pad-slash
scg045c:
	mov	ah,0e0h			; set high byte to e0
	jmp	short scg045a
scg045b:
	cmp	ax,0a600h
	je	scg045a			; else, if not alt-pad-enter
	cmp	ax,9500h		; and not cntrl-numpad-slash
	je	scg045a
	mov	al,0e0h			; set low byte to e0
	jmp	short scg045a
scg045d:
	cmp	ax,0a600h		; if e0 wasn't last scancode
	jne	scg045a			; and table word is a600 (alt-enter)
	mov	ax,1c00h		; convert to non-pad version
scg045a:
	mov	[tcblscan],cl
	xor	dx,dx			; initialize function return
	cmp	ah,0
	jne	scg060
	add	bx,bx			; use data from table before e0 mod
	call	cs:[keyvct+bx]		; call special function
scg060:

; dx = function code from special routine
; ax = key code from table or special routine
;	= -1  for nulls
;	al = 0	 for function keys
;	ah > 128 for accent shift
;	cl = scan code (special routine may have manipulated)

	mov	bx,-1			; initialize auxiliary return
	test	cl,80h
	jnz	scg080			; if break of a key
	cmp	ax,-1
	je	scg110
	cmp	al,0
	jne	scg070
	jmp	short scg110
scg070:
	test	ch,kbs_cap
	jz	scg075
	call	caseshft		; toggle case of character
scg075:
	jmp	short scg110
scg080:
	and	[tcbkbctl],not (kbc_e0 or kbc_e1)
	cmp	cl,0e0h
	jne	scg090
	or	[tcbkbctl],kbc_e0	; set prefix flag
	jmp	short scg100
scg090:
	cmp	cl,0e1h
	jne	scg100
	or	[tcbkbctl],kbc_e1	; set prefix flag
scg100:
	mov	ax,-1			; return without a key
	jmp	short scg120
scg110:
	and	[tcbkbctl],not (kbc_e0 or kbc_e1)
scg120:
	retf


; in: 	al = char to case shift
;
; out:	if zr al = case shifted character
;	if nz lookup failed
;
; caseshft if capslock is enabled, alphabetic chars must
; be case shifted.  ascii chars are xored and foreign chars
; are found in the table.

caseshft:
	cmp	al,'z'			; test al is ascii
	ja	cashftxit
	cmp	al,'A'
	jb	cashftxit		; not ascii and not shiftable
	cmp	al,'Z'
	jbe	cashftasc		; ascii case shift
	cmp	al,'a'
	jb	cashftxit		; not ascii and not shiftable
cashftasc:
	xor	al,'a'-'A'		; case shift ascii chars
cashftxit:
	ret


@caps:
	mov	al,kbs_cap
	jmp	toggle
@num:
	mov	al,kbs_num
	jmp	toggle
@scroll:
	mov	al,kbs_scrl

; toggle handles toggle states (scroll, numlock, caplock)
; sets/resets tggl bit.  if first make toggles shft bit.
;
; enter: al = bit to set / reset

toggle:
	or	cl,cl			; test break / make
	js	togglclr
	test	[tcbktggl],al		; test first make
	jnz	togglxit		; no just exit
	or	[tcbktggl],al
	xor	[tcbkshft],al		; set tggl bit / flip shft bit
	mov	al,[tcbkshft]
	push	ds
	mov	ds,[sbios]
	assume	ds:bios
	mov	[ikbstat],al		; update tcb on change to shift state
	pop	ds
	assume	ds:code
	jmp	short togglxit
togglclr:
	not	al			; clear toggle bit
	and	[tcbktggl],al
togglxit:
	mov	ax,-1			; no key to return
	ret

; alt shift with alt num-pad capability

@alt:
	mov	al,kbs_alt
	test	[tcbkbctl],kbc_e0	; test right alt key
	jz	@altleft
	mov	al,kbc_ralt		; fake out for alt-gr
	call	control
@altleft:
	mov	al,kbs_alt
	call	shift
	or	cl,cl
	jns	@altxit			; finished if make of alt
	cmp	byte ptr [tcbaltnum+1],0
	je	@altxit			; test numbered entered during alt
	xor	ax,ax			; clear / get altnum
	xchg	ax,word ptr [tcbaltnum]
	xor	ah,ah			; flag key came from alt-numpad
	and	cl, 07fh		; reset key-break flag, so this looks normal
@altxit:
	ret

@ctrl:
	test	[tcbkbctl],kbc_e0	; test right alt key
	jz	@ctrlleft
	mov	al,kbc_rctl		; flag right control
	call	control
@ctrlleft:
	mov	al,kbs_ctl
	jmp	short shift
@lshift:
	mov	al,kbs_lshf
	jmp	short shift
@rshift:
	mov	al,kbs_rshf

; shift sets / clears bits in tcbkshft
; enter: al = bits to set on make / reset on break of key

shift:
	or	[tcbkshft],al
	or	cl,cl			; test make / break of key
	jns	shftxit
	not	al			; key break - clear bits
	and	[tcbkshft],al
shftxit:
	push	ds
	mov	ax,bios
	mov	ds,ax
	assume	ds:bios
	mov	al,[tcbkshft]
	mov	[ikbstat],al		; update bios on tcb change
	pop	ds
	assume	ds:code
	mov	ax,-1
	ret

; control sets / clears bits in tcbkbctl
; enter: al = bits to set on make / reset on break of key

control:
	or	[tcbkbctl],al
	or	cl,cl			; test make / break of key
	jns	ctrlxit
	not	al			; key break - clear bits
	and	[tcbkbctl],al
ctrlxit:
	ret

@insert:
	push	ax			; save al (could be e0)
	mov	al,kbs_ins		; toggle insert flag
	call	toggle
	pop	ax			; restore al
	cmp	al,0e0h
	je	@ins1
	xor	al,al
@ins1:
	mov	ah,52h			; setup ah
	push	cx
	and	cl,80h
	or	ah,cl			; preserve make/break state
	pop	cx
	ret

; shift prtsc key

@prtscr:
	or	cl,cl
	js	@prtsc1			; skip if releasing the key
	mov	dx,1
@prtsc1:
	mov	ax,-1
	ret

; ignore pause key

@pause:
	or	[tcbbrkfg],10h
	mov	ax,-1
	ret

; ctrl scroll-lock

@break: or	cl,cl
	js	@break1			; skip if releasing the key
	mov	dx,2
@break1:
	mov	ax,-1
	ret

; handle alt-numpad character entry
; accumulate number in tcbaltnum, if 999 entered toggle flag

@altnum:
	or	cl,cl			; key make?
	js	@altnxit
	mov	bl,cl			; lookup ascii value
	add	bl,bl			; word index
	xor	bh,bh
	mov	bl,byte ptr [shfttbl+bx]
	and	bl,15			; bx = key's value
	mov	al,10
	mul	[tcbaltnum]		; multiply old number by 10
	add	ax,bx			; add new digit
	cmp	ax,999			; alt 999 ?
	je	@altn999
	or	ah,80h			; flag alt-number seen
	mov	word ptr [tcbaltnum],ax
@altnxit:
	mov	ax,-1			; no key to return
	ret

@altn999:				; toggle alt999 and init altnum
	mov	word ptr [tcbaltnum],0
        assume  ss:tcb, ds:nothing	;bwr 9/17/90
	xor	[tcbalt999],0ffh
        assume  ds:code, ss:nothing	;bwr 9/17/90
	jmp	@altnxit

; ctrl-alt-f1 reverts to us keyboard
; ctrl-alt-f2 reverts to foreign keyboard

@uskeyb:
	or	[tcbkbctl],kbc_us
	mov	ax,-1			; revert to us keyboard
	ret

; ctrl-alt-del return reboot function

@reboot:
	mov	ax, 0a300h		; get alt-del code
	test	ch, kbs_ctl
	jz	@rebtxit
	mov	ax,-1			; else return ctrl-alt-del function
	mov	dx,3			; return reboot function
@rebtxit:
	ret


;======================================================================

; vectors into subroutines for keys which require special handling

keyvct	label	word
	dw	@caps			; 00
	dw	@num			; 01
	dw	@scroll			; 02
	dw	@alt			; 03
	dw	@ctrl			; 04
	dw	@lshift			; 05
	dw	@rshift			; 06
	dw	@insert			; 07
	dw	@prtscr			; 08
	dw	@pause			; 09
	dw	@break			; 0a
	dw	@altnum			; 0b
	dw	@reboot			; 0c
	dw	?			; 0d
	dw	?			; 0e
	dw	?			; 0f
	dw	?			; 10

comment ^==============================================================

                       format of table entries
                       =======================

normal entries
==============

the first byte is the keycode, second is the scan code to be returned
by int16fun00:

	db	074h,014h		; 14 t


extended keys have 0 as their first byte:

	db	000h,03bh		; 3b f1


special cases
=============

this entry defines a scancode which doesn't return any keycode:

	db	0ffh,0ffh		; 00


special function keys have 0 as their second byte.  the first byte is
the function number (using the keyvct table):

	db	002h,000h		; 46 scrollock


keys which were first introduced on the 101 keyboard use either a
scan code > 84h (such as f11) or have f0 as their first byte (such as
numeric pad 5).  int16fun10 and fun11 must be used to read these
scancodes.

	db	0f0h,04ch		; 4c n5

	db	000h,085h		; 57 f11


======================================================================^

basetbl label	word
					;scan code
					;=========
	db	0ffh,0ffh		; 00
	db	01bh,001h		; 01 escape
	db	031h,002h		; 02 1
	db	032h,003h		; 03 2
	db	033h,004h		; 04 3
	db	034h,005h		; 05 4
	db	035h,006h		; 06 5
	db	036h,007h		; 07 6
	db	037h,008h		; 08 7
	db	038h,009h		; 09 8
	db	039h,00ah		; 0a 9
	db	030h,00bh		; 0b 0
	db	02dh,00ch		; 0c -
	db	03dh,00dh		; 0d =
	db	008h,00eh		; 0e backspace
	db	009h,00fh		; 0f tab
	db	071h,010h		; 10 q
	db	077h,011h		; 11 w
	db	065h,012h		; 12 e
	db	072h,013h		; 13 r
	db	074h,014h		; 14 t
	db	079h,015h		; 15 y
	db	075h,016h		; 16 u
	db	069h,017h		; 17 i
	db	06fh,018h		; 18 o
	db	070h,019h		; 19 p
	db	05bh,01ah		; 1a [
	db	05dh,01bh		; 1b ]
	db	00dh,01ch		; 1c new-line
	db	004h,000h		; 1d lctrl
	db	061h,01eh		; 1e a
	db	073h,01fh		; 1f s
	db	064h,020h		; 20 d
	db	066h,021h		; 21 f
	db	067h,022h		; 22 g
	db	068h,023h		; 23 h
	db	06ah,024h		; 24 j
	db	06bh,025h		; 25 k
	db	06ch,026h		; 26 l
	db	03bh,027h		; 27
	db	027h,028h		; 28 '
	db	060h,029h		; 29 `
	db	005h,000h		; 2a lshift
	db	05ch,02bh		; 2b \
	db	07ah,02ch		; 2c z
	db	078h,02dh		; 2d x
	db	063h,02eh		; 2e c
	db	076h,02fh		; 2f v
	db	062h,030h		; 30 b
	db	06eh,031h		; 31 n
	db	06dh,032h		; 32 m
	db	02ch,033h		; 33 ,
	db	02eh,034h		; 34 .
	db	02fh,035h		; 35 /
	db	006h,000h		; 36 rshift
	db	02ah,037h		; 37 prtsc
	db	003h,000h		; 38 alt
	db	020h,039h		; 39 spacebar
	db	000h,000h		; 3a capslock
	db	000h,03bh		; 3b f1
	db	000h,03ch		; 3c f2
	db	000h,03dh		; 3d f3
	db	000h,03eh		; 3e f4
	db	000h,03fh		; 3f f5
	db	000h,040h		; 40 f6
	db	000h,041h		; 41 f7
	db	000h,042h		; 42 f8
	db	000h,043h		; 43 f9
	db	000h,044h		; 44 f10
	db	001h,000h		; 45 numlock
	db	002h,000h		; 46 scrollock
	db	000h,047h		; 47 n7 home
	db	000h,048h		; 48 n8 uparrow
	db	000h,049h		; 49 n9 pgup
	db	02dh,04ah		; 4a gray -
	db	000h,04bh		; 4b n4 larrow
	db	0f0h,04ch		; 4c n5
	db	000h,04dh		; 4d n6 rarrow
	db	02bh,04eh		; 4e gray +
	db	000h,04fh		; 4f n1 end
	db	000h,050h		; 50 n2 darrow
	db	000h,051h		; 51 n3 pgdn
	db	007h,000h		; 52 n0 insert
	db	000h,053h		; 53 n. delete
	db	0ffh,0ffh		; 54 sysreq
	db	0ffh,0ffh		; 55
	db	0ffh,0ffh		; 56
	db	000h,085h		; 57 f11
	db	000h,086h		; 58 f12

; for citoh 7102

	db	0ffh,0ffh		; 59
	db	0ffh,0ffh		; 5a
	db	0ffh,0ffh		; 5b
	db	0ffh,0ffh		; 5c
	db	000h,051h		; 5d pgdn
	db	007h,000h		; 5e
	db	000h,053h		; 5f
	db	00dh,060h		; 60 return
	db	000h,047h		; 61 home
	db	000h,048h		; 62
	db	000h,049h		; 63 pgup
	db	000h,04bh		; 64 left
	db	000h,04dh		; 65 right
	db	000h,04fh		; 66 end
	db	000h,050h		; 67
	db	0a0h,07fh		; 68 pf1 - pf24
	db	0a1h,07fh		; 69
	db	0a2h,07fh		; 6a
	db	0a3h,07fh		; 6b
	db	0a4h,07fh		; 6c
	db	0a5h,07fh		; 6d
	db	0a6h,07fh		; 6e
	db	0a7h,07fh		; 6f
	db	0a8h,07fh		; 70
	db	0a9h,07fh		; 71
	db	0aah,07fh		; 72
	db	0abh,07fh		; 73
	db	0ach,07fh		; 74
	db	0adh,07fh		; 75
	db	0aeh,07fh		; 76
	db	0afh,07fh		; 77
	db	0b0h,07fh		; 78
	db	0b1h,07fh		; 79
	db	0b2h,07fh		; 7a
	db	0b3h,07fh		; 7b
	db	0b4h,07fh		; 7c
	db	0b5h,07fh		; 7d
	db	0b6h,07fh		; 7e
	db	0b7h,07fh		; 7f

;======================================================================

	subttl	shift case keyboard scan code translation table
	page

shfttbl label	word
					;scan code
					;=========
	db	0ffh,0ffh		; 00
	db	01bh,001h		; 01 escape
	db	021h,002h		; 02 1
	db	040h,003h		; 03 2
	db	023h,004h		; 04 3
	db	024h,005h		; 05 4
	db	025h,006h		; 06 5
	db	05eh,007h		; 07 6
	db	026h,008h		; 08 7
	db	02ah,009h		; 09 8
	db	028h,00ah		; 0a 9
	db	029h,00bh		; 0b 0
	db	05fh,00ch		; 0c -
	db	02bh,00dh		; 0d =
	db	008h,00eh		; 0e backspace
	db	000h,00fh		; 0f tab
	db	051h,010h		; 10 q
	db	057h,011h		; 11 w
	db	045h,012h		; 12 e
	db	052h,013h		; 13 r
	db	054h,014h		; 14 t
	db	059h,015h		; 15 y
	db	055h,016h		; 16 u
	db	049h,017h		; 17 i
	db	04fh,018h		; 18 o
	db	050h,019h		; 19 p
	db	07bh,01ah		; 1a [
	db	07dh,01bh		; 1b ]
	db	00dh,01ch		; 1c new-line
	db	004h,000h		; 1d lctrl
	db	041h,01eh		; 1e a
	db	053h,01fh		; 1f s
	db	044h,020h		; 20 d
	db	046h,021h		; 21 f
	db	047h,022h		; 22 g
	db	048h,023h		; 23 h
	db	04ah,024h		; 24 j
	db	04bh,025h		; 25 k
	db	04ch,026h		; 26 l
	db	03ah,027h		; 27
	db	022h,028h		; 28 '
	db	07eh,029h		; 29 `
	db	005h,000h		; 2a lshift
	db	07ch,02bh		; 2b \
	db	05ah,02ch		; 2c z
	db	058h,02dh		; 2d x
	db	043h,02eh		; 2e c
	db	056h,02fh		; 2f v
	db	042h,030h		; 30 b
	db	04eh,031h		; 31 n
	db	04dh,032h		; 32 m
	db	03ch,033h		; 33 ,
	db	03eh,034h		; 34 .
	db	03fh,035h		; 35 /
	db	006h,000h		; 36 rshift
	db	008h,000h		; 37 prtsc
	db	003h,000h		; 38 alt
	db	020h,039h		; 39 spacebar
	db	000h,000h		; 3a capslock
	db	000h,054h		; 3b f1
	db	000h,055h		; 3c f2
	db	000h,056h		; 3d f3
	db	000h,057h		; 3e f4
	db	000h,058h		; 3f f5
	db	000h,059h		; 40 f6
	db	000h,05ah		; 41 f7
	db	000h,05bh		; 42 f8
	db	000h,05ch		; 43 f9
	db	000h,05dh		; 44 f10
	db	001h,000h		; 45 numlock
	db	0ffh,0ffh		; 46 scrollock
	db	037h,047h		; 47 n7 home
	db	038h,048h		; 48 n8 uparrow
	db	039h,049h		; 49 n9 pgup
	db	02dh,04ah		; 4a gray -
	db	034h,04bh		; 4b n4 larrow
	db	035h,04ch		; 4c n5
	db	036h,04dh		; 4d n6 rarrow
	db	02bh,04eh		; 4e gray +
	db	031h,04fh		; 4f n1 end
	db	032h,050h		; 50 n2 darrow
	db	033h,051h		; 51 n3 pgdn
	db	030h,052h		; 52 n0 insert
	db	02eh,053h		; 53 n. delete
	db	0ffh,0ffh		; 54 sysreq
	db	0ffh,0ffh		; 55
	db	0ffh,0ffh		; 56
	db	000h,087h		; 57 f11
	db	000h,088h		; 58 f12

; for citoh 7102

	db	0ffh,0ffh		; 59
	db	0ffh,0ffh		; 5a
	db	0ffh,0ffh		; 5b
	db	0ffh,0ffh		; 5c
	db	000h,051h		; 5d pgdn
	db	007h,000h		; 5e
	db	000h,053h		; 5f
	db	00dh,060h		; 60 return
	db	000h,047h		; 61 home
	db	000h,048h		; 62
	db	000h,049h		; 63 pgup
	db	000h,04bh		; 64 left
	db	000h,04dh		; 65 right
	db	000h,04fh		; 66 end
	db	000h,050h		; 67
	db	0a0h,07fh		; 68 pf1 - pf24
	db	0a1h,07fh		; 69
	db	0a2h,07fh		; 6a
	db	0a3h,07fh		; 6b
	db	0a4h,07fh		; 6c
	db	0a5h,07fh		; 6d
	db	0a6h,07fh		; 6e
	db	0a7h,07fh		; 6f
	db	0a8h,07fh		; 70
	db	0a9h,07fh		; 71
	db	0aah,07fh		; 72
	db	0abh,07fh		; 73
	db	0ach,07fh		; 74
	db	0adh,07fh		; 75
	db	0aeh,07fh		; 76
	db	0afh,07fh		; 77
	db	0b0h,07fh		; 78
	db	0b1h,07fh		; 79
	db	0b2h,07fh		; 7a
	db	0b3h,07fh		; 7b
	db	0b4h,07fh		; 7c
	db	0b5h,07fh		; 7d
	db	0b6h,07fh		; 7e
	db	0b7h,07fh		; 7f

;======================================================================

	subttl	ctrl case of keyboard scan code translation table
	page
public ctrltbl

ctrltbl label	word
	scan = 0
					;scan code
					;=========
	db	0ffh,0ffh		; 00
	db	01bh,001h		; 01 escape
	db	0ffh,0ffh		; 02 1
	db	000h,003h		; 03 2
	db	0ffh,0ffh		; 04 3
	db	0ffh,0ffh		; 05 4
	db	0ffh,0ffh		; 06 5
	db	01eh,007h		; 07 6
	db	0ffh,0ffh		; 08 7
	db	0ffh,0ffh		; 09 8
	db	0ffh,0ffh		; 0a 9
	db	0ffh,0ffh		; 0b 0
	db	01fh,00ch		; 0c -
	db	0ffh,0ffh		; 0d =
	db	07fh,00eh		; 0e backspace
	db	000h,094h		; 0f tab
	db	011h,010h		; 10 q
	db	017h,011h		; 11 w
	db	005h,012h		; 12 e
	db	012h,013h		; 13 r
	db	014h,014h		; 14 t
	db	019h,015h		; 15 y
	db	015h,016h		; 16 u
	db	009h,017h		; 17 i
	db	00fh,018h		; 18 o
	db	010h,019h		; 19 p
	db	01bh,01ah		; 1a [
	db	01dh,01bh		; 1b ]
	db	00ah,01ch		; 1c new-line
	db	004h,000h		; 1d lctrl
	db	001h,01eh		; 1e a
	db	013h,01fh		; 1f s
	db	004h,020h		; 20 d
	db	006h,021h		; 21 f
	db	007h,022h		; 22 g
	db	008h,023h		; 23 h
	db	00ah,024h		; 24 j
	db	00bh,025h		; 25 k
	db	00ch,026h		; 26 l
	db	0ffh,0ffh		; 27
	db	0ffh,0ffh		; 28 '
	db	0ffh,0ffh		; 29 `
	db	005h,000h		; 2a lshift
	db	01ch,02bh		; 2b \
	db	01ah,02ch		; 2c z
	db	018h,02dh		; 2d x
	db	003h,02eh		; 2e c
	db	016h,02fh		; 2f v
	db	002h,030h		; 30 b
	db	00eh,031h		; 31 n
	db	00dh,032h		; 32 m
	db	0ffh,0ffh		; 33 ,
	db	0ffh,0ffh		; 34 .
	db	000h,095h		; 35 /
	db	006h,000h		; 36 rshift
	db	000h,096h		; 37 prtsc
	db	003h,000h		; 38 alt
	db	020h,039h		; 39 spacebar
	db	000h,000h		; 3a capslock
	db	000h,05eh		; 3b f1
	db	000h,05fh		; 3c f2
	db	000h,060h		; 3d f3
	db	000h,061h		; 3e f4
	db	000h,062h		; 3f f5
	db	000h,063h		; 40 f6
	db	000h,064h		; 41 f7
	db	000h,065h		; 42 f8
	db	000h,066h		; 43 f9
	db	000h,067h		; 44 f10
	db	009h,000h		; 45 numlock
	db	00ah,000h		; 46 scrollock
	db	000h,077h		; 47 n7 home
	db	000h,08dh		; 48 n8 uparrow
	db	000h,084h		; 49 n9 pgup
	db	000h,08eh		; 4a gray -
	db	000h,073h		; 4b n4 larrow
	db	000h,08fh		; 4c n5
	db	000h,074h		; 4d n6 rarrow
	db	000h,090h		; 4e gray +
	db	000h,075h		; 4f n1 end
	db	000h,091h		; 50 n2 darrow
	db	000h,076h		; 51 n3 pgdn
	db	000h,092h		; 52 n0 insert
	db	000h,093h		; 53 n. delete
	db	0ffh,0ffh		; 54 sysreq
	db	0ffh,0ffh		; 55
	db	0ffh,0ffh		; 56
	db	000h,089h		; 57 f11
	db	000h,08ah		; 58 f12

; for citoh 7102

	db	0ffh,0ffh		; 59
	db	0ffh,0ffh		; 5a
	db	0ffh,0ffh		; 5b
	db	0ffh,0ffh		; 5c
	db	000h,076h		; 5d pgdn
	db	0ffh,0ffh		; 5e
	db	0ffh,0ffh		; 5f
	db	00ah,060h		; 60 return
	db	000h,077h		; 61 home
	db	0ffh,0ffh		; 62
	db	000h,084h		; 63 pgup
	db	000h,073h		; 64 left
	db	000h,074h		; 65 right
	db	000h,075h		; 66 end
	db	0ffh,0ffh		; 67
	db	0d0h,07fh		; 68 pf1 - pf24
	db	0d1h,07fh		; 69
	db	0d2h,07fh		; 6a
	db	0d3h,07fh		; 6b
	db	0d4h,07fh		; 6c
	db	0d5h,07fh		; 6d
	db	0d6h,07fh		; 6e
	db	0d7h,07fh		; 6f
	db	0d8h,07fh		; 70
	db	0d9h,07fh		; 71
	db	0dah,07fh		; 72
	db	0dbh,07fh		; 73
	db	0dch,07fh		; 74
	db	0ddh,07fh		; 75
	db	0deh,07fh		; 76
	db	0dfh,07fh		; 77
	db	0e0h,07fh		; 78
	db	0e1h,07fh		; 79
	db	0e2h,07fh		; 7a
	db	0e3h,07fh		; 7b
	db	0e4h,07fh		; 7c
	db	0e5h,07fh		; 7d
	db	0e6h,07fh		; 7e
	db	0e7h,07fh		; 7f


;======================================================================

	subttl	alt case of keyboard scan code translation table
	page
public alttbl

alttbl	label	word
	scan = 0
					;scan code
					;=========
	db	0ffh,0ffh		; 00
	db	0f0h,001h		; 01 escape
	db	000h,078h		; 02 1
	db	000h,079h		; 03 2
	db	000h,07ah		; 04 3
	db	000h,07bh		; 05 4
	db	000h,07ch		; 06 5
	db	000h,07dh		; 07 6
	db	000h,07eh		; 08 7
	db	000h,07fh		; 09 8
	db	000h,080h		; 0a 9
	db	000h,081h		; 0b 0
	db	000h,082h		; 0c -
	db	000h,083h		; 0d =
	db	0f0h,00eh		; 0e backspace
	db	000h,0a5h		; 0f tab
	db	000h,010h		; 10 q
	db	000h,011h		; 11 w
	db	000h,012h		; 12 e
	db	000h,013h		; 13 r
	db	000h,014h		; 14 t
	db	000h,015h		; 15 y
	db	000h,016h		; 16 u
	db	000h,017h		; 17 i
	db	000h,018h		; 18 o
	db	000h,019h		; 19 p
	db	0f0h,01ah		; 1a [
	db	0f0h,01bh		; 1b ]
	db	000h,0a6h		; 1c new-line
	db	004h,000h		; 1d lctrl
	db	000h,01eh		; 1e a
	db	000h,01fh		; 1f s
	db	000h,020h		; 20 d
	db	000h,021h		; 21 f
	db	000h,022h		; 22 g
	db	000h,023h		; 23 h
	db	000h,024h		; 24 j
	db	000h,025h		; 25 k
	db	000h,026h		; 26 l
	db	0f0h,027h		; 27
	db	0f0h,028h		; 28 '
	db	0f0h,029h		; 29 `
	db	005h,000h		; 2a lshift
	db	0f0h,02bh		; 2b \
	db	000h,02ch		; 2c z
	db	000h,02dh		; 2d x
	db	000h,02eh		; 2e c
	db	000h,02fh		; 2f v
	db	000h,030h		; 30 b
	db	000h,031h		; 31 n
	db	000h,032h		; 32 m
	db	0f0h,033h		; 33 ,
	db	0f0h,034h		; 34 .
	db	0f0h,035h		; 35 /
	db	006h,000h		; 36 rshift
	db	0f0h,037h		; 37 prtsc
	db	003h,000h		; 38 alt
	db	020h,039h		; 39 spacebar
	db	000h,000h		; 3a capslock
	db	000h,068h		; 3b f1
	db	000h,069h		; 3c f2
	db	000h,06ah		; 3d f3
	db	000h,06bh		; 3e f4
	db	000h,06ch		; 3f f5
	db	000h,06dh		; 40 f6
	db	000h,06eh		; 41 f7
	db	000h,06fh		; 42 f8
	db	000h,070h		; 43 f9
	db	000h,071h		; 44 f10
	db	009h,000h		; 45 numlock
	db	00ah,000h		; 46 scrollock
	db	00bh,000h		; 47 n7 home
	db	00bh,000h		; 48 n8 uparrow
	db	00bh,000h		; 49 n9 pgup
	db	0f0h,04ah		; 4a gray -
	db	00bh,000h		; 4b n4 larrow
	db	00bh,000h		; 4c n5
	db	00bh,000h		; 4d n6 rarrow
	db	0f0h,04eh		; 4e gray +
	db	00bh,000h		; 4f n1 end
	db	00bh,000h		; 50 n2 darrow
	db	00bh,000h		; 51 n3 pgdn
	db	00bh,000h		; 52 n0 insert
	db	00ch,000h		; 53 n. delete
	db	0ffh,0ffh		; 54 sysreq
	db	0ffh,0ffh		; 55
	db	0ffh,0ffh		; 56
	db	000h,08bh		; 57 f11
	db	000h,08ch		; 58 f12

; for citoh 7102

	db	0ffh,0ffh		; 59
	db	0ffh,0ffh		; 5a
	db	0ffh,0ffh		; 5b
	db	0ffh,0ffh		; 5c
	db	000h,076h		; 5d pgdn
	db	0ffh,0ffh		; 5e
	db	0ffh,0ffh		; 5f
	db	00ah,060h		; 60 return
	db	000h,077h		; 61 home
	db	0ffh,0ffh		; 62
	db	000h,084h		; 63 pgup
	db	000h,073h		; 64 left
	db	000h,074h		; 65 right
	db	000h,075h		; 66 end
	db	0ffh,0ffh		; 67
	db	0e8h,07fh		; 68 pf1 - pf24
	db	0e9h,07fh		; 69
	db	0eah,07fh		; 6a
	db	0ebh,07fh		; 6b
	db	0ech,07fh		; 6c
	db	0edh,07fh		; 6d
	db	0eeh,07fh		; 6e
	db	0efh,07fh		; 6f
	db	0f0h,07fh		; 70
	db	0f1h,07fh		; 71
	db	0f2h,07fh		; 72
	db	0f3h,07fh		; 73
	db	0f4h,07fh		; 74
	db	0f5h,07fh		; 75
	db	0f6h,07fh		; 76
	db	0f7h,07fh		; 77
	db	0f8h,07fh		; 78
	db	0f9h,07fh		; 79
	db	0fah,07fh		; 7a
	db	0fbh,07fh		; 7b
	db	0fch,07fh		; 7c
	db	0fdh,07fh		; 7d
	db	0feh,07fh		; 7e
	db	0ffh,07fh		; 7f

;======================================================================
;   patch code for int 21h function 67h fix - version 1.01
;======================================================================


fixfun67  proc	far
	assume  ds:scbx,es:nothing,ss:tcb
	cmp	[tcbversn],1403h	; if dos 3.2 skip it
	jne	dofun67
	or	[tflag], carry
	mov	[tax],1

; far jump back to int 21h function 67h code

	db	0eah			; farjump
jmp67a	dw	?,?			; 5d72h

dofun67:

; if psp handle pointer is not in psp segment, we must deallocate
; if the system is not the same as requested

	mov	ax,[tcbpsp]
	mov	ds,ax
	assume	ds:pspseg
	cmp	word ptr [psppntr+2],ax
	je	cont67			; not allocated so skip
	mov	ax,[tbx]		; get handle count
	cmp	ax,[psphdls]		; is it same as current
	jne	cont67a

; far jump to int 21h function 67h code

	db	0eah			; far jump
jmp67b	dw	?,?			; 5d6e


cont67a:

; we must copy current contents of first 20 handles to psp handle table

	push	ds
	pop	es
	mov	ds,word ptr [psppntr+2]
	xor	si,si
	mov	di,18h
	mov	cx,20/2
	rep	movsw

; we must free current pointer and reset it to current psp
; please note doing this hear handle both resizing of larger than
; 20 table and going back to a 20 handle table

	mov	ds,[tcbpsp]
	mov	es,word ptr [psppntr+2]
	mov	ah,49h
;!!	call	sim21
	db	9ah			; far call opcode
sim21l	dw	?,?

	mov	word ptr [psppntr], 18h
	mov	word ptr [psppntr + 2], es
	mov	[psphdls],20

cont67:

	cmp	word ptr [tbx], 20	;assigning < 20?

; far jump back to int 21h function 67 code

	db	0eah			; far jump
jmp67c	dw	?,?			; 5d6c

fixfun67 endp


;======================================================================
;   patch code for mosint13 normalize fix - version 1.02/1.03
;======================================================================

dma13ax	equ	650h
dma13cx	equ	654h
dma13dx	equ	656h
dma13es	equ	658h
dmascnt	equ	64fh
oint13	equ	2030h

maxhead	db	0
maxsect	dw	0

	assume	ds:nothing,es:nothing,ss:nothing

; at mos:13a4, code a far jump to 13a  (at the label xyes)

i13a:

; get disk parameters for the drive, setting them into maxhead and maxsect
; these will be used by the normalize function.

	push	cx
	push	di
	mov	dx,ds:[dma13dx]		; need dl = drive #
	cmp	dl,80h
	jb	m13a
	mov	ah,8
	pushf
	call	dword ptr ds:[oint13]
	mov	cs:[maxhead],dh
	mov	bl,cl
	and	bl,03fh			; max sct # in bx (1 based)
	xor	bh,bh
	mov	cs:[maxsect],bx
m13a:
	pop	di
	pop	cx

; patch recovery instructions

	mov	ax,ds:[dma13ax]
	cmp	al,cl

	db	0eah			; far jump opcode
jmp13a	dw	?,?			; mos:13a9


;=======

; at mos:13cd, code a far jump to 13b

i13b:
	add	ds:[dmascnt],al		; restoration instruction
	call	normalize

	db	0eah			; far jump opcode
jmp13b	dw	?,?			; mos:13d5


;=======

; at mos:1431, code a far jump to 13c

i13c:
	add	ds:[dmascnt],al		; restoration instruction
	call	normalize

	db	0eah			; far jump opcode
jmp13c	dw	?,?			; mos:1439


;=======

; at mos:1492, code a far jump to 13d

i13d:

; patch recovery instructions

	mov	es,ds:[dma13es]
	pop	ds

; new instruction

	clc

	db	0eah			; far jump opcode
jmp13d	dw	?,?			; mos:14b1



comment ^==============================================================
.fs
; normalize - adjust int13 parameters
;
; in:	al = # of sectors to add to the starting sector
;	ds -> grp
;	[dma13cx]
;	[dma13dx]
;
; out:	[dma13cx] and [dma13dx] adjusted
;	crashes ax,cx and dx
;
; calls:
; reads:
; writes:
;
.fe
;=====================================================================^
	assume	ds:nothing,es:nothing,ss:nothing
normalize:
	cmp	byte ptr ds:[dma13dx],80h
	jae	normfd
	add	byte ptr ds:[dma13cx],al
	ret
normfd:
	mov	dl,byte ptr ds:[dma13cx]; calc new starting sector number
	and	dx,03fh			; in ax
	xor	ah,ah
	add	ax,dx
	mov	ch,byte ptr ds:[dma13cx]; caller's cl to ch
	mov	cl,6			; bring upper cyl bits over
	shr	ch,cl
	mov	cl,byte ptr ds:[dma13cx+1]  ; cx is now cylnder number
	mov	dh,cs:[maxhead]
i13comp1:
	cmp	ax,cs:[maxsect]		; if starting sector (al) > spt
	jna	i13comp2
	sub	ax,cs:[maxsect]		; adjust sector # downwards
	inc	byte ptr ds:[dma13dx+1]	; increment head # in dh
	cmp	byte ptr ds:[dma13dx+1],dh  ; if request head (dh) > max head
	jna	i13comp1
	mov	byte ptr ds:[dma13dx+1],0  ; wrap head #
	inc	cx			; and increment cyl #
	jmp	short i13comp1
i13comp2:
	mov	byte ptr ds:[dma13cx+1],cl
	mov	cl,6
	shl	ch,cl
	or	al,ch
	mov	byte ptr ds:[dma13cx],al
	ret


;======================================================================

	subttl	initialization
	page

end_res	label	byte
	nop

instmsg		db	13,10,'Patch410.sys driver installed, version 1.03           ',13,10,'$'  ;@@xlat
notmosmsg	db	13,10,'Patch410.sys must only be used with PC-MOS version 4.10                 ',13,10,'$'  ;@@xlat
notmos410	db	13,10,'Patch410.sys detects mismatched kernel code           ',13,10,'$'  ;@@xlat
notsmpmsg	db	13,10,'Patch410.sys must be loaded globally                ',13,10,'$'  ;@@xlat

m16f0k_ofs	equ	09fe6h
m16f0_ofs	equ	09f9bh
m16exit_ofs	equ	09f94h
m16f1_ofs	equ	0a03dh
timparm_ofs	equ	0c675h
xtimparm_ofs	equ	m16f0k_ofs+5
suspend_ofs	equ	0ca3eh
xsuspend_ofs	equ	xtimparm_ofs+8
csynch_ofs	equ	09ebch

; equates use by function 67 fix
; note that this code puts a near call shell into old int 16 code

xsim21_ofs	equ	xsuspend_ofs+8
sim21_ofs	equ	05e08h
xfun67_ofs	equ	05d68h
xfun67a_ofs	equ	05d72h
xfun67b_ofs	equ	05d6eh
xfun67c_ofs	equ	05d6ch


chk16	dw	m16f0k_ofs		; offset within segment
	db	5			; # of bytes in list
	db	0c6h,006h,0feh,000h,000h; the list

chk67	dw	xfun67_ofs		; offset within segment
	db	6			; # of bytes in list
	db	083h,07eh,012h,014h,077h,006h  ; the list

chk13	dw	013a4h			; offset within segment
	db	5			; # of bytes in list
	db	0a1h,050h,006h,03ah,0c1h; the list


	subttl chk_code - verify code match in kernel
	page
comment ^==============================================================
.fs
; chk_code - verify code match in kernel
;
; verify that a certain section of the kernel contains the expected
; binary code by comparing with a local reference string.  the format
; for the local reference string is:
;
;	dw	x		; offset within segment
;	db	x		; # of bytes in list
;	db	x,x,x...	; the list
; 
; in:	ax = kernel segment to check
;	si = offset of list
;
; out:	zr if match, else nz
;	all other regs preserved
;
;
; .calls:
; .reads:
; .writes:
;
.fe
;=====================================================================^
	assume	ds:nothing,es:nothing,ss:nothing
chk_code:
	pushset	cx,si,di,ds,es
	cld
	mov	es,ax
	mov	cx,cs
	mov	ds,cx			; need ds:si -> reference string
	mov	di,[si]
	mov	cl,[si+2]		; need cx = # of bytes
	xor	ch,ch
	add	si,3
	rep	cmpsb			; return with zr or nz flags
	popset	cx,si,di,ds,es
	ret


	subttl install16 - install int 16 fix for 4.10
	page
comment ^==============================================================
.fs
; install16 - install int 16 fix for 4.10
;
; install int 16 fix
;
; in:	ax -> mos segment
;
; out:	ax -> mos segment
;
; calls:
; reads:
; writes:
;
.fe
;=====================================================================^
	assume	ds:nothing,es:nothing,ss:nothing

install16 proc	near
	push	ax

; setup far jump to m16exit from local code

	mov	[m16exl],m16exit_ofs
	mov	[m16exl+2],ax

; setup far jump to m16f0 from local code

	mov	[m16f0l],m16f0_ofs
	mov	[m16f0l+2],ax

; setup far call to timparm calling shell from local code

	mov	[timpl],xtimparm_ofs
	mov	[timpl+2],ax

; setup far call to suspend calling shell from local code

	mov	[suspl],xsuspend_ofs
	mov	[suspl+2],ax

; setup far call to csynch

	mov	[csynl],csynch_ofs
	mov	[csynl+2],ax

; patch timparm calling shell into old mosint16 code

	push	es
	cli
	mov	es,ax
	cld
	mov	di,xtimparm_ofs		; location for calling shell
	mov	al,2eh			; cs: override
	stosb
	mov	al,0ffh			; mem call opcode
	stosb
	mov	al,16h			; mod011r/m
	stosb
	mov	ax,di
	add	ax,3			; address of location holding address
	stosw
	mov	al,0cbh			; retf opcode
	stosb
	mov	ax,timparm_ofs		; offset of real timparm function
	stosw

; patch suspend calling shell into old mosint16 code

	mov	di,xsuspend_ofs		; location for calling shell
	mov	al,2eh			; cs: override
	stosb
	mov	al,0ffh			; mem call opcode
	stosb
	mov	al,16h			; mod011r/m
	stosb
	mov	ax,di
	add	ax,3			; address of location holding address
	stosw
	mov	al,0cbh			; retf opcode
	stosb
	mov	ax,suspend_ofs		; offset of real timparm function
	stosw

; patch kernel to use new m16f0k

	mov	di,m16f0k_ofs
	mov	al,0eah			; far jump opcode
	stosb
	mov	ax,offset m16f0k
	stosw
	mov	ax,cs
	stosw

; patch kernel to use new m16f1

	mov	di,m16f1_ofs
	mov	al,0eah			; far jump opcode
	stosb
	mov	ax,offset m16f1
       	stosw
	mov	ax,cs
	stosw

; recover es -> scb and install our vector into scbscang

	pop	es
	mov	word ptr es:[bx+scbscang],offset translat
	mov	word ptr es:[bx+scbscang+2],cs
	sti
	pop	ax
	ret
install16 endp


	subttl install67 - install int 21h fun 67 fix for 4.10
	page
comment ^==============================================================
.fs
; install67 - install int 21h fun 67 fix for 4.10
;
; install int 21h function 67h fix
;
; in:	ax -> mos segment
;
; out:	ax -> mos segment
;
; calls:
; reads:
; writes:
;
.fe
;=====================================================================^
	assume	ds:nothing,es:nothing,ss:nothing

install67 proc	near
	push	ax

; patch sim21 calling shell into patch 67 code

	mov	[sim21l],xsim21_ofs
	mov	[sim21l+2],ax

; patch jump locations back to kernel old mosfun67 codes

	mov	[jmp67a],xfun67a_ofs
	mov	[jmp67a+2],ax
	mov	[jmp67b],xfun67b_ofs
	mov	[jmp67b+2],ax
	mov	[jmp67c],xfun67c_ofs
	mov	[jmp67c+2],ax

; patch sim21 calling shell in old mosint16 code

	push	es
	mov	es,ax
	cld
	mov	di,xsim21_ofs		; location for calling shell
	mov	al,2eh			; cs: override
	stosb
	mov	al,0ffh			; mem call opcode
	stosb
	mov	al,16h			; mod011r/m
	stosb
	mov	ax,di
	add	ax,3			; address of location holding address
	stosw
	mov	al,0cbh			; retf opcode
	stosb
	mov	ax,sim21_ofs		; offset of real sim21 function
	stosw

; patch kernel code to far jump to our patch area

	mov	di,xfun67_ofs		; location of mosfun67
	mov	al,0eah			; far jump opcode
	stosb
	mov	ax,offset fixfun67	; get offset to our code
	stosw
	mov	ax,cs			; get our code segment
	stosw
	pop	es

	pop	ax
	ret
install67 endp

	subttl install13 - install int 13 fix for 4.10
	page
comment ^==============================================================
.fs
; install13 - install int 13 fix for 4.10
;
; install int 13 fix
;
; in:	ax -> mos segment
;
; out:	ax -> mos segment
;
; calls:
; reads:
; writes:
;
.fe
;=====================================================================^
	assume	ds:nothing,es:nothing,ss:nothing

install13 proc	near
	push	ax

; setup far jumps back to kernel

	mov	[jmp13a],13a9h
	mov	[jmp13a+2],ax

	mov	[jmp13b],13d5h
	mov	[jmp13b+2],ax

	mov	[jmp13c],1439h
	mov	[jmp13c+2],ax

	mov	[jmp13d],14b1h
	mov	[jmp13d+2],ax

; patch kernel to use code at i13p1, i13p2 and i13p3

	push	es
	cli
	mov	es,ax
	cld
	mov	di,13a4h
	mov	al,0eah			; far jump opcode
	stosb
	mov	ax,offset i13a
       	stosw
	mov	ax,cs
	stosw

	mov	di,13cdh
	mov	al,0eah			; far jump opcode
	stosb
	mov	ax,offset i13b
       	stosw
	mov	ax,cs
	stosw

	mov	di,1431h
	mov	al,0eah			; far jump opcode
	stosb
	mov	ax,offset i13c
       	stosw
	mov	ax,cs
	stosw

	mov	di,1492h
	mov	al,0eah			; far jump opcode
	stosb
	mov	ax,offset i13d
       	stosw
	mov	ax,cs
	stosw
	sti
	pop	es
	pop	ax
	ret
install13 endp


	subttl ismos - test for mos
	page
comment ^==============================================================
.fs
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
; calls:
; reads:
; writes:
;
.fe
;=====================================================================^
	assume	ds:nothing,es:nothing,ss:nothing
ismos:
	pushset	ax,bx,cx,dx
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


	subttl init - initialize this device driver
	page
comment ^==============================================================
.fs
; init - initialize this device driver
;
; verify mos is the os, then dynamically patch the kernel
;
; in:	none
;
; out:	none
;
; calls:
; reads:
; writes:
;
.fe
;=====================================================================^
	assume	ds:nothing,es:nothing,ss:nothing
init:
	pushset	ax,bx,cx,dx,si,di,bp,ds,es
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

; use es->scb right now to fetch the mos segment

	mov	ax,es:[bx+scbmosadr]
	mov	[mos_seg],ax

; check to see if code is correct

	mov	si,offset chk16
	call	chk_code
	jnz	badcode
	mov	si,offset chk67
	call	chk_code
	jnz	badcode
	mov	si,offset chk13
	call	chk_code
	jnz	badcode
	jmp	short goodcode
badcode:
	mov	dx,offset notmos410
	xor	cx,cx
	jmp	initx
goodcode:

; install the patches

	call	install16		; int16      (ver 1.00)
	call	install67		; int21fun67 (ver 1.01)
	call	install13		; int13      (ver 1.02/1.03)

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

code	ends
	end	begin

