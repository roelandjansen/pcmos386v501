	include page.inc
	title	mosfutl2 - mosfun39 utility subroutines
comment ^================================================================
		      development specification

 program name:	$$mos.com		assigned to: jim bean
 module name:	mosfutil		assign date: 01/30/86
 entry points:	mosfun39-mosfun5c	completed: 09/03/86
 entry from:	mosint39, mosfun0f
 entry method:	call
 calls:		device drivers, mosliman, mossaver(mosrestore),
		mosddint(setbdb), terminate, suspend, caps, getdate
		gettime
 purpose:	file handle functions
 last update:	08/18/1992
========================================================================

jsm 02/27/87	fixed wrsector to invalidate buffers until wrbf
		returned successfully

dam 03/03/87	moved to grp group (god i hope it works!)

sah 05/08/87	added clc before jumping out in flushrange & invalrange

sah 06/24/87	corrected problem with request headers, hyperbug

jsm 07/21/87	added cpycmap and eblcmap routines so create (functions
		3c & 16) can create files with any class.

sah 08/05/87	check if trying to write 0 bytes to devwrite and return
		if so - this avoids mos possiablity of writing on some
		she is not suppose to.	(like tcbdta in my case)

jrb 01/21/88	getclust was computing the rd/wr starting cluster
		assuming that the sector offset into the file fit in
		16 bits, 32m seek was broken

sah 01/21/88	change scbseg and zero seg to mgetxxxx macros

sah/rbr 02/11/88 change inter-segment calling conventions
		added caller1 and callfun1 (for int 21 function
		depatcher) and remove mos2

sah\rdr 02/20/88 move ddt segment to mo2 group

jrb 04/13/88 	changed shl to rcl @ blkrdf1: to correct large vol
		problem - a read extending through a fragmented
		allocation would map clusters > 4000h to the
		cluster mod 4000h

mjs  4/24/88	modify todriver to skip retries when a block device
		returns a device not ready error.  (also modified
		mosddblk to skip retries in such a case - zenith/navy)
		also, modified media check to mark gfb's as invalid
		when dbb's are invalidated.  This is to fix cadkey's
		install program.

jrb  5/02/88	changes for caching - basically split off everything
		below the level of blkread and blkwrite and put it in
		mosfutl3.asm
		changed toint24 to recognize a flush bit for special
		handling
		changed mediachk to call to check for dirty buffers
		and to invalidate buffers
		changed various retry counts from 3 to 4

jrb  5/13/88	toint24 wasn't saving scb cache variables which needed
		to be saved - worse, it was restoring mapvsa with the
		wrong values because it was placed in the wrong pop
		order

mjs 5/19/88	fix error handling code in todriver - in certain cases,
		would not return from todriver with the carry flag set.

jrb 6/3/88	changed behavior of fat-id bit set during media check
		corrected rd of first fat sector to actually do it
		freed it immediately after so build-bpb wouldn't
		throw it away without invalidating it

jrb 6/4/88	changed toint24 to reflect the fact that cacheing
		doesn't use the video save buffer any more

rdg 6/20/88	changed todriver at todrvrxg so that device status (ax) 
		is not destroyed when calculating bytes sent. (ptr 0050)

sah 10/13/88	added updating critical flags for tsr support during
		critical errors.  i.e function 5d06h	clean it up!

sah 01/26/89	change lock equate to nlock (masm 5.10 compatibility)

mjs 04/06/89	modified toint24 to save the value of scbinmos and
		set it to 0 before issuing the int24.  quickbasic's
		printer error handler was testing the indos flag during
		and int24 and haning up when it was != 0.

rkg 04/21/89	handle int 24's for parallel ports special.  Allow task
		switching and normal processing.

sah 07/25/89	corrections for novell, gave full access for invalid
		classes.

mjs 10/10/89	correct crash of es in toint24.
		modify sector size calculations

bwr 11/28/89	marked messages for foreign language translation.

sah 12/14/89	remove mosregs2.inc

mjs 03/07/90	added re-entrance gating logic to todriver and toint24
		to accomodate the disk busy task switching logic.

mjs 03/15/90	corrected bug in xfindbdb.  was trying to return parm
		in ds register but pushing and poping!

mjs 03/19/90	remove all code pertaining to bdb specific gating.
		implmeneted absolute bdb gating permanently.

sah 04/19/90    remove reference to tcbres

bwr 04/23/90	the logic within subroutine "toint24" that sidestepped
		applications own critical error handlers is incorrect.
		(the logic was backward, causing mos's critical error
		window to be called at the wrong time). however, pre-emption
		of application-installed critical error handlers is a
		"feature" that violates dos compatibility and has been
		removed.  this corrects a problem discovered with a
		btrieve application which caused termination of the
		app. upon abort of the error.

mjs 07/23/90	modify todriver/drvpoll to test for a timeout.  if a
		task is waiting at the todriver gate level for more
		than a few ticks, as soon as the task that's inside
		gets done, short change its slice.

mjs 07/24/90	corrected remainder calc at start of getclust to
		work for files > 32mb

mjs 08/03/90	modified todriver to not increment or decrement scbdrbsy
		when scbtsl15 != Y.  this prevent a lockup when abort from
		a drive door open critical error.

BWR 11/05/90      Compatibility fix for Corel CD-WORM driver.  Device
                driver being called with wrong request header length.
                Due to some weird Microsoft convention, the device
                header length field does NOT consider the Volume ID
                fields as part of the request header length for DOS
                versions < 4.00.  For DOS 4.0 or later, the entire
                header is included in the length field.
                  The Corel driver was deciding that the request
                header was a DOS 4.00 request header based on the fact
                that the RH length was NOT 22 bytes, causing him to
                look for the starting sector number at a different
                location in the RH, and to make matters worse, he was
                looking for a double-word sector number at that
                location which was, of course, garbage.  The side
                effect of all this wound up being a divide overflow
                condition within the driver.

mjs 11/08/90	getclust was using tfbrccur when it hadn't been set yet.
		this occured when a file was opened and written to more 
		than once before being closed.  this could happen by
  		multiple opens within one task or single opens within
		multiple tasks.  corrected by testing tfbrccur != 0 before
		using it.

mjs 04/09/91	improved disk busy gating logic in toint24.  if one task
		incurred a critical error while another was doing disk i/o,
		the system could get stalled.  the logic that uses
		t224poll needs to know which task is within the bdb
		and todriver gates.
		also, fixed omission of code within toint24 which caused
		the abort choice to not jump to terminate whtn the flshflg
		was set.  this was ptr494

BWR 04/11/91    New routine in MOSINT17, Determine_route called from
                this module.  Part of MOSINT17 refit.

mjs 05/09/91	modified toint24 to set the tcb24nest flag to 1 when
		within toint24.  on exit, the new nest_chk function
		checks for a reentry attempt where tcb24nest will hold
		2.  when this is detected, tcbflush is set to 'Y' to
		cause flush to be called so the deferred error condition
		will be dealt with.

mjs 05/24/91	modified the todriver logic which sets/clears tcbcrit24 
		so that automatic retries will be done for lpt outputs
		no matter what type of redirection is in effect.

mjs 10/07/91	fix dbts/prtsc/spool bugs (patch410.118).
		changed the todriver gating logic to use suspend2
		instead of suspend.  prevents re-entrancy problems
		due to the short-circuit return that suspend will
		make when the intsl flag != 0.

mjs 12/16/91	dlg mods: modified declaration of the request header in
		todriver.  corrected a doubleword addition within blkread
		to use adc for the high word.

================ 5.01 Kernel Ends Here ====================================

mjs 08/18/92	clean up segment declarations

=======================================================================^

.xlist
;	include mosfutl2.pub
	include group.inc
	include mosregs.inc
	include moscdb.inc
	include mosgfb.inc
	include mostfb.inc
	include mosrlb.inc
	include mosbdb.inc
	include macros.inc
	include	dskstruc.inc

tcb	segment at 1234h
	include mostcb.inc
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
	extrn	m1retf:word, timparm:near, timchk:near, reordlst:near
	extrn	determine_route:near
mosseg	ends

;======================================================== ddt segment
if 0 eq 0
segment_num = 2
endif
ddt	segment
	assume	cs:mo2,ds:grp,es:nothing,ss:tcb

	extrn	terminate:near, mosrestore:near, sbios2:word
	extrn	caps:near, getdate:near, gettime:near
	extrn	suspend:near, setbdb:near, mosheman:near
	extrn	nullpoll8:near, nullpoll9:near, getfat:near
	extrn	timestamp:near, flushdir:near, flushdata:near, 
	extrn	wrfat:near, rdbf:near, wrbf:near, rddir:near
	extrn	wrsector:near, flush:near, rdfat:near, 
	extrn	flush24:near, chklogd:near, chkbdb:near, 
	extrn	invbdb:near, freecache:near, cmap:near, 
	extrn	rddata:near, cfree:near, findbdb:near
	extrn	suspend2:near		

	public	toint24, caller1, m2retf, mo1seg, callfun1
	public	blkread, blkwrite, mediachk, devchk, todriver
	public	getclust, devread, devwrite, classbits
	public	cpycmap, eblcmap, classlvl, encrypt, decrypt
	public	random

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
retry24h equ	84 or 8000h
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


; the following code is new method of inter-code-segment transfer of
; call mos (segment) routines from mos 2nd code segment.  to do this
; use the callmos1 macros:
;	call	caller1
;	dw	offset grp:routine

cal1off dw	offset mos:m1retf
mo1seg	dw	0			; filled in only by mosinit

; note: if mo1seg is a protected-mode selector, set its rpl to 3!

caller1 proc	near
	push	bx
	push	bp			; save original bp
	mov	bp,sp
	push	cs			; selector for final return
	mov	bx,[bp+4]		; address data word following the call
	inc	bx
	inc	bx
	push	bx			; set offset for final return
	push	cs:[cal1off]		; put mos near return address on stack
	push	cs:[mo1seg]		; push mos selector on stack
	push	cs:[bx-2]		; put offset of called rtn on stack
	mov	bx,[bp+2]		; recover original bx
	mov	bp,[bp] 		; recover original bp
	db	0cbh			; retf enters called routine in mos
