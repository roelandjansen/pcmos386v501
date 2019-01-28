	include page.inc
	title	mosfun39 - mos functions 39 - 5c
comment ^===============================================================
		      development specification

 program name:	$$mos.com		 assigned to: jim bean
 module name:	mosfun39		 assign date: 01/30/86
 entry points:	mosfun39-mosfun5c	 completed: 09/03/86
 entry from:	mosint21, mosfun0f
 entry method:	call
 calls:		mosfutil, mosliman, gettime, caps
 purpose:	file handle functions
 last update:	08/18/1992
========================================================================

implementation comments

functions implemented:
  39, 3a, 3b, 3c, 3d, 3e, 3f, 40, 41, 42, 43, 44, 45, 46, 47, 4e, 4f,
  56, 57, 5a, 5b, 5c

each of the mosfun?? functions considers all registers except ds, bp,
  ss, sp, cs and ip as fair game so if you call near instead of doing
  an int 21h, be warned - also note that the parameters are expected
  in the task register set tax, tbx, .. - kids don't try this at home

sector size (bdbssiz) must be an integral multiple of 32 (directory
  entry size)

rmdir not allowed if directory is the current directory for any task

pathdir relies on the .. entry in the subdirectory if .. is specified
  in the path (note that dos doesn't depend upon the .. entry or even
  seem to use the .. entry)

timestamp (to get date and time for directory entries) uses gettime
  and getdate extrn functions - gettime and getdate should be
  provided with the implementation of functions 2ah and 2ch

little attention is paid to multi-user stuff within a function since
  task switches are locked out for the duration of the dos functions

reports too many files open if it runs out of heap space trying to
  open a file (allocating a gfb or tfb), or if handle 65535 is the
  only available handle

reports error 128 (attempt to duplicate a system handle) if fdup
  or dup used on a handle which isn't a psp handle

when exec is implemented, it must duplicate access to open files of
  the parent process - it must create a copy of the parent's psp
  handle table and set each entry to 0ffh whose inheritance bit is 1
  note to deal with special cases like, 20 bytes fits in child psp,
  else space has to be allocated somewhere else and pointed to by
  child psp handle table pointers

close flushes dir entry info (date, time, size) and written sectors
  each time, the tfb is deleted only when the open count goes to 0,
  the gfb is deleted only if that was the last tfb

change file mode (43h) sets the new attribute in the gfb (if any) as
  well as in the dir entry

requires the ability to acquire exclusive access to file to create,
  delete or rename the file (calls exlcude which closes the
  respective file if open)

chkacc and iolock (checking open access and read/write locks)
  suspend the task between retries.

chkacc, iolock, devread, devwrite all currently pass a null poll
  subroutine pointer to suspend - the null poll always tells mos
  the task is ready to run

compatibility table for higher level function ax returns

	function	  ax return	   updated
	  39		    0005	   sah	5/02/87
	  3a		    0005	   sah	5/02/87
	  3b		    0000	   sah	5/02/87
	  3e		    0006	   sah	5/02/87 (twin)
	  47		    0100	   mjs
	  4e		    0000	   mjs	(sah ax) (first choice)
	  4f		    0000	   sah	6/10/87 (bbx)

========================================================================

mjs 02/24/87	cooking mods.  moved readguts, writeguts, 
		truncguts and creatguts to the mosmiman module.

jsm 03/18/87	large volume support

jsm 04/01/87	alias support

jsm 04/27/87	make 5c (lock) initialize rlb properly

jsm 05/02/87	make 4e (find first) deal properly with volume 
		labels & alias drives

sah 05/02/87	example dos return codes for sucessfull functions in 39+
		range which do not return any values in ax and made mos to
		to simulate their returns (set table)

rbr 05/03/87	code optimization

jrb 05/17/87	create check attribute low byte only

sah 06/10/87	bbx requires ax to be 00 on fun 4e requires ax to be 00 on
		fun 4f

sah 06/24/87	44 sub function 2 returns count in ax

jsm 07/21/87	temporarily enable access to all classes in 3c (create
		file) if file does not already exist.

sah 08/13/87	fix bugs with function 44 sub function 6 return status
		codes back to the caller also check out similar sub
		functions for similar problems.

sah 08/25/87	fix function 44 sub function 8 which did termination
		condition correctly store ds:dx into tcbopen60 for use in
		return information in function 60h

sjc 10/26/87	optimization.  modify okswt to check for improper use.

sjc 11/10/87	fixed bug - execute only files did not execute properly.
		mosfun3d used current code segment when referencing
		external seg scbmosadr.

sah 12/07/87	fixed bug with function 44 sub-function 02 in not returning
		correct value back in ax, because bp is not correct when ax
		is set.	 this fix also fix problems with sub- functions
		03,04, and 05

sjc 12/13/87	function 4f clears byte 20 of the dta.	this causes
		problems with lanlink.	dos does not clear this byte!  set
		al reg to function number to make certain this byte is not
		cleared in 4f.

jrb 12/17/87	allow device find in function 4e

sah 01/21/88	change scbseg and zero seg access to mgetxxxx macros

jrb 02/04/88	don't release one handle's locks on a close on another
		handle

mjs 02/09/88	add logic to fun56 (rename) to return access denied if the
		second parm contains any *'s or ?'s.  also added logic to
		support renaming and relocating of subdirectories.

rbr/sah 02/20/88  move ddt code to mo2 group.

sah 04/13/88	change fun 3d so if openfile got an extended error that it
		will return access denied instead of path not found

jrb 05/02/88	correct ioctl fn 0e and 0f (get/set logical drive) change
		get current dir to do a media check (which also returns cdb
		ptr) because dos does and it's needed on floppies.  split
		mosfun44 into new mosfun44.asm cause mosfun39 ran out of
		room

mjs 7/2/88	added a call to noswt in mosfun47.  this function had an
		okswt call but no call to noswt.

sah 07/14/88	correct function 3f if invalid handle would always try read
		because flags were not save around and xor cx,cx

sah 08/15/88	corrected mosfun47 by making sure that the directory path
		is actually there. some body could have change disks on us.
		clean up source and correct lundefs for optasm.

sah 09/04/88	corrected function 47h return of ax to 0100h not 100d this
		solve conflict with windows write.

sah 11/04/88	remove dependency on mosscbex.inc

sah 01/26/89	change lock equate to nlock (masm 5.10 compatibility)

mjs 06/06/89	mosfun39 was not checking the entry string for globals so
		it was possible to do a "md a?b" and create a dir that
		could not be removed and which would screw up verify.  i
		excised code from fun56 and made the procedure chk_glbl. 
		both fun39 and fun56 call this now.

sah 12/14/89	remove mosregs2.inc

mjs 04/30/90	add setup of al register to pathfind calls.  add test in
		mosfun3c and mosfun5b to skip files of the same name when
		creating a label

sah 07/18/90	corrected function 3c for handling creating read-only
		files.	also fix fun 5a and 5b for similar condition

mjs 12/16/91	dlg mods: extracted mosfun3c logic to form the hl_create
		function.  extracted mosfun3d logic to form the hl_open
		function.  modified mosfun5b to use the hl_create
		function.  added mosfun6c, which uses hl_create and
		hl_open.  transferred the following functions from 
		mosfun00 to mosfun39: mosfun58, 59, 65, 66, 67 and 68.


SAH 03/05/92	Change mosfun6c error codes as following
		DX=0001h  and no file exist return 0002 - file not found
		DX=0010h  and file exists return 0050h - file exists

================ 5.01 Kernel Ends Here ====================================

mjs 07/13/92	remove test of entry flags for mosfun3d.  testing
		for calling cs:ip == mos:execopen is enough.  the
		effect of this flags test was thwarted when
		sah modifed sim21 to bias the tcb stack.
		updat501.sys version 1.03 effects this change for
		the mos 5.01 release.

mjs 07/23/92	modify i21f68 to update the directory entry by
		calling the upd_dir function.

mjs 08/18/92	clean up segment declarations

mjs 09/17/92	added security check to i21f3b.

mjs 09/18/92	added a call to findphdl to the start of mosfun68
		(per sah).

=======================================================================^

.xlist
;	include mosfun39.pub
	include group.inc
	include mosregs.inc
	include moscdb.inc		; etc., etc., etc.
	include mosgfb.inc
	include mostfb.inc
	include mosrlb.inc
	include mosbdb.inc
	include macros.inc
	include errcodes.inc
	include mospsp.inc

tcb	segment at 1234h
	include mostcb.inc		; tcb definition
tcb	ends

gdata	segment
extrn	scbnoswt:byte, scbtcbpf:word
gdata	ends
.list

;======================================================== mos segment
if 0 eq 0
segment_num = 1
endif
mosseg	segment
	extrn	caps:near, sim21:near
mosseg	ends

;======================================================== ddt segment
if 0 eq 0
segment_num = 2
endif
ddt	segment
	assume	cs:mo2,ds:grp,es:nothing,ss:tcb

	extrn	mosend:byte, sbios2:word
	extrn	mosliman:near
	extrn	gettime:near, execopen:near
	extrn	mo1seg:word
	extrn	mediachk:near, flushdata:near, upd_dir:near

; extrn's from MOSFUTIL.ASM

	extrn	alloclust:near, blkread:near, blkwrite:near
	extrn	chklock:near, closefile:near, clrclust:near, create:near
	extrn	dealloc:near, delete:near, devchk:near, todriver:near
	extrn	emptydir:near, findbdb:near, findgfb:near, findlbl:near
	extrn	findnm:near, findrlb:near, findtfb:near, flushdir:near
	extrn	getfat:near, getphdl:near, makelbl:near
	extrn	moserror:near, nextnm:near, openfile:near
	extrn	pathfind:near, putfat:near, rddir:near, slash:near
	extrn	timestamp:near, wrsector:near, setphdl:near, iolock:near
	extrn	devread:near, devwrite:near, finddrv:near, exclude:near
	extrn	okchar:near, encrypt:near, decrypt:near, classlvl:near
	extrn	cpycmap:near, eblcmap:near, capscmps:near, findphdl:near

; extrn's from MOSMIMAN.ASM

	extrn	readguts:near, writeguts:near, truncguts:near
	extrn	creatguts:near, checkexon:near
	extrn	buffinp:near, cdevinp:near

	public	okswt, noswt, sttax0
	public		  mosfun39, mosfun3a, mosfun3b
	public	mosfun3c, mosfun3d, mosfun3e, mosfun3f
	public	mosfun40, mosfun41, mosfun42, mosfun43
	public	mosfun45, mosfun46, mosfun47
	public			    mosfun4e, mosfun4f
	public			    mosfun56, mosfun57
	public			    mosfun5a, mosfun5b
	public	mosfun5c
	public	mosfun6c

if 0 eq 0				; trick public.com

; error codes defined

syshdl	equ	127 or 8000h		; attempt to dup or fdup a non-psp handle
xshare	equ	error_sharing_violation or 8000h  ; fail from int 24h sharing
xlock	equ	error_lock_violation or 8000h  ; fail from int 24h locking
err24h	equ	error_fail_i24 or 8000h	; fail error from int 24h (signal for moserror)
intern	equ	80ffh			; internal error

; directory entry fields

datr	equ	11			; offset of attribute byte
dclass0 equ	13			; offset of class byte
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

; critical error coding

rdx	equ	00h			; read operation
wrx	equ	01h			; write operation

failx	equ	08h			; fail not allowed
retryx	equ	10h			; retry not allowed
ignorex equ	20h			; ignore not allowed
allx	equ	failx or retryx or ignorex
sysx	equ	failx or retryx		; ignore not allowed in system areas

dosx	equ	00h or allx		; dos area of disk?
fatx	equ	02h or sysx		; fat area
dirx	equ	04h or sysx		; dir area
datax	equ	06h or allx		; data area

endif

	subttl noswt - turn off task switching
	page
;======================================================================
;,fs
; noswt - turn off task switching
;
; in:	
;
; out:	
;
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:nothing
noswt proc near
	push	ds
	mgetscb2 ds
	assume	ds:grp
	inc	[scbnoswt]
	pop	ds
	assume	ds:nothing
	ret
noswt endp

	subttl okswt - enable task switching
	page
;======================================================================
;,fs
; okswt - enable task switching
;
; in:	
;
; out:	
;
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:nothing
okswt proc near
	push	ds
	mgetscb2 ds
	assume	ds:grp
	cmp	[scbnoswt],0		; guard against improper use of noswt/okswt
	jz	endok			; if already zero, don't decrement
	dec	[scbnoswt]

; check for pending task switch here!

	assume	ds:nothing
endok:
	pop	ds
	ret
okswt endp

	subttl chk_glbl - check a string for global chars
	page
;======================================================================
;,fs
; chk_glbl - check a string for global chars
;
; in:	es:di -> string to check
;
; out:	ax = 0 if no globals, error_access_denied if any found
;
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:nothing
chk_glbl:
	push	bx
	push	cx
	push	si
	push	di
	mov	si,di
	mov	cx,0ffffh
	cld
	xor	al,al			; find length of string
	repne	scasb
	mov	cx,di
	sub	cx,si
	mov	di,si
	mov	al,'?'
	push	cx
	repne	scasb
	pop	cx
	je	chkglbl1
	mov	di,si
	mov	al,'*'
	xor	bx,bx
	repne	scasb
	je	chkglbl1
	xor	ax,ax
	jmp	chkglbl2
chkglbl1:
	mov	ax,error_access_denied
chkglbl2:
	pop	di
	pop	si
	pop	cx
	pop	bx
	ret

	subttl mosfun39 - create dir (mkdir)
	page
;======================================================================
;,fs
; mosfun39 - create dir (mkdir)
;
; in:	tds:tdx -> asciiz string specifying path and dir to create
;
; out:	carry bit of tflag set if error
;	 tax = error code
;	  error_path_not_found - invalid drive specified
;		   invalid path specified
;		   path not found
;		   subdir name is invalid
;	  error_access_denied - a file or dir with the same drive, path and name (or
;		    a device with the same name) already exists
;		    the root dir is full
;		    the parent dir is full and the disk is full so the
;		    parent dir can't be extended
;	  & critical error codes
;	carry bit of tflag clear if no error
;
;,fe
;======================================================================
	assume	ds:grp,es:nothing,ss:tcb
lproc	mosfun39
lword	pcluster			; first cluster of parent dir (0 if root)
lword	ccluster			; first cluster of new subdir
lword	pofs				; offset in sector of parent dir entry
ldword	psect				; sector of parent dir entry
lstring fnm,11				; dir entry formatted name of new subdir
lstring secbuf,<size sectorblk>		; buffer for sector number
	call	usts0			; use task regs
	call	chk_glbl
	or	ax,ax
	jnz	jmosf39y

; validate drive, path and subdir name
	
	mov	[fnm],' '		; to detect drive only path
	lea	si,fnm
	lea	bx,secbuf
	mov	al,1			; skip labels
	call	pathfind
	assume	ds:bdb,es:nothing
	jc	mosf39a
	mov	ax,error_access_denied	; name already exists in subdir
jmosf39y:
	jmp	mosf39y
mosf39a:
	cmp	ax,error_file_not_found
	jne	jmosf39y		; ne includes error_path_not_found
	mov	ax,error_path_not_found
	cmp	[fnm],' '
	je	jmosf39y		; invalid if only drive supplied in path
	mov	ax,error_access_denied	; must have read/write access to parent dir
	cmp	cl,3
	jb	jmosf39y
	mov	[pcluster],dx

; create dir entry in parent dir for subdir

	push	ss
	pop	es
	lea	di,fnm
	mov	al,dir
	call	create			; make a dir entry (fails if duplicate)
	jc	jmosf39y		; (error - nothing to undo)
	mov	[pofs],si
	mov	dx,[secbuf].seclow
	mov	word ptr [psect],dx
	mov	dx,[secbuf].sechigh
	mov	word ptr [psect+2],dx

