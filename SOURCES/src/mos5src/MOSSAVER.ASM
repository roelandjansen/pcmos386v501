	include page.inc
	title	mossaver - common logic for mos interrupt entry
extrn	bugerror:near		; enable debug error reporting
comment ^===============================================================
		      development specification

 program name:	$$mos.com		 assigned to: jim bean
 module name:	mossaver		 assign date: 01/30/86
 entry points:	mossaver		 completed:   02/10/86
 entry from:	mosintxx
 entry method:	call
 purpose:	common logic for mos interrupt entry
 refer to:	dosaver.inc (ml advanced)
 last update:	08/18/1992
========================================================================

this module is called more or less at the beginning of all
interrupt routines(mosintxx).	it handles the saving of
application registers, setting "standard" registers in mos, and
various other chores and housekeeping that may be required on a
periodic basis.  its logic will depend on that in various other
routines... best bet for initial programming is to refer to
dosaver.inc.

"Standard" register usage is as follows:

      ds - same as cs; addresses scb
      ss - points to tcb of active task
      sp - current internal stack pointer
      bp - points to the application's registers

by using [bp+nn] to address the application's registers, we
remove a roadblock to recursion; i.e., there is no need for a
"fixed" area of the tcb to hold these register values.  besides,
bp isn't much good for anything else.  Note that using BP as an
index implies that ss is the default segment register.

mossaver assumes that a call to mossaver is the first instruction in
the calling int xxh handler, i.e. that cs = grp, that interrupts
are disabled, that no registers have been changed and that there has
been nothing pushed on the stack

mosrestore assumes that the caller is going to do an iret immediately
following the return from mosunsaver, i.e. that no registers are
going to be changed before an iret is executed back to the original
int xxh caller

an int xxh handler shell would thus be:

	assume	ds:nothing,es:nothing,ss:nothing
intxxh: 
	call	mossaver		; also does sti and cld
	assume	ds:scb,ss:tcb
	.... any int xxh handler processing
	.... (possibly including a task switch)
	call	mosrestore
	iret
	assume	ds:nothing,ss:nothing

implemented mossaver so as to reduce the time spent in the critical
region with the stack segment and pointer stored in local storage as
well as copying cs, ip, and flags from the application stack to the
tcb stack

the net result is that ss:bp ends up pointing to the following
structure:

	   application's IP = +0
			 cs = +2
		      flags = +4
			 ds = +6
			 es = +8
			 di = +10
			 si = +12
			 bp = +14
		    garbage = +16
			 bx = +18
			 dx = +20
			 cx = +22
			 ax = +24
			 sp = +26
			 ss = +28
		    garbage = +30

these are defined as follows in the include file mosregs.inc, they
are accessed for the current partition using the labels below.
the parentheses allow you to override the type attribute if you need
to exactly as if they were normally-addressed memory locations

	mov	ax,[tbp]
	mov	[tbp],ax

are both valid instructions which do what you would think whenever
the registers are set up in their default configuration (i.e. ss
is pointing to the tcb for the current partition and bp has the value
which was set by mossaver)

	tip	equ	(word ptr [bp+0])
	tcs	equ	(word ptr [bp+2])
	tflag	equ	(word ptr [bp+4])
	tds	equ	(word ptr [bp+6])
	tes	equ	(word ptr [bp+8])
	tdi	equ	(word ptr [bp+10])
	tsi	equ	(word ptr [bp+12])
	tbp	equ	(word ptr [bp+14])
	; word ptr [bp+16] reserved
	tbx	equ	(word ptr [bp+18])
	tbl	equ	(byte ptr [bp+18])
	tbh	equ	(byte ptr [bp+19])
	tdx	equ	(word ptr [bp+20])
	tdl	equ	(byte ptr [bp+20])
	tdh	equ	(byte ptr [bp+21])
	tcx	equ	(word ptr [bp+22])
	tcl	equ	(byte ptr [bp+22])
	tch	equ	(byte ptr [bp+23])
	tax	equ	(word ptr [bp+24])
	tal	equ	(byte ptr [bp+24])
	tah	equ	(byte ptr [bp+25])
	tstack	equ	(dword ptr [bp+26])
	tsp	equ	(word ptr [bp+26])
	tss	equ	(word ptr [bp+28])
	; word ptr [bp+30] reserved

