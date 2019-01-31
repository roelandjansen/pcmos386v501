	include page.inc
	title	spool - spool data area and pop up window
	subttl	spool development specification
comment ^===============================================================
 spool.asm  =>	spool.com
 creates the spool data buffer used by int 17 to channel printer
 output to a file.  if spool segment already exits, modifies
 the spool parameters.	a tsr routine remains for popup changes
 to the spool parameters.
=======================================================================
02/23/87 sah	added /t command to close spooler

07/12/87 sah	converted 80+ to interupt 38h 00+ calls

07/21/87 jsm	fixed divide overflow problem in binary -> ascii
		conversion of task id in spooler file name, and
		set new spooler timeout value in resident code
		if not installing as resident (second+ time)

11/23/87 sah	change version # to 2.00

07/22/87 rdg	ptr 0067 - rewrote speccmd to accept up to 4
		digits for the spool file close timeout.  the
		max we can delay is 3600 seconds, or ffffh
		timer ticks.

09/15/88 rkg	ptr 0129 - overwrites spool files when in
		background.
		also validate paths and protect from aborts

12/15/88 rkg	correct timeout message from translations

0/06/89  mjs	correct oversight - the update procedure was ignoring
		changes made from the /n parameter.  clean up source code.

11/30/89 bwr	marked messages for foreign language translations.

03/13/90 sah	added spool off option to disable spooler

04/18/90 bwr	corrected problem with extended keyboard support.  spool.com
		now allows nearly any combination of keys to be assigned
		as the window "hot-key".  the hot-key handling routines
		have been simplified, eliminating access to both the scb
		and	the bios data areas.

05/01/90 bwr	security option (specified /s or /s_) caused system crash.
		this because security-set routine jumped to section and
		popped es register that was not pushed.  stack corruption
		resulted.  also corrected problem with spooler screwing
		up the hotkey whenever invoked a second time to change
		some other parameter.  (the spooler window was no longer
		accessible in that case.)  finally, also corrected a
		segment addressing error in the reset routine which was
		placing the default_hotkey into the wrong segment.  (bad
		use of assume).


11/02/90 bwr	corrected problem i created by changing the way the hotkey
		was being read from the keyboard. the manual states that
		the hotkey sequence as displayed in the on-screen window
		can be entered on the /k command-line option.  the change
		made did not account for this and has been corrected.  the
		user may now enter this code (which is now a hex code)
		on the /k parameter.

		also corrected a small problem with the error message
		displayed when a bad option was entered on the command
		line.  the bx register was being loaded with the message
		offset instead of dx, causing garbage to be displayed
		on the screen instead of the required error message.
		definitely inelegant.

		corrected a precision error in the routine that handles
		the interpretation of the /t (timeout) argument.  if the
		user entered /t18, the timeout displayed was 17 seconds.

		spool now enforces the timeout range of 1 to
		3600 seconds by issuing the appropriate error message
		and	aborting if the argument is out of range.

		corrected problem with command line handling.  if spaces
		entered after spool without any other parameters, the
		parse routine caused an invalid instruction error.  this
		was because parse was popping two values off the stack
		that he did not place there!

		spool program now displays a copyright banner on being
		invoked.

mjs 12/20/90	modified int16 intercept code to also watch int16fun10
		and	int16fun11.  programs compiled with basic 7.0 use
		these functions when a 101 key keyboard is detected.
		updated to v4.11 (901220).
		updated copyright notice to 1991

rsr 02/05/92	put logic in to check if in graphics mode and not pop up.
		updated version to 4.12 and copyright to 1992

mjs 04/10/92	cleaned up module.  corrected register crash by i10f0f
		call (made by rsr on 02/05/92).  modified read of new
		hot key to use i16f10 on extended keyboard.

========================================================================^

keyvect 	equ	16h		; vector used for hotkey monitor.
default_hotkey	equ	7700h		; ctrl-home / ascii zero.

include options.inc

; define segment templates for addressing memory.

tcb segment at	6666h
include mostcb.inc
tcb ends

cr		equ	0dh
esc_key 	equ	1bh
up		equ	4800h
pgup		equ	4900h
down		equ	5000h
pgdn		equ	5100h

code group tsr, spoolseg, init

tsr segment para
	assume cs:code
	org	80h

cmdline 	db	80h dup (?)	; command tail.

	org	100h
start label near
	jmp	begin

spoolseg segment  para
splsegbeg label byte
include moxspldt.inc
splsegend label byte
spoolseg ends

splbuff segment at 7000h		; spooldat defined above.
splb	spooldat <>
splbuff 	ends

spl16		db	'Y'		; int 16 intercept enabled.
keybvct 	dd	0		; original int 16 vector address.
keybax		dw	0		; user keyboard function.

winattr 	equ	1fh		; white on blue.
winrow		equ	3
wincol		equ	15
winrows 	equ	13
wincols 	equ	50

; buffer to save user's screen

scrnsave	dw	3+(winrows*wincols) dup(0)
window	dw	-1			; create a scrn rstrscrn can display
	db	wincol, winrow
	db	wincol+wincols, winrow+winrows
	db	'ÉÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ»'
	db	'º * * * *   S U P E R    S P O O L E R   * * * * º'  ;@@xlat
	db	'ÇÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¶'
	db	'º                                                º'
	db	'ÇÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¶'
	db	'º   [1] Current Spool Parameters    -            º'  ;@@xlat
	db	'º   [2] Spool file status           -            º'  ;@@xlat
	db	'º   [3] Spool file close time       -            º'  ;@@xlat
	db	'º   [4] Spooler popup Hotkey        -            º'  ;@@xlat
	db	'º   [5] Keyboard Polling mode       -            º'  ;@@xlat
	db	'ÇÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¶'
	db	'º                                                º'
	db	'ÈÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼'
	db	'                                                $'

msgfilelen	equ	29

msgfile   db	03,04
	  db	msgfilelen dup (' '),'$'
msglpt	  db	03,30,' LPT1 LPT2 LPT3$'
msglptclr db	03,34,'               $'
msgdpc	  db	05,42,'D2A$'
msgopen   db	06,38,'   OPEN    $'	;@@xlat
msgclose  db	06,38,'  CLOSED   $'	;@@xlat
msgtime   db	07,41,'   0$'
msghotkey db	08,41,'   0$'
msgkbenb  db	09,38,'   NoDis   $'	;@@xlat
msgkbdis  db	09,38,'    Dis    $'	;@@xlat
cmdclr	  db	11,01,'                                                $'
cmdqry	  db	11,02,'Enter 1-5, UP/DN for printer, <RETURN> exits $ '  ;@@xlat
dispqry   db	11,02,'Please enter new Disposition (D,S,H,I,N)  - $  '  ;@@xlat
prioqry   db	11,02,'  Please enter new Priority   ( 0 - 9 )   - $  '  ;@@xlat
clasqry   db	11,02,'  Please enter new Class      ( A - Z )   - $  '  ;@@xlat
timeqry   db	11,02,' Enter new Spooler close time          - $     '  ;@@xlat
htkyqry1  db	11,02,'Press the key you want for the new HotKey. $   '  ;@@xlat
htkyqry2  db	11,02,'Press the key AGAIN to verify your choice. $   '  ;@@xlat
htkyok	  db	11,02,'HotKey VERIFIED.  Any key to continue.     $   '  ;@@xlat
htkyerr   db	11,02,'HotKey NOT VERIFIED. Any key to continue.  $   '  ;@@xlat
msgclsd   db	11,02,' Spooler closed.  Press a key to continue. $   '  ;@@xlat
curprntr  dw	0			; current printer to update
tcbseg	  dw	0			; tcb segment
splseg	  dw	0			; spool header segment
ten	  dw	10			; for decimal <=> binary
one82	  dw	182			; 18.2 ticks / second

	subttl keybint - int 16 keyboard interrupt monitor for popup
	page
;======================================================================
;,fs
; keybint - int 16 keyboard interrupt monitor for popup
; 
; int 16 keyboard interrupt monitor for popup
; this routine is the intercept routine for the bios keyboard interrupt
; (16h).  it will simply check keys coming from the keyboard for the hotkey
; and if found will display a menu and allow the user to select spooler
; parameters.
;
; in:	
; 
; out:	
; 
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:nothing
keybint proc far
	cmp	[spl16],'Y'		; is int 16 intercept enabled?
	jne	skip16
	cmp	ah,1			; get key or get status?
	jb	kybiget 		; keyboard read
	je	kybistat
	cmp	ah,11h
	je	kybistat
	cmp	ah,10h
	je	kybiget
