	include page.inc
	title	mosdebug.asm - debug information output routine
comment ^===============================================================
		    development specification

 program name:	mos.com 		assigned to: david morrow
 module name:	mosdebug		assign date: 08/29/86
 entry points:	mosdebug		completed:
 entry from:	anyone and everyone
 entry method:	call
 calls:		no one
 purpose:	to output debug information in specified format
 refer to:	n/a
 last update:	08/18/1992
========================================================================

sah 04/20/87	added smp heap checking option for debugging

sah 06/19/87	added mcb checking and optional dumping

sah 07/11/87	added interupt 38 support

sah 10/20/87	remove internal debugger for production version

sah 01/22/88	change scbseg and zero seg to mgetxxxx macros

sah\rdr 02/21/88 move ddt segment to mo2 group

sah 05/19/88  change removal of mcb stuff to conditional assembly

================ 5.01 kernel ends here ====================================

mjs 08/18/92	clean up segment declarations

mjs 08/26/92	delete reference to scbfree

======================================================================^

.xlist
;	include mosdebug.pub
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

;======================================================== mos segment
if 0 eq 0
segment_num = 1
endif
mosseg	segment
	assume	cs:mos,ds:nothing,es:nothing,ss:nothing

	extrn	mosend:byte, sbios:word
	extrn	chkheap:near

	public	hex2asc

	if	mdebug eq 1
	public mosdebug, dec2asc, mossimck, mossim, int38p
	endif


mtrace	equ	0			; true if mcb trace included
fcbdump equ	0			; do fcbdumps if true

if	mdebug eq 1
	.list
	subttl	mosdebug - output debug information

	page
;-----------------------------------------------------------------------
; this routine will output a debug message to one of the following:
; the screen, an alternate screen, or a serial port (depending on the
; setting of the config.sys command dbport).  if requested by
; the calling routine a full register dump will be performed.  the
; calling routine may also request a key press or even an 'Abort or
; ignore' prompt.
;
;  on entry:
;	ds:dx -> message to display terminated by a '$'
;
;	al = command list (bitwise)
;		bit 0 - display full register dump
;		bit 1 - prompt for 'Abort or Ignore'
;		bit 2 - pause for keypress (ignored if bit 1=1)
;		bit 3 - test for key input, return in al (0 if none)
;		bit 4 - use task registers for regdump
;		bit 5 - interupt 38 to be process (0 if not int 38)
;		bit 6 - undefined
;		bit 7 - undefined
;
;	sp+6 -> original ax (pushed before calling mosdebug)
;	sp+4 -> original ds	"       "	"       "
;	sp+2 -> original dx	"       "	"       "
;
;	the idea here that ax, ds and dx are saved on the stack before
;	being pointed to a message to display.
;
;  on exit:
;	al = ascii of key pressed (if bit 2 set on entry)
;	cf = 0 for ignore or 1 for abort (if bit 1 set on entry)
;	ds and dx are cleared from the stack (no need to pop them)
;
;	no global data affected
;	no global procedures called
;	all registers preserved (ax, ds and dx are restored to pre-call
;	value except where al is supposed to return a value)
;-----------------------------------------------------------------------
simhk	db	'@'			; sim hotkey
simon	db	'On $'
simoff	db	'Off$'

simmen	db	13,10,'--  System Input Monitor  --',13,10
	db	13,10,'1) Toggle reg dump on funs 0-C  $'
simm2	db	13,10,'2) Toggle reg dump on funs D-30 $'
simm3	db	13,10,'3) Toggle reg dump on funs 31+  $'
simm4	db	13,10,'4) Toggle pause on INT 21 entry $'
simm5	db	13,10,'5) Toggle pause on INT 21 exit  $'
simm6	db	13,10,'6) Toggle MOS internal INT 21s  $'
simm7	db	13,10,'7) Toggle MOS Interupt 38 Calls $'
simm8	db	13,10,'8) Toggle MOS SMP heap checking $'
simm9	db	13,10,'9) Toggle MOS MCB Checking      $'
simmp	db	13,10,13,10,'Choice or <RET> to end?$'
simcr	db	13,10,'$'

regmsg	db	13,10,'AX='
regdata db	'0000  BX=0000  CX=0000  DX=0000  '
	db	'SP=0000  BP=0000  SI=0000  DI=0000',13,10
	db	'DS=0000  ES=0000  SS=0000  CS=0000  '
	db	'IP=0000   '
regf	db	'OV DN EI NG ZR AC PE CY ',13,10,'$'

					;=1 =0
