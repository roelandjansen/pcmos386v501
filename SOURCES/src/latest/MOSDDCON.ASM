	include page.inc
	title	mosddcon - mos device driver for console i/o
comment ^===============================================================
		    development specification

 program name:	$$mos.sys		assigned to: david morrow
 module name:	mosddcon		assign date: 04/08/86
 entry points:	n/a			completed:
 entry from:	n/a
 entry method:	n/a
 calls: 	n/a
 purpose:	mos console device driver
 refer to:	n/a
 last update:	08/18/1992
========================================================================

sah 07/23/87	modify ndinput to check convert cntrl-prtsc into cntrl-p

sah 12/01/87	implemented wrap around ansi output sequence
		esc [?7h and esc [?7l.	please note remaining setmode
		and	reset mode, get status and keyboard reassignment
		need to be implemented

jsm 12/06/87	fixed erase to end of line command so that it would
		erase the last character

sah 01/20/88	change scbseg and zero seg access to use mgetxxxx macros.
		optimize mos10 and mos16 macros for code size

sah 02/18/88	remove mos16 macro and con16 proc which are not used

rbr/sah 02/21/88 move ddt code to mo2 group.

mjs 6/9/88	modified sah's new code which calls int16, func 1 and
		issues int28's if there is an int28 intercept for the
		current task.  because i had to skip around the call
		to tsl in mossaver when scbnoswt != 0, there was no
		way for tsl to get called when an int28 intercept
		was in place.  i added a call to tsl in the int16/int28
		loop	here so task switching would not stop.

rdg 6/20/88	modified instat to do an int16 to determine the actual
		status of the keyboard and to set the busy status if no
		character is ready.  (ptr 0050)

sah 06/21/88	remove unnessary safe28 calls, added support for ansi
		(not dos ansi compatible) ptr 064 clear to end of screen
		esc [0j. implemented status report ptr 061.

sah 08/11/88	corrected clear to end of screen.
		optimize module slight by removing calls to ckansi
		which did nothing.

sah 09/15/88	changes so that norvell execution speed will not be
		hurt by int 28 loop logic.  this is done by using int 38
		function to wait for a key or time.

sah 09/23/88	move wait above to mosint28 routine.  this is done
		because windows loops on int 28 when idea and placing
		wait inside mosint28 can improve performance on both.

sah 12/04/88	corrected rdg's 06/20/88 updated by skiping call to to
		get keyboard status if scan code is pending. this was
		causing mos to suspend unnecessary in devread if caller
		ask for 1 key at a time and key pressed is extended.

sah 03/24/89	correct int 28 looping for novell (or any int 28 inside
		a device driver - why put int 28 in a device driver in
		multitasking enviroment like mos) by making sure that
		scbnoswt is zero during the loop.

sah 08/15/89	revamp output for ansi processing. including the
		ability to disable ansi processing with mos ansi command

sah 08/29/89	corrections to mos ansi scrolling.

sah 01/09/90	implemented keyboard re-assigment (p). also remove some
		unuse code usage and other code optimization.

sah 11/16/90	correction dino.exe which was directly poking cursor
		position before int 21 call.

sah 01/23/91	correction for error processing on ansi attribute set

sah 04/05/91	corrections for chineese character set program et
		if int 10 is intercept than call int 10 to get cursor
		position instead of grabbing from tcbcpos.

sah 05/09/91	corrections for color prompts from my 04/05/91 changes

================ 5.01 Kernel Ends Here ====================================

mjs 05/22/92	converted all i16f00 and i16f01 calls to a call to
		the new call16 function.  this function uses the
		enhanced keyboard bit at 40:96 to modify i16f00 to i16f10
		and i16f01 to i16f11 when an enhanced keyboard is being
		used.  this is necessary to support alt-f11... as a
		hotkey for spool.com, monitor.com and any other
		tsr that intercepts int16.
		also, added filtering of e0 scancodes at the entrance
		to the keytrans function.
		updat501.sys version 0.04

================ 5.01 Kernel Ends Here ====================================

mjs 08/18/92	clean up segment declarations

=======================================================================^

.xlist
;	include mosddcon.pub
	include group.inc
	include mosregs.inc
	include macros.inc

tcb	segment at 1234h
	include mostcb.inc
tcb	ends

gdata	segment
	include mosscbex.inc
gdata	ends

.list

;======================================================== mos segment
if 0 eq 0
segment_num = 1
endif
mosseg	segment
	assume	cs:mos,ds:grp,es:nothing,ss:tcb

	extrn	sbios:word
	extrn	safe28:near, testmos28:near, tsl:near, mosint38:near

	public	scbstdcon, doesc, finstr

mos10	macro
	call	con10
	endm

getcrs0 macro
	call	getcrsx
	endm

;----------------------- device header ---------------------------------

	org	0h
scbstdcon label byte
	dd	-1
	dw	1000000000000011b	; char, stdin, stdout
	dw	mos:constrat
	dw	mos:conintr
	db	'CON     '		; standard console device

ten	db	10			; used for mul

funtbl	dw	dinit			; 0  init
	dw	donefun 		; 1  media check
	dw	donefun 		; 2  build bpb
	dw	donefun 		; 3  i/o control input
	dw	input			; 4  input (read)
	dw	ndinput 		; 5  nondestructive input no wait
	dw	instat			; 6  input status
	dw	inflsh			; 7  input flush
	dw	output			; 8  output (write)
	dw	output			; 9  output with verify (same as output)
	dw	donefun 		; 10 output status
	dw	donefun 		; 11 output flush
	dw	donefun 		; 12 i/o control output

	subttl constrat - console strategy routine
	page
;======================================================================
;,fs
; constrat - console strategy routine
;
; this routine is the console drivers strategy routine, it just
; queues the dword pointer to the request header.
; the pointer tcb$hdr is set in the current tasks tcb.
; 
; in:	es:bx points to the device request header.
; 
; out:	the request header pointer is saved.
; 
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:tcb
constrat proc	far
	mov	[tcb$hdr],bx		; save pointer in active tcb
	mov	[tcb$hdr+2],es
	ret
constrat endp

	subttl conintr - console interrupt routine
	page
;======================================================================
;,fs
; conintr - console interrupt routine
; 
; in:
; 
; out: 
; 
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:tcb
conintr proc	far
	push	ax
	push	bx
	push	cx
	push	dx
	push	es
	push	ds
	push	cs
	pop	ds
	assume	ds:mos
	les	bx,dword ptr [tcb$hdr]	; get request header pointer
	mov	al,es:[bx+2]		; get command code
	cmp	al,12			; check for invalid call
	ja	err1			; yes, exit with error
	xor	ah,ah
	mov	bx,offset funtbl
	shl	ax,1
	add	bx,ax
	call	[bx]			; execute appropriate routine
rexit:
	pop	ds
	pop	es
	pop	dx
	pop	cx
	pop	bx
	pop	ax
	ret
err1:
	les	bx,dword ptr [tcb$hdr]	; get request header pointer
	mov	word ptr es:[bx+3],8103h; return 'Unknown Command'
	jmp	rexit
conintr endp

	subttl donefun - done function
	page
;======================================================================
;,fs
; donefun - done function
; 
; in:
; 
; out: 
; 
;,fe
;======================================================================
	assume	ds:mos,es:nothing,ss:tcb
donefun proc	near
	les	bx,dword ptr [tcb$hdr]	; get pointer to rh
	mov	word ptr es:[bx+3],100h ; return with 'DONE'
	ret
donefun endp

	subttl input - input read
	page
;======================================================================
;,fs
; input - input read
; 
; in:
; 
; out: 
; 
;,fe
;======================================================================
	assume	ds:mos,es:nothing,ss:tcb
input	proc	near
	les	bx,dword ptr [tcb$hdr]	; get pointer to rh
	mov	ax,es:[bx+14]		; get offset transfer addrs
	mov	dx,es:[bx+16]		; get seg transfer addrs
	mov	cx,es:[bx+18]		; get byte count
	push	cx			; save byte count for later return value
	mov	bx,ax			; set buffer address
	mov	es,dx
	cmp	[tcbkboff],-1		; is in keys in translation buffer
	je	notrans

; handle keyboard translations here

	push	ds
	mov	si,[tcbkboff]		; get offset of translation
	mov	ds,[tcbkbansi]		; get translation buffer
tranloop:
	mov	al,byte ptr ds:[si]
	or	al,al			; are we done translations
	jz	donetrans
	mov	byte ptr es:[bx],al	; save into buffer
	inc	si
	inc	bx			; increment buffer pointer
	dec	cx
	jnz	tranloop		; continue looping - count runs out

; we done all we can do this time, save counter and return

	mov	[tcbkboff],si
	pop	ds
	jmp	endin
donetrans:
	pop	ds
	mov	word ptr [tcbkboff],-1	; should follow onto notrans
notrans:
	cmp	[tcb$kp],'Y'		; is scan code pending read?
	jne	inloop
	mov	al,[tcb$hb]		; get buffered scan code
	mov	es:[bx],al		; put code in buffer
	mov	[tcb$kp],'N'		; clear pending flag
	inc	bx			; inc buffer pointer
	dec	cx			; dec char count
	jnz	inloop
	jmp	endin
inloop:

; special code for int 28 efficiency only do int 28 if handler is
; install and do special version of int 16 which waits for before
; exiting

	call	testmos28		; test for mosint28 handler
	je	inskip

; we must set scbnoswt to zero before calling safe28, so that if
; someone pamswitches out while we are in this loop, that we allow
; switching, this corrected a problem with with novell int 28 handle
; which is not designed how real int 28 should be.

	push	ds
	mgetscb ds
	assume	ds:grp
	mov	al,[scbnoswt]		; get current noswitch flag
	push	ax			; save current switch flag on stack
public	in28loop
in28loop:
	mov	[scbnoswt],0
	call	safe28			; do int 28 while waiting for character
	mov	ah,1			; when tsr int 28 handler calls our int28
	call	call16			; we will suspend so that performance with
	jz	in28loop		; tsr's will be reasonable.
	pop	ax			; retrieve current switch flag off stack
	mov	[scbnoswt],al		; restore noswitch flag
	pop	ds
	assume	ds:mos
inskip:
	xor	ah,ah
	call	call16			; get at least one keystroke
	call	keytrans		; translate key into sequence
	or	ax,ax			; ctrl-break?
	jnz	nobrk
	mov	ax,103h 		; tell dos ctrl-c
nobrk:
	mov	es:[bx],al		; put char in buffer
	or	al,al			; extended key?
	jnz	noextn			; no
	mov	[tcb$hb],ah		; save for later
	mov	[tcb$kp],'Y'		; set flag that scan code is buffered
noextn:
	inc	bx
	dec	cx
	jz	endin
	cmp	[tcb$kp],'Y'		; is scan code pending read?
	jne	inloop
	mov	al,[tcb$hb]		; get buffered scan code
	mov	es:[bx],al		; put code in buffer
	mov	[tcb$kp],'N'		; clear pending flag
	inc	bx			; inc buffer pointer
	dec	cx			; dec char count
	jz	endin
	mov	ah,1
	call	call16			; check for any additional characters
	jnz	inloop			; yes, get them
	pop	ax			; original count
	sub	ax,cx			; calc # read
	push	ax
endin:
	pop	cx			; get byte count read
	les	bx,dword ptr [tcb$hdr]	; get pointer to rh
	mov	es:[bx+18],cx		; set byte count
	mov	word ptr es:[bx+3],100h ; return 'Done'
	ret
input	endp

	subttl keytrans - 
	page
;======================================================================
;,fs
; keytrans - 
; 
; in:
; 
; out: 
; 
;,fe
;======================================================================
	assume	ds:mos,es:nothing,ss:tcb
public	keytrans
keytrans proc	near

; if this is an extended key from an enhanced keyboard, 
; make it look like an extended key from a normal keyboard.

	cmp	al,0e0h
	jne	kt1
	xor	al,al
kt1:
	cmp	byte ptr [tcbansi],0ffh
	jne	ktskip
	cmp	word ptr [tcbkbansi],0
	je	ktskip
	push	es
	mov	es,[tcbkbansi]
	cmp	word ptr es:[0],-1
	je	ktskip2

; search for key in buffer if so make the translation

	push	bx
	push	dx
	push	di
	push	ax			; save current value of ax
	mov	bx,ax
	or	bl,bl			; is this extendend key sequence
	jz	kthigh
	mov	bh,bl
	mov	bl,-1			; handle single key re-assigment
kthigh:
	call	findkeyr		; search for key in key assignment area
	jnc	ktfinish
	add	di,2
	xor	ah,ah
	mov	al,byte ptr es:[di]
	inc	di
	cmp	byte ptr es:[di],0
	je	ktsingle
	mov	[tcbkboff],di
ktsingle:
	pop	bx			; discard old ax
	push	ax			; place new ax on stack
ktfinish:
	pop	ax

	pop	di
	pop	dx
	pop	bx
ktskip2:
	pop	es
ktskip:
	 ret
keytrans endp

	subttl ndinput - nondestructive input no wait
	page
;======================================================================
;,fs
; ndinput - nondestructive input no wait
; 
; in:
; 
; out: 
; 
;,fe
;======================================================================
	assume	ds:mos,es:nothing,ss:tcb
ndinput proc	near
	les	bx,dword ptr [tcb$hdr]	; get pointer to rh
	mov	al,[tcb$hb]		; get buffered scan code
	cmp	[tcb$kp],'Y'		; is scan code pending read?
	je	nobrk2			; yes, return that
	mov	ah,1
	call	call16			; test keyboard
	jz	ndend			; no char, exit
	or	ax,ax			; break?
	jnz	nobrk2			; no
	mov	al,03			; return ctrl-c
nobrk2:
	cmp	ax,7200h		; ctrl-prtsc
	jne	nocps
	mov	al,10h			; set it to cntrl-p
nocps:
	mov	es:[bx+13],al		; return character
	mov	word ptr es:[bx+3],100h ; return 'Done'
	ret
ndend:
	mov	word ptr es:[bx+3],300h ; return 'Done' & 'Busy'
	ret
ndinput endp

	subttl instat - input status
	page
;======================================================================
;,fs
; instat - input status
; 
; in:
; 
; out: 
; 
;,fe
;======================================================================
	assume	ds:mos,es:nothing,ss:tcb
instat	proc	near
	les	bx,dword ptr [tcb$hdr]	; get pointer to request header
	mov	word ptr es:[bx+3],100h ; return 'Done - Char Ready'
	cmp	[tcb$kp],'Y'		; sah scan-code pending
	je	instat0 		; if so skip the keyboard test
	push	ax			; save ax
	mov	ah,1			; get keyboard status
	call	call16			; call the keyboard handler
	pop	ax			; restore ax
	jnz	instat0 		; jump if character ready
	mov	word ptr es:[bx+3],300h ; return 'Done - no Char Ready'
instat0:
	ret
instat	endp

	subttl inflsh - input flush
	page
;======================================================================
;,fs
; inflsh - input flush
; 
; in:
; 
; out: 
; 
;,fe
;======================================================================
	assume	ds:mos,es:nothing,ss:tcb
inflsh	proc	near
	mov	ah,1			; read any buffered characters
	call	call16
	jz	endflsh
	xor	ah,ah
	call	call16
	jmp	inflsh
endflsh:
	les	bx,dword ptr [tcb$hdr]	; get pointer to rh
	mov	word ptr es:[bx+3],100h ; return 'Done'
	ret
inflsh	endp

	subttl output - output write
	page
;======================================================================
;,fs
; output - output write
; 
; in:
; 
; out: 
; 
;,fe
;======================================================================
	assume	ds:mos,es:nothing,ss:tcb
output	proc	near
	public	outansi
outansi label	near
	push	bp			; used in bios string writes
	push	di
	les	bx,dword ptr [tcb$hdr]	; get pointer to rh
	mov	ax,es:[bx+14]		; get offset transfer addrs
	mov	dx,es:[bx+16]		; get seg transfer addrs
	mov	cx,es:[bx+18]		; get byte count
	mov	bx,ax			; set buffer address

; the following addition corrects problems with educational package
; which was directly poking the cursor position in bios and then
; call int 21  function for write in graphics mode.  i fix the
; problem by making sure the tcbcpos had the current bios position

	mgetzero es
	mov	ax,word ptr es:[450h]
	mov	[tcbcpos],ax
	mov	es,dx

; we will now test to see if ansi support is enable

	cmp	[tcbansi],0ffh
	je	charout

; handle non-ansi processing. this is fast through 1 int 10 call

	getcrs0 			; dx= cursor pos
	mov	bp,bx
	mov	bl,[tcb$ca]
	mov	ax,1301h		; string output with [char,char...] & move cur
	mov	bh,[tcbpage]
	mos10
	jmp	endout

; handle ansi emulation here.

charout:
	cmp	[tcb$ef],'Y'		; esc sequence pending?
	jne	charout2
	jmp	[tcb$er]		; yes
charout2:

; scan string for any esc sequences before outputing
; if found output up to esc seq. and then process esc seq.

	cld
	mov	di,bx
	push	cx			; save count
	mov	al,27			; scan for esc
	repne scasb
	pop	cx			; count back
	jne	finstr			; no escs, finish string output
escing:
	mov	[tcb$ef],'Y'		; set esc seq pending flag
	push	di			; save string pointer
	dec	di			; point to esc
	sub	di,bx			; calc # chars til esc
	sub	cx,di			; calc count for rest of string
	push	cx			; save new count
	mov	cx,di			; calc count before esc
	or	cx,cx			; is esc the 1st char?
	jnz	finstr			; sah
	jmp	esconly 		; sah
finstr:
	getcrs0 			; dx= cursor pos
	mov	si,bx
lpwrap:
	push	dx
	mov	ah,2
	mov	bh,[tcbpage]		; set cursor position
	mos10
	mov	al, byte ptr es:[si]
	cmp	al,13			; test for carriage-return
	je	wrapcr
	cmp	al,10			; test for line-feed
	je	wraplf
	cmp	al,8			; test for backspace
	je	wrapbs
	cmp	al,7			; test for bell
	je	wrapbell
	push	cx
	mov	bl,[tcb$ca]
	mov	bh,[tcbpage]
	mov	cx,1			; 1 character at a time
	mov	ah,9			; display char
	mos10				; must use function 9 so attribute is
	pop	cx			; displayed
	pop	dx

; after displaying character, we must test to see if we place character
; at botton right corner, if so we must scroll screen

	inc	dl
	cmp	dl,[tcbcols]		; test to see if end of line
	jb	wpneol
	push	dx
	mov	ax,0e0dh
	mov	bl,[tcb$ca]
	mos10
wraplf:
	getcrs0 			; get cursor
	inc	dh
	cmp	dh,[tcbrows]
	jb	setlf
	call	wscroll 		; must scroll the screen, don't do it
	dec	dh
setlf:
	pop	ax			; discard old cursor position
	jmp	short wpneol
wrapbell:
	mov	bl,[tcb$ca]
	mov	ah,0eh			; write tty
	mos10
wrapcont:
	pop	dx
	getcrs0
	jmp	short wpneol
wrapbs:
	pop	dx
	getcrs0
	or	dl,dl
	jz	wpneol
	dec	dl			; handle back space
	jmp	short wpneol
wrapcr: 				; carriage return
	pop	dx
	xor	dl,dl			; reset to row 0
wpneol:
	inc	si			; point to next char
	dec	cx
	jcxz	wrapdone
	jmp	lpwrap			; wrap till you done
wrapdone:
	mov	ah,2
	mov	bh,[tcbpage]
	mos10				; set cursor pos
	cmp	[tcb$ef],'Y'		; is esc seq pending?
	jne	endout			; no
esconly:
	pop	cx			; get size of new string
	pop	bx			; get string pointer
	dec	cx			; skip the esc char itself
	or	cx,cx			; end of string?
	jz	endout			; yes
	jmp	charout 		; continue with rest of string
endout:
	les	bx,dword ptr [tcb$hdr]	; get pointer to rh
	mov	word ptr es:[bx+3],100h ; return 'Done'
	pop	di
	pop	bp
	ret

	subttl wscroll - scroll the screen if necessary
	page
;======================================================================
;,fs
; wscroll - scroll the screen if necessary
; 
; in:
; 
; out: 
; 
;,fe
;======================================================================
	assume	ds:mos,es:nothing,ss:tcb
wscroll proc	near
	push	cx
	push	dx
	mov	ax,0601h
	xor	cx,cx
	mov	dh,[tcbrows]
	dec	dh
	mov	dl,4fh
	mov	bh,[tcb$ca]
	push	dx
	mos10
	pop	dx
	mov	cx,dx
	xor	cl,cl
	mov	ax,0600h
	mov	bh,07h
	mos10
	pop	dx
	pop	cx
	ret
wscroll endp

	subttl curinc - increment current cursor position and wrap line if needed
	page
;======================================================================
;,fs
; curinc - increment current cursor position and wrap line if needed
; 
; in:	bh = page on entry
; 
; out: 
; 
;,fe
;======================================================================
	assume	ds:mos,es:nothing,ss:tcb
curinc	proc	near
	push	dx
	getcrs0 			; read cursor position
	inc	dl
	cmp	dl,80			; end of line?
	jne	lineok			; not yet
	mov	ah,14
	mov	al,10			; send lf and let bios do scroll if needed
	mov	bl,[tcb$ca]		; attribute
	mov	bh,[tcbpage]
	mos10
	getcrs0
	xor	dl,dl
lineok:
	mov	ah,2			; set new cursor position
	mov	bh,[tcbpage]
	mos10
	pop	dx
	ret
curinc	endp

	subttl con10 - 
	page
;======================================================================
;,fs
; con10 - 
; 
; in:	
; 
; out: 
; 
;,fe
;======================================================================
	assume	ds:mos,es:nothing,ss:tcb
con10	proc	near
	push	ds
	mgetzero ds
	pushf
	cli
	call	dword ptr ds:[10h*4]
	pop	ds
	ret
con10	endp

	subttl getcrsx - get cursor position
	page
;======================================================================
;,fs
; getcrsx - get cursor position
; 
; the following routine is use to get the current cursor position, for
; maximun performance, if int 10h intercept points to mos's kenrel
; than return value at tcbcpos
;
; in:
; 
; out: 
; 
;,fe
;======================================================================
	assume	ds:mos,es:nothing,ss:tcb
	public	getcrsx
getcrsx proc	near
	push	ds
	push	ax
	push	bx
	push	cx
	mgetzero ds
	mov	ah,3
	mov	bh,[tcbpage]
	pushf
	cli
	call	dword ptr ds:[10h*4]
	pop	cx
	pop	bx
	pop	ax
	pop	ds
	ret
getcrsx endp

;-----------------------------------------------------------------------
; the following table is used to check for valid characters in an esc
; sequence.  if any of the characters in the 1st part of the table are
; received then the sequence is processed.  if any of the characters
; in the 2nd part of the table are received then they are buffered
; until a terminator is received.
;-----------------------------------------------------------------------

seqtbl	db	'HABCDfnsuJKmhlp'	; valid ansi function terminators
seqrtn	db	'1234567890;=?' 	; valid characters in esc sequence
seqlen	equ	$ - mos:seqtbl		; used to set up scan length

;-----------------------------------------------------------------------
; this table is used for the address look up of the appropriate routine
; to call for each esc sequence supported by the ansi standard.
;-----------------------------------------------------------------------
rtntbl	dw	escpos			; h  cursor position
	dw	escup			; a  "   up
	dw	escdn			; b  "   down
	dw	escfwd			; c  "   forward
	dw	escbak			; d  "   backward
	dw	eschvp			; f  "   horz and vert position
	dw	esstat			; n  device status report
	dw	escsav			; s  save cursor position
	dw	escrst			; u  restore cursor position
	dw	escls			; j  clear screen (erase in display)
	dw	eseol			; k  clear to end of line
	dw	essgr			; m  set graphics rendition
	dw	essm			; h  set mode
	dw	esrm			; l  reset mode
	dw	eskeyr			; p  key reassignment

;-----------------------------------------------------------------------
doesc:
	mov	al,es:[bx]		; get 1st char of esc seq
	inc	bx
	cmp	al,'['			; check for valid seq
	je	$+5
	jmp	escabort		; invalid sequence, abort
	mov	[tcb$er],offset mos:doesc2
	jmp	escexit
doesc2:
	mov	al,es:[bx]
	inc	bx
	push	es
	push	di
	push	cx
	mov	cx,cs			; for scaning local table
	mov	es,cx
	assume	es:nothing
	cmp	al,'"'			; Double quotes need special consideration
	jne	noquote
	xor	[tcb$iq],1		; toggle quote switch
	jmp	dobuffer
noquote:
	cmp	[tcb$iq],0		; are we inside a quote?
	jne	dobuffer		; yes, just buffer what ever it is
	mov	di,offset seqtbl	; scan for valid character in seq.
	mov	cx,seqlen
	repne	scasb			; scan while al ne to any char in string
	je	charok
	jmp	esc2end 		; invalid sequence
charok:
	cmp	di,offset mos:seqrtn	; is this char a sequence terminator?
	ja	dobuffer		; no, just buffer it
	push	di			; buffer esc terminator
	mov	di,[tcb$ebp]		; get current buffer pointer
	xor	ah,ah			; assure buffer terminated by 0
	push	es
	push	ss
	pop	es			; stos cannot be overridden
	stosw
	pop	es
	dec	di			; point to term 0 for next input
	mov	[tcb$ebp],di		; update new pointer
	pop	di
	dec	di			; correctly point to char that matched
	sub	di,offset mos:seqtbl	; calc char offset in table
	shl	di,1
	push	ds
	push	ss
	pop	ds
	assume	ds:tcb
	call	[rtntbl+di]		; transfer to appropriate routine
	pop	ds
	assume	ds:mos
	mov	[tcb$er],offset mos:doesc
	mov	[tcb$ef],'N'		; no sequence now pending
	jmp	esc2end
dobuffer:
	mov	di,[tcb$ebp]		; get current buffer pointer
	xor	ah,ah			; assure buffer terminated by 0
	push	es
	push	ss
	pop	es			; stos cannot be overridden
	stosw
	pop	es
	dec	di			; point to term 0 for next input
	mov	[tcb$ebp],di		; update new pointer
esc2end:
	pop	cx
	pop	di
	pop	es
	jmp	escexit

;-----------------------------------------------------------------------
escabort:
	mov	[tcb$er],offset mos:doesc
	mov	[tcb$ef],'N'		; no sequence now pending
	mov	ah,14			; tty output
	push	bx
	mov	bl,[tcb$ca]		; attribute
	mov	bh,[tcbpage]
	mos10
	pop	bx
escexit:
	dec	cx
	jnz	contout
	jmp	endout			; no more to output, end
contout:
	jmp	charout 		; continue with character output

output	endp

	subttl dec2bin - decimal to binary conversion
	page
;======================================================================
;,fs
; dec2bin - decimal to binary conversion
; 
; this routine will retreive the one or two digit ascii number pointed
; to by ds:si and translate it to binary then return the result in al
; on entry al = esc terminator for this sequence.
;
; in:
; 
; out: 
; 
;,fe
;======================================================================
	assume	ds:tcb,es:nothing,ss:tcb
dec2bin proc	near
	push	bx
	mov	bh,al			; esc terminator
	mov	bl,1			; set default
	mov	al,[si] 		; get 1st num
	cmp	al,'0'			; check for valid range
	jb	ckbad
	cmp	al,'9'
	ja	ckbad
	sub	al,'0'			; calc binary
	mov	bl,al			; set new default
	inc	si
	mov	al,[si] 		; get 1st num
	cmp	al,'0'			; check for valid range
	jb	ckbad
	cmp	al,'9'
	ja	ckbad
	sub	al,'0'			; calc binary
	xchg	al,bl
	mul	[ten]
	add	al,bl
	inc	si			; point to next char after numbers

; handle 3 digit numbers

	cmp	byte ptr [si],'9'
	ja	digit2
	cmp	byte ptr [si],'0'
	jb	digit2
	mul	[ten]
	add	al,byte ptr [si]
	sub	al,'0'
	inc	si
digit2:
	pop	bx
	ret
ckbad:
	cmp	al,';'			; delimiter?
	jne	ckseqend		; no, check for sequence end
seqterm:
	mov	al,bl
	pop	bx
	clc				; no errors return flag
	ret
ckseqend:
	cmp	al,bh			; is this the end of the sequence
	je	seqterm 		; yes
	stc				; set error return flag
	pop	bx
	ret
dec2bin endp

	subttl escpos - process cursor position
	page
;======================================================================
;,fs
; escpos - process cursor position
; 
; on entry tcb$eb holds characters between '[' and terminating char
;
; in:
; 
; out: 
; 
;,fe
;======================================================================
	assume	ds:tcb,es:nothing,ss:tcb
escpos	proc	near
	push	bx
	push	cx
	push	dx
	push	si
	mov	al,'H'			; esc terminator  (require for dec2bin)
	mov	si,offset tcb$eb
	call	dec2bin 		; get row number in al
	jnc	escpos1
	jmp	errcpos
escpos1:
	or	al,al			; 0 is the same as 1
	jz	escpos2
	dec	al
escpos2:
	mov	dh,al
semiskp:
	cmp	byte ptr [si],';'	; check for ';'
	jne	getcol
	inc	si			; skip ';'
	jmp	semiskp
getcol:
	mov	al,'H'			; esc terminator
	call	dec2bin 		; get col num
	jnc	escpos3
	jmp	errcpos
escpos3:
	or	al,al			; 0 is the same as 1
	jz	escpos4
	dec	al
escpos4:
	mov	dl,al
	mov	bh,[tcbpage]
	mov	ah,2
	mos10
	pop	si
	pop	dx
	pop	cx
	pop	bx
seqexit:
	push	dx
	mov	dx,offset tcb$eb
	mov	[tcb$ebp],dx		; reset buffer pointer
	pop	dx
	ret
errcpos:
	pop	si
	pop	dx
	pop	cx
	pop	bx
	jmp	seqexit
escpos	endp

	subttl escup - process cursor up
	page
;======================================================================
;,fs
; escup - process cursor up
; 
; on entry tcb$eb holds characters between '[' and terminating char
;
; in:
; 
; out: 
; 
;,fe
;======================================================================
	assume	ds:tcb,es:nothing,ss:tcb
escup	proc	near
	push	bx
	push	cx			; set in fun 3 of int 10h
	push	dx
	push	si
	getcrs0
	mov	si,offset tcb$eb
	mov	al,'A'			; esc terminator
	call	dec2bin 		; get row number in al
	jc	errcup
	sub	dh,al
	jnc	docup
	xor	dh,dh
docup:
	mov	ah,2
	mov	bh,[tcbpage]
	mos10
errcup:
	pop	si
	pop	dx
	pop	cx
	pop	bx
	jmp	seqexit
escup	endp

	subttl escdn - process cursor down
	page
;======================================================================
;,fs
; escdn - process cursor down
; 
; on entry tcb$eb holds characters between '[' and terminating char
;
; in:
; 
; out: 
; 
;,fe
;======================================================================
	assume	ds:tcb,es:nothing,ss:tcb
escdn	proc	near
	push	bx
	push	cx			; set in fun 3 of int 10h
	push	dx
	push	si
	getcrs0
	mov	si,offset tcb$eb
	mov	al,'B'			; esc terminator
	call	dec2bin 		; get row number in al
	jc	errcdn
	add	dh,al
	cmp	dh,[tcbrows]		; going off screen?
	jb	docdn			; no
	mov	dh,[tcbrows]		; set to last line
	dec	dh
docdn:
	mov	ah,2
	mov	bh,[tcbpage]
	mos10
errcdn:
	pop	si
	pop	dx
	pop	cx
	pop	bx
	jmp	seqexit
escdn	endp

	subttl escfwd - process cursor forward
	page
;======================================================================
;,fs
; escfwd - process cursor forward
; 
; on entry tcb$eb holds characters between '[' and terminating char
;
; in:
; 
; out: 
; 
;,fe
;======================================================================
	assume	ds:tcb,es:nothing,ss:tcb
escfwd	proc	near
	push	bx
	push	cx			; set in fun 3 of int 10h
	push	dx
	push	si
	getcrs0
	mov	si,offset tcb$eb
	mov	al,'C'			; esc terminator
	call	dec2bin 		; get row number in al
	jc	errcfwd
	add	dl,al
	cmp	dl,79
	jbe	docfwd
	mov	dl,79
docfwd:
	mov	ah,2
	mov	bh,[tcbpage]
	mos10
errcfwd:
	pop	si
	pop	dx
	pop	cx
	pop	bx
	jmp	seqexit
escfwd	endp

	subttl escbak - process cursor back
	page
;======================================================================
;,fs
; escbak - process cursor back
; 
; on entry tcb$eb holds characters between '[' and terminating char
;
; in:
; 
; out: 
; 
;,fe
;======================================================================
	assume	ds:tcb,es:nothing,ss:tcb
escbak	proc	near
	push	bx
	push	cx			; set in fun 3 of int 10h
	push	dx
	push	si
	getcrs0
	mov	si,offset tcb$eb
	mov	al,'D'			; esc terminator
	call	dec2bin 		; get row number in al
	jc	errcbak
	sub	dl,al
	jnc	docbak
	xor	dl,dl
docbak:
	mov	ah,2
	mov	bh,[tcbpage]
	mos10
errcbak:
	pop	si
	pop	dx
	pop	cx
	pop	bx
	jmp	seqexit
escbak	endp

	subttl eschvp - process horizontal and vertical position
	page
;======================================================================
;,fs
; eschvp - process horizontal and vertical position
; 
; on entry tcb$eb holds characters between '[' and terminating char
;
; in:
; 
; out: 
; 
;,fe
;======================================================================
	assume	ds:tcb,es:nothing,ss:tcb
eschvp	proc	near
	push	di
	mov	di,[tcb$ebp]
	mov	byte ptr [di-1],'H'
	pop	di
	jmp	escpos			; this does the same thing
eschvp	endp

	subttl esstat - process device status report
	page
;======================================================================
;,fs
; esstat - process device status report
; 
; on entry tcb$eb holds characters between '[' and terminating char
;
; in:
; 
; out: 
; 
;,fe
;======================================================================
	assume	ds:tcb,es:nothing,ss:tcb
esstat	proc	near
	push	cx
	mov	cx,011bh		; send an esc
	call	setbyte
	mov	cl,'['			; send a bracket
	mov	ch,1ah			; scan code for bracket
	call	setbyte
	getcrs0
	mov	al,dh
	inc	al
	call	covdec			; convert row into decimal
	mov	cl,ah
	call	makescan		; send upper byte to keyboard
	mov	cl,al
	call	makescan		; send lower byte to keyboard
	mov	cl,';'			; send a semi-colon
	mov	ch,27h			; scan code for semi-colon
	call	setbyte
	mov	al,dl
	inc	al
	call	covdec			; convert column to keyboard
	mov	cl,ah
	call	makescan		; send upper byte to keyboard
	mov	cl,al
	call	makescan		; send lower byte to keyboard
	mov	cl,'R'			; send a 'R'
	mov	ch,13h			; scan code for 'R'
	call	setbyte
	mov	cx,1c0dh		; send a carriage return
	call	setbyte
	pop	cx
	jmp	seqexit

makescan:
	mov	ch,0bh			; make scan code for '0' - '9'
	cmp	cl,'0'
	je	setbyte
	mov	ch,cl
	sub	ch,2fh
setbyte:				; place byte in keyboard
	push	ax
	push	dx
	push	ds
	mgetzero ds
	mov	ah,5
	pushf
	call	dword ptr ds:[16h*4]
	pop	ds
	pop	dx
	pop	ax
	ret
covdec: 				; convert al in decimal digit in ax
	xor	ah,ah
covdec1:
	cmp	al,0ah
	jb	covdec2
	sub	al,0ah
	inc	ah
	jmp	short covdec1
covdec2:
	add	ax,3030h
	ret
esstat	endp

	subttl escsav - process save cursor position
	page
;======================================================================
;,fs
; escsav - process save cursor position
; 
; on entry tcb$eb holds characters between '[' and terminating char
;
; in:
; 
; out: 
; 
;,fe
;======================================================================
	assume	ds:tcb,es:nothing,ss:tcb
escsav	proc	near
	push	bx
	push	cx
	push	dx
	getcrs0
	mov	[tcb$tcp],dx		; save cursor position for later recall
	pop	dx
	pop	cx
	pop	bx
	jmp	seqexit
escsav	endp

	subttl escrst - process restore cursor position
	page
;======================================================================
;,fs
; escrst - process restore cursor position
; 
; on entry tcb$eb holds characters between '[' and terminating char
;
; in:
; 
; out: 
; 
;,fe
;======================================================================
	assume	ds:tcb,es:nothing,ss:tcb
escrst	proc	near
	push	bx
	push	dx
	mov	ah,2
	mov	bh,[tcbpage]
	mov	dx,[tcb$tcp]		; get saved position
	mos10
	pop	dx
	pop	bx
	jmp	seqexit
escrst	endp

	subttl escls - process erase in display
	page
;======================================================================
;,fs
; escls - process erase in display
; 
; on entry tcb$eb holds characters between '[' and terminating char
;
; in:
; 
; out: 
; 
;,fe
;======================================================================
	assume	ds:tcb,es:nothing,ss:tcb
escls	proc	near
	push	bx
	push	cx
	push	si			; sah
	mov	si,offset [tcb$eb]	; sah 06/21/88
	mov	ax,0600h		; do a 'CLS'
	mov	bh,[tcb$ca]		; use current attribute to blank lines
	xor	cx,cx
	cmp	byte ptr [si],'0'	; sah test for esc [0j
	jne	escls1			; sah
	mov	cx,[tcbcpos]		; sah get current cursor pos
	mov	dx,cx
	mov	dl,4fh
	push	ax
	push	bx
	push	cx
	push	dx
	mos10				; clear to end of line
	pop	dx
	pop	cx
	pop	bx
	pop	ax
	inc	ch
	cmp	ch,[tcbcols]		; last column
	jae	escls2			; don't clear the window below
	xor	cl,cl			; clear row
escls1: 				; sah
	mov	dl,04fh
	mov	dh,[tcbrows]
	dec	dh
	mos10
	cmp	byte ptr [si],'0'	; sah	don't home cursor
	je	escls2			; sah
	mov	bh,[tcbpage]
	mov	ah,2			; home cursor
	xor	dx,dx
	mos10
escls2: 				; sah
	pop	si			; sah
	pop	cx
	pop	bx
	jmp	seqexit
escls	endp

	subttl eseol - process erase in line
	page
;======================================================================
;,fs
; eseol - process erase in line
; 
; on entry tcb$eb holds characters between '[' and terminating char
;
; in:
; 
; out: 
; 
;,fe
;======================================================================
	assume	ds:tcb,es:nothing,ss:tcb
eseol	proc	near
	push	bx
	push	cx
	push	dx
	getcrs0
	mov	al,[tcbcols]
	sub	al,dl			; calc # chars to end of line
	mov	cl,al
	xor	ch,ch			; cx = number of spaces to write
	mov	ah,9			; write char/attr
	mov	bh,[tcbpage]
	mov	al,' '			; write spaces
	mov	bl,[tcb$ca]		; write char with active attribute
	mos10
	pop	dx
	pop	cx
	pop	bx
	jmp	seqexit
eseol	endp

	subttl essgr - process set graphics rendition
	page
;======================================================================
;,fs
; essgr - process set graphics rendition
; 
; on entry tcb$eb holds characters between '[' and terminating char
;
; in:
; 
; out: 
; 
;,fe
;======================================================================
	assume	ds:tcb,es:nothing,ss:tcb
essgr	proc	near
	push	bx
	push	cx
	push	dx
	push	si

	mov	si,offset tcb$eb
attrlp:
	mov	al,'m'			; esc terminator
	call	dec2bin 		; get next attr
	jnc	attrsk
	jmp	errsgr
attrsk:
	call	setattr 		; process attribute
	jnc	semskp
	jmp	errsgr			; invalid selection
semskp:
	cmp	byte ptr [si],';'	; check for ';'
	jne	getnxt
	inc	si			; skip ';'
	jmp	semskp
getnxt:
	cmp	byte ptr [si],'m'	; esc terminator?
	jne	attrlp			; process as many as specified
errsgr:
	pop	si
	pop	dx
	pop	cx
	pop	bx
	jmp	seqexit

;-----------------------------------------------------------------------
; set 'tcb$ca' according to ansi sgr value passed in al
;-----------------------------------------------------------------------
;fg	30     31     32     33     34	   35	  36	 37
;fg	black  red    green  yellow blue   magta  cyan	 white

attvals db	0,0f8h,4,0f8h,2,0f8h,6,0f8h,1,0f8h,5,0f8h,3,0f8h,7,0f8h

;bg	40     41      42      43      44      45      46      47
;bg	black  red     green   yellow  blue    magta   cyan    white

	db	00,8fh,40h,8fh,20h,8fh,60h,8fh,10h,8fh,50h,8fh,30h,8fh,70h,8fh

	subttl setattr - 
	page
;======================================================================
;,fs
; setattr - 
; 
; in:
; 
; out: 
; 
;,fe
;======================================================================
	assume	ds:tcb,es:nothing,ss:tcb
setattr proc	near
	cmp	al,0			; normal?
	jne	attr1
	clc
attr0:
	mov	[tcb$ca],7		; set normal
	ret
attr1:
	cmp	al,1			; bold?
	jne	attr2
	or	[tcb$ca],8		; set high intensity bit
	clc
	ret
attr2:
	cmp	al,4			; underscore?
	jne	attr3
	and	[tcb$ca],0f8h		; clear low 3 bits
	or	[tcb$ca],01		; set low bit
	clc
	ret
attr3:
	cmp	al,5			; blink?
	jne	attr4
	or	[tcb$ca],80h		; set blink bit
	clc
	ret
attr4:
	cmp	al,7			; reverse?
	jne	attr5
	and	[tcb$ca],88h
	or	[tcb$ca],70h		; set to inverse
	clc
	ret
attr5:
	cmp	al,8			; invisible?
	jne	attr6
	mov	[tcb$ca],0
	clc
	ret
attr6:
	cmp	al,30			; validate range
	jb	attinvl 		; invalid
	cmp	al,37
	jb	attrok
	cmp	al,40
	jb	attinvl
	cmp	al,47
	ja	attinvl
	sub	al,2			; 38 and 39 invalid
attrok:
	sub	al,30			; calc offset into table
	xor	ah,ah
	push	bx
	mov	bx,ax			; calc offset into table
	shl	bx,1			; word entries
	mov	ax,word ptr [attvals+bx]; get mask and setting
	pop	bx
	and	[tcb$ca],ah		; clear nibble for attr
	or	[tcb$ca],al		; set attr
	clc
	ret
attinvl:
	stc
	jmp	short attr0

setattr endp

essgr	endp

	subttl essm - process set mode
	page
;======================================================================
;,fs
; essm - process set mode
; 
; on entry tcb$eb holds characters between '[' and terminating char
;
; in:
; 
; out: 
; 
;,fe
;======================================================================
	assume	ds:tcb,es:nothing,ss:tcb
essm	proc	near
	push	si
	mov	si,offset tcb$eb	; access buffer
	cld
	lodsb
	cmp	al,'?'			; check for ? of ?7
	jne	essm1			; no..skip
	lodsb
	cmp	al,'7'			; check for 7 of ?7
	jne	essm1			; no..skip
	mov	[tcb$wrap],'Y'		; set eol wrap mode
essm1:
	pop	si
	jmp	seqexit
essm	endp

	subttl esrm - process reset mode
	page
;======================================================================
;,fs
; esrm - process reset mode
; 
; on entry tcb$eb holds characters between '[' and terminating char
;
; in:
; 
; out: 
; 
;,fe
;======================================================================
	assume	ds:tcb,es:nothing,ss:tcb
esrm	proc	near
	push	si
	mov	si,offset tcb$eb	; access buffer
	cld
	lodsb
	cmp	al,'?'			; check for ? of ?7
	jne	esrm1			; no..skip
	lodsb
	cmp	al,'7'			; check for 7 of ?7
	jne	esrm1			; no..skip
	mov	[tcb$wrap],'N'		; reset eol wrap mode
esrm1:
	pop	si
	jmp	seqexit

esrm	endp

	subttl eskeyr - process keyboard reassignment
	page
;======================================================================
;,fs
; eskeyr - process keyboard reassignment
; 
; on entry tcb$eb holds characters between '[' and terminating char
;
; in:
; 
; out: 
; 
;,fe
;======================================================================
	assume	ds:tcb,es:nothing,ss:tcb
	public	eskeyr
eskeyr	proc	near
	push	bp
	push	di
	push	es

; first we must find end of list

	cld
	mov	es,[tcbkbansi]

; now we need to gather information from esc command line

	mov	al,'p'			; esc terminator
	mov	si,offset tcb$eb
	call	dec2bin 		; get first key value
	jnc	eskr1
	jmp	outky
eskr1:
	mov	[tcbkbanhi],0ffh	; indicate 0ffh for single value
	or	al,al			; if non-zero than value must
	jnz	eskr2			; single keyboard translation
	mov	[tcbkbanhi],al
eskrs1:
	cmp	byte ptr [si],';'	; check for ';'
	jne	eskrs2
	inc	si			; skip ';'
	jmp	short eskrs1
eskrs2:
	call	dec2bin 		; get second key value
	jnc	eskr2
	jmp	outky
eskr2:
	mov	[tcbkbanlow],al
	push	bx
	mov	bh,al			; note low is store above
	mov	bl,[tcbkbanhi]		; get high value
	call	findkeyr		; is keystroke store already
	pop	bx
	jnc	eskrct

; we have found key store in buffer, remove sequence from buffer

	push	si
	mov	si,di
	add	si,2			; point past keyboard values
eskrs0:
	cmp	byte ptr es:[si],0	; search for 0 past list
	je	eskrf0
	inc	si
	jmp	short eskrs0
eskrf0:
	inc	si

; now for every non-zero word at es:si, copy to es:di

eskrrlp:
	mov	ax,word ptr es:[si]
	mov	word ptr es:[di],ax
	cmp	ax,-1			; end of replacement
	je	eskrcout
	add	si,2
	add	di,2
	cmp	si,63
	jbe	eskrrlp
eskrcout:
	mov	word ptr es:[di+2],-1	; fore a termination at end
	pop	si
eskrct:
	call	findendr		; refind end of keyboard re-assignment list
	mov	bp,di			; save end just in case of error
	cmp	di,62			; check for boandary errors
	ja	errky			; overboard...don't kill the smp
	mov	al,[tcbkbanlow] 	; get low value
	stosb
	mov	al,[tcbkbanhi]		; get high value
	stosb

; at this point we will need to process the key statements
; as "string" or dec ascii numbers, seperated by ; and terminate with 'p'

eskrloop:
	lodsb
	cmp	al,';'			; seperator...ignore
	je	eskrloop
	cmp	al,'p'			; have we reach the terminator
	je	contky
	cmp	al,'"'			; is this quate
	je	eskrstr
	dec	si			; account for the lodsb above
	call	dec2bin 		; must be decimal
	jc	errky
	cmp	di,63			; over the limit
	jae	errky
	stosb				; store value in
	jmp	short eskrloop
eskrstr:
	lodsb
	cmp	al,'"'			; end string terminator
	je		eskrloop	; yes...then back to main loop
	cmp	di,63			; over the limit
	jae	errky
	stosb				; store value in table
	jmp	short eskrstr		; loop back for next value in string
errky:
	mov	di,bp			; error....so mark start as clear position
	jmp	short outky2
contky:
	cmp	di,61			; make sure that we can't overlap into
	jae	errky			; next smp block
	xor	al,al
	stosb
outky2:
	mov	ax,-1
	stosw				; clear so next search will place here
outky:
	pop	es
	pop	di
	pop	bp
	jmp	seqexit

eskeyr	endp

	subttl findkeyr - search for key in list
	page
;======================================================================
;,fs
; findkeyr - search for key in list
; 
; the following procedure is use to search for key sequece in the keyboard
; re-assigment list (key to search for is in tcbkbanlow and tcbkbanhi
;
; in:
; 
; out: 
; 
;,fe
;======================================================================
	assume	ds:tcb,es:nothing,ss:tcb
findkeyr proc	near
	xor	di,di
fkeyloop:
	cmp	word ptr es:[di],-1	; key-assigment stored
	je	fkeyerr
	cmp	byte ptr es:[di],bh
	jne	fkeynext
	cmp	byte ptr es:[di+1],bl
	jne	fkeynext
	stc				; we have found, return position
	ret
fkeynext:
	add	di,2			; point past keys
fkeynloop:
	cmp	byte ptr es:[di],0	; key-assigment terminate found
	je	fkeynend
	inc	di
	jmp	short fkeynloop 	; continue scanning for terminator
fkeynend:
	inc	di
	jmp	short fkeyloop		; go and search next string
fkeyerr:
	clc
	ret
findkeyr endp

	subttl findendr - find end of keyboard list
	page
;======================================================================
;,fs
; findendr - find end of keyboard list
; 
; in:
; 
; out: 
; 
;,fe
;======================================================================
	assume	ds:tcb,es:nothing,ss:tcb
findendr proc	near
	xor	di,di
fendloop:
	cmp	word ptr es:[di],-1	; find end of list
	je	fendend
	inc	di
	jmp	short fendloop
fendend:
	 ret
findendr endp

endres	label	byte

	subttl call16 - issue the int16 call, adjusting for kybd type
	page
;======================================================================
;,fs
; call16 - issue the int16 call, adjusting for kybd type
; 
; in:
; 
; out: 
; 
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:nothing
call16 proc near
	push	bx
	push	es
	mgetzero es
	mov	bl,byte ptr es:[496h]
	and	bl,10h
	or	ah,bl
	pop	es
	pop	bx
	int	16h
	ret
call16 endp

	subttl dinit - init driver
	page
;======================================================================
;,fs
; dinit - init driver
; 
; in:
; 
; out: 
; 
;,fe
;======================================================================
	assume	ds:mos,es:nothing,ss:tcb
dinit	proc	near
	mov	bx,[tcb$hdr]		; get request header pointer
	mov	dx,offset endres
	mov	es:[bx+14],dx		; set ending address of driver
	mov	es:[bx+16],cs
	mov	word ptr es:[bx+3],100h ; return with 'DONE'
	ret				; end of init
dinit	endp

mosseg	ends
	end

