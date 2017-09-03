	include page.inc
	title	mosint06.asm - io protection logic
comment ^===============================================================
			development specification

 program name:	mos			assigned to: stewart hyde
 module name:	mosint06		assign date: 10/10/88
 entry points:	mosint06		completed:   10/11/88
 entry from:	anywhere
 entry method:	int 06h or int 03h
 calls:		mosddtxx
 purpose:	provides io protection on video, io ports so that we
		can provide necessary simulation for these ports
 refer to:	n/a
 last update:	08/18/1992
========================================================================

sah 10/16/88	correct my mistake with gvram declaration. sorry.

sah 12/16/88	added function 4 to initioptbl to initialize non-video
		io protection. this was necessary for the sunriver ega
		station because it handles the video ports itself.

rdg 03/01/89	corrected the code in trap3d8 so that trapped cga mode
		changes are handled properly.

sah 03/27/89	change int 6 to call special int 24 handler, so that
		mos appears to be in control to user.

mjs 06/19/89	add code to initioptbl to reset the tcbpalfg and the
		tcbovsfg when ega i/o trapping is turned on.

mjs 06/28/89	remove code in initioptbl to reset the tcbpalfg and the
		tcbovsfg when ega i/o trapping is turned on.

mjs 07/14/89	added code to manage trapping on 03da when the palovr
		flag is set.  this flag will be set by pamswitching
		when setegapal is called.  it is also set when mosddtmc
		passes on an int10fun10 call.

bwr 11/28/89	marked messages for foreign language translation.

sah 12/05/89	added corrections to non-video io trapping function 4
		for vgna, making sure it turn off un used io.

sah 12/29/89	corrections for atm vga board which does i/o to mono
		ports on color vga monitor during int 10 function 10h
		made corrections to 7/14/89 additions to handle both
		mono and color ports (3ba and 3da).  previous state of
		both ports io protection is save. (omniline)

mjs 05/17/90	modified irq list entry (two fields now abandoned)

mjs 07/06/90	overhauled i/o trapping logic.  implemented repne scasw
		lookup method.  much faster and cleaner.
		also, removed i/o trapping for 3d9, 3db and 3dc
		since no one knew why this logic was in here.

mjs 07/11/90	move isega, egaon/off in here.  clean up initioptbl.
		create set_trap.  fix oversight bugs from recent int6
		overhaul.

mjs 07/17/90	add new trapping logic for port 60 to accomplish keyboard
		rate control.  modify set_trap to control the scbout60
		flag.  added port 64 trapping.

mjs 08/15/90	corrections to set_trap to handle vna workstations.
		added 3x4/3x5 logic to handle cursor type programming.

mjs 08/29/90	corrects so that i/o trapping is not on when the master 
		console is the only watcher of a cga background which is 
		in a cga graphics mode.  this problem was causing the master 
		console video to garbage-up when a program switched from 
		cga graphics mode back to 80x25 color text mode.

SAH 12/27/90	Corrections for VnaPlus/Maxstation and VGA IO protection
		on cursor  position so that work station is switch in
		before calling ddt.

SAH 01/08/91	Corrections for Cursor problem when MOS Vmode Mono is
		used.  IO protection was not on.

SAH 01/09/91    Remove TCBVRAM Bit 2 usage for SunRiver and function
	 	4 of initioptbl

mjs 01/21/91	added a "je askipcrs" below the label "aendcrs:"
		this was forgotten in sah's recent modifications.

mjs 02/21/91	trimmed code out of initioptbl pertaining to scbegaio
		and scbioflg.  these two variables are no longer used.
  		patch 33 overwrites initioptbl with a new shrunken
		version to create a patch pocket.
  
SAH 03/20/91	Use SCBIOPTR for accessing IO protection table 

SAH 03/27/91	Use word access instead of byte access

mjs 08/09/91	added an entry to the trapaddr and traphndlr lists
		for port 43.  this was overlooked when I overhauled
		the trapping code back on 07/06/90.

================ 5.01 Kernel Ends Here ====================================

mjs 08/18/92	clean up segment declarations

mjs 08/26/92	delete reference to scbfree

=======================================================================^

.xlist
;	include mosint06.pub
	include group.inc
	include macros.inc
	include mosregs.inc

tcb	segment at 1234h
	include mostcb.inc
tcb	ends

gdata	segment
	include mosscbex.inc
gdata	ends
.list

gdata	segment
	extrn palovr:byte
gdata	ends

	subttl	irq segment - sepcify a system interrupt handler for mossaver
	page
irq	segment

	dw	3*4
i3old	dd	?
i3sav	dw	0
i3new	dw	mos:mosint3
i3new2	dw	0

	dw	06h*4			; the protection interrupt
	dd	?
	dw	0
	dw	mos:mosint06		; initial value is here
	dw	0

irq	ends

if 0 eq 0
bios	segment at 40h

	org	10h
bioeqp	db	?

	org	17h
kbshft	db	?
kbshftx db	?
altval	db	?
kbhead	dw	?
kbtail	dw	?
kbbf	db	16 dup(?)

	org	49h
biomode db	?
biocols db	?
	db	?
biopgln dw	?
biopgst dw	?
biocpos dw	8 dup(?)
bioctyp dw	?
biopage db	?
biocrt	dw	?
bio3x8	db	?
biopal	db	?

	org	6ch
biotime dd	?
biotrol db	?

bios	ends
endif

;======================================================== mos segment
if 0 eq 0
segment_num = 1
endif
mosseg	segment
	assume	cs:mos,ds:grp,es:nothing,ss:tcb

	extrn	mosend:byte, mo2seg:word, sbios:word
	extrn	mossaver:near,mosrestore:near,noswitch:near,okswitch:near
	extrn	ddtcallf:near,hex2asc:near

	public initioptbl,isega,egaon,egaoff,set_trap,mosint06

err06tb dw	msg060
	dw	msg061
	dw	msg062
msg060	db	'Application attempted to write outside of task space.$           ' ;@@XLAT
msg061	db	'Invalid instruction encountered in application.$          '  ;@@xlat
msg062	db	'General software error occured.$      '  ;@@xlat
psint02 dw	0,0

int3ofs dw	mo2:crtint3

	subttl initioptbl - manipulate the i/o permission map
	page
;======================================================================
;.fs
; initioptbl - manipulate the i/o permission map
;
; in:	al = 0 clear video and sound bits
;	al = 1 set video and sound bits
;	al = 2 clear ega video bits
;	al = 3 set ega video bits
;
; out:
;
;.fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:nothing
initioptbl proc near
	push	si
	push	ds
	push	es
	call	noswitch		; no switching
	mgetscb es			; change to es
	assume	es:grp			; change to ed
	test	[scbmmfea],40h		; is io protection supported
	jz	inpx
	lds	si,[scbioptr]		; get pointer to memman data
	assume	ds:nothing
	or	al,al
	jz	inp0
	cmp	al,1
	je	inp1
	cmp	al,2
	je	inp2
	jmp	short inp3

;=========== function 0 - clear video and sound bits

inp0:
	and	byte ptr [si+12],not 00000010b   ; 61
	and	word ptr [si+118],not 1000010100110000b ;3b8,3ba,3bf,3b4,3b5
	and	word ptr [si+122],not 0000010100110000b ;3d8,3da,3d4,3d5
	and	word ptr [si+120],not 1100000000110111b ;3ce,3cf,3c0,3c1,3c2,3c4,3c5
	jmp	short inpx

;=========== function 1 - set video and sound bits

inp1:
	or	byte ptr [si+12],00000010b       ; 61
	or	word ptr [si+118],1000010100110000b   ;3b8,3ba,3bf,3b4,3b5
	or	word ptr [si+122],0000010100110000b   ;3d8,3da,3d4,3d5
	and	word ptr [si+120],not 1100000000110111b ;3ce,3cf,3c0,3c1,3c2,3c4,3c5
	jmp	short inpx

