	include page.inc
	title	mosint17 - bios keyboard software interrupt
comment ^==============================================================
			development specification
 program name:	$$mos.sys		assigned to: martin stitt
 module name:	mosint17		assign date:
 entry points:	mosint17		completed:
 entry method:	int 17h

 purpose:	perform printer output and manage spooling
 last update:	08/18/1992
========================================================================

mjs 03/23/87	add function 03 for string printing.  add support for
		serial printers

sah 07/20/87	change clospoll to make sure it never sets a non-zero
		timer value or it will skip the close (observed because
		of disapearing terminal - vidram)

sah/jrb 08/04/87 corrected int 17h logics so that is waits up to
		a maximum of a clock cycle before it test for
		printer status after printer output

sah 08/06/87	modified printer logic so that is works from a
		terminal printer even when spooling is active

mjs 10/15/87	modified the procedure setsplfl to only call timparm
		if the low word of the timer has changed since the last
		call	to setsplfl. modified serial port status checking
		to use bit 80h of ah after an int14 call rather than
		specifically decode the modem bits. modify return status
		when a serial port is found to be busy.  at the entry
		to mosint17, just before the call to mossaver, set the
		flag tcbfsavr in order to make a quick pass through
		mossaver.  re-organized the logic of the serial printing
		segment in order to optimize performance and solve
		problems with critical error handling. (from d.c. trip)

sah 02/11/88	correct int 17 not returning al correctly (multimate)
		and timeout value in ah should be 11h instead 01h

rdg 07/06/88	gated access to the console device drivers to prevent
		corruption of the serial data stream being sent to a
		terminal by changing the calls to the console device
		driver from a call dword ptr [si] to call ddtcallf

sjc 08/15/88	added do21h for re-entrant mos calls.
		replaces domos macro.  this change, with ddtmc change,
		allows lanlink to spool across network.

sah 09/27/88	use suspend2 calls instead suspend calls which allow
		tsl to be re-enter.

sah 09/28/88	change serial printing logic on that if printer returns
		error pointer return to caller is not decremented.

rkg 02/13/88	change spooling to different spool file per printer
		and pass-through printing.  func ff closes spool files.

mjs 03/03/89	added error handling after the calls to the ddt printing
		functions.

sah 08/22/89	corrections for spooling across novell, must use int 21
		get and set psp calls, so novell can propertly handle
		psp's.

sah 08/23/89	corrected routing from lpt to com above com1, port was
		not being set!

mjs 09/01/89	corrected two problems with printing when redirection
		to a com port is being used.  single character printing
		with int17fun00 would not work at all (wrong type of
		jump used).  int7fun03 printing would fail when the
		serial driver's buffer filled up (wrong type of status
		test).

mjs 09/08/89	modified the error handling logic for print spooling to
		not  do a bugerror.  scbcin24 is called to pop up a
		critical error type window instead.

bwr 11/29/89	corrected route problem and marked messages for
		foreign language translation.

sah 02/20/90	made i17prtbit public for mosint38

bwr 04/09/90	spooler now accepts timeout values up to 3600 seconds.
		(60 minutes).  due to math error in routine "clospoll"
		a signed value was being tested instead of an unsigned
		causing problems for timeouts of 1800 and greater. (the
		signed test was causing many little spool files to be
		created instead of just one.)

bwr 06/06/90	corrected problem with incorrect status being returned
cbk		for status check on printer when redirected through
		terminal or com device.

mjs 02/21/91	added logic to defer a spool file close during an int15
		disk busy task switch.

mjs 03/11/91	added logic to prevent a disk busy task switch when
		splclose does file i/o.  this prevents a stall when
		mos vmo vga/ega and dbts and spool and pamswitching
		are used.

bwr 03/14/91	modified to take advantage of new printer status function
		available in the terminal driver.  (at present only the
		sherwood version of this driver, swterm.sys actually
		returns a printer status).  prior to this, mosint17 returned
		an ok printer status by default because none was available.
		this turned out to be somewhat dangerous for some of our
		clients who need to know if the remote printer chokes!

bwr 04/11/91	1) subroutine reserve_lpt_port has been corrected to
		   properly pick up the tcbhold value from the tcb.
		   up to now it has not indexed this value, but picked
		   up the hold value from the 0 offset of that variable
		   all the time.

		2) added logic to enforce the new mos hold comxx command
		   with which a user can reserve a com port in the
		   same way he would an lpt port.

		3) rewrote routine i17com and i17coms to more correctly
		   handle modem handshaking coming from the com port
		   when an lpt port is redirected there.  this code is
		   now the same code as found in mosdevs.  the next stage
		   of this change will be to put a common version of
		   the serial read routine where both mosdevs and mosint17
		   can use it.

bwr 04/17/91	reserve_com_port is now public so mosdevs can call it
		when enforcing mos hold to com ports.

mjs 05/24/91	reworked printer status logic for the remote case.
		cleaned up module.

mjs 10/07/91	fix dbts/prtsc/spool bugs (patch410.118).
		changed splclose to use the scbi15off flag to temporarily
		disable dbts rather than manipulate the scbi15tsl flag.

================ 5.01 Kernel Ends Here ====================================

mjs 08/18/92	clean up segment declarations

=========================================================================^

.xlist
	include mosint17.pub
	include group.inc
	include options.inc
	include macros.inc
	include mosregs.inc

tcb	segment at 1234h
	include mostcb.inc
tcb	ends

gdata	segment
	include mosscbex.inc
gdata	ends
.list

polltim equ	110
remtim equ	18

irq	segment

	dw	17h*4			; offset for this interrupt
i17old	dd	?			; save prior value
i17sav	dw	0			; don't save changes, leave them alone
i17new	dw	mos:mosint17		; initial value is here
i17new2 dw	0			; don't change back if app it

irq	ends

poll	segment
	extrn	pollstart:byte, pollend:byte

	dw	clospoll
	dw	0
sptimr	dw	tcbspltp

poll	ends

spldseg segment at 55aah
	include moxspldt.inc		; data structure of spooler storage
spldseg ends

splbuff segment at 7777
splb	spooldat <>			; define seg for a single spool file
splbuff ends

bios	segment at 40h
	org	8h
bioslpts dw	4 dup (?)		; printer port table in bios
	org	6ch
biostick dw	?			; bios area timer tick counter
bios	ends

;======================================================== mos segment
if 0 eq 0
segment_num = 1
endif
mosseg	segment

	extrn	mossaver:near,mosrestore:near,suspend2:near
	extrn	timparm:near,timchk:near,tsl:near,getkeys:near
	extrn	ddtcallf:near		; console device driver gating
	extrn	bugerror:near

	public	mosint17, closspls, i17prtbit, wordten
	public	reserve_com_port, determine_route

	assume	cs:mos,ds:nothing,es:nothing,ss:nothing

i17prtbit db	1,2,4			; printer bit lookup table

; printer type definitions

