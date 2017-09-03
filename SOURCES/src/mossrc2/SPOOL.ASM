	include page.inc
	title	spool - spool data area and pop up window
	subttl	spool development specification
comment ^===============================================================
 spool.asm  =>  spool.com
 creates the spool data buffer used by int 17 to channel printer
 output to a file.  if spool segment already exits, modifies
 the spool parameters.  a tsr routine remains for popup changes
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

11/30/89 BWR	Marked messages for foreign language translations.

03/13/90 SAH	Added spool off option to disable spooler		

04/18/90 BWR	Corrected problem with Extended Keyboard Support.  SPOOL.COM
		now allows nearly ANY combination of keys to be assigned
		as the window "hot-key".  The hot-key handling routines
		have been simplified, eliminating access to both the SCB
		and the BIOS data areas.

05/01/90 BWR	Security option (specified /S or /S_) caused system crash.
		This because security-set routine jumped to section and
		popped ES register that was NOT pushed.  Stack corruption
		resulted.  Also corrected problem with spooler screwing
		up the hotkey whenever invoked a second time to change
		some other parameter.  (The spooler window was no longer
		accessible in that case.)  Finally, also corrected a
		segment addressing error in the RESET routine which was
		placing the DEFAULT_HOTKEY into the wrong segment.  (Bad
		use of ASSUME).


11/02/90 BWR	Corrected problem I created by changing the way the hotkey
		was being read from the keyboard. The manual states that
		the hotkey sequence as displayed in the on-screen window
		can be entered on the /K command-line option.  The change
		made did not account for this and has been corrected.  The
		user may now enter this code (which is now a HEX code)
		on the /K parameter.

		Also corrected a small problem with the error message
		displayed when a bad option was entered on the command
		line.  The BX register was being loaded with the message
		offset instead of DX, causing garbage to be displayed
		on the screen instead of the required error message.
		Definitely inelegant.

		Corrected a precision error in the routine that handles
		the interpretation of the /T (timeout) argument.  If the
		user entered /T18, the timeout displayed was 17 seconds.

		SPOOL now enforces the timeout range of 1 to
		3600 seconds by issuing the appropriate error message
		and aborting if the argument is out of range.

		Corrected problem with command line handling.  If spaces
		entered after SPOOL without any other parameters, the
		parse routine caused an invalid instruction error.  This
		was because PARSE was popping two values off the stack
		that he did not place there!

		Spool program now displays a copyright banner on being
		invoked.

mjs 12/20/90	modified int16 intercept code to also watch int16fun10 
		and int16fun11.  programs compiled with basic 7.0 use 
		these functions when a 101 key keyboard is detected.
		updated to v4.11 (901220).
		updated copyright notice to 1991

========================================================================^

KEYVECT 	equ	16h		;Vector used for HOTKEY monitor.
DEFAULT_HOTKEY	equ	7700h		;CTRL-HOME / ASCII zero.

include OPTIONS.INC
;
;   Define segment templates for addressing memory.
;
tcb		segment at	6666h
include MOSTCB.INC
tcb	ends


CR	equ	0Dh
ESC_KEY equ	1Bh
UP	equ	4800h
PGUP	equ	4900h
DOWN	equ	5000h
PGDN	equ	5100h

code	GROUP	tsr, spoolseg, init

tsr	segment 	para
	ASSUME		CS:code
ORG	80h

cmdline db	80h dup (?)	;Command tail.

ORG	100h
start	label near
	jmp	begin

spoolseg	segment 	para
splsegbeg	label		byte
include 	MOXSPLDT.INC
splsegend	label		byte
spoolseg	ends

splbuff 	segment at	7000h		;Spooldat defined above.
splb	spooldat <>
splbuff 	ends

;--------------------------- Local DATA storage areas ----------------------

spl16		db	'Y'     ;INT 16 intercept enabled.
keybvct 	dd	0	;Original INT 16 vector address.
keybax		dw	0	;User keyboard function.

WINATTR equ	1fh		;White on blue.
WINROW	equ	3
WINCOL	equ	15
WINROWS equ	13
WINCOLS equ	50

; buffer to save user's screen

