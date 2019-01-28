	include page.inc
	title DEBUGMAN.ASM  MOS DEBUG Main Functions
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
;******************************************************************************
;---------------------------------------------------------------------------;
;  07/23/87	SAH	corrected misc problems and cleanup - MAINTENANCE   ;
;---------------------------------------------------------------------------;
;  08/20/87     SAH     faster dump output				    ;
;---------------------------------------------------------------------------;
;  04/26/90	SAH	Corrections for GO command.			    ;
;---------------------------------------------------------------------------;	
;  05/17/90	SAH	Corrections for g=c800:5			    ;
;---------------------------------------------------------------------------;	
	page
	include debugman.pub

extrn	opbuff:byte, stpflag:byte, lenbuff:byte, buff:byte, badreg:byte
extrn	crlf:byte, regmsg:byte, rop2:byte, goflag:byte, brk:byte
extrn	blank2:byte, badflag:byte, flagmsg:byte, badread:byte, badwrit:byte
extrn	lasterr:byte, nfile:byte, noname:byte, wrbytes:byte, wbyte:byte
extrn	wrname:byte, getbuff:byte, badadr:byte, badbpad:byte, isload:byte
extrn	usrterm:byte, ptn:byte, loadct:byte, loadbuf:byte, path:byte
extrn	badname:byte, nbad:byte, syntax:byte, intern:byte, sizeovr:byte
extrn	quitprg:byte, fcbbuf1:byte, fcbbuf2:byte, tmbrk:byte, segflag:byte
extrn   dumpbuff:byte
extrn	asmloc:word, dumploc:word, regcs:word, regip:word, regtran:word
extrn	regall:word, uasmloc:word, regds:word, regflag:word, wrloc:word
extrn	stkseg:word, stkptr:word, regss:word, regsp:word, tcount:word
extrn	retseg:word, retoff:word, retflag:word, userprg:word, saveip:word
extrn	sizehi:word, sizelo:word, retloc:word, fcb1loc:word, fcb2loc:word
extrn	parmblk:word, regbx:word, regcx:word, valdi:word, valsi:word
extrn	debugpsp:word, childpsp:word
extrn	GetAddr:near, GetOp:near, GetRang:near, OutMsg:near, MakeHex:near
extrn	GetHex:near, GetList:near, GetReg:near, DispOp:near, DispFg:near
extrn	RemSpac:near, UserHex:near, GetMsg:near, FixBuff:near, OutChar:near
extrn	ToFlag:near, FrFlag:near, ErrMsg:near, LoadPrg:near, ClrBrk:near
extrn	SetBrk:near, InsBrk:near, RemBrk:near, DoSwap:near, DumpReg:near
extrn	SaveReg:near, RestReg:near, SetInt:near, RestInt:near, GetAll:near
extrn	SetSS:near, RestSS:near, SetDReg:near, SaveAll:near,ValidOP:near 
extrn	SkipIns:near, MkPath:near, MakeFcb:near, SynErr:near, OutText:near

	if	0 eq 0
FILE1	equ	005CH
FILE2	equ	006CH
LINELEN equ	0080H
LINEBEG equ	0081H

BPSOFT	equ	10	; # of soft break points
BPHARD	equ	10	; # of hard break points
	endif

	include	  debugmac.inc

	page
;-------------------------------------------------------------------------;
;	Macro:	  makech						  ;
;		  sends char to pointer specify by di and increments di	  ;
;	Input:	  char to be stored					  ;
;	Output:								  ;
;-------------------------------------------------------------------------;

makech	macro	value
	mov	byte ptr [di], value
	inc	di
	endm

;-------------------------------------------------------------------------;
;	Macro:	  getareg						  ;
;		  gets a register value from translation to ax		  ;
;-------------------------------------------------------------------------;

getareg macro
	push	 bx
	mov	 bx, word ptr [bx+regtran]
	mov	 ax, word ptr [bx+regall]
	pop	 bx
	endm

	page

moss	segment word public 'code'
	assume cs:moss;ds:moss;es:moss


	page
;-------------------------------------------------------------------------;
;	MOS Debug Functions
;-------------------------------------------------------------------------;

;-------------------------------------------------------------------------;
;	Function: asm							  ;
;		  assembles intel assembly languages instructions in	  ;
;		  memory						  ;
;	Input:								  ;
;	Output:								  ;
;		  None - displays information to screen			  ;
;-------------------------------------------------------------------------;

asm	proc	near
	push	ax
	push	si
	push	di
	push	es


	mov	si, [asmloc]
	mov	di, [asmloc+2]
	mov	bx, 1
	call	GetAddr
	mov	es, si
	xchg	si, di

asm1:
	call	GetOp
	or	bh, bh
	jz	asm2
	call	SynErr		; display syntax error message

asm2:
	or	bl, bl
	jz	asm1
	mov	[asmloc], es
	mov	[asmloc+2], si
	xor	bh, bh
	pop	es
	pop	di
	pop	si
	pop	ax
	ret
asm	endp

	page
;-------------------------------------------------------------------------;
;	Function: comp							  ;
;		  compares to ranges of memory				  ;
;	Input:								  ;
;	Output:								  ;
;		  None - displays information to screen			  ;
;-------------------------------------------------------------------------;

comp	proc	near
	push	ax
	push	cx
	push	si
	push	di
	push	bp
	push	ds
	push	es

	lea	di, opbuff
	mov	ax, 2020h
	mov	cx, 39
	rep	stosw
	mov	cx, 1
	mov	si, [regds]
	xor	di, di
	mov	bx, 1
	call	GetRang
	or	bx,bx
	jnz	comp0
	inc	bh
	jmp	comp5

comp0:
	mov	dx, di		; save offset
	mov	es, si		; save segment
        mov	cx, bp
	sub	cx, dx
	call	GetAddr
	push	es
	pop	ds
	mov	es, si		; get segment of destination
	mov	si, dx		; get offset of destination
	mov	bx, di
	lea	di, opbuff

