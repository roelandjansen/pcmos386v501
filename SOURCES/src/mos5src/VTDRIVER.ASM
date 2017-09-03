	include page.inc
	title	vtdriver.asm - VT 100 terminal driver module
comment ^--------------------------------------------------------------
		     development specification

 program name:	vtdriver.asm	assigned to:
 module name:	vtdriver	assign date:
 entry points:	mosterm 	completed:
 entry from:	mosint10, mosint16, mosvidrm
 entry method:	call dword [vector] with ah = function number
 calls: 	interrupt 14
 purpose:	mos interface to generic rs-232 terminals
 refer to:	n/a
 last update:	03/01/90

 this module is the generic mos terminal driver.
 it follows the coding standards established in the multilink
 operating system project description (section i.d. introduction -
 coding standards)

 this driver is intended to be customizable to work with any rs-232
 asynchronous terminal without color or graphics capability.

 the driver will be opened by mositask which will read a four byte
 vector to the function interpretation code

-----------------------------------------------------------------------
dam 1/2/87	made segment changes for ddts to reside in grp segment
		to provide more room in code segment.  the ddts were already
		referenced with far calls so they are the easiest to change.

jsm 02/16/87	adapted from mosddtsh

jsm 05/12/87	first release

jsm 06/25/87	fixed setcursor proc for teletype terminal

jsm 08/06/87	changed eeos so that it sends does not erase the screen
		on teletype terminals.	also changed conditional
		assembly for teletype to leave out more unneeded code.

jsm 08/11/87	fixed mtonstr and mtoffstr to be proper scan codes to
		perform the pam switch.  added esc s n sequence to
		send num lock scan codes.

jsm 10/22/87	added support for ext shift code to allow extended
		style scan codes to be returned for numeric keys.
		changed setattr to send boldon string if bold attribute
		turned on, not if it has been turned off.

jsm 12/17/87	added charmask symbol to mask incoming characters down
		to 7 bits if so desired.  changed parsing of keys
		so that illegal characters received after an esc m
		sequence would abort the pam switch.  ignore all but
		selected input characters for teletype terminal.

sah 02/21/89	masm 5.10 compatibility.

mjs 05/22/89	cleaned up for tech ref distribution.

rkg 07/17/89	added function 18 to driver for terminal keyb status

bwr 11/29/89	marked messages for foreign language translation

sah 02/13/90	corrections for 52term special cls calls for clearing
		screen faster

sah 03/01/90	corrections for carriar drop

mjs 03/20/90	modified register to call int14fun23 and to call
		int14fun11 if any error during register.  this was done
		to accomodate stargate's cluster controller.

----------------------------------------------------------------------^

	subttl	group segments and include block definitions
	page

;-----------------------------------------------------------------------
; macros for reentrant procedures
;-----------------------------------------------------------------------


;-----------------------------------------------------------------------
; the following statement causes the assembler and linker to respect
; our desire that the data in the ddt and gdata segments be
; addressable in the grp group
;-----------------------------------------------------------------------
grp	group	gdata,ddt,compat

;-----------------------------------------------------------------------
; the following include files are definitions of the respective blocks
; the definitions do not reserve any storage by virtue of the
; segment at x construction
;-----------------------------------------------------------------------
tcb	segment at 1234h

ddtrec	struc
	dd	?
logscr	dd	?
crsofs	dw	?
cols	db	?
port	dw	?
baud	dd	?
attrib	db	?
cursor	dw	?
tstate	dw	?
kbresum dw	?			; keyboard interpreter resume address
kbsav	db	?			; intermediate for function key decoding
kbmsk	db	?			; keyboard scan code mask
kbcode	dw	?			; pointer to scan code to send
kbshft	db	?			; index of current scan table entry
tmpatr	db	?			; temporary attribute for scrolling
					; (trashed by keyboard decoding, so don't
					;  depend on this guy to hold a value)
string	db	5 dup (0)
kblst	db	0			; last character from terminal
ddtrec	ends
tcb	ends

.xlist
	include macros.inc
.list

;-----------------------------------------------------------------------
;	generally used constants.
;-----------------------------------------------------------------------

; bits in the tstate word.

movmod	equ	00001h			; move between partitions
cmdmod	equ	00002h			; treat control characters as commands
normal	equ	00004h			; output in normal mode
print	equ	00008h			; output to go to printer
nextcall equ	00010h			; call a routine in table match code
bottom	equ	00020h			; set if seeing bottom of screen
offscrn equ	00040h			; set if cursor off screen
dstread equ	00080h			; do destructive key read
sendkey equ	00100h			; sending a key sequence
sendext equ	00200h			; send an extended prefix

; bits in the kbmsk field.

lsh	equ	01h			; left shift emulate flag
rsh	equ	02h			; right shift emulate flag
ctl	equ	04h			; control key emulate flag
alt	equ	08h			; alt key emulate flag
cap	equ	10h			; caps lock emulate flag
nrm	equ	20h			; no shift flags
ext	equ	40h			; send extended prefix code

extpsc	equ	0e0h			; extended prefix scan code

	subttl compatibility section -- different for each terminal
	page

gdata	segment para public 'code'	; to force loading with code

; this segment must be loaded before compatibility segment.

gdata	ends

compat	segment word public 'code'

; structures & equates for mos command match tables.

; capability descriptor.

bincur	equ	1			; set if binary cursor position
					; cleared if ascii numeral cursor position
colrow	equ	2			; set if cursor string in column, row format
lindel	equ	4			; set if terminal can insert/delete lines
sclrgn	equ	8			; set if terminal requires a scrolling
					; to be set before insert/delete
btmwrp	equ	10h			; if terminal wraps when writing to bottom
					; right corner
speccls equ	20h		; use for special cls using eos

; comm protocols to use.

pr_none equ	0			; no protocol
pr_rxon equ	1			; enable receive xon/xoff
pr_txon equ	2			; enable transmit xon/xoff
pr_dtsr equ	4			; enable dtr/dsr protocol
pr_rcts equ	8			; enable rts/cts protocol

term	equ	0			; terminating state
ntab	equ	1			; get new table address
callr	equ	2			; call a routine next time
caln	equ	3			; call next time

keymtch struc
mtch	db	?			; character to match
state	db	?			; next state
nxttab	dw	?			; next table to search or keystroke to send
keymtch ends

include vtdef.inc

compat	ends

; end of compatibility section.

	subttl	data segment - local data for the driver
	page

gdata	segment

; device header.

	public	moxddtgn, gnterm
	org	0

moxddtgn equ	this byte
	dd	-1			; filled in with pointer to next driver
	dw	8000h			; signifying a character device
	dw	grp:strat		; device strategy entry point
	dw	grp:inter		; device interrupt entry point
tname	label	byte
	defname 			; device name (different for each driver)
					; this macro should be defined in termdef.inc
	db	'$'			; trick to let us display name using fn 9

int14h	dd	0

do14h	macro
	int	14h			;; have to do a real software interrupt
	endm

	even

request dd	0

shscantbl label byte			; translation of shift key codes
db	56				; alt key
db	29				; control key
db	42				; scan code for left shift key
db	54				; right shift key
db	58				; caps lock key
db	42				; end of table, default value

topcode 	db	0ffh,	0	; scan code for top of screen
botcode 	db	0feh,	0	; scan code for bottom of screen
ctlbrkcode	db	70,	ctl	; ctl-break scan code
btcode		db	15,	lsh	; back tab

; numeric keypad keys (numeric order).

keyntable label byte
		db	82,	nrm	; number pad 0 (ins)
		db	79,	nrm	; number pad 1 (end)
		db	80,	nrm	; number pad 2 (down arrow)
		db	81,	nrm	; number pad 3 (pg dn)
		db	75,	nrm	; number pad 4 (left arrow)
		db	76,	nrm	; number pad 5 (dead)
		db	77,	nrm	; number pad 6 (right arrow)
		db	71,	nrm	; number pad 7 (home)
		db	72,	nrm	; number pad 8 (up arrow)
		db	73,	nrm	; number pad 9 (pg up)

; special function keys (no particular order).

inscode 	db	82,	ext	; number pad 0 (ins)
endcode 	db	79,	ext	; number pad 1 (end)
crdncode	db	80,	ext	; number pad 2 (down arrow)
pgdncode	db	81,	ext	; number pad 3 (pg dn)
crlfcode	db	75,	ext	; number pad 4 (left arrow)
crrtcode	db	77,	ext	; number pad 6 (right arrow)
homecode	db	71,	ext	; number pad 7 (home)
crupcode	db	72,	ext	; number pad 8 (up arrow)
pgupcode	db	73,	ext	; number pad 9 (pg up)

nlcode		db	69,	nrm	; num lock
delcode 	db	83,	ext	; number pad . (del)
pscode		db	55,	lsh	; shift prtsc
ctlhmcode	db	71,	ctl or ext  ; ctl-home key
ctlendcode	db	79,	ctl or ext  ; ctl-end key
ctlpgupcode	db	73,	ctl or ext  ; ctl-pg up key
ctlpgdncode	db	81,	ctl or ext  ; ctl-pg dn key

; scan codes for function keys f1 - f40

fntable db	68, nrm					 ; f10
	db	59, nrm,	60, nrm,	61, nrm  ; f1, f2, f3
	db	62, nrm,	63, nrm,	64, nrm  ; f4, f5, f6
	db	65, nrm,	66, nrm,	67, nrm  ; f7, f8, f9

fntab1	db	59, nrm,	60, nrm,	61, nrm  ; f1, f2, f3
	db	62, nrm,	63, nrm,	64, nrm  ; f4, f5, f6
	db	65, nrm,	66, nrm,	67, nrm  ; f7, f8, f9
	db	68, nrm					 ; f10

fntab2	db	59, lsh,	60, lsh,	61, lsh  ; shift f1, etc.
	db	62, lsh,	63, lsh,	64, lsh
	db	65, lsh,	66, lsh,	67, lsh
	db	68, lsh
	db	59, ctl,	60, ctl,	61, ctl  ; ctl f1, etc.
	db	62, ctl,	63, ctl,	64, ctl
	db	65, ctl,	66, ctl,	67, ctl
	db	68, ctl
	db	59, alt,	60, alt,	61, alt  ; alt f1, etc.
	db	62, alt,	63, alt,	64, alt
	db	65, alt,	66, alt,	67, alt
	db	68, alt

