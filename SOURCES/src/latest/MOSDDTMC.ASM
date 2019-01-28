	include page.inc
	title	mosddtmc.asm - mos master console terminal driver module
comment ^===============================================================
		       development specification

 program name:	mosddtmc.asm		assigned to: jim bean
 module name:	mosddtmc		assign date: 09/30/86
 entry points:	mosterm 		completed:   11/01/86
 entry from:	mosint10, mosint16, mosvidrm
 entry method:	call dword [vector] with ah = function number
 calls: 	i10old (boot interrupt 10h)
 purpose:	mos interface to master console (ibm pc hardware and
		software compatible)
 refer to:	n/a
 last update:	08/18/1992
========================================================================

this module is the mos terminal driver for the master console
it follows the coding standards established in the multilink
operating system project description (section i.d. introduction -
coding standards)

the driver will be opened by mositask which will read a four byte
vector to the function interpretation code

graphics not implemented yet

implementation notes:

key buffer overrun throws away remaining keys and stores an overrun
  char (0ffh) to tell mos to beep if it wants to

key buffer is 32 scan codes (16 make/breaks) long

local printer has no meaning for master console (it is controlled
  along with int 17h)

========================================================================

dam 1/2/87	made segment changes for ddts to reside in grp
		segment to provide more room in code segment.  the ddts
		were already referenced with far calls so they are the
		easiest to change. (so i thought!!)

sah 05/11/87	ega graphics fixes

rbr 05/30/87	corrections to int 15h logic, some of which were
		required to work with zenith 386 bios.

sah 08/14/87	corrected set type if physical mode does not equal
		virtual mode.  code was always acting like they were
		equal.

mjs 8/19/87	add code to mosint09, origin type 2 to insure that the
		keyboard controller chip is enabled and to reset the
		8259.

jrb 10/22/87	small change so current mode is reset when hercules
		mode is attempted, but not supported (so mc pamm'ed
		into hercules partition gets a blank screen)

jrb 10/26/87	added scb variable to signal for i/o protection with
		hercules enabled that i/o is being done by ddtmc and
		is, therefore, ok

jrb 10/29/87	changes to getscr to support hercules graphics mode
		and	correctly support hercules emulation of cga

jrb 11/05/87	use allowhio, denyhio instead of scbhinmc to control
		turning herc i/o prot on/off while in master console

mjs 11/24/87	irma support.  must save 40:19 around the call to the
		bios int9 so irma's pamswitching mods can work.
		because gwbasic's int9 intercept disables the keyboard,
		reads the scan code and then passes on to what it thinks
		is the bios's int9 (leaving the keyboard disabled), I
		had put code into mosint09, origin type 2 to re-enable
		the keyboard.  with irma's int9 handler installed,
		origin type 2 was never used since they totaly take over
		int9 so i had to make sure the keyboard controller was
		reset in origin type 1 also.

sah 12/17/87	additions to support high bit of int 10 calls for acad
		by directly writing to ports if not ega or mode 7

jrb 12/21/87	disallow hercules page 2 access if master console isn't
		hercules-capable

sah 01/21/88	change scbseg and zero seg to mgetxxxx macros
		optimization to routines accessing 40:0050 and calling
		bios.  plus joining routines to turn video off during
		desnow into one call.

mjs 2/16/88	remove int05 and int1b from chain table management
		scheme.  this was initiated as a means of gaining
		compatibility with mfcobol.

rbr/sah 02/20/88 move ddt code to mo2 group.

mjs 3/30/88	converted all calls to swrealram to a new procedure
		called exposreal.  this procedure insures that ax = 0
		ax is a new entry parameter for swrealram.  see the file
		\mos.dir\utils.dir\vidmods.doc on the server for info.

sah 03/31/88	added new ff handler, to switch real ram in.  remove
		condition of ax = 0 for call to swrealram and converted
		exposreal main code which was in swrealram

