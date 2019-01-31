	include page.inc
	title DEBUGEXT.ASM - MOS DEBUG Extra or Misc Commands
;
;******************************************************************************
;*									      *
;*			  MOS Development Specification			      *
;*									      *
;* Command type: External		Assigned to:	    Stewart A. Hyde   *
;* Command name: DEBUG			Date assigned:	    August 20, 1986   *
;*					Date completed:			      *
;* Command format: DEBUG d:[path][filename][.ext][parm1][parm2]		      *
;* Purpose:  To provide debugging facilities to MOS			      *
;* Refer to: IBM PC-DOS 3.2 DOC and MOSDEBUG.DOC			      *
;* Last Update:				By:				      *
;*									      *
;*	External		Values			Values		      *
;*	routines		passed			returned	      *
;* -------------------------------------------------------------------------- *
;* (add as many lines as you need here and above to complete the form.)	      *
;* -------------------------------------------------------------------------- *
;* MOS commands will use the same segment grouping as the MOS kernel. This    *
;* file is a template as is MOSSHELL.ASM. Except that its designed for use in *
;* commands, both internal and external, for MOS. See MOSSHELL.ASM for de-    *
;* tails. The commands should not need to go into as much detail as the kernel*
;* does in keeping track of end of segment pointers in the INC files and such.*
;* Our desire is to maintain the same coding standards thruout MOS and to use *
;* code modularity as much as possible. So, use the same group labels in any  *
;* routine to keep the code and data segments in the same segment.	      *
;*									      *
;******************************************************************************
;
;	09/08/88	RKG	Misc Cleanup and internal name change
;	11/22/88	RKG	Message changes

	if1
		%out ---------------------------------------------------------
		%out -	  PC-MOS/386  Debugger Version 1.00  Release 1.02
		%out -			Author:	 Stewart Hyde
		%out -
		%out -			   DEBUGEXT.ASM
		%out -
		%out -	 (c) Copyright 1987 The Software Link, Incorporated
		%out ---------------------------------------------------------
		%out
		%out
		%out   Pass 1	Started.
	else
		%out   Pass 2	Started.
	endif


	include debugext.pub

extrn	OutMsg:near, OutChar:near, GetKey:near, MakeHex:near, GetAddr:near
extrn	RemSpac:near, SwapScr:near, GetKBD:near, Get8087:near, dump:near
extrn	GetHex:near, GetList:near, SizeMax:near, SizeMin:near
extrn	stkptr:word, stkseg:word, cmdout:word, dbaddr:word, r87ctr:word
extrn	r87stat:word, r87iseg:word, r87ioff:word, r87dseg:word, r87tag:word
extrn	r87dseg:word, r87doff:word, r87stk:word, cmdtab:word, bptab:word
extrn	regip:word, regcs:word, r87all:word, dbport:word
extrn	valsi:word, valdi:word
extrn	bpflag:byte, bonmsg:byte, boffmsg:byte, shmsg:byte, buff:byte
extrn	chip:byte, cpu:byte, cpumsg:byte, crlf:byte, endbyte:byte
extrn	getbuff:byte, bpthere:byte, cbadmsg:byte, NotDone:byte, retcode:byte
extrn	cpbuff:byte, cpparms:byte, lenbuff:byte, minfo:byte
extrn	r87msg:byte, r87msg1:byte, helptab:byte, blank2:byte, tempbuf:byte
extrn	bsetmsg:byte, bclrmsg:byte, badbpad:byte, badbp:byte, bpfull:byte
extrn	mcpu:byte, mchip:byte, nomath:byte, nobrk:byte
extrn	bsetend:byte, dbmsg:byte, dbad:byte, nommsg:byte
 
	if	0 eq 0

helplen equ	0026h
SCREEN	equ	0FFFFH
BPSOFT	equ	10			; # of soft break points
BPHARD	equ	10			; # of hard break points

	endif

moss	segment word public 'code'
	assume cs:moss;ds:moss;es:moss

	subttl	Math - Display coprocessor info
	page
;-------------------------------------------------------------------------;
;	Function: math							  ;
;		  Display Math Coprocessor				  ;
;	Input:								  ;
;	Output:								  ;
;		  None - displays information to screen			  ;
;-------------------------------------------------------------------------;

math	proc	near
	cmp	[mcpu], 0	; no math coprocessor
	jne	math0
	push	dx
	lea	dx, nomath
	call	OutMsg		; display error message
	pop	dx
	xor	bx, bx
	ret			; exit

