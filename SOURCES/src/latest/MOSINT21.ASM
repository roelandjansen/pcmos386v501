	include page.inc
	title	mosint21 - interrupt 21h handler - mos function dispatcher

extrn	bugerror:near			; enable debug error reporting

comment ^==============================================================
		      development specification

 program name:	$$mos.com		 assigned to: jim bean
 module name:	mosint21		 assign date: 01/30/86
 entry points:	mosint21, mosint20	 completed:   02/12/86
 entry from:	anywhere
 entry method:	int 21h
 calls:		mossaver,mosfunxx
 purpose:	entry to mos function calls
 refer to:	?
 last update:	08/18/1992
========================================================================

this module is the entry to interrupts 21h and 20h.  it does the
following:

(1)  if entered at mosint20, moves zero to ah and jumps to
     mosint21.

(2)  calls mossaver to save registers and perform other required
     mos entry logic.

(3)  transfers control to the appropriate mosfunxx entry point,
     depending on the function code value in the ah regster.

==== management of int 23 call

logic was added to manage the issuing of int 23h when a control-c
code was detected.	a control-c can be detected in mosmiman, during
console i/o, or within mosint21, when the break flag is on.
since it is permitted for an int 23 handler to retain control,
returning, the int 23 can only be issued when not in a nested state
so no reliance is made on data in mos's internal stack.  For this
reason, the nest counter tcbnest was created.  note that the int 21
function calls which enter the mosint21 logic, but do not exit
directly (exec and terminate) include a counter-balancing decrement
of tcbnest.

=======================================================================

jrb 02/12/86	allows use of the "old-style" function request moving 
		the function number to cl ( <= 24h ) and performing a 
		near call to psp:5 which holds a far call to mosoldfn

		mosoldfn converts the near call followed by a far call 
		into an int a long call into an int call, then moves 
		cl to ah and checks to see that the function 
		number <= 24h then jumps to mosint21

jrb 02/12/86	after calling mossaver, mosint21 doesn't really know 
		what the reg's were, ah in particular, unless it reads 
		them from the tcb stack using bp

jrb 02/24/86	segmentation changes for romable code - code changes 
		to remove the need for local data (in mosoldfn)

jrb 04/24/86	changed segment class to 'data' from 'code' in 
		gdata, irq, poll

jrb 07/28/86	add irq seg entries and default handlers for int 23h 
		and 24h

dam 09/26/86	added int 27h entry point and handler

dam 10/09/86	added mosdebug calls using bits 1,2,3,4 and 5.
		bit 1 gives a register dump on entry to int 21h fun 0-c
		bit 2	"       "	"       "	int 21h fun d-30
		bit 3	"       "	"       "	int 21h fun 31+
		bit 4 pauses for input on entry to int 21h
		bit 5 pauses for input on exit from int 21h
		bit 6 do internal int 21s as well (not just application)
		bit 7 enables check for system input monitor (sim) hotkey

dam 11/04/86	changed 'do21debug' code to use task registers and our
		stack space.  also added bit 4 of al on call to mosdebug to use
		task registers and not current state.

jsm 12/15/86	added functions c4, get tcb address, and c5, delete
		task with given tcb.

dam 12/29/86	changed funtions cx to 8x to avoid novell conflicts

jsm 02/16/87	added functions 88 & 89

mjs 2/24/87	cooking mods - modified nondestructive call to check 
		for a cntrl-c when the break flag is on

jsm 03/16/87	expanded int 25 & 26 to 32-bit sector numbers
		for large volume support

jsm 04/02/87	added dummy functions 8a, 8b, 8c & alias (8d)

sah 06/10/87	change invalid function calls to return 00 in al instead
		of 01 software checking for novell networks are checking
		for 01

sah 07/12/87	remove function 80+ amd place them into mosint38 (which
		replaces mosfun80 module)

