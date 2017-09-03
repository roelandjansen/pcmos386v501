	title FAKE17.SYS -  Fake status of INT 17h 

code	segment para public 'data'	; To force loading with data
	assume	cs:code,ds:nothing,es:nothing,ss:nothing

DDTVGA	equ	this byte
	dd	-1		; filled in with pointer to next driver 
	dw	8000h		; signifying a character device		
	dw	strat		; device strategy entry point		
	dw	inter		; device interrupt entry point		
egnanm	db	'$$FAKE17'	; device name				


request   dd	0

strat	proc	far
	mov	word ptr [request],bx
	mov	word ptr [request+2],es
	ret
strat	endp

inter	proc	far
	push	es
	push	ds
	push	si
	push	bx
	push	ax
	mov	bx,cs
	mov	ds,bx
	assume	ds:code
	les	bx,[request]
	mov	si,es:[bx+2]
	and	si,0ffh
	or	si,si  			; is this for initialization
	jnz	Inter1
	call	ddtinit			; call init  code
	mov	ax,0100h		; no error, done
inter1:
	assume	ds:nothing
	les	bx,[request]
	mov	es:[bx+3],ax	; store result status
	pop	ax
	pop	bx
	pop	si
	pop	ds
	pop	es
	ret
inter	endp

oldint17	dd	0

Fake17:
	pushf
	call	dword ptr cs:[oldint17]
	mov	ah,90h
	retf	2

endofres:

;========== Start of device driver Initialization ==================

	assume	ds:nothing,es:nothing,ss:nothing
ddtinit:
	mov	ax,cs
	mov	ds,ax
	xor	ax,ax
	mov	es,ax
	mov	dx,offset ddtmsg
	mov	ah,9
	int	21h
	mov	ax,3517h
	int	21h
	push	cs
	pop	ds
	mov	word ptr cs:[oldint17],bx
	mov	word ptr cs:[oldint17+2],es
	mov	dx,offset fake17
	mov	ax,2517h
	int	21h
	les	bx,[request]
	mov	word ptr es:[bx+14],offset endofres
	mov	es:[bx+16],cs
	ret

ddtmsg	db	'Fake INT 17h Status Device Driver Installed.',13,10,'$'
code	ends

	end	