;=========== function 2 - clear ega video bits

inp2:
	and	word ptr [si+120],not 1100000000110111b ;3ce,3cf,3c0,3c1,3c2,3c4,3c5
	and	byte ptr [si+123],not 00000100b  ; 3da
	jmp	short inpx

;=========== function 3 - set ega video bits

inp3:
	or	byte ptr [si+119],00000100b  ; 3ba
	or	word ptr [si+120],1100000000110111b     ;3ce,3cf,3c0,3c1,3c2,3c4,3c5
	or	byte ptr [si+123],00000100b  ; 3da

;	jmp	short inpx

;$$$$$$ un-rem this line when add inp4 !!!!!!!!!!!!!!!

;=========== termination point

inpx:
	push	es			; protect 3ba while
	mov	es,[scbtcbpc]		; hercules enabled for
	assume	es:tcb			; current partition
	test	[tcbvideo],30h
	pop	es
	assume	es:grp
	jz	inpz			; (z if not enabled)
	or	word ptr [si+118],1000010100110000b  ;3b8,3ba,3bf,3b4,3b5
inpz:
	call	okswitch		; ok to switch
	pop	es
	pop	ds
	pop	si
	ret
initioptbl endp

	subttl isega - test for ega
	page
;======================================================================
;.fs
; isega - test for ega
; 
; in:	es -> tcb
; 
; out:	return non-zero flag is in ega vidram mode
; 
;.fe
;======================================================================
 	assume	ds:nothing,es:tcb,ss:nothing
isega proc near
	cmp	[tcbstate],0		; test for state stuff
	je	isega1
	test	[tcbvideo],4		; test for mos vmode ega
isega1:
	ret
isega endp

	subttl egaon - activate ega i/o protection
	page
;======================================================================
;.fs
; egaon - activate ega i/o protection
; 
; in: 	ax -> tcb
;
; out:	
; 
;.fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:nothing
egaon proc near
	push	es
	mov	es,ax
	assume	es:tcb,ds:nothing
	call	isega			; test for ega
	jz	egaoff1
	mov	al,3
	call	initioptbl		; turn on ega io ports
	pop	es
	ret
egaon endp

	subttl egaoff - deactivate ega i/o protection
	page
;======================================================================
;.fs
; egaoff - deactivate ega i/o protection
; 
; in: 	ax -> tcb
; 
; out:	
; 
;.fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:nothing
egaoff proc near
	push	es
egaoff1:
	mov	es,ax
	assume	es:tcb
	mov	al,2
	call	initioptbl		; turn off ega io
egaoff2:
	pop	es
	ret
egaoff endp

	subttl set_trap - set the trapping state for a task
	page
;======================================================================
;.fs
; set_trap - set the trapping state for a task
;
; in:	ds-> grp
;	ss-> current tcb
;
; out:
;
;.fe
;======================================================================
	assume	ds:grp,es:nothing,ss:tcb
set_trap proc near
	pushset	ax,bx,es
	test	[scbmmfea],40h		; is i/o trapping supported ?
	jz	stp6
	mov	[scbout60],0		; presume to not pass port60 i/o 
	mov	bx,ss
	cmp	[scbtcbpv],bx
	jne	stp7			; mc not watching

; at this point, the master console is one of the watchers

	mov	[scbout60],1		; flag that port 60 i/o goes thru.
	cmp	[scbmconly],0
	je	stp1

; at this point, the master console is the only watcher
; if the one and only watcher is the master console and, if watcher's
; original mode doesn't match task's current mode then need trapping

	mov	es,[tcbscrdd]
	assume	es:tcb,ss:nothing	
	mov	al,[tcbomode]
	assume	es:nothing,ss:tcb
	cmp	[tcbmode],7
	jne	stp5
	cmp	al,[tcbmode]
	jne	stp1
stp5:
	xor	al,al			; turn off trapping
	jmp	short stp4
stp7:
	test	[tcbvideo],30h		; if in vmo hg1 or hg2
	jnz	stp1			; need trapping											       
	cmp	[tcbconly],0		; if not a single con-only watcher
	jne	stp5			; need trapping
stp1:
	mov	al,1			; set normal io protection
stp4:
	assume	es:nothing,ss:tcb
	call	initioptbl
	mov	ax,ss			; ax <--- tcb (in ss)
	call	egaon			; condition ega on
stp6:
	popset	ax,bx,es
	ret
set_trap endp

	subttl	mosint06 - the protection interrupt
	page
;======================================================================
;.fs
; mosint06 - the protection interrupt
;
; this routine is responsible for cleaning up when "the shit
; hits the fan", that is when an application (or mos for that
; matter) attempts to write over memory outside of its task
; space, execute and invalid instruction, or write to
; protected memory (or port).	basically the application has
; crashed and this routine will attempt to save the system
; from doing the same.
;
; control will be passed to this routine upon the occurance of 
; one of the following:
;
; 1) attempt was made to write to protected memory
;     (as set by memman function 6)
;
; 2) attempt was made to write to a protected port
;     (as set by memman function 8)
;
; 3) a processor exception occured
;
; in:	parm6ec (memman header) contains error code
;	parm6adr contains memory address of write (type 1)
;	tasks cs and ip are on the stack (as a normal int)
;
; out:
;
;.fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:nothing
mosint06 proc  near
	push	bp			; [bp+2] -> ip
	mov	bp,sp			; [bp+4] -> cs
	push	ds			; [bp+6] -> flags
	push	es
	db	0fh,0a0h		; push fs
	push	si
	push	dx
	push	cx
	push	bx
	push	ax
	mgetscb ds
	assume	ds:grp

; if the palette override flag is set, enable interrupts to compensate
; for video bios logic which keeps interrupts disabled for too long
; when a set palette call is being made

	cmp	[palovr],0
	je	i6novp
	sti
i6novp:
	mov	es,[scbtcbpc]
	assume	es:tcb
	lds	si,[scbmmptr]		; get pointer to memman data
	assume	ds:nothing
	mov	ax,[si].parm6ec		; get error code
	cmp	ax,3
	jb	$+5
	jmp	mosi6prt		; handle port stuff

; allow periscope to come up at the location which cause the the exception

	push	ax
	push	si
	push	es
	mgetscb es
	assume	es:grp
	cmp	word ptr [scbdump+2],0
	je	nodumper
	mov	ah,2
	call	dword ptr [scbdump]
nodumper:
	mgetzero es
	assume	es:nothing
	les	si,es:[2*4]		; check to see if periscope is installed
	cmp	word ptr es:[si],0b450h
	jne	skipperi

; periscope is installed, now cause an int 02 at invalid instruction

	mov	word ptr cs:[psint02+2],es
	mov	word ptr cs:[psint02],si
	pop	es
	pop	si			;\
	pop	ax			; \
	pop	ax			;   restore registers (like it was)
	pop	bx			; /
	pop	cx			;/
	pop	dx
	pop	si
	db	0fh,0a1h		; pop fs
	pop	es
	pop	ds
	pop	bp
	jmp	dword ptr cs:[psint02]	;   jump into periscopes int 02 handle
skipperi:
	pop	es
	assume	es:tcb
	pop	si

; do normal exception message

	pop	ax			; get error code back
	mov	bx,offset err06tb
	add	ax,ax			; word table
	add	bx,ax
	mov	dx,cs:[bx]
	push	cx
	push	es
	mgetscb es
	assume	es:grp
	cmp	word ptr [scbcin24+2],0	; special handler installed!
	jz	int06s24
	push	ds
	mov	ds,[scbtcbpc]
	assume	ds:tcb
	mov	al,[tcbmode]
	cmp	al,4			; mode < 4, no mode change
	jb	int06nmc
	cmp	al,7			; mode 7, no mode change
	je	int06nmc
	mov	ax,3
	int	10h			; set to mode to text