scrnsave dw	3+(WINROWS*WINCOLS) dup(0)
window	dw	-1			; create a scrn rstrscrn can display
	db	WINCOL, WINROW
	db	WINCOL+WINCOLS, WINROW+WINROWS
	db	'ÉÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ»'
	db	'º * * * *   S U P E R    S P O O L E R   * * * * º' ;@@XLAT
	db	'ÇÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¶'
	db	'º                                                º'
	db	'ÇÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¶'
	db	'º   [1] Current Spool Parameters    -            º' ;@@XLAT
	db	'º   [2] Spool file status           -            º' ;@@XLAT
	db	'º   [3] Spool file close time       -            º' ;@@XLAT
	db	'º   [4] Spooler popup Hotkey        -            º' ;@@XLAT
	db	'º   [5] Keyboard Polling mode       -            º' ;@@XLAT
	db	'ÇÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¶'
	db	'º                                                º'
	db	'ÈÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼'
	db	'                                                $'

MSGFILELEN	equ	29

msgfile   db	03,04
	  db	msgfilelen dup (' '),'$'
msglpt	  db	03,30,' LPT1 LPT2 LPT3$'
msglptclr db	03,34,'               $'
msgdpc	  db	05,42,'D2A$'
msgopen   db	06,38,'   OPEN    $' ;@@XLAT
msgclose  db	06,38,'  CLOSED   $' ;@@XLAT
msgtime   db	07,41,'   0$'
msghotkey db	08,41,'   0$'
msgkbenb  db	09,38,'   NoDis   $' ;@@XLAT
msgkbdis  db	09,38,'    Dis    $' ;@@XLAT
cmdclr	  db	11,01,'                                                $'
cmdqry	  db	11,02,'Enter 1-5, UP/DN for printer, <RETURN> exits $ ' ;@@XLAT
dispqry   db	11,02,'Please enter new Disposition (D,S,H,I,N)  - $  ' ;@@XLAT
prioqry   db	11,02,'  Please enter new Priority   ( 0 - 9 )   - $  ' ;@@XLAT
clasqry   db	11,02,'  Please enter new Class      ( A - Z )   - $  ' ;@@XLAT
timeqry   db	11,02,' Enter new Spooler close time          - $     ' ;@@XLAT
htkyqry1  db	11,02,'Press the key you want for the new HotKey. $   ' ;@@XLAT
htkyqry2  db	11,02,'Press the key AGAIN to verify your choice. $   ' ;@@XLAT
htkyok	  db	11,02,'HotKey VERIFIED.  Any key to continue.     $   ' ;@@XLAT
htkyerr   db	11,02,'HotKey NOT VERIFIED. Any key to continue.  $   ' ;@@XLAT
msgclsd   db	11,02,' Spooler closed.  Press a key to continue. $   ' ;@@XLAT
curprntr  dw	0			; current printer to update
tcbseg	  dw	0			; tcb segment
splseg	  dw	0			; spool header segment
ten	  dw	10			; for decimal <=> binary
one82	  dw	182			; 18.2 ticks / second

	page
;---------------------------------------------------------------------------
; int 16 keyboard interrupt monitor for popup
; this routine is the intercept routine for the bios keyboard interrupt
; (16h).  it will simply check keys coming from the keyboard for the hotkey
; and if found will display a menu and allow the user to select spooler
; parameters.
;-----------------------------------------------------------------------
	ASSUME	CS:code, DS:nothing, ES:nothing

keybint:
        cmp     [spl16],'Y'             ; is int 16 intercept enabled?
	jne	skip16
	cmp	ah,1			; get key or get status?
	jb	kybiget 		; keyboard read
	je	kybistat
skip16:


	cmp	ah,11h
	je	kybistat
	cmp	ah,10h
	je	kybiget


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





;-----------------------------------------------------------------------
; kybitst test the key in ax is our hotkey
; enter:	ax = scan code, key code from int 16 call
; exits:	nz if not hotkey
;		zr if our hotkey was processed (ax restored to [keybax])
;-----------------------------------------------------------------------
kybitst:
	push	ax
	cmp	al,0e0h
	jne	kbixe0
	xor	al,al
kbixe0:
	cmp	ax, [hotkey]
	pop	ax

	je	kybigot
	ret				;Hotkey not found.
kybigot:
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
	ASSUME	DS:code, ES:code
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

; macro to define key/routine table

splvect macro	char, rout
	dw	char
	dw	offset rout
	endm

