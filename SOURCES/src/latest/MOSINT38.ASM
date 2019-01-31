	include	page.inc
	title	mosint38.asm - mos special function calls
extrn	bugerror:near		; bug detection (used in 8c)
comment ^==============================================================
		       development specification

 program name:	$$mos.com		assigned to: david morrow
 module name:	mosint38		assign date: 10/27/86
 entry points:	mosext00-mosext??	completed:
 entry from:	mosint38 (this module)
 entry method:	call
 calls: 	mosliman, mositask
 purpose:	extended function calls.
 last update:	08/18/1992
========================================================================

this module handles function calls needed for mos that do not have
a pc-dos equivalent.	the following are indentified to date:

ah=00 - allocate and initialize a tcb from the heap.	this is
	  intended for use by the addtask command.  the tcb address
	  is returned in es.  carry flag and ax indicate errors.

ah=01 - call mositask to initiate the task indentified by the tcb
	  address in es.  carry flag and ax indicate errors.

ah=02 - return scb segment address

ah=03 - get/set creation data (10-byte area w/ class, userid,
	  date/time initially class)

ah=04 - find tcb whose id matches bx, return in es.  carry flag
	  and ax indicate errors.

ah=05 - delete task with tcb address in es.  carry flag and ax
	  indicate errors.

ah=06 - time wait an optional task deselection.  bx=# of timer ticks
	  this is used by the time slicing with a bx value of 1

ah=07 - wait for event.  waits for one of 4 types of events:
	  keystroke, timer ticks, hardware interrupt, serial port
	  status change.

ah=08 - copy information from one task's memory space to another's.

ah=09 - call a routine in another task's memory space.  Routine
	  returns via iret instruction.

ah=0a - int 21h call to interface with mosheman. use a similar
	  calling interface.

ah=0b - add/remove a device on the fly.

ah=0c - change current task's memory size

ah=0d - get, set, or delete alias for drive

ah=0e - set task's priority

ah=0f - reserved internally for mos for later use

ah=14 - set up printer

ah=15 - announce process termination

ah=16 - set/reset scbidq field for device driver

ah=17 - declare 286 code\data segment, undeclare segment

ah=18 - flush cache for drive and invalidate cache for drive

**** api functions

ah=19 - return current tcbid

ah=1a - read\set\exchange priority

ah=1b - read\set\exchange slice

ah=1c - clear\set\read keyboard status

ah=1d - return pointer to program name

ah=1e - return pointer to user name and class

ah=1f - return partition size information

ah=20 - return port and baud information

ah=21 - remove a task

ah=22 - add a task

ah=23 - change ddt on the fly

ah=24 - return serial #

ah=25 - is cs in system memory pool

ah=26 - get scb address selector

ah=27 - get tcb address selector

ah=28 - read control block data with selector

ah=29 - write control block data with selector

ah=2a - exchange control block data with selector

ah=2b - set spooler time out value (custumer needs this one)

ah=2c - get\set spooler parameters

ah=2d - return maximun task size

ah=2e - check partition security access	

ah=2f - check class security access

ah=30 - Set/Clear ALT-999 mode. (For ALT-ASCII key entry)

====================================================================

jsm 12/15/86	added functions 84 & 85

dam 12/29/86	changed all cx function references to 8x
		(for those interested the cx range conflicts with novell)

dam 1/05/87	added function 86 (only for slicing though)

dam 1/20/87	changed fun 81 to return errors and % heap in bx

mjs 1/26/87	mod fun 81 to copy startup batch string into local
		storage and pass in ds:si to mositask

jsm 01/30/87	added function 87

jsm 02/12/87	added functions 88 & 89

jsm 03/17/87	updated funtion 83 for large volume support

sah 04/06/87	added function 8c for resizing partition size

bmw 05/16/87	added functions 8a & 8b

sah 07/10/87	converted function 80+ into to interupt 38 00+

sah 07/15/87	corrected problem with 0c error handling

jsm 08/11/87	allow replacement of drives a or b by an alias drive
		 from function 0dh.

sah 08/13/87	added vtype of 0 precheck in function 0c and not allow
		 mos resize above a000h

jsm 10/06/87	put in stubs for functions 0f, and 14.	added function
		15, announce process termination.

sah 10/20/87	remove mosdebug support (optionally in options.inc)

sah 11/15/87	inmos flag is now supported for sidekick(+)

sah 12/03/87	remove uptinmos calls

mjs 12/8/87	corrected bug with the way tcbbrkfg was tested for a
		cntrl-c response.

jsm 01/05/88	allow deletion of aliases created by function 0dh.

mjs 1/12/88	added function 16 to allow a serial device driver to set
		and	reset the scbidq field (ffff or 0000)
		also, corrected some assume statements

sah 01/19/88	change scbseg and zero seg access to mgetxxx macros

sah 02/17/88	added function 17h for 286 driver
		subfunction 00 - declare data segment
		subfunction 01 - declare code segment
		subfunction ff - undeclare segment

sah\rbr 02/20/88 move ddt segment to mo2 group
		corrected problem in function 0b where where should of
		be accessing the stack not the cs.

rbr 02/29/88	moving notsl to grp.

jrb 05/02/88	add function 18

sah 05/20/88	my 03/06/88 was incorrect. after running a test program
		on dos, indos flag is actual increment and decrement.
		to give a consistent and easy changable interface to
		to scbinmos i implement the following routines
			decinmos - decrements inmos flag is not zero
			incinmos - increments inmod flag

jrb 06/06/88	function 0 wasn't clearing carry if there was no
 jrbw		error - addtask for vna would go to int 38 with
		carry set (just because it happened that way) and
		would think there was an error allocating the tcb