i17_nul equ	-1			; unknown or ignore
i17_lpt equ	0			; printing to parallel port
i17_spl equ	1			; spooling to disk
i17_com equ	2			; printing to serial port
i17_rem equ	3			; printing to terminal printer

; list of routines to execute dependent on function

i17funcs dw	i17close		; func ffh close spool file
	 dw	i17print		; func 00h output char to printer
	 dw	i17init			; func 01h reset/initialize printer
	 dw	i17stat			; func 02h return printer status
	 dw	i17prtstr		; func 03h print string

prtcvect dw	i17lpt,i17spl,i17com,i17remc  ; print character vects
prtsvect dw	i17lpts,i17spls,i17coms,i17rems  ; print string vectors
initvect dw	initlpt,initspl,initcom,initrem  ; printer initialize
statvect dw	statlpt,statspl,statcom,statrem  ; printer status vects

ok_stat 	equ	90h		;normal printer status.
err_stat	equ	11h		;i/o error | timeout.
inv_stat	equ	0ffh		;invalid port status.
reserved	equ	13h		;port in use by another task.

lptsetl equ	4000			; loop counter lpt init settle value
comsetl equ	50			; loop counter com port settle time

wordten dw	10			; constant
splmsg1 db	'Spool Error$        ',00h  ;@@xlat

	subttl mosint17
	page
;======================================================================
;,fs
; mosint17
;
; in:
;
; out:
;
;,fe
;=====================================================================
	assume	ds:nothing, es:nothing, ss:nothing
mosint17 proc near
	push	es
	mgetscb es			; address scb with es
	assume	es:grp
	mov	es,[scbtcbpc]		; get the tcb
	assume	es:tcb
	mov	[tcbfsavr],'Y'		; tell mossaver to use short save.
	pop	es
	call	mossaver
	assume	ds:grp,es:nothing,ss:tcb

IF BIAS
	push	[tcbstkp]
	sub	[tcbstkp],bias
ENDIF

	mov	[tcbfsavr],'N'		; reset short form flag for mossaver
	mov	[tcbkbcnt],0		; reset keyboard looping counter

; check to see that the port # is valid. (0-2)

	cmp	[tdx],2
	ja	i17_invalid
	mov	bx,[tdx]

; check for any routing.

	call	determine_route
	assume	es:splbuff
	or	di,di			; invalid printer?
	js	i17_exit		; if so, get out immediately.

; check the function dispatch.	valid function call?

	mov	ax,[tax]
	inc	ah			; adjust for ff function.
	cmp	ah,4			; function in range?
	ja	i17_invalid
	mov	si,bx			; hold printer # in si for a sec.
	xor	bh,bh			; compute dispatch to functions.
	mov	bl,ah
	shl	bx,1
	xchg	bx,si			; get printer # back from si.
	call	i17funcs[si]		; call the selected function.
	jmp	short i17_exit

i17_invalid:
	mov	ah,inv_stat
i17_exit:
	mov	[tah],ah		; don't destroy AL value (Multi-Mate)

IF BIAS
	pop	[tcbstkp]
ENDIF

	call	mosrestore
	iret
mosint17 endp

	subttl i17print - i17print print character in al to [dx] printer
	page
;======================================================================
;,fs
; i17print - i17print print character in al to [dx] printer
;
; in:	ah = function #
;	al = char
;	bx = logical printer number (used by reserve_lpt_port)
;	dx = printer physical port (if parallel printer)
;	di = device type (0 = printer, 1 = spool, 2 = com, 3 = remote)
;	ch = spool disposition
;	ds = spool data seg (if spooling)
;	es = bios (if parallel port)
;
; out:	ah = printer status
;
;,fe
;=====================================================================
	assume	ds:grp,es:splbuff,ss:tcb
i17print proc near
	add	di,di			; just call routine
	jmp	prtcvect[di]
i17print endp

	subttl i17init - initialize printer and return status
	page
;======================================================================
;,fs
; i17init - initialize printer and return status
;
; in:	ah = function #
;	al = char
;	bx = logical printer number (used by reserve_lpt_port)
;	dx = printer physical port (if parallel printer)
;	di = device type (0 = printer, 1 = spool, 2 = com, 3 = remote)
;	ch = spool disposition
;	ds = spool data seg (if spooling)
;	es = bios (if parallel port)
;
; out:	ah = printer status
;
;,fe
;=====================================================================
	assume	ds:grp,es:splbuff,ss:tcb
i17init proc near
	shl	di,1
	jmp	initvect[di]
i17init endp

	subttl i17stat - returns status of printing device
	page
;======================================================================
;,fs
; i17stat - returns status of printing device
;
; in:	ah = function #
;	al = char
;	bx = logical printer number (used by reserve_lpt_port)
;	dx = printer physical port (if parallel printer)
;	di = device type (0 = printer, 1 = spool, 2 = com, 3 = remote)
;	ch = spool disposition
;	ds = spool data seg (if spooling)
;	es = bios (if parallel port)
;
; out:	ah = printer status
;
;,fe
;=====================================================================
	assume	ds:grp,es:splbuff,ss:tcb
i17stat proc near
	add	di,di			; turn into dispatch index
	jmp	statvect[di]
i17stat endp

	subttl i17prtstr
	page
;======================================================================
;,fs
; i17prtstr
;
; in:	ah = function #
;	al = char
;	bx = logical printer number (used by reserve_lpt_port)
;	dx = printer physical port (if parallel printer)
;	di = device type (0 = printer, 1 = spool, 2 = com, 3 = remote)
;	ch = spool disposition
;	ds = spool data seg (if spooling)
;	es = bios (if parallel port)
;	cx = number of chars to print
;	si => string to print
;	*** function must load [tds] - string segment ***
;
; out:	ah = printer status
;	cx = number of chars printed
;
;,fe
;=====================================================================
	assume	ds:grp,es:splbuff,ss:tcb
i17prtstr proc near
	mov	cx,[tcx]		; number of chars
	mov	ah,ok_stat
	xor	si,si			; return value if no chars
	jcxz	i17sxit			; quick exit when no chars to print
	mov	si,[tsi]
	cld				; for lodsb
	add	di,di			; turn into dispatch index
	call	prtsvect[di]
	sub	si,[tsi]		; calc bytes output
	cmp	ah,ok_stat		; test any errors
	je	i17sxit
	dec	si			; error on last one so decr count
i17sxit:
	mov	[tcx],si
	ret
i17prtstr endp

	subttl determine_route
	page
;======================================================================
;,fs
; determine_route
;
; returns ultimate destination of int 17 printer
;
; in:	bx = printer number (0-2)
;
; out:	di = printer type number
;	 -1 - null
; 	  0 - parallel
;	  1 - spool
;	  2 - com
;	  3 - remote
;	bx updated if directed to different printer
;	cl = printer bit, ch = spooling disposition
;	ah = status if di = -1 (invalid device)
;	dx = printer port if parallel device
;	es = splbuff (if spooling) / = bios if parallel port
;
;,fe
;=====================================================================
	assume	ds:grp,es:nothing,ss:tcb