flagdat db	'OV NV '	; overflow
	db	'DN UP '		; direction
	db	'EI DI '		; interrupt
	db	'NG PL '		; sign
	db	'ZR NZ '		; zero
	db	'AC NA '		; auxiliary carry
	db	'PE PO '		; parity
	db	'CY NC '		; carry

flgtst	dw	800h			; overflow	\
	dw	400h			; direction	 \
	dw	200h			; interrupt	  \
	dw	 80h			; sign		   \ bit positions
	dw	 40h			; zero		   /
	dw	 10h			; aux carry	  /
	dw	  4h			; parity	 /
	dw	  1h			; carry 	/
	dw	0			; list terminator

regflg	dw	0
saveax	dw	0			; save space

					; this byte is local (input only from the debug port)
lstread db	0		; last read serial char

smpchk	db	0			; smp heap checking
mcbchk	db	0			; mcb checking
int38p	db	0			; interupt 38 processing

msgabig db	'Abort or Ignore?$'
msgabrt db	' Abort',13,10,'$'
msgignr db	' Ignore',13,10,'$'

mcbbad	db	13,10,'MCB Chain is corrupted',13,10,'$'
i38msg	db	13,10,'MOS Extended Interupt 38H Function Calls$'

if	fcbdump
msgcr	db	13,10,'$'

msgaddr db	'xxxx:xxxx  '
msgdta	db	'xx xx xx xx xx xx xx xx-xx xx xx xx xx xx xx xx   '
msgadta db	'xxxxxxxxxxxxxxxx',13,10,'$'
endif

;-----------------------------------------------------------------------
mosdebug proc	near

	assume	ds:nothing, es:nothing	; it could be anything!
	pushf
	pop	[regflg]		; save flags
	push	si

; do register dump before anything else
; if interupt 38 processing is on it will always be dump no matter if
; interupt 21 dumping is turn on or off

	test	al,20h			; interupt 38h call
	jz	dordump 		; no...do reg dump
	cmp	[int38p],0		; interupt 38 processing
	jz	skipdump		; no...skip dump
	lea	si, i38msg		; display interupt 38 message
	call	msgout
	jmp	doregdp
dordump:
	test	al,1			; do they want dump
	jz	skipdump
doregdp:
	call	regdump 		; yes

skipdump:
	mov	si,dx
	call	msgout			; display message at ds:si

	test	[smpchk], 1		; ***** do they want heap check
	jz	cmdmcb
	push	ds
	mgetscb ds
	call	chkheap 		; ***** check the heap (temporary sah 4-20-87)
	pop	ds

cmdmcb:


if	mtrace
	test	[mcbchk], 1		; ***** do they want mcb check
	jz	cmdrest

	push	ax
	push	bx
	push	cx
	push	bp

	call	mbtrace

;	xor	bx,bx
;	call	mbcheck 	; ***** process mcb checking

	pop	bp
	pop	cx
	pop	bx
	pop	ax
;	jnc	cmdrest
;	lea	si,mcbbad
;	call	msgout		; disp error message

;cmdrest:
endif


; do rest of commands here

	test	al,2			; prompt for 'Abort or Ignore'?
	jz	cmdnext 		; no
	call	askabig 		; ask for abort or ignore
	jmp	cmdnext2		; skip keypress check
cmdnext:
	test	al,4			; get keypress?
	jz	$+5			; no
	call	askkey			; get key
	jmp	dbexit2 		; exit with key in al
cmdnext2:
	test	al,8			; test input?
	jz	$+5			; no
	call	dbtchar 		; test for key
cmdnext3:
					; add any other tests here

	pop	si
	pop	[regflg]		; get return address
	pop	dx			; restore original for caller
	pop	ds			;	"       "	"
	pop	ax			;	"       "	"
	jmp	[regflg]		; return to calling routine
dbexit2:
	pop	si
	pop	[regflg]		; get return address
	pop	dx			; restore original for caller
	pop	ds			;	"       "	"
	pop	[saveax]		; clear old ax value from stack
	jmp	[regflg]		; return to calling routine


	if mtrace
	subttl	mbtrace - trace mcb chain and display content
	page
;-----------------------------------------------------------------------
;	mbtrace -  traces mcb chain and displays to debug console
;		   displays segment:parent:lenght
;-----------------------------------------------------------------------

mtbuff	db	79 dup (' ')
mtcr	db	13,10,'$'

