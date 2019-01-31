
; '!!' markings surround cownid changes

; '##' markings surround changes for bdbsctr/csector/sechigh/seclow

; '$$' markings surround changes for bdbfsiz


	include page.inc
	title	mosfutl3 - mosfun39 utility subroutines - mostly cacheing
comment ^===============================================================
		      development specification

 program name:	$$mos.com		 assigned to: jim bean
 module name:	mosfutil		 assign date: 01/30/86
 entry points:	mosfun39-mosfun5c	 completed: 09/03/86
 entry from:	mosint39, mosfun0f
 entry method:	call
 calls:		device drivers
 purpose:	file handle functions
 last update:	08/18/1992
========================================================================

to help isolate bugs (try each of the following in the following
order):

 0.  in cvmove, xor 0800h with dx after loading from tcbvidw2
     before calling mapvma (so the piece doesn't get mapped over
     physical screen and you can't see your debug display)
 1.  patch out coalesce
 2.  set [scbcnxt] to [bdbclpf] every time chkcnxt is called
 3.  set fdirect to always return c
 4.  no postponed writes
 5.  no cacheing
 6.  no mm

critical errors
  reads reported as they occur
      if read error, then uob isn't in cache and it still isn't
	  we don't invalidate anything, because mediachk will
	  do that if needed at the times it recognizes as
	  appropriate for invalidation
      all this is the same as used to be done for buffers
  write-through writes
      if write error, then we want to allow the user to correct
	  the situation so we don't invalidate anything,
	  mediachk will, again, deal with things as and when it
	  deems appropriate
  all this is the same as used to be done for buffers
  write-postponed writes
      reported to owner @ owner's next tsl
      note that this won't be an int 24h, but something outside
	  the app's control since the app won't be expecting it
	  and	we need more control than the app might give us
      note that the error handler needs to be reentrant or we
	  have to suspend everybody which isn't satisfactory
  (see also flush24 discussion)

========================================================================

jrb 06/03/88	marty's changes to cli before invalidating scbtcbvr
		or scbtcbvs

jrb 06/03/88	use scbcseg for mapping uob's instead of scbmastv
		raise retry24h for cacheit one procedural level
		and handle cacheit int 24h ignore response correctly

mjs 7/2/88	modified coalesce (cvmove) to map into mm's scratch
		buffer instead of the video buffer.  was getting disk
		data corruption when an int8 intercept did direct video.
		added 'include macros.inc' for access to the mmparm
		struc.

sah 12/02/88	changes from useing 0:6ch to scbtimer necessary because
		of my recent changes for correcting problem with spool
		and wordperfect 5.0 (dopoll)  thanx to mjs on this one!

sah 12/03/88	also did it for motor...according to jrb

rbr 12/12/88	removed mosscbex.inc dependency.

rkg 03/03/89	ptr197 invalid divide when more than 135 megs on drive
		caused by cache suob logic.  when sects > 64k secs/buff
		divide faulted since result > 64k.  replaced remainder
		logic with extended divide and multiply.

mjs 07/10/89	found and fixed register conflict problem in cvmove.

mjs 10/02/89	modify rdsector to test for redundant action before
		calling any subordinate routines.

mjs 10/10/89	modified sector size calculations.
		modified inituob to not fill out buffers for
		non-cached drives.

sah 12/14/89	remove mosregs2.inc					  

sah 01/23/90	added calls to wordmov for faster execution on i386\i486

mjs 03/07/90	added disk busy gating logic
		NOTE: currently, this logic is not fully implemented.
		the bdb specific re-entrance feature is disabled until
		I can find one last stinker of a bug with it.

mjs 03/19/90	remove all code pertaining to bdb specific gating.
		implmeneted absolute bdb gating permanently.

mjs 03/31/90	modify flshpoll to use scblastw1/2 to keep track of the
		last task to do a disk write.  this prevents a cpu intensive
		task from being delayed by a flushed poll - it directs
		the delay to the last task to do a write.

mjs 07/23/90	modify chk_bdbgate/bdbpoll to test for a timeout.  if a
		task is waiting at the bdb gate level for more
		than a few ticks, as soon as the task that's inside
		gets done, short change its slice.
		
mjs 07/29/90	modify exit_bdbgate to preserve the flags.  this was
		causing alloclust to not be able to return an error.

SAH 10/05/90	Correction for Divide by 0 error in coalence 
JRB

BWR 11/05/90    Compatibility fix for Corel CD-WORM driver.  Device
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

SAH 01/31/91	Made sure that AL is set to 1 at  beginning of bdbpoll
		so that if poll exits, that it will make sure that poll 
		is done prematurely.  It is possiable that MOS could 
		re-enter BDB layers and disk corruption could be possiable

SAH 02/12/91	Correctios to  Flush24 so that MOS will not call tomox24
		(so that it will call applications INT 24) and allow fail
		to work correctly if MOS is not inside the flush polling
		logic.  This was done to correct  a problem with Unisys
		system.

mjs 04/22/91	remove the test of scb15act from the start of 
		chk_bdbgate.  change the test of scb15act within flushbdb 
		to a test of scbi15tsl.  this was done to prevent a
		stall when an attempt is made to create a directory on
		a write-protected diskette while a background task is
 		doing disk i/o.

mjs 04/26/91	added a test of scbi15tsl at the start of chk_bdbgate.
		this was necessary to prevent a stall of disk activity
  		in other tasks when one task incurred a critical error
		from trying to write to a write protected diskette.

mjs 05/09/91	modified flush24 to detect an attempted reentrance
		into toint24 and set tcb24nest to 2.  this will cause
		toint24 to set tcbflush upon exit.

mjs 05/10/91	modified flushbdb to not call invbdb.  this prevents
		unnecessary "critical block" errors.
		modified chklogd to call invbdb directly rather than
		manipulate bdbcach to try to make flushbdb call invbdb.

mjs 10/07/91	fix dbts/prtsc/spool bugs (patch410.118).
		change the chk_bdbgate function to call suspend2 instead
		of suspend.  this was done to prevent bdb layer
		re-entrance during a shift-prtsc when the spooler is
		loaded.  the suspend function is susceptable to a
		short-circuit return when the intsl flag is not zero.

mjs 12/16/91	dlg mods: convert method of handling the cownid field within
		the cache descriptor.  convert operations on bdbfsiz from
		byte to word.  convert operations on the csector field
		within the cache descriptor from 24 bit to 32 bit.  enlarge
		device driver request header size in the rdreal and wrreal
		functions.  convert from 24 to 32 bit sector numbers within
		device driver request headers.  converted to use of
		structures within dskstruc.inc.

mjs 12/19/91	corrected mistaken register use in dlg code within inituob.

mjs 03/03/92	modified flush24 to always call toint24, to mask off
		the flshflg bit and to set the tcbcacer flag around
		the int24 call.

================ 5.01 Kernel Ends Here ====================================

mjs 08/18/92	clean up segment declarations

=======================================================================^

.xlist
;	include mosfutl3.pub
	include group.inc
	include	macros.inc
	include	dskstruc.inc
	include mosregs.inc
	include moscdb.inc
	include mosgfb.inc
	include mostfb.inc
	include mosrlb.inc
	include mosbdb.inc

tcb	segment at 1234h
	include mostcb.inc
tcb	ends

gdata	segment
	include	mosscbex.inc
	extrn	intsl:byte
gdata	ends
.list

poll	segment
	extrn	pollstart:byte, pollend:byte

	dw	flshpoll		; subroutine for flush polling from first write
flushf	dw	0			; don't call until enabled
	dw	0			; global poll

	dw	flshpoll		; subroutine for flush polling from last write
flushl	dw	0			; don't call until enabled
	dw	0			; global poll

	dw	mtrpoll			; subroutine for setting motor on timer
motor	dw	0			; don't call until enabled
	dw	0			; global poll

poll	ends

;======================================================== mos segment
if 0 eq 0
segment_num = 1
endif
mosseg	segment
	assume	cs:mos,ds:nothing,es:nothing,ss:tcb
	extrn	sbios:word, m1retf:word, reordlst:near, suspend2:near
	extrn	timparm:near, timchk:near

	subttl flshpoll - polled flush of all writes
	page
;======================================================================
;,fs
; flshpoll - polled flush of all writes
; 
; save extended error information for current tcb
;   (so flush can crash it with impunity)
; set global polled flush flag true (used by flush24)
; call flush
; set global polled flush flag false
; restore extended error information for current tcb
; 
; in:	ss -> tcb
; 
; out:	nothing
;	no registers changed
; 
;,fe
;=====================================================================^
	assume	ds:nothing,es:nothing,ss:tcb
flshpoll proc near
	pushset	ax,ds
	mgetscb ds
	assume	ds:grp
	cmp	[scbflonce],0		; if already in here - quick exit
	jne	flp1
	mov	al,[scbdrbsy]		; if either the todriver or int13
	or	al,[scb13bsy]		; gate is blocked, doctor the
	jz	flp2			; timers and make a quick exit.
flp3:
	mov	ax,[scbtimer]		; keep flushl off and reset
	mov	[flushl],ax		; flushf to fire on the next
	inc	ax			; timer tick
	mov	[flushf],ax
     	jmp	short flp1

; at this point, its time to flush and the gates are not blocked.  must
; now see if the current task is the one which did the last write.  if
; not, reset timers for next tick.  if yes, go ahead.
; the purpose of this test is to prevent a polled flush from occuring
; during the execution of a cpu intensive task - causing an unfair delay.
; a set of staged variables are used to prevent prepetual-putoff.  with
; a single variable, this could have occured when each task was doing 
; some writing.

flp2:
	mov	ax,ss
	cmp	[scblastw2],0
	je	flp4
	cmp	[scblastw2],ax
	jne	flp3
	jmp	short flp5
flp4:
	cmp	[scblastw1],0
	je	flp5
	cmp	[scblastw1],ax
	je	flp5
	mov	ax,[scblastw1]
	mov	[scblastw2],ax
	jmp	short flp3
flp5:
	inc	[scbflonce]
	push	word ptr [tcberrvol+2]	; flush might change these for the
	push	word ptr [tcberrvol]	;   current tcb
	push	word ptr [tcberrcod]
	mov	[scbflush],'Y'		; signal polled flush
	callmos2 flush
	mov	[scbflush],'N'
	pop	ax
	mov	[tcberrcod],al
	pop	word ptr [tcberrvol]
	pop	word ptr [tcberrvol+2]
	dec	[scbflonce]
	mov	[scblastw1],0
	mov	[scblastw2],0
flp1:
	popset	ax,ds
	assume	ds:nothing
	ret
flshpoll endp

	subttl mtrpoll - keep floppy motor turned on
	page
;======================================================================
;,fs
; mtrpoll - keep floppy motor turned on
; 
; extend motor off timer timeout
; add 1 second to current time to come back
; 
; in:	ss -> tcb
; 
; out:	nothing
;	no registers changed
; 
;,fe
;====================================================================^
	assume	ds:nothing,es:nothing,ss:tcb
mtrpoll proc near
	push	es
	mgetzero es
	assume	es:nothing
	mov	byte ptr es:[0440h],0ffh; keep motor off timer on
	mgetscb es
	assume	es:grp
	add	cx,18
	or	cx,cx
	jnz	mtrpoll1
	inc	cx
mtrpoll1:
	mov	[motor],cx		; next poll for motor
	pop	es
	assume	es:nothing
	ret
mtrpoll endp

mosseg	ends

;======================================================== ddt segment
if 0 eq 0
segment_num = 2
endif
ddt	segment
	assume	cs:mo2,ds:grp,es:nothing,ss:tcb
	extrn	sbios2:word, wordmov:near
	extrn	findbdb:near
	extrn	todriver:near, devchk:near, toint24:near
        extrn   clearbit:near, setbit:near, testbit:near
        extrn   bitaddr:near, findbdbc:near
        extrn   markdirty:near, markclean:near, cmap:near, cfree:near

	public	flushdir, flushdata, wrfat, flush24
	public	rdbf, wrbf, rddir, wrsector, flush
	public	rdfat, rddata, chkbdb, flushbdb, freecache, 
	public	chklogd, invbdb, chk_bdbgate, exit_bdbgate

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
wrprot	equ	19
notrdy	equ	21
genfail equ	31
share	equ	32			; sharing violation
zlock	equ	33			; lock violation
wrongdisk equ	34			; wrong disk in drive
shareov equ	36			; share buffer overflow (couldn't alloc RLB)
errblock equ	37			; blocked on another task's critical error
filexst equ	80			; file already exists
fail24h equ	83			; fail chosen from int 24h (as defined by dos)
retry24h equ	84 or 8000h
syshdl	equ	127 or 8000h		; attempt to dup or fdup a non-psp handle
xshare	equ	share or 8000h		; fail from int 24h sharing
xlock	equ	zlock or 8000h		; fail from int 24h locking
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

endif

	assume	ds:bdb,es:nothing,ss:nothing
sct2para proc near
	mov	cx,[bdbssiz]
	shr	cx,1
	shr	cx,1
	shr	cx,1
	shr	cx,1
	push	dx
	mul	cx
	pop	dx
	ret
sct2para endp

sct2word proc near
	mov	cx,[bdbssiz]
	shr	cx,1
	push	dx
	mul	cx
	pop	dx
	ret
sct2word endp

sct2byte proc near
	mov	cx,[bdbssiz]
	push	dx
	mul	cx
	pop	dx
	ret
sct2byte endp


	subttl cownid2tcb - find tcb segment for cownid task id byte
	page
;======================================================================
;,fs
; cownid2tcb - find tcb segment for cownid task id byte
;
; in:	es:[di].cownid -> task id byte in descriptor or scbcsave
;
; out:	ax = corresponding tcb segment
;	ax = 0 if es:[di].cownid == ff
;	ax = 0 if no match can be found (should never happen)
;
;,fe
;====================================================================^
	assume	ds:nothing,es:nothing,ss:nothing
cownid2tcb proc near
	push	bx
	push	ds
	mgetscb2 ds
	assume	ds:grp
	mov	ds,[scbtcbpf]
	assume	ds:tcb
	mov	bl,es:[di].cownid
	xor	ax,ax
	cmp	bl,0ffh
	je	cow2
cow3:
	cmp	bl,byte ptr [tcbid]
	je	cow1
	mov	ax,[tcbtcbpn]
	or	ax,ax
	jz	cow2
	mov	ds,ax
	jmp	short cow3
cow1:
	mov	ax,ds
cow2:
	pop	ds
	assume	ds:nothing
	pop	bx
	ret
cownid2tcb endp


	subttl chk_bdbgate - task switch gating for disk i/o
	page
;======================================================================
;,fs
; chk_bdbgate - task switch gating for disk i/o
; 
; only allow entry to the bdb layer by one task at a time
; 
; in:	ds -> bdb
;	ss -> tcb
;
; out:	
;
;,fe
;====================================================================^
	assume	ds:bdb,es:nothing,ss:tcb
chk_bdbgate proc near
	pushset	ax,cx,ds,es
	mgetscb2 es
	assume	es:grp
	cmp	[scbi15tsl],'Y'
	jne	ckb3
	cmp	[scbbdbbsy],0		; and the gate is open
	jne	ckb1
ckb3:
	inc	[scbbdbbsy]		; close it
	mov	[scbbsytcb],ss
	jmp	short ckb2
ckb1:
	mov	ax,ss
	cmp	[scbbsytcb],ax		; else, if open by this same task
	jne	ckb0
	inc	[scbbdbbsy]		; let them through
	jmp	short ckb2
ckb0:
	mov	[tcbbdbwf],0		; zero the wait flag
	mov	ax,ss			; get tcb for timparm
	mov	es,ax
	assume	es:nothing
	mov	cl,01000000b		; bit position in tcbwtflg for wrap flag
	mov	ax,3
	callmos1 timparm 		; setup time out data
	mov	[tcbdbwax],ax
	mov	[tcbdbwcx],cx
	mov	word ptr [tcbpoll],offset mo2:bdbpoll	; else, must wait
	mov	word ptr [tcbpoll+2],cs
	and	[tcbwait],not 2		; clear b1
	or	[tcbwait],5		; set b0 and b2
	callmos1 suspend2		; call in mos segment
	mov	[tcbbdbwf],0		; zero the wait flag
ckb2:
	popset	ax,cx,ds,es
	ret
chk_bdbgate endp

	subttl bdbpoll
	page
;======================================================================
;,fs
; bdbpoll
; 
; determine if a task can wake up and enter the bdb access layer
;
; in:	ss -> tcb
;	ds -> grp
;	[tcbbdbbsy] == bdb which needs to clear up before a wakeup can happen
; 
; out:	al == 0 if can awake, al == 1 if still need to suspend
; 
;,fe
;====================================================================^
	assume	ds:grp,es:nothing,ss:tcb
bdbpoll proc far
	pushset	cx,es
	mov	al,1
	cmp	[scbbdbbsy],0
	jne	bpl2
	dec	al
	inc	[scbbdbbsy]
	mov	[scbbsytcb],ss
	jmp	short bpl3
bpl2:
	cmp	[tcbbdbwf],0		; flag already set?
	jne	bpl3
	mov	ax,ss			; get tcb into es for timchk
	mov	es,ax
	mov	ax,[tcbdbwax]		; check for time out
	mov	cx,[tcbdbwcx]
	callmos1 timchk
	mov	al,1
	jnz	bpl3			; jmp if not timed out yet
	mov	[tcbbdbwf],1		; set flag for exit_bdbgate
bpl3:
	popset	cx,es
	assume	es:nothing
	retf
bdbpoll endp

	subttl exit_bdbgate - exit from the bdb gate layer
	page
;======================================================================
;,fs
; exit_bdbgate - exit from the bdb gate layer
; 
; manage the exit from the bdb gate layer
; 
; in:	ss -> tcb
; 
; out:	
;
;,fe
;====================================================================^
	assume	ds:nothing,es:nothing,ss:tcb
exit_bdbgate proc near
	pushf
	pushset	bx,ds,es
	mgetscb2 ds
	assume	ds:grp
	dec	[scbbdbbsy]		; signal exit from this bdb layer
	jnz	etb2
	mov	bx,[scbtcbpf]		; if at base level
etb1:					; for each tcb, check tcbbdbbsy
	or	bx,bx
	jz	etb2
	mov	es,bx
	assume	es:tcb,ss:nothing
	cmp	[tcbbdbwf],0		; if find a task which has been
	je	etb3			; waiting at the bdb gate too
	assume	es:nothing,ss:tcb	; long, short-change the current
	mov	[tcbslcnt],0
	jmp	short etb2		; a chance.
etb3:
	assume	es:tcb,ss:nothing
	mov	bx,[tcbtcbpn]
	jmp	short etb1
etb2:
	popset	bx,ds,es
	popf
	ret
exit_bdbgate endp

	subttl	rdfat - read a fat sector from a block device
	page
;======================================================================
;,fs
; rdfat - read a fat sector from a block device
; 
; compute logical sector number of fat sector
; read it
; if any error, try each of the other copies in succession
; set the uob descriptor to indicate that we read the first
;   copy regardless of whether an error occurred
; this function and flushuob are the only functions which have to
;   mess with the fact that there are multiple copies of the fat
;   (actually inituob does implicitly so that these two can work
;   the way they do)
; 
; in:	bx = sector offset into fat to read
;	ds -> bdb
;	ss -> tcb
; 
; out:	c if error
;	 ax = error code
;	nc if no error
;	 es -> buffered sector
;	ax, es destroyed, all others unchanged
; 
;,fe
;====================================================================^
	assume	ds:bdb,es:nothing,ss:tcb
lproc rdfat

lstring sector,<size sectorblk>

	push	ds
	mov	ds,[bdbreal]		; on real drive
	push	dx
	push	cx
	push	bx
	xor	cx,cx
	add	bx,[bdbfat]
	adc	cx,0
	mov	ax,bx
	lea	bx,[sector]
	mov	ss:[bx].seclow,ax
	mov	ss:[bx].sechigh,cx
	mov	cl,[bdbfnum]
	xor	ch,ch

; try each fat copy until it's read

rdfat1:
	push	cx
	mov	dl,fatx
	call	rdsector
	pop	cx
	jnc	rdfat2

;$$<
;	mov	dl,[bdbfsiz]		; to next copy
;	xor	dh,dh

	mov	dx,[bdbfsiz]		; to next copy
;$$>

	add	ss:[bx].seclow,dx
	adc	ss:[bx].sechigh,0
	loop	rdfat1
	stc
	jmp	rdfatx
rdfat2:

; now that the sector is read, we need to set the uob to the first fat
; copy regardless of which fat copy it really was - we can do this
; because fat uobs are separate from everything else in the cache and
; fat copies are separate from each other so the uob break points and
; number of sectors are the same for each fat copy relative to the
; start of that fat copy

	push	es
	push	di
	mgetscb2 es
	assume	es:grp
	mov	di,[scbccur]
	mov	es,[scbclst]
	assume	es:nothing
	mov	ax,word ptr es:[di].csector
	sub	ax,[bdbfat]


;$$<
;	div	[bdbfsiz]
;	mov	al,ah
;	xor	ah,ah

;$$ ax/[bdbfsiz](byte) --> ah remainder --> ax is remainder

	push	dx
	xor	dx,dx
	div	[bdbfsiz]
	mov	ax,dx
	pop	dx
;$$>


	add	ax,[bdbfat]
	mov	word ptr es:[di].csector,ax
	pop	di
	pop	es
	clc
rdfatx:
	pop	bx
	pop	cx
	pop	dx
	pop	ds

lundef	sector

lendp	rdfat

	subttl	rddir, rddata, rdsector - read a sector from a block device
	page
;======================================================================
;,fs
; rddir - rdsector of a directory sector
;
; in:	
;
; out:	
;
;,fe
;====================================================================^
	assume	ds:bdb,es:nothing,ss:tcb
rddir proc near
	push	dx
	mov	dl,dirx
	call	rdsector
	pop	dx
	ret
rddir endp

	subttl rddata - rdsector of a data sector
	page
;======================================================================
;,fs
; rddata - rdsector of a data sector
; 
; in:	
;
; out:	
;
;,fe
;====================================================================^
	assume	ds:bdb,es:nothing,ss:tcb
rddata proc near
	push	dx
	mov	dl,datax
	call	rdsector
	pop	dx
	ret
rddata endp

	subttl rdsector - read a sector from a block device
	page
;======================================================================
;,fs
; rdsector - read a sector from a block device
; 
; see if the sector is cached
; if so, we're finished
; otherwise
;   if the motor flag for this bdb has already been set
;     call cacheit to cache the sector and return
;   otherwise
;     save the motor flag and set it to 0
;     call cacheit to cache the sector
;     analyze the motor flag to determine the motor number and bit
;     restore the motor flag
;     if the motor number and bit are 0, we assume it's not
;       a floppy, but mark the motor flag init'ed so we don't go
;       through this again for this bdb
; we deal with the motor flag here because we assume that we will
;   read a dir or fat sector as the very first thing we do on the
;   disk - so it's defined as early as it can be, and as early as
;   it needs to be
; 
; in:	ss:bx -> sectorblk containing sector to read
;	dl = dirx, fatx or datax as appropriate
;	ds -> bdb
;	ss -> tcb
; 
; out:	c if error
;	 ax = error code
;	nc if no error
;	 es -> buffered sector
;	ax, es destroyed, all others unchanged
; 
;,fe
;====================================================================^
	assume	ds:bdb,es:nothing,ss:tcb
rdsector proc near
	push	ds
	mov	ds,[bdbreal]		; on real drive
	call	chk_bdbgate		; check if ok to enter this layer
	push	cx
	mgetscb2 es
	assume	es:grp

; optimization to prevent redundant calls below this level
; when the sector we want has already been mapped in

	mov	ax,ds
	cmp	[scbclbdb],ax 
	jne	rds3 
	mov	ax,ss:[bx]
	cmp	[scbclsct],ax 
	jne	rds3
	mov	ax,ss:[bx+2]
	cmp	[scbclsct+2],ax 
	jne	rds3
	mov	es,[scbclseg]
	assume	es:nothing
	clc
	jmp 	rds6			; terminate without error
rds3:
	mgetscb2 es
	assume	es:grp
	mov	ax,[bdbclpf]
	mov	[scbcnxt],ax
	assume	es:nothing
	mov	cx,1			; 1 sector clue
	call	nxtcache		; find sector in cache
	jnc	rds8 
	cmp	[bdbdmtr],0		; if hasn't been init'ed yet
	jne	rds9 
	mgetzero2 es
	push	es:[043fh]		; save motor status
	and	byte ptr es:[043fh],not 3fh  ; set it to 0
	mov	cx,1			; 1 sector clue
	call	cacheit
	pop	cx
	push	es
	mgetzero2 es
	xchg	cl,es:[043fh]
	pop	es
	jc	rds10 
	and	cl,3fh			; clearing all but drive bits and select
	mov	[bdbdmtr],cl		; remember how motor status changed
	jnz	rds8 
	mov	[bdbdmtr],-1		; no change if we can't turn drive motor on
	jmp	short 	rds8
rds10:
	cmp	ax,retry24h 
	je	rds3 
	stc
	jmp	short 	rds8
rds9:
	mov	cx,1			; 1 sector clue
	call	cacheit
	jnc	rds8 
	cmp	ax,retry24h 
	je	rds3 
	stc
rds8:

; cleanup/termination handler

	jc	rds6			; exit if carry
	push	es
	mov	ax,es
	mgetscb2 es
	assume	es:grp
	mov	[scbclseg],ax		; save bdb segment, buffer segment
	mov	ax,ss:[bx]		; and sector number to prevent
	mov	[scbclsct],ax		; redundant calling below rdsector
	mov	ax,ss:[bx+2]		; when the sector we want is already
	mov	[scbclsct+2],ax		; buffered.
	mov	[scbclbdb],ds
	pop	es
	assume	es:nothing
	clc
rds6:

; direct exit point

	call	exit_bdbgate
	pop	cx
	pop	ds
	ret
rdsector endp

	subttl	wrfat - flag a fat sector as changed
	page
;======================================================================
;,fs
; wrfat - flag sector as changed
; 
; same as wrsector
; if something changes in the future it may be useful to know
;   specifically that this is a fat sector at offset bx into the
;   fat - doing it this way sets the standard for all the subroutines
;   that they come here, in case it matters that they all come one
;   place  (who knows, it doesn't cost much)
; wrfat is just another label for wrsector, so we don't have to pay
;   any code space
;
; in:	[scbccur] -> uob descriptor for changed sector
;	bx -> sector offset into fat
;	ds -> bdb
;	ss -> tcb
; 
; out:	c if error
;	 ax = error code
;	nc if no error
;	ax destroyed, all others unchanged
; 
;,fe
;====================================================================^
	assume	ds:bdb,es:nothing,ss:tcb

	subttl	wrsector - flag a sector as changed
	page
;======================================================================
;,fs
; wrsector - flag a sector as changed
; 
; turn the drive motor on if cacheing is on
; set first write timer if enabled and not set yet
; set last write timer if enabled
; wrsector requires that no disk i/o be done from the time the sector
;   is read - the sequence is to read the sector, make your changes
;   and then call wrsector to mark it changed - this isn't too
;   limiting really since all the code is written assuming that two
;   sectors can't be accessed at the same time and that reading one
;   invalidates the buffer address returned for an earlier (as it
;   has to be to handle the 1 buffer case)
; we don't need to check for a logical drive change because we
;   checked when we read the sector
; set the status to changed
; set the verify status true if a fat or dir sector or if the task's
;   verify flag is on
; note motoron checks to see if postponed writes are enabled before
;   turning the motor on
; currently no errors are defined because wrsector doesn't really
;   do anything physical - the callers all pay attention to the
;   returned error just in case
; 
; in:	[scbccur] -> uob descriptor for changed sector
;	ds -> bdb
;	ss -> tcb
; 
; out:	c if error
;	 ax = error code
;	nc if no error
; 
;,fe
;====================================================================^
	assume ds:bdb,es:nothing,ss:tcb
wrsector proc near
wrfat:
	push	es
	push	ds
	mov	ds,[bdbreal]		; on real drive
	call	chk_bdbgate		; check if ok to enter this layer
	push	di
	mgetscb2 es
	assume	es:grp
	cmp	[scbcach],'Y' 
	jne	wrs12 
	cmp	[bdbcach],'Y' 
	jne	wrs12 
	call	motoron			; turn  motor on if cacheing is on

; update flush poll first write timer if needed

	cmp	[scbcwrf],0 
	je	wrs13 
	cmp	[flushf],0 
	jne	wrs13 
	mov	ax,[scbtimer]		;  use scbtimer instead of 40:6ch
	add	ax,[scbcwrf]
	mov	[flushf],ax
wrs13:
	cmp	[scbcwrl],0		; update flush poll last
	je	wrs12
	mov	ax,[scbtimer]		; write timer if needed
	add	ax,[scbcwrl]
	mov	[flushl],ax
wrs12:
	mov	di,[scbccur]		; mark the sector changed
	mov	es,[scbclst]
	assume	es:nothing
	call	markdirty
	cmp	es:[di].cerror,0 
	jne	wrs15 


;!!<
;	mov	es:[di].cownid,ss

	push	ax
	mov	al,byte ptr [tcbid]
	mov	es:[di].cownid,al
	pop	ax
;!!>


	push	es
	mgetscb2 es
	assume	es:grp
	mov	[scblastw1],ss
	pop	es
	assume	es:nothing
wrs15:

; mark for verify if dir or verify is on for tcb

	test	es:[di].cstatus,dirflg or fatflg 
	jnz	wrs15a 
	cmp	[tcbvflg],0 
	je	wrs16 
wrs15a: 
	or	es:[di].cstatus,vrfflg
wrs16:
	call	exit_bdbgate
	pop	di
	pop	ds
	pop	es
	ret
wrsector endp

	subttl	rdbf - read sectors from a block device into a buffer
	page
;======================================================================
;,fs
; rdbf - read sectors from a block device into a buffer
; 
; call fromcache to determine how much of start of read is in cache
;   and transfer that portion to read buffer
; if not all in cache
;   call todisk to determine extent of physical read necessary
;     (determines how much of end of read is in the cache, the
;     remainder has to be physically read)
;   call rdcache to read it and update the cache as needed
;   if more of read remains,
;     call fromcache to get it from the cache
; basically we divide the i/o into three phases
;   1.  the leading part of the i/o which can all be found in the
;       cache
;   2.  the trailing part of the i/o which can all be found in the
;       cache
;   3.  all the rest
; the only stuff that changes for cacheing, not cacheing, write-
;   through or postponed writes is in the all the rest part (rdcache)
; 
; in:	es:di = pointer to buffer into which to read
;	ss:bx -> sectorblk with sector number of sector to read
;	cx = number of sectors to read
;	dl = area of disk being read (always datax currently)
;	ds -> bdb
;	ss -> tcb
; 
; out:	c if error
;	 ax = error code
;	nc if no error
;	 ax = undefined
;	ax is destroyed, all others unchanged
; 
;,fe
;====================================================================^
	assume	ds:bdb,es:nothing,ss:tcb
lproc rdbf

lstring sector,<size sectorblk>
lword bufptr0
lstring sector0,<size sectorblk>
lword numsct0
lword cnxt0

	push	es
	push	ds
	mov	ds,[bdbreal]		; on real drive
	call	chk_bdbgate		; check if ok to enter this layer
	push	di
	push	si
	push	cx
	push	bx
	push	es
	mgetscb2 es
	assume	es:grp
	mov	ax,[bdbclpf]		; looking through cache list
	mov	[scbcnxt],ax		;   from start for bdb
	pop	es
	mov	ax,ss:[bx].seclow
	mov	[sector.seclow],ax
	mov	ax,ss:[bx].sechigh
	mov	[sector.sechigh],ax

; from the cache until we have to start physically reading

	lea	bx,[sector]
	mov	al,0			; flag front of read
	call	fromcache
	jc	rdb17			; if no err & didn't get all frm cache
	jcxz	rdb17
	mov	[numsct0],cx		; save start of needed read
	mov	[bufptr0],di
	mov	ax,[sector.seclow]
	mov	[sector0.seclow],ax
	mov	ax,[sector.sechigh]
	mov	[sector0.sechigh],ax
	push	es
	mgetscb2 es
	assume	es:grp
	mov	ax,[scbcnxt]		; save lookup position in uob list
	mov	[cnxt0],ax
	pop	es
	call	todisk			; determine extent of physical read needed
	push	di			; do whatever read is needed
	push	cx
	push	es
	mgetscb2 es
	assume	es:grp
	mov	ax,[cnxt0]		; restore position in uob list
	mov	[scbcnxt],ax		;   for start of physical read
	pop	es
	mov	di,[bufptr0]
	lea	bx,[sector0]
	sub	cx,[numsct0]
	neg	cx
	call	rdcache
	pop	cx
	pop	di
	jc	rdb17
	jcxz	rdb17
	lea	bx,[sector]		; take the rest from the cache
	mov	al,0ffh			; signal end of read
	call	fromcache
rdb17:
	call	exit_bdbgate
	pop	bx
	pop	cx
	pop	si
	pop	di
	pop	ds
	pop	es

lundef sector
lundef bufptr0
lundef sector0
lundef numsct0
lundef cnxt0

lendp rdbf

	subttl	rdcache - the part of rdbf which isn't in the cache
	page
;======================================================================
;,fs
; rdcache - the part of rdbf which isn't in the cache
;
; call chklogd to check for logical drive change - any physical
;   i/o might prompt the user to switch disks and we need to flush
;   the old disk first
; do the entire physical read to get it over with in a big chunk
;   rdbf has theoretically made sure that we actually need to
;   physically read most of it
; divide the read into uob-sized chunks
; look for chunk in cache
; if not found
;   if not cached, skip to update vars
;    (if cache off we've read the most current copy already)
;   call getcache to get a uob for the chunk
;   copy chunk from read buffer to uob
; else found
;   copy chunk from cache to read buffer
;     cache is most current copy and it may have changed since
;       we did our read even if it's not marked changed now,
;       since getcache above might have flushed it
; update vars past chunk
; repeat for all chunks
;
; rdcache is a helper for rdbf
; note that we have to look for each chunk of the read regardless
;   of whether cacheing is enabled and regardless of write-through
;   or postponed write state - this is because it's always possible
;   for a middle piece to be in the cache and changed and that piece
;   would be the most current disk image, so the read buffer has to
;   be taken from it
; what costs the most is moving the data (obviously), looking doesn't
;   cost much - a future optimization would be not to put the data
;   in the cache if it's not already there, even when cached - though
;   we'd still have to move any data found in the cache to the read
;   buffer
; 
; in:	es:di = pointer to buffer into which to read
;	ss:bx -> sectorblk with sector number
;	cx = number of sectors to read
;	dl = area of disk being read (currently always datax)
;	ds -> bdb
;	ss -> tcb
; 
; out:	c if error
;	 ax = error code
;	nc if no error
;	 es:di past portion read
;	 ss:bx -> sectorblk with next sector to read
;	 cx = number of sectors remaining
;	ax, bx, cx, di destroyed, all others unchanged
; 
;,fe
;====================================================================^
	assume	ds:bdb,es:nothing,ss:tcb
lproc	rdcache

lbyte	cached

	push	di
	push	si
	push	dx
	push	cx
	call	chklogd			; check for logical drive change
	jmpc	rdcx

; physically read the chunk

rdc0a:
	push	cx
	call	rdreal
	pop	cx
	jnc	rdc0b
	cmp	ax,retry24h
	je	rdc0a
	stc
	jmp	rdcx
rdc0b:
	push	es
	mgetscb2 es
	assume	es:grp
	mov	[cached],'N'		; remember if cached
	cmp	[scbcach],'Y'
	pop	es
	jne	rdc1
	cmp	[bdbcach],'Y'
	jne	rdc1
	mov	[cached],'Y'
rdc1:
	push	es
	push	di
	push	cx
	call	nxtcache		; get next chunk from cache
	mov	ax,cx
	pop	cx
	jnc	rdc1b

; if it's not in the cache we only worry about it if cacheing's on

	cmp	[cached],'Y'
        jne	rdc1a1
        call	testbit
        jnz	rdc2
rdc1a1:

; if cacheing's off we skip to the next chunk

	pop	di
	pop	es
	cmp	ax,cx
	jbe	rdc1a
	mov	ax,cx
rdc1a:
	mov	si,ax
	push	cx
	call	sct2byte
	xchg	si,ax
	pop	cx
	jmp	rdc5
rdc1b:

; if it is in the cache, we have to transfer it from the cache even
; if we already read it because it might be changed in the cache
; (even if it's not marked changed, it might have been flushed by
; getcache after we physically read it above)

	pop	di
	pop	si
	push	si
	push	ds
	push	di
	push	cx
	cmp	ax,cx
	jbe	rdc1c
	mov	ax,cx
rdc1c:
	push	ax
	call	sct2word
	mov	cx,ax
	push	es
	pop	ds
	mov	es,si			; buffer seg
	xor	si,si
	jmp	rdc3
	assume	ds:bdb
rdc2:

; if it's not in the cache, and cacheing is enabled, then we want to
; put it in the cache - taking it from the read buffer

	call	getcache		; (cx = total needed)
	pop	si
	pop	di
	jc	rdcx			; flush error
	push	di
	push	ds
	push	si
	push	cx
	cmp	ax,cx
	jbe	rdc2a
	mov	ax,cx
rdc2a:
	push	ax
	call	sct2word
	mov	cx,ax
	mov	ds,di			; buffer seg
	assume	ds:nothing
	xor	di,di
rdc3:

; note two code lines join here - one is copying from cache to
; read buffer, one is copying from read buffer to cache

	call	wordmov			; rep movsw (but fast on 386/486)
rdc4:
	mov	si,ax
	shl	si,1
	pop	ax
	pop	cx
	pop	di
	pop	ds
	assume	ds:bdb
	pop	es
	call	coalesce		; coalesce in case getcache needs it
rdc5:

; update vars past chunk

	add	di,si
	add	ss:[bx].seclow,ax
	adc	ss:[bx].sechigh,0
	sub	cx,ax
	jmpnz	rdc1
rdcx:
	pop	cx
	pop	dx
	pop	si
	pop	di

lundef	cached

lendp	rdcache

	subttl	fromcache - get leading/trailing piece of read from cache
	page
;======================================================================
;,fs
; fromcache - get leading/trailing piece of read from cache
; 
; call nxtcache to get the next chunk of sectors from the cache
; if not found
;   if we're getting the trailing piece we have to read it here
;      (nobody else is going to do it)
;   else
;     if there are fewer sectors to read than a uob,
;       we read it here to save rdcache the trouble
;     else if our sector would be in the middle of the uob,
;       we read it here so rdcache starts reading on a uob boundary
;     else we return cause we're finished
;     call cacheit to cache it
; move it to the read buffer
; repeat until all chunks checked
;
; fromcache is a helper for rdbf
; 
; in:	al = 0 for leading piece
;	   != 0 for trailing piece
;	es:di = pointer to buffer into which to read
;	ss:bx -> sectorblk with sector number of sector to read
;	cx = number of sectors to read
;	dl = area of disk being read (always datax currently)
;	ds -> bdb
;	ss -> tcb
; 
; out:	c if error
;	 ax = error code
;	nc if no error
;	 es:di past portion read
;	 ss:bx -> sectorblk with next sector to read
;	 cx = number of sectors remaining
;	ax, bx, cx, di are destroyed, all others unchanged
; 
;,fe
;====================================================================^
	assume	ds:bdb,es:nothing,ss:tcb
lproc	fromcache

lword	bufseg
lword	numsct
lbyte	endflag

	push	si
	mov	[numsct],cx
	mov	[bufseg],es
	mov	[endflag],al
fromc0:					;jrbw
	call	nxtcache
	jnc	fromc2

; start chunk of piece isn't in the cache

	cmp	[endflag],0
	jne	fromc1			; ne if reading trailing piece
	cmp	cx,[numsct]
	jae	fromc1			; reading less than remainder in uob
	cmp	cx,ax			; e if starting on uob boundary &
	je	fromcx			;   reading at least a full uob
fromc1:
	mov	cx,[numsct]
	call	cacheit			; read it
	jnc	fromc2			;jrbw
	mov	cx,[numsct]		;jrbw
	cmp	ax,retry24h		;jrbw
	je	fromc0			;jrbw
	stc				;jrbw
	jmp	fromcx			;jrbw
fromc2:
	cmp	cx,[numsct]
	jbe	fromc3
	mov	cx,[numsct]
fromc3:

; update our variables past chunk and move cached sectors to read buffer

	sub	[numsct],cx
	add	ss:[bx].seclow,cx
	adc	ss:[bx].sechigh,0
	mov	ax,cx
	call	sct2word
	mov	cx,ax
	push	ds
	assume	ds:nothing
	mov	ax,es
	mov	ds,ax
	mov	es,[bufseg]
	xor	si,si
	call	wordmov			; rep movsw (but fast on 386/486)
	pop	ds
	assume	ds:bdb
	cmp	[numsct],0
	je	fromcx			; no more to check
	mov	cx,[numsct]
	call	nxtcache
	jnc	fromc2			; nc if found in cache

; this chunk not in cache

	cmp	[endflag],0
	jne	fromc1			; in trailing piece of read we have to read it
	cmp	cx,[numsct]
	jae	fromc1			; ae if more in uob than remainder we need
	clc				; note nc
fromcx:
	mov	cx,[numsct]		; remaining sectors to read
	mov	es,[bufseg]
	pop	si

lundef	bufseg
lundef	numsct
lundef	endflag

lendp	fromcache

	subttl	wrbf - write to a block device from a buffer
	page
;======================================================================
;,fs
; wrbf - write to a block device from a buffer
; 
; set verify bit of i/o status byte (dl) if verify is on for tcb
; turn the drive motor on if bdb is cached
; set first write timer if enabled and not set
; call tocache to determine how much of start of write is in cache
;   and transfer that portion from write buffer to cache
; if not all in cache
;   call todisk to determine extent of physical write necessary
;     (determines how much of end of write is in the cache, the
;     remainder has to be physically written)
;   call wrcache to write it and update the cache as needed
;   if more of write remains,
;     call tocache to move it to the cache
; set last write timer if enabled
;
; basically we divide the i/o into three phases
;   1.  the leading part of the i/o which can all be found in the
;       cache
;   2.  the trailing part of the i/o which can all be found in the
;       cache
;   3.  all the rest
; the only stuff that changes for cacheing, not cacheing, write-
;   through or postponed writes is in the all the rest part (wrcache)
; 
; in:	es:di = pointer to buffer from which to write
;	ss:bx -> sectorblk with sector number
;	cx = number of sectors to write
;	dl = area of disk being written (currently always datax)
;	ds -> bdb
;	ss -> tcb
; 
; out:	c if error
;	 ax = error code
;	nc if no error
;	ax is destroyed, all others unchanged
; 
;,fe
;====================================================================^
	assume	ds:bdb,es:nothing,ss:tcb
lproc	wrbf

lstring sector,<size sectorblk>
lword	bufptr0
lstring sector0,<size sectorblk>
lword	numsct0
lword	cnxt0

	cmp	[tcbvflg],0		; set verify flag if verify is
	je	wrb19 
	or	dl,vrfflg		; on for tcb
wrb19:
	or	dl,wrx
	push	es
	push	ds
	mov	ds,[bdbreal]		; on real drive
	call	chk_bdbgate		; check if ok to enter this layer
	push	di
	push	si
	push	cx
	push	bx
	push	es
	mgetscb2 es
	assume	es:grp
	mov	ax,[bdbclpf]		; start looking through uob list
	mov	[scbcnxt],ax		;   at first for this bdb
	cmp	[scbcach],'Y' 
	jne	wrb20 
	cmp	[bdbcach],'Y' 
	jne	wrb20 
	call	motoron			; turn the motor on if cached
	cmp	[scbcwrf],0		; update flush poll first write
	je	wrb20
	cmp	[flushf],0 
	jne	wrb20
	mov	ax,[scbtimer]		; timer if needed
	add	ax,[scbcwrf]
	mov	[flushf],ax
wrb20:
	pop	es
	assume	es:nothing
	mov	ax,ss:[bx].seclow
	mov	[sector.seclow],ax
	mov	ax,ss:[bx].sechigh
	mov	[sector.sechigh],ax

; to the cache until the first sector not in cache

	lea	bx,[sector]
	mov	al,0			; flag leading piece
	call	tocache
	ljc	wrb22			; write or flush error
	jcxz	wrb23			; all was in the cache
	mov	[numsct0],cx		; save start of needed write
	mov	[bufptr0],di
	mov	ax,[sector.seclow]
	mov	[sector0.seclow],ax
	mov	ax,[sector.sechigh]
	mov	[sector0.sechigh],ax
	push	es
	mgetscb2 es
	assume	es:grp
	mov	ax,[scbcnxt]		; save position in uob list
	mov	[cnxt0],ax
	pop	es
	call	todisk			; determine extent of needed write
	push	di			; do whatever write is needed
	push	cx
	push	es
	mgetscb2 es
	assume	es:grp
	mov	ax,[cnxt0]		; restore uob list position to
	mov	[scbcnxt],ax		;   saved start of write
	pop	es
	mov	di,[bufptr0]
	lea	bx,[sector0]
	sub	cx,[numsct0]
	neg	cx
	call	wrcache
	pop	cx
	pop	di
	jc	wrb22			; write error
	jcxz	wrb23			; if more to do
	lea	bx,[sector]		; to the cache until the end
	mov	al,0ffh			; flag trailing piece
	call	tocache
	jc	wrb22 
wrb23:
	push	es			; update flush poll last write
	mgetscb2 es			; timer if needed
	assume	es:grp
	cmp	[scbcach],'Y' 
	jne	wrb25 
	cmp	[bdbcach],'Y' 
	jne	wrb25 
	cmp	[scbcwrl],0 
	je	wrb25
	mov	ax,[scbtimer]
	add	ax,[scbcwrl]
	mov	[flushl],ax
wrb25:
	pop	es
	assume	es:nothing
	clc
wrb22:
	call	exit_bdbgate
	pop	bx
	pop	cx
	pop	si
	pop	di
	pop	ds
	pop	es

lundef	sector
lundef	bufptr0
lundef	sector0
lundef	numsct0
lundef	cnxt0

lendp	wrbf

	subttl	wrcache - the part of wrbf which isn't in the cache
	page
;======================================================================
;,fs
; wrcache - the part of wrbf which isn't in the cache
; 
; call chklogd to check for logical drive change - any physical
;   i/o might prompt the user to switch disks and we need to flush
;   the old disk first
; if write-through then do the entire physical write
;   (write-through if cacheing is off or first and last timers
;   are disabled)
; divide the write into uob-sized chunks
; look for chunk in cache
; if not found
;   if write-through, skip to update vars
;     (if off we don't need to update anything in the cache for
;     this chunk and we've already written it)
;   call getcache to get a uob for chunk
; copy chunk from write buffer to uob
;   have to update uob since write buffer is now most current
; update vars past chunk
; repeat for all chunks
;
; wrcache is a helper for wrbf
; note that we have to look for each chunk of the write regardless
;   of whether cacheing is enabled and regardless of write-through
;   or postponed write state - this is because it's always possible
;   for a middle piece to be in the cache and this write buffer is
;   now the most current disk image, so the cache image has to be
;   updated
; what costs the most is moving the data (obviously), looking doesn't
;   cost much - a future optimization might be to throw it away if
;   it's found in the cache - NOTE this requires that wrcache
;   continue to start at a uob boundary and that it continue through
;   whole uob's, otherwise if the found uob is changed and is not
;   spanned by the write buffer, it has to be updated from the
;   write buffer and can't be thrown away
; 
; in:	es:di = pointer to buffer from which to write
;	ss:bx -> sectorblk with sector number
;	cx = number of sectors to write
;	dl = area of disk being written (currently always datax)
;	ds -> bdb
;	ss -> tcb
; 
; out:	c if error
;	 ax = error code
;	nc if no error
;	 es:di past portion written
;	 ss:bx -> sectorblk with next sector to write
;	 cx = number of sectors remaining
;	ax, bx, cx, di destroyed, all others unchanged
; 
;,fe
;====================================================================^
	assume	ds:bdb,es:nothing,ss:tcb
lproc	wrcache

lbyte	cached

	push	es
	push	di
	push	si
	push	dx
	push	cx
	call	chklogd			; check for logical drive change
	jmpc	wrcx
	push	es
	mgetscb2 es
	assume	es:grp
	mov	[cached],'N'		; remember whether or not cached
        test	dl,allx
        jz	wrc1			; physical write if abs write (int 26h)
	cmp	[scbcach],'Y'
	jne	wrc1
	cmp	[bdbcach],'Y'
	jne	wrc1
	mov	[cached],'Y'		; is cached
	cmp	[scbcwrf],0
	jne	wrc2
	cmp	[scbcwrl],0
	jne	wrc2
wrc1:
	pop	es
	assume	es:nothing

; physical write if write-through

wrc1a:
	mov	al,0
	test	dl,vrfflg
	jz	wrc1b
	mov	al,1			; flag verify on write
wrc1b:
	and	dl,not (wrx or vrfflg)	; we don't want to mark it
	push	cx
	call	wrreal			;   changed in the cache when we put
	pop	cx
	jnc	wrc3			;   it there below
	cmp	ax,retry24h
	je	wrc1a
	stc
	jmp	wrcx
wrc2:
	pop	es
wrc3:
	push	es
	push	di
	push	cx
	call	nxtcache		; find next chunk
	mov	ax,cx
	pop	cx
	jnc	wrc5

; if it's not in the cache, we only need to worry about it if
;   cached, and then only if this is the 2nd time we've requested it

	cmp	[cached],'Y'
        jne	wrc3a4
        call	testbit
        jnz	wrc4

; even if we decide not to cache it, we still have to write it

        pop	di
        pop	es
        push	cx
        push	ax
        mov	cx,ax
wrc3a1:
	mov	al,0
	test	dl,vrfflg
	jz	wrc3a2
	mov	al,1			; flag verify on write
wrc3a2:
        call	wrreal
        jnc	wrc3a3
        cmp	ax,retry24h
        je	wrc3a1
        pop	cx
        pop	cx
        stc
        jmp	wrcx
wrc3a3:
        pop	ax
        pop	cx
        push	es
        push	di
wrc3a4:

; if not cached and not in the cache, we just update vars past the
;   chunk and continue

	pop	si
	pop	es
	cmp	ax,cx
	jbe	wrc3a
	mov	ax,cx
wrc3a:
	mov	di,ax
	push	cx

	call	sct2byte
;mjs@	mov	cl,[bdbsshl]
;mjs@	shl	ax,cl

	pop	cx
	add	si,ax
	mov	ax,di
	jmp	wrc6
wrc4:

; else for postponed write, we get a uob to copy the write to

	call	getcache		; (cx = total needed)
wrc5:
	pop	si
	pop	di
	jc	wrcx			; flush error
	cmp	ax,cx
	jbe	wrc5a
	mov	ax,cx
wrc5a:

; copy write to uob

	push	ds
	push	cx
	push	ax
	call	sct2word
	mov	cx,ax
	mov	ds,di			; buffer seg
	xor	di,di
	call	wordmov			; rep movsw (but fast on 386/486)
	mov	di,ds
	mov	es,di
	pop	ax
	pop	cx
	pop	ds
	call	coalesce		; coalesce for getcache if needed
wrc6:

; update the vars past this chunk

	add	ss:[bx].seclow,ax
	adc	ss:[bx].sechigh,0
	mov	di,si
	sub	cx,ax
	jz	wrcx
        jmp	wrc3
wrcx:
	pop	cx
	pop	dx
	pop	si
	pop	di
	pop	es

lundef	cached

lendp	wrcache

	subttl	tocache - copy leading/trailing piece of write to cache
	page
;======================================================================
;,fs
; tocache - copy leading/trailing piece of write to cache
; 
; call nxtcache to get the next chunk of sectors from the cache
; if not found
;   if we're getting the trailing piece we have to write it here
;     (nobody else is going to do it)
;   else
;     if there are fewer sectors to write than a uob,
;       we read it here to save wrcache the trouble
;     else if our sector would be in the middle of the uob,
;       we write it here so wrcache starts writing on a uob boundary
;     else we return cause we're finished
;     call cacheit to cache it
; move it from the write buffer
; repeat until all chunks checked
;
; to cache is a helper for wrbf
; 
; in:	al = 0 for leading piece
;	   != 0 for trailing piece
;	es:di = pointer to buffer from which to write
;	ss:bx -> sectorblk with sector number of sector to write
;	cx = number of sectors to write
;	dl = area of disk being written (always datax currently)
;	ds -> bdb
;	ss -> tcb
; 
; out:	c if error
;	 ax = error code
;	nc if no error
;	 es:di past portion written
;	 ss:bx -> sectorblk with next sector to write
;	 cx = number of sectors remaining
;	ax, bx, cx, di are destroyed, all others unchanged
; 
;,fe
;====================================================================^
	assume	ds:bdb,es:nothing,ss:tcb
lproc	tocache

lword	bufseg
lword	numsct
lbyte	endflag

	push	si
	mov	[numsct],cx
	mov	[bufseg],es
	mov	[endflag],al
toc0:					;jrbw
	call	nxtcache
	jnc	toc2

; start chunk of write isn't in the cache

	cmp	[endflag],0
	jne	toc1			; ne if trailing piece and have to write it
	cmp	cx,[numsct]
	jae	toc1			; writing less than remainder in uob
	cmp	cx,ax			; e if starting on uob boundary &
	je	tocx			;   writing at least a full uob
toc1:
	mov	cx,[numsct]
	call	cacheit			; get it into the cache
	jnc	toc2			;jrbw
	mov	cx,[numsct]		;jrbw
	cmp	ax,retry24h		;jrbw
	je	toc0			;jrbw
	stc				;jrbw
	jmp	tocx			;jrbw
toc2:
	cmp	cx,[numsct]
	jbe	toc3
	mov	cx,[numsct]
toc3:
	sub	[numsct],cx

; update our variables and move it to the cache

	add	ss:[bx].seclow,cx
	adc	ss:[bx].sechigh,0
	mov	ax,cx
	call	sct2word
	mov	cx,ax
	push	ds
	mov	ds,[bufseg]
	mov	si,di
	xor	di,di
	call	wordmov			; rep movsw (but fast on 386/486)
	mov	di,si
	pop	ds
        test	dl,allx
        jnz	toc4

; flush new uob if absolute write (int 26h)

        push	es
        push	di
        mgetscb2 es
        assume  es:grp
        mov	di,[scbccur]
        mov	es,[scbclst]
        assume  es:nothing
        call	flushuob
        pop	di
        pop	es
toc4:
	cmp	[numsct],0
	je	tocx			; all done
	mov	cx,[numsct]
	call	nxtcache
	jnc	toc2

; this chunk is not in cache

	cmp	[endflag],0
	jne	toc1			; have to write in trailing piece
	cmp	cx,[numsct]
	jae	toc1			; ae if more in uob than remainder we need
	clc				; note nc
tocx:
	mov	cx,[numsct]
	mov	es,[bufseg]
	pop	si

lundef	bufseg
lundef	numsct
lundef	endflag

lendp	tocache

	subttl	todisk - determine extent of physical disk i/o needed
	page
;======================================================================
;,fs
; todisk - determine extent of physical disk i/o needed
; 
; call chkcnxt to find the next chunk in the cache
;   if not found, remember it
;     at the end, the last one remembered will precede the first
;       one not to require physical i/o
; update vars past this chunk
; repeat until no more needed in i/o
; set vars to the uob following the last one remembered
;   (set to the first one which doesn't require physical i/o)
;
; todisk is a helper for rdbf & wrbf
; 
; in:	es:di = pointer to buffer position
;	ss:bx -> sectorblk with sector number of sector position
;	cx = number of sectors remaining in i/o
;	ds -> bdb
; 
; out:	es:di past portion which needs physical i/o
;	ss:bx -> sectorblk with next sector past physical i/o
;	cx = number of sectors remaining after physical i/o
;	ax, bx, cx, di are destroyed, all others unchanged
; 
;,fe
;====================================================================^
	assume	ds:bdb,es:nothing,ss:tcb
lproc	todisk

lword	numsct
lword	bufptrx
lword	numsctx
lstring sectorx,<size sectorblk>
lword	numuobx

	push	es
	mov	[numsct],cx
tod1:
	mov	cx,[numsct]
	push	di
	call	chkcnxt			; look for it
	pop	di
	jnc	tod2			; found in cache
	cmp	cx,[numsct]		; if a, count it found since uob > remaining
	ja	tod2a			;    (2nd fromcache/tocache will do it)

; not found in cache, remember it for determining last found
;    ( last found will = next following last not found )

	mov	[numuobx],cx
	mov	ax,[numsct]
	mov	[numsctx],ax
	mov	ax,ss:[bx].seclow
	mov	[sectorx.seclow],ax
	mov	ax,ss:[bx].sechigh
	mov	[sectorx.sechigh],ax
	mov	[bufptrx],di

; logically here if found or not found (tod2a saves a redundant cmp)

tod2:
	cmp	cx,[numsct]
	jbe	tod3
tod2a:
	mov	cx,[numsct]
tod3:

; update vars past this chunk

	sub	[numsct],cx
	add	ss:[bx].seclow,cx
	adc	ss:[bx].sechigh,0
	mov	ax,cx
	call	sct2byte
	add	di,ax
tod4:
	cmp	[numsct],0
	jne	tod1

; set vars for first uob following last one not found
;   (which is only sort of the first one found)

	mov	cx,[numuobx]
	mov	ax,[sectorx.seclow]
	add	ax,cx
	mov	ss:[bx].seclow,ax
	mov	ax,[sectorx.sechigh]
	adc	ax,0
	mov	ss:[bx].sechigh,ax
	mov	di,[bufptrx]
	mov	ax,cx
	call	sct2byte
	add	di,ax
	mov	cx,[numsctx]
	sub	cx,[numuobx]
	pop	es

lundef	numsct
lundef	bufptrx
lundef	numsctx
lundef	sectorx
lundef	numuobx

lendp	todisk

	subttl	chklogd - check for a logical drive change
	page
;======================================================================
;,fs
; chklogd - check for a logical drive change
; 
; if the device driver supports get/set logical drive
; call to see if the last logical drive differs from the one
;   for this io
; if it does
;   find the bdb for that logical drive
;   set cacheing off for that bdb
;   call flushbdb to flush that bdb and invalidate uobs for bdb
;   restore [bdbcache] for bdb
;
; this is to make sure that everything which needs to be flushed to
;   the old disk is flushed before the disks are changed
; invalidating the uobs for the old disk makes things happen more
;   logically if the user fails to replace the disk (if so, we read
;   it correctly rather than taking stuff out of the cache for the
;   new disk the user failed to put in)
; 
; in:	ds -> bdb
; 
; out:	c if an error occurs flushing previous logical drive
;	 ax = error code
;	nc
;	ax destroyed, no other registers changed
; 
;,fe
;====================================================================^
	assume	ds:bdb,es:nothing,ss:nothing
chklogd proc near
	push	es
	push	ds
	mov	ds,[bdbreal]		; on real drive
	push	bp
	push	di
	push	si
	push	dx
	push	cx
	push	bx
	push	ds
	mov	dl,[bdbunit]
	mov	dh,[bdbid]
	lds	si,[bdbdrvr]
	assume	ds:nothing
	test	byte ptr [si+4],40h
	jz	chklx			; z if supports get/set logical drive
	xor	ax,ax			; block device
	mov	al,23			; get logical drive
	call	devchk
	cmc
	jnc	chklx			; no error if device drive doesn't like us
	pop	ds
	push	ds
	assume	ds:bdb
	or	dl,dl
	jz	chklx			; only one logical drive
	dec	dl
	cmp	dl,[bdbid]
	je	chklx			; logical drive not changed
	mov	al,dl
	call	findbdb			; find last logical drive bdb
	cmc				; on internal error (bdb not found?) don't
	jnc	chklx			; choke
	mov	ds,[bdbreal]
	call	flushbdb		; else flush and invalidate all uobs
	call	invbdb			; for the drive
chklx:
	pop	ds
	pop	bx
	pop	cx
	pop	dx
	pop	si
	pop	di
	pop	bp
	pop	ds
	pop	es
	ret
chklogd endp

	subttl	motoron - force motor for bdb to stay on
	page
;======================================================================
;,fs
; motoron - force motor for bdb to stay on
; 
; if postponed writes are active,
;   physically turn the motor on and set motor status and motor
;     count bytes in bios as appropriate
;   turn on our motor poll routine to keep it forced on
;
; see rdsector to see how we find out how to physically turn it on
; this won't be called with [bdbcache] off
; 
; in:	ds -> bdb
; 
; out:	no registers changed
; 
;,fe
;====================================================================^
	assume	ds:bdb,es:nothing,ss:nothing
motoron proc near
	push	es
	push	dx
	push	ax
	mgetscb2 es
	assume	es:grp
	cmp	[scbcwrf],0
	jne	mon0
	cmp	[scbcwrl],0
	je	monx			; cache is write-through
mon0:
	mgetzero2 es
	assume	es:nothing
	mov	al,[bdbdmtr]
	or	al,al
	jz	monx			; not init'ed (implies that the very first
					;   i/o to this bdb is an int 26h - not likely)
	js	monx			; either already on or not init/ed

; physically turn motor on

	or	[bdbdmtr],80h		; signal it's on
	and	byte ptr es:[043fh],not 30h  ; clear selected motor field
	or	es:[043fh],al		; set to us with our bit on
	mov	al,es:[043fh]
	rol	al,1
	rol	al,1
	rol	al,1
	rol	al,1
	or	al,0ch			; cause it says to
	mov	dx,03f2h
	mov	byte ptr es:[0440h],0ffh; keep the motor running
	out	dx,al

; enable poll routine to keep motor on

	mgetscb2 es
	assume	es:grp
	mov	ax,[scbtimer]
	add	ax,18
	jnz	mon1			; check it every second
	inc	ax			; 0 is off so we don't allow it
mon1:
	mov	[motor],ax		; enables poll routine
monx:
	pop	ax
	pop	dx
	pop	es
	assume	es:nothing
	ret
motoron endp

	subttl	motoroff - allow motor to be turned off for bdb
	page
;======================================================================
;,fs
; motoroff - allow motor to be turned off for bdb
; 
; if postponed writes are active,
;   set motor status flag to indicate this motor isn't selected or on
;   if it was the only one on
;     set the bios motor timer flag to 2 seconds after which
;       the bios will turn it off
;     clear our motor poll routine which kept it on
;
; this might be called with [bdbcache] off - we allow that so we
;   can temporarily turn it off so the uob's for the bdb are
;   invalidated, while still recognizing that the motor can be
;   turned off now that the bdb has been flushed
; 
; in:	ds -> bdb
; 
; out:	no registers changed
; 
;,fe
;====================================================================^
	assume	ds:bdb,es:nothing,ss:nothing
motoroff proc near
	push	es
	push	ax
	mgetscb2 es
	assume	es:grp
	cmp	[scbcwrf],0
	jne	moff1
	cmp	[scbcwrl],0
	je	moffx			; write-through
moff1:
	mgetzero2 es
	assume	es:nothing
	mov	al,[bdbdmtr]
	or	al,al
	jns	moffx			; off or not init'ed (implies that the very
					;   first i/o to this bdb is an int 26h)
	cmp	al,-1
	je	moffx			; not a floppy or we can't deal with it
	and	[bdbdmtr],not 80h	; flag it off
	and	al,0fh			; clear selected motor (bits 4,5)
	not	al			; and mask for our bit
	and	al,es:[043fh]
	mov	es:[043fh],al		; clearing it in motor status
	test	al,0fh			; testing for any other motors active
	jnz	moffx			; z if none other still running
	mov	byte ptr es:[0440h],25h	; 2 seconds from last one off
	mgetscb2 es
	assume	es:grp
	mov	[motor],0		; no more polling to keep the motor on
moffx:
	pop	ax
	pop	es
	assume	es:nothing
	ret
motoroff endp

	subttl	flush - flush all changed uobs in the cache
	page
;======================================================================
;,fs
; flush - flush all changed uobs in the cache
; 
; calls flushbdb for each bdb
;
; note fake bdb's will have [bdbclpf] = -1 so won't cost much
; call flush with complete security each time you want to make sure
;   the disk is in sync with the cache - set [scbflush] to 'Y' if
;   you want to postpone error reporting until the respective owner
;   task is current - but then flush will return possibly without
;   having done anything (make sure you set [scbflush] back to <> 'Y')
; clears flush timers regardless of whether its a polled flush
; ignores any errors from flushbdb
; 
; in:	
; 
; out:	no registers changed
; 
;,fe
;====================================================================^
	assume	ds:nothing,es:nothing,ss:nothing
flush proc near
	push	es
	push	ds
	push	ax
	mgetscb2 es
	assume	es:grp
	mov	[flushf],0		; clear flush timers
	mov	[flushl],0
	mov	ax,[scbbdbpf]
flush1:
	or	ax,ax
	jz	flush3
	mov	ds,ax
	assume	ds:bdb
flush1a:
	call	flushbdb
flush2:
	mov	ax,[bdbnext]
	jmp	flush1
flush3:
	pop	ax
	pop	ds
	pop	es
	ret
flush endp

	subttl	flushbdb - flush all changed uobs for a bdb
	page
;======================================================================
;,fs
; flushbdb - flush all changed uobs for a bdb
; 
; if not a polled flush, clear all error indicators
;   this task will have to deal with all critical errors
; call fdirect to see which direction to flush
; if flushing backwards
;   for each uob which is changed and has no pending error
;     call flushuob if uob doesn't cross a cylinder boundary
;     call flushuob if uob is prior to root directory
;     else call flushback
; else
;   for each uob which has no pending error
;     call flushuob
; if there are no pending errors for the bdb
;   turn the motor off if it's a floppy bdb
;
; the only error currently possible is the error from flush24 when
;   a polled flush critical error has to be postponed, in which case
;   it is telling flushbdb not to continue for the bdb because
;   the error was write-protect, drive not ready or general failure
;   a polled flush only comes from subroutine flush which ignores
;   any flushbdb error return
; all non-polled flushes can't get errors currently, but all the
;   callers pay attention to whether or not an error occurred
; originally i had set things up so flush back happened even if
;   bdbspc wasn't defined - each uob was flushed forward, but they
;   were flushed in backwards order - this took a long time on a
;   floppy and sounded terrible since many uob's cross the cylinder
;   boundary (all this in a test case where i forced bdbspc undefined)
;   - so i changed fdirect to flush forwards if [bdbsc] isn't defined
;   causing an extra seek to the top of the disk, but what you gonna
;   do
; we stop flushing backwards at the fat so writing the extra copies
;   of the fat doesn't seek back and forth
; 
; in:	ds -> bdb
; 
; out:	c if error
;	 ax = error code
;	else nc
;	ax destroyed, no other registers changed
; 
;,fe
;====================================================================^
	assume	ds:bdb,es:nothing,ss:tcb
flushbdb proc near
	push	es
	push	ds
	mov	ds,[bdbreal]		; on real drive
	push	di
	push	si
	push	dx
	push	cx
	push	bx
	mgetscb2 es
	assume	es:grp
        cmp	[scbflush],'Y'		; if called from flshpoll
	jne	fbdb0
	cmp	[scbi15tsl],'Y'
	je	fbdb0
	cmp	[scbbdbbsy],0		; and if the bdb gate is closed
	je	fbdb0
	jmp	fbdby			; then exit rather than suspend
fbdb0:	
	call	chk_bdbgate		; check if ok to enter this layer
	mov	es,[scbclst]
	assume	es:nothing
	cmp	[bdbclpf],-1
	jmpe	fbdb4			; nothing for bdb in cache
	call	fdirect			; compute direction of flush
	jnc	fbdb1			; nc for flush backwards
	jmp	fbdb2g			; else flush forward

; flush from high to low starting w/ es:di cache descriptor
; except from low to high for anything < root directory start
; (so fat flushing doesn't waste writes of fat copies 2..n)

fbdb1:
	cmp	es:[di].csector+2,0
	jne	fbdb2

;##<
;	mov	ax,word ptr es:[di].csector

	mov	ax,es:[di].csector
;##>


	cmp	ax,[bdbdir]
	jnb	fbdb2
	jmp	fbdb2g			; low to high for remainder (note bx = first)
fbdb2:
	test	es:[di].cstatus,wrx
	jz	fbdb2f			; z if unchanged - no need to write
	cmp	es:[di].cerror,0
	je	fbdb2ax			; ne if pending error - leave it alone


;!!<
;	mov	ax,ss
;	cmp	ax,es:[di].cownid

	mov	al,byte ptr [tcbid]
	cmp	al,es:[di].cownid
;!!>


	jne	fbdb2f			; unless this tcb owns it
fbdb2ax:

; uob crosses a cylinder boundary if sectors/cylinder < sectors in uob
;   or if the remainder from dividing the absolute end sector + 1
;   by sectors/cylinder is < sectors in uob

	mov	cx,[bdbspc]

;##<
;	mov	ax,word ptr es:[di].csector
;	mov	dl,byte ptr es:[di].csector+2
;	xor	dh,dh

	mov	ax,es:[di].csector
	mov	dx,es:[di].csector+2
;##>


	add	al,byte ptr es:[di].cnumsct
	adc	ah,0
	adc	dx,0
	add	ax,word ptr [bdbhddn]
	adc	dx,word ptr [bdbhddn+2]
	div	cx			; dx = offset into cyl past end uob
	or	dx,dx
	jnz	fbdb2a
	mov	dx,cx			; (use remainder of [bdbspc] if remainder is 0)
fbdb2a:
	or	ch,ch
	jnz	fbdb2b
	cmp	cl,es:[di].cnumsct
	jb	fbdb2c			; spc < numsct so flush back
fbdb2b:
	or	dh,dh
	jnz	fbdb2d
	cmp	dl,es:[di].cnumsct	; remainder >= sectors in uob means
	jae	fbdb2d			;   flush forward
fbdb2c:
	call	flushback
	jc	fbdbx
	jmp	fbdb2f
fbdb2d:
	call	flushuob
	jc	fbdbx
fbdb2f:
	mov	di,es:[di].clocprv
	cmp	di,-1
	je	fbdb4
	jmp	fbdb1

; flush from low to high starting w/ es:bx cache descriptor

fbdb2g:
	mov	di,bx
fbdb3:
	cmp	es:[di].cerror,0
	je	fbdb3a


;!!<
;	mov	ax,ss
;	cmp	ax,es:[di].cownid

	mov	al,byte ptr [tcbid]
	cmp	al,es:[di].cownid
;!!>


	jne	fbdb3b
fbdb3a:
	call	flushuob
	jc	fbdbx
fbdb3b:
	mov	di,es:[di].clocnxt
	cmp	di,-1
	jne	fbdb3
fbdb4:

; allow floppy motor to turn off if no error occurred

	mov	di,[bdbclpf]
fbdb7:
	cmp	di,-1
	je	fbdb8			; no errors pending for bdb
	cmp	es:[di].cerror,0
	jne	fbdbx			; (and nc)
	mov	di,es:[di].clocnxt
	jmp	fbdb7
fbdb8:
	call	motoroff		; if on
	clc
fbdbx:
	call	exit_bdbgate
fbdby:
	pop	bx
	pop	cx
	pop	dx
	pop	si
	pop	di
	pop	ds
	pop	es
	ret
flushbdb endp

	subttl	fdirect - decide direction to flush bdb
	page
;======================================================================
;,fs
; fdirect - decide direction to flush bdb
; 
; if [bdbspc] = 0 (sectors/cylinder isn't defined) flush fwd
; find first uob to flush
; if start sector of first uob >= current sector on disk flush fwd
; find last uob to flush
; if end sector of last uob <= current sector flush back
; else if start of first uob is closer to current sector than
;   end of last uob flush fwd
; else flush back
;
; a helper for flushbdb
; originally i had set things up so flush back happened even if
;   bdbspc wasn't defined - each uob was flushed forward, but they
;   were flushed in backwards order - this took a long time on a
;   floppy and sounded terrible since many uob's cross the cylinder
;   boundary (all this in a test case where i forced bdbspc undefined)
;   - so i changed fdirect to flush forwards if [bdbsc] isn't defined
;   causing an extra seek to the top of the disk, but what you gonna
;   do
; 
; in:	ds -> bdb
; 
; out:	bx = first changed uob
;	di = last changed uob
;	c to flush forward
;	nc to flush backward
;	bx, di destroyed, no other registers changed
; 
;,fe
;====================================================================^
	assume	ds:bdb,es:nothing,ss:nothing
fdirect proc near
	push	dx
	push	cx
	push	ax
	mov	bx,[bdbclpf]		; caller makes sure it's not -1
	cmp	[bdbspc],0
	stc
	je	fdrx			; only if sectors / cluster is defined

; find first uob to flush

	mov	ax,word ptr [bdbslo]
	mov	dx,word ptr [bdbshi]
	mov	di,bx
fdr0a:
	cmp	di,-1
	stc
	je	fdrx			; nothing to flush
	test	es:[di].cstatus,wrx
	jnz	fdr0b			; nz for first to flush
	mov	di,es:[di].clocnxt
	jmp	fdr0a
fdr0b:
	mov	bx,di			; remember first to flush

;##<
;	sub	ax,word ptr es:[di].csector
;	sbb	dl,es:[di].csector+2

	sub	ax,es:[di].csector
	sbb	dx,es:[di].csector+2
;##>


	jb	fdrx			; last i/o precedes first in cache (c & fwd)
	mov	di,es:[di].clocnxt
	mov	cx,bx			; cx ends up set to last to flush

; find last to flush

fdr1:
	cmp	di,-1
	je	fdr1b
	test	es:[di].cstatus,wrx
	jz	fdr1a
	mov	cx,di			; remember it's changed
fdr1a:
	mov	di,es:[di].clocnxt
	jmp	fdr1
fdr1b:
	mov	di,cx
	cmp	di,bx
	stc
	je	fdrx			; e if only one to flush



;##<
;
; dh:cx = distance from first in cache to last i/o
;
;	mov	cx,ax
;	mov	dh,dl
;	mov	ax,word ptr es:[di].csector
;	mov	dl,es:[di].csector+2
;	add	al,es:[di].cnumsct
;	adc	ah,0
;	adc	dl,0			; dl:ax = last in cache + 1
;	sub	ax,[bdbslo]
;	sbb	dl,byte ptr [bdbshi]
;	cmc				; (for nc return)
;	jnc	fdrx			; last i/o follows last in cache (nc & bak)
;
;; dl:ax = distance from last i/o to last sector
;; dh:cx = distance from last i/o to first sector
;
;	cmp	dh,dl
;	jne	fdrx			; c if dh < dl and fwd, else nc and bak
;	cmp	cx,ax			; c if cx < ax and fwd, else nc and bak

	push	bx
	mov	cx,ax
	mov	bx,dx

; bx:cx = distance from first in cache to last i/o

	mov	ax,es:[di].csector
	mov	dx,es:[di].csector+2
	add	al,es:[di].cnumsct
	adc	ah,0
	adc	dx,0			; dx:ax = last in cache + 1
	sub	ax,[bdbslo]
	sbb	dx,[bdbshi]
	cmc				; (for nc return)
	jnc	fdrw			; last i/o follows last in cache (nc & bak)

; dx:ax = distance from last i/o to last sector
; bx:cx = distance from last i/o to first sector

	cmp	bx,dx
	jne	fdrw			; c if bx < dx and fwd, else nc and bak
	cmp	cx,ax			; c if cx < ax and fwd, else nc and bak
fdrw:
	pop	bx
;##>




fdrx:
	pop	ax
	pop	cx
	pop	dx
	ret
fdirect endp

	subttl	flush24 - handle a critical error during flush
	page
;======================================================================
;,fs
; flush24 - handle a critical error during flush
; 
; if this is a polled flush and the current task is the owner task
;   flag the owner task for a pending error, set him top priority
;   return c if write-protect, drive not ready or general failure
;     (figuring we'd just get the same error for each uob in the bdb)
;   else return nc to flush as much as possible
; otherwise
;   if inside mos's polling logic
;     call moxcpcor's int 24h handler (so we know abort will return)
;   else call applications INT 24 handler
;     on retry, do it
;     on ignore, pretend the error didn't happen
;     on fail, invalidate the single uob
;     on abort, invalidate all uob's for this bdb
;   return nc regardless to allow flushing to continue
;     (user can always abort and there will be nothing more to flush)
;
; fail is not currently implemented in moxcpcor's int 24h
; ignore is currently not displayed as an option in moxcpcor's 24h
;   though 'i' is accepted and returned as ignore
; 
; in:	registers set up for a toint24 call
;	ss -> tcb
; 
; out:	c if error to stop flushing for this bdb for now
;	nc to continue flushing for this bdb
;	no registers changed
; 
;,fe
;====================================================================^
	assume	ds:nothing,es:nothing,ss:tcb
lproc	flush24

ldword	sav24

	push	es
	push	ds
	push	di
	push	ax
	mgetscb2 ds
	assume	ds:grp
	mov	di,[scbccur]
	mov	es,[scbclst]
	mov	es:[di].cerror,'Y'	; mark error in uob

;!!<
;	mov	ax,es:[di].cownid

	call	cownid2tcb		; return tcb in ax for es:[di].cownid
;!!>


	mov	es,ax
	assume	es:tcb
	cmp	[intsl],0		; could be in tsl if a polled flush
	jne	f24a0a			;   (get keys would hang)
	cmp	ax,[scbtcbpc]		; e if owned by current task
	jne	f24a0a
	cmp	[tcb24nest],0		; already within toint24?
	jne	f24a0bx
	jmp	short f24ok
f24a0bx:
	mov	[tcb24nest],2		; if already within toint24, signal
	jmp	short f24a0c		; the exit logic to set tcbflush
f24a0a:

; either a polled flush, or owner is not current task

	cmp	[tcbflush],0
	je	f24a0b			; e if no error pending
	cmp	[tcbflush],'Y'
	je	f24a0c			; e if unrecognized pending error
	mov	[tcbflush],'n'		; else signal new error
	jmp	f24a0c
f24a0b:
	mov	[tcbflush],'Y'		; and in tcb
	mov	al,[tcbpri]		; total maximum priority while still
	or	al,0f0h			;   being able to restore prior pri
	push	si
	push	dx
	push	cx
	push	bx
	callmos1 reordlst
	pop	bx
	pop	cx
	pop	dx
	pop	si
f24a0c:
	pop	ax
	pop	di

; fail the remainder of the bdb flush on write-protect, not-ready or
;   general failure, else continue

	mov	ax,di
	cmp	al,wrprot-19
	je	f24a1
	cmp	al,notrdy-19
	je	f24a1
	cmp	al,genfail-19
	mov	ax,0			; appears like ignore
	clc				;   (but es:[di].cerror is set)
	jne	f24a2
f24a1:
	mov	ax,err24h		; appears like fail
	stc
f24a2:
	pop	ds
	pop	es
	jmp	f24x
	assume	es:nothing,ss:tcb
f24ok:

; either not a polled flush, or owner is current task
; set up handler for moxcpcor int 24h

	pop	ax
	pop	di
	pop	ds
	assume	ds:nothing
	pop	es
	assume	es:nothing

; set tcbcacer flag to let the i24 handler within moxcpcor know that
; this is a cacheing error

	mov	[tcbcacer],1
	and	ah,not flshflg
	call	toint24
	mov	[tcbcacer],0
	push	es			; clear error flag
	push	di
	mgetscb2 es
	assume	es:grp
	mov	di,[scbccur]
	mov	es,[scbclst]
	mov	es:[di].cerror,0
	pop	di
	pop	es
	assume	es:nothing
	jmpnc	f24x			; retry or ignore just like we're told

; c for fail or abort

	or	ax,ax
	jz	f24abort

; fail chosen - free the failed uob only

	push	es
	push	di
	push	si
	mgetscb2 es
	assume	es:grp
	mov	di,[scbccur]
	mov	es,[scbclst]
	assume	es:nothing
        push	ds
        call	findbdbc		; find bdb for uob
	call	cfree
        pop	ds
	MGetSCB2 es
	assume	es:grp
	cmp	 [scbflush],'Y'		; if not in flush poll, fail app
	jne	f24fail
	mov	si,-1			; so cmp si,0 returns nz,nc below
	jmp	f24ab3
f24fail:

; return 'fail'

	pop	si
	pop	di
	pop	es
	assume	es:nothing
	mov	ax,err24h		; appears like fail
	stc
	jmp	f24x
f24abort:

; abort chosen - free all uob's for this bdb

	push	es
	push	di
	push	si
	mgetscb2 es
	assume	es:grp
	mov	ax,[scbtcbpc]
	mov	di,[scbccur]
	mov	es,[scbclst]
	assume	es:nothing

; find first for bdb
; (we don't know where bdb is to find the first through it)

f24ab1:
	mov	si,di
	mov	di,es:[di].clocprv
	cmp	di,-1
	jne	f24ab1
f24ab2:
	cmp	si,-1
	je	f24ab3
	mov	di,si
	mov	si,es:[di].clocnxt
	test	es:[di].cstatus,wrx
	jz	f24ab2


;!!<
;	cmp	ax,es:[di].cownid

	push	ax
	push	bx
	mov	bx,ax
	call	cownid2tcb
	cmp	bx,ax
	pop	bx
	pop	ax
;!!>


	jne	f24ab2
	push	ax
        push	ds
        call	findbdbc		; find bdb for uob
	call	cfree
        pop	ds
	pop	ax
	jmp	f24ab2
f24ab3:

; make it look like ignore if abort or fail (we've done what we had to)

	xor	ax,ax			; ax = 0
	cmp	si,0			; nz & nc (si = -1)
	pop	si
	pop	di
	pop	es
	assume	es:nothing
f24x:

lundef	sav24

lendp	flush24

	subttl	tomox24 - pass int 24h to moxcpcor
	page
;======================================================================
;,fs
; tomox24 - pass int 24h to moxcpcor
; 
; saves int 24h
; sets int 24h to moxcpcor critical error handler
; calls toint24
; restores int 24h
; 
; in:	as toint24 (mosfutl2)
; 
; out:	as toint24
; 
;,fe
;====================================================================^
	assume	ds:nothing,es:nothing,ss:nothing
lproc   tomox24

ldword  sav24

	push	es
	push	ds
	push	ax
	mgetscb2 es
	assume	es:grp
	mgetzero2 ds
	assume	ds:nothing
	mov	ax,ds:[24h*4]
	mov	word ptr [sav24],ax
	mov	ax,ds:[24h*4+2]
	mov	word ptr [sav24+2],ax
	mov	ax,word ptr [scbcin24]
	mov	ds:[24h*4],ax
	mov	ax,word ptr [scbcin24+2]
	mov	ds:[24h*4+2],ax
	pop	ax
	pop	ds
	pop	es
	assume	es:nothing
	call	toint24

; restore previous int 24h

	push	ds
	push	ax
	mgetzero2 ds
	assume	ds:nothing
	mov	ax,word ptr [sav24]
	mov	ds:[24h*4],ax
	mov	ax,word ptr [sav24+2]
	mov	ds:[24h*4+2],ax
	pop	ax
	pop	ds

lundef	sav24

lendp   tomox24

	subttl	flushdir - flush all dir and fat sectors for a bdb
	page
;======================================================================
;,fs
; flushdir - flush all dir and fat sectors for a bdb
; 
; if cacheing is enabled and postponed write is enabled
;   for bdb and system, do nothing
; else
;   for each uob for bdb, if it's a fat or dir sector, and it
;     was last written by this tcb (the one doing the mos function)
;       call flushuob to flush it to disk
;
; called during any dir or file function which changes fat or dir
;   sectors to make sure they're flushed to disk
; 
; in:	ds -> bdb
; 
; out:	c if error
;	 ax = error code
;	nc if no error
;	ax destroyed, all others unchanged
; 
;,fe
;====================================================================^
	assume	ds:bdb,es:nothing,ss:nothing
flushdir proc near
	push	es
	push	ds
	mov	ds,[bdbreal]		; on real drive
	call	chk_bdbgate		; check if ok to enter this layer
	push	di
	push	si
	mgetscb2 es
	assume	es:grp
	cmp	[scbcach],'Y'
	jne	fdir0
	cmp	[bdbcach],'Y'
	jne	fdir0			; flush if not cached
	cmp	[scbcwrf],0
	jne	fdirx			; ne if not write-through (nc)
	cmp	[scbcwrl],0
	jne	fdirx			; ne if not write-through (nc)
fdir0:
	mov	es,[scbclst]
	assume	es:nothing
	mov	di,[bdbclpf]
fdir1:
	cmp	di,-1
	je	fdirx			; e when finished (nc)
	test	es:[di].cstatus,fatflg or dirflg
	jz	fdir2			; z for data sector


;!!<
;	mov	ax,ss
;	cmp	ax,es:[di].cownid

	mov	al,byte ptr ss:[tcbid]
	cmp	al,es:[di].cownid
;!!>


	jne	fdir2			; ne if not this tcb
	call	flushuob		; flushing a dir/fat sector for tcb
	jc	fdirx
fdir2:
	mov	di,es:[di].clocnxt
	jmp	fdir1
fdirx:
	call	exit_bdbgate
	pop	si
	pop	di
	pop	ds
	pop	es
	ret
flushdir endp

	subttl	flushdata - flush all data sectors for a bdb
	page
;======================================================================
;,fs
; flushdata - flush all data sectors for a bdb
; 
; if cacheing is enabled and postponed write is enabled
;   for bdb and system, do nothing
; else
;   for each uob for bdb, if it's not a fat or dir sector, and it
;     was last written by this tcb (the one closing the file)
;       call flushuob to flush it to disk
;
; called during closefile (mosfutil) to make sure the file is
;   completely written
; 
; in:	ds -> bdb
; 
; out:	c if error
;	 ax = error code
;	nc if no error
;	ax destroyed, all others unchanged
; 
;,fe
;====================================================================^
	assume	ds:bdb,es:nothing,ss:nothing
flushdata proc near
	push	es
	push	ds
	mov	ds,[bdbreal]		; on real drive
	call	chk_bdbgate		; check if ok to enter this layer
	push	di
	push	si
	mgetscb2 es
	assume	es:grp
	cmp	[scbcach],'Y'
	jne	fdata0
	cmp	[bdbcach],'Y'
	jne	fdata0			; flush if not cached
	cmp	[scbcwrf],0
	jne	fdatax			; ne if not write-through (nc)
	cmp	[scbcwrl],0
	jne	fdatax			; ne if not write-through (nc)
fdata0:
	mov	es,[scbclst]
	assume	es:nothing
	mov	di,[bdbclpf]
fdata1:
	cmp	di,-1
	je	fdatax			; e when finished (and nc)
	test	es:[di].cstatus,fatflg or dirflg
	jnz	fdata2			; nz for a fat or dir sector

;!!<
;	mov	ax,ss
;	cmp	ax,es:[di].cownid

	mov	al,byte ptr ss:[tcbid]
	cmp	al,es:[di].cownid
;!!>
	

	jne	fdata2			; ne for another tcb
	call	flushuob		; flushing a data sector for this tcb
	jc	fdatax
fdata2:
	mov	di,es:[di].clocnxt
	jmp	fdata1
fdatax:
	call	exit_bdbgate
	pop	si
	pop	di
	pop	ds
	pop	es
	ret
flushdata endp

	subttl	flushuob - flush uob forwards
	page
;======================================================================
;,fs
; flushuob - flush uob forwards
; 
; write the uob to disk
; if uob status indicates a fat sector, write the uob to remaining
;   fat copies
;
; that things are flushed (forwards or backwards) even if cacheing
;   is disabled - sector pieces at the start and end of a read/write
;   could be buffered until the file is closed - dir and fat sectors
;   might be buffered until the particular high-level function is
;   finished
; called every time flushback isn't called and a uob needs to be
;   written
; it isn't called if there's an error pending on the uob, but it
;   is called for uob's that don't need to be written
; if any error occurs - even postponed errors - we mark the bdb so
;   we know not to turn off the drive light
; if an error occurs writing remaining fat copies, we don't write any
;   other copies - the guy who gets the error will write them
; 
; in:	es:di -> uob descriptor
;	ds -> bdb
; 
; out:	c if error
;	 ax = error code
;	nc if no error
;	ax destroyed, all others unchanged
; 
;,fe
;====================================================================^
	assume	ds:bdb,es:nothing,ss:nothing
lproc	flushuob

lstring sector,<size sectorblk>
lword	bufseg

	test	es:[di].cstatus,wrx
	jnz	flushu0a
	jmp	flushuoby
flushu0a:
	mov	es:[di].cerror,0
	push	dx
	push	cx
	push	bx

; write the uob itself

flushu0b:
	mov	cl,es:[di].cnumsct	; sectors to write
	xor	ch,ch
	lea	bx,[sector]		; start sector of write


;##<
;	mov	ax,word ptr es:[di].csector
;	mov	ss:[bx].seclow,ax
;	mov	al,es:[di].csector+2
;	xor	ah,ah

	mov	ax,es:[di].csector
	mov	ss:[bx].seclow,ax
	mov	ax,es:[di].csector+2
;##>


	mov	ss:[bx].sechigh,ax
	mov	dl,es:[di].cstatus
	xor	dl,06h			; xlat status flag to int 24h flag
	or	dl,flshflg		; signal flushing to todriver
	xor	al,al			; set al according as verify needed
	test	dl,vrfflg
	jz	flushuob1
	inc	al
flushuob1:
	and	dl,not vrfflg
	push	es
	push	di
	push	ax
	call	cmap			; map in uob
	pop	ax
	mov	[bufseg],es		; remember it in case it's a fat
	xor	di,di
	call	wrreal
	pop	di
	pop	es
	jc	fuob1a
	cmp	es:[di].cerror,0
	je	fuob1b			; compare must be ae (nc) which is
	jmp	flushuobx
fuob1a:					;   what we want
	cmp	ax,retry24h
	je	flushu0b
	stc
	jmp	flushuobx
fuob1b:
	call	markclean
	test	es:[di].cstatus,fatflg
	jz	flushuobx

; if fat, write to remaining fat copies

	mov	cl,[bdbfnum]
	xor	ch,ch
	dec	cx			; already wrote one
	jz	flushuobx
flushuob2:
	push	es
	push	di
	push	cx
fuob2ax:
	mov	dl,es:[di].cstatus
	xor	dl,06h
	and	dl,not vrfflg
	or	dl,flshflg
	mov	cl,es:[di].cnumsct
	xor	ch,ch


;$$<
;	mov	al,[bdbfsiz]
;	xor	ah,ah

	mov	ax,[bdbfsiz]
;$$>


	add	ss:[bx].seclow,ax	; nc cause < [bdbdir]
	push	es
	push	di
	xor	di,di
	mov	es,[bufseg]
	mov	al,1			; verify fat sectors
	call	wrreal
	pop	di
	pop	es
	jc	fuob2a
	cmp	es:[di].cerror,0
	je	fuob2b
	jmp	flushuob4
fuob2a:
	cmp	ax,retry24h
	je	fuob2ax
	stc
	jmp	flushuob4
fuob2b:

; throw away any cached sectors for this fat copy out of the cache
; if they're clean, it doesn't matter, if they're dirty, this is defined
; to be the correct version at this point

	mov	ax,ss:[bx].seclow
fuob2c:
	mov	di,es:[di].clocnxt
	cmp	di,-1
	je	flushuob3
	cmp	es:[di].csector+2,0
	jne	flushuob3
	cmp	ax,word ptr es:[di].csector
	ja	fuob2c
	jb	flushuob3
	call	cfree
flushuob3:
	pop	cx
	pop	di
	pop	es
	loop	flushuob2
	clc
	jmp	flushuobx
flushuob4:
	pop	cx
	pop	di
	pop	es
flushuobx:
	pop	bx
	pop	cx
	pop	dx
flushuoby:

lundef	sector
lundef	bufseg

lendp	flushuob

	subttl	flushback - flush uob backwards
	page
;======================================================================
;,fs
; flushback - flush uob backwards
; 
; starting with the latest cylinder represented in the uob's,
;   write the piece of the uob for that cylinder
;   step to preceding cylinder
;
; only called when it has been determined that the uob crosses a
;   cylinder boundary (the disk head will definitely step), we
;   don't want to step back to the beginning of the uob to do the i/o
;   then step to the next cylinder, only to have to step back to the
;   next uob
; only called when it has been determined that there is no pending
;   error for the uob and the uob has been changed
; since it has been determined that the uob crosses a cylinder
;   boundary, bdbspc and bdbhddn are defined
; it is not called for reserved or fat sectors so that flushing
;   backwards doesn't cause inefficiencies in writing multiple fat
;   copies
; the error return has some special ramifications - c is returned
;   from wrreal when flushing only if the owner of the uob is not
;   the current task (postponed error) for an error that we judge
;   might be repeated for all uob's for bdb (not ready, write-protect
;   and general failure) - no other error causes a c (see flush24)
;   so we can, and do, use c to abort the flush for this bdb only
; if any error occurs - even postponed errors - we mark the bdb so
;   we know not to turn off the drive light
; 
; in:	es:di -> uob descriptor
;	ds -> bdb
;	dx = number of sectors in last cylinder for uob
; 
; out:	c if error
;	 ax = error code
;	nc if no error
;	ax destroyed, all others unchanged
; 
;,fe
;====================================================================^
	assume	ds:bdb,es:nothing,ss:nothing
lproc	flushback

lstring sector,<size sectorblk>
lbyte	status

	push	si
	push	dx
	push	cx
	push	bx
	push	es
	push	di
	mov	es:[di].cerror,0
	mov	al,es:[di].cstatus
	or	al,flshflg		; to signal flushing to todriver
	mov	[status],al
	push	dx			; sectors to write in final cylinder
	mov	cl,es:[di].cnumsct
	xor	ch,ch			; total to write


;##<
;	mov	ax,word ptr es:[di].csector
;	add	ax,cx
;	mov	dl,es:[di].csector+2
;	mov	dh,0

	mov	ax,es:[di].csector
	add	ax,cx
	mov	dx,es:[di].csector+2
;##>


	adc	dx,0			; dx:ax = last to write + 1
	mov	bx,cx
	push	ax
	call	cmap			; get uob mapped in
	pop	ax
	mov	di,cx
	xchg	di,ax
	call	sct2byte
	xchg	di,ax
	mov	cx,bx
	pop	bx			; sectors in final cylinder
fbk1:

; compute start of write in this cylinder

	sub	cx,bx			; cx = sectors remaining after this wr
	sub	ax,bx			; dx:ax = start sector of this wr
	sbb	dx,0
fbk1a:
	push	dx
	push	cx
	push	bx
	push	ax
	mov	cx,bx			; cx = sectors to write this time
	lea	bx,[sector]
	mov	ss:[bx].seclow,ax
	mov	ss:[bx].sechigh,dx
	mov	dx,cx
	mov	ax,cx
	call	sct2byte
	sub	di,ax			; di = offset of start of this write
	mov	cx,dx
	mov	dl,[status]		; xlat status flag to int 24h flag
	xor	dl,06h
	xor	al,al			; set al according as verify needed
	test	dl,vrfflg
	jz	fbk2
	inc	al
fbk2:
	and	dl,not vrfflg
	call	wrreal
	pop	si
	pop	bx
	pop	cx
	pop	dx
	jnc	fbk2a
	xchg	si,ax
	cmp	si,retry24h
	je	fbk1a
	mov	ax,si
	stc
	jmp	fbkx
fbk2a:
	jcxz	fbk3			; no more to read
	mov	ax,si
	mov	bx,[bdbspc]
	cmp	bx,cx
	jbe	fbk1			; in the unlikely event uob > spc
	mov	bx,cx
	jmp	fbk1
fbk3:
	pop	di
	pop	es
	cmp	es:[di].cerror,0	; clear changed flag unless an
	jne	fbky			;   error occurred (note compare must
					;   be ae (nc) which is what we want)
	call	markclean
	jmp	fbky
fbkx:
	pop	di
	pop	es
fbky:
	pop	bx
	pop	cx
	pop	dx
	pop	si

lundef	sector
lundef	status

lendp	flushback

	subttl	chkbdb - see if any uob's are changed for bdb
	page
;======================================================================
;,fs
; chkbdb - see if an uob's are changed for bdb
; 
; starting with first uob for bdb,
;   check the wrx status bit to see if it's changed
;
; used by only by mediachk (mosfutl2) when some media might have
;   been changed to see if any uob's are changed
; 
; in:	ds -> bdb
; 
; out:	z if none are changed, else nz
;	no registers changed
; 
;,fe
;====================================================================^
	assume	ds:bdb,es:nothing,ss:nothing
chkbdb proc near
	push	es
	push	ds
	mov	ds,[bdbreal]		; on real drive
	push	di
	mgetscb2 es
	assume	es:grp
	mov	es,[scbclst]
	assume	es:nothing
	mov	di,[bdbclpf]
chkbdb1:
	cmp	di,-1
	je	chkbdb2
	test	es:[di].cstatus,wrx
	jnz	chkbdb2
	mov	di,es:[di].clocnxt
	jmp	chkbdb1
chkbdb2:
	pop	di
	pop	ds
	pop	es
	ret
chkbdb endp

	subttl	invbdb - invalidate all uob's for bdb
	page
;======================================================================
;,fs
; invbdb - invalidate all uob's for bdb
; 
; starting with first uob for bdb,
;   while uob has a pending error,
;     issue a critical error
;   call cfree to free the uob
;
; used by mediachk to invalidate all uob's when it determines that
;   media might have been changed and no uob's need to be flushed
; 
; in:	ds -> bdb
; 
; out:	no registers changed
; 
;,fe
;====================================================================^
	assume	ds:bdb,es:nothing,ss:tcb
invbdb proc near
	push	es
	push	ds
	mov	ds,[bdbreal]		; on real drive
	push	di
	push	cx
	push	ax
	mgetscb2 es
	assume	es:grp
	mov	es,[scbclst]
	assume	es:nothing
	mov	di,[bdbclpf]
invbdb1:
	cmp	di,-1			;   until there are no more
	je	invbdbx			; and nc
invbdb1a:
	cmp	es:[di].cerror,0
	je	invbdb1b

; can't invalidate the cache entry because of pending critical errors

	push	di
	mov	di,12			; set up general error for int 24 handler
	mov	[tcberrcod],errblock	; extended error code
	mov	al,[bdbid]
	mov	ah,dosx and (not ignorex)
	call	tomox24			; to moxcpcor
	pop	di
	jc	invbdbx			; fail specified
	jz	invbdb1a		; retry specified
					; else ignore specified
	mov	ax,err24h		;   (which we don't allow)
	stc
	jmp	invbdbx
invbdb1b:
	push	es:[di].clocnxt
	call	cfree
	pop	di
	jmp	invbdb1
invbdbx:
	mov	[bdbslo],0		; the thought is that device driver will,
	mov	[bdbshi],0		;   or has, read the boot sector to build bpb
	pop	ax
	pop	cx
	pop	di
	pop	ds
	pop	es
	ret
invbdb endp

	subttl	rdreal - really read from the disk
	page
;======================================================================
;,fs
; rdreal - really read from the disk
; 
; set up the call to todriver
; update current location on disk to end of read if no error
; else set current location on disk to home
;
; only error possible is failed int 24h
; current location on disk is maintained for flushbdb so that fdirect
;   can determine whether the current location is closer to the end
;   of the cached uob's or the start of the cached uob's
; all int 21h, 25h & 38h disk reads end up here to physically read to
;   the disk
; 
; in:	ss:[bx] -> sectorblk w/ start sector
;	cx = # sectors to read
;	es:di -> buffer to read into
;	ds -> bdb
;	dl = i/o status (fatx, dirx, datax, vrfflg, flshflg) for mapcache
; 
; out:	c if error reading
;	 ax = error code
;	else nc
;	ax destroyed, other registers unchanged
; 
;,fe
;====================================================================^
	assume	ds:bdb,es:nothing,ss:tcb
lproc rdreal

lstring rq, <size readwrite_rq>

	push	es
	push	di
	push	si
	push	ds
	push	bx
	mov	word ptr [rq].rwrBuffer,di
	mov	word ptr [rq].rwrBuffer+2,es
	mov	[rq].rwrBytesSec,cx

; presume a sector number above ffff

	mov	di,ss:[bx].seclow
	mov	word ptr [rq].rwrHugeStartSec,di
	mov	bx,ss:[bx].sechigh
	mov	word ptr [rq].rwrHugeStartSec+2,bx
	mov	[rq].rwrStartSec,0ffffh

; set other request header vars

	mov	[rq].rwrLength,size readwrite_rq
	mov	[rq].rwrFunction,4
	mov	al,[bdbunit]
	mov	[rq].rwrUnit,al
	mov	ah,[bdbmdia]
	mov	[rq].rwrMediaID,ah
	mov	ax,ss
	mov	es,ax
	lea	di,[rq].rwrStatus
	mov	cx,(13-3)/2
	xor	ax,ax
	rep	stosw
	add	di,22-13
	stosw				; clear volume id dword ptr
	stosw
	mov	cx,3			; 3 retries + 1 try
	mov	ah,dl			; ah for int 24 logic
	test	ah,allx
	jnz	rdr1
	mov	cx,0			; no int 24h unless one of allx enabled
rdr1:
	mov	al,[bdbid]		; drive number
	lds	si,[bdbdrvr]
	assume	ds:nothing

; if b1 of the driver's attribute word is set, the driver supports
; 32 bit sector numbers.
; when 32 bit sector numbers are supported, the sector number is already
; setup properly.  note that even if the sector number is below 10000,
; the rwrHugeStartSec field is used.

	test	[si].dhAttributes,2
	jnz	rdr5

; when a driver doesn't support 32 bit sector numbers, must put the 
; starting sector in the rwrStartSec field.

	mov	bx,word ptr [rq].rwrHugeStartSec
	mov	[rq].rwrStartSec,bx
rdr5:
	lea	bx,[rq]
	call	todriver
	mov	cx,word ptr [rq].rwrBytesSec
	pop	bx
	pop	ds
	assume	ds:bdb
	mov	[bdbslo],0		; who knows where we are if
	mov	[bdbshi],0		;   an error occurred
	jc	rdr4
	mov	si,ss:[bx].seclow	; remember where we ended up
	add	si,cx
	mov	[bdbslo],si
	mov	si,ss:[bx].sechigh
	adc	si,0
	mov	[bdbshi],si

; note: if the above calculation causes a wrap out of 32 bits, a
; return from this function will be made with the carry flag set.
; this is intentional -- strange things are going on if this type
; of wrap occurs.

rdr4:
	pop	si
	pop	di
	pop	es

lundef	rq

lendp	rdreal

	subttl	wrreal - really write to disk
	page
;======================================================================
;,fs
; wrreal - really write to disk
; 
; set up the call to todriver
; update current location on disk to end of write if no error
; else set current location on disk to home
;
; only error possible is failed int 24h
; current location on disk is maintained for flushbdb so that fdirect
;   can determine whether the current location is closer to the end
;   of the cached uob's or the start of the cached uob's
; all int 21h, 38h & 26h disk writes end up here to physically write
;   to the disk
; 
; in:	ss:[bx] -> sectorblk w/ start sector
;	cx = # sectors to write
;	es:di -> buffer to write
;	ds -> bdb
;	dl = i/o status (fatx, dirx, datax, vrfflg, flshflg) for mapcache
;	al = 0 for no verify, 1 for verify
; 
; out:	c if error writing
;	 ax = error code
;	else nc
;	ax destroyed, other registers unchanged
; 
;,fe
;====================================================================^
	assume	ds:bdb,es:nothing,ss:tcb
lproc wrreal

lstring rq,<size readwrite_rq>

	push	es
	push	di
	push	si
	push	bx
	push	ds
	add	al,8			; cmd for write (+ verify flag)
	mov	[rq+2],al
	mov	word ptr [rq].rwrBuffer,di
	mov	word ptr [rq].rwrBuffer+2,es
	mov	[rq].rwrBytesSec,cx

; presume a sector number above ffff

	mov	di,ss:[bx].seclow
	mov	word ptr [rq].rwrHugeStartSec,di
	mov	bx,ss:[bx].sechigh
	mov	word ptr [rq].rwrHugeStartSec+2,bx
	mov	[rq].rwrStartSec,0ffffh

; set other request header vars

	mov	[rq].rwrLength,size readwrite_rq
	mov	al,[bdbunit]		
	mov	[rq+1],al
	mov	ah,[bdbmdia]		
	mov	[rq+13],ah
	mov	ax,ss			
	mov	es,ax
	lea	di,[rq].rwrStatus
	mov	cx,(13-3)/2
	xor	ax,ax
	rep	stosw
	add	di,22-13
	stosw				; clear volume id dword ptr
	stosw
	mov	cx,3			; 3 retries + 1 try
	mov	ah,dl			; ah for int 24 logic
	or	ah,wrx			; signal writing
	test	ah,allx
	jnz	wrr1
	mov	cx,0			; no int 24h unless one of allx enabled
wrr1:
	mov	al,[bdbid]		; drive number
	mov	bh,[bdbbig]		; big volume indicator
	lds	si,[bdbdrvr]
	assume	ds:nothing


; if b1 of the driver's attribute word is set, the driver supports
; 32 bit sector numbers.
; when 32 bit sector numbers are supported, the sector number is already
; setup properly.  note that even if the sector number is below 10000,
; the rwrHugeStartSec field is used.

	test	[si].dhAttributes,2
	jnz	wdr5

; when a driver doesn't support 32 bit sector numbers, must put the 
; starting sector in the rwrStartSec field.

	mov	bx,word ptr [rq].rwrHugeStartSec
	mov	[rq].rwrStartSec,bx
wdr5:
	lea	bx,[rq]
	call	todriver
	mov	cx,word ptr [rq].rwrBytesSec
	pop	ds
	assume	ds:bdb
	pop	bx
	mov	[bdbslo],0		; who knows where we are if
	mov	[bdbshi],0		;   an error occurred
	jc	wrr4
	mov	si,ss:[bx].seclow	; remember where we ended up
	add	si,cx
	mov	[bdbslo],si
	mov	si,ss:[bx].sechigh
	adc	si,0
	mov	[bdbshi],si		; (note 24 bit sectors mean nc here)

; note: if the above calculation causes a wrap out of 32 bits, a
; return from this function will be made with the carry flag set.
; this is intentional -- strange things are going on if this type
; of wrap occurs.

wrr4:
	pop	si
	pop	di
	pop	es

lundef	rq

lendp	wrreal

	subttl	nxtcache - find a sector in the cache
	page
;======================================================================
;,fs
; nxtcache - find a sector in the cache
; 
; call chkcnxt (from wherever [scbcnxt] was left last)
; if found
;   map it in and compute start of sector and sectors remaining
; 
; in:	ss:[bx] -> sectorblk w/ start sector
;	cx = a clue as to total number of sectors in high-level i/o
;	ds -> bdb
;	dl = i/o status (fatx, dirx, datax, vrfflg, flshflg) for mapcache
; 
; out:	c if not found
;	 ax = # sectors in uob if it had been found
;	 cx = # from start sector to end of uob if it had been found
;	 [scbcsave] filled out as descriptor if it had been found
;	else nc
;	 es -> sector within uob
;	 cx = # sectors from start sector to end of uob
;	ax, cx, es destroyed, all other registers unchanged
; 
;,fe
;====================================================================^
	assume	ds:bdb,es:nothing,ss:tcb
nxtcache proc near
	push	di
	call	chkcnxt
	jc	nxtx			; c couldn't find it
	push	word ptr es:[di].cnumsct
	call	mapcache		; else map it in
	mov	di,cx
	pop	ax			; total sectors in uob
	xor	ah,ah
	sub	ax,cx			; - sectors remaining (from chkcnxt)
	call	sct2para
	mov	cx,es
	add	ax,cx
	mov	es,ax
	mov	cx,di
	clc				; found it
nxtx:
	pop	di
	ret
nxtcache endp

	subttl	cacheit - read a sector into the cache
	page
;======================================================================
;,fs
; cacheit - read a sector into the cache
; 
; check for a change in logical drive (we invalidate old drive uob's
;   if this is a new logical drive)
; get a uob for the read
; free it
; read into it
; get the uob back
; coalesce it with prior/next uob if needed
; compute offset of start sector and number of sectors from
;   start sector to the end of the uob
;
; we assume that getcache/cfree/getcache returns the same uob so
;   we don't have to worry about an int 24h never coming back
; coalesce might change anything we know about what we got, so we
;   get new [scbcele] and [scbccur] and recompute what we have to
;   return
; 
; in:	ss:[bx] -> sectorblk w/ start sector
;	cx = a clue as to total number of sectors in high-level i/o
;	ds -> bdb
;	dl = i/o status (fatx, dirx, datax, vrfflg, flshflg) for mapcache
; 
; out:	c if read or flush error
;	 ax = error code
;	else nc
;	 es -> start sector within uob
;	 cx = # sectors from start sector to end of uob
;	ax, cx, es destroyed, all other registers unchanged
; 
;,fe
;====================================================================^
	assume	ds:bdb,es:nothing,ss:tcb
lproc	cacheit

lstring sector,<size sectorblk>
lword	clue

	push	di
	push	dx
	push	bx
	call	chklogd			; check for logical drive change
	jmpc	cachx
	mov	[clue],cx
cach0:
	call	getcache		; (cx = total needed)
	jmpc	cachx			; flush error

; get parameters for read

	push	es			; buffer to read into
	mgetscb2 es
	assume	es:grp
	mov	di,[scbccur]
	mov	es,[scbclst]
	assume	es:nothing
	lea	bx,[sector]		; sector to start reading


;##<
;	mov	ax,word ptr es:[di].csector
;	mov	ss:[bx].seclow,ax
;	mov	al,es:[di].csector+2
;	xor	ah,ah

	mov	ax,es:[di].csector
	mov	ss:[bx].seclow,ax
	mov	ax,es:[di].csector+2
;##>


	mov	ss:[bx].sechigh,ax
	mov	cl,es:[di].cnumsct	; # sectors to read
	xor	ch,ch

; free it in case of read error - note that this leaves the cache
;    descriptor last in usage list - it must be free here because a
;    read error in rdreal may not return (user's int 24h may take over)

	call	cfree
	pop	es			; uob is still mapped in
	xor	di,di
	call	rdreal
	jc	cachx			;jrbw handle it one higher level
;jrbwcach1:

; get descriptor back - note this must get back the same one we cfree'd
;   above since it will take the last in usage list - actually it
;   could be different if ignore were specified on an int 24h and
;   somebody else stole our uob, but if ignore is specified we don't
;   care

	pop	bx			; back to original sector
	push	bx

;jrbw below to handle the case of int 24h, user chooses ignore and somebody
;jrbw   else has used our buffer in the meantime

	mov	cx,[clue]
	mgetscb2 es
	assume	es:grp
	mov	di,[scbccur]
	push	es
	mov	es,[scbclst]
	cmp	es:[di].cnumsct,0
	pop	es
	je	cach2			; ne if state changed cause of other
	mov	ax,[bdbclpf]		; tasks while int 24h ignored
	mov	[scbcnxt],ax
	call	nxtcache
	jnc	cach3			; ok if found
	assume	es:nothing
cach2:
	call	getcache		; get back uob (no reread cause of ignore)
	jc	cachx			; flush error
cach3:
	call	coalesce		; combine with prior/next uob if needed
	mgetscb2 es
	assume	es:grp

; compute offset of sector in uob and # sectors from that sector to
;   end of uob

	push	[scbcele]		; segment where [scbccur] uob is mapped
	mov	di,[scbccur]		; descriptor of [scbccur] uob
	mov	es,[scbclst]
	assume	es:nothing
	mov	ax,ss:[bx].seclow


;##<
;	sub	ax,word ptr es:[di].csector  ; ax = sector offset to desired

	sub	ax,es:[di].csector	; ax = sector offset to desired
;##>


	mov	cl,es:[di].cnumsct
	xor	ch,ch
	mov	bx,cx
	sub	bx,ax			; sectors remaining in buffer
	call	sct2para
	pop	cx			; buffer segment
	add	ax,cx
	mov	es,ax			; offset of sector into buffer
	mov	cx,bx
cachx:
	pop	bx
	pop	dx
	pop	di

lundef	sector
lundef	clue

lendp	cacheit

	subttl	chkcnxt - find sector in cache
	page
;======================================================================
;,fs
; chkcnxt - find sector in cache
; 
; look for first uob > our sector
; look at preceding uob to see if it contains the sector
; if so we're finished
; else
;   fill out scbcsave as uob would be
;   compute sectors in uob and sectors remaining in uob
;
; [scbcnxt] must be valid at all times - in particular it can only
;   be -1 when there are no uob's for drive, otherwise inituob will
;   fill out the uob as if there are no uob's, getcache will link
;   into the bdb as if there are no uob's, and the other uob's
;   won't be found
; [scbcnxt] saves us from having to start from the beginning of the
;   list each time we're looking for the next bunch of sectors on a
;   long read or write
; 
; in:	ss:[bx] -> sectorblk w/ start sector
;	cx = a clue as to total number of sectors in high-level i/o
;	ds -> bdb
;	dl = i/o status (fatx, dirx, datax, vrfflg, flshflg) for mapcache
; 
; out:	c if not found
;	 ax = # sectors in uob if it had been found
;	 cx = # from start sector to end of uob if it had been found
;	 [scbcsave] filled out as descriptor if it had been found
;	else nc
;	 es:di -> uob descriptor
;	 cx = # sectors from start sector to end of uob
;	ax, cx, di, es destroyed, all other registers unchanged
; 
;,fe
;====================================================================^
	assume	ds:bdb,es:nothing,ss:tcb

;##<
;lproc	chkcnxt
;
;lword	next
;
;	push	si
;	push	dx
;	push	bx
;	mov	si,cx
;	mgetscb2 es
;	assume	es:grp
;	mov	cx,[scbcnxt]
;	mov	es,[scbclst]
;	assume	es:nothing
;	mov	ax,ss:[bx].seclow
;	mov	dx,ss:[bx].sechigh
;
;; look for first uob > our sector
;
;        mov	di,cx
;chkc1:
;	mov	[next],cx
;	cmp	cx,-1
;	je	chkc1a			; all through list and not found
;	mov	di,cx
;	mov	cx,es:[di].clocnxt
;	mov	bx,word ptr es:[di].csector
;	mov	dh,byte ptr es:[di].csector+2
;	sub	bx,ax
;	sbb	dh,dl
;	jb	chkc1			; b if this uob precedes the one we want
;
;; then see if prior uob contains our sector
;
;	mov	cl,es:[di].cnumsct
;	mov	ch,bl
;	or	ch,bh
;	or	ch,dh
;	jz	chkc2			; starts with the target (and cx = cnumsct)
;	mov	di,es:[di].clocprv
;chkc1a:
;	cmp	di,-1
;	je	chkc3			; no prior (so it doesn't contain the target)
;	mov	cl,es:[di].cnumsct
;	xor	ch,ch
;	mov	bx,word ptr es:[di].csector
;	mov	dh,es:[di].csector+2
;	dec	cx			; (to give us b below)
;	add	bx,cx
;	adc	dh,0			; dh:bx = last sector in uob
;	sub	bx,ax
;	sbb	dh,dl
;	jb	chkc3			; last sector < target (not found)
;	inc	bx			; (back from dec cx above)
;	mov	cx,bx			; sectors remaining in uob
;chkc2:
;
;; found (cx already sectors remaining)
;
;	push	ds
;	mgetscb2 ds
;	assume	ds:grp
;	mov	[scbcnxt],di		; remember where found for next chkcnxt
;	mov	ax,es:[di].clocnxt	; next time, start looking at next one
;	cmp	ax,-1			;   unless it's the last one (in which case
;	je	chkc2a			;   we have to start with this one again)
;	mov	[scbcnxt],ax
;chkc2a:
;	pop	ds
;	assume	ds:bdb
;	clc
;	jmp	chkcx
;chkc3:
;
;; not found
;
;	pop	bx
;	push	bx
;	mov	cx,si			; total needed clue
;	mov	ax,di			; prior descriptor
;	mov	dx,[next]		; next descriptor
;	mgetscb2 es
;	assume	es:grp
;	mov	[scbcnxt],ax		; remember prior for next chkcnxt
;	cmp	ax,-1			; if no prior, remember next
;	je	chkc3a			;  (ok even if there is no next)
;	cmp	dx,-1			; else remember next if there is one to
;	je	chkc3b			;  save looking at prior unnecessarily
;chkc3a:					;  (if prior to this sector, it's prior
;	mov	[scbcnxt],dx		;  later sectors)
;chkc3b:
;	lea	di,scbcsave
;	call	inituob			; fill out scbcsave
;
;; compute total sectors and sectors remaining
;
;	pop	bx
;	push	bx
;	mov	ax,ss:[bx].seclow
;	sub	ax,word ptr es:[di].csector  ; ax = sector offset into uob
;	mov	cl,es:[di].cnumsct
;	xor	ch,ch
;	sub	cx,ax			; sectors remaining
;	add	ax,cx			; total sectors
;	stc				; flag not found
;chkcx:
;	pop	bx
;	pop	dx
;	pop	si
;
;lundef	next
;
;lendp	chkcnxt


lproc	chkcnxt

lword	next
lword	clue

	push	si
	push	dx
	push	bx
	mov	[clue],cx
	mgetscb2 es
	assume	es:grp
	mov	cx,[scbcnxt]
	mov	es,[scbclst]
	assume	es:nothing
	mov	ax,ss:[bx].seclow
	mov	dx,ss:[bx].sechigh

; look for first uob > our sector

        mov	di,cx
chkc1:
	mov	[next],cx
	cmp	cx,-1
	je	chkc1a			; all through list and not found
	mov	di,cx
	mov	cx,es:[di].clocnxt
	mov	bx,es:[di].csector
	mov	si,es:[di].csector+2
	sub	bx,ax
	sbb	si,dx
	jb	chkc1			; b if this uob precedes the one we want

; then see if prior uob contains our sector

	mov	cx,bx
	or	cx,si
	mov	cl,es:[di].cnumsct
	jz	chkc2			; starts with the target (and cx = cnumsct)
	mov	di,es:[di].clocprv
chkc1a:
	cmp	di,-1
	je	chkc3			; no prior (so it doesn't contain the target)
	mov	cl,es:[di].cnumsct
	xor	ch,ch
	mov	bx,es:[di].csector
	mov	si,es:[di].csector+2
	dec	cx			; (to give us b below)
	add	bx,cx
	adc	si,0			; si:bx = last sector in uob
	sub	bx,ax
	sbb	si,dx
	jb	chkc3			; last sector < target (not found)
	inc	bx			; (back from dec cx above)
	mov	cx,bx			; sectors remaining in uob
chkc2:

; found (cx already sectors remaining)

	push	ds
	mgetscb2 ds
	assume	ds:grp
	mov	[scbcnxt],di		; remember where found for next chkcnxt
	mov	ax,es:[di].clocnxt	; next time, start looking at next one
	cmp	ax,-1			;   unless it's the last one (in which case
	je	chkc2a			;   we have to start with this one again)
	mov	[scbcnxt],ax
chkc2a:
	pop	ds
	assume	ds:bdb
	clc
	jmp	chkcx
chkc3:

; not found

	pop	bx
	push	bx
	mov	cx,[clue]		; total needed clue
	mov	ax,di			; prior descriptor
	mov	dx,[next]		; next descriptor
	mgetscb2 es
	assume	es:grp
	mov	[scbcnxt],ax		; remember prior for next chkcnxt
	cmp	ax,-1			; if no prior, remember next
	je	chkc3a			;  (ok even if there is no next)
	cmp	dx,-1			; else remember next if there is one to
	je	chkc3b			;  save looking at prior unnecessarily
chkc3a:					;  (if prior to this sector, it's prior
	mov	[scbcnxt],dx		;  later sectors)
chkc3b:
	lea	di,scbcsave
	call	inituob			; fill out scbcsave

; compute total sectors and sectors remaining

	pop	bx
	push	bx
	mov	ax,ss:[bx].seclow
	sub	ax,es:[di].csector	; ax = sector offset into uob
	mov	cl,es:[di].cnumsct
	xor	ch,ch
	sub	cx,ax			; sectors remaining
	add	ax,cx			; total sectors
	stc				; flag not found
chkcx:
	pop	bx
	pop	dx
	pop	si

lundef	next
lundef	clue

lendp	chkcnxt
;##>



	subttl	getcache - get an empty uob
	page
;======================================================================
;,fs
; getcache - get an empty uob
; 
; call freecache to get a free cache entry
; fill it out from scbcsave
; link it into the location list
; call mapcache to map it in, set status and link it into usage list
;
; getcache depends on chkcnxt having been called immediately prior
;   for the same sector - this allows us to localize all location
;   ordered list traversal in chkcnxt and also to go through the list
;   only once for any single high-level i/o - functionally, we're
;   first looking through the list to see if the uob is already
;   cached (and retrieving it if so), then getting a free uob and
;   looking through the list again to see where to link this new uob,
;   but we don't want to really _do_ it that way
; 
; in:	ds -> bdb
;	scbcsave initialized by chkcnxt (calling inituob)
;	dl = i/o status (fatx, dirx, datax, vrfflg, flshflg) for mapcache
; 
; out:	c if error flushing
;	 ax = error code
;	else nc
;	 es -> uob, ax = size of uob in sectors
;	es, ax destroyed, all other registers unchanged
; 
;,fe
;====================================================================^
	assume	ds:bdb,es:nothing,ss:tcb
getcache proc near
	push	di
	push	si
	push	cx
	push	bx
	call	freecache		; get free uob
	jmpc	getcx

; fill out descriptor using scbcsave as set by inituob

	mov	ax,ds
	mgetscb2 ds
	assume	ds:grp
	mov	bl,[scbcsave].cnumsct
	mov	es:[di].cnumsct,bl

;##<
;	mov	bx,word ptr [scbcsave].csector
;	mov	word ptr es:[di].csector,bx
;	mov	bl,[scbcsave+2].csector
;	mov	es:[di].csector+2,bl

	mov	bx,[scbcsave].csector
	mov	es:[di].csector,bx
	mov	bx,[scbcsave+2].csector
	mov	es:[di].csector+2,bx
;##>


	call	markclean
	mov	es:[di].cstatus,0
	mov	es:[di].cerror,0


;!!<
;	mov	es:[di].cownid,0

	mov	es:[di].cownid,0ffh
;!!>


; link it in to location list ([scbcsave] tells us where)

	mov	si,[scbcsave].clocprv
	mov	bx,[scbcsave].clocnxt
	mov	ds,ax
	assume	ds:bdb
        call	setbit

; si -> previous, bx -> next

	cmp	si,-1
	jne	getc1			; e if no previous (we're first)
	mov	[bdbclpf],di
	jmp	getc2
getc1:
	mov	es:[si].clocnxt,di
getc2:
	mov	es:[di].clocprv,si
	cmp	bx,-1
	je	getc3			; e if no next (we're last)
	mov	es:[bx].clocprv,di
getc3:
	mov	es:[di].clocnxt,bx
	push	word ptr es:[di].cnumsct
	call	mapcache		; map it in
	pop	ax
	xor	ah,ah			; (& nc for no error)
getcx:
	pop	bx
	pop	cx
	pop	si
	pop	di
	ret
getcache endp

	subttl	coalesce - combine uobs if needed
	page
;======================================================================
;,fs
; coalesce - combine scbbcur w/ preceding and following uobs according
; as they are adjacent pieces of the same logical uob
; 
; if [scbccur] number of sectors = [bdbsuob] then not needed
; if start of uob precedes root dir then not needed
; compute start of logical uob
; if [scbccur] doesn't start at start of logical uob
;   and prior uob starts at or after start of logical uob
;   and prior uob and [scbccur] are adjacent then combine them
; if following uob starts before the end of the logical uob
;   and [scbccur] and following uob are adjacent then combine them
;
; if just check single preceding and single following because
;   if we're current all the time, those are the only possibilities
; coalesce is needed because of the fragmentation which occurs as
;   we read less than full [bdbsuob]'s to avoid unnecessarily reading
;   known bad areas on the disk - otherwise we would waste cache
;   space leading to an effectively smaller cache, also cache
;   searches would be slower than they have to be because we would
;   have to look through more descriptors
; 
; in:	ds -> bdb
; 
; out:	no registers changed
; 
;,fe
;====================================================================^
	assume	ds:bdb,es:nothing,ss:tcb
coalesce proc near
	push	es
	push	di
	push	dx
	push	ax
	mgetscb2 es
	assume	es:grp
	mov	di,[scbccur]
	mov	es,[scbclst]
	assume	es:nothing
	mov	dl,es:[di].cnumsct
	xor	dh,dh
	cmp	dx,[bdbsuob]
	jmpe	coalx			; e if already full

;##<
;	mov	ax,word ptr es:[di].csector
;	mov	dl,es:[di].csector+2

	mov	ax,es:[di].csector
	mov	dx,es:[di].csector+2
;##>


	sub	ax,[bdbdir]
	sbb	dx,0
	jmpb	coalx			; unnecessary if start precedes root directory
	push	si
	push	cx
	push	bx

; the following code corrects a problem with divide by zero area

	push	ax
	mov	ax,dx
	xor	dx,dx
	div	[bdbsuob]
	pop	ax
	div	[bdbsuob]
	mov	si,dx			; si = offset of [scbccur] into logical uob

;##<
;	mov	ax,word ptr es:[di].csector
;	sub	ax,dx
;	mov	dl,es:[di].csector+2
;	sbb	dl,0			; dl:ax = bdbsuob boundary for uob

	mov	ax,es:[di].csector
	sub	ax,dx
	mov	dx,es:[di].csector+2
	sbb	dx,0			; dx:ax = bdbsuob boundary for uob
;##>


	or	si,si
	jz	coal2			; 0 remainder for [scbccur] starts at [bdbsuob]

; see if prior uob is adjacent to this one and in the same bdbsuob

	mov	si,es:[di].clocprv
	cmp	si,-1
	je	coal2			; no prior uob

;##<
;	mov	bx,word ptr es:[si].csector
;	mov	cl,es:[si].csector+2
;	sub	bx,ax
;	sbb	cl,dl
;	jb	coal2			; prior uob starts prior to [bdbsuob]
;	add	bx,ax
;	adc	cl,dl
;	add	bl,es:[si].cnumsct
;	adc	bh,0
;	adc	cl,0
;	cmp	cl,es:[di].csector+2
;	jne	coal2			; prior uob ends before this uob (not adjacent)
;	cmp	bx,word ptr es:[di].csector
;	jne	coal2			; prior uob ends before this uob (not adjacent)

	mov	bx,es:[si].csector
	mov	cx,es:[si].csector+2
	sub	bx,ax
	sbb	cx,dx
	jb	coal2			; prior uob starts prior to [bdbsuob]
	add	bx,ax
	adc	cx,dx
	add	bl,es:[si].cnumsct
	adc	bh,0
	adc	cx,0
	cmp	cx,es:[di].csector+2
	jne	coal2			; prior uob ends before this uob (not adjacent)
	cmp	bx,es:[di].csector
	jne	coal2			; prior uob ends before this uob (not adjacent)
;##>




; combine prior uob with [scbccur]

	xchg	si,di
	mov	bx,si
	call	cvmove

; see if following uob is adjacent and belongs in bdbsuob

coal2:

	add	ax,[bdbsuob]


;##<
;	adc	dl,0			; dl:ax = start of next bdbsuob

	adc	dx,0			; dx:ax = start of next bdbsuob
;##>


	mov	si,di
coal3:
	mov	si,es:[di].clocnxt
	cmp	si,-1
	je	coal5			; e if no following uob


;##<
;	mov	bx,word ptr es:[si].csector
;	mov	cl,es:[si].csector+2
;	sub	bx,ax
;	sbb	cl,dl
;	jnb	coal5			; start of following is >= end of bdbsuob
;	add	bx,ax
;	adc	cl,dl
;	sub	bl,es:[di].cnumsct
;	sbb	bh,0
;	sbb	cl,0
;	cmp	cl,es:[di].csector+2
;	jne	coal5			; following start > end current (not adjacent)
;	cmp	bx,word ptr es:[di].csector
;	jne	coal5			; following start > end current (not adjacent)

	mov	bx,es:[si].csector
	mov	cx,es:[si].csector+2
	sub	bx,ax
	sbb	cx,dx
	jnb	coal5			; start of following is >= end of bdbsuob
	add	bx,ax
	adc	cx,dx
	sub	bl,es:[di].cnumsct
	sbb	bh,0
	sbb	cx,0
	cmp	cx,es:[di].csector+2
	jne	coal5			; following start > end current (not adjacent)
	cmp	bx,es:[di].csector
	jne	coal5			; following start > end current (not adjacent)
;##>



coal3a:

; combine [scbccur] with following uob

	mov	bx,di
	call	cvmove			; move through vidram
coal5:
	pop	bx
	pop	cx
	pop	si
coalx:
	pop	ax
	pop	dx
	pop	di
	pop	es
	ret
coalesce endp

	subttl	cvmove - combine two uobs
	page
;======================================================================
;,fs
; cvmove - combine two uobs
; 
; map in 'to' uob into
; compute buffer offset in 'to' uob (past current contents)
; compute length to move (length of 'from' uob)
; compute offset into cache of 'from' uob
; if not memory managed, just move it
; if memory managed
;   map 'from' uob 4k at a time into vidram and copy it to 'to' uob
; update length of 'to' uob to include 'from' uob
; if the later uob was written, set the 'to' owner to its owner
; else set the 'to' owner to the owner of whichever uob was written
; if the error flag of the 'to' uob isn't set, set it to the error
;   flag of the 'from' uob
; free the 'from' uob
;
; cvmove is a helper for coalesce
; though si isn't changed, it is a free uob on return and thus no
;   longer a part of the location list
; in the mm case, [tcbvidw2] must be defined at all points after
;   memdev is loaded whenever disk i/o is done
; 
; in:	es:di -> uob combined to (earlier in location list)
;	es:si -> uob combined from (later in location list)
;	es:bx -> newer of two uob's (later in usage list)
;	ds -> bdb
; 
; out:	bx, cx destroyed, all others unchanged
; 
;,fe
;====================================================================^
	assume	ds:bdb,es:nothing,ss:tcb
cvmove proc near
	push	bp			; mjs 6/30/88
	push	dx
	push	ax
        push	ds
	push	es
	push	di
	push	si
	push	bx

; map in 'to' uob

	mov	dl,es:[si].cstatus
	xor	dl,06h			; adding 'from' uob status to 'to' uob
	push	es
	call	mapcache		; map in 'to' uob (and make it first in
	pop	bx			;   usage list and [scbccur])
	push	es
	mov	es,bx
	mov	cx,[bdbssiz]
	mgetscb2 ds
	assume	ds:grp

; compute offset to move to, and length to move

	mov	bl,es:[di].cnumsct
	xor	bh,bh
	push	dx
	xchg	bx,ax
	mul	cx
	xchg	bx,ax
	pop	dx
	push	bx			; buffer offset past current contents
	mov	bl,es:[si].cnumsct
	xor	bh,bh
	push	dx
	xchg	bx,ax
	mul	cx
	xchg	bx,ax
	pop	dx
	push	bx			; bytes to move

; compute para offset into cache of 'from' uob

	mov	ax,si
	mov	cl,4
	shr	ax,cl			; ax = cache element number
	mul	[scbcuob]		; ax = para offset into cache
	test	[scbmmfea],80h
	jnz	cvmv1

; non-mm case

	add	ax,[scbchdl]
	mov	ds,ax
	pop	cx
	pop	di
	pop	es
	shr	cx,1
	xor	si,si
	call	wordmov			; rep movsw (but fast on 386/486)
	jmp	cvmv4
cvmv1:

; mm case

	push	es			; get segment of page frame in memmman
	push	bx			; which can be used as mapping area
	les	bx,[scbmmptr]		; and record in bp
	mov	bp,es:[bx+parmpfa]
	pop	bx
	pop	es
	mov	dh,al			; dh = dx:ax % ( 4096 / 16 )
	mov	al,ah
	mov	ah,dl			; ax = dx:ax / ( 4096 / 16 )
	add	ax,[scbchdl]
	mov	bx,ax			; bx = handle to map
	mov	al,dh
	xor	ah,ah
	mov	cl,4
	shl	ax,cl			; byte offset into mapping space
	pop	dx			; total bytes to move
	pop	di			; offset to move to
	pop	es			; segment to move to
cvmv2:
	push	ds
	mov	cx,4096
	sub	cx,ax			; bytes to move this time
	mov	si,ax			; offset of start of move this time

; mjs 6/30/88 - converting from mapvma usage to using staging buffer in memman
; bx is page number at this point, ds -> grp
; don't need to use dx, si or di so don't need to push/pop

	push	es
	push	cx
	mov	cx,1			; mapping one page
	mov	es,bp
	mov	ah,3			; map in the cache data and make
	call	[scbmmsub]		; ds point to it
	mov	ds,bp
	assume	ds:nothing
	pop	cx
	pop	es
	cmp	cx,dx
	jb	cvmv3
	mov	cx,dx
cvmv3:
	sub	dx,cx
	shr	cx,1
	call	wordmov			; rep movsw (but fast on 386/486)
	pop	ds
	assume	ds:grp
	inc	bx			; next handle
	xor	ax,ax			; offset 0
	or	dx,dx			; bytes remaining
	jnz	cvmv2

; here, we must unmap the mm's buffer

	mov	es,bp			; get segment of page frame in mm
	push	ax
	push	cx			; and expose acutal mm buffer
	mov	cx,1
	mov	ah,4
	call	[scbmmsub]
	pop	cx
	pop	ax

cvmv4:
	pop	bx
	pop	si
	pop	di
	pop	es

; adjust number of sectors, owner and error flag in 'to' uob

	mov	cl,es:[si].cnumsct
	add	es:[di].cnumsct,cl


;!!<
;	mov	ax,es:[di].cownid
;	cmp	es:[di].cerror,0	; don't change owner if pending
;	jne	cvmv5			;   error
;	test	es:[bx].cstatus,wrx	; take later owner if any,
;	mov	ax,es:[bx].cownid	;   else other owner
;	jnz	cvmv5
;	test	es:[di].cstatus,wrx
;	mov	ax,es:[di].cownid
;	jnz	cvmv5
;	mov	ax,es:[si].cownid
;cvmv5:
;	mov	es:[di].cownid,ax
;	mov	[scblastw1],ax

	mov	al,es:[di].cownid
	cmp	es:[di].cerror,0	; don't change owner if pending
	jne	cvmv5			;   error
	test	es:[bx].cstatus,wrx	; take later owner if any,
	mov	al,es:[bx].cownid	;   else other owner
	jnz	cvmv5
	test	es:[di].cstatus,wrx
	mov	al,es:[di].cownid
	jnz	cvmv5
	mov	al,es:[si].cownid
cvmv5:
	mov	es:[di].cownid,al
	call	cownid2tcb
	mov	[scblastw1],ax
;!!>


	mov	cl,es:[di].cerror	; take either error if active
	or	cl,cl
	jnz	cvmv6
	mov	cl,es:[si].cerror
cvmv6:
	mov	es:[di].cerror,cl

; free the 'from' uob

	mov	bx,di
	mov	di,si
	pop	ds
	assume	ds:bdb
	call	cfree
	mov	di,bx
	pop	ax
	pop	dx
	pop	bp			; mjs 6/30/88
	ret
cvmove endp

	subttl	inituob - initialize a uob descriptor
	page
;======================================================================
;,fs
; inituob - initialize a uob descriptor
; 
; [bdbsuob]   = the number of sectors on this disk which fit into a
;               uob also, a unit of uob allocation (discussed in the
;               same manner as a cluster would be discussed)
; the sector  = requested sector
; clue sector = requested sector + contiguous sectors clue - 1
;               (the clue as to the last sector required)
;
; clear status, error flag, owner of last write
; set number of sectors to [bdbsuob]
;
; if sector is in the area of the disk preceding the first fat
;   set start sector to the start of the [bdbsuob] containing the
;     sector, starting with logical sector 0 as the start of the
;     first [bdbsuob]
;   adjust number of sectors, if needed, so uob ends before the start
;     of the fat area
;
; if sector is in the fat area of the disk
;   set start sector to the start of the [bdbsuob] containing the
;     sector, starting with the first sector of this fat copy as the
;     start of the first [bdbsuob]
;   adjust number of sectors, if needed, so uob ends before the start
;     of the next fat copy and before the start of the root directory
;
; if sector is in the remainder of the disk
;   set start sector to the start of the [bdbsuob] containing the
;     sector, starting with the first sector of the root dir as the
;     start of the first [bdbsuob]
;   if the clue sector is not in the root directory
;     if sector is not in the root directory
;       adjust start sector to the max of start sector and
;         the min of ( the start of the cluster containing the sector
;         the start of the track containing the sector )
;     adjust number of sectors, if needed, to min of clue sector and
;       the max of ( the end of the cluster containing the clue
;       sector and the end of the track containing the clue sector )
;     adjust the start sector, if needed, so it follows the prior uob
;     adjust the number of sectors, if needed, so this uob precedes
;       the start sector of the following uob
;
; inituob is currently just a helper for chkcnxt
; the code deliberately does not assume that the descriptor is in
;   the descriptor list ('cause currently it's not) so modifications
;   which have to reference a real descriptor have to set ds to
;   [scbclst]
; the fat special case is so we can deal properly at flush time with
;   the multiple fat update - we end up with parallel uob's for
;   fat copies and can flush the first copy to the disk to all copies
;   and throw away the uob's for any other copies - thus we stay
;   consistent through critical errors and application absolute reads
;   of fat copies
; the shenanigans for the remainder of the disk are to avoid reading
;   bad clusters unless they are specifically requested by the
;   application using absolute reads/writes - the assumptions are:
;   1.  file read/writes won't request known bad clusters so the
;       cluster containing the start, and the cluster containing the
;       good, and all the clusters in between are good (very safe
;       assumption except for code bugs or disk bugs)
;   2.  format programs which detect a bad area on the disk mark the
;       track bad, therefore the entire track containing a good
;       sector is good
;       a.  use of this assumption requires that we know sectors per
;           track and hidden sectors for the disk - there is no
;           way to acquire this information from a pre dos 3.20
;           device driver - knowing this, we attempt (in setbdbc in
;           mosddint) to validate the data and we only use it if
;           valid, but it's fuzzy
;       b.  some utilities (norton?) probably just invalidate the
;           single cluster found bad after format - this screws us
;           up totally and we'll get unnecessary critical errors by
;           deciding on a prior or following cluster to read to/from
;           the track boundary including the known bad cluster
; 
; in:	es:di -> uob descriptor to initialize
;	[scbclst]:ax -> prior uob descriptor in location order
;	[scbclst]:dx -> next uob descriptor in location order
;	cx = a clue as to the contiguous sectors required from this point
;	ss:[bx] = dword sector number required
;	ds -> bdb for sector
; 
; out:	initialized uob descriptor
;	di, bp, ds, es unchanged, all others destroyed
; 
;,fe
;====================================================================^
	assume	ds:bdb,es:nothing,ss:nothing
inituob proc near
	push	dx
	push	ax
	mov	si,cx
	mov	es:[di].cstatus,0
	mov	es:[di].cerror,0


;!!<
;	mov	es:[di].cownid,0

	mov	es:[di].cownid,0ffh
;!!>


; if cacheing is off for a particular drive, don't fill out the uob.
; this prevents sluggishness in the remote lanlink case.

	cmp	[bdbcach],0
	jne	iuob0
	mov	es:[di].cnumsct,1
	mov	ax,ss:[bx].seclow

;##<
;	mov	word ptr es:[di].csector,ax
;	mov	ax,ss:[bx].sechigh
;	mov	byte ptr es:[di].csector+2,al

	mov	es:[di].csector,ax
	mov	ax,ss:[bx].sechigh
	mov	es:[di].csector+2,ax
;##>


	pop	si
	pop	bx
	jmp	iuob6
iuob0:
	mov	cx,[bdbsuob]
	mov	es:[di].cnumsct,cl

; find out if it's in:
;     reserved area - prior to fat # 1
;     fat area	    - prior to root dir
;     data area     - remainder

	mov	ax,ss:[bx].seclow
	cmp	ss:[bx].sechigh,0
	jne	iuob2			; must be data area
	cmp	ax,[bdbdir]
	jae	iuob2			; also data area
	pop	si
	pop	bx
	cmp	ax,[bdbfat]
	jae	iuob1			; fat area

; in reserved area
;     buffer at [bdbsuob] boundary, up to [bdbsuob] sectors or
;     sector [bdbfat]-1

	div	cl
	mul	cl


;##<
;	mov	word ptr es:[di].csector,ax
;	mov	byte ptr es:[di].csector+2,0

	mov	es:[di].csector,ax
	mov	es:[di].csector+2,0
;##>


	mov	cx,[bdbfat]		; precedes fat if distance to fat # 1
	sub	cx,ax			; is greater than [bdbsuob]
	or	ch,ch
	jmpnz	iuob6
	cmp	cl,es:[di].cnumsct
	jmpae	iuob6
	mov	es:[di].cnumsct,cl	; else adjust number of sectors
	jmp	iuob6
iuob1:

; in fat area
;     buffer at [bdbsuob] boundary into respective fat copy, up to
;     [bdbsuob] sectors or start of next fat or [bdbdir]

	sub	ax,[bdbfat]		; offset from fat # 1






;$$<
;	mov	dl,[bdbfsiz]		; # sectors / fat
;	div	dl
;	mov	dh,ah			; dh = offset into fat copy
;	mul	dl			; ax = start of fat copy
;	add	ax,[bdbfat]
;	xchg	ax,dx			; dx = sector of start of fat copy
;	mov	al,ah
;	xor	ah,ah			; ax = offset into fat copy
;	div	cl
;	mul	cl			; ax = [bdbsuob] boundary in fat copy
;	add	ax,dx			; ax = sector address of [bdbsuob] boundary
;	add	dl,[bdbfsiz]		; dx = sector address past fat copy
;	adc	dh,0

comment ^

upon entry to this section of code:

 ax is a sector number of a sector in the fat

mov	dl,[bdbfsiz]
div	dl
mov	dh,ah

will produce al == 0 if the original ax sector number was in the
first fat, al == 1 if in the second fat.

in either case, ah will be the sector number relative to a fat.
saving fat relative sector number in dh


mul	dl
add	ax,[bdbfat]

will produce ax == 0 if the original ax sector number was in the
first fat, ax == [bdbfsiz] if it was in the second

adding [bdbfat] to this will make ax the sector number of the start of
the first or second fat copy


xchg	ax,dx
mov	al,ah
xor	ah,ah

will make ax a word holding the remainder of the original division. 
ax is the number of the sector within the fat.  dx now holds the
sector number of the start of the fat copy being operated on.


div	cl
mul	cl

for this operation, need to see what cl holds.  from just after the
label iuob0, come the following two lines:

	mov	cx,[bdbsuob]
	mov	es:[di].cnumsct,cl

so, cl is the total number of sectors the uob can hold.

dividing the fat relative sector number by the number of sectors
which can fit into a uob will produce:

al = the number of uobs preceding the uob which would contain the
sector in question.  could also be thought of as the zero-based fat
relative uob number.

ah = the 0 based number of the sector within the uob

multiplying al by cl will abandon the ah remainder of the previous
division.  the resulting ax value will be the fat relative sector
number of the first sector within the bdbsuob which contains the
sector in question.  this will be a zero-based number.


add	ax,dx
add	dl,[bdbfsiz]
adc	dh,0

dx holds the sector number of the first sector of the copy of the fat
in which the sector in question is located.  adding this to ax will 
produce an ax which holds the logical sector number of the start of
the bdbsuob which contains the sector in question.

adding [bdbfsiz], the number of sectors per fat, to dx will result in
a dx which is the sector number of the first sector past the copy of
the fat which is being dealt with.

upon exit from this section:

 ax = sector number of bdbsuob containing sector in question
 cx = bdbsuob
 dx = sector number of first sector after copy of fat being dealt with

^
	push	bx
	xor	dx,dx
	div	[bdbfsiz]
	mov	bx,dx			; save remainder
	mul	[bdbfsiz]
	add	ax,[bdbfat]
	xchg	ax,bx
	div	cl
	mul	cl
	add	ax,bx
	add	bx,[bdbfsiz]
	mov	dx,bx
	pop	bx
;$$>



;##<
;	mov	word ptr es:[di].csector,ax
;	mov	byte ptr es:[di].csector+2,0

	mov	es:[di].csector,ax
	mov	es:[di].csector+2,0
;##>


	add	ax,cx			; ax = start of next uob
	sub	ax,dx
	jmpbe	iuob6			; <= next fat is ok
	sub	es:[di].cnumsct,al	; else adjust number of sectors
	jmp	iuob6
iuob2:

; in data area
;     buffer up to [bdbsuob] sectors at [bdbsuob] boundary from
;     [bdbdir]

	mov	dx,ss:[bx].sechigh
	sub	ax,[bdbdir]		; offset into remainder
	sbb	dx,0

; get starting buffer = (sectors - directory) blocked at [bdbsuob]
; = (sectors - directory) - (sectors - directory) mod [bdbsuob]

	push	dx
	push	ax			; save sector for later subtract	|
	push	ax
	mov	ax,dx			; divide hi order part			|
	xor	dx,dx
	div	cx
	pop	ax
	div	cx			; dx = remainder sector/suob		|
	pop	ax			; restore original sector		|
	sub	ax,dx
	pop	dx			; and subtract remainder		|
	sbb	dx,0			;					ptr197
	add	ax,[bdbdir]
	adc	dx,0

;##<
;	mov	word ptr es:[di].csector,ax
;	mov	es:[di].csector+2,dl	; dl:ax = [bdsuob] boundary into remainder
;	add	ax,cx
;	adc	dx,0			; dl:ax = next [bdbsuob] boundary

	mov	es:[di].csector,ax
	mov	es:[di].csector+2,dx	; dx:ax = [bdsuob] boundary into remainder
	add	ax,cx
	adc	dx,0			; dx:ax = next [bdbsuob] boundary
;##>


	sub	ax,[bdbclus]
	sbb	dx,0
	jnb	iuob2a			; b if end of [bdbsuob] precedes first cluster
	pop	si			; no adjustment needed
	pop	bx
	jmp	iuob6
iuob2a:
	sub	ax,cx
	sbb	dx,0
	jb	iuob2c			; b if start sector precedes first cluster

; if start sector not in root directory, then can start at max of
;   [bdbsuob] start and ( min of cluster start and track start )

	mov	ax,ss:[bx].seclow
	mov	dx,ss:[bx].sechigh
	sub	ax,[bdbclus]
	sbb	dx,0
	mov	cl,[bdbcmsk]
	not	cl
	and	al,cl
	add	ax,[bdbclus]
	adc	dx,0			; dx:ax = cluster start sector


;##<
;	sub	ax,word ptr es:[di].csector
;	sbb	dl,es:[di].csector+2

	sub	ax,es:[di].csector
	sbb	dx,es:[di].csector+2
;##>


	jb	iuob2c			; cluster < [bdbsuob], don't bother w/ track
					;   (we've proven [bdbsuob] is ok)
	cmp	[bdbspt],0
	je	iuob2b			; sectors/track undefined
	mov	cx,ax			; cx = cluster - [bdbsuob]
	mov	ax,ss:[bx].seclow
	mov	dx,ss:[bx].sechigh
	add	ax,word ptr [bdbhddn]
	adc	dx,word ptr [bdbhddn+2]	; dx:ax = sector offset from start of
					;   physical disk
	push	bx			; divide 32 bits / 16 bits giving 32 bits
	mov	bx,ax			; physical sector / ( sectors / track )
	mov	ax,dx
	xor	dx,dx
	div	[bdbspt]
	mov	ax,bx
	pop	bx
	div	[bdbspt]		; dx = remainder
	mov	ax,ss:[bx].seclow
	sub	ax,dx
	mov	dx,ss:[bx].sechigh
	sbb	dx,0			; dx:ax = start track sector

;##<
;	sub	ax,word ptr es:[di].csector
;	sbb	dl,es:[di].csector+2

	sub	ax,es:[di].csector
	sbb	dx,es:[di].csector+2
;##>


	jb	iuob2c			; track < [bdbsuob], so cluster doesn't matter
					;   (since we've proven [bdbsuob] ok)
	cmp	ax,cx
	jb	iuob2b			; b if track is min
	mov	ax,cx			; else cluster is min
iuob2b:

; adjust start sector and number of sectors to min of track or cluster


;##<
;	add	word ptr es:[di].csector,ax

	add	es:[di].csector,ax
;##>


	adc	es:[di].csector+2,0
	sub	es:[di].cnumsct,al
iuob2c:

; adjust number read so we don't read past the min of end [bdbsuob] and
;   ( max of end clue cluster and end clue track )

	mov	ax,ss:[bx].seclow
	mov	dx,ss:[bx].sechigh
	add	ax,si
	adc	dx,0			; = first sector past clue sector
	sub	ax,[bdbclus]
	sbb	dx,0
	jnb	iuob2c1			; b occurs on a root dir read where
	xor	ax,ax			;   start sector + [bdbsuob] > [bdbclus]
	mov	dx,ax			; stop at [bdbclus]
iuob2c1:
	add	al,[bdbcmsk]		; following taking advantage of the fact
	adc	ah,0			;   of the fact that bdbcsiz is a power of 2
	adc	dx,0			; [bdbcmsk] = [bdbcsiz] - 1
	mov	cl,[bdbcmsk]
	not	cl
	and	al,cl
	add	ax,[bdbclus]
	adc	dx,0			; dx:ax = sector of cluster past clue sectors
	mov	cl,es:[di].cnumsct


;##<
;	sub	ax,word ptr es:[di].csector
;	sbb	dl,es:[di].csector+2	; dx:ax = sectors to cluster past clue

	sub	ax,es:[di].csector
	sbb	dx,es:[di].csector+2	; dx:ax = sectors to cluster past clue
;##>


	sub	ax,cx			; ch already 0, cx = cnumsct
	sbb	dx,0
	jnb	iuob2e			; [bdbsuob] <= clue cluster, ignore track
					;   (proved [bdbsuob] is ok)
	cmp	[bdbspt],0
	je	iuob2d			; sectors/track undefined
	mov	cx,ax
	mov	ax,ss:[bx].seclow
	mov	dx,ss:[bx].sechigh
	dec	si			; (equivalent to adding [bdbspt]-1 below)
	add	ax,si
	adc	dx,0			; = first past clue sectors
	inc	si
	add	ax,[bdbspt]		; ([bdbspt]-1 from above)
	adc	dx,0
	push	dx
	push	ax
	add	ax,word ptr [bdbhddn]
	adc	dx,word ptr [bdbhddn+2]
	push	bx			; 32 bits divided by 16 bits giving 32 bits
	mov	bx,ax			; a sector in track following clue /
	mov	ax,dx			;   sectors / track
	xor	dx,dx
	div	[bdbspt]
	mov	ax,bx
	pop	bx
	div	[bdbspt]
	pop	ax			; note recovering logical sector from stack
	sub	ax,dx
	pop	dx
	sbb	dx,0			; dx:ax = start sector of track past clue


;##<
;	sub	ax,word ptr es:[di].csector
;	sbb	dl,es:[di].csector+2	; sectors to track past clue

	sub	ax,es:[di].csector
	sbb	dx,es:[di].csector+2	; sectors to track past clue
;##>


	sub	al,es:[di].cnumsct
	sbb	ah,0
	sbb	dx,0
	jnb	iuob2e			; [bdbsuob] <= track sector, ignore cluster
					;   (proved [bdbsuob] is ok)
	cmp	ax,cx
	jge	iuob2d			; track >= cluster (less negative)
	mov	ax,cx
iuob2d:
	add	es:[di].cnumsct,al	; adjust sectors / track
iuob2e:

; adjust number read so we don't read past end of disk
;   (might happen on absolute read)


;##<
;	mov	ax,word ptr es:[di].csector
;	mov	dl,es:[di].csector+2
;	add	al,es:[di].cnumsct
;	adc	ah,0
;	adc	dl,0
;	sub	ax,word ptr [bdbsctr]
;	sbb	dl,[bdbsctr+2]
;	jb	iuob3			; not past end
;	or	dl,ah			; nz if starting past end (they get

	mov	ax,es:[di].csector
	mov	dx,es:[di].csector+2
	add	al,es:[di].cnumsct
	adc	ah,0
	adc	dx,0
	sub	ax,[bdbsctr]
	sbb	dx,[bdbsctr+2]
	jb	iuob3			; not past end
	or	dl,ah			; nz if starting past end (they get
	or	dx,dx
;##>


	jnz	iuob3			;   what they deserve)
	sub	es:[di].cnumsct,al
	ja	iuob3			; na if starting past end
	add	es:[di].cnumsct,al	; restore cnumsct
iuob3:
	pop	si
	pop	bx
	push	ds
	mgetscb2 ds
	assume	ds:grp
	mov	ds,[scbclst]		; because es might not be scbclst
	assume	ds:nothing

; adjust start so it doesn't precede the end of the prior uob

	cmp	si,-1
	je	iuob4

;##<
;	mov	ax,word ptr ds:[si].csector
;	mov	dl,ds:[si].csector+2
;	add	al,ds:[si].cnumsct
;	adc	ah,0
;	adc	dl,0
;	sub	ax,word ptr es:[di].csector
;	sbb	dl,es:[di].csector+2
;	jb	iuob4
;	add	word ptr es:[di].csector,ax
;	adc	es:[di].csector+2,dl
;	sub	es:[di].cnumsct,al

	mov	ax,ds:[si].csector
	mov	dx,ds:[si].csector+2
	add	al,ds:[si].cnumsct
	adc	ah,0
	adc	dx,0
	sub	ax,es:[di].csector
	sbb	dx,es:[di].csector+2
	jb	iuob4
	add	es:[di].csector,ax
	adc	es:[di].csector+2,dx
	sub	es:[di].cnumsct,al
;##>



iuob4:

; adjust end so it doesn't follow the start of the next uob

	cmp	bx,-1
	je	iuob5

;##<
;	mov	ax,word ptr es:[di].csector
;	mov	dl,es:[di].csector+2
;	add	al,es:[di].cnumsct
;	adc	ah,0
;	adc	dl,0
;	sub	ax,word ptr ds:[bx].csector
;	sbb	dl,ds:[bx].csector+2

	mov	ax,es:[di].csector
	mov	dx,es:[di].csector+2
	add	al,es:[di].cnumsct
	adc	ah,0
	adc	dx,0
	sub	ax,ds:[bx].csector
	sbb	dx,ds:[bx].csector+2
;##>



	jb	iuob5
	sub	es:[di].cnumsct,al
iuob5:
	pop	ds
	assume	ds:bdb
iuob6:
	mov	es:[di].clocprv,si	; save prior/end pointers
	mov	es:[di].clocnxt,bx	; (though it's not linked in)
	ret
inituob endp

	subttl	freecache - middle-level free a uob
	page
;======================================================================
;,fs
; freecache - middle-level free a uob
; 
; find the least recently used (lru) uob which doesn't need to be
;   (it's the one behind the most recently used)
; if all uob's require flushing, flush them all
; find lru uob which doesn't need flushing
; if none, then issue a critical error block - pending errors
;   for other tasks are preventing us from getting a uob
; free the lru uob
;
; it might pay to flush the lru uob only rather than the entire cache
;   or to flush the uob closest to the requested read/write - if the
;   cache is large and the timer values are big, there might be a lot
;   to flush
; in the same respect, it might pay to flush when the lru uob
;   requires it, rather than when all uob's require it - again, if
;   the cache and timers are big, it's going to take awhile to flush,
;   plus it would save the time of looking through up to 4096
;   descriptors to find that they're all dirty
; on the other hand, if we flush too frequently, much of the benefit
;   of postponed writes is lost since we don't queue up enough writes
; 
; in:	ss -> tcb
; 
; out:	nc if no error, es:di -> free uob descriptor
;	c and ax = error code if some error flushing cache get a free uob
;	ax, di, es destroyed, others unchanged
; 
;,fe
;====================================================================^
	assume	ds:bdb,es:nothing,ss:tcb
freecache proc near
	push	cx
freec0:
	mgetscb2 es
	assume	es:grp

; find the oldest uob which doesn't need to be flushed

	mov	di,[scbcupf]		; usage list first pointer
	mov	es,[scbclst]
	assume	es:nothing
	mov	di,es:[di].cuseprv	; oldest is one prior to newest
	cmp	es:[di].cnumsct,0	; if any are free, oldest is free
	je	freecx			;   (else there's a bug somewhere)
	mov	ax,di
	mov	cx,di			; remember when we wrap back to oldest
freec1:
	mov	di,ax
	mov	ax,es:[di].cuseprv
	test	es:[di].cstatus,wrx
	jz	freec2			; z if a clean uob
	cmp	ax,cx
	jne	freec1			; e when all dirty (wrapped to oldest)

; all cache elements are dirty, flush 'em all

	call	flush
	mov	di,cx
freec1a:
	mov	ax,es:[di].cuseprv
	test	es:[di].cstatus,wrx
	jz	freec2			; z if a clean uob
        mov	di,ax
	cmp	ax,cx
	jne	freec1a			; e when all dirty (wrapped to oldest)

; can't get a free cache entry because of pending critical errors

	mov	di,12			; set up general error for int 24 handler
	mov	[tcberrcod],errblock	; extended error code
	mov	al,[bdbid]
	mov	ah,dosx and (not ignorex)
	call	tomox24			; to moxcpcor
	jc	freecx			; fail specified
	jz	freec0			; retry specified
					; else ignore specified
	mov	ax,err24h		;   (which we don't allow)
	stc
	jmp	freecx

; free the lru uob

freec2:
        push	ds
        call	findbdbc
	call	cfree
        pop	ds
	clc				; no error (cfree might return c unknowingly)
freecx:
	pop	cx
	ret
freecache endp

	subttl	mapcache - middle-level map a uob
	page
;======================================================================
;,fs
; mapcache - middle-level map a uob
; 
; or status into uob
; if status indicates a write request,
;   set uob write owner as current tcb
; set first in usage list
; call cmap to map it in
; return segment from cmap
;
; status xor'ed w/ 06h 'cause this effectively produces a fat bit and
;   dir bit out of normal i/o status for int 24h, to better remember
;   what has been read/written
; we only remember the last writer, but it's only used to report
;   critical errors to the person most likely to be concerned
; the dl = status approach requires that dl be preserved from the
;   highest levels (rdsector, rdbf, wrbf) where it starts as a
;   parameter, to the lowest levels - this is inconvenient and you
;   have to keep it in mind, but it hasn't been a problem yet
; mapcache is used to map in a uob when it is to be used in the sense
;   the usage list is supposed to keep track of - it isn't used by
;   the flush code because flushing isn't usage that helps us keep
;   track of application activity
; 
; in:	es:di -> uob
;	dl = i/o status (fatx, dirx, datax, vrfflg, flshflg)
; 
; out:	es -> uob
;	ax, es destroyed, all others unchanged
; 
;,fe
;====================================================================^
	assume	ds:nothing,es:nothing,ss:nothing
mapcache proc near
	push	ds
	push	si
	push	bx

; or status into uob

	mov	al,dl			; translate data to 0, fat to 4, dir to 2
	xor	al,06h			; to or in cstatus to remember fat/dir reads
	test	al,wrx			; remember who this was if it were writing
	jz	mapc0
	call	markdirty
	cmp	es:[di].cerror,0
	jne	mapc0


;!!<
;	mov	es:[di].cownid,ss
	
	push	ax
	mov	al,byte ptr ss:[tcbid]
	mov	es:[di].cownid,al
	pop	ax
;!!>


	push	ds
	mgetscb2 ds
	assume	ds:grp
	mov	[scblastw1],ss
	pop	ds
	assume	ds:nothing
mapc0:
	or	es:[di].cstatus,al

; set to first in usage list

        mov	ax,ds			; remember bdb
	mgetscb2 ds
	assume	ds:grp
	mov	bx,[scbcupf]
	cmp	di,bx
	je	mapc1			; already first in list
	mov	[scbcupf],di
        mov	[scbcbdb],ax
	cmp	di,es:[bx].cuseprv
	je	mapc1			; used to be last, now is first

; delete it out of usage list

	mov	ax,bx			; remember old first
	mov	si,es:[di].cuseprv
	mov	bx,es:[di].cusenxt
	mov	es:[si].cusenxt,bx
	mov	es:[bx].cuseprv,si
	mov	bx,ax

; insert it following old first

	mov	si,es:[bx].cuseprv
	mov	es:[si].cusenxt,di
	mov	es:[bx].cuseprv,di
	mov	es:[di].cusenxt,bx
	mov	es:[di].cuseprv,si
mapc1:
	call	cmap
	pop	bx
	pop	si
	pop	ds
	assume	ds:bdb
	ret
mapcache endp

ddt	ends
	end