determine_route proc near
	mov	cl,i17prtbit[bx]
	mov	di,i17_rem		; device type = remote
	test	[tcbauxbt],cl
	jnz	ptrxit			; jmp if the remote bit is set

; test for spooling

	mov	ax,[tcbspool]		; get spool segment
	or	ax,ax
	jz	ptrnospl
	add	ax,spldoff		; get to first spool data seg
ptrsplsg:
	mov	es,ax			; into ds if spooling
	assume	es:splbuff
	test	cl,[splb.printer]	; test buffer for printer
	jz	ptrsplnxt

; verify spooling and redirect with dispostion

	mov	ch,[splb.filname+spldisp]  ; spooling get dispostion
	cmp	ch,'I'			; check for output ignore
	mov	di,i17_nul
	mov	ah,ok_stat		; give success status
	je	ptrxit
	cmp	ch,'N'			; check pass-through
	je	ptrnospl		; then no spooling
	mov	di,i17_spl		; di = print device = spool
	jmp	ptrxit			; exit with spooling mode
ptrsplnxt:
	add	ax,spldpars		; get to next buffer
	cmp	[splb.printer],0	; end of spool buffers?
	jnz	ptrsplsg

; test device routed to serial device

ptrnospl:
	mov	di,i17_com		; device type = serial
	mov	al,tcblptxl[bx]
	or	al,al
	jz	ptr_lpt
	dec	al			; printer translated to com or lpt
	mov	bx,ax			; update printer index and bit
	and	bx,7fh			; strip lpt/com bit
	mov	dx,bx			; bug correction for printer problem
	mov	cl,i17prtbit[bx]
	test	al,80h			; if high bit set, (lpt to lpt) case
	jz	ptrxit			; else (lpt to com) case

; verify parallel port exists

ptr_lpt:
	mov	di,i17_lpt		; device type = parallel printer
	mov	ax,bios
	mov	es,ax			; test valid printer
	assume	es:bios
	mov	ax,bx			; save printer number around test
	add	bx,bx
	mov	dx,bioslpts[bx]
	or	dx,dx			; test printer is attached
	mov	bx,ax
	assume	es:nothing
	jnz	ptrxit			; printer found

; printer not found in table doesn't exist

ptrinvld:
	mov	ah,inv_stat		; invalid printer return error status
	mov	di,i17_nul		; unknown printer
ptrxit:
	ret
determine_route endp

;,fs
;**********************************************************************
;******** parallel port functions
;**********************************************************************
;,fe

	subttl i17lpt - print char/string to parallel port
	page
;======================================================================
;,fs
; i17lpt - print char/string to parallel port
;
; in:
;
; out:
;
;,fe
;=====================================================================
	assume	ds:grp,es:splbuff,ss:tcb
i17lpt proc near
	call	reserve_lpt_port	; is printer held by another task
	jc	i17lerr
	mov	cx,1			; character count
	jmp	short i17lchar
i17lpt endp

	subttl i17lpts
	page
;======================================================================
;,fs
; i17lpts
;
; in:
;
; out:
;
;,fe
;=====================================================================
	assume	ds:grp,es:splbuff,ss:tcb
i17lpts proc near
	mov	es,[tds]
	call	reserve_lpt_port	; printer held by another task
i17llup:
	mov	al,es:[si]		; get first/next char of string
	inc	si
	jc	i17lerr			; error from reserve_lpt_port
i17lchar:
	mov	di,[scbtimer]		; test status for up to a cycle
i17ltest:				; sah/jrb 08/04/87
	out	dx,al			; output to port
	call	lptbusy
	jz	i17lprt			; printer ready
	cmp	di,[scbtimer]
	je	i17ltest		; loop until ready or tick
i17lbusy:
	mov	di,offset polllpt	; give poll routine
	call	i17wait			; to wait/timeout
	mov	ah,err_stat
	jz	i17lerr			; port timeout
	call	reserve_lpt_port	; reserve printer again
	jnc	i17lchar		; printer reserved/ensure prn ready
i17lerr:
	ret
i17lprt:
	mov	al,0dh
	add	dx,2
	out	dx,al			; raise the strobe line
	jnext
	jnext				; delay for peripheral device
	jnext
	mov	al,0ch
	out	dx,al			; lower the strobe line again
	jnext
	sub	dx,2			; revert to printer base port addr
	loop	i17llup			; loop for all chars
	mov	ah,ok_stat		; return good status since printed
	ret
i17lpts endp

	subttl initlpt
	page
;======================================================================
;,fs
; initlpt
;
; in:
;
; out:
;
;,fe
;=====================================================================
	assume	ds:grp,es:splbuff,ss:tcb
initlpt proc near
	call	reserve_lpt_port	; check access to printer
	jc	inithld
	add	dx,2			; add 2 for control port
	mov	al,8			; lower the init line
	out	dx,al
	mov	cx,lptsetl		; wait for initialize to effect
	loop	$
	mov	al,0ch			; raise the init line back up
	out	dx,al
	sub	dx,2
	mov	cx,lptsetl
	loop	$
	call	lptstatus		; and return status
inithld:
	ret
initlpt endp

	subttl statlpt
	page
;======================================================================
;,fs
; statlpt
;
; in:
;
; out:
;
;,fe
;=====================================================================
	assume	ds:grp,es:splbuff,ss:tcb
statlpt proc near
	call	reserve_lpt_port	; is printer held by another task
	jc	statlhld		; yes return with reserved error
	call	lptstatus
statlhld:
	ret
statlpt endp

	subttl lptbusy - returns zr if printer ready
	page
;======================================================================
;,fs
; lptbusy - returns zr if printer ready
;
; in:	dx = parallel printer port
;
; out:	zr/nz = printer error status
;
;,fe
;=====================================================================
	assume	ds:nothing,es:nothing,ss:tcb
lptbusy proc near
	push	ax
	call	lptstatus
	xor	ah,10010000b		; invert busy, select
	and	ah,10111000b		; check busy, paper, select, error
	pop	ax
	ret
lptbusy endp

	subttl lptstatus - returns parallel printer status
	page
;======================================================================
;,fs
; lptstatus - returns parallel printer status
;
; in:	dx = printer port
;
; out:	ah = printer status
;
;,fe
;=====================================================================
	assume	ds:nothing,es:nothing,ss:tcb
lptstatus proc near
	inc	dx			; get to status port
	in	al,dx			; read parallel status port
	mov	ah,al
	and	ah,0f8h			; mask off unused bits
	xor	ah,048h			; invert active low signals from port
	dec	dx
	ret
lptstatus endp

	subttl reserve_lpt_port
	page