mbtrace proc	near
	push	si
	push	di
	push	ds
	push	es

	push	cs
	pop	ds
	assume	ds:mos

	lea	si,mtcr
	call	msgout

	push	cs
	pop	es
	lea	di,mtbuff
	mov	cx,78/2
	mov	ax, 2020h
	cld
	rep	stosw

	lea	si,mtbuff
	xor	cx,cx			; zero out counter
	mgetscb es
	assume	es:grp
	mov	es,[scbtcbpc]
	assume	es:tcb
	mov	es,[tcbmbpf]		; get top pointer


mtloop	label	near
	push	cx
	mov	ax,es
	mov	dx,si
	call	hex2asc
	mov	byte ptr [si+4],':'
	add	si,5
	mov	ax,es:[1]
	mov	dx,si
	call	hex2asc
	mov	byte ptr [si+4],':'
	add	si,5
	mov	ax,es:[3]
	mov	dx,si
	call	hex2asc
	add	si,8
	pop	cx
	cmp	cx, 3
	jb	mtnext
	lea	si,mtbuff
	call	msgout
	push	es
	push	cs
	pop	es
	lea	di,mtbuff
	mov	cx,78/2
	mov	ax,2020h
	cld
	rep	stosw
	pop	es
	mov	cx, -1
	lea	si, mtbuff

mtnext	label	near
	cmp	byte ptr es:[0],'M'
	jne	mtdone
	mov	ax,es
	inc	ax
	add	ax,word ptr es:[3]
	mov	es,ax
	inc	cx
	jmp	mtloop

mtdone	label	near
	cmp	cx, -1
	jz	mtskip
	lea	si,mtbuff
	call	msgout
	push	cs
	pop	es
	lea	di,mtbuff
	mov	cx,78/2
	mov	ax,2020h
	cld
	rep	stosw

mtskip	label	near

	pop	es
	pop	ds
	pop	di
	pop	si
	ret
mbtrace endp
endif

	subttl	regdump - do a register display
	page
;-----------------------------------------------------------------------
; this subroutine will display a register dump similar to that of the
; ms-dos debug program.
;
;  on entry:
;	sp+12-> return address of original call to mosdebug
;	sp+10-> ax
;	sp+8 -> ds
;	sp+6 -> dx
;	sp+4 -> junk
;	sp+2 -> si
;	sp+0 -> junk (return address)
;
;  on exit:
;	nothing
;
;	no global data affected
;	no global procedures called
;	no registers are changed
;-----------------------------------------------------------------------
regdump proc	near
	assume	ds:nothing, es:nothing

	test	al,10h			; use task registers?
	jz	$+5
	jmp	regtask 		; yes

	mov	[saveax],ax
	mov	ax,sp
	xchg	ax,bp
	push	[bp+10] 		; ax
	push	bx			; bx
	push	cx			; cx
	xchg	ax,bp
	mov	bx,bp			; starting sp value
	mov	bp,ax			; address stack data
	push	[bp+6]			; dx
	sub	ax,10			; calc original sp value
	push	ax			; sp
	push	bx			; bp
	push	[bp+2]			; si
	push	di			; di
	push	[bp+8]			; ds
	push	es			; es
	push	ss			; ss
	push	cs			; cs (this only called in mos segment)
	push	[bp+4]			; ip

	push	ds			; save for sub
	push	dx			; "     "
	push	cs
	pop	ds
	assume	ds:mos
	lea	si,regdata		; start here
	mov	cx,13			; do 13 registers
	sub	bp,2			; point to ax register 1st
reglp:
	mov	ax,[bp] 		; get next register value
	mov	dx,si
	call	hex2asc
	add	si,9			; length of each register entry
	sub	bp,2			; next value
	loop	reglp
	call	doflags 		; set flag values in display message
	lea	si,regmsg		; now display info
	call	msgout

	pop	dx
	pop	ds			; entry ds back
	assume	ds:nothing
	pop	ax			; clear ip
	pop	ax			; clear cs
	pop	ax			; clear ss
	pop	es			; es
	pop	ax			; clear ds
	pop	di			; di
	pop	ax			; clear si
	pop	bp			; bp
	pop	ax			; clear sp
	pop	ax			; clear dx
	pop	cx			; cx
	pop	bx			; bx
	pop	ax			; clear ax
	mov	ax,[saveax]
	ret