comp1:
	push	cx
	mov	al, byte ptr [si]
	cmp	al, byte ptr es:[bx]
	je	comp2
	mov	bp, ax
	mov	ax, ds
	push	ds
	push	cs
	pop	ds
	mov	cx, 1
	call	MakeHex
	makech	':'
	mov	ax, si
	call	MakeHex
	makech	' '
	mov	ax, bp
	xor	cl, cl
	call	MakeHex
	makech	' '
	mov	al, byte ptr es:[bx]
	call	MakeHex
	makech	' ' 
	mov	ax, es
	mov	cl, 1
	call	MakeHex
	makech	':'
	mov	ax, bx
	call	MakeHex
	push	dx
	lea	dx, opbuff
	call	OutMsg
	pop	dx
	pop	ds


comp2:
	inc	si
	inc	bx
	lea	di, opbuff
	pop	cx
	loop	comp1
	jmp	short comp4

comp3:
	pop	ds
	pop	cx
	
comp4:	
	xor	bh, bh

comp5:
	pop	es
	pop	ds
	pop	bp
	pop	di
	pop	si
	pop	cx
	pop	ax
	ret
comp	endp

	page
;-------------------------------------------------------------------------;
;	Function: dump							  ;
;		  dumps the memory at specific location to user and	  ;
;		  update defaults.					  ;
;	Input:								  ;
;	Output:								  ;
;		  None - displays information to screen			  ;
;-------------------------------------------------------------------------;

dump	proc	near
	push	ax
	push	cx
	push	si
	push	di
	push	bp
	push	es

	push	cs
	pop	es
	mov	si, [dumploc]
	mov	di, [dumploc+2]
	mov	cx, 8*16
	mov	bx, 1
	call	GetRang
	call    ValidOP
	jnc     dump0
	mov     bh, bl
	jmp	dumpdon

dump0:
	mov	es, si
	xchg	si, di

dump1:
	push	cx
	push	es
	push	cs
	pop	es
	lea	di, dumpbuff
	mov	ax, 2020h
	mov	cx, 39
	rep	stosw		; clear buffer
	pop	es
	lea	di, dumpbuff
	mov	ax, es
	mov	cx, 1
	call	MakeHex
	mov	byte ptr [di], ':'
	inc	di
	mov	ax, si
	call	MakeHex
	mov	word ptr [di], 2020h
	inc	di
	inc	di
	pop	cx
	and	cx, 0fh
	add	di, cx
	add	di, cx
	add	di, cx

dump2:
	mov	al, byte ptr es:[si]
	push	ax
	push	cx
	xor	cx, cx
	call	MakeHex
	pop	cx
	mov	al, ' '
	cmp	cx, 7
	jne	dump3
	cmp	si, bp
	jae	dump3
	mov	al, '-'

dump3:
	mov	byte ptr [di], al
	inc	di
	pop	ax
	push	di
	lea	di, dumpbuff+61
	add	di, cx
	cmp	al, 20h
	jb	dump4
	cmp	al, 7fh
	jb	dump5

dump4:
	mov	al, '.'

dump5:
	mov	byte ptr [di], al
	pop	di
	inc	cx
	cmp	cl, 10h
	jb	dump7

dump6:
	xor	cx, cx
	xchg	ax, dx
	lea	dx, dumpbuff
	call	OutText
	push    dx
	mov	dl,13
	call	OutChar
	mov	dl,10
	call	OutChar
	pop	dx
	xchg	ax, dx	

dump7:
	inc	si
	cmp	si, bp
	ja	dump9
	or	cx, cx
	jnz	dump8
	or	si, si
	jz	dump10
	jmp	dump1
	

dump8:
	jmp	dump2


dump9:
	or	cx, cx
	jnz	dump6

dump10:
	mov	[dumploc+2], si
	mov	[dumploc], es
	xor	bh, bh

dumpdon:
	pop	es
	pop	bp
	pop	di
	pop	si
	pop	cx
	pop	ax
	ret
dump	endp

	page
;-------------------------------------------------------------------------;
;	Function: entr							  ;
;		  enter memory contents					  ;
;	Input:								  ;
;	Output:								  ;
;		  None - displays information to screen			  ;
;-------------------------------------------------------------------------;

entr	proc	near
	push	ax
	push	cx
	push	dx
	push	bp
	push	si
	push	di
	push	ds
	push	es

	mov	si, [regds]
	xor	di, di
	mov	cx, 8
	mov	bx, 1
	call	GetAddr
	xchg	si, di
	mov	[valdi], di
	mov	[valsi], si
	or	bx, bx
	jz	entr2
	call	GetList
	or	cx, cx
	jz	entr2

entr1:
	mov	di, [valsi]
	lea	si, getbuff
	mov	es, [valdi]
	rep	movsb
	jmp	entrdon

entr2:
	lea	di, opbuff
	mov	cx, 38
	mov	ax, 2020h
	rep	stosw
	lea	di, opbuff
	mov	ax, [valdi]
	mov	cx, 1
	call	MakeHex
	makech	':'
	mov	ax, si
	call	MakeHex
	inc	di
	makech	'$'
	lea	dx, opbuff
	call	OutMsg
	xor	bx, bx

entr21:
	lea	di, opbuff
	push	es
	mov	es, [valdi]
	mov	al, byte ptr es:[si]
	pop	es
	xor	cx, cx
	call	MakeHex
	makech	'.'
	makech	'$'
	call	OutMsg
	mov	cx, 2
	call	UserHex

entrus:
	push	es
	mov	es, [valdi]
	mov	byte ptr es:[si], al
	pop	es
	or	cx, cx		; exit
	jz	entr23


entr22:
	inc	si
	mov	word ptr [opbuff], 2020H
	mov	byte ptr [opbuff+2], '$'
	call	OutMsg
	inc	bx
	cmp	bl, 8
	jb	entr21
	lea	dx, crlf
	call	OutMsg
	jmp	entr2

