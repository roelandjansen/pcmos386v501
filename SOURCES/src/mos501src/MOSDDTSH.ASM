	include page.inc

	include shgraph.inc		; to define conditional assembly of
					; pcterm, emulink, at&t or sherwood
					; driver.

IFDEF PCTERM
	title	pcterm.sys (v5.02) - mos pc shadow terminal driver module
ENDIF

IFDEF SHERWOOD
	title	swterm.sys (v5.02) - mos sherwood terminal driver module
ENDIF

IFDEF EMULINK
	title	elterm.sys (v5.02) - mos emulink terminal driver module
ENDIF

IFDEF ATT
	title	atterm.sys (v5.02) - mos at&t 605 terminal driver module
ENDIF

IFDEF W7TERM
	title	w7term.sys (v5.02) - mos WYSE 370 terminal driver module
ENDIF

IFDEF TRTERM
	title	trterm.sys (v5.02) - mos TR-170 terminal driver module
ENDIF

IFDEF VT420
	title	v4term.sys (v5.02) - mos DEC VT420 terminal driver module
ENDIF

comment ^===============================================================
		development specification

 program name:	mosddtsh.asm	assigned to: rod girod
 module name:	mosddtsh	assign date: 05/09/88
 entry points:	shterm		completed:   05/25/88
 entry from:	mosint10, mosint16, mosvidrm
 entry method:	call dword [vector] with ah = function number
 calls: 	i10old (boot interrupt 10h)
 purpose:	mos interface to pc terminal, emulink and at&t 605.
 refer to:	n/a
 last update:	n/a

 this module is the mos terminal driver for the pc (shadow) terminal,
 emulink, and the at&t 605.

 this driver will support:
   1.	the pc (shadow) terminal with xpc protocol and without graphics
	and	color.
   2.	emulink with xpc protocol and with graphics and color.
   3.	the at&t 605 terminal with xpc protocol and without graphics
	and	color.

 the driver will be opened by mositask which will read a four byte
 vector to the function interpretation code

=======================================================================

rdg 08/18/88	corrected setct1 so that it saved the currently selected
		cursor style (like it used to) so as to prevent
		constant setting of the cursor style.
		corrected wrcha1 - wrcha3 so as to not corrupt the stack
		when a write is requested that is writing data that is
		already in the screen buffer at the designated locatio
		corrected wrcho1 - wrcho3 so as to not corrupt the stack
		when a write is requested that is writing data that is
		already in the screen buffer at the designated locatio

rdg 09/27/88	corrected setcp1 and setcp2 for emulink because emulink
  		does not support forward space or backspace

rdg 11/29/88	modified setcursor to use only direct cursor addressing
  		for emulink.  emulink will not function properly if
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
		that flag conditions can be returned to the caller.
		modified inkbdata to return the carry flag set if the
		terminal has disconnected (carrier dropped).

rdg 03/30/89	modified register (reg3) to check if any flow control
		was configured at startup, and to not force xpc flow
		control if something was configured at startup.

rdg 05/01/89	modified scrollup and scrolldn to take advantage of
		emulink's ability to do the scrolling locally.
		modified wrstr to use emulink's repeat character
		function.

rkg 07/17/89	added function 18 to terminal driver for keyb status

mjs 09/14/89	modified the check character function call to flush
		0feh and 0ffh calls as well as null codes.  this was
		done to accomodate stargate's cluster controller.

sah 10/17/89	correct cursor off control, esc . 0 instead esc . 7

cbk 11/22/89	removed setting of si for function 14 calls 1 & 2
		removed block of emulink using repeat writes in graphics mode
		emulink pass 0ffh to clear screen when receives an fdh.

bwr 11/28/89	marked messages for foreign language translation.

cbk 01/31/89	added scan code verification to inkbdata for emulink

sah 02/02/90	corrections for revelations technologies and scrolling
		a single line

mjs 03/20/90	modified register to call int14fun23 and to call
		int14fun11 if any error during register.  this was done
		to accomodate stargate's cluster controller.

cbk 05/01/90	modified setwindow to pass emulink graphic lines to
		wrstrg one line at a time.  changed setmode to send
		escape seq for mode 640x320.

cbk 06/06/90	commented out an invalid test from port register that
		was resetting protocol when it shouldn't
cbk 06/13/90	changed register port logic to include cd/auto reboot
		that may have been done in serial driver when it sets
		port protocol.

cbk 08/03/90	changed set cursor routine to not do cursor right for
		at&t (705 doesn't handle it & according to tech specs
		neither does the 605).

sah  11/13/90	previsions so that emulink 3.0's Send and Fetch can
		disable terminal io by setting high bit of port

sah  12/06/90	always force elterm.sys to use xpc protocal

sah  03/06/91	corrections for emulink's rep writes

bwr  03/27/91	modification to produce new terminal driver
		swterm.sys for new sherwood 750/760 terminals.
		these terminals now have the ability to return
		a printer status byte to the ddt.

		also note that in mostcb.inc (not referenced by
		this module) the ddt memory structure has been modified
		to allow for the new variables required.

bwr  04/04/91	continuing tune-up of code to prevent overrun of
		terminal.  the terminal, at times, has difficulty
		keeping up with heavy serial i/o traffic and can
		occasionally intermix a keyboard scan code into
		the printer status sequence.  the specialty sherwood
		code anticipates this as much as possible and attempts
		to make printer request calls to the terminal only when
		necessary.  all this will be subject to continuing
		testing by engineering but, at this point, appears to
		be working quite reliably.

mjs 05/24/91	completely reworked printer status logic for the 
		sherwood.  the new ddt function 12h now returns a 
		'fresh flag' to indicate when a new status value 
		has been received.

mjs 07/29/91	partial update for sherwood.  needed to check this module
		back in because cbk needed it.

cbk 07/30/91	added wyse 370 color terminal.  Fixed scroll up and down
		to handle case of clearing entire box if al greater or
		equal to number of lines in the box.  

cbk 08/22/91	added TR 170 color terminal.

SAH 11/06/91	made sure that hardware flow control bits are not modified

SAH 03/26/92	Assemble error corrections in last update.

SAH 04/09/92	Corrections for printer problem on terminals
MJS

RSR 06/01/92    Added support for 40:17 through ELTERM.

cbk 06/22/92	Added DEC VT420 terminal

======================================================================^

	subttl	group segments and include block definitions
	page

	include mosddtsh.pub

sher_lead	equ	60h		; printer status lead byte

; tcbcondd device driver data structure

ddtrec	struc				; tcbcondd device driver info
		dd	?		; ? seg:off ?
logscr		dd	?		; seg:off of current screen data
crsofs		dw	?		; current cursor offset
cols		db	?		; screen width in columns
port		dw	?		; port address of device
baud		dd	?		; initialization parameter
attrib		db	?		; currently set attribute
cursor		dw	?		; row/col of cursor location
tmode		db	?		; terminal monitor/print mode
drvf		db	?		; driver functionality level
string		db	8 dup(0)	; was  used in prior versions
tmpatr		db	?		; used by scrolling code
mode		db	?		; video hardware mode
crstyp		dw	?		; cursor style (start/stop scan)
trmlmod 	db	0		; emulink's scan code chk value

IFDEF SHERWOOD
pcode_state	db	0		; state transition variable for esc z.
printer_stat	db	0		; current printer status byte.
prs_fresh	db	0		; printer status operation complete

ELSE
printer_stat	db	?		; initialized to printer_ok for non
					; sherwood terminals.
ENDIF
IFDEF EMULINK
Led_Status       db     -1              ; 40:17 support
ENDIF

ddtrec	ends

; bit definitions of [si].tmode

monitor 	equ	00000010b	; monitor mode flag
print		equ	00000001b	; print mode flag

escp		equ	1bh		; esc code.
printer_ok	equ	90h

_text	segment para	'code'
	assume	cs:_text, ds:nothing, es:nothing, ss:nothing

mosddtsh equ	this byte
	dd	-1			; pointer to next driver
	dw	8000h			; character device flag
	dw	strat			; device strategy entry point
	dw	inter			; device interrupt entry point

IFDEF PCTERM
	db	'$$PCTERM'		; pcterm device name
ENDIF

IFDEF SHERWOOD
	db	'$$SWTERM'		; swterm device name
ENDIF

IFDEF EMULINK

IFDEF HGTERM
	db	'$$HGTERM'		; emulink device name
ELSE
	db	'$$ELTERM'		; emulink device name
ENDIF
ENDIF

IFDEF ATT
	db	'$$ATTERM'		; at&t device name
ENDIF

IFDEF W7TERM
	db	'$$W7TERM'		; wyse 370 device name
ENDIF

IFDEF TRTERM
	db	'$$TRTERM'		; TR 170 device name
ENDIF

IFDEF VT420
	db	'$$V4TERM'		; DEC VT 420 device name
ENDIF


request dd	0			; seg:off of request header

IFDEF	W7TERM
colortran	db	"!$-0QSEK6<N@UX]`"
ENDIF

	subttl strat - enque request header pointer
	page
;======================================================================
;,fs
; strat - enque request header pointer
;
; in:	
;
; out:	
;
;,fe
;=====================================================================
strat proc far
	mov	word ptr [request],bx	; store offset of request
	mov	word ptr [request+2],es	; store segment of request
	ret				; return from strategy routine
strat endp

	subttl inter - process request
	page
;======================================================================
;,fs
; inter - process request
;
; in:	
;
; out:	
;
;,fe
;=====================================================================

fn	dw	ddtinit			; 0 - init
	dw	ddtnull			; 1 - media check
	dw	ddtnull			; 2 - build bpb
	dw	ddtnull			; 3 - ioctl input
	dw	ddtread			; 4 - read
maxfn	equ	($-fn)/2

inter proc far
	push	es
	push	ds
	push	si
	push	bx
	push	ax
	mov	bx,cs
	mov	ds,bx
	assume	ds:_text
	mov	ax,00100h		; initial return status
	les	bx,[request]		; set es:bx to the request
	mov	si,es:[bx+2]		; get the command code in si low
	and	si,0ffh
	cmp	si,maxfn		; is it a valid request
	jae	inter1
	shl	si,1			; convert to a word offset
	call	fn[si]			; call the routine
	assume	ds:nothing
inter1:
	les	bx,[request]		; point es:bx to request block
	mov	es:[bx+3],ax		; store result status
	pop	ax
	pop	bx
	pop	si
	pop	ds
	pop	es
	ret
inter endp

	subttl ddtnull - processing for media check, build bpb, and ioctl
	page
;======================================================================
;,fs
; ddtnull - processing for media check, build bpb, and ioctl
;
; in:	
;
; out:	
;
;,fe
;=====================================================================
ddtnull proc near
	mov	ax,00100h		; return no error, done
	ret
ddtnull endp

	subttl ddtread - returns the terminal function vector
	page
;======================================================================
;,fs
; ddtread - returns the terminal function vector
;
; in:	
;
; out:	
;
;,fe
;=====================================================================
ddtread proc near
	lds	si,es:[bx+14]
	mov	cx,es:[bx+18]
	mov	word ptr es:[bx+18],0	; nothing read if error
	mov	ax,08103h		; error, done, unknown command
	cmp	cx,4
	jne	ddtrd1			; if not reading exactly 4 bytes
	mov	es:[bx+18],cx		; else read 4 bytes
	mov	word ptr ds:[si],offset shterm  ; store offset of shterm
	mov	ds:[si+2],cs		; and the segment
	mov	ax,00100h		; no error, done
ddtrd1:
	ret
ddtread endp

	subttl	termfn - all the terminal and keyboard functions for mos
	page

IF 0 EQ 0				; no publics for ps

; stack data buffer definitions

databuf equ	(byte ptr [bp])		; bytes to send to serial.sys
IFNDEF EMULINK
bufsiz	equ	64			; allocate 64 bytes for buffer
ELSE
bufsiz	equ	128
ENDIF

; stack register save definitions

ddes	equ	(word ptr [bp+bufsiz+00])
ddds	equ	(word ptr [bp+bufsiz+02])
ddsi	equ	(word ptr [bp+bufsiz+04])
dddi	equ	(word ptr [bp+bufsiz+06])
ddbp	equ	(word ptr [bp+bufsiz+08])
dddx	equ	(word ptr [bp+bufsiz+10])
dddl	equ	(byte ptr [bp+bufsiz+10])
dddh	equ	(byte ptr [bp+bufsiz+11])
ddcx	equ	(word ptr [bp+bufsiz+12])
ddcl	equ	(byte ptr [bp+bufsiz+12])
ddch	equ	(byte ptr [bp+bufsiz+13])
ddbx	equ	(word ptr [bp+bufsiz+14])
ddbl	equ	(byte ptr [bp+bufsiz+14])
ddbh	equ	(byte ptr [bp+bufsiz+15])
ddax	equ	(word ptr [bp+bufsiz+16])
ddal	equ	(byte ptr [bp+bufsiz+16])
ddah	equ	(byte ptr [bp+bufsiz+17])
ddfl	equ	(byte ptr [bp+bufsiz+18])
ENDIF