regtask:
	push	ax
	push	[tax]			; ax
	mov	ax,sp			; get starting pointer
	push	[tbx]			; bx
	push	[tcx]			; cx
	push	[tdx]			; dx
	push	[tsp]			; sp
	push	[tbp]			; bp
	push	[tsi]			; si
	push	[tdi]			; di
	push	[tds]			; ds
	push	[tes]			; es
	push	[tss]			; ss
	push	[tcs]			; cs
	push	[tip]			; ip

	push	ds			; save for sub
	push	dx			; "     "
	push	cs
	pop	ds
	assume	ds:mos
	lea	si,regdata		; start here
	mov	cx,13			; do 13 registers
	push	di
	mov	di,ax			; stack register pointer
reglpt:
	mov	ax,ss:[di]		; get next register value
	mov	dx,si			; put register ascii value here
	call	hex2asc
	add	si,9			; length of each register entry
	sub	di,2			; next value
	loop	reglpt
	pop	di
	push	[regflg]
	mov	ax,[tflag]
	mov	[regflg],ax
	call	doflags 		; set flag values in display message
	pop	[regflg]
	lea	si,regmsg		; now display info
	call	msgout

if	fcbdump
	cmp	[tah],28h		; dump fcb?
	jne	rd10			; if we don't care about the FCB
	mov	dx,[tdx]
	mov	ds,[tds]		; print the fcb at ds:dx
	call	dumpfcb
rd10:
endif

	pop	dx
	pop	ds			; entry ds back
	assume	ds:nothing
	mov	ax,sp
	add	ax,13*2 		; 13 registers on stack
	mov	sp,ax			; clear data from stack
	pop	ax			; entry ax back

	ret

regdump endp

	subttl	doflags - set up string of flag names
	page
;-----------------------------------------------------------------------
; build the string of flag settings for display.
;
;  on entry:
;	ds -> mos
;	'regflg' = flags to process
;
;  on exit:
;	the flags are ascii formated in the 'regf' data area
;
;	no global data affected
;	no global procedures called
;	no registers are changed
;-----------------------------------------------------------------------
doflags proc	near

	assume	ds:mos, es:nothing
	push	ax
	push	bx
	push	cx
	push	es
	push	si
	push	di

	push	cs
	pop	es
	assume	es:nothing

	lea	si,flagdat
	lea	di,regf
	lea	bx,flgtst		; list of flag test values
	mov	ax,[regflg]		; get callers flags
flglp:
	push	si			; save flag pointer
	cmp	word ptr [bx],0 	; end of list?
	je	dofend			; yes
	test	ax,[bx] 		; test for set flag
	jnz	flgset
	add	si,3			; point to not set string
flgset:
	mov	cx,3
	rep	movsb
	pop	si
	add	si,6			; point to next set of strings
	add	bx,2			; point to next flag test value
	jmp	flglp
dofend:
	pop	si			; clear from loop section
	pop	di
	pop	si
	pop	es
	pop	cx
	pop	bx
	pop	ax
	ret

doflags endp

if	fcbdump
	subttl	dumpfcb - print out contents of an fcb
	page
;-----------------------------------------------------------------------
; prints out the 64 bytes pointed to by ds:dx on entry.  prints the
; address, two spaces, 8 bytes of stuff, a dash, 8 more bytes of stuff,
; a tab, then the ascii values of the 16 bytes, if they are are in the
; range 20h -- 7eh.
;
;  on entry:
;	ds:dx points to the fcb to print
;
;  on exit:
;
;	no global data affected
;	no global procedures called
;	only flags register changed
;-----------------------------------------------------------------------
dumpfcb proc	near
	push	si
	push	ds
	push	dx
	push	ds
	push	cs
	pop	ds			; temporarily switch to our ds
	lea	si,msgcr
	call	msgout			; print initial cr lf
	pop	ds			; back to fcb ds

	call	dump16
	add	dx,16
	call	dump16
	add	dx,16
	call	dump16
	add	dx,16
	call	dump16
	pop	dx
	pop	ds
	pop	si
	ret
dumpfcb endp

	subttl	dump16 - dump out 16 bytes of memory
	page
;-----------------------------------------------------------------------
; prints out the 64 bytes pointed to by ds:dx on entry.  prints the
; address, two spaces, 8 bytes of stuff, a dash, 8 more bytes of stuff,
; a tab, then the ascii values of the 16 bytes, if they are are in the
; range 20h -- 7eh.
;
;  on entry:
;	ds:dx points to the fcb to print
;
;  on exit:
;
;	no global data affected
;	no global procedures called
;	only flags register changed
;-----------------------------------------------------------------------
dump16	proc	near
	push	ds
	push	es
	push	si
	push	dx
	push	bx
	push	ax
	mov	bx,dx
	mov	ax,ds
	mov	es,ax			; fcb lives in es now
	push	cs
	pop	ds			; ds now points to our strings
	lea	dx,msgaddr
	call	hex2asc 		; print out segment
	mov	ax,bx
	lea	dx,msgaddr+5		; convert offset
	call	hex2asc

	mov	cx,16
	lea	dx,msgdta		; where the numeric version goes
	lea	si,msgadta		; where the ascii version goes
