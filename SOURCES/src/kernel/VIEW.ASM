	include page.inc
	title	view.asm - viewport system 1000 and system 2000 driver

	debug = 0			; controls debugging dump code

comment ^===============================================================
		       development specification

 program name:	view.asm			assigned to: stewart hyde
 module name:	view				assign date: 03/27/90
 entry points:	viewterm			completed:   04/09/90
 entry from:	mosint10, mosint16, mosvidrm
 entry method:	call dword [vector] with ah = function number
 calls: 	i10old (boot interrupt 10h)
 purpose:	mos interface to viewport technology system 2000
 refer to:	n/a
 last update:	04/03/91
========================================================================

mjs 05/09/90	added the clr_set_irq dummy function.  it is called by
		int14fun11 within int14.inc (only needed by _serial.asm)

mjs 06/16/90	correct floaty problem with serial irq handler by
		adding cld.  replace serial irq handler with one which
		will support a task specific bank port scheme.

mjs 07/02/90	rewrite driver to support physical to logical serial
		port assignments and serial parameter parsing.

mjs 07/13/90	reversed order of calls to count_ports and getwkscnt
		in the case where no parameters exist.  prevents a
		crash.

mjs 08/13/90	modified to use vidchk.inc and a boot_prep function.

mjs 12/19/90	modified the way the status port is written back to in
		serial_irq.  if the write-back is not done right after
		reading, can lose an irq and stall.
		the problems this corrects are: random stalling of serial
		output when streaming output at a high baud rate and
		stalling when dtr/dsr handshaking is used and the
		dtr line is pulsed a few times.

sah 04/01/91	corrections for 40:17 works  for 4.11

mjs 05/24/91	added dummy printer status function.  cleaned up module.

=======================================================================^

	subttl group segments and include block definitions
	page
true	equ	1 eq 1
false	equ	1 eq 0

	.xlist
	.286				; only works on 286+ machines, so take
					; advantage of it
	include macros.inc

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

stall	macro
	mov	cx,-1
	loop	$
	mov	cx,-1
	loop	$
	endm

	.list

code	segment para public 'code'	; to force loading with data
	assume	cs:code,ds:nothing,es:nothing,ss:nothing

ddtview equ	this byte
	dd	-1			; filled in with pointer to next driver
	dw	8000h			; signifying a character device
	dw	strat			; device strategy entry point
	dw	inter			; device interrupt entry point
viewnm	db	'$$VIEW  '		; device name

enddrvr0 equ	$

request dd	0

	subttl strat - device driver strategy routine
	page
;======================================================================
;,fs
; strat - device driver strategy routine
;
; in:	es:bx -> request header
;
; out:
;
;,fe
;======================================================================
strat proc far
	mov	word ptr [request],bx
	mov	word ptr [request+2],es
	ret
strat endp

	subttl inter - device driver interrupt routine
	page
;======================================================================
;,fs
; inter - device driver interrupt routine
;
; in:	uses enqued pointer to request header
;
; out:	data in request header - per function
;
;,fe
;======================================================================
inter proc far
	push	es
	push	ds
	push	si
	push	bx
	push	ax
	mov	bx,cs
	mov	ds,bx
	assume	ds:code
	mov	ax,0100h
	les	bx,[request]
	mov	si,es:[bx+2]
	and	si,0ffh
	cmp	si,4			; is it ddtread
	jne	inter1
	call	ddtread 		; do read
	jmp	short inter2
inter1:
	or	si,si			; is it ddtinit
	jnz	inter2
	call	ddtinit 		; do init
inter2:
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

	subttl ddtread - return the terminal function vector
	page
;======================================================================
;,fs
; ddtread - return the terminal function vector
;
; in:	none
;
; out:	doubleword vector to ddt function handler
;
;,fe
;======================================================================
ddtread proc near
	lds	si,es:[bx+14]
	mov	cx,es:[bx+18]
	mov	word ptr es:[bx+18],0	; nothing read if error
	mov	ax,8103h		; error, done, unknown command
	cmp	cx,4
	jne	ddtrd1			; if not reading exactly 4 bytes
	mov	es:[bx+18],cx		; else read 4 bytes
	mov	word ptr ds:[si],offset viewterm  ; and these are them
	mov	ds:[si+2],cs
	mov	ax,0100h		; no error, done
ddtrd1:
	ret
ddtread endp

;==================== end of ddt interface code =========================

	subttl termfn - all the terminal and keyboard functions for mos
	page

tfn	dw	register
	dw	inkbdata
	dw	outkbctl
bgnvid	equ	($-tfn)/2
	dw	0			;setmode
	dw	0			;setcrstyp
	dw	0			;setcrspos
	dw	0			;scrollup
	dw	0			;scrolldn
	dw	0			;wrchatr
	dw	0			;setpalet
	dw	0			;wrtty
	dw	0			;wrstr
	dw	0			;setwindow
	dw	0			;wrcho
	dw	0			;readch
	dw	0			;getscr
endvid	equ	($-tfn)/2
	dw	nullret			; print character
	dw	nullret			; print string
	dw	nullret			; get printer status
endtfn	equ	($-tfn)/2

	assume	ds:nothing,es:nothing,ss:nothing

;===================== permanent resident data ==========================

scbptr	label	dword
scbofs	dw	0			; offset of scb
scbseg	dw	0			; segment of scb
ddtmc	dd	0			; address of master console ddt entry
viewcur db	-1			; who is currently banked in
viewunreg dd	8 dup (0)		; prevous un-register calls
saveds	dw	0
savebx	dw	0
savevid dw	0
savevram db	0
baseaddr  dw	0			; base address
kbcommand dw	0			; keyboard command register
keyistat  dw	0			; keyboard interupt status
com1stat  dw	0			; com1 interupt status (com2 = com1+1)
keyimask  db	0			; keyboard interupt status mask
commask   db	0			; com1 and com2 mask for irqs
keyirq	  db	0			; keyboard irq
keymask   db	0			; keyboard mask
saveview  db	0

; one key buffer for each workstation

kbsize	equ	32			; 32 scan codes buffered

; there are several spots within this driver hard-coded to expect this
; keyboard size.  they don't all reference the size through kbsize either.

if kbsize ne 32
	%out	kb buffer size wrong for shift count
endif

numport dw	0			; total number of serial ports declared
viewtcb dw	8 dup (-1)		; register tcbs
nview	dw	0			; number of viewport works stations on system
kbget	dw	8 dup(0)
kbput	dw	8 dup(0)
keyrdy	db	8 dup(0)
kbf	db	8*kbsize dup(0)
kbstat	db	8 dup(0)
kbbios	db	'N'			; is kbbios set

portoff dw	offset porttbl

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
;======================================================================
	assume	ds:nothing,es:nothing,ss:nothing
setws proc near
	cmp	al,[viewcur]		; if not already selected
	jne	setws1
	ret
setws1:
	push	dx
	mov	dx,[baseaddr]
	mov	[viewcur],al
	and	al,0fh
	out	dx,al			; bank in selected wks
	jmp	$+2
	pop	dx
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
; selected workstation is another viewport workstation then here is no
; need to call the fe function of the ddt which is in scblastdd.  in
; this case, one call to setws will bank out the current wks and bank in
; the new one.
;
; in:	ds:si -> tcbddt
;
; out:	none
;
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:nothing
bankin proc near
	assume	ds:nothing,es:nothing,ss:nothing
	push	ax
	push	bx
	push	di
	push	es
	pushf				; save current interrupt flag setting
	cli				; secure against irq's that switch video
	les	di,[scbptr]
	cmp	es:[di.scblastff],0
	jz	bankin2 		; if scblastff == 0, nobody needs banked out
	mov	ax,ds
	cmp	ax,es:[di.scblastff]	; is this workstation already selected?
	je	bankin3

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
	mov	si,offset tcbcondd
	mov	ah,0feh
	call	dword ptr [si]
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

	subttl viewterm - entry point for ddt calls
	page
;======================================================================
;,fs
; viewterm - entry point for ddt calls
;
; off to master console ddt if
; workstation 0 and master console is workstation 0
; or if a video function
; else handle it in viewport ddt
;
; in:
;
; out:
;
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:nothing
	db	'VPT'
viewterm proc far
	cmp	ah,0feh
	jne	viewfj00
	mov	al,0fh
	pushf
	cli
	call	setws
	popf
	jmp	viewfnx

; 0ffh is a special function to bank in a workstation

viewfj00:
	cmp	ah,0ffh
	jne	viewfn1
	call	bankin

; now, call ddtmc's ff handler to insure that the video display ram is exposed

	push	di
	push	es
	les	di,[scbptr]
	call	ddtmc			; ah should still be 0ffh
	pop	es
	pop	di
	jmp	viewfnx

; for all video functions - pass the call onto ddtmc
; also, pass to ddtmc when not a video function but the port is 0 and the
; master console is a viewport workstation
; otherwise, process locally

; one exception is when a 7 is written to function 0a

viewfn1:
	cmp	ah,endtfn
	jae	viewfn3a
	cmp	ax,0a07h		; is this beep
	jne	viewfn1a
	cmp	byte ptr [si].port,0	; if not master console - ignore it
	je	viewfn1a

; the following code is added to execute a beep on the viewport's
; beeper.  please note that the viewport beeper is higher pitch
; sound than normal beeper on master console and there is not much
; that we can do about

	push	ax
	push	dx
	mov	dx,[baseaddr]
	add	dl,8			; access beeper port at base+8
	mov	al,80h			; always out and 80h
	out	dx,al
	jmp	$+2
	pop	dx
	pop	ax
	jmp	short viewfnx		; we are done with this call
viewfn1a:
	cmp	ah,bgnvid
	jb	viewfn2
	cmp	ah,endvid
	jb	viewfn3
	jmp	short viewfn4
viewfn2:
	cmp	byte ptr [si].port,0
	jne	viewfn4 		; not ws0
	or	ah,ah
	jnz	viewfn3b
	jmp	short viewfn3a

; process a video function

viewfn3:
	cmp	ah,4			; for set cursor type or set cursor
	je	viewfn3a		; position, must bank in the right
	cmp	ah,5			; workstation first
	jne	viewfn3b