splfuncs label	word
	splvect CR,doexit	    ; cr to exit spooler popup
	splvect ESC_KEY,doexit		; esc to exit popup
	splvect '1',dodpc
	splvect '2',doclose
	splvect '3',dotime
	splvect '4',dohotkey
	splvect '5',dokbpoll
	splvect DOWN,nextlpt
	splvect PGDN,nextlpt
	splvect UP,prevlpt	    ; arrow keys to change stream/printer
	splvect PGUP,prevlpt
	dw	0

spool:
	lea	di,scrnsave
	mov	dh,WINROW
	mov	dl,WINCOL
	mov	ch,WINROWS
	mov	cl,WINCOLS
	call	savescrn		; save their screen area
	lea	si,window		; display our screen
	mov	bl,WINATTR		; our screen 'savescrn' format
	call	rstrscrn		;   so it is displayed by 'rstrscrn'
	mov	ax,[splseg]
	add	ax,spldoff		; (offset spldata) shr 4
	mov	es,ax			; es => 1st spool data buffer seg
	ASSUME	ES:SPLBUFF
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

; exit from loop when <cr> or <esc> is pressed.
; called from statement above.

doexit:
	pop	ax			; pop call return address off stack
	lea	si,scrnsave
	call	rstrscrn		; put their screen area back
	ret

; splkey get a key from the previous handler

splkey:
	xor	ah,ah			; get a key
	pushf
	call	[keybvct]		; call regular kb routine
	ret

; dodpc update spooling disposition, priority, class

dodpc:
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
	mov	[splb.filname+spldisp],al ; set new disp
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
	mov	[splb.filname+splprio],al ; set new pri
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
	mov	[splb.filname+splclas],al ; set new class
dodpcxit:				; fall into display routine

; dispdpc display spooler dpc in window

dspdpc:
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

; dokbpoll change setting of keyboard polling

dokbpoll:
	push	ds
	mov	ds,[tcbseg]
	ASSUME	DS:tcb
	xor	[tcbloop],1		; flip the dis mode bit
	pop	ds

; fall into display routine

dspkbpoll:
	push	ds
	mov	ds,[tcbseg]
	mov	al,[tcbloop]
	pop	ds
	ASSUME	DS:code
	lea	si,msgkbdis
	test	al,1			; get dis bit
	jnz	dspkbdis
	lea	si,msgkbenb
dspkbdis:
	call	disp
	ret

; dohotkey change spooler hotkey value

dohotkey:
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
dsphotkey:
	mov	ax, [hotkey]
	mov	cx,4			; display hotkey value
	lea	di,msghotkey+2
        call    itoh                    ;Produce hexadecimal value.
	lea	si,msghotkey
	call	disp
	ret

; returns hotkey scancode and shift mode in ax

hotkeyget:
	call	dispclr 		; display message
	call	splkey			; get a key
	ret

; doclose close the current spool file

doclose:
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
dspclose:
	lea	si,msgclose
	cmp	[splb.handle],-1
	je	dspclosdsp
	lea	si,msgopen
dspclosdsp:
	call	disp
	ret

; dotime changes spool file close timeout

dotime:
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

; fall into display routine

dsptime:
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

; prevlpt sets es => to the previous spool data segment

prevlpt:
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

; nextlpt sets es => to the next spool data segment

nextlpt:
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

; dsplpt displays the printers handled by spool buffer

dsplpt:
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

; dspfile display spool file pathname

dspfile:
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

; dspall displays all fields in the popup display

dspall:
	call	dspfile 		; display all variables
	call	dsplpt
	call	dspdpc
	call	dspclose
	call	dsptime
	call	dsphotkey
	call	dspkbpoll
	ret

;-----------------------------------------------------------------------
; savescrn stores a window in the current display
; enter:	es:di => buffer to save window 6+2*(rows*cols)
;		dh,dl top-left row/col
;		ch,cl rows, cols to save
; uses: 	ax, bx, cx, dx, di
;-----------------------------------------------------------------------
savescrn:
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

;-----------------------------------------------------------------------
; rstrscrn restores screen saved by savescrn
; enter:	ds:si => store screen from savescrn = [curscol], [cursrow],
;		[colmin], [rowmin], [colmax], [rowmax], attr, char.....
;		bl = attribute if [cursor] = -1
; uses: 	ax, bx, cx, dx, si, di, bp
; note: if [cursor] = -1, does not display attributes
;-----------------------------------------------------------------------
rstrscrn:
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