dmp10:
	mov	al,es:[bx]		; get next byte
	call	byte2asc		; do numeric version
	mov	ah,'.'			; what to print if can't print byte as is
	cmp	al,20h			; printable?
	jb	dmp20
	cmp	al,7eh
	ja	dmp20
	cmp	al,'$'			; can't print these out
	je	dmp20
	mov	ah,al			; we can print the byte as is
dmp20:
	mov	[si],ah 		; store the printable version of it
	inc	bx			; next byte
	add	dx,3			; next print location for numerals
	inc	si			; next print location for ascii
	loop	dmp10

	lea	si,msgaddr
	call	msgout			; send the message

	pop	ax
	pop	bx
	pop	dx
	pop	si
	pop	es
	pop	ds
	ret
dump16	endp

endif

	subttl	askabig - ask for abort or ignore
	page
;-----------------------------------------------------------------------
; prompt user with 'Abort or Ignore?' and return cf=1 if abort selected
;
;  on entry:
;	nothing
;
;  on exit:
;	cf=1 if abort selected or cf=0 if ignore selected.
;
;	no global data affected
;	no global procedures called
;	only flags register changed
;-----------------------------------------------------------------------
askabig proc	near

	push	ax
	push	ds
	push	cs
	pop	ds
	assume	ds:mos, es:nothing
	lea	si,msgabig		; print 'Abort or Ignore' message
	call	msgout
reinput:
	call	dbgchar 		; get character from debug terminal
	and	al,0dfh 		; uppercase
	cmp	al,'A'
	je	carryon
	cmp	al,'I'
	je	carryoff
	jmp	reinput 		; only accept a or i
carryon:
	lea	si,msgabrt		; display abort for informational purposes
	call	msgout
	stc
	jmp	aiexit
carryoff:
	lea	si,msgignr		; display abort for informational purposes
	call	msgout
	clc
aiexit:
	pop	ds
	pop	ax
	ret

askabig endp

	subttl	askkey - ask for keypress
	page
;-----------------------------------------------------------------------
; wait for key press, return in al.
;
;  on entry:
;	nothing
;
;  on exit:
;	al = ascii of key pressed
;	 note: if main console is input device the extended keys are
;		not accepted.
;
;	no global data affected
;	no global procedures called
;	al returns value, no other registers are changed
;-----------------------------------------------------------------------
askkey	proc	near

	push	ds
	push	cs
	pop	ds
	assume	ds:mos, es:nothing
	call	dbgchar 		; get character from debug terminal
	pop	ds
	ret

askkey	endp

	subttl	msgout - output message to dbport device
	page
;-----------------------------------------------------------------------
; this routine will output a message to the port, screen, or device
; specified by the config command dbport.
;
;  on entry:
;	ds:si -> string to output (terminated by a '$')
;
;  on exit:
;	nothing
;
;	no global data affected
;	no global procedures called
;	no registers are changed
;-----------------------------------------------------------------------
msgout	proc	near

	assume	ds:nothing, es:nothing
	push	ax
	push	dx
	push	ds			; save msg pointer
	mgetscb ds
	assume	ds:grp
	mov	ax,[scbdbprt]		; get port to display to (or screen)
	cmp	ax,[scbvidad]		; should we use the default display?
	pop	ds			; callers pointer back
	assume	ds:nothing
	jne	ckother 		; check for alternate display device
conout:
	lodsb
	cmp	al,'$'
	je	msgend
	mov	bx,7
	mov	ah,14
	int	10h			; display to standard device
	jmp	conout
msgend:
	pop	dx
	pop	ax
	ret
ckother:
					; check for alternate screen here

	cmp	ax,4			; check for lpt device
	ja	nxtdev			; no, check for other devices
	call	doprn			; display to printer
	jmp	msgend
nxtdev:
	call	doport			; display to serial port
	jmp	msgend

msgout	endp

	subttl	doport - display to serial port
	page
