	include page.inc
	title remdev.asm - delete a device from device driver chain
;-----------------------------------------------------------------------;
;		     development specification				;
;									;
; command type: external		assigned to: bob wright 	;
; command name: remdev			date assigned: may 16, 1987	;
;					date completed: 		;
; command format: remdev devicename					;
; purpose: to remove a device driver after bootup			;
;-----------------------------------------------------------------------;
; mjs 12/26/88	Complete overhaul/cleanup.  Modified to display and 	;
;		remove task specific device drivers.			;
;-----------------------------------------------------------------------;
; SAH 02/20/89	Converted INT 38 calls to INT SERVICES			;
;-----------------------------------------------------------------------;
; BWR 11/30/89	Marked messages for foreign language translation.	;
;-----------------------------------------------------------------------;
; SAH 12/18/89  Modified to use INT D4 function 25 for split Heap mods	;
;-----------------------------------------------------------------------;
; SAH 01/23/91 Corrections for "undocumented DOS" device driver 	;
;		compatibility.						;
;-----------------------------------------------------------------------;
; SAH 05/06/91 Corrections for "undocumented DOS" device driver work    ;
;	       and removing device drivers.				;
;-----------------------------------------------------------------------;
; SAH 04/20/92 Up version to 5.01, copyright corrections		;
;-----------------------------------------------------------------------;

	include options.inc
	include remdev.pub

scbs	segment	at 0beach
	assume  cs:scbs
	include mosscbdf.inc
scbs 	ends


mainseg segment word public 'code'
	assume cs:mainseg,ds:mainseg,es:mainseg,ss:mainseg
	org	100h

remdev	proc	near
	jmp	begin

;=== Macros ==========================

call38	macro
	pushf
	call	dword ptr [i38vect]
	endm

;=== Equates =========================

true	equ	0ffffh
false	equ	0

tcbddpf  equ	830h

;=== Strings =========================

tsl	db	13,10,'PC-MOS Remove Device Utility  v5.01   ',13,10 ;@@XLAT
	db	'(c) Copyright 1987 - 1992 The Software Link, Incorporated.' ;@@XLAT
	db	13,10
	db	'All rights reserved worldwide ',13,10,'$' ;@@XLAT

syntax	db	13,10,'Syntax: .Remdev devicename',13,10 ;@@XLAT
	db	'           where <devicename> = name of driver to remove        ',13,10,'$' ;@@XLAT

glbl_header	db	13,10,10,'   Global device drivers$' ;@@XLAT
task_header	db	13,10,10,'   Task specific device drivers$' ;@@XLAT
underline	db	13,10,'-----------------------------------------------------------------------------',13,10,'$'
comp1_glbl	db	13,10,'Global device driver unlinked         ',13,10,'$' ;@@XLAT
comp2_glbl	db	'SMP memory de-allocated         ',13,10,'$' ;@@XLAT
comp3_glbl	db	'Error duing de-allocation of SMP memory          ',13,10,'$' ;@@XLAT
comp0_task	db	13,10,'Task specific device driver cannot be removed          ',13,10 ;@@XLAT
		db	'Task memory has been allocated after the driver         ',13,10,'$' ;@@XLAT
comp1_task	db	13,10,'Task specific device driver unlinked         ',13,10,'$' ;@@XLAT
comp2_task	db	'Task memory de-allocated         ',13,10,'$' ;@@XLAT
comp3_task	db	'Error duing de-allocation of task memory        ',13,10,'$' ;@@XLAT
kernel_task	db	13,10,'Internal device driver cannot be removed	           ',13,10,'$' ;@@XLAT
not_found	db	13,10,10,'The device driver specified was not found            ',13,10,'$' ;@@XLAT

memdev		db	'$$MEMDEV',0

;=== Variables =======================

ddname		db	'                    '
rem_name	db	'        '
prev_ddoff	dw	0		; temp for holding previous dd offset
prev_ddseg	dw	0		;  "    "    "       "	    "  segment
dd_heap 	dw	0		; beginning segment address of heap
dd_hpend	dw	0		; number of paragraphs for heap
i38vect 	dd	0		; storage for the int38 vector
scbesbx 	dd	0		; es:bx -> scb
tcbseg		dw	0		; segment of tcb for current task
chk_marker	db	'N'		; check for NUL device driver marker