sah 09/13/87	added sidekick support by including a loop before int 21
		which does int 28 call follow by a non-destrunctive
    09/25/87	int 16 call.	this is what sidekick needs to wake up
    10/19/87	the actual method use in this module is the function is
		one that use the keyboard, non-destructive int 16 calls
		will be call so that int 28 will be called during int 16

sah 10/20/87	remove mosdebug support (optional done in options.inc)

sah 11/15/87	include uptinmos support for sidekick(+), new routine
		uptinmos

sah 12/03/87	remove uptinmos, move int 16h loop above mossaver call
		and only for function 01 - 0ch

mjs 12/8/87	remove loop in mosint21 which called mosint16.
		corrected bug with the way tcbbrkfg was tested for
		cntrl-c response.

sah 01/19/88	change scbseg and zero seg access to mgetxxx macros

sah 02/11/88	change inter segment calling to new conventions
rbr		added caller2 and removed mos1

rbr/sah 02/20/88 move ddt code to mo2 group.

jrb 05/02/88	minor changes to mosint25 and 26 for cacheing, rewrite
jrbr		of rdabs and wrabs for cacheing

mjs 5/18/88	corrected problem with mosint25 and mosint26 returning
		carry when an error occurs.

sah 05/20/88	my 03/06/88 was incorrect. after running a test program
		on dos, indos flag is actual increment and decrement.
		to give a consistent and easy changable interface to
		to scbinmos i implement the following routines
			decinmos - decrements inmos flag is not zero
			incinmos - increments inmod flag
		int 28 should only be issue during functions 01 to 0c,
		so tcbsafe28 has been created if you can do a int 28.
		all int 28 calls move out of int 16 and move into the
		console routines. see resident.doc for more information

mjs 7/2/88	added calls to noswitch/okswitch calls to int25 and
		int26.

sah 01/26/89	modifications to retf macro for masm5.10

rkg 04/20/89	delete 'closechk' checking close of spool file

sah 05/25/89	code added to handler function 50, 51, 62  on
		users stack, according to ms-papers book.

sah 07/06/89	added bias conditional assembly for stack biasing
		for use in internal debugging with periscope

sah 08/10/89	made sure that int 25h flushes and invalidates the bdb
		this was done to correct a problem with lotus 2.2
		init program for initializing serial # on disk.

mjs 10/10/89	modified sector size calculations.

bwr 11/29/89	marked messages for foreign language translation.

sah 11/30/89	remove function 06 from keyboard disable list
		see mosfun01 for details.

bwr 01/29/90	added dos functions through 68h for dos 3.30 compat.
		function 65: get extended country info
		function 66: get/set gloabl code page. (not supported)
		function 67: set handle count
		function 68: commit file

		note:  functions 65 and 66 are not yet supported.  mos 
		does not yet have code page support.  this should be 
		initiated as a separate project.

mjs 03/30/90	reset tcbconfg to default value of 1b just before the
		int21 function call is issued.

mjs 04/19/90	remove code added on 3/30 to reset tcbconfg.  found
		that this correction had to be made in mosfun01.asm

SAH 06/22/90	Corrections for setting TCB use MSetPsp macros

SAH 10/01/90	Remove function 80 check, Norton 5.0 depended on this

mjs 12/16/91	dlg mods: added function 6c to the i21 function table. 
		modified int25 and int26 for the dlg calling interface.
		modified int21 function table to account for transfer
		of the following functions from mosfun00 to mosfun39:
		mosfun58, 59, 65, 66, 67 and 68.

mjs 12/19/91	int25 and int26 no longer support the mlg calling 
		interface (where di == fffc means si holds the upper
		portion of the starting sector number).  this caused
		problems with sysinfo since it always had di == fffc
		and various values in si (not sector number values).

================ 5.01 Kernel Ends Here ====================================

mjs 08/18/92	clean up segment declarations

=======================================================================^

.xlist
;	include mosint21.pub
	include group.inc
	include options.inc
	include mosregs.inc
	include mosbdb.inc
	include macros.inc