;-----------------------------------------------------------------------
; disp displays a '$' terminated string in the window
; enter:	ds:si => [rel row], [rel col], string to display, '$'
;		the first bytes are a relative row,col position
; uses: 	ax, si
; dispclr clears the command line and then displays the message
;-----------------------------------------------------------------------
dispclr:
	push	si			; save message addr
	lea	si,cmdclr
	call	disp			; clear command line display
	pop	si			; fall into display with message
disp:
	push	bx
	push	cx
	push	dx
	mov	dh,WINROW
	mov	dl,WINCOL
	add	dh,[si] 		; calc relative screen coordinates
	inc	si
	add	dl,[si]
	inc	si
	mov	bx,WINATTR		; page 0, color attribute
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

;-----------------------------------------------------------------------
; bintodec converts a binary number to a decimal string.
; enter:	ax = binary number
;		ds:di => buffer to place decimal string
;		cx = maximum chars in string
; uses: 	ax, cx, di
;-----------------------------------------------------------------------
bintodec:
	push	dx
	add	di,cx			; get to end of string
btdloop:
	xor	dx,dx
	div	[ten]
        add     dl, '0'
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

;-----------------------------------------------------------------------
; Function:     ITOH
;
; Description:  ITOH takes a binary value and outputs a character string
;               in hexadecimal to represent that value.
;
; Input:        AX      = Binary value to be displayed.
;               DS:DI   = Location to place the output string.
;               CX      = Max # of digits to be placed.
;
; Output:       None.  Routine uses AX, CX and DI
;
;-----------------------------------------------------------------------
itoh:
        rol     ax, 1           ;Put digit into position.
        rol     ax, 1
        rol     ax, 1
        rol     ax, 1
        push    ax              ;Save for a sec.
        and     ax, 000Fh       ;Mask out the digit of interest.
        cmp     al, 9           ;If 0-9, display '0' - '9' else 'A' - 'F'
        ja      @F
        add     al, '0'         ;Digit is '0' - '9'
        jmp short itoh_eol
@@:
        sub     al, 10          ;Digit is 'A' - 'F'
        add     al, 'A'
itoh_eol:
        mov     [di], al        ;Place the digit.
        inc     di
        pop     ax              ;Get remainder back.
        loop    itoh            ;Go for next digit.

        ret                     ;All done.

tsr     ends                            ; end of resident routines

;------------------------- initialization code -------------------------

	subttl	initialization code
	page

init	segment para
toknbuf   db	64 dup (0)		; buffer for command line token
printers  db	0			; contains bits of printers allocated
oldsplseg dw	0			; old spooler address

banner  db      'PC-MOS Print Spooler v4.11 (901220)',13,10
        db      '(C) Copyright 1987-1991 The Software Link Inc.',13,10
        db      'All Rights Reserved.',13,10,10,'$'

include copyrit.inc

	  db	13,10,'$'
msgrerun  db	'Spooler parameters modified.           ',13,10 ;@@XLAT
msgss	  db	'Super Spooler Menu available.          ',13,10,'$' ;@@XLAT
msgdflhk  db	13,10,'Spooler HotKey reset to Ctrl-Home       ','$' ;@@XLAT
msgpath   db	13,10,'Invalid path!   ',13,10,'$' ;@@XLAT
msgclbd   db	13,10,'Invalid Spool Closing Parameter.                  ',13,10,'$' ;@@XLAT
errbeep   db	7,'$'
srchpath  db	64 dup (0)		; filename initiating search
srchname  db	13 dup (0)
removed	db	'Spooler removed from memory',13,10,'$'		      ;@@XLAT	
spldisable db	'Spooler disabled',13,10,'$'			      ;@@XLAT	


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

	subttl	initilization - not retained in memory
	page
;---------------------------------------------------------------
;		user interface logic
;---------------------------------------------------------------
begin:

include verschk.inc

	mov	ax, cs
	mov	ds, ax			; DS=>CS
	ASSUME	DS:code
        lea     dx, banner
        call    display_string

	mov	ah, 4			; Get TCB address.
	mov	bx, -1			; For current task.
	int	SERVICES		; Go get it.
	ASSUME	ES:tcb
	mov	[tcbseg], es		; Save for later.
	mov	ax, [tcbspool]
	mov	[oldsplseg], ax
	mov	dx, [tcbid]
	or	ax, ax			; Spooler already loaded?
	jnz	chkremove
	jmp	setsplseg
