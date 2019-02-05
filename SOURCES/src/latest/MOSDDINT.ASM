
; '##' markings surround changes for bdbsctr/csector/sechigh/seclow


	include page.inc
	title	mosddint.asm - device driver initialization

extrn	bugerror:near			;enable debug stack error reporting
comment ^===============================================================
		      development specification

 program name:	$$mos.com		 assigned to: jim bean
 module name:	mosddint		 assign date: 01/30/86
 entry points:	mosddint		 completed:   02/12/86
 entry from:	mosxxxxx
 entry method:	call
 calls:		mosheman
 purpose:	device driver initialization
 last update:	09/02/1992
========================================================================

discussion of mosddint as implemented

this routine provides for initializing a device driver.  if it is a
block device, a bdb is built for it.  if it has a "standard" name
(con, prt, etc.), appropriate steps are taken to assure that it is
treated as standard input, output, or whatever.

registers passed are:
     es - address of driver

registers returned are:
     al - return code; 0 if all is ok

this routine provides for initializing a device driver.  if it is
a block device, a bdb is built for it.  if the standard character
device bits are set, the standard character device pointers are set
to the new driver

bit 0 = stdin standard input device
bit 1 = stdout standard output device
bit 2 = nul device (we allow it to be re-defined, unlike pcdos)
bit 3 = clock device
device name prn = standard printer device (not defined in pcdos)
device name aux = standard auxilliary device (not defined in pcdos)

it is called with es:bx = address of start of device driver
ds:dx points to the remainder of the arguments from the specification
  of the device driver
it returns al = 0 if no error
else al = error code

error codes are:
0	 no error
1 - 7  mosheman error codes from driver allocation adjustment
  ( driver requested more space than was available)
8	 block device driver specified an invalid sector size
9 - 15 mosliman error codes + 8 from bdb allocation request
   (block device block allocation failed)

also changed mosbdb.inc to reflect the fact that we don't allow a
block device to set a sector size larger than our maximum and
added some shift counts to rapidly convert between sectors and blocks
and between allocation units (clusters) and blocks

added to sys block
sysdrives:byte the number of drives allocated so far
sysbufsz:word  the maximum size of a sector
sysstdin:dword pointers to standard device drivers
sysstdout, sysstdnul, sysstdclk, sysstdprn, sysstdaux

=======================================================================

jrb 02/12/86	have to set the first byte of the name field to 
		the number of units after calling a block device 
		driver for init

jrb 02/13/86	make use of scbhpadr and scbhpsiz to determine if
		device driver is a built-in device driver, to more
		accurately detect whether or not we need to call
		mosheman to adjust the allocation

jrb 02/17/86	changed scb??? to scbstd??? as it refers to standard
		devices as well as scbdrives to scbdrivs (because they
		ended up in scb that way)
		changed the allocation of a bdb to use mosliman instead
		of mosheman

jrb 02/24/86	support segmentation for romable code

jrb 03/03/86	changed bdbclus and bdbcnum because mosfun39 does the 2
		cluster calculation and doesn't need (or want) it
		precomputed
		bdbunit wasn't being set correctly

jrb 03/04/86	corrections from mosinit testing don't assume ds:grp
		coming into mosddint device driver in heap points one
		paragraph past block header for purposes of mosehman
		shrinking, so have to decrement it for mosheman

jrb 04/09/86	setbdb was setting bdbssiz incorrectly, and was not
		setting bdbsshl

jrb 04/22/86	added lundef to lproc mosddint variables

jrb 04/24/86	changed segment class from 'code' to 'data' for gdata,
		poll, irq

jrb 07/28/86	allocate a cdb as well as a bdb when init'ing a block
		device de-allocate bdb on error after it's allocated
		pass mosbdint -> request block from init instead of ->
		device driver

jrb 08/04/86	pass mosbdint -> driver and -> request block

jrb 08/25/86	set ds to scbseg after storing parameter pointer

jrb 09/02/86	change setbdb not to set unnecessary bdb parameters -
		just sets bdb from bpb

dam 09/08/86	on exit dx -> segment of next available memory passed
		back from driver

jrb 09/22/86	add various dpb fields to setbdb

dam 12/09/86	handle block devices that return 0 size and/or 0 units
		active

jsm 03/24/87	large volume support in setbdb

rbr 07/05/87	if sector size of standard block device is too big,
		don't abort...  just invalidate the drive.

sah 01/20/88	change scbseg and zero seg access to mgetxxx
		macros.

sah 01/22/88	removed external reference to scbseg

sah\rbr 02/21/88 move ddt segment to mo2 group

jrb 05/02/88  added init needed for cache to setbdb

jrb 05/13/88	wrong sense of jump invalidating sectors/track if
		too many cylinders

