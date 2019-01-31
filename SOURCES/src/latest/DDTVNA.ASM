	include page.inc
	title	ddtvna.asm - ali (video network adapter) card ddt

true	equ	1 eq 1
false	equ	1 eq 0

maxwks	equ	32			; for new bank select scheme

copyright equ	true			; true for rom copyright checking

comment ^===============================================================
		       development specification

 program name:	ddtvna.asm			assigned to: jim bean
 module name:	ddtvna				assign date: 10/26/87
 entry points:	vnaterm 			completed:   10/27/87
 entry from:	mosint10, mosint16, mosvidrm
 entry method:	call dword [vector] with ah = function number
 calls: 	i10old (boot interrupt 10h)
 purpose:	mos interface to ali vna
 refer to:	n/a
 last update:	08/14/1992

 version number 2.01
=======================================================================

mjs 5/2/88	added support for a ddtlw proc.  this proc can be called
		by the serial irq logic to cause a re-selection of the
		last workstation when its time to restore the current
		task after a task switch was done.

jrbv 5/20/88	need to set scbvidad and scbvidpg to what we need
		so co-resident ega works

jrb  6/13/88	implement fe call to switch out all ws's (actually
 jrbj		switches in ws 15 so ega/vga can't be coresident with
		16 vna's)

sah 07/22/88	corrected problem related to adding and removing task
		by inserting a wait loop when board is reset when board
		does not respond.

mjs 8/30/88	modified the ddtlw procedure and the vnalcur data item
		to account for nested calls.  fixes video bleed over
		problem with multiple mice.

sah 09/18/88	added tcbunreg support so that more than one task can
		not	be added to the same port. also remove copyright
		checking from driver and check flag set by mosinit

mjs 09/23/88	re-worked bank selection method - see above.  corrected
		word count to clear memory when set mode.

sah 09/23/88	correctly merge 09/23/88 changes in with 09/18/88 mods

mjs 09/27/88	removed the ddtlw logic - its no longer needed since
		the serial irq logic can now use scblastff to save and
		restore the bank selection state.

mjs 09/29/88	correct problem with vna cursor syncronization by
		insuring that the vna workstation is bank selected
		when a set cursor position call is to be passed on from
		this driver to ddtmc.

sah 10/13/88	correction to problem found when driver use with new
		init code.

mjs 03/13/89	add support for the iona board.  this file was generated
		from an action chart file through the use of a filter
		program.  this file, ddtvna.cht, is located in the
		\mos.dir\utils.dir directory of the server.

rkg 07/17/89	added func 18 to driver for keyboard status

mjs 07/27/89	modified 9 xif which used the "and" operator so that
		they used the "test1" operator instead.  this was
		necessary to match a change made in the xifmac.inc file

bwr 11/17/89	messages marked for foreign language translation.

mjs 05/09/90	added the clr_set_irq dummy function.  it is called by
		int14fun11 within int14.inc (only needed by _serial.asm)

mjs 05/22/90	modified the init of vna workstations to prevent
		connect card systems from beeping/hanging when the host
		is soft rebooted.

sah 07/10/90	corrections for zenith keyboard, return eah from reset
		instead of 0aah.

mjs 08/05/90	add to init logic to insure uarts are fully reset on a
		warm boot.  zero out ier and issue eoi to all pics.

mjs 08/13/90	modify to handle maxwks number of workstations when
		the /n parameter is used.  currently, this value is
		set to 32.

mjs 05/24/91	add new printer status ddt function.  clean up text.

================ 5.01 Kernel Ends Here ====================================

mjs 06/14/92	modified printer status testing by adding a new 
		function: get_prnstat.
		changed version # to 2.01

mjs 08/14/92	modified printer status reporting at end of prnchr.
		if taking the non-error exit, return a 90h status
		value instead of re-reading the actual status.
		if re-read the actual status port value, could
		see it when the busy line is down and get a false
		trigger of a printer critical error.
		changed version # to 2.02

=======================================================================^

	subttl	group segments and include block definitions
	page
.xlist

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

	include macros.inc
.list

code	segment para public 'data'	; to force loading with data
	assume	cs:code,ds:nothing,es:nothing,ss:nothing

	include ddtvna.pub

ddtvna	equ	this byte
	dd	-1			; filled in with pointer to next driver
	dw	8000h			; signifying a character device
	dw	strat			; device strategy entry point
	dw	inter			; device interrupt entry point
vnanm	db	'$$VNA   '		; device name

enddrvr0 equ	$

request dd	0

fn	dw	ddtinit 		; 0 - init
	dw	ddtnull 		; 1 - media check
	dw	ddtnull 		; 2 - build bpb
	dw	ddtnull 		; 3 - ioctl input
	dw	ddtread 		; 4 - read
maxfn	equ	($-fn)/2

	subttl strat - strategy function
	page
;======================================================================
;,fs
; strat - strategy function
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

	subttl 
	page
;======================================================================
;,fs
; 
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
inter endp

; null device driver call does nothing

	subttl 
	page
;======================================================================
;,fs
; 
;
; in:	
;
; out:	
;
;,fe
;=====================================================================
	assume	ds:nothing,es:nothing,ss:nothing
ddtnull proc near
	mov	ax,0100h		; return no error, done
	ret
ddtnull endp

	subttl ddtread - return the terminal function vector
	page
;======================================================================
;,fs
; ddtread - return the terminal function vector
;
; in:	
;
; out:	
;
;,fe
;=====================================================================
	assume	ds:nothing,es:nothing,ss:nothing
ddtread proc near
	lds	si,es:[bx+14]
	mov	cx,es:[bx+18]
	mov	word ptr es:[bx+18],0	; nothing read if error
	mov	ax,8103h		; error, done, unknown command
	cmp	cx,4
	jne	ddtrd1			; if not reading exactly 4 bytes
	mov	es:[bx+18],cx		; else read 4 bytes
	mov	word ptr ds:[si],offset vnaterm  ; and these are them
	mov	ds:[si+2],cs
	mov	ax,0100h		; no error, done
ddtrd1:
	ret
ddtread endp

;==================== end of ddt interface code =========================

	subttl	termfn - all the terminal and keyboard functions for mos
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
	dw	prch
	dw	prstr
	dw	get_pstat		; func 18 - get printer status
endtfn	equ	($-tfn)/2

	assume	ds:nothing,es:nothing,ss:nothing

;===================== permanent resident data ==========================

; after parameters have been validated (during initialization), the base
; addresses for each vna and iona card are copied into irppack.  the ipntr?
; and icnt? variables are used to keep track of the addresses in irqpack.

ipntr2	dw	?			; pointer to irq2 entries in irqpack
ipntr5	dw	?			; pointer for irq5
ipntr7	dw	?			; etc.
ipntr10 dw	?
ipntr11 dw	?			; note !!!!!!!!!!!!!!
ipntr12 dw	?			; the ipntr and icnt lists must stay in this order
ipntr15 dw	?

ipntsize equ	$-ipntr2

icnt2	dw	0			; count of irq2 entries in irqpack
icnt5	dw	0			; count for irq5
icnt7	dw	0			; etc.
icnt10	dw	0
icnt11	dw	0
icnt12	dw	0
icnt15	dw	0

; vna and iona base addresses are recorded in irqpack.	iona base addresses
; have their high bit set.  the irq handler accesses the entries in
; this list through the appropriate ipntr? and icnt? variables.

irqpack dw	8 dup(?)

; misc vna variables

nvna	dw	0			; total number of vna base ports
vnaport dw	maxwks/4 dup(0) 	; vna base addresses
numport dw	0			; total number of serial ports declared
scbptr	label	dword
scbofs	dw	0			; offset of scb
scbseg	dw	0			; segment of scb
mcdcbios db	0			; a copy of the foreground's dcbios
ddtmc	dd	0			; address of master console ddt entry
ws0ismc db	'Y'			; 'N' if master console not workstation 0
vnacur	db	0			; who is currently banked in
vnatcb	dw	maxwks dup (-1) 	; register tcbs
vnaunreg dd	maxwks dup (0)		; prevous un-register calls
saveds	dw	0
savebx	dw	0
prnproc1 dw	0			; near pointer to print character routine
prnproc2 dw	0			; near pointer to print string routine
prnproc3 dw	0			; near pointer to print status routine
beepproc dw	0			; near pointer to beep routine
newbank db	0		; != 0 means use new bank select logic


; one key buffer for each workstation

kbsize	equ	32			; 32 scan codes buffered

; there are several spots within this driver hard-coded to expect this
; keyboard size.  they don't all reference the size through kbsize either.

if kbsize ne 32
	%out	kb buffer size wrong for shift count
endif

kbget	dw	maxwks dup(0)
kbput	dw	maxwks dup(0)
keyrdy	db	maxwks dup(0)
kbf	db	maxwks*kbsize dup(0)

;==================== bank selection procedures =========================

	subttl setws - bank in the workstation
	page
;======================================================================
;,fs
; setws - bank in the workstation
;
; in:	al is the workstation number
;
; out:	
;
;,fe
;=====================================================================
	assume	ds:nothing,es:nothing,ss:nothing
setws proc near
	cmp	al,[vnacur]
	jne	setws1
	ret
setws1:
	push	dx
	push	cx
	push	bx
	mov	bx,offset vnaport
	mov	cx,[nvna]
	cmp	[newbank],0
	jne	setws3
setws2:
	mov	dx,cs:[bx]
	add	dl,0fh
	out	dx,al
	inc	bx
	inc	bx
	loop	setws2
	jmp	short setws4
setws3:
	mov	cx,ax			; save entry ax
	mov	al,[vnacur]		; bank out the current workstation
	cmp	al,0ffh
	je	setws5
	xor	ah,ah
	shr	ax,1			; derive an offset to fetch the
	and	ax,not 1		; base address
	add	bx,ax
	mov	dx,cs:[bx]
	add	dl,0fh			; address vna workstation select reg
	mov	al,0fh
	out	dx,al			; select wks #15 (phantom)
	jmp	$+2
	jmp	$+2
setws5:
	mov	ax,cx			; recover entry ax
	cmp	al,0ffh
	je	setws4			; if wks # == ff, all done
	xor	ah,ah
	shr	ax,1
	and	ax,not 1		; derive an offset to fetch the
	mov	bx,offset vnaport	; base address
	add	bx,ax
	mov	dx,cs:[bx]		; fetch the base address
	add	dl,0fh			; address vna workstation select reg
	mov	al,cl
	and	al,3			; derive the board specific wks #
	out	dx,al			; bank 'em in
	mov	ax,cx			; recover entry ax
setws4:
	mov	[vnacur],al
	pop	bx
	pop	cx
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
; selected workstation is another vna workstation then here is no need
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
	pushf				; save current interrupt flag setting
	cli				; secure against irq's that switch video
	push	ax
	push	bx
	push	di
	push	es
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
	lea	si,[tcbcondd]
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
	pop	es
	pop	di
	pop	bx
	pop	ax
	popf				; restore interrupt flag state
	ret
bankin endp

	subttl vnaterm - the entry point for ddt calls
	page
;======================================================================
;,fs
; vnaterm - the entry point for ddt calls
;
; off to master console ddt if
;   workstation 0 and master console is workstation 0
;   or if a video function
; else handle it in vna ddt
;
; in:	
;
; out:	
;
;,fe
;=====================================================================
	assume	ds:nothing,es:nothing,ss:nothing
	db	'VNA'
vnaterm proc far

; 0feh is a special function to switch out all vna's (co-resident case)

	cmp	ah,0feh
	jne	vnafj00
	mov	al,0ffh 		; new way to bank out all vna
	cmp	[newbank],0
	jne	vnafn6
	mov	al,15			; old way to bank out all vna
vnafn6:
	pushf
	cli
	call	setws
	popf
	jmp	vnafnx

; 0ffh is a special function to bank in a workstation

vnafj00:
	cmp	ah,0ffh
	jne	vnafn1
	call	bankin

; now, call ddtmc's ff handler to insure that the video display ram is exposed

	push	di
	push	es
	les	di,[scbptr]
	call	ddtmc			; ah should still be 0ffh
	pop	es
	pop	di
	jmp	vnafnx

; for all video functions - pass the call onto ddtmc
; also, pass to ddtmc when not a video function but the port is 0 and the
; master console is a vna workstation
; otherwise, process locally

; one exception is when a 7 is written to function 0a and an iona card is
; installed.  if the beep call vector isn't even pointing to the beep procedure
; then skip ahead.  also skip if dealing with the master console.

vnafn1:
	cmp	word ptr [beepproc],offset [nullret]
	je	vnafn1a
	cmp	[ws0ismc],'Y'
	jne	vnafn1b
	cmp	byte ptr [si].port,0
	je	vnafn1a