; macro to insure that enuf room is available in the stack buffer

ifroom	macro	bytes			; check for enuf room in buffer
	local	llabel
	cmp	di,bufsiz-bytes		; have we got enuf room
	jb	llabel			; return if yes
	call	senddata		; send the data to serial.sys
llabel:
	endm

; macro to insure the terminal is in normal mode

setnorm macro				; terminal must be in normal mode
	local	llabel
	cmp	[si].tmode,0		; are we in normal mode
	je	llabel			; return if yes
	call	notmonitor		; reset monitor or print mode
llabel:
	endm

; macro to perform simulate int14

int14h	dd	0			; segment:offset of serial.sys

do14h	macro				; simulate an int 14
	pushf
	cli
	call	cs:int14h
	endm

IFDEF ATT				; at&t unique command sequences

; at&t 605 terminal commands

ceos	   db	4,escp,'[0J'		; erase to end of screen
ceoln	   db	4,escp,'[0K'		; erase to end of line
insertline db	4,escp,'[1L'		; insert line
deleteline db	4,escp,'[1M'		; delete line
linecursor db	12,escp,'[?25;11;12h'	; set underline cursor
boxcursor  db	15,escp,'[?25;12h',escp,'[?11l'  ; set block cursor
nocursor   db	6,escp,'[?25l'		; turn off cursor
printon    db	4,escp,'[5i'		; turn on transparent print mode
printoff   db	4,escp,'[4i'		; turn off transparent print mode

ELSE					; emulink/pcterm unique command
IFDEF VT420

ceos	   db	4,escp,'[0J'		; erase to end of screen
ceoln	   db	4,escp,'[0K'		; erase to end of line
insertline db	4,escp,'[1L'		; insert line
deleteline db	4,escp,'[1M'		; delete line
linecursor db	6,escp,'[?25h'		; set cursor on
boxcursor  db	6,escp,'[?25h'  	; set cursor on
nocursor   db	6,escp,'[?25l'		; turn off cursor
printon    db	4,escp,'[5i'		; turn on transparent print mode
printoff   db	4,escp,'[4i'		; turn off transparent print mode

ELSE

; pc terminal, emulink and sherwood terminal commands.

ceos	   db	2,escp,'Y'		; erase to end of screen
ceoln	   db	2,escp,'T'		; erase to end of line
insertline db	2,escp,'E'		; insert line
deleteline db	2,escp,'R'		; delete line
IFDEF TRTERM
linecursor db	5,escp,"?'",2Eh,30h	; set underline cursor
boxcursor  db	5,escp,"?'",21h,30h	; set block cursor
nocursor   db	5,escp,"?'",20h,20h	; turn off cursor
ELSE
linecursor db	3,escp,'.6'		; set underline cursor
boxcursor  db	3,escp,'.5'		; set block cursor
nocursor   db	3,escp,'.0'		; turn off cursor
ENDIF

IFDEF SHERWOOD
printon	   db	2,escp,'w'		; turn on transparent print mode
ELSE
printon    db	2,escp,'`'		; turn on transparent print mode
ENDIF

printoff   db	2,escp,'a'		; turn off transparent print mode
ENDIF
ENDIF

IFDEF SHERWOOD
req_printer_stat	db	2,escp,'z'	; get printer status.
ENDIF

IFDEF EMULINK				; emulink unique command sequence

; emulink graphics commands

gr640	db	2,escp,'b'		; set 640x200 graphics
gr320	db	2,escp,'c'		; set 320x200 graphics
grtext	db	2,escp,'d'		; set graphics text

IFDEF HGTERM
grherc	db	2,escp,'h'
hplot   db      2,escp,'H'
hunplot db      2,escp,'U'
rhplot  db      2,escp,'r'
rhunplot db     2,escp,'t'
ENDIF

ENDIF

; console device (terminal) function table

tfn	dw	register		; func 00 - register a port
	dw	inkbdata		; func 01 - input keyboard scan
	dw	outkbctl		; func 02 - clear current scan c
	dw	setmode			; func 03 - set terminal mode
	dw	setcrstyp		; func 04 - set cursor type
	dw	setcrspos		; func 05 - position the cursor
	dw	scrollup		; func 06 - scroll screen up
	dw	scrolldn		; func 07 - scroll screen down
	dw	wrchatr			; func 08 - write char and attrb
	dw	setpalet		; func 09 - set color palette
	dw	wrtty			; func 10 - write tty
	dw	wrstr			; func 11 - write a string of ch
	dw	setwindow		; func 12 - redisplay window
	dw	wrcho			; func 13 - write character
	dw	readch			; func 14 - read character/attrb
	dw	getscr			; func 15 - get screen
	dw	prch			; func 16 - send char to printer
	dw	prstr			; func 17 - send string to print
	dw	print_status		; func 18 - get printer status

endtfn	equ	($-tfn)/2



	subttl shterm - console device (terminal) primary entry point
	page
;======================================================================
;,fs
; shterm - console device (terminal) primary entry point
;
; in:	
;
; out:	
;
;,fe
;=====================================================================
	assume	ds:nothing,es:nothing,ss:nothing
shterm proc far
	pushf
	push	ax
	push	bx
	push	cx
	push	dx
	push	bp
	push	di
	push	si
	push	ds
	push	es
	cmp	ah,endtfn		; does he want a valid function
	jae	termfn1
	sub	sp,bufsiz		; allocate buffer on the stack
	mov	bp,sp
	xor	di,di			; initialize count of data.
	mov	bl,ah			; function code to bl
	xor	bh,bh
	shl	bx,1			; make word offset for table
	call	tfn[bx]			; call the desired function
	add	bp,bufsiz		; deallocate the buffer
	mov	sp,bp			; reset the stack pointer
termfn1:
	pop	es
	pop	ds
	pop	si
	pop	di
	pop	bp
	pop	dx
	pop	cx
	pop	bx
	pop	ax
	popf				; retrieve the modified flags
	ret
shterm endp

	subttl register - register port address, receive key buffer flag
	page
;======================================================================
;,fs
; register - register port address, receive key buffer flag
;
; in:	ah = 00h
;	dx = port address
;	ds:si -> tcbddt for this terminal for this partition
;
; out:	[ddes]:[ddbx] -> key buffer flag
;	 key buffer flag is <> 0 while scan codes buffered
;	[ddal] = 80h if master console
;		 40h if terminal with graphics (emulink)
;		 00h if terminal
;	[ddah] = 0 if no error
;	       = 1 if bad port number
;	       = 2 if bad baud rate
;
;,fe
;=====================================================================
              
IF 0 EQ 0				; no publics for ps

; status return definitions

badprt	equ	1			; bad port number
badbau	equ	2			; bad baud rate
ENDIF

; register the port

	assume	ds:nothing,es:nothing,ss:nothing
register proc near
	cmp	word ptr [int14h+2],0	; is this our first time thru
	jne	reg1			; skip it if yes
	push	ds
	xor	ax,ax
	mov	ds,ax			; set ds to interupt vector segm
	lds	ax,dword ptr ds:[14h*4]	; get segment:offset of int 14
	mov	word ptr [int14h],ax	; store the offset
	mov	word ptr [int14h+2],ds	; and the segment
	pop	ds
reg1:
	mov	[si].cursor,-1		; initialize the cursor location
	mov	[si].attrib,-1		; initialize the current attribu
	mov	[si].crstyp,-1		; initialize the cursor style
	mov	[si].tmode,-1		; initialize the current mode
	mov	[si].printer_stat,printer_ok
	mov	[si].drvf,0		; initialize driver functionality
	mov	dx,[si].port		; get the port address
	mov	ah,13			; register the port
	do14h				; call serial.sys
	or	ah,ah			; is all ok
	jz	reg2			; continue if yes
	mov	[ddah],badprt		; show bad port address
	jmp	reg5			; no need to continue
reg2:
	mov	[ddes],es		; store segment of keyboard flag
	mov	[ddbx],bx		; store offset of keyboard flag

; this is done for the sake of stargate's cluster controller.
; it must be done right after the function 13 call.
; after this call, if any errors within this ddt register function, must
; call int14 function 11 to disable the port.  this is required so that
; the cluster controller driver can know it should deallocate its resources.

	mov	bx,ds
	mov	dx,[si].port		; get the port address
	mov	ah,23
	do14h				; register ownership
	mov	dx,[si].port		; get the port address
	mov	bx,word ptr [si].baud	; get the extended baud rate
	mov	cx,word ptr [si].baud+2	; " " " " " " " " " " " " "
	mov	ah,4			; extended port init
	mov	al,003h			; 8 data, 1 stop, no parity
	do14h				; call serial.sys
	or	ah,ah			; is all ok
	jz	reg3			; continue if yes
	mov	[ddah],badbau		; invalid baud rate selection
	jmp	reg5x			; exit if unable to initialize
reg3:
	mov	ah,12			; get the current setup
	mov	dx,[si].port		; get the port address
	do14h				; call serial.sys

; if emulink, force protocal always to xpc, emulink requires xpc

IFNDEF EMULINK
	test	ah,00fh			; is any flow control configured
	jnz	reg4			; leave as is if yes
ENDIF
	mov	al,ah
	and	al,00001100b		; keep hardware flow control
	or	al,003h			; set xon/xoff
	and	ah,030h			; jump if no connection
	cmp	ah,0
	je	reg3a			;  info
	or	al,ah			; else or in connection info
	or	al,080h			; or in change cd bit
reg3a:
	mov	ah,5			; set line protocol
	mov	bh,067h			; xoff character
	mov	bl,065h			; xon character
	mov	dx,[si].port		; get port address
	do14h				; call serial.sys
reg4:
	mov	[ddah],0		; no errors
	mov	ah,6			; driver id function
	mov	dx,[si].port		; get the port address
	do14h				; call the driver
	or	ah,ah			; did he do this right
	jns	reg5			; leave character mode if no
	cmp	al,14			; does it support string output
	jb	reg5			; jump if no string output
	mov	[si].drvf,0ffh		; show string output ok
	jmp	short reg5
reg5x:
	mov	ah,11			; if any error after register
	mov	dx,[si].port		; ownership, disable the port
	do14h
reg5:

IFDEF EMULINK
IFDEF HGTERM
	mov	[ddal],010h		; graphics, hercules, not mc
ELSE
	mov	[ddal],040h		; graphics, but not master conso
ENDIF
ELSE
IFDEF W7TERM
	mov	[ddal],020h		; color no graphics no master conso
ELSE
IFDEF TRTERM
	mov	[ddal],020h		; color no graphics no master conso
ELSE
	mov	[ddal],000h		; no graphics for pcterm
ENDIF
ENDIF
ENDIF

	ret
register endp

	subttl inkbdata - input keyboard scan code
	page
;======================================================================
;,fs
; inkbdata - input keyboard scan code
;
; key scan code is read non-destructively (unless a null is found)
;
; in:	ah = 01h
;	ds:si -> tcbddt
;
; out:	[ddal] = bit  7	- key break if 1, key make or key repeat if 0
;	 bits 6-0 - key scan code 01h - 07dh
;	[ddfl]   cy = 1 if terminal has disconnected (carrier dropped)
;	         cy = 0 if all normal
;
;,fe
;=====================================================================
	assume	ds:nothing,es:nothing,ss:nothing
inkbdata proc near
	and	[ddfl],not 001h		; initialize the carry flag
	mov	dx,[si].port		; get the port address

IFDEF EMULINK
	test	dx,8000h
	jnz	kbdat0
	test	dx,8000h
	jnz	kbdat0
        mov     ax,[dddx]
        cmp     ax,[ddcx]
        jne     kbtestskip
        cmp     al,[si].Led_Status
        je      kbtestskip
        mov     [si].Led_Status,al
	mov	[databuf+di],escp
	inc	di
	mov	[databuf+di],'~'
	inc	di
	mov	[databuf+di],'k'
	inc	di
       	mov	[databuf+di],al
	inc	di
        call    senddata

kbtestskip:



ENDIF

	mov	ah,8			; input status check
	do14h				; call serial.sys
	jc	kbgone			; carry set if terminal gone.
	jz	kbdat0			; zf set if no data.
	jmp	short kbdat1		; data available.
kbgone:
	or	[ddfl],001h		; show the terminals is gone
kbdat0:
	mov	[ddal],0		; show mos nothing there
	ret				; return to caller
kbdat1:

IFDEF SHERWOOD

; are we processing a printer status sequence?

	cmp	byte ptr [si].pcode_state,0
	je	kbdata00