sah 08/10/88	remove tsl from function 06 (since mossaver will call
		tsl anyway. also clean up module including removing
		obsolete code from function 0c.

sah 09/27/88	change function 7 suspend calls suspend2 calls so it
		work if call within tsl.

sah 10/04/88	made linkdrv public for mosinit2

sah 10/14/88	changes so that it will assemble.  cleanup.

sah 10/17/88	directly incoded scb declarations need here

mjs 10/21/88	remove the procedure linkdrv.  modify and cleanup
		function 0b to account for changes to mosddint.

mjs 10/22/88	more corrections to function 0b - the return value for
		dx was not being handled properly.

mjs 11/14/88	fixed mos resize lockup.  when the scb declarations
		were made directly in this module rather than using
		mosscbex.inc, the definition for scbmmsub slipped from
		a dword down to a word.  you call mm - you go bye bye.

sah 01/26/89	change lock equate to nlock (masm 5.10 compatibility)

rkg 03/08/89	corrected creation of alias for drives a: or b:

sah 03/09/89	added mos api services functions 19 - 22

rkg 04/20/89	deleted 'closechk' checking for close of spool files

mjs 05/03/89	modified function 22 to do a verification check on the
		id number supplied.  also, modified the return portion
		of the data structure and the data put in it.

mjs 05/05/89	corrected the firstbdb procedure in mosext0d.  when
		alias's for the A: drive were created and deleted in
		more than one task at once, the bdb links could get
		mangled.

mjs 05/05/89	added function 23 to support the changing of ddt's on
		the fly.  this is only for mono/serial types of ddt's
		not	for elterm, vna or sunriver.

mjs 06/27/89	modified function 16 to test for an existing irq
		reservation in the scbidq and scbidqp tables.  an error
		code is returned if a reservation already exists.

sah 06/29/89	converted notsl flag into scbnotsl flag.

sah 07/06/89	added bias equate for conditional assemble for stack
		biasing for use with debugging with periscope.

sah 07/25/89	corrections for novell, int d4 function 03 did not clear
		the buffer return to application.

sah 07/31/89	move tcb initialization data from function 22 into
		mositask.

sah 08/02/89	corrected a possiable problem with function ah could be
		non-zero when call mosliman to allocated tcb, remove
		function 00, and 01 - force them to bugerrors, remove
		ctrl-c processing which is not needed and could be
		causing problem with memory allocation errors. also
		speeded up function 15 by making test at front of
		mosint38 to reduce overhead when termination logic call
		the function and lanlink or other app has not hook it.

sah 08/03/89	corrections for function 22, so that dta is preseverd
		called for current task, this was causing restart to
		logic to have problems

sah 11/01/89	added function 24 to return serial #

mjs 11/10/89	added a line to clear the low nibble of tcbwait after
		the call to suspend2 within function 07.  this was needed
		to prevent a deadlock situation posed by stargate's new
		acl driver.

bwr 11/29/89	marked messages for foreign language translation.

sah 12/08/89	conditional assemble 286 driver logic out.

sah 12/15/89	corrections for split-smp support.
		added function 25h, to check if cs is in smp
		corrections for function 1a

bwr 01/16/90	  added new api functions 26 through 2a. these are to
		be used instead of their older counterparts in
		preparation for the move of the system to protected
		mode memory.
		  these functions will eventually be modified again to
		use a protected mode selector for addressing the memory
		segments.  at present, a real-mode (v86) segment
		address is used instead.  the applications level should
		never access the memory directly with the selector
		anyway, so applications written to this new interface
		will not require modification when the protected mode
		is established.

bwr 01/26/90	minor correction in critical region of new functions.
		instead of cli/sti, using pushf/cli/popf so flag state
		is preserved.

sah 02/20/90	added function 2b,2c and 2d. 2b is in use by custumer
		but is undocument, perferred method is through function
		2ch which is a more general spooler api call. also added
		function 2d for get maximun task size.

sah 03/16/90	switch cx and si meaning for purposes of ease of use.

mjs 03/30/90	the order of the inc [tcbnest] and call incinmos needed
		to be reversed to prevent scbinmos from wrapping under.
		this was causing Progress to lock up.

mjs 04/16/90	zero out tcbwinfo after call mosheman to delete the
		wait info smp block.  this is necessary so that 
		mosrtask only tries to delete a leftover wait info
		block when there actually is one.

mjs 04/17/90	modified extfun07 to manage tcbex7np.  this allows
		moskey to test for a task which is suspended without
		keyboard monitoring included.  if pamming is not denyed
		to such a task, the new watcher will get stuck there.

mjs 04/19/90	had to remove tcbex7np code (04/17/90).  was causing side
		effect where couldn't always pamswitch into a lanserve
		partition.

SAH 04/30/90	Had Function 22, set TCBOCLASS instead of TCBCLASS
		Correct problems with restart and security.

mjs 04/30/90	modified calls to pathfind to use new entry parameter
		in al which controls the response to volume labels.

SAH 05/01/90	Added function 2e, to check security partition access
		Added function 2f, to check security class access

mjs 05/17/90	added nesting of tcbwinfo for function 7.  predicted
		problem with cluster controller.

mjs 06/16/90	split most of mosext22 off into start_task so the
		restart logic wouldn't have to make an intd4 call.

BWR 09/17/90    Added new API function 0x30 to allow application to
                turn on/off TCBALT999 to allow keyboard ALT-ASCII
                code entry.

mjs 03/20/91	converted functions 14, 26, 27, 28, 29 and 2a to be
		direct.  these functions do not go through mossaver
		and mosrestore now.  for the scb/tcb access functions 
  		(26 through 2a) this was necessary to support api
		calls during irq handlers.
		function 14 is going to be used for the netbios post
		api function (which also must be callable from an
		irq handler).

mjs 03/21/91	modified the calling logic for non-saver functions to 
		not enable interrupts.  this is left up to individual
  		non-saver functions.
		added netbios post api function 14.

mjs 03/28/91	added intd4fun0f.  this is a special version of the
		suspend call when supports the tcbfwake force awake
		flag.  the tcbd40f flag is used to signal suspend
		that it is being entered from intd4fun0f.

mjs 04/18/91	modified intd4fun25 to be a non-saver function.  the 
		llnetbios irq logic needs to call this.

mjs 05/10/91	modified mosext18 to explicitly call invbdb instead
		of trying to manipulate bdbcach so flushbdb would
		call it (flushbdb no longer calls invbdb anyway).

====================== 5.01 begins here ==============================

SAH 08/06/92    Corrections for INT d4h function 1bh, subfunction 01
		change jnc into jnz... <one-liner>

mjs 08/11/92	added function 31h to support copy/c across llpro.
		$$shell.sys version 5.04 and updat501.sys version 1.08
		implement this fix for release 5.01.

mjs 08/18/92	clean up segment declarations

mjs 09/18/92	removed security check in id4f03

======================================================================^

.xlist
;	include mosint38.pub
	include options.inc
	include group.inc
	include macros.inc
	include mosregs.inc
	include moscdb.inc
	include mosgfb.inc
	include mostfb.inc
	include mosbdb.inc

tcb	segment at 09999h
	include mostcb.inc
tcb	ends
.list

spldseg segment at 55aah
	include moxspldt.inc		; data structure of spooler storage
spldseg ends

splbuff segment at 7777
splb	spooldat <>			; define seg for a single spool file
splbuff ends

; memory block definition

	if	0 eq 0			; so no publics
mbseg	segment at 1111h
mbtype	db	?			; m for memory block, z for last block
mbowner dw	?			; owner psp address
mbsize	dw	?			; size of block
mbseg	ends
	endif

gdata	segment
	extrn	scbtcbpf:word, scbtcbpc:word, scbtcbps:word, scbhp2siz:word
	extrn	scbmmptr:dword, scbgfbpf:word, scbbdbpf:word, scbbdbpl:word
	extrn	scbdrvr:dword, scbmmfg:byte, scbvtype:byte, scbmmsub:dword
	extrn	scbidq2:word, scbhwcl:byte, scbhpalc:word, scbnotsl:byte
	extrn	scbhpsiz:word, scbmmfea:byte, scbidqp:word, scbsmsg:byte
	extrn	scbhpadr:word, scbhp2adr:word, scbpost:word

if	code286
	extrn	scb286dec:byte
endif
gdata	ends

if 0 eq 0

extvct	macro	fn
	dw	mos:mosext&fn
	endm

; error codes defined

invfn	equ	1			; invalid function (or sub-function)
filenf	equ	2			; file not found (or invalid name)
pathnf	equ	3			; path not found (or invalid path)
manyfil equ	4			; too many files open
accdeny equ	5			; access denied
invhdl	equ	6			; invalid handle (file not open)
insmem	equ	8			; insufficient memory
invacc	equ	12			; invalid access code specified
invdata equ	13			; invalid data
drivenf equ	15			; drive not found (or invalid drive)
delcurd equ	16			; attempt to delete current directory
diffdev equ	17			; not the same device
nomore	equ	18			; no more files found
badcmd	equ	22			; unknown command (bad)
general equ	31			; general error
share	equ	32			; sharing violation
nlock	equ	33			; lock violation
shareov equ	36			; share buffer overflow (couldn't alloc RLB)
filexst equ	80			; file already exists
invprm	equ	87			; invalid parameter
fail24h equ	83			; fail chosen from int 24h (as defined by dos)
syshdl	equ	127 or 8000h		; attempt to dup or fdup a non-psp handle
xshare	equ	share or 8000h		; fail from int 24h sharing
xlock	equ	nlock or 8000h		; fail from int 24h locking
err24h	equ	fail24h or 8000h	; fail error from int 24h (signal for moserror)
intern	equ	80ffh			; internal error

; directory entry fields

datr	equ	11			; offset of attribute byte
dmade	equ	12			; reserved for creation data
dclass0 equ	13			; dir entry offset of class created
duser0	equ	14			; dir entry offset of user id created
dtime0	equ	18			; dir entry offset of time created
ddate0	equ	20			; dir entry offset of date created
dtime	equ	22			; offset of time word
ddate	equ	24			; offset of date word
dsize	equ	28			; offset of size dword
dclust	equ	26			; offset of bof cluster word

; directory entry file attribute bits defined

override equ	80h			; dir search class level override
arch	equ	20h			; archive
dir	equ	10h			; directory
lbl	equ	08h			; label
sys	equ	04h			; system
hid	equ	02h			; hidden
ro	equ	01h			; read-only

; bits in al on wait (fn 87) call

wkey	equ	1			; wait for keystroke
wtime	equ	2			; wait for timer ticks
wint	equ	4			; wait for hardware interrupt
wport	equ	8			; wait for char or status change on port(s)
wupoll	equ	80h			; wait, call user poll routine

; structures defined

waitinfo struc
wioldinfo dw	?			; previous value of tcbwinfo
wievent db	?			; class of events task is waiting for
wiblksz db	0			; size of this waitinfo block
wiibixi dw	?			; input index for key buffer
witicks dw	?			; timer value when task should wake up
	dw	?			; second word of timer information
wifport db	?			; first serial port number to check
winport db	?			; number of serial ports to check
wiimask dw	?			; bit mask for interrupts to watch
wiicount db	16 dup (?)		; occurrence count for hardware interrupts
waitinfo ends

wipl	equ	word ptr (size waitinfo); start of port information list

endif

waitblk segment at 2222
waitb waitinfo <?,?,?,?,?,?>
waitblk ends

irq	segment
	dw	38h*4			; offset of interupt 38
	dd	?			; save prior value
	dw	0			; don't save changes
	dw	mos:mosint38		; initial interupt return
	dw	0			; don't change back
irq	ends

;======================================================== mos segment
if 0 eq 0
segment_num = 1
endif
mosseg	segment
	assume	cs:mos,ds:grp,es:nothing,ss:tcb
	public	$$$int38
$$$int38 label	byte

	extrn	mosend:byte, sbios:word, scbfree:word
	extrn	mosliman:near, mosheman:near, classlvl:near
	extrn	noswitch:near, okswitch:near, moserror:near
	extrn	tsl:near, suspend:near, suspend2:near
	extrn	wrsector:near, flushdir:near, pathfind:near
	extrn	timparm:near, timchk:near, getkeys:near
	extrn	swtaskram:near, switchgp:near, invbdb:near
	extrn	caps:near, slash:near, mosddint:near
	extrn	callcon:near, mossaver:near, mosrestore:near
	extrn	terminate:near, ddtcallf:near, dopost:near
	extrn	reordlst:near, incinmos:near, decinmos:near
	extrn	flushbdb:near, findbdb:near, i17prtbit:near
	extrn	mositask:near, mosrtask:near, calclim:near,wordten:word

	public	mosext00, mosext02, mosext06, mosext07, mosext09, mosext0a

fkbhead equ	1ah			; 40:1a head pointer

; mos extended function vector table for interupt 38h function handler
; all vectors represented between 00h and xxh
; all must be defined externally (valid functions or not) in the form
; mosextxx where xx is the function number in hex
; if an invalid function, all you need do is a near return

vct38	label	word
	irp	fn,<00,01,02,03,04,05,06,07,08,09,0a,0b,0c,0d,0e,0f>
	extvct	fn
	endm
	dw	0,0,0,0,0,0		; functions 10 through 15
	irp	fn,<16,17,18,19,1a,1b,1c,1d,1e,1f,20,21,22,23,24>
	extvct	fn
	endm
	dw	0,0,0,0,0,0		; func 25 through 2a
        irp     fn,<2b,2c,2d,2e,2f,30>
	extvct	fn
	endm
lnvct38 equ	$-vct38

; non-saver functions

nsf_tbl db	14h,25h,26h,27h,28h,29h,2ah,31h
nsf_len	equ	$-nsf_tbl
nsf_ofs	dw	mosext14,mosext25,mosext26,mosext27,mosext28,mosext29,mosext2a
	dw	mosext31

	subttl mosint38 service routine
	page
;=======================================================================
;,fs
; mosint38
; 
; the following is a clone of mosint21 to serve mos extended
; functions.  basically the same as mosint21 routine - please
; note that any changes to this or mosint21 should be investi-
; if other corresponding routines since they are very similar
;
; in:	ah = function selector
;	other regs - depends on function
;
; out:	depends on function
; 
;,fe
;======================================================================^
	assume	ds:nothing,es:nothing,ss:nothing
	public	mosint38
mosint38 proc far

; interrupts must stay off until the test below is done for 
; function 0f (where tcbd40f is set)

	cmp	ah,15h			; func 15 is a hook
	jne	mosnot15
	iret
mosnot15:
	push	di			; precheck for non-saver functions
	push	ax
	push	cx
	push	es
	mov	al,ah
	mov	di,cs
	mov	es,di
	mov	di,offset nsf_tbl
	mov	cx,nsf_len
	cld
	repne	scasb
	pop	es
	pop	cx
	pop	ax
	jne	nsf1
	sub	di,offset nsf_tbl
	dec	di			; enter the non-saver function
	shl	di,1			; with all entry registers
	add	di,offset nsf_ofs	; except that di is on the stack
	jmp	word ptr cs:[di]
nsf1:
	pop	di
	push	ds			; on user's registers at this time
	mgetscb ds
	assume	ds:grp
	mov	ds,[scbtcbpc]
	assume	ds:tcb

; interrupts must still be off at this point

	cmp	ah,0fh
	jne	mos38xx
	mov	[tcbd40f],1		; set signal for suspend
mos38xx:
	call	incinmos		; sah 05/26/88
	inc	[tcbnest]
	pop	ds			; back to user's regs
	assume	ds:nothing, es:nothing
	call	mossaver
	assume	ds:grp,ss:tcb

if bias
	push	[tcbstkp]
	sub	word ptr [tcbstkp], bias
endif

	mov	bl,[tah]		; get function number from tcb stack using bp
	xor	bh,bh
	add	bx,bx
	cmp	bx,lnvct38
	jb	mos38h
jmos38i:
	mov	[tax],1 		; invalid function code
	or	[tflag],carry
	jmp	short mos38a
mos38h:
	cmp	[vct38+bx],0
	je	jmos38i 		; also invalid
	call	[vct38+bx]		; call the function
mos38a:

if bias
	pop	[tcbstkp]
endif

	call	mosrestore
	assume	ds:nothing,ss:nothing
	push	ds			; on user's registers at this time
	mgetscb ds
	assume	ds:grp
	mov	ds,[scbtcbpc]
	assume	ds:tcb
	dec	[tcbnest]
	call	decinmos		; sah 05/26/88
	pop	ds			; back to user's regs
	assume	ds:nothing, es:nothing
	iret
mosint38 endp

	subttl	mosext00 - allocate tcb
	page
;=======================================================================
;,fs
; mosext00 - api fun 00 - allocate tcb
; 
; this function will allocate a tcb from the system heap and return a
; pointer to it.
; 
; in:	al = 0 for allocate
; 	al = 1 for deallocate
;	 tes -> tcb
; 
; out:	tes -> allocated tcb (when entry al == 0)
; 
; errors: 18 - out of heap space
; 	31 - general failure
; 
;,fe
;======================================================================^
	assume	ds:grp,ss:tcb,es:nothing
mosext00 proc near	
	 mov	ax,'00'
	 jmp	short funbug
mosext00 endp

	subttl	mosext01 - initiate task
	page
;=======================================================================
;,fs
; mosext01 - api fun 01 - initiate task
; 
; this function will start up a new task from a passed tcb.
; 
; in:	tah = 1
; 	tes -> tcb with task information
; 	tds:tsi -> startup batch file string
; 
; out:	tbx = % heap used in ascii format
; 	tds:tsi -> memman memory used message (40 bytes)
; 	tax = error information if cy
; 
; errors (if carry) : see mositask
; 
;,fe
;======================================================================^
	assume	ds:grp,ss:tcb,es:nothing
mosext01 proc near
	mov	ax,'10'
funbug:
	mov	word ptr cs:[fbugxx],ax
	call	bugerror
	db	'01 '
	db	'Extended Service '	;@@xlat
fbugxx	db	'xx no longer supported', 00h  ;@@xlat
mosext01 endp

	subttl	mosext02 - get scb address
	page
;=======================================================================
;,fs
; mosext02 - api fun 02 - get scb address
; 
; returns the scb address in es:bx.
; 
; in:	none
; 
; out:	tes:tbx -> scb
; 
;,fe
;======================================================================^
	assume	ds:grp,ss:tcb,es:nothing
mosext02 proc	near
	mgetscb es			; scb segment address
	mov	[tes],es
	mov	[tbx],offset scbtcbpf	; offset to first field in scb
	mov	[tax],0 		; tell them it work
	ret
mosext02 endp

	subttl	mosext03 - get/set a file's creation data
	page
;=======================================================================
;,fs
; mosext03 - api fun 03 - get/set a file's creation data
; 
; get/set a file's creation data
; 
; in:	tds:tdx -> path
; 	tes:tbx -> 10-byte buffer fielded as:
; 	 byte  0 - reserved (set it to 0)
; 	 byte  1 - class
; 	 bytes 2 thru 5 - userid created by
; 	 bytes 6 & 7 - creation time
; 	 bytes 8 & 9 - creation date
; 	tal = 0 get tsl system info
; 	    = 1 set tsl system info
; 
; out:	carry bit of tflag set if error
; 	 tax = error code
; 	 invhdl - invalid file handle specified
; 	 invfn - invalid function specified
; 	 & critical error codes
; 	carry bit of tflag clear if no error
; 	 tds:tdx -> 10-byte buffer containing current creation data
; 	 tal = access level permitted to file
; 
;,fe
;======================================================================^
	assume	ds:grp,es:nothing,ss:tcb
public	mosext03
lproc	mosext03

lbyte	function
ldword	bf
lstring fnb,11
lstring secbuf,<size sectorblk>

	mov	cx,bp
	mov	bp,[bp]
	mov	al,[tal]
	mov	bx,[tbx]		; handle of file for date and time
	mov	es,[tes]
	mov	dx,[tds]
	mov	di,[tdx]
	mov	bp,cx
	call	noswitch		; no task switches allowed
	mov	[function],al
	mov	word ptr [bf],bx
	mov	word ptr [bf+2],es
	mov	es,dx
	lea	si,[fnb]
	lea	bx,[secbuf]
	mov	al,1			; skip labels
	callmos2 pathfind
	jnc	mosf83ok

; novell will cause an error here, the idea method would be
; that mosnet will intercept this function and handle it correctly
; so what was done was to clear out all bytes in buffer returned

	cmp	[function],00h		; is this query call
	jne	mosf83out
	mov	bx,es
	push	ax
	les	di,[bf]
	xor	ax,ax
	mov	cx,10/2
	rep	stosw
	pop	ax
mosf83out:
	jmp	mosf83x
mosf83ok:
	mov	al,3
	or	bx,bx
	jz	mosf83a
	assume	es:dbb
	mov	al,es:[dbbbuf+si+dclass0]  ; return access level
	callmos2 classlvl
mosf83a:
	mov	cx,bp
	mov	bp,[bp]
	mov	[tal],al
	mov	bp,cx
	cmp	[function],0
	jne	mosf83c

; getting file date and time

	or	bx,bx
	jz	mosf83b
	mov	ax,es
	mov	ds,ax
	lea	si,[dbbbuf+si+dmade]
	les	di,[bf]
	mov	cx,10/2
	rep	movsw
	xor	ax,ax
	jmp	mosf83x

; getting device file date and time (all 0's)

mosf83b:
	les	di,[bf]
	xor	ax,ax
	mov	cx,10/2
	rep	stosw
	jmp	mosf83x

; setting file date and time

mosf83c:
	mov	cl,al			; remember access level to dir entry
	or	bx,bx			; device or file?
	mov	ax,accdeny		;   dir entry
	jz	mosf83x 		; z if path in question represents device
	cmp	[function],01h
	mov	ax,invfn
	jnz	mosf83x
	mov	dx,ds			; remember bdb address
	lea	di,[dbbbuf+si+dmade]
	test	[dbbbuf+si+datr],dir
	lds	si,[bf]
	jnz	mosf83d
	mov	cl,[si+1]
	cmp	cl,es:[di+1]		; access denied to try to change class byte
	jne	mosf83x 		; (unless it's a directory)
mosf83d:
	mov	cx,10/2
	rep	movsw
	mov	ds,dx
	callmos2 wrsector
	jc	mosf83x
	callmos2 flushdir
	jc	mosf83x
	xor	ax,ax
	assume	ds:nothing,es:nothing,ss:tcb
mosf83x:
	call	okswitch		; safe to allow a task switch
	mov	bx,bp
	mov	bp,[bp] 		; address task registers to report tax error
	mov	cx,filenf
	callmos2 moserror
	mov	bp,bx
	mgetscb ds

lundef	function
lundef	bf
lundef	fnb
lundef	secbuf

lendp	mosext03

	subttl	mosext04 - get tcb address from task id
	page
;=======================================================================
;,fs
; mosext04 - api fun 04 - get tcb address from task id
; 
; in:	tbx = task id   (an id of -1 means the current task)
; 
; out:	carry bit of tflag set if error
; 	 tax = error code
; 	 accdeny - access to the task denied
; 	 invprm - invalid parameter specified
; 	 & critical error codes
; 	carry bit of tflag clear if no error
; 	 tes -> tcb of task with id in tbx
; 
; changes: es, ax, bx
; 
;,fe
;======================================================================^
	assume	ds:grp,es:nothing,ss:tcb
public	mosext04
mosext04 proc near
	mov	bx,[tbx]
	call	gettask 		; get task segment error in ax, tcb in es
	or	ax,ax
	jnz	skipes
	mov	[tes],es
skipes:
	callmos2 moserror
	ret
mosext04 endp

	subttl	mosext05 - remove task
	page
;=======================================================================
;,fs
; mosext05 - api fun 05 - remove task
; 
; in:	tes = tcb address for task
; 
; out:	carry bit of tflag set if error
; 	 tax = error code
; 	 accdeny - access to the task denied
; 	 invprm - invalid parameter specified
; 	 & critical error codes
; 	carry bit of tflag clear if no error
; 	 tax = % of system heap used, in ascii format
; 	 tds:tsi -> memman memory used message (40 bytes)
; 
; changes: es, ax
; 
;,fe
;======================================================================^
	assume	ds:grp,es:nothing,ss:tcb
public	mosext05
mosext05 proc near
	mov	es,[tes]
	assume	es:tcb
	cmp	es:[tcbtype],'T'	; really a tcb?
	je	mf8510			; if no error
	mov	ax,accdeny
	jmp	short mf85100		; return error

; check to see if we have access to the task

mf8510:
	call	mosrtask		; remove the task
	or	ax,ax			; error removing it?
	jnz	mf85100 		; if error
	mov	ah,3			; get % heap used up
	call	mosheman
	mov	[tax],ax

; return pointer to memman memory message

	mov	ax,word ptr [scbmmptr]
	add	ax,12
	mov	[tsi],ax
	mov	ax,word ptr [scbmmptr+2]
	mov	[tds],ax
	xor	ax,ax
mf85100:
	callmos2 moserror
	ret
mosext05 endp

	subttl	mosext06 - used by mosnet
	page
;=======================================================================
;,fs
; mosext06 - api fun 06 - used by mosnet
; 
; called by mosnet to get tsl called (thorugh mossaver)
; when spend lot of time in ipx, will miss most int8 slicing
; opportunities.  mosnet calls id4f06 to allow compensation.
;
; in:	none
; 
; out:	none
; 
;,fe
;======================================================================^
	assume	ds:grp,ss:tcb,es:nothing
mosext06 proc	near
	ret
mosext06 endp

	subttl	mosext07 - wait for event
	page
;=======================================================================
;,fs
; mosext07 - api fun 07 - wait for event
; 
; this is the mos wait for event call.  it is used to provide tasks a
; means of giving up the processor and waiting for an event to occur
; without pigging system time.
; 
; the task may request to wait for up to 4 classes of events:
; a keystroke on the task's console, a specified number of timer ticks,
; a hardware interrupt, or status change on one or more serial ports.
; tasks may request to wait for no event.  in that case, they will be
; put to sleep forever, or until some external agent changes the
; task's TCB to indicate that it should wake up.
; 
; the task is awakened when its requested events occur, and told which
; event awakened it.
; 
; to put the task to sleep the following approach is used:
; 
; 1) set bit 0 of tcbwait to 1 (and bits 1 & 2 to 0) so tsl (task
; selection logic) knows task is waiting for something to happen
; 2) point tcbpoll to the 'event waiting' routine (the one that deter-
; mines that the events the task is waiting for has occurred)
; 3) call suspend
; 
; when the 'event waiting' routine has determined that the wait is
; finished it should return an al code of 0 and the suspend routine
; will return to the calling routine
; 
; in:	tah = 07h
; 	tal = 0 indicates that the task should wait until the
; 		"wait resolved" bit in [tcbwait] is set
; 	otherwise,
; 	tal = event type to wait for, logical or of these 5 values:
; 	 1 == wait for keystroke
; 	 2 == wait for timer ticks
; 	 4 == wait for hardware interrupts
; 	 8 == wait for serial port change
; 	 80h == wait, call user-supplied poll routine
; 	    if this bit is set, all others are ignored
; 	tbx = # of time ticks to wait (if specified)
; 	tcx = bit map of interrupts to wait for (if specified)
; 	 bit 0 indicates irq0, bit 1 indicates irq1, etc. up to
; 	 bit 15 and irq15
; 	tdh = number of serial ports to watch (if specified)
; 	tdl = first serial port to watch (if specified)
; 	tes:tbx = pointer to user poll routine (if specified)
; 
; out:	tax = error code if carry set, or if carry clear:
; 	tal = event type which awakened task
; 	tcx = hardware interrupt, if any, which awakened the task
; 	tdl = serial port, if any, which awakened the task
; 
; ax, bx, cx, dx, si, di, es changed
; 
;,fe
;======================================================================^
	assume	ds:grp,ss:tcb,es:nothing
mosext07 proc	near
	cld
	or	[tcbwait],1		; tell tsl that task is waiting
	and	[tcbwait],not 6 	; clear bits 1 & 2 (ready to awake)

; what are we waiting for?

	cmp	[tal],0 		; are we waiting for anything?
	jnz	mf8710			; if we're picky about what we wait for
	jmp	mf87200 		; if just want to sleep, sleep, sleep

; set address of routine to resolve wait

mf8710:
	test	[tal],wupoll		; user polling routine?
	jz	mf8713			; if no poll routine, check next bit
	jmp	mf87250 		; if user poll routine, install & leave
mf8713:
	mov	word ptr [tcbpoll],offset mos:evwait
	mov	word ptr [tcbpoll+2],cs

; set up waitinfo block for task

	mov	ax,size waitinfo - size wiicount  ; assume smallest waitinfo block
	test	[tal],wint		; need bigger block if waiting on interrupts
	jz	mf8715			; if we don't wait on interrupts
	add	ax,size wiicount	; if waiting for interrupts, 16 more bytes
mf8715:
	mov	bx,ax			; save block size
	test	[tal],wport		; will waitinfo block have serial port info?
	jz	mf8720			; if normal size block
	mov	cl,[tdh]		; number of ports
	xor	ch,ch
	shl	cx,1			; 4 bytes per port
	shl	cx,1
	add	ax,cx
mf8720:
	add	ax,15			; make sure it has enough paragraphs
	mov	cl,4			; need to divide by 16
	shr	ax,cl			; convert to paragraphs
	inc	ax			; add one for header
	mov	dx,ax			; ready for call to mosheman
	xor	ax,ax			; request mosheman to allocate memory
	call	mosheman		; get memory from heap
	or	al,al			; if non-zero, couldn't get memory
	jz	mf8730			; if memory allocated ok
	jmp	mf87300 		; error allocating memory
mf8730:
	mov	ax,es			; paragraph address of new block
	inc	ax			; skip link at beginning
	mov	cx,[tcbwinfo]		; don't lose current value, could nest
	mov	[tcbwinfo],ax		; store information pointer in tcb
	mov	es,ax
	assume	ds:waitblk, es:waitblk
	push	ds
	mov	ds,ax			; pointer to waitinfo block
	mov	[waitb.wioldinfo],cx	; prepare for nesting
	mov	[waitb.wiblksz],bl	; save size of the block in bytes
	mov	al,[tal]		; events to monitor
	mov	[waitb.wievent],al	; set events to monitor
	test	al,wkey 		; waiting for keystroke?
	jz	mf8733			; if no key wait
	or	[tcbstat],wkey		;jrb signal tsl of wait for key
	push	es
	push	ax
	mov	ax,40h
	mov	es,ax
	pop	ax			;rbr
	assume	es:nothing
	mov	cx,es:[fkbhead] 	; save input pointer of keyboard ring buffer
	pop	es
	assume	es:waitblk
	mov	[waitb.wiibixi],cx
mf8733:
	test	al,wtime		; wait for specific time?
	jz	mf8740			; no, check next parameter
	mov	ax,[tbx]		; ticks to wait
	or	ax,ax			; wait zero ticks?
	jnz	mf8735			; if wait time is not zero
	jmp	mf87400 		; if zero wait time, error
mf8735:
	mov	cl,8			; wrap flag for general wait logic
	push	es			; save pointer to wait block
	push	ss
	pop	es			; es points to tcb
	call	timparm 		; set up for timchk calls in evwait
	pop	es
	mov	[waitb.witicks],ax	; store tick value for evwait
	mov	[waitb.witicks+2],cx

; wait for serial port status change?

mf8740:
	test	[tal],wport		; check on ports?
	jz	mf8770			; if we don't care about ports

; test for serial driver installed

	mov	ah,6
	mov	dx,0
	int	14h
	or	ax,ax			; is high bit of ax set?
	js	mf8750			; if serial driver there, all is ok
	jmp	mf87400 		; no serial driver, invalid parameter
mf8750:
	xor	cx,cx
	mov	dx,cx			; zero dh
	mov	cl,[tdh]		; get port count
	or	cx,cx			; how many ports?
	jnz	mf8755			; port count not zero, we're OK
	jmp	mf87400 		; if zero port count, error
mf8755:
	mov	dl,[tdl]		; get starting port number
	mov	[waitb.wifport],dl	; store starting port number
	mov	[waitb.winport],cl	; store port count
	mov	di,word ptr [waitb.wiblksz]  ; start of port list in waitinfo block
	and	di,0ffh 		; block length only a byte

; es should point to waitinfo block at this point (see above).

mf8760:
	mov	ah,3			; get port status bits
	int	14h
	stosw				; store in wait block
	mov	ah,10			; get number of chars in input buffer
	int	14h
	stosw				; store in second word of two
	inc	dx			; next port in list
	loop	mf8760

; set up for hardware interrupt alert.

mf8770:
	test	[tal],wint		; wait on hardware interrupts?
	jz	mf8780			; if we don't care about hardware interrupts
	mov	ax,[tcx]		; interrupt mask
	or	ax,ax
	jnz	$+5
	jmp	mf87400 		; if mask has no bits set, error
	mov	[waitb.wiimask],ax	; store interrupt request mask
	pop	ds
	assume	ds:grp			; ds points to scb again

; copy current hardware interrupt counts from scb.

	lea	si,[scbhwcl]		; pointer to interrupt count list
	mov	cx,8
	lea	di,[waitb.wiicount]
	rep	movsw			; copy the counts into the waitinfo block
	jmp	short mf8790		; suspend the task
mf8780:
	pop	ds
mf8790:
mf87x:
	call	suspend2		; allow task switch

; the task has been awakened.  tell it why.

	and	[tcbwait],0f0h		; clear the wait info
	xor	bx,bx			; we'll zero something.
	mov	al,[waitb.wievent]
	mov	[tal],al		; return event type which woke us
	test	al,wint 		; did an interrupt wake us?
	jnz	mf87100 		; if it was a hardware interrupt
	test	al,wport		; did a serial port wake us?
	jz	mf87110 		; if it wasn't a port

; serial port woke task up.

	mov	bl,[waitb.wifport]
	mov	[tdl],bl		; return port number
	jmp	short mf87110

; hardware interrupt woke task up.

mf87100:
	mov	bx,[waitb.wiimask]
	mov	[tcx],bx		; return interrupt bit mask

; return to task.

mf87110:
	and	[tflag],not carry	; clear carry flag in application flags
mf87120:				; to indicate no error occurred
	mov	cx,[waitb.wioldinfo]	; un-nest to previous block
	mov	ax,es
	dec	ax
	mov	es,ax			; get pointer to base of block again
	mov	ah,1			; give waitinfo block back
	call	mosheman
	mov	[tcbwinfo],cx		; un-nest
mf87130:
	ret

; just sleep, don't wait for anything in particular.
; give task a poll routine which checks the "wait resolved" bit.

mf87200:
	mov	word ptr [tcbpoll],offset mos:bitwait
	mov	word ptr [tcbpoll+2],cs
mf87210:
	call	suspend2		; allow task switch
	and	[tflag],not carry	; clear carry flag, say we waited ok
	jmp	mf87130 		; the wait is over, return to caller

; wait, call user polling routine.

mf87250:
	mov	ax,[tbx]		; offset of user poll routine
	mov	word ptr [tcbpoll],ax
	mov	ax,[tes]		; segment of user poll routine
	mov	word ptr [tcbpoll+2],ax
	jmp	mf87210 		; give up processor

; couldn't allocate WaitInfo block

mf87300:
	pop	ds			; restore original ds register
	mov	ax,insmem
	callmos2 moserror
	jmp	mf87130

; wait time of zero ticks requested, or zero ports to check,
; or no bits set in interrupt bit mask

mf87400:
	pop	ds			; restore original ds
	mov	ax,invprm		; invalid parameter
	callmos2 moserror
	jmp	mf87120 		; return waitinfo block

	subttl evwait - event waiting routine
	page
;=======================================================================
;,fs
; evwait - event waiting routine
; 
;  called from task selection logic.  determines if the keystroke, timer
;  tick, hardware interrupt, or serial port status change the task is
;  waiting for has happened.
; 
; in:	ss points to the tcb of the task to check
; 
; out:	ax 0 if task can be awakened
; 	ax non-0 if task must remain asleep
; 
; ax, cx, dx, si, di, es changed
; 
;,fe
;======================================================================^
evwait	proc	far
	assume	ds:nothing, es:nothing, ss:tcb
	push	ds
	mov	ax,[tcbwinfo]		; get segment of wait block
	mov	ds,ax			; point ds at wait block for this task
	assume	ds:waitblk

; check for keystroke

	test	[waitb.wievent],wkey
	jz	evwa20			; if not waiting on keystroke
	mov	cx,[tcbscrdd]		; first terminal watching this partition
	jcxz	evwa20			; if no one watching, no keys
	push	ds
	xor	dl,dl			; flag for scan code found
	assume	ds:tcb
evwa10:
	mov	ds,cx			; see if scan code found for this terminal
	les	di,[tcbkeyrdy]		; check for scan code ready
	or	dl,es:[di]
	mov	cx,[tcbnxtdd]
	or	cx,cx			; another terminal to check?
	jnz	evwa10			; check next one
evwa15:
	pop	ds
	assume	ds:waitblk
	or	dl,dl			; did we find a scan code?
	jz	evwa20
	and	[waitb.wievent],wkey	; say which event woke us
	jmp	evwa100 		; there was a key, wake process

; check for time expired.

evwa20:
	test	[waitb.wievent],wtime	; waiting for ticks?
	jz	evwa30			; if we don't care about ticks
	mov	ax,[waitb.witicks]	; info for timchk
	mov	cx,[waitb.witicks+2]
	push	ss
	pop	es
	call	timchk			; see if time is up
	jnz	evwa30			; if time is not up
	and	[waitb.wievent],wtime	; say which event woke us
	jmp	evwa100 		; time is up, wake process

; test for hardware interrupt.

evwa30:
	test	[waitb.wievent],wint	; waiting for hardware interrupts
	jz	evwa50			; if we don't care about hardware interrupts
	mov	cx,size wiicount	; number of bytes to check
	mgetscb es			; es points to scb
	mov	si,offset waitblk:[waitb.wiicount]
	mov	di,offset grp:[scbhwcl]
	mov	ax,1
evwa40:
	test	ax,[waitb.wiimask]	; do we care about this interrupt?
	jnz	evwa45			; if we care
evwa43:
	shl	ax,1			; test next interrupt
	inc	si
	inc	di
	loop	evwa40
	jmp	short evwa50		; no hardware interrupts, try next
evwa45:
	mov	dl,[si] 		; compare stored count to count now
	cmp	dl,es:[di]
	jz	evwa43			; if counts same
	and	[waitb.wiimask],ax	; leave only interrupt's bit set
	and	[waitb.wievent],wint	; say which event woke us
	jmp	evwa100

; test for serial port status change.

evwa50:
	test	[waitb.wievent],wport	; watching serial ports?
	jz	evwa70			; if we don't care about ports
	xor	cx,cx			; zero out ch
	mov	dx,cx			; zero out dh
	mov	cl,[waitb.winport]	; number of ports to check
	mov	dl,[waitb.wifport]	; first port to check
	cld
	mov	si,word ptr [waitb.wiblksz]  ; point si at port data
	and	si,0ffh 		; length is only a byte
evwa60:
	lodsw				; get port status
	mov	di,ax			; save old status
	mov	ah,3			; get port status
	int	14h
	cmp	ax,di			; current status same as old?
	jne	evwa80			; wake because of port status change
	lodsw				; get # of input characters
	mov	di,ax
	mov	ah,10
	int	14h
	cmp	ax,di			; # of characters in buffer changed?
	jne	evwa80			; wake because of character received
	inc	dx
	loop	evwa60			; next port to check
evwa70:
	mov	al,1			; can't be awakened
	jmp	short evwa110		; exit routine

; task awakened because of serial port status change

evwa80:
	and	[waitb.wievent],wport	; woke up because of port

; task can be awakened.

evwa100:
	xor	ax,ax			; return 0 to caller
evwa110:
	pop	ds
	ret
evwait	endp

	subttl bitwait - event waiting routine for device drivers
	page
;=======================================================================
;,fs
; bitwait - event waiting routine for device drivers
; 
; called from task selection logic.  determines if the "wait resolved"
; bit in the tcbwait field of the tcb is set or clear.	if the bit is
; set, the routines sets ax to 0 - "wake task up."  if the bit is
; clear, the routine sets ax to 1 - "keep task asleep."
; 
; in:	ss points to the tcb of the task to check
; 
; out:	ax 0 if task can be awakened
; 	ax 2 if task must remain asleep
; 
; ax changed
; 
;,fe
;======================================================================^
bitwait proc	far
	assume	ds:nothing, es:nothing, ss:tcb
	mov	ax,2
	xor	al,[tcbwait]		; return 0 if bit 1 set, 2 if bit 1 clear
	and	al,2			; we only care about that one bit
	ret
bitwait endp

mosext07 endp

	subttl	mosext08 - move information between tasks.
	page
;=======================================================================
;,fs
; mosext08 - api fun 08 - move information between tasks.
; 
; this call allows the caller to move information between tasks.
; the information is moved through an intermediate 512 byte buffer
; which is allocated from the system heap.
; 
; optimizations for odd-sized copies require that the copy routine must
; be able to load the byte immediately after the section of memory to
; copy, regardless of whether the section of memory to move is of odd
; or even length.
; 
; the move routine calls the switch routine to switch the proper tasks'
; memory into context.
; 
; in:	tah = 08h
; 	tbx -> source task's TCB
; 	tds:tsi -> location in source task's memory of memory to move
; 	tdx -> destination task's TCB
; 	tes:tdi -> location in destination to which to move information
; 	tcx = number of bytes to move
; 
; out:	tax = error code if carry set
; 
; ax, bx, cx, dx, si, di, es changed
; 
;,fe
;======================================================================^
	assume	ds:grp,ss:tcb,es:nothing
public	mosext08
lproc	mosext08
ldword	srcptr
ldword	dstptr
lword	count
lword	srctcb
lword	dsttcb
lword	switcb
ldword	tmpbuf

	mov	[scbnotsl],'Y'		; not ok to switch ram banks
	call	noswitch		; don't do task switching
	mov	bx,bp
	mov	bp,[bp] 		; get task registers
	push	ds
	push	[scbtcbps]		; tcb of task whose memory is switched in
	mov	ds,[tds]		; copy source pointer
	assume	ds:nothing
	mov	si,[tsi]
	mov	es,[tes]		; copy destination pointer
	mov	di,[tdi]
	mov	cx,[tcx]		; byte count
	mov	ax,[tbx]		; source tcb
	mov	dx,[tdx]		; destination tcb
	mov	bp,bx			; back to local variables
	pop	[switcb]		; store tcb of current task in local var.
	mov	word ptr [srcptr],si
	mov	word ptr [srcptr+2],ds
	pop	ds			; restore initial ds
	assume	ds:grp
	mov	word ptr [dstptr],di	; continue storing local vars
	mov	word ptr [dstptr+2],es
	mov	word ptr [count],cx
	mov	word ptr [srctcb],ax
	mov	word ptr [dsttcb],dx
	cmp	cx,3			; 0, 1 or 2 bytes are special cases
	jae	mf8805			; if more than 2 bytes to move
	jmp	mf88100 		; if 0, 1 or 2 byte special case
mf8805:

; copy more than 2 bytes.

mf8810:
	mov	dx,(512 / 16) + 1	; get temp buf from mosheman
	xor	ax,ax
	call	mosheman
	or	al,al			; did we get the memory?
	jz	mf8820			; if we got the memory
	mov	ax,insmem		; say "not enough memory"
	jmp	mf88200 		; leave routine
mf8820:
	mov	ax,es
	inc	ax			; skip header
	mov	word ptr [tmpbuf+2],ax	; store buffer pointer segment
	mov	word ptr [tmpbuf],0	; store offset
	mov	bh,cl
	and	bh,1			; bh will be non-zero if odd count
	cld

; copy 512 bytes from source to temp to destination.

mf8830:
	mov	cx,512
	cmp	[count],cx		; a whole buffer's worth to move?
	jae	mf8840			; if at least 512 bytes to move
	mov	cx,[count]		; if less than 512 bytes to move
	jcxz	mf8850			; if no more bytes to copy
mf8840:
	sub	[count],cx		; we will copy another cx bytes
	shr	cx,1			; do copy in words, not bytes
	mov	es,[srctcb]
	call	swtaskram		; switch source task's RAM in
	push	ds			; save ds across copy
	lds	si,[srcptr]		; copy from user's source of copy
	les	di,[tmpbuf]		; copy into temporary buffer
	push	cx			; save count for next copy
	rep	movsw
	mov	bl,ds:[si]		; get one byte past end of copy
	mov	word ptr [srcptr],si	; update source pointer
	pop	cx
	pop	ds
	mov	es,[dsttcb]		; now copy buffer into dest. task
	call	swtaskram		; switch destination task's RAM in
	push	ds
	lds	si,[tmpbuf]
	les	di,[dstptr]

; cx is already set

	rep	movsw			; copy from temp buf to dest. task
	mov	word ptr [dstptr],di	; update destination pointer
	pop	ds
	jmp	mf8830			; next chunk

; if length of copied memory is odd, move last byte into destination.

mf8850:
	or	bh,bh			; odd size copy?
	jz	mf8860			; if size not odd
	mov	es:[di],bl		; if size odd, account for shr
					; done on byte count above
; return temporary buffer to heap.

mf8860:
	mov	ax,word ptr [tmpbuf+2]	; only need segment address
	dec	ax			; account for header paragraph
	mov	es,ax
	mov	ah,1
	call	mosheman		; return the buffer
	jmp	short mf88130		; exit routine

; deal with 0, 1, or 2 byte copies.

mf88100:
	or	cx,cx
	jnz	mf88110 		; if non-zero length
	mov	ax,invprm		; zero length copies are bad stuff
	jmp	short mf88200		; leave routine
mf88110:
	push	dx			; save destination task's TCB
	mov	es,ax
	call	swtaskram		; switch in source task's RAM
	pop	dx
	push	ds
	lds	si,[srcptr]		; get byte(s) to copy
	mov	bx,ds:[si]		; assume 2 byte length
	pop	ds			; restore original ds
	mov	es,dx			; dx has destination task's RAM
	push	bx
	push	bp			; be paranoid & save them
	call	swtaskram		; switch in destination task's RAM
	pop	bp
	pop	bx
	les	di,[dstptr]		; restore destination pointer
	cmp	[count],1		; 1 byte or 2?
	ja	mf88120 		; if 2 bytes to move
	mov	es:[di],bl		; store new byte
	jmp	short mf88130		; exit routine
mf88120:
	mov	es:[di],bx		; move 2 bytes

; switch in original task's RAM.

mf88130:
	mov	es,[switcb]
	call	swtaskram		; switch in application ram
	xor	ax,ax			; return successful copy
mf88200:
	mov	bx,bp
	mov	bp,[bp] 		; use task registers to report error
	mov	cx,filenf
	callmos2 moserror
	mov	bp,bx
	call	okswitch		; task switching may resume
	mov	[scbnotsl],'N'		; ok to switch ram now

lundef	srcptr
lundef	dstptr
lundef	count
lundef	srctcb
lundef	dsttcb
lundef	switcb
lundef	tmpbuf
lendp	mosext08

	subttl	mosext09 - call routine in another task.
	page
;=======================================================================
;,fs
; mosext09 - api fun 09 - call routine in another task.
; 
; this routine calls a routine in another task's memory.  It will not
; call a routine in the current task's memory, since the caller can do
; that himself.
; 
; the called task's memory is switched in, all of the called task's
; registers are set to the values of the calling task's registers,
; except for ss and sp.  this routine does not switch stacks from the
; system stack of the calling tcb.  once the registers are set, control
; is transferred to the requested address.  the task routine must
; return via an iret instruction.
; 
; in:	tah = 09h
; 	tdx -> tcb of task in which routine is to be called.
; 	tds:tsi -> routine in task's memory space to call
; 
; out:	tax = error code if carry set
; 
;,fe
;======================================================================^
	assume	ds:grp,ss:tcb,es:nothing
mosext09 proc	near
	mov	ax,[tdx]
	mov	bx,[scbtcbpc]		; we will use this later on, so keep it.
	cmp	ax,bx			; do they want to call themselves?
	je	mf89200 		; if they try to use this to call themselves
	mov	[scbnotsl],'Y'		; say no bank switching
	call	noswitch		; and no asynchronous task switching
	push	[scbtcbps]		; save scbtcbps so we can switch back after
	call	switchgp		; switch dest. task's RAM, video & context
	push	bp			; save pointer to calling task's registers
	push	ds			; save our data segment
	pushf				; set up for iret done by called routine
	push	cs
	lea	ax,[mf8920]		; iret to our cs, label mf8910
	push	ax
	push	[tds]			; do retf to this address
	push	[tsi]
	mov	ax,[tax]		; switch to calling task's registers
	mov	bx,[tbx]
	mov	cx,[tcx]
	mov	dx,[tdx]
	mov	si,[tsi]
	mov	di,[tdi]
	mov	ds,[tds]
	mov	es,[tes]
	mov	bp,[tbp]		; all registers set
	retf				; do far return to requested address
mf8920:
	pop	ds			; restore original data segment
	pop	bp			; and original bp
	pop	ax			; restore entire task context from scbtcbps
	call	switchgp		; switch calling task's RAM & all else
	call	okswitch
	mov	[scbnotsl],'N'		; allow task and ram switching
	xor	ax,ax
	jmp	short mf89300		; return to caller
mf89200:
	mov	ax,invprm		; no calling yourself through this routine.
mf89300:				; this is a respectable operating system.
	callmos2 moserror		; set error flags
	ret
mosext09 endp

	subttl	mosext0a - allocate memory from heap
	page
;=======================================================================
;,fs
; mosext0a - api fun 0a - allocate memory from heap
; 
; this function will allow programs to have access to the heap.
; it allows the caller to use the full complement of mosheman functions,
; except the init call
; 
; in:	 tal = request code - 0=allocate, 1=deallocate, 2=shrink block
; 	       3= % usage
; 	 tdx = size requested, in paragraphs (allocate and shrink)
; 	 tes = address of block (deallocate and shrink)
; 
; out:	 tal = exit code,0 = successful
; 			 1 = requested size not available (allocate only)
; 			 2 = bad block address (deallocate and shrink)
; 			 3 = unknown command
; 	 tdx = number of paragraphs allocated (allocate and shrink)
; 	       (or # available, 0 if no heap space at all)
; 	 tes = address of block (allocate and shrink), undefined if error
; 
;        for tal = 3 -> tax = formated ascii % value al=high digit, ah=low
; 	       tbx = integer % value (for calculations)
; 
; the ax, dx and es registers are modified as documented.  in
; the case of an error es is undefined.  all other
; registers are preserved.
; 
;,fe
;======================================================================^
	assume	ds:grp,ss:tcb,es:nothing
mosext0a proc	near
	push	bx

; pointer to block to be modified if not an allocation call.
; in that case the es that the user sends should be pointing to
; paragraph 2 of the block. this needs to be adjusted before you call
; mosheman.

	mov	ax,[tes]
	dec	ax
	mov	es,ax

; get function code and set hi byte to low bytes because the
; low byte contains the operation that mosheman should perform

	mov	ax,[tax]
	mov	ah,al
	mov	al,0
	mov	dx,[tdx]		; number of requested paragraphs
	inc	dx			; add 1 to handle the header
	call	mosheman
	dec	dx			; dec returned # to accomodate header
	mov	bx,es			; ----\    make es point to the second paragraph
	inc	bx			; -------  of the returned block.
	mov	[tes],bx		; ----/
	mov	[tax],ax		; return error code
	mov	[tdx],dx		; number of paragraphs allocate/free
	pop	bx
	ret
mosext0a endp

	subttl	mosext0b - add/remove devices on the fly
	page
;=======================================================================
;,fs
; mosext0b - api fun 0b - add/remove devices on the fly
; 
; this function allows for a device driver to be loaded up in memory
; that has been allocated via the 8ah call and install the driver and
; add the driver to the device driver chain.  the inverse of this call
; allows for special drivers to be removed from memory and their memory
; to be deallocated as well as removing them from the dd chain.  the
; call to remove device driver call will send a code to the device
; that tells the driver it is about to be removed and that it should
; do eoj housekeeping.
; 
; in:	tes:tbx-> location of device driver
; 	tds:tdx-> device driver arguments
; 	tal = function selector:
; 	 0 - add device to scbdrvr list (smp)
; 	 1 - remove device from scbdrvr list
; 	 2 - add device to tcbddpf list (task memory)
; 	 3 - remove device from tcbddpf list
; 
; out:	tal-> 0 if ok 1 if there was an error
; 	tdx-> next available memory segment
; 
;,fe
;======================================================================^
	assume	ds:grp,ss:tcb,es:nothing
public	mosext0b
lproc	mosext0b
lstring ddname,8
lword	ddseg
lword	ddoff
lword	ddparmoff
lword	ddparmseg

	jmp	short mf8bskp

; this is a table of the gfb filenames that should have their device
; driver address changed if the dd being installed is of the same name.

mf8bnames  db	'CON     '
	   db	'AUX     '
	   db	'PRN     '
	   db	'CLOCK$  '
	   db	'NUL     '

mf8bskp:
	call	noswitch
	push	ds
	mov	si,bp
	mov	bp,[bp]
	mov	ax,[tax]
	mov	bx,[tbx]
	mov	cx,[tcx]
	mov	dx,[tdx]
	mov	es,[tes]
	mov	ds,[tds]
	mov	bp,si
	mov	[ddseg],es		; save pointer to device driver
	mov	[ddoff],bx
	mov	[ddparmoff],dx		; save pointer to parameter line
	mov	[ddparmseg],ds
	push	cx
	test	al,0			; if bit 0 = 0 then al = 0 or 2
	jz	mf8badd 		; so jump to add device routine
	jmp	mf8brem 		; else jump to remove routine
mf8badd:
	mov	si,0ffffh		; reset block device flag
	test	word ptr es:[bx+4],8000h; is this a block device?
	jnz	mf8bdochar		; no, jump next thing
	mov	si,0			; yes, set flag

; this routine checks the list of gfb's if the device is a character
; device.  otherwise we skip this routine and do the mf8binstall routine.

mf8bdochar:
	push	si
	cmp	si,0ffffh		; see if character device flag is set
	jz	mf8b0001		; yes, it is a character device
	jmp	mf8binstall		; no, go do the install procedure
mf8b0001:
	mov	cx,8			; yes, set cx to number of characters in dd name
	lea	di,ddname		; load the di with the address of local variable
	mov	si,10			; set si to offset in device driver where name is
	push	ds
	push	ds
	pop	es
	mov	ds,[ddseg]		; get dd's segment
	cld
	rep	movsb			; move dd name
	pop	ds
	assume	ds:grp
	push	es
	push	ds
	push	ss
	push	cs
	pop	ds
	pop	es			; zero counter for number
	mov	cx,0			; of elements in gfb name list(5)
mf8boutlp:
	mov	ax,8			; size of each element in the list
	mul	cx			; ax * the number of the element
					; we are now comparing to get a table offset
	mov	bx,ax			; save out the result
	lea	si,mf8bnames		; load si with the address of the beginning of
					; the list
	add	si,bx			; add table offset to base of table
	lea	di,ddname		; load di with the address of the dd's name
	push	cx
	mov	cx,8			; set cx to number of characters to compare
	cld
	rep	cmpsb
	pop	cx
	jz	mf8bfnd 		; did we find a match? if yes jump out
	inc	cx			; nope check the next name in the list.
	cmp	cx,5			; have we checked the entire list?
	jz	mf8bnot1		; yep leave this place.
	jmp	short mf8boutlp 	; nope, let us run through it again.
mf8bfnd:

; restore ds - ** warning there are two pops for the one push of
; ds but it should only go through one or the other.

	pop	ds
	pop	es
	jmp	short mf8b0002		; go change the corresponding gfb
mf8bnot1:
	pop	ds

; restore ds - ** warning there are two pops for the one push of
; ds but it should only go through one or the other.

	pop	es
	jmp	short mf8binstall
mf8b0002:
	mov	ax,[scbgfbpf]		; load ax with pointer to first gfb
	cmp	ax,0			; is it a null pointer?
	jz	mf8bno_gfb		; yes, jump out of routine there is no gfb's
	push	ds
	push	ss
	pop	es
mf8bgfblp:				; this is a loop to check all of the gfbs
	lea	di,ddname		; set di to point to variable holding dd name
	mov	ds,ax			; set ds to point to the gfb segment
	assume	ds:gfb			; assume ds points to gfb
	lea	si,gfbname		; load si with offset of gfbname
	mov	cx,8			; load cx with number of characters to compare
	cld
	rep	cmpsb
	mov	bx,ax			; set bx to point to current gfb
	mov	ax,[gfbnext]		; load ax with pointer to next gfb
	pop	ds
	jnz	mf8bnot_same		; these two were not the same
	jmp	mf8berrdup		; we had a duplicate name
mf8bnot_same:
	cmp	ax,0			; does ax point to the next gfb
	jnz	mf8bnnn1		; yes, go back into the loop
	pop	si
	jmp	mf8binstall		; nope go install the driver.
mf8bnnn1:
	push	ds
	jmp	short mf8bgfblp 	; jump back into loop
mf8berrdup:
	push	ds
	mov	ds,bx			; set ds to segment address of current gfb
	assume	ds:gfb
	mov	cx,[ddoff]		; set cx to device driver's offset
	mov	word ptr [gfbdrvr],cx	; plug that address into the correct gfb
	mov	cx,[ddseg]		; set cs to dd's segment
	mov	word ptr [gfbdrvr+2],cx ; plug that address into the correct gfb
	pop	ds
	jmp	short mf8binstall	; now go install the dd
mf8bno_gfb:
	mov	ah,'C'			; error is given if a gfb cannot be found
	mov	al,'2'
	jmp	mf8blver		; exits without setting ax to 0

; call mosddint to link the driver in and get it initialized

mf8binstall:
	push	si			; save flag showing whether or not
	mov	bx,[ddoff]		; this dd is a character device.
	mov	es,[ddseg]		; set es:bx -> device driver
	mov	dx,[ddparmoff]		; set ds:dx -> parameter line
	mov	ds,[ddparmseg]
	mov	si,bp
	mov	bp,[bp]
	mov	ax,[tax]		; if tal = 0 -> al = 0 (scbdrvr link)
	mov	bp,si
	shr	al,1			; if tal = 2 -> al = 1 (tcbddpf link)
	call	mosddint		; call the initialization routine
	pop	si			; restore flag
	pop	cx
	pop	ds
	assume	ds:grp,ss:tcb,es:nothing
	or	al,al
	ljnz	mf8blver
	cmp	si,0			; is this a block device?
	ljnz	mf8blv

; this routine is only run if si is a 0 which means that it is a block
; device.  it creates a cdb for each active tcb

	mgetscb ds
	assume	ds:grp
	mov	ax,[scbtcbpf]		; set ax to point to the first tcb
	mov	bx,ss
	mov	si,ss
	mov	di,sp
mf8blp:
	or	ax,ax			; is there another tcb?
	jz	mf8bgood		; nope, good-bye
	mov	es,ax			; set es to point to that tcb
	assume	es:tcb
	cli
	mov	ss,ax			; set stack segment to tcb segment
	assume	ss:tcb
	mov	sp,[tcbsp]		; load sp with tcb's SP
	sub	sp,128			; buffer stack
	sti
	cmp	ax,bx			; is this tcb the current tcb?
	je	mf8bnext		; yes, skip this next step.
	push	es			; nope, save es
	mov	ah,0			; set ah to add function for mosliman
	mov	al,'C'			; set al to type block to add
	call	mosliman		; call mosliman

; this routine initialize the cdb that was just created

	push	ax
	push	ds
	mgetscb ds
	assume	ds:grp
	mov	ds,[scbbdbpl]		; set ds to the pointer to the last bdb
	assume	ds:bdb,es:cdb
	mov	al,[bdbid]		; get its id in al
	mov	[cdbdrive],al		; set the cdb's drive designator to the ID
	mov	[cdblvl],3		; set level to 3
	mov	[cdbpath],0		; set path to 0 - root directory
	mov	[cdbclus],0		; set cluster to 0
	pop	ds
	pop	ax
	pop	es
	assume	es:tcb,ss:nothing
mf8bnext:
	mov	ax,[tcbtcbpn]		; set ax to point to the next tcb
	jmp	mf8blp			; jump back in the loop
mf8bgood:
	cli
	mov	ss,si			; restore ss:sp to current tcb
	mov	sp,di
	sti
	jmp	short mf8blv		; let's go home
mf8brem:

; reserved for remtask

mf8blv:
	mov	ax,0			; if everything is ok return ax as 0
mf8blver:
	mov	si,bp
	mov	bp,[bp]
	mov	[tax],ax		; return error code
	mov	[tdx],dx		; and next free segment
	mov	bp,si
	pop	ds
	call	okswitch
mf8bbye:
lundef ddname
lundef ddseg
lundef ddoff
lundef ddparmoff
lundef ddparmseg
lendp	mosext0b

	subttl	mosext0c - resize current task's memory
	page
;=======================================================================
;,fs
; mosext0c - api fun 0c - resize current task's memory
; 
; this routine resizes the current task memory size.  if able it
; it will add or remove memory space neccessary to addjust for
; the change in memory size.
; 
; in:	tah = 8ah
; 	tbx = partition size to set to current task, in kilobytes
; 
; out:	tax = error code if carry set
; 
;,fe
;======================================================================^
	assume	ds:grp, ss:tcb, es:nothing
public	mosext0c
lproc	mosext0c
lword	mbptr
lword	mblen
lword	size8c

	mov	ax,insmem
	cmp	[scbmmfg],'Y'		; memory management
	je	mf8cont
	jmp	mf8cexit
mf8cont:
	mov	cx,bp
	mov	bp,[bp]
	mov	bx,[tbx]		; get request partition size
	mov	bp,cx
	push	bx
	mov	cl,6
	shl	bx,cl
	mov	cx,bx
	add	cx,[tcbbegad]
	pop	bx
	mov	dx,0b000h		; sah maximum of 704h for vtype > 0

	test	[scbvtype],7fh		;#jrb (ignoring high bit)
	jnz	mf0cvok 		;#jrb
	mov	dx,0a000h		; sah maximum of 640h for vtype = 0
mf0cvok:
	cmp	cx,dx
	jbe	mf8cxx
	jmp	mf8cexit
mf8cxx:

	mov	ax,[tcbendad]
	sub	ax,[tcbbegad]
	mov	[size8c],ax

; find last mcb block and return size in k in cx

	push	es
	mov	ax,[tcbmbpf]		; get first mcb
mf8c00:
	mov	es,ax
	assume	es:mbseg
	mov	cx,[mbsize]
	cmp	[mbtype],'Z'		; is this last block
	je	mf8c01
	inc	ax
	add	ax,cx			; position to next prefix
	jmp	mf8c00
mf8c01:
	mov	[mbptr],es
	mov	[mblen],cx
	pop	es
	assume	es:nothing
	mov	ax,[size8c]
	sub	ax,cx
	mov	cl,6
	shr	ax,cl
	cmp	bx,ax
	ja	mf8c02
	mov	ax,invdata
	jmp	mf8cexit
mf8c02:
	mov	cx,bx
	sub	cx,ax
	mov	ax,invdata
	cmp	cx,16			; mimimun of  16k free partition space
	jae	mf8c02a
	jmp	mf8cexit
mf8c02a:
	mov	ax,[size8c]
	mov	cl,6
	shr	ax,cl
	add	bx,3			; convert request to rounded up pages
	shr	bx,1
	shr	bx,1
	add	ax,3			; convert actual to rounded up pages
	shr	ax,1
	shr	ax,1
	cmp	bx,ax
	jne	$+5
	jmp	mf8cskip
	mov	[scbnotsl],'Y'
	call	noswitch		; no bank switching
	cmp	bx,ax
	jb	$+5
	jmp	mf8cadd

; remove memory memory from task space

	sub	ax,bx			; pages to remove
	mov	dx,ax			; save it
	xor	bx,bx
mf8c10:
	cmp	word ptr [bx+tcbmmpgs],0; find last allocate frag
	je	mf8c11
	add	bx,2
	cmp	bx,8
	jb	mf8c10
mf8c11:
	or	bx,bx			; internal error - nothing allocated
	jnz	mf8c11a
	jmp	mf8cint
mf8c11a:
	sub	bx,2
	cmp	[bx+tcbmmpgs],ax
	ja	mf8c12
	mov	cx,[bx+tcbmmpgs]
	push	ax
	push	bx
	push	cx
	mov	bx,[bx+tcbmmhdl]
	mov	ah,2			; free memory
	call	[scbmmsub]
	pop	cx
	pop	bx
	or	ax,ax
	jnz	mf8cint1
	mov	[bx+tcbmmpgs],ax	; zero out fragment pages
	mov	[bx+tcbmmhdl],ax	; zero out fragment handle
	pop	ax
	sub	ax,cx			; adjust count for next update
	jnz	mf8c11
	jmp	short mf8c13		; all done for this request
mf8c12:
	mov	cx,[bx+tcbmmhdl]	; get handle
	add	cx,[bx+tcbmmpgs]	; add pages
	push	ax
	push	bx
	sub	cx,ax			; calculate start handle
	mov	bx,cx
	mov	cx,ax			; # of pages to free
	mov	ah,2			; free memory
	call	[scbmmsub]
	pop	bx
	or	ax,ax
	jnz	mf8cint1
	pop	ax
	sub	[bx+tcbmmpgs],ax	; subtract free pages from allocated
mf8c13:
	xchg	dl,dh
	mov	ax,[tcbendad]
	cmp	dx,ax			; paragraphs remove greater available
	ja	mf8cint 		; internal error
	sub	ax,dx
	mov	dx,[tcbbegad]
	cmp	ax,dx			; end address < start address
	jb	mf8cint 		; internal error
	xor	dh,dh			; adjust for begin address
	add	ax,dx
	mov	[tcbendad],ax		; save it
	jmp	mf8cpsp 		; all done
mf8cint1:
	pop	ax

mf8cint:

; internal error

	call	bugerror
	db	'0C '
	db	'error resizing task      ',00h  ;@@xlat

mf8cadd:

; add memory to task space

	xchg	bx,ax
	sub	ax,bx			; pages needed to add
	mov	dx,ax
	xor	bx,bx
mf8c20:
	cmp	word ptr [bx+tcbmmpgs],0; scan for last free
	je	mf8c21
	inc	bx
	inc	bx
	cmp	bx,8
	jb	mf8c20
mf8c21:
	dec	bx
	dec	bx
	mov	di,ax			; save pages allocated
mf8c22:
	mov	cx,ax
	push	ax
	push	bx
	mov	ah,1			; allocate memory
	call	[scbmmsub]
	or	ax,ax			; error in memman - insuficent memory
	jnz	mf8c23
	or	cx,cx			; nothing return - insufient memory
	jz	mf8c23a
	mov	si,bx			; save handle
	pop	bx
	pop	ax
	mov	ax,[bx+tcbmmhdl]
	add	ax,[bx+tcbmmpgs]
	cmp	ax,si			; test for consective memory space
	jne	mf8c24			; quess not
	add	[bx+tcbmmpgs],cx
	jmp	short mf8c27
mf8c23:
	mov	ah,2
	call	[scbmmsub]		; free bad stuff out
mf8c23a:
	pop	bx
	pop	ax
	mov	ax,insmem		; indicate insufient memory
	jmp	short mf8c25
mf8c24:
	inc	bx			; next handle (up po maximun of 4)
	inc	bx
	cmp	bx,8
	jb	mf8c26
	mov	ax,general		; general error - fragment memory
mf8c25:
	call	okswitch
	mov	[scbnotsl],'N'		; bank switching ok
	jmp	short mf8cexit
mf8c26:
	mov	[bx+tcbmmhdl],si
	mov	[bx+tcbmmpgs],cx
mf8c27:
	cmp	cx,di
	jae	mf8c28
	sub	di,cx			; adjust for next allocation
	mov	ax,dx
	jmp	short mf8c22
mf8c28:
	mov	ax,[tcbendad]
	xchg	dl,dh
	add	ax,dx
	mov	[tcbendad],ax		; save new end address
mf8cpsp:
	push	es

; update memory control block

	mov	bx,[size8c]		; get original size
	sub	bx,[mblen]		; subtract size off last mcb
	mov	ax,[tcbendad]
	sub	ax,[tcbbegad]		; calculate new size
	sub	ax,bx
	mov	es,[mbptr]
	assume	es:mbseg
	mov	[mbsize],ax
	assume	es:nothing

; adjust task psp for memory change

	mov	bx,[tcbpsp]		; get current psp
	mov	cx,[tcbendad]
mf8c30:
	mov	es,bx
	mov	ax,bx
	mov	es:[2h],cx
	mov	bx,es:[16h]		; get parent
	cmp	bx,ax
	jne	mf8c30
	pop	es
	call	okswitch
	mov	[scbnotsl],'N'		; bank switching ok
mf8cskip:
	xor	ax,ax			; all ok
mf8cexit:
	mov	bp,[bp]
	callmos2 moserror		; set error flags

lundef	mbptr
lundef	mblen
lundef	size8c
lendp	mosext0c

	subttl	mosext0d - get, set, delete alias drive
	page
;=======================================================================
;,fs
; mosext0d - api fun 0d - get, set, delete alias drive
; 
; allows 3 functions:	1) get alias definition for a drive
; 			2) create alias definition for drive
; 			3) remove alias definition
; 
; in:	tal = 0 to get alias for drive
; 	    = 1 to set alias for drive
; 	    = 2 to delete alias for drive
; 	tdl = 1-based drive number for alias drive
; 	tds:tsi -> 64 byte buffer for alias (alias to set if al = 1)
; 
; out:	tcy set if error, tax set to error code
; 	if tcy clear, no registers changed
; 	tds:tsi -> 64 byte max alias definition if tal = 0
; 
; ds, cs, ss, bp, sp preserved, all others undefined
; 
;,fe
;======================================================================^
	assume	ds:grp,ss:tcb,es:nothing