alttable label byte
	db	012,alt,	000,000,	000,000  ; -, nul, nul
	db	011,alt,	002,alt,	003,alt  ; 0, 1, 2
	db	004,alt,	005,alt,	006,alt  ; 3, 4, 5
	db	007,alt,	008,alt,	009,alt  ; 6, 7, 8
	db	010,alt,	000,000,	000,000  ; 9
	db	000,000,	013,alt,	000,000  ; =
	db	000,000,	000,000,	030,alt  ; a
	db	048,alt,	046,alt,	032,alt  ; b, c, d
	db	018,alt,	033,alt,	034,alt  ; e, f, g
	db	035,alt,	023,alt,	036,alt  ; h, i, j
	db	037,alt,	038,alt,	050,alt  ; k, l, m
	db	049,alt,	024,alt,	025,alt  ; n, o, p
	db	016,alt,	019,alt,	031,alt  ; q, r, s
	db	020,alt,	022,alt,	047,alt  ; t, u, v
	db	017,alt,	045,alt,	021,alt  ; w, x, y
	db	044,alt 		; z

; scan code strings to move into or out of move mode, and to abort it.

mtonstr db	038h, 0 		; alt key down
mtoffstr db	0b8h, 0 		; alt key up
mtabstr db	048h, 0c8h, 048h, 0c8h, 048h, 0c8h, 0
						  ; keypad 8, 8, 8

fn	dw	grp:ddtinit		; 0 - init
	dw	grp:ddtnull		; 1 - media check
	dw	grp:ddtnull		; 2 - build bpb
	dw	grp:ddtnull		; 3 - ioctl input
	dw	grp:ddtread		; 4 - read
maxfn	equ	($-fn)/2

tfn	dw	grp:register
	dw	grp:inkbdata
	dw	grp:outkbctl
	dw	grp:setmode
	dw	grp:setcrstyp
	dw	grp:setcursor
	dw	grp:scrollup
	dw	grp:scrolldn
	dw	grp:wrchatr
	dw	grp:setpalet
	dw	grp:wrtty
	dw	grp:wrstr
	dw	grp:setwindow
	dw	grp:wrcho
	dw	grp:readch
	dw	grp:getscr
	dw	grp:prch
	dw	grp:prstr
endtfn	equ	($-tfn)/2

gdata	ends

	subttl	code segment - all routines for driver
	page

ddt	segment para public 'code'
	assume	cs:grp,ds:nothing,es:nothing,ss:nothing

strat	proc	far
	mov	word ptr [request],bx
	mov	word ptr [request+2],es
	ret
strat	endp

inter	proc	far
	push	es
	push	ds
	push	si
	push	bx
	push	ax
	mov	bx,cs
	mov	ds,bx
	assume	ds:grp
	mov	ax,0100h
	les	bx,[request]
	mov	si,es:[bx+2]
	and	si,0ffh
	cmp	si,maxfn
	jae	inter1
	shl	si,1
	call	fn[si]
inter1:
	assume	ds:nothing
	les	bx,[request]
	mov	es:[bx+3],ax		; store result status
	pop	ax
	pop	bx
	pop	si
	pop	ds
	pop	es
	ret
inter	endp

; null device driver call does nothing

ddtnull proc	near
	mov	ax,0100h		; return no error, done
	ret
ddtnull endp

	subttl	ddtread - return the terminal function vector
	page

; read just returns the terminal function vector

ddtread proc	near
	lds	si,es:[bx+14]
	mov	cx,es:[bx+18]
	mov	word ptr es:[bx+18],0	; nothing read if error
	mov	ax,8103h		; error, done, unknown command
	cmp	cx,4
	jne	ddtrd1			; if not reading exactly 4 bytes
	mov	es:[bx+18],cx		; else read 4 bytes
	mov	word ptr ds:[si],offset grp:gnterm  ; and these are them
	mov	ds:[si+2],cs
	mov	ax,0100h		; no error, done
ddtrd1:
	ret
ddtread endp

	subttl	termfn - all the terminal and keyboard functions for mos
	page

	assume	ds:tcb,es:nothing,ss:nothing
gnterm	proc	far
	push	ds
	push	bp
	cmp	ah,endtfn
	jae	termfn1
	mov	bp,bx
	mov	bl,ah
	xor	bh,bh
	shl	bx,1
	xchg	bx,bp
	call	tfn[bp]
termfn1:
	pop	bp
	pop	ds
	ret
gnterm	endp

; error codes

if	0 eq 0				; no publics for ps
badprt	equ	1			; bad port number
badbau	equ	2			; bad baud rate
endif

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
;     es:bx -> key buffer flag
;	key buffer flag is <> 0 while scan codes are buffered
;     al = 80h if master console
;	   00h if not master console
;     ah = 0 if no error
;	 = 1 if bad port number
;	 = 2 if bad baud rate
;-----------------------------------------------------------------------
	assume	ds:tcb,es:nothing,ss:nothing
register proc
	cmp	word ptr [int14h+2],0
	jne	reg1
	push	ds
	xor	ax,ax
	mov	ds,ax
	lds	ax,dword ptr ds:[14h*4]
	mov	word ptr [int14h],ax
	mov	word ptr [int14h+2],ds
	pop	ds
reg1:
	mov	[si].cursor,-1
	mov	[si].tstate,0
	mov	[si].attrib,-1
	mov	[si].kbresum,offset grp:serinput
	mov	dx,[si].port
	mov	ah,13			; 13 - register the port with supercom
	do14h
	or	ah,ah			; ah=ff if invalid port number
	jz	reg2
	mov	ah,badprt		; bad port error
	jmp	reg5
reg2:
	push	es
	push	bx

; this is done for the sake of stargate's cluster controller.
; it must be done right after the function 13 call.
; after this call, if any errors within this ddt register function, must
; call int14 function 11 to disable the port.  this is required so that
; the cluster controller driver can know it should deallocate its resources.

	mov	bx,ds
	mov	dx, [si].port		; get the port address
	mov	ah,23
	do14h				; register ownership

	mov	dx,[si].port
	mov	bx,word ptr [si].baud
	mov	cx,word ptr [si].baud+2
	mov	ax,0403h		; extended port init, al=8 data, 1 stop,
	do14h				;   no parity
	or	ah,ah			; =ff if invalid baud rate
	jz	reg3
	mov	ah,badbau		; invalid baud rate error
	jmp	reg5x
reg3:
	mov	ax,0500h or protocol	; set required terminal protocol
	mov	bx,xoff * 256 or xon	; use required xon/xoff characters
	mov	dx,[si].port
	do14h				; no errors returned from this one
	xor	ah,ah			; no errors
reg4:
	pop	bx
	pop	es
	jmp	short reg5
reg5x:
	mov	ah,11			; if any error after register
	mov	dx,[si].port		; ownership, disable the port
	do14h
reg5:
	xor	al,al			; not a master console
	ret
register endp

	subttl	inkbdata - input keyboard scan code
	page
;-----------------------------------------------------------------------
; inkbdata - input keyboard scan code
;
;   ah = 01h
;     ds:si -> tcbddt
;
;   returns:
;     al = bit	7   - key break if 1, key make or key repeat if 0
;	   bits 6-0 - key scan code 01h - 07dh
;     carry if terminal drop dtr
;     key scan code is read non-destructively
;-----------------------------------------------------------------------
	assume	ds:tcb,es:nothing,ss:nothing
inkbdata proc
	test	[si].tstate,sendkey	; sending a key?
	jnz	ink20			; if we have keystrokes to send
	mov	dx,[si].port
	mov	ah,08h			; peek for a character
	do14h
	jnz	ink10			; nz if a char is ready
	jc	ink30			; exit if carriar drop
	xor	al,al			; else signal mos that there is no key
	jmp	ink30			; exit from routine
ink10:
	and	al,charmask		;jsm 12/17/87 only look at some bits
	mov	[si].kblst,al		; last real character read
ink20:
	and	[si].tstate,not dstread ; peek at the next key
	call	readkey 		; make char into scan code
ink30:
	ret
inkbdata endp

;-----------------------------------------------------------------------
; readkey - read ascii characters & interpret as scan codes
;
;   al contains last character read from serial port
;   [si].tstate & dstread = destructive read flag
;	if dstread bit clear, non-destructive read
;	if dstread bit set, destructive read
;   ds:si -> tcbddt
;
;   returns:
;     if z set, no scan code
;     if z clear, bl has scan code
;
;   changes: ax, bx, cx, dx
;   calls: nothing global
;   uses: keycodes, kbmsk, tstate, kbc, kbptr
;-----------------------------------------------------------------------
	assume	ds:tcb,es:nothing,ss:nothing
readkey proc
	jmp	[si].kbresum		; start up interpreter
serinnah:
	test	[si].tstate,movmod	; partition move mode?
	jz	serinna0		; if not in move mode
	sub	al,'0'			; convert digit to binary
	jb	sermmnod		; if not a digit
	cmp	al,9
	ja	sermmnod		; if not a digit
	cbw
	add	ax,ax
	add	ax,offset grp:keyntable ; offset into numeric keypad table
	mov	bx,ax
	jmp	short serinntr		; send the corresponding keypad code
sermmnod:
	mov	[si].kbcode,offset grp:mtabstr	; abort the pam sequence
	jmp	sersndst
serinna0:

ifdef	teletype
	cmp	al,inctllen		; is it in control char table?
	jae	serinna1		; if it isn't in the table
	mov	bx,offset grp:inctl
	xlat	inctl			; can we pass this one?
	or	al,al
	jz	serinres		; no, eat it
serinna1:
endif

	xor	ah,ah
	add	ax,ax			; get word pointer into scan table
	add	ax,offset grp:keycodes	; make scan code pointer
	mov	bx,ax			; get table offset in bx
serinntr:
	mov	[si].kbcode,bx		; store for next time
	mov	[si].kbshft,0		; offset in scan code table
	mov	[si].kbmsk,alt		; first scan code
	or	[si].tstate,sendkey	; sending a key
	test	byte ptr cs:[bx+1],ext	; send ext prefix code?
	jz	seringenmk		; no, just generate makes
	or	[si].tstate,sendext	; send ext code before scan
	jmp	short seringenmk	; generate a make code

serinres:
	and	[si].tstate,not sendext ; finished with extended codes
	mov	ah,02
	do14h				; clear the last character
	mov	ax,offset grp:serinput	; reset from esc sequence
serinret:
	mov	[si].kbresum,ax
	xor	ax,ax			; no character available
	ret				; done for this character
serineat:
	mov	[si].kbresum,ax 	; new state
	mov	ah,2
	do14h				; eat current character
	xor	ax,ax			; say no char this time
	ret

; keycode generator.

seringenmk:
	mov	bx,[si].kbcode
	mov	ah,[si].kbmsk
shtst:
	or	ah,ah
	jz	sendscan		; send the key stroke
	mov	di,word ptr [si].kbshft ; shift table index
	and	di,0ffh 		; the index is only one byte
	mov	al,cs:[bx+1]		; shift code mask
shtst10:
	test	al,ah			; send this shift code?
	jnz	sendsh
	inc	di			; next code
	shr	ah,1
	jnz	shtst10 		; if more shift codes
