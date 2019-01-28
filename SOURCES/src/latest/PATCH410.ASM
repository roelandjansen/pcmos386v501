	include page.inc
	title	patch410.asm
	subttl	patch410.asm - generic patch driver for pc-mos 4.10
comment ^===============================================================
		     development specification

 program name:	patch410.sys		   assigned to: martin stitt
 module name:	patch410.asm		   assign date: 10/08/90
 entry points:	strat/intr		   completed:	10/15/90
 entry from:	todriver
 entry method:	device driver call
 purpose:	patches in repairs to mos 4.10
 refer to:	n/a
 last update:	03/24/92

=======================================================================

sah 10/25/90	version 1.01 - added correction to correct problem with
		with int 21h function 67h.  also change driver so that
		initialization is more modular.

mjs 10/29/90	version 1.02 - added correction logic to mosint13
		for passport and other situations where a large
		number of sectors is read or written with one call.

mjs 12/11/90	version 1.03 - modified mosint13 correction logic
		(introduced in ver 1.02) to not use int13fun08 for
		diskette operations.

sah 03/26/91	version 1.04 - corrections for peachtree complete iii
		this corrects the case of user intercept of int 17
		and not being able to handle the case of mos's fun 3

mjs 05/19/91	version 1.05 - implemented bwr's correction to serial
		handshaking in i17com and i17coms (mosint17).

sah 05/21/91	version 1.06 - corrections for foxpro enhance keyboard
		handling for extended cursor key pad.

mjs 07/01/91	version 1.07 - corrections for i10f0f - don't go 
		switch to tcb stack.  needed for g.e. officewriter.

sah 07/11/91	version 1.08 - corrections for barres, barcode software
		made sure that 1.04 change saves si when calling int 17h

sah 07/30/91    version 1.09 - corrections for et logic and ansi.sys 
		logic.

sah 08/06/91    version 1.10 - corrections for bugs that i found in the
		above patch

sah 08/21/91    version 1.11 - correction for seting 60 line from quick
		basic.  int 10h function 1123h problem