vnafn1b:
	cmp	ax,0a07h
	jne	vnafn1a
	call	[beepproc]
	jmp	vnafnx
vnafn1a:
	cmp	ah,bgnvid
	jb	vnafn2
	cmp	ah,endvid
	jb	vnafn3
vnafn2:
	cmp	[ws0ismc],'Y'
	jne	vnafn4			; ws0 not master console
	cmp	byte ptr [si].port,0
	jne	vnafn4			; not ws0
	cmp	ah,10h
	je	vnafn4			; the print routines are an except - so
	cmp	ah,11h			; the master console could used an iona
	je	vnafn4			; parallel port if desired.

; process a video function

vnafn3:
	cmp	ah,4			; for set cursor type or set cursor
	je	vnafn3a 		; position, must bank in the right
	cmp	ah,5			; workstation first
	jne	vnafn3b
vnafn3a:
	call	bankin
vnafn3b:
	push	si
	call	ddtmc			; when ddtmc calls exposreal, the
	pop	si			; ddt function ff which will come back
	jmp	vnafnx			; to this ddt first

; process non-video functions locally

vnafn4:
	push	bp
	mov	bp,bx
	mov	bl,ah
	cmp	bl,endtfn
	jae	vnafn5
	xor	bh,bh
	shl	bx,1
	xchg	bx,bp
	push	ds
	push	si
	call	tfn[bp]
	pop	si
	pop	ds
vnafn5:
	pop	bp
vnafnx:
	ret
vnaterm endp

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
; out:	ah != 0 if error
;	es:bx -> key buffer flag
;	 key buffer flag is <> 0 while scan codes are buffered
;	al = 80h if master console
;	 00h if not master console
;
;,fe
;=====================================================================
	assume	ds:nothing,es:nothing,ss:nothing
register proc near

; range checking for the workstation number

	mov	al,byte ptr [si].port
	cmp	al,(maxwks-1)		; above the absolute limit?
	lja	regsbad
	cmp	[newbank],0		; if not using the new bank
	jne	reg0a			; selection method and
	cmp	al,15			; the wks # is 15
	jne	reg0a			; and the master console
	cmp	[ws0ismc],'Y'		; is not vna (co-resident)
	je	reg0a			; then error
	jmp	regsbad
reg0a:

; check to see if task has already been registered
; if so return error

	mov	bl,al
	xor	bh,bh
	shl	bx,1
	cmp	word ptr [vnatcb+bx],-1
	ljne	regsbad

; save tcb pointer and port pointer for later.	then, continue
; with init process.

	mov	[saveds],ds
	mov	[savebx],bx
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
	mov	cx,4
regs0:
	push	ds
	push	si
	push	cx
	mov	al,byte ptr [si].port
	mov	bl,al
	mov	bh,0
	and	bx,not 3		; derive the board number from the
	shr	bx,1			; port number
	lea	bp,vnaport[bx]

; to initkb, supply al = port number and cs:[bp] -> port table entry

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
	push	es
	push	bx
	mov	bx,[scbofs]
	mov	es,[scbseg]
	cmp	byte ptr es:[bx+scbvnasys],'Y'
	pop	bx
	pop	es

if	copyright
	jne	regsbad
endif

; update save unregister and set tcbunreg to our routine
; indicated that port is register to tcb pass to us

	push	si
	push	di
	push	bx
	push	ds
	push	es
	mov	bx,[savebx]		; get savebx
	mov	ds,[saveds]
	assume	ds:tcb
	mov	word ptr [vnatcb+bx],ds ; register task
	push	cs
	pop	es
	shl	bx,1
	lea	si,tcbunreg		; save current tcbunreg
	lea	di,vnaunreg
	add	di,bx
	cld
	movsw
	movsw
	lea	ax,unregister		; set our unregister call
	mov	word ptr [tcbunreg],ax
	mov	word ptr [tcbunreg+2],cs
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
	mov	al,98h			; hercules graphics and mc and ali
	mov	cx,0b000h		; physical buffer address (stuffed into
	ret				;   tcbvidad)
register endp

	subttl initkb - initialize a vna keyboard
	page
;======================================================================
;,fs
; initkb - initialize a vna keyboard
;
; notes: init al kb according to vna spec sheet
; release reset, enable kb
; wait a spell
; see if irr indicates char received from kb, if not - can't enable it
; see if char is 0aah - reset code, if not - can't enable it
; else enable ints from kb
;
; in:	al = port number
;	cs:[bp] -> port table entry (port address)
;
; out:	ah = 0ffh if error, else ah = 0
;	bx -> keyready flag if no error
;
;,fe
;=====================================================================
	assume	ds:nothing,es:nothing,ss:nothing
initkb proc near
	push	di
	mov	cl,al
	and	cx,3			; cx = board relative port number (0-3)
	mov	ah,1
	shl	ah,cl			; derive bit mask for 8259 imr from the
	mov	bl,al			; port number
	xor	bh,bh
	shl	bx,1			; bx = word index based on port number
	cli
	mov	dx,cs:[bp]		; allow ali 8259 ints for this port
	add	dx,9
	in	al,dx
	jmp	$+2
	not	ah
	and	al,ah
	out	dx,al
	jmp	$+2
	sub	dx,8
	add	dx,cx			; cx = board relative port number
	add	dx,cx			; derive address of keyboard control register
	mov	al,40h
	out	dx,al			; release kb rst and enable kb
	jmp	$+2
	mov	kbget[bx],0
	mov	kbput[bx],0
	shr	bx,1
	mov	keyrdy[bx],0		; no keys yet
	sti

; wait for 0aah received from keyboard.  the irq handler will set the
; keyrdy flag to != 0.

	mov	di,cx			; put board relative port number in di
	mov	cx,4
initk0:
	push	cx
	mov	cx,0
initk1:
	cmp	keyrdy[bx],0
	jne	initk2x
	loop	initk1
	pop	cx
	loop	initk0
	jmp	initkbx
initk2x:
	pop	cx
initk2:
	mov	si,bx
	mov	cl,5
	shl	si,cl			; if kbsize is 32
	mov	al,kbf[si]		; check keyboard code
	cmp	al,0eah 		; zenith keyboard return eah
	je	initkok
	cmp	al,0aah
	jne	initkbx 		; error if not 0aah
initkok:
	shl	bx,1
	cli
	mov	kbget[bx],0
	mov	kbput[bx],0
	shr	bx,1
	mov	keyrdy[bx],0		; no keys yet
	sti
	lea	bx,keyrdy[bx]
	mov	ah,0
	pop	di
	ret

; undo the keyboard init.
; when enter here, cs:[bp] must point to the port table entry
; di is the board relative port number (0-3)
; ah must have the 8259 mask value

initkbx:
	mov	dx,cs:[bp]
	add	dx,9
	in	al,dx			; disallow ali 8259 ints
	jmp	$+2
	not	ah
	or	al,ah
	out	dx,al
	jmp	$+2
	mov	dx,cs:[bp]		; disable and reset kb
	inc	dx
	add	dx,di
	add	dx,di
	mov	al,80h
	out	dx,al
	mov	ah,0ffh
	push	cx
	xor	cx,cx			; wait awhile here
	loop	$
	pop	cx
	pop	di
	ret
initkb endp

	subttl vna_irq - process a vna keyboard irq
	page
;======================================================================
;,fs
; vna_irq - process a vna keyboard irq
;
; in:	al = ir level
;	dx = vna base port address
;	ds -> local data  (== cs)
;
; out:	keyboard data put in queue
;
;,fe
;=====================================================================
	assume	ds:nothing,es:nothing,ss:nothing
vna_irq proc near
	push	ax
	push	bx
	push	cx
	push	dx
	push	si
	push	di
	push	ax			; save ir level for later calcs
	push	dx			; save port address for later calcs
	xor	ah,ah
	shl	ax,1			; determine kybd port address
	add	dx,ax
	in	al,dx			; get char from keyboard
	jmp	$+2
	mov	ah,al
	inc	dx
	mov	al,0c0h 		; reset keyboard
	out	dx,al
	jmp	$+2
	mov	al,40h
	out	dx,al
	jmp	$+2
	mov	al,ah			; get keyboard char back in al
	pop	dx
	mov	bx,offset vnaport
	mov	cx,maxwks/4
viq000:
	cmp	[bx],dx 		; scan through vnaport to find a match
	je	viq005
	add	bx,2
	loop	viq000
	jmp	$			; problems - should've found a match
viq005:
	mov	bx,maxwks/4
	sub	bx,cx			; bx is now a board number (0-3)
	shl	bx,1
	shl	bx,1
	pop	cx			; pushed as ax - the ir level
	xor	ch,ch
	add	bx,cx			; (board number * 4) + ir level = wks #
	mov	di,bx			; bx is now a byte index for keyrdy
	shl	di,1			; di is now a word index for kbput and kbget
	mov	si,di
	mov	cl,4			; si is now a major index to the 32 byte
	shl	si,cl			; scan code buffers  (kbsize dependency)
	cmp	keyrdy[bx],0		; any scans before?
	mov	keyrdy[bx],0ffh 	; got some now
	mov	bx,kbput[di]		; place to put it
	je	viq010			; nothing in buffer if e
	cmp	bx,kbget[di]
	je	viq020			; buffer is full if e
viq010:
	mov	kbf[si][bx],al
	inc	bx
	cmp	bx,kbsize
	jb	viq020
	xor	bx,bx
viq020:
	mov	kbput[di],bx
	pop	di
	pop	si
	pop	dx
	pop	cx
	pop	bx
	pop	ax
	ret
vna_irq endp

	subttl irq_main - the main vna/iona irq handler
	page
;======================================================================
;,fs
; irq_main - the main vna/iona irq handler
;
; notes: this is the main irq handling loop.  it traces the chain of
; 8259's on the vna and iona boards and determines the source of the
; irq - calling vna_irq or iona_irq.  then, after reseting the 8259(s)
; on the motherboard, as many vna/iona 8259's as were traced are reset.
;
; in:	
;
; out:	
;
;,fe
;=====================================================================
	assume	ds:nothing,es:nothing,ss:nothing

;==== individual irq entry points

irq2_entry:
	push	bx
	mov	bx,offset [ipntr2]
	jmp	short irq_main

irq5_entry:
	push	bx
	mov	bx,offset [ipntr5]
	jmp	short irq_main

irq7_entry:
	push	bx
	mov	bx,offset [ipntr7]
	jmp	short irq_main

irq10_entry:
	push	bx
	mov	bx,offset [ipntr10]
	jmp	short irq_main

irq11_entry:
	push	bx
	mov	bx,offset [ipntr11]
	jmp	short irq_main

irq12_entry:
	push	bx
	mov	bx,offset [ipntr12]
	jmp	short irq_main

irq15_entry:
	push	bx
	mov	bx,offset [ipntr15]

;==== main irq entry point

; on entry, [bx] points to a head of list pointer for the irq

irq_main:
	push	ax
	push	cx
	push	dx
	push	si
	push	di
	push	ds
	push	cs
	pop	ds
	cld
	mov	si,[bx] 		; si = index into the irqpack list
	mov	cx,[bx+ipntsize]	; cx  = # of entries in irqpack
	jcxz	$			; make them errors show up right away
	xor	di,di			; setup as depth counter

; must trace the chain of vna/iona 8259's and determine the
; of the irq.  if an iona 8259 shows an ir level of 7, or if a vna
; 8259 shows an ir level of 6 then the irq came from the next
; pic in a daisy chain.

irq000:
	mov	dx,[si] 		; get the base address
	inc	di			; increment depth counter for eoi loop
	test	dx,8000h
	jz	irq010

; an iona board caused this irq

	and	dx,not 8000h
	add	dx,200eh		; address the 8259's !INTA line
	in	al,dx
	jmp	$+2
	in	al,dx			; make two pulses on !inta
	cmp	al,7			; if not from further down a chain
	je	irq020
	sub	dx,200eh		; derive base address and process
	call	iona_irq		; ir level in al, base address in dx
	add	dx,0eh			; point to the first 8259 register
	jmp	irq030

; a vna board caused this irq

irq010:
	add	dx,0ah			; address the 8259's !INTA line
	in	al,dx
	jmp	$+2
	in	al,dx			; make two pulses on !inta
	cmp	al,6			; if not from further down a chain
	je	irq020
	sub	dx,0ah			; derive base address and process
	call	vna_irq 		; ir level in al, base address in dx
	add	dx,8			; point to the first 8259 register
	jmp	irq030
irq020:
	add	si,2			; advance to next address in list to
	dec	cx			; find the 8259 which sourced the irq
	jcxz	$			; make them errors show up right away
	jmp	irq000

; time to re-trace the chain and issue eoi's

