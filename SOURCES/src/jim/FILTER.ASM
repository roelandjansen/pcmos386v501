	include page.inc
	title filter.asm - fake network response for selected drives

comment ^===============================================================
		    development specification

 program name:	filter.com		assigned to: Martin Stitt
 module name:	filter.asm		assign date: 10/30/89
 entry from:	exec
 purpose:	fake network response for selected drives

 usage:  FILTER C,D,E

 must specify at least one drive letter.
 only run once - (e.g. install in autoexec.bat)
 can specify any number of drive letters, in any order:

 FILTER K,D,B,F

======================================================================

SAH	11/12/90	Added Support for function 5f02h for Lotus 2.2
			file and record locking.
			Also  added FILTER OFF command to remove Filter
			from Memory....

======================================================================^

	include filter.pub

code	segment para public 'code'
	assume	cs:code, ds:nothing, es:nothing, ss:nothing
	org	0100H
start	proc	near
	jmp	begin

;======================= RESIDENT DATA =============================

vect_num	equ	21h
orig_vect	dd	0		 
drvtbl		db	26 dup(0)
explicit	db	0

netdrive	db	26  dup (0)

netname		db	'\\PC-MOS\DRIVE_'
netdata		db	' '
netlen		equ	($-netname)


;======================== INTERRUPT HANDLER ========================

	subttl intr_proc - interrupt intercept handler
	page
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
	assume	ds:nothing,es:nothing,ss:nothing

	db	'FL'				; This Must be here
intr_proc:
	cmp	ax,5f02h
	jne	not5f02
	cmp	bx,26
	ja	nodrives
	mov	cl,netdrive[bx]
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
	mov	[netdata],cl		; save drive letter into drive name
	mov	byte ptr ds:[si],cl
	mov	byte ptr ds:[si+1],':'
	mov	byte ptr ds:[si+2],0
	cld
	push	cs
	pop	ds
	mov	cx,netlen
	mov	si,offset netname
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
	call	dword ptr cs:[orig_vect]
	mov	bl,al
	pop	ax
	inc	bl			; adjust to 1 for A, 2 for B, etc.
notdef:
	xor	bh,bh
	dec	bx			; adjust to 0 based
	cmp	byte ptr cs:[drvtbl+bx],1  ; faking for this drive?
	pop	bx
	jne	passon
	mov	dx,1000h
        push    bp
        mov     bp,sp
        and     word ptr [bp+6],not 1	; insure carry is clear
        pop     bp
        iret
passon:
	jmp	dword ptr cs:[orig_vect]


end_of_tsr label	byte
	nop			; to keep periscope from mixing up this
				; label with the next one


errmsg1	db	13,10,'Invalid parameter                  ',13,10,'$' ;@@xlat
errmsg2	db	13,10,'Must specify at least one drive letter                    ',13,10,'$' ;@@xlat
errmsg3	db	13,10,'Filter can not be unloaded.        ',13,10,'$'	     ;@@xlat
errmsg4	db	13,10,'Filter Unloaded and Removed from Memory.     ',13,10,'$'  ;@@xlat



;===================== TRANSIENT SUBROUTINES =======================




	subttl low2upper - xlate lowercase letters to upper
	page
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
	assume	ds:nothing,es:nothing,ss:nothing
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


	subttl pass_space - advance ds:si past whitespace
	page
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
	assume	ds:nothing,es:nothing,ss:nothing
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



	subttl CheckOff - check for Filter Off
	page
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
	assume	ds:nothing,es:nothing,ss:nothing
CheckOff proc	near
	cmp	byte ptr ds:[80h],0
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
	cmp	di,offset intr_proc
	jne	CheckBad
	cmp	word ptr es:[di-2],'LF'
	je	CheckOk
CheckBad:
	mov	dx,offset errmsg3
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
	mov	word ptr ds:[21h*4],si
	mov	word ptr ds:[21h*4+2],ax
	sti
;
;	Deallocated TSR code segment and enviroment
;
	push	es
	mov	es,word ptr es:[2ch]
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
	mov	dx,offset errmsg4
	mov	ah,9
	int	21h
	mov	ax,4c00h
	int	21h

CheckOff endp

;======================== MAIN CODE ========================

	assume	cs:code, ds:code, es:code, ss:code
begin:
	call	CheckOff
	xor	di,di
	cmp	byte ptr ds:[80h],0
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
	mov	byte ptr netdrive[di],al
	inc	di
	mov	bx,offset drvtbl
	sub	al,'A'
	xor	ah,ah
	add	bx,ax
	mov	byte ptr [bx],1
	mov	[explicit],1
	inc	si
	jmp	short nxtparm
badparm:
	mov	dx,offset errmsg1
badparm2:
	mov	ah,9
	int	21h
	mov	ah,4ch
	int	21h
doneparm:
	mov	dx,offset errmsg2
	cmp	[explicit],0
	je	badparm2

; establish interrupt handler

	xor	ax,ax
	mov	es,ax
	cli
	mov	ax,es:[vect_num*4]
	mov	word ptr [orig_vect],ax
	mov	ax,es:[vect_num*4+2]
	mov	word ptr [orig_vect+2],ax
	lea	ax,[intr_proc]
	mov	es:[vect_num*4],ax
	mov	es:[vect_num*4+2],cs
	sti
	lea	dx,[end_of_tsr]
	int	27h
start	endp


code	ends
	end	start
