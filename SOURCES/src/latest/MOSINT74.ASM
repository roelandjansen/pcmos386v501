	include page.inc
	title	mosint74 - int 74 (ps/2 mice) interface for pc-mos
comment ^=============================================================
		      development specification

 program name:	$$mos.sys		assigned to: stewart hyde
 module name:	mosint74		assign date: 02/05/90
 entry points:	mosint74		completed:   02/09/90
 entry from:	
 entry method: 
 calls:	swcall
 purpose:	handle ps/2 mouse and $mouse.sys handling
 refer to:	n/a
 last update:	08/18/1992
========================================================================

mjs 05/17/90	modified irq list entry (two fields now abandoned)

sah 06/26/90	correction for windows 3.00 and delay writes, corruption
		of bx register accross int 74 interupt

================ 5.01 kernel ends here ====================================

mjs 08/18/92	clean up segment declarations

=====================================================================^

.xlist
	include mosint74.pub
	include group.inc
	include options.inc
	include macros.inc
	include mosregs.inc

tcb	segment at 1234h
	include mostcb.inc
tcb	ends

gdata	segment
	include mosscbex.inc
gdata	ends
.list

gdata	segment
	extrn	ps2mouse:byte
gdata	ends

irq	segment
	extrn	irqstart:byte, irqend:byte
	dw	74h*4
oint74	dd	?
	dw	0
	dw	mos:mosint74
	dw	0
irq	ends

;======================================================== mos segment
if 0 eq 0
segment_num = 1
endif
mosseg	segment
	assume	cs:mos,ds:grp,es:nothing,ss:tcb

extrn   swcall:near,mosintxx:near,mos2ndxx:near

public	lidtstub74, lidtint74


; the following is int 74 interupt handlers which take account of
; special needs require for accurated immulations of the ps/2 mouse
; bias. if task has generic mouse interface installed and handler
; is present [scbcall74], then before calling original int 74 we
; will make a far call to the mouse handler at scbcall74
;
; code was also added here to propertly access the ps/2 mouse

lidtstub74 label  near
	iret

lidtint74 label near
	push	ds
	MGetSCB ds
	assume  ds:grp
	cmp	[scbin74],'Y'			; are we in $MOUSE.SYS's INT 74
	je	lidtmice

; following code is use to handle IBM PS/2 Hardware Mouse

	cmp	[scbmoutcb],0			; is PS/2 Mice installed
	je	lidtorg74
	push	bx
	push	si
	mov	bx,offset grp:[scbhwcl] + 74h - 68h  ; scbhwcl + irq #
	inc	byte ptr ds:[bx]
	push	cx
	mov	cx,[scbmoutcb]		; get task who did int 15 call
	inc	[scbinirq]
	call	swcall			; switch interupted task into memory
	dec	[scbinirq]
	pop	cx
	pop	bx
	pop	si
	iret

; following code is use to handle INT 74 by $MOUSE.SYS

lidtmice:
	cmp	word ptr [scbcall74+2],0	; is mouse handler installed
	je	lidtorg74
	push	bx
	mov	bx,[scbtcbpc]
	cmp	bx,[scbtcbps]			; skip mice call if not full
	jne	lidtskmice			; context in	
	push	es
	mov	es,bx		
	call	dword ptr [scbcall74]		; are $MOUSE.SYS
	pop	es
lidtskmice:
	pop	bx
lidtorg74:
	push	bx
	xor	bx,bx
	mov	ds,bx		     		; call original INT 74
	pushf	
	call	dword ptr ds:[074h*4]
	pop	bx				
	pop	ds
	iret

public	mosint74
mosint74:
	push	si
	push	bx
	push	ds
	mgetscb ds
	assume	ds:grp
	mov	bx,[scbtcbpc]
	cmp	bx,[scbtcbps]
	jne	m74done			; skip if context is not correct
	cmp	word ptr [scbcall74+2],0; skip if driver not installed
	je	m74done
	cmp	[scbin74],'Y'		; skip if not called within int14
	jne	m74done
	push	es
	mov	es,bx
	assume	es:tcb
	call	dword ptr [scbcall74]	; call	driver
	pop	es
m74done:
	pop	ds
	assume	ds:nothing,es:nothing
	mov	si,offset grp:[oint74]
	mov	bx,offset grp:[scbhwcl] + 74h - 68h  ; scbhwcl + irq #
	jmp	mosintxx