sendscan:
	test	[si].tstate,sendext
	jz	send01			; if don't send EXT prefix
	mov	al,extpsc		; send this baby
	test	[si].tstate,dstread
	jz	send03			; if not destructive
	and	[si].tstate,not sendext ; don't send extended prefix again
	jmp	short send03
send01:
	mov	al,cs:[bx]		; real scan code
	test	[si].tstate,dstread
	jnz	send05			; if destructive read
send03:
	mov	[si].kbresum,offset grp:seringenmk  ; come back here
	jmp	short send10
send05:
	mov	[si].kbresum,offset grp:seringenbk  ; do break codes next time
send10:
	or	si,si			; clear zero flag
	ret
sendsh:
	mov	[si].kbresum,offset grp:seringenmk  ; send more make codes
	mov	al,cs:shscantbl[di]	; get shift scan code
	test	[si].tstate,dstread
	jz	sendsh10
	shr	ah,1			; next shift code
	inc	di
	mov	[si].kbmsk,ah
	mov	word ptr [si].kbshft,di ; next shift thing in table
					; note that this trashes tmpatr,
					; but we don't care about its contents
sendsh10:
	or	si,si			; clear zero flag
	ret

seringenbk:
	test	[si].tstate,sendext	; have we sent the ext code?
	jnz	sendbk5 		; yes, already sent it
	test	byte ptr cs:[bx+1],ext	; send ext prefix code?
	jz	sendbk5 		; if no ext prefix
	mov	al,extpsc		; scan code to send
	test	[si].tstate,dstread	; advance state?
	jz	bkex
	or	[si].tstate,sendext	; we sent the ext
	jmp	short bkex
sendbk5:
	mov	bx,[si].kbcode
	mov	al,cs:[bx]		; scan code for key again & shift mask
	or	[si].tstate,sendext	; we won't send the EXT now
	or	al,80h			; set break bit this time
sendbk20:
	test	[si].tstate,dstread
	jz	bkex			; if no state change
	mov	[si].kbresum,offset grp:serbksh  ; do shift breaks next time
	mov	[si].kbmsk,alt		; reset shift scan mask
	mov	[si].kbshft,0		; and shift index
	and	[si].tstate,not sendkey
bkex:
	or	si,si			; clear zero flag
	ret

serbksh:
	mov	bx,[si].kbcode
	mov	ah,[si].kbmsk
	mov	al,cs:[bx+1]		; shift code mask
	mov	di,word ptr [si].kbshft ; index into shift code table
	and	di,0ffh 		; index is only a byte
bksh10:
	test	al,ah			; send this shift code?
	jnz	sendbksh
	inc	di			; next code in table
	shr	ah,1
	jnz	bksh10			; if more shift codes
	jmp	serinres		; reset interpreter
sendbksh:
	mov	al,cs:shscantbl[di]	; scan code to send
	test	[si].tstate,dstread
	jz	sendbk10
	shr	ah,1			; advance to next shift code
	inc	di
	mov	[si].kbmsk,ah
	mov	word ptr [si].kbshft,di ; again, this trashes tmpatr
					; but that's OK
sendbk10:
	or	al,80h			; set break bit
	or	si,si			; clear zero flag
	ret

serinput label near
	cmp	al,20h			; check if control code
	jmpa	serinnah		; no, skip
	cmp	al,[crttctlp]		; check if command prefix
	je	serinsk4		; yes, go handle it


	jmp	serinnah	;#### let control chars thru


	test	[si].tstate,cmdmod	; treat control chars as normal?
	jmpnz	serinnah		; if no special processing
	cmp	[crttcurp],0		; check if cursor has prefix
	je	serinsk1		; no, jump
	cmp	al,[crttcurp]		; check if this is it
	jmpne	serinnah		; no, take it as is
	mov	ax,offset grp:serinsk1
	jmp	serineat		; yes, get its companion
serinsk1:
	mov	bx,offset grp:crupcode
	cmp	al,[crttcuru]
	je	serinsk2
	mov	bx,offset grp:crdncode
	cmp	al,[crttcurd]
	je	serinsk2
	mov	bx,offset grp:crlfcode
	cmp	al,[crttcurl]
	je	serinsk2
	mov	bx,offset grp:crrtcode
	cmp	al,[crttcurr]
	je	serinsk2
	mov	bx,offset grp:ctlhmcode
	cmp	al,[crtthome]
	je	serinsk2
serinsk8:
	jmp	serinnah
serinsk2:
	jmp	serinntr

serinsk4 label near			; handle esc sequences
	mov	ax,offset grp:serinbk2	; get 2nd byte
	jmp	serineat
serinbk2:
	call	upercase		; convert to upper case
	cmp	al,[crttctlp]		; esc esc = they really want esc
	je	serinsk8
	cmp	al,'C'			; esc c = go to control mode
	je	serinec
	cmp	al,'N'			; esc n = go to normal mode
	je	serinen
	cmp	al,'T'			; esc t = window to top
	je	serinet
	cmp	al,'B'			; esc b = window to bottom
	je	serineb
	cmp	al,'K'			; esc k = ctrl-break
	jmpe	serinek
	cmp	al,'M'			; esc m = toggle move mode
	je	serinem
	cmp	al,'A'			; esc a = alt keys
	jmpe	serinea
	cmp	al,09h			;? esc tab = shift back tab
	jne	$+5			;?
	jmp	serinbt 		;?
	cmp	al,'S'			; esc s = special codes
	jne	$+5
	jmp	serines
	cmp	al,'Z'			; esc z = special ctrl codes
	jne	$+5
	jmp	serinez
	cmp	al,'F'			; esc f = f11-f40
	jne	$+5
	jmp	serinef

;####
	cmp	al,'O'
	jne	$+5
	jmp	serinfun
	cmp	al,'['
	jne	$+5
	jmp	serincur
;####

	cmp	al,'9'			; esc digit = function key
	ja	serinbuz		; anything else is invalid
	cmp	al,'0'
	jb	serinbuz
serinsk5:
	sub	al,'0'
	xor	ah,ah			; convert digit to
	add	ax,ax			;	function key scan code
	mov	bx,offset grp:fntable
	add	bx,ax
	jmp	serinntr
serinet:
	mov	[si].kbcode,offset grp:topcode	; set window to top 24 lines
	jmp	sersndst
serineb:
	mov	[si].kbcode,offset grp:botcode	; bottom 24 lines
	jmp	sersndst
serinec:
	or	[si].tstate,cmdmod	; set control mode
	jmp	serinres		; we still need a character
serinen:
	and	[si].tstate,not cmdmod	; set normal mode
	jmp	serinres
serinem:
	mov	ax,[si].tstate
	xor	ax,movmod		; toggle move mode
	test	ax,movmod		; toggle on or off?
	mov	[si].tstate,ax
	jz	sertoff 		; if off
	mov	[si].kbcode,offset grp:mtonstr	; send this key string
	jmp	sersndst
sertoff:
	mov	[si].kbcode,offset grp:mtoffstr  ; send toggle off string

; send a string of scan codes.

sersndst:
	mov	bx,[si].kbcode
	mov	al,cs:[bx]		; next scan code
	or	al,al			; last code?
	jz	serinbuz		; if the end
	mov	[si].kbresum,offset grp:sersndst  ; send scan code string again
	inc	bx
	test	[si].tstate,dstread	; advance to next one?
	jz	sersndnxt
	mov	[si].kbcode,bx
sersndnxt:
	or	al,al			; clear z flag
	ret

serinbuz:
	jmp	serinres
serinea:
	mov	ax,offset grp:serinbk3	; get 3rd byte
	jmp	serineat
serinek:
	mov	bx,offset grp:ctlbrkcode; start sending ctl break codes
	jmp	serinntr
serinbk3:
	call	upercase		; convert to upper case
	cmp	al,2dh			; check range
	jb	serinbuz
	cmp	al,5ah
	ja	serinbuz
	xor	bh,bh			; compute alttable index
	mov	bl,al
	sub	bl,2dh
	add	bx,bx			; now it's a word index
	add	bx,offset grp:alttable
	cmp	word ptr cs:[bx],0	; check if ok character
	je	serinbuz
	jmp	serinntr
serinbt:
	mov	bx,offset grp:btcode	;? scan code for back-tab
	jmp	serinntr		;?
serines:
	mov	ax,offset grp:serinbk4	; get 3rd byte
	jmp	serineat
serinbk4:
	call	upercase
	mov	bx,offset grp:homecode
	cmp	al,'H'			; home
	je	serinsk6
	mov	bx,offset grp:endcode
	cmp	al,'E'			; end
	je	serinsk6
	mov	bx,offset grp:pgupcode
	cmp	al,'U'			; pg up
	je	serinsk6
	mov	bx,offset grp:pgdncode
	cmp	al,'D'			; pg dn
	je	serinsk6
	mov	bx,offset grp:inscode
	cmp	al,'I'			; ins
	je	serinsk6
	mov	bx,offset grp:delcode
	cmp	al,'X'			; del
	je	serinsk6
	mov	bx,offset grp:nlcode
	cmp	al,'N'			; num lock
	je	serinsk6
	mov	bx,offset grp:pscode
	cmp	al,'P'			; print screen
	jne	serinsk7
serinsk6:
	jmp	serinntr
serinez:
	mov	ax,offset grp:serinbk5	; get 3rd byte
	jmp	serineat
serinbk5:
	call	upercase
	mov	bx,offset grp:ctlhmcode
	cmp	al,'H'			; ctrl-home
	je	serinsk6
	mov	bx,offset grp:ctlendcode
	cmp	al,'E'			; ctrl-end
	je	serinsk6
	mov	bx,offset grp:ctlpgupcode
	cmp	al,'U'			; ctrl-pgup
	je	serinsk6
	mov	bx,offset grp:ctlpgdncode
	cmp	al,'D'			; ctrl-pgdn
	je	serinsk6
	jmp	serinbuz
serinef:
	mov	ax,offset grp:serinbk6	; get 3rd byte
	jmp	serineat
serinbk6:
	sub	al,30h
	jng	serinsk7		; exit if not a digit
	cmp	al,4
	jg	serinsk7
	xor	ah,ah			;d
	shl	ax,1			;d 2x			(2 clks)
	mov	bx,ax			;d temp save for the 2x (2 clks)
	shl	ax,1			;d 4x			(2 clks)
	shl	ax,1			;d 8x			(2 clks)
	add	ax,bx			;d 8x + 2x = 10x	(3 clks)
	mov	[si].kbsav,al		; save it
	mov	ax,offset grp:serinbk7	; get 4th byte
	jmp	serineat
serinbk7:
	sub	al,30h
	jl	serinsk7
	cmp	al,9
	ja	serinsk7
	add	al,[si].kbsav		; compute value in binary
	cmp	al,11			; validate range
	jb	serinsk7
	cmp	al,40
	ja	serinsk7
	sub	al,11			; get offset in second table
	xor	ah,ah
	add	ax,ax			; double for word offset
	mov	bx,ax
	add	bx,offset grp:fntab2	; is now function key table index
	jmp	serinsk6
