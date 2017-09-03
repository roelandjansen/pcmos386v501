	include page.inc
	include options.inc
	title	mosint17 - bios keyboard software interrupt

;-----------------------------------------------------------------------
;			development specification
; program name: $$mos.sys		assigned to: martin stitt
; module name:	mosint17		assign date:
; entry points: mosint17		completed:
; entry method: int 17h
;
; purpose:	perform printer output and manage spooling
;-----------------------------------------------------------------------
; mjs  3/23/87	add function 03 for string printing.  add support for
;		serial printers
;
; sah  7/20/87	change clospoll to make sure it never sets a non-zero
;		timer value or it will skip the close (observed because
;		of disapearing terminal - vidram)
;-----------------------------------------------------------------------
; sah/jrb 8/04/87  corrected int 17h logics so that is waits up to
;		a maximum of a clock cycle before it test for
;		printer status after printer output
;-----------------------------------------------------------------------
; sah  8/06/87	modified printer logic so that is works from a
;		terminal printer even when spooling is active
;-----------------------------------------------------------------------
; mjs 10/15/87	modified the procedure setsplfl to only call timparm
;		if the low word of the timer has changed since the last
;		call to setsplfl. modified serial port status checking
;		to use bit 80h of ah after an int14 call rather than
;		specifically decode the modem bits. modify return status
;		when a serial port is found to be busy.  at the entry
;		to mosint17, just before the call to mossaver, set the
;		flag tcbfsavr in order to make a quick pass through
;		mossaver.  re-organized the logic of the serial printing
;		segment in order to optimize performance and solve
;		problems with critical error handling. (from d.c. trip)
;-----------------------------------------------------------------------
; sah 02/11/88	correct int 17 not returning al correctly (multimate)
;		and timeout value in ah should be 11h instead 01h
;-----------------------------------------------------------------------
; rdg 07/06/88	gated access to the console device drivers to prevent
; rg8188	corruption of the serial data stream being sent to a
;		terminal by changing the calls to the console device
;		driver from a call dword ptr [si] to call ddtcallf
;-----------------------------------------------------------------------
; sjc 08/15/88	added do21h for re-entrant mos calls.
;		replaces domos macro.  this change, with ddtmc change,
;		allows lanlink to spool across network.
;-----------------------------------------------------------------------
; sah 09/27/88	use suspend2 calls instead suspend calls which allow
;		tsl to be re-enter.
; sah 09/28/88	change serial printing logic on that if printer returns
;		error pointer return to caller is not decremented.
;-----------------------------------------------------------------------
; rkg 02/13/88	change spooling to different spool file per printer
;		and pass-through printing.  func ff closes spool files.
;-----------------------------------------------------------------------
; mjs 03/03/89	added error handling after the calls to the ddt printing
;		functions.
;-----------------------------------------------------------------------
; sah 08/22/89	corrections for spooling across novell, must use int 21
;		get and set psp calls, so novell can propertly handle
;		psp's.
;-----------------------------------------------------------------------
; sah 08/23/89	corrected routing from lpt to com above com1, port was
;		not being set!
;-----------------------------------------------------------------------
; mjs 09/01/89	corrected two problems with printing when redirection
;		to a com port is being used.  single character printing
;		with int17fun00 would not work at all (wrong type of
;		jump used).  int7fun03 printing would fail when the
;		serial driver's buffer filled up (wrong type of status
;		test).
;-----------------------------------------------------------------------
; mjs 09/08/89	modified the error handling logic for print spooling to
;		not do a bugerror.  scbcin24 is called to pop up a 
;		critical error type window instead.
;-----------------------------------------------------------------------
; BWR 11/29/89	Corrected ROUTE problem and marked messages for
;		foreign language translation.
;-----------------------------------------------------------------------
; SAH 02/20/90  made i17prtbit public for mosint38
;-----------------------------------------------------------------------
; BWR 04/09/90	Spooler now accepts timeout values up to 3600 seconds.
;		(60 minutes).  Due to math error in routine "clospoll"
;		a signed value was being tested instead of an unsigned
;		causing problems for timeouts of 1800 and greater. (The
;		signed test was causing many little spool files to be
;		created instead of just one.)
;-----------------------------------------------------------------------
; BWR 06/06/90  Corrected problem with incorrect status being returned
;  &            for status check on printer when redirected through
; CBK           terminal or COM device.
;-----------------------------------------------------------------------
	include group.inc

					; time out value for poll routines
