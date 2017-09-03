	include page.inc

	include shgraph.inc		; to define conditional assembly of
					; pcterm, emulink, or at&t driver

ifdef	pcterm
	title	pcterm.sys (v4.00) - mos pc shadow terminal driver modul
endif

ifdef	emulink
	title	elterm.sys (v4.00) - mos emulink terminal driver module
endif

ifdef	att
	title	atterm.sys (v4.00) - mos at&t 605 terminal driver module
endif

comment ^---------------------------------------------------------------
		development specification

 program name:	mosddtsh.asm	assigned to: rod girod
 module name:	mosddtsh	assign date: 05/09/88
 entry points:	shterm		completed:   05/25/88
 entry from:	mosint10, mosint16, mosvidrm
 entry method:	call dword [vector] with ah = function number
 calls:		i10old (boot interrupt 10h)
 purpose:	mos interface to pc terminal, emulink and at&t 605.
 refer to:	n/a
 last update:	n/a

 this module is the mos terminal driver for the pc (shadow) terminal,
 emulink, and the at&t 605.

 this driver will support:
   1.	the pc (shadow) terminal with xpc protocol and without graphics
	and color.
   2.	emulink with xpc protocol and with graphics and color.
   3.	the at&t 605 terminal with xpc protocol and without graphics
	and color.

 the driver will be opened by mositask which will read a four byte
 vector to the function interpretation code

-----------------------------------------------------------------------

rdg 08/18/88	corrected setct1 so that it saved the currently selected
  rg8231	  cursor style (like it used to) so as to prevent
		  constant setting of the cursor style.
		corrected wrcha1 - wrcha3 so as to not corrupt the stack
		  when a write is requested that is writing data that is
		  already in the screen buffer at the designated locatio
		corrected wrcho1 - wrcho3 so as to not corrupt the stack
		  when a write is requested that is writing data that is
		  already in the screen buffer at the designated locatio

rdg 09/27/88	corrected setcp1 and setcp2 for emulink because emulink
  rg8271	  does not support forward space or backspace

rdg 11/29/88	modified setcursor to use only direct cursor addressing
  rg8334	  for emulink.	emulink will not function properly if
		  more efficient cursor positioning is used.
		modified sup12 and sdn12 so that the vacated line is
		  rewritten for emulink.  emulink appears to have a
		  sporadic problem with setting the correct attribute
		  during insert and delete line commands
		corrected suclrb1 so that the lines cleared were the
		  right ones.
		corrected wrstr so that emulink modes 7 and above
		  position the cursor and initialize di
		corrected wrstrg because emulink uses different values
		  in its cursor position command when in graphics mode.
		modified wrstrg1 because emulink does not currently
		  support data compression

rdg 02/17/89	added storage of the flags on the stack in shterm so
  rg9048	  that flag conditions can be returned to the caller.
		modified inkbdata to return the carry flag set if the
		  terminal has disconnected (carrier dropped).

rdg 03/30/89	modified register (reg3) to check if any flow control
  rg9089	  was configured at startup, and to not force xpc flow
		  control if something was configured at startup.

rdg 05/01/89	modified scrollup and scrolldn to take advantage of
  rg9121	  emulink's ability to do the scrolling locally.
		modified wrstr to use emulink's repeat character
		  function.

rkg 07/17/89	added function 18 to terminal driver for keyb status

mjs 09/14/89	modified the check character function call to flush
		0feh and 0ffh calls as well as null codes.  this was
		done to accomodate Stargate's cluster controller.

SAH 10/17/89	Correct Cursor off control, ESC . 0 instead ESC . 7  

CBK 11/22/89	Removed setting of SI for function 14 calls 1 & 2
		removed block of Emulink using repeat writes in graphics mode
		Emulink pass 0ffh to clear screen when receives an fdh.

BWR 11/28/89	Marked messages for foreign language translation.

cbk 01/31/89	added scan code verification to inkbdata for EMULINK

SAH 02/02/90	Corrections for revelations technologies and scrolling
		a single line

mjs 03/20/90	modified register to call int14fun23 and to call 
		int14fun11 if any error during register.  this was done
		to accomodate stargate's cluster controller.

cbk 05/01/90	modified setwindow to pass Emulink graphic lines to
		wrstrg one line at a time.  Changed setmode to send
		escape seq for mode 640X320.

cbk 06/06/90	commented out an invalid test from port register that 
		was resetting protocol when it shouldn't
cbk 06/13/90	Changed register port logic to include CD/auto reboot 
		that may have been done in serial driver when it sets 
		port protocol. 

cbk 08/03/90	Changed set cursor routine to not do cursor right for
		AT&T (705 doesn't handle it & according to tech specs
		neither does the 605).
----------------------------------------------------------------------^

	subttl	group segments and include block definitions
	page

	include mosddtsh.pub

;-----------------------------------------------------------------------
; tcbcondd device driver data structure
;-----------------------------------------------------------------------
ddtrec	struc				; tcbcondd device driver info
	dd	?			; ? seg:off ?
logscr	dd	?			; seg:off of current screen data
crsofs	dw	?			; current cursor offset
cols	db	?			; screen width in columns
port	dw	?			; port address of device
baud	dd	?			; initialization parameter
attrib	db	?			; currently set attribute
cursor	dw	?			; row/col of cursor location
tmode	db	?			; terminal monitor/print mode
drvf	db	?			; driver functionality level
string	db	8 dup(0)		; was  used in prior versions
tmpatr	db	?			; used by scrolling code
mode	db	?			; video hardware mode
crstyp	dw	?			; cursor style (start/stop scan)
trmlmod	db	0			; Emulink's scan code chk value
	db	0			; unused
ddtrec	ends

;-----------------------------------------------------------------------
; bit definitions of [si].tmode
;-----------------------------------------------------------------------

monitor equ	00000010b	; monitor mode flag
print	equ	00000001b		; print mode flag

ddt	segment para public 'data'	; to force loading with data
	assume	cs:ddt,ds:nothing,es:nothing,ss:nothing


mosddtsh equ	this byte
	dd	-1			; pointer to next driver
	dw	8000h			; character device flag
	dw	strat			; device strategy entry point
	dw	inter			; device interrupt entry point

ifdef	pcterm
	db	'$$PCTERM'		; pcterm device name
endif

ifdef	emulink
	db	'$$ELTERM'		; emulink device name
endif

ifdef	att
	db	'$$ATTERM'		; at&t device name
endif



	subttl	device driver strategy routine
	page
;-----------------------------------------------------------------------
; device driver strategy routine entry point
;-----------------------------------------------------------------------
request dd	0			; seg:off of request header

strat	proc	far
	mov	word ptr [request], bx	; store offset of request
	mov	word ptr [request+2], es; store segment of request
	ret				; return from strategy routine
strat	endp

	subttl	device driver interupt routine
	page
;-----------------------------------------------------------------------
; device driver interupt routine
;-----------------------------------------------------------------------
fn	dw	ddtinit 		; 0 - init
	dw	ddtnull 		; 1 - media check
	dw	ddtnull 		; 2 - build bpb
	dw	ddtnull 		; 3 - ioctl input
	dw	ddtread 		; 4 - read
maxfn	equ	($-fn)/2

;-----------------------------------------------------------------------
; device driver interupt routine entry point
;-----------------------------------------------------------------------
inter	proc	far
	push	es			; save
	push	ds			;  these
	push	si			;   registers
	push	bx			;    for
	push	ax			;     restoration
	mov	bx, cs			; our segment to bx
	mov	ds, bx			; set ds to our segment
	assume	ds:ddt
	mov	ax, 00100h		; initial return status
	les	bx, [request]		; set es:bx to the request
	mov	si, es:[bx+2]		; get the command code in si low
	and	si, 0ffh		; clear the high byte
	cmp	si, maxfn		; is it a valid request
	jae	inter1			; jump if no
	shl	si, 1			; convert to a word offset
	call	fn[si]			; call the routine
	assume	ds:nothing
inter1:
	les	bx, [request]		; point es:bx to request block
	mov	es:[bx+3], ax		; store result status
	pop	ax			; restore
	pop	bx			;  the
	pop	si			;   corrupted
	pop	ds			;    registers
	pop	es
	ret				; return
inter	endp

;-----------------------------------------------------------------------
; device driver processing for media check, build bpb, and ioctl
;-----------------------------------------------------------------------
ddtnull proc	near
	mov	ax, 00100h		; return no error, done
	ret				; return to caller
ddtnull endp

;-----------------------------------------------------------------------
; device driver processing for input (read) - returns the terminal
;					      function vector
;-----------------------------------------------------------------------
ddtread proc	near
	lds	si, es:[bx+14]		; set ds:si from request block
	mov	cx, es:[bx+18]		; set cx from request block
	mov	word ptr es:[bx+18], 0	; nothing read if error
	mov	ax, 08103h		; error, done, unknown command
	cmp	cx, 4			; ??????
	jne	ddtrd1			; if not reading exactly 4 bytes
	mov	es:[bx+18], cx		; else read 4 bytes
	mov	word ptr ds:[si], offset shterm  ; store offset of shterm
	mov	ds:[si+2], cs		; and the segment
	mov	ax, 00100h		; no error, done
ddtrd1:
	ret				; return to caller
ddtread endp

	subttl	termfn - all the terminal and keyboard functions for mos
	page

if	0 eq 0				; no publics for ps
;-----------------------------------------------------------------------
; stack data buffer definitions
;-----------------------------------------------------------------------

databuf equ	(byte ptr [bp]) 	; bytes to send to serial.sys
ifndef	emulink
bufsiz	equ	64			; allocate 64 bytes for buffer
else
bufsiz	equ	128
endif
;-----------------------------------------------------------------------
; stack register save definitions
;-----------------------------------------------------------------------

ddes	equ	(word ptr [bp+bufsiz+00])  ; storage
ddds	equ	(word ptr [bp+bufsiz+02])  ;  for
ddsi	equ	(word ptr [bp+bufsiz+04])  ;   all
dddi	equ	(word ptr [bp+bufsiz+06])  ;	registers
ddbp	equ	(word ptr [bp+bufsiz+08])  ;	 corrupted
dddx	equ	(word ptr [bp+bufsiz+10])  ;	  by
dddl	equ	(byte ptr [bp+bufsiz+10])  ;	   the
dddh	equ	(byte ptr [bp+bufsiz+11])  ;	    terminal
ddcx	equ	(word ptr [bp+bufsiz+12])  ;	     drivers
ddcl	equ	(byte ptr [bp+bufsiz+12])
ddch	equ	(byte ptr [bp+bufsiz+13])
ddbx	equ	(word ptr [bp+bufsiz+14])
ddbl	equ	(byte ptr [bp+bufsiz+14])
ddbh	equ	(byte ptr [bp+bufsiz+15])
ddax	equ	(word ptr [bp+bufsiz+16])
ddal	equ	(byte ptr [bp+bufsiz+16])
ddah	equ	(byte ptr [bp+bufsiz+17])
ddfl	equ	(byte ptr [bp+bufsiz+18])
endif