chkremove:
;
;  If the user wants the spooler removed from memory, the
;  command 'SPOOL OFF' would have been issued.
;
	mov	si,offset cmdline+1
cofflp:
	lodsb
	cmp	al,13
        je      coffskip
	cmp	al,' '
	je	cofflp
	and	al,0dfh		; convert to uppercase
	cmp	al,'O'
	jne	cofflp
	mov	ax,word ptr ds:[si]
	inc	si
	and	ax,0dfdfh	; convert to uppercase
	cmp	ax,'FF'
	jne	cofflp
;
;	at this point we know that SPOOL OFF has been done
;	so now we will first ZAP tcbspool to zero 
;	and also set INT 16h back to normal vectors
;	
	mov	word ptr [tcbspool],0	; clear spooler from system
	mov	ax,3516h
	int	21h			; get vector for 16h
	cmp	bx,offset keybint	
	jne	NotOurs
;
;	INT 16h points to our interupt so we will
;	set it back to original INT 16	intercept
;
	mov	di,offset spl16
	mov	ds,word ptr es:[di+3]	; this points to previos int 16
	mov	dx,word ptr es:[di+1]
	mov	ax,2516h
	int	21h
;
;	free up memory to MOS for spool.com code and enviroment
;
	push	es
	mov	es,word ptr es:[2ch]
	mov	ah,49h
	int	21h
	pop	es
	mov	ah,49h
	int	21h
	lea	dx,removed
	jmp	short SplRem

NotOurs:
;
;	We have detected that someone has taken int 16 and we must 
;	now set flag to indicated that our INT 16 logic is disable
;	this will waste memory for spool.com tsr
;
	mov	ax,offset code:splsegbeg
	mov	cx,4
	shr	ax,cl
	mov	bx,[oldsplseg]
	sub	bx,ax
	mov	es,bx
	mov	di,offset spl16
	mov	byte ptr es:[di],'N'
	lea	dx,spldisable
	
SplRem:
	push	cs
	pop	ds
	mov	ah,9
	int	21h
	mov	ax,4c00h
	int	21h
	

coffskip:

; if rerun of spool clear default values from spool data
; then update old spool data with changed values

	mov	di, offset code:spldata
	mov	cx,offset code:splsegend
	sub	cx,di
	xor	ax,ax
clearspl:
	mov	[di],al 		; let's not change the ES register
	inc	di
	loop	clearspl

;
;  The new hotkey combination will be updated in the old spooler segment
;  from the temporary spool segment in this code segment.  Make sure
;  that the hotkey combination from the old segment is kept so it can
;  be restored.  If the user specifies a new one from the command line
;  or just entered SPOOL with no parameters, the local copy of the hot key
;  will be reset.  Then, when UPDATE gets it's hands on it the update will
;  contain the hotkey that was specified.
;
        push    es
        mov     es, [oldsplseg]
        ASSUME  es:spoolseg
        mov     ax, es:[hotkey]         ;Yank out of old spool seg.
        ASSUME  es:nothing
        pop     es
        mov     [hotkey], ax            ;Put in new seg.

setsplseg:				; get new spool data segment in es
	mov	ax,offset code:splsegbeg
	mov	cx,4
	shr	ax,cl
	mov	bx,cs			; compute spool data header segment
	add	ax,bx
	mov	[splseg],ax		; ax = new spooler segment
	add	ax,spldoff		; (offset spldata) shr 4
	mov	es,ax
	ASSUME	ES:splbuff
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
	call	display_string 		; write error string
	lea	dx,errbeep		; beep after error message
	mov	al,1			; exit with error
	call	display_string
	mov	ah,4ch			; exit
	int	21h
;-----------------------------------------------------------------------
; set the bios keyboard interrupt vector and exit with routines resident
; set the spool pointer in tcb
; set only after any aborts may terminate this prog before completion
;-----------------------------------------------------------------------
exittsr:
	mov	es,[tcbseg]
	ASSUME	ES:tcb
	mov	ax,[splseg]
	mov	[tcbspool],ax
	mov	al,KEYVECT
	mov	ah, 35h 		; Get keyboard interrupt vector.
	int	21h
	mov	word ptr [keybvct],bx	; and save for tsr chaining
	mov	word ptr [keybvct+2],es
	ASSUME	ES:nothing
	lea	dx,keybint		; set new keyboard interrupt routine
	mov	ah, 25h
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