int06nmc:
	mov	cx,ds			; make cx -> tcb
	mov	ah,0fdh
	mov	bx,cs			; make bx:si point to error string
	push	[tcbstkp]
	sub	[tcbstkp],128
	push	ds
	pushf
	call	[scbcin24]		; call command processor
	pop	ds
	pop	[tcbstkp]
	cmp	[tcbcamon],0ffh		; user selected restart
	jne	int06nrst
	inc	byte ptr [scbrstrtc]
int06nrst:
	pop	ds
	assume	ds:nothing
int06s24:
	pop	es
	pop	cx

; we are terminating, therefore we do not care about stack or
; any registers being restored for app.

	mov	ax,4c01h
	int	21h			; simple termination

;======================================================================
; mosi6prt - trapping logic for i/o ports
;
; when an i/o operation with an immediate operand is trapped, that
; operand is contained in the byte [si].parm6adr + 1
;
; in:	dx = port address
;	es -> tcb
;	ds:si -> memman data structure
;	ax = code describing type of i/o instruction trapped:
;
;	ax = 3 - in al,xx	ax = 7 - in al,dx
;	     4 - in ax,xx	     8 - in ax,dx
;	     5 - out xx,al	     9 - out dx,al
;	     6 - out xx,ax	    10 - out dx,ax
;
;======================================================================
	assume	ds:nothing,es:tcb,ss:nothing
mosi6prt:

; if type 3,4,5 or 6 then put the address in dx to simplify testing

	cmp	al,7
	jae	mosi6a
	mov	dl,byte ptr [si].parm6adr+1
	xor	dh,dh
	sti
mosi6a:

; bump ip past the current instruction

	inc	word ptr [bp+2]
	cmp	ax,7			; if this is a two byte version
	jae	m6skip2			; then bump ip again
	inc	word ptr [bp+2]   
m6skip2:

; scan the trapaddr list to find the offset of the handler
; for this event.

	push	di
	push	es
	push	ax
 	mov	ax,dx
 	mov	di,offset trapaddr
 	mov	cx,cs
 	mov	es,cx
 	mov	cx,trapcnt/2
 	cld
 	repne	scasw
 	jnz	mosi6z
	mov	bx,cs:[di+(trapcnt-2)]

; set the zr flag if this is an input operation

	pop	ax
	mov	cx,4
	mov	di,offset inp_list
	repne	scasb
	pop	es
	pop	di
	db	0fh,0b4h,74h		; lfs si,dword ptr [si].parmiop
	db	parmiop
	mgetscb	ds
	assume	ds:grp
	cli
	mov	cx,ax			; type code to cx
	pop	ax			; retrieve original entry ax

;======================================================================
; enter the handler with:
;
;   ax = the original ax value
;   dx = the original dx i/o trap address 
;   cx = the type code 
;   ds -> grp
;   es -> tcb
;   fs:si -> the iop table
;   zr = 1 if the type code is in [3,4,7,8]  (for an input operation)
;   interupts disabled
;======================================================================

	jmp	bx
mosi6z:
	popset ax,di,es,ax
	jmp	mosi6x

inp_list db	3,4,7,8

; the following address list must match the order of the following
; list of handler offsets.  entries should be ordered by most needed
; first  (e.g. ega video first).

; NOTE: these two tables must remain adjacent - no intervening stuff!

trapaddr label word
	dw	03ceh
	dw	03cfh
	dw	03c0h
	dw	03c1h
	dw	03c2h
	dw	03c4h
	dw	03c5h
	dw	03b4h
	dw	03b5h
	dw	03b8h 
	dw	03bah
	dw	03bfh
	dw	03d4h
	dw	03d5h
	dw	03d8h
	dw	03dah
	dw	0021h
	dw	0040h
	dw	0042h
	dw	0043h
	dw	0060h
	dw	0061h
	dw	0064h

trapcnt equ	$-trapaddr

traphndlr label word
	dw	trap03ce
	dw	trap03cf
	dw	trap03c0
	dw	trap03c1
	dw	trap03c2
	dw	trap03c4
	dw	trap03c5
	dw	trap03x4		; 03b4
	dw	trap03x5		; 03b5
	dw	trap03x8		; 03b8
	dw	trap03xa		; 03ba
	dw	trap03bf
	dw	trap03x4		; 03d4
	dw	trap03x5		; 03d5
	dw	trap03x8		; 03d8
	dw	trap03xa		; 03da
	dw	trap0021
	dw	trap0040
	dw	trap0042
	dw	trap0043
	dw	trap0060
	dw	trap0061
	dw	trap0064

;============

	assume	ds:grp,es:tcb,ss:nothing
trap0021:
	jz	t0021_input

; process an output to port 0021

	or	al,2			; make sure that irq 1 is disabled
	db	64h			; fs override
	and	byte ptr [si+4],not 00000010b  ; clear bit for port 21
	out	21h,al
	db	64h			; fs override
	or	byte ptr [si+4],00000010b	  ; set again
	jmp	mosi6x

; process an input from port 0021

	assume	ds:grp,es:tcb,ss:nothing
t0021_input:
	db	64h			; fs override
	and	byte ptr [si+4],not 00000010b  ; clear bit for port 21
	in	al,21h
	db	64h			; fs override
	or	byte ptr [si+4],00000010b	  ; set again
	jmp	mosi6x

;============

	assume	ds:grp,es:tcb,ss:nothing
trap0040:
	jz	t0040_input

; process an output to port 0040

	xor	bh,bh
	mov	bl,[scbttrap1]		; derive index into tcbl40
	and	bx,1			; 0 -> 0,  1 -> 1,   2 -> 0
	add	bx,offset tcbl40
	mov	es:[bx],al		; save data for task selection
	cmp	[scbttrap1],0		; decrement scbttrap1 only if not
	jz	dtt1a			; already 0.
	dec	[scbttrap1]
dtt1a:
	db	64h			; fs override
	and	byte ptr [si+8],not 00000001b  ; clear bit for port 40
	out	40h,al
	db	64h			; fs override
	or	byte ptr [si+8],00000001b	  ; set again
	jmp	mosi6x

; process an input from port 0040

	assume	ds:grp,es:tcb,ss:nothing
t0040_input:
	cmp	[scbttrap1],0		; decrement scbttrap1 only if not
	jz	dtt1b			; already 0.
	dec	[scbttrap1]
dtt1b:
	db	64h			; fs override
	and	byte ptr [si+8],not 00000001b  ; clear bit for port 40
	in	al,40h
	db	64h			; fs override
	or	byte ptr [si+8],00000001b	  ; set again
	jmp	mosi6x

;============

	assume	ds:grp,es:tcb,ss:nothing
trap0042:
	pushf
	cmp	[scbttrap2],0		; decrement scbttrap2 only if not
	jz	dtt2a			; already 0.
	dec	[scbttrap2]
dtt2a:
	popf
	jz	t0042_input

; process an ouput to port 0042

	db	64h			; fs override
	and	byte ptr [si+8],not 00000100b  ; clear bit for port 42
	out	42h,al
	db	64h			; fs override
	or	byte ptr [si+8],00000100b  ; set again
	jmp	mosi6x

; process an input from port 0042

	assume	ds:grp,es:tcb,ss:nothing
t0042_input:
	db	64h			; fs override
	and	byte ptr [si+8],not 00000100b  ; clear bit for port 42
	in	al,42h
	db	64h			; fs override
	or	byte ptr [si+8],00000100b  ; set again
	jmp	mosi6x

;============

	assume	ds:grp,es:tcb,ss:nothing
trap0043:
	jz	t0043_input

; process an ouput to port 0043

	push	ax			; trap cntrl byte writes to hte 8253.
	mov	ah,al
	test	al,11000000b		; test for channel 0 operation
	jnz	mosi643a
	mov	bx,offset scbttrap1
	mov	[tcbl43],al		; save for task selection logic
	jmp	mosi643b