sah 04/08/88	change old (03/31/88) exposreal to exposit (for mc ff
		call.  new routine exposreal will call master console
		recursivitly to switch real ram in.   i.e can't call
		master console expose routine because it would not
		switch the real ram in for the station (sunriver)
sah 04/11/88	corrections for 04/08/88 code

sah 04/15/88	added special scbvidchk call to tell special video cards
		like #9 card that we are about to do a reboot
		for more information on vidcheck routine see
		vidcheck.doc on the mosutils.dir on the r&d server.

mjs 5/2/88	added support for a ddtlw proc (null case).  modified
		the fun ff code to be secured against video switching
		serial irq's.

jrbv 5/20/88	do swrealram even if scbtcbvr says it doesn't need it
		scbtcbvr might indicate b800 exposed and we need to
		expose b000 for somebody else (like vna)

mjs 5/29/88	corrected the mods made on 5/20/88 (jrbv).  by
		commenting out the mov cx,[scbtcbvr] instruction, there
		was no good value in cx for later use.

jrb 6/13/88	add function 0feh, detect presence of vga bios so fe
		can use enable/disable function, allow 2nd hercules
		page if either, master console is hercules or master
		console is ega/vga, show ega/vga on function ff
		add	dcbios bits (0 for ega bios present, 1 for vga bios
		present, 2 for enhanced display, 7 for currently hidden)

sah 06/17/88	allow int 15 to passed on functions above 8fh (some of
		these are reserved) this is to take account of the ps/2
		bios.  this was necessary for compatiblity with the
		tecmar tape drive for the ps/2 series.

mjs 6/22/88	i was finding some strange problems with the int15
		changes that sah just did (6/17/88) so instead of trying
		to fix the existing int15 logic, i replaced it with
		a version that doesn't use the chain table logic scheme.
		as a result, mos's int15 handler is now very simple.
		also, modified mosint09 so that when the bios's int9
		handler is going to be called, the current int15 vector
		is saved, int15 is pointed to an iret stub, the bios
		is called and then int15 is restored.  this insures
		that we stay in control when the bios int9 is called.
		can't let any int15 intercepts get control at this point

mjs 7/2/88	took out mmparm struc and added 'inlude macros.inc' for
		access to the common mmparm struc.

rdg 07/06/88	gated access to the console device drivers to prevent
		corruption of the serial data stream being sent to a
		terminal by changing the calls to the console device
		driver from a call dword ptr [si] to call ddtcallf

mjs 7/14/88	converted int9 to lidt control scheme.
		also, cleaned out old unused code - can get from pvcs.

mjs 7/22/88	added regrab logic for int9.

mjs 8/10/88	manipulate the inmos flag and tsl8stat to prevent any
		int8's which occur during mosint09 from allowing a
		tsr to pop up.	too many sensitive things going on in
		mosint09 to let a tsr pop up in there.

sjc 8/16/88	bias the stack around the call to i09old. allows lanlink
		to spool across the network on an int5. - bias9
		apparently not necessary - conditional assembly left in

sah 09/08/88	corrections for autocad scrolling and cleanup.

mjs 09/23/88	re-designed bank selection method.  when a ddt is
		called for a video function, it will expose itself and
		bank itself in.  each con-only type of workstation
		stays banked in until a different bankin is needed.
		when a bank selectable workstation is selected, it
		updates scblastff to point to its tcb.	this way, when
		a driver's ff function is called to select it, the ff
		logic can know which driver to call with an fe function.
		this way, the last workstation banked in can always be
		known so it can be banked out when another workstation
		needs to be banked in.	corrected misc bugs.  created
		a ddtlw procedure so the master console's bank
		selection status can be maintained through video
		switching irq's.  Tried to simplify the vidram
		unmapping process but was held up by a very strange
		bug - will go back to it later.

mjs 09/27/88	removed the ddtlw logic since the scblastff variable
		now provides all that the serial irq logic needs in
		order to restore the bank selection state.
		simplify the logic in ddtmc's 0ffh handler which is
		responsible for unmapping the video memory area.  this
		logic had been making a call to scbmmsub when it didn't
		need to.

mjs 10/01/88	modify the bank selection call made when a cntrl-alt-del
		is detected to insure proper rebooting in co-resident
		ega/vna case.

mjs 10/04/88	modify the bank selection logic to never set scblastff
		to a zero value.

rkg 10/06/88	public as necessary for link with .pubs

rkg 10/19/88	ptrxxx print-screen and pause problem with 101 keyboard
		augment bios fakeout and simplify the interrupt code.
		scbinmos no longer modifed and ddtmcbio used to store
		bios variables now put on stack.

rkg 10/31/88	after discussing changes with marty fixed probs with
		previous edit

sah 12/04/88	ps/2 mouse support implemented. basically the ps/2 bios
		calls a far routine set up by int 15 function c2h when
		mouse sends it reported to the servicer. i change
		mosint15 so that it will save current tcb and the far
		call	routine into the scb and sets up mos's PS/2 mouse
		routine (moucall). for information see description of
		of moucall routine inside new module mosnxtsk.asm

sah 01/04/89	corrected int c207 crashing of ds which found while
		developing generic mouse driver interface.

sah 02/03/89	change use of scbvmaal = 0 to use scbbankin so that it
		be compatible with sunriver style workstations

mjs 03/03/89	make the prch and prstr procedures return ah = 1 so
		anyone doing a mos rou term for the foreground when
		not	using an iona unit will get an error window.

mjs 05/17/89	modified the setmode function to test bit 6 of al.  if
		bit 6 is set, set mode but don't clear video ram.
		note: when mosint10 is called with bit 7 of al set, it
		calls the ddt with bit 6 set.  this is done to sidestep
		the fact that calling with bit 7 set on a vna system
		will put you in herc graphics mode.
		also, modified our int15 handler to just iret when an
		int15, function 4f call is make.  this is to insure
		that scan codes are not eaten when they're not supposed
		to be.

mjs 05/26/89	modified my modification from 05/17.  it turns out
		that ddtmc's setmode call uses bit 6 to indicate the
		herc page number.  this was not documented!  i changed
		my code to use bit 5 and changed mosint10 to match.

sah 06/08/89	made changes necessary for addition of mapvma function
		3 for sunriver, which mosddtmc ffh handler does not
		have to unmap memory since srterm take care of it.

sah 06/22/89	create new generic mouse handler during bios device
		waits (int 15 function 90 - which allows us to poll
		mouse driver for any active (mice) task on system while
		bios is waiting for disk io.

sah 06/27/89	made corrections for vmode of ega\vga on monochrome
		systems.  mos never had support for these system, it
		was assume that mono system only had mode 7 (except
		for hercules)

mjs 07/14/89	when passon detects int10 function 10 calls, it calls
		the i10fun10 procedure instead of directly passing on
		the bios int10.  on a 386, this will cause trapping
		to enable interrupts for awhile during each 03da access.

rkg 07/17/89	added function 18 to terminal driver to set/get keyboard
		status.

sah 07/19/89	corrections for using $mouse.sys on ps/2 style hardware

mjs 12/19/89	modified the biosint9 function to save, clear and restore
		the state of i/o trapping for port 61.	this corrected a
		lockup of the foreground when multiple tasks were run
		on a pc using $386.sys and an intel inboard 386/pc.
		also, modified mos's int15 intercept to pass on calls
		to functions 87 through 89 (inclusive) when there is
		no memory management.

sah 01/18/90	remove int 15 logic and place code into new module
		mosint15.asm so that this module can truely be master
		console device driver. this also make int 15 logic
		issolated to one module for better clarity.

cbk 01-22-90	added check for reboot flag at mosi9f3 and if reboot is
		disabled don't react to CTL-ALT-DEL. Done especially for
		emulink which is disabling console reboot.

sah 01/24/90	speeded up video using wordmov calls.

sah 03/09/90	removing write protecting 40:17 via update bios from
		tcbkshft.

mjs 03/16/90	modified interrupt control when int15 is set to a stub
		so the bios int9 can be called.  have to prevent an
		int15fun91 from being lost.

sah 03/20/90	replace code removed on 03/09/90, needs more invest.

sah 05/18/90	skip calling chkherc if ega or vga console

sah 07/06/90	corrections for master console ega test, bl was 10 dec
		should be 10h hex.

sah 07/23/90	cleanup and some optimization, corrections for windows
		on a monochrome vga.

mjs 08/01/90	make biosint09 clear trapping state for port 60.  this
		prevents a problem with maintaining the toggle keys
		when kbrate control is active and more than one task
		exists.

sah 11/08/90	corrections for int 10 propertly returning bp.

sah 11/09/90	corrections for int 10 propertly sending bp.

sah 01/09/91	if scblastff=0 skip calling fe handler instead of
		skipping bank entirely.

sah 03/08/91	removing 40:17 write protect logic, when calling
		orginal bios int9 inside our int9 handler. also
		master console function 1 is change so that leds will be
		be change by issuing original bios int 16 function 01h

sah 03/27/91	corrections for int 9, ctrl-alt-del and 40:17 work

mjs 05/24/91	added dummy print_stat function.  cleaned up module

SAH 06/05/91	Corrections for 1024 by 768 resolution mode 37h and 38h
		Skip MJS's 5/26/89 change if station is not hercules

SAH 06/25/91    Correction for MOS VMODE Mono and previous update
		06/05/91.  Must mask out all bit of cl.

SAH 06/27/91    Corrections for 06/05 and 06/25 for display automination
		INT 10h problem with autocad.

SAH 09/05/91    Correction to my 06/27/91 to make sure it uses the tcb
		or current task (scbtcbpc) instead of workstations tcb

================ 5.01 Kernel Ends Here ====================================

mjs 08/18/92	clean up segment declarations

======================================================================^

.xlist
	include mosddtmc.pub
	include group.inc
	include macros.inc
	include mosregs.inc

tcb	segment at 1234h
	include mostcb.inc
tcb	ends
.list

gdata	segment

.xlist
	include mosscbex.inc
.list

	extrn	tsl8stat:word

request dd	0

; video values for cga modes

cgatbl	db	2ch,28h,2dh,29h,2eh,2ah,3eh
t3d5tbl db	38h,71h,38h		; r0
	db	28h,50h,28h		; r1
	db	2dh,5ah,2dh		; r2
	db	0ah,0ah,0ah		; r3
	db	1fh,1fh,7fh		; r4
	db	06h,06h,06h		; r5
	db	19h,19h,64h		; r6
	db	1ch,1ch,70h		; r7
	db	02h,02h,02h		; r8
	db	07h,07h,01h		; r9
	db	06h,06h,06h		; r10
	db	07h,07h,07h		; r11
	db	00h,00h,00h		; r12
	db	00h,00h,00h		; r13

; video values for hercules mode

herctbl db	02h			; 3b8h control code
	db	35h,2dh,2eh,07h,5bh,02h,57h,57h,02h,03h,00h,00h
	db	0ah			; 3b8h control code

; video values for mono mode

	monotbl db	20h
	db	61h,50h,52h,0fh,19h,06h,19h,19h,02h,0dh,0bh,0ch
	db	28h

mcsnow	db	0

; temp save/restore of bios ram around our use of bios rom

mcbio	db	1ch dup(?)		; (65h-49h) include all but crt_mode_set & crt_pallette
kbbf	db	32 dup(0)
endkb	equ	this byte
kbget	dw	offset grp:kbbf 	; where to get earliest char from kb
kbput	dw	offset grp:kbbf 	; where to put next char from kb
kbnotmt db	0			; z while scan code buffer is empty
in09	db	-1			; 0 if first trip else >0
	public	ddtmctcb
ddtmctcb dw	0			; seg of tcb for foreground

mkbstatus equ	17h			; 40:17 keyboard status byte
mkbaltnm equ	19h			; 40:19 alt numbers
mkbhead equ	1ah			; 40:1a head pointer
mkbtail equ	1ch			; 40:1c tail pointer
mkbbuff equ	1eh			; start of keyboard buffer
mkbauxst equ	96h			; auxiliary keyboard shift status

ifdef debug
tripcnt1 db	0			; debugging counter
endif
	public	endchn9
endchn9 db	0			; flag to tell getkeys that an int9 chain
					; call resulted in the 'original bios' getting
					; a call
	public	chain9
chain9	db	0			; control flag for re-grab int9 logic

gdata	ends

irq	segment

	extrn	i10old:dword, i16old:dword

	dw	09h*4			; offset for this interrupt
i09old	dd	?			; save prior value
	dw	0			; we don't save changes, we leave them alone
	dw	mosint09		; offset of handler
	dw	0			; don't change back if application changes it

irq	ends

;======================================================== mos segment
if 0 eq 0
segment_num = 1
endif
mosseg	segment
	assume	cs:mos,ds:nothing,es:nothing,ss:nothing

	extrn	mapvma:near, decodescan:near
	extrn	i10fun10:near

	subttl regrab09 - int9 management for non-lidt memory management
	page
;======================================================================
;,fs
; regrab09 - int9 management for non-lidt memory management
;
; regrab09 - int9 management for cases when no memory management driver
; is used or the cpu is an 8088 - basically, whenever the lidt scheme
; is not available.
;
; in:	
;
; out:	
;
;,fe
;=====================================================================
	assume	ds:nothing,es:nothing,ss:nothing
	public	regrab9_data
regrab9_data:
	dw	9*4			; +0 offset of vector relative to segment 0
	dw	mosint09		; +2 offset of primary handler
	dw	regrab9a		; +4 offset of first regrab handler
	dw	tcb:tcbnest9		; +6 offset of nest flag
	dw	tcb:tcbchn9		; +8 offset of table for user's vectors

regrab9a:
	push	bx			; these are the int9 handlers which mos
	mov	bl,1			; will re-assert to stay in control
	jmp	short	regrab09
	push	bx
	mov	bl,2			; note - each of these entry points
	jmp	short	regrab09	; consists of 5 bytes of code.
	push	bx			; the procedure calc_next is
	mov	bl,3			; dependant on this code size.
	jmp	short	regrab09
	push	bx
	mov	bl,4
	jmp	short	regrab09
	push	bx
	mov	bl,5
	jmp	short	regrab09

regrab09:
	push	ds			; original bx saved on the stack
	mgetscb ds			; current bx value indicates nest level
	assume	ds:grp
	mov	ds,[scbtcbpc]
	assume	ds:tcb
	cmp	bl,[tcbnest9]		; if enter at highest recorded nest level
	pushf				; then pass the call on to the mosint09
	xor	bh,bh			; logic - intercepts are only called
	dec	bx			; from getddkeys.
	shl	bx,1
	shl	bx,1			; if enter via another nest level then must
	popf				; be due to an intercept calling the previous
	je	re9a			; vector holder.  in this case, pass control
	assume	ds:tcb			; onto the next application vector stored in
	push	ax			; the table.
	push	ax			; make some room on the stack
	push	bp
	mov	bp,sp
	push	ax
	mov	ax,[bp+6]		; relocate ds (already pushed)
	mov	[bp+2],ax
	mov	ax,[bp+8]		; relocate bx
	mov	[bp+4],ax
	mov	ax,word ptr [tcbchn9+bx]
	mov	[bp+6],ax		; put address of next int9
	mov	ax,word ptr [tcbchn9+bx+2]  ; intercept on stack
	mov	[bp+8],ax
	pop	ax
	pop	bp
	pop	ds
	assume	ds:nothing
	pop	bx
	retf				; transfer to next intercept
re9a:
	pop	ds
	pop	bx
	jmp	mosint09

	subttl mosint09 - default int9 handler for re-grab scheme
	page
;======================================================================
;,fs
; mosint09 - default int9 handler for re-grab scheme
;
; this handler is entered when the irq1 occurs - either directly,
; because the vector points here (no intercepts), or indirectly, after
; being routed through the regrab9 logic above (when intercepts exist).
;
; in:	
;
; out:	
;
;,fe
;=====================================================================
	assume	ds:nothing,es:nothing,ss:nothing
	public	mosint09
mosint09 proc far
	push	ds
	mgetscb ds
	assume	ds:grp
	cmp	byte ptr [chain9],0
	pop	ds
	assume	ds:nothing
	jnz	lidtstub9
	callmos2 i9helper		; use to get lidtint09 code called
	iret
mosint09 endp

	subttl lidtstub9 - the irq1 handler for lidt
	page
;======================================================================
;,fs
; lidtstub9 - the irq1 handler for lidt
;
; this is the int9 handler presented via 0:9*4 when lidt support
; is available.  this procedure will be called as the end of the chain
; when getkeys calls the int9 intercept chain.
;
; in:	
;
; out:	
;
;,fe
;=====================================================================
	assume	ds:nothing,es:nothing,ss:nothing
	public	lidtstub9
lidtstub9 proc far
	push	ax
	push	es
	push	ds
	mgetscb ds
	assume	ds:grp
	mov	byte ptr [endchn9],1	; let getkeys know we got here
	mov	es,[scbtcbpc]
	assume	es:tcb
	mov	ds,[tcbi9seg]		; recover the visual segment from getddkeys
	mov	al,[tcbtrapcd]		; recover the scan code
	call	decodescan		; simulate the bios action
	mov	[tcbi9flg],al		; save the pamkey flag for getddkeys
	pop	ds
	pop	es
	assume	ds:nothing,es:nothing
	pop	ax
	call	cleario
	iret
lidtstub9 endp

	subttl cleario - enable the kybd controller
	page
;======================================================================
;,fs
; cleario - enable the kybd controller
;
; cleario - insure that the keyboard controller chip is enabled.
; some intercept programs will disable the keyboard controller before
; doing their in al,61 and leave it disabled - counting on the
; the bios handler to re-enable it again.  because of the different
; order things happen in with mos's int9 processing, when an intercept
; thinks its calling the bios, it really isn't.
;
; in:	
;
; out:	
;
;,fe
;=====================================================================
	assume	ds:nothing,es:nothing,ss:nothing
cleario proc near
	cli
	push	ax
	push	cx
	xor	cx,cx
ll1:
	in	al,64h
	test	al,2
	loopnz	ll1
	mov	al,0aeh 		; insure that the keyboard controller chip
	out	64h,al			; is enabled
	sti
	pop	cx
	pop	ax
	ret
cleario endp

mosseg	ends

;======================================================== ddt segment
if 0 eq 0
segment_num = 2
endif
ddt	segment
	assume	cs:mo2,ds:nothing,es:nothing,ss:nothing

	extrn	noswt:near, okswt:near, sbios2:word
	extrn	allowhio:near, denyhio:near, wordmov:near
	extrn	ddtcall:near		; console device driver gating	; rg8188

	public	mcterm, mcsnow

	subttl 
	page
;======================================================================
;,fs
; regrab09 - int9 management for non-lidt memory management
;
; biosint9 - set up a safe condition with respect to the int15 vector
; and give the bios int9 handler a call.
;
; in:	
;
; out:	
;
;,fe
;=====================================================================
	assume	ds:grp,es:nothing,ss:nothing
biosint9 proc near
	push	ax
	push	bx
	push	si
	push	es
	mgetzero2 es
	assume	es:nothing

; fake int 15 so nothing funny happens

	cli				; no interrupts during vector setting
	push	es:[15h*4]		; restore things later
	push	es:[15h*4+2]
	mov	word ptr es:[15h*4],offset stub15
	mov	es:[15h*4+2],cs

; if i/o protection, save state of port 60 and 61 trapping and then
; turn them off.
; port 60 is for the kbrate scheme
; port 61 is for pc bios with 386 (e.g. inboard pc)

	test	[scbmmfea],40h		; is i/o protection supported?
	jz	bio9a			; no, skip
	mov	bx,ds
	lds	si,[scbioptr]		; get pointer to memman data
	assume	ds:nothing
	mov	al,[si+12]		; save current trapping state in al
	and	byte ptr [si+12],not 13h; clear byte 12, bits 1, 2, and 5
	mov	ds,bx
	assume	ds:grp
	push	ax
bio9a:
	in	al,21h
	push	ax
	or	al,0fdh 		; disable all irq's except 1
	out	21h,al
	pushf				; call bios to acknowledge key
	call	dword ptr [i09old]

; restore the machine state

	pop	ax
	out	21h,al			; restore original mask
	test	[scbmmfea],40h		; i/o protection supported?
	jz	bio9b			; no, skip
	pop	ax
	mov	bx,ds
	lds	si,[scbioptr]		; get pointer to memman data
	assume	ds:nothing
	mov	[si+12],al		; restore original trapping state
	mov	ds,bx
	assume	ds:grp
bio9b:
	pop	es:[15h*4+2]		; disable again while restoring vector
	pop	es:[15h*4]
	sti

	pop	es
	pop	si
	pop	bx
	pop	ax
	ret
biosint9 endp

; this will be the int15 handler when we call the original bios int9. 
; can't let any int15 tsr's get control during that time.

stub15:
	iret

	subttl i9helper - link between regrab and lidt code
	page
;======================================================================
;,fs
; i9helper - link between regrab and lidt code
;
; this procedure allows the regrab code, in the mos segment, to call
; the lidtint09 handler
;
; in:	
;
; out:	
;
;,fe
;=====================================================================
	assume	ds:grp,es:nothing,ss:nothing
i9helper proc near
	pushf
	push	cs
	call	lidtint09
	ret
i9helper endp

	subttl lidtint09 - irq1 handler for lidt managment
	page
;======================================================================
;,fs
; lidtint09 - irq1 handler for lidt managment
;
; in:	
;
; out:	
;
;,fe
;=====================================================================
	assume	ds:nothing,es:nothing,ss:nothing
	public	lidtint09
lidtint09:
	push	ds
	mgetscb2 ds
	assume	ds:grp
	inc	[scbnoswt]		; no task switch save/restore context
	inc	[scbinmos]		; technically not in mos
	push	[tsl8stat]		; no tsr pop up
	mov	[tsl8stat],0
	inc	byte ptr [scbhwcl+1]	; bump interrupt count
	inc	[in09]			; test reentering
	sti				; enable interrupts
	jz	mosi9b1 		; first trip handle completely
	call	biosint9		; reentering deal with nack codes
	jmp	mosi9c

; save variables in the bios data area to prepare for a call to the
; original int9 handler in the rom bios.  we call the rom bios to let
; it update keyboard leds and do anything else that might be machine
; specific.

mosi9b1:
	push	ax
	push	si
	push	es

ifdef debug
					; set breakcnt to character before breakpoint trap
	cmp	[breakcnt],0		; test tripped
	jz	nobreak
	dec	[breakcnt]		; test tripcnt reached
	jnz	nobreak
	int	2
nobreak:
endif
	mov	ax,40h			; save task variables from bios
	mov	es,ax
	assume	es:nothing
	push	es:[mkbstatus]		; save shift state
	mov	al,es:[mkbaltnm]
	mov	ah,es:[mkbauxst]	; save alt-num and aux shift
	push	ax
	push	es:[mkbhead]		; save head/tail pointers
	push	es:[mkbtail]
	mov	ax,mkbbuff
	mov	word ptr es:[mkbhead],ax; fake buffer pointers so the
	mov	word ptr es:[mkbtail],ax; bios doesn't crash our buffer
	push	ds
	mov	ds,[ddtmctcb]		; get segment of foreground's tcb
	assume	ds:tcb
	mov	al,[tcbkshft]
	mov	es:[mkbstatus],al
	pop	ds
	assume	ds:grp
	in	al,60h			; get the scan code
	cmp	al,0fah
	jb	mosi9f
	jmp	mosi9d

; write the scan code in ddtmc's local buffer

mosi9f:
	mov	si,[kbput]
	mov	[si],al 		; store character
	inc	si			; test buffer full
	cmp	si,offset grp:endkb
	jb	mosi9f2 		; test buffer wrap
	mov	si,offset grp:kbbf
mosi9f2:
	cmp	si,[kbget]
	je	mosi9f3 		; buffer full, should beep (ega problem)
	mov	[kbput],si		; update keyboard put pointer
	inc	[kbnotmt]		; update char available

; when a cntrl-alt-delete is detected, clean up the machine before
; rebooting.  if a memory manager exists, call it to invoke the reboot.
; if no memory manager, pass on to let the rom bios handle the reboot.

mosi9f3:
	cmp	al,83			; is it del ?
	jne	mosi9d1
	mov	al,es:[mkbstatus]
	and	al,0ch
	cmp	al,0ch			; are both cntrl and alt down ?
	jne	mosi9d1
	push	ds
	mov	ds,[scbtcbpc]		; get tcb segment
	assume	ds:tcb
	cmp	[tcbreboot],0ffh	; if reboot is disabled
	pop	ds
	assume	ds:grp
	je	mosi9d2 		; then go let bios ack key
	push	ax			; go ahead and call the ff function of
	push	si			; the master console's ddt
	push	ds
	mov	ds,[scbtcbpf]		; just in case its a vna workstation
	assume	ds:tcb			; or an ega in a co-resident situation
	mov	si,offset [tcbcondd]
	mov	ah,0ffh
	call	dword ptr [si]		; don't need ddtcall here
	pop	ds
	pop	si
	pop	ax
	assume	ds:grp
	cmp	word ptr [scbvidchk+2],0
	je	nospecvid		; check for special video card
	push	ds
	mov	ah,2
	call	dword ptr [scbvidchk]
	pop	ds
nospecvid:
	cmp	[scbmmfg],'Y'		; if have a normal mm, call its function 0
	je	mosi9d5
	test	[scbmmfea],6		; must also check for a mm driver that only
	jz	mosi9d1 		; supports lidt and/or limited 286 relocation
mosi9d5:
	xor	ah,ah
	call	[scbmmsub]		; let the mm reset the machine

; test for special cases - don't want to let the rom bios see certain
; keystrokes.  shift-prtsc would cause an int5, cntrl-num lock would
; hang the system until another keystroke occured, cntrl-brk would
; cause an int1b.  the shift state at 40:17 is manipulated to prevent
; any of these un-desirable effects from occuring.
; on advanced keyboard/bios mkbauxst contains extended key shift states
; this is also manipulated for extended keys

mosi9d1:				; following simplified
	cmp	al,37h			; test for '*' scan code (prtscrn)
	je	mosi9d2
	cmp	al,45h			; test for num lock scan code (pause)
	je	mosi9d2
	cmp	al,46h			; test for scroll lock scan code (break)
	jne	mosi9d
mosi9d2:
	xor	ax,ax			; just fake out everything on these
	mov	es:[mkbstatus],al
	mov	es:[mkbauxst],al
mosi9d:
	call	biosint9		; bios acknowledges the interrupt
	pop	es:[mkbtail]		; restore bios data area to its previous state.
	pop	es:[mkbhead]
	pop	ax
	mov	es:[mkbaltnm],al
	mov	es:[mkbauxst],ah
	pop	es:[mkbstatus]
	pop	es
	pop	si
	pop	ax
mosi9c:
	cli
	pop	[tsl8stat]		; allow tsrs to pop up
	dec	[scbnoswt]		; finished with context shuffle
	dec	[scbinmos]
	dec	[in09]			; reentrancy flag
	pop	ds
	iret

	page
;--------------------------- ddtmc logic --------------------------------

	subttl mosddtmc - device driver for master console

	assume	ds:nothing

	subttl termfn - all the terminal and keyboard functions for mos
	page

tfn	dw	mo2:register
	dw	mo2:inkbdata
	dw	mo2:outkbctl
	dw	mo2:setmode
	dw	mo2:setcrstyp
	dw	mo2:setcrspos
	dw	mo2:scrollup
	dw	mo2:scrolldn
	dw	mo2:wrchatr
	dw	mo2:setpalet
	dw	mo2:wrtty
	dw	mo2:wrstr
	dw	mo2:setwindow
	dw	mo2:wrcho
	dw	mo2:readch
	dw	mo2:getscr
	dw	mo2:prch
	dw	mo2:prstr
	dw	mo2:print_stat
endtfn	equ	($-tfn)/2
	dw	mo2:passon

	subttl bankin - bank select the master console.  
	page
;======================================================================
;,fs
; bankin - bank select the master console.  
;
; in:	ds:si -> ddt
;
; out:	
;
;,fe
;=====================================================================
	assume	ds:nothing,es:nothing,ss:nothing
bankin proc near
	push	bx
	push	cx
	push	dx
	push	ds
	push	es
	mgetscb2 es
	assume	es:grp
	test	[si].dcbios,01h 	; if no ega bios, then can't show
	jmpz	mctrm150		; what could never be hidden
	mov	ax,ds
	cmp	ax,[scblastff]		; if this workstation is already selected
	jmpe	mctrm150		; then skip all this bankin logic
	cmp	[scblastff],0		; if not yet through mositask for the
	jz	mctrm090		; then skip call to fe handler

; scblastff doesn't point to this workstation so make an fe call
; to the last driver banked in to get it banked out.

	push	si
	push	ds
	mov	ds,[scblastff]		; call the ddt at scblastff:tcbcondd
	mov	si,offset [tcbcondd]
	mov	ah,0feh
	call	ddtcall
	pop	ds
	pop	si

; bank in the new workstation.	then, if the bank in actually succeeds,
; update scblastff so the next ff call to a ddt will know who to bank out.

mctrm090:
	push	es
	test	[si].dcbios,02h 	; vga?
	jnz	mctrm120

; here to show ega

	mov	es,[scbtcbpc]
	assume	es:tcb
	cmp	[tcbstate],0
	mov	al,[tcb3c2]
	jne	mctrm110
	mov	ah,[si].dcmode
	cmp	ah,07h			; ignore mono modes
	je	mctrm140
	cmp	ah,0fh
	je	mctrm140
	mov	al,23h			; misc output reg for cga display
	test	[si].dcbios,04h
	jz	mctrm100
	cmp	ah,0dh			; d and e are lower frequency modes
	je	mctrm100
	cmp	ah,0eh
	je	mctrm100
	mov	al,0a7h 		; enhanced display modes
	cmp	ah,04h
	jb	mctrm100		; include modes 0,1,2,3
	cmp	ah,06h
	ja	mctrm100		; and any modes greater than 6 (10h)
	mov	al,23h			; else slower clock
mctrm100:
	mov	[tcb3c2],al
mctrm110:
	or	al,02h
	mov	dx,03c2h
	out	dx,al
	jmp	mctrm130

; show vga

mctrm120:
	mov	ax,1200h
	mov	bl,32h
	call	savbio
	call	callint
	call	rstbio
mctrm130:
	pop	es
	assume	es:grp			; when the showing is successful,
	mov	[scblastff],ds		; record this ddt in scblastff.
	jmp	mctrm150
mctrm140:
	pop	es
	assume	es:grp
mctrm150:
	pop	es
	pop	ds
	pop	dx
	pop	cx
	pop	bx
	ret
bankin endp

	subttl mcterm - entry point for ddt calls.
	page
;======================================================================
;,fs
; mcterm - entry point for ddt calls.
;
; in:	
;
; out:	
;
;,fe
;=====================================================================
	assume	ds:nothing,es:nothing,ss:nothing
mcterm proc far
	cmp	ah,0feh
	je	mctrm020
	jmp	mctrm070

; 0feh is a special function to bank out the master console.
; this is intended for the co-resident vna with a vga/ega master console case

mctrm020:
	push	ax
	push	es
	test	[si].dcbios,01h
	jz	mctrm060		; not ega/vga
	test	[si].dcbios,02h
	jnz	mctrm050

; here to hide ega

	mgetscb2 es
	assume	es:grp
	mov	es,[scbtcbpc]
	assume	es:tcb
	cmp	[tcbstate],0
	mov	al,[tcb3c2]
	jne	mctrm040
	mov	ah,[si].dcmode
	cmp	ah,07h			; ignore mono modes
	je	mctrm060
	cmp	ah,0fh
	je	mctrm060
	mov	al,23h			; misc output reg for cga display
	test	[si].dcbios,04h
	jz	mctrm030
	cmp	ah,0dh			; d and e are lower frequency modes
	je	mctrm030
	cmp	ah,0eh
	je	mctrm030
	mov	al,0a7h 		; enhanced display modes
	cmp	ah,04h
	jb	mctrm030		; include modes 0,1,2,3
	cmp	ah,06h
	ja	mctrm030		; and any modes greater than 6 (10h)
	mov	al,23h			; else slower clock
mctrm030:
	mov	[tcb3c2],al		; remember it even if no io prot
mctrm040:
	push	dx
	and	al,not 2
	mov	dx,03c2h
	out	dx,al
	pop	dx
	jmp	mctrm060

; hide vga

mctrm050:
	push	cx
	push	bx
	mov	ax,1201h
	mov	bl,32h
	call	savbio
	call	callint
	call	rstbio
	pop	bx
	pop	cx
mctrm060:
	pop	es
	assume	es:nothing
	pop	ax
	jmp	mctrm230
mctrm070:
	cmp	ah,0ffh 		; is this special ff call
	je	mctrm080
	jmp	mctrm210

; 0ffh is a special call to bank in the master console.  this is also
; part of co-resident support.

mctrm080:
	pushf				; save current interrupt flag status
	cli				; secure against video switching irq's
	push	cx
	push	dx
	push	ds
	push	es
	call	bankin			; bank select the master console

; expose the physical video display ram

	mgetscb2 ds
	assume	ds:grp,es:nothing
	test	[scbmmmod],80h		; is video mm used?
	jz	mctrm200
	cmp	[scbbankin],'N' 	; check to see if ff call need to unmap
	je	mctrm200
	mov	ax,[scbvmaal]
	cmp	al,3			; was last one list base
	je	mcskmap 		; if so skio mapping call
	or	al,al			; only need to unmap if the last call to
	jz	mctrm200		; mapvma was to map something
	mov	dx,[scbvmaseg]
	or	dx,dx
	jz	mctrm200		; skip if get an unmap call before anything's
	mov	cx,[scbvmacnt]		; been mapped
	add	cx,[scbvmacnt+2]
	xor	al,al
	callmos1 mapvma
mcskmap:
	mov	[scbtcbvr],0
mctrm200:
	pop	es
	pop	ds
	pop	dx
	pop	cx
	popf				; restore interrupt flag status
	jmp	mctrm230

; process a lower function

mctrm210:
	push	ds			; note: the passon function is based on stack
	push	bp			; usage here
	mov	bp,bx
	mov	bl,ah			; note: if any mcterm functions are added which
	cmp	bl,endtfn		; require bp, will need to use a similar
	jb	mctrm220		; recovery method as the passon function.
	mov	bl,endtfn
mctrm220:
	xor	bh,bh
	shl	bx,1
	xchg	bx,bp
	call	allowhio
	call	tfn[bp]
	call	denyhio
	pop	bp
	pop	ds
mctrm230:
	ret
mcterm	endp

	subttl passon - pass on unrecognized bios calls
	page
;======================================================================
;,fs
; passon - pass on unrecognized bios calls
;
; in:	
;
; out:	
;
;,fe
;=====================================================================
	assume	ds:nothing,es:nothing,ss:nothing
passon proc near
	mov	bp,sp
	mov	bp,[bp+4]		; note: bp+8 is based on the current stack
	and	ah,7fh			; usage in the mcterm function selection logic
	call	savbio
	or	ah,ah			; remember the mode set for hideit/showit
	jnz	pass1
	mov	[si].dcmode,al
	and	[si].dcmode,not 80h
pass1:
	cmp	ah,10h
	jne	pass2
	push	ds
	mgetscb2 ds
	assume	ds:grp
	callmos1 i10fun10		; set palette calls get special treatment.
	pop	ds			; the i10fun10 procedure is in mosint16.asm
	assume	ds:nothing
	jmp	pass3
pass2:
	call	callint
pass3:
	call	rstbio
	push	bx
	mov	bx, sp			; note: we are replacing bp back on the stack
	mov	ss:[bx+6], bp
	pop	bx
	ret
passon endp

	subttl callint - manage trapping and call bios int10
	page
;======================================================================
;,fs
; callint - manage trapping and call bios int10
;
; in:	
;
; out:	
;
;,fe
;=====================================================================
	assume	ds:nothing,es:nothing,ss:nothing
callint proc near
	push	ds			; we assume ds never used by int 10...
	mgetscb2 ds
	assume	ds:grp
	pushf
	call	[i10old]
	pop	ds
	assume	ds:nothing
	ret
callint endp

	subttl exposreal - expose real video ram
	page
;======================================================================
;,fs
; exposreal - expose real video ram
;
; in:	ds -> tcb
;
; out:	
;
;,fe
;=====================================================================
	assume	ds:tcb,es:nothing,ss:nothing
exposreal proc near
	push	ax
	push	si
	mov	ah,0ffh
	call	dword ptr [si]
	pop	si
	pop	ax
	ret
exposreal endp

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
;	  key buffer flag is <> 0 while scan codes are buffered
;	al = 80h if master console
;	     00h if not master console
;	ah = 00h cause no error can happen
;
;,fe
;=====================================================================
	assume	ds:tcb,es:grp,ss:nothing
register proc near
	mov	al,[mcsnow]		; transfer global snow var to ddtmc var
	mov	[si].dcsnow,al
	and	[si].dcbios,not 7h	; set ega/vga bios not supported
	mov	ax,1200h
	mov	bl,10h
	call	savbio
	call	callint
	cmp	bl,10h
	je	ddtin1
	or	[si].dcbios,5		; set ega bios supported
	push	ds			; enhanced display
	mgetzero2 ds
	assume	ds:nothing
	mov	al,ds:[488h]
	pop	ds
	assume	ds:tcb
	and	al,0fh
	cmp	al,03h
	je	ddtin0
	cmp	al,09h
	je	ddtin0
	and	[si].dcbios,not 04h	; display not enhanced
ddtin0: 				; (see ibm ega bios page 123)
	mov	ax,1200h		; al=0 for enable vga memory
	mov	bl,32h
	call	callint
	cmp	al,12h
	jne	ddtin1
	or	[si].dcbios,2		; set vga bios supported also
ddtin1:
	call	rstbio
	call	chkmode
	mov	[si].dcvmode,al
	mov	[si].dcmode,al
	mov	[si].dcpherc,'N'
	cmp	al,7
	jne	reg0
	test	[si].dcbios,3		; skip if ega or vga
	jnz	reg0
	call	chkherc 		; if mode 7, see if hercules card
reg0:
	mov	bx,offset [kbnotmt]
	mov	[si].dcpcrs,0
	mov	[si].dcpcol,80
	mov	[si].dcpscrl,80*25*2
	mov	[si].dcpscr,0b800h
	mov	[si].dcaddr,03d4h
	cmp	al,07h			; ah = 0 for no error
	mov	ax,0e0h 		; al bits 6 & 5 for graphics and color support
	jne	reg1
	mov	[si].dcpscr,0b000h
	mov	[si].dcaddr,03b4h
	mov	al,80h
	cmp	[si].dcpherc,'Y'
	jne	reg1			; ne if straight monochrome card
	mov	al,090h 		; hercules graphics and master console
reg1:
	mov	cx,[si].dcpscr		; return physical screen address (to
					;   be stuffed into tcbvidad)
	ret
register endp

	subttl inkbdata - input keyboard scan code
	page
;======================================================================
;,fs
; inkbdata - input keyboard scan code
;
; if cx=dx then we will need to all orginal bios  int 16 fun 1 to
; set the state of the leds.  please not scbcon417 is use here and only
; here to manage calling bios only when necessary.
;
; in:	ah = 01h
;	ds:si -> tcbddt
;	cx=dx -> 40:17 value to set leds
;
; out:	al = bit 7   - key break if 1, key make or key repeat if 0
;	     bits 6-0 - key scan code 01h - 07dh
;	key scan code is read non-destructively
;
;,fe
;=====================================================================
	assume	ds:nothing,es:nothing,ss:nothing
inkbdata proc near
	mgetscb2 ds
	assume	ds:grp
	cmp	dl,[scbcon417]
	je	kbdat0
	cmp	cx,dx			; cx must equal dx
	jne	kbdat0
	cmp	[scbinit],0
	je	kbdat0
	mov	[scbcon417],dl
	call	updateleds		; update leds on master console
kbdat0:
	xor	ax,ax
	mov	si,[kbget]		; test buffer empty
	cmp	si,[kbput]
	je	kbdat1			; empty return 0
	mov	al,[si] 		; return scan code
kbdat1:
	ret
inkbdata endp

	subttl updateleds - updates leds on master console
	page
;======================================================================
;,fs
; updateleds - updates leds on master console
;
; this procedure is use by inkbdata to	update the leds on the master
; console keyboard.   it does this by calling the original bios int 16
; function 01h with io protection off
;
; in:	ds -> grp
;
; out:	
;
;,fe
;=====================================================================
	assume	ds:grp,es:nothing,ss:nothing
updateleds proc near
	push	es
	mov	ax,40h
	mov	es,ax
	push	word ptr es:[0097h]
	push	word ptr es:[0017h]
	push	word ptr es:[001ah]	; save head pointer
	push	word ptr es:[001ch]	; save tail pointer

; force 40:97 to be differents so bios with switch leds on and off

	mov	al,dl
	shr	al,1
	shr	al,1
	shr	al,1
	shr	al,1
	not	al
	and	al,07h
	or	byte ptr es:[0097h],al
	and	byte ptr es:[0097h],not 040h

; turn keyboard io protection off while calling int 16h

	test	[scbmmfea],40h		; is i/o protection supported?
	jz	dat9a			; no, skip
	push	ds
	lds	si,[scbioptr]		; get pointer to io protection table
	assume	ds:nothing
	mov	al,[si+12]		; save current trapping state in al
	and	byte ptr [si+12],not 13h; clear byte 12, bits 1 and 2
	pop	ds
	assume	ds:grp
	push	ax
dat9a:

; call bios int 16 to change keyboard leds

	mov	ah,1			; pick up current state of toggles
	test	byte ptr es:[0096h],10h
	jz	datnoenh
	or	ah,10h
datnoenh:
	pushf				; (so mc keyboard matches lights)
	cli
	call	[i16old]
	test	[scbmmfea],40h		; is i/o protection supported?
	jz	dat9b			; no, skip
	pop	ax
	push	ds
	lds	si,[scbioptr]		; get pointer to io protection table
	assume	ds:nothing
	mov	[si+12],al		; save current trapping state in al
	pop	ds
	assume	ds:grp
dat9b:
	pop	word ptr es:[001ch]	; restore tail pointer
	pop	word ptr es:[001ah]	; restore head pointer
	pop	word ptr es:[0017h]
	pop	word ptr es:[0097h]
skipdat:
	pop	es
	ret
updateleds endp

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
	mgetscb2 ds
	assume	ds:grp
	test	al,80h
	jz	kbctl2
	test	[kbnotmt],-1		; test any keys in buffer
	jz	kbctl2			; nothing to clear if buffer is empty
	mov	si,[kbget]
	inc	si
	cmp	si,offset grp:endkb
	jb	kbctl1
	mov	si,offset grp:kbbf
kbctl1:
	mov	[kbget],si		; update get pointer and keys available
	dec	[kbnotmt]
kbctl2:
	ret
outkbctl endp

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
	mov	cl,al
	cmp	[si].dcpherc,'Y'		
	je	setxy
	and	al,07fh
	jmp	short setxx
setxy:
	and	cl,00100000b
	shl	cl,1
	shl	cl,1			; cl == 80h if bit 5 was set in entry al
	and	al,11011111b
setxx:						
	and	cl,80h			

; need to switch physical display in for set mode so bios cls works

	call	exposreal
	cmp	[si].dcpherc,'Y'
	jne	setm0c

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

; here whether or not hercules is present

setm0c:
	mov	[si].dcvmode,al
	cmp	al,0fh			; skip if mode 0f or higher windows 3.00
	jae	setm1b			; on a monochrome vga
	mov	ah,[tcbomode]		; get orginal mode
	cmp	al,7
	je	setm1a
	mov	ah,al
	test	ah,80h
	jz	setm1a
	mov	ah,[si].dcmode
setm1a:
	mov	al,ah
setm1b:
	mov	[si].dcmode,al
	or	al,cl			; set high bit if appliable
	xor	ah,ah
	call	savbio
	mov	es,[sbios2]		; access bios data segment
	push	word ptr es:[0010h]
	or	byte ptr es:[0010h],30h
	cmp	al,7
	je	setm2
	cmp	al,0fh			; skip if monochrome ega\vga
	je	setm2
	and	byte ptr es:[0010h],not 30h
	or	byte ptr es:[0010h],20h
setm2:
	cmp	al,06h			; check to see if mode is above 6
	ja	setm3
	test	[si].dcbios,1		; check to see if console support ega
	jnz	setm3
	test	cl,80h			; check to see if don't clear image bit set
	jz	setm3

; do set mode directly

	push	ds
	push	si
	mgetscb2 ds
	mov	dl,al			; set up for offset into controller table
	cmp	dl,06h			; test for mode 6 which is graphic
	jne	setm2a
	dec	dl			; adjust
setm2a:
	shr	dl,1			; divide by 2 (0 = 40col,1 = 80col, 2 = graph)
	xor	dh,dh
	xor	ah,ah
	mov	si,offset cgatbl
	add	si,ax
	cld
	lodsb
	push	ax
	push	bx
	push	cx
	mov	si,offset t3d5tbl	; get offset of crt table
	add	si,dx			; add off set to entry
	and	al,0f7h 		; turn off video
	mov	dx,03d8h
	out	dx,al
	mov	dx,03d4h		; point to crt index
	mov	cx,14
	xor	bx,bx
setm2lp:
	mov	al,bl
	out	dx,al			; send index
	inc	dx			; point to crt data
	inc	bx			; next index
	lodsb
	out	dx,al			; send value
	dec	dx			; point to crt index
	inc	si
	inc	si			; skip other two entries
	loop	setm2lp
	pop	cx
	pop	bx
	pop	ax
	mov	dx,03d8h		; set the mode
	out	dx,al
	pop	si
	pop	ds
	jmp	short	setm4
setm3:
	or	al,cl			; set high bit of al if entry
	call	callint 		; al had bit 6 set
	push	ds
	cmp	byte ptr es:[049h],13h
	jbe	setm4
	MGetSCB2 ds
	assume  ds:gdata
	mov	ds,[scbtcbpc]
	assume	ds:tcb
	mov	al,es:[004ah]
	cmp	al,80
	jbe	setm3a
	mov	[tcbcols],al
setm3a:
	mov	al,es:[0084h]
	inc	al
	cmp	al,25
	jbe	setm4
	mov	[tcbrows],al
setm4:
	pop	ds
	pop	word ptr es:[0010h]
	call	chkmode
	call	rstbio
	push	ds
	MGetSCB2 ds
	assume  ds:gdata
	mov	ds,[scbtcbpc]
	assume	ds:tcb
	mov	al,[tcbcols]
	mov	es:[004ah],al
	pop	ds
	ret
setmode endp

	subttl setmono - set hercules card to monochrome text mode
	page
;======================================================================
;,fs
; setmono - set hercules card to monochrome text mode
;
; in:	
;
; out:	
;
;,fe
;=====================================================================
	assume	ds:tcb,es:nothing,ss:nothing
setmono proc near
	push	es
	push	ds
	push	si
	mgetscb2 ds
	assume	ds:grp
	mov	si,offset grp:monotbl
	xor	al,al			; disable graphics and page 1
	mov	bx,0720h		; value to clear
	mov	cx,80*25		; words to clear
	jmp	sethcard
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

	mgetscb2 ds
	assume	ds:grp
	push	ds
	mov	ds,[scbtcbpf]		; -> master console ddt
	assume	ds:tcb
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
	pop	ds
	assume	ds:grp
	mov	si,offset grp:herctbl
	xor	bx,bx			; value to clear
sethcard:
	assume	ds:grp
	mov	dx,3bfh
	out	dx,al			; enable graphics, disable page 1
	jmp	$+2
	mov	dx,03b8h
	lodsb
	out	dx,al			; setting new mode, but turning off 6845
	jmp	$+2
	xor	ah,ah
	mov	dx,03b4h
	push	cx
	mov	cx,12			; setting all 6845 registers for new mode
sethrc1:
	mov	al,ah
	out	dx,al
	jmp	$+2
	inc	dx
	lodsb
	out	dx,al
	jmp	$+2
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
setherc endp

	subttl chkmode - get various ddtmc state parameters from real bios
	page
;======================================================================
;,fs
; chkmode - get various ddtmc state parameters from real bios
;
; in:	
;
; out:	
;
;,fe
;=====================================================================
	assume	ds:tcb,es:nothing,ss:nothing
chkmode proc near
	mov	ah,3
	call	callint
	mov	[si].dcpcrs,dx
	mov	ah,15
	call	callint
	mov	[si].dcpcol,ah
	mov	[si].dcpscrl,80*25*2
	cmp	al,07h
	jae	chkm2			; change from je to jae for acad
	mov	[si].dcpscrl,8192+8000
	cmp	al,4
	jae	chkm2
	mov	[si].dcpscrl,80*25*2
	je	chkm2
	cmp	al,1
	ja	chkm2
	mov	[si].dcpscrl,40*25*2
chkm2:
	ret
chkmode endp

	subttl chkherc - see if it's a hercules card
	page
;======================================================================
;,fs
; chkherc - see if it's a hercules card
;
; in:	
;
; out:	
;
;,fe
;=====================================================================
	assume	ds:tcb,es:nothing,ss:nothing
chkherc proc near
	push	es
	mov	es,[sbios2]		; access bios data segment
	mov	dx,03bah
	in	al,dx
	and	al,80h
	mov	ah,al			; save current bit 7
	mov	cx,es:[006ch]
	inc	cx
chkmh1:
	in	al,dx
	and	al,80h
	xor	ah,al
	jnz	chkmh2			; nz when it changes
	mov	ah,al
	cmp	cx,es:[006ch]
	jns	chkmh1			; ns while cx >= 40:006ch

; didn't change after at least 1/18.2 seconds

	mov	al,7
	pop	es
	ret
chkmh2:

; bit 7 changed so it must be a hercules card

	mov	[si].dcpherc,'Y'
	mov	al,7
	pop	es
	ret
chkherc endp

	subttl savbio - save current video bios ram context to temp holding area
	page
;======================================================================
;,fs
; savbio - save current video bios ram context to temp holding area
;
; in:	
;
; out:	
;
;,fe
;=====================================================================
	assume	ds:tcb,es:nothing,ss:nothing
savbio proc near
	push	es
	push	ds
	push	di
	push	si
	push	cx
	mov	di,offset mcbio
	mov	si,49h
	mgetscb2 es
	mov	ds,[sbios2]		; access bios data segment
	mov	cx,size mcbio/2
	rep	movsw
	pop	cx
	pop	si
	pop	di
	pop	ds
	pop	es
	ret
savbio endp

	subttl rstbio - restore current video bios ram context from temp holding area
	page
;======================================================================
;,fs
; rstbio - restore current video bios ram context from temp holding area
;
; in:	
;
; out:	
;
;,fe
;=====================================================================
	assume	ds:tcb,es:nothing,ss:nothing
rstbio proc near
	push	es
	push	ds
	push	di
	push	si
	push	cx
	mov	si,offset mcbio
	mov	di,49h
	mgetscb2 ds
	mov	es,[sbios2]		; access bios data segment
	mov	cx,size mcbio/2
	rep	movsw
	pop	cx
	pop	si
	pop	di
	pop	ds
	pop	es
	ret
rstbio endp

	subttl setcrstyp - set cursor type
	page
;======================================================================
;,fs
; setcrstyp - set cursor type
;
; in:	ah = 04h - set cursor type
;	ch = begin scan line
;	cl = end scan line
;	al = source screen mode
;	dh = row
;	dl = col
;	ds:si -> tcbddt
;	[tcbddt] = dword -> screen buffer @ page/row/col
;
; out:	
;
;,fe
;=====================================================================
	assume	ds:tcb,es:nothing,ss:nothing
setcrstyp proc near
	mov	es,[sbios2]		; access bios data segment
	push	es:[0049h]		; a little more optimize
	mov	al,[si].dcmode
	mov	es:[0049h],al
	cmp	[si].dcmode,7		; physical mode
	pop	ax			; fix for cursor problem
	push	ax			; virtual use to be alway physical
	jne	setct0
	cmp	al,7			; virtual mode
	je	setct1
	dec	ch			; physical mode = 7, virtual mode <> 7
	dec	cl
	shl	ch,1
	shl	cl,1
	jmp	setct1
setct0:
	cmp	al,7
	jne	setct1
	shr	ch,1			; physical mode <> 7, virtual mode = 7
	shr	cl,1
	inc	ch
	inc	cl
setct1:
	push	es:[0060h]		; save/restore ram cursor type
	mov	ah,1
	call	callint
	pop	es:[0060h]
	pop	es:[0049h]		; a little more optimize
	ret
setcrstyp endp

	subttl setcrspos - set physical cursor position
	page
;======================================================================
;,fs
; setcrspos - set physical cursor position
;
; in:	ah = 05h - set physical cursor position
;	dh = row
;	dl = col
;	ds:si -> tcbddt
;	[tcbddt] = dword -> screen buffer @ page/row/col
;
; out:	
;
;,fe
;=====================================================================
	assume	ds:tcb,es:nothing,ss:nothing
setcrspos proc near
	cmp	dx,[si].dcpcrs
	je	setcp2
	cmp	[si].dcmode,4
	jb	setcp1
	cmp	[si].dcmode,7
	je	setcp1
	mov	ax,[si].dcpcrs
	mov	[si].dcpcrs,dx
	mov	ah,2
	xor	bh,bh
	call	callb50 		; call bios with dx int 40:0050
	ret
setcp1:
	mov	[si].dcpcrs,dx
	mov	cx,[si].crsofs		; cursor offset into screen
	shr	cx,1
	mov	dx,[si].dcaddr
	mov	al,14
	out	dx,al
	jmp	$+2
	mov	al,ch
	inc	dx
	out	dx,al
	jmp	$+2
	mov	al,15
	dec	dx
	out	dx,al
	jmp	$+2
	mov	al,cl
	inc	dx
	out	dx,al
setcp2:
	ret
setcrspos endp

	subttl scrollup - as described for the ibm pc scroll up function
	page
;======================================================================
;,fs
; scrollup - as described for the ibm pc scroll up function
;
; in:	ah = 06h - scroll up
;	al = number of lines to scroll (0 to clear region)
;	bl = attribute to use on blanked lines
;	ch = top-left-corner row
;	cl = top-left-corner col
;	dh = bottom-right-corner row
;	dl = bottom-right-corner col
;	ds:si -> tcbddt
;	[tcbddt] = dword -> screen buffer @ page/row/col
;
; out:	
;
;,fe
;=====================================================================

	assume	ds:tcb,es:nothing,ss:nothing
scrollup proc near
	call	exposreal
	cmp	[si].dcmode,4
	jb	scup1
	cmp	[si].dcmode,7		; we scroll non-graphic modes (0-3 & 7)
	je	scup1
	mov	bh,bl
	mov	ah,06h
	call	callint 		; ok bios you do the graphics (too tough for me!)
	ret
scup1:
	mov	bp,si
	call	mcsuparg
	call	mcscrit
	ret
scrollup endp

	subttl scrolldn - as described for the ibm pc scroll down function
	page
;======================================================================
;,fs
; scrolldn - as described for the ibm pc scroll down function
;
; in:	ah = 07h - scroll down
;	al = number of lines to scroll (0 to clear region)
;	bl = attribute to use on blanked lines
;	ch = top-left-corner row
;	cl = top-left-corner col
;	dh = bottom-right-corner row
;	dl = bottom-right-corner col
;	ds:si -> tcbddt
;	[tcbddt] = dword -> screen buffer @ page
;
; out:	
;
;,fe
;=====================================================================
	assume	ds:tcb,es:nothing,ss:nothing
scrolldn proc near
	call	exposreal
	cmp	[si].dcmode,4
	jb	scdn1
	cmp	[si].dcmode,7
	je	scdn1
	mov	bh,bl
	mov	ah,07h
	call	callint
	ret
scdn1:
	mov	bp,si
	call	mcsdnarg
	call	mcscrit
	ret
scrolldn endp

	subttl wrchatr - write character and attribute
	page
;======================================================================
;,fs
; wrchatr - write character and attribute
;
; in:	ah = 08h - write character and attribute at row & col & page
;	al = char to write
;	bl = attribute to write
;	cx = number of times to write
;	dh = row
;	dl = col
;	ds:si -> tcbddt
;	[tcbddt] = dword -> screen buffer @ page/row/col
;
; out:	
;
;,fe
;=====================================================================
	assume	ds:tcb,es:nothing,ss:nothing
wrchatr proc near
	call	exposreal
	cmp	[si].dcmode,4
	jb	wrcha0
	cmp	[si].dcmode,7
	je	wrcha0
	mov	bh,bl
	xor	bh,bh
	mov	ah,9
	call	callb50 		; call bios with dx in 40:0050
	ret
wrcha0:
	mov	ah,bl			; attr
	mov	es,[si].dcpscr
	mov	di,[si].crsofs
	cmp	[si].dcsnow,0
	jne	wrcha1
	rep	stosw
	ret
wrcha1:
	mov	dx,[si].dcaddr
	add	dx,6
	mov	bx,ax
	mov	ah,01h
	jcxz	wrchax
wrcha2:
	in	al,dx
	test	al,ah
	jnz	wrcha2
	cli
wrcha3:
	in	al,dx
	test	al,ah
	jz	wrcha3
	mov	ax,bx			; char/attr
	stosw
	sti
	mov	ah,01h			; for bit test
	dec	cx
	jnz	wrcha2
wrchax:
	ret
wrchatr endp

	subttl setpalet - set color palette or background color
	page
;======================================================================
;,fs
; setpalet - set color palette or background color
;
; in:	ah = 09h - set color palette or background color
;	bl = byte as stored in crt_palette by ibm bios
;	bl and 1fh = background color)
;	bl and 20h = 20h for palette 1 else palette 0
;	ds:si -> tcbddt
;
; out:	
;
;,fe
;=====================================================================
	assume	ds:tcb,es:nothing,ss:nothing
setpalet proc near
	test	[si].dcmode,80h
	jnz	setp0
	cmp	[si].dcmode,7
	jne	setp1a
setp0:
	ret
setp1a:
	mov	ds,[sbios2]		; access bios data segment
	mov	al,ds:[0066h]
	push	ax
	push	bx
	mov	bh,0
	and	bl,1fh
	mov	ah,11
	call	callint
	pop	bx
	mov	bh,1
	and	bl,20h
	mov	cl,5
	shr	bl,cl
	mov	ah,11
	call	callint
	pop	ax
	mov	ds:[0066h],al
	ret
setpalet endp

	subttl wrtty - as described by the ibm pc write tty function
	page
;======================================================================
;,fs
; wrtty - as described by the ibm pc write tty function
;
; in:	ah = 0ah - write tty at row & col & page
;	al = char to write
;	bl = attribute in graphics mode for mc only)
;	dh = row
;	dl = col
;	ds:si -> tcbddt
;	[tcbddt] = dword -> screen buffer @ page/row/col
;
; out:	
;
;,fe
;=====================================================================
	assume	ds:tcb,es:nothing,ss:nothing