viewfn3a:
	call	bankin
viewfn3b:
	push	si
	call	ddtmc			; when ddtmc calls exposreal, the
	pop	si			; ddt function ff which will come back
	jmp	viewfnx 		; to this ddt first

; process non-video functions locally

viewfn4:
	push	bp
	mov	bp,bx
	mov	bl,ah
	cmp	bl,endtfn
	jae	viewfn5
	xor	bh,bh
	shl	bx,1
	xchg	bx,bp
	push	ds
	push	si
	call	tfn[bp]
	pop	si
	pop	ds
viewfn5:
	pop	bp
viewfnx:
	ret
viewterm endp

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
;	  (key buffer flag is <> 0 while scan codes are buffered)
;	al = 80h if master console
;	     00h if not master console
;	ah = 00h cause no error can happen
;
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:nothing
register proc near
	mov	ah,0ffh
	mov	bl,byte ptr [si].port

; check to see if task has allready been register
; if so return error

	xor	bh,bh
	shl	bx,1
	cmp	word ptr [viewtcb+bx],-1
	je	reg0b
	jmp	regsx
reg0b:
	mov	[saveds],ds		; save pointer to tcb
	mov	[savebx],bx		; save port pointer for later
	mov	[si].dcpherc,'N'
	mov	[si].dcpcrs,25*256
	mov	[si].dcpcol,80
	mov	[si].dcpscrl,80*25*2
	mov	[si].dcbios,5
	mov	[si].dcsnow,0
	mov	cx,4
	mov	[si].dcmode,3
	mov	[si].dcvmode,3
	mov	[si].dcaddr,03d4h
	mov	[si].dcpscr,0b800h
	mov	[savevid],0b800h
	mov	[savevram],0ech
regs0:
	push	ds
	push	si
	push	cx
	xor	bx,bx
	mov	bl,byte ptr [si].port
	mov	bh,bh
	push	cs
	pop	ds
	call	getview
	mov	[saveview],al
	mov	al,bl
	call	setws
	call	initkb
	push	ax
	mov	al,[saveview]
	call	setws
	pop	ax
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
	cmp	bx,8*2
	ja	regok
	mov	ds,[saveds]
	assume	ds:tcb
	mov	word ptr [viewtcb+bx],ds; register task
	push	cs
	pop	es
	shl	bx,1
	mov	si,offset tcbunreg	; save current tcbunreg
	mov	di,offset viewunreg
	add	di,bx
	cld
	movsw
	movsw
	mov	word ptr [tcbunreg],offset unregister
	mov	word ptr [tcbunreg+2],cs
regok:
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
	mov	al,[savevram]		; graphics and mc and view
	mov	cx,[savevid]		; physical buffer address (stuffed into
	ret				;   tcbvidad)
register endp

	include vidchk.inc

	subttl boot_prep - prepare the video state for a reboot
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
;======================================================================
	assume	cs:code,ds:nothing,es:nothing,ss:nothing
boot_prep proc near
	xor	ax,ax			; switch forground in
	call	setws
	ret
boot_prep endp

	subttl getview - return currently banked in workstation
	page
;======================================================================
;,fs
; getview - return currently banked in workstation
;
; in:
;
; out:	al = node number (0-7)
;
;,fe
;======================================================================
getview proc near
	push	bx
	push	dx
	xor	bx,bx
	mov	dx,[baseaddr]
	in	al,dx
	cmp	al,0ffh
	je	gvfound
gvlp:
	rcr	al,1
	jnc	gvfound
	inc	bl
	jmp	short gvlp
gvfound:
	mov	al,bl
	pop	dx
	pop	bx
	ret
getview endp

	subttl keyboard_irq - keyboard irq handler
	page
;======================================================================
;,fs
; keyboard_irq - keyboard irq handler
;
; in:
;
; out:
;
;,fe
;======================================================================
keyboard_irq proc far
	pusha
	push	ds
	push	es
	mov	ax,cs
	mov	ds,ax
	mov	es,ax
	call	getview 		; get current viewport in al
	push	ax
	mov	dx,[keyistat]		; point to keyboard interupt status register
	in	al,dx			; find out who cause the interupt
	or	al,[keyimask]		; mask out undesirable channels
	push	ax
	rcr	al,1
	mov	bx,1			; start out at node 1 (0 is master console)
	mov	cx,[nview]		; get no of viewport on system
	mov	dx,[kbcommand]
keyloop:
	rcr	al,1			; is work station interupting
	jc	keynext
	push	ax
	push	cx
	push	dx
	mov	al,bl
	call	setws
	mov	di,bx
	call	keybd
	pop	dx
	pop	cx
	pop	ax
keynext:
	inc	bx
	loop	keyloop
	mov	al,20h
	cmp	cs:[keyirq],0fh
	jbe	lowirq
	out	0a0h,al
	jmp	$+2
lowirq:
	out	20h,al
	pop	ax			; re-arm interupt status
	mov	dx,[keyistat]
	out	dx,al
	jmp	$+2
	pop	ax			; bank switch original station back in
	call	setws
	pop	es
	pop	ds
	popa
	iret
keyboard_irq endp

	subttl keybd - process a viewport keyboard irq
	page
;======================================================================
;,fs
; keybd - process a viewport keyboard irq
;
; this is the stations keyboard handler, it will put the
; the key scan codes into the driver 32 byte keyboard buffer in
; task information table.
;
; in:	di = points to viewport data structure
;	dx = points to keyboard control register
;
; out:
;
;,fe
;======================================================================
keybd proc near
	push	bx
	inc	dx
	mov	cx,8000h
kbd1:
	in	al,dx
	test	al,2			; outfull full
	loopnz	kbd1
	jmp	$+2
	dec	dx
	in	al,dx			; get data
	inc	dx
	cmp	al,0feh 		; resend
	je	kbd2
	cmp	al,0fah 		; acknowledge
	jne	kbd3

; do keyboard acknowledge

	jmp	kbover
kbd2:

; do keyboard resend

	jmp	kbover
kbd3:
	cmp	al,0ffh 		; overrun.....
	je	kbover
	cmp	byte ptr [di].keyrdy,00h; any characters
	je	kbempty
	shl	di,1			; shift to word index
	mov	si,word ptr [di].kbget
	cmp	si,word ptr [di].kbput	; overflow in buffer
	je	kbover
	shr	di,1			; shift back to byte index
kbempty:
	mov	byte ptr [di].keyrdy,0ffh  ; flag keyboard ready flag
	shl	di,1			; shift to word index
	mov	si,word ptr [di].kbput	; get point to que
	push	di
	shl	di,4			; this assume 32 bytes
	add	di,si			; and that we are at bus
	mov	byte ptr [di].kbf,al
	pop	di
	inc	si
	cmp	si,kbsize		; test to see if over limit
	jb	kbset
	xor	si,si
kbset:
	mov	word ptr [di].kbput,si	; save new pointer
	cmp	[kbbios],'Y'
	je	kbover
	call	doleds			; handle leds
kbover:
	pop	bx
	ret
keybd endp

	subttl doleds - set the keyboard status leds on the keyboard
	page
;======================================================================
;,fs
; doleds - set the keyboard status leds on the keyboard
;
; this is done by checking the 40:17 status save in the tcb as
; tcbkshft (this is necessary because keyboard irq could and will get
; get call when another task is switch into memory).  if status is
; is different that prevous saved status, then the routine will access
; memory map area to change the leds.
;
; in:
;
; out:
;
;,fe
;======================================================================
doleds proc near
	push	ax
	push	es
	mov	es,word ptr [di].viewtcb; get tcb for station
	assume	es:tcb
	mov	al,tcbkshft		; get keyboard status
	pop	es
	assume	es:nothing
	shr	di,1
	call	setleds
	pop	ax
	ret
doleds	endp

	subttl setleds - update the keyboard leds
	page
;======================================================================
;,fs
; setleds - update the keyboard leds
;
; in:	al = value at 40:17
;	di = pointer to view structure
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
	cmp	al,byte ptr [di].kbstat ; same as saved?
	jne	dleds
	shl	di,1
	ret
dleds:

; we must now change the keyboard leds

	push	cx
	mov	byte ptr [di].kbstat,al
	dec	dx
	mov	al,0edh
	out	dx,al
	call	keyack			; wait for ack
	mov	al,byte ptr [di].kbstat
	out	dx,al
	call	keyack
	inc	dx
	shl	di,1
	pop	cx
	ret
setleds endp

	subttl keyack - used by doleds to check for ack from keyboard
	page
;======================================================================
;,fs
; keyack - used by doleds to check for ack from keyboard
;
; in:
;
; out:
;
;,fe
;======================================================================
keyack proc near
	mov	cx,-1
kaloop:
	in	al,dx			; get data
	cmp	al,0fah 		; is it ack
	loopnz	kaloop			; loop if not
	ret
keyack endp

	subttl initkb - initialize keyboard controller
	page
;======================================================================
;,fs
; initkb - initialize keyboard controller
;
; this procedure is use to initial the stations keyboard controller
; that it will send scan codes to host adapter which will generate
; irq so that driver can place the scan code into the keyboard buffer
;
; in:	bx -> port
;
; out:
;
;,fe
;======================================================================
initkb proc near
	push	cx			;  now initialize keyboard
	push	dx
	push	ax
	mov	dx,[kbcommand]
	inc	dx
	mov	cx,-1
	loop	$
	mov	al,0aah
	out	dx,al
	stall
	dec	dx
	in	al,dx
	stall
	inc	dx
	cmp	al,55h
	jne	errorkb
	stall
	dec	dx
	in	al,dx
	stall
	in	al,dx
	stall
	mov	al,0f2h 		; send nop
	out	dx,al
	stall
	in	al,dx
	inc	dx
	stall
	cmp	al,0fah
	je	initkba
errorkb:
	pop	ax
	pop	dx
	pop	cx
	mov	ax,0ffffh
	ret