sah 07/28/88	corrected problem with uppermemory by adding a test to
		see if requested value is greater f000h (just in case
		we change the fff8 address)

mjs 09/01/88	cleaned up extraneous crlf's, spaces, etc.

sjc 09/16/88	disallow cacheing on lanlink block devices

mjs 10/21/88	combine the actions of linkdrv into mosddint and make
		modifications to support task specific device drivers.

mjs 10/22/88	corrections to the calculation of the next free segment
		value which mosddint returns in dx.  for who knows how
		long, when a driver is loaded, we've been wasting SMP
		on it due to this one.

mjs 04/16/89	corrected adj_smp_alloc to de-allocate the block when
		the driver returns a status error.  modify to pass a
		driver status error back to the caller.  modify to
		restore the root pointer when an error occurs.

sah 08/28/89	corrections to adj_smp_alloc not to delete actual block
		but just leave the header there, it was causing device
		drivers to lock up  when if user did bad syntax and
		driver indicated that it did not want to install by
		return cs:0 in requested header.

mjs 08/31/89	complete correction to problem with device drivers
		which return cs:0 to abort their loading.  restored
		adj_smp_alloc to its previous state.  modified the logic
		within the mosddint main procedure to unlink a driver
		when a cs:0 return is made.  for the 4.00 masters,
		the ndev4xx.pat series now replaces the dev4xx.pat
		series.  convert the mosddint procedure to action chart
		and add 'include xifmacs'.

mjs 10/10/89	modified sector size calculations.

sah 12/15/89	corrections for split-smp

sah 01/15/91	corrections for intel fax device driver, don't error
		out if busy bit (bit 9) is set in status word.

sah 02/05/91	corrections for device driver will be supported by
		undocumented dos techniques

mjs 04/03/91	change a je to a jne from sah's 02/05/91 changes.
		improve method of determining when scbdrvr points
		to scbnul (should also test the segment).
		clean up module.

mjs 12/16/91	dlg mods: convert operations on bsFATsecs from byte to word.
		convert handling large partitions, from the mlg 24 bit
		sector number format to the 32 bit dlg format.  converted
		to use of structures within dskstruc.inc.
 
================ 5.01 Kernel Ends Here ====================================

mjs 08/18/92	clean up segment declarations

SAH 09/02/92	Corrections for Bernoulli 90 Pro... OADDOS.SYS has 
		multiable device driver in a list an if it desires
		that it does not need to include the other device
		drivers in driver it will terminated the list early.
		I add code to check for this codition and correct the
		problem.
		(Corrected for MOS 5.01 with patch 501_p04.pat)

=======================================================================^

.xlist
;	include mosddint.pub
	include group.inc
	include mosregs.inc
	include moscdb.inc
	include mosbdb.inc
	include macros.inc
	include dskstruc.inc

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
	assume	cs:mos,ds:nothing,es:nothing,ss:tcb
	extrn	mosend:byte, sbios:word

	extrn	mosheman:near, mosliman:near, scbnul:word
	extrn	get_true_clusters:near

	public	mosddint, setbdb

prnname db	'PRN     '		; name of standard printer device
auxname db	'AUX     '		; name of standard auxilliary device
ramname db	'$RAMDISK'

	subttl mosddint - device driver initialization code
	page
;======================================================================
;,fs
; mosddint - device driver initialization code
;
; mosddint provides for initializing a device driver.  if it is
; a block device, a bdb is built for it.  if the standard character
; device bits are set, the standard character device pointers are set
; to the new driver
;
; attribute word bit values:
; bit 0 = stdin standard input device
; bit 1 = stdout standard output device
; bit 2 = nul device (we allow it to be re-defined, unlike pcdos)
; bit 3 = clock device
; device name prn = standard printer device (not defined in pcdos)
; device name aux = standard auxilliary device (not defined in pcdos)
;
; in:	es:bx -> device driver
;	ds:dx -> parameter string (e.g. from config.sys line)
;	al = 0 if driver is to be linked into scbdrvr list
;	al = 1 if to be linked into tcbddpf list (adddev option)
;	al = 2 if not to be linked (special mosinit usage)
;
; out:	dx = next free segment
;	for entry al = 0, al = result code:
;         0	 no error
; 	  1 - 7  mosheman error codes from driver allocation adjustment
; 	  	  ( driver requested more space than was available)
; 	  8	 block device driver specified an invalid sector size
; 	  9 - 15 mosheman error codes + 8 from bdb allocation request
; 	  	   (not enough memory to allocate block device blocks)
; 	  ff	 error status from device driver
;
;,fe
;=====================================================================
	assume	ds:nothing,es:nothing,ss:tcb