caller1 endp

m2retf	label	near			; resume logic in mos
	db	0cah,6,0		; retf 6

; the following routine is use to call mos function in 2nd code segment
; from the int 21 function despatcher.	 the offset of function is pass
; in bx.

callfun1 proc	far
	call	bx
	ret
callfun1 endp

	subttl classlvl - retrieve class access permission bits
	page
;======================================================================
;,fs
; classlvl - retrieve class access permission bits
;
; in:	ss = paragraph address of class map tcb
;	al = class to retrieve
;
; out:	al = access bits
;
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:tcb
classlvl proc near
	push	ds
	push	ss
	pop	ds
	assume	ds:tcb
	call	classbits
	pop	ds
	ret
classlvl endp

	subttl classbits - retrieve class access permission bits
	page
;======================================================================
;,fs
; classbits - retrieve class access permission bits
;
; in:	ds = paragraph address of class map tcb
;	al = class to retrieve
;
; out:	al = access bits
;
;,fe
;======================================================================
	assume	ds:tcb
classbits proc near
	push	bx
	mov	bl,al
	mov	al,3			; full access to blank or null class
	or	bl,bl
	jz	classx
	cmp	bl,' '
	je	classx
	sub	bl,'A'
	jb	classx
	cmp	bl,'Z'-'A'
	ja	classx
	push	cx
	mov	cl,bl
	xor	bh,bh
	shr	bx,1
	shr	bx,1			; / 4 since 4 classes / byte
	mov	al,tcbcmap[bx]
	and	cl,3			; 0, 1, 2, 3 class field within byte
	shl	cl,1			; cl = 0, 2, 4, 6 (shift right count for field)
	shr	al,cl
	and	al,3
	pop	cx
classx:
	pop	bx
	ret
classbits endp

	subttl cpycmap, eblcmap -- class access map change utilities
	page
;======================================================================
;,fs
; cpycmap, eblcmap -- class access map change utilities
;
; copies something the size of the tcbcmap variable from ss:si to ss:di.
; 
; in:	ss:si -> source of copy
;	ss:di -> destination for copy
;
; out:	si and di changed.
;
;,fe
;======================================================================
cpycmap proc near
	push	ax
	push	cx
	push	ds
	push	es
	mov	ax,ss
	mov	ds,ax
	mov	es,ax
	cld
	mov	cx,size tcbcmap
	rep	movsb			; copy the 7 bytes of the class map
	pop	es
	pop	ds
	pop	cx
	pop	ax
	ret
cpycmap endp

	subttl eblcmap - set all locations in the tcbcmap to full access
	page
;======================================================================
;,fs
; eblcmap - set all locations in the tcbcmap to full access
;
; gives tcb pointed to by ss full access to all classes by 
; setting all bytes of the tcbcmap to ff's.
;
; in:
;
; out:
;
;,fe
;======================================================================
eblcmap proc near
	push	ax
	push	cx
	push	di
	push	es
	mov	ax,ss
	mov	es,ax
	mov	al,0ffh 		; give complete access to all classes
	lea	di,[tcbcmap]
	mov	cx,size tcbcmap
	rep	stosb			; copy the 7 bytes of the class map
	pop	es
	pop	di
	pop	cx
	pop	ax
	ret
eblcmap endp

	subttl devread - read from a character device
	page
;======================================================================
;,fs
; devread - read from a character device
;
; in:	es:di -> buffer to read into
;	cx = number of bytes to read
;	check device driver to see if read would wait in device driver
;	  and suspend task if so
;
; out:	c if error
;  	 ax = error code
;  	 cx = number of bytes read before error
;	else
;  	 cx = number of bytes read
;  	 ax = undefined
;
;,fe
;======================================================================
	assume	ds:gfb,es:nothing,ss:tcb
devread proc near
	push	ds
	push	si
	push	dx
	push	bx
	lds	si,[gfbdrvr]
	assume	ds:nothing
devrd1:
	mov	al,6
	mov	ah,80h			; 80h for character device
	xor	dx,dx
	call	devchk
	mov	bx,cx			; nothing read this time if error here
	mov	cx,0
	jc	devrd2			; shouldn't be any errors here, just goto read
	mov	cx,bx
	test	ah,02h
	jz	devrd2			; busy bit clear if chars ready (not busy)
	mov	word ptr [tcbpoll],offset mo2:nullpoll8  ;%%%%
	mov	word ptr [tcbpoll+2],cs
	and	[tcbwait],not 06h	; clear bits 2,1
	or	[tcbwait],01h		; set bit 0
	callmos1 suspend		;** call in mos segment
	jmp	devrd1
devrd2:
	mov	al,4			; read function to device driver
	mov	ah,80h or dosx or rdx
	call	devio
	jnc	devrdy
devrdx:
	and	ax,7fh
	stc
devrdy:
	pop	bx
	pop	dx
	pop	si
	pop	ds
	ret
devread endp

	subttl devwrite - write to a character device
	page
;======================================================================
;,fs
; devwrite - write to a character device
;
; in:	es:di -> buffer to write from
;	cx = number of bytes to write
;
; out:	c if error
;	 ax = error code
;	else
;  	 cx = number of bytes written
;  	 ax = undefined
;
;,fe
;======================================================================
	assume	ds:gfb,es:nothing,ss:tcb
devwrite proc near
	or	cx,cx			;sah check to see if nothing to write
	jnz	devwrnz
	clc
	ret				;sah do nothing on nothing to write
devwrnz:				;sah doesn't hurt anything but may hide bugs
	push	ds
	push	si
	push	dx
	push	bx
	lds	si,[gfbdrvr]
	assume	ds:nothing
devwr1:
	mov	al,10
	mov	ah,80h			; 80h for character device
	xor	dx,dx
	call	devchk
	mov	bx,cx
	mov	cx,0			; none written this time if error here
	jc	devwr2			; shouldn't be any errors here, but goto write
	mov	cx,bx
	test	ah,02h
	jz	devwr2			; busy bit clear if not busy
	mov	word ptr [tcbpoll],offset mo2:nullpoll9  ;%%%%
	mov	word ptr [tcbpoll+2],cs
	and	[tcbwait],not 06h	; clear bits 2,1
	or	[tcbwait],01h		; set bit 0
	callmos1 suspend		;** call in mos segment
	jmp	devwr1
devwr2:
	mov	al,16			; output until busy if possible
	test	byte ptr ds:[si+5],20h
	jnz	devwr3			; (output until busy supported)
	mov	al,8			; else simple output of 1 char
devwr3:
	mov	ah,80h or dosx or wrx
	call	devio
	jnc	devwry
devwrx:
	and	ax,7fh
	stc
devwry:
	pop	bx
	pop	dx
	pop	si
	pop	ds
	ret
devwrite endp

	subttl devio - device i/o
	page
;======================================================================
;,fs
; devio - device i/o
;
; in:	ds:si -> device driver
;	es:di -> xfr buffer
;	cx = number of bytes i/o
;	ah = as defined for int 24h
;	al = command
;
; out:	c if error
;  	 ax = error code
;  	 cx number of bytes i/o
;	else
;  	 cx = number of bytes i/o
;  	 ax = undefined
;
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:tcb
lproc	devio

lstring request,28

	push	es
	push	di
	push	bx
	mov	bx,ax
	mov	word ptr [request+18],cx; length of i/o
	call	setbufad		;rr1  normalize if needed
	mov	word ptr [request+14],di;rr1
	mov	word ptr [request+16],ax;rr1
	mov	ax,ss
	mov	es,ax
	lea	di,request
	mov	cx,14/2
	xor	ax,ax
	rep	stosw
	add	di,20-14
	stosw
	stosw
	stosw
	mov	ax,bx
	mov	[request+2],al
	xor	al,al
	mov	[request],22
	mov	cx,3			;jrbr 3 tries
	lea	bx,[request]
	call	todriver
	mov	cx,word ptr [request+18]
	pop	bx
	pop	di
	pop	es

lundef	request,28

lendp	devio
  
	subttl devchk - device status and queries
	page
;======================================================================
;,fs
; devchk - device status and queries
;
; in:	ds:si -> device driver
;	dl = unit within block device driver if applicable, else 0
;	dh = drive number if applicable, else 0
;	al = device driver command
;	ah = 80h if character device else 00h
;
; out:	c if error, ax = error, dl undefined
;	nc if no error
;  	 ax = status word from call to device driver
;  	 dl = returned unit
;
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:tcb
lproc	devchk

lstring request,28

	push	es
	push	di
	push	cx
	push	bx
	mov	[request],13
	mov	[request+1],dl		; unit within block device
	mov	[request+2],al		; i/o command
	mov	al,dh
	mov	bx,ss
	mov	es,bx
	mov	bx,ax
	xor	ax,ax
	lea	di,[request+3]
	mov	cx,(13-3)/2
	rep	stosw
	mov	ax,bx
	lea	bx,[request]
	mov	cx,0			; no retries, no int 24h
	call	todriver
	mov	dl,[request+1]
	pop	bx
	pop	cx
	pop	di
	pop	es

lundef	request,28

lendp	devchk

	subttl mediachk - see if disk has been changed
	page
;======================================================================
;,fs
; mediachk - see if disk has been changed
;
; in:	ds -> bdb
;
; out:	c if error and int 24h failed call
;	nc if no error
;
;,fe
;======================================================================
	assume	ds:bdb,es:nothing,ss:tcb
noname	db	'NO NAME    ',0

lproc	mediachk

lword	bdbseg
lstring request,28
lword	maxclus
lbyte	drive
lbyte	unit
lbyte	media
lstring sector,<size sectorblk> 	;jrbv

	push	es
	push	ds
	push	di
	push	si
	push	dx
	push	cx
	push	bx
	mov	ds,[bdbreal]		; address of real bdb for this block device
	mov	[bdbseg],ds
	call	chklogd 		;jrbr check for logical drive change
	jmpc	mediax			;jrbr
	mov	al,[bdbid]
	mov	[drive],al
	mov	al,[bdbunit]
	mov	[unit],al
	mov	al,[bdbmdia]
	mov	[media],al
	mov	bx,ss
	mov	es,bx
