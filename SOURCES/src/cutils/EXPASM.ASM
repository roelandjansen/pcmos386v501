	page 90,132
	title	expasm
comment ^==============================================================
		    development specification

 program name:	expasm		assigned to: mjs
 module name:	expasm		assign date: 12/11/92
 entry points:	expasm		completed:
 entry from:	
 entry method:	call
 calls: 	
 purpose:	util functions for export
 last update:	!!!!!!
========================================================================

mjs 12/11/92	rewrite

======================================================================^

; define segments

_TEXT	segment byte public 'CODE'
_TEXT	ends
_DATA	segment word public 'DATA'
_DATA	ends
_BSS	segment word public 'BSS'
_BSS	ends
DGROUP	group _DATA,_BSS

_TEXT	segment
	assume	cs:_TEXT,ds:nothing,es:nothing,ss:nothing

orig23		dd	?
orig24		dd	?
saveflags	dw	?
savecs		dw	?
saveip		dw	?
entryax		dw	?

;======================================================================
;,fs
; setup_i2324
;
; void setup_i2324(void);
;
; in:	
;
; out:	
;
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:nothing
public _setup_i2324
_setup_i2324 proc near
	push	ax
	push	bx
	push	dx
	push	ds
	push	es

; hook int23

	mov	ax,3523h
	int	21h
	mov	word ptr cs:[orig23],bx
	mov	word ptr cs:[orig23+2],es
	mov	dx,offset _TEXT:icept23
	mov	ax,cs
	mov	ds,ax
	mov	ax,2523h
	int	21h

; hook int24

	mov	ax,3524h
	int	21h
	mov	word ptr cs:[orig24],bx
	mov	word ptr cs:[orig24+2],es
	mov	dx,offset _TEXT:icept24
	mov	ax,2524h
	int	21h
	pop	es
	pop	ds
	pop	dx
	pop	bx
	pop	ax
	ret
_setup_i2324 endp

;======================================================================
;,fs
; icept23
;
; in:	
;
; out:	
;
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:nothing
icept23 proc far
	push	ax
	push	bx
	push	ds
	push	es
	mov	ax,seg DGROUP
	mov	ds,ax
	assume	ds:DGROUP
	cmp	[_sensitive],0
	je	i23a
	mov	al,[_origcdft]
	les	bx,[_tcbcdftPtr]
	assume	es:nothing
	mov	es:[bx],al
i23a:
	pop	es
	pop	ds
	pop	bx
	pop	ax
	jmp	dword ptr cs:[orig23]
icept23 endp

;======================================================================
;,fs
; icept24
;
; in:	
;
; out:	
;
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:nothing
icept24 proc far
	push	bx
	push	ds
	mov	bx,seg DGROUP
	mov	ds,bx
	assume	ds:DGROUP
	cmp	[_sensitive],0
	jne	i24a
	pop	ds
	assume	ds:nothing
	pop	bx
	jmp	dword ptr cs:[orig24]
i24a:
	assume	ds:DGROUP
	push	cx
	push	es

; save the current value in tcbcdft and then restore tcbcdft to
; its original value.  must do this just in case the int24 handler
; doesn't return.

	les	bx,[_tcbcdftPtr]
	mov	cl,es:[bx]
	mov	[current_cdft],cl
	mov	cl,[_origcdft]
	mov	es:[bx],cl

; record the "can't" flags.

	mov	[entryax],ax

; enter the previous int24 handler with the stack frame it expects
; but setup so that when (if) it irets, it will come back here.

	pop	es
	pop	cx
	pop	ds
	pop	bx
	pop	cs:[saveip]
	pop	cs:[savecs]
	pop	cs:[saveflags]
	push	cs:[saveflags]
	push	cs
	mov	ax,offset _TEXT:return_point
	push	ax
	mov	ax,cs:[entryax]
	jmp	dword ptr cs:[orig24]
return_point:
	push	bx
	push	ds
	mov	bx,seg DGROUP
	mov	ds,bx
	assume	ds:DGROUP
	cmp	al,0
	je	attempt_ignore
	cmp	al,1
	je	attempt_retry
	cmp	al,3
	je	attempt_fail

; if get here, al must be 2 for abort

	jmp	i24x
attempt_ignore:

; if the entry ah value indicated that ignore was not allowed,
; deal with as an attempt to fail (since that's what the os will do).

	test	byte ptr cs:[entryax+1],00100000b
	jnz	not_terminating
	jmp	attempt_fail

attempt_retry:

; if the entry ah value indicated that retry was not allowed,
; deal with as an attempt to fail (since that's what the os will do).

	test	byte ptr cs:[entryax+1],00010000b
	jnz	not_terminating
attempt_fail:

; if the entry ah value indicated that fail was not allowed,
; deal with as if al == 2 for abort (since that's what the os will do).

	test	byte ptr cs:[entryax+1],00001000b
	jz	i24x
not_terminating:

; if not terminating, restore the tcbcdft value that was in
; use when this int24 started.

	push	cx
	push	es
	les	bx,[_tcbcdftPtr]
	mov	cl,[current_cdft]
	mov	es:[bx],cl
	pop	es
	pop	cx
i24x:
	pop	ds
	assume	ds:nothing
	pop	bx
	push	cs:[saveflags]
	push	cs:[savecs]
	push	cs:[saveip]
	iret
icept24 endp

_TEXT	ends

_DATA	segment 

extrn _sensitive:byte
extrn _origcdft:byte
extrn _tcbcdftPtr:dword

current_cdft	db	?

_DATA	ends

_BSS	segment 
_BSS	ends

	end