lproc	mosddint
lstring ddrequest,23			; device request block
ldword	nxtdrvr 			; next driver in multi header file
ldword	parmptr 			; original ds:dx
lbyte	linktype			; original al
ldword	origesbx			; original es:bx
ldword	origroot			; original root pointer - for restoration on error
ldword	origroot2			; storage for scbdrvr next in list pointer
lword   lastdrvr			
ldword  savedrvr
	push	bx
	push	cx
	push	si
	push	di
	push	ds
	push	es
	mov	word ptr [parmptr],dx
	mov	word ptr [parmptr+2],ds
	mov	[linktype],al
	mov	word ptr [origesbx],bx
	mov	word ptr [origesbx+2],es
	mgetscb ds
	assume	ds:grp
	mov	ax,word ptr [scbdrvr]
	mov	word ptr [origroot],ax
	mov	ax,word ptr [scbdrvr+2] ; record the original root pointer so
	mov	word ptr [origroot+2],ax; a restoration can be made if error

; when mosddint is called by adddev, scbdrvr will point to scbnul.
; for the sake of undocumented dos support, scbdrvr must not be
; changed.  as new global drivers are linked in by adddev, the next
; pointer of the scbnul driver must be treated as the root of the
; linked list rather than scbdrvr.  therefore, in case the driver
; decides not to load, this next pointer must be saved for possible
; restoration. 

	call	if_scbnul
	jne	skdd1
	push	ds
	push	si
	lds	si,[scbdrvr]
	mov	ax,ds:[si]
	mov	word ptr [origroot2],ax
	mov	ax,ds:[si+2]
	mov	word ptr [origroot2+2],ax
	pop	si
	pop	ds
skdd1:
	cmp	[linktype],1 
	jne	msdd6 
	mov	ax,word ptr [tcbddpf]	; overwrite for task specific case
	mov	word ptr [origroot],ax
	mov	ax,word ptr [tcbddpf+2]
	mov	word ptr [origroot+2],ax

; when there is more than one header in a file, only the offsets are linked.
; the following line is redundant for the first pass through this loop but
; required for the extra passes which will occur in the multi header case.

msdd6:
	mov	es,word ptr [origesbx+2]
	cmp	[linktype],2 		; linktype 2, special case from mosinit
	je	msdd3 
	mov	ax,es:[bx]		; when linktype == 0 or 1, save the
	mov	word ptr [nxtdrvr],ax	; driver's next pointer in case of
	mov	ax,es:[bx+2]		; multiple headers per file
	mov	word ptr [nxtdrvr+2],ax
	mov	[lastdrvr],bx
	cli
	cmp	[linktype],1 
	je	msdd4 
	mov	ax,word ptr [scbdrvr]	; linktype assumed to be 0, link

; if scbdrvr is pointing to scbnul then adddev must be calling mosddint.
; in that case, jump to msdd6a to link the new driver in using the
; next pointer of the scbnul driver as the root.  otherwise, must
; be loading a driver from config.sys.  in that case, use scbdrvr as
; the root.   

	call	if_scbnul
	je	msdd6a
	mov	es:[bx],ax		; into global list
	mov	ax,word ptr [scbdrvr+2]
	mov	es:[bx+2],ax
	mov	word ptr [scbdrvr],bx
	mov	word ptr [scbdrvr+2],es
	jmp	short msdd3  
msdd6a:
	push	ds
	push	si
	lds	si,[scbdrvr]
	mov	ax,ds:[si]
	mov	es:[bx],ax		; into global list
	mov	ax,ds:[si+2]
	mov	es:[bx+2],ax
	mov	ds:[si],bx
	mov	word ptr ds:[si+2],es
	pop	si
	pop	ds
	jmp	short msdd3
msdd4:
	mov	ax,word ptr [tcbddpf]	; must be adddev, doing a task specifc
	mov	es:[bx],ax		; device driver load (linktype = 1)
	mov	ax,word ptr [tcbddpf+2]
	mov	es:[bx+2],ax
	mov	word ptr [tcbddpf],bx
	mov	word ptr [tcbddpf+2],es
msdd3:
	sti
	mov	ax,word ptr es:[bx]		; save next on list 
	mov	word ptr [savedrvr],ax		; for cases like 
	mov	ax,word ptr es:[bx+2]		; Bernoulli 90 Pro
	mov	word ptr [savedrvr+2],ax
	lea	di,[ddrequest]		; ss:di -> device request block
	mov	ax,word ptr [parmptr]
	mov	word ptr ss:[di+18],ax	; set pointer to arguments
	mov	ax,word ptr [parmptr+2] ; in request block
	mov	word ptr ss:[di+20],ax
	push	di
	call	ddinit0
	pop	di

