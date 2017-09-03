	title insasm - install asm interface
comment ^===============================================================
		    development specification

 program name:	install.exe		assigned to: sah/mjs
 module name:	insasm.asm		assign date: 04/06/89
 entry points:	install (c files)	completed: 04/01/92 (mjs)
 entry from:
 entry method:
 calls:		n/a
 purpose:	int21 intercept for install.c
 last update:	04/01/92

=======================================================================

mjs 04/01/92	major overhaul for mos 5.01

======================================================================^

	ifdef large
	.model large,c
	else
	.model small,c
	endif

	.data

public vidattr
vidattr		db	07h		; default video attribute

	.code

	subttl setint21 - setups int 21 vector for trap shelling
	page
;======================================================================
;,fs
; setint21 - setups int 21 vector for trap shelling
;
; extern void setint21(void);
;
; in:	
;
; out:	
;
;,fe
;======================================================================
public setint21
setint21 proc
	push	ax
	push	es
	mov	byte ptr cs:[xpos],8
	mov	byte ptr cs:[ypos],8
	xor	ax,ax
	mov	es,ax
	mov	ax,word ptr es:[21h*4]
	mov	word ptr cs:[old21],ax
	mov	ax,word ptr es:[21h*4+2]
	mov	word ptr cs:[old21+2],ax
	cli
	mov	ax,offset install21
	mov	word ptr es:[21h*4],ax
	mov	word ptr es:[21h*4+2],cs
	sti
	pop	es
	pop	ax
	ret
setint21 endp

	subttl resetint21 - resets int 21 vector back to one saved by setint21
	page
;======================================================================
;,fs
; resetint21 - resets int 21 vector back to one saved by setint21
;
; extern void resetint21(void);
;
; in:	
;
; out:	
;
;,fe
;======================================================================
public resetint21
resetint21 proc
	push	ax
	push	es
	xor	ax,ax
	mov	es,ax
	cmp	word ptr cs:[old21],ax
	je	skipreset
	mov	ax,word ptr cs:[old21]
	mov	word ptr es:[21h*4],ax
	mov	ax,word ptr cs:[old21+2]
	mov	word ptr es:[21h*4+2],ax
	mov	word ptr cs:[old21],0
skipreset:
	pop	es
	pop	ax
	ret
resetint21 endp

	subttl install21 - 
	page
;======================================================================
;,fs
; install21 - 
;
; in:	
;
; out:	
;
;,fe
;======================================================================
public install21
install21 proc	far
	cmp	ah,2
	je	fun2
	cmp	ah,6
	je	fun6
	jmp	notfun6
fun6:
	cmp	dl,0ffh
	je	notfun6
fun2:
	cmp	dl,10
	jne	not610
	push	ax
	push	bx
	push	cx
	push	dx
	inc	byte ptr cs:[ypos]
	cmp	byte ptr cs:[ypos],13h
	jbe	set6pos
	dec	byte ptr cs:[ypos]
	push	ds
	mov	ax,@data
	mov	ds,ax
	mov	bh,vidattr
	mov	ax,0601h
	mov	cx,0808h
	mov	dx,1348h
	int	10h
	mov	dl,byte ptr cs:[xpos]
	mov	dh,byte ptr cs:[ypos]
	mov	ah,2
	xor	bh,bh
	int	10h
	mov	ax,0920h		; print space
	mov	bl,[vidattr]
	xor	bh,bh
	mov	cx,40h
	int	10h
	pop	ds
	jmp	short set6pos
not610:
	cmp	dl,13
	jne	not613
	push	ax
	push	bx
	push	cx
	push	dx
	mov	byte ptr cs:[xpos],8
set6pos:
	mov	dl,byte ptr cs:[xpos]
	mov	dh,byte ptr cs:[ypos]
	mov	ah,2
	xor	bh,bh
	int	10h
	pop	dx
	pop	cx
	pop	bx
	pop	ax
	iret
notfun6:
	cmp	ah,9
 	je	fun9
	jmp	dword ptr cs:[old21]
not613:
	cmp	dl,8
	jne	not608
	dec	byte ptr cs:[xpos]
	push	ax
	push	bx
	push	cx
	push	dx
	jmp	short set6pos
not608:
	inc	byte ptr cs:[xpos]
	cmp	byte ptr cs:[xpos],46h
	ja	skip6
	push	ax
	push	bx
	push	cx
	push	dx
	mov	al,dl
	call	near ptr writchar
	pop	dx
	pop	cx
	pop	bx
	pop	ax
skip6:
	iret
fun9:
	push	ax
	push	bx
	push	cx
	push	dx
	push	si
	mov	si,dx
	cld
loop9:
	lodsb
	cmp	al,'$'
	jne	notdone9
	jmp	done9
notdone9:
	cmp	al,9
	jne	nottab
	mov	al,byte ptr cs:[xpos]
	add	al,8
	and	al,0f8h
	mov	byte ptr cs:[xpos],al
	jmp	setpos
nottab:
	cmp	al,13
	jne	notret
	mov	byte ptr cs:[xpos],8
	jmp	setpos
notret:
	cmp	al,10
	jne	notscroll
	inc	byte ptr cs:[ypos]
	cmp	byte ptr cs:[ypos],13h
	jbe	setpos
	dec	byte ptr cs:[ypos]
	push	ds
	mov	ax,@data
	mov	ds,ax
	mov	bh,vidattr
	mov	ax,0601h
	mov	cx,0808h
	mov	dx,1348h
	int	10h
	mov	dl,byte ptr cs:[xpos]
	mov	dh,byte ptr cs:[ypos]
	mov	ah,2
	xor	bh,bh
	int	10h
	mov	ax,0920h		; print space
	mov	bl,[vidattr]
	xor	bh,bh
	mov	cx,40h
	int	10h
	pop	ds
setpos:
	mov	dl,byte ptr cs:[xpos]
	mov	dh,byte ptr cs:[ypos]
	mov	ah,2
	xor	bh,bh
	int	10h
	jmp	loop9
notscroll:
	inc	byte ptr cs:[xpos]
	cmp	byte ptr cs:[xpos],46h
	ja	toobig
	call	near ptr writchar
toobig:
	jmp	loop9
done9:
	pop	si
	pop	dx
	pop	cx
	pop	bx
	pop	ax
	iret

old21	dd	0
xpos	db	0
ypos	db	0

install21 endp

	subttl writchar - 
	page
;======================================================================
;,fs
; writchar - 
;
; in:	
;
; out:	
;
;,fe
;======================================================================
writchar proc	near
	push	ds
	mov	bx,@data
	mov	ds,bx
	mov	bl,[vidattr]
	mov	cx,1
	xor	bh,bh
	mov	ah,9
	int	10h
	mov	ah,3
	xor	bh,bh			; get cursor position
	int	10h
	inc	dl			; increment it
	mov	ah,2
	xor	bh,bh			; set cursor position
	int	10h
	pop	ds
	ret
writchar endp

	end