;=== Subroutines =====================

;- PRINT ---------------------------------------------------------------;
; entry parms:	ds:dx -> string to send to stdout (terminate with '$')	;
; exit parms:	none							;
;-----------------------------------------------------------------------;
	assume	ds:mainseg,es:nothing,ss:nothing
print:
	push	ax
	mov	ah,9
	int	21h
	pop	ax
	ret

;- TOUPPER -------------------------------------------------------------;
; entry parms:	ds:bx -> string to be converted 			;
;		cx = string length					;
; exit parms:	string is converted to upper case			;
;-----------------------------------------------------------------------;
	assume	ds:mainseg,es:nothing,ss:nothing
toupper:
	push	bx
	jcxz	tux
tua:
	cmp	byte ptr [bx],'a'
	jb	tub
	cmp	byte ptr [bx],'z'
	ja	tub
	sub	byte ptr [bx],32
tub:
	inc	bx
	loop	tua
tux:
	pop	bx
	ret

;- DDPRINT -------------------------------------------------------------;
; entry parms:	es:bx -> the dd's header                                ;
; exit parms:	none							;
;									;
; NOTES: display a dd's name                                            ;
;-----------------------------------------------------------------------;
	assume	ds:mainseg,es:nothing,ss:nothing
ddprint:
	test	word ptr es:[bx+4],8000h	; skip block devices
	jz	ddpx
	mov	cx,8
	lea	di,[ddname]
	mov	si,bx
	add	si,10
	push	es
	push	ds
	push	ds
	push	es			; swap ds and es
	pop	ds
	pop	es
	rep	movsb
	pop	ds
	pop	es
	lea	dx,[ddname]
	mov	cx,20
	push	bx
	mov	bx,1
	mov	ah,40h
	int	21h
	pop	bx
ddpx:
	ret

;- LISTDDS -------------------------------------------------------------;
; entry parms:	ds:dx -> header message 				;
;		es:bx -> device driver chain				;
; exit parms:	none							;
;									;
; NOTES: print out a list of all device drivers installed		;
;-----------------------------------------------------------------------;
	assume	ds:mainseg,es:nothing,ss:nothing

lstdd2:
	cmp	bx,-1
	je	lstd4
	push	bp
	xor	bp,bp
lstd1:
;
;	if task specific check, check to see if it is our special marker
;	use in provide compatibility with undocumented dos techniques of
;	searching device driverr list
;
	cmp	[chk_marker],'Y'
	jne	lstd1b
	push	ax
	push	si
	push	ds
	lds	si,[scbesbx]
	assume	ds:scbs
	lds	si,dword ptr ds:[si+scbdrvr]
	assume	ds:mainseg
	cmp	si,bx
	jne	lstd1a	
	mov	ax,es
	mov	si,ds
	cmp	ax,si
lstd1a:
	pop	ds
	pop	si
	pop	ax
	je	lstd3a			; if equal than get out
lstd1b:
	test	word ptr es:[bx+4],8000h ; don't count block devices towards
	jz	lstd2			; displaying the header
	or	bp,bp
	jnz	lstd2			; only enter here once to display
	mov	bp,1			; header
	call	print			; use entry dx for first message
	lea	dx,[underline]
	call	print
lstd2:
	cmp	word ptr es:[bx],-1
	je	lstd3
	call	ddprint
	les	bx,es:[bx]
	jmp	lstd1
lstd3:
	call	ddprint
	mov	dl,13
	mov	ah,2
	int	21h
	mov	dl,10
	mov	ah,2
	int	21h
lstd3a:
	pop	bp
lstd4:
	ret

listdds:
	push	dx
	mov	es,[tcbseg]
	les	bx,dword ptr es:[tcbddpf]
	lea	dx,[task_header]
	mov	[chk_marker],'Y'		; check for special marker
	call	lstdd2
	mov	[chk_marker],'N'
	les	bx,[scbesbx]
	assume	es:scbs
	les	bx,dword ptr es:[bx+scbdrvr]
	assume	es:mainseg
	lea	dx,[glbl_header]
	call	lstdd2
	pop	dx
	ret