; skip linking details if special mosinit case exit loop if error
; from mosbdint else, set es:bx to the original next driver pointer
; of the current driver and go back through the loop until done
; Updated 09/02/92 SAH, to include special case for handle drivers
; like IOMEGA's OADDOS.SYS which has multible drivers but only includes
; what it needs

	cmp	[linktype],2 
	je	msdd5 
	cmp	al,0 
	jne	msdd1 
	mov	bx,[lastdrvr]		   ; point to last driver init
	cmp	word ptr es:[bx],-1	   ; did the driver request to	
	jne	msdd1s			   ; to terminate remaing ones? no
;
;  driver does not need remaining drivers in file, so replace list
;  with one saves earler and make sure we don't loop back
;
	push	ax
	mov	ax,word ptr [savedrvr]
	mov	word ptr es:[bx],ax
	mov	ax,word ptr [savedrvr+2]
	mov	word ptr es:[bx+2],ax
	pop	ax
	jmp	short msdd1
msdd1s:
	les	bx,[nxtdrvr]
	cmp	bx,-1
	je	msdd1
	jmp	msdd6
msdd1:
	cmp	[linktype],0 		; if linktype = 0 adjust smp allocation
	jne	msdd5 
	mov	cl,al			; save original error status
	les	bx,[origesbx]		; need original es:bx for smp adjustment
	push	cx
	call	adj_smp_alloc
	pop	cx
	or	al,cl			; form cumulative error status
msdd5:
	cmp	[linktype],2 		; if skip linking, skip recovery test
	je	msdd7 

; if the driver returns cs:0000 or there is an error, unlink

	lea	di,[ddrequest]		; ss:di -> device request block
	call	calc_size
	cmp	dx,word ptr [origesbx+2] 
	je	msdd5a 
	cmp	al,0 
	je	msdd7 
msdd5a:
	mov	cx,word ptr [origroot]
	mov	dx,word ptr [origroot+2]
	cmp	[linktype],1 
	je	msdd8 
	mov	word ptr [scbdrvr],cx	; unlink for the global case
	mov	word ptr [scbdrvr+2],dx

; if scbdrvr points to scbnul (mosddint called by adddev) then the
; next pointer of the scbnul driver must be restored.

	call	if_scbnul
	jne	msdd7
	push	ds
	push	si
	lds	si,[scbdrvr]
	mov	cx,word ptr [origroot2]
	mov	word ptr ds:[si],cx
	mov	cx,word ptr [origroot2+2]
	mov	word ptr ds:[si+2],cx
	pop	si
	pop	ds
	jmp	short msdd7
msdd8:
	mov	word ptr [tcbddpf],cx	; unlink for the task specific case
	mov	word ptr [tcbddpf+2],dx
msdd7:
	lea	di,[ddrequest]		; ss:di -> device request block
	call	calc_size
	pop	es
	pop	ds
	pop	di
	pop	si
	pop	cx
	pop	bx
lundef	ddrequest,23
lundef	nxtdrvr
lundef	parmptr
lundef	linktype
lundef	origesbx
lundef	origroot
lundef	origroot2
lundef	lastdrvr
lundef	savedrvr
lendp	mosddint

	subttl if_scbnul - see if scbdrvr points to scbnul
	page
;======================================================================
;,fs
; if_scbnul - see if scbdrvr points to scbnul
;
; in:	ds -> grp
;
; out:	zr if scbdrvr points to scbnul
;	else nz
;
;,fe
;=====================================================================
	assume	ds:grp,es:nothing,ss:nothing
if_scbnul proc near
	cmp	word ptr [scbdrvr],offset scbnul
	jne	ifs1
	push	ax
	mov	ax,cs
	cmp	word ptr [scbdrvr+2],ax
	pop	ax
ifs1:
	ret
if_scbnul endp 

	subttl calc_size - calculate a drivers return point
	page
;======================================================================
;,fs
; calc_size - calculate a drivers return point
;
; in:	none
;
; out:	dx = number of paras for driver
;
;,fe
;=====================================================================
	assume	ds:nothing,es:nothing,ss:nothing
calc_size proc near
	mov	dx,ss:[di+14]		; get end res offset
	add	dx,15			; calc seg
	mov	cl,4
	shr	dx,cl
	add	dx,ss:[di+16]		; add seg value
	ret
calc_size endp 

	subttl ddinit0 - initialize a driver
	page
;======================================================================
;,fs
; ddinit0 - initialize a driver
;
; in:	es:bx -> device driver
;	ss:di -> request block
;	ds -> grp
;
; out:	al = result code  0 if ok
;
;,fe
;=====================================================================
	assume	ds:grp,es:nothing,ss:tcb