public	mosext0d
lproc mosext0d
lbyte	drive				; drive id number
lbyte	class				; default file class for caller
lword	realbdb 			; bdb pointer for real disk
lword	newbdb				; bdb pointer for alias
lword	cdbptr				; segment address of new cdb for create
lword	rclust				; cluster of "root"
lword	error				; error return value
ldword	alias				; pointer to caller's alias string
lword	aliasseg			; segment for mos alias string
lstring secbuf,<size sectorblk> 	; buffer for directory sector number
lstring fnm,11				; directory format name of directory file
lbyte	pathdrv 			; drive number from alias path

	push	ds			; we change ds
	call	noswitch		; allow no task switching in here
	mov	bx,bp			; get task registers
	mov	bp,[bp]
	mov	ah,[tal]		; subfunction code
	mov	al,[tdl]		; drive number
	mov	di,[tsi]		; alias buffer
	mov	es,[tds]		; "     "
	mov	bp,bx			; back to local variables
	dec	al			; convert from 0=default, 1=a
	jns	mf8d10
	mov	al,[tcbcdriv]		; to 0=a, 1=b, etc.
mf8d10:
	mov	[drive],al		; remember alias drive
	cmp	ah,1			; create alias doesn't need existing BDB
	je	mf8d30			; jump to dispatcher if so