; allocate and clear a cluster for the subdir

	mov	dx,0ffffh		; no clusters allocated so far
	call	alloclust		; allocate a cluster to the dir entry
	jc	mosf39x			; (error - del dir entry, no cluster)
	mov	[ccluster],dx
	call	clrclust
	jc	mosf39w			; (error - del dir entry, dealloc cluster)

; assign allocated cluster to new dir entry

	call	rddir			; ss:bx -> parent dir entry sector
	jc	mosf39w			; (error - del dir entry, dealloc cluster)
	assume	es:dbb

; si = parent dir entry offset

	mov	word ptr [si+dbbbuf+dclust],dx
	call	wrsector
	jc	mosf39x			; (error - del dir entry with cluster)

; set up . (self-reference) and .. (parent) dir entries in subdir

	push	ss
	pop	es
	assume	es:tcb
	lea	di,fnm
	mov	al,'.'			; construct . name
	stosb
	mov	ax,'  '
	mov	cx,10/2
	rep	stosw
	lea	di,fnm
	mov	al,dir			; dx = subdir start cluster
	call	create			; . (self-reference) entry
	jc	mosf39x
	mov	[fnm+1],'.'		; (constructs .. name)
	mov	al,dir			; dx = subdir start cluster, di -> fnm
	call	create			; .. (parent-reference) entry
	jc	mosf39x

; supply starting cluster to . and .. dir entries

	call	rddir
	jc	mosf39x
	assume	es:dbb

; si -> .. entry (immediately follows . entry)

	mov	word ptr [dbbbuf+si-32+dclust],dx
	mov	ax,[pcluster]
	mov	word ptr [dbbbuf+si+dclust],ax
	call	wrsector
	jc	mosf39x
	call	flushdir		; flush any changed fat and dir sectors
	jc	mosf39x
	xor	ax,ax			; no error
	jmp	short mosf39y

; error before new dir entry owns cluster, so explicitly dealloc it

mosf39w:
	push	ax
	mov	dx,[ccluster]
	call	dealloc
	pop	ax
mosf39x:

; error after creating dir entry, so del it

	push	ax
	mov	ax,word ptr [psect]
	mov	[secbuf].seclow,ax
	mov	ax,word ptr [psect+2]
	mov	[secbuf].sechigh,ax
	lea	bx,[secbuf]
	mov	si,[pofs]
	call	delete			; delete the dir entry, dealloc cluster if any
	call	flushdir		; flush changed fat and dir sectors
	pop	ax
	assume	ds:nothing,es:nothing,ss:tcb
mosf39y:
	mov	dx,5			; sjc optimize, set return code of 5 per sah
	mov	cx,error_path_not_found
	call	repo0			; report error and return codes for task
lundef	pcluster
lundef	ccluster
lundef	pofs
lundef	psect
lundef	fnm
lundef	secbuf
lendp	mosfun39

	subttl mosfun3a - remove dir (rmdir)
	page
;======================================================================
;,fs
; mosfun3a - remove dir (rmdir)
;
; in:	tds:tdx -> asciiz string specifying path and dir to remove
;
; out:	carry bit of tflag set if error
;	 tax = error code
;	  error_path_not_found -  invalid path specified
;		    path not found
;		    subdir not found
;		    the subdir is not valid
;	  error_access_denied - the subdir is the current dir for another task
;		    the subdir is not empty
;	  error_current_directory - the subdir is the current dir for this task
;	  & critical error codes
;	carry bit of tflag clear if no error
;
;,fe
;======================================================================
	assume	ds:grp,es:nothing,ss:tcb
lproc	mosfun3a
ldword	psect
lword	pofs
lword	pclust
lword	xtcb
lstring fnm,11
lstring secbuf,<size sectorblk>
	call	usts0			; use task regs, no switch

; validate drive, path and dir name

	lea	si,fnm
	lea	bx,secbuf
	mov	al,1			; skip labels
	call	pathfind
	assume	ds:bdb,es:nothing
	jc	jmosf3ax
	cmp	al,'?'
	mov	ax,error_path_not_found
	je	jmosf3ax		; no wild-cards allowed
	or	bx,bx
	jz	jmosf3ax		; device isn't a directory
	mov	ax,error_access_denied
	cmp	dx,-1
	je	jmosf3ax		; can't remove root dir
	cmp	cl,3			; must have read/write access to parent dir
	jb	jmosf3ax
	mov	[pclust],dx		; dx = cluster for parent dir
	assume	es:dbb
	test	[dbbbuf+si+datr],dir
	jmpz	mosf3ax			; not a directory
	mov	dx,word ptr [dbbbuf+si+dclust]

; verify that subdir is a valid, empty subdir:
; 1.  first entry is a dir named . which owns the subdir cluster
; 2.  second entry is a dir named .. which owns the parent cluster
; 3.  there are no other entries
; read the first sector of the subdir

	mov	[pofs],si
	mov	si,[secbuf].seclow
	mov	word ptr [psect],si
	mov	si,[secbuf].sechigh
	mov	word ptr [psect+2],si
	mov	bx,dx			; dx = cluster for subdir
	cmp	bx,[bdbcnum]		; validate subdir cluster number
	jnc	jmosf3ax
	sub	bx,2
	jc	jmosf3ax
	xor	cx,cx
	mov	[secbuf].sechigh,cx
	mov	cl,[bdbcshl]
	jcxz	mosf3a1
mosf3a0:
	shl	bx,1
	rcl	[secbuf].sechigh,1
	loop	mosf3a0
mosf3a1:
	add	bx,[bdbclus]		; bx = sector for subdir
	adc	[secbuf].sechigh,cx	; cx is 0
	mov	[secbuf].seclow,bx
	lea	bx,[secbuf]
	call	rddir
	jnc	$+5
jmosf3ax:
	jmp	mosf3ax
	assume	es:dbb

; first entry must be a dir named . owning the subdir cluster

	lea	di,dbbbuf
	mov	al,'.'
	scasb
	jne	mosf3ab
	mov	ax,'  '
	mov	cx,10/2
	repe	scasw
	jne	mosf3ab
	test	[dbbbuf+datr],dir
	jz	mosf3ab
	cmp	word ptr [dbbbuf+dclust],dx
	jne	mosf3ab

; second entry must be a dir named .. owning the parent dir cluster

	lea	di,dbbbuf+32
	mov	ax,'..'
	scasw
	jne	mosf3ab
	mov	al,' '
	mov	cx,11-2
	repe	scasb
	jne	mosf3ab
	test	byte ptr [dbbbuf+32+datr],dir
	jz	mosf3ab
	mov	ax,[pclust]
	cmp	word ptr [dbbbuf+32+dclust],ax
	je	mosf3ac
mosf3ab:
	mov	ax,error_path_not_found	; dos returns error_path_not_found for invalid subdir
	jmp	short jmosf3ax

; there can be no other entries

mosf3ac:
	push	ss
	pop	es
	assume	es:tcb
	lea	di,fnm			; construct fnm *.* to match any other entry
	mov	cx,11			;   in subdir
	mov	al,'?'
	rep	stosb
	lea	di,fnm
	mov	si,32*2			; point at third dir entry to start
	call	nextnm			; dx = cluster for subdir
	mov	cx,ax
	mov	ax,error_access_denied
	jnc	mosf3ax			; nc if dir not empty
	mov	ax,cx
	cmp	ax,error_file_not_found
	jne	mosf3ax			; ne if error other than name not in directory

