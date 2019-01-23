	include page.inc
	title	VGNA.ASM - VGNA (Video Graphics Network Adapter)

true	equ	1 eq 1
false	equ	1 eq 0
MONO	equ	0

comment ^===============================================================
		       Development Specification

 Program Name:	VGNA.ASM			Assigned to: Stewart Hyde
 Module Name:	VGNA				Assign date: 09/06/89
 Entry Points:	VGNATERM 			Completed:   10/11/89
 Entry From:	MOSINT10, MOSINT16, MOSVIDRM
 Entry Method:	CALL DWORD [vector] with AH = function number
 Calls:		I10OLD (boot interrupt 10h)
 Purpose:	MOS interface to ALI VGNA
 Refer to:	n/a
 Last Update:	08/06/90
========================================================================

SAH 02/08/90	Correction for 33Mhz AMI machine (fast)

mjs 05/09/90	added the clr_set_irq dummy function.  it is called by
		int14fun11 within int14.inc (only needed by _serial.asm)

SAH 06/25/90    Corrections for Non-(EGA\VGA) stations can pamswitch.

SAH 07/19/90	Corrections for faster machines (486 and 33mhz 386's)

SAH 08/06/90	Added Logic to init serial ports and pics

mjs 08/13/90	modified to use vidchk.inc and a boot_prep function.

SAH 06/05/92	Correction for VGNA on MOS 5.01, move some of UNTERM's
		VGA Init code over - save video vectors over. Please
		note that 40:17 corrections are not in here. they need
		more work.  How every the corrections for printer status 
		are included.

=======================================================================^

	subttl	group segments and include block definitions
	page
.xlist
	.286			; Only works on 286+ machines, so take
				; advantage of it

;-----------------------------------------------------------------------;
; the following include files are definitions of the respective blocks	;
; the definitions do not reserve any storage by virtue of the		;
; SEGMENT AT x construction						;
;-----------------------------------------------------------------------;
tcb	segment at 1234h
	include MOSTCB.INC	; TCB definition
tcb	ends

;-----------------------------------------------------------------------;
; the MOSSCBX include file is a file with extrn statements specified	;
; for all the items defined in the SCB					;
;-----------------------------------------------------------------------;
gdata	segment at 5678h
	assume	ds:gdata

	include MOSSCBDF.INC	; specify all SCB items as external

gdata	ends

	include xifmacs.inc

stall	macro	
	mov	cx,-1
	loop	$
	mov	cx,-1
	loop	$
	endm

.list

code	segment para public 'data'	; To force loading with data
	assume	cs:code,ds:nothing,es:nothing,ss:nothing
	
	include vgna.pub

DDTVGA	equ	this byte
	dd	-1		; filled in with pointer to next driver
	dw	8000h		; signifying a character device
	dw	strat		; device strategy entry point
	dw	inter		; device interrupt entry point
vgnanm	db	'$$VGNA  '	; device name

enddrvr0 equ	$

request dd	0

infoofs	dw	offset 	VgnaInfo	; offset to start of VGNA driver
					; information packet This is use
					; by VGNA.EXE to display VGNA driver
					; information	

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
	mov	ax,8103h	; error, done, unknown command
	cmp	cx,4
	jne	inter1		; if not reading exactly 4 bytes
	mov	es:[bx+18],cx	; else read 4 bytes
	mov	word ptr ds:[si],offset VGATERM ; and these are them
	mov	ds:[si+2],cs
	mov	ax,0100h	; no error, done
inter1:
	assume	ds:nothing
	les	bx,[request]
	mov	es:[bx+3],ax	; store result status
	pop	ax
	pop	bx
	pop	si
	pop	ds
	pop	es
	ret
inter	endp

;==================== END OF DDT INTERFACE CODE =========================

	subttl	termfn - all the terminal and keyboard functions for mos
	page

tfn	dw	register
	dw	inkbdata
	dw	outkbctl
bgnvid	equ	($-tfn)/2
	dw	0		;setmode
	dw	0		;setcrstyp
	dw	0		;setcrspos
	dw	0		;scrollup
	dw	0		;scrolldn
	dw	0		;wrchatr
	dw	0		;setpalet
	dw	0		;wrtty
	dw	0		;wrstr
	dw	0		;setwindow
	dw	0		;wrcho
	dw	0		;readch
	dw	0		;getscr
endvid	equ	($-tfn)/2
	dw	prch
	dw	prstr
	dw	print_status
endtfn	equ	($-tfn)/2

	assume	ds:nothing,es:nothing,ss:nothing

;===================== PERMANENT RESIDENT DATA ==========================

; after parameters have been validated (during initialization), the base 
; addresses for each vgna card are copied into irppack.  the ipntr?
; and icnt? variables are used to keep track of the addresses in irqpack.

ipntr2	dw	?	; pointer to irq2 entries in irqpack
ipntr5	dw	?	; pointer for irq5
ipntr7	dw	?	; etc.
ipntr10 dw	?
ipntr11 dw	?	; NOTE !!!!!!!!!!!!!!
ipntr12 dw	?	; the ipntr and icnt lists must stay in this order
ipntr15 dw	?

ipntsize equ	$-ipntr2

icnt2	dw	0	; count of irq2 entries in irqpack
icnt5	dw	0	; count for irq5
icnt7	dw	0	; etc.
icnt10	dw	0
icnt11	dw	0
icnt12	dw	0
icnt15	dw	0

; vgna base addresses are recorded in irqpack.  iona base addresses 
; have their high bit set.  the irq handler accesses the entries in
; this list through the appropriate ipntr? and icnt? variables.

irqpack	dw	8 dup(?)

; misc vgna variables

scbptr	label	dword
scbofs	dw	0		; offset of scb
scbseg	dw	0		; segment of scb
mcdcbios db	0		; a copy of the foreground's dcbios
ddtmc	dd	0		; address of master console ddt entry
vgnacur	db	-1		; who is currently banked in
vgnaunreg dd	8 dup (0)	; prevous un-register calls
saveds	dw	0
savebx	dw	0	
savevid	dw	0
savevram db	0
off10	dw	0		; original INT 10 offset
seg10	dw	0		; original INT 10 segment
off1d		dw	0		; original int 1d offset
seg1d		dw	0		; original int 1d segment
off1f		dw	0		; original int 1f offset
seg1f		dw	0		; original int 1f segment
off43		dw	0		; original int 43 offset
seg43		dw	0		; original int 43 segment
off6d		dw	0		; original int 6d offset
seg6d		dw	0		; original int 6d segment
off4a8		dw	0		; bios word at 40:a8h
seg4a8		dw	0		; bios word at 40:aah


; one key buffer for each workstation

KBSIZE	equ	32		; 32 scan codes buffered

; there are several spots within this driver hard-coded to expect this
; keyboard size.  They don't all reference the size through kbsize either.

if KBSIZE ne 32
	%out	kb buffer size wrong for shift count
endif

;-----------------------------------------------------------------------;
; VGNA Information Packet - use to display information externally by    ;
; VGNA.EXE which is use to print out this information after driver has  ;
; be loaded.								;
;									;
; Offset     Size   Name	   Description				;
;-----------------------------------------------------------------------;
;  00h	     2	    NVGNA	   # of VGNA Base ports			;
;  02h	     4*2    VGNAPORT	   Array of Port use by system		;
;  0ah	     4*2    VGNAIRQ	   Array of Irq use by system		;
;  12h	     2	    NUMPORT	   Total # of serial ports declared	;
;  14h	     8*2    VGNATCB	   Array of TCB use on system (-1 N/A)  ;
;  24h	     1	    WS0ISMC	   Y is Workstation 0 is master console ;
;	     1      filler	  					;		
;  26h	     8*2    KBGET	   Array of Keyboard Get Pointers	;
;  36h	     8*2    KBPUT	   Array of Keyboard Put Pointers	;
;  46h       8      KEYRDY	   Array of Keyboard Ready Flags	;
;  46h	     8*32   KBY		   Array of 32 byte Keyboard buffers	;
; 14Eh	     2	    SPORTOFS	   Offset to port table information	;
; 150h	     2      SEROFF	   Offset to serport			;
;-----------------------------------------------------------------------; 						 			

	even		
VgnaInfo label	word
nvgna	dw	0		; total number of vgna base ports
vgnaport dw	4 dup(0)	; vgna base addresses
vgnairq	 dw	4 dup(0)	; irq associated with each vgna base address
numport	dw	0		; total number of serial ports declared
vgnatcb	dw	8 dup (-1)	; register tcbs
ws0ismc db	'Y'		; 'N' if master console not workstation 0
	db	0
kbget	dw	8 dup(0)
kbput	dw	8 dup(0)
keyrdy	db	8 dup(0)
kbf	db	8*KBSIZE dup(0)
sportofs dw	offset porttbl
seroff	dw	offset serport
spaoff	dw	offset spoff
kbstat	db	8 dup(0)

;==================== BANK SELECTION PROCEDURES =========================

;- SETWS ---------------------------------------------------------------;
; setws - bank in the workstation - al is the workstation number	;
;-----------------------------------------------------------------------;
	assume	ds:nothing,es:nothing,ss:nothing
setws:
	cmp	al,[vgnacur]
	jne	setws1
	ret
setws1:
 	cmp	[ws0ismc],'Y'		; is WS 0, VGNA
	je	setwstation		; if so then no need to full with
					; 46e8h register
;
;	Co-existence with Paradise VGA need special handling
;       if switching to VGNA station, you will need to 
;		1.  Switch Master Console out (46e8h)
;		2.  Switch Work station in (set bank)
;	if switching to Master Console, you will need to
;		1.  Switch all Work stations out (set bank to non station)
;		2.  Switch Master Console in (46e8h)
;
; 	Special Notes:
;		While Work Station is in, we must make sure that 
;		Master Console does not get switch in. We must handle
;		port 46e8h specially. 
;
	or	al,al
	jz	setmc		; if 0, then switch in master console
;
;       Switch in work station
;
	push	ax
	push	dx
	mov	al,0fh
	call	setwstation	; set master console
	mov	al,06h		; this is the value we send to 46e8h
	mov	dx,46e8h
	out	dx,al
	pop	dx
	pop	ax
	call	setwstation	; set bank
	ret
;
;       Switch out all work stations
;
setmc:
	call	setwstation	; set bank
	push	ax
	push	dx
	mov	al,0eh		; this is the value we send to 46e8h
	mov	dx,46e8h
	out	dx,al
	pop	dx
	pop	ax
	ret
;
;	Set work station - actuall routine to set bank
;
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

;- BANKIN --------------------------------------------------------------;
; bank in the workstation  - ds:si -> tcbddt				;
; if the currently selected workstation is the one needed, then just 	;
; return, else, use scblastdd to bankout the workstation that is	;
; currently in before selecting the one needed.  If the currently	;
; selected workstation is another vgna workstation then here is no need	;
; to call the fe function of the ddt which is in scblastdd.  In this	;
; case, one call to setws will bank out the current wks and bank in the	;
; new one.								;
;-----------------------------------------------------------------------;
	assume	ds:nothing,es:nothing,ss:nothing
bankin:
	assume	ds:nothing,es:nothing,ss:nothing
	pushf			; save current interrupt flag setting
	cli			; secure against irq's that switch video
	push	ax
	push	bx
	push	di
	push	es
	les	di,[scbptr]
	cmp	es:[di.scblastff],0
	jz	bankin2		; if scblastff == 0, nobody needs banked out
	mov	ax,ds
	cmp	ax,es:[di.scblastff]	; is this workstation already selected?
	je	bankin3

; Is this driver's entry point the same as that of the 
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

; When the last workstation banked in has a different driver entry point, 
; then make an fe call to the last driver banked in to get it banked out.
; Otherwise, it is presumed that banking in the new workstation will
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

; Bank in the new workstation and update scblastff 
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
	popf			; restore interrupt flag state
	ret

;- VGATERM -------------------------------------------------------------;
; vgnaterm - this is the entry point for ddt calls			;
; off to master console ddt if						;
;   workstation 0 and master console is workstation 0			;
;   or if a video function						;
; else handle it in vgna ddt						;
;-----------------------------------------------------------------------;
	assume	ds:nothing,es:nothing,ss:nothing
	db	'VGA'
VGATERM proc	far

; 0feh is a special function to switch out all vgna's (co-resident case)
; this logic switches in workstation 15
; Since VGNA only has a max of 8 VGNA's, switching in workstation 15
; will switch out all VGNA's, and if master console isn't VGNA, this
; will allow access to master console VGA card

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

; Now, call ddtmc's ff handler to insure that the video display ram is exposed

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
	cmp	byte ptr [si].port,0	; if not Master console - ignore it
	jne	vgnafnx
vgnafn1a:
	cmp	ah,bgnvid
	jb	vgnafn2
	cmp	ah,endvid
	jb	vgnafn3
vgnafn2:
	cmp	[ws0ismc],'Y'
	jne	vgnafn4		; ws0 not master console
	cmp	byte ptr [si].port,0
	jne	vgnafn4		; not ws0
	cmp	ah,10h
	je	vgnafn4		; the print routines are an except - so
	cmp	ah,11h		; the master console could used an VGNA
	je	vgnafn4		; parallel port if desired.

; process a video function

vgnafn3:
	cmp	ah,4		; for set cursor type or set cursor
	je	vgnafn3a	; position, must bank in the right 
	cmp	ah,5		; workstation first
	jne	vgnafn3b
vgnafn3a:
	call	bankin
vgnafn3b:
	push	si
	call	ddtmc		; when ddtmc calls exposreal, the 
	pop	si		; ddt function ff which will come back
	jmp	vgnafnx		; to this ddt first

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
VGATERM endp
	
	subttl	register - register port address, receive key buffer flag
	page
;- REGISTER ------------------------------------------------------------;
; register - register port address, receive key buffer flag		;
;									;
;   AH = 00H								;
;     es:bx -> scbmapvmf						;
;     DX = port address 						;
;     DS:SI -> tcbddt for this terminal for this partition		;
;									;
;   returns:								;
;     ES:BX -> key buffer flag						;
;	key buffer flag is <> 0 while scan codes are buffered		;
;     AL = 80H if master console					;
;	   00H if not master console					;
;     AH = 00H cause no error can happen				;
;-----------------------------------------------------------------------;
	assume	ds:nothing,es:nothing,ss:nothing
register:
	mov	ah,0ffh
	mov	bl,byte ptr [si].port
	cmp	[ws0ismc],'Y'
	je	reg0a
	dec	bl
reg0a:

; check to see if task has allready been register
; if so return error

	xor bh,bh
	shl bx,1
	cmp word ptr [vgnatcb+bx],-1
	je  reg0b
	jmp regsx
reg0b:
    	mov [saveds],ds     ; save pointer to tcb
	mov [savebx],bx     ; save port pointer for later
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

	if	MONO
	mov	al,byte ptr [si].port
	call	ChkMono				; check if mono station
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


	call	initkb		; returning ah = 0ffh if error
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
	mov	bx,[savebx]	; get savebx
	cmp	bx,8*2
	ja	regok
	mov	ds,[saveds]
	assume  ds:tcb
	mov	word ptr [vgnatcb+bx],ds	; register task
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
	assume  ds:nothing
	pop	bx
	pop	di
	pop	si
	xor	ah,ah
	jmp	short regsx
regsbad:
	mov	ah,0ffh
regsx:
	mov	al,[savevram]	; graphics and mc and ali
	mov	cx,[savevid]	; physical buffer address (stuffed into
	ret			;   tcbvidad)


	if	MONO

	subttl ChkMono - check if MONO station
	page
;-----------------------------------------------------------------------;
; ChkMono:								;
; This routine will check system hard to check if station is Mono VGA   ;
; Al = station to set, return carry if stations is Color		;
;-----------------------------------------------------------------------;

ChkMono proc 	near
	mov	ah,[vgnacur]
	push	ax
	call	setws		; switch station in
	push	dx
	mov	dx,3ceh		; get Options bits from card
	mov	al,0fh
	out	dx,al
	jmp	$+2
	inc	dx
	in	al,dx
	test	al,40h		; is bit 2 set	
	jnz	Mono
	clc
	jmp	short MonoOut
Mono:
	stc
MonoOut:
	pop	dx
	pop	ax		; get current station
	mov	al,ah
	pushf
	call	setws		; set back to current
	popf
	ret
ChkMono endp

	endif

; The following routine is use to initialized the workstation by calling
; the VGA bios boot strap routine, INT Vector must be save and restore
; after call because VGA Bios will initialize the vertor.

; Note for co-existence with Paradise VGA card as master console, master
; console screen will flicker and clear when this routine is called
; And this routine is call at device driver init time.

InitBios proc	near
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
; Set INT 1dh vector to c000:0085h
;
	mov	word ptr es:[1dh*4],0085h
	mov	word ptr es:[1dh*4+2],0c000h
;
; Set INT 1fh vector to c000:0e02h
;
	mov	word ptr es:[1fh*4],00e02h
	mov	word ptr es:[1fh*4+2],0c000h
;
; Set INT 43h vector to c000:0a02h
;
	mov	word ptr es:[43h*4],00a02h
	mov	word ptr es:[43h*4+2],0c000h
;
; Set INT 6dh vector to c000:007a3h
;
	mov	word ptr es:[6dh*4],007a3h
	mov	word ptr es:[6dh*4+2],0c000h
;
; Set dword at 40:a8h to c000:5274h
;
	mov	word ptr es:[04a8h],05274h
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
InitBios endp	 


	include vidchk.inc


	subttl boot_prep - prepare the video state for a reboot
	page
;======================================================================
; .func: boot_prep - prepare the video state for a reboot
;
; input:
;	
; output:
;
; comments:
;
; .calls: 
; .reads: 
; .writes: 
;
; .endfn
;======================================================================
	assume	cs:code,ds:nothing,es:nothing,ss:nothing
boot_prep:
	xor	ax,ax		; switch forground in
	call	setws
	ret


	subttl keybd - process a vgna keyboard irq
	page
;-----------------------------------------------------------------------;
; KEYBD - this is the stations keyboard handler, it will put the        ;
; the key scan codes into the driver 32 byte keyboard buffer in         ;
; task information table.					        ;
; 								        ;
; Assumes:							        ;
;      DI = Points to VGNA data structure				;
;      DX = Points to keyboard control register				;	
;-----------------------------------------------------------------------;

keybd	label	near
	push	bx

	push	dx
	and	dx, 0fff0h
	mov	bx,offset [vgnaport]	; first need to determine the board number
	cmp	[bx],dx			; check each vgnaport entry for a match
	je	keybd1
	add	bx,2
	cmp	[bx],dx			; check each vgnaport entry for a match
	je	keybd1
	add	bx,2
	cmp	[bx],dx			; check each vgnaport entry for a match
	je	keybd1
	add	bx,2
	cmp	[bx],dx			; check each vgnaport entry for a match
	je	keybd1
	add	bx,2
keybd1:
	sub	bx,offset [vgnaport]	; derive a major index into serport array
	pop	dx
	add	di,bx
	mov	cx,08000h
kbd1:
	in	al,dx
	test	al,1				; input ready?
	loopz	kbd1
	dec	dx
	in	al,dx				; get data
	inc	dx
	cmp	al,0feh				; resend
	je	kbd2
	cmp	al,0fah				; achnolodge
	jne	kbd3		
;	
;	do keyboard achnolodge
;
	jmp	kbover
kbd2:
;
;	do keyboard resend 
;	
	jmp	kbover
kbd3:
	cmp	al,0ffh				; overrun.....
	je	kbover
	cmp	byte ptr [di].keyrdy,00h	; any characters
	je	kbempty
	shl	di,1				; shift to word index
	push	si
	mov	si,word ptr [di].kbget
	cmp	si,word ptr [di].kbput		; overflow in buffer
	pop	si
	je	kbover
	shr	di,1				; shift back to byte index
kbempty:	    
	mov	byte ptr [di].keyrdy,0ffh	; flag keyboard ready flag
	shl	di,1				; shift to word index
	mov	si,word ptr [di].kbput		; get point to que
	push	di
	shl	di,4 				; this assume 32 bytes	
	add	di,si				; and that we are AT bus
	mov	byte ptr [di].kbf,al
	pop	di
 	inc	si
	cmp	si,KBSIZE			; test to see if over limit
	jb	kbset
	xor	si,si
kbset:
	mov	word ptr [di].kbput,si		; save new pointer	
	call	DoLeds				; Handle LEDs
kbover:
	pop	bx
	ret


;-----------------------------------------------------------------------;
; DoLEDS - This routine is use to set the keyboard status LEDS on the	;
; keyboard.  This is do by checking the 40:17 status save in the TCB as ;
; TCBKSHFT (This is necessary because keyboard IRQ could and will get	;
; get call when another task is switch into memory).  If status is	;
; is different that prevous saved status, then the routine will access	;
; memory map area to change the leds.					;
;-----------------------------------------------------------------------;

DoLEDS	proc	near
	push	ax
	push	es
	mov	es,word ptr [di].vgnatcb 	; get TCB for station
	assume	es:tcb
	mov	al,tcbkshft			; get keyboard status
	pop	es
	assume	es:nothing
	shr	al,4				; format it for the output
	and	al,7				; to keyboard
	shr	di,1
	cmp	al,byte ptr [di].kbstat 	; same as saved?
	jne	dleds
	shl     di,1
	pop	ax				; yes...then no need to do it
	ret
 dleds:
;
;	we must now change the keyboard LEDS
;
	push	cx
	mov	byte ptr [di].kbstat,al
	dec	dx
	mov	al,0edh
	out	dx,al
	jmp	$+2
	jmp	$+2
	call	KeyACK				     ; wait for ACK
	mov	al,byte ptr [di].kbstat
	out	dx,al
	jmp	$+2
	jmp	$+2
	call	KeyACK
	inc	dx
	shl	di,1
	pop	cx
	pop	ax
	ret
DoLEDS	endp

;
;	This routine is use by DoLEDS to check for ACk from keyboard
;

KeyACK	proc	near
	mov	cx,-1
kaloop:
	in	al,dx				; get data
	cmp	al,0fah 			; is it ACK
	loopnz	kaloop				; loop if not
	ret
KeyACK	endp

	subttl InitKB - initialize keyboard controller
	page
;-----------------------------------------------------------------------;
; INITKB:								;
; this procedure is use to initial the stations keyboard controller     ;
; that it will send scan codes to host adapter which will generate      ;
; IRQ so that driver can place the scan code into the keyboard buffer   ;
;									;
;	BX = Port							;
;	AL = Station 0 for first, 1 for second				;
;-----------------------------------------------------------------------;

InitKB	proc	near
	shl	bx,1
	mov	dx,vgnaport[bx]
	xor	ah,ah
	add	ax,bx
	mov	bx,ax
	and	ax,1		
;
;	Now Clear keyboard 8259
;
	push	ax
	push	dx
	add	dx,9
	mov	ah,al
	and	ah,1
	inc	ah
	in	al,dx
	jmp 	$+2
	jmp	$+2
	jmp	$+2
	or	al,ah
	out	dx,al
	jmp	$+2
	jmp	$+2
	jmp	$+2
	pop	dx
	pop	ax
;
;	Now initialize Keyboard
;
	push	cx
	push	dx
	push	ax
	add	dx,ax		; set up to point to keyboard control
	add	dx,ax		; register
	inc	dx
	mov	al,0aah
	call	OutCmd
	dec	dx
	call	InKyb
	inc	dx
	cmp	al,55h

comment  |

	jne	ErrorKB
	dec	dx
	call	InKyb
	call	InKyb
	inc	dx
	mov	cx,8000h
;WaitF2:
	in	al,dx
	test	al,2
	loopnz	Waitf2
	dec	dx	
	mov	al,0f2h			; send NOP
	out	dx,al  
	call	InKyb
	inc	dx	
	cmp	al,0fah	
	|

	je	InitKBa
ErrorKB:
	pop	ax
	pop	dx	
	pop	cx
	mov	ax,0ffffh
	ret
InitKBa: 
	pop	ax
	pop	dx
;
;	Now set up keyboard 8259
;
	push	ax
	push	dx
	add	dx,9
	mov	ah,al
	and	ah,1
	inc	ah
	not 	ah
	in	al,dx
	jmp	$+2
	and	al,ah
	out	dx,al
	pop	dx
	pop	ax

	push	dx
	add	dx,ax
	add	dx,ax
	inc	dx
	mov	al,0aah
	call	OutCmd
	mov	al,60h
	call	OutCmd
	mov	cx,8000h
WAit45:
	in	al,dx	
	test	al,2
	loopnz	Wait45
	dec	dx
	mov	al,45h
	out	dx,al
	pop	dx

	pop	cx

	xor	ax,ax
;
;	Now initialize keyboard data areas
;
	cli
	shl	bx,1
	mov	kbget[bx],0
	mov	kbput[bx],0
	shr	bx,1
	mov	keyrdy[bx],0	; no keys yet
	sti
	lea	bx,keyrdy[bx]
	ret
InitKB	endp

;
; The following routine is use by InitKB to output commands to keyboard
; controller during initialization of Keyboard.
;


OutCmd	proc	near
	push	cx
	mov	cx,-1
	mov	ah,al
OCLoop:
	in	al,dx
	test	al,2
	loopnz	OCLoop
	mov	al,ah
	out	dx,al	
	pop	cx
	ret
OutCmd	endp	

InKyb	proc	near
	inc	dx
	push	cx
	mov	cx,-1
IKLoop:
	in	al,dx
	test	al,2
	loopz   IKLoop
	dec	dx
	in	al,dx
	pop	cx
	ret
InKyb	endp	



subttl	irq_main - the main vgna irq handler
	page
;- IRQ_MAIN-------------------------------------------------------------;
; entry parms:	none							;
; exit parms: 	none							;
;									;
; NOTES: This is the main irq handling loop.  It traces the chain of	;
; 8259's on the vgna boards and determines the source of the    	;
; irq - calling vgna_irq or serial_irq.  Then, after reseting the 8259	;
; on the motherboard, as many vgna 8259's as were traced are reset.	;
;-----------------------------------------------------------------------;
	assume	ds:nothing,es:nothing,ss:nothing

;===================== INDIVIDUAL IRQ ENTRY POINTS ===================

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

;========================== MAIN IRQ ENTRY POINT ========================

; on entry, [bx] points to a head of list pointer for the IRQ

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
	mov	si,[bx]			; si = index into the irqpack list
	mov	dx,[si]			; get the base address
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
	xif si ae <offset [ipntr10]> else irq060
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
;
;	This must be keyboard, so find out if station 1 or 2
;
	jne	dokey0
;
;	Handle Keyboard #2
;
	add	dx,2
	inc	di		
;
;	Handle Keyboard #1 (also remaining of Keyboard #2)
;
dokey0:
	inc	dx
	call	keybd
	jmp	short	iodone
doserial:
;
;	This is not keyboard, put could be a spurious interupt, if
;	so then we must skip servicing
;
	cmp	al,3
	ja	iodone
;
;	now we must check if serial 1 or 2
;	
	jne	doser0
;
;	Handle Serial #2
;	
	inc	di
doser0:
	call	Serial_Irq		
iodone:
	pop	ds
	pop	di
	pop	si
	pop	dx
	pop	cx
	pop	ax
	pop	bx
	iret

	subttl unregister 
	page
;- UNREGISTER ----------------------------------------------------------;
; UnRegister 								;
;									;
; Input:								;
;	DS --> tcb of task						;
;-----------------------------------------------------------------------;
	assume	ds:nothing,es:nothing,ss:nothing
unregister proc	far
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
	mov	word ptr cs:[vgnatcb+bx],-1	; unregister
	shl	bx,1
	cmp	word ptr cs:[vgnaunreg+bx+2],0	; end of list
	je	unr1				
	call	dword ptr cs:[vgnaunreg+bx]	; chain it
unr1:
	pop	ds
	pop	si
	pop	bx
	ret
unregister endp

	subttl	inkbdata - input keyboard scan code
	page
;-----------------------------------------------------------------------;
; inkbdata - input keyboard scan code					;
;									;
;   AH = 01H								;
;     DS:SI -> tcbddt							;
;									;
;   returns:								;
;     AL = bit	7   - key break if 1, key make or key repeat if 0	;
;	   bits 6-0 - key scan code 01H - 07DH				;
;     key scan code is read non-destructively				;
;-----------------------------------------------------------------------;
	assume	ds:nothing,es:nothing,ss:nothing
inkbdata:
	mov	bl,byte ptr [si].port
	xor	bh,bh
	cmp	[ws0ismc],'Y'
	je	inkbmc
	dec	bx
inkbmc:
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

	subttl	outkbctl - clear current scan code from terminal driver
	page
;-----------------------------------------------------------------------;
; outkbctl - clear current scan code from terminal driver		;
;									;
;   AH = 02H								;
;     AL = bit	7   - clear buffered scan code if 1, ignored if 0	;
;	   bits 6-0 - ignored						;
;     DS:SI -> tcbddt							;
;-----------------------------------------------------------------------;
	assume	ds:nothing,es:nothing,ss:nothing
outkbctl:
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
	jz	outkbx		; no scan code to clear
	shl	bx,1
	mov	si,kbget[bx]
	inc	si
	cmp	si,KBSIZE
	jb	outkb1
	xor	si,si
outkb1:
	cli			; any more scan codes ?
	mov	kbget[bx],si
	cmp	si,kbput[bx]
	jne	outkb2
	shr	bx,1
	mov	keyrdy[bx],0
outkb2:
	sti
outkbx:
	ret

	subttl	prch - print a character on the terminal's local printer
	page
;- PRCH ----------------------------------------------------------------;
; entry parms:	ah = 10h						;
;		al = char to print					;
;		ds:si -> tcbddt						;
; exit parms:	returns ah as in int17					;
; NOTES: print a character on the terminal's local printer		;
;-----------------------------------------------------------------------;
	assume	ds:nothing,es:nothing,ss:nothing
prch:
	ret

	subttl	prstr - print a string on the terminal's local printer
	page
;- PRSTR ---------------------------------------------------------------;
; entry parms:	AH = 11H						;
;		ES:DI -> string to print				; 
;		CX = length (bytes) to print				;
;		DS:SI -> tcbddt						;
; exit parms: 	AH as in INT 17H if all of string can't be printed	;
;		DI -> first char not printed, CX = number not printed	;
;									;
; NOTES: print a string on the terminal's local printer			;
;-----------------------------------------------------------------------;
	assume	ds:nothing,es:nothing,ss:nothing
prstr:
	ret


nullret:	; used as the initial value for the call vectors
	ret	; for beep and print


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

;====== START OF RESIDENT CODE AND DATA WHEN SERIAL PORTS ARE USED ======

;==================== SERIAL RESIDENT DATA ==============================

ports	struc

addr	dw	0			; physical port address
prtirq	db	4			; default IRQ line for port
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
					; 01h - rcv xon/xo; Novell
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


porttbl	ports	8 dup(<>)	; the port table array
portoff	dw	offset porttbl	; pointer to the port table

spoff	dw	8 dup (0)
serport dw	8 dup (0) 

; sername must be 40 bytes long since this is what MOS INFO expects

sername	db	'VGNA.SYS  V2.00 (920605)                '

; misc serial data

orig1a	dd	0		; int 1a vector at initialization
orig38	dd	0		; Original Services vector
child	dd	0		; point to next int14 driver
tocount dw	182		; default timeout (10 seconds)

;========= async adapter port and status definitions

TXDAT	equ	0			; data transmitter
RXDAT	equ	0			; data receiver
DIVLL	equ	0			; baud rate divisor latch lsb
DIVLM	equ	1			; baud rate divisor latch msb

IEREG	equ	1			; interupt enable register
enmsi	equ	000001000b		; enable modem status interupts
enlsi	equ	000000100b              ; enable line status interupts
entei	equ	000000010b		; enable transmitter empty inter
endri	equ	000000001b		; enable data ready interupts

IIREG	equ	2			; interupt identification regist
noint	equ	000000001b		; no interupt pending

LCREG	equ	3			; line control register
divla	equ	010000000b		; divisor latch access control
stbrk	equ	001000000b		; set break condition

MCREG	equ	4			; modem control register
stot2	equ	000001000b		; set out 2 (enable interupts)
stot1	equ	000000100b		; set out 1
strts	equ	000000010b              ; set rts
stdtr	equ	000000001b		; set dtr

LSREG	equ	5			; line status register
tsre	equ	001000000b		; transmitter shift reg empty
thre 	equ	000100000b		; transmitter holding reg empty
brki	equ	000010000b		; break indicator
frerr	equ	000001000b		; framing error
paerr	equ	000000100b		; parity error
overr	equ	000000010b		; data overrun error
drdy	equ	000000001b		; data ready

MSREG	equ	6			; modem status register
carst	equ	010000000b		; status of carrier detect (RLSD)
rngst	equ	001000000b		; status of ring indicator (RI)
dsrst	equ	000100000b		; status of data set ready (DSR)
ctsst	equ	000010000b		; status of clear to send (CTS)
carch	equ	000001000b		; change in carrier detect (RLSD)
trlri	equ	000000100b		; trailing end of ring indicator
dsrch	equ	000000010b		; change in data set ready (DSR)
ctsch	equ	000000001b		; change in clear to send (CTS)

	assume	ds:nothing,es:nothing,ss:nothing

serial	equ	false
emulink	equ	false
mos	equ	true

include seriomac.inc		; i/o macros
include jmpmacro.inc		; long jump macros
include	int14.inc		; int14 logic
include	isrsub.inc		; serial irq support surbroutines

	subttl clr_set_irq - dummy (only needed by _serial.asm)
	page
;======================================================================
; .func: clr_set_irq - dummy (only needed by _serial.asm)
;
; input:
;	ch = 0 to clear, 1 to set
;	cl = irq number
;
; .calls: 
; .reads: 
; .writes: 
;
; .endfn
;======================================================================
clr_set_irq:
	ret

	subttl serial_irq - process a serial irq
	page
;- SERIAL_IRQ ----------------------------------------------------------;
; entry parms:	al = ir level						;
;		dx = vgna base port address				;
;		ds -> local data  (== cs)				;
;									;
; exit parms: 	process a serial irq					;
; note: This routine crashes ax,cx,dx,si, and di			;
;-----------------------------------------------------------------------;
	assume	ds:nothing,es:nothing,ss:nothing
serial_irq:
	push	bx
	push	es
	mov	bx,offset [vgnaport]	; first need to determine the board number
	cmp	[bx],dx			; check each vgnaport entry for a match
	je	iirq005
	add	bx,2
	cmp	[bx],dx			; check each vgnaport entry for a match
	je	iirq005
	add	bx,2
	cmp	[bx],dx			; check each vgnaport entry for a match
	je	iirq005
	add	bx,2
	cmp	[bx],dx			; check each vgnaport entry for a match
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
	RDIIR				; read the interrupt indentification register
	test	al,noint		; is he interupting
	jnz	iirq015			; jump if not this port
	xor	ah,ah			; convert interupt type to offset
	mov	si,ax			; move the offset to si
	call	inttbl[si]		; call the interupt processor
	jmp	short iirq010
iirq015:
	pop	es
	pop	bx
	ret
enddrvr3 equ	$

;======= END OF RESIDENT CODE AND DATA WHEN SERIAL PORTS ARE USED =======


;========= START OF DEVICE DRIVER INITIALIZATION CODE AND DATA ==========

;======================== TRANSIENT DATA ================================

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
; mode).  As each address is found in parsing the parameter line, the
; corresponding bits are tested.  if not set already, they are set.  
; if already set, then there is an address conflict.