irq030:
	cli
	mov	al,20h
	mov	si,[bx] 		; si = index into the irqpack list
	mov	cx,di			; cx = depth of above loop
irq040:
	mov	dx,[si] 		; get the base address
	add	dx,8			; assume a vna card
	test	dx,8000h
	jz	irq050
	and	dx,7fffh
	add	dx,0eh - 8		; address the 1st 8259 register on an iona card
irq050:
	out	dx,al
	jmp	$+2
	add	si,2			; advance to next address in list to
	loop	irq040
	mov	si,[bx] 		; si = index into the irqpack list
	cmp	si,offset [ipntr10]
	jnae	irq060
	out	0a0h,al
	jmp	$+2
irq060:
	out	20h,al
	jmp	$+2
	pop	ds
	pop	di
	pop	si
	pop	dx
	pop	cx
	pop	ax
	pop	bx
	iret

	subttl unregister - accomodate task removal
	page
;======================================================================
;,fs
; unregister - accomodate task removal
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
	lea	si,[tcbcondd]
	mov	bl,byte ptr [si].port
	xor	bh,bh
	shl	bx,1
	mov	word ptr cs:[vnatcb+bx],-1  ; unregister
	shl	bx,1
	cmp	word ptr cs:[vnaunreg+bx+2],0  ; end of list
	je	unr1
	call	dword ptr cs:[vnaunreg+bx]  ; chain it
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
	mov	bh,0
	mov	al,keyrdy[bx]
	or	al,al
	jz	inkbdx
	shl	bx,1
	mov	si,bx
	mov	cl,4
	shl	si,cl
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
;=====================================================================
	assume	ds:nothing,es:nothing,ss:nothing
outkbctl proc near
	test	al,80h
	jz	outkbx
	mov	bl,byte ptr [si].port
	mov	bh,0
	mov	al,keyrdy[bx]
	or	al,al
	jz	inkbdx			; no scan code to clear
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
	jmp	cs:[prnproc1]
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
;	di -> first char not printed, cx = number not printed
;
;,fe
;=====================================================================
	assume	ds:nothing,es:nothing,ss:nothing
prstr proc near
	jmp	cs:[prnproc2]
prstr endp

	subttl get_pstat - printer status
	page
;======================================================================
;,fs
; get_pstat - printer status
;
; for the non-sherwood case, where a good printer status is faked
; or is imediately available the fresh-flag will be returned as 1.
; when mosint17 sees the fresh-flag come back as 1 when the
; entry al == 0, it will know that there is no need to call getkeys.
;
; in:	ah = 12h
;	al = 0 to initiate a status request
;	   = 1 to check the status and fresh-flag
;	ds:si -> tcbddt
;
; out:	ah = status as in int 17/02
;	al = the state of the fresh-flag (always 1)
;
;,fe
;=====================================================================
	assume	ds:nothing,es:nothing,ss:nothing
get_pstat proc near
	jmp	cs:[prnproc3]
get_pstat endp


nullret:				; used as the initial value for the call vectors
	ret				; for beep and print

enddrvr1 equ	$

;============ end of resident code and data in simple vna case ==========

;===== start of resident code and data when parallel ports are used =====

;=========================== parallel data ==============================

; for each iona card for which a parallel base port was declared, the
; corresponding 4 slots in this prnport table will be filled in.  if banked
; mode was specified, each of the four addresses will be the same.  when linear
; mode is specified, the base address will go in the first slot (of the group
; of four slots for the card) with the next three slots receiving base+4,
; base+8 and base+0ch respectively.  by accessing every 4th element, the
; base address can always be found.
; the printer ddt functions will index this table by the port number in order
; to fetch the parallel port's base address.  if a 0 is fetched, the print
; function should return an error.

prnport dw	maxwks dup(0)
prnpend label byte
	nop				; to keep periscope happy (so prnpend != orig38)

orig38	dd	0			; int38 vector at initialization

	subttl get_prnstat - low level print status function
	page
;======================================================================
;,fs
; get_prnstat - low level print status function
;
; in:	dx = printer port base address + 1
;
; out:	status in ah, destroys al
;
;,fe
;=====================================================================
	assume ds:nothing,es:nothing,ss:nothing
get_prnstat:
	push	cx
	mov	cx,500
gps1:
	in	al,dx
	mov	ah,al
	and	ah,0f8h 		; mask off unused bits
	xor	ah,048h 		; invert active low signals from port
	and	ah,not 40h		; strip off ack bit
	cmp	ah,90h
	loopne	gps1
	pop	cx
	ret

	subttl prnchr - low level printing logic
	page
;======================================================================
;,fs
; prnchr - low level printing logic
;
; in:	al = char to print
;	dx = base port address
;	es -> current tcb - to use in manipulating tcbsiorb
;
; out:	status in ah
;	cy if error
;
;,fe
;=====================================================================
	assume ds:nothing,es:tcb,ss:nothing
prnchr proc near
	push	bx
	push	cx
	push	dx
	push	ax
	mov	bh,182			; number of cycles before error
	out	dx,al			; write the char to the port
	jmp	$+2
	jmp	$+2
	inc	dx			; point to the status register
prn000:
	mov	bl,0ffh 		; number of cycles before suspend
prn005:
	in	al,dx
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
	cli
	in	al,dx			; preserve bits
	and	al,1eh
	or	al,1			; raise the strobe
	jmp	$+2
	jmp	$+2
	out	dx,al
	jmp	$+2
	jmp	$+2
	jmp	$+2
	and	al,1eh
	out	dx,al			; lower the strobe
	sti
	dec	dx
	mov	ah,90h
	clc
	jmp	prnexit
prnerror:
	call	get_prnstat
	or	ah,1			; set timeout error bit
	stc
prnexit:
	pop	dx			; push'ed as the entry ax
	mov	al,dl
	pop	dx
	pop	cx
	pop	bx
	ret
prnchr endp

	subttl print_char - high level character print logic
	page
;======================================================================
;,fs
; print_char - high level character print logic
;
; in:	al = char to print
;	ds:si -> tcbddt
;
; out:	returns ah as in int17
;
;,fe
;=====================================================================
	assume	ds:nothing,es:nothing,ss:nothing
print_char proc near
	push	bx
	push	dx
	push	es
	push	ds
	pop	es
	assume	es:tcb
	mov	bl,[vnacur]		; use the current workstation number
	xor	bh,bh			; to derive an index into the prnport array
	shl	bx,1
	mov	dx,[prnport+bx] 	; get port address
	cmp	dx,0
	je	ptc000
	call	prnchr
	jmp	ptc005
ptc000:
	mov	ah,1			; return error status
ptc005:
	pop	es
	pop	dx
	pop	bx
	ret
print_char endp

	subttl print_str - high level string print logic
	page
;======================================================================
;,fs
; print_str - high level string print logic
;
; in:	es:di -> string to print
;	cx = length (bytes) to print
;	ds:si -> tcbddt
;
; out:	ah as in int 17h if all of string can't be printed
;	di -> first char not printed, cx = number not printed
;
;,fe
;=====================================================================
	assume	ds:nothing,es:nothing,ss:nothing
print_str proc near
	push	bx
	push	dx
	push	ds
	push	si
	push	bp
	mov	bl,[vnacur]		; use the current workstation number
	xor	bh,bh			; to derive an index into the prnport array
	shl	bx,1
	mov	dx,[prnport+bx] 	; get port address
	mov	ah,1			; setup error status for dx == 0 test
	cmp	dx,0
	je	pst010
	push	es
	mov	bp,ds
	mov	es,bp			; swap ds and es
	pop	ds
	mov	si,di
	mov	bp,cx			; store request size for cleanup calcs
	cld
pst000:
	lodsb
	call	prnchr
	jc	pst005
	loop	pst000
	jmp	pst010
pst005:
	add	di,bp			; error handler
	sub	di,cx
pst010:
	pop	bp
	pop	si
	pop	ds
	pop	dx
	pop	bx
	ret
print_str endp

	subttl print_stat - return status
	page
;======================================================================
;,fs
; print_stat - return status
;
; in:	ds:si -> tcbddt
;	bx = 0  (caller should use this value anyway)
;	al = 0 to initiate a status request
;	   = 1 to check the status and fresh-flag
;
; out:	returns ah as in int17
;	al = 1 (fresh flag)
;	bx = 0f3c9h  (signature to verify this function is supported)
;
;,fe
;=====================================================================
	assume	ds:nothing,es:nothing,ss:nothing
print_stat proc near
	push	dx
	mov	bl,[vnacur]		; use the current workstation number
	xor	bh,bh			; to derive an index into the prnport array
	shl	bx,1
	mov	dx,[prnport+bx] 	; get port address
	or	dx,dx
	jz	psa005
	inc	dx			; point to the status register
	call	get_prnstat
	mov	al,1
	mov	bx,0f3c9h		; signature
psa005:
	pop	dx
	ret
print_stat endp

;=========================== beep procedure =============================

; the beep procedure is included with the parallel code so it will stay
; resident when any indication of an iona card is exists within
; the parameter line.

	subttl beep - activate the iona beeper 
	page
;======================================================================
;,fs
; beep - activate the iona beeper 
;
; in:	
;
; out:	
;
;,fe
;=====================================================================
	assume	ds:nothing,es:nothing,ss:nothing
beep proc near
	push	ax
	push	bx
	push	cx
	push	dx
	mov	bl,[vnacur]		; use the current workstation number
	xor	bh,bh			; to derive a board number and a
	mov	cl,bl			; board relative workstation number
	and	cl,3
	shr	bx,1
	and	bx,0feh
	mov	dx,[vnaport+bx]
	add	dx,0dh			; address the iona speaker control register
	xor	al,al
	out	dx,al			; insure all bits are low
	jmp	$+2
	mov	al,1
	shl	al,cl			; make a low to high transition
	out	dx,al
	pop	dx
	pop	cx
	pop	bx
	pop	ax
	ret
beep endp

enddrvr2 equ	$

;====== end of resident code and data when parallel ports are used ======

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

porttbl ports	maxwks dup(<>)		; the port table array
portoff dw	offset porttbl		; pointer to the port table

; the phy2log translation table its used to deterine the physical port
; number (in terms of a port table offset) given an iona base address
; and an interrupt level.  it translates a physical serial port into a
; logical serial port.

phy2log dw	maxwks dup(0)

; sername must be 40 bytes long since this is what mos info expects

sername db	'VNA.SYS (IONA)  V2.02 (920615)          '

; misc serial data

orig1a	dd	0			; int 1a vector at initialization
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

serial	equ	false
emulink equ	false
mos	equ	true

.xlist
include seriomac.inc			; i/o macros
include int14.inc			; int14 logic
include isrsub.inc			; serial irq support surbroutines
.list

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
clr_set_irq proc near
	ret
clr_set_irq endp

	subttl iona_irq - process a serial irq
	page
;======================================================================
;,fs
; iona_irq - process a serial irq
;
; in:	al = ir level
;	dx = vna/iona base port address
;	ds -> local data  (== cs)
;
; out:	
;
;,fe
;=====================================================================
	assume	ds:nothing,es:nothing,ss:nothing
iona_irq proc near
	push	ax
	push	bx
	push	cx
	push	dx
	push	si
	push	di
	push	es
	mov	cx,3
	mov	bx,offset [vnaport] - 2 ; first need to determine the board number
iirq000:
	add	bx,2
	cmp	[bx],dx 		; check each vnaport entry for a match
	je	iirq005
	loop	iirq000
	add	bx,2			; must be the last vnaport entry