media1:
	lea	di,[request]
	mov	cx,22/2
	xor	ax,ax
	rep	stosw
	mov	al,[unit]
	mov	[request+1],al		; unit within block driver
	mov	al,[media]
	mov	[request+13],al
	mov	[request+2],1		; media check command
	lds	si,[bdbdrvr]
	assume	ds:nothing
	mov	[request],15		; length of request block
	lea	bx,request
	mov	cx,3			;jrbr
	mov	al,[drive]
	mov	ah,dosx and (not ignorex)
	call	todriver
	jmpc	mediax			; a failed int 24h
	cmp	[request+14],1
	jmpe	mediax			; 1 if not changed and then we're finished
	push	ds			;jrbr
	mov	ds,[bdbseg]		;jrbr
	call	chkbdb			;jrbr see if any to flush for this bdb
	pop	ds			;jrbr
	jz	media6			;jrbr none to flush

; if any buffer needs to be flushed and the driver didn't know whether
;   or not the media had been changed, then assume not changed
; if driver said media was changed then issue an int 24h on behalf of
;   the device driver

media4:
	cmp	[request+14],0		; don't know, and some buffer must be flushed,
	jmpe	mediax			;   regard it as not changed
	mov	word ptr [tcberrvol],offset mo2:noname	; use default volume id
	mov	word ptr [tcberrvol+2],cs
	test	byte ptr [si+5],08h	; unless open/close/rm bit set?
	jz	media5
	mov	ax,word ptr [request+15]; then use the volume it returned
	mov	word ptr [tcberrvol],ax
	mov	ax,word ptr [request+17]
	mov	word ptr [tcberrvol+2],ax
media5:
	mov	di,12			; set up general error for int 24 handler
	mov	[tcberrcod],wrongdisk	; extended error code
	mov	al,[drive]
	mov	ah,dosx and (not ignorex)
	call	toint24
	jmpc	mediax			; fail specified
	jmpz	media1			; retry specified
					; else ignore specified
media6: 				;jrbr
	push	ds			;jrbr
	mov	ds,[bdbseg]		;jrbr
	call	invbdb			;jrbr invalidate all buffers for this bdb
	pop	ds			;jrbr
	jmpc	mediax			;jrbu

; mark any gfb's for the bdb as invalid (for findgfb)

	mgetscb2 ds			;jrbr
	assume	ds:grp			;jrbr
	mov	cx,[scbgfbpf]
	mov	ax,[bdbseg]
media7b:
	jcxz	media8
	mov	es,cx
	assume	es:gfb
	mov	cx,[gfbnext]
	cmp	ax,[gfbbdb]
	jne	media7b
	mov	byte ptr [gfbinvld],-1
	jmp	media7b

; tell the driver to build a new bpb for the device

media8:
	mov	ds,[bdbseg]
	assume	ds:bdb
	mov	[bdbcfree],-1		; # of free clusters no longer valid
	les	si,[bdbdrvr]
	assume	es:nothing
	test	byte ptr es:[si+5],20h	; fat-id bit
	jz	media9			;jrbv

; get a free cache entry and map it in

	call	freecache
	jmpc	mediax
	call	cmap
	jmp	media10
media9:
	lea	bx,[sector]		;jrbv
	mov	ss:[bx].seclow,1	;jrbv
	mov	ss:[bx].sechigh,0	;jrbv
	call	rddir
	jmpc	mediax

; free the one we just read, we don't want anything in the cache for
;   this bdb and the device driver just wants to see it

	push	es
	mgetscb2 es
	assume	es:grp
	mov	di,[scbccur]
	mov	es,[scbclst]
	assume	es:nothing
	call	cfree
	pop	es
media10:
	push	es
	mov	ax,ss
	mov	es,ax
	lea	di,[request]
	mov	cx,22/2
	xor	ax,ax
	rep	stosw
	pop	word ptr [request+16]	; segment address of sector buffer
	mov	[request],22		; length of command block
	mov	al,[unit]
	mov	[request+1],al		; unit within block driver
	mov	[request+2],2		; build bpb command
	mov	al,[media]
	mov	[request+13],al
	mov	[request+14],offset dbbbuf
	lds	si,[bdbdrvr]
	assume	ds:nothing
	lea	bx,[request]		; set previous media descriptor
	mov	al,[drive]
	mov	ah,dosx and (not ignorex)
	mov	cx,3			;jrbr
	call	todriver
	jc	mediax

; translate the bpb into a bdb

	mgetscb2 es
	assume	es:grp
	mov	ax,[scbbufsz]		; max allowable cluster size
	mov	[maxclus],ax

media11:
	cmp	[bdbseg],0		; at end of alias chain?
	jz	media12 		; if at end of alias chain
	mov	es,[bdbseg]		; address of bdb
	assume	es:bdb
	mov	ax,[bdbanxt]		; next bdb in alias chain for real drive
	mov	[bdbseg],ax		; next bdb
	mov	ax,[maxclus]		; maximum cluster size for setbdb
	lds	si,dword ptr [request+18]  ; address of bpb
	mov	dl,1			; tell setbdb this isn't initialization time
	callmos1 setbdb 		;** call in mos segment
	or	al,al
	jz	media11 		; if no error, next bdb
media12:
mediax:
	pop	bx
	pop	cx
	pop	dx
	pop	si
	pop	di
	pop	ds
	pop	es

lundef	bdbseg
lundef	drive
lundef	unit
lundef	media
lundef	maxclus
lundef	request,28
lundef	sector				;jrbv

lendp	mediachk

	subttl drvpoll - poll function for todriver
	page
;======================================================================
;,fs
; drvpoll - poll function for todriver
;
; determine if a task can wake up and enter todriver
;
; in:	ss -> tcb
;	ds -> grp
;	[scbdrbsy] is re-entrance control flag for todriver
;
; out:	al == 0 if can awake, al == 1 if still need to suspend
;
;,fe
;======================================================================
	assume	ds:grp,es:nothing,ss:tcb 
drvpoll proc near
	mov	al,1			; preset return status for al
	cmp	[scbdrbsy],0		; if block cleared
	jne	dvp1 
	xor	al,al			; setup for wakeup
	jmp	short dvp2
dvp1:
	cmp	[tcbbdbwf],0		; flag already set?
	jne	dvp2
	mov	ax,ss			; get tcb into es for timchk
	mov	es,ax
	mov	ax,[tcbdbwax]		; check for time out
	mov	cx,[tcbdbwcx]
	callmos1 timchk
	mov	al,1
	jnz	dvp2			; jmp if not timed out yet
	mov	[tcbbdbwf],1		; set flag for exit_bdbgate
dvp2:
	retf
drvpoll endp

	subttl todriver - pass a request block to a device driver
	page
;======================================================================
;,fs
; todriver - pass a request block to a device driver
;
; pass a request block to a device driver
; optionally call int 24h on error
;
; in:	es:bx -> request block
;	ds:si -> device driver
;	cx = retry count (0 for no int 24h)
;	ax = as appropriate for int 24h on error
; 	 al = drive number (0=a)
;	 ah =
;	  bit 7	  = 0 if block device
;		    1 if character device
;	  bit 5	  = 0 ignore not allowed
;		    1 ignore allowed
;	  bit 4	  = 0 retry not allowed
;		    1 retry allowed
;	  bit 3	  = 0 fail not allowed
;		    1 fail allowed
;	  bits 2-1 = 0 msdos area
;		    1 fat area
;		    2 dir area
;		    3 data area
;	  bit 0	  = 1 writing
;
; out:	nc - no error
;  	 ax = status word
;	c - error
;  	 ax = error code
;
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:tcb
lproc todriver

lword retries
lword axfor24h
ldword reqptr
ldword drvptr
ldword strat
ldword inter
lstring request, <size readwrite_rq>
lword bytesent
lbyte ischardev

	cmp	[tcbno24],0
	je	tdr000
	xor	cx,cx
tdr000:
	cld
	push	di
	mov	[bytesent],0		; init carry over tally for bytes sent
	mov	[retries],cx
	mov	[axfor24h],ax
	mov	[ischardev],0		; setup for block device
	test	word ptr [si+4],8000h	; if high bit set in header attribute
	jz	tdr010 
	mov	[ischardev],1		; flag as character device
	jmp	tdr040
tdr010:					; else its a block device
	push	ds
	mgetscb2 ds
	assume	ds:grp

; must first check to see if another task is already within the todriver
; layer.  if it is, we must suspend until this original thread gets
; done in the todriver layer.

	cmp	[scbi15tsl],'Y' 
	ljne	tdr030
	cmp	[scbdrbsy],0
	lje	tdr020 

; save cache context  (ds -> grp)

	push	cx
	push	si
	push	di
	push	es
	push	[scbccur]
	push	[scbcnxt]
	sub	sp,16
	mov	di,sp
	mov	si,offset scbcsave
	mov	cx,ss			; need es -> stack
	mov	es,cx
	mov	cx,16/2
	rep	movsw

; give up processor until can be the only on in todriver

	mov	[tcbbdbwf],0		; zero the wait flag
	mov	ax,ss			; get tcb for timparm
	mov	es,ax
	assume	es:nothing
	mov	cl,01000000b		; bit position in tcbwtflg for wrap flag
	mov	ax,3
	callmos1 timparm 		; setup time out data
	mov	[tcbdbwax],ax
	mov	[tcbdbwcx],cx
	mov	word ptr [tcbpoll],offset mo2:drvpoll
	mov	word ptr [tcbpoll+2],cs
	and	[tcbwait],not 6		; clear b1 and b2
	or	[tcbwait],1		; set b0
	callmos1 suspend2		; call in mos segment
	mov	[tcbbdbwf],0		; zero the wait flag

