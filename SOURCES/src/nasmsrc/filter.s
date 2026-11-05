; filter.asm - fake network response for selected drives

; usage:  FILTER C,D,E

; must specify at least one drive letter.
; only run once - (e.g. install in autoexec.bat)
; can specify any number of drive letters, in any order:

; FILTER K,D,B,F

org	100h

segment code

start:
	jmp	begin

;======================= RESIDENT DATA =============================

vect_num:	equ	21h
orig_vect:	dd	0		 
drvtbl:		times 26 db 0
explicit:	db	0

netdrive:	times 26 db 0

netname:	db	'\\PC-MOS\DRIVE_'
netdata:	db	' '
netlen:		equ	$ - netname


;======================== INTERRUPT HANDLER ========================

; intr_proc - interrupt intercept handler

;======================================================================
; .func: intr_proc - interrupt intercept handler
;
; input:
;
; output:
;
; comments:
;
; .calls: 
; .reads: 
; .writes: 
;
; .endfn
;======================================================================

	db	'FL'				; This Must be here
intr_proc:
	cmp	ax,5f02h
	jne	not5f02
	cmp	bx,26
	ja	nodrives
	mov	cl,[cs:netdrive+bx]
	or	cl,cl
	jnz	ok5f
nodrives:
	mov	ah,12h
	stc
	retf	2
ok5f:
	mov	bx,0004h
	push	cx
	push	si
	push	di
	push	ds
	mov	[cs:netdata],cl		; save drive letter into drive name
	mov	[si],cl
	mov	[si+1],':'
	mov	[si+2],0
	cld
	push	cs
	pop	ds
	mov	cx, netlen
	mov	si, netname
	rep	movsb
	xor	al,al
	stosb
		
	pop	ds
	pop	di
	pop	si
	pop	cx
	xor	ax,ax
	clc
	retf	2
not5f02:
	cmp	ax,4409h
	jne	passon
	push	bx
	or	bl,bl
	jnz	notdef
	push	ax			; when bl == 0, get default drive
	mov	ah,19h
	pushf
	call	far [cs:orig_vect]
	mov	bl,al
	pop	ax
	inc	bl			; adjust to 1 for A, 2 for B, etc.
notdef:
	xor	bh,bh
	dec	bx			; adjust to 0 based
	cmp	byte [cs:drvtbl+bx], 1  ; faking for this drive?
	pop	bx
	jne	passon
	mov	dx,1000h
        push    bp
        mov     bp,sp
        and     [bp+6],0FFFEh     	; insure carry is clear
        pop     bp
        iret
passon:
	jmp	far [cs:orig_vect]


end_of_tsr:
	nop			; to keep periscope from mixing up this
				; label with the next one


errmsg1:	db	13,10,'Invalid parameter                  ',13,10,'$' ;@@xlat
errmsg2:	db	13,10,'Must specify at least one drive letter                    ',13,10,'$' ;@@xlat
errmsg3:	db	13,10,'Filter can not be unloaded.        ',13,10,'$'	     ;@@xlat
errmsg4:	db	13,10,'Filter Unloaded and Removed from Memory.     ',13,10,'$'  ;@@xlat



;===================== TRANSIENT SUBROUTINES =======================

; low2upper - xlate lowercase letters to upper

;======================================================================
; .func: low2upper - xlate lowercase letters to upper
;
; input:
;	al = character to convert
;
; output:
;	al = uppercase equivalent of entry al
;
; comments:
;
; .calls: 
; .reads: 
; .writes: 
;
; .endfn
;======================================================================

low2upper:
	cmp	al,'a'
	jae	lu1
	ret
lu1:
	cmp	al,'z'
	jbe	lu2
	ret
lu2:
	sub	al,32
	ret


; pass_space - advance ds:si past whitespace

;======================================================================
; .func: pass_space - advance ds:si past whitespace
;
; input:
;	ds:si points to string
;
; output:
;	ds:si advanced past spaces and commas
;	al = stop char
;
; comments:
;
; .calls: 
; .reads: 
; .writes: 
;
; .endfn
;======================================================================

pass_space:
	cld
ps1:	
	lodsb
	cmp	al,' '
	je	ps1
	cmp	al,','
	je	ps1
	dec	si
	ret



; CheckOff - check for Filter Off

;======================================================================
; .func: CheckOff - check for Filter Off
;
; input:
;	ds:si points to string
;
; output:
;	Program is terminated if OFF is detected 
; comments:
;
; .calls: 
; .reads: 
; .writes: 
;
; .endfn
;======================================================================

CheckOff:
	cmp	byte [80h],0
	je	CheckDone
	mov	si,81h
	call	pass_space
	cmp	al,13
	je	CheckDone
	call	low2upper
	cmp	al,'O'
	jne	CheckDone
	inc	si
	lodsb
	cmp	al,13
	je	CheckDone
	call	low2upper
	cmp	al,'F'
	jne	CheckDone
	lodsb
	cmp	al,13
	je	CheckDone
	call	low2upper
	cmp	al,'F'
	je	CheckOff1
CheckDone:
	ret
CheckOff1:
;
;	Test to see if INT 21 Points to our INT 21
;	if not display message
;			
	xor	ax,ax
	mov	es,ax
	les	di,es:[21h*4]			; Get INT 21h Vector
	cmp	di, intr_proc
	jne	CheckBad
	cmp	es:[di-2], word 'FL'
	je	CheckOk
CheckBad:
	mov	dx, errmsg3
	mov	ah,9
	int	21h
	mov	ax,4c01h
	int	21h
CheckOk:
;
;	Reset to Original INT 21h Vector
;
	lds	si,es:[orig_vect]
	push	ds
	xor	ax,ax
	mov	ds,ax
	pop	ax
	cli
	mov	[21h*4],si
	mov	[21h*4+2],ax
	sti
;
;	Deallocated TSR code segment and enviroment
;
	push	es
	mov	es, es:[2ch]
	mov	ah,49h
	int	21h
	pop	es
	mov	ah,49h
	int	21h
;
;	display message and exit
;	
	mov	ax,cs
	mov	ds,ax
	mov	dx, errmsg4
	mov	ah,9
	int	21h
	mov	ax,4c00h
	int	21h


;======================== MAIN CODE ========================

begin:
	call	CheckOff
	xor	di,di
	cmp	byte [80h],0
	je	doneparm
	mov	si,81h
nxtparm:
	call	pass_space
	cmp	al,13
	je	doneparm
	call	low2upper
	cmp	al,'A'
	jb	badparm
	cmp	al,'Z'
	ja	badparm
	mov	netdrive[di],al
	inc	di
	mov	bx, drvtbl
	sub	al,'A'
	xor	ah,ah
	add	bx,ax
	mov	[bx],1
	mov	[explicit],1
	inc	si
	jmp	short nxtparm
badparm:
	mov	dx, errmsg1
badparm2:
	mov	ah,9
	int	21h
	mov	ah,4ch
	int	21h
doneparm:
	mov	dx, errmsg2
	cmp	byte [explicit],0
	je	badparm2

; establish interrupt handler

	xor	ax,ax
	mov	es,ax
	cli
	mov	ax,es:[vect_num*4]
	mov	[orig_vect],ax
	mov	ax,es:[vect_num*4+2]
	mov	[orig_vect+2],ax
	lea	ax,[intr_proc]
	mov	es:[vect_num*4],ax
	mov	es:[vect_num*4+2],cs
	sti
	lea	dx,[end_of_tsr]
	int	27h