;- LOOKUP --------------------------------------------------------------;
; entry parms:	es:bx -> device driver chain to search			;
; exit parms:	NC if match found, es:bx -> driver			;
;		[prev_ddoff/seg] -> previous entry in list		;
;		else CY if no match					;
;									;
; NOTES: look up a device driver in a global or task specific list	;
;-----------------------------------------------------------------------;
	assume	ds:mainseg,es:nothing,ss:nothing
lookup:
	push	es
	push	cs
	pop	es
	lea	si,[rem_name]
	lea	di,[memdev]
	mov 	cx,8
	rep	cmpsb
	pop	es
	je	not_memdev
	mov	word ptr [prev_ddoff],0
	mov	word ptr [prev_ddseg],0
lookup2:
	cmp	bx,-1
	je	endlook
	lea	si,[rem_name]
	mov	di,bx
	add	di,10
	mov	cx,8
	rep	cmpsb
	jz	got_it
	mov	[prev_ddoff],bx
	mov	[prev_ddseg],es
	les	bx,es:[bx]
	jmp	lookup2
endlook:
	mov	dx,offset not_found
	stc
	ret
got_it:
	push	bx
	push	es
;
; 	Now we must determine type of Device driver
;	AX non-zero means global, AX=0 means task specific
;
	mov	dx,es
	mov	ah,25h
	call38
	or	ax,ax
	jnz	got_it2
;
	mov	ax,es
	les	bx,[scbesbx]
	assume	es:scbs
	cmp	ax,es:[bx+scbmosadr]		; is it MOS segment
	je	not_kernel
	cmp	ax,es:[bx+scbmo2end]
	assume	es:nothing
	jae	got_it_ok
	mov	bx,es
	cmp	ax,bx				; is it GRP segment
	jae	not_kernel
got_it_ok:	
	xor	ax,ax		
got_it2:
	pop	es
	pop	bx
	clc
	ret
not_kernel:
	pop	es
	pop	bx
not_memdev:
	mov	dx,offset kernel_task
	stc
	ret


;- UNLINK_GLBL ---------------------------------------------------------;
; entry parms:	es:bx -> driver to unlink				;
;		[prev_ddofs/seg] -> previous driver in list		;
; exit parms:	none							;
;									;
; NOTES: unlinks a global device driver and deallocates its smp block	;
;-----------------------------------------------------------------------;
	assume	ds:mainseg,es:nothing,ss:nothing
unlink_glbl:
	push	ax
	push	dx
	push	es
	push	bx
	les	dx,es:[bx]
	mov	ax,es			; ax:dx point to the next driver past
	cli				; the one being unlinked
	cmp	[prev_ddseg],0
	je	unlgla

; unlink in mid-chain by makeing the previous driver point to the next driver

	les	bx,dword ptr [prev_ddoff]
	mov	es:[bx],dx
	mov	es:[bx+2],ax
	jmp	short unlglb

; when [prev_ddseg] == 0, the driver to be unlinked is the first one so 
; the root pointer must be modified 

unlgla:
	les	bx,[scbesbx]		
	assume	es:scbs
	mov	word ptr es:[bx+scbdrvr],dx
	mov	word ptr es:[bx+scbdrvr+2],ax
	assume	es:nothing
unlglb:
	sti
	lea	dx,[comp1_glbl]
	call	print

; check to see if the driver being removed is located within the smp

	pop	bx
	pop	es
	mov	dx,es
	mov	ah,25h		; check if in heap call
	call38	
	or	ax,ax
	jz	unlglx
	mov	ah,0ah
	mov	al,1

; call mosheman to de-allocate smp block

	call38
	lea	dx,[comp2_glbl] ; report good mem de-allocation
	cmp	al,0
	je	unlglc
	lea	dx,[comp3_glbl] ; report de-alloc error
unlglc:
	call	print
unlglx:
	pop	dx
	pop	ax
	ret

;- UNLINK_TASK ---------------------------------------------------------;
; entry parms:	es:bx -> driver to unlink				;
;		[prev_ddofs/seg] -> previous driver in list		;
; exit parms:	none							;
;									;
; NOTES: unlinks a task specific device driver				;
;-----------------------------------------------------------------------;
	assume	ds:mainseg,es:nothing,ss:nothing