wrtty proc near
	call	exposreal
	push	ds
	mgetscb2 ds
	assume	ds:grp
	mov	ds,[scbtcbpc]		; current task in 43 line mode?
	assume	ds:tcb
	cmp	[tcbrows],25
	pop	ds
	ja	wrtbio			; for 43 line mode support
	cmp	[si].dcmode,4
	jb	wrt0
	cmp	[si].dcmode,7
	je	wrt0
wrtbio:
	mov	ah,0eh
	call	callb50 		; call bios with dx into 40:0050
	ret
wrt0:
	mov	di,[si].crsofs
	mov	es,[si].dcpscr
	cmp	al,0dh
	ja	wrtty2
	je	wrtty0d
	cmp	al,0ah
	je	wrtty6
	cmp	al,08h
	je	wrtty08
	cmp	al,07h
	jne	wrtty2

;%%%% until ega beep doesn't hang up

	mov	ah,14			; let bios do the beep
	call	callint
	jmp	wrttyx
wrtty0d:
	mov	al,dl
	xor	ah,ah
	shl	ax,1
	sub	di,ax
	xor	dl,dl
	jmp	wrttyx
wrtty08:
	or	dl,dl
	jz	wrtty08a
	dec	di
	dec	di
	dec	dl
wrtty08a:
	jmp	wrttyx