polltim equ	110			; # of ticks for approx 6 seconds
					; it will take 4 tries to get a critical
					; error

	subttl	group segments and include block definitions
	page

	include macros.inc
	.xlist
	include mosregs.inc

tcb	segment at 1234h
	include mostcb.inc		; tcb definition
tcb	ends

gdata	segment word public 'data'
	include mosscbex.inc		; specify all scb items as external
gdata	ends
	.list

irq	segment byte public 'data'

	dw	17h*4			; offset for this interrupt
i17old	dd	?			; save prior value
i17sav	dw	0			; don't save changes, leave them alone
i17new	dw	mos:mosint17		; initial value is here
i17new2 dw	0			; don't change back if app it

irq	ends

poll	segment byte public 'data'
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

ddt	segment word public 'code2'
ddt	ends

	subttl	int 17 handler
	page

mosseg	segment word public 'code1'

	extrn	mossaver:near,mosrestore:near,suspend2:near
	extrn	timparm:near,timchk:near
	extrn	ddtcallf:near		; console device driver gating
	extrn	bugerror:near

	public	mosint17,ptrtype,closspls,i17prtbit,wordten

	include mosint17.pub

	subttl	mosint17 - printer i/o

	assume	cs:mos,ds:nothing,es:nothing,ss:nothing

i17prtbit db	1,2,4			; printer bit lookup table

; printer type definitions

I17_NUL equ	-1			; unknown or ignore
I17_LPT equ	0			; printing to parallel port
I17_SPL equ	1			; spooling to disk
I17_COM equ	2			; printing to serial port
I17_REM equ	3			; printing to terminal printer

; list of routines to execute dependent on function

i17funcs dw	i17close		; func ffh close spool file
	 dw	i17print		; func 00h output char to printer
	 dw	i17init			; func 01h reset/initialize printer
	 dw	i17stat			; func 02h return printer status
	 dw	i17prtstr		; func 03h print string

OK_STAT   equ	090h			; normal print status
ERR_STAT  equ	011h			; error/timeout status
INV_STAT  equ	0ffh			; invalid port status
RSVD_STAT equ	013h			; in use by different task

bios	segment at 40h
	org	8h
bioslpts dw	4 dup (?)		; printer port table in bios
	org	6ch
biostick dw	?			; bios area timer tick counter
bios	ends

lptsetl equ	4000			; loop counter lpt init settle value
comsetl equ	50			; loop counter com port settle time

;----------------------- mosint17 ----------------------------

mosint17:
	sti
	push	es
	mgetscb es
	assume	es:grp
	mov	es,[scbtcbpc]		; get tcb
	assume	es:tcb
	mov	[tcbfsavr],'Y'		; set short form flag for mossaver
	pop	es
	call	mossaver
	assume	ds:grp,es:nothing,ss:tcb

if	bias
	push	[tcbstkp]
	sub	[tcbstkp],bias
endif

	mov	[tcbfsavr],'N'		; reset short form flag for mossaver
	mov	[tcbkbcnt],0		; reset keyboard looping counter
	mov	bx,[tdx]
	cmp	bx,2			; check port is valid
i17invld:
	mov	ah,INV_STAT
	ja	i17xit
	call	ptrtype			; return type of printer
	or	di,di			; test invalid printer
	js	i17xit
	mov	si,bx			; duplicate port into si
	mov	ax,[tax]
	inc	ah			; adjust for ff function
	cmp	ah,4			; test function in range
	ja	i17invld
	mov	bl,ah			; vector to function
	xor	bh,bh
	add	bx,bx
	xchg	bx,si			; call with bx = logical printer
	call	i17funcs[si]
i17xit:
	mov	[tah],ah		; don't destroy AL value (Multi-Mate)

if	bias
	pop	[tcbstkp]
endif

	call	mosrestore
	iret

;- ptrtype -------------------------------------------------------------
; returns ultimate destination of int 17 printer
; enter:	bx = printer number (0-2)
; exits:	di = printer type as defined above
;		bx updated if directed to different printer
;		cl = printer bit, ch = spooling disposition
;		ah = status if di = -1 (invalid device)
;		dx = printer port if parallel device
;		es = splbuff (if spooling) / = bios if parallel port
;-----------------------------------------------------------------------
	assume	ds:grp,es:nothing,ss:tcb