math0:
	push	ax
	push	cx
	push	dx
	push	di

	call	Get8087		; get 8087 context
	mov	cx, 1
	lea	di, r87msg+8
	mov	ax, [r87ctr]
	call	MakeHex
	add	di, 9
	mov	ax, [r87stat]
	call	MakeHex
	add	di, 6
	mov	ax, [r87tag]
	call	MakeHex
	add	di, 14
	mov	ax, [r87iseg]
	call	MakeHex
	inc	di
	mov	ax, [r87ioff]
	call	MakeHex
	add	di, 7
	mov	ax, [r87dseg]
	call	MakeHex
	inc	di
	mov	ax, [r87doff]
	call	MakeHex
	lea	dx, r87msg
	call	OutMsg
	mov	cx, 8
	xor	bx, bx

math1:
	push	cx
	mov	al, '9'
	sub	al, cl
	dec	al
	mov	byte ptr [r87msg1+2], al
	mov	cl, '0'
	mov	ax, word ptr [bx+r87stk]
	test	ax, 8000h
	jz	math2
	mov	cl, '1'

math2:
	lea	di, r87msg1+9
	mov	byte ptr [di], cl
	add	di, 7
	and	ax, 7FFFH
	mov	cl, 1
	call	MakeHex
	add	di, 4
	inc	bx
	inc	bx

	mov	cx, 4

math3:
	push	cx
	mov	cl, 1
	mov	ax, word ptr [bx+r87stk]
	call	MakeHex
	inc	bx
	inc	bx
	inc	di
	mov	ax, word ptr [bx+r87stk]
	call	MakeHex
	inc	bx
	inc	bx
	inc	di
	inc	di
	pop	cx
	loop	math3

	lea	dx, r87msg1
	call	OutMsg
	pop	cx
	loop	math1
	xor	bh, bh

	pop	di
	pop	dx
	pop	cx
	pop	ax
	ret
math	endp

	subttl	Help - displays help
	page
;-------------------------------------------------------------------------;
;	Function: help							  ;
;		  Display help information				  ;
;	Input:								  ;
;	Output:								  ;
;		  None - displays information to screen			  ;
;-------------------------------------------------------------------------;

help	proc	near
	push	ax
	push	cx
	push	dx
	push	bp
	push	si

	mov	cx, helplen/3
	mov	bp, cx
	lea	si, helptab
	mov	bx, 2

hloop:
	push	cx
	mov	cx, 3
	push	si
	push	bx

hloop2:
	lea	dx, blank2
	call	OutMsg
	mov	ax, [bx+cmdtab]
	mov	word ptr [tempbuf], ax
	lea	dx, tempbuf
	call	OutMsg
	lea	dx, blank2
	call	OutMsg
	mov	dx, si
	call	OutMsg
	add	bx, bp
	add	bx, bp
	add	si, (helplen/3)*21
	loop	hloop2
	pop	bx
	pop	si
	pop	cx
	lea	dx, crlf
	call	OutMsg
	inc	bx
	inc	bx
	add	si, 21
	loop	hloop
	xor	bh, bh

	pop	si
	pop	bp
	pop	dx
	pop	cx
	pop	ax
	ret
help	endp

	page
;-------------------------------------------------------------------------;
;	Function: bpon							  ;
;		  Turns breakpoints on					  ;
;	Input:								  ;
;	Output:								  ;
;		  None - displays information to screen			  ;
;-------------------------------------------------------------------------;

bpon	proc	near
	push	dx

	mov	[bpflag], 1	; turn breakpoints on
	lea	dx, bonmsg
	call	OutMsg
	xor	bh, bh

	pop	dx
	ret
bpon	endp

	page
;-------------------------------------------------------------------------;
;	Function: bpoff							  ;
;		  Turns breakpoints off					  ;
;	Input:								  ;
;	Output:								  ;
;		  None - displays information to screen			  ;
;-------------------------------------------------------------------------;

bpoff	proc	near
	push	dx

	mov	[bpflag], 0	; turn breakpoints off
	lea	dx, boffmsg
	call	OutMsg
	xor	bh, bh

	pop	dx
	ret
bpoff	endp

	page
;-------------------------------------------------------------------------;
;	Function: bpset							  ;
;		  Set Breakpoint 0-9 to address nnnn:nnnn		  ;
;	Input:								  ;
;	Output:								  ;
;		  None - displays information to screen			  ;
;-------------------------------------------------------------------------;

bpset	proc	near
	push	ax
	push	cx
	push	dx
	push	bp
	push	si
	push	di
	push	es

	push	cs
	pop	es
	mov	di, [regip]
	mov	si, [regcs]
	mov	bx, 2
	call	GetAddr
	or	bx, bx
	jne	bp1