cflt_map db	7 dup(0)
	db	0f0h		; 01f0 - reserved
	db	3 dup(0)
	db	0f0h		; 0270 - reserved
	db	3 dup(0)
	db	0f0h		; 02f0 - reserved
	db	0fh		; 0300 - reserved
	db	2 dup(0)
	db	0f0h		; 0370 - reserved
	db	0
	db	0f0h		; 03b0 - reserved
	db	0ffh		; 03d0 - reserved
	db	0f0h		; 03f0 - reserved

;===== MISC VARS FOR THE PARSE EXEC

p1_val	dw	?
p3_rc	dw	?
p3_val	dw	?
bl_mode	db	?
p5_val	dw	?
p6_val	dw	?
p7_rc	dw	?
p7_count db	?
p7_cflt	db	?
portndx dw	?
p8a_once db	?
p8b_once db	?
p8c_once db	?
p8d_once db	?
p1p_off	dw	?

;===== MISC VARS FOR DDTINIT

serflg	db	0		; indicates serial logic is to stay

;========================= ERROR MESAGES ===========================

edef	macro	p1, p2, p3
p1	equ	p2
db p2,p3,'$'
	endm

; standard error codes for report_error

error_list:
edef er_inv,1,'Parameter invalid or missing        '     ;@@XLAT
edef er_eol,2,'Premature end of line        '		 ;@@XLAT
edef er_nonull,3,'Null parameter not allowed        '	 ;@@XLAT