; the lead character was noticed, this should be the status

	mov	dx,[si].port		; gobble printer byte.
	mov	ah,2
	do14h
	and	al,0f8h			; bits 7-3 supported.
	mov	[si].printer_stat,al	; save current print status.
	mov	[si].pcode_state,0	; reset for esc z sensing.
	mov	[si].prs_fresh,1	; flag the operation as complete
	xor	al,al			; return null.
	jmp	kb_exit
kbdata00:
ENDIF

	or	al,al			; if read a 0, 0feh or 0ffh
	jz	kbdat1a			; then flush the char

IFDEF EMULINK				; emulink is doing scan code verifying
	cmp	al,0fbh			; turn off ascii mode
	jne	kbdata03
	mov	[si].trmlmod,0
	jmp	short kbdat1a
kbdata03:
	cmp	al,0fch
	jne	kbdata05
	mov	[si].trmlmod,al		; mark ascii mode
	jmp	short kbdat1a
kbdata05:
	cmp	al,0fdh			; emulink uses 0fdh
	jne	kbdata10
	mov	al,0ffh
	jmp	kbdat2			; to get screen refresh
kbdata10:
	cmp	al,0efh
	ja	kbdat1a
	mov	bh,[si].trmlmod
	cmp	bh,0fch			; ascii mode does no checking
	je	kbdat2			; but just passes char on
	cmp	bh,0			; if haven't rcvd check byte
	je	kbdata15		; go chk if this is one
	and	bh,0fh			; else go compare the two
	jmp	cdcomp
kbdata15:
	mov	bh,al			; has to be a scan check code
	and	al,0f0h
	cmp	al,0e0h
	jne	kbdat1a			; else ignore it as noise
	and	bh,0fh
	mov	dx,[si].port		; get the port address
	mov	ah,2			; read a character(clear scan cd ck)
	do14h				; call serial.sys
	mov	ah,8			; input status check
	do14h				; call serial.sys
	jc	kbgone
	jnz	cdcomp
	or	al,bh
	mov	[si].trmlmod,al		; save the scan code check byte
	xor	al,al
	jmp	short kbdat2		; and return no char
cdcomp:
	mov	[si].trmlmod,0		; kill the scan code chk byte
	mov	bl,al
	mov	dl,al
	shr	dl,1			; move hi nibble to low
	shr	dl,1
	shr	dl,1
	shr	dl,1
	and	bl,0fh			; get rid of hi nibble
	xor	bl,dl
	cmp	bl,bh			; ignore char if doesn't
	jne	kbdat1a			; match scan code ck byte
ENDIF

	cmp	al,0feh			; and return a null code
	jb	kbdat2

kbdat1a:
	mov	dx,[si].port		; get the port address
	mov	ah,2			; read a character(clear the null)
	do14h				; call serial.sys
	xor	al,al			; clear the character
	jmp	short kb_exit		; and get out immediately.
kbdat2:

IFDEF SHERWOOD

; if the state variable is clear, check to see if an esc z sequence is
; beginning.  if so, then gobble the esc character and return a null
; character to the app. (indicating no character ready).  on the next
; pass, see if a 'z' is sent.	if not, then the esc will be sent
; to the app.

	cmp	al,sher_lead		; printer status lead char?
	jne	kb_exit
	mov	dx,[si].port		; get the port address.
	mov	ah,2			; flush from input buffer.
	do14h
	mov	[si].pcode_state,1
	xor	al,al
ENDIF

kb_exit:
	mov	[ddal],al		; store the character
	ret				; return to caller
inkbdata endp 

	subttl outkbctl - clear current scan code from terminal driver
	page
;======================================================================
;,fs
; outkbctl - clear current scan code from terminal driver
;
; in:	ah = 02h
;	al = bit 7 - clear buffered scan code if 1, ignored if 0
;	     bits 6-0 - ignored
;	ds:si -> tcbddt
;
; out:	
;
;,fe
;=====================================================================
	assume	ds:nothing,es:nothing,ss:nothing
outkbctl proc near
	test	al,080h			; should we clear the character
	jz	kbctl1			; return if no
	mov	dx,[si].port		; get the port address

IFDEF EMULINK
	test	dx,8000h		; high bit set means ignore port
	jnz	kbctl1
ENDIF

; flush the character from the buffer.

	mov	ah,2			; read character
	do14h				; call serial.sys
kbctl1:
	ret				; return to caller
outkbctl endp 

	subttl setmode - set terminal mode
	page
;======================================================================
;,fs
; setmode - set terminal mode
;
; in:	ah = 03h
;	al = 00h, 01h - 40x25 text
;	     02h, 03h, 07h - 80x25 text
;	     04h, 05h - 320x200 graphics (currently not implemented)
;	     06h - 640x200 graphics (currently not implemented)
;            80h - herc graphics mode    
;	ds:si -> tcbddt
;	[tcbddt] = dword -> screen buffer
;	ss:bp -> databuf
;	di = databuf insertion pointer/count of bytes in databuf
;
; out:	
;
;,fe
;=====================================================================
	assume	ds:nothing,es:nothing,ss:nothing
setmode proc near

IFDEF EMULINK

IFDEF HGTERM
	mov	[si].mode,al		; store the mode
	mov	[databuf+di],escp
	inc	di
	mov	ah,'d'
	cmp     al,80h
        je      sethgmode
        cmp	al,7
	je	hgmode
sethgmode:
	mov	ah,'h'
hgmode:
	mov	[databuf+di],ah
	inc	di
ELSEIF
	mov	[si].mode,al		; store the mode
	cmp	al,4			; does he want a text mode
	jb	setmd1			; jump if yes
	cmp	al,6
	je	setmd0
	cmp	al,7			; how about this text mode
	jae	setmd1			; skip over if text mode
	mov	[databuf+di],escp
	inc	di
	mov	[databuf+di],'c'	; set 320x200
	inc	di
	call	senddata		; send the data to serial.sys
	ret
setmd0:
	mov	[databuf+di],escp
	inc	di
	mov	[databuf+di],'b'	; set 640x200
	inc	di
	call	senddata		; send the data to serial.sys
	ret
setmd1:
	mov	[databuf+di],escp
	inc	di
	mov	[databuf+di],'d'	; set graphics text
	inc	di
ENDIF
ENDIF

IFDEF TRTERM
	mov	[databuf+di],escp
	inc	di
	mov	[databuf+di],'?'
	inc	di
	mov	[databuf+di],')'
	inc	di
	mov	[databuf+di],20h	;set bit 7 for blink/bit 3 for intensity
	inc	di
ENDIF

IFDEF VT420
	ifroom	12
	mov	[databuf+di],escp
	inc	di
	mov	[databuf+di],'['
	inc	di
	mov	[databuf+di],'2'
	inc	di
	mov	[databuf+di],'5'
	inc	di
	mov	[databuf+di],'t'
	inc	di
	mov	[databuf+di],escp
	inc	di
	mov	[databuf+di],'['
	inc	di
	mov	[databuf+di],'1'
	inc	di
	mov	[databuf+di],';'
	inc	di
	mov	[databuf+di],'2'
	inc	di
	mov	[databuf+di],'5'
	inc	di
	mov	[databuf+di],'r'
	inc	di

ENDIF


	xor	dx,dx			; home the cursor
	call	xsetcrs			; go position it
	mov	ah,007h			; default attribute
	call	setattrib		; set default attribute
	mov	bx,cs			; segment of terminal commands
	mov	es,bx			; set es to terminal commands
	mov	bx,offset ceos		; erase to end of screen
	call	movestr			; move command to buffer
		  
IFNDEF LEAVE_CURSOR_ALONE
	mov	[si].crstyp,00b0ch	; show cursor an underline
	mov	bx,offset linecursor	; underline cursor command
	call	movestr			; move command to buffer
ENDIF

	call	senddata
	ret
setmode endp 

	subttl setcrstyp - set cursor type
	page
;======================================================================
;,fs
; setcrstyp - set cursor type
;
; in:	ah = 04h - set cursor type
;	ch = begin scan line
;	cl = end scan line
;	dh = row
;	dl = col
;	ds:si -> tcbddt
;	[tcbddt] = dword -> screen buffer @ page/row/col
;	ss:bp -> databuf
;	di = databuf insertion pointer/count of bytes in databuf
;
; out:	
;
;,fe
;=====================================================================
	assume	ds:nothing,es:nothing,ss:nothing
setcrstyp proc near

IFDEF LEAVE_CURSOR_ALONE
	ret
ENDIF

IFDEF EMULINK
	cmp	[si].mode,7		; are we in text mode
	jae	setct0			; jump if text mode
	cmp	[si].mode,4		; how about these text modes
	jb	setct0			; jump if text mode
	ret				; no need if graphics mode
setct0:
ENDIF

	mov	bx,cs			; get segment of command data
	mov	es,bx			; set es to command data
	mov	ax,00c0bh		; start greater than stop
	mov	bx,offset nocursor	; hidden cursor command
	cmp	ch,25			; handle special case
	jae	setct1
	sub	cl,ch			; subtract start from stop scan
	jc	setct1			; jump if cursor should be hidden
	mov	ax,0000ch		; start at 0 stop at 12
	mov	bx,offset boxcursor	; block cursor command
	cmp	cl,3			; is it more than 3 scan lines
	jae	setct1			; jump if cursor should be a blo
	mov	ax,00b0ch		; start 1 less than stop
	mov	bx,offset linecursor	; underline cursor
setct1:
	cmp	[si].crstyp,ax		; is it already set
	je	setct2			; exit if yes
	mov	[si].crstyp,ax		; set the new cursor type
	setnorm				; terminal must see escape seq
	call	movestr			; move command to the buffer
	call	senddata		; send the data to serial.sys
setct2:
	ret
setcrstyp endp 

	subttl setcrspos - set physical cursor position
	page
;======================================================================
;,fs
; setcrspos - set physical cursor position
;
; in:	ah = 05h - set physical cursor position
;	dh = row
;	dl = col
;	ds:si -> tcbddt
;	[tcbddt] = dword -> screen buffer @ page/row/col
;	ss:bp -> databuf
;	di = databuf insertion pointer/count of bytes in databuf
;
; out:	
;
;,fe
;=====================================================================
	assume	ds:nothing,es:nothing,ss:nothing
setcrspos proc near			; set the cursor position 
	cmp	[si].string,0		; are we already in progress
	je	scp1			; jump if nothing in progress
	ret				; ignore cursor if interupted
scp1:
	call	setcursor		; go figure the best way to do it
	call	senddata		; send the commands to serial.sys
	ret

; look for simple cursor movement i.e. carriage return, line feed, etc.

setcursor:

IFDEF EMULINK

; do not attempt to position the cursor if emulink is in graphics mode

	cmp	[si].mode,7		; are we in text mode
	jae	setcp0			; jump if yes
	cmp	[si].mode,4		; how about these
	jb	setcp0			; jump if text mode
	ret
setcp0:
ENDIF

	cmp	dx,[si].cursor		; do we have to move the cursor
	jne	setcp1			; jump if yes
	ret
setcp1:
	setnorm				; must be in normal mode
	ifroom	2			; must be room for 2 bytes
	push	ax

IFDEF EMULINK
	jmp	short setcp6		; emulink does not do forward sp
ENDIF

IFDEF ATT
	jmp	short setcp6		; at&t does not do forward sp
ENDIF

	mov	ax,[si].cursor		; get the current cursor position
	inc	al			; bump to the next column
	cmp	ax,dx			; is it just move to next column
	jne	setcp2			; jump if no
	mov	[si].cursor,dx		; store the new cursor position

IFDEF VT420
	ifroom	4			; must be room for 4 bytes
	mov	[databuf+di],escp	; store a cursor right
	inc	di
	mov	[databuf+di],'['
	inc	di
	mov	[databuf+di],'1'
	inc	di
	mov	[databuf+di],'C'
	inc	di
	pop	ax
	ret
ELSE
	mov	[databuf+di],00ch	; store a cursor right
	inc	di
	pop	ax
	ret
ENDIF	

setcp2:
	sub	al,2			; back up a space
	cmp	ax,dx			; is it a backspace
	jne	setcp3			; jump if not backspace
	mov	[si].cursor,dx		; store the new cursor position


IFDEF VT420
	ifroom	4			; must be room for 4 bytes
	mov	[databuf+di],escp	; store a cursor left
	inc	di
	mov	[databuf+di],'['
	inc	di
	mov	[databuf+di],'1'
	inc	di
	mov	[databuf+di],'D'
	inc	di
	pop	ax
	ret
ELSE	

	mov	[databuf+di],008h	; store a backspace
	inc	di
	pop	ax
	ret
ENDIF	

setcp3:


IFDEF VT420
	jmp	short setcp6
ENDIF

	inc	al			; back out the backspace
	inc	ah			; bump to next line
	cmp	ax,dx			; is it just a line feed
	jne	setcp4			; jump if no
	mov	[si].cursor,dx		; store the new cursor position
	mov	[databuf+di],00ah	; store a line feed
	inc	di
	pop	ax
	ret