;-----------------------------------------------------------------------
; macro to insure that enuf room is available in the stack buffer
;-----------------------------------------------------------------------
ifroom	macro	bytes			; check for enuf room in buffer
	local	llabel			; set a local label
	cmp	di, bufsiz-bytes	; have we got enuf room
	jb	llabel			; return if yes
	call	senddata		; send the data to serial.sys
llabel:
	endm

;-----------------------------------------------------------------------
; macro to insure the terminal is in normal mode
;-----------------------------------------------------------------------
setnorm macro			; terminal must be in normal mode
	local	llabel			; set a local label
	cmp	[si].tmode, 0		; are we in normal mode
	je	llabel			; return if yes
	call	notmonitor		; reset monitor or print mode
llabel:
	endm

;-----------------------------------------------------------------------
; macro to perform simulate int14
;-----------------------------------------------------------------------

int14h	dd	0			; segment:offset of serial.sys

do14h	macro				; simulate an int 14
	pushf				; save the flags
	cli				; inhibit interupts
	call	cs:int14h		; far call to serial.sys
	endm

ifdef	att				; at&t unique command sequences
;-----------------------------------------------------------------------
; at&t 605 terminal commands
;-----------------------------------------------------------------------

ceos	   db	4,1bh,'[0J'		; erase to end of screen
ceoln	   db	4,1bh,'[0K'		; erase to end of line
insertline db	4,1bh,'[1L'		; insert line
deleteline db	4,1bh,'[1M'		; delete line
linecursor db	12,1bh,'[?25;11;12h'    ; set underline cursor
boxcursor  db	15,1bh,'[?25;12h',1bh,'[?11l' ; set block cursor
nocursor   db	6,1bh,'[?25l'		; turn off cursor
printon    db	4,1bh,'[5i'	; turn on transparent print mode
printoff   db	4,1bh,'[4i'		; turn off transparent print mode

else					; emulink/pcterm unique command
;-----------------------------------------------------------------------
; pc terminal and emulink terminal commands
;-----------------------------------------------------------------------

ceos	   db	2,1bh,'Y'		; erase to end of screen
ceoln	   db	2,1bh,'T'		; erase to end of line
insertline db	2,1bh,'E'		; insert line
deleteline db	2,1bh,'R'		; delete line
linecursor db	3,1bh,'.6'		; set underline cursor
boxcursor  db	3,1bh,'.5'		; set block cursor
nocursor   db	3,1bh,'.0'		; turn off cursor
printon    db	2,1bh,'`'	; turn on transparent print mode
printoff   db	2,1bh,'a'		; turn off transparent print mode
endif

ifdef	emulink 			; emulink unique command sequence
;-----------------------------------------------------------------------
; emulink graphics commands
;-----------------------------------------------------------------------

gr640	db	2,1bh,'b'		; set 640x200 graphics
gr320	db	2,1bh,'c'		; set 320x200 graphics
grtext	db	2,1bh,'d'		; set graphics text
endif

;-----------------------------------------------------------------------
; console device (terminal) function table
;-----------------------------------------------------------------------

tfn	dw	register		; func 00 - register a port
	dw	inkbdata		; func 01 - input keyboard scan
	dw	outkbctl		; func 02 - clear current scan c
	dw	setmode 		; func 03 - set terminal mode
	dw	setcrstyp		; func 04 - set cursor type
	dw	setcrspos		; func 05 - position the cursor
	dw	scrollup		; func 06 - scroll screen up
	dw	scrolldn		; func 07 - scroll screen down
	dw	wrchatr 		; func 08 - write char and attrb
	dw	setpalet		; func 09 - set color palette
	dw	wrtty			; func 10 - write tty
	dw	wrstr			; func 11 - write a string of ch
	dw	setwindow		; func 12 - redisplay window
	dw	wrcho			; func 13 - write character
	dw	readch			; func 14 - read character/attrb
	dw	getscr			; func 15 - get screen
	dw	prch			; func 16 - send char to printer
	dw	prstr			; func 17 - send string to print
	dw	keybstat		; func 18 - get/set keyboard status
endtfn	equ	($-tfn)/2

;-----------------------------------------------------------------------
; console device (terminal) primary entry point
;-----------------------------------------------------------------------
	assume	ds:nothing,es:nothing,ss:nothing
shterm	proc	far
	pushf				; save flags so we can modify
	push	ax			; save
	push	bx			;  all
	push	cx			;   pointers
	push	dx			;    registers
	push	bp			;     and
	push	di			;      segments
	push	si			;	for
	push	ds			;	 later
	push	es			;	  restoration
	cmp	ah, endtfn		; does he want a valid function
	jae	termfn1 		; exit if no
	sub	sp, bufsiz		; allocate buffer on the stack
	mov	bp, sp			; set bp to location of the buff
	mov	di, 0			; initlalize count of data
	mov	bl, ah			; function code to bl
	xor	bh, bh			; convert to word
	shl	bx, 1			; make word offset for table
	call	tfn[bx] 		; call the desired function
	add	bp, bufsiz		; deallocate the buffer
	mov	sp, bp			; reset the stack pointer
termfn1:
	pop	es			; restore
	pop	ds			;  all
	pop	si			;   of
	pop	di			;    his
	pop	bp			;     registers
	pop	dx			;      and
	pop	cx			;	return
	pop	bx			;	 information
	pop	ax
	popf				; retrieve the modified flags
	ret				; return to who called us
shterm	endp

	subttl	register - register port address, receive key buffer flag
	page
;-----------------------------------------------------------------------
; register - register port address, receive key buffer flag
;
;   ah = 00h
;     dx = port address
;     ds:si -> tcbddt for this terminal for this partition
;
;   returns:
;     [ddes]:[ddbx] -> key buffer flag
;		       key buffer flag is <> 0 while scan codes buffered
;     [ddal] = 80h if master console
;	       40h if terminal with graphics (emulink)
;	       00h if terminal
;     [ddah] = 0 if no error
;	     = 1 if bad port number
;	     = 2 if bad baud rate
;-----------------------------------------------------------------------
if	0 eq 0				; no publics for ps

; status return definitions

badprt	equ	1			; bad port number
badbau	equ	2			; bad baud rate
endif

; register the port

	assume	ds:nothing,es:nothing,ss:nothing
register:
	cmp	word ptr [int14h+2], 0	; is this our first time thru
	jne	reg1			; skip it if yes
	push	ds			; save ds
	xor	ax,ax			; zero ax
	mov	ds,ax			; set ds to interupt vector segm
	lds	ax, dword ptr ds:[14h*4]; get segment:offset of int 14
	mov	word ptr [int14h], ax	; store the offset
	mov	word ptr [int14h+2], ds ; and the segment
	pop	ds			; restore ds
reg1:
	mov	[si].cursor, -1 	; initialize the cursor location
	mov	[si].attrib, -1 	; initialize the current attribu
	mov	[si].crstyp, -1 	; initialize the cursor style
	mov	[si].tmode, -1		; initialize the current mode
	mov	[si].drvf,0		; initialize driver functionality
	mov	dx, [si].port		; get the port address
	mov	ah, 13			; register the port
	do14h				; call serial.sys
	or	ah, ah			; is all ok
	jz	reg2			; continue if yes
	mov	[ddah], badprt		; show bad port address
	jmp	reg5			; no need to continue
reg2:
	mov	[ddes], es		; store segment of keyboard flag
	mov	[ddbx], bx		; store offset of keyboard flag

; this is done for the sake of Stargate's cluster controller.
; it must be done right after the function 13 call.
; after this call, if any errors within this ddt register function, must
; call int14 function 11 to disable the port.  this is required so that
; the cluster controller driver can know it should deallocate its resources.

	mov	bx,ds
	mov	dx, [si].port		; get the port address
	mov	ah,23
	do14h				; register ownership

	mov	dx, [si].port		; get the port address
	mov	bx, word ptr [si].baud	; get the extended baud rate
	mov	cx, word ptr [si].baud+2; " " " " " " " " " " " " "
	mov	ah, 4			; extended port init
	mov	al, 003h		; 8 data, 1 stop, no parity
	do14h				; call serial.sys
	or	ah, ah			; is all ok
	jz	reg3			; continue if yes
	mov	[ddah], badbau		; invalid baud rate selection
	jmp	reg5x			; exit if unable to initialize
reg3:
	mov	ah, 12			; get the current setup
	mov	dx, [si].port		; get the port address
	do14h				; call serial.sys
;;;;;;	cmp	ah, 12			; was it done	(060690)
;;;;;;	je	reg3a			; set xpc if no	(060690)
	test	ah, 00fh		; is any flow control configured
	jnz	reg4			; leave as is if yes
	mov	al, 003h		; set xon/xoff
	and	ah, 030h		; jump if no connection
	cmp	ah,0
	je	reg3a			;  info
	or	al, ah			; else or in connection info
	or	al, 080h		; or in change CD bit
reg3a:
	mov	ah, 5			; set line protocol
	mov	bh, 067h		; xoff character
	mov	bl, 065h		; xon character
	mov	dx, [si].port		; get port address
	do14h				; call serial.sys
reg4:
	mov	[ddah], 0		; no errors
	mov	ah, 6			; driver id function
	mov	dx, [si].port		; get the port address
	do14h				; call the driver
	or	ah, ah			; did he do this right
	jns	reg5			; leave character mode if no
	cmp	al, 14			; does it support string output
	jb	reg5			; jump if no string output
	mov	[si].drvf, 0ffh 	; show string output ok
	jmp	short reg5
reg5x:
	mov	ah,11			; if any error after register
	mov	dx,[si].port		; ownership, disable the port
	do14h
reg5:

ifdef	emulink
	mov	[ddal], 040h		; graphics, but not master conso
else
	mov	[ddal], 000h		; no graphics for pcterm
endif
	ret

	subttl	inkbdata - input keyboard scan code
	page
;-----------------------------------------------------------------------
; inkbdata - input keyboard scan code
;   ah = 01h
;     ds:si -> tcbddt
;
;   returns:
;     [ddal] = bit  7	- key break if 1, key make or key repeat if 0
;	       bits 6-0 - key scan code 01h - 07dh
;     [ddfl]   cy = 1 if terminal has disconnected (carrier dropped)
;	       cy = 0 if all normal
;     key scan code is read non-destructively (unless a null is found)
;-----------------------------------------------------------------------
	assume	ds:nothing,es:nothing,ss:nothing