; application specific error messages for report_error

edef uer_np3wp4,51,'B/L parameter supplied when no printer port was specifie                '	;@@XLAT
edef uer_np4wp3,52,'B/L parameter required when a printer port is specified                 '	;@@XLAT
edef uer_vgnamax,53,'More than 2 VGNA base ports specified                '   ;@@XLAT
edef uer_adrcflt,54,'Address conflict        '	       ;@@XLAT
edef uer_sermax,55,'More than 2 serial ports specified per VGNA card set                '   ;@@XLAT
edef uer_ibmax,56,'More than 1 IB= per port        ' ;@@XLAT
edef uer_obmax,57,'More than 1 OB= per port        ' ;@@XLAT
edef uer_hsmax,58,'More than 1 HS= per port        ' ;@@XLAT
edef uer_cnmax,59,'More than 1 HS= per port        ' ;@@XLAT
edef uer_iblow,60,'Input buffer must be at least 16 bytes        '  ;@@XLAT
edef uer_oblow,61,'Output buffer must be at least 16 bytes        '    ;@@XLAT
db	0		; end of list marker

crlf	db	13,10,'$'
err_lead db	'Parameter error in VGNA.SYS:        ',13,10,'$'     ;@@XLAT

em1	db	'VGNA base address        $'	 ;@@XLAT
em2	db	'VGNA System irq          $'	 ;@@XLAT
em7	db	'VGNA serial port address (/AD=)        $'  ;@@XLAT
em8	db	'VGNA serial option (IB=, OB=, HS=, CN=)        $'  ;@@XLAT
em9	db	'VGNA serial option (IB=)        $' ;@@XLAT
em10	db	'VGNA serial option (OB=)        $' ;@@XLAT
em11	db	'VGNA serial option (HS=)        $' ;@@XLAT
em12	db	'VGNA serial option (CN=)        $' ;@@XLAT
emnull	db	'$'