wrtty2:
	mov	cx,dx
	cmp	[si].dcsnow,0
	je	wrtty5
	mov	bl,al
	mov	ah,01
	mov	dx,[si].dcaddr
	add	dx,6
wrtty3:
	in	al,dx
	test	al,ah
	jnz	wrtty3
	cli
wrtty4:
	in	al,dx
	test	al,ah
	jz	wrtty4
	mov	al,bl
wrtty5:
	stosb
	sti
	mov	dx,cx
	inc	di
	inc	dl
	cmp	dl,[si].dcpcol
	jnb	wrtty5a
	jmp	wrttyx
wrtty5a:
	xor	dl,dl
	jmp	wrtty6a
wrtty6:
	mov	al,[si].dcpcol
	xor	ah,ah
	shl	ax,1
	add	di,ax
wrtty6a:
	inc	dh
	push	ds
	mgetscb2 ds
	assume	ds:grp
	mov	ds,[scbtcbpc]
	assume	ds:tcb
	cmp	dh,[tcbrows]		; make it generic
	pop	ds
	jnb	wrtty6b
	jmp	wrttyx
wrtty6b:
	mov	al,[si].dcpcol
	xor	ah,ah
	shl	ax,1
	sub	di,ax
	dec	dh
	push	ds
	push	si
	cmp	[si].dcsnow,0
	je	wrtty9
	mov	bx,dx
	mov	dx,[si].dcaddr
	mov	cx,ds
	xchg	si,di
	mov	ax,es
	mov	ds,ax
	inc	si
	mov	ah,01h
	add	dx,6