ptrtype:
	mov	cl,i17prtbit[bx]
	mov	di,I17_REM		; device type = remote
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
	mov	di,I17_NUL
	mov	ah,OK_STAT		; give success status
	je	ptrxit
	cmp	ch,'N'			; check pass-through
	je	ptrnospl		; then no spooling
	mov	di,I17_SPL		; di = print device = spool
	jmp	ptrxit			; exit with spooling mode
ptrsplnxt:
	add	ax,spldpars		; get to next buffer
	cmp	[splb.printer],0	; end of spool buffers?
	jnz	ptrsplsg

; test device routed to serial device

ptrnospl:
	mov	di,I17_COM		; device type = serial
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
	mov	di,I17_LPT		; device type = parallel printer
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
	mov	ah,INV_STAT		; invalid printer return error status
	mov	di,I17_NUL		; unknown printer
ptrxit:
	ret

	subttl	char and string print routines
	page
;-----------------------------------------------------------------------
;	int 17 internal functions are called with:
;
;	ax = user ax,(function, char)
;	bx = logical printer number (used by holdstat)
;	dx = printer physical port (if parallel printer)
;	di = device type (0 = printer, 1 = spool, 2 = com, 3 = remote)
;	ch = spool disposition
;	ds = spool data seg (if spooling)
;	es = bios (if parallel port)
;-----------------------------------------------------------------------

;-----------------------------------------------------------------------
;	int 17	function 1	print character
;	enter:	ah = 1
;		al = char
;		dx = printer port
;	exits:	ah = printer status
;-----------------------------------------------------------------------
prtcvect dw	i17lpt,i17spl,i17com,i17remc  ; print character vects
	public	i17lpt,i17spl,i17com,i17remc

; i17print print character in al to [dx] printer

i17print:
	add	di,di			; just call routine
	jmp	prtcvect[di]

;-----------------------------------------------------------------------
;	int 17	function 3	print string
;	enter:	ah = 3
;		dx = printer port
;		cx = number of chars to print
;		si => string to print
;		*** function must load [tds] - string segment ***
;	exits:	cx = number of chars printed
;-----------------------------------------------------------------------
prtsvect dw	i17lpts,i17spls,i17coms,i17rems  ; print string vectors
	public	i17lpts,i17spls,i17coms,i17rems

i17prtstr:
	mov	cx,[tcx]		; number of chars
	mov	ah,OK_STAT
	xor	si,si			; return value if no chars
	jcxz	i17sxit			; quick exit when no chars to print
	mov	si,[tsi]
	cld				; for lodsb
	add	di,di			; turn into dispatch index
	call	prtsvect[di]
	sub	si,[tsi]		; calc bytes output
	cmp	ah,OK_STAT		; test any errors
	je	i17sxit
	dec	si			; error on last one so decr count
i17sxit:
	mov	[tcx],si
	ret

	subttl	print char/string remote
	page
;-----------------------------------------------------------------------
;	i17remc outputs character to remote printer
;	enter:	ah = print function 0
;		al = character to print
;	exits:	al = printer status
;-----------------------------------------------------------------------
i17remc:
	mov	cx,ss			; ds:si = driver vector
	mov	ds,cx
	mov	si,offset [tcbcondd]
	mov	ah,10h			; single char print function
	call	ddtcallf		; call device driver when not busy	rg8188
	test	ah,29h			; test printer errors			890303
	jnz	i17rcxit
	mov	ah,OK_STAT		; get good status
i17rcxit:
	ret				; return with status

