;------------------------------ Revision Log ---------------------------;
; BWR	11/30/89	Marked messages for foreign language 		;
;			translation.					;
;-----------------------------------------------------------------------;

	jmp	Vrchk1		; skip around the data
version	label	byte
	include	version.inc

vermsg	db	13,10,'Improper MOS Version.',13,10,'$' ;@@XLAT

Vrchk1:
	mov	ah,30h
	mov	bx,ax		; read the MOS version number
	mov	cx,ax
	mov	dx,ax
	int	21h
	cmp	ax,word ptr [version]
	jne	Vrchk2
	cmp	bx,word ptr [version+2]
	je	Vrchk3
Vrchk2:
	lea	dx,[vermsg]	; report mismatch
	push	cs
	pop	ds
	mov	ah,9
	int	21h
	mov	al,2		; errorlevel 2
	mov	ah,4ch		; and terminate
	int	21h
Vrchk3:

