tcb	segment at 1234h
	include mostcb.inc
tcb	ends

gdata	segment
	include mosscbex.inc
gdata	ends
.list

irq	segment

	dw	21h*4			; offset for this interrupt
	dd	?			; save prior value
	dw	0			; we don't save changes, we leave them alone
	dw	mos:mosint21		; initial value is here
	dw	0			; don't change back if application changes it

	dw	20h*4			; interrupt 20h
	dd	?			; see below
	dw	0
	dw	mos:mosint20
	dw	0

	dw	23h*4			; default interrupt 23h
	dd	?			; see above
	dw	0
	dw	mos:mosint23
	dw	0

	dw	24h*4			; default interrupt 24h
	dd	?			; see above
	dw	0
	dw	mos:mosint24
	dw	0

	dw	25h*4			; default interrupt 25h
	dd	?
	dw	0
	dw	mos:mosint25
	dw	0

	dw	26h*4			; default interrupt 26h
	dd	?
	dw	0
	dw	mos:mosint26
	dw	0

	dw	27h*4			; default interrupt 27h
	dd	?			; see above
	dw	0
	dw	mos:mosint27
	dw	0

irq	ends

;======================================================== ddt segment
if 0 eq 0
segment_num = 2
endif
ddt	segment
	extrn	m2retf:word
ddt	ends

;======================================================== mos segment
if 0 eq 0
segment_num = 1
endif
mosseg	segment
	assume	cs:mos,ds:grp,es:nothing,ss:tcb


	extrn	mossaver:near, mosrestore:near
	extrn	callcon:near, sbios:word, mo2seg:word, mo2fun:word
	extrn	findbdb:near, todriver:near, flushbdb:near, invbdb:near
	extrn	terminate:near, incinmos:near, decinmos:near
	extrn	rdbf:near, wrbf:near	;jrbr
	extrn	noswitch:near, okswitch:near


	public	mosoldfn		; for whoever uses it making a psp
	public	caller2,m1retf		; for intersegment calls

; define a word and define the near ptr value in the word as external

extvct	macro	fn
ifdif	<&fn>,<fr>			;; do not declare extrn if this is a far one
	extrn	mosfun&fn:near
endif
	dw	mos:mosfun&fn
	endm

extfar	macro	fn
ifidn	<&fn>,<fx>			;; no address or extrn if near routine
	dw	0
else
	extrn	mosfun&fn:near
	dw	mo2:mosfun&fn
endif
	endm

	subttl caller2 - inter-code-segment transfer
	page
;======================================================================
;,fs
; caller2 - inter-code-segment transfer
;
; in:	depends on what's being called
;
; out:	depends on call
;
; the following code is new method of inter-code-segment transfer of
; call mos 2nd code segment from mos  code segment.  to do this
; use the callmos2 macros:
; 	call	caller2
; 	dw	offset mos:routine
; 
; note: if mosaddr is a protected-mode selector, set its rpl to 3!
;
;,fe
;======================================================================

cal2off dw	offset mo2:m2retf

caller2 proc	near
	push	bx
	push	bp			; save original bp
	mov	bp,sp
	push	cs			; selector for final return
	mov	bx,[bp+4]		; address data word following the call
	inc	bx
	inc	bx
	push	bx			; set offset for final return
	push	cs:[cal2off]		; put mo2 near return address on stack
	push	cs:[mo2seg]		; push mo2 selector on stack
	push	cs:[bx-2]		; put offset of called rtn on stack
	mov	bx,[bp+2]		; recover original bx
	mov	bp,[bp]			; recover original bp
	retf				; retf enters called routine in mo2
caller2 endp

m1retf	label	near			; resume logic in mo2
	retf	6