mosi643a:
	and	al,11000000b
	cmp	al,10000000b		; test for channel 2 operation
	mov	al,ah
	jne	mosi643d		; skip to pass on the output
	mov	bx,offset scbttrap2
mosi643b:
	mov	byte ptr [bx],1
	and	al,00110000b		; test for 1 or 2 byte sequence
	jz	mosi643c
	cmp	al,00110000b
	jne	mosi643d
mosi643c:
	mov	byte ptr [bx],2
mosi643d:
	pop	ax
	db	64h			; fs override
	and	byte ptr [si+8],not 00001000b  ; clear bit for port 43
	out	43h,al
	db	64h			; fs override
	or	byte ptr [si+8],00001000b  ; set again
	jmp	mosi6x

; process an input from port 0043

	assume	ds:grp,es:tcb,ss:nothing
t0043_input:
	jmp	mosi6x

;============

	assume	ds:grp,es:tcb,ss:nothing
trap0060:
	jz	t0060_input

; process an ouput to port 0060

	cmp	[scbkbrate],0ffh	; are output controls active?
	lje	mosi6x
	cmp	[tcbkbstg],2		; have we just seen a two step cmd?
	jne	t0060b
	mov	[tcbkbstg],1		; reset stage tracking
	cmp	[tcbkbcmd],0f3h		; processing an repeat rate command?
	jne	t0060c
	mov	[tcbkbrate],al		; yes, record the rate
	jmp	short t0060c
t0060b:
	mov	[tcbkbcmd],al		; not in second stage so record cmd
	cmp	al,0f3h			; is it a two step?
	je	t0060d
	cmp	al,0edh
	jne	t0060e
t0060d:
	mov	[tcbkbstg],2		; mark as a two step command
	jmp	short t0060c
t0060e:
	cmp	al,0f5h			; is it a command that restores 
	je	t0060f			; the default repeat rate?
	cmp	al,0f6h
	je	t0060f
	cmp	al,0ffh
	jne	t0060c
t0060f:
	mov	cl,[scbkbrate]		; re-instate the default
	mov	[tcbkbrate],cl
t0060c:
	cmp	[scbout60],0		; supposed to pass i/o to hardware?
	lje	mosi6x
	db	64h			; fs override
	and	byte ptr [si+12],not 00000001b  ; clear bit for port 60
	out	60h,al
	db	64h			; fs override
	or	byte ptr [si+12],00000001b  ; set bit for port 60
	jmp	mosi6x

; process an input from port 0060

	assume	ds:grp,es:tcb,ss:nothing
t0060_input:
	cmp	[scbin60],0		; supposed to pass i/o to hardware?
	jne	t0060a
	mov	al,[tcbtrapcd]		; get the scan code to present
	jmp	mosi6x
t0060a:
	db	64h			; fs override
	and	byte ptr [si+12],not 00000001b  ; clear bit for port 60
	in	al,60h
	db	64h			; fs override
	or	byte ptr [si+12],00000001b  ; set bit for port 60
	jmp	mosi6x

;============

	assume	ds:grp,es:tcb,ss:nothing
trap0061:
	jz	t0061_input

; process an ouput to port 0061
; save the output data for use with the input simulation

	mov	[tcbprt61],al
	jmp	mosi6x

; process an input from port 0061

	assume	ds:grp,es:tcb,ss:nothing
t0061_input:
	mov	al,[tcbprt61]		; provide simulated status for an in al,61h
	and	al,3fh			; make sure high bit is clear
	xor	[tcbprt61],10h
	jmp	mosi6x

;============

	assume	ds:grp,es:tcb,ss:nothing
trap0064:
	jz	t0064_input

; process an ouput to port 0064

	cmp	[scbout60],0
	lje	mosi6x
	db	64h			; fs override
	and	byte ptr [si+12],not 00010000b  ; clear bit for port 64
	out	64h,al
	db	64h			; fs override
	or	byte ptr [si+12],00010000b  ; set bit for port 64
	jmp	mosi6x

; process an input from port 0064

	assume	ds:grp,es:tcb,ss:nothing
t0064_input:
	cmp	[scbout60],0
	je	t0064a
	db	64h			; fs override
	and	byte ptr [si+12],not 00010000b  ; clear bit for port 64
	in	al,64h
	db	64h			; fs override
	or	byte ptr [si+12],00010000b  ; set bit for port 64
	jmp	mosi6x
t0064a:
	xor	al,al			; return safe data
	jmp	mosi6x

;============

	assume	ds:grp,es:tcb,ss:nothing
trap03x4:
	jz	t03x4_input

; process an ouput to port 03x4

	push	ax
	and	al,1fh
	mov	[tcbt3x4],al		; save index in tcb
	pop	ax
	jmp	mosi6x			; was mosi6x

; process an input from port 03x4

	assume	ds:grp,es:tcb,ss:nothing
t03x4_input:
	mov	al,80h			; provide 80h as al value
	jmp	mosi6x			; get out of here

;============

	assume	ds:grp,es:tcb,ss:nothing
trap03x5:
	ljz	t03x5_input

; process an ouput to port 03x5

	push	ax
	cmp	[tcbt3x4], 0eh		; is index 0e - set high cpos
	jne	t3x5nhigh
	mov	[tcbtchigh],al		; yes save it
	jmp	short t3x5cset
t3x5nhigh:
	cmp	[tcbt3x4], 0fh		; is index 0f - set low cpos
	jne	aaa1
	mov	[tcbtclow],al		; yes save
	jmp	short t3x5cset
aaa1:
	cmp	[tcbt3x4],0ah
	jne	aaa2
	mov	[tcbtctst],al
	jmp	aaaset
aaa2:
	cmp	[tcbt3x4],0bh
	ljne	t3x5end
	mov	[tcbtctnd],al
	jmp	aaaset
t3x5cset:
	mov	al,[tcbtclow]		; get low cpos
	mov	ah,[tcbtchigh]		; get high cpos
	push	di

; ax = (row*80) + col) + tcbpgst/2

	mov	di,ax
	mov	bx,[tcbpgst]		; get page start
	shr	bx,1
	cmp	ax,bx			; this is possiable if they set
	jb	t3x5c1			; low before the high
	sub	ax,bx			; sub page start if possiable
t3x5c1:
	xor	dx,dx
	mov	cx,80			; divide by 80
	div	cx			;   row in dh
	mov	dh,al			;   col (remainder) already in dl

; save and clear i/o trapping that would interfere if the
; master console happens to be one of the watchers.

	db	64h			; fs override
	push	word ptr [si+118]
	db	64h			; fs override
	push	word ptr [si+122]
	db	64h			; fs override
	and	byte ptr [si+118],not 00110000b  ; clear bit for 3b5,3b4
	db	64h			; fs override
	and	byte ptr [si+122],not 00110000b  ; clear bit for 3d5,3d4
	push	si

; simulate cursor setting

	mov	bl,[tcbpage]
	xor	bh,bh
	mov	[bx+tcbcpos],dx		; save cursor in tcb
	push	es
	mov	es,[sbios]		; point to bios
	mov	word ptr es:[bx+0050h],dx  ; save cpos in bios
	pop	es

; call terminal driver

	mov	al,[scbbankin]
	push	ax
	mov	byte ptr [scbbankin],'N'
	push	word ptr [scblastff]
	mov	si,[tcbscrdd]
	or	si,si
	jz	endcrs	  
termcrs:
	pushset	es,di,dx
	mov	ds,si
	assume	ds:tcb,es:nothing
	mov	si,offset tcbcondd
	test	[tcbvram],80h
	jz	termcrs1
	mov	ah,0ffh
	call	ddtcallf