initkba:
	mov	dx,[kbcommand]
	inc	dx
	mov	cx,-1
	loop	$
	mov	al,0aah
	out	dx,al
	mov	cx,-1
	loop	$
	mov	al,60h
	out	dx,al
	mov	cx,-1
	loop	$
	dec	dx
	mov	al,45h
	out	dx,al
	pop	ax
	pop	dx
	pop	cx
	xor	ax,ax
	shl	bx,1			; now initialize keyboard data areas
	mov	kbget[bx],0
	mov	kbput[bx],0
	shr	bx,1
	mov	keyrdy[bx],0		; no keys yet
	sti
	lea	bx,keyrdy[bx]
	ret
initkb endp

	subttl unregister - handle task removal
	page
;======================================================================
;,fs
; unregister - handle task removal
;
; in:	ds --> tcb of task
;
; out:
;
;,fe
;======================================================================
	assume	ds:tcb,es:nothing,ss:nothing
unregister proc far
	push	bx
	push	si
	push	ds
	mov	si,offset tcbcondd
	mov	bl,byte ptr [si].port
	cmp	bl,8
	ja	unr1
	xor	bh,bh
	shl	bx,1
	mov	word ptr cs:[viewtcb+bx],-1  ; unregister
	shl	bx,1
	cmp	word ptr cs:[viewunreg+bx+2],0	; end of list
	je	unr1
	call	dword ptr cs:[viewunreg+bx]  ; chain it
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
; key scan code is read non-destructively
;
; in:	ah = 01h
;	ds:si -> tcbddt
;
; out:	al = bit 7   - key break if 1, key make or key repeat if 0
;	     bits 6-0 - key scan code 01h - 07dh
;
;,fe
;======================================================================
	assume	ds:tcb,es:nothing,ss:nothing
inkbdata proc near
	mov	bl,byte ptr [si].port
	xor	bh,bh
	cmp	[kbbios],'Y'		; skip this if kbbios not support
	jne	kbdat0
	cmp	cx,dx			; cx must equal dx
	jne	kbdat0
	cmp	dh,-1			; dh must be 0ffh
	jne	kbdat0
	push	dx
	push	di
	mov	al,dl
	mov	di,bx
	shl	di,1
	mov	dx,[kbcommand]
	inc	dx
	call	setleds
	pop	di
	pop	dx
kbdat0:
	mov	al,keyrdy[bx]
	or	al,al
	jz	inkbdx
	shl	bx,1
	mov	si,bx
	shl	si,4
	mov	bx,kbget[bx]
	mov	al,kbf[si][bx]
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
;======================================================================
	assume	ds:tcb,es:nothing,ss:nothing
outkbctl proc near
	test	al,80h
	jz	outkbx
	mov	bl,byte ptr [si].port
	xor	bh,bh
	mov	al,keyrdy[bx]
	or	al,al
	jz	outkbx			; no scan code to clear
	shl	bx,1
	mov	si,kbget[bx]
	inc	si
	cmp	si,kbsize
	jb	outkb1
	xor	si,si
outkb1:
	cli				; any more scan codes ?
	mov	kbget[bx],si
	cmp	si,kbput[bx]
	jne	outkb2
	shr	bx,1
	mov	keyrdy[bx],0
outkb2:
	sti
outkbx:
nullret:				; this label is use by print routines
	ret				; and should be followed by ret
outkbctl endp

enddrvr1 equ	$

;====== start of resident code and data when serial ports are used ======

;==================== serial resident data ==============================

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

sername db	'VIEW.SYS  V1.20 ViewPort 2000 (910403)  '

; misc serial data

view14	dw	0			; saved area for work station during int 14
orig1a	dd	0			; int 1a vector at initialization
orig38	dd	0			; original services vector
child	dd	0			; point to next int14 driver
tocount dw	182			; default timeout (10 seconds)

;========= async adapter port and status definitions

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

serial	equ	true
emulink equ	false
mos	equ	true

include vptiomac.inc			; i/o macros
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
;======================================================================
clr_set_irq proc near
	ret
clr_set_irq endp

; the following tables, cp1list and cp2list, enable the irq handler
; to determine the handling method and port table offset for each
; possible com port.

cp	struc
cpmask	db	?			; bit mask for list searching
cpbank	db	?			; node number
cpstate dw	?		; 0 for dd, else tcb if task specific
cpofs	dw	?			; ptr to port table entry
cp	ends

cpdef	macro	p1,p2,p3,p4
	db	p1
	db	p2
	dw	p3
	dw	p4
	endm

cp1list label byte
	cpdef	00000001b,0,0,0
	cpdef	00000010b,1,0,0
	cpdef	00000100b,2,0,0
	cpdef	00001000b,3,0,0
	cpdef	00010000b,4,0,0
	cpdef	00100000b,5,0,0
	cpdef	01000000b,6,0,0
	cpdef	10000000b,7,0,0

cp2list label byte
	cpdef	00000001b,0,0,0
	cpdef	00000010b,1,0,0
	cpdef	00000100b,2,0,0
	cpdef	00001000b,3,0,0
	cpdef	00010000b,4,0,0
	cpdef	00100000b,5,0,0
	cpdef	01000000b,6,0,0
	cpdef	10000000b,7,0,0

	subttl ptbl2node - xlate a port table offset to a node number
	page
;======================================================================
;,fs
; ptbl2node - xlate a port table offset to a node number
;
; the design of this function presumes that a match will be found
;
; in:	bx = port table offset
;
; out:	al = node number
;
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:nothing
ptbl2node proc near
	pushset cx,si
	mov	si,offset cp1list
	mov	cx,8
ptn1:
	cmp	bx,cs:[si].cpofs
	je	ptn3
	add	si,size cp		; check next entry in the cp table
	loop	ptn1
	mov	si,offset cp2list
	mov	cx,8
ptn2:
	cmp	bx,cs:[si].cpofs
	je	ptn3
	add	si,size cp		; check next entry in the cp table
	loop	ptn2
ptn3:
	mov	al,cs:[si].cpbank
	popset	cx,si
	ret
ptbl2node endp

	subttl serial_irq - process serial irqs - irq3 and irq4
	page
;======================================================================
;,fs
; serial_irq - process serial irqs - irq3 and irq4
;
; in:
;
; out:
;
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:nothing
serial_irq proc far
	pushset ax,bx,cx,dx,si,ds
	cld				; isrsub needs this
	mov	ax,cs
	mov	ds,ax
	call	getview 		; get current viewport in al
	push	ax			; and save for later restoration
sirq0:
	mov	dx,[com1stat]		; get status port address for com1
	in	al,dx
	or	al,[commask]		; only test supported ports
	cmp	al,0ffh 		; anything on any com1?
	jne	sirq1
	inc	dx			; derive status port address for com2
	in	al,dx
	or	al,[commask]		; only test supported ports
	cmp	al,0ffh 		; anything on any com2?
	je	sirq2
	mov	si,offset cp2list	; si -> index table for com2
	jmp	short sirq3
sirq1:
	mov	si,offset cp1list	; si -> index table for com1
sirq3:
	out	dx,al			; re-arm the controller
	mov	cx,8			; 8 possibilities per base address
	xor	bx,bx			; init table index
	not	al			; want to test for high bits
	mov	ah,al
sirq4:
	test	ah,[si+bx].cpmask	; check each table entry
	jz	sirq5
	mov	dx,[baseaddr]
	mov	al,[si+bx].cpbank	; index table has the node #
	mov	[viewcur],al		; bank in the node
	out	dx,al
	cmp	[si+bx].cpstate,0	; if cpstate != 0, its the tcb of
	je	sirq6			; the task to get this irq

; process irq for task $$$$$$$$$$$$$$

	jmp	short sirq5
sirq6:
	pushset ax,bx,cx,si,di,es	; irq within the driver
	mov	bx,[si+bx].cpofs
	add	bx,[portoff]		; point to port table entry
	mov	dx,[bx].addr		; and fetch the uart's address
sirq7:
	rdiir				; read the interrupt indentification register
	test	al,noint		; is he interupting
	jnz	sirq8			; jump if not this port
	xor	ah,ah			; convert interupt type to offset
	mov	si,ax			; move the offset to si
	call	inttbl[si]		; call the interupt processor
	jmp	short sirq7
sirq8:
	popset	ax,bx,cx,si,di,es
sirq5:
	add	bx,size cp		; check next entry in the cp table
	loop	sirq4
	jmp	sirq0			; check everything again
sirq2:
	pop	ax			; recover original bank state
	mov	dx,[baseaddr]
	cli
	mov	[viewcur],al
	out	dx,al			; bank in the original node
	jmp	$+2
	mov	al,20h			; eoi
	out	20h,al
	popset	ax,bx,cx,dx,si,ds
	iret
serial_irq endp

; note: the port table must be the last resident entity of the
; serial logic

porttbl ports	16 dup(<>)		; the port table array

;======= end of resident code and data when serial ports are used =======
;========= start of device driver initialization code and data ==========

;======================= installation messages ==========================

ddtmsg	db	'ViewPort terminal device driver (910403) installed, version 1.10            ',13,10  ;@@xlat
	db	'(c) Copyright 1990, 1991 The Software Link, Inc.                   ',13,10  ;@@xlat
	db	'(c) Portions Copyrighted 1990, 1991 Viewport Technology, Inc.      ',13,10  ;@@xlat
	db	'All Rights Reseved Worldwide                 ',13,10,10  ;@@xlat
	db	'     '
	db	'Base Address at '	;@@xlat
baddr	db	'0310H on IRQ ' 	;@@xlat
birq	db	'5. ',13,10
	db	'     '
vports	db	'x ViewPort Stations Detected.      ',13,10,'$'  ;@@xlat
sermsg	db	'     ViewPort serial port logic installed             ',13,10,'$'  ;@@xlat

;===== misc vars for the parse exec and init logic

keymasks label	byte
	db	0ffh			; 0 - everything is masked out
	db	0fdh			; 1 - master console, 2-7 mask
	db	0f9h			; 2 - master console, 3-7 mask
	db	0f1h			; 3 - master console, 4-7 mask
	db	0e1h			; 4 - master console, 5-7 mask
	db	0c1h			; 5 - master console, 6-7 mask
	db	081h			; 6 - master console, 7 mask
	db	001h			; 7 - master console