skip16:
	jmp	[keybvct]		; continue with regular kb routine

; int 16 func 1/11 - keyboard status

kybistat:
	mov	[keybax],ax		; save function for correct scarf
	pushf				; simulate int
	call	[keybvct]		; call regular kb routine
	jz	kybiret 		; no key available
	call	kybitst 		; our hotkey?
	jz	kybistat
kybiret:
	retf	2			; return correct zr popping old flags

; int 16 func 0/10 - keyboard get key

kybiget:
	mov	[keybax],ax		; save function for correct reread
	pushf
	call	[keybvct]		; call regular kb routine
	call	kybitst 		; hotkey?
	jz	kybiget 		; yes and scarfed - get next
	iret				; return with key
keybint endp

	subttl kybitst - test the key in ax is our hotkey
	page
;======================================================================
;,fs
; kybitst - test the key in ax is our hotkey
; 
; in:	ax = scan code, key code from int 16 call
; 
; out:	nz if not hotkey
;	zr if our hotkey was processed (ax restored to [keybax])
; 
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:nothing
kybitst proc near
	push	ax
	cmp	al,0e0h
	jne	kbixe0
	xor	al,al
kbixe0:
	cmp	ax,[hotkey]
	pop	ax
	je	kybigot
	ret				; hotkey not found.
kybigot:
	push	ax
	push	bx
	mov	ah,0fh
	int	10h
	pop	bx
	cmp	al,4
	jb	kybigot1
	cmp	al,7
	je	kybigot1
	pop	ax
	ret
kybigot1:
	pop	ax
	push	bx
	push	cx			; save all regs
	push	dx
	push	di
	push	si
	push	bp
	push	ds
	push	es
	mov	ax,cs
	mov	ds,ax			; set our data seg
	mov	es,ax
	assume	ds:code,es:code
	call	spool			; execute spooler pop-up
	pop	es
	pop	ds
	pop	bp
	pop	si			; restore all regs
	pop	di
	pop	dx
	pop	cx
	pop	bx
	xor	ax,ax
	mov	ax,cs:[keybax]		; regain original keyboard func
	ret				; return zr flagging hotkey executed
kybitst endp


; macro to define key/routine table

splvect macro	char,rout
	dw	char
	dw	offset rout
	endm

splfuncs label	word
	splvect cr,doexit		; cr to exit spooler popup
	splvect esc_key,doexit		; esc to exit popup
	splvect '1',dodpc
	splvect '2',doclose
	splvect '3',dotime
	splvect '4',dohotkey
	splvect '5',dokbpoll
	splvect down,nextlpt
	splvect pgdn,nextlpt
	splvect up,prevlpt		; arrow keys to change stream/printer
	splvect pgup,prevlpt
	dw	0

	subttl spool - main resident function
	page
;======================================================================
;,fs
; spool - main resident function
; 
; in:	
; 
; out:	
; 
;,fe
;======================================================================
	assume	ds:code,es:code,ss:nothing
spool proc near
	lea	di,scrnsave
	mov	dh,winrow
	mov	dl,wincol
	mov	ch,winrows
	mov	cl,wincols
	call	savescrn		; save their screen area
	lea	si,window		; display our screen
	mov	bl,winattr		; our screen 'savescrn' format
	call	rstrscrn		;   so it is displayed by 'rstrscrn'
	mov	ax,[splseg]
	add	ax,spldoff		; (offset spldata) shr 4
	mov	es,ax			; es => 1st spool data buffer seg
	assume	es:splbuff
	call	dspall
getkey:
	lea	si,cmdqry		; ask for new input again
	call	dispclr
	call	splkey			; get a key
	lea	bx,splfuncs		; lookup routine from table
	or	al,al
	jz	dovect
	xor	ah,ah			; if not func key, clear scan code
dovect:
	cmp	word ptr [bx],0
	jz	getkey			; eol - invalid char - get another
	cmp	ax,[bx] 		; key matches table entry
	je	docall
	add	bx,4			; no get to next entry
	jmp	dovect
docall:
	call	[bx+2]			; call routine
	jmp	getkey			; and loop until <return> is pressed
spool endp

	subttl doexit - 
	page
;======================================================================
;,fs
; doexit - 
;
; exit from loop when <cr> or <esc> is pressed.
; called from statement above.
; 
; in:	
; 
; out:	
; 
;,fe
;======================================================================
	assume	ds:code,es:nothing,ss:nothing
doexit proc near
	pop	ax			; pop call return address off stack
	lea	si,scrnsave
	call	rstrscrn		; put their screen area back
	ret
doexit endp

	subttl splkey - 
	page
;======================================================================
;,fs
; splkey - 
; 
; in:	
; 
; out:	
; 
;,fe
;======================================================================
	assume	ds:code,es:nothing,ss:nothing
splkey proc near
	xor	ah,ah			; get a key
	pushf
	call	[keybvct]		; call regular kb routine
	ret
splkey endp

	subttl dodpc - dodpc update spooling disposition, priority, class
	page
;======================================================================
;,fs
; dodpc - dodpc update spooling disposition, priority, class
;
; in:	
; 
; out:	
; 
;,fe
;======================================================================
	assume	ds:code,es:splbuff,ss:nothing
dodpc proc near
	lea	si,dispqry		; ask for new disposition
	call	dispclr
	call	splkey			; get a key
	cmp	al,' '			; place marker?
	je	donodisp
	cmp	al,'_'			; place marker?
	je	donodisp
	and	al,0dfh 		; convert to upper case
	cmp	al,'D'			; delete
	je	dodisp
	cmp	al,'S'			; save
	je	dodisp
	cmp	al,'H'			; hold
	je	dodisp
	cmp	al,'N'			; no spooling
	je	dodisp
	cmp	al,'I'			; ignore
	je	dodisp
	jne	dodpcxit		; bad input
dodisp:
	mov	[splb.filname+spldisp],al  ; set new disp
	call	dspdpc
donodisp:
	lea	si,prioqry		; ask for new disp
	call	dispclr
	call	splkey
	cmp	al,' '			; place marker
	je	donoprio
	cmp	al,'_'			; place marker
	je	donoprio
	cmp	al,'0'			; make sure input valid
	jb	dodpcxit		; no
	cmp	al,'9'
	ja	dodpcxit		; no
doprio:
	mov	[splb.filname+splprio],al  ; set new pri
	call	dspdpc
donoprio:
	lea	si,clasqry		; ask for new class
	call	dispclr
	call	splkey
	and	al,0dfh 		; convert to upper case
	cmp	al,'A'			; make sure input valid
	jb	dodpcxit
	cmp	al,'Z'
	ja	dodpcxit		; no
doclas:
	mov	[splb.filname+splclas],al  ; set new class
dodpcxit:				; fall into display routine
	call	dspdpc
	ret
dodpc endp

	subttl dspdpc - dispdpc display spooler dpc in window
	page
;======================================================================
;,fs
; dspdpc - dispdpc display spooler dpc in window
; 
; in:	es -> splbuff segment
; 
; out:	
; 
;,fe
;======================================================================
	assume	ds:code,es:splbuff,ss:nothing
dspdpc proc near
	lea	si,splb.filname+spldisp
	lea	di,msgdpc+2
	mov	cx,3
dodpclup:
	mov	al,es:[si]		; copy spooler dpc to display var
	mov	[di],al
	inc	si
	inc	di
	loop	dodpclup
	lea	si,msgdpc		; display dpc string
	call	disp
	ret
dspdpc endp

	subttl dokbpoll - kb polling
	page
;======================================================================
;,fs
; dokbpoll - kb polling
; 
; in:	
; 
; out:	
; 
;,fe
;======================================================================
	assume	ds:code,es:nothing,ss:nothing
dokbpoll proc near
	push	ds
	mov	ds,[tcbseg]
	assume	ds:tcb
	xor	[tcbloop],1		; flip the dis mode bit
	pop	ds
	assume	ds:code
	call	dspkbpoll
	ret