entr23:
	lea	dx, crlf
	call	OutMsg

entrdon:
	push	cs
	pop	es
	lea	di, opbuff
	mov	cx, 38
	mov	ax, 2020h
	rep	stosw


	pop	es
	pop	ds
	pop	di
	pop	si
	pop	bp
	pop	dx
	pop	cx
	pop	ax
	ret
entr	endp

	page
;-------------------------------------------------------------------------;
;	Function: fill							  ;
;		  fill a range of memory with specific value(s)		  ;
;	Input:								  ;
;	Output:								  ;
;		  None - displays information to screen			  ;
;-------------------------------------------------------------------------;

fill	proc	near
	push	cx
	push	bp
	push	si
	push	di
	push	es 

	mov	si, [regds]
	xor	di, di
	mov	cx, 7
	mov	bx, 1
	call	GetRang
	cmp	bp, di
	jbe	fillend
	sub	bp, di
	mov	es, si
	call	GetList
	or	cx, cx
	jz	fillend 
	xchg	cx, bp
	inc	cx
	mov	bx, bp
	lea	si, getbuff
	
fill1:
	or	bx, bx
	jnz	fill2
	mov	bx, bp
	lea	si, getbuff

fill2:
	dec	bx
	movsb
	loop	fill1

fillend:
	xor	bh, bh

	pop	es
	pop	di
	pop	si
	pop	bp
	pop	cx
	ret
fill	endp


	page
;-------------------------------------------------------------------------;
;	Function: go							  ;
;		  executes program in fast mode				  ;
;	Input:								  ;
;	Output:								  ;
;		  None - displays information to screen			  ;
;-------------------------------------------------------------------------;

go	proc	near
	push	ax
	push	cx
	push	dx
	push	si
	push	di

	mov	[goflag], 1
	xor	al, al
	mov	cx, BPSOFT

gosclr:
	call	ClrBrk		; clear go break point
	inc	al
	loop	gosclr

	xor	cx, cx
	mov	bx, 1
	call	RemSpac
	or	bx, bx
	jz	go4
	mov	si, [regcs]
	mov	di, [regip]
	cmp	byte ptr [bx+buff], '='
	jne	go2		; no start address specified
	inc	bx
	call	GetAddr		; get address
	or	bx, bx
	jnz	go1
	lea	dx, badadr
	call	OutMsg
	jmp	goend
	
go1:
	mov	[regcs], si
	mov	[regip], di

go2:
	call	RemSpac
	or	bx, bx
	jz	go4
	call	GetAddr
	or	bx, bx
	jnz	go3
	lea	dx, badbpad
	call	OutMsg
	jmp	goend

go3:
	xchg	si, di
	mov	dx, si
	mov	al, cl
	cmp	cl, BPSOFT
	jae	go3bad
	call	SetBrk
	inc	cx
	mov	si, [regcs]	; get default code segment
	mov	di, [regip]
	jmp	go2
	
go3bad:
	lea	dx, tmbrk	; too many break boints
	call	OutMsg		
	jmp	goend

go4:		; now the fun starts
	mov	bx, [childpsp]
	mov	ah, 50h
	int	21h
	mov	byte ptr [segflag], 1	; defaults will change
	xor	al,al			; don't quit debug
	mov	dx, [childpsp]
	cmp	dx, [regcs]
	je	OnPSP
	inc	al		; not on psp quit debug
OnPSP:
	mov	[quitprg], al	
	mov	[usrterm], 0	; user has not terminated yet
	mov	[brk], 0	; indicate no break 
	call	InsBrk		; insert break points into the code
	call	DoSwap		; swap screen if neccessary
	mov	[retseg], cs	; save segment of program
	mov	word ptr [retoff], offset goret
	mov	ax, [regflag]
	mov	[retflag], ax	; save return flags
	mov	ax, [regip]
	mov	[userprg], ax	; save user prg offset
	mov	ax, [regcs]
	mov	[userprg+2], ax ; save user prg segment 
	call	SetInt		; enamble interupts	
	call	SaveAll		; save registers
	call	RestReg		; restore to original register
	UserStk			; user stack
	push	cs:[regflag]
	popf
	jmp	dword ptr cs:[userprg]

;	return from breakpoint, terminate....


goret:
	PrgStk			; program stack
	call	GetAll		; get registers 
	call	RestInt		; disable interupts
	call	RemBrk		; remove break points from the code
	call	DoSwap		; swap screens if necessary
	mov	bx, [debugpsp]
	mov	ah, 50h
	int	21h
	cmp	[usrterm], 0	; no user terminated
	je	go5
	lea	dx, ptn
	call	OutMsg		; display  terminate message
	jmp	short goend

go5:
	cmp	[brk], 0	; user break
	je	goend
	call	SetDReg		; set debug registers
	call	DumpReg		; dump registers

goend:
	mov	[goflag], 0
	xor	bh, bh

	pop	di
	pop	si
	pop	dx
	pop	cx
	pop	ax
	ret
go	endp

	page
;-------------------------------------------------------------------------;
;	Function: hex							  ;
;		  performs hexidecimal arithmetric functions		  ;
;	Input:								  ;
;	Output:								  ;
;		  None - displays information to screen			  ;
;-------------------------------------------------------------------------;


hex	proc	near
	push	ax
	push	cx
	push	dx
	push	bp
	push	di

	lea	di, opbuff
	mov	ax, 2020h
	mov	cx, 39
	rep	stosw
	mov	cx, 4
	mov	bx, 1
	call	GetHex
	mov	dx, ax
	call	GetHex
	mov	bp, ax
	lea	di, opbuff
	add	ax, dx
	mov	cl, 1
	call	MakeHex
	inc	di
	mov	ax, dx
	sub	ax, bp
	call	MakeHex
	lea	dx, opbuff
	call	OutMsg
	xor	bh, bh

	pop	di
	pop	bp
	pop	dx
	pop	cx
	pop	ax
	ret