serinsk7:
	jmp	serinbuz


;####
serinfun:
	mov	ax,offset grp:serinbk8
	jmp	serineat
serinbk8:				;3rd byte of kbrd fun keys
	cmp	al,'P'
	jb	serinsk7
	cmp	al,'Y'
	ja	serinsk7
	sub	al,'P'
	xor	ah,ah			; convert digit to
	add	ax,ax			;	function key scan code
	mov	bx,offset grp:fntab1
	add	bx,ax
	jmp	serinntr

serincur:
	mov	ax,offset grp:serinbk9
	jmp	serineat
serinbk9:				;3rd byte of num keys in cursor mode
	mov	bx,offset grp:homecode
	cmp	al,'H'			; home
	je	serinsk9
	mov	bx,offset grp:endcode
	cmp	al,'Q'			; end
	je	serinsk9
	mov	bx,offset grp:pgupcode
	cmp	al,'S'			; pg up
	je	serinsk9
	mov	bx,offset grp:pgdncode
	cmp	al,'T'			; pg dn
	je	serinsk9
	mov	bx,offset grp:inscode
	cmp	al,'@'			; ins
	je	serinsk9
	mov	bx,offset grp:crdncode
	cmp	al,'B' 			;down arrow
	je	serinsk9
	mov	bx,offset grp:crrtcode
	cmp	al,'C' 			;right arrow
	je	serinsk9
	mov	bx,offset grp:crlfcode
	cmp	al,'D' 			;left arrow
	je	serinsk9
	mov	bx,offset grp:crupcode
	cmp	al,'A' 			;up arrow
	jne	serinsk7
serinsk9:
	jmp	serinntr	



upercase proc	near
	cmp	al,60h			; check if lower case
	jng	upercasx
	cmp	al,7ah
	ja	upercasx
	sub	al,20h
upercasx:
	ret
upercase endp

readkey endp

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
	assume	ds:tcb,es:nothing,ss:nothing
outkbctl proc
	test	al,80h
	jz	kbctl1
	or	[si].tstate,dstread
	mov	al,[si].kblst		; last character read
	call	readkey 		; wait for chars from port
kbctl1:
	ret
outkbctl endp

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
;-----------------------------------------------------------------------
	assume	ds:tcb,es:nothing,ss:nothing

; just remember the number of cols/line the application expects
;     and clear the screen

setmode proc
	and	[si].tstate,not (offscrn or bottom)
	xor	dx,dx
	call	setcursor
	mov	ah,07h
	call	setattrib
	call	eeos
	mov	di,cs
	mov	es,di
	lea	di,[linecursor]
	call	writesnc
	ret
setmode endp

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
;-----------------------------------------------------------------------
	assume	ds:tcb,es:nothing,ss:nothing
setcrstyp proc
	call	notmonitor
	mov	di,cs
	mov	es,di
	sub	cl,ch
	jc	setct1			; start > end turns cursor off
	cmp	cl,3
	jae	setct2			; cursor size >= 4 scan lines sets box

; line cursor

	lea	di,[linecursor]
	call	writesnc
	ret

; hide the cursor

setct1:
	lea	di,[nocursor]
	call	writesnc
	ret

; box cursor

setct2:
	lea	di,[boxcursor]
	call	writesnc
	ret
setcrstyp endp

	subttl	setcrspos - set physical cursor position
	page
;-----------------------------------------------------------------------
; setcursor - set physical cursor position
;
; ah = 05h - set physical cursor position
;   dh = row
;   dl = col
;   ds:si -> tcbddt
;   [tcbddt] = dword -> screen buffer @ page/row/col
;-----------------------------------------------------------------------
	assume	ds:tcb,es:nothing,ss:nothing

storchar macro	source
	mov	[di],source
	inc	di
	inc	ah
	endm

setcursor proc
	cmp	dx,[si].cursor
	jne	setcp10 		; if cursor has changed
	jmp	setcpx
setcp10:

ifdef	teletype
	push	dx
	push	cx
	xchg	[si].cursor,dx		; set new position
	sub	dl,byte ptr [si].cursor ; get # of columns to move
	jl	setcp30 		; if old pos < new pos, do nothing
	xor	ch,ch
	mov	cl,dl			; number of backspaces to write
	jcxz	setcp30 		; if none to write

; new pos < old pos, write backspaces.

	mov	[si].string,1		; write them one at a time
	mov	[si].string+1,08h	; write backspaces
	push	ds
	pop	es
	lea	di,[si].string		; pointer to string to send
setcp20:
	push	es
	push	di
	push	cx
	call	writesnc
	pop	cx
	pop	di
	pop	es
	loop	setcp20
setcp30:
	pop	cx
	pop	dx
else
	mov	[si].cursor,dx		; new cursor position
	cmp	[maxrow],24		; 25 line terminal?
	jae	setcp70 		; if 25 line terminal, skip check

; test for on/off screen cursor.

	test	[si].tstate,bottom
	jnz	setcp40 		; if bottom of screen shows
	cmp	dh,[maxrow]
	jbe	setcp30 		; if not on bottom row
setcp20:
	mov	dh,[maxrow]		; position cursor on max line
setcp25:
	or	[si].tstate,offscrn	; set offscreen flag
	jmp	short setcp60
setcp30:
	and	[si].tstate,not offscrn ; clear offscreen flag
	jmp	short setcp60
setcp40:
	sub	dh,[extrar]		; make up for screen offset
	jge	setcp30 		; if on screen
	xor	dh,dh			; go to row 0 (physical)
	jmp	setcp25 		; set off screen flag
setcp60:

; sent cursor position string to terminal.

setcp70:
	call	notmonitor
	test	[capable],colrow	; which comes first?
	jz	setcp80 		; if row comes first
	xchg	dh,dl			; swap to write column byte first
setcp80:
	push	dx
	mov	di,cs
	mov	es,di
	lea	di,[crintro]
	call	writesnc		; write out cursor intro string
	pop	dx
	lea	di,[si].string+1	; pointer to next byte in string
	mov	ah,0			; set string length to zero
	test	[capable],bincur	; binary cursor string?
	jz	setcp100		; if ascii cursor string

; binary format cursor string.

	add	dh,[croffs]		; convert to terminal's format
	storchar dh
	mov	al,[crsep]
	or	al,al
	jz	setcp90 		; if no separator
	storchar al			; store separator
setcp90:
	add	dl,[croffs]
	storchar dl			; store second byte of string
	jmp	short setcp200		; exit routine

; ascii cursor position.

setcp100:
	add	dh,[croffs]		; convert to terminal's format
	mov	al,dh
	call	cnvchar 		; convert the number to ascii
	mov	al,[crsep]
	or	al,al
	jz	setcp110		; if no separator
	storchar al			; store separator
setcp110:
	mov	[si].string,ah
	mov	di,ds
	mov	es,di
	lea	di,[si].string		; send off first part of string
	push	dx
	call	writesnc
	pop	dx
	lea	di,[si].string+1	; pointer to next byte in string
	mov	ah,0			; set string length to zero
	add	dl,[croffs]
	mov	al,dl			; convert number to ascii
	call	cnvchar
setcp200:
	mov	[si].string,ah		; store length
	mov	di,ds			; write rest of the cursor string
	mov	es,di
	lea	di,[si].string
	call	writesnc
	mov	di,cs
	mov	es,di
	lea	di,[crterm]
	call	writesnc		; write cursor terminator
endif

setcpx:
	ret
setcursor endp

;-----------------------------------------------------------------------
; cnvchar
;
; convert byte in al to decimal ascii.	put result at bytes pointed to
; by ds:di. the byte is assumed to be in the range 99-0, so as to
; produce only two characters.
;
; changes: ah, di
;-----------------------------------------------------------------------
cnvchar proc
	push	bx
	push	ax
	xor	ah,ah
	mov	bl,10			; divide position by 10
	div	bl
	mov	bx,ax			; keep cursor position
	pop	ax
	add	bl,'0'			; convert tens byte to ascii numeral
	storchar bl
	add	bh,'0'			; convert ones byte to ascii numeral
	storchar bh
	pop	bx
	ret
cnvchar endp

	subttl	scrollup - as described for the ibm pc scroll up function
	page
;-----------------------------------------------------------------------
; scrollup - as described for the ibm pc scroll up function
;
; ah = 06h - scroll up
;   al = number of lines to scroll (0 to clear region)
;   bl = attribute to use on blanked lines
;   ch = top-left-corner row
;   cl = top-left-corner col
;   dh = bottom-right-corner row
;   dl = bottom-right-corner col
;   ds:si -> tcbddt
;   [tcbddt] = dword -> screen buffer @ page/row/col
;-----------------------------------------------------------------------
	assume	ds:tcb,es:nothing,ss:nothing
scrollup proc

ifdef	teletype
	ret
else
	push	[si].cursor		; final cursor position is current position
	mov	[si].tmpatr,bl		; attribute for scrolled-in lines
	mov	ah,bl
	mov	bl,al
	push	dx
	call	setattrib		; current attribute for blanked lines
	pop	dx
	or	cl,cl
	jz	sup0a			; z if box starts at col 0
	jmp	sboxup
sup0a:
	mov	al,[si].cols
	dec	al
	cmp	dl,al
	jnb	sup0b			; nb if box ends at last col
	jmp	sboxup
sup0b:
	test	[capable],speccls	; if using special cls
	jnz	sup0c			; then continue on with old logic
	test	[capable],lindel	; can term delete/insert lines?
	jnz	sup0c			; nz if it can insert/delete
	jmp	sboxup
sup0c:
	cmp	[maxrow],24		; 25 line terminal?
	jae	sup0e			; ae if 25 lines
	test	[si].tstate,bottom	; bottom or top visible
	jnz	sup0d			; if bottom visible
	push	dx
	mov	dl,[maxrow]
	inc	dl
	cmp	dh,dl
	pop	dx
	jbe	sup0e			; if top visible & box ends
					; before invisible line
	jmp	sboxup			; if scrolling invisible line
sup0d:
	cmp	ch,[extrar]
	jae	sup0e			; if bottom visible & box
					; begins after invisible line
	jmp	sboxup			; if scrolling invisible line
;-----------------------------------------------------------------------
; here if scrolling/blanking entire lines
;-----------------------------------------------------------------------
sup0e:
	cmp	dh,24
	jb	sup4			; b if box doesn't end at bottom row
	or	bl,bl
	jz	sup1			; z if clearing entire box
	mov	al,dh
	inc	al
	sub	al,ch			; al = number of rows in box
	cmp	bl,al
	jb	sup2
