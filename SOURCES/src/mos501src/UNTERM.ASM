	include page.inc
	title	unterm.asm - egna (enhance graphics network adapter)
comment ^===============================================================
		      development specification

 program name:	unterm.asm			assigned to: stewart hyde
 module name:	unterm				assign date: 03/03/89
 entry points:	egnaterm			completed:   07/10/90
 entry from:	mosint10, mosint16, mosvidrm
 entry method:	call dword [vector] with ah = function number
 calls: 	i10old (boot interrupt 10h)
 purpose:	mos interface to ali egna, vna+, vgna+
 refer to:	stewart hyde, egna doc, vnaplus doc
 last update:	12/14/92

 command link structure:
    device=unterm.sys /base,keyirq,serirq /serial definitions
		    /base2 /serial definitions /base3 /serial

 this driver is designed to work with amr's Second Generation
 video network adapters.   currently it is designed to work with
     1.  egna board which support up to 4 ega workstation (please
	 note that vnaplus daughter board can be plug into this card
	 and	vna style station can coexist on same board.
     2.  vnaplus board which supports up 8 vna+ workstations or which
	 4 of these station are permamently installed onto this board.
     3.  vgnaplus board which support up to 4 vgna+ workstations 

 this driver should also work with future vga+ boards, and hopefully
 this board should come up on this driver with out any changes.  I
 have left provisions to support this board. it is supposed to be
 similar to egna, except that it support vga stations, amr has provide
 me with prelimalary specs so that I can atleast detect this board.

 goals in designing is driver.
     1.  to provide a single driver which will work with all of amr's
	 second generation boards which have been designed so that
	 software interface (io ports) will be identicle accross the
	 boards which only board characteristics being different
     2.  designed the driver so that it can be easy for use to install
	 and	if use makes an error, to do our best in providing a
	 pinpoint on why the error occur. i have also including
	 important configuration information when driver initializes
	 at init time.
     3.  to provide a flexiable driver which will work with almost
	 unlimited number of station, by use of dynamic structures.
     4.  to provide code which is clearly written and easy to maintain
	 so that future amr boards can be added easily.
     5.  to designed the most efficient driver for best code size and
	 speed by taking advantage of 286 instructions and designing
	 code and data areas for maximun efficently.  installation
	 code is designed to be easily maintain and modulular, and also
	 designed so that it overlay with the driver data structure.
     6.  all idems for each station is place into data structure so
	 that code can be made generic so future additions and # of
	 stations is handle efficently.

=======================================================================

mjs 08/13/90	modified to use vidchk.inc and a boot_prep function.

sah 08/13/90	added code to check for tsl's ROM

bwr 8/28/90	removed tabs from message strings.

sah 09/27/90	added code to use /pa /pb ... instead of /p1 /p2....
		corrected problems with printing on fast machines (486)
		added code for corrections for paradise 16 vga

sah 10/22/90	corrections for paradise vga's, Corrections for Keyboard
		initialization.

sah 02/14/91	added corrections for amr (vnaplus.asm additiions)

sah 04/01/91	added 40:17 support

mjs 05/24/91	added printer status function.  cleaned up module.

SAH 09/11/91	Added Bios Load Logic, corrections for Multiable VGNA+
		(Hardware Problem), VGNA+ and VNA+, directly intercept
		setmode function.  Added -s option which is used to
		disable unterm calling of setmode directory. (This will
		be undocumented, just in case tech support has a problem
		out in the field)

SAH 10/14/91	Made co-existence work, added logic for 3c3h support
		(Similar to 46e8h but for different cards).  Added  -b
		option to use bios to switch VGA in and out. (This will
		be undocumented, just in case tech support has a problem
		out in the field)

SAH 10/29/91    Message Changes for released.  Also made change so that
		-C is nolonger needed....

SAH 12/18/91	Call Paradise16bit for VGA co-existence

SAH 02/25/92    Corrections for ODD# of boards on system
		No more VNA+ check

SAH 09/22/92	Corrections for Osmose, force /slashs if no VGNA+ on
		system

SAH 10/06/92	Corrections for printing problems...

SAH 10/09/92	-G option to disable hires graphics and allow pamswitching

SAH 10/13/92	Corrections with osmose problem with 2 boards

SAH 10/30/92	Corrections for kbios=yes byte clobbering beast found on
RVA		trip to buffalo NY at OSMOSE... DS reg need to be set
		to cs when call setleds

SAH 12/14/92	disable CPUSPEED for serial IRQ's
======================================================================^

include unterm.pub
include macros.inc

	subttl group segments and include block definitions
	page
.xlist
	.286				; only works on 286+ machines, so take
					; advantage of it

;-----------------------------------------------------------------------
; the following include files are definitions of the respective blocks
; the definitions do not reserve any storage by virtue of the
; segment at x construction
;-----------------------------------------------------------------------
tcb	segment at 1234h
	include mostcb.inc		; tcb definition
tcb	ends

;-----------------------------------------------------------------------
; the mosscbx include file is a file with extrn statements specified
; for all the items defined in the scb
;-----------------------------------------------------------------------
gdata	segment at 5678h
	assume	ds:gdata

	include mosscbdf.inc		; specify all scb items as external
gdata	ends

.list

;------------------------------------------------------------------------
; workstation types - these definitions specify type of workstation being
;		     installed on unterm driver.

;  work station       symbol	   ports	video
;------------------------------------------------------------------------
;  not installed     snot_install   n/a		station not installed
;  egna 	     segna	    4		ega
;  egna - hercules   segnamono      4		hercules on egna board
;  vnaplus	     svnaplus	    8		hercules only
;  vgnaplus	     svgnaplus      4		vga
;------------------------------------------------------------------------

snot_install	equ	0
segna		equ	2
segnamono	equ	1
svnaplus	equ	1
svgnaplus	equ	3

slash		equ	'/'

code	segment para public 'data'	; to force loading with data
	assume	cs:code,ds:nothing,es:nothing,ss:nothing

ddtvga	equ	this byte
	dd	-1			; filled in with pointer to next driver
	dw	8000h			; signifying a character device
	dw	strat			; device strategy entry point
	dw	inter			; device interrupt entry point
egnanm	db	'$$UNTERM'		; device name

enddrvr0 equ	$

ewsoff	 dw	offset	ofsws		; use by external egnastat.com
directptr dw	-1
speedptr  dw	offset cpuspeed

request   dd	0

	subttl strat - device driver strategy function
	page
;======================================================================
;,fs
; strat - device driver strategy function
; 
; in:	es:bx -> request header
;
; out:	
;
;,fe
;=====================================================================
	assume	ds:nothing,es:nothing,ss:nothing
strat proc far
	mov	word ptr [request],bx
	mov	word ptr [request+2],es
	ret
strat endp

	subttl intr - device driver interrupt function
	page
;======================================================================
;,fs
; intr - device driver interrupt function
;
; in:	
;
; out:	
;
;,fe
;=====================================================================
	assume	ds:nothing,es:nothing,ss:nothing
inter proc far
	push	es
	push	ds
	push	si
	push	bx
	push	ax
	mov	bx,cs
	mov	ds,bx
	assume	ds:code
	les	bx,[request]
	mov	si,es:[bx+2]
	and	si,0ffh
	or	si,si			; is this for initialization
	jnz	notinit
	call	ddtinit 		; call init  code
	jmp	short inter0
notinit:
	cmp	si,4			; is this for read
	jne	inter0
	lds	si,es:[bx+14]
	mov	cx,es:[bx+18]
	mov	word ptr es:[bx+18],0	; nothing read if error
	mov	ax,8103h		; error, done, unknown command
	cmp	cx,4
	jne	inter1			; if not reading exactly 4 bytes
	mov	es:[bx+18],cx		; else read 4 bytes
	mov	word ptr ds:[si],offset egaterm  ; and these are them
	mov	ds:[si+2],cs
inter0:
	mov	ax,0100h		; no error, done
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
inter endp

;==================== end of ddt interface code =========================

	subttl termfn - all the terminal and keyboard functions for mos
	page

tfn	dw	register
	dw	inkbdata
	dw	outkbctl
bgnvid2 equ	($-tfn)/2
	dw	setmode			; unterm's setmode function
bgnvid	equ	($-tfn)/2
	dw	0			; setcrstyp
	dw	0			; setcrspos
	dw	0			; scrollup
	dw	0			; scrolldn
	dw	0			; wrchatr
	dw	0			; setpalet
	dw	0			; wrtty
	dw	0			; wrstr
	dw	0			; setwindow
	dw	0			; wrcho
	dw	0			; readch
	dw	0			; getscr
endvid	equ	($-tfn)/2
	dw	prch
	dw	prstr
	dw	print_status
endtfn	equ	($-tfn)/2

	assume	ds:nothing,es:nothing,ss:nothing

;===================== permanent resident data ==========================

scbptr	label	dword
scbofs	dw	0			; offset of scb
scbseg	dw	0			; segment of scb
mcdcbios db	0			; a copy of the foreground's dcbios
ddtmc	dd	0			; address of master console ddt entry
saveds	dw	0
savebx	dw	0
savevid dw	0
savevram db	0
mctcb	 dw	0			; tcb for master console

; one key buffer for each workstation

kbsize	equ	32			; 32 scan codes buffered

; there are several spots within this driver hard-coded to expect this
; keyboard size.  they don't all reference the size through kbsize either.

if kbsize ne 32
	%out	kb buffer size wrong for shift count
endif

egna	struc
eaddr	dw	0			; egna port
ekeybase dw	0			; egna keyboard base address (cntrl reg)
elptbase dw	0			; egna lpt printe base address
eserial dw	0			; offset serial structure
ews	db	0			; work station for port
etype	db	0			; type of egna installed
etcb	dw	0			; register tcb
eunreg	dd	0			; previous unregister handler
kbget	dw	0			; keyboard get
kbput	dw	0			; keyboard put
keyrdy	db	0			; keyboard ready
kbstat	db	0			; keyboard status
kbbuf	db	kbsize dup (0)		; keyboard buffer
evers	db	0			; board revision
eboard	db	0			; board type
timerbase dw	0			; timer base address
egna	ends

; static information

kbirq		db	0		; keyboard irq
serirq		db	-1		; serial irq (-1 mean not available)
numport 	dw	0		; total number of egna ports
egnacur 	db	-1		; who is currently banked in
lastport	dw	-1		; last port bank in
portoff 	dw	0		; start offset of serial structures
basedxxd	dw	0d00dh		; main dxxd register
baseexxd	dw	0e00dh		; main exxd register
wsmask		db	0		; work 8259 mask

vmemcall	dd	0		; memory management handler
orig1a		dd	0 		; int 1a vector at initialization
orig38		dd	0 		; original services vector
child		dd	0      		; point to next int14 driver
tocount 	dw	182	   	; default timeout (10 seconds)
ws0ismc 	db	'Y'	  	; 'N' if master console not workstation 0
slashp		db	'N'  		; paradise not installed
slashs		db	'N'		; handle setmode internally
slashc		db	'N'		; force co-existence
slashb		db	'N'		; use bios to switch VGA
kbbios		db	'N'    		; is kbbios set
ws0vga  	db	'N'	    	; 'Y' is WS 0 is VGNA+
WSSwitch	db	'N'		; we have not switch a WS
HiResGraph	db	'Y'		; we allow hi-res graphics
SaveDSPort		dw	-1		; save DS (-1) mean not in unterm
	even
;==================== bank selection procedures =========================


	subttl setws - bank in the workstation
	page
;======================================================================
;,fs
; setws - bank in the workstation
;
; in:	al = workstation number
;
; out:	
;
;,fe
;=====================================================================
	assume	ds:nothing,es:nothing,ss:nothing
setws proc near
	cmp	al,[egnacur]
	jne	setws1
	ret
setws1:
	push	ax
	push	bx
	push	dx
	mov	[egnacur],al
	mov	dx,[lastport]
	cmp	al,-1
	je	bankout
	mov	bl,al
	xor	bh,bh
	shl	bx,1
	add	bx,offset ofsws
	mov	bx,cs:[bx]		; get structure offset
	mov	dx,cs:[bx].eaddr	; get port address
	add	dl,0fh
	mov	al,cs:[bx].ews
	out	dx,al			; switch station
	cmp	dx,[lastport]		; same port as last time
	je	skipout
	xchg	dx,[lastport]		; exchange ports

; bank out previous work station				 

bankout:
	cmp	dx,-1
	je	skipout
	mov	al,0fh
	out	dx,al			; switch out last port
skipout:
	pop	dx
	pop	bx
	pop	ax
	ret
setws endp 


	subttl bankin - bank in the workstation 
	page
;======================================================================
;,fs
; bankin - bank in the workstation 
;
; if the currently selected workstation is the one needed, then just
; return, else, use scblastdd to bankout the workstation that is
; currently in before selecting the one needed.  if the currently
; selected workstation is another vgna workstation then here is no need
; to call the fe function of the ddt which is in scblastdd.  in this
; case, one call to setws will bank out the current wks and bank in the
; new one.
;
; in:	ds:si -> tcbddt
;
; out:	
;
;,fe
;=====================================================================
	assume	ds:nothing,es:nothing,ss:nothing
bankin proc near
	push	ax
	push	bx
	push	di
	push	es
	pushf				; save current interrupt flag setting
	cli				; secure against irq's that switch video
	les	di,[scbptr]
	mov	ax,ds
	cmp	ax,es:[di.scblastff]	; is this workstation already selected?
	je	bankin3
	cmp	es:[di.scblastff],0
	jz	bankin2 		; if scblastff == 0, nobody needs banked out

; is this driver's entry point the same as that of the
; last workstation selected?

	push	es
	mov	es,es:[di.scblastff]
	assume	es:tcb
	mov	ax,word ptr [tcbcondd]
	mov	bx,word ptr [tcbcondd+2]
	pop	es
	assume	es:nothing
	cmp	ax,[si]
	jne	bankin1
	cmp	bx,[si+2]
	je	bankin2

; when the last workstation banked in has a different driver entry point,
; then make an fe call to the last driver banked in to get it banked out.
; otherwise, it is presumed that banking in the new workstation will
; automatically bank out the previous one.

bankin1:
	push	si
	push	ds
	mov	ds,es:[di.scblastff]	; call the ddt at scblastff:tcbcondd
	mov	si,offset [tcbcondd]
	mov	ah,0feh
	call	dword ptr [si]
	cmp	[ws0ismc],'Y'
	je	bankin1b
bankin1a:
	push	dx
	mov	al,06h
	mov	dx,46e8h	; diable master console using 46e8h
	out	dx,al
	xor	al,al
	mov	dx,3c3h		; diable master console using 3c3h
	out	dx,al
	pop	dx
bankin1b:
	pop	ds
	pop	si

; bank in the new workstation and update scblastff
; so the next ff call to a ddt will know who to bank out.

bankin2:
	mov	al,byte ptr [si].port
	call	setws
	mov	es:[di.scblastff],ds	; record this ddt in scblastff
bankin3:
	popf				; restore interrupt flag state
	pop	es
	pop	di
	pop	bx
	pop	ax
	ret
bankin endp 


	subttl egaterm - entry point for ddt calls
	page
;======================================================================
;,fs
; egaterm - entry point for ddt calls
;
; off to master console ddt if
;   workstation 0 and master console is workstation 0
;   or if a video function
; else handle it in ega ddt
;
; in:	
;
; out:	
;
;,fe
;=====================================================================
	assume	ds:nothing,es:nothing,ss:nothing

	even
	db	' '
	db	'EGA'
egaterm proc far
	mov	cs:[SaveDSPort],ds
	cld
	sti
	cmp	ah,0feh
	jne	egnafj00
	mov	al,-1
	pushf
	cli
	call	setws
	popf
	mov	cs:[saveDSPort],-1
	jmp	egnafnx

; 0ffh is a special function to bank in a workstation

egnafj00:
	cmp	ah,0ffh
	jne	egnafn1
	call	bankin

; now, call ddtmc's ff handler to insure that the video display ram is exposed

	push	di
	push	es
	les	di,[scbptr]
	call	ddtmc			; ah should still be 0ffh
	pop	es
	pop	di
	jmp	short egnafnx

; for all video functions - pass the call onto ddtmc
; also, pass to ddtmc when not a video function but the port is 0 and the
; master console is a egna workstation
; otherwise, process locally

; one exception is when a 7 is written to function 0a and an iona card is
; installed.  if the beep call vector isn't even pointing to the beep procedure
; then skip ahead.  also skip if dealing with the master console.

egnafn1:
	cmp	ah,endtfn
	jae	egnafn3a
	cmp	ax,0a07h		; is this beep
	jne	egnafn1a
	cmp	[ws0ismc],'Y'
	jne	dobeeper
	cmp	byte ptr [si].port,0	; if not master console - ignore it
	je	egnafn1a
dobeeper:
	call	beeper
	jmp	short egnafnx
egnafn1a:
	cmp	ah,bgnvid
	jb	egnafn2
	cmp	ah,endvid
	jb	egnafn3
egnafn2:
	cmp	[slashs],'N'		; using internal setmode
	je	egnafn2a
	cmp	ah,bgnvid2		; is this setmode call
	je	egnafn3			; if so, call ddtmc setmode	
egnafn2a:
	cmp	[ws0ismc],'Y'
	jne	egnafn4 		; ws0 not master console

	cmp	byte ptr [si].port,0
	jne	egnafn4 		; not ws0
	cmp	ah,10h
	je	egnafn4 		; the print routines are an except - so
	cmp	ah,11h			; the master console could used an egna
	je	egnafn4 		; parallel port if desired.

; process a video function

egnafn3:
	cmp	ah,4			; for set cursor type or set cursor
	jb	egnafn3b		; position, must bank in the right
	cmp	ah,5			; workstation first
	ja	egnafn3b
egnafn3a:
	call	bankin
egnafn3b:
	push	si
	call	ddtmc			; when ddtmc calls exposreal, the
	pop	si			; ddt function ff which will come back
	jmp	short egnafnx		; to this ddt first

; process non-video functions locally

egnafn4:
	push	bp
	mov	bp,bx
	mov	bl,ah
	cmp	bl,endtfn
	jae	egnafn5
	xor	bh,bh
	shl	bx,1
	xchg	bx,bp
	push	ds
	push	si
	call	tfn[bp]			 
	pop	si
	pop	ds
egnafn5:
	pop	bp
egnafnx:
	ret
egaterm endp

	subttl beeper - activate the workstation beeper
	page
;======================================================================
;,fs
; beeper - activate the workstation beeper
;
; the following will send the closest sound that could
; resemble and chr(7) bell on pc, this routine will
; sound interface units internal beeper when chr(7) is
; send to terminate to be displayed.  it has been
; designed so that system resources will not be wasted
; when waiting to turn off beeper.
;
; in:	
;
; out:	
;
;,fe
;=====================================================================
	assume	ds:tcb,es:nothing,ss:nothing
beeper proc near
	push	ax
	push	bx
	push	cx
	push	dx
	mov	bl,byte ptr [si].port
	xor	bh,bh
	shl	bx,1
	add	bx,offset ofsws 	; point to desired egna structure
	mov	bx,cs:[bx]		; get structure offset
	mov	dx,cs:[bx].timerbase	; access timer registers
	mov	al,3
	out	dx,al
	push	dx
	mov	al,[tcbsiorb]		; save the state of the road block flag
	push	ax			; and reset it so its possible to pam
	mov	[tcbsiorb],0		; away from a task waiting for a busy printer
	mov	ax,0702h
	mov	bx,1			; suspend for one tick before
	pushf				; trying again
	call	[orig38]
	pop	ax
	mov	[tcbsiorb],al
	pop	dx
	xor	al,al
	out	dx,al
	pop	dx
	pop	cx
	pop	bx
	pop	ax
	ret
beeper endp



	subttl setmode - set terminal mode
	page
;======================================================================
;,fs
; setmode - set terminal mode
;
; in:	ah = 03h
;	al = 00h, 01h - 40x25 text
;	     02h, 03h, 07h - 80x25 text
;	     04h, 05h - 320x200 graphics
;	     06h - 640x200 graphics
;	     80h - set hercules graphics mode
;	bit 6 selects herc page!!
;	if bit 5 is set, set mode but don't clear video ram
;	ds:si -> tcbddt
;	[tcbddt] = dword -> screen buffer
;
; out:	
;
;,fe
;=====================================================================

	assume	ds:tcb,es:nothing,ss:nothing
setmode proc near
	cmp	[si].dcpherc,'Y'
	je	setvna
	cmp	[HiResGraph],'Y'
	je	smok
	cmp	al,07			
	jbe	smok			; EGA / VGA mode
	mov	al,3			; force it to mode 3
smok:
	push	si
	call	ddtmc
     	pop	si
	ret
	
setvna:
	call	bankin			; switch workstation in
;
	push	di
	push	es
	les	di,[scbptr]
	call	ddtmc			; ah should still be 0ffh
	pop	es
	pop	di
;
	push	ax
	push	es
	push	di
	les	di,[scbptr]
	assume	es:gdata
	test	es:[di.scbmmfea],40h		; io protection
	jz	nonio
	push	dx
	les	di,[di.scbmmptr]		; get pointer to memman data
	assume	es:nothing
	les	di,dword ptr es:[di].parmiop
	mov	dx,es:[di+118]
	and	word ptr es:[di+118],not 1000010100110000b  ;3b8,3ba,3bf,3b4,3b5
	push	dx
	push	di
	push	es
	call	dosetmode
	pop	es
	pop	di
	pop	dx
	mov	es:[di+118],dx
	pop	dx
	jmp	short endio
nonio:
	call	dosetmode
endio:
	pop	di
	pop	es
	pop	ax
	assume  es:nothing
	ret
setmode endp

dosetmode proc	near
	mov	cl,al
	and	cl,00100000b
	shl	cl,2			; cl == 80h if bit 5 was set in entry al
	and	al,11011111b
	and	cl,80h			

; here if hercules card present

	cmp	al,4	
	jb	setm0b
	cmp	al,7
	jb	setm0a			; virtual cga graphics sets hercules mode
	je	setm0b
	test	al,80h
	jz	setm0b
	test	[si].dcmode,80h
	jz	setm0a

;setting hercules page

	and	al,40h			; set relevant page
	and	[si].dcmode,not 40h
	or	[si].dcmode,al
	mov	dx,03b8h
	shl	al,1
	or	al,0ah
	out	dx,al
	ret
setm0a:
	mov	[si].dcvmode,al 	; virtual mode
	mov	[si].dcmode,80h 	; in hercules mode
	call	setherc
	ret
setm0b:
	and	al,7fh
	push	ax
	push	cx
	call	setmono
	pop	cx
	pop	ax
	mov	[si].dcmode,7
	mov	[si].dcvmode,al
	ret
dosetmode endp

	subttl setmono - initializes one video controller to monochrome mode
	page
;======================================================================
;,fs
; setmono - initializes one video controller to monochrome mode
;
; in:	
;
; out:	
;
;,fe
;=====================================================================
	assume	ds:nothing,es:nothing,ss:nothing

monotbl db	20h
	db	61h,50h,52h,0fh,19h,06h,19h,19h,02h,0dh,0bh,0ch
	db	00h,00h 		; start offset 0
	db	07h,0d0h		; cursor offset 2000 (80*25)
	db	28h

; video values for hercules mode

herctbl db	02h			; 3b8h control code
	db	35h,2dh,2eh,07h,5bh,02h,57h,57h,02h,03h,00h,00h
	db	00h,00h 		; start offset 0
	db	07h,0d0h		; cursor offset 2000 (80*25)
	db	0ah			; 3b8h control code



setmono proc near
	push	es
	push	ds
	push	si
	push	cs
	pop	ds
	mov	si,offset monotbl
	xor	al,al			; disable graphics and page 1
	mov	bx,0720h		; value to clear
	mov	cx,80*25		; words to clear
sethcard:
	mov	dx,3bfh
	out	dx,al			; enable graphics, disable page 1
	mov	dx,03b8h
	lodsb
	out	dx,al			; setting new mode, but turning off 6845
	xor	ah,ah
	mov	dx,03b4h
	push	cx
	mov	cx,16			; setting all 6845 registers for new mode
sethrc1:
	mov	al,ah
	out	dx,al
	jmp	$+2
	inc	dx
	lodsb
	out	dx,al
	dec	dx
	inc	ah
	loop	sethrc1
	pop	cx
	mov	ax,0b000h		; clearing to spaces
	mov	es,ax
	xor	di,di
	mov	ax,bx
	cld
	rep	stosw
	mov	dx,03b8h
	lodsb
	out	dx,al			; turn 6845 on in new mode

	pop	si
	pop	ds
	pop	es
	ret
setmono endp 

	subttl setherc - set hercules card to hercules graphics mode
	page
;======================================================================
;,fs
; setherc - set hercules card to hercules graphics mode
;
; in:	
;
; out:	
;
;,fe
;=====================================================================
	assume	ds:tcb,es:nothing,ss:nothing
setherc proc near
	push	es
	push	ds
	push	si

; only allow 2nd display page if master console is hercules-capable
; else we assume that master console is a cga and requires b800

	mov	al,3
	mov	cx,32768
	cmp	[tcbcondd.dcpherc],'Y'
	je	seth1			; e if master console is hercules capable

; since the master console is not hercules capable, the master console
; must be hidden in order for the 2nd hercules page to be usable.
; since exposreal was called on entry to this function, if the
; master console is hideable, it is presumed to be hidden now

	test	[tcbcondd.dcbios],1	; is mc hideable?
	jnz	seth1
	shr	al,1			; shift the i/o data
	shr	cx,1			; cut the byte count in half
seth1:
	push	cs
	pop	ds
	mov	si,offset herctbl
	xor	bx,bx			; value to clear
	jmp	sethcard
setherc endp

	subttl register - register port address, receive key buffer flag
	page
;======================================================================
;,fs
; register - register port address, receive key buffer flag
;
; in:	ah = 00h
;	es:bx -> scbmapvmf
;	dx = port address
;	ds:si -> tcbddt for this terminal for this partition
;
; out:	es:bx -> key buffer flag
;	 key buffer flag is <> 0 while scan codes are buffered
;	al = 80h if master console
;	   = 00h if not master console
;	ah = 00h cause no error can happen
;
;,fe
;=====================================================================
	assume	ds:nothing,es:nothing,ss:nothing
register proc near
	mov	ah,0ffh
	mov	bl,byte ptr [si].port
	xor	bh,bh

; check to see if task has allready been register
; if so return error

	shl	bx,1
	push	bx
	add	bx,offset ofsws 	; point to desired egna structure
	mov	bx,cs:[bx]		; get structure offset
	mov	al,cs:[bx].etype	; get workstation type
	cmp    	word ptr cs:[bx].etcb,-1
	pop	bx
	je     	reg0b
	jmp    	regsx
reg0b:
	mov    	[saveds],ds	; save pointer to tcb
	mov    	[savebx],bx	; save port pointer for later
	cmp	al,svnaplus
	je	regvna

; setup ddt for egna or vgna plus workstation

	mov	al,3
	cmp	cs:[HiResGraph],'Y'
	je	reghires
	xor	al,al
reghires:
	mov	[si].dcbios,al

	mov	[si].dcpherc,'N'
	mov	[si].dcpcrs,25*256
	mov	[si].dcpcol,80
	mov	[si].dcpscrl,80*25*2
	mov	[si].dcsnow,0
	mov	[si].dcmode,3
	mov	[si].dcvmode,3
	mov	[si].dcaddr,03d4h
	mov	[si].dcpscr,0b800h
	mov	[savevid],0b800h
	mov	[savevram],0ech
	jmp	short regcont
regvna:


comment  |
; test for tsl rom, this check has been removed!!!!!!

	push	es
	push	di
	les	di,[scbptr]
	cmp	byte ptr es:[di.scbvnasys],'Y'
	pop	di
	pop	es
	je	regvna1
	jmp	regsx			; error out
	|

regvna1:


; setup ddt for vnaplus station hercules

	mov	[si].dcpherc,'Y'
	mov	[si].dcmode,7
	mov	[si].dcvmode,7
	mov	[si].dcpcrs,25*256
	mov	[si].dcpcol,80
	mov	[si].dcaddr,03b4h
	mov	[si].dcpscr,0b000h
	mov	[si].dcpscrl,80*25*2
	mov	[si].dcbios,0
	mov	[si].dcsnow,0
	mov	[savevid],0b000h
	mov	[savevram],98h
regcont:

; now setup wsmask which can be use to set 8259 mask
; ws 1 is 1, ws 2 is 2, ws 3 is 4

	mov	bx,cs
	mov	ds,bx
	mov	bx,[savebx]
	add	bx,offset ofsws
	mov	bx,[bx]
	mov	al,1
	mov	cl,[bx].ews
	cmp	[ws0ismc],'Y'
	jne	dontupit
	push	dx
	push	bx
	mov	dx,[bx].eaddr
	mov	bx,offset ofsws
	mov	bx,[bx]
	cmp	dx,[bx].eaddr
	pop	bx
	pop	dx
	jne	dontupit
	inc	cl
dontupit:
	cmp	cl,1
	je	regws
	dec	cl
	shl	al,cl
regws:
	mov	[wsmask],al
	mov	cx,4
regs0:
	push	ds
	push	si
	push	cx
	mov	bx,cs
	mov	ds,bx
	mov	bx,[savebx]
	add	bx,offset ofsws
	mov	si,word ptr [bx]

; si -> egna structure when calling initkb

	call	initkb			; returning ah = 0ffh if error
	pop	cx
	pop	si
	pop	ds
	or	ah,ah
	loopnz	regs0
	or	ah,ah
	jnz	regsbad
	mov	cx,cs
	mov	es,cx

; update save unregister and set tcbunreg to our routine
; indicated that port is register to tcb pass to us

	push	si
	push	di
	push	bx
	push	ds
	push	es
	mov	bx,[savebx]		; get savebx
	mov	ax,[saveds]
	mov	si,offset ofsws
	mov	si,cs:[si+bx]
	mov	word ptr cs:[si].etcb,ax; register task
	mov	ds,ax
	assume	ds:tcb
	mov	ax,word ptr [tcbunreg]
	mov	word ptr cs:[si].eunreg,ax
	mov	ax,word ptr [tcbunreg+2]
	mov	word ptr cs:[si+2].eunreg,ax
	mov	word ptr [tcbunreg],offset unregister
	mov	word ptr [tcbunreg+2],cs
	mov	word ptr [tcbvidset],offset vidinit
	mov	word ptr [tcbvidset+2],cs

; initialized time port

	push	dx
	mov	dx,cs:[si].timerbase
	sub	dx,2000h		; access time control registers
	mov	al,0b6h
	out	dx,al
	jmp	$+2
	dec	dx
	mov	al,33h
	out	dx,al
	jmp	$+2
	mov	al,5
	out	dx,al
	pop	dx
	pop	es
	pop	ds
	assume	ds:nothing
	pop	bx
	pop	di
	pop	si
	xor	ah,ah
	jmp	short regsx
regsbad:
	mov	ah,0ffh
regsx:
	mov	al,[savevram]		; graphics and mc and ali
	mov	cx,[savevid]		; physical buffer address (stuffed into
	ret				;   tcbvidad)
register endp 


	subttl vidinit - initialized video areas for workstation
	page
;======================================================================
;,fs
; vidinit - initialized video areas for workstation
;
; in:	
;     ES-> TCB
;
; out:	
;
;,fe
;=====================================================================
	assume	cs:code,ds:nothing,es:tcb,ss:nothing
VidInit proc	far
	push	ax
	push	bx
	push	si
	push	ds

	mov	si,offset [tcbcondd]
	mov	bl,byte ptr [si].port
	xor	bh,bh
	shl	bx,1
	mov	si,offset ofsws
	mov	bx,cs:[si+bx]
	mov	al,cs:[bx].eboard
	cmp	al,svgnaplus
	jne	VINotVGNA
;
;	handle logic for VGNA+ Initialization
;
	xor	ax,ax
	mov	ds,ax
;
; Set INT 1dh vector to c000:0090h
;
	mov	word ptr ds:[1dh*4],0090h
	mov	word ptr ds:[1dh*4+2],0c000h
;
; Set INT 1fh vector to c000:0fb0h
;
	mov	word ptr ds:[1fh*4],00fb0h
	mov	word ptr ds:[1fh*4+2],0c000h
;
; Set INT 43h vector to c000:0bb0h
;
	mov	word ptr ds:[43h*4],00bb0h
	mov	word ptr ds:[43h*4+2],0c000h
;
; Set INT 6dh vector to c000:073f2h
;
	mov	word ptr ds:[6dh*4],073f2h
	mov	word ptr ds:[6dh*4+2],0c000h
;
; Set dword at 40:a8h to c000:43f0h
;
	mov	word ptr ds:[04a8h],043f0h
	mov	word ptr ds:[04aah],0c000h
VINotVGNA:
	pop	ds
	pop	si
	pop	bx
	pop	ax
	ret
VidInit endp


	include vidchk.inc

	subttl 
	page
;======================================================================
;,fs
; boot_prep - prepare the video state for a reboot
;
; in:	
;
; out:	
;
;,fe
;=====================================================================
	assume	cs:code,ds:nothing,es:nothing,ss:nothing
boot_prep proc near
	xor	ax,ax			; switch forground in
	cmp	[ws0ismc],'Y'
	je	vc2
	mov	al,-1
vc2:
	call	setws
	call	HandleCoRes		; handle co-resident case
	ret
boot_prep endp 

	subttl keybd_irq - process a keyboard irq
	page
;======================================================================
;,fs
; keybd_irq - process a keyboard irq
;
; outline on keyboard irq program logic
;    1.  ouput a 0 to dxxd register to disable interupt to the at bus
;    2.  setup to point to first board on system
;    3.  input from status register 0xxc of current board
;    4.  is bit 6 a logical 1? if no then goto to step 6
;    5.    service local keyboard interupt as follows
;		a. input from 0xxa twice
;		b. use the value read on the second input command to
;		  determine which keyboard port cause the interupt
;		c. serivice the keyboard port
;		d. issue eoi to board being service
;    6.  if bit 4 of status register is logica 0 then step 8
;    7.    point to next board on system and goto to step 3
;    8.  issue eoi to the motherboard pic (20h and a0h)
;    10. output a 1 to exxd register to enable interupt from at bus
;
; note: future additions will alter method of servicing so that we find
; out exactly which interupts have fire from 8259 and service each one.
; this will allow us to service more than just the highest priority
; interuppt on the system.
;
; in:	
;
; out:	
;
;,fe
;=====================================================================
	assume	ds:nothing,es:nothing,ss:nothing
keybd_irq proc far
	push	ax
	push	bx
	push	cx
	push	dx
	push	si
	push	di
	push	ds
	push	es
	mov	ax,cs
	mov	ds,ax			; make ds point to cs
	assume	ds:code
	xor	al,al
	mov	dx,[basedxxd]
	out	dx,al			; disable interupts to at bus

; setup bx to point to first egna structure on system

	mov	bx,[directptr]

; this is code which next board will loop back to

keybd_loop:
	mov	si,word ptr [bx]
	mov	dx,[si].eaddr
	add	dl,0ch			; point to status register
	in	al,dx
	test	al,40h			; has keyboard port interupted
	jz	keybd_next		; no...then try next board

; at this point we know that keyboard port has interuptted

	sub	dl,2			; point int ack register
	in	al,dx
	jmp	$+2
	jmp	$+2			; delay for faster 386 / 486 cpus
	jmp	$+2
	in	al,dx

; first we need to validated that interupt is in range

	mov	dx,[si].eaddr
	mov	cx,bx			; save tbl ptr
	xor	ah,ah			
	add	bx,ax			; index forward to correct slot
	add	bx,ax
	mov	si,word ptr [bx]	; get correct egna ptr
	mov	bx,cx
	cmp	si,-1			; port not defined?
	je	keybd_skip		;   yes
	cmp	dx,[si].eaddr		; same board?
        jne	keybd_skip		;   no

; at this point we know which station has fire and point to
; station's EGNA buffer.

	mov	dx,[si].ekeybase	; point to keyboard base (cntrl reg)
	call	keybd			; call keyboard service routine

; issue eoi for this board

keybd_skip:
	mov	si,word ptr [bx]
	mov	dx,[si].eaddr
	add	dl,8
	mov	al,20h
	out	dx,al

; now we will check to see if there is another interupt on chain
; please note at this point, this logic has been designed so
; that dx -> base address

keybd_next:
	mov	si,word ptr [bx]
	mov	dx,[si].eaddr		; set to base
	add	dl,0ch			; point to status register
	in	al,dx			; read status register
	test	al,10h			; do we have another interupt in chain
	jz	keybd_end

; at this point we must setup bx so it is pointing to next work station
; in chain

	add	bx,4*2			; set up for egna or vgna+ style boards
	cmp	[si].eboard,svnaplus
	jne	keybd_novna
	add	bx,4*2
keybd_novna:
	jmp	keybd_loop

; now send eoi first to primary and then to secondary 8259 on
; main motherboard.

keybd_end:
	mov	al,20h
	out	20h,al			; set eoi to primary 8259
	jmp	$+2
	out	0a0h,al 		; set eoi to secondary 8259
	mov	al,1
	mov	dx,[basedxxd]
	out	dx,al			; enable interupts to at bus
	assume	ds:nothing
	pop	es
	pop	ds
	pop	di
	pop	si
	pop	dx
	pop	cx
	pop	bx
	pop	ax
	iret
keybd_irq endp

	subttl keybd - keyboard service routine
	page
;======================================================================
;,fs
; keybd - keyboard service routine
;
; keybd - this is the stations keyboard handler, it will put the
; the key scan codes into the driver 32 byte keyboard buffer in
; task information table.
;
; in:	si = points to egna data structure
;	dx = points to keyboard control register
;
; out:	
;
;,fe
;=====================================================================
	assume	ds:nothing,es:nothing,ss:nothing
keybd proc near
	push	bx
	mov	cx,8000h
kbd1:
	in	al,dx
	test	al,2			; outfull full
	loopnz	kbd1
	dec	dx
	in	al,dx			; get data
	inc	dx
	cmp	al,0fah 		; achnolodge
	jb	kbd3			; < fa is ok
	je	kbd2			; = fa is skip
	cmp	al,0feh 		; resend
	jb	kbd3			; fa > x < fe is ok
kbd2:					; fe, ff is skip
	jmp	short kbover
kbd3:
	cmp	byte ptr [si].keyrdy,00h; any characters
	je	kbempty
	mov	cx,word ptr [si].kbget
	cmp	cx,word ptr [si].kbput	; overflow in buffer
	je	kbover
kbempty:
	mov	byte ptr [si].keyrdy,0ffh  ; flag keyboard ready flag
	mov	di,word ptr [si].kbput	; get point to que
	mov	cx,si
	add	si,di
	mov	byte ptr [si].kbbuf,al
	mov	si,cx
	inc	di
	cmp	di,kbsize		; test to see if over limit
	jb	kbset
	xor	di,di
kbset:
	mov	word ptr [si].kbput,di	; save new pointer
	cmp	[kbbios],'Y'
	je	kbover
	call	doleds			; handle leds
kbover:
	pop	bx
	ret
keybd endp 

	subttl doleds - set the keyboard status leds
	page
;======================================================================
;,fs
; doleds - set the keyboard status leds
;
; done by checking the 40:17 status save in the tcb as
; tcbkshft (this is necessary because keyboard irq could and will get
; get call when another task is switch into memory).  if status is
; is different that prevous saved status, then the routine will access
; memory map area to change the leds.
;
; in:	si = pointer to vgna structure
;	dx = keyboard status port
;
; out:	
;
;,fe
;=====================================================================
	assume	ds:nothing,es:nothing,ss:nothing
doleds proc near
	mov	cx,es
	mov	es,word ptr [si].etcb
	assume	es:tcb
	mov	al,tcbkshft		; get keyboard status
	mov	es,cx
	call	setleds 		; call lowlevel 40:17 stuff
	ret
doleds endp

	subttl setleds - lowlevel 40:17 support
	page
;======================================================================
;,fs
; setleds - lowlevel 40:17 support
;
; in:	al = value at 40:17
;	si = pointer to vgna structure
;	dx = keyboards status port
;
; out:	
;
;,fe
;=====================================================================
	assume	ds:nothing,es:nothing,ss:nothing
setleds proc near
	shr	al,4			; format it for the output
	and	al,7			; to keyboard
;	shr	di,1		;??? old code ???
	cmp	al,byte ptr [si].kbstat ; same as saved?
	jne	dleds
;	shl	di,1		;??? old code ???
	ret
dleds:

; we must now change the keyboard leds

	pushf
	cli
	mov	byte ptr [si].kbstat,al
	dec	dx
	mov	al,0edh
	call	outdata
	inc	dx
	mov	cx,-1
kaloop:
	call	getkey			; get data
	cmp	al,0fah 		; is it ack
	je	kaexit
	dec	cx
	jnz	kaloop			; loop if not
kaexit:
	dec	dx
	mov	al,byte ptr [si].kbstat
	call	outdata
	out	dx,al
	inc	dx
	mov	cx,-1
kaloop2:
	call	getkey			; get data
	cmp	al,0fah 		; is it ack
	je	kaexit2
	dec	cx
	jnz	kaloop2 		; loop if not
kaexit2:
	popf
	ret
setleds endp

	subttl initkb - initialize keyboard controller
	page
;======================================================================
;,fs
; initkb - initialize keyboard controller
;
; used to initialize the stations keyboard controller so
; that it will send scan codes to host adapter which will generate
; irq so that driver can place the scan code into the keyboard buffer
;
; in:	si = egna structure
;
; out:	
;
;,fe
;=====================================================================
	assume	ds:nothing,es:nothing,ss:nothing
initkb proc near

; now clear keyboard 8259

	push	dx
	mov	dx,[si].eaddr
	add	dx,9
	in	al,dx
	jmp    	$+2
	jmp	$+2
	jmp	$+2
	or	al,[wsmask]		; or in mask for workstation
	out	dx,al
	jmp	$+2
	jmp	$+2
	jmp	$+2
	pop	dx

; now initialize keyboard

	push	cx
	push	dx
	mov	dx,[si].ekeybase
	mov	al,0aah
	call	outcmd			; send 0aah to keyboard
	cmp	ax,-1
	je	erroraa
	call	get55			; get keyboard input
	cmp	al,055h
	je	setup8042
	call	get55
	cmp	al,055h
	je	setup8042
erroraa:
	jmp	errorkb
setup8042:

; setup 8042 command byte

	mov	al,060h
	call	outcmd
	cmp	ax,-1
	je	errorkb 		; error initing keyboard
	dec	dx
	mov	al,45h
	call	outdata
	cmp	ax,-1
	je	errorkb 		; error initing keyboard
	inc	dx
	call	getkey

; if you got an 0xfe back try a keyboard reset 0xff command
; to the keyboard

	cmp	al,0feh
	jnz	go_ahead
send_ff:
	xor	ax,ax			; ax=0x00ff
	not	al
	dec	dx
	call	outdata
	inc	dx
	cmp	ax,-1
	je	errorkb
go_ahead:
	dec	dx
	mov	al,0edh
	call	outdata
	cmp	ax,-1
	je	errorkb 		; error initing keyboard
	inc	dx
	mov	cx,4
gkeylp1:
	call	getfa
	je	gkeyok1
	loop	gkeylp1
	jmp	short errorkb
gkeyok1:
	dec	dx
	xor	al,al
	call	outdata
	cmp	ax,-1
	je	errorkb 		; error initing keyboard
	inc	dx
	mov	cx,4
gkeylp2:
	call	getfa
	cmp	al,0fah
	je	initkba
	loop	gkeylp2
errorkb:
	pop	dx
	pop	cx
	mov	ax,0ffffh
	ret
initkba:

; now set up keyboard 8259

	mov	dx,[si].eaddr
	add	dx,9
	mov	ah,[wsmask]
	not	ah
	in	al,dx
	jmp	$+2
	jmp	$+2
	and	al,ah
	out	dx,al
	jmp	$+2
	jmp	$+2

; now setup up serial 8259 to make sure that that it can fire also

	cmp	[si].eserial,0		; if no buffer, don't init
	je	skips8259		; serial 8259
	add	dx,1000h
	in	al,dx
	jmp	$+2
	jmp	$+2
	and	al,ah
	out	dx,al
	jmp	$+2
	jmp	$+2
skips8259:

	pop	dx
	pop	cx

	xor	ax,ax

; now initialize keyboard data areas

	cli
	mov	[si].kbget,ax
	mov	[si].kbput,ax
	mov	[si].keyrdy,al		; no keys yet
	sti
	lea	bx,[si].keyrdy
	ret
initkb endp

	subttl outcmd - output commands to kybd controller
	page
;======================================================================
;,fs
; outcmd - output commands to kybd controller
;
; in:	
;
; out:	
;
;,fe
;=====================================================================
	assume	ds:nothing,es:nothing,ss:nothing
outcmd proc near
	push	cx
	mov	cx,1000h
	mov	ah,al
ocloop:
	in	al,dx
	test	al,2
	loopnz	ocloop
	or	cx,cx
	jz	ocexit
	mov	al,ah
	out	dx,al
	mov	cx,1000h
ocloop2:
	in	al,dx
	test	al,2
	loopnz	ocloop2
	pop	cx
	ret
ocexit:
	mov	ax,-1
	pop	cx
	ret
outcmd endp

	subttl outdata - output to kybd controller
	page
;======================================================================
;,fs
; outdata - output to kybd controller
;
; in:	
;
; out:	
;
;,fe
;=====================================================================
	assume	ds:nothing,es:nothing,ss:nothing
outdata proc near
	push	cx
	inc	dx
	mov	cx,1000h
	mov	ah,al
odloop:
	in	al,dx
	test	al,2
	loopnz	odloop
	or	cx,cx
	jz	odexit
	dec	dx
	mov	al,ah
	out	dx,al
	pop	cx
	xor	ah,ah			; make sure ah=0 if sucessfull
	ret
odexit:
	mov	ax,-1			; error
	pop	cx
	ret
outdata endp

	subttl getkey - read kybd controller
	page
;======================================================================
;,fs
; getkey - read kybd controller
;
; in:	
;
; out:	
;
;,fe
;=====================================================================
	assume	ds:nothing,es:nothing,ss:nothing
getkey proc near
	push	cx
	mov	cx,100h
gkloop:
	in	al,dx
	test	al,1
	loopz	gkloop
	mov	ax,-1
	or	cx,cx
	jz	gkexit
	xor	ah,ah
	dec	dx
	in	al,dx
	inc	dx
gkexit:
	pop	cx
	ret
getkey endp

	subttl getch - 
	page
;======================================================================
;,fs
; getch - 
;
; in:	
;
; out:	
;
;,fe
;=====================================================================
	assume	ds:nothing,es:nothing,ss:nothing
getch proc near
	push	ds
	push	bx
	xor	ax,ax
	mov	ds,ax
	mov	bx,word ptr ds:[46ch]
gkloop2:
	in	al,dx
	test	al,1
	jnz	gkfound
gkloop3:
	mov	ax,word ptr  ds:[46ch]
	sub	ax,bx
	cmp	ax,10			; wait abort 1/2 second
	jb	gkloop2
	mov	ax,-1
	cmp	al,cl
	jmp	short gkout
gkfound:
	dec	dx
	in	al,dx
	inc	dx
	cmp	al,cl
	jne	gkloop3
gkout:
	pop	bx
	pop	ds
	ret
getch endp

	subttl getfa - 
	page
;======================================================================
;,fs
; getfa - 
;
; in:	
;
; out:	
;
;,fe
;=====================================================================
	assume	ds:nothing,es:nothing,ss:nothing
getfa proc near
	push	cx
	mov	cl,0fah
	call	getch
	pop	cx
	ret
getfa endp

	subttl get55 - 
	page
;======================================================================
;,fs
; get55 - 
;
; in:	
;
; out:	
;
;,fe
;=====================================================================
	assume	ds:nothing,es:nothing,ss:nothing
get55 proc near
	push	cx
	mov	cl,055h
	call	getch
	pop	cx
	ret
get55 endp

	subttl unregister - called during task removal
	page
;======================================================================
;,fs
; unregister - called during task removal
;
; in:	ds -> tcb of task
;
; out:	
;
;,fe
;=====================================================================
	assume	ds:nothing,es:nothing,ss:nothing
unregister proc far
	push	bx
	push	si
	push	ds
	mov	si,offset [tcbcondd]
	mov	bl,byte ptr [si].port
	xor	bh,bh
	shl	bx,1
	mov	si,offset ofsws
	mov	bx,cs:[si+bx]
	xor	ax,ax
	mov	cs:[bx].kbget,ax
	mov	cs:[bx].kbput,ax
	mov	cs:[bx].keyrdy,al	; no keys yet
	mov	word ptr cs:[bx].etcb,-1; unregister
	cmp	word ptr cs:[bx+2].eunreg,0  ; end of list
	je	unr1
	call	dword ptr cs:[bx].eunreg; chain it
unr1:
	pop	ds
	pop	si
	pop	bx
	ret
unregister endp

	subttl inkbdata - input keyboard scan code
	page
;======================================================================
;,fs
; inkbdata - input keyboard scan code
;
; in:	ah = 01h
;	ds:si -> tcbddt
;	cx == dx and dh == -1 implies:
;          the kernel understands KBBIOS support, and thus:
;	      dl = desired LED state
;
; out:	al = bit 7   - key break if 1, key make or key repeat if 0
;	     bits 6-0 - key scan code 01h - 07dh
;	key scan code is read non-destructively
;
;,fe
;=====================================================================
	assume	ds:nothing,es:nothing,ss:nothing
inkbdata proc near
	mov	bl,byte ptr [si].port
	xor	bh,bh
	shl	bx,1
	mov	si,offset ofsws
	mov	bx,cs:[si+bx]
	cmp	[kbbios],'Y'		; skip this if kbbios not support
	jne	kbdat0
	cmp	cx,dx			; cx must equal dx 
	jne	kbdat0
	cmp	dh,-1			; dh must be 0ffh
	jne	kbdat0
	push	dx
	push	si
	mov	al,dl
	mov	si,bx
	shl	si,1
	push	ds
	push	cs
	pop	ds
	mov	dx,[bx].ekeybase
	call	setleds
	pop	ds
	pop	si
	pop	dx
kbdat0:
	mov	al,cs:[bx].keyrdy
	or	al,al
	jz	inkbdx
	mov	si,cs:[bx].kbget
	mov	al,cs:[bx+si].kbbuf
inkbdx:
	ret
inkbdata endp

	subttl outkbctl - clear current scan code from terminal driver
	page
;======================================================================
;,fs
; outkbctl - clear current scan code from terminal driver
;
; in:	ah = 02h
;	al = bit 7   - clear buffered scan code if 1, ignored if 0
;	     bits 6-0 - ignored
;	ds:si -> tcbddt
;
; out:	
;
;,fe
;=====================================================================
	assume	ds:nothing,es:nothing,ss:nothing
outkbctl proc near
	test	al,80h
	jz	outkbx
	mov	bl,byte ptr [si].port
	xor	bh,bh
	shl	bx,1
	mov	si,offset ofsws
	mov	bx,cs:[si+bx]
	mov	al,cs:[bx].keyrdy
	or	al,al
	jz	outkbx			; no scan code to clear
	mov	si,cs:[bx].kbget
	inc	si
	cmp	si,kbsize
	jb	outkb1
	xor	si,si
outkb1:
	cli				; any more scan codes ?
	mov	cs:[bx].kbget,si
	cmp	si,cs:[bx].kbput
	jne	outkb2
	mov	cs:[bx].keyrdy,0
outkb2:
	sti
outkbx:
	ret
outkbctl endp


	subttl prch - print a character on the terminal's local printer
	page
;======================================================================
;,fs
; prch - print a character on the terminal's local printer
;
; in:	ah = 10h
;	al = char to print
;	ds:si -> tcbddt
;
; out:	returns ah as in int17
;
;,fe
;=====================================================================
	assume	ds:nothing,es:nothing,ss:nothing
prch proc near
	push	dx
	push	ds
	push	es
	call	getlptbase		; get lpt base for task
	push	ds
	pop	es
	call	prchar
	pop	es
	pop	ds
	pop	dx
	ret
prch endp

	subttl prstr - print a string on the terminal's local printer
	page
;======================================================================
;,fs
; prstr - print a string on the terminal's local printer
;
; in:	ah = 11h
;	es:di -> string to print
;	cx = length (bytes) to print
;	ds:si -> tcbddt
;
; out:	ah as in int 17h if all of string can't be printed
;	di -> first char not printed
;	cx = number not printed
;
;,fe
;=====================================================================
	assume	ds:nothing,es:nothing,ss:nothing
prstr proc near
	push	dx
	push	si
	push	bp
	push	ds
	push	es
	call	getlptbase
	mov	si,es
	push	ds
	pop	es
	mov	ds,si			; make ds point to cs
	mov	si,di
	mov	bp,cx
	cld
prstrlp:
	lodsb
	call	prchar
	test	ah,1h
	jnz	prserr
	loop	prstrlp
	jmp	short prsdone
prserr:
	add	di,bp			; error handler
	sub	di,cx
prsdone:
	pop	es
	pop	ds
	pop	bp
	pop	si
	pop	dx
	ret
prstr endp

	subttl print_status - get printer status
	page
;======================================================================
;,fs
; print_status - get printer status
;
; in:	ah = 12h
;	ds:si -> tcbddt
;	al = 0 to initiate a status request
;	   = 1 to check the status and fresh-flag
;
; out:	returns ah as in int 17h call
;	al = 1 (fresh flag)
;	bx = 0f3c9h  (signature to verify this function is supported)
;
;,fe
;=====================================================================
	assume	ds:nothing,es:nothing,ss:nothing
print_status proc near
	ret
print_status endp

	subttl getlptbase - return lpt base for station
	page
;======================================================================
;,fs
; getlptbase - return lpt base for station
;
; in:	ds:si -> ddt
;
; out:	dx -> lpt printer base address
;
;,fe
;=====================================================================
	assume	ds:nothing,es:nothing,ss:nothing
getlptbase proc near
	push	bx
	mov	bl,byte ptr [si].port
	xor	bh,bh
	shl	bx,1
	add	bx,offset ofsws ; point to desired egna structure
	mov	bx,word ptr cs:[bx]
	mov	dx,cs:[bx].elptbase
	pop	bx
	ret
getlptbase endp

	subttl prchar - lowlevel printer routine use to print character
	page
;======================================================================
;,fs
; prchar - lowlevel printer routine use to print character
;
; in:	dx -> printers parallel port
;	al -> value to print
;	es -> current tcb
;
; out:	
;
;,fe
;=====================================================================
	assume	ds:code,es:tcb,ss:nothing
prchar proc near
	push	bx
	push	cx
	push	dx
	push	ax
	push	ds
	push	cs
	pop	ds
	mov	bh,182			; number of cycles before error
	out	dx,al			; write the char to the port
	call	tickwait
	inc	dx			; point to the status register
prn000:
	mov	bl,0ffh 		; number of cycles before suspend
prn005:
	call	tickwait
	in	al,dx
	call	tickwait
	test	al,80h
	jnz	prn010
	dec	bl
	jnz	prn005
	dec	bh
	jz	prnerror
	push	ax
	push	bx
	push	dx
	mov	al,[tcbsiorb]		; save the state of the road block flag
	push	ax			; and reset it so its possible to pam
	mov	[tcbsiorb],0		; away from a task waiting for a busy printer
	mov	ax,0702h
	mov	bx,1			; suspend for one tick before
	pushf				; trying again
	call	[orig38]
	pop	ax
	mov	[tcbsiorb],al
	pop	dx
	pop	bx
	pop	ax
	jmp	prn000
prn010:
	inc	dx			; address control register
	call	tickwait
	cli
	in	al,dx			; preserve bits
	call	tickwait
	and	al,1eh
	or	al,1			; raise the strobe
	call	tickwait
	out	dx,al
	call	tickwait
	and	al,1eh
	out	dx,al			; lower the strobe
	call	tickwait
	sti
	mov	ah,90h
	clc
	jmp	short prnexit
prnerror:
	in	al,dx
	call	tickwait
	mov	ah,al
	and	ah,0f8h 		; mask off unused bits
	or	ah,1			; set timeout error bit
	stc
	pushf
	xor	ah,48h			; invert active low signals from port
	popf
prnexit:

	pop	ds
	pop	dx			; push'ed as the entry ax
	mov	al,dl
	pop	dx
	pop	cx
	pop	bx
	ret
prchar endp

	assume	ds:nothing,es:nothing,ss:nothing

ports	struc

addr	dw	0			; physical port address
prtirq	db	4			; default irq line for port
kbeflg	db	0			; keyboard empty flag
modmst	db	0			; current modem status register
linest	db	0			; current line status register
ioprot	db	0			; i/o protocols enabled
					; 80h - waiting for timer wrap
					; 40h - not used
					; 20h - report carrier loss
					; 10h - monitor carrier
					; 08h - rts/cts enabled
					; 04h - dtr/dsr enabled
					; 02h - xmit xon/xoff
					; 01h - rcv xon/xo; novell
iopend	db	0			; protocol state bits
					; 80h - carrier drop reported
					; 40h - carrier drop has occured
					; 20h - xon to be sent
					; 10h - xoff to be sent
					; 08h - rts off
					; 04h - dtr off
					; 02h - xoff rcvd
					; 01h - xoff sent
xoffch	db	0			; xoff character
xonch	db	0			; xon character
datovr	db	0			; data overrun flag
bufovr	db	0			; buffer overrun flag
ibfsiz	dw	0			; input buffer size (bytes)
obfsiz	dw	0			; output buffer size (bytes)

ibfseg	dw	0			; input buffer segment
ibfcnt	dw	0			; count of bytes in buffer
ibfget	dw	0			; next byte from buffer
ibfput	dw	0			; next empty buffer location

obfseg	dw	0			; output buffer segment
obfcnt	dw	0			; count of bytes in buffer
obfget	dw	0			; next byte from buffer
obfput	dw	0			; next empty buffer location

ports	ends

; sername must be 40 bytes long since this is what mos info expects

sername db	'UNTERM.SYS  V2.30 (921214)              '

txdat	equ	0			; data transmitter
rxdat	equ	0			; data receiver
divll	equ	0			; baud rate divisor latch lsb
divlm	equ	1			; baud rate divisor latch msb

iereg	equ	1			; interupt enable register
enmsi	equ	000001000b		; enable modem status interupts
enlsi	equ	000000100b		; enable line status interupts
entei	equ	000000010b		; enable transmitter empty inter
endri	equ	000000001b		; enable data ready interupts

iireg	equ	2			; interupt identification regist
noint	equ	000000001b		; no interupt pending

lcreg	equ	3			; line control register
divla	equ	010000000b		; divisor latch access control
stbrk	equ	001000000b		; set break condition

mcreg	equ	4			; modem control register
stot2	equ	000001000b		; set out 2 (enable interupts)
stot1	equ	000000100b		; set out 1
strts	equ	000000010b		; set rts
stdtr	equ	000000001b		; set dtr

lsreg	equ	5			; line status register
tsre	equ	001000000b		; transmitter shift reg empty
thre	equ	000100000b		; transmitter holding reg empty
brki	equ	000010000b		; break indicator
frerr	equ	000001000b		; framing error
paerr	equ	000000100b		; parity error
overr	equ	000000010b		; data overrun error
drdy	equ	000000001b		; data ready

msreg	equ	6			; modem status register
carst	equ	010000000b		; status of carrier detect (rlsd)
rngst	equ	001000000b		; status of ring indicator (ri)
dsrst	equ	000100000b		; status of data set ready (dsr)
ctsst	equ	000010000b		; status of clear to send (cts)
carch	equ	000001000b		; change in carrier detect (rlsd)
trlri	equ	000000100b		; trailing end of ring indicator
dsrch	equ	000000010b		; change in data set ready (dsr)
ctsch	equ	000000001b		; change in clear to send (cts)

	assume	ds:nothing,es:nothing,ss:nothing

true	equ	1 eq 1
false	equ	1 eq 0

serial	equ	false
emulink equ	false
mos	equ	true

;
; The need for CPUSPEED does not appear necessary, but Rod wanted the
; code left in serial.sys, so we find the need we can put it. if so
; comment out the following equate

DISABLE_CPUSPEED 	equ	1

IFDEF DISABLE_CPUSPEED
cpuspeed dw	0
tickwait proc	near
	push	cx
	mov	cx,cs:[cpuspeed]
tickloop:
	loop	tickloop
	pop	cx
	ret
tickwait endp
ENDIF

include seriomac.inc			; i/o macros
include jmpmacro.inc			; long jump macros
include int14.inc			; int14 logic
include isrsub.inc			; serial irq support surbroutines

	subttl clr_set_irq - dummy (only needed by _serial.asm)
	page
;======================================================================
;,fs
; clr_set_irq - dummy (only needed by _serial.asm)
;
; in:	ch = 0 to clear, 1 to set
;	cl = irq number
;
; out:	
;
;,fe
;=====================================================================
	assume	ds:nothing,es:nothing,ss:nothing
clr_set_irq proc  near
	ret
clr_set_irq endp

	subttl serial_irq - process a serial irq
	page
;======================================================================
;,fs
; serial_irq - process a serial irq
;
; outline or serial serial irq program logic
;    1.  ouput a 0 to exxd register to disable interupt to the at bus
;    2.  setup to point to first board on system
;    3.  input from status register 0xxc of current board
;    4.  is bit 7 a logical 1? if no then goto to step 6
;    5.    service local serial interupt as follows
;		a. input from 0xxa twice
;		b. use the value read on the second input command to
;		  determine which serial port cause the interupt
;		c. serivice the serial port
;		d. issue eoi to board being service
;    6.  if bit 5 of status register is logica 0 then step 8
;    7.    point to next board on system and goto to step 3
;    8.  issue eoi to the motherboard pic (20h and a0h)
;    10. output a 1 to exxd register to enable interupt from at bus
;
; note: future additions will alter method of servicing so that we find
; out exactly which interupts have fire from 8259 and service each one.
; this will allow us to service more than just the highest priority
; interuppt on the system.
;
; in:	
;
; out:	
;
;,fe
;=====================================================================
	assume	ds:nothing,es:nothing,ss:nothing
serial_irq proc far
	push	ax
	push	bx
	push	cx
	push	dx
	push	si
	push	di
	push	ds
	push	es
	cld				; clear direction flags for serial use
	mov	ax,cs
	mov	ds,ax			; make ds point to cs
	assume	ds:code
	xor	al,al
	mov	dx,[baseexxd]
	out	dx,al			; disable interupts to at bus

; setup bx to point to first egna structure on system

	mov	bx,[directptr]

; this is code which next board will loop back to

serial_loop:
       mov	si,word ptr [bx]
       mov	dx,[si].eaddr
       add	dl,0ch			; point to status register
       in	al,dx
       test	al,80h			; has serial board interupted
       jz	serial_next		; no...then try next board

; at this point we know that serial board has interuptted

	add	dx,1000h-2		; point int ack register
	in	al,dx
	jmp	$+2
	jmp	$+2			; delay for faster 386 / 486 cpus
	jmp	$+2
	in	al,dx

; first we need to validated that interupt is in range

	mov	dx,[si].eaddr
	mov	cx,bx
	xor	ah,ah
	add	bx,ax
	add	bx,ax
	mov	si,word ptr [bx]
	mov	bx,cx
	cmp	si,-1
	jz	serial_skip
	cmp	dx,[si].eaddr
	jne	serial_skip

; at this point we know which station has fire and point to
; station's EGNA buffer.

	push	bx
	mov	bx,[si].eserial
	or	bx,bx			; no serial buffer, how can this be
	jz	serial_done		; i quest we better not do anything
	mov	dx,[bx].addr
serial_int:
	rdiir				; read the interrupt indentification register
	test	al,noint		; is he interupting
	jnz	serial_done		; jump if not this port
	xor	ah,ah			; convert interupt type to offset
	mov	si,ax			; move the offset to si
	call	inttbl[si]		; call the interupt processor
	jmp	short serial_int
serial_done:
	pop	bx

; issue eoi for this board

serial_skip:
	mov	si,word ptr [bx]
	mov	dx,[si].eaddr
	add	dx,1008h
	mov	al,20h
	out	dx,al

; now we will check to see if there is another interupt on chain
; please note at this point, this logic has been designed so
; that dx -> base address

serial_next:
	and	dx,0ff0h		; set to base
	add	dl,0ch			; point to status register
	in	al,dx			; read status register
	test	al,20h			; do we have another interupt in chain
	jz	serial_end

; at this point we must setup bx so it is pointing to next work station
; in chain

	mov	si,word ptr [bx]
	add	bx,4*2			; set up for egna or vgna+ style boards
	cmp	[si].eboard, svnaplus
	jne	serial_novna
	add	bx,4*2
serial_novna:
	jmp	serial_loop

; now send eoi first to primary and then to secondary 8259 on
; main motherboard.

serial_end:
	mov	al,20h
	out	20h,al			; set eoi to primary 8259
	jmp	$+2
	out	0a0h,al 		; set eoi to secondary 8259
	mov	al,1
	mov	dx,[baseexxd]
	out	dx,al			; enable interupts to at bus
	assume	ds:nothing
	pop	es
	pop	ds
	pop	di
	pop	si
	pop	dx
	pop	cx
	pop	bx
	pop	ax
	iret
serial_irq endp

;
; The following code is added to system, so that when system is
; rebooted video will be map back to the master console
;

HandleCoRes	proc	near
	cmp	[WSSwitch],'Y'	; skip if bios switching is not set
	jne	SkipCoRes
	call	SaveBios    	; this function will map in master console
				; video if necessary
SkipCoRes:
	ret
HandleCoRes	endp


;
; The following routine is use by BIOSRES.INC's getcurbios routine to
; return current workstation on system
;

GetCurPort proc	near
	mov	bx,00ffh	; indicate workstation not install
	cmp	cs:[SaveDSPort],-1
	je	GCPExit
	push	ax
	push	ds
	push	si
	mov	ds,cs:[SaveDSPort]
	assume	ds:tcb
	mov	si,offset tcbcondd
	mov	ax,cs
	cmp	ax,word ptr ds:[si+2]
	jne	GCPSkip
	mov	bx,word ptr ds:[si].port
GCPSkip:
	assume	ds:nothing
	pop	ds
	pop	si
	pop	ax
GCPExit:
	ret
GetCurPort endp


include biosres.inc


	assume	ds:nothing,es:nothing,ss:nothing

; the following is a data structure which is use during parsing of
; command to store specific information about each of the boards on the
; system.  all information in these structures will be transfer to
; egna structure, or serial port structure after init as complete its
; parsing analysis.

initstat struc
baseaddr  dw		0		; base address for board
board	  db		0		; board type
serenable db	   8  dup  (0) 		; serial enable flags
setserial db	   8  dup  (0) 		; serial option set
ibuffer   dw	   8  dup  (0)		; serial input buffer sizes
obuffer   dw	   8  dup  (0) 		; serial output buffer sizes
hsopt	 db	   8  dup  (0) 		; hs options
cnopt	 db	   8  dup  (0) 		; cn options
stations  db	   8  dup  (0) 		; stations on system
versions  db	   8  dup  (0) 		; board revisions on system
initstat ends

; the following data structure is overlap in each stations egna structure
; keyboard buffer areas for use during init, this is done so that we can
; virtually have unlimited # of work stations on the system, and at the
; same time disregard almost 100% of initialization code.

egnainit struc
inbuff	dw		0		; serial input buffer size
outbuff dw		0		; serial output buffer size
hsoption db		0		; hs option
cnoption db		0		; cn option
inuse	db		0		; is serial use for this port
egnainit ends

;
; the following location, is executed with drivers initialization
; logic is complete, so we must transfer data structures to end of
; resident code in structure designed for faster execution. once
; transfer, we will then adjust device driver return size so that only
; driver resident code and permament data as preserved in memory. this
; allows this driver to virtually have unlimited stations, while
; minimizing space requirements.

noofboards	dw	0		; number of boards on system
processport	dw	0		; current board processing
lastoffset	dw	0		; last avaliable offset
lastsegment	dw	0		; last segment value
noofstations	dw	0		; number of stations


; the following table is use to initialized serial table for egna ports
; depends on which work station is attach across serial port base address
; is number in table plus the base address for work station in question

serialtable  dw   2000h,2008h,3000h,3008h  ; (port 1-4 egna or vnaplus)
	    dw   4000h,4008h,5000h,5008h  ; (port 5-8 vnaplus)

; addition room reserved for initialization.  this should provide enought
; storage for maximun amount of mos tasks on system.   a 99 user system
; could be created with this system if you had enough smp.

tempextra	equ	4096

finalstage label near
	call	laststage
	call	install14
	les	bx,[request]
	mov	word ptr es:[bx+14],0
	mov	ax,[lastsegment]
	mov	es:[bx+16],ax
	ret

	subttl install14 - install the int14 handler
	page
;======================================================================
;,fs
; install14 - install the int14 handler
;
; in:	
;
; out:	
;
;,fe
;=====================================================================
	assume	ds:nothing,es:nothing,ss:nothing
install14 proc near
	cmp	[serirq],-1		; serial logic installed???
	je	donein14
	mov	ah,6			; check to see if int 14 handler, already
	xor	dx,dx
	int	14h			; is install, if not then install our handler
	test	ah,80h			; test high bit to see if installed
	jz	setint14

; if we come here this means that we must link our driver in as child

	push	es
	push	cs
	pop	es
	mov	bx,offset int14 	; register child with serial driver
	mov	ah,10h
	int	14h
	pop	es
	jmp	short donein14

; this is were we would install our int 14 handler

setint14:
	push	ds
	push	cs
	pop	ds
	mov	dx,offset int14 	; install our int 14 handler
	mov	ax,2514h
	int	21h
	pop	ds
donein14:
	ret
install14   endp

	subttl laststage - 
	page
;======================================================================
;,fs
; laststage - 
;
; allocate data structure, first call setegnaoffsets, 
; which is located at end of file which is can be overwritten 
; by egna data structures.
;
; in:	
;
; out:	
;
;,fe
;=====================================================================
	assume	ds:nothing,es:nothing,ss:nothing
laststage proc near
	call	setegnaoffsets
	mov	cx,[noofboards]
	mov	si,offset temparea+tempextra
	mov	di,offset ofsws
iesetup:
	push	cx
	push	si
	mov	cx,4
	cmp	byte ptr ds:[si].board,svnaplus
	jne	notplus
	add	cl,4
notplus:
	xor	bx,bx			; start at bank 1
statloop:
	cmp	byte ptr ds:[si+bx].stations,snot_install
	je	ieskip
	push	cx
	push	di
	mov	di,word ptr cs:[di]
	push	bx
	call	processegna
	pop	bx
	pop	di
	pop	cx
	inc	di
	inc	di
ieskip:
	inc	bx
	loop	statloop
	pop	si
	pop	cx
	add	si,type (initstat)
	loop	iesetup

; now we must initialize serial port structure for each station

	mov	ax,[lastoffset] 	; next offset will be start of
	mov	[portoff],ax		; serial buffer
	mov	cx,[noofstations]
	xor	di,di
sinitloop:
	push	cx
	push	di
	push	bx
	mov	bx,offset ofsws
	mov	di,word ptr [bx+di]	; get offset to egna structure
	pop	bx
	call	processserial
	pop	di
	pop	cx
	inc	di
	inc	di
	loop	sinitloop

; check to see if no serial ports defined if so ignore serial irq

	cmp	[numport],0
	jne	sserialins
	mov	[serirq],-1
sserialins:

; now we will convert lastoffset into lastsegment so that we can do segment
; allocation for serial buffers

	mov	ax,[lastoffset]
	add	ax,15			; round up to next segment
	shr	ax,4			; convert to segment
	mov	bx,cs
	add	ax,bx
	mov	[lastsegment],ax	; store as segment value

; now we must setup up serial buffers for each serial port on system

	mov	cx,[numport]
	or	cx,cx
	jz	sskipbuff
	mov	di,[portoff]
sbuffloop:
	push	di
	mov	bx,[lastsegment]
	mov	[di].ibfseg,bx
	mov	ax,[di].ibfsiz		; get input buffer size
	call	nextseg
	mov	[di].obfseg,bx
	mov	ax,[di].obfsiz		; get output buffer size
	call	nextseg
	mov	[lastsegment],bx
	pop	di
	add	di,type ports
	loop	sbuffloop
sskipbuff:
	ret
laststage endp

InitLPT proc	near
	push	ax
	push	dx
	
	mov	dx,ax
	inc	dx
	inc	dx
	mov	al,08h
	out	dx,al
	mov	ax,4000
InitLPTLp:
	dec	ax
	jnz	InitLPTLp
	mov	al,0ch
	out	dx,al
	
	pop	dx
	pop	ax
	ret
InitLPT endp	
	

	subttl processegna - initialize a single ega station
	page
;======================================================================
;,fs
; processegna - initialize a single ega station
;
; in:	cs:si -> points to init structure
;	cs:di -> egna structure
;	bx -> bank for board (0-3 for egna, 0-7 for vnaplus)
;
; out:	
;
;,fe
;=====================================================================
	assume	ds:nothing,es:nothing,ss:nothing
processegna proc near
	mov	ax,[si].baseaddr
	mov	[di].eaddr,ax		; transfer base address
	push	si
	push	bx
	inc	bx			; start out at station 1
	mov	si,offset ofsws
	mov	si,word ptr cs:[si]
	cmp	ax,cs:[si].eaddr	; is this first station
	jne	setwsbl 		; no than start bank is 1
	cmp	[ws0ismc],'Y'		; is ws 0 master console
	jne	setwsbl 		; no than start bank is 1
	dec	bx			; use start at bank 0 for master
setwsbl:
	mov	[di].ews,bl		; transfer ws #
	pop	bx
	pop	si
	xor	bh,bh

; set desired timer base address

	push	bx
	shl	bx,1
	add	bx,0a001h
	add	bx,ax
	mov	[di].timerbase,bx	; set timer base address
	pop	bx

; set desired keyboard base address

	push	bx
	shl	bx,1
	cmp	bl,8
	jb	pnot8ports
	add	ax,1000h
	sub	bl,8
pnot8ports:
	add	ax,bx
	pop	bx
	inc	ax			; point to control register
	mov	[di].ekeybase,ax

; set desired lpt printer base address

	push	bx
	mov	ax,[si].baseaddr	; get base address
	add	ax,6000h		; lpt start at 6xx0-6xxf
	cmp	bl,4
	jb	lnot8ports
	add	ax,1000h		; asume lpt (4-8) at 7xxx
	sub	bl,4
lnot8ports:
	shl	bx,2			; port address per port
	add	ax,bx
	pop	bx
	mov	[di].elptbase,ax
	call	InitLPT
	mov	al,[si].board
	mov	[di].eboard,al		; transfer board type
	mov	al,[si+bx].stations
	mov	[di].etype,al		; transfer type
	mov	al,[si+bx].versions
	mov	[di].evers,al		; board revision type
	mov	[di].etcb,-1		; zero out tcb register
	xor	ax,ax
	mov	word ptr [di].eunreg,ax
	mov	word ptr [di+2].eunreg,ax
	mov	[di].kbget,ax
	mov	[di].kbput,ax
	mov	[di].kbstat,al
	mov	[di].keyrdy,al

; the following will store serial specific information inside keyboard buffer
; area which will be use later to initialized the serial ports on the system

	lea	di,[di].kbbuf		; point to keyboard buffer area
	mov	al,[si+bx].serenable
	mov	[di].inuse,al		; set serial inuse flag
	cmp	al,'Y'			; is serial enable for this port
	jne	pegnaskip

; serial is enable for this port, so store serial information into keyboard
; buffer using egnainit structure

	mov	al,[si+bx].hsopt
	mov	[di].hsoption,al	; transfer hs option
	mov	al,[si+bx].cnopt
	mov	[di].cnoption,al	; transfer cn option
	shl	bx,1
	mov	ax,[si+bx].ibuffer
	mov	[di].inbuff,ax		; transfer input serial buffer size
	mov	ax,[si+bx].obuffer
	mov	[di].outbuff,ax 	; transfer input serial buffer size
pegnaskip:
	ret
processegna endp

	subttl processserial - 
	page
;======================================================================
;,fs
; processserial - 
;
; the following routine is use to process serial port information, this
; mean that we will allocate space for serial port information and
; initialized serial information into ports structure correctly
;
; in:	cs:di -> egna structure
;
; out:	
;
;,fe
;=====================================================================
	assume	ds:nothing,es:nothing,ss:nothing
processserial proc near

; first we will check to see if serial is enable for this port if not,
; then we we will return a not allocated space for serial information

	lea	si,[di].kbbuf		; point to keyboard buffer area
	cmp	[si].inuse,'Y'
	je	psercont
	mov	[di].eserial,0		; indicated serial not installed
	ret				; return if serial not install
psercont:
	inc	[numport]		; increment # of serial ports
	mov	bx,[lastoffset]
	mov	[di].eserial,bx 	; set offset to serial for irq logic
	add	[lastoffset], type ports

; clear out all information for port entry

	push	di
	mov	di,bx
	mov	cx,type ports
	shr	cx,1
	xor	ax,ax
	rep	stosw			; clear out serial port information
	pop	di

; tranfer buffer size information from temporary area located inside keyboard
; buffer to ports structures

	mov	ax,[si].inbuff
	mov	[bx].ibfsiz,ax		; transfer input buffer size
	mov	ax,[si].outbuff
	mov	[bx].obfsiz,ax		; transfer output buffer size

; the following logic is use to derived serial port base address from base
; address of board + number in serialtable from workstation #

	push	di
	mov	al,[di].ews		; get work station
	cmp	[ws0ismc],'Y'		
	jne	psset
	push	bx
	push	dx
	mov	bx,offset ofsws
	mov	bx,[bx]
	mov	dx,[bx].eaddr
	cmp	dx,[di].eaddr
	pop	dx
	pop	bx
	je	psskip
psset:
	dec	al
psskip:
	xor	ah,ah
	shl	ax,1
	mov	di,ax
	mov	ax,word ptr [serialtable+di]
	pop	di
	add	ax,[di].eaddr
	mov	[bx].addr,ax

; process hs= option

	mov	al,[si].hsoption	; get hs option
	cmp	al,'N'			; is hs=n none
	jne	pshsnotn
	and	[bx].ioprot,0f0h	; clear all bits
	jmp	short hsdone
pshsnotn:
	cmp	al,'R'			; is hs=r rts
	jne	pshsnotr
	or	[bx].ioprot,08h 	; set rts
	jmp	short hsdone
pshsnotr:
	cmp	al,'D'			; is hs=d dtr
	jne	pshsnotd
	or	[bx].ioprot,04h 	; set dtr
	jmp	short hsdone
pshsnotd:
	cmp	al,'X'			; is hs=x xon/xoff
	jne	pshsnotx
	or	[bx].ioprot,03h 	; set xon/xoff
	mov	[bx].xoffch,13h
	mov	[bx].xonch,11h
	jmp	short hsdone
pshsnotx:				; hs=p
	or	[bx].ioprot,03h 	; set xpc
	mov	[bx].xoffch,67h
	mov	[bx].xonch,65h
hsdone:

; process cn= option

	mov	al,[si].cnoption	; get cn= option
	cmp	al,'L'			; cn=l
	jne	pscnnotl
	and	[bx].ioprot,not 30h
	jmp	short cndone
pscnnotl:
	cmp	al,'R'			; cn=r
	jne	pscnnotr
	or	[bx].ioprot,10h
	jmp	short cndone
pscnnotr:				; cn=t
	or	[bx].ioprot,30h
cndone:
	ret
processserial endp

	subttl nextseg - 
	page
;======================================================================
;,fs
; nextseg - 
;
; the following routine is use by process buffer to adjust current buffer
; segment to next buffer segment depending on size
;
; in:	bx -> current segment
;	ax -> size of buffer
;
; out:	bx -> next segment
;
;,fe
;=====================================================================
	assume	ds:nothing,es:nothing,ss:nothing
nextseg proc near
	add	ax,15			; plus 15 for paragraph boundary
	rcr	ax,1			; bring in the carry if full 64k
	shr	ax,3			; convert buffer to paragraphs
	add	bx,ax			; adjust segment value
	ret
nextseg endp

; now we must go through list and initialized each data area for each work
; station on the system

			public	$$UNTERM_DATA
$$UNTERM_DATA 	label	byte

		even
ofsws		label	word

;========= start of device driver initialization code and data ==========
									
; serial options set

ib_option		equ	1
ob_option		equ	2
hs_option		equ	4
cn_option		equ	8

; error codes for parsing logic

end_of_serial		equ	-1
end_of_cmd		equ	0
bad_base		equ	1
dup_base		equ	2
bad_keyirq		equ	3
bad_irq 		equ	bad_keyirq
bad_serirq		equ	4
dup_key_ser		equ	5
bad_port		equ	6
dup_port		equ	7
bad_port8		equ	8
bad_ib			equ	9
dup_ib			equ	10
bad_ob			equ	11
dup_ob			equ	12
bad_hs			equ	13
dup_hs			equ	14
bad_cn			equ	15
dup_cn			equ	16
bad_serial		equ	17
base_not_install	equ	18
no_port 		equ	19
no_serial		equ	20

comma			equ	','
irq10			equ	10
irq11			equ	11
irq15			equ	15

errtab	label	word
	dw	offset mbadbas		; 1  : bad_base
	dw	offset mdupbas		; 2  : dup_base
	dw	offset mbadkey		; 3  : bad_keyirq
	dw	offset mbadser		; 4  : bad_serirq
	dw	offset mdupirq		; 5  : dup_key_ser
	dw	offset mbadp4		; 6  : bad_port
	dw	offset mduppt		; 7  : dup_port
	dw	offset mbadp8		; 8  : bad_port8
	dw	offset mbadib		; 9  : bad_ibuff
	dw	offset mdupib		; 10 : dup_ibuff
	dw	offset mbadob		; 11 : bad_obuff
	dw	offset mdupob		; 12 : dup_obuff
	dw	offset mbadhs		; 13 : bad_hs
	dw	offset mduphs		; 14 : dup_hs
	dw	offset mbadcn		; 15 : bad_cn
	dw	offset mdupcn		; 16 : dup_cn
	dw	offset mbadopt		; 17 : bad_serial
	dw	offset nobase		; 18 : base_not_install
	dw	offset nosport		; 19 : no_port
	dw	offset mustser		; 20 : no_serial
errlen	equ	($-errtab)/2

opttab	label	word
	dw	offset processib	; 0  : ib_option
	dw	offset processob	; 1  : ob_option
	dw	offset processhs	; 2  : hs_option
	dw	offset processcn	; 3  : cn_option

curbase dw	-1			; current base address
curserial db	0

;======================== transient data ================================

ddtmsg	db	13,10
	db	'UnTerminal device driver (921214) $          '  ;@@xlat
ddtnins db	'not installed.          ',13,10,'$'  ;@@xlat
ddtins	db	'installed.           ',13,10,'$'  ;@@xlat
ddtains db	'already installed.             ',13,10,'$'  ;@@xlat

msgbmice db	'UNTERM.SYS must be installed before Mouse driver.        ',13,10,'$'  ;@@xlat

dmsgkey  db	'     Keyboard IRQ on IRQ1$           '  ;@@xlat
dmsgkey2 db	'x, Serial IRQ $          '  ;@@xlat
dmsgser  db	'on IRQ1$            '	;@@xlat
dmsgser2 db	'x.',13,10,'$'
dmsgnser db	'not used.        ',13,10,'$'  ;@@xlat
VirtualBios db	'     Virtual Bios $           	' 	  ;@@xlat	
dmsgnhr  db	'     Hi-Resolution Graphics Disable.         ',13,10,'$' ;@@XLAT
dmsgcon  db	'     Co-resident Video Adapter Exists.       ',13,10,'$' ;@@xlat	
dmsgbase db	'     Base $          ' ;@@xlat
dmsghas  db	'0000H has $           '  ;@@xlat
dmsges	db	'x EGNA$'
dmsghs	db	'x VNA PLUS$'
dmsgvs	db	'x VGNA PLUS$'
dmsgand  db	' and $            '	;@@xlat
dmsgws	db	' workstation(s).         ',13,10,'$'  ;@@xlat

msgpos	db	'Above Error occurred $        '  ;@@xlat
msgstart db	'at start of command line.       ',13,10,'$'  ;@@xlat
msgbase db	'on the use of Base Address of $         '  ;@@xlat
dbase	db	'0000H$'
msgserial db	', Serial Port $       ';@@xlat
dserial db	'x.',13,10,'$'
basecrlf db	'.'			;[1]	these two lines must stay
msgcrlf db	13,10,'$'		;[2]	together
errmsg	db	'Error in Command Line: $             '  ;@@xlat
mbadbas db	'Invalid Base Address Specified.     ',13,10,'$'  ;@@xlat
mdupbas db	'Duplicate Base Address Specified.      ',13,10,'$'  ;@@xlat
mbadkey db	'Invalid Keyboard IRQ (Interrupt level) Specified.     ',13,10,'$'  ;@@xlat
mbadser db	'Invalid Serial (Interrupt level) IRQ Specified.       ',13,10,'$'  ;@@xlat
mdupirq db	'Duplicate Keyboard-Serial IRQ.      ',13,10,'$'  ;@@xlat
mbadp4	db	'Invalid 4-Port Serial Port (1-4).      ',13,10,'$'  ;@@xlat
mbadp8	db	'Invalid 8-Port Serial Port (1-8).      ',13,10,'$'  ;@@xlat
mduppt	db	'Duplicate Serial Port Specified.       ',13,10,'$'  ;@@xlat
mbadib	db	'Invalid Input Buffer (16-65535).       ',13,10,'$'  ;@@xlat
mbadob	db	'Invalid Output Buffer (16-65535).      ',13,10,'$'  ;@@xlat
mbadhs	db	'Invalid HS= Option (N,D,X,P,R).        ',13,10,'$'  ;@@xlat
mbadcn	db	'Invalid CN= Option (R,L,T).            ',13,10,'$'  ;@@xlat
mdupib	db	'Only 1 Input Buffer per Serial Port.      ',13,10,'$'	;@@xlat
mdupob	db	'Only 1 Output Buffer per Serial Port.     ',13,10,'$'	;@@xlat
mduphs	db	'Only 1 HS= Option per Serial Port.        ',13,10,'$'	;@@xlat
mdupcn	db	'Only 1 CN= Option per Serial Port.        ',13,10,'$'	;@@xlat
mbadopt db	'Invalid Serial Option (IB=,OB=,HS=,CN=).     ',13,10,'$'  ;@@xlat
nobase	db	'No Network Adapter Installed.          ',13,10,'$'  ;@@xlat
nosport db	'Work Station not installed.      ',13,10,'$'  ;@@xlat
mustser db	'Serial IRQ (Interrupt level) Must be present.       ',13,10,'$'  ;@@xlat

hslist		db	'NDXPR',0	; list of possiable hs options
cnlist		db	'RLT',0 	; list of possiable cn options
irqlist 	db	10,11,15,0  ; list of possiable irqs
optlist 	db	'IBOBHSCN',0,0	; list of serial options

wordten 	dw	10		; constant  10

definput	dw	0		; defualt input buffer size
defoutput	dw	0		; defualt output buffer size
defhsoption	db	0		; default hs= option
defcnoption	db	0		; default cn= option

moudriver   	db	'$$MOUSE',0		; mouse driver
vgnarom		db	'VGNAPLUS.ROM',0	; vgnaplus rom
vgdriver	db	'UNTERM.SYS',0		; driver name

vgbiostab	label	dword
		dw	-1			; handle for memory management
		dw	32768			; 32K ROM

;===========================================================================
vgpatchtab	label	byte
;
; offset 24ca, 1 byte 81h
;
		db	2			; bank #2
		dw	04cah			; offset 4cah
		db	1
		db	81h
;
		db	-1			; terminator

;============================================================================	
;	BIOS Switching Logic  Data 

UNTERM_BIOS_DATA 	label	word
VGNA_BIOS_DATA  	label	word
		dw	0c000h		; allways at 0c000h
VGNA_Handle	dw	?		; Handle for VGNA+ rom image
VGNA_Banks	db	8		; 8 banks (8*4k) = 32k
		db	?		; *** RESERVED ***
		dw	07402h		; offset for VGNAPLUS rom INT 10h
		dw	0c000h
		dw	00090h		; offset for VGNAPLUS rom INT 1dh
		dw	0c000h
		dw	00fb0h		; offset for VGNAPLUS rom INT 1fh
		dw	0c000h
		dw	00bb0h		; offset for VGNAPLUS rom INT 43h
		dw	0c000h
		dw	073f2h		; offset for VGNAPLUS rom INT 6dh
		dw	0c000h
		dw	043f0h		; offset for VGNAPLUS rom bios 40:a8
		dw	0c000h


;============================================================================	

carddefs	label	byte
		db	svnaplus
		db	segna
		db	svgnaplus	

off10		dw	0		; original int 10 offset
seg10		dw	0		; original int 10 segment
savecur 	dw	0		; saved cursor position
savectype	dw	0		; saved cursor type
VGNAIns		db	'N'		; VGNA+ Installed, a quick check
VGNACount	db	0		; # of VGNA+ cards on system
VGNASwitch	db	'N'		; do not switch VGNA Bios
V8514Switch	db	'N'		; do not switch 8514 Bios

UnPortTable	db	128 dup (0ffh)   ; unterm's Port Table

;=================== main initialization procedure ======================


	subttl ddtinit - device driver initialization
	page
;======================================================================
;,fs
; ddtinit - device driver initialization
;
; retrieve location of master console ddt entry, taking tcbcondd 
; address from foreground tcb, replacing that address with our 
; entry, set driver length and exit.
;
; in:	[request] -> request header from dd call
;
; out:	end of resident point set into request header
;
;,fe
;=====================================================================
	assume	ds:nothing,es:nothing,ss:nothing
ddtinit proc near
	mov	ax,cs
	mov	ds,ax
	xor	ax,ax
	mov	es,ax
	mov	dx,offset ddtmsg
	mov	ah,9
	int	21h
	mov	ax,es:[1ah*4]		; init orig1a vector for int14.inc
	mov	word ptr [orig1a],ax
	mov	ax,es:[1ah*4+2]
	mov	word ptr [orig1a+2],ax
	mov	ah,34h
	int	21h
	les	bx,es:[bx-18h]		; get a pointer to the extended
	mov	word ptr [orig38],bx	; services entry point
	mov	word ptr [orig38+2],es
	mov	ah,2
	pushf
	call	[orig38]		; call extended services to get a
	mov	[scbofs],bx		; pointer to the base of the scb
	mov	[scbseg],es

; get kbbios parameter

	cmp	byte ptr es:[bx+scbkbbios],'Y'
	jne	nobios
	mov	[kbbios],'Y'
nobios:
	mov	es,es:[bx+scbtcbpf]	; access the foreground tcb
	mov	[mctcb],es
	assume es:tcb
	mov	al,byte ptr [tcbcondd.dcbios]  ; save foreground's dcbios
	lds	bx,[tcbcondd]		; to detect co-resident case

; check for a second loading of unterm.sys

	cmp	word ptr [bx-3],'GE'
	jne	sddierror
	cmp	byte ptr [bx-1],'A'
	jne	sddierror
	mov	dx,offset ddtains
	jmp	ddierror
sddierror:
	mov	word ptr [ddtmc],bx	; mcterm address
	mov	word ptr [ddtmc+2],ds
	cmp	[HiResGraph],'Y'
	je	sddhires
	mov	es,[mctcb]
	mov	byte ptr [tcbcondd.dcbios],0  	; set it to CGA
sddhires:
	les	bx,[request]
	lds	si,es:[bx+18]		; -> device driver command line
	call	GetCurDir		; get current directory for loading
					; bios off of disk
	call	parsecmd
	push	cs
	pop	ds
	cmp	ax,end_of_cmd
	je	continit

; we have detected an error

	call	dispemsg		; display error message to user
	jmp	dder01

; continueing initialization

continit:
	cmp	[serirq],-1		; if no serial, then we don't care
	je	miceok
	call	checkspeed
	call	chkmouse
	jc	miceok			; if we can find $$mouse.sys then we are ok
	push	cs
	pop	ds
	mov	dx,offset ddtnins
	mov	ah,9
	int	21h
	mov	dx,offset msgbmice
	jmp	ddierror
miceok:
	call	checkcoexist		; check for co-existence
;
;============= CODE to Handle VGNA Bios and Switching ===================
;
;	Check for loading rom
;	LoadRom if more than 1 VGNA+ card is installed or
;	if atleast 1 VGNA+ card is installed and co-existence
;
	mov	al,[VGNACount]		;
	or	al,al
	jnz	wehavevgna
	mov	[SlashS],'Y'
	jmp	unskipbios		; if no VGNA+ don't load rom
wehavevgna:
	cmp	al,1
	jne	dorombios
	cmp	[ws0ismc],'Y'		; if 1 card and non-conexistence
	je	unskipbios		; than skip loading bios
dorombios:
	mov	dx,offset vgnarom
	mov	si,offset vgpatchtab	; (-1 if no patches)
	mov	bx,offset vgbiostab
	xor	al,al			; indicate VGNA+ master console
	cmp	[ws0ismc],'Y'
	je	doinitv
	dec	al			; indicate coexistence system
doinitv:
	call	initvbios		; init VBIOS	
	jnc	unskipbios
	push	ax
	push	dx
	mov	dx,offset ddtnins
	mov	ah,9
	int	21h
	pop	dx
	pop	ax
	mov	si,offset vgdriver
	call	dispverr		; display error message
	jmp	dder01
unskipbios:
;
;	setup bios switching logic for switching
;
	cmp	[VGNACount],0			; any VGNA's
	je	skbiossw
	cmp	[ws0ismc],'Y'
	je	skbiossw
	mov	[VGNASwitch],'Y'		; VGNA switching is include
;
;	setup memory management handle for VGNA Bios switching
;
	mov	bx,offset vgbiostab
	mov	ax,word ptr cs:[bx]
	mov	[VGNA_Handle],ax
skbiossw:
;
;============= CODE to Handle 8514 Bios and Switching ===================
;
;                Not currently implement but planned 
;
;============ CODE to initialized bios switching logic ===================
;
	cmp	[VGNASwitch],'Y'		; is VGNA Bios switching
						; enable
	je	setbiosset
	cmp	[V8514Switch],'Y'		; is 8514 Bios switching
						; enable
	jne	skbiosset
setbiosset:
	push	ds
	push	es
	push	cs
	pop	ds
	push	cs
	pop	es
	mov	di,offset UnPortTable
	mov	cx,128				; up to 128 Port (driver
						; should handle it)	
	call	CreatePortInfo
	mov	si,offset UnPortTable
	mov	di,offset UNTERM_BIOS_DATA
	mov	bx,1
	call	InitContext
	pop	es
	pop	ds

skbiosset:
;
; set vidchk routine for pamswitching access
;
	cmp	cs:[HiResGraph],'Y'
	jne	NoVidChk		; no hi-res support
	push	bx
	push	es
	les	bx,[scbptr]
	assume	es:gdata
	mov	word ptr es:[bx+scbvidchk],offset vidchk
	mov	word ptr es:[bx+scbvidchk+2],cs
	assume	es:tcb
	pop	es
	pop	bx
NoVidChk:
	call	configdriver		; set up interupts
	push	cs
	pop	ds
	mov	ah,9
	mov	dx,offset ddtins	; display install message
	int	21h
	call	dispconfig		; display configuration to user
	call	initbios		; initialize bios for all stations
	cmp	[WSSwitch],'Y'		; are we switching bios
	jne	noswtbios
	push	cs
	pop	ds
	xor	dx,dx			; set cursor to top of screen
	xor	bx,bx
	mov	ah,2
	int	10h		
	mov	dx,offset ddtmsg
	mov	ah,9
	int	21h
	mov	ah,9
	mov	dx,offset ddtins	; display install message
	int	21h
	call	dispconfig		; display configuration to user
noswtbios:
	cmp	[ws0ismc],'Y'
	jne	ddtskmc

; we now must setup so that master console is pointing to egaterm

	push	es
	les	bx,[scbptr]
	assume	es:gdata
	mov	es,es:[bx+scbtcbpf]	; access the foreground tcb
	assume	es:tcb
	or	[tcbvram],08h
	mov	word ptr [tcbcondd.port],0
	mov	word ptr [tcbcondd],offset [egaterm]
	mov	word ptr [tcbcondd+2],cs
	pop	es
	assume	es:nothing
ddtskmc:
;
; at this point we have determined that driver can be installed
; so we will jump to to logic above which will setup drivers database
;
	jmp	finalstage
ddierror:
	push	cs
	pop	ds
	mov	ah,9
	int	21h

; make sure this driver can't be opened and shrink allocation to header

dder01:
	mov	word ptr [egnanm],'\\'	; can't be opened
	les	bx,[request]
	mov	word ptr es:[bx+14],offset [enddrvr0]
	mov	es:[bx+16],cs
	ret
ddtinit endp 

include cpuspeed.inc
include biosload.inc	

	subttl dispstatmsg - disp station message
	page
;======================================================================
;,fs
; dispstatmsg - disp station message
;
; in:	
;
; out:	
;
;,fe
;=====================================================================
	assume	ds:nothing,es:nothing,ss:nothing
dispstatmsg proc near

; display base xxxxh has

	push	si
	mov	ax,word ptr [si].baseaddr
	mov	cx,4
	mov	si,offset dmsghas
	call	bintohex
	pop	si
	mov	dx,offset dmsgbase
	mov	ah,9
	int	21h
	mov	dx,offset dmsghas
	mov	ah,9
	int	21h

; first zero out counters

	mov	[dmsges],'0'
	mov	[dmsghs],'0'
	mov	[dmsgvs],'0'

; now for each work station on card increment counter for type of
; of work station

	xor	bx,bx
	mov	cx,8			; up to 8 work station on card
dconlp2:
	mov	al,byte ptr [si+bx].stations
	cmp	al,segna
	jne	dcon5
	inc	[dmsges]
	jmp	short dcon7
dcon5:
	cmp	al,svnaplus
	jne	dcon6
	inc	[dmsghs]
	jmp	short dcon7
dcon6:
	cmp	al,svgnaplus
	jne	dcon7
	inc	[dmsgvs]
dcon7:
	inc	bx
	loop	dconlp2
	xor	bx,bx			; indicate and not need
	cmp	[dmsges],'0'		; any egna's
	je	dcon8
	inc	bx			; indicate and is need for next
	mov	dx,offset dmsges
	mov	ah,9
	int	21h
dcon8:
	cmp	[dmsghs],'0'		; any vnaplus
	je	dcon10
	or	bx,bx			; is and needed
	jz	dcon9
	mov	dx,offset dmsgand
	mov	ah,9
	int	21h
dcon9:
	inc	bx
	mov	dx,offset dmsghs
	mov	ah,9
	int	21h
dcon10:
	cmp	[dmsgvs],'0'		; any vgna plus
	je	dcon12
	or	bx,bx			; is and need
	jz	dcon11
	mov	dx,offset dmsgand
	mov	ah,9
	int	21h
dcon11:
	mov	dx,offset dmsgvs
	mov	ah,9
	int	21h
dcon12:

; now display workstation(s).

	mov	dx,offset dmsgws
	mov	ah,9
	int	21h

	ret
dispstatmsg endp


	subttl dispascii - display ascii string
	page
;======================================================================
;,fs
; dispascii - display ascii string
;
; in:	
;	ds:dx -> string
;
; out:	
;
;,fe
;=====================================================================
	assume	ds:nothing,es:nothing,ss:nothing
dispascii proc	near
	push	si
	mov	si,dx
dasciil:
	lodsb
	or	al,al
	jz	dasciie
	mov	dl,al
	mov	ah,2
	int	21h
	jmp	short dasciil
dasciie:
 	pop	si
	ret
dispascii endp

	subttl dispconfig - display configuration to user
	page
;======================================================================
;,fs
; dispconfig - display configuration to user
;
; in:	
;
; out:	
;
;,fe
;=====================================================================
	assume	ds:nothing,es:nothing,ss:nothing
dispconfig proc near

; determine keyboard and serial (if appliable) irq

	mov	dx,offset dmsgkey
	mov	ah,9
	int	21h
	mov	al,'1'
	cmp	[kbirq],irq11		; keyboard can only do 11 and 15
	je	dcon1
	mov	al,'5'
dcon1:
	mov	[dmsgkey2],al
	mov	dx,offset dmsgkey2
	mov	ah,9
	int	21h
	mov	dx,offset dmsgnser
	cmp	[serirq],-1
	je	dcon3
	mov	dx,offset dmsgser
	mov	ah,9
	int	21h
	mov	al,'0'
	cmp	[serirq],irq10
	je	dcon2
	inc	al
dcon2:
	mov	[dmsgser2],al
	mov	dx,offset dmsgser2
dcon3:
	mov	ah,9
	int	21h
	cmp	[HiResGraph],'Y'
	je	dcon3a
	mov	dx,offset dmsgnhr
	mov	ah,9
	int	21h
dcon3a:

; determine type station on master console

	cmp	[ws0ismc],'Y'
	je	dcon4
	mov	dx,offset dmsgcon
	mov	ah,9
	int	21h
	cmp	[VGNASwitch],'Y'
	jne	dcon4
	mov	dx,offset VirtualBios
	mov	ah,9
	int	21h
	mov	dx,offset vgnarom
	call	dispascii
	mov	dl,' '
	mov	ah,2
	int	21h
	mov	dx,offset ddtins
	mov	ah,9
	int	21h
dcon4:

; now for each card on system, display type of stations on system

	mov	si,offset temparea+tempextra
	mov	cx,[noofboards]
dconlp1:
	push	cx
	call	dispstatmsg
	pop	cx
	add	si,type (initstat)
	loop	dconlp1
	ret
dispconfig endp

	subttl dispemsg - disp approviate errormessage
	page
;======================================================================
;,fs
; dispemsg - disp approviate errormessage
;
; in:	
;
; out:	
;
;,fe
;=====================================================================
	assume	ds:nothing,es:nothing,ss:nothing
dispemsg proc near
	push	ax
	or	ax,ax			; no errors then skip
	jz	demnoerror
	push	ax
	mov	ah,9
	mov	dx,offset ddtnins
	int	21h
	pop	ax
	cmp	ax,errlen
	jna	demerror
demnoerror:
	pop	ax
	ret
demerror:
	dec	ax
	push	ax
	mov	ah,9
	mov	dx,offset errmsg
	int	21h
	pop	ax
	mov	bx,ax
	shl	bx,1
	mov	dx,word ptr [bx+errtab]
	mov	ah,9
	int	21h
	mov	dx,offset msgpos
	mov	ah,9
	int	21h
	cmp	[curbase],-1
	jne	demnstart
	mov	dx,offset msgstart
	mov	ah,9
	int	21h
	jmp	short demcont
demnstart:
	mov	dx,offset msgbase
	mov	ah,9
	int	21h
	mov	ax,[curbase]
	mov	si,offset dbase
	mov	cx,4
	call	bintohex
	mov	dx,offset dbase
	mov	ah,9
	int	21h
	mov	dx,offset basecrlf
	cmp	[curserial],0
	je	demnserial
	mov	al,[curserial]
	mov	[dserial],al
	mov	dx,offset msgserial
	mov	ah,9
	int	21h
	mov	dx,offset dserial
demnserial:
	mov	ah,9
	int	21h
demcont:
	mov	dx,offset msgcrlf
	mov	ah,9
	int	21h
	pop	ax
	ret
dispemsg endp

	subttl initparse - initializes parsing line for parsing.
	page
;======================================================================
;,fs
; initparse - initializes parsing line for parsing.
;
; in:	ds:si -> start of line
;
; out:	ds:si -> first paramter in line, line terminated by 0
;
;,fe
;=======k==============================================================
	assume	ds:nothing,es:nothing,ss:nothing
initparse proc near
	push	es

; replace cr with a 0 for termination

	push	ds
	pop	es
	push	di
	mov	di,si
	mov	cx,-1
	mov	al,13			; look for config.sys terminator
	repne	scasb
	mov	al,byte ptr es:[di]
	mov	ah,byte ptr es:[di-1]
	mov	byte ptr es:[di-1],0	; insert our terminator
	pop	di

; search for -v  to indicate that system is paradise master console
; also search for -s to disable unterm's internal setmode handling
; also search for -c to force co-existence, this is use for VGNA+ 
;     coexistence

	push	si
	push	di
iparloop:
	mov	di,si
	lodsb
	or	al,al
	jz	iparexit
	cmp	al,'-'
	jne	iparloop
	mov	al,ds:[di+1]
	and	al,0dfh
	cmp	al,'B'
	jne	iparnob
	mov	[slashb],'Y'
	mov	word ptr ds:[di],2020h
	jmp	short iparloop	
iparnob:		
	cmp	al,'C'
	jne	iparnoc
	mov	[slashc],'Y'
	mov	word ptr ds:[di],2020h
	jmp	short iparloop	
iparnoc:		
	cmp	al,'S'
	jne	iparnos
	mov	[slashs],'Y'
	mov	word ptr ds:[di],2020h
	jmp	short iparloop	
iparnos:		
	cmp	al,'G'
	jne	iparnog
	mov	cs:[HiResGraph],'N'
	mov	word ptr ds:[di],2020h
	jmp	short iparloop	
iparnog:		
	cmp	al,'V'
	jne	iparloop
	mov	[slashp],'Y'
	mov	word ptr ds:[di],2020h
	jmp	short iparloop	
iparexit:
	pop	di
	pop	si

; search for first blank

iploop:
	lodsb
	or	al,al
	je	ipend
	cmp	al,' '
	je	ipend
	cmp	al,9
	jne	iploop
ipend:
	dec	si
	pop	es
	ret
initparse endp

	subttl skipblanks - skip over blanks to first non-blank character
	page
;======================================================================
;,fs
; skipblanks - skip over blanks to first non-blank character
;
; in:	ds:si -> next part of line
;
; out:	ds:si -> first non blank part of line
;	if carry, then we have read end of line
;
;,fe
;=====================================================================
	assume	ds:nothing,es:nothing,ss:nothing
skipblanks proc near
skiploop:
	lodsb
	or	al,al			; end of line
	jz	blankend
	cmp	al,' '			; is it space
	je	skiploop
	cmp	al,9			; is it tab
	je	skiploop
	dec	si
	clc
	ret
blankend:
	dec	si
	mov	ax,end_of_cmd
	stc
	ret
skipblanks endp

	subttl skipcomma - skip over blanks to first non-blank character after comma
	page
;======================================================================
;,fs
; skipcomma - skip over blanks to first non-blank character after comma
;
; in:	ds:si -> next part of line
;
; out:	ds:si -> first non blank part of line after comma
;	if carry, then we have read end of line or no comma
;
;,fe
;=====================================================================
	assume	ds:nothing,es:nothing,ss:nothing
skipcomma proc near
	lodsb
	cmp	al,comma		; is it comma
	jne	commaerror		; mo then we got an error
	clc
	ret
commaerror:
	stc
	ret
skipcomma endp

	subttl testlist - test list for entry in al
	page
;======================================================================
;,fs
; testlist - test list for entry in al
;
; in:	cs:si -> list terminated with 0
;	al -> value to test for
;
; out:	cx -> irq position
;	if carry, not found on list
;
;,fe
;=====================================================================
	assume	ds:nothing,es:nothing,ss:nothing
testlist proc near
	push	ds
	mov	ah,al
	mov	cx,cs
	mov	ds,cx
	xor	cx,cx
testloop:
	inc	cx
	lodsb
	or	al,al			; end of list
	jz	testbad
	cmp	al,ah			; are they the same
	jne	testloop		; test next one
	dec	cx
	pop	ds
	clc
	ret
testbad:
	pop	ds
	stc
	ret
testlist endp

	subttl parsedigit - parse digits from command line
	page
;======================================================================
;,fs
; parsedigit - parse digits from command line
;
; in:	ds:si -> next part of line
;
; out:	ds:si -> first non blank part of line after base address
;	dx:ax -> binary value of digit parse
;	if carry, have read end of line or error parsing digit
;
;,fe
;=====================================================================
	assume	ds:nothing,es:nothing,ss:nothing
parsedigit proc near
	push	bx
	push	cx
	xor	ax,ax
	xor	dx,dx
digitlp:
	mov	cl,byte ptr ds:[si]	; get character from command
	cmp	cl,'0'
	jb	notdigit
	cmp	cl,'9'
	ja	notdigit
	mul	[wordten]
	xor	ch,ch
	sub	cl,'0'
	add	ax,cx
	adc	dx,0
	inc	si
	jmp	short digitlp
notdigit:
	pop	cx
	pop	bx
	ret
parsedigit endp

	subttl parsehex - parse's hex number from line and place it into ax
	page
;======================================================================
;,fs
; parsehex - parse's hex number from line and place it into ax
;
; in:	ds:si -> next part of line
;
; out:	ds:si -> first non blank part of line after hex number
;	ax    -> binary value of hex number
;	if carry, have read end of line or error parsing number
;
;,fe
;=====================================================================
	assume	ds:nothing,es:nothing,ss:nothing
parsehex proc near
	push	cx
	push	dx
	xor	dx,dx
	mov	cx,4			; up to a max of 4 characters
	call	skipblanks
	jc	badhex
hexloop:
	mov	al,byte ptr [si]	; get next hex value
	cmp	al,'0'
	jb	notnumber
	cmp	al,'9'
	ja	notnumber
	sub	al,'0'
	jmp	short sethex
notnumber:
	and	al,0dfh 		; upper case
	cmp	al,'A'
	jb	hexdone 		; we are done
	cmp	al,'F'
	ja	hexdone 		; we are done
	sub	al,'A'- 10		; adjust for digit
sethex:
	shl	dx,4			; mult by 16
	xor	ah,ah
	add	dx,ax
	inc	si
	dec	cx
	jnz	hexloop
hexdone:
	mov	ax,dx			; report number
	clc
	jmp	short hexend
badhex:
	stc
hexend:
	pop	dx
	pop	cx
	ret
parsehex endp

	subttl setdefault - set up defualt serial options
	page
;======================================================================
;,fs
; setdefault - set up defualt serial options
;
; in:	es:di -> initialialization structure
;
; out:	
;
;,fe
;=====================================================================
	assume	ds:nothing,es:nothing,ss:nothing
setdefault proc near
	mov	[definput],64		; default input 64 bytes for mice
	mov	[defoutput],16		; default output 16 bytes
	mov	[defhsoption],'N'	; default hs='N'
	mov	[defcnoption],'L'	; default cn='L'
	push	bx
	push	cx
	mov	cx,8
	xor	bx,bx
sdloop:
	mov	byte ptr es:[di+bx].serenable,'N'  ; disable all serial ports
	mov	byte ptr es:[di+bx].setserial,0  ; no options set
	mov	byte ptr es:[di+bx].stations,snot_install
	inc	bx
	loop	sdloop
	pop	cx
	pop	bx
	ret
setdefault endp

	subttl initialize - initialize serial options to prevous serial options
	page
;======================================================================
;,fs
; initialize - initialize serial options to prevous serial options
;
; in:	es:di -> initialization structure.
;
; out:	
;
;,fe
;=====================================================================
	assume	ds:nothing,es:nothing,ss:nothing
initialize proc near
	push	ax
	push	bx
	mov	bx,[processport]
	mov	ax,[definput]		; transfer default input buffer size
	shl	bx,1
	mov	es:[di+bx].ibuffer,ax
	mov	ax,[defoutput]		; transfer default output buffer size
	mov	es:[di+bx].obuffer,ax
	shr	bx,1
	mov	al,[defhsoption]	; transfer hs= option
	mov	es:[di+bx].hsopt,al
	mov	al,[defcnoption]	; transfer cn= option
	mov	es:[di+bx].cnopt,al
	pop	bx
	pop	ax
	ret
initialize endp

	subttl newdefault - initialize current defaults to prevous selection.
	page
;======================================================================
;,fs
; newdefault - initialize current defaults to prevous selection.
;
; in:	es:di -> initialization structure.
;
; out:	
;
;,fe
;=====================================================================
	assume	ds:nothing,es:nothing,ss:nothing
newdefault proc near
	push	ax
	push	bx
	mov	bx,[processport]
	shl	bx,1
	mov	ax,es:[di+bx].ibuffer
	mov	[definput],ax		; transfer default input buffer size
	mov	ax,es:[di+bx].obuffer
	mov	[defoutput],ax		; transfer default output buffer size
	shr	bx,1
	mov	al,es:[di+bx].hsopt
	mov	[defhsoption],al	; transfer hs= option
	mov	al,es:[di+bx].cnopt
	mov	[defcnoption],al	; transfer cn= option
	pop	bx
	pop	ax
	ret
newdefault endp

	subttl testboard - see if board is egna, vnaplus or vgnaplus
	page
;======================================================================
;,fs
; testboard - see if board is egna, vnaplus or vgnaplus
;
; in:	dx -> baseaddress
;	bx -> card # (0-3, or 0-7 on vnaplus)
;
; out:	al -> board type (as follows)
;		snot_install:	no card install for this station
;		segna:		egna station installed
;		svnaplus:	vna+ station installed
;		svgnaplus:	vgna+ station installed
;	ah -> board revision code (0-7)
;
;,fe
;=====================================================================
	assume	ds:nothing,es:nothing,ss:nothing
testboard proc near
	push	bx
	push	cx
	push	dx
	cmp	bl,4
	jb	not8port
	add	dx,1000h
	sub	bl,4
not8port:
	shl	bx,1
	add	dx,bx			; now dx is pointing to keyboard

; read keyboard and find out type of card on system
; set page 7 of egna doc

	inc	dx
	mov	al,0aah
	call	outcmd
	call	Get55
	cmp	al,55h			; all ok
	jne	sbadcard
	mov	al,0c0h 		; read input command
	call	outcmd
	dec	dx
	mov	cx,-1
	loop	$
	mov	cx,-1
	loop	$
	mov	cx,-1
	loop	$
	mov	cx,-1
	loop	$
	in	al,dx
	test	al,80h			; high bit must always be set
	jz	sbadcard
;
; at this point al has station identification register
; format as follows
;
; bit		7 6 5 4 3 2 1 0
; definition	1 v v v v r r r
;
; where  rrr is revision code 3 bit 0-7
; where  vvvv is video type
; where  bit 7 is always 1
;
; video type definition is as follows
;
; 0 - hercules monochrome
; 1 - color ega
; 2 - color vga
; 3-15 - reserved
;
	mov	bl,al
	shr	bx,3
	and	bx,0fh
	cmp	bl,2			; only support video type 0 - 2 now
	ja	sbadcard
	and	al,07h			; mask out revison
	mov	ah,al
	mov	al,[carddefs+bx]
	jmp	short tbdone
sbadcard:
	mov	al,snot_install
tbdone:
	pop	dx
	pop	cx
	pop	bx
	ret
testboard endp

	subttl setboard - set board type by checking configuration
	page
;======================================================================
;,fs
; setboard - set board type by checking configuration
;
; in:	es:di -> init structure
;	ax -> base address
;
; out:	
;
;,fe
;=====================================================================
	assume	ds:nothing,es:nothing,ss:nothing
setboard proc near
	push	ax
	push	bx
	push	cx
	push	dx

; verify type of board install on system, first we will test the
; first 4 cards on system.

	mov	[VGNAIns],'N'		; reset flag for bios logic
	mov	byte ptr es:[di].board,snot_install
	mov	dx,ax			; set base address
	xor	bx,bx			; set pointer to first card on board
	mov	cx,4			; do first  4 cards
sbloop1:
	call	testboard		; test board
	cmp	al,svgnaplus		; VGNA Installed
	jne	sbskip0
	mov	[VGNAIns],'Y'		; flag it for bios logic
sbskip0:
	mov	byte ptr es:[di+bx].versions,ah
	mov	byte ptr es:[di+bx].stations,al
	cmp	al,byte ptr es:[di].board
	jbe	sbskip1
	mov	byte ptr es:[di].board,al
sbskip1:
	inc	bx
	loop	sbloop1

; if current configuration is a vnaplus board then we will
; need to test the remain boards on systems

	cmp	byte ptr es:[di].board,svnaplus
	jne	notvnaplus
	mov	cx,4			; handle 4 more addition cards
sbloop2:
	call	testboard
	mov	byte ptr es:[di+bx].versions,ah
	mov	byte ptr es:[di+bx].stations,al
	inc	bx
	loop	sbloop2
notvnaplus:
	cmp	[VGNAIns],'Y'		; VGNA+ system
	jne	notvgnaplus
	inc	[VGNACount]		; increment counter
notvgnaplus:
	pop	dx
	pop	cx
	pop	bx
	pop	ax
	ret
setboard endp

	subttl chkbase - check out base address to make sure it is valid
	page
;======================================================================
;,fs
; chkbase - check out base address to make sure it is valid
;
; in:	ax -> base address
;	es:di -> point to egna init structure
;
; out:	ax -> error code if carry set
;	 bad_base: bad base address
;	 dup_base: duplicate base address
;
;,fe
;=====================================================================
	assume	ds:nothing,es:nothing,ss:nothing
chkbase proc near
	push	si
	mov	si,offset temparea+tempextra
cbloop:
	cmp	si,di			; are we at end of structures
	je	cbtest
	cmp	ax,es:[si].baseaddr	; duplicate found
	je	cbdup
	add	si,type (initstat)
	jmp	short cbloop

; duplicate base address found in command line

cbdup:
	mov	ax,dup_base
	stc
	jmp	short cbdone
cbtest:
	clc
cbdone:
	pop	si
	ret
chkbase endp

	subttl getoption - determines optional parameter
	page
;======================================================================
;,fs
; getoption - determines optional parameter
;
; in:	ds:si -> next part of line
;
; out:	ds:si -> first non blank part of line after base address
;	bx -> option
;	if carry, have found option not on list
; 	 errors:
;	  end_of_serial: end of serial processing
;	  end_of_cmd: end of command line
;	  bad_serial: bad serial command
;
;,fe
;=====================================================================
	assume	ds:nothing,es:nothing,ss:nothing
getoption proc near
	call	skipblanks
	jc	gopterr
	mov	bx,si			; save current position
	call	skipcomma
	jnc	gopt1
	cmp	al,slash
	jne	goptbad
	mov	si,bx			; restore original position
	mov	ax,end_of_serial
	jmp	short gopterr
gopt1:
	xor	bx,bx
	lodsw				; load option into ax
	and	ax,0dfdfh		; upper case it
gopt2:
	mov	dx,word ptr [optlist+bx]
	or	dx,dx
	jz	goptbad
	cmp	ax,dx			; are they the same
	je	goptfound
	inc	bx
	inc	bx
	jmp	short gopt2		; check next on list
goptfound:
	shr	bx,1
	mov	ax,bx
	inc	ax
	push	ax
	call	skipblanks		; remove banks i.e (ib	= )
	jc	goptbad2
	lodsb
	cmp	al,'='			; is it equals
	jne	goptbad2
	pop	ax
	clc
	ret
goptbad2:
	pop	ax
goptbad:
	mov	ax,bad_serial
gopterr:
	stc
	ret
getoption endp

	subttl parseport - parses serial port in form /px.....
	page
;======================================================================
;,fs
; parseport - parses serial port in form /px.....
;
; in:	ds:si -> next part of line
;	es:di -> points to init structure
;
; out:	ds:si -> first non blank part of line after base address
;	if carry, have read end of line or error parsing base address
; 	 errors:
;         end_of_serial: end of serial processing
;         end_of_cmd: end of command line
;	  bad_port: bad serial port (4 port board)
;	  bad_port8: bad serial port (8 port board)
;	  dup_port: duplicate serial
;	  no_port: station not installed.
;	  no_serial: serial logic not installed.
;
;,fe
;=====================================================================
	assume	ds:nothing,es:nothing,ss:nothing
parseport proc near
	call	skipblanks
	jc	pportend
	mov	bx,si			; save current position
	cmp	byte ptr ds:[si],slash
	jne	bport			; no then they specified it wrong
	inc	si
	call	skipblanks
	jc	notport
	lodsb
	and	al,0dfh 		; upper case it
	cmp	al,'P'			; is it p for /px
	je	cport
notport:

; we must be at end of serial processing and begining to process
; another board

	mov	si,bx
	mov	ax,end_of_serial
	jmp	short bport2
cport:
	cmp	[serirq],-1
	jne	pp1
	mov	ax,no_serial
	jmp	short bport2
pp1:
	lodsb
	and	al,0dfh
	cmp	al,'A'			; must be range a - (max)  (d or h)
	jb	bport
	cmp	al,'H'			; can't be above 8 for this driver
	ja	bport
	cmp	es:[di].board,svnaplus	; is it 8 port vna+ board
	je	cport1
	cmp	al,'D'			; can't be above D for EGNA
	ja	bport
cport1:
	mov	[curserial],al
	sub	al,'A'			; make it range 0 - (max-1)
	xor	ah,ah
	mov	bx,ax			; set in bx
	cmp	es:[di+bx].serenable,'Y'; is serial definition already define
	je	dupport
	mov	es:[di+bx].serenable,'Y'; indicate serial is define for port
	mov 	processport,bx		; save port processing

; now we will check to make sure station is installed for this port

	cmp	es:[di+bx].stations,snot_install
	je	noserial
	clc
	jmp	short pportend

; enter if we don't have a station installed for specified port

noserial:
	mov	ax,no_port
	jmp	short bport2

; enter here if we have a duplicate serial definition defined

dupport:
	mov	ax,dup_port
	jmp	short bport2

; error processing port than we display apporviate message
; depending on if board is 4 port or 8 port board

bport:
	mov	ax,bad_port
	cmp	es:[di].board,svnaplus
	jne	bport2
	mov	ax,bad_port8
bport2:
	stc
pportend:
	ret
parseport endp

	subttl processib - process input buffer
	page
;======================================================================
;,fs
; processib - process input buffer
;
; in:	ds:si -> next part of line
;	bx -> serial port being process
;	es:di -> points to init structure
;
; out:	ds:si -> first non blank part after input buffer
;	if carry, have found option not on list
; 	 errors:
;	  bad_ib: invalid input buffer specified
;	  dup_ib: duplicate input buffer specified
;
;,fe
;=====================================================================
	assume	ds:nothing,es:nothing,ss:nothing
processib proc near
	call	parsedigit		; parse number
	cmp	ax,16			; if below 16 bytes then error
	jb	badib
	mov	bx,[processport]
	shl	bx,1
	mov	es:[di+bx].ibuffer,ax
	shr	bx,1
	test	es:[di+bx].setserial,ib_option	; has user already defined it
	jnz	errorib
	or	es:[di+bx].setserial,ib_option	; indicate that we done it
	clc
	ret
errorib:
	mov	ax,dup_ib		; indicate duplicate input
	jmp	short iberror
badib:
	mov	ax,bad_ib
iberror:
	stc
	ret
processib endp

	subttl processob - process output buffer
	page
;======================================================================
;,fs
; processob - process output buffer
;
; in:	ds:si -> next part of line
;	es:di -> points to init structure
;
; out:	ds:si -> first non blank part after output buffer
;	bx    -> serial port being process
;	if carry, have found option not on list
;	 errors:
;	  bad_ib: invalid input buffer specified
;	  dup_ib: duplicate input buffer specified
;
;,fe
;=====================================================================
	assume	ds:nothing,es:nothing,ss:nothing
processob proc near
	call	parsedigit		; parse number
	cmp	ax,16			; if below 16 bytes then error
	jb	badob
	mov	bx,[processport]
	shl	bx,1
	mov	es:[di+bx].obuffer,ax
	shr	bx,1
	test	es:[di+bx].setserial,ob_option	; has user already defined it
	jnz	errorob
	or	es:[di+bx].setserial,ob_option	; indicate that we done it
	clc
	ret
errorob:
	mov	ax,dup_ob		; indicate duplicate output
	jmp	short oberror
badob:
	mov	ax,bad_ob
oberror:
	stc
	ret
processob endp

	subttl processhs - process hs= option
	page
;======================================================================
;,fs
; processhs - process hs= option
;
; in:	ds:si -> next part of line
;	bx -> serial port being process
;	es:di -> points to init structure
;
; out:	ds:si -> first non blank part after hs= option
;	if carry, have found option not on list
;	 errors:
;	  bad_hs: invalid hs option
;	  dup_hs: duplicate hs option
;
;,fe
;=====================================================================
	assume	ds:nothing,es:nothing,ss:nothing
processhs proc near
	lodsb				; get character
	and	al,0dfh 		; make it upper case
	push	si
	mov	si,offset hslist
	call	testlist
	pop	si
	jc	badhs
	mov	bx,[processport]
	mov	es:[di+bx].hsopt,al	; save option
	mov	ax,dup_hs
	test	es:[di+bx].setserial,hs_option	; has user already defined it
	jnz	errorhs
	or	es:[di+bx].setserial,hs_option	; indicate that we done it
	clc
	ret
badhs:
	mov	ax,bad_hs
errorhs:
	stc
	ret
processhs endp

	subttl processcn - process cn= option
	page
;======================================================================
;,fs
; processcn - process cn= option
;
; in:	ds:si -> next part of line
;	es:di -> points to init structure
;
; out:	ds:si -> first non blank part after cn= option
;	bx    -> serial port being process
;	if carry, have found option not on list
;	 errors:
;	  bad_cn: invalid cn option
;	  dup_cn: duplicate cn option
;
;,fe
;=====================================================================
	assume	ds:nothing,es:nothing,ss:nothing
processcn proc near
	lodsb				; get character
	and	al,0dfh 		; make it upper case
	push	si
	mov	si,offset cnlist
	call	testlist
	pop	si
	jc	badcn
	mov	bx,[processport]
	mov	es:[di+bx].cnopt,al	; save option
	mov	ax,dup_cn
	test	es:[di+bx].setserial,cn_option	; has user already defined it
	jnz	errorhs
	or	es:[di+bx].setserial,cn_option	; indicate that we done it
	clc
	ret
badcn:
	mov	ax,bad_cn
	stc
	ret
processcn endp

;=======================================================================

	subttl parsebase - parse base address from command line in form  /hex
	page
;======================================================================
;,fs
; parsebase - parse base address from command line in form  /hex
;
; in:	ds:si -> next part of line
;	es:di -> points to init structure
;
; out:	ds:si -> first non blank part of line after base address
;	ax -> binary value of base address
;	if carry, have read end of line or error parsing base address
; 	 errors:
;	  end_of_cmd: end of command line
;	  bad_base: bad base address
;	  dup_base: duplicate base address
;
;,fe
;=====================================================================
	assume	ds:nothing,es:nothing,ss:nothing
parsebase proc near
	mov	[curserial],0		; reset current serial port
	call	skipblanks
	jnc	base1
	mov	ax,end_of_cmd
	ret
base1:
	lodsb
	cmp	al,slash		; must be forward-slash
	jne	basebad
	call	parsehex		; get hex number
	jc	basebad 		; error must be bad
	mov	es:[di].baseaddr,ax
	mov	[curbase],ax
	call	chkbase 		; validate base address
	jc	baseerror
	call	setboard		; set board type
	cmp	byte ptr es:[di].board,snot_install
	je	nobaseerr
	clc
	ret
nobaseerr:
	mov	ax,base_not_install	; base address not installed
	jmp	short baseerror
basebad:
	mov	ax,bad_base		; indicate bad base address
baseerror:
	stc
	ret
parsebase endp

	subttl parseirq - parse irq address from command line in decimal form
	page
;======================================================================
;,fs
; parseirq - parse irq address from command line in decimal form
;
; in:	ds:si -> next part of line
;
; out:	ds:si -> first non blank part of line after base address
;	al    -> binary value of irq
;	if carry, have read end of line or error parsing base address
; 	 errors:
;	  bad_irq: bad irq specified
;
;,fe
;=====================================================================
	assume	ds:nothing,es:nothing,ss:nothing
parseirq proc near
	call	skipblanks
	jc	irqerror
	call	parsedigit		; get digit

; irq found is in al, valid irq from irq list

	push	si
	mov	si,offset irqlist
	call	testlist		; test irq list
	pop	si
	jc	irqerror
	clc
	ret
irqerror:
	mov	ax,bad_irq
	stc
	ret
parseirq endp

	subttl parsefirst - parse first base address and irqs in form  /hex,irq,irq
	page
;======================================================================
;,fs
; parsefirst - parse first base address and irqs in form  /hex,irq,irq
;
; in:	ds:si -> next part of line
;	es:di -> init structure
;
; out:	ds:si -> after first part of command line
;	if carry, add an error as follows
;	 errors:
;	  end_of_cmd: end of command line
;	  bad_base: bad base address
;	  bad_keyirq: bad keyboard irq specified
;	  bad_serirq: bad serial irq specified
;	  dup_key_ser: duplicate irq, keyboard irq = serial irq
;
;,fe
;=====================================================================
	assume	ds:nothing,es:nothing,ss:nothing
parsefirst proc near
	call	parsebase		; parse out base address
	jnc	fc0
	cmp	ax,end_of_cmd
	jne	firsterror
	mov	ax,bad_base
	jmp	short firsterror
fc0:
	mov	ax,es:[di].baseaddr	; setup dxxd and exxd save values
	or	[basedxxd],ax
	or	[baseexxd],ax
	call	skipblanks
	jc	fckeybad
	call	skipcomma
	jc	fckeybad
	call	parseirq		; parse out keyboard irq
	jnc	fc1
	cmp	ax,end_of_cmd
	jne	firsterror
fckeybad:
	mov	ax,bad_keyirq
	jmp	short firsterror
fc1:
	cmp	al,irq10		; keyboard can't have IRQ 10
	je	fckeybad		; why did they design it this way
	mov	cs:[kbirq],al
	call	skipblanks
	jnc	okser
	inc	[noofboards]
	xor	ax,ax
	jmp	short firsterror
okser:
	call	skipcomma
	jnc	okser2
	dec	si			; put comma back
	jmp	short nosirq
okser2:
	call	parseirq		; parse out serial irq
	jnc	firstok
	cmp	ax,bad_irq		; was it bad irq
	jne	firsterror		; no than error out
fcserbad:
	mov	ax,bad_serirq		; make it bad serial irq
	jmp	short firsterror
firstok:
	cmp	al,irq15		; serial can't have IRQ 15
	je	fcserbad
	cmp	al,cs:[kbirq]		; is keyboard irq = serial irq
	je	firstdup
	mov	cs:[serirq],al		; save serial irq
nosirq:
	xor	ax,ax			; indicate no error
	inc	[noofboards]
	clc
	jmp	short firstend
firstdup:
	mov	ax,dup_key_ser		; indicate duplicate keyboard-serial
firsterror:
	stc
firstend:
	ret
parsefirst endp

	subttl parseserial - parse serial irq info in form  /px,ib=xxx,ob=xxx,hs=x,cn=x
	page
;======================================================================
;,fs
; parseserial - parse serial irq info in form  /px,ib=xxx,ob=xxx,hs=x,cn=x
;
; in:	ds:si -> next part of line
;
; out:	ds:si -> after first part of command line
;	if carry, add an error as follows
;	 errors:
;	  bad_serial: invalid serial command.
;	  end_of_cmd: end of command line
;	  bad_port: bad serial port (4 port board)
;	  bad_port8: bad serial port (8 port board)
;	  dup_port: duplicate serial
;	  bad_hs: invalid hs option
;	  dup_hs: duplicate hs option
;	  bad_cn: invalid cn option
;	  dup_cn: duplicate cn option
;
;,fe
;=====================================================================
	assume	ds:nothing,es:nothing,ss:nothing
parseserial proc near
serialloop:
	call	parseport		; parse out port
	jc	serialtest		; if error dump error
sportloop:
	call	initialize		; set parameters, to last one set
	call	getoption
	jnc	sokoption
	cmp	ax,end_of_serial	; end of serial processing
	jne	serialerr
	jmp	short serialnext
sokoption:
	shl	bx,1
	call	word ptr [opttab+bx]	; process option
	jc	serialerr
	call	newdefault		; set up new default options
	call	skipblanks
serialnext:
	cmp	byte ptr ds:[si],comma
	je	sportloop
	jmp	short serialloop
serialtest:
	cmp	ax,end_of_serial	; is this end of serial processing
	je	serialend
	cmp	ax,end_of_cmd		; is this end of command line
	jne	serialerr
serialend:
	clc				; yes
	ret
serialerr:
	stc
	ret
parseserial endp

	subttl parsecmd - parse command line 
	page
;======================================================================
;,fs
; parsecmd - parse command line 
;
; place command line data into installation database at 
; end of code.
;
; overview of logic.
;
;	    parse first board, for base address, keyboard irq and
;		serial irq
;	    parse serial options if any
;	    while not end of parse line
;		parse boards base address
;		parse serial options if any.
;
; in:	ds:si -> command line.
;
; out:	if cy error code is in ax
;
;,fe
;=====================================================================
	assume	ds:nothing,es:nothing,ss:nothing
parsecmd proc near
	push	bx
	push	cx
	push	dx
	push	si
	push	di
	push	ds
	push	es
	cld
	mov	ax,cs
	mov	es,ax
	call	initparse		; init parsing subsystem
	mov	di,offset temparea+tempextra
	call	setdefault		; setup default paramters
	call	parsefirst		; parse first board
	jc	parseend
	call	parseserial		; parse serial logic
	jc	parseend
parselp:
	add	di,type (initstat)	; adjust to next baord
	call	setdefault		; setup default paramters
	call	parsebase		; parse base address
	jc	parseend
	inc	[noofboards]		; increment # of boards
	call	parseserial		; parse serial logic
	jnc	parselp
parseend:
	pop	es
	pop	ds
	pop	di
	pop	si
	pop	dx
	pop	cx
	pop	bx
	ret
parsecmd endp

;===================== end of parsing logic ===========================

IFDEF DISABLE_CPUSPEED
checkspeed  proc  near
	    pushf	;11/20/92
	    sti		;11/20/92

            push  ax
            push  cx
            push  dx

            push  es

            mov   ax,0
            mov   es,ax
            mov   cx,es:[046ch]
loop1:
            cmp   cx,es:[046ch]    ; wait for beginning of a timer tick
            je    loop1
            xor   ax,ax
            xor   dx,dx
            mov   cx,es:[046ch]
loop2:
            add   ax,1             ; count while waiting for next timer tick
            adc   dx,0
            cmp   cx,es:[046ch]
            je    loop2
 
            mov   al,ah
            mov   ah,dl
            mov   dl,dh
            xor   dh,dh    
                            ;div  256
            mov   cl,3
            shr   ax,cl
            mov   cl,3
            shl   dx,cl
            or    ah,dl
            shr   ax,1
                           ;div 4096
	    or	  ax,ax				; make sure that never 0
	    jnz	  CSpeed1			; or we will wait for long
	    inc	  ax				; time on a slow machine
CSpeed1:
            mov   [cpuspeed],ax
            pop   es
            pop   dx
            pop   cx
            pop   ax
	    popf	;11/20/92
            ret
checkspeed endp

ENDIF


	subttl chkmouse - verify if $$mouse.sys is installed
	page
;======================================================================
;,fs
; chkmouse - verify if $$mouse.sys is installed
;
; if serial support is included, egna driver cannot 
; be installed on system.
;
; in:	
;
; out:	
;
;,fe
;=====================================================================
	assume	ds:nothing,es:nothing,ss:nothing
chkmouse proc near
	push	ds
	push	cs
	pop	ds
	cmp	[serirq],-1		; serial logic installed???
	je	nomouse
	mov	dx,offset [moudriver]
	mov	ax,3d00h
	int	21h
	jc	nomouse
	pushf
	mov	ah,3eh
	int	21h
	popf
nomouse:
	pop	ds
	ret
chkmouse endp

	subttl installirq - install keyboard irq or serial irq
	page
;======================================================================
;,fs
; installirq - install keyboard irq or serial irq
;
; in:	al -> irq  (irq10, irq11 or irq15)
;	dx -> offset to irq routine
;
; out:	
;
;,fe
;=====================================================================
	assume	ds:nothing,es:nothing,ss:nothing
installirq proc near
	push	ds
	push	cs
	pop	ds
	push	ax			; save irq for seting up main 8259

; set interupt for irq using function 25h

	add	al,72h-irq10
	mov	ah,25h
	int	21h
	pop	ax			; retrieve irq

; now mask in irq on 8259h

	mov	ah,not 4
	cmp	al,irq10
	je	set8259
	mov	ah,not 8
	cmp	al,irq11
	je	set8259
	mov	ah,not 80h
set8259:
	in	al,0a1h
	and	al,ah			; set mask for 8259 #2
	out	0a1h,al
	in	al,21h
	and	al,not 2		; set mask for 8259 #1
	out	21h,al
	pop	ds
	ret
installirq  endp

	subttl configcard - configure egna or vnaplus cards
	page
;======================================================================
;,fs
; configcard - configure egna or vnaplus cards
;
; in:	cs:si -> points to egna initialization structure
;	bx -> board #
;
; out:	
;
;,fe
;=====================================================================
	assume	ds:nothing,es:nothing,ss:nothing
configboard proc near
	push	ax
	push	bx
	push	cx
	push	dx

; if we are using serial interupts, we must clear out the ier's
; for each serial port on system

	cmp	[serirq],-1
	je	skipier
	push	bx
	push	si
	mov	bx,cs:[si].baseaddr
	mov	si,offset serialtable
	cld
	mov	cx,4
	cmp	byte ptr cs:[si].board,svnaplus
	jne	setierloop
	add	cx,4
setierloop:
	lodsw				; get address from table
	or	ax,bx			; or in base
	mov	dx,ax
	xor	al,al
	out	dx,al
	loop	setierloop
	pop	si
	pop	bx
skipier:

	push	bx

; now setup up board 8259's for Keyboard

	mov	dx,cs:[si].baseaddr
	add	dx,8			; address the first egna 8259 register
	mov	al,00010111b		; icw1 - need icw4, single, edge triggered
	out	dx,al
	jmp	$+2
	inc	dx			; address the second egna 8259 register
	mov	al,00000000b		; icw2 - interrupt type 0
	out	dx,al
	jmp	$+2			; (skipping icw3)
	mov	al,00001001b		; icw4 - select 8086, buffered slave
	out	dx,al
	jmp	$+2
	mov	al,0ffh 		; disable all interupts for default
	out	dx,al

; clear data in keyboard if any

	push	cx
	mov	cx,4
	mov	dx,cs:[si].baseaddr
cbkbloop1:
	in	al,dx
	add	dl,2
	loop	cbkbloop1
	cmp	byte ptr cs:[si].board,svnaplus
	jne	skipkbloop
	mov	cx,4
	mov	dx,cs:[si].baseaddr
	add	dx,1000h
cbkbloop2:
	in	al,dx
	add	dl,2
	loop	cbkbloop2
skipkbloop:
	pop	cx

; now setup up board 8259's for Serial Interupts

	mov	dx,cs:[si].baseaddr
	add	dx,1008h		; address the first egna 8259 register
	mov	al,00010111b		; icw1 - need icw4, single, edge triggered
	out	dx,al
	jmp	$+2
	inc	dx			; address the second egna 8259 register
	mov	al,00000000b		; icw2 - interrupt type 0
	out	dx,al
	jmp	$+2			; (skipping icw3)
	mov	al,00001001b		; icw4 - select 8086, buffered slave
	out	dx,al
	jmp	$+2
	xor	al,al			; enable all interupts for default
	out	dx,al
	pop	bx

; setup cxxd register, for system configuration

	mov	dx,cs:[si].baseaddr
	add	dx,0c00dh		; point to cxxd
	mov	al,00000111b		; enable parallal, disable serial
					; set irq as past through
	cmp	[serirq],-1
	je	cbnoserial		; skip if serial is not used
	or	al,00001000b		; enable serial support
cbnoserial:
	or	bx,bx			; check to see if first work station
	jnz	cbset			; no...then set pass through
	cmp	[kbirq],irq11		; is keyboard set to irq 11
	jne	cbnotirq11
	or	al,00100000b		; set up for irq 11, irq 10
	jmp	short cbset
cbnotirq11:
	or	al,10000000b		; set up for irq 15, irq 10
	cmp	[serirq],-1		; none install
	je	cbset			; defualt to irq 15, irq 10
	cmp	[serirq],irq10
	je	cbset			; set up for irq 15, irq 10
	or	al,00100000b		; setup for  irq 15, irq 11
cbset:
	out	dx,al
	mov	dx,[basedxxd]
	mov	al,01h
	out	dx,al
	cmp	[serirq],-1
	jne	cbsset
	dec	al
cbsset:
	mov	dx,[baseexxd]
	out	dx,al

; now we must enable interupts and video for station

	mov	dx,cs:[si].baseaddr
	add	dl,0ch
	mov	al,03h
	or	bx,bx
	jz	enablefirst
	dec	al
enablefirst:
	out	dx,al

; if serial ports are enable we must set eoi to pics

	cmp	[serirq],-1
	je	skipeoi
	mov	dx,cs:[si].baseaddr
	add	dx,1008h
	mov	al,20h
	out	dx,al			; send eoi to boards serial pic
	jmp	$+2
	jmp	$+2
	mov	dx,0a0h
	out	dx,al			; send eoi to upper motherboard pic
	jmp	$+2
	jmp	$+2
	mov	dx,20h
	out	dx,al			; send eoi to main motherboard pic
skipeoi:

	pop	dx
	pop	cx
	pop	bx
	pop	ax
	ret
configboard endp

	subttl configdriver - configure unterm driver
	page
;======================================================================
;,fs
; configdriver - configure unterm driver
;
; for each board on system
;  call configboard to configurated the card
; setup irq for keyboard
; if serial logic is enable then
;  setup irq for serial
;  setup up int 14 intercept
;
; in:	
;
; out:	
;
;,fe
;=====================================================================
	assume	ds:nothing,es:nothing,ss:nothing
configdriver proc near
	push	bx
	push	cx
	push	si

; now setup 8259s for keyboard irq

	mov	al,[kbirq]
	mov	dx,offset keybd_irq	; keyboard irq routine
	call	installirq

; if serial logic is installed, setup up 8259s for serial irq
; and then call install14 to install int 14 interface

	cmp	[serirq],-1		; if serial irqs installed?
	je	cdrvskip
	mov	al,[serirq]
	mov	dx,offset serial_irq	; serial irq routine
	call	installirq

cdrvskip:
	xor	bx,bx
	mov	cx,[noofboards]
	mov	si,offset temparea+tempextra
cdrvloop:
	call	configboard
	inc	bx
	add	si,type (initstat)
	loop	cdrvloop
	pop	si
	pop	cx
	pop	bx
	ret
configdriver endp

	subttl paradise16bit - place paradise 16 bit card into 8 bit mode. 
	page
;======================================================================
;,fs
; paradise16bit - place paradise 16 bit card into 8 bit mode. 
;
; this information was provided by amr
;
; in:	
;
; out:	
;
;,fe
;=====================================================================
	assume	ds:nothing,es:nothing,ss:nothing
paradise16bit proc near
	push	ax
	push	dx

; need to add a check for paradise card here

	cmp	[slashp],'N'
	jne	skipparadise

; place paradise card into 8 bit mode

	mov	dx,03ceh		; point to index register
	mov	al,0fh
	out	dx,al
	jmp	$+2
	jmp	$+2
	inc	dx			; point to data register
	in	al,dx
	jmp	$+2
	jmp	$+2
	and	al,0f0h
	or	al,05h
	push	ax
	dec	dx			; point to index register
	mov	al,0fh
	out	dx,al
	jmp	$+2
	jmp	$+2
	inc	dx			; point to data register
	pop	ax
	out	dx,al
	jmp	$+2
	jmp	$+2
	dec	dx			; point to index register
	mov	al,0bh
	out	dx,al
	jmp	$+2
	jmp	$+2
	inc	dx			; point to data register
	in	al,dx
	jmp	$+2
	jmp	$+2
	and	al,0fbh
	push	ax			; save result
	dec	dx			; point to index register
	mov	al,0bh
	out	dx,al
	jmp	$+2
	jmp	$+2
	inc	dx			; point to data register
	pop	ax			; get result save above
	out	dx,al
skipparadise:
	pop	dx
	pop	ax
	ret
paradise16bit endp

	subttl checkcoexist - check for coexistence with another video card.
	page
;======================================================================
;,fs
; checkcoexist - check for coexistence with another video card.
;
; currently coexistence only works with vnaplus.
; -C is use to force co-existence and is required with VGNA+
;
; in:	
;
; out:	
;
;,fe
;=====================================================================
	assume	ds:nothing,es:nothing,ss:nothing
checkcoexist proc near
	push	ax
	push	dx
	push	si
	push	ds
	mov	ah,'N'
	cmp	[slashc],'Y'
	je	iscoexist
	mov	si,offset temparea+tempextra
	cmp	byte ptr cs:[si].board,svnaplus
	je	dovnatest
	mov	dx,word ptr cs:[si].baseaddr
	add	dl,0fh
	mov	al,0fh
	out	dx,al			; switch out first board
	push	ax
	push	dx
	call	VGACoExist		; see if coexistence		
	pop	dx
	pop	ax
	jnc	iscoexist
	xor	al,al
	out	dx,al
	call	paradise16bit		; do stuff for 16 bit
	mov	ah,'Y'
	jmp	short iscoexist

dovnatest:
	push	ds
	mov	ds,[mctcb]
	assume	ds:tcb
	mov	al,[tcbstation]
	pop	ds
	assume	ds:nothing
	mov	ah,'Y'
	or	al,al
	jz	iscoexist
	cmp	al,4
	je	iscoexist
	call	paradise16bit
	mov	ah,'N'
iscoexist:
	mov	[ws0ismc],ah
noncoexist:
	pop	ds
	pop	si
	pop	dx
	pop	ax
	ret
checkcoexist endp


WaitVert proc	near
	 push	ax
	 push	dx
	
	 mov	dx,3dah
wvert:
	 in	al,dx
	 test	al,8
	 jz	wvert
	  
	 pop	dx
	 pop	ax
	 ret
WaitVert endp

VGACoExist proc	near
	cli
	call	WaitVert
	mov	dx,3d4h
	mov	al,14
	out	dx,al
	jmp	$+2
	inc	dx
	in	al,dx
	jmp	$+2
	push	ax
	mov	ah,al
	inc	ah
	dec	dx
	mov	al,14
	out	dx,al
	jmp	$+2
	inc	dx
	mov	al,ah
	out	dx,al
	jmp	$+2
	dec	dx
	call	WaitVert
	mov	al,14
	out	dx,al
	jmp	$+2
	inc	dx
	in	al,dx
	jmp	$+2
	dec	dx
	cmp	al,ah
	pop	ax
	pushf
	mov	ah,al
	mov	al,14
	out	dx,al
	jmp	$+2
	inc	dx
	mov	al,ah
	out	dx,al
	jmp	$+2
	popf
	je	is_coexist
	sti
	stc
	ret
is_coexist:
	sti
	clc
	ret	
VGACoExist endp



	subttl initstation - initialize video bios by calling c000:3
	page
;======================================================================
;,fs
; initstation - initialize video bios by calling c000:3
;
; this routine is called by dostation, when we have detected that we
; should initialize the video hardware for desire station. this code
; uses the video initialization routine in the video bios located at
; c000:0003	0
;
; in:	
;
; out:	
;
;,fe
;=====================================================================
	assume	ds:nothing,es:nothing,ss:nothing
initstation proc near
	pusha
	push	es
	xor	ax,ax
	mov	es,ax
	mov	ax,word ptr es:[10h*4]
	mov	cs:[off10],ax
	mov	ax,word ptr es:[10h*4+2]
	mov	cs:[seg10],ax
	mov	ax,word ptr es:[1dh*4]
	mov	cs:[off1d],ax
	mov	ax,word ptr es:[1dh*4+2]
	mov	cs:[seg1d],ax
	mov	ax,word ptr es:[1fh*4]
	mov	cs:[off1f],ax
	mov	ax,word ptr es:[1fh*4+2]
	mov	cs:[seg1f],ax
	mov	ax,word ptr es:[43h*4]
	mov	cs:[off43],ax
	mov	ax,word ptr es:[43h*4+2]
	mov	cs:[seg43],ax
	mov	ax,word ptr es:[6dh*4]
	mov	cs:[off6d],ax
	mov	ax,word ptr es:[6dh*4+2]
	mov	cs:[seg6d],ax
	mov	ax,word ptr es:[04a8h]
	mov	cs:[off4a8],ax
	mov	ax,word ptr es:[04aah]
	mov	cs:[seg4a8],ax

;
; Set INT 1dh vector to c000:0090h
;
	mov	word ptr es:[1dh*4],0090h
	mov	word ptr es:[1dh*4+2],0c000h
;
; Set INT 1fh vector to c000:0fb0h
;
	mov	word ptr es:[1fh*4],00fb0h
	mov	word ptr es:[1fh*4+2],0c000h
;
; Set INT 43h vector to c000:0bb0h
;
	mov	word ptr es:[43h*4],00bb0h
	mov	word ptr es:[43h*4+2],0c000h
;
; Set INT 6dh vector to c000:073f2h
;
	mov	word ptr es:[6dh*4],073f2h
	mov	word ptr es:[6dh*4+2],0c000h
;
; Set dword at 40:a8h to c000:43f0h
;
	mov	word ptr es:[04a8h],043f0h
	mov	word ptr es:[04aah],0c000h

	pusha
	push	ds
	push	es

	db	9ah
	dw	00003h			; call c000:0003
	dw	0c000h

	pop	es
	pop	ds
	popa
	xor	ax,ax
	mov	es,ax
	mov	ax,cs:[off10]
	cli
	mov	word ptr es:[10h*4],ax
	mov	ax,cs:[seg10]
	mov	word ptr es:[10h*4+2],ax
	mov	ax,cs:[off1d]
	mov	word ptr es:[1dh*4],ax
	mov	ax,cs:[seg1d]
	mov	word ptr es:[1dh*4+2],ax
	mov	ax,cs:[off1f]
	mov	word ptr es:[1fh*4],ax
	mov	ax,cs:[seg1f]
	mov	word ptr es:[1fh*4+2],ax
	mov	ax,cs:[off43]
	mov	word ptr es:[43h*4],ax
	mov	ax,cs:[seg43]
	mov	word ptr es:[43h*4+2],ax
	mov	ax,cs:[off6d]
	mov	word ptr es:[6dh*4],ax
	mov	ax,cs:[seg6d]
	mov	word ptr es:[6dh*4+2],ax
	mov	ax,cs:[off4a8]
	mov	word ptr es:[04a8h],ax
	mov	ax,cs:[seg4a8]
	mov	word ptr es:[04aah],ax
	sti
	pop	es
	popa
	ret
initstation endp



	subttl  dostation - initialize video bios and also bankswitch bios in and out
	page
;======================================================================
;,fs
; dostation - initialize video bios and also bankswitch bios in and out
;
; this routine is called by initbios, when we have detected that we
; should initialize the video hardware for desire station. this code
; uses the video initialization routine in the video bios located at
; c000:0003.  This code will also manage switching in BIOS if necessary
;
; in:	
;
; out:	
;
;,fe
;=====================================================================
	assume	ds:nothing,es:nothing,ss:nothing
dostation proc	near
	cmp	[VGNASwitch],'Y'
	jne	donoswt
	cmp	al,svgnaplus
	jne	donoswt
	mov	[WSSwitch],'Y'		; indicate that we have switch a WS
	push	di
	mov	di, offset VGNA_BIOS_DATA 
	call	MapInitBiosIn
	pop	di
	call	initstation
	ret
donoswt:
	call	initstation
	ret
dostation endp

	subttl initbios - initialize bios for all stations on machines
	page
;======================================================================
;,fs
; initbios - initialize bios for all stations on machines
;
; the following code will run down initialization structures and call
; video initialization routines if necessary.  currently this logic is
; setup to call c000:3 for ega and vga stations only.
;
; in:	
;
; out:	
;
;,fe
;=====================================================================
	assume	ds:nothing,es:nothing,ss:nothing
initbios proc near
	pusha

; save current cursor position

	mov	ah,3
	xor	bh,bh
	int	10h
	mov	[savecur],dx
	mov	[savectype],cx

; now for each system call video initialization routine
; at c000:3

	mov	si,offset temparea+tempextra
	mov	cx,[noofboards]
	mov	bx,1
ibloop1:
	push	cx
	mov	cx,8
	sub	cx,bx
	mov	dx,word ptr cs:[si].baseaddr
	add	dl,0fh
ibloop2:
	mov	ax,word ptr cs:[temparea+tempextra].baseaddr
	add	al,0fh
	cmp	ax,dx
	je	ibskip0
	push	dx
	mov	dx,ax
	mov	al,0fh
	out	dx,al
	pop	dx
ibskip0:
	push	si
	push	bx
	push	cx
	push	dx
	mov	al,byte ptr cs:[si+bx].stations
	cmp	al,snot_install
	je	ibskip
	push	bx
	mov	bx,word ptr cs:[temparea+tempextra].baseaddr
	add	bx,0fh
	cmp	dx,bx
	pop	bx
	je	ibskip1
	inc	bl
ibskip1:
	cmp	al,svnaplus
	je	ibvnaplus

; we have detected that we are on and ega or vga bios so we must
; initialize the video by calling the bios for that station

	push	ax
	mov	al,bl
	out	dx,al			; bank station in
	pop	ax
	
	call	dostation		; handle initializing station for
					; for VGNA, EGNA and 8514
	jmp	short ibskip
ibvnaplus:
	mov	al,bl
	out	dx,al			; bank station in
	call	setmono
ibskip:
	pop	dx
	pop	cx
	pop	bx
	pop	si
	mov	al,0fh
	out	dx,al
	inc	bx
	loop	ibloop2
	pop	cx
	xor	bx,bx
	add	si,type (initstat)
	loop	ibloop1

; set station back to master console

	mov	si,offset temparea+tempextra
	mov	dx,word ptr cs:[si].baseaddr
	add	dl,0fh
	xor	ax,ax
	cmp	[ws0ismc],'Y'
	je	ibmaster
	mov	al,0fh
ibmaster:
	out	dx,al
;
;	if we have switch a bIOS in, map it out on exit
;
	cmp	[WSSwitch],'Y'
	jne	skipwsswt
	call	InstallContext
skipwsswt:

; now set cursor back to where it was originally

	mov	dx,[savecur]		; if vgna is master console,
	mov	cx,[savectype]		; set cursor back to normal
	mov	ah,2
	xor	bh,bh
	int	10h
	popa
	ret
initbios endp


	subttl CreatePortInfo - create Port Information for bios logic
	page
;======================================================================
;,fs
; CreatePortInfo - create Port Information for bios logic
;
; The following code will creat port table information for setting up
; BIOS switching logic port table.
; 
; VGNA+ rom is currently the only workstation support, 8514 will be next
;
; The following is definitions that will be place in port table
;
;	Workstation		ROMID		ROM
; ===================================================================
;	   VNAPLUS		 0ffh	      	; no rom
;	   EGNA			 0ffh	      	; no rom (not supported)
;	   VGNA			 000h		; VGNAPLUS.ROM
;
; in:
;	ES:DI -> Drivers Internal ROM Port table 
;	CX     = Max Ports in port table
; out:
;	CX     = Number of Ports include
;
;,fe
;=====================================================================
	assume	ds:nothing,es:nothing,ss:nothing

CreatePortInfo	proc	near
	push	cx
	push	si
	push	di
	push	es
;
;	first clear out the table so that all ports are disable
;
	push	di
	mov	al,0ffh
	rep	movsb
	pop	di
;
; 	Next we will Map in BIOS information for bios indicated
;
	mov	cx,[noofboards]
	mov	si,offset temparea+tempextra
CPILoop:
	push	cx
	xor	bx,bx
	mov	cx,4
	cmp	[si].board,svnaplus	; if vna+ we have 8 stations
	jne	CPILoop1
	add	cx,4
CPILoop1:
	mov	al,0ffh				; indicate no switch in bios
	mov	ah,byte ptr [si+bx].stations
	cmp	ah,snot_install
	je	CPISkip
	cmp	ah,SVGNAPLUS
	jne	CPISet
	xor	al,al				; set for VGNA+	switch bios
CPISet:
	stosb
CPISkip:
	inc	bx
	loop	CPILoop1
	pop	cx
	add	si,type (initstat)
	loop	CPILoop

	pop	es
	pop	di
	pop	si
	pop	cx
	ret
CreatePortInfo	endp

	subttl setegnaoffsets - set pointer to egna structures
	page
;======================================================================
;,fs
; setegnaoffsets - set pointer to egna structures
;
; the following code counts of stations, and setups offset in offset
; table to point to egna structure, note this routine was purposely
; place at end of file so that memory occupy by routine is not wasted
;
; in:	
;
; out:	
;
;,fe
;=====================================================================
	assume	ds:nothing,es:nothing,ss:nothing
setegnaoffsets proc near

; first we must sum up # of ports on system, for egna we have
; 4 ports per board, vna+ has 8 ports per board

	xor	ax,ax
	xor	dx,dx
	mov	cx,[noofboards]
	mov	si,offset temparea+tempextra
cstats:
	push	cx
	mov	cx,4
	cmp	[si].board,svnaplus	; if vna+ we have 8 stations
	jne	not8s
	add	cx,4
not8s:
	xor	bx,bx
	add	dx,cx
cstloop:
	cmp	[si+bx].stations,snot_install
	je	cstskip
	inc	ax
cstskip:
	inc	bx
	loop	cstloop
	pop	cx
	add	si,type (initstat)
	loop	cstats
	mov	cx,ax
	mov	[noofstations],cx

; first we will initialized ofsws table to be a list of offsets to
; workstation data structures, follow by terminating 0
; start offset of data structure will be equal offset of ofsws +
; 2 * (no of stations +1)

	push	cs
	pop	es
	mov	ax,offset ofsws
	add	ax,cx
	add	ax,cx
	add	ax,2
	mov	[directptr],ax
	add	ax,dx
	add	ax,dx
	add	ax,2			; take in count egnaoffset table
	mov	di,offset ofsws		; and physical direct table
	cld
iwsloop:
	stosw				; store offset into table
	add	ax,type egna
	loop	iwsloop
	mov	[lastoffset],ax 	; save this is last offset
	xor	ax,ax
	stosw				; set terminating 0

; initialize direct table, use in irq routines

	mov	di,[directptr]
	mov	cx,[noofboards]
	mov	si,offset temparea+tempextra
	xor	dx,dx
directloop:
	push	cx
	mov	cx,4
	cmp	[si].board,svnaplus	; if vna+ we have 8 stations
	jne	dlnot8
	add	cx,4
dlnot8:
	xor	bx,bx
dlloop:
	mov	ax,-1
	cmp	[si+bx].stations,snot_install
	je	dlnotins
	push	si
	mov	si,offset ofsws
	add	si,dx
	mov	ax,word ptr cs:[si]
	add	dx,2
	pop	si
dlnotins:
	inc	bx
	stosw
	loop	dlloop
	pop	cx
	add	si,type (initstat)
	loop	directloop
	xor	ax,ax
	stosw
	ret
setegnaoffsets endp

	subttl bintohex - convert binary value in ax to hexidecimal value at ds:bx
	page
;======================================================================
;,fs
; bintohex - convert binary value in ax to hexidecimal value at ds:bx
;
; in:	ds:si -> place to store hexidecimal value
;	ax -> value to convert
;	cx -> count of digits to convert
;
; out:	
;
;,fe
;=====================================================================
	assume	ds:nothing,es:nothing,ss:nothing

hextab		db	'0123456789ABCDEF'

bintohex proc near
	push	bx
	mov	dx,ax
	push	cx
	mov	al,'0'
bclear:
	mov	byte ptr [si],al
	inc	si
	loop	bclear
	pop	cx
	dec	si
bhloop:
	mov	bx,dx
	and	bx,0fh			; mask out lower nibble
	mov	al,byte ptr [hextab+bx]
	mov	byte ptr [si],al
	dec	si
	shr	dx,4
	dec	cx
	jnz	bhloop
	pop	bx
	ret
bintohex endp

; the following area is use to store data structures while device driver is
; initializing data structures, after driver has completely initiallize
; information will be moved to end of permament code and pointers will be
; adjusted to affect this change.  symbol tempextra is use to reserved
; addition space for initialization
					
	even
temparea label byte

code	ends
	end