savecur	dw	0
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

ddt2	db	'VGNA terminal device driver already installed         ',13,10,'$'  ;@@XLAT

;======================= INSTALLATION MESSAGES ==========================

badali	equ	$
ddtmsg	db	'VGNA terminal device driver (920605) installed           ',13,10,'$'  ;@@XLAT
sermsg	db	'  VGNA serial port logic installed             ',13,10,'$'	;@@XLAT
pvgamsg db	'  Paradise VGA Card on host                    ',13,10,'$'	;@@XLAT

;=================== MAIN INITIALIZATION PROCEDURE ======================

	subttl	ddtinit - device driver initialization
	page
;- DDTINIT -------------------------------------------------------------;
; entry parms:	[request] -> request header from dd call		;
; exit parms: 	end of resident point set into request header		;
;									;
; NOTES: initialization - retrieve location of master console ddt 	;
; entry, taking tcbcondd address from foreground tcb, replacing that 	;
; address with our entry, set driver length and exit.			;
;-----------------------------------------------------------------------;
	assume	ds:nothing,es:nothing,ss:nothing
ddtinit:
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
	mov	es,es:[bx+scbtcbpf]	; access the foreground tcb
	assume es:tcb
	mov	al,byte ptr [tcbcondd.dcbios]  ; save foreground's dcbios
	lds	bx,[tcbcondd]		; to detect co-resident case
	mov	dx,offset [ddt2]	; in the procedure hideif