hex	endp

	page
;-------------------------------------------------------------------------;
;	Function: input							  ;
;		  input byte from a specific port			  ;
;	Input:								  ;
;	Output:								  ;
;		  None - displays information to screen			  ;
;-------------------------------------------------------------------------;

input	proc	near
	push	ax
	push	cx
	push	dx
	push	di

	mov	bx, 1
	mov	cx, 4
	call	GetHex
	or	bx, bx
	jne	input1
	jmp	short input2

input1:
	mov	dx, ax
	in	al, dx
	lea	di, opbuff
	xor	cx, cx
	call	MakeHex
	mov	byte ptr [di], 13
	mov	byte ptr [di+1], 10
	mov	byte ptr [di+2], '$'
	lea	dx, opbuff
	call	OutMsg
	mov	word ptr [di], 2020h
	mov	word ptr [di+2], 2020h
	mov	word ptr [di+4], 2020h

input2:
	xor	bh, bh
	pop	di
	pop	dx
	pop	cx
	pop	ax
	ret
input	endp

	page
;-------------------------------------------------------------------------;
;	Function: load							  ;
;		  load's a sector of file from disk			  ;
;	Input:								  ;
;	Output:								  ;
;		  None - displays information to screen			  ;
;-------------------------------------------------------------------------;

load	proc	near
	push	ax
	push	cx
	push	dx
	push	bp
	push	si
	push	di

	mov	bx, 1
	mov	si, [regcs]	; get default load segment
	mov	di, [regip]	; get default load segment
	call	RemSpac		; remove spaces
	or	bx, bx
	jz	load1		; no parms use defaults and load program
	call	GetAddr		; get load address
	call	RemSpac		; remove spaces
	or	bx, bx
	jz	load1		; error in syntax....
	mov	cx, 2
	call	GetHex
	or	bx, bx
	jnz	load2		; drive parameter found!

badload:
	jmp	lderr

load1:

;	Load Program name1

	cmp	[nfile], 1
	je	load1a
	lea	dx, noname
	call	OutMsg
	jmp	ldok

load1a:
	cmp	[isload], 1	; is program in memory
	jne	lskip		; no...skip termination
	mov	[quitprg], 1	; indicated internal quit to user program
	mov	[retloc], offset lreturn
	call	RestReg
	UserStk
	mov	ax, 4c00h
	int	21h

lreturn:
	mov	ax, cs
	mov	ds, ax
	mov	es, ax
	cli
	mov	ss, [stkseg]
	mov	sp, [stkptr]
	sti

lskip:
	mov	byte ptr [segflag],1 ; defaults will change
	mov	word ptr [fcb1loc],  FILE1
	mov	word ptr [fcb2loc],  FILE2
	mov	cl, [loadct]
	lea	si, loadbuf
	lea	bx, parmblk
	call	LoadPrg		; load program into memory
	mov	al, [lasterr]
	call	ErrMsg
	jmp	ldok

load2:
	mov	dl, al		; save drive
	call	RemSpac
	or	bx, bx
	jz	lderr		; parameter error
	push	si
	push	di
	xor	si, si
	call	GetAddr
	mov	bp, di		; save start sector
	mov	[valsi], si
	pop	di
	pop	si
	call	RemSpac
	or	bx, bx
	jz	load3		; use default of 1 sector
	call	GetHex
	or	bx, bx
	jz	load3		; use default of 1 sector
	mov	cx, ax		; save count
	jmp	short load4

lderr:
	mov	bh, 3
	jmp	ldexit

load3:
	mov	cx, 1

load4:

;	Load sectors in

	push	ds
	mov	al, dl		; get drive
	mov	bx, di		; get offset
	mov	ds, si		; get segment
	mov	dx, bp		; get start sector
	mov	si, cs:[valsi]	; large drive support
	or	si, si
	jz	loaddo
	mov	di, -4		; -4 means large volume

loaddo:	
	int	25h
	jnc	loadok
	push	cs
	pop	ds
	lea	dx, badread
	call	OutMsg

loadok:
	popf
	pop	ds

ldok:
	xor	bh, bh

ldexit:
	pop	di
	pop	si
	pop	bp
	pop	dx
	pop	cx
	pop	ax
	ret
load	endp

	page
;-------------------------------------------------------------------------;
;	Function: move							  ;
;		  moves a range of memory to somewhere else		  ;
;	Input:								  ;
;	Output:								  ;
;		  None - displays information to screen			  ;
;-------------------------------------------------------------------------;

move	proc	near
	push	ax
	push	cx
	push	dx
	push	si
	push	di
	push	bp
	push	ds
	push	es
	pushf

	mov	cx, 1
	mov	si, [regds]
	xor	di, di
	mov	bx, 1
	call	GetRang
	cmp	bp, di
	jbe	moveend
	mov	dx, di		; save offset
	mov	es, si		; save segment
	mov	cx, bp
	sub	cx, dx
	inc	cx
	call	GetAddr
	push	es
	pop	ds
	mov	es, si		; get segment of destination
	mov	si, dx		; get offset of destination

movinit:
	xchg	cx, bp		; place cx in bp
	mov	ax, ds
	mov	dx, es
	cmp	ax, dx		; is source seg >= destination seg
	jae	move1
	sub	dx, ax		; dest - source
	mov	cl, 4
	shl	dx, cl		; dest = (dest - source) * 16
	xor	ax, ax		; source = 0
	jmp	short move2

move1:
	sub	ax, dx		; source - dest
	mov	cl, 4
	shl	ax, cl		; source = (source - dest) * 16
	xor	dx, dx		; dest = 0

move2:
	add	ax, si		; source = source + offset
	add	dx, di		; dest = dest + offset
	cmp	ax, dx		; source >= dest
	jae	move3
	sub	dx, ax		; diff = dest - source
	mov	ax, dx
	jmp	short move4