; find drive's BDB.

	mov	cx,[scbbdbpf]		; first bdb
	mov	[error],drivenf 	; assume no drive
mf8d20:
	or	cx,cx
	jmpz	mf8dx			; if drive number invalid
	mov	ds,cx
	assume	ds:bdb
	mov	cx,[bdbnext]
	cmp	al,[bdbid]
	jne	mf8d20

; make sure this is an aliased drive.

	cmp	[bdbalias],0		; is this an alias drive?
	jmpe	mf8dx			; if not an alias drive, invalid
	mov	bx,ss
	cmp	bx,[bdbtask]		; is right alias for this task?
	jne	mf8d20			; if not right one

; get alias definition for drive letter.

mf8d30:
	xchg	al,ah
	or	al,al			; get alias?
	jnz	mf8d50			; if not get alias for drive
	mov	ds,[bdbalias]		; ds:si will be pointer to alias string
	mov	[aliasseg],es		; store pointer to alias string
	mov	si,10h
mf8d40:
	lodsb
	stosb
	or	al,al
	jnz	mf8d40
	mov	[error],0		; no error, return to caller
	jmp	mf8dx

; create alias definition for drive letter.

mf8d50:
	dec	al			; create alias?
	jmpnz	mf8d290 		; if not create alias
	mov	al,ah
	mov	word ptr [alias],di
	mov	word ptr [alias+2],es	; store alias pointer