; check for a second loading of vgna.sys

	lxaif <word ptr [bx-3]> == 'GV' && <byte ptr [bx-1]> == 'A' then ddierror
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
	lxif flags == cy then ddierror

;
;	Set VidChk routine for Pamswitching access
;

	push	bx
	push	es

	les	bx,[scbptr]
	assume  es:gdata
	mov	word ptr es:[bx.scbvidchk], offset VidChk
	mov	word ptr es:[bx.scbvidchk+2],cs
	assume  es:tcb

	pop	es
	pop	bx
;
; Verify that Master Console is WorkStation 0, this is done by banking
; in bank 0fh (which will never be present) and check B800:0 for -1
; if so than Foreground is not VGNA board and we must assume that it is
; Paradise style VGA Card.
;

	push	dx
	push	es
	
	mov	dx,word ptr [vgnaport]
	add	dl,0fh
	mov	ax,0b800h
	mov	es,ax

	mov	al,0fh
	out	dx,al		; bank in non-vgna bank

	cmp	word ptr es:[0],-1	; ff ff ff.....
	je	MustBeVGNA		; yes than VGNA is host
	mov	[ws0ismc],'N'		; indicate NO
	jmp	short SkipNormal

MustBeVGNA:

	mov	al,00h
	out	dx,al			; back to normal

SkipNormal:
	mov	ah,3				; save cursor
	xor	bh,bh
	int	10h
	mov	[savecur],dx
	mov	[savectype],cx

	pop	es
	pop	dx

;
; initialize each ws for each ali card

	mov	al,2
	xif [ws0ismc] == 'Y' else ddi015
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
	mov	word ptr [tcbcondd],offset [VGATERM]
	mov	word ptr [tcbcondd+2],cs
ddi010:


; set up main system irq's and 8259's

	xif [icnt2] != 0 else ddi025
	mov	al,2
	mov	cx,[icnt2]
	mov	bx,[ipntr2]
	call	initpic
ddi025:
	xif [icnt5] != 0 else ddi030
	mov	al,5
	mov	cx,[icnt5]
	mov	bx,[ipntr5]
	call	initpic
ddi030:
	xif [icnt7] != 0 else ddi035
	mov	al,7
	mov	cx,[icnt7]
	mov	bx,[ipntr7]
	call	initpic
ddi035:
	xif [icnt10] != 0 else ddi040
	mov	al,10
	mov	cx,[icnt10]
	mov	bx,[ipntr10]
	call	initpic
ddi040:
	xif [icnt11] != 0 else ddi045
	mov	al,11
	mov	cx,[icnt11]
	mov	bx,[ipntr11]
	call	initpic
ddi045:
	xif [icnt12] != 0 else ddi050
	mov	al,12
	mov	cx,[icnt12]
	mov	bx,[ipntr12]
	call	initpic
ddi050:
	xif [icnt15] != 0 else ddi055
	mov	al,15
	mov	cx,[icnt15]
	mov	bx,[ipntr15]
	call	initpic
ddi055:

; calculate the next free segment - accounting for how much code
; and data must be kept 

	mov	di,offset [enddrvr1]	; only keep vgna code and data
	xif [serflg] == 1 else ddi135	; if any serial ports, keep the third
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

	cmp 	[serflg],1	; is serial logic installed
	je	ddi136
	jmp	ddi150
ddi136:	

; for each port, account for the space required for 
; its two serial buffers

	mov	cx,[numport]
	xif cx != 0 else ddi143		; could be a serial base but no /ad's
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
	
; for each serial port, output a 0 to the ier.  this is done to insure
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
	loop	ddi129a			; go do the next port

; find all VGNA pic's and clear them - also for warm boot insurance.
; note: this loop presumes there will be an iona for every vna.
; if there isn't, shouldn't hurt anything.

	mov	al,20h			; eoi command
	xor	cx,cx
ddi129c:				; for each VGNA
	mov	bx,cx
	shl	bx,1			; derive an index into the vgnaport
	mov	dx,[vgnaport+bx]	; array   (card number - 1) * 2
	add	dx,08h			; address VGNA 8259 even register
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

;
	push	di
	mov	ah,6
	xor	dx,dx			; see if another serial driver exists
	int	14h
	xif ah test1 80h else ddi145
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

; switch in Master console, if master console is VGNA switch workstation
; 0 in, other wise switch in workstation

	xor	ax,ax		; switch foreground in
	call	setws

	cmp	[ws0ismc],'Y'
	jne	ddi155a
	push	bx
	push	cx
	mov	dx,[savecur] 		; if VGNA is master console,
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
	cmp [ws0ismc],'Y'		
	je  	ddi156
	mov	dx,offset [pvgamsg]
	mov	ah,9
	int	21h
ddi156:
	xif [serflg] == 1 else ddi160
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
	xif dx != 0 else dder01
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

;================== PARAMETER PROCESSING DEFINITIONS ====================

; parameter classification table entry codes