p5a_once db	?
p5b_once db	?
p5c_once db	?
p5d_once db	?

irqlist db	   5,	 6,    7,   10,  11,	14,   15, 0
irqint	db	00dh, 00eh, 00fh, 072h, 073h, 076h, 077h
irqmask db	0dfh, 0bfh, 07fh, 0fbh, 0f7h, 0bfh, 07fh
irqval	db	'5.', '6.', '7.', '01', '11', '41', '51'

irqnum	db	?			; irq # from parsing
ip_table_max	equ	16		; max # of physical ports supported
ip_table	db	ip_table_max dup(1)  ; one flag per physical port
numportp	dw	?		; actual # of physical ports
serflg		db	0		; indicates serial logic is to stay
c1flg		db	0		; indicates 03f8 ports to be used
c2flg		db	0		; indicates 02f8 ports to be used
current_lp	dw	?		; current logical port #
portndx 	dw	?	; port table index
last_pndx	dw	?		; last port table index
hextab	db	'0123456789ABCDEF'

;========================= error mesages ===========================

markerr macro	p1, p2			; p1 is parameter # and p2 is error #
	mov	ax,(&p1 shl 8) + p2
	endm

edef	macro	p1, p2, p3
p1	equ	p2
db		p2,p3,'$'
	endm

; standard error codes for report_error

error_list:
edef er_inv,1,'Parameter invalid or missing        '  ;@@xlat
edef er_eol,2,'Premature end of line        '  ;@@xlat
edef er_nonull,3,'Null parameter not allowed        '  ;@@xlat

; application specific error messages for report_error

edef uer_ibmax,51,'More than 1 IB= per port        '  ;@@xlat
edef uer_obmax,52,'More than 1 OB= per port        '  ;@@xlat
edef uer_hsmax,53,'More than 1 HS= per port        '  ;@@xlat
edef uer_cnmax,54,'More than 1 HS= per port        '  ;@@xlat
edef uer_iblow,55,'Input buffer must be at least 16 bytes        '  ;@@xlat
edef uer_oblow,56,'Output buffer must be at least 16 bytes        '  ;@@xlat
edef uer_badseq,57,'Improper port sequence                 '  ;@@xlat
edef uer_bigpn,58,'Too many logical ports referenced                '  ;@@xlat
edef uer_nohard,59,'No ViewPort Hardware detected on system.            ',13,10,'$'  ;@@xlat

	db	0			; end of list marker

crlf	db	13,10,'$'
err_lead db	'Parameter error in VIEW.SYS:        ',13,10,'$'  ;@@xlat

em1	db	'Base address        $' ;@@xlat
em2	db	'Keyboard irq        $' ;@@xlat
em3	db	'Port definition (/IP=) or Logical port # (/Pn)             $'	;@@xlat
em4	db	'Logical port # (/Pn)          $'  ;@@xlat
em5	db	'Serial option (IB=, OB=, HS=, CN=)        $'  ;@@xlat
em6	db	'Serial option (IB=)        $'	;@@xlat
em7	db	'Serial option (OB=)        $'	;@@xlat
em8	db	'Serial option (HS=)        $'	;@@xlat
em9	db	'Serial option (CN=)        $'	;@@xlat

parm_msg_tbl:
	dw	em1
	dw	em2
	dw	em3
	dw	em4
	dw	em5
	dw	em6
	dw	em7
	dw	em8
	dw	em9

ddt2	db	'ViewPort terminal device driver already installed         ',13,10,'$'	;@@xlat

;================== parameter processing definitions ====================

; parameter classification table entry codes

pc_skip equ	0			; to make the parse engine skip a parameter
					;  (for the case where explicit code is required)
