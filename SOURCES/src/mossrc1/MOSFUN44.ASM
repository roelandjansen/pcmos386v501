	include	page.inc
	title	MOSFUN44 - MOS function 44

	subttl	MOSFUN44 Development Specification
	.sall
;-----------------------------------------------------------------------;
;									;
;		      Development Specification 			;
;									;
;									;
; Program Name: $$MOS.COM		 Assigned to: Jim Bean		;
; Module Name:	MOSFUN44		 Assign date: 05/02/88		;
; Entry Points: MOSFUN44		 Completed: 05/02/88		;
; Entry From:	MOSINT21, MOSFUN0F					;
; Entry Method: CALL							;
; Calls:	MOSFUTIL, MOSLIMAN, gettime, caps			;
; Purpose:	File handle functions					;
; Last Update:	04/20/90						;
;									;
; This module handles function call 44					;
;									;
;-----------------------------------------------------------------------;
; jrb 05/02/88  correct ioctl fn 0e and 0f (get/set logical drive)	;
;		change get current dir to do a media check (which also	;
;		returns cdb ptr) because dos does and it's needed on	;
;		floppies						;
;		split mosfun44 into new mosfun44.asm cause mosfun39	;
;		ran out of room						;
;-----------------------------------------------------------------------;
; sjc 07/06/88	correct ioctl fn 0b to use the right reg (dx, not bx). 	;
;-----------------------------------------------------------------------;
; jrb 12/03/88  generic ioctl wasn't looking to see if it was supported ;
;               by the device driver before calling the device driver   ;
;               lanlink and ramdisk (in particular) went off into       ;
;               space                                                   ;
;-----------------------------------------------------------------------;
; SAH 01/26/89	Change LOCK equate to NLOCK (MASM 5.10 Compatibility)	;
;-----------------------------------------------------------------------;
; SAH 03/23/89	Notice that DOS places return value in AX for function	;
;		4400h.							;
;-----------------------------------------------------------------------;
; SAH 07/26/89	Corrections for function 4400 via MJS			;
;-----------------------------------------------------------------------;
; SAH 12/14/89  Remove mosregs2.inc					;
;-----------------------------------------------------------------------;
; SAH 04/20/90  Corrections for 4409 and 440a for proper report device  ;
;		is local or remote.					;
;-----------------------------------------------------------------------;

 	include GROUP.INC

	subttl	group segments and include block definitions
	page
.xlist

;-----------------------------------------------------------------------;
; access to partition saved registers					;
;-----------------------------------------------------------------------;

	include MOSREGS.INC

tcb	segment at 1234h
	include MOSTCB.INC	; TCB definition
tcb	ends

	include MOSCDB.INC	; etc., etc., etc.
	include MOSGFB.INC
	include MOSTFB.INC
	include MOSRLB.INC
	include MOSBDB.INC

	include	MACROS.INC

;-----------------------------------------------------------------------;
; the MOSSCBX include file is a file with extrn statements specified	;
; for all the items defined in the SCB					;
;-----------------------------------------------------------------------;

gdata	segment word public 'data'
	include MOSSCBEX.INC	; specify all SCB items as external
gdata	ends

.list

irq	segment byte public 'data'
irq	ends

poll	segment byte public 'data'
poll	ends
	subttl	mos segment - local code and data

mosseg	segment word public 'code1'
mosseg	ends

	page
ddt	segment word public 'code2'
	assume	cs:mo2,ds:grp,es:nothing,ss:tcb

	extrn	mosend:byte, sbios2:word
	extrn	mosliman:near, caps:near
	extrn	gettime:near, execopen:near
	extrn	mo1seg:word			;rs1

	; extrn's from MOSFUTIL.ASM
	extrn	alloclust:near, blkread:near, blkwrite:near
	extrn	chklock:near, closefile:near, clrclust:near, create:near
	extrn	dealloc:near, delete:near, devchk:near, todriver:near
	extrn	emptydir:near, findbdb:near, findgfb:near, findlbl:near
	extrn	findnm:near, findrlb:near, findtfb:near, flushdir:near
	extrn	getfat:near, getphdl:near, makelbl:near
	extrn	moserror:near, nextnm:near, openfile:near
	extrn	pathfind:near, putfat:near, rddir:near, slash:near
	extrn	timestamp:near, wrsector:near, setphdl:near, iolock:near
	extrn	devread:near, devwrite:near, finddrv:near, exclude:near
	extrn	okchar:near, encrypt:near, decrypt:near, classlvl:near
	extrn	cpycmap:near, eblcmap:near, capscmps:near

	; extrn's from MOSMIMAN.ASM
	extrn	readguts:near, writeguts:near, truncguts:near
	extrn	creatguts:near, checkexon:near
	extrn	buffinp:near, cdevinp:near

	; extrn's from MOSFUN39.ASM
	extrn	noswt:near
	extrn	okswt:near
	extrn	sttax0:near

	public	mosfun44