; validate path for alias drive.

	mov	[error],pathnf
	lea	bx,[secbuf]		; buffer for sector number of dir
	lea	si,[fnm]		; buffer for file name
	les	di,[alias]		; pointer to alias string
	mov	al,1			; skip labels
	callmos2 pathfind		; find the directory
	jmpc	mf8dx			; if couldn't find dir
	assume	ds:bdb,es:dbb
	cmp	al,'?'
	jmpe	mf8dx			; no wild-cards allowed
	or	bx,bx
	jmpz	mf8dx			; device isn't a directory
	inc	dx			; check for root directory
	jz	mf8d60			; if it's the drive's root directory
	test	[dbbbuf+si+datr],dir
	jmpz	mf8dx			; not a directory
	mov	[error],accdeny
	cmp	cl,2			; must have read access to parent dir
	jmpb	mf8dx
mf8d60:
	or	dx,dx			; drive's root?
	jz	mf8d70			; if the root
	mov	dx,word ptr [dbbbuf+si+dclust]
	jmp	short mf8d80		; contine with processing
mf8d70:
	mov	dx,[bdbroot]		; root directory of desired device
mf8d80:
	mov	[rclust],dx
	mov	al,byte ptr [dbbbuf+si+dclass0]
	mov	[class],al		; file class for calling task
	mov	al,[bdbid]		; id of path's drive
	mov	[pathdrv],al

; save the "real" bdb.

	mov	ax,[bdbreal]		; segment address of the "real" one
	mov	[realbdb],ax

; find bdb for alias drive.

	mov	[error],drivenf 	; assume drive not found error
	mgetscb ds
	assume	ds:grp
	mov	cx,[scbbdbpf]		; first bdb
	mov	al,[drive]		; id for alias drive
mf8d90:
	jcxz	mf8d100 		; if no drive with this number
	mov	ds,cx
	assume	ds:bdb
	mov	cx,[bdbnext]
	cmp	al,[bdbid]
	jne	mf8d90			; if no drive found yet
	cmp	al,2			;jsm if drive a or b, allow replacement
	jae	mf8d94			;jsm if not drive a or b
	cmp	[bdbalias],0		;jsm currently unaliased?
					; allocate bdb cdb and aliasseg 	890308
	jmpe	mf8d100 		;jsm yes, give it alias for first time
	mov	bx,ss			;jsm
	cmp	bx,[bdbtask]		;jsm right task?
	jne	mf8d90			;jsm if wrong task
	jmp	mf8d97			; free current and allocate again?	890308
mf8d94: 				;jsm
	cmp	[bdbalias],0		; null alias pointer?
	jmpe	mf8dx			; if not really an alias drive
	mov	bx,ss			; it's an alias drive, but ....
	cmp	bx,[bdbtask]		; right task for alias drive?
	jne	mf8d90			; if wrong task

; found an existing alias bdb for drive.

mf8d97:
	mov	[newbdb],ds		; bdb pointer
	mov	bx,[bdbalias]		; pointer to alias string
	mov	[aliasseg],bx		; store it
	call	freeblocks		; free the existing blocks
	jmpc	mf8dx			; if error freeing the blocks

; allocate bdb, cdb, alias block for alias drive.

mf8d100:
	mov	[error],insmem		; assume error is not enough memory
	mgetscb ds
	assume	ds:grp, es:nothing
	mov	ax,0 or 'B'		; allocate bdb block
	call	mosliman
	or	al,al			; memory there ok?
	jmpnz	mf8dx			; if no memory
	assume	es:bdb
	mov	[newbdb],es		; save bdb pointer
	mov	[bdbalias],0		; don't look for others on chain
	cmp	[drive], 2		; floppy aliases must be before real
	jge	mf8d105
	lea	si, scbbdbpf		; moved for special floppy code r890308
	lea	di, scbbdbpl		;				r800308
	call	firstbdb		; move the block to beginning of list
mf8d105:
	mov	ax,0 or 'C'		; allocate cdb block
	call	mosliman
	or	al,al
	jz	mf8d110 		; if no error
	call	fb140			; if error
	jmp	mf8dx
mf8d110:
	mov	ds,[newbdb]		; bdb for alias
	mov	[cdbptr],es		; store pointer to cdb
	assume	ds:bdb, es:cdb
	mov	al,[drive]		; drive id for cdb
	mov	[cdbdrive],al		; set id so we can find cdb later
	mov	dx,(67 / 16) + 2	; get alias buf from mosheman
	xor	ax,ax
	call	mosheman
	or	al,al			; did we get the memory?
	jz	mf8d120 		; if we got the memory
	call	fb110			; if we didn't get the memory
	jmp	mf8dx
mf8d120:
	mov	[aliasseg],es		; store pointer to alias string
	jmp	mf8d140 		; copy old bdb to new bdb
mf8d130:
	call	freeblocks		; free the blocks
	jmp	mf8dx			; quit

; copy contents of old bdb to new bdb

mf8d140:
	mov	ds,[realbdb]
	mov	es,[newbdb]
	assume	ds:bdb, es:bdb
	mov	di,10h			; destination for copy
	mov	si,di			; ds:10 is where to copy from
	mov	cx,bdblen - 10h 	; how much to copy
	rep	movsb

; set up alias bdb properly.

	mov	ds,[newbdb]		; bdb for alias drive
	mov	ax,[rclust]		; root cluster
	mov	[bdbroot],ax		; root cluster for drive
	mov	es,[aliasseg]		; segment for alias block
	mov	[bdbalias],es
	mov	ax,[realbdb]
	mov	[bdbreal],ax		; store pointer to real bdb
	mov	ax,ss
	mov	[bdbtask],ax		; store tcb pointer (task specific)
	mov	al,[drive]
	mov	[bdbid],al		; drive id number for searches
	mov	[bdbanxt],0		; make sure its next pointer is 0

; put this bdb on the end of the alias chain.

	mov	cx,[realbdb]		; real bdb for alias chain
mf8d150:
	jcxz	mf8d160 		; if no more alias drives
	mov	ds,cx
	mov	cx,[bdbanxt]
	jmp	mf8d150 		; next one in chain
mf8d160:
	mov	ax,[newbdb]		; put the new alias
	mov	[bdbanxt],ax		; on the end of the chain
					; new bdb has bdbanxt of 0 now
; copy alias string.

	mov	[error],pathnf		; bad path if error now

; es is already set here.

	mov	di,010h 		; destination for alias
	lds	si,[alias]
	assume	ds:nothing
	cmp	byte ptr [si+1],':'	; is there a drive id?
	jz	mf8d170 		; if already a drive id
	mov	al,[pathdrv]		; drive id from pathfind
	add	al,'A'			; convert id to letter
	stosb				; & put in alias definition
	mov	al,':'
	stosb
	jmp	mf8d180 		; check for path now
mf8d170:
	lodsw
	call	caps			; capitalize drive id
	stosw				; copy the drive id to alias
mf8d180:
	mov	cx,64			; max length for alias

; check for path.

	cmp	byte ptr [si],'\'	; do we need current path?
	je	mf8d220 		; if path is rooted

; copy current path into alias definition.

	mov	al,[pathdrv]
	mov	dx,[tcbcdbpf]		; find current cdb
	push	ds
	assume	ds:cdb
mf8d190:
	or	dx,dx
	jz	mf8d210
	mov	ds,dx			; next cdb
	mov	dx,[cdbnext]
	cmp	al,[cdbdrive]		; right cdb?
	jne	mf8d190 		; if the wrong one

; found the cdb.

	push	si			; save alias pointer
	lea	si,[cdbpath]		; where the path lives
mf8d200:
	lodsb
	stosb
	or	al,al			; end of path yet?
	loopnz	mf8d200 		; if not done yet
	pop	si			; restore alias pointer
	pop	ds			; and alias segment
	or	cx,cx
	jmpz	mf8dx			; if too many characters
	dec	di			; to make up for last stosb
	jmp	short mf8d220		; do rest of copy
mf8d210:
	pop	ds
	mov	[error],intern
	jmp	mf8dx			; bizarre error - bdb w/no cdb

; copy the alias string, accounting for \.\ & \..\ combinations.

	assume	ds:nothing
mf8d220:
	lodsb
	cmp	al,'.'			; any funny stuff?
	jne	mf8d270 		; if no funny stuff
	mov	al,[si]
	callmos2 slash			; .\ pair?
	jne	mf8d230 		; if not .\ pair
	inc	si			; if .\ pair, skip over the \
	jmp	mf8d220 		; do the next thing
mf8d230:
	cmp	al,'.'			; .. pair?
	je	mf8d240 		; if .. pair, scan backwards
	mov	al,'.'			; lone dot
	jmp	short mf8d270		; process it normally

; on ..\ scan backwards to preceding \	or beginning of dir string

mf8d240:
	inc	si			; skip over second .
	dec	cx			; forget previous backslash
	dec	di
	dec	di			; back di past previous \
	mov	bx,cx			; save copy count
	mov	dx,cx
	mov	cx,di
	sub	cx,10h			; max search backwards is current
	mov	al,'\'			; length - initial paragraph
	std
	repne	scasb
	cld
	sub	dx,cx			; how many bytes did we back up
	add	bx,dx			; that's how much more space we have
	mov	cx,bx			; set counter back
	inc	di			; onto found \ (or to beg. of path)
	lodsb
	dec	cx			; account for copied character
	jnz	mf8d250
	inc	cx
mf8d250:
	or	al,al
	jz	mf8d260
	mov	al,'\'			; must be \ if not 0
	jmp	short mf8d270
mf8d260:
	cmp	byte ptr es:[di-1],':'
	jne	mf8d270 		; if not at root
	inc	di			; at root, keep terminal backslash
mf8d270:
	call	caps			; convert char to upper case
	stosb
	or	al,al			; end of string?
	loopnz	mf8d220 		; if not, continue
	jmpnz	mf8d130 		; if string too long, return blocks

; set up cdb.

	mov	ds,[cdbptr]
	assume	ds:cdb
	mov	al,[drive]
	mov	[cdbdrive],al		; drive id
	mov	ax,[rclust]		; root directory cluster
	mov	[cdbclus],ax
	mov	al,[class]
	callmos2 classlvl		; get access to "root" directory
	mov	[cdblvl],al
	xor	ax,ax			; use zeroes a lot
	mov	[cdbpath],al		; set directory to "root"
	mov	[error],ax		; no error
	jmp	short mf8dx

; delete alias definition for drive letter.

	assume	ds:bdb,ss:tcb,es:nothing
mf8d290:
	dec	al			; delete alias?
	jnz	mf8d300 		; if not delete alias
	mov	[error],0		; assume all goes ok
	mov	[newbdb],ds		;jsm set up local variables
	mov	bx,[bdbalias]		;jsm pointer to alias string
	mov	[aliasseg],bx		;jsm store it
	jmp	mf8d130 		; free all of the blocks
mf8d300:
	mov	[error],badcmd		; if bad subfunction code
mf8dx:
	assume	ds:nothing, es:nothing
	call	okswitch		; start switching again
	pop	ds
	mov	ax,[error]		; get error return value
	mov	bx,bp
	mov	bp,[bp] 		; to task registers
	callmos2 moserror		; set error codes
	jmp	mf8dx2			; leave function

	subttl freeblocks - free all blocks for alias
	page