;======================================================================
; mos function vector table.
; all vectors represented between 00h and 68h
;
; all must be defined externally (valid functions or not) in the form
; mosfunxx where xx is the function number in hex.
;
; if an invalid function, all you need do is a near return
;
; 03/04/87 dam	  the functions with 'fr' reside in a different segment
; and the routine 'mosfunfr' will see that they get to where they need
; to go.
;======================================================================
vct21	label	word
	irp	fn,<00,01,02,03,04,05,06,07,08,09,0a,0b,0c,0d,0e,fr>
	extvct	fn
	endm
	irp	fn,<fr,fr,fr,fr,fr,fr,fr,fr,18,19,fr,1b,1c,1d,1e,1f>
	extvct	fn
	endm
	irp	fn,<20,fr,fr,fr,fr,25,26,fr,fr,29,2a,2b,2c,2d,2e,fr>
	extvct	fn
	endm
	irp	fn,<30,31,32,33,34,35,36,37,38,fr,fr,fr,fr,fr,fr,fr>
	extvct	fn
	endm
	irp	fn,<fr,fr,fr,fr,fr,fr,fr,fr,48,49,4a,4b,4c,4d,fr,fr>
	extvct	fn
	endm
	irp	fn,<xx,xx,52,53,54,55,fr,fr,fr,fr,fr,fr,fr,5d,5e,5f>
	extvct	fn
	endm
	irp	fn,<60,61,xx,63,xx,fr,fr,fr,fr,xx,xx,xx,fr>
	extvct	fn
	endm
lnvct21 equ	$-vct21

far21	label	word
	irp	fn,<fx,fx,fx,fx,fx,fx,fx,fx,fx,fx,fx,fx,fx,fx,fx,0f>
	extfar	fn
	endm
	irp	fn,<10,11,12,13,14,15,16,17,fx,fx,1a,fx,fx,fx,fx,fx>
	extfar	fn
	endm
	irp	fn,<fx,21,22,23,24,fx,fx,27,28,fx,fx,fx,fx,fx,fx,2f>
	extfar	fn
	endm
	irp	fn,<fx,fx,fx,fx,fx,fx,fx,fx,fx,39,3a,3b,3c,3d,3e,3f>
	extfar	fn
	endm
	irp	fn,<40,41,42,43,44,45,46,47,fx,fx,fx,fx,fx,fx,4e,4f>
	extfar	fn
	endm
	irp	fn,<fx,fx,fx,fx,fx,fx,56,57,58,59,5a,5b,5c,fx,fx,fx>
	extfar	fn
	endm
	irp	fn,<fx,fx,fx,fx,fx,65,66,67,68,fx,fx,fx,6c>>
	extfar	fn
	endm

	assume	ds:nothing,ss:nothing

	subttl mosoldfn - entry for "old-style" calls
	page
;======================================================================
;,fs
; mosoldfn - entry for "old-style" calls
;
; in:	depends on what's being called
;
; out:	depends on call
;
; this is the entry for an "old-style" call to mos functions
; an application may put a mos function number from 00h to 24h into
; cl and do a near call to psp:5
; 
;,fe
;======================================================================
mosoldfn:
	push	bp			; stack is bp, trash, cs, ip
	mov	bp,sp			; we want it to be ip, cs, flags
	pushf
	pop	ax
	xchg	ax,[bp+6]		; setting flags
	mov	[bp+2],ax		; setting ip
	pop	bp
	mov	ah,cl
	cmp	ah,24h
	cli
	ja	mosoldx
	jmp	mosint21
mosoldx:
	iret				; invalid function for this method

	subttl mosint23 - default int23 handler
	page
;======================================================================
;,fs
; mosint23 - default int23 handler
;
; in:	
;
; out:	
;
;,fe
;======================================================================
public	mosint23
mosint23:
	iret

	subttl mosint24 - default int24 handler
	page
;======================================================================
;,fs
; mosint24 - default int24 handler
;
; in:	per int24 spec
;
; out:	al = 3 to fail
;
;,fe
;======================================================================
public	mosint24
mosint24:
	mov	al,03h			; default int 24h returns fail code
	iret

	subttl	mosint25 - read absolute disk sectors
	page