=======================================================================

jrb 02/24/86	segmentation changes so code is romable

jrb 10/05/86	added call to suspend after chkirq and dopoll so all 
		the other tasks have a chance whenever any system 
		call is made

jrb 10/06/86	signal non-keyboard status call in mossaver
		(if it is keyboard status, that function will take 
		care of changing it)

jsm 08/20/87	added patch space to dopoll routine to help fix 
		vidram/wordperfect problems in the future.

jsm 08/24/87	fixed problem in dopoll routine by performing signed 
		comparisons on vidram timers.

mjs 9/21/87	modfied chkirq to track which irqs of the set irq2
		through irq7 have intercepts

sah 10/12/87	added calls to turn on or off ega io protection.
		included calls to egaon and egaoff.

sah 10/20/87	added tick check for demo version of pc-mos/386

mjs 12/1/87	if can't enter TSL because the re-entrance control flag
		intsl is set, call getkeys.

sah 12/03/87	added code to inc scbinmos during mossaver, dec (if not
		0) scbinmos during mosrestore for sidekick support

sah/mjs 12/09/87 place mov ds,[scbseg] at front on mosrestore since
		ds was not group during mosint17.  this will fix the
		more general case.

sah 01/20/88	change scbseg and zero seg access to mgetxxx macros

sah/rbr 02/20/88 move ddt segment to mo2 group

rbr 02/29/88	move intsl, irqwflag to grp.