setcp4:
	xor	al,al			; set to first column
	cmp	ax,dx			; was it a new line
	jne	setcp5			; jump if no
	mov	[si].cursor,dx		; store the new cursor position
	mov	[databuf+di],00dh	; store a carriage return
	inc	di
	mov	[databuf+di],00ah	; and a line feed
	inc	di
	pop	ax
	ret
setcp5:
	dec	ah			; back out the line feed
	cmp	ax,dx			; was it just a carriage return
	jne	setcp6			; if not, use set cursor position
	mov	[si].cursor,dx		; store the new cursor position
	mov	[databuf+di],00dh	; store a carriage return
	inc	di
	pop	ax
	ret
setcp6:
	pop	ax			; restore ax for entry to xsetcrs

; use direct cursor addressing,  when not simple one position movement.

xsetcrs:				; direct cursor addressing
	cmp	dx,[si].cursor		; do we need to move the cursor
	je	setcpx			; exit if no
	mov	[si].cursor,dx		; store the new cursor position
	setnorm				; must be in normal mode

IFDEF ATT

; at&t 605 cursor positioning

	ifroom	8			; must be room for 8 bytes
	mov	[databuf+di],escp	; store an escape
	inc	di
	mov	[databuf+di],'['	; store the csi
	inc	di
	push	ax
	mov	al,dh			; move row number to al
	call	calcpos			; convert row number to ascii
	cmp	ah,'0'			; is the first character 0
	je	xatt1			; don't send a leading zero
	mov	[databuf+di],ah		; store the high byte
	inc	di
xatt1:
	mov	[databuf+di],al		; store the low byte
	inc	di
	mov	[databuf+di],';'	; store the seperator
	inc	di
	mov	al,dl			; get the column count
	call	calcpos			; convert column count to ascii
	cmp	ah,'0'			; is the first character 0
	je	xatt2			; don't send a leading zero
	mov	[databuf+di],ah		; store the high byte
	inc	di
xatt2:
	mov	[databuf+di],al		; store the low byte
	inc	di
	mov	[databuf+di],'H'	; tell him its direct cursor add
	inc	di
	pop	ax
ELSE



IFDEF VT420 

; dec VT420 cursor positioning

	ifroom	8			; must be room for 8 bytes
	mov	[databuf+di],escp	; store an escape
	inc	di
	mov	[databuf+di],'['	; store the csi
	inc	di
	push	ax
	mov	al,dh			; move row number to al
	call	calcpos			; convert row number to ascii
	cmp	ah,'0'			; is the first character 0
	je	xatt1			; don't send a leading zero
	mov	[databuf+di],ah		; store the high byte
	inc	di
xatt1:
	mov	[databuf+di],al		; store the low byte
	inc	di
	mov	[databuf+di],';'	; store the seperator
	inc	di
	mov	al,dl			; get the column count
	call	calcpos			; convert column count to ascii
	cmp	ah,'0'			; is the first character 0
	je	xatt2			; don't send a leading zero
	mov	[databuf+di],ah		; store the high byte
	inc	di
xatt2:
	mov	[databuf+di],al		; store the low byte
	inc	di
	mov	[databuf+di],'H'	; tell him its direct cursor add
	inc	di
	pop	ax
ELSE

; pc (shadow) terminal/emulink cursor positioning

	ifroom	4			; must be room for 4 bytes
	mov	[databuf+di],escp
	inc	di
	mov	[databuf+di],'='	; direct cursor address
	inc	di
	push	dx
	add	dh,020h			; convert to ascii
	mov	[databuf+di],dh		; store row
	inc	di
	add	dl,020h			; convert to ascii
	mov	[databuf+di],dl		; store the column
	inc	di
	pop	dx
ENDIF
ENDIF

setcpx:
	ret
setcrspos endp

	subttl calcpos - calc decimal ascii row/column for ansi type devices
	page
;======================================================================
;,fs			 0
; calcpos - calc decimal ascii row/column for ansi type devices
;
; in:	al = binary number
;
; out:	ah,al two decimal ascii digits
;
;,fe
;=====================================================================

IFDEF ATT
calcpos proc near
	xor	ah,ah			; clear ah
	inc	al			; bump to true count
calcloop:
	cmp	al,10			; is it greater than 10
	jb	calcend			; done if no
	inc	ah			; bump count of 10's
	sub	al,10			; subtract this one
	jmp	short calcloop		; continue the divide loop
calcend:
	add	ax,03030h		; convert to ascii
	ret
calcpos endp 
ENDIF

IFDEF VT420 
calcpos proc near
	xor	ah,ah			; clear ah
	inc	al			; bump to true count
calcloop:
	cmp	al,10			; is it greater than 10
	jb	calcend			; done if no
	inc	ah			; bump count of 10's
	sub	al,10			; subtract this one
	jmp	short calcloop		; continue the divide loop
calcend:
	add	ax,03030h		; convert to ascii
	ret
calcpos endp 
ENDIF


	subttl scrollup - as described for the ibm pc scroll up function
	page
;======================================================================
;,fs
; scrollup - as described for the ibm pc scroll up function
;
; in:	ah = 06h - scroll up
;	al = number of lines to scroll (0 to clear region)
;	[ddbl] = attribute to use on blanked lines
;	ch = top-left-corner row
;	cl = top-left-corner col
;	dh = bottom-right-corner row
;	dl = bottom-right-corner col
;	ds:si -> tcbddt
;	[tcbddt] = dword -> screen buffer @ page/row/col
;	ss:bp -> databuf
;	di = databuf insertion pointer/count of bytes in databuf
;
; out:	
;
;,fe
;=====================================================================
	assume	ds:nothing,es:nothing,ss:nothing
scrollup proc near

; if row is same both for top and bottom then force logic
; to clear region even if call specifies line cound, most likely
; line count will be only for 1 line

	cmp	ch,dh			; same?
	jne	scrupdif
	xor	al,al			; force to clear
scrupdif:

IFDEF EMULINK
	mov	ah,[ddbl]		; get the attribute
	call	setattrib		; set the attribute
	mov	[databuf+di],escp
	inc	di
	mov	[databuf+di],086h	; scroll up command
	inc	di
	sub	dh,ch			; calculate the height
	mov	[databuf+di],dh		; store the height
	inc	di
	sub	dl,cl			; calculate the width
	mov	[databuf+di],dl		; store the height
	inc	di
	mov	[databuf+di],ch		; store the top row
	inc	di
	mov	[databuf+di],cl		; store the left column
	inc	di
	mov	[databuf+di],al		; store the number to scroll
	inc	di
	call	senddata		; send the commands
	ret
ELSE
	push	[si].cursor		; save the original cursor locat
	cmp	al,0			; do we scroll the entire window
	je	sup00
	inc	dh
	sub	dh,ch
	cmp	dh,al
	ja	sup10			;if # lines in window>al not clear all
	mov	dx,[dddx]
sup00:
	call	testnrm			; does it use default attribute
	jz	sup01			; jump if not default video
	or	cl,cl			; are we at the left margin
	jnz	sup01			; clear box if not at left margi
	mov	bh,[si].cols		; get the screen width
	dec	bh			; minus 1
	cmp	dl,bh			; are we at the right margin
	jnb	sup02			; erase line/screen if at margin
sup01:
	call	suclrb			; clear the box
	jmp	supex			; and wrapup the rest
sup02:
	cmp	dh,24			; any data below the window
	jb	sup03			; jump if data below window

; scroll complete full line window to end of screen

	xchg	cx,dx			; swap top and bottom corners
	call	xsetcrs			; position the cursor at top
	xchg	cx,dx			; put them back
	mov	bx,cs			; segment of command data
	mov	es,bx			; set es to command data
	mov	bx,offset ceos		; erase to end of screen
	call	movestr			; move commands to buffer
	jmp	supex			; go wrapup the rest

; scroll complete full line window to end of window

sup03:
	xchg	cx,dx			; swap top and bottom
	mov	cl,ch			; bottom row to cl
	inc	cl			; plus 1
	sub	cl,dh			; minus top row
	xor	ch,ch			; convert to word
	mov	bx,cs			; segment of command data
	mov	es,bx			; set es to command data
sup04:
	call	xsetcrs			; move the cursor
	mov	bx,offset ceoln		; erase to end of line
	call	movestr			; move command to buffer
	inc	dh			; bump to next line
	loop	sup04			; loop until all clear
	jmp	supex			; go wrapup when done

; scroll partial full line window

sup10:
	mov	dx,[dddx]
	or	cl,cl			; are we at the left margin
	jnz	sup20			; move box if not at left margin
	mov	bh,[si].cols		; get screen width
	dec	bh			; minus 1
	cmp	dl,bh			; are we at the right margin
	jb		sup20		; move box if not at right margi
	xchg	cx,dx			; swap top and bottom again
	call	xsetcrs			; move cursor to top corner
	xchg	cx,dx			; put top and bottom back
	mov	cl,al			; cl equals number to scroll
	xor	ch,ch			; convert to word
	mov	bx,cs			; segment of command data
	mov	es,bx			; set es to command data
sup11:
	mov	bx,offset deleteline	; delete line command
	call	movestr			; move command to the buffer
	loop	sup11			; do as many times as neccessary
	inc	dh			; bottom plus 1
	sub	dh,al			; back up scrolled lines
	call	xsetcrs			; position the cursor at data
	mov	cl,al			; scrolled count to cl
	xor	ch,ch			; convert to word
sup12:
	mov	bx,offset insertline	; insert line command
	call	movestr			; move command to the buffer
	loop	sup12			; do as many times as neccessary
	call	testnrm			; is it default attribute
	jz	sup13			; jump if not default attribute
	jmp	supex			; go wrap it up
sup13:
	call	suclrb			; set attributes in the box
	jmp	supex			; wrap up the scroll

; scroll partial line window

sup20:
	add	al,ch			; al equals first line of data
	mul	[si].cols		; calculate line offset
	mov	bl,cl			; column offset to bl
	xor	bh,bh			; convert to word
	add	bx,ax			; calculate screen offset
	shl	bx,1			; convert to word offset
	les	ax,[si].logscr		; get screen offset
	add	bx,ax			; get location of data
	xchg	cx,dx			; swap top and bottom
	call	xsetcrs			; position the at the top
	inc	cl			; right corner plus 1
	sub	cl,dl			; characters per line to move
	inc	ch			; bottom line plus 1
	sub	ch,dh			; ch equals lines in window
	sub	ch,[ddal]		; ch equals lines to move
	push	cx			; save lines/char to move
sup21:
	mov	ax,es:[bx]		; get the attribute and characte
	call	setattrib		; set the attribute
	call	setchar			; store the character
	add	bx,2			; bump to next position
	dec	cl			; one less to move
	jnz	sup21			; move the next one if more
	inc	dh			; bump to the next line
	call	xsetcrs			; position the cursor there
	pop	cx			; restore lines/character
	mov	al,[si].cols		; screen width to al
	sub	al,cl			; minus columns moved
	xor	ah,ah			; convert to word
	shl	ax,1			; make a word offset
	add	bx,ax			; bump to next line origin
	dec	ch			; one less line to do
	push	cx			; save for next time thru
	jnz	sup21			; go move the next line
	pop	cx			; clear the stack
	call	suclrb			; go clear the box
supex:
	pop	dx			; get original cursor position
	call	xsetcrs			; restore the cursor position
	call	senddata		; send any commands to serial.sys
	ret				; return to caller

; clear the vacated portion of a partial line window

suclrb:
	mov	ah,[ddbl]		; get the desired attribute
	call	setattrib		; set the attribute
	mov	ax,[ddax]		; retrieve scroll count
	mov	cx,[ddcx]		; and upper left corner
	mov	dx,[dddx]		; and lower right corner
	cmp	al,0			; are we clearing them all
	je	suclrb0			;jump to clear all
	inc	dh
	sub	dh,ch
	cmp	dh,al
	mov	dx,[dddx]
	ja	suclrb1			;if # lines in box>al not clear all
suclrb0:	
	mov	al,dh			; get bottom line
	inc	al			; plus 1
	sub	al,ch			; minus top line = lines to clear
suclrb1:
	inc	dh			; must use bottom plus one
	sub	dh,al			; back up to first line to clear
	xchg	dl,cl			; dl = left col, cl = right col
	call	xsetcrs			; position the cursor
	inc	cl			; right column plus 1
	sub	cl,dl			; character per line to clear
	mov	ch,al			; ch - lines to clear
	push	cx			; save lines/characters
suclrb2:
	ifroom	1			; must be room for 1 more byte
	mov	[databuf+di],020h	; store a space
	inc	di			; bump the pointer
	dec	cl			; dec the count to clear
	jnz	suclrb2			; clear until line done
	inc	dh			; move to the next line
	call	xsetcrs			; move the cursor
	pop	cx			; restore line/char
	dec	ch			; any more lines to do
	push	cx			; save it for later
	jnz	suclrb2			; continue if more to clear
	pop	cx
	ret