;======================================================================
;,fs
; mosint25 - read absolute disk sectors
;
; in:	per int25 spec (both m5 and d4+)
;
; out:	per int25 spec
;
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:nothing
public	mosint25
mosint25:
	call	incinmos
	call	mossaver
	call	noswitch
	push	bp
	mov	cx,[tcx]		; using dlg interface?
	mov	es,[tds]
	mov	di,[tbx]
	cmp	cx,0ffffh
	jne	mosi25d
	mov	dx,es:[di]
	mov	si,es:[di+2]
	mov	cx,es:[di+4]
	les	di,es:[di+6]
	jmp	short mosi25e
mosi25d:
	xor	si,si
	mov	dx,[tdx]
mosi25e:
	mov	ax,[tax]
	call	rdabs
	mov	[tax],ax
	jc	mosi25a
	and	[tflag],not carry
	jmp	mosi25b
mosi25a:
	or	[tflag],carry
mosi25b:
	pop	bp
	call	okswitch
	call	mosrestore
	call	decinmos		; sah 05/23/88
	push	bp			; 5/18/88 mjs - need to get flags
	mov	bp,sp			; back to caller but keep on stack too
	mov	bp,[bp+6]
	push	bp
	popf
	pop	bp
	retf

	subttl	mosint26 - write absolute disk sectors
	page
;======================================================================
;,fs
; mosint26 - write absolute disk sectors
;
; in:	per int26 spec (both m5 and d4+)
;
; out:	per int26 spec
;
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:nothing
public	mosint26
mosint26:
	call	incinmos		;sah	05/23/88
	call	mossaver
	call	noswitch
	push	bp
	mov	cx,[tcx]		; using dlg interface?
	mov	es,[tds]
	mov	di,[tbx]
	cmp	cx,0ffffh
	jne	mosi26d
	mov	dx,es:[di]
	mov	si,es:[di+2]
	mov	cx,es:[di+4]
	les	di,es:[di+6]
	jmp	short mosi26e
mosi26d:
	xor	si,si
	mov	dx,[tdx]
mosi26e:
	mov	ax,[tax]
	call	wrabs
	mov	[tax],ax
	jc	mosi26a
	and	[tflag],not carry
	jmp	mosi26b
mosi26a:
	or	[tflag],carry
mosi26b:
	pop	bp
	call	okswitch
	call	mosrestore
	call	decinmos		; sah 05/23/88
	push	bp			; 5/18/88 mjs - need to get flags
	mov	bp,sp			; back to caller but keep on stack too
	mov	bp,[bp+6]
	push	bp
	popf
	pop	bp
	retf

	subttl	rdabs - read a sector from a block device into a buffer
	page
;======================================================================
;,fs
; rdabs - read a sector from a block device into a buffer
;
; in:	es:di = pointer to buffer into which to read
;	si:dx = sector number of sector to read
;	al = drive to read
;	cx = number of sectors to read
;
; out:	c if error
;	  ax = error code
;	nc if no error
;	  ax = undefined
;
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:tcb
lproc	rdabs

lstring startsect,<size sectorblk>

	mgetscb ds
	assume	ds:grp
	push	dx
	push	cx
	callmos2 findbdb
	pop	cx
	pop	dx
	mov	ax,1			; unknown unit
	jc	rdxx
	assume	ds:bdb

; the following code was necessory because of sloppy programing
; which was done inside lotus 2.2 init program.

	callmos2 flushbdb		; flush the bdb for this drive
	callmos2 invbdb			; invalidate cache for this drive

; normalize the buffer pointer if needed

	push	cx
	push	ax
	mov	ax,cx
	mov	cx,[bdbssiz]
	push	dx
	mul	cx
	pop	dx
	add	ax,di
	jnc	rdabs1
	mov	ax,di
	and	ax,0fh
	mov	cl,4
	shr	di,cl
	mov	cx,es
	add	cx,di
	mov	es,cx
	mov	di,ax
