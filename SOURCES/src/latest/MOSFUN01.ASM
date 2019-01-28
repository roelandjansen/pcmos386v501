	include page.inc
	title	mosfun01.asm - general function calls

; extrn	bugerror:near		; defined to turn stack overflow on
comment ^===============================================================
		development specification

 program name:	$$mos.com		assigned to: david morrow
 module name:	mosfun01		assign date: 09/30/86
 entry points:	mosfunxx (see below)	completed:
 entry from:	mosint21
 entry method:	call
 calls:
 purpose:	keyboard, aux, and printer functions
 last update:	08/18/1992
========================================================================

mjs 11/7/86	match mods to mosmiman

jsm 02/13/87	make fun06 match ms-dos manual

mjs 2/24/87	cooking mods - set bit #3 of tcb%confg for every 
		call except 0a to insure outdev would echo to con 
		instead of stdout on buffered input

sah 11/25/87	made function 0ch clear the buffer it was commented, 
		but never implemented (i can't believe it!)

sah 11/30/87	corrected method of test for keys in function 0bh (and 
		function 6) problem was occuring because tcbconfg
		was not being updated at all during the call.

sah 01/20/88	change scbseg and zero seg access to mgetxxxx macros

sah/rbr 02/20/88 move ddt segment to mo2 group

sah 02/27/88	corrected 11/30/87 changes for output case.

rbr 03/12/88	some optimization to reduce number of segreg loads.

mjs 12/09/88	modify function 0a to accomodate case where input
		redirection is being used from a pipe driver.

mjs 11/02/89	modify function 06 to return the character displayed
		in al (from entry dl when dl != ff).  fastape.exe
		was counting on this.  dos does this but it isn't doc'd.

sah 11/30/89	if function 06, and dl != ff, then we will need to zero
		tcbkbcnt, do that applications using function 06 to
		display will run efficiently in disable mode.

mjs 04/19/90	remove code at end of fun06 and fun0b which manipulates
		tcbconfg.   this was put in in 02/88 by sah to 
		correct problems with the config.exe program of cadkey
		but is actually not needed.  a side effect of this
		change was causing problems with progress.

SAH 09/06/91    Change function 06 so that it only call readdev once if
		standard in is redirected to a file.

================ 5.01 Kernel Ends Here ====================================

mjs 08/18/92	clean up segment declarations

======================================================================^

.xlist
;	include mosfun01.asm
	include group.inc
	include mosregs.inc
	include mostfb.inc
	include macros.inc

tcb	segment at 9999h
	include mostcb.inc
tcb	ends

gdata	segment
	include mosscbex.inc
gdata	ends
.list

gdata	segment
chardump db	?			; use in mosfun0a
gdata	ends

;======================================================== mos segment
if 0 eq 0
segment_num = 1
endif
mosseg	segment
	assume	cs:mos,ds:grp,es:nothing,ss:tcb

	extrn	mosend:byte
	extrn	moserror:near, caps:near, findtfb:near, noswitch:near
	extrn	readguts:near, writeguts:near, okswitch:near
	extrn	callcon:near

	public	writdev 		; for mosmiman


	subttl	readdev - read from device
	page
;======================================================================
;,fs
; readdev - read from device
;
; in:	ax:dx -> buffer to read into
;	di = byte length to read
;	es -> tfb for handle
;
; out:	cx = number of bytes read (0 implies eof)
;
;,fe
;======================================================================
	assume	ds:grp,es:tfb,ss:tcb
readdev:
	push	si
	push	ds
	inc	[scbnoswt]

; normalize buffer address to prevent segment overrun

	push	ax			; normalized segment
	pop	ds			; get buffer segment
	mov	cx,di			; count for read
	callmos2 readguts		; returns cx bytes read
	assume	ds:nothing,es:nothing,ss:tcb
	pop	ds
	assume	ds:grp			
	dec	[scbnoswt]		
	pop	si
	ret


	subttl	writdev - write to device
	page
;======================================================================
;,fs
; writdev - write to device
;
; in:	ax:dx -> buffer to write from
;	di = byte length to write
;	es -> tfb for handle
;
; out:	cx = number of bytes written
;
;,fe
;======================================================================
	assume	ds:grp,es:nothing,ss:tcb
writdev:
	push	si
	push	ds
	inc	[scbnoswt]
	push	ax			; normalized buffer pointer segment
	pop	ds			; get segment of buffer
	assume	es:tfb
	mov	cx,di
	callmos2 writeguts
	assume	ds:nothing,es:nothing,ss:tcb
	pop	ds
	assume	ds:grp
	dec	[scbnoswt]
	pop	si
	ret


	subttl	mosfun01 - keyboard input
	page
;======================================================================
;,fs
; mosfun01 - keyboard input
;
; reads the next key from the standard input device and echos the
; character to the standard output device.  if ctrl-break is found
; then an int 23h is issued.
;
; in:	none
;
; out:	tal - character read
;
;,fe
;======================================================================
	assume	cs:mos,ds:grp,ss:tcb,es:nothing
public	mosfun01
lproc	mosfun01
lbyte	kbbuf				; buffer for kb device read and write
	mov	al,[tcbconfg]		; save current state of console control flags
	push	ax

; no echo, wait, exact len, cont keys

	mov	byte ptr [tcbconfg],00011110b
	mov	bx,0			; stdin
	call	cfindtfb		; find tfb for handle
	mov	ax,ss			; address of buffer
	lea	dx,kbbuf		; "     "
	mov	di,1			; read one char
	call	readdev

; echo, cont keys

	mov	byte ptr [tcbconfg],00011001b
	mov	bx,1			; stdout
	call	cfindtfb		; find tfb for handle
	mov	ax,ss			; address of buffer
	lea	dx,kbbuf		; "     "
	mov	di,1			; write one char
	call	writdev
	pop	ax			; console flags back
	mov	[tcbconfg],al
	mov	al,[kbbuf]
	mov	bx,bp
	mov	bp,[bp] 		; address task registers
	mov	[tal],al
	mov	bp,bx
lundef	kbbuf
lendp	mosfun01


	subttl	mosfun02 - display output
	page
;======================================================================
;,fs
; mosfun02 - display output
;
; outputs a character to the standard output device then checks it for
; ctrl-break.  a backspace (8h) is nondestructive.
;
; in:	tdl - character to output
;
; out:	none
;
;,fe
;======================================================================
	assume	cs:mos,ds:grp,ss:tcb,es:nothing
public	mosfun02
lproc	mosfun02
lbyte	kbbuf				; buffer for kb device read and write
	mov	bx,bp
	mov	bp,[bp]
	mov	dl,[tdl]		; get char to write
	mov	bp,bx
	mov	al,[tcbconfg]		; save current state of console control flags
	push	ax

; echo, cont keys

	mov	byte ptr [tcbconfg],00011001b
	mov	[kbbuf],dl
	mov	bx,1			; stdout
	call	cfindtfb		; find tfb for handle
	mov	ax,ss			; address of buffer
	lea	dx,kbbuf		; "     "
	mov	di,1			; write one char
	call	writdev
	pop	ax			; console flags back
	mov	[tcbconfg],al
lundef	kbbuf
lendp	mosfun02


	subttl	mosfun03 - auxiliary input
	page
;======================================================================
;,fs
; mosfun03 - auxiliary input
;
; reads the next character from the standard auxiliary device.
;
; in:	none
;
; out:	tal - character read
;
;,fe
;======================================================================
	assume	cs:mos,ds:grp,ss:tcb,es:nothing
public	mosfun03
lproc	mosfun03
lbyte	combuf
	mov	bx,3			; stdaux
	call	cfindtfb		; find tfb for handle
	mov	ax,ss			; address of buffer
	lea	dx,combuf		; "     "
	mov	di,1			; read one char
	call	readdev
	mov	al,[combuf]
	mov	bx,bp
	mov	bp,[bp] 		; address task registers
	mov	[tal],al
	mov	bp,bx
lundef	combuf
lendp	mosfun03

	subttl	mosfun04 - auxiliary output
	page
;======================================================================
;,fs
; mosfun04 - auxiliary output
;
; writes a character to the standard auxiliary device.
;
; in:	tdl - character to write
;
; out:	none
;
;,fe
;======================================================================
	assume	cs:mos,ds:grp,ss:tcb,es:nothing
public	mosfun04
lproc	mosfun04
lbyte	combuf
	mov	bx,bp
	mov	bp,[bp] 		; address task registers
	mov	dl,[tdl]		; get char to write
	mov	bp,bx
	mov	[combuf],dl
	mov	bx,3			; stdaux
	call	cfindtfb		; find tfb for handle
	mov	ax,ss			; address of buffer
	lea	dx,combuf		; "     "
	mov	di,1			; read one char
	call	writdev
lundef	combuf
lendp	mosfun04


	subttl	mosfun05 - printer output
	page
;======================================================================
;,fs
; mosfun05 - printer output
;
; outputs a character to the standard printer device.
;
; in:	tdl - character to write
;
; out:	none
;
;,fe
;======================================================================
	assume	cs:mos,ds:grp,ss:tcb,es:nothing
public	mosfun05
lproc	mosfun05
lbyte	prnbuf
	mov	bx,bp
	mov	bp,[bp] 		; address task registers
	mov	dl,[tdl]		; get char to write
	mov	bp,bx
	mov	[prnbuf],dl
	mov	bx,4			; stdprn
	call	cfindtfb		; find tfb for handle
	mov	ax,ss			; address of buffer
	lea	dx,prnbuf		; "     "
	mov	di,1			; read one char
	call	writdev
lundef	prnbuf
lendp	mosfun05


	subttl	mosfun06 - direct console i/o
	page
;======================================================================
;,fs
; mosfun06 - direct console i/o
;
; gets a character from the standard input device if one is ready else
; returns without the character.
; raw mode
;
; note that setting al to zero for the input call is not documented in
; the pc-dos manual, but only the ms-dos manual.
;
; in:	tdl - 0ffh for console input
;	      00h-0feh for console output
;
; out:	tal - character read or 0 if no char available (if tdl = 0ffh)
;	tzf - 1 if no character ready
;
;,fe
;======================================================================
	assume	cs:mos,ds:grp,ss:tcb,es:nothing
public	mosfun06
lproc	mosfun06
lbyte	kbbuf
	mov	bx,bp
	mov	bp,[bp] 		; address task registers
	mov	dl,[tdl]
	mov	bp,bx
	mov	al,[tcbconfg]		; save current state of console control flags
	push	ax

; no cont keys, no wait (simulate command #5)

	mov	byte ptr [tcbconfg],00001000b
	cmp	dl,0ffh 		; is this an input call?
	jne	fun06out		; no
	mov	bx,0			; stdin
	call	cfindtfb		; find tfb for handle
	assume	es:tfb
	mov	ax,ss			; address of buffer
	lea	dx,kbbuf		; "     "
	mov	di,1			; read one char
	call	readdev
	mov	bx,bp
	mov	bp,[bp] 		; address task registers
	or	[tflag],zero		; set for no char ready
	test	[tfbioctl], 80h 	; character device
	jnz	fun06a0 		; yes skip the cx check
	jcxz	fun06a1
	test	[tfbioctl],01h		; is this standard in
	jnz	fun06a0			; yes... then continue
	and	[tflag],not zero	; tell task chars ready
	mov	bp,bx	     		; set bp back to local variables
	jmp	short fun06ax		; jump directory in to return code
fun06a0:
	test	[tcbconfg],2		; any characters available?
	jz	fun06a			; yes
fun06a1:
	mov	[tal],0 		; follow ms-dos manual, set al to 0
	mov	bp,bx			; address local variables
	jmp	fun06b			; exit
fun06a:
	and	[tflag],not zero	; tell task chars ready
	mov	bp,bx			; address local variables

; no echo, wait, exact length, no cont keys

	mov	byte ptr [tcbconfg],00001110b
	mov	bx,0			; stdin
	call	cfindtfb		; find tfb for handle
	mov	ax,ss			; address of buffer
	lea	dx,kbbuf		; "     "
	mov	di,1			; read the char to get it out of the type
	call	readdev 		; ahead buffer
fun06ax:				
	mov	[tcbkbcnt],00h		; make sure that we reset disable logic
	mov	al,[kbbuf]		; get read char
	mov	bx,bp
	mov	bp,[bp] 		; address task registers
	mov	[tal],al
	mov	bp,bx
	jmp	fun06b
fun06out:

; no echo/tab, no cont keys

	mov	byte ptr [tcbconfg],00001000b
	mov	[kbbuf],dl		; char to write
	mov	bx,1			; stdout
	call	cfindtfb		; find tfb for handle
	mov	ax,ss			; address of buffer
	lea	dx,kbbuf		; "     "
	mov	di,1			; write one char
	call	writdev
	mov	[tcbkbcnt],00h		; make sure that we reset disable logic
	mov	bx,bp
	mov	bp,[bp] 		; address task registers
	mov	al,[tdl]
	mov	[tal],al
	mov	bp,bx
fun06b:
	pop	ax			; console flags back
	mov	[tcbconfg],al		; restore to original value
fun06d:
lundef	kbbuf
lendp	mosfun06


	subttl	mosfun07 - direct console input (no echo)
	page
;======================================================================
;,fs
; mosfun07 - direct console input (no echo)
;
; reads the next key from the standard input device.  no check is made
; on the character.
;
; in:	none
;
; out:	tal - character read
;
;,fe
;======================================================================
	assume	cs:mos,ds:grp,ss:tcb,es:nothing
public	mosfun07
lproc	mosfun07
lbyte	kbbuf				; buffer for kb device read and write
	mov	al,[tcbconfg]		; save current state of console control flags
	push	ax

; no echo, wait, exact len, no cont keys

	mov	byte ptr [tcbconfg],00001110b
	mov	bx,0			; stdin
	call	cfindtfb		; find tfb for handle
	mov	ax,ss			; address of buffer
	lea	dx,kbbuf		; "     "
	mov	di,1			; read one char
	call	readdev
	pop	ax			; console flags back
	mov	[tcbconfg],al
	mov	al,[kbbuf]
	mov	bx,bp
	mov	bp,[bp] 		; address task registers
	mov	[tal],al
	mov	bp,bx
lundef	kbbuf
lendp	mosfun07

	subttl	mosfun08 - console input (no echo)
	page
;======================================================================
;,fs
; mosfun08 - console input (no echo)
;
; reads the next key from the standard input device.  if ctrl-break is
; found then an int 23h is issued.
;
; in:	none
;
; out:	tal - character read
;
;,fe
;======================================================================
	assume	cs:mos,ds:grp,ss:tcb,es:nothing
public	mosfun08
lproc	mosfun08
lbyte	kbbuf				; buffer for kb device read and write
	mov	al,[tcbconfg]		; save current state of console control flags
	push	ax

; no echo, wait, exact len, cont keys

	mov	byte ptr [tcbconfg],00011110b
	mov	bx,0			; stdin
	call	cfindtfb		; find tfb for handle
	mov	ax,ss			; address of buffer
	lea	dx,kbbuf		; "     "
	mov	di,1			; read one char
	call	readdev
	pop	ax			; console flags back
	mov	[tcbconfg],al
	mov	al,[kbbuf]
	mov	bx,bp
	mov	bp,[bp] 		; address task registers
	mov	[tal],al
	mov	bp,bx
lundef	kbbuf
lendp	mosfun08


	subttl	mosfun09 - print string
	page
;======================================================================
;,fs
; mosfun09 - print string
;
; ouputs a string of characters to the standard output device.	the
; string is terminated with a '$'.
;
; in:	tds:tdx -> character string
;
; out:	none
;
;,fe
;======================================================================
	assume	cs:mos,ds:grp,ss:tcb,es:nothing
public	mosfun09
lproc	mosfun09
	mov	bx,bp
	mov	bp,[bp]
	mov	di,[tdx]		; get pointer to string to write
	mov	es,[tds]		; "     "	"
	mov	bp,bx
	mov	al,[tcbconfg]		; save current state of console control flags
	push	ax

; echo/tab, cont keys

	mov	byte ptr [tcbconfg],00011001b
	push	di
	mov	al,'$'
	mov	cx,0ffffh		; allow rrrreeeeaaaaalllll long strings!
	repne scasb			; find end of string
	mov	ax,cx
	xor	cx,cx
	sub	cx,ax			; calc length of string
	sub	cx,2			; do not include '$'
	pop	dx			; get buffer pointer
	mov	ax,es			; "     "
	mov	bx,1			; stdout
	call	cfindtfb		; find tfb for handle
	mov	di,cx			; count to write
	call	writdev
	pop	ax			; console flags back
	mov	[tcbconfg],al
lendp	mosfun09


	subttl	mosfun0a - buffered keyboard input
	page
;======================================================================
;,fs
; mosfun0a - buffered keyboard input
;
; reads character from the standard input device and places them in a
; buffer passed by the caller.	the 1st byte of the buffer is the
; buffer size and the second byte of the buffer is the count of
; characters read (not including the cr).  the input is terminated on
; a cr.  if the buffer is full before a cr then a bell is output until
; a cr is read.
;
; in:	tds:tdx -> input buffer
;
; out:	none
;
;,fe
;======================================================================
	assume	cs:mos,ds:grp,ss:tcb,es:nothing
public	mosfun0a
lproc	mosfun0a
	mov	al,[tcbconfg]		; save current state of console control flags
	push	ax

; echo/tab, cont keys

	mov	byte ptr [tcbconfg],00010011b
	mov	bx,bp
	mov	bp,[bp] 		; address task registers
	mov	si,[tdx]		; get pointer to buffer
	mov	es,[tds]		; "     "	"
	mov	bp,bx
	mov	al,es:[si]		; read byte count from buffer
	xor	ah,ah
	mov	di,ax
	mov	dx,si
	add	dx,2			; init ax:dx to point to the buffer
	mov	ax,es
	push	es
	push	dx
	mov	bx,0
	call	cfindtfb		; find tfb for handle
	assume	es:tfb
	test	[tfbioctl],80h		; is it a char device ?
	jnz	fun0a1			; jmp if yes, else filter one char at a time

; ax:dx points to buffer, di is count, es is tfb

	xor	si,si			; init tally counter
	mov	bx,di
	or	bx,bx
	jz	fun0a2
fun0a7:
	mov	di,1
	push	ax
	push	dx
	push	bx
	call	readdev
	pop	bx
	pop	dx
	pop	ax
	jcxz	fun0a2
	or	bx,bx
	jz	fun0a4
	assume	es:nothing
	push	es
	push	bx
	mov	es,ax
	mov	bx,dx
	cmp	byte ptr es:[bx],0dh	; just read a cr ?
	jz	fun0a5
	cmp	byte ptr es:[bx],1ah	; just read a ctrl-z ?
	pop	bx
	pop	es
	jnz	fun0a6
	xor	bx,bx			; cause short cycling until a cr or eof
	jmp	fun0a7			; is detected
fun0a6:
	inc	si
	inc	dx
	dec	bx
	jz	fun0a2
	jmp	fun0a7
fun0a4:
	push	es
	push	bx
	mov	es,ax			; short cycle once a 1a is found
	mov	bx,dx
	cmp	byte ptr es:[bx],0dh	; just read a cr ?
	pop	bx
	pop	es
	jnz	fun0a7
	jmp	fun0a8
fun0a5:
	pop	bx
	pop	es
fun0a8: 				; when find a cr, must read the 0a
	mov	ax,ds			;sr1
	lea	dx,[chardump]
	mov	di,1
	call	readdev
	jmp	fun0a2
fun0a2:
	pop	bx			; was pushed as dx
	pop	es
	dec	bx
	mov	ax,si
	mov	es:[bx],al		; write return count in user's buffer
	mov	byte ptr es:[bx+si+1],0dh  ; write a cr at the end
	jmp	fun0a3
fun0a1:
	call	readdev 		; call mosmiman driver
	pop	bx
	pop	es
	dec	bx

; modify return count here to accomodate case where the pipe device has been
; redirected to standard input (e.g. command <pipe).

	push	ax
	push	cx
	push	di
	mov	di,bx
	inc	di
	xor	ch,ch
	jcxz	chkcr1
	mov	al,0dh
	cld
	repne	scasb
	jne	chkcr1
	sub	di,bx
	sub	di,2
	mov	cx,di
	pop	di
	pop	ax			; throw away original cx
	jmp	chkcr2
chkcr1:
	pop	di
	pop	cx
chkcr2:
	pop	ax
	mov	es:[bx],cl		; set return count in buffer
fun0a3:
	pop	ax			; console flags back
	mov	[tcbconfg],al
lendp	mosfun0a

	subttl	mosfun0b - check standard input status
	page
;======================================================================
;,fs
; mosfun0b - check standard input status
;
; checks for character availability from the standard input device.
; checks for ctrl-break.
;
; in:	none
;
; out:	tal = 0ffh if character available
;	tal =  00h if no character available
;
;,fe
;======================================================================
	assume	cs:mos,ds:grp,ss:tcb,es:nothing
public	mosfun0b
lproc	mosfun0b
lbyte	kbbuf
	mov	al,[tcbconfg]		; save current state of console control flags
	push	ax

; no wait, cont keys

	mov	byte ptr [tcbconfg],00011000b
	mov	bx,0			; stdin
	call	cfindtfb		; find tfb for handle
	mov	ax,ss			; address of buffer
	lea	dx,kbbuf		; "     "
	mov	di,1			; read one char
	call	readdev
	mov	bx,bp
	mov	bp,[bp] 		; address task registers
	mov	[tal],0 		; set for no char ready
	test	[tcbconfg],2		; any characters available?
	jz	fun0b1			; yes
	mov	bp,bx			; address local variables
	jmp	fun0b2			; exit
fun0b1:
	mov	[tal],0ffh		; tell task chars ready
	mov	bp,bx
fun0b2:
	pop	ax			; console flags back
	mov	[tcbconfg],al		; sah or current status of key board for new
lundef	kbbuf
lendp	mosfun0b

	subttl	mosfun0c - clear kb buffer and do kb function
	page
;======================================================================
;,fs
; mosfun0c - clear kb buffer and do kb function
;
; clears the standard input buffer then executes the desired keyboard
; function.
;
; in:	tal - function # (1,6,7,8,a)
;
; out:	none
;
;,fe
;======================================================================
	assume	cs:mos,ds:grp,ss:tcb,es:nothing
kbnul	proc	near
	ret				; the old do nothing subroutine trick!
kbnul	endp

kbtable dw	mos:kbnul, mos:mosfun01, mos:kbnul, mos:kbnul, mos:kbnul
	dw	mos:kbnul, mos:mosfun06, mos:mosfun07, mos:mosfun08
	dw	mos:kbnul, mos:mosfun0a

	public	mosfun0c
mosfun0c proc	near

; clear kb here

	mov	al,7			; sah flush keyboard contents
	callmos2 callcon		; sah call console driver

; now invoke requested function

	mov	al,[tal]
	cmp	al,0ah			; max allowed
	jbe	fun0c1
	xor	al,al			; point to nul routine
fun0c1:
	mov	bl,al
	xor	bh,bh
	shl	bx,1
	call	[kbtable+bx]		; do requested function
	ret

mosfun0c endp

cfindtfb proc	near
	callmos2 findtfb
	ret
cfindtfb endp

mosseg	ends
	end