; restore cache context

	mov	cx,ds			; need es -> grp
	mov	es,cx
	assume	ds:nothing,es:grp
	mov	cx,sp
	push	ds
	mov	si,cx
	mov	di,offset scbcsave
	mov	cx,ss
	mov	ds,cx
	mov	cx,16/2
	rep	movsw
	pop	ds
	add	sp,16
	pop	[scbcnxt]
	pop	di
	mov	es,[scbclst]
	assume	es:nothing
	call	cmap			; setting [scbcele] & [scbccur] also

; ax and es now destroyed by cmap

	pop	es
	assume	ds:grp,es:nothing
	pop	di
	pop	si
	pop	cx
tdr020:
	inc	[scbdrbsy]		; mark this entry
	mov	[scbdrtcb],ss		; leave record for toint24
tdr030:
	pop	ds
	assume	ds:nothing
tdr040:
	mov	word ptr [reqptr],bx
	mov	word ptr [reqptr+2],es
	mov	word ptr [drvptr],si
	mov	word ptr [drvptr+2],ds
	mov	ax,[si+6]
	mov	word ptr [strat],ax
	mov	word ptr [strat+2],ds
	mov	ax,[si+8]
	mov	word ptr [inter],ax
	mov	word ptr [inter+2],ds
	mov	di,ss
	mov	es,di
	lea	di,[request]
	lds	si,[reqptr]
	mov	cl,[si]
	xor	ch,ch			; save copy of user's request header
	shr	cx,1			; for restoration if need to retry
	rep	movsw
	jnc	tdr050 
	movsb
tdr050:
	mov	cx,[retries]
tdr060:
	les	bx,[reqptr]
	push	[tcbstkp]
	mov	[tcbstkp],sp
	sub	[tcbstkp],96
	mov	[tcbdnum],-1		; initialize device number
	call	[strat]
	call	[inter]			; character device sets device number
	pop	[tcbstkp]

; if no error, calc complete return count.  
; if es:bx+18 is not the ret count then will be adding 0 - big deal

	mov	ax,es:[bx+3]		; get return status word
	test	ah,80h			; if no error
	jnz	tdr070 
	les	bx,[reqptr]
	push	ax			; save the driver status
	mov	ax,[bytesent]
	add	es:[bx+18],ax		; calc ret count
	pop	ax			; retrieve the driver status
	jmp 	tdr190
tdr070:
	and	ax,7fh
	cmp	cx,0			; just return error if no retries
	lje	tdr180
	lds	si,[drvptr]

; if other than drive not ready, or a character device, 
; dec the retry count and retry if not counted out

	cmp	al,2 
	jne	tdr080
	cmp	[ischardev],1 
	jne	tdr090 
tdr080: 
	dec	cx
	cmp	cx,0			; retry 
	ljne	tdr130 
tdr090:
	mov	di,ax
	and	di,7fh			; did all retries - invoke int 24h
	mov	ax,di
	add	al,19
	mov	[tcberrcod],al		; extended error = driver error + 19
	cmp	di,12 
	jbe	tdr100 
	mov	di,12
	cmp	al,wrongdisk 
	jne	tdr100
	mov	ax,word ptr [request+22]
	mov	word ptr [tcberrvol],ax
	mov	ax,word ptr [request+24]
	mov	word ptr [tcberrvol+2],ax
tdr100:
	mov	ax,[axfor24h]
	test	ah,flshflg 
	jz	tdr110 
	call	flush24
	jmp	short tdr120
tdr110:
	call	toint24
tdr120:
	jc	tdr190			; if fail chosen
	mov	cx,[retries]
	jz	tdr130			; if ignore chosen
	mov	ax,es:[bx+3]
	and	ax,not 807fh
	jmp 	tdr190
tdr130:

; setup for a retry

	push	cx
	mov	ax,ss
	mov	ds,ax
	cmp	[ischardev],1		; if a char device
	jne	tdr140 
	lea	si,[request]		; mod the header copy first
	mov	cx,[si+18]		; get the attempted send count
	mov	ax,es:[bx+18]		; get the actual returned count
	sub	cx,ax			; calc remainder
	mov	[si+18],cx		; update send count
	add	[si+14],ax		; update data pointer
	add	[bytesent],ax		; tally total bytes sent for final
	jmp 	tdr160			; return count
tdr140:					; a block device
	cmp	cx,[retries] 
	jne	tdr160 

; flow here if user chose retry (else <= [retries]-1)
; if block device read, write, verify, return retry
; event to higher levels

	mov	al,es:[bx+2]
	cmp	al,4 
	je	tdr150 
	cmp	al,8 
	je	tdr150 
	cmp	al,9 
	jne	tdr160 
tdr150:
	pop	cx
	mov	ax,retry24h
	jmp 	tdr180
tdr160:
	lea	si,[request]
	mov	di,bx			; restore the user's header from the saved copy
	mov	cl,[si]			; and try again
	xor	ch,ch
	shr	cx,1
	rep	movsw
	jnc	tdr170 
	movsb
tdr170:
	pop	cx
	jmp 	tdr060
tdr180:
	stc
tdr190:
	les	bx,[reqptr]
	lds	si,[drvptr]
	mov	cx,[retries]
	pop	di
	pushf				; must preserve the carry state
	cmp	[ischardev],0		; if a block device
	jne	tdr230 
	push	ds
	mgetscb2 ds
	assume	ds:grp
	cmp	[scbi15tsl],'Y' 
	jne	tdr220
	dec	[scbdrbsy]		; open the gate
	jnz	tdr220
	mov	bx,[scbtcbpf]		; if at base level
tdr200:					; for each tcb, check tcbbdbbsy
	or	bx,bx
	jz	tdr220
	mov	es,bx
	assume	es:tcb,ss:nothing
	cmp	[tcbbdbwf],0		; if find a task which has been
	je	tdr210			; waiting at the bdb gate too
	assume	es:nothing,ss:tcb	; long, short-change the current
	mov	[tcbslcnt],0		; task's slice to give others
	jmp	short tdr220		; a chance.
tdr210:
	assume	es:tcb,ss:nothing
	mov	bx,[tcbtcbpn]
	jmp	short tdr200
tdr220:
	pop	ds
	assume	ds:nothing
tdr230:
	popf				; get cy/nc return status back

lundef retries
lundef axfor24h
lundef reqptr
lundef drvptr
lundef strat
lundef inter
lundef request,28
lundef bytesent
lundef ischardev

lendp	todriver



	subttl t24poll - poll routine for todriver's int24 logic
	page
;======================================================================
;,fs
; t24poll - poll routine for todriver's int24 logic
;
; determine if a task can proceed out of toint24
; if the bdb gate was originally closed, and is closed upon return 
; from the int24, must suspend until its clear.
; if the todriver gate was originally closed, and is closed 
; upon return from the int24, must suspend until its clear.
;
; in:	ss -> tcb
;	ds -> grp
;
; out:	al == 0 if can awake, al == 1 if still need to suspend
;
;,fe
;======================================================================
	assume	ds:grp,es:nothing,ss:tcb 
t24poll proc far
	xor	al,al			; preset for wakeup
	cmp	[tcbbbsy],0 
	je	t24pl29 
	cmp	[scbbdbbsy],0 
	je	t24pl29 
	mov	al,1			; sleep on
	jmp	short t24pl30
t24pl29:
	cmp	[tcbdbsy],0 
	je	t24pl30 
	cmp	[scbdrbsy],0 
	je	t24pl30 
	mov	al,1			; sleep on
t24pl30:
	ret
t24poll endp

	subttl toint24 - set up for doing an int 24h
	page
;======================================================================
;,fs
; toint24 - set up for doing an int 24h
;
; restore user stack before int 24h
; restore mos stack after int 24h
; if abort chosen - jumps to terminate with process code 0200h
;
; in:	ax, si, di, bx significant to int 24h routine
;	cx, dx, bp, ds, es, ss, sp significant to retry handling
;
; out:	c if fail chosen ax = fail24h
;	else nz if ignore chosen ax = 0
;	else retry
;
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:tcb
toint24 proc near
	push	si
	push	bx			; use to store di when restore stack
	push	es			; buffer segment
	push	ds
	push	bp			; entire int 21 frame
	push	dx			; dh = buffer offset, dl = misc
	push	cx			; number of sectors
	mov	[tcb24nest],1

; must save and reset the flags which control the todriver and bdb
; levels of the int15 task switching logic.  if the action at the
; end of toint24 is other than abort, these vars will be restored.

	mgetscb2 es
	assume	es:grp
	cmp	[scbi15tsl],'Y' 
	jne	t24p31 
	push	ax

; if scbbdbbsy is set and its due to the current task ([scbbsytcb] == ss)
; then record [scbbdbbsy] and zero it to let other tasks use the
; bdb gate while the int24 prompt is up.  
; otherwise, [tcbbbsy] will be 0.

	mov	[tcbbbsy],0
	cmp	[scbbdbbsy],0
	je	t24p01
	mov	ax,ss
	cmp	ax,[scbbsytcb]
	jne	t24p01
	mov	al,[scbbdbbsy]
	mov	[tcbbbsy],al
	mov	[scbbdbbsy],0
t24p01:

; if scbdrbsy is set and its due to the current task ([scbdrtcb] == ss)
; then record [scbdrbsy] and zero it to let other tasks use the
; todriver gate while the int24 prompt is up.  
; otherwise, [tcbdbsy] will be 0.

	mov	[tcbdbsy],0
	cmp	[scbdrbsy],0
	je	t24p02
	mov	ax,ss
	cmp	ax,[scbdrtcb]
	jne	t24p02
	mov	al,[scbdrbsy]
	mov	[tcbdbsy],al
	mov	[scbdrbsy],0
t24p02:
	pop	ax
t24p31:
	push	ax			; save valid responses