termcrs1:
	assume  ds:nothing,es:tcb
	shl	di,1			; offset in screen buffer
	mov	[si+4],di
	sub	di,[tcbpgst]
	mov	[si+8],di		; offset into page
	mov	ah,[tcbcols]		; cols per row
	mov	[si+10],ah
	mgetscb es
	assume	es:grp
	mov	es,[scbmastv]
	mov	[si+6],es
	mov	ah,05h
	call	ddtcallf		; check if busy and then call
	popset	es,di,dx
	assume	ds:tcb
	mov	si,[tcbnxtdd]
	or	si,si
	jnz	termcrs
endcrs:
	pop	si			; pop [scblastff], previos value
	MGetSCB ds
	assume  ds:grp,es:nothing
	cmp	si,[scblastff]
	je	skipcrs
	push	ds
	mov	ds,si
	assume  ds:tcb
	test	[tcbvram],80h
	jz	skipff
	mov	si,offset tcbcondd
	mov	ah,0ffh
 	call	ddtcallf
skipff:
	pop	ds
	assume  ds:grp
skipcrs:
	pop	ax
	mov	[scbbankin],al
	pop	si
	db	64h			; fs override
	pop	word ptr [si+122]
	db	64h			; fs override
	pop	word ptr [si+118]
	pop	di
t3x5end:
	pop	ax
	jmp	mosi6x			; was mosi6x

; this code handles trapping for i/o to set the cursor type

	assume	ds:grp,es:tcb,ss:nothing
aaaset:
	mov	ch,[tcbtctst]
	mov	cl,[tcbtctnd]

; save and clear i/o trapping that would interfere if the
; master console happens to be one of the watchers.

	db	64h			; fs override
	push	word ptr [si+118]
	db	64h			; fs override
	push	word ptr [si+122]
	db	64h			; fs override
	and	byte ptr [si+118],not 00110000b  ; clear bit for 3b5,3b4
	db	64h			; fs override
	and	byte ptr [si+122],not 00110000b  ; clear bit for 3d5,3d4
	push	si

; simulate cursor type setting

	mov	[tcbctyp],cx		; save cursor type in tcb
	push	es
	mov	es,[sbios]		; point to bios
	mov	word ptr es:[60h],cx	; save cursor type in bios
	pop	es

; call terminal driver

	mov	al,[scbbankin]
	push	ax
	mov	byte ptr [scbbankin],'N'
	push	word ptr [scblastff]
	mov	si,[tcbscrdd]
	or	si,si
	jz	aendcrs
atermcrs:
	pushset	cx,es
	mov	ds,si
	assume	ds:tcb,es:nothing
	mov	si,offset tcbcondd
	test	[tcbvram],80h
	jz	atermcrs1
	mov	ah,0ffh
	call	ddtcallf
atermcrs1:
	mov	ah,04h
	call	ddtcallf		; check if busy and then call
	popset	cx,es
	mov	si,[tcbnxtdd]
	or	si,si
	jnz	atermcrs
aendcrs:
	pop	si			; pop [scblastff], previos value
	MGetSCB ds
	assume  ds:grp,es:nothing
	cmp	si,[scblastff]
	je	askipcrs
	push	ds
	mov	ds,si
	assume  ds:tcb
	test	[tcbvram],80h
	jz	askipff
	mov	si,offset tcbcondd
	mov	ah,0ffh
 	call	ddtcallf
askipff:
	pop	ds
	assume  ds:grp
askipcrs:
	pop	ax
	mov	[scbbankin],al

	pop	si
	db	64h			; fs override
	pop	word ptr [si+122]
	db	64h			; fs override
	pop	word ptr [si+118]
	jmp	t3x5end

; process an input from port 03x5

	assume	ds:grp,es:tcb,ss:nothing
t03x5_input:
	xor	[tcbprt61],10h		; toggle refresh
	mov	al,80h			; provide default return value
	cmp	[tcbt3x4], 0eh		; is index 0e - set high cpos
	jne	ti3x5a
	mov	al,[tcbtchigh]		; get it for return value
	jmp	mosi6x
ti3x5a:
	cmp	[tcbt3x4], 0fh		; is index 0f - set low cpos
	jne	ti3x5b
	mov	al,[tcbtclow]		; get it for return value
ti3x5b:
	jmp	mosi6x

;============

	assume	ds:grp,es:tcb,ss:nothing
trap03x8:
	jz	t03x8_input

; process an ouput to port 03x8

	pushf				; set up for iret from int3 to mosi6x
	push	cs
	mov	si,offset mos:mosi6x
	push	si
	push	[mo2seg]
	mov	si,offset mo2:crtint3
	push	si
	retf				; calling crtint3, returning to mosi6x

; process an input from port 03x8

	assume	ds:grp,es:tcb,ss:nothing
t03x8_input:
	jmp	mosi6x

;============

fakestat db	11111101b		; show light pen as not active

	assume	ds:grp,es:tcb,ss:nothing
trap03xa:
	jz	t03xa_input

; process an ouput to port 03xa

	jmp	mosi6x

; process an input from port 03xa

	assume	ds:grp,es:tcb,ss:nothing
t03xa_input:

; some video bios code keeps interrupts disabled while polling 03da for a
; vertical sync interval.  this trapping code lets the i/o go through.
; earlier trapping code has enabled interuppts.  here, we simply let the
; call go through.  note that interrupts are turned back off first.

; update 12/29/89 sah: to include support for 3ba, which some vga boards
; will also use, if this support is not added system will lock

	cmp	[palovr],0
	je	mosi6i0
	db	64h			; fs override
	push	word ptr [si+119]
	db	64h			; fs override
	push	word ptr [si+123]
	db	64h			; fs override
	and	byte ptr [si+119],not 00000100b  ; clear bit for port 3ba
	db	64h			; fs override
	and	byte ptr [si+123],not 00000100b  ; clear bit for port 3da
	in	al,dx
	db	64h			; fs override
	pop	word ptr [si+123]
	db	64h			; fs override
	pop	word ptr [si+119]
	jmp	mosi6x
mosi6i0:
	call	isega			; is this ega
	je	mi6fake			; no..then fake it
	push	ds
	call	getstate		; get the state
	jz	t3xaexit
	mov	byte ptr ds:[bx+7], 0	; clear bit
t3xaexit:
	pop	ds
	db	64h			; fs override
	push	word ptr [si+119]
	db	64h			; fs override
	push	word ptr [si+123]
	db	64h			; fs override
	and	byte ptr [si+119],not 00000100b  ; clear bit for port 3ba
	db	64h			; fs override
	and	byte ptr [si+123],not 00000100b  ; clear bit for port 3da
	in	al,dx
	db	64h			; fs override
	pop	word ptr [si+123]
	db	64h			; fs override
	pop	word ptr [si+119]
	jmp	mosi6x
mi6fake:
	mov	al,cs:[fakestat]
	xor	byte ptr cs:[fakestat],9
	test	[tcbvideo],30h		; hercules present bit if vmode hg1 or hg2
	ljz	mosi6x
	xor	byte ptr cs:[fakestat],80h
	jmp	mosi6x

;============

	assume	ds:grp,es:tcb,ss:nothing
trap03bf:
	jz	t03bf_input

; process an ouput to port 03bf

	pushf				; set up for iret from int3 to mosi6x
	push	cs
	mov	si,offset mos:mosi6x
	push	si
	push	[mo2seg]
	mov	si,offset mo2:crtint3
	push	si
	retf				; calling crtint3, returning to mosi6x

; process an input from port 03bf

	assume	ds:grp,es:tcb,ss:nothing
t03bf_input:
	jmp	mosi6x

;============

	assume	ds:grp,es:tcb,ss:nothing
trap03c0:
	jz	t03c0_input

