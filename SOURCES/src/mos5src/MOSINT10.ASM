	include page.inc
	title	mosint10.asm - pc bios int 10 emulation
comment ^==============================================================
		development specification

 program name:	mos			assigned to: jim bean
 module name:	mosint10		assign date: 09/30/86
 entry points:	mosint10		completed:   11/01/86
 entry from:	anywhere
 entry method:	int 10h
 calls:		mosddtxx
 purpose:	intercept pc bios int 10h video calls and interpret
		in terms of terminal device driver functions
 refer to:	n/a
 last update:	08/18/1992
========================================================================

dam 11/24/86	added function 19 - print string (as per at bios)

jsm 04/30/87	use short form mossaver for register saves

jsm 05/02/87	use local stack switching code instead of mossaver for
		speed

jsm 05/04/87	update screen save buffers properly for multiple line
		scrolls (scruparg & scrdnarg).

sah 05/04/87	remove setting bios equipment flags on function 00 and
		not allowing mono <> color changes

sah 05/11/87	improve ega support and 43 line support (application)

sah 05/13/87	ega support for main console while other tasks are active

sah 07/20/87	corrected bug where terminal were disappearing randomly
		because vidram timer value was getting set to 0 which
		means that vidram updating was turn off.

sah 07/30/87	added logic in code which would only allow vidram to be
		called once while task is suspended. jsm suspected this

sah 08/04/87	added logic so that topview int 10h functions will
		inc keyboard counter for dis so that wordperfect will
		work in dis mode correctely. because it is making topview
		calls. functions fe and ffh

mjs 09/04/87	added a control flag (vdrskip) to the vidram check
		procedure to allow pamswitching to temporarily diable
		vidram checking.

sah 09/09/87	alter control of tcbega so that state-paming will use
		other bits of the byte

sah 09/29/87	added functionallity to function 10 of the ega bios
		to store the pallettes on the ega into a 17 byte array
		tcbegapal.  (this is usefull in multi-task ega world)

jrb 10/22/87	various updates for hercules support

sah 10/26/87	skip vidram checking if using ega\vga state logic
		(no need - does not apply)

jrb 10/29/87	want to support master console only stuff for ali card
		so cononly recognizes as mc only an mc which supports
		hercules modes and is in a hercules mode

jrb 11/05/87	instead of scbhinmc, now using allowhio and denyhio to
		turn on and off hercules i/o protection for those times
		when we need to get at the port ourselves

sah 11/10/87	set up ega pallettes depending on mode during function 00
		(set mode).  following table is use for ega pallette vals

	mode   00-01-02-03-04-05-06-07-08-09-0a-0b-0c-0d-0e-0f	 over
   ------------------------------------------------------------------
	 00    00 01 02 03 04 05 06 07 10 11 12 13 14 15 16 17	  00
	 01    00 01 02 03 04 05 06 07 10 11 12 13 14 15 16 17	  00

!!!!! this table out of date - see the table in vf00 !!!!!!

	 02    00 01 02 03 04 05 06 07 10 11 12 13 14 15 16 17	  00
	 03    00 01 02 03 04 05 06 07 10 11 12 13 14 15 16 17	  00
	 04    00 13 15 17 02 04 06 07 10 11 12 13 14 15 16 17	  00
	 05    00 13 15 17 02 04 06 07 10 11 12 13 14 15 16 17	  00
	 06    00 17 17 17 17 17 17 17 17 17 17 17 17 17 17 18	  00

sah 11/12/87	corrected 43 line mode cursor pos. problem by after
		doing vfnul (function 12) check bios 40:0084h and
		checking to see if greater than 25 rows, if so set
		tcbrows according.  also remove
		reduntant tcbrows setting inside of function 00

sah 11/15/87	fixed some problem on above implementation
		for resident programs like ps and sidekick(+)

sah 11/16/87	fixed the fixed above for ws 4.00

sah 11/18/87	support for high bit on int 10 function 00 which means
		not to clear buffer.	this corrected probems with
		doing a help command on autocad.

sah 11/23/87	corrected bugs in 43 line support logic

sah 12/03/87	added code to inc scbinmos before int 10 (if no saver)
		and dec scbinmos after int 10 (if not 0)

sah 12/16/87	added 3d8 int 3 support

sah 01/21/88	change scbseg and zero seg to mgetxxxx macros
		optimize decrement inmos flag with calls to decimos
		removes some relundent ds loads for calls to gvram

sah 01/25/88	replace scbseg reference with mo2seg

jrb 02/11/88	no vidram check unless at least on person is looking

rbr/sah 02/20/88 move ddt code to mo2 group.