ENDIF
scrollup endp 

	subttl testnrm - determine if attribute produces normal video or not
	page
;======================================================================
;,fs
; testnrm - determine if attribute produces normal video or not
;
; in:	[ddbl] contains attribute to check
;
; out:	z flag set if attribute produces abnormal video
;	z flag clear if attribute produces normal video
;	all registers unchanged
;
;,fe
;=====================================================================
IFDEF EMULINK
ELSE
testnrm proc near
	push	ax
	mov	al,[ddbl]		; get the attribute
	test	al,0f8h			; blink, reverse or bold
	jnz	tstnd			; jump if blink, reverse or bold
	cmp	al,1			; is it underline
	jne	tstnx			; jump if normal
tstnd:
	cmp	al,al			; set the zero flag
tstnx:
	pop	ax
	ret
testnrm endp 
ENDIF

	subttl scrolldn - as described for the ibm pc scroll down function
	page
;======================================================================
;,fs
; scrolldn - as described for the ibm pc scroll down function
;
; in:	ah = 07h - scroll down
;	al = number of lines to scroll (0 to clear region)
;	[ddbl] = attribute to use on blanked lines
;	ch = top-left-corner row
;	cl = top-left-corner col
;	dh = bottom-right-corner row
;	dl = bottom-right-corner col
;	ds:si -> tcbddt
;	[tcbddt] = dword -> screen buffer @ page
;	ss:bp -> databuf
;	di = databuf insertion pointer/count of bytes in databuf
;
; out:	
;
;,fe
;=====================================================================
	assume	ds:nothing,es:nothing,ss:nothing
scrolldn proc near

; if row is same both for top and bottom then force logic
; to clear region even if call specifies line cound, most likely
; line count will be only for 1 line

	cmp	ch,dh			; same?
	jne	scrdndif
	xor	al,al			; force to clear
scrdndif:

IFDEF EMULINK
	mov	ah,[ddbl]		; get the attribute
	call	setattrib		; set the attribute
	mov	[databuf+di],escp
	inc	di
	mov	[databuf+di],087h	; scroll down command
	inc	di
	sub	dh,ch			; calculate the height
	mov	[databuf+di],dh		; store the height
	inc	di
	sub	dl,cl			; calculate the width
	mov	[databuf+di],dl		; store the height
	inc	di
	mov	[databuf+di],ch		; store the top row
	inc	di
	mov	[databuf+di],cl		; store the left column
	inc	di
	mov	[databuf+di],al		; store the number to scroll
	inc	di
	call	senddata		; send the commands
	ret
ELSE
	push	[si].cursor		; save the original cursor locat
	cmp	al,0			; do we scroll the entire window
	je	sdn00
	inc	dh
	sub	dh,ch
	cmp	dh,al
	ja	sdn10			;if # lines in window>al not clear all
	mov	dx,[dddx]
sdn00:
	call	testnrm			; does it use default attribute
	jz	sdn01			; jump if not default video
	or	cl,cl			; are we at the left margin
	jnz	sdn01			; clear box if not at left margi
	mov	bh,[si].cols		; get the screen width
	dec	bh			; minus 1
	cmp	dl,bh			; are we at the right margin
	jnb	sdn02			; erase line/screen if at margin
sdn01:
	call	sdclrb			; clear the box
	jmp	sdnex			; and wrapup the rest
sdn02:
	cmp	dh,24			; any data below the window
	jb	sdn03			; jump if data below window

; scroll complete full line window to end of screen

	xchg	cx,dx			; swap top and bottom corners
	call	xsetcrs			; position the cursor at top
	xchg	cx,dx			; put them back
	mov	bx,cs			; segment of command data
	mov	es,bx			; set es to command data
	mov	bx,offset ceos		; erase to end of screen
	call	movestr			; move commands to buffer
	jmp	sdnex			; go wrapup the rest

; scroll complete full line window to end of window

sdn03:
	xchg	cx,dx			; swap top and bottom
	mov	cl,ch			; bottom row to cl
	inc	cl			; plus 1
	sub	cl,dh			; minus top row
	xor	ch,ch			; convert to word
	mov	bx,cs			; segment of command data
	mov	es,bx			; set es to command data
sdn04:
	call	xsetcrs			; move the cursor
	mov	bx,offset ceoln		; erase to end of line
	call	movestr			; move command to buffer
	inc	dh			; bump to next line
	loop	sdn04			; loop until all clear
	jmp	sdnex			; go wrapup when done

; scroll partial full line window

sdn10:
	mov	dx,[dddx]
	or	cl,cl			; are we at the left margin
	jnz	sdn20			; move box if not at left margin
	mov	bh,[si].cols		; get screen width
	dec	bh			; minus 1
	cmp	dl,bh			; are we at the right margin
	jb		sdn20		; move box if not at right margi
	inc	dh			; bottom row plus 1
	sub	dh,al			; minus number to scroll
	call	xsetcrs			; move cursor to first line to ki
	mov	cl,al			; cl equals number to scroll
	xor	ch,ch			; convert to word
	mov	bx,cs			; segment of command data
	mov	es,bx			; set es to command data
sdn11:
	mov	bx,offset deleteline	; delete line command
	call	movestr			; move command to the buffer
	loop	sdn11			; do as many times as neccessary
	mov	dx,[ddcx]		; top corner to dx
	call	xsetcrs			; position cursor at top corner
	mov	cl,al			; scrolled count to cl
	xor	ch,ch			; convert to word
sdn12:
	mov	bx,offset insertline	; insert line command
	call	movestr			; move command to the buffer
	loop	sdn12			; do as many times as neccessary
	call	testnrm			; is it default attribute
	jz	sdn13			; jump if not default attribute
	jmp	sdnex			; go wrap it up
sdn13:
	call	sdclrb			; set attributes in the box
	jmp	sdnex			; wrap up the scroll

; scroll partial partial line window

sdn20:
	mov	al,dh			; bottom row to al
	sub	al,[ddal]		; minus lines to scroll
	mul	[si].cols		; calculate line offset
	mov	bl,cl			; column offset to bl
	xor	bh,bh			; convert to word
	add	ax,bx			; calculate screen offset
	shl	ax,1			; convert to word offset
	les	bx,[si].logscr		; get screen location
	add	bx,ax			; add cursor offset
	xchg	dl,cl			; swap left and right margin
	call	xsetcrs			; position the cursor at lower lef
	inc	cl			; right corner plus 1
	sub	cl,dl			; characters per line to move
	mov	ch,dh			; bottom row to ch
	inc	ch			; bottom line plus 1
	sub	ch,[ddch]		; ch equals lines in window
	sub	ch,[ddal]		; ch equals lines to move
	push	cx			; save lines/char to move
sdn21:
	mov	ax,es:[bx]		; get the attribute and characte
	call	setattrib		; set the attribute
	call	setchar			; store the character
	add	bx,2			; bump to next position
	dec	cl			; one less to move
	jnz	sdn21			; move the next one if more
	dec	dh			; backup to the next line
	call	xsetcrs			; position the cursor there
	pop	cx			; restore lines/character
	mov	al,[si].cols		; screen width to al
	add	al,cl			; add columns moved
	xor	ah,ah			; convert to word
	shl	ax,1			; make a word offset
	sub	bx,ax			; backup to next line to move
	dec	ch			; one less line to do
	push	cx			; save for next time thru
	jnz	sdn21			; go move the next line
	pop	cx			; clear the stack
	call	sdclrb			; go clear the box
sdnex:
	pop	dx			; get original cursor position
	call	xsetcrs			; restore the cursor position
	call	senddata		; send any commands to serial.sys
	ret				; return to caller

; clear the vacated area of a partial line window (or not default attrb)

sdclrb:
	mov	ah,[ddbl]		; get the desired attribute
	call	setattrib		; set the attribute
	mov	ax,[ddax]		; retrieve scroll count
	mov	cx,[ddcx]		; and upper left corner
	mov	dx,[dddx]		; and lower right corner
	cmp	al,0			; are we clearing them all
	je	sdclrb0			;jump to clear all
	inc	dh
	sub	dh,ch
	cmp	dh,al
	mov	dx,[dddx]
	ja	sdclrb1			;if # lines in box>al not clear all
sdclrb0:	
	mov	al,dh			; get bottom line
	inc	al			; plus 1
	sub	al,ch			; minus top line = lines to clear
sdclrb1:
	xchg	cx,dx			; stop top/left and bottom/right
	add	dh,al			; add cleared to top row
	dec	dh			; back up to last cleared
	call	xsetcrs			; position the cursor
	inc	cl			; right column plus 1
	sub	cl,dl			; character per line to clear
	mov	ch,al			; ch - lines to clear
	push	cx			; save lines/characters
sdclrb2:
	ifroom	1			; must be room for 1 more bye
	mov	[databuf+di],020h	; store a space
	inc	di			; bump the pointer
	dec	cl			; dec the count to clear
	jnz	sdclrb2			; clear until line done
	dec	dh			; backup to the next line
	call	xsetcrs			; move the cursor
	pop	cx			; restore line/char
	dec	ch			; any more lines to do
	push	cx			; save it for later
	jnz	sdclrb2			; continue if more to clear
	pop	cx
	ret
ENDIF
scrolldn endp 

	subttl wrchatr - write character and attribute
	page
;======================================================================
;,fs
; wrchatr - write character and attribute
;
; in:	ah = 08h - write character and attribute at row & col & page
;	al = char to write
;	[ddbl] = attribute to write
;	cx = number of times to write
;	dh = row
;	dl = col
;	ds:si -> tcbddt
;	[tcbddt] = dword -> screen buffer @ page/row/col
;	ss:bp -> databuf
;	di = databuf insertion pointer/count of bytes in databuf
;
; out:	
;
;,fe
;=====================================================================
	assume	ds:nothing,es:nothing,ss:nothing
wrchatr proc near
	mov	bx,[ddbx]		; get the original bx
	push	di			; save buffer count
	les	di,[si].logscr		; point es:di to screen buffer
	mov	ah,bl			; move the attribute to ah
	mov	bx,ax			; move char/attrb to bx also
wrcha1:
	scasw				; compare it to the buffer
	jne	wrcha3			; jump if they're not equal
	inc	dl			; bump to the next column
	cmp	dl,[si].cols		; are we at end of line
	jb	wrcha2			; jump if no
	xor	dl,dl			; reset to column 0
	inc	dh			; bump to the next line
	cmp	dh,25			; was that the last line
	jae	wrcha2x			; exit if yes
wrcha2:
	loop	wrcha1			; go check the next char positio
wrcha2x:
	pop	di
	ret				; return if no changes
wrcha3:
	sub	di,2			; back up to the different chara
	dec	cx			; set to offset from start
	jz	wrcha4			; skip end checking if at end
	add	di,cx			; figure new offset
	add	di,cx			; " " " " " " " " "
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
	call	setchar			; store the character
	inc	dl			; here too
	cmp	dl,[si].cols		; are we at the end of the line
	jb	wrcha6			; press on if no
	cmp	dh,24			; are we on the last line
	jae	wrchax			; exit if yes
	xor	dl,dl			; set to column 0
	inc	dh			; and the next line
	call	setcursor		; move the cursor with direct cu
wrcha6:
	mov	[si].cursor,dx		; update the cursor location
	loop	wrcha5			; continue until we have done all
wrchax:
	call	senddata		; send remaining data to serial.sys
	ret
wrchatr endp 

	subttl setpalet - set color palette or background color
	page
;======================================================================
;,fs
; setpalet - set color palette or background color
;
; in:	ah = 09h - set color palette or background color
;	[ddbl] = byte as stored in crt_palette by ibm bios
;	bl and 1fh = background color)
;	bl and 20h = 20h for palette 1 else palette 0
;	ds:si -> tcbddt
;	ss:bp -> databuf
;	di = databuf insertion pointer/count of bytes in databuf
;
; out:	
;
;,fe
;=====================================================================
	assume	ds:nothing,es:nothing,ss:nothing
setpalet proc near

IFDEF EMULINK
	mov	bx,[ddbx]		; get the palette settings
	ifroom	6			; must be room for 6 bytes
	mov	[databuf+di],escp
	inc	di
	mov	[databuf+di],'v'	; set the palette color
	inc	di
	mov	al,bl			; get the data
	and	al,01fh			; save only the color
	mov	[databuf+di],al		; store it
	inc	di
	mov	[databuf+di],escp
	inc	di
	mov	[databuf+di],'V'	; select palette number
	inc	di
	mov	cl,5			; shift right 5 bits
	shr	bl,cl			; move palette number to bit 1
	mov	[databuf+di],bl		; store it
	inc	di
	call	senddata		; send it to serial.sys
ENDIF

	ret