; process an ouput to port 03c0

	call	trap3c0			; do 3c0 trapping
	db	64h			; fs override
	and	byte ptr [si+120],not 00000001b  ; clear bit for port 3c0
	out	dx,al
	db	64h			; fs override
	or	byte ptr [si+120],00000001b  ; set again
	cmp	cx,10			; is this a word out to ega port
	jne	t03c0a			; no skip the following
	inc	dx			; next port
	xchg	al,ah			; place high byte in al simulation
	call	trap3c0			; do 3c1 trapping
	db	64h			; fs override
	and	byte ptr [si+120],not 00000010b  ; clear bit for port 3c1
	out	dx,al
	db	64h			; fs override
	or	byte ptr [si+120],00000010b  ; set again
	xchg	al,ah
	dec	dx
t03c0a:
	jmp	mosi6x

; process an input from port 03c0

	assume	ds:grp,es:tcb,ss:nothing
t03c0_input:
	jmp	mosi6x

;============

	assume	ds:grp,es:tcb,ss:nothing
trap03c1:
	jz	t03c1_input

; process an ouput to port 03c1

	call	trap3c0			; do 3c0 trapping
	db	64h			; fs override
	and	byte ptr [si+120],not 00000010b  ; clear bit for port 3c1
	out	dx,al
	db	64h			; fs override
	or	byte ptr [si+120],00000010b  ; set again
	jmp	mosi6x

; process an input from port 03c1

	assume	ds:grp,es:tcb,ss:nothing
t03c1_input:
	jmp	mosi6x

;============

	assume	ds:grp,es:tcb,ss:nothing
trap03c2:
	jz	t03c2_input

; process an ouput to port 03c2

	push	ax
	mov	[tcb3c2],al		;just remember it for
	db	64h			; fs override
	and	byte ptr [si+120],not 00000100b  ; clear bit for port 3c2
	out	dx,al
	db	64h			; fs override
	or	byte ptr [si+120],00000100b  ; set again
	cmp	cx,10			; is this a word out to ega port
	jne	t03c2a			; no skip the following
	inc	dx			; next port
	mov	al,ah			; place high byte in al simulation
	mov	[tcb3c2],al		;just remember it for
	db	64h			; fs override
	and	byte ptr [si+120],not 00001000b  ; clear bit for port 3c3
	out	dx,al
	db	64h			; fs override
	or	byte ptr [si+120],00001000b  ; set again
	dec	dx
t03c2a:
	pop	ax
	jmp	mosi6x

; process an input from port 03c2

	assume	ds:grp,es:tcb,ss:nothing
t03c2_input:
	db	64h			; fs override
	and	byte ptr [si+120],not 00000100b  ; clear bit for port 3c2
	in	al,dx
	db	64h			; fs override
	or	byte ptr [si+120],00000100b  ; set again
	jmp	mosi6x

;============

	assume	ds:grp,es:tcb,ss:nothing
trap03c4:
	jz	t03c4_input

; process an ouput to port 03c4

	call	trap3c4			; do 3c4 trapping
	db	64h			; fs override
	and	byte ptr [si+120],not 00010000b  ; clear bit for port 3c4
	out	dx,al
	db	64h			; fs override
	or	byte ptr [si+120],00010000b  ; set again
	cmp	cx,10			; is this a word out to ega port
	jne	t03c4a			; no skip the following
	inc	dx			; next port
	xchg	al,ah			; place high byte in al simulation
	call	trap3c4			; do 3c5 trapping
	db	64h			; fs override
	and	byte ptr [si+120],not 00100000b  ; clear bit for port 3c5
	out	dx,al
	db	64h			; fs override
	or	byte ptr [si+120],00100000b  ; set again
	xchg	al,ah
	dec	dx
t03c4a:
	jmp	mosi6x

; process an input from port 03c4

	assume	ds:grp,es:tcb,ss:nothing
t03c4_input:
	jmp	mosi6x

;============

	assume	ds:grp,es:tcb,ss:nothing
trap03c5:
	jz	t03c5_input

; process an ouput to port 03c5

	call	trap3c5			; do 3c5 trapping
	db	64h			; fs override
	and	byte ptr [si+120],not 00100000b  ; clear bit for port 3c5
	out	dx,al
	db	64h			; fs override
	or	byte ptr [si+120],00100000b  ; set again
	jmp	mosi6x

; process an input from port 03c5

	assume	ds:grp,es:tcb,ss:nothing
t03c5_input:
	jmp	mosi6x

;============

	assume	ds:grp,es:tcb,ss:nothing
trap03ce:
	jz	t03ce_input

; process an ouput to port 03ce

	call	trap3ce			; do 3ce trapping
	db	64h			; fs override
	and	byte ptr [si+121],not 01000000b  ; clear bit for port 3ce
	out	dx,al
	db	64h			; fs override
	or	byte ptr [si+121],01000000b  ; set again
	cmp	cx,10			; is this a word out to ega port
	jne	t03cea			; no skip the following
	inc	dx			; next port
	xchg	al,ah			; place high byte in al simulation
	call	trap3ce			; do 3cf trapping
	db	64h			; fs override
	and	byte ptr [si+121],not 10000000b  ; clear bit for port 3cf
	out	dx,al
	db	64h			; fs override
	or	byte ptr [si+121],10000000b  ; set again
	xchg	al,ah
	dec	dx
t03cea:
	jmp	mosi6x

; process an input from port 03ce

	assume	ds:grp,es:tcb,ss:nothing
t03ce_input:
	jmp	mosi6x

;============

	assume	ds:grp,es:tcb,ss:nothing
trap03cf:
	jz	t03cf_input

; process an ouput to port 03cf

	call	trap3cf			; do 3cf trapping
	db	64h			; fs override
	and	byte ptr [si+121],not 10000000b  ; clear bit for port 3cf
	out	dx,al
	db	64h			; fs override
	or	byte ptr [si+121],10000000b  ; set again
	jmp	mosi6x

; process an input from port 03cf

	assume	ds:grp,es:tcb,ss:nothing
t03cf_input:
	jmp	mosi6x

;======================== exit handler ========================

mosi6x:
	pop	bx
	pop	cx
	pop	dx
	pop	si
	db	0fh,0a1h		; pop fs
	pop	es
	pop	ds
	pop	bp
	iret
mosint06 endp

	subttl getstate - get state variable
	page
;======================================================================
;.fs
; getstate - get state variable
;
; in:	es -> tcb
;
; out:	nz if not error
;	ds = state segment
;	bx = 0
;
;.fe
;======================================================================
	 assume es:tcb
getstate proc	near
	 push	ax
	 mov	ax,[tcbstate]
	 or	ax,ax			; state set
	 jz	gstend			; no...skip
	 mov	ds,ax			; place state segment in ds
	 xor	bx,bx			; clear zero flag since all ega io need it
	 cmp	ax,bx			; clear zero flag
gstend:
	 pop	ax
	 ret
getstate endp

	subttl trap3c0 - ega attribute controller
	page
;======================================================================
;.fs
; trap3c0 - ega attribute controller
;
; 3c0 is a toggle port so when application writes the index 
; to the port, the next write will be the value
; 
; state area offsets used:
; 6	 attribute controller index
; 7	 toggle flag (to indicate if setting index or value)
; 8 - 26 attribute controller (index 0 - 18)
;
; sah 10/05/87 now saves values of palletes into tcbegapal array
;
; in:
;
; out:
;
;.fe
;======================================================================
trap3c0 proc	near
	push	bx
	push	ds
	call	getstate		; get the state
	jz	t3c0exit		; not a state then skip
	cmp	byte ptr ds:[bx+7],0
	jne	t3c01
	cmp	al,19
	ja	t3c0exit
	mov	[bx+6],al		; save index
	jmp	t3c0end
t3c01:
	mov	bl, byte ptr ds:[bx+6]
	cmp	bl,18
	ja	t3c0end
	xor	bh,bh
	cmp	bl,17			; is this overscan color
	jne	t3c02
	mov	[tcbegapal+16],al	; store over scan color
	jmp	short t3c03
t3c02:
	cmp	bl,15			; test for index 0 - 16
	ja	t3c03
	mov	[tcbegapal+bx],al	; save value into tcbegapal array