iirq005:
	sub	bx,offset [vnaport]	; derive a major index into the phy2log
	shl	bx,1			; table based on the board number
	shl	bx,1
	xor	ah,ah
	shl	ax,1			; (board # * 8) + (ir level * 2) for phy2log index
	add	bx,ax
	mov	bx,[phy2log+bx] 	; fetch the offset of the port table entry
	mov	dx,[bx].addr		; fetch the serial port's address
iirq010:
	rdiir				; read the interrupt indentification register
	test	al,noint		; is he interupting
	jnz	iirq015 		; jump if not this port
	xor	ah,ah			; convert interupt type to offset
	mov	si,ax			; move the offset to si
	push	cx			; save count of ports remaining
	call	inttbl[si]		; call the interupt processor
	pop	cx			; restore the port count
	jmp	short iirq010		; go check it again
iirq015:
	pop	es
	pop	di
	pop	si
	pop	dx
	pop	cx
	pop	bx
	pop	ax
	ret
iona_irq endp

enddrvr3 equ	$

;======= end of resident code and data when serial ports are used =======

;========= start of device driver initialization code and data ==========

;======================== transient data ================================

; put base port addresses in these lists on first pass in parse_exec.
; as addresses are put into each list, the icnt counter will be incremented.
; iona base addresses will have their high bit set.  after all parameters have
; been validated, the contents of these lists will be copied into the irqpack
; list and the ipntr? and icnt? variables will be set appropriately.

ilist2	dw	maxwks/2 dup(?)
ilist5	dw	maxwks/2 dup(?)
ilist7	dw	maxwks/2 dup(?)
ilist10 dw	maxwks/2 dup(?)
ilist11 dw	maxwks/2 dup(?)
ilist12 dw	maxwks/2 dup(?)
ilist15 dw	maxwks/2 dup(?)

; this is a table of the base addresses for the iona serial ports.
; there is a slot in this table for each possible iona card.
; if a serial port base address was not specified, its entry will be 0.
; once all parameters have been validated, these addresses are used to
; program the spl register on each iona board.

serbase dw	maxwks/4 dup(0)

; this bit map, and the chk_cflt procedure, are used to check for address
; conflicts.  each bit in this table represents a group of 4 addresses since
; this is the smallest unit of concern (when parallel ports are in banked
; mode).  as each address is found in parsing the parameter line, the
; corresponding bits are tested.  if not set already, they are set.
; if already set, then there is an address conflict.

cflt_map db	7 dup(0)
	db	0f0h			; 01f0 - reserved
	db	3 dup(0)
	db	0f0h			; 0270 - reserved
	db	3 dup(0)
	db	0f0h			; 02f0 - reserved
	db	0fh			; 0300 - reserved
	db	2 dup(0)
	db	0f0h			; 0370 - reserved
	db	0
	db	0f0h			; 03b0 - reserved
	db	0ffh			; 03d0 - reserved
	db	0f0h			; 03f0 - reserved

;===== misc vars for the parse exec

p1_val	dw	?
p3_rc	dw	?
p3_val	dw	?
bl_mode db	?
p5_val	dw	?
p6_val	dw	?
p7_rc	dw	?
p7_count db	?
p7_cflt db	?
portndx dw	?
p8a_once db	?
p8b_once db	?
p8c_once db	?
p8d_once db	?

;===== misc vars for ddtinit

parflg	db	0			; indicates parallel logic is to stay
serflg	db	0			; indicates serial logic is to stay

; this array stores the results of the /ms= option - to specify which
; workstations require modem handshaking signal support.  when a new
; version of the iona board is available which supports both the
; parallel port and modem handshaking lines, this parameter can
; be ignored.

modem_sig db	maxwks dup('N')

;========================= error mesages ===========================

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

edef uer_np3wp4,51,'B/L parameter supplied when no printer port was specifie                '  ;@@xlat
edef uer_np4wp3,52,'B/L parameter required when a printer port is specified                 '  ;@@xlat
edef uer_vnamax,53,'More than 4 VNA base ports specified                '  ;@@xlat
edef uer_adrcflt,54,'Address conflict        '	;@@xlat
edef uer_sermax,55,'More than 4 serial ports specified per VNA/IONA card set                '  ;@@xlat
edef uer_ibmax,56,'More than 1 IB= per port        '  ;@@xlat
edef uer_obmax,57,'More than 1 OB= per port        '  ;@@xlat
edef uer_hsmax,58,'More than 1 HS= per port        '  ;@@xlat
edef uer_cnmax,59,'More than 1 HS= per port        '  ;@@xlat
edef uer_iblow,60,'Input buffer must be at least 16 bytes        '  ;@@xlat
edef uer_oblow,61,'Output buffer must be at least 16 bytes        '  ;@@xlat
db	0				; end of list marker

crlf	db	13,10,'$'
err_lead db	'Parameter error in VNA.SYS:        ',13,10,'$'  ;@@xlat

em1	db	'VNA base address        $'  ;@@xlat
em2	db	'VNA keyboard irq        $'  ;@@xlat
em3	db	'IONA parallel base address        $'  ;@@xlat
em4	db	'IONA B/L option        $'  ;@@xlat
em5	db	'IONA serial base address        $'  ;@@xlat
em6	db	'IONA serial irq        $'  ;@@xlat
em7	db	'IONA serial port address (/AD=)        $'  ;@@xlat
em8	db	'IONA serial option (IB=, OB=, HS=, CN=)        $'  ;@@xlat
em9	db	'IONA serial option (IB=)        $'  ;@@xlat
em10	db	'IONA serial option (OB=)        $'  ;@@xlat
em11	db	'IONA serial option (HS=)        $'  ;@@xlat
em12	db	'IONA serial option (CN=)        $'  ;@@xlat
em13	db	'IONA modem signal option (/MS=)           $'  ;@@xlat

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
	dw	em10
	dw	em11
	dw	em12
	dw	em13

ddt2	db	'VNA terminal device driver (900711) already installed         ',13,10,'$'  ;@@xlat

;======================= installation messages ==========================

badali	equ	$
ddtmsg	db	'VNA terminal device driver (900711) installed             ',13,10,'$'	;@@xlat
parmsg	db	'  IONA parallel port logic installed             ',13,10,'$'  ;@@xlat
sermsg	db	'  IONA serial port logic installed             ',13,10,'$'  ;@@xlat
crmsg1	db	'(c) Copyright 1987 The Software Link Incorporated '  ;@@xlat
	db	'All rights reserved worldwide.'  ;@@xlat
crlen1	equ	$-crmsg1

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
;=====================================================================
	assume	ds:nothing,es:nothing,ss:nothing
ddtinit proc near
	push	cs
	pop	ds
	mov	ax,offset [nullret]
	mov	[beepproc],ax
	mov	[prnproc1],ax
	mov	[prnproc2],ax
	mov	[prnproc3],ax
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
	mov	es,es:[bx+scbtcbpf]	; access the foreground tcb
	assume	es:tcb
	mov	al,byte ptr [tcbcondd.dcbios]  ; save foreground's dcbios
	lds	bx,[tcbcondd]		; to detect co-resident case
	mov	dx,offset [ddt2]	; in the procedure hideif

; check for a second loading of vna.sys

	cmp	word ptr [bx-3],'NV'
	je	ddi001
	jmp	ddi002
ddi001:
	cmp	byte ptr [bx-1],'A'
	jne	ddi002
	jmp	ddierror
ddi002:
	mov	word ptr [ddtmc],bx	; mcterm address
	mov	word ptr [ddtmc+2],ds
	mov	al,byte ptr [tcbcondd.dcpherc]
	mov	[ws0ismc],al
	push	es
	les	bx,[request]
	lds	si,es:[bx+18]		; -> device driver command line
	call	parse_exec		; parse the command line
	pop	es
	push	cs
	pop	ds
	mov	dx,0			; no additional error message if error
	jnc	ddi003
	jmp	ddierror
ddi003:
	mov	al,[ws0ismc]

; if workstation 0 is hercules capable, set the ali bit in tcbvram,
; store vna port address and link vna driver in ahead of mc driver

	cmp	al,'Y'
	jne	ddi005
	or	[tcbvram],08h
	mov	word ptr [tcbcondd.port],0
	mov	word ptr [tcbcondd],offset [vnaterm]
	mov	word ptr [tcbcondd+2],cs
ddi005:
	push	bx
	push	es
	les	bx,cs:[scbptr]
	assume	es:nothing
	cmp	byte ptr es:[bx+scbvnasys],'Y'
	pop	es
	assume	es:tcb
	pop	bx
	if not copyright
	cmp	al,al
	endif
	jz	ddi010
	mov	dx,offset badali
	jmp	ddierror
ddi010:

; initialize each ws for each ali card

	mov	al,4
	cmp	[ws0ismc],'Y'
	jne	ddi015
	mov	al,3
ddi015:
	mov	bx,offset [vnaport]
	mov	cx,[nvna]
ddi020:
	push	cx
	push	bx
	mov	dx,cs:[bx]
	mov	cl,al
	sub	bx,offset [vnaport]
	shl	bl,1
	call	initvna
	pop	bx
	pop	cx
	mov	al,4
	inc	bx
	inc	bx
	loop	ddi020

; set up main system irq's and 8259's

	cmp	[icnt2],0
	je	ddi025
	mov	al,2
	mov	cx,[icnt2]
	mov	bx,[ipntr2]
	call	initpic
ddi025:
	cmp	[icnt5],0
	je	ddi030
	mov	al,5
	mov	cx,[icnt5]
	mov	bx,[ipntr5]
	call	initpic
ddi030:
	cmp	[icnt7],0
	je	ddi035
	mov	al,7
	mov	cx,[icnt7]
	mov	bx,[ipntr7]
	call	initpic
ddi035:
	cmp	[icnt10],0
	je	ddi040
	mov	al,10
	mov	cx,[icnt10]
	mov	bx,[ipntr10]
	call	initpic
ddi040:
	cmp	[icnt11],0
	je	ddi045
	mov	al,11
	mov	cx,[icnt11]
	mov	bx,[ipntr11]
	call	initpic
ddi045:
	cmp	[icnt12],0
	je	ddi050
	mov	al,12
	mov	cx,[icnt12]
	mov	bx,[ipntr12]
	call	initpic
ddi050:
	cmp	[icnt15],0
	je	ddi055
	mov	al,15
	mov	cx,[icnt15]
	mov	bx,[ipntr15]
	call	initpic
ddi055:

; initialize registers on each iona card - pcr1, pcr2, pcr3 and the 8253

	push	bp
	xor	cl,cl
ddi060: 				; for each vna/iona card pair
	xor	bp,bp			; use bp to flag when pcr1 should be written
	mov	ch,11110000b		; set ch up as a byte for pcr 1
	mov	bl,cl			; (ports disabled, modem hndshk disabled)
	xor	bh,bh
	shl	bx,1			; derive an index into the vnaport
	mov	dx,[vnaport+bx] 	; array   (card number - 1) * 2
	shl	bx,1			; get the base address in dx and
	shl	bx,1			; adjust the index for the prnport array
	mov	ax,[prnport+bx]
	cmp	ax,0			; if a printer support was specified
	je	ddi065
	shr	ax,1
	shr	ax,1			; adjust base address
	add	dx,400dh
	out	dx,al			; program pcr2 with the starting
	sub	dx,400dh		; parallel port address
	mov	[parflg],1		; flag that parallel code is used
	mov	bp,1			; flag that pcr1 be written
	or	ch,00000010b		; setup to enable parallel port logic

; if the next entry != the current one, linear mode was specified

	mov	ax,[prnport+bx]
	cmp	ax,[prnport+bx+2]
	je	ddi065
	or	ch,00000001b
ddi065:
	mov	bl,cl			; derive an index into the serbase
	xor	bh,bh			; array   (card number - 1) * 2
	shl	bx,1
	mov	ax,[serbase+bx]
	cmp	ax,0			; if any serial ports were specified
	je	ddi080
	shr	ax,1
	shr	ax,1			; adjust base address
	shr	ax,1
	add	dx,600dh
	out	dx,al			; program pcr3 with the starting
	sub	dx,600dh		; serial port address
	mov	[serflg],1		; flag that serial code is used
	mov	bp,1			; flag that pcr1 be written
	or	ch,00001100b		; enable serial ports - always in linear mode

; in the first level iona product, its not possible to have both
; modem handshaking signals and parallel port support.	the /ms=
; option is used to specify when modem handshaking is required.
; this limitation won't exist in a future version of the hardware.
; when this new hardware is available, the /ms= option can
; be ignored.

	mov	ah,11101111b		; init bit mask for modem signals
	mov	bl,cl			; reset bx for the modem_sig array
	xor	bh,bh
	mov	si,4
ddi070:
	cmp	byte ptr [modem_sig+bx],'Y'
	jne	ddi075
	and	ch,ah			; zeroing the bit to enable modem signals
ddi075:
	inc	bx			; point to the next byte in modem_sig
	shl	ah,1			; adjust the mask
	or	ah,1
	dec	si
	jnz	ddi070
ddi080:
	cmp	bp,1			; if any ports specified for this card
	jne	ddi085
	add	dx,200dh		; (e.g. if an iona card is being used)
	mov	al,ch			; then write to pcr 1 to enable or disable
	out	dx,al			; the ports based on the above analysis
	sub	dx,200dh

; initialize the two 8253's on each iona board (for the speakers)

	push	cx
	add	dx,700eh		; base + 700e	timer 1 control register
	mov	al,00110110b		; cntr 0, load lsb/msg, mode 3, binary
	mov	si,3000h
	mov	cx,0800h		; use a count of 800h for divide by 2048
	call	set_cntr		; (1.8432 mhz / 2048 = 900 hz)
	mov	al,01110010b		; cntr 1, load lsb/msb, mode 1, binary
	mov	si,2000h
	mov	cx,0384h		; use a count of 900 for a 1 second period
	call	set_cntr
	mov	al,10110010b		; cntr 2, load lsb/msb, mode 1, binary
	mov	si,1000h
	mov	cx,0384h
	call	set_cntr
	add	dx,4000h		; adjust dx to base of timer 2
	mov	al,00110010b		; cntr 0, load lsb/msb, mode 1, binary
	mov	si,3000h
	mov	cx,0384h
	call	set_cntr
	mov	al,01110010b		; cntr 1, load lsb/msb, mode 1, binary
	mov	si,2000h
	mov	cx,0384h
	call	set_cntr
	mov	al,10110110b		; cntr 2, load lsb/msg, mode 3, binary
	mov	si,1000h
	mov	cx,0800h		; use a count of 800h for divide by 2048
	call	set_cntr		; (1.8432 mhz / 2048 = 900 hz)
	pop	cx
ddi085:
	inc	cl
	cmp	cl,byte ptr [nvna]
	je	ddi090
	jmp	ddi060
ddi090:
	pop	bp

; for each non-zero entry in the prnport array, initialize
; the parallel port

	mov	bx,offset [prnport]
	mov	al,0
ddi095:
	mov	dx,[bx]
	cmp	dx,0
	je	ddi105
	call	setws			; just in case using banked mode
	add	dx,2			; add 2 for control port
	push	ax
	mov	al,8			; lower the init line
	out	dx,al
	mov	cx,8000
ddi100:
	loop	ddi100
	mov	al,0ch			; raise the init line back up
	out	dx,al
	jmp	$+2
	sub	dx,2
	pop	ax
ddi105:
	add	bx,2
	inc	al
	cmp	al,maxwks
	jne	ddi095

; update jump vectors

	cmp	[serflg],1
	je	ddi127a
	cmp	[parflg],1
	jne	ddi127
ddi127a:
	mov	ax,offset [beep]
	mov	[beepproc],ax
ddi127:
	cmp	[parflg],1
	jne	ddi128
	mov	word ptr [prnproc1],offset print_char
	mov	word ptr [prnproc2],offset print_str
	mov	word ptr [prnproc3],offset print_stat
ddi128:

; for each serial port, output a 0 to the ier.	this is done to insure
; the uart's are fully reset on a warm boot.

	mov	ax,cs
	mov	ds,ax
	mov	cx,[numport]
	jcxz	ddi129e
	mov	bx,offset [porttbl]
	xor	al,al
ddi129a:
	mov	dx,[bx].addr
	add	dx,1			; address the ier
	out	dx,al			; disable uart interrupts
	jmp	$+2
	jmp	$+2
	add	bx,type ports		; bump bx to the next port
	loop	ddi129a 		; go do the next port

; find all iona pic's and clear them - also for warm boot insurance.
; note: this loop presumes there will be an iona for every vna.
; if there isn't, shouldn't hurt anything.

	mov	al,20h			; eoi command
	xor	cx,cx
ddi129c:				; for each vna/iona card pair
	mov	bx,cx
	shl	bx,1			; derive an index into the vnaport
	mov	dx,[vnaport+bx] 	; array   (card number - 1) * 2
	add	dx,0eh			; address iona 8259 even register
	out	dx,al
	jmp	$+2
	jmp	$+2
	inc	cx
	cmp	cx,[nvna]
	jne	ddi129c

; if any irq > 7 is in use, clear the upper motherboard pic

	mov	cx,[icnt10]
	add	cx,[icnt11]
	add	cx,[icnt12]
	add	cx,[icnt15]
	jcxz	ddi129d
	mov	dx,0a0h
	out	dx,al
	jmp	$+2
	jmp	$+2
ddi129d:

; clear the main motherboard pic

	mov	dx,20h
	out	dx,al
ddi129e:

; calculate the next free segment - accounting for how much code
; and data must be kept

	mov	di,offset [enddrvr1]	; only keep vna code and data
	cmp	[parflg],1		; if any parallel ports specified, keep
	jne	ddi130
	mov	di,offset [enddrvr2]	; the second level of code and data
ddi130:
	cmp	[serflg],1		; if any serial ports, keep the third
	jne	ddi135
	mov	di,offset [enddrvr3]	; level of code and data
ddi135:
	add	di,15
	mov	cl,4			; convert the offset in di to paragraphs
	shr	di,cl			; and calc the next free segment
	mov	ax,cs
	add	di,ax

; when serial port support is being used, must adjust the next free
; segment to account for the serial data buffers.  also must set the
; int14 vector or establish this driver as a child of an existing driver

	cmp	[serflg],1
	jne	ddi150

; for each port, account for the space required for
; its two serial buffers

	mov	cx,[numport]
	cmp	cx,0			; could be a serial base but no /ad's
	je	ddi143
	mov	bx,offset [porttbl]
ddi140:
	mov	[bx].ibfseg,di		; input buffer at next avail seg
	mov	ax,[bx].ibfsiz		; get the input buffer size
	add	ax,15			; plus 16 for paragraph boundary
	rcr ax,1			; bring in the carry if full 64k
	shr	ax,1			; convert buffer
	shr	ax,1			;  size to number
	shr	ax,1			;   of paragraphs
	add	di,ax			; calculate next available segment
	mov	[bx].obfseg,di		; output buffer at next avail seg
	mov	ax,[bx].obfsiz		; get the output buffer size
	add	ax,15			; plus 15 for paragraph boundary
	rcr ax,1			; bring in the carry if full 64k
	shr	ax,1			; convert buffer
	shr	ax,1			;  size to number
	shr	ax,1			;   of paragraphs
	add	di,ax			; calculate next available segment
	add	bx,type ports		; bump bx to the next port
	loop	ddi140			; go do the next port
ddi143:
	push	di
	mov	ah,6
	xor	dx,dx			; see if another serial driver exists
	int	14h
	test	ah,80h
	jz	ddi145
	push	cs
	pop	es
	lea	bx,[int14]
	mov	ah,10h			; if yes, register us as his child
	int	14h
	jmp	short ddi147
ddi145:
	xor	ax,ax			; when no other driver exists
	mov	es,ax			; then this driver sets the int14 vector
	cli
	mov	es:[14h*4],offset [int14]
	mov	es:[14h*4+2],cs
	sti
ddi147:
	pop	di
ddi150:
	les	bx,[request]
	assume	es:nothing
	mov	word ptr es:[bx+14],0	; set next free segment into
	mov	es:[bx+16],di		; the request header

; display installation messages

	mov	dx,offset [ddtmsg]
	mov	ah,9
	int	21h
	cmp	[parflg],1
	jne	ddi155
	mov	dx,offset [parmsg]
	mov	ah,9
	int	21h
ddi155:
	cmp	[serflg],1
	jne	ddi160
	mov	dx,offset [sermsg]
	mov	ah,9
	int	21h
ddi160:
	mov	ax,0100h
	ret

; display error message (unless dx == 0)

ddierror:
	push	cs
	pop	ds
	cmp	dx,0
	je	dder01
	push	cs
	pop	ds
	mov	ah,9
	int	21h

; make sure this driver can't be opened and shrink allocation to header

dder01:
	mov	word ptr [vnanm],'\\'	; can't be opened
	les	bx,[request]
	mov	word ptr es:[bx+14],offset [enddrvr0]
	mov	es:[bx+16],cs
	ret
ddtinit endp

;================== parameter processing definitions ====================

; parameter classification table entry codes

pc_skip equ	0			; skip case
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

parm_type_tbl:
;		type  format  return		   notes
;		====  ======  ======  ==================================
dw	get_vbase			; 1   /hhhh	ax     literal / followed by 4 hex digits
dw	get_irq 			; 2   h 	ax     1 or more decimal digits - 64k max
dw	hex2word			; 3   hhhh	ax     hex word value
dw	get_paddr			; 4   /ad=hhhh	ax     literal /ad=  and a hex word value
dw	get_ib				; 5   ib=d	ax     literal ib=  and a decimal word value
dw	get_ob				; 6   ob=d	ax     literal ob=  and a decimal word value
dw	get_hs				; 7   hs=a	al     literal hs=  and a single alpha char
dw	get_cn				; 8   cn=a	al     literal cn=  and a single alpha char
dw	get_ms				; 9   /ms=xxxx	al     literal /ms= and y's or N's

;=================== parameter classification table ======================

class_tbl_p1:
	db	pc_singl,1		; p1 - vna base port address
	db	pc_singl,2		; p2 - vna kybd irq
	db	pc_singl,3		; p3 - iona printer base address
	db	pc_skip 		; p4 - b/l designator
	db	pc_singl,3		; p5 - iona serial base address
	db	pc_singl,2		; p6 - iona serial irq
class_tbl_p7:
	db	pc_singl,4		; p7 - iona serial port address
class_tbl_p8:
	db	pc_orgrp,4,5,6,7,8	; p8a,b,c and d - iona serial port options
class_tbl_p9:
	db	pc_singl,9		; p9 - enable modem signals option

;================== parameter processing procedures =====================

	subttl check_type - pass through mechanism for type checking
	page
;======================================================================
;,fs
; check_type - pass through mechanism for type checking
;
; notes: all exit parms are from the type checking procedure, not
; this procedure.  bx and cx must not be used in a type checking
; procedure.  this procedure crashes di.
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
;=====================================================================
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
; notes: some exit parms come from the type checking procedure, and
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
;=====================================================================
	assume	ds:nothing,es:nothing,ss:nothing
fetch_parm proc near
	push	si			; si must remain the last thing pushed
	cld

; check for double comma case

	xor	ch,ch			; clear comma counter
ftp1:
	lodsb
	cmp	al,0
	jne	ftp2
	mov	ax,rc_eol
	jmp	ftp10			; goto cy exit handler
ftp2:
	cmp	al,','
	jne	ftp3
	inc	ch
	cmp	ch,2
	jne	ftp1
	mov	ax,rc_null		; si is set just after the 2nd comma
	add	sp,2			; compensate for the pop si
	dec	si			; compensate si for another double comma
	push	si			; that the exit handler will do

; advance bx to next entry

	cmp	byte ptr cs:[bx],pc_skip
	jne	ftp2a
	inc	bx
	jmp	ftp10
ftp2a:
	cmp	byte ptr cs:[bx],pc_orgrp
	jne	ftp2b
	add	bx,2
	mov	al,cs:[bx-1]		; get the count
	xor	ah,ah
	add	bx,ax
	jmp	ftp10
ftp2b:
	add	bx,2
	jmp	ftp10			; goto cy exit handler
ftp3:
	call	testdelims
	jz	ftp1			; can't be a null parm if not
	dec	si			; in the delim set
	jmp	ftp4			; exit loop
ftp4:
	call	passdelims
	or	al,al
	jnz	ftp5
	mov	ax,rc_eol
	jmp	ftp10			; goto cy exit handler

; check the entry type code in the parameter classification table

ftp5:
	cmp	byte ptr cs:[bx],pc_skip
	jne	ftp5a
	inc	bx			; advance bx to next entry
	jmp	ftp11			; goto nc exit handler
ftp5a:
	add	sp,2			; replace stack si with current si
	push	si
	cmp	byte ptr cs:[bx],pc_orgrp
	jne	ftp9
	inc	bx
	mov	cl,cs:[bx]		; get number of type codes in group
	xor	ch,ch			; reset element counter
ftp6:
	inc	bx
	mov	al,cs:[bx]		; get a type code
	push	di
	call	check_type
	jc	ftp7
	add	sp,2			; discard the push'ed di
	push	cx
	sub	cl,ch
	xor	ch,ch			; adjust bx to next entry in parameter
	add	bx,cx			; classification table
	pop	cx
	inc	ch
	mov	cl,ch
	xor	ch,ch			; make cx represent the element number
	jmp	ftp11			; goto nc exit handler
ftp7:
	pop	di
	inc	ch			; advance to next element
	cmp	ch,cl			; tried all elements?
	jne	ftp8
	mov	ax,rc_gerr
	jmp	ftp10			; goto cy exit handler
ftp8:
	pop	si			; restore si for next attempt
	push	si
	jmp	ftp6

; not a group type of entry, must be single

ftp9:
	mov	al,cs:[bx+1]		; get type code
	call	check_type
	jc	ftp10			; return with error code from type checking procedure
	add	bx,2
	jmp	ftp11			; goto nc exit handler

; cy exit handler

ftp10:
	pop	si
	stc
	ret

; nc exit handler

ftp11:
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
; out:	
;
;,fe
;=====================================================================
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
rer01:
	cmp	es:[di],al
	je	rer02
	cmp	byte ptr es:[di],0
	je	rer02
	mov	cx,0ffffh
	push	ax
	mov	al,'$'
	repne scasb			; find the string
	pop	ax
	jmp	rer01
rer02:
	cmp	es:[di],al
	jne	rer03
	inc	di
	mov	dx,di
	mov	ah,9
	int	21h
rer03:
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
; notes: this routine cannot be used to test for a 0.
; ax, ds and si are preserved.
;
; in:	ds:si -> asciiz string of test characters
;	al = character to test
;
; out:	z if a match
;
;,fe
;=====================================================================
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

	subttl cs_testset - check a character for inclusion in a string
	page
;======================================================================
;,fs
; cs_testset - check a character for inclusion in a string
;
; notes: this routine cannot be used to test for a 0.
; ax, ds and si are preserved.
;
; in:	cs:si -> asciiz string of test characters
;	al = character to test
;
; out:	z if a match
;
;,fe
;=====================================================================
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
; notes: a new delimset string can be declared if newdelim exists
; al is preserved.  calls testset.
;
; in:	al = character to check against delimset
;
; out:	z if a match
;
;,fe
;=====================================================================
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
;		al = character found
;
;,fe
;=====================================================================
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
; notes: in addition to stopping on chars in the delimset, this
; procedure will also stop on a 0.  calls testdelims.
;
; in:	ds:si -> string to parse
;
; out:	ds:si -> first delimiter found in string
;	al = character found
;
;,fe
;=====================================================================
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

	subttl chk_cflt - test for address conflicts
	page
;======================================================================
;,fs
; 
;
; notes: uses the cflt_map bit map to check for address conflicts.
; does not preserve bx or cx.
;
; in:	bx = base address (within 0100 to 03f0)
;	cx = size factor
;	 cx = 1 for banked parallel ports
;	 cx = 4 for linear parallel ports and vna base address
;	 cx = 8 for iona serial base address
;
; out:	nz for conflict, z if ok
;
;,fe
;=====================================================================
	assume	ds:nothing,es:nothing,ss:nothing
chk_cflt proc near
	push	dx
	sub	bx,100h
	shr	bx,1
	shr	bx,1
	push	cx
	mov	cx,bx
	and	cx,00000111b		; form bit number
	mov	dl,1
	shl	dl,cl			; form bit mask in dl
	pop	cx
	and	bx,11111000b
	shr	bx,1
	shr	bx,1
	shr	bx,1			; form byte offset in bx
	lea	bx,[bx+cflt_map]
cft01:
	test	cs:[bx],dl
	jnz	cft03
	or	cs:[bx],dl
	shl	dl,1
	jnc	cft02
	inc	bx
	mov	dl,1
cft02:
	loop	cft01
	cmp	ax,ax			; set z
cft03:
	pop	dx
	ret
chk_cflt endp

	subttl put_ilist - enter a base port address into an irq list
	page
;======================================================================
;,fs
; put_ilist - enter a base port address into an irq list
;
; notes: the appropriate icnt and ilist are determined based on the
; irq number supplied in ax.  after the data is stored in the ilist
; the icnt is incremented.
;
; in:	ax = the irq number
;	dx = the address to store in an ilist
;
; out:	
;
;,fe
;=====================================================================
	assume	ds:nothing,es:nothing,ss:nothing
put_ilist proc near
	push	bx
	push	si
	push	di
	mov	bx,offset [icnt2]
	mov	si,offset [ilist2]
	cmp	ax,2
	je	pil01
	add	bx,2
	add	si,maxwks
	cmp	ax,5
	je	pil01
	add	bx,2
	add	si,maxwks
	cmp	ax,7
	je	pil01
	add	bx,2
	add	si,maxwks
	cmp	ax,10
	je	pil01
	add	bx,2
	add	si,maxwks
	cmp	ax,11
	je	pil01
	add	bx,2
	add	si,maxwks
	cmp	ax,12
	je	pil01
	add	bx,2			; must be irq 15
	add	si,maxwks
pil01:
	mov	di,cs:[bx]		; get the icnt
	inc	word ptr cs:[bx]	; increment the icnt
	shl	di,1			; derive and index into the ilist based on icnt
	mov	bx,si
	mov	cs:[bx+di],dx		; and store in the ilist
	pop	di
	pop	si
	pop	bx
	ret
put_ilist endp

	subttl chk_parie - check for a parameter of the type  /xx=
	page
;======================================================================
;,fs
; 
;
; notes: checks for a pair of characters followed by an '=' sign.
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
;=====================================================================
	assume	ds:nothing,es:nothing,ss:nothing
chk_paire proc near
	push	bx
	mov	bx,ax
	cld
	lodsb
	cmp	al,bl
	jne	chp01
	lodsb
	cmp	al,bh
	jne	chp01
	lodsb
	cmp	al,'='			; return with z or nz based on this comparison
chp01:
	pop	bx
	ret
chk_paire endp

	subttl get_vbase - get a vna base address
	page
;======================================================================
;,fs
; get_vbase - get a vna base address
;
; suitable as a type checking procedure for the parsing engine.
; calls hex2word.
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
;=====================================================================
	assume	ds:nothing,es:nothing,ss:nothing
get_vbase proc near
	cmp	byte ptr [si],'/'
	jne	gvb01
	inc	si
	call	hex2word		; let hex2word return ax and nc or cy
	jmp	gvb02
gvb01:
	mov	ax,rc_gerr		; general error return code if no '/'
	stc
gvb02:
	ret
get_vbase endp

	subttl get_irq - get a vna irq parameter
	page
;======================================================================
;,fs
; get_irq - get a vna irq parameter
;
; suitable as a type checking procedure for the parsing engine.
; calls dec2word.
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
;=====================================================================
	assume	ds:nothing,es:nothing,ss:nothing

irq_set db	2,5,7,10,11,12,15,0

get_irq proc near
	call	dec2word
	jc	gti01a
	cmp	ah,0
	je	gti01
gti01a:
	mov	ax,rc_gerr
	stc
	ret
gti01:
	push	si
	lea	si,[irq_set]
	call	cs_testset		; validate the irq
	pop	si
	jz	gti02
	mov	ax,rc_gerr
	stc
	ret
gti02:
	clc
	ret
get_irq endp

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
;=====================================================================
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
;=====================================================================
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

	subttl get_paddr - get a port address parameter
	page
;======================================================================
;,fs
; get_paddr - get a port address parameter
;
; suitable as a type checking procedure for the parsing engine.
; calls hex2word. leaves direction flag set to up.
; checks for a parameter of the type   /ad=hhhh
;
; in:	ds:si -> parameter string to convert
;
; out:	nc if no error
;	 ax = port address
;	 si advanced just past end of parm
;	cy if error
;	 ax = 3 (rc_gerr)
;	 si undefined
;
;,fe
;=====================================================================
	assume	ds:nothing,es:nothing,ss:nothing
get_paddr proc near
	cld
	lodsb
	cmp	al,'/'
	jne	gpd01
	mov	ax,'DA'
	call	chk_paire
	jnz	gpd01
	call	hex2word
	ret				; return with flags and ax from hex2word
gpd01:
	mov	ax,3
	stc
	ret
get_paddr endp

	subttl get_ib - get a parameter of type ib=
	page
;======================================================================
;,fs
; get_ib - get a parameter of type ib=
;
; suitable as a type checking procedure for the parsing engine.
; calls dec2word.  leaves direction flag set to up.
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
;=====================================================================
	assume	ds:nothing,es:nothing,ss:nothing
get_ib proc near
	cld
	mov	ax,'BI'
	call	chk_paire
	jnz	gib01
	call	dec2word
	ret				; return with flags and ax from dec2word
gib01:
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
; calls dec2word. leaves direction flag set to up.
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
;=====================================================================
	assume	ds:nothing,es:nothing,ss:nothing
get_ob proc near
	cld
	mov	ax,'BO'
	call	chk_paire
	jnz	gob01
	call	dec2word
	ret				; return with flags and ax from dec2word
gob01:
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
;=====================================================================
	assume	ds:nothing,es:nothing,ss:nothing

hs_set	db	'NDXPR',0

get_hs proc near
	cld
	mov	ax,'SH'
	call	chk_paire
	jnz	ghs01
	lodsb
	cmp	al,0
	je	ghs01
	push	si
	lea	si,[hs_set]
	call	cs_testset
	pop	si
	jnz	ghs01
	clc
	ret
ghs01:
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
;=====================================================================
	assume	ds:nothing,es:nothing,ss:nothing

cn_set	db	'RLT',0

get_cn proc near
	cld
	mov	ax,'NC'
	call	chk_paire
	jnz	gcn01
	lodsb
	cmp	al,0
	je	gcn01
	push	si
	lea	si,[cn_set]
	call	cs_testset
	pop	si
	jnz	gcn01
	clc
	ret
gcn01:
	mov	ax,3
	stc
	ret
get_cn endp

	subttl get_ms - get a parameter of type /ms=xxxx
	page
;======================================================================
;,fs
; get_ms - get a parameter of type /ms=xxxx
;
; suitable as a type checking procedure for the parsing engine.
; calls hex2word.  leaves direction flag set to up.
; checks for a parameter of the type   /ms=xxxx  (where x= y or n)
;
; in:	ds:si -> parameter string to convert
;
; out:	nc if no error
;	 al = bits from the /ms=xxxx pattern
;	 si advanced just past end of parm
;	cy if error
;	 ax = 3 (rc_gerr)
;	 si undefined
;
;,fe
;=====================================================================
	assume	ds:nothing,es:nothing,ss:nothing

yn_set	db	'YN',0

get_ms proc near
	push	cx
	cld
	lodsb
	cmp	al,'/'
	jne	gms010
	mov	ax,'SM'
	call	chk_paire
	jnz	gms010
	mov	ah,0
	mov	cx,4
gms000:
	lodsb
	push	si
	lea	si,[yn_set]
	call	cs_testset
	pop	si
	jnz	gms010
	shr	ah,1
	cmp	al,'Y'
	jne	gms005
	or	ah,8
gms005:
	loop	gms000
	pop	cx
	mov	al,ah
	clc
	ret				; return with flags and ax from hex2word
gms010:
	pop	cx
	mov	ax,3
	stc
	ret
get_ms endp

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
;=====================================================================
	assume	ds:nothing,es:nothing,ss:nothing

markerr macro	p1, p2			;; p1 is parameter # and p2 is error #
	mov	ax,(&p1 shl 8) + p2
	endm

bl_set	db	'BL',0

parse_exec proc near
	push	ds
	pop	es
	mov	di,si
	mov	cx,0ffffh
	mov	al,13
	repne scasb			; replace the cr terminator with a 0
	mov	byte ptr es:[di-1],0
	call	finddelim
	call	passdelims		; make si point to the first vna base address

; if the first parameter is the /n switch, activate the new bank select
; logic.  this enables > 15/16 workstations.

	mov	[newbank],0
	cmp	word ptr [si],'n/'
	je	donew
	cmp	word ptr [si],'N/'
	jne	prx000
donew:
	mov	[newbank],1
	add	si,2

; process p1 - the vna base address

prx000: 				; processing loop for p1
	mov	bx,offset [class_tbl_p1]; setup cs:bx
	mov	di,offset [parm_type_tbl]
	call	fetch_parm
	jnc	prx005
	cmp	ax,rc_eol		; eol always ok at the 1st parameter
	jne	prx001
	jmp	prxdone
prx001:
	markerr 1,er_inv		; position, else error
	jmp	prxerror
prx005:
	cmp	[nvna],maxwks/4
	jne	prx010
	markerr 1,uer_vnamax
	jmp	prxerror
prx010:
	test	ax,not 03f0h
	jnz	prx011
	cmp	ax,100h
	jnb	prx015
prx011:
	markerr 1,er_inv
	jmp	prxerror
prx015:
	mov	cx,4
	push	bx
	mov	bx,ax
	call	chk_cflt		; check for addressing conflicts
	pop	bx
	jz	prx020
	markerr 1,uer_adrcflt
	jmp	prxerror
prx020:
	mov	di,cs:[nvna]
	inc	cs:[nvna]
	shl	di,1			; derive index into vnaport table
	mov	cs:[di+vnaport],ax	; store the vna base port
	mov	cs:[p1_val],ax		; save for p2 processing

; process p2 - the vna keyboard irq

	mov	di,offset [parm_type_tbl]
	call	fetch_parm
	jnc	prx025
	markerr 2,er_inv
	jmp	prxerror
prx025:
	mov	dx,cs:[p1_val]		; fetch the vna base address
	call	put_ilist		; ax holds the irq number

; process p3 - iona printer base address

	mov	cs:[p3_rc],rc_ok	; clear the return code
	mov	di,offset [parm_type_tbl]
	call	fetch_parm
	jnc	prx045
	cmp	ax,rc_eol
	jne	prx035
	jmp	prxdone
prx035:
	cmp	ax,rc_null
	jne	prx040
	mov	[p3_rc],ax
	jmp	prx047
prx040:
	push	si			; preserve parse pointer
	mov	al,1			; check for type 1  "/hhhh"
	mov	di,offset [parm_type_tbl]
	call	check_type
	pop	si
	jc	prx042			; recycle to the p1 level
	jmp	prx000
prx042:
	markerr 3,er_inv
	jmp	prxerror
prx045:
	mov	cs:[p3_val],ax		; can't fully process p3 until analyze p4

; p4, the b/l designator, is a pc_skip entry in the parameter
; classification table.  calling fetch_parm is only done to advance
; the bx pointer and check for rc_eol and rc_null

prx047:
	mov	di,offset [parm_type_tbl]
	call	fetch_parm		; p4 - b/l designator
	jnc	prx055
	cmp	ax,rc_eol
	jne	prx050
	markerr 4,er_eol
	jmp	prxerror
prx050:

; the return code must be rc_null at this point

	cmp	cs:[p3_rc],rc_null
	jne	prx052
	jmp	prx097
prx052:
	markerr 4,uer_np4wp3		; p4 is null but p3 wasn't
	jmp	prxerror

; got a good return from fetch_parm for p4.  if p3 was null
; where p4 isn't - error.

prx055:
	cmp	cs:[p3_rc],rc_null
	jne	prx060
	markerr 4,uer_np3wp4
	jmp	prxerror
prx060:
	mov	al,[si]
	push	si
	lea	si,[bl_set]		; validate the character
	call	cs_testset
	pop	si
	jz	prx065
	markerr 4,er_inv		; something other than b or l
	jmp	prxerror
prx065:
	mov	ah,al
	inc	si			; advance si explicitly
	mov	al,[si] 		; make sure there's a valid delimiter
	call	testdelims
	jz	prx070
	cmp	al,0
	je	prx070
	markerr 4,er_inv
	jmp	prxerror

; validated b/l designator now in ah and p3_val holds base address
; for the parallel port

prx070:
	mov	cs:[bl_mode],ah
	mov	di,cs:[p3_val]

; for linear mode, parallel base address must be on a 16 byte
; boundary.  must be on a 4 byte boundary for banked mode.

	mov	dx,not 03f0h
	cmp	ah,'B'
	jne	prx075
	mov	dx,not 03fch
prx075:
	test	di,dx
	jnz	prx076
	cmp	di,100h
	jnb	prx080
prx076:
	markerr 3,er_inv
	jmp	prxerror

; if using banked mode, using 03bc for the parallel port address is
; always ok.  otherwise, if the address is not already in the
; prnport table, check for a conflict.	always check for conflicts
; in linear mode.

prx080:
	mov	cx,4			; size factor for linear mode (for chk_cflt)
	cmp	ah,'B'
	jne	prx085
	cmp	di,03bch		; if using banked mode, 03bc is always ok
	je	prx090
	push	es
	mov	ax,di
	mov	di,offset [prnport]
	push	cs
	pop	es
	cld
	mov	cx,maxwks		; else see if this address has already been
	repne scasw			; encountered.
	pop	es

; if yes, must make sure the match is due to a previous banked
; mode allocation rather than a linear one.
; if yes, can skip the check_cflt call.

	jnz	ddi083
	cmp	di,offset [prnpend]
	je	ddi083
	cmp	cs:[di],ax
	je	prx090
ddi083:
	mov	cx,1			; size factor for banked mode
prx085:
	push	bx
	mov	bx,cs:[p3_val]
	call	chk_cflt
	pop	bx
	jnz	prx086
	jmp	prx090
prx086:
	markerr 3,uer_adrcflt
	jmp	prxerror

; now its time to store the port in the prnport table.	for banked
; mode, store the same address for each workstation on a card.
; for linear mode, adjust each address up by 4.

prx090:
	push	bx
	mov	bx,cs:[nvna]
	dec	bx
	mov	cl,3			; derive an index into the prnport table
	shl	bx,cl
	add	bx,offset [prnport]
	mov	dx,cs:[p3_val]
	mov	di,0			; setup adjustment factor for banked mode
	cmp	ah,'L'
	jne	prx095
	mov	di,4			; adj factor for linear mode
prx095:
	mov	cx,4
prx100:
	mov	cs:[bx],dx		; set four entries in the prnport table
	add	bx,2
	add	dx,di
	loop	prx100
	pop	bx

; process p5 - iona serial base address.

prx097:
	mov	di,offset [parm_type_tbl]
	call	fetch_parm
	jnc	prx110

; not worrying about the possiblity of a
; null p3 and p4 and then an eol

	cmp	ax,rc_eol
	jne	prx098
	jmp	prxdone
prx098:
	cmp	ax,rc_null
	jne	prx105
	markerr 5,er_nonull
	jmp	prxerror
prx105:
	push	si			; preserve parse pointer
	mov	al,1			; check for type 1  "/hhhh"
	mov	di,offset [parm_type_tbl]
	call	check_type
	pop	si
	jc	prx111
	jmp	prx000			; recycle to the p1 level
prx111:
	markerr 5,er_inv
	jmp	prxerror
prx110:
	test	ax,not 03e0h
	jnz	prx112
	cmp	ax,100h
	jnb	prx115
prx112:
	markerr 5,er_inv
	jmp	prxerror
prx115:
	mov	cx,8
	push	bx
	mov	bx,ax
	call	chk_cflt		; check for address conflicts
	pop	bx
	jz	prx120
	markerr 5,uer_adrcflt
	jmp	prxerror
prx120:
	push	bx
	mov	bx,cs:[nvna]
	dec	bx
	shl	bx,1			; derive an index for serbase
	mov	cs:[bx+serbase],ax	; store it in serbase for later initiaization
	pop	bx
	mov	cs:[p5_val],ax		; save for use in p7 also

; process p6 - iona serial irq

	mov	di,offset [parm_type_tbl]
	call	fetch_parm
	jnc	prx135
	cmp	ax,rc_eol
	jne	prx123
	jmp	prxdone
prx123:
	cmp	ax,rc_null
	jne	prx125
	markerr 6,er_nonull
	jmp	prxerror
prx125:
	push	si			; preserve parse pointer
	mov	al,1			; check for type 1  "/hhhh"
	mov	di,offset [parm_type_tbl]
	call	check_type
	pop	si
	jc	prx127
	jmp	prx000			; recycle to the p1 level
prx127:
	push	si			; preserve parse pointer
	mov	al,9			; check for type 9 "/MS=xxxx"
	mov	di,offset [parm_type_tbl]
	call	check_type
	pop	si
	jc	prx128
	jmp	prx285			; advance to the p9 level
prx128:
	markerr 6,er_inv		; invalid parm
	jmp	prxerror
prx135:
	push	bx
	mov	bx,cs:[nvna]
	dec	bx
	shl	bx,1			; derive an index for vnaport and serbase
	mov	dx,cs:[bx+vnaport]
	pop	bx
	or	dx,8000h		; set high bit to distinguish from vna ports
	call	put_ilist		; ax holds the irq number
	mov	cs:[p6_val],ax		; save for p7 processing

; process p7 - iona serial port address

	mov	cs:[p7_count],0
	mov	cs:[p7_cflt],0
prx145:
	mov	cs:[p7_rc],rc_ok	; clear the return code
	mov	bx,offset [class_tbl_p7]; reset cs:bx for another p7
	mov	di,offset [parm_type_tbl]
	call	fetch_parm
	jnc	prx165
	cmp	ax,rc_eol		; if p6 specified, must have
	jne	prx150
	cmp	cs:[p7_count],0 	; at least one p7
	je	prx146
	jmp	prxdone
prx146:
	markerr 7,er_eol
	jmp	prxerror
prx150:
	cmp	ax,rc_null
	jne	prx155
	markerr 7,er_nonull
	jmp	prxerror
prx155:
	cmp	cs:[p7_count],0
	je	prx160
	push	si			; preserve parse pointer
	mov	al,1			; check for type 1  "/hhhh"
	mov	di,offset [parm_type_tbl]
	call	check_type
	pop	si
	jc	prx156
	jmp	prx000			; recycle to the p1 level
prx156:
	push	si			; preserve parse pointer
	mov	al,9			; check for type 9 "/MS=xxxx"
	mov	di,offset [parm_type_tbl]
	call	check_type
	pop	si
	jc	prx160
	jmp	prx285			; advance to the p9 level
prx160:
	markerr 7,er_inv
	jmp	prxerror
prx165:
	cmp	cs:[p7_count],4 	; check for too many /ad='s
	jne	prx170
	markerr 7,uer_sermax
	jmp	prxerror
prx170:
	inc	cs:[p7_count]
	mov	dx,cs:[p5_val]		; validate p7 against base address
	mov	cl,1			; init bit mask for p7_clft
	cmp	ax,dx			; same as base?
	je	prx175
	add	dx,8
	mov	cl,2
	cmp	ax,dx			; base+8?
	je	prx175
	add	dx,8
	mov	cl,4
	cmp	ax,dx			; base+10h?
	je	prx175
	add	dx,8
	mov	cl,8
	cmp	ax,dx			; base+18?
	je	prx175
	markerr 7,er_inv
	jmp	prxerror

; check for duplicate port address

prx175:
	test	cs:[p7_cflt],cl
	jz	prx177
	markerr 7,uer_adrcflt
	jmp	prxerror
prx177:
	or	cs:[p7_cflt],cl

; p7 now fully validated - time to update port table

	mov	di,cs:[numport] 	; need port-1 for calcs
	inc	cs:[numport]
	mov	cl,5			; port table size = 32 bytes
	shl	di,cl			; derive index into port table
	add	di,offset [porttbl]
	push	ax			; store for phy2log update
	or	ax,8000h
	mov	cs:[di].addr,ax 	; store the port's address
	mov	ax,cs:[p6_val]
	mov	cs:[di].prtirq,al	; store the port's irq
	mov	cs:[portndx],di 	; save port table index for p8 processing

; now time to update entry in the phy2log table which is used
; as a fast index in the irq handler to determine the logical
; port number given an iona board number and interrupt level.
; index derivation:  ((nvna - 1) * 8) + ((p7_val - p5_val) shr 2))

	mov	ax,cs:[nvna]
	dec	ax
	mov	cl,3
	shl	ax,cl			; derive major index into phy2log
	pop	bx			; push'ed as ax - p7's value
	sub	bx,cs:[p5_val]
	shr	bx,1
	shr	bx,1			; derive minor index
	add	bx,ax
	mov	cs:[phy2log+bx],di

