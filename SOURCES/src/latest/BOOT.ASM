include		page.inc
;
;****************************************************************************
;
;	Module name:		BOOT.ASM
;
;	Creation date:		
;
;	Revision date:		20-Nov-89
;
;	Author:			
;
;	Description:		Cold boot system.
;
;
;		(C) Copyright 1989, The Software Link Inc.
;			All Rights Reserved
;
;****************************************************************************
;			>> Revision Log <<
;
; Date		Prog		Description of Revision
; ----		----		-----------------------
; 11/20/89	BWR		Updated for language translation.
;
;****************************************************************************
;
cgroup	group	cseg
cseg	segment	public word 'CODE'

	assume	cs:cgroup,ds:cgroup,es:nothing,ss:nothing

	org	100h
start:
	jmp	reboot
;
; Data segment same as code
;
cr	equ	0dh
lf	equ	0ah
beep	equ	7

rdevice	db	'$$memdev',0	; memdev driver name

nmdev	db	cr,lf,lf,'Cannot access MEMDEV',cr,lf,lf,beep ;@@XLAT
	db	'Reboot to BIOS',cr,lf,'$' ;@@XLAT

rbmsg	db	cr,lf,lf,'Performing Boot...$' ;@@XLAT
	db	68 dup (?)			; rem fill to 80 chars

vermsg	db	cr,lf,lf,beep,'Improper MOS Version!',cr,lf,lf,'$' ;@@XLAT

rdbuf	dd	?		; four byte read

biosloc	dd	0f000fff0h	; bios reboot loc

timloc	dd	0040006ch	; bios timer lo byte loc

versnum label	near

	include	version.inc

reboot:
	mov	ah,30h			;check version number
	mov	bx,ax
	mov	cx,ax
	mov	dx,ax
	int	21h
	cmp	ax,word ptr [versnum]
	jnz	badver
;
	mov	ah,9			;tell them whats happening
	lea	dx,rbmsg
	int	21h
	mov	ax,3d10h		;open memdev driver, read, no share
	lea	dx,rdevice
	int	21h
	jc	biosboot		;any errors just reboot to BIOS
	mov	bx,ax			;handle returned
	mov	ax,4400h		;ioctl, get current device attr
	int	21h
	xor	dh,dh
	or	dl,20h			;set raw mode
	mov	ax,4401h
	int	21h
	mov	ah,3fh			;read address out of driver
	mov	cx,4
	lea	dx,rdbuf
	int	21h
	jc	biosboot
	mov	ah,3eh
	int	21h			;close device
	les	bx,dword ptr [rdbuf]
	les	bx,es:[bx]
	mov	word ptr [rdbuf+2],es	;extra pointer manipulation
	mov	word ptr [rdbuf],bx
	call	wait1
	xor	ax,ax
	jmp	dword ptr [rdbuf]	;reboot
;
biosboot:
	mov	ah,9
	lea	dx,nmdev
	int	21h

; pause for a sec

	call	wait1
;
	jmp	dword ptr [biosloc]	;jump to bios
;
badver:	mov	ah,9
	lea	dx,vermsg
	int	21h
	xor	ax,ax
	int	21h			;terminate
;
wait1:	mov	cx,18
	les	bx,dword ptr [timloc]
	mov	ax,es:[bx]
stlp:	mov	dx,ax
wtlp:	mov	ax,es:[bx]
	cmp	ax,dx
	jz	wtlp
	loop	stlp
	ret

cseg	ends
	end	start