move3:
	sub	ax, dx		; diff = source - dest

move4:
	cld
	cmp	ax, bp		; compare diff to count (in BP, save above)
	ja	move5
	std
	add	si, bp		; adjust for backword!!!!
	dec	si
	add	di, bp
	dec	di

move5:
	xchg	cx, bp		; get cx from bp
	rep	movsb		; move data

moveend:
	xor	bh, bh

	popf
	pop	es
	pop	ds
	pop	bp
	pop	di
	pop	si
	pop	dx
	pop	cx
	pop	ax
	ret
move	endp

	page
;-------------------------------------------------------------------------;
;	Function: nameout						  ;
;		  names the disk file for storage			  ;
;	Input:								  ;
;	Output:								  ;
;		  None - displays information to screen			  ;
;-------------------------------------------------------------------------;

nameout proc	near
	push	ax
	push	cx
	push	si
	push	di
	push	bp
	push	es

	push	cs
	pop	es
	mov	cl, [lenbuff]
	xor	ch, ch
	lea	si, buff+1
	push	cx
	push	si
	lea	di, loadbuf
	dec	cl
	mov	[loadct], cl
	rep	movsb
	mov	al, 0dh
	stosb
	pop	si
	pop	cx
	mov	es, [regds]
	mov	es:[LINELEN], cl
	dec	cl
	mov	di, LINEBEG
	rep	movsb
	mov	al, 0dh
	stosb
	lea	si,buff+1
	mov	di,FILE1
	call	MakeFcb
	or	si, si
	jz	nerr1
	mov	di, FILE2
	call	MakeFcb
	or	si, si
	jnz	nameset
	mov	al, '2'
	jmp	short nameerr

nerr1:
	mov	al, '1'

nameerr:
	mov	byte ptr [nbad], al
	push	dx
	lea	dx, badname
	call	OutMsg
	pop	dx
	jmp	short namedon

nameset:
	mov	[nfile], 1	; indicate that file has been named

namedon:
	xor	bh, bh

	pop	es
	pop	bp
	pop	di
	pop	si
	pop	cx
	pop	ax
	ret
nameout endp


	page
;-------------------------------------------------------------------------;
;	Function: output						  ;
;		  output byte to a specific port			  ;
;	Input:								  ;
;	Output:								  ;
;		  None - displays information to screen			  ;
;-------------------------------------------------------------------------;

output	proc	near
	push	ax
	push	cx
	push	dx

	mov	bx, 1
	mov	cx, 4
	call	GetHex
	or	bx, bx
	jne	output2
	jmp	short output3


output2:
	mov	dx, ax
	mov	cx, 2
	call	GetHex
	out	dx, al

output3:
	xor	bh, bh
	pop	dx
	pop	cx
	pop	ax
	ret
output	endp

	page
;-------------------------------------------------------------------------;
;	Function: proceed						  ;
;		  proceed to next instruction				  ;
;	Input:								  ;
;	Output:								  ;
;		  None - displays information to screen			  ;
;-------------------------------------------------------------------------;

proceed proc	near
	push	ax
	push	cx
	push	dx
	push	si
	push	di

	xor	al, al
	mov	cx, BPSOFT
	
psclr:
	call	ClrBrk		; clear Break Point
	inc	al
	loop	psclr

	xor	cx, cx
	mov	word ptr [tcount], 1
	mov	bx, 1
	call	RemSpac
	or	bx, bx
	jz	p4
	mov	si, [regcs]
	mov	di, [regip]
	cmp	byte ptr [bx+buff], '='
	jne	p2		; no start address specified
	inc	bx
	call	GetAddr		; get address
	or	bx, bx
	jnz	p1
	lea	dx, badadr
	call	OutMsg
	jmp	tend
	
p1:
	mov	[regcs], si
	mov	[regip], di

p2:
	call	RemSpac
	or	bx, bx
	jz	p3
	mov	cl, 4
	call	GetHex
	or	bx, bx
	jnz	p3
	lea	dx, badbpad
	call	OutMsg
	jmp	pend

p3:
	or	ax, ax
	jz	p4
	mov	[tcount], ax

p4:		; now the fun starts
	mov	byte ptr [segflag], 1 ; defaults will change
	mov	[brk], 0	; indicate no break
	call	DoSwap		; swap screen if neccessary
	mov	[retseg], cs	; save segment of program
	mov	ax, [regflag]
	mov	[retflag], ax	; save return flags
	mov	ax, [regip]
	mov	[userprg], ax	; save user prg offset
	mov	ax, [regcs]
	mov	[userprg+2], ax ; save user prg segment

;	test for skip on next instruction
;	skip on calls, reps, ints

	call	SkipIns		; test for skip
	cmp	al, 0cch	; int3
	je	pskip
	or	al, al		; skip???
	jnz	p4a		; yes...
	jmp	p7

;	do a go until break point occurs


p4a:
	mov	[quitprg], 0	; don't do termination
	mov	[goflag], 1
	mov	word ptr [retoff], offset pbret
	mov	dx, [childpsp]
	mov	ah, 50h
	int	21h
	call	InsBrk		; set break points
	call	SetInt		; set up interupts for go
	call	SaveAll		; save registers
	call	RestReg		; restore registers to user program
	UserStk			; user Stack
	push	cs:[regflag]
	popf
	jmp	dword ptr cs:[userprg]

;	return from break point, terminate

pbret:
	PrgStk			; debugs stack
	call	GetAll		; get registers
	call	RestInt		; restore interupts
	call	RemBrk		; remove breaks
	mov	dx, [debugpsp]
	mov	ah, 50h
	int	21h

pskip:
	call	DoSwap		; swap screens
	cmp	[usrterm], 0	; child terminated
	je	p5
	lea	dx, ptn
	call	OutMsg
	jmp	pend

p5:
	cmp	[brk], 0
	jne	pdump
	jmp	pend