; process p8 - iona serial port options
; note: di is expected to contain the port table index

	cmp	[numport],1
	jne	prx180

; explicitly set default parameters on first entry

	mov	cs:[di].ibfsiz,16	; use small buffer default size since
	mov	cs:[di].obfsiz,16	; mouse usage is most likely
	mov	cs:[di].ioprot,0
	mov	cs:[di].xoffch,0
	mov	cs:[di].xonch,0
	jmp	prx185

; copy default parameters from previous port table entry.
; this will make any specifications become the new default.

prx180:
	push	si
	mov	si,di
	sub	si,32
	mov	ax,cs:[si].ibfsiz
	mov	cs:[di].ibfsiz,ax
	mov	ax,cs:[si].obfsiz
	mov	cs:[di].obfsiz,ax
	mov	al,cs:[si].ioprot
	mov	cs:[di].ioprot,al
	mov	al,cs:[si].xoffch
	mov	cs:[di].xoffch,al
	mov	al,cs:[si].xonch
	mov	cs:[di].xonch,al
	pop	si
prx185:
	mov	cs:[p8a_once],0
	mov	cs:[p8b_once],0
	mov	cs:[p8c_once],0
	mov	cs:[p8d_once],0
prx190:
	mov	bx,offset [class_tbl_p8]; reset cs:bx for secondary p8
	mov	di,offset [parm_type_tbl]
	call	fetch_parm
	jnc	prx205
	cmp	ax,rc_eol
	jne	prx195
	jmp	prxdone