;======================================================================
;,fs
; reserve_lpt_port
;
; this function attempts to reserve the selected printer port for
; exclusive use by this task for a set period of time. (as defined
; in the tcbhold variable).
;
; in: 	bx = index of parallel printer port. (0-2)
;	ss = reference to tcb segment.
;
; out:	cf set if port reserved by another task.
;	ax contains reserved status.
;	if cf clear, the reservation was honored and
;	output may proceed to the device.
;
;,fe
;=====================================================================
	assume	ds:nothing,es:nothing,ss:tcb
reserve_lpt_port proc near

; save needed registers.

	push	ax			;[bp+6]
	push	bx			;[bp+4]
	push	ds			;[bp+2]
	push	bp
	mov	bp,sp			;will need to get at index.

; load ds with pointer to scb so we can get at the printer reservation
; variables.

	mgetscb ds
	assume	ds:grp
	cli				;protect ourself.

; compute offset into printer reservation table. (see scb)

	mov	al,bl
	mov	ah,scbhldlen		; printer # * length of table entry.
	mul	ah
	mov	bx,ax

; is the printer already held hostage by this task?

	mov	ax,tcbid		;get the tcbid.
	cmp	scbhldtask[bx],-1	; no one holding it?
	je	lpt_hold_1
	cmp	scbhldtask[bx],ax
	je	lpt_hold_1

; the printer is not held by this task.  check and see if the task
; holding it has timed out.  (is the reservation timer < current timer?)

	mov	ax,scbhldtick[bx]
	sub	ax,scbtimer
	mov	ax,scbhldtock[bx]
	sbb	ax,scbtimerh
	jb	lpt_hold_1		; last reservation timed out

; another task still has the printer reserved.  exit with an error
; status.

	mov	ax,[bp+6]		;get original ax.
	mov	ah,reserved
	mov	[bp+6],ax		;return it to stack.
	stc
	jmp	short rlp_exit

; reserve the port for the specified time period.

lpt_hold_1:
	mov	scbhldtask[bx],ax	;place the tcbid in hold variable.
	push	bx			;let's fetch TCBHOLD.
	mov	bx,[bp+4]		;get printer index.
	shl	bx,1			;index a word table.
	mov	ax,tcbhold[bx]
	pop	bx

; if the hold request in the tcb is for 0 seconds then
; simply relinquish ownership of the port by this task.

	cmp	ax,0			;tcbhold == 0?
	jne	lpt_hold_2		;if not, let's go reserve it.
	mov	scbhldtask[bx],-1	;mark this port as unreserved.
	mov	scbhldtick[bx],0	;re-initialize the counter.
	mov	scbhldtock[bx],0
	jmp	short rlp_ok

;  reserve the port by getting the current scb timer and adding to
;  it the timeout value requested by the tcb.

lpt_hold_2:
	add	ax,scbtimer
	mov	scbhldtick[bx],ax
	mov	ax,scbtimerh
	adc	ax,0
	mov	scbhldtock[bx],ax

; done reserving.  return an ok status.

rlp_ok:
	mov	ax,[bp+6]		;get original ax.
	mov	ah,ok_stat
	mov	[bp+6],ax
	clc

; return to caller.

rlp_exit:
	sti				;interrupts back on.
	pop	bp
	pop	ds
	pop	bx
	pop	ax
	ret
reserve_lpt_port endp

	subttl i17wait - calls suspend
	page
;======================================================================
;,fs
; i17wait - calls suspend
;
; sets poll routine to check port
; then suspends until port readies or timesout.
;
; in:	cs:di -> poll routine
;
; out:	zr if timeout
;
;,fe
;=====================================================================
	assume	ds:nothing,es:nothing,ss:tcb
i17wait proc near
	push	ax
	push	cx
	push	es
	mov	[tcbprprt],dx		; give port to poll routine
i17w_loop:
	mov	ax,ss			; get tcb into es
	mov	es,ax
	mov	cl,2			; bit pos in tcbwtflg for wrap flag
	mov	ax,polltim		; # of ticks for 30 seconds
	call	timparm			; get timer time-out value
	mov	[tcbtoax],ax
	mov	[tcbtocx],cx		; save time out data for poll/timchk
	cli				; disable while changing vector
	mov	word ptr [tcbpoll],di
	mov	word ptr [tcbpoll+2],cs
	sti
	or	[tcbwait],1		; set waiting bit 0
	call	suspend2
	cmp	[tcbtocx],-1		; test timed out
	jne	i17w_ok
	mov	ax,1
	or	bx,bx			; LPT0?
	jz	i17w_cont
	mov	cl,bl
	shr	ax,cl	      		; mask correct port in
i17w_cont:	
	test	al,[tcbiretry]
	jnz	i17w_loop
i17w_ok:
	pop	es
	pop	cx
	pop	ax
	ret
i17wait endp

	subttl polllpt - tcb poll routine
	page
;======================================================================
;,fs
; polllpt - tcb poll routines
;
; awake task when device readies, or signal timeout
;
; in:	ss, es = tcb
;
; out:	al = 0 to end suspend
;
;,fe
;=====================================================================
	assume	ds:nothing,es:nothing,ss:tcb
polllpt proc far
	mov	dx,[tcbprprt]
	call	lptbusy			; check busy status
	jz	polldone
polltime:				; test time out
	push	cx
	mov	ax,[tcbtoax]		; check for time out
	mov	cx,[tcbtocx]
	call	timchk
	pop	cx
	jnz	pollcont
	mov	[tcbtocx],-1		; signal time out
polldone:				; finished waiting
	xor	al,al			; signal not busy
	or	[tcbwait],2
	retf
pollcont:
	mov	al,7
	retf
polllpt endp


;
; following procedure is use to check for infinete retry and if so
; call tsl so task will suspend for a while and then return so that
; the remaining of INT 17h logic continues
;

	assume  ss:tcb
InfRetry proc	near
	push	ax
	push	cx
	mov	ax,1
	or	bx,bx
	jz	InfRetryCont
	mov	cl,bl
	shr	ax,cl
InfRetryCont:
	test	al,[tcbiretry]
	jz	IRetryOut
	pushf
	mov	[tcbslcnt],0
	call	tsl
	popf
IRetryOut:
	pop	cx
	pop	ax
	ret
InfRetry endp

;,fs
;**********************************************************************
;******** spooling functions
;**********************************************************************
;,fe

	subttl i17spl - stores a character into the spool buffer
	page
;======================================================================
;,fs
; i17spl - stores a character into the spool buffer
;
; in:	al = character
;	es -> spool data segment
;
; out:
;
;,fe
;=====================================================================
	assume	ds:grp,es:splbuff,ss:tcb
i17spl proc near
	mov	bx,es			; move splbuff segment into ds
	mov	ds,bx
	assume	ds:splbuff
	mov	bx,[splb.buffpnt]
	mov	[bx],al			; write the char in the spool buffer
	call	splopen			; open file
	call	spltimer		; set flags to show timeout started
	inc	[splb.buffpnt]