setpalet endp 

	subttl wrtty - as described by the ibm pc write tty function
	page
;======================================================================
;,fs
; wrtty - as described by the ibm pc write tty function
;
; in:	ah = 0ah - write tty at row & col & page
;	al = char to write
;	dh = row
;	dl = col
;	ds:si -> tcbddt
;	[tcbddt] = dword -> screen buffer @ page/row/col
;	ss:bp -> databuf
;	di = databuf insertion pointer/count of bytes in databuf
;
; out:	
;
;,fe
;=====================================================================
	assume	ds:nothing,es:nothing,ss:nothing
wrtty proc near
	cmp	al,008h			; is it a backspace
	je	wrttyx			; exit if backspace
	cmp	al,00dh			; is it a carriage return
	je	wrttyx			; exit if carriage return
	cmp	al,007h			; is it a bell
	jne	wrtty1			; jump if not a bell
	setnorm				; make sure we're in normal mode
	mov	[databuf+di],007h	; store a bell
	inc	di
	jmp	short wrtty4		; go send the data and wrap up
wrtty1:
	cmp	al,00ah			; is it a line feed
	jne	wrtty2			; jump if not a line feed
	inc	dh			; bump to the next line
	cmp	dh,25			; do we need to scroll
	jb	wrttyx			; quit if no scroll needed
	dec	dh			; back up to line 24
	call	setcursor		; position the cursor
	mov	[databuf+di],00ah	; store a line feed
	inc	di
	jmp	short wrtty4		; go send the data and wrap up
wrtty2:
	call	setcursor		; position the cursor
	les	bx,[si].logscr		; point es:bx to screen buffer
	mov	ah,es:[bx+1]		; get this positions attribute
	call	setattrib		; set the attribute
	call	setchar			; set the character
	inc	dl			; bump to the next column
	cmp	dl,[si].cols		; are we at the end of the line
	jb	wrtty3			; go wrap up if not end of line
	mov	[databuf+di],00dh	; store a carriage return
	inc	di
	xor	dl,dl			; set to column 0
	mov	[databuf+di],00ah	; store a line feed
	inc	di			; bump the count
	cmp	dh,24			; are we on the last line
	jnb	wrtty3			; jump if on last line
	inc	dh			; bump to next line
wrtty3:
	mov	[si].cursor,dx		; store new cursor location
wrtty4:
	call	senddata		; send any commands to serial.sy
wrttyx:
	ret
wrtty endp 

	subttl wrstr - write a string of characters and attributes
	page
;======================================================================
;,fs
; wrstr - write a string of characters and attributes
;
; in:	ah = 0bh - write string of characters and attributes at row/col
;       al = high byte for row for Herc (HGTERM) mode ONLY
;	cx = number of chars to write (word length of string)
;	dh = row
;	dl = col
;	ds:si -> tcbddt
;	[tcbddt] = dword -> screen buffer @ page/row/col
;	[ddes]:[dddi] -> string
;	ss:bp -> databuf
;	di = databuf insertion pointer/count of bytes in databuf
;
; out:	
;
;,fe
;=====================================================================
	assume	ds:nothing,es:nothing,ss:nothing
wrstr proc near

IFNDEF EMULINK
	call	setcursor		; set the cursor to starting loc
	mov	bx,[dddi]		; get offset to the string
wrstr1:
	mov	ax,es:[bx]		; get the char/attrb pair
	add	bx,2			; bump to the next position
	call	setattrib		; set the attribute
	call	setchar			; store the character
	inc	dl			; in the register too
	cmp	dl,[si].cols		; are we at the end of the line
	jb	wrstr2			; jump if no
	cmp	dh,24			; are we at the end of the scree
	jae	wrstrx			; exit if yes
	xor	dl,dl			; set to column 0
	inc	dh			; bump to the next line
	call	setcursor		; reposition the cursor
wrstr2:
	mov	[si].cursor,dx		; store the new cursor position
	loop	wrstr1			; continue until all done
wrstrx:
	call	senddata		; send any data to serial.sys
	ret				; return to caller
ELSE

IFDEF   HGTERM
        cmp     [si].mode,7
        je      wrstr0
        jmp     wrstrh
ELSE
	cmp	[si].mode,7		; are we in a text mode
  	jae	wrstr0			; jump if yes
	cmp	[si].mode,4		; how about these
	jb	wrstr0			; jump if in text mode
	jmp	wrstrg			; jump if in graphics mode
ENDIF

wrstr0:
	call	setcursor		; set the cursor to starting loc
	mov	bx,[dddi]		; get offset to the string
	mov	[si].string+7,0		; initialize the repeat count
wrstr1:
	cmp	[si].string+7,0		; have we got a character
	jne	wrstr1a			; jump if we have already got on
	mov	ax,es:[bx]		; get the char/attrb pair
	call	setattrib		; set the attribute
wrstr1a:
	inc	[si].string+7		; bump the repeat count
	add	bx,2			; bump to the next position
	cmp	[si].string+7,8
	jae	wrstr1b
	cmp	ax,es:[bx]		; is the next one the same
	je	wrstr1c			; jump if the character is repea
wrstr1b:
	call	reptwr			; write the character
	mov	[si].string+7,0		; initialize the repeat count
wrstr1c:
	inc	dl			; in the register too
	cmp	dl,[si].cols		; are we at the end of the line
	jb	wrstr2			; jump if no
	cmp	dh,24			; are we at the end of the scree
	jae	wrstrx			; exit if yes
	call	reptwr			; write any characters before se
	mov	[si].string+7,0		; initialize the repeat count
	xor	dl,dl			; set to column 0
	inc	dh			; bump to the next line
	call	setcursor		; reposition the cursor
wrstr2:
	mov	[si].cursor,dx		; store the new cursor position
	loop	wrstr1			; continue until all done
wrstrx:
	call	reptwr			; send any remaining characters
	call	senddata		; send any data to serial.sys
	ret				; return to caller

reptwr proc near
	mov	ah,[si].string+7	; get the character count
	mov	[si].string+7,0		; reinitialize the repeat count
	cmp	ah,0			; are there any to write
	jne	reptwr1			; press on if some waiting
	ret				; return to caller
reptwr1:
	cmp	ah,1			; was the character duplicated
	jne	reptwr2			; jump if character repeated
	call	setchar			; store the character
	ret				; return to caller
;####
reptwr2:
	cmp	ah,4	
	jae	reptwr3
	push	cx
	mov	cl,ah
	xor	ch,ch
reptwrlp:
	push	ax
	push	cx
	call	setchar
	pop	cx
	pop	ax
	loop	reptwrlp
	pop	cx
	ret
reptwr3:
;######
	ifroom	4			; must be room for 4 bytes
	mov	[databuf+di],escp
	inc	di
	mov	[databuf+di],08ah	; store repeat command
	inc	di
	mov	[databuf+di],ah		; store the count
	inc	di
	mov	[databuf+di],al		; store the character
	inc	di
	ret
reptwr endp

wrstrg:

IFDEF   HGTERM

wrstrh:

        ifroom	5			; must be room for 5 bytes
	mov	[databuf+di],escp	; store an escape
	inc	di			; bump count of chars in buffer
	mov	[databuf+di],'='	; store cursor position command
	inc	di			; bump count of chars in buffer
        mov     [databuf+di],al         ; store high word of row
        inc     di
	mov	[databuf+di],dh		; store the row (binary)
	inc	di			; bump count of chars in buffer
	mov	[databuf+di],dl		; store the column (binary)
	inc	di			; bump count of chars in buffer
ELSE
	ifroom	4			; must be room for 4 bytes
	mov	[databuf+di],escp	; store an escape
	inc	di			; bump count of chars in buffer
	mov	[databuf+di],'='	; store cursor position command
	inc	di			; bump count of chars in buffer
	mov	[databuf+di],dh		; store the row (binary)
	inc	di			; bump count of chars in buffer
	mov	[databuf+di],dl		; store the column (binary)
	inc	di			; bump count of chars in buffer
ENDIF
wrstrgh1a:
	mov	bx,[dddi]		; set bx to pointer to data
wrstrg1:
	mov	ax,es:[bx]		; get the first word
	add	bx,2			; bump to the next
	dec	cx			; drop the count
	xchg	di,bx			; set di for scasw
	cmp	al,ah			; are high and low equal
	jne	wrstrg5			; jump if high and low not equal
	mov	dx,cx			; save the count in dx
	cld				; set for the right direction
	repe scasw			; check for equal bytes
	je	wrstrg2			; jump if all the same
	sub	di,2			; back up to unequal byte
	inc	cx			; count remaining
	sub	dx,cx			; dx equal repeat count
	jz	wrstrg5			; jump if not repeated
wrstrg2:
	xchg	di,bx			; restore buffer pointer
	inc	dx			; add one for first instance
	add	dx,dx			; convert word count to byte cou
wrstrg3:
	sub	dx,254			; are there more than 254
	jbe	wrstrg4			; jump if less than 254
	ifroom	4			; must be room for 4 bytes
	mov	[databuf+di],escp
	inc	di
	mov	[databuf+di],'R'	; repeat byte command
	inc	di
	mov	[databuf+di],254	; max even number repeat
	inc	di
	mov	[databuf+di],al		; store the character
	inc	di
	jmp	short wrstrg3		; go try it again
wrstrg4:
	add	dx,254			; put it back to the readl count
	ifroom	4			; must be room for 4 bytes
	mov	[databuf+di],escp
	inc	di
	mov	[databuf+di],'R'	; repeat byte command
	inc	di
	mov	[databuf+di],dl		; store the count
	inc	di
	mov	[databuf+di],al		; store the character
	inc	di
	jcxz	wrstrg8			; wrap it up if none left
	jmp	short wrstrg1		; go look at the next position
wrstrg5:
	xchg	di,bx			; restore buffer pointer
	ifroom	4			; must be room for up to 4 bytes
	cmp	al,escp			; is it an esc char?
	jne	wrstrg6			; jump if not 1b
	mov	[databuf+di],al		; must send 2 1b's to get it thru
	inc	di			; bump the count
wrstrg6:
	mov	[databuf+di],al		; store the character
	inc	di
	cmp	ah,escp			; is ah a esc
	jne	wrstrg7			; jump if not 1b
	mov	[databuf+di],ah		; must send 2 1b's to get it thru
	inc	di			; bump the count
wrstrg7:
	mov	[databuf+di],ah		; store the character
	inc	di

	jcxz	wrstrg8			; jump if no more to check
	jmp	wrstrg1			; go check the next character
wrstrg8:
	call	senddata		; send any commands to serial.sys
	ret
ENDIF
wrstr endp 

	subttl setwindow - re-display the top or bottom 24 lines
	page
;======================================================================
;,fs
; setwindow - re-display the top or bottom 24 lines
;
; in:	ah = 0ch - put screen
;	al = 0 - re-display top lines of screen
;	     1 - re-display bottom lines of screen
;	cx = screen length (words)
;	ds:si -> tcbddt
;	[tcbddt] = dword -> screen buffer @ page/row/col
;	ss:bp -> databuf
;	di = databuf insertion pointer/count of bytes in databuf
;
; out:	
;
;,fe
;=====================================================================
	assume	ds:nothing,es:nothing,ss:nothing
setwindow proc near
	push	[dddx]
	push	[dddi]
	push	[ddes]
	push	di
	les	di,[si].logscr		; get pointer to screen data
	mov	[ddes],es		; set ddes for screen buffer
	mov	[dddi],di		; set dddi for screen buffer
	pop	di			; restore buffer pointer
	xor	dx,dx			; set to start of screen
	mov	[dddx],dx		; set dddx to start of screen

IFDEF EMULINK
	cmp	[si].mode,7		; are we in a text mode
	jae	usewrstr		; jump if yes
	cmp	[si].mode,4		; how about these
	ja	setwg			; jump if in graphics mode
usewrstr:
ENDIF

	call	wrstr			; call write string
	pop	[ddes]
	pop	[dddi]
	pop	[dddx]
	ret

IFDEF EMULINK
setwg:					; parcel it to wrstr 1 line at a time
	mov	cx,200			; 200 lines
setwglp:
	push	cx
	push	dx
	mov	cx,40			; 80 cols in row
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
	pop	[ddes]
	pop	[dddi]
	pop	[dddx]
	ret
ENDIF
setwindow endp 

	subttl wrcho - write char only
	page
;======================================================================
;,fs
; wrcho - write char only
;
; in:	ah = 0dh - write char only at row & col
;	al = char to write
;	cx = number of times to write
;	dh = row
;	dl = col
;	ds:si -> tcbddt
;	[tcbddt] = dword -> screen buffer @ page/row/col
;	ss:bp -> databuf
;	di = databuf insertion pointer/count of bytes in databuf
;
; out:	
;
;,fe
;=====================================================================
	assume	ds:nothing,es:nothing,ss:nothing