; Check the device number sent in from the standard device driver.
; If said device number indicates a parallel printer, then set a flag
; that will inform the command processor that the error has to do
; with a parallel printer.

	cmp	[tcbdnum], 1
	jb	t24p33
	cmp	[tcbdnum], 3
	ja	t24p33
	pushset	ax,bx,cx,di,es		; save regs for call to type printer
	xor	bx,bx
	mov	bl,[tcbdnum]
	dec	bx			; get to lpt number 0-2
	callmos1 Determine_route        ; Is LPT routed somewhere else?
	mov	[tcbdnum],bl		; and bx = ultimate printer
	popset	ax,bx,cx,di,es
	mov	[tcbcrit24],0		; flag not a critical error
	jmp 	t24p35
t24p33:
	mov	[tcbcrit24],1

; save cache context

	push	[scbccur]
	push	[scbcnxt]
	sub	sp,16
	mov	cx,sp
	pushset	es,ds,di,si
	mov	di,cx
	mov	si,offset scbcsave
	mov	cx,es
	mov	ds,cx
	mov	cx,ss
	mov	es,cx
	mov	cx,16/2
	rep	movsw
	popset	es,ds,di,si
t24p35:
	push	word ptr [scbinmos]
	mov	[scbinmos],0
	mov	cl,[scbnoswt]		; save no switch nesting count
	mov	ch,[tcbnest]		; save nest counter for int 23 logic
	push	cx
	mov	dx,ss
	mov	cx,sp			; now state needed for retry is saved
	pushset	ax,cx,dx,si,di,es,ds
	mov	es,[tcbpsp]
	mov	ax,es:[18h]		; read and save first two psp handle table
	mov	[tcbhdl24],ax		; entries
	mov	word ptr es:[18h],0101h	; insure no redirection
	mov	ax,[tcbsav24]
	mov	es,ax
	cmp	ax,0 
	jne	t24p36 
	mov	dx,stksiz
	add	dx,15
	shr	dx,1
	shr	dx,1
	shr	dx,1
	shr	dx,1			; calc number of paragraphs, adding 1 for
	inc	dx			; the control block
	xor	ah,ah
	callmos1 mosheman		; allocate heap block for the stack

ifdef bugerror
	cmp	al,0
	je	t24p37
	callmos1 bugerror		; call in mos segment
	db	'80 '
	db	'error allocating heap in toint24          ',00h  ;@@xlat
t24p37:
endif

	mov	[tcbsav24],es
t24p36:

; stack is saved in heap since handler does not necessarily return
; but the handler may use int 21.  therefore create another stack
; for handler (if it returns, revert to old).  else just continue
; with newly created stack.

	mov	di,10h
	mov	si,ss
	mov	ds,si
	mov	si,offset tcbminstk
	cld
	mov	cx,stksiz
	shr	cx,1			; copy mos's stack to the heap
	cli
	rep	movsw
	sti
	popset	ax,cx,dx,si,di,es,ds
	push	ds			; segment address of device driver
	push	di			; error code
	push	ax			; error misc
	mov	ax,es
	mov	ds,ax
	assume	ds:grp
	mov	bp,[tcbtpfrm]
	les	di,[tstack]		; move user reg's to user stack
	std
	sub	di,2
	mov	ax,[tflag]		; ip, cs, flags from int 21h
	stosw
	mov	ax,[tcs]
	stosw
	mov	ax,[tip]
	stosw
	mov	ax,[tes]		; all the registers as defined by int 24h doc
	stosw
	mov	ax,[tds]
	stosw
	mov	ax,[tbp]
	stosw
	mov	ax,[tdi]
	stosw
	mov	ax,[tsi]
	stosw
	mov	ax,[tdx]
	stosw
	mov	ax,[tcx]
	stosw
	mov	ax,[tbx]
	stosw
	mov	ax,[tax]
	stosw
	pop	ax			; error category to new stack
	stosw
	pop	ax			; error code to new stack
	stosw
	cld
	pop	bp			; segment address for device driver
	add	di,2			; pointing back to top of stack
	mov	ax,es
	cli
	mov	[tcbnest],0		; if don't return, nest counter is OK
	inc	byte ptr [scbcrit]	; sah increment tsr int 24 flag
	mov	ss,ax			; set stack to user stack
	mov	sp,di
	mov	[scbnoswt],0		; switches ok from here on
	sti
	pop	di			; pop error code
	pop	ax			; pop error category
	int	24h			; Call error-handler.
	dec	byte ptr [scbcrit]
	cli				; restore mos stack
	mov	ss,dx
	mov	sp,cx
	sti
	mov	es,[tcbpsp]		; restore the first two handles
	mov	cx,[tcbhdl24]
	mov	word ptr es:[18h],cx
	mov	[tcbhdl24],ax		; use as temp storage for ax
	mov	dx,ds
	mov	ds,[tcbsav24]
	assume	ds:nothing
	mov	si,10h
	mov	bx,di
	mov	di,ss
	mov	es,di
	mov	di,offset tcbminstk
	cld
	mov	cx,stksiz
	shr	cx,1			; restore mos's stack from the heap
	cli
	rep	movsw
	sti
	mov	di,ds
	mov	es,di
	mov	di,bx
	mov	ah,1
	mov	word ptr [tcbsav24],0	; reset the pointer
	callmos1 mosheman		; free the heap block

ifdef bugerror
	cmp	al,0
	je	t24p41
	callmos1 bugerror		; call in mos segment
	db '80 '
	db 'error freeing heap in toint24               ',00h  ;@@xlat
t24p41:
endif

; while out in the int24 handler, the scbbdbbsy or scbdrbsy flags
; might have gotten set.  if the corresponding flag was set
; upon original entry to toint24, must suspend until its clear

	mov	ds,dx
	assume	ds:grp
	cmp	[scbi15tsl],'Y' 
	jne	t24p42 
	xor	cx,cx
	cmp	[tcbbbsy],0 
	je	t24p43 
	cmp	[scbbdbbsy],0 
	je	t24p43 
	mov	cx,1
	jmp	short t24p44
t24p43:
	cmp	[tcbdbsy],0 
	je	t24p44 
	cmp	[scbdrbsy],0 
	je	t24p44 
	mov	cx,1
t24p44:
	cmp	cx,0 
	je	t24p42
	mov	word ptr [tcbpoll],offset mo2:t24poll
	mov	word ptr [tcbpoll+2],cs
	and	[tcbwait],not 6		; clear b1 and b2
	or	[tcbwait],1		; set b0
	callmos1 suspend		; call in mos segment
t24p42:
	pop	cx
	cli
	mov	[scbnoswt],cl		; no switches now
	mov	[tcbnest],ch		; restore nest counter for int 23 logic
	pop	word ptr [scbinmos]
	cmp	[tcbcrit24],0 
	je	t24p46 
	sti

; restore cache context

	mov	cx,ds
	mov	es,cx			; need es -> grp
	mov	cx,sp
	pushset	ds,di,si
	mov	si,cx
	mov	di,offset scbcsave
	mov	cx,ss
	mov	ds,cx
	mov	cx,16/2
	rep	movsw
	popset	ds,di,si
	add	sp,16
	pop	[scbcnxt]
	pop	di
	mov	es,[scbclst]
	assume	es:nothing
	call	cmap			; setting [scbcele] & [scbccur] also

; ax and es now destroyed by cmap

t24p46:
	mov	ax,[tcbhdl24]		; recover ax from temp storage
	pop	cx
	mov	ah,ch

; at this point, al = 0 for ignore, 1 for retry, 2 for abort, 3 for fail

	cmp	al,0			; if ignore and ignore is allowed
	jne	t24p47 
	test	ah,20h 
	jz	t24p47 
	mov	ax,0			; (else fail)
	jmp	short t24p48
t24p47:
	cmp	al,1			; if retry and retry is allowed
	jne	t24p49 
	test	ah,10h 
	jz	t24p49 
	cmp	ax,ax			; (else fail)
	jmp	short t24p48
t24p49:
	cmp	al,2			; if need to fail and allowed
	je	t24p50 
	test	ah,8 
	jz	t24p50 
	mov	ax,err24h		; (else abort)
	stc
	jmp	short t24p48
t24p50:

; when get here, need to abort because al was 2 or needed to
; fail and fail wasn't allowed.

	test	ah,flshflg		; abort not allowed during flushing
	jz	t24p48a
	xor	ax,ax			; cy and ax == 0 signal abort
	stc
	jmp	t24p48
t24p48a:
	call	nest_chk
	mov	ax,02ffh		; (al = maximum error level)
	assume	ss:nothing
	push	[mo1seg]
	lea	bx,mos:terminate
	push	bx
	retf
t24p48:
	assume	ss:tcb
	pushf				; flags important at this point
	mgetscb2 ds
	assume	ds:grp
	cmp	[scbi15tsl],'Y' 
	jne	t24p51 
	cmp	[tcbdbsy],0		; if original flag != 0, restore
	je	t24p52 
	mov	cl,[tcbdbsy]
	mov	[scbdrbsy],cl
	mov	[scbdrtcb],ss
t24p52:
	cmp	[tcbbbsy],0		; if original flag != 0, restore
	je	t24p51
	mov	cl,[tcbbbsy]
	mov	[scbbdbbsy],cl
	mov	[scbbsytcb],ss
t24p51:
	call	nest_chk
	popf				; restore flags
	pop	cx
	pop	dx
	pop	bp			; recover registers for retry state
	pop	ds
	assume	ds:nothing
	pop	es
	assume	es:nothing
	pop	bx
	pop	si
	ret
toint24 endp

	subttl nest_chk - manage response to int24 reentry attempt
	page
;======================================================================
;,fs
; nest_chk - manage response to int24 reentry attempt
;
; if an attempt is made for an int24 reentry, the tcb24nest flag will
; be set to 2 (within flush24).  when toint24 is exited, if this has
; occurred, set tcbflush == 'Y' to cause a flush to be done so the 
; offending operation is retried.  such a reentry attempt should only
; be possible due to a flush call in the first place. 
;  
; in:	ss -> tcb
;
; out:	all regs preserved
;
;,fe
;=====================================================================
	assume	ds:nothing,es:nothing,ss:tcb