prx195:
	cmp	ax,rc_null
	jne	prx200
	markerr 8,er_nonull
	jmp	prxerror
prx200:
	push	si			; preserve parse pointer
	mov	al,1			; check for type 1  "/hhhh"
	mov	di,offset [parm_type_tbl]
	call	check_type
	pop	si
	jc	prx201
	jmp	prx000			; recycle to the p1 level
prx201:
	push	si			; preserve parse pointer
	mov	al,4			; check for type 4  "/AD=hhhh"
	mov	di,offset [parm_type_tbl]
	call	check_type
	pop	si
	jc	prx202
	jmp	prx145			; recycle to the p7 level
prx202:
	push	si			; preserve parse pointer
	mov	al,9			; check for type 9 "/MS=xxxx"
	mov	di,offset [parm_type_tbl]
	call	check_type
	pop	si
	jc	prx203
	jmp	prx285			; advance to the p9 level
prx203:
	markerr 8,er_inv
	jmp	prxerror

; cx holds the element number of the group member which matched

prx205:
	mov	di,cs:[portndx]
	cmp	cx,1			; p8a	ib=
	jne	prx220
	cmp	cs:[p8a_once],0
	je	prx210
	markerr 9,uer_ibmax
	jmp	prxerror		; more than one p8a per port