wrtty7:
	in	al,dx
	test	al,ah
	jnz	wrtty7
	cli
wrtty8:
	in	al,dx
	test	al,ah
	jz	wrtty8
	lodsb
	sti
	mov	dx,bx
	mov	bl,al
	xchg	si,di
	dec	di
	dec	di
	mov	ds,cx
	jmp	wrtty10
wrtty9:
	mov	bl,es:[di+1]
wrtty10:
	pop	si
	pop	ds
	push	di
	push	dx
	push	ds
	push	si
	push	bx
	mov	bx,[si].dcpscr
	mov	dx,[si].dcaddr
	mov	cx,[si].dcpscrl
	mov	al,[si].dcpcol
	xor	di,di
	xor	ah,ah
	shl	ax,1
	sub	cx,ax
	shr	cx,1
	cmp	[si].dcsnow,0
	mov	si,ax
	je	wrtty12
	add	dx,6
wrtty11:
	in	al,dx
	test	al,08h
	jz	wrtty11
	sub	dx,2
	call	vidoff			; turn video off
wrtty12:
	mov	ds,bx			; dcpscr
	mov	es,bx
	rep	movsw
	pop	bx
	pop	si
	pop	ds
	mov	ah,bl
	mov	al,20h
	mov	cl,[si].dcpcol
	xor	ch,ch
	rep	stosw
	cmp	[si].dcsnow,0
	je	wrtty13
	push	ds
	mov	ds,[sbios2]
	mov	al,ds:[0065h]
	or	al,08h
	mov	ds:[0065h],al
	out	dx,al
	pop	ds