pc_skip	equ	0	; skip case
pc_singl equ	1	; single entry case
pc_orgrp equ	2	; OR group case.  (next number is the # in the group)


; return codes from fetch_parm, check_type and type checking procedures

rc_ok	equ	0	; no error  ( !! this code not actually returned)
rc_eol	equ	1	; end of parameter line
rc_null	equ	2	; null parm (e.g. an empty position of the type  ,,)
rc_gerr	equ	3	; general error - invalid parameter

; codes 0-50 reserved for future use by the parameter engine
; 51+ available for use by type checking routines

;======================== PARAMETER TYPE TABLE =========================

parm_type_tbl:
;               type  format  return               notes
;               ====  ======  ======  ==================================
dw get_vbase	; 1   /hhhh     ax     literal / followed by 4 hex digits
dw get_irq	; 2   h         ax     1 or more decimal digits - 64k max
dw hex2word	; 3   hhhh      ax     hex word value
dw get_paddr	; 4   /AD=hhhh  ax     literal /AD=  and a hex word value
dw get_ib	; 5   IB=d      ax     literal IB=  and a decimal word value
dw get_ob	; 6   OB=d      ax     literal OB=  and a decimal word value
dw get_hs	; 7   HS=a      al     literal HS=  and a single alpha char
dw get_cn	; 8   CN=a      al     literal CN=  and a single alpha char
dw nojump	; 9   /MS=xxxx  al     literal /MS= and Y's or N's

;=================== PARAMETER CLASSIFICATION TABLE ======================

class_tbl_p1:
	db pc_singl,1		; p1 - vgna base port address
	db pc_singl,2		; p2 - vgna kybd irq
	db pc_singl,3		; p3 - vgna printer base address
	db pc_skip		; p4 - b/l designator
	db pc_singl,3		; p5 - vgna serial base address
	db pc_singl,2		; p6 - vgna serial irq
class_tbl_p7:
	db pc_singl,4		; p7 - vgna serial port address
class_tbl_p8:
	db pc_orgrp,4,5,6,7,8	; p8a,b,c and d - vgna serial port options
class_tbl_p9:
	db pc_singl,9		; p9 - enable modem signals option

;================== PARAMETER PROCESSING PROCEDURES =====================

	subttl check_type - pass through mechanism for type checking
	page
;- CHECK_TYPE ----------------------------------------------------------;
; entry parms:	ds:si -> paramter string to parse			;
;		cs:di -> vector table of type checking procedures	;
;		al = type code to check for				;
;									;
; exit parms: 	nc if no error						;
;		 ds:si advanced to next char after parm			;
;		 return value in ax, dx and/or di (depends on proc)	;
;		cy if error						;
;		 ax = error code					;
;		 si is undefined					;
;									;
; NOTES: ALL exit parms are from the type checking procedure, not	;
; this procedure.  bx and cx must not be used in a type checking 	;
; procedure.  this procedure crashes di.				;
;-----------------------------------------------------------------------;
	assume	ds:nothing,es:nothing,ss:nothing
check_type:
	dec	al
	xor	ah,ah
	shl	ax,1
	add	di,ax
	push	cs:[di]
nojump:
	ret

	subttl fetch_parm - parameter parsing procedure
	page
;- FETCH_PARM ----------------------------------------------------------;
; entry parms:	ds:si -> paramter string to parse			;
;		cs:di -> vector table of type checking procedures	;
;		cs:bx -> parameter classification table			;
;									;
; exit parms: 	nc if no error						;
;		 si advanced to next char after parm			;
;		 bx advanced to next classification table entry		;
;		 return value in ax, dx and/or di (depends on proc)	;
;		 cx = element number in the case of a group entry	;
;		 else cx undefined					;
;		cy if error						;
;		 ax = error code					;
;		 si restored to entry value				;
;		 bx advanced to next class table entry if ax = rc_null	;
;		 else bx undefined					;
;									;
; NOTES: some exit parms come from the type checking procedure, and	;
; some are from this procedure.	 direction flag is left up.		;
; calls testdelims, passdelims and check_type.  di is crashed.		;
;-----------------------------------------------------------------------;
	assume	ds:nothing,es:nothing,ss:nothing
fetch_parm:
	push	si			; si must remain the last thing pushed
	cld

; check for double comma case

	xor	ch,ch			; clear comma counter
ftp1:
	lodsb
	xif al == 0 else ftp2
	mov	ax,rc_eol
	jmp	ftp10			; goto cy exit handler
ftp2:
	xif al == ',' else ftp3
	inc	ch
	xif ch == 2 else ftp1
	mov	ax,rc_null		; si is set just after the 2nd comma
	add	sp,2			; compensate for the pop si
	dec	si			; compensate si for another double comma
	push	si			; that the exit handler will do

; advance bx to next entry

	case <byte ptr cs:[bx]> == pc_skip else ftp2a
	inc	bx
	jmp	ftp10
ftp2a:
	case <byte ptr cs:[bx]> == pc_orgrp else ftp2b
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
	xif flags == nz else ftp1	; can't be a null parm if not 
	dec	si			; in the delim set
	jmp	ftp4			; exit loop
ftp4:	
	call	passdelims
	or	al,al
	xif flags == zr else ftp5
	mov	ax,rc_eol
	jmp	ftp10			; goto cy exit handler

; check the entry type code in the parameter classification table

ftp5:
	xif <byte ptr cs:[bx]> == pc_skip else ftp5a
	inc	bx			; advance bx to next entry
	jmp	ftp11			; goto nc exit handler
ftp5a:
	add	sp,2			; replace stack si with current si
	push	si
	xif <byte ptr cs:[bx]> == pc_orgrp else ftp9
	inc	bx
	mov	cl,cs:[bx]		; get number of type codes in group
	xor	ch,ch			; reset element counter
ftp6:
	inc	bx
	mov	al,cs:[bx]		; get a type code
	push	di
	call	check_type
	xif flags == nc else ftp7
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
	xif ch == cl else ftp8		; tried all elements?
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

;============ MISC SUPPORT PROCEDURES FOR THE PARSE EXEC ==============

	subttl report_error - display an error message
	page
;- REPORT_ERROR ---------------------------------------------------------;
; entry parms:	al = error number					;
;		cs:di -> error message list				;
; 									;
; exit parms:	none							;
;-----------------------------------------------------------------------;
	assume	ds:nothing,es:nothing,ss:nothing
report_error:
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
	xoif es:[di] == al || <byte ptr es:[di]> == 0 then rer02
	mov	cx,0ffffh
	push	ax
	mov	al,'$'
	repne scasb			; find the string
	pop	ax
	jmp	rer01
rer02:
	xif es:[di] == al else rer03
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

	subttl testset - check a character for inclusion in a string
	page
;- TESTSET -------------------------------------------------------------;
; entry parms:	ds:si -> asciiz string of test characters		;
;		al = character to test					;
; 									;
; exit parms:	zr if a match						;
;									;
; NOTES: this routine cannot be used to test for a 0. 			;
; ax, ds and si are preserved.						;
;-----------------------------------------------------------------------;
	assume	ds:nothing,es:nothing,ss:nothing
testset:
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

;- CS_TESTSET ----------------------------------------------------------;
; entry parms:	cs:si -> asciiz string of test characters		;
;		al = character to test					;
; 									;
; exit parms:	zr if a match						;
;									;
; NOTES: this routine cannot be used to test for a 0. 			;
; ax, ds and si are preserved.						;
;-----------------------------------------------------------------------;
	assume	ds:nothing,es:nothing,ss:nothing
cs_testset:
	push	ds
	push	cs
	pop	ds
	call	testset
	pop	ds
	ret

	subttl testdelims - see if al is a delimiter
	page
;- TESTDELIMS ----------------------------------------------------------;
; entry parms:	al = character to check against delimset		;
;									;
; exit parms:	zr if a match						;
;									;
; NOTES: a new delimset string can be declared if newdelim exists	;
; al is preserved.  calls testset.					;
;-----------------------------------------------------------------------;
	assume	ds:nothing,es:nothing,ss:nothing

delimset db	',',20h,9,0		; default set of delimiters

testdelims:
	push	si
	push	ds
	lea	si,[delimset]
	push	cs
	pop	ds
	call	testset
	pop	ds
	pop	si
	ret

	subttl passdelims - scan forward past delimiters
	page
;- PASSDELIMS ----------------------------------------------------------;
; entry parms:	ds:si -> string to parse				;
;									;
; exit parms:	ds:si -> first non-delimiter found in string		;
;		al = character found					;
; 									;
; NOTES: calls testdelims.						;
;-----------------------------------------------------------------------;
	assume	ds:nothing,es:nothing,ss:nothing
passdelims:
	cld
pd1:
	lodsb
	call	testdelims
	je	pd1
	dec	si
	ret

	subttl finddelim - scan forward until a delimiter is found
	page
;- FINDDELIM -----------------------------------------------------------;
; entry parms:	ds:si -> string to parse				;
;									;
; exit parms:	ds:si -> first delimiter found in string		;
;		al = character found					;
;									;
; NOTES: in addition to stopping on chars in the delimset, this		;
; procedure will also stop on a 0.  calls testdelims.			;
;-----------------------------------------------------------------------;
	assume	ds:nothing,es:nothing,ss:nothing
finddelim:
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

	subttl chk_cflt - test for address conflicts
	page
;- CHK_CFLT ------------------------------------------------------------;
; entry parms:	bx = base address (within 0100 to 03f0)			;
;		cx = size factor					;
;		 cx = 1 for banked parallel ports			;
;		 cx = 4 for linear parallel ports and vgna base address	;
;		 cx = 8 for vgna serial base address			;
;									;
; exit parms: 	nz for conflict, zr if ok				;
;									;
; NOTES: uses the cflt_map bit map to check for address conflicts.	;
; does not preserve bx or cx.						;
;-----------------------------------------------------------------------;
	assume	ds:nothing,es:nothing,ss:nothing
chk_cflt:
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
	xif flags == nz then cft03
	or	cs:[bx],dl
	shl	dl,1
	xif flags == cy else cft02
	inc	bx
	mov	dl,1
cft02:
	loop	cft01
	cmp	ax,ax			; set zr
cft03:
	pop	dx
	ret

	subttl put_ilist - enter a base port address into an irq list
	page
;- PUT_ILIST -----------------------------------------------------------;
; entry parms:	ax = the irq number					;
;		dx = the address to store in an ilist			;
;									;
; exit parms: 	none							;
;									;
; NOTES: the appropriate icnt and ilist are determined based on the 	;
; irq number supplied in ax.  after the data is stored in the ilist	;
; the icnt is incremented.						;
;-----------------------------------------------------------------------;
	assume	ds:nothing,es:nothing,ss:nothing
put_ilist:
	push	bx
	push	si
	push	di
	mov	bx,offset [icnt2]
	mov	si,offset [ilist2]
	xif ax == 2 then pil01
	add	bx,2
	add	si,10h
	xif ax == 5 then pil01
	add	bx,2
	add	si,10h
	xif ax == 7 then pil01
	add	bx,2
	add	si,10h
	xif ax == 10 then pil01
	add	bx,2
	add	si,10h
	xif ax == 11 then pil01
	add	bx,2
	add	si,10h
	xif ax == 12 then pil01
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

	subttl chk_parie - check for a parameter of the type  /xx=
	page
;- CHK_PAIRE -----------------------------------------------------------;
; entry parms:	ds:si -> parameter string to test			;
;		al = first char in pair					;
;		ah= second char in pair					;
;									;
; exit parms: 	zr if no error						;
;		 si advanced just past end of the pair			;
;		nz if error						;
;		 si undefined						;
;									;
; NOTES: checks for a pair of characters followed by an '=' sign.	;
; leaves direction flag set to up.					;
;-----------------------------------------------------------------------;
	assume	ds:nothing,es:nothing,ss:nothing
chk_paire:
	push	bx
	mov	bx,ax
	cld
	lodsb
	xif al == bl else chp01
	lodsb
	xif al != bh then chp01
	lodsb
	cmp	al,'='			; return with zr or nz based on this comparison
chp01:
	pop	bx
	ret

	subttl get_vbase - get a vgna base address
	page
;- GET_VBASE -----------------------------------------------------------;
; entry parms:	ds:si -> parameter string to convert			;
;									;
; exit parms: 	nc if no error						;
;		 ax = binary value of string				;
;		 si advanced just past end of parm			;
;		cy if error						;
;		 ax = 3 (rc_gerr)					;
;		 si undefined						;
;									;
; NOTES: suitable as a type checking procedure for the parsing engine.	;
; calls hex2word.							;
; checks for a parameter of the type   /hhhh				;
;-----------------------------------------------------------------------;
	assume	ds:nothing,es:nothing,ss:nothing
get_vbase:
	xif <byte ptr [si]> == '/' else gvb01
	inc	si
	call	hex2word		; let hex2word return ax and nc or cy
	jmp	gvb02
gvb01:
	mov	ax,rc_gerr		; general error return code if no '/'
	stc
gvb02:
	ret

	subttl get_irq - get a vgna irq parameter
	page
;- GET_IRQ -------------------------------------------------------------;
; entry parms:	ds:si -> parameter string to convert			;
;									;
; exit parms: 	nc if no error						;
;		 ax = binary value of string				;
;		 si advanced just past end of parm			;
;		cy if error						;
;		 ax = 3 (rc_gerr)					;
;		 si undefined						;
;									;
; NOTES: suitable as a type checking procedure for the parsing engine.	;
; calls dec2word.							;
; checks for a parameter of the type   h   within the irq set		;
;-----------------------------------------------------------------------;
	assume	ds:nothing,es:nothing,ss:nothing

irq_set	db	2,5,7,10,11,12,15,0

get_irq:
	call	dec2word
	xoif flags == cy || ah != 0 else gti01
	mov	ax,rc_gerr
	stc
	ret
gti01:
	push	si
	lea	si,[irq_set]
	call	cs_testset		; validate the irq
	pop	si
	xif flags == nz else gti02
	mov	ax,rc_gerr
	stc
	ret	
gti02:
	clc
	ret

	subttl hex2word - convert a hexadecimal string to a word
	page
;- HEX2WORD ------------------------------------------------------------;
; entry parms:	ds:si -> parameter string to convert			;
;									;
; exit parms: 	nc if no error						;
;		 ax = binary value of string				;
;		 si advanced just past end of parm			;
;		cy if error						;
;		 ax = 3 (rc_gerr)					;
;		 si undefined						;
;									;
; NOTES: suitable as a type checking procedure for the parsing engine.	;
; this proc does not require 4 digits.  checks are made for overflow	;
; out of a word and a proper terminating character.  calls testdelim.	;
;-----------------------------------------------------------------------;
	assume	ds:nothing,es:nothing,ss:nothing
hex2word:
	push	cx
	xor	ax,ax		; ax will contain the result
	mov	ch,ah
	mov	cl,[si]
	cmp	cl,'0'		; validate first char
	jb	htbx
	cmp	cl,'9'
	jbe	htbloop
	and	cl,0dfh
	cmp	cl,'A'
	jb	htbx
	cmp	cl,'F'
	ja	htbx
htbloop:			; si is source address
	mov	cl,[si]
	cmp	cl,'0'
	jb	htbwrap 	      ; 00-2f
	cmp	cl,'9'
	jbe	htb1
	and	cl,0dfh
	cmp	cl,'A'
	jb	htbwrap 	      ; 3a-40
	cmp	cl,'F'
	ja	htbwrap 	      ; 41-46
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
	push 	ax
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

	subttl dec2word - convert a decimal string to a word
	page
;- DEC2WORD ------------------------------------------------------------;
; entry parms:	ds:si -> string to convert				;
;									;
; exit parms: 	nc if no error						;
;		  ax = binary value					;
;		  ds:si -> first char after parameter			;
;		cy if error						;
;		  ax = 3  (rc_gerr)					;
;		  si undefined						;
;									;
; NOTES: suitable as a type checking procedure for the parsing engine.	;
;-----------------------------------------------------------------------;
	assume	ds:nothing,es:nothing,ss:nothing
dec2word:
	push	cx
	push	dx
	xor	ax,ax		; ax will contain the result
	mov	ch,ah
	mov	cl,[si]
	cmp	cl,'0'		; validate the first digit
	jb	dtbx
	cmp	cl,'9'
	ja	dtbx
dtbloop:			; bx is source address
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
	mov	ax,3		; rc_gerr
dtbxx:
	pop	dx
	pop	cx
	ret

	subttl get_paddr - get a port address parameter
	page
;- GET_PADDR -----------------------------------------------------------;
; entry parms:	ds:si -> parameter string to convert			;
;									;
; exit parms: 	nc if no error						;
;		 ax = port address					;
;		 si advanced just past end of parm			;
;		cy if error						;
;		 ax = 3 (rc_gerr)					;
;		 si undefined						;
;									;
; NOTES: suitable as a type checking procedure for the parsing engine.	;
; calls hex2word. leaves direction flag set to up.			;
; checks for a parameter of the type   /AD=hhhh				;
;-----------------------------------------------------------------------;
	assume	ds:nothing,es:nothing,ss:nothing
get_paddr:
	cld
	lodsb
	xif al != '/' then gpd01
	mov	ax,'DA'
	call	chk_paire
	xif flags == nz then gpd01
	call	hex2word
	ret				; return with flags and ax from hex2word
gpd01:					; cy exit handler
	mov	ax,3
	stc
	ret

	subttl get_ib - get a parameter of type IB=
	page
;- GET_IB --------------------------------------------------------------;
; entry parms:	ds:si -> parameter string to convert			;
;									;
; exit parms: 	nc if no error						;
;		 ax = specified buffer size				;
;		 si advanced just past end of parm			;
;		cy if error						;
;		 ax = 3 (rc_gerr)					;
;		 si undefined						;
;									;
; NOTES: suitable as a type checking procedure for the parsing engine.	;
; calls dec2word.  leaves direction flag set to up.			;
; checks for a parameter of the type   IB=d				;
;-----------------------------------------------------------------------;
	assume	ds:nothing,es:nothing,ss:nothing
get_ib:
	cld
	mov	ax,'BI'
	call	chk_paire
	xif flags == nz then gib01
	call	dec2word
	ret				; return with flags and ax from dec2word
gib01:					; cy exit handler
	mov	ax,3
	stc
	ret

	subttl get_ob - get a parameter of type OB=
	page
;- GET_OB --------------------------------------------------------------;
; entry parms:	ds:si -> parameter string to convert			;
;									;
; exit parms: 	nc if no error						;
;		 ax = specified buffer size				;
;		 si advanced just past end of parm			;
;		cy if error						;
;		 ax = 3 (rc_gerr)					;
;		 si undefined						;
;									;
; NOTES: suitable as a type checking procedure for the parsing engine.	;
; calls dec2word. leaves direction flag set to up.			;
; checks for a parameter of the type   OB=d				;
;-----------------------------------------------------------------------;
	assume	ds:nothing,es:nothing,ss:nothing
get_ob:
	cld
	mov	ax,'BO'
	call	chk_paire
	xif flags == nz then gob01
	call	dec2word
	ret				; return with flags and ax from dec2word
gob01:					; cy exit handler
	mov	ax,3
	stc
	ret

	subttl get_hs - get a parameter of type HS=
	page
;- GET_HS --------------------------------------------------------------;
; entry parms:	ds:si -> parameter string to convert			;
;									;
; exit parms: 	nc if no error						;
;		 al = handshaking letter - in uppercase			;
;		 si advanced just past end of parm			;
;		cy if error						;
;		 ax = 3 (rc_gerr)					;
;		 si undefined						;
;									;
; NOTES: suitable as a type checking procedure for the parsing engine.	;
; leaves direction flag set to up.					;
; checks for a parameter of the type   HS=a				;
;-----------------------------------------------------------------------;
	assume	ds:nothing,es:nothing,ss:nothing

hs_set	db	'NDXPR',0

get_hs:
	cld
	mov	ax,'SH'
	call	chk_paire
	xif flags == nz then ghs01
	lodsb
	xif al == 0 then ghs01
	push	si
	lea	si,[hs_set]
	call	cs_testset
	pop	si
	xif flags == nz then ghs01
	clc
	ret
ghs01:					; cy exit handler
	mov	ax,3
	stc
	ret

	subttl get_cn - get a parameter of type CN=
	page
;- GET_CN --------------------------------------------------------------;
; entry parms:	ds:si -> parameter string to convert			;
;									;
; exit parms: 	nc if no error						;
;		 al = connection type letter - in uppercase		;
;		 si advanced just past end of parm			;
;		cy if error						;
;		 ax = 3 (rc_gerr)					;
;		 si undefined						;
;									;
; NOTES: suitable as a type checking procedure for the parsing engine.	;
; leaves direction flag set to up.					;
; checks for a parameter of the type   CN=a				;
;-----------------------------------------------------------------------;
	assume	ds:nothing,es:nothing,ss:nothing

cn_set	db	'RLT',0

get_cn:
	cld
	mov	ax,'NC'
	call	chk_paire
	xif flags == nz then gcn01
	lodsb
	xif al == 0 then gcn01
	push	si
	lea	si,[cn_set]
	call	cs_testset
	pop	si
	xif flags == nz then gcn01
	clc
	ret
gcn01:					; cy exit handler
	mov	ax,3
	stc
	ret

	subttl parse_exec - main parsing logic
	page
;- PARSE_EXEC ----------------------------------------------------------;
; entry parms:	ds:si -> parameter string to convert			;
;									;
; exit parms: 	nc if ok (and global vars set), else cy if error	;
;-----------------------------------------------------------------------;
	assume	ds:nothing,es:nothing,ss:nothing

markerr	macro	p1, p2		;; p1 is parameter # and p2 is error #
	mov ax,(&p1 shl 8) + p2
	endm

bl_set	db	'BL',0

parse_exec:
	push	ds
	pop	es
	mov	di,si
	mov	cx,0ffffh
	mov	al,13
	repne scasb			; replace the CR terminator with a 0
	mov	byte ptr es:[di-1],0
	call	finddelim
	call	passdelims		; make si point to the first vgna base address

; process p1 - the vgna base address

prx000:
	mov	bx,offset [class_tbl_p1]; setup cs:bx
	mov	di,offset [parm_type_tbl]
	call	fetch_parm
	xif flags == cy else prx005
	lxif ax == rc_eol then prxdone	; eol always ok at the 1st parameter 
	jmp	prxerror
prx005:
	xif [nvgna] == 4 else prx010
	jmp	prxerror
prx010:
	xoif ax test1 <not 03f0h> || ax b 100h else prx015
	jmp	prxerror
prx015:
	mov	cx,4
	push	bx
	mov	bx,ax
	call	chk_cflt		; check for addressing conflicts
	pop	bx
	xif flags == nz else prx020
	jmp	prxerror 
prx020:
	mov	di,cs:[nvgna]
	inc	cs:[nvgna]
	shl	di,1			; derive index into vgnaport table
	mov	cs:[p1p_off],di		; save port offset
	mov	cs:[di+vgnaport],ax	; store the vgna base port
	mov	cs:[p1_val],ax		; save for p2 processing

; process p2 - the vgna keyboard irq

	mov	di,offset [parm_type_tbl]
	call	fetch_parm
	xif flags == cy else prx025
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
	xif flags == cy else prx165
	xif ax == rc_eol else prx150	; if p6 specified, must have
	jmp	prxdone
prx150:
	xif ax == rc_null else prx155
	markerr 7,er_nonull
	jmp	prxerror
prx155:
	push	si			; preserve parse pointer
	mov	al,1			; check for type 1  "/hhhh"
	mov	di,offset [parm_type_tbl]
	call	check_type
	pop	si
	lxif flags == nc then prx000	; recycle to the p1 level
prx160:
	markerr 7,er_inv
	jmp	prxerror
prx165:
	xif cs:[p7_count] == 2 else prx170  ; check for too many /AD='s
	markerr 7,uer_sermax
	jmp	prxerror
prx170:
	inc	cs:[p7_count]

; check for duplicate port address

prx175:
	xif cs:[p7_cflt] test1 cl else prx177
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
	mov	di,cs:[numport]		; need port-1 for calcs
	inc	cs:[numport]
	mov	cl,5			; port table size = 32 bytes
	shl	di,cl			; derive index into port table
	add	di,offset [porttbl]
	or	ax,8000h
	mov	cs:[di].addr,ax		; store the port's address
	mov	ax,cs:[p6_val]
	mov	cs:[di].prtirq,al	; store the port's irq
	mov	cs:[portndx],di		; save port index for lator

; process p8 - vgna serial port options
; NOTE: di is expected to contain the port table index

	xif [numport] == 1 else prx180

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
	xif flags == cy else prx205
	case ax == rc_eol else prx195
	jmp	prxdone
prx195:
	case ax == rc_null else prx200
	markerr 8,er_nonull
	jmp	prxerror
prx200:
	push	si			; preserve parse pointer
	mov	al,1			; check for type 1  "/hhhh"
	mov	di,offset [parm_type_tbl]
	call	check_type
	pop	si
	lxif flags == nc then prx000	; recycle to the p1 level
	push	si			; preserve parse pointer
	mov	al,4			; check for type 4  "/AD=hhhh"
	mov	di,offset [parm_type_tbl]
	call	check_type
	pop	si
	lxif flags == nc then prx145	; recycle to the p7 level
	markerr 8,er_inv
	jmp	prxerror

; cx holds the element number of the group member which matched

prx205:
	mov	di,cs:[portndx]
	case cx == 1 else prx220	; p8a	IB=
	xif cs:[p8a_once] != 0 else prx210
	markerr 9,uer_ibmax
	jmp	prxerror		; more than one p8a per port
prx210:
	xif ax b 16 else prx215
	markerr 9,uer_iblow
	jmp	prxerror		; input buffer must be at least 16 bytes
prx215:
	mov	cs:[p8a_once],1
	mov	cs:[di].ibfsiz,ax
	jmp	prx190
prx220:
	case cx == 2 else prx235	; p8b	OB=
	xif cs:[p8b_once] != 0 else prx225
	markerr 10,uer_obmax
	jmp	prxerror		; more than one p8b per port
prx225:
	xif ax b 16 else prx230
	markerr 10,uer_oblow
	jmp	prxerror		; output buffer must be at least 16 bytes
prx230:
	mov	cs:[p8b_once],1
	mov	cs:[di].obfsiz,ax
	jmp	prx190
prx235:
	case cx == 3 else prx265	; p8c	HS=
	xif cs:[p8c_once] != 0 else prx240
	markerr 11,uer_hsmax
	jmp	prxerror		; more than one p8c per port
prx240:
	mov	cs:[p8c_once],1
	case al == 'N' else prx245
	and	cs:[di].ioprot,0f0h	; clear flags
	jmp	prx190
prx245:
	case al == 'R' else prx250
	or	cs:[di].ioprot,8	; enable rts
	jmp	prx190
prx250:
	case al == 'D' else prx255
	or	cs:[di].ioprot,4	; enable dtr
	jmp	prx190
prx255:
	case al == 'X' else prx260
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

; cx must be 4 (p8d)  CN=

prx265:
	xif cs:[p8d_once] != 0 else prx270
	markerr 12,uer_cnmax
	jmp	prxerror		; more than one p8d per port
prx270:
	mov	cs:[p8d_once],1
	case al == 'L' else prx275
	and	cs:[di].ioprot,not 30h	; conteract any R or T
	jmp	prx190
prx275:
	case al == 'R' else prx280
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
	xif ax == rc_eol else prx295
	jmp	prxdone

; ax must be rc_gerr

prx295:
	push	si			; preserve parse pointer
	mov	al,1			; check for type 1  "/hhhh"
	mov	di,offset [parm_type_tbl]
	call	check_type
	pop	si
	lxif flags == nc then prx000	; recycle to the p1 level
	markerr 13,er_inv
	jmp	prxerror	

; error termination handler
; at this point, al holds the error # and ah is the parameter position
; display parameter postition message,  call report_error (to display 
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
	xif [nvgna] == 0 else prxd01

; setup for default parameters

; default for VGNA is /240,7	

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

	subttl	initvgna - vgna board initialization
	page
;- INITvgna ------------------------------------------------------------;
; entry parms:	bl = starting ws number for board			;
;		cl = number of ws's to init for board			;
;		dx = base address of vgna board 			;
; exit parms: 	none							;
;									;
; NOTES: initialize all ws's for one vgna board				;
;-----------------------------------------------------------------------;
	assume	ds:nothing,es:nothing,ss:nothing
initvgna:
	push	cx
initv1:
	push	dx
	push	cx
	push	bx
	   
	mov	[vgnacur],0ffh		; clear it out so it will always
	mov	al,2			; be set
	sub	al,cl	; so ws0 is skipped if init'ing 2 only
	add	al,bl	; starting bank number
	cmp	[ws0ismc],'Y'
	je	Initv2			; if Paradise VGA is master console
	inc	al			; must add one to work station	
Initv2:
	call	setws
	call	InitBios
Initv3:

	pop	bx
	pop	cx
	pop	dx
	loop	initv1
	pop	cx
	ret

	subttl	initpic - init 8259's and irq vector
	page
;- INITPIC -------------------------------------------------------------;
; entry parms:	al = irq to init					;
;		bx = [ilist?]						;
;		cx = [icnt?]						;
;									;
; exit parms: 	none							;
;									;
; NOTES: crashes ax, bx, cx, dx, di					;
;-----------------------------------------------------------------------;
	assume	ds:nothing,es:nothing,ss:nothing

irqtbl	dw	0,0,irq2_entry,0,0,irq5_entry,0,irq7_entry
	dw	0,0,irq10_entry,irq11_entry,irq12_entry,0,0,irq15_entry

initpic:
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
	mov	al,11110011b		; Only INIT Serials
ipc04:
	out	dx,al
	jmp	$+2
	dec	dx
	mov	al,20h			; issue an eoi
	out	dx,al
ipc05:
	loop	ipc01
	pop	ax
	xif al b 8 else ipc06

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
code	ends
	end
