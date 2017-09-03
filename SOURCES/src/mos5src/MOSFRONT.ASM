	include page.inc
	title	mosfront.asm - the first mos module to link
public	bugerror
bugreport equ	bugerror
comment ^===============================================================
		    development specification

 program name:	mos			assigned to: jrb, dam
 module name:	mosfront		assign date: 01/01/86
 entry points:	n/a			completed:   02/06/86
 entry from:	n/a
 entry method:	n/a
 calls:		n/a
 purpose:	establish start pointers in each of the mos segments,
		as well as specifying the last entries of the irq and
		poll segment tables
		establish the segment ordering by using the masm /s
		option when assembling this module (only) to force
		ordering as it is in this module
 refer to:	n/a
 last update:	08/18/1992
========================================================================

added a very simple error reporter for critical internal errors
it is currently used as follows:

call	bugerror
db	'99 '		; this is the internal error number
db	'This is some variety of message',00h

the string following the call is displayed, preceded by 'Internal
error #' (e.g. 'internal error #99 this is some variety of message')
and then an enabled loop is entered to hang up the system

error numbers are:
01 - stack overflow during allocation of local variables for a
     recursive procedure - the message consists of the procedure name
02 - heap structure corruption, someone or something trashed a block
     headers information.

detection of the 01 error is enabled for a source file which makes
use of the macros in mosregs.inc (also updated) if the statement

extrn bugerror:near

appears in the source file prior to the include mosregs.inc statement
I put it immediately following the title statement

mostcb.inc changed slightly by the addition of tcbminstk which is a
label in front of the stack area so overflow can be detected

=======================================================================

jrb 02/24/86	took the mos segment out of the grp group of segments
		added mos group of mosseg code segments
		added scbseg and scbfree in mosseg segment

jrb 03/06/86	added bootseg word in mosseg segment

		this is the segment address of 29 bytes formatted
		as follows:
		0-2	reserved
		3-6	'TSL '  verification id
		11-27 	bios parameter block of boot default disk
		28	boot default disk id for bios int 13h

		if we are romed,
		 this is a segment in rom with this information
		if we were loaded off a disk,
		 this is the segment address of the boot loader,
		  whose first 29 bytes are formatted as above
		the standard block device driver should look
		at the verification id and, if valid, should
		copy the bpb into its own space so it can
		return a bpb pointer to mos

dam 01/02/87	added ddt segment to grp group for the ddts to be put
		into the grp.  this will give us more code room in mos.

dam 01/15/87	added 'mainseg' to mos group.  this is the memman seg

jrb 05/17/87	added code fragment to trick sidekick

sah 07/14/87	added getkeys call to bugerror dead loop to ctl-alt-del

sah 09/18/87	added patch areas for both mosseg and mainseg. current
		size is 512 bytes each and the following is what to
		search for:
		mosseg   -   "PATCH-MOS"   follow by 512 byte patch area
		mainseg  -   "PATCH-MAIN"  follow by 512 byte patch area

sah 01/18/88 	added initialization of 40:3fa and 40:03fc, conversion
		of scbseg and zero access to mgetxxxx access.  remove
		mainseg	patch area which is not needed.

sah 01/22/88	change scbseg to mo2seg for mos 2nd segment

sah 02/12/88	made changes necessary for mos's new inter-segment calls

sah/rbr 02/21/88 move ddt segment to mo2 group
		remove mainseg which is not used
		made patch size 128 bytes for mos and mo2

rbr 03/12/88	created grpseg1 and grpseg2 to get addressability to
		grp in only one segment load, via the mgetscb and
		mgetscb2 macros.  this means that mosinit must write
		to code segments, but the performance improvement and
		space savings are significant.

sah 07/23/88	change mos segment so start of real mos code is at
		origin of 1080h. made module compatible with optasm

sah 07/29/88	added special call to scbdump is available. this can be
		useful for easly information debugging if buggerror
		passed with ah=1 to indicated that it happen here

sah 08/01/88	added init segment for init code which will be
		discarded.

bwr 11/28/89	marked messages for foreign language translation.