dokbpoll endp

	subttl dspkbpoll - display polling state
	page
;======================================================================
;,fs
; dspkbpoll - display polling state
; 
; in:	es -> splbuff segment
; 
; out:	
; 
;,fe
;======================================================================
	assume	ds:code,es:splbuff,ss:nothing
dspkbpoll proc near
	push	ds
	mov	ds,[tcbseg]
	assume	ds:tcb
	mov	al,[tcbloop]
	pop	ds
	assume	ds:code
	lea	si,msgkbdis
	test	al,1			; get dis bit
	jnz	dspkbdis
	lea	si,msgkbenb
dspkbdis:
	call	disp
	ret
dspkbpoll endp

	subttl dohotkey - dohotkey change spooler hotkey value
	page
;======================================================================
;,fs
; dohotkey - dohotkey change spooler hotkey value
; 
; in:	
; 
; out:	
; 
;,fe
;======================================================================
	assume	ds:code,es:nothing,ss:nothing
dohotkey proc near
	lea	si,htkyqry1		; ask for new hotkey
	call	hotkeyget
	push	ax			; save request
	lea	si,htkyqry2		; ask for verify
	call	hotkeyget
	pop	bx			; get original request
	cmp	ax,bx
	lea	si,htkyerr
	jne	dohtkyerr		; not same key - don't set it
	mov	[hotkey],ax		; set new hotkey
	lea	si,htkyok		; get verified message
dohtkyerr:
	push	si
	call	dsphotkey
	pop	si
	call	dispclr 		; tell user hotkey verified
	call	splkey
	ret
dohotkey endp

	subttl dsphotkey - 
	page
;======================================================================
;,fs
; dsphotkey - 
; 
; in:	
; 
; out:	
; 
;,fe
;======================================================================
	assume	ds:code,es:nothing,ss:nothing
dsphotkey proc near
	mov	ax,[hotkey]
	mov	cx,4			; display hotkey value
	lea	di,msghotkey+2
	call	itoh			; produce hexadecimal value.
	lea	si,msghotkey
	call	disp
	ret
dsphotkey endp

	subttl hotkeyget - returns hotkey scancode and shift mode in ax
	page
;======================================================================
;,fs
; hotkeyget - returns hotkey scancode and shift mode in ax
; 
; in:	
; 
; out:	
; 
;,fe
;======================================================================
	assume	ds:code,es:nothing,ss:nothing
hotkeyget proc near
	call	dispclr 		; display message
	xor	ah,ah			; get a key

; if on an extended keyboard, use i16f10 instead of i16f00

	push	bx
	push	es
	mov	bx,40h
	mov	es,bx
	mov	bl,es:[96h]
	and	bl,10h
	or	ah,bl
	pop	es
	pop	bx
	pushf
	call	[keybvct]		; call regular kb routine
	ret
hotkeyget endp

	subttl doclose - doclose close the current spool file
	page
;======================================================================
;,fs
; doclose - doclose close the current spool file
; 
; in:	
; 
; out:	
; 
;,fe
;======================================================================
	assume	ds:code,es:splbuff,ss:nothing
doclose proc near
	mov	al,[splb.printer]
	mov	dx,0
	test	al,1			; lpt1 buffer?
	jnz	doclosit
	inc	dx
	test	al,2			; lpt2 buffer?
	jnz	doclosit
	inc	dx			; must be lpt3
doclosit:
	mov	ah,0ffh
	int	17h
	call	dspclose
	ret
doclose endp

	subttl dspclose - 
	page
;======================================================================
;,fs
; dspclose - 
; 
; in:	es -> splbuff segment
; 
; out:	
; 
;,fe
;======================================================================
	assume	ds:code,es:splbuff,ss:nothing
dspclose proc near
	lea	si,msgclose
	cmp	[splb.handle],-1
	je	dspclosdsp
	lea	si,msgopen
dspclosdsp:
	call	disp
	ret
dspclose endp

	subttl dotime - dotime changes spool file close timeout
	page
;======================================================================
;,fs
; dotime - dotime changes spool file close timeout
; 
; in:	
; 
; out:	
; 
;,fe
;======================================================================
	assume	ds:code,es:splbuff,ss:nothing
dotime proc near
	lea	si,timeqry
	call	dispclr
	push	[splb.timeout]
	xor	ax,ax
	mov	[splb.timeout],ax
	push	ax			; current value on the stack
	call	dsptime
dotimlup:
	call	splkey			; get a digit
	cmp	al,'0'
	jb	dotimxit
	cmp	al,'9'
	ja	dotimxit
	mov	cx,ax
	and	cx,0fh			; mask to digit value
	pop	ax
	mul	[ten]
	add	ax,cx			; add new digit
	cmp	ax,3600 		; ensure not greater than max
	jbe	dotimok
	xor	ax,ax			; else clear to wrap
dotimok:
	push	ax
	mul	[one82] 		; turn into tick count
	add	ax,91			; round it
	adc	dx,0
	div	[ten]
	mov	[splb.timeout],ax
	call	dsptime
	jmp	dotimlup
dotimxit:
	pop	bx			; pop new value
	pop	ax			; pop previous value
	or	bx,bx
	jnz	dsptime 		; store new value
	mov	[splb.timeout],ax	; revert to old value
	call	dsptime
	ret
dotime endp

	subttl dsptime - 
	page
;======================================================================
;,fs
; dsptime - 
; 
; in:	es -> splbuff segment
; 
; out:	
; 
;,fe
;======================================================================
	assume	ds:code,es:splbuff,ss:nothing
dsptime proc near
	mov	ax,[splb.timeout]
	mul	[ten]
	add	ax,5			; round before divide
	adc	dx,0
	div	[one82] 		; divide by 182
	mov	cx,4			; display timeout value
	lea	di,msgtime+2
	call	bintodec
	lea	si,msgtime
	call	disp
	ret
dsptime endp

	subttl prevlpt - prevlpt sets es => to the previous spool data segment
	page
;======================================================================
;,fs
; prevlpt - prevlpt sets es => to the previous spool data segment
; 
; in:	
; 
; out:	
; 
;,fe
;======================================================================
	assume	ds:code,es:splbuff,ss:nothing
prevlpt proc near
	mov	ax,es
	sub	ax,spldpars
	cmp	ax,[splseg]		; check before the last
	ja	prevlset
prevllup:
	add	ax,spldpars
	mov	es,ax
	cmp	[splb.printer],0
	je	prevlpt 		; get the last data buffer
	jmp	prevllup
prevlset:
	mov	es,ax
	call	dspall			; display all parameters
	ret
prevlpt endp

	subttl nextlpt - nextlpt sets es => to the next spool data segment
	page
;======================================================================
;,fs
; nextlpt - nextlpt sets es => to the next spool data segment
; 
; in:	
; 
; out:	
; 
;,fe
;======================================================================
	assume	ds:code,es:splbuff,ss:nothing
nextlpt proc near
	mov	ax,es
	add	ax,spldpars
	mov	es,ax
	cmp	[splb.printer],0
	jnz	nextlset
	mov	ax,[splseg]
	add	ax,spldoff		; (offset spldata) shr 4
	mov	es,ax
nextlset:
	call	dspall			; disp all fields since printer based
	ret
nextlpt endp

	subttl dsplpt - dsplpt displays the printers handled by spool buffer
	page
;======================================================================
;,fs
; dsplpt - dsplpt displays the printers handled by spool buffer
; 
; in:	
; 
; out:	
; 
;,fe
;======================================================================
	assume	ds:code,es:splbuff,ss:nothing
dsplpt proc near
	mov	al,' '			; clear '$' terminators from display
	mov	[msglpt+7],al
	mov	[msglpt+12],al
	mov	al,[splb.printer]	; which printers handled
	mov	ah,'0'			; printer number
	mov	bx,1			; offset to store number
dspllup:
	inc	ah
	shr	al,1
	jnc	dsplnext
	add	bx,5			; length of string
	mov	msglpt[bx],ah		; store printer number in string
dsplnext:
	or	al,al
	jnz	dspllup
	mov	msglpt[bx+1],'$'
	shr	bx,1			; calc position to display string
	neg	bx
	add	bx,42
	mov	[msglpt+1],bl		; store column
	lea	si,msglptclr
	call	disp			; clear current printer display
	lea	si,msglpt
	call	disp			; display current printers
	ret