;-----------------------------------------------------------------------
; scrolling/blanking entire lines including last screen line
; scrolling as many lines as are box = clearing entire box
;-----------------------------------------------------------------------
sup1:
	mov	dx,cx
	mov	al,[si].tmpatr		; attribute for new lines
	call	testnrm 		; check if attribute produces normal video
	je	sup1a			; if it produces abnormal video
	call	setcursor		; set cursor to top row of box
	call	eeos
	jmp	supx
sup1a:
	mov	bl,25
	sub	bl,dh			; rows to clear = total rows - current row
	mov	bh,[si].cols		; row is 80 columns long
	call	clrbox
	jmp	supx
;-----------------------------------------------------------------------
; scrolling/blanking entire lines including last screen line
; scrolling fewer lines than in box
;-----------------------------------------------------------------------
sup2:
	test	[capable],speccls	; if using special cls
	jz	sup2a			; continue with normal scroll logic
	jmp	sboxup
sup2a:
	mov	dl,bl			; dh has bottom row, dl # to clear
	push	dx
	call	setrgn			; set scrolling region
	mov	dx,cx
	call	setcursor		; set cursor to top row of box
	mov	cl,bl
	xor	ch,ch
	mov	di,cs
	mov	es,di
sup3:
	lea	di,[deleteline] 	; and delete as many lines as are scrolled
	call	writesnc
	loop	sup3
	mov	ch,0
	mov	dh,[maxrow]
	call	setrgn			; reset scrolling region to whole screen
	pop	dx
	mov	al,[si].tmpatr		; attribute for new lines
	call	testnrm 		; does this attribute produce normal video?
	je	sup3a			; if abnormal video
	jmp	supx
sup3a:
	mov	bh,[si].cols		; length of rows to clear
	mov	bl,dl			; number of rows to clear
	dec	dl
	sub	dh,dl			; top row to clear
	xor	dl,dl			; start at column 0
	call	clrbox
	jmp	supx
;-----------------------------------------------------------------------
; scrolling/blanking entire lines, not including the last screen line
;-----------------------------------------------------------------------
sup4:
	inc	dh
	mov	al,dh
	sub	dh,ch			; dh = number of rows in box
	or	bl,bl
	jnz	sup5
	mov	bl,dh			; 0 lines scrolled = entire box (blanked)
sup5:
	sub	dh,bl
	ja	sup7			; a if some lines not blanked
;-----------------------------------------------------------------------
; scrolling/blanking entire lines, not including the last screen line
; clearing the box (for each line, clear to end of line)
;-----------------------------------------------------------------------
	add	bl,dh
	mov	dh,ch
	xor	dl,dl			; dx = cursor position of first row
	mov	cl,bl			; cx = number of lines to clear
	xor	ch,ch
sup6:					; for each row in box,
	mov	al,[si].tmpatr		; attribute for new lines
	call	testnrm
	jz	sup6a			; if abnormal video attributes
	push	dx
	push	cx
	call	setcursor		; set cursor to start of row
	call	eeol			; erase to end of line
	pop	cx
	pop	dx
	inc	dh
	loop	sup6
	jmp	supx
sup6a:
	mov	bh,[si].cols		; length of lines to clear in bh
	call	clrbox			; top row already in dx, # of lines in bl
	jmp	supx
;-----------------------------------------------------------------------
; scrolling/blanking entire lines, not including the last screen line
; scrolling some, clearing some
;-----------------------------------------------------------------------
sup7:
	call	setrgn			; set scrolling region to box
	mov	dh,al			; row of first row past box
	xor	dl,dl
	xor	cl,cl
	xchg	dx,cx
	call	setcursor		; starting with top line of box
	xchg	dx,cx
	mov	cl,bl			; number of lines to scroll
	xor	ch,ch
	mov	di,cs
	mov	es,di
sup8:
	push	dx
	lea	di,[deleteline] 	; delete the scrolled lines
	call	writesnc
	pop	dx
	dec	dh			; keeping track of first row past box
	loop	sup8
	push	dx
	call	setcursor		; set cursor to first row scrolled into box
	mov	cl,bl
	xor	ch,ch
	mov	di,cs
	mov	es,di
sup9:					;   move scrolled-in rows back out
	lea	di,[insertline] 	; and insert as many lines as scrolled to
	call	writesnc
	loop	sup9
	mov	ch,0
	mov	dh,[maxrow]
	call	setrgn			; reset scrolling region to whole screen
	pop	dx			; position of top of box
	mov	al,[si].tmpatr		; attribute for new lines
	call	testnrm 		; is it the normal attribute?
	jz	sup9a			; if not normal
	jmp	supx
sup9a:
	mov	bh,[si].cols		; bl already has # of lines, bh is length
	call	clrbox
	jmp	supx
;-----------------------------------------------------------------------
; scrolling/blanking less than entire lines
;-----------------------------------------------------------------------
sboxup:
	inc	dh
	sub	dh,ch
	or	bl,bl
	jnz	sbxu1
	mov	bl,dh
sbxu1:
	sub	dh,bl
	jbe	sbxu7			; be if clearing box
;-----------------------------------------------------------------------
; scrolling/blanking less than entire lines
; scrolling some, blanking some
;-----------------------------------------------------------------------
	inc	dl
	sub	dl,cl
	mov	bh,dl			; bh = length of each line
;-----------------------------------------------------------------------
; write dh lines of length bh getting chars to write starting from
;   row ch+bl and col cl in screen buffer
;-----------------------------------------------------------------------
	push	bx
	mov	al,ch
	add	al,bl
	mul	[si].cols
	mov	di,ax
	mov	al,cl
	xor	ah,ah
	add	di,ax
	shl	di,1
	add	di,word ptr [si].logscr ; starting position to copy from
	mov	bl,dh			; number of lines to write
	mov	dx,cx			; starting position for write

; di to start of first line to copy from

sbxu2:
	push	dx
	push	di
	push	di
	call	setcursor		; cursor to copy to (start of box line)
	pop	di
	mov	es,word ptr [si].logscr+2
	mov	cl,bh
	xor	ch,ch
sbxu3:
	mov	ax,es:[di]
	push	es
	push	di
	push	ax
	call	setattrib
	pop	ax
	call	setchar
	mov	di,ds
	mov	es,di
	lea	di,[si].string
	call	writestr
	pop	di
	pop	es
	inc	byte ptr [si].cursor	; advance cursor column
	add	di,2
	loop	sbxu3
	pop	di
	mov	al,[si].cols		; set di -> start of next box line to copy from
	xor	ah,ah
	add	di,ax
	add	di,ax
	pop	dx
	inc	dh
	dec	bl
	jnz	sbxu2
	pop	bx
	call	clrbox			; then blank the rest
	jmp	supx
;-----------------------------------------------------------------------
; scrolling/blanking less than entire lines
; clearing the box
;-----------------------------------------------------------------------
sbxu7:
	inc	dl
	sub	dl,cl
	mov	bh,dl			; bh = number of chars/row, bl = number of rows
	mov	dx,cx			; start of box
	call	clrbox
supx:
	pop	dx
	call	setcursor
	ret
endif

scrollup endp

;-----------------------------------------------------------------------
; starting at cursor position dx, for bl rows of length bh, clear box
;-----------------------------------------------------------------------
clrbox	proc
	push	dx
	mov	ah,[si].tmpatr		; attribute for new lines
	call	setattrib
	pop	dx
cbx8:
	push	dx
	call	setcursor		; for each line in box
	mov	cl,bh
	xor	ch,ch
	push	ax
	mov	ax,bx
	mov	al,[maxcol]
	pop	ax
	cmp	bh,[maxcol]
	jbe	cbx9
	test	[capable],speccls
	jz	cbx9
	push	bx
	push	cx
	push	word ptr [si].tstate
	and	byte ptr [si].tstate,not offscrn
	call	eeol
	pop	word ptr [si].tstate
	pop	cx
	pop	bx
	jmp	short cbx10
cbx9:
	mov	al,' '			; write spaces through the end of the box
	call	setchar
	mov	di,ds
	mov	es,di
	lea	di,[si].string
	call	writesnc
	inc	byte ptr [si].cursor	; advance cursor column
	loop	cbx9
cbx10:
	pop	dx
	inc	dh
	dec	bl
	jz	cbx11
	jmp	cbx8
cbx11:
	ret
clrbox	endp

;-----------------------------------------------------------------------
; chkbox - determine if scrolling box fits on terminal screen
;
; if on 24 line display, make sure ch & dh are in displayable range on
; exit.
;
;   ch = start row of scrolling region
;   dh = end row of scrolling region
;   ds:si -> tcbddt
;   [tcbddt] = dword -> screen buffer @ page/row/col
;
;  ch and dh changed to fit into displayable range
;  ah changed
;-----------------------------------------------------------------------
	assume	ds:tcb,es:nothing,ss:nothing
chkbox	proc
	cmp	[maxrow],24
	jae	chkb20			; if 25 line display, no problem
	test	[si].tstate,bottom
	jnz	chkb10			; if bottom of screen shows

; top of screen shows.

	cmp	dh,[maxrow]
	jb	chkb20			; if bottom of box above bottom of screen
	mov	dh,[maxrow]		; set bottom to bottom of screen
	jmp	short chkb20

; bottom of screen shows.

chkb10:
	cmp	ch,[extrar]		; top of box on invisible line?
	jae	chkb20			; if ch < [extrar], top is on invisible
	mov	ch,[extrar]		; lineh, to set top to first visible line
chkb20:
	ret
chkbox	endp

;-----------------------------------------------------------------------
; testnrm
;
; determine if attribute produces normal video or not
;
; input:  al contains attribute to check
; output: z flag set if attribute produces abnormal video
;	  z flag clear if attribute produces normal video
;	  all registers unchanged
;-----------------------------------------------------------------------
testnrm proc
	test	al,88h			; blinking or bold attribute?
	jnz	tstnx2			; if either of above
	cmp	al,70h			; reverse attribute?
	je	tstnx			; if reverse
	and	al,7
	cmp	al,1			; underline (z flag set for caller)
tstnx:
	ret
tstnx2:
	cmp	al,al			; set zero flag
	ret
testnrm endp

;-----------------------------------------------------------------------
; setrgn - set scrolling region on a terminal which requires it
;
;   ch = start row of scrolling region
;   dh = end row of scrolling region
;   ds:si -> tcbddt
;   [tcbddt] = dword -> screen buffer @ page/row/col
;-----------------------------------------------------------------------
	assume	ds:tcb,es:nothing,ss:nothing
setrgn	proc
	test	[capable],sclrgn	; does it need regions?
	jnz	setrg2			; if regions
	jmp	setrgx
setrg2:
	push	cx			; save as chkbox changes them
	push	dx
	call	notmonitor

; check rows for right settings.

	call	chkbox
setrg3:
	mov	dl,dh			; put end row in dl
	mov	dh,ch			; start row in dh
	test	[capable],colrow	; which comes first?
	jz	setrg5			; if row comes first
	xchg	dh,dl			; swap to write column byte first