;-----------------------------------------------------------------------
; parse digests the command line parameters
; exits:	ds:dx => error message (0 if none)
;-----------------------------------------------------------------------

errsyntx db	"Syntax Error $        " ;@@XLAT

parse:
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
        je      parsxit                 ; If not, exit loop.
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
	cmp	word ptr [oldsplseg], 0
	je	parsxit
        mov     [hotkey], DEFAULT_HOTKEY        ;UPDATE will move to old seg.
	lea	dx,msgdflhk		; display resetting hotkey
	call	display_string
parsxit:
	ret

        ASSUME  ES:splbuff
parswtch:				; with es => splbuff
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

errswitch db	"Unknown switch $       " ;@@XLAT

parswter:
        lea     dx, errswitch
	stc
	jmp	parsloop

;-----------------------------------------------------------------------
; dpc validates and sets file's Disposition, Priority, Class
; enter:	[toknbuf] contains dpc
;		cx contains token length
; exits:	cy if error
;		dx contains error message
;-----------------------------------------------------------------------
dpc:
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

errdisp db	"Invalid Disposition $     " ;@@XLAT

parsdisp:
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

errprio db	"Invalid Print Priority $        " ;@@XLAT

parsprio:
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

errclas db	"Invalid Print Class $        " ;@@XLAT

parsclas:
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

;-----------------------------------------------------------------------
; path validates spool directory path
; enter:	[toknbuf] contains pathname
;		di => terminator of pathname
; exits:	cy if error
;		bx = error message
;		nc
;		es:[splb.filpath] = right justified path
;		es:[splb.pathlen] = length of path
; there is a problem with sequence numbers if multiple directories
; are used.  but we will allow them this feature (bug).
;-----------------------------------------------------------------------
	ASSUME	ES:splbuff

errdrive db	'Must specify drive with spool directory $          ' ;@@XLAT
errpath  db	'Spool directory not found $           ' ;@@XLAT
errpaths db	'All files are spooled to same directory $           ' ;@@XLAT

path:
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
	mov	ah, 1Ah
	int	21h
	lea	dx,toknbuf		; validate path with open
	mov	cx,10h			; search for a directory
	mov	ah, 4Eh
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

;-----------------------------------------------------------------------
; key parses the spooler hotkey.  '/Kxxxx' gives the hexadecimal hotkey
; value
; enter:	cx = token length
;		ds:bx => argument string
; exits:	dx = error message if cy
;-----------------------------------------------------------------------

errkey	db	'Invalid hotkey number $        ' ;@@XLAT

key:
	jcxz	keyerr			; must specify number
        call    htoi
        jc      keyerr
        mov     [hotkey], dx            ; set initial popup hotkey
	ret
keyerr:
	lea	dx,errkey
	ret

;-----------------------------------------------------------------------
; sysname parse name switch  '/Nx'  sets hybrid system spool file name
; enter:	ax = character after '/N'
;		cx = token length
; exits:	dx = error message if cy
;-----------------------------------------------------------------------
	ASSUME	ES:splbuff

errname db	"Invalid Name switch $      " ;@@XLAT

sysname:
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

;-----------------------------------------------------------------------
; secure parse spool file security switch
; enter:	ax = character after '/S'
;		cx = length of switch argument
; exits:	dx = error message if cy
;-----------------------------------------------------------------------

errsecur db	"Unaccessable security class $      " ;@@XLAT

secure:
	lea	dx,errsyntx
	cmp	cx, 1
	ja	scurerx
	jb	scurblnk
;
;  No character was given.  Blank the security class.
;
	cmp	al,'_'			; test blank security
	je	scurblnk		; yes always good
	cmp	al,'A'			; validate security class
	jb	scurerr
	cmp	al,'Z'
	ja	scurerr
					; ensure allowable security
	push	es			; address tcb
	mov	es,[tcbseg]
	ASSUME	ES:tcb
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
	jmp short scurdone

scursto:				; store spool file security
	pop	es
	ASSUME	ES:splbuff