bwr 01/15/90	scb aligned on 16-byte boundary.  this is done to
		support the new get_scb_address call that returns
		a selector to the scb.  (before going to protected
		mode, a segment address is returned).

sah 03/29/91	added 128 bytes to mos segment's patch area.

mjs 12/16/91	dlg mods: added an "include dskstruc.inc" because mboot.inc
		needs the structure definitions in that file.  

================ 5.01 Kernel Ends Here ====================================

mjs 08/18/92	clean up segment declarations

======================================================================^

.xlist
;	include	mosfront.pub
	include	mosregs.inc
	include	dskstruc.inc
is_mosfront = 1
	include	group.inc
	include macros.inc
.list

gdata	segment
	assume	cs:grp,ds:nothing,es:nothing,ss:nothing
gstart	label	byte
	org	0100h

patchsize equ 512

	public	fgscboff

	extrn	gend:byte

; from start to fgscboff is defined for purposes of non-rom'ed mos code
; the assumption is that the boot code loads mos into memory at some
; segment address and transfers to the start of the load image
; note: code below allows for starting at .com file offset 0100h (so we
; can test it more easily) or at boot loader offset of 0000h (so we can
; boot it)
; if the code segment (mos) is rom'ed, then the assumption is that
; execution somehow gets to the start of the mos segment (at mosstart)

start	proc	far

; xfr to remainder of bootstrap (must be @ offset 3 into mos file image)

	jmp	grpx
	call	mosboot			
grpx:					
	call	grpofs
grpofs:
	pop	ax
	sub	ax,offset grp:grpofs
	mov	cl,4
	sar	ax,cl
	mov	bx,cs
	add	bx,ax			; bx = true address of grp segment
	mov	ax,offset grp:gend+255	; defined in mosback.asm
	xor	al,al
	mov	cl,4
	shr	ax,cl
	add	ax,bx
	mov	es,ax			; init grp address in mo2
	assume	es:mo2
	mov	es:[grpseg2],bx
	push	ax			; save mo2 seg address
	mov	dx,offset mo2:mo2end+255 ; account for mo2 length
	xor	dl,dl
	shr	dx,cl
	add	ax,dx
	mov	es,ax			; es = true address of mos segment
	assume	es:mos
	pop	es:[mo2seg]		; init mo2 seg address in mo1
	mov	es:[grpseg1],bx		; init grp address in mo1
        push	ax			; crashes cx and dx which are assume to be
        push	ds			; unimportant at this time of initialization
        mov	dx,00040h		; note this is a constant value
        mov	cx,ds			; save current ds
        mov	ds,dx			; make ds point to bios
        mov	ds:[03fah],bx
        xor	ax,ax			; initialize value at 0040:03fc to 0000
        mov	ds:[03fch],ax
        mov	ds,bx			; access scb in ds
        assume  cs:nothing,ds:grp
        mov	[scbboot],cx		; save boot segment into scb
        pop	ds
        assume  cs:grp,ds:nothing
        pop	ax
	mov	es:[bootseg],ds		; save segment location of boot sector
	mov	bx,es			; bx = mos segment address
	mov	ax,offset mos:mosend+15
	mov	cl,4
	shr	ax,cl
	add	ax,bx
	mov	es:[sinit],ax		; store start location of initseg
	mov	bx,offset init:initend+15
	shr	bx,cl
	add	ax,bx			; adjust for the lenght of init
	or	al,3
	mov	es:[scbfree],ax		; first free memory segment location for heap
	push	es			; far jmp to mosstart (below)
	mov	ax,offset mos:mosstart
	push	ax
	ret
start	endp

bootstrap segment at 0
	include	mboot.inc
bootstrap ends
	assume	cs:grp,ds:bootstrap,es:nothing,ss:bootstrap

	subttl mosboot - boot logic
	page
;======================================================================
;,fs
; mosboot - boot logic
;
; read through to end of file cluster
; must near return to mos with ds -> boot sector
;
; in:	es = segment address to start loading remainder of mos
;	bx = cluster address of first cluster of mos
;	ds, ss = bootstrap sector
;
; out:	
;
;,fe
;======================================================================
	assume	ds:bootstrap,es:nothing,ss:bootstrap