prx210:
	cmp	ax,16
	jnb	prx215
	markerr 9,uer_iblow
	jmp	prxerror		; input buffer must be at least 16 bytes
prx215:
	mov	cs:[p8a_once],1
	mov	cs:[di].ibfsiz,ax
	jmp	prx190
prx220:
	cmp	cx,2			; p8b	ob=
	jne	prx235
	cmp	cs:[p8b_once],0
	je	prx225
	markerr 10,uer_obmax
	jmp	prxerror		; more than one p8b per port
prx225:
	cmp	ax,16
	jnb	prx230
	markerr 10,uer_oblow
	jmp	prxerror		; output buffer must be at least 16 bytes
prx230:
	mov	cs:[p8b_once],1
	mov	cs:[di].obfsiz,ax
	jmp	prx190
prx235:
	cmp	cx,3			; p8c	hs=
	jne	prx265
	cmp	cs:[p8c_once],0
	je	prx240
	markerr 11,uer_hsmax
	jmp	prxerror		; more than one p8c per port
prx240:
	mov	cs:[p8c_once],1
	cmp	al,'N'
	jne	prx245
	and	cs:[di].ioprot,0f0h	; clear flags
	jmp	prx190
prx245:
	cmp	al,'R'
	jne	prx250
	or	cs:[di].ioprot,8	; enable rts
	jmp	prx190
