	include page.inc
	title class - mos security class changes
comment ^===============================================================
		    development specification

 program name:	class.com		assigned to: sah
 module name:	class.asm		assign date: 12/10/86
 entry points:	exec			completed:   12/22/86
 entry from:	exec
 entry method:	exec
 calls: 	n/a
 purpose:	change directory class, task class or default output class
 last update:	08/10/1992

=======================================================================

sah 07/12/87	converted 80+ to int 38h 00+ calls

rbr 08/24/87	spelling error correction.

sah 02/20/89	converted int 38 to int services

sah 03/21/89	remove 386 reference

bwr 11/17/89	messages marked for foreign language translation.

sah 05/01/90	only allowed to change class to class which user
		has access to.

sah 04/20/92	up version to 5.01, copyright notice

================ 5.01 kernel ends here ====================================

sah 07/01/92	corrections for displaying #

mjs 08/10/92	insure that when a directory is first secured
		that its system bit is set.  also, when a secured
		directory is changed to have space class, must
		clear the system bit.
		version #5.03

======================================================================^

	subttl	group segments for code, data and extra segments
	page

tcb	segment at 7777h
	include mostcb.inc
tcb	ends

scbs	segment at 08888h
	assume	cs:scbs
	include mosscbdf.inc
	assume	cs:nothing
scbs	ends

moss	segment word public 'code'
	assume cs:moss,ds:moss,es:moss,ss:moss

	include options.inc
	include class.pub

	org	100h

start	label	near
	jmp	begin
	db	8,8,8,'   '

tsl	db	13,10,'PC-MOS CLASS v5.03',13,10
	db	'(c) Copyright 1987 - 1992 The Software Link, Incorporated'  ;@@xlat
	db	13,10
	db	'All rights reserved worldwide ',13,10,'$'  ;@@xlat
	db	8,' ',26

	even
version label	near
	include version.inc

badmos	db	13,10, 'Incorrect MOS Version. ',13,10,'$'  ;@@xlat

syntax	db	13,10
	db	'Usage:    ',13,10	;@@xlat
	db	'  CLASS           - display command form       ',13,10  ;@@xlat
	db	'  CLASS   Dir  C  - change Directory to class C        ',13,10  ;@@xlat
	db	'  CLASS   PD      - changes Partition (P) and                  ',13,10  ;@@xlat
	db	'                    User Default (D) Class(es)        ',13,10,'$'  ;@@xlat

status	db	'CLASS Changing Directory $    '  ;@@xlat
stmsg	db	'  to Class  '		;@@xlat
clmsg	db	'A.',13,10,'$'
errmsg	db	13,10
	db	'CLASS Error:  $   '	;@@xlat
errend	db	'.',13,10,'$'
clsspec db	'Invalid Class Specification$      '  ;@@xlat
erpath	db	'Invalid Directory Path$       '  ;@@xlat
eracc	db	'Access not allowed$          '  ;@@xlat
erdir	db	'Error changing directory$                 '  ;@@xlat

utmsg	db	'Partition Class      = $          '  ;@@xlat
dfmsg	db	'Default Output Class = $           '  ;@@xlat

len1	db	0			; parm 1 lenght and storage
parm1	db	63 dup (' ')
len2	db	0			; parm 2 lenght and storage
parm2	db	2 dup (' ')

buff83	label	byte
	db	(?)			; reserved
clsin	db	'C'			; class
userin	db	'USER'			; user @@xlat
	db	4 dup (?)		; time & date

savecls db	0			; save class
saveacc db	255			; save access for class
class	db	0			; output class
cntrlc	db	0			; control - c checking save state
path	db	63 dup (0),'$'		; scan path

	even
pathlen dw     0			; len off scan path
tcbseg	dw     0			; tcb segment..

	subttl upper -- convert al to uppercase
	page
;======================================================================
;,fs
; upper -- convert al to uppercase
;
; in:	al = character
;
; out:	al = upper case character (0 if not character)
; 
;,fe
;================================================================
	assume	ds:nothing,es:nothing,ss:nothing
upper proc near
	cmp	al,'_'
	jne	ucont
	mov	al,' '
	ret