wrtty13:
	pop	dx
	pop	di
wrttyx:
	cmp	dx,[si].dcpcrs
	je	wrttyy
	mov	[si].dcpcrs,dx
	mov	cx,di
	shr	cx,1
	mov	dx,[si].dcaddr
	mov	al,14
	out	dx,al
	jmp	$+2
	mov	al,ch
	inc	dx
	out	dx,al
	jmp	$+2
	mov	al,15
	dec	dx
	out	dx,al
	jmp	$+2
	mov	al,cl
	inc	dx
	out	dx,al
wrttyy:
	ret
wrtty endp

	subttl wrstr - write a string of characters (and attributes)
	page
;======================================================================
;,fs
; wrstr - write a string of characters (and attributes)
;
; in:	ah = 0bh - write string of characters and attributes at page/row/col
;	cx = number of chars to write
;	al:dh = row
;	dl = col
;	ds:si -> tcbddt
;	[tcbddt] = dword -> screen buffer @ page/row/col
;	es:di -> string
;
; out:	
;
;,fe
;=====================================================================
	assume	ds:tcb,es:nothing,ss:nothing
wrstr proc near
	call	exposreal
	push	ds
	mgetscb2 ds
	assume	ds:grp
	mov	ds,[scbtcbpc]
	assume	ds:tcb
	cmp	[tcbrows],25
	pop	ds
	ja	wrst0			; 43 mode goes to bios
	cmp	[si].dcmode,4
	jb	wrst0
	cmp	[si].dcmode,7
	je	wrst0

; string write in graphics mode

	test	[si].dcmode,80h
	jz	wrstg0
	jmp	wrsherc