;-----------------------------------------------------------------------
; output message at ds:si ending in '$' to serial port in ax.
;
;  on entry:
;	ax = serial port address
;	ds:si -> string to output (terminated by a '$')
;
;  on exit:
;	nothing
;
;	no global data affected
;	no global procedures called
;	ax and dx registers are changed
;-----------------------------------------------------------------------
doport	proc	near
	assume	ds:nothing, es:nothing

	push	si
	mov	dx,ax			; get port address
	cld
chkxoff:
	add	dx,5			; lsr
	in	al,dx
	sub	dx,5			; tx & rx
	test	al,1			; data ready?
	jnz	chkx2			; yes
	xor	al,al			; flag no char read for 'dbtchar'
	jmp	chkx3
chkx2:
	in	al,dx			; read port
	and	al,7fh
	cmp	al,13h			; check for xoff (ctrl-s)
	je	chkx2			; loop until something else is there
chkx3:
	mov	[lstread],al		; save for 'dbtchar'
dopstr:
	lodsb				; get char to write
	cmp	al,'$'			; end of string?
	jne	$+5
	jmp	dopend
	push	ax			; save char to write
	add	dx,5			; lsr
waittx:
	in	al,dx
	test	al,20h			; check for transmitter empty
	jz	waittx
	sub	dx,5
	pop	ax			; char to write
	out	dx,al			; send it to the port
	jmp	dopstr			; back to top of loop
dopend:
	pop	si
	ret

doport	endp

	subttl	doprn - display to lpt device
	page
;-----------------------------------------------------------------------
; output message at ds:si ending in '$' to lpt # in ax
;
;  on entry:
;	ax = lpt number (1 - 4)
;	ds:si -> string to output (terminated by a '$')
;
;  on exit:
;	nothing
;
;	no global data affected
;	no global procedures called
;	ax and dx registers are changed
;-----------------------------------------------------------------------
doprn	proc	near

	assume	ds:nothing, es:nothing
	push	si
	mov	dx,ax			; set lpt number
	dec	dx			; make 0 relative
	cld
dolpt:
	lodsb				; get char to write
	cmp	al,'$'			; end of string?
	jne	$+5
	jmp	dolend
	push	ax			; save char to write

waitrdy:
	mov	ah,2			; get printer status
	int	17h			; bios printer i/o
	test	ah,80h			; check for busy
	jz	waitrdy 		; wait til not busy
	pop	ax			; char to write
	mov	ah,0			; print char in al
	int	17h
	jmp	dolpt			; back to top of loop
dolend:
	pop	si
	ret

doprn	endp

	subttl	dbgchar - debug get character
	page
;-----------------------------------------------------------------------
; get character from input device (debug terminal or console) return
; in al.  if device is a printer device then an 'I' or ignore is
; returned.
;
;  on entry:
;	nothing
;
;  on exit:
;	al = ascii character input from device
;
;	no global data affected
;	no global procedures called
;	what registers are changed
;-----------------------------------------------------------------------
dbgchar proc	near

	assume	ds:nothing, es:nothing
	push	dx
	push	ds			; save msg pointer
	mgetscb ds
	assume	ds:grp
	mov	ax,[scbdbprt]		; get port to display to (or screen)
	pop	ds			; callers pointer back
	cmp	ax,0b000h		; use console?
	je	getcon			; yes
	cmp	ax,0b800h		; use console?
	je	getcon			; yes
	jmp	getother
getcon:
	xor	ah,ah
	int	16h			; get key press
	or	al,al			; extended?
	jz	getcon			; yes, do not accept extended, ask again
gcharend:
	pop	dx
	ret

getother:
	cmp	ax,4			; is this an lpt device?
	ja	getport 		; no, get from serial port
	mov	al,'I'			; respond default for lpt
	jmp	gcharend

getport:
	mov	dx,ax			; port address
	in	al,dx			; clear any current char
	add	dx,5			; point to lsr
waitkey:
	in	al,dx
	test	al,1			; check data ready
	jz	waitkey
	sub	dx,5			; point back to tx
	in	al,dx			; get char
	jmp	gcharend		; exit routine

dbgchar endp

	subttl	dbtchar - debug test for character
	page
;-----------------------------------------------------------------------
; test for character from input device (debug terminal or console)
; return in al (0 if none).  if device is a printer device then an 'I'
; or ignore is returned.
;
;  on entry:
;	nothing
;
;  on exit:
;	al = ascii character input from device (0 if no char)
;
;	no global data affected
;	no global procedures called
;	what registers are changed
;-----------------------------------------------------------------------
dbtchar proc	near

	push	ds
	assume	ds:nothing, es:nothing
	push	dx
	mgetscb ds
	assume	ds:grp
	mov	ax,[scbdbprt]		; get port to display to (or screen)
	push	cs
	pop	ds			; callers pointer back
	assume	ds:mos
	cmp	ax,0b000h		; use console?
	je	tstcon			; yes
	cmp	ax,0b800h		; use console?
	je	tstcon			; yes
	jmp	tstother