setrg5:
	push	dx
	mov	di,cs
	mov	es,di
	lea	di,[rgintro]
	call	writesnc		; send the introducer string
	pop	dx
	lea	di,[si].string+1	; pointer to next byte in string
	mov	ah,0			; set string length to zero
	test	[capable],bincur	; binary position string?
	jz	setrg100		; if ascii position string

; binary format region string.

	add	dl,[rgoffs]		; convert to terminal's format
	storchar dl
	mov	al,[rgsep]
	or	al,al
	jz	setrg10 		; if no separator
	storchar al			; store separator
setrg10:
	add	dh,[rgoffs]
	storchar dh			; store second byte of string
	jmp	short setrg200		; exit routine

; ascii cursor position.

setrg100:
	lea	di,[si].string+1	; pointer to next byte in string
	mov	ah,0			; set string length to zero
	add	dl,[rgoffs]		; convert to terminal's format
	mov	al,dl
	call	cnvchar 		; convert the number to ascii
	mov	al,[rgsep]
	or	al,al
	jz	setrg110		; if no separator
	storchar al			; store separator
setrg110:
	mov	[si].string,ah		; store length
	mov	di,ds			; write out the cursor string
	mov	es,di
	lea	di,[si].string		; first half of string
	push	dx
	call	writesnc
	pop	dx
	lea	di,[si].string+1	; pointer to next byte in string
	mov	ah,0			; set string length to zero
	add	dh,[rgoffs]
	mov	al,dh			; convert number to ascii
	call	cnvchar
setrg200:
	mov	[si].string,ah		; store length
	mov	di,ds			; write out the cursor string
	mov	es,di
	lea	di,[si].string
	call	writesnc
	mov	di,cs
	mov	es,di
	lea	di,[rgterm]
	call	writesnc		; copy cursor terminator
	pop	dx
	pop	cx
setrgx:
	ret
setrgn	endp

ifdef	use_cpystr
;-----------------------------------------------------------------------
; cpystr
;
; copy string from cs:dx to ds:di.
; length in first byte of string.
;
; changes: ax, bx, cx, di
;-----------------------------------------------------------------------
cpystr	proc
	mov	bx,dx
	xor	ch,ch
	mov	cl,cs:[bx]
	inc	bx			; length of string in cx
	jcxz	cpyst20 		; if null string, quit now
cpyst10:
	mov	al,cs:[bx]
	inc	bx
	storchar al
	loop	cpyst10
cpyst20:
	ret
cpystr	endp

endif

	subttl	scrolldn - as described for the ibm pc scroll down function
	page
;-----------------------------------------------------------------------
; scrolldn - as described for the ibm pc scroll down function
;
; ah = 07h - scroll down
;   al = number of lines to scroll (0 to clear region)
;   bl = attribute to use on blanked lines
;   ch = top-left-corner row
;   cl = top-left-corner col
;   dh = bottom-right-corner row
;   dl = bottom-right-corner col
;   ds:si -> tcbddt
;   [tcbddt] = dword -> screen buffer @ page
;-----------------------------------------------------------------------
	assume	ds:tcb,es:nothing,ss:nothing
scrolldn proc

ifdef	teletype
	ret
else
	push	[si].cursor		; save initial position for end
	mov	[si].tmpatr,bl		; save attribute for scrolled-in lines
	mov	ah,bl
	mov	bl,al
	push	dx
	call	setattrib		; set attribute for blanked lines
	pop	dx
	or	cl,cl
	jz	sdn0a			; z if box begins at left edge of screen
	jmp	sboxdn			; (else not scrolling entire lines)
sdn0a:
	mov	al,[si].cols
	dec	al
	cmp	dl,al
	jnb	sdn0b			; nb if box ends at right edge of screen
	jmp	sboxdn			; (else not scrolling entire lines)
sdn0b:
	test	[capable],lindel	; can term insert/delete lines?
	jnz	sdn0c			; if it can
	jmp	sboxdn			; else do as partial lines
sdn0c:
	cmp	[maxrow],24		; 25 line terminal?
	jae	sdn0e			; ae if 25 lines
	test	[si].tstate,bottom	; bottom or top visible
	jnz	sdn0d			; if bottom visible
	cmp	dh,[maxrow]
	jbe	sdn0e			; if top visible & box ends
					; before invisible line
	jmp	sboxdn			; if scrolling invisible line
sdn0d:
	cmp	ch,[extrar]
	jae	sdn0e			; if bottom visible & box
					; ends before invisible line
	jmp	sboxdn			; if scrolling invisible line
;-----------------------------------------------------------------------
; scrolling/blanking entire lines
;-----------------------------------------------------------------------
sdn0e:
	cmp	dh,24
	jb	sdn4			; b if doesn't include the last line
	or	bl,bl
	jz	sdn1			; blanking box if 0 lines scrolled
	sub	dl,cl
	cmp	bl,dl
	jb	sdn2			; or more lines to scroll than in box
;-----------------------------------------------------------------------
; scrolling/blanking entire lines including last line
; blanking box
;-----------------------------------------------------------------------
sdn1:
	mov	dx,cx
	mov	al,[si].tmpatr		; attribute for new lines
	call	testnrm 		; check if attribute produces normal video
	je	sdn1a			; if it produces abnormal video
	call	setcursor
	call	eeos			; line of box
	jmp	sdnx
sdn1a:
	mov	bl,25
	sub	bl,dh			; rows to clear = total rows - current row
	mov	bh,[si].cols		; length of row to clear
	call	clrbox			; do the blank
	jmp	sdnx			; reset cursor position
;-----------------------------------------------------------------------
; scrolling/blanking entire lines including last line
; scrolling some, blanking some
;-----------------------------------------------------------------------
sdn2:
	call	setrgn			; set scrolling region to box
	push	dx
	mov	dx,cx
	call	setcursor		; cursor at first line of box
	mov	cl,bl
	xor	ch,ch
	mov	di,cs
	mov	es,di
sdn3:
	lea	di,[insertline] 	; insert as many lines as must be scrolled
	call	writesnc
	loop	sdn3
	mov	ch,0
	mov	dh,[maxrow]
	call	setrgn			; reset scrolling region to whole screen
	pop	dx
	mov	al,[si].tmpatr		; attribute for new lines
	call	testnrm 		; does this attribute produce normal video?
	je	sdn3a			; if abnormal video
	jmp	sdnx
sdn3a:
	mov	bh,[si].cols		; length of rows.  bl already has # of rows
	xor	dl,dl			; start at column 0.  dh already has top row
	call	clrbox
	jmp	sdnx
;-----------------------------------------------------------------------
; scrolling/blanking entire lines not including last line
;-----------------------------------------------------------------------
sdn4:
	inc	dh
	mov	al,dh
	sub	dh,ch			; number of rows in box
	or	bl,bl
	jnz	sdn5			; nz if not blanking box
	mov	bl,dh			; else scrolling all lines in box (blanking it)
sdn5:
	sub	dh,bl
	ja	sdn7			; a if scrolling some, blanking some
;-----------------------------------------------------------------------
; scrolling/blanking entire lines not including last line
; clearing the entire box (for each line, clear to end of line)
;-----------------------------------------------------------------------
	add	bl,dh			; number of lines in box
	mov	dh,ch			; start row of box
	xor	dl,dl
	mov	cl,bl
	xor	ch,ch
sdn6:
	mov	al,[si].tmpatr		; attribute for new lines
	call	testnrm
	jz	sdn6a			; if abnormal video attribute
	push	dx
	push	cx
	call	setcursor
	call	eeol			; erase to end of line
	pop	cx
	pop	dx
	inc	dh
	loop	sdn6
	jmp	sdnx
sdn6a:
	mov	bh,[si].cols		; length of lines to clear in bh
	call	clrbox
	jmp	sdnx
;-----------------------------------------------------------------------
; scrolling/blanking entire lines not including last line
; scrolling some of box and clearing some of box
;-----------------------------------------------------------------------
sdn7:
	call	setrgn			; set scrolling region to box
	push	cx
	xor	dl,dl
	mov	dh,al			; dh = first line past box
	sub	dh,bl			; first line scrolled out of box
	mov	cl,bl
	xor	ch,ch			; cx = number of lines scrolled
	call	setcursor
	mov	di,cs
	mov	es,di
sdn8:
	lea	di,[deleteline] 	; delete lines scrolled out of box
	call	writesnc
	loop	sdn8
	pop	dx
	push	dx
	call	setcursor		; then insert that many lines back at the
	mov	cl,bl			; top of the box
	xor	ch,ch
	mov	di,cs
	mov	es,di
sdn9:
	lea	di,[insertline]
	call	writesnc
	loop	sdn9
	mov	ch,0
	mov	dh,[maxrow]
	call	setrgn			; reset scrolling region to whole screen
	pop	dx
	mov	al,[si].tmpatr		; attribute for new lines
	call	testnrm 		; is it normal?
	jz	sdn9a			; if abby normal
	jmp	sdnx
sdn9a:
	mov	bh,[si].cols		; bl has # of lines, bh is length of lines
	call	clrbox
	jmp	sdnx
;-----------------------------------------------------------------------
; scrolling/blanking less than entire lines
;-----------------------------------------------------------------------
sboxdn:
	inc	dh
	sub	dh,ch
	or	bl,bl
	jnz	sbxd1
	mov	bl,dh
sbxd1:
	sub	dh,bl
	jbe	sbxd7			; be if clearing box
;-----------------------------------------------------------------------
; scrolling/blanking less than entire lines
; scrolling some, blanking some
;-----------------------------------------------------------------------
	inc	dl
	sub	dl,cl
	mov	bh,dl			; bh = length of each line
;-----------------------------------------------------------------------
; write dh lines of length bh getting chars to write starting from
;   row ch+bl and col cl in screen buffer
;-----------------------------------------------------------------------
	push	cx
	push	bx
	mov	al,ch
	add	al,bl
	mov	bl,dh			; number of lines to copy
	mov	dh,al			; start row to copy to
	mov	dl,cl
	mov	al,ch
	mul	[si].cols
	mov	di,ax
	mov	al,cl
	xor	ah,ah
	add	di,ax
	shl	di,1
	add	di,word ptr [si].logscr ; starting position to copy from di
sbxd2:					; to start of first line to copy from
	push	dx
	push	di
	push	di
	call	setcursor		; cursor to copy to (start of box line)
	pop	di
	mov	es,word ptr [si].logscr+2
	mov	cl,bh
	xor	ch,ch