inkbdata:
	and	[ddfl], not 001h	; initialize the carry flag
	mov	dx, [si].port		; get the port address
	mov	ah, 8			; input status check
	do14h				; call serial.sys
	jnz	kbdat1			; jump if we got a character
	jnc	kbdat0			; jump if terminal still there
kbgone:	or	[ddfl], 001h		; show the terminals is gone
kbdat0:
	mov	[ddal], 0		; show mos nothing there
	ret				; return to caller
kbdat1:
	or	al, al			; if read a 0, 0feh or 0ffh
	jz	kbdat1a			; then flush the char

ifdef	emulink	       			;EMULINK is doing scan code verifying
	cmp	al, 0fbh		; turn off ascii mode
	jne	kbdata00
	mov	[si].trmlmod, 0
	jmp	short kbdat1a		
kbdata00:
	cmp	al, 0fch
	jne	kbdata05
	mov	[si].trmlmod, al	; mark ascii mode
	jmp	short kbdat1a		
kbdata05:
	cmp	al,0fdh			; emulink uses 0fdh
	jne	kbdata10
	mov	al,0ffh
	jmp	kbdat2		; to get screen refresh
kbdata10:
	cmp	al, 0efh
	ja	kbdat1a
	mov	bh, [si].trmlmod
	cmp	bh, 0fch		; ascii mode does no checking
	je	kbdat2			;  but just passes char on
	cmp	bh, 0			; if haven't rcvd check byte
	je 	kbdata15	       	;  go chk if this is one
	and	bh, 0fh			; else go compare the two
	jmp	cdcomp
kbdata15:
	mov	bh, al			; has to be a scan check code
	and	al, 0f0h
	cmp	al, 0e0h
	jne	kbdat1a			;  else ignore it as noise
	and	bh, 0fh
	mov	dx, [si].port		; get the port address
	mov	ah, 2			; read a character(clear scan cd ck)
	do14h				; call serial.sys

	mov	ah, 8			; input status check
	do14h				; call serial.sys
	jc	kbgone
	jnz	cdcomp
	or	al, bh
	mov	[si].trmlmod, al       	; save the scan code check byte
	xor	al, al			
	jmp	short kbdat2		;  and return no char
cdcomp:
	mov	[si].trmlmod, 0		; kill the scan code chk byte
	mov	bl, al
	mov	dl, al
	shr	dl, 1			; move hi nibble to low
	shr	dl, 1
	shr	dl, 1
	shr	dl, 1
	and	bl, 0fh			; get rid of hi nibble
	xor	bl, dl
	cmp	bl, bh			; ignore char if doesn't
	jne	kbdat1a			;  match scan code ck byte 

endif

	cmp	al,0feh			; and return a null code
	jb	kbdat2
kbdat1a:
	mov	dx, [si].port		; get the port address
	mov	ah, 2			; read a character(clear the null)
	do14h				; call serial.sys
	xor	al, al			; clear the character
kbdat2:
	mov	[ddal], al		; store the character
	ret				; return to caller

	subttl	outkbctl - clear current scan code from terminal driver
	page
;-----------------------------------------------------------------------
; outkbctl - clear current scan code from terminal driver
;
;   ah = 02h
;     al = bit	7   - clear buffered scan code if 1, ignored if 0
;	   bits 6-0 - ignored
;     ds:si -> tcbddt
;-----------------------------------------------------------------------
	assume	ds:nothing,es:nothing,ss:nothing
outkbctl:
	test	al, 080h		; should we clear the character
	jz	kbctl1			; return if no
	mov	dx, [si].port		; get the port address
	mov	ah, 2			; read character
	do14h				; call serial.sys
kbctl1:
	ret				; return to caller

	subttl	setmode - set terminal mode
	page
;-----------------------------------------------------------------------
; setmode - set terminal mode
;
; ah = 03h
;   al = 00h, 01h - 40x25 text
;	 02h, 03h, 07h - 80x25 text
;	 04h, 05h - 320x200 graphics (currently not implemented)
;	 06h - 640x200 graphics (currently not implemented)
;   ds:si -> tcbddt
;   [tcbddt] = dword -> screen buffer
;   ss:bp -> databuf
;   di = databuf insertion pointer/count of bytes in databuf
;-----------------------------------------------------------------------
	assume	ds:nothing,es:nothing,ss:nothing
setmode:

ifdef	emulink
	mov	[si].mode, al		; store the mode
	cmp	al, 4			; does he want a text mode
	jb	setmd1			; jump if yes
	cmp	al,6
	je	setmd0
	cmp	al, 7			; how about this text mode
	jae	setmd1			; skip over if text mode
	mov	[databuf+di],01bh	; store an escape
	inc	di			; bump the count
	mov	[databuf+di],'c'	; set 320x200
	inc	di			; bump the count
	call	senddata		; send the data to serial.sys
	ret				; return to caller
setmd0:
	mov	[databuf+di],01bh	; store an escape
	inc	di			; bump the count
	mov	[databuf+di],'b'	; set 640x200
	inc	di			; bump the count
	call	senddata		; send the data to serial.sys
	ret				; return to caller
setmd1:
	mov	[databuf+di],01bh	; store an escape
	inc	di			; bump the count
	mov	[databuf+di],'d'	; set graphics text
	inc	di			; bump the count
endif

	xor	dx, dx			; home the cursor
	call	xsetcrs 		; go position it
	mov	ah, 007h		; default attribute
	call	setattrib		; set default attribute
	mov	bx, cs			; segment of terminal commands
	mov	es, bx			; set es to terminal commands
	mov	bx, offset ceos 	; erase to end of screen
	call	movestr 		; move command to buffer
	mov	[si].crstyp, 00b0ch	; show cursor an underline
	mov	bx, offset linecursor	; underline cursor command
	call	movestr 		; move command to buffer
	call	senddata		; send data to serial.sys
	ret				; return to caller

	subttl	setcrstyp - set cursor type
	page
;-----------------------------------------------------------------------
; setcrstyp - set cursor type
;
; ah = 04h - set cursor type
;   ch = begin scan line
;   cl = end scan line
;   dh = row
;   dl = col
;   ds:si -> tcbddt
;   [tcbddt] = dword -> screen buffer @ page/row/col
;   ss:bp -> databuf
;   di = databuf insertion pointer/count of bytes in databuf
;-----------------------------------------------------------------------
	assume	ds:nothing,es:nothing,ss:nothing
setcrstyp:

ifdef	emulink
	cmp	[si].mode, 7		; are we in text mode
	jae	setct0			; jump if text mode
	cmp	[si].mode, 4		; how about these text modes
	jb	setct0			; jump if text mode
	ret				; no need if graphics mode
setct0:
endif

	mov	bx, cs			; get segment of command data
	mov	es, bx			; set es to command data
	mov	ax, 00c0bh		; start greater than stop
	mov	bx, offset nocursor	; hidden cursor command
	cmp	ch,25			; handle special case 
	jae	setct1			;
	sub	cl, ch			; subtract start from stop scan
	jc	setct1			; jump if cursor should be hidden
	mov	ax, 0000ch		; start at 0 stop at 12
	mov	bx, offset boxcursor	; block cursor command
	cmp	cl, 3			; is it more than 3 scan lines
	jae	setct1			; jump if cursor should be a blo
	mov	ax, 00b0ch		; start 1 less than stop
	mov	bx, offset linecursor	; underline cursor
setct1:
	cmp	[si].crstyp, ax 	; is it already set
	je	setct2			; exit if yes
	mov	[si].crstyp, ax 	; set the new cursor type
	setnorm 			; terminal must see escape seq
	call	movestr 		; move command to the buffer
	call	senddata		; send the data to serial.sys
setct2:
	ret				; return to caller

	subttl	setcrspos - set physical cursor position
	page
;-----------------------------------------------------------------------
; setcrspos - set physical cursor position
;
; ah = 05h - set physical cursor position
;   dh = row
;   dl = col
;   ds:si -> tcbddt
;   [tcbddt] = dword -> screen buffer @ page/row/col
;   ss:bp -> databuf
;   di = databuf insertion pointer/count of bytes in databuf
;-----------------------------------------------------------------------
	assume	ds:nothing,es:nothing,ss:nothing
setcrspos:				; set the cursor position
	cmp	[si].string, 0		; are we already in progress
	je	scp1			; jump if nothing in progress
	ret				; ignore cursor if interupted
scp1:
	call	setcursor		; go figure the best way to do it
	call	senddata		; send the commands to serial.sys
	ret				; return to caller

; look for simple cursor movement i.e. carriage return, line feed, etc.

setcursor:

ifdef	emulink

; do not attempt to position the cursor if emulink is in graphics mode

	cmp	[si].mode, 7		; are we in text mode
	jae	setcp0			; jump if yes
	cmp	[si].mode, 4		; how about these
	jb	setcp0			; jump if text mode
	ret				; return to caller
setcp0:
endif

	cmp	dx, [si].cursor 	; do we have to move the cursor
	jne	setcp1			; jump if yes
	ret				; return to caller
setcp1:
	setnorm 			; must be in normal mode
	ifroom	2			; must be room for 2 bytes
	push	ax			; save ax

ifdef	emulink
	jmp	short setcp6		; emulink does not do forward sp
endif

ifdef	att
	jmp	short setcp6		; AT&T does not do forward sp
endif

	mov	ax, [si].cursor 	; get the current cursor position
	inc	al			; bump to the next column
	cmp	ax, dx			; is it just move to next column
	jne	setcp2			; jump if no
	mov	[si].cursor, dx 	; store the new cursor position
	mov	[databuf+di], 00ch	; store a cursor right
	inc	di			; bump the count
	pop	ax			; restore ax
	ret				; return to caller
setcp2:
	sub	al, 2			; back up a space
	cmp	ax, dx			; is it a backspace
	jne	setcp3			; jump if not backspace
	mov	[si].cursor, dx 	; store the new cursor position
	mov	[databuf+di], 008h	; store a backspace
	inc	di			; bump the count
	pop	ax			; restore ax
	ret				; return to caller
setcp3:
	inc	al			; back out the backspace
	inc	ah			; bump to next line
	cmp	ax, dx			; is it just a line feed
	jne	setcp4			; jump if no
	mov	[si].cursor, dx 	; store the new cursor position
	mov	[databuf+di], 00ah	; store a line feed
	inc	di			; bump the count
	pop	ax			; restore ax
	ret				; return to caller
setcp4:
	xor	al, al			; set to first column
	cmp	ax, dx			; was it a new line
	jne	setcp5			; jump if no
	mov	[si].cursor, dx 	; store the new cursor position
	mov	[databuf+di], 00dh	; store a carriage return
	inc	di			; bump the count
	mov	[databuf+di], 00ah	; and a line feed
	inc	di			; bump the count
	pop	ax			; restore ax
	ret				; return to caller
