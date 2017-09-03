	include page.inc
	title	mosint28 - int 28 and indos routines (tsr support)
comment ^===============================================================
		    development specification

 program name:	$$mos.com		 assigned to: stewart hyde
 module name:	mosint28		 assign date: 10/05/88
 entry points:	mosint28		 completed:   10/05/88
 entry from:	mosddcon for int 28 and approptiate inmos locations
 entry method:	call
 purpose:	provides pc-mos/386 tsr usage routines
 refer to:
 last update:	08/18/1992
========================================================================

this module is intended to be mos source which provides support for
tsr usaged under pc-mos/386.	the following is a brief discription
of the current understanding of how dos handlers tsr's

the int 28 handler is call when system is waiting for input, this
indicates that the os is not busy. also under my current under-
standing of int 28 handling, int 28 will only be issue for during
input calls of functions <= function 0ch.  this is becuase dos uses a
different stack on lower level functions.

the following is sample code for which most int 28 handlers would
look like:

int28:
	pushf
	call	dword ptr cs:[old28]

; handler application's INT 28 handling.

	iret

indos flag is use to indicated that os is busy or not.  the indos
flag is increment when inside the os and when os exits back to
application the indos flag is then decrement.  this flag can be
access by function 34.

the following are procedures for handling of mos int 28 handling.
int 28 should only be call from console input routine when mos is
waiting for a key. this is currently place in mosddcon routine before
int 16h function 00, there is a test for an application int 28
handler if there is one, loop of safe28 (our method of calling the
application int 28 handler follow by int 16 function 1 looping if no
key was press

also inside our int 28 handler, which by word of the trade the
application should call original int 28 handler inside their int 28
handler, is special efficency handling of int 28 so that tsr or
others (i.e. windows and norvell).

when applications int 28 handler is called, we need to be prepare for
the tsr application to reenter mos.

procedures define for int 28 handling are:
mosint28	-	our int 28 routine
testmos28	-	test to see if mosint28 handler is
			int 28 handler for task
do28		-	issue the int 28 call
safe28		-	determine if it is safe to call int 28
			if so, call int 28

tcbsafe28 - indicates if int 28 call should be made, ie for function
<= 0c.

tcbtsrflg - indicates if efficiency waiting inside mosint28 should be
done.

tcb28timer - is a counter of int 28 issue before int 28 application
should be suspended.

tcb28cnt - this is a nesting counter for handling of inmos flag.

tcbmtimer - this is a timer which is use to improve the efficency of
applications which intercept int 28 and use generic mouse interface.
it indicate time sence has mouse activity.

tcbmport - this is the port which generic mouse interface uses.

=======================================================================

sah 10/13/88	if scbcrit is non-zero (i.e inside critical error) don't
		issue int 28

sah 01/26/89	added necessary efficiencys to mosint28 when apps that
		intercept int 28 and use new generic mouse interface
		($mouse.sys) are installed on system.

mjs 04/06/89	modified mosfun34 to not clear ax upon return.
		quickbasic's printer error handler was counting on the
		exit ah being the same as the entry ah.

sah 05/01/89	corrected mosint28 for conditions where mouse driver is
		not installed and int 28 is issue (ie novell, in this
		case) this was cause invalid serial ports to be polled
		and was corrected by not polling serial ports unless
		mouse driver is being used.

sah 06/15/89	remove call to userpoll, which is not need since
		mossaver call will perform a userpoll.

sah 06/22/89	improve mice efficency and coded for new mouse buffers

================ 5.01 Kernel Ends Here ====================================

mjs 08/18/92	clean up segment declarations

======================================================================^

.xlist
;	include mosint28.pub
	include group.inc
	include options.inc
	include mosregs.inc
	include macros.inc

tcb	segment at 1234h
	include mostcb.inc
tcb	ends

gdata	segment
	include mosscbex.inc
gdata	ends
.list

gdata	segment
	extrn	intsl:byte,irqwflag:byte
gdata	ends

irq	segment
	extrn	irqstart:byte, irqend:byte

	dw	28h*4			; offset for this interupt
public	i28old
i28old	dd	?			; save prior value
	dw	0			; we don't save changes, we leave them alone
	dw	mos:mosint28		; initial value here
	dw	0			; don't change back if application changes it

irq	ends

;======================================================== mos segment
if 0 eq 0
segment_num = 1
endif
mosseg	segment
	assume	cs:mos,ds:grp,es:nothing,ss:tcb
	public	$$$mos28
$$$mos28 label	byte

	extrn	mosend:byte, sbios:word
	extrn	suspend:near, tsl:near, switchif:near
	extrn	egaon:near, egaoff:near, regrab9_data:near
	extrn	getkeys:near, regrab8_data:byte, grab_back:near
	extrn	mossaver:near, mosrestore:near
	extrn	mosint38:near

	public	decinmos, incinmos, rstinmos, mosint28, testmos28
	public	mosfun34

	subttl mosint28 - default int 28 handler
	page
;======================================================================
;,fs
; mosint28 - default int 28 handler
;
; in:	
;
; out:	
;
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:nothing
mosint28:
	call	mossaver
	assume	ds:grp,ss:tcb
	cmp	byte ptr [tcbtsrflg],'Y'; has tsr flag been set
	je	mint28c 		; yes skip wait
	inc	byte ptr [tcb28timer]	; increment efficiency
	cmp	byte ptr [tcb28timer],3 ; if lest than 3 call
	jb	mint28c 		; skip wait
	mov	word ptr [tcb28timer],0 ; reset efficiency

; the following is code which is include to improved the
; efficiency of ms-windows (and novell, tsr's) when mouse
; support has been include.

	mov	al,03h			; set for keys and time
	cmp	byte ptr [tcbmouse],'Y' ; generic mouse installed
	jne	mint28b
	mov	ax,[scbtimer]
	sub	ax,[tcbmtimer]
	cmp	ax,18*3 		; check time lapse since
	jbe	mint28c 		; last mouse activity
	push	es
	les	bx,[tcbmready]
	cmp	byte ptr es:[bx],0	; any characters in serial.sys
	pop	es
	jne	mint28c 		; yes...dont suspend
	push	es
	les	bx,[tcbmcount]
	cmp	byte ptr es:[bx],0	; any characters in mouse buffer
	pop	es
	jne	mint28c 		; yes...don't supend
mint28a:
	mov	dx,[tcbmport]		; set port
	mov	dh,1			; set for 1 port to wait
	mov	al,0bh			; ser for keys, com, and time
mint28b:

; now that we desided to wait to improve overall efficiency of system
; we can wake under following 3 conditions while suspended
;     1. if user presses the keyboard
;     2. if we get any mouse actively (only if mouse is installed)
;     3. if 6 cycles expired.

	mov	ah,07h
	mov	bx,6			; set for 6 cycles
	pushf
	push	cs
	call	mosint38		; wait for 6 ticks or key
mint28c:
	call	mosrestore
	iret

	subttl testmos28 - test for mos's int 28 handler
	page
;======================================================================
;,fs
; testmos28 - test for mos's int 28 handler
;
; in:	
;
; out:	return z if mos's int 28 handler
;
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:nothing
testmos28 proc	near
	push	ax
	push	bx
	push	ds
	mgetzero ds
	mov	bx,28h*4
	mov	ax,cs
	cmp	ax,word ptr [bx+2]
	jne	t28out
	lea	ax,mosint28
	cmp	ax,word ptr [bx]
t28out:
	pop	ds
	pop	bx
	pop	ax
	ret
testmos28 endp

	subttl safe28 - set up for and issue an int28
	page
;======================================================================
;,fs
; safe28 - set up for and issue an int28
;
; note: don't do INT 28 if tcbsafe28 is not set to 'y'
;
; in:	
;
; out:	
;
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:nothing
public	safe28
safe28	proc near
	push	ax
	push	ds
	mgetscb ds
	assume	ds:grp
	push	es
	mov	es,[scbtcbpc]
	assume	es:tcb
	cmp	[tcbsafe28],'Y'
	jne	x28c
	cmp	[scbcrit],0		; if inside int 24 handler don't
	je	x28a			; do the int 28 call.
	pushf
	push	cs			; call mosint28 handler so that
	call	mosint28		; task switching can be occur
	jmp	short x28c		; while we are in a critical error
x28a:
	inc	[tcb28cnt]		; increment 28 staging
	mov	ax,ss
	cmp	ax,[scbtcbpc]
	je	x28b
	call	do28
	jmp	x28c
x28b:
	assume	ss:tcb
	cli
	push	[tcbstkp]
	mov	[tcbstkp],sp
	sub	[tcbstkp],256
	sti
	call	do28
	pop	[tcbstkp]
x28c:
	pop	es			;sah
	pop	ds
	pop	ax
	ret
safe28	endp

	page
	subttl do28 - issue int 28 call
;======================================================================
;,fs
; do28 - issue int28 call
;
; in:	
;
; out:	
;
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:nothing
do28 proc near
	push	ax
	push	bx			; never know what those tsr's will do
	push	cx
	push	dx
	push	si
	push	di
	push	bp
	push	ds
	push	es
	mgetscb es			; point to scb seg
	assume	es:grp
	push	word ptr [scbinmos]	; make sure you push scbinmos
	mov	al,[scbnoswt]
	push	ax
	mov	[scbnoswt],0
	int	28h
	pop	ax
	mov	[scbnoswt],al
	pop	word ptr [scbinmos]	; and restore the value
	mov	es,[scbtcbpc]
	assume	es:tcb
	mov	[tcbsafe28],'Y'
	dec	[tcb28cnt]		; decrement counter
	pop	es
	pop	ds
	pop	bp
	pop	di
	pop	si
	pop	dx
	pop	cx
	pop	bx
	pop	ax
	ret
do28 endp

	subttl mosfun34 - get pointer to indos flag
	page
;======================================================================
;,fs
; mosfun34 - get pointer to indos flag
;
; this return a pointer to mos equivilent to dos's InDOS flag which
; indicated that mos is busy or not for a tsr or application which uses
; indos flag can re-enter mos or not.
;
; in:	
;
; out:	tes:tbx -> scbinmos
;
;,fe
;======================================================================
	assume	ds:grp,es:nothing,ss:tcb
mosfun34 proc	near
	mgetscb es			; scb segment address
	lea	bx,[scbinmos]		; sah our inmos flag
	mov	[tes],es
	mov	[tbx],bx
	ret
mosfun34 endp

	subttl decinmos - if inmos is non-zero, decrement it
	page
;======================================================================
;,fs
; decinmos - if inmos is non-zero, decrement it
;
; in:	
;
; out:	
;
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:nothing
decinmos proc	near
	push	ds
	mgetscb ds
	assume	ds:grp
	call	testinmos		; test to make sure not internal call
	ja	dimskip
	cmp	byte ptr [scbinmos],0	; just for safety
	je	dimskip
	dec	byte ptr [scbinmos]
dimskip:
	pop	ds
	ret
decinmos endp

	subttl incinmos - increment inmos
	page
;======================================================================
;,fs
; incinmos - increment inmos
;
; in:	
;
; out:	
;
;,fe
;======================================================================
	assume ds:nothing,es:nothing,ss:nothing
incinmos proc	near
	push	ds
	mgetscb ds
	assume	ds:grp
	call	testinmos		; test to make sure not internal call
	ja	iim
	inc	byte ptr [scbinmos]
iim:
	pop	ds
	ret
incinmos endp

	subttl rstinmos - resets inmos to initial state (currently 0)
	page
;======================================================================
;,fs
; rstinmos - resets inmos to initial state (currently 0)
;
; in:	
;
; out:	
;
;,fe
;======================================================================
	assume ds:nothing,es:nothing,ss:nothing
rstinmos proc	near
	push	ds
	mgetscb ds
	assume ds:grp
	mov	byte ptr [scbinmos],0
	pop	ds
	ret
rstinmos endp

	subttl testinmos - test to see if we can do inmos modification
	page
;======================================================================
;,fs
; testinmos - test to see if we can do inmos modification
;
; in:	
;
; out:	
;
;,fe
;======================================================================
	assume	ds:grp
testinmos proc	near
	push	ax
	push	ds
	mov	ds,[scbtcbpc]
	assume	ds:tcb
	mov	ax,[tcb28cnt]		; this is number of int 28's nest
	cmp	[tcbnest],al		; this is int 21 nested
	pop	ds
	pop	ax
	ret
testinmos endp

mosseg	ends
	end