sbxd3:
	mov	ax,es:[di]
	push	es
	push	di
	push	ax
	call	setattrib
	pop	ax
	call	setchar
	mov	di,ds
	mov	es,di
	lea	di,[si].string
	call	writestr
	pop	di
	pop	es
	inc	byte ptr [si].cursor	; advance column number
	add	di,2
	loop	sbxd3
	pop	di
	mov	al,[si].cols		; set di -> start of next box line to copy from
	xor	ah,ah
	add	di,ax
	add	di,ax
	pop	dx
	inc	dh
	dec	bl
	jnz	sbxd2
	pop	bx
	pop	dx			; start of box
	call	clrbox			; blank top bl lines of box
	jmp	sdnx
;-----------------------------------------------------------------------
; scrolling/blanking less than entire lines
; clearing the box
;-----------------------------------------------------------------------
sbxd7:
	inc	dl
	sub	dl,cl
	mov	bh,dl			; bh = number of chars/row, bl = number of rows
	mov	dx,cx			; start of box
	call	clrbox
sdnx:
	pop	dx			; restore original cursor position
	call	setcursor
	ret
endif
scrolldn endp

	subttl	wrchatr - write character and attribute
	page
;-----------------------------------------------------------------------
; wrchatr - write character and attribute
;
; ah = 08h - write character and attribute at row & col & page
;   al = char to write
;   bl = attribute to write
;   cx = number of times to write
;   dh = row
;   dl = col
;   ds:si -> tcbddt
;   [tcbddt] = dword -> screen buffer @ page/row/col
;-----------------------------------------------------------------------
	assume	ds:tcb,es:nothing,ss:nothing
wrchatr proc
	les	di,[si].logscr
	mov	ah,bl
	mov	bx,ax

ifndef	teletype
wrcha1:
	scasw
	jne	wrcha3
	inc	dl
	cmp	dl,[si].cols
	jb	wrcha2
	xor	dl,dl
	inc	dh
	cmp	dh,25
	jae	wrchax
wrcha2:
	loop	wrcha1
	ret
wrcha3:
	sub	di,2
	dec	cx
	jz	wrcha4
	add	di,cx
	add	di,cx
	inc	cx
	std
	repe scasw
	cld
wrcha4:
	inc	cx
	push	dx
	call	setattrib
	pop	dx
endif

wrcha5:
	cmp	dh,24
	jb	wrcha6
	cmp	dl,79
	jae	wrchax
wrcha6:
	push	dx
	call	setcursor
	mov	al,bl
	call	setchar
	mov	di,ds
	mov	es,di
	lea	di,[si].string
	call	writestr
	pop	dx
	inc	byte ptr [si].cursor	; not col>=80 causes [si].cursor <>
	inc	dl			;   dx and cursor is explictly set
	cmp	dl,[si].cols		;   next time
	jb	wrcha8
	xor	dl,dl
	inc	dh
wrcha8:
	loop	wrcha5
wrchax:
	ret
wrchatr endp

	subttl	setpalet - set color palette or background color
	page
;-----------------------------------------------------------------------
; setpalet - set color palette or background color
;
; ah = 09h - set color palette or background color
;   bh = 01h - set color palette
;     bl = palette
;   bh = 00h - set background (border) color
;     bl = color
;   ds:si -> tcbddt
;-----------------------------------------------------------------------
	assume	ds:tcb,es:nothing,ss:nothing
setpalet proc
	ret
setpalet endp

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
;-----------------------------------------------------------------------
	assume	ds:tcb,es:nothing,ss:nothing
wrtty	proc
	mov	bl,al
	mov	cx,dx
	call	setcursor
	mov	dx,cx
	mov	al,bl
	cmp	al,07h
	jne	wrtty1
	call	notmonitor
	mov	al,07h
	jmp	wrttyy
wrtty1:
	cmp	al,08h
	jne	wrtty2
	jmp	wrtty08
wrtty2:
	cmp	al,0ah
	je	wrtty0a
	cmp	al,0dh
	jmpe	wrtty0d
	call	setchar
	inc	dl
	mov	byte ptr [si].cursor,dl
	cmp	dl,80
	jae	wrtty3			; >= 80 and cursor will be explicitly set next
	jmp	wrttyx			;   time it's used
wrtty3:
	inc	dh
	cmp	dh,[maxrow]
	jmpbe	wrttyx
	cmp	dh,25
	jb	wrtty4			; if not past logical bottom line
	mov	di,word ptr [si].logscr
	mov	cl,dl
	dec	cl
	xor	ch,ch
	sub	di,cx
	sub	di,cx
	mov	word ptr [si].logscr,di
	jmp	short wrtty4
wrtty0a:
	call	notmonitor
	mov	al,0ah
	inc	dh
	cmp	dh,[extrar]
	ja	wrtty4
	test	[si].tstate,bottom	; we're on a 24 line terminal
	jnz	wrtty4b 		; if on invisible line on top
wrtty4:
	cmp	dh,[maxrow]
	ja	wrtty4a
	mov	byte ptr [si].cursor+1,dh  ; set new cursor position
	jmp	wrttyx
wrtty4a:
	mov	[si].string,1
	mov	[si].string+1,al

; on or beneath last visible line.

	cmp	[maxrow],24		; 25 line screen?
	jae	wrtty5			; if 25 lines, do line feed
	test	[si].tstate,bottom
	jnz	wrtty5			; if bottom line visible, erase it

; there is an invisible bottom line.

	mov	cl,dh
	dec	cl
	cmp	cl,[maxrow]
	je	wrtty4b 		; if starting from last visible line

; scroll whole screen from invisible bottom line.

	dec	dh			; back to bottom line
	push	dx			; save cursor
	mov	di,ds
	mov	es,di
	lea	di,[si].string
	call	writesnc		; scroll the screen
	les	di,[si].logscr
	mov	cl,dl
	xor	ch,ch
	sub	di,cx
	sub	di,cx			; now pointing to beginning of row 25
	mov	dh,[maxrow]		; display at bottom of terminal
	xor	dl,dl			; column 0
	mov	cx,80			; number of characters to write
	call	wrstr			; line 25 goes at bottom of terminal
	pop	dx
	call	setcursor		; set cursor to new location
	jmp	wrttyz			; leave

; on last visible line above invisible line, or invisible line
; above first visible line, eat line feed, set new cursor position.

wrtty4b:
	call	setcursor
	jmp	wrttyz			; exit

; normal line feed handling.

wrtty5:
	mov	byte ptr [si].cursor+1,dh
	dec	dh			; back to bottom line
	mov	di,ds
	mov	es,di
	lea	di,[si].string
	call	writesnc		; scroll the screen
	les	di,[si].logscr
	mov	ah,es:[di+1]
	cmp	ah,[si].attrib
	je	wrttyz
	call	setattrib
	xor	dl,dl
	call	setcursor
	call	eeol			; erase to end of line
	jmp	wrttyz

; carriage return unless already at col 0

wrtty0d:
	or	dl,dl
	jz	wrttyz
	call	notmonitor
	mov	al,0dh
	mov	byte ptr [si].cursor,0
	jmp	short wrttyy

; backspace, if not at col 0

wrtty08:
	or	dl,dl
	jz	wrttyz
	call	notmonitor
	mov	al,08h
	dec	byte ptr [si].cursor
	jmp	short wrttyy

; write a single character to the terminal

wrttyx:
	mov	[si].string,1
	mov	[si].string+1,al
wrttyx1:
	mov	di,ds
	mov	es,di
	lea	di,[si].string
	call	writestr		; honor offscreen flag
	jmp	short wrttyz

; write the string to the terminal, ignore offscreen flag.

wrttyy:
	mov	[si].string,1
	mov	[si].string+1,al
	mov	di,ds
	mov	es,di
	lea	di,[si].string
	call	writesnc
wrttyz:
	ret
wrtty	endp

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
;   es:di -> string
;-----------------------------------------------------------------------
	assume	ds:nothing,es:nothing,ss:nothing
wrstr	proc

	cmp	dh,24
	jb	wrs1
	cmp	dl,79
	jae	wrsx
wrs1:
	mov	bx,es:[di]
	add	di,2
	push	es
	push	di
	push	dx
	call	setcursor
	mov	ah,bh
	call	setattrib
	mov	al,bl
	call	setchar
	mov	di,ds
	mov	es,di
	lea	di,[si].string
	call	writestr
	pop	dx
	pop	di
	pop	es
	inc	byte ptr [si].cursor	; >=80 means <> dx and cursor pos
	inc	dl			;   will be explictly set next time
	cmp	dl,[si].cols
	jb	wrs3
	xor	dl,dl
	inc	dh
	cmp	dh,25
	jb	wrs3			; if row still in range
	mov	dh,24
wrs3:
	loop	wrstr
wrsx:
	ret
wrstr	endp

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
;-----------------------------------------------------------------------
	assume	ds:nothing,es:nothing,ss:nothing
setwindow proc
	xor	dx,dx			; initial cursor position
	les	di,[si].logscr		; screen pointer
	cmp	[maxrow],24		; 25 rows on terminal?
	jae	setw30			; if it has 25

; 24 line terminal support.

	or	al,al			; display top or bottom?
	jnz	setw10			; if bottom
	and	[si].tstate,not bottom	; top of screen, clear bottom flag
	jmp	short setw20
setw10:
	or	[si].tstate,bottom	; bottom of screen, set bottom flag
	mov	al,[extrar]
	mov	ah,80 * 2
	mul	ah			; bytes past top of screen
	add	di,ax			; display top - 1 row
	inc	dh			; start from row 1, not 0
setw20:
	mov	al,[maxrow]
	inc	al			; from max number to # of rows
	mov	ah,80
	mul	ah			; number of chars in terminal screen
	mov	cx,ax

; redisplay screen.

setw30:
	call	wrstr
	mov	[si].cursor,-1		; invalidate old cursor position
	ret
setwindow endp

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
;-----------------------------------------------------------------------
	assume	ds:nothing,es:nothing,ss:nothing
wrcho proc

ifndef	teletype
	les	di,[si].logscr
	mov	bl,al
wrcho1:
	scasb
	jne	wrcho3
	inc	di
	inc	dl
	cmp	dl,[si].cols
	jb	wrcho2
	xor	dl,dl
	inc	dh
	cmp	dh,25
	jae	wrchox
wrcho2:
	loop	wrcho1
	ret
wrcho3:
	dec	di
	dec	cx
	jz	wrcho4
	add	di,cx
	add	di,cx
	std
wrcho3a:
	scasb
	jne	wrcho4
	dec	di
	loop	wrcho3a
wrcho4:
	cld
	inc	cx
	inc	di
endif

wrcho5:
	cmp	dh,24
	jb	wrcho5a
	cmp	dl,79
	jae	wrchox
wrcho5a:
	mov	bh,es:[di]
	add	di,2
	push	es
	push	di
	push	dx
	call	setcursor
	mov	ah,bh
	call	setattrib
	mov	al,bl
	call	setchar
	mov	di,ds
	mov	es,di
	lea	di,[si].string
	call	writestr
	pop	dx
	pop	di
	pop	es
	inc	byte ptr [si].cursor
	inc	dl
	cmp	dl,[si].cols
	jb	wrcho6
	xor	dl,dl
	inc	dh