bp0:
	lea	dx, badbpad
	call	OutMsg
	jmp	bp12

bp1:
	mov	cx, BPSOFT
	mov	bx, BPSOFT*4	; start at bp 10


bp2:
	or	cx, cx
	jz	bp4
	cmp	si, [bx+bptab]
	jne	bp3
	cmp	di, [bx+bptab+2]
	jne	bp3
	lea	dx, bpthere
	call	OutMsg
	jmp	bp12

bp3:
	add	bx, 4
	dec	cx
	jmp	short bp2

bp4:
	mov	ax, BPSOFT-1		; start at break point 10
	mov	bx, BPSOFT*4		
	mov	cx, BPHARD

bp5:
	inc	ax
	cmp	[bx+bptab], 0
	jne	bp6
	cmp	[bx+bptab+2], 0
	je	bp7

bp6:
	add	bx, 4
	loop	bp5
	lea	dx, bpfull
	call	OutMsg
	jmp	short bp12


bp7:
	mov	[bx+bptab], si
	mov	[bx+bptab+2], di
	call	bpdisp

bp12:
	xor	bh, bh

	pop	es
	pop	di
	pop	si
	pop	bp
	pop	dx
	pop	cx
	pop	ax
	ret
bpset	endp

	page
;-------------------------------------------------------------------------;
;	Function: bpclr							  ;
;		  Clear Breakpoint 0-9					  ;
;	Input:								  ;
;	Output:								  ;
;		  None - displays information to screen			  ;
;-------------------------------------------------------------------------;

bpclr	proc	near
	push	ax
	push	dx

	mov	bx, 2
	call	RemSpac
	mov	al, byte ptr [bx+buff]
	xor	ah, ah
	sub	al, '0'
	cmp	al, 10
	jb	bc2

bc1:
	lea	dx, badbp
	call	OutMsg
	jmp	short bc3

bc2:
	add	al, BPSOFT			; start at break point 10
	mov	bx, ax
	shl	bx, 1
	shl	bx, 1
	xor	dx, dx
	mov	[bx+bptab], dx		; zero out to clear break point
	mov	[bx+bptab+2], dx
	call	bpdisp

bc3:
	xor	bh, bh

	pop	dx
	pop	ax
	ret
bpclr	endp

	page
;-------------------------------------------------------------------------;
;	Function: bplist						  ;
;		  list Breakpoints 0 - 9				  ;
;	Input:								  ;
;	Output:								  ;
;		  None - displays information to screen			  ;
;-------------------------------------------------------------------------;

bplist	proc	near
	push	ax
	push	cx
	push	dx

	mov	cx, BPHARD
	mov	ax, BPSOFT-1		; start at bp 10
	xor	dx, dx

bpl1:
	inc	ax
	mov	bx, ax
	shl	bx, 1
	shl	bx, 1
	cmp	[bx+bptab], 0
	jne	bpl2
	cmp	[bx+bptab+2], 0
	je	bpl3

bpl2:
	inc	dl
	call	bpdisp

bpl3:
	loop	bpl1
	or	dl, dl
	jnz	bpl4
	lea	dx, nobrk
	call	OutMsg

bpl4:
	xor	bh, bh

	pop	dx
	pop	cx
	pop	ax
	ret
bplist	endp

	page
;-------------------------------------------------------------------------;
;	Function: bpdisp						  ;
;		  display breakpoint n					  ;
;	Input:								  ;
;		  AX = Breakpoint n					  ;
;	Output:								  ;
;		  None - displays information to screen			  ;
;-------------------------------------------------------------------------;

bpdisp	proc	near
	push	ax
	push	bx
	push	cx
	push	dx
	push	bp
	push	si
	push	di

	mov	bx, ax
	shl	bx, 1
	shl	bx, 1
	mov	bp, bx
	cmp	[bx+bptab], 0
	jne	bpd1
	cmp	[bx+bptab+2], 0
	je	bpd2

bpd1:

;	Break Point is set


	push	cx
	xchg	ax, dx
	mov	ax, [bx+bptab]
	mov	cx, 1
	lea	di, bsetmsg+20
	call	MakeHex
	mov	ax, [bx+bptab+2]
	mov	cx, 1
	lea	di, bsetmsg+25
	call	MakeHex
	xchg	dx, ax
	pop	cx
	lea	si, bsetmsg
	jmp	short bpd3

bpd2:

;	Break Point is clear

	lea	si, bclrmsg


bpd3:
	sub	al, BPSOFT
	add	al, '0'
	mov	[si+11], al
	mov	dx, si
	call	OutMsg

	pop	di
	pop	si
	pop	bp
	pop	dx
	pop	cx
	pop	bx
	pop	ax
	ret
