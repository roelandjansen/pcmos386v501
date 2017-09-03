	include page.inc
	title	mosfun0f.asm - fcb-oriented file functions
; extrn	bugerror:near	; enable run-time debug error traps
comment ^===============================================================
		development specification

 program name:	$$mos.sys		assigned to: jim bean
 module name:	mosfun0f		assign date: 08/19/86
 entry points:	mosfunxx (see below)	completed: 09/22/86
 entry from:	mosint21
 entry method:	call
 calls:		mosfutil
 purpose:	fcb i/o functions
 last update:	08/18/1992
========================================================================

implementation comments

validating an fcb as open consists of getting a tfb segment from
  fcb+30, making sure it has a tfb id ('T' at offset 1), getting
  the gfb segment from the tfb, making sure it has a gfb id ('G' at
  offset 1), making sure fcb+24 (first cluster) = gfbcbof, fcb+26
  (dir entry sector offset) = gfbdofs, fcb+28 (dir entry sector) =
  gfbdloc - note that these last three items have no meaning for
  character devices, but they must be equal to whatever values are
  present in the gfb or the fcb isn't considered to be open

if the fcb looks open, but there is no gfb, an attempt will be made
  to re-open it in the (now) current directory.  if this attempt
  succeeds, then the fcb fields other than the tfb segment are
  checked.  if they match the re-opened file, then the fcb access
  succeeds transparently and invisibly, else it fails

valid open fcb also requires that drive byte - 1 = [bdbid] for
  [gfbbdb]

tfb's and GFB's aren't updated from information in FCB except for
  current position in file - in particular, the date, time and size
  are modified in the gfb when writing, and the fcb is updated from
  that.  if the application changes any system areas of the fcb
  including the date, time and size, we ignore it except that we
  may no longer be able to validate the fcb as open

multiple fcb open's of a file or device generate only one TFB
  with a tfbhdl of -1

delete, rename, create require that no other tcb:psp have the file
  open

file is originally opened for no access and read and/or write access
  is acquired only when and if necessary

=======================================================================

jsm 04/27/87	changed validfcb to capitalize when comparing file names 
		in the gfb to names in the fcb

rbr 05/03/87	optimization

jsm 05/05/87	made fcbread & fcbwrite return errors if no access to 
		file being read or written

jsm 07/21/87	temporarily enable access to all classes in 16 
		(create file) if file does not already exist.

jsm 08/11/87	changed findfcb so that it couldn't find labels	
		on aliased drives.

jsm 08/13/87	changed fcbwrite to set file size if 0 record write is 
		requested (fixes autocad).

mjs 9/4/87	found that mosfun14, 15, 27 and 28 were calling okswt 
		without ever having called noswt.

sjc 10/22/87	optimization

jsm 11/10/87	changed mosfun12 to fix problem with slow floppy disk i/o.

jrb 12/17/87	fill out dta correctly on fn 11 finding device

sah 01/20/88	change scbseg and zero seg access to mgetxxxx macros

sah\mjs 02/02/88 remove push and pop not remove above

jrb 02/04/88	don't release one handle's locks on a close on another
		handle

rbr/sah 02/20/88 move ddt code to mo2 group.

mjs 6/10/88	mosfun11 was calling noswt but not calling okswt.

mjs 11/16/88	corrections to mosfun16.  when findfcb returned cy, the
		clvl variable was not getting set.  modified findfcb
		to return the class level in cl when there was an error.
		modified mosfun16 to use cl for the class level when
		a filenf error is detected from findfcb so createguts
		will have the proper entry parameters.

sah 01/26/89	change lock equate to nlock (masm 5.10 compatibility)

sah 12/14/89	remove mosregs2.inc

mjs 04/30/90	correct setup of bx register for call to fcbopen within
		mosfun16.
		add test within mosfun17 to manage volume label = file
		name case.

mjs 07/30/90	mod fun17 to keep any gfb's syncronized for the file
		being renamed.  this helps mos accomodate skplus's slop.
		also, had to modify fcbopen to account for the case where
		skplus would open a file, then call create on the same
		file.

SAH 11/08/90	Corrections for WS 3.x with Function 17, corrupted register
	        corrected because of MJS's 07/30/90 fix

SAH 02/27/91	Correction for function 16 with opening to device, don't set
		sector buffer if device.
    02/28/91    Correction for FCBWRITE propertly not saying disk is full
		for devices

================ 5.01 Kernel Ends Here ====================================

SAH 04/15/92	Corrections for function 12h and LanLink Professional
		need to make sure that ah (use as attribute for searching)
		is zero out for the non-extended FCB cased.
		(Corrected in UPDAT501.SYS Version 0.03)

mjs 08/18/92	clean up segment declarations

=======================================================================^

.xlist
;	include mosfun0f.pub
	include group.inc
	include mosregs.inc
	include moscdb.inc
	include mosgfb.inc
	include mostfb.inc
	include mosrlb.inc
	include mosbdb.inc
	include macros.inc

tcb	segment at 1234h
	include mostcb.inc
tcb	ends

gdata	segment
	include mosscbex.inc
gdata	ends

.list

;======================================================== ddt segment
if 0 eq 0
segment_num = 2
endif
ddt	segment
	assume	cs:mo2,ds:grp,es:nothing,ss:tcb

	extrn	noswt:near, okswt:near
	extrn	alloclust:near, blkread:near, blkwrite:near, chkacc:near
	extrn	chklock:near, closefile:near, clrclust:near, create:near
	extrn	dealloc:near, delete:near, devchk:near, todriver:near
	extrn	emptydir:near, findgfb:near, findlbl:near
	extrn	findnm:near, findrlb:near, findtfb:near, flushdir:near
	extrn	getfat:near, getphdl:near
	extrn	moserror:near, nextnm:near, openfile:near
	extrn	putfat:near, rddir:near, slash:near
	extrn	timestamp:near, wrsector:near, setphdl:near, iolock:near
	extrn	devread:near, devwrite:near
	extrn	devicenm:near, finddrv:near, exclude:near, okchar:near
	extrn	classlvl:near, findbdb:near, capscmps:near
	extrn	cpycmap:near, eblcmap:near
	extrn	readguts:near, writeguts:near, truncguts:near, creatguts:near
	extrn	checkexon:near

	public	mosfun0f, mosfun10, mosfun11, mosfun12, mosfun13, mosfun14
	public	mosfun14, mosfun15, mosfun16, mosfun17, mosfun1a, mosfun21
	public	mosfun22, mosfun23, mosfun24, mosfun27, mosfun28, mosfun2f