setcp5:
	dec	ah			; back out the line feed
	cmp	ax, dx			; was it just a carriage return
	jne	setcp6			; if not, use set cursor position
	mov	[si].cursor, dx 	; store the new cursor position
	mov	[databuf+di], 00dh	; store a carriage return
	inc	di			; bump the count
	pop	ax			; restore ax
	ret				; return to caller
setcp6:
	pop	ax			; restore ax for entry to xsetcrs

; use direct cursor addressing,  when not simple one position movement.

xsetcrs:				; direct cursor addressing
	cmp	dx, [si].cursor 	; do we need to move the cursor
	je	setcpx			; exit if no
	mov	[si].cursor, dx 	; store the new cursor position
	setnorm 			; must be in normal mode

ifdef	att

; at&t 605 cursor positioning

	ifroom	8			; must be room for 8 bytes
	mov	[databuf+di], 01bh	; store an escape
	inc	di			; bump the count
	mov	[databuf+di], '['	; store the csi
	inc	di			; bump the count
	push	ax			; save ax
	mov	al, dh			; move row number to al
	call	calcpos 		; convert row number to ascii
	cmp	ah, '0' 		; is the first character 0
	je	xatt1			; don't send a leading zero
	mov	[databuf+di], ah	; store the high byte
	inc	di			; bump the count
xatt1:
	mov	[databuf+di], al	; store the low byte
	inc	di			; bump the count
	mov	[databuf+di], ';'	; store the seperator
	inc	di			; bump the count
	mov	al, dl			; get the column count
	call	calcpos 		; convert column count to ascii
	cmp	ah, '0' 		; is the first character 0
	je	xatt2			; don't send a leading zero
	mov	[databuf+di], ah	; store the high byte
	inc	di			; bump the count
xatt2:
	mov	[databuf+di], al	; store the low byte
	inc	di			; bump the count
	mov	[databuf+di], 'H'	; tell him its direct cursor add
	inc	di			; bump the count
	pop	ax			; restore ax
else

; pc (shadow) terminal/emulink cursor positioning

	ifroom	4			; must be room for 4 bytes
	mov	[databuf+di], 01bh	; store an escape
	inc	di			; bump the count
	mov	[databuf+di], '='	; direct cursor address
	inc	di			; bump the count
	push	dx			; save dx
	add	dh, 020h		; convert to ascii
	mov	[databuf+di], dh	; store row
	inc	di			; bump the count
	add	dl, 020h		; convert to ascii
	mov	[databuf+di], dl	; store the column
	inc	di			; bump the count
	pop	dx			; restore dx
endif

setcpx:
	ret				; return to caller

ifdef	att
;-----------------------------------------------------------------------
; calculate decimal ascii row/column for ansi type devices
;   al = binary number
;
;   return
;      ah,al two decimal ascii digits
;-----------------------------------------------------------------------
calcpos:
	xor	ah, ah			; clear ah
	inc	al			; bump to true count
calcloop:
	cmp	al, 10			; is it greater than 10
	jb	calcend 		; done if no
	inc	ah			; bump count of 10's
	sub	al, 10			; subtract this one
	jmp	short calcloop		; continue the divide loop
calcend:
	add	ax, 03030h		; convert to ascii
	ret				; return to caller
endif

	subttl	scrollup - as described for the ibm pc scroll up function
	page
;-----------------------------------------------------------------------
; scrollup - as described for the ibm pc scroll up function
; ah = 06h - scroll up
;   al = number of lines to scroll (0 to clear region)
;   [ddbl] = attribute to use on blanked lines
;   ch = top-left-corner row
;   cl = top-left-corner col
;   dh = bottom-right-corner row
;   dl = bottom-right-corner col
;   ds:si -> tcbddt
;   [tcbddt] = dword -> screen buffer @ page/row/col
;   ss:bp -> databuf
;   di = databuf insertion pointer/count of bytes in databuf
;-----------------------------------------------------------------------
	assume	ds:nothing,es:nothing,ss:nothing
scrollup:
;
;	if row is same both for top and bottom then force logic
;	to clear region even if call specifies line cound, most likely
;	line count will be only for 1 line
;
	cmp	ch,dh				; same?
	jne	scrupdif
	xor	al,al				; force to clear
scrupdif:
;

ifdef	emulink
	mov	ah, [ddbl]		; get the attribute
	call	setattrib		; set the attribute
	mov	[databuf+di], 01bh	; store an escape
	inc	di			; bump the count
	mov	[databuf+di], 086h	; scroll up command
	inc	di			; bump the count
	sub	dh, ch			; calculate the height
	mov	[databuf+di], dh	; store the height
	inc	di			; bump the count
	sub	dl, cl			; calculate the width
	mov	[databuf+di], dl	; store the height
	inc	di			; bump the count
	mov	[databuf+di], ch	; store the top row
	inc	di			; bump the count
	mov	[databuf+di], cl	; store the left column
	inc	di			; bump the count
	mov	[databuf+di], al	; store the number to scroll
	inc	di			; bump the count
	call	senddata		; send the commands
	ret				; return to caller
else
	push	[si].cursor		; save the original cursor locat
	cmp	al, 0			; do we scroll the entire window
	jne	sup10			; jump if not the entire window
	call	testnrm 		; does it use default attribute
	jz	sup01			; jump if not default video
	or	cl, cl			; are we at the left margin
	jnz	sup01			; clear box if not at left margi
	mov	bh, [si].cols		; get the screen width
	dec	bh			; minus 1
	cmp	dl, bh			; are we at the right margin
	jnb	sup02			; erase line/screen if at margin
sup01:
	call	suclrb			; clear the box
	jmp	supex			; and wrapup the rest
sup02:
	cmp	dh, 24			; any data below the window
	jb	sup03			; jump if data below window

; scroll complete full line window to end of screen

	xchg	cx, dx			; swap top and bottom corners
	call	xsetcrs 		; position the cursor at top
	xchg	cx, dx			; put them back
	mov	bx, cs			; segment of command data
	mov	es, bx			; set es to command data
	mov	bx, offset ceos 	; erase to end of screen
	call	movestr 		; move commands to buffer
	jmp	supex			; go wrapup the rest

; scroll complete full line window to end of window

sup03:
	xchg	cx, dx			; swap top and bottom
	mov	cl, ch			; bottom row to cl
	inc	cl			; plus 1
	sub	cl, dh			; minus top row
	xor	ch, ch			; convert to word
	mov	bx, cs			; segment of command data
	mov	es, bx			; set es to command data
sup04:
	call	xsetcrs 		; move the cursor
	mov	bx, offset ceoln	; erase to end of line
	call	movestr 		; move command to buffer
	inc	dh			; bump to next line
	loop	sup04			; loop until all clear
	jmp	supex			; go wrapup when done

; scroll partial full line window

sup10:
	or	cl, cl			; are we at the left margin
	jnz	sup20			; move box if not at left margin
	mov	bh, [si].cols		; get screen width
	dec	bh			; minus 1
	cmp	dl, bh			; are we at the right margin
	jb		sup20		; move box if not at right margi
	xchg	cx, dx			; swap top and bottom again
	call	xsetcrs 		; move cursor to top corner
	xchg	cx, dx			; put top and bottom back
	mov	cl, al			; cl equals number to scroll
	xor	ch, ch			; convert to word
	mov	bx, cs			; segment of command data
	mov	es, bx			; set es to command data
sup11:
	mov	bx, offset deleteline	; delete line command
	call	movestr 		; move command to the buffer
	loop	sup11			; do as many times as neccessary
	inc	dh			; bottom plus 1
	sub	dh, al			; back up scrolled lines
	call	xsetcrs 		; position the cursor at data
	mov	cl, al			; scrolled count to cl
	xor	ch, ch			; convert to word
sup12:
	mov	bx, offset insertline	; insert line command
	call	movestr 		; move command to the buffer
	loop	sup12			; do as many times as neccessary
	call	testnrm 		; is it default attribute
	jz	sup13			; jump if not default attribute
	jmp	supex			; go wrap it up
sup13:
	call	suclrb			; set attributes in the box
	jmp	supex			; wrap up the scroll

; scroll partial line window

sup20:
	add	al, ch			; al equals first line of data
	mul	[si].cols		; calculate line offset
	mov	bl, cl			; column offset to bl
	xor	bh, bh			; convert to word
	add	bx, ax			; calculate screen offset
	shl	bx, 1			; convert to word offset
	les	ax, [si].logscr 	; get screen offset
	add	bx, ax			; get location of data
	xchg	cx, dx			; swap top and bottom
	call	xsetcrs 		; position the at the top
	inc	cl			; right corner plus 1
	sub	cl, dl			; characters per line to move
	inc	ch			; bottom line plus 1
	sub	ch, dh			; ch equals lines in window
	sub	ch, [ddal]		; ch equals lines to move
	push	cx			; save lines/char to move
sup21:
	mov	ax, es:[bx]		; get the attribute and characte
	call	setattrib		; set the attribute
	call	setchar 		; store the character
	add	bx, 2			; bump to next position
	dec	cl			; one less to move
	jnz	sup21			; move the next one if more
	inc	dh			; bump to the next line
	call	xsetcrs 		; position the cursor there
	pop	cx			; restore lines/character
	mov	al, [si].cols		; screen width to al
	sub	al, cl			; minus columns moved
	xor	ah, ah			; convert to word
	shl	ax, 1			; make a word offset
	add	bx, ax			; bump to next line origin
	dec	ch			; one less line to do
	push	cx			; save for next time thru
	jnz	sup21			; go move the next line
	pop	cx			; clear the stack
	call	suclrb			; go clear the box
supex:
	pop	dx			; get original cursor position
	call	xsetcrs 		; restore the cursor position
	call	senddata		; send any commands to serial.sys
	ret				; return to caller

;-----------------------------------------------------------------------
; clear the vacated portion of a partial line window
;-----------------------------------------------------------------------
suclrb:
	mov	ah, [ddbl]		; get the desired attribute
	call	setattrib		; set the attribute
	mov	ax, [ddax]		; retrieve scroll count
	mov	cx, [ddcx]		; and upper left corner
	mov	dx, [dddx]		; and lower right corner
	cmp	al, 0			; are we clearing them all
	jne	suclrb1 		; jump if no
	mov	al, dh			; get bottom line
	inc	al			; plus 1
	sub	al, ch			; minus top line = lines to clear
suclrb1:
	inc	dh			; must use bottom plus one
	sub	dh, al			; back up to first line to clear
	xchg	dl, cl			; dl = left col, cl = right col
	call	xsetcrs 		; position the cursor
	inc	cl			; right column plus 1
	sub	cl, dl			; character per line to clear
	mov	ch, al			; ch - lines to clear
	push	cx			; save lines/characters