t3c03:
	add	bl,8			; port 3c0 is offset of 8
	mov	ds:[bx],al		; store information in save area
t3c0end:
	xor	bx,bx
	inc	byte ptr ds:[bx+7]	; toggle 3c0 port
	and	byte ptr ds:[bx+7],1
t3c0exit:
	pop	ds
	pop	bx
	ret
trap3c0 endp

	subttl trac3c4 - ega sequencer
	page
;======================================================================
;.fs
; trac3c4 - ega sequencer
;
; state area offsets used:
;  0  sequencer index
;
; in:
;
; out:
;
;.fe
;======================================================================
trap3c4 proc	near
	push	bx
	push	ds
	call	getstate		; get the state
	jz	t3c4exit		; not a state, skip
	mov	byte ptr ds:[bx+0],al	; save sequence index
t3c4exit:
	pop	ds
	pop	bx
	ret
trap3c4 endp

	subttl trap3c5 - ega sequencer
	page
;======================================================================
;.fs
; trap3c5 - ega sequencer
;
; state area offsets used:
;  0   sequencer index (used to set which value)
;  1-5 sequencer controller values
;
; in:
;
; out:
;
;.fe
;======================================================================
trap3c5 proc	near
	push	bx
	push	ds
	call	getstate		; get the state
	jz	t3c5end			; not a state exit
	mov	bl,byte ptr ds:[bx]	; get sequence index
	cmp	bl,4
	ja	t3c5end
	xor	bh,bh
	inc	bx			; sequencer start at offset 1
	mov	ds:[bx],al
t3c5end:
	pop	ds
	pop	bx
	ret
trap3c5 endp

	subttl trap3ce - ega graphics controller
	page
;======================================================================
;.fs
; trap3ce - ega graphics controller
;
; state area offsets used:
;  27	graphics controller index
;
; in:
;
; out:
;
;.fe
;======================================================================
trap3ce proc	near
	push	bx
	push	ds
	call	getstate		; get the state
	jz	t3ceexit		; not a state, exit
	mov	byte ptr ds:[bx+27],al	; save graphics controller index
t3ceexit:
	pop	ds
	pop	bx
	ret
trap3ce endp

	subttl trap3cf - ega graphics controller
	page
;======================================================================
;.fs
; trap3cf - ega graphics controller
;
; state area offsets used:
;   27	  graphics controller index (used to set value)
;   28-36 graphics controller values
;
; in:
;
; out:
;
;.fe
;======================================================================
trap3cf proc	near
	push	bx
	push	ds
	call	getstate		; get the state
	jz	t3cfend			; not a state, exit
	mov	bl,ds:[bx+27]		; get graphics controller index
	cmp	bl,8			; check to see if too big
	ja	t3cfend
	add	bl,28			; graphics controller is offset 28
	xor	bh,bh
	mov	ds:[bx],al		; save value
t3cfend:
	pop	ds
	pop	bx
	ret
trap3cf endp

	subttl mosint3 - video controller trapping
	page
;======================================================================
;.fs
; mosint3 - video controller trapping
; 
; mosint3 just transfers to crtint3 in ddt
;
; in:	
;
; out:	
;
;.fe
;=====================================================================
	assume	ds:nothing,es:nothing,ss:nothing
mosint3:
	push	[mo2seg]
	push	[int3ofs]
	retf

mosseg	ends

;======================================================== ddt segment
if 0 eq 0
segment_num = 2
endif
ddt	segment
	assume	cs:mo2,ds:nothing,es:nothing,ss:nothing

	public	crtint3

	extrn	sbios2:word,farco:far
	extrn	ddtcall:near,cononly:near,gvram:near

	public allowhio,denyhio

	subttl allowhio - allow direct access to hercules ports
	page
;======================================================================
;.fs
; allowhio - allow direct access to hercules ports
;
; in:
;
; out:
;
;.fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:nothing
allowhio proc near
	push	bp
	mov	bp,sp
	sub	sp,4
	mov	[bp-4],ax		; save ax where it can be popped
	mov	ax,[bp]			; move original bp
	mov	[bp-2],ax
	mov	ax,[bp+2]		; move ip
	mov	[bp],ax
	pushset	si,ds
	mgetscb2 ds
	assume	ds:grp
	test	[scbmmfea],40h		; no i/o protection
	jz	allowx
	lds	si,[scbioptr]		; get pointer to memman data
	assume	ds:nothing
	mov	ax,[si+118]
	mov	[bp+2],ax
	and	word ptr [si+118],not 1000010100110000b  ;3b8,3ba,3bf,3b4,3b5
allowx:
	popset	si,ds
	pop	ax			; leave word on the stack
	pop	bp			; for denyhio to read   
	ret
allowhio endp

	subttl denyhio - deny direct access to hercules ports
	page
;======================================================================
;.fs
; denyhio - deny direct access to hercules ports
;
; in:
;
; out:
;
;.fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:nothing
denyhio proc near
	push	bp
	mov	bp,sp
	pushset	si,ds
	mgetscb2 ds
	assume	ds:grp
	test	[scbmmfea],40h		; no i/o protection
	jz	denyx
	lds	si,[scbioptr]		; get pointer to memman data
	assume	ds:nothing
	mov	bp,[bp+4]
	mov	[si+118],bp
denyx:
	popset	si,ds
	pop	bp
	ret	2			; dump the temp storage
denyhio endp

	subttl crtint3 - int 3 interception for i/o trapping to crt controller
	page
;======================================================================
;.fs
; crtint3 - int 3 interception for i/o trapping to crt controller
;
; save all registers, this is interpreting an out dx,al instruction and
; should be assumed to come directly from an application whose out
; dx,al instructions relating to crt controller access have been
; patched with int 3's note in particular, we make (and can make) no
; assumptions about ss
;
; in:	dx = port for output
;	al = value to output
;
; out:
;
;.fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:nothing
crtint3 proc far
	sti
	push	ds
	mgetscb2 ds
	assume	ds:grp
	mov	ds,[scbtcbpc]
	assume	ds:tcb
	test	[tcbvideo],30h		; hercules enabled?
	jz	crtint3a
	cmp	dx,03b8h
	jmpz	crtctrl			; e if crt control port
	cmp	dx,03bfh
	je	crtcfg			; e if crt configuration port
	jmp	crtint3sk
crtint3a:
	cmp	dx,03d8h
	jne	crtint3sk		; e if not cga mode register
	call	trap3d8
crtint3sk:
	pop	ds
	iret
crtcfg:

; setting the hercules configuration port
; bit 0 must be set to allow a hercules mode to be set
; bit 1 must be set to allow a switch to page 1

	push	dx
	mov	[tcb03bf],0
	test	al,01h
	jmpz	crtcfg1

; allow graphics mode set only if enough screen buffer pages (8) and
;   vidram pages (8)

	cmp	[tcbvidp1],8
	jmpb	crtcfg1
	mov	dx,[tcbvmpgs]
	add	dx,[tcbvmpgs+2]
	cmp	dx,8
	jmpb	crtcfg1

; here if enough pages for graphics mode

	or	[tcb03bf],01h		; graphics mode enabled
	test	al,02h
	jz	crtcfg0			; (allow graphics mode anyway)

; need 16 vidram pages to enable second page

	cmp	dx,16
	jb	crtcfg0
	or	[tcb03bf],02h		; pages allowed also
crtcfg0:
	call	cononly
	jnz	crtcfg1
	push	ax
	mov	al,[tcb03bf]
	mov	dx,03bfh
	push	bx
	push	ds
	push	es
	mgetscb2 es
	assume	es:grp
	mov	ds,[scbtcbpf]
	assume	ds:tcb			; if the master console is hercules
	cmp	[tcbcondd.dcpherc],'Y'	; then the second page can be enabled
	je	crtcfg0a
	test	[tcbcondd.dcbios],1	; if not, can it be hidden?
	jz	crtcfg0b		; no (co-resident but not hideable)
	mov	bx,ds			; yes, it can be hidden so now the
	cmp	bx,[scblastff]		; question is  "is it??"
	jne	crtcfg0a
	push	ax
	push	si
	mov	si,offset tcbcondd	; ds already points to the foreground tcb
	mov	ah,0feh
	call	dword ptr [si]		; don't need to use ddtcall here
	pop	si
	pop	ax
	jmp	crtcfg0a
