	page	255,132
;,fs
;******** $.
;,fe

	.model small,c

	.data

extrn ul_vidptr:dword

	.code

	subttl save_window - save specified area of screen into storage area
	page
;======================================================================
;,fs
; save_window - save specified area of screen into storage area
;
; prototype: 
;
; void ul_save_window(int xl, int yt, int xr, int yb, void far *saveptr);
;
; in:	xl = x coordinate of left edge
;	yt = y coordinate of top edge
;	xr = x coordinate of right edge
;	yb = y coordinate of bottom edge
;	saveptr = pointer to storage area
;
; out:	
;
;,fe
;======================================================================
public ul_save_window
ul_save_window proc xl:word,yt:word,xr:word,yb:word,saveptr:dword
	push	cx
	push	dx
	push	si
	push	di
	push	ds
	push	es
	mov	ax,@data
	mov	ds,ax
	mov	ds,word ptr [ul_vidptr+2]
	mov	ax,yt
	call	ytooff
	mov	si,ax
	add	si,xl
	add	si,xl
	les	di,[saveptr]
	mov	dx,xr
	sub	dx,xl
	inc	dx
	cld
	mov	cx,yb
	sub	cx,yt
	inc	cx
sloop1:
	push	cx
	push	si
	mov	cx,dx
	rep	movsw
	pop	si
	pop	cx
	add	si,160
	loop	sloop1
	pop	es
	pop	ds
	pop	di
	pop	si
	pop	dx
	pop	cx
	ret
ul_save_window endp

	subttl restore_window - restores specified area of screen from storage area
	page
;======================================================================
;,fs
; restore_window - restores specified area of screen from storage area
;
; prototype: 
;
; void ul_restore_window(int xl, int yt, int xr, int yb, void far *saveptr);
;
; in:	xl = x coordinate of left edge
;	yt = y coordinate of top edge
;	xr = x coordinate of right edge
;	yb = y coordinate of bottom edge
;	saveptr = pointer to storage area
;
; out:	
;
;,fe
;======================================================================
public ul_restore_window
ul_restore_window proc xl:word,yt:word,xr:word,yb:word,saveptr:dword
	push	cx
	push	dx
	push	si
	push	di
	push	ds
	push	es
	mov	ax,@data
	mov	ds,ax
	mov	es,word ptr [ul_vidptr+2]
	lds	si,[saveptr]
	mov	dx,xr
	sub	dx,xl
	inc	dx
	mov	ax,yt
	call	ytooff
	mov	di,ax
	add	di,xl
	add	di,xl
	cld
	mov	cx,yb
	sub	cx,yt
	inc	cx
rloop1:
	push	cx
	push	di
	mov	cx,dx
	rep	movsw
	pop	di
	pop	cx
	add	di,160
	loop	rloop1
	pop	es
	pop	ds
	pop	di
	pop	si
	pop	dx
	pop	cx
	ret
ul_restore_window endp

	subttl ytooff - converts y value to screen offset
	page
;======================================================================
; ytooff - converts y value to screen offset
;
; this is a private helper function
;
; in:	ax = y value
;
; out:	ax = offset in screen
;
;======================================================================
ytooff proc near
	push	bx
	push	cx
	mov	cl,5
	shl	ax,cl
	mov	cx,ax
	shl	cx,1
	shl	cx,1
	add	ax,cx
	pop	cx
	pop	bx
	ret
ytooff endp

	end