dsplpt endp

	subttl dspfile - dspfile display spool file pathname
	page
;======================================================================
;,fs
; dspfile - dspfile display spool file pathname
; 
; in:	
; 
; out:	
; 
;,fe
;======================================================================
	assume	ds:code,es:splbuff,ss:nothing
dspfile proc near
	lea	si,splb.filname
	mov	cx,[splb.pathlen]
	sub	si,cx			; get to start of pathname
	add	cx,8			; add length of name
	cmp	cx,msgfilelen		; too large
	jb	dspfok
	mov	cx,msgfilelen
dspfok:
	lea	di,msgfile+2		; pointer to storage
dspflup:
	mov	al,es:[si]		; move filename to display buffer
	mov	[di],al
	inc	si
	inc	di
	loop	dspflup
	mov	byte ptr [di],'$'	; terminate string
	lea	si,msgfile
	call	disp
	ret
dspfile endp

	subttl dspall - dspall displays all fields in the popup display
	page
;======================================================================
;,fs
; dspall - dspall displays all fields in the popup display
; 
; in:	es -> splbuff segment
; 
; out:	
; 
;,fe
;======================================================================
	assume	ds:code,es:splbuff,ss:nothing
dspall proc near
	call	dspfile 		; display all variables
	call	dsplpt
	call	dspdpc
	call	dspclose
	call	dsptime
	call	dsphotkey
	call	dspkbpoll
	ret
dspall endp

	subttl savescrn - stores a window in the current display
	page
;======================================================================
;,fs
; savescrn - stores a window in the current display
; 
; in:	es:di => buffer to save window 6+2*(rows*cols)
;	dh,dl top-left row/col
;	ch,cl rows, cols to save
; 
; out:	
; 
;,fe
;======================================================================
	assume	ds:code,es:nothing,ss:nothing
savescrn proc near
	xor	bh,bh			; all references page 0
	push	dx
	push	cx
	mov	ah,3			; read cursor position
	int	10h
	mov	ax,dx			; save cursor position
	stosw
	pop	cx
	pop	dx
	mov	ax,dx			; store topleft row,col
	stosw
	add	cx,dx			; get to ending row, col
	mov	ax,cx			; store rows,cols
	stosw
	mov	bl,dl			; copy left column position
saveline:
	mov	ah,2			; set cursor pos
	int	10h
	mov	ah,8			; read char/attr
	int	10h
	stosw				; save in data area
	inc	dl			; next column position
	cmp	dl,cl			; end of line yet?
	jl	saveline		; do the whole line
	mov	dl,bl			; reset to start of next line
	inc	dh			; next row
	cmp	dh,ch			; last row yet?
	jl	saveline		; do all rows
	ret
savescrn endp

	subttl rstrscrn - restores screen saved by savescrn
	page
;======================================================================
;,fs
; rstrscrn - restores screen saved by savescrn
; 
; note: if [cursor] = -1, does not display attributes
;
; in:	ds:si => store screen from savescrn = [curscol], [cursrow],
;	[colmin], [rowmin], [colmax], [rowmax], attr, char.....
;	bl = attribute if [cursor] = -1
; 
; out:	
; 
;,fe
;======================================================================
	assume	ds:code,es:nothing,ss:nothing
rstrscrn proc near
	mov	di,si			; save ptr to cursor, top, left, rows, cols
	mov	bp,[di] 		; flags type of screen
	mov	dx,[di+2]		; top, left
	mov	cx,1			; display 1 character
	mov	bh,0			; always page 0
	add	si,6			; get to stored attrs/chars
rstrlup:
	mov	ah,2
	int	10h			; set cursor
	cmp	bp,-1
	je	rstrchar
	lodsw
	mov	bl,ah			; set attribute
	jmp	rstrdisp
rstrchar:
	lodsb				; just load byte (no attribute)
rstrdisp:
	mov	ah,9
	int	10h			; display character
	inc	dl
	cmp	dl,[di+4]		; end of line?
	jb	rstrlup
	mov	dl,[di+2]		; left column
	inc	dh
	cmp	dh,[di+5]		; end of lines
	jb	rstrlup
	mov	dx,[di] 		; restore cursor position
	cmp	dx,-1
	je	rstrsxit
	mov	ah,2
	int	10h
rstrsxit:
	ret
rstrscrn endp

	subttl disp - displays a '$' terminated string in the window
	page
;======================================================================
;,fs
; disp - displays a '$' terminated string in the window
; 
; dispclr clears the command line and then displays the message
;
; in:	ds:si => [rel row], [rel col], string to display, '$'
;	the first bytes are a relative row,col position
; 
; out:	
; 
;,fe
;======================================================================
	assume	ds:code,es:nothing,ss:nothing
dispclr proc near
	push	si			; save message addr
	lea	si,cmdclr
	call	disp			; clear command line display
	pop	si			; fall into display with message
disp:
	push	bx
	push	cx
	push	dx
	mov	dh,winrow
	mov	dl,wincol
	add	dh,[si] 		; calc relative screen coordinates
	inc	si
	add	dl,[si]
	inc	si
	mov	bx,winattr		; page 0, color attribute
	mov	cx,1			; display 1 character at a time
displup:
	mov	ah,2			; set cursor
	int	10h
	mov	al,[si] 		; get character
	inc	si
	cmp	al,'$'			; test end of string
	je	dispxit
	mov	ah,9			; disp attr/char at current cursor
	int	10h
	inc	dl			; next column
	jmp	displup
dispxit:
	pop	dx
	pop	cx
	pop	bx
	ret
dispclr endp

	subttl bintodec - converts a binary number to a decimal string.
	page
;======================================================================
;,fs
; bintodec - converts a binary number to a decimal string.
; 
; in:	ax = binary number
;	ds:di => buffer to place decimal string
;	cx = maximum chars in string
; 
; out:	
; 
;,fe
;======================================================================
	assume	ds:code,es:nothing,ss:nothing
bintodec proc near
	push	dx
	add	di,cx			; get to end of string
btdloop:
	xor	dx,dx
	div	[ten]
	add	dl,'0'
	dec	di
	mov	[di],dl 		; store next least significant digit
	or	ax,ax
	loopnz	btdloop 		; loop while nonzero chars and string space
btdspace:
	jcxz	btdxit			; space out remainder of string
	dec	di
	mov	byte ptr [di],' '
	loop	btdspace
btdxit:
	pop	dx
	ret
bintodec endp

	subttl itoh - outputs binary in hexadecimal char string
	page
;======================================================================
;,fs
; itoh - outputs binary in hexadecimal char string
; 
; in:	ax	= binary value to be displayed.
;	ds:di	= location to place the output string.
;	cx	= max # of digits to be placed.
; 
; out:	
; 
;,fe
;======================================================================
	assume	ds:code,es:nothing,ss:nothing
itoh proc near
	rol	ax,1			; put digit into position.
	rol	ax,1
	rol	ax,1
	rol	ax,1
	push	ax			; save for a sec.
	and	ax,000fh		; mask out the digit of interest.
	cmp	al,9			; if 0-9, display '0' - '9' else 'A' - 'F'
	ja	itoh1
	add	al,'0'	 		; digit is '0' - '9'
	jmp	short itoh_eol
itoh1:
	sub	al,10			; digit is 'A' - 'F'
	add	al,'A'
itoh_eol:
	mov	[di],al			; place the digit.
	inc	di
	pop	ax			; get remainder back.
	loop	itoh			; go for next digit.
	ret				; all done.
itoh endp

tsr	ends				; end of resident routines

;------------------------- initialization code -------------------------

	subttl	initialization code
	page

init	segment para
toknbuf   db	64 dup (0)		; buffer for command line token
printers  db	0			; contains bits of printers allocated
oldsplseg dw	0			; old spooler address

banner	db	'PC-MOS Print Spooler v4.12 (920205)',13,10
	db	'(C) Copyright 1987-1992 The Software Link Inc.',13,10
	db	'All Rights Reserved.',13,10,10,'$'

include copyrit.inc

	  db	13,10,'$'