nest_chk proc near
	cmp	[tcb24nest],2		; reentry attempt?
	jne	t24p48b
	push	ax
	push	bx
	push	cx
	push	dx
	push	si
	push	es
	mov	ax,ss
	mov	es,ax
	mov	[tcbflush],'Y'
	mov	al,[tcbpri]		; total maximum priority while still
	or	al,0f0h			;   being able to restore prior pri
	callmos1 reordlst
	pop	es
	pop	si
	pop	dx
	pop	cx
	pop	bx
	pop	ax
t24p48b:
	mov	[tcb24nest],0
	ret
nest_chk endp

	subttl blkread - read sectors from block device
	page
;======================================================================
;,fs
; blkread - read sectors from block device
;
; in:	ds = gfb
;	es:di -> buffer to read into
;	cx = number of bytes to read
;	dx = absolute cluster number of read start
;	ax = file-relative cluster num of read start
;	bx = sector ofs within cluster of read start
;	si = byte offset within sector of read start
;
; out:	c if error
;  	 ax = error code
;	else
;  	 dx = absolute cluster last read
;  	 ax = relative cluster last read
;  	 cx = number of bytes read
;
;,fe
;======================================================================
	assume	ds:gfb,es:nothing,ss:tcb
lproc	blkread

lword	rclust				; relative cluster of start of read
lword	aclust				; absolute cluster of start of read
lword	numleft 			; number left to read
lword	numread 			; number requested to read
ldword	buffer				; buffer for read
lstring secbuf,<size sectorblk> 	; sector number buffer

	push	es
	push	ds
	push	di
	push	si
	push	bx
	mov	[rclust],ax
	mov	[aclust],dx
	mov	[numleft],cx
	mov	[numread],cx
	call	setbufad		;rr1  normalize if needed
	mov	word ptr [buffer],di	;rr1
	mov	word ptr [buffer+2],ax	;rr1
	mov	ds,[gfbbdb]
	assume	ds:bdb
	xor	ax,ax
	mov	di,bx			; di = sector offset within cluster
	mov	bx,dx
	cmp	bx,[bdbcnum]
	jmpnc	blkrdx			; fat inconsistent with file size or invalid
	sub	bx,2
	jmpc	blkrdx			; invalid cluster number
	mov	cl,[bdbcshl]
	xor	ch,ch
	mov	[secbuf].sechigh,0
	jcxz	blkrd20
blkrd10:
	shl	bx,1
	rcl	[secbuf].sechigh,1
	loop	blkrd10
blkrd20:
	add	bx,[bdbclus]
	adc	[secbuf].sechigh,cx	; cx will be 0
	add	bx,di			; secbuf = absolute sector to start read
	adc	[secbuf].sechigh,cx
	mov	[secbuf].seclow,bx

; first read up to first sector boundary

	or	si,si
	jmpz	blkrdb			; read already on a sector boundary if e
	lea	bx,[secbuf]		; point bx to sector buffer
	call	rddata
	jmpc	blkrdx
	assume	es:dbb
	mov	cx,[bdbssiz]
	sub	cx,si
	cmp	cx,[numleft]
	jbe	blkrda
	mov	cx,[numleft]
blkrda:
	sub	[numleft],cx
	lea	si,[dbbbuf+si]
	push	ds
	mov	ax,es
	mov	ds,ax
	assume	ds:dbb
	les	di,[buffer]
	assume	es:nothing
	fastmove
	mov	cx,[numleft]		;rr1
	call	setbufad		;rr1  normalize if needed
	mov	word ptr [buffer],di	;rr1
	mov	word ptr [buffer+2],ax	;rr1
	pop	ds
	assume	ds:bdb
	xor	ax,ax
	cmp	[numleft],0
	jmpe	blkrdx			; all finished with no error
	add	[secbuf].seclow,1
	adc	[secbuf].sechigh,0	; set to read following sector
	mov	ax,[secbuf].seclow	; compute (sector offset into data area) mod
	sub	ax,[bdbclus]		;   (number of sectors / cluster)
	mov	ah,[bdbcsiz]		;   nz if next sector not on cluster boundary
	dec	ah			;     (first sector of next cluster)
	and	al,ah
	jnz	blkrdb			; still more in cluster
	call	getfat			; else find out where next cluster is
	jmpc	blkrdx
	mov	dx,ax
	mov	bx,ax			; remember next cluster #
	xor	ax,ax
	cmp	bx,[bdbcnum]
	jmpnc	blkrdx			; fat eof (fat inconsistent with file size)
	sub	bx,2
	jmpc	blkrdx
	xor	cx,cx
	mov	[secbuf].sechigh,cx
	mov	cl,[bdbcshl]
	jcxz	blkrda4
blkrda3:
	shl	bx,1
	rcl	[secbuf].sechigh,1
	loop	blkrda3
blkrda4:
	mov	ax,[bdbclus]
	add	bx,ax
	adc	[secbuf].sechigh,cx	; cx will be zero
	mov	[secbuf].seclow,bx	; store low part of number
	inc	[rclust]		; next cluster of file
	mov	[aclust],dx		; @ this cluster #

; then read all the whole sectors

blkrdb:
	mov	ax,[numleft]		; bytes remaining?
	or	ax,ax
	jmpz	blkrdx			; none
	cmp	ax,[bdbssiz]
	jmpb	blkrdg			; less than one sector
	mov	cx,word ptr [buffer]
	not	cx
	cmp	cx,ax			; make sure we don't get to 64K boundary in
	jae	blkrdc			;   buffer segment
	mov	ax,cx
blkrdc:
	mov	cx,[bdbssiz]		; ax = # of bytes to transfer
	push	dx			; divide by bytes/sector
	xor	dx,dx			; to get number of sectors
	div	cx
	or	dx,dx			; set nz flag if any remainder
	pop	dx
	mov	si,ax			; need number of entire later
	jz	blkrdc1
	inc	ax
blkrdc1:				; ax = number of sectors including partial
					; this calculation need only be 16 bits wide
	mov	di,dx			; compute start sector of next absolute cluster
	dec	di			; di = (di+1) - 2
	mov	cl,[bdbcshl]
	shl	di,cl
	add	di,[bdbclus]		; di = sector number start of next cluster
	sub	di,[secbuf].seclow	; di = sectors to next absolute cluster
blkrdd:
	cmp	di,ax			; compare # sectors to next cluster with total
	jae	blkrde			;   needed to read
	mov	cx,ax
	call	getfat			; get next cluster if we're going to need it
	jmpc	blkrdx
	xchg	cx,dx			; cx = current cluster, dx = # sectors needed
	xchg	dx,ax			; dx = next cluster,	ax = # sectors needed
	cmp	dx,[bdbcnum]
	jmpnc	blkrde			; fat inconsistent with file size
	cmp	dx,2
	jmpc	blkrde			;   or cluster number is invalid
	inc	[rclust]
	mov	[aclust],dx
	inc	cx
	cmp	cx,dx
	jne	blkrde			; ne for non-contiguous cluster
	mov	cl,[bdbcsiz]
	xor	ch,ch
	add	di,cx			; di = number of contiguous sectors so far
	jmp	blkrdd
blkrde:
	mov	cx,di			; di = sectors to first non-contiguous cluster
	cmp	cx,si			; si = entire sectors to be read
	jbe	blkrdf
	mov	cx,si
blkrdf: 				; cx = number of sectors to read
	mov	si,di			; remember number of sectors to next cluster
	les	di,[buffer]		; bx = starting sector
	push	dx
	lea	bx,[secbuf]		; sector to read
	mov	dl,datax		; data area read
	mov	ah,1			; signal buffers should be flushed
	call	rdbf
	pop	dx
	jmpc	blkrdx
	add	[secbuf].seclow,cx	; next sector to read
	adc	[secbuf].sechigh,0
	sub	si,cx			; number of sectors now to next cluster
	mov	ax,cx
	mov	cx,[bdbssiz]
	push	dx
	mul	cx
	pop	dx
	sub	[numleft],ax		; ax = number of bytes read
	add	ax,di
	mov	di,ax			; compute normalized buffer pointer past
	mov	cx,[numleft]		;rr1
	call	setbufad		;rr1  normalize if needed
	mov	word ptr [buffer],di	;rr1
	mov	word ptr [buffer+2],ax	;rr1
	or	si,si
	jmpnz	blkrdb			; nz only if didn't read all of cluster
	xor	ax,ax			; else need to find sector start of next
	mov	bx,dx			;   cluster
	cmp	bx,[bdbcnum]
	jmpnc	blkrdx
	sub	bx,2
	jmpc	blkrdx
	xor	cx,cx
	mov	[secbuf].sechigh,cx	; zero high word of sector number
	mov	cl,[bdbcshl]
	jcxz	blkrdf2
blkrdf1:
	shl	bx,1
	rcl	[secbuf].sechigh,1	;jrbz
	loop	blkrdf1
blkrdf2:
	add	bx,[bdbclus]
	adc	[secbuf].sechigh,cx	; cx zero again
	mov	[secbuf].seclow,bx	; store sector low word
	jmp	blkrdb

; then read whatever is leftover in last sector
; secbuf = # of next sector to read

blkrdg:
	lea	bx,[secbuf]
	call	rddata
	jmpc	blkrdx
	assume	es:dbb
	push	ds
	mov	cx,es
	mov	ds,cx
	assume	ds:dbb
	mov	cx,[numleft]
	les	di,[buffer]
	lea	si,[dbbbuf]
	fastmove
	mov	[numleft],0
	pop	ds
	assume	ds:bdb
	xor	ax,ax
blkrdx:
	mov	cx,[numread]
	sub	cx,[numleft]
	or	ax,ax
	stc
	jnz	blkrdy
	clc
	mov	ax,[rclust]
	mov	dx,[aclust]
blkrdy:
	pop	bx
	pop	si
	pop	di
	pop	ds
	pop	es

lundef	rclust				; relative cluster of start of read
lundef	aclust				; absolute cluster of start of read