public	mos2nd74
mos2nd74:
	push	si
	push	bx
	mov	si,offset tcb:[tcbapv74]
	mov	bx,offset grp:[scbhwcl] + 74h - 68h  ; scbhwcl + irq #
	push	ds
	mgetscb ds
	assume	ds:grp
	cmp	[scbin74],'Y'		; is $mouse.sys trying use int 74
	je	jmp2nd74
	cmp	[scbmoutcb],0
	je	jmpold74
	inc	byte ptr ds:[bx]
	push	cx
	mov	cx,[scbmoutcb]		; get task who did int 15 call
	inc	[scbinirq]
	call	swcall			; switch interupted task into memory
	dec	[scbinirq]
	pop	cx
	pop	ds
	pop	bx
	pop	si
	iret

jmpold74:				; pass to orig bios's INT 74 handler
	pop	ds
	mov	si,offset grp:[oint74]
	jmp	mosintxx

jmp2nd74:				; pass to task's int 74 hanlder
	pop	ds
	jmp	mos2ndxx

	subttl moucall - ps/2 mouse service routine
	page
;======================================================================
;,fs
; moucall - ps/2 mouse service handler for pc-mos
; 
; this far routine is called by the bios when mouse tell user code that
; mouse as given it data. it is setup by call int 15 function c2h
; subfunction 07h. please note that entry parameters pushed onto stack are
; not susposed to be pop off by this routine or user routine. see page 2-98
; of ps/2 bios documentation.
;				
; in:	status - first word push on stack
;	x data - second word push on stack
;	y data - third word push on stack
;	z data - forth word push on stack
;
; out:	above entry still on stack.
;
;,fe
;======================================================================
	public	moucall
moucall proc far
	push	bp
	mov	bp,sp
	pushf
	cli
	push	cx
	push	ds
	mgetscb ds
	assume	ds:grp
	cmp	[ps2mouse],'Y'		; skip this call if already in it
	je	mcskip
	mov	cx,word ptr [bp+6]
	mov	[scbmouval+6],cx
	mov	cx,word ptr [bp+8]
	mov	[scbmouval+4],cx	; tranfer words push onto stack
	mov	cx,word ptr [bp+10]	; to scb saved area
	mov	[scbmouval+2],cx
	mov	cx,word ptr [bp+12]
	mov	[scbmouval],cx
	mov	[ps2mouse],'Y'		; indicated ps/2 mouse call for swcall
	mov	cx,[scbmoutcb]		; get tcb of ps/2 mouse routine
	call	swcall			; switch every thing in and call it
	mov	[ps2mouse],'N'		; put swcall back to normal
	mov	cx,[scbmouval]
	mov	word ptr [bp+12],cx
	mov	cx,[scbmouval+2]
	mov	word ptr [bp+10],cx	; transfer scb saved area back
	mov	cx,[scbmouval+4]	; to callers stack
	mov	word ptr [bp+8],cx
	mov	cx,[scbmouval+6]
	mov	word ptr [bp+6],cx
mcskip:
	pop	ds
	pop	cx
	popf
	pop	bp
	ret
moucall endp

	subttl ps2call - call users ps/2 mouse routine
;======================================================================
;,fs
; ps2call - call users ps/2 mouse routine
;
; ps2call - call the users ps/2 routine. this routine assumes that es is
; pointing to grp and that tcb save in scbmoutcb is switch is memory
;
; in:	
;
; out:	
;
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:nothing
	public  ps2call
ps2call proc	near
	push	ax
	push	bx
	push	cx
	push	dx
	push	si
	push	di
	push	bp
	push	ds
	push	es
	mgetscb es
	assume	es:grp
	push	word ptr [scbmouval]	; push 4 words defined by ps/2 doc
	push	word ptr [scbmouval+2]
	push	word ptr [scbmouval+4]
	push	word ptr [scbmouval+6]
	call	dword ptr [scbmouse]	; call user routine (save in mosint15)
	mgetscb es			; just in case
	pop	word ptr [scbmouval+6]
	pop	word ptr [scbmouval+4]
	pop	word ptr [scbmouval+2]	; return the 4 word to scb
	pop	word ptr [scbmouval]
	pop	es
	pop	ds
	pop	bp
	pop	di
	pop	si
	pop	dx
	pop	cx
	pop	bx
	pop	ax
	ret
ps2call endp

mosseg	ends
	end