p7:
	mov	word ptr [retoff], offset ptret
	call	SetSS		; enamble interupt 01	  
	PushAll			; save registers
	call	RestReg		; restore to original register
	UserStk			; user stack
	push	cs:[regflag]
	popf
	SetTFlg			; set trace flag
	jmp	dword ptr cs:[userprg]

;	return from breakpoint, terminate....


ptret:
	prgstk			; program stack
	PopAll			; get registers 
	call	RestSS		; disable interupt 01
	call	DoSwap		; swap screens
	call	SetDReg		; set values use by debugger

pdump: 
	call	DumpReg

pend:
	mov	[goflag], 0
	xor	bh, bh

	pop	di
	pop	si
	pop	dx
	pop	cx
	pop	ax
	ret
proceed endp

	page
;-------------------------------------------------------------------------;
;	Function: reg							  ;
;		  Displays Register Information to user and allows user	  ;
;		  to change his registers.				  ;
;	Input:								  ;
;	Output:								  ;
;		  None - displays information to screen			  ;
;-------------------------------------------------------------------------;

reg	proc	near
	push	ax
	push	cx
	push	dx
	push	si
	push	di
	push	ds

	mov	bx, 1
	call	RemSpac
	or	bx, bx
	jnz	rf1
	jmp	regskip

rf1:
	cmp	byte ptr [bx+buff], 'F' ; test for reg flag test
	je	rf2
	jmp	rfskip

rf2:
	lea	dx, flagmsg
	call	OutMsg
	call	DispFg
	lea	dx, crlf
	call	OutMsg
	lea	si, buff
	mov	cx, 80h
	call	GetMsg
	lea	dx, crlf
	call	OutMsg
	xor	dx, dx
	or	cl, cl	   
	je	rfdone
	mov	[lenbuff], cl
	xor	bx, bx
	cmp	byte ptr [bx+buff], ' '
	jne	rf3
	call	RemSpac
	or	bx, bx
	jz	rfdone

rf3:
	mov	cx, 8
	mov	dh, 128		; value for top flag

rf4:
	cmp	byte ptr [bx+buff], '0'
	je	rf5
	cmp	byte ptr [bx+buff], '1'
	jne	rfbad
	or	dl, dh		; set bit

rf5:
	shr	dh, 1		; move one bit down
	inc	bx
	loop	rf4
	jmp	short rfset
	

rfbad:
	mov	al, byte ptr [bx+buff]
	or	al, al
	jz	rfset
	cmp	al, ' '
	je	rfset
	lea	dx, badflag
	call	OutMsg
	jmp	rfdone

rfset:
	xor	ah, ah
	mov	al, dl		; mask out flags turn off
	call	ToFlag		; save flags

rfdone:
	jmp	reg3
rfskip:
	call	GetReg
	or	bx, bx
	jnz	reg00

regskip:
	jmp	reg04

reg00:
	mov	dl, ah
	xor	dh, dh
	cmp	dl, 14
	jb	reg01
	lea	dx, badreg
	call	OutMsg
	jmp	reg3

reg01:
	dec	dx
	lea	di, opbuff
	mov	bx, dx
	shl	bx, 1
	add	bx, dx
	mov	ax, word ptr [bx+1+rop2]
	mov	word ptr [di], ax
	inc	di
	inc	di
	makech	' '
	mov	bx, dx
	shl	bx, 1
	push	bx
	mov	ax, word ptr [bx+regall]
	mov	cl, 1
	call	MakeHex
	makech	13
	makech	10
	makech	':'
	makech	'$'
	push	dx
	lea	dx, opbuff
	call	OutMsg
	pop	dx
	lea	si, buff
	mov	cx, 80h
	call	GetMsg

regdeb:
	or	cl, cl
	jz	reg03
	mov	[lenbuff], cl
	xor	bx, bx
	call	FixBuff
	xor	ch, ch
	xor	bx, bx

reg01a:
	mov	al, byte ptr [bx+buff]
	inc	bx
	cmp	al, ' '		; excludes spaces for this test
	je	reg01c
	cmp	al, '0'		; test for 0...9
	jb	reg01b
	cmp	al, '9'		; test for 0...9
	jbe	reg01c

reg01b:
	cmp	al, 'A'		; test for A...F
	jb	reg01d
	cmp	al, 'F'		; test for A...F
	ja	reg01d

reg01c:
	loop	reg01a
	jmp	short reg01e

reg01d:
	xchg	bl, bh
	pop	cx		; discard old bx
	jmp	short reg4

reg01e:
	xor	bx, bx
	mov	cx, 4
	call	GetHex
	or	bx, bx
	jnz	reg02
	pop	bx
	mov	bh, 1
	jmp	short reg4

reg02:
	pop	bx
	push	bx
	mov	word ptr [bx+regall], ax
	cmp	bx, 12h
	jne	reg02a
	mov	[asmloc], ax
	mov	[uasmloc], ax
	jmp	short reg03

reg02a:
	cmp	bx, 16h
	jne	reg03
	mov	[dumploc], ax

reg03:
	pop	bx
	jmp	short reg3

reg04:
	call	DumpReg		; dump register values

reg3:
	xor	bh, bh

reg4:
	pop	ds
	pop	di
	pop	si
	pop	dx
	pop	cx
	pop	ax
	ret
reg	endp

	page
;-------------------------------------------------------------------------;
;	Function: search						  ;
;		  search memory for specific values			  ;
;	Input:								  ;
;	Output:								  ;
;		  None - displays information to screen			  ;
;-------------------------------------------------------------------------;


search	proc	near
	push	ax
	push	cx
	push	bp
	push	si
	push	di
	push	es

	lea	di, opbuff
	mov	cx, 39
	mov	ax, 2020h
	rep	stosw
	mov	si, [regds]
	xor	di, di
	mov	cx, 8
	mov	bx, 1
	call	GetRang
	sub	bp, di
	mov	es, si
	call	GetList
	or	cx, cx
	jz	srchend
	xchg	cx, bp
	inc     cx
	inc	bp