wrcho proc near
	push	di			; save the buffer count
	les	di,[si].logscr		; point es:di to screen buffer
wrcho1:
	scasb				; is it already here
	jne	wrcho3			; jump if no
	inc	di			; bump past the attribute
	inc	dl			; bump the column count
	cmp	dl,[si].cols		; are we at the end of a line
	jb	wrcho2			; jump if no
	xor	dl,dl			; do a carriage return
	inc	dh			; and a line feed
	cmp	dh,25			; are we done
	jae	wrcho2x			; exit if yes
wrcho2:
	loop	wrcho1			; check until all have been chec
wrcho2x:
	pop	di
	ret				; return if screen already written
wrcho3:
	push	di			; save location of first attribut
	dec	di			; back up to the different chara
	dec	cx			; set to offset from the start
	jz	wrcho4			; skip end checking if at end
	add	di,cx			; figure new offset
	add	di,cx			; " " " " " " " " "
	std				; start looking from the rear
wrcho3a:
	scasb				; is it already here
	jne	wrcho4			; quit if no
	dec	di			; skip over the attribute
	loop	wrcho3a			; keep looking until done
wrcho4:
	cld				; restore the directional flag
	inc	cx			; back out the last compare
	pop	bx			; restore location of first diff
	pop	di			; restore buffer offset
	call	setcursor		; position the cursor
wrcho5:
	mov	ah,es:[bx]		; get the current attribute
	add	bx,2			; bump to the next position
	call	setattrib		; set the current attribute
	call	setchar			; store the character
	inc	dl			; here too
	cmp	dl,[si].cols		; are we at the end of the line
	jb	wrcho6			; jump if no
	cmp	dh,24			; are we at bottom of the screen
	jae	wrchox			; exit if at bottom
	xor	dl,dl			; do a carriage return
	inc	dh			; and a line feedd
	call	xsetcrs			; use direct cursor addressing
wrcho6:
	mov	[si].cursor,dx		; store the new cursor position
	loop	wrcho5			; loop until done
wrchox:
	call	senddata		; send remaining data to serial.sys
	ret
wrcho endp 

	subttl readch - read char/attribute at row & col & page
	page
;======================================================================
;,fs
; readch - read char/attribute at row & col & page
;
; in:	ah = 0eh - read char/attribute at row & col & page
;	 (master console only)
;	dh = row
;	dl = col
;	ds:si -> tcbddt
;	[tcbddt] = dword -> screen buffer @ row/col/page
;	ss:bp -> databuf
;	di = databuf insertion pointer/count of bytes in databuf
;
; out:	
;
;,fe
;=====================================================================
	assume	ds:nothing,es:nothing,ss:nothing
readch proc near
	ret				; not supported on terminal
readch endp 

	subttl getscr - get screen
	page
;======================================================================
;,fs
; getscr - get screen
;
; in:	ah = 0fh - get screen
;	 (master console only)
;	cx = word length to get
;	ds:si -> tcbddt
;	[tcbddt] = dword -> logical screen buffer
;	ss:bp -> databuf
;	di = databuf insertion pointer/count of bytes in databuf
;
; out:	
;
;,fe
;=====================================================================
	assume	ds:nothing,es:nothing,ss:nothing
getscr proc near
	ret				; not supported on terminal
getscr endp 

	subttl prch - print a character on the terminal's local printer
	page
;======================================================================
;,fs
; prch - print a character on the terminal's local printer
;
; in:	ah = 10h
;	al = char to print
;	ds:si -> tcbddt
;	ss:bp -> databuf
;	di = databuf insertion pointer/count of bytes in databuf
;
; out:	[ddah] as in int 17h call
;
;,fe
;=====================================================================
	assume	ds:nothing,es:nothing,ss:nothing
prch proc near
 	test	[si].tmode,print	; are we in print mode
	jnz	prch1			; jump if yes
	setnorm				; set to normal mode
	or	[si].tmode,print	; turn on print mode
	mov	bx,cs			; get segment of command data
	mov	es,bx			; set es to command data
	mov	bx,offset printon	; address of printer on command
	call	movestr			; move it to the buffer
prch1:
	mov	[databuf+di],al		; store the character
	inc	di
	call	senddata		; send any data to serial.sys
prch_exit:
	mov	ah,[si].printer_stat
	mov	[ddah],ah
	ret
prch endp 

	subttl prstr - print a string on the terminal's local printer
	page
;======================================================================
;,fs
; prstr - print a string on the terminal's local printer
;
; in:	ah = 11h
;	[ddes]:[dddi] -> string to print
;	es = [ddes]
;	cx = length (bytes) to print
;	ds:si -> tcbddt
;	ss:bp -> databuf
;	di = databuf insertion pointer/count of bytes in databuf
;
; out:	[ddah] as in int 17h call
;	if all not printed:
;	 di -> first char not printed
;	 cx = number not printed
;
;,fe
;=====================================================================
	assume	ds:nothing,es:nothing,ss:nothing
prstr proc near
	mov	bx,[dddi]		; get pointer to data
	test	[si].tmode,print	; are we in print mode
	jnz	prstr1			; jump if yes
	setnorm				; set to normal mode
	or	[si].tmode,print	; turn on print mode
	push	es
	push	bx
	mov	bx,cs			; get segment of command data
	mov	es,bx			; set es to command data
	mov	bx,offset printon	; address of printer on command
	call	movestr			; move it to the buffer
	pop	bx
	pop	es
prstr1:
	ifroom	1			; must be room for 1 more byte
	mov	al,es:[bx]		; get a character
	inc	bx
	mov	[databuf+di],al		; store the character
	inc	di
	loop	prstr1			; go get the next character
	call	senddata		; send any data to serial.sys
	mov	ah,[si].printer_stat
	mov	[ddah],ah
	mov	[ddcx],cx
	ret				; return when finished
prstr endp 

	subttl print_status - printer status
	page
;======================================================================
;,fs
; print_status - printer status
;
; for the sherwood case, when entry al == 0, clear the fresh-flag
; and initiate a printer status request.  the fresh-flag will be
; set when the inkbdat function receives its next printer status.
; when entry al == 1, return the state of the status flag and
; fresh-flag.  the logic in mosint17 will use this function with
; al == 0 to initiate a request and then call getkeys and this function
; with al == 1 until the fresh-flag indicates a fresh status report.
; since the fresh-flag will be reset when entry al == 0, a 0 will always
; be returned in al.
;
; for the non-sherwood case, where a good printer status is faked
; or is imediately available the fresh-flag will be returned as 1.  
; when mosint17 sees the fresh-flag come back as 1 when the 
; entry al == 0, it will know that there is no need to call getkeys. 
;
; in:	ah = 12h
;	al = 0 to initiate a status request
;	   = 1 to check the status and fresh-flag
;	di = # of chars in buffer
;	ds:si -> tcbddt
;	bx = 0  (caller should use this value anyway)
;
; out:	[ddah] = status as in int17fun02
;	[ddal] = the state of the fresh-flag
;	[ddbx] = 0f3c9h  (signature to verify this function is supported)
;
;,fe
;=====================================================================
print_status proc near

IFDEF SHERWOOD
	or	al,al
	jnz	pst1
	mov	[si].prs_fresh,0	; clear the completion flag
	setnorm				; initiate request.
	push	bx
	push	es
	mov	bx,cs
	mov	es,bx
	mov	bx,offset req_printer_stat
	call	movestr
	call	senddata
	pop	es
	pop	bx
pst1:
	mov	al,[si].prs_fresh
	mov	ah,[si].printer_stat
	mov	[ddbx],0f3c9h		; signature
ELSE

; in the non-sherwood case, just fake a good status.

	mov	ah,printer_ok
	mov	al,1
ENDIF

	mov	[ddax],ax
	ret
print_status endp 

	subttl setattrib - set current attribute
	page
;======================================================================
;,fs
; setattrib - set current attribute
;
; in:	ah = attribute
;
; out:	
;
;,fe
;=====================================================================
	assume	ds:nothing,es:nothing,ss:nothing
setattrib proc near
	cmp	ah,[si].attrib		; has the attribute changed
	jne	sattr0
	jmp	setax			; exit if no
sattr0:
	push	ax			; save ax
IFDEF W7TERM
	jmp	short sattr1
ENDIF
	mov	[si].attrib,ah		; store the new attribute
	setnorm				; reset monitor or print mode

IFDEF ATT
	ifroom	10			; must be room for 10 bytes
	mov	[databuf+di],escp
	inc	di
	mov	[databuf+di],'['	; store the csi
	inc	di
	mov	[databuf+di],'0'	; reset attribute
	inc	di
	test	ah,080h			; is blink set
	jz	satt1			; skip if no
	mov	[databuf+di],';'	; store the seperator
	inc	di
	mov	[databuf+di],'5'	; set blink attribute
	inc	di
satt1:
	test	ah,008h			; is high intensity set
	jz	satt2			; jump if no
	mov	[databuf+di],';'	; store the seperator
	inc	di
	mov	[databuf+di],'1'	; set bold attribute
	inc	di
satt2:
	and	ah,077h			; any foreground or background
	jnz	satt3			; press on if yes
	mov	[databuf+di],';'	; store the seperator
	inc		di
	mov	[databuf+di],'8'	; store hidden attribute
	inc	di
	jmp	short satt5		; skip next 2 if hidden
satt3:
	cmp	ah,070h			; is it reverse video
	jne	satt4			; skip if no
	mov	[databuf+di],';'	; store the seperator
	inc	di
	mov	[databuf+di],'7'	; set reverse video
	inc	di
satt4:
	and	ah,007h			; save only the foreground
	cmp	ah,001h			; is it underlined
	jne	satt5			; skip if not underlined
	mov	[databuf+di],';'	; store the seperator
	inc	di
	mov	[databuf+di],'4'	; store an underline attribute
	inc	di
satt5:
	mov	[databuf+di],'m'	; set attribute command
	inc	di
ENDIF


IFDEF VT420
	ifroom	10			; must be room for 10 bytes
	mov	[databuf+di],escp
	inc	di
	mov	[databuf+di],'['	; store the csi
	inc	di
	mov	[databuf+di],'0'	; reset attribute
	inc	di
	test	ah,080h			; is blink set
	jz	satt1			; skip if no
	mov	[databuf+di],';'	; store the seperator
	inc	di
	mov	[databuf+di],'5'	; set blink attribute
	inc	di
satt1:
	test	ah,008h			; is high intensity set
	jz	satt2			; jump if no
	mov	[databuf+di],';'	; store the seperator
	inc	di
	mov	[databuf+di],'1'	; set bold attribute
	inc	di
satt2:
	and	ah,077h			; any foreground or background
	jnz	satt3			; press on if yes
	mov	[databuf+di],';'	; store the seperator
	inc		di
	mov	[databuf+di],'8'	; store hidden attribute
	inc	di
	jmp	short satt5		; skip next 2 if hidden
satt3:
	cmp	ah,070h			; is it reverse video
	jne	satt4			; skip if no
	mov	[databuf+di],';'	; store the seperator
	inc	di
	mov	[databuf+di],'7'	; set reverse video
	inc	di
satt4:
	and	ah,007h			; save only the foreground
	cmp	ah,001h			; is it underlined
	jne	satt5			; skip if not underlined
	mov	[databuf+di],';'	; store the seperator
	inc	di
	mov	[databuf+di],'4'	; store an underline attribute
	inc	di
satt5:
	mov	[databuf+di],'m'	; set attribute command
	inc	di
ENDIF


IFDEF EMULINK
	ifroom	3			; must be room for 3 bytes
	mov	[databuf+di],escp	; store an escape
	inc	di
	mov	[databuf+di],08bh	; attribute command
	inc	di
	mov	[databuf+di],ah		; store the attribute
	inc	di
ENDIF

IFDEF PCTERM
	ifroom	3			; must be room for 3 bytes
	mov	[databuf+di],escp	; store an escape
	inc	di
	mov	[databuf+di],'G'	; attribute command
	inc	di
	mov	al,'0'			; base attribute
	test	ah,080h			; should it blink
	jz	seta2			; skip if no
	add	al,2			; add in the blink attribute
seta2:
	test	ah,008h			; should it be high intensity
	jnz	seta3			; skip if no
	add	al,'@'-'0'		; add in low intensity
seta3:
	and	ah,077h			; any foreground or background
	jnz	seta4			; jump if not hidden
	add	al,1			; add in hidden attribute
	jmp	short seta6		; skip next 2 if hidden
seta4:
	cmp	ah,070h			; is it reversed
	jne	seta5			; skip if no
	add	al,4			; add reverse attribute
seta5:
	and	ah,007h			; save the foreground
	cmp	ah,001h			; should it be underlined
	jne	seta6			; skip if no
	add	al,8			; add underline attribute
seta6:
	mov	[databuf+di],al		; store the new attribute
	inc	di