splfini:
	cmp	[splb.buffpnt],buffer + size buffer
	mov	ah,ok_stat		; good status unless flush fails
	jb	splxit
	mov	bx,[splb.handle]
	call	splwrite		; write to file when buffer is full
splxit:
	ret				; return with status from
i17spl endp

	subttl i17spls
	page
;======================================================================
;,fs
; i17spls
;
; in:
;
; out:
;
;,fe
;=====================================================================
	assume	ds:grp,es:splbuff,ss:tcb
i17spls proc near
	mov	ax,es			; check if room for this string
	mov	ds,ax			; get buffer seg in ds
	assume	ds:splbuff
	call	splopen
	call	spltimer		; set flags to show timeout started
	mov	ax,buffer + size buffer
	sub	ax,[splb.buffpnt]
	mov	cx,[tcx]
	cmp	ax,cx			; ax = free, cx = string len
	jae	splsmov
	mov	bx,[splb.handle]
	call	splwrite		; flush spool buffer
	mov	cx,[tcx]		; regain length of string
splslup:				; move string to buffer
	cmp	cx,size buffer		; handle strings larger than buffer
	jbe	splsmov
	push	cx			; call move/flush while cx > buffer
	mov	cx,size buffer
	call	splsmov
	pop	cx
	sub	cx,size buffer		; subtract amnt written from tot size
	jmp	splslup
splsmov:
	push	ds
	mov	ax,ds
	mov	es,ax			; get destination to es:di
	mov	di,[splb.buffpnt]
	mov	ds,[tds]		; and source in ds:si
	rep	movsb
	pop	ds
	mov	[splb.buffpnt],di
	jmp	splfini			; flush if necessary and return
i17spls endp

	subttl splopen - opens the spool file if not already open
	page
;======================================================================
;,fs
; splopen - opens the spool file if not already open
;
; in:	ds = spooler data segment
;
; out:	cy if error on open
;	bx = spool file handle
;
;,fe
;=====================================================================
	assume	ds:splbuff,es:nothing,ss:tcb
splopen proc near
	push	si
	mov	bx,[splb.handle]	; get and test handle
	cmp	bx,-1
	clc
	jne	splz
	mov	[splb.buffpnt],buffer
	push	es
	mov	es,[tcbspool]		; get to sequence #
	assume	es:spldseg
	mov	ax,[fileseq]
	inc	ax			; bump sequence #
	cmp	ax,1000
	jb	sploname
	mov	ax,1
sploname:
	mov	[fileseq],ax
	pop	es
	lea	bx,splb.filname+7	; end of sequence in filename
	mov	cx,3			; set sequence number in filename
splonlp:
	xor	dx,dx
	div	[wordten]		; convert sequence to filename
	add	dl,'0'
	mov	[bx],dl
	dec	bx
	loop	splonlp
	mov	ah,[tcbcdft]		; change default security to specified
	mov	al,[splb.seclass]
	push	ax			; save default security
	cmp	al,0			; spool security set?
	je	splunsec
	mov	[tcbcdft],al		; if security class was speced
splunsec:
	call	gspsp			; get current psp and ser spool's PSP
	push	ax			; save user's PSP
	mov	ax,3c00h		; open the file for output
	xor	cx,cx
	lea	dx,splb.filname
	sub	dx,[splb.pathlen]	; address of filename
	call	do21h
	mov	si,ax			; save handle in si
	pop	ax			; restore user's PSP
	pushf
	push	bx
	mov	bx,ax
	mov	ah,50h
	call	do21h
	pop	bx
	popf
	pop	ax
	mov	[tcbcdft],ah		; restore default security class
	jc	splx			; check results of 3c call
	mov	[splb.handle],si	; only save handle if no error
	and	[tcbbrkfg],not 20h
	jmp	short splz
splx:
	call	splerr
splz:
	pop	si
	ret
splopen endp

	subttl splwrite - write contents of spool buffer
	page
;======================================================================
;,fs
; splwrite - write contents of spool buffer
;
; in:	ds = spool buffer segment
;	bx = file handle
;
; out:	ah = ok status
;
;,fe
;=====================================================================
	assume	ds:splbuff,es:nothing,ss:tcb
splwrite proc near
	lea	dx,splb.buffer		; buffer addr
	mov	cx,[splb.buffpnt]
	sub	cx,dx			; number of chars to write
	jcxz	splwxit
	call	gspsp			; get current psp and ser spool's PSP
	push	ax			; save user's PSP
	mov	ah,40h			; write to file
	call	do21h
	jc	splwx
	pop	ax			; restore psp
	pushf
	push	bx
	mov	bx,ax
	mov	ah,50h
	call	do21h
	pop	bx
	popf
	mov	[splb.buffpnt],dx
splwxit:
	mov	ah,ok_stat
	jmp	short splwz
splwx:
	pop	ax
	mov	ah,err_stat
	call	splerr
splwz:
	ret
splwrite endp

	subttl splerr - pop up the error message window
	page
;======================================================================
;,fs
; splerr - pop up the error message window
;
; in:
;
; out:
;
;,fe
;=====================================================================
	assume	ds:nothing,es:nothing,ss:tcb
splerr proc near
	pushf
	test	[tcbbrkfg],20h
	jnz	splerra
	push	ax
	push	dx
	push	ds
	push	es
	mov	dx,offset splmsg1
	mov	bx,cs
	mov	ah,0ffh
	mgetscb es
	assume	es:grp
	cmp	word ptr [scbcin24+2],0
	je	splerrb
	pushf
	call	[scbcin24]
	or	[tcbbrkfg],20h
splerrb:
	pop	es
	pop	ds
	pop	dx
	pop	ax
splerra:
	popf
	ret
splerr endp

	subttl spltimer - start spooler timeout
	page
;======================================================================
;,fs
; spltimer - start spooler timeout
;
; spltimer sets the poll time for a spooler timeout file close.
;
; in:	ds -> spool buffer segment
;
; out:
;
;,fe
;=====================================================================
	assume	ds:splbuff,es:nothing,ss:tcb
spltimer proc near
	push	es
	mgetscb es			; get scb segment
	assume	es:grp
	mov	ax,[scbtimer]		; get system tick counter
	pop	es
	cmp	ax,[splb.timebeg]
	mov	[splb.timebeg],ax
	jne	spltimout		; short circuit if no change
	ret
spltimer endp

	subttl spltimout
	page
;======================================================================
;,fs
; spltimout
;
; spltimout set spool poll time to minimum of spool data segment
; file close timeout value
;
; in:
;
; out:
;
;,fe
;=====================================================================
	assume	ds:nothing,es:nothing,ss:tcb
spltimout proc near
	push	ds
	push	es
	mgetscb es			; get current tick counter
	assume	es:grp
	mov	ax,[scbtimer]
	mov	bx,[tcbspool]		; loop through all spool data segs
	or	bx,bx			; test any spooling
	jz	spltmxit
	add	bx,spldoff		; get minimum spool close ticks
	mov	ds,bx
	assume	ds:splbuff
	mov	dx,-1			; dx is minimum time to close timeout