mosboot:
	mov	dx,bx
	call	nxtcls
	mov	bx,dx			; first cluster in remainder of read
	xor	cx,cx

; collect clusters while contiguous until eof

mboot1:
	inc	cx
	push	dx
	push	cx
	call	nxtcls
	pop	cx
	pop	di
	cmp	dx,0fff8h		; so di = 0fff7h doesn't compare contiguous
	jae	mboot2			;   to eof
	inc	di
	cmp	di,dx
	je	mboot1

; read all the contiguous ones then continue

	push	dx
	call	rdclust
	pop	dx
	mov	bx,dx
	xor	cx,cx
	jmp	mboot1
mboot2:
	call	rdclust
	ret				; ret to mos startup

	subttl nxtcls - get cluster number of next cluster in file
	page
;======================================================================
;,fs
; nxtcls - get cluster number of next cluster in file
;
; in:	dx = cluster number
;
; out:	dx = next cluster in file
;
;,fe
;======================================================================
	assume	ds:bootstrap,es:nothing,ss:bootstrap
nxtcls:
	cmp	[bigfat],0
	jne	nxtcl2

; this one is a little (12-bit) fat

	mov	si,dx			; fat offset is cluster * 3 / 2
	add	dx,dx
	add	dx,si
	mov	si,dx			; si = fat offset * 2

; prepare for call to getcls
; si will be fat offset * 2 and will eventually be the offset within
;   the fat sector
; dx will be shifted right by cl to form the fat sector offset to be read

	mov	cl,[sctshft]		; cl prepared for / 2 for above + / sctsiz
	inc	cl			;  to find fat sector #
	call	getcls
	and	dx,0fffh		; and out any but meaningful 12 bit
	cmp	dx,0ff8h
	jb	nxtcl3
	or	dx,0f000h
	jmp	short nxtcl3

; this is for a big fat

nxtcl2:
	add	dx,dx
	mov	si,dx			; si & dx = fat offset

; prepare for call to getcls
; si will be fat offset * 2 and will eventually be the offset within
;   the fat sector
; dx will be shifted right by cl to form the fat sector offset to be read

	rcr	dx,1			; (c flag, if set by above, is significant)
	shl	si,1			; (as above we want fat offset * 2 )
	mov	cl,[sctshft]
	dec	cl			; already shifted right 1 above to get c flag
	call	getcls
nxtcl3:
	ret

	subttl getcls - get a cluster
	page
;======================================================================
;,fs
; getcls - get a cluster
;
; this is here just because it was easy to transform the 16 bit logic in
; such a manner that all of this code could be shared to save space, and
; otherwise much of the code was duplicated, wasting space
;
; in:	( si and (sctsiz*2-1) ) = byte offset of cluster 
;	 within fat sector * 2
;	dx shr cl = sector offset of cluster within fat
;
; out:	( dx and (2 ^ fat entry size - 1) ) = next cluster
;
;,fe
;======================================================================
	assume	ds:bootstrap,es:nothing,ss:bootstrap
getcls:
	mov	ax,dx
	shr	ax,cl
	add	ax,[bs_bpb.bsResSectors]
	cmp	ax,[fatbuf]		; fat sector number currently in the buffer
	je	getcl1			; already in the buffer
	push	es
	mov	cx,ds
	add	cx,512/16		; pointing to fat buffers (bootbuf)
	mov	es,cx
	mov	cx,2			; 2 at a time in case entry is split across
	push	si
	xor	dx,dx
	push	ax
	call	read
	pop	ax
	pop	si
	pop	es
	mov	[fatbuf],ax		; else read it and remember it
getcl1:
	mov	cx,[bs_bpb.bsBytesPerSec]
	shl	cx,1
	dec	cx
	and	si,cx			; si and (sctsiz*2)-1
	shr	si,1			; /2 for actual offset
	mov	dx,[si+512]
	jnc	getcl2
	mov	cl,4
	shr	dx,cl
getcl2:
	ret

	subttl rdclust - read a bunch of clusters
	page
