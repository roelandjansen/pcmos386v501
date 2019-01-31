	include page.inc
	title	mostemp.asm - temp mos module
extrn bugerror:near
comment ^===============================================================
		development specification

 program name:	mos.com			assigned to: n/a
 module name:	mostemp			assign date: n/a
 entry points:	n/a			completed:   n/a
 entry from:	n/a
 entry method:	n/a
 calls:		n/a
 purpose:	provide mosfunxx labelx and whatever else might be
		needed to temp some mos module
 refer to:	n/a
 last update:	08/18/1992
========================================================================

mjs 11/25/86	inserted code at terminate label (supplied in 
		cterm from dam

sah 07/07/87	added limited function 5e and 5f to support ms 
		network not installed (ax=1) 7-15

sah 08/13/87	added undocoment function 55 which appears to do the 
		same thing as function 26 must be a more efficent way 
		or special cond.  under dos.  information about this 
		call was provide in pd doc about undocomented calls

sah 08/18/87	added undocment function 60 which from pd doc about
		undocmented call seams to return the current drive and
		directory in asciiz format into address specify by es:di

sah 08/25/87	enhanced function 5e and 5f to set extended error.  require
		for rm-cobol/85 corrected function in which pd doc was
		incorect after investigating function 60 seems to return
		last open file by task.

sah 09/12/87	enhanced function 55 from information supplied from
		computer associates. function 55 creates a psp (similar to
		function 26) but also allows the file to inherit the files
		from the parent whose inherit bit is on.  the new psp is
		also the active psp.

sah 11/06/87	slightly improved space and speed of function 52 while
		investigating problems with mcb and initialization of
		device drivers

sah 11/12/87	implement function 63 information from adv ms-dos pg 385
		and invest- igation.  found out that al is clear, dl is
		unless al is 1 and dl is 1 (which then dl is 1) this
		function is use by ms-c 5.00 and masm 5.0 linker.

sah 11/15/87	function 34 now points correct to our inmos flag (scbinmos)
		similar to tcbnest but global to all tasks

sah 01/20/88	change scbseg and zero seg access to use mgetxxxx macros.
		optimize int 00 and int 2e for smaller code since previous
		code is very similar.

sah 02/20/88	move ddt segment to mo2 group

sah 10/05/88	move function 34 into mosint28 so that all tsr related
		code is in one module.

rkg 10/06/88	public mosfunxx for assembly without .pubs

sah 10/13/88	added function 5d06h to point to critical flag scbcrit

sah 12/0/88	move mosint2f handler to this module since it is in
		this is better place for it. also enhance it for mos
		share off command which is necessary because of dbase
		iv's Installation program.

sah 07/07/89	added int 2e support which is back door to command
		processor, which novell's menu interface uses.

bwr 11/29/89	marked messages for foreign language translation

bwr 01/22/90	added support for dos 3.30 (network) functions 5e00
		and 5e01.  (5e01 is an undocumented call that places
		the network machine name and id into local space.
		novell calles 5e01 to furnish this id.
		the other functions on 5e and 5f are handled directly
		by the novell shell itself and need not be intercepted
		by the o/s.  presumably this is how the network
		drivers handle it anyway - dos (or mos in this case)
		doesn't know, or care, what network is installed.
		dos does have some mystery code down under 5e02, 5e03
		5f02, 5f03 and 5f04, but at this point exploring that
		code is unnecessary.  (it's probably specific to the
		microsoft network.)

sah 02/20/90	added int 29h support

sah 02/23/90	use maxdays from mosfun00 (duplicate data)

sah 02/26/90	corrections for novell's INT 2eh use in menus

sah 03/07/90	corrections for function 55h, so it inherits files
		also corrected unused dos functions, so that al is
		return as 00 (as in dos) instead of given a nasty
		error.

sah 06/22/90	corrections for msetpsp macro and lanlink

sah 01/23/91	added function 53h tranlate bdb for pc-geos support

sah 04/19/91	added support for int 2fh function 1680h

mjs 12/16/91	dlg mods: rewrote i21f53 for new bpb and dpb.  converted to
		use of structures within dskstruc.inc.  fixed problem with
		int2e due to sloppy use of assume statements.  the
		following two lines appear near the top of the int2e
		handler, but the "assume es:tcb" wasn't effective since an
		"assume ss:tcb" was still in effect from an above point and
		the assembler looks to ss before es.
		  mov    es,[scbtcbpc]
		  assume es:tcb

================ 5.01 Kernel Ends Here ====================================

SAH 07/22/92    Found that we need to save bx during INT 29h handler
		when working with one of my test programs.

mjs 08/18/92	clean up segment declarations

=======================================================================^

.xlist
;	include mostemp.pub
	include group.inc
	include mosregs.inc
	include dskstruc.inc
	include moscdb.inc
	include mosgfb.inc
	include mostfb.inc
	include mosrlb.inc
	include mosbdb.inc
	include mospsp.inc
	include macros.inc

tcb	segment at 1234h
	include mostcb.inc
tcb	ends

gdata	segment
	include mosscbex.inc
gdata	ends
.list

irq	segment
	extrn	irqstart:byte, irqend:byte

	dw	00h*4			; offset for this interrupt
	dd	?			; save prior value
	dw	0			; we don't save changes, we leave them alone
	dw	mos:mosint00		; initial value is here
	dw	0			; don't change back if application changes it

	dw	2eh*4			; offset for this interrupt
	dd	?			; save prior value
	dw	0			; we don't save changes, we leave them alone
	dw	mos:mosint2e		; initial value is here
	dw	0			; don't change back if application changes it

	dw	24h*4
	dd	?
	dw	0
	dw	mos:mostmp24
	dw	0

	dw	29h*4			; offset for this interrupt
	dd	?			; save prior value
	dw	0			; we don't save changes, we leave them alone
	dw	mosint29		; offset of handler
	dw	0			; don't change back if application changes it

	dw	2fh*4			; offset for this interrupt
	dd	?			; save prior value
	dw	0			; we don't save changes, we leave them alone
	dw	mosint2f		; offset of handler
	dw	0			; don't change back if application changes it
irq	ends

;======================================================== ddt segment
if 0 eq 0
segment_num = 2
endif
ddt	segment
	extrn	findtfb:near
ddt	ends

;======================================================== mos segment
if 0 eq 0
segment_num = 1
endif
mosseg	segment
	assume	cs:mos,ds:nothing,es:nothing,ss:nothing

	extrn	mosend:byte, sbios:word, maxdays:byte
	extrn	moserror:near, fun00a:near,mossaver:near, mosrestore:near
	extrn	todriver:near, mosfun26:near

int0msg db	13,10,'Divide by zero error      ',13,10,13,10,'$'  ;@@xlat

	subttl mosint00 - divide by zero exception handler
	page
;======================================================================
;,fs
; mosint00 - divide by zero exception handler
;
; note: mosint00 simply flows into to terminate instead of jumping to it.
;
; in:	
;
; out:	
;
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:nothing
mosint00:
	mov	dx,offset [int0msg]
	assume	ds:nothing,es:nothing,ss:nothing
	mgetscb ds
	assume	ds:grp
	mov	ss,[scbtcbpc]		; gain addressability to mos data
	assume	ss:tcb
	lea	sp,[tcbstack]
	mov	ax,cs
	mov	ds,ax			; access constant data in mos
	assume	ds:mos
	mov	ah,9
	int	21h

	subttl terminate - mos's general terminate entry point
	page
;======================================================================
;,fs
; terminate - mos's general terminate entry point
;
; note: mosint00 simply flows into to terminate instead of jumping to it.
;
; in:	
;
; out:	
;
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:nothing
public	terminate
terminate:
	mgetscb ds
	assume	ds:grp
	cli
	mov	ss,[scbtcbpc]
	mov	sp,offset tcbstack
	sti
	assume	ss:tcb
	mov	es,[tcbpsp]		; used in normal termination procedures
	mov	[tcbretc],ax
	mov	ax,offset tcbstack	; reset stack
	mov	[tcbstkp],ax
	jmp	fun00a

	subttl mostmp23, mostmp24 - initial null handlers
	page
;======================================================================
;,fs
; mostmp23, mostmp24 - initial null handlers
;
; temporary int 23h and int 24 handler until command processor is
; loaded and initialized.
;
; in:	
;
; out:	
;
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:nothing
mostmp24:
	mov	al,3
mostmp23:
	iret

	subttl mosint2e - back door to command processor.
	page
;======================================================================
;,fs
; mosint2e - back door to command processor.
;
; we are going to sorta cheat on this but basically we will
; exec our command.com.  this should make the int 2e function
; correctly and my understanding of why dos has this is for
; a quick and dirty way or getting to command processor with out
; reloading it.  since our command processor is only 20 bytes and
; all of the main code is resident anyway.  this technique should work
;
; in:	ds:si -> #,'string',0dh  which is passed to command processor
;
; out:	
;
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:nothing
mosint2e:
	push	ax
	push	bx
	push	cx
	push	dx
	push	di
	push	ds
	push	es

; the following is use to set up parameters to be passed to function
; 4bh (exec)

	mov	dx,ds			; save current ds
	mgetscb ds
	assume	ds:grp
	mov	es,[scbtcbpc]
	assume	es:tcb
	mov	di,offset [tcbparm2e]
	cld
	xor	ax,ax			; store 00h into offset 00 of parm block
	stosw				; this means copy enviroment
	mov	ax,offset [tcbtext2e]
	stosw				; use si for offset of command to pass
	mov	ax,es			; use ds (save in dx above) for segment
	stosw
	mov	ax,5ch			; we are going to use current psp for
	stosw				; fcbs
	mov	ax,[tcbpsp]
	stosw
	mov	ax,6ch			; we are going to use current psp for
	stosw				; fcbs
	mov	ax,[tcbpsp]
	stosw

; now we must append /c in front of the command pass in ds:si

	mov	di,offset [tcbtext2e]
	push	ds
	mov	ds,dx
	lodsb
	mov	cl,al			; save count
	add	al,3
	stosb
	mov	al,'/'
	stosb
	mov	ax,' C'
	stosw
	xor	ch,ch
	rep	movsb
	pop	ds

; now is the time to do actual exec

	mov	dx,offset [scbshell]	; point ds:dx -> scbshell
	mov	bx,offset [tcbparm2e]	; point es:bx -> tcbparm2e
	mov	ax,4b00h
	int	21h
	pop	es
	pop	ds
	pop	di
	pop	dx
	pop	cx
	pop	bx
	pop	ax
	iret

	subttl mosint2f - multiplex interupt 
	page
;======================================================================
;,fs
; mosint2f - multiplex interupt 
;
; currently support function 10 which checks to see if share 
; is installed. if mos share off is use then int 2f function 10 
; will return that share is not install
;
; sah 04/19/91 added support for int 2fh function 1680h, windows &
; dpmi apps will use this to release current virtual machines time
; slice.  implemented so that these apps will be more efficent under
; mos
;
; in:	
;
; out:	
;
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:nothing
mosint2f proc	far
	cmp	ax,1000h		; only respond to the id for share
	jne	i2f2
	pushf				; save flags
	push	ds
	mgetscb ds
	assume	ds:grp
	mov	ds,[scbtcbpc]		; get current tcb
	assume	ds:tcb
	cmp	[tcbshare],'N'		; share installed or not (mos share)
	jne	i2f1
	pop	ds
	popf				; get old flags
	ret	2			; return back with current flags
i2f1:
	pop	ds
	popf
	mov	al,0ffh			; indicate share is installed
i2f2:
	cmp	ax,1680h
	jne	i2f3
	push	ds
	mgetscb ds
	assume	ds:grp
	mov	ds,[scbtcbpc]		; get current tcb
	assume	ds:tcb
	mov	byte ptr [tcbslcnt],0	; force tsl to switch
	pop	ds
	call	mossaver		; this will force tsl to be call
	call	mosrestore
	xor	al,al			; os does support this call
i2f3:
	iret
mosint2f endp

	subttl mosint29 - video support
	page
;======================================================================
;,fs
; mosint29 - video support
;
; in:	al = character to display
;
; out:	
;
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:nothing
mosint29 proc	near
	 push	ax
	 push	si
	 push	di
	 push	bp
	 push	bx
	 mov	bx,7
	 mov	ah,0eh
	 int	10h
	 pop	bx
	 pop	bp
	 pop	di
	 pop	si
	 pop	ax
	 iret
mosint29 endp

;======================================================================
; return invalid function for all the others
;======================================================================
pubfn	macro	fn
	public	mosfun&fn
mosfun&fn:
	endm

	irp	fn,<18,1d,1e>
	pubfn	fn
	endm
	irp	fn,<20>
	pubfn	fn
	endm
	irp	fn,<61>
	pubfn	fn
	endm

; print message that unsupported function used

unkfun	label	near
	mov	[tal],0			; do as dos and return 00 in al
	ret				; don't lock entired system

	subttl mosfun52 - get dos variable table
	page
;======================================================================
;,fs
; mosfun52 - get dos variable table
;
; in:	
;
; out:	tes:tbx-2 -> tcbmbpf
;
;,fe
;======================================================================
	assume	ds:grp,ss:tcb,es:nothing
	public	mosfun52
mosfun52 proc	near
	mov	bx,ss
	mov	es,bx			; es -> tcb
	lea	bx,[tcbmbpf+2]		; pointer to 1st memory block prefix
	xor	ax,ax			; tell them it worked
	mov	[tes],es
	mov	[tbx],bx
	mov	[tax],ax
	ret
mosfun52 endp

	subttl get_true_clusters - derive total clusters
	page
;======================================================================
;,fs
; get_true_clusters - derive total clusters
;
; verify that the fat can hold all the clusters possible based on
; total data sectors.
;
; in:	dx:ax = total sectors in data area
; 	cl = sector/cluster shift factor
;	si = bytes per sector
;	di = sectors per fat
;
; out:	bx = true number of data clusters
;	crashes ax, cx, dx, si, di
;
;,fe
;======================================================================
	assume	ds:grp,es:nothing,ss:tcb
public get_true_clusters
get_true_clusters proc near

; use the cluster shift factor to derive a raw cluster count.

	xor	ch,ch
	jcxz	fun53c
fun53b:
	clc
	rcr	dx,1
	rcr	ax,1
	loop	fun53b
fun53c:
	mov	bx,ax

; now must see how many clusters can actually be managed given the size
; of the fat.  calc total bytes in a fat and then /2 for a 16 bit or
; /1.5 for a 12 bit.  then, subtract 2 since the first two fat entries
; aren't used for real clusters.

	mov	ax,di
	mul	si
	cmp	bx,(4096-10)
	jbe	fun53d

; 16 bits per fat entry

	shr	dx,1
	rcr	ax,1
	jmp	short fun53e

; 12 bits per fat entry

fun53d:
	add	ax,ax
	adc	dx,dx
	mov	cx,3
	div	cx
fun53e:
	sub	ax,2

; ax now holds the maximum number of fat entries which can be supported
; given the number of fat sectors.  bx now holds the total number of 
; clusters possible, based on the total number of data sectors.  
; the lessor of these two is used for dpbMaxCluster.
; note that the dpbMaxCluster field is defined as total clusters + 1.

	cmp	ax,bx
	jnb	fun53f
	mov	bx,ax
fun53f:
	ret
get_true_clusters endp

	subttl mosfun53 - translate bios parameter block
	page
;======================================================================
;,fs
; mosfun53 - translate bios parameter block
;
; compute the information in a drive parameter block from the
; information in the bios parameter block
;
; in:	tds:tsi -> pointer to bios parameter block
;	tes:tbp -> pointer to buffer  for dos driver parameter block
;
; out:	tes:tbp -> buffer is filled with a dpb
;
;,fe
;======================================================================
	assume	ds:grp,es:nothing,ss:tcb
	public	mosfun53
mosfun53 proc	near
	push	ds
	push	es
	push	si
	push	di
	mov	es,[tes]
	assume	es:nothing
	mov	ds,[tds]
	assume	ds:nothing
	mov	si,[tsi]
	mov	di,[tbp]

; transfer these fields straight from the bpb to the dpb.

	mov	ax,[si].bsBytesPerSec
	mov	es:[di].dpbSectorSize,ax
	mov	ax,[si].bsResSectors
	mov	es:[di].dpbFirstFat,ax
	mov	al,[si].bsFATs
	mov	es:[di].dpbFATCount,al
	mov	al,[si].bsMedia
	mov	es:[di].dpbMedia,al

; force these fields

	mov	es:[di].dpbNextFree,0
	mov	es:[di].dpbFreeCnt,0ffffh

; use sectors per cluster to derive the cluster mask 
; and sector to cluster shift count.

	mov	al,[si].bsSecPerClust
	dec	al
	mov	es:[di].dpbClusterMask,al
	inc	al
	xor	ah,ah
sloop53:
	test	al,1
	jnz	sexit53
	shr	al,1
	inc	ah
	jmp	short sloop53
sexit53:
	mov	es:[di].dpbClusterShift,ah

; now, xfer the # of root directory entries and calc number of sectors
; required for root directory -- rounding up to the next whole sector.

	mov	ax,[si].bsRootDirEnts
	mov	es:[di].dpbRootEntries,ax
	mov	cl,5
	mov	dx,word ptr es:[di].dpbSectorSize
	shr	dx,cl
	dec	ax
	add	ax,dx
	mov	cx,dx
	xor	dx,dx
	div	cx
	mov	cx,ax

; cx now holds the number of sectors required for the root directory.
; derive # of sectors for the FATs and the first sector of the root
; directory.

	mov	ax,[si].bsFATsecs
	mov	es:[di].dpbFATSize,ax
	mov	bl,es:[di].dpbFATCount
	xor	bh,bh
	mul	bx
	add	ax,es:[di].dpbFirstFAT
	mov	es:[di].dpbDirSector,ax

; once the first sector of the root directory is known, add in the 
; # of directory sectors to get the first data sector.

	add	ax,cx
	mov	es:[di].dpbFirstSector,ax
	mov	bx,ax			; save for below

; derive the total number of sectors in dx:ax and then subtract
; the sector number of the first data sector to derive the total
; sectors in the data area.

	xor	dx,dx
	mov	ax,[si].bsSectors
	or	ax,ax
	jnz	fun53a
	mov	ax,word ptr [si].bsHugeSectors
	mov	dx,word ptr [si].bsHugeSectors+2
fun53a:
	sub	ax,bx
	sbb	dx,0

; derive total data clusters

	mov	cl,es:[di].dpbClusterShift
	push	di
	mov	di,[si].bsFATsecs
	mov	si,[si].bsBytesPerSec
	call	get_true_clusters
	pop	di
	inc	bx
	mov	es:[di].dpbMaxCluster,bx
	pop	di
	pop	si
	pop	es
	pop	ds
	ret
mosfun53 endp

	subttl mosfun55 - undocomented create new psp call
	page
;======================================================================
;,fs
; mosfun55 - undocomented create new psp call
;
; in:	si = segment for end of allocation
;	dx = segment for psp to create
;
; out:	new psp created
;
;,fe
;======================================================================
	assume	ds:grp,ss:tcb,es:nothing
	public	mosfun55
mosfun55 label	near

; call function 26 to initialize psp

	 call	mosfun26

; set this psp as active psp

	 mov	bx,[tcbpsp]		; get parent psp
	 mov	ax,[tdx]		; set active psp to this psp
	 msetpsp ax
	 mov	es,ax			; point to psp
	 assume es:pspseg
	 mov	ax,[tsi]		; get end segment
	 mov	es:[pspmem],ax
	 mov	es:[pspprnt],bx		; save parent psp
	 assume es:nothing
	 mov	byte ptr [tal],0

; now for the fun part, if handles are mark inherit, set handle to ffh.

	 push	es
	 push	ds
	 mov	ax,es
	 mov	ds,ax
	 mov	cx,15
	 mov	si,offset [psphtbl]
	 mov	bx,5
handloop:
	 callmos2 findtfb
	 jc	handzap
	 assume es:tfb
	 test	[tfbalow],08h		; is it inherited
	 jz	handnext
handzap:
	 mov	byte ptr ds:[si+bx],0ffh
handnext:
	 inc	bx
	 loop	handloop
	 pop	ds
	 pop	es
	 and	[tflag],not carry
	 ret

	subttl mosfun5d - error setup functions
	page
;======================================================================
;,fs
; mosfun5d - error setup functions
;
; this is provided for compatibility with some tsrs to reset the
; extended error information for an application that they may have
; interrupted.
;
; in:	tal = function code
;	    = 06h - return critical flag
;	    = 0ah - reset extended error
;	tds:tdx -> 3	words of data (error, class, locus)
;
; out:	
;
;,fe
;======================================================================
	assume	ds:grp,ss:tcb,es:nothing
	public	mosfun5d
mosfun5d proc	near
	mov	al,[tal]
	cmp	al,06h			; is this for critical flag
	jne	mf5dn6
	mov	[tds],ds		; make sure you return ds --> grp
	mov	[tsi], offset scbcrit
	ret
mf5dn6:
	cmp	al,0ah			; is this set extended error?
	jne	mf5dx			; no, could be anything
	mov	es,[tds]		; get pointer to error info
	mov	bx,[tdx]
	mov	al,es:[bx]		; get error number only (don't care about rest)
	mov	[tcberrcod],al		; set it
mf5dx:
	ret
mosfun5d endp

	 subttl mosfun5e - printer setup & mosfun5f get assign list entry
	 page
;======================================================================
;,fs
; mosfun5e - printer setup & mosfun5f get assign list entry
;
; function 5e00 - get machine name
; ================================
;
; in:	ax = 5e00h
;	ds:dx = pointer to buffer to receive string.
;
; out:	ch = validity. (1 = valid network station)
;	cl = local station id.
;	machine name placed at location supplied on input.
;
; function 5e01 - set machine name
; ================================
;
; this function is undocumented by dos, but found to be used by
; novell login.exe in assigning the machine name and network id.
;
; in:	ax = 5e01h
;	cx = station id assigned.
;	ds:dx = pointer to buffer with machine name string in it.
;
; out:	
;
;,fe
;======================================================================
	assume	ds:nothing, es:nothing, ss:tcb
public	mosfun5e
mosfun5e	proc	near
	mov	ax,[tax]
	cmp	al,1
	jb	m5e_0
	je	m5e_1

; bad function.

	mov	ax,1
	callmos2  moserror
	ret
m5e_0:
	mov	ax,ss			; build ds:si at machine name.
	mov	ds,ax
	mov	si,offset tcb_machine_name
	mov	es,[tds]		; es:di => buffer @ ds:dx
	mov	di,[tdx]
	mov	cx,15			; move 15 bytes.

; if the machine name was never initialized in our tcb, stuff
; the name with blanks.

	cmp	byte ptr [si],0		; zero in machine name?
	jne	m5e_0_copy		; if not, copy it to dest.
	mov	al,' '			; if so, return string of blanks.
	rep	stosb
	jmp	short m5e_0_terminate
m5e_0_copy:
	rep	movsb
m5e_0_terminate:
	mov	byte ptr es:[di],0	; zero terminate the string.
	mov	cx,[tcb_machine_id]
	mov	[tcx],cx		; return machine id.
	ret
m5e_1:
	mov	ds,[tds]		; build ds:si at buffer.
	mov	si,[tdx]
	mov	ax,ss			; build es:di in the tcb.
	mov	es,ax
	mov	di,offset tcb_machine_name
	mov	cx,15			; move 15 bytes.
	rep	movsb
	mov	cx,[tcx]		; get machine id.
	mov	[tcb_machine_id],cx
	ret
mosfun5e	endp

	subttl mosfun5f - network support
	page
;======================================================================
;,fs
; mosfun5f - network support
;
; indicate ms network not installed.
;
; in:	
;
; out:	
;
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:tcb
public mosfun5f
mosfun5f	proc	near
	mov	[tax],1
	or	[tflag],carry
	mov	byte ptr [tcberrcod],1
	ret
mosfun5f	endp

	 subttl mosfun60 - get last open file name (undocumented)
	 page
;======================================================================
;,fs
; mosfun60 - get last open file name (undocumented)
;
; the following is currently knowned implementation of
; undocmomented function 60 which from information from pd doc
; about undocumented call returns the current drive and
; and directory into address specify by es:di.  rm-cobol 85 uses
; this function.
; after investigation function 60 seems to return the last open
; file by system, here is what i observed:
;
; task open file with function 3d and later (the task)
; converted the filename at ds:dx of open function to full path
; when function 60 is called, it seems to return the same info
; stored at ds:dx of the prevous open file.  possiablity trans-
; lated under pc-networks but i am not sure about it.
;
; in:	
;
; out:	
;
;,fe
;======================================================================
	assume ds:grp,es:nothing,ss:tcb
	public mosfun60
mosfun60 proc	near
	mov	di,[tdi]
	mov	ax,[tes]
	mov	es,ax
	lds	si,[tcbopen60]
mf60loop:
	lodsb				; get character
	or	al,al
	jz	mf60done
	stosb				; store it in user space
	jmp	short mf60loop
mf60done:
	stosb				; store trailing zero
	mov	[tax],004ch		; seems to be right (who knows)
	ret
mosfun60 endp

	subttl mosfun63 - get dos interim flag
	page
;======================================================================
;,fs
; mosfun63 - get dos interim flag
;
; adv ms-dos page 384 for more information
; use by ms-c 5.00 and masm 5.00 linker
;
; in:	
;
; out:	
;
;,fe
;======================================================================
	assume	ds:grp,es:nothing,ss:tcb
	public	mosfun63
mosfun63 proc	near
	 mov	al,[tdl]
	 mov	byte ptr [tdl],00h
	 cmp	byte ptr [tal],01h
	 jne	mf63skip
	 mov	[tdl],al
mf63skip:
	 mov	byte ptr [tal],00h
	 ret
mosfun63 endp

	subttl caps - convert character to uppercase
	page
;======================================================================
;,fs
; caps - convert character to uppercase
;
; in:	al = character to convert
;
; out:	al = converted character
;
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:nothing

capstbl db	80h,9ah,90h,83h,8eh,85h,8fh,80h,88h,89h,8ah,8bh,8ch,8dh,8eh,8fh
	db	90h,92h,92h,93h,99h,95h,96h,97h,98h,99h,9ah,9bh,9ch,9dh,9eh,9fh
	db	0a0h,0a1h,0a2h,0a3h,0a4h

public	caps
caps:	cmp	al,'a'
	jb	caps1
	cmp	al,'z'
	jbe	caps2
	cmp	al,80h
	jb	caps1
	cmp	al,0e5h
	je	caps3
	cmp	al,165
	jae	caps1
	push	bx
	lea	bx,capstbl-80h
	xlat	capstbl
	pop	bx
caps1:
	ret
caps2:
	sub	al,'a'-'A'
	ret
caps3:
	mov	al,05h
	ret

	subttl getdate - read the clock driver
	page
;======================================================================
;,fs
; getdate - read the clock driver
;
; in:	
;
; out:	
;
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:nothing
public	getdate
lproc	getdate
lstring reqhead,26
lstring datebuffer,6
lbyte	wkday
lword	year
lbyte	month
	assume	ds:nothing
	push	bx
	push	si
	push	di
	push	es
	mov	byte ptr [reqhead],26	; set rh length
	mov	byte ptr [reqhead+2],4	; input read from mosddclk
	lea	bx,[datebuffer]
	mov	word ptr [reqhead+14],bx  ; set transfer address
	mov	ax,ss
	mov	word ptr [reqhead+16],ax
	push	ds
	mgetscb ds
	assume	ds:grp
	lds	si,[scbstdclk]
	assume	ds:nothing
	mov	bx,ss
	mov	es,bx
	lea	bx,[reqhead]
	mov	ah,80h
	xor	cx,cx
	callmos2 todriver		; call the clock driver
	mov	cx,word ptr [datebuffer]
	pop	ds
	mov	ax,cx			; day count now in cx
	xor	dx,dx
	mov	bx,7
	div	bx
	mov	ax,dx
	sub	ax,5
	mov	[wkday],al
	cmp	dx,4
	ja	dc1
	add	dx,2
	mov	[wkday],dl
dc1:
	mov	ax,cx
	xor	dx,dx
	mov	bx,1461			; number of days in a four year period
	div	bx
	or	ax,ax
	jz	dc2
	shl	ax,1
	shl	ax,1			; ax * 4
dc2:
	mov	[year],ax
	xor	di,di
	cmp	dx,366
	jae	dc7
	mov	di,1			; set di=1 for leap year
	jmp	dc3
dc7:
	inc	[year]
	sub	dx,366
	mov	ax,dx
	xor	dx,dx
	mov	bx,365
	div	bx
	add	[year],ax
dc3:					; dx now holds number of days into the year
	add	word ptr [year],1980
	mov	byte ptr [month],1
dc4:
	mov	al,[month]
	xor	ah,ah
	mov	si,ax
	dec	si
	mov	bx,offset [maxdays]
	mov	bl,mos:[bx+si]		; get max number of days for month
	xor	bh,bh
	cmp	al,2			; is it february?
	jne	dc5
	add	bx,di			; if feb, add the leap year factor (0 or 1)
dc5:
	cmp	dx,bx
	jnae	dc6
	sub	dx,bx
	inc	byte ptr [month]
	cmp	byte ptr [month],12
	jne	dc4
dc6:
	inc	dl
	mov	al,[wkday]
	mov	cx,[year]
	mov	dh,[month]
	pop	es
	pop	di
	pop	si
	pop	bx
lundef	reqhead,26
lundef	datebuffer,6
lundef	wkday
lundef	year
lundef	month
lendp	getdate

	subttl gettime - read the clock driver
	page
;======================================================================
;,fs
; gettime - read the clock driver
;
; in:	
;
; out:	
;
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:nothing
public	gettime
lproc	gettime
lstring reqhead,26
lstring datebuffer,6
	assume	ds:nothing
	push	ax
	push	bx
	push	si
	push	di
	push	es
	mov	byte ptr [reqhead],26	; set rh length
	mov	byte ptr [reqhead+2],4	; input read from mosddclk
	lea	bx,[datebuffer]
	mov	word ptr [reqhead+14],bx  ; set transfer address
	mov	ax,ss
	mov	word ptr [reqhead+16],ax
	push	ds
	mgetscb ds
	assume	ds:grp
	lds	si,[scbstdclk]
	assume	ds:nothing
	push	ss
	pop	es
	lea	bx,[reqhead]
	mov	ah,80h
	xor	cx,cx
	callmos2 todriver		; call the clock driver
	pop	ds
	mov	cl,byte ptr [datebuffer+2]  ; minutes
	mov	ch,byte ptr [datebuffer+3]  ; hour
	mov	dl,byte ptr [datebuffer+4]  ; hundreth secs
	mov	dh,byte ptr [datebuffer+5]  ; seconds
	pop	es
	pop	di
	pop	si
	pop	bx
	pop	ax
lundef	reqhead,26
lundef	datebuffer,6
lendp	gettime

mosseg	ends
	end

