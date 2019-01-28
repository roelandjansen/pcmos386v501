	include page.inc
	title	mostemp.asm - temp mos module
	extrn bugerror:near
comment ^===============================================================
		    development specification

 program name:	mosmisc.asm		assigned to: stewart hyde
 module name:	mosmisc 		assign date: 01/22/90
 entry points:	n/a			completed:   01/22/90
 entry from:	n/a
 entry method:	n/a
 calls:		n/a
 purpose:	provide misc utility routines for pc-mos
 refer to:	n/a
 last update:	08/18/1992
========================================================================

================ 5.01 Kernel Ends Here ====================================

mjs 08/18/92	clean up segment declarations

======================================================================^

.xlist
;	include mosmisc.pub
	include group.inc
	include mosregs.inc
	include macros.inc

tcb	segment at 1234h
	include mostcb.inc
tcb	ends

gdata	segment
	include mosscbex.inc
gdata	ends
.list

;======================================================== ddt segment
if 0 eq 0
segment_num = 2
endif
ddt	segment
	assume	cs:mo2,ds:nothing,es:nothing,ss:nothing

	subttl wordmov - cpu optimized block move
	page
;======================================================================
;,fs
; wordmov - cpu optimized block move
;
; this procedure is use to take advantage of 386/486 32 bit
; instructions if processor is present
;
; in:	
;
; out:	
;
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:nothing
	public	wordmov
wordmov proc	near
	pushf				; some replacement might depend on carry
	push	ds
	mgetscb2 ds
	assume	ds:grp
	cmp	[scbreg32],'Y'		; 386/486 cpu
	pop	ds
	assume	ds:nothing
	jne	wrd16
	cmp	cx,4
	jb	wrd16

; handle the block move on 386/486 cpus

	shr	cx,1
	db	66h
	rep	movsw			; 32 bit move
	jnc	skp32
	movsw				; move final word
skp32:
	popf
	ret

; handle the block copy on a 8088/286 cpu's

wrd16:
	rep	movsw
	popf
	ret
wordmov endp

ddt	ends

;======================================================== mos segment
if 0 eq 0
segment_num = 1
endif
mosseg	segment
	assume	cs:mos,ds:grp,es:nothing,ss:tcb

	subttl wordmove - cpu optimized block move
	page
;======================================================================
;,fs
; wordmove - cpu optimized block move
;
; this procedure is use to take advantage of 386/486 32 bit
; instructions if processor is present
;
; in:	
;
; out:	
;
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:nothing
	public	wordmove
wordmove proc	near
	pushf				; some replacement might depend on carry
	push	ds
	mgetscb ds
	assume	ds:grp
	cmp	[scbreg32],'Y'		; 386/486 cpu
	pop	ds
	assume	ds:nothing
	jne	word16
	cmp	cx,4
	jb	word16

; handle the block move on 386/486 cpus

	shr	cx,1
	db	66h
	rep	movsw			; 32 bit move
	jnc	skip32
	movsw				; move final word
skip32:
	popf
	ret

; handle the block copy on a 8088/286 cpu's

word16:
	rep	movsw
	popf
	ret
wordmove endp

mosseg	ends
	end