spltmlup:
	cmp	[splb.handle],-1	; if file is open
	je	spltmnxt
	mov	cx,[splb.timebeg]	; timeoutbeg - current + timeoutlen
	sub	cx,ax
	add	cx,[splb.timeout]
	cmp	cx,dx			; get minimum of all spool buffers
	jae	spltmnxt
	mov	dx,cx			; timeout for this file is less
spltmnxt:
	add	bx,spldpars		; get to next buffer
	mov	ds,bx
	cmp	[splb.printer],0	; test end of spool buffers
	jne	spltmlup

; dx = minimum ticks to spool file close timeout

	inc	dx			; check no files active
	jz	spltmsto		; jump and store 0 => no poll
	add	dx,[scbtimer]		; get system tick value
	jnz	spltmsto		; ensure nonzero tick
	inc	dx
spltmsto:
	mov	[tcbspltp],dx		; set poll time
spltmxit:
	pop	es
	pop	ds
	ret
spltimout endp

	subttl closspls - close the spool file
	page
;======================================================================
;,fs
; closspls - close the spool file
;
; closspls closes all spool files on exit of program
;
; in:
;
; out:
;
;,fe
;=====================================================================
	assume	ds:nothing,es:nothing,ss:tcb
closspls proc near
	cmp	[tcbspool],0		; any spooling active
	je	clospxit
	push	ds
	mov	ax,[tcbspool]
	add	ax,spldoff
	mov	ds,ax			; get to first data buffer segment
	assume	ds:splbuff
closplup:
	call	splclose
	mov	ax,ds
	add	ax,spldpars
	mov	ds,ax
	cmp	[splb.printer],0
	jne	closplup
	pop	ds
clospxit:
	ret
closspls endp

	subttl i17close
	page
;======================================================================
;,fs
; i17close
;
; in:	ah = function #
;	al = char
;	bx = logical printer number (used by reserve_lpt_port)
;	dx = printer physical port (if parallel printer)
;	di = device type (0 = printer, 1 = spool, 2 = com, 3 = remote)
;	ch = spool disposition
;	ds = spool data seg (if spooling)
;	es = bios (if parallel port)
;
; out:	ah = printer status
;
;,fe
;=====================================================================
	assume	ds:grp,es:splbuff,ss:tcb
i17close proc near
	mov	ah,inv_stat		; invalid if not spooling
	cmp	di,i17_spl
	jne	i17clsxit
	mov	ax,es			; get buffer segment to ds
	mov	ds,ax
	call	splclose		; close specified file
	mov	ah,ok_stat		; return good status
i17clsxit:
	ret
i17close endp

	subttl splclose - flushes and closes the spool file.
	page
;======================================================================
;,fs
; splclose - flushes and closes the spool file.
;
; in:	ds -> spool data structure
;	ss -> tcb
;
; out:
;
;,fe
;=====================================================================
	assume	ds:splbuff,es:nothing,ss:tcb
splclose proc near
	mov	bx,-1
	xchg	[splb.handle],bx	; get/reset spooling file handle
	cmp	bx,-1			; any file to close?
	je	sclsxit
	push	es
	mgetscb es
	assume	es:grp
	inc	[scbi15off]		; temporarily disable dbts
	call	splwrite		; flush remaining data
	call	gspsp			; get current psp and ser spool's PSP
	push	ax			; save user's PSP
	mov	ah,3eh			; close the file
	call	do21h
	pop	ax			; reset psp original
	pushf
	push	bx
	mov	bx,ax
	mov	ah,50h
	call	do21h
	pop	bx
	dec	[scbi15off]		; re-enable dbts
	popf
	pop	es
	assume	es:nothing
	jnc	sclsxit
	call	splerr
sclsxit:
	ret
splclose endp

	subttl clospoll - check for spool closes on poll
	page
;======================================================================
;,fs
; clospoll - check for spool closes on poll
;
; clospoll spool file close poll routine.  called at timer tick
; [tcbspltp].  closes spool file not written to in x ticks
;
; in:	cx = current timer tick
;
; out:
;
;,fe
;=====================================================================
	assume ds:nothing,es:nothing,ss:tcb
clospoll proc near
	mov	bx,[tcbspool]		; loop through spool data segs
	or	bx,bx			; any spooling?
	jz	clspret
	push	ds
	mgetscb ds
	assume	ds:grp
	cmp	[scb15act],0		; if out in i15suspend, defer file i/o
	je	clspskp1
	mov	dx,1			; try again next tick
	add	dx,[scbtimer]		; get system tick value
	mov	[tcbspltp],dx		; set poll time
	jmp	short clspskp2
clspskp1:
	add	bx,spldoff
	mov	ds,bx
	assume	ds:splbuff
clsploop:
	cmp	[splb.printer],0	; any buffer
	je	clspxit
	cmp	[splb.handle],-1	; file open
	je	clspnext

; peform an unsigned compare of the time difference here.

	mov	ax,cx
	sub	ax,[splb.timebeg]
	cmp	ax,[splb.timeout]
	jb	clspnext
	push	cx
	call	splclose		; file timed-out,close it
	pop	cx
clspnext:
	mov	bx,ds
	add	bx,spldpars		; get to next buffer
	mov	ds,bx
	jmp	clsploop
clspxit:
	call	spltimout		; set next close timeout poll
clspskp2:
	pop	ds
clspret:
	ret
clospoll endp

	subttl initspl
	page
;======================================================================
;,fs
; initspl
;
; in:
;
; out:
;
;,fe
;=====================================================================
	assume	ds:grp,es:splbuff,ss:tcb
initspl proc near
	mov	ah,ok_stat		;fake good status for remote case
	ret
initspl endp

	subttl statspl
	page
;======================================================================
;,fs
; statspl
;
; in:
;
; out:
;
;,fe
;=====================================================================
	assume	ds:grp,es:splbuff,ss:tcb
statspl proc near
	mov	ah,ok_stat		; fake good status for remote case
	ret
statspl endp

	subttl gspsp
	page
;======================================================================
;,fs
; gspsp
;
; in:
;
; out:
;
;,fe
;=====================================================================
	assume	ds:splbuff,es:nothing,ss:tcb
gspsp proc near
	push	bx
	push	[tcbstkp]
	mov	[tcbstkp],sp		; use current sp as stack top
	sub	[tcbstkp],80h		; bias it then call 21h handler
	mov	ah,51h
	int	21h
	push	bx			; get current psp
	mov	bx,[splb.iopsp]
	mov	ah,50h
	int	21h
	pop	ax			; return it to ax
	pop	[tcbstkp]
	pop	bx
	ret
gspsp endp

	subttl do21h - call int21 with stack biasing
	page