srchlp:
	push	cx
	push	di
	lea	si, getbuff
	mov	cx, bp
	repe	cmpsb
	or	cx, cx
	jne	srchsk
	pop	di
	push	di
	push	dx
	push	es
	mov	ax, es
	push	cs
	pop	es 
	
	mov	dx, di
	lea	di, opbuff
	mov	cl, 1
	call	MakeHex
	makech	':'
	mov	ax, dx
	call	MakeHex
	makech	13
	makech	10
	makech	'$'
	lea	dx, opbuff
	call	OutMsg

	pop	es
	pop	dx
	

srchsk: 
	pop	di

srchnx:
	pop	cx
	inc	di
	loop	srchlp

srchend:
	xor	bh, bh
	pop	es 
	pop	di
	pop	si
	pop	bp
	pop	cx
	pop	ax
	ret
search	endp

	page
;-------------------------------------------------------------------------;
;	Function: trace							  ;
;		  trace program to next instruction			  ;
;									  ;
;	Output:								  ;
;		  None - displays information to screen			  ;
;-------------------------------------------------------------------------;


trace	proc	near
	push	ax
	push	dx
	push	si
	push	di

	mov	word ptr [tcount], 1
	mov	bx, 1
	call	RemSpac
	or	bx, bx
	jz	t4
	mov	si, [regcs]
	mov	di, [regip]
	cmp	byte ptr [bx+buff], '='
	jne	t2		; no start address specified
	inc	bx
	call	GetAddr		; get address
	or	bx, bx
	jnz	t1
	lea	dx, badadr
	call	OutMsg
	jmp	tend
	
t1:
	mov	[regcs], si
	mov	[regip], di

t2:
	call	RemSpac
	or	bx, bx
	jz	t3
	mov	cl, 4
	call	GetHex
	or	bx, bx
	jnz	t3
	lea	dx, badbpad
	call	OutMsg
	jmp	tend

t3:
	or	ax, ax
	jz	t4
	mov	[tcount], ax

t4:		; now the fun starts
	mov	byte ptr [segflag], 1
	mov	[brk], 0	; indicate no break
	push	es
	mov	es, [regcs]
	mov	bx, [regip]
	mov	dl, byte ptr es:[bx]
	mov	dh, byte ptr es:[bx+1]
	pop	es
	cmp	dl, 0cch	; int 3???
	jne	t4a
	inc	[regip]
	jmp	tskip

t4a	label		near	
	call	DoSwap		; swap screen if neccessary
	mov	[retseg], cs	; save segment of program
	mov	word ptr [retoff], offset tret
	mov	ax, [regflag]
	mov	[retflag], ax	; save return flags
	mov	ax, [regip]
	mov	[userprg], ax	; save user prg offset
	mov	ax, [regcs]
	mov	[userprg+2], ax ; save user prg segment
	call	SetSS		; enamble interupt 01	  
	PushAll			; save registers
	cmp	dl, 0cdh	; int xx
	jne	t4b
	
;	simulate int instrunction

	mov	al, dh		; get interupt
	mov	ah, 35h		; get interupt function
	push	es
	int	21h
	mov	[userprg+2], es ; save segment
	pop	es
	mov	[userprg], bx	; save offset
;	inc	[tcount]
	mov	ax, [regip]
	inc	ax
	inc	ax
	mov	[saveip], ax
	call	RestReg
	UserStk 
	push	cs:[regflag]
	popf
	pushf
	push	cs:[regcs]
	push	cs:[saveip]
	SetTFlg			; set trace flags
	cli
	jmp	dword ptr cs:[userprg]

t4b:
	call	RestReg		; restore to original register
	UserStk			; user stack
	push	cs:[regflag]
	popf
	SetTFlg			; set trace flag
	jmp	dword ptr cs:[userprg]

;	return from breakpoint, terminate....


tret:
	prgstk			; program stack
	PopAll			; get registers 
	call	RestSS		; disable interupt 01
	call	DoSwap		; swap screens

tskip:
	call	SetDReg		; set values use by debugger
	call	DumpReg

tend:
	xor	bh, bh

	pop	di
	pop	si
	pop	dx
	pop	ax
	ret
trace	endp

	page
;-------------------------------------------------------------------------;
;	Function: unasm							  ;
;		  Displays Unassemble code to user.			  ;
;	Input:								  ;
;	Output:								  ;
;		  None - displays information to screen			  ;
;-------------------------------------------------------------------------;

unasm	proc	near
	push	cx
	push	si
	push	di
	push	bp
	push	ds

	mov	si, [uasmloc]
	mov	di, [uasmloc+2]
	mov	cx, 32
	mov	bx, 1
	mov	bp, si
	add	bp, cx
	call	GetRang
	mov	ds, si
	mov	bx, di


unasm1:
	call	DispOp
	cmp	bx, bp
	jbe	unasm1

unasm2: 
	mov	cs:[uasmloc], ds
	mov	cs:[uasmloc+2], bx

	xor	bh, bh
	pop	ds
	pop	bp
	pop	di
	pop	si
	pop	cx
	ret
unasm	endp


	page
;-------------------------------------------------------------------------;
;	Function: write							  ;
;		  writes a sector to file on disk			  ;
;	Input:								  ;
;	Output:								  ;
;		  None - displays information to screen			  ;
;-------------------------------------------------------------------------;

write	proc	near
	push	ax
	push	cx
	push	dx
	push	bp
	push	si
	push	di
	push	es

	mov	bx, 1
	mov	si, [regcs]	; get default write segment
	mov	di, [wrloc]	; get default write segment
	call	RemSpac		; remove spaces
	or	bx, bx
	jz	write1		; no parms use defaults and write program
	call	GetAddr		; get write address
	call	RemSpac		; remove spaces
	or	bx, bx
	jnz	write0
	jmp	write1		
 