;======================================================================
;,fs
; rdclust - read a bunch of clusters
;
; read cx clusters starting at cluster bx into buffer at es
; adjust es past last read
; bx unchanged
;
; in:	
;
; out:	
;
;,fe
;======================================================================
	assume	ds:bootstrap,es:nothing,ss:bootstrap
rdclust:
	mov	al,[bs_bpb.bsSecPerClust]
	xor	ah,ah
	xchg	ax,cx
	mul	cx
	xchg	ax,cx			; = total sectors to be read
	mov	dx,bx
	dec	dx
	dec	dx
	mul	dx
	add	ax,[cdata]
	adc	dx,0			; dx:ax = starting sector to read
	call	read
	ret

	align	16			; ensure scb on paragraph boundary.

fgscboff label	byte
	assume	cs:grp,ds:grp
	include mosscbdf.inc		; scb definition include file
gdata	ends

	subttl	foreground tcb definition
	page

tcb	segment
	public	fgtcboff
fgtcboff label	byte
	include mostcb.inc		; tcb definition
tcb	ends

irq	segment
	extrn	irqend:byte
	public	irqstart
irqstart label	byte			; specify the address of the first table entry by
					;   specifying the address of the start of irq segment
irq	ends

poll	segment
	extrn	pollend:byte
	public	pollstart
pollstart label byte			; specify the address of the first table entry by
					;   specifying the address of the start of poll segment
poll	ends

ddt     segment
	assume  cs:mo2
	public  mo2start
mo2start label	byte

        extrn   callfun1:near,mo2end:byte
        public  sbios2
	public	grpseg2

sbios2  dw      0040h			; temporary inside ddt seg
grpseg2	dw	0

	db	'PATCH-MO2'
mo2pat	db	patchsize dup (0)

ddt     ends

;======================================================== mos segment
if 0 eq 0
segment_num = 1
endif
mosseg	segment
	assume	cs:mos,ds:nothing,es:nothing,ss:nothing

	public	mosstart, mo2seg, scbfree, bootseg, mo2fun, sbios
	public	grpseg1, sinit, sinitaddr, initcall

	extrn	mosend:byte
	extrn	mosinit:near, getkeys:near, moscall:near

	subttl mosstart - entry point to mosinit
	page
;======================================================================
;,fs
; mosstart - entry point to mosinit
;
; mosstart is the first byte of the code segment - it also forces the
; cs register to be correct for the mos segment, regardless of how
; execution arrives here - so long as mos starts on a paragraph
;
; in:	
;
; out:	
;
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:nothing
mosstart proc	far
	call	mosofs
mosofs: 
	pop	ax			; what offset are we executing at
	sub	ax,offset mos:mosofs	; ax = byte correction to mos segment
	mov	cl,4
	sar	ax,cl			; ax = segment correction for mos execution
	mov	cx,cs
	add	ax,cx
	push	ax			; far transfer (with correct mos cs) to mosinit
	mov	ax,offset mos:mosinit
	push	ax
	ret
mosstart endp


; sah	07/23/88 the following code starts at origin 1080h and all code
;		 before this in mos segment is discarded when mos finally
;		 relocates it self during initp5 during mosinit.
;
; special note:  for code size efficenciety part of mos init code can be
;		 moved above this location which means that this code will
;		 not be include in final object image


	db	1080h dup (90h)		; start at 1080h
	org	1080h

; below locations are constant by the time we are executing in mosseg
; either they are built in to rom, or they are initialized by the startup
; code in grp
; the mos2 label is used as a dword far call into the mosfutil code area
; which resides in mo2

	even
mo2fun	dw	offset mo2:callfun1	; offset of mos 2nd code fun depatcher
mo2seg	dw	?			; segment address of mos 2nd code seg

; !!!sah!!! the following 2 word will need to be remove later