msgrerun  db	'Spooler parameters modified.           ',13,10  ;@@xlat
msgss	  db	'Super Spooler Menu available.          ',13,10,'$'  ;@@xlat
msgdflhk  db	13,10,'Spooler HotKey reset to Ctrl-Home       ','$'  ;@@xlat
msgpath   db	13,10,'Invalid path!   ',13,10,'$'  ;@@xlat
msgclbd   db	13,10,'Invalid Spool Closing Parameter.                  ',13,10,'$'  ;@@xlat
errbeep   db	7,'$'
srchpath  db	64 dup (0)		; filename initiating search
srchname  db	13 dup (0)
removed db	'Spooler removed from memory',13,10,'$'  ;@@xlat
spldisable db	'Spooler disabled',13,10,'$'  ;@@xlat

findstr struc
fbuff	  db	21 dup (?)
fattr	  db	0
ftime	  dw	0
fdate	  dw	0
fsize	  dd	0
fname	  db	13 dup(0)
findstr ends

finds	  findstr <>			; declare structure for find
lastdat   dw	0			; latest spool file date
lasttim   dw	0			; latest spool file time

	subttl begin - start of init code
	page
;======================================================================
;,fs
; begin - start of init code
; 
; in:	
; 
; out:	
; 
;,fe
;======================================================================
	assume	ds:code,es:nothing,ss:nothing
begin:

include verschk.inc

	mov	ax,cs
	mov	ds,ax			; ds=>cs
	assume	ds:code
	lea	dx,banner
	call	display_string
	mov	ah,4			; get tcb address.
	mov	bx,-1			; for current task.
	int	services		; go get it.
	assume	es:tcb
	mov	[tcbseg],es		; save for later.
	mov	ax,[tcbspool]
	mov	[oldsplseg],ax
	mov	dx,[tcbid]
	or	ax,ax			; spooler already loaded?
	jnz	chkremove
	jmp	setsplseg
chkremove:

; if the user wants the spooler removed from memory, the
; command 'SPOOL OFF' would have been issued.

	mov	si,offset cmdline+1
cofflp:
	lodsb
	cmp	al,13
	je	coffskip
	cmp	al,' '
	je	cofflp
	and	al,0dfh 		; convert to uppercase
	cmp	al,'O'
	jne	cofflp
	mov	ax,word ptr ds:[si]
	inc	si
	and	ax,0dfdfh		; convert to uppercase
	cmp	ax,'FF'
	jne	cofflp

; at this point we know that spool off has been done
; so now we will first zap tcbspool to zero
; and also set int 16h back to normal vectors

	mov	word ptr [tcbspool],0	; clear spooler from system
	mov	ax,3516h
	int	21h			; get vector for 16h
	cmp	bx,offset keybint
	jne	notours

; int 16h points to our interupt so we will
; set it back to original int 16 intercept

	mov	di,offset spl16
	mov	ds,word ptr es:[di+3]	; this points to previos int 16
	mov	dx,word ptr es:[di+1]
	mov	ax,2516h
	int	21h

; free up memory to mos for spool.com code and enviroment

	push	es
	mov	es,word ptr es:[2ch]
	mov	ah,49h
	int	21h
	pop	es
	mov	ah,49h
	int	21h
	lea	dx,removed
	jmp	short splrem
notours:

; we have detected that someone has taken int 16 and we must
; now set flag to indicated that our int 16 logic is disable
; this will waste memory for spool.com tsr

	mov	ax,offset code:splsegbeg
	mov	cx,4
	shr	ax,cl
	mov	bx,[oldsplseg]
	sub	bx,ax
	mov	es,bx
	mov	di,offset spl16
	mov	byte ptr es:[di],'N'
	lea	dx,spldisable
splrem:
	push	cs
	pop	ds
	mov	ah,9
	int	21h
	mov	ax,4c00h
	int	21h
coffskip:

; if rerun of spool clear default values from spool data
; then update old spool data with changed values

	mov	di,offset code:spldata
	mov	cx,offset code:splsegend
	sub	cx,di
	xor	ax,ax
clearspl:
	mov	[di],al 		; let's not change the ES register
	inc	di
	loop	clearspl

; the new hotkey combination will be updated in the old spooler segment
; from the temporary spool segment in this code segment.  make sure
; that the hotkey combination from the old segment is kept so it can
; be restored.  if the user specifies a new one from the command line
; or just entered spool with no parameters, the local copy of the hot key
; will be reset.  then, when update gets it's hands on it the update will
; contain the hotkey that was specified.

	push	es
	mov	es,[oldsplseg]
	assume	es:spoolseg
	mov	ax,es:[hotkey]	 	; yank out of old spool seg.
	assume	es:nothing
	pop	es
	mov	[hotkey],ax		; put in new seg.
setsplseg:				; get new spool data segment in es
	mov	ax,offset code:splsegbeg
	mov	cx,4
	shr	ax,cl
	mov	bx,cs			; compute spool data header segment
	add	ax,bx
	mov	[splseg],ax		; ax = new spooler segment
	add	ax,spldoff		; (offset spldata) shr 4
	mov	es,ax
	assume	es:splbuff
	mov	[splb.iopsp],cs 	; spool segment psp for future i/o
	mov	ax,dx			; task id into al
	aam				; convert to decimal
	or	ax,'00'
	xchg	al,ah			; store task id into spool name
	mov	word ptr [splb.filname+spltask],ax
	mov	[splb.buffpnt],offset splbuff:buffer
	mov	[splb.filname],'S'
	mov	[splb.filname+1],'P'
	mov	[splb.filname+2],'L'
	call	parse			; parse command line
	jc	exiterr
	mov	al,[printers]		; mark streams sent to last buffer
	xor	al,7			; all printers not yet handled
	mov	[splb.printer],al
	call	lastfile		; for remaining printers
	cmp	[oldsplseg],0		; rerun of spool
	jz	exittsr 		; no exit leaving tsr and data buffers
	call	update			; rerun - update old spool data seg
	lea	dx,msgrerun		; output exiting message
	xor	al,al			; no exit error
	call	display_string
	mov	ah,4ch			; exit
	int	21h
exiterr:
	call	display_string		; write error string
	lea	dx,errbeep		; beep after error message
	mov	al,1			; exit with error
	call	display_string
	mov	ah,4ch			; exit
	int	21h

; set the bios keyboard interrupt vector and exit with routines resident
; set the spool pointer in tcb
; set only after any aborts may terminate this prog before completion

exittsr:
	mov	es,[tcbseg]
	assume	es:tcb
	mov	ax,[splseg]
	mov	[tcbspool],ax
	mov	al,keyvect
	mov	ah,35h	 		; get keyboard interrupt vector.
	int	21h
	mov	word ptr [keybvct],bx	; and save for tsr chaining
	mov	word ptr [keybvct+2],es
	assume	es:nothing
	lea	dx,keybint		; set new keyboard interrupt routine
	mov	ah,25h
	int	21h
	lea	dx,msgss		; tell user using ss
	call	display_string
	lea	bx,spldata		; offset to first buffer
calcend:
	add	bx,spldpars * 16
	cmp	[bx].printer,0		; find end of last buffer
	jne	calcend
	add	bx,16			; +1 para for the terminating null printer
	mov	dx,bx			; terminate & stay resident
	int	27h

	subttl parse - digests the command line parameters
	page
;======================================================================
;,fs
; parse - digests the command line parameters
; 
; in:	
; 
; out:	ds:dx => error message (0 if none)
; 
;,fe
;======================================================================
	assume	ds:code,es:splbuff,ss:nothing

errsyntx db	"Syntax Error $        " ;@@xlat

parse proc near
	lea	si,cmdline		; pntr to command line
	lodsb				; get length of line
	xor	cx,cx
	mov	cl,al			; as a character count
	clc
	jcxz	parsdef 		; no arguments reset spooler hotkey
	push	cx			; save command line length
	push	si			; and source pointer
parsloop:
	pop	si
	pop	cx
	jc	parsxit 		; error on last argument
	jcxz	parsxit
	lea	di,toknbuf
	call	token			; get next command line token
	cmp	[toknbuf],0		; any argument?
	je	parsxit 		; if not, exit loop.
	push	cx			; save command line length
	push	si			; and source pointer
	mov	cx,di			; calculate token length
	sub	cx,offset code:toknbuf
	lea	bx,toknbuf
	cmp	[toknbuf],'/'		; some switch
	je	parswtch