;======================================================================
;,fs
; do21h - call int21 with stack biasing
;
; call int 21h with stack biasing for mos re-entrancy from apps
; must call the current handler to allow apps which have it to handle
; the int 21h function (i.e. lanlink for spooling on network).
;
; in:
;
; out:
;
;,fe
;=====================================================================
	assume ds:nothing,es:nothing,ss:tcb
do21h proc near
	push	[tcbstkp]		; save current tcb stack top
	mov	[tcbstkp],sp		; use current sp as stack top
	sub	[tcbstkp],80h		; bias it then call 21h handler
	int	21h
	pop	[tcbstkp]		; restore biased stack top and return
	ret
do21h endp

;,fs
;**********************************************************************
;******** serial port functions
;**********************************************************************
;,fe

	subttl i17com - print character to serial port.
	page
;======================================================================
;,fs
; i17com - print character to serial port.
;
; in:	al = character to be output to the port.
;	dx = serial port (0-23) to output character to.
;
; out:	ah = i/o status for use by int 17 return.
;	note that this status will not accurately
;	reflect what is wrong at the serial port
;	since this is a redirection, but will
;	simply approximate the situation.
;
;,fe
;=====================================================================
	assume	ds:grp,es:splbuff,ss:tcb
i17com	proc near

; first thing, attempt to reserve the com port for use by this task.

	call	reserve_com_port
	jc	i17com_exit

; the reservation was successful.  now attempt to send the
; character out.  (attempt to retry on failure for 256 iterations
; in the same fashion that mosdevs does).

	mov	cx,256			;try at least 256 times.
i17com_lp:
	push	ax			;save the character.
	mov	ah,1			;output to serial port.
	int	14h
	test	ah,80h			;if no error, exit immediately.
	jz	i17com_ok
	pop	ax			;get character back and retry.
	loop	i17com_lp
	call	InfRetry		; is this setup for infinete retry
	mov	cx,128
	jnz	i17com_lp		
	mov	ah,err_stat		;if all retries failed, return error.
	ret
i17com_ok:
	pop	ax			;rebalance stack.
	mov	ah,ok_stat		;return ok status.
i17com_exit:
	ret
i17com	endp

	subttl i17coms
	page
;======================================================================
;,fs
; i17coms
;
; in:	cx = length of string to be output.
;	dx = port to output to. (0-23)
;	ds:si = pointer to string to be output.
;
; out:	ah = status of output.
;	cx = number of characters left in string
;	on failure.  (will naturally be 0
;	if entire string was output)
;
;,fe
;=====================================================================
	assume	ds:nothing,es:splbuff,ss:tcb
i17coms proc near

; first, let's attempt to reserve the COM port for our use.

	call	reserve_com_port
	jc	i17_cs_exit
	mov	ds,[tds]		;load ds:si with buffer loc.

; the reservation was successful.  we don't have to worry about someone
; else sending data out this port right now.

i17_cs1:
	lodsb				;get the next character.
	push	cx			;save the character counter.
	mov	cx,256			;inner (retry loop) = 256 tries.

i17_cs2:
	push	ax			;save the character.
	push	cx
	mov	ah,1			;output the character.
	int	14h
	pop	cx
	test	ah,80h			;everything ok?
	jz	i17_csok		;if so, go loop for next char.
	pop	ax			;not ok. get char back and retry.
	loop	i17_cs2

;
	call	InfRetry		; check for infinite retry
	mov	cx,128
	jnz	i17_cs2			; if it is then retry...

; after 256 retries, we couldn't send anything to the COM port.
; return an error.

	pop	cx			;rebalance the stack.
	mov	ah,err_stat		;return error.
	ret
i17_csok:
	pop	ax			;balance the stack.
	pop	cx			;recover the character counter.
	loop	i17_cs1			;if any left, go fetch it.

; the output to the com port was ok.  return.

	mov	ah,ok_stat

i17_cs_exit:
	ret
i17coms endp

	subttl initcom
	page
;======================================================================
;,fs
; initcom
;
; this routine doesn't actually initialize the COM port ...
; $serial.sys does that on startup.
;
; in:
;
; out:
;
;,fe
;=====================================================================
	assume	ds:grp,es:splbuff,ss:tcb
initcom proc near
	call	reserve_com_port
	ret
initcom endp

	subttl statcom
	page
;======================================================================
;,fs
; statcom
;
; in:
;
; out:
;
;,fe
;=====================================================================
	assume	ds:grp,es:splbuff,ss:tcb
statcom proc near
	call	reserve_com_port
	jc	statcom_exit
	call	comstatus
statcom_exit:
	ret
statcom endp

	subttl comstatus
	page
;======================================================================
;,fs
; comstatus
;
; checks the status of the serial port (or buffer in $serial.sys).
; if the transmitter holding buffer is not empty, return error code
; indicating that fact.
;
; in:	dx = serial port to check.
;
; out:	ah = printer status.
;
;,fe
;=====================================================================
	assume	ds:nothing,es:nothing,ss:tcb
comstatus proc near
	mov	ah,3			;get serial port status.
	int	14h
	test	ah,20h			;test xmitter holding reg. empty.
	mov	ah,err_stat
	jz	comstxit		;if not empty, return error stat.
	mov	ah,ok_stat		;empty.  character can be sent.
comstxit:
	ret
comstatus endp

	subttl reserve_com_port
	page
;======================================================================
;,fs
; reserve_com_port
;
; this function attempts to reserve the selected com port for
; exclusive use by this task for a set period of time. (as defined
; in the tcb_com_hold variable).
;
; in:	dx = index of serial port. (0-23)
;	ss = reference to tcb segment.
;
; out:	cf set if port reserved by another task.
;	ax contains reserved status.
;	if cf clear, the reservation was honored and
;	output may proceed to the device.
;
;,fe
;=====================================================================
	assume	ds:nothing,es:nothing,ss:tcb
reserve_com_port proc near
	push	ax			;[bp+6]
	push	dx			;[bp+4]
	push	es			;[bp+2]
	push	bp
	mov	bp,sp

; load ds with the scb pointer so we can get at port reservation
; values.

	mgetscb es
	assume	es:grp
	cli				;protect ourself.

; compute offset into reservation list.

	mov	bx,[bp+4]
	shl	bx,1
	cmp	scb_com_owner[bx],-1
	je	rcp_ok
	mov	ax,tcbid
	cmp	ax,scb_com_owner[bx]
	je	rcp_ok

; someone else has the port.  have they timed out yet?

	shl	bx,1
	mov	ax,word ptr scb_com_timeout[bx]
	sub	ax,scbtimer
	mov	ax,word ptr scb_com_timeout[bx+2]
	sbb	ax,scbtimerh
	jb	rcp_ok

; the port has not yet timed out.  return an error status.

	mov	ax,[bp+6]		;get character back.
	mov	ah,reserved
	mov	[bp+6],ax		;return it to the stack.
	stc
	jmp	short rcp_exit

; the port is available to be reserved.  do it.  if the hold time
; was specified as zero, do nothing with it.