rdabs1:
	pop	ax
	pop	cx
	mov	[startsect].seclow,dx
	mov	[startsect].sechigh,si
	lea	bx,[startsect]

; no int 24h, reading data (can't have DATAX or no bits would 
; be set which caching regards as an empty uob - so we set dirx
; which is relatively innocuous)

	mov	dl,dirx and not allx	
	callmos2 rdbf
rdxx:

lundef	startsect

lendp	rdabs

	subttl	wrabs - write a sector to a block device from a buffer
	page
;======================================================================
;,fs
; wrabs - write a sector to a block device from a buffer
;
; in:	es:di = pointer to buffer into which to write
;	si:dx = sector number of sector to write
;	al = drive to write
;	cx = number of sectors to write
;
; out:	c if error
;	  ax = error code
;	nc if no error
;	  ax = undefined
;
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:tcb
lproc	wrabs

lstring startsect,<size sectorblk>

	mgetscb ds
	assume	ds:grp
	push	dx
	push	cx
	callmos2 findbdb
	pop	cx
	pop	dx
	mov	ax,1			; unknown unit
	jc	wrxx
	assume	ds:bdb

; normalize the buffer pointer if needed

	push	cx
	push	ax
	mov	ax,cx
	mov	cx,[bdbssiz]
	push	dx
	mul	cx
	pop	dx
	add	ax,di
	jnc	wrabs1
	mov	ax,di
	and	ax,0fh
	mov	cl,4
	shr	di,cl
	mov	cx,es
	add	cx,di
	mov	es,cx
	mov	di,ax
wrabs1:
	pop	ax
	pop	cx
	mov	[startsect].seclow,dx
	mov	[startsect].sechigh,si
	lea	bx,[startsect]

; no int 24h, writing data (can't have DATAX or no bits would be 
; set which caching regards as an empty uob - so we set dirx
; which is relatively innocuous)

	mov	dl,(dirx or wrx) and not allx  
	callmos2 wrbf
wrxx:

lundef	startsect

lendp	wrabs

	subttl	mosint27 - terminate and stay resident
	page
;======================================================================
;,fs
; mosint27 - terminate and stay resident
;
; in:	per int27 spec
;
; out:	per int27 spec
;
; int 27h default will calc the # para's to keep and transfer control
; to function 31h.
;
;,fe
;======================================================================
public	mosint27
	assume	ds:nothing,es:nothing,ss:nothing
mosint27:
	mov	bp,sp
	mov	ax,[bp+2]		; get callers cs
	mgetscb es			; get pointer to mos data
	mov	es,es:[scbtcbpc]	; get pointer to current tcb
	assume  es:tcb
	MSetPsp	ax			; set active psp to cs (to be sure)
	assume  es:nothing
	add	dx,0fh			; round up to next seg
	shr	dx,1			; calc # of para's to keep
	shr	dx,1
	shr	dx,1
	shr	dx,1
	mov	ax,3100h		; terminate, zero error code
	jmp	mosint21

	subttl mosint20 - terminate handler
	page
;======================================================================
;,fs
; mosint20 - terminate handler
;
; in:	cs -> psp
;
; out:	n/a
;
; an application may terminate by doing int 20h with cs pointing at the
; psp - this is exactly the same as terminating by setting ah = 00h and
; doing an int 21h with cs pointing at the psp - in fact, we just
; transform it to that and go to the int 21h logic
; 
; int 20h the same as int 21h function 0 jump so it still works if 
; someone sticks something between here and mosint21
;
;,fe
;======================================================================
public	mosint20
mosint20:
	mov	ah,00h
	jmp	mosint21

	subttl mosint21 - system services handler
	page