scurdone:
	mov	[splb.seclass],al
	clc
	ret
;-----------------------------------------------------------------------
; time sets spool file time out value
;-----------------------------------------------------------------------

errtime         db      "Timeout value error $         " ;@@XLAT
time_range      db      "Timeout value must be 1 to 3600 seconds.    $";@@XLAT

time:
	jcxz	timeerr
	call	dectobin		; get number
        jc      timeerr
        cmp     dx, 3600                ; BWR 10/18/90
        ja      time_too_large
	mov	ax,dx
	mul	[one82] 		; convert seconds to ticks
	div	[ten]
        cmp     dx, 0                   ;If remainder, increment 1 tick.
        je      @F
        inc     ax
@@:
	mov	[splb.timeout],ax	; set timeout value
	clc
	ret
timeerr:
        lea     dx, errtime
	stc
	ret

time_too_large:
        lea     dx, time_range
        stc
        ret

;-----------------------------------------------------------------------
; dectobin converts a decimal string to binary number
; enter:	ds:bx => decimal string
;		cx = length of string
; exits:	dx = string value
;		cy if invalid digit
;-----------------------------------------------------------------------
dectobin:
        xor     dx, dx                  ;Clear accumulator.
        xor     ax, ax                  ;Only using AL.
dtb_loop:
        mov     al, [bx]                ;Get next digit.
        cmp     al, 0                   ;End of string?
        je      dtb_exit
        inc     bx
        cmp     al, '0'                 ;In range? (0-9)
        jb      dtb_error
        cmp     al, '9'
        ja      dtb_error
        sub     al, '0'                 ;Convert from digit to numeric.
        push    bx
        mov     bx, dx
        shl     dx, 1                   ;Multiply DX*10.
        shl     dx, 1
        shl     dx, 1                   ;DX = DX*8
        shl     bx, 1                   ;BX = DX*2
        add     dx, bx                  ;DX = (DX*8) + (DX*2)
        pop     bx
        add     dx, ax                  ;DX = (DX*10) + AX.
        loop    dtb_loop
        jmp short dtb_exit

dtb_error:
        stc
dtb_exit:
        ret

;;;dectobin:
;;;        xor     dx,dx                   ; clear sum
;;;dtbloop:
;;;        xor     ax,ax                   ; clear digit
;;;        jcxz    dtbxit                  ; exit when finished
;;;        mov     al,[bx]
;;;        inc     bx                      ; get and validate char
;;;        dec     cx
;;;        cmp     al,'0'
;;;        jb      dtberr                  ; invalid char
;;;        cmp     al,'9'
;;;        ja      dtberr
;;;        and     al,15                   ; strip to digit value
;;;        push    ax
;;;        mov     ax,10                   ; multiply dx by 10
;;;        mul     dx
;;;        pop     dx                      ; restore digit value
;;;        add     dx,ax                   ; add to previous * 10
;;;        jmp     dtbloop
;;;dtberr:
;;;        stc
;;;dtbxit:
;;;        ret                             ; return with offending char in al

;-----------------------------------------------------------------------
; Function:     HTOI
;
; Description:  HTOI converts an input character string expressed as
;               hexadecimal into its binary equivalent.
;
; Input:        DS:BX   = Hexadecimal (ASCIIZ) string to be converted.
;               CX      = Max length of string.
;
; Output:       DX      = Value of input string.
;               Carry   = Set on invalid digit error.
;
; Note:         The usage of CX should be redundant.  Remove its usage
;               after determining if it's needed by routines calling
;               HTOI.
;
;-----------------------------------------------------------------------
htoi:
        xor     dx, dx          ;Clear accumulator.
        xor     ax, ax          ;Only use AL.
htoi_loop:
        mov     al, [bx]        ;Get next digit from string.
        inc     bx
        cmp     al, 0           ;End of ASCIIZ string?
        je      htoi_exit       ;If so, get out.
        cmp     al, '0'         ;Check the digit range. (0-9, A-F)
        jb      htoi_error
        cmp     al, '9'
        ja      @F
;
;  Hex digit '0' - '9'
;
        sub     al, '0'
        jmp short htoi_add
@@:
        cmp     al, 'A'
        jb      htoi_error
        cmp     al, 'F'
        ja      htoi_error
        sub     al, 'A'
        add     al, 10