; must be directory path or dpc [dispostionpriorityclass]

	cmp	cx,3			; dpc is 3 or fewer chars
	jg	parspath		; path must have more than 3 'd:\x'
	call	dpc			; parse disposition/priority/class
	jmp	parsloop
parspath:
	call	path
	jmp	parsloop
parsdef:
	cmp	word ptr [oldsplseg],0
	je	parsxit
	mov	[hotkey],default_hotkey	; update will move to old seg.
	lea	dx,msgdflhk		; display resetting hotkey
	call	display_string
parsxit:
	ret
parse endp

	subttl parswtch - 
	page
;======================================================================
;,fs
; parswtch - 
; 
; in:	
; 
; out:	
; 
;,fe
;======================================================================
	assume	ds:code,es:splbuff,ss:nothing
parswtch proc near
	mov	ah,[toknbuf+1]		; get switch char
	mov	al,[toknbuf+2]		; get simple switch argument
	sub	cx,2			; subtract 2 for '/X'
	lea	bx,toknbuf+2		; address of parameter
parskey:
	cmp	ah,'K'
	jne	parslpt
	call	key
	jmp	parsloop
parslpt:
	cmp	ah,'L'
	jne	parsname
	call	lpt
	jmp	parsloop
parsname:
	cmp	ah,'N'
	jne	parsecur
	call	sysname
	jmp	parsloop
parsecur:
	cmp	ah,'S'
	jne	parstime
	call	secure
	jmp	parsloop
parstime:
	cmp	ah,'T'
	jne	parswter
	call	time
	jmp	parsloop

errswitch db	"Unknown switch $       "  ;@@xlat

parswter:
	lea	dx,errswitch
	stc
	jmp	parsloop
parswtch endp

	subttl dpc - validates and sets file's Disposition, Priority, Class
	page
;======================================================================
;,fs
; dpc - validates and sets file's Disposition, Priority, Class
; 
; in:	[toknbuf] contains dpc
;	cx contains token length
; 
; out:	cy if error
;	dx contains error message
; 
;,fe
;======================================================================
	assume	ds:code,es:splbuff,ss:nothing
dpc proc near
	mov	al,[toknbuf]		; validate disposition
	call	parsdisp
	jc	dpcxit
	mov	[toknbuf],al		; set in token after translation
	cmp	cx,1
	jbe	dpcset
dpcprio:
	mov	al,[toknbuf+1]		; validate priority
	call	parsprio
	jc	dpcxit
	mov	[toknbuf+1],al
	cmp	cx,2
	jbe	dpcset
dpcclas:
	mov	al,[toknbuf+2]		; validate printer class
	call	parsclas
	jc	dpcxit
	mov	[toknbuf+2],al
dpcset: 				; dpc validated copy to filename
	lea	si,toknbuf
	lea	di,splb.filname + spldisp
	rep	movsb
	clc				; no error
dpcxit:
	ret
dpc endp

	subttl parsdisp -
	page
;======================================================================
;,fs
; parsdisp -
; 
; in:	
; 
; out:	
; 
;,fe
;======================================================================
	assume	ds:code,es:splbuff,ss:nothing

errdisp db	"Invalid Disposition $     "  ;@@xlat

parsdisp proc near
	lea	dx,errdisp
	cmp	al,'D'			; delete
	je	prsdispxit
	cmp	al,'H'			; hold
	je	prsdispxit
	cmp	al,'I'			; none
	je	prsdispxit
	cmp	al,'N'			; print
	je	prsdispxit
	cmp	al,'S'			; save
	je	prsdispxit
	cmp	al,'_'			; check place marker
	mov	al,[splb.filname+spldisp]
	je	prsdispxit		; translate to previous if place holder
	stc
prsdispxit:
	ret
parsdisp endp

	subttl parsprio -
	page
;======================================================================
;,fs
; parsprio - 
; 
; in:	
; 
; out:	
; 
;,fe
;======================================================================
	assume	ds:code,es:splbuff,ss:nothing

errprio db	"Invalid Print Priority $        "  ;@@xlat

parsprio proc near
	lea	dx,errprio
	cmp	al,'0'
	jb	prioerr
	cmp	al,'9'
	ja	prioerr
prioxit:
	clc
	ret
prioerr:
	cmp	al,'_'			; check place holder
	mov	al,[splb.filname+splprio]
	je	prioxit 		; return translated priority
	stc				; return error flag
	ret
parsprio endp

	subttl parsclas - 
	page
;======================================================================
;,fs
; parsclas - 
; 
; in:	
; 
; out:	
; 
;,fe
;======================================================================
	assume	ds:code,es:splbuff,ss:nothing

errclas db	"Invalid Print Class $        "  ;@@xlat

parsclas proc near
	lea	dx,errclas
	cmp	al,'A'
	jb	claserr
	cmp	al,'Z'
	ja	claserr
clasxit:
	clc
	ret
claserr:
	cmp	al,'_'			; check for strange placeholder
	mov	al,[splb.filname+splclas]
	je	clasxit
	stc				; return flagging error
	ret
parsclas endp

	subttl path - validates spool directory path
	page
;======================================================================
;,fs
; path - validates spool directory path
; 
; there is a problem with sequence numbers if multiple directories
; are used.  but we will allow them this feature (bug).
;
; in:	[toknbuf] contains pathname
;	di => terminator of pathname
; 
; out:	cy if error
;	bx = error message
;	nc
;	es:[splb.filpath] = right justified path
;	es:[splb.pathlen] = length of path
; 
;,fe
;======================================================================
	assume	ds:code,es:splbuff,ss:nothing

errdrive db	'Must specify drive with spool directory $          '  ;@@xlat
errpath  db	'Spool directory not found $           '  ;@@xlat
errpaths db	'All files are spooled to same directory $           '	;@@xlat

path proc near
	cmp	byte ptr [di-1],'\'	; ensure path ends with '\'
	je	pathdriv
	mov	byte ptr [di],'\'
	inc	di
pathdriv:
	lea	dx,errdrive		; must start with drive
	cmp	word ptr [toknbuf+1],'\:'
	jne	patherr
	mov	byte ptr [di-1],0	; delete terminal '\' for open
	lea	dx,finds		; set dta to find structure
	mov	ah,1ah
	int	21h
	lea	dx,toknbuf		; validate path with open
	mov	cx,10h			; search for a directory
	mov	ah,4eh
	int	21h
	lea	dx,errpath
	jc	patherr 		; must give access denied
	mov	byte ptr [di-1],'\'	; append terminal '\'
	sub	di,offset code:toknbuf	; calculate length
	mov	[splb.pathlen],di	; and save length of path
	mov	cx,di
	lea	di,splb.filname
	sub	di,cx			; move to path buffer
	lea	si,toknbuf
	rep	movsb
	clc				; no error
	ret
patherr:				; return with error flag
	stc
	ret
path endp

	subttl key  - parses the spooler hotkey.  '/Kxxxx' gives the hexadecimal hotkey
	page
;======================================================================
;,fs
; key  - parses the spooler hotkey.  '/Kxxxx' gives the hexadecimal hotkey
; 
; in:	cx = token length
;	ds:bx => argument string
; 
; out:	dx = error message if cy
; 
;,fe
;======================================================================
	assume	ds:code,es:splbuff,ss:nothing

errkey	db	'Invalid hotkey number $        '  ;@@xlat

key proc near
	jcxz	keyerr			; must specify number
	call	htoi
	jc	keyerr
	mov	[hotkey],dx		; set initial popup hotkey
	ret
keyerr:
	lea	dx,errkey
	ret
key endp

	subttl sysname  - parse name switch  '/Nx'  sets hybrid system spool file name
	page
;======================================================================
;,fs
; sysname  - parse name switch  '/Nx'  sets hybrid system spool file name
; 
; in:	ax = character after '/N'
;	cx = token length
; 
; out:	dx = error message if cy
; 
;,fe
;======================================================================
	assume	ds:code,es:splbuff,ss:nothing

errname db	"Invalid Name switch $      "  ;@@xlat

sysname proc near
	cmp	cx,1
	jne	nameerr
	cmp	al,'0'
	jb	nameerr 		; system name char  '0' - '9'
	cmp	al,'9'
	jle	nameset
	cmp	al,'A'			; system name char  'A' - 'Z'
	jb	nameerr
	cmp	al,'Z'
	ja	nameerr 		; otherwise error