if 0 eq 0				; trick public.com

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
shareov equ	36			; share buffer overflow (couldn't alloc RLB)
filexst equ	80			; file already exists
fail24h equ	83			; fail chosen from int 24h (as defined by dos)
syshdl	equ	127 or 8000h		; attempt to dup or fdup a non-psp handle
xshare	equ	share or 8000h		; fail from int 24h sharing
xlock	equ	nlock or 8000h		; fail from int 24h locking
err24h	equ	fail24h or 8000h	; fail error from int 24h (signal for moserror)
intern	equ	80ffh			; internal error

; directory entry fields

eofnone equ	1			; eof w/o partial record
diskfull equ	1			; disk full
dtaover equ	2			; dta segment overrun
eofpart equ	3			; eof w/ partial record
fcberr	equ	0ffh			; general error for fcb call

; directory entry fields

datr	equ	11			; offset of attribute byte
dclass0 equ	13			; offset of class byte
dtime	equ	22			; offset of time word
ddate	equ	24			; offset of date word
dsize	equ	28			; offset of size dword
dclust	equ	26			; offset of bof cluster word

; directory entry file attribute bits defined

override equ	80h			; override class access for dir search
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

	subttl mosfun0f - fcb file open
	page
;======================================================================
;,fs
; mosfun0f - fcb file open
;
; in:	tds:tdx -> fcb to open
;
; out:	tal = 0ffh on error
;	else tal = 00h
;
;,fe
;======================================================================
	assume	ds:grp,es:nothing,ss:tcb
lproc	mosfun0f
lstring secbuf,<size sectorblk>
	lea	bx,[secbuf]
	call	ustscl			; use task regs, call fcbatr and findfcb
	jc	mosf0fx
	assume	ds:bdb			; al = cumulative class level
	mov	es,[tds]
	mov	di,[tdx]
	xor	dx,dx			; attempting to open existing file
	call	fcbopen
mosf0fx:
	call	tstalerr
lundef	secbuf
lendp	mosfun0f

	subttl	mosfun10 - fcb file close
	page
;======================================================================
;,fs
; mosfun10 - fcb file close
;
; in:	tds:tdx -> opened fcb of file to close
;
; out:	tal = 0ffh on error
;	else tal = 00h
;
;,fe
;======================================================================
	assume	ds:grp,es:nothing,ss:tcb
lproc mosfun10
lstring secbuf,<size sectorblk>
	lea	bx,[secbuf]
	call	ustscv			;use task regs, call validfcb
	jc	mosf10x
	call	updatfcb
	mov	es,es:[di+30]
	assume	es:tfb
	call	closefile
	jc	mosf10x
	xor	al,al
mosf10x:
	call	tstalerr		;save and test error code in al
lundef	secbuf
lendp	mosfun10

	subttl	mosfun11 - fcb find first
	page
;======================================================================
;,fs
; mosfun11 - fcb find first
;
; in:	tds:tdx -> fcb to find
;
; out:	tal = 0ffh on error
;	else tal = 00h
;	 dta filled with matching dir entry
;
;,fe
;======================================================================
	assume	ds:grp,es:nothing,ss:tcb
lproc mosfun11
lstring secbuf,<size sectorblk>
	lea	bx,[secbuf]		; sector block to use for this call
	push	bx
	call	ustscl			; task reg setup, noswitch and fcb setup
	pop	bx
	jc	mosf11x 		; carry if error on findfcb
	call	xfrddta 		; transfer dir entry to dta
	jmp	mosf11y
mosf11x:
	call	seterr			; set tcb error code and al reg
mosf11y:
	call	okswt
lundef	secbuf
lendp	mosfun11

	subttl	mosfun12 - fcb find next
	page
;======================================================================
;,fs
; mosfun12 - fcb find next
;
; in:	tds:tdx -> fcb to find
;
; out:	tal = 0ffh on error
;	else tal = 00h
;	 dta filled with matching dir entry
;
;,fe
;======================================================================
	assume	ds:grp,es:nothing,ss:tcb
lproc mosfun12
lstring secbuf,<size sectorblk>
	lea	bx,[secbuf]
	call	ustsrg			; use task registers, no switch allowed
	mov	ss:[bx].secoper,0
	xor	ah,ah			; set normal attribute for
					; non-extended FCB's
	mov	al,es:[di]
	inc	al
	jnz	mosf12a 		; jmp if not an extended fcb
	mov	ah,es:[di+6]		; attribute
	add	di,7			; offset to fcb drive
	cmp	ah,es:[di+12]		; attribute must match search attribute
	jne	jmosf12x
mosf12a:
	mov	al,es:[di]		; drive must match search drive
	cmp	al,es:[di+19]
	je	mosf12b
	or	al,al			; unless it is the default
	jnz	jmosf12x
	mov	al,es:[di+19]
mosf12b:
	mov	ss:[bx].secoper,ah	; save search attribute
	dec	al
	call	finddrv
	jc	jmosf12y		; drive must be valid
	assume	ds:bdb
	mov	si,es:[di+13]
	test	si,32-1
	jnz	jmosf12x		; must indicate a dir entry boundary
	cmp	si,[bdbssiz]
	jae	jmosf12x		; < sector size
	mov	ax,es:[di+15]
	mov	dx,es:[di+17]		; then go ahead
	mov	ss:[bx].seclow,ax
	mov	ss:[bx].sechigh,dx	; set sector number for later
	or	dx,dx			; high word zero?
	ja	mosf12c1		; if > 0, not root dir
	cmp	ax,[bdbdir]
	jb	jmosf12x		; < root dir (maybe device)
	cmp	ax,[bdbclus]
	jb	mosf12c
mosf12c1:
	xor	cx,cx			; lots of zeroes will be useful
	sub	ax,[bdbclus]
	sbb	dx,cx
	mov	cl,[bdbcshl]
	jcxz	mosf12c3		; if sector size == cluster size
mosf12c2:
	shr	dx,1
	rcr	ax,1			; shift sector # right to make cluster
	loop	mosf12c2
mosf12c3:
	or	dx,dx
	jnz	jmosf12x
	cmp	ax,[bdbcnum]
	jb	mosf12c
jmosf12x:
	jmp	short mosf12x
mosf12c:
	mov	ah,ss:[bx].secoper	; search attribute in ah
	add	si,32
	call	nextfcb
	jnc	$+4
jmosf12y:
	jmp	short mosf12y
	call	xfrddta 		;xfr dir to dta
	jmp	mosf12z
mosf12x:
	mov	al,filenf
mosf12y:
	call	seterr			;set tcb error code
mosf12z:
	call	okswt
lundef	secbuf
lendp	mosfun12

	subttl	mosfun13 - fcb file delete
	page
;======================================================================
;,fs
; mosfun13 - fcb file delete
;
; in:	tds:tdx -> fcb to delete
;
; out:	tal = 0ffh on error
;	else tal = 00h
;
;,fe
;======================================================================
	assume	ds:grp,es:nothing,ss:tcb
lproc	mosfun13
lstring secbuf,<size sectorblk>
	lea	bx,[secbuf]
	call	ustsrg			; use task regs
	mov	[tal],fcberr
	call	fcbatr
	call	findfcb
	mov	es,cx			; dbb address
	xor	ch,ch			; nothing deleted yet
	jc	mosf13x
	assume	ds:bdb,es:dbb
	mov	cl,ah			; remember search attribute
	cmp	al,3
	mov	ax,accdeny		; must have cumulative read/write access to
	jc	mosf13x 		;   parent (current) dir
	or	bx,bx
	jz	mosf13x 		; can't delete devices
mosf13a:
	test	[dbbbuf+si+datr],dir
	jnz	mosf13c 		; can't delete directories
	mov	al,[dbbbuf+si+dclass0]
	call	classlvl
	cmp	al,3			; on to next if don't have read/write
	jc	mosf13c 		;   access to this class
	call	exclude
	jnc	mosf13b 		; c if can't get exclusive access
	cmp	ax,accdeny
	je	mosf13c
	jmp	mosf13x 		; some critical error on a close
mosf13b:
	call	delete
	jc	mosf13x
	mov	ch,0ffh 		; flag that something was deleted
mosf13c:
	mov	ah,cl
	mov	es,[tds]
	push	cx
	add	si,32
	call	nextfcb
	mov	es,cx
	pop	cx
	assume	es:dbb
	jnc	mosf13a
	cmp	ax,filenf
	jne	mosf13x
	xor	al,al
mosf13x:
	mov	[tcberrcod],al
	or	ch,ch
	jz	mosf13y 		; nothing to flush if nothing was deleted
	cmp	al,fail24h
	je	mosf13y 		; don't bother repeating a critical error
	call	flushdir
	jnc	mosf13y
	cmp	[tcberrcod],0
	jne	mosf13y 		; ne if there was another error
	mov	[tcberrcod],al		;   else report this error
mosf13y:
	mov	[tal],fcberr
	mov	al,[tcberrcod]
	or	al,al
	jnz	mosf13z
	mov	[tcberrcod],filenf	; file not found if no other error, but
	or	ch,ch			; nothing deleted
	jz	mosf13z
	call	zerrcod 		; everything ok
mosf13z:
	call	okswt
lundef	secbuf
lendp	mosfun13

	subttl	mosfun14 - fcb sequential read
	page
;======================================================================
;,fs
; mosfun14 - fcb sequential read
;
; in:	tds:tdx -> opened fcb of file to read
;
; out:	tal = 0 no error and record in dta
;	      1 eof and none in dta
;	      2 dta segment overrun
;	      3 eof and some in dta area
;
;,fe
;======================================================================
	assume	ds:grp,es:nothing,ss:tcb
lproc	mosfun14
lstring secbuf,<size sectorblk>
	lea	bx,[secbuf]
	call	ustscv			; task regs, no switch and validfcb
	mov	ah,eofnone
	jc	mosf14x
	mov	cx,1			; one record
	call	setupfcb		; setup fcb for r/w
	call	fcbread
	call	aftset			; after setup, update fcb
mosf14x:
	call	stercd			; set error code (tcb and task), switching ok
lundef	secbuf
lendp	mosfun14

	subttl	mosfun15 - fcb sequential write
	page
;======================================================================
;,fs
; mosfun15 - fcb sequential write
;
; in:	tds:tdx -> opened fcb of file to write
;
; out:	tal = 0 no error, dta record written to file
;	      1 disk full
;	      2 dta segment overrun
;
;,fe
;======================================================================
	assume	ds:grp,es:nothing,ss:tcb
lproc	mosfun15
lstring secbuf,<size sectorblk>
	lea	bx,[secbuf]
	call	ustscv			; use task regs, no switch, call validfcb
	mov	ah,diskfull
	jc	mosf15x
	mov	cx,1			; one record
	call	setupfcb
	call	fcbwrite
	call	aftset
mosf15x:
	call	stercd
lundef	secbuf
lendp	mosfun15

	subttl	mosfun16 - fcb file create
	page
;======================================================================
;,fs
; mosfun16 - fcb file create
;
; in:	tds:tdx -> fcb to create
;
; out:	tal = 0ffh on error
;	else tal = 00h
;
;,fe
;======================================================================
	assume	ds:grp,es:nothing,ss:tcb
lproc	mosfun16
ldword	fcbptr
lbyte	clvl
lstring secbuf,<size sectorblk>
lstring clsmap,<size tcbcmap>		; copy of class map for task
	lea	si,[tcbcmap]		; copy tcbcmap -> clsmap
	lea	di,[clsmap]		; save original class access map
	call	cpycmap
	mov	bx,bp			; save bp reg temporarily
	call	ustsrg			; use task regs, no switching allowed
	mov	bp,bx
	mov	word ptr [fcbptr],di
	mov	word ptr [fcbptr+2],es
	call	fcbatr
	or	ah,override		; set override bit to prevent exclusion test
	lea	bx,[secbuf]
	call	findfcb
	assume	ds:bdb
	jc	mosf16a 		; error or name not in directory
	and	ah,not override 	; clear override to prevent confusion later
	or	bx,bx
	jmpz	mosf16b 		; name refers to a device (cx = drvr seg)
	mov	[clvl],al
	mov	al,ah
	and	al,not ( arch or dir or lbl or sys or hid or ro )
	mov	al,accdeny
	jmpnz	mosf16x 		; fail if any invalid attribute bit set
	push	cx			; save attribute
	mov	cx,11
	inc	di
	mov	al,'?'
	repne scasb			; wild-cards not allowed
	pop	es			; segment address of bdb
	mov	al,accdeny
	jmpe	mosf16x
	assume	es:dbb
	mov	cl,ah			; attribute for file
	mov	ah,[clvl]
	call	truncguts		; else truncate the existing dir entry
	jc	mosf16x
	jmp	short mosf16b

; no dir entry with that name, create a new one with supplied attrib

mosf16a:
	cmp	ax,filenf
	jmpne	mosf16x 		; some error other than not found
	mov	[clvl],cl		; class level in cl when filenf is in ax
	mov	di,word ptr [fcbptr]	; get attr from extended fcb if any
	xor	ah,ah
	cmp	byte ptr es:[di],0ffh
	jne	mosf16a1
	add	di,7
	mov	ah,es:[di-1]
mosf16a1:
	mov	cl,ah
	and	ah,not ( arch or dir or lbl or sys or hid or ro )
	mov	ax,accdeny
	jnz	mosf16x 		; fail if any invalid attribute bit set
	inc	di
	mov	ah,[clvl]
	lea	bx,[secbuf]
	call	creatguts
	jc	mosf16x
	call	eblcmap 		; enable access to all classes for create
mosf16b:

; open file and return handle

	mov	al,[clvl]
	les	di,[fcbptr]
	or	bx,bx
	jz	skipbuf16
	lea	bx,[secbuf]		; set buffer location if not device
skipbuf16:
	mov	dx,1			; creating new file
	call	fcbopen
	pushf
	push	si
	push	di
	lea	si,[clsmap]		;restore original class access map
	lea	di,[tcbcmap]		;copy clsmap -> tcbcmap
	call	cpycmap
	pop	di
	pop	si
	popf
	jc	mosf16x
	mov	es,es:[di+30]
	assume	es:tfb
	mov	ds,[tfbgfb]
	assume	ds:gfb
	xor	ax,ax			; no error
	cmp	[gfbdev],0
	jne	mosf16x
	mov	[gfbwrtn],'Y'
	or	[tfbioctl],40h		; signal file has been written (if not device)
mosf16x:
	mov	bx,bp
	mov	bp,[bp]
	mov	[tcberrcod],al
	mov	[tal],al
	or	al,al
	jz	mosf16y
	mov	[tal],fcberr
mosf16y:
	mov	bp,bx
	call	okswt			; safe to allow a task switch
lundef	clvl
lundef	fcbptr
lundef	secbuf
lundef	clsmap				; copy of class map for task
lendp	mosfun16

	subttl	mosfun17 - fcb file rename
	page
;======================================================================
;,fs
; mosfun17 - fcb file rename
;
; in:	tds:tdx -> fcb to rename
;
; out:	tal = 0ffh on error
;	else tal = 00h
;
;,fe
;======================================================================
	assume	ds:grp,es:nothing,ss:tcb
lproc	mosfun17
lbyte	renamed
lbyte	attrib
lword	pclust
lword	dofs
ldword	dsct
ldword	fcbptr
lword	bdbseg
lstring fcb,11
lstring secbuf,<size sectorblk>
	mov	bx,bp
	call	ustsrg			; use task regs, no switching
	mov	bp,bx
	mov	[renamed],0		; nothing renamed yet
	mov	word ptr [fcbptr+2],es
	call	fcbatr
	lea	bx,[secbuf]
	call	findfcb
	mov	es,cx
	mov	[tcberrcod],al
	jc	jmosf17y
	assume	ds:bdb,es:dbb
	mov	word ptr [pclust],dx	; parent dir start cluster
	mov	word ptr [fcbptr],di	; -> drive byte of fcb
	mov	[attrib],ah		; attribute searched
	mov	[bdbseg],ds		; bdb for drive
	mov	[tcberrcod],filenf
	or	bx,bx
	jz	jmosf17y		; can't rename device
	mov	[tcberrcod],accdeny
	cmp	al,3			; can't rename without cumulative
	jnc	mosf17a
jmosf17y:
	jmp	mosf17y 		;   read/write access

; for each matching directory entry (not a system file, hidden file
;   or subdirectory)

mosf17a:
	mov	[dofs],si		; dir entry offset
	push	ax
	mov	ax,[secbuf].seclow	; dir entry sector
	mov	word ptr [dsct],ax
	mov	ax,[secbuf].sechigh
	mov	word ptr [dsct+2],ax
	pop	ax
	test	[dbbbuf+si+datr],(hid or dir)
	jnz	jmosf17d		; can't rename system, hidden or subdir files

; make sure we can acquire exclusive access to the file

	mov	al,[dbbbuf+si+dclass0]
	call	classlvl
	cmp	al,3			; go on to next if don't have read/write
	jc	jmosf17d		;   access to this file's class
	call	exclude
	jnc	mosf17a1
	cmp	ax,accdeny
	jne	jmosf17x
jmosf17d:
	jmp	mosf17d
jmosf17x:
	jmp	mosf17x 		; some critical error on a close
mosf17a1:
	call	rddir
	jc	jmosf17x
	push	es
	pop	ds
	assume	ds:dbb
	push	ss
	pop	es
	assume	es:tcb
	lea	si,[dbbbuf+si]		; move dir entry to temp storage
	lea	di,[fcb]
	mov	cx,11
	rep	movsb
	lds	si,[fcbptr]
	lea	si,[si+17]		; -> target name
	mov	cx,11
	lea	di,[fcb]
mosf17b:
	lodsb
	call	okchar			; validate char and capitalize it
	mov	[tcberrcod],pathnf	; path not found extended error if invalid
	jc	jmosf17y		; c if invalid char in dir entry
	cmp	al,'?'
	jne	mosf17c
	mov	al,es:[di]		; leave wild-cards the same as the dir entry
mosf17c:
	stosb
	loop	mosf17b

; see if there's already a file with the target name

	mov	ds,[bdbseg]
	assume	ds:bdb
	mov	dx,[pclust]
	lea	di,[fcb]
	call	findnm
	jc	mosf17c2		; cy if none found
	or	bx,bx
	jz	mosf17c1		; fail if device driver
mosf17c0:
	assume	es:dbb
	test	[dbbbuf+si+datr],lbl
	jz	mosf17c1		; fail if not label

; when find a match with a volume label, must check further

	mov	di,ss
	mov	es,di
	assume	es:tcb
	lea	di,[fcb]
	add	si,32
	call	nextnm
	jc	mosf17c2		; cy if no more found
	jmp	short mosf17c0		; else, recheck for label
mosf17c1:
	mov	[tcberrcod],accdeny	; second file name exists
	jnc	jmosf17x
mosf17c2:
	mov	[tcberrcod],al
	cmp	ax,filenf
	jne	jmosf17x

; copy the new name to the dir entry if not

	mov	si,word ptr [dsct]
	mov	[secbuf].seclow,si
	mov	si,word ptr [dsct+2]
	mov	[secbuf].sechigh,si
	mov	si,[dofs]
	call	rddir			; re-read the dir entry
	mov	[tcberrcod],al
	jc	mosf17x

; if can find a gfb for the file whose directory name
; is just about to be updated, update the gfbname also.
; this helps accomodate sloppy programming done by skplus 1.01c

	push	ds
	push	es
	mov	si,[dofs]
	call	findgfb
	jc	mosf17da
	assume	es:gfb
	mov	di,ss
	mov	ds,di
	assume	ds:tcb
	mov	di,offset gfbname
	push	si
	lea	si,[fcb]
	mov	cx,11
	rep	movsb
	pop	si
mosf17da:
	pop	es
	assume	es:dbb
	pop	ds
	assume	ds:bdb
	mov	di,ss
	mov	ds,di
	assume	ds:tcb
	lea	di,[dbbbuf+si]		; copy the new name to it
	lea	si,[fcb]
	mov	cx,11
	rep	movsb
	mov	ds,[bdbseg]
	assume	ds:bdb
	call	wrsector		; and flag sector as modified
	mov	[tcberrcod],al
	jc	mosf17x
	mov	[renamed],0ffh		; now something has been renamed

; then get the next matching source dir entry

mosf17d:
	les	di,[fcbptr]
	mov	ds,[bdbseg]
	mov	si,word ptr [dsct]
	mov	[secbuf].seclow,si
	mov	si,word ptr [dsct+2]
	mov	[secbuf].sechigh,si
	mov	si,[dofs]
	mov	ah,[attrib]
	add	si,32
	call	nextfcb 		; next matching dir entry
	mov	es,cx
	assume	es:dbb
	jmpnc	mosf17a
	mov	[tcberrcod],al
	cmp	ax,filenf
	jne	mosf17x
	call	flushdir
	mov	[tcberrcod],al
	jc	mosf17y
	mov	[tcberrcod],0
	jmp	short mosf17y
mosf17x:				; error, but some dir sectors may need to
	cmp	[tcberrcod],fail24h
	je	mosf17y
	call	flushdir		;   be flushed
mosf17y:
	call	okswt
	mov	al,fcberr
	cmp	[tcberrcod],0
	jne	mosf17z 		; return error if any extended error
	mov	[tcberrcod],filenf
	cmp	[renamed],0
	je	mosf17z 		; or if nothing was renamed
	xor	al,al
	mov	[tcberrcod],al		; else no error
mosf17z:
	mov	bx,bp
	mov	bp,[bp]
	mov	[tal],al
	mov	bp,bx
lundef	renamed
lundef	attrib
lundef	pclust
lundef	dofs
lundef	dsct
lundef	fcbptr
lundef	bdbseg
lundef	fcb,11
lundef	secbuf
lendp	mosfun17

	subttl	mosfun1a - set dta
	page
;======================================================================
;,fs
; mosfun1a - set dta
;
; in:	tds:tdx -> dta to set
;
; out:
;
;,fe
;======================================================================
	assume	ds:grp,es:nothing,ss:tcb
mosfun1a:
	mov	ax,[tdx]
	mov	word ptr [tcbdta],ax
	mov	ax,[tds]
	mov	word ptr [tcbdta+2],ax
	ret

	subttl	mosfun21 - fcb random read
	page
;======================================================================
;,fs
; mosfun21 - fcb random read
;
; in:	tds:tdx -> opened fcb of file to read
;
; out:	al = 00h no error, dta filled with read record
;	     01h eof, dta empty
;	     02h dta segment overrun
;	     03h eof, dta has partial record
;
;,fe
;======================================================================
	assume	ds:grp,es:nothing,ss:tcb
lproc	mosfun21
lstring secbuf,<size sectorblk>
	lea	bx,[secbuf]
	call	ustscv			; use task regs, no switch, call validfcb
	mov	ah,eofnone
	jc	mosf21x
	mov	cx,1			; one record
	call	stfcb0			; setup regs for fcb r/w function
	call	fcbread
	call	updaft			; update current rec ptr, fcb fields from gfb
mosf21x:
	call	stercd			; set error code and allow switching
lundef	secbuf
lendp	mosfun21

	subttl	mosfun22 - fcb random write
	page
;======================================================================
;,fs
; mosfun22 - fcb random write
;
; in:	tds:tdx -> opened fcb of file to write
;
; out:	al = 00h no error, dta record written to file
;	     01h disk full
;	     02h dta segment overrun
;
;,fe
;======================================================================
	assume	ds:grp,es:nothing,ss:tcb
lproc	mosfun22
lstring secbuf,<size sectorblk>
	lea	bx,[secbuf]
	call	ustscv
	mov	ah,diskfull
	jc	mosf22x
	mov	cx,1			; one record
	call	stfcb0			; setup regs for record write
	call	fcbwrite
	call	updaft			; update after function
mosf22x:
	call	stercd			; set error code and allow switching
lundef	secbuf
lendp	mosfun22

	subttl	mosfun23 - fcb file size
	page
;======================================================================
;,fs
; mosfun23 - fcb file size
;
; in:	tds:tdx -> unopened fcb of file to get size
;
; out:	al = 0ffh on error
;	else al = 00h
;
;,fe
;======================================================================
	assume	ds:grp,es:nothing,ss:tcb
lproc	mosfun23
lstring secbuf,<size sectorblk>
	lea	bx,[secbuf]
	call	ustscl			; use task regs, no switching, fcbatr, findfcb
	mov	es,cx			; segment from nextfcb
	jc	mosf23x
	assume	ds:bdb,es:dbb
	mov	ax,filenf
	or	bx,bx
	jz	mosf23x 		; also not found if device
	mov	ax,word ptr [dbbbuf+si+dsize]  ; byte size of file
	mov	dx,word ptr [dbbbuf+si+dsize+2]
	mov	es,[tds]		; segment of fcb
	mov	cx,es:[di+14]		; record length
	or	cx,cx
	jnz	mosf23b
	mov	cx,128			; record length 128 if 0
mosf23b:
	dec	cx			; count fractional record as full record
	add	ax,cx
	adc	dx,0
	inc	cx

; dx:ax div cx is what we're looking for, but the result may be up to
;   a dword long so the div instruction isn't good enough
;
; dx:ax div cx = int( ( dx * 64k ) / cx + ax / cx )
;   = int( ( dx / cx ) * 64k + ax / cx )
;   = int( ( dx div cx ) * 64k + ( ( dx mod cx ) * 64k ) / cx +
;	ax div cx + ( ax mod cx ) / cx )
;   = ( dx div cx ) * 64k + ( ax div cx ) +
;	int( ( ( dx mod cx ) * 64k + ( ax mod cx ) ) / cx )
;   = ( dx div cx ) * 64k + ( ax div cx ) +
;	( ( dx mod cx ) * 64k + ( ax mod cx ) ) div cx
;
; note that the second and third terms are both < 64k, so the sum
;   is < 64k + carry

	mov	si,dx
	xor	dx,dx
	div	cx			; computing ax = ax div cx & dx = ax mod cx
	xchg	si,ax			; si = ax div cx
	mov	bx,dx			; bx = ax mod cx
	xor	dx,dx
	div	cx			; computing ax = dx div cx & dx = dx mod cx
	xchg	bx,ax			; bx = dx div cx, ax = ax mod cx
	div	cx			; computing (dx mod cx)*64k+(ax mod cx) div cx
	add	ax,si			; + ax div cx
	adc	bx,0			; + ( bx div cx ) * 64k
	mov	word ptr es:[di+33],ax
	mov	word ptr es:[di+35],bx
	call	zerrcod 		; zero out error code and task return reg
	jmp	short mosf23y
mosf23x:
	call	seterr			;set error codes
mosf23y:
	call	okswt
lundef	secbuf
lendp	mosfun23

	subttl	mosfun24 - fcb set random record
	page
;======================================================================
;,fs
; mosfun24 - fcb set random record
;
; in:	tds:tdx -> opened fcb of file to set random record
;
; out:
;
;,fe
;======================================================================
	assume	ds:grp,es:nothing,ss:tcb
mosfun24:
	mov	si,[tdx]
	mov	ds,[tds]
	mov	al,[si+32]
	mov	ah,[si+12]
	mov	dl,[si+13]
	xor	dh,dh
	shl	al,1
	shr	dx,1
	rcr	ax,1
	mov	word ptr [si+33],ax
	mov	word ptr [si+35],dx
	call	zerrcod 		; zero out error codes
	ret

	subttl	mosfun27 - random block read
	page
;======================================================================
;,fs
; mosfun27 - random block read
;
; in:	tds:tdx -> opened fcb of file to read
;	tcx = number of records to read
;
; out:	al = 00h no error, dta filled with tcx records
;	     01h eof, dta filled with tcx records
;	     02h dma segment overrun, dta filled with tcx records
;	     03h eof, partial record, dta filled with tcx-1 record and
;	         one partial record
;
;,fe
;======================================================================
	assume	ds:grp,es:nothing,ss:tcb
lproc	mosfun27
lstring secbuf,<size sectorblk>
	lea	bx,[secbuf]
	call	ustscv			; no switch, use task regs, validfcb
	mov	ah,eofnone
	jc	mosf27x
	mov	cx,[tcx]		; number of records
	call	stfcb0			; setup for read
	call	fcbread
	call	updaf0			; update after func.
mosf27x:
	call	stercd
lundef	secbuf
lendp	mosfun27

	subttl	mosfun28 - fcb random block write
	page
;======================================================================
;,fs
; mosfun28 - fcb random block write
;
; if tcx = 0, set the file size to the current random record 
; field length
;
; in:	tds:tdx -> opened fcb of file to write
;	tcx = number of records to write
;
; out:	al = 00h no error, tcx records written from dta
;	     01h disk full, tcx records written from dta
;	     02h dta segment overrun, tcx records written from dta
;
;,fe
;======================================================================
	assume	ds:grp,es:nothing,ss:tcb
lproc	mosfun28
lstring secbuf,<size sectorblk>
	lea	bx,[secbuf]
	call	ustscv			;use task regs, no switch, validfcb
	mov	ah,diskfull
	jc	mosf28x
	mov	cx,[tcx]		; number of records
	call	stfcb0
	call	fcbwrite
	call	updaf0
mosf28x:
	call	stercd
lundef	secbuf
lendp	mosfun28

	subttl	mosfun2f - get dta address
	page
;======================================================================
;,fs
; mosfun2f - get dta address
;
; input:
;
; out:	tes:tbx -> dta address
;
;,fe
;======================================================================
	assume	ds:grp,es:nothing,ss:tcb
mosfun2f:
	mov	ax,word ptr [tcbdta]
	mov	[tbx],ax
	mov	ax,word ptr [tcbdta+2]
	mov	[tes],ax
	ret

	subttl	findfcb - find device or dir entry for an unopened fcb
	page
;======================================================================
;,fs
; findfcb - find device or dir entry for an unopened fcb
;
; in:	ss:bx -> buffer for sector number
;	es:di -> fcb (possibly extended)
;	ah = attribute
;
; out:	c if error
;   	  ax = pathnf if invalid drive
;   		   filenf if no device or dir entry
;   	  cl = cumulative class access level - only meaningful for filenf
;   	  ds, bx, es, si, di undefined
;   	nc if no error
;   	  ds -> bdb
;   	  bx = 0 if device
;   		cx:si -> device driver header
;   	  ah = attribute for search
;   	  al = cumulative class access level
;   	  ss:bx -> sector number of dir entry if file
;   		si = ofs in sector of dir entry
;   		cx = dbb containing sector
;   	  es:di -> fcb drive field
;   	  dx = start cluster of parent directory
;
;,fe
;======================================================================
	assume	ds:grp,es:nothing,ss:tcb
fcbatr:
	xor	ah,ah
	mov	al,es:[di]
	inc	al
	jnz	findf1
	mov	ah,es:[di+6]		; extended fcb, so pick up supplied attribute
	add	di,7			;   and point to start of rest of fcb
findf1:
	ret
lproc	findfcb

lbyte	clvl
	mov	cl,ah
	push	di
	mov	al,es:[di]
	dec	al
	jns	findf2
	mov	al,[tcbcdriv]
findf2:
	push	cx			; save since otherwise is crashed w/ cdb ptr
	call	finddrv
	mov	ax,es
	mov	es,cx
	assume	es:cdb
	mov	cl,[cdblvl]		; cumulative access level to current dir
	mov	[clvl],cl
	pop	cx
	mov	es,ax
	mov	ax,pathnf
	jc	findfx
	assume	ds:bdb
	inc	di			; -> name part of fcb
	push	es
	call	devicenm
	mov	ah,cl			; remember search attribute
	mov	cx,es
	pop	es
	jc	findf2a 		; c if no device found with that name
	xor	bx,bx			; device found if bx = 0
	jmp	short findfx
findf2a:
	dec	di			; -> back to drive part of fcb
	mov	si,[bdbdir]
	mov	ss:[bx].seclow,si	; assume root directory
	mov	ss:[bx].sechigh,0
	mov	cl,ah			; search attribute back to cl
	cmp	ah,lbl
	je	findf2d
	or	dx,dx
	jz	findf3
	mov	si,dx			; find subdirectory sector from cluster
	sub	si,2
	xor	cx,cx
	mov	cl,[bdbcshl]
	jcxz	findf2c
findf2b:
	shl	si,1
	rcl	ss:[bx].sechigh,1
	loop	findf2b
findf2c:
	add	si,[bdbclus]
	adc	ss:[bx].sechigh,cx	; cx is zero
	mov	ss:[bx].seclow,si
	jmp	short findf3
findf2d:
	cmp	[bdbalias],0		; alias drives can't have labels
	je	findf3			; if it's not an alias drive
	stc
	mov	ax,filenf
	jmp	short findfx		; no label for you!
findf3:
	xor	si,si
	call	nextfcb
	jc	findfx
	mov	al,[clvl]
findfx:
	jnc	findfz			; return class level in bl for filenf case
	mov	cl,[clvl]
findfz:
	pop	di

lundef	clvl

lendp	findfcb

	subttl	nextfcb - find next dir entry for fcb
	page
;======================================================================
;,fs
; nextfcb - find next dir entry for fcb
;
; in:	ds -> bdb
;	es:di -> fcb drive field
;	ah = attribute for search
;	ss:bx -> dir sector of last found dir entry
;	si = offset to start looking (last found + 32)
;
; out:	c if error
;   	  ax = pathnf if invalid drive
;   		   filenf if no device or dir entry
;   	  ds, bx, es, si, cx, di undefined
;   	nc if no error
;   	  ds -> bdb
;   	  ah = attribute for search
;   	  ss:bx -> sector number of dir entry if file
;   	  si = ofs in sector of dir entry
;   	  cx = dbb containing sector
;   	  es:di -> fcb drive field
;
;,fe
;======================================================================
	assume	ds:bdb,es:nothing,ss:tcb
lproc	nextfcb
lword	fcbseg
	push	di
	mov	[fcbseg],es
	mov	cl,ah
nextf1:
	inc	di			; -> name part of fcb
	call	nextnm
	jc	nextfx
	assume	es:dbb
	dec	di			; -> fcb drive byte
	mov	ah,cl			; returning search attribute if there's a hit
	mov	ch,cl
	and	ch,(hid or dir or lbl)
	mov	al,[dbbbuf+si+datr]
	and	al,(hid or dir or lbl)
	cmp	ch,lbl
	jne	nextf2
	test	al,lbl
	jnz	nextfy
	jmp	nextf3
nextf2:
	and	ch,al
	cmp	ch,al
	jne	nextf3
	test	cl,override		; see if dir entry is accessible
	jnz	nextfy			; nz for access override
	push	si
	push	ds
	push	es
	pop	ds
	lea	si,[dbbbuf+si]
	call	checkexon		; check the +only/+except list
	pop	ds
	pop	si
	jc	nextf3
	mov	al,[dbbbuf+si+dclass0]
	call	classlvl
	or	al,al
	jnz	nextfy			; z if not accessible to this tcb
nextf3:
	mov	es,[fcbseg]
	add	si,32
	jmp	nextf1
nextfx:
	stc
nextfy:
	mov	cx,es
	mov	es,[fcbseg]
	pop	di
lundef	fcbseg
lendp	nextfcb

	subttl	validfcb - make sure fcb is a valid, opened fcb
	page
;======================================================================
;,fs
; validfcb - make sure fcb is a valid, opened fcb
;
; drive must be the same as the gfbbdb
; fcb+30:0 must be a valid tfb
; [tfbgfb] must be a valid gfb
; bdb address, starting cluster and dir entry loc must match gfb
;
; in:	es:di -> fcb
;	ss:bx -> buffer for sector number
;
; out:	c if error
;   	  ax = invhdl (file not open)
;   	nc if no error
;   	  es:di -> drive field of fcb
;   	  ax, bx, cx, dx, si, ds changed
;
;,fe
;======================================================================
;-----------------------------------------------------------------------
	assume	ds:grp,es:nothing,ss:tcb
lproc	validfcb
lbyte	clvl
	mov	dx,di
	mov	al,es:[di]
	inc	al
	jnz	validf0
	add	di,7
validf0:
	mov	ds,es:[di+30]
	assume	ds:tfb
	cmp	byte ptr ds:[1],'F'
	jne	jvalidf2
	cmp	[tfbhdl],-1
	jne	jvalidf2		; not an fcb tfb
	mov	ds,[tfbgfb]
	assume	ds:gfb
	cmp	byte ptr ds:[1],'G'
	jne	jvalidf2
	cmp	[gfbdev],0
	je	validf1

; validating a device fcb

	test	byte ptr es:[di+28+1],80h
	jz	jvalidf2		; must have a device attribute in fcb
	lds	si,dword ptr es:[di+24]
	mov	ax,[si+4]
	cmp	ax,es:[di+28]
	jne	jvalidf2
	lea	si,[si+10]
	mov	ax,di
	inc	di
	mov	cx,8
	push	ax
	call	capscmps		; compare names & ignore case
	pop	ax
	mov	di,ax
	jne	jvalidf2		; driver name must = fcb name
	jmp	validfz 		; device fcb all right

; validate a file fcb

validf1:				; validating a file fcb
	test	byte ptr es:[di+28+1],80h
	jz	$+4			; offset in dir entry < 8000h
jvalidf2:
	jmp	short validf2

	mov	cl,es:[di]
	or	cl,cl			; default drive?
	jnz	vf1skip
	mov	cl,[tcbcdriv]		; get default drive
	inc	cl
vf1skip:
	dec	cl			; drive unit
	add	di,24
	mov	ax,[gfbcbof]
	scasw				; 24
	jne	validf2
	mov	ax,[gfbdloc]
	scasw				; 26
	jne	validf2
	mov	ax,[gfbdofs]
	scasw				; 28
	jne	validf2
	push	[gfbbdb]		; address of gfb's bdb
	mov	al,cl			; drive number
	push	cx
	push	dx
	call	findbdb 		; find the bdb for that drive
	pop	dx
	pop	cx
	assume	ds:bdb
	mov	ds,[bdbreal]
	mov	cl,[bdbid]		; id of real drive for alias
	pop	ds			; bdb of gdb
	cmp	cl,[bdbid]		; id of gfb drive
	jne	validf2 		; if different bdb's, file fcb, but reopen
	mov	ds,es:[di]		; 30
	assume	ds:tfb
	sub	di,30
	mov	ds,[tfbgfb]
	assume	ds:gfb
	lea	si,[gfbname]
	mov	cx,11
	mov	ax,di
	inc	di
	push	ax
	call	capscmps		; compare names & ignore case
	pop	ax
	mov	di,ax
	jmpe	validfz 		; file fcb all right

; else have to re-open the fcb (application must be ill-behaved)

validf2:
	mov	di,dx
	push	dx
	call	fcbatr
	call	findfcb 		; note that disk media check is performed
	pop	dx
	jc	validfz
	or	bx,bx
	jz	validf3 		; z if device

; matching entry is file, check against fcb system fields

	mov	[clvl],al
	test	word ptr es:[di+28],8000h
	jnz	validfx 		; nz if fcb for a device
	push	ax
	mov	ax,es:[di+26]
	cmp	ax,ss:[bx].seclow
	pop	ax
	jne	validfx 		; dir sector different
	cmp	si,es:[di+28]
	jne	validfx 		; dir offset different
	mov	ax,es:[di+24]
	push	es
	mov	es,cx
	assume	es:dbb
	cmp	ax,word ptr es:[dbbbuf+si+dclust]
	pop	es
	assume	es:nothing
	jne	validfx 		; first cluster different
	jmp	validf4 		; else we believe it's the same one

; matching entry is device, check against fcb system fields

validf3:
	test	word ptr es:[di+28],8000h
	jz	validfx 		; z if fcb not for a device
	cmp	cx,word ptr es:[di+26]	; check fcb driver pointer against
	jne	validfx 		; found device
	cmp	si,word ptr es:[di+24]
	jne	validfx
	mov	ax,es:[di+28]
	push	es
	mov	es,cx
	cmp	ax,es:[si+4]
	pop	es
	jne	validfx 		; attributes don't match

; ok to re-open

validf4:
	mov	al,[clvl]		; (only initialized if it's a file fcb)
	push	word ptr es:[di+14]	; save record length
	push	word ptr es:[di+12]	; save current block
	mov	di,dx
	push	dx
	xor	dx,dx			; attempting to open existing file
	call	fcbopen
	pop	dx
	pop	bx
	pop	cx
	jc	validfz
	mov	es:[di+12],bx		; restore current block
	mov	es:[di+14],cx		; restore record length
	jmp	validfz
validfx:
	mov	ax,invhdl
	stc
validfz:
lundef	clvl
lendp	validfcb

	subttl	updatfcb - update fcb from gfb entry
	page
;======================================================================
;,fs
; updatfcb - update fcb from gfb entry
;
; in:	es:di -> fcb at drive part
;
; out:	fcb updated
;
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:tcb
updatfcb:
	push	ds
	mov	ds,es:[di+30]
	assume	ds:tfb
	mov	ds,[tfbgfb]
	assume	ds:gfb
	add	di,14
	mov	ax,es:[di]		; make sure record length is defined
	or	ax,ax
	jnz	updat1
	mov	ax,128
updat1:
	stosw				; 14
	mov	ax,word ptr [gfbsize]
	stosw				; 16
	mov	ax,word ptr [gfbsize+2]
	stosw				; 18
	mov	ax,[gfbdate]
	stosw				; 20
	mov	ax,[gfbtime]
	stosw				; 22
	cmp	[gfbdev],0		; is this a file or device?
	jnz	updat2			; if a device
	mov	ax,[gfbcbof]		; first cluster (in case file started empty)
	stosw				; 24
	sub	di,26			; back to drive byte
	jmp	short updat3
updat2:
	lea	si,[gfbdrvr]		; restore driver id
	movsw				; 24
	movsw				; 26
	sub	di,28			; back to drive byte
updat3:
	pop	ds
	ret

	subttl	updatcr - update current record ptr from random record ptr
	page
;======================================================================
;,fs
; updatcr - update current record ptr from random record ptr
;
; in:	es:di -> fcb at drive part
;
; out:	fcb updated
;
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:tcb
updatcr:
	mov	ax,es:[di+33]
	mov	dx,es:[di+35]
	add	ax,ax
	adc	dx,dx
	shr	al,1
	mov	es:[di+32],al
	mov	es:[di+12],ah
	mov	es:[di+13],dl
	ret

	subttl	fcbread - read sequentially from an fcb file or device
	page
;======================================================================
;,fs
; fcbread - read sequentially from an fcb file or device
;
; in:	es = tfb
;	cx = number of records to read
;	bx = length of each record
;	dx:ax = record position to start read
;
; out:	cx = number of records read
;	ah = 0 if no error, else fcb error code
;	al = 0 if no extended error, else extended error code
;	ah, bx, dx, si, di, ds, es undefined
;
;,fe
;======================================================================
	assume	ds:nothing,es:tfb,ss:tcb
fcbread:
	push	es
	push	bx
	mov	di,2			; read and write access required
	cmp	[tfbacc],1
	je	fcbrd1			; if already have write access
	xor	di,di			; read access required
	cmp	[tfbacc],3
	jne	fcbrd2			; if don't have any access
fcbrd1:

; currently don't have read access to the file

	call	ckaccd			; check access via chkacc
	jc	fcbrdx			; if no read access exit, else
	call	stfbac			; set tfb access
fcbrd2:
	call	xformr			; transform records to bytes
	jcxz	fcbrdx			; nothing to read
	lds	dx,dword ptr [tcbdta]
	push	cx
	push	bx
	push	ax
	call	readguts
	pop	dx			; fcb error code to this point (dh = 0 or 2)
	pop	bx			; record length
	pop	si			; number of bytes requested
	jc	fcbrd3
	xor	al,al			; clear error code if no read error returned
fcbrd3:
	mov	ah,dh			; error from recbyte if any
	cmp	si,cx
	je	fcbrd4			; read = requested?
	mov	ah,eofnone		; else eof encountered (dta no longer matters)
fcbrd4:
	mov	di,word ptr [tcbdta]
	add	di,cx			; first byte past bytes read
	xchg	ax,cx
	xor	dx,dx
	div	bx
	sub	bx,dx			; amount left in partial record (if dx <> 0)
	xchg	ax,cx			; cx = whole records read
	or	dx,dx
	jz	fcbrdx			; z if no partial records read
	or	al,al
	jnz	fcbrdx			; if some read error, only count whole records
	inc	cx			; include partial record in count
	push	cx			; zero out the remainder of the partial record
	mov	es,word ptr [tcbdta+2]
	mov	cx,bx
	xor	al,al
	rep	stosb
	pop	cx
	mov	ah,03h			; report partial record read
fcbrdx:
	pop	bx
	pop	es
	ret

	subttl	fcbwrite - write sequentially to an fcb file or device
	page
;======================================================================
;,fs
; fcbwrite - write sequentially to an fcb file or device
;
; in:	es = tfb
;	cx = number of records to write (0 set file length to dx:ax)
;	bx = length of each record
;	dx:ax = record position to start write
;
; out:	cx = number of records written
;	al = 0 if no error, else error code from write
;	ah = 1 if diskfull or other write error, 2 if dta segment overrun
;	bx, dx, si, di, ds, es undefined
;
;,fe
;======================================================================
	assume	ds:nothing,es:tfb,ss:tcb
fcbwrite:
	mov	di,2			; read and write access required
	cmp	[tfbacc],0
	je	fcbwr1			; if already have read access
	mov	di,1			; write access required
	cmp	[tfbacc],3
	jne	fcbwr2			; if don't have any access
fcbwr1:

; currently don't have write access to the file

	push	es
	push	ax
	mov	es,[tfbgfb]
	mov	ax,di
	call	chkacc
	pop	si
	pop	es
	mov	ax,0100h		; error code for access denied
	jc	fcbwrx			; if file write-protected
	mov	ax,di
	mov	[tfbacc],al
	mov	ax,si
fcbwr2:
	call	recbyte 		; transform records to bytes
	mov	ah,al			; fcb error code if any
	xor	al,al			; no extended error here
	lds	dx,dword ptr [tcbdta]	; if cx is zero, set file size
	push	cx
	push	bx
	push	ax
	call	writeguts
	pop	dx			; fcb error code to this point (dh = 0 or 2)
	pop	bx			; record length
	pop	si			; number of bytes requested
	jc	fcbwr3
	xor	al,al			; clear write error if none returned
fcbwr3:
	mov	ah,dh
	cmp	cx,si
	je	fcbwr4

; if fcb is a device then don't report disk full if device

	push	ds
	mov	ds,[tfbgfb]
	assume  ds:gfb
	cmp	[gfbdev],0
	pop	ds
	assume  ds:nothing
	jne	fcbwr4
	mov	ah,diskfull
fcbwr4:
	mov	di,ax
	mov	ax,cx			; read as many as requested
	xor	dx,dx
	div	bx
	mov	cx,ax			; cx = number of whole records read
	mov	ax,di			; and return error status
fcbwrx:
	ret

	subttl	recbyte - transform from records to bytes
	page
;======================================================================
;,fs
; recbyte - transform from records to bytes
;
; in:	cx = number of records
;	bx = record length (128 if 0)
;	dx:ax = 0-based record number (high byte set to 0 if record 
;		length >= 64 per msdos programmer's reference)
;	es = tfb
;
; out:	set [tfbpos] to byte offset of record number
;	set cx to number of bytes to read/write without dta seg overrun
;	set bx to true record length (128 if 0)
;	set al = 1 if >= 2**32 offset into file
;	set al = 2 if cx*bx overflows dta seg
;	set al = 0 otherwise
;	ah, bx, cx, dx, si, di undefined
;
;,fe
;======================================================================
	assume	ds:nothing,es:tfb,ss:tcb
recbyte:
	or	bx,bx
	jnz	rdbyta
	mov	bx,128
rdbyta:
	cmp	bx,64
	jb	rdbytb
	xor	dh,dh			; three-byte record number if rec len >= 64
rdbytb:
	mov	di,dx			; ax:dx * bx
	mul	bx
	mov	si,dx
	xchg	di,ax
	mul	bx
	add	si,ax
	adc	dx,0
	mov	dx,cx
	xor	cx,cx
	mov	al,1			; eof or diskfull and nothing read/written if
	stc
	jnz	recbytx 		; past eof > 2**32
	mov	cx,dx
	mov	word ptr [tfbpos],di
	mov	word ptr [tfbpos+2],si

; compute number of bytes to be read/written

	mov	ax,bx
	mul	cx
	mov	cx,ax
	or	dx,dx
	mov	al,1
	jnz	recbytf 		; too many if >= 64k (use dta)
	mov	ax,cx
	add	ax,word ptr [tcbdta]
	xor	al,al
	jnc	recbytx 		; nc if doesn't overrun dta
recbytf:
	mov	ax,word ptr [tcbdta]
	neg	ax			; computing number of records to read/write
	dec	ax			;   up to dta seg boundary
	xor	dx,dx
	div	bx
	mul	bx
	mov	cx,ax
	mov	al,2
recbytx:
	ret

	subttl	fcbopen - all the hard stuff to open an fcb file or device
	page
;======================================================================
;,fs
; fcbopen - all the hard stuff to open an fcb file or device
;
; in:	al = cumulative class access level
;	es:di -> unopened fcb (could be extended)
;	ds = bdb
;	bx = 0 for device
;	  cx:si -> device driver
;	else ss:bx -> dir entry sector
;	  si = dir entry offset
;	dx = 0 when attempting open an existing file (e.g. fun0f)
;	dx = 1 when creating a file
;
; out:	c if error, al = error code
;	else nc and es:di -> drive byte of opened fcb (es:[di+30] = tfbseg)
;	bx, cx, dx, si, ds undefined
;
;,fe
;======================================================================
	assume	ds:bdb,es:nothing,ss:tcb
lproc	fcbopen
lbyte	clvl
ldword	fcbptr
lword	tfbseg
lword	bdbseg
lword	drvseg
lword	origdx

; see if there's already a tcb open for an fcb for this file or device

	mov	[clvl],al
	mov	[drvseg],cx
	mov	[bdbseg],ds
	mov	[origdx],dx
	cmp	byte ptr es:[di],0ffh
	jne	fcbopna
	add	di,7
fcbopna:
	mov	word ptr [fcbptr],di
	mov	word ptr [fcbptr+2],es
	mov	cx,[tcbtfbpf]
fcbopnb:
	jcxz	fcbopndhlp
	mov	ds,cx
	assume	ds:tfb
	mov	[tfbseg],cx		; remember in case this one's it
	mov	cx,[tfbntcb]
	cmp	[tfbhdl],-1
	jne	fcbopnc 		; ne if this tfb opened for a handle call
	mov	ax,ss
	cmp	[tfbtcb],ax
	jne	fcbopnc
	mov	ax,[tcbpsp]
	cmp	ax,[tfbpsp]
	jne	fcbopnc 		; ne if this tfb not for this psp
	mov	ds,[tfbgfb]
	assume	ds:gfb
	cmp	[gfbdev],0
	je	fcbopnc
	or	bx,bx
	jnz	fcbopnb 		; looking for file, this gfb's a device
	mov	ax,es
	cmp	ax,word ptr [gfbdrvr+2]
	jne	fcbopnb 		; not the same driver seg
	cmp	si,word ptr [gfbdrvr]
	jne	fcbopnb 		; not the same driver ofs
	jmp	short fcbopne		; found it
fcbopndhlp:
	jmp	fcbopnd
fcbopnc:
	or	bx,bx
	jz	fcbopnb 		; looking for device, this gfb's a file
	mov	ax,[gfbdloc]
	cmp	ax,ss:[bx].seclow
	jne	fcbopnb 		; not the same dir sector
	cmp	si,[gfbdofs]
	jne	fcbopnb 		; not the same dir sector offset
	mov	ax,[bdbseg]
	cmp	ax,[gfbbdb]
	jne	fcbopnb 		; not the same drive
	les	di,[fcbptr]
	inc	di
	push	si
	lea	si,[gfbname]
	mov	cx,11
	call	capscmps		; compare & ignore case
	pop	si
	jne	fcbopnb 		; not the same name
	cmp	[origdx],0
	je	fcbopne			; do this stuff 
	mov	word ptr [gfbsize],0	; just in case some idiot (skplus)
	mov	word ptr [gfbsize+2],0	; calls create on an open file
	mov	word ptr [gfbpos],0
	mov	word ptr [gfbpos+2],0
	mov	[gfbcbof],0
	jmp	short fcbopne

; couldn't find a tfb, so go ahead and open file or device

fcbopnd:
	mov	es,[drvseg]
	mov	ds,[bdbseg]
	mov	al,83h			; fcb access, not inherited
	mov	ah,[clvl]
	call	openfile		;   (until first write attempt)
	jmpc	fcbopnx
	assume	es:tfb
	mov	[tfbhdl],-1		; flag it opened by fcb
	mov	[tfbfnh],-1
	mov	[tfbseg],es
	jmp	short fcbopnf

; found a tfb, so it doesn't need to be re-opened

fcbopne:
	mov	es,[tfbseg]
	assume	es:tfb

; fill out fcb the way it needs to be

fcbopnf:
	mov	ds,[tfbgfb]
	assume	ds:gfb
	les	di,[fcbptr]
	assume	es:nothing
	mov	al,es:[di]		; fill out drive byte
	or	al,al
	jnz	fcbopng
	mov	al,[tcbcdriv]
	inc	al
fcbopng:
	mov	es:[di],al
	add	di,12
	mov	cx,(32-12)/2
	xor	ax,ax
	rep	stosw
	sub	di,32
	mov	word ptr es:[di+14],128
	cmp	[gfbdev],0
	je	fcbopnh
	add	di,20
	call	timestamp
	mov	ax,dx
	stosw				; 20
	mov	ax,cx
	stosw				; 22
	lea	si,[gfbdrvr]
	movsw				; 24
	movsw				; 26
	push	ds
	lds	si,[gfbdrvr]
	mov	ax,[si+4]		; something to id the driver with
	stosw				; 28 (interrupt entry point)
	pop	ds
	jmp	short fcbopni
fcbopnh:
	add	di,16
	mov	ax,word ptr [gfbsize]
	stosw				; 16
	mov	ax,word ptr [gfbsize+2]
	stosw				; 18
	mov	ax,word ptr [gfbdate]
	stosw				; 20
	mov	ax,word ptr [gfbtime]
	stosw				; 22
	mov	ax,word ptr [gfbcbof]
	stosw				; 24 starting cluster
	mov	ax,word ptr [gfbdloc]
	stosw				; 26
	mov	ax,word ptr [gfbdofs]
	stosw				; 28
fcbopni:
	mov	ax,[tfbseg]
	stosw				; 30
	sub	di,32
	xor	al,al
fcbopnx:
lundef	clvl
lundef	fcbptr
lundef	tfbseg
lundef	bdbseg
lundef	drvseg
lundef	origdx
lendp	fcbopen

	subttl ustsrg - set task registers
	page
;======================================================================
;,fs
; ustsrg - set task registers
;
; in:
;
; out:
;
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:tcb
ustsrg:
	mov	bp,[bp] 		; to task registers on stack
	mov	di,[tdx]
	mov	es,[tds]
	call	noswt			; no task switching allowed
	ret

	subttl ustscl - call ustsrg, fcbatr, findfcb
	page
;======================================================================
;,fs
; ustscl - call ustsrg, fcbatr, findfcb
;
; in:
;
; out:
;
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:tcb
ustscl:
	call	ustsrg
	call	fcbatr
	call	findfcb
	ret

	subttl ustscv - call ustsrg, validfcb
	page
;======================================================================
;,fs
; ustscv - call ustsrg, validfcb
;
; in:
;
; out:
;
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:tcb
ustscv:
	call	ustsrg
	call	validfcb
	ret

	subttl tstalerr - deal with errorcode, call okswt
	page
;======================================================================
;,fs
; tstalerr - deal with errorcode, call okswt
;
; in:
;
; out:
;
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:tcb
tstalerr:
	mov	[tcberrcod],al
	mov	[tal],al
	or	al,al
	jz	mosf0fy
	mov	[tal],fcberr
mosf0fy:
	call	okswt
	ret

	subttl xfrddta - transfer directory entry to dta
	page
;======================================================================
;,fs
; xfrddta - transfer directory entry to dta
;
; in:
;
; out:
;
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:tcb
xfrddta:
	assume	ds:bdb
	mov	al,[bdbid]		; drive for dta
	inc	al			; (0 = device, 1=a)
	mov	ds,cx			; dbb seg
	assume	ds:dbb
	mov	es:[di+12],ah		; attribute for search
	mov	es:[di+13],si		; save offset in dir sector (or driver offset)
	mov	dx,ss:[bx].seclow	; low word of dir sector number
	mov	es:[di+15],dx
	mov	dx,ss:[bx].sechigh	; high word of dir sector number
	mov	es:[di+17],dx
	mov	es:[di+19],al		; and drive number
	les	di,dword ptr [tcbdta]	; transfer dir entry to dta
	assume	es:nothing
	mov	dx,ds
	mov	cx,si
	mov	ds,[tds]
	assume	ds:nothing
	mov	si,[tdx]
	cmp	byte ptr [si],0ffh
	jne	mosf11d
	movsw
	movsw
	movsw
	movsb
mosf11d:
	mov	si,cx
	mov	ds,dx
	assume	ds:dbb
	stosb				; drive byte first
	mov	ax,ss:[bx].seclow
	or	ax,ss:[bx].sechigh
	jnz	xfrdd1
	add	si,10
	mov	cx,8/2
	rep	movsw
	mov	ax,'  '
	stosw
	stosb
	jmp	xfrdd2
xfrdd1: 				
	lea	si,[dbbbuf+si]
	mov	cx,32/2
	rep	movsw			; followed by rest of dir entry
xfrdd2: 
	call	zerrcod 		; zero error code
	ret

	subttl zerrcod - zero out tcberror code and task al reg
	page
;======================================================================
;,fs
; zerrcod - zero out tcberror code and task al reg
;
; in:
;
; out:
;
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:tcb
zerrcod:
	mov	[tcberrcod],0
	mov	[tal],0
	ret

	subttl seterr - set tcb error code and al task reg
	page
;======================================================================
;,fs
; seterr - set tcb error code and al task reg
;
; in:
;
; out:
;
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:tcb
seterr:
	mov	[tcberrcod],al
	mov	[tal],fcberr
	ret

	subttl setupfcb - setup fcb regs and segment
	page
;======================================================================
;,fs
; setupfcb - setup fcb regs and segment
;
; in:
;
; out:
;
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:tcb
setupfcb:
	mov	bx,es:[di+14]		; record length
	mov	al,es:[di+32]
	mov	ah,es:[di+12]
	mov	dl,es:[di+13]
	xor	dh,dh
	shl	al,1
	shr	dx,1
	rcr	ax,1
	mov	es,es:[di+30]
	ret

	subttl aftset - after fcb r/w function, update fcb
	page
;======================================================================
;,fs
; aftset - after fcb r/w function, update fcb
;
; in:
;
; out:
;
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:tcb
aftset:
	mov	di,[tdx]
	mov	es,[tds]
	add	byte ptr es:[di+32],cl
	jns	mosf14a
	mov	byte ptr es:[di+32],0
	inc	word ptr es:[di+12]
mosf14a:
	push	ax
	call	updatfcb
	pop	ax
	ret

	subttl stercd - set err code, allow task switch
	page
;======================================================================
;,fs
; stercd - set err code, allow task switch
;
; in:
;
; out:
;
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:tcb
stercd:
	mov	[tcberrcod],al
	mov	[tal],ah
	call	okswt
	ret

	subttl updaft - update regs from tsk regs, cur rec pntr and fcb 
	page
;======================================================================
;,fs
; updaft - update regs from tsk regs, cur rec pntr and fcb 
;
; in:
;
; out:
;
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:tcb
updaft:
	mov	di,[tdx]
	mov	es,[tds]
	push	ax
	call	updatcr 		; update current record ptr
	call	updatfcb		; update fcb fields from gfb
	pop	ax
	ret

	subttl updaf0 - update regs from task regs, write # recs read to fcb
	page
;======================================================================
;,fs
; updaf0 - update regs from task regs, write # recs read to fcb
;
; in:
;
; out:
;
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:tcb
updaf0:
	mov	di,[tdx]
	mov	es,[tds]
	mov	[tcx],cx		; number of records from fcb function
	add	word ptr es:[di+33],cx
	adc	word ptr es:[di+35],0
	push	ax
	call	updatcr 		; update current record ptr
	call	updatfcb		; update fcb fields from gfb
	pop	ax
	ret

	subttl stfcb0 - setup registers for fcb r/w function
	page
;======================================================================
;,fs
; stfcb0 - setup registers for fcb r/w function
;
; in:
;
; out:
;
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:tcb
stfcb0:
	mov	ax,es:[di+33]		; at record number dx:ax
	mov	dx,es:[di+35]
	mov	bx,es:[di+14]		; record length
	mov	es,es:[di+30]
	ret

	subttl ckaccd - check access code for file
	page
;======================================================================
;,fs
; ckaccd - check access code for file
;
; in:
;
; out:
;
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:tcb
ckaccd:
	assume	ds:nothing,es:tfb,ss:tcb
	push	es
	push	ax
	mov	es,[tfbgfb]
	mov	ax,di
	call	chkacc
	pop	si
	pop	es
	mov	ax,0100h		; error code for access denied
	ret

	subttl stfbac - set tfb access
	page
;======================================================================
;,fs
; stfbac - set tfb access
;
; in:
;
; out:
;
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:tcb
stfbac:
	assume	ds:nothing,es:tfb,ss:tcb
	mov	ax,di
	mov	[tfbacc],al
	mov	ax,si
	ret

	subttl xformr - xform recs to bytes without extended error code (if any)
	page
;======================================================================
;,fs
; xformr - xform recs to bytes without extended error code (if any)
;
; in:
;
; out:
;
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:tcb
xformr:
	call	recbyte 		; transform records to bytes
	mov	ah,al			; fcb error code if any
	xor	al,al			; no extended error here
	ret

ddt	ends
	end