sah 03/06/88	made changes for sk(+) "Thanks to some insight from ROD
		and techinical information which i have"   Change
		how scbinmos works (should have 2 values only	0 = not
		busy,	1 = busy.

sah 05/20/88	my 03/06/88 was incorrect. after running a test program
		on dos, indos flag is actual increment and decrement.
		to give a consistent and easy changable interface to
		to scbinmos i implement the following routines
			decinmos - decrements inmos flag is not zero
			incinmos - increments inmos flag
			rstinmos - reset inmos flag
			testinmos - test to make sure not internal call
				    use internally by dec and incinmos

mjs 6/10/88	added a test in mossaver to skip call to tsl if
		scbnoswt is set.  when e78 would call int16 during its
		int8 handler, tsl was being entered.  since we no longer
		control when an apps int8 handler gets control, the
		mapping state of the disk logic was not secure.  by
		skipping the tsl call in mossaver when scbnoswt != 0
		we keep ourselves from shooting ourselves in the foot.

mjs 7/2/88	removed a call to switchif in mosrestore.  when
		mosrestore gets called during an int8 intercept (or,
		theoretically, during an int9 intercept) this switchif
		call can upset any special mapping that might be in
		place (e.g. pamswitching).

mjs 7/13/88	modified chkirq to to grab_back for int8.  this is to
		support the re-grab logic which must be used to
		maintain control when the lidt scheme is not available.

mjs 7/14/88	removed last remnant of the old chain table logic scheme
		since int9 is being converted to lidt/regrab control.
		also, cleaned out dead code.

mjs 7/22/88	added logic to support regrab control of int9.

sah 08/10/88	remove test for tah = 86h (obsolete fun86)

sah 09/28/88	set tcbega flag, not to ega-pamswitch during getkeys.
		only should be allowed during tsl.

sah 10/05/88	move inmos handling to new mosint28 module so that all
		of tsr releated operations will be located in one
		module.

sah 11/30/88	use independed timer (scbtimer) instead of 40:6ch for
		time check during dopoll.  if someone plays with bios
		timer area, poll routines might not get call. before
		this poll routines would never get called if mos wasn't
		doing anything.

sah 01/12/89	added a call to userpoll for mouse implementation if not
		called from int 8 handler.

sah 03/23/89	remove test code which should have not been place in
		here when i implemented automatic stack biasing.

sah 05/31/89	remove skippoll flag test which is no longer needed
		because of changes in mosnxtsk for user polling

bwr 11/29/89	marked messages for foreign language translation.

sah 01/10/90	made demo code always be include and patch it out if
		demo version version is not intended to be use. see
		mosinit2

mjs 03/07/90	added regrab support for int13 to chkirq (for the int15 
		disk busy task switching feature)

mjs 03/22/90	modified the int13 regrab logic so its inactive 
		when disksw=n is used and so its only called once
		per task.

mjs 05/09/90	modified chkirq logic to handle case where app asserts
		the same irq vector twice in a row.  skplus was 
		confusing the linked list logic for the automatic
		irq reservation scheme.

mjs 05/17/90	completely rewrote the chkirq logic.  it no longer
		parses through the entire irq segment list.  this was
		wasteful since only 15 of the 40 entries in this
		segment needed special handling.  chkirq now contains
		discrete logic for each group of vectors which need
		attention.  refer the description of an irq entry within
		this module to see which two fields are now abandoned.

mjs 05/22/90	modify chkirq to skip processing until scbinit != 0

sah 06/29/90	corrected oversight in demo logic, scbdemo value should have
		been scbsdemo 

mjs 07/17/90	added calls to grab_back for int8 and int9 from within
		chkirq.  this was forgotten in my last overhaul of
		this function.

mjs 12/10/90	added call to grab_back for int13 - also forgotten in 
		my last overhaul of this function.

mjs 03/28/91	made mossaver skip the tsl call when tcbd40f is set.
		this flag must only be tested and reset by the 
		suspend call made from the function 0f (func 07) logic.
		(llnetbios)

================ 5.01 Kernel Ends Here ====================================

mjs 08/18/92	clean up segment declarations

======================================================================^

.xlist
	include mossaver.pub
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

gdata	segment
	extrn	intsl:byte,irqwflag:byte
gdata	ends

demoout equ	65520		; 60*60*18.2 or 60 minutes

irq	segment
	extrn	irqstart:byte, irqend:byte

; irq table entries are specified as:  (fictitious values used for example)
;
;i09num dw	09h*4	; segment 0 offset of interrupt (0ffffh ends table)
;i09old dd	?	; storage for original boot value (the initialization
;			;   code will save the value put in the interrupt table
;			;   during boot - you just need to reserve the space in
;			;   your module)
;i09ofs dw	0	; abandoned
;i09h1	dw	grp:dokbint1 ; offset in mos segment of first level irq handler
;			;   (mos initialization will set the interrupt vector
;			;   to this value)
;i09h2	dw	0	; abandoned

irq	ends

poll	segment
	extrn	pollstart:byte, pollend:byte

;subr	dw	?	; mos segment offset of subroutine to call
;			;   (0ffffh = end of list)
;nxttmr dw	?	; if tmrofs = 0 then next time to call subroutine
;			;    nxttmr = 0 for subroutine inactive or
;			;    nxttmr <> 0 to call the subroutine when the
;			;      current timer >= nxttmr
;tmrofs dw	?	; offset in tcb of word containing next time to call
;			;   subroutine for the tcb partition - word is defined
;			;   like nxttmr, but refers to that partition only
;			;   (see below)

poll	ends

;======================================================== mos segment
if 0 eq 0
segment_num = 1
endif
mosseg	segment
	assume	cs:mos,ds:grp,es:nothing,ss:tcb
	public	$$$saver
$$$saver label	byte

	extrn	mosend:byte, sbios:word, suspend:near, tsl:near, 
	extrn	switchif:near, userpoll:near, regrab13_data:byte
	extrn	egaon:near, egaoff:near, regrab9_data:near
	extrn	getkeys:near, regrab8_data:byte, grab_back:near
	extrn	dtimeout:byte,mosdemo:byte,mosdemo1:byte
	extrn	lidt0a:near, lidt0b:near, lidt0c:near, lidt0d:near
	extrn	lidt0e:near, lidt0f:near, regrsec0a:near, regrsec0b:near
	extrn	regrsec0c:near, regrsec0d:near, regrsec0e:near
	extrn	regrsec0f:near, mosint70:near, mosint71:near, mosint72:near
	extrn	mosint73:near, mosint74:near, mosint75:near, mosint76:near
	extrn	mosint77:near, mos2nd70:near, mos2nd71:near, mos2nd72:near
	extrn	mos2nd73:near, mos2nd74:near, mos2nd75:near, mos2nd76:near
	extrn	mos2nd77:near, mosint06:near, lidtst_af:near


	public	mossaver, mosrestore, chkirq, dopoll

	subttl	mossaver - save anything necessary including regs and return
	page
;======================================================================
;,fs
; mossaver - save anything necessary including regs and return
;
; mossaver assumes that a call to mossaver is the first 
; instruction in the calling int xxh handler, i.e. that 
; cs = mos, that interrupts are disabled, that no registers 
; have been changed and that there has been nothing pushed
; on the stack before the call
;
; in:	entry registers
;
; out:	entry registers available on stack through bp reference
;	ss:sp -> tcb stack
;	ds -> grp
;
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:nothing
mossaver:
	sti
	cld
	push	bp			; [bp+4]
	push	ds			; [bp+2]
	push	es			; [bp]
	mov	bp,sp
	mgetscb ds
	assume	ds:grp
	push	ax
	mov	ax,ss
	mov	es,ax
	cmp	ax,[scbtcbpc]
	pop	ax
	je	mossv1			;already executing with stack in tcb
	cli
	mov	ss,[scbtcbpc]
	assume	ss:tcb
	mov	sp,[tcbstkp]
	sti
	assume	ds:nothing
mossv1:
	push	[tcbtpfrm]
	push	es			; old ss
	push	bp			; old sp
	mov	bp,es:[bp+4]		; restore old bp
	push	ax			;\
	push	cx			; \
	push	dx			;  \
	push	bx			;   \  emulating 286 pusha instruction
	mov	bx,sp			;    /
	push	bx			;      (push same sp as 286 would have
					;      so pop is inverse)
	push	bp			;  /
	push	si			; /
	push	di			;/
	mov	bp,sp
	sub	bp,10			;leave room for es, ds, flags, cs, ip
					;  (bp now set up as "standard")
	cmp	[tcbnest],1		; when at nest level 0, update tcbtpfrm to
	jne	keeptpfrm		; hold bp's value to allow TOINT24 to address
	mov	[tcbtpfrm],bp		; the user's registers
keeptpfrm:
	mov	ax,ss			; sah ax <--- tcb
	call	egaoff			; sah turn off ega io protection (if so)

; start of demo additions

	public patdemo2
patdemo2 label	near
	jmp	short skipchk		; note replace with 2 nop if demo
	push	es
	mov	ax,cs			; replace increment counter code
	mov	es,ax			; we just change it write back
	lea	di,mosdemo
	cld
	mov	al,0ffh 		; inc [scbdemo]
	stosb
	mov	al,06h
	stosb
	lea	ax,scbdemo
	stosw
	mov	byte ptr cs:[mosdemo1],1eh  ; make sure that push is there
	mgetscb  es
	assume	es:grp
	cmp	[scbdemo2],0		; second counter past
	jne	gotyou			; if so...force time out
	mov	ax,[scbdemo]		; get demo counter
	cmp	ax,[scbsdemo]		; test it against old value
	jb	gotyou
	mov	[scbsdemo],ax		; save the new counter (was scbdemo)
	cmp	ax, demoout
	jb	notyet
gotyou:
	cmp	[scbinsave],'N' 	; are we inside critical time out
	jne	notyet			; yes...so skip this stuff
	mov	[scbinsave],'Y' 	; indicate inside handler
	cmp	word ptr [scbcin24],0	; special handler installed
	je	mosbye
	mov	ah,0feh
	mov	bx,cs
	lea	dx,dtimeout
	pushf
	call	[scbcin24]		; call command processor
mosbye:
	cli				; hard lock the system
	jmp	$
notyet:
	pop	es
skipchk:
	lds	si,[tstack]		;application ss:sp -> es|ds|bp|mossaver ret|
	assume	ds:nothing		;  ip|cs|flags
	push	[si]			;old es
	push	[si+2]			;old ds
	push	[si+12] 		;flags from application int xxh
	push	[si+10] 		;cs from application int xxh
	push	[si+8]			;ip from application int xxh
	push	[si+6]			;return address from call mossaver to new stack
	add	word ptr [tstack],14	;throw away the stuff we've transferred
	mgetscb ds
	assume	ds:grp
	call	userpoll		; call user poll routine
	cmp	[tcbfsavr],'O'
	ja	shortsavr		; y means use short form (mosint16 function 1)
	je	notsla			; o means use real short form
	mov	ax,ss
	cmp	ax,[tss]
	je	shortsavr		; don't bother if we're in control
	call	chkirq
shortsavr:				; enter here if tcbfsavr is set
	cmp	[scbinirq],0		; currently in a serial irq handler?
	jne	notsla			; if yes, skip tsl call
	cmp	[scbnoswt],0		; mjs 6/8/88
	jne	callkeys		; mjs 6/9/88
	cmp	[intsl],0
	jne	callkeys
	cmp	[tcbd40f],1		; when intd4fun0f calls mossaver
	je	callkeys		; don't call tsl here
	call	tsl
	jmp	notsla
callkeys:
	or	[tcbega],2		; pamswitching not allow
	call	getkeys
notsla:
	ret

	subttl	mosrestore - restore all registers and return
	page
;======================================================================
;,fs
; mosrestore - restore all registers and return
;
; mosrestore assumes that the caller is going to do an iret 
; immediately following the return from mosrestore, i.e. that 
; no registers are going to be changed before an iret is executed 
; back to the original int xxh caller
;
; in:	ss:sp -> tcb stack
;
; out:	original stack re-instated
;	registers restored from stack image
;
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:tcb
mosrestore:
	mgetscb ds			; sah/mjs make sure ds is group
	assume	ds:grp
	sub	word ptr [tstack],12	;room for ax, bx, return, ip, cs, flags
	mov	ax,ss			; sah ax <--- tcb
	call	egaon			; sah turn ega on (if so)
	cli				; sah don't allow to be broke in here
	lds	si,[tstack]
	assume	ds:nothing
	mov	ax,[tax]		;move old ax and bx to new stack so we
	mov	[si],ax 		;  can use them here (see below)
	mov	ax,[tbx]
	mov	[si+2],ax
	pop	[si+4]			;mosrestore return onto application stack
	pop	[si+6]			;restore ip, cs, flags to other stack in
	pop	[si+8]			;  case int xxh changed any of them
	pop	[si+10]
	pop	ds
	pop	es
	pop	di			;\
	pop	si			; \
	pop	bp			;  \
	pop	sp			;   \	emulating 286 popa instruction
	pop	bx			;   /	(and assume that pop sp is inverse of push sp)
	pop	dx			;  /
	pop	cx			; /
	pop	ax			;/
	pop	ax			;old sp
	pop	bx			;old ss
	pop	[tcbtpfrm]
	mov	ss,bx
	assume	ss:nothing
	mov	sp,ax
	sti
	pop	ax
	pop	bx
	ret

; vectors for irq2 through 7 are in a group because they must be processed
; for automatic irq reservations even if lidt support is being used.

iqlist1 label word
	dw	0ah*4,tcbapv0a,mos:lidt0a,mos:regrsec0a	; irq2
	dw	0bh*4,tcbapv0b,mos:lidt0b,mos:regrsec0b	; irq3
	dw	0ch*4,tcbapv0c,mos:lidt0c,mos:regrsec0c	; irq4
	dw	0dh*4,tcbapv0d,mos:lidt0d,mos:regrsec0d	; irq5
	dw	0eh*4,tcbapv0e,mos:lidt0e,mos:regrsec0e	; irq6
	dw	0fh*4,tcbapv0f,mos:lidt0f,mos:regrsec0f	; irq7
iql1_max equ	(($-iqlist1)/4)-2

; these vectors are processed for 1 level regrab

iqlist2 label word
	dw	70h*4,tcbapv70,mos:mosint70,mos:mos2nd70
	dw	71h*4,tcbapv71,mos:mosint71,mos:mos2nd71
	dw	72h*4,tcbapv72,mos:mosint72,mos:mos2nd72
	dw	73h*4,tcbapv73,mos:mosint73,mos:mos2nd73
	dw	75h*4,tcbapv75,mos:mosint75,mos:mos2nd75
	dw	76h*4,tcbapv76,mos:mosint76,mos:mos2nd76
	dw	77h*4,tcbapv77,mos:mosint77,mos:mos2nd77
iql2_max equ	(($-iqlist2)/4)-2


; int74 is managed by lidt logic when lidt support is available

iqlist3 label word
	dw	74h*4,tcbapv74,mos:mosint74,mos:mos2nd74
iql3_max equ	(($-iqlist3)/4)-2


; structure for referencing iqlist data

iqlist_strc struc
iql_0ofs dw	?			; offset of vector in 0:0 table
iql_tcb	 dw	?			; offset of tcb save var
iql_pri	 dw	?			; offset of primary handler
iql_sec	 dw	?			; offset of secondary handler
iqlist_strc ends

	subttl chkirq - check/fix interrupt vectors
	page
;======================================================================
;,fs
; chkirq - check/fix interrupt vectors
;
; monitor select interrupt vectors for changes and assert
; appropriate responses.
;
; in:	ds -> grp
;	ss -> tcb
;
; out:
;
;,fe
;======================================================================
	assume	ds:grp,es:nothing,ss:tcb
chkirq:
	cmp	[scbinit],0		; done with init?
	jne	$+3			; yes
	ret				; no, do not change any vectors
	pushset	bp,es
	xor	ax,ax
	mov	es,ax
	cli
	cmp	[scbi15tsl],'Y'		; only regrab int13 if no disksw=n
	jne	chkq1a
	cmp	[tcb13once],0		; only regrab int13 once per task
	jne	chkq1a
	mov	al,[tcbnest13]
	mov	bx,offset regrab13_data ; regrab int13
	call	grab_back
	cmp	al,[tcbnest13]
	jne	chkq1a
	mov	[tcb13once],1
chkq1a:
	test	[scbmmfea],04h		; lidt support?
	jnz	chq16
	mov	bx,offset regrab8_data	; if not, regrab int8 and int9
	call	grab_back
	mov	bx,offset regrab9_data
	call	grab_back
chq16:
	mov	di,es:[06h*4]
	mov	ax,es:[06h*4+2]		; always regrab int6
	mov	bp,offset mosint06
	mov	cx,cs
	call	cmp_dword
	jz	chq1
	mov	es:[06h*4],bp
	mov	es:[06*4+2],cx
chq1:
	sti

; check irq2 through 7 for auto reservations.  note: this is done 
; regardless of whether lidt management is used for these irq's

	xor	bx,bx			; init word index
	mov	dl,1			; init bit mask for tcbirqsec
	mov	dh, not 1		; init inverted bit mask
	mov	si,offset iqlist1
chq2:
	cmp	[scbirqd0a+bx],irq_no_res  ; if at no_res or auto_res
	je	chq6
	cmp	[scbirqd0a+bx],irq_auto_res
	ljne	chq4
chq6:
	cmp	[scbidq2+bx],-1		; skip if device driver has it
	lje	chq4
	cli
	mov	di,cs:[si].iql_0ofs	; get vector offset in 0:0 table
	mov	ax,es:[di+2]		; segment in ax
	mov	di,es:[di]		; offset in di
	mov	bp,cs:[si].iql_pri	; reference offset in bp
	test	[scbmmfea],4
	jz	chq6a
	mov	bp,offset lidtst_af	; use this for lidt management
chq6a:
	mov	cx,cs			; reference segment in cx
	test	[tcbirqsec],dl		; if not in secondary state
	ljnz	chq5
	call	cmp_dword		; but vector not at primary level
	lje	chq7
	or	[tcbirqsec],dl		; set bit in tcbirqsec
	and	[irqwflag],dh		; clear bit in irqwflag
	mov	[scbirqd0a+bx],irq_auto_res  ; set reservation status

; before linking a new task into the list, must make sure its not already
; in the list.  skplus has a habit of re-asserting the same irq4 vector 
; more than once.

	push	es
	mov	ax,[scbirqpf+bx]
	mov	cx,ss
	cmp	ax,cx			; if current == root, get out
	je	chq14
	mov	ax,ss
	mov	es,ax
chq13:
	assume	es:tcb,ss:nothing	; parse through the list
	mov	ax,[tcbirqpn+bx]
	or	ax,ax			; if end of list, ok to insert ss
	jz	chq15
	cmp	ax,cx			; if already linked, get out
	je	chq14
	mov	es,ax			; advance to next list entry
	jmp	short chq13
chq14:
	pop	es
	jmp	chq7
chq15:
	assume	es:nothing,ss:tcb
	pop	es
	mov	ax,[scbirqpf+bx]	; link the current task into the 
	mov	[tcbirqpn+bx],ax	; list of tasks which have 
	mov	[scbirqpf+bx],ss	; intercepts for this irq
	jmp	chq7
chq5:					; if in secondary state
	call	cmp_dword		; and vector at primary level
	jne	chq7
	and	[tcbirqsec],dh		; clear bit in tcbirqsec
	push	dx			
	push	es			; trace the linked list of tasks
	mov	dx,ss			; which have intercepts for this
	xor	cx,cx			; irq and unlink the current task
	mov	ax,word ptr [scbirqpf+bx]
chq8:
	cmp	ax,dx
	je	chq9
	mov	es,ax
	mov	cx,ax
	assume	es:tcb,ss:nothing
	mov	ax,word ptr [tcbirqpn+bx]
	or	ax,ax
	jnz	chq8
	call	bugerror		; it was supposed to be in the list
	db	'59 '
	db	'Invalid IRQ list   ',00h  ;@@xlat
chq9:
	assume	es:nothing,ss:tcb
	mov	ax,word ptr [tcbirqpn+bx]
	jcxz	chq10			; if cx == 0, unlink at root pointer
	mov	es,cx
	assume	es:tcb,ss:nothing	; else, unlink later list element
	mov	word ptr [tcbirqpn+bx],ax
	assume	es:nothing,ss:tcb
	jmp	short chq12
chq10:
	mov	word ptr [scbirqpf+bx],ax
chq12:
	pop	es
	pop	dx
	cmp	word ptr [scbirqpf+bx],0	; if the list is empty
	jne	chq7
	mov	[scbirqd0a+bx],irq_no_res	; cancel auto reservation
chq7:
	sti
chq4:
	rol	dl,1			; update bit mask for setting
	rol	dh,1			; update bit mask for clearing
	add	si,8			; update table index
	cmp	bx,iql1_max		; if not at end
	je	chq3
	add	bx,2			; update word index
	jmp 	chq2
chq3:

; if non-lidt, check/fix irq2 through 7 and irq12 (int74) for changes

	test	[scbmmfea],4
	jnz	chq11
	mov	si,offset iqlist1	; check/fix irq2 through 7
	mov	dx,iql1_max
	call	check_fix
	mov	si,offset iqlist3	; check/fix irq12
	mov	dx,iql3_max
	call	check_fix
chq11:

; always check/fix irq8 through 11 and irq13 through 15

	mov	si,offset iqlist2
	mov	dx,iql2_max
	call	check_fix
	popset	bp,es
	ret

	subttl cmp_dword - compare two doublewords
	page
;======================================================================
;,fs
; cmp_dword - compare two doublewords
;
; compare ax:di with cx:bp for ==/!=
;
; in:	ax:di = 1st doubleword
;	cx:bp = 2nd doubleword
;
; out:	zr if equal, else nz
;
;,fe
;======================================================================
	assume	ds:grp,es:nothing,ss:nothing
cmp_dword:
	cmp	di,bp			; compare the offsets
	jne	cdw1
	cmp	ax,cx			; then the segs
cdw1:
	ret

	subttl check_fix - helper for chkirq
	page
;======================================================================
;,fs
; check_fix - helper for chkirq
;
; if vector has changed, copy into the tcb variable and
; assert mos's secondary vector
;
; in:	si -> list entry
;	dx = index value for last entry
;	es = 0
;
; out:
;
;,fe
;======================================================================
	assume	ds:grp,es:nothing,ss:tcb
check_fix:
	xor	bx,bx			; init word index
	mov	cx,cs
chf1:
	mov	di,cs:[si].iql_0ofs	; get offset of vector in 0:0 table
	cli
	mov	ax,es:[di]
	cmp	cx,es:[di+2]		; if segments don't match
	je	chf3
	push	bp
	mov	bp,cs:[si].iql_tcb	; copy new vector to tcb var
	mov	[bp],ax
	mov	ax,es:[di+2]
	mov	[bp+2],ax
	pop	bp
	mov	ax,cs:[si].iql_sec
	mov	es:[di],ax
	mov	es:[di+2],cx
	jmp	short 	chf4
chf3:
	cmp	ax,cs:[si].iql_pri
	je	chf4
	cmp	ax,cs:[si].iql_sec
	je	chf4
	sti
	call	bugerror
	db	'58  '
	db	'Invalid IRQ    ',00h	;@@xlat
chf4:
	sti
	add	si,8
	cmp	bx,dx
	je	chf2
	add	bx,2
	jmp 	chf1
chf2:
	ret

	subttl	dopoll - call any needed polled subroutines
	page
;======================================================================
;,fs
; dopoll - call any needed polled subroutines
;
; look through poll segment, for each table entry
; if subroutine address = 0ffffh then we're finished
; else if tmrofs = 0 then
;   if nxttmr = 0 then ignore the entry
;   else if nxttmr <= current timer low word then
;     set nxttmr = 0
;     call the subroutine
; else if tmrofs <> 0 then
;   if word at tmrofs offset in tcb = 0 then ignore the entry
;   else if word at tmrofs offset in tcb <= current timer low word then
;     set word at tmrofs offset in tcb = 0
;     call the subroutine
;
; in:	ds -> grp
;	ss -> tcb
;
; out:
;
;,fe
;======================================================================
	assume	ds:grp,es:nothing,ss:tcb
dopoll:
	push	ax
	push	bx
	push	cx
	push	dx
	push	si
	push	di
	push	es
	mov	cx,[scbtimer]		; sah use independent timer
	cmp	cx,[tcbptmr]
	je	dopoll4 		; no need to do it again if already this slice
	mov	[tcbptmr],cx
	mov	si,offset grp:pollstart
dopoll1:
	cmp	word ptr [si],0ffffh
	je	dopoll4 		; end of table flag
	mov	ax,ss			; construct pointer to appropriate poll timer
	mov	bx,[si+4]		;   value
	or	bx,bx
	jnz	dopoll2 		; tmrofs <> 0
	mov	ax,ds			; else using nxttmr
	lea	bx,[si+2]
dopoll2:
	mov	es,ax			; es:[bx] = timer value to call subroutine
	cmp	word ptr es:[bx],0
	je	dopoll3 		; 0 if turned off
	mov	ax,es:[bx]
	cmp	ax,cx
	je	dopoll2a		; it's time to do check
	jns	dopoll3 		; haven't reached the right time yet
	jmp	short dopoll2a		; jump around patch space
	db	18 dup (?)		; patch space for vidram problem
dopoll2a:
	mov	word ptr es:[bx],0
	push	si
	push	cx
	call	[si]
	pop	cx
	pop	si
dopoll3:
	add	si,6			; to next poll table entry
	cmp	si,offset grp:pollend
	jb	dopoll1
dopoll4:
	pop	es
	pop	di
	pop	si
	pop	dx
	pop	cx
	pop	bx
	pop	ax
	ret

mosseg	ends
	end