tstcon:
	mov	ah,1
	int	16h			; check for key
	jnz	tstcon2 		; yes, key available
	xor	al,al			; return no char available code
	jmp	tcharend
tstcon2:
	xor	ah,ah
	int	16h			; clear key
	or	al,al			; extended?
	jz	tstcon			; yes, do not accept extended, ask again
	jmp	tcharend

tstother:
	cmp	ax,4			; is this an lpt device?
	ja	tstport 		; no, get from serial port
	mov	al,'I'			; respond default for lpt
	jmp	tcharend

tstport:
	mov	dx,ax			; port address
	add	dx,5			; point to lsr
	in	al,dx
	test	al,1			; check data ready
	jnz	tstport2		; yes
	mov	al,[lstread]		; return last read one if any
	jmp	tcharend		; end
tstport2:
	sub	dx,5			; point back to tx
	in	al,dx			; get char
tcharend:
	pop	dx
	pop	ds
	ret

dbtchar endp

	subttl	mossimck - check for sim hotkey
	page
;-----------------------------------------------------------------------
; this routine will check for the sim hotkey and if found envoke the
; sim menu.
;
;  on entry:
;	nothing
;
;  on exit:
;	nothing
;
;	global data affected: scbdebug
;	no global procedures called
;	no registers are changed
;-----------------------------------------------------------------------
mossimck proc	near
	assume	ds:nothing, es:nothing

	push	ax
	call	dbtchar 		; check for any pressed key
	or	al,al
	jnz	$+5
	jmp	mossime

	cmp	al,[simhk]		; is this a sim request?
	je	$+5			; yes
	jmp	mossime 		; no, exit
	pop	ax

					; display menu and get any input
mossim: 				; entry from mosint21
	push	ax
	push	ds
	push	cs
	pop	ds
	assume	ds:mos
mossim0:
	call	dosimm			; display menu
mossim1:
	call	dbgchar 		; get users input
	cmp	al,13
	je	mossimx 		; exit
	cmp	al,'7'			; interupt 38 processing
	je	mossim38
	cmp	al,'8'			; ***** heap checking
	je	mossimh
	cmp	al,'9'			; ***** mcb checking
	je	mossimm
	cmp	al,'1'			; validate range
	jb	mossim1 		; not in range
	cmp	al,'6'
	ja	mossim1 		; not in range
	mov	cl,al
	sub	cl,'0'			; ascii to binary
	mov	ax,1
	shl	ax,cl			; set desired bit
	push	es
	mgetscb es
	assume	es:grp
	xor	[scbdebug],ax
	pop	es
	jmp	mossim0
mossim38:
	xor	[int38p], 1		; toggle interupt 38 processing
	jmp	mossim0
mossimh:
	xor	[smpchk], 1		; ***** toggle heap checking
	jmp	mossim0
mossimm:
	xor	[mcbchk], 1		; ***** toggle mcb checking
	jmp	mossim0
mossimx:
	lea	si,simcr		; cr, lf
	call	msgout
	pop	ds
mossime:
	pop	ax
	ret

mossimck endp

	subttl	dosimm - display sim menu
	page
;-----------------------------------------------------------------------
; display the sim menu and the current values.
;
;  on entry:
;	ds -> mos
;
;  on exit:
;	nothing
;
;	no global data affected
;	no global procedures called
;	no registers are changed
;-----------------------------------------------------------------------
dosimm	proc	near

	assume	ds:mos, es:nothing
	push	ax
	push	si
	push	es
	mgetscb es
	assume	es:grp

	lea	si,simmen		; menu header
	call	msgout
	mov	ax,2			; fun 0-c bit
	call	dispset 		; display on/off

	lea	si,simm2
	call	msgout
	mov	ax,4			; fun d-30 bit
	call	dispset

	lea	si,simm3
	call	msgout
	mov	ax,8			; fun 31+ bit
	call	dispset

	lea	si,simm4
	call	msgout
	mov	ax,10h			; pause on entry bit
	call	dispset

	lea	si,simm5
	call	msgout
	mov	ax,20h			; pause on exit bit
	call	dispset

	lea	si,simm6
	call	msgout
	mov	ax,40h			; internal int 21s bit
	call	dispset

	lea	si,simm7
	call	msgout
	lea	si,simon
	test	[int38p], 1		; interupt 38 processing
	jnz	dosim38
	lea	si,simoff