ucont:
	cmp	al,'A'
	jb	uerror
	cmp	al,'Z'
	jbe	udone
	cmp	al,'a'
	jb	uerror
	cmp	al,'z'
	ja	uerror
	sub	al,'a'
	add	al,'A' 		; force upper case
udone:
	ret
uerror:
	cmp	al,'0'
	jb	uerror2
	cmp	al,'9'
	jbe	udone
uerror2:
	xor	al,al
	ret
upper endp

	subttl skipspc -- parameter parsing
	page
;======================================================================
;,fs
; skipspc -- parameter parsing
;
; in:	si = command position
;	bl = character count
;
; out:	si = new command position
;	bl = new character count
; 
;,fe
;================================================================
	assume	ds:nothing,es:nothing,ss:nothing
skipspc proc near
	push	ax
ss1:
	lodsb
	cmp	al,' ' 			; space??
	jne	ss2
	dec	bl			; decrement counter
	or	bl,bl			; done
	jnz	ss1			; no??
	jmp	short ss3
ss2:
	dec	si			; decremnt command position
ss3:
	pop	ax
	ret
skipspc endp

	subttl cpyparm -- parameter parsing
	page
;======================================================================
;,fs
; cpyparm -- parameter parsing
;
; in:	si = command position
;	bl = character count
;
; out:	si = new command position
;	di = destination
;	bl = new character count
;	cx = count
; 
;,fe
;================================================================
	assume	ds:nothing,es:nothing,ss:nothing
cpyparm proc near
	push	ax
	xor	cx,cx
cp1:
	lodsb
	cmp	al,' ' 			; space??
	je	cp2
	or	al,al
	je	cp2
	stosb				; store byte
	inc	cx			; increment buff counter
	dec	bl			; decrement counter
	or	bl,bl			; done
	jnz	cp1			; no??
	jmp	short cp3
cp2:
	dec	si			; decremnt command position
cp3:
	pop	ax
	ret
cpyparm endp

	subttl error -- display error message
	page
;======================================================================
;,fs
; error -- display error message
;
; in:	dx = offset of error message
;
; out:	dx = destroyed
; 
;,fe
;================================================================
	assume	ds:nothing,es:nothing,ss:nothing
error proc near
	push	ax
	push	dx
	lea	dx,errmsg
	mov	ah,9
	int	21h
	pop	dx
	int	21h
	lea	dx,errend
	int	21h
	pop	ax
	ret
error endp

	subttl chkclass -- check the class
	page
;======================================================================
;,fs
; chkclass -- check the class
;
; in:	al = class to check
;
; out:	cy if class is not valid
; 
;,fe
;================================================================
	assume	ds:nothing,es:nothing,ss:nothing
chkclass proc near
	push	ax
	push	bx
	push	cx
	push	dx
	mov	cl,al
	mov	bx,-1
	mov	ah,2fh			; check security class
	int	services
	jnc	ccok
	cmp	ax,1			; invalid function
	je	ccok
	lea	dx,eracc
	call	error
	stc
	jmp	short ccdone
ccok:
	clc				; all ok
ccdone:
	pop	dx
	pop	cx
	pop	bx
	pop	ax
	ret
chkclass endp


;======================================================

	assume cs:moss,ds:moss,es:moss,ss:moss
begin:

; routine to check mos version

	mov	ah,30h
	mov	bx,ax
	mov	cx,ax
	mov	dx,ax
	int	21h
	cmp	ax,word ptr [version]
	je	mosok
	lea	dx,badmos
	mov	ah,9
	int	21h
	mov	ax,4c01h
	int	21h
mosok:

; all ok continue with bussiness

	mov	ax,3300h
	int	21h
	mov	[cntrlc],dl
	xor	dl,dl
	mov	ax,3301h
	int	21h
	mov	si,80h 			; start of command line
	mov	bl,byte ptr [si]	; get command lenght  (bug in masm )
	inc	si
	or	bl,bl
	jz	begin0
	call	skipspc 		; skip spaces
	or	bl,bl
	jnz	begin1
begin0:
	mov	dx,offset tsl
	mov	ah,9
	int	21h
	mov	dx,offset syntax
	mov	ah,9
	int	21h
	int	20h
