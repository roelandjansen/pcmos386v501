
; '##' markings surround changes for bdbsctr/csector/sechigh/seclow


	include page.inc
	title	mosfutl4 - mosfun39 utility subroutines
comment ^===============================================================
		      development specification

 program name:	$$mos.com		 assigned to: stewart hyde
 module name:	mosfutil		 assign date:
 entry points:	mosfun39-mosfun5c	 completed: 09/03/88
 entry from:	mosint39, mosfun0f
 entry method:	call
 calls: 	device drivers, mosliman, mossaver(mosrestore),
		mosddint(setbdb), terminate, suspend, caps, getdate
		gettime
 purpose:	file handle functions
 last update:	08/18/1992
========================================================================

sah 09/03/88	moved code from mosfutil to here and made change do
		makegfb to account for dos sft structure.

sah 12/04/88	made changes to getthdl to account for new mos
		limit command which limits the number of open files
		to the value store in psp at offset 32h. this is to
		fix a problem with enable 3.00 install program.

sah 01/26/89	change lock equate to nlock (masm 5.10 compatibility)

rkg 02/23/89	updating file's first cluster on all closes, since
		first cluster may be 0 if truncated to zero length

sah 03/22/89	corrected problem with novell lptdrv and closing files
		closefile was returning an error if file attempting to
		be close is an device.

rkg 05/11/89	findgfb had bug in looping through gfbs

sah 07/25/89	corrections for novell, made sure that class security is
		is nulified if invalid class.

mjs 10/02/89	modify cmap to prevent redundant calls to scbmmsub.

mjs 10/10/89	modified sector size calculations.

mjs 10/11/89	modified closeall to not delete the rlb's for a tfb
		if tfbopen > 1.

sah 12/14/89	remove mosregs2.inc

sah 04/09/90	corrections for mos files command so that error will be
		return to application.

sah 07/17/90	corrections for relation (force dup) made sure to inc
		tfbopen instead of setting it to 1. also remove logic
		from exclude for closing files. return is use to check
		if task as exclusive access to file. all calls to this
		routine should not have the need to close the files

mjs 07/29/90	modified findgfb to detect an orphaned gfb and call
		closepart to deallocate the orphaned resources.  this
		helps mos accomdate skplus's slop.

sah 08/23/90	corrections for mos files on for miscrosft linker 5.10
		we were allowing 16 open files instead of 15.

sah 03/08/91	corrections for dr-software, make sure closeall, clears
		out psp handle table if tfb is not an fcb

sah 03/25/91	corrections for peachtree complete iii, change the mos
		files on check for getthdl to check psp for available 
		handle and report error if none available, else return
		highest handle (if mos files on, highes available is 254)

mjs 07/15/91	reworked sah's change to closeall of 03/08/91.  to find
		the psp handle for a system handle, must scan for a match.
		setphdl is only to be used for psp handles, not system
		handles.

mjs 08/09/91	modify my closeall change of 07/15/91 to skip the case 
		where mosrtask forces tcbpsp to 0 to close the standard 
		system handles for a task.

mjs 12/16/91	dlg mods: modify access to csector to use 'byte ptr' for the
		3rd byte.

================ 5.01 Kernel Ends Here ====================================
		
mjs 07/23/92	converted the logic within closefile that updates
		the directory entry to a separate function named
		upd_dir.  this was done so i21f68 could call this function.

mjs 08/18/92	clean up segment declarations

========================================================================^

.xlist
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

;======================================================== mos segment
if 0 eq 0
segment_num = 1
endif
mosseg	segment
	extrn	m1retf:word
	extrn	mosliman:near
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
	extrn	timestamp:near
	extrn	flushdir:near, flushdata:near, wrfat:near
	extrn	rdbf:near, wrbf:near, rddir:near, wrsector:near
	extrn	flush:near, rdfat:near, flush24:near
	extrn	chklogd:near, chkbdb:near, invbdb:near
	extrn	freecache:near, rddata:near
	extrn	chkacc:near, maketfb:near
	extrn	classlvl:near, devchk:near, mediachk:near
	extrn	mapvsa:near, bugerror:near, random:near

	public	openfile, closefile, closeall, exclude, findbdbc
	public	findphdl, setphdl, getphdl, getthdl, ckdev0
	public	findgfb, makegfb, clearbit, setbit, testbit, bitaddr, 
	public	markdirty, markclean, cmap, cfree, moslim0, fat16
	public	fat12


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
compat	equ	10001111b		; compatibility mode - 8fh

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

	subttl openfile - open a file from a directory entry
	page
;======================================================================
;,fs
; openfile - open a file from a directory entry
;
; in:	ds = paragraph address of bdb
;	ah = cumulative dir class access level for tcb
;	al = access desired
;	bx = 0 if device
;	 es:si -> device driver
;	else ss:bx -> sector address of dir entry
;	 si = offset within sector of dir entry
;	ss -> tcb (needed by makegfb, etc.)
;
; out:	c if error
;	 ax = error code
;	 es = undefined
;	nc if no error
;	 tfb (and gfb if first task) filled out
;	 es = address of tfb
;	 ax undefined
;
;,fe
;======================================================================
	assume	ds:bdb
