	include page.inc
	title	vgna.asm - vgna (video graphics network adapter)

true	equ	1 eq 1
false	equ	1 eq 0
mono	equ	0

comment ^===============================================================
		       development specification

 program name:	vgna.asm			assigned to: stewart hyde
 module name:	vgna				assign date: 09/06/89
 entry points:	vgnaterm			completed:   10/11/89
 entry from:	mosint10, mosint16, mosvidrm
 entry method:	call dword [vector] with ah = function number
 calls: 	i10old (boot interrupt 10h)
 purpose:	mos interface to ali vgna
 refer to:	n/a
 last update:	03/29/91
========================================================================

sah 02/08/90	correction for 33mhz ami machine (fast)

mjs 05/09/90	added the clr_set_irq dummy function.  it is called by
		int14fun11 within int14.inc (only needed by _serial.asm)

sah 06/25/90	corrections for non-(ega\vga) stations can pamswitch.

sah 07/19/90	corrections for faster machines (486 and 33mhz 386's)

sah 08/06/90	added logic to init serial ports and pics

mjs 08/13/90	modified to use vidchk.inc and a boot_prep function.

sah 01/04/91	implement vna+ corrected keyboard logic inside vgna

sah 03/29/91	added 40:17 support for 4.11 release

mjs 05/24/91	added printer status function.  cleaned up module.

=======================================================================^

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

stall	macro
	mov	cx,-1
	loop	$
	mov	cx,-1
	loop	$
	endm

.list

code	segment para public 'data'	; to force loading with data
	assume	cs:code,ds:nothing,es:nothing,ss:nothing

	include vgna.pub

ddtvga	equ	this byte
	dd	-1			; filled in with pointer to next driver
	dw	8000h			; signifying a character device
	dw	strat			; device strategy entry point
	dw	inter			; device interrupt entry point
vgnanm	db	'$$VGNA  '		; device name

enddrvr0 equ	$

request dd	0

infoofs dw	offset	vgnainfo ; offset to start of vgna driver

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
	mov	ax,0100h
	les	bx,[request]
	mov	si,es:[bx+2]
	and	si,0ffh
	or	si,si
	jnz	inter0
	call	ddtinit
	jmp	short inter1
inter0:
	cmp	si,4
	jne	inter1
	lds	si,es:[bx+14]
	mov	cx,es:[bx+18]
	mov	word ptr es:[bx+18],0	; nothing read if error
	mov	ax,8103h		; error, done, unknown command
	cmp	cx,4
	jne	inter1			; if not reading exactly 4 bytes
	mov	es:[bx+18],cx		; else read 4 bytes
	mov	word ptr ds:[si],offset vgaterm  ; and these are them
	mov	ds:[si+2],cs
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

	subttl termfn - all the terminal and keyboard functions for mos
	page

tfn	dw	register
	dw	inkbdata
	dw	outkbctl
bgnvid	equ	($-tfn)/2
	dw	0			; setmode
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

; after parameters have been validated (during initialization), the base
; addresses for each vgna card are copied into irppack.  the ipntr?
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

; vgna base addresses are recorded in irqpack.	iona base addresses
; have their high bit set.  the irq handler accesses the entries in
; this list through the appropriate ipntr? and icnt? variables.

irqpack dw	8 dup(?)

; misc vgna variables

scbptr	label	dword
scbofs	dw	0			; offset of scb
scbseg	dw	0			; segment of scb
mcdcbios db	0			; a copy of the foreground's dcbios
ddtmc	dd	0			; address of master console ddt entry
vgnacur db	-1			; who is currently banked in
vgnaunreg dd	8 dup (0)		; prevous un-register calls
saveds	dw	0
savebx	dw	0
savevid dw	0
savevram db	0
off10	dw	0			; original int 10 offset
seg10	dw	0			; original int 10 segment

; one key buffer for each workstation

kbsize	equ	32			; 32 scan codes buffered

; there are several spots within this driver hard-coded to expect this
; keyboard size.  they don't all reference the size through kbsize either.

if kbsize ne 32
	%out	kb buffer size wrong for shift count
endif

;-----------------------------------------------------------------------
; vgna information packet - use to display information externally by
; vgna.exe which is use to print out this information after driver has
; be loaded.

; offset     size   name	   description
;-----------------------------------------------------------------------
;  00h	     2	    nvgna	   # of vgna base ports
;  02h	     4*2    vgnaport	   array of port use by system
;  0ah	     4*2    vgnairq	   array of irq use by system
;  12h	     2	    numport	   total # of serial ports declared
;  14h	     8*2    vgnatcb	   array of tcb use on system (-1 n/a)
;  24h	     1	    ws0ismc	   y is workstation 0 is master console
;	     1	    filler
;  26h	     8*2    kbget	   array of keyboard get pointers
;  36h	     8*2    kbput	   array of keyboard put pointers
;  46h	     8	    keyrdy	   array of keyboard ready flags
;  46h	     8*32   kby 	   array of 32 byte keyboard buffers
; 14eh	     2	    sportofs	   offset to port table information
; 150h	     2	    seroff	   offset to serport
;-----------------------------------------------------------------------
	even
vgnainfo label	word
nvgna	dw	0			; total number of vgna base ports
vgnaport dw	4 dup(0)		; vgna base addresses
vgnairq  dw	4 dup(0)		; irq associated with each vgna base address
numport dw	0			; total number of serial ports declared
vgnatcb dw	8 dup (-1)		; register tcbs
ws0ismc db	'Y'			; 'N' if master console not workstation 0
	db	0
kbget	dw	8 dup(0)
kbput	dw	8 dup(0)
keyrdy	db	8 dup(0)
kbf	db	8*kbsize dup(0)
sportofs dw	offset porttbl
seroff	dw	offset serport
spaoff	dw	offset spoff
kbstat	db	8 dup(0)
kbport	dw	8 dup (0)		; keyboard port for each station
kbbios	db	'N'			; is kbbios set

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
	cmp	al,[vgnacur]
	jne	setws1
	ret
setws1:
	cmp	[ws0ismc],'Y'		; is ws 0, vgna
	je	setwstation		; if so then no need to full with
					; 46e8h register

; co-existence with paradise vga need special handling
; if switching to vgna station, you will need to
;  1.  switch master console out (46e8h)
;  2.  switch work station in (set bank)
; if switching to master console, you will need to
;  1.  switch all work stations out (set bank to non station)
;  2.  switch master console in (46e8h)
;
; special notes:
;  while work station is in, we must make sure that
;  master console does not get switch in. we must handle
;  port 46e8h specially.

	or	al,al
	jz	setmc			; if 0, then switch in master console

; switch in work station

	push	ax
	push	dx
	mov	al,0fh
	call	setwstation		; set master console
	mov	al,06h			; this is the value we send to 46e8h
	mov	dx,46e8h
	out	dx,al
	pop	dx
	pop	ax
	call	setwstation		; set bank
	ret

; switch out all work stations

setmc:
	call	setwstation		; set bank
	push	ax
	push	dx
	mov	al,0eh			; this is the value we send to 46e8h
	mov	dx,46e8h
	out	dx,al
	pop	dx
	pop	ax
	ret

; set work station - actuall routine to set bank

setwstation:
	push	dx
	push	cx
	push	bx
	mov	bx,offset vgnaport
	mov	cx,[nvgna]
setws4:
	mov	dx,cs:[bx]
	add	dl,0fh
	out	dx,al
	add	bx,2
	loop	setws4
	mov	[vgnacur],al
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
	assume	ds:nothing,es:nothing,ss:nothing
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

	subttl vgnaterm - entry point for ddt calls
	page
;======================================================================
;,fs
; vgnaterm - entry point for ddt calls
;
; off to master console ddt if
;   workstation 0 and master console is workstation 0
;   or if a video function
; else handle it in vgna ddt
;
; in:	
;
; out:	
;
;,fe
;=====================================================================
	assume	ds:nothing,es:nothing,ss:nothing
	db	'VGA'
vgaterm proc far

; 0feh is a special function to switch out all vgna's (co-resident case)
; this logic switches in workstation 15
; since vgna only has a max of 8 vgna's, switching in workstation 15
; will switch out all vgna's, and if master console isn't vgna, this
; will allow access to master console vga card

	cmp	ah,0feh
	jne	vgnafj00
	mov	al,0fh
	pushf
	cli
	call	setws
	popf
	jmp	vgnafnx

; 0ffh is a special function to bank in a workstation

vgnafj00:
	cmp	ah,0ffh
	jne	vgnafn1
	call	bankin

; now, call ddtmc's ff handler to insure that the video display ram is exposed

	push	di
	push	es
	les	di,[scbptr]
	call	ddtmc			; ah should still be 0ffh
	pop	es
	pop	di
	jmp	vgnafnx

; for all video functions - pass the call onto ddtmc
; also, pass to ddtmc when not a video function but the port is 0 and the
; master console is a vgna workstation
; otherwise, process locally

; one exception is when a 7 is written to function 0a and an iona card is
; installed.  if the beep call vector isn't even pointing to the beep procedure
; then skip ahead.  also skip if dealing with the master console.

vgnafn1:
	cmp	ah,endtfn
	jae	vgnafn3a
	cmp	ax,0a07h		; is this beep
	jne	vgnafn1a
	cmp	byte ptr [si].port,0	; if not master console - ignore it
	jne	vgnafnx
vgnafn1a:
	cmp	ah,bgnvid
	jb	vgnafn2
	cmp	ah,endvid
	jb	vgnafn3
vgnafn2:
	cmp	[ws0ismc],'Y'
	jne	vgnafn4 		; ws0 not master console
	cmp	byte ptr [si].port,0
	jne	vgnafn4 		; not ws0
	cmp	ah,10h
	je	vgnafn4 		; the print routines are an except - so
	cmp	ah,11h			; the master console could used an vgna
	je	vgnafn4 		; parallel port if desired.

; process a video function

vgnafn3:
	cmp	ah,4			; for set cursor type or set cursor
	je	vgnafn3a		; position, must bank in the right
	cmp	ah,5			; workstation first
	jne	vgnafn3b
vgnafn3a:
	call	bankin
vgnafn3b:
	push	si
	call	ddtmc			; when ddtmc calls exposreal, the
	pop	si			; ddt function ff which will come back
	jmp	vgnafnx 		; to this ddt first

; process non-video functions locally

vgnafn4:
	push	bp
	mov	bp,bx
	mov	bl,ah
	cmp	bl,endtfn
	jae	vgnafn5
	xor	bh,bh
	shl	bx,1
	xchg	bx,bp
	push	ds
	push	si
	call	tfn[bp]
	pop	si
	pop	ds
vgnafn5:
	pop	bp
vgnafnx:
	ret
vgaterm endp

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
	cmp	[ws0ismc],'Y'
	je	reg0a
	dec	bl
reg0a:

; check to see if task has allready been register
; if so return error

	xor	bh,bh
	shl	bx,1
	cmp	word ptr [vgnatcb+bx],-1
	je	reg0b
	jmp	regsx
reg0b:
	mov	[saveds],ds		; save pointer to tcb
	mov	[savebx],bx		; save port pointer for later
	mov	[si].dcpherc,'N'
	mov	[si].dcpcrs,25*256
	mov	[si].dcpcol,80
	mov	[si].dcpscrl,80*25*2
	mov	[si].dcbios,1
	mov	[si].dcsnow,0
	mov	cx,4
	mov	[si].dcmode,3
	mov	[si].dcvmode,3
	mov	[si].dcaddr,03d4h
	mov	[si].dcpscr,0b800h
	mov	[savevid],0b800h
	mov	[savevram],0ech

if mono
	mov	al,byte ptr [si].port
	call	chkmono 		; check if mono station
	jnc	regs0
	mov	[si].dcmode,7
	mov	[si].dcvmode,7
	mov	[si].dcaddr,03b4h
	mov	[si].dcpscr,0b000h
	mov	[savevid],0b000h
	mov	[savevram],08ch
endif

regs0:
	push	ds
	push	si
	push	cx
	xor	bx,bx
	mov	al,byte ptr [si].port
	cmp	[ws0ismc],'Y'
	je	reg0c
	dec	al
reg0c:
	mov	bl,al
	and	bx,not 1		; derive the board number from the
	shr	bx,1			; port number
	and	ax,1
	push	cs
	pop	ds

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
	mov	word ptr [vgnatcb+bx],ds; register task
	push	cs
	pop	es
	shl	bx,1
	lea	si,tcbunreg		; save current tcbunreg
	lea	di,vgnaunreg
	add	di,bx
	cld
	movsw
	movsw
	lea	ax,unregister		; set our unregister call
	mov	word ptr [tcbunreg],ax
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
	mov	al,[savevram]		; graphics and mc and ali
	mov	cx,[savevid]		; physical buffer address (stuffed into
	ret				;   tcbvidad)
register endp 

if mono

	subttl chkmono - check if mono station
	page
;======================================================================
;,fs
; chkmono - check if mono station
;
; check system hardware to check if station is mono vga
;
; in:	al = station to set
;
; out:	return carry if station is color
;
;,fe
;=====================================================================
	assume	ds:nothing,es:nothing,ss:nothing
chkmono proc near
	mov	ah,[vgnacur]
	push	ax
	call	setws			; switch station in
	push	dx
	mov	dx,3ceh 		; get options bits from card
	mov	al,0fh
	out	dx,al
	jmp	$+2
	inc	dx
	in	al,dx
	test	al,40h			; is bit 2 set
	jnz	mono
	clc
	jmp	short monoout
mono:
	stc
monoout:
	pop	dx
	pop	ax			; get current station
	mov	al,ah
	pushf
	call	setws			; set back to current
	popf
	ret
chkmono endp

endif

	subttl initbios - call vga bios bootstrap function
	page
;======================================================================
;,fs
; initbios - call vga bios bootstrap function
;
; int vector must be saved and restored because the vga 
; bios will initialize the vertor.
;
; note for co-existence with paradise vga card as master console, master
; console screen will flicker and clear when this routine is called
; and this routine is call at device driver init time.
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
	push	es
	xor	ax,ax
	mov	es,ax
	mov	ax,word ptr es:[10h*4]
	mov	cs:[off10],ax
	mov	ax,word ptr es:[10h*4+2]
	mov	cs:[seg10],ax
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
	sti
	pop	es
	popa
	ret
initbios endp

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
;=====================================================================
	assume	ds:nothing,es:nothing,ss:nothing
boot_prep proc near
	xor	ax,ax			; switch forground in
	call	setws
	ret
boot_prep endp 

	subttl keybd - process a vgna keyboard irq
	page
;======================================================================
;,fs
; keybd - process a vgna keyboard irq
;
; keybd - this is the stations keyboard handler, it will put the
; the key scan codes into the driver 32 byte keyboard buffer in
; task information table.
;
; in:  di = points to vgna data structure
;      dx = points to keyboard control register	
;
; out:	
;
;,fe
;=====================================================================
	assume	ds:nothing,es:nothing,ss:nothing
keybd proc near
	push	bx
	push	dx
	and	dx, 0fff0h
	mov	bx,offset [vgnaport]	; first need to determine the board number
	cmp	[bx],dx 		; check each vgnaport entry for a match
	je	keybd1
	add	bx,2
	cmp	[bx],dx 		; check each vgnaport entry for a match
	je	keybd1
	add	bx,2
	cmp	[bx],dx 		; check each vgnaport entry for a match
	je	keybd1
	add	bx,2
	cmp	[bx],dx 		; check each vgnaport entry for a match
	je	keybd1
	add	bx,2
keybd1:
	sub	bx,offset [vgnaport]	; derive a major index into serport array
	pop	dx
	add	di,bx
	mov	cx,08000h
kbd1:
	in	al,dx
	test	al,1			; input ready?
	loopz	kbd1
	dec	dx
	in	al,dx			; get data
	inc	dx
	cmp	al,0feh 		; resend
	je	kbd2
	cmp	al,0fah 		; achnolodge
	jne	kbd3

; do keyboard achnolodge

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
	push	si
	mov	si,word ptr [di].kbget
	cmp	si,word ptr [di].kbput	; overflow in buffer
	pop	si
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
; in:	
;
; out:	
;
;,fe
;=====================================================================
	assume	ds:nothing,es:nothing,ss:nothing
doleds proc near
	push	ax
	push	es
	mov	es,word ptr [di].vgnatcb; get tcb for station
	assume	es:tcb
	mov	al,tcbkshft		; get keyboard status
	pop	es
	assume	es:nothing
	call	setleds 		; call lowlevel 40:17 stuff
	pop	ax
	ret
doleds endp

	subttl setleds - lowlevel 40:17 support
	page
;======================================================================
;,fs
; setleds - lowlevel 40:17 support
;
; in:	al = value at 40:17
;	di = pointer to vgna structure
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
	shr	di,1
	cmp	al,byte ptr [di].kbstat ; same as saved?
	jne	dleds
	shl	di,1
	ret
dleds:

; we must now change the keyboard leds

	pushf
	cli
	mov	byte ptr [di].kbstat,al
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
	mov	al,byte ptr [di].kbstat
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
; in:	bx = port
;	al = station 0 for first, 1 for second
;
; out:	
;
;,fe
;=====================================================================
	assume	ds:nothing,es:nothing,ss:nothing
initkb proc near
	shl	bx,1
	mov	dx,vgnaport[bx]
	xor	ah,ah
	add	ax,bx
	mov	bx,ax
	and	ax,1

; now clear keyboard 8259

	push	ax
	push	dx
	add	dx,9
	mov	ah,al
	and	ah,1
	inc	ah
	in	al,dx
	jmp		$+2
	jmp	$+2
	jmp	$+2
	or	al,ah
	out	dx,al
	jmp	$+2
	jmp	$+2
	jmp	$+2
	pop	dx
	pop	ax

; now initialize keyboard

	push	cx
	push	dx
	push	ax
	add	dx,ax			; set up to point to keyboard control
	add	dx,ax			; register
	inc	dx
	mov	kbport[bx],dx
	call	drainkeybd		; drain keyboard
	mov	al,0aah
	call	outcmd			; send 0aah to keyboard
	cmp	ax,-1
	je	erroraa
	call	get55			; get keyboard input
	cmp	al,055h
	je	setup8042
erroraa:
	jmp	errorkb
setup8042:

; setup 8042 command byte

	call	drainkeybd
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
	call	drainkeybd
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
	pop	ax
	pop	dx
	pop	cx
	mov	ax,0ffffh
	ret
initkba:
	pop	ax
	pop	dx

; now set up keyboard 8259

	push	ax
	push	dx
	add	dx,9
	mov	ah,al
	and	ah,1
	inc	ah
	not		ah
	in	al,dx
	jmp	$+2
	and	al,ah
	out	dx,al
	pop	dx
	pop	ax
	pop	cx
	xor	ax,ax

; now initialize keyboard data areas

	cli
	shl	bx,1
	mov	kbget[bx],0
	mov	kbput[bx],0
	shr	bx,1
	mov	keyrdy[bx],0		; no keys yet
	sti
	lea	bx,keyrdy[bx]
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
	ret
odexit:
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

	subttl drainkeybd - 
	page
;======================================================================
;,fs
; drainkeybd - 
;
; in:	
;
; out:	
;
;,fe
;=====================================================================
	assume	ds:nothing,es:nothing,ss:nothing
drainkeybd proc near
	push	cx
	mov	cx,10
drainloop:
	call	getkey
	loop	drainloop
	pop	cx
	ret
drainkeybd endp

	subttl irq_main - the main vgna irq handler
	page
;======================================================================
;,fs
; irq_main - the main vgna irq handler
;
; notes: this is the main irq handling loop.  it traces the chain of
; 8259's on the vgna boards and determines the source of the
; irq - calling vgna_irq or serial_irq.  then, after reseting the 8259
; on the motherboard, as many vgna 8259's as were traced are reset.
;
; in:	
;
; out:	
;
;,fe
;=====================================================================
	assume	ds:nothing,es:nothing,ss:nothing

;===================== individual irq entry points ===================

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

;========================== main irq entry point ========================

; on entry, [bx] points to a head of list pointer for the irq

irq_main proc far
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
	mov	dx,[si] 		; get the base address
	add	dx,0ah
	in	al,dx
	jmp	$+2
	jmp	$+2
	jmp	$+2
	in	al,dx
	sub	dx,0ah
	push	ax
	add	dx,08h
	mov	al,20h
	cli
	cmp	si,offset [ipntr10] 
	jnae	irq060 
	out	0a0h,al
	jmp	$+2
	jmp	$+2
	jmp	$+2
irq060:
	out	20h,al
	jmp	$+2
	jmp	$+2
	jmp	$+2
	out	dx,al
	sub	dx,8h
	pop	ax
	xor	di,di
	cmp	al,1			; is this serial or keyboard
	ja	doserial

; this must be keyboard, so find out if station 1 or 2

	jne	dokey0

; handle keyboard #2

	add	dx,2
	inc	di

; handle keyboard #1 (also remaining of keyboard #2)

dokey0:
	inc	dx
	call	keybd
	jmp	short	iodone
doserial:

; this is not keyboard, put could be a spurious interupt, if
; so then we must skip servicing

	cmp	al,3
	ja	iodone

; now we must check if serial 1 or 2

	jne	doser0

; handle serial #2

	inc	di
doser0:
	call	serial_irq
iodone:
	pop	ds
	pop	di
	pop	si
	pop	dx
	pop	cx
	pop	ax
	pop	bx
	iret
irq_main endp 

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
	lea	si,[tcbcondd]
	mov	bl,byte ptr [si].port
	cmp	[ws0ismc],'Y'
	je	unr0
	dec	bl
unr0:
	cmp	bl,8
	ja	unr1
	xor	bh,bh
	shl	bx,1
	mov	word ptr cs:[vgnatcb+bx],-1  ; unregister
	shl	bx,1
	cmp	word ptr cs:[vgnaunreg+bx+2],0	; end of list
	je	unr1
	call	dword ptr cs:[vgnaunreg+bx]  ; chain it
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
	xor	bh,bh
	cmp	[ws0ismc],'Y'
	je	inkbmc
	dec	bx
inkbmc:
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
	mov	dx,kbport[di]
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
;=====================================================================
	assume	ds:nothing,es:nothing,ss:nothing
outkbctl proc near
	test	al,80h
	jz	outkbx
	mov	bl,byte ptr [si].port
	xor	bh,bh
	cmp	[ws0ismc],'Y'
	je	outkbmc
	dec	bx
outkbmc:
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
	mov	ah,11h
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
	mov	ah,11h
	ret
prstr endp 

nullret:				; used as the initial value for the call vectors
	ret				; for beep and print

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
; out:	returns ah as in int 17h call for bad status
;	al = 1 (fresh flag)
;	bx = 0f3c9h  (signature to verify this function is supported)
;
;,fe
;=====================================================================
	assume	ds:nothing,es:nothing,ss:nothing
print_status proc near
	mov	ah,11h
	mov	al,1
	mov	bx,0f3c9h		; signature
	ret
print_status endp


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

porttbl ports	8 dup(<>)	; the port table array
portoff dw	offset porttbl	; pointer to the port table

spoff	dw	8 dup (0)
serport dw	8 dup (0)

; sername must be 40 bytes long since this is what mos info expects

sername db	'VGNA.SYS  V3.00 (910329)                '

; misc serial data

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

serial	equ	false
emulink equ	false
mos	equ	true

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
clr_set_irq proc near
	ret
clr_set_irq endp 

	subttl serial_irq - process a serial irq
	page
;======================================================================
;,fs
; serial_irq - process a serial irq
;
; in:	al = ir level
;	dx = vgna base port address
;	ds -> local data  (== cs)
;
; out:	
;
;,fe
;=====================================================================
	assume	ds:nothing,es:nothing,ss:nothing
serial_irq proc near
	push	bx
	push	es
	mov	bx,offset [vgnaport]	; first need to determine the board number
	cmp	[bx],dx 		; check each vgnaport entry for a match
	je	iirq005
	add	bx,2
	cmp	[bx],dx 		; check each vgnaport entry for a match
	je	iirq005
	add	bx,2
	cmp	[bx],dx 		; check each vgnaport entry for a match
	je	iirq005
	add	bx,2
	cmp	[bx],dx 		; check each vgnaport entry for a match
	je	iirq005
	add	bx,2
iirq005:
	sub	bx,offset [vgnaport]	; derive a major index into serport array
	shl	bx,1			; 2 ports per board
	add	bx,di
	add	bx,di
	mov	dx,[bx+serport]
	mov	bx,[bx+spoff]
iirq010:
	rdiir				; read the interrupt indentification register
	test	al,noint		; is he interupting
	jnz	iirq015 		; jump if not this port
	xor	ah,ah			; convert interupt type to offset
	mov	si,ax			; move the offset to si
	call	inttbl[si]		; call the interupt processor
	jmp	short iirq010
iirq015:
	pop	es
	pop	bx
	ret
serial_irq endp 

enddrvr3 equ	$

;======= end of resident code and data when serial ports are used =======

;========= start of device driver initialization code and data ==========

;======================== transient data ================================

; put base port addresses in these lists on first pass in parse_exec.
; as addresses are put into each list, the icnt counter will be incremented.
; vgna base addresses will have their high bit set.  after all parameters have
; been validated, the contents of these lists will be copied into the irqpack
; list and the ipntr? and icnt? variables will be set appropriately.

ilist2	dw	8 dup(?)
ilist5	dw	8 dup(?)
ilist7	dw	8 dup(?)
ilist10 dw	8 dup(?)
ilist11 dw	8 dup(?)
ilist12 dw	8 dup(?)
ilist15 dw	8 dup(?)

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
p1p_off dw	?

;===== misc vars for ddtinit

serflg	db	0			; indicates serial logic is to stay

;========================= error mesages ===========================

edef	macro	p1, p2, p3
p1	equ	p2
db	p2,p3,'$'
	endm

; standard error codes for report_error

error_list:
edef er_inv,1,'Parameter invalid or missing        '  ;@@xlat
edef er_eol,2,'Premature end of line        '  ;@@xlat
edef er_nonull,3,'Null parameter not allowed        '  ;@@xlat

; application specific error messages for report_error

edef uer_np3wp4,51,'B/L parameter supplied when no printer port was specifie                '  ;@@xlat
edef uer_np4wp3,52,'B/L parameter required when a printer port is specified                 '  ;@@xlat
edef uer_vgnamax,53,'More than 2 VGNA base ports specified                '  ;@@xlat
edef uer_adrcflt,54,'Address conflict        '	;@@xlat
edef uer_sermax,55,'More than 2 serial ports specified per VGNA card set                '  ;@@xlat
edef uer_ibmax,56,'More than 1 IB= per port        '  ;@@xlat
edef uer_obmax,57,'More than 1 OB= per port        '  ;@@xlat
edef uer_hsmax,58,'More than 1 HS= per port        '  ;@@xlat
edef uer_cnmax,59,'More than 1 HS= per port        '  ;@@xlat
edef uer_iblow,60,'Input buffer must be at least 16 bytes        '  ;@@xlat
edef uer_oblow,61,'Output buffer must be at least 16 bytes        '  ;@@xlat
db	0				; end of list marker

crlf	db	13,10,'$'
err_lead db	'Parameter error in VGNA.SYS:        ',13,10,'$'  ;@@xlat

em1	db	'VGNA base address        $'  ;@@xlat
em2	db	'VGNA System irq          $'  ;@@xlat
em7	db	'VGNA serial port address (/AD=)        $'  ;@@xlat
em8	db	'VGNA serial option (IB=, OB=, HS=, CN=)        $'  ;@@xlat
em9	db	'VGNA serial option (IB=)        $'  ;@@xlat
em10	db	'VGNA serial option (OB=)        $'  ;@@xlat
em11	db	'VGNA serial option (HS=)        $'  ;@@xlat
em12	db	'VGNA serial option (CN=)        $'  ;@@xlat
emnull	db	'$'

savecur dw	0
savectype dw	0

parm_msg_tbl:
	dw	em1
	dw	em2
	dw	emnull
	dw	emnull
	dw	emnull
	dw	em2
	dw	em7
	dw	em8
	dw	em9
	dw	em10
	dw	em11
	dw	em12
	dw	emnull

ddt2	db	'VGNA terminal device driver already installed         ',13,10,'$'  ;@@xlat

;======================= installation messages ==========================

badali	equ	$
ddtmsg	db	'VGNA terminal device driver (910329) installed           ',13,10,'$'  ;@@xlat
sermsg	db	'  VGNA serial port logic installed             ',13,10,'$'  ;@@xlat
pvgamsg db	'  Paradise VGA Card on host                    ',13,10,'$'  ;@@xlat

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
	assume es:tcb
	mov	al,byte ptr [tcbcondd.dcbios]  ; save foreground's dcbios
	lds	bx,[tcbcondd]		; to detect co-resident case
	mov	dx,offset [ddt2]	; in the procedure hideif

; check for a second loading of vgna.sys

	cmp	word ptr [bx-3],'GV' 
	je	xx000B 
	jmp	xx000A 
xx000B: 
	cmp	byte ptr [bx-1],'A' 
	jne	xx000a
	jmp	ddierror 
xx000A: 
	mov	word ptr [ddtmc],bx	; mcterm address
	mov	word ptr [ddtmc+2],ds
	push	es
	les	bx,[request]
	lds	si,es:[bx+18]		; -> device driver command line
	call	parse_exec		; parse the command line
	pop	es
	push	cs
	pop	ds
	mov	dx,0			; no additional error message if error
	jnc	xx000E 
	jmp	ddierror 
xx000E: 

; set vidchk routine for pamswitching access

	push	bx
	push	es
	les	bx,[scbptr]
	assume	es:gdata
	mov	word ptr es:[bx.scbvidchk], offset vidchk
	mov	word ptr es:[bx.scbvidchk+2],cs
	assume	es:tcb
	pop	es
	pop	bx

; verify that master console is workstation 0, this is done by banking
; in bank 0fh (which will never be present) and check b800:0 for -1
; if so than foreground is not vgna board and we must assume that it is
; paradise style vga card.

	push	dx
	push	es
	mov	dx,word ptr [vgnaport]
	add	dl,0fh
	mov	ax,0b800h
	mov	es,ax
	mov	al,0fh
	out	dx,al			; bank in non-vgna bank
	cmp	word ptr es:[0],-1	; ff ff ff.....
	je	mustbevgna		; yes than vgna is host
	mov	[ws0ismc],'N'		; indicate no
	jmp	short skipnormal
mustbevgna:
	mov	al,00h
	out	dx,al			; back to normal
skipnormal:
	mov	ah,3			; save cursor
	xor	bh,bh
	int	10h
	mov	[savecur],dx
	mov	[savectype],cx
	pop	es
	pop	dx

; initialize each ws for each ali card

	mov	al,2
	cmp	[ws0ismc],'Y' 
	jne	ddi015 
	mov	al,1
ddi015:
	mov	bx,offset [vgnaport]
	mov	cx,[nvgna]
ddi020:
	push	cx
	push	bx
	mov	dx,cs:[bx]
	mov	cl,al
	sub	bx,offset [vgnaport]
	call	initvgna
	pop	bx
	pop	cx
	mov	al,2
	add	bx,2
	loop	ddi020
	cmp	[ws0ismc],'Y'
	jne	ddi010
	or	[tcbvram],08h
	mov	word ptr [tcbcondd.port],0
	mov	word ptr [tcbcondd],offset [vgaterm]
	mov	word ptr [tcbcondd+2],cs
ddi010:

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

; calculate the next free segment - accounting for how much code
; and data must be kept

	mov	di,offset [enddrvr1]	; only keep vgna code and data
	cmp	[serflg],1 
	jne	ddi135			; if any serial ports, keep the third
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

	cmp	[serflg],1		; is serial logic installed
	je	ddi136
	jmp	ddi150
ddi136:

; for each port, account for the space required for
; its two serial buffers

	mov	cx,[numport]
	cmp	cx,0 			; could be a serial base but no /ad's
	je	ddi143 
	mov	bx,offset [porttbl]
ddi140:
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
	loop	ddi140			; go do the next port
ddi143:

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

; find all vgna pic's and clear them - also for warm boot insurance.
; note: this loop presumes there will be an iona for every vna.
; if there isn't, shouldn't hurt anything.

	mov	al,20h			; eoi command
	xor	cx,cx
ddi129c:				; for each vgna
	mov	bx,cx
	shl	bx,1			; derive an index into the vgnaport
	mov	dx,[vgnaport+bx]	; array   (card number - 1) * 2
	add	dx,08h			; address vgna 8259 even register
	out	dx,al
	jmp	$+2
	jmp	$+2
	inc	cx
	cmp	cx,[nvgna]
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
	assume es:nothing
	mov	word ptr es:[bx+14],0	; set next free segment into
	mov	es:[bx+16],di		; the request header

; switch in master console, if master console is vgna switch workstation
; 0 in, other wise switch in workstation

	xor	ax,ax			; switch foreground in
	call	setws
	cmp	[ws0ismc],'Y'
	jne	ddi155a
	push	bx
	push	cx
	mov	dx,[savecur]		; if vgna is master console,
	mov	cx,[savectype]		; set cursor back to normal
	mov	ah,2
	xor	bh,bh
	int	10h
	pop	cx
	pop	bx
ddi155a:

; display installation messages

	mov	dx,offset [ddtmsg]
	mov	ah,9
	int	21h
	cmp	[ws0ismc],'Y'
	je		ddi156
	mov	dx,offset [pvgamsg]
	mov	ah,9
	int	21h
ddi156:
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
	mov	word ptr [vgnanm],'\\'	; can't be opened
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
;		  type  format  return		   notes
;		  ====  ======  ======  ==================================
dw	get_vbase ; 1   /hhhh	  ax     literal / followed by 4 hex digits
dw	get_irq   ; 2   h 	  ax     1 or more decimal digits - 64k max
dw	hex2word  ; 3   hhhh	  ax     hex word value
dw	get_paddr ; 4   /ad=hhhh  ax     literal /ad=  and a hex word value
dw	get_ib	  ; 5   ib=d	  ax     literal ib=  and a decimal word value
dw	get_ob	  ; 6   ob=d	  ax     literal ob=  and a decimal word value
dw	get_hs	  ; 7   hs=a	  al     literal hs=  and a single alpha char
dw	get_cn	  ; 8   cn=a	  al     literal cn=  and a single alpha char
dw	nojump	  ; 9   /ms=xxxx  al     literal /ms= and y's or N's

;=================== parameter classification table ======================

class_tbl_p1:
	db	pc_singl,1		; p1 - vgna base port address
	db	pc_singl,2		; p2 - vgna kybd irq
	db	pc_singl,3		; p3 - vgna printer base address
	db	pc_skip 		; p4 - b/l designator
	db	pc_singl,3		; p5 - vgna serial base address
	db	pc_singl,2		; p6 - vgna serial irq
class_tbl_p7:
	db	pc_singl,4		; p7 - vgna serial port address
class_tbl_p8:
	db	pc_orgrp,4,5,6,7,8	; p8a,b,c and d - vgna serial port options
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
nojump:
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
	jz	ftp1 			; can't be a null parm if not
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
	cmp	ch,cl 
	jne	ftp8 			; tried all elements?
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
;
; in:	ds:si -> asciiz string of test characters
;	al = character to test
;
; out:	zr if a match
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
; this routine cannot be used to test for a 0.
;
; in:	cs:si -> asciiz string of test characters
;	al = character to test
;
; out:	zr if a match
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
; a new delimset string can be declared if newdelim exists
;
; in:	al = character to check against delimset
;
; out:	zr if a match
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
;	al = character found
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
; in addition to stopping on chars in the delimset, this
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
; chk_cflt - test for address conflicts
;
; uses the cflt_map bit map to check for address conflicts.
; does not preserve bx or cx.
;
; in:	bx = base address (within 0100 to 03f0)
;	cx = size factor
;	 cx = 1 for banked parallel ports
;	 cx = 4 for linear parallel ports and vgna base address
;	 cx = 8 for vgna serial base address
;
; out:	nz for conflict, zr if ok
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
	cmp	ax,ax			; set zr
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
; the appropriate icnt and ilist are determined based on the
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
	add	si,10h
	cmp	ax,5 
	je	pil01 
	add	bx,2
	add	si,10h
	cmp	ax,7 
	je	pil01 
	add	bx,2
	add	si,10h
	cmp	ax,10 
	je	pil01 
	add	bx,2
	add	si,10h
	cmp	ax,11 
	je	pil01 
	add	bx,2
	add	si,10h
	cmp	ax,12 
	je	pil01 
	add	bx,2			; must be irq 15
	add	si,10h
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
; chk_parie - check for a parameter of the type  /xx=
;
; checks for a pair of characters followed by an '=' sign.
; leaves direction flag set to up.
;
; in:	ds:si -> parameter string to test
;	al = first char in pair
;	ah= second char in pair
;
; out:	zr if no error
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
	cmp	al,'='			; return with zr or nz based on this comparison
chp01:
	pop	bx
	ret
chk_paire endp 

	subttl get_vbase - get a vgna base address
	page
;======================================================================
;,fs
; get_vbase - get a vgna base address
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

	subttl get_irq - get a vgna irq parameter
	page
;======================================================================
;,fs
; get_irq - get a vgna irq parameter
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
;=====================================================================
	assume	ds:nothing,es:nothing,ss:nothing

irq_set db	2,5,7,10,11,12,15,0

get_irq proc near
	call	dec2word
	jc	xx005A 
	cmp	ah,0 
	je	gti01 
xx005A: 
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
	push		ax
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
gpd01:					; cy exit handler
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
gib01:					; cy exit handler
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
gob01:					; cy exit handler
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
ghs01:					; cy exit handler
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
gcn01:					; cy exit handler
	mov	ax,3
	stc
	ret
get_cn endp 

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

markerr macro	p1, p2		;; p1 is parameter # and p2 is error #
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
	call	passdelims		; make si point to the first vgna base address

; process p1 - the vgna base address

prx000:
	mov	bx,offset [class_tbl_p1]; setup cs:bx
	mov	di,offset [parm_type_tbl]
	call	fetch_parm
	jnc	prx005 
	cmp	ax,rc_eol 
	jne	xx0076 
	jmp	prxdone			; eol always ok at the 1st parameter
xx0076: 
	jmp	prxerror
prx005:
	cmp	[nvgna],4 
	jne	prx010 
	jmp	prxerror
prx010:
	test	ax,not 03f0h 
	jnz	xx0079 
	cmp	ax,100h 
	jnb	prx015 
xx0079: 
	jmp	prxerror
prx015:
	mov	cx,4
	push	bx
	mov	bx,ax
	call	chk_cflt		; check for addressing conflicts
	pop	bx
	jz	prx020 
	jmp	prxerror
prx020:
	mov	di,cs:[nvgna]
	inc	cs:[nvgna]
	shl	di,1			; derive index into vgnaport table
	mov	cs:[p1p_off],di 	; save port offset
	mov	cs:[di+vgnaport],ax	; store the vgna base port
	mov	cs:[p1_val],ax		; save for p2 processing

; process p2 - the vgna keyboard irq

	mov	di,offset [parm_type_tbl]
	call	fetch_parm
	jnc	prx025 
	markerr 2,er_inv
	jmp	prxerror
prx025:
	mov	dx,cs:[p1_val]		; fetch the vgna base address
	call	put_ilist		; ax holds the irq number
	push	bx
	mov	bx,cs:[nvgna]
	dec	bx
	shl	bx,1			; derive an index into vgnairq
	mov	cs:[bx+vgnairq],ax
	pop	bx

; process p7 - vgna serial port address

	mov	cs:[p7_count],0
	mov	cs:[p7_cflt],0
prx145:
	mov	cs:[p7_rc],rc_ok	; clear the return code
	mov	bx,offset [class_tbl_p7]; reset cs:bx for another p7
	mov	di,offset [parm_type_tbl]
	call	fetch_parm
	jnc	prx165 
	cmp	ax,rc_eol 		; if p6 specified, must have
	jne	prx150 
	jmp	prxdone
prx150:
	cmp	ax,rc_null 
	jne	prx155 
	markerr 7,er_nonull
	jmp	prxerror
prx155:
	push	si			; preserve parse pointer
	mov	al,1			; check for type 1  "/hhhh"
	mov	di,offset [parm_type_tbl]
	call	check_type
	pop	si
	jc	xx0087 			; recycle to the p1 level
	jmp	prx000 
xx0087: 
prx160:
	markerr 7,er_inv
	jmp	prxerror
prx165:
	cmp	cs:[p7_count],2 	; check for too many /ad='s
	jne	prx170 
	markerr 7,uer_sermax
	jmp	prxerror
prx170:
	inc	cs:[p7_count]

; check for duplicate port address

prx175:
	test	cs:[p7_cflt],cl 
	jz	prx177 
	markerr 7,uer_adrcflt
	jmp	prxerror
prx177:
	or	cs:[p7_cflt],cl

; p7 now fully validated - time to update port table

	push	bx
	push	di
	mov	di,cs:[p1p_off]
	shl	di,1			; 2 work stations for each card
	test	ax,08h
	jz	notp2
	inc	di
	inc	di
notp2:
	mov	bx,cs:[numport]
	shl	bx,5			; derive index into port table
	add	bx,offset [porttbl]
	mov	cs:[di+spoff],bx	; set high speed index into porttbl
	mov	cs:[di+serport],ax
	pop	di
	pop	bx
	or	cs:[serflg],1		; indicate that we have serial code
	mov	di,cs:[numport] 	; need port-1 for calcs
	inc	cs:[numport]
	mov	cl,5			; port table size = 32 bytes
	shl	di,cl			; derive index into port table
	add	di,offset [porttbl]
	or	ax,8000h
	mov	cs:[di].addr,ax 	; store the port's address
	mov	ax,cs:[p6_val]
	mov	cs:[di].prtirq,al	; store the port's irq
	mov	cs:[portndx],di 	; save port index for lator

; process p8 - vgna serial port options
; note: di is expected to contain the port table index

	cmp	[numport],1 
	jne	prx180 

; explicitly set default parameters on first entry

	mov	cs:[di].ibfsiz,64	; use 64 byte buffer (ideal 25mhz)
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
	jc	xx0095 		
	jmp	prx000 			; recycle to the p1 level
xx0095: 
	push	si			; preserve parse pointer
	mov	al,4			; check for type 4  "/AD=hhhh"
	mov	di,offset [parm_type_tbl]
	call	check_type
	pop	si
	jc	xx0097 
	jmp	prx145 			; recycle to the p7 level
xx0097: 
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
	cmp	cx,2 			; p8b	ob=
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
	cmp	cx,3 			; p8c	hs=
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
; return error

prx285:
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
	jc	xx00B9 
	jmp	prx000 			; recycle to the p1 level
xx00B9: 
	markerr 13,er_inv
	jmp	prxerror

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
	cmp	[nvgna],0 
	jne	prxd01 

; setup for default parameters

; default for vgna is /240,7

	mov	[vgnaport],0240h
	mov	[vgnairq],7
	mov	ax,offset [irqpack]
	mov	[ipntr7],ax
	mov	[irqpack],0240h
	mov	[icnt7],1
	mov	[nvgna],1
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

	subttl initvgna - vgna board initialization
	page
;======================================================================
;,fs
; initvgna - vgna board initialization
;
; in:	bl = starting ws number for board
;	cl = number of ws's to init for board
;	dx = base address of vgna board
;
; out:	
;
;,fe
;=====================================================================
	assume	ds:nothing,es:nothing,ss:nothing
initvgna proc near
	push	cx
initv1:
	push	dx
	push	cx
	push	bx
	mov	[vgnacur],0ffh		; clear it out so it will always
	mov	al,2			; be set
	sub	al,cl			; so ws0 is skipped if init'ing 2 only
	add	al,bl			; starting bank number
	cmp	[ws0ismc],'Y'
	je	initv2			; if paradise vga is master console
	inc	al			; must add one to work station
initv2:
	call	setws
	call	initbios
initv3:
	pop	bx
	pop	cx
	pop	dx
	loop	initv1
	pop	cx
	ret
initvgna endp 

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
; out:	
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
ipc02:
	add	dx,8			; address the first vgna 8259 register
	mov	al,00010011b		; icw1 - need icw4, single, edge triggered
	out	dx,al
	jmp	$+2
	inc	dx			; address the second vgna 8259 register
	mov	al,00000000b		; icw2 - interrupt type 0
	out	dx,al
	jmp	$+2			; (skipping icw3)
	mov	al,00001001b		; icw4 - select 8086, buffered slave
	out	dx,al
	jmp	$+2
	mov	al,11110011b		; only init serials
ipc04:
	out	dx,al
	jmp	$+2
	dec	dx
	mov	al,20h			; issue an eoi
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

code	ends
	end