suclrb2:
	ifroom	1			; must be room for 1 more byte
	mov		[databuf+di], 020h  ; store a space
	inc	di			; bump the pointer
	dec	cl			; dec the count to clear
	jnz	suclrb2 		; clear until line done
	inc	dh			; move to the next line
	call	xsetcrs 		; move the cursor
	pop	cx			; restore line/char
	dec	ch			; any more lines to do
	push	cx			; save it for later
	jnz	suclrb2 		; continue if more to clear
	pop	cx			; clear the stack
	ret				; return to caller

;-----------------------------------------------------------------------
; testnrm
;
; determine if attribute produces normal video or not
;
; input:  [ddbl] contains attribute to check
; output: z flag set if attribute produces abnormal video
;	  z flag clear if attribute produces normal video
;	  all registers unchanged
;-----------------------------------------------------------------------
testnrm:
	push	ax			; save ax
	mov	al, [ddbl]		; get the attribute
	test	al, 0f8h		; blink, reverse or bold
	jnz	tstnd			; jump if blink, reverse or bold
	cmp	al, 1			; is it underline
	jne	tstnx			; jump if normal
tstnd:
	cmp	al, al			; set the zero flag
tstnx:
	pop	ax			; restore ax
	ret				; return to caller
endif

	subttl	scrolldn - as described for the ibm pc scroll down function
	page
;-----------------------------------------------------------------------
; scrolldn - as described for the ibm pc scroll down function
;
; ah = 07h - scroll down
;   al = number of lines to scroll (0 to clear region)
;   [ddbl] = attribute to use on blanked lines
;   ch = top-left-corner row
;   cl = top-left-corner col
;   dh = bottom-right-corner row
;   dl = bottom-right-corner col
;   ds:si -> tcbddt
;   [tcbddt] = dword -> screen buffer @ page
;   ss:bp -> databuf
;   di = databuf insertion pointer/count of bytes in databuf
;-----------------------------------------------------------------------
	assume	ds:nothing,es:nothing,ss:nothing
scrolldn:
;
;	if row is same both for top and bottom then force logic
;	to clear region even if call specifies line cound, most likely
;	line count will be only for 1 line
;
	cmp	ch,dh				; same?
	jne	scrdndif
	xor	al,al				; force to clear
scrdndif:
;

ifdef	emulink
	mov	ah, [ddbl]		; get the attribute
	call	setattrib		; set the attribute
	mov	[databuf+di], 01bh	; store an escape
	inc	di			; bump the count
	mov	[databuf+di], 087h	; scroll down command
	inc	di			; bump the count
	sub	dh, ch			; calculate the height
	mov	[databuf+di], dh	; store the height
	inc	di			; bump the count
	sub	dl, cl			; calculate the width
	mov	[databuf+di], dl	; store the height
	inc	di			; bump the count
	mov	[databuf+di], ch	; store the top row
	inc	di			; bump the count
	mov	[databuf+di], cl	; store the left column
	inc	di			; bump the count
	mov	[databuf+di], al	; store the number to scroll
	inc	di			; bump the count
	call	senddata		; send the commands
	ret				; return to caller
else
	push	[si].cursor		; save the original cursor locat
	cmp	al, 0			; do we scroll the entire window
	jne	sdn10			; jump if not the entire window
	call	testnrm 		; does it use default attribute
	jz	sdn01			; jump if not default video
	or	cl, cl			; are we at the left margin
	jnz	sdn01			; clear box if not at left margi
	mov	bh, [si].cols		; get the screen width
	dec	bh			; minus 1
	cmp	dl, bh			; are we at the right margin
	jnb	sdn02			; erase line/screen if at margin
sdn01:
	call	sdclrb			; clear the box
	jmp	sdnex			; and wrapup the rest
sdn02:
	cmp	dh, 24			; any data below the window
	jb	sdn03			; jump if data below window

; scroll complete full line window to end of screen

	xchg	cx, dx			; swap top and bottom corners
	call	xsetcrs 		; position the cursor at top
	xchg	cx, dx			; put them back
	mov	bx, cs			; segment of command data
	mov	es, bx			; set es to command data
	mov	bx, offset ceos 	; erase to end of screen
	call	movestr 		; move commands to buffer
	jmp	sdnex			; go wrapup the rest

; scroll complete full line window to end of window

sdn03:
	xchg	cx, dx			; swap top and bottom
	mov	cl, ch			; bottom row to cl
	inc	cl			; plus 1
	sub	cl, dh			; minus top row
	xor	ch, ch			; convert to word
	mov	bx, cs			; segment of command data
	mov	es, bx			; set es to command data
sdn04:
	call	xsetcrs 		; move the cursor
	mov	bx, offset ceoln	; erase to end of line
	call	movestr 		; move command to buffer
	inc	dh			; bump to next line
	loop	sdn04			; loop until all clear
	jmp	sdnex			; go wrapup when done

; scroll partial full line window

sdn10:
	or	cl, cl			; are we at the left margin
	jnz	sdn20			; move box if not at left margin
	mov	bh, [si].cols		; get screen width
	dec	bh			; minus 1
	cmp	dl, bh			; are we at the right margin
	jb		sdn20		; move box if not at right margi
	inc	dh			; bottom row plus 1
	sub	dh, al			; minus number to scroll
	call	xsetcrs 		; move cursor to first line to ki
	mov	cl, al			; cl equals number to scroll
	xor	ch, ch			; convert to word
	mov	bx, cs			; segment of command data
	mov	es, bx			; set es to command data
sdn11:
	mov	bx, offset deleteline	; delete line command
	call	movestr 		; move command to the buffer
	loop	sdn11			; do as many times as neccessary
	mov	dx, [ddcx]		; top corner to dx
	call	xsetcrs 		; position cursor at top corner
	mov	cl, al			; scrolled count to cl
	xor	ch, ch			; convert to word
sdn12:
	mov	bx, offset insertline	; insert line command
	call	movestr 		; move command to the buffer
	loop	sdn12			; do as many times as neccessary
	call	testnrm 		; is it default attribute
	jz	sdn13			; jump if not default attribute
	jmp	sdnex			; go wrap it up
sdn13:
	call	sdclrb			; set attributes in the box
	jmp	sdnex			; wrap up the scroll

; scroll partial partial line window

sdn20:
	mov	al, dh			; bottom row to al
	sub	al, [ddal]		; minus lines to scroll
	mul	[si].cols		; calculate line offset
	mov	bl, cl			; column offset to bl
	xor	bh, bh			; convert to word
	add	ax, bx			; calculate screen offset
	shl	ax, 1			; convert to word offset
	les	bx, [si].logscr 	; get screen location
	add	bx, ax			; add cursor offset
	xchg	dl, cl			; swap left and right margin
	call	xsetcrs 		; position the cursor at lower lef
	inc	cl			; right corner plus 1
	sub	cl, dl			; characters per line to move
	mov	ch, dh			; bottom row to ch
	inc	ch			; bottom line plus 1
	sub	ch, [ddch]		; ch equals lines in window
	sub	ch, [ddal]		; ch equals lines to move
	push	cx			; save lines/char to move
sdn21:
	mov	ax, es:[bx]		; get the attribute and characte
	call	setattrib		; set the attribute
	call	setchar 		; store the character
	add	bx, 2			; bump to next position
	dec	cl			; one less to move
	jnz	sdn21			; move the next one if more
	dec	dh			; backup to the next line
	call	xsetcrs 		; position the cursor there
	pop	cx			; restore lines/character
	mov	al, [si].cols		; screen width to al
	add	al, cl			; add columns moved
	xor	ah, ah			; convert to word
	shl	ax, 1			; make a word offset
	sub	bx, ax			; backup to next line to move
	dec	ch			; one less line to do
	push	cx			; save for next time thru
	jnz	sdn21			; go move the next line
	pop	cx			; clear the stack
	call	sdclrb			; go clear the box
sdnex:
	pop	dx			; get original cursor position
	call	xsetcrs 		; restore the cursor position
	call	senddata		; send any commands to serial.sys
	ret				; return to caller

; clear the vacated area of a partial line window (or not default attrb)

sdclrb:
	mov	ah, [ddbl]		; get the desired attribute
	call	setattrib		; set the attribute
	mov	ax, [ddax]		; retrieve scroll count
	mov	cx, [ddcx]		; and upper left corner
	mov	dx, [dddx]		; and lower right corner
	cmp	al, 0			; are we clearing them all
	jne	sdclrb1 		; jump if no
	mov	al, dh			; get bottom line
	inc	al			; plus 1
	sub	al, ch			; minus top line = lines to clear
sdclrb1:
	xchg	cx, dx			; stop top/left and bottom/right
	add	dh, al			; add cleared to top row
	dec	dh			; back up to last cleared
	call	xsetcrs 		; position the cursor
	inc	cl			; right column plus 1
	sub	cl, dl			; character per line to clear
	mov	ch, al			; ch - lines to clear
	push	cx			; save lines/characters
sdclrb2:
	ifroom	1			; must be room for 1 more bye
	mov		[databuf+di], 020h  ; store a space
	inc	di			; bump the pointer
	dec	cl			; dec the count to clear
	jnz	sdclrb2 		; clear until line done
	dec	dh			; backup to the next line
	call	xsetcrs 		; move the cursor
	pop	cx			; restore line/char
	dec	ch			; any more lines to do
	push	cx			; save it for later
	jnz	sdclrb2 		; continue if more to clear
	pop	cx			; clear the stack
	ret				; return to caller
endif					; rg9121

	subttl	wrchatr - write character and attribute
	page
;-----------------------------------------------------------------------
; wrchatr - write character and attribute
;
; ah = 08h - write character and attribute at row & col & page
;   al = char to write
;   [ddbl] = attribute to write
;   cx = number of times to write
;   dh = row
;   dl = col
;   ds:si -> tcbddt
;   [tcbddt] = dword -> screen buffer @ page/row/col
;   ss:bp -> databuf
;   di = databuf insertion pointer/count of bytes in databuf
;-----------------------------------------------------------------------
	assume	ds:nothing,es:nothing,ss:nothing
wrchatr:
	mov	bx, [ddbx]		; get the original bx
	push	di			; save buffer count
	les	di, [si].logscr 	; point es:di to screen buffer
	mov	ah, bl			; move the attribute to ah
	mov	bx, ax			; move char/attrb to bx also
wrcha1:
	scasw				; compare it to the buffer
	jne	wrcha3			; jump if they're not equal
	inc	dl			; bump to the next column
	cmp	dl, [si].cols		; are we at end of line
	jb	wrcha2			; jump if no
	xor	dl, dl			; reset to column 0
	inc	dh			; bump to the next line
	cmp	dh, 25			; was that the last line
	jae	wrcha2x 		; exit if yes
wrcha2:
	loop	wrcha1			; go check the next char positio