ddinit0 proc near
	mov	al,[scbdrivs]		; get current drive #
	mov	ss:[di+22],al		; and set drive # for driver
	mov	byte ptr ss:[di+2],0	; init command
	mov	byte ptr ss:[di],22	; length of request block
	mov	byte ptr ss:[di+1],0	; unit number
	mov	word ptr ss:[di+3],0	; status
	push	di
	push	ds
	push	[tcbstkp]
	mov	[tcbstkp],sp
	sub	[tcbstkp],96+4		; 96 + following es & bx
	push	es
	push	bx
	push	cs			; emulate far call
	call	ddstrat
	pop	bx
	pop	es
	push	es
	push	bx
	push	cs			; emulate far call again
	call	ddinter
	pop	bx
	pop	es
	pop	[tcbstkp]
	pop	ds
	pop	di
	mov	al,0ffh
	test	word ptr es:[bx+4],8000h
	jnz	ddi0a
	push	bx
	push	es
	call	mosbdint		; block device (allocate and set bpb's)
	pop	es
	pop	bx
	mov	es:[bx+10],dl		; number of drives actually installed
	add	[scbdrivs],dl		; increasing total number of drives in system
	jmp	ddi0b
ddi0a:
	call	moscdint		; character device (look for standard devices)
	xor	al,al			; no errors possible in moscdint
ddi0b:
	ret
ddinit0 endp 

	subttl adj_smp_alloc - adjust smp allocation for driver
	page
;======================================================================
;,fs
; adj_smp_alloc - adjust smp allocation for driver
;
; in:	es:bx -> device driver
;	ss:di -> request block
;	ds -> grp
;
; out:	al = mosheman result code (0 no error)
;
;,fe
;=====================================================================
	assume	ds:grp,es:nothing,ss:nothing
adj_smp_alloc proc near
	xor	al,al			; prepare error code of 0
	mov	dx,es
	cmp	dx,0f000h		; check if in upper memory
	jae	ddint1
	mov	cl,4
	shr	bx,cl
	add	dx,bx
	cmp	[scbhp2siz],0
	je	doheap1
	mov	bx,[scbhp2adr]
	or	bx,bx
	jz	doheap1
	cmp	dx,bx			; must be >= scbhp2adr or we won't allocate
	jb	doheap1
	add	bx,[scbhp2siz]
	cmp	dx,bx
	jb	doheap2 		; must be < scbhp2adr + scbhp2siz
doheap1:
	mov	bx,[scbhpadr]
	cmp	dx,bx			; must be >= scbhpadr or we won't allocate
	jb	ddint1
	add	bx,[scbhpsiz]
	cmp	dx,bx
	jae	ddint1			; must be < scbhpadr + scbhpsiz

; shrink or expand driver's memory allocation

doheap2:
	mov	dx,word ptr ss:[di+14]	; as requested
	add	dx,15
	mov	cl,4			; new size is requested end address (rounded
	shr	dx,cl			; up to nearest segment) less start address
	add	dx,word ptr ss:[di+16]
	mov	ax,es
	dec	ax
	mov	es,ax
	sub	dx,ax
	mov	ah,02h			; setup for modify allocation
	cmp	dx,1			; shrinking down to just the header?
	jne	ddint2
	mov	ah,1			; if yes, de-allocate the block
ddint2:
	call	mosheman
ddint1:
	ret
adj_smp_alloc endp 

	subttl ddstrat - call device driver strategy routine
	page
;======================================================================
;,fs
; ddstrat - call device driver strategy routine
;
; returns to ddstrat caller
;
; in:	es:bx -> device driver header
;	ss:di -> device request block
;
; out:	
;
;,fe
;=====================================================================
	assume	ds:nothing,es:nothing,ss:nothing
ddstrat:
	push	es
	pop	ds
	push	es
	push	es:[bx+6]		; device driver strategy far address on stack
	push	ss			; es:bx -> request header
	pop	es
	mov	bx,di
	retf

	subttl ddintr - call device driver interrupt routine
	page
;======================================================================
;,fs
; ddintr - call device driver interrupt routine
;
; in:	es:bx -> device driver header
;	ss:di -> device request block
;
; out:	
;
;,fe
;=====================================================================
	assume	ds:nothing,es:nothing,ss:nothing
ddinter:
	push	es
	pop	ds
	push	es
	push	es:[bx+8]		; device driver interrupt far address on stack
	push	ss			; es:bx -> request header
	pop	es
	mov	bx,di
	retf

	subttl moscdint - look for standard devices
	page
;======================================================================
;,fs
; moscdint - look for standard devices
;
; determine if device driver represents a standard character device
;
; standard input if attribute field bit 0 set
; standard output if attribute field bit 1 set
; standard nul if attribute field bit 2 set
; standard clock if attribute field bit 3 set
; standard printer if device name is 'PRN     '
; standard aux if device name is 'AUX     '
;
; in:	ex:bx -> device driver header
;	ds -> grp
;
; out:	
;
;,fe
;=====================================================================
	assume	ds:grp,es:nothing,ss:nothing
moscdint:
	test	word ptr es:[bx+4],0001h
	jz	moscd1
	mov	word ptr [scbstdin],bx	; standard input device
	mov	word ptr [scbstdin+2],es
moscd1:
	test	word ptr es:[bx+4],0002h
	jz	moscd2
	mov	word ptr [scbstdout],bx ; standard output device
	mov	word ptr [scbstdout+2],es
moscd2:
	test	word ptr es:[bx+4],0004h
	jz	moscd3
	mov	word ptr [scbstdnul],bx ; standard nul device
	mov	word ptr [scbstdnul+2],es
moscd3:
	test	word ptr es:[bx+4],0008h
	jz	moscd4
	mov	word ptr [scbstdclk],bx ; standard clock device
	mov	word ptr [scbstdclk+2],es
moscd4:
	lea	di,[bx+10]
	lea	si,prnname
	mov	cx,8/2
	repe	cmpsw
	jne	moscd5
	mov	word ptr [scbstdprn],bx ; standard printer device
	mov	word ptr [scbstdprn+2],es
	ret
moscd5:
	lea	di,[bx+10]
	lea	si,auxname
	mov	cx,8/2
	repe	cmpsw
	jne	moscd6
	mov	word ptr [scbstdaux],bx ; standard auxilliary device
	mov	word ptr [scbstdaux+2],es
moscd6:
	ret

	subttl mosbdint - initialize block device
	page
;======================================================================
;,fs
; mosbdint - initialize block device
;
; based upon the returned bios parameter blocks (bpb's), allocate
; a block device block for each unit claimed by the block device driver
;
; in:	ss:di -> request block from call to init block device
;	es:bx -> device driver
;
; out:	al = 0 if no error
;	else al = 8 if sector size is invalid
;	else al = mosliman error + 8 if can't allocate some bdb
;
;,fe
;=====================================================================
	assume	ds:nothing,es:nothing,ss:nothing
mosbdint:
	xor	al,al
	xor	dl,dl			; this will be the unit number within device
	mov	cl,ss:[di+13]		; number of units defined by this device
	xor	ch,ch
	lds	si,ss:[di+18]		; bpb array pointer returned by driver
	mov	di,es
	assume	ds:nothing
	or	cx,cx
	jnz	mosbd1
	jmp	mosbd3			; no units (maybe the driver changed its mind)
mosbd1:
	push	ds			
	mgetscb ds
	assume	ds:grp
	mov	ax,[scbbufsz]		; max allowable sector size
	pop	ds
	assume	ds:nothing
	push	si
	mov	si,[si] 		; address next bpb
	cmp	ax,[si].bsBytesPerSec
	pop	si
	jae	mosbd1r
	xor	ax,ax			; if invalid size, just ignore the drive
	jmp	mosbd3
mosbd1r:
	mov	ah,00h			; allocate the bdb
	mov	al,'B'
	call	mosliman		; call mosliman
	add	al,8			; mosliman error offset for our purposes
	cmp	al,8
	je	mosbd1a 		; if enough space to allocate this bdb
	jmp	mosbd3
	assume	es:bdb
mosbd1a:
	mov	word ptr [bdbdrvr],bx	; offset of block device driver
	mov	word ptr [bdbdrvr+2],di ; segment of block device driver
	mov	[bdbunit],dl		; sub-unit within block device
	mov	al,dl
	push	ds
	mgetscb ds
	assume	ds:grp
	add	al,[scbdrivs]
	mov	[bdbid],al		; absolute drive number of this unit
	mov	ax,[scbbufsz]		; remember max allowable sector size
	pop	ds
	assume	ds:nothing
	push	es			; remember where bdb is
	push	si
	mov	si,[si] 		; -> next bpb
	push	dx
	xor	dx,dx			; say "initialize device"
	call	setbdb			; construct bdb
	pop	dx
	pop	si
	or	al,al
	jnz	mosbd2			; sector size invalid
	mov	ah,00h			; allocate a cdb for the bdb
	mov	al,'C'
	call	mosliman		; call mosliman
	add	al,8			; mosliman error offset for our purposes
	cmp	al,8
	jne	mosbd2			; not enough space for cdb
	assume	es:cdb
	push	ds
	mgetscb ds
	assume	ds:grp
	mov	al,[scbdrivs]
	pop	ds
	assume	ds:nothing
	add	al,dl
	mov	[cdbdrive],al		; drive number
	mov	[cdbclus],0		; at root directory
	mov	[cdbpath],0
	pop	es
	inc	dl			; next unit for block device driver
	add	si,2
	dec	cx
	jz	mosbd1b
	jmp	mosbd1
mosbd1b:
	xor	al,al
	jmp	mosbd3
mosbd2:
	pop	es			; address of bdb
	push	ax			; save error code
	mov	ah,1			; remove memory block
	mov	al,'B'			; remove BDB entry
	call	mosliman		; call mosliman
	pop	ax
mosbd3:
	mgetscb ds
	assume	ds:grp
	ret				; return dl = number of units installed

	subttl setbdb - construct a block device block from a bpb
	page
;======================================================================
;,fs
; setbdb - construct a block device block from a bpb
;
; using bpb at ds:si, construct bdb at es:0
; large volume support added 3/24/87
; alias support added 4/3/87
; 
; in:	di:bx = device driver address
;	ax = max sector size allowable
;	if dx = 0, set bdbroot and bdbalias to 0 too
;
; out:	al = 0 if no error
;	else al = 8, invalid sector size
;
;,fe
;=====================================================================
	assume	ds:nothing,es:nothing,ss:nothing
setbdb:
	assume	ds:nothing,es:bdb
	push	dx
	push	cx
	cmp	ax,[si].bsBytesPerSec
	mov	al,8
	jnb	setbd0			; max sector size < device sector size
	jmp	setbd7
setbd0:
	or	dx,dx			; initialize call?
	jnz	setbd0a 		; if not initialization time
	mov	[bdbroot],dx		; zero out root directory cluster
	mov	[bdbalias],dx		; alias pointer
	mov	[bdbanxt],dx		; it has no aliases
	mov	[bdbreal],es		; this is a real drive, is its own real bdb
setbd0a:
	mov	ax,[si].bsBytesPerSec
	mov	[bdbssiz],ax		; # of bytes in 1 sector
	mov	ax,[si].bsResSectors
	mov	[bdbfat],ax		; first sector of first fat
	mov	ax,[si].bsFATsecs	; # sectors per fat
	mov	[bdbfsiz],ax
	mov	al,[si].bsFATs		; # of fat's
	mov	[bdbfnum],al
	xor	ah,ah
	mul	[si].bsFATsecs
	add	ax,[si].bsResSectors
	mov	[bdbdir],ax		; first sector of root directory
	mov	ax,[si].bsRootDirEnts
	mov	[bdbrnum],ax		; number of root directory entries allowed
	mov	cx,32
	mul	cx			; dx:ax = size of directory in bytes
	mov	cx,[si].bsBytesPerSec
	dec	cx
	add	ax,cx
	adc	dx,0
	inc	cx
	div	cx			; ax = size of directory in sectors
	add	ax,[bdbdir]
	mov	[bdbclus],ax		; ax = first sector of cluster #2
	mov	al,[si].bsSecPerClust
	mov	[bdbcsiz],al		; cl = size of cluster in sectors (power of 2)
	dec	al
	mov	[bdbcmsk],al		; size - 1 (mask for size) for dpb field
	inc	al
	mov	cx,8
setbd2:
	shl	al,1
	loopnz	setbd2
	mov	[bdbcshl],cl		; shift count to convert clusters to sectors


;##<
;	mov	ax,[si+sctunit] 	; total size of block device unit in sectors
;	xor	dx,dx
;	mov	dl,[si+scthigh] 	; high byte of sector count
;	mov	word ptr [bdbsctr],ax
;	mov	byte ptr [bdbsctr+2],dl
;	mov	[bdbbig],'N'		; assume volume 65535 sectors or less
;	or	dx,dx
;	jz	setbd3
;	mov	[bdbbig],'Y'		; if volume bigger than 65535 sectors
;setbd3:

	mov	[bdbbig],'N'		; assume 65535 sectors or less
	xor	dx,dx
	mov	ax,[si].bsSectors 	; total sectors of block device unit
	or	ax,ax
	jnz	setbd3
	mov	[bdbbig],'Y'		; volume is larger than 65535 sectors
	mov	ax,word ptr [si].bsHugeSectors
	mov	dx,word ptr [si].bsHugeSectors+2
setbd3:
	mov	[bdbsctr],ax
	mov	[bdbsctr+2],dx
;##>


	sub	ax,[bdbclus]
	sbb	dx,0

; at this point, dx:ax holds the total number of sectors within the
; data area.  cl holds the cluster/sector shift count.
; derive the true total cluster count.

	push	bx
	push	si
	push	di
	mov	di,[si].bsFATsecs
	mov	si,[si].bsBytesPerSec
	call	get_true_clusters
	mov	ax,bx
	pop	di
	pop	si
	pop	bx

; bdbcnum should be the upper range of the cluster numbers (where 
; clusters range from 2 to bdbcnum).
; bdbcnmx is total clusters+1, to act as dpbMaxCluster.

	add	ax,2
	mov	[bdbcnum],ax		
	dec	ax
	mov	[bdbcnmx],ax		

	mov	al,[si].bsMedia
	mov	[bdbmdia],al		; media descriptor byte
	mov	[bdbcfree],-1		; # free clusters not valid yet
	mov	[bdbclustl],1		; pretend last allocated was cluster 1
					;   so first looked at is cluster 2
	call	setbdbc 		; set bdb parameters for cacheing
	xor	al,al			; no error
setbd7:
	pop	cx
	pop	dx
	ret

; set cache parameters for bdb

setbdbc:
	push	ds
	push	bx
	mov	word ptr [bdbclpf],-1	; no cached sectors yet
	mov	ax,[si].bsSecPerTrack
	mov	cx,ax
	mul	[si].bsHeads
	push	ds
	lds	bx,[bdbdrvr]
	assume	ds:nothing
	test	byte ptr [bx+4],40h
	pop	ds
	jz	setbc0a

; note the following to determine whether to use spt and spc logic in
; cacheing drive does not invalidate the drive, just the spt and spc logic

	or	dx,dx
	jnz	setbc0a
	cmp	ax,2048 		; 64 sectors per track * 32 heads
	ja	setbc0a
	mov	[bdbspc],ax		; sectors / cylinder
	or	ax,ax
	jz	setbc0a
	mov	[bdbspt],cx		; sectors / track
	cmp	cx,8
	jb	setbc0a
	mov	ax,word ptr [si].bsHiddenSecs
	mov	word ptr [bdbhddn],ax
	mov	dx,word ptr [si].bsHiddenSecs+2
	mov	word ptr [bdbhddn+2],dx


;##<
;	add	ax,word ptr [bdbsctr]
;	adc	dl,[bdbsctr+2]
;	adc	dh,0

	add	ax,[bdbsctr]
	adc	dx,[bdbsctr+2]
;##>


	mov	cx,ax
	mov	ax,dx
	xor	dx,dx
	div	[bdbspc]
	xchg	cx,ax
	div	[bdbspc]
	or	cx,cx
	jnz	setbc0a
	cmp	ax,1024
	jbe	setbdbc0		; no more than 1023 cylinders
setbc0a:

; disable spt and spc logic

	mov	[bdbspc],0
	mov	[bdbspt],0
	mov	word ptr [bdbhddn],0
	mov	word ptr [bdbhddn+2],0
setbdbc0:
	mgetscb ds
	assume	ds:grp
	mov	cl,[bdbid]		; drive number
	mov	bl,cl
	xor	bh,bh
	shr	bx,1
	shr	bx,1
	shr	bx,1			; bx = offset into drive enable bit map
	and	cl,7			; cl = bit position in byte
	mov	al,1
	shl	al,cl			; al = bit set in bit position
	mov	[bdbcach],'Y'		; preset cache on
	mov	cx,word ptr [scbcd]
	or	cx,word ptr [scbcd+2]
	jz	setbdbc1		; cache on for all if none specified
	test	scbcd[bx],al
	jnz	setbdbc1		; cache on if bit set
	mov	[bdbcach],0		; else cache off
setbdbc1:

; set cache off for bdb if device driver name is our ramdisk

	push	es
	push	ds
	push	di
	push	si
	lds	si,[bdbdrvr]
	assume	ds:nothing
	add	si,11			; note 11, not 10 cause our ram disk driver
	push	cs			;   has the name in a weird place
	pop	es
	assume	es:nothing
	lea	di,[ramname]
	mov	cx,8/2
	repe	cmpsw
	pop	si
	pop	di
	pop	ds
	assume	ds:grp
	pop	es
	assume	es:bdb
	jne	setbdbc2
	mov	[bdbcach],0
setbdbc2:

; set cache off for bdb if device driver is lansat (lanlink) - sjc 9/16/88

	push	ds
	push	si
	lds	si,[bdbdrvr]		; get driver seg:off
	assume	ds:nothing
	cmp	word ptr [si+12h],'AS'	; is this driver lansat?
	pop	si
	pop	ds
	assume	ds:grp
	jne	setbdbc3
	mov	[bdbcach],0		; if so, don't cache this drive
setbdbc3:

; compute how many of this bdb's sectors will fit in a cache uob

	mov	ax,[bdbssiz]
	mov	cl,4
	shr	ax,cl			; sector size in para's
	mov	cx,ax
	mov	ax,[scbcuob]
	xor	dx,dx
	div	cx
	mov	[bdbsuob],ax
	pop	bx
	pop	ds
	ret

mosseg	ends
	end