;=======================================================================
;,fs
; freeblocks - free all blocks for alias
; 
; in:	?
;
; out:	?
;
;,fe
;======================================================================^
	assume	ds:nothing, es:nothing
freeblocks proc near
	mov	es,[aliasseg]
	mov	ah,1			; free the alias block
	call	mosheman
	jnc	fb110			; if no error
	mov	[error],intern
	jmp	short fbx		; exit with error
fb110:
	mov	cx,[tcbcdbpf]		; find our cdb
	mov	al,[drive]
fb120:
	jcxz	fb130
	mov	ds,cx
	assume	ds:cdb
	mov	cx,[cdbnext]
	cmp	al,[cdbdrive]
	jne	fb120
	push	ds
	pop	es			; cdb pointer in es
	mgetscb ds
	mov	ax,1 * 256 or 'C'
	call	mosliman		; free the cdb
	jnc	fb140			; if no error
fb130:
	mov	[error],intern
	stc
	jmp	short fbx
	assume	ds:nothing, es:bdb
fb140:
	mov	es,[newbdb]		; free bdb
	cmp	[bdbalias],0		; should we look on alias chain?
	jz	fb160			; if it was newly allocated.
	call	remalbdb		; remove bdb from alias chain
fb160:
	mov	es,[newbdb]
	mgetscb ds
	mov	ax, 1 * 256 or 'B'
	call	mosliman
	jnc	fbx			; if no error
	mov	[error],intern
fbx:
	ret
freeblocks endp

	subttl remalbdb - remove alias bdb from alias chain
	page
;=======================================================================
;,fs
; remalbdb - remove alias bdb from alias chain
; 
; in:	es points to the alias to remove from chain
; 
; out:	none
; 
; ax, cx changed
; 
;,fe
;======================================================================^
	assume	ds:bdb
remalbdb proc near
	push	ds
	mov	ax,es
	mov	ds,ax
	mov	cx,[bdbreal]
remal10:
	jcxz	remal20 		; if no more blocks
	mov	ds,cx
	mov	cx,[bdbanxt]
	cmp	cx,ax			; the block linked to one to free?
	jne	remal10 		; if not
	mov	ax,es:[bdbanxt] 	; next pointer of block to free
	mov	[bdbanxt],ax		; link parent to grandchild
remal20:
	pop	ds
	ret
remalbdb endp

	subttl firstbdb - move a bdb to be first on the bdb list
	page
;=======================================================================
;,fs
; firstbdb - move a bdb to be first on the bdb list
; 
; in:	es points to the bdb to move to the front
; 	si has the address of the first pointer for the list
; 	di has the address of the last pointer for the list
; 
; out:	?
; 
; ax, bx changed
; 
;,fe
;======================================================================^
firstbdb proc near
	push	ds
	mgetscb ds
	assume	ds:grp, es:bdb
	mov	ax,es			; bdb to move to front
	cmp	ax,[si] 		; is block already at front?
	je	firb30			; if block at front now, quit
	cmp	ax,[di] 		; is it at the end?
	jne	firb10			; if not at end
	mov	bx,[bdbprev]
	mov	[di],bx 		; scbxxxpl now points to next-to-last blk
	push	ds
	assume	ds:bdb
	mov	ds,bx
	mov	ds:[bdbnext],0		; next-to-last is now last
	pop	ds
	assume	ds:grp, es:bdb
	jmp	short firb20
firb10:
	mov	bx,[bdbnext]
	mov	ax,[bdbprev]
	push	ds
	mov	ds,bx			; next guy will point to prev
	assume	ds:bdb,es:nothing
	mov	[bdbprev],ax
	mov	ds,ax			; prev guy will point to next
	mov	[bdbnext],bx
	pop	ds
	assume	ds:grp, es:bdb
firb20:
	mov	bx,[si] 		; get old first guy
	mov	[bdbnext],bx		; he's our next guy
	mov	[bdbprev],0		; no one before us
	push	ds
	mov	ds,bx
	assume	ds:bdb,es:nothing
	mov	[bdbprev],es		; update prev of old first
	pop	ds
	assume	ds:grp,es:bdb
	mov	[si],es 		; now we're first
firb30:
	pop	ds
	ret
firstbdb	endp

mf8dx2:

lundef	drive				; drive id number
lundef	class				; default file class for caller
lundef	realbdb 			; bdb pointer for real disk
lundef	newbdb				; bdb pointer for alias
lundef	cdbptr				; segment address of new cdb for create
lundef	rclust				; cluster of "root"
lundef	error				; error return value
lundef	alias				; pointer to caller's alias string
lundef	aliasseg
lundef	secbuf				; buffer for directory sector number
lundef	fnm				; full name of directory file
lundef	pathdrv 			; drive id for path
lendp mosext0d

	subttl	mosext0e - set task priority
	page
;=======================================================================
;,fs
; mosext0e - api fun 0e - set task priority
; 
; in:	es -> tcb
; 	al = priority
; 
; out:	nc tcb set to last in list of given priority
; 	c if es not pointing to tcb or priority not 0-7
; 
; registers changed according to reordlst
; 
;,fe
;======================================================================^
	assume	ds:grp,es:nothing,ss:tcb
mosext0e proc near
	mov	es,[tes]
	cmp	[tcbtype],'T'
	jne	mosf8e1
	mov	al,[tal]
	cmp	al,7
	ja	mosf8e1
	shl	al,1
	call	reordlst
	xor	ax,ax
	jmp	mosf8e2
mosf8e1:
	mov	ax,invfn
mosf8e2:
	callmos2 moserror
	ret
mosext0e endp 

	subttl	mosext0f - special tsl call
	page
;=======================================================================
;,fs
; mosext0f - api fun 0f - special tsl call
; 
; this version of the suspend api call sets tcb0d0f.  this makes
; the suspend logic pay attention to the tcbfwake call.  initially
; used by llnetbios.
;
; in:	same as mosext07
; 
; out:	same as mosext07
; 
;,fe
;======================================================================^
	assume	ds:grp,es:nothing,ss:tcb
mosext0f proc near
	jmp	mosext07
mosext0f endp

        subttl mosext14 - api fun 14 - update/call post chain
        page