wrcha2x:
	pop	di			; restore di
	ret				; return if no changes
wrcha3:
	sub	di, 2			; back up to the different chara
	dec	cx			; set to offset from start
	jz	wrcha4			; skip end checking if at end
	add	di, cx			; figure new offset
	add	di, cx			; " " " " " " " " "
	inc	cx			; count back to remainder
	std				; start looking from the back
	repe scasw			; look for a mismatch
	cld				; restore the direction flag
wrcha4:
	inc	cx			; back out the last compare
	pop	di			; restore databuf counter
	call	setcursor		; position the cursor
	call	setattrib		; set the attribute
wrcha5:
	call	setchar 		; store the character
	inc	dl			; here too
	cmp	dl, [si].cols		; are we at the end of the line
	jb	wrcha6			; press on if no
	cmp	dh, 24			; are we on the last line
	jae	wrchax			; exit if yes
	xor	dl, dl			; set to column 0
	inc	dh			; and the next line
	call	setcursor		; move the cursor with direct cu
wrcha6:
	mov	[si].cursor, dx 	; update the cursor location
	loop	wrcha5			; continue until we have done all
wrchax:
	call	senddata		; send remaining data to serial.sys
	ret				; all done

	subttl	setpalet - set color palette or background color
	page
;-----------------------------------------------------------------------
; setpalet - set color palette or background color
;
; ah = 09h - set color palette or background color
;   [ddbl] = byte as stored in crt_palette by ibm bios
;   (bl and 1fh = background color)
;   (bl and 20h = 20h for palette 1 else palette 0
;   ds:si -> tcbddt
;   ss:bp -> databuf
;   di = databuf insertion pointer/count of bytes in databuf
;-----------------------------------------------------------------------
	assume	ds:nothing,es:nothing,ss:nothing
setpalet:

ifdef	emulink
	mov	bx, [ddbx]		; get the palette settings
	ifroom	6			; must be room for 6 bytes
	mov	[databuf+di], 01bh	; store an escape
	inc	di			; bump the count
	mov	[databuf+di], 'v'	; set the palette color
	inc	di			; bump the count
	mov	al, bl			; get the data
	and	al, 01fh		; save only the color
	mov	[databuf+di], al	; store it
	inc	di			; bump the count
	mov	[databuf+di], 01bh	; store an escape
	inc	di			; bump the count
	mov	[databuf+di], 'V'	; select palette number
	inc	di			; bump the count
	mov	cl, 5			; shift right 5 bits
	shr	bl, cl			; move palette number to bit 1
	mov	[databuf+di], bl	; store it
	inc	di			; bump the count
	call	senddata		; send it to serial.sys
endif

	ret				; return to caller

	subttl	wrtty - as described by the ibm pc write tty function
	page
;-----------------------------------------------------------------------
; wrtty - as described by the ibm pc write tty function
;
; ah = 0ah - write tty at row & col & page
;   al = char to write
;   dh = row
;   dl = col
;   ds:si -> tcbddt
;   [tcbddt] = dword -> screen buffer @ page/row/col
;   ss:bp -> databuf
;   di = databuf insertion pointer/count of bytes in databuf
;-----------------------------------------------------------------------
	assume	ds:nothing,es:nothing,ss:nothing
wrtty:
	cmp	al, 008h		; is it a backspace
	je	wrttyx			; exit if backspace
	cmp	al, 00dh		; is it a carriage return
	je	wrttyx			; exit if carriage return
	cmp	al, 007h		; is it a bell
	jne	wrtty1			; jump if not a bell
	setnorm 			; make sure we're in normal mode
	mov	[databuf+di], 007h	; store a bell
	inc	di			; bump the counter
	jmp	short wrtty4		; go send the data and wrap up
wrtty1:
	cmp	al, 00ah		; is it a line feed
	jne	wrtty2			; jump if not a line feed
	inc	dh			; bump to the next line
	cmp	dh, 25			; do we need to scroll
	jb	wrttyx			; quit if no scroll needed
	dec	dh			; back up to line 24
	call	setcursor		; position the cursor
	mov	[databuf+di], 00ah	; store a line feed
	inc	di			; bump the count
	jmp	short wrtty4		; go send the data and wrap up
wrtty2:
	call	setcursor		; position the cursor
	les	bx, [si].logscr 	; point es:bx to screen buffer
	mov	ah, es:[bx+1]		; get this positions attribute
	call	setattrib		; set the attribute
	call	setchar 		; set the character
	inc	dl			; bump to the next column
	cmp	dl, [si].cols		; are we at the end of the line
	jb		wrtty3		; go wrap up if not end of line
	mov	[databuf+di], 00dh	; store a carriage return
	inc	di			; bump the count
	xor	dl, dl			; set to column 0
	mov	[databuf+di], 00ah	; store a line feed
	inc	di			; bump the count
	cmp	dh, 24			; are we on the last line
	jnb	wrtty3			; jump if on last line
	inc	dh			; bump to next line
wrtty3:
	mov	[si].cursor, dx 	; store new cursor location
wrtty4:
	call	senddata		; send any commands to serial.sy
wrttyx:
	ret

	subttl	wrstr - write a string of characters and attributes
	page
;-----------------------------------------------------------------------
; wrstr - write a string of characters and attributes
;
; ah = 0bh - write string of characters and attributes at row/col
;
;   cx = number of chars to write (word length of string)
;   dh = row
;   dl = col
;   ds:si -> tcbddt
;   [tcbddt] = dword -> screen buffer @ page/row/col
;   [ddes]:[dddi] -> string
;   ss:bp -> databuf
;   di = databuf insertion pointer/count of bytes in databuf
;-----------------------------------------------------------------------
	assume	ds:nothing,es:nothing,ss:nothing
wrstr:

ifndef	emulink
	call	setcursor		; set the cursor to starting loc
	mov	bx, [dddi]		; get offset to the string
wrstr1:
	mov	ax, es:[bx]		; get the char/attrb pair
	add	bx, 2			; bump to the next position
	call	setattrib		; set the attribute
	call	setchar 		; store the character
	inc	dl			; in the register too
	cmp	dl, [si].cols		; are we at the end of the line
	jb	wrstr2			; jump if no
	cmp	dh, 24			; are we at the end of the scree
	jae	wrstrx			; exit if yes
	xor	dl, dl			; set to column 0
	inc	dh			; bump to the next line
	call	setcursor		; reposition the cursor
wrstr2:
	mov	[si].cursor, dx 	; store the new cursor position
	loop	wrstr1			; continue until all done
wrstrx:
	call	senddata		; send any data to serial.sys
	ret				; return to caller
else
	cmp	[si].mode, 7		; are we in a text mode
	jae	wrstr0			; jump if yes
	cmp	[si].mode, 4		; how about these
	jb	wrstr0			; jump if in text mode
	jmp	wrstrg			; jump if in graphics mode
wrstr0:
	call	setcursor		; set the cursor to starting loc
	mov	bx, [dddi]		; get offset to the string
	mov	[si].string+7, 0	; initialize the repeat count
wrstr1:
	cmp	[si].string+7, 0	; have we got a character
	jne	wrstr1a 		; jump if we have already got on
	mov	ax, es:[bx]		; get the char/attrb pair
	call	setattrib		; set the attribute
wrstr1a:
	inc	[si].string+7		; bump the repeat count
	add	bx, 2			; bump to the next position
	cmp	ax, es:[bx]		; is the next one the same
	je	wrstr1c 		; jump if the character is repea
	call	reptwr			; write the character
wrstr1c:
	inc	dl			; in the register too
	cmp	dl, [si].cols		; are we at the end of the line
	jb	wrstr2			; jump if no
	cmp	dh, 24			; are we at the end of the scree
	jae	wrstrx			; exit if yes
	call	reptwr			; write any characters before se
	xor	dl, dl			; set to column 0
	inc	dh			; bump to the next line
	call	setcursor		; reposition the cursor
wrstr2:
	mov	[si].cursor, dx 	; store the new cursor position
	loop	wrstr1			; continue until all done
wrstrx:
	call	reptwr			; send any remaining characters
	call	senddata		; send any data to serial.sys
	ret				; return to caller

reptwr	proc	near
	mov	ah, [si].string+7	; get the character count
	mov	[si].string+7, 0	; reinitialize the repeat count
	cmp	ah, 0			; are there any to write
	jne	reptwr1 		; press on if some waiting
	ret				; return to caller
reptwr1:
	cmp	ah, 1			; was the character duplicated
	jne	reptwr2 		; jump if character repeated
	call	setchar 		; store the character
	ret				; return to caller
reptwr2:
	ifroom	4			; must be room for 4 bytes
	mov	[databuf+di], 01bh	; store an escape
	inc	di			; bump the count
	mov	[databuf+di], 08ah	; store repeat command
	inc	di			; bump the count
	mov	[databuf+di], ah	; store the count
	inc	di			; bump the count
	mov	[databuf+di], al	; store the character
	inc	di			; bump the count
	ret				; return to caller
reptwr	endp

wrstrg:
	ifroom	4			; must be room for 4 bytes
	mov	[databuf+di], 01bh	; store an escape
	inc	di			; bump count of chars in buffer
	mov	[databuf+di], '='	; store cursor position command
	inc	di			; bump count of chars in buffer
	mov	[databuf+di], dh	; store the row (binary)
	inc	di			; bump count of chars in buffer
	mov	[databuf+di], dl	; store the column (binary)
	inc	di			; bump count of chars in buffer
	mov	bx, [dddi]		; set bx to pointer to data
wrstrg1:
	mov	ax, es:[bx]		; get the first word
	add	bx,2			; bump to the next
	dec	cx			; drop the count
	xchg	di, bx			; set di for scasw
	cmp	al, ah			; are high and low equal
	jne	wrstrg5 		; jump if high and low not equal
	mov	dx, cx			; save the count in dx
	cld				; set for the right direction
	repe scasw			; check for equal bytes
	je	wrstrg2 		; jump if all the same
	sub	di, 2			; back up to unequal byte
	inc	cx			; count remaining
	sub	dx, cx			; dx equal repeat count
	jz	wrstrg5 		; jump if not repeated
wrstrg2:
	xchg	di, bx			; restore buffer pointer
	inc	dx			; add one for first instance
	add	dx, dx			; convert word count to byte cou
wrstrg3:
	sub	dx, 254 		; are there more than 254
	jbe	wrstrg4 		; jump if less than 254
	ifroom	4			; must be room for 4 bytes
	mov	[databuf+di], 01bh	; store an escape
	inc	di			; bump the count
	mov	[databuf+di], 'R'	; repeat byte command
	inc	di			; bump the count
	mov	[databuf+di], 254	; max even number repeat
	inc	di			; bump the count
	mov	[databuf+di], al	; store the character
	inc	di			; bump the count
	jmp	short wrstrg3		; go try it again
wrstrg4:
	add	dx, 254 		; put it back to the readl count
	ifroom	4			; must be room for 4 bytes
	mov	[databuf+di], 01bh	; store an escape
	inc	di			; bump the count
	mov	[databuf+di], 'R'	; repeat byte command
	inc	di			; bump the count
	mov	[databuf+di], dl	; store the count
	inc	di			; bump the count
	mov	[databuf+di], al	; store the character
	inc	di			; bump the count
	jcxz	wrstrg8 		; wrap it up if none left
	jmp	short wrstrg1		; go look at the next position
wrstrg5:
	xchg	di, bx			; restore buffer pointer
	ifroom	4			; must be room for up to 4 bytes
	cmp	al, 1bh 		; is it a 1b
	jne	wrstrg6 		; jump if not 1b
	mov	[databuf+di], al	; must send 2 1b's to get it thru
	inc	di			; bump the count
wrstrg6:
	mov	[databuf+di], al	; store the character
	inc	di			; bump the count
	cmp	ah, 01bh		; is ah a 1b
	jne	wrstrg7 		; jump if not 1b
	mov	[databuf+di], ah	; must send 2 1b's to get it thru
	inc	di			; bump the count
wrstrg7:
	mov	[databuf+di], ah	; store the character
	inc	di			; bump the count
	jcxz	wrstrg8 		; jump if no more to check
	jmp	wrstrg1 		; go check the next character
wrstrg8:
	call	senddata		; send any commands to serial.sys
	ret				; return when done
endif

	subttl	setwindow - re-display the top or bottom 24 lines
	page
;-----------------------------------------------------------------------
; setwindow - re-display the top or bottom 24 lines
;
; ah = 0ch - put screen
;   al = 0 - re-display top lines of screen
;	 1 - re-display bottom lines of screen
;   cx = screen length (words)
;   ds:si -> tcbddt
;   [tcbddt] = dword -> screen buffer @ page/row/col
;   ss:bp -> databuf
;   di = databuf insertion pointer/count of bytes in databuf
;-----------------------------------------------------------------------
	assume	ds:nothing,es:nothing,ss:nothing
setwindow:
	push	[dddx]			; save original dx
	push	[dddi]			; save original di
	push	[ddes]			; save original es
	push	di			; save di
	les	di, [si].logscr 	; get pointer to screen data
	mov	[ddes], es		; set ddes for screen buffer
	mov	[dddi], di		; set dddi for screen buffer
	pop	di			; restore buffer pointer
	xor	dx, dx			; set to start of screen
	mov	[dddx], dx		; set dddx to start of screen
ifdef emulink
	cmp	[si].mode, 7		; are we in a text mode
	jae	usewrstr		; jump if yes
	cmp	[si].mode, 4		; how about these
	ja	setwg			; jump if in graphics mode
usewrstr:
endif
	call	wrstr			; call write string
	pop	[ddes]			; restore ddes
	pop	[dddi]			; restore dddi
	pop	[dddx]			; restore dddx
	ret

ifdef emulink
setwg:					;parcel it to wrstr 1 line at a time
	mov	cx,200			;200 lines
setwglp:
	push	cx	
	push	dx
	mov	cx,40			;80 cols in row
	call	wrstrg
	pop	dx
	pop	cx
	dec	cx
	jcxz	setwgret
	inc	dh
	test	cx,1
	jz	bank1
	add	[dddi],2000h
	jmp	setwglp
bank1:
	sub	[dddi],2000h-80
	jmp	setwglp
setwgret:
	pop	[ddes]			; restore ddes
	pop	[dddi]			; restore dddi
	pop	[dddx]			; restore dddx
	ret
endif

	subttl	wrcho - write char only
	page
;-----------------------------------------------------------------------
; ah = 0dh - write char only at row & col
;   al = char to write
;   cx = number of times to write
;   dh = row
;   dl = col
;   ds:si -> tcbddt
;   [tcbddt] = dword -> screen buffer @ page/row/col
;   ss:bp -> databuf
;   di = databuf insertion pointer/count of bytes in databuf
;-----------------------------------------------------------------------
	assume	ds:nothing,es:nothing,ss:nothing
wrcho:
	push	di			; save the buffer count
	les	di, [si].logscr 	; point es:di to screen buffer
wrcho1:
	scasb				; is it already here
	jne	wrcho3			; jump if no
	inc	di			; bump past the attribute
	inc	dl			; bump the column count
	cmp	dl, [si].cols		; are we at the end of a line
	jb	wrcho2			; jump if no
	xor	dl, dl			; do a carriage return
	inc	dh			; and a line feed
	cmp	dh, 25			; are we done
	jae	wrcho2x 		; exit if yes
wrcho2:
	loop	wrcho1			; check until all have been chec
wrcho2x:
	pop	di			; restore di
	ret				; return if screen already written
wrcho3:
	push	di			; save location of first attribut
	dec	di			; back up to the different chara
	dec	cx			; set to offset from the start
	jz	wrcho4			; skip end checking if at end
	add	di, cx			; figure new offset
	add	di, cx			; " " " " " " " " "
	std				; start looking from the rear
wrcho3a:
	scasb				; is it already here
	jne	wrcho4			; quit if no
	dec	di			; skip over the attribute
	loop	wrcho3a 		; keep looking until done
wrcho4:
	cld				; restore the directional flag
	inc	cx			; back out the last compare
	pop	bx			; restore location of first diff
	pop	di			; restore buffer offset
	call	setcursor		; position the cursor
wrcho5:
	mov	ah, es:[bx]		; get the current attribute
	add	bx, 2			; bump to the next position
	call	setattrib		; set the current attribute
	call	setchar 		; store the character
	inc	dl			; here too
	cmp	dl, [si].cols		; are we at the end of the line
	jb	wrcho6			; jump if no
	cmp	dh, 24			; are we at bottom of the screen
	jae	wrchox			; exit if at bottom
	xor	dl, dl			; do a carriage return
	inc	dh			; and a line feedd
	call	xsetcrs 		; use direct cursor addressing
wrcho6:
	mov	[si].cursor, dx 	; store the new cursor position
	loop	wrcho5			; loop until done
wrchox:
	call	senddata		; send remaining data to serial.sys
	ret

	subttl	readch - read char/attribute at row & col & page
	page
;-----------------------------------------------------------------------
; ah = 0eh - read char/attribute at row & col & page
;     (master console only)
;   dh = row
;   dl = col
;   ds:si -> tcbddt
;   [tcbddt] = dword -> screen buffer @ row/col/page
;   ss:bp -> databuf
;   di = databuf insertion pointer/count of bytes in databuf
;-----------------------------------------------------------------------
	assume	ds:nothing,es:nothing,ss:nothing
readch:
	ret				; not supported on terminal

	subttl	getscr - get screen
	page
;-----------------------------------------------------------------------
; ah = 0fh - get screen
;     (master console only)
;   cx = word length to get
;   ds:si -> tcbddt
;   [tcbddt] = dword -> logical screen buffer
;   ss:bp -> databuf
;   di = databuf insertion pointer/count of bytes in databuf
;-----------------------------------------------------------------------
	assume	ds:nothing,es:nothing,ss:nothing
getscr:
	ret				; not supported on terminal

	subttl	prch - print a character on the terminal's local printer
	page
;-----------------------------------------------------------------------
; prch - print a character on the terminal's local printer
;
;   ah = 10h
;     al = char to print
;     ds:si -> tcbddt
;   ss:bp -> databuf
;   di = databuf insertion pointer/count of bytes in databuf
;
;   returns [ddah] as in int 17h call
;-----------------------------------------------------------------------
	assume	ds:nothing,es:nothing,ss:nothing
prch:
	test	[si].tmode, print	; are we in print mode
	jnz	prch1			; jump if yes
	setnorm 			; set to normal mode
	or		[si].tmode, print  ; turn on print mode
	mov	bx, cs			; get segment of command data
	mov	es, bx			; set es to command data
	mov	bx, offset printon	; address of printer on command
	call	movestr 		; move it to the buffer
prch1:
	mov	[databuf+di],al 	; store the character
	inc	di			; bump the counter
	call	senddata		; send any data to serial.sys
	mov	[ddah], 0		; send a good status
	ret				; return to caller

	subttl	prstr - print a string on the terminal's local printer
	page
;-----------------------------------------------------------------------
; prstr - print a string on the terminal's local printer
;
;   ah = 11h
;   [ddes]:[dddi] -> string to print
;   cx = length (bytes) to print
;   ds:si -> tcbddt
;   ss:bp -> databuf
;   di = databuf insertion pointer/count of bytes in databuf
;
;   returns ah as in int 17h call if all of string can't be printed
;     and di -> first char not printed, cx = number not printed
;-----------------------------------------------------------------------
	assume	ds:nothing,es:nothing,ss:nothing
prstr:
	mov	bx, [dddi]		; get pointer to data
	test	[si].tmode, print	; are we in print mode
	jnz	prstr1			; jump if yes
	setnorm 			; set to normal mode
	or		[si].tmode, print  ; turn on print mode
	push	es			; save es
	push	bx			; save bx
	mov	bx, cs			; get segment of command data
	mov	es, bx			; set es to command data
	mov	bx, offset printon	; address of printer on command
	call	movestr 		; move it to the buffer
	pop	bx			; restore bx
	pop	es			; and es
prstr1:
	ifroom	1			; must be room for 1 more byte
	mov	al, es:[bx]		; get a character
	inc	bx			; bump to the next
	mov	[databuf+di], al	; store the character
	inc	di			; bump the counter
	loop	prstr1			; go get the next character
	call	senddata		; send any data to serial.sys
	mov	[ddah], 0		; set normal return status
	mov	[ddcx], 0		; all characters sent
	ret				; return when finished

;-----------------------------------------------------------------------
; keybstat - get/set keyboard status
;
;   ah = 12h
;   al = app's keyboard status
;   bl = terminal's keyboard status
;
;	returns al = keyboard status to use for decoding
;	should set keyboard leds
;-----------------------------------------------------------------------
	assume	ds:nothing,es:nothing,ss:nothing
keybstat:
	mov	al, bl			; return terminal's keyboard status
	ret

	subttl	setattrib - set current attribute
	page
;-----------------------------------------------------------------------
; set current attribute to ah
;-----------------------------------------------------------------------
	assume	ds:nothing,es:nothing,ss:nothing
setattrib:
	cmp	ah, [si].attrib 	; has the attribute changed
	je	setax			; exit if no
	push	ax			; save ax
	mov	[si].attrib, ah 	; store the new attribute
	setnorm 			; reset monitor or print mode

ifdef	att
	ifroom	10			; must be room for 10 bytes
	mov	[databuf+di], 01bh	; store an escape
	inc	di			; bump the count
	mov	[databuf+di], '['	; store the csi
	inc	di			; bump the count
	mov	[databuf+di], '0'	; reset attribute
	inc	di			; bump the count
	test	ah, 080h		; is blink set
	jz	satt1			; skip if no
	mov	[databuf+di], ';'	; store the seperator
	inc	di			; bump the count
	mov	[databuf+di], '5'	; set blink attribute
	inc	di			; bump the count
satt1:
	test	ah, 008h		; is high intensity set
	jz	satt2			; jump if no
	mov	[databuf+di], ';'	; store the seperator
	inc	di			; bump the count
	mov	[databuf+di], '1'	; set bold attribute
	inc	di			; bump the count
satt2:
	and	ah, 077h		; any foreground or background
	jnz	satt3			; press on if yes
	mov	[databuf+di], ';'	; store the seperator
	inc		di		; bump the count
	mov	[databuf+di], '8'	; store hidden attribute
	inc	di			; bump the count
	jmp	short satt5		; skip next 2 if hidden
satt3:
	cmp	ah, 070h		; is it reverse video
	jne	satt4			; skip if no
	mov	[databuf+di], ';'	; store the seperator
	inc	di			; bump the count
	mov	[databuf+di], '7'	; set reverse video
	inc	di			; bump the count
satt4:
	and	ah, 007h		; save only the foreground
	cmp	ah, 001h		; is it underlined
	jne	satt5			; skip if not underlined
	mov	[databuf+di], ';'	; store the seperator
	inc	di			; bump the count
	mov	[databuf+di], '4'	; store an underline attribute
	inc	di			; bump the count
satt5:
	mov	[databuf+di], 'm'	; set attribute command
	inc	di			; bump the count
endif

ifdef	emulink
	ifroom	3			; must be room for 3 bytes
	mov	[databuf+di], 01bh	; store an escape
	inc	di			; bump the count
	mov	[databuf+di], 08bh	; attribute command
	inc	di			; bump the count
	mov	[databuf+di], ah	; store the attribute
	inc	di			; bump the count
endif

ifdef	pcterm
	ifroom	3			; must be room for 3 bytes
	mov	[databuf+di], 01bh	; store an escape
	inc	di			; bump the count
	mov	[databuf+di], 'G'	; attribute command
	inc	di			; bump the count
	mov	al, '0' 		; base attribute
	test	ah, 080h		; should it blink
	jz	seta2			; skip if no
	add	al, 2			; add in the blink attribute
seta2:
	test	ah, 008h		; should it be high intensity
	jnz	seta3			; skip if no
	add	al, '@'-'0'		; add in low intensity
seta3:
	and	ah, 077h		; any foreground or background
	jnz	seta4			; jump if not hidden
	add	al, 1			; add in hidden attribute
	jmp	short seta6		; skip next 2 if hidden
seta4:
	cmp		ah, 070h	; is it reversed
	jne	seta5			; skip if no
	add	al, 4			; add reverse attribute
seta5:
	and	ah, 007h		; save the foreground
	cmp	ah, 001h		; should it be underlined
	jne	seta6			; skip if no
	add	al, 8			; add underline attribute
seta6:
	mov	[databuf+di], al	; store the new attribute
	inc	di			; bump the count
endif

	pop	ax			; restore ax
setax:
	ret				; return to caller

	subttl	setchar - prepare to send character to display
	page
;-----------------------------------------------------------------------
; send character in al to terminal
;-----------------------------------------------------------------------
	assume	ds:nothing,es:nothing,ss:nothing
setchar:
	test	[si].tmode, print	; are we in print mode
	jz	setch1			; jump if no
	call	notprint		; reset print mode
setch1:
	cmp	al, ' ' 		; is it a control character
	jb	setch2			; jump if yes
	ifroom	1			; must be room for 1 byte
	mov	[databuf+di], al	; store the character
	inc	di			; bump the counter
	ret				; return to caller
setch2:
	cmp	al, 01bh		; is it an escape
	jne	setch3			; jump if not escape
	setnorm 			; make sure not in monitor mode
	ifroom	2			; must be room for 2 bytes
	mov	[databuf+di], al	; store the escape
	inc	di			; bump the counter
	mov	[databuf+di], al	; store a second one
	inc	di			; bump the counter
	ret				; all done for escape
setch3:
	test	[si].tmode, monitor	; are we in monitor mode
	jnz	setch4			; press on if yes
	or	[si].tmode, monitor	; turn on monitor mode
	ifroom	2			; must be room for 2 bytes
	mov	[databuf+di], 01bh	; store an escape
	inc	di			; bump the count
	mov	[databuf+di], 'U'	; set monitor mod
	inc	di			; bump the count
setch4:
	push	ax			; save ax
	or	al, al			; is it a null
	jnz	setch5			; jump if no
	mov	al,' '			; make the null a space
setch5:
	ifroom	1			; must be room for 1 more
	mov	[databuf+di], al	; store the character
	inc	di			; bump the count
	pop	ax			; restore ax
	ret				; return to caller

	subttl	notmonitor - make sure we're not in monitor mode
	page
;-----------------------------------------------------------------------
; make sure we're not in monitor mode
;-----------------------------------------------------------------------
notmonitor:
	test	[si].tmode, monitor	; are we in monitor mode
	jz	notprint		; check print mode if no
	and	[si].tmode, not monitor ; turn off monitor mode
	ifroom	2			; must be room for 2 bytes
	mov	[databuf+di], 01bh	; store an escape
	inc	di			; bump the count
	mov	[databuf+di], 'u'	; turn off monitor mode
	inc	di			; bump the count
notprint:
	test	[si].tmode, print	; are we in print mode
	jz	notexit 		; exit if no
	and	[si].tmode, not print	; turn off print mode
	push	bx			; save bx
	push	es			; save es
	mov	bx,cs			; command segment to bx
	mov	es,bx			; set es to segment of command d
	mov	bx, offset printoff	; address of print off command
	call	movestr 		; move the string to the buffer
	pop	es			; restore es
	pop	bx			; restore bx
notexit:
	ret				; return to caller - modes reset

	subttl	movestr - move a string of bytes to the terminal buffer
	page
;-----------------------------------------------------------------------
; move a string of bytes to the terminal buffer (located in the stack)
;-----------------------------------------------------------------------
	assume	ds:nothing,es:nothing,ss:nothing
movestr:
	push	ax			; save ax
	push	cx			; and cx
	xor	cx, cx			; clear the counter
	mov	cl, es:[bx]		; get the count
	inc	bx			; bump the offset
	mov	ax, cx			; count to ax
	add	ax, di			; add count in buffer
	cmp	ax, bufsiz		; do we have room
	jb	ms10			; skip the write if theres room
	call	senddata		; send data and empty the buffer
ms10:
	mov	al, es:[bx]		; get a character
	inc	bx			; bump the pointer
	mov	[databuf+di], al	; put it in the buffer
	inc	di			; bump the count
	loop	ms10			; continue until all moved
	pop	cx			; restore cx
	pop	ax			; restore ax
	ret				; return to caller

	subttl	senddata - send a buffer of data to the terminal
	page
;-----------------------------------------------------------------------
; send a buffer of data to the terminal
;-----------------------------------------------------------------------
	assume	ds:nothing,es:nothing,ss:nothing
senddata:
	cmp	di, 0			; is there anything to send
	je	sd30			; exit if no
	mov	[si].string, 0ffh	; show we have i/o in progress
	push	ax			; save
	push	bx			;  all
	push	cx			;   registers
	push	dx			;    used
	push	si			;     for
	push	es			;      setup
	cmp	[si].drvf, 0		; does he support string output
	je	sd50			; jump if no
	mov	ax, ss			; data segment to ax
	mov	es, ax			; set es to segment of buffer
	mov	bx, bp			; set bx to offset of data
	mov	cx, di			; set cx to count of data
	mov	dx, [si].port		; get terminals port address
sd10:
        mov	si, 91		  	; only allow 5 seconds per char
	mov	ah, 14			; string output
	do14h				; send the data to serial.sys
	cmp	ax, cx			; did they all get sent
	je	sd20			; exit if yes
	add	bx, ax			; adjust the data offset
	sub	cx, ax			; and the count
	jcxz	sd20			; quit if no more to do
	jmp	short sd10		; go try to send the reset
sd20:
	mov	di, 0			; show the data has been sent
	pop	es			; restore
	pop	si			;  the
	pop	dx			;   original
	pop	cx			;    registers
	pop	bx
	pop	ax
	mov	[si].string, 0		; show i/o completed
sd30:
	ret				; return to caller

; send a buffer of data to the terminal via int14 - func 01

sd50:
	mov	cx, di			; move count to cx
	mov	di, 0			; start at beginning of buffer
	mov	dx, [si].port		; get the port address
sd60:
	mov	al, [databuf+di]	; get it out of the buffer
	inc	di			; bump the offset
sd70:
	mov	ah, 1			; send a character
	do14h				; call int14
	cmp	ah, 0			; did he send the character
	jns	sd80			; jump if ok
	jmp	short sd70		; go try it again
sd80:
	loop	sd60			; continue until all sent
	mov	di, 0			; show the buffer has been sent
	pop	es
	pop	si			; restore
	pop	dx			;  the
	pop	cx			;   corrupted
	pop	bx
	pop	ax			;    register
	mov	[si].string, 0		; show i/o completed
	ret				; return to caller

	subttl	ddtinit - mos device driver init
	page
;-----------------------------------------------------------------------
; initialization - set driver length and exit
;-----------------------------------------------------------------------
ddtinit proc	near
	mov	dx, offset ddtmsg	; point to initialization message
	mov	ah, 9			; print string on console
	int	21h			; let mos do it
	mov	word ptr es:[bx+14], offset ddtinit  ; store our location
	mov	es:[bx+16], cs		; in the request buffer
	mov	ax, 0100h		; unknown
	ret				; return to caller
ddtinit endp

ifdef	emulink
ddtmsg	db	'ELTERM terminal device driver installed V4.00 (900206)' ;@@XLAT
	db	13,10
	db	'(c) Copyright 1988, 1989, 1990 The Software Link, Incorporated' ;@@XLAT
	db	13,10,'$'
endif

ifdef	att
ddtmsg	db	'ATTERM terminal device driver installed V4.00 (900206)' ;@@XLAT
	db	13,10
	db	'(c) Copyright 1988, 1989, 1990 The Software Link, Incorporated' ;@@XLAT
	db	13,10,'$'
endif

ifdef	pcterm
ddtmsg	db	'PCTERM terminal device driver installed V4.00 (900206)' ;@@XLAT
	db	13,10
	db	'(c) Copyright 1988, 1989, 1990 The Software Link, Incorporated' ;@@XLAT
	db	13,10,'$'
endif
ddt	ends
	end