;======================================================================
;,fs
; mosint21 - system services handler
;
; in:	depends on call
;
; out:	depends on call
;
; an application performs some mos function by putting a function
; number in ah, setting various other registers depending upon the
; function and doing an int 21h which points here
; 
;,fe
;======================================================================
public	mosint21
mosint21:
	assume	ds:nothing, es:nothing
	push	ds			; on user's registers at this time
	mgetscb ds
	assume	ds:grp
	mov	ds,[scbtcbpc]		; gain addressability to mos data
	assume	ds:tcb
	cmp	ah,50h			; is this set psp call
	jne	notfun50
	MSetPsp bx			; set psp to value in bx
	jmp	short short21
notfun50:
	cmp	ah,62h
	je	dofun51			; is this get psp call (51 or 62)
	cmp	ah,51h
	jne	notfun51
dofun51:
	MGetPsp bx			; place psp in bx
short21:
	pop	ds
	iret
notfun51:
	call	incinmos		; sah 05/23/88
	inc	[tcbnest]		; increment counter for nest control
	pop	ds			; back on user's stack
	assume	ds:nothing,es:nothing
	call	mossaver
	assume	ds:grp,ss:tcb

if bias
	push	[tcbstkp]
	sub	word ptr [tcbstkp],bias
endif

	mov	ah,[tah]		; see if the function should cause the dis
	cld				;  mode counter to be reset
	lea	si,[kblist]
dis21a:
	lods	byte ptr cs:[si]
	or	al,al			; (will reset for func 0 since 0 is end of
	je	dis21c			; list marker)
	cmp	ah,al
	jne	dis21a			; if a match, don't reset tcbkbcnt
	jmp	dis21b

; note when adding new functions to int 21, consider whether it should be
; added to this list.  for example, fun 0b reads the status of the console,
; reporting if any keys are ready.  when fun 0b is called, we do not want to
; zero out the dis counter or disable mode would be defeated.  however, on
; calls which are not in this list, we do want to zero out tcbkbcnt in order
; to restart the count down for successive keyboard status polls.

; updated: 11/30/89 - note function 06 is now handled inside mosfun06, if
; function 06, and not reading keyboard then we will need to zero counter.
; so we will skip it here.

kblist	db	1,6,7,8,0ah,0bh,0ch,2ah,2ch,0

dis21c:
	mov	[tcbkbcnt],0		; if not in the ignore list, reset dis counter
dis21b:
	cmp	byte ptr [tcbnest],1	; at nest level 1 ?
	je	mos21k
	jmp	mos21b
mos21k:
	mov	si,sp			; save original user registers
	add	si,4			; in case of iret from int 23h
	lea	di,[tcbsreg]
	push	es
	push	ds
	push	ss
	push	ss
	pop	es
	pop	ds
	mov	cx,11
	cld
	rep	movsw
	pop	ds
	pop	es
	test	byte ptr [tcbbrkfg],2
	jnz	mos21b			; if nest counter = 1 and control-c
	cmp	byte ptr [tcbbrk],0	; checking is on and break in on and
	je	mos21b			; not (ah = 6 or 7) then
	mov	bl,[tah]		; check for a cont-c in the type
	cmp	bl,6			; ahead buffer
	je	mos21b
	cmp	bl,7
	je	mos21b
	mov	cx,1			; buffer address doesn't matter for #5
	mov	al,5
	callmos2 callcon		; is a key waiting?
	or	cx,cx
	jz	mos21b			; no key waiting
	cmp	al,3			; control-c?
	jne	mos21b
	lea	bx,[tcb%dbuf]		; use dbuf as a temporary buffer
	push	es
	push	ss
	pop	es
	mov	cx,1
	mov	al,4			; get the key out of the type ahead buffer
	callmos2 callcon
	pop	es
	mov	ax,[tcbstkp]		; since tcbnest counter = 1, tcbstkp should
	cmp	ax,offset tcbstack	; be set to the top of the tcb stack
	je	mos21f			; if not, ignore the control-c