nameset:
	mov	[splb.filname+splname],al
	clc
	ret				; set system name char in filename
nameerr:
	lea	dx,errname		; return with error message
	stc
	ret
sysname endp

	subttl secure - parse spool file security switch
	page
;======================================================================
;,fs
; secure - parse spool file security switch
; 
; in:	ax = character after '/S'
;	cx = length of switch argument
; 
; out:	dx = error message if cy
; 
;,fe
;======================================================================
	assume	ds:code,es:splbuff,ss:nothing

errsecur db	"Unaccessable security class $      "  ;@@xlat

secure proc near
	lea	dx,errsyntx
	cmp	cx,1
	ja	scurerx
	jb	scurblnk

; no character was given.  blank the security class.

	cmp	al,'_'			; test blank security
	je	scurblnk		; yes always good
	cmp	al,'A'			; validate security class
	jb	scurerr
	cmp	al,'Z'
	ja	scurerr

; ensure allowable security

	push	es			; address tcb
	mov	es,[tcbseg]
	assume	es:tcb
	cmp	al,[tcbcdft]		; equals default?
	je	scursto
	push	cx
	xor	bx,bx
	mov	bl,al			; calculate index to security bits
	sub	bl,'A'
	add	bx,bx			; 2 bits / class
	mov	cx,bx			; calc shift bits
	and	cx,7
	shr	bx,1
	shr	bx,1
	shr	bx,1
	mov	bl,[tcbcmap+bx]
	shr	bl,cl			; get class permission bits
	and	bl,3
	cmp	bl,3			; can create such class?
	pop	cx
	je	scursto
	pop	es
scurerr:
	lea	dx,errsecur		; invalid security class
scurerx:
	stc
	ret
scurblnk:
	mov	al,' '
	jmp	short scurdone
scursto:				; store spool file security
	pop	es
	assume	es:splbuff
scurdone:
	mov	[splb.seclass],al
	clc
	ret
secure endp

	subttl time - sets spool file time out value
	page
;======================================================================
;,fs
; time - sets spool file time out value
; 
; in:	
; 
; out:	
; 
;,fe
;======================================================================
	assume	ds:code,es:splbuff,ss:nothing

errtime 	db	"Timeout value error $         "  ;@@xlat
time_range	db	"Timeout value must be 1 to 3600 seconds.    $"  ;@@xlat

time proc near
	jcxz	timeerr
	call	dectobin		; get number
	jc	timeerr
	cmp	dx,3600
	ja	time_too_large
	mov	ax,dx
	mul	[one82] 		; convert seconds to ticks
	div	[ten]
	cmp	dx,0			; if remainder, increment 1 tick.
	je	tim1
	inc	ax
tim1:
	mov	[splb.timeout],ax	; set timeout value
	clc
	ret
timeerr:
	lea	dx,errtime
	stc
	ret
time_too_large:
	lea	dx,time_range
	stc
	ret
time endp

	subttl dectobin - converts a decimal string to binary number
	page
;======================================================================
;,fs
; dectobin - converts a decimal string to binary number
; 
; in:	ds:bx => decimal string
;	cx = length of string
; 
; out:	dx = string value
;	cy if invalid digit
; 
;,fe
;======================================================================
	assume	ds:code,es:nothing,ss:nothing
dectobin proc near
	xor	dx,dx			; clear accumulator.
	xor	ax,ax			; only using al.
dtb_loop:
	mov	al,[bx]			; get next digit.
	cmp	al,0			; end of string?
	je	dtb_exit
	inc	bx
	cmp	al,'0'	 		; in range? (0-9)
	jb	dtb_error
	cmp	al,'9'
	ja	dtb_error
	sub	al,'0'	 		; convert from digit to numeric.
	push	bx
	mov	bx,dx
	shl	dx,1			; multiply dx*10.
	shl	dx,1
	shl	dx,1			; dx = dx*8
	shl	bx,1			; bx = dx*2
	add	dx,bx			; dx = (dx*8) + (dx*2)
	pop	bx
	add	dx,ax			; dx = (dx*10) + ax.
	loop	dtb_loop
	jmp	short dtb_exit
dtb_error:
	stc
dtb_exit:
	ret
dectobin endp

	subttl htoi  - converts input hex string expressed to binary 
	page
;======================================================================
;,fs
; htoi  - converts input hex string expressed to binary 
; 
; the usage of cx should be redundant.  remove its usage
; after determining if it's needed by routines calling
; htoi.
;
; in:	ds:bx	= hexadecimal (asciiz) string to be converted.
;	cx	= max length of string.
; 
; out:	dx	= value of input string.
;	carry	= set on invalid digit error.
; 
;,fe
;======================================================================
	assume	ds:code,es:nothing,ss:nothing
htoi proc near
	xor	dx,dx			; clear accumulator.
	xor	ax,ax			; only use al.
htoi_loop:
	mov	al,[bx]			; get next digit from string.
	inc	bx
	cmp	al,0			; end of asciiz string?
	je	htoi_exit		; if so, get out.
	cmp	al,'0'	 		; check the digit range. (0-9, a-f)
	jb	htoi_error
	cmp	al,'9'
	ja	htoi1

; hex digit '0' - '9'

	sub	al,'0'
	jmp	short htoi_add
htoi1:
	cmp	al,'A'
	jb	htoi_error
	cmp	al,'F'
	ja	htoi_error
	sub	al,'A'
	add	al,10
htoi_add:
	shl	dx,1			; make room for next digit.
	shl	dx,1
	shl	dx,1
	shl	dx,1
	add	dx,ax			; add to least signifigant digit.
	loop	htoi_loop
	jmp	short htoi_exit
htoi_error:
	stc
htoi_exit:
	ret
htoi endp

	subttl lpt - stores line printer bit in current spool data buffer.
	page
;======================================================================
;,fs
; lpt - stores line printer bit in current spool data buffer.
; 
; validates printer number.
; adds printer bit to [printers], which printers buffered
; bumps spool data segment pointer (es) to next buffer.
; copies values in old data buffer to new buffer.
;
; in:	
; 
; out:	
; 
;,fe
;======================================================================
	assume	ds:code,es:splbuff,ss:nothing

errlpt	db	"Invalid LPT $      "	;@@xlat

lpt proc near
	and	al,0dfh 		; uppercase
	cmp	al,'P'			; check lpt entered
	jne	lptnum			; check number if /lx
	inc	bx
	mov	al,[bx]
	and	al,0dfh
	cmp	al,'T'
	jne	lpterr
	inc	bx			; get printer number
	mov	al,[bx]
lptnum:
	cmp	al,'1'			; valid printer?
	jb	lpterr
	cmp	al,'3'
	ja	lpterr
	sub	al,'1'			; get printer binary num 0-2
	mov	cl,al			; create printer bit
	mov	al,1
	shl	al,cl
	mov	[splb.printer],al
	or	[printers],al		; add printer bit to total seen
	call	lastfile		; update fileseq
	mov	ax,es			; next spool data segment
	add	ax,spldpars		; (size spldata + 15) shr 4
	mov	es,ax
	cmp	[oldsplseg],0		; just changing parameters?
	jnz	lptxit			; then leave nulls to flag changes
	push	ds			; save data segment
	sub	ax,spldpars		; (size spldata + 15) shr 4
	mov	ds,ax
	assume	ds:splbuff
	push	si			; move current parmeters to new data seg
	push	di
	xor	si,si
	mov	di,si
	mov	cx,size spldata
	rep	movsb
	pop	di
	pop	si
	pop	ds			; restore data segment
	assume	ds:code
lptxit:
	clc				; return without error
	ret
lpterr:
	lea	dx,errlpt		; invalid lpt number
	stc
	ret
lpt endp

	subttl token - scans a space,tab,comma,slash delimited token
	page
;======================================================================
;,fs
; token - scans a space,tab,comma,slash delimited token
; 
; in:	ds:si => source buffer
;	ds:di => destination buffer
;	cx = length of source
; 
; out:	ds:di => null terminating token
;	ds:si => character after delimiter
;	cx = updated source length
;	al = delimiter char
; 
;,fe
;======================================================================
	assume	ds:code,es:splbuff,ss:nothing