rcp_ok:
	mov	bx,[bp+4]		;get original index back.
	shl	bx,1
	cmp	tcb_com_hold[bx],0
	jne	rcp_res

; the requested timeout was zero, meaning that he doesn't want
; it reserved.  simply relinquish ownership of the port and
; exit.

	mov	scb_com_owner[bx],-1
	shl	bx,1			;index dword time table.
	mov	word ptr scb_com_timeout[bx],0
	mov	word ptr scb_com_timeout[bx+2],0
	jmp	short rcp_done

; the reservation may proceed.

rcp_res:
	mov	ax,tcbid
	mov	bx,[bp+4]
	shl	bx,1
	mov	scb_com_owner[bx],ax	;establish ownership.
	mov	ax,tcb_com_hold[bx]	;get the old time.
	shl	bx,1			;address dword time values.
	add	ax,scbtimer
	mov	word ptr scb_com_timeout[bx],ax
	mov	ax,scbtimerh
	adc	ax,0
	mov	word ptr scb_com_timeout[bx+2],ax
rcp_done:
	mov	ax,[bp+6]		;update ah.
	mov	ah,ok_stat
	mov	[bp+6],ax		;put back on stack.
	clc
rcp_exit:
	sti
	pop	bp
	pop	es
	pop	dx
	pop	ax
	ret
reserve_com_port endp

;,fs
;**********************************************************************
;******** remote port functions
;**********************************************************************
;,fe

	subttl i17remst - get remote status
	page
;======================================================================
;,fs
; i17remst - get remote status
;
; in:	ss -> tcb
;
; out:	ah = printer status
;	al destroyed
;
;,fe
;=====================================================================
	assume	ds:nothing,es:nothing,ss:tcb
i17remst proc near
	push	cx
	push	si
	push	di
	push	ds
	push	es
	mov	di,3			; 3 status read retries
i17rc4:
	mov	cx,ss			; ds:si = driver vector
	mov	ds,cx
	mov	si,offset [tcbcondd]
	mov	ax,1200h		; initiate printer status request
	call	ddtcallf
	cmp	bx,0f3c9h		; is the ddt new enough?
	jne	i17rc7
	or	al,al			; if the fresh-flag is already 
	jnz	i17rc2			; set, no need to call getkeys
	mov	ax,ss			; get tcb into es
	mov	es,ax
	mov	cl,2			; bit pos in tcbwtflg for wrap flag
	mov	ax,remtim
	call	timparm			; get timer time-out value
	mov	[tcbtoax],ax
	mov	[tcbtocx],cx		; save time out data for poll/timchk
i17rc3:

; call getkeys so printer status codes can be received and
; processed by the ddt.  in the sherwood case, this is necessary to
; update the printer status.  

	cmp	[tcbslcnt],0
	je	i17rc5
	call	getkeys
	jmp	short i17rc6
i17rc5:
	call	suspend2		; note: tcbwait/tcbpoll not set
i17rc6:
	mov	ax,[tcbtoax]		; check for time out
	mov	cx,[tcbtocx]
	call	timchk
	jnz	i17rc1
	dec	di			; count down a status read retry
	jnz	i17rc4
	mov	ah,err_stat
	jmp	short i17rc2
i17rc1:
	mov	ax,1201h
	call	ddtcallf
	or	al,al			
	jz	i17rc3
i17rc2:
	and	ah,not 40h		; strip off ack bit
i17rc8:
	pop	es
	pop	ds
	pop	di
	pop	si
	pop	cx
	ret
i17rc7:
	mov	ah,ok_stat		; get good status
	jmp	short i17rc8
i17remst endp

	subttl i17remc - outputs characters to remote printer
	page
;======================================================================
;,fs
; i17remc - outputs characters to remote printer
;
; when must wait for a good status, can't use a typical poll routine
; since getkeys must be called to process status codes (sherwood).
; getkeys cannot be called from within a tcbpoll routine since getkeys
; requires the task's context and task ram be switched in. 
;   
; in:	ah = print function 0
;	al = character to print
;
; out:	ah = printer status
;
;,fe
;=====================================================================
	assume	ds:grp,es:splbuff,ss:tcb
i17remc proc near
	push	bp
	sub	sp,4
	mov	bp,sp
	mov	dl,al

; check status
	call	i17remst
	cmp	ah,ok_stat		; printer ok?
	je	i17rm1

; if not ok, setup timeout for retry loop

i17rm0:
	mov	ax,ss			; get tcb into es
	mov	es,ax
	mov	cl,2			; bit pos in tcbwtflg for wrap flag
	mov	ax,polltim		; # of ticks for 30 seconds
	call	timparm			; get timer time-out value
	mov	[bp],ax
	mov	[bp+2],cx		; save time out data for poll/timchk
i17rm2:
	mov	[tcbslcnt],0
	call	tsl			; let other tasks breath
	call	i17remst
	cmp	ah,ok_stat		; printer ok?
	je	i17rm1
	mov	ax,[bp]			; check for time out
	mov	cx,[bp+2]
	call	timchk
	jnz	i17rm2
	call	InfRetry		; if infinate retry continue
	jnz	i17rm0		
	mov	ah,err_stat
	jmp	short i17rm3
i17rm1:
	mov	al,dl
	mov	cx,ss			; ds:si = driver vector
	mov	ds,cx
	mov	si,offset [tcbcondd]
	mov	ah,10h			; single char print function
	call	ddtcallf		; call device driver.
	cmp	ah,ok_stat
	je      i17rm3
	call	InfRetry
	jnz	i17rm0
i17rm3:
	add	sp,4
	pop	bp
	ret				; return with status
i17remc endp

	subttl i17rems - outputs string to remote printer
	page
;======================================================================
;,fs
; i17rems - outputs string to remote printer
;
; in:	ah = print function 3
;	[tcx] = chars to print
;	[tds]:tsi=> string to print
;
; out:	ah = remote printer status
;	si = new position in string after outputting to printer.
;
;,fe
;=====================================================================
	assume	ds:grp,es:splbuff,ss:tcb
i17rems proc near
	mov	ds,[tds]
	cld
i17rs1:
	lodsb
	push	cx
	push	si
	push	ds
	call	i17remc
	pop	ds
	pop	si
	pop	cx
	cmp	ah,ok_stat		; printer ok?
	loope	i17rs1
	ret
i17rems endp

	subttl initrem
	page
;======================================================================
;,fs
; initrem
;
; in:
;
; out:
;
;,fe
;=====================================================================
	assume	ds:grp,es:splbuff,ss:tcb
initrem proc near
	mov	ah,ok_stat		;fake good status for remote case.
	ret
initrem endp

	subttl statrem
	page
;======================================================================
;,fs
; statrem
;
; in:	ah = 2
;
; out:	ah = returned printer status.
;
;,fe
;=====================================================================
	assume	ds:grp,es:splbuff,ss:tcb
statrem proc near
	call	i17remst
	ret
statrem endp

mosseg	ends
	end