begin1:
	push	bx
	push	es
	mov	ah,002h
	int	services
	assume	es:scbs
	mov	ax,es:[bx+scbtcbpc]
	pop	es
	pop	bx
	mov	[tcbseg],ax
	lea	di,parm1
	call	cpyparm
	mov	[len1],cl
	call	skipspc
	or	bl,bl
	jnz	begin11
	jmp	begin2
begin11:
	lea	di,parm2
	call	cpyparm
	mov	[len2],cl
	or	cl,cl
	jnz	begin12
	jmp	begin2
begin12:
	cmp	cl,1
	je	begin13
	jmp	begin3
begin13:
	mov	al,byte ptr [parm2]
	call	upper
	or	al,al
	jnz	begin14
	jmp	begin3
begin14:
	mov	[class],al
	push	cs
	pop	es
	mov	bl,[len1]
	xor	bh,bh
	mov	[bx+parm1],0
	lea	dx,parm1		; get directory path
	lea	bx,buff83
	mov	ax,0300h		; get security information
	int	services
	jnc	begin1a
	lea	dx,erpath		; error in path
	call	error
	jmp	finish
begin1a:
	cmp	al,3			; must have access of 3
	je	begin1b
	lea	dx,eracc		; invalid access
	call	error
	jmp	finish
begin1b:
	mov	al,[class]		; get class
	mov	[clsin],al
	lea	bx,buff83
	lea	dx,parm1
	mov	ax,0301h		; set security information
	int	services
	jnc	begin1c
beg_err:
	lea	dx,erdir		; error processing directory
	call	error
	jmp	finish
begin1c:

; after id4f03 call completes, must insure that the directory's
; system bit is set.

	lea	dx,parm1
	mov	ax,4300h
	int	21h
	jc	beg_err

; i21f4301 can't handle seeing the directory attribute in entry cx

	and	cx,not 10h

; if new class is space or 0, insure system bit is reset
; else, insure system bit is set

	cmp	[class],' '
	je	beg1c1
	cmp	[class],0
	je	beg1c1
	or	cx,4
	jmp	short beg1c2
beg1c1:
	and	cx,not 4h
beg1c2:
	lea	dx,parm1
	mov	ax,4301h
	int	21h
	jc	beg_err
	lea	dx,status
	mov	ah,9
	int	21h
	mov	cl,[len1]
	xor	ch,ch
	lea	si,parm1
begin1d:
	lodsb
	call	upper			; convert to upper case
	mov	dl,al			; display character
	mov	ah,2
	int	21h
	loop	begin1d
	mov	al,[class]
	mov	[clmsg],al
	lea	dx,stmsg
	mov	ah,9
	int	21h
	jmp	short finish
begin2:
	cmp	[len1],2
	jne	begin3
	mov	es,[tcbseg]
	assume	es:tcb
	mov	al,[parm1+1]
	cmp	al,'*'
	jne	begin2a
	mov	al,es:[tcbcdft]
	jmp	short begin2b
begin2a:
	call	upper
	or	al,al
	je	begin3
begin2b:
	mov	[class],al
	mov	al,[parm1]
	cmp	al,'*'
	jne	begin2c
	mov	al,es:[tcbclass]
	jmp	short begin4
begin2c:
	call	upper
	or	al,al
	jnz	begin4
begin3:
	lea	dx,clsspec
	call	error
	jmp	short finish
begin4:
	push	ax
	mov	al,[class]
	call	chkclass
	pop	ax
	jc	finish
	call	chkclass
	jc	finish
	mov	es,[tcbseg]
	assume	es:tcb
	mov	es:[tcbclass],al
	mov	[clmsg],al
	lea	dx,utmsg
	mov	ah,9
	int	21h
	lea	dx,clmsg
	int	21h
	mov	al,[class]
	mov	es:[tcbcdft],al
	mov	[clmsg],al
	lea	dx,dfmsg
	int	21h
	lea	dx,clmsg
	int	21h
finish:
	mov	dl,[cntrlc]
	mov	ax,3301h
	int	21h
	int	20h

moss ends
	end start