;-----------------------------------------------------------------------
;	i17rems outputs string to remote printer
;	enter:	ah = print function 3
;		[tcx] = chars to print
;		[tds]:[tsi=> string to print
;	exits:	al = remote printer status
;		[tcx] = characters printed
;-----------------------------------------------------------------------
i17rems:
	mov	es,[tds]		; send string to print string function
	mov	di,si
	mov	ax,ss			; ds:si = driver vector
	mov	ds,ax
	mov	si,offset [tcbcondd]
	mov	ah,11h
	call	ddtcallf		; call device driver when not busy
	mov	si,[tsi]
	add	si,[tcx]		; calc pointer
	sub	si,cx			; returns cx chars not printed
	test	ah,29h			; test printer errors
	jnz	i17rsxit
	mov	ah,OK_STAT		; get good status
i17rsxit:
	ret				; return with status


	subttl	print char/string to parallel port
	page
;-----------------------------------------------------------------------
; print char/string to parallel port
;-----------------------------------------------------------------------
	assume	ds:grp
i17lpt:
	call	holdstat		; is printer held by another task
	jc	i17lerr
	mov	cx,1			; character count
	jmp	short i17lchar
i17lpts:
	mov	es,[tds]
	call	holdstat		; printer held by another task
i17llup:
	mov	al,es:[si]		; get first/next char of string
	inc	si
	jc	i17lerr			; error from holdstat
i17lchar:
	mov	di,[scbtimer]		; test status for up to a cycle
i17ltest:				; sah/jrb 08/04/87
	out	dx,al			; output to port
	call	lptbusy
	jz	i17lprt			; printer ready
	cmp	di,[scbtimer]
	je	i17ltest		; loop until ready or tick
i17lbusy:
	mov	di,offset polllpt     	; give poll routine
	call	i17wait			; to wait/timeout
	mov	ah,ERR_STAT
	jz	i17lerr			; port timeout
	call	holdstat		; reserve printer again
	jnc	i17lchar		; printer reserved/ensure prn ready
i17lerr:
	ret

i17lprt:
	call	printbyte
	loop	i17llup			; loop for all chars
	mov	ah,90h			; return good status since printed
	ret

	subttl	print char/string to serial port
	page
;-----------------------------------------------------------------------
; print char/string to serial port
;-----------------------------------------------------------------------
i17com:					; printing to serial port
	mov	cx,1			; character count
	jmp	short i17cchar
i17coms:
	mov	ds,[tds]
i17cmslup:
	lodsb				; get next char
i17cchar:
	mov	ah,1			; output char
	int	14h
	or	ah,ah
	jns	i17cloop
	mov	di,offset pollcom 	; wait til port readies or timeout
	call	i17wait
	jnz	i17cchar		; port ready output char
	mov	ah,ERR_STAT		; return with timeout status
	ret
i17cloop:
	loop	i17cmslup		; loop for all chars
	call	comstatus		; return with status
	ret

	subttl	status and initialize routines
	page
;-----------------------------------------------------------------------
; i17init initialize printer and return status
;-----------------------------------------------------------------------
initvect dw	initlpt,initspl,initcom,initrem  ; printer initialize
	public	initlpt,initspl,initcom,initrem
i17init:
	add	di,di			; turn into dispatch index
	jmp	initvect[di]

initrem:
initcom:
initspl:
	mov	ah,OK_STAT		; fake good status for remote case
	ret

initlpt:
	call	holdstat		; check access to printer
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
;-----------------------------------------------------------------------
;	i17stat returns status of printing device
;-----------------------------------------------------------------------
statvect dw	statlpt,statspl,statcom,statrem  ; printer status vects
	public	statlpt,statspl,statcom,statrem
i17stat:
	add	di,di			; turn into dispatch index
	jmp	statvect[di]

statrem:
statspl:
	mov	ah,OK_STAT		; fake good status for remote case
	ret

statcom:
	call	comstatus
	ret

statlpt:
	call	holdstat		; is printer held by another task
	jc	statlhld		; yes return with reserved error
	call	lptstatus
statlhld:
	ret

	subttl	port printing poll routines
	page

;- i17wait -------------------------------------------------------------
;	i17wait waits for port to ready.  sets poll routine to check port
;	then suspends until port readies or timesout.
;	enter:	cs:di => poll routine
;	exits:	zr if timeout
;	saves:	all
;-----------------------------------------------------------------------
	assume	ds:nothing
i17wait:
	push	ax
	push	cx
	push	es
	mov	[tcbprprt],dx		; give port to poll routine
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
	pop	es
	pop	cx
	pop	ax
	ret

;-----------------------------------------------------------------------
;	polllpt,pollcom called on timer tick as tcb poll routine
;	awake task when device readies, or signal timeout
;	enter:	ss, es = tcb
;	exits:	al = 0 to end suspend
;	saves:	all?
;-----------------------------------------------------------------------
polllpt:				; check lpt device for busy
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
pollcom:				; check com device for busy
	mov	dx,[tcbprprt]		; expect port address here
	mov	ah,3
	int	14h
	and	ah,0e0h			; check port ready
	xor	ah,060h
	jz	polldone		; port ready
	jmp	polltime

	subttl	spooling routines
	page
;-----------------------------------------------------------------------
;	i17spl stores a character into the spool buffer
;	enter:	al = character
;		es => spool data segment
;----------------------------------------------------------------------
i17spl:
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
	mov	ah,OK_STAT		; good status unless flush fails
	jb	splxit
	mov	bx,[splb.handle]
	call	splwrite		; write to file when buffer is full
splxit:
	ret				; return with status from

;-----------------------------------------------------------------------
;	i17spls spools a print string
;-----------------------------------------------------------------------
i17spls:				; check if room for this string
	mov	ax,es
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

;-----------------------------------------------------------------------
;	splopen opens the spool file if not already open
;	enter:	ds = spooler data segment
;	exits:	cy if error on open
;		bx = spool file handle
;-----------------------------------------------------------------------
	assume	ds:splbuff

wordten dw	10			; constant

splopen:
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

	subttl	splwrite write contents of spool buffer
	page
;-----------------------------------------------------------------------
;	splwrite writes contents of spool data buffer
;	enter:	ds = spool buffer segment
;		bx = file handle
;	exits:	ah = ok status
;	uses	cx, dx
;-----------------------------------------------------------------------
	assume	ds:splbuff
splwrite:
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
	mov	ah,OK_STAT
	jmp	short splwz
splwx:
	pop	ax
	mov	ah,ERR_STAT
	call	splerr
splwz:
	ret

	subttl	splerr - pop up the error message window
	page
;-----------------------------------------------------------------------
;	splerr - pop up the error message window
;-----------------------------------------------------------------------

splmsg1	db	'Spool Error$        ',00h ;@@XLAT

splerr:
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

	subttl	spltimer - start spooler timeout
	page
;-----------------------------------------------------------------------
;	spltimer sets the poll time for a spooler timeout file close.
;	enter:	ds => spool buffer segment
;	uses:	ax
;-----------------------------------------------------------------------
	assume	ds:splbuff,es:nothing,ss:tcb
spltimer:
	push	es
	mgetscb es			; get scb segment
	assume	es:grp
	mov	ax,[scbtimer]		; get system tick counter
	pop	es
	cmp	ax,[splb.timebeg]
	mov	[splb.timebeg],ax
	jne	spltimout		; short circuit if no change
	ret

;-----------------------------------------------------------------------
;	spltimout set spool poll time to minimum of spool data segment
;	file close timeout value
;-----------------------------------------------------------------------
	assume	ds:nothing,es:nothing,ss:tcb
spltimout:
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

	subttl	splclose - close the spool file
	page
;-----------------------------------------------------------------------
; closspls closes all spool files on exit of program
;-----------------------------------------------------------------------
	assume	ds:nothing,es:nothing,ss:tcb
closspls:
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

;-----------------------------------------------------------------------
;	int 17 function ffh  -	close spool file
;	dx = printer  (translated to spool buffer)
;-----------------------------------------------------------------------
     	assume	es:splbuff,ds:nothing,ss:tcb
i17close:
	mov	ah,INV_STAT		; invalid if not spooling
	cmp	di,I17_SPL
	jne	i17clsxit
	mov	ax,es			; get buffer segment to ds
	mov	ds,ax
	call	splclose		; close specified file
	mov	ah,OK_STAT		; return good status
i17clsxit:
	ret

;-----------------------------------------------------------------------
;	splclose flushes and closes the spool file.
;	enter:	ds => spool data structure
;		ss => tcb
;	uses:	ax,bx
;-----------------------------------------------------------------------
	assume	ds:splbuff
 splclose:
	mov	bx,-1
	xchg	[splb.handle],bx	; get/reset spooling file handle
	cmp	bx,-1			; any file to close?
	je	sclsxit
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
	popf
	jnc	sclsxit
	call	splerr
sclsxit:
	ret

	subttl	clospoll - check for spool closes on poll
	page
;-----------------------------------------------------------------------
;	clospoll spool file close poll routine.  called at timer tick
;	[tcbspltp].  closes spool file not written to in x ticks
;	enter:	cx = current timer tick
;-----------------------------------------------------------------------
	assume ds:nothing, es:nothing,ss:tcb
clospoll:
	mov	bx,[tcbspool]		; loop through spool data segs
	or	bx,bx			; any spooling?
	jz	clspret
	push	ds
	add	bx,spldoff
	mov	ds,bx
	assume	ds:splbuff
clsploop:
	cmp	[splb.printer],0	; any buffer
	je	clspxit
	cmp	[splb.handle],-1	; file open
	je	clspnext
;
;BWR 4/9/90 -----------------------------------------------------------------
;
;  Peform an UNSIGNED compare of the time difference here.
;
	mov	ax, cx
	sub	ax, [splb.timebeg]
	cmp	ax, [splb.timeout]
	jb	clspnext
;
;BWR 4/9/90 -----------------------------------------------------------------
;
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
	pop	ds
clspret:
	ret

	subttl	port i/o routines
	page
;-----------------------------------------------------------------------
;	lptbusy returns zr if printer ready
;	enter:	dx = parallel printer port
;	exits:	zr/nz = printer error status
;	saves:	all
;-----------------------------------------------------------------------
lptbusy:
	push	ax
	call	lptstatus
	xor	ah,10010000b		; invert busy, select
	and	ah,10111000b		; check busy, paper, select, error
	pop	ax
	ret

;-----------------------------------------------------------------------
;	lptstatus returns parallel printer status
;	enter:	dx = printer port
;	exits:	ah = printer status
;	uses:	al
;-----------------------------------------------------------------------
lptstatus:
	inc	dx			; get to status port
	in	al,dx			; read parallel status port
	mov	ah,al
	and	ah,0f8h			; mask off unused bits
	xor	ah,048h			; invert active low signals from port
	dec	dx
	ret

;-----------------------------------------------------------------------
; Function comstatus:
;
;  Checks the status of the serial port (or buffer in $SERIAL.SYS).
;  If the transmitter holding buffer is not empty, return error code
;  indicating that fact.
;
;       Input:  DX = Serial port to check.
;       Output: AH = Printer status.
;
;-----------------------------------------------------------------------
comstatus:
        mov     ah,3            ;Get serial port status.
	int	14h
        test    ah, 20h         ;Test Xmitter holding reg. empty.
        mov     ah, ERR_STAT
        jz      comstxit        ;If not empty, return error stat.
        mov     ah, OK_STAT     ;Empty.  Character can be sent.
comstxit:
	ret

;-----------------------------------------------------------------------
;	holdstat returns cy if printer is held by a different task
;	enter:	bp = printer port
;		ss => tcb
;	exits:	cy if parallel port held by another task
;		ax = reserved status
;		nc port reserved by this task, ax destroyed
;-----------------------------------------------------------------------
	assume	ds:nothing,es:nothing,ss:tcb
holdstat:
	push	bx
	push	ds			; get scb segment
	push	ax
	mgetscb ds			; address printer reservations
	assume	ds:grp
	mov	al,bl			; get printer index
	mov	ah,scbhldlen
	mul	ah			; calc index in printer reservations
	mov	bx,ax
	mov	ax,[tcbid]		; test held by this task
	cmp	ax,scbhldtask[bx]
	je	hldsthld
	mov	ax,scbhldtick[bx]
	sub	ax,[scbtimer]		; is reservation < current counter
	mov	ax,scbhldtock[bx]
	sbb	ax,[scbtimerh]
	jb	hldsthld		; last reservation timed out
	pop	ax			; still reserved exit with cy
	mov	ah,RSVD_STAT		; and reserved status
	stc
	jmp	hldstxit
hldsthld:
	mov	ax,[tcbid]		; reserve port for this task
	mov	scbhldtask[bx],ax
	mov	ax,[scbtimer]
	add	ax,[tcbhold]
	mov	scbhldtick[bx],ax
	mov	ax,[scbtimerh]
	adc	ax,0
	mov	scbhldtock[bx],ax
	pop	ax
	clc
hldstxit:
	pop	ds
	pop	bx
	ret

;-----------------------------------------------------------------------
;	printbyte strobes the parallel port which already has the character
;	enter:	dx = port address
;	uses:	al
;-----------------------------------------------------------------------
printbyte:
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
	ret

	assume	ds:splbuff
gspsp	proc	near
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
gspsp	endp

; do21h - call int 21h with stack biasing for mos re-entrancy from apps
;	must call the current handler to allow apps which have it to handle
;	the int 21h function (i.e. lanlink for spooling on network).

do21h	proc	near
	push	[tcbstkp]		; save current tcb stack top
	mov	[tcbstkp],sp		; use current sp as stack top
	sub	[tcbstkp],80h		; bias it then call 21h handler
	int	21h
	pop	[tcbstkp]		; restore biased stack top and return
	ret
do21h	endp

mosseg	ends
	end