scbfree dw	?			; segment address of first free memory
bootseg dw	?			; segment address of boot sector
					;   (startup default disk bpb starts at offset
					;   11 if romed with a 4 byte id at offset 3
					;   consisting of 'MOS '

; following is a constant use for accessing the bios word at
; 40:03fa and 40:3fc for accessing scbseg (grp) and zero segment

sbios	  dw	0040h
grpseg1	  dw	0		;031288
initcall  dw	offset init:incall	; use for far calls to init segment
sinit	  dw	0			; start address of init segment
sinitaddr dw	0			; address use in passing

	assume	cs:mos,ds:nothing,es:nothing,ss:nothing

if1
	%out
	%out	* * * * * * * * * * * * * * * * * * * * * * * * * * * * *
	%out	*							*
endif

ifdef bugreport

if1
	%out	* debug option for internal error reporting is on	*
endif

errmsg	db	0dh,0ah,'Internal error #',0  ;@@xlat

	subttl bugerror - display string at return address from caller then hang
	page
;======================================================================
;,fs
; bugerror - display string at return address from caller then hang
;
; in:	
;
; out:	
;
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:nothing
bugerror:
	cld
	sti
	mgetscb	ds
	assume	ds:grp
	cmp	word ptr [scbdump+2],0
	je	nobugret
	mov	ah,1
	call	dword ptr [scbdump]	; call dumper
nobugret:
	push	cs
	pop	ds
	mov	si,offset errmsg
	call	dspstr
	pop	si
	call	dspstr
	assume  ss:tcb
	cmp	[tcbtype], 'T'		; make sure we are at a tcb
	je	bugloop
	push	cs
	pop	ds
	mgetscb	es
	assume  es:grp
	mov	ax, [scbtcbpc]
	cli
	push	ax
	pop	ss
	sti
bugloop:
	call	getkeys			; attempt to allow for ctl-alt-del's
	jmp	short bugloop

	subttl dspstr - display a null-terminated string at ds:si
	page
;======================================================================
;,fs
; dspstr - display a null-terminated string at ds:si
;
; in:	ds:si -> asciiz string
;
; out:	
;
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:nothing
dspstr:
	lodsb
	or	al,al
	jz	dspst1
	mov	ah,14
	mov	bx,7
	int	10h
	jmp	short dspstr
dspst1:
	ret

else
if1
	%out	* debug option for internal error reporting is off	*
endif
endif

if1
	%out	*							*
	%out	* * * * * * * * * * * * * * * * * * * * * * * * * * * * *
endif

;-----------------------------------------------------------------------
;	this is a temporary home for the critical flag (scbnoswt)
;	routines.  call noswitch to tell you are in a critical section
;	of code and that no task switch is to take place, and call
;	okswitch to tell mos that it may now switch.
;	note: there are duplicate routines in mosfun39 for use by code
;	that resides in the mo2 group.
;-----------------------------------------------------------------------
	assume	cs:mos,ds:nothing,es:nothing,ss:nothing

public	noswitch, okswitch

	subttl noswitch - disable task switching
	page
;======================================================================
;,fs
; noswitch - disable task switching
;
; in:	
;
; out:	
;
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:nothing
noswitch proc	near
	push	ds
	mgetscb	ds
	assume	ds:grp
	inc	[scbnoswt]
	pop	ds
	ret
noswitch endp

	assume	ds:nothing

	subttl okswitch - ensable task switching
	page
;======================================================================
;,fs
; okswitch - ensable task switching
;
; in:	
;
; out:	
;
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:nothing
okswitch proc	near
	push	ds
	mgetscb ds
	assume	ds:grp
	dec	[scbnoswt]
	pop	ds
	ret
okswitch endp

	assume	ds:nothing

	 db	'PATCH-MOS'
mospat   db	(patchsize+128) dup(0)

mosseg ends

; following is used for defining the init segment

;======================================================== init segment
if 0 eq 0
segment_num = 3
endif
initseg	segment
	extrn	initend:byte
	extrn	incall:near

	public imosaddr, mscall
	public initstart, initmos, initmo2, initgrp

initstart label	byte
mscall   dw	offset mos:moscall ; offset of routine to call in mos segment
initmos	 dw	0		; pointer to mos segment for init segment
initmo2  dw	0		; pointer to mo2 segment for init segment
initgrp	 dw	0		; pointer to grp segment for init segment
imosaddr dw	0		; address use in calling mos from init
initseg	ends

fcseg	segment
public	fcstart
fcstart label byte		; start of far call list
fcseg	ends

	end	start