htoi_add:
        shl     dx, 1           ;Make room for next digit.
        shl     dx, 1
        shl     dx, 1
        shl     dx, 1
        add     dx, ax          ;Add to least signifigant digit.
        loop    htoi_loop
        jmp short htoi_exit

htoi_error:
        stc
htoi_exit:
        ret

;-----------------------------------------------------------------------
; lpt stores line printer bit in current spool data buffer.
; validates printer number.
; adds printer bit to [printers], which printers buffered
; bumps spool data segment pointer (es) to next buffer.
; copies values in old data buffer to new buffer.
;-----------------------------------------------------------------------
	ASSUME	ES:splbuff

errlpt	db	"Invalid LPT $      " ;@@XLAT

lpt:
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
	ASSUME	DS:splbuff
	push	si			; move current parmeters to new data seg
	push	di
	xor	si,si
	mov	di,si
	mov	cx,size spldata
	rep	movsb
	pop	di
	pop	si
	pop	ds			; restore data segment
	ASSUME	DS:code
lptxit:
	clc				; return without error
	ret
lpterr:
	lea	dx,errlpt		; invalid lpt number
	stc
	ret

;-----------------------------------------------------------------------
; token scans a space,tab,comma,slash delimited token
; enter:	ds:si => source buffer
;		ds:di => destination buffer
;		cx = length of source
;
; exits:	ds:di => null terminating token
;	        ds:si => character after delimiter
;	        cx = updated source length
;	        al = delimiter char
;-----------------------------------------------------------------------
token:
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

;-----------------------------------------------------------------------
; lastfile scans directory in es = splbuff for highest/latest file
; if spntt999.xxx is found returns latest spool sequence
; else returns highest spool sequence
;-----------------------------------------------------------------------
lastfile:
	lea	dx,finds		; set dta to find structure
	mov	ah, 1Ah
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
	mov	ah, 4Eh
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
	mov	ah, 4Eh
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
	mov	ah, 4Fh
	int	21h
	jmp	lstfllup
lstfmost:				; get largest sequence num
	mov	ah, 4Eh
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
	mov	ah, 4Fh
	int	21h
	jmp	lstfmlup
lstfxit:
	ret

;-----------------------------------------------------------------------
; update update the old spool data with the new parameters.
; enter:	[oldsplseg] => spool data segment from initial spool command
;		[splseg] => new cleared data segment so only changes are non-null
; exits:	changes stored in the corresponding old spool data
;-----------------------------------------------------------------------
update:
	push	ds
	push	es
	mov	es,[oldsplseg]
	mov	ds,[splseg]
	ASSUME	DS:spoolseg, ES:spoolseg
;
;  Update the hot-key.
;
        mov     ax, [hotkey]
        mov     es:[hotkey], ax

updlpts:				; for all current lpts update old data segment
	mov	ax,ds
	add	ax,spldoff		; get to data segment
	mov	ds,ax
	ASSUME	DS:splbuff
updloop:				; loop for all printers
	mov	al,[splb.printer]
	or	al,al
	je	updxit			; finished with all printers
	call	findold 		; find corresponding old data segment
	jc	updlnext		; couldn't find??
	ASSUME	ES:splbuff
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

;-----------------------------------------------------------------------
; findold finds the spool buffer for the given printer
; enter:	al = printer bits of new spool buffer
;		ds => new splbuff
; exits:	es => old splbuff or cy if not found
;-----------------------------------------------------------------------
	ASSUME	DS:splbuff
findold:
	mov	dx,[oldsplseg]		; get old base spool segment
	add	dx,spldoff		; (offset spldata) shr 4
findolup:
	mov	es,dx
	ASSUME	ES:splbuff
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

;-----------------------------------------------------------------------
; dsplstr outputs a '$' terminated string to standard output
; enter:	ds:dx => message
; saves:	all
;-----------------------------------------------------------------------
dsplstr:
	push	ax
	mov	ah, 9
	int	21h
	pop	ax
	ret

;-----------------------------------------------------------------------
; display_string outputs a string and then cr,lf to standard output
; enter:	ds:dx => message
; saves:	all
;-----------------------------------------------------------------------

crlf    db      13,10,'$'

display_string:
	call	dsplstr
	push	dx
	lea	dx,crlf
	call	dsplstr
	pop	dx
	ret

init    ends
	end	start
