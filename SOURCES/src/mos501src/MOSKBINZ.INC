; UPDATE NOTES
;-----------------------------------------------------------------------;
; mjs 08/31/89	Detect and respond to the case where someone attempts	;
;		to load a kybd driver using "adddev t,...".  When this	;
;		condition is detected, report an error and return with	;
;		cs:0000 as the end of load point.			;
;-----------------------------------------------------------------------;
; mjs 11/10/89	Corrected logic which prevens dd load if not in task 
;		space.  using tcbgegad and tcbendad wasn't valid since
;		these weren't initialized when config.sys loading is 
;		done.  changed to use scbhpadr and scbhpsiz.  notified
;		sah that this would need changed when he split the heap.
;-----------------------------------------------------------------------;
; BWR 11/30/89	Marked messages for foreign language translation.
;-----------------------------------------------------------------------;
; SAH 12/19/89  Modifications for Split SMP support.			;
;-----------------------------------------------------------------------;

include OPTIONS.INC

;	Initialization code for foreign keyboard drivers

ntskmsg	db	13,10,'This driver must be loaded globally                ',13,10,'$' ;@@XLAT

init:
	mov	ax,cs
	mov	ds,ax
	assume	cs:code, ds:code
	mov	ah,02		; get SCB segment
	int	SERVICES
	push	es

	mov	dx,cs
	mov	ah,25h
	int	SERVICES
	or	ax,ax
	jnz	in_smp
not_smp:
	pop	es
	mov	dx,offset ntskmsg	; specific manner.
	mov	ah,9
	int	21h
	push	cs
	pop	ds
	xor	dx,dx
	jmp	initx
in_smp:

; SCANG install our vector and save previous

	pop	es
	mov	ax,offset TRANSLAT
	mov	dx,cs
	cli			; in case keyboard interrupts
	xchg	ax,word ptr es:[bx+SCBSCANG]
	xchg	dx,word ptr es:[bx+SCBSCANG+2]
	sti
	mov	word ptr [oldkeyb],ax	; save US keyboard driver address
	mov	word ptr [oldkeyb+2],dx

ifdef initial
	call	initial		; perform other initialization
endif

	lea	dx,instmsg
	mov	ah,9		; display alive message
	int	21h
	lea	bx,instmsg	; everything from instmsg down is not retained
	add	bx,15
	mov	cl,4
	shr	bx,cl
	mov	dx,cs		; TSR with driver code and tables
	add	bx,dx
	mov	ds,bx
	xor	dx,dx
initx:
	ret