dosim38:
	call	msgout

	lea	si,simm8		; ***** heap checking
	call	msgout
	lea	si,simon
	test	[smpchk], 1		; ***** heap check on or off
	jnz	dosimhp
	lea	si,simoff
dosimhp:
	call	msgout

	lea	si,simm9		; ***** mcb checking
	call	msgout
	lea	si,simon
	test	[mcbchk], 1		; mcb checking on or off
	jnz	dosimmcb
	lea	si,simoff
dosimmcb:
	call	msgout

	lea	si,simmp		; prompt
	call	msgout
	pop	es
	pop	si
	pop	ax
	ret				; end dosimm

dispset proc	near
	lea	si,simon
	test	[scbdebug],ax		; is bit on?
	jnz	dsp1
	lea	si,simoff
dsp1:
	call	msgout			; display at end of last line
	ret
dispset endp

dosimm	endp

endif


	subttl	hex2asc - hex 2 ascii conversion
	page
;-----------------------------------------------------------------------
; hex to ascii convertion routine.
;
;  on entry:
;	ax = 16-bit binary value
;	ds:dx -> 4 byte area to store ascii result
;
;  on exit:
;	ds:dx -> ascii string
;
;	no global data affected
;	no global procedures called
;	no registers are changed
;-----------------------------------------------------------------------
hextbl	db	'0123456789ABCDEF'

	assume	ds:nothing, es:nothing, ss:nothing
hex2asc proc	near

	push	ax
	push	bx
	push	cx
	push	dx
	push	si
	pushf

	mov	si,dx
	mov	cl,4
	lea	bx,hextbl
	mov	ch,al			; save lsbyte
	call	hexcal
	mov	ah,ch			; do lsbyte
	call	hexcal

	popf
	pop	si
	pop	dx
	pop	cx
	pop	bx
	pop	ax
	ret
hexcal:
	xor	al,al
	shr	ax,cl
	shr	al,cl
	xlat	hextbl
	xchg	al,ah
	xlat	hextbl
	mov	[si],ax
	add	si,2
	ret

hex2asc endp

if	mdebug eq 1

if	fcbdump
	subttl	byte2asc - byte 2 ascii conversion
	page
;-----------------------------------------------------------------------
; hex to ascii conversion routine.
;
;  on entry:
;	al = 8-bit binary value
;	ds:dx -> 2 byte area to store ascii result
;
;  on exit:
;	ds:dx -> ascii string
;
;	no global data affected
;	no global procedures called
;	no registers are changed
;-----------------------------------------------------------------------

	assume	ds:nothing, es:nothing, ss:nothing
byte2asc	proc	near

	push	ax
	push	bx
	push	cx
	push	dx
	push	si
	pushf

	mov	si,dx
	mov	cl,4
	lea	bx,hextbl
	mov	ah,al			; print lsbyte
	call	hexcal

	popf
	pop	si
	pop	dx
	pop	cx
	pop	bx
	pop	ax
	ret
byte2asc	endp

endif

	subttl	dec2asc - decimal 2 ascii conversion
	page
;-----------------------------------------------------------------------
; decimal to ascii convertion routine.
; buffer must be 5 bytes long as it is cleared to blanks.
;
;  on entry:
;	ax = 16-bit value
;	ds:dx -> 5 byte area to store ascii string result
;
;  on exit:
;	ds:dx -> ascii string
;
;	no global data affected
;	no global procedures called
;	no registers are changed
;-----------------------------------------------------------------------
dec10	dw	10			; constant

	assume	ds:nothing, es:nothing, ss:nothing
dec2asc proc	near

	push	ax
	push	dx
	push	si
	mov	si,dx
	mov	byte ptr [si],' '	; clear buffer
	mov	word ptr [si+1],'  '	; "     "
	mov	word ptr [si+3],'  '	; "     "
	pushf
	add	si,4			; point to end of buffer
dec2lp:
	xor	dx,dx
	div	[dec10] 		; isolate next digit
	add	dl,'0'			; convert to ascii
	mov	[si],dl 		; store in buffer
	dec	si			; next digit position
	or	ax,ax			; is that all?
	jnz	dec2lp			; no
	popf
	pop	si
	pop	dx
	pop	ax
	ret

dec2asc endp

;-----------------------------------------------------------------------
mosdebug endp

endif

mosseg	ends
	end