crtcfg0b:
	and	al,not 02h		; can't be enabled - sorry, get a vga or ega
crtcfg0a:
	pop	es
	pop	ds
	pop	bx
	call	allowhio
	out	dx,al
	call	denyhio
	pop	ax
	test	[tcb03bf],02h		; if page bit already set, this bit
	jz	crtcfg1			;   enables it and 2nd page is displayed
	pop	dx
	push	ax
	jmp	crtchg5
crtcfg1:
	pop	dx
	pop	ds
	iret
crtctrl:

; setting the crt controller control port

	push	ax
	xor	al,[tcb03b8]
	test	al,82h			; only concerned with mode and page
	jmpz	crtchgx			; don't care if unchanged from last time
	xor	[tcb03b8],al		; remember it
	test	al,02h
	jmpz	crtchg5			; z if mode didn't change
	test	[tcb03b8],02h
	jmpz	crtchg1			; text mode always allowed
	and	[tcb03b8],not 02h
	test	[tcb03bf],01h
	jmpz	crtchgx			; graphics only allowed if enabled
	or	[tcb03b8],02h
	mov	[tcbmode],80h
	push	es
	push	ds
	pop	es
	assume	ds:nothing,es:tcb
	mov	ax,[tcbscrdd]
	or	ax,ax
	jnz	crtchg2a
	pop	es
	jmp	crtchgy
crtchg2a:
	push	di
	push	si
	push	dx
	push	cx
	push	bx
	mov	cl,[tcbcols]
crtchg2:
	xor	di,di
	xor	dx,dx
	mov	ds,ax
	assume	ds:tcb,es:nothing
	mov	si,offset tcbcondd
	mov	[si+4],di
	mov	[si+8],di		; offset into page
	mov	[si+10],cl
	push	ds
	mgetscb2 ds
	assume	ds:grp
	mov	ax,[scbmastv]
	pop	ds
	assume	ds:tcb
	mov	[si+6],ax
	mov	ax,0380h
	mov	[tcbcmode],al
	test	[tcbvram],10h		;hercules supported?
	jz	crtchg3
	push	cx
	call	ddtcall			; see if ddt busy and call
	pop	cx
crtchg3:
	mov	ax,[tcbnxtdd]
	or	ax,ax
	jnz	crtchg2
crtchg4:

; clear vidram and screen save buffer

	assume	ds:nothing,es:tcb
	push	ds
	mov	ax,es
	mov	ds,ax
	call	cononly
	pop	ds
	jz	crtchg4a
	push	es			;clear screen save buffer if not cononly
	mgetscb2 es
	assume	es:grp
	mov	es,[scbmastv]
	mov	cx,32768/2
	xor	di,di
	xor	ax,ax
	rep	stosw
	pop	es
	assume	es:tcb
crtchg4a:
	test	[tcbvram],01h
	jz	crtchg4c
	call	gvram			;clear vidram if enabled
	xor	di,di
	xor	ax,ax
	mov	cx,32768
	test	[tcbvideo],20h
	jnz	crtchg4b
	shr	cx,1
crtchg4b:
	mov	es,[tcbvidw2]
	rep	stosw
crtchg4c:
	assume	ds:tcb,es:nothing
	pop	bx
	pop	cx
	pop	dx
	pop	si
	pop	di
	pop	es

; set physical page bit if master console only

crtchg5:
	mgetscb2 ds
	assume	ds:grp
	mov	ds,[scbtcbpc]
	assume	ds:tcb
	call	cononly
	jnz	crtchgx

; set active hercules display page through ddt

	cmp	[tcbscrdd],0		; make sure there is a watcher
	je	crtchgx			; or calling the ddt to set the mode will
	push	es			; result in a crash
	push	di
	push	si
	push	dx
	push	cx
	push	bx
	push	ax
	mov	al,[tcb03bf]		; setting bit according to current display
	ror	al,1			;   page
	ror	al,1
	and	al,[tcb03b8]
	and	al,80h
	shr	al,1
	or	al,80h
	mov	ds,[tcbscrdd]
	mov	si,offset tcbcondd
	mov	ah,03h
	test	[tcbvram],10h		; hercules supported?
	jz	crtchg6			; nope
	call	ddtcall			; see if ddt busy and call
crtchg6:
	pop	ax
	pop	bx
	pop	cx
	pop	dx
	pop	si
	pop	di
	pop	es
	jmp	crtchgx
crtchg1:

; here if changing to text mode

	push	es
	mgetzero2 es
	mov	ax,7
	pushf
	cli
	call	dword ptr es:[10h*4]
	pop	es

; if not cononly, switch vidram back in

crtchgx:
	mgetscb2 ds
	assume	ds:grp
	mov	ds,[scbtcbpc]
	assume	ds:tcb
	call	cononly
	jz	crtchgy
	call	gvram
crtchgy:
	pop	ax
	pop	ds
	iret
crtint3 endp

	subttl trap3d8 - cga mode change trapping
	page
;======================================================================
;.fs
; trap3d8 - cga mode change trapping
;
; 		for future reference
; --------------------------------------------------------
; bit 0 -  80 x 25 alpha mode
; bit 1 -  graphics select
; bit 2 -  black/white select
; bit 3 -  enable video signal
; bit 4 -  high res 640 x 200 (b/w) mode
; bit 5 -  backgrount intesity = blink bit
;
; in:	al = value sent to port 3d8
;
; out:
;
;.fe
;======================================================================
	assume	cs:mo2, ds:tcb, es:nothing, ss:nothing
trap3d8 proc	near
	push	ax			; save the original data
	push	dx			; save the port address
	xor	dx, dx			; initialize the new mode value
	and	al, 037h		; save only the mode flags
	test	al, 002h		; is it a graphics mode
	jnz	t3d8gr			; jump if graphics mode
	test	al, 001h		; is it an 80 column text mode
	jz	t3d840			; jump if 80 column mode
	and	al, 03ch		; reset graphics/80 col for next
	inc	dx			; bump past
	inc	dx			;   40 x 25 modes
t3d840:
	cmp	al, 02ch		; is it a black/white text mode
	je	t3d8do			; go set it if black/white text
	inc	dx			; bump it to a color mode
	cmp	al, 028h		; is it a color text mode
	je	t3d8do			; go set it if color text
	jmp	short t3d8ex		; throw it away if invalid
t3d8gr:
	mov	dl, 4			; start at mode 4
	and	al, 01fh		; save only the graphics mode bi
	cmp	al, 00eh		; is it 320 x 200 b/w
	je	t3d8do			; go set it if yes
	inc	dx			; bump it to mode 5
	cmp	al, 00ah		; is it 320 x 200 color
	je	t3d8do			; go set it if yes
	inc	dx			; bump it to mode 6
	cmp	al, 01eh		; is it 640 x 200
	je	t3d8do			; go set it if yes
	jmp	short t3d8ex		; throw it away if invalid
t3d8do:
	push	es			; save es
	mgetzero2 es			; get the segment of intr vector
	mov	ax, dx			; move the mode to al (ah=0)
	or	al, 080h		; don't clear the buffer
	pushf				; save the flags (like int)
	cli				; no interupts (like int)
	call	dword ptr es:[10h*4]	; call the int 10 handler
	pop	es			; restore es
t3d8ex:
	pop	dx			; restore the port address
	pop	ax			; and the data
	ret				; return to caller
trap3d8 endp

ddt	ends
	end