;======================================================================
;,fs
; mosext14 - api fun 14 - update/call post chain
;
; this is a non-saver function
;
;               ÚÄ                            Ä¿
;               ³ ÚÄ                           ³
; post_tcb   -->³ ³ es = post_tcb              ³ --> nc if complete
; &post_func -->³ ³ÚÄ if(es:[0] != 'HT')       ³     cy if invalid tcb
; &post_orig -->³ ³³ stc                       ³
;               ³ ³³ ret                       ³
;               ³ ³ÀÄ                          ³
;               ³ ³ pushf                      ³
;               ³ ³ cli                        ³
;               ³ ³ *post_orig = es:[tcbpost]  ³
;               ³ ³ es:[tcbpost] = post_func   ³
;               ³ ³ popf                       ³
;               ³ ³ÚÄ if(post_tcb == [scbpost] ³
;               ³ ³³ call dopost               ³
;               ³ ³ÀÄ                          ³
;               ³ ³ clc                        ³
;               ³ ³ ret                        ³
;               ³ ÀÄ                           ³
;               ÀÄ                            ÄÙ
;
; this api function adds a post function to the tcbpost chain.
; then, if the post_tcb task happens to be the current task,
; the chain of post function is called directly.  otherwise, the 
; post chain will be called the next time the task is switched in.
;
; the post function must preserve all registers.  it must either
; make a far call to the previous post vector (post_orig) and do a
; retf or do a far jump to the previous vector. 
;
; this function was designed for lanlink/netbios but could be used
; in other situations requiring a posting.  it has been designed
; to be callable from an irq handler.  neither this function nor
; dopost enables interrupts.  pushf/cli/popf is used to insure
; interrupts are off when necessary.  dopost calls the post function
; with interrupts disabled.
;
; in:   bx:si -> post function                                  (post_func)
;       cx:di -> dword field to receive current tcbnpost vector (post_orig)
;       dx = seg/sel of tcb for task                            (post_tcb)
;
; out:  nc if complete
;       cy if invalid tcb
;       all other registers preserved
;
;,fe
;=====================================================================
        assume  ds:nothing,es:nothing,ss:nothing
mosext14 proc far
	pop	di
	pushset	ax,ds,es
	mov	es,dx
	assume	es:tcb
	cmp	word ptr es:[0],'TH'
	je	m14a
	stc
	jmp	short m14x
m14a:
	pushf
	cli
	mov	ds,cx
	mov	ax,word ptr [tcbpost]
	mov	[di],ax
	mov	ax,word ptr [tcbpost+2]
	mov	[di+2],ax
	mov	word ptr [tcbpost],si
	mov	word ptr [tcbpost+2],bx
	popf
	push	ds
	mgetscb ds
	assume	ds:grp
	cmp	dx,[scbpost]
	pop	ds
	assume	ds:nothing
	jne	m14b
	call	dopost
m14b:
	clc
m14x:
	popset	ax,ds,es
	retf	2
mosext14 endp

	subttl	mosext16 - set/reset scbidq field for a device driver
	page
;=======================================================================
;,fs
; mosext16 - api fun 16 - set/reset scbidq field for a device driver
; 
; in:	tal = 0 for set scbidq to 0, 1 for set to ffff
; 	tcx - irq number
; 
; out:	tax = 0 for ok
; 	tax = 1 for fail because the port is currently reserved
; 
;,fe
;======================================================================^
	assume	ds:grp,es:nothing,ss:tcb
mosext16 proc near
	mov	al,[tal]
	mov	bx,[tcx]
	sub	bx,2
	shl	bx,1
	mov	dx,bx
	shl	dx,1			; dx = irqnum * 4 (for idqp)
	add	bx,offset [scbidq2]

; first, must check for reservations in the idq table

	cmp	word ptr [bx],0
	je	msx16c			; if idq entry == 0, ok so far
	cmp	word ptr [bx],0ffffh
	jne	msx16d			; if != 0 and != ffff, fail

; now, must check for reservations in the idqp table

msx16c:
	push	bx
	push	es
	mov	es,[scbidqp]
	mov	bx,dx
	mov	cl,4			; this multiplying by 16 is
	shl	bx,cl			; dependant on the fpiq equate
	cmp	word ptr es:[bx],0	; within mos.asm
	pop	es
	pop	bx
	jne	msx16d			; if idqp != 0, fail
	or	al,al
	jz	msx16a
	mov	word ptr [bx],0ffffh
	jmp	msx16b
msx16a:
	mov	word ptr [bx],0
msx16b:
	mov	[tax],0
	jmp	msx16x
msx16d:
	mov	[tax],1
msx16x:
	ret
mosext16 endp

	subttl	mosext17 - declare\undeclare 286 segment
	page
;=======================================================================
;,fs
; mosext17 - api fun 17 - declare\undeclare 286 segment
; 
; declare a 286 data or code segment or undeclare a segment
; this enable mos applications faster operations under 286
; mos because 286 driver will not cause interupts during
; these segment changes
; 
; in:	tal = 00 declare a 286 data segment
;       	    = 01 declare a 286 code segment
;       	    = ff undeclare a 286 segment
;      	tbx = segment to declare or undeclare
; 
; out:	tax = 00 all ok
; 	tax = non-zero (invalid function or memman error)
; 
;,fe
;======================================================================^
	assume	ds:grp,es:nothing,ss:tcb
mosext17 proc near

if	code286
	mov	cl,[tal]
	cmp	cl,0ffh
	je	m17dec
	cmp	cl,2
	jb	m17dec
	mov	ax,invfn		; invalid function
	jmp	m17exit
m17dec:
	xor	ax,ax			; indicate no-errors
	cmp	[scb286dec],'N' 	; does system support 286
	je	m17exit 		; declare calls
	mov	ah,0ah
	mov	bx,[tbx]		; get segment
	call	[scbmmsub]
m17exit:
else
	mov	ax,invfn		; invalid function
endif

	mov	[tax],ax		; return error code in ax
	ret
mosext17 endp

	subttl	mosext18 - flush and invalidate cache for one bdb
	page
;=======================================================================
;,fs
; mosext18 - api fun 18 - flush and invalidate cache for one bdb
; 
; this allows format to operate the way it should
; 
; in:	tdl = 1-based drive (0=default)
; 
; out:	?
; 
;,fe
;======================================================================^
	assume	ds:grp,es:nothing,ss:tcb
mosext18 proc near
	mov	dl,[tdl]
	mov	al,dl
	dec	al
	jns	mos18x1
	mov	al,[tcbcdriv]
mos18x1:
	callmos2 findbdb
	assume	ds:bdb
	jc	mosx18x
	callmos2 flushbdb
	callmos2 invbdb
mosx18x:
	ret
mosext18 endp 

	subttl	mosext19 - return task id of current task
	page
;=======================================================================
;,fs
; mosext19 - api fun 19 - return task id of current task
; 
; in:	?
; 
; out:	tbx = task id of current task
; 	tax = 00h allok
; 
;,fe
;======================================================================^
	assume	ds:grp,es:nothing,ss:tcb
mosext19 proc	near
	mov	ax,[tcbid]		; get task id out of tcb
	mov	[tbx],ax		; return it to user
	mov	[tax],00h		; return all ok
	ret
mosext19 endp

	subttl	gettask - get tcb address based on tcbid value
	page
;=======================================================================
;,fs
; gettask  - get tcb address based on tcbid value
; 
; use internal by function 04 and also by api function to access
; requested tcb address.
;
; NOTE: do not count on bp referencing [tbx], etc. 
;
; in:	bx = tcbid value to search for
;	ds -> grp
;
; out:	ax = 0 if no error
;	 es -> tcb
;	ax != 0 if error
;
;,fe
;======================================================================^
	assume	ds:grp,es:nothing,ss:nothing
gettask proc	near
	cmp	bx,-1			; current task?
	jne	mf8410			; if not current task
	mov	es,[scbtcbpc]
	xor	ax,ax			; no error
	jmp	mf84ex			; exit function & return value

; find tcb with id in bx

mf8410:
	call	noswitch		; following list of tcb's, don't delete any
	assume es:tcb
	mov	ax,[scbtcbpf]		; first tcb on list
mf8415:
	or	ax,ax
	jz	mf84100 		; if end of list
	mov	es,ax
	cmp	bx,[tcbid]		; right tcb?
	jz	mf8420			; if found tcb with given id
	mov	ax,[tcbtcbpn]		; next on list
	jmp	mf8415			; check it out

; found tcb return it to caller

mf8420:
	mov	es,ax			; return tcb address in es
	xor	ax,ax			; return ok value in ax
	jmp	short mf84110		; exit

; no tcb found

mf84100:
	mov	ax,invprm
mf84110:
	call	okswitch		; allow task switching again
mf84ex:
	ret
gettask endp

	subttl	mosext1a - set\read priority
	page
;=======================================================================
;,fs
; mosext1a - api fun 1a - set\read priority
; 
; in: 	tal = 00 = read priority
; 	tal = 01 = set priority
; 	tal = 02 = echange priority
; 	tbx = task id or -1 for current task
; 	tcl = priority to set
; 
; out:	tcl = priority return back
; 
; registers changed according to reordlst
; 
;,fe
;======================================================================^
	assume	ds:grp,es:nothing,ss:tcb
mosext1a proc	near
	mov	bx,[tbx]
	call	gettask 		; get task tcb
	or	ax,ax
	jnz	 mext1aout
	assume	es:tcb,ss:nothing
	mov	al,[tal]		; get subfunction
	or	al,al
	jnz	mext1aa

; read priority subfunction

	mov	al,[tcbpri]		; get priority
	shr	al,1			; must divide by 2
	mov	[tcl],al		; return to user
	jmp	short mext1aok
mext1aa:
	dec	al
	jnz	mext1ab

; set priority subfunction

	mov	al,[tcl]		; get priority from user
	jmp	short mext1aset
mext1ab:
	dec	al
	jnz	mext1aerr

; exchange priority subfunction

	mov	al,[tcl]		; get priority from user
	mov	ah,[tcbpri]		; get current priority from tcb
	shr	ah,1			; must divide by 2
	mov	[tcl],ah		; return priority in tcb to user
mext1aset:
	cmp	al,7
	ja	mext1aerr
	shl	al,1
	call	reordlst
mext1aok:
	mov	[tax],00h
	and	[tflag], not carry
	ret
mext1aerr:
	mov	ax,invfn		; indicate invalid sub-function
mext1aout:
	callmos2 moserror
	ret
mosext1a endp

	subttl	mosext1b - read\set\exchange time slice
	page
;=======================================================================
;,fs
; mosext1b - api fun 1b - read\set\exchange time slice
; 
; in:	tal = 00 = read slice
; 	tal = 01 = set slice
; 	tal = 02 = echange slice
; 	tbx = task id or -1 for current task
; 	tcl = slice to set
; 
; out:	tcl = slice return back
; 
;,fe
;======================================================================^
	assume	ds:grp,es:nothing,ss:tcb
mosext1b proc	near
	mov	bx,[tbx]
	call	gettask 		; get task tcb
	or	ax,ax
	jnz	mext1bout
	mov	al,[tal]
	or	al,al
	jnz	mext1ba

; read slice

	mov	al,[tcbslice]		; get slice from tcb
	mov	[tcl],al		; return to user
	jmp	short mext1bok
mext1ba:
	dec	al
	jnz	mext1bb

; set slice

	mov	al,[tcl]		; get slice value from user
	mov	[tcbslice],al		; save in tcb
	jmp	short mext1bok
mext1bb:
	dec	al
	jnz	mext1berr

; exchange slice

	mov	al,[tcl]		; get slice value from user
	mov	ah,[tcbslice]		; get slice from tcb
	mov	[tcl],ah		; return tcbslice to user
	mov	[tcbslice],al		; save user slice in tcb
mext1bok:
	mov	[tax],00h
	and	[tflag], not carry
	ret
mext1berr:
	mov	ax,invfn		; indicate invalid sub-function
mext1bout:
	callmos2 moserror
	ret
mosext1b endp

	subttl	mosext1c - clear\set\read keyboard mode
	page
;=======================================================================
;,fs
; mosext1c - api fun 1c - clear\set\read keyboard mode
; 
; in:	tal = 00h - set nodis mode
; 	tal = 01h - set dis mode
; 	tal <> 00h or 01h return current state
; 	tbx = task id or -1 for current task
;
; out:	tcl = prevous keyboard state 00h = nodis, 01 = dis mode
; 
;,fe
;======================================================================^
	assume	ds:grp,es:nothing,ss:tcb
mosext1c proc	near
	mov	bx,[tbx]
	call	gettask 		; get task tcb
	or	ax,ax
	jz	mext1ca
	callmos2 moserror
	ret
mext1ca:
	assume	es:tcb,ss:nothing
	mov	ah,[tcbloop]		; get keyboard status
	and	ah,1			; mask out upper bits
	mov	al,[tal]
	or	al,al
	jnz	mext1cb

; set nodis mode

	and	[tcbloop], not 1	; set nodis mode
	jmp	short mext1cout
mext1cb:
	dec	ah
	jz	mext1cout

; set dis mode

	or	[tcbloop],1		; set dis mode
mext1cout:
	mov	[tcl],ah		; return status
	mov	[tax],00h
	and	[tflag], not carry
	ret
mosext1c endp

	subttl	mosext1d - return current program name
	page
;=======================================================================
;,fs
; mosext1d - api fun 1d - return current program name
; 
; in:	tbx = task id or -1 for current task
; 	es:di = 11 byte buffer to place name
; 
; out:	?
; 
;,fe
;======================================================================^
	assume	ds:grp,es:nothing,ss:tcb
mosext1d proc	near
	mov	bx,[tbx]
	call	gettask 		; get task tcb
	or	ax,ax
	jz	mext1da
	callmos2 moserror
	ret
mext1da:
	assume	es:tcb,ss:nothing
	lea	si,[tcbprgnm]
	push	es
	pop	ds
	mov	es,[tes]
	mov	di,[tdi]
	mov	cx,11
	cld
	rep	movsb
	mov	[tax],00h
	and	[tflag], not carry
	ret
mosext1d endp

	subttl	mosext1e - return current user name and security class
	page
;=======================================================================
;,fs
; mosext1e - api fun 1e - return current user name and security class
; 
; in:	tbx = task id or -1 for current task
; 	es:di = 4  byte buffer to place name
; 
; out:	tcl = task security class
; 
;,fe
;======================================================================^
	assume	ds:grp,es:nothing,ss:tcb
mosext1e proc	near
	mov	bx,[tbx]
	call	gettask 		; get task tcb
	or	ax,ax
	jz	mext1ea
	callmos2 moserror
	ret
mext1ea:
	assume	es:tcb,ss:nothing
	lea	si,[tcbuser]
	mov	bx, es
	mov	ds, bx
	assume	ds:tcb,es:nothing
	mov	es,[tes]
	mov	di,[tdi]
	cld
	movsw
	movsw
	mov	al,[tcbclass]
	mov	[tcl],al
	mov	[tax],0
	and	[tflag], not carry
	ret
mosext1e endp

	subttl	mosext1f - return task partion information
	page
;=======================================================================
;,fs
; mosext1f - api fun 1f -  return task partion information
; 
; in:	tbx = task id or -1 for current task
; 
; out:	tcx = begin address
; 	tcx = end address
; 
;,fe
;======================================================================^
	assume	ds:grp,es:nothing,ss:tcb
mosext1f proc	near
	mov	bx,[tbx]
	call	gettask 		; get task tcb
	or	ax,ax
	jz	mext1fa
	callmos2 moserror
	ret
mext1fa:
	assume	es:tcb,ss:nothing
	mov	ax,[tcbbegad]
	mov	[tcx],ax
	mov	ax,[tcbendad]
	mov	[tdx],ax
	mov	[tax],00h
	and	[tflag], not carry
	ret
mosext1f endp

	subttl	mosext20 - return port and baud information
	page
;=======================================================================
;,fs
; mosext20 - api fun 20 - return port and baud information
; 
; in:	tbx = task id or -1 for current task
; 
; out:	tcx = port (0 if none)
; 	tdi:tsi = baud rate
; 
;,fe
;======================================================================^
	assume	ds:grp,es:nothing,ss:tcb
mosext20 proc	near
	mov	bx,[tbx]
	call	gettask 		; get task tcb
	or	ax,ax
	jz	mext20a
	callmos2 moserror
	ret
mext20a:
	assume	es:tcb,ss:nothing
	mov	ax,[tcbport]
	mov	[tcx],ax
	mov	ax,word ptr [tcbbaud]
	mov	[tdi],ax
	mov	ax,word ptr [tcbbaud+2]
	mov	[tsi],ax
	mov	[tax],00h
	and	[tflag], not carry
	ret
mosext20 endp

	subttl	mosext21 - remove a task
	page
;=======================================================================
;,fs
; mosext21 - api fun 21 - remove a task
; 
; in:	tbx = task id or -1 for current task
; 
; out:	?
; 
;,fe
;======================================================================^
	assume	ds:grp,es:nothing,ss:tcb
mosext21 proc	near
	mov	bx,[tbx]
	call	gettask 		; get task tcb
	or	ax,ax
	jz	mext21a
	callmos2 moserror
	ret
mext21a:
	assume	es:tcb,ss:nothing
	mov	ax,[tes]
	push	ax
	mov	[tes],es
	call	mosext05
	pop	ax
	mov	[tes],ax
	ret
mosext21 endp

	subttl	mosext22 - add a task
	page
;=======================================================================
;,fs
; mosext22 - api fun 22 - add a task
; 
; in:	tds:tsi = pointer to addtask structure as follows
; 
; 	    offset	    size	    description
; 	 -----------------------------------------------------------
; 	    00h 	    word	    size
; 	    02h 	    word	    task id (0 if none)
; 	    04h 	    byte	    class   (0 if none)
; 	    05h 	    dword	    startup batch (0 if none)
; 	    09h 	    dword	    terminal driver (0 if none)
; 	    0dh 	    word	    port
; 	    0fh 	    dword	    baud rate (0 if none)
; 
; 
; out:	    13h 	    dword	    total ext mem
; 	    17h 	    dword	    ext mem allocated
; 	    1bh 	    word	    amount smp allocated
; 	    1dh 	    word	    total smp memory
; 	    1fh 	    word	    percent smp allocated
; 
; 	tes = newly created tcb segment
; 
; reserved:
; 	    21h - 23h			    reserved  for later
; 
;,fe
;======================================================================^
	assume	ds:grp,es:nothing,ss:tcb
public	mosext22
mosext22 proc near
	mov	ds,[tds]
	mov	si,[tsi]
	call	start_task
	mov	[tes],es
	callmos2 moserror
	ret
mosext22 endp 

	subttl	start_task - add a task
	page
;=======================================================================
;,fs
; start_task - add a task
;
; in:	ds:si -> addparm table
;
; out:	ax = 0 for no error, else error code
;	es -> new tcb
; 
;,fe
;======================================================================^
	assume	ds:nothing,es:nothing,ss:tcb
public	start_task
lproc	start_task
lword	addsize
lword	taskid
lbyte	addclass
ldword	addbatch
ldword	adddriver
lword	addport
ldword	addbaud
lword	alloctcb
lstring addstart,72
ldword	adddta
lword	xtds
lword	xtsi
lword	xtes
	mov	ax,[tcbdta]
	mov	word ptr [adddta],ax
	mov	ax,[tcbdta+2]
	mov	word ptr [adddta+2],ax
	mov	[alloctcb], 00h 	; tcb not allocated
	mov	[xtds],ds
	mov	[xtsi],si
	mov	ax,ds
	mgetscb	ds
	push	ds
	mov	ds,ax
	cld
	lodsw
	mov	[addsize],ax		; save size of task
	lodsw
	mov	[taskid],ax		; save taskid
	lodsb
	mov	[addclass],al		; save class
	lodsw
	mov	word ptr [addbatch],ax	; save high part of startup batch
	lodsw
	mov	word ptr [addbatch+2],ax; save low part of startup batch
	lodsw
	mov	word ptr [adddriver],ax ; save high part of driver
	lodsw
	mov	word ptr [adddriver+2],ax  ; save low part of driver
	lodsw
	mov	[addport],ax		; save port
	lodsw
	mov	word ptr [addbaud],ax	; save high part of baud rate
	lodsw
	mov	word ptr [addbaud+2],ax ; save low part of baud rate
	pop	ds
	cmp	[taskid],99
	jna	idok
	mov	al,87
	jmp	f22doerr
idok:
	xor	ah,ah			; this is to allocated
	mov	al,'T'
	call	mosliman		; allocate a tcb for task
	or	al,al
	jz	f22a
	jmp	f22error		; jump to error handler
f22a:
	mov	[alloctcb],es		; tcb allocated

; tcb successfully allocated and in es

	assume	es:tcb,ss:nothing
	mov	ax,word ptr [adddriver]
	mov	word ptr [tcbcondd],ax
	mov	ax,word ptr [adddriver+2]
	mov	word ptr [tcbcondd+2],ax
	mov	al,[addclass]
	mov	[tcboclass],al
	mov	ax,[taskid]
	mov	[tcbid],ax
	mov	ax,[addport]
	mov	[tcbport],ax
	mov	ax,word ptr [addbaud]
	mov	word ptr [tcbbaud],ax
	mov	ax,word ptr [addbaud+2]
	mov	word ptr [tcbbaud+2],ax
	mov	ax,[addsize]
	shl	ax,1
	shl	ax,1
	shl	ax,1
	shl	ax,1
	shl	ax,1			; convert # of k to # of paragraphs
	shl	ax,1
	mov	[tcbendad],ax
	lds	si, [addbatch]		; point to the autoexec file nam
	assume	ds:nothing
	push	es
	push	ss
	pop	es
	lea	di, addstart		; make a copy on stack
	mov	cx, 72			; max of 72 bytes
	cld
skip4:
	lodsb				; get a byte
	stosb				; store a byte
	cmp	al, 0			; is it the end of the string
	je	skip5			; quit if yes
	loop	skip4			; continue until entire string m
skip5:
	pop	es
	lds	si, [addbatch]		; point to the autoexec file nam
	assume	ds:nothing
	lea	di, [tcbautoe]		; point to tcb storage
	mov	cx, 72			; max of 72 bytes
	cld
skip7:
	lodsb				; get a byte
	stosb				; store a byte
	cmp	al, 0			; is it the end of the string
	je	skip8			; quit if yes
	loop	skip7			; continue until entire string m
skip8:
	mgetscb ds
	assume	ds:grp
	cmp	[scbmmfg], 'Y'		; are we memory managed
	je	skip9			; ignore parent task if memory m
	mov	bx,ss
	mov	[tcbparnt], bx		; set the parent tcb
skip9:
	assume	ds:nothing
	push	ds
	push	ss
	pop	ds
	lea	si, addstart
	assume	ds:nothing
	call	mositask		; add the task
	pop	ds
	jc	f22error
	mov	ah,[tcboclass]
	mov	[tcbclass],ah
	mov	[tcbslice],1		; set slice to 1 to start task
	mgetscb ds
	assume	ds:grp
	mov	ah,3			; get % heap used up
	call	mosheman
	mov	[xtes],es		; return es -> tcb
	mov	es,[xtds]
	mov	di,[xtsi]
	add	di,13h			; point to return information area
	push	ax
	cmp	[scbmmfg],'Y'
	jne	f22nomm 		; do we have a paging capable
	test	[scbmmfea],80h		; memory manager?
	jz	f22nomm
	push	si
	push	ds
	lds	si,[scbmmptr]
	assume	ds:nothing
	add	si,10			; address parmtot within the memdev
	movsw
	movsw
	movsw
	movsw
	pop	ds
	assume	ds:grp
	pop	si
	jmp	f22mmx
f22nomm:
	xor	ax,ax
	stosw
	stosw
	stosw
	stosw
f22mmx:
	mov	ax,[scbhpalc]
	stosw
	mov	ax,[scbhpsiz]
	add	ax,[scbhp2siz]
	stosw
	pop	ax
	stosw				; store % heap for return value
	xor	ax,ax
	jmp	short	f22done

; add a task error handler

f22error:
	cmp	[alloctcb],0
	je	f22notcb
	mov	es,[alloctcb]
	push	ax
	mov	ah,1
	mov	al,'T'
	call	mosliman		; free up tcb in es
	pop	ax
f22notcb:
	cmp	al,11			; invalid format (bad port...)
	je	f22done
	cmp	al,87			; task id out of range
	je	f22doerr
	cmp	al,85			; task id currently in use
	je	f22doerr
	cmp	al,8			; out of memory
	je	f22doerr
	cmp	al,18			; low smp memory
	je	f22doerr
	cmp	al,1			; heap error
	jne	f22fail
	mov	al,18			; out of heap error
	cmp	ah,1			; out of space?????
	je	f22doerr
f22fail:
	mov	al,31			; indicate general failure
f22doerr:
	xor	ah,ah
f22done:
	assume	ds:nothing,es:nothing,ss:tcb
	mov	bx,word ptr [adddta]
	mov	[tcbdta],bx
	mov	bx,word ptr [adddta+2]
	mov	[tcbdta+2],bx
	mov	es,[xtes]		; return es -> tcb
lundef	xtes
lundef	xtsi
lundef	xtds
lundef	adddta
lundef	addstart
lundef	alloctcb
lundef	addbaud
lundef	addport
lundef	adddriver
lundef	addbatch
lundef	addclass
lundef	taskid
lundef	addsize
lendp	start_task

	subttl	mosext23 - change ddt
	page
;=======================================================================
;,fs
; mosext23 - api fun 23 - change ddt
; 
; change a task's ddt driver on the fly.  only for serial/mono
; class drivers.  no elterm, vna, srterm!  caller must open the new
; driver in raw mode and read the 4 byte vector.
; 
; in:	bx = task id or -1 for current task
; 	ds:si -> entry point of new driver
; 
; out:	cy if error, ax = error code
; 	nc if ok
; 
;,fe
;======================================================================^
	assume	ds:grp,es:nothing,ss:tcb
public	mosext23
lproc	mosext23
lstring conddsav,36
	mov	si,bp
	mov	bp,[bp]
	mov	bx,[tbx]
	call	gettask 		; get task tcb
	mov	bp,si
	or	ax,ax
	jz	mext23a
	jmp	mext23x
mext23a:
	assume	es:tcb,ss:nothing
	test	[tcbvram],11111100b	; no vna, srterm, graphics, etc.
	jmpnz	mext23y
	mov	ax,word ptr [tcbbaud]
	or	ax,word ptr [tcbbaud+2] ; must be a serial terminal
	jmpz	mext23y
	push	es
	push	es			; es -> ds
	pop	ds
	push	ss			; ss -> es
	pop	es
	assume	ds:tcb,es:nothing
	mov	si,offset [tcbcondd]
	lea	di,[conddsav]
	mov	cx,36/2
	rep	movsw			; save current data in case need
	pop	es			; to restore from an error
	mov	di,offset [tcbcondd+4]
	mov	ax,0
	mov	cx,7			; freshen up the condd data area
	rep	stosb			; (stosb is ok since es -> tcb too)
	add	di,6
	mov	cx,19
	rep	stosb
	mov	bx,bp
	mov	bp,[bp]
	mov	ax,[tsi]
	mov	si,offset [tcbcondd]
	mov	word ptr [si],ax	; record new condd address
	mov	ax,[tds]
	mov	bp,bx
	mov	word ptr [si+2],ax
	xor	ax,ax			; register function
	call	ddtcallf		; see if ddt busy and call
	or	ah,ah			; any errors?
	jnz	mext23v
	mov	ah,[tcbvram]
	and	ah,not 1
	cmp	al,ah			; new and old tcbvram must match
	jne	mext23v
	mov	dx,[tcbport]
	mov	ah,9			; flush both buffers
	int	14h
	mov	word ptr [tcbkeyrdy],bx
	mov	word ptr [tcbkeyrdy+2],es
	xor	ax,ax			; no error
	jmp	mext23x
mext23v:
	push	ds
	pop	es			; error - time to restore the tcbcondd
	push	ss			; data area.  when enter here,
	pop	ds			; ds is pointing to the tcb.
	assume	es:tcb,ds:nothing
	lea	si,[conddsav]
	mov	di,offset [tcbcondd]
	mov	cx,36/2
	rep	movsw
mext23y:
	mov	ax,invprm		; invalid parameter
mext23x:
	mov	bp,[bp]
	callmos2 moserror		; set error flags
lundef	conddsav
lendp	mosext23

	subttl	mosext24 - return serial #
	page
;=======================================================================
;,fs
; mosext24 - api fun 24 - return serial #
; 
; this function will serial # return in ds:dx (terminated by $)
; 
; in:	nothing.
; 
; out:	tds:tdx -> serial # (terminated with $)
; 
;,fe
;======================================================================^
	assume	ds:grp,ss:tcb,es:nothing
mosext24 proc	near
	mov	[tds],ds
	mov	[tdx],offset scbsmsg
	mov	[tax],0
	ret
mosext24 endp

	subttl	mosext25 - if cs is in system memory pool
	page
;=======================================================================
;,fs
; mosext25 - api fun 25 - if cs is in system memory pool
; 
; this is a non-saver function
;
; this function will return ax with starting point to system memory pool
; if value in dx (which could be cs of device driver) is smp
; 
; in:	dx -> location to check.
; 
; out:	ax -> segment of smp (either scbhpadr or scbhp2adr)
; 	      or 0000h if not in system memory pool
; 
;,fe
;======================================================================^
	assume	ds:nothing,es:nothing,ss:nothing
mosext25 proc	near
	push	bx
	push	ds
	mgetscb ds			; get the scb address.
	assume	ds:grp
	mov	ax,[scbhpadr]		; is it start smp #1
	cmp	dx,ax
	jb	notsmp1 		; it is below
	mov	bx,ax
	add	bx,[scbhpsiz]		; add size for end
	cmp	dx,bx
	jb	retsmp			; yes...it is in smp #1
notsmp1:
	mov	ax,[scbhp2adr]		; is it start smp #2
	cmp	dx,ax
	jb	notsmp2 		; it is below
	mov	bx,ax
	add	bx,[scbhp2siz]		; add size for end
	cmp	dx,bx
	jb	retsmp			; yes...it is in smp #2
notsmp2:
	xor	ax,ax
retsmp:
	pop	ds
	assume	ds:nothing
	pop	bx
	pop	di
	iret
mosext25 endp

	subttl mosext26
	page
;=======================================================================
;,fs
; mosext26 - api fun 26
; 
; this is a non-saver function
;
; this function returns the selector (or segment address) of the
; system control block. (scb).  this selector must be used by the an
; application that wants to access the scb.
; 
; for the interim, the scb must be located on a paragraph
; boundary for the segment address returned to be accurate.
; (this has been corrected in mosfront.asm)
; 
; in:	none
; 
; out:	dx = selector of scb
; 
;,fe
;======================================================================^
	assume	ds:nothing,es:nothing,ss:nothing
mosext26 proc	far
	push	bx
	push	cx
	mgetscb dx			; get the scb address.
	mov	bx,offset scbtcbpf	; offset of first scb field.
	mov	cl,4
	shr	bx,cl			; convert to a segment address.
	add	dx,bx			; scb address complete.
	pop	cx
	pop	bx
	pop	di
	iret
mosext26 endp

;=======================================================================
;,fs
; set_errcod
; 
; in:	al = value for tcberrcod
; 
; out:	cy flag set
; 
;,fe
;======================================================================^
	assume	ds:grp,es:nothing,ss:nothing
set_errcod proc near
	push	ds
	mov	ds,[scbtcbpc]
	assume	ds:tcb
	mov	[tcberrcod],al
	pop	ds
	assume	ds:grp
	stc
	ret
set_errcod endp

	subttl mosext27
	page
;=======================================================================
;,fs
; mosext27 - api fun 27
; 
; this is a non-saver function
;
; this function returns the selector (or segment address) of the
; terminal control block (tcb) of the selected task.  this selector
; must be used by an application that wishes to obtain information
; from this control block.
; 
; in:	bx = task id. (or -1 for current task)
; 
; out:	if nc, dx = selector of tcb
; 	if cy, ax = error code
; 
; errs:	87 - invalid parameter.
; 
;,fe
;======================================================================^
	assume	ds:nothing,es:nothing,ss:nothing
mosext27 proc	near
	push	ds
	mgetscb ds			; get the scb address.
	assume	ds:grp
	push	es
	call	gettask 		; gets tcb in es.
	or	ax,ax
	jnz	f27x
	mov	dx,es			; return "selector" in dx.
	clc
	jmp	short f27z
f27x:
	call	set_errcod		; also does an stc
f27z:
	pop	es
	pop	ds
	assume	ds:nothing
	pop	di
	retf	2
mosext27 endp

	subttl mosext28
	page
;=======================================================================
;,fs
; mosext28 - api fun 28
; 
; this is a non-saver function
;
; this function copies the selected section of the chosen control
; block to a local buffer.
; 
; in:	bx = offset into control block to get data.
; 	cx =	number of bytes to be read.
; 	dx =	selector of the desired control block.
; 	es:di = address of buffer in which the data read
; 		is to be placed.
; 
; out:	ax =	error code if carry is set.
; 
; errs:	05 -	access denied. (tried to access data outside the
; 		selected block.
; 	28 -	invalid parameter. (bad selector)
; 
;,fe
;======================================================================^
	assume	ds:nothing,es:nothing,ss:nothing
mosext28 proc	near
	pop	di			; retrieve entry di
	push	cx
	push	si
	push	di
	push	ds
	mov	si,bx
	mov	ds,dx
	assume	ds:nothing
	pushf
	cld
	cli
	rep	movsb
	popf
	xor	ax,ax
	clc
	pop	ds
	pop	di
	pop	si
	pop	cx
	xor	ax,ax
	retf	2
mosext28 endp

	subttl mosext29
	page
;=======================================================================
;,fs
; mosext29 - api fun 29
; 
; this is a non-saver function
;
; this function copies the selected section of a local buffer to the
; selected control block.
; 
; in:	ah =	29h
; 	bx =	offset into control block to put data.
; 	cx =	number of bytes to be written.
; 	dx =	selector of the desired control block.
; 	ds:si = address of buffer from which data to be placed
; 		in control block is read.
; 
; out:	ax =	error code if carry is set.
; 
; errs:	05 -	access denied. (tried to access data outside the
; 		selected block.
; 	28 -	invalid parameter. (bad selector)
; 
;,fe
;======================================================================^
	assume	ds:nothing,es:nothing,ss:nothing
mosext29 proc	near
	push	cx
	push	si
	push	es
	mov	di,bx
	mov	es,dx
	assume	es:nothing
	pushf
	cld
	cli
	rep	movsb
	popf
	pop	es
	pop	si
	pop	cx
	pop	di
	xor	ax,ax
	clc
	retf	2
mosext29 endp

	subttl mosext2a
	page
;=======================================================================
;,fs
; mosext2a - api fun 2a
; 
; this is a non-saver function
;
; this function swaps a section of memory with the selected control
; block.  use this function when exchanging values that are critical
; such as vector addresses, etc.
; 
; selected control block.
; 
; in:	ah =	2ah
; 	bx =	offset into control block to be swapped.
; 	cx =	number of bytes to be swapped.
; 	dx =	selector of the desired control block.
; 	ds:si = address of buffer to be exchanged with control
; 		block.
; 
; out:	ax =	error code if carry is set.
; 
; errs:	05 -	access denied. (tried to access data outside the
; 		selected block.
; 	28 -	invalid parameter. (bad selector)
; 
;,fe
;======================================================================^
	 assume ds:nothing,es:nothing,ss:nothing
mosext2a proc	near
	push	cx
	push	si
	push	es
	mov	di,bx
	mov	es,dx
	assume	es:nothing
	pushf				;preserve flag state.
	cld				;all moves forward.
	cli				;disable interrupts during swap
f2a_loop:
	lodsb				;get next byte from source.
	xchg	al, es:[di]		;swap with value at destination.
	mov	[si-1], al		;place dest value at source.
	inc	di			;move to next destination address.
					;(si incremented on lodsb)
	loop	f2a_loop		;go back for another?
	popf				;restore flag state.
	pop	es
	pop	si
	pop	cx
	pop	di
	xor	ax,ax
	clc
	retf	2
mosext2a endp

	subttl	mosext2b - spooler timeout change
	page
;=======================================================================
;,fs
; mosext2b - api fun 2b - spooler timeout change
; 
; this function is use to set spooler timeout, it is undocumented  but
; is used by a pre-4.10 release custumer. custumers should use function
; 2ch instead
; 
; in:	tbx = time in seconds (max or 3600)
; 	tdx = lpt number
; 
; out:	tax = return error code
; 
;,fe
;======================================================================^
	assume	ds:grp,ss:tcb,es:nothing
mosext2b proc	near
	 push	es
	 mov	ax,ss
	 mov	es,ax
	 mov	bx,[tbx]		; get time to set
	 mov	dx,[tdx]		; get lpt #
	 xor	al,al			; use subfunction 00 - set timeout
	 call	extspool		; call spool subfunction handler
	 callmos2 moserror
	 pop	es
	 ret
mosext2b endp

	subttl extspool
	page
;=======================================================================
;,fs
; extspool
; 
; this procedure is use internal by function 2bh and 2ch to allow 
; change to spooler data items
; 
; in:	al = subfunction
; 	 00h = set spooler time out
; 	  bx = time in seconds
; 	 01h = get spooler time out
; 	  bx = time in seconds
; 	02h = set spooler paramters
; 	  bl = disposition (d,s,h,i,n)
; 	  bh = priority    (0 - 9)
; 	  cl = class	    (a - z)
; 	 03h = set spooler paramters
; 	  bl = disposition (d,s,h,i,n)
; 	  bh = priority    (0 - 9)
; 	  cl = class	    (a - z)
; 	dx = lpt device
; 	es = tcb segment
; 
; out:	?
; 
;,fe
;======================================================================^

sparms	db	'DSHIN'
word182 dw	182			; constant use in time calcuations

vctspool label	word
	dw	mos:settimeout
	dw	mos:gettimeout
	dw	mos:setsplparm
	dw	mos:getsplparm
vctslen equ	($-vctspool)

	assume ds:grp,es:tcb,ss:nothing
extspool proc	near
	 push	si
	 push	di
	 push	es
	 xor	ah,ah
	 mov	si,ax
	 shl	si,1
	 mov	ax,1			; return error in paraters
	 cmp	dx,2			; if not lpt1, lpt2, or lpt3
	 ja	skipspool		; return error
	 mov	di,dx
	 push	ax
	 mov	ah,byte ptr [i17prtbit+di]
	 test	[tcbauxbt],ah		; test for remote routing
	 pop	ax
	 jnz	skipspool
	 mov	dx,[tcbspool]
	 or	dx,dx
	 jz	skipspool
	 assume es:spldseg
	 add	dx,spldoff
	 assume es:splbuff
	 mov	ah,byte ptr [i17prtbit+di]
esplloop:
	 mov	es,dx
	 test	[splb.printer],ah	; is printer installed
	 jnz	espldo
	 add	dx,spldpars
	 cmp	[splb.printer],0	; ran out of buffers
	 jne	esplloop
	 xor	ah,ah
	 jmp	short skipspool
espldo:
	 xor	ah,ah
	 cmp	si,vctslen
	 jae	skipspool
	 call	[vctspool+si]
skipspool:
	 pop	es
	 pop	di
	 pop	si
	 ret
extspool endp

	subttl settimeout
	page
;=======================================================================
;,fs
; settimeout
; 
; spooling extended services sub-functions
;
; in:	?
;
; out:	?
; 
;,fe
;======================================================================^
settimeout proc near
	cmp	bx,3600 		; is value invalid
	ja	stoend
	mov	ax,bx
	mul	cs:[word182]
	add	ax,91
	adc	dx,0
	div	cs:[wordten]
	mov	[splb.timeout],ax	; set time out value
	xor	ax,ax
stoend:
	ret
settimeout endp

	subttl gettimeout
	page
;=======================================================================
;,fs
; gettimeout
; 
; spooling extended services sub-functions
;
; in:	?
;
; out:	?
; 
;,fe
;======================================================================^
gettimeout proc near
	mov	ax,[splb.timeout]	; get time out value
	mul	cs:[wordten]
	div	cs:[word182]
	mov	bx,ax
	xor	ax,ax
	ret
gettimeout endp

	subttl setsplparm
	page
;=======================================================================
;,fs
; setsplparm
; 
; spooling extended services sub-functions
;
; in:	?
;
; out:	?
; 
;,fe
;======================================================================^
setsplparm proc near

; first make sure that parameters are valid

	and	cl,0dfh
	cmp	cl,'A'
	jb	sspend
	cmp	cl,'Z'
	ja	sspend
	cmp	bh,'0'
	jb	sspend
	cmp	bh,'9'
	ja	sspend
	push	ax
	push	cx
	push	di
	push	es
	mov	ax,cs
	mov	es,ax
	mov	di,offset sparms
	mov	cx,5
	mov	al,bl
	repne	scasb
	pop	es
	pop	di
	pop	cx
	pop	ax
	jne	sspend
	mov	[splb.filname+spldisp],bl
	mov	[splb.filname+splprio],bh
	mov	[splb.filname+splclas],cl
	xor	ax,ax
sspend:
	ret
setsplparm endp

	subttl getsplparm
	page
;=======================================================================
;,fs
; getsplparm
; 
; spooling extended services sub-functions
;
; in:	?
;
; out:	?
; 
;,fe
;======================================================================^
getsplparm proc near
	mov	bl,[splb.filname+spldisp]
	mov	bh,[splb.filname+splprio]
	mov	cl,[splb.filname+splclas]
	xor	ax,ax
	ret
getsplparm endp

	subttl	mosext2c - spooler parameters
	page
;=======================================================================
;,fs
; mosext2c - api fun 2c - spooler parameters
; 
; get\set spooler parameters
; 
; in:	tal = subfunction
; 	 00h = set spooler time out
; 	  cx = time in seconds
; 	 01h = get spooler time out
; 	  cx = time in seconds
; 	 02h = set spooler paramters
; 	  cl = disposition (d,s,h,i,n)
; 	  ch = priority    (0 - 9)
; 	  si = class	    (a - z)
; 	 03h = set spooler paramters
; 	  cl = disposition (d,s,h,i,n)
; 	  ch = priority    (0 - 9)
; 	  si = class	    (a - z)
; 	tbx = task id or -1 for current task
; 	tcx = time in seconds (max or 3600)
; 	      or disposition and priority
; 	tsi = class
; 	tdx = lpt number
; 
; out:	tax = return error code
; 
;,fe
;======================================================================^
	assume	ds:grp,ss:tcb,es:nothing
mosext2c proc	near
	 push	es
	 mov	bx,[tbx]
	 call	gettask 		; get task tcb
	 or	ax,ax
	 jnz	mosend2c
	 mov	dx,[tdx]
	 mov	al,[tal]
	 mov	cx,[tsi]		; get lower byte of si
	 mov	bx,[tcx]
	 call	extspool		; call spooler subfunctions
	 mov	[tcx],bx
	 mov	bx,[tsi]
	 mov	bl,cl
	 mov	[tsi],bx
mosend2c:
	 callmos2 moserror
	 pop	es
	 ret
mosext2c endp

	subttl	mosext2d - return max task size
	page
;=======================================================================
;,fs
; mosext2d - api fun 2d - return max task size
; 
; in:	nothing
; 
; out:	tbx = start of task
; 	tdx = maximun size of task
; 
;,fe
;======================================================================^
	assume	ds:grp,ss:tcb,es:nothing
mosext2d proc	near
	 call	calclim 		; calcuated limit from mositask
	 mov	bx,[scbfree]		; get base of task
	 sub	ax,bx
	 mov	[tdx],ax		; return max task size
	 mov	[tbx],bx		; return start of task
	 xor	ax,ax
	 callmos2 moserror
	 ret
mosext2d endp

	subttl	mosext2e - check partition security access
	page
;=======================================================================
;,fs
; mosext2e - api fun 2e - check partition security access
; 
; in:	tbx - task id to check access current task
; 
; out:	tax = error code
; 
;,fe
;======================================================================^
	assume	ds:grp,ss:tcb,es:nothing
mosext2e proc	near
	xor	ax,ax		; indicate ok
	mov	bx,[TBX]
	cmp	bx,-1		; requesting for current task ...
	je	mosend2e
	cmp	bx,[tcbid]	; if ID is current task then ok
	je	mosend2e
	mov	al,ACCDENY
	call	gettask
	or	ax,ax
	jnz	moserr2e
	assume  es:tcb,ss:nothing
	mov	al,[tcbclass]	; is task not running security
	callmos2 classlvl
	mov	bl,al
	xor	ax,ax
	cmp	bl,3		; full access
	je	mosend2e
moserr2e:
	mov	ax,ACCDENY		 
mosend2e:
	callmos2 moserror
	ret
mosext2e endp

	subttl	mosext2f - check class security access
	page
;=======================================================================
;,fs
; mosext2f - api fun 2f - check class security access
; 
; in:	tbx - task id to check access current task
; 	tcl - class to check
; 
; out:	tax = error code
; 
;,fe
;======================================================================^
	assume	ds:grp,ss:tcb,es:nothing
mosext2f proc	near
	mov	bx,[TBX]
	mov	ax,ACCDENY
	call	gettask
	or	ax,ax
	jnz	mosend2f
	assume  es:tcb,ss:nothing
	mov	al,[TCL]	
	callmos2 classlvl
	mov	bl,al
	xor	ax,ax
	cmp	bl,3		; full access
	je	mosend2f
	mov	ax,ACCDENY		 
mosend2f:
	callmos2 moserror
	ret
mosext2f endp

;=======================================================================
;,fs
; mosext30 - api fun 30 - Set / clear ALT999 mode.
; 
; in:	tal -   Non-zero if TCBALT999 is to be set to allow PAM switching
;               by all watchers of this task.  Zero if PAM switching is
;               to be disabled in favor of the ALT-ASCII keyboard mode.
;               All watchers reflect the current mode.
; out:  none
; 
;,fe
;======================================================================^
	assume	ds:grp,ss:tcb,es:nothing
mosext30 proc	near
        mov     al, [TAL]
        cmp     al, 0
        je      mosext30a
        mov     al, 0FFh                ;Force to value of 0xFF
mosext30a:
        mov     [tcbalt999], al         ;Set the selected mode.
        xor     ax, ax
        callmos2 moserror
        ret
mosext30 endp

;=======================================================================
;,fs
; mosext31 - api fun 31 - read/set tcbcdflt
;
; this is a non-saver function
; 
; in:	dh = destination drive # (1 for a:, 2 for b:...)
;	  (needed by lansat.sys, this function ignores dh)
;	al = 0 to read tcbcdflt
;	al = 1 to set tcbcdflt
;	 dl = new tcbcdflt value
;
; out:  dl = current tcbcdflt value (for entry tal == 0)
; 
;,fe
;======================================================================^
	 assume ds:nothing,es:nothing,ss:nothing
mosext31 proc far
	pop	di
	push	es
	mgetscb	es
	assume	es:grp
	mov	es,[scbtcbpc]
	assume	es:tcb
        cmp     al,0
        je      mosext31a
	mov	[tcbcdft],dl
	jmp	short mosext31b
mosext31a:
	mov	dl,[tcbcdft]
mosext31b:
	pop	es
	retf	2
mosext31 endp

mosseg	ends
	end