; subdir can't be any task's current dir

	mgetscb2 es
	assume	es:grp
	mov	bx,[scbtcbpf]		; first tcb
	assume	ss:nothing		; (make sure ss not used to address tcb's)

; for every task

mosf3ad:
	or	bx,bx
	jz	mosf3af
	mov	es,bx
	assume	es:tcb
	mov	[xtcb],bx		; remember which tcb we're looking at
	mov	bx,[tcbtcbpn]
	mov	cx,[tcbcdbpf]

; look through cdb's for task to find cdb for subdir drive

mosf3ae:
	mov	ax,intern		; internal error - every task has a cdb for
	jcxz	mosf3ax			;   every drive
	mov	es,cx
	assume	es:cdb
	mov	cx,[cdbnext]
	mov	al,[bdbid]
	cmp	al,[cdbdrive]
	jne	mosf3ae			; e when we've found the correct drive

; and make sure it's not the same as the subdir

	cmp	dx,[cdbclus]
	jne	mosf3ad
	mov	ax,ss
	cmp	ax,[xtcb]
	mov	ax,error_current_directory  ; tried to delete own task's current dir
	je	mosf3ax			;   if e
	mov	ax,error_access_denied	; else tried to delete another task's current
	jmp	short mosf3ax		;   dir

; delete subdir and flush changed sectors

	assume	es:nothing,ss:tcb
mosf3af:
	mov	bx,word ptr [psect]
	mov	[secbuf].seclow,bx
	mov	bx,word ptr [psect+2]
	mov	[secbuf].sechigh,bx
	lea	bx,[secbuf]
	mov	si,[pofs]
	call	delete			; delete subdir and dealloc any clusters
	jc	mosf3ax
	call	flushdir		; flush everything out to disk
	jc	mosf3ax
	xor	ax,ax
	assume	ds:nothing,es:nothing,ss:tcb
mosf3ax:
	cmp	ax,error_file_not_found
	jne	mosf3ay
	mov	ax,error_path_not_found
mosf3ay:
	mov	dx,5			; per sah  success code
	mov	cx,error_path_not_found
	call	repo0
lundef	psect
lundef	pofs
lundef	pclust
lundef	xtcb
lundef	fnm
lundef	secbuf
lendp	mosfun3a

	subttl mosfun3b - change the current directory (chdir)
	page
;======================================================================
;,fs
; mosfun3b - change the current directory (chdir)
;
; in:	tds:tdx -> asciiz string with subdirectory to change to
;
; out:	carry bit of tflag set if error
;	 tax = error code
;	  error_path_not_found - invalid path specified
;		   path not found
;		   subdirectory not found
;		   subdirectory not a valid subdirectory
;	  & critical error codes
;	carry bit of tflag clear if no error
;
;,fe
;======================================================================
	assume	ds:grp,es:nothing,ss:tcb
lproc	mosfun3b
lbyte	clvl
lword	cdbptr
lword	rootclust
ldword	pathptr
lstring fnm,64
lstring secbuf,<size sectorblk>
	call	usts0			; task regs, no switch

; validate drive, path and dir name

	mov	word ptr [pathptr],di
	mov	word ptr [pathptr+2],es
	lea	si,fnm			; pathfind serves to validate path and access
	lea	bx,secbuf
	mov	al,1			; skip labels
	call	pathfind		;   level
	assume	ds:bdb,es:nothing
	mov	[clvl],cl
	jc	jmosf3bx
	cmp	al,'?'
	mov	ax,error_path_not_found
	je	jmosf3bx		; no wild-cards allowed
	or	bx,bx
	jz	jmosf3bx		; can't set dir to device name
	inc	dx
	jnz	mosf3ba2		; if not a root of a physical disk
	mov	dx,[bdbroot]		; get root directory for the disk
	jmp	short mosf3ba3
	assume	es:dbb
mosf3ba2:
	test	[dbbbuf+si+datr],dir
	jz	jmosf3bx		; not a directory
	mov	dx,word ptr [dbbbuf+si+dclust]
	mov	ax,error_path_not_found
	jne	mosf3ba3
jmosf3bx:
	jmp	mosf3bx

;!@!@

; check for security clearance

mosf3ba3:
	mov	al,[dbbbuf+si+dclass0]
	call	classlvl
	cmp	al,1
	mov	ax,error_access_denied
	jb	jmosf3bx
;!@!@

; find current directory block for this task for this drive
; set new subdir data in cdb
; but remember old data in case of error

	mov	cx,[bdbroot]		; root directory cluster for the real drive
	mov	[rootclust],cx
	mov	bl,[bdbid]
	mov	cx,[tcbcdbpf]
	mov	ax,intern
	or	dx,dx
	jnz	mosf3ba4		; make sure root access is read/write
	mov	[clvl],3
mosf3ba4:
	or	cx,cx			; internal error if drive not represented among
	jz	jmosf3bx		;   cdb's
	mov	ds,cx
	assume	ds:cdb
	mov	cx,[cdbnext]
	cmp	bl,[cdbdrive]
	jne	mosf3ba4
	lea	si,cdbpath
	push	ss
	pop	es
	lea	di,fnm
	mov	cx,64/2
	rep	movsw			; remember old current dir string
	xchg	[cdbclus],dx		; remember old current dir cluster
	mov	al,[clvl]
	xchg	[cdblvl],al
	mov	[clvl],al
	push	ds
	pop	es
	assume	es:cdb
	lds	si,[pathptr]
	assume	ds:nothing
	cmp	byte ptr ds:[si+1],':'
	jne	mosf3bb
	add	si,2			; past drive designator
mosf3bb:
	lea	di,cdbpath
	lodsb
	call	slash
	je	mosf3bc			; e if starting path with root

; starting path with current dir (find end of current dir string)

	dec	si			; correcting for lodsb
	cmp	dx,[rootclust]		; (cluster of previous current dir)
	jz	mosf3bc			; current dir is root
	mov	cx,64
	xor	al,al
	repne	scasb
	mov	byte ptr es:[di-1],'\'
mosf3bc:
	lodsw
	cmp	al,'.'
	mov	al,ah
	mov	ah,0
	jne	mosf3bd
	dec	di			; backup onto last slash
	or	al,al
	jz	mosf3be1		; so zero is written on top of it if '.',00h
	inc	di
	call	slash
	je	mosf3bc			; skip any .\ encountered
	cmp	al,'.'
	jne	mosf3bd			; isn't ..
	mov	al,[si]
	or	al,al
	jz	mosf3bc1
	call	slash
	jne	mosf3bd
mosf3bc1:

; on ..\ scan backwards to preceding \	or beginning of dir string

	sub	di,2			; di preceding last \
	mov	cx,di
	sub	cx,offset cdbpath-1
	mov	al,'\'
	std
	repne	scasb
	cld
	inc	di			; onto encountered \ (or to cdbpath)
	lodsb
	or	al,al
	jz	mosf3be1
	mov	al,'\'			; must be \ if not 0
	cmp	di,offset cdbpath
	jne	mosf3be1
	jmp	mosf3bc			; don't need slash at start of cd string

; not .\ or ..\ so just copy it to dir string

mosf3bd:
	sub	si,2
mosf3be:
	lodsb
	callmos1 caps			;** call in mos segment
	cmp	al,'/'
	jne	mosf3be1
	mov	al,'\'
mosf3be1:
	cmp	di,offset cdbpath+64
	jae	mosf3bf			; new current dir path is too long
	stosb
	or	al,al
	jz	mosf3be2
	cmp	al,'\'
	je	mosf3bc
	jmp	mosf3be
mosf3be2:
	dec	di			; remove any trailing spaces (who needs 'em)
	cmp	byte ptr es:[di],' '
	je	mosf3be2
	inc	di
	stosb
	jmp	mosf3bx
mosf3bf:

; if string too long or encountered ..\ at root,
; restore previous current dir information

	mov	[cdbclus],dx
	mov	al,[clvl]
	mov	[cdblvl],al
	lea	di,cdbpath
	push	ss
	pop	ds
	assume	ds:tcb
	lea	si,fnm
	mov	cx,64/2
	rep	movsw
	mov	ax,error_path_not_found
	assume	ds:nothing,es:nothing,ss:tcb
mosf3bx:
	cmp	ax,error_file_not_found
	jne	mosf3by
	mov	ax,error_path_not_found
mosf3by:
	xor	dx,dx			; per sah-return code of zero
	mov	cx,error_path_not_found
	call	repo0			; report
lundef	clvl
lundef	cdbptr
lundef	rootclust
lundef	pathptr
lundef	fnm
lundef	secbuf
lendp	mosfun3b

	subttl hl_create - high level create logic
;======================================================================
;,fs
; hl_create - high level create logic
;
; in:	es:di -> asciiz string with drive, path and file to create
;	al = file open mode for the openfile function
;	ah = the newonly flag, != 0 when should fail for pre-existing file
;	cl = attributes
;
; out:	ax = 0 if no error
;	 bx = file handle (if not label)
;	else 
;	 ax = error code
;	  error_path_not_found -  invalid path specified
;		    path not found
;		    invalid file name specified
;	  error_access_denied - the root directory is full
;		    the disk is full
;		    see attribute discussion below
;	  error_too_many_open_files - too many files open
;	 & critical error codes
;	 cx = error code if b15 of ax is set
;,fe
;======================================================================
	assume	ds:grp,es:nothing,ss:tcb
public hl_create
lproc	hl_create
lword	bufptr				; pointer to sector buffer
lbyte	clvl				; cumulative access level into parent
lstring clsmap,<size tcbcmap>		; copy of class map for task
lstring fnm,11				; dir entry formatted file name
lstring secbuf,<size sectorblk>		; sector number buffer
lbyte	openmode			; open mode byte
lbyte	newonly				; != 0 if to create new only
	mov	[openmode],al
	mov	[newonly],ah
	push	di
	lea	si,[tcbcmap]		; copy tcbcmap -> clsmap
	lea	di,[clsmap]		; save original class access map
	call	cpycmap
	pop	di
	call	noswt			; no task switches allowed

; validate attribute

	test	cl,not ( arch or dir or lbl or sys or hid or ro )
	mov	ax,error_access_denied
	jnz	hlc040			; fail if any invalid attribute bit set
	mov	[fnm],' '		; to check for null path (drive only)
	lea	si,fnm
	lea	bx,secbuf
	push	cx
	mov	al,1			; skip labels
	test	cl,lbl
	jz	hlc010
	xor	al,al			; unless specified in entry cx
hlc010:
	call	pathfind
	mov	[bufptr],bx
	mov	[clvl],cl
	pop	cx
	assume	ds:bdb,es:dbb
	jc	hlc050			; error or name not in directory
	cmp	al,'?'
	mov	ax,error_access_denied
	je	hlc040			; no wild-cards allowed
	or	bx,bx
	jz	hlc060			; name refers to a device
	cmp	dx,-1
	je	hlc040			; root dir is invalid file to create

; if supposed to create a volume label, make sure pathfind doesn't
; find a file by the same name.

	test	cl,lbl
	jz	hlc030
hlc020:
	assume	es:dbb
	test	[dbbbuf+si+datr],lbl
	jnz	hlc030			; fail if not a label
	mov	di,ss
	mov	es,di
	lea	di,fnm			; when find a file
	add	si,32			; must keep checking
	lea	bx,secbuf
	call	nextnm
	jc	hlc050			; exit loop when can't find more
	jmp	short hlc020
hlc030:
	mov	ax,error_file_exists
	cmp	[newonly],0
	jne	hlc040
	mov	ah,[clvl]
	push	cx
	call	truncguts
	pop	cx
	jnc	hlc060
hlc040:
	jmp	short hlc090

; no dir entry with that name, create a new one with supplied attrib

hlc050:
	cmp	ax,error_file_not_found
	jne	hlc090			; some error other than not found
	mov	ax,error_path_not_found
	cmp	[fnm],' '
	je	hlc090			; drive was only path item supplied
	push	ss
	pop	es
	assume	es:tcb
	mov	ah,[clvl]
	lea	di,[fnm]
	call	creatguts
	jc	hlc090
	call	eblcmap			; enable access to all classes
hlc060:

; open file and return handle

	mov	al,[openmode]
	mov	ah,[clvl]
	mov	bx,[bufptr]
	call	openfile
	pushf
	push	si
	push	di
	lea	si,[clsmap]		; restore original class access map
	lea	di,[tcbcmap]		; copy clsmap -> tcbcmap
	call	cpycmap
	pop	di
	pop	si
	popf
	jc	hlc090
	assume	es:tfb
	call	getphdl			; get free handle from psp table
	mov	ax,[tfbhdl]
	xchg	ax,bx
	jc	hlc070			; c if no room in psp table (no error)
	xchg	ax,bx
	call	setphdl			; set system handle into psp table
	jnc	hlc070
	mov	bx,[tfbhdl]		; c if tfbhdl is a system handle (no error)
hlc070:
	mov	[tfbfnh],bx
	mov	ds,[tfbgfb]
	assume	ds:gfb
	cmp	[gfbdev],0
	jne	hlc080
	mov	[gfbwrtn],'Y'
	or	[tfbioctl],40h		; signal file has been written (if not device)
hlc080:
	xor	ax,ax			; no error

; no error recovery - if new entry, we didn't succeed in adding it
; if truncated, we lost the allocation chain anyway

	assume	ds:nothing,es:nothing,ss:tcb
hlc090:
	mov	cx,error_path_not_found
	call	okswt
lundef	bufptr
lundef	clvl
lundef	clsmap
lundef	fnm
lundef	secbuf
lundef	openmode
lundef	newonly
lendp	hl_create

	subttl mosfun3c - create a file (creat)
	page
;======================================================================
;,fs
; mosfun3c - create a file (creat)
;
; file is opened in compatibility sharing mode with read/write access
;
; access permission established as follows:
;
; bits 15-6 - invalid bits
;   if set in creat attribute
;     then access denied
;   else
;     bit 5 - 20h - archive bit
;	ignored
;     bit 3 - 08h - volume label bit
;	if set in creat attribute
;	  then
;	    if set in any root dir entry
;	      then access denied
;	else
;	  bit 4 - 10h - sub-directory bit
;	    if set in creat attribute or dir entry
;	      then access denied
;	    else
;	      bit 0 - 01h - read-only bit
;		if set in the dir entry
;		  then access denied
;		else
;		  bit 2 - 04h - system bit
;		    if set in the dir entry
;		      if clear in the creat attribute
;			then access denied
;		  bit 1 - 02h - hidden bit
;		    if set in the dir entry
;		      if clear in the creat attribute
;			then access denied
;
; file creation as follows:
;
; bit 3 - 08h - volume label bit
;   if set in creat attribute
;     then
;	create the file in the root dir
;	set bit 3 of attribute
;   else
;     create the file according to the path
;     bit 2 - 04h - system bit
;	if set then set bit 2 of attribute
;     bit 1 - 02h - hidden bit
;	if set then set bit 1 of attribute
;     bit 0 - 01h - read-only bit
;	if set then set bit 0 of attribute
; bit 5 - 20h - archive bit
;   set bit 5 of attribute
;
; in:	tds:tdx -> asciiz string with drive, path and file to create
;	tcx = attribute for created file
;
; out:	carry bit of tflag set if error
;	 tax = error code
;	  error_path_not_found -  invalid path specified
;		    path not found
;		    invalid file name specified
;	  error_access_denied - the root directory is full
;		    the disk is full
;		    see attribute discussion below
;	  error_too_many_open_files - too many files open
;	 & critical error codes
;	carry bit of tflag clear if no error
;	tax = file handle (if not label)
;
;,fe
;======================================================================
	assume	ds:grp,es:nothing,ss:tcb
mosfun3c proc near
	mov	al,2			; setup for read-write access
	test	[tcx],ro
	jz	f3c_1
	dec	al
f3c_1:
	mov	ah,0			; newonly = 0
	mov	es,[tds]
	mov	di,[tdx]
	mov	cx,[tcx]
	call	hl_create
	or	ax,ax
	jnz	f3c_2
	mov	[tax],bx
f3c_2:
	call	moserror
	ret
mosfun3c endp

	subttl validate_acc - check the open mode
	page
;======================================================================
;,fs
; validate_acc - check the open mode
;
; in:	al = the open mode
;
; out:	cy if bad
;	 ax = error code
;	nc if ok
;	 entry ax preserved
;
;,fe
;======================================================================
	assume	ds:grp,es:nothing,ss:tcb
validate_acc proc near
	push	bx
	push	cx
	mov	cx,ax
	mov	bl,al			; remember access
	mov	bh,al
	mov	ax,error_invalid_access
	test	bl,8			; invalid bit
	jnz	vac_2
	and	bl,07h
	cmp	bl,3
	jae	vac_2			; invalid access requested
	and	bh,70h
	cmp	bh,50h
	jae	vac_2			; invalid share mode requested
	clc
	mov	ax,cx
	jmp	short vac_2
vac_1:
	stc
vac_2:
	pop	cx
	pop	bx
	ret
validate_acc endp

	subttl hl_open - high level open logic
	page
;======================================================================
;,fs
; hl_open - high level open logic
;
; in:	es:di -> asciiz string with drive, path and file to open
;	al = open mode
;	 bit 7 = 0 - inherited by child processes
;		 1 - or not
;	 bits 6-4 = 000 - compatibility mode
;		    001 - deny read/write (nothing ok)
;		    010 - deny write (read ok)
;		    011 - deny read (write ok)
;		    100 - deny none (read, write, read/write all ok)
;	 bit 3 = 0 (reserved)
;	 bits 2-0 = 000 - read only access required
;		    001 - write only access required
;		    010 - read and write access required
;	cl = inc_tfblvl flag
;
; out:	ax = 0 if no error
;	 bx = handle
;	else
;	 ax = error code
;	  error_path_not_found -  invalid path specified
;		    path not found
;		    invalid file name specified
;	  error_file_not_found -  file not found
;	  error_access_denied - can't grant requested access
;		    can't restrict access as requested
;	  invvacc - invalid access code
;	  error_too_many_open_files - too many files open
;	  & critical errors
;
;,fe
;======================================================================
	assume	ds:grp,es:nothing,ss:tcb
public hl_open
lproc	hl_open
lbyte	clvl				; cumulative access level into parent
lbyte	access				; attribute for created file
lword	pseg				; if device, seg for driver
lstring fnm,11				; dir entry formatted file name
lstring secbuf,<size sectorblk>		; buffer for sector number
lbyte	inc_tfblvl
	mov	[inc_tfblvl],cl
	mov	[access],al
	mov	word ptr [tcbopen60+2],es
	mov	word ptr [tcbopen60],di
	call	noswt			; no task switches allowed

; validate drive, path and name and look up name in dir

	lea	si,fnm
	lea	bx,secbuf
	mov	al,1			; skip labels
	call	pathfind
	mov	[clvl],cl
	assume	ds:bdb,es:nothing
	jc	hlo010
	call	ckexcl			; check for exclusion from except/only
	jnc	hlo020
	mov	ax,error_access_denied
hlo010:
	jmp	hlo060
hlo020:
	cmp	al,'?'
	mov	ax,error_file_not_found
	je	hlo010			; no wild-cards allowed
	mov	[pseg],es		; (if a device, then segment for driver)
	or	bx,bx
	jz	hlo030			; name refers to a device

; found a dir entry, check attribute

	mov	ax,error_access_denied
	cmp	dx,-1
	je	hlo010
	assume	es:dbb
	mov	ax,error_access_denied
	test	[dbbbuf+si+datr],lbl or dir
	jnz	hlo010			; no good if it's a label or directory
	test	[access],07h
	jz	hlo030			; else ok if only need read access to the file
	test	[dbbbuf+si+datr],ro
	jnz	hlo010			; else must not be a read-only file
hlo030:

; open file and return handle

	mov	al,[access]		; compatibility sharing, read/write,
	mov	es,[pseg]
	assume	es:nothing
	mov	ah,[clvl]
	call	openfile
	jc	hlo060
	assume	es:tfb
	cmp	[inc_tfblvl],1
	jne	hlo040
	inc	[tfblvl]
hlo040:
	call	getphdl			; get free handle from psp table
	mov	ax,[tfbhdl]
	xchg	ax,bx
	jc	hlo050			; c if no room in psp table (no error)
	xchg	ax,bx
	call	setphdl			; set system handle into psp table
	jnc	hlo050
	mov	bx,[tfbhdl]		; c if tfbhdl is a system handle (no error)
hlo050:
	mov	[tfbfnh],bx
	assume	ds:nothing,es:nothing,ss:tcb
	xor	ax,ax
hlo060:
	mov	cx,error_access_denied
	call	okswt
lundef	clvl
lundef	pseg
lundef	access
lundef	fnm
lundef	secbuf
lundef	inc_tfblvl
lendp	hl_open

	subttl mosfun3d - open a file
	page
;======================================================================
;,fs
; mosfun3d - open a file
;
; in:	tds:tdx -> asciiz string with drive, path and file to open
;	tal = open mode
;	 bit 7 = 0 - inherited by child processes
;		 1 - or not
;	 bits 6-4 = 000 - compatibility mode
;		    001 - deny read/write (nothing ok)
;		    010 - deny write (read ok)
;		    011 - deny read (write ok)
;		    100 - deny none (read, write, read/write all ok)
;	 bit 3 = 0 (reserved)
;	 bits 2-0 = 000 - read only access required
;		    001 - write only access required
;		    010 - read and write access required
;
; out:	carry bit of tflag set if error
;	 tax = error code
;	  error_path_not_found -  invalid path specified
;		    path not found
;		    invalid file name specified
;	  error_file_not_found -  file not found
;	  error_access_denied - can't grant requested access
;		    can't restrict access as requested
;	  invvacc - invalid access code
;	  error_too_many_open_files - too many files open
;	  & critical errors
;	carry bit of tflag clear if no error
;	 tbx = handle of opened file
;
;,fe
;======================================================================
	assume	ds:grp,es:nothing,ss:tcb
mosfun3d proc near
	xor	cl,cl
	mov	dx,[mo1seg]		; this is the mos group segment address
	cmp	dx,[tcs]		; test if exec did it
	jne	f3d_1
	cmp	[tip],offset mos:execopen
	jne	f3d_1
	inc	cl
f3d_1:
	mov	es,[tds]
	mov	di,[tdx]
	mov	al,[tal]
	call	validate_acc
	jc	f3d_2
	call	hl_open
	or	ax,ax
	jnz	f3d_2
	mov	[tax],bx		; return handle
f3d_2:
	call	moserror
	ret
mosfun3d endp

	subttl mosfun3e - close a file handle
	page
;======================================================================
;,fs
; mosfun3e - close a file handle
;
; in:	tbx = handle for file or device to close
;
; out:	carry bit of tflag set if error
;	 tax = error code
;	  error_invalid_handle - invalid handle specified
;	  & critical errors
;	carry bit of tflag clear if no error
;
;,fe
;======================================================================
	assume	ds:grp,es:nothing,ss:tcb
lproc	mosfun3e
	call	usts1
	jc	mosf3ex			; (invalid handle if not found)
	assume	es:tfb
	mov	ax,0ffffh		; delete handle from tfb handle list
	call	setphdl			; don't bother checking for error
	call	closefile		; all the hard stuff
mosf3ex:
	mov	dx,6			; return code
	mov	cx,error_invalid_handle
	call	repo0
lendp	mosfun3e

	subttl mosfun3f - read from a file or device
	page
;======================================================================
;,fs
; mosfun3f - read from a file or device
;
; in:	tbx = handle for file or device to read
;	tds:tdx -> buffer to read into
;	tcx = byte length to read
;
; out:	carry bit of tflag set if error
;	 tax = error code
;	  error_invalid_handle - invalid handle specified
;	  error_access_denied - file opened for write only
;	  & critical errors
;	carry bit of tflag clear if no error
;	 tax = number of bytes read (0 implies eof)
;
;,fe
;======================================================================
	assume	ds:grp,es:nothing,ss:tcb
lproc	mosfun3f
	call	rwdevs			; read/write device setup
	pushf				; make sure you save the flags
	xor	cx,cx			; set # of bytes read if error
	popf
	jc	mosf3fx			; (invalid handle)
	assume	es:tfb
	mov	cx,di
	call	readguts
mosf3fx:
	call	stnbyt			; set number of bytes read into tax
	assume	ds:nothing,es:nothing,ss:tcb
	mov	cx,error_access_denied
	call	repo1			; report
lendp	mosfun3f

	subttl mosfun40 - write to a file or device
	page
;======================================================================
;,fs
; mosfun40 - write to a file or device
;
; in:	tbx = handle for file or device to write
;	tds:tdx -> buffer to write from
;	tcx = byte length to write (0 to truncate at current position)
;
; out:	carry bit of tflag set if error
;	 tax = error code
;	  error_invalid_handle - invalid handle specified
;	  error_access_denied - file opened for read only
;	  & critical errors
;	carry bit of tflag clear if no error
;	 tax = number of bytes written (tax <> tcx implies disk full)
;
;,fe
;======================================================================
	assume	ds:grp,es:nothing,ss:tcb
lproc	mosfun40
	call	rwdevs
	jc	mosf40x			; (invalid handle)
	assume	es:tfb
	mov	cx,di

	push	es
	call	writeguts
	pop	es

; if no error from writeguts and tfb6ccom is set, do a commit operation.
; tfb6ccom would be set by i21f6c.

	jc	mosf40x
	cmp	[tfb6ccom],0
	je	mosf40x
	push	ds
	mov	ds,[tfbgfb]		; get tfb address.
	assume	ds:gfb
	mov	ds,[gfbbdb]		; finally, get the bdb for the file.
	assume	ds:bdb
	call	mediachk		; anyone remove the disk?
	mov	ax,error_wrong_disk
	jc	mosf40a
	call	flushdata		; flush the file to disk.
	jc	mosf40a
	xor	ax,ax			; mimic retval from writeguts
mosf40a:				; for non-error case
	pop	ds

; return number of bytes read in tax

mosf40x:
	call	stnbyt			; set number of bytes written
	assume	ds:nothing,es:nothing,ss:tcb
	mov	cx,error_access_denied
	call	repo1			; report results to caller
lendp	mosfun40

	subttl mosfun41 - delete a file from a specified directory (unlink)
	page
;======================================================================
;,fs
; mosfun41 - delete a file from a specified directory (unlink)
;
; in:	tds:tdx -> asciiz string with drive, path and file to delete
;
; out:	carry bit of tflag set if error
;	 tax = error code
;	  error_path_not_found -  invalid path specified
;		    path not found
;		    invalid file name specified
;	  error_file_not_found -  file not found
;	  error_access_denied - file is ro
;		    can't establish exclusive access
;	  & critical errors
;	carry bit of tflag clear if no error
;
;,fe
;======================================================================
	assume	ds:grp,es:nothing,ss:tcb
lproc	mosfun41
lstring fnm,11				; dir entry formatted file name
lstring secbuf,<size sectorblk>		; buffer for sector number
	call	usts0

; validate drive, path and name

	lea	si,fnm
	lea	bx,secbuf
	mov	al,1			; skip labels
	call	pathfind
	assume	ds:bdb,es:nothing
	jc	mosf41x
	cmp	al,'?'
	mov	ax,error_file_not_found
	je	mosf41x			; no wild-cards allowed
	xor	ax,ax			; no error if device (just don't do anything)
	or	bx,bx
	jz	mosf41x			; name refers to a device

; found a dir entry with that name, check its attribute

	mov	ax,error_access_denied
	cmp	cl,3			; must have read/write access to parent
	jb	mosf41x			;   to delete dir entry
	cmp	dx,-1
	jz	mosf41x			; can't unlink root dir
	assume	es:dbb
	test	[dbbbuf+si+datr],ro or lbl or dir
	jnz	mosf41x			; must not be read-only or label or directory
	call	ckexcl			; check for exclusion from except/only
	jnc	noex2
	mov	ax,error_access_denied
	jmp	short mosf41x
noex2:
	mov	al,[dbbbuf+si+dclass0]
	call	classlvl		; must have read/write access to dir entry
	cmp	al,3			;   to delete it
	mov	ax,error_access_denied
	jb	mosf41x

; must be able to establish exclusive access to file

	call	exclude
	jc	mosf41x

; go ahead and delete it

mosf41a:
	call	delete
	jc	mosf41x
	call	flushdir
	jc	mosf41x
	xor	ax,ax
	assume	ds:nothing,es:nothing,ss:tcb
mosf41x:
	mov	cx,error_path_not_found
	call	repo1			; report
lundef	fnm
lundef	secbuf
lendp	mosfun41

	subttl mosfun42 - move file read/write pointer (lseek)
	page
;======================================================================
;,fs
; mosfun42 - move file read/write pointer (lseek)
;
; in:	tbx = file handle
;	tcx:tdx = length to move pointer
;	tal = method (0 from beginning of file, 1 from current position
;		2 from end of file)
;
; out:	carry bit of tflag set if error
;	 tax = error code
;	  error_invalid_function	 - invalid method specified
;	  error_invalid_handle - invalid handle specified
;	carry bit of tflag clear if no error
;	 tdx:tax = new file position
;
;,fe
;======================================================================
	assume	ds:grp,es:nothing,ss:tcb
lproc	mosfun42
lword	tfbseg
lbyte	method
ldword	distance
	mov	si,bp
	mov	bp,[bp]
	mov	cl,[tal]
	mov	bx,[tbx]		; handle of file to seek
	mov	ax,[tdx]
	mov	dx,[tcx]
	mov	bp,si
	call	noswt			; no task switches allowed
	mov	[method],cl
	mov	word ptr [distance],ax
	mov	word ptr [distance+2],dx
	call	findtfb			; locate tfb corresponding to file handle
	mov	ax,error_invalid_handle
	jc	mosf42x			; (invalid handle)
	assume	es:tfb
	mov	[tfbseg],es

; offset from beginning of file if method = 0

	xor	dx,dx
	mov	cx,dx
	mov	al,[method]
	or	al,al
	jz	mosf42a

; offset from current position if method = 1

	mov	dx,word ptr [tfbpos]
	mov	cx,word ptr [tfbpos+2]
	dec	al
	jz	mosf42a

; offset from end of file if method = 2

	mov	es,[tfbgfb]
	assume	es:gfb
	mov	dx,word ptr [gfbsize]
	mov	cx,word ptr [gfbsize+2]
	dec	al
	mov	ax,error_invalid_function
	jnz	mosf42x			; error if method > 2
mosf42a:

; add distance to offset and record as new file position

	add	dx,word ptr [distance]
	adc	cx,word ptr [distance+2]
	mov	es,[tfbseg]
	assume	es:tfb
	mov	word ptr [tfbpos],dx	; new current position
	mov	word ptr [tfbpos+2],cx
	mov	bx,bp
	mov	bp,[bp]
	mov	[tax],dx		; and return it
	mov	[tdx],cx
	mov	bp,bx
	xor	ax,ax
	assume	ds:nothing,es:nothing,ss:tcb
mosf42x:
	mov	cx,error_invalid_handle
	call	repo1			; report code
lundef	tfbseg
lundef	method
lundef	distance
lendp	mosfun42

	subttl mosfun43 - change file mode (chmod)
	page
;======================================================================
;,fs
; mosfun43 - change file mode (chmod)
;
; in:	tds:tdx -> asciiz string with drive, path and file to change mode
;	tcx = attribute to change to
;	tal = 0 return attribute
;	    = 1 set attribute
;
; out:	carry bit of tflag set if error
;	 tax = error code
;	  error_path_not_found -  invalid path specified
;		    path not found
;		    invalid file name specified
;	  error_file_not_found -  file not found or name specifies a device
;	  error_access_denied - attribute of found file is dir or lbl or invalid
;	  error_invalid_function -   invalid function specified
;	 & critical errors
;	carry bit of tflag clear if no error
;	 tcx = current attribute
;
;,fe
;======================================================================
	assume	ds:grp,es:nothing,ss:tcb
lproc	mosfun43
lbyte	function			; 0 = get attribute, 1 = set attribute
lbyte	fattrib				; current attribute of file
lword	attrib				; new attribute for file
lstring fnm,11				; dir entry formatted file name
lstring secbuf,<size sectorblk>		; buffer for sector number
	mov	bx,bp
	mov	bp,[bp]
	mov	cx,[tcx]
	mov	es,[tds]
	mov	di,[tdx]
	mov	al,[tal]
	mov	bp,bx
	call	noswt			; no task switches allowed

; validate drive, path and name

	mov	[function],al
	mov	[attrib],cx
	lea	si,fnm
	lea	bx,secbuf
	mov	al,1			; skip labels
	call	pathfind
	assume	ds:bdb,es:nothing
	jc	jmosf43x
	cmp	al,'?'
	mov	ax,error_file_not_found
	je	jmosf43x		; no wild-cards allowed
	or	bx,bx
	jz	jmosf43x		; name refers to a device

; found a dir entry with that name, check its attribute

	mov	al,10h			; report a directory if root
	cmp	dx,-1
	je	mosf43c
	call	rddir
	jc	jmosf43x
	assume	es:dbb
	mov	al,[dbbbuf+si+datr]
	mov	[fattrib],al		; save file's real attribute
mosf43c:
	cmp	[function],0
	je	mosf43b
	mov	ax,error_invalid_function
	cmp	[function],1
	jne	jmosf43x

; setting attribute

	mov	ax,error_access_denied
	cmp	dx,-1
	je	jmosf43x		; can't set attributes on root dir
	assume	es:dbb
	cmp	cl,3			; must have read/write access to parent
	jb	jmosf43x		;   to change attributes of dir entry
	call	ckexcl			; check exclusion from except/only
	jnc	noex3
	mov	ax,error_access_denied
jmosf43x:
	jmp	short mosf43x
noex3:
	mov	al,[dbbbuf+si+dclass0]
	call	classlvl		; must have read/write access to dir/entry
	cmp	al,3			;   to change its attributes
	mov	ax,error_access_denied
	jb	mosf43x
	test	[attrib],not ( arch or sys or hid or ro )
	jnz	mosf43x			; invalid or dir or lbl attributes

; make new file attribute.

	mov	al,byte ptr [attrib]
	mov	ah,[fattrib]		; current file attribute
	and	ah,dir or lbl		; toss all old bits but dir & lbl bit
	or	al,ah			; put old dir & lbl bits into new attribute
	mov	byte ptr [attrib],al
	mov	di,es
	call	findgfb			; set attribute in gfb
	assume	es:gfb
	mov	ax,[attrib]
	jc	mosf43a			; no gfb found
	mov	[gfbattr],al
mosf43a:				; and in directory entry
	mov	es,di
	assume	es:dbb
	mov	[dbbbuf+si+datr],al
	call	wrsector
	jc	mosf43x
	call	flushdir
	jc	mosf43x
	xor	ax,ax
	jmp	short mosf43x

; getting attribute (already in al)

mosf43b:
	xor	ah,ah
	mov	bx,bp
	mov	bp,[bp]
	mov	[tcx],ax
	mov	bp,bx
	xor	ax,ax
	assume	ds:nothing,es:nothing,ss:tcb
mosf43x:
	mov	cx,error_path_not_found
	call	repo1			; report code
lundef	function			; 0 = get attribute, 1 = set attribute
lundef	fattrib				; old file attribute
lundef	attrib				; new attribute for file
lundef	fnm				; dir entry formatted file name
lundef	secbuf
lendp	mosfun43

	subttl mosfun45 - duplicate a file handle (dup)
	page
;======================================================================
;,fs
; mosfun45 - duplicate a file handle (dup)
;
; in:	tbx = file handle to duplicate
;
; out:	carry bit of tflag set if error
;	 tax = error code
;	  error_invalid_handle - invalid handle specified
;	  error_too_many_open_files - too many files open
;	  syshdl - attempt to dup a non-psp handle
;	 & critical errors
;	carry bit of tflag clear if no error
;	 tax = new handle
;
;,fe
;======================================================================
	assume	ds:grp,es:nothing,ss:tcb
lproc	mosfun45
lword	tfbseg
	call	usts1
	jc	mosf45x			; (invalid handle)
	assume	es:tfb
	call	getphdl			; returns bx = free handle
	jc	mosf45x			; no free psp handles available or sys handle
	mov	ax,[tfbhdl]
	call	setphdl			; set bx handle in psp to tfbhdl
	jc	mosf45x			; trying to dup a system handle
	inc	[tfbopen]		; else another instance now exists
	mov	ax,bp
	mov	bp,[bp]
	mov	[tax],bx		; return new handle to application
	mov	bp,ax
	xor	ax,ax
	assume	ds:nothing,es:nothing,ss:tcb
mosf45x:
	mov	cx,error_invalid_handle
	call	repo1
lundef	tfbseg
lendp	mosfun45

	subttl mosfun46 - force a duplicate of a handle (forcdup)
	page
;======================================================================
;,fs
; mosfun46 - force a duplicate of a handle (forcdup)
;
; in:	tbx = file handle to duplicate
;	tcx = file handle to force (if active file, it is closed first)
;
; out:	carry bit of tflag set if error
;	 tax = error code
;	  error_invalid_handle - invalid handle specified
;	  error_too_many_open_files - too many files open
;	  syshdl - attempt to dup from/to a non-psp handle
;	 & critical errors
;	carry bit of tflag clear if no error
;
;,fe
;======================================================================
	assume	ds:grp,es:nothing,ss:tcb
lproc	mosfun46
lword	tfbseg
	mov	ax,bp
	mov	bp,[bp]
	mov	cx,[tbx]		; handle of file to duplicate
	mov	bx,[tcx]		; handle to refer to file also
	mov	bp,ax
	call	noswt			; no task switches allowed
	mov	ax,error_invalid_handle
	call	findtfb			; find tfb for second handle
	jc	mosf46a			; c if not in use
	mov	ax,0ffffh		; delete handle from tfb's handle list
	call	setphdl			; don't bother checking for error
	call	closefile		; second handle in use, close the file first
	jc	mosf46x
mosf46a:
	push	bx
	mov	bx,cx
	call	findtfb			; locate tfb corresponding to first file handle
	pop	bx
	mov	ax,error_invalid_handle
	jc	mosf46x			; (invalid handle)
	assume	es:tfb
	mov	ax,[tfbhdl]
	call	setphdl			; set second file handle to it
	jc	mosf46x			; tried to fdup from or to a system handle
	inc	[tfbopen]		; else another instance now exists
	xor	ax,ax
	assume	ds:nothing,es:nothing,ss:tcb
mosf46x:
	mov	cx,error_invalid_handle
	call	repo1
lundef	tfbseg
lendp	mosfun46

	subttl mosfun47 - get current directory
	page
;======================================================================
;,fs
; mosfun47 - get current directory
;
; mjs 01/08/87	if no error, must return tax = 0100.  this is 
;		required by the lotus 123 v2.0 install.exe program.
;
; sah 08/15/88	check to see if current path is actually valid.	 
;		if it is a floppy, some could change it on us.	
;		we should have already catch this problem.
;
; in:	tds:tsi -> 64-byte buffer to return asciiz current dir string
;	tdl = drive number of current dir (0=default drive)
;
; out:	carry bit of tflag set if error
;	 tax = error code
;	  error_invalid_drive - invalid drive specified
;	carry bit of tflag clear if no error
;
;,fe
;======================================================================
	assume	ds:grp,es:nothing,ss:tcb
lproc	mosfun47
lstring fnm,11
lstring secbuf,<size sectorblk>
lstring temp,64				; temporary space for path
lbyte	drv47				; temporary space for drive
	mov	bx,bp
	mov	bp,[bp]
	mov	dl,[tdl]		; drive for current dir (0=default)
	mov	es,[tds]		; pointer to buffer for current dir string
	mov	di,[tsi]
	mov	bp,bx
	call	noswt
	mov	al,[tcbcdriv]
	or	dl,dl
	jz	mosf47a0
	mov	al,dl
	dec	al
mosf47a0:
	mov	[drv47],al
	call	finddrv
	jc	mosf47x
	mov	ds,cx
	assume	ds:cdb
mosf47b:
	lea	si,cdbpath

; check to see if path return is valid and make sure it exist on disk
; this is done just in case somebody changes drives on us

	push	si
	push	di
	push	es
	push	ds
	push	ss
	pop	es
	mov	al,[drv47]		; get drive
	add	al,'A'
	lea	di,temp			; use temporary space on stack
	stosb
	mov	al,':'
	stosb
	mov	al,'\'
	stosb
	mov	cx,60/2			; 61 = 60+1
	rep	movsw			; transfer entry
	movsb
	lea	di,temp
	mov	[fnm],' '		; only path validation
	lea	si,fnm
	lea	bx,secbuf
	mov	al,1			; skip labels
	call	pathfind
	pop	ds
	pop	es
	pop	di
	pop	si
	jnc	mosf47c			; path is ok so use it
	mov	byte ptr [si],0		; place it root
mosf47c:
	lodsb
	stosb
	or	al,al
	jnz	mosf47c
	xor	ax,ax			; no error
	assume	ds:nothing,es:nothing,ss:tcb
mosf47x:
	mov	cx,error_invalid_drive
	mov	dx,100h			; return ax = 0100 if no error
	call	repo0
lundef	drv47
lundef	temp
lundef	fnm
lundef	secbuf
lendp	mosfun47

	subttl mosfun4e - find first matching file (find first)
	page
;======================================================================
;,fs
; mosfun4e - find first matching file (find first)
;
; dta filled in as follows:
;
;     offset 00h 21 bytes reserved
;	     00h byte	  file drive (a=1)
;	     01h 11 bytes search name
;	     0ch byte	  search attribute
;	     0dh word	  offset in sector of dir entry of found file
;			    (note: dos is entry number within cluster)
;	     0fh word	  sector number of dir entry of found file
;			    (note: dos is cluster number)
;	     11h 4 bytes  0's (not used)
;	     15h byte	  found file's attribute
;	     16h word	  found file's time
;	     18h word	  found file's date
;	     1ah dword	  found file's length
;	     1eh 13 bytes foundfile's name and extension followed by 0
;
; mjs 03/10/87	if successful operation then tal should return 0.
;		this is needed by pfs first choice
;
; in:	tds:tdx -> asciiz string with drive/path/file to be found
;	tcx = attribute to use during search
;	if tcx = 8 find only volume label
;	else
;	 match all files without hidden, system or read-only attributes
;	 additionaly match files with those attributes if the respective
;	 bit is set in tcx
;
; out:	carry bit of tflag set if error
;	 tax = error code
;	  error_path_not_found - invalid path specified
;		   path not found
;		   invalid file name
;	  error_no_more_files - no matching files
;	 & critical error codes
;	carry bit of tflag clear if no error
;
;,fe
;======================================================================
	assume	ds:grp,es:nothing,ss:tcb
lproc	mosfun4e
lword	attrib				; attribute of matching files
lstring fnm,11				; dir entry formatted file name
lstring secbuf,<size sectorblk>		; buffer for sector number
	mov	bx,bp
	mov	bp,[bp]
	mov	cx,[tcx]
	mov	es,[tds]
	mov	di,[tdx]
	mov	bp,bx
	call	noswt			; no task switches allowed
	mov	[attrib],cx

; validate drive, path and name

mosf4ea:
	lea	si,fnm
	lea	bx,secbuf
	mov	al,1			; skip labels
	test	cx,lbl
	jz	mosf4ea0
	xor	al,al
mosf4ea0:
	call	pathfind
	assume	ds:bdb,es:nothing
	jc	jmosf4ex
	mov	ax,error_no_more_files
	cmp	dx,-1
	je	jmosf4ex		; name refers to root dir

; see if it's a search for a label (and look in root if so)

	mov	al,byte ptr [attrib]
	or	bx,bx
	jz	mosf4ee
	and	al,hid or dir or lbl
	cmp	al,lbl
	jne	mosf4eb
	cmp	[bdbalias],0		; is this an alias device?
	je	mosf4ea1		; if not an alias drive, it can have a label
	mov	ax,error_file_not_found	; make search fail if alias drive
jmosf4ex:
	jmp	mosf4ex
mosf4ea1:
	push	ss
	pop	es
	lea	di,[fnm]
	mov	dx,[bdbdir]
	mov	[secbuf].seclow,dx
	xor	dx,dx
	mov	[secbuf].sechigh,dx
	lea	bx,[secbuf]
	xor	si,si
	call	nextnm
	jc	jmosf4ex		; none found
mosf4eb:

; found a dir entry with that name, check its attribute

	assume	es:dbb
	mov	al,byte ptr [attrib]
	mov	cl,al
	and	cl,(hid or dir or lbl)
	mov	ch,[dbbbuf+si+datr]
	and	ch,(hid or dir or lbl)
	cmp	cl,lbl
	jne	mosf4ec			; not specifically looking for a label
	test	ch,lbl
	jnz	mosf4ee			; nz if found the label
	jmp	mosf4ed			; else not found if specifically looking
mosf4ec:
	and	cl,ch			; else found bits must be set in search
	cmp	cl,ch			;   attribute
	jne	mosf4ed			; e if found the one we're looking for
	test	al,override
	jnz	mosf4ee			; class override for dir search
	call	ckexcl			; check for exclusion
	jc	mosf4ed
	push	ax			; else make sure this tcb can look at dir
	mov	al,[dbbbuf+si+dclass0]
	call	classlvl		; entries of this class
	or	al,al
	pop	ax
	jnz	mosf4ee			; class access ok if not deny access
mosf4ed:

; if wrong attribute, get the next

	push	ss
	pop	es
	assume	es:tcb
	lea	di,fnm
	add	si,32
	lea	bx,[secbuf]
	call	nextnm
	jnc	mosf4eb
	jmp	short mosf4ex

; fill out dma area with found entry
; es = segment of dbb for dir sector
; ss:bx -> sector number
; si =offset
; al = attribute for search

mosf4ee:
	mov	ah,al
	mov	al,[bdbid]
	inc	al
	push	es
	pop	ds
	assume	ds:dbb
	les	di,dword ptr [tcbdta]
	assume	es:nothing
	stosb
	push	ds
	push	si
	push	ss
	pop	ds
	lea	si,fnm
	mov	cx,11
	rep	movsb
	pop	si
	pop	ds
	mov	al,ah
	stosb
	mov	al,4eh			; setup to clear function reserved bytes - sjc
	lea	bx,[secbuf]
	call	dta4e			; fill out rest of dta with found file stuff
	xor	ax,ax
	call	sttax0			; return zero in task ax
	assume	ds:nothing,es:nothing,ss:tcb
mosf4ex:
	cmp	ax,error_file_not_found
	jne	mosf4ey
	mov	ax,error_no_more_files
mosf4ey:
	mov	cx,error_no_more_files
	call	repo1
lundef	attrib
lundef	fnm
lundef	secbuf
lendp	mosfun4e

	subttl dta4e - fill out dta with data from dir entry
	page
;======================================================================
;,fs
; dta4e - fill out dta with data from dir entry
;
; fill out dta with data from found directory entry
;
; in:	si = ?
;	di = ?
;	ss:bx -> sector number
;
; out:	
;
;,fe
;======================================================================
	assume	ds:dbb,es:nothing,ss:tcb
dta4e:
	push	ax			; save reserved clear status - sjc
	mov	ax,si			; offset into sector of entry
	stosw
	mov	ax,ss:[bx].seclow	; sector address of entry
	stosw
	mov	ax,ss:[bx].sechigh	; high word of sector address
	stosw
	pop	ax			; retrieve reserved status - sjc
	cmp	al,4eh
	je	d4eclr
	inc	di			; bypass clear reserved bytes if not fun4e
	inc	di
	jmp	short d4enoc
d4eclr:
	xor	ax,ax
	stosw				; reserved
d4enoc:
	mov	ax,ss:[bx].seclow	; see if it's a device
	or	ax,ss:[bx].sechigh
	jnz	dta4ej1			; a device if 0
	mov	cx,9			; clear out rsrvd area
	rep	stosb			; (note al already 0)
	add	si,10			; if so ds:si -> driver header
	mov	cx,8/2			; copy driver name
	rep	movsw
	mov	cx,8
	mov	al,' '
	jmp	dta4e3			; strip trailing spaces
dta4ej1:				; else not a device
	mov	al,[dbbbuf+si+datr]
	stosb
	mov	ax,word ptr [dbbbuf+si+dtime]
	stosw
	mov	ax,word ptr [dbbbuf+si+ddate]
	stosw
	mov	ax,word ptr [dbbbuf+si+dsize]
	stosw
	mov	ax,word ptr [dbbbuf+si+dsize+2]
	stosw
	lea	si,[dbbbuf+si]
	mov	cx,4
	rep	movsw
	mov	cx,8
	mov	al,' '
dta4e1:
	dec	di
	cmp	al,es:[di]
	loope	dta4e1
	je	dta4e2
	inc	di
dta4e2:
	mov	al,'.'
	stosb
	movsw
	movsb
	mov	cx,3
	mov	al,' '
dta4e3:
	dec	di
	cmp	al,es:[di]
	loope	dta4e3
	jne	dta4e4
	dec	di
	cmp	byte ptr es:[di],'.'
	je	dta4e5
dta4e4:
	inc	di
dta4e5:
	xor	ax,ax
	stosb
	ret

	subttl mosfun4f - find next matching file (find next)
	page
;======================================================================
;,fs
; mosfun4f - find next matching file (find next)
;
; dam 01/10/87	if successful operation then tal should return 0.
;		this is needed by the public domain program sd.com v2.4
;
; in:	dta filled in from function 4eh or 4fh
;
; out:	carry bit of tflag set if error
;	 tax = error code
;	  error_no_more_files - no matching files
;	 & critical error codes
;	carry bit of tflag clear if no error
;	 dta filled in as in function 4eh
;
;,fe
;======================================================================
	assume	ds:grp,es:nothing,ss:tcb
lproc	mosfun4f
lbyte	attrib
lstring secbuf,<size sectorblk>
	call	noswt
	les	di,dword ptr [tcbdta]
	mov	al,es:[di]
	dec	al
	call	finddrv
	mov	ax,error_no_more_files
	jc	jmosf4fx
	assume	ds:bdb
	les	di,dword ptr [tcbdta]
	mov	al,es:[di+12]
	mov	[attrib],al
	mov	ax,error_no_more_files
	mov	si,es:[di+13]
	test	si,32-1
	jnz	jmosf4fx		; offset must be a dir entry boundary
	mov	dx,es:[di+17]
	mov	[secbuf].sechigh,dx
	mov	bx,es:[di+15]
	mov	[secbuf].seclow,bx
	cmp	si,[bdbssiz]
	jae	jmosf4fx		; and less than sector size
	or	dx,dx
	jnz	mosf410			; dir sector & data sector have high word 0
	cmp	bx,[bdbdir]
	jb	jmosf4fx		; sector must be >= first root sector
	cmp	bx,[bdbclus]
	jb	mosf4fa			; ok if in root directory ( < data clusters)
mosf410:

; else make sure its a valid data cluster

	xor	cx,cx
	sub	bx,[bdbclus]
	sbb	dx,cx
	mov	cl,[bdbcshl]
	jcxz	mosf430
mosf420:
	shr	dx,1
	rcr	bx,1
	loop	mosf420
mosf430:
	add	bx,2
	cmp	bx,[bdbcnum]
	jae	jmosf4fx		; and < max cluster
mosf4fa:
	les	di,dword ptr [tcbdta]
	inc	di			; -> name to find
	add	si,32
	lea	bx,[secbuf]		; point bx at sector buffer
	call	nextnm
	jnc	$+4
jmosf4fx:
	jmp	short mosf4fx

; found a dir entry with that name, check its attribute

	assume	es:dbb
	mov	al,byte ptr [attrib]
	and	al,(hid or dir or lbl)
	mov	ah,[dbbbuf+si+datr]
	and	ah,(hid or dir or lbl)
	cmp	al,lbl
	jne	mosf4fb			; ne if not looking specifically for label
	test	ah,lbl
	jnz	mosf4fc			; nz if found label
	jmp	mosf4fa			; else next if looking specifically
mosf4fb:
	and	al,ah			; else found bits must be set in search
	cmp	al,ah			;   attribute
	jne	mosf4fa
	test	byte ptr [attrib],override
	jnz	mosf4fc			; ok if level access overrride for dir search
	call	ckexcl			; check except/only list
	jc	mosf4fa
	mov	al,[dbbbuf+si+dclass0]
	call	classlvl
	or	al,al
	jz	mosf4fa			; ignore dir entry at deny access level
mosf4fc:

; fill out dma area with found entry
; es = segment of dbb for dir sector
; ss:bx -> sector number
; si = sector offset

	push	es
	pop	ds
	assume	ds:dbb
	les	di,dword ptr [tcbdta]
	assume	es:nothing
	lea	di,[di+13]
	lea	bx,[secbuf]
	mov	al,4fh			; set no clear reserved bytes - sjc
	call	dta4e
	xor	ax,ax
	call	sttax0
	assume	ds:nothing,es:nothing,ss:tcb
mosf4fx:
	cmp	ax,error_file_not_found
	jne	mosf4fy
	mov	ax,error_no_more_files
mosf4fy:
	mov	cx,error_no_more_files
	call	repo1
lundef	attrib
lundef	secbuf
lendp	mosfun4f

	subttl find_cdb - find a matching cdb for a drive number
	page
;======================================================================
;,fs
; find_cdb - find a matching cdb for a drive number
;
; search the list of cdb's to find match with drive in al
; enter with  es -> 1st cdb in list, al = drive to search for
; return with es->cdb for drive in al
;
; in:	
;
; out:	
;
;,fe
;======================================================================
	assume	ds:nothing,es:cdb,ss:nothing
find_cdb:
	cmp	[cdbdrive],al
	je	fcdb1
	mov	es,[cdbnext]
	jmp	find_cdb
fcdb1:
	ret

	subttl chk_pths - path checking for rename
	page
;======================================================================
;,fs
; chk_pths - path checking for rename
;
; before renaming a subdirectory, must make sure the target directory
; is not the current dir, or parent dir of any task.
; must also prohibit renaming a directory as a child of itself!
; enter with ds->bdb, es->dbb, ss->tcb, bx = tds, dx = tdx,
; si value from pathfind.  cx:di -> 2nd parm
; return with ax = 0 if ok, != 0 if conflict
;
; in:	
;
; out:	
;
;,fe
;======================================================================
	assume	ds:bdb, es:dbb, ss:tcb
lproc chk_pths
lstring refbuf,64			; reference buffer for subdir comparisons
lbyte	refdrv				; "    "    drive   "    "	"      "
lword	refptr				; pointer for 1st/2nd parm comparisons
lword	refcpth				; segment of cdb
	push	cx
	push	di
	mov	al,[bdbid]		; get drive of 1st parm
	mov	[refdrv],al
	mov	es,[tcbcdbpf]
	assume	es:cdb
	call	find_cdb
	mov	[refcpth],es		; find the current path for the drive
	mov	ds,bx
	assume	ds:nothing
	mov	si,dx
	cmp	byte ptr [si+1],':'
	jne	f56mjs3
	add	si,2
	add	dx,2
f56mjs3:
	push	ss
	pop	es
	assume	es:nothing
	lea	di,[refbuf]
	inc	si
	cmp	byte ptr [si-1],'\'
	je	f56mjs5
	mov	ds,[refcpth]
	push	ss
	pop	es
	assume	ds:cdb,es:nothing	; and stick it in refbuf first
	lea	si,[cdbpath]
	lea	di,[refbuf]
	cld
	cmp	byte ptr [si],0
	je	f56mjs4a
f56mjs4:
	lodsb
	stosb
	or	al,al
	jnz	f56mjs4
	mov	byte ptr es:[di-1],'\'
f56mjs4a:
	mov	ds,bx
	assume	ds:nothing
	mov	si,dx
f56mjs5:
	mov	[refptr],di
f56mjs5a:
	lodsb				; copy 1st parm into rebuf (after current
	callmos1 caps			; path, if there)
	stosb
	or	al,al
	jnz	f56mjs5a
	dec	di
	mov	cx,di
	lea	di,[refbuf]
	sub	cx,di			; calc length of string (not counting the 0)

; must make sure the 1st parm is not contained within the 2nd parm.
; when this situation is found, some idiot is trying to rename a dir
; as a child of itself.	 if we don't crash the party, bye bye files!

	pop	si			; push'ed as entry di
	pop	ds			; push'ed as entry cx   ds:si->2nd parm
	push	cx
	cmp	byte ptr [si],'\'
	jne	f56mjs5b		; if 2nd parm starts with a \ then
	inc	si			; compare with full 1st parm
	lea	di,[refbuf]
	jmp	f56mjs5c
f56mjs5b:				; else compare with 1st parm after
	lea	ax,[refbuf]		; the point where the current dir
	mov	bx,[refptr]		; was added
	mov	di,bx
	sub	bx,ax
	sub	cx,bx			; calc new comparison length
	push	ss
	pop	es
f56mjs5c:
	call	capscmps
	pop	cx			; when find a substring match, if next
	jne	f56mjs5d		; char in 2nd parm is a "\" then
	cmp	byte ptr [si],'\'	; have a conflict.  otherwise, have
	je	f56mjs8			; a case of the type "ren abc abcd" and
f56mjs5d:				; must not indicate an error
	mgetscb2 es
	assume	es:grp			; pass on to here when no substring match
	mov	ds,[scbtcbpf]
	assume	ds:tcb
f56mjs7:
	mov	es,[tcbcdbpf]
	assume	es:cdb
	mov	al,[refdrv]		; for each task, find the cdbpath
	call	find_cdb		; for the drive
	lea	di,[cdbpath]
	push	ds
	push	ss
	pop	ds
	lea	si,[refbuf]
	push	cx			; see if the 1st parm's path matches
	repe	cmpsb			; or is a substring of the current
	pop	cx			; path (for the drive) of any task
	pop	ds
	je	f56mjs8			; if find a match, error
	xor	ax,ax
	cmp	[tcbtcbpn],0
	je	f56mjs9			; all done, no matches
	mov	ds,[tcbtcbpn]
	jmp	f56mjs7
f56mjs8:
	mov	ax,error_access_denied	; return error if any task's current
f56mjs9:				; dir for the drive is the same as, or parent
					; of the 1st parm
	assume	ds:nothing,es:nothing
lundef	refbuf
lundef	refdrv
lundef	refptr
lundef	refcpth
lendp	chk_pths

	subttl mosfun56 - rename a file
	page
;======================================================================
;,fs
; mosfun56 - rename a file
;
; in:	tds:tdx -> asciiz drive, path, name to be renamed
;	tes:tdi -> asciiz drive, path and new name
;
; out:	carry bit of tflag set if error
;	 tax = error code
;	  error_path_not_found -  invalid path specified
;		    path not found
;		    invalid file name specified
;	  error_file_not_found -  file not found
;	  error_access_denied - second file exists
;	  error_not_same_device - not the same drive
;	carry bit of tflag clear if no error
;
;,fe
;======================================================================
	assume	ds:grp,es:nothing,ss:tcb
lproc	mosfun56
ldword	asciiz2				; -> second name
lstring fnm1,11				; dir entry formatted first name
lstring fnm2,32				; dir entry formatted second name
					;   (later has entire new dir entry)
lbyte	clvl				; cumulative level to destination parent dir
lword	dofs1				; offset in dir sector of first name
ldword	dsct1				; dir sector of first name
lword	clust1				; cluster of parent directory for first name
lword	clust2				; cluster of parent directory for second name
lstring secbuf,<size sectorblk>		; buffer for sector number
	mov	cx,bp
	mov	bp,[bp]
	mov	di,[tdx]
	mov	es,[tds]
	mov	ax,[tdi]
	mov	dx,[tes]
	mov	bp,cx
	call	noswt
	mov	word ptr [asciiz2],ax
	mov	word ptr [asciiz2+2],dx

; validate drive, path, name of first file

	lea	si,fnm1
	lea	bx,secbuf
	mov	al,1			; skip labels
	call	pathfind
	assume	ds:bdb,es:nothing
	jc	jmosf56x
	cmp	al,'?'
	mov	ax,error_file_not_found
	je	jmosf56x		; no wild-cards allowed
	or	bx,bx
	mov	ax,error_access_denied
	jz	jmosf56x		; name refers to a device
	cmp	cl,3			; must have read/write access to source parent
	jb	jmosf56x
	cmp	dx,-1
	je	jmosf56x		; can't rename root directory
	assume	es:dbb
	test	[dbbbuf+si+datr],lbl
	jnz	jmosf56x		; can't rename label
	mov	[clust1],dx
	push	ax
	mov	ax,[secbuf].seclow
	mov	word ptr [dsct1],ax
	mov	ax,[secbuf].sechigh
	mov	word ptr [dsct1+2],ax
	pop	ax
	mov	[dofs1],si
	call	ckexcl			; check exclusion
	jnc	noex5
	mov	ax,error_access_denied
jmosf56x:
	jmp	mosf56x
noex5:
	mov	al,[dbbbuf+si+dclass0]
	call	classlvl		; must have read/write access to source
	cmp	al,3			;   dir entry
	mov	ax,error_access_denied
	jb	jmosf56x

; must be able to establish exclusive access to first file

	call	exclude
	jc	jmosf56x
mosf56a:
	push	es
	les	di,[asciiz2]		; must check for globals in 2nd parm this
	call	chk_glbl		; way.	pathfind will return al == '?' when
	pop	es			; a matching file is found for a global
	or	ax,ax			; filespec, but when no match is found,
	jz	f56mjs2			; then ax == error_file_not_found
	jmp	mosf56x
f56mjs2:				; the bdb for first name is now the
	push	ds			; first thing on top of stack
	test	[dbbbuf+si+datr],dir
	jz	f56pthok
	mov	ax,bp
	mov	bp,[bp]
	mov	di,[tdi]		; cx:di -> second parm
	mov	cx,[tes]
	mov	dx,[tdx]
	mov	bx,[tds]		; when the first path is a directory, must
	mov	bp,ax			; make sure there is no conflict with the
	call	chk_pths		; current path of any other tasks before
	or	ax,ax			; allowing the rename
	jz	f56pthok
	pop	ds
	jmp	mosf56x
f56pthok:
	les	di,[asciiz2]

; validate drive, path, name of second file

	lea	si,fnm2
	lea	bx,[secbuf]
	mov	al,1			; skip labels
	call	pathfind
	assume	ds:bdb,es:nothing
	mov	[clvl],cl
	pop	cx
	jc	mosf56ab
	mov	ax,error_access_denied	; file already exists
xmosf56x:
	jmp	mosf56x
mosf56ab:
	cmp	ax,error_file_not_found
	jne	xmosf56x		; ne if some error other than file not found
	mov	ax,ds
	cmp	ax,cx
	mov	ax,error_not_same_device
	jne	xmosf56x		; drives must be the same for first and second
	mov	ax,error_access_denied
	cmp	[clvl],3		; must have read/write access to dest parent
	jb	xmosf56x
	mov	[clust2],dx		; first cluster of parent of new dir

; first file exists, second file doesn't - go ahead with rename
; save first dir entry

	mov	si,word ptr [dsct1]
	mov	[secbuf].seclow,si
	mov	si,word ptr [dsct1+2]
	mov	[secbuf].sechigh,si
	mov	si,[dofs1]
	lea	bx,[secbuf]
	call	rddir
	jc	x2f56x
	assume	es:dbb
	push	es
	push	ds
	push	es
	pop	ds
	push	ss
	pop	es
	assume	ds:dbb,es:tcb
	lea	si,[dbbbuf+si+11]	; past file name
	lea	di,fnm2+11		; past file name
	mov	cx,32-11
	rep	movsb
	pop	ds
	pop	es
	assume	ds:bdb,es:dbb
	mov	si,[dofs1]
	mov	dx,[clust1]
	cmp	dx,[clust2]
	je	mosf56c			; new name and old name in same dir

; if new and old names in different paths, delete old name

	mov	[dbbbuf+si],0e5h
	call	wrsector
	jnc	$+5
x2f56x:
	jmp	mosf56x

; find empty place for new name

	mov	dx,[clust2]
	call	emptydir
	jc	x2f56x

; copy saved dir entry to new location (including new name)

	assume	es:dbb
mosf56c:
	push	si
	push	ds
	push	ss
	pop	ds
	assume	ds:tcb
	lea	di,[dbbbuf+si]
	lea	si,fnm2
	mov	cx,32/2
	rep	movsw
	pop	ds
	pop	si
	assume	ds:bdb
	call	wrsector
	jc	mosf56x

; when a subdirectory is renamed into a different position, must
; update the first cluster pointer in the .. directory entry.

	test	[dbbbuf+si+datr],dir
	jnz	$+5			; if not working with a directory, skip all this
	jmp	f56mjs12
	mov	bx,word ptr [dbbbuf+si+dclust]
	cmp	bx,[bdbcnum]		; validate subdir cluster number
	jnc	mosf56x
	sub	bx,2
	jc	mosf56x
	xor	cx,cx
	mov	[secbuf].sechigh,cx
	mov	cl,[bdbcshl]
	jcxz	f56mjs11
f56mjs10:
	shl	bx,1
	rcl	[secbuf].sechigh,1
	loop	f56mjs10
f56mjs11:
	add	bx,[bdbclus]		; bx = sector for subdir
	adc	[secbuf].sechigh,cx	; cx is 0
	mov	[secbuf].seclow,bx
	lea	bx,[secbuf]
	call	rddir
	jc	mosf56x
	assume	es:dbb

; second entry must be a dir named .. owning the parent dir cluster

	lea	di,dbbbuf+32
	mov	ax,'..'
	scasw
	jne	mosf56x
	mov	al,' '
	mov	cx,11-2
	repe	scasb
	jne	mosf56x
	test	byte ptr [dbbbuf+32+datr],dir
	jz	mosf56x
	mov	ax,[clust2]		; update the starting cluster number
	mov	word ptr [dbbbuf+32+dclust],ax
	call	wrsector
	jc	mosf56x
f56mjs12:
	call	flushdir
	jc	mosf56x
	xor	ax,ax
	assume	ds:nothing,es:nothing,ss:tcb
mosf56x:
	mov	cx,error_file_not_found
	call	repo1
lundef	asciiz2				; -> second name
lundef	fnm1				; dir entry formatted first name
lundef	fnm2				; dir entry formatted second name
					;   (later has entire new dir entry)
lundef	clvl
lundef	dofs1				; offset in dir sector of first name
lundef	dsct1				; dir sector of first name
lundef	clust1				; cluster of parent directory for first name
lundef	clust2				; cluster of parent directory for second name
lundef	secbuf
lendp	mosfun56

	subttl mosfun57 - get/set a file's date and time
	page
;======================================================================
;,fs
; mosfun57 - get/set a file's date and time
;
; in:	tbx = file handle
;	tcx = time to set
;	tdx = date to set
;	tal = 0 get date/time
;	    = 1 set date/time
;
; out:	carry bit of tflag set if error
;	 tax = error code
;	  error_invalid_handle - invalid file handle specified
;	  error_invalid_function - invalid function specified
;	  & critical error codes
;	carry bit of tflag clear if no error
;	 tcx = file time
;	 tdx = file date
;
;,fe
;======================================================================
	assume	ds:grp,es:nothing,ss:tcb
lproc	mosfun57
lbyte	function
	mov	cx,bp
	mov	bp,[bp]
	mov	al,[tal]
	mov	bx,[tbx]		; handle of file for date and time
	mov	bp,cx
	call	noswt			; no task switches allowed
	mov	[function],al
	call	findtfb			; locate tfb corresponding to file handle
	mov	ax,error_invalid_handle
	jc	mosf57x			; (invalid handle)
	assume	es:tfb
	cmp	[function],0
	jne	mosf57a

; getting file date and time

	mov	es,[tfbgfb]
	assume	es:gfb
	mov	cx,[gfbtime]
	mov	dx,[gfbdate]
	mov	bx,bp
	mov	bp,[bp]
	mov	[tcx],cx
	mov	[tdx],dx
	mov	bp,bx
	xor	ax,ax
	jmp	short mosf57x

; setting file date and time

mosf57a:
	assume	es:tfb
	cmp	[function],01h
	mov	ax,error_invalid_function
	jnz	mosf57x
	mov	ax,error_access_denied	; must have read/write access to file to
	cmp	[tfblvl],3		;   set the file date
	jb	mosf57x
	mov	es,[tfbgfb]
	assume	es:gfb
	mov	bx,bp
	mov	bp,[bp]
	mov	ax,[tcx]
	mov	[gfbtime],ax
	mov	ax,[tdx]
	mov	[gfbdate],ax
	mov	bp,bx
	mov	[gfbwrtn],'Y'		; signal file has been modified
	xor	ax,ax
	assume	ds:nothing,es:nothing,ss:tcb
mosf57x:
	mov	cx,error_invalid_handle
	call	repo1
lundef	function
lendp	mosfun57

	subttl mosfun58 - get/set allocation strategy
	page
;======================================================================
;,fs
; mosfun58 - get/set allocation strategy
;
; get/set memory allocation strategy.
;
; this function, although not implemented by mos, must appear to the
; application that it does.  this routine merely stores the allocation
; strategy requested by the application (on set) so that same number
; can be recalled if an application needs to find out what the strategy
; is.
;
;  notes:
;
;  1) allocation strategy values can be 0 for "first fit", 1 for
;     "best fit" and 2 for "last fit".
;
;  2) presently, nothing is changed in mos based on the value of the
;     allocation strategy variable.  this function stores the value
;     for the sake of applications that may wish to test on the value
;     once it's set.
;
; get allocation strategy
; =======================
; in:	ax = 5800h
;
; out:	ax = memory allocation strategy
;      	or error code if carry set
;
; set allocation strategy
; =======================
; in:	ax = 5801h
;	bx = allocation strategy
;
; out:	ax = error code if carry set
;
; get upper memory link
; ======================
; in:	ax = 5802h
;
; out:	cy and al = 0 to indicate upper memory not available
;
; set upper memory link
; =====================
; in:	ax = 5803h
;	bx = link flag
;
; out:	cy and ax = 1 for invalid function
;
;,fe
;======================================================================
	assume	ds:grp,ss:tcb,es:nothing
public	mosfun58
mosfun58 proc near
	mov	ax,[tax]
	cmp	al,0
	je	f58_0
	cmp	al,1
	je	f58_1
	cmp	al,2
	je	f58_2
	cmp	al,3
	je	f58_3
	mov	ax,error_invalid_function
	jmp	short f58_exit

; get allocation strategy.

f58_0:
	mov	ax,[tcb_malloc_strategy] ; get from tcb.
	mov	[tax],ax
	xor	ax,ax
	jmp	short f58_exit

; set allocation strategy.

f58_1:
	mov	bx,[tbx]
	mov	[tcb_malloc_strategy],bx ; place in tcb.
	xor	ax,ax
	jmp	short f58_exit

; get upper memory link

f58_2:
	mov	[tal],0
	or	[tflag],carry
	jmp	short f58x2

; set upper memory link

f58_3:
	mov	[tax],1
	or	[tflag],carry
	jmp	short f58x2

f58_exit:
	call	moserror
f58x2:
	ret

mosfun58 endp

	subttl mosfun59 - get extended error
	page
;-----------------------------------------------------------------------
; this is the extended error code table
; see mos manual for types of class, action and locus
;-----------------------------------------------------------------------
fun59tbl label	byte

;*********    class   action  locus  error code	   *********

	db	0,	0,	1	;0
	db	7,	4,	1	;1
	db	8,	3,	2	;2
	db	8,	3,	2	;3
	db	1,	4,	1	;4
	db	3,	4,	1	;5
	db	7,	4,	1	;6
	db	7,	4,	5	;7
	db	1,	4,	5	;8
	db	7,	4,	5	;9

	db	9,	4,	1	;10
	db	9,	4,	1	;11
	db	7,	4,	1	;12
	db	9,	4,	1	;13
	db	13,	6,	1	;14 * reserved
	db	8,	3,	2	;15
	db	3,	3,	2	;16
	db	9,	3,	2	;17
	db	8,	3,	2	;18
	db	3,	7,	2	;19

	db	13,	3,	1	;20
	db	11,	1,	2	;21
	db	7,	4,	1	;22
	db	11,	5,	2	;23
	db	9,	4,	1	;24
	db	11,	5,	2	;25
	db	11,	7,	2	;26
	db	11,	7,	2	;27
	db	1,	7,	4	;28
	db	11,	1,	1	;29

	db	11,	1,	1	;30
	db	5,	1,	1	;31
	db	10,	2,	2	;32
	db	10,	2,	1	;33
	db	11,	7,	2	;34
	db	1,	4,	2	;35
	db	1,	4,	1	;36
	db	13,	6,	1	;37 *
	db	13,	6,	1	;38 * reserved
	db	13,	6,	1	;39 *

	page

	db	13,	6,	1	;40 *
	db	13,	6,	1	;41 *
	db	13,	6,	1	;42 *
	db	13,	6,	1	;43 *
	db	13,	6,	1	;44 *
	db	13,	6,	1	;45 * reserved
	db	13,	6,	1	;46 *
	db	13,	6,	1	;47 *
	db	13,	6,	1	;48 *
	db	13,	6,	1	;49 *

	db	7,	4,	3	;50
	db	3,	2,	3	;51
	db	13,	3,	3	;52
	db	8,	3,	3	;53
	db	2,	2,	3	;54
	db	1,	3,	3	;55
	db	1,	4,	3	;56
	db	5,	5,	3	;57
	db	13,	5,	3	;58
	db	4,	2,	3	;59

	db	13,	5,	3	;60
	db	1,	2,	1	;61
	db	1,	2,	1	;62
	db	8,	3,	1	;63
	db	8,	3,	3	;64
	db	3,	3,	3	;65
	db	13,	4,	3	;66
	db	3,	3,	3	;67
	db	9,	3,	3	;68
	db	1,	2,	3	;69

	db	2,	2,	3	;70
	db	13,	2,	3	;71
	db	2,	2,	3	;72
	db	13,	6,	1	;73 *
	db	13,	6,	1	;74 *
	db	13,	6,	1	;75 *
	db	13,	6,	1	;76 * reserved
	db	13,	6,	1	;77 *
	db	13,	6,	1	;78 *
	db	13,	6,	1	;79 *

	db	12,	2,	2	;80
	db	13,	6,	1	;81 * reserved
	db	13,	3,	2	;82
	db	13,	5,	1	;83
	db	1,	4,	3	;84
	db	12,	6,	3	;85
	db	3,	3,	3	;86
	db	9,	3,	3	;87
	db	5,	4,	3	;88
	db	12h,	21h,	99h	;89 test

	subttl mosfun59 - extended error
	page
;======================================================================
;,fs
; mosfun59 - extended error
;
; returns additional error information, such as the error class, locus,
; and recommended action.
;
; in:	tbx = version (should always be 0)
;
; out:	tax = extended error
;	tbh = error class
;	tbl = suggested action
;	tch = locus
;	tes:tdi -> disk volume label
;
;,fe
;======================================================================
	assume	ds:grp,ss:tcb,es:nothing
public	mosfun59
mosfun59:
	mov	al,[tcberrcod]		; novell may plug in invalid # here to
					;  flag their error codes
	mov	[tal],al		; return to user
	xor	ah,ah
	mov	[tah],ah		; clear ah
	mov	bx,ax
	shl	bx,1			; bx *2
	add	bx,ax			; bx = code * 3
	mov	al,[fun59tbl+bx+0]	; get class
	mov	[tbh],al		; return to user
	mov	al,[fun59tbl+bx+1]	; get action
	mov	[tbl],al		; return to user
	mov	al,[fun59tbl+bx+2]	; get locus
	mov	[tch],al		; return to user
	les	di,[tcberrvol]		; get pointer to volume label
	mov	[tes],es		; return to user
	mov	[tdi],di		; "     "
	and	[tflag],not carry	; make sure carry cleared
	ret

	subttl mosfun5a - create unique file
	page
;======================================================================
;,fs
; mosfun5a - create unique file
;
; file is opened in compatibility sharing mode with read/write access.
; access permission established as in function 3ch (except lbl 
; attribute always results in error_access_denied).
;
; in:	tds:tdx -> asciiz string with drive and path of directory in which
;	to create the file
;	tcx = attribute for created file
;
; out:	carry bit of tflag set if error
;	 tax = error code
;	  error_path_not_found -  invalid path specified
;		    path not found
;	  error_access_denied - the root directory is full (can't add to root)
;		    the disk is full (can't extend subdir)
;		    label attribute
;		    see attribute discussion in function 3ch
;	  error_too_many_open_files - too many files open
;	  & critical error codes
;	carry bit of tflag clear if no error
;	 tax = file handle
;	 tds:dx -> asciiz string filled in with file name
;
;,fe
;======================================================================
	assume	ds:grp,es:nothing,ss:tcb
lproc	mosfun5a
lbyte	clvl				; cumulative access to parent dir
lbyte	attrib				; attribute for created file
lword	pcluster			; first cluster of parent dir (0 if root)
lstring fnm,11				; dir entry formatted file name
ldword	buffer				; pointer to user path
lstring secbuf,<size sectorblk>		; buffer for sector number
	mov	bx,bp
	mov	bp,[bp]
	mov	es,[tds]
	mov	di,[tdx]
	mov	cx,[tcx]
	mov	bp,bx
	call	noswt			; no task switches allowed

; validate drive and path and attribute

	mov	[attrib],cl
	and	cl,not ( arch or sys or hid or ro )  ; lbl and dir invalid
	mov	ax,error_access_denied
	jnz	jmosf5ax		; fail if any invalid attribute bit set

; validate drive and path (and get first cluster of dir)

	push	di
	mov	cx,67			; 64 byte path + c: + trailing \
	xor	al,al
	repne	scasb
	pop	cx
	mov	ax,error_path_not_found
	jne	jmosf5ax
	mov	al,byte ptr es:[di-2]
	call	slash
	je	mosf5aa
	inc	di			; supply trailing \ if omitted
	mov	ax,'\'			; (note ah = 0)
	mov	es:[di-2],ax
mosf5aa:
	dec	di
	mov	word ptr [buffer],di
	mov	word ptr [buffer+2],es
	push	cx
	call	genname
	pop	di
	lea	si,fnm
	lea	bx,secbuf
	mov	al,1			; skip labels
	call	pathfind
	mov	[pcluster],dx		; first cluster of parent dir
	mov	[clvl],cl
	jc	mosf5ac
	cmp	al,'?'
	mov	ax,error_path_not_found
	je	jmosf5ax		; no wild-cards allowed
	mov	ax,error_access_denied
	or	bx,bx
	jz	jmosf5ax
	cmp	[clvl],3		; must have read/write access to parent dir
	jb	jmosf5ax
	cmp	dx,-1
	jne	mosf5ab
jmosf5ax:
	jmp	mosf5ax

; generate a name and see if it's unique

mosf5ab:
	les	di,[buffer]
	call	genname			; generate a new name into buffer
	push	ds
	push	ss
	pop	es
	lea	di,fnm
	lds	si,[buffer]
	mov	cx,8/2
	rep	movsw
	mov	ax,'  '
	stosw
	stosb
	pop	ds
	mov	dx,[pcluster]
	lea	di,fnm
	call	findnm			; see if file exists
	jnc	mosf5ab			; (repeat if so)
	assume	es:nothing
mosf5ac:
	cmp	ax,error_file_not_found
	jne	mosf5ax			; make sure it's not some other error

; no dir entry with that name, create a new one with supplied attrib

	push	ss
	pop	es
	lea	di,fnm
	mov	dx,[pcluster]
	mov	al,byte ptr [attrib]
	call	create			; make a directory entry (fail if duplicate)
	jc	mosf5ax			; (probably root full)

; flush out buffered sectors

	call	flushdir		; flush any changed fat and dir sectors
	jc	mosf5ax
	mov	al,02h			; compatibility sharing, read/write,
	test	[attrib],01h		; is this for read-only access
	jz	mosf5acx
	dec	al			; set for read-only
mosf5acx:
	mov	ah,[clvl]
	call	openfile		; inherited by child processes
	jc	mosf5ax
	assume	es:tfb
	call	getphdl			; get free handle from psp table
	mov	ax,[tfbhdl]
	xchg	ax,bx
	jc	mosf5ad			; c if no room in psp table (no error)
	xchg	ax,bx
	call	setphdl			; set system handle into psp table
	jnc	mosf5ad
	mov	bx,[tfbhdl]		; c if tfbhdl is a system handle (no error)
mosf5ad:
	mov	[tfbfnh],bx
	mov	ds,[tfbgfb]
	assume	ds:gfb
	mov	[gfbwrtn],'Y'		; file has been written
	or	[tfbioctl],40h		; written by this process
	mov	ax,bp
	mov	bp,[bp]
	mov	[tax],bx		; set up to return handle
	mov	bp,ax
	xor	ax,ax
	assume	ds:nothing,es:nothing,ss:tcb
mosf5ax:
	mov	cx,error_path_not_found
	call	repo1
lundef	clvl
lundef	attrib				; attribute for created file
lundef	pcluster			; first cluster of parent dir (0 if root)
lundef	fnm,11				; dir entry formatted file name
lundef	buffer				; pointer to user path
lundef	secbuf
lendp	mosfun5a

	subttl genname - generate a file name from the current time
	page
;======================================================================
;,fs
; genname - generate a file name from the current time
;
; generate a file name from the current time
; copy it to es:di terminated with 0
;
; in:	es:di -> buffer for filename
;
; out:	
;
;,fe
;======================================================================
	assume ds:nothing,es:nothing,ss:nothing
genname:
	callmos1 gettime		;** call in mos segment
	mov	ax,cx			; hour, minutes
	call	hexword
	mov	ax,dx			; seconds, hundredths
	call	hexword
	xor	al,al
	stosb
	ret

	subttl hexword - translate ax to ascii hex at es:di
	page
;======================================================================
;,fs
; hexword - translate ax to ascii hex at es:di
;
; in:	
;
; out:	
;
;,fe
;======================================================================
	assume ds:nothing,es:nothing,ss:nothing
hexword:
	xchg	al,ah
	call	hexbyte
	xchg	al,ah
hexbyte:
	push	ax
	shr	al,1
	shr	al,1
	shr	al,1
	shr	al,1
	call	hexdig
	pop	ax
hexdig:
	and	al,0fh
	add	al,'0'
	cmp	al,'0'+10
	jb	hexdg1
	add	al,7
hexdg1: stosb
	ret

	subttl mosfun5b - create new file
	page
;======================================================================
;,fs
; mosfun5b - create new file
;
; file is opened in compatibility sharing mode with read/write access.
; access permission established as in function 3ch.
;
; in:	tds:tdx -> asciiz string with drive, path and file to create
;	tcx = attribute for created file
;
; out:	carry bit of tflag set if error
;	 tax = error code
;	  error_path_not_found -  invalid path specified
;		    path not found
;		    invalid file name specified
;	  error_access_denied - the root directory is full
;		    the disk is full
;		    see attribute discussion in function 3ch
;	  error_too_many_open_files - too many files open
;	  error_file_exists - file exists (not new)
;	  & critical error codes
;	carry bit of tflag clear if no error
;	 tax = file handle (if not label)
;
;,fe
;======================================================================
	assume	ds:grp,es:nothing,ss:tcb
mosfun5b proc near
	mov	al,2			; setup for read-write access
	test	[tcx],ro
	jz	f5b1
	dec	al
f5b1:
	mov	ah,1			; newonly = 1
	mov	es,[tds]
	mov	di,[tdx]
	mov	cx,[tcx]
	call	hl_create
	or	ax,ax
	jnz	f5b2
	mov	[tax],bx
f5b2:
	call	moserror
	ret
mosfun5b endp

	subttl mosfun5c - lock/unlock file access
	page
;======================================================================
;,fs
; mosfun5c - lock/unlock file access
;
; in:	tal = function (0=lock, 1=unlock)
;	tbx = file handle
;	tcx:tdx = offset of lock region
;	tsi:tdi = length of lock region
;
; out:	carry bit of tflag set if error
;	 tax = error code
;	  error_invalid_function -  invalid function specified
;	  error_invalid_handle - invalid handle specifed
;	  lock -   lock violation
;	  & critical error codes
;	carry bit of tflag clear if no error
;
;,fe
;======================================================================
	assume	ds:grp,es:nothing,ss:tcb
lproc	mosfun5c
lbyte	function
ldword	locklen
ldword	lockofs
	mov	bx,bp
	mov	bp,[bp]
	mov	al,[tal]
	mov	dx,[tdx]
	mov	cx,[tcx]
	mov	di,[tdi]
	mov	si,[tsi]
	push	[tbx]			; handle of file containing region
	mov	bp,bx
	pop	bx
	call	noswt			; no task switches allowed
	mov	[function],al
	mov	word ptr [lockofs],dx
	mov	word ptr [lockofs+2],cx
	mov	word ptr [locklen],di
	mov	word ptr [locklen+2],si
	call	findtfb			; locate tfb corresponding to file handle
	mov	ax,error_invalid_handle
	jc	jmosf5cx		; (invalid handle)
	push	es
	pop	ds
	assume	ds:tfb,es:tfb
	cmp	[function],0
	jne	mosf5ca

; lock sub-function

	mov	dx,word ptr [lockofs]
	mov	cx,word ptr [lockofs+2]
	mov	di,word ptr [locklen]
	mov	si,word ptr [locklen+2]
	mov	ds,[tfbgfb]
	call	chklock
	mov	ax,error_lock_violation
	jc	jmosf5cx		; error if locked by others
	jz	jmosf5cx		; error if locked by this process

; allocate and fill out a new rlb

	push	es
	push	ds
	pop	es
	xor	ax,ax
	mov	al,'R'
	callmos1 mosliman		;** call in mos segment
	pop	ds
	assume	ds:tfb,es:rlb
	or	al,al
	mov	ax,error_sharing_buffer_exceeded  ; no room for more locks
	jnz	jmosf5cx
	mov	[rlbtfb],ds		; tfb of owner process and psp and handle
	mov	ax,[tfbfnh]
	mov	[rlbhdl],ax
	mov	dx,word ptr [lockofs]
	mov	cx,word ptr [lockofs+2]
	mov	di,word ptr [locklen]
	mov	si,word ptr [locklen+2]
	mov	ax,[tcbpsp]		; current psp -- jsm 04/27/87
	mov	word ptr [rlbpsp],ax	; psp for owner of locked region
	mov	word ptr [rlbbgn],dx	; start of locked region
	mov	word ptr [rlbbgn+2],cx
	add	di,dx
	adc	si,cx
	mov	word ptr [rlbend],di	; end+1 of locked region
	mov	word ptr [rlbend+2],si
	xor	ax,ax
jmosf5cx:
	jmp	short mosf5cx
	assume	ds:tfb,es:tfb
mosf5ca:
	cmp	[function],1
	mov	ax,error_invalid_function
	jne	mosf5cx

; unlock sub-function

	mov	dx,word ptr [lockofs]
	mov	cx,word ptr [lockofs+2]
	mov	di,word ptr [locklen]
	mov	si,word ptr [locklen+2]
	push	[tfbfnh]
	mov	ds,[tfbgfb]
	push	es
	call	findrlb
	pop	bx
	pop	cx
	assume	ds:gfb,es:rlb
	mov	ax,error_lock_violation
	jc	mosf5cx			; error if not found
	jnz	mosf5cx			; error if not exact match
	cmp	bx,[rlbtfb]
	jne	mosf5cx			; error if current process not the owner
	mov	ax,[tcbpsp]
	cmp	ax,[rlbpsp]
	jne	mosf5cx
	cmp	cx,[rlbhdl]
	jne	mosf5cx

; deallocate rlb

	mov	ah,01h
	mov	al,'R'
	callmos1 mosliman		;** call in mos segment
	xor	ah,ah
	or	al,al
	jz	mosf5cx
	mov	ax,intern		; internal error if can't de-allocate RLB
	assume	ds:nothing,es:nothing,ss:tcb
mosf5cx:
	mov	cx,error_invalid_handle
	call	repo1
lundef	function
lundef	locklen
lundef	lockofs
lendp	mosfun5c

	subttl mosfun65,66 - unsupported code page functions
	page
;======================================================================
;,fs
; mosfun65,66 - unsupported code page functions
;
; functions 65 and 66 currently deal with code pages for international
; support.  mos does not currently implement code pages, so these
; two functions are presently unsupported.
;
; in:	
;
; out:	
;
;,fe
;======================================================================
	assume	ds:grp,ss:tcb,es:nothing
public	mosfun65, mosfun66
mosfun65:
mosfun66:
	mov	[tax],error_invalid_function
	or	[tflag],carry
	ret

	subttl mosfun67 - set handle count
	page
;======================================================================
;,fs
; mosfun67 - set handle count
;
; this function allows for the extension of the psp's handle table
; allowing more than 20 file handles to be open at one time.	mos already
; supports more than 20 open file handles through the mechanism of the
; tfb (task file block) chain which is only limited by the amount of heap
; memory currently available.	 this function is provided solely for
; compatibility reasons.
;
; the extension of the psp's handle table is accomplished by allocating
; a block of memory equal to the number of handles requested in bytes and
; copying the psp's handle table up to the new location.  The pointer to
; the handle table in the psp is then modified with this new address.
;
; in:	ah = 67h
;	bx = new maximum psp handle count. (256 maximum)
;
; out:	ax = error code if carry bit is set.  otherwise, no output.
;
;,fe
;======================================================================
	assume	ds:grp,ss:tcb,es:nothing
public	mosfun67
mosfun67 proc near
	cmp	[tcbversn],1403h	; if dos 3.2 skip it
	jne	dofun67
	or	[tflag],carry
	mov	[tax],error_invalid_function
	ret
dofun67:

; if psp handle pointer is not in psp segment, we must deallocate
; if the system is not the same as requested

	mov	ax,[tcbpsp]
	mov	ds,ax
	assume	ds:pspseg
	cmp	word ptr [psppntr+2],ax
	je	cont67			; not allocated so skip
	mov	ax,[tbx]		; get handle count
	cmp	ax,[psphdls]		; is it same as current
	je	skip67			; yes...no need for alternations

; we must copy current contents of first 20 handles to psp handle table

	push	ds
	pop	es
	mov	ds,word ptr [psppntr+2]
	xor	si,si
	mov	di,18h
	mov	cx,20/2
	rep	movsw

; we must free current pointer and reset it to current psp
; please note doing this hear handle both resizing of larger than
; 20 table and going back to a 20 handle table

	mov	ds,[tcbpsp]
	mov	es,word ptr [psppntr+2]
	mov	ah,49h
	callmos1 sim21
	mov	word ptr [psppntr],18h
	mov	word ptr [psppntr + 2],es
	mov	[psphdls],20
cont67:
	cmp	word ptr [tbx],20	; assigning < 20?
	ja	f67_get_block
skip67:
	and	[tflag],not carry
	jmp	short f67_exit

f67_get_block:
	mov	ah,48h			; allocate memory function.
	mov	bx,[tbx]		; get new size requested.
	mov	cl,4
	shr	bx,cl			; convert bytes to paragraphs.
	inc	bx			; round up to nearest whole paragraph.
	callmos1 sim21			; internal call to mos.
	jnc	f67_copy_table		; if no error, go copy the table.
	or	[tflag],carry
	mov	[tax],error_not_enough_memory
	jmp	short f67_exit

f67_copy_table:
	mov	si,offset psphtbl	; psp handle table in ds:si
	assume	ds:pspseg		; to access psp variables.
	mov	es,ax			; ax got memory address from fn 48.
	xor	di,di			; allocated block in es:di.
	mov	word ptr [psppntr],di	; pointer moved.
	mov	word ptr [psppntr + 2],es
	mov	cx,[tbx]
	mov	[psphdls],cx		; max handle count.

; clear the new block of memory before putting anything in it.

	push	di
	mov	al,0ffh			; free handle.
	rep	stosb			; clear the memory. (cx already loaded)
	pop	di

; copy the old handle table from the psp to the new location.

	mov	cx,20/2			; copy the whole psp table.
	rep	movsw			; copy complete.

; operation is complete.

	and	[tflag],not carry
f67_exit:
	ret
mosfun67 endp

	subttl mosfun68 - commit file
	page
;======================================================================
;,fs
; mosfun68 - commit file
;
; this function flushes a currently open file to disk.
;
; in:	ah = 68h
;	bx = handle of file to commit to disk.
;
; out:	ax = error code if carry bit is set.  (otherwise no output)
;
;,fe
;======================================================================
	assume	 ss:tcb,ds:nothing,es:nothing
public	mosfun68
mosfun68 proc near
	mov	ax,error_invalid_handle
	cmp	[tcbtfbpf],0		; is there a tfb?
	je	f68_error

; trace the tfb chain until the correct one is found for the specified
; file handle.

	mov	ax,error_invalid_handle	; hold error code in ax.
	mov	bx,[tbx]		; get the handle.
	call	findphdl		
	mov	ds,[tcbtfbpf]		; first tfb for this tcb.
	assume	ds:tfb
f68_tfb_search:
	cmp	[tfbhdl],bx		; match of handle yet?
	je	f68_flush_file
	cmp	[tfbntcb],0		; at end of chain?
	je	f68_error
	mov	ds,[tfbntcb]		; get next tfb for this tcb.
	jmp	short f68_tfb_search

; a match was found on the supplied handle.  now, get the gfb for this
; file and in-turn get the bdb pointed at by the gfb.

f68_flush_file:
	mov	es,[tfbgfb]		; setup for call to upd_dir
	mov	ds,[tfbgfb]		; get tfb address.
	assume	ds:gfb
	mov	ds,[gfbbdb]		; finally, get the bdb for the file.
	assume	ds:bdb
	call	mediachk		; anyone remove the disk?
	mov	ax,error_wrong_disk
	jc	f68_error
	call	flushdata		; flush the file to disk.
	jc	f68_error		; ax will have error code if cy set.

; now, update the directory entry

	pushset	bx,cx,si,ds
	call	upd_dir
	popset	bx,cx,si,ds
	jc	f68_error

; the file flush completed successfully.

	and	[tflag],not carry
	ret
f68_error:
	or	[tflag],carry
	mov	[tax],ax
	ret
mosfun68 endp

	subttl mosfun6c - extended open/create
	page
;======================================================================
;,fs
; mosfun6c - extended open/create
;
;
; quirk #1:
; if a device driver, and tdx spec is 10h, create a device handle
;
; in:	!!!!!!!!!!!!!!!
;
; out:	carry bit of tflag set if error
;	 tax = error code
;	carry bit of tflag clear if no error
;
;,fe
;======================================================================
	assume	ds:grp,es:nothing,ss:tcb
lproc	mosfun6c
lstring fnm,11				; dir entry formatted file name
lstring secbuf,<size sectorblk>		; sector number buffer
lword action
	call	noswt			; no task switches allowed
	mov	bx,bp
	mov	bp,[bp]
	mov	cx,[tcx]
	mov	dx,[tdx]
	mov	es,[tds]
	mov	di,[tsi]
	mov	al,[tbl]
	mov	bp,bx

; validate the open mode

	call	validate_acc
	ljc	f6c_x

; validate attribute

	test	cl,not ( arch or dir or lbl or sys or hid or ro )
	mov	ax,error_access_denied
	ljnz	f6c_x			; fail if any invalid attribute bit set

; validate action bits

	mov	ax,error_invalid_function  ; error when bad bits in tdx
	mov	dh,dl
	and	dl,0fh
	shr	dh,1
	shr	dh,1
	shr	dh,1
	shr	dh,1
	cmp	dl,2
	lja	f6c_x
	cmp	dh,1
	lja	f6c_x
	mov	[action],dx

; supposed to suppress int24 for this call?

	mov	bx,bp
	mov	bp,[bp]
	mov	al,[tbh]
	mov	bp,bx
	test	al,20h
	jz	f6c_6
	mov	[tcbno24],1
f6c_6:

; use pathfind to see if the file/device exists or not.	 note that
; a go/no go indication is all that is taken here.  more complete
; error analysis is left to hl_open and hl_create (e.g. such as
; trying to open the root directory or a global filespec).

	mov	[fnm],' '		; to check for null path (drive only)
	lea	si,fnm
	lea	bx,secbuf
	mov	al,1			; skip labels
	test	cl,lbl
	jz	f6c_1
	xor	al,al			; unless specified in entry cx
f6c_1:
	push	di
	push	ds
	push	es
	call	pathfind
	pop	es
	pop	ds
	pop	di
	mov	dx,[action]
	jc	f6c_2

; quirk #1:
; if a device driver, and tdx spec is 10h, create a device handle

	or	bx,bx
	jnz	f6c_4
	cmp	dx,0100h		; 10 == 100 in expanded form
	je	f6c_5

; something exists -- so react based on tdl bits 0-3

f6c_4:
	mov	ax,error_file_exists
	or	dl,dl
	jz	f6c_x
	cmp	dl,1
	jne	f6c_3
	mov	cx,bp
	mov	bp,[bp]
	mov	al,[tbl]
	mov	bp,cx
	xor	cl,cl
	call	hl_open
	mov	cx,1			; file existed and was opened
	jmp	short f6c_x
f6c_3:
	mov	bx,bp
	mov	bp,[bp]
	mov	al,[tbl]
	mov	cl,[tcl]
	mov	bp,bx
	xor	ah,ah
	call	hl_create
	mov	cx,3			; file existed and was replaced
	jmp	short f6c_x

; failure from pathfind - react based on tdl bits 4-7

f6c_2:
	mov	ax,error_file_not_found
	or	dh,dh
	jz	f6c_x
f6c_5:
	mov	bx,bp
	mov	bp,[bp]
	mov	al,[tbl]
	mov	cl,[tcl]
	mov	bp,bx
	xor	ah,ah
	call	hl_create
	mov	cx,2			; file did not exist and was created
f6c_x:
	or	ax,ax
	jnz	f6c_y
	mov	dx,bp
	mov	bp,[bp]
	mov	[tax],bx		; return handle
	mov	[tcx],cx		; return status word
	mov	bp,dx
f6c_y:
	mov	[tcbno24],0
	call	okswt			; safe to allow a task switch
	mov	bx,bp
	mov	bp,[bp]			; address task registers to report tax error
	call	moserror
	mov	bp,bx
lundef	fnm
lundef	secbuf
lundef action
lendp	mosfun6c

	subttl usts0 - common function startup logic
	page
;======================================================================
;,fs
; usts0 - common function startup logic
;
; use task registers, do not modify bp reg.
; called from start of most procs
;
; in:	
;
; out:	
;
;,fe
;======================================================================
	assume ds:nothing,es:nothing,ss:nothing
usts0 proc near
	mov	bx,bp
	mov	bp,[bp]
	mov	es,[tds]
	mov	di,[tdx]
	mov	bp,bx
	call	noswt			; no task switches allowed
	ret
usts0 endp

	subttl usts1 - common function startup logic
	page
;======================================================================
;,fs
; usts1 - common function startup logic
;
; in:	
;
; out:	
;
;,fe
;======================================================================
	assume ds:nothing,es:nothing,ss:nothing
usts1 proc near
	mov	ax,bp
	mov	bp,[bp]
	mov	bx,[tbx]		; handle of file to duplicate
	mov	bp,ax
	call	noswt			; no task switches allowed
	call	findtfb			; locate tfb corresponding to file handle
	mov	ax,error_invalid_handle
	ret
usts1 endp

	subttl repo0 - common closeout logic
	page
;======================================================================
;,fs
; repo0 - common closeout logic
;
; report error in tasks space - version 0
; success code in dx reg.
; return code in cx (for moserror)
;
; in:	
;
; out:	
;
;,fe
;======================================================================
	assume ds:nothing,es:nothing,ss:nothing
repo0 proc near
	call	okswt			; safe to allow a task switch
	mov	bx,bp
	mov	bp,[bp]			; address task registers for tax = error code
	mov	[tax],dx		; dx holds success code
	call	moserror
	mov	bp,bx
	ret
repo0 endp

	subttl repo1 - common closeout logic
	page
;======================================================================
;,fs
; repo1 - common closeout logic
;
; report code/error, version 1
; error code in cx.
;
; in:	
;
; out:	
;
;,fe
;======================================================================
	assume ds:nothing,es:nothing,ss:nothing
repo1 proc near
	call	okswt
	mov	bx,bp
	mov	bp,[bp]			; address task registers to report tax error
	call	moserror
	mov	bp,bx
	ret
repo1 endp

	subttl rethan - return handle in task ax reg.
	page
;======================================================================
;,fs
; rethan - return handle in task ax reg.
;
; in:	
;
; out:	
;
;,fe
;======================================================================
	assume ds:nothing,es:nothing,ss:nothing
rethan proc near
	mov	ax,bp
	mov	bp,[bp]
	mov	[tax],bx		; return handle
	mov	bp,ax
	xor	ax,ax			; no error
	ret
rethan endp

	subttl ckexcl - check for exclusion
	page
;======================================================================
;,fs
; ckexcl - check for exclusion
;
; in:	
;
; out:	
;
;,fe
;======================================================================
	assume ds:nothing,es:nothing,ss:nothing
ckexcl proc near
	push	ds
	push	si
	push	es
	pop	ds
	lea	si,[dbbbuf+si]
	call	checkexon		; check for an exclusion from +except/+only
	pop	si
	pop	ds
	ret
ckexcl endp

	subttl rwdevs - read/write device setup routine
	page
;======================================================================
;,fs
; rwdevs - read/write device setup routine
;
; in:	
;
; out:	
;
;,fe
;======================================================================
	assume ds:nothing,es:nothing,ss:nothing
rwdevs proc near
	mov	si,bp
	mov	bp,[bp]
	mov	bx,[tbx]		; handle of file to read
	mov	dx,[tdx]
	mov	ax,[tds]
	mov	di,[tcx]
	mov	bp,si
	call	noswt			; no task switches allowed
	push	ax			; normalized segment
	call	findtfb			; locate tfb corresponding to file handle
	pop	ds
	mov	ax,error_invalid_handle
	ret
rwdevs endp

	subttl stnbyt - set number of bytes read/written in task ax reg.
	page
;======================================================================
;,fs
; stnbyt - set number of bytes read/written in task ax reg.
;
; in:	
;
; out:	
;
;,fe
;======================================================================
	assume ds:nothing,es:nothing,ss:nothing
stnbyt proc near
	mov	di,bp
	mov	bp,[bp]
	mov	[tax],cx		; number of bytes read returned in ax
	mov	bp,di
	ret
stnbyt endp

	subttl sttax0 - set tax reg with processor ax reg
	page
;======================================================================
;,fs
; sttax0 - set tax reg with processor ax reg
;
; in:	
;
; out:	
;
;,fe
;======================================================================
	assume ds:nothing,es:nothing,ss:nothing
sttax0 proc near
	mov	bx,bp
	mov	bp,[bp]
	mov	[tax],ax
	mov	bp,bx
	xor	ax,ax
	ret
sttax0 endp

ddt	ends
	end