lproc	openfile
lbyte	class
lbyte	access
lword	gfbseg
lword	drvrseg
	push	dx
	push	cx
	mov	[class],ah
	mov	[access],al
	mov	[drvrseg],es
	call	findgfb 		; find global file block for file
	jnc	openf1
	mov	es,[drvrseg]
	call	makegfb 		; create gfb if not found
	jmpc	openfy			; (c probably couldn't allocate it)
openf1:
	mov	[gfbseg],es
	assume	es:gfb

; if exec flag is set then if gfbtfb <> 0 and tfb is in compatibility
; mode then use compatibility mode to open

	push	ax
	push	es
	cmp	[tcbexec3d],0
	je	openf3			; if flag not set, proceed as before
	mov	ax,[gfbtfb]
	or	ax,ax
	jz	openf3
	mov	es,ax
	assume	es:tfb
	mov	al,[tfbalow]
	and	al,7
	jnz	openf3
	and	[access],compat 	; 10001111b-force to compatibility mode
openf3:
	pop	es
	pop	ax
	assume	es:gfb
	mov	al,[access]
	call	chkacc			; see if requested access is ok
	jc	openfx
	mov	al,3			; assume full access
	cmp	[gfbdev],0		; device?
	jne	openf1b 		; yes, skip class bs
	mov	al,[gfbclass]		; class for file
	call	classlvl
	cmp	al,[class]		; file access level restricted to lesser of
	jbe	openf1a 		;   file class access and cumulative access
	mov	al,[class]		;   to parent dir
openf1a:
	or	al,al
	jnz	openf1b 		; must have at least exec access to file
	mov	ax,filenf
	jmp	short openfx
openf1b:
	mov	ah,al
	mov	al,[access]
	call	maketfb 		; create a tfb
	assume	es:tfb
	jc	openfx			; (c probably couldn't allocate it)
	push	es
	mov	es,[gfbseg]
	mov	al,13			; check device support, command 13 to driver
	call	ckdev0
	pop	es			; ignore error from check
	assume	es:tfb
	inc	[tfbopen]		; open it
	clc
	jmp	short openfz

; on error following establishment of gfb, see if gfb needs to be
;   closed

openfx:
	mov	es,[gfbseg]
	assume	es:gfb
	cmp	[gfbtfb],0
	jne	openfy			; ne if some other tfb using gfb
	push	ax
	mov	ah,1			; (delete)
	mov	al,'G'			; (gfb) - must be deallocated if no other
					;   tfb's for this gfb
	call	moslim0
	pop	ax
	jz	openfy
	mov	ax,intern		; internal errors are only ones possible
openfy:
	stc
openfz:
	pop	cx
	pop	dx
lundef	class
lundef	access
lundef	gfbseg
lundef	drvrseg
lendp	openfile

	subttl closepart - partial close file function
	page
;======================================================================
;,fs
; closepart - partial close file function
;
; this partial version of the closefile function is used when
; an orphaned gfb is detected by findgfb.  it is used to deallocate
; all tfb, rlb and gfb resources.
; note that psp handle tables are not updated.
; see mjs's notes on skplus to understand how a gfb can become
; orphaned.
;
; in:	es -> gfb
;
; out:	c if error
;	 ax = error code
;	nc if no error
;	 ax = 0
;	es = undefined in either case
;
;,fe
;======================================================================
	assume	ds:nothing,es:gfb,ss:tcb
closepart:
	pushset cx,si
	mov	si,es			; save gfb for later
	mov	cx,[gfbrlb]
clpf2:
	jcxz	clpf3			; delete all rlb's for this GFB
	mov	es,cx
	assume	es:rlb
	mov	cx,[rlbngfb]		; (next rlb if any)
	mov	ah,1
	mov	al,'R'
	call	moslim0
	jz	clpf2
	jmp	short clpfy
clpf3:
	mov	es,si
	assume	es:gfb
	mov	cx,[gfbtfb]
clpf4:
	jcxz	clpf5			; delete all tfb's for this GFB
	mov	es,cx
	assume	es:tfb
	mov	cx,[tfbngfb]		; (next tfb if any)
	mov	ah,1
	mov	al,'F'
	call	moslim0
	jz	clpf4
	jmp	short clpfy
clpf5:
	mov	es,si			; location of gfb
	assume	es:gfb
	mov	ah,1
	mov	al,'G'
	call	moslim0
	jnz	clpfy
clpfx:
	xor	ax,ax
	jmp	short clpfz
clpfy:
	mov	ax,intern
	stc
clpfz:
	popset	cx,si
	ret

	subttl upd_dir - update a file's directory entry
	page
;======================================================================
;,fs
; upd_dir - update a file's directory entry
;
; in:	es -> gfb
;	ss -> tcb
;
; out:	c if error
;	 ax = error code
;	 es = undefined
;	nc if no error
;	 ax = 0
;	 cx -> gfb
;
; crashes: ax,bx,cx,si,ds
;
;,fe
;======================================================================
	assume	ds:nothing,es:gfb,ss:tcb
public upd_dir
lproc upd_dir
lstring secbuf,<size sectorblk>
	mov	ds,[gfbbdb]
	assume	ds:bdb
	mov	ax,[gfbdloc]
	mov	si,[gfbhloc]
	mov	[secbuf].seclow,ax
	mov	[secbuf].sechigh,si
	lea	bx,[secbuf]
	push	es
	call	rddir
	pop	cx
	jc	updx
	mov	ds,cx
	assume	ds:gfb,es:dbb
	mov	si,[gfbdofs]
	or	[dbbbuf+si+datr],arch
	mov	ax,[gfbtime]
	mov	word ptr [dbbbuf+si+dtime],ax
	mov	ax,[gfbdate]
	mov	word ptr [dbbbuf+si+ddate],ax
	mov	ax,word ptr [gfbsize]
	mov	word ptr [dbbbuf+si+dsize],ax
	mov	ax,word ptr [gfbsize+2]
	mov	word ptr [dbbbuf+si+dsize+2],ax
	mov	ax,word ptr [gfbcbof]	; update starting cluster for file
	mov	word ptr [dbbbuf+si+dclust],ax
	mov	ds,[gfbbdb]
	assume	ds:bdb
	call	wrsector
	jc	updx
	call	flushdir
updx:
lundef	secbuf
lendp upd_dir

	subttl closefile - close a file
	page
;======================================================================
;,fs
; closefile - close a file
;
; in:	es = paragraph address of tfb
;
; out:	c if error
;	 ax = error code
;	 es = undefined
;	nc if no error
;	 ax = 0
;
;,fe
;======================================================================
	assume	ds:nothing,es:tfb,ss:tcb
lproc	closefile
lword	tfbseg

; these locals must be in this order!

lstring endsect,<size sectorblk>
lstring startsect,<size sectorblk>

; end order dependent locals.

	pushset ds,si,dx,cx,bx
	mov	[tfbseg],es

; delete rlb's for this TFB, for this TCB, for this PSP

	cmp	[tfbopen],1		; don't kill the rlb's if not
	jne	closef3 		; closing the last handle
	mov	ax,[tfbseg]
	mov	bx,[tfbfnh]
	mov	es,[tfbgfb]		; optimize, used to mov cx then es,cx
	mov	dx,[tcbpsp]
	assume	es:gfb
	mov	cx,[gfbrlb]
closef2:
	jcxz	closef3 		; delete those rlb's for this GFB
	mov	es,cx			;   with same tcb and same psp
	assume	es:rlb
	mov	cx,[rlbngfb]		; (next rlb if any)
	cmp	ax,[rlbtfb]		; (note for above that tfb implies tcb)
	jne	closef2
	cmp	dx,[rlbpsp]
	jne	closef2
	cmp	bx,[rlbhdl]
	jne	closef2
	push	dx
	push	cx
	push	bx
	push	ax
	mov	ah,1
	mov	al,'R'
	call	moslim0
	pop	ax
	pop	bx
	pop	cx
	pop	dx
	jz	closef2
	mov	ax,intern		; internal error if can't deallocate the RLB
	stc
	jmp	closefx
closef3:
	mov	es,[tfbseg]		; delete the tfb itself
	assume	es:tfb
	push	[tfbgfb]		; remember parent gfb
	mov	ax,[tfbpsp]
	cmp	ax,[tcbpsp]
	jne	closef3a		; only owner can delete tfb
	dec	[tfbopen]
	jnz	closef3a		; if no more open, then delete tfb
	mov	ah,1			; (delete)
	mov	al,'F'			; (tfb)
	call	moslim0
	mov	ax,intern
	stc
	jnz	cfx0
closef3a:
	pop	cx
	mov	es,cx			; need cx to be this for some reason
	mov	al,14			; close function
	call	ckdev0			; check device attr
	jnc	cfndev			; if not device then continue

; if device than we must not return bad but indicate ok status
; this corrects a problem with novell lptdrv and redirection

	xor	ax,ax			; return everthing is ok
	clc
	jmp	closefx
cfndev:

; if no other active tfb's for this gfb, delete it

	assume	es:gfb
	cmp	[gfbdev],0
	jne	cf80
	cmp	[gfbwrtn],0
	jne	flushbuf
cf80:	jmp	closef8

; flush all of file's buffered sectors

flushbuf:
	mov	ds,[gfbbdb]
	assume	ds:bdb
	call	mediachk		; make sure the disk hasn't been changed
	jc	cfx0
	call	flushdata		; if write-thru, flush all data for bdb
	jnc	closef7
cfx0:
	jmp	closefx
closef7:

; if written to, update dir entry with size, date and time

	call	upd_dir
	jc	closefx

; delete the gfb

closef8:
	mov	es,cx			; location of gfb
	assume	es:gfb
	xor	ax,ax
	cmp	[gfbtfb],ax
	clc
	jne	closefx 		; finished if other tfb's for this gfb
	mov	ah,1
	mov	al,'G'
	call	moslim0
	mov	ax,intern		; internal error if can't de-allocate it
	stc
	jnz	closefx
	xor	ax,ax
closefx:
	popset	ds,si,dx,cx,bx
lundef	tfbseg
lundef	startsect
lundef	endsect
lendp	closefile

	subttl closeall - close all open files for a psp for a tcb
	page
;======================================================================
;,fs
; closeall - close all open files for a psp for a tcb
;
; ÚÄ 
; ³ cx = ss:[tcbtfbpf]
; ³ÕÍ 
; ³³ if(cx == 0) exit
; ³³ es = cx
; ³³ cx = es:[tfbntcb]
; ³³ if(ss:[tcbpsp] != es:[tfbpsp]) continue
; ³³ bx = es:[tfbhdl]
; ³³ÚÄ if(bx != ffff)
; ³³³ scan for system handle bx-2 within the psp handle table
; ³³³ if find, reset to ff
; ³³ÀÄ 
; ³³ call closefile
; ³ÔÍ  
; ÀÄ 
; 
; for each tfb which matches the current psp 
;  if the system handle is not ffff, reset the psp handle to ff
;  call closefile
;
; in:	ss -> tcb
;
; out:
;
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:tcb
closeall proc	near
	push	bx
	mov	cx,[tcbtfbpf]
closea1:
	or	cx,cx
	jz	closea2
	mov	es,cx			; close each tfb for this tcb and psp
	assume	es:tfb
	mov	cx,[tfbntcb]
	mov	ax,[tcbpsp]
	cmp	ax,[tfbpsp]
	jne	closea1
	mov	bx,[tfbhdl]
	cmp	bx,-1
	je	skipclall

; search for the bx-2 system handle within the tfbpsp
; if find, reset to ff

; this first test is to skip the case where mosrtask forces tcbpsp to 0
; to close the standard system handles for a task.

	or	ax,ax
	jz	skipclall
	pushset cx,di,es
	mov	es,ax
	mov	ax,bx
	sub	ax,2
	mov	cx,word ptr es:[32h]
	les	di,dword ptr es:[34h]
	cld
	repne	scasb
	jne	closea3
	mov	byte ptr es:[di-1],0ffh
closea3:
	popset	cx,di,es
skipclall:
	call	closefile
	jmp	short closea1
closea2:
	pop	bx
	ret
closeall endp

	subttl exclude - see if exclusive access can be acquired
	page
;======================================================================
;,fs
; exclude - see if exclusive access can be acquired
;
; in:	ds = bdb segment address
;	ss:bx -> dir entry sector
;	si = dir entry offset
;
; out:
;	c if error, file is open by another psp or tcb
;	else nc
;
;,fe
;======================================================================
	assume	ds:bdb,es:nothing,ss:tcb
exclude:
	push	es
	push	cx
	call	findgfb
	cmc
	jnc	excludx 		; ok if no gfb's for this dir entry
	assume	es:gfb
	mov	cx,[gfbtfb]
exclud1:
	jcxz	exclud3
	mov	es,cx
	assume	es:tfb
	mov	cx,[tfbngfb]
	mov	ax,ss
	cmp	ax,[tfbtcb]
	jne	exclud2
	mov	ax,[tfbpsp]
	cmp	ax,[tcbpsp]
	je	exclud1
exclud2:
	mov	ax,accdeny
	stc
	jmp	short excludx

; they're all ok

exclud3:
	clc
excludx:
	pop	cx
	pop	es
	ret

	subttl findphdl - find system handle corresponding to psp handle
	page
;======================================================================
;,fs
; findphdl - find system handle corresponding to psp handle
;
; ÚÄ 
; ³ ax = ss:[tcbpsp]
; ³ if(ax == 0) exit
; ³ ds = ax
; ³ if(bx >= ds:[32h]) exit
; ³ fetch system handle for bx psp handle number
; ³ÚÄ if(psp handle == ff)
; ³³ bx = entry bx (psp handle number)
; ³ÃÄ else
; ³³ bx = system handle + 2
; ³ÀÄ  
; ÀÄ 
; 
; if tcbpsp != 0 and psp handle within range
;  index handle table with psp handle
;  convert the byte read from handle table to a word
;  if byte from table == ff, return entry bx value
;  else return table word + 2
; else return entry bx value
;
; in:	bx = psp handle
;	ss -> tcb
;
; out:	bx = corresponding system handle
;	crashes ax
;
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:tcb
findphdl:
	push	ds
	push	si
	mov	ax,[tcbpsp]
	or	ax,ax
	jz	findpy			; no psp implies bx is system handle also
	mov	ds,ax
	cmp	bx,word ptr ds:[32h]
	jae	findpy			; or past end of handle table
	mov	si,bx
	mov	al,bl
	lds	bx,dword ptr ds:[34h]
	xlat
	mov	bl,al
	xor	bh,bh
	inc	bl			; these instructions make bx = -1
	dec	bx			; if and only if bl = -1, else bx = bl.
	xchg	bx,si			; if bx is -1 return original handle
	js	findpy
	xchg	bx,si			; otherwise, return psp handle
	inc	bx			; translated to system handle
	inc	bx
findpy:
	pop	si
	pop	ds
	ret

	subttl setphdl - set psp handle to system handle
	page
;======================================================================
;,fs
; setphdl - set psp handle to system handle
;
; ÚÄ 
; ³ if(ss:[tcbpsp] != 0) exit/cy
; ³ ds = ss:[tcbpsp]
; ³ if(bx >= ds:[32h]) exit/cy
; ³ÚÄ if(ax != -1)
; ³³ÚÄ if(ax < 2 || ax > 100h)
; ³³³ exit/cy
; ³³ÃÄ else
; ³³³ ax -= 2
; ³³ÀÄ 
; ³ÀÄ 
; ³ set psp handle to al
; ³ exit/nc
; ÀÄ 
; 
; if tcbpsp != 0 and psp handle within range
;  if system handle != ffff
;   if system handle out of range, return error 
;   system handle += 2
;  poke low byte of system handle into psp handle entry
;
; in:	bx = psp handle
;	ax = system handle to set (or -1)
;	ss -> tcb
;
; out:	cy if error
;	 ax = syshdl
;	nc if no error
;	 ax = undefined
;
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:tcb
setphdl:
	push	ds
	push	si
	mov	si,[tcbpsp]
	or	si,si
	jz	setpx			; no psp so psp handles are invalid
	mov	ds,si
	cmp	bx,word ptr ds:[32h]
	jae	setpx			; setting >= length of table invalid
	cmp	ax,-1
	je	setp1			; setting to -1 ok
	cmp	ax,2			; system handle must be between 2
	jb	setpx			; and 100h (inclusive) to translate	it
	cmp	ax,100h 		; into a psp handle
	ja	setpx
	dec	ax
	dec	ax
setp1:
	lds	si,dword ptr ds:[34h]
	mov	ds:[bx+si],al
	clc
	jmp	short setpy
setpx:
	mov	ax,syshdl
	stc
setpy:
	pop	si
	pop	ds
     	ret

	subttl getphdl - get free psp handle
	page
;======================================================================
;,fs
; getphdl - get free psp handle
;
; if tcbpsp != 0
;  scan the psp handle table for an ff entry
;  if none found, return error
;  derive psp handle corresponding to free slot found
;
; in:	ss -> tcb
;
; out:	cy if not found
;	 ax = syshdl or manyfil
;	nc if found
;	 bx = psp handle
;	 ax = undefined
;
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:tcb
getphdl:
	push	es
	push	di
	push	cx
	xor	bx,bx
	mov	di,[tcbpsp]
	or	di,di
	mov	ax,syshdl
	stc
	jz	getpx			; no psp implies do nothing
	mov	es,di
	mov	cx,word ptr es:[32h]
	les	di,dword ptr es:[34h]
	mov	bx,di
	mov	al,0ffh
	repne	scasb
	mov	ax,manyfil
	stc
	jne	getpx			; too many files if none found
	xchg	bx,di			; compute offset into table if found
	sub	bx,di
	dec	bx
	clc
getpx:
	pop	cx
	pop	di
	pop	es
	ret

	subttl getthdl - return first available system handle number
	page
;======================================================================
;,fs
; getthdl - return first available system handle number
;
; ÚÄ 
; ³ÚÄ if(ss:[tcbflimit] == 'Y')
; ³³ push bx
; ³³ call getphdl
; ³³ pop bx
; ³³ if(flags == cy) exit/cy
; ³ÀÄ 
; ³ ax = 2
; ³ÕÍ 
; ³³ cx = ss:[tcbtfbpf]
; ³³ÕÍ 
; ³³³ if(cx == 0) exit/nc
; ³³³ es = cx
; ³³³ cx = es:[tfbntcb]
; ³³³ if(ax == es:[tfbhdl]) break
; ³³ÔÍ 
; ³³ ax++
; ³³ if(ax == 0 || (ax == 255 && ss:[tcbflimit] == 'Y')) exit/cy
; ³ÔÍ  
; ÀÄ 
; 
; tcbflimit will be set to 'Y' when a MOS FILES ON command has been
; issued.  the call to getphdl is done to cause an error/exit if the
; current psp handle table is full.
; 
; in the main set of loops, existing tfbhdl values are checked for the 
; first available system handle number.  this search is limited to 255
; if tcbflimit == 'Y'.
; 
; in:	ss -> tcb
;
; out:	nc if no error
;	 ax = lowest numbered available system handle for this task
;	cy if if handle not available
;
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:tcb
getthdl:
	push	es
	push	cx
	cmp	[tcbflimit],'Y' 	; mos limit command sets this
	jne	getthdl0

; if "mos files on" is on then return carry if no psp handle is avaliable

	push	bx
	call	getphdl			; get first free handle
	pop	bx
	jc	getthdl4
getthdl0:
	mov	ax,2			; system handles start at 2
getthdl1:
	mov	cx,[tcbtfbpf]
getthdl2:
	jcxz	getthdl5		; z when checked all tfb's for tcb
	mov	es,cx
	assume	es:tfb
	mov	cx,[tfbntcb]
	cmp	ax,[tfbhdl]
	jne	getthdl2		; on to next tfb
getthdl3:
	inc	ax			; duplicate found
	jz	getthdl4		; no more than 65536 open files
	cmp	ax,255
	jb	getthdl1		; start over from beginning of tfb list
	cmp	[tcbflimit],'Y'
	jne	getthdl1		; if file  limit not set, continue	
getthdl4:
	mov	ax,manyfil
	stc
	jmp	short getthdlx
getthdl5:
	clc				; handle is available
getthdlx:
	pop	cx
	pop	es
	ret

	subttl findgfb - find gfb corresponding to a dir entry or device
	page
;======================================================================
;,fs
; findgfb - find gfb corresponding to a dir entry or device
;
; in:	ds = paragraph address of bdb
;	ss:bx -> sector number for dir entry
;	 si = ofs in sector of dir entry
;	bx = 0
;	 es:si -> device driver
;
; out:	c if not found
;	 es = undefined
;	nc if found
;	 es = segment address of gfb
;
;,fe
;======================================================================
	assume	ds:bdb
findgfb:
	push	cx
	push	dx
	push	ax
	mov	cx,es
fgfb0:
	mgetscb2 es
	assume	es:grp
	mov	ax,[scbgfbpf]
	jmp	short fgfb1a
	assume	es:gfb
fgfb1:
	mov	ax, [gfbnext]		; get next gfb seg			r890511
fgfb1a:
	or	ax,ax
	stc
	jmpz	fgfbx			; z if at end of gfb list (couldn't find gfb)
	mov	es,ax
	or	bx,bx
	ljz	fgfb2			; z if device
	mov	cx,ss:[bx].sechigh
	cmp	cx,[gfbhloc]		; check high word first
	jne	fgfb1
	mov	cx,ss:[bx].seclow
	cmp	cx,[gfbdloc]		; else see if sector and offset of dir entry
	jne	fgfb1			;   matches for this gfb
	cmp	si,[gfbdofs]
	jne	fgfb1
	mov	cx,[bdbreal]		; make sure bdb pointer is the same
	cmp	cx,[gfbbdb]
	jne	fgfb1
	cmp	byte ptr [gfbinvld],0	; is gfb invalid? (from media change)
	jne	fgfb4

; at this point, the essential data matches.  under normal circumstances,
; it would be safe to presume that the gfbname matched the name within
; the directory entry on the disk.  oh... were life so simple.
; due to sloppy fcb usage on the part of skplus 1.01c, it is possible
; to end up with a gfb where everything matches except for the name.

; when the name doesn't match, the gfb is considered orphaned.  all
; rlb's and tfb's will be deallocated.	updating all psp handle tables
; within all tasks would be too complex so this will leave invalid
; handles in existance.

	mov	dx,es			; save gfb pointer in dx
	call	rddir
	assume	es:dbb			; rddir destroys ax
	push	cx
	push	si
	push	di
	push	ds
	lea	di,[dbbbuf+si]
	mov	cx,11
	lea	si,[gfbname]
	mov	ds,dx
	cld
	repe	cmpsb
	pop	ds
	pop	di
	pop	si
	pop	cx
	mov	es,dx
	assume	es:gfb
	lje	fgfbx			; skip out if name matches
	call	closepart		; delete the orphaned resources
	jmp	fgfb0			; restart the list scan 
fgfb4:
	mov	dx,es			; save gfb pointer in dx
	call	rddir
	assume	es:dbb			; rddir destroys ax		r890511
	push	cx
	push	si
	push	di
	push	ds
	lea	di,[dbbbuf+si]
	mov	cx,11
	lea	si,[gfbname]
	mov	ds,dx
	cld
	repe	cmpsb
	pop	ds
	pop	di
	pop	si
	pop	cx
	mov	es,dx
	assume	es:gfb
	je	fgfb3
	jmp	fgfb1
fgfb3:
	mov	byte ptr [gfbinvld],0
	clc
	jmp	fgfbx			; found gfb for dir entry (nc)
fgfb2:
	cmp	cx,word ptr [gfbdrvr+2] ; check for gfb for device
	ljne	fgfb1			;   by comparing driver pointer ;$$$$$$$
	cmp	si,word ptr [gfbdrvr]
	ljne	fgfb1			; found gfb for device (nc) ;$$$$
	cmp	[gfbtspdd],0
	je	fgfbx			; if this gfb is for a task specific dd
	mov	ax,ss			; and this isn't the task it belongs to
	cmp	ax,[gfbtspdd]		; then keep looking
	jmpne	fgfb1
fgfbx:
	pop	ax
	pop	dx
	pop	cx
	ret

	subttl makegfb - make a gfb for a dir entry or device
	page
;======================================================================
;,fs
; makegfb - make a gfb for a dir entry or device
;
; in:	ds = paragraph address of bdb
;	ss:bx -> sector number for dir entry
;	 si = ofs in sector of dir entry
;	bx = 0
;	 es:si -> device driver
;
; out:	c if couldn't be created
;	 ax = error code
;	nc if created ok
;	 es = segment address of gfb
;	 ax = undefined
;
;,fe
;======================================================================
	assume	ds:bdb
makegfb:
	push	ds
	push	di
	push	cx
	mov	cx,es
	xor	ax,ax
	mov	al,'G'
	call	moslim0
	jz	mkgfb1
	cmp	ax,0101h		; (not enough heap space for gfb)
	mov	ax,intern
	stc
	jne	mx0
	mov	ax,manyfil		; (if out of space, call it too many files)
mx0:
	jmp	makgfbx
mkgfb1:
	assume	es:gfb
	mov	[gfbtfb],0		; no tfb's yet
	mov	[gfbrlb],0		; no rlb's yet

; fill out gfb as if for a char device

	mov	word ptr [gfbdrvr],si	; fill out gfb as a character device
	mov	word ptr [gfbdrvr+2],cx ; (device driver address)
	mov	[gfbdev],'Y'		; (nz is a char device)
	lea	di,[gfbname]		; (device name)
	push	ds
	push	si
	push	cx
	mov	ds,cx
	add	si,10
	mov	cx,8/2
	rep	movsw
	mov	ax,'  '
	stosw
	stosb
	pop	cx
	pop	si
	pop	ds
	or	bx,bx
	jnz	mgx1

; device driver address in cx:si - check to see if this driver
; is in the task specific list

	push	ax
	push	bx
	push	ds
	lds	bx,[tcbddpf]
mgfbtdd1:
	mov	ax,ds
	and	ax,bx
	inc	ax
	jz	mgfbtddx
	cmp	bx,si
	jne	mgfbtdd2
	mov	ax,ds
	cmp	ax,cx
	jne	mgfbtdd2
	mov	[gfbtspdd],ss
	jmp	short mgfbtddx
mgfbtdd2:
	lds	ax,[bx]
	mov	bx,ax
	jmp	short mgfbtdd1
mgfbtddx:
	pop	ds
	pop	bx
	pop	ax
	jmp	makgfbx

; make gfb for block device file

mgx1:
	mov	[gfbdev],0		; isn't a char device
	mov	cx,word ptr [bdbdrvr]	; address of block device driver
	mov	word ptr [gfbdrvr],cx
	mov	cx,word ptr [bdbdrvr+2]
	mov	word ptr [gfbdrvr+2],cx
	mov	cx,[bdbreal]
	mov	[gfbbdb],cx		; address of bdb for file
	mov	cx,ss:[bx].seclow
	mov	[gfbdloc],cx		; sector of dir sector for file
	mov	cx,ss:[bx].sechigh
	mov	[gfbhloc],cx		; high word of sector
	mov	[gfbdofs],si		; offset within sector of dir sector for file
	mov	[gfbwrtn],0		; file not written since gfb created
	mov	cx,es			; remember location of new gfb

; fill out remainder of file gfb from dir entry

	call	rddir			; read sector containing dir entry for file
	jmpc	makgfby
	mov	ds,cx
	assume	ds:gfb,es:dbb
	mov	al,[si+dbbbuf+datr]	; directory entry attribute
	mov	[gfbattr],al
	mov	ax,word ptr [si+dbbbuf+dclust]	; first allocated cluster
	mov	[gfbcbof],ax
	mov	[gfbcmax],ax		; last cluster encountered so far
	mov	[gfbrcmax],0		; relative number of that cluster (0th)
	mov	ax,word ptr [si+dbbbuf+dsize]  ; file size
	mov	word ptr [gfbsize],ax
	mov	ax,word ptr [si+dbbbuf+dsize+2]
	mov	word ptr [gfbsize+2],ax
	mov	ax,word ptr [si+dbbbuf+dtime]  ; file time
	mov	[gfbtime],ax
	mov	ax,word ptr [si+dbbbuf+ddate]  ; file date
	mov	[gfbdate],ax

; the following logic is handler strange occurances where other
; systems will modified the class bits, if not 'A' - 'Z' range
; mark file with null class

	xor	al,al			; default to space
	mov	ah,byte ptr [si+dbbbuf+dclass0]
	cmp	ah,'A'
	jb	mgfbc1
	cmp	ah,'Z'
	ja	mgfbc1
	mov	al,ah			; set if in range 'A' - 'Z'
mgfbc1:
	mov	[gfbclass],al
	push	es			; xchg ds,es
	push	ds
	pop	es
	pop	ds
	assume	ds:dbb,es:gfb
	lea	si,[si+dbbbuf]		; -> dir entry file name
	mov	cx,5			; moving 11 bytes (5*2+1)
	lea	di,[gfbname]		; -> gfb name
	rep	movsw
	movsb

; compute file encryption/decryption key

	mov	si,dx
	mov	ax,[gfbcbof]
	sub	ax,2			; cluster is 2-based
	mov	dx,26			; 26 possible classes
	mul	dx
	mov	cl,[gfbclass]
	sub	cl,'A'			; class is 'A'-based
	xor	ch,ch
	add	ax,cx
	adc	dx,0
	mgetscb2 ds
	assume	ds:grp
	add	ax,word ptr [scbkey+2]
	adc	dx,word ptr [scbkey]
	mov	word ptr [gfbkey],ax
	mov	word ptr [gfbkey+2],dx
	mov	dx,si
	clc				; no error
	jmp	makgfbx

; deallocate gfb if any error occurs after it's allocated

makgfby:
	mov	es,cx
	push	ax			; remember error code
	mov	ah,1
	mov	al,'G'
	call	moslim0 		; delete gfb
	pop	ax
	stc
makgfbx:
	pop	cx
	pop	di
	pop	ds
	ret

	subttl ckdev0 - check device support
	page
;======================================================================
;,fs
; ckdev0 - check device support
;
; in:	al = driver command number
;	es -> gfb
;
; out:
;	carry flag set if error
;
;,fe
;======================================================================
	assume	es:gfb
ckdev0:
	push	ds
	xor	dx,dx
	mov	ah,80h or dosx or rdx	; for char device
	cmp	[gfbdev],0
	jne	openf1c
	and	ah,7fh			; else block device
	mov	ds,[gfbbdb]
	assume	ds:bdb
	mov	dl,[bdbunit]		; unit within block device driver
	mov	dh,[bdbid]		; drive number
openf1c:
	lds	si,[gfbdrvr]
	assume	ds:nothing
	test	byte ptr [si+5],08h	; driver supporting open/close/rm ?
	jz	openf2
	call	devchk
openf2:
	pop	ds
	ret

	subttl moslim0 - call mosliman in mos segment
	page
;======================================================================
;,fs
; moslim0 - call mosliman in mos segment
;
; in:	ax = mode and table name
;
; out:
;	zero flag set if no internal errors
;
;,fe
;======================================================================
moslim0:
	callmos1 mosliman		;** call in mos segment
	or	al,al
	ret

	subttl fat16 - setup and read allocation table entry, 16-bit entries
	page
;======================================================================
;,fs
; fat16 - setup and read allocation table entry, 16-bit entries
;
; in:	ds -> bdb
;	????
;
; out:	????
;
;,fe
;======================================================================
	assume	ds:bdb
fat16:
	add	ax,ax
	mov	bx,ax			; c:bx = offset within fat of fat entry
	rcr	bx,1			; (carry is significant if present)
	xchg	bx,ax
	mov	cx,[bdbssiz]
	shr	cx,1			; /2 because of rcr above
	push	dx
	xor	dx,dx
	div	cx
	xchg	bx,ax
	xor	dx,dx
	mov	cx,[bdbssiz]
	div	cx
	mov	cx,dx
	pop	dx
	call	rdfat
	ret

	subttl fat12 - setup and read allocation table, 12-bit entries
	page
;======================================================================
;,fs
; fat12 - setup and read allocation table, 12-bit entries
;
; in:	ds -> bdb
;	????
;
; out:	????
;
;,fe
;======================================================================
	assume	ds:bdb
fat12:
	add	ax,ax			; fat offset = (cluster * 3) / 2
	add	ax,dx
	shr	ax,1
	mov	bx,ax			; bx = offset in fat of entry
	xchg	bx,ax
	mov	cx,[bdbssiz]
	push	dx
	xor	dx,dx
	div	cx
	xchg	bx,ax
	xor	dx,dx
	mov	cx,[bdbssiz]
	div	cx
	mov	cx,dx
	pop	dx
	call	rdfat
	ret

	subttl markdirty - change a uob's write status
	page
;======================================================================
;,fs
; markdirty - change a uob's write status
;
; if wrx not set in es:[di].cstatus,
;   set it
;   if scbcwnum >= scbcwmax
; 	  flush the cache
;   increment scbcwnum (number of dirty buffers)
;
; in:	es:di -> uob descriptor
;
; out:	all registers but flags preserved
;
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:nothing
markdirty:
	test	es:[di].cstatus,wrx
	jnz	mdx
	push	ds
	push	ax
	mgetscb2 ds
	assume	ds:grp
	mov	ax,[scbcwmax]
	cmp	ax,[scbcwnum]
	ja	md1
	or	ax,ax
	jz	md1
	call	flush
md1:
	or	es:[di].cstatus,wrx
	inc	[scbcwnum]
	pop	ax
	pop	ds
	assume	ds:nothing
mdx:
	ret

	subttl markclean - change a uob's write status
	page
;======================================================================
;,fs
; markclean - change a uob's write status
;
; if wrx set in es:[di].cstatus,
;  if scbcwnum > 0, decrement scbcwnum (number of dirty buffers)
;
; in:	es:di -> uob descriptor
;
; out:	all registers but flags preserved
;
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:nothing
markclean:
	test	es:[di].cstatus,wrx
	jz	mcx
	push	ds
	mgetscb2 ds
	assume	ds:grp
	and	es:[di].cstatus,not wrx
	cmp	[scbcwnum],0
	je	mc1
	dec	[scbcwnum]
mc1:
	pop	ds
	assume	ds:nothing
mcx:
	ret

	subttl cmap - low-level map a uob
	page
;======================================================================
;,fs
; cmap - low-level map a uob
;
; if not memory-managed,
;   return segment
; 	[scbchdl] + [scbcuob] * (di/cachedescriptorsize)
; else
;   map handle
; 	[scbchdl] + ( [scbuob] * (di/cachedescriptorsize) ) / (4096/16)
;   for
; 	( remainder + [scbuob] + ( (4096/16) - 1 ) ) / (4096/16) pages
;   return segment
; 	[scbcseg] + remainder
; set [scbcele] to segment (address of current uob)
; set [scbccur] to di (current uob descriptor)
;
; can't do disk i/o from the time scbmmfea is defined (memdev loaded)
;   until scbcseg is defined (because there's no place to map
;   a cache buffer)
; anything which might do int 10h's (like int 24h) could map into the
;   screen save buffer, so while the data must be mapped, anything
;   which might do any int 10h has to be surrounded by a save then
;   restore of mapvsa variables (of course serial irq's are handled)
;
; in:	es:di -> uob descriptor
;
; out:	es -> uob
;	ax, es destroyed, all others unchanged
;
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:nothing
cmap:
	push	ds
	push	dx
	push	cx
	push	bx
	mgetscb2 ds
	assume	ds:grp
	mov	[scbclbdb],0		; nullify rdsector optimization
	mov	ax,di
	mov	cl,4
	shr	ax,cl			; ax = uob number
	mul	[scbcuob]		; ax = para offset into cache
	test	[scbmmfea],80h
	jnz	mapc2

; non-memory-managed

	add	ax,[scbchdl]		; + start segment of cache if no mm
	mov	es,ax
	jmp	mapcx
mapc2:

; memory-managed

	mov	dh,al			; dh = (dx:ax) mod (4096/16)
	mov	al,ah
	mov	ah,dl			; ax = (dx:ax) / (4096/16)
	add	ax,[scbchdl]		; + handle of start of cache
	mov	bx,ax			; bx = handle to map
	mov	al,dh
	xor	ah,ah			; ax = remainder which is
	push	ax			;   paragraph offset into mapping space
	add	ax,[scbcuob]		; remainder + buffer size = paras needed to map
	add	ax,(4096/16)-1		; rounding for # pages
	mov	al,ah
	xor	ah,ah			; / (4096/16) for # pages
	mov	cx,ax			; cx = # pages to map
	cmp	bx,[scbclbx]		; if last bx and cx values are
	jne	mapc4			; the same as this request, skip the
	cmp	cx,[scbclcx]		; mm call to save time.
	je	mapc3
mapc4:
	mov	[scbclbx],bx
	mov	[scbclcx],cx
	mov	ah,03h			; remap
	mov	es,[scbcseg]
	cli
	call	[scbmmsub]
	sti
mapc3:
	pop	ax			; para offset into mapped area
	add	ax,[scbcseg]
	mov	es,ax			; seg start of uob
mapcx:
	mov	[scbccur],di		; current uob descriptor
	mov	[scbcele],es		; seg address of current uob
	pop	bx
	pop	cx
	pop	dx
	pop	ds
	assume	ds:bdb
	ret

	subttl cfree - low-level free a uob
	page
;======================================================================
;,fs
; cfree - low-level free a uob
;
; uob is marked free by setting cnumsct = 0 (number of sectors in
;   buffer) in the descriptor
; deleted from usage list and re-inserted last
; deleted from location list (now it doesn't have a location)
; if deleted uob is referenced in scbcsave, the respective scbcsave
;   reference is adjusted to refer to the newly prior (next) uob
; if deleted uob is scbcnxt, set scbcnxt to prior uob (will only
;   happen on a coalesce, so there must be a prior uob which now
;   includes the old scbcnxt)
;
; if cnumsct is 0 (uob is already free) no action is taken
; the data in the uob is thrown away, no check is made to see if
;   it should be written (so that has to be done before this)
; next and prior location pointers set to -1 (no next and no prior)
;   unnecessarily because it makes the free uob's easier to see in
;   a dump
; if the location prior pointer is -1 (no prior uob) and no bdb first
;   location pointer points to it, either you'll hang up in the bdb
;   lookup loop or offset bdbclpf in segment 0 will be set to -1
;   this could happen because of a code bug or something walking on
;   the cache descriptors
; cfree can't change scbcseg mapping because cacheit relies on the
;   uob staying mapped through the cfree call
;
; in:	ds -> bdb
;	es:di -> uob descriptor
;
; out:	ax destroyed, all others unchanged
;
;,fe
;======================================================================
	assume	ds:bdb,es:nothing,ss:nothing
cfree:
	cmp	es:[di].cnumsct,0	; don't bother if its already empty
	jmpe	cf5
	push	si
	push	bx
	push	ds
	call	clearbit		; clear from bit map
	mov	es:[di].cnumsct,0	; set it empty
	call	markclean
	mov	es:[di].cstatus,0	; (especially wrx and fatx bits)
	mgetscb2 ds
	assume	ds:grp
	mov	[scbclbdb],0		; nullify rdsector optimization
	mov	si,es:[di].clocprv
	mov	bx,es:[di].clocnxt

; adjust scbcsave references if needed

	cmp	di,[scbcsave].clocprv
	jne	cf0a
	mov	[scbcsave].clocprv,si	; new prior
cf0a:
	cmp	di,[scbcsave].clocnxt
	jne	cf0b
	mov	[scbcsave].clocnxt,bx	; new next
cf0b:
	cmp	di,[scbcnxt]
	jne	cf0c
	mov	[scbcnxt],si
	cmp	si,-1
	jne	cf0c
	mov	[scbcnxt],bx
cf0c:

; delete from location list

	cmp	si,-1
	jne	cf1c

; first in location list, find the bdb

	mov	ax,ds
	pop	ds
	push	ds
	assume	ds:bdb
	mov	[bdbclpf],bx		; set bdb first pointer to new first
	mov	ds,ax
	assume	ds:grp
	jmp	cf2a
cf1c:					; here if wasn't first in list
	mov	es:[si].clocnxt,bx	; link prior to next
cf2a:
	cmp	bx,-1
	je	cf2b			; e if was last in list
	mov	es:[bx].clocprv,si	; link next to prior
cf2b:
	mov	es:[di].clocprv,-1
	mov	es:[di].clocnxt,-1

; delete from usage list

	cmp	di,[scbcupf]
	jne	cf3			; e if was first in usage list
	mov	ax,es:[di].cusenxt	; adjust head pointer so it's last
	mov	[scbcupf],ax
	jmp	short cf4
cf3:
	mov	si,es:[di].cuseprv
	mov	bx,es:[di].cusenxt
	mov	es:[si].cusenxt,bx
	mov	es:[bx].cuseprv,si

; insert at end of usage list

	mov	bx,[scbcupf]
	mov	si,es:[bx].cuseprv
	mov	es:[bx].cuseprv,di
	mov	es:[si].cusenxt,di
	mov	es:[di].cusenxt,bx
	mov	es:[di].cuseprv,si
cf4:
	pop	ds
	assume	ds:bdb
	pop	bx
	pop	si
cf5:
	ret

	subttl clearbit - clr bitmap bit @ es:[di].csector for [bdbid] drive
	page
;======================================================================
;,fs
; clearbit - clr bitmap bit @ es:[di].csector for [bdbid] drive
;
; in:
;
; out:	no registers changed except flags
;
;,fe
;======================================================================
	assume	ds:bdb,es:nothing,ss:nothing
clearbit:
	push	es
	push	di
	push	dx
	push	ax

;##<
;## this instance of deriving a 24 bit sector number was not converted
;## to a 32 bit form.  dx:ax is used as a seed to the random function.

;	mov	ax,word ptr es:[di].csector
;	mov	dl,es:[di].csector+2

	mov	ax,es:[di].csector
	mov	dl,byte ptr es:[di].csector+2
;##>

	mov	dh,[bdbid]
	call	bitaddr
	not	al
	and	es:[di],al
	mgetscb2 es
	assume	es:grp

; when number removed from cache = number cache buffers,

	dec	[scbcclr]
	jnz	clrb1

; clear the cache bit map

	mov	di,[scbcnum]
	mov	[scbcclr],di
	push	cx
	mov	cx,[scbcbmsz]
	shl	cx,1
	shl	cx,1
	shl	cx,1			; # words in cache bit map
	xor	ax,ax
	mov	di,ax
	mov	es,[scbcbmap]
	rep	stosw
	pop	cx
clrb1:
	pop	ax
	pop	dx
	pop	di
	pop	es
	ret

	subttl setbit - set bitmap bit @ es:[di].csector for [bdbid] drive
	page
;======================================================================
;,fs
; setbit - set bitmap bit @ es:[di].csector for [bdbid] drive
;
; in:
;
; out:	no registers changed except flags
;
;,fe
;======================================================================
setbit:
	push	es
	push	di
	push	dx
	push	ax


;##<
;## this instance of deriving a 24 bit sector number was not converted
;## to a 32 bit form.  dx:ax is used as a seed to the random function.

;	mov	ax,word ptr es:[di].csector
;	mov	dl,es:[di].csector+2

	mov	ax,es:[di].csector
	mov	dl,byte ptr es:[di].csector+2


	mov	dh,[bdbid]
	call	bitaddr
	or	es:[di],al
	pop	ax
	pop	dx
	pop	di
	pop	es
	ret

	subttl testbit - test bitmap bit @ es:[di].csector for [bdbid] drive
	page
;======================================================================
;,fs
; testbit - test bitmap bit @ es:[di].csector for [bdbid] drive
;
; in:
;
; out:	return z flag if 0, else nz
;	no registers changed except flags
;
;,fe
;======================================================================
testbit:
	push	es
	push	di
	push	dx
	push	ax
	mov	ax,ss:[bx].seclow
	mov	dx,ss:[bx].sechigh
	mov	dh,[bdbid]
	call	bitaddr
	mov	ah,es:[di]
	or	es:[di],al
	test	ah,al
	pop	ax
	pop	dx
	pop	di
	pop	es
	ret

	subttl bitaddr - 
	page
;======================================================================
;,fs
; bitaddr - 
;
; in:
;
; out:	es:di -> byte, 
;	al w/ bit set for bit map bit corresponding to es:di -> uob, 
;	  bdbid drive
;
;,fe
;======================================================================
	assume	ds:bdb
bitaddr:
	cmp	word ptr ds:[0],'BH'
	je	bit1
	callmos1 bugerror
	db	'DS <> BDB @ bitaddr',0
bit1:
	push	ds
	push	cx
	push	bx
	call	random

; we assume the most significant word is the most random (dx)

	mgetscb2 ds
	assume	ds:grp

; we treat the word as a fraction, multiply by # bits in bit map
; and truncate the resulting fraction

	mov	ax,dx
	mul	[scbcbmsz]

; shift left 4 (paras) + 3 (bits) == shift left 1 byte + shift right 1 bit

	mov	bh,dl
	mov	bl,ah
	shr	dh,1
	rcr	bx,1

; bx = 0 - (# bits - 1)

	mov	ah,bl
	mov	cl,3
	shr	bx,cl

; bx = byte offset into bit map

	mov	di,bx
	mov	es,[scbcbmap]
	mov	cl,ah
	and	cl,7
	mov	al,1
	shl	al,cl

; al = bit offset into byte

	pop	bx
	pop	cx
	pop	ds
	ret
	assume	ds:nothing

	subttl findbdbc - ???
	page
;======================================================================
;,fs
; findbdbc - ???
;
; to make sure cfree always gets a target bdb
;
; in:
;
; out:	ds -> bdb for es:di -> uob
;	no registers changed except ds & flags
;
;,fe
;======================================================================
findbdbc:
	push	bx
	push	ax
	cmp	es:[di].cstatus,0
	je	fbdbcx
	mov	ax,di

; find first in uob list for bdb

fbdbc1:
	mov	bx,ax
	mov	ax,es:[bx].clocprv
	cmp	ax,-1
	jne	fbdbc1

; bx = first in uob list

	mgetscb2 ds
	assume	ds:grp
	mov	ax,[scbbdbpf]
fbdbc2:
	or	ax,ax
	jz	fbdbcx
	mov	ds,ax
	assume	ds:bdb
	mov	ax,[bdbnext]
	cmp	bx,[bdbclpf]
	jne	fbdbc2
	mov	ds,[bdbreal]

; ds = bdb -> first in list

fbdbcx:
	pop	ax
	pop	bx
	ret

ddt	ends
	end