sah 09/03/91	version 1.12 - corrections for cga only style workstation
		need for wyse370 and relisys terminals
		(prevously patch #50)	

mjs 09/03/91	version 1.13 - correction for 'mos files on' logic.
		(formerly patch 51).

sah 09/04/91    version 1.14 - correction for basic application doing
		a lot of int 10h function 0bh - set pallete
		calls - remove int 10h function 1009h call
		which cause performance degradation

sah 09/04/91	version 1.15 - corrections for at&t demo program, i had
		to reapply patch#48 and make approviate 
		far jumps to make this correction correct

sah 09/06/91	version 1.16 - corrections for everex tape drive
		redirection.  this is correction to mos's
		int 21h function 06 handing for standard in
		being redirected from a file

mjs 09/13/91	version 1.17 - fix blkread for sector number boundary
		problem.  reported by d. long of osmose.  demonstrated
		by the boom.pas/exe program.  fix was made in blkread 
		of mosfutl2.asm.

mjs 09/27/91	version 1.18 - fix disk corruption problems involving
		spooler file i/o during other disk i/o.

sah 10/14/91	version 1.19 - corrections for loading exe device drivers
		this of course requires that patch410.sys be loaded before 
		an 'exe' device driver.

sah 10/23/91	version 1.20 - corrections for 'metlif' exec problem. 
		correctly handle path names with trailing spaces
		     
sah 10/24/91	version 1.21 - corrections for cursor problems on pcterm
		elterm tasks while scrolling   

sah 10/31/91    version 1.22 -  40:17 fix! corrected ray's write protected
		40:17 for 4.0 and 4.1  -k disables this patch
	
sah 11/08/91	version 1.23 -  corrections for brief and exec. -e will
		disable this patch

mjs  note:  version 1.24 is being skipped

sah 12/03/91    version 1.25 -  set scbkbbios to 'y' and also mos map
		tcbprgnm patch

stardate 12/06/91  ver  1.26 -  don't allow pamswitching to a task that did
		an alt 999. (compucon)

mjs 01/10/92	verison 1.27 - corrections for dbts and shift-prtsc.
		corrections to 1.01 -- foxpro was crashing from i21f67.

SAH 01/11/92	Version 1.28 - corrections for INT 21h function 58's
		Last Fit inside INT 21h function 48h. This patch was 
		done for Pharlaps DPMI/VCPI test suite but should make
		other application more compatible.

SAH 01/11/92	Version 2.00 - apply MJS fix for Aladian INT 10h function
		03 needs to grab bios cursor location and update tcbcpos
		This patch is planned to be release with PL6

mjs 01/16/92	version 2.01 - correction to patch code introduced in
		version 1.13.  when getthdl fails, must preserve the
		error code in ax when call mosliman.  this was part of
		the basic compiler 7 problem.

mjs 01/20/92	version 2.02 - correction to scanguts for e0 logic.  
		pressing del then 2 was causing a 3 to be returned
		from scanguts in dx.  this make a reboot occur.

SAH 02/21/92    Version 2.03 - corection for mosint17 so that we have
	        Infinite retry on printer.
		This driver uses offset 12e9h to 12ech of MOS's patch area

mjs 03/03/92	version 2.04 - modifies flush24 to make it set the 
		tcbcacer instead of using the flshflg bit when a cacheing
		critical error occurs.  must use $$shell.sys 4.20 
		with this version of the patch driver.  this change
		was made for unisys u.k.

mjs 03/17/92	version 2.02a - special version so we can ship pl6a.
		has all code up through version 2.02 except that
		the portion of version 1.27 that modifies the front
		end of suspend/tsl has been nullified.
		nullification points marked with the string '@@@@'.

mjs 03/18/92	version 2.02b - has all code up through version 2.02
		including all portions of the original version 1.27.
		also included is logic which corrects for the problems
		found with version 1.27 (programs running at a serial 
		terminal that stall (e.g. foxpro demo, wp51)).

SAH 03/24/92	Version 2.05 (Released with 2.02b corrections along
		with 2.03 and 2.04

mjs 04/07/92	Version 2.06 print screen fix.  the problem was that
		pressing PrintScrn alone on an enhanced keyboard was
		being ignored.  This was a side-effect of sah's
		version 1.06 fix made on 05/21/91.  modified the @prtscr
		that was already contained within this patch driver.
		modified the prtscr entry within the basetbl table
		to use the @prtscr function.

mjs 04/22/92	version 2.07.  fix for brooks drugs/comcotec.
		modify switchtask to prevent irq14 and irq6.  when
		dbts is active and disk irq occurs during switchtask
		and a task based i15 intercept exists, crash.

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
	db	'_410207 '

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
	jb	m16f0ta 		; wrap to begining on overflow
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
	db	far_jmp_opcode
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
	db	far_call_opcode
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
	db	far_call_opcode
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
	db	far_call_opcode
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
	db	far_jmp_opcode
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
	je	scg078
	cmp	al,0e1h
	je	scg078
	and	al,7fh
	add	al,al			; get index into table
	xor	ah,ah
	add	si,ax			; table + 2 * scan
	mov	ax,[si] 		; get translated code from table
	mov	bx,ax			; setup for special function here
	cmp	dl,0e0h
	jne	scg045d 		; if last scancode == e0
	cmp	ax,35f0h		; and if alt-slash (alt-pad-/)
	jne	scg045e
	mov	ax,0a400h		; xlate to a400
	jmp	short scg045a
scg045e:
	cmp	ax,1c0dh
	je	scg045c 		; if pad-enter, or
	cmp	ax,1c0ah
	je	scg045c 		; if pad-cntrl-enter, or
	cmp	ax,352fh
	jne	scg045b 		; if pad-slash
scg045c:
	mov	ah,0e0h 		; set high byte to e0
	jmp	short scg045a
scg045b:
	cmp	ax,0a600h
	je	scg045a 		; else, if not alt-pad-enter
	cmp	ax,9500h		; and not cntrl-numpad-slash
	je	scg045a
	mov	al,0e0h 		; set low byte to e0
	jmp	short scg045a
scg045d:
	cmp	ax,0a600h		; if e0 wasn't last scancode
	jne	scg045a 		; and table word is a600 (alt-enter)
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
scg078:
	xor	dx,dx
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

; in:	al = char to case shift
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
	jns	@altxit 		; finished if make of alt
	cmp	byte ptr [tcbaltnum+1],0
	je	@altxit 		; test numbered entered during alt
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
	cmp	al,kbs_lshf		; is this for left switch
	jne	shftcont		; no than this is not it
	test	[tcbkbctl],kbc_e0	; test for enhance cursor pad keys
	jnz	shftdone
shftcont:
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
shftdone:
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
	js	@prtsc1 		; skip if releasing the key

; if last code was e0, always do print screen
; else, only do if a shift key is down
; else, return a '*' (must have gotten here from the base case)

	test	[tcbkbctl],kbc_e0
	jnz	@prtsc0
	test	[tcbkshft],(kbs_lshf + kbs_rshf)
	jnz	@prtsc0
	mov	ax,372ah
	ret	
@prtsc0:
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
	js	@break1 		; skip if releasing the key
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
	assume	ss:tcb, ds:nothing	;bwr 9/17/90
	xor	[tcbalt999],0ffh
	assume	ds:code, ss:nothing	;bwr 9/17/90
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
	dw	@scroll 		; 02
	dw	@alt			; 03
	dw	@ctrl			; 04
	dw	@lshift 		; 05
	dw	@rshift 		; 06
	dw	@insert 		; 07
	dw	@prtscr 		; 08
	dw	@pause			; 09
	dw	@break			; 0a
	dw	@altnum 		; 0b
	dw	@reboot 		; 0c
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
	db	008h,000h		; 37 prtsc
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
	assume	ds:scbx,es:nothing,ss:tcb
	cmp	[tcbversn],1403h	; if dos 3.2 skip it
	jne	dofun67
	or	[tflag], carry
	mov	[tax],1

; far jump back to int 21h function 67h code

	db	far_jmp_opcode
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

	db	far_jmp_opcode
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
	db	far_call_opcode
sim21l	dw	?,?

	mov	word ptr [psppntr],18h
	mov	word ptr [psppntr + 2],es
	mov	[psphdls],20
cont67:
	cmp	word ptr [tbx],20	; assigning < 20?
	jna	goback
	and	word ptr [bp+4],not 1
	db	far_jmp_opcode
jmp67d	dw	?,?			; 5d6c

goback:

; far jump back to int 21h function 67 code

	db	far_jmp_opcode
jmp67c	dw	?,?			; 5d6c

fixfun67 endp

;======================================================================
;   patch code for mosint13 normalize fix - version 1.02/1.03
;======================================================================

dma13ax equ	650h
dma13cx equ	654h
dma13dx equ	656h
dma13es equ	658h
dmascnt equ	64fh
oint13	equ	2030h

maxhead db	0
maxsect dw	0

	assume	ds:nothing,es:nothing,ss:nothing

; at mos:13a4, code a far jump to 13a  (at the label xyes)

i13a:

; get disk parameters for the drive, setting them into maxhead and maxsect
; these will be used by the normalize function.

	push	cx
	push	di
	mov	dx,ds:[dma13dx] 	; need dl = drive #
	cmp	dl,80h
	jb	m13a
	mov	ah,8
	pushf
	call	dword ptr ds:[oint13]
	mov	cs:[maxhead],dh
	mov	bl,cl
	and	bl,03fh 		; max sct # in bx (1 based)
	xor	bh,bh
	mov	cs:[maxsect],bx
m13a:
	pop	di
	pop	cx

; patch recovery instructions

	mov	ax,ds:[dma13ax]
	cmp	al,cl

	db	far_jmp_opcode
jmp13a	dw	?,?			; mos:13a9

;=======

; at mos:13cd, code a far jump to 13b

i13b:
	add	ds:[dmascnt],al 	; restoration instruction
	call	normalize

	db	far_jmp_opcode
jmp13b	dw	?,?			; mos:13d5

;=======

; at mos:1431, code a far jump to 13c

i13c:
	add	ds:[dmascnt],al 	; restoration instruction
	call	normalize

	db	far_jmp_opcode
jmp13c	dw	?,?			; mos:1439

;=======

; at mos:1492, code a far jump to 13d

i13d:

; patch recovery instructions

	mov	es,ds:[dma13es]
	pop	ds

; new instruction

	clc

	db	far_jmp_opcode
jmp13d	dw	?,?			; mos:14b1

;======================================================================
;.fs
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
;.fe
;=====================================================================^
	assume	ds:nothing,es:nothing,ss:nothing
normalize:
	cmp	byte ptr ds:[dma13dx],80h
	jae	normfd
	add	byte ptr ds:[dma13cx],al
	ret
normfd:
	mov	dl,byte ptr ds:[dma13cx]; calc new starting sector number
	and	dx,03fh 		; in ax
	xor	ah,ah
	add	ax,dx
	mov	ch,byte ptr ds:[dma13cx]; caller's cl to ch
	mov	cl,6			; bring upper cyl bits over
	shr	ch,cl
	mov	cl,byte ptr ds:[dma13cx+1]  ; cx is now cylnder number
	mov	dh,cs:[maxhead]
i13comp1:
	cmp	ax,cs:[maxsect] 	; if starting sector (al) > spt
	jna	i13comp2
	sub	ax,cs:[maxsect] 	; adjust sector # downwards
	inc	byte ptr ds:[dma13dx+1] ; increment head # in dh
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
;   patch code for mosint17 fix -- version 1.04 / 1.08
;======================================================================

	subttl	out17 - output a string ds:si to lptx
	page
;-----------------------------------------------------------------------
;	this routine processes a string int 17 output
;
;	input:
;	  cx  -  count
;	  dx  -  lpt port
;	  ds:si - string to passed
;	output:
;	  cx  -  number of characters sent
;	  ah  -  printer status
;-----------------------------------------------------------------------

out17	proc	near
	push	ds
	xor	ax,ax
	mov	ds,ax

; check to see if int 17h points to mosint17

	cmp	word ptr ds:[17h*4],0ba2dh
	jne	tsr17
	mov	ax,cs:[mos_seg]			
	cmp	word ptr ds:[17h*4+2],ax
	je	mos17
tsr17:

; int 17h <> mosint17, use function 1 instead

	pop	ds
	push	bx
	push	si
	xor	bx,bx			; no characters printed yet
	mov	ah,90h			; indicated ok
	or	cx,cx			; no characters
	jz	tsr17end
tsr17lp:
	lodsb
	xor	ah,ah
	push	bx
	push	si			; 1.08 Save SI - buggy Barres software
	int	17h			; print character
	pop	si			; 1.08 restore SI
	pop	bx
	test	ah,1
	jne	tsr17end
	inc	bx			; indicate character ok, up count
	loop	tsr17lp
tsr17end:
	mov	cx,bx
	pop	si
	pop	bx
	ret
mos17:

; int 17h = mosint17, ok to use function 3

	pop	ds
	mov	ah,3			; use string printing function
	int	17h			; send char to the printer
	ret
out17	endp

fixprn	proc	far
	call	out17
	add	si,cx
	ret
fixprn	endp

;======================================================================
;   patch code for mosint17 fix -- version 1.05
;======================================================================

ok_stat 	equ	90h		;normal printer status.
err_stat	equ	11h		;i/o error | timeout.
tds		equ	bp+6

; new code to handle i17com

i17a:
	mov	cx,256			; try at least 256 times.
i17a1:
	push	ax			; save the character.
	mov	ah,1			; output to serial port.
	int	14h
	test	ah,80h			; if no error, exit immediately.
	jz	i17com_ok
	pop	ax			; get character back and retry.
	loop	i17a1
	mov	ah,err_stat		; if all retries failed, return error.
	jmp	short i17com_exit
i17com_ok:
	pop	ax			; rebalance stack.
	mov	ah,ok_stat		; return ok status.
i17com_exit:
	db	far_jmp_opcode
jmp17a	dw	?,?			; mos:bbb8

;==== new code to handle i17coms

i17b:
	mov	ds,[tds]		; load ds:si with buffer loc.
i17_cs1:
	lodsb				; get the next character.
	push	cx			; save the character counter.
	mov	cx,256			; inner (retry loop) = 256 tries.
i17_cs2:
	push	ax			; save the character.
	push	cx
	mov	ah,1			; output the character.
	int	14h
	pop	cx
	test	ah,80h			; everything ok?
	jz	i17_csok		; if so, go loop for next char.
	pop	ax			; not ok. get char back and retry.
	loop	i17_cs2

; after 256 retries, we couldn't send anything to the com port.
; return an error.

	pop	cx			; rebalance the stack.
	mov	ah,err_stat		; return error.
	jmp	short i17_cs_exit
i17_csok:
	pop	ax			; balance the stack.
	pop	cx			; recover the character counter.
	loop	i17_cs1 		; if any left, go fetch it.

; the output to the com port was ok.  return.

	mov	ah,ok_stat
i17_cs_exit:
	db	far_jmp_opcode
jmp17b	dw	?,?			; mos:bbb8


;======================================================================
;   patch code for mosint10 fix -- version 2.00
;======================================================================

i10a:
	mov	ds,[scb_seg]
	assume	ds:scbx
	mov	es,[scbtcbpc]
	assume	es:tcb

; if function 03h, get cursor don't go through the overhead of int 10
; handler

	cmp	ah,03h			; is this get cursor?
	jne	notint03
	push	bx

	mov	bx,bios
	mov	es,bx
	assume	es:bios

	mov	bl,bh
	xor	bh,bh
	shl	bx,1

	mov	dx,[biocpos+bx]

	mov	es,[scbtcbpc]
	assume	es:tcb

	mov	[tcbcpos+bx],dx

	mov	cx,[tcbctyp]
	pop	bx
	jmp	short m10a
notint03:

; if i10f0f (get mode), don't go through stack switch -- causes stack 
; corruption in certain cases.  
; g.e. office writer calls i10f0f during its int 1c handler.  
; when the irq0 occurs during the time in tsl when when scbtcbpc and 
; ss don't match, if mosint10 switches stacks, the scbtcbpc stack 
; ends up getting corrupted.
 
	cmp	ah,0fh			; is this get mode?
	jne	notint0f
	mov	di,bios
	mov	ds,di
	assume	ds:bios
	mov	al,[biomode]
	mov	bh,[tcbpage]
	mov	ah,[tcbcols]
m10a:
	pop	es
	assume	es:nothing
	pop	di
	pop	ds
	assume	ds:nothing
	iret
notint0f:
	assume	ds:scbx,es:tcb
	push	bp
	mov	di,ss
	
	db	far_jmp_opcode
jmp10a	dw	?,?			; mos:9dc6


;======================================================================

;
; Patch Code for 1.09/1.10 fix, ANSI corrections for ET software
; 

mos10	macro
	call	con10
	endm

getcrs0 macro
	call	getcrsx
	endm


	assume  ds:nothing,es:nothing,ss:tcb
OutAnsi proc	far
	push	bp		; Used in BIOS string writes
	push	di
	les	bx,dword ptr [tcb$hdr]	; Get pointer to RH
	mov	ax,es:[bx+14]		; Get offset transfer addrs
	mov	dx,es:[bx+16]	; Get seg transfer addrs
	mov	cx,es:[bx+18]	; Get byte count
	mov	bx,ax		; Set buffer address
;
; The following addition corrects problems with educational package
; which was directly poking the cursor position in bios and then
; call INT 21  function for write in graphics mode.  I fix the 
; problem by making sure the TCBCPOS had the current bios position
;
	mov	es,[zeroseg]
	mov	ax,word ptr es:[450h]
	mov	[tcbcpos],ax
;
	mov	es,dx
;
;	we will now test to see if ansi support is enable
;
	cmp	[tcbansi],0ffh
	je	charout
;
;	handle non-ansi processing. This is fast through 1 INT 10 call
;
	getcrs0 		; DX= cursor pos
	mov	bp,bx
	mov	bl,[tcb$ca]
	mov	ax,1301H	; String output with [char,char...] & move cur
	mov	bh,[tcbpage]
	mos10
	jmp	endout
;
;	Handle ansi emulation here.
;
charout:
	cmp	[tcb$ef],'Y'	; ESC sequence pending?
	jne	charout2
	db	far_jmp_opcode
jmpansi	dw	?,?			
;#####	jmp	[tcb$er]	; Yes
charout2:
	; Scan string for any ESC sequences before OUTPUTing
	; If found output up to ESC seq. and then process ESC seq.

	cld
	mov	di,bx
	push	cx		; Save count
	mov	al,27		; Scan for ESC
	repne scasb
	pop	cx		; Count back
	jne	finstr		; No ESCs, finish string output
ESCing:
	mov	[tcb$ef],'Y'	; Set ESC seq pending flag
	push	di		; Save string pointer
	dec	di		; Point to ESC
	sub	di,bx		; Calc # chars til ESC
	sub	cx,di		; Calc count for rest of string
	push	cx		; Save new count
	mov	cx,di		; Calc count before ESC
	or	cx,cx		; Is ESC the 1st char?
	jnz	finstr		; SAH
	jmp	ESConly		; SAH

finstr:
	getcrs0 		; DX= cursor pos
	mov	si,bx

lpwrap:
	push	dx
	mov	ah,2
	mov	bh,[tcbpage]		; set cursor position
	mos10	
	mov	al, byte ptr es:[si]
	cmp	al,13			; test for carriage-return
	je	wrapcr
	cmp	al,10			; test for line-feed
	je	wraplf	
	cmp	al,8  			; test for backspace	
	je	wrapbs
	cmp	al,7			; test for Bell
	je	wrapbell		
	push	cx
	mov	bl,[tcb$ca]
	mov	bh,[tcbpage]
	mov	cx,1			; 1 character at a time
	mov	ah,9			; display char
	mos10				; must use function 9 so attribute is
	pop	cx			; displayed
	pop	dx
;
;	after displaying character, we must test to see if we place character
;	at botton right corner, if so we must scroll screen
;
	inc	dl
	cmp	dl,[tcbcols]		; test to see if end of line
	jb	wpneol
;
	push	dx
	mov	ax,0e0dh
	mov	bl,[tcb$ca]
	mos10
wraplf:
	getcrs0 			; get cursor
	inc	dh
	cmp	dh,[tcbrows]
	jb	setlf
	call	wscroll 		; must scroll the screen, don't do it
	dec	dh
setlf:
	pop	ax			; discard old cursor position
	jmp	short wpneol
wrapbell:
	mov	bl,[tcb$ca]
	mov	ah,0eh			; write TTY
	mos10
wrapcont:
	pop	dx
	getcrs0
	jmp	short wpneol
wrapbs:
	pop	dx
	getcrs0
	or	dl,dl
	jz	wpneol
	dec	dl	    		; handle back space
	jmp	short wpneol	
wrapcr: 				; carriage return
	pop	dx
	xor	dl,dl			; reset to row 0
wpneol:
	inc	si			; point to next char
	dec	cx
	jcxz	wrapdone
	jmp	lpwrap			; wrap till you done
wrapdone:
	mov	ah,2
	mov	bh,[tcbpage]
	mos10				; set cursor pos	
	cmp	[tcb$ef],'Y'	; Is ESC seq pending?
	jne	endout		; No
ESConly:
	pop	cx		; Get size of new string
	pop	bx		; Get string pointer
	dec	cx		; Skip the ESC char itself
	or	cx,cx		; End of string?
	jz	endout		; Yes
	jmp	charout 	; Continue with rest of string
endout:
	db	far_jmp_opcode
jmpaout	dw	?,?			
OutAnsi endp

;
;   The following procedure is use to scroll the screen if necessary
;

wscroll proc	near
	push	cx
	push	dx
	mov	ax,0601h
	xor	cx,cx
	mov	dh,[tcbrows]
	dec	dh
	mov	dl,4fh
	mov	bh,[tcb$ca]
	push	dx
	mos10
	pop	dx
	mov	cx,dx
	xor	cl,cl
	mov	ax,0600h
	mov	bh,07h
	mos10
	pop	dx
	pop	cx
	ret
wscroll endp

con10	proc	near
        push    ds
        mov	ds,[zeroseg]
        pushf
        cli
        call    dword ptr ds:[10H*4]
        pop     ds
	ret
con10	endp

;
; The following routine is use to get the current cursor position, for
; maximun performance, if INT 10h intercept points to MOS's kenrel 
; than return value at TCBCPOS
;

	public	getcrsx
getcrsx	proc	near
	push	ds
	push	ax
	push	bx
	push	cx

	xor	ax,ax
	mov	ds,ax
	mov	ah,3
	mov	bh,[tcbpage]
        pushf
        cli
        call    dword ptr ds:[10H*4]

	pop	cx
	pop	bx
	pop	ax		
	pop	ds
	ret
getcrsx	endp
sizcrsx equ     ($-getcrsx)

;
; Patch 410 1.11 fix, the following logic is insert into the vfnul logic
; inside mosint10 ddt code. 
;

setrows	proc	far
	assume  ds:tcb,es:nothing,ss:nothing
;
; SAH 08/21/91 The following logic was added to support function 1122 - 1124
; which allows the user to set number of line in dl
;
	cmp	al,22h			; only for 22h - 24h
	jb	not2224
	cmp	al,24h
	ja	not2224
	push	ax
	mov	al,[bp+6]		; get  # of line to set
	jmp	short not50
not2224:
;
	cmp	al,12h			; setting 43line mode
	jne	notfun11
	push	ax
	mov	al,43			; 43 for ega
	mov	ah,[tcbstation]
	cmp	ah,2			; ega - set it to 43
	je	not50
	cmp	ah,5			; mono ega set it to 43
	je	not50
	mov	al,50			; 50 for vga or mono vga
not50:
	mov	[tcbrows],al		; let mos no its 43 or 50 line mode
	pop	ax
notfun11:
	ret
setrows	endp


;======================================================================

; patch code for 1.13 fix - 'mos files on'

	assume	ds:nothing,es:tfb,ss:nothing 
p113_entry:
	db	far_jmp_opcode
fj113a	dw	?,?			
p113a:
;	call	getthdl 		;   -1 can't be returned)

	jnc	maktfb4
	push	ax
	mov	ah,1			; delete the tfb
	mov	al,'F'

	db	far_jmp_opcode
fj113b	dw	?,?			
p113b:
;	call	moslim0

	pop	ax
	stc

	db	far_jmp_opcode
fj113c	dw	?,?			
;	jmp	maktfbx

maktfb4:
	mov	[tfbhdl],ax		; handle for file
	xor	ax,ax
	mov	word ptr [tfbpos],ax	; positioned at offset 0 in file
	mov	word ptr [tfbpos+2],ax
	mov	[tfblvl],bh
	mov	bh,bl
	and	bl,0fh
	shr	bh,1
	shr	bh,1
	shr	bh,1
	shr	bh,1

	db	far_jmp_opcode
fj113d	dw	?,?			



comment ^

========== old

2660	call	getthdl				9c23h
	jc	maktfbx				26d4h
	mov	[tfbhdl],ax			es:[0018h]
	xor	ax,ax
	mov	word ptr [tfbpos],ax		es:[001dh]
	mov	word ptr [tfbpos+2],ax		es:[001fh]
	mov	[tfblvl],bh			es:[001ch]
	mov	bh,bl
	and	bl,0fh
	shr	bh,1
	shr	bh,1
	shr	bh,1
2683	shr	bh,1
2685

========== new

	call	getthdl
	jnc	maktfb4
	mov	ah,1
	mov	al,'F'
	call	moslim0				9edfh
	stc
	jmp	maktfbx
maktfb4:
	mov	[tfbhdl],ax
	xor	ax,ax
	mov	word ptr [tfbpos],ax
	mov	word ptr [tfbpos+2],ax
	mov	[tfblvl],bh
	mov	bh,bl
	and	bl,0fh
	shr	bh,1
	shr	bh,1
	shr	bh,1
	shr	bh,1
^






;======================================================================
; Resident code portion for Version 1.15 - INT 10h fix
;======================================================================

Fix15a proc	far
	push	ds
	mov	ds,[scb_seg]
	assume  ds:scbx
	mov	ds,[scbtcbpc]
	assume	ds:tcb
	mov	al,es:[004ah]
	cmp	al,80
	jbe	setm3a
	mov	[tcbcols],al
setm3a:
	mov	al,es:[0084h]
	inc	al
	cmp	al,25
	jbe	setm4
	mov	[tcbrows],al
setm4:
	pop	ds
	ret
Fix15a endp

Fix15b proc	far
	push	ds
	mov	ds,[scb_seg]
	assume  ds:scbx
	mov	ds,[scbtcbpc]
	assume	ds:tcb
	mov	al,[tcbcols]
	mov	es:[004ah],al
	pop	ds
	ret
Fix15b endp

;======================================================================
; Resident code portion for Version 1.16 - INT 21h function 06h fix
;======================================================================

Fix16 proc	far
      test	byte ptr es:[0025h],80h
      jnz	Fix16exit
      jcxz	Fix16zero
      test	byte ptr es:[0025h],01h
      jnz	Fix16exit
      and	word ptr [bp+04],-41h		; clear zero flage
      pop	bp				; pop offset
      pop	bp				; pop cs
      mov	bp,bx
;
; do a far jump back into the code to return value to user
;
      db	far_jmp_opcode
      dw	600ch
seg16 dw	?
Fix16zero:
      cmp	ax,ax		; make sure zero flag is set
Fix16exit:
      ret
Fix16 endp


;======================================================================
; fix for version 1.18 - disk corruption from spooler
;======================================================================

noi5	db	0

enter118a:
	or	byte ptr ss:[125h],2
	mov	cs:[noi5],1
	db	far_jmp_opcode
	dw	0cd50h
return118a dw	?
	

enter118b:
	mov	cs:[noi5],0
	mov	ds,cs:[scb_seg]
	db	far_jmp_opcode
	dw	0cd58h
return118b dw	?


enter118c:

; when getkeys is called on the way out of tsl, must defer any int5
; calls because spooler file i/o could cause re-entrance into the
; disk logic.

	cmp	cs:[noi5],0
	jne	getoutx

; whenever the current task is inside the bdb gate, must defer any
; int5 calls to prevent re-entrance.

	mov	ds,cs:[scb_seg]
	cmp	ds:[scbbdbbsy],0
	je	gt1
	mov	ax,ss
	cmp	ax,ds:[scbbsytcb]
	je	getoutx
gt1:
	test	ss:[tcbbrkfg],80h
	jz	getoutx
	and	ss:[tcbbrkfg],not 80h
	push	ss:[tcbstkp]
	mov	ss:[tcbstkp],sp
	sub	ss:[tcbstkp],128
	int	5
	pop	ss:[tcbstkp]
getoutx:
	and	ss:[tcbbrkfg],not 8
	db	far_jmp_opcode
	dw	0a1d1h
return118c dw	?

Icnfsiz	dw	0

	subttl ExeDevice - check and adjust 'EXE' style device drivers
	page
;======================================================================
;,fs
; ExeDevice - check and adjust 'EXE' style device drivers
;
; in:	ds -> cnfbuf (config data segment)
; out:	es = segment of driver
;
;out:	ds -> cnfbuf (config data segment)
;	es = segment of driver
;
;,fe
;=====================================================================
	assume ds:nothing,es:nothing,ss:tcb
ExeDevice proc	near
	push	si
	push	di
	push	ds
	push	es
;
;	first we must test to see if file is EXE
;
	cmp	word ptr es:[0],5a4dh
	jne	skipexe
;
;	Now we must go through relocation table and relocate exe items
;	for device driver
;
	mov	ax,es
	mov	cx,es:[6]
	jcxz	skiprel
	mov	si,es:[18h]
looprel:

;old;	push	si
;old;	lds	si,dword ptr es:[si]
;old;	add	word ptr ds:[si],ax		
;old;	pop	si
	
	mov	di,ax			;new; seg address of header
	add	di,es:[8]		;new; plus header length in paragraphs
	add	di,es:[si+2]		;new; plus seg portion of relo item
	mov	ds,di			;new; gives target segment
	mov	di,es:[si]		;new; target offset
	add	word ptr ds:[di],ax	;new;

	add	si,4
	loop	looprel		
skiprel:	
;
;	Once Relocated, we can strip header off by moving actual code
;	to start of exe header
;
	cld
	xor	si,si
	xor	di,di
	mov	cx,cs:[Icnfsiz]
	add	ax,word ptr es:[8]	; add size of header
	mov	ds,ax
	rep	movsb		
;
skipexe:

	pop	es
	pop	ds
	pop	di
	pop	si
	ret
ExeDevice endp	


PatchEXE proc	far
	call	ExeDevice
	xor	bx,bx
	mov	dx,si
	mov	ax,di
	ret
PatchEXE endp

SetIcnfsiz proc	far
	mov	cs:[Icnfsiz],cx
	add	cx,15
	shr	cx,1
	ret
SetIcnfsiz endp

;======================================================================
; fix for version 1.20 - exec file name fix
;======================================================================
fix120 proc far
	jz	pathok
;
; SAH 10/23/91 Correction for Metlif 
;
	cmp	byte ptr es:[di-1],' '	; is last character check a ' '
	jne	doerror
pathslp:
	dec	di			; remove space
	cmp	byte ptr es:[di-1],' '	
	je	pathslp
	jmp	short pathok
doerror:	
;
	db	far_jmp_opcode
	dw	5b4bh
seg120a dw	?
	
pathok:
	db	far_jmp_opcode
	dw	5352h
seg120b dw	?
fix120	endp       	

fix120a proc	far
	rep	movsb
	xor	al,al
 	stosb
	mov	bp,[bp]
	ret
fix120a endp
	
;======================================================================
; fix for version 1.21 - cursor - scroll problem
;======================================================================

ZeroVal	dw	0			; constant for zero

fix121	proc	far
	assume	ss:tcb
	cmp	[tcbin10],0		; if inside mosint10 logic
	jne	tsl055			; no need to synce cursors
	assume	ss:nothing
	push	es
	mov	es,cs:[ZeroVal]
	db	far_jmp_opcode
	dw	0cb38h
seg121a dw	?

tsl055:
	db	far_jmp_opcode
	dw	0cb4eh
seg121b dw	?
fix121	endp

;=======================================================================
;              Version 1.23   Brief EXEC Fix  -E diables this option
;=======================================================================
fix123	proc	far
	mov	ax,[bp-4eh]		; get size of file to load
	add	ax,es:[0ah]		; minalloc
	ret
fix123  endp



;=======================================================================
;              Version 1.22   40:17 Fix   -K diables this option
;=======================================================================
fix122a proc	far
	assume  es:tcb
	mov	[tcbkboff],-1		; initialize key assignment pointer
	mov	[tcbcon417],-1		; for keykeys to set value
	assume  es:nothing
	ret
fix122a endp


fix122b proc	far
	assume  ss:tcb
	cmp	[tcbcon417],-1		; if pamswitch flag to update leds
	je	tsl125			; then force call to getkeys
	test	[tcbstat],wkey		; getkeys here
tsl125:	
	assume  ss:nothing
	ret
fix122b endp

fix122c proc	far
	assume  es:tcb
	mov	word ptr [tcbtsk38+2],bx; int d4 intercepts
	xor	ax,ax
	mov	ds,ax
	assume  ds:nothing
	mov	al,byte ptr ds:[417h]
	mov	[tcbcon417],al
	assume  es:nothing
	ret
fix122c endp

fix122d proc	far
	mov	ds,[scb_seg]
	assume  ds:scbx
	cmp	dl,[scbcon417]
	je	kbdat0
	cmp	cx,dx			; cx must equal dx
	jne	kbdat0
	cmp	[scbinit],0
	je	kbdat0
	mov	[scbcon417],dl
	call	updateleds		; update leds on master console
kbdat0:
	assume ds:nothing
	ret
fix122d endp

ddtfar	dd	0			; far routine for ddtcallf


fix122e proc	far
	assume 	ds:tcb
	push	dx
	push	es			; let's be smart and check the
	push	bx
	les	bx,[tcbkeyrdy]		; ddt has any scan codes available.
	cmp	byte ptr es:[bx],0
	mov	bx,40h
	mov	es,bx
	mov	dl,byte ptr es:[17h]
	mov	[tcbkshft],dl
contgetdd2:
	assume	es:nothing
	pop	bx
	pushf
	and	dl,070h
	popf
	jnz	getdd0a

; Now we must check to see if stations copy of 40:17 is the same as
; what currently located in BIOS, if value at 40:17 is the same as
; value of TCBCON417 then we will skip the calls to terminal driver

	cmp	dl,[tcbcon417]
	jne	getdd0a
	pop	es
	pop	dx
;
	db	far_jmp_opcode
	dw	0a220h
seg122a dw	?
		
	
getdd0a:
	mov	[tcbcon417],dl
	pop	es
	mov	ah,1			; get a keyboard char (inkbdata)
	mov	si,offset [tcbcondd]	; get the console driver address
	push	cx
	mov	dh,-1			; always force this to 0ffh
	mov	cx,dx			; cx must equal dx
	call	dword ptr cs:[ddtfar]	; use the driver gate mechanism
	pop	cx
	pop	dx			
	jnc	getdd0			; jump if terminal connected

	db	far_jmp_opcode
	dw	0a1fdh
seg122b dw	?
	

getdd0:
	db	far_jmp_opcode
	dw	0a21ch
seg122c dw	?
	assume  ds:nothing		
fix122e endp


fix122f	proc	far
	assume	ds:tcb
	push	ax
	push	es
	mov	ax,40h
	mov	es,ax
	mov	al,es:[17h]		; update TCBKSHFT from 40:17
	mov	[tcbkshft],al
	and	byte ptr es:[96h],0fch
	cmp	bl,0e0h
	jne	prse0
	or	byte ptr es:[96h],2
prse0:
	cmp	bl,0e1h
	jne	prse1
	or	byte ptr es:[96h],1
prse1:
	pop	es
	pop	ax	
	assume	es:scbx
	call	dword ptr [scbscang]
	assume  ds:nothing,es:nothing
	ret
fix122f	endp

	subttl updateleds - updates leds on master console
	page
;======================================================================
;,fs
; updateleds - updates leds on master console
;
; this procedure is use by inkbdata to	update the leds on the master
; console keyboard.   it does this by calling the original bios int 16
; function 01h with io protection off
;
; in:	ds -> grp
;
; out:	
;
;,fe
;=====================================================================
	assume	ds:scbx,es:nothing,ss:nothing
updateleds proc near
	push	es
	mov	ax,40h
	mov	es,ax
	push	word ptr es:[0097h]
	push	word ptr es:[0017h]
	push	word ptr es:[001ah]	; save head pointer
	push	word ptr es:[001ch]	; save tail pointer

; force 40:97 to be differents so bios with switch leds on and off

	mov	al,dl
	shr	al,1
	shr	al,1
	shr	al,1
	shr	al,1
	not	al
	and	al,07h
	or	byte ptr es:[0097h],al
	and	byte ptr es:[0097h],not 040h

; turn keyboard io protection off while calling int 16h

	test	[scbmmfea],40h		; is i/o protection supported?
	jz	dat9a			; no, skip
	push	ds
	lds	si,[scbmmptr]		; get pointer to memman data
	assume	ds:nothing
	lds	si,dword ptr [si].parmiop
	mov	al,[si+12]		; save current trapping state in al
	and	byte ptr [si+12],not 13h; clear byte 12, bits 1 and 2
	pop	ds
	assume	ds:scbx
	push	ax
dat9a:

; call bios int 16 to change keyboard leds

	mov	ah,1			; pick up current state of toggles
	test	byte ptr es:[0096h],10h
	jz	datnoenh
	or	ah,10h
datnoenh:
	pushf				; (so mc keyboard matches lights)
	cli
	call	[i16old]
	test	[scbmmfea],40h		; is i/o protection supported?
	jz	dat9b			; no, skip
	pop	ax
	push	ds
	lds	si,dword ptr [si].parmiop
	lds	si,[scbioptr]		; get pointer to io protection table
	assume	ds:nothing
	mov	[si+12],al		; save current trapping state in al
	pop	ds
	assume	ds:scbx
dat9b:
	pop	word ptr es:[001ch]	; restore tail pointer
	pop	word ptr es:[001ah]	; restore head pointer
	pop	word ptr es:[0017h]
	pop	word ptr es:[0097h]
skipdat:
	pop	es
	ret
updateleds endp

;======================================================================
;		FIX 1.25 MOS MAP
;======================================================================
fix125a proc	far
	assume  es:tcb
	mov	word ptr [tcbprgnm],2020h
	mov	word ptr [tcbprgnm+2],2020h
	mov	word ptr [tcbprgnm+4],2020h
	mov	word ptr [tcbprgnm+6],2020h
	mov	word ptr [tcbprgnm+8],2020h
	mov	byte ptr [tcbprgnm+10],20h
	mov	[tcbansi],0ffh		; initialize ansi support to on
	assume  es:nothing
	ret
fix125a endp



;======================================================================
;		FIX 1.26 Don't allow pamswitch to alt999 task
;======================================================================
fix126a proc	far
	assume  es:tcb
	cmp	[tcbpam],'N'
	je	tvx

; if task did a alt 999 don't allow pamswitching...

	cmp	[tcbalt999],0ffh	
	jne	tvx   
	db	0eah
	dw	0b9bah
seg126a dw	?			
tvx:
	db	0eah
	dw	0b9cch
seg126b dw	?			
fix126a endp

;======================================================================
; fix for version 1.27 - dbts and shift-prtsc
;======================================================================
fix127_a:
	and	byte ptr ss:[125h],0fdh
	push	ax
	push	cx
	db	far_call_opcode
	dw	094bfh
s127_a	dw	?
	pop	cx
	pop	ax
	mov	word ptr ds:[10c1h],0
	db	far_jmp_opcode
	dw	0cb2dh
s127_b	dw	?



;======================================================================
; fix for version 1.28 - function 48 and 58 last fix
; 
; This fix adds logic inside MOSFUN48 so that if  some one does a
; INT 21h function 58h to change memory allocations to last fix.
; MOS's INT 21h function 48h will correctly handle allocating 
; memory in upper space of convential memory.  I found this problem
; with Pharlap's DPMI/VCPI test suit.       
;======================================================================

	assume  ds:mbseg,es:nothing,ss:tcb
fix128a proc	far
	mov	bx,[tcbmbpf]
	mov	[tcb_malloc_mark],0
	ret
fix128a endp


fix128b proc	far
	cmp	[tcb_malloc_strategy],2
	jne	f128b1
	mov	[tcb_malloc_mark],bx
	db	far_jmp_opcode			; jmp far fun48b
	dw	50c2h				
seg128a dw	?
f128b1:
	mov	bx,[tcbpsp]			
	db	far_jmp_opcode			; jmp far xxxx:5090
	dw	5090h				
seg128b dw	?
fix128b endp
	
fix128c proc	far
	mov	cx,ds
	inc	cx
	cmp	[tcb_malloc_strategy],2
	je	f128c1
	add	cx,ax
	mov	[mbsize],ax
	db	far_jmp_opcode			; jmp far xxxx:50a7h
	dw	50a7h
seg128c dw	?
f128c1:
	mov	word ptr [mbowner],0	; set as free block
	sub	[mbsize],ax
	dec	[mbsize]
	add	cx,[mbsize]
	mov	bl,[mbtype]		; get type of current block
	mov	byte ptr [mbtype],'M'	; set current as not last block
	mov	ds,cx
	mov	[mbtype],bl		; set as type of new block
	mov	[mbsize],ax
	mov	bx,[tcbpsp]
	mov	[mbowner],bx
	db	far_jmp_opcode			; jmp far xxxx:50d0h
	dw	50d0h
seg128d dw	?
fix128c endp

fix128d proc	far
	cmp	[tcb_malloc_mark],0	; did we mark a block
	je	f128d
	mov	ds,[tcb_malloc_mark]
	mov	bx,[tcbpsp]
	db	far_jmp_opcode			; jmp far xxxx:50d0h
	dw	5090h
seg128e dw	?
f128d:
	mov	[bp+12h],cx
	mov	word ptr [bp+18h],0008
	db	far_jmp_opcode			; jmp far xxxx:50e4h
	dw	50e4h
seg128f dw	?
	
fix128d endp
	

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
; fix for version 2.02b - protection for dopoll and vidram
; calls within suspend.
;======================================================================

; the following code was moved to this patch driver from the i8maint
; function to open up a patch pocket within the mos segment for the 
; code that will make gated calls to dopoll and vidram.  this approach 
; was easier than patching in a bunch of far calls to near calling shells.
; this opens up the address range mos:c26c through c2b5 inclusive.

	assume  ds:scbx,es:tcb,ss:nothing
fix202b:

	pop	ax			; so retf at end will work
	push	cs:[mos_seg]
	push	ax

	push	ds
	push	es
	inc	byte ptr [scbhwcl]	; update indicators for any

;	mov	[lagtcb],0		; processes waiting on this irq0
	mov	word ptr ds:[1093h],0

	cli				; increment the internal counter
	inc	[scbtimer]		; and manage wraps
	jne	chkw1			; zr if a wrap around
	mov	ax,[scbtcbpf]		; start with top of tcb list
	inc	[scbtimerh]		; bump most significant word of counter
chkw2:
	or	ax,ax
	jz	chkw1
	mov	es,ax
	assume	es:tcb
	mov	[tcbwtflg],0ffh 	; set wrap flag for all tcb's
	mov	ax,[tcbtcbpn]
	jmp	chkw2
chkw1:
	sti

;	mgetzero ds			; update the lag counter from
	xor	ax,ax
	mov	ds,ax

	assume	ds:nothing		; the current timer value
	cli
	pop	es			; recover pointer to current tcb
	mov	ax,ds:[6ch]
	mov	word ptr [tcblagcnt],ax
	mov	ax,ds:[6eh]
	mov	word ptr [tcblagcnt+2],ax
	sti
	xor	[tcbprt61],10h		; toggle refresh bit for sidekick
	pop	ds

;	ret
	retf				; pushed cs:[mos_seg] above


;======================================================================
; fix for version 2.07 - dbts/user i15 icept/switchtask
;======================================================================

; this first section is simply a patch replacement for the 
; switchif function.  it was necessary to relocate it to this
; patch driver to make room in the kernel for the two calling shells
; required for the switchtask patch.

fix207p1:
	push	es
	mov	es,cs:[mos_seg]
	cmp	byte ptr es:[869fh],059h
	pop	es
	jz	fix207p1a
	push	ax
	mov	ax,ss

	db	far_call_opcode
	dw	86abh
seg207a	dw	?
	pop	ax
fix207p1a:
	db	far_jmp_opcode
	dw	086afh
seg207b	dw	?


; this is the switchtask patch.

fix207p2:
	in	al,021h			
	push	ax
	or	al,40h			; mask off irq6
	out	021h,al
	in	al,0a1h			
	push	ax
	or	al,40h			; mask off irq14
	out	0a1h,al

	mov	ax,es

	db	far_call_opcode
	dw	86a5h
seg207c	dw	?

	mov	bx,ax

	db	far_call_opcode
	dw	86b7h
seg207d	dw	?

	pop	ax
	out	0a1h,al			; restore irq14
	pop	ax
	out	021h,al			; restore irq6
	mov	ax,es

	jmp	short fix207p1a


;======================================================================
	subttl	initialization
	page
	
	assume	ds:nothing,es:nothing,ss:nothing

end_res label	byte
	nop

instmsg 	db	13,10,'Patch410.sys driver installed, version 2.07            ',13,10,'$'  ;@@xlat
notmosmsg	db	13,10,'Patch410.sys must only be used with PC-MOS version 4.10                 ',7,7,13,10,'$'  ;@@xlat
notmos410	db	13,10,'Patch410.sys detects mismatched kernel code           ',7,7,13,10,'$'  ;@@xlat
notsmpmsg	db	13,10,'Patch410.sys must be loaded globally                ',7,7,13,10,'$'	;@@xlat
notpl4		db	13,10,'Patch410.sys requires PL4             ',7,7,13,10,'$'  ;@@xlat


InitSeg		dw	0		; segment for INIT segment

OptionK		db	'N'		; Ver 1.22 is enable
OptionE		db	'N'		; Ver 1.23 is enable
OptionL		db	'N'		; Ver 1.28 is enable
OptionI		db	'N'		; Ver 2.03 is enable

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

chk100	dw	m16f0k_ofs		; offset within segment
	db	5			; # of bytes in list
	db	0c6h,006h,0feh,000h,000h; the list

chk101	dw	xfun67_ofs		; offset within segment
	db	6			; # of bytes in list
	db	083h,07eh,012h,014h,077h,006h  ; the list

chk103	dw	013a4h			; offset within segment
	db	5			; # of bytes in list
	db	0a1h,050h,006h,03ah,0c1h; the list

chk104	dw	09357h			; offset within segment
	db	6			; # of bytes in list
	db	0b4h,003h,0cdh,017h,003h,0f1h

chk105	dw	0bbaeh
	db	6			; # of bytes in list
	db	0b9h,001h,000h,0ebh,004h,008eh

chk107	dw	09dc6h
	db	6			; # of bytes in list
	db	026h,080h,03eh,0d2h,002h,000h

chk109	dw	03b6dh
	db	6			; # of bytes in list
	db	055h,057h,036h,0c4h,01eh,036h

chk113	dw	2660h
	db	6			; # of bytes in list
	db	0e8h,0c0h,075h,072h,06fh,026h

	subttl chk_code - verify code match in kernel
	page
;======================================================================
;.fs
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
;.fe
;=====================================================================^
	assume	ds:nothing,es:nothing,ss:nothing
chk_code:
	pushset cx,si,di,ds,es
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

	subttl install100 - install int 16 fix for 4.10
	page
;======================================================================
;.fs
; install100 - install int 16 fix for 4.10
;
; install int 16 fix
;
; in:	ax -> mos segment
;	es -> scb segment
;
; out:	ax -> mos segment
;
;.fe
;=====================================================================^
	assume	ds:nothing,es:scbx,ss:nothing
install100 proc	near
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
	mov	di,xtimparm_ofs 	; location for calling shell
	mov	al,2eh			; cs: override
	stosb
	mov	al,0ffh 		; mem call opcode
	stosb
	mov	al,16h			; mod011r/m
	stosb
	mov	ax,di
	add	ax,3			; address of location holding address
	stosw
	mov	al,0cbh 		; retf opcode
	stosb
	mov	ax,timparm_ofs		; offset of real timparm function
	stosw

; patch suspend calling shell into old mosint16 code

	mov	di,xsuspend_ofs 	; location for calling shell
	mov	al,2eh			; cs: override
	stosb
	mov	al,0ffh 		; mem call opcode
	stosb
	mov	al,16h	   		; mod011r/m
	stosb
	mov	ax,di
	add	ax,3			; address of location holding address
	stosw
	mov	al,0cbh 		; retf opcode
	stosb
	mov	ax,suspend_ofs		; offset of real timparm function
	stosw

; patch kernel to use new m16f0k

	mov	di,m16f0k_ofs
	mov	al,far_jmp_opcode	; far jump opcode
	stosb
	mov	ax,offset m16f0k
	stosw
	mov	ax,cs
	stosw

; patch kernel to use new m16f1

	mov	di,m16f1_ofs
	mov	al,far_jmp_opcode
	stosb
	mov	ax,offset m16f1
	stosw
	mov	ax,cs
	stosw

; recover es -> scb and install our vector into scbscang

	pop	es
	mov	word ptr es:[scbscang],offset translat
	mov	word ptr es:[scbscang+2],cs
	sti
	pop	ax
	ret
install100 endp

	subttl install101 - install int 21h fun 67 fix for 4.10
	page
;======================================================================
;.fs
; install101 - install int 21h fun 67 fix for 4.10
;
; install int 21h function 67h fix
;
; in:	ax -> mos segment
;	es -> scb segment
;
; out:	ax -> mos segment
;
;.fe
;=====================================================================^
	assume	ds:nothing,es:scbx,ss:nothing
install101 proc	near
	push	ax

; patch sim21 calling shell into patch 67 code

	mov	[sim21l],xsim21_ofs
	mov	[sim21l+2],ax

; patch jump locations back to kernel old mosfun67 codes

	mov	[jmp67a],xfun67a_ofs
	mov	[jmp67a+2],ax
	mov	[jmp67b],xfun67b_ofs
	mov	[jmp67b+2],ax
	mov	[jmp67c],5d72h
	mov	[jmp67c+2],ax
	mov	[jmp67d],5d74h
	mov	[jmp67d+2],ax

; patch sim21 calling shell in old mosint16 code

	push	es
	mov	es,ax
	cld
	mov	di,xsim21_ofs		; location for calling shell
	mov	al,2eh			; cs: override
	stosb
	mov	al,0ffh 		; mem call opcode
	stosb
	mov	al,16h			; mod011r/m
	stosb
	mov	ax,di
	add	ax,3			; address of location holding address
	stosw
	mov	al,0cbh 		; retf opcode
	stosb
	mov	ax,sim21_ofs		; offset of real sim21 function
	stosw

; patch kernel code to far jump to our patch area

	mov	di,xfun67_ofs		; location of mosfun67
	mov	al,far_jmp_opcode
	stosb
	mov	ax,offset fixfun67	; get offset to our code
	stosw
	mov	ax,cs			; get our code segment
	stosw
	pop	es

	pop	ax
	ret
install101 endp

	subttl install103 - install int 13 fix for 4.10
	page
;======================================================================
;.fs
; install103 - install int 13 fix for 4.10
;
; install int 13 fix
;
; in:	ax -> mos segment
;	es -> scb segment
;
; out:	ax -> mos segment
;
;.fe
;=====================================================================^
	assume	ds:nothing,es:scbx,ss:nothing
install103 proc	near
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
	mov	al,far_jmp_opcode
	stosb
	mov	ax,offset i13a
	stosw
	mov	ax,cs
	stosw

	mov	di,13cdh
	mov	al,far_jmp_opcode
	stosb
	mov	ax,offset i13b
	stosw
	mov	ax,cs
	stosw

	mov	di,1431h
	mov	al,far_jmp_opcode
	stosb
	mov	ax,offset i13c
	stosw
	mov	ax,cs
	stosw

	mov	di,1492h
	mov	al,far_jmp_opcode
	stosb
	mov	ax,offset i13d
	stosw
	mov	ax,cs
	stosw
	sti
	pop	es
	pop	ax
	ret
install103 endp

	page
;======================================================================
;.fs
; install104 - install prn,lpt device change for int 17 intercepts
;
; in:	ax -> mos segment
;	es -> scb segment
;
; out:	ax -> mos segment
;
;.fe
;=====================================================================^
	assume	ds:nothing,es:scbx,ss:nothing
install104 proc near
	push	ax
	push	es
	mov	es,ax
	mov	al,far_call_opcode
	mov	di,9357h
	cli
	stosb
	mov	ax,offset fixprn
	stosw
	mov	ax,cs
	stosw
	mov	al,90h
	stosb
	sti
	pop	es
	pop	ax
	ret
install104 endp

	page
;======================================================================
;.fs
; install105 - install fix for i17com and i17coms
;
; in:	ax -> mos segment
;	es -> scb segment
;
; out:	ax -> mos segment
;
;.fe
;=====================================================================^
	assume	ds:nothing,es:scbx,ss:nothing
install105 proc near
	push	ax
	push	es
	mov	[jmp17a],0bbb8h
	mov	[jmp17a+2],ax
	mov	[jmp17b],0bbb8h
	mov	[jmp17b+2],ax
	cli
	mov	es,ax
	cld
	mov	di,0bbaeh
	mov	al,far_jmp_opcode
	stosb
	mov	ax,offset i17a
	stosw
	mov	ax,cs
	stosw
	mov	di,0bbb3h
	mov	al,far_jmp_opcode
	stosb
	mov	ax,offset i17b
	stosw
	mov	ax,cs
	stosw
	mov	al,0c3h 		; near ret opcode at bbb8
	stosb
	sti
	pop	es
	pop	ax
	ret
install105 endp

	page
;======================================================================
;.fs
; install107 - i10f0f fix for mosint10
;
; in:	ax -> mos segment
;	es -> scb segment
;
; out:	ax -> mos segment
;
;.fe
;=====================================================================^
	assume	ds:nothing,es:scbx,ss:nothing
install107 proc near
	push	ax
	push	es
	mov	[jmp10a],09dc6h
	mov	[jmp10a+2],ax
	cli
	mov	es,ax
	cld
	mov	di,09db8h
	mov	al,far_jmp_opcode
	stosb
	mov	ax,offset i10a
	stosw
	mov	ax,cs
	stosw
	sti
	pop	es
	pop	ax
	ret
install107 endp



	page
;======================================================================
;.fs
; install109 - outansi fix for mosddcon
;
; in:	ax -> mos segment
;	es -> scb segment
;
; out:	ax -> mos segment
;
;.fe
;=====================================================================^
	assume	ds:nothing,es:scbx,ss:nothing


; The following is a patch table use by routine patcher to patch area
; in MOS that so that they will call int 10h function 3 instead of
; using TCBCPOS  


patch9	label	byte
	dw	3cc5h
	db	5,0e8h,0abh,0feh,90h,90h
	dw	3ce2h
	db	5,0e8h,08eh,0feh,90h,90h
	dw	3ea0h
	db	4,0e8h,0d0h,0fch,90h
	dw	3ec7h
	db	4,0e8h,0a9h,0fch,90h
	dw	3ef6h
	db	4,0e8h,07ah,0fch,90h
	dw	3f21h
	db	4,0e8h,04fh,0fch,90h
	dw	3f60h
	db	4,0e8h,010h,0fch,90h
	dw	3fd4h
	db	4,0e8h,09ch,0fbh,90h
	dw	404bh
	db	4,0e8h,025h,0fbh,90h
	dw	-1


patch9a	label	byte
	dw	3628h
	db	14,036h,8ah,3eh,35h,00h,0b4h,03h,0e8h,10h,0ffh
	db	90h,90h,90h,90h
	dw	-1



install109 proc near
	push	ax
	push	es
	cli
	mov	[jmpansi],03baeh
	mov	[jmpansi+2],ax
	mov	[jmpaout],03c8dh
	mov	[jmpaout+2],ax
	mov	es,ax
	cld
	mov	di,03b6dh
	mov	al,far_jmp_opcode
	stosb
	mov	ax,offset outansi
	stosw
	mov	ax,cs
	stosw
	mov	al,0c3h
	stosb
	sti

	push	ds
	push	si
	push	cx

	push	cs
	pop	ds
	mov	si,offset getcrsx
	mov	cx,sizcrsx
	rep	movsb

	mov	si,offset patch9
	call	patcher			; call patcher

	mov	es,[mo2_seg]
	mov	si,offset patch9a
	call	patcher	
		
	pop	cx
	pop	si
	pop	ds

	pop	es
	pop	ax
	ret
install109 endp

	page
;======================================================================
;.fs
; install111 - setrows
;
; in:	ax -> mos segment
;	es -> scb segment
;
; out:	ax -> mos segment
;
;.fe
;=====================================================================^
	assume	ds:nothing,es:scbx,ss:nothing
install111 proc near
	push	ax
	push	di
	push	es

	mov	es,[mo2_seg]
	mov	di,04e6bh
	mov	al,far_call_opcode
	cli
	stosb
	mov	ax,offset setrows
	stosw
	mov	ax,cs
	stosw
	mov	al,0ebh
	stosb
	mov	al,14h
	stosb
	sti

	pop	es
	pop	di
	pop	ax
	ret
install111 endp

	page
;======================================================================
;.fs
; install112 - cga only itask fix
;
; in:	ax -> mos segment
;	es -> scb segment
;
; out:	ax -> mos segment
;
;.fe
;=====================================================================^
	assume	ds:nothing,es:scbx,ss:nothing
install112 proc near
	push	ax
	push	di
	push	es

	mov	es,ax
	mov	di,0e23fh
	mov	al,60h
	stosb

	pop	es
	pop	di
	pop	ax
	ret
install112 endp

	page
;======================================================================
;.fs
; install113 - 'mos files on'
;
; in:	ax -> mos segment
;	es -> scb segment
;
; out:	ax -> mos segment
;
;.fe
;=====================================================================^
	assume	ds:nothing,es:scbx,ss:nothing
install113 proc near
	push	ax
	push	di
	push	es
	mov	es,[mo2_seg]

; at mo2:2660, plant a far jump to p113_entry
; will take 2660,1,2,3,4

	cld
	mov	di,2660h
	mov	al,far_jmp_opcode
	stosb
	mov	ax,offset p113_entry
	stosw
	mov	ax,cs
	stosw

; at mo2:2665, plant a near call to getthdl 
; followed by a far jump to p113_e2
; will take 2665,6,7,8,9,a,b,c

	mov	di,2665h
	mov	al,0e8h
	stosb
	mov	al,0bbh
	stosb
	mov	al,75h
	stosb
	mov	al,far_jmp_opcode
	stosb
	mov	ax,offset p113a
	stosw
	mov	ax,cs
	stosw

; at mo2:266d, plant a near call to moslim0 
; followed by a far jump to p113_e2
; will take 266d,e,f,2670,1,2,3,4

	mov	di,266dh
	mov	al,0e8h
	stosb
	mov	al,06fh
	stosb
	mov	al,78h
	stosb
	mov	al,far_jmp_opcode
	stosb
	mov	ax,offset p113b
	stosw
	mov	ax,cs
	stosw

; set fj113a to mo2:2665 - the near calling stub for getthdl

	mov	word ptr cs:[fj113a],2665h
	mov	word ptr cs:[fj113a+2],es

; set fj113b to mo2:266d - the near calling stub for moslim0

	mov	word ptr cs:[fj113b],266dh
	mov	word ptr cs:[fj113b+2],es

; set fj113c to mo2:maktfbx (26d4)

	mov	word ptr cs:[fj113c],26d4h
	mov	word ptr cs:[fj113c+2],es

; set fj113d to mo2:2685  (recovery point)

	mov	word ptr cs:[fj113d],2685h
	mov	word ptr cs:[fj113d+2],es

	pop	es
	pop	di
	pop	ax
	ret
install113 endp

	page
;======================================================================
;.fs
; install114 - INT 10h function 0b slowdown fix
;
; in:	ax -> mos segment
;	es -> scb segment
;
; out:	ax -> mos segment
;
;.fe
;=====================================================================^
	assume	ds:nothing,es:scbx,ss:nothing
install114 proc near
	push	ax
	push	di
	push	es

	mov	ax,es
	add	ax,230h
	mov	es,ax
	mov	di,17h
	mov	ax,2bebh		; jmp 44 in patch #1 patch code
	stosw

	pop	es
	pop	di
	pop	ax
	ret
install114 endp

	page
;======================================================================
;.fs
; install115 - INT 10h setmode fix - replaces patch 48
;
; in:	ax -> mos segment
;	es -> scb segment
;
; out:	ax -> mos segment
;
;.fe
;=====================================================================^
	assume	ds:nothing,es:scbx,ss:nothing

pdata15 label	byte
	db      0F6h,046h,000h,080h,074h,004h,0E8h,047h,000h,090h
	db      0C3h,080h,07Ch,011h,059h,075h,037h,09Ch,080h,0E1h
	db      020h,0D0h,0E1h,09Dh,0C3h,0E8h
	db	050h,064h,026h,080h,03Eh,049h,000h,013h,076h,018h
	db	026h,0A0h,04Ah,000h,09ah
poff15a dw	?
pseg15a dw	?
	db      0c3h,000h,026h,0A0h,084h,000h,0FEh
	db	0C0h,03Ch,019h,076h,003h,0A2h
	db	037h,000h,0C3h,0E8h,02Bh,067h,09ah
poff15b dw	?
pseg15b dw	?
	db	0c3h,000h,0C3h,09Ch,080h
	db	0E1h,080h,024h,07Fh,09Dh,0C3h,080h,07Ch,011h,059h
	db      075h,003h,03Ch,0FFh,0C3h,00Ch
	db      080h,038h,0C0h,0C3h,008h,0C8h,0E8h,0E8h,066h,0C3h
dlen15	equ 	($-pdata15)


patch15	label	byte
	dw	0518dh
	db	3,0e8h,0e6h,0afh
	dw	066e3h
	db	3,0e8h,09bh,09ah
	dw	06753h
	db	3,0e8h,07eh,09ah
	dw	067d5h
	db	3,0e8h,0b7h,099h
	dw	067e0h
	db	3,0e8h,0d0h,099h
	dw	-1

	
install115 proc near
	push	ax
	push	di
	push	ds
	push	es

	mov	ax,cs
	mov	[poff15a],offset fix15a
	mov	[pseg15a],ax
	mov	[poff15b],offset fix15b
	mov	[pseg15b],ax

	push	cs
	pop	ds
	mov	ax,es
	add	ax,230h
	mov	es,ax
	mov	si,offset pdata15
	mov	di,176h
	mov	cx,dlen15
	rep	movsb
  
	mov	si,offset patch15
	call	patcher	

	pop	es
	pop	ds
	pop	di
	pop	ax
	ret
install115 endp

	page
;======================================================================
;.fs
; install116 - INT 21h function 06 fix
;
; in:	ax -> mos segment
;	es -> scb segment
;
; out:	ax -> mos segment
;
;.fe
;=====================================================================^
	assume	ds:nothing,es:scbx,ss:nothing
install116 proc near
	push	ax
	push	di
	push	ds
	push	es

	mov	[seg16],ax
  	mov	es,ax
	mov	di,05fd4h
	mov	al,far_call_opcode
	stosb
	mov	ax,offset fix16
	stosw
	mov	ax,cs
	stosw
	mov	al,90h
	stosb

	pop	es
	pop	ds
	pop	di
	pop	ax
	ret
install116 endp

	page
;======================================================================
;.fs
; install117 - sector number boundary fix
;
; in:	ax -> mos segment
;	es -> scb segment
;
; out:	ax -> mos segment
;
;.fe
;=====================================================================^
	assume	ds:nothing,es:scbx,ss:nothing
install117 proc near
	push	es

; convert and add to an adc within blkread

	mov	es,[mo2_seg]
	mov	byte ptr es:[7b03h],56h
	pop	es
	ret
install117 endp

	page
;======================================================================
;.fs
; install118 - sector number boundary fix
;
; in:	ax -> mos segment
;	es -> scb segment
;
; out:	ax -> mos segment
;
;.fe
;=====================================================================^
	assume	ds:nothing,es:scbx,ss:nothing

;====== patch list

patch118 label	byte

; overwrite instruction at start of mositask

	dw	0d593h
	db	5
	db	0feh,006h,0ebh,003h,090h

; overwrite instruction at end of mositask

	dw	0e07eh
	db	4
	db	0feh,00eh,0ebh,003h

; modify patch of i15suspend

	dw	011c8h
	db	2
	db	000h,075h

; modify patch of splclose, 1st section

	dw	094eeh
	db	17
	db	006h,02eh,08eh,006h,08ah,010h,026h,0feh
	db	006h,0ebh,003h,0e8h,09eh,028h,0e9h,0c2h
	db	029h
		  
; modify patch of splclose, 2nd section

	dw	09508h
	db	14
	db	0e8h,0c6h,02ah,026h,0feh,00eh,0ebh,003h
	db	05bh,09dh,007h,0e9h,0c0h,029h

; end of list

	dw	0ffffh

;====== end of patch list

	
install118 proc near
	pushset	ax,cx,di,es
  	mov	es,ax
	cld
	cli				; no int8s here, could call getkeys

; make kernel jump far to new getkeys call prolog

	mov	[return118a],es
	mov	di,0cd4ah
	mov	al,far_jmp_opcode
	stosb
	mov	ax,offset enter118a
	stosw
	mov	ax,cs
	stosw

; make kernel jump far to new getkeys call epilog

	mov	[return118b],es
	mov	di,0cd53h
	mov	al,far_jmp_opcode
	stosb
	mov	ax,offset enter118b
	stosw
	mov	ax,cs
	stosw

; make kernel jump far to new int5 calling logic

	mov	[return118c],es
	mov	di,0a1a6h
	mov	al,far_jmp_opcode
	stosb
	mov	ax,offset enter118c
	stosw
	mov	ax,cs
	stosw

; change chk_bdbgate from calling suspend to calling suspend2

	mov	es,cs:[mo2_seg]
	mov	word ptr es:[8182h],0ca06h

; change todriver's gate from calling suspend to calling suspend2

	mov	word ptr es:[7597h],0ca06h

; done with interrupt sensitive patching

	sti

; patch changes into mositask, i15suspend and splclose

	mov	es,cs:[mos_seg]
	mov	si,offset patch118
	call	patcher	

; remove the old code in mosinit2 which will re-init scbfar21.
; 410_p7.pat added new init code for this but didn't blank out 
; the old code.  as a result, if you intercept scbfar21 from
; a device driver, the old code later on within mosinit2 will
; overwrite your new value.

; at the time device drivers are called for initialization, the
; high word of tcbdta ponits to the init code segment.

	mov	es,[scb_seg]
	assume	es:scbx
	mov	es,[scbtcbpf]
	assume	es:tcb
	mov	es,word ptr [tcbdta+2]
	mov	di,1db5h
	mov	cx,12
	mov	al,90h
	cld
	rep	stosb

	popset	ax,cx,di,es
	ret
install118 endp


	page
;======================================================================
;.fs
; install119 - 'EXE' device driver patch
;
; in:	ax -> mos segment
;	es -> scb segment
;
; out:	ax -> mos segment
;
;.fe
;=====================================================================^
	assume	ds:nothing,es:scbx,ss:nothing
install119 proc	near
	push	ax
	push	di
	push	es
	mov	es,[InitSeg]

	mov	di,258ch
	cli
	cld
	mov	al,far_call_opcode
	stosb
	mov	ax,offset PatchEXE
	stosw
	mov	ax,cs
	stosw
	mov	al,90h
	stosb
	mov	al,56h
	stosb
	mov	di,24f3h
	mov	al,far_call_opcode
	stosb
	mov	ax,offset SetIcnfsiz
	stosw
	mov	ax,cs
	stosw
	sti
	pop	es
	pop	di
	pop	ax
	ret
install119 endp

	page
;======================================================================
;.fs
; install120 - trailing space - exec fix
;
; in:	ax -> mos segment
;	es -> scb segment
;
; out:	ax -> mos segment
;
;.fe
;=====================================================================^
	assume	ds:nothing,es:scbx,ss:nothing
install120 proc near
	push	ax
	push	es
	mov	[seg120a],ax
	mov	[seg120b],ax
	mov	es,ax
	mov	di,534dh
	mov	al,far_jmp_opcode
	cli
	stosb
	mov	ax,offset fix120
	stosw
	mov	ax,cs
	stosw
	sti
	mov	di,5365h
	mov	al,far_call_opcode
	cli
	stosb
	mov	ax,offset fix120a
	stosw
	mov	ax,cs
	stosw
	sti


	pop	es
	pop	ax
	ret
install120 endp


	page
;======================================================================
;.fs
; install121 - cursor scroll problem
;
; in:	ax -> mos segment
;	es -> scb segment
;
; out:	ax -> mos segment
;
;.fe
;=====================================================================^
	assume	ds:nothing,es:scbx,ss:nothing
install121 proc near
	push	ax
	push	es

	mov	[seg121a],ax
	mov	[seg121b],ax
	mov	es,ax
	mov	di,0cb2dh
	mov	al,far_jmp_opcode
	cli
	stosb
	mov	ax,offset fix121
	stosw
	mov	ax,cs
	stosw
	sti

	pop	es
	pop	ax
	ret
install121 endp


	page
;======================================================================
;.fs
; install122 - 40:17 Fix  (-K disables this correction)
;
; in:	ax -> mos segment
;	es -> scb segment
;
; out:	ax -> mos segment
;
;.fe
;=====================================================================^
	assume	ds:nothing,es:scbx,ss:nothing
install122 proc near
	cmp	[OptionK],'Y'
	jne	Do22
	ret
Do22:
	pushf
	cli
	push	ax
	push	es

	mov	[scbkbbios],'Y'		; set kbbios to yes for unterm.sys

;
; handle stuff in MO2 and SCB segments first
;
	push	ax
 	mov	ax,es		; get GRP
	add	ax,230h		; point to MO2
	mov	es,ax
;
; change biosint9 logic so it clear 5 for io protection too...
;
	mov	byte ptr es:[627bh],0ech
;
; jump over unneeded change in lidtint09
;
	mov	word ptr es:[631ch],05ebh
;
;
; handle patch in inside of inkbdate inside mosddtmc.asm
;
	mov	di,066a6h
	mov	al,far_call_opcode
	stosb
	mov	ax,offset Fix122d
	stosw
	mov	ax,cs
	stosw
;
; jump over unneeded change in register function inside mosddtmc.asm
;
	mov	word ptr es:[6646h],0aebh
;
	pop	ax
;
; handle stuff in MOS segment now
;
	mov	[seg122a],ax
	mov	[seg122b],ax
	mov	[seg122c],ax
	mov	word ptr [ddtfar+2],ax
	mov	word ptr [ddtfar],0a1f8h
	mov	es,ax
;
; added routine to initialized tcbcon417 inside inittcb routine in 
; mositask.asm
;
	mov	di,0e29bh
	mov	al,far_call_opcode
	stosb
	mov	ax,offset Fix122a
	stosw
	mov	ax,cs
	stosw
	mov	ax,9090h		; NOP NOP
	stosw
;
; added routine to force getkeys to be call inside tsl (mosnxtsk) if
; tcbcon417 is -1
;
	mov	di,0cc23h
	mov	al,far_call_opcode
	stosb
	mov	ax,offset Fix122b
	stosw
	mov	ax,cs
	stosw
	mov	al,90h		; NOP
	stosb
;
;
; added routine to initialized tcbcon417 from 40:17 inside 
; savcntxt (moscntxt)
;
	mov	di,827ah
	mov	al,far_call_opcode
	stosb
	mov	ax,offset Fix122c
	stosw
	mov	ax,cs
	stosw
;
; added routine to replace code in getddkey for getting keyboard input
;
	mov	di,0a1e5h
	mov	al,far_jmp_opcode
	stosb
	mov	ax,offset Fix122e
  	stosw
	mov	ax,cs
	stosw
	mov	byte ptr es:[0a1fbh],0cbh
;
; add routine to update tcbkbshft from 40:17 before calling scanguts
;
	mov	di,0a5b9h
	mov	al,far_call_opcode
	stosb
	mov	ax,offset Fix122f
	stosw
	mov	ax,cs
	stosw
;
	mov	byte ptr es:[0a68dh],0ebh
	pop	es
	pop	ax
	popf
	ret
install122 endp


	page
;======================================================================
;.fs
; install123 - Brief Exec Fix  (-E disables this correction)
;
; in:	ax -> mos segment
;	es -> scb segment
;
; out:	ax -> mos segment
;
;.fe
;=====================================================================^
	assume	ds:nothing,es:scbx,ss:nothing
install123 proc near
	cmp	[OptionE],'Y'
	jne	Do23
	ret
Do23:
	pushf
	cli
	push	ax
	push	es

	mov	es,ax
	mov	di,5858h
	mov	al,far_call_opcode
	stosb
	mov	ax,offset Fix123
	stosw
	mov	ax,cs
	stosw

	pop	es
	pop	ax
	popf
	ret
install123 endp

	page
;======================================================================
;.fs
; install125 - MOS MAP correction
;
; in:	ax -> mos segment
;	es -> scb segment
;
; out:	ax -> mos segment
;
;.fe
;=====================================================================^
	assume	ds:nothing,es:scbx,ss:nothing
install125 proc near
	pushf
	cli
	push	ax
	push	es
	mov	es,ax

; added routine to initialized tcbprgnm inside inittcb routine in 
; mositask.asm

	mov	di,0e2a2h
	mov	al,9ah			; call xxxx:xxxx
	stosb
	mov	ax,offset Fix125a
	stosw
	mov	ax,cs
	stosw
	mov	al,90h		; NOP 
	stosb

; patch in the new access to tcbbatnm at 760h

	mov	word ptr es:[0d580h],0760h	
	mov	word ptr es:[0d585h],0762h	
	mov	word ptr es:[0dd26h],0760h	
	mov	word ptr es:[0dd96h],0760h	
	pop	es
	pop	ax
	popf
	ret
install125 endp

	page
;======================================================================
;.fs
; install126 - Don't allow pamswitching to alt 999 task
;
; in:	ax -> mos segment
;	es -> scb segment
;
; out:	ax -> mos segment
;
;.fe
;=====================================================================^
	assume	ds:nothing,es:scbx,ss:nothing
install126 proc near
	pushf
	cli
	push	ax
	push	es


	mov	es,ax
	mov	[seg126a],ax
	mov	[seg126b],ax
	mov	di,0b9b2h
	mov	al,0eah
	stosb
	mov	ax,offset Fix126a
	stosw
	mov	ax,cs
	stosw

	pop	es
	pop	ax
	popf
	ret
install126 endp

	page
;======================================================================
;.fs
; install127 - dbts/prtsc corrections and corrections to the 1.01
; patch code (foxpro/i21f67).
;
; in:	ax -> mos segment
;	es -> scb segment
;
; out:	ax -> mos segment
;
;.fe
;=====================================================================^
	assume	ds:nothing,es:scbx,ss:nothing

;====== patch list

patch127 label	byte

; near tsl050:
; call savecrit, call getkeys, call restorcrit, retf

	dw	094bfh
	db	10
	db	0e8h,080h,030h,0e8h,092h,00ch,0e8h,0aah
	db	030h,0cbh

; convert suspend2 and suspend entry points

	dw	0ca06h
	db	39
	db	01eh,02eh,08eh,01eh,08ah,010h,036h,0ffh
	db	036h,08ah,000h,0e8h,036h,000h,036h,08fh
	db	006h,08ah,000h,01fh,0c3h,01eh,02eh,08eh
	db	01eh,08ah,010h,080h,03eh,092h,010h,000h
	db	075h,003h,0e8h,01fh,000h,01fh,0c3h

	dw	0ca3eh
	db	2
	db	0ebh,0dbh

	dw	0ca4ah
	db	1
	db	01eh

; convert inc/dec of intsl flag

	dw	0ca64h
	db	5
	db	0feh,006h,092h,010h,090h

	dw	0cadbh
	db	5
	db	0feh,006h,092h,010h,090h

	dw	0cd98h
	db	5
	db	0feh,00eh,092h,010h,090h

; end of list marker

	dw	0ffffh

;====== end of patch list

install127 proc near
	pushf
	cli
	push	es
	push	ax
	mov	es,ax
	mov	cs:[s127_a],es
	mov	cs:[s127_b],es
	mov	di,94bah
	mov	al,far_jmp_opcode
	stosb
	mov	ax,offset fix127_a
	stosw
	mov	ax,cs
	stosw
	mov	si,offset patch127
	call	patcher	
	pop	ax
	pop	es
	popf
	ret
install127 endp


	page
;======================================================================
;.fs
; install128 - Correctly handle Function 58's Last Fit for function 48
;
; in:	ax -> mos segment
;	es -> scb segment
;
; out:	ax -> mos segment
;
;.fe
;
; Note: This patch can be disable with -L
;=====================================================================^
	assume	ds:nothing,es:scbx,ss:nothing
install128 proc near
	cmp	[OptionL],'Y'
	jne	do128
	ret
do128:
	pushf
	cli
	push	ax
	push	es

	mov	[seg128a],ax
	mov	[seg128b],ax
	mov	[seg128c],ax
	mov	[seg128d],ax
	mov	[seg128e],ax
	mov	[seg128f],ax

	mov	es,ax

	mov	di,506dh
	mov	al,far_call_opcode
	stosb
	mov	ax,offset fix128a
	stosw
	mov	ax,cs
	stosw

	mov	di,508bh
	mov	al,far_jmp_opcode
	stosb
	mov	ax,offset fix128b
	stosw
	mov	ax,cs
	stosw

	mov	di,5098h
	mov	ax,9090h
	stosw
	stosb

	mov	di,50a2h
	mov	al,far_jmp_opcode
	stosb
	mov	ax,offset fix128c
	stosw
	mov	ax,cs
	stosw

	mov	di,50dch
	mov	al,far_jmp_opcode
	stosb
	mov	ax,offset fix128d
	stosw
	mov	ax,cs
	stosw
	mov	ax,9090h			; need 3 nop's
	stosw
	stosb

	pop	es
	pop	ax
	popf
	ret
install128 endp


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
	cmp	[OptionI],'Y'
	jne	do203
	ret
do203:
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

;======================================================================
;.fs
; install204 - modify flush24 action
;
; in:	ax -> mos segment
;	es -> scb segment
;
; out:	ax -> mos segment
;
;.fe
;
;=====================================================================^
	assume	ds:nothing,es:scbx,ss:nothing

plist204 label byte
	dw	095h
	db	19
	db	036h,0c6h,006h,066h,007h,001h,080h,0e4h
	db	0bfh,0e8h,0ceh,076h,036h,0c6h,006h,066h
	db	007h,000h,0c3h
	dw	0ffffh		; end of list marker

install204 proc	near
	push	es
	mov	es,[mo2_seg]
	mov	si,offset plist204
	call	patcher
	pop	es
	ret
install204 endp

;======================================================================
;.fs
; install202b - protection for dopoll and vidrams cals within suspend
;
; in:	ax -> mos segment
;	es -> scb segment
;
; out:	ax -> mos segment
;
;.fe
;
;=====================================================================^
	assume	ds:nothing,es:scbx,ss:nothing

plist202b label byte
	dw	0c26ch		; just past the far jump instruction
	db	60
	db	0FAh,080h,03Eh,096h,004h,000h,075h,014h
	db	0C6h,006h,096h,004h,001h,0FBh,0E8h,0C5h
	db	002h,0E8h,0F6h,0A6h,0E8h,0EFh,002h,0C6h
	db	006h,096h,004h,000h,0FBh,0C3h,0FAh,080h
	db	03Eh,095h,004h,000h,075h,014h,0C6h,006h
	db	095h,004h,001h,0FBh,0E8h,0A7h,002h,0E8h
	db	0EEh,0DBh,0E8h,0D1h,002h,0C6h,006h,095h
	db	004h,000h,0FBh,0C3h

	dw	0cc34h
	db	3
	db	0e8h,035h,0f6h

	dw	0cd58h
	db	3
	db	0e8h,011h,0f5h

	dw	0caa5h
	db	3
	db	0e8h,0e2h,0f7h

	dw	0ffffh		; end of list marker

install202b proc near
	cli				; no irq0s while patching int8 logic
	push	ax
	push	es
	cld
	mov	es,ax
	mov	di,0c267h
	mov	al,far_jmp_opcode
	stosb
	mov	ax,offset fix202b
	stosw
	mov	ax,cs
	stosw

	mov	si,offset plist202b
	call	patcher
	pop	es
	pop	ax
	ret
install202b endp

;======================================================================
;.fs
; install207 - protection for dopoll and vidrams cals within suspend
;
; in:	ax -> mos segment
;	es -> scb segment
;
; out:	ax -> mos segment
;
;.fe
;
;=====================================================================^
	assume	ds:nothing,es:scbx,ss:nothing

plist207 label byte
	dw	086a5h
	db	4
	db	0e8h,084h,0fdh,0cbh

	dw	086aeh
	db	1
	db	0cbh

	dw	086bah
	db	1
	db	0cbh

	dw	0ffffh		; end of list marker

install207 proc near
	cli				; no irq0s while patching int8 logic

	push	ax
	push	es
	cld
	mov	es,ax

	mov	[seg207a],ax
	mov	[seg207b],ax
	mov	[seg207c],ax
	mov	[seg207d],ax

	mov	di,086a0h
	mov	al,far_jmp_opcode
	stosb
	mov	ax,offset fix207p1
	stosw
	mov	ax,cs
	stosw
	
	mov	di,086b0h
	mov	al,far_jmp_opcode
	stosb
	mov	ax,offset fix207p2
	stosw
	mov	ax,cs
	stosw
	
	mov	si,offset plist207
	call	patcher

	pop	es
	pop	ax
	ret
install207 endp

	page
;======================================================================
;.fs
; patcher
;
; generic table driven patcher routine
;
; in:	cs:si-> patch list:   (terminated with offset of ffffh)
;
;	  offset  size   description
;	  ------  ----   -----------
;	    0	  word   offset to start patching
;	    2	  byte   size of array 
;	    3     var	 array of above size
;           
;	es -> code segment to patch
;	     0
; out:	
;
;.fe
;=====================================================================^
	assume	ds:nothing,es:nothing,ss:nothing
patcher proc	near
	push	ds
	push	si
	push	di
	push	ax
	push	cx
	push	cs
	pop	ds	
	cld
patchlp:
	lodsw
	cmp	ax,-1		; are we at end
	je	patchend
	mov	di,ax
	lodsb
	mov     cl,al		; get size
	or	cl,cl
	jz	patchlp		; should never happen but allow for it
	xor	ch,ch
	rep	movsb		; move array
	jmp	short patchlp
patchend:	
	pop	cx
	pop	ax
	pop	di
	pop	si
	pop	ds
	ret
patcher	endp

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

	subttl ParseCmd - Parse command line
	page
;======================================================================
;.fs
; ParseCmd - Parse Command Line
;
; Parses command Line, check for options
; current supported options:
;	-K     =   Disable 40:17 Fix (Ver 1.22)
;
; in:	none
;
; out:	none
;
;.fe
;=====================================================================^
	assume	ds:nothing,es:nothing,ss:nothing
ParseCmd proc	near
	push	ax
	push	bx
	push	si
	push	di
	push	ds
	push	es

	les	bx,[request]
	lds	si,es:[bx+18]		; -> device driver command line
	cld
ParseLoop:
	mov	di,si
	lodsb
	cmp	al,13
	je	ParseExit
	or	al,al
	jz	ParseExit
	cmp	al,'-'
	je	DoOption
	cmp	al,'/'
	je	DoOption
	cmp	al,'\'
	je	ParseLoop
DoOption:
	mov	al,byte ptr ds:[si]
	and	al,0dfh
	cmp	al,'K'
	jne	SkipOptK
	mov	[OptionK],'Y'
	jmp	short ClearOption
SkipOptK:
	cmp	al,'E'
	jne	SkipOptE
	mov	[OptionE],'Y'
	jmp	short ClearOption
SkipOptE:
	cmp	al,'L'
	jne	SkipOptL
	mov	[OptionL],'Y'
	jmp	short ClearOption
SkipOptL:
	cmp	al,'I'
	jne	SkipOptI
	mov	[OptionI],'Y'
	jmp	short ClearOption
SkipOptI:
	jmp	short ParseLoop	
ClearOption:
	mov	word ptr ds:[di],2020h
	jmp	short ParseLoop
ParseExit:		
	pop	es
	pop	ds
	pop	di
	pop	si
	pop	bx
	pop	ax
	ret
ParseCmd endp

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
	call	ParseCmd

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


; make sure patches 1, 3-35 and 37-49 have been applied (pl4)

; at the time device drivers are called for initialization, the
; high word of tcbdta ponits to the init code segment.

	pushset	ax,cx,di,es
	mov	es,es:[scbtcbpf]
	mov	es,word ptr es:[tcbdta+2]
	mov	[InitSeg],es
	cmp	byte ptr es:[03e2h],'Y'	; patch 1?
	jne	not_pl4
	mov	al,'Y'
	cld
	mov	di,03e4h
	mov	cx,33
	repe	scasb			; patches 3-35?
	jne	not_pl4
	mov	di,0406h
	mov	cx,13
	repe	scasb
	jne	not_pl4
	popset	ax,cx,di,es
	jmp	short is_pl4
not_pl4:
	popset	ax,cx,di,es
	mov	dx,offset notpl4
	xor	cx,cx
	jmp	initx

; check to see if code is correct

is_pl4:
	mov	si,offset chk100 	; int16      (ver 1.00/1.06)
	call	chk_code
	jnz	badcode
	mov	si,offset chk101 	; int21fun67 (ver 1.01)
	call	chk_code
	jnz	badcode
	mov	si,offset chk103 	; int13      (ver 1.02/1.03)
	call	chk_code
	jnz	badcode
	mov	si,offset chk104	; prn (17)   (ver 1.04/1.08)
	call	chk_code
	jnz	badcode
	mov	si,offset chk105	; i17com/coms (ver 1.05)
	call	chk_code
	jnz	badcode
	mov	si,offset chk107	; i10f0f (ver 1.07)
	call	chk_code
	jnz	badcode
	mov	si,offset chk109	; outansi (ver 1.09/1.10)
	call	chk_code
	jnz	badcode
	push	ax
	mov	ax,[mo2_seg]
	mov	si,offset chk113	; 'mos files on'
	call	chk_code
	pop	ax
	jnz	badcode
	jmp	short goodcode
badcode:
	mov	dx,offset notmos410
	xor	cx,cx
	jmp	initx
goodcode:

; install the patches

	call	install100		; int16       (ver 1.00/1.06)
	call	install101		; int21fun67  (ver 1.01)
	call	install103		; int13       (ver 1.02/1.03)
	call	install104		; prn (17)    (ver 1.04/1.08)
	call	install105		; i17com/coms (ver 1.05)
	call	install107		; i10f0f      (ver 1.07/2.00)
	call	install109		; outansi     (ver 1.09/1.10)
	call	install111		; setrows     (ver 1.11)
	call	install112		;	      (ver 1.12)
	call	install113		; 'mos files on' (ver 1.13)
	call	install114		; fix10_0b    (ver 1.14)
	call	install115		; fix15a/15b  (ver 1.15)
	call	install116		; fix16	      (ver 1.16)
	call	install117		; sector number boundary (ver 1.17)
	call	install118		; disk corruption while spooling
	call	install119		; 'EXE' device drivers (Ver 1.19)
	call	install120		; trailing space exec (Ver 1.20)
	call	install121		; cursor scroll problem (Ver 1.21)
	call	install122		; 40:17 Fix!	(Ver 1.22)
	call	install123		; Brief EXEC fix  (ver 1.23)

; version 1.24 was skipped on purpose

	call	install125		; MOS MAP fix	(Ver 1.25)
	call	install126		; Alt 999 fix   (Ver 1.26)	
	call	install127		; dbts/prtsc and i21f67 (ver 1.27)
	call	install128		; Last Fit Correction (Ver 1.28)

	call	Install203		; Infinite LPT Retry (Ver 2.03)
	call	Install204		; cacheing critical error


	call	install202b		; protection for dopoll and vidram
					; calls within suspend. (Ver 2.05)

; version 2.05 was used to re-activate versions 2.03/04

; version 2.06 consists of modifications to the int16 logic
; (already contained within this patch driver)

	call	install207		; dbts/user i15 icept/switchtask


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