ENDIF

IFDEF SHERWOOD

; the following code is exactly the same as in the pcterm case above.

	ifroom	3			; must be room for 3 bytes
	mov	[databuf+di],escp
	inc	di
	mov	[databuf+di],'G'	; attribute command
	inc	di
	mov	al,'0'			; base attribute
	test	ah,080h			; should it blink
	jz	seta2			; skip if no
	add	al,2			; add in the blink attribute
seta2:
	test	ah,008h			; should it be high intensity
	jnz	seta3			; skip if no
	add	al,'@'-'0'		; add in low intensity
seta3:
	and	ah,077h			; any foreground or background
	jnz	seta4			; jump if not hidden
	add	al,1			; add in hidden attribute
	jmp	short seta6		; skip next 2 if hidden
seta4:
	cmp	ah,070h			; is it reversed
	jne	seta5			; skip if no
	add	al,4			; add reverse attribute
seta5:
	and	ah,007h			; save the foreground
	cmp	ah,001h			; should it be underlined
	jne	seta6			; skip if no
	add	al,8			; add underline attribute
seta6:
	mov	[databuf+di],al		; store the new attribute
	inc	di
ENDIF

IFDEF W7TERM

sattr1:
	ifroom	12
	push	bx
	push	cx
	mov	ch,[si].attrib		;get old attribute
	mov	[si].attrib,ah		; store the new attribute
	setnorm				; reset monitor or print mode
	mov	bh,ch
	and	bh,0fh			;isolate fgnd of old attri
	mov	bl,ah
	and	bl,0fh			;isolate foregnd color
	cmp	bl,bh
	je	sattr3

	mov	[databuf+di],escp	; store an escape
	inc	di
	mov	[databuf+di],' '	; attribute command
	inc	di
	mov	[databuf+di],'d'	;set foregrnd color
	inc	di

	xor	bh,bh
	mov	al,colortran[bx]
	mov	[databuf+di],al		;set new foregrnd color
	inc	di
sattr3:
	mov	bh,ch
	and	bh,070h			;isolate bkgnd of old attri
	mov	bl,ah
	and	bl,070h			;isolate bkgnd color
	cmp	bl,bh
	je	sattr5
	mov	cl,4			;shift into low nibble
	shr	bl,cl

	mov	[databuf+di],escp	; store an escape
	inc	di
	mov	[databuf+di],' '	; attribute command
	inc	di
	mov	[databuf+di],'e'	;set bkgrnd color
	inc	di

	xor	bh,bh
	mov	al,colortran[bx]
	mov	[databuf+di],al		;set new bkgrnd color
	inc	di
sattr5:
	and	ch,80h			;has blinking attribute changed
	and	ah,80h
	cmp	ch,ah
	je	sattr11			;done if it hansn't

	mov	[databuf+di],escp	; store an escape
	inc	di
	mov	[databuf+di],' '	; attribute command
	inc	di
	mov	[databuf+di],'f'     
	inc	di
	test	ah,080h			; should it blink
	jz	sattr7			; skip if no
	mov	[databuf+di],'2'	;blink attribute
	jmp	short sattr9
sattr7:
	mov	[databuf+di],'0'	;no blink attribute
sattr9:
	inc	di
sattr11:
	pop	cx
	pop	bx
ENDIF

IFDEF TRTERM

sattr1:
	ifroom	4
	mov	[databuf+di],escp	; store an escape
	inc	di
	mov	[databuf+di],'?'
	inc	di
	mov	[databuf+di],';'
	inc	di
	mov	[databuf+di],ah		;set new color
	inc	di

ENDIF


	pop	ax
setax:
	ret
setattrib endp 

	subttl setchar - prepare to send character to display
	page
;======================================================================
;,fs
; setchar - prepare to send character to display
;
; in:	al = char to send
;
; out:	
;
;,fe
;=====================================================================
	assume	ds:nothing,es:nothing,ss:nothing
setchar proc near
	test	[si].tmode,print	; are we in print mode
	jz	setch1			; jump if no
	call	notprint		; reset print mode
setch1:
	cmp	al,' '			; is it a control character
	jb	setch2			; jump if yes
	ifroom	1			; must be room for 1 byte
	mov	[databuf+di],al		; store the character
	inc	di
	ret
setch2:
IFDEF VT420
	ifroom	2			; space must send an escp
	mov	[databuf+di],escp	;  first to get it
	inc	di			;   displayed
	mov	[databuf+di],al		; store the character
	inc	di
	ret
ENDIF
	cmp	al,escp			; is it an escape
	jne	setch3			; jump if not escape
	setnorm				; make sure not in monitor mode
	ifroom	2			; must be room for 2 bytes
	mov	[databuf+di],al		; store the escape
	inc	di
	mov	[databuf+di],al		; store a second one
	inc	di			; bump the counter
	ret				; all done for escape
setch3:
	test	[si].tmode,monitor	; are we in monitor mode
	jnz	setch4			; press on if yes
	or	[si].tmode,monitor	; turn on monitor mode
	ifroom	2			; must be room for 2 bytes
	mov	[databuf+di],escp
	inc	di
	mov	[databuf+di],'U'	; set monitor mod
	inc	di
setch4:
	push	ax			; save ax
	or	al,al			; is it a null
	jnz	setch5			; jump if no
	mov	al,' '			; make the null a space
setch5:
	ifroom	1			; must be room for 1 more
	mov	[databuf+di],al		; store the character
	inc	di
	pop	ax
	ret
setchar endp 

	subttl notmonitor - make sure we're not in monitor mode
	page
;======================================================================
;,fs
; notmonitor - make sure we're not in monitor mode
;
; in:	ds:si -> tcbddt
;	di = # of chars in buffer
;
; out:	
;
;,fe
;=====================================================================
notmonitor proc near

IFNDEF VT420	;vt420 doesn't have monitor control
	test	[si].tmode,monitor	; are we in monitor mode
	jz	notprint		; check print mode if no
	and	[si].tmode,not monitor	; turn off monitor mode
	ifroom	2			; must be room for 2 bytes
	mov	[databuf+di],escp
	inc	di
	mov	[databuf+di],'u'	; turn off monitor mode
	inc	di
ENDIF

notprint:
	test	[si].tmode,print	; are we in print mode
	jz	notexit			; exit if no
	and	[si].tmode,not print	; turn off print mode
	push	bx
	push	es
	mov	bx,cs			; command segment to bx
	mov	es,bx			; set es to segment of command d
	mov	bx,offset printoff	; address of print off command
	call	movestr			; move the string to the buffer
	pop	es
	pop	bx
notexit:
	ret				; return to caller - modes reset
notmonitor endp 

	subttl movestr - move a string of bytes to the terminal buffer
	page
;======================================================================
;,fs
; movestr - move a string of bytes to the terminal buffer
;
; in:	es:bx -> string to move (1st byte is character count)
;	di = # of chars in buffer
;
; out:	
;
;,fe
;=====================================================================
	assume	ds:nothing,es:nothing,ss:nothing
movestr proc near
	push	ax
	push	cx
	xor	cx,cx			; clear the counter
	mov	cl,es:[bx]		; get the count
	inc	bx			; bump the offset
	mov	ax,cx			; count to ax
	add	ax,di			; add count in buffer
	cmp	ax,bufsiz		; do we have room
	jb	ms10			; skip the write if theres room
	call	senddata		; send data and empty the buffer
ms10:
	mov	al,es:[bx]		; get a character
	inc	bx			; bump the pointer
	mov	[databuf+di],al		; put it in the buffer
 	inc	di
	loop	ms10			; continue until all moved
	pop	cx
	pop	ax
	ret
movestr endp 

	subttl senddata - send a buffer of data to the terminal
	page
;======================================================================
;,fs
; senddata - send a buffer of data to the terminal
;
; in:	di = # of chars in buffer
;
; out:	
;
;,fe
;=====================================================================
	assume	ds:nothing,es:nothing,ss:nothing
senddata proc near
	cmp	di,0			; is there anything to send
	je	sd30			; exit if no
	mov	[si].string,0ffh	; show we have i/o in progress
	push	ax
	push	bx
	push	cx
	push	dx
	push	si
	push	es
	cmp	[si].drvf,0		; does he support string output
	je	sd50			; jump if no
	mov	ax,ss			; data segment to ax
	mov	es,ax			; set es to segment of buffer
	mov	bx,bp			; set bx to offset of data
	mov	cx,di			; set cx to count of data
	mov	dx,[si].port		; get terminals port address

IFDEF EMULINK
	test	dx,8000h		; is port ignore for emulink
	jnz	sd20
ENDIF

sd10:
	mov	si,91			; only allow 5 seconds per char
	mov	ah,14			; string output
	do14h				; send the data to serial.sys
	cmp	ax,cx			; did they all get sent
	je	sd20			; exit if yes
	add	bx,ax			; adjust the data offset
	sub	cx,ax			; and the count
	jcxz	sd20			; quit if no more to do
	jmp	short sd10		; go try to send the reset
sd20:
	xor	di,di			; data has been sent. reset pointer.
	pop	es
	pop	si
	pop	dx
	pop	cx
	pop	bx
	pop	ax
	mov	[si].string,0		; show i/o completed
sd30:
	ret

; send a buffer of data to the terminal via int14 - func 01

sd50:
	mov	cx,di			; move count to cx
	mov	di,0			; start at beginning of buffer
	mov	dx,[si].port		; get the port address

IFDEF EMULINK
	test	dx,8000h		; is port ignore for emulink
	jnz	sd90
ENDIF

sd60:
	mov	al,[databuf+di]		; get it out of the buffer
	inc	di			; bump the offset
sd70:
	mov	ah,1			; send a character
	do14h				; call int14
	cmp	ah,0			; did he send the character
	jns	sd80			; jump if ok
	jmp	short sd70		; go try it again
sd80:
	loop	sd60			; continue until all sent
sd90:
	mov	di,0			; show the buffer has been sent
	pop	es
	pop	si
	pop	dx
	pop	cx
	pop	bx
	pop	ax
	mov	[si].string,0		; show i/o completed
	ret
senddata endp 


	subttl ddtinit - mos device driver init
	page
;======================================================================
;,fs
; ddtinit - mos device driver init
;
; in:	
;
; out:	
;
;,fe
;=====================================================================

ddtinit proc near

	mov	dx,offset ddtmsg	; point to initialization message
	mov	ah,9			; print string on console
	int	21h			; let mos do it
	mov	word ptr es:[bx+14],offset ddtinit  ; store our location
	mov	es:[bx+16],cs		; in the request buffer
	mov	ax,0100h		; unknown
	ret				; return to caller
ddtinit endp


                                                                
IFDEF EMULINK

IFDEF HGTERM
ddtmsg	db	'HGTERM terminal device driver installed V5.02 (920601)'  ;@@xlat
ELSE
ddtmsg	db	'ELTERM terminal device driver installed V5.02 (920601)'  ;@@xlat
ENDIF     
	db	13,10
	db	'(c) Copyright 1987 - 1992 The Software Link, Incorporated'  ;@@xlat
	db	13,10,'$'
ENDIF

IFDEF ATT
ddtmsg	db	'ATTERM terminal device driver installed V5.02 (920601)'  ;@@xlat
	db	13,10
	db	'(c) Copyright 1987 - 1992 The Software Link, Incorporated'  ;@@xlat
	db	13,10,'$'
ENDIF

IFDEF PCTERM
ddtmsg	db	'PCTERM terminal device driver installed V5.02 (920601)'  ;@@xlat
	db	13,10
	db	'(c) Copyright 1987 - 1992 The Software Link, Incorporated'  ;@@xlat
	db	13,10,'$'
ENDIF

IFDEF SHERWOOD
ddtmsg	db	'SHERWOOD terminal device driver installed V5.02 (920601)'  ;@@xlat
	db	13,10
	db	'(c) Copyright 1987 - 1992 The Software Link, Incorporated'  ;@@xlat
	db	13,10,'$'
ENDIF

IFDEF W7TERM
ddtmsg	db	'WYSE 370 terminal device driver installed V5.02 (920601)'  ;@@xlat
	db	13,10
	db	'(c) Copyright 1987 - 1992 The Software Link, Incorporated'  ;@@xlat
	db	13,10,'$'
ENDIF

IFDEF TRTERM
ddtmsg	db	'TR 170 terminal device driver installed V5.02 (920601)'  ;@@xlat
	db	13,10
	db	'(c) Copyright 1987 - 1992 The Software Link, Incorporated'  ;@@xlat
	db	13,10,'$'
ENDIF

IFDEF VT420
ddtmsg	db	'DEC VT420 terminal device driver installed V5.02 (920601)'  ;@@xlat
	db	13,10
	db	'(c) Copyright 1987 - 1992 The Software Link, Incorporated'  ;@@xlat
	db	13,10,'$'
ENDIF

_text	ends
	end