wrstg0:
	mov	bx,es
	mov	ax,di
	mov	es,[si].dcpscr
	mov	di,[si].crsofs
	mov	si,ax
	mov	ds,bx
	mov	bx,cx
	mov	cl,80
	xor	ch,ch
	sub	cl,dl
	shr	cl,1
	test	dh,01h			; even/odd line bit
	jnz	wrsg3
wrsg1:
	sub	bx,cx
	jae	wrsg2

; write doesn't extend past end of row

	add	cx,bx
	xor	bx,bx
wrsg2:
	rep	movsw
	mov	cx,40
	add	di,2000h-80
	or	bx,bx
	jz	wrsg5
wrsg3:
	sub	bx,cx
	jae	wrsg4
	add	cx,bx
	xor	bx,bx
wrsg4:
	rep	movsw
	mov	cx,40
	sub	di,2000h
	or	bx,bx
	jnz	wrsg1
wrsg5:
	ret

; string write in alpha mode

wrst0:
	cmp	[si].dcsnow,0
	jne	wrst1
	mov	bx,es
	mov	ax,di
	mov	es,[si].dcpscr
	mov	di,[si].crsofs
	mov	si,ax
	mov	ds,bx
	rep	movsw
	ret
wrst1:
	mov	dx,[si].dcaddr
	add	dx,6
	mov	bx,es
	mov	ax,di
	mov	es,[si].dcpscr
	mov	di,[si].crsofs
	mov	si,ax
	mov	ds,bx
	jcxz	wrstx
wrst2:
	lodsw
	mov	bx,ax
	mov	ah,01h
wrst3:
	in	al,dx
	test	al,ah
	jnz	wrst3
	cli
wrst4:
	in	al,dx
	test	al,ah
	jz	wrst4
	mov	ax,bx
	stosw
	sti
	dec	cx
	jnz	wrst2
wrstx:
	ret

; write string in hercules graphics mode

wrsherc:
	mov	ah,al
	test	[si].dcmode,40h 	; make sure of page 0
	jz	wrsh0a
	mov	bx,dx
	mov	dx,03b8h
	mov	al,0ah
	out	dx,al
	mov	dx,bx
	and	[si].dcmode,not 40h
wrsh0a:
	mov	bx,es
	push	di
	mov	es,[si].dcpscr
	mov	al,dh			; computing ( line / 4 ) * 90 + col
	mov	di,ax
	shr	di,1
	shr	di,1
	mov	ax,di
	shl	di,1			; di = line / 4
	shl	di,1
	shl	di,1
	add	di,ax			; di = ( line / 4 ) * 9
	mov	ax,di
	shl	di,1
	shl	di,1
	add	di,ax
	shl	di,1			; di = ( line / 4 ) * 9 * 10
	mov	al,dl
	xor	ah,ah
	add	di,ax			; + col
	mov	ah,[si].dcvmode
	pop	si
	mov	ds,bx
	mov	bx,cx
	mov	cl,90			; hercules mode 90 bytes / line
	mov	ch,45
	test	ah,80h
	jnz	wrsh0
	mov	cl,80			; cga mode 80 bytes / line
	mov	ch,40
	add	di,(348-200)/2/4*90+(90-80)/2  ; offset into hercules screen
wrsh0:
	sub	cl,dl
	shr	cl,1
	mov	dl,ch			; words/line
	xor	ch,ch			; cx = words remaining in first line
	mov	al,dh
	xor	dh,dh
	and	al,03h
	jz	wrsh1
	add	di,2000h
	cmp	al,1
	je	wrsh3
	add	di,2000h
	cmp	al,2
	je	wrsh5
	add	di,2000h
	jmp	wrsh7

; hercules bank 1

wrsh1:
	sub	bx,cx
	jae	wrsh2

; write doesn't extend past end of row

	add	cx,bx
	xor	bx,bx
wrsh2:
	rep	movsw
	mov	cl,dl
	add	di,2000h
	sub	di,dx
	sub	di,dx
	or	bx,bx
	jz	wrsh9

; hercules bank 2

wrsh3:
	sub	bx,cx
	jae	wrsh4

; write doesn't extend past end of row

	add	cx,bx
	xor	bx,bx
wrsh4:
	rep	movsw
	mov	cl,dl
	add	di,2000h
	sub	di,dx
	sub	di,dx
	or	bx,bx
	jz	wrsh9

; hercules bank 3

wrsh5:
	sub	bx,cx
	jae	wrsh6

; write doesn't extend past end of row

	add	cx,bx
	xor	bx,bx
wrsh6:
	rep	movsw
	mov	cl,dl
	add	di,2000h
	sub	di,dx
	sub	di,dx
	or	bx,bx
	jz	wrsh9

; hercules bank 4

wrsh7:
	sub	bx,cx
	jae	wrsh8
	add	cx,bx
	xor	bx,bx
wrsh8:
	rep	movsw
	mov	cl,dl
	sub	di,2000h*3
	sub	di,dx
	sub	di,dx
	add	di,90
	or	bx,bx
	jnz	wrsh1
wrsh9:	        
	ret
wrstr endp

	subttl setwindow - re-display the top or bottom 24 lines
	page
;======================================================================
;,fs
; setwindow - re-display the top or bottom 24 lines
;
; in:	ah = 0ch - put screen
;	al = 0 - re-display top lines of screen    (top display page)
;	     1 - re-display bottom lines of screen (bottom display page)
;	cx = screen length (words)
;	ds:si -> tcbddt
;	[tcbddt] = dword -> screen buffer @ page/row/col
;
; out:	
;
;,fe
;=====================================================================
	assume	ds:tcb,es:nothing,ss:nothing
setwindow proc near
	call	exposreal
	cmp	[si].dcmode,4
	jb	setw0
	cmp	[si].dcmode,7
	je	setw0
	test	[si].dcmode,80h
	jz	setwg1
	jmp	setwherc
setwg1:

; screen write in graphics mode
; hard coded for modes 4, 5, 6 currently (200 lines, 40 words/line)

	mov	bx,di
	mov	es,[si].dcpscr
	mov	di,[si].crsofs		; copying from vidram buffer to
	lds	si,[si].logscr		; the physical memory.	(vidram is
	mov	cx,4000 		; temporarily mapped into the
	call	wordmov 		; scbmastv memory area for this.)
	add	di,192
	add	si,192
	mov	cx,4000
	call	wordmov
	ret
setw0:
	cmp	[si].dcsnow,0
	je	setw2
	mov	dx,[si].dcaddr		; 6845 base port
	add	dx,6
setw1:
	in	al,dx
	test	al,08h
	jz	setw1
	sub	dx,2
	call	vidoff			; turn video off
setw2:
	mov	es,[si].dcpscr
	mov	di,[si].crsofs
	lds	si,[si].logscr
	call	wordmov
	mov	ds,[sbios2]
	mov	al,ds:[0065h]
	test	al,08h
	jnz	setw3
	or	al,08h
	mov	ds:[0065h],al
	out	dx,al
setw3:
	ret

; set window in hercules mode

setwherc:
	test	[si].dcvmode,80h
	jnz	setwhgc

; emulating cga

	mov	es,[si].dcpscr
	mov	di,[si].crsofs		; copying from vidram buffer to
	lds	si,[si].logscr		; the physical memory.	(vidram is
	add	di,(348-200)/2/4*90+(90-80)/2  ; offset into hercules screen
	mov	ax,di
	call	swhgc
	add	si,192
	mov	di,ax
	add	di,2000h		; to start of odd lines
	call	swhgc
	ret

; truly in hercules mode

setwhgc:
	or	al,al
	mov	ax,[si].dcpscr
	jz	setwhg1 		; first display page
	or	ah,08h			; else second
setwhg1:
	mov	es,ax
	mov	di,[si].crsofs		; copying from vidram buffer to
	lds	si,[si].logscr		; the physical memory.	(vidram is
	mov	cx,7830/2		; temporarily mapped into the
	call	wordmov 		; scbmastv memory area for this.)
	add	di,362
	add	si,362
	mov	cx,7830/2
	call	wordmov
	add	di,362
	add	si,362
	mov	cx,7830/2
	call	wordmov
	add	di,362
	add	si,362
	mov	cx,7830/2
	call	wordmov
	ret

; copy a single cga buffer to a hercules-oriented buffer

swhgc:
	mov	bx,50
swhg1:
	mov	cx,40
	rep	movsw
	add	di,4000h-80
	mov	cx,40
	rep	movsw
	sub	di,4000h+80-90
	dec	bx
	jnz	swhg1
	ret
setwindow endp

	subttl wrcho - write char only
	page
;======================================================================
;,fs
; wrcho - write char only
;
; in:	ah = 0dh - write char only at row & col
;	al = char to write
;	cx = number of times to write
;	dh = row
;	dl = col
;	ds:si -> tcbddt
;	[tcbddt] = dword -> screen buffer @ page/row/col
;
; out:	
;
;,fe
;=====================================================================
	assume	ds:tcb,es:nothing,ss:nothing
wrcho proc near
	call	exposreal
	cmp	[si].dcmode,4
	jb	wrcho0a
	cmp	[si].dcmode,7
	je	wrcho0a
	xor	bh,bh
	mov	ah,0ah
	call	callb50 		; call bios with dx into 40:0050
	ret
wrcho0a:
	mov	es,[si].dcpscr
	mov	di,[si].crsofs
	cmp	[si].dcsnow,0
	jne	wrcho1
	jcxz	wrchox
wrcho0:
	stosb
	inc	di
	dec	cx
	jnz	wrcho0
	ret
wrcho1:
	mov	dx,[si].dcaddr
	add	dx,6
	mov	bl,al
	mov	ah,01h
	jcxz	wrchox
wrcho2:
	in	al,dx
	test	al,ah
	jnz	wrcho2
	cli
wrcho3:
	in	al,dx
	test	al,ah
	jz	wrcho3
	mov	al,bl
	stosb
	sti
	inc	di
	dec	cx
	jnz	wrcho2
wrchox:
	ret
wrcho endp

	subttl readch - read char/attribute at row & col & page
	page
;======================================================================
;,fs
; readch - read char/attribute at row & col & page
;
; in:	ah = 0eh - read char/attribute at row & col & page
;	  (master console only)
;	dh = row
;	dl = col
;	ds:si -> tcbddt
;	[tcbddt] = dword -> screen buffer @ row/col/page
;
; out:	
;
;,fe
;=====================================================================
	assume	ds:tcb,es:nothing,ss:nothing
readch proc near
	call	exposreal
	cmp	[si].dcmode,4
	jb	rdch0
	cmp	[si].dcmode,7
	je	rdch0
	xor	di,di
	xor	bh,bh
	mov	ah,08h
	call	callb50 		; call bios with dx into 40:0050
	ret
rdch0:
	mov	es,[si].dcpscr
	mov	di,[si].crsofs
	cmp	[si].dcsnow,0
	jne	rdch1
	mov	ax,es:[di]
	ret
rdch1:
	mov	dx,[si].dcaddr
	mov	cx,es
	mov	ds,cx
	mov	si,di
	add	dx,6
	mov	ah,01h
rdch2:
	in	al,dx
	test	al,ah
	jnz	rdch2
	cli
rdch3:
	in	al,dx
	test	al,ah
	jz	rdch3
	lodsw
	sti
	ret
readch endp

	subttl getscr - get screen
	page
;======================================================================
;,fs
; getscr - get screen
;
; in:	ah = 0fh - get screen
;	master console only)
;	al = 0 first page, 1 second page (hercules)
;	ds:si -> tcbddt
;	[tcbddt] = dword -> logical screen buffer
;	cx = word length to get
;
; out:	
;
;,fe
;=====================================================================
	assume	ds:tcb,es:nothing,ss:nothing