lundef	numleft 			; number left to read
lundef	numread 			; number requested to read
lundef	buffer				; buffer for read
lundef	secbuf

lendp	blkread

setbufad proc	near			;rr1
	mov	ax,es			;rr1 normalize buffer pointer
	add	cx,di			;rr1   but only if necessary
	jnc	sba01			;rr1
	mov	ax,di			;rr1
	mov	cl,4			;rr1
	shr	ax,cl			;rr1
	mov	cx,es			;rr1
	add	ax,cx			;rr1
	and	di,0fh			;rr1
sba01:					;rr1
	ret				;rr1
setbufad endp				;rr1

	subttl blkwrite - write to block device
	page
;======================================================================
;,fs
; blkwrite - write to block device
;
; in:	ds = gfb
;	es:di -> data to write
;	cx = number of bytes to write
;	dx = absolute cluster number of write start
;	ax = file-relative cluster num of write start
;	bx = sector ofs within cluster of write start
;	si = byte offset within sector of write start
;
; out:	c if error
;  	 ax = error code
;	else
;  	 dx = absolute cluster last written
;  	 ax = relative cluster last written
;  	 cx = number of bytes written
;
;,fe
;======================================================================
	assume	ds:gfb,es:nothing,ss:tcb
lproc	blkwrite

lword	rclust				; relative cluster of start of write
lword	aclust				; absolute cluster of start of write
lword	numleft 			; number left to write
lword	numwr				; number requested to write
lword	gfbseg				; gfb address
ldword	buffer				; data for write
lstring secbuf,<size sectorblk>

	push	es
	push	ds
	push	di
	push	si
	push	bx
	mov	[rclust],ax
	mov	[aclust],dx
	mov	[gfbseg],ds
	mov	[numleft],cx
	mov	[numwr],cx
	call	setbufad		;rr1  normalize if needed
	mov	word ptr [buffer],di	;rr1
	mov	word ptr [buffer+2],ax	;rr1
	mov	ds,[gfbbdb]
	assume	ds:bdb
	xor	ax,ax
	mov	di,bx			; di = sector offset within cluster
	mov	bx,dx
	cmp	bx,[bdbcnum]
	jmpnc	blkwrx			; fat inconsistent with file size or invalid
	sub	bx,2
	jmpc	blkwrx			; invalid cluster number
	xor	cx,cx
	mov	[secbuf].sechigh,cx
	mov	cl,[bdbcshl]
	jcxz	blkwr20
blkwr10:
	shl	bx,1
	rcl	[secbuf].sechigh,1
	loop	blkwr10
blkwr20:
	add	bx,[bdbclus]
	adc	[secbuf].sechigh,cx	; cx is zero
	add	bx,di			; secbuf = absolute sector to start write
	adc	[secbuf].sechigh,cx
	mov	[secbuf].seclow,bx

; first write up to first sector boundary

	or	si,si
	jmpz	blkwrb			; write already on a sector boundary if e
	lea	bx,[secbuf]		; where the sector number is
	call	rddata
	jmpc	blkwrx
	assume	es:dbb
	mov	cx,[bdbssiz]
	sub	cx,si
	cmp	cx,[numleft]
	jbe	blkwra
	mov	cx,[numleft]
blkwra:
	sub	[numleft],cx
	lea	di,[dbbbuf+si]
	push	ds
	lds	si,[buffer]
	assume	ds:nothing
	fastmove
	mov	cx,[numleft]		;rr1 normalize new buffer pointer
	add	cx,si			;rr1   but only if necessary
	jnc	blkwra0 		;rr1
	mov	ax,si			;rr1
	mov	cl,4			;rr1
	shr	ax,cl			;rr1
	mov	cx,ds			;rr1
	add	ax,cx			;rr1
	and	si,0fh			;rr1
	mov	word ptr [buffer+2],ax	;rr1
blkwra0:				;rr1
	mov	word ptr [buffer],si	;rr1
	pop	ds
	assume	ds:bdb
	call	wrsector
	jmpc	blkwrx
	xor	ax,ax
	cmp	[numleft],0
	jmpe	blkwrx			; all finished with no error
	add	[secbuf].seclow,1	; set to write following sector
	adc	[secbuf].sechigh,0
	mov	ax,[secbuf].seclow	; compute (sector offset into data area)
	sub	ax,[bdbclus]		;   mod (number of sectors / cluster)
	mov	ah,[bdbcsiz]		;   nz if next sector not on cluster boundary
	dec	ah			;     (first sector of next cluster)
	and	al,ah
	jnz	blkwrb			; still more in cluster
	call	getfat			; else find out where next cluster is
	jmpc	blkwrx
	mov	dx,ax
	mov	bx,ax
	xor	ax,ax
	cmp	bx,[bdbcnum]
	jmpnc	blkwrx			; fat eof (fat inconsistent with file size)
	sub	bx,2
	jmpc	blkwrx
	xor	cx,cx
	mov	[secbuf].sechigh,cx	; 0:cluster to start with
	mov	cl,[bdbcshl]
	jcxz	blkwra2
blkwra1:
	shl	bx,1
	rcl	[secbuf].sechigh,1
	loop	blkwra1
blkwra2:
	add	bx,[bdbclus]		; bx = sector address of next cluster
	adc	[secbuf].sechigh,cx
	mov	[secbuf].seclow,bx
	inc	[rclust]		; next cluster within file
	mov	[aclust],dx		; dx = cluster # of next cluster

; then write all the whole sectors

blkwrb:
	mov	ax,[numleft]		; bytes remaining?
	or	ax,ax
	jmpz	blkwrx			; none
	cmp	ax,[bdbssiz]
	jmpb	blkwrg			; less than one sector
	mov	cx,word ptr [buffer]
	not	cx
	cmp	cx,ax			; make sure we don't get to 64K boundary in
	ja	blkwrc			;   buffer segment
	mov	ax,cx
blkwrc:
	mov	cx,[bdbssiz]		; ax = # of bytes to transfer
	push	dx			; divide by bytes/sector
	xor	dx,dx			; to get number of sectors
	div	cx
	or	dx,dx			; set nz flag if any remainder
	pop	dx
	mov	si,ax			; need number of entire later
	jz	blkwrc1
	inc	ax
blkwrc1:				; ax = number of sectors including partial
					; this need only be a 16 bit calculation
	mov	di,dx			; compute start sector of next absolute cluster
	dec	di			; di = (di+1) - 2
	mov	cl,[bdbcshl]
	shl	di,cl
	add	di,[bdbclus]
	sub	di,[secbuf].seclow	; di = sectors to next absolute cluster
blkwrd:
	cmp	di,ax			; compare # sectors to next cluster with total
	jae	blkwre			;   which will have to be read
	mov	cx,ax			; remember # which will have to be read
	call	getfat
	jmpc	blkwrx
	xchg	cx,dx			; cx = last cluster, dx = # sectors to read
	xchg	dx,ax			; dx = next cluster, ax = # sectors to read
	cmp	dx,[bdbcnum]
	jmpnc	blkwre			; fat inconsistent with file size
	cmp	dx,2
	jmpc	blkwre			;   or cluster number is invalid
	inc	[rclust]
	mov	[aclust],dx
	inc	cx
	cmp	cx,dx
	jne	blkwre			; ne for non-contiguous cluster
	mov	cl,[bdbcsiz]
	xor	ch,ch
	add	di,cx			; total contiguous sectors so far
	jmp	blkwrd
blkwre:
	mov	cx,di			; di = total contiguous sectors
	cmp	cx,si			; si = total entire sectors to be read
	jbe	blkwrf
	mov	cx,si
blkwrf: 				; cx = number of sectors to read
	mov	si,di			; remember # to next cluster
	les	di,[buffer]		; bx = starting sector
	xor	al,al
	cmp	[tcbvflg],0
	je	blkwrf1
	inc	al
blkwrf1:
	push	dx
	mov	dl,datax
	lea	bx,[secbuf]		; sector number
	mov	ah,1			; indicate buffers should be invalidated
	call	wrbf
	pop	dx
	jmpc	blkwrx
	add	[secbuf].seclow,cx
	adc	[secbuf].sechigh,0	; next sector to read
	sub	si,cx			; number to next cluster now
	mov	ax,cx
	mov	cx,[bdbssiz]
	push	dx
	mul	cx
	pop	dx
	sub	[numleft],ax		; new number left
	add	ax,di			; new buffer offset
	mov	di,ax			; and normalize it
	mov	cx,[numleft]		;rr1
	call	setbufad		;rr1  normalize if needed
	mov	word ptr [buffer],di	;rr1
	mov	word ptr [buffer+2],ax	;rr1
	or	si,si
	jmpnz	blkwrb			; nz if more of cluster to read
	xor	ax,ax			; else compute sector # of next cluster
	mov	bx,dx
	cmp	bx,[bdbcnum]
	jmpnc	blkwrx
	sub	bx,2
	jmpc	blkwrx
	xor	cx,cx
	mov	[secbuf].sechigh,cx
	mov	cl,[bdbcshl]
	jcxz	blkwrf3
blkwrf2:
	shl	bx,1
	rcl	[secbuf].sechigh,1
	loop	blkwrf2
blkwrf3:
	add	bx,[bdbclus]
	adc	[secbuf].sechigh,cx
	mov	[secbuf].seclow,bx
	jmp	blkwrb
;-----------------------------------------------------------------------
; then write whatever is leftover in last sector
;-----------------------------------------------------------------------
blkwrg:
	lea	bx,[secbuf]
	call	rddata
	jmpc	blkwrx
	assume	es:dbb
	mov	cx,[numleft]
	lea	di,[dbbbuf]
	push	ds
	lds	si,[buffer]
	fastmove
	pop	ds
	mov	[numleft],0
	assume	ds:bdb
	call	wrsector
	jmpc	blkwrx
	xor	ax,ax
