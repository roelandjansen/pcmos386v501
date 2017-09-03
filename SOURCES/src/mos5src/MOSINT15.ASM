	include page.inc
	title	mosint15.asm - mos interupt 15 interface
comment ^===============================================================
		       development specification

 program name:	mosint15.asm		assigned to: stewart hyde
 module name:	mosint15		assign date: 01/18/90
 entry points:	mosterm 		completed:   01/18/90
 entry from:	mosint10, mosint16, mosvidrm
 entry method:	call dword [vector] with ah = function number
 calls:		i10old (boot interrupt 10h)
 purpose:	mos interface to interupt 15						software compatible)					;
 refer to:	n/a
 last update:	08/18/1992
========================================================================

mjs 02/26/90	add disk busy task switching logic

mjs 03/14/90	correct bugs in timparm/timchk handling

mjs 03/27/90	mod to re=instate trapping for p40, p41, p43, p61
		mod to clear scb15post after find it high instead of
		clearing it in the int15fun90 handler.  it is possible
		for the irq6/14 to occur before int15fun90 gets
		called.

mjs 09/21/90	added test of scbi15ita within i15suspend.  when 
		mositask is building a new task, this flag will be
		non-zero and will prevent disk busy task switching.

sah 10/11/90	corrections for everex step 386 and kbrate logic
		added re-instate trapping for p60 and p64

sah 01/30/91	set scb15tcb to current tasks with suspending task 
		because of int 15 suspension logic

mjs 10/07/91	fix dbts/prtsc bugs (patch410.118).
		rename scbi15ita to i15off.  change sense of test
		because this is now an increment/decrement flag.

================ 5.01 kernel ends here ====================================

mjs 08/18/92	clean up segment declarations

=======================================================================^

.xlist
	include mosint15.pub
	include group.inc
	include	macros.inc
	include mosregs.inc

tcb	segment at 1234h
	include mostcb.inc	; tcb definition
tcb	ends

gdata	segment
	include mosscbex.inc	; specify all scb items as external
gdata	ends
.list

irq	segment
	dw	15h*4		; bios services we want to control
i15old	dd	?
	dw	0		; we don't save changes, we leave them alone
	dw	mosint15	; offset of handler
	dw	0		; don't change back if application changes it
irq	ends

;======================================================== ddt segment
if 0 eq 0
segment_num = 2
endif
ddt	segment
	extrn	cmap:near
ddt	ends

;======================================================== mos segment
if 0 eq 0
segment_num = 1
endif
mosseg	segment
	assume	cs:mos,ds:nothing,es:nothing,ss:nothing

	extrn	moucall:far, reordlst:near
	extrn 	suspend2:near, timparm:near, timchk:near, chkslice:near

	subttl	mosint15 - bios services we want to control
	page
;======================================================================
;,fs
; mosint15 - bios services we want to control
;
; in:	
;
; out:	
;
;,fe
;======================================================================
	assume	cs:mos,ds:nothing,es:nothing,ss:nothing
	public	mosint15
mosint15 proc far
	cli
	pushf
	cmp	ah,4fh 
	jne	m15p1 
	popf
	iret
m15p1:
	cmp	ah,87h 			; if 87, 88 or 89
	jnae	m15p2 
	cmp	ah,89h 
	jnbe	m15p2 
	push	ds
	mgetscb	ds
	assume	ds:grp
	cmp	[scbmmfg],'Y'
	pop	ds
	assume	ds:nothing
	ljne	m15p3
	popf
	cmp	ah,87h 
	jne	m15p4 
	mov	ax,2			; error signal for 87
	stc
	jmp 	m15p5			; return with current flags
m15p4:
	cmp	ah,88h 
	jne	m15p6 
	xor	ax,ax			; dummy return value for 88
	stc
	jmp	m15p5			; return with current flags
m15p6:
	mov	ah,0ffh			; must be fun89
	stc
	jmp	m15p5			; return with current flags
m15p2:
	cmp	ax,9000h 		; disk busy call
	je	m15p1b
	cmp	ax,9001h 
	jne	m15p7 
m15p1b: 
	popf
	call	i15suspend		; task switch during disk waits
	clc				; make the bios do its own testing
	pushf
	jmp	m15p3			; have to pass on - zenith quirk
m15p7:
	cmp	ax,9100h 		; disk post call
	je	m15p7a
	cmp	ax,9101h 
	jne	m15p9 
m15p7a: 
	popf				; recover entry flags
	push	ds
	mgetscb	ds
	assume	ds:grp
	mov	[scb15post],1		; let i15poll know the disk is ready
	pushf
	call	dword ptr [i15old]	; let the bios do its thing
	pop	ds
	assume	ds:nothing
	iret
m15p9:
	cmp	ax,0c207h 		; configuration call
	jne	m15p3
	popf
	pushset	bx,ds,es
	mgetscb	ds
	assume	ds:grp
	mov	ax,[scbtcbpc]
	mov	[scbmoutcb],ax		; set mouse tcb to current tcb
	mov	word ptr [scbmouse],bx
	mov	word ptr [scbmouse+2],es ; save use far call routine
	mov	bx,cs
	mov	es,bx
	mov	bx,offset moucall	; set our far call routine instead
	mov	ax,0c207h
	pushf
	call	dword ptr [i15old]	; call old 15 flags alread pushed
	popset	bx,ds,es
	jmp	short m15p5		; return with current flags
m15p3:

; if reach this point, call the original int15 bios

	popf				; have original flags 	
	push	ds			; (just for good measure)
	mgetscb	ds
	assume	ds:grp
	pushf
	call	dword ptr [i15old]
	pop	ds
	assume	ds:nothing
m15p5:

; return with current flags

	retf 2
mosint15 endp

	subttl i15suspend - handle a disk busy task switch
	page
;======================================================================
;,fs
; i15suspend - handle a disk busy task switch
;
; switch to tcb stack, setup for timeout and call suspend.
; this is done to give other tasks some execution time during 
; disk wait operation.
;
; in:	
;
; out:	
;
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:nothing
i15suspend proc near
	pushset	di,bp,ds,es
	MGetSCB	ds
	assume	ds:grp
	sti
	cmp	[scbi15tsl],'Y'		; skip if config.sys parm used
	jne	m15p11a
	cmp	[scbi15off],0		; suppress dbts logic?
	jne	m15p11a
	mov	es,[scbtcbpc]
 	assume	es:tcb
m15p12b:
	cmp	[tcbslcnt],0		; if slice is up, call tsl
	je	m15p12a
	cmp	[scb15post],0 		; if haven't had fun91 yet, 
	je	m15p12b			; keep polling
	mov	[scb15post],0		; clear when find high
m15p11a:
	jmp	m15p11			; else, exit back to bios
m15p12a:
	mov	bp,sp			; save current sp
	mov	di,ss			; save current ss
	cmp	di,[scbtcbpc]		; if not already on tcb stack
	je	m15p12 
	cli
	mov	ss,[scbtcbpc]		; new stack
	assume	es:nothing,ss:tcb
	mov	sp,[tcbstkp]
	sti
m15p12:
	push	di			; old ss
	push	bp			; old sp
	pushset	ax,cx,si,di,es
	mov	cx,ss
	mov	es,cx
	mov	ax,10*18
	mov	cl,20h			; bit position in tcbwtflg
	call	timparm			; setup time out data
	mov	[tcb15ax],ax
	mov	[tcb15cx],cx

; save cache context

	push	[scbccur]
	push	[scbcnxt]
	sub	sp,16
	mov	di,sp
	mov	si,offset scbcsave
	mov	cx,16/2			; es is pointing to the stack
	rep	movsw			; from the timparm parm setup

; re-instate i/o trapping state for p40, p41, p43, p60, p61, and p64

	test	[scbmmfea],40h		; io protection supported?
	jz	m15p13a
	pushset	ax,si,es
	les	si,[scbmmptr]		; get pointer to memman data
	les	si,dword ptr es:[si].parmiop
	mov	al,[scbtfix1]
	or	byte ptr es:[si+8],al	; restore 
	mov	al,[scbtfix2]
	or	byte ptr es:[si+12],al
m15p13a:

; suspend during disk wait to give other tasks some cpu time

	mov	[scb15act],1		; activate the bdb gate
	mov	[scb15tcb],ss		; save task for reference
	mov	word ptr [tcbpoll],offset mos:i15poll
	mov	word ptr [tcbpoll+2],cs
	and	[tcbwait],not 2		; clear b1
	or	[tcbwait],5		; set b0 and b2
	call	suspend2		; call in mos segment
	mov	[scb15act],0		; deactivate the bdb gate

; restore i/o trapping state for p40, p41, p43, p60, p61, and p64

	test	[scbmmfea],40h		; io protection supported?
	jz	m15p13b
	and	byte ptr es:[si+8],not 00001101b  ; clear p40, p41, p43
	and	byte ptr es:[si+12],not 00010011b  ; clear p60, p61, p64
	popset	ax,si,es
m15p13b:

; restore cache context

	mov	cx,ds
	mov	es,cx
	assume	ds:nothing,es:grp
	mov	cx,sp
	push	ds
	mov	si,cx
	mov	di,offset scbcsave
	mov	cx,ss
	mov	ds,cx
	mov	cx,16/2
	rep	movsw
	pop	ds
	assume	ds:grp,es:nothing
	add	sp,16
	pop	[scbcnxt]
	pop	di
	mov	es,[scbclst]
	assume	es:nothing
	callmos2 cmap			; setting [scbcele] & [scbccur] also

; ax and es now destroyed by cmap

	popset	ax,cx,si,di,es
	pop	bp			; old sp
	cli
	pop	ss			; old ss (pushed in di)
	mov	sp,bp
	sti
m15p11:
	popset	di,bp,ds,es
	ret
i15suspend endp

	subttl i15poll - suspend/poll routine for disk busy task switching
	page
;======================================================================
;,fs
; i15poll - suspend/poll routine for disk busy task switching
;
; determine if a task should be re-awakened because its disk 
; operation is complete or if a timeout has occured.
;
; in:	ss -> tcb
;	ds -> grp
;
; out:	al == 0 if can awake
;	al == 1 if still need to suspend
;
;,fe
;======================================================================
	assume	ds:grp,es:nothing,ss:tcb 
i15poll proc far
	pushset	bx,cx,es
	xor	bl,bl			; preset for wakeup
	cmp	[scb15post],0 		; disk event complete?
	je	m15p18a
	mov	[scb15post],0		; clear when find high
	jmp	short m15p18
m15p18a:
	mov	bl,1			; stay asleep
	mov	ax,ss
	mov	es,ax
	mov	ax,[tcb15ax]
	mov	cx,[tcb15cx]
	call	timchk
	jnz	m15p18
	xor	bl,bl			; wakeup due to timeout
m15p18:
	mov	al,bl
	popset	bx,cx,es
	retf
i15poll endp

mosseg	ends
	end