pc_singl equ	1			; single entry case
pc_orgrp equ	2			; or group case.  (next number is the # in the group)

; return codes from fetch_parm, check_type and type checking procedures

rc_ok	equ	0			; no error  ( !! this code not actually returned)
rc_eol	equ	1			; end of parameter line
rc_null equ	2			; null parm (e.g. an empty position of the type  ,,)
rc_gerr equ	3			; general error - invalid parameter

; codes 0-50 reserved for future use by the parameter engine
; 51+ available for use by type checking routines

;======================== parameter type table =========================

; parm1  /hhhh	    hhhh is a hex word for the base address
; parm2  h	    h is hex number for the irq (5,6,7,10,11,14,15)
; parm3  /ip=d..    d is a 1 or a 0
; parm4  /pd	    d is the logical port number
; parm5a ib=d	    d is the input buffer size (16 to 64k)
; parm5b ob=d	    d is the input buffer size (16 to 64k)
; parm5c hs=c	    c is of the set: n,d,p,x or r
; parm5d cn=c	    c is of the set: l,r or t

parm_type_tbl:
;		type  format  return		   notes
;		====  ======  ======  ==================================
dw	get_vbase			; 1   /hhhh	ax     literal / followed by 4 hex digits
dw	get_irq 			; 2   h 	ax     1 or more decimal digits in the set
					;			 (5,6,7,10,11,14,15)
dw	get_ip				; 3   /ip=	n/a    literal /ip= and string of 0's and 1's
dw	get_lp				; 4   /pn	ax     literal /p   and a decimal number
dw	get_ib				; 5   ib=d	ax     literal ib=  and a decimal word value
dw	get_ob				; 6   ob=d	ax     literal ob=  and a decimal word value
dw	get_hs				; 7   hs=a	al     literal hs=  and a single alpha char
dw	get_cn				; 8   cn=a	al     literal cn=  and a single alpha char

;=================== parameter classification table ======================

class_tbl_p1:
	db	pc_singl,1		; p1 - base port address
	db	pc_singl,2		; p2 - kybd irq
	db	pc_singl,3		; p3 - ip= string
class_tbl_p4:
	db	pc_singl,4		; p4 - /pn - logical port # designator
class_tbl_p5:
	db	pc_orgrp,4,5,6,7,8	; p5a,b,c and d - iona serial port options

;=================== main initialization procedure ======================

	subttl ddtinit - device driver initialization
	page
;======================================================================
;,fs
; ddtinit - device driver initialization
;
; notes: initialization - retrieve location of master console ddt
; entry, taking tcbcondd address from foreground tcb, replacing that
; address with our entry, set driver length and exit.
;
; in:	[request] -> request header from dd call
;
; out:	end of resident point set into request header
;
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:nothing
ddtinit proc near
	pushset bx,cx,dx,si,di,ds,es,bp
	mov	ax,cs
	mov	ds,ax
	assume	ds:code
	xor	ax,ax
	mov	es,ax
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
	assume	es:tcb
	push	ds
	lds	bx,[tcbcondd]		; to detect co-resident case
	assume	ds:nothing

; check for a second loading of view.sys

	cmp	word ptr [bx-3],'PV'
	jne	ddi1
	cmp	byte ptr [bx-1],'T'
	jne	ddi1
	mov	dx,offset ddt2		; in the procedure hideif
	pop	ds
	jmp		ddi2		; error
ddi1:
	mov	word ptr [ddtmc],bx	; mcterm address
	mov	word ptr [ddtmc+2],ds
	pop	ds
	assume	ds:code

; process the parameter line

	mov	di,offset porttbl	; put defaults into first
	mov	[di].ibfsiz,64		; port table entry
	mov	[di].obfsiz,16
	les	bx,[request]
	lds	si,es:[bx+18]		; make ds:si point to the
	assume	ds:nothing		; device driver command line
	call	parse_exec		; parse the parameter line
	jnc	ddi3
	xor	dx,dx			; parse_exec already took care
	jmp		ddi2		; of the error message
ddi3:
	mov	ax,cs			; init other i/o addresses from
	mov	ds,ax			; the base address
	mov	es,ax
	assume	cs:code,ds:code,es:nothing,ss:nothing
	mov	ax,[baseaddr]
	add	ax,2
	mov	[kbcommand],ax
	add	ax,2
	mov	[keyistat],ax
	add	ax,2
	mov	[com1stat],ax

; process the keyboard irq

	mov	al,[irqnum]
	mov	di,offset irqlist
	mov	cx,-1
	cld
	repne	scasb
	dec	di
	sub	di,offset irqlist
	mov	al,byte ptr [irqmask+di]
	mov	[keymask],al
	mov	al,byte ptr [irqint+di]
	mov	[keyirq],al
	shl	di,1
	cmp	al,0fh
	jna	ddi4
	mov	[birq+2],'.'
ddi4:
	mov	ax,word ptr [irqval+di]
	mov	word ptr [birq],ax
	mov	ax,[baseaddr]
	mov	si,offset baddr
	mov	cx,4
	call	bintohex
	xor	ax,ax
	mov	es,ax
	assume	es:nothing
	cli
	mov	al,[keyirq]
	xor	ah,ah
	shl	ax,2
	mov	di,ax
	mov	ax,offset keyboard_irq
	stosw
	mov	ax,cs
	stosw
	mov	dx,21h
	cmp	[keyirq],0fh
	jna	ddi5
	mov	dx,0a1h
ddi5:
	in	al,dx
	and	al,[keymask]
	out	dx,al
	sti

; set vidchk routine for pamswitching access

	les	bx,[scbptr]
	assume	es:gdata
	mov	word ptr es:[bx.scbvidchk],offset vidchk
	mov	word ptr es:[bx.scbvidchk+2],cs
	mov	es,es:[bx+scbtcbpf]	; access the foreground tcb
	assume	es:tcb
	mov	ah,3			; save cursor
	xor	bh,bh
	int	10h
	push	dx
	push	cx

; initialize each ws for each card

	mov	ax,1
	mov	cx,[nview]
ddi6:
	call	setws
	call	initbios
	inc	al
	loop		ddi6
	xor	ax,ax			; switch in master console
	call	setws
	pop	cx
	pop	dx
	mov	ah,2
	xor	bh,bh
	int	10h
	or	[tcbvram],08h
	mov	word ptr [tcbcondd.port],0
	mov	word ptr [tcbcondd],offset viewterm
	mov	word ptr [tcbcondd+2],cs

; set the end of resident point for the case where the serial
; logic isn't included

	les	bx,[request]
	assume	es:nothing
	mov	word ptr es:[bx+14],offset enddrvr1
	mov	word ptr es:[bx+16],cs

; initialize the serial logic

	cmp	[serflg],0
	jne	xx0012
	jmp	ddi8
xx0012:

; finish the carry through of port table defaults

	mov	bx,[last_pndx]
	cmp	bx,0			; must not have spec'ed anything
	jne	ddi9
	mov	bx,offset porttbl	; for the serial ports
ddi9:
	mov	ax,[numport]
	shl	ax,5			; calc offset of the last
	add	ax,offset porttbl	; table entry used
	cmp	ax,bx
	je	ddi10
	mov	cx,ax
	sub	cx,bx
	shr	cx,5			; calc # of table entries to init
	mov	si,bx
	mov	di,si			; make si point to port table entry
	add	di,size ports		; to use as reference (the last
	mov	ax,cs			; one filled) and di point to the
	mov	ds,ax			; next consecutive table entry
	assume	ds:nothing
	mov	es,ax
	cld
ddi11:
	push	cx
	mov	cx,(size ports)/2
	rep	movsw			; carry the port table data forward
	pop	cx			; to pass on defaults
	loop		ddi11
ddi10:
	mov	ax,cs
	mov	ds,ax
	assume	ds:code

; init cp1list, cp2list and the address and irq's in the port table

	cmp	[numport],0
	je	ddi13
	xor	dx,dx			; init entry counter
	mov	bx,offset porttbl
	mov	si,offset ip_table
	mov	cx,[numportp]
ddi14:
	inc	dx
	cmp	byte ptr [si],1
	jne	ddi16
	mov	[bx].addr,82f8h
	mov	[bx].prtirq,3
	mov	di,offset cp2list
	test	dx,1			; if the entry # is odd, com1
	jz	ddi17
	mov	[bx].addr,83f8h
	mov	[bx].prtirq,4
	mov	di,offset cp1list
	mov	[c1flg],1		; record that irq4 should be hooked
	jmp	short ddi18
ddi17:
	mov	[c2flg],1		; record that irq3 should be hooked
ddi18:
	push	dx
	dec	dx
	shr	dx,1
	mov	ax,size cp
	mul	dx
	pop	dx
	add	di,ax
	mov	[di].cpofs,bx
	sub	[di].cpofs,offset porttbl
	add	bx,size ports
ddi16:
	inc	si
	loop		ddi14
ddi13:

; the port table is declared large enough for 16 ports and is
; positioned at the end of the resident serial logic section.
; calc the offset of the point just past the last table entry
; actually used and use this point as the starting point for the
; serial input and output buffers.

	mov	di,[numport]		; fetch number of logical ports
	shl	di,5			; calc offset of the last
	add	di,offset porttbl	; table entry used
	add	di,size ports		; get past last entry
	add	di,15			; convert to a segment
	shr	di,4
	mov	ax,cs
	add	di,ax

; for each port, account for the space required for
; its two serial buffers

	mov	cx,[numport]
	cmp	cx,0
	je	ddi20
	mov	bx,offset porttbl
ddi21:
	mov	[bx].ibfseg,di		; input buffer at next avail seg
	mov	ax,[bx].ibfsiz		; get the input buffer size
	add	ax,15			; plus 16 for paragraph boundary
	rcr	ax,1			; bring in the carry if full 64k
	shr	ax,1			; convert buffer
	shr	ax,1			;  size to number
	shr	ax,1			;   of paragraphs
	add	di,ax			; calculate next available segment
	mov	[bx].obfseg,di		; output buffer at next avail seg
	mov	ax,[bx].obfsiz		; get the output buffer size
	add	ax,15			; plus 15 for paragraph boundary
	rcr	ax,1			; bring in the carry if full 64k
	shr	ax,1			; convert buffer
	shr	ax,1			;  size to number
	shr	ax,1			;   of paragraphs
	add	di,ax			; calculate next available segment
	add	bx,type ports		; bump bx to the next port
	loop		ddi21
ddi20:

; set the next free segment for the resident serial logic case

	les	bx,[request]
	assume	es:nothing
	mov	word ptr es:[bx+14],0
	mov	es:[bx+16],di

; setup serial irq handlers

	xor	ax,ax
	mov	es,ax
	cli
	mov	bl,0ffh
	cmp	[c1flg],0
	je	ddi23
	mov	word ptr es:[0ch*4],offset serial_irq
	mov	es:[0ch*4+2],cs
	and	bl,11101111b
ddi23:
	cmp	[c2flg],0
	je	ddi24
	mov	word ptr es:[0bh*4],offset serial_irq
	mov	es:[0bh*4+2],cs
	and	bl,11110111b
ddi24:
	in	al,21h
	jmp	$+2
	and	al,bl
	out	21h,al
	sti

; if another serial driver exists, link to it as a child.
; otherwise, hook the int14 vector.

	mov	ah,6
	xor	dx,dx			; see if another driver exists
	int	14h
	test	ah,80h
	jz	ddi25
	mov	ax,cs
	mov	es,ax
	mov	bx,offset int14
	mov	ah,10h			; if yes, register us as his child
	int	14h
	jmp	short ddi8
ddi25:
	xor	ax,ax			; when no other driver exists
	mov	es,ax			; then this driver sets the int14 vector
	assume	es:nothing
	mov	word ptr es:[14h*4],offset int14
	mov	es:[14h*4+2],cs
ddi8:
	jmp	short ddi28		; normal exit
ddi2:

; error termination handler

	mov	ax,cs
	mov	ds,ax
	assume	ds:code
	cmp	dx,0			; if dx != 0, display error msg
	je	ddi29
	mov	ah,9
	int	21h
ddi29:

; make sure this driver can't be opened and shrink allocation to header

	mov	word ptr [viewnm],'\\'
	les	bx,[request]
	mov	word ptr es:[bx+14],offset enddrvr0
	mov	es:[bx+16],cs
	mov	ax,08103h		; error, done, unknown command
	jmp	short ddi30
ddi28:

; normal termination handler
; display installation messages

	mov	ax,cs
	mov	ds,ax
	assume	ds:code
	mov	ax,[nview]
	add	al,'0'
	mov	[vports],al
	mov	dx,offset ddtmsg
	mov	ah,9
	int	21h
	cmp	[serflg],0
	je	ddi31
	mov	dx,offset sermsg
	mov	ah,9
	int	21h
ddi31:
	mov	ax,0100h
ddi30:

if debug eq 1
	push	ax
	call	dbgdump
	pop	ax
endif
	popset bx,cx,dx,si,di,ds,es,bp
	ret
ddtinit endp

	subttl getwkscnt - returns the number of viewport workstations
	page
;======================================================================
;,fs
; getwkscnt - returns the number of viewport workstations
;
; note: that master console is not considered one
; of the workstations reported back.
;
; in:
;
; out:
;
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:nothing
getwkscnt proc near
	push	bx
	push	cx
	push	dx
	xor	bx,bx			; zero detected
	mov	dx,[baseaddr]
	inc	dx
	xor	al,al			; output 0 to mask register to
	out	dx,al			; enable interrupts from all boards
	jmp	$+2
	in	al,dx
	mov	ah,al
	and	al,3			; mask out higher 6 bits
	or	al,al
	jnz	getout
	inc	bx			; first board detected
	mov	cx,3
	shr	ah,2
gbloop:
	mov	al,ah			; look at next pair of bits
	and	al,3			; mask out higher 6 bits
	or	al,al
	jnz	getout			; if no bits set, done
	add	bx,2			; 2 wks per board
	shr	ah,2			; prepare for next iteration
	loop	gbloop
getout:
	mov	[nview],bx		; record number of workstations
	mov	al,byte ptr [keymasks+bx]
	mov	[keyimask],al
	and	al,0feh
	mov	[commask],al
	shl	bx,1
	add	bx,2
	mov	[numportp],bx		; number ports = 2* stations +2
	pop	dx
	pop	cx
	pop	bx
	ret
getwkscnt endp

	subttl initbios - init video through bios
	page
;======================================================================
;,fs
; initbios - init video through bios
;
; this routine is use to initialized the video for
; workstation by calling c000:0003. please note that we
; must save current int 10 vector when doing this. this
; will clear the screen on the workstation.
;
; in:
;
; out:
;
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:nothing
initbios proc near
	pusha
	push	es
	xor	ax,ax
	mov	es,ax
	mov	ax,word ptr es:[10h*4]
	push	ax
	mov	ax,word ptr es:[10h*4+2]
	push	ax
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
	pop	bx			; get segment of int 10h
	pop	ax			; get offset of int 10h
	cli
	mov	word ptr es:[10h*4],ax
	mov	word ptr es:[10h*4+2],bx
	sti
	pop	es
	popa
	ret
initbios endp

	subttl check_type - pass through mechanism for type checking
	page

;================== parameter processing procedures =====================

;======================================================================
;,fs
; check_type - pass through mechanism for type checking
;
; all exit parms are from the type checking procedure, not
; this procedure.  bx and cx must not be used in a type
; checking procedure.
; this procedure crashes di.
;
; in:	ds:si -> paramter string to parse
;	cs:di -> vector table of type checking procedures
;	al = type code to check for
;
; out:	nc if no error
;	 ds:si advanced to next char after parm
;	 return value in ax, dx and/or di (depends on proc)
;	cy if error
;	 ax = error code
;	 si is undefined
;
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:nothing
check_type proc near
	dec	al
	xor	ah,ah
	shl	ax,1
	add	di,ax
	push	cs:[di]
	ret
check_type endp

	subttl fetch_parm - parameter parsing procedure
	page
;======================================================================
;,fs
; fetch_parm - parameter parsing procedure
;
; some exit parms come from the type checking procedure, and
; some are from this procedure.  direction flag is left up.
; calls testdelims, passdelims and check_type.	di is crashed.
;
; in:	ds:si -> paramter string to parse
;	cs:di -> vector table of type checking procedures
;	cs:bx -> parameter classification table
;
; out:	nc if no error
;	 si advanced to next char after parm
;	 bx advanced to next classification table entry
;	 return value in ax, dx and/or di (depends on proc)
;	 cx = element number in the case of a group entry
;	 else cx undefined
;	cy if error
;	 ax = error code
;	 si restored to entry value
;	 bx advanced to next class table entry if ax = rc_null
;	 else bx undefined
;
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:nothing
fetch_parm proc near
	push	si			; si must remain the last thing pushed
	cld

; check for double comma case

	xor	ch,ch			; clear comma counter
ftp1:
	lodsb
	cmp	al,0
	jne	ftp3
	mov	ax,rc_eol
	jmp		ftp4		; goto cy exit handler
ftp3:
	cmp	al,','
	jne	ftp5
	inc	ch
	cmp	ch,2
	jne	ftp1
	mov	ax,rc_null		; si is set just after the 2nd comma
	add	sp,2			; compensate for the pop si
	dec	si			; compensate si for another double comma
	push	si			; that the exit handler will do

; advance bx to next entry

	cmp	byte ptr cs:[bx],pc_skip
	jne	ftp6
	inc	bx
	jmp		ftp4
ftp6:
	cmp	byte ptr cs:[bx],pc_orgrp
	jne	ftp7
	add	bx,2
	mov	al,cs:[bx-1]		; get the count
	xor	ah,ah
	add	bx,ax
	jmp		ftp4
ftp7:
	add	bx,2

	jmp		ftp4		; goto cy exit handler
ftp5:
	call	testdelims
	jz	ftp1
	dec	si			; in the delim set
	call	passdelims
	or	al,al
	jnz	ftp10
	mov	ax,rc_eol
	jmp		ftp4		; goto cy exit handler
ftp10:

; check the entry type code in the parameter classification table

	cmp	byte ptr cs:[bx],pc_skip
	jne	ftp11
	inc	bx			; advance bx to next entry
	jmp		ftp12		; goto nc exit handler
ftp11:
	add	sp,2			; replace stack si with current si
	push	si
	cmp	byte ptr cs:[bx],pc_orgrp
	jne	ftp13
	inc	bx
	mov	cl,cs:[bx]		; get number of type codes in group
	xor	ch,ch			; reset element counter
ftp14:
	inc	bx
	mov	al,cs:[bx]		; get a type code
	push	di
	call	check_type
	jc	ftp16
	add	sp,2			; discard the push'ed di
	push	cx
	sub	cl,ch
	xor	ch,ch			; adjust bx to next entry in parameter
	add	bx,cx			; classification table
	pop	cx
	inc	ch
	mov	cl,ch
	xor	ch,ch			; make cx represent the element number
	jmp		ftp12		; goto nc exit handler
ftp16:
	pop	di
	inc	ch			; advance to next element
	cmp	ch,cl			; tried all elements?
	jne	ftp17
	mov	ax,rc_gerr
	jmp		ftp4		; goto cy exit handler
ftp17:
	pop	si			; restore si for next attempt
	push	si
	jmp		ftp14

ftp13:

; not a group type of entry, must be single

	mov	al,cs:[bx+1]		; get type code
	call	check_type
	jc	ftp4			; return with error code from type checking procedure
	add	bx,2
	jmp		ftp12		; goto nc exit handler
ftp4:

; cy exit handler

	pop	si
	stc
	ret
ftp12:

; nc exit handler

	add	sp,2
	clc
	ret
fetch_parm endp

;============ misc support procedures for the parse exec ==============


	subttl report_error - display an error message
	page
;======================================================================
;,fs
; report_error - display an error message
;
; in:	al = error number
;	cs:di -> error message list
;
; out:	none
;
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:nothing
report_error proc near
	pushf
	push	ax
	push	bx
	push	cx
	push	dx
	push	di
	push	ds
	push	es
	push	cs
	pop	es
	push	cs
	pop	ds
	cld
rpe1:
	cmp	es:[di],al
	je	rpe2
	cmp	byte ptr es:[di],0
	je	rpe2
	mov	cx,0ffffh
	push	ax
	mov	al,'$'
	repne	scasb			; find the string
	pop	ax
	jmp		rpe1
rpe2:
	cmp	es:[di],al
	jne	rpe3
	inc	di
	mov	dx,di
	mov	ah,9
	int	21h
rpe3:
	pop	es
	pop	ds
	pop	di
	pop	dx
	pop	cx
	pop	bx
	pop	ax
	popf
	ret
report_error endp

	subttl testset - check a character for inclusion in a string
	page
;======================================================================
;,fs
; testset - check a character for inclusion in a string
;
; this routine cannot be used to test for a 0.
;
; in:	ds:si -> asciiz string of test characters
;	al = character to test
;
; out:	z if a match
;	ax, ds and si are preserved.
;
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:nothing
testset proc near
	push	ax
	push	si
	dec	si
ts2:
	inc	si
	cmp	byte ptr [si],0
	je	ts3
	cmp	al,[si]
	je	ts1
	jmp	ts2
ts3:
	xor	al,al
	cmp	al,1
ts1:
	pop	si
	pop	ax
	ret
testset endp

	subttl cs_testset - test a set relative to the cs register
	page
;======================================================================
;,fs
; cs_testset - test a set relative to the cs register
;
; this routine cannot be used to test for a 0.
;
; in:	cs:si -> asciiz string of test characters
;	al = character to test
;
; out:	z if a match
;	ax, ds and si are preserved.
;
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:nothing
cs_testset proc near
	push	ds
	push	cs
	pop	ds
	call	testset
	pop	ds
	ret
cs_testset endp

	subttl testdelims - see if al is a delimiter
	page
;======================================================================
;,fs
; testdelims - see if al is a delimiter
;
; a new delimset string can be declared if newdelim exists
;
; in:	al = character to check against delimset
;
; out:	z if a match
;	al is preserved
;
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:nothing

delimset db	',',20h,9,0		; default set of delimiters

testdelims proc near
	push	si
	push	ds
	lea	si,[delimset]
	push	cs
	pop	ds
	call	testset
	pop	ds
	pop	si
	ret
testdelims endp

	subttl passdelims - scan forward past delimiters
	page
;======================================================================
;,fs
; passdelims - scan forward past delimiters
;
; in:	ds:si -> string to parse
;
; out:	ds:si -> first non-delimiter found in string
;	al = character found
;
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:nothing
passdelims proc near
	cld
pd1:
	lodsb
	call	testdelims
	je	pd1
	dec	si
	ret
passdelims endp

	subttl finddelim - scan forward until a delimiter is found
	page
;======================================================================
;,fs
; finddelim - scan forward until a delimiter is found
;
; in addition to stopping on chars in the delimset, this
; procedure will also stop on a 0.  calls testdelims.
;
; in:	ds:si -> string to parse
;
; out:	ds:si -> first delimiter found in string
;	al = character found
;
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:nothing
finddelim proc near
	cld
fd1:
	lodsb
	call	testdelims
	je	fd2
	or	al,al
	jz	fd2
	jmp	fd1
fd2:
	dec	si
	ret
finddelim endp

	subttl chk_parie - check for a parameter of the type  /xx=
	page
;======================================================================
;,fs
; chk_parie - check for a parameter of the type  /xx=
;
; checks for a pair of characters followed by an '=' sign.
; leaves direction flag set to up.
;
; in:	ds:si -> parameter string to test
;	al = first char in pair
;	ah= second char in pair
;
; out:	z if no error
;	 si advanced just past end of the pair
;	nz if error
;	 si undefined
;
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:nothing
chk_paire proc near
	push	bx
	mov	bx,ax
	cld
	lodsb
	cmp	al,bl
	jne	ckp1
	lodsb
	cmp	al,bh
	jne	ckp1
	lodsb
	cmp	al,'='			; return with z or nz based on this comparison
ckp1:
	pop	bx
	ret
chk_paire endp

	subttl hex2word - convert a hexadecimal string to a word
	page
;======================================================================
;,fs
; hex2word - convert a hexadecimal string to a word
;
; suitable as a type checking procedure for the parsing engine.
; this proc does not require 4 digits.	checks are made for overflow
; out of a word and a proper terminating character.  calls testdelim.
;
; in:	ds:si -> parameter string to convert
;
; out:	nc if no error
;	 ax = binary value of string
;	 si advanced just past end of parm
;	cy if error
;	 ax = 3 (rc_gerr)
;	 si undefined
;
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:nothing
hex2word proc near
	push	cx
	xor	ax,ax			; ax will contain the result
	mov	ch,ah
	mov	cl,[si]
	cmp	cl,'0'			; validate first char
	jb	htbx
	cmp	cl,'9'
	jbe	htbloop
	and	cl,0dfh
	cmp	cl,'A'
	jb	htbx
	cmp	cl,'F'
	ja	htbx
htbloop:				; si is source address
	mov	cl,[si]
	cmp	cl,'0'
	jb	htbwrap 		; 00-2f
	cmp	cl,'9'
	jbe	htb1
	and	cl,0dfh
	cmp	cl,'A'
	jb	htbwrap 		; 3a-40
	cmp	cl,'F'
	ja	htbwrap 		; 41-46
	sub	cl,7
htb1:
	sub	cl,'0'
	mov	dx,16
	mul	dx
	or	dx,dx
	jnz	htbx
	add	ax,cx
	inc	si
	jmp	htbloop

; check for a proper end of paramter: a delimiter or end of line code

htbwrap:
	or	cl,cl
	jz	htbwa
	push	ax
	mov	al,cl
	call	testdelims
	pop	ax
	jnz	htbx
htbwa:
	clc
	jmp	htbz
htbx:
	stc
	mov	ax,3
htbz:
	pop	cx
	ret
hex2word endp

	subttl dec2word - convert a decimal string to a word
	page
;======================================================================
;,fs
; dec2word - convert a decimal string to a word
;
; suitable as a type checking procedure for the parsing engine.
;
; in:	ds:si -> string to convert
;
; out:	nc if no error
;	  ax = binary value
;	  ds:si -> first char after parameter
;	cy if error
;	  ax = 3  (rc_gerr)
;	  si undefined
;
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:nothing
dec2word proc near
	push	cx
	push	dx
	xor	ax,ax			; ax will contain the result
	mov	ch,ah
	mov	cl,[si]
	cmp	cl,'0'			; validate the first digit
	jb	dtbx
	cmp	cl,'9'
	ja	dtbx
dtbloop:				; bx is source address
	mov	cl,[si]
	cmp	cl,'0'
	jb	dtbwrap
	cmp	cl,'9'
	ja	dtbwrap
	mov	dx,10
	mul	dx
	or	dx,dx
	jnz	dtbx
	sub	cl,'0'
	add	ax,cx
	inc	si
	jmp	dtbloop

; check for a proper end of paramter: a delimiter or end of line code

dtbwrap:
	or	cl,cl
	jz	dtbw2
	push	ax
	mov	al,cl
	call	testdelims
	pop	ax
	jnz	dtbx
dtbw2:
	clc
	jmp	dtbxx
dtbx:
	stc
	mov	ax,3			; rc_gerr
dtbxx:
	pop	dx
	pop	cx
	ret
dec2word endp

	subttl get_vbase - get a base address
	page
;======================================================================
;,fs
; get_vbase - get a base address
;
; suitable as a type checking procedure for the parsing engine.
; checks for a parameter of the type   /hhhh
;
; in:	ds:si -> parameter string to convert
;
; out:	nc if no error
;	 ax = binary value of string
;	 si advanced just past end of parm
;	cy if error
;	 ax = 3 (rc_gerr)
;	 si undefined
;
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:nothing
get_vbase proc near
	cmp	byte ptr [si],'/'
	jne	gvb1
	inc	si
	call	hex2word		; let hex2word return ax and nc or cy
	jmp		gvb2
gvb1:
	mov	ax,rc_gerr		; general error return code if no '/'
	stc
gvb2:
	ret
get_vbase endp

	subttl get_irq - get an irq parameter
	page
;======================================================================
;,fs
; get_irq - get an irq parameter
;
; suitable as a type checking procedure for the parsing engine.
; checks for a parameter of the type   h   within the irq set
;
; in:	ds:si -> parameter string to convert
;
; out:	nc if no error
;	 ax = binary value of string
;	 si advanced just past end of parm
;	cy if error
;	 ax = 3 (rc_gerr)
;	 si undefined
;
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:nothing

irq_set db	5,6,7,10,11,14,15,0

get_irq proc near
	call	dec2word
	jc	xx004c
	cmp	ah,0
	je	gtq1
xx004c:
	mov	ax,rc_gerr
	stc
	ret
gtq1:
	push	si
	lea	si,[irq_set]
	call	cs_testset		; validate the irq
	pop	si
	jz	gtq2
	mov	ax,rc_gerr
	stc
	ret
gtq2:
	clc
	ret
get_irq endp

	subttl get_ib - get a parameter of type ib=
	page
;======================================================================
;,fs
; get_ib - get a parameter of type ib=
;
; suitable as a type checking procedure for the parsing engine.
; leaves direction flag set to up.
; checks for a parameter of the type   ib=d
;
; in:	ds:si -> parameter string to convert
;
; out:	nc if no error
;	 ax = specified buffer size
;	 si advanced just past end of parm
;	cy if error
;	 ax = 3 (rc_gerr)
;	 si undefined
;
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:nothing
get_ib proc near
	cld
	mov	ax,'BI'
	call	chk_paire
	jnz	gti1
	call	dec2word
	ret				; return with flags and ax from dec2word
gti1:
	mov	ax,3
	stc
	ret
get_ib endp

	subttl get_ob - get a parameter of type ob=
	page
;======================================================================
;,fs
; get_ob - get a parameter of type ob=
;
; suitable as a type checking procedure for the parsing engine.
; leaves direction flag set to up.
; checks for a parameter of the type   ob=d
;
; in:	ds:si -> parameter string to convert
;
; out:	nc if no error
;	 ax = specified buffer size
;	 si advanced just past end of parm
;	cy if error
;	 ax = 3 (rc_gerr)
;	 si undefined
;
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:nothing
get_ob proc near
	cld
	mov	ax,'BO'
	call	chk_paire
	jnz	gto1
	call	dec2word
	ret				; return with flags and ax from dec2word
gto1:
	mov	ax,3
	stc
	ret
get_ob endp

	subttl get_hs - get a parameter of type hs=
	page
;======================================================================
;,fs
; get_hs - get a parameter of type hs=
;
; suitable as a type checking procedure for the parsing engine.
; leaves direction flag set to up.
; checks for a parameter of the type   hs=a
;
; in:	ds:si -> parameter string to convert
;
; out:	nc if no error
;	 al = handshaking letter - in uppercase
;	 si advanced just past end of parm
;	cy if error
;	 ax = 3 (rc_gerr)
;	 si undefined
;
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:nothing

hs_set	db	'NDXPR',0

get_hs proc near
	cld
	mov	ax,'SH'
	call	chk_paire
	jnz	gth1
	lodsb
	cmp	al,0
	je	gth1
	push	si
	lea	si,[hs_set]
	call	cs_testset
	pop	si
	jnz	gth1
	clc
	ret
gth1:
	mov	ax,3
	stc
	ret
get_hs endp

	subttl get_cn - get a parameter of type cn=
	page
;======================================================================
;,fs
; get_cn - get a parameter of type cn=
;
; suitable as a type checking procedure for the parsing engine.
; leaves direction flag set to up.
; checks for a parameter of the type   cn=a
;
; in:	ds:si -> parameter string to convert
;
; out:	nc if no error
;	 al = connection type letter - in uppercase
;	 si advanced just past end of parm
;	cy if error
;	 ax = 3 (rc_gerr)
;	 si undefined
;
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:nothing

cn_set	db	'RLT',0

get_cn proc near
	cld
	mov	ax,'NC'
	call	chk_paire
	jnz	gtn1
	lodsb
	cmp	al,0
	je	gtn1
	push	si
	lea	si,[cn_set]
	call	cs_testset
	pop	si
	jnz	gtn1
	clc
	ret
gtn1:
	mov	ax,3
	stc
	ret
get_cn endp

	subttl get_ip - get the interrupt managed port string
	page
;======================================================================
;,fs
; get_ip - get the interrupt managed port string
;
; suitable as a type checking procedure for the parsing engine.
; leaves direction flag set to up.
; checks for a parameter of the type   /ip=dddd (where d = 0 or 1)
; can use shorthand form to deny all ports:  /ip=n
;
; in:	ds:si -> parameter string to convert
;
; out:	nc if no error
;	 ip_table array filled with ip flags
;	 si advanced just past end of parm
;	cy if error
;	 ax = 3 (rc_gerr)
;	 si undefined
;
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:nothing
get_ip proc near
	pushset bx,cx,di,es
	cld
	lodsb
	cmp	al,'/'
	jne	gtp1
	mov	ax,'PI'
	call	chk_paire
	jnz	gtp1
	cmp	byte ptr [si],'N'
	je	xx0065
	cmp	byte ptr [si],'n'
	jne	gtp2
xx0065:
	mov	ax,cs
	mov	es,ax
	mov	di,offset ip_table
	mov	cx,ip_table_max
	cld
	xor	al,al
	rep	stosb
	inc	si
	jmp	short gtp3
gtp2:
	mov	bx,offset ip_table	; init pointer to table of flags
	xor	di,di			; init limit counter
gtp5:
	lodsb
	cmp	al,0			; exit loop if find end of parm
	je	gtp6
	cmp	al,' '
	je	gtp6
	cmp	di,[numportp]		; error if too many 1's and 0's
	je	gtp1
	cmp	al,'0'			; error if other than 1 or 0
	je	xx006d
	cmp	al,'1'
	jne	gtp1
xx006d:
	cmp	al,'0'
	jne	gtp7
	mov	byte ptr cs:[bx],0	; clear the default flag setting
gtp7:
	inc	bx
	inc	di
	jmp	short gtp5
gtp6:
	cmp	al,0
	jne	gtp8
	dec	si			; let next logic see the eol
gtp8:
	cmp	di,0			; check for /ip= with no 1's and 0's
	je	gtp1
gtp3:
	popset bx,cx,di,es
	mov	al,ah
	clc
	ret				; return with flags and ax from hex2word
gtp1:
	popset bx,cx,di,es
	mov	ax,3
	stc
	ret
get_ip endp

	subttl get_lp - get the logical port marker
	page
;======================================================================
;,fs
; get_lp - get the logical port marker
;
; suitable as a type checking procedure for the parsing engine.
; leaves direction flag set to up.
; checks for a parameter of the type   /pd (where d is a decimal digit)
;
; in:	ds:si -> parameter string to convert
;
; out:	nc if no error
;	 ax = logical port number
;	 si advanced just past end of parm
;	cy if error
;	 ax = 3 (rc_gerr)
;	 si undefined
;
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:nothing
get_lp proc near
	cld
	cmp	word ptr [si],'P/'
	jne	gtl1
	add	si,2
	call	dec2word
	ret				; return with flags and ax from dec2word
gtl1:
	mov	ax,3
	stc
	ret
get_lp endp

	subttl count_ports - tally up logical ports from ip_table
	page
;======================================================================
;,fs
; count_ports - tally up logical ports from ip_table
;
; in:	none
;
; out:	none
;	crashes ax,bx,cx
;
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:nothing
count_ports proc near
	xor	al,al
	mov	cx,[numportp]		; tally the table entries
	mov	bx,offset ip_table
cpt1:
	add	al,cs:[bx]
	inc	bx
	loop		cpt1

	xor	ah,ah
	mov	[numport],ax		; record actual # of logical ports
	cmp	ax,0
	je	cpt3
	mov	[serflg],1
cpt3:
	ret
count_ports endp

	subttl parse_exec - main parsing logic
	page
;======================================================================
;,fs
; parse_exec - main parsing logic
;
; in:	ds:si -> parameter string to convert
;
; out:	nc if ok (and global vars set), else cy if error
;
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:nothing
parse_exec proc near
	mov	ax,ds
	mov	es,ax
	mov	di,si
	mov	cx,0ffffh
	mov	al,13
	repne	scasb			; replace the cr terminator with a 0
	mov	byte ptr es:[di-1],0
	call	finddelim
	call	passdelims		; make si point to the base address

; process p1 - the base address

	mov	[baseaddr],0310h	; establish defaults in case
	mov	[irqnum],5		; no parms are specified
	mov	bx,offset class_tbl_p1	; setup cs:bx for fetch_parm
	mov	di,offset parm_type_tbl ; setup di for fetchparm
	call	fetch_parm
	jnc	pxc1
	cmp	ax,rc_eol
	jne	pxc2
	call	getwkscnt		; get number of workstations in system
	call	count_ports
	cmp	[nview],0
	jne	pxc3
	markerr 1,uer_nohard
	jmp		pxc4		; error
pxc3:
	jmp		pxc5		; done
pxc2:
	markerr 1,er_inv		; position, else error
	jmp		pxc4		; error
pxc1:
	test	ax,not 03f0h		; validate address
	jnz	xx0080
	cmp	ax,100h
	jnb	pxc6
xx0080:
	markerr 1,er_inv
	jmp		pxc4		; error
pxc6:
	mov	[baseaddr],ax
	call	getwkscnt		; get number of workstations in system
	cmp	[nview],0
	jne	pxc7
	markerr 1,uer_nohard
	jmp		pxc4		; error
pxc7:

; process p2 - the keyboard irq

	mov	di,offset parm_type_tbl
	call	fetch_parm
	jnc	pxc8
	markerr 2,er_inv
	jmp		pxc4		; error
pxc8:
	mov	[irqnum],al

; process p3 - the /ip= string

	mov	di,offset parm_type_tbl
	push	si			; save - might need to backup since
	call	fetch_parm		; the /ip= parm is optional
	jnc	pxc9
	cmp	ax,rc_eol
	jne	pxc10
	add	sp,2			; dump the saved si value
	call	count_ports
	jmp		pxc5		; done
pxc10:
	pop	si			; recover original si
	push	si
	mov	bx,offset class_tbl_p4	; if fail on /ip=, check for /pn
	mov	di,offset parm_type_tbl
	call	fetch_parm
	pop	si
	jnc	pxc11			; if fail that, report as /ip= error
	markerr 3,er_inv		; (note: could also be a bum /pn)
	jmp		pxc4		; error
pxc11:
	jmp	short pxc12
pxc9:
	add	sp,2			; dump the saved si value
pxc12:
	call	count_ports

; process p4 - the /pn switch

	mov	[current_lp],0		; used to monitor sequence
	mov	[last_pndx],0		; used to carry defaults forward
	mov	bx,offset porttbl
pxc14:
	mov	bx,offset class_tbl_p4	; reset cs:bx for another p4
	mov	di,offset parm_type_tbl
	call	fetch_parm
	jnc	pxc16
	cmp	ax,rc_eol		; done
	jne	xx0090
	jmp	pxc5
xx0090:
	markerr 4,er_inv
	jmp		pxc4		; error
pxc16:
	cmp	ax,[numport]
	jna	pxc17
	markerr 4,uer_bigpn
	jmp		pxc4		; error
pxc17:
	cmp	ax,[current_lp]
	ja	pxc18
	markerr 4,uer_badseq
	jmp		pxc4		; error
pxc18:
	mov	[current_lp],ax

; convert logical port number to port table offset
; (port_number-1) * 32

	dec	ax
	shl	ax,5
	add	ax,offset porttbl
	mov	[portndx],ax

; if a /pn switch has already been processed, transfer the
; contents of its record into all records up through the one
; for the /pn switch currently being processed.

	cmp	[last_pndx],0
	je	pxc19
	pushset si,ds
	mov	cx,[portndx]
	sub	cx,[last_pndx]
	shr	cx,5			; calc # of table entries to init
	mov	si,[last_pndx]
	mov	di,si			; make si point to port table entry
	add	di,size ports		; to use as reference (the last
	mov	ax,cs			; one filled) and di point to the
	mov	ds,ax			; next consecutive table entry
	mov	es,ax
	cld
pxc20:
	push	cx
	mov	cx,(size ports)/2
	rep	movsw			; carry the port table data forward
	pop	cx			; to pass on defaults
	loop		pxc20
	popset si,ds
pxc19:
	mov	ax,[portndx]
	mov	[last_pndx],ax

; process p5 - iona serial port options

	mov	cs:[p5a_once],0
	mov	cs:[p5b_once],0
	mov	cs:[p5c_once],0
	mov	cs:[p5d_once],0
pxc22:
	mov	bx,offset class_tbl_p5	; reset cs:bx for secondary p5
	mov	di,offset parm_type_tbl
	call	fetch_parm
	jnc	pxc24
	cmp	ax,rc_eol
	jne	pxc25
	mov	al,[p5a_once]
	or	al,[p5b_once]
	or	al,[p5c_once]
	or	al,[p5d_once]		; if no p5's found after a p4
	cmp	al,0			; then something is wrong
	jne	pxc26
	markerr 5,er_inv
	jmp		pxc4		; error
pxc26:
	jmp		pxc5		; done
pxc25:
	cmp	ax,rc_null
	jne	pxc27
	markerr 5,er_nonull
	jmp		pxc4		; error
pxc27:
	push	si			; preserve parse pointer
	mov	al,4			; check for type 4 (/pd)
	mov	di,offset parm_type_tbl
	call	check_type
	pop	si
	jc	xx00a0			; recycle to the p4 level
	jmp	pxc14
xx00a0:
	markerr 5,er_inv
	jmp		pxc4		; error
pxc24:

; cx holds the element number of the group member which matched

	mov	di,cs:[portndx]
	cmp	cx,1
	jne	pxc29
	cmp	cs:[p5a_once],0
	je	pxc30
	markerr 6,uer_ibmax
	jmp		pxc4		; error - more than one p5a per port
pxc30:
	cmp	ax,16
	jnb	pxc31
	markerr 6,uer_iblow
	jmp		pxc4		; input buffer must be at least 16 bytes
pxc31:
	mov	cs:[p5a_once],1
	mov	cs:[di].ibfsiz,ax
	jmp		pxc22
pxc29:
	cmp	cx,2			; p5b	ob=
	jne	pxc32
	cmp	cs:[p5b_once],0
	je	pxc33
	markerr 7,uer_obmax
	jmp		pxc4		; more than one p5b per port
pxc33:
	cmp	ax,16
	jnb	pxc34
	markerr 7,uer_oblow
	jmp		pxc4		; output buffer must be at least 16 bytes
pxc34:
	mov	cs:[p5b_once],1
	mov	cs:[di].obfsiz,ax
	jmp		pxc22
pxc32:
	cmp	cx,3			; p5c	hs=
	jne	pxc35
	cmp	cs:[p5c_once],0
	je	pxc36
	markerr 8,uer_hsmax
	jmp		pxc4		; more than one p5c per port
pxc36:
	mov	cs:[p5c_once],1

	cmp	al,'N'
	jne	pxc37
	and	cs:[di].ioprot,0f0h	; clear flags
	jmp		pxc22
pxc37:
	cmp	al,'R'
	jne	pxc38
	or	cs:[di].ioprot,8	; enable rts
	jmp		pxc22
pxc38:
	cmp	al,'D'
	jne	pxc39
	or	cs:[di].ioprot,4	; enable dtr
	jmp		pxc22
pxc39:
	cmp	al,'X'
	jne	pxc40
	or	cs:[di].ioprot,3	; enable xon/off for xmit and recv
	mov	cs:[di].xoffch,13h
	mov	cs:[di].xonch,11h
	jmp		pxc22
pxc40:

; al must be 'P'

	or	cs:[di].ioprot,3	; enable xon/off for xmit and recv
	mov	cs:[di].xoffch,67h
	mov	cs:[di].xonch,65h
	jmp		pxc22
pxc35:

; cx must be 4 (p5d)  cn=

	cmp	cs:[p5d_once],0
	je	pxc43
	markerr 9,uer_cnmax
	jmp		pxc4		; more than one p5d per port
pxc43:
	mov	cs:[p5d_once],1
	cmp	al,'L'
	jne	pxc44
	and	cs:[di].ioprot,not 30h	; conteract any r or t
	jmp		pxc22
pxc44:
	cmp	al,'R'
	jne	pxc45
	or	cs:[di].ioprot,10h	; set carrier monitor bit
	jmp		pxc22
pxc45:

; must be 'T'

	or	cs:[di].ioprot,30h	; set carrier monitor and report bits
	jmp		pxc22
pxc4:

; error termination handler
; at this point, al holds the error # and ah is the parameter position
; display parameter postition message,	call report_error (to display
; error type) and  set cy flag

	push	cs
	pop	ds
	push	ax
	lea	dx,[crlf]
	mov	ah,9
	int	21h
	lea	dx,[err_lead]
	mov	ah,9
	int	21h
	pop	ax
	push	ax
	mov	bl,ah
	xor	bh,bh
	dec	bx
	shl	bx,1
	add	bx,offset parm_msg_tbl
	mov	dx,[bx]
	mov	ah,9
	int	21h
	lea	dx,[crlf]
	mov	ah,9
	int	21h
	pop	ax
	lea	di,[error_list]
	call	report_error
	lea	dx,[crlf]
	mov	ah,9
	int	21h
	mov	ah,9
	int	21h
	stc
	ret
pxc5:

; normal termination handler

	clc
	ret
parse_exec endp

	subttl	bintohex - convert binary value in ax to hex value at ds:bx
	page
;======================================================================
;,fs
; bintohex - convert binary value in ax to hex value at ds:bx
;
; in:	ds:si -> place to store hexidecimal value
;	ax = value to convert
;	cx = count of digits to convert
;
; out:
;
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:nothing
bintohex proc near
	push	bx
	add	si,cx
	dec	si
	mov	bx,ax
bhloop:
	and	bx,0fh			; mask out lower nibble
	mov	al,byte ptr [hextab+bx]
	mov	byte ptr [si],al
	shr	dx,4
	dec	cx
	jnz	bhloop
	pop	bx
	ret
bintohex endp

code	ends
	end