blkwrx:
	mov	ds,[gfbseg]
	assume	ds:gfb
	push	ax
	call	timestamp
	pop	ax
	mov	[gfbtime],cx		; set the date and time
	mov	[gfbdate],dx
	mov	cx,[numwr]
	sub	cx,[numleft]
	or	ax,ax
	stc
	jnz	blkwry
	clc
	mov	ax,[rclust]
	mov	dx,[aclust]
blkwry:
	pop	bx
	pop	si
	pop	di
	pop	ds
	pop	es

lundef	rclust				; relative cluster of start of write
lundef	aclust				; absolute cluster of start of write
lundef	numleft 			; number left to write
lundef	numwr				; number requested to write
lundef	gfbseg				; gfb address
lundef	buffer				; data for write
lundef	secbuf

lendp	blkwrite

	subttl div32 - 32 bit division
	page
;======================================================================
;,fs
; div32 - 32 bit division
;
; does 32 bit division to produce a 32 bit quotient with a
; 16 bit remainder.
;
; in:	dx:ax = the dividend
;	cx = the divisor
;
; out:	dx:ax = the quotient
;	cx = the remainder
;
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:nothing
div32 proc near
	push	bx
	mov	bx,ax
	mov	ax,dx
	xor	dx,dx
	div	cx			; get the high word of the result
	xchg	bx,ax
	div	cx			; get the low word
	mov	cx,dx			; remainder in cx
	mov	dx,bx			; high word of result in dx
	pop	bx
	ret
div32 endp

	subttl getclust - get cluster corresponding to file position
	page
;======================================================================
;,fs
; getclust - get cluster corresponding to file position
;
; compute cluster corresponding to current position in file
; extending file allocation as needed
;
; in:	ds = gfb address
;	dx:ax = byte offset into file of current position
;
; out:	c if error
;  	 ax = error code
;  	 bx, dx, si = undefined
;	else nc and
;  	 dx = absolute cluster number of read start
;  	 ax = file-relative cluster num of read start
;  	 bx = sector ofs within cluster of read start
;  	 si = byte offset within sector of read start
;
;,fe
;======================================================================
	assume	ds:gfb,es:tfb
getclust proc near
	push	ds
	push	bp
	push	cx
	mov	ds,[gfbbdb]
	assume	ds:bdb
	mov	cx,[bdbssiz]
	call	div32
	mov	si,cx			; remainder -> si
	mov	bl,[bdbcsiz]
	xor	bh,bh
	dec	bx
	and	bx,ax			; sector offset within cluster
	mov	cl,[bdbcshl]
	xor	ch,ch
	jcxz	getcl1b
getcl1a:
	shr	dx,1
	rcr	ax,1
	loop	getcl1a
getcl1b:
	mov	bp,ax			; bp = relative cluster number for read
;-----------------------------------------------------------------------
; determine absolute cluster number of relative cluster
;-----------------------------------------------------------------------
	mov	ds,[tfbgfb]
	assume	ds:gfb
	mov	dx,[gfbcbof]		; dx = absolute number of bof cluster
	mov	cx,bp			; cx = number of clusters from desired cluster
	cmp	[tfbrccur],0		; can't use if not set yet
	je	getcl2
	cmp	bp,[tfbrccur]		; relative number of current cluster
	jb	getcl2
	mov	dx,[tfbclus]		; dx = absolute number of current cluster
	sub	cx,[tfbrccur]		; cx = number of clusters from desired cluster
	cmp	bp,[gfbrcmax]		; max relative number encountered so far
	jb	getcl2
	mov	dx,[gfbcmax]		; absolute number of max rel cluster so far
	mov	cx,bp
	sub	cx,[gfbrcmax]
getcl2:
;-----------------------------------------------------------------------
; traverse fat cx entries starting from dx to arrive at relative
;   cluster bp
; dx = absolute number of cluster to start looking from
; cx = number of clusters to look
; bx = relative cluster arrived at
;-----------------------------------------------------------------------
	mov	ds,[gfbbdb]
	assume	ds:bdb
	jcxz	getcl4
getcl3:
	call	getfat
	jmpc	getclx
	mov	dx,ax
	loop	getcl3
getcl4:
	mov	ax,bp
	clc
getclx:
	pop	cx
	pop	bp
	pop	ds
	ret
getclust endp

	subttl encrypt - encrypt buffered information
	page
;======================================================================
;,fs
; encrypt - encrypt buffered information
;
; in:	ds:si -> buffer
;	cx = length of buffer
;
; out:
;
;,fe
;======================================================================
	assume	ds:nothing,es:tfb,ss:tcb
encrypt proc near
	jcxz	encx
	push	es
	push	di
	push	dx
	push	cx
	push	bx
	push	ax
	mov	ax,word ptr [tfbpos]
	mov	dx,word ptr [tfbpos+2]
	mov	bx,ax
	mov	di,dx
	and	al,not 7fh
	mov	es,[tfbgfb]
	assume	es:gfb
enc1:
	add	ax,word ptr [gfbkey]
	adc	dx,word ptr [gfbkey+2]
	call	random
	mov	ax,cx
	mov	cx,bx
	or	cx,not (128-1)
	neg	cx			; length to next 128 byte boundary
	sub	ax,cx
	jae	enc2
	add	cx,ax			; not 128 bytes left
	xor	ax,ax
enc2:
	add	dl,bl
	add	bx,cx
	adc	di,0
enc3:
	xor	[si],dh
	add	[si],dl
	inc	dl
	inc	si
	loop	enc3
	or	ax,ax
	mov	cx,ax
	mov	ax,bx
	mov	dx,di
	jnz	enc1			; z if none left to encrypt
	pop	ax
	pop	bx
	pop	cx
	pop	dx
	pop	di
	pop	es
encx:
	ret
encrypt endp

	subttl decrypt - decrypt buffered information
	page
;======================================================================
;,fs
; decrypt - decrypt buffered information
;
; in:	ds:si -> buffer
;	cx = length of buffer
;
; out:
;
;,fe
;======================================================================
	assume	ds:nothing,es:tfb,ss:tcb
decrypt proc near
	jcxz	decx
	push	es
	push	di
	push	dx
	push	cx
	push	bx
	push	ax
	mov	ax,word ptr [tfbpos]
	mov	dx,word ptr [tfbpos+2]
	mov	bx,ax
	mov	di,dx
	and	al,not 7fh
	mov	es,[tfbgfb]
	assume	es:gfb
dec1:
	add	ax,word ptr [gfbkey]
	adc	dx,word ptr [gfbkey+2]
	call	random
	mov	ax,cx
	mov	cx,bx
	or	cx,not (128-1)
	neg	cx			; length to next 128 byte boundary
	sub	ax,cx
	jae	dec2
	add	cx,ax			; less than 128 bytes left
	xor	ax,ax
dec2:
	add	dl,bl
	add	bx,cx
	adc	di,0
dec3:
	sub	[si],dl
	xor	[si],dh
	inc	dl
	inc	si
	loop	dec3
	or	ax,ax
	mov	cx,ax
	mov	ax,bx
	mov	dx,di
	jnz	dec1			; z if none left to decrypt
	pop	ax
	pop	bx
	pop	cx
	pop	dx
	pop	di
	pop	es
decx:
	ret
decrypt endp

	subttl random - calculate a random number
	page
;======================================================================
;,fs
; random - calculate a random number 
;
; knuth vol 2 page 170
; dx:ax = seed x
; return x := ( a * x + c ) mod m
; m = 2 ** 32
; c = 1
; a = some value such that a mod 8 = 5 and bits look irregular
;   1010 1001 1100 0010 1011 0110 1110 0101 = a9c2b6e5
;
; in:	ds:si -> buffer
;	cx = length of buffer
;
; out:
;
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:nothing
random proc near
	push	di
	push	bx
	mov	bx,ax			; bit 0
	mov	di,dx
	shl	ax,1			; bit 1
	rcl	dx,1
	shl	ax,1			; bit 2
	rcl	dx,1
	add	bx,ax
	adc	di,dx
	shl	ax,1			; bit 3
	rcl	dx,1
	shl	ax,1			; bit 4
	rcl	dx,1
	shl	ax,1			; bit 5
	rcl	dx,1
	add	bx,ax
	adc	di,dx
	shl	ax,1			; bit 6
	rcl	dx,1
	add	bx,ax
	adc	di,dx
	shl	ax,1			; bit 7
	rcl	dx,1
	add	bx,ax
	adc	di,dx
	shl	ax,1			; bit 8
	rcl	dx,1
	shl	ax,1			; bit 9
	rcl	dx,1
	add	bx,ax
	adc	di,dx
	shl	ax,1			; bit 10
	rcl	dx,1
	add	bx,ax
	adc	di,dx
	shl	ax,1			; bit 11
	rcl	dx,1
	shl	ax,1			; bit 12
	rcl	dx,1
	add	bx,ax
	adc	di,dx
	shl	ax,1			; bit 13
	rcl	dx,1
	add	bx,ax
	adc	di,dx
	shl	ax,1			; bit 14
	rcl	dx,1
	shl	ax,1			; bit 15
	rcl	dx,1
	add	bx,ax
	adc	di,dx
	shl	ax,1			; bit 16
	mov	ax,bx
	rcl	dx,1
	shl	dx,1			; bit 17
	add	di,dx
	shl	dx,1			; bit 18
	shl	dx,1			; bit 19
	shl	dx,1			; bit 20
	shl	dx,1			; bit 21
	shl	dx,1			; bit 22
	add	di,dx
	shl	dx,1			; bit 23
	add	di,dx
	shl	dx,1			; bit 24
	add	di,dx
	shl	dx,1			; bit 25
	shl	dx,1			; bit 26
	shl	dx,1			; bit 27
	add	di,dx
	shl	dx,1			; bit 28
	shl	dx,1			; bit 29
	add	di,dx
	shl	dx,1			; bit 30
	shl	dx,1			; bit 31
	add	dx,di
	pop	bx
	pop	di
	add	ax,0b6e5h		; + a
	adc	dx,0a9c2h
	ret
random endp

ddt	ends
	end