mos21b:
	mov	bl,[tah]		; get function number from tcb stack using bp
	cmp	bl,0ch			; sah 05/23/88 only allow int 28 during
	ja	mos2128			; sah functions 01 to 0ch
	or	bl,bl			; sah
	jz	mos2128			; sah
	mov	[tcbsafe28],'Y'		; sah set flag to yes
mos2128:				; sah
	xor	bh,bh
	add	bx,bx
	cmp	bx,lnvct21
	jb	mos21h
	jmp	mos21i
mos21h:
	cmp	[vct21+bx],0
	je	mos21a			; also invalid
	call	[vct21+bx]		; call the function
	mov	[tcbsafe28],'N'		; sah 05/23/88 not safe to do int 28 anymore
	assume	ds:nothing		; sah don't make any assumptions on DS
mos21a:
	cmp	byte ptr [tcbnest],1
	jne	mos21d
	mov	al,[tcbbrkfg]
	and	al,3
	cmp	al,1			; is break bit set and override not?
	jne	mos21d
	mov	ax,[tcbstkp]		; since tcbnest counter = 1, tcbstkp should
	cmp	ax,offset tcbstack	; be set to the top of the tcb stack
	je	mos21f			; if not, ignore the control-c
mos21d:

if	bias
	pop	[tcbstkp]
endif

	call	mosrestore
	assume	ds:nothing,ss:nothing
	push	ds			; on user's registers at this time
	mgetscb ds
	assume	ds:grp
	mov	ds,[scbtcbpc]		; gain addressability to mos data
	assume	ds:tcb
	dec	[tcbnest]		; increment counter for nest control
	call	decinmos		; sah 05/23/88
	pop	ds			; back to user's regs
	assume	ds:nothing, es:nothing
	iret

;-----------------------------------------------------------------------
; this routine gets called for the functions that reside in the mo2
; group.  those routines are a far call from here.
;-----------------------------------------------------------------------

mosfunfr:
	assume	ds:grp
	mov	bx,[far21+bx]
	call	dword ptr [mo2fun]
	ret

	assume	ds:grp,ss:tcb
mos21f:
	mov	di,sp			; restore original user registers
	add	di,4			; in case of iret from int 23h
	lea	si,[tcbsreg]
	push	es
	push	ds
	push	ss
	push	ss
	pop	es
	pop	ds
	mov	cx,11
	cld
	rep	movsw
	pop	ds
	pop	es

if	bias
	pop	[tcbstkp]
endif

	call	mosrestore
	assume	ds:nothing,ss:nothing
	push	ds			; on user's registers at this time
	mgetscb ds
	assume	ds:grp
	mov	ds,[scbtcbpc]		; gain addressability to mos data
	assume	ds:tcb
	mov	[tcborgsp],sp		; save sp for comparison
	sub	word ptr [tcborgsp],2
	dec	[tcbnest]		; increment counter for nest control
	and	byte ptr [tcbbrkfg],0feh; reset break flag
	pop	ds			; back to user's regs
	assume	ds:nothing, es:nothing
	clc
	int	23h			; process the cont-c, prepared for no return
	pushf
	push	ds			; on user's registers at this time
	mgetscb ds
	assume	ds:grp
	mov	ds,[scbtcbpc]		; gain addressability to mos data
	assume	ds:tcb
	cmp	[tcborgsp],sp		; jump if returned via a far return
	jne	mos21e
	pop	ds
	popf
	jmp	mosint21		; restart the function call
mos21e:
	pop	ds
	popf
	jnc	mos21g
	mov	ax,0100h		; no, error, ctrl-c terminate
	jmp	terminate		; if cy, terminate
mos21g:
	add	sp,2			; compensate stack for far return
	jmp	mosint21		; restart the function call
mos21i:					; temporary range code to detect for 80 bugs
	mov	[tal],0			; invalid function code
	and	[tflag],not carry
	jmp	mos21a

mosseg	ends
	end