prx250:
	cmp	al,'D'
	jne	prx255
	or	cs:[di].ioprot,4	; enable dtr
	jmp	prx190
prx255:
	cmp	al,'X'
	jne	prx260
	or	cs:[di].ioprot,3	; enable xon/off for xmit and recv
	mov	cs:[di].xoffch,13h
	mov	cs:[di].xonch,11h
	jmp	prx190
prx260:

; al must be 'P'

	or	cs:[di].ioprot,3	; enable xon/off for xmit and recv
	mov	cs:[di].xoffch,67h
	mov	cs:[di].xonch,65h
	jmp	prx190

; cx must be 4 (p8d)  cn=

prx265:
	cmp	cs:[p8d_once],0
	je	prx270
	markerr 12,uer_cnmax
	jmp	prxerror		; more than one p8d per port
prx270:
	mov	cs:[p8d_once],1
	cmp	al,'L'
	jne	prx275
	and	cs:[di].ioprot,not 30h	; conteract any r or t
	jmp	prx190
prx275:
	cmp	al,'R'
	jne	prx280
	or	cs:[di].ioprot,10h	; set carrier monitor bit
	jmp	prx190
prx280:

; must be 'T'

	or	cs:[di].ioprot,30h	; set carrier monitor and report bits
	jmp	prx190

; enter here when fail to match on another p7 or p8 but do
; match on a p9.  this is the code for the /ms= option.

prx285:
	mov	bx,offset [class_tbl_p9]; must setup cs:bx for p9 since
	mov	di,offset [parm_type_tbl]  ; could enter here from p7
	call	fetch_parm
	jnc	prx300
	cmp	ax,rc_null
	jne	prx290
	markerr 13,er_nonull
	jmp	prxerror
prx290:
	cmp	ax,rc_eol
	jne	prx295
	jmp	prxdone

; ax must be rc_gerr

prx295:
	push	si			; preserve parse pointer
	mov	al,1			; check for type 1  "/hhhh"
	mov	di,offset [parm_type_tbl]
	call	check_type
	pop	si
	jc	prx296
	jmp	prx000			; recycle to the p1 level
prx296:
	markerr 13,er_inv
	jmp	prxerror

; no error for p9 - al holds a bit map

prx300:
	mov	bx,[nvna]
	dec	bx			; derive index to the modem_sig array
	shl	bx,1			; based on the card number
	shl	bx,1			; (al has one bit per board relative wks)
	mov	cx,4
prx305:
	shr	al,1			; shift the low bit into the carry flag
	jnc	prx310
	mov	byte ptr [modem_sig+bx],'Y'
prx310:
	inc	bx
	loop	prx305
	jmp	prx000

; error termination handler
; at this point, al holds the error # and ah is the parameter position
; display parameter postition message,	call report_error (to display
; error type) and  set cy flag

prxerror:
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
	add	bx,offset [parm_msg_tbl]
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

; normal termination handler

prxdone:
	push	cs
	push	cs
	pop	ds
	pop	es
	cmp	[nvna],0
	jne	prxd01

; setup for default parameters

	mov	[vnaport],0240h
	mov	ax,offset [irqpack]
	mov	[ipntr7],ax
	mov	[irqpack],0240h
	mov	[icnt7],1
	mov	[nvna],1
	jmp	short prxd02

; pack ilist data into irqpack and set ipntr's

prxd01:
	lea	di,[irqpack]
	lea	si,[ilist2]
	mov	[ipntr2],di
	mov	cx,[icnt2]
	rep	movsw
	lea	si,[ilist5]
	mov	[ipntr5],di
	mov	cx,[icnt5]
	rep	movsw
	lea	si,[ilist7]
	mov	[ipntr7],di
	mov	cx,[icnt7]
	rep	movsw
	lea	si,[ilist10]
	mov	[ipntr10],di
	mov	cx,[icnt10]
	rep	movsw
	lea	si,[ilist11]
	mov	[ipntr11],di
	mov	cx,[icnt11]
	rep	movsw
	lea	si,[ilist12]
	mov	[ipntr12],di
	mov	cx,[icnt12]
	rep	movsw
	lea	si,[ilist15]
	mov	[ipntr15],di
	mov	cx,[icnt15]
	rep	movsw
prxd02:
	clc
	ret
parse_exec endp

	subttl initvna - vna board initialization
	page
;======================================================================
;,fs
; initvna - vna board initialization
;
; initialize all ws's for one vna board
;
; in:	bl = starting ws number for board
;	cl = number of ws's to init for board
;	dx = base address of vna board
;
; out:	
;
;,fe
;=====================================================================
	assume	ds:nothing,es:nothing,ss:nothing
initvna proc near
	push	cx
initv1:
	push	dx
	push	cx
	push	bx
	mov	al,4
	sub	al,cl			; so ws0 is skipped if init'ing 3 only
	add	al,bl			; starting bank number
	call	setws
	call	setmono
	pop	bx
	pop	cx
	pop	dx
	loop	initv1
initv2:
	pop	cx
	push	dx
	inc	dx			; start at base+1
initv3:
	mov	al,80h			; reset irq flag/disable kyb, clk low
	out	dx,al
	jmp	$+2
	mov	al,0c0h
	out	dx,al
	jmp	$+2
	add	dx,2			; skip to next wks
	loop	initv3
	pop	dx
	mov	al,3			; enable workstations and kb ints
	add	dl,0ch
	out	dx,al
	ret
initvna endp

	subttl setmono - init video controller
	page
;======================================================================
;,fs
; setmono - init video controller
;
; initializes one video controller to monochrome mode
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

setmono proc near
	push	es
	push	ds
	push	si
	push	cs
	pop	ds
	mov	si,offset monotbl
	mov	al,0			; disable graphics and page 1
	mov	bx,0720h		; value to clear
	mov	cx,80*25		; words to clear
	mov	dx,3bfh
	out	dx,al			; enable graphics, disable page 1
	mov	dx,03b8h
	lodsb
	out	dx,al			; setting new mode, but turning off 6845
	mov	ah,00h
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
	rep	stosw
	mov	dx,03b8h
	lodsb
	out	dx,al			; turn 6845 on in new mode
	pop	si
	pop	ds
	pop	es
	ret
setmono endp

	subttl initpic - init 8259's and irq vector
	page
;======================================================================
;,fs
; initpic - init 8259's and irq vector
;
; in:	al = irq to init
;	bx = [ilist?]
;	cx = [icnt?]
;
; out:	crashes ax, bx, cx, dx, di
;
;,fe
;=====================================================================
	assume	ds:nothing,es:nothing,ss:nothing

irqtbl	dw	0,0,irq2_entry,0,0,irq5_entry,0,irq7_entry
	dw	0,0,irq10_entry,irq11_entry,irq12_entry,0,0,irq15_entry

initpic proc near
	push	ax
ipc01:
	mov	dx,cs:[bx]		; get the base address from the irqpack list
	add	bx,2
	test	dx,8000h		; high bit set for an iona base address
	jz	ipc02

; setup an iona 8259

	and	dx,7fffh		; strip off high bit
	add	dx,0eh			; address the first iona 8259 register
	mov	al,00010011b		; icw1 - need icw4, single, edge triggered
	out	dx,al
	jmp	$+2
	add	dx,1000h		; address the second iona 8259 register
	mov	al,00000000b		; icw2 - interrupt type 0
	out	dx,al
	jmp	$+2			; (skipping icw3)
	mov	al,00001001b		; icw4 - select 8086, buffered slave
	out	dx,al
	jmp	$+2
	mov	al,01110000b		; if not at end of a chain, enable ir's for
	cmp	cx,1			; serial ports and the next 8259 in the chain
	jne	ipc03
	mov	al,11110000b		; else, just enable ir's for serial ports
ipc03:
	out	dx,al
	jmp	$+2
	mov	al,20h			; issue an eoi
	sub	dx,1000h
	out	dx,al
	jmp	ipc05

; setup a vna 8259

ipc02:
	add	dx,8			; address the first vna 8259 register
	mov	al,00010011b		; icw1 - need icw4, single, edge triggered
	out	dx,al
	jmp	$+2
	inc	dx			; address the second iona 8259 register
	mov	al,00000000b		; icw2 - interrupt type 0
	out	dx,al
	jmp	$+2			; (skipping icw3)
	mov	al,00001001b		; icw4 - select 8086, buffered slave
	out	dx,al
	jmp	$+2
	mov	al,10111111b		; if not at end of a chain, enable the
	cmp	cx,1			; ir for the next 8259 in the chain
	jne	ipc04
	mov	al,11111111b		; else, enable none
ipc04:
	out	dx,al
	jmp	$+2
	mov	al,20h			; issue an eoi
	dec	dx
	out	dx,al
ipc05:
	loop	ipc01
	pop	ax
	cmp	al,8
	jnb	ipc06

; setup primary main board 8259 and vector

	mov	cl,al
	mov	bl,al
	mov	bh,0
	shl	bx,1
	mov	di,irqtbl[bx]
	shl	bx,1
	add	bx,8*4			; derive offset of vector
	push	ds
	xor	ax,ax
	mov	ds,ax
	mov	word ptr ds:[bx],di	; plug the vector
	mov	word ptr ds:[bx+2],cs
	pop	ds
	mov	ah,1
	shl	ah,cl
	not	ah
	in	al,21h
	and	al,ah			; mask enable the irq
	out	21h,al
	jmp	ipc07

; setup both main board 8259's and vector

ipc06:
	sub	al,8			; when working with >= irq8, must program
	mov	cl,al			; the 2nd main board 8259
	mov	bl,al
	mov	bh,0
	shl	bx,1
	mov	di,irqtbl[bx+8*2]
	shl	bx,1
	add	bx,70h*4
	push	ds
	xor	ax,ax
	mov	ds,ax
	mov	word ptr ds:[bx],di	; plug the vector
	mov	word ptr ds:[bx+2],cs
	pop	ds
	mov	ah,1
	shl	ah,cl
	not	ah
	in	al,0a1h
	and	al,ah			; set mask for 8259 #2
	out	0a1h,al
	in	al,21h
	and	al,not 2		; set mask for 8259 #1
	out	21h,al
ipc07:
	ret
initpic endp

	subttl set_cntr - initialize iona's 8253 timer/counters
	page
;======================================================================
;,fs
; set_cntr - initialize iona's 8253 timer/counters
;
; in:	al = byte for control register
;	dx = address of control register
;	si = offset of data register from control register
;	cx = data word to write
;
; out:	dx restored to control register
;	al crashed
;
;,fe
;=====================================================================
	assume	ds:nothing,es:nothing,ss:nothing
set_cntr proc near
	out	dx,al			; write to control register
	jmp	$+2
	sub	dx,si			; use a one shot down count of 900 hz
	mov	al,cl			; lsb
	out	dx,al
	jmp	$+2
	mov	al,ch			; msb
	out	dx,al
	jmp	$+2
	add	dx,si			; back to control register
	ret
set_cntr endp

code	ends
	end