wrcho6:
	loop	wrcho5
wrchox:
	ret
wrcho	endp

	subttl	readch - read char/attribute at row & col & page
	page
;-----------------------------------------------------------------------
; ah = 0eh - read char/attribute at row & col & page
;     (master console only)
;   dh = row
;   dl = col
;   ds:si -> tcbddt
;   [tcbddt] = dword -> screen buffer @ row/col/page
;-----------------------------------------------------------------------
	assume	ds:nothing,es:nothing,ss:nothing
readch	proc
	ret
readch	endp

	subttl	getscr - get screen
	page
;-----------------------------------------------------------------------
; ah = 0fh - get screen
;     (master console only)
;   ds:si -> tcbddt
;   [tcbddt] = dword -> logical screen buffer
;   cx = word length to get
;-----------------------------------------------------------------------
	assume	ds:nothing,es:nothing,ss:nothing
getscr	proc
	ret
getscr	endp

	subttl	prch - print a character on the terminal's local printer
	page
;-----------------------------------------------------------------------
; prch - print a character on the terminal's local printer
;
;   ah = 10h
;     al = char to print
;     ds:si -> tcbddt
;
;   returns ah as in int 17h call
;-----------------------------------------------------------------------
	assume	ds:nothing,es:nothing,ss:nothing
prch	proc
	mov	bl,al
	test	[si].tstate,print
	jnz	prch1
	or	[si].tstate,print
	call	notmonitor
	mov	di,cs
	mov	es,di
	lea	di,[printon]
	call	writesnc
prch1:
	mov	[si].string,1
	mov	[si].string+1,bl
	mov	di,ds
	mov	es,di
	lea	di,[si].string
	call	writesnc
	ret
prch	endp

	subttl	prstr - print a string on the terminal's local printer
	page
;-----------------------------------------------------------------------
; prstr - print a string on the terminal's local printer
;
;   ah = 11h
;   es:di -> string to print
;   cx = length (bytes) to print
;   ds:si -> tcbddt
;
;   returns ah as in int 17h call if all of string can't be printed
;     and di -> first char not printed, cx = number not printed
;-----------------------------------------------------------------------
	assume	ds:nothing,es:nothing,ss:nothing

prstr	proc
	mov	al,es:[di]
	inc	di
	push	es
	push	di
	call	prch
	pop	di
	pop	es
	loop	prstr
	ret
prstr	endp


	subttl	setattrib - set current attribute
;-----------------------------------------------------------------------
; set current attriubte to ah
;-----------------------------------------------------------------------
	assume	ds:nothing,es:nothing,ss:nothing
setattrib proc
	cmp	ah,[si].attrib
	je	setax
	push	cx
	push	bx
	mov	[si].attrib,ah
	mov	bh,ah
	call	notmonitor
	mov	al,bh

; start with null attribute.

	mov	di,cs
	mov	es,di
	lea	di,[attrsoff]		; initially set normal attribute
	call	writesnc
	test	[si].attrib,77h
	jnz	seta2
	lea	di,[blankon]
	call	writesnc		; set invisible attribute
seta2:
	test	[si].attrib,80h
	jz	seta3
	lea	di,[blinkon]
	call	writesnc		; set blinking attribute
seta3:
	cmp	[si].attrib,70h
	jne	seta4
	lea	di,[reverseon]
	call	writesnc		; set reverse video attribute
seta4:
	mov	al,[si].attrib
	and	al,07h
	cmp	al,01h
	jne	seta5
	lea	di,[underon]
	call	writesnc		; set underline attribute
seta5:
	test	[si].attrib,08h
	jz	seta6
	lea	di,[boldon]		; set bold attribute
	call	writesnc
seta6:
	pop	bx
	pop	cx
setax:
	ret
setattrib endp

	subttl	setchar - prepare to send character to display
;-----------------------------------------------------------------------
; prepare to send character to display
;-----------------------------------------------------------------------
	assume	ds:nothing,es:nothing,ss:nothing
setchar proc
	push	bx
	push	cs
	pop	es
	test	[si].tstate,print
	je	setch1
	and	[si].tstate,not print
	lea	di,[printoff]
	call	writesnc
setch1:
	mov	bx,offset grp:txtbl
	xlat	txtbl			; translate characters as terminal requires
	xor	bx,bx
setch4:
	mov	[si][bx].string+1,al
	inc	bx
	mov	[si].string,bl
	pop	bx
	ret
setchar endp

	subttl	notmonitor - make sure we're not in monitor mode
	page
;-----------------------------------------------------------------------
; make sure we're not in monitor mode
;-----------------------------------------------------------------------
notmonitor proc
	test	[si].tstate,normal
	jnz	notprint
	or	[si].tstate,normal
	mov	di,cs
	mov	es,di
	lea	di,[monitoroff]
	push	dx
	call	writesnc
	pop	dx
	ret
notmonitor endp

;-----------------------------------------------------------------------
; make sure the printer is turned off
;-----------------------------------------------------------------------
notprint proc
	test	[si].tstate,print
	jz	notprnx
	and	[si].tstate,not print
	mov	di,cs
	mov	es,di
	lea	di,[printoff]
	push	dx
	call	writesnc
	pop	dx
notprnx:
	ret
notprint endp

	subttl	erase - erase lines on the terminal
	page
;-----------------------------------------------------------------------
; erase to end of screen from current position
; di contains erase command
;-----------------------------------------------------------------------
eeos	proc
ifdef	teletype
	mov	[si].string,2		; write 1 cr/lf pair, then quit
	mov	[si].string+1,0dh
	mov	[si].string+2,0ah
	mov	di,ds
	mov	es,di
	lea	di,[si].string
	call	writesnc
else
	xor	cx,cx
	mov	cl,[ceos]		; length of erase string is presence test
	jcxz	eeos100 		; no erase string
	mov	dh,byte ptr [si].cursor+1  ; current column
	test	[si].tstate,bottom	; bottom of screen showing?
	jnz	eeos10			; if bottom, any screen stuff ok
	cmp	dh,[maxrow]
	ja	eeosx			; if off screen, quit
eeos10:
	mov	di,cs
	mov	es,di
	lea	di,[ceos]		; es:di points to string to write
	call	writesnc
	jmp	eeosx			; leave routine

; erase to end of screen without equipment.

eeos100:
	mov	dx,[si].cursor
	push	dx			; save cursor for end of procedure
	mov	cl,[maxrow]		; get maximum terminal row
	sub	cl,dh			; subtract current row
eeos110:
	inc	byte ptr [si].cursor+1	; fake out eeol so final position
					; is on next line
	push	cx
	call	eeol			; erase to the end of this line, move to next
	pop	cx
	loop	eeos110
	pop	dx			; remember old cursor position
	call	setcursor		; move to it
eeosx:
endif
	ret
eeos	endp

;-----------------------------------------------------------------------
; eeol
; erase to end of line from current position
; changes: al, cx, dx, di, es
;-----------------------------------------------------------------------
eeol	proc
	test	[si].tstate,offscrn
	jz	eeol10
	ret
eeol10:
	xor	cx,cx
	mov	cl,[ceoln]		; length of erase string is presence test
	jcxz	eeol100 		; no erase string
	mov	di,cs
	mov	es,di
	lea	di,[ceoln]		; es:di points to string to write
	call	writesnc
	jmp	eeolx			; leave routine

; erase to end of line without equipment.

eeol100:
	mov	dx,[si].cursor
	push	dx			; save cursor position
	mov	cl,[maxcol]		; get maximum column position
	sub	cl,dl			; subtract current position
	mov	[si].string,1		; print one space many times
	mov	[si].string+1,' '	; this is the space
	mov	di,ds
	mov	es,di			; it's in the data segment
eeol110:
	lea	di,[si].string
	call	writestr		; write a space
	inc	byte ptr [si].cursor	; increment column position
	loop	eeol110
	pop	dx
	call	setcursor		; restore original cursor position
eeolx:
	ret
eeol	endp

	subttl	writestr - send a string of bytes to the terminal
	page
;-----------------------------------------------------------------------
; send a string of bytes to the terminal
;-----------------------------------------------------------------------
	assume	ds:nothing,es:nothing,ss:nothing
writestr proc
	mov	dx,[si].port
	test	[si].tstate,offscrn
	jnz	writeso 		; if cursor off screen
	test	[capable],btmwrp	; does it wrap when you write
					; to bottom right corner?
	jz	writes3 		; if it doesn't wrap
	mov	ax,[si].cursor
	cmp	[maxrow],24
	jae	writes1 		; if 25 line terminal
	test	[si].tstate,bottom
	jz	writes1
	sub	ah,[extrar]		; adjust for screen size
writes1:
	cmp	ah,[maxrow]		; on bottom row?
	jb	writes3 		; if above bottom row
	cmp	al,[maxcol]		; at rightmost column?
	jb	writes3 		; if to left of rightmost column
	ret				; don't move cursor
writes3:
	mov	dx,[si].port

; fall through into common subroutine

write1s proc
	push	cx
	mov	cl,es:[di]
	xor	ch,ch
	inc	di
	jcxz	write1x
write1a:
	mov	al,es:[di]
	mov	ah,01h
	do14h
	or	ah,ah
	js	write1a
	inc	di
	loop	write1a
write1x:
	pop	cx
	ret
write1s endp

writeso proc				; offscreen, move cursor right one place
	push	cx
	xor	ch,ch
	mov	cl,es:[di]		; count for write
	mov	di,cs
	mov	es,di
	mov	di,offset grp:crrt	; move cursor right string
writeso1:
	mov	al,byte ptr [si].cursor
	cmp	al,[maxcol]		; to end of line yet?
	jae	writeso2		; if at end of line, don't move
	push	di
	call	write1s 		; write first string
	pop	di
writeso2:
	loop	writeso1		; write the rest
	pop	cx
	ret
writeso endp

writesnc proc				; write string with no offscreen check
	mov	dx,[si].port
	jmp	write1s
writesnc endp

writestr endp

	subttl	ddtinit - mos device driver init
	page
;-----------------------------------------------------------------------
; initialization - set driver length and exit
;-----------------------------------------------------------------------
ddtinit proc	near
	push	si
	mov	si,offset grp:tname
ddtinlp:
	lodsb				; remove $'s
	cmp	al, '$'
	je	ddtinlp
	dec	si
	mov	dx, si
	mov	ah,9
	int	21h			; display driver name
	mov	dx,offset grp:inits2
	mov	ah,9
	int	21h
	mov	word ptr es:[bx+14],offset grp:ddtinit
	mov	es:[bx+16],cs
	mov	ax,0100h
	pop	si
	ret
ddtinit endp

inits2	db	" terminal device driver installed",0ah,0dh,"$"  ;@@xlat

ddt	ends
	end