getscr proc near
	call	exposreal
	cmp	[si].dcmode,4
	jb	gets0
	cmp	[si].dcmode,7
	je	gets0

; screen retrieve in graphics mode
; hard coded for modes 4, 5, 6 currently (200 lines, 40 words/line)

	test	[si].dcmode,80h
	jz	getsg0
	jmp	getsherc		; get screen in hercules mode
getsg0:
	les	di,[si].logscr
	mov	ds,[si].dcpscr
	mov	si,di
	mov	bx,100
getsg1:
	mov	cx,40
	rep	movsw
	add	si,2000h-80
	mov	cx,40
	rep	movsw
	sub	si,2000h
	dec	bx
	jnz	getsg1
	ret
gets0:
	cmp	[si].dcsnow,0
	je	getsc1			; e if don't have to worry about snow
	mov	dx,[si].dcaddr		; 6845 base port
	add	dx,6
getsc0:
	in	al,dx
	test	al,08h
	jz	getsc0
	sub	dx,2
	call	vidoff			; turn video off
getsc1:
	mov	ax,[si].dcpscr
	les	di,[si].logscr		; logical screen address
	mov	si,[si].crsofs		; physical screen address
	mov	ds,ax
	call	wordmov
	mov	ds,[sbios2]
	mov	al,ds:[0065h]
	test	al,08h
	jnz	getsc2
	or	al,08h
	mov	ds:[0065h],al
	out	dx,al
getsc2:
	ret

; get screen in hercules mode

getsherc:
	test	[si].dcvmode,80h
	jnz	getshgc

; emulating cga mode

	mov	cx,[si].dcpscr
	mov	di,[si].crsofs		; copying from vidram buffer to
	les	si,[si].logscr		; the physical memory.	(vidram is
	mov	ds,cx			; temporarily mapped into the
	xchg	di,si			; scbmastv memory area for this.)
	add	si,(348-200)/2/4*90+(90-80)/2  ; offset into hercules screen
	mov	bx,200/2
getshc1:
	mov	cx,40
	rep	movsw
	add	si,2000h-80
	mov	cx,40
	rep	movsw
	add	si,2000h-80
	mov	cx,40
	rep	movsw
	add	si,2000h-80
	mov	cx,40
	rep	movsw
	sub	si,2000h*3-80+90
	dec	bx
	jnz	getshc1
	ret

; truly in hercules mode

getshgc:
	mov	cx,[si].dcpscr
	or	al,al
	jz	getsh0
	or	ch,08h
getsh0:
	mov	di,[si].crsofs		; copying from vidram buffer to
	les	si,[si].logscr		; the physical memory.	(vidram is
	mov	ds,cx			; temporarily mapped into the
	xchg	di,si			; scbmastv memory area for this.)
	mov	bx,348/4
getsh1:
	mov	cx,45
	rep	movsw
	add	si,2000h-90
	mov	cx,45
	rep	movsw
	add	si,2000h-90
	mov	cx,45
	rep	movsw
	add	si,2000h-90
	mov	cx,45
	rep	movsw
	sub	si,2000h*3
	dec	bx
	jnz	getsh1
	ret
getscr endp

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
; out:	returns ah as in int 17h call
;
;,fe
;=====================================================================
	assume	ds:nothing,es:nothing,ss:nothing
prch proc near
	mov	ah,1			; indicate error
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
; out:	returns ah as in int 17h call if all of string can't be printed
;	di -> first char not printed, cx = number not printed
;
;,fe
;=====================================================================
	assume	ds:nothing,es:nothing,ss:nothing
prstr proc near
	mov	ah,1			; indicate error
	ret
prstr endp

	subttl print_stat - get printer status
	page
;======================================================================
;,fs
; print_stat - get printer status
;
; in:	ah = 12h
;	ds:si -> tcbddt
;
; out:	returns ah as in int 17h call for bad status
;
;,fe
;=====================================================================
	assume	ds:nothing,es:nothing,ss:nothing
print_stat proc near
	mov	ah,11h
	ret
print_stat endp

	subttl mcsuparg - mcscrit arguments for scrolling up
	page
;======================================================================
;,fs
; mcsuparg - mcscrit arguments for scrolling up
;
; in:	al = number of lines to scroll (0 to clear region)
;	bl = attribute to use on blanked lines
;	ch = top-left-corner row
;	cl = top-left-corner col
;	dh = bottom-right-corner row
;	dl = bottom-right-corner col
;	ds -> terminal tcb
;	es -> screen buffer
;
; out:	
;
;,fe
;=====================================================================
	assume	ds:tcb,es:nothing,ss:nothing
mcsuparg proc near
	mov	si,cx			; temp save top left
	push	bx
	mov	bx,ax			; temp save # to scroll
	inc	dl
	inc	dh
	sub	dl,cl
	mov	cl,dl			; number of cols/box
	sub	dh,ch			; number of rows/box
	or	al,al
	jnz	mcsup1
	mov	al,dh
mcsup1: 				; al = number of lines to blank
	sub	dh,al
	jae	mcsup2			; dh = number of lines to move
	add	al,dh			; blank all lines
	xor	dh,dh			; move no lines
mcsup2:
	mov	dl,al			; dl = number to blank
	xchg	dh,dl
	xor	ch,ch			; cx = length (words) to move for each line
	push	dx			; dh = number to blank, dl = number to move
	mov	dx,si			; get top left back
	call	mcpos			; calc offset in buffer for this cur pos
	add	dh,bl			; calc source line for move
	push	di
	call	mcpos			; calc offset into buffer
	mov	si,di
	pop	di
	mov	al,ds:[bp].dcpcol
	xor	ah,ah
	shl	ax,1
	shl	cx,1
	sub	ax,cx			; add end to get from end of one line to start
	shr	cx,1			;   of next line
	pop	dx
	pop	bx
	xchg	ax,bx
	mov	ah,al
	mov	al,20h
	mov	es,ds:[bp].dcpscr
	ret
mcsuparg endp

	subttl mcsdnarg - mcscrit args for scrolling down
	page
;======================================================================
;,fs
; mcsdnarg - mcscrit args for scrolling down
;
; in:	al = number of lines to scroll (0 to clear region)
;	bl = attribute to use on blanked lines
;	ch = top-left-corner row
;	cl = top-left-corner col
;	dh = bottom-right-corner row
;	dl = bottom-right-corner col
;	ds -> terminal tcb
;	es -> screen buffer
;
; out:	
;
;,fe
;=====================================================================
	assume	ds:tcb,es:nothing,ss:nothing
mcsdnarg proc near
	mov	si,bx
	mov	bl,cl
	mov	bh,dh
	xchg	si,bx			; si = row, col of destination for first line
	push	bx
	mov	bx,ax			; temp save # lines to scroll
	inc	dl
	inc	dh
	sub	dl,cl
	mov	cl,dl			; number of cols/box
	sub	dh,ch
	or	al,al
	jnz	mcsdn1
	mov	al,dh
mcsdn1:
	sub	dh,al
	jae	mcsdn2
	add	al,dh			; blank all the lines if more scrolled than in box
	xor	dh,dh			; leaving none to move
mcsdn2:
	mov	dl,al
	xchg	dh,dl
	xor	ch,ch			; cx = length (words) to move for each line
	push	dx			; dh = number of lines to blank, dl = number to move
	mov	dx,si
	call	mcpos
	sub	dh,bl			; calc cur pos for source
	push	di
	call	mcpos
	mov	si,di
	pop	di
	mov	al,ds:[bp].dcpcol
	xor	ah,ah
	shl	ax,1
	shl	cx,1
	add	ax,cx			; addend from get from end of box to beginning of box
	shr	cx,1
	neg	ax			;   going backwards in screen
	pop	dx
	pop	bx
	xchg	ax,bx
	mov	ah,al
	mov	al,20h
	mov	es,ds:[bp].dcpscr
	ret
mcsdnarg endp

	subttl mcpos - offset into screen buffer page of row & col
	page
;======================================================================
;,fs
; mcpos - offset into screen buffer page of row & col
;
; in:	dh = row
;	dl = col
;	ds -> terminal tcb
;	es -> screen buffer
;
; out:	
;
;,fe
;=====================================================================
	assume	ds:tcb,es:nothing,ss:nothing
mcpos proc near
	mov	al,dh
	xor	ah,ah
	shl	ax,1
	shl	ax,1
	shl	ax,1
	cmp	ds:[bp].dcpcol,40
	je	mcpos1
	shl	ax,1
mcpos1:
	mov	di,ax			; row*16 or row*8
	shl	ax,1
	shl	ax,1
	add	di,ax			; row*80=row*16+row*64 or row*40=row*8+row*32
	mov	al,dl
	xor	ah,ah
	add	di,ax			; + col
	add	di,di			; * 2 for char/attribute
	ret
mcpos endp

	subttl mcscrit - main buffer scroll (up and down)
	page
;======================================================================
;,fs
; mcscrit - main buffer scroll (up and down)
;
; in:	es:si = source for first line
;	es:di = dest for first line
;	cx = number of chars/line
;	bx = add to source and dest
;	ax = char and attribute for blank lines
;	dh = number of lines to blank
;	dl = number of lines to move
;
; out:	
;
;,fe
;=====================================================================
	assume	ds:tcb,es:nothing,ss:nothing
mcscrit proc near
	push	ds
	push	bp
	cmp	ds:[bp].dcsnow,0	; compare used below
	mov	bp,ds:[bp].dcaddr
	push	es
	pop	ds
	je	mcsa2			; from comparison above
	push	ax
	push	dx
	mov	dx,bp
	add	dx,6
mcsa1:
	in	al,dx
	test	al,08h
	jz	mcsa1
	sub	dx,2
	call	vidoff			; turn video off
	pop	dx
	pop	ax
mcsa2:
	or	dl,dl
	jz	mcsb
mcsa3:
	push	cx
	rep	movsw
	pop	cx
	add	si,bx
	add	di,bx
	dec	dl
	jnz	mcsa3
mcsb:
	or	dh,dh
	jz	mcsd
mcsc:
	push	cx
	rep	stosw
	pop	cx
	add	di,bx
	dec	dh
	jnz	mcsc
mcsd:
	mov	ds,[sbios2]
	mov	al,ds:[0065h]
	test	al,08h
	jnz	mcsd0
	or	al,08h
	mov	ds:[0065h],al
mcsd0:
	mov	dx,bp
	add	dx,4
	out	dx,al
mcsd1:
	pop	bp
	pop	ds
	ret
mcscrit endp

	subttl callb50 - call bios and set 40:0050 to value in dx
	page
;======================================================================
;,fs
; callb50 - call bios and set 40:0050 to value in dx
;
; in:	
;
; out:	
;
;,fe
;=====================================================================
	assume	ds:tcb,es:nothing,ss:nothing
callb50 proc near
	mov	ds,[sbios2]		; access bios data segment
	push	word ptr ds:[0050h]
	mov	ds:[0050h],dx
	call	callint
	pop	word ptr ds:[0050h]
	ret
callb50 endp

	subttl vidoff - turn video off
	page
;======================================================================
;,fs
; vidoff - turn video off
;
; in:	
;
; out:	
;
;,fe
;=====================================================================
	assume	ds:tcb,es:nothing,ss:nothing
vidoff proc near
	push	ds
	mov	ds,[sbios2]
	mov	al,ds:[0065h]
	and	al,not 08h
	mov	ds:[0065h],al
	out	dx,al
	pop	ds
	ret
vidoff endp

ddt	ends
	end

