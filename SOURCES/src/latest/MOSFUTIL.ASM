	include page.inc
	title	mosfutil - mosfun39 utility subroutines
comment ^==============================================================
		      development specification

 program name:	$$mos.com		 assigned to: jim bean
 module name:	mosfutil		 assign date: 01/30/86
 entry points:	mosfun39-mosfun5c	 completed: 09/03/86
 entry from:	mosint39, mosfun0f, mosmiman
 entry method:	call
 calls: 	device drivers, mosliman, mossaver(mosrestore),
		mosddint(setbdb), terminate, suspend, caps, getdate
		gettime
 purpose:	file handle functions
 last update:	08/18/1992
========================================================================

jsm 02/27/87	fixed wrsector to invalidate buffers until wrbf
		returned successfully

dam 03/03/87	moved to grp group (god i hope it works!)

jsm 03/09/87	fixed parsenm to allow extra valid chars on names

jsm 03/30/87	large volume support

jsm 03/31/87	alias support in findbdb

jsm 05/05/87	made chkacc accept access code 3 (no access) for
		read-only files.  made chkacc and accok return accdeny
		(not share) if a sharing conflict

jsm 05/12/87	fixed double word add of rlb offset to rlb length in
		findrlb.

jsm 05/19/87	allowed simultaneous opening of con, prn, and nul in
		all tasks in any compatibility mode.

jsm 07/21/87	changed parsenm so that it stops copying file name
		characters into the directory entry formatted area after
		eight characters.  before, if the file name was longer
		than eight characters, parsenm would copy the ninth
		character into the file's extension area.

jsm 07/23/87	changed nullpoll4 and nullpoll5 to sharepoll and
		lockpoll, respectively.  the routines are installed as
		polling routines in case of sharing or lock conflicts.
		instead of just returning "ready to wake up", the
		routines wait about a second, the return "wake up."

mjs 08/18/87	modified openfile to test the flag tcbexec3d.  if flag
		is set, means that openfile is being entered from a call
		to fun3d in exec.  the need is to provide exec with a
		universal open mode so if the file to be exec'ed is
		already open in compatibility mode, exec can still open
		it with a sharing mode.

jsm 09/11/87	changed findphdl, setphdl, and getthdl to fix problem
		with file handles when more files are opened than will
		fit in the psp.  before this would cause two duplicate
		file handles to be returned.  now, all system (internal)
		handles are 256 or greater, to forestall any duplicate
		system vs. psp handle problems.

jsm 09/25/87	changed findphdl, setphdl, and getthdl again so that
		system handles start at 2.  this will still fix problem
		above, but the transition from psp handles to system
		handles will be continuous.

		changed moserror() so that it doesn't change the
		extended error code for the task unless another error
		occurs.  this fixes the bbx/lanlink/mos endless loop
		problem.

mjs 10/7/87	found that bascom ver 1.00 was getting a critical error
		when it tried to write the lst file to the nul device.
		this was due the procedure univacc setting the share
		mode to deny none.  when a fun28 (fcb block write) was
		done, chkacc would be called with compatiblity mode.
		since the device had not been opened in compat mode
		chkacc would issue a critical error.  tested dos an
		found that charactor devices can always be opened
		regardless of any sharing mode conflicts.  corrected
		mos by testing for gfbdev at the entry to chkacc.  also
		removed univacc since it should no longer be needed.

sjc 10/29/87	optimzation

jrb 12/17/87	flag found device name by clearing sector number buffer

jrb 12/31/87	parsenm was trashing past fcb if ext > 3 chars

sah 01/21/88	change scbseg and zero seg access to mgetxxxx macros

jrb 02/04/88	don't release one handle's locks on a close on another
		handle

rbr/sah 02/20/88 move ddt code to mo2 group.

sah 04/13/88	change error code return by chkok from access denied to
		xshare.

mjs 4/24/88	modify findgfb to test new flag gfbinvld.  this is to
		handle cadkey's install program - findgfb must be
		smart enough to know the install program has left a
		file open on a disk that it has just prompted you to
		swap out for another disk.

jrb 5/02/88	flush all changed data sectors when closing a file
		cache will physically write them only if the volume
		isn't cached
		have putfat call wrfat instead of wrsector (to better
		identify the write if needed in future)

sjc 7/6/88	assumed ax=0 on entry to sharepoll/lockpoll
		sorry but, this is not the case! clr ax if done polling

mjs 9/1/88	modified findgfb and makegfb for task specific device
		drivers.

sah 09/03/88	cleaned up so that it could assemble correctly
		move part of code to new module mosfutl4
sah 09/06/88	small correct because data item got converted to tabs

sjc 09/12/88	test for device access instead of cking media descriptor
		in pathfind subr. (bug which hit removable drive when
		attempting to open a memory resident device driver and
		logged onto that removable device).

mjs 09/28/88	re-worked sjc's mod to pathfind (9/12/88).  The string
		constant at 'dev' was being used as a scratch buffer.

sah 11/16/88	correct to findtfb where handle could be set into wrong
		tfb or other memory space if handle not found in tfbs

sah 12/02/88	corrections to findrlb is lock region request is > 32
		bits. if so than we should say that the lock is valid
		this was causing file and record locking problem with
		mf-cobol compiled applications.

jrb 12/08/88	allow compatibility mode and share mode to coexist if
		it's the same tcb and the same psp

sah 01/26/89	change lock equate to nlock (masm 5.10 compatibility)

mjs 06/28/89	modified parsenm and pathfind to handle trailing spaces
		in the users asciiz search string.

mjs 10/10/89	modified sector size calculations.

sah 10/30/89	modify pathcomp to correctly handle searching for labels
		could not search for a label by name.  this corrected
		install for sbt accounting software.

sah 11/06/89	correction for md c: in pathfind

sah 12/14/89	remove mosregs2.inc

mjs 03/07/90	added gating to alloclust

sah 03/14/90    correction to chkacc for same psp

mjs 03/19/90	remove all code pertaining to bdb specific gating.
		implmeneted absolute bdb gating permanently.

sah 04/09/90	corrections for maketfb and file limit.

bwr 04/11/90	during file creation call (mosfun3c) a pathname
		containing the forward slash '/' was being incorrectly
		handled.  in this function, dos considers a '/' in the
		pathname as a '\'.  this fixes a problem with foxpro's
		install program which sends the pathnames using the
		'/' character.

mjs 04/30/90	modified pathfind and pathcomp to accept al as an entry
		parameter.  if al != 0, volume labels will be skipped.
		this was necessary to manage cases where a file or dir
		name was the same as a volume label.

sah 07/18/90	change chkacc so that it will also check for read-only 
		access when read-only attribute is set

mjs 07/23/90	make alloclust call exit_bdbgate.

mjs 08/03/90	fix problem in alloclust.  if the fat entry for the
		last cluster on a disk happens to contain an eof mark
		the alloclust logic was getting into an endless loop.
		this resulted in a hung system when copying to a full
		disk.

bwr 10/08/90    fixed routine "pathfind" to consider multiple occurences
                of the path separator (\ or /) as a single element.  some
                applications like to double the character.  this fix in
                response to problem report from microbiz inc.

sah 01/22/91	corrections for device driver will be supported by	
		undocumented dos techniques				

sah 02/21/91    the following is correction for running  paradox 3.5 
	        (network enviroment)  on mos  if another task has open a
                read-only file in read-only mode and current task is
                checking to open file in compatibility mode than it
                it is ok to open it

mjs 07/15/91	cleaned up

mjs 08/09/91	corrected maketfb.  when an error is being returned
		due to the 'mos files on' feature (tcbflimit), the
		tfb must be deallocated.

mjs 12/16/91	dlg mods: modified maketfb to set the new tfb field tfb6ccom
		to zero. modified the makelbl and delete functions to use
		ioctl functions 0866 and 0846 to update the label field
		within the extended bpb when a directory label entry is
		created or deleted.

mjs 01/16/92	correction to maketfb.  when getthdl fails and mosliman
		is called to delete the tfb, must preserve the error
		code in ax.  this was causing problems with basic
		compiler version 7.

================ 5.01 Kernel Ends Here ====================================

mjs 08/18/92	clean up segment declarations

mjs 09/17/92	rewrote chkacc function (actually did on 07/22/92)
		parallel: updat501.sys version 1.04

======================================================================^

.xlist
;	include mosfutil.pub
	include group.inc
	include macros.inc
	include dskstruc.inc
	include mosregs.inc
	include moscdb.inc
	include mosgfb.inc
	include mostfb.inc
	include mosrlb.inc
	include mosbdb.inc

tcb	segment at 1234h
	include mostcb.inc		; tcb definition
tcb	ends

gdata	segment
	include mosscbex.inc		; specify all scb items as external
gdata	ends
.list

;======================================================== mos segment
if 0 eq 0
segment_num = 1
endif
mosseg	segment
	extrn 	scbnul:word
mosseg	ends

;======================================================== ddt segment
if 0 eq 0
segment_num = 2
endif
ddt	segment
	assume	cs:mo2,ds:grp,es:nothing,ss:tcb

mosfutil label near			; mark the beginning of this module - sjc

	extrn	terminate:near, mosrestore:near, sbios2:word
	extrn	mosliman:near, caps:near, getdate:near, gettime:near
	extrn	suspend:near, setbdb:near, fat12:near, fat16:near
	extrn	mosheman:near, ckdev0:near, moslim0:near, getthdl:near
	extrn	classlvl:near, devchk:near, mediachk:near, wrsector:near
	extrn	rddir:near, flushdir:near, rdfat:near, todriver:near
	extrn	toint24:near, flush:near, openfile:near, setphdl:near
	extrn	flushdata:near, wrfat:near, findphdl:near, getphdl:near
	extrn	makegfb:near, findgfb:near, chk_bdbgate:near
	extrn	exit_bdbgate:near, io0d:near

	public	nullpoll8, nullpoll9, alloclust, setfree, chkacc
	public	chklock, clrclust, create, dealloc, delete
	public	emptydir, findbdb, findlbl, findnm, findrlb
	public	getfat, makelbl, maketfb, moserror, nextnm, pathfind
	public	putfat, slash, timestamp, iolock, findtfb
	public	devicenm, finddrv, okchar, capscmps

if 0 eq 0				; fake out public.com

; error codes defined