unlink_task:
	push	ax
	push	cx
	push	dx
	push	es

; make sure the driver was the last thing loaded into the task

	push	es
	mov	ax,es
	sub	ax,11h		; calc next mcb block after the driver's
	mov	es,ax
	mov	cx,es:[3]
	add	ax,cx
	add	ax,2
	mov	cx,cs:[2ch]	; find segment of this program's environment
	pop	es
	cmp	ax,cx
	je	unltsd
	lea	dx,[comp0_task]
	pop	ax
	jmp	unltsc
unltsd:
	les	dx,es:[bx]
	mov	ax,es			; ax:dx point to the next driver past
	cli				; the one being unlinked
	cmp	[prev_ddseg],0
	je	unltsa

; unlink in mid-chain by makeing the previous driver point to the next driver

	les	bx,dword ptr [prev_ddoff]
	mov	es:[bx],dx
	mov	es:[bx+2],ax
	jmp	short unltsb

; when [prev_ddseg] == 0, the driver to be unlinked is the first one so 
; the root pointer must be modified 

unltsa:
	mov	es,[tcbseg]
	mov	word ptr es:[tcbddpf],dx
	mov	word ptr es:[tcbddpf+2],ax
unltsb:
	sti
	lea	dx,[comp1_task]
	call	print

; de-allocate the mcb that the driver is in

	pop	ax			; push'ed as es
	sub	ax,10h
	mov	es,ax
	push	es
	lea	dx,[comp3_task] 	; setup for error message
	mov	es,es:[2ch]		; get segment of environment
	mov	ah,49h
	int	21h
	jc	unltsc
	pop	es
	mov	ah,49h
	int	21h
	jc	unltsc
	lea	dx,[comp2_task]
unltsc:
	call	print
	pop	dx
	pop	cx
	pop	ax
	ret

;- PULLDEV -------------------------------------------------------------;
; entry parms:	ds:si -> name of device in parameter line		;
; exit parms:	CY if driver can't be found in either the task specific ;
;		or global list. 					;
;-----------------------------------------------------------------------;
	assume	ds:mainseg,es:nothing,ss:nothing
pulldev:
	lea	di,[rem_name]
	mov	cx,9
mov_loop:
	lodsb
	cmp	al,0dh
	jz	end_loop
	dec	cx
	jz	end_loop
	mov	byte ptr [di],al
	inc	di
	jmp	short mov_loop
end_loop:
	lea	bx,[rem_name]
	mov	cx,8
	call	toupper
	mov	es,[tcbseg]
	les	bx,es:[tcbddpf]
	call	lookup
	jc	not_here
	or	ax,ax
	jnz	try_glbl
	call	unlink_task
	jmp	short pullx
try_glbl:
	call	unlink_glbl
pullx:
	clc
	ret
not_here:
	stc
	ret

;=== main code =======================
	assume cs:mainseg,ds:mainseg,es:mainseg,ss:mainseg
begin:
	push	es
	xor	ax,ax
	mov	es,ax
	assume	es:nothing
	les	ax,es:[SERVICES*4]	     ; store int38 vector for
	mov	word ptr [i38vect],ax	; pushf/call far
	mov	word ptr [i38vect+2],es
	mov	ah,2
	call38
	mov	word ptr [scbesbx],bx
	mov	word ptr [scbesbx+2],es
	mov	ah,4
	mov	bx,-1
	call38
	mov	[tcbseg],es
	pop	es
	assume	es:mainseg
	mov	si,81h
	cmp	byte ptr [si-1],0	; check for null parm line
	je	list_devs
prsa:
	lodsb
	cmp	al,13
	je	list_devs
	cmp	al,' '
	jbe	prsa
	dec	si
	call	pulldev
	jnc	g_bye
	call	print
	jmp	error_out

; no parameter - dump installed drivers 

list_devs:
	lea	dx,[tsl]
	call	print
	call	listdds
	lea	dx,[syntax]
	call	print
g_bye:
	mov	ax,4c00h
	int	21h

;=== error handling ==================

error_out:
	mov	ax,4c01h
	int	21h

remdev	endp
mainseg ends
	end	remdev