sah 03/06/88	made changes for sk(+) "Thanks to some insight from ROD
		and techinical information which i have"  Change
		how scbinmos works (should have 2 values only	0 = not
		busy,	1 = busy.

mjs 3/9/88	moved a set of tests at the start of the nvidram proc.
		was possible to skip the part of vidram logic that reset
		the poll timer which resulted in vidram being disabled.

sah 05/20/88	my 03/06/88 was incorrect. after running a test program
		on dos, indos flag is actual increment and decrement.
		to give a consistent and easy changable interface to
		to scbinmos i implement the following routines
			decinmos - decrements inmos flag is not zero
			incinmos - increments inmod flag
		remove handling of inmos flag is this module, tsr will
		check if in bios and not allow to be interupted

jrb 06/15/88	changes to hercules code to disallow physically enabling
		2nd page unless master console is hercules or hidden
		(disabled ega/vga)
		allow somebody to be cononly even if it's tcbvidw2
		differs from scbvidad (like ega mc and vna task)

rdg 07/06/88	added subroutine ddtcall to gate all output producing
		calls to the console device drivers.  this was done to
		prevent corruption of the serial data stream being sent
		to a terminal.
		modified cursynch and vidram to skip an update if it was
		requested during a suspension caused by a full serial
		buffer.
		changed all calls to the console device driver from
		call dword ptr [si] to call ddtcall			

sah 07/18/88	correct int initialization of ega pallettes
		cleaned up source module

sah 08/04/88	at beginning of int 10, got current cursor position from
		bios data area and place in tcb.  this was necessary
		because unisys 386 bios depends on this.

mjs 8/15/88	reversed jrb's change to cononly of 6/15/88 - need to
		find a different way to support ega/vna.  removing this
		tcbvidw2 == scbvidad test causes direct video to go to
		the wrong display in certain cases.
		also, cleaned up this module - trimmed out over 10,000
		bytes.

sah 08/23/88	corrected problem with autocad and scrolling

jrb 09/16/88	problem w/ lotus can't exit herc graphics mode

mjs 09/17/88	changed vf0f to report video mode from biomode rather
		than from tcbmode.  this is to correct a jumpy mouse
		problem with ventura.  ventura pokes a 6 in 40:49 and
		then calls int33, func 0 to initialize the mouse.
		int33, func 0 uses int10, func 0 to get the mode.

mjs 09/23/88	correct words to clear when setting herc mode.
		modified crtint3 logic to match new bank selection
		method.  corrected bug with segment loading order.

mjs 09/27/88	cleaned up the vidram updating logic to fix problems
		relating to bank selection, mapping and serial irqs.

sah 10/02/88	if function is pass onto bios and station (tcbstation)
		is not ega or vga and function is 10h - 1ch then
		function is not passed on.

mjs 10/04/88	modify the crtint3 logic not clear scblastff when hiding
		the master console.
		also, corrected bug when a background task establishes
		a hercules mode - crashing from stack imbalance.

sah 10/10/88	corrected ega palletes for system that have enhanced
		monitor on system.  where pallete 6 should be 14h
		instead of 06h.

sah 10/10/88	move int 3 logic to new module mosint06 for ease of work

sah 10/13/88	applied marty's fix for light pen return AH = 00 for
		function 04h.

mjs 10/25/88	corrected situation in vf0e where vidram could be left
		exposed when it shouldn't be.

sah 12/10/88	correction to function 1112h for vga = tcbrows = 50

sah 03/15/89	added automatic biasing of stack inside int 10 handler
		if switching to mos stack from applications stack. this
		is done to solve the stack problem that we have notice
		debugging with periscope and other debuggers when we are
		are debugging inside of mos's kernel.

mjs 05/17/89	modified the handling of the case where a set mode call
		is made with the high bit of al set.  passing the high
		bit set onto the ddt was causing a vna station to go
		into herc graphics mode.  i modified mosddtmc to check
		bit 6 instead of bit 7 and modified this module to
		set bit6 of al for the ddt if tal bit 7 was set.

mjs 05/26/89	modified my modification from 05/17.  it turns out that
		ddtmc's setmode call uses bit 6 to indicate the herc
		page number.  this was not documented!	i changed my
		code to use bit 5 and changed ddtmc to match.

sah 06/02/89	modified vfnul so that handle the case where work
		station is a monochrome vga style station. don't allow
		hercules or cga to go to bias.	bios could be ega\vga
		and applications could detect ega\vga hardware where
		terminal would not support. monochrome stations is not
		done because pcterm or main console would not have
		access to ega\vga bios.

mjs 06/19/89	added code to store the palette data on int10fun10 calls
		so pamswitching could restore it when ega trapping is
		not being used.

sah 06/26/89	corrections for new definitions for tcbstation for
		monochrome ega and monochrome vga support.

sah 06/27/89	corrections for vmode of ega\vga on monochrome monitors
		mos never took in account of int mode 0f, always
		converted modes to mode 7 if on monochrome systems.

mjs 06/28/89	added mode 7 logic to the initialization of tcbegapal
		and placed an updated palette table in the vf00 code
		removed code which set bit flags in tcbpalfg and
		tcbovsfg

sah 07/17/89	correction for 43 line support, remove resetting of
		tcbrows to 25 line if ah=11h and al <> 12h. this was
		causing brief to not be able to display correctly
		passed the 25th line.

sah 08/10/89	corrections for paint, if hercules force mode to mode 7
		even if mode is 0fh for monochrome vga

mjs 08/12/89	add invidram flag to gdata segment and make nvidram
		set it when a vidram process is started and reset it
		when done.  userpoll tests this flag so that userpoll
		calls made during int8's which occur during vidram
		will not call the user poll handler.  this is to prevent
		mouse droppings.

sah 08/17/89	correction to latest update to correct problem with
		monochrome tasks locking up.

sah 11/08/89	corrections for show partner (fall comdex), function 1bh
		needs di to be past to it.

sah 01/24/90	faster video via wordmov procedure.
		corrections for modes 0dh,11h,12h and 13h

sah 02/02/90	corrections to 01/24/90

sah 02/26/90	corrections for magnavox vga bios, re-entriency int 10

sah 07/23/90	corrections for monochrome vga, windows 3.0

mjs 08/29/90	if the watcher is ega/vga and not doing ega trapping, 
		update the tcbegapal table within the watched task when 
		int10fun0b is called.  this is necessary because when 
		an ega/vga workstation will later pam into this task, we 
		don't want setegapal undoing what pamswitch's set palette 
		call (ddt fun09) because the tcbegapal data isn't up to 
		date.  presuming only one ega/vga watcher will be found 
		at most since mos doesn't support multiple ega/vga watchers

SAH 12/27/90	MJS's correction for Periscope and stack biasing.

mjs 12/28/90	applied further corrections for periscope

SAH 04/05/91	Move getcursor (AH=3) to top INT 10h interupt, improved
		speed no need for stack biasing....  This was done so
		that my change in mosddcon for ansi processing will be
		faster.

SAH 04/23/91	Found a way to speed up INT 10 function 13h, use alot if
		by MOSDDCON if ANSI is off, by accumulating repeated
		characters.  Now all we got to do is make terminal
		driver support string writes.

SAH 06/05/91	Corrections for 1024 by 768 resolution mode 37h and 38h
		Skip MJS's 5/26/89 change if station is not hercules

mjs 06/27/91	made i10f0f not go through mossaver.  this was done
		to gain compatibility with g.e. officewriter which makes
		an i10f0f call from within its int1c handler.

SAH 06/28/91	Changes for display Automination, made sure that high bit
		is past on to terminal driver is workstation is not
		hercules

SAH 07/10/91	Corrections for WordPerfect Office 3.0 Notify TSR, 
		Corrected INT 10h function 0ah usage of SI for pointing
		office to vidram.  Wrong offset was being use if CX <> 1
		so vidram update will be wrong. (Patch 410_p47.pat)

SAH 08/20/91	Corrections for QuickBasic App setting up 60 line mode
		on a VGA using INT 10h function 1123h.

SAH 09/04/91	Remove MJS's 08/29/90 fix to call bios INT 10h function
		1009h - this fix appear to be only necessary on a flakey
		overton?? VGA card and cause slow down for basic application
		which was doing setpallete calls.

SAH  01/11/91	MJS's fix for aladian. Need to make sure that INT 10h
MJS 		function 03h resets tcbcpos from bios data area....

================ 5.01 Kernel Ends Here ====================================

mjs 08/18/92	clean up segment declarations

mjs 08/26/92	delete reference to scbfree

=======================================================================^

.xlist
;	include mosint10.pub
	include options.inc
	include group.inc
	include mosregs.inc
	include macros.inc

tcb	segment at 1234h
	include mostcb.inc
tcb	ends

gdata	segment
	include mosscbex.inc
gdata	ends
.list

gdata	segment

public vdrskip
vdrskip db	'N'			; control flag used by pamswitching to temporarily
					; suspend vidram updates
public vdrirq
vdrirq	db	'N'			; flag to tell the irq logic that vidram is calling
					; the ddt to update the watchers
public invidram
invidram db	'N'			; flag to tell the userpoll routine that a vidram
					; update is in process
gdata	ends

	subttl	irq segment - sepcify a system interrupt handler for mossaver
	page
irq	segment

	dw	10h*4			; offset for this interrupt
public	i10old
i10old	dd	?			; save prior value
i10sav	dw	0			; we don't save changes, we leave them alone
i10new	dw	mos:mosint10		; initial value is here
i10new2 dw	0			; don't change back if application changes it

irq	ends

	subttl	poll segment - specify a polled subroutine for mossaver
	page
;-----------------------------------------------------------------------
; poll segment is used (if needed) within a mos module to specify a
; polled subroutine for mossaver
;-----------------------------------------------------------------------
poll	segment

	dw	mos:vidram
	dw	0
vrmtmr	dw	tcbvrtim

poll	ends

	page
	subttl	bios segment - pc bios defs for bios ram

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
	extrn	mossaver:near, mosrestore:near, decinmos:near, incinmos:near

	public	mosint10, vidram, nosbuf


	subttl mosint10 - pc video bios functions
	page
;======================================================================
;,fs
; mosnt10 - pc video bios functions
;
; if video function is valid, calls the appropriate subroutine,
;   otherwise does nothing
; see individual functions for their descriptions
;
; each partition has a screen save buffer and may have a vidram buffer
;   [tcbscrdd] for a partition points to a tcb whose [tcbcondd] points
;	to the ddt for a terminal looking at the screen, that tcb's
;   that tcb's [TCBNXTDD] points to the next tcb whose [TCBCONDD]
;     to the ddt for another terminal looking at the screen
;   [tcbnxtdd] is 0 when there are no more terminals in the list
;   [tcbscrdd] is 0 when there are no terminals in the list
;
; the screen save buffer reflects what has been sent to the terminals
;   except for the special case where the master console (ddtmc) is
;   the only terminal looking at the screen and vidram is not active.
;   in this case, the screen save buffer is not updated, the assumption
;   is that the screen image can be obtained from the master console if
;   necessary.	this is necessary when another terminal switches to the
;   screen, or when the master console switches to another screen.
;
; the vidram buffer is just like the multilink vidram buffer - at each
;   point, when active, it represents the "true" image of how the
;   screen should appear
;
; the vidram buffer is active and current whenever [tcbvram] bit 0 is
;   set
;
; the master console is pointed to by [tcbcondd] in the tcb whose
;   [tcbvram] bit 7 is set the master console does not use the
;   screen save buffer
;
; the terminal device driver video functions are:
;
; ah = 03h
;   al = 00h, 01h - 40x25 text
;	 02h, 03h, 07h - 80x25 text
;	 04h, 05h - 320x200 graphics
;	 06h - 640x200 graphics
;   ds:si -> tcbddt
;   [tcbddt] = dword -> screen buffer
;
; ah = 04h - set cursor type
;   ch = begin scan line
;   cl = end scan line
;   dh = row
;   dl = col
;   ds:si -> tcbddt
;   [tcbddt] = dword -> screen buffer @ page/row/col
;
; ah = 05h - set physical cursor position
;   dh = row
;   dl = col
;   ds:si -> tcbddt
;   [tcbddt] = dword -> screen buffer @ page/row/col
;
; ah = 06h - scroll up
;   al = number of lines to scroll (0 to clear region)
;   bl = attribute to use on blanked lines
;   ch = top-left-corner row
;   cl = top-left-corner col
;   dh = bottom-right-corner row
;   dl = bottom-right-corner col
;   ds:si -> tcbddt
;   [tcbddt] = dword -> screen buffer @ page/row/col
;
; ah = 07h - scroll down
;   al = number of lines to scroll (0 to clear region)
;   bl = attribute to use on blanked lines
;   ch = top-left-corner row
;   cl = top-left-corner col
;   dh = bottom-right-corner row
;   dl = bottom-right-corner col
;   ds:si -> tcbddt
;   [tcbddt] = dword -> screen buffer @ page
;
; ah = 08h - write character and attribute at row & col & page
;   al = char to write
;   bl = attribute to write
;   cx = number of times to write
;   dh = row
;   dl = col
;   ds:si -> tcbddt
;   [tcbddt] = dword -> screen buffer @ page/row/col
;
; ah = 09h - set color palette or background color
;   bl = byte as stored in crt_palette by ibm bios
;   (bl and 1fh = background color)
;   (bl and 20h = 20h for palette 1 else palette 0
;   ds:si -> tcbddt
;
; ah = 0ah - write tty at row & col & page
;   al = char to write
;   dh = row
;   dl = col
;   ds:si -> tcbddt
;   [tcbddt] = dword -> screen buffer @ page/row/col
;
; ah = 0bh - write string of characters and attributes at page/row/col
;   al = string type code:
;	= 0 string is [char,char,char...], bl = attr
;	= 1 not defined
;	= 2 string is [char,attr,char,attr...]
;   cx = number of chars to write (word length of string)
;   dh = row
;   dl = col
;   ds:si -> tcbddt
;   [tcbddt] = dword -> screen buffer @ page/row/col
;   es:di -> string
;
; ah = 0ch - put screen
;   al = 0 - re-display top lines of screen
;	 1 - re-display bottom lines of screen
;   ds:si -> tcbddt
;   cx = length of screen in words
;   [tcbddt] = dword -> screen buffer @ page/row/col
;
; ah = 0dh - write char only at row & col & page
;   al = char to write
;   cx = number of times to write
;   dh = row
;   dl = col
;   ds:si -> tcbddt
;   [tcbddt] = dword -> screen buffer @ page/row/col
;
; ah = 0eh - read char/attribute at row & col & page
;     (master console only)
;   dh = row
;   dl = col
;   ds:si -> tcbddt
;   [tcbddt] = dword -> screen buffer @ page/row/col
;
; ah = 0fh - get screen
;     (master console only)
;   ds:si -> tcbddt
;   cx = length of screen in words
;   [tcbddt] = dword -> screen buffer
;
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:nothing

fn10	dw	mo2:vf00,mo2:vf01,mo2:vf02,mo2:vfnul
	dw	mo2:vf04,mo2:vf05,mo2:vf06,mo2:vf07
	dw	mo2:vf08,mo2:vf09,mo2:vf0a,mo2:vf0b
	dw	mo2:vf0c,mo2:vf0d,mo2:vf0e,mo2:vf0f
	dw	mo2:vfnul,mo2:vfnul,mo2:vfnul,mo2:vf13
lenfn10 equ	($-fn10)/2
	dw	mo2:vfnul		; slop over for undefined functions

farfn10 proc far
	push	[mo2seg]
	push	fn10[bx]
	ret
farfn10 endp

tax	equ	(word ptr [bp])
tal	equ	(byte ptr [bp])
tah	equ	(byte ptr [bp+1])
tbx	equ	(word ptr [bp+2])
tbl	equ	(byte ptr [bp+2])
tbh	equ	(byte ptr [bp+3])
tcx	equ	(word ptr [bp+4])
tcl	equ	(byte ptr [bp+4])
tch	equ	(byte ptr [bp+5])
tdx	equ	(word ptr [bp+6])
tdl	equ	(byte ptr [bp+6])
tdh	equ	(byte ptr [bp+7])
tsi	equ	(word ptr [bp+8])
tbp	equ	(word ptr [bp+10])
tes	equ	(word ptr [bp+12])
tdi	equ	(word ptr [bp+18])

;====================== mosint10 entry point ====================

mosint10 proc far
	sti
	cld
	push	ds			; not used, not copied
	push	di			; ditto
	push	es
	mgetscb ds
	assume	ds:grp
	mov	es,[scbtcbpc]
	assume	es:tcb

; if function 03h, get cursor don't go through the overhead of int 10
; handler

	cmp	ah,03h			; is this get cursor?
	jne	notint03
	push	bx
	mov	bx,bios
	mov	es,bx
	assume	es:bios
	mov	bl,bh
	xor	bh,bh
	shl	bx,1
	mov	dx,[biocpos+bx]
	mov	es,[scbtcbpc]
	assume	es:tcb
	mov	[tcbcpos+bx],dx
	mov	cx,[tcbctyp]
	pop	bx
	jmp	short m10a
notint03:

; if i10f0f (get mode), don't go through stack switch -- causes stack 
; corruption in certain cases.  
; g.e. office writer calls i10f0f during its int 1c handler.  
; when the irq0 occurs during the time in tsl when when scbtcbpc and 
; ss don't match, if mosint10 switches stacks, the scbtcbpc stack 
; ends up getting corrupted.
 
	cmp	ah,0fh			; is this get mode?
	jne	notint0f
	mov	di,bios
	mov	ds,di
	assume	ds:bios
	mov	al,[biomode]
	mov	bh,[tcbpage]
	mov	ah,[tcbcols]
m10a:
	pop	es
	assume	es:nothing
	pop	di
	pop	ds
	assume	ds:nothing
	iret
notint0f:
	assume	ds:grp,es:tcb
	push	bp
	mov	di,ss

; the following is added for re-entrency control if a video bios
; desides to call itself during int 10. in this case we will
; simply pass it on to the original int 10 bios.

	cmp	[tcbin10],0		; inside mosint10 currently
	je	notinside
	pop	bp
	pop	es
	assume	es:nothing
	pop	di
	pushf
	call	[i10old]
	pop	ds
	assume	ds:nothing
	iret
notinside:
	assume	ds:grp,es:tcb
	mov	[tcbin10],1		; indicate inside mosint10
	push	word ptr [tcbstkp]	; save current mos stack pointer
	mov	bp,sp
	cmp	di,[scbtcbpc]
	je	smstk
	cli
	sub	word ptr [tcbstkp],64	; bias the stack for re-entcy control
	mov	ss,[scbtcbpc]		; new stack
	assume	es:nothing,ss:tcb
	mov	sp,[tcbstkp]
	sti
smstk:
	mov	es,di
	push	es:[bp+6]		; old di  save original di value
	push	es			; old ss
	push	bp			; old sp
	push	es:[bp+4]		; old es
	push	es:[bp+2]		; old bp
	push	si
	push	dx
	push	cx
	push	bx
	push	ax
	mov	bp,sp
	mov	ds,[scbtcbpc]		; end of new stack switch
	assume	ds:tcb,ss:nothing
	cmp	[tcbkbcnt],0
	je	kbcntnz
	dec	[tcbkbcnt]		; cut them a wee bit of slack as far as dis
kbcntnz:				; (vf02 revokes the slack)

; the following is use to set tcbcpos to value in bios because
; some bios's (IE bios on the the UniSys machine) will set the
; cursor position directly in bios data area

	mov	bx, bios
	mov	es, bx
	assume	es:bios
	push	dx
	mov	bl, [tcbpage]		; get page for index
	xor	bh, bh
	shl	bx, 1
	mov	dx,[biocpos+bx]
	mov	[tcbcpos+bx],dx
	pop	dx
	mov	bl,[tah]
	cmp	bl,lenfn10
	jb	mosi101
	cmp	bl,0feh
	jb	mosi10nf
	inc	[tcbkbcnt]		; remove slack from keyboard disable logic
	jmp	mosi10ex
mosi10nf:
	mov	bl,lenfn10
mosi101:

if bias
	push	[tcbstkp]
	sub	word ptr [tcbstkp],bias
endif

	xor	bh,bh
	shl	bx,1
	push	cs
	call	near ptr farfn10

if	bias
	pop	[tcbstkp]
endif

mosi10ex:
	pop	ax			; start of new stack switch
	pop	bx
	pop	cx
	pop	dx
	pop	si
	mov	di,sp
	mov	bp, word ptr ss:[di+4]
	mov	es, word ptr ss:[di+6]
	pop	es:[bp+2]
	pop	es:[bp+4]
	pop	bp			; old sp
	cli
	pop	ss
	mov	sp,bp
	sti				; back to application's stack
	mgetscb ds			; please note that old di is being disregard
	assume	ds:grp
	mov	ds,[scbtcbpc]
	assume	ds:tcb
	pop	word ptr [tcbstkp]	; restore saved mos stack pointer
	mov	[tcbin10],0		; reset re-entrency flag
	pop	bp
	pop	es
	pop	di
	pop	ds			; end of new stack switch
	iret
mosint10 endp


	subttl vidram - set up far call to mo2:vidram
	page
;======================================================================
;,fs
; vidram - set up far call to mo2:vidram
;
; in:	
;
; out:	
;
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:nothing
vidram proc far
	push	cs
	mov	ax,offset mos:vidret
	push	ax
	push	[mo2seg]
	mov	ax,offset mo2:nvidram
	push	ax
	ret
vidram endp

vidret proc near
	ret
vidret endp

; set up far call to mo2:vram1a

public	vidram1a
vidram1a proc far
	push	cs
	mov	ax,offset mos:vidret
	push	ax
	push	[mo2seg]
	mov	ax,offset mo2:vdrm040
	push	ax
	ret
vidram1a endp

	subttl nosbuf - test for screen buffer
	page
;======================================================================
;,fs
; nosbuf - test for screen buffer
;
; return z if there's no screen buffer (or vidram 'cause physical display
; memory's being used)
; saves ax, then jumps to farco in mo2 which calls cononly and returns
;   to the caller of nosbuf
;
; in:	
;
; out:	
;
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:nothing
nosbuf proc far
	push	ax
	push	[mo2seg]
	mov	ax,offset mo2:farco
	push	ax
	ret
nosbuf endp

	assume	ds:nothing, es:nothing, ss:nothing
	public	ddtcallf
ddtcallf proc near			; for far calls to ddtcall
	callmos2 ddtcall		; now do a far call to ddtcall
	ret				; return to caller in other segm
ddtcallf endp

mosseg	ends

;======================================================== ddt segment
if 0 eq 0
segment_num = 2
endif
ddt	segment
	assume	cs:mo2,ds:nothing,es:nothing,ss:nothing

	public	cursynch, farco, gvram

	extrn	swvidram:near,sbios2:word, wordmov:near
	extrn	allowhio:near,denyhio:near

; allowing mos access to cononly
; returns directly to original mos caller

farco proc far
	call	near ptr cononly
	pop	ax
	ret
farco endp

gvram proc near
	push	ds
	push	es
	mgetscb2 ds
	assume	ds:grp
	mov	es,[scbtcbpc]
	assume	es:tcb
	callmos1 swvidram
	pop	es
	pop	ds
	ret
gvram endp

; invalid functions are pointed here to be interpreted by
; the master console ddt (if connected to this partition) as well as it can

	assume	ds:tcb,es:bios,ss:nothing

vfnul proc far
	mov	al,[tcbpage]		; provide offset into buffer, cursor pos
	mov	ah,[tcbcols]
	call	crspos			;   and page in case driver needs it
	assume	es:nothing

; if task does not support ega or vga, we must skip calling
; these functions, because some apps (ie lotus 123 and wp 5.0)
; will get confused if forground (which does support ega or vga)
; is switch in.

	push	ax
	mov	al,[tcbstation]
	cmp	al,2
	jb	vftest			; mono or cga we must test function
	cmp	al,4
	jne	vfnok			; if not hercules (or mono,cga)
vftest: 				; then we can support high functions
	mov	ax,[tax]
	cmp	ah,10h			; functions below 10h ok
	jb	vfnok
	cmp	ah,1ch			; functions above 1ch ok
	ja	vfnok
	pop	ax
	jmp	vfnlx			; not ok....get out
vfnok:
	pop	ax

; for int10, function 10, if ega trapping is not being used, must
; save the int10 entry data so pamswitch can restore the ega palettes

vfnskip:
	cmp	[tah],10h
	je	$+5
	jmp	vfnd
	cmp	[tcbstate],0
	je	$+5
	jmp	vfnd
	push	ax
	push	bx
	push	cx
	cmp	[tal],0
	jne	vfna
	mov	cl,[tbl]		; use regsiter number as an
	mov	bl,cl			; index into the tcbegapal list
	xor	bh,bh
	mov	al,[tbh]
	mov	[tcbegapal+bx],al	; store the register value
	jmp	vfnc
vfna:
	cmp	[tal],1
	jne	vfnb
	mov	al,[tbh]		; of the overscan register
	mov	[tcbegapal+10h],al
	jmp	vfnc
vfnb:
	cmp	[tal],2
	jne	vfnc
	push	di
	push	ds
	push	es
	mov	ds,[tes]		; record a setting of all
	mov	si,[tdx]		; palette registers and the
	push	ss			; overscan register
	pop	es
	mov	di,offset [tcbegapal]
	mov	cx,8
	cld
	rep	movsw
	movsb
	pop	es
	pop	ds
	pop	di
vfnc:
	pop	cx
	pop	bx
	pop	ax

; check all watchers - if the master console is among
; them, pass the call onto ddtmc

vfnd:
	mov	si,[tcbscrdd]
vfnla:
	or	si,si
	jnz	vfnla1
	jmp	vfnlx
vfnla1:
	mov	ds,si
	mov	si,[tcbnxtdd]
	test	[tcbvram],80h
	jz	vfnla
	push	es
	push	bp
	push	di
	push	dx
	push	cx
	push	bx
	push	ax
	mov	si,offset [tcbcondd]
	mov	[si+4],di
	mov	[si+6],es
	mov	[si+8],bx
	mov	[si+10],ah
	mov	ax,[tax]
	push	ds
	mgetscb2 ds
	assume	ds:grp
	mov	ds,[scbtcbpc]
	assume	ds:tcb
	cmp	ah,11h			; check if function 11
	jne	notfun11

; support functions 1122 - 1124
; which allows the user to set number of line in dl

	cmp	al,22h			; only for 22h - 24h
	jb	not2224
	cmp	al,24h
	ja	not2224
	push	ax
	mov	al,[tdl]		; get  # of line to set
	jmp	short not50
not2224:
	cmp	al,12h			; setting 43line mode
	jne	notfun11
	push	ax
	mov	al,43			; 43 for ega
	mov	ah,[tcbstation]
	cmp	ah,2			; ega - set it to 43
	je	not50
	cmp	ah,5			; mono ega set it to 43
	je	not50
	mov	al,50			; 50 for vga or mono vga
not50:
	mov	[tcbrows],al		; let mos no its 43 or 50 line mode
	pop	ax
notfun11:
	pop	ds
	mov	bx,[tbx]
	mov	cx,[tcx]
	mov	dx,[tdx]
	mov	es,[tes]
	or	ah,80h
	push	di
	push	bp
	mov	di,[tdi]		; function 1bh (vga) needs di
	mov	bp,[tbp]
	call	ddtcall 		; see if ddt is busy and call
	mov	di,bp			; place bp in di for save
	pop	bp
	mov	[tbp],di		; return user bp function 11h
	pop	di
	mov	[tes],es
	mov	[tax],ax
	mov	[tbx],bx
	mov	[tcx],cx
	mov	[tdx],dx
	pop	ax
	pop	bx
	pop	cx
	pop	dx
	pop	di
	pop	bp
	pop	es
vfnlx:
	ret
vfnul endp

	subttl vf00 - set video mode
	page
;======================================================================
;,fs
; vf00 - set video mode
;
; note: bit 7 of al means that buffer is not cleared
;
; in:	val = video mode to set
;	  00 - 40x25 character bw
;	  01 - 40x25 character color
;	  02 - 80x25 character bw
;	  03 - 80x25 character color
;	  04 - 320x200 graphics color
;	  05 - 320x200 graphics bw
;	  06 - 640x200 graphics bw
;	  07 - 80x25 monochrome
;
; out:
;
;,fe
;======================================================================
	assume	ds:tcb,es:bios,ss:nothing
public	vf00
vf00 proc far
	mov	byte ptr [tcbrows],25
	and	byte ptr [tcbega], 0feh ; mask out ega bit
	mov	ah,[bioeqp]
	and	ah, 30h
	mov	al,[tal]
	and	al,07fh 		; mask out high bit for test
	cmp	ah,30h
	jne	vf00a
	cmp	[tcbstation],04h	; if on hercules force it to mode 7
	je	vf00hrc
	cmp	al,0fh			; is this mono chrome ega\vga
	je	vf00b
vf00hrc:
	mov	al,7

; validate mode according to size allocated for screen buffer

vf00a:
	cmp	[tcbstation],05 	; if monochrome ega\vga
	jae	vf00b			; then skip the following test
	cmp	[tcbscln],16384
	jae	vf00b			; ae if big enough for cga graphics modes
	cmp	al,7
	je	vf00b
	cmp	al,4
	jb	vf00b
	jmp	near ptr vf00x		; else those modes aren't allowed

; initialize the partition terminal vars according to the mode

vf00b:
	cmp	[tcbvidw2],0a000h	; ega modes
	jne	vf00b0
	mov	si,0b800h		; defaut it to b800h
	cmp	[tcbstation],05 	; is this mono ega\vga
	jb	vf00be
	mov	si,0b000h		; for monochrome ega\vga
vf00be:
	mov	[tcbvidw2],si

; the following is necessary because if no-clear bit is set
; than console will not be called to clear screen and screen
; lenght will not be reset to normal value

	mov	si,offset [tcbcondd]
	mov	[si].dcpscrl,80*25*2
vf00b0:
	mov	[tcbpal],30h
	mov	[biopal],30h
	cmp	al,6
	jne	vf00b1
	mov	[tcbpal],3fh
	mov	[biopal],3fh
vf00b1:
	mov	[biomode],al		; crt mode
	mov	[tcbmode],al
	mov	[biopage],0		; active page = 0
	mov	[tcbpage],0
	mov	[biocpos],0		; cursor position = 0,0 for pages 0-7
	mov	[tcbcpos],0
	mov	[biocpos+2],0
	mov	[tcbcpos+2],0
	mov	[biocpos+4],0
	mov	[tcbcpos+4],0
	mov	[biocpos+6],0
	mov	[tcbcpos+6],0
	mov	[biocpos+8],0
	mov	[tcbcpos+8],0
	mov	[biocpos+10],0
	mov	[tcbcpos+10],0
	mov	[biocpos+12],0
	mov	[tcbcpos+12],0
	mov	[biocpos+14],0
	mov	[tcbcpos+14],0
	mov	[biopgst],0
	mov	[tcbpgst],0
	mov	[biopgln],2048		; each page 2k for modes 0 & 1
	mov	[tcbpgln],2048
	mov	[bioctyp],0607h 	; cursor type for modes 0-6
	mov	[tcbctyp],0607h
	mov	[biocols],40		; cols/line for modes 0 & 1
	mov	[tcbcols],40
	cmp	al,2
	jae	vf00b2c
	jmp	vf00c
vf00b2c:
	mov	[biocols],80		; cols/line for modes 2 & 3
	mov	[tcbcols],80
	mov	[biopgln],4096		; each page 4k for modes 2 & 3
	mov	[tcbpgln],4096
	cmp	al,4
	jae	vf00b4c
	jmp	vf00c
vf00b4c:
	mov	[tcbpgln],16384 	; else full video buffer for anyone who cares
	mov	[biopgln],16384
	mov	[biocols],40		; cols/line for modes 4 & 5
	mov	[tcbcols],40
	cmp	al,6
	jae	notmode6
	jmp	vf00c
notmode6:
	mov	[biocols],80		; cols/line for modes 6 & 7
	mov	[tcbcols],80
	mov	[tcbpgln],16384
	mov	[biopgln],16384
	cmp	al, 7
	jb	vf00c
	je	vf00mo
	or	[tcbega], 1
	cmp	al,0dh			; modes 0dh and 13h are 80 x 25
	je	do0d13
	cmp	al,13h
	jne	vf00n13
do0d13:
	shr	[tcbpgln],1
	shr	[biopgln],1
	mov	[biocols],40
	mov	[tcbcols],40
	jmp	short vf00c
vf00n13:
	shl	[biopgln], 1		; 32k bios (works with some egas allways)
	push	ax
	mov	ax, [tcbvmpgs]
	add	ax, [tcbvmpgs+2]
	cmp	ax, 8
	pop	ax
	jb	vfck1112
	shl	[tcbpgln], 1		; 32k tcb if we got enough vidram
vfck1112:
	cmp	al,11h			; move 11h and 12h are 30 rows
	je	do1112
	cmp	al,12h
	jne	not1112
do1112:
	mov	[tcbrows],30h
not1112:
	jmp	short vf00c
vf00mo:
	and	[tcbega], 0feh
	mov	[tcbpgln],4096
	mov	[biopgln],4096
vf00bc:
	mov	[bioctyp],0b0ch 	; cursor type for mode 7
	mov	[tcbctyp],0b0ch

; call each terminal device driver to set the mode

vf00c:
	cmp	al, 7
	jbe	vf00c0
	mov	[tcbvidw2],0a000h
	test	byte ptr [tal], 80h	; check to see if high bit set
	jnz	vf00c0			; yes skip clearing ega ram
	call	gvram
	push	cx
	push	di
	push	es
	mov	cx, 4000h
	xor	ax, ax
	xor	di, di
	mov	es, [tcbvidw2]
	rep	stosw
	pop	es
	pop	di
	pop	cx

; set the ega pallettes to mode based on the following:

;	mode   00-01-02-03-04-05-06-07-08-09-0a-0b-0c-0d-0e-0f	 over
;    ------------------------------------------------------------------
;	 00    00 01 02 03 04 05 06 07 38 39 3a 3b 3c 3d 3e 3f	  00
;	 01    00 01 02 03 04 05 06 07 38 39 3a 3b 3c 3d 3e 3f	  00
;	 02    00 01 02 03 04 05 06 07 38 39 3a 3b 3c 3d 3e 3f	  00
;	 03    00 01 02 03 04 05 06 07 38 39 3a 3b 3c 3d 3e 3f	  00
;	 00*   00 01 02 03 04 05 14 07 38 39 3a 3b 3c 3d 3e 3f	  00
;	 01*   00 01 02 03 04 05 14 07 38 39 3a 3b 3c 3d 3e 3f	  00
;	 02*   00 01 02 03 04 05 14 07 38 39 3a 3b 3c 3d 3e 3f	  00
;	 03*   00 01 02 03 04 05 14 07 38 39 3a 3b 3c 3d 3e 3f	  00
;	 04    00 13 15 17 02 04 06 07 38 39 3a 3b 3c 3d 3e 3f	  00
;	 05    00 13 15 17 02 04 06 07 38 39 3a 3b 3c 3d 3e 3f	  00
;	 06    00 17 17 17 17 17 17 17 17 17 17 17 17 17 17 18	  00
;	 07    00 01 02 03 04 05 06 07 38 39 3a 3b 3c 3d 3e 3f	  00
;
; * means enhanced monitor

vf00c0:
	push	di
	push	ds
	push	es
	push	ds
	pop	es
	assume	ds:nothing,es:tcb
	mov	di,offset [tcbegapal]
	mov	cx,16			; set defaults for pallette 00 - 0f
	xor	ax,ax
vf00p1:
	cmp	al,8			; pallette 08 -> 10
	jne	vf00p2
	mov	al,38h			; change to 38h for compatibility
vf00p2:
	stosb
	inc	ax
	loop	vf00p1
	xor	ax,ax
	stosb				; save overscan allway zero for mode 0-7
	cmp	[tcbmode],7		; for mode 7, leave the default values
	je	vf00p6
	cmp	[tcbmode],06h		; do mode 06 special handling
	jne	vf00p3
	mov	cx,14/2
	lea	di,[tcbegapal+1]
	mov	ax,1717h		; pallettes 01 - 0e are 17h for mode 6
	rep	stosw
	inc	ax
	stosb				; pallette 0e is 18h for mode 6
	jmp	short vf00p4
vf00p3:
	cmp	[tcbmode],4		; handle special case for modes 4 & 5
	jb	vf00p4
	lea	di,[tcbegapal+1]
	mov	al,13h
	stosb				; pallette 01 --> 13h
	inc	ax
	inc	ax
	stosb				; pallette 02 --> 15h
	inc	ax
	inc	ax
	stosb				; pallette 03 --> 17h
	mov	al,02h
	stosb				; pallette 04 --> 02h
	inc	ax
	inc	ax
	stosb				; pallette 05 --> 04h

; if system has an enhanced monitor, pallette 06 = 14h
; for modes 00 - 03h, i.e modes 0* - 3*

vf00p4:
	cmp	[tcbmode],3		; only modes 00 - 03h
	ja	vf00p6
	mgetzero2 ds
	mov	al,byte ptr ds:[488h]	; check equiptment bytes
	and	al,0fh			; see page 123 of ibm ega
	cmp	al,03h
	je	vf00p5
	cmp	al,09h
	jne	vf00p6
vf00p5:
	mov	byte ptr [tcbegapal+6],14h
vf00p6:
	pop	es
	pop	ds
	assume	ds:tcb,es:bios
	pop	di

; finished with ega pallettes

	and	[tcb03b8],not 82h	; back to text mode
	mov	ah,[tcbcols]		; cols/row
	mov	al,[tcbmode]		; mode to set
	mgetscb2 es
	assume	es:grp
	mov	es,[scbmastv]		; screen buffer
	assume	es:nothing
	mov	si,[tcbscrdd]		; first terminal looking at this screen
	push	ds
vf00d:
	or	si,si
	jz	vf00e
	mov	ds,si
	push	es
	push	ax
	xor	cx,cx
	mov	si,offset [tcbcondd]
	mov	[si+4],cx
	mov	[si+6],es
	mov	[si+8],cx		; cursor offset within page
	mov	[si+10],ah		; cols/row
	mov	[tcbcmode],al		; remember it's the current mode for terminal

; when an int10 call is made where bit 7 of the entry al register == 1,
; we must convert this into a setting of bit 5 for ddtmc's setmode function.
; this is required to prevent conflicts with the use of bit 7 to establish
; hercules graphics mode.  note that bit 6 is used to indicate the
; herc page number.
;
; Updated 06/28/91 SAH Corrections for Display Automination,  make sure
; that high bit is past on to terminal driver setmode function (AH=3)

	test	byte ptr [tal],80h
	jz	vf00d1
	mov	ah,80h
	cmp	[si].dcpherc,'Y' 	
	jne	vf00d1a			
	mov	ah,00100000b
vf00d1a:
	or	al,ah
vf00d1:
	mov	ah,03h
	call	ddtcall 		; see if ddt is busy and call
	pop	ax
	pop	es
	mov	si,[tcbnxtdd]
	jmp	near ptr vf00d
vf00e:
	pop	ds
	test	byte ptr [tal], 80h	; test for no-clear buffer case
	jnz	vf00x

; clear screen buffer and vidram buffer to spaces in text modes,
;   nulls in graphics modes

	mov	bl,al
	mov	ax,0720h
	cmp	bl,4
	jb	vf00f
	cmp	bl,7
	je	vf00f
	xor	ax,ax
vf00f:
	mov	cx,[tcbscln]		; length to be cleared
	shr	cx,1			; words to be cleared
	mov	bx,cx

; update screen buffer if master console isn't the only one

	call	cononly
	jz	vf00x			; z if master console is only terminal
	mgetscb2 es
	assume	es:grp
	mov	es,[scbmastv]
	assume	es:nothing
	xor	di,di
	rep	stosw

; update vidram buffer if vidram is active

vf00g:
	test	[tcbvram],01h
	jz	vf00x
	mov	cx,ax
	call	gvram			; expose vidram if needed
	mov	ax,cx
	mov	cx,bx
	mov	es,[tcbvidw2]
	xor	di,di
	rep	stosw
vf00x:					; note use high bit set if change
					; below this line
	ret
vf00 endp

	subttl vf01 - set cursor type
	page
;======================================================================
;,fs
; vf01 - set cursor type
;
; in:	vch bits 4-0 = start scan line for cursor
;	vcl bits 4-0 = end scan line for cursor
;
; out:
;
;,fe
;======================================================================
	assume	ds:tcb,es:bios,ss:nothing
vf01 proc far
	mov	cx,[tcx]
	mov	[bioctyp],cx
	mov	[tcbctyp],cx
	mov	cx,[tcx]
	mov	ah,01h
	call	graphics
	jz	vf01x
	mov	al,[tcbpage]		; provide offset into buffer, cursor pos
	mov	ah,[tcbcols]
	call	crspos			;   and page in case driver needs it
	assume	es:nothing
	mov	cx,[tcx]
	mov	al,[tcbmode]
	mov	si,[tcbscrdd]
vf01a:
	or	si,si
	jz	vf01x
	mov	ds,si
	push	es
	push	di
	push	dx
	push	cx
	push	bx
	push	ax
	mov	si,offset [tcbcondd]
	mov	[si+4],di
	mov	[si+6],es
	mov	[si+8],bx
	mov	[si+10],ah
	mov	ah,04h
	call	ddtifnot
	pop	ax
	pop	bx
	pop	cx
	pop	dx
	pop	di
	pop	es
	mov	si,[tcbnxtdd]
	jmp	near ptr vf01a
vf01x:
	ret
vf01 endp

	subttl vf02 - set cursor position
	page
;======================================================================
;,fs
; vf02 - set cursor position
;
; in:	vdh = row
;	vdl = column
;	vbh = page
;
; out:
;
;,fe
;======================================================================
	assume	ds:tcb,es:bios,ss:nothing
vf02 proc far
	mov	dx,[tdx]
vf02a:
	mov	al,[tbh]
	mov	bl,al
	xor	bh,bh
	shl	bx,1
mcsync:
	cmp	dx,[tcbcpos+bx] 	; don't bother if it's the same
	je	vf02dx
	mov	[biocpos+bx],dx
	mov	[tcbcpos+bx],dx
	cmp	al,[tcbpage]
	jne	vf02d			; or if not active page
	mov	dx,[tdx]
	mov	bh,[tbh]
	mov	ah,02h
	call	graphics
	jz	vf02d
	mov	ah,[tcbcols]
	call	crspos
	assume	es:nothing
	mov	si,[tcbscrdd]

; set master console position only

vf02b:
	or	si,si
	jz	vf02d
	mov	ds,si
	test	[tcbvram],80h
	jnz	vf02c
	mov	si,[tcbnxtdd]
	jmp	near ptr vf02b
vf02c:
	mov	si,offset [tcbcondd]
	mov	[si+4],di
	mov	[si+6],es
	mov	[si+8],bx
	mov	[si+10],ah
	mov	ah,05h
	call	ddtifnot
	jmp	vf02d
vf02dx:
	inc	[tcbkbcnt]		; since its the same cursor position
					; don't cut them any slack
vf02d:
	ret
vf02 endp

	subttl vf04 - read light pen position
	page
;======================================================================
;,fs
; vf04 - read light pen position
;
; in:	ignored
;
; out:	ah = 04h indicating that light pen is not supported.
;
;,fe
;======================================================================
	assume	ds:tcb,es:bios,ss:nothing
vf04 proc far
	mov	[tah],0 		; light pen not supported
	ret
vf04 endp

	subttl vf05 - set active page
	page
;======================================================================
;,fs
; vf05 - set active page
;
; in:	val = page
;
; out:
;
;,fe
;======================================================================
	assume	ds:tcb,es:bios,ss:nothing
vf05 proc far
	mov	al,[tal]
	cmp	al,[tcbpage]
	jmpe	vf05x

; verify page number according to current screen mode

	cmp	[tcbmode],3
	jmpa	vf05x			; modes 4, 5, 6, 7 don't support pages
	cmp	[tcbmode],2
	jb	vf05a			; 0 <= page < 7 correct if mode < 2
	cmp	al,3
	jmpa	vf05x			; else 0 <= page < 2 correct
vf05a:

; verify page number according to length allocated for screen buffer

	xor	ah,ah
	mov	si,[tcbpgln]		; length of one page
	mul	si
	add	ax,si			; ax past end of page
	cmp	ax,[tcbscln]
	jmpa	vf05x			; no good if past end of allocated screen
	sub	ax,si
	mov	di,ax			; offset into screen buffer of new page
	push	es
	push	di

; set new active page for each terminal
;   (just display new page on terminal screen

	xor	dx,dx
	mov	ah,[tcbcols]
	mov	cx,[tcbpgln]
	call	scrpos
	assume	es:nothing
	call	cononly
	jnz	vf05a1

; if master console only, get a copy of page 0
; (note it's not mc only unless page 0 active and we aren't here unless we're
; actually changing the active page

	push	es
	push	ds
	push	di
	push	cx
	push	bx
	push	ax
	mov	ds,[tcbscrdd]
	mov	si,offset [tcbcondd]
	mov	[si+4],di		; cursor offset is offset into page 0 also
	mov	[si+6],es
	mov	[si+8],bx
	mov	[si+10],ah
	mov	ah,0fh
	call	ddtcall 		; see if ddt busy and call
	pop	ax
	pop	bx
	pop	cx
	pop	di
	pop	ds
	pop	es

; and set copy in vidram also, if active

	test	[tcbvram],01h
	jz	vf05a1
	push	es
	push	ds
	push	di
	push	bx
	push	ax
	call	gvram
	mov	es,[tcbvidw2]
	mgetscb2 ds
	assume	ds:grp
	mov	ds,[scbmastv]
	mov	si,di
	shr	cx,1
	call	wordmov 		; fast move on 386\486
	pop	ax
	pop	bx
	pop	di
	pop	ds
	assume	ds:tcb
	pop	es
vf05a1:
	pop	di
	pop	es
	assume	es:bios
	mov	al,[tal]
	mov	[biopage],al		; validation is done
	mov	[tcbpage],al
	mov	[biopgst],di
	mov	[tcbpgst],di
	xor	dx,dx
	mov	ah,[tcbcols]
	mov	cx,[tcbpgln]
	call	scrpos
	assume	es:nothing

; copy vidram, if active, into screen buffer

	test	[tcbvram],01h
	jz	vf05a2
	push	es
	push	ds
	push	di
	push	cx
	push	ax
	call	gvram
	mov	ds,[tcbvidw2]
	mov	si,di
	shr	cx,1
	call	wordmov 		; fast move on 386\486
	pop	ax
	pop	cx
	pop	di
	pop	ds
	pop	es
vf05a2:
	mov	si,[tcbscrdd]
	or	si,si
	jz	vf05x			; done if no terminals
	shr	cx,1
	mov	ds,si
vf05b:
	mov	al,[tcbwinpo]
	cmp	[tcbnxtdd],0
	je	vf05c			; only one more if 0
	push	es
	push	di
	push	cx
	push	bx
	push	ax
	mov	si,offset [tcbcondd]
	mov	[si+4],di
	mov	[si+6],es
	mov	[si+8],bx
	mov	[si+10],ah
	mov	ah,0ch
	call	ddtcall 		; see if ddt busy and call
	pop	ax
	pop	bx
	pop	cx
	pop	di
	pop	es
	mov	ds,[tcbnxtdd]
	jmp	near ptr vf05b
vf05c:
	mov	si,offset [tcbcondd]
	mov	[si+4],di
	mov	[si+6],es
	mov	[si+8],bx
	mov	[si+10],ah
	mov	ah,0ch
	call	ddtcall 		; see if ddt busy and call
vf05x:
	ret
vf05 endp

	subttl vf06 - scroll active page up
	page
;======================================================================
;,fs
; vf06 - scroll active page up
;
; in:	val = number of lines to scroll (0 for clear screen)
;	vch, vcl = top left corner of region to scroll
;	vdh, vdl = bottom right corner of region to scroll
;	vbh = attribute to use on blanked line(s)
;
; out:
;
;,fe
;======================================================================
	assume	ds:tcb,es:bios,ss:nothing
vf06 proc far
	mov	al,[tcbpage]
	xor	dx,dx
	mov	ah,[tcbcols]
	push	es
	call	scrpos
	assume	es:nothing
	mov	al,[tal]
	mov	cx,[tcx]
	mov	dx,[tdx]
	call	fixbox
	call	cononly
	jnz	vf06a

; scroll master console only if it's the only terminal

	mov	ds,[tcbscrdd]
	mov	si,offset [tcbcondd]
	mov	[si+4],di
	mov	[si+6],es
	mov	[si+8],bx
	mov	[si+10],ah
	mov	bl,[tbh]
	push	dx
	push	cx
	mov	ah,06h
	call	ddtcall 		; see if ddt busy and call
	pop	cx
	pop	dx
	pop	es
	jmp	near ptr vf06x

; scroll each terminal looking at screen

vf06a:
	mov	si,[tcbscrdd]
	or	si,si
	jz	vf06d
	push	ds
	mov	ds,si
vf06b:
	cmp	[tcbnxtdd],0
	je	vf06c
	push	es
	push	di
	push	dx
	push	cx
	push	bx
	push	ax
	mov	si,offset [tcbcondd]
	mov	[si+4],di
	mov	[si+6],es
	mov	[si+8],bx
	mov	[si+10],ah
	mov	bl,[tbh]
	mov	ah,06h
	call	ddtifnot
	pop	ax
	pop	bx
	pop	cx
	pop	dx
	pop	di
	pop	es
	mov	ds,[tcbnxtdd]
	jmp	near ptr vf06b
vf06c:
	mov	si,offset [tcbcondd]
	mov	[si+4],di
	mov	[si+6],es
	mov	[si+8],bx
	mov	[si+10],ah
	mov	bl,[tbh]
	push	dx
	push	cx
	mov	ah,06h
	call	ddtifnot
	pop	cx
	pop	dx
	pop	ds

; scroll screen save area and vidram screen (if needed)

vf06d:
	pop	es
	assume	es:bios
	mov	ah,[tcbcols]
	mov	al,[tal]
	mov	bh,[tbh]
	mov	cx,[tcx]
	mov	dx,[tdx]
	call	fixbox
	mov	ah,06h
	call	graphics
	jz	vf06x
	mov	al,[tal]
	mov	bl,[tbh]
	mov	bh,[tcbpage]
	call	scruparg		; scroll up arguments to scrollit
	assume	es:nothing
	test	[tcbvram],01h
	jnz	vf06e			; nz if vidram active
	call	scrollit		; else scroll screen buffer only
	jmp	near ptr vf06x
vf06e:
	push	di			; scroll screen buffer and vidram both
	push	si
	push	dx
	call	scrollit		; screen buffer
	mov	dx,ax
	call	gvram
	mov	ax,dx
	pop	dx
	pop	si
	pop	di
	mov	es,[tcbvidw2]
	call	scrollit		; vidram buffer
vf06x:
	ret
vf06 endp

	subttl vf07 - scroll active page down
	page
;======================================================================
;,fs
; vf07 - scroll active page down
;
; in:	val = number of lines to scroll (0 for clear screen)
;	vch, vcl = top left corner of region to scroll
;	vdh, vdl = bottom right corner of region to scroll
;	vbh = attribute to use on blanked line(s)
;
; out:
;
;,fe
;======================================================================
	assume	ds:tcb,es:bios,ss:nothing
vf07 proc far
	mov	al,[tcbpage]
	mov	ah,[tcbcols]
	xor	dx,dx
	push	es
	call	scrpos
	assume	es:nothing
	mov	al,[tal]
	mov	cx,[tcx]
	mov	dx,[tdx]
	call	fixbox
	call	cononly
	jnz	vf07a

; scroll master console only if it's the only terminal

	mov	ds,[tcbscrdd]
	mov	si,offset [tcbcondd]
	mov	[si+4],di
	mov	[si+6],es
	mov	[si+8],bx
	mov	[si+10],ah
	mov	bl,[tbh]
	push	dx
	push	cx
	mov	ah,07h
	call	ddtcall 		; see if ddt busy and call
	pop	cx
	pop	dx
	pop	es
	jmp	near ptr vf07x

; scroll each terminal looking at screen

vf07a:
	mov	si,[tcbscrdd]
	or	si,si
	jz	vf07d
	push	ds
	mov	ds,si
vf07b:
	cmp	[tcbnxtdd],0
	je	vf07c
	push	es
	push	di
	push	dx
	push	cx
	push	bx
	push	ax
	mov	si,offset [tcbcondd]
	mov	[si+4],di
	mov	[si+6],es
	mov	[si+8],bx
	mov	[si+10],ah
	mov	bl,[tbh]
	mov	ah,07h
	call	ddtifnot
	pop	ax
	pop	bx
	pop	cx
	pop	dx
	pop	di
	pop	es
	mov	ds,[tcbnxtdd]
	jmp	near ptr vf07b
vf07c:
	mov	si,offset [tcbcondd]
	mov	[si+4],di
	mov	[si+6],es
	mov	[si+8],bx
	mov	[si+10],ah
	mov	bl,[tbh]
	push	dx
	push	cx
	mov	ah,07h
	call	ddtifnot
	pop	cx
	pop	dx
	pop	ds

; scroll screen save area and vidram screen (if needed)

vf07d:
	pop	es
	assume	es:bios
	mov	ah,[tcbcols]
	mov	al,[tal]
	mov	bh,[tbh]
	mov	cx,[tcx]
	mov	dx,[tdx]
	call	fixbox
	mov	ah,07h
	call	graphics
	jz	vf07x
	mov	al,[tal]
	mov	bl,[tbh]
	mov	bh,[tcbpage]
	call	scrdnarg
	assume	es:nothing
	test	[tcbvram],01h
	jnz	vf07e			; nz if vidram is active
	call	scrollit		; else scroll screen buffer only
	jmp	near ptr vf07x
vf07e:
	push	di			; scroll screen buffer and vidram
	push	si
	push	dx
	call	scrollit		; screen buffer
	mov	dx,ax
	call	gvram
	mov	ax,dx
	pop	dx
	pop	si
	pop	di
	mov	es,[tcbvidw2]
	call	scrollit		; vidram buffer
vf07x:
	ret
vf07 endp

	subttl vf08 - read char/attribute at cursor
	page
;======================================================================
;,fs
; vf08 - read char/attribute at cursor
;
; in:	vbh = page
;
; out:	val = character read
;	vah = attribute read
;
;,fe
;======================================================================
	assume	ds:tcb,es:bios,ss:nothing
vf08 proc far
	mov	bh,[tbh]
	mov	ah,08h
	call	graphics
	jz	vf08c
	mov	al,[tbh]		; page to read
	mov	ah,[tcbcols]
	call	crspos			; offset into screen buffer
	assume	es:nothing
	call	cononly
	jz	vf08b
	test	[tcbvram],01h
	jz	vf08a			; z if vidram not active
	call	gvram
	mov	es,[tcbvidw2]		; else its the best version of the screen
	mov	ax,es:[di]
	jmp	near ptr vf08c
vf08a:
	mgetscb2 es
	assume	es:grp
	mov	es,[scbmastv]
	assume	es:nothing
	mov	ax,es:[di]
	jmp	near ptr vf08c
vf08b:
	mov	ds,[tcbscrdd]
	mov	si,offset [tcbcondd]
	mov	[si+4],di
	mov	[si+6],es
	mov	[si+8],bx
	mov	[si+10],ah
	mov	ah,0eh			; get char/atr from mc driver
	call	ddtcall 		; see if ddt busy and call
vf08c:
	mov	[tax],ax
	ret
vf08 endp

	subttl vf09 - write char/attribute at cursor
	page
;======================================================================
;,fs
; vf09 - write char/attribute at cursor
;
; in:	val = char to write
;	vbh = page
;	vbl = attribute to write
;	vcx = number to write
;
; out:
;
;,fe
;======================================================================
	assume	ds:tcb,es:bios,ss:nothing
vf09 proc far
	mov	al,[tbh]
	mov	ah,[tcbcols]
	call	crspos			; current page, row and col position
	assume	es:nothing
	mov	cx,[tcx]
	or	cx,cx
	jnz	vf09a
	jmp	near ptr vf09x		; no characters to write
vf09a:
	cmp	al,[tcbpage]
	je	vf09a1
	jmp	vf09j1
vf09a1:
	mov	al,[tal]
	call	cononly
	jnz	vf09c			; nz if not master console only

; char & attribute to master console only

	mov	ds,[tcbscrdd]
	push	di
	mov	si,offset [tcbcondd]
	mov	[si+4],di
	mov	[si+6],es
	mov	[si+8],bx
	mov	[si+10],ah
	mov	bl,[tbl]
	mov	ah,08h
	call	ddtcall 		; see if ddt busy and call	; rg8188
	pop	di
	jmp	near ptr vf09x

; check for special case where only 1 char/attr being sent and it is
;   the same as what's already in the screen buffer

vf09c:
	cmp	[tcbmode],4
	jb	vf09c1
	cmp	[tcbmode],7
	je	vf09d
vf09c1:
	mov	ch,ah
	mov	ah,[tbl]
	scasw
	lea	di,[di-2]
	mov	ah,ch
	jne	vf09d			; ne so go look at end of string
	dec	cl
	jnz	vf09d
	jmp	vf09k			; finished w/ terminals and save area
vf09d:
	push	di

; send char(s) & attribute(s) to each terminal

vf09e:
	mov	si,[tcbscrdd]
	or	si,si
	jz	vf09j
	push	ds
	mov	ds,si
vf09h:
	assume	ds:tcb,ss:nothing
	mov	cx,[tcx]
	cmp	[tcbnxtdd],0
	je	vf09i
	push	es
	push	di
	push	dx
	push	bx
	push	ax
	mov	si,offset [tcbcondd]
	mov	[si+4],di
	mov	[si+6],es
	mov	[si+8],bx
	mov	[si+10],ah
	mov	bl,[tbl]
	mov	ah,08h
	call	ddtifnot
	pop	ax
	pop	bx
	pop	dx
	pop	di
	pop	es
	mov	ds,[tcbnxtdd]
	jmp	near ptr vf09h
vf09i:
	mov	si,offset [tcbcondd]
	mov	[si+4],di
	mov	[si+6],es
	mov	[si+8],bx
	mov	[si+10],ah
	mov	bl,[tbl]
	mov	ah,08h
	call	ddtifnot
	pop	ds

; update screen buffer

vf09j:
	pop	di
vf09j1:
	mov	al,[tal]
	mov	bx,[tbx]
	mov	cx,[tcx]
	mov	ah,09h
	call	graphics
	jz	vf09x
	mov	si,di
	mov	cx,[tcx]
	mov	al,[tal]
	mov	ah,[tbl]
	mgetscb2 es
	assume	es:grp
	mov	es,[scbmastv]
	assume	es:nothing
	rep	stosw
	mov	di,si

; update vidram buffer if active

vf09k:
	test	[tcbvram],01h
	jz	vf09x
	call	gvram
	mov	cx,[tcx]
	mov	al,[tal]
	mov	ah,[tbl]
	mov	es,[tcbvidw2]
	rep	stosw
vf09x:
	ret
vf09 endp

	subttl vf0a - write char only at cursor
	page
;======================================================================
;,fs
; vf0a - write char only at cursor
;
; in:	val = char to write
;	vbh = page
;	vcx = number to write
;
; out:
;
;,fe
;======================================================================
	assume	ds:tcb,es:bios,ss:nothing
vf0a proc far
	mov	al,[tbh]
	mov	ah,[tcbcols]
	call	crspos			; current page, row & col position
	assume	es:nothing
	mov	cx,[tcx]
	or	cx,cx
	jnz	vf0aa
	jmp	near ptr vf0ax
vf0aa:
	cmp	al,[tcbpage]
	je	vf0ab
	jmp	vf0aj1
vf0ab:
	mov	al,[tal]
	call	cononly
	jnz	vf0ac			; nz if not master console only

; char to master console only

	mov	ds,[tcbscrdd]
	push	di
	mov	si,offset [tcbcondd]
	mov	[si+4],di
	mov	[si+6],es
	mov	[si+8],bx
	mov	[si+10],ah
	mov	ah,0dh
	call	ddtifnot
	pop	di
	jmp	near ptr vf0ax

; check for special case where only 1 char is being sent and it's the
;   same as what's already in the screen buffer

vf0ac:
	cmp	[tcbmode],4
	jb	vf0ac1
	cmp	[tcbmode],7
	je	vf0ad
vf0ac1:
	scasb
	lea	di,[di-1]
	jne	vf0ad
	dec	cx
	jz	vf0ak			; finished w/ terminals and save area
vf0ad:
	push	di

; send char(s) to each terminal

vf0ae:
	mov	si,[tcbscrdd]
	or	si,si
	jz	vf0aj
	push	ds
	mov	ds,si
vf0ah:
	mov	cx,[tcx]
	cmp	[tcbnxtdd],0
	je	vf0ai
	push	es
	push	di
	push	dx
	push	bx
	push	ax
	mov	si,offset [tcbcondd]
	mov	[si+4],di
	mov	[si+6],es
	mov	[si+8],bx
	mov	[si+10],ah
	mov	ah,0dh
	call	ddtifnot
	pop	ax
	pop	bx
	pop	dx
	pop	di
	pop	es
	mov	ds,[tcbnxtdd]
	jmp	near ptr vf0ah
vf0ai:
	mov	si,offset [tcbcondd]
	mov	[si+4],di
	mov	[si+6],es
	mov	[si+8],bx
	mov	[si+10],ah
	mov	ah,0dh
	call	ddtifnot
	pop	ds

; update screen buffer

vf0aj:
	pop	di
vf0aj1:
	mov	al,[tal]
	mov	bh,[tbh]
	mov	cx,[tcx]
	mov	ah,0ah
	call	graphics
	jz	vf0ax
	mov	al,[tal]
	mov	cx,[tcx]
	mgetscb2 es
	assume	es:grp
	mov	es,[scbmastv]
	assume	es:nothing
	mov	si,di
vf0aj2:
	stosb
	inc	di
	loop	vf0aj2
	mov	di,si

; update vidram buffer if active

vf0ak:
	test	[tcbvram],01h
	jz	vf0ax
	call	gvram
	mov	cx,[tcx]		; update vidram if active
	mov	es,[tcbvidw2]
	mov	al,[tal]
vf0ak1:
	stosb
	inc	di
	loop	vf0ak1
vf0ax:
	ret
vf0a endp

	subttl vf0b - set color palette
	page
;======================================================================
;,fs
; vf0b - set color palette
;
; in:	vbh = 0 set background color
;	  vbl = background color
;	vbh = 1 set graphics color palette
;	  vbl = palette
;
; out:
;
;,fe
;======================================================================
	assume	ds:tcb,es:bios,ss:nothing
vf0b proc far
	mov	bx,[tbx]
	mov	si,[tcbscrdd]
	mov	ah,[tcbcols]
	mov	al,[tcbpal]		; record the new value in the tcb
	or	bh,bh
	jz	vf0ba
	and	al,0dfh
	shr	bl,1
	jnc	vf0bb
	or	al,20h
	jmp	vf0bb
vf0ba:
	and	al,0e0h
	and	bl,1fh
	or	al,bl
vf0bb:
	mov	[biopal],al
	mov	[tcbpal],al
	mov	bl,al
	mov	dx,ds
	mgetscb2 es
	assume	es:grp
	mov	es,[scbmastv]
	assume	es:nothing
vf0bc:
	or	si,si
	jz	vf0bx
	mov	ds,si
	push	bx
	push	ax
	xor	cx,cx
	mov	si,offset [tcbcondd]
	mov	[si+4],cx
	mov	[si+6],es
	mov	[si+8],cx
	mov	[si+10],ah
	mov	ah,09h
	call	ddtcall 		; see if ddt busy and call
	pop	ax
	pop	bx
	mov	si,[tcbnxtdd]
	jmp	near ptr vf0bc
vf0bx:
	ret
vf0b endp

	subttl vf0c - write dot
	page
;======================================================================
;,fs
; vf0c - write dot
;
; in:	vdx = row number
;	vcx = column number
;	val = color value (> 128, color value xor'ed)
;
; out:
;
;,fe
;======================================================================
	assume	ds:tcb,es:bios,ss:nothing
vf0c proc far
	mov	dx,[tdx]
	mov	cx,[tcx]
	mov	al,[tal]
	call	graphics
	jz	vf0cx
	call	cononly
	jnz	vf0cx
	mov	dx,[tdx]
	mov	cx,[tcx]
	mov	al,[tal]
	mov	ds,[tcbscrdd]
	mov	si,offset [tcbcondd]
	mov	ah,8ch
	call	ddtcall 		; see if ddt busy and call
vf0cx:
	ret
vf0c endp

	subttl vf0d - read dot
	page
;======================================================================
;,fs
; vf0d - read dot
;
; in:	vdx = row number
;	vcx = column number
;
; out:	val = color value of dot
;
;,fe
;======================================================================
	assume	ds:tcb,es:bios,ss:nothing
vf0d proc far
	mov	dx,[tdx]
	mov	cx,[tcx]
	call	graphics
	jz	vf0dx
	call	cononly
	jnz	vf0dy
	mov	dx,[tdx]
	mov	cx,[tcx]
	mov	ds,[tcbscrdd]
	mov	si,offset [tcbcondd]
	mov	ah,8dh
	call	ddtcall 		; see if ddt busy and call
vf0dx:
	mov	[tal],al
vf0dy:
	ret
vf0d endp

	subttl vf0e - write tty
	page
;======================================================================
;,fs
; vf0e - write tty
;
; in:	val = char to write
;	vbl = foreground color in graphics modes
;
; out:
;
;,fe
;======================================================================
	assume	ds:tcb,es:bios,ss:nothing
vf0e proc far
	mov	[tcbkbcnt],0		; counteract dis mode
	mov	al,[tcbpage]
	mov	ah,[tcbcols]
	call	crspos			; offset for page, row and col
	assume	es:nothing
	mov	al,[tal]		; char to write
	call	cononly
	jnz	vf0ea

; send to master console only, if it's the only terminal

	push	ds
	mov	ds,[tcbscrdd]
	push	di
	push	dx
	mov	si,offset [tcbcondd]
	mov	[si+4],di
	mov	[si+6],es
	mov	[si+8],bx
	mov	[si+10],ah
	mov	bl,[tbl]		;(mc only knows about this)
	mov	ah,0ah
	call	ddtcall 		; see if ddt busy and call
	pop	dx
	pop	di
	pop	ds
	mov	al,[tal]
	cmp	al,0dh
	jmpa	vf0ef
	jmpe	vf0eh
	cmp	al,0ah
	jmpe	vf0eg			; take care of line feed
	cmp	al,08h
	jmpe	vf0ei			; take care of back space
	cmp	al,07h
	jmpe	vf0ey			; finished if bell
	jmp	near ptr vf0ef		; not a control char (no update of screen buf)

; send char to each terminal

vf0ea:
	mov	si,[tcbscrdd]
	or	si,si
	jz	vf0ed
	push	ds
	mov	ds,si
vf0eb:
	cmp	[tcbnxtdd],0
	je	vf0ec
	push	es
	push	di
	push	dx
	push	bx
	push	ax
	mov	si,offset [tcbcondd]
	mov	[si+4],di
	mov	[si+6],es
	mov	[si+8],bx
	mov	[si+10],ah
	mov	ah,0ah
	call	ddtifnot
	pop	ax
	pop	bx
	pop	dx
	pop	di
	pop	es
	mov	ds,[tcbnxtdd]
	jmp	near ptr vf0eb
vf0ec:
	push	di
	push	dx
	mov	si,offset [tcbcondd]
	mov	[si+4],di
	mov	[si+6],es
	mov	[si+8],bx
	mov	[si+10],ah
	mov	ah,0ah
	call	ddtifnot
	pop	dx
	pop	di
	pop	ds
	test	[tcbvram],01h
	jz	vf0ed
	call	gvram

; if it isn't a control char, then update screen buffer

vf0ed:
	mov	al,[tal]
	mov	bl,[tbl]
	mov	ah,0eh
	call	graphics
	jnz	vf0ed1
	mov	ax,bios
	mov	es,ax
	assume	es:bios
	mov	bl,[tcbpage]
	xor	bh,bh
	shl	bx,1
	mov	dx,[tcbcpos+bx]
	jmp	vf0ej
vf0ed1:
	mov	al,[tal]
	cmp	al,0dh
	ja	vf0ed2
	jmpe	vf0eh
	cmp	al,0ah
	jmpe	vf0eg
	cmp	al,08h
	jmpe	vf0ei
	cmp	al,07h
	jmpe	vf0ey
vf0ed2:
	mgetscb2 es
	assume	es:grp
	mov	es,[scbmastv]
	assume	es:nothing
	mov	es:[di],al

; update vidram buffer if active and not a control char

	test	[tcbvram],01h
	jz	vf0ef
	mov	es,[tcbvidw2]
	mov	es:[di],al

; increment cursor position if not a control char

vf0ef:
	inc	dl
	cmp	dl,[tcbcols]
	jmpb	vf0ej
	xor	dl,dl

; increment row if line feed or char at end of a line

vf0eg:
	inc	dh
	cmp	dh,[tcbrows]
	jmpb	vf0ej

; scroll if incremented row at last row

	dec	dh			; back to row 24
	call	cononly
	jmpz	vf0ej

; scroll screen buffer if not master console only

vf0eg1:
	push	dx
	mov	al,[tcbpage]
	mov	ah,[tcbcols]
	call	scrpos			; return di = offset of row 24, col 0
	assume	es:nothing
	mov	cl,ah
	mov	ah,es:[di+1]		; attribute of that char
	mov	al,' '
	push	di
	xor	ch,ch
	mov	bx,cx
	mov	si,cx
	shl	si,1
	push	ds
	mov	cx,[tcbpgln]
	sub	cx,si
	shr	cx,1
	mov	di,ax
	mov	ax,[tcbpgst]
	xchg	di,ax
	add	si,di
	mov	dx,es
	mov	ds,dx
	mov	dx,di
	call	wordmov 		; fast move on 386\486
	pop	ds
	assume	ds:tcb
	mov	cx,bx
	rep	stosw
	pop	di
	test	[tcbvram],01h
	jz	vf0eg2			; nz if vidram active

; scroll vidram buffer if vidram active

	mov	cx,ax
	call	gvram
	mov	ax,cx
	mov	es,[tcbvidw2]
	mov	ah,es:[di+1]
	mov	cx,bx
	mov	di,dx
	mov	si,cx
	shl	si,1
	add	si,di
	push	ds
	mov	cx,[tcbpgln]
	sub	cx,si
	shr	cx,1
	mov	dx,es
	mov	ds,dx
	call	wordmov 		; fast move on 386\486
	pop	ds
	assume	ds:tcb
	mov	cx,bx
	rep	stosw
vf0eg2:
	pop	dx
	jmp	near ptr vf0ej

; on carriage return, set col 0

vf0eh:					; carriage return
	xor	dl,dl
	jmp	near ptr vf0ej

; on back space, dec col if not first col

vf0ei:
	or	dl,dl
	jz	vf0ej
	dec	dl

; store new cursor position

vf0ej:
	mov	ax,bios
	mov	es,ax
	assume	es:bios
	mov	al,[tcbpage]
	mov	bl,al
	xor	bh,bh
	shl	bx,1
	cmp	[tah],13h
	je	vf0ex			; if not function 13h (write string), then
	jmp	mcsync			; synchronize master console cursor
vf0ex:
	mov	ax,bios
	mov	es,ax
	assume	es:bios
	mov	[biocpos+bx],dx 	; else just store new position
	mov	[tcbcpos+bx],dx
vf0ey:
	ret
vf0e endp

	subttl vf0f - read video state
	page
;======================================================================
;,fs
; vf0f - read video state
;
; in:
;
; out:	val = current mode
;	vah = columns per line
;	vbh = current page
;
;,fe
;======================================================================
	assume	ds:tcb,es:bios,ss:nothing
vf0f proc far
	mov	al,[biomode]
	mov	bh,[tcbpage]
	mov	ah,[tcbcols]
	mov	[tax],ax
	mov	[tbh],bh
	ret
vf0f endp

	subttl vf13 - write string
	page
;======================================================================
;,fs
; vf13 - write string
;
; in:	ves:vbp -> string to write
;	vcx = length of character string
;	vdx = cursor position
;	vbh = page number
;	val = 0  then  vbl = attribute & string is [char,char,char...]
;	  cursor not moved
;	val = 1  then  vbl = attribute & string is [char,char,char...]
;      	  cursor is moved
;	val = 2  then  string is [char,attr,char,attr...]
;	  cursor not moved
;	val = 3  then  string is [char,attr,char,attr...]
;	  cursor is moved
;
; out:
;
;,fe
;======================================================================
	assume	ds:tcb,es:bios,ss:nothing
vf13 proc far
	mov	[tcbkbcnt],0		; counteract dis mode
	cmp	[tcx],0 		; anything to write?
	jne	$+5
	jmp	near ptr vf13z

; save current cursor pos

	mov	bl,[tbh]
	xor	bh,bh
	shl	bx,1
	push	[tcbcpos+bx]		; restore original cursor pos

; set starting cursor position to vdx

	mov	dx,[tdx]
	mov	[tcbcpos+bx],dx
	push	[tax]			; save current callers registers
	push	[tbx]
	push	[tcx]
	push	[tsi]			; we will use this as temp storage for user ax
	mov	ax,[tax]
	mov	[tsi],ax		; set user al command code for easy access
	cmp	al,4			; validate command code
	jb	$+5
	jmp	near ptr vf13x		; invalid command code
	mov	es,[tes]		; get string pointer
	mov	di,[tbp]		; "     "
	mov	cx,[tcx]		; get string length char count (char/attr = 1)
vf13a1:
	mov	[tcx],1 		; for 'vf09'
	mov	al,es:[di]		; get next char
	mov	[tal],al		; set for 'vf0e' or 'vf09'
	inc	di			; update string pointer
	mov	bl,[tbl]		; attr to use
	cmp	byte ptr [tsi],2	; attr in string?
	jb	vf13b
	mov	bl,es:[di]		; get attr for char
	inc	di
vf13b:
	cmp	al,13
	je	vf13b3
	cmp	al,10
	je	vf13b3
	cmp	al,8
	je	vf13b3
	cmp	al,7
	je	vf13b3
vf13b1:
	cmp	cx,1
	je	vf13b3
	cmp	al,es:[di]
	jne	vf13b3
	cmp	byte ptr [tsi],2
	jb	vf13b2
	cmp	bl,es:[di+1]
	jne	vf13b3
	inc	di
vf13b2:
	inc	di
	dec	cx
	inc	[tcx]
	mov	bh,byte ptr [tcl]
	cmp	bh,[tcbcols]
	jb	vf13b
vf13b3:
	push	es
	push	di
	push	cx
	push	ds
	cmp	al,13			; cr?
	jbe	$+5
	jmp	near ptr dovf09 	; no, treat as printable
	je	dovf0e			; yes, output to tty
	cmp	al,10			; lf?
	je	dovf0e			; yes, output to tty
	cmp	al,08			; bs?
	je	dovf0e			; yes, handle with tty
	cmp	al,07			; bel?
	jne	dovf09			; no, all others as char/attr
dovf0e:

; do tty output (non printables)

	mov	[tah],13h
	mov	ax,bios
	mov	es,ax
	push	cs
	call	near ptr vf0e		; do tty
	pop	ds
	assume	ds:tcb
	pop	cx
	pop	di
	pop	es
	assume	es:nothing
	loop	vf13a1
	jmp	near ptr vf13x
dovf09:

; do char/attr with printables

	mov	[tbl],bl		; set attr
	mov	ax,bios
	mov	es,ax
	push	cs
	call	near ptr vf09
	pop	ds
	assume	ds:tcb
	pop	cx
	pop	di
	mov	ax,bios
	mov	es,ax
	assume	es:bios
	mov	bl,[tbh]
	xor	bh,bh
	shl	bx,1
	mov	dx,[tcbcpos+bx] 	; get current cursor pos
	add	dx,[tcx]
	cmp	dl,[tcbcols]		; # cols/row for screen
	jb	vf13c
	sub	dl,[tcbcols]
	inc	dh
	cmp	dh,[tcbrows]		; scroll screen?
	jne	vf13c

; screen must be scrolled here, so just output a lf

	dec	dh			; last line
	mov	[biocpos+bx],dx 	; set new position
	mov	[tcbcpos+bx],dx
	pop	es
	mov	al,10
	mov	[tal],al
	jmp	near ptr vf13b		; let tty routines do the scroll
vf13c:
	mov	[biocpos+bx],dx 	; set new cursor position
	mov	[tcbcpos+bx],dx
	pop	es
	dec	cx
	jz	vf13x
	jmp	vf13a1
vf13x:
	pop	[tsi]
	pop	[tcx]
	pop	[tbx]
	pop	[tax]			; original callers ax back

; restore cursor postion if need be

	pop	dx			; get saved original cursor pos
	mov	bx,bios
	mov	es,bx
	assume	es:bios
	mov	al,[tbh]
	mov	bl,al
	xor	bh,bh
	shl	bx,1
	mov	[biocpos+bx],dx
	xchg	dx,[tcbcpos+bx] 	; new position if cursor to be moved
	cmp	[tal],0 		; cursor not to be moved
	je	vf13y
	cmp	[tal],2 		; cursor not to be moved
	je	vf13y
	cmp	[tal],4 		; invalid command must restore cursor
	jb	vf13z			; keep new cursor position
vf13y:
	ret				; retain old position
vf13z:
	jmp	near ptr mcsync 	; synchronize master console
vf13 endp

	subttl crspos - text mode screen offset from row and col
	page
;======================================================================
;,fs
; crspos - text mode screen offset from row and col
;
; in:	al = page
;
; out:	di = offset of cursor in screen
;	dh = cursor row, dl = cursor col
;	bx = offset of cursor in page
;	es = tcbvidw1
;
;,fe
;======================================================================
	assume	ds:tcb,es:bios,ss:nothing
crspos:
	mov	bl,al
	xor	bh,bh
	shl	bx,1
	mov	dx,[tcbcpos+bx]

	subttl scrpos - text mode screen offset from row and col
;======================================================================
;,fs
; scrpos - text mode screen offset from row and col
;
; in:	dh = row, dl = col, al = page
;
; out:	di = row, col offset within screen
;	bx = row, col offset within page
;	es = tcbvidw1
;
;,fe
;======================================================================
	assume	ds:tcb,es:bios,ss:nothing
scrpos:
	push	ax
	cmp	dh,[tcbrows]
	jb	sp1
	mov	dh,[tcbrows]
	dec	dh
sp1:
	cmp	dl,[tcbcols]
	jb	sp2
	mov	dl,[tcbcols]
	dec	dl
sp2:
	mov	si,dx
	xchg	al,dh
	xor	ah,ah
	call	colmul			; multiply by 80 or 40
	mov	di,bx
	mov	al,dl
	xor	ah,ah
	add	di,ax			; + col
	add	di,di			; * 2 for char/attribute
	mov	bx,di			; row, col offset within page
	mov	ax,[tcbpgst]
	cmp	dh,[tcbpage]
	je	scrpos2
	mov	al,dh
	xor	ah,ah
	mul	[tcbpgln]
scrpos2:
	add	di,ax			; + offset into screen buffer for page
	mov	dx,si
	mgetscb2 es
	assume	es:grp
	mov	es,[scbmastv]
	assume	es:nothing
	pop	ax
	ret

	subttl colmul - multiply number in ax by column number
	page
;======================================================================
;,fs
; colmul - multiply number in ax by column number
;
; in:	ax = number to multiply by column number
;
; out:	bx = input number * 40 or 80
;	ax, bx changed
;
;,fe
;======================================================================
	assume	ds:tcb,es:bios,ss:nothing
colmul proc near
	shl	ax,1
	shl	ax,1
	shl	ax,1
	cmp	[tcbcols],40
	je	colmul1
	shl	ax,1
colmul1:
	mov	bx,ax			; row*16 or row*8
	shl	ax,1
	shl	ax,1
	add	bx,ax			; row*80=row*16+row*64 or row*40=row*8+row*32
	ret
colmul endp

	subttl cursynch - synchronize each terminal's physical cursor
	page
;======================================================================
;,fs
; cursynch - synchronize each terminal's physical cursor
;
; in:
;
; out:
;
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:tcb
cursynch proc far
	push	ds			; save ds
	push	es			; and es
	mgetscb2 ds			; get the scb segment
	assume	ds:grp, es:nothing, ss:nothing
	mov	es, [scbtcbpc]		; point es at the current task
	assume	ds:grp, es:tcb, ss:nothing
	cmp	[tcbsiorb], 0		; is serial i/o roadblocked
	pop	es			; restore es
	pop	ds			; and ds
	assume	ds:nothing,es:nothing,ss:tcb
	je	cs00			; press on if ok to do more i/o
	ret				; return to caller
cs00:
	push	es
	push	ds
	push	ss
	pop	ds
	assume	ds:tcb,ss:nothing
	mov	al,[tcbpage]
	mov	ah,[tcbcols]
	call	crspos
	mov	si,[tcbscrdd]
cursy1:
	or	si,si
	jz	cursyx
	mov	ds,si
	push	es
	push	di
	push	dx
	push	bx
	push	ax
	mov	si,offset [tcbcondd]
	mov	[si+4],di
	mov	[si+6],es
	mov	[si+8],bx
	mov	[si+10],ah
	mov	ah,05h
	call	ddtifnot
	pop	ax
	pop	bx
	pop	dx
	pop	di
	pop	es
	mov	si,[tcbnxtdd]
	jmp	near ptr cursy1
cursyx:
	pop	ds
	pop	es
	ret
cursynch endp

	subttl scrollit - scroll box in buffer up or down
	page
;======================================================================
;,fs
; scrollit - scroll box in buffer up or down
;
; in:	es:si = source for first line
;	es:di = dest for first line
;	cx = number of chars/line
;	bx = add to source and dest
;	ax = char and attribute for blank lines
;	dh = number of lines to blank
;	dl = number of lines to move
;
; out:	ax, bx, cx, bp, ds, es unchanged
;
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:nothing
scrollit:
	push	ds
	push	bp
	mov	bp,es
	mov	ds,bp
	mov	bp,cx
	or	dl,dl
	jz	scrollb
scrolla:
	call	wordmov
	add	si,bx
	add	di,bx
	mov	cx,bp
	dec	dl
	jnz	scrolla
scrollb:
	or	dh,dh
	jz	scrolld
scrollc:
	rep	stosw
	add	di,bx
	mov	cx,bp
	dec	dh
	jnz	scrollc
scrolld:
	pop	bp
	pop	ds
	ret

	subttl scruparg - set up parameters for scroll up
	page
;======================================================================
;,fs
; scruparg - set up parameters for scroll up
;
; in:	cx = box top-left-corner row/col
;	dx = box btm-rite-corner row/col
;	al = number of lines
;	bl = attribute for blank lines
;	bh = page
;
; out:	si = source offset for first line
;	di = dest offset for first line
;	cx = number of chars/line
;	bx = add to source and dest at end of line for next line
;	ax = char and attribute for blank lines
;	dh = number of lines to blank
;	dl = number of lines to move
;
;,fe
;======================================================================
	assume	ds:tcb,es:nothing,ss:nothing
scruparg:
	mov	si,cx
	inc	dl
	inc	dh
	sub	dl,cl
	mov	cl,dl			; number of cols/box
	sub	dh,ch			; number of rows/box
	or	al,al
	jnz	scrup1
	mov	al,dh
scrup1: 				; al = number of lines to blank
	sub	dh,al
	jae	scrup2			; dh = number of lines to move
	add	al,dh			; blank all lines
	xor	dh,dh			; move no lines
scrup2:
	mov	dl,al			; dl = number to blank
	xchg	dh,dl
	xor	ch,ch			; cx = length (words) to move for each line
	push	bx			; save first, & save across call
	push	dx			; dh = number to blank, dl = number to move
	mov	dx,si
	mov	al,bh
	mov	ah,[tcbcols]
	call	scrpos
	assume	es:nothing
	pop	dx
	mov	si,di			; destination for first line to move
	mov	al,dh			; lines to blank is distance to move lines
	xor	ah,ah
	call	colmul			; multiply by # of columns to get source
	add	bx,bx			; convert # of characters to words
	add	si,bx			; source of first line to move
	pop	bx
	mov	al,[tcbcols]
	xor	ah,ah
	shl	ax,1
	shl	cx,1
	sub	ax,cx			; addend to get from end of one line to start of next
	shr	cx,1			;   line
	xchg	ax,bx
	mov	ah,al
	mov	al,20h
	ret

	subttl scrdnarg - set up parameters for scroll down
	page
;======================================================================
;,fs
; scrdnarg - set up parameters for scroll down
;
; in:	cx = box top-left-corner row/col
;	dx = box btm-rite-corner row/col
;	al = number of lines
;	bl = attribute for blank lines
;	bh = page
;
; out:	si = source offset for first line
;	di = dest offset for first line
;	cx = number of chars/line
;	bx = add to source and dest at end of line for next line
;	ax = char and attribute for blank lines
;	dh = number of lines to blank
;	dl = number of lines to move
;
;,fe
;======================================================================
	assume	ds:tcb,es:nothing,ss:nothing
scrdnarg:
	xchg	si,bx
	mov	bh,dh
	mov	bl,cl
	xchg	si,bx
	inc	dl
	inc	dh
	sub	dl,cl
	mov	cl,dl			; number of cols/box
	sub	dh,ch			; number of rows/box
	or	al,al
	jnz	scrdn1
	mov	al,dh
scrdn1: 				; al = number of lines to blank
	sub	dh,al
	jae	scrdn2			; dh = number of lines to move
	add	al,dh			; blank all lines
	xor	dh,dh			; move no lines
scrdn2:
	mov	dl,al			; dl = number to blank
	xchg	dh,dl
	xor	ch,ch			; cx = length (words) to move for each line
	push	bx			; save across call & save first
	push	dx			; dh = number to blank, dl = number to move
	mov	dx,si
	mov	al,bh
	mov	ah,[tcbcols]
	call	scrpos
	assume	es:nothing
	pop	dx
	mov	si,di			; destination for first line to move
	mov	al,dh			; lines to blank is distance to move lines
	cbw
	call	colmul			; multiply by # of columns to get source
	add	bx,bx			; convert # of characters to words
	sub	si,bx			; source of first line to move
	pop	bx
	mov	al,[tcbcols]
	xor	ah,ah
	shl	ax,1
	shl	cx,1
	add	ax,cx			; addend to get from end of one line to start of next
	shr	cx,1			;   line
	neg	ax
	xchg	ax,bx
	mov	ah,al
	mov	al,20h
	ret

	subttl fixbox - fixup a scroll box so it's proper
	page
;======================================================================
;,fs
; fixbox - fixup a scroll box so it's proper
;
; in:	ah = number of cols/line
;
; out:
;
;,fe
;======================================================================
	assume	ds:tcb,es:nothing,ss:nothing
fixbox:
	cmp	dh,[tcbrows]		; is lower row spec too large?
	jb	fix1
	mov	dh,[tcbrows]		; if yes, mod to max
	dec	dh
fix1:
	cmp	dl,ah
	jb	fix2
	mov	dl,ah
	dec	dl
fix2:
	cmp	ch,dh
	jna	fix3
	mov	ch,dh
fix3:
	cmp	cl,dl
	jna	fix4
	mov	cl,dl
fix4:
	ret

	subttl cononly - return z if master console only looking at screen
	page
;======================================================================
;,fs
; cononly - return z if only master console is looking at screen
;
; in:
;
; out:	return z if only master console is looking at screen
;
;,fe
;======================================================================
	assume	ds:tcb,es:nothing,ss:nothing
public	cononly
cononly:
	push	es
	push	ds
	push	bx
	push	ax
	mgetscb2 es
	assume	es:grp
	cmp	[tcbscrdd],0
	je	cononly1		; nobody looking at screen
	mov	al,[tcbmode]
	mov	bx,[tcbvidw2]
	mov	ds,[tcbscrdd]
	test	[tcbvram],80h
	jz	cononly1		; not master console
	cmp	[tcbnxtdd],0
	jne	cononly1		; e if only master console looking
	cmp	[tcbvidad],0
	je	conskip 		; if tcbvidad and tcbvidw2 have both been
	or	bx,bx			; set but are not equeal then can't be
	jz	conskip 		; mc only
	cmp	bx,0a000h		; test for a000 of ega which is mc only
	je	conskip
	cmp	bx,[tcbvidad]
	jne	cononly1
conskip:
	cmp	[tcbpage],0
	jne	cononly1		; support buffers if not in page 0
	cmp	[tcbstation],05
	jae	con0a
	test	[tcbvram],40h
	jnz	con0a			; nz if master console supports graphics
	cmp	al,4			; maintain buffers if graphics mode
	jb	con0a			; but master console doesn't support it
	cmp	al,7
	jb	cononly1
	je	con0a
	cmp	al,80h
	jne	cononly1
	test	[tcbvram],10h
	jz	cononly1
con0a:

; if vidram and not mm then vidram address<>video buffer (8088)
; therefore, apps mod vidram direct and we always need to update
; also if there is mm and no vidram there is no buffer

	cmp	[tcbstate],0
	jne	cononly0		; if ega\vgastate saving, no screen buffer

; the meaning of the following tests may not be apparent without
; explanation:	if have a memory manager which does not support video mapping
; (e.g. jram) or don't have any memory management then tcbvram bit 1 is the
; final criteria in determining if vidram should be used.  if tcbvram bit 1 is
; set then a tsr type of vidram is in place so must always use vidram.

	test	[scbmmmod],80h
	jnz	cononly0		; if video mm then no screen buffer or vidram
	test	[tcbvram],01h
	jnz	cononly1		; if vidram inactive, no screen buffer either
cononly0:
	cmp	al,al			; set z flag
	jmp	cononly3
cononly1:
	cmp	[tcbtype],0		; clear z flag (must be 'T' for valid tcb)
cononly3:
	pop	ax
	pop	bx
	pop	ds
	pop	es
	ret

	subttl vidram - do a check of the vidram buffer
	page
;======================================================================
;,fs
; vidram - do a check of the vidram buffer
;
; compare vidram buffer with screen save buffer and update
; the terminals if there are any discrepancies
;
; in:	ss -> tcb for screen
;	cx = timer value now
;
; out:
;
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:tcb
nvidram proc far

; update the poll timer - and don't let it be zero or there will be no
; more vidram checking

	push	ds
	mgetscb2 ds
	assume	ds:grp
	mov	[invidram],'Y'
	add	cx,[scbvrwait]
	or	cx,cx
	jnz	vdrm020
	inc	cx
vdrm020:
	mov	bx,[vrmtmr]
	mov	ss:[bx],cx		; look again in scbvrwait ticks

; check for exclusions to vidram processing

	cmp	[vdrskip],'Y'		; in the middle of a pamswitch?
	pop	ds
	assume	ds:nothing
	je	vdrm030
	test	[tcbvram],01h		; is vidram even active?
	jz	vdrm030
	cmp	[tcbsiorb], 0		; is serial i/o roadblocked?
	jne	vdrm030
	cmp	[tcbstate],0		; using state logic?
	jne	vdrm030
	cmp	[tcbscrdd],0		; is nobody is looking?
	je	vdrm030
	cli
	and	[tcbvram],0feh		; clear vidram on bit for 'cononly' routine
	push	ds
	push	ss
	pop	ds
	assume	ds:nothing
	call	cononly 		; is the only watcher a con only workstation?
	pop	ds
	pushf				; save zero flag setting from cononly
	or	[tcbvram],1		; set bit back on
	popf
	sti
	jnz	vdrm040
vdrm030:
	jmp	vdrm530

; the pamswitch procedure uses this special entry point to force an
; update for a task that has changed to cononly status

vdrm040:
	cmp	[tcbmode],4
	jb	vdrm050
	cmp	[tcbmode],7
	je	vdrm050
	jmp	near ptr vdrm240
vdrm050:
	push	ds
	push	bp
	mov	ax,[tcbpgst]
	mov	dl,[tcbcols]
	mgetscb2 ds
	assume	ds:grp
	mov	ds,[scbmastv]
	assume	ds:nothing
	mov	es,[tcbvidw2]
	mov	di,ax
	mov	si,ax
	mov	bp,ax			; remember offset of start of page
	xor	dh,dh			; starting at row 0
	mov	cl,dl
	xor	ch,ch

; compare one row at a time until done, or a mismatch is found

vdrm060:
	repe cmpsw
	jne	vdrm070
	mov	cl,dl
	xor	ch,ch
	inc	dh
	cmp	dh,[tcbrows]
	jb	vdrm060 		; already exposed
	jmp	vdrm520 		; all done

; es:[di-2] was different from ds:[si-2]
; cl+1 chars remaining in row (including mismatched)
; thus mismatch at col dl-(cl+1) and row dh

vdrm070:
	mov	[tcbkbcnt],0		; reset kb loop disable
	sub	di,2
	mov	si,di
	inc	cl
	mov	ax,dx
	sub	al,cl			; ax = row/col of start of mis-compare
	mov	bx,di			; bx = starting offset of mis-compare

; compare remainder of this row, then one row at a time until match
;   found again

vdrm080:
	repne cmpsw
	je	vdrm090
	mov	cl,dl
	xor	ch,ch
	inc	dh
	cmp	dh,[tcbrows]
	jb	vdrm080
	jmp	near ptr vdrm100

; ds:[si-2] = ds:[di-2]
; c+1 chars remaining in row, including matched char

vdrm090:
	inc	cl
	sub	di,2
vdrm100:
	push	di			; offset of next match
	push	dx			; row of next match
	push	cx			; chars remaining in row from next match
	sub	di,bx			; bytes which didn't match
	mov	cx,di
	shr	cx,1			; number of words to refresh
	mov	di,bx			; offset of start
	mov	dx,ax			; row/col of mis-compare
	sub	bx,bp			; offset into page
	assume	ds:nothing,ss:tcb
	mov	ax,ds			; ax:di -> screen buffer offset to refresh

; then refresh screen buffer itself
; ax:di -> screen buffer offset to start refresh
; cx = number of words to refresh
; es:di -> vidram buffer to get refresh

	push	es
	push	di
	push	cx
	mov	si,es
	mov	ds,si
	mov	es,ax
	mov	si,di			; update the screen buffer
	call	wordmov 		; fast move on 386\486
	pop	cx
	pop	di
	pop	es

; here:
;   ax:di -> screen buffer offset to start refresh
;   es:di -> vidram buffer
;   cx = number of words to refresh
;   dx = row/col for string
;   bx = offset into page for string
; write the string to each terminal

	push	es
	mgetscb2 es
	assume	es:grp
	mov	[vdrirq],'Y'		; tell any irq's that the video is non-standard
	mov	es,ax
	assume	es:nothing		; make es:di the source address
	mov	si,[tcbscrdd]
vdrm110:
	or	si,si
	jz	vdrm120
	mov	ds,si
	push	es
	push	di
	push	dx
	push	cx
	push	bx
	push	ax
	mov	si,offset [tcbcondd]
	mov	[si+4],di
	mov	[si+6],ax
	mov	[si+8],bx
	mov	ah,[tcbcols]
	mov	[si+10],ah
	assume	ds:tcb,ss:tcb
	mov	ax,0b02h		; write string of char,attr,char,attr...
	call	ddtcall 		; see if ddt busy and call
	pop	ax
	pop	bx
	pop	cx
	pop	dx
	pop	di
	pop	es
	mov	si,[tcbnxtdd]
	jmp	near ptr vdrm110
vdrm120:
	pop	es			; es = vidram address
	pop	cx			; cx = remaining chars in row after match
	pop	dx			; dl = cols/row, dh = current row
	pop	di			; di = offset into screen buffers of match
	mov	ds,ax			; ds -> screen buffer
	assume	ds:nothing,ss:tcb
	mov	si,di			; and back for more checks
	call	gvram			; expose vidram buffer if needed
	push	es
	mgetscb2 es
	assume	es:grp
	mov	[vdrirq],'N'		; tell any irq's that the video ok now
	pop	es
	assume	es:nothing
	cmp	dh,[tcbrows]
	jmpb	vdrm060
	jmp	vdrm520 		; all done 

	assume	ds:nothing,es:nothing,ss:tcb
; video buffer description structure

vdsc	struc
vadd2	dw	0			; increment for 2nd buffer
vadd3	dw	0			; increment for 3rd buffer
vadd4	dw	0			; increment for 4th buffer
vadd1	dw	0			; increment back to 1st buffer
vwpl	dw	0			; words / line
vlps	dw	0			; lines / screen
vdsc	ends

; video buffer description for cga
cga	vdsc	<2000h-80,-2000h,2000h-80,-2000h,40,200>
; video buffer description for hgc
hgc	vdsc	<2000h-90,2000h-90,2000h-90,-2000h*3,45,348>

; graphics mode vidram compare

vdrm240:
	push	ds
	push	bp
	mov	bp,offset mo2:cga
	cmp	[tcbmode],80h
	jne	vdrm250 		; = if in hercules graphics mode
	mov	bp,offset mo2:hgc
vdrm250:
	mgetscb2 ds
	assume	ds:grp
	mov	ds,[scbmastv]		; video save buffer segment
	assume	ds:nothing
	mov	ax,[tcbvidw2]		; vidram segment
	cmp	[tcbmode],80h		; if hercules mode,
	jne	vdrm260
	mov	ch,[tcb03bf]		; vidram address depends upon active page
	ror	ch,1
	ror	ch,1
	and	ch,[tcb03b8]
	and	ch,80h
	mov	cl,4
	shr	ch,cl
	or	ah,ch
vdrm260:
	mov	es,ax
	mov	dx,cs:[bp].vlps 	; lines per screen
	mov	cx,cs:[bp].vwpl 	; words per line
	xor	di,di			; vidram offset
	mov	si,di			; video save offset

; compare one row at a time until done, or a mismatch found within some

vdrm270:
	mov	al,dl
	and	al,03h
	jz	vdrm280 		; z for first buffer
	cmp	al,02h
	ja	vdrm290 		; =3 for second buffer (cause counting down)
	je	vdrm300 		; =2 for third buffer
	jmp	vdrm310 		; =1 for fourth buffer
vdrm280:
	repe cmpsw
	jne	vdrm320
	add	di,cs:[bp].vadd2	; addend to second buffer
	mov	cx,cs:[bp].vwpl 	; words per line
	dec	dx
vdrm290:
	repe cmpsw			; etc.
	jne	vdrm320
	add	di,cs:[bp].vadd3
	mov	cx,cs:[bp].vwpl
	dec	dx
vdrm300:
	repe cmpsw			; etc.
	jne	vdrm320
	add	di,cs:[bp].vadd4
	mov	cx,cs:[bp].vwpl
	dec	dx
vdrm310:
	repe cmpsw			; etc.
	jne	vdrm320
	add	di,cs:[bp].vadd1	; addend back to buffer 1
	mov	cx,cs:[bp].vwpl
	dec	dx
	jnz	vdrm280
	jmp	vdrm520 		; all done

; miscompare in buffers if here
; now find the end of the inequality

vdrm320:
	sub	di,2			; back to first unequal comparison
	sub	si,2
	inc	cx
	push	dx			; lines left at start of miscompare
	push	di
	push	si
	push	cx			; words left in line at start of miscompare
	mov	al,dl
	and	al,03h
	jz	vdrm330 		; = 0 for buffer 1
	cmp	al,2
	ja	vdrm340 		; = 3 for second buffer
	je	vdrm350 		; = 2 for third buffer
	jmp	vdrm360 		; = 1 for fourth buffer
vdrm330:
	repne cmpsw
	je	vdrm370
	add	di,cs:[bp].vadd2
	mov	cx,cs:[bp].vwpl
	dec	dx
vdrm340:
	repne cmpsw
	je	vdrm370
	add	di,cs:[bp].vadd3
	mov	cx,cs:[bp].vwpl
	dec	dx
vdrm350:
	repne cmpsw
	je	vdrm370
	add	di,cs:[bp].vadd4
	mov	cx,cs:[bp].vwpl
	dec	dx
vdrm360:
	repne cmpsw
	je	vdrm370
	add	di,cs:[bp].vadd1
	mov	cx,cs:[bp].vwpl
	dec	dx
	jnz	vdrm330
	add	di,2			; make up for subtraction below
	add	si,2			; ditto

; now the end of the inequality has been found

vdrm370:
	pop	ax			; words remaining in line at start
	mov	ch,al			; remember it (less than 256 words/line)
	pop	bx			; buffer offset
	pop	ax			; vidram offset
	pop	bp			; lines remaining at start of miscompare
	sub	di,2			; back to first equal compare
	sub	si,2
	inc	cl

; save state for resumption of vidram checking

	push	di			; vidram offset at end
	mov	di,ax			; vidram offset of start
	mov	al,ch			; setting ax = start words remaining in line
	xor	ah,ah			; cx = end words remaining in line
	mov	ch,ah
	push	si			; buffer offset at end
	push	dx			; lines remaining at end
	push	cx			; words remaining in line at end
	push	es
	push	ds

; update screen buffer itself

	mov	dx,bp			; remaining lines at start of inequality
	mov	cx,ax			; remaining words in line at start
	mov	bp,offset mo2:cga	; resetting buffer parameter pointer
	cmp	[tcbmode],80h
	jne	vdrm380
	mov	bp,offset mo2:hgc
vdrm380:
	mov	ax,cs:[bp].vwpl
	sub	ax,cx			; word offset of start of inequality
	shl	ax,1			; byte offset
	push	ax			; byte offset to start update
	mov	ax,cs:[bp].vlps
	sub	ax,dx
	push	ax			; line offset to start update
	push	bx			; buffer offset to start update
	xchg	si,bx
	sub	bx,si
	shr	bx,1
	push	bx			; number of words to update
	push	di			; vidram offset to start update
	xchg	di,si
	mov	ax,ds
	push	es
	pop	ds
	mov	es,ax
	mov	al,dl
	and	al,03h
	jz	vdrm390
	cmp	al,2
	ja	vdrm410
	je	vdrm430
	jmp	vdrm450
vdrm390:
	sub	bx,cx
	jae	vdrm400
	add	cx,bx
	xor	bx,bx
vdrm400:
	call	wordmov 		; fast move on 386\486
	mov	cx,cs:[bp].vwpl
	add	si,cs:[bp].vadd2
	or	bx,bx
	jz	vdrm470
vdrm410:
	sub	bx,cx
	jae	vdrm420
	add	cx,bx
	xor	bx,bx
vdrm420:
	call	wordmov 		; fast move on 386\486
	mov	cx,cs:[bp].vwpl
	add	si,cs:[bp].vadd3
	or	bx,bx
	jz	vdrm470
vdrm430:
	sub	bx,cx
	jae	vdrm440
	add	cx,bx
	xor	bx,bx
vdrm440:
	call	wordmov 		; fast move on 386\486
	mov	cx,cs:[bp].vwpl
	add	si,cs:[bp].vadd4
	or	bx,bx
	jz	vdrm470
vdrm450:
	sub	bx,cx
	jae	vdrm460
	add	cx,bx
	xor	bx,bx
vdrm460:
	call	wordmov 		; fast move on 386\486
	mov	cx,cs:[bp].vwpl
	add	si,cs:[bp].vadd1
	or	bx,bx
	jnz	vdrm390

; now update the ddt's themselves

vdrm470:
	pop	di			; screen offset
	pop	cx			; words to update
	pop	bx			; buffer offset
	pop	dx			; line offset
	pop	ax			; byte offset into line

; here:
;   es:bx -> screen buffer offset to start refresh
;   ds:di -> vidram buffer
;   cx = number of words to refresh
;   dx = line offset
;   ax = byte offset
; write the string to each terminal

	mov	ah,dl
	mov	dl,al			; dl = byte offset into line
	mov	al,dh
	mov	dh,ah			; al:dh = line offset into screen
	mov	ah,[tcbcols]
	mov	si,[tcbscrdd]
	push	es
	mgetscb2 es
	assume	es:grp
	mov	[vdrirq],'Y'		; tell any irq's that the video is non-standard
	pop	es
	assume	es:nothing
vdrm480:
	or	si,si
	jz	vdrm510
	mov	ds,si
	push	es
	push	di
	push	dx
	push	cx
	push	bx
	push	ax
	mov	si,offset [tcbcondd]
	mov	[si+4],di
	mov	[si+6],es
	mov	[si+8],di
	mov	di,bx
	mov	[si+10],ah
	assume	ds:tcb,ss:nothing
	mov	ah,50h			; to ddt only if it supports
	cmp	bp,offset mo2:cga	; the current mode
	je	vdrm490
	mov	ah,10h
vdrm490:
	test	[tcbvram],ah
	jz	vdrm500
	mov	ah,0bh
	call	ddtcall 		; see if ddt busy and call
vdrm500:
	pop	ax
	pop	bx
	pop	cx
	pop	dx
	pop	di
	pop	es
	mov	si,[tcbnxtdd]
	jmp	near ptr vdrm480
vdrm510:
	pop	ds
	pop	es
	pop	cx
	pop	dx
	pop	si
	pop	di
	call	gvram			; expose vidram buffer if needed
	push	es
	mgetscb2 es
	assume	es:grp
	mov	[vdrirq],'N'		; tell any irq's that the video is ok now
	pop	es
	assume	es:nothing
	or	dx,dx
	jmpnz	vdrm270
vdrm520:
	pop	bp
	pop	ds
vdrm530:
	push	ds
	mgetscb2 ds
	assume	ds:grp
	mov	[invidram],'N'
	pop	ds
	assume	ds:nothing
	ret
nvidram endp

	subttl ddtifnot - call ddt if not graphics
	page
;======================================================================
;,fs
; ddtifnot - call ddt if not graphics
;
; call ddt through dword ptr ds:[si] if ddt doesn't support 
; graphics or screen isn't in graphics mode
;
; in:
;
; out:
;
;,fe
;======================================================================
	assume	ds:tcb,es:nothing,ss:nothing
ddtifnot:
	test	[tcbvram],50h		; hercules also
	jz	ddtin1
	cmp	[tcbcmode],4
	jb	ddtin1
	cmp	[tcbcmode],7
	je	ddtin1			; be here if in graphics mode and ddt will
	ret
ddtin1:
	call	ddtcall 		; see if ddt busy and call
ddtin2:
	ret

	subttl graphics - handle graphics mode chores
	page
;======================================================================
;,fs
; graphics - handle graphics mode chores
;
; if in graphics mode, call rom bios to interpret call 
; and return z else return nz without calling rom
;
; in:
;
; out:
;
;,fe
;======================================================================
	assume	ds:tcb,es:nothing,ss:nothing
graphics:
	cmp	[tcbmode],4
	jb	gr1
	cmp	[tcbmode],7
	je	gr1
	call	cononly
	jz	gr1
	test	[tcbvram],01h
	jz	gr1
	push	ax
	call	gvram
	pop	ax
	push	ds
	mgetscb2 ds
	assume	ds:grp
	pushf
	call	[i10old]
	pop	ds
	assume	ds:tcb
	cmp	al,al
	ret
gr1:
	cmp	[tcbtype],0		; set nz (not in graphics mode)
	ret

	subttl ddtcall - control access to the console driver [tcbcondd]
	page
;======================================================================
;,fs
; ddtcall - control access to the console driver [tcbcondd]
;
; ddtcall is used to prevent reentry to a terminal driver when
; a task has been suspended because it's serial buffers
; are full.  this is accomplished by setting [tcbsiorb]
; in the tcb pointed to by [scbtcbpc] to nonzero.  this
; flag is also used by cursynch and nvidram to prevent
; sending additional serial i/o to a terminal that is
; already busy.
;
; in:	ah = ddt function
;	ds:si = location of ddtrec
;	??    = as required by the ddt
;
; out:
;
;,fe
;======================================================================
	assume	ds:tcb, es:nothing, ss:nothing
	public	ddtcall
ddtcall proc near
	test	[tcbvram],80h		; is this for a terminal driver
	jnz	dc00			; skip check if not for terminal
	assume	ds:nothing
	cmp	ah, 3			; does this call produce output
	jae	dc10			; check busy if producing output
dc00:
	call	dword ptr [si]		; call the device driver
	ret				; return to caller
dc10:
	push	ds
	push	es
	mgetscb2 ds			; get the scb segment
	assume	ds:grp, es:nothing
	mov	es, [scbtcbpc]		; point es at the current task
	assume	ds:grp, es:tcb
	cmp	[tcbsiorb], 0		; is serial i/o roadblocked
	jne	dc20			; exit if driver already busy
	mov	[tcbsiorb], 0ffh	; set to roadblock further i/o
	pop	es
	pop	ds
	assume	ds:nothing, es:nothing
	call	dword ptr [si]		; call the driver
	push	ds
	push	es
	mgetscb2 ds			; get the scb segment
	assume	ds:grp, es:nothing
	mov	es, [scbtcbpc]		; point es at the current task
	assume	ds:grp, es:tcb
	mov	[tcbsiorb], 0		; clear the roadblock when done
dc20:
	pop	es
	pop	ds
	assume	ds:nothing, es:nothing, ss:nothing
	ret
ddtcall endp

ddt	ends
	end