invfn	equ	1			; invalid function (or sub-function)
filenf	equ	2			; file not found (or invalid name)
pathnf	equ	3			; path not found (or invalid path)
manyfil equ	4			; too many files open
accdeny equ	5			; access denied
invhdl	equ	6			; invalid handle (file not open)
invacc	equ	12			; invalid access code specified
drivenf equ	15			; drive not found (or invalid drive)
delcurd equ	16			; attempt to delete current directory
diffdev equ	17			; not the same device
nomore	equ	18			; no more files found
share	equ	32			; sharing violation
nlock	equ	33			; lock violation
wrongdisk equ	34			; wrong disk in drive
shareov equ	36			; share buffer overflow (couldn't alloc RLB)
filexst equ	80			; file already exists
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

arch	equ	20h			; archive
dir	equ	10h			; directory
lbl	equ	08h			; label
sys	equ	04h			; system
hid	equ	02h			; hidden
ro	equ	01h			; read-only
timloc	equ	006ch			; sjc portability - timer location in bios

; critical error coding

rdx	equ	00h			; read operation
wrx	equ	01h			; write operation

failx	equ	08h			; fail not allowed
retryx	equ	10h			; retry not allowed
ignorex equ	20h			; ignore not allowed
allx	equ	failx or retryx or ignorex
sysx	equ	failx or retryx 	; ignore not allowed in system areas
dosx	equ	00h or allx		; dos area of disk?
fatx	equ	02h or sysx		; fat area
dirx	equ	04h or sysx		; dir area
datax	equ	06h or allx		; data area

endif

	subttl findtfb - find tfb corresponding to a file handle and tcbpsp
	page
;======================================================================
;,fs
; findtfb - find tfb corresponding to a file handle and tcbpsp
; 
; in:	bx = file handle
;	ss:[tcbpsp] = psp of current process for active task
; 
; out:	c if not found
;	 es = undefined
;	nc if found
;	 es = segment address of tfb
; 
;,fe
;=====================================================================^
	assume	ds:nothing,es:nothing,ss:tcb
findtfb:
	push	cx
	push	bx
	push	ax
	mov	cx,[tcbtfbpf]		; first tfb for this task
	cmp	[tcbpsp],0
	je	findtf1 		; if psp is undefined then search for handle
	call	findphdl		; else de-reference through psp
	cmp	bx,-1
	stc
	je	findtfx
findtf1:
findtf2:
	or	cx,cx
	stc
	jz	findtfx 		; end of list and not found
	mov	es,cx
	assume	es:tfb
	mov	cx,[tfbntcb]
	cmp	bx,[tfbhdl]		; or if handle not in handle list
	jne	findtf2
	mov	[tfbfnh],bx		;jrba remember handle for this function call
findtfx:
	pop	ax
	pop	bx
	pop	cx
	ret

	subttl maketfb - make a tfb for a task for a dir entry or device
	page
;======================================================================
;,fs
; maketfb - make a tfb for a task for a dir entry or device
; 
; in:	al = requested access and requested permission
;	es -> gfb
;	ds -> bdb
;	ss -> tcb (for mosliman, getthdl, etc)
; 
; out:	c if couldn't be created
;	 ax = error code
;	nc if created ok
;	 es = segment address of tfb
;	 ax = undefined
; 
;,fe
;====================================================================^
	assume	ds:bdb,es:gfb
maketfb:
	push	ds
	push	es
	pop	ds
	assume	ds:gfb
	push	cx
	push	bx
	mov	bx,ax
	xor	ax,ax
	mov	al,'F'
	call	moslim0
	jz	maktfb1
	cmp	ax,0101h		; (not enough heap space for tfb)
	mov	ax,intern
	stc
	jne	mx1			; sjc optimize
	mov	ax,manyfil		; (report too many files if not enough heap
mx1:
	jmp	maktfbx 		;   space)
maktfb1:
	assume	es:tfb
	mov	ax,[gfbcbof]
	mov	[tfbclus],ax		; positioned at first cluster in file
	mov	[tfbhdl],-1		; set invalid handle to start (which also means
	call	getthdl 		;   -1 can't be returned)
	jnc	maktfb4
	push	ax
	mov	ah,1			; delete the tfb
	mov	al,'F'
	call	moslim0
	pop	ax
	stc
	jmp	maktfbx
maktfb4:
	mov	[tfbhdl],ax		; handle for file
	xor	ax,ax
	mov	word ptr [tfbpos],ax	; positioned at offset 0 in file
	mov	word ptr [tfbpos+2],ax
	mov	[tfblvl],bh
	mov	bh,bl
	and	bl,0fh			; requested access (and reserved bit)
	shr	bh,1
	shr	bh,1
	shr	bh,1
	shr	bh,1
	and	bh,0fh			; access for others (and inheritance bit)
	mov	[tfbacc],bl
	mov	[tfbalow],bh
	mov	ax,[tcbpsp]
	mov	[tfbpsp],ax
	push	ds
	lds	bx,[gfbdrvr]
	mov	ax,[bx+4]
	pop	ds
	and	al,1fh			; the only bits we need
	or	al,80h			; set char device and ascii mode
	cmp	[gfbdev],0
	jne	maktfb2
	push	ds			; block device
	mov	ds,[gfbbdb]
	assume	ds:bdb
	mov	al,[bdbid]
	pop	ds
	assume	ds:gfb
	and	al,1fh			; unit number and file not yet written
	jmp	maktfb3 		;   (by this process)
maktfb2:				; character device
	mov	[tfb@xof],0		; xoff not encountered
	test	al,04h			; (check null bit)
	jz	maktfb3 		; z if not null device
	or	al,40h			; else set eof bit
maktfb3:
	mov	[tfbioctl],al		; ioctl flag for this tfb
	mov	[tfbopen],0		; no psp handles yet
	mov	[tfb6ccom],0		; no auto-commit unless set by mosfun6c
	cmp	ax,ax
maktfbx:
	pop	bx
	pop	cx
	pop	ds
	ret

	subttl chkacc - check access to a file or device
	page
;======================================================================
;,fs
; chkacc - check access to a file or device
; 
; make sure requested access is permitted by others
; make sure access permitted others is consistent with access 
; already granted others
; 
; in:	al = reqested access
;	 bits 2-0 = requested access
;	 bits 6-4 = requested permission
;	ds -> bdb
;	es -> gfb
;	ss -> tcb
; 
; out:	c if access can't be granted
;	 ax = error code
;	nc if access can be granted
;	 ax = undefined
; 
;,fe
;====================================================================^
	assume	ds:bdb,es:gfb,ss:tcb

share_compt	equ	0    	; compatibility
share_dn_rw	equ	1	; deny read/write
share_dn_w	equ	2	; deny write
share_dn_r	equ	3	; deny read
share_dn_no	equ	4	; deny none

access_r	equ	0	; read access
access_w	equ	1	; write access
access_rw	equ	2	; read/write access
access_none	equ	3	; no access (special mos-specific value)

lproc	chkacc
lword	gfbseg
	mov	[gfbseg],es
	push	es
	push	si
	push	cx
	push	bx
	push	dx
	push	di

; check for open of a character device 

	cmp	[gfbdev],0
	je	ch0
	clc
	jmp	chkacy
ch0:

; derive share and access values from entry al

	mov	bl,al
	mov	bh,al
	and	bl,07h			; bl = new.access
	shr	bh,1
	shr	bh,1
	shr	bh,1
	shr	bh,1
	and	bh,07h			; bh = new.share

; check for write access to a read-only file

	xor	di,di			; init read_only flag
	test	[gfbattr],ro
	jz	ch1
	mov	di,1			; set read_only flag
	cmp	bl,access_r
	je	ch1
	cmp	bl,access_none		; special "no access" value
	je	ch1
	mov	ax,accdeny
	stc
	jmp	chkacy
ch1:

; check for critical error situations
;
; if new requested share mode is compatibility
; and if have any existing open that is not compatibility
; then retry, issuing critical error when exhausted


	cmp	bh,share_compt
	ljne	ch2
ch13:
	mov	cx,[tcbntry]
	inc	cx			; tcbntry retries + first try
ch14:
	mov	es,[gfbseg]
	assume	es:gfb
	mov	dx,[gfbtfb]
ch4:
	or	dx,dx
	ljz	ch2
	mov	es,dx				  
	assume	es:tfb
	mov	ah,[tfbalow]		; fetch tfb.share
	and	ah,07h			; strip off inheritance bit

; special case test for read-only files

	or	di,di
	jz	ch20
	cmp	ah,share_dn_w
	je	ch3
	cmp	ah,share_dn_no
	je	ch3
ch20:
	cmp	ah,share_compt
	je	ch3
	dec	cx
	jcxz	ch5

; setup for and call suspend

	push	es
	push	ax
	mov	es,[sbios2]
	mov	ax,es:[timloc]		; get current system timer
	mov	[tcbwinfo],ax		; store current system time for polling
	pop	ax
	pop	es
	mov	word ptr [tcbpoll],offset mo2:sharepoll
	mov	word ptr [tcbpoll+2],cs
	and	[tcbwait],not 06h	; clear bits 2,1
	or	[tcbwait],01h		; set bit 0
	callmos1 suspend		; call in mos segment
	jmp	short ch14
ch5:

; setup for and call toint24

	mov	es,[gfbseg]
	assume	es:gfb
	cmp	[gfbdev],0
	jne	chkacx1
	mov	al,[bdbid]
chkacx1:
	push	ds
	lds	si,[gfbdrvr]
	push	di
	mov	di,12			; general error sent to int 24h
	mov	[tcberrcod],share	; sharing violation
	mov	ah,dosx and (not ignorex)  ; ah as defined by int 24 doc
	call	toint24
	pop	di
	pop	ds
	ljc	chkacy			; fail chosen
	jnz	chkacy			; ignore chosen
	jmp	ch13
ch3:
	assume	es:tfb
	mov	dx,[tfbngfb]
	jmp	ch4
ch2:

; check for sharing violations
;
; if new requested share mode is not compatibility
; and if have existing open in compatibility
; then return a sharing violation error

	cmp	bh,share_compt
	je	ch6
	mov	es,[gfbseg]
	assume	es:gfb
	mov	dx,[gfbtfb]
ch7:
	or	dx,dx
	jz	ch6
	mov	es,dx				  
	assume	es:tfb
	mov	ah,[tfbalow]		; fetch tfb.share
	and	ah,07h			; strip off inheritance bit
	cmp	ah,share_compt
	jne	ch8

; special case test for read-only files

	or	di,di
	jz	ch21
	cmp	bh,share_dn_w
	je	ch8
	cmp	bh,share_dn_no
	je	ch8
ch21:
	mov	ax,share
	stc
	jmp	chkacy
ch8:
	mov	dx,[tfbngfb]
	jmp	short ch7
ch6:

; if basic conflict between existing and new modes
; then return a sharing violation error

	mov	es,[gfbseg]
	assume	es:gfb
	mov	dx,[gfbtfb]
ch9:
	or	dx,dx
	jz	ch10
	mov	es,dx				  
	assume	es:tfb
	mov	ah,[tfbalow]		; fetch tfb.share
	and	ah,07h			; strip off inheritance bit
	mov	al,bl			; fetch new.access
	call	accok
	jc	ch12
	mov	ah,bh			; fetch new.share
	mov	al,[tfbacc]		; fetch tfb.access
	call	accok
	jc	ch12
	mov	dx,[tfbngfb]
	jmp	short ch9
ch12:
	mov	ax,share
	stc
	jmp	chkacy
ch10:

; if make it through all error checking, return "ok"

	xor	ax,ax
chkacy:
	pop	di
	pop	dx
	pop	bx
	pop	cx
	pop	si
	pop	es
lundef	gfbseg
lendp	chkacc

	subttl sharepoll,lockpoll - tell mos when task can start up
	page
;======================================================================
;,fs
; sharepoll,lockpoll - tell mos when task can start up again
; 
; these routines wait for tcbttry ticks to go by, then return "wake up"
; 
; in:
;
; out:
;
;,fe
;====================================================================^
	assume	ds:nothing,es:nothing,ss:tcb
sharepoll:				; file lock
lockpoll:				; record lock
	mov	es,[sbios2]
	mov	bx,es:[timloc]		; get current system time
	sub	bx,[tcbwinfo]		; how much time has elapsed since start?
	cmp	bx,[tcbttry]
	ja	nullpoll8		; return if time exhausted - sjc 7/6/88
	mov	al,1			; set al properly if still waiting
	retf

	subttl nullpoll - tell mos when task can start up
	page
;======================================================================
;,fs
; nullpoll8,nullpoll9,nullpoll - tell mos when task can start up again
; 
; these routines always return "task can be awakened"
; 
; in:
;
; out:
;
;,fe
;====================================================================^
	assume	ds:nothing,es:nothing,ss:tcb
nullpoll8:				; device input not ready
nullpoll9:				; device output busy
nullpoll:
	xor	al,al
	retf

;======================================================================
;,fs
; accok - check requested access against permitted access
; 
; in:	ah = permitted access (0-compatibility,1-none,2-ro,3-wo,4-rw)
;	al = requested access (0-ro,1-wo,2-rw,3-none)
;
; out:
;
;,fe
;====================================================================^
	assume	ds:bdb,es:gfb,ss:tcb
accok:
	cmp	al,3
	je	accoky			; no access is always ok
	cmp	ah,4			; validate attributes
	ja	accokx
	cmp	al,2
	ja	accokx
	or	ah,ah
	jz	accoky			; compatibility allows any access
	cmp	ah,4
	je	accoky			; rw allows any access
	dec	ah
	jz	accokx			; none allows no access
	dec	ah
	cmp	ah,al
	jne	accokx			; else access must be equal to (permission-2)
accoky:
	cmp	ax,ax			; access ok
	ret
accokx:
	mov	ax,xshare		; sah change to xshare
	stc
	ret

	
	subttl create - create a new directory entry
	page
;======================================================================
;,fs
; create - create a dir entry - 
; 
; the created entry describes a file of length 0 created at the 
; current date and time with the supplied attribute
;
; in:	ds -> bdb
;	ss -> tcb
;	dx = starting cluster of directory
;	es:di -> dir entry formatted name of new file
;	ss:bx -> buffer for sector number
;	al = attribute for new dir entry
;
; out:	c if error
;	 ax = error code
;	 si, bx = undefined
;	nc if no error
;	 ss:bx -> sector number of new dir entry
;	 si = offset within sector of new dir entry
;	 ax undefined
;
;,fe
;====================================================================^
	assume	ds:bdb,es:nothing,ss:tcb
lproc	create
ldword	nptr				; ptr to name for file entry
lbyte	attrib				; attribute for file
	push	es
	push	di
	push	dx
	push	cx
	mov	[attrib],al
	mov	word ptr [nptr],di
	mov	word ptr [nptr+2],es

; find a free directory entry

	call	emptydir
	jc	makenx
	assume	es:dbb

; add the new dir entry to the dir

	mov	dx,si
	lea	di,[si+dbbbuf]		; move the name to the dir entry
	push	ds
	lds	si,nptr
	assume	ds:tcb
	mov	cx,11
	rep	movsb
	pop	ds
	assume	ds:bdb
	mov	al,[attrib]		; set the attribute
	stosb
	xor	ax,ax			; clear the rest
	mov	cx,(32-12)/2
	rep	stosw
	mov	si,dx			; restore ptr to new dir entry
	call	timestamp
	mov	word ptr [si+dbbbuf+dtime],cx  ; set the date and time
	mov	word ptr [si+dbbbuf+ddate],dx
	mov	word ptr [si+dbbbuf+dtime0],cx	; created date and time
	mov	word ptr [si+dbbbuf+ddate0],dx
	mov	ax,word ptr [tcbuser]	; created user id
	mov	word ptr [si+dbbbuf+duser0],ax
	mov	ax,word ptr [tcbuser+2]
	mov	word ptr [si+dbbbuf+duser0+2],ax
	test	[si+dbbbuf+datr],dir
	jnz	maken1
	or	[si+dbbbuf+datr],arch	; archive bit if not dir
maken1:
	mov	al,byte ptr [tcbcdft]	; created class
	mov	[si+dbbbuf+dclass0],al
	or	al,al
	jz	maken2
	cmp	al,' '
	je	maken2
	or	[si+dbbbuf+datr],sys	; set system attribute in secured files
maken2:
	call	wrsector
makenx:
	pop	cx
	pop	dx
	pop	di
	pop	es
	assume	es:nothing
lundef	nptr				; ptr to name for file entry
lundef	attrib				; attribute for file
lendp	create

	
	subttl emptydir - find or make an empty dir entry
	page
;======================================================================
;,fs
; emptydir - find or make an empty directory entry
; 
; in:	dx = cluster of directory
;	ss:bx -> buffer for sector number
;	ds -> bdb
;	ss -> tcb
;
; out:	c on error
;	 ax = error code
;	else nc and
;	 es = dbb of dir sector
;	 ss:bx -> sector number
;	 si = offset in sector of free entry
; 
;,fe
;====================================================================^
	assume	ds:bdb,es:nothing,ss:tcb
lproc	emptydir
lword	numdir
lword	numsect
	push	cx
	mov	ax,[bdbdir]		; first sector of root
	mov	ss:[bx].seclow,ax
	mov	ss:[bx].sechigh,0	; root dir is at 0:bdbdir
	mov	ax,[bdbrnum]
	mov	[numdir],ax		; number of root entries
	mov	ax,dx
	or	dx,dx
	jz	empty2			; z if in root directory
empty1:
	mov	dx,ax
	mov	al,[bdbcsiz]
	xor	ah,ah
	mov	[numsect],ax		; number of sectors in each cluster
	mov	ax,dx			; start sector for this subdir cluster
	sub	ax,2
	xor	cx,cx
	mov	ss:[bx].sechigh,cx	; start with high word of 0
	mov	cl,[bdbcshl]
	jcxz	empty1b
empty1a:
	shl	ax,1
	rcl	ss:[bx].sechigh,1
	loop	empty1a
empty1b:
	add	ax,[bdbclus]
	adc	ss:[bx].sechigh,cx	; cx will be 0
	mov	ss:[bx].seclow,ax	; set low word of sector
empty2:
	call	rddir
	jc	emptyx
	assume	es:dbb
	xor	si,si
empty4:
	mov	al,[dbbbuf+si]
	or	al,al
	jz	emptyx			; finished if first byte of entry is 0
	cmp	al,0e5h
	je	emptyx			; or 0e5h (delete flag)
	or	dx,dx
	jnz	empty5
	dec	[numdir]		; dec number left to check if root
	mov	ax,accdeny
	stc
	jz	emptyx			; root directory is full
empty5:
	add	si,32			; next dir entry in sector
	cmp	si,[bdbssiz]		; at end of sector
	jb	empty4
	add	ss:[bx].seclow,1	; to read next sector
	adc	ss:[bx].sechigh,0
	or	dx,dx
	jz	empty2			; go ahead if root
	dec	[numsect]
	jnz	empty2			; subdir cluster not done
	call	getfat			; get next cluster in subdir chain
	jc	emptyx
	cmp	ax,0fff8h
	jb	empty1			; subdirectory eof if nb

; subdirectory is full, add (and clear) a cluster to it

	call	alloclust
	jc	emptyx
	call	clrclust
	jc	emptyx
	mov	si,dx
	xor	cx,cx
	mov	ss:[bx].sechigh,cx	; zero high word
	mov	cl,[bdbcshl]
	sub	si,2
	jcxz	empty7
empty6:
	shl	si,1
	rcl	ss:[bx].sechigh,1
	loop	empty6
empty7:
	add	si,[bdbclus]		; first sector of newly allocated cluster
	adc	ss:[bx].sechigh,cx	; cx will be 0
	mov	ss:[bx].seclow,si	; store low word of sector
	xor	si,si			; first entry in sector
	call	rddir
emptyx:
	pop	cx
lundef	numdir
lundef	numsect
lendp	emptydir

	
	subttl makelbl - make a label directory entry
	page
;======================================================================
;,fs
; makelbl - create a volume label directory entry 
; 
; only if there is no directory entry with the label attribute
; 
; in:	ds -> bdb
;	es:di -> dir-entry formatted name of volume label
;	ss:bx -> buffer for sector number
;	ss -> tcb
;
; out:	c if error
;	 ax = error code
;	nc if no error
;	 ax = undefined
;	 ss:bx -> sector of dir entry
;	 si = offset in sector of dir entry
;
;,fe
;====================================================================^
	assume	ds:bdb,es:nothing,ss:tcb
lproc	makelbl
lstring	midbuf,<size mid>
	cmp	[bdbalias],0
	jz	maklbl0 		; if not an alias drive, it may have a label
	mov	ax,accdeny		; alias drives can't have labels
	stc
	jmp	short maklblx
maklbl0:
	push	dx
	call	findlbl
	jc	maklbl1
	mov	ax,accdeny
	stc
	jmp	maklblx
maklbl1:
	cmp	ax,filenf		; ok if error was not finding a label
	stc
	jne	maklblx 		; else report the error
	xor	dx,dx			; put dir entry in root dir
	mov	al,lbl			; attribute for dir entry
	call	create
	jc	maklblx

; update the bdb label field (if an extended bpb)
; es:di -> label name

	pushset	ax,bx,cx,si,di,ds,es
	push	di
	push	es
	mov	di,ss
	lea	dx,[midbuf]
	mov	bl,[bdbid]
	inc	bl
	mov	cx,0866h
	push	bx
	call	io0d
	pop	bx
	pop	ds			; pushed as es:di
	pop	si
	or	ax,ax
	jnz	maklblw
	mov	cx,11
	cld
	mov	ax,ss
	mov	es,ax
	lea	di,[midbuf].midVolLabel
	rep	movsb
	mov	di,ss
	lea	dx,[midbuf]
	mov	cx,0846h
	call	io0d
	clc
maklblw:
	popset	ax,bx,cx,si,di,ds,es
maklblx:
	pop	dx
lundef	midbuf
lendp	makelbl

	
	subttl findlbl - find volume label dir entry if any
	page
;======================================================================
;,fs
; findlbl - find volume label directory entry if any
; 
; in:	ds -> bdb
;	ss:bx -> buffer for sector number
;	ss -> tcb
;
; out:	c if error or none found
;	 ax, bx, si = undefined
;	nc if no error and found
;	 ax = undefined
;	 ss:bx -> sector where found
;	 si = offset within sector
;
;,fe
;====================================================================^
	assume	ds:bdb,es:nothing,ss:tcb
findlbl:
	cmp	[bdbalias],0
	jz	findlb0 		; if not an alias drive, can have label
	mov	ax,accdeny		; alias drives can't have labels
	stc
	jmp	short findlbx
findlb0:
	push	es
	push	cx
	mov	cx,[bdbdir]
	mov	ss:[bx].seclow,cx
	mov	ss:[bx].sechigh,0
	mov	cx,[bdbrnum]
findlb1:
	call	rddir
	jc	findlbx
	xor	si,si
	mov	ax,filenf
findlb2:
	cmp	byte ptr es:[dbbbuf+si],0e5h
	je	findlb3
	cmp	byte ptr es:[dbbbuf+si],0
	stc
	je	findlbx
	test	byte ptr es:[dbbbuf+si+datr],lbl
	clc
	jnz	findlbx
findlb3:
	dec	cx
	stc
	jz	findlbx
	add	si,32
	cmp	si,[bdbssiz]
	jb	findlb2
	inc	word ptr ss:[bx]
	jmp	findlb1
findlbx:
	pop	cx
	pop	es
	ret

no_name	db	'NO NAME    '
	
	subttl delete - delete a directory entry
	page
;======================================================================
;,fs
; delete - remove a directory entry and de-allocate all its clusters 
; 
; in:	ds -> bdb
;	ss:bx -> sector of dir entry
;	ss -> tcb
;	si = offset within sector of dir entry
;
; out:	c if error
;	 ax = error code
;	nc if no error
;	 ax = undefined
;
;,fe
;====================================================================^
	assume	ds:bdb,es:nothing,ss:tcb
lproc	delete
lstring	midbuf,<size mid>
	push	es
	push	dx
	call	rddir			; read dir sector containing directory entry
	jc	deletex
	assume	es:dbb

; deallocate any clusters it owns (stop at first invalid cluster - eof)
; flag the directory entry as deleted (0e5h in first byte)

	mov	dl,[si+dbbbuf+datr]
	push	dx
	mov	dx,word ptr [si+dbbbuf+dclust]
	mov	[si+dbbbuf],0e5h
	call	wrsector
	jc	deletex
	call	dealloc
	jc	deletex

; if the directory entry was a label, update the bpb field

	pop	dx
	test	dl,lbl
	jz	deletew
	pushset	ax,bx,cx,si,di,ds,es
	mov	di,ss
	lea	dx,[midbuf]
	mov	bl,[bdbid]
	inc	bl
	mov	cx,0866h
	push	bx
	call	io0d
	pop	bx
	or	ax,ax
	jnz	deleteu
	mov	ax,cs
	mov	ds,ax
	mov	si,offset mo2:no_name
	mov	cx,11
	cld
	mov	ax,ss
	mov	es,ax
	lea	di,[midbuf].midVolLabel
	rep	movsb
	mov	di,ss
	lea	dx,[midbuf]
	mov	cx,0846h
	call	io0d
deleteu:
	popset	ax,bx,cx,si,di,ds,es
deletew:
	clc
	jmp	short deletey
deletex:
	pop	dx
deletey:
	pop	dx
	pop	es
	assume	es:nothing
lundef	midbuf
lendp	delete
	
	subttl getfat - get a file allocation table entry
	page
;======================================================================
;,fs
; getfat - get the value of a file allocation table entry
; 
; in:	dx = cluster number of fat entry to get
;	ds -> bdb
;
; out:	c if error
;	 ax = error code
;	nc if no error
;	 ax = fat entry value
; 
;,fe
;====================================================================^
	assume	ds:bdb
getfat:
	push	es
	push	cx
	push	bx
	mov	ax,dx
	cmp	[bdbcnum],4096-10
	jbe	getfat1

; 16-bit fat (since there are more clusters than fit in 12 bits)

	call	fat16			; sjc optimize
	jc	getfatx
	assume	es:dbb
	mov	bx,cx
	mov	ax,word ptr [dbbbuf+bx] ; and this is the fat entry
	jmp	short getfat4
getfat1:

; 12-bit fat (since the number of clusters fits in 12 bits)

	call	fat12			; sjc optimize
	jc	getfatx
	assume	es:dbb
	xchg	bx,cx			; remember sector number
	mov	ax,word ptr [dbbbuf+bx]
	inc	bx
	cmp	bx,[bdbssiz]
	jne	getfat2 		; e if entry crosses a sector boundary
	mov	bx,cx			; in which case we read the next sector
	inc	bx
	mov	cl,al			; (saving the low byte of the fat entry value)
	call	rdfat
	jc	getfatx
	mov	ah,[dbbbuf]		; high byte of entry is first byte in buffer
	mov	al,cl			; (restore low byte of entry)
getfat2:
	test	dx,1			; odd or even entry?
	jz	getfat3
	mov	cl,4
	shr	ax,cl			; move it to 12 low bits if odd entry
getfat3:
	and	ax,0fffh		; mask out all but our 12 bits
	cmp	ax,0ff8h
	jb	getfat4
	or	ax,0f000h		; so eof looks the same in for 12 & 16 bit fats
getfat4:
	clc				; no error
getfatx:
	pop	bx
	pop	cx
	pop	es
	assume	es:nothing
	ret

	
	subttl putfat - set a file allocation table entry
	page
;======================================================================
;,fs
; putfat - set a file allocation table entry
; 
; note: we rely on caller to know when these changed sectors need to be
; physically written to disk
; 
; in:	dx = cluster number of fat entry to set
;	ax = value to set
;	ds -> bdb
;
; out:	c if error
;	 ax = error code
;	nc if no error
;	 ax = undefined
;
;,fe
;====================================================================^
	assume	ds:bdb
lproc	putfat
lstring secbuf,<size sectorblk>
	push	es
	push	si
	push	cx
	push	bx
	push	ax			; save value to set
	mov	ax,dx
	cmp	[bdbcnum],4096-10
	jbe	putfat1

; 16-bit fat

	call	fat16			; sjc optimize
	pop	ax			; value to set
	jmpc	putfatx
	assume	es:dbb
	mov	si,cx			;jrbr preserve bx
	mov	word ptr [dbbbuf+si],ax ;jrbr
	jmp	putfat5
putfat1:

; 12-bit fat

	call	fat12			; sjc optimize
	pop	ax			; value to set
	jmpc	putfatx
	mov	si,cx
	and	ax,0fffh		; (make sure value fits)
	test	dx,1
	jz	putfat3

; odd-numbered, 12-bit fat entry

	shl	ax,1
	shl	ax,1
	shl	ax,1
	shl	ax,1
	inc	cx
	cmp	cx,[bdbssiz]
	je	putfat2

; odd-numbered fat entry wholly contained in a sector

	and	word ptr [dbbbuf+si],not 0fff0h  ; clear out the old
	or	word ptr [dbbbuf+si],ax ; set the new
	jmp	putfat5
putfat2:

; odd-numbered fat entry which crossess a sector boundary

	and	[dbbbuf+si],not 0f0h
	or	[dbbbuf+si],al		; set low-order byte
	mov	cx,ax			; save value to set
	call	wrfat			;jrbr
	jc	putfatx
	inc	bx
	call	rdfat			; sector containing high-order byte
	jc	putfatx
	mov	[dbbbuf],ch		; set high-order byte
	jmp	putfat5

; even-numbered, 12-bit fat entry

putfat3:
	inc	cx
	cmp	cx,[bdbssiz]
	je	putfat4

; even-numbered fat entry wholly contained in a sector

	and	word ptr [dbbbuf+si],not 0fffh	; clear the old
	or	word ptr [dbbbuf+si],ax ; set the new
	jmp	putfat5
putfat4:

; even-numbered fat entry which crosses a sector boundary

	mov	[dbbbuf+si],al		; set the low-order byte
	mov	cx,ax			; remember the value to set
	call	wrfat			;jrbr
	jc	putfatx
	inc	bx
	call	rdfat			; read sector containing high-order byte
	jc	putfatx
	and	[dbbbuf],not 0fh	; clear the old high-order byte
	or	[dbbbuf],ch		; set the new
putfat5:
	call	wrfat			;jrbr
putfatx:
	pop	bx
	pop	cx
	pop	si
	pop	es
	assume	es:nothing
lundef	secbuf
lendp	putfat

	
	subttl pathfind - parse path and fnm and look for dir entry for fnm
	page
;======================================================================
;,fs
; pathfind - get drive, path and name from an asciiz string 
; and look for dir entry for name
; 
; in:	al != 0 means exclude volume labels
;	es:di -> asciiz path string
;	ss:si -> buffer for dir entry format name
;	ss:bx -> sector number buffer
;	ss -> tcb
; 
; out:	c if error
;	 ax = error code
;	  pathnf invalid drive
;	  invalid path
;	  invalid file name
;	  filenf file not found
;	 bx, cx, dx, si, es undefined
;
;	nc if no error
;	 al = ? if wild-card encountered, else <> ?
;	 ah = undefined
;	 ds = paragraph address of bdb
;	 dx = cluster number for first cluster of directory (-1 for root)
;	 cl = cumulative access level to last directory
;	 ch = undefined
;	 es = paragraph address of device driver if character device
;	 si = offset of device driver if character device
;	      offset in dir sector of dir entry if file
;	 bx = 0 if character device
;	 ss:bx -> sector number of dir sector if file
;	 es -> dbb for file
; 
;,fe
;====================================================================^
	assume	ds:nothing,es:nothing,ss:tcb

dev	db	'DEV        '
dots	db	'..         ',' '	; (used for dot also)
wild	db	'???????????'

lproc	pathfind
lbyte	dotdot
lword	fnmptr
lword	pathseg
lword	pclust
lword	cclust
lword	compseg
ldword	cursect
lbyte	skiplbl
	mov	[skiplbl],al
	mov	[dotdot],'N'		; haven't encountered '..'
	push	di			; this must be pushed last
	mov	[fnmptr],si
	mov	[pathseg],es

; first, do a pretest to see if the path is that of a device driver
; so no media check will be done when a character driver is opened
; at this point:
; es:di -> asciiz path string
; ss:si -> buffer for dir entry format name

	push	ds			; save data ref
	push	ss			; set local seg for parse call
	pop	es
	mov	ds,[pathseg]		; get original path to parse
	xchg	si,di

; original ss:si is now in es:di  (pointer to scratch buffer)
; original es:di is now in ds:si  (pointer to path string)

	push	di
	call	parsenm
	pop	di
	pop	ds			; restore data refs
	jc	pfcpd			; if err from parse, not a device

; es:di still points to scratch buffer - which now holds the device/file name

	call	devicenm		; ck for device before doing media check
	jc	pfcpd			; dev?
	xor	bx,bx			; yes
	jmp	pathfy			; return no err

; the path supplied is not a device driver so restore to the entry registers

pfcpd:
	mov	byte ptr es:[di],' '	; make buffer with space
	mov	es,[pathseg]		; so that md c: fails correctly
	mov	si,[fnmptr]
	pop	di
	push	di
	call	pathdrv 		; get bdb and do a media check
	jc	pfy0
	assume	ds:bdb
	mov	es,cx
	assume	es:cdb
	mov	cl,[cdblvl]		; cumulative access for current sub dir
	mov	es,[pathseg]
	assume	es:nothing
	mov	al,es:[di]
	or	al,al
	mov	ax,filenf
	stc
	jz	pfy0
	mov	al,es:[di]
	call	slash
	jne	pathfa
	mov	cl,3
	inc	di
	mov	dx,-1			; flag root
	mov	al,es:[di]
	or	al,al
	jnz	cordfd
pfy0:
	jmp	pathfy			; nc and <> ? for exit
cordfd:
	mov	dx,[bdbroot]		; cluster of root directory for drive

; for each component of path

pathfa:
	or	dx,dx
	jnz	pathfa1
	mov	cl,3			; always have read/write access to root
pathfa1:
	mov	ax,es:[di]
	add	di,2
	cmp	al,'.'
	jne	pathfb
	mov	al,ah
	or	al,al
	jmpz	pathfh			; z if . followed by 00h
	call	slash
	je	pathfa			; e if . followed by \ (throw it away)
	cmp	al,'.'
	jne	pathfb
	mov	[dotdot],'Y'
	mov	ax,pathnf		; e if ..
	cmp	dx,[bdbroot]
	stc
	jz	pfy0
	cmp	byte ptr es:[di],0
	jmpe	pathfg			; e if .. followed by 00h
pathfb:
	sub	di,2
	mov	es,[pathseg]
	mov	si,[fnmptr]
	mov	al,[skiplbl]
	call	pathcomp
	jc	pathff
	mov	[compseg],es		; save driver seg or dbb seg
	mov	es,[pathseg]
	mov	[pclust],dx
	or	bx,bx
	jz	pathfd			; this component is a device
	cmp	al,'?'			; ? if wild-card encountered
	je	pathfe			; (so must be finished)
	call	rddir
	jc	pfy0
	assume	es:dbb
	mov	dx,word ptr [dbbbuf+si+dclust]
	test	[dbbbuf+si+datr],dir
	mov	es,[pathseg]
	assume	es:nothing
	jz	pathfd			; if this component not a dir, then finished
pathfc:
; BWR 10/8/90 ---------------------------------------------------------------
;
;  Find the next component of the pathname.  To do so, pass all
; slash characters.  (Handle multiple slash characters)
;
        mov	al,es:[di]		; else if \ then next component
	inc	di
	call	slash
        jne     pathfc_x
;
;  Since at least 1 slash character was found, bypass any additional
; ones on the pathname.
;
pathfc_1:
        mov     al, es:[di]             ;Get next character.
        call    slash
        ljne    pathfa                  ;Not a slash.  Go process component.
        inc     di                      ;Was a slash.  Bypass it.
        jmp short pathfc_1
pathfc_x:
;BWR 10/8/90 --------------------------------------------------------------
	dec	di			; else must be finished
pathfd:
	xor	al,al			; flag ? not encountered

; encountered device or file, or wild-card, so this has to be the end

pathfe:
	mov	dx,[pclust]
pathfe2:
	cmp	byte ptr es:[di],0
	je	pathfe1
	cmp	byte ptr es:[di],' '	; have to allow for trailing
	jne	pathfe3 		; blanks before the terminating 0
	inc	di
	jmp	pathfe2
pathfe3:
	mov	es,[compseg]
	mov	ax,pathnf
	stc
	jmp	pathfy
pathfe1:
	mov	es,[compseg]
	jmp	pathfx

; if not found error on some component, see if path evaluates to \dev\device

pathff:
	cmp	ax,filenf
	je	pathff1
	cmp	ax,pathnf
	stc
	jne	pfy1
pathff1:
	mov	es,[pathseg]
	push	ax
	mov	al,es:[di]
	call	slash
	pop	ax
	stc
	jne	pfy1
	inc	di			; (can't be \DEV\)
	push	es
	push	ds
	push	di
	push	cx
	push	ss			; mov ss into es and cs into ds
	push	cs
	pop	ds			; address constant data in code segment
	pop	es
	mov	di,[fnmptr]
	mov	si,offset dev
	mov	cx,11
	push	ax
	call	capscmps		; is it dev?
	pop	ax
	pop	cx
	pop	di
	pop	ds
	pop	es
	stc
	jne	pfy1
	mov	si,[fnmptr]
	push	ax
	mov	al,[skiplbl]
	call	pathcomp
	pop	ax
	jc	pfy1
	or	bx,bx			; component following \dev\ must be device
	stc
	jnz	pfy1
	push	es
	mov	es,[pathseg]
	push	ax
	xor	al,al			; wild-card not encountered
	scasb				; must be end of path
	pop	ax
	pop	es
pfy1:	jmp	pathfy			; note: carry set if <> 0

; path ending in .. so we have to develop dx = parent start cluster

pathfg:
	push	cs
	pop	es			; address constants in code segment
	mov	di,offset dots 		; get dx = parent of last component
	call	findnm			;   (is first cluster of ..)
	jc	pfy1
	assume	es:dbb
					; and then get parent (and ptr) for that
	mov	dx,word ptr [dbbbuf+si+dclust]

; path ending in . so we have to develop dx = parent start cluster and
;   bx:si -> dir entry

pathfh:
	or	dx,dx
	jnz	pathfh1
	mov	dx,-1			; parent of root is -1
	mov	cl,3			; access is read/write
	jmp	pathfy
pathfh1:
	push	cs
	pop	es			; address constants in code segment
	mov	di,offset dots 		; get first cluster of parent dir
	call	findnm
	jc	pfy1
	assume	es:dbb
	mov	[cclust],dx		; start cluster of this dir
	mov	dx,word ptr [dbbbuf+si+dclust]
	mov	[pclust],dx		; start cluster of parent
	push	cs			; address constants in code segment
	pop	es
	mov	di,offset wild
	call	findnm			; first dir entry of parent
	jc	pathfy

; for each directory entry of parent, see if start cluster of dir
;   entry same as the one we're looking for

pathfh2:
	assume	es:dbb
	xor	al,al			; (no wild-cards)
	mov	dx,word ptr [dbbbuf+si+dclust]
	cmp	dx,[cclust]		; compare this start cluster with ours
	mov	dx,[pclust]
	je	pathfx			; returning parent start cluster and ptr
	push	cs
	pop	es			; address constants in code segment
	mov	di,offset wild
	add	si,32
	call	nextnm			; next dir entry
	jnc	pathfh2
	jmp	pathfy
pathfx:
	cmp	[dotdot],'Y'
	clc
	jne	pathfy

; encountered dotdot entry, so have to re-evaluate cumulative access
; level looking back to root (same as looking forward from root)

	mov	cl,3
	or	dx,dx
	jz	pathfy			; access is read/write if parent dir is root
	push	si
	push	dx
	mov	ax,ss:[bx].seclow
	mov	word ptr [cursect],ax
	mov	ax,ss:[bx].sechigh
	mov	word ptr [cursect+2],ax ; save sector number we want
	mov	ch,al			; save wild-card flag
	lea	di,[dots+1]		; starting with this dir (dot entry)
pathfx1:
	push	cs
	pop	es			; address constants in code segment
	call	findnm
	jc	pathfx3
	mov	al,[dbbbuf+si+dclass0]
	call	classlvl
	cmp	al,cl
	jae	pathfx2 		; taking the least allowed access level
	mov	cl,al
pathfx2:
	mov	dx,word ptr [dbbbuf+si+dclust]	; cluster of next dir to look
	mov	di,offset [dots]		; now looking at .. entries
	cmp	dx,[bdbroot]
	jnz	pathfx1 		; z if at root (and finished)
	mov	ax,word ptr [cursect]
	mov	ss:[bx].seclow,ax
	mov	ax,word ptr [cursect+2]
	mov	ss:[bx].sechigh,ax
	call	rddir			; make sure target dir entry still accessible
	jc	pathfx3
	mov	al,ch			; restore wild-card flag
pathfx3:
	pop	dx
	pop	si
pathfy:
	pop	di
lundef	dotdot
lundef	fnmptr
lundef	pathseg
lundef	pclust
lundef	cclust
lundef	compseg
lundef	cursect
lundef	skiplbl
lendp	pathfind

	subttl pathcomp - parse one component of path
	page
;======================================================================
;,fs
; pathcomp - parse next component of path and locate it in directory
; whose first cluster is dx
; 
; in:	al = 1 means exclude volume labels
;	es:di -> asciiz path string
;	ss:si -> buffer for dir-entry formatted name of component
;	ss:bx -> buffer for sector number
;	dx = cluster number of start of dir
;	ds -> bdb
;
; out:	c if error
;	 ax = error code
;	 bx, dx, si, di undefined
;	nc if no error
;	 al = ? if wild-card encountered, else <> ?
;	 bx = 0 if component is a device name, else
;	 ss:bx -> buffer for sector number
;	 bx = sector address of dir entry for component
;	 si = offset in sector of dir entry for component
;	 es:di -> asciiz string following component
;
;,fe
;====================================================================^
	assume	ds:bdb
lproc	pathcomp
lbyte	clvl
lword	fnmptr
lword	pseg
lbyte	skiplbl
	mov	[skiplbl],al
	mov	[clvl],cl
	mov	[fnmptr],si
	mov	[pseg],es
	push	ds			; save ds
	push	es			; mov es into ds, ss into es
	push	ss
	pop	es
	pop	ds
	assume	ds:nothing,es:tcb
	mov	si,di
	mov	di,[fnmptr]
	call	parsenm 		; translate asciiz name to dir entry format
	pop	ds
	push	si
	jc	pathcx			; evidently an invalid name
	mov	di,[fnmptr]
	call	findnm
	jc	pathcx			; evidently not in directory
	assume	es:dbb
	cmp	[skiplbl],0		; wanting to skip labels?
	je	pathc4
	or	bx,bx			; if yes, and a device, continue
	jz	pathc4			; as before
pathc5:
	test	[dbbbuf+si+DATR],LBL	; if not a label, don't skip
	jz	pathc4
	mov	di,ss
	mov	es,di
	mov	di,[fnmptr]
	add	si,32
	call	nextnm
	jc	pathcx
	jmp	short pathc5
pathc4:
	push	es
	push	ss
	pop	es
	mov	di,[fnmptr]
	mov	al,'?'
	mov	cx,11
	repne scasb
	pop	es
	je	pathc2			; return ? if encountered
	xor	al,al
pathc2:
	push	ax
	mov	al,[dbbbuf+si+dclass0]
	call	classlvl
	mov	cl,[clvl]
	cmp	al,cl
	jae	pathc3
	mov	cl,al
pathc3:
	pop	ax
	pop	di
	clc				; no error
	jmp	pathcy
pathcx:
	pop	di
	mov	es,[pseg]
	cmp	ax,filenf
	jne	pathcx1
;BWR 4/11/90
	cmp	byte ptr es:[di], '\'
	je	pathc0
	cmp	byte ptr es:[di], '/'
	je	pathc0
	jmp short pathcx1
pathc0:
;BWR 4/11/90
	mov	ax,pathnf
pathcx1:
	stc
pathcy:
lundef	clvl
lundef	fnmptr
lundef	pseg
lundef	skiplbl
lendp	pathcomp

	subttl findnm - find directory entry for a name
	page
;======================================================================
;,fs
; findnm - find directory entry for a name
; 
; in:	ds -> bdb
;	es:di -> dir entry formatted name
;	dx = cluster number of dir within which to search
;	ss:bx -> sector number buffer
;
; out:	c if error
;	 ax = error code
;	 si = undefined
;	 bx = undefined
;	nc if no error
;	 al = undefined
;	 bx = 0 if device
;	 es = seg of device driver
;	 si = ofs of device driver
;	 ss:bx -> sector number of dir entry if file
;	 es = dbb of dir entry sector
;	 si = ofs in sector of dir entry
; 
;,fe
;====================================================================^
	assume	ds:bdb
findnm:
	push	cx
	mov	cx,es
	call	devicenm
	jc	findnm10
	xor	bx,bx			; if name is a device name
	jmp	findnm2
findnm10:
	mov	es,cx
	mov	ss:[bx].sechigh,0
	mov	cx,[bdbdir]
	mov	ss:[bx].seclow,cx
	or	dx,dx
	jz	findnm1

; compute sector for subdirectory cluster

	mov	ss:[bx].sectmp,dx
	xor	cx,cx
	sub	dx,2
	mov	cl,[bdbcshl]
	jcxz	findnm0a
findnm0:
	shl	dx,1
	rcl	ss:[bx].sechigh,1
	loop	findnm0
findnm0a:
	add	dx,[bdbclus]
	adc	ss:[bx].sechigh,cx	; cx will be zero
	mov	ss:[bx].seclow,dx
	mov	dx,ss:[bx].sectmp	; restore cluster number
findnm1:
	xor	si,si
	call	nextnm
findnm2:
	pop	cx
	ret

	subttl nextnm - find next directory entry for a name
	page
;======================================================================
;,fs
; nextnm - find next directory entry for a name
; 
; in:	ds -> bdb
;	es:di -> directory entry formatted name
;	ss:bx -> current sector number
;	si = offset within current sector
;
; out:	c if error
;	 ax = error code
;	 si = undefined
;	 ss:bx -> undefined
;	nc if no error
;	 ax = undefined
;	 si = offset in sector of dir entry
;	 ss:bx -> sector number of dir entry
;	 es = dbb of dir entry sector
; 
;,fe
;====================================================================^
	assume	ds:bdb
lproc	nextnm
ldword	fnmptr
lword	numdir
lword	numsect
lword	cluster
	push	dx
	push	cx
	mov	word ptr [fnmptr],di
	mov	word ptr [fnmptr+2],es
	cmp	ss:[bx].sechigh,0
	ja	nextnm2
	mov	ax,ss:[bx].seclow
	cmp	ax,[bdbclus]
	jae	nextnm2

; root search
; compute number of root dir entries remaining from bx and si

	mov	[cluster],0
	sub	ax,[bdbdir]		; ax = sector offset into root dir
	xor	dx,dx
	mov	cx,[bdbssiz]
	mul	cx
	add	ax,si			; + offset into sector
	adc	dx,cx			; (cx=0) dx:ax = byte offset into root dir
	add	ax,ax			; divide by 32 by shifting left 3, then
	adc	dx,cx			; shifting right 8 (total shr 5)
	add	ax,ax
	adc	dx,cx
	add	ax,ax
	adc	dx,cx
	mov	al,ah			; (dl:ax shr 8)
	mov	ah,dl			; ax = number of directory entries so far
	mov	dx,[bdbrnum]		; total number in root
	sub	dx,ax
	inc	dx
	mov	[numdir],dx		; number remaining to check + 1
	call	rddir
	jmpc	nextnmx
	mov	di,si
	sub	di,32
	jmp	nextnm7 		; prepare for pre-increment past last entry
nextnm2:

; subdir search
; compute cluster containing bx sector for subdir
; as well as number of sectors remaining in cluster

	mov	ax,ss:[bx].seclow
	mov	dx,ss:[bx].sechigh
	xor	cx,cx
	sub	ax,[bdbclus]
	sbb	dx,cx			; have to zero cx anyway
	mov	cl,[bdbcshl]
	jcxz	nextnm2b
nextnm2a:
	shr	dx,1
	rcr	ax,1
	loop	nextnm2a
nextnm2b:

; calculate sectors left in cluster.

	add	ax,2
	mov	[cluster],ax		; starting cluster for subdir
	sub	ax,2
	mov	cl,[bdbcshl]
	shl	ax,cl			; ax is low word of first sector in cluster
	add	ax,[bdbclus]
	mov	dx,ax			; dx is low(first sector in cluster)
	mov	al,[bdbcsiz]
	xor	ah,ah
	add	ax,dx			; low word of 1st sector past cluster
	sub	ax,ss:[bx].seclow
	mov	[numsect],ax		; number of sectors remaining in cluster
	call	rddir
	jmpc	nextnmx
	mov	di,si
	sub	di,32
	jmp	nextnm7 		; prepare for pre-increment past last entry
	assume	es:dbb

; looking through directory for name

nextnm3:
	call	rddir
	jmpc	nextnmx
	xor	di,di
nextnm4:
	mov	al,[dbbbuf+di]
	or	al,al
	jmpz	nextnm9 		; finished if 0 (name not found)
	cmp	al,0e5h
	jz	nextnm7 		; don't need to check this entry
	mov	dx,di
	push	ds
	lds	si,[fnmptr]
	assume	ds:nothing
	lea	di,[dbbbuf+di]
	mov	cx,11
nextnm5:
	lodsb
	mov	ah,es:[di]
	scasb
	je	nextnm6
	cmp	al,'?'
	je	nextnm6
	callmos1 caps			;** call in mos segment
	xchg	ah,al
	callmos1 caps			;** call in mos segment
	cmp	al,ah
nextnm6:
	loopz	nextnm5
	pop	ds
	assume	ds:bdb
	mov	di,dx			; to start of dir entry
	mov	si,dx
	mov	dx,[cluster]
	je	nextnmx
nextnm7:
	mov	ax,[cluster]
	or	ax,ax
	jnz	nextnm8
	dec	[numdir]
	jz	nextnm9 		; finished with root (name not found)
nextnm8:
	add	di,32
	cmp	di,[bdbssiz]
	jb	nextnm4
	add	ss:[bx].seclow,1
	adc	ss:[bx].sechigh,0
	or	ax,ax
	jz	nextnm3 		; root directory read next sector
	dec	[numsect]
	jnz	nextnm3 		; subdirectory cluster not exhausted
	mov	dx,ax
	call	getfat
	jc	nextnmx
	cmp	ax,0fff8h
	jae	nextnm9 		; subdir exhausted (name not found)
	mov	[cluster],ax
	mov	ss:[bx].seclow,ax
	xor	ax,ax
	mov	ss:[bx].sechigh,ax	; ready to get new sector
	mov	al,[bdbcsiz]		; new number of sectors remaining in cluster
	mov	[numsect],ax
	mov	cl,[bdbcshl]
	mov	ah,ch			; zero high byte
	sub	ss:[bx].seclow,2	; first cluster is 2
	jcxz	nextnm8b
nextnm8a:
	shl	ss:[bx].seclow,1
	rcl	ss:[bx].sechigh,1
	loop	nextnm8a
nextnm8b:
	mov	ax,[bdbclus]
	add	ss:[bx].seclow,ax
	adc	ss:[bx].sechigh,cx	; cx is 0
	jmp	nextnm3
nextnm9:				; name not found
	mov	ax,filenf
	stc
nextnmx:
	mov	di,word ptr [fnmptr]
	pop	cx
	pop	dx
	assume	es:nothing
lundef	fnmptr
lundef	numdir
lundef	numsect
lundef	cluster
lendp	nextnm

	
	subttl srch_list - search a device driver list for a name match
	page
;======================================================================
;,fs
; srch_list - search a device driver list for a name match
; 
; in:	ds:si = pointer to list to search
;	es:si = pointer to name to match
;
; out:	cy if not found, ds:si undefined
;	nc if found, ds:si = address of device driver
; 
;,fe
;====================================================================^
	assume	ds:nothing,es:nothing
srch_list:
	mov	cx,ds
	and	cx,si
	inc	cx
	stc
	jz	dev3			; z if ds:si = ffff:ffff (no more drivers)
	test	byte ptr [si+5],80h
	jz	dev2			; no need to check a block device
	push	di
	push	si
	lea	si,[si+10]		; -> device name
	mov	cx,8
	call	capscmps
	pop	si
	pop	di
	clc
	je	dev3
dev2:
	lds	si,dword ptr [si]	; next device
	jmp	srch_list
dev3:
	ret

	subttl devicenm - find device corresponding to name
	page
;======================================================================
;,fs
; devicenm - find device corresponding to name
; 
; in:	es:di -> directory entry formatted name (first 8 chars significant)
;	ss:bx -> sector number buffer
;
; out:	c if not found
;	 es:si = undefined
;	nc if found
;	 es:si = address of character device driver
;	 ss:bx.seclow & sechigh = 0
; 
;,fe
;====================================================================^
	assume	ds:nothing
lproc	devicenm
	push	ds
	push	cx
	push	di
	mov	cx,11
	mov	al,'?'
	repne scasb			; any question marks and it isn't a device
	pop	di
	stc
	je	devx
	mov	ax,word ptr es:[di]
	cmp	ax,'..' 		; .. and . aren't devices
	je	dev0a
	cmp	ax,' .'
	jne	dev0b
dev0a:
	push	di
	add	di,2
	mov	al,' '
	mov	cx,9
	repe scasb
	pop	di
	stc
	je	devx
dev0b:
	lds	si,[tcbddpf]
	assume	ds:nothing
	call	srch_list		; check the task specific device driver
	jnc	devy			; list first
	cmp	word ptr [tcbddpf],-1   ; if task DOS specific list
	je	dev0c			; don't search main list
	stc
	jmp	devx
dev0c:
	mgetscb2 ds
	assume	ds:grp
	lds	si,[scbdrvr]		; if not task specific, then check the
	assume	ds:nothing		; global list
	call	srch_list
	jc	devx
devy:
	mov	ss:[bx].seclow,0	;jrby flag device
	mov	ss:[bx].sechigh,0	;jrby
	push	ds
	pop	es			; return dd address in es:si
devx:
	pop	cx
	pop	ds
lendp	devicenm

	subttl pathdrv - parse drive from asciiz string
	page
;======================================================================
;,fs
; pathdrv - parse drive from asciiz string
; 
; in:	es:di -> asciiz string
;	ds -> grp
;
; out:	c if error
;	 ax = error code
;	 cx = undefined
;	 dx = undefined
;	nc if no error
;	 ax = undefined
;	 ds = segment address of bdb
;	 cx = segment address of cdb
;	 dx = cluster number of start of current dir
;	 es:di -> past drive designator if any
; 
;,fe
;====================================================================^
	assume	ds:grp
pathdrv:
	mov	al,[tcbcdriv]
	cmp	byte ptr es:[di+1],':'
	jne	pathdr2
	mov	al,es:[di]
	cmp	al,'a'
	jb	pathdr1
	sub	al,'a'-'A'
pathdr1:
	sub	al,'A'
	jb	pathdrx
	cmp	al,'Z'-'A'
	ja	pathdrx
	add	di,2			; past drive designator
pathdr2:

; find bdb for al = drive

	call	finddrv
	jnc	pathdry
	cmp	ax,drivenf
	stc
	jne	pathdry
pathdrx:
	stc
	mov	ax,pathnf		; significant if carry flag set
pathdry:
	ret
	

	subttl finddrv - find bdb for a drive
	page
;======================================================================
;,fs
; finddrv - find bdb corresponding to a drive, then do a media check
; 
; in:	al = drive (a=0)
;
; out:	c if error
;	 ax = error code
;	 cx = undefined
;	 dx = undefined
;	nc if no error
;	 ds = segment address of bdb
;	 cx = segment address of cdb
;	 dx = cluster number of start of current dir (0 for root)
; 
;,fe
;====================================================================^

finddrv:
	call	findbdb
	jc	finddrx
	call	mediachk
finddrx:
	ret

	subttl findbdb - find bdb for a drive
	page
;======================================================================
;,fs
; findbdb - find bdb corresponding to a drive (used by ioctl calls
; which don't care whether the media is changed)
; 
; in:	al = drive (a=0)
;
; out:	c if error
;	 ax = error code
;	 cx = undefined
;	 dx = undefined
;	nc if no error
;	 ds = segment address of bdb
;	 cx = segment address of cdb
;	 dx = cluster number of start of current dir (0 for root)
; 
;,fe
;====================================================================^

findbdb:
	push	ds
	mgetscb2 ds
	assume	ds:grp
	mov	cx,[scbbdbpf]		; first bdb
fndbdb1:
	jcxz	fndbdbx
	mov	ds,cx
	assume	ds:bdb
	mov	cx,[bdbnext]
	cmp	al,[bdbid]
	jne	fndbdb1

; ds = bdb, determine if it's an alias & if so, the right one

	cmp	[bdbalias],0
	je	fndbdb1a		; if a normal drive
	mov	dx,ss
	cmp	dx,[bdbtask]		; right task for bdb?
	jne	fndbdb1 		; if wrong task

; ds = bdb, find cdb for current directory cluster

fndbdb1a:
	pop	cx			; throw away saved ds
	push	ds
	mov	cx,[tcbcdbpf]		; first cdb for task
fndbdb2:
	mov	ds,cx
	assume	ds:cdb
	mov	cx,[cdbnext]
	cmp	al,[cdbdrive]
	jne	fndbdb2
	mov	dx,[cdbclus]		; cluster of current directory
	mov	cx,ds
	or	dx,dx			; (also clearing carry)
	jnz	fndbdby
	mov	[cdblvl],3		; read/write access to root
	jmp	fndbdby
fndbdbx:
	mov	ax,drivenf
	stc
fndbdby:
	pop	ds			; bdb if found
	ret

	subttl parsenm - parse file name and create dir entry name
	page
;======================================================================
;,fs
; parsenm - parse file name and create dir entry name
; 
; in:	ds:si -> asciiz string
;	es:di -> buffer for dir-entry-formatted name
;
; out:	c if error
;	 ax = error code
;	 si, di = undefined
;	nc if no error
;	 ax = undefined
;	 di = undefined
;	 si -> at terminator
; 
;,fe
;====================================================================^
	assume	ds:nothing,es:nothing
parsenm:
	push	cx
	push	ax
	mov	cx,10/2 		; clear dir entry to spaces
	mov	ax,'  '
	rep	stosw
	stosb
	sub	di,11			; back to start of dir entry name
	pop	ax
	mov	cx,8			;jsm 07/21/87 8 because "too many valid chars"
					;jsm logic catches the '.' if present
	mov	al,[si]
	or	al,al
	jz	pnx0
	cmp	al,' '
	je	pnx0
	call	slash
	je	pnx0
	cmp	al,'.'
	jne	parsen1
	movsb				; '.' ok as dir name
	mov	al,[si]
	or	al,al
	jz	pny0
	call	slash
	je	pny0
	lodsb
	cmp	al,'.'			; or '..' followed by 00h or \
	jne	pnx0
	stosb
	mov	al,[si]
	or	al,al
	je	pny0
	call	slash
	je	pny0
pnx0:
	jmp	parsenx
pny0:
	jmp	parseny
parsen1:
	mov	al,[si]
	or	al,al
	jz	pny0
	call	slash
	je	pny0
prsn1a:
	lodsb
	cmp	al,'.'
	je	parsen2
	cmp	al,'*'
	je	prsn1c
prsn1b:
	call	okchar			; disallow all invalid chars (and capitalize)
	jc	parsenx
	stosb
	loop	parsen1

; no such thing as too many valid chars.
; eat rest of them up without storing them.

parsev1:
	mov	al,[si]
	or	al,al
	jz	parseny
	call	slash
	je	parseny
	lodsb				; isn't a legal terminator
	cmp	al,'.'
	je	parsen2

	call	okchar			; disallow invalid chars (and capitalize)
	jnc	parsev1 		; no such thing as too many valid chars
	jmp	parsenx 		; if invalid char
prsn1c:
	mov	al,'?'
	rep	stosb
	mov	al,[si]
	or	al,al
	jz	parseny
	call	slash
	je	parseny
	lodsb
	cmp	al,'.'
	jne	parsenx 		; error if char following * not 0 \ or .
parsen2:
	add	di,cx			; bump to ext dir entry field
	mov	cx,3			;jrbg 3 is all to be copied
parsen3:
	mov	al,[si]
	or	al,al
	jz	parseny
	call	slash
	je	parseny
prsn3a:
	lodsb
	cmp	al,'*'
	je	prsn3c
prsn3b:
	call	okchar			; disallow invalid chars (and capitalize)
	jc	parsenx
	stosb
	loop	parsen3
parsev3:
	mov	al,[si]
	or	al,al
	jz	parseny
	call	slash
	je	parseny
	lodsb
	call	okchar			; disallow invalid chars (and capitalize)
	jnc	parsev3 		; no such thing as too many valid chars
	jmp	parsenx 		; if invalid char
prsn3c:
	mov	al,'?'
	rep	stosb

; sometimes, there will be trailing blanks before the terminating 0

prsn3d:
	mov	al,[si]
	cmp	al,' '
	jne	prsn3e
	inc	si
	jmp	prsn3d
prsn3e:
	or	al,al
	jz	parseny
	call	slash
	je	parseny
parsenx:
	mov	ax,pathnf		; file not found if name invalid
	stc
parseny:
	pop	cx
	ret

	subttl alloclust - add a cluster to the end of an fat chain
	page
;======================================================================
;,fs
; alloclust - add a cluster to a fat chain
; 
; in:	dx = cluster number of previous last cluster
;	ds -> bdb
;	ss -> tcb
;
; out:	c if error
;	 ax = error code
;	 dx = undefined
;	nc if no error
;	 ax = undefined
;	 dx = number of added cluster
;	 fat entry at previous last cluster position set to added cluster
;	 fat entry at added cluster position set to 0(f)fffh
; 
;,fe
;====================================================================^
	assume	ds:bdb,es:nothing,ss:tcb
alloclust:
	call	chk_bdbgate
	push	cx
	push	si
	mov	cx,dx
	mov	dx,[bdbclustl]		;####
	xor	si,si			; init once flag

; find a free cluster

alloc1:
	inc	dx
	mov	ax,accdeny
	cmp	dx,[bdbclustl]		;####
	stc
	lje	allocx			; disk full (back to where we started)
	cmp	dx,[bdbcnum]
	jb	alloc2
	or	si,si			; if the last cluster is an eof
	stc				; mark, must prevent wrapping to
	jnz	allocx			; beginning more than once.
	inc	si
	mov	dx,2			; wrap to beginning cluster at end
alloc2:
	cmp	dx,2
	jae	alloc3
	mov	dx,2
alloc3:
	call	getfat
	jc	allocx
	or	ax,ax
	jnz	alloc1

; chain free cluster to previous last cluster
; and set free cluster fat entry to eof

	cmp	cx,0fff8h
	jae	alloc4			; ae if first cluster allocated
	push	dx
	mov	ax,dx
	mov	dx,cx
	call	putfat			; previous fat entry pointing to new cluster
	pop	dx
	jc	allocx
alloc4:
	mov	[bdbclustl],dx		;####
	mov	ax,0ffffh
	call	putfat			; new fat entry set to eof
	jc	allocx
	cmp	[bdbcfree],-1
	je	allocy			; e if number free not valid yet
	mov	cx,[bdbcfree]
	dec	cx
	call	setfree 		; one less is free
	clc
	jmp	allocy
allocx:
	mov	cx,-1			; # free is invalid if there's an error
	pushf				; save carry flag
	call	setfree
	popf				; restore carry flag
allocy:
	call	exit_bdbgate
	pop	si
	pop	cx
	ret

	subttl setfree - set the number of free clusters on a block device
	page
;======================================================================
;,fs
; setfree - set the number of free clusters on a block device
; 
; in:	cx = new number of free clusters on the block device
;	ds -> bdb
;
; out:	bdb's of all drives referring to the same physical drive as the
;	input drive will have their free cluster count updated
;
;,fe
;====================================================================^
	assume	ds:bdb
setfree proc
	push	ax
	push	ds
	mov	ax,[bdbreal]		; bdb of the real drive
setf10:
	or	ax,ax			; next drive to check exists?
	jz	setf20			; if no more
	mov	ds,ax			; move to the new drive
	mov	ax,[bdbanxt]		; next alias drive on chain
	mov	[bdbcfree],cx		; set free clusters for this one
	jmp	setf10			; next
setf20:
	pop	ds
	pop	ax
	ret
setfree endp

	subttl dealloc - deallocate from current cluster to end of chain
	page
;======================================================================
;,fs
; dealloc - deallocate from current cluster to end of chain
; 
; in:	dx = cluster number to start from
;
; out:	c if error
;	 ax = error code
;	nc if no error
;	 ax = undefined
; 
;,fe
;====================================================================^
	assume	ds:bdb
dealloc:
	push	dx
	push	cx
dealloc1:
	cmp	dx,2
	jb	dealloc2		; < minimum valid cluster
	cmp	dx,[bdbcnum]
	jae	dealloc2		; > maximum valid cluster
	call	getfat
	jc	deallocx
	dec	dx			;####
	cmp	dx,[bdbclustl]		;####
	ja	dealloc1a		;####
	mov	[bdbclustl],dx		;####
dealloc1a:				;####
	inc	dx			;####
	mov	cx,ax			; remember value of fat entry for cluster
	xor	ax,ax			; and clear the fat entry (de-allocated now)
	call	putfat
	jc	deallocx
	mov	dx,cx
	cmp	[bdbcfree],-1
	je	dealloc1		; (# free not set yet)
	or	dx,dx
	jz	dealloc1		; if cluster already free, don't increment
	inc	[bdbcfree]		; one more free
	jmp	dealloc1
dealloc2:
	clc
	jmp	deallocy
deallocx:
	mov	[bdbcfree],-1		; flag invalid # free clusters
deallocy:
	pop	cx
	pop	dx
	ret

	subttl clrclust - clear all sectors of a cluster to 0's
	page
;======================================================================
;,fs
; clrclust - clear all sectors of a cluster to 0's
; 
; in:	dx = cluster
;	ds -> bdb
; 
; out:	c if error
;	 ax = error code
;	nc if no error
; 
;,fe
;====================================================================^
	assume	ds:bdb
lproc clrclust
lstring secbuf,<size sectorblk>
	push	es
	push	di
	push	dx
	push	cx
	push	bx
	xor	cx,cx
	mov	bx,dx
	mov	dx,cx			; dx:bx is 32 bit cluster number
	mov	cl,[bdbcshl]
	sub	bx,2
	jcxz	clrclus0a
clrclus0:
	shl	bx,1
	rcl	dx,1
	loop	clrclus0
clrclus0a:
	add	bx,[bdbclus]		; bx = sector address of cluster
	adc	dx,cx			; cx will be 0 here
	mov	cl,[bdbcsiz]
	xor	ch,ch			; cx = number of sectors in cluster
	mov	[secbuf].seclow,bx
	mov	[secbuf].sechigh,dx
	lea	bx,secbuf		; point bx to sector number
clrclus1:
	call	rddir
	jc	clrclusx
	assume	es:dbb
	push	cx			; clear the sector
	lea	di,dbbbuf
	mov	cx,[bdbssiz]
	shr	cx,1
	xor	ax,ax
	rep	stosw
	pop	cx
	call	wrsector
	jc	clrclusx
	add	ss:[bx].seclow,1	; inc doesn't set carry
	add	ss:[bx].sechigh,0	; increment sector number
	loop	clrclus1
clrclusx:
	pop	bx
	pop	cx
	pop	dx
	pop	di
	pop	es
lundef	secbuf
lendp	clrclust

	subttl findrlb - find conflicting rlb if any
	page
;======================================================================
;,fs
; findrlb - find a lock for this file which includes any portion of
; a region
; 
; updated 12/02/88 sah made change for special condition 
; where requested regions > 32 bits. in this case we should 
; say that lock is found
; 
; in:	cx:dx = offset in file of region to access
;	si:di = length of region to access
;	ds -> gfb
;	ss -> tcb
; 
; out:	nc if a lock is found
;	 es = rlb for lock
;	 ax = undefined
;	c  if no lock is found
;	 es = undefined
;	 ax = undefined
; 
;,fe
;====================================================================^
	assume	ds:gfb,es:nothing,ss:tcb
findrlb:
	push	bp
	push	di
	push	si
	add	di,dx
	adc	si,cx			; jsm 05/12/87 -- used to be add (!)
	mov	[tcblock],'N'
	jnc	frlb0
	mov	[tcblock],'Y'
	pop	si
	pop	di
	push	di
	push	si
frlb0:
	mov	ax,[gfbrlb]

; look at each rlb for this gfb
;   conflicting rlb is found if
;     region start < rlb end+1 and region end+1 > rlb begin

frlb1:
	or	ax,ax
	stc
	jz	frlbx
	mov	es,ax
	assume	es:rlb
	mov	ax,[rlbngfb]

; if request end check is > 32 bits than valid lock if rlb
; is found with its end (using size given by request) is
; is greater than 32 bits also

	cmp	[tcblock],'N'		; request > 32 bits
	je	frlb2
	push	si
	push	di			; save si and di for next check
	add	di,word ptr [rlbbgn]
	adc	si,word ptr [rlbbgn+2]	; check if greater > 32
	pop	di
	pop	si
	jnc	frlb1			; time to test again
	jmp	short frlb3		; found rlb > 32 bits
frlb2:
	mov	bx,dx
	sub	bx,word ptr [rlbend]
	mov	bx,cx
	sbb	bx,word ptr [rlbend+2]
	jae	frlb1			; region start >= rlb end+1
	mov	bp,di
	sub	bp,word ptr [rlbbgn]
	mov	bx,si
	sbb	bx,word ptr [rlbbgn+2]
	jb	frlb1			; region end+1 < rlb begin
	or	bx,bp
	jz	frlb1			; region end+1 = rlb begin

; conflicting lock found, return nc (also z if region matches exactly)

	cmp	dx,word ptr [rlbbgn]
	jne	frlb3
	cmp	cx,word ptr [rlbbgn+2]
	jne	frlb3
	cmp	di,word ptr [rlbend]
	jne	frlb3
	cmp	si,word ptr [rlbend+2]
frlb3:
	clc
frlbx:
	pop	si
	pop	di
	pop	bp
	ret

	subttl chklock - check access to a region
	page
;======================================================================
;,fs
; chklock - check access to a region
; 
; in:	cx:dx = offset in file of region to access
;	si:di = length of region to access
;	ds -> gfb 
;	es -> tfb 
;	ss -> tcb
; 
; out:	nc if there are no conflicting locks on region
;	z if there is a lock on the region owned by this process
;	else nz
;	 ax = undefined
;	c if there is a conflicting lock on region
;	 ax = undefined
; 
;,fe
;====================================================================^
	assume	ds:gfb,es:tfb,ss:tcb
chklock:
	push	dx			;jrba
	push	cx
	push	bx
	push	es
	call	findrlb
	assume	es:rlb
	mov	ax,[rlbtfb]
	mov	cx,[rlbpsp]
	mov	dx,[rlbhdl]		;jrba
	pop	es
	assume	es:tfb
	jnc	chklk1			; found a conflicting lock
	or	ax,-1			; no conflict with any other locks
	jmp	chklky			;   (return nc and nz)
chklk1:
	mov	bx,es
	cmp	ax,bx
	jne	chklkx			; owned by a different tfb
	cmp	cx,[tcbpsp]		; nc and z if conflicting lock is owned by
	jne	chklky			;   this tfb and this psp
	cmp	dx,[tfbfnh]		;jrba for this handle
	je	chklky			;jrba
chklkx:
	mov	ax,accdeny
	stc
chklky:
	pop	bx
	pop	cx
	pop	dx
	ret

	subttl iolock - try to acquire read/write access to a region
	page
;======================================================================
;,fs
; iolock - try to acquire read/write access to a region
; 
; in:	cx:dx = offset in file of region to access
;	si:di = length of region to access
;	ds -> gfb
;	es -> tfb 
;	ss -> tcb
; 
; out:	nc if there are no conflicting locks on region
;	c if there is a conflicting lock on region owned by another
; 
;,fe
;====================================================================^
	assume	ds:gfb,es:tfb,ss:tcb
lproc	iolock
lword	retries
	push	si
	push	cx
	mov	ax,[tcbntry]
	inc	ax
	mov	[retries],ax
iolk1:
	call	chklock
	jmpnc	iolkx

; locking conflict, retry as many times
;   as many times as required by ioctl

	dec	[retries]
	stc
	jz	iolk2
	push	ds
	push	dx
	push	es			; jsm
	push	ax			; jsm
	mov	es,[sbios2]		; jsm
	mov	ax,es:[timloc]		; jsm get current system timer
	mov	[tcbwinfo],ax		; jsm store current system time for polling
	pop	ax			; jsm
	pop	es			; jsm
	mov	word ptr [tcbpoll],offset mo2:lockpoll	;jsm
	mov	word ptr [tcbpoll+2],cs
	and	[tcbwait],not 06h	; clear bits 2,1
	or	[tcbwait],01h		; set bit 0
	callmos1 suspend		;** call in mos segment
	pop	dx
	pop	ds
	jmp	iolk1
iolk2:
	mov	ax,accdeny
	cmp	[tfbalow],0		; return access denied error if file open
	stc				;   with a sharing mode other than
	jne	iolkx			;   compatibility

; retries exhausted, do an int 24h

	push	ds
	push	di
	cmp	[gfbdev],0
	jne	iolk2a
	push	ds
	mov	ds,[gfbbdb]
	assume	ds:bdb
	mov	al,[bdbid]
	pop	ds
	assume	ds:gfb
iolk2a:
	lds	si,[gfbdrvr]
	mov	di,12			; general error sent to int 24h
	mov	[tcberrcod],nlock	; extended error code
	mov	ah,dosx and (not ignorex)  ; ah as defined by int 24h doc
	call	toint24
	pop	di
	pop	ds
	jc	iolkx			; fail chosen
	jnz	iolkx			; ignore chosen
	mov	cx,[tcbntry]		; else retry chosen
	inc	cx
	mov	[retries],cx
	jmp	iolk1
iolkx:
	pop	cx
	pop	si
lundef	retries
lendp	iolock

	subttl okchar, slash, capscmps
	page
;======================================================================
;,fs
; okchar - test a char for validity within a file name 
; and capitalize char
; 
; in:
;
; out:	return c if al = char is invalid in a file name
;	else return nc and al = caps(char)
; 
;,fe
;====================================================================^
	assume	ds:nothing,es:nothing,ss:tcb
okchar:
	cmp	al,'0'			;deal efficiently with most usual case
	jb	okch2			;  (digits and letters)
	cmp	al,'9'
	jbe	okch1
	cmp	al,'A'
	jb	okch2
	cmp	al,'Z'
	jbe	okch1
	cmp	al,'a'
	jb	okch2
	cmp	al,'z'
	ja	okch2
	sub	al,'a'-'A'		; capitalize lower case letters
okch1:
	clc
	ret
okch2:
	call	slash
	je	okch3
	cmp	al,'|'			; if they get here it doesn't matter if
	je	okch3			;   it takes too long (serves them right)
	cmp	al,'['
	je	okch3
	cmp	al,'\'
	je	okch3
	cmp	al,']'
	je	okch3
	cmp	al,'<'
	je	okch3
	cmp	al,'='
	je	okch3
	cmp	al,'>'
	je	okch3
	cmp	al,';'
	je	okch3
	cmp	al,':'
	je	okch3
	cmp	al,'/'
	je	okch3
	cmp	al,'.'
	je	okch3
	cmp	al,','
	je	okch3
	cmp	al,'+'
	je	okch3
	cmp	al,'*'
	je	okch3
	cmp	al,'"'
	je	okch3
	cmp	al,' '
	jb	okch3			; strange but true, space is ok
	callmos1 caps			;** call in mos segment
	clc
	ret
okch3:
	stc
	ret

;======================================================================
;,fs
; slash
; 
; in:
;
; out:	return z if al = slash char '/' or '\'
; 
;,fe
;====================================================================^
slash:
	cmp	al,'/'
	je	slash1
	cmp	al,'\'
slash1:
	ret

;======================================================================
;,fs
; capscmps
; 
; in:	ds:si -> 1st string
;	es:di -> 2nd string
;
; out:	zr/nz set depending on comparison
; 
;,fe
;====================================================================^
capscmps:
	jcxz	cmpcap3
cmpcap1:
	lodsb
	mov	ah,es:[di]
	scasb
	je	cmpcap2
	callmos1 caps			;** call in mos segment
	xchg	al,ah
	callmos1 caps			;** call in mos segment
	cmp	al,ah
cmpcap2:
	loope	cmpcap1
cmpcap3:
	ret

	subttl timestamp - get date and time stamp for file
	page
;======================================================================
;,fs
; timestamp - get date and time in directory entry format
; 
; in:
;
; out:	cx = time and dx = date in format suitable for directory entry
; 
;,fe
;====================================================================^
	assume	ds:nothing,es:nothing,ss:tcb
timestamp:
	callmos1 getdate		;** call in mos segment
	sub	cx,1980
	mov	ah,cl
	mov	al,dh
	mov	cl,4
	shl	al,cl
	shl	ax,1
	or	al,dl
	push	ax			; ax = date in dir entry format
	callmos1 gettime		;** call in mos segment
	shr	dh,1
	mov	al,cl
	mov	ah,ch
	add	al,al
	add	al,al
	mov	cl,3
	shl	ax,cl
	or	al,dh
	mov	cx,ax			; cx = time in dir entry format
	pop	dx
	ret

	subttl moserror - set mos error codes
	page
;======================================================================
;,fs
; moserror - set mos error codes
; 
; in:
; 
; out:	ax = error code
;	if ax <> 0 set tax (application ax register) to error code and set
;	 carry in tflag (application carry flag)
;	else clear carry flag in tflag
; 
;,fe
;====================================================================^
	assume	ds:nothing,es:nothing,ss:tcb
moserror:
	and	[tflag],not carry
	or	ax,ax
	jz	moser1
	mov	[tcberrcod],al		;jsm 09/25/87 only set ext'd error if error
	mov	[tax],ax
	or	[tflag],carry
	test	ax,8000h
	jz	moser1
	mov	[tax],cx		; ax has extended error code, return code in cx
moser1:
	ret

ddt	ends
	end