write0:
	mov	cx, 2
	call	GetHex
	or	bx, bx
	jnz	write0a		; drive parameter found!
	jmp	write1

write0a:
	jmp	write2		; augh segmentation !!!!

write1:
	cmp	[nfile], 1
	je	write1a
	lea	dx, noname
	call	OutMsg
	jmp	wrok

write1a:
	push	si
	push	si
	push	di
	lea	di, wbyte
	mov	ax, [regbx]
	mov	cl, 1
	call	MakeHex
	lea	di, wbyte+4
	mov	ax, [regcx]
	call	MakeHex
	lea	dx, wrbytes
	call	OutMsg
	lea	dx, wrname
	call	OutMsg
	lea	si, loadbuf
	mov	cl, [loadct]
	xor	ch, ch
	
wloop:
	lodsb
	cmp	al, 'a'
	jb	wnext
	cmp	al, 'z'
	ja	wnext
	sub	al, 'a'
	add	al, 'A'

wnext:
	mov	dl, al
	call	OutChar
	loop	wloop

	lea	dx, crlf
	call	OutMsg
	pop	di
	pop	si
	mov	cl, [loadct]
	xor	ch, ch
	lea	si, loadbuf
	call	MkPath
	pop	si
	mov	ax, 3d32h	; open handle
	lea	dx, path
	int	21h
	jnc	write1b
	cmp	al, 2
	jne	nocreat
	mov	ah, 3ch		; create handle
	xor	cx, cx		; normal attribute
	int	21h
	jnc	write1b		; no errors...continue

nocreat:
	call	ErrMsg
	jmp	wrok

write1b:
	mov	bx, ax		; save handle
	push	ds
	mov	ax, [regcx]
	mov	[sizelo], ax
	mov	ax, [regbx]
	mov	[sizehi], ax 
	
write1c:
	mov	cx, 0ff00h	; set up max characters to write
	cmp	[sizehi], 0
	jne	write1e
	cmp	[sizelo], 0 
	jne	write1d
	jmp	write1i

write1d:
	mov	cx, [sizelo]

write1e:
	mov	ds, si
	mov	dx, di
	mov	ah, 40h
	int	21h
	jnc	write1f
	pop	ds
	jmp	wfilerr		; file error

write1f:
	push	cs
	pop	ds
	push	ax		; save actual bytes written
	mov	cx, ax
	shr	ax, 1
	shr	ax, 1
	shr	ax, 1
	shr	ax, 1
	and	cx, 3
	add	di, cx
	add	si, ax
	pop	ax		; get actual bytes written into cx	
	mov	cx, [sizelo]
	clc
	sub	cx, ax
	jc	write1g
	mov	[sizelo], cx
	jmp	write1c

write1g:
	mov	[sizelo], cx
	cmp	[sizehi], 0
	jne	write1h
	pop	ds
	mov	ah, 3eh
	int	21h
	lea	dx, intern
	call	OutMsg
	lea	dx, sizeovr
	call	OutMsg
	jmp	wrok
	
write1h:
	dec	[sizehi]
	jmp	write1c
	
write1i:
	pop	ds
	mov	ah, 3eh
	int	21h
	jmp	wrok

write2:
	mov	dl, al		; save drive
	call	RemSpac
	or	bx, bx
	jz	wrerr		; parameter error
	push	si
	push	di
	xor	si, si
	call	GetAddr
	mov	bp, di		; save start sector
	mov	[valsi], si
	pop	di
	pop	si
	call	RemSpac
	or	bx, bx
	jz	write3		; use default of 1 sector
	call	GetHex
	or	bx, bx
	jz	write3		; use default of 1 sector
	mov	cx, ax		; save count
	jmp	write4

wrerr:
	mov	bh, 3
	jmp	wrexit

write3:
	mov	cx, 1

write4:

;	Load sectors in

	push	ds
	mov	al, dl		; get drive
	mov	bx, di		; get offset
	mov	ds, si		; get segment
	mov	dx, bp		; get start sector
	mov	si, cs:[valsi]	; hard drive support
	or	si, si
	jz	writedo
	mov	di, -4		; hard volume support

writedo:
	int	26h
	jnc	writeok
	push	cs
	pop	ds
	lea	dx, badwrit
	call	OutMsg

writeok:
	popf
	pop	ds
	jmp	short wrok

wfilerr:
	pop	ds
	call	ErrMsg		; display error message
	mov	ah, 3eh		; close handle
	int	21h

wrok:
	xor	bh, bh

wrexit:
	pop	es
	pop	di
	pop	si
	pop	bp
	pop	dx
	pop	cx
	pop	ax
	ret
write	endp

	page
;-------------------------------------------------------------------------;
;	Function: asmun							  ;
;		  assembles intel assembly languages instructions in	  ;
;		  memory (1 line) and then unassembles it.		  ;
;	Input:								  ;
;	Output:								  ;
;		  None - displays information to screen			  ;
;-------------------------------------------------------------------------;

asmun	proc	near
	push	ax
	push	si
	push	di
	push	bp
	push	ds
	push	es


	mov	di, [asmloc+2]
	mov	si, [asmloc]
	mov	bx, 1
	call	GetAddr
	mov	es, si
	xchg	si, di

asmun1:
	mov	bp, si		; save offset for unasmbly
	call	GetOp
	or	bh, bh
	jz	asmun2
	call	SynErr		; display syntax error message
	jmp	short asmun1

asmun2:
	or	bl, bl
	jnz	asmun3
	push	ds
	push	es
	pop	ds
	push	bx
	mov	bx, bp		; get offset
	call	DispOp		; display instruction generated
	pop	bx
	pop	ds
	assume	ds:moss
	jmp	short asmun1

asmun3:
	mov	[asmloc+2], si
	mov	[asmloc], es
	xor	bx, bx

	pop	es
	pop	ds
	pop	bp
	pop	di
	pop	si
	pop	ax
	ret
asmun	endp

;-------------------------------------------------------------------------;
moss	ends
	end