bpdisp	endp

	page
;-------------------------------------------------------------------------;
;	Function: swap							  ;
;		  Swap to users screen and  return when key is press	  ;
;	Input:								  ;
;	Output:								  ;
;		  None - displays information to screen			  ;
;-------------------------------------------------------------------------;

swap	proc	near
	push	ax

	cmp	[dbaddr], SCREEN
	jne	swapend
	call	SwapScr		; Swap Screen Image with buffer
	call	GetKBD		; get keyboard input (bios)
	call	SwapScr		; Swap Screen Image with buffer

swapend:
	xor	bx, bx
	pop	ax
	ret
swap	endp

	page
;-------------------------------------------------------------------------;
;	Function: shell							  ;
;		  Shell to MOS Operating System				  ;
;	Input:								  ;
;	Output:								  ;
;		  None - displays information to screen			  ;
;-------------------------------------------------------------------------;

shell	proc	near
	push	ax
	push	cx
	push	dx
	push	es

	call	SizeMin
	or	ax, ax
	jz	shdo
	lea	dx, nommsg 
	call	OutMsg
	lea	dx, crlf
	call	OutMsg
	jmp	shdone

shdo:
	cmp	[dbaddr], SCREEN
	je	sh1
	call	SwapScr		; swap screen if using terminal console

sh1:
	lea	dx, shmsg
	call	OutMsg

shbeg:
	cli
	mov	[stkptr], sp
	mov	[stkseg], ss
	sti
	lea	dx, cpbuff
	lea	bx, cpparms
	mov	word ptr cpparms[02H], offset cmdout
	mov	word ptr cpparms[04H], cs
	mov	word ptr cpparms[06H], 5CH
	mov	word ptr cpparms[08H], es
	mov	word ptr cpparms[0AH], 6CH
	mov	word ptr cpparms[0CH], es
	xor	al, al
	mov	ah, 4BH		; MOS Exec Function

shdeb:
	int	21h
shret:

	push    cs
	pop	ds
	cmp	[dbaddr], SCREEN
	je	sh2
	call	SwapScr		; swap screen if using terminal console
	

sh2:
	cli
	mov	sp, [stkptr]
	mov	ss, [stkseg]
	sti
	call	SizeMin		; shrink back

shdone:
	xor	bh, bh

	pop	es
	pop	dx
	pop	cx
	pop	ax
	ret
shell	endp


	page
;-------------------------------------------------------------------------;
;	Function: config						  ;
;		  Display Debug Configuration.				  ;
;	Input:								  ;
;	Output:								  ;
;		  None - displays information to screen			  ;
;-------------------------------------------------------------------------;

config	proc	near
	push	dx

	lea	dx, chip       ; display processor chip message
	call	OutMsg
	mov	dl, [cpu]      ; get cpu ID
	xor	dh, dh
	shl	dl, 1
	shl	dl, 1
	add	dx, offset cpumsg
	call	OutMsg
	lea	dx, crlf       ; disp cr/l
	call	OutMsg
	lea	dx, nomath
	cmp	[mcpu], 0      ; no coprocessor
	je	cfig1
	lea	dx, mchip

cfig1:
	call	OutMsg
	lea	dx, dbmsg
	call	OutMsg
	lea	dx,dbad
	call	OutMsg
	lea	dx, bonmsg
	cmp	[bpflag], 1	; breakpoints on???
	je	cfig3
	lea	dx, boffmsg
cfig3:
	call	OutMsg
	xor	bh, bh

	pop	dx
	ret
config	endp

	page
;-------------------------------------------------------------------------;
;	Function: console						  ;
;		  Toggle system console.				  ;
;	Input:								  ;
;	Output:								  ;
;		  None - displays information to screen			  ;
;-------------------------------------------------------------------------;

console proc	near
	push	cx
	push	dx
	push	di

	mov	bx, 2
	call	RemSpac
	or	bx, bx
	jz	cons0
	mov	al, [bx+buff]
	cmp	al, '0'
	jb	conbad
	cmp	al, '9'
	ja	conbad
	inc	bx
	mov	ah, [bx+buff]
	cmp	ah, '0'
	jb	conbyte
	cmp	ah, '9'
	ja	conbyte
	mov	bx, ax
	xchg	al, ah
	sub	ax, '00'
	shl	ah, 1
	add	al, ah
	shl	ah, 1
	shl	ah, 1
	add	al, ah
	cmp	al, 24
	ja	conbad
	jmp	short conset

conbyte:
	mov	bx, ax
	mov	bh, ' '
	sub	al, '0'
	or	al, al
	je	conbad