if 0 eq 0		; trick PUBLIC.COM

;-----------------------------------------------------------------------;
; error codes defined							;
;-----------------------------------------------------------------------;

INVFN	EQU	1		; invalid function (or sub-function)
FILENF	EQU	2		; file not found (or invalid name)
PATHNF	EQU	3		; path not found (or invalid path)
MANYFIL EQU	4		; too many files open
ACCDENY EQU	5		; access denied
INVHDL	EQU	6		; invalid handle (file not open)
INVACC	EQU	12		; invalid access code specified
DRIVENF EQU	15		; drive not found (or invalid drive)
DELCURD EQU	16		; attempt to delete current directory
DIFFDEV EQU	17		; not the same device
NOMORE	EQU	18		; no more files found
SHARE	EQU	32		; sharing violation
NLOCK	EQU	33		; lock violation
SHAREOV EQU	36		; share buffer overflow (couldn't alloc RLB)
FILEXST EQU	80		; file already exists
FAIL24H EQU	83		; fail chosen from INT 24H (as defined by DOS)
SYSHDL	EQU	127 OR 8000H	; attempt to DUP or FDUP a non-psp handle
XSHARE	EQU	SHARE OR 8000H	; fail from INT 24H sharing
XLOCK	EQU	NLOCK OR 8000H	; fail from INT 24H locking
ERR24H	EQU	FAIL24H OR 8000H; fail error from INT 24H (signal for MOSERROR)
INTERN	EQU	80FFH		; internal error

;-----------------------------------------------------------------------;
; directory entry fields						;
;-----------------------------------------------------------------------;

DATR	EQU	11		; offset of attribute byte
DCLASS0 EQU	13		; offset of class byte
DTIME	EQU	22		; offset of time word
DDATE	EQU	24		; offset of date word
DSIZE	EQU	28		; offset of size dword
DCLUST	EQU	26		; offset of bof cluster word

;-----------------------------------------------------------------------;
; directory entry file attribute bits defined				;
;-----------------------------------------------------------------------;

OVERRIDE EQU	80H		; dir search class level override
ARCH	EQU	20H		; archive
DIR	EQU	10H		; directory
LBL	EQU	08H		; label
SYS	EQU	04H		; system
HID	EQU	02H		; hidden
RO	EQU	01H		; read-only

;-----------------------------------------------------------------------;
; critical error coding 						;
;-----------------------------------------------------------------------;

RDX	EQU	00H		; read operation
WRX	EQU	01H		; write operation

FAILX	EQU	08H		; fail not allowed
RETRYX	EQU	10H		; retry not allowed
IGNOREX EQU	20H		; ignore not allowed
ALLX	EQU	FAILX OR RETRYX OR IGNOREX
SYSX	EQU	FAILX OR RETRYX ; ignore not allowed in system areas

DOSX	EQU	00H OR ALLX	; dos area of disk?
FATX	EQU	02H OR SYSX	; fat area
DIRX	EQU	04H OR SYSX	; dir area
DATAX	EQU	06H OR ALLX	; data area

endif

	assume	cs:mo2,ds:nothing,es:nothing,ss:nothing


	subttl	mosfun44 - I/O control for devices (IOCTL)
	page
;-----------------------------------------------------------------------;
;									;
; MOS function 44H - I/O control for devices (IOCTL)			;
;									;
; entry:								;
;   see sub-functions							;
;									;
; returns:								;
;   CARRY bit of TFLAG set if error					;
;     TAX = error code							;
;	INVFN  - invalid function number				;
;	sub-function-specific errors below				;
;   CARRY bit of TFLAG clear if no error				;
;     see sub-functions for other returned values			;
;									;
;-----------------------------------------------------------------------;

; vectors for IOCTL subfunctions

ioctl	dw	mo2:ioctl00, mo2:ioctl01, mo2:ioctl02, mo2:ioctl03
	dw	mo2:ioctl04, mo2:ioctl05, mo2:ioctl06, mo2:ioctl07
	dw	mo2:ioctl08, mo2:ioctl09, mo2:ioctl0a, mo2:ioctl0b
	dw	mo2:ioctl0c, mo2:ioctl0d, mo2:ioctl0e, mo2:ioctl0f
endioct equ	this byte

	assume	ds:grp,es:nothing,ss:tcb
lproc	mosfun44

	mov	si,bp
	mov	bp,[bp]
	mov	al,[TAL]
	mov	bx,[TBX]
	mov	cx,[TCX]
	mov	dx,[TDX]
	mov	di,[TDS]
	mov	bp,si
	call	noswt
	xor	ah,ah
	mov	si,ax
	mov	ax,INVFN
	cmp	si,(endioct-ioctl)/2
	jae	mosf44x 	; invalid sub-function if greater than 0BH
	add	si,si
	call	ioctl[si]

	assume	ds:nothing,es:nothing,ss:tcb
mosf44x:
	call	okswt		; safe to allow a task switch
	mov	bx,bp
	mov	bp,[bp] 	; address task registers to report TAX error
	and     [TFLAG],not CARRY
	or      ax,ax		; SAH
	jz	mosf44sk	; SAH 08/25/87 if clear means no error	
	mov	cx,ax
	and	cx,not 8000h
	call	moserror
mosf44sk:			; SAH 08/25/87
	mov	bp,bx

lendp	mosfun44

	subttl	mosfun44 - ioctl00 - get device information
	page
;-----------------------------------------------------------------------;
;									;
; IOCTL function 00h - return device information			;
;									;
; entry:								;
;   bx = file handle							;
;									;
; returns:								;
;   CARRY bit of TFLAG set if error					;
;     TAX = error code							;
;	INVHDL - invalid handle 					;
;   CARRY bit of TFLAG clear if no error				;
;     TDX = device data 						;
;									;
;-----------------------------------------------------------------------;
	assume	ds:grp,es:nothing,ss:tcb
ioctl00:
	call	findtfb

	assume	es:tfb

	mov	ax,INVHDL
	jc	ioctl00x
	mov	ds,[tfbgfb]

	assume	ds:gfb
	xor	dh,dh
	cmp	[gfbdev],0	; is this a character device
	je	ioctl00a	; then set dh == hi-order byte of driver
	lds	si,[gfbdrvr]	; attribute word, esle set to 0
	assume	ds:nothing
	mov	dh,[si+5]	; hi-order byte of driver attribute word
ioctl00a:
	mov	dl,[tfbioctl]

	mov	bx,bp
	mov	bp,[bp]
	mov	[TDX],dx
	mov	[TAX],dx	; SAH dos appears to put it in AX too
	mov	bp,bx
	xor	ax,ax
ioctl00x:
	ret

	subttl	mosfun44 - ioctl01 - set device information
	page

;-----------------------------------------------------------------------;
;									;
; IOCTL function 01h - set device information				;
;									;
; entry:								;
;   bx = file handle							;
;   dx = device information to set					;
;									;
; returns:								;
;   CARRY bit of TFLAG set if error					;
;     TAX = error code							;
;	INVHDL - invalid handle 					;
;	INVFN  - device information invalid				;
;   CARRY bit of TFLAG clear if no error				;
;									;
;-----------------------------------------------------------------------;

	assume	ds:grp,es:nothing,ss:tcb

ioctl01:
	call	findtfb

	assume	es:tfb

	mov	ax,INVHDL
	jc	ioctl01x
	mov	ds,[tfbgfb]

	assume	ds:gfb

	mov	ax,INVFN
	test	[tfbioctl],80h
	jz	ioctl01x	; invalid function for block device
	or	dh,dh
	jnz	ioctl01x	; "DH must be zero for call AL=01H"
	or	dl,80h		; can't change the ISDEV bit
	mov	[tfbioctl],dl
	xor	ax,ax
ioctl01x:
	ret

	subttl	mosfun44 - ioctl02 - read from device control channel
	page

;-----------------------------------------------------------------------;
;									;
; IOCTL function 02h - read from device control channel 		;
;									;
; entry:								;
;   bx = file handle							;
;   cx = number of bytes to read					;
;   di:dx -> buffer							;
;									;
; returns:								;
;   CARRY bit of TFLAG set if error					;
;     TAX = error code							;
;	INVHDL - invalid handle 					;
;	INVFN  - device doesn't support IOCTL                           ;
;   CARRY bit of TFLAG clear if no error				;
;     TAX = number of bytes read					;
;									;
;-----------------------------------------------------------------------;

	assume	ds:nothing,es:nothing,ss:tcb

lproc	ioctl02

lstring request,26

	mov	word ptr [request+14],dx ; transfer buffer offset
	mov	word ptr [request+16],di ; transfer buffer segment
	mov	word ptr [request+18],cx ; transfer buffer length
	push	ss
	pop	es
	lea	di,[request]
	xor	ax,ax
	mov	cx,14/2
	rep stosw
	add	di,20-14
	stosw
	stosw
	stosw
	call	findtfb

	assume	es:tfb

	mov	ax,INVHDL
	jc	ioctl02x
	mov	es,[tfbgfb]

	assume	es:gfb

	mov	ax,INVFN
	cmp	[gfbdev],0
	je	ioctl02x	; e if not a character device
	lds	si,[gfbdrvr]
	test	byte ptr [si+5],40h
	jz	ioctl02x	; ioctl not allowed if z
	mov	[request+2],3	; command is ioctl write
	mov	[request],22	; length of request block
	test	byte ptr [si+5],08h
	jz	ioctl02a
	mov	[request],26	; length of request block
ioctl02a:
	push	ss
	pop	es
	lea	bx,[request]
	xor	cx,cx		; no retries
	xor	al,al		; no drive
	mov	ah,80h or DOSX
	call	todriver
	mov	cx,word ptr [request+18]
	call	sttax
ioctl02x:

lundef	request,26

lendp	ioctl02

	subttl	mosfun44 - ioctl03 - write to device control channel
	page

;-----------------------------------------------------------------------;
;									;
; IOCTL function 03h - write to device control channel			;
;									;
; entry:								;
;   bx = file handle							;
;   cx = number of bytes to write					;
;   di:dx -> data to write						;
;									;
; returns:								;
;   CARRY bit of TFLAG set if error					;
;     TAX = error code							;
;	INVHDL - invalid handle 					;
;	INVFN  - device doesn't support IOCTL                           ;
;   CARRY bit of TFLAG clear if no error				;
;     TAX = number of bytes written					;
;									;
;-----------------------------------------------------------------------;

	assume	ds:nothing,es:nothing,ss:tcb

lproc	ioctl03

lstring request,26

	mov	word ptr [request+14],dx ; transfer buffer offset
	mov	word ptr [request+16],di ; transfer buffer segment
	mov	word ptr [request+18],cx ; transfer buffer length
	push	ss
	pop	es
	lea	di,[request]
	xor	ax,ax
	mov	cx,14/2
	rep stosw
	add	di,20-14
	stosw
	stosw
	stosw
	call	findtfb

	assume	es:tfb

	mov	ax,INVHDL
	jc	ioctl03x
	mov	es,[tfbgfb]

	assume	es:gfb

	mov	ax,INVFN
	cmp	[gfbdev],0
	je	ioctl03x	; e if not a character device
	lds	si,[gfbdrvr]
	test	byte ptr [si+5],40h
	jz	ioctl03x	; ioctl not allowed if z
	mov	[request+2],12	; command is ioctl write
	mov	[request],22	; length of request block
	test	byte ptr [si+5],08h
	jz	ioctl03a
	mov	[request],26	; length of request block
ioctl03a:
	push	ss
	pop	es
	lea	bx,[request]
	xor	cx,cx		; no retries
	xor	al,al		; no drive
	mov	ah,80h or DOSX or WRX
	call	todriver
	mov	cx,word ptr [request+18]
	call	sttax		; bytes actually written
ioctl03x:

lundef	request,26

lendp	ioctl03

	subttl	mosfun44 - ioctl04 - read from block device control channel
	page

;-----------------------------------------------------------------------;
;									;
; IOCTL function 04h - read from block device control channel		;
;									;
; entry:								;
;   bl = block device drive (0=default) 				;
;   cx = number of bytes to read					;
;   di:dx -> buffer							;
;									;
; returns:								;
;   CARRY bit of TFLAG set if error					;
;     TAX = error code							;
;	DRIVENF - invalid drive 					;
;	INVFN	- device doesn't support IOCTL                          ;
;   CARRY bit of TFLAG clear if no error				;
;     TAX = number of bytes read					;
;									;
;-----------------------------------------------------------------------;

	assume	ds:nothing,es:nothing,ss:tcb

lproc	ioctl04

lstring request,26

	mov	word ptr [request+14],dx ; transfer buffer offset
	mov	word ptr [request+16],di ; transfer buffer segment
	mov	word ptr [request+18],cx ; transfer buffer length
	push	ss
	pop	es
	lea	di,[request+3]
	xor	ax,ax
	mov	cx,(13-3)/2
	rep stosw
	add	di,20-13
	stosw
	stosw
	stosw
	mov	al,bl
	dec	al
	jns	ioctl04a
	mov	al,[tcbcdriv]
ioctl04a:
	call	findbdb

	assume	ds:bdb

	jc	ioctl04x
	push	ds
	pop	es
	assume	es:bdb

	lds	si,[bdbdrvr]
	assume	ds:nothing

	mov	ax,INVFN
	test	byte ptr [si+5],40h
	jz	ioctl04x	; ioctl not allowed if z
	mov	al,[bdbmdia]
	mov	[request+13],al
	mov	al,[bdbunit]	; unit within block device driver
	mov	[request+1],al
	mov	[request+2],3	; command is ioctl write
	mov	[request],22
	test	byte ptr [si+5],08h
	jz	ioctl04b
	mov	[request],26
ioctl04b:
	xor	cx,cx		; no retries
	mov	al,[bdbid]
	push	ss
	pop	es
	assume	es:nothing

	lea	bx,[request]
	mov	ah,DOSX or RDX
	call	todriver
	mov	cx,word ptr [request+18]
	call	sttax
ioctl04x:

lundef	request,26

lendp	ioctl04

	subttl	mosfun44 - ioctl05 - write to block device control channel
	page

;-----------------------------------------------------------------------;
;									;
; IOCTL function 05h - write to block device control channel		;
;									;
; entry:								;
;   bl = block device drive (0=default) 				;
;   cx = number of bytes to write					;
;   di:dx -> data to write						;
;									;
; returns:								;
;   CARRY bit of TFLAG set if error					;
;     TAX = error code							;
;	DRIVENF - invalid drive 					;
;	INVFN	- device doesn't support IOCTL                          ;
;   CARRY bit of TFLAG clear if no error				;
;     TAX = number of bytes written					;
;									;
;-----------------------------------------------------------------------;

	assume	ds:nothing,es:nothing,ss:tcb

lproc	ioctl05

lstring request,26

	mov	word ptr [request+14],dx ; transfer buffer offset
	mov	word ptr [request+16],di ; transfer buffer segment
	mov	word ptr [request+18],cx ; transfer buffer length
	push	ss
	pop	es
	lea	di,[request+3]
	xor	ax,ax
	mov	cx,(13-3)/2
	rep stosw
	add	di,20-13
	stosw
	stosw
	stosw
	mov	al,bl
	dec	al
	jns	ioctl05a
	mov	al,[tcbcdriv]
ioctl05a:
	call	findbdb

	assume	ds:bdb

	jc	ioctl05x
	push	ds
	pop	es
	assume	es:bdb

	lds	si,[bdbdrvr]
	assume	ds:nothing

	mov	ax,INVFN
	test	byte ptr [si+5],40h
	jz	ioctl05x	; ioctl not allowed if z
	mov	al,[bdbmdia]
	mov	[request+13],al
	mov	al,[bdbunit]	; unit within block device driver
	mov	[request+1],al
	mov	[request+2],12	; command is ioctl write
	mov	[request],22
	test	byte ptr [si+5],08h
	jz	ioctl05b
	mov	[request],26
ioctl05b:
	mov	al,[bdbid]
	push	ss
	pop	es
	assume	es:nothing

	lea	bx,[request]
	xor	cx,cx		; no retries
	mov	ah,DOSX or WRX
	call	todriver
	mov	cx,word ptr [request+18]
	call	sttax
ioctl05x:

lundef	request,26

lendp	ioctl05

	subttl	mosfun44 - ioctl06 - get input status
	page

;-----------------------------------------------------------------------;
;									;
; IOCTL function 06h - get input status 				;
;									;
; entry:								;
;   TBX = file or device handle 					;
;									;
; returns:								;
;   CARRY bit of TFLAG set if error					;
;     TAX = error code							;
;	INVHDL - invalid handle 					;
;   CARRY bit of TFLAG clear if no error				;
;     TAL = 0ffh if ready for read (chars are buffered or not at eof)	;
;     TAL = 00h if not ready (no chars ready or at eof if file) 	;
;									;
;-----------------------------------------------------------------------;
	assume	ds:grp,es:nothing,ss:tcb

ioctl06:
	call	findtfb

	assume	es:tfb

	mov	ax,INVHDL
	jc	ioctl06x
	mov	bx,word ptr [tfbpos]
	mov	dx,word ptr [tfbpos+2]
	mov	es,[tfbgfb]

	assume	es:gfb

	cmp	[gfbdev],0
	jne	ioctl06a
	mov	al,0ffh
	sub	bx,word ptr [gfbsize]
	sbb	dx,word ptr [gfbsize+2]
	jc	ioctl06b	; SAH input file ready if prior to eof
	inc	al		; else is not ready (al=0)
	jmp	ioctl06b	; SAH fixed bugs with Turbo-Pascal
ioctl06a:
	lds	si,[gfbdrvr]

	assume	ds:nothing

	mov	al,6
	mov	ah,80h		; character device
	xor	dx,dx
	call	devchk
	xor	al,al
	jc	ioctl06b
	test	ah,02h
	jnz	ioctl06b	; busy bit set if no chars ready
	dec	al
ioctl06b:
	call	sttal		; set TAL reg w/ al
ioctl06x:
	ret

	subttl	mosfun44 - ioctl07 - get output status
	page

;-----------------------------------------------------------------------;
;									;
; IOCTL function 07h - get output status				;
;									;
; entry:								;
;   TBX = file or device handle 					;
;									;
; returns:								;
;   CARRY bit of TFLAG set if error					;
;     TAX = error code							;
;	INVHDL - invalid handle 					;
;   CARRY bit of TFLAG clear if no error				;
;     TAL = 0ffh if ready for write (won't wait)                        ;
;     TAL = 00h if not ready						;
;									;
;-----------------------------------------------------------------------;
	assume	ds:grp,es:nothing,ss:tcb

ioctl07:
	call	findtfb

	assume	es:tfb

	mov	ax,INVHDL
	jc	ioctl07x
	mov	es,[tfbgfb]

	assume	es:gfb

	mov	al,0ffh
	cmp	[gfbdev],0
	je	ioctl07b	; output status of file is always ready
	lds	si,[gfbdrvr]

	assume	ds:nothing

	mov	al,10
	mov	ah,80h		; 80h for character device
	xor	dx,dx
	call	devchk
	xor	al,al
	jc	ioctl07b
	test	ah,02h
	jnz	ioctl07b	; busy bit set if write would wait
	dec	al
ioctl07b:
	call	sttal
ioctl07x:
	ret

	subttl	mosfun44 - ioctl08 - is a block device changeable?
	page

;-----------------------------------------------------------------------;
;									;
; IOCTL function 08h - is block device changeable			;
;									;
; entry:								;
;   TBL = drive of block device (0=default)				;
;									;
; returns:								;
;   CARRY bit of TFLAG set if error					;
;     TAX = error code							;
;	DRIVENF - invalid drive 					;
;   CARRY bit of TFLAG clear if no error				;
;     TAX = 1 if not changeable 					;
;     TAX = 0 if changeable						;
;									;
;-----------------------------------------------------------------------;
	assume	ds:grp,es:nothing,ss:tcb

ioctl08:
	mov	al,bl
	dec	al
	jns	ioctl08a
	mov	al,[tcbcdriv]
ioctl08a:
	call	findbdb

	assume	ds:bdb

	mov	ax,INVFN	; SAH 08/25/87 this is where it should be done
	jc	ioctl08x
	mov	dl,[bdbunit]	; dl = unit within block device driver
	mov	dh,[bdbid]	; dh = drive number
	lds	si,[bdbdrvr]

	assume	ds:nothing

	mov	ax,1		; indicated device is not changeable
	test	word ptr [si+4],0800h
	jz	ioctl08b	; device doesn't support this call
	mov	al,15
	mov	ah,00h		; bit 7 clear for block device
	call	devchk
	test	ah,02h
	mov     ax,0
	jz	ioctl08b
	inc	ax
ioctl08b:
	call	sttax0
ioctl08x:
	ret

	subttl	mosfun44 - ioctl09 - is a block device local or remote
	page

;-----------------------------------------------------------------------;
;									;
; IOCTL function 09h - is block device local or remote			;
;									;
; entry:								;
;   TBL = drive of block device (0=default)				;
;									;
; returns:								;
;   CARRY bit of TFLAG set if error					;
;     TAX = error code							;
;	DRIVENF - invalid drive 					;
;   CARRY bit of TFLAG clear if no error				;
;     TDX = device attribute (bit 12 on implies remote) 		;
;									;
;-----------------------------------------------------------------------;
	assume	ds:grp,es:nothing,ss:tcb

ioctl09:
	mov	al,bl
	dec	al
	jns	ioctl09a
	mov	al,[tcbcdriv]
ioctl09a:
	call	findbdb

	assume	ds:bdb

	jc	ioctl09x
	les	bx,[bdbdrvr]

	assume	es:nothing

	mov	ax,es:[bx+4]
	and	ah,7fh
	test	ah,10h
	jz	ioctl09b
	or	ah,80h
ioctl09b:
	call	sttdx
ioctl09x:
	ret

	subttl	mosfun44 - ioctl0a - is a handle local or remote
	page

;-----------------------------------------------------------------------;
;									;
; IOCTL function 0ah - is file or device handle local or remote 	;
;									;
; entry:								;
;   TBX = handle							;
;									;
; returns:								;
;   CARRY bit of TFLAG set if error					;
;     TAX = error code							;
;	INVHDL - invalid handle 					;
;   CARRY bit of TFLAG clear if no error				;
;     TDX = device attribute (bit 12 on implies remote) 		;
;									;
;-----------------------------------------------------------------------;
	assume	ds:grp,es:nothing,ss:tcb

ioctl0a:
	call	findtfb

	assume	es:tfb

	mov	ax,INVHDL
	jc	ioctl0ax
	mov	es,[tfbgfb]

	assume	es:gfb

	les	bx,[gfbdrvr]

	assume	es:nothing

	mov	ax,es:[bx+4]
	and	ah,7fh
	test	ah,10h
	jz	ioctl0ab
	or	ah,80h
ioctl0ab:
	call	sttdx
ioctl0ax:
	ret

	subttl	mosfun44 - ioctl0b - set sharing retry count
	page

;-----------------------------------------------------------------------;
;									;
; IOCTL function 0bh - set sharing retry count				;
;									;
; entry:								;
;   TDX = number of retries						;
;   TCX = time to wait between retries					;
;									;
; returns:								;
;   CARRY bit of TFLAG clear						;
;									;
;-----------------------------------------------------------------------;
	assume	ds:grp,es:nothing,ss:tcb

ioctl0b:
;;SJC	mov	[tcbntry],bx	; number of retries for share violations
	mov	[tcbntry],dx	;;SJC - use dx, not bx!
	mov	[tcbttry],cx	; interval between retries for share violations
	xor	ax,ax
	ret

	subttl	mosfun44 - ioctl0c - undocumented
	page

;-----------------------------------------------------------------------;
;									;
; IOCTL function 0ch - undocumented					;
;									;
; entry:								;
;									;
; returns:								;
;   AX = INVFN								;
;									;
;-----------------------------------------------------------------------;
	assume	ds:grp,es:nothing,ss:tcb

ioctl0c:
	mov	ax,INVFN
	ret

	subttl	mosfun44 - ioctl0d - set sharing retry count
	page

;-----------------------------------------------------------------------;
;									;
; IOCTL function 0dh - 3.20 Generic IOCTL				;
;									;
; entry:								;
;   TCX (cx) = function major and minor codes				;
;   TBL (bl) = drive number (0 default) 				;
;   TDS:TDX (di:dx) -> parameter block					;
;									;
; returns:								;
;   AX = error code from device driver if error, else 0 		;
;									;
;-----------------------------------------------------------------------;
	assume	ds:grp,es:nothing,ss:tcb

lproc	ioctl0d

lstring request,23

	xchg	ch,cl
	mov	word ptr [request+13],cx
	mov	word ptr [request+15],si
	mov	cx,bp
	mov	bp,[bp]
	mov	ax,[TDI]
	mov	bp,cx
	mov	word ptr [request+17],ax
	mov	word ptr [request+19],dx
	mov	word ptr [request+21],di
	mov	al,bl
	dec	al
	jns	ioctl0da
	mov	al,[tcbcdriv]
ioctl0da:
	call	findbdb

	assume	ds:bdb

	jc	ioctl0dx
	mov	al,[bdbunit]
	mov	[request+1],al
	mov	[request],23
	mov	[request+2],19
	lds	si,[bdbdrvr]

	assume	ds:nothing

        mov     ax,INVFN
        test    byte ptr [si+4],40h
        jz      ioctl0dx

	lea	di,[request+3]
	mov	cx,(13-3)/2
	push	ss
	pop	es
	assume	es:nothing

	xor	ax,ax
	rep stosw
	lea	bx,[request]
	xor	cx,cx		; no retries, no int 24h
	call	todriver
	mov	ax,word ptr [request+3]
	and	al,7fh
	test	ah,80h
	jnz	ioctl0db
	xor	ax,ax
	jmp	ioctl0dx
ioctl0db:
	xor	ah,ah
	add	ax,19
ioctl0dx:

lundef	request,23

lendp	ioctl0d

	subttl	mosfun44 - ioctl0e - get logical device
	page

;-----------------------------------------------------------------------;
;									;
; IOCTL function 0eh - get logical device				;
;									;
; entry:								;
;   TBL (bl) = drive number (0 default) 				;
; returns:								;
;   AX = error code from device driver, else 0 and TAL = assigned	;
;-----------------------------------------------------------------------;
	assume	ds:grp,es:nothing,ss:tcb

ioctl0e:
	mov	al,bl
	dec	al
	jns	ioctl0ea
	mov	al,[tcbcdriv]
ioctl0ea:
	call	findbdb

	assume	ds:bdb

	jc	ioctl0ex
;jrbr	mov	dl,[bdbid]	; (note - this isn't documented as sub-unit,
        mov     dl,[bdbunit]    ;jrbr yes it is
	lds	si,[bdbdrvr]	;   so it isn't passed as subunit)

	assume	ds:nothing

	mov	ax,INVFN
;jrbr	test	word ptr [si+4],0800h
        test    byte ptr [si+4],40h     ;jrbr
	jz	ioctl0ex	; device doesn't support this call
	xor	ax,ax		; block device
	mov	al,23
	call	devchk
	jnc	ioctl0eb
	and	ax,7fh
	add	ax,19
	jmp	ioctl0ex
ioctl0eb:
	call	sttal0
ioctl0ex:
	ret

	subttl	mosfun44 - ioctl0f - set logical device
	page

;-----------------------------------------------------------------------;
;									;
; IOCTL function 0fh - set logical device				;
;									;
; entry:								;
;   TBL (bl) = drive number (0 default) 				;
; returns:								;
;   AX = error code from device driver, else 0 and TAL = assigned	;
;-----------------------------------------------------------------------;
	assume	ds:grp,es:nothing,ss:tcb

ioctl0f:
	mov	al,bl
	dec	al
	jns	ioctl0fa
	mov	al,[tcbcdriv]
ioctl0fa:
	call	findbdb

	assume	ds:bdb

	jc	ioctl0fx
;jrbr	mov	dl,[bdbid]	; (note - this isn't documented as sub-unit,
        mov     dl,[bdbunit]    ;jrbr yes it is
	lds	si,[bdbdrvr]	;   so it isn't passed as subunit)

	assume	ds:nothing

	mov	ax,INVFN
;jrbr	test	word ptr [si+4],0800h
        test    byte ptr [si+4],40h     ;jrbr
	jz	ioctl0fx	; device doesn't support this call
	xor	ax,ax		; block device
	mov	al,24
	call	devchk
	jnc	ioctl0fb
	and	ax,7fh
	add	ax,19
	jmp	ioctl0fx
ioctl0fb:
	call	sttal0
ioctl0fx:
	ret


;
; Set TAX reg with processor cx reg
; SAH 12/07/87 This will only work with nested (1 level) lprocs
;
sttax	proc	near
	mov	bx,bp
	mov	bp,[bp]
	mov	bp,[bp]		; SAH Remember that Function 44x calls are
				; SAH nested lproc's
	mov	[TAX],cx	
	mov	bp,bx
	xor	ax,ax
	ret
sttax	endp

;
; Set TAL reg from AL
;
sttal	proc	near
	mov	bx,bp
	mov	bp,[bp]
	mov	[TAL],al
	mov	bp,bx
	xor	ax,ax
	ret
sttal	endp

;
; Set TDX reg with processor ax reg
;
sttdx	proc	near
	mov	bx,bp
	mov	bp,[bp]
	mov	[TDX],ax
	mov	bp,bx
	xor	ax,ax
	ret
sttdx	endp

sttal0	proc	near
	mov	ax,bp
	mov	bp,[bp]
	mov	[TAL],dl	; returned drive parameter
	mov	bp,ax
	xor	ax,ax
	ret
sttal0	endp

ddt	ends
	end