token proc near
	jcxz	toknxit 		; jump if no chars left
	lodsb				; get next char
	dec	cx
	cmp	al,' '			; skip spaces
	je	token
	cmp	al,9			; skip tabs
	je	token
	cmp	al,0dh			; exit on <cr>
	je	toknxit
	cmp	al,'/'
	je	toknsto 		; store slash if first char
toknlup:
	cmp	al,' '			; test token end delimitor
	je	toknxit
	cmp	al,9
	je	toknxit
	cmp	al,0dh
	je	toknxit
	cmp	al,','
	je	toknxit
	cmp	al,'/'
	jne	toknupr
	dec	si
	inc	cx			; so next token begins with '/'
	jmp	short toknxit
toknupr:
	cmp	al,'a'			; upper case alpha input
	jb	toknsto
	cmp	al,'z'
	ja	toknsto
	and	al,0dfh 		; mask to upper case
toknsto:
	mov	[di],al 		; store in destination
	inc	di
	jcxz	toknxit 		; exit on terminator or count
	lodsb				; get next char
	dec		cx
	jmp	toknlup 		; loop until delimitor or count
toknxit:
	mov	byte ptr [di],0 	; terminate destination string
	ret
token endp

	subttl lastfile - scans directory in es = splbuff for highest/latest file
	page
;======================================================================
;,fs
; lastfile - scans directory in es = splbuff for highest/latest file
; 
; if spntt999.xxx is found returns latest spool sequence
; else returns highest spool sequence
;
; in:	
; 
; out:	
; 
;,fe
;======================================================================
	assume	ds:code,es:splbuff,ss:nothing
lastfile proc near
	lea	dx,finds		; set dta to find structure
	mov	ah,1ah
	int	21h
	mov	cx,[splb.pathlen]
	lea	si,splb.filname 	; copy buffer's pathname to search name
	sub	si,cx
	lea	di,srchname
	sub	di,cx
	add	cx,13			; add length of filename
lstfcopy:
	mov	al,es:[si]
	mov	[di],al
	inc	si
	inc	di
	loop	lstfcopy
	mov	al,'9'
	mov	[srchname+splseq],al
	mov	[srchname+splseq+1],al
	mov	[srchname+splseq+2],al
	mov	al,'?'			; search for spltt999.???
	mov	[srchname+spldisp],al
	mov	[srchname+splprio],al
	mov	[srchname+splclas],al
	lea	dx,srchname
	sub	dx,[splb.pathlen]
	xor	cx,cx			; find only normal files
	mov	ah,4eh
	int	21h
	mov	al,'?'			; now searching for any sequence number
	mov	[srchname+splseq],al
	mov	[srchname+splseq+1],al	; spltt???.???
	mov	[srchname+splseq+2],al
	jc	lstfmost		; go find file with highest sequence

; if file 999 exists spool file sequence overflowed.
; find latest spool file created

lstflast:
	xor	ax,ax			; initialize latest date/time
	mov	[lasttim],ax
	mov	[lastdat],ax
	mov	ah,4eh
	int	21h
lstfllup:
	jc	lstfxit 		; exit when no more files
	mov	ax,[finds.ftime]
	sub	ax,[lasttim]
	mov	ax,[finds.fdate]
	sbb	ax,[lastdat]
	jb	lstflnxt
	lea	bx,finds.fname+splseq
	mov	cx,3			; convert sequence number to binary
	call	dectobin
	mov	[fileseq],dx
lstflnxt:
	mov	ah,4fh
	int	21h
	jmp	lstfllup
lstfmost:				; get largest sequence num
	mov	ah,4eh
	int	21h
lstfmlup:
	jc	lstfxit
	lea	bx,finds.fname+splseq
	mov	cx,3			; get filename sequence number
	call	dectobin
	jc	lstfmnxt		; invalid digit if cy
	cmp	dx,[fileseq]
	jb	lstfmnxt		; produce max sequence #
	mov	[fileseq],dx
lstfmnxt:
	mov	ah,4fh
	int	21h
	jmp	lstfmlup
lstfxit:
	ret
lastfile endp

	subttl update - update the old spool data with the new parameters.
	page
;======================================================================
;,fs
; update - update the old spool data with the new parameters.
; 
; in:	[oldsplseg] => spool data segment from initial spool command
;	[splseg] => new cleared data segment so only changes are non-null
; 
; out:	changes stored in the corresponding old spool data
; 
;,fe
;======================================================================
	assume	ds:code,es:splbuff,ss:nothing
update proc near
	push	ds
	push	es
	mov	es,[oldsplseg]
	mov	ds,[splseg]
	assume	ds:spoolseg,es:spoolseg

; update the hot-key.

	mov	ax,[hotkey]
	mov	es:[hotkey],ax
updlpts:				; for all current lpts update old data segment
	mov	ax,ds
	add	ax,spldoff		; get to data segment
	mov	ds,ax
	assume	ds:splbuff
updloop:				; loop for all printers
	mov	al,[splb.printer]
	or	al,al
	je	updxit			; finished with all printers
	call	findold 		; find corresponding old data segment
	jc	updlnext		; couldn't find??
	assume	es:splbuff
updtime:
	cmp	[splb.timeout],0	; timeout value changed
	je	updpfx
	mov	ax,[splb.timeout]
	mov	es:[splb.timeout],ax
updpfx:
	cmp	[splb.filname],0
	je	upddisp
	mov	cx,5
	cld
	mov	si,offset splb.filname
	mov	di,si
	rep	movsb
upddisp:
	cmp	[splb.filname+spldisp],0
	je	updprio
	mov	al,[splb.filname+spldisp]
	mov	es:[splb.filname+spldisp],al
updprio:
	cmp	[splb.filname+splprio],0
	je	updclas
	mov	al,[splb.filname+splprio]
	mov	es:[splb.filname+splprio],al
updclas:
	cmp	[splb.filname+splclas],0
	je	updpath
	mov	al,[splb.filname+splclas]
	mov	es:[splb.filname+splclas],al

; there are problems with changing the path
; since there may not be a good sequence number
; for both directories.  however,the benefits
; appear to outweigh the risks.

updpath:
	mov	cx,[splb.pathlen]
	jcxz	updlnext		; path wasn't given
	mov	es:[splb.pathlen],cx
	lea	si,splb.filname
	sub	si,cx			; beginning of pathname
	mov	di,si
	rep	movsb
updlnext:
	mov	ax,ds
	add	ax,spldpars		; (size spooldat + 15) shr 4
	mov	ds,ax
	jmp	updloop
updxit:
	pop	es
	pop	ds
	ret
update endp

	subttl findold - finds the spool buffer for the given printer
	page
;======================================================================
;,fs
; findold - finds the spool buffer for the given printer
; 
; in:	al = printer bits of new spool buffer
;	ds => new splbuff
; 
; out:	es => old splbuff or cy if not found
; 
;,fe
;======================================================================
	assume	ds:splbuff,es:nothing,ss:nothing
findold proc near
	mov	dx,[oldsplseg]		; get old base spool segment
	add	dx,spldoff		; (offset spldata) shr 4
findolup:
	mov	es,dx
	assume	es:splbuff
	cmp	es:[printer],0		; end of old spool segs
	je	findoerr
	test	al,es:[printer] 	; any printers match??
	jnz	findoxit
	add	dx,spldpars		; (size spldata + 15) shr 4
	jmp	findolup
findoerr:
	stc				; give error return
findoxit:
	ret
findold endp

	subttl dsplstr - outputs a '$' terminated string to standard output
	page
;======================================================================
;,fs
; dsplstr - outputs a '$' terminated string to standard output
; 
; in:	ds:dx => message
; 
; out:	
; 
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:nothing
dsplstr proc near
	push	ax
	mov	ah,9
	int	21h
	pop	ax
	ret
dsplstr endp

	subttl display_string - outputs a string and then cr,lf to standard output
	page
;======================================================================
;,fs
; display_string - outputs a string and then cr,lf to standard output
; 
; in:	ds:dx => message
; 
; out:	
; 
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:nothing

crlf	db	13,10,'$'

display_string proc near
	call	dsplstr
	push	dx
	lea	dx,crlf
	call	dsplstr
	pop	dx
	ret
display_string endp

init	ends
	end	start