conset:
	xor	ah, ah
	mov	[dbport], ax
	lea	di, dbad
	mov	[di], bl
	cmp	bh, ' '
	je	conskip
	inc	di
	mov	[di], bh
	
conskip:
	inc	di
	mov	word ptr [di], ' .'
	lea	dx, dbmsg
	call	OutMsg
	lea	dx, dbad
	call	OutMsg
	jmp	short conend

conbad:
	lea	dx, cbadmsg
	call	OutMsg
	
conend:
	xor	bh, bh

	pop	di
	pop	dx
	pop	cx
	ret
		
cons0:
	cmp	[dbaddr], SCREEN
	je	cons1
	call	SwapScr		; swap in debug screen, console is both
	mov	[dbaddr], SCREEN
	jmp	short cons2

cons1:
	call	SwapScr		; swap in user screen, console is terminal
	mov	dx, [dbport]
	mov	[dbaddr], dx
	mov	dl, 26
	call	OutChar

cons2:
	xor	bx, bx

	pop	cx
	pop	dx
	pop	cx
	ret
console endp

	page
;-------------------------------------------------------------------------;
;	Function: pause							  ;
;		  Pause for key to be pressed.				  ;
;	Input:								  ;
;	Output:								  ;
;		  None - displays information to screen			  ;
;-------------------------------------------------------------------------;

pause	proc	near
	push	ax

	cmp	[dbaddr], SCREEN
	je	pause1
	call	GetKey
	jmp	short pause2

pause1:
	call	GetKBD

pause2:
	xor	bx, bx

	pop	ax
	ret
pause	endp

	page
;-------------------------------------------------------------------------;
;	Function: delay							  ;
;		  delay execution for a while				  ;
;	Input:								  ;
;	Output:								  ;
;		  None - displays information to screen			  ;
;-------------------------------------------------------------------------;

delay	proc	near
	push	ax
	push	cx
	push	dx
	push	si
	push	di

	xor	ax, ax
	int	1AH
	mov	si, cx
	mov	di, dx

delay1:
	xor	ax, ax
	int	1AH
	cmp	cx, si
	je	delay2
	mov	ax, di
	sub	ax, dx
	dec	ax
	mov	dx, 0FFFFH
	sub	dx, ax
	cmp	dx, 19
	jb	delay1
	jmp	delay3

delay2:
	sub	dx, di
	cmp	dx, 19
	jb	delay1

delay3:
	xor	bh, bh
	pop	di
	pop	si
	pop	dx
	pop	cx
	pop	ax
	ret
delay	endp

	page
;-------------------------------------------------------------------------;
;	Function: verify						  ;
;		  verify address data and terminate debug with errorlevel ;
;		  of 1	if data does not match				  ;
;-------------------------------------------------------------------------;

verify	proc	near
	push	ax
	push	cx
	push	dx
	push	bp
	push	si
	push	di
	push	ds
	push	es

	mov	si, [regcs]
	xor	di, di
	mov	cx, 8
	mov	bx, 1
	call	GetAddr
	xchg	si, di
	mov	[valdi], di
	mov	[valsi], si
	or	bx, bx
	jz	vererr
	call	GetList
	or	cx, cx
	jnz	ver1

vererr:
	mov	bx, 1
	jmp	short verexit

ver1:
	mov	di, [valsi]
	lea	si, getbuff
	mov	es, [valdi]
	repe	cmpsb
	jz	ver2
	mov	byte ptr [NotDone], 0	; quit debug
	mov	byte ptr [retcode], 1	; with errorlevel = 1
	jmp	short verexit

ver2:
	xor	bh, bh

verexit:
	pop	es
	pop	ds
	pop	di
	pop	si
	pop	bp
	pop	dx
	pop	cx
	pop	ax
	ret
verify	endp
   
	page
;-------------------------------------------------------------------------;
;	Function: mosinfo						  ;
;		  mos information command for technical support		  ;
;	Input:								  ;
;	Output:								  ;
;		  None - displays information to screen			  ;
;-------------------------------------------------------------------------;

mosinfo proc	near
	push	cx
	push	si
	push	di
	push	es
	

	push	cs
	pop	es
	lea	si, minfo
	lea	di, buff
	mov	cl, 6
	mov	[lenbuff], cl
	rep	movsb
	call	dump		; dump command

	pop	es
	pop	di
	pop	si
	pop	cx
	ret
mosinfo endp


;-------------------------------------------------------------------------;
moss	ends

	if1
		%out   Pass 1	Completed.
	else
		%out   Pass 2	Completed.
	endif


	end
