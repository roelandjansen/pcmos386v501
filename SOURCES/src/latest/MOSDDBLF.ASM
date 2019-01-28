	include page.inc
	title	mosddblf - mos device driver for fixed disk i/o
comment ^==============================================================
		      development specification

 program name:	$$mos.sys		assigned to: rod roark
 module name:	mosddblf		assign date: 10/29/86
 entry points:	n/a			completed:   10/29/86
 entry from:	n/a
 entry method:	n/a
 calls:		n/a
 purpose:	mos block device driver (fixed disk)
 refer to:	n/a
 last update:	08/18/1992
========================================================================

jsm 01/19/87	multiple logical drives, moxfdisk, & format

jsm 02/11/87	large volume support

jsm 04/14/87	return sector offset from partition table as
		hidden sector count to generic i/o ctl

rbr 07/05/87	support up to 32 sectors per track.
		don't abort INIT if errors.
		use default bpb on init if sector size <> 512.

rbr 10/27/87	support up to 35 sectors per track.

sah 01/20/88	change scbseg and zero to mgetxxx macros

rbr 01/26/88	support up to 64 sectors per track.

rbr/sah 02/21/88 move ddt code to mo2 group.

sah 03/01/88	when initializing hard disks, some hard drives
		like the 40 meg model 80 drive required a bios
		reset on the hard drive.

jrb 06/03/88	changed sense of ibm bit - current dos
		drivers (including us) are not ibm devices -
		that is, they don't require the first fat
		sector on a build bpb call

rbr 12/05/88	since format now checks to see if generic ioctl
		is supported (so we don't try to format a ram-
		disk), device attribute bit 6 must be on. also,
		homed the drive head before the reset command.

mjs 04/19/91	added int13fun00 reset call after failure on
		read or write.	this should fix the sporadic
		"error: unspecified device failure while flushing ..."
		patch 42 applies this fix to the 4.10 kernel.

mjs 12/16/91	dlg mods: complete overhaul.  modified to support dlg and
		extended partitions.  dropped support for mlg partitions. 
		adpated request header format for dos 32 bit sector
		numbers.  added support for i21f44s0ds0846, i21f44s0ds0846
		and i21f44s11.  dib records are now allocated out of the
		smp since up to 24 could be needed (for drives c: through
		z:).  converted to use of structures within dskstruc.inc.

================ 5.01 Kernel Ends Here ====================================

mjs 07/23/92	when partition is not extended, make sure that the
		high byte of the hidden sectors field is 0.  can be
		non-zero from a partition made with mos 4.10 or older.
		also, when validating a bpb, in addition to checking
		for the signature, validate the hidden count against
		the value from the partition table entry.  partitions
		made with a kernel patched with 501_p01.pat could
		need this correction (this first patch is bad).
		this fix is effected by static patch 501_p02.pat.

mjs 08/18/92	clean up segment declarations

======================================================================^

.xlist
;	include mosddblf.pub
	include mosregs.inc
	include dskstruc.inc
	include macros.inc
	include group.inc
.list

gdata	segment
	extrn ourbuf:byte	; system init disk buffer (mosint13)

;==== bits in the attribute byte in the dib block

dtmsk		equ	7	; mask for disk types
dtnone		equ	0	; no disk there
dtnochg		equ	1	; drive without change line -- 360k disk (old)
dtchg		equ	2	; drive with change line -- 1.2m disk drive
dtfixed		equ	3	; hard disk drive
loadbpb		equ	8	; set if bpb should be loaded from media
bpberr		equ	010h	; set if error loading bpb from media
dirtybpb	equ	020h	; set when we have to load bpb from disk
firstbpb	equ	040h	; set first time bpb is loaded

;==== command subcodes for generic i/o control

setparms	equ	040h	; set device parameters
getparms	equ	060h	; get device parameters
wrttrack	equ	041h	; write track on logical device
rdtrack		equ	061h	; read track on logical device
fvtrack		equ	042h	; format and verify track on logical device
vertrack	equ	062h	; verify track on logical device
getmedid	equ	066h	; get media id
setmedid	equ	046h	; get media id

biostl		equ	06ch	; bios timer low address (seg 40)
biosth		equ	06eh	; bios timer high address (seg 40)
lblsiz		equ	11	; size of mos volume label

;==== device information block

dbpb_size	equ	25	; bytes for 1 bpb section of the dib

dib	struc

; real bpb for unit

dibBytesPerSec	dw	?	; bytes per sector
dibSecPerClust	db	?	; sectors per cluster
dibResSectors	dw	?	; # of reserved sectors
dibFATs		db	?	; # of FAT tables
dibRootDirEnts	dw	?	; # of root directory entries
dibSectors	dw	?	; total # of sectors
dibMedia	db	?	; media descriptor
dibFATsecs	dw	?	; # of sectors per FAT
dibSecPerTrack	dw	?	; # of sectors per track
dibHeads	dw	?	; # of heads
dibHiddenSecs	dd	?	; # of hidden sectors
dibHugeSectors	dd	?	; # of sectors when dibSectors == 0

; default bpb for unit

dibdBytesPerSec dw	?	; bytes per sector
dibdSecPerClust db	?	; sectors per cluster
dibdResSectors	dw	?	; # of reserved sectors
dibdFATs	db	?	; # of FAT tables
dibdRootDirEnts dw	?	; # of root directory entries
dibdSectors	dw	?	; total # of sectors
dibdMedia	db	?	; media descriptor
dibdFATsecs	dw	?	; # of sectors per FAT
dibdSecPerTrack dw	?	; # of sectors per track
dibdHeads	dw	?	; # of heads
dibdHiddenSecs	dd	?	; # of hidden sectors
dibdHugeSectors dd	?	; # of sectors when dibdSectors == 0

; other dib data

dibOffsetLo	dw	?	; low word of physical disk offset
dibOffsetHi	dw	?	; high word of physical disk offset
dibCylsPerTrack dw	?	; number of cylinders on disk
dibCylsFBeg	dw	?	; cylinders from beginning of disk
dibAttributes	db	?	; drive attributes
dibRealDrive	db	?	; drive number this drive really should be
dibPBRcx	dw	?	; cx for i13 call to access partition boot record
dibPBRdx	dw	?	; dx for i13 call to access partition boot record
dib ends

badlayout	dw	0	; non-zero if funny track layout

tracktable	label word
	dw	17		; 17 entries in the default table
	dw	1
sec1size dw	512		; sector 1, 512 bytes long
	dw	2,512
	dw	3,512
	dw	4,512
	dw	5,512
	dw	6,512
	dw	7,512
	dw	8,512
	dw	9,512
	dw	10,512
	dw	11,512
	dw	12,512
	dw	13,512
	dw	14,512
	dw	15,512
	dw	16,512
	dw	17,512
	dw	18,512
	dw	19,512
	dw	20,512
	dw	21,512
	dw	22,512
	dw	23,512
	dw	24,512
	dw	25,512
	dw	26,512
	dw	27,512
	dw	28,512
	dw	29,512
	dw	30,512
	dw	31,512
	dw	32,512
	dw	33,512
	dw	34,512
	dw	35,512
	dw	36,512
	dw	37,512
	dw	38,512
	dw	39,512
	dw	40,512
	dw	41,512
	dw	42,512
	dw	43,512
	dw	44,512
	dw	45,512
	dw	46,512
	dw	47,512
	dw	48,512
	dw	49,512
	dw	50,512
	dw	51,512
	dw	52,512
	dw	53,512
	dw	54,512
	dw	55,512
	dw	56,512
	dw	57,512
	dw	58,512
	dw	59,512
	dw	60,512
	dw	61,512
	dw	62,512
	dw	63,512
	dw	64,512

maxtrktbl equ (($ - tracktable) / 4)

formattable	label	byte
	db	(maxtrktbl * 2) dup (?) ; table for format call

;==== miscellaneous data
	even

hdr		dw	2 dup(0) ; request header pointer
biosfun		db	0	; temp holding for next disk function
sectcnt		dw	0	; total count of sectors for read or write
sectstr		dw	0	; starting sector for next disk i/o in loop
		dw	0	; high word of starting sector (if needed)
giobuf		dd	0	; buffer pointer for doint generic i/o
typrtr		db	0	; retry count for generic i/o
		db	0	; fill to word boundary
drives		db	0	; actual number of hard drives
pt0		dw	0	; ptr to copy of drive 0's partition table
pt1		dw	0	; ptr to copy of drive 1's partition table
dib_seg		dw	0	; ptr to dib storage area within smp
dib_cnt		db	-1	; actual number of dib entries (0 based)
dib_max		db	0	; max possible number of dib entries (init only)
dib_ptr		dw	0	; offset of dib entry being operated on
nslow		dw	0	; low word in # of sectors in partition
nshigh		dw	0	; high word of # of sectors in partition
strtsec		dd	0	; starting sector adjustment factor (init only)
public trueboot
trueboot	db	0,0,0	; used by mosinit to adjust scbbootdrv

dib_total	equ	24	; for drive letters c: through z:
dib_overhead	equ	24*2	; bytes for bpb array at start of dib block

emsg1		db	'Insufficient SMP for number of partitions            ',13,10,'$'	;@@xlat
emsg2		db	'Disk error during partition scan            ',13,10,'$'	;@@xlat

;==== default bpb for unformatted disk.

dftbpb	bpb	<512,4,1,2,512,4080,0f8h,1,17,5,0>

;==== function table

	even
hfuntbl	dw	hinitblk	; 0  init
	dw	hmedck		; 1  media check
	dw	hbldbpb		; 2  build bpb
	dw	0		; 3  i/o control input
	dw	hinput		; 4  input (read)
	dw	0		; 5  nondestructive input no wait
	dw	0		; 6  input status
	dw	0		; 7  input flush
	dw	houtput		; 8  output (write)
	dw	houtver		; 9  output with verify
	dw	0		; 10 output status
	dw	0		; 11 output flush
	dw	0		; 12 i/o control output
	dw	0		; 13 device open
	dw	0		; 14 device close
	dw	0		; 15 removable media
	dw	0		; 16 illegal
	dw	0		; 17 illegal
	dw	0		; 18 illegal
	dw	hgenioctl	; 19 generic i/o control
	dw	0		; 20 illegal
	dw	0		; 21 illegal
	dw	0		; 22 illegal
	dw	0		; 23 get logical device
	dw	0		; 24 set logical device
	dw	hioquery	; 25 query ioctl

hmax_func equ (($-hfuntbl)/2-1)

gdata	ends

;======================================================== mos segment
if 0 eq 0
segment_num = 1
endif
mosseg	segment
	assume	cs:mos,ds:nothing,es:nothing,ss:nothing

	extrn sbios:word, mosheman:near

;==== device header

	public	scbstdhd
scbstdhd label	byte

	dd	-1

; bit1 is set to declare support for 32 bit sector numbers.
; bit6 is set to declare support for generic ioctl functions.

	dw	0010000001000011b	
	dw	mos:blkstrat
	dw	mos:blkintr
	db	8 dup (0)		; # devices passed at init

	subttl blkstrat - block strategy routine
	page
;======================================================================
;,fs
; blkstrat - block strategy routine
;
; in:	es:bx points to the device request header.
;
; out:	the request header pointer is saved.
;
;,fe
;=====================================================================
	assume	ds:nothing,es:nothing,ss:nothing
blkstrat proc far
	push	ds
	mgetscb ds
	assume	ds:grp
	mov	[hdr],bx		; save pointer
	mov	[hdr+2],es
	pop	ds
	assume	ds:nothing
	ret
blkstrat endp

	subttl blkintr - block interrupt routine
	page
;======================================================================
;,fs
; blkintr - block interrupt routine
;
; in:	none
;
; out:	none
;
;,fe
;=====================================================================
	assume	ds:nothing,es:nothing,ss:nothing
blkintr proc far
	pushf
	push	ax
	push	bx
	push	cx
	push	dx
	push	si
	push	es
	push	ds
	mgetscb ds
	assume	ds:grp
	les	bx,dword ptr [hdr]
	mov	al,es:[bx].rhUnit	; save unit code for later
	mov	bl,es:[bx].rhFunction	; get command code
	cmp	bl,hmax_func		; check for invalid call
	ja	herr1			; if bad command code
	cmp	al,[dib_cnt]		; unit # in proper range?
	ja	herr2			; if too high (yes, i want a ja here!)
	mov	ah,size dib
	mul	ah			; form pointer to dib record
	add	ax,16+dib_overhead	; skip smp header and bpb array
	mov	si,ax
	push	es
	mov	es,[dib_seg]
	mov	dl,es:[si].dibRealDrive	; get real drive number for unit
	pop	es
	xor	bh,bh
	shl	bx,1
	mov	bx,[bx+hfuntbl]		; get address of appropriate routine
	or	bx,bx			; legal code?
	jz	herr1			; if illegal code

; at this point,
;  [dib_seg]:si -> dib record for logical drive
;  ds -> grp
;  dl = drive number (e.g. 80, 81)

	call	bx			; call the function
hrexit:
	pop	ds
	pop	es
	pop	si
	pop	dx
	pop	cx
	pop	bx
	pop	ax
	popf
	ret
herr1:
	les	bx,dword ptr [hdr]	; get request header pointer
	mov	es:[bx].rhStatus,8103h	; return 'Unknown Command'
	jmp	hrexit
herr2:
	les	bx,dword ptr [hdr]	; get request header pointer
	mov	es:[bx].rhStatus,8101h	; return 'Bad Unit'
	jmp	hrexit
blkintr endp

	subttl hmedck - media check
	page
;======================================================================
;,fs
; hmedck - media check
;
; in:	ds -> grp
;	[dib_seg]:si -> dib record for logical drive
;	dl = drive number (e.g. 80, 81)
;
; out:	none
;
;,fe
;=====================================================================
	assume	ds:grp,es:nothing,ss:nothing
hmedck proc near
	mov	es,[dib_seg]
	test	es:[si].dibAttributes,dirtybpb ; tell mos new bpb?
	jz	hmed10			; if bpb needn't be changed
	mov	al,-1			; if bpb should be changed,
	jmp	short hmed20		; return "media changed"
hmed10:
	mov	al,1			; "no change"
hmed20:
	and	es:[si].dibAttributes,not dirtybpb  ; bpb will be clean soon.
	les	bx,dword ptr [hdr]
	mov	es:[bx].mrReturn,al	; media changed or not
	mov	es:[bx].mrStatus,0100h	; return with 'DONE'
	ret
hmedck endp

	subttl hbldbpb - build bios parm block
	page
;======================================================================
;,fs
; hbldbpb - build bios parm block
;
; in:	ds -> grp
;	[dib_seg]:si -> dib record for logical drive
;	dl = drive number (e.g. 80, 81)
;
; out:	none
;
;,fe
;=====================================================================
	assume	ds:grp,es:nothing,ss:nothing
hbldbpb proc near
	les	bx,dword ptr [hdr]
	mov	word ptr es:[bx].bbrBPBAddress,si  ; set bpb pointer offset
	mov	ax,[dib_seg]
	mov	word ptr es:[bx+2].bbrBPBAddress,ax
	mov	es:[bx].bbrStatus,100h	; return 'Done'
	ret
hbldbpb endp

	subttl hinput - input read
	page
;======================================================================
;,fs
; hinput - input read
;
; in:	ds -> grp
;	[dib_seg]:si -> dib record for logical drive
;	dl = drive number (e.g. 80, 81)
;
; out:
;
;,fe
;=====================================================================
	assume	ds:grp,es:nothing,ss:nothing
hinput proc near
	mov	[biosfun],2		; bios function 2 - read
outentry:
	push	di
	les	bx,dword ptr [hdr]
	mov	ax,es:[bx].rwrBytesSec	; get sector count
	mov	[sectcnt],ax		; save total count for io

; get the starting sector number.  since this driver has bit1 of 
; its attribute word set, it must deal with dos's 32 bit interface
; for the starting sector number.  if the word sized starting sector
; number field (rwrStartSec) is ffff, the actual starting sector 
; number is in the dword field named rwrHugeStartSec.

	xor	dx,dx
	mov	ax,es:[bx].rwrStartSec
	cmp	ax,0ffffh
	jne	have_sect
	mov	ax,word ptr es:[bx].rwrHugeStartSec
	mov	dx,word ptr es:[bx].rwrHugeStartSec+2
have_sect:
	mov	[sectstr],ax
	mov	[sectstr+2],dx
	les	bx,es:[bx].rwrBuffer	; get transfer address
	mov	cx,3			; 3 retries
diskio_loop:
	push	cx			; save retry count
	mov	ax,[sectstr]		; get starting logical sector
	mov	dx,[sectstr+2]		; high word of starting sector
	call	calcabs			; calculate absolute disk loc. from logical
	push	es
	mov	es,[dib_seg]
	mov	dl,es:[si].dibRealDrive	; disk drive to use
	mov	ax,es:[si].dibSecPerTrack
	pop	es
	push	bx			; save buffer pointer
	mov	bx,[sectcnt]		; # sectors io
	inc	ax			; max per io +1
	push	cx
	and	cl,3fh
	sub	al,cl			; calc # sectors til end of track (this head)
	pop	cx
	cmp	ax,bx			; enough?
	jb	iopart			; no, must do some more io later
	mov	ax,bx			; yes, just what is needed
iopart:
	mov	di,ax			; save io count
	pop	bx			; restore buffer pointer
	mov	ah,[biosfun]		; bios disk function
	int	13h
	jnc	iook
	push	ax
	mov	ah,0			; reset after error
	int	13h
	pop	ax
	pop	cx
	loop	diskio_loop
	jmp	hdskerr
iook:
	pop	cx			; clear retry count from stack
	sub	[sectcnt],di		; update amount of io
	add	[sectstr],di		; update new starting sector
	adc	[sectstr+2],0		; update high word too
	mov	ax,[sectcnt]
	or	ax,ax			; have we read all that was requested
	jz	endio			; yes, exit
	mov	cx,3			; new retry count
	mov	ax,di			; get # sectors (read or written)
	xor	dx,dx			;   operation
	push	es
	mov	es,[dib_seg]
	mul	es:[si].dibBytesPerSec	; * bytes per sector
	pop	es
	add	bx,ax			; update new buffer pointer
	jmp	diskio_loop		; no, read next group
endio:
	les	bx,dword ptr [hdr]
	mov	es:[bx].rwrStatus,0100h ; return 'Done'
	pop	di
	ret
hinput endp

;-----------------------------------------------------------------------
; a jump is made here if the bios returns a disk error during read or
; write. the bios error is translated.
;
; error table and request header are given to diskerr in mosddblk
; diskerr pops di before returning to caller.
;-----------------------------------------------------------------------
	extrn	dskerrtbl:byte, diskerr:near
hdskerr:
	les	bx,dword ptr [hdr]
	mov	di,offset dskerrtbl	; error translate table
	jmp	diskerr			; translate store and return

	subttl calcabs - calculate absolute sector
	page
;======================================================================
;,fs
; calcabs - calculate absolute sector
;
; this routine will calculate the absolute disk location
; from the logical sector number.
;
; in:	dx:ax = logical sector number
;	[dib_seg]:si -> dib record for logical drive
;	ds -> grp
;
; out:	dh = head number
;	ch = low 8 bits of cylinder number
;	cl = sector number (0-5); high cylinder bits (6-7)
;
;,fe
;=====================================================================
	assume	ds:grp,es:nothing,ss:nothing
calcabs proc near
	pushset ax,es
	mov	es,[dib_seg]
	add	ax,es:[si].dibOffsetLo	; disk partitioning adjustment
	adc	dx,es:[si].dibOffsetHi
	mov	cx,es:[si].dibSecPerTrack
	push	bx			; remainder comes in bx
	mov	cx,es:[si].dibSecPerTrack
	call	ldiv
	mov	cl,bl			; giving remainder = sector number
	pop	bx
	inc	cl			; and quotient = relative track
	div	es:[si].dibHeads	; divide by tracks/cylinder (# heads)
	xchg	dh,dl			; giving remainder = head number
	mov	ch,al			; and quotient = cylinder number
	mov	al,0			; pick up quotient high bits
	shr	ax,1
	shr	ax,1
	or	cl,al
	popset	ax,es
	ret
calcabs endp

	subttl houtput - output write
	page
;======================================================================
;,fs
; houtput - output write
;
; in:	ds -> grp
;	[dib_seg]:si -> dib record for logical drive
;	dl = drive number (e.g. 80, 81)
;
; out:
;
;,fe
;=====================================================================
	assume	ds:grp,es:nothing,ss:nothing
houtput proc near
	mov	[biosfun],3		; bios function 3 - write
	jmp	outentry		; use same routines as 'input' function
houtput endp

	subttl houtver - output with verify
	page
;======================================================================
;,fs
; houtver - output with verify
;
; in:	ds -> grp
;	[dib_seg]:si -> dib record for logical drive
;	dl = drive number (e.g. 80, 81)
;
; out:
;
;,fe
;=====================================================================
	assume	ds:grp,es:nothing,ss:nothing
houtver proc near
	mov	[biosfun],3		; bios function 3 - write
	jmp	outentry		; use same routines as 'input' function
houtver endp

	subttl hgenioctl - generic i/o control
	page
;======================================================================
;,fs
; hgenioctl - generic i/o control
;
; subfunctions:
;
; sub 40h - set device parameters
; sub 60h - get device parameters
; sub 41h - write track on logical device
; sub 61h - read track on logical device
; sub 42h - format and verify track on logical device
; sub 62h - verify track on logical device
; sub 66h - get media id
; sub 46h - set media id
;
; in:	ds -> grp
;	[dib_seg]:si -> dib record for logical drive
;	dl = drive number (e.g. 80, 81)
;
; out:
;
;,fe
;=====================================================================
	assume	ds:grp,es:nothing,ss:nothing
hgenioctl proc near
	les	bx,dword ptr [hdr]
	mov	cl,es:[bx].giMinorCode	; minor function code
	cmp	cl,setparms
	je	hgen10
	cmp	cl,getparms
	je	hgen20
	cmp	cl,wrttrack
	je	hgen30
	cmp	cl,rdtrack
	je	hgen40
	cmp	cl,fvtrack
	je	hgen50
	cmp	cl,vertrack
	je	hgen60
	cmp	cl,getmedid
	je	hgen70
	cmp	cl,setmedid
	je	hgen80
	mov	es:[bx].giStatus,8103h	; return 'Unknown Command'
	ret
hgen10:
	jmp	hgsetparms
hgen20:
	jmp	hggetparms
hgen30:
	jmp	hgwrttrack
hgen40:
	jmp	hgrdtrack
hgen50:
	jmp	hgfvtrack
hgen60:
	jmp	hgvertrack
hgen70:
	jmp	hgetmedid
hgen80:
	jmp	hsetmedid
hgenioctl endp

	subttl hgsetparms - generic i/o ctl set parameters
	page
;======================================================================
;,fs
; hgsetparms - generic i/o ctl set parameters
;
; in:	ds -> grp
;	[dib_seg]:si -> dib record for logical drive
;	dl = drive number (e.g. 80, 81)
;	es:bx -> request header
;
; out:
;
;,fe
;=====================================================================
	assume	ds:grp,es:nothing,ss:nothing
hgsetparms proc near
	les	bx,dword ptr [hdr]
	push	ds
	push	ds
	lds	bx,es:[bx].giIOCTLData	; pointer to ioctl request
	pop	es			; es points to old ds
	push	si
	assume	ds:nothing,es:grp
	mov	cx,[bx].dpTracks	; number of tracks in sector
	cmp	cx,maxtrktbl		; more than we can hold?
	lja	hgset50			; if too many
	shl	cx,1			; tracks*2 == words in table
	inc	cx			; plus the track count
	lea	si,[bx].dpTracks	; source for copy
	mov	di,offset tracktable	; destination for copy
	cld
	rep	movsw			; copy the track table
	pop	si			; construct format table
	call	makeftbl		; from track table
	test	[bx].dpSpecFunc,2	; ignore all but track table?
	jnz	hgset20			; if ignore all else

; copy bpb to driver.

	push	si
	test	[bx].dpSpecFunc,1	; default bpb or real bpb?
	jnz	hgset10			; if set real bpb

; copy default bpb into dib.

	mov	cx,dbpb_size
	lea	di,[si].dibdBytesPerSec ; address of default bpb
	lea	si,[bx].dpBytesPerSec	; address of caller's BPB
	mov	es,[dib_seg]
	assume	es:nothing
	rep	movsb			; copy the default bpb
	pop	si
	pop	ds
	assume	ds:grp
	or	es:[si].dibAttributes,loadbpb	; load bpb from real media

; load the real bpb again (we probably overwrote it)

	xor	ax,ax			; read logical sector 0
	mov	dx,ax
	call	calcabs			; dx & cx set up for read
	mov	dl,es:[si].dibRealDrive	; real drive id
	push	ds
	pop	es
	lea	bx,[ourbuf]		; sector buffer
	mov	ax,0201h		; command code to . . .
	int	13h			; read the sector
	push	si
	mov	di,si			; destination is our bpb
	lea	si,[bx+11]		; source is sector buffer + 11
	mov	cx,dbpb_size
	mov	es,[dib_seg]
	repe	movsb
	pop	si
	jmp	short hgset30		; exit function

; copy real bpb into dib

hgset10:
	assume	ds:nothing,es:grp
	mov	cx,dbpb_size
	mov	di,si			; copy into real bpb
	lea	si,[bx].dpBytesPerSec	; caller's BPB
	mov	es,[dib_seg]
	assume	es:nothing
	rep	movsb
	pop	si
	pop	ds
	assume	ds:grp
	and	es:[si].dibAttributes,not loadbpb  ; don't load BPB from disk
	or	es:[si].dibAttributes,dirtybpb ; make sure we read new bpb
	jmp	short hgset30		; exit function
hgset20:
	assume	ds:nothing,es:grp
	pop	ds
	assume	ds:grp,es:nothing
hgset30:
	mov	ax,0100h		; "Done" status code
hgset40:
	les	bx,dword ptr [hdr]
	mov	es:[bx].giStatus,ax	; return 'Done'
	ret
hgset50:
	assume	ds:nothing,es:grp
	pop	si
	pop	ds
	assume	ds:grp,es:nothing
	mov	ax,8105h		; return "Error, bad structure length"
	jmp	hgset40			; return to caller
hgsetparms endp

	subttl makeftbl - construct format table from track table
	page
;======================================================================
;,fs
; makeftbl - construct format table from track table
;
; this routine constructs the format buffer needed by the format
; call to format a track.  it constructs this table from the
; tracktable.  if the track layout table is a format supported
; by this routine, the badlayout flag will be cleared.	if the
; layout is not supported, the badlayout is not supported.
;
; in:	ds -> grp
;
; out:
;
;,fe
;=====================================================================
	assume	ds:grp,es:nothing,ss:nothing
makeftbl proc near
	push	ds
	push	es
	push	cx
	push	ax
	push	si
	push	di
	mgetscb ds
	push	ds
	pop	es
	assume	ds:grp
	mov	si,offset tracktable
	mov	di,offset formattable
	mov	[badlayout],0		; assume layout is good
	cld
	lodsw
	mov	cx,ax			; number of sectors to set up for
	jcxz	mkft30			; if zero sectors
	xor	ax,ax			; make high byte 0
	stosb				; store bytes backward
mkft10:
	lodsb				; sector number
	add	si,3			; skip high byte of sector & size
	stosw				; good sector, use given number
	loop	mkft10			; do the next sector
	jmp	mkft40			; exit routine
mkft30:
	mov	[badlayout],1		; bad track layout
mkft40:
	pop	di
	pop	si
	pop	ax
	pop	cx
	pop	es
	pop	ds
	ret
makeftbl endp

	subttl hggetparms - generic i/o ctl get parameters
	page
;======================================================================
;,fs
; hggetparms - generic i/o ctl get parameters
;
; in:	ds -> grp
;	[dib_seg]:si -> dib record for logical drive
;	dl = drive number (e.g. 80, 81)
;	es:bx -> request header
;
; out:
;
;,fe
;=====================================================================
	assume	ds:grp,es:nothing,ss:nothing
hggetparms proc near
	push	ds
	mov	ds,[dib_seg]
	assume	ds:nothing
	les	bx,es:[bx].giIOCTLData	; pointer to ioctl request
	push	si			; we use this later
	test	es:[bx].dpSpecFunc,1	; default bpb or real bpb?
	jnz	hgget20			; if real bpb
	lea	si,[si].dibdBytesPerSec ; pointer to default bpb
hgget20:
	lea	di,[bx].dpBytesPerSec	; where to copy the bpb
	mov	cx,dbpb_size		; length of it in bytes
	cld
	push	di
	rep	movsb			; copy into caller's buffer
	pop	di			; restore dib pointer
	pop	si

; return parameters for fixed disk drive.

	mov	es:[bx].dpDevType,5	; fixed disk drive
	mov	es:[bx].dpDevAttr,1	; can't remove, no change line
	mov	es:[bx].dpMediaType,0	; set media type
	mov	ax,[si].dibCylsPerTrack	; total cylinders on disk
	mov	es:[bx].dpCylinders,ax
	pop	ds
	assume	ds:grp
	les	bx,dword ptr [hdr]
	mov	es:[bx].giStatus,0100h	; return "Done"
	ret
hggetparms endp

	subttl hgwrttrack - generic i/o ctl write track
	page
;======================================================================
;,fs
; hgwrttrack - generic i/o ctl write track
;
; in:	ds -> grp
;	[dib_seg]:si -> dib record for logical drive
;	dl = drive number (e.g. 80, 81)
;	es:bx -> request header
;
; out:
;
;,fe
;=====================================================================
	assume	ds:grp,es:nothing,ss:nothing
hgwrttrack proc near
	mov	[biosfun],3		; bios function 3 - write
hg_rventry:
	les	bx,es:[bx].giIOCTLData  ; generic i/o request packet
	mov	ax,word ptr es:[bx].rwBuffer  ; set transfer address
	mov	word ptr [giobuf],ax
	mov	ax,word ptr es:[bx+2].rwBuffer
	mov	word ptr [giobuf+2],ax
	push	di			; save di before we munge it

; check starting sector.

	mov	ax,es:[bx].rwFirstSector; starting sector
	mov	[sectstr],ax		; store for later
	cmp	ax,[tracktable]		; is start sector too big?
	jb	hgwr10			; if start sector ok
	jmp	hgwrer1			; if start sector too big

; check sector count.

hgwr10:
	add	ax,es:[bx].rwSectors	; total sector count
	cmp	ax,[tracktable]
	jbe	hgwr20			; if sector count ok
	jmp	hgwrer1
hgwr20:
	mov	ax,es:[bx].rwSectors
	mov	[sectcnt],ax

; check head number.

	mov	cx,es:[bx].rwCylinder	; get requested cylinder (for below)
	mov	di,es:[bx].rwHead	; check requested head number
	mov	es,[dib_seg]
	cmp	di,es:[si].dibHeads	; head number above max?
	jb	hgwr30			; if head number ok
	jmp	hgwrer2			; if head number too big
hgwr30:
	cmp	di,es:[si].dibHeads	; head wrap?
	jb	hgwr40			; if no wrap, continue
	inc	cx			; up cylinder # by one
	sub	di,es:[si].dibHeads	; unwrap heads
	jmp	short hgwr40		; continue processing

;==== this is a jump and call entry point for code below

hg_fmtentry:
	push	di
	mov	ax,[tracktable+2]	; starting sector
	dec	ax			; make it 0-based
	mov	[sectstr],ax		; store for later
	mov	ax,[tracktable]		; sectors to format

; store sector count.

	mov	[sectcnt],ax

; check head number.

	mov	cx,es:[bx].rwCylinder	; get requ cylinder before change es
	mov	di,es:[bx].rwHead	; check requested head number
	mov	es,[dib_seg]
	cmp	di,es:[si].dibHeads	; head number above max?
	jae	hgwrer2			; if head number too big

; check cylinder number.

hgwr40:
	cmp	cx,es:[si].dibCylsPerTrack  ; greater than cylinders on device?
	jae	hgwrer3			; if out of range, add cylinder offset
	add	cx,es:[si].dibCylsFBeg	; to get physical cylinder

; set up registers for i/o.

	mov	[typrtr],3		; retry count
	and	cx,03ffh		; 10 bits of cylinder
	xchg	ch,cl			; low 8 bits in ch
	ror	cl,1
	ror	cl,1			; high 2 bits in high cl
	or	cl,byte ptr [sectstr]	; starting sector number
	inc	cl			; 1-based sector number
	mov	dh,dl			; save disk number here
	xor	dl,dl			; this will be head number
	or	dx,di			; get head number in dl
	xchg	dh,dl			; dh=head, dl=disk
	les	bx,[giobuf]		; where data lives
	jmp	short hg_iopart		; do the real i/o

; reset disk system & retry i/o.

hg_diskio:
	xor	ax,ax			; reset disk
	int	13h
	jnc	hg_iopart		; no errors continue with io
	jmp	hdskerr			; guess what . . .

; do the disk i/o.

hg_iopart:
	mov	al,byte ptr [sectcnt]	; sector count (format ignores this)
	mov	ah,[biosfun]		; function to perform
	int	13h
	jnc	hg_iook			; if no error doing i/o
	dec	[typrtr]		; out of retries?
	jnz	hg_diskio		; no, try i/o again
	jmp	hdskerr			; return user to caller

; the i/o call succeeded.

hg_iook:
	mov	ax,0100h		; return "Done"
hg_ioex:
	les	bx,dword ptr [hdr]
	mov	es:[bx].giStatus,ax	; return status code
	pop	di
	ret

; error handlers.

hgwrer1:
	mov	ax,08108h		; return "sector not found"
	jmp	hg_ioex
hgwrer2:
hgwrer3:
	mov	ax,08103h		; return "Bad command"
	jmp	hg_ioex

hgwrttrack endp

	subttl hgrdtrack - generic i/o ctl read track
	page
;======================================================================
;,fs
; hgrdtrack - generic i/o ctl read track
;
; in:	ds -> grp
;	[dib_seg]:si -> dib record for logical drive
;	dl = drive number (e.g. 80, 81)
;	es:bx -> request header
;
; out:
;
;,fe
;=====================================================================
	assume	ds:grp,es:nothing,ss:nothing
hgrdtrack proc near
	mov	[biosfun],2		; bios function 2 - read
	jmp	hg_rventry		; do the i/o
hgrdtrack endp

	subttl hgfvtrack - generic i/o ctl format & verify track
	page
;======================================================================
;,fs
; hgfvtrack - generic i/o ctl format & verify track
;
; in:	ds -> grp
;	[dib_seg]:si -> dib record for logical drive
;	dl = drive number (e.g. 80, 81)
;	es:bx -> request header
;
; out:
;
;,fe
;=====================================================================
	assume	ds:grp,es:nothing,ss:nothing
hgfvtrack proc near
	les	bx,es:[bx].giIOCTLData  ; generic i/o request packet
	mov	al,byte ptr [badlayout]
	shl	al,1			; bad bit is bit 1, not 0
	or	al,1			; no funny layouts
	test	es:[bx].rwSpecFunc,1	; just a status call?
	jnz	hgfv10			; exit if just status call
	test	al,2			; funny track layout?
	jz	hgfv20			; if layout ok
hgfv10:
	mov	es:[bx].rwSpecFunc,al	; tell if layout ok
	les	bx,dword ptr [hdr]
	mov	es:[bx].giStatus,0100h	; return "Done"
	ret

; if this disk partition is the first partition on the disk,
; don't allow formatting of cylinder 0, head 0.  The criterion
; for first partition is that its sector offset is not an even
; number of cylinders.

hgfv20:
	xor	ax,ax			; use for constant 0
	cmp	es:[bx].rwCylinder,ax	; cylinder 0?
	jne	hgfv40			; if not cylinder 0, normal
	cmp	es:[bx].rwHead,ax	; head 0?
	jne	hgfv40			; if not head 0, normal
	push	dx
	push	es
	mov	es,[dib_seg]
	mov	ax,es:[si].dibOffsetLo	; partition on cylinder bound?
	mov	dx,es:[si].dibOffsetHi	; divide sector offset by

; derive sectors per cylinder in cx and divide that into the current dx:ax

	push	cx
	push	ax
	push	dx
	mov	ax,es:[si].dibSecPerTrack
	mul	es:[si].dibHeads
	mov	cx,ax
	pop	dx
	pop	ax
	div	cx
	pop	cx

; if there is a remainder, disallow the format.

	pop	es
	or	dx,dx
	pop	dx
	jz	hgfv40

; don't allow format of track 0

	les	bx,dword ptr [hdr]
	mov	es:[bx].giStatus,0100h	; return "Done"
	ret
hgfv40:
	mov	word ptr [giobuf],offset formattable
	mov	word ptr [giobuf+2],ds
	mov	[biosfun],5		; bios function 5 - format
	call	hg_fmtentry		; format the track

; if the operation succeeded, the error bit in the driver request
; block will be reset.	es:bx will be left pointing to the main
; driver request block at this point, so we can conveniently test
; for an error.

	test	es:[bx].giStatus,080h	; did an error occur?
	jz	hgfv50			; if no error
	ret				; quit now if error
hgfv50:
	les	bx,es:[bx].giIOCTLData  ; generic i/o request packet
	mov	[biosfun],4		; bios function 4 - verify
	jmp	hg_fmtentry		; verify the track
hgfvtrack endp

	subttl hgvertrack - generic i/o ctl verify track
	page
;======================================================================
;,fs
; hgvertrack - generic i/o ctl verify track
;
; in:	ds -> grp
;	[dib_seg]:si -> dib record for logical drive
;	dl = drive number (e.g. 80, 81)
;	es:bx -> request header
;
; out:
;
;,fe
;=====================================================================
	assume	ds:grp,es:nothing,ss:nothing
hgvertrack proc near
	mov	[biosfun],4		; bios function 4 - verify
	les	bx,dword ptr [hdr]
	les	bx,es:[bx].giIOCTLData  ; generic i/o request packet
	cmp	[badlayout],0		; funny track layout?
	jz	hgve20			; if layout ok
	or	es:[bx].rwSpecFunc,3
hgve10:
	les	bx,dword ptr [hdr]
	mov	es:[bx].giStatus,0100h	; return "Done"
	ret
hgve20:
	test	es:[bx].rwSpecFunc,1	; just a status call?
	jz	hgve30			; if a "really do it" call
	mov	es:[bx].rwSpecFunc,1	; say layout ok
	jmp	hgve10			; exit routine

; the contents of giobuf are irrelevant, since verify ignores es:bx.

hgve30:
	jmp	hg_fmtentry		; do the i/o
hgvertrack endp

	subttl read_pbr - read the partition boot record sector
	page
;======================================================================
;,fs
; read_pbr - read the partition boot record sector
;
; in:	ds -> grp
;	[dib_seg]:si -> dib record for logical drive
;	dl = drive number (e.g. 80, 81)
;
; out:	nc if ok
;	cy if error, ax = i13 status
;
;,fe
;======================================================================
	assume	ds:grp,es:nothing,ss:nothing
read_pbr:
	push	bx
	push	cx
	push	dx
	push	es

; attempt to read partition boot sector

	mov	es,[dib_seg]
	mov	cx,es:[si].dibPBRcx
	mov	dx,es:[si].dibPBRdx
	mov	ax,0201h		; read 1 sector
	mov	bx,ds
	mov	es,bx
	mov	bx,offset grp:ourbuf
	mov	[typrtr],3		; 3 retries
rpr1:
	mov	ax,0201h		; read 1 sector
	int	13h
	jnc	rpr3			; if successfully read sector
	push	ax
	xor	ah,ah			; reset drive on timeout
	int	13h
	pop	ax
	test	ah,80h			; no retires if time out
	jnz	rpr2
	dec	[typrtr]		; through retries?
	jnz	rpr1			; no try to read one more sector
rpr2:
	stc
rpr3:
	pop	es
	pop	dx
	pop	cx
	pop	bx
	ret

	subttl hgetmedid - get media id
	page
;======================================================================
;,fs
; hgetmedid - get media id
;
; this routine processes the get media id call, i21f440ds66
;
; in:	ds -> grp
;	[dib_seg]:si -> dib record for logical drive
;	dl = drive number (e.g. 80, 81)
;	es:bx -> request header
;
; out:
;
;,fe
;======================================================================
	assume	ds:grp,es:nothing,ss:nothing
hgetmedid proc near
	push	ax
	push	bx
	push	cx
	push	si
	push	di
	push	ds
	push	es
	call	read_pbr
	jc	hgtmx
	les	di,dword ptr [hdr]
	les	di,es:[di].giIOCTLData
	mov	si,offset grp:ourbuf

; must be an extended partition

	cmp	[si].btBootSignature,29h
	jne	hgtmx

; xfer the info

	mov	ax,word ptr [si].btVolumeID
	mov	word ptr es:[di].midSerialNum,ax
	mov	ax,word ptr [si].btVolumeID+2
	mov	word ptr es:[di].midSerialNum+2,ax
	cld
	mov	cx,11
	push	si
	push	di
	lea	si,[si].btVolumeLabel
	lea	di,[di].midVolLabel
	rep	movsb
	pop	di
	pop	si
	mov	cx,8
	lea	si,[si].btFileSysType
	lea	di,[di].midFileSysType
	rep	movsb
	les	bx,dword ptr [hdr]
	mov	es:[bx].giStatus,0100h
	jmp	short hgtmz
hgtmx:
	les	bx,dword ptr [hdr]
	mov	es:[bx].giStatus,8103h
hgtmz:
	pop	es
	pop	ds
	pop	di
	pop	si
	pop	cx
	pop	bx
	pop	ax
	ret
hgetmedid endp

	subttl hsetmedid - get media id
	page
;======================================================================
;,fs
; hsetmedid - set media id
;
; this routine processes the set media id call, i21f440ds46
;
; in:	ds -> grp
;	[dib_seg]:si -> dib record for logical drive
;	dl = drive number (e.g. 80, 81)
;	es:bx -> request header
;
; out:
;
;,fe
;======================================================================
	assume	ds:grp,es:nothing,ss:nothing
hsetmedid proc near
	push	ax
	push	bx
	push	cx
	push	si
	push	di
	push	bp
	push	ds
	push	es
	mov	bp,si
	call	read_pbr
	ljc	hstmx
	mov	ax,ds
	lds	si,dword ptr [hdr]
	assume	ds:nothing
	lds	si,es:[si].giIOCTLData
	mov	es,ax
	mov	di,offset grp:ourbuf

; must be an extended partition

	cmp	es:[di].btBootSignature,29h
	jne	hstmx

; xfer the info

	mov	ax,word ptr [si].midSerialNum
	mov	word ptr es:[di].btVolumeID,ax
	mov	ax,word ptr [si].midSerialNum+2
	mov	word ptr es:[di].btVolumeID+2,ax
	cld
	mov	cx,11
	push	si
	push	di
	lea	di,[di].btVolumeLabel
	lea	si,[si].midVolLabel
	rep	movsb
	pop	di
	pop	si
	mov	cx,8
	lea	di,[di].btFileSysType
	lea	si,[si].midFileSysType
	rep	movsb

; write the modified buffer back to disk

	mgetscb ds
	assume	ds:grp
	mov	es,[dib_seg]
	mov	cx,es:[bp].dibPBRcx
	mov	dx,es:[bp].dibPBRdx
	mov	bx,ds
	mov	es,bx
	mov	bx,offset grp:ourbuf
	mov	[typrtr],3		; 3 retries
hsets10:
	mov	ax,0301h		; write 1 sector
	int	13h
	jnc	hsets40			; if successful
	push	ax
	xor	ah,ah			; reset drive on timeout
	int	13h
	pop	ax
	test	ah,80h			; no retires if time out
	jnz	hstmx
	dec	[typrtr]
	jnz	hsets10
	jmp	short hstmx
hsets40:
	les	bx,dword ptr [hdr]
	mov	es:[bx].giStatus,0100h
	jmp	short hstmz
hstmx:
	mgetscb ds
	assume	ds:grp
	les	bx,dword ptr [hdr]
	mov	es:[bx].giStatus,8103h
hstmz:
	pop	es
	pop	ds
	pop	bp
	pop	di
	pop	si
	pop	cx
	pop	bx
	pop	ax
	ret
hsetmedid endp

	subttl hioquery - ioctl query
	page
;======================================================================
;,fs
; hioquery - ioctl query
;
; in:	ds -> grp
;	[dib_seg]:si -> dib record for logical drive
;	dl = drive number (e.g. 80, 81)
;
; out:
;
;,fe
;=====================================================================
	assume	ds:grp,es:nothing,ss:nothing
hioquery proc near
	les	bx,dword ptr [hdr]
	mov	es:[bx].giStatus,8103h	; prep for 'unknown command'
	cmp	es:[bx].giCategory,8
	jne	hiqz
	mov	cl,es:[bx].giMinorCode	; minor function code
	cmp	cl,40h
	je	hiqx
	cmp	cl,41h
	je	hiqx
	cmp	cl,42h
	je	hiqx
	cmp	cl,46h
	je	hiqx
	cmp	cl,60h
	je	hiqx
	cmp	cl,61h
	je	hiqx
	cmp	cl,62h
	je	hiqx
	cmp	cl,66h
	je	hiqx
	cmp	cl,68h
	je	hiqx
	jmp	short hiqz
hiqx:
	mov	es:[bx].giStatus,0100h	; return 'Done'
hiqz:
	ret
hioquery endp

hendres label	byte

	subttl process_partition - fill out a dib block for a partition
	page
;======================================================================
;,fs
; process_partition - fill out a dib block for a partition
;
; in:	[dib_seg]:[dib_ptr] locates the dib block
;	bp:si points to the partition table entry
;	dl = the drive number
;	bx:cx = the starting sector adjustment factor
;	ds -> grp
;
; out:	nc if no error
;	cy if error
;
;,fe
;=====================================================================
	assume	ds:grp,es:nothing,ss:nothing
process_partition proc near
	pushset ax,bx,cx,dx,si,di,es
	push	bx
	push	cx

; get the heads and sectors per track values for the default bpb

	push	dx
	mov	ah,8
	int	13h			; get parameters for this drive
	mov	al,dh
	pop	dx
	xor	ah,ah			; make heads into word
	inc	ax			; # heads = max # + 1
	mov	[dftbpb.bsHeads],ax	; number of heads on the drive
	mov	al,cl
	xor	ah,ah			; make sectors/track a word
	and	ax,3fh			; mask sector number to 6 bits
	mov	[dftbpb.bsSecPerTrack],ax

; setup es:di to address the dib block

	mov	es,[dib_seg]
	mov	di,[dib_ptr]

; init offsets within the dib

	pop	cx
	pop	bx
	push	ds
	mov	ds,bp
	assume	ds:nothing
	mov	ax,word ptr [si].peStartSector
	add	ax,cx
	mov	es:[di].dibOffsetLo,ax
	mov	ax,word ptr [si].peStartSector+2
	adc	ax,bx
	mov	es:[di].dibOffsetHi,ax
	pop	ds
	assume	ds:grp

; prepare hidden sector count

	mov	es,bp
	mov	ax,word ptr es:[si].peStartSector
	mov	word ptr [dftbpb.bsHiddenSecs],ax
	mov	ax,word ptr es:[si].peStartSector+2
	mov	word ptr [dftbpb.bsHiddenSecs+2],ax

; prepare the default bpb with the sector count from the
; partition table value.

	mov	word ptr [dftbpb.bsHugeSectors],0
	mov	word ptr [dftbpb.bsHugeSectors+2],0
	mov	ax,word ptr es:[si].peSectors
	mov	[dftbpb.bsSectors],ax
	mov	[nslow],ax
	mov	cx,word ptr es:[si].peSectors+2
	mov	[nshigh],cx
	or	cx,cx
	jz	prp010
	mov	[dftbpb.bsSectors],0
	mov	word ptr [dftbpb.bsHugeSectors],ax
	mov	word ptr [dftbpb.bsHugeSectors+2],cx
prp010:

; read boot sector

	mov	cl,es:[si].peBeginSector
	mov	ch,es:[si].peBeginCylinder
	mov	dh,es:[si].peBeginHead

; record cx and dx for i21f44s0Ds46/66

	mov	es,[dib_seg]
	mov	es:[di].dibPBRcx,cx
	mov	es:[di].dibPBRdx,dx
	mov	ax,0201h		; read 1 sector
	mov	bx,ds
	mov	es,bx
	mov	bx,offset grp:ourbuf
	push	dx
	int	13h
	pop	dx
	ljc	prp070
	push	si

; determine if bpb is good.

	cmp	word ptr [bx+11],0200h	; 512 bytes per sector?
	jne	prp020			; no, use default bpb
	cmp	byte ptr [bx],0ebh	; start with short or long jumps
	je	prp030			; if good boot sector
	cmp	byte ptr [bx],0e9h
	je	prp030			; if good boot sector
prp020:
	mov	si,offset dftbpb	; if no good, use default bpb
	jmp	short prp055
prp030:
	mov	si,offset grp:ourbuf+11	; they're all in the boot sector

; test hidden count, if bad, --> prp020

	mov	ax,word ptr [dftbpb.bsHiddenSecs]
	cmp	ax,word ptr [si].bsHiddenSecs
	jne	prp020
	mov	ax,word ptr [dftbpb.bsHiddenSecs+2]
	cmp	ax,word ptr [si].bsHiddenSecs+2
	jne	prp020

; set the number of sectors from partition table

	cmp	[nshigh],0
	jnz	prp040
	mov	word ptr [si].bsHugeSectors,0
	mov	word ptr [si].bsHugeSectors+2,0
	mov	cx,[nslow]
	mov	[si].bsSectors,cx
	jmp	short prp050
prp040:
	mov	[si].bsSectors,0
	mov	cx,[nslow]
	mov	word ptr [si].bsHugeSectors,cx
	mov	cx,[nshigh]
	mov	word ptr [si].bsHugeSectors+2,cx
prp050:

; if a non-ext pbr/bpb, zero the high word of bsHiddenSecs 

	cmp	[si].bsBootSignature,29h
	je	prp055
	mov	word ptr [si].bsHiddenSecs+2,0
prp055:

; prepare the main bpb within the dib

	mov	es,[dib_seg]
	push	di			; save bpb pointer
	push	si			; and pointer to bpb
	mov	cx,dbpb_size
	cld
	rep	movsb
	pop	si
	pop	di

; prepare the default bpb within the dib

	push	di			; save bpb pointer
	lea	di,es:[di].dibdBytesPerSec  ; address of default bpb
	mov	cx,dbpb_size
	rep	movsb
	pop	di
	pop	si

; calculate cylinders on disk by formula
; cylinders = (total sectors / sectors per track) / # heads.

	push	dx
	mov	ax,[nslow]		; total sectors
	mov	dx,[nshigh]
	mov	cx,es:[di].dibSecPerTrack
	call	ldiv
	div	es:[di].dibHeads	; max tracks/heads = cylinders
	or	dx,dx			; remainder?
	jz	prp060			; if even division
	inc	ax			; if partial cylinder
prp060:
	mov	es:[di].dibCylsPerTrack,ax  ; total cylinders on disk

; calculate cylinder offset for generic i/o control.
; formula is (offset sectors / sectors per track) / # heads.

	mov	ax,es:[di].dibOffsetLo
	mov	dx,es:[di].dibOffsetHi
	mov	cx,es:[di].dibSecPerTrack
	call	ldiv
	div	es:[di].dibHeads
	mov	es:[di].dibCylsFBeg,ax	; store cylinder offset
	pop	dx
	mov	es:[di].dibRealDrive,dl	; remember real drive number
	or	es:[di].dibAttributes,loadbpb	; load bpb from disk
	clc
	jmp	short prp080
prp070:
	stc
prp080:
	popset ax,bx,cx,dx,si,di,es
	ret
process_partition endp

	subttl next_dib - advance to the next dib
	page
;======================================================================
;,fs
; next_dib - advance to the next dib
;
; if ([dib_cnt] + 1) == [dib_max] return cy
; inc [dib_cnt]
; dib_ptr += size dib
; return nc
;
; in:	[dib_cnt] = the current count (0 based)
;	[dib_max] = the max count (1 based)
;	[dib_ptr] = offset of current dib
;	ds -> grp
;
; out:	nc if no error
;	cy if error
;
;,fe
;=====================================================================
	assume	ds:grp,es:nothing,ss:nothing
next_dib proc near
	push	ax
	mov	al,[dib_cnt]
	inc	al
	cmp	al,[dib_max]
	je	ndcy
	inc	[dib_cnt]
	add	[dib_ptr],size dib
	clc
	jmp	short ncx
ndcy:
	stc
ncx:
	pop	ax
	ret
next_dib endp

	subttl hinitblk - init hard disk driver
	page
;======================================================================
;,fs
; hinitblk - init hard disk driver
;
; this routine will initialize the fixed-disk device driver.
;
; it looks through the partition table on each physical disk.
; it assigns a dib block & a unit number to each partition found
; on each physical drive.  dib blocks are allocated out of the smp.
;
; the drive letter assignment order is as follows:
;  the primary partition on drive 0
;  the primary partition on drive 1 (if there is a second hard drive)
;  any extended partitions on drive 0
;  any extended partitions on drive 1
;  any secondary partitions on drive 0
;  any secondary partitions on drive 1
;
; the old MLG partition type is no longer recognized by this driver.
; it has been replaced by the DLG type.
;
; the initial bpb for each fixed disk contains either a) the
; contents of the boot sector bpb, if that is determined to be
; ok, or b) a bare-bones bpb which contains the correct number
; of heads, sectors per track, and total number of sectors.
;
; in:	ds -> grp
;	[dib_seg]:si -> dib record for logical drive
;	dl = drive number (e.g. 80, 81)
;
; out:	data in request header filled out
;
;,fe
;=====================================================================
	assume	ds:grp,es:nothing,ss:nothing
hinitblk proc near
	pushset ax,bx,cx,dx,si,di,bp,ds,es
	mov	[dib_cnt],-1		; init 0 based counter for 0 drives

; allocate stack block for two partition tables (two tables of
; four entries each at 16 bytes per entry).

	sub	sp,2*4*16
	mov	[pt0],sp		; pointer to drive 0's table
	mov	[pt1],sp		; pointer to drive 1's table
	add	[pt1],4*16

; see how many physical hard drives exist

	mov	ah,8
	mov	dl,80h
	int	13h			; get drive parameters
	cmp	dl,0
	lje	init290
	cmp	dl,2			; limit to 2
	jna	init010
	mov	dl,2
init010:
	mov	[drives],dl

; allocate smp buffer for 24 dib blocks (or as many as possible).
; 24 is the max number of hard drives that can be lettered
; (c: through z:).  this allocation will be shrunk back later to
; only what is actually needed.

	mov	[dib_max],dib_total
	mov	dx,(16 + dib_overhead + (size dib * dib_total) + 15) / 16
	xor	ah,ah
	call	mosheman
	or	al,al
	jz	init020

; insufficient smp available to accomodate 24 dib blocks -- calc max
; amount possible and hope that will be enough as the partitions are
; processed.

	shl	dx,1			; convert paras to bytes
	shl	dx,1
	shl	dx,1
	shl	dx,1
	mov	ax,dx

; regarding the dib_overhead, sticking with 24 array elements
; for simplicity.  easier to find the first dib block.

	sub	ax,dib_overhead
	mov	bl,size dib		; how many dibs in that many bytes?
	div	bl
	or	al,al
	ljz	init290			; hopefully > 0 dibs will fit
	mov	[dib_max],al
	mul	bl			; max number * bytes each = total bytes
	add	ax,dib_overhead+16
	add	ax,15			; convert to paras
	shr	ax,1
	shr	ax,1
	shr	ax,1
	shr	ax,1
	mov	dx,ax
	xor	ah,ah
	call	mosheman
	or	al,al
	ljnz	init290			; shouldn't happen
init020:
	mov	[dib_seg],es		; es -> the block's mosheman header

; initialize the 'other' fields within the dib

	mov	di,16+dib_overhead
	mov	cl,[dib_max]
	xor	ch,ch
init023:
	mov	es:[di].dibOffsetLo,0
	mov	es:[di].dibOffsetHi,0
	mov	es:[di].dibCylsPerTrack,0
	mov	es:[di].dibCylsFBeg,0
	mov	es:[di].dibAttributes,0
	mov	es:[di].dibRealDrive,0
	add	di,size dib
	loop	init023

; init the bpb array

	mov	di,16
	mov	ax,16+dib_overhead
	mov	cx,dib_total
	cld
init030:
	stosw
	add	ax,size dib
	loop	init030

; reset drive 0 and then
; read the first sector of drive 0 (h0, s1, c0, the first mbr)

	mov	ax,0401h		; verify to position to cylinder 0
	mov	cx,0001h		; c0, s1
	mov	dx,0080h		; h0, drive 80
	int	13h
	mov	ah,0			; reset
	mov	dl,80h			; drive 80
	int	13h
	mov	ax,0201h		; read 1 sector
	mov	bx,ds
	mov	es,bx
	mov	bx,offset grp:ourbuf
	mov	cx,0001h		; c0, s1
	mov	dx,0080h		; h0, drive 80
	int	13h
	ljc	init290

; validate the sector's signature and partition table

	cmp	word ptr [ourbuf+01feh],0aa55h
	ljne	init290
	mov	si,offset grp:ourbuf+1beh
	cmp	[si].peBootable,80h
	je	init040
	cmp	[si].peBootable,0
	ljne	init290
init040:
	cmp	[si].peFileSystem,PTCsm12
	je	init050
	cmp	[si].peFileSystem,PTCsm16
	je	init050
	cmp	[si].peFileSystem,PTCdlg
	ljne	init290

; copy the partition table into the first stack block

init050:
	mov	ax,ss
	mov	es,ax
	mov	di,[pt0]
	mov	cx,4*16/2
	cld
	rep	movsw

; if a second drive exists, reset it and then
; read the first sector of drive 1 (h0, s1, c0, the second mbr)

	cmp	[drives],2
	jne	init090
	mov	ax,0401h		; verify to position to cylinder 0
	mov	cx,0001h		; c0, s1
	mov	dx,0081h		; h0, drive 81
	int	13h
	mov	ah,0			; reset
	mov	dl,81h			; drive 81
	int	13h
	mov	ax,0201h		; read 1 sector
	mov	bx,ds
	mov	es,bx
	mov	bx,offset grp:ourbuf
	mov	cx,0001h		; c0, s1
	mov	dx,0081h		; h0, drive 81
	int	13h
	jc	init070

; validate the sector's signature and partition table

	cmp	word ptr [ourbuf+01feh],0aa55h
	jne	init070
	mov	si,offset grp:ourbuf+1beh
	cmp	[si].peBootable,80h
	je	init060
	cmp	[si].peBootable,0
	jne	init070
init060:
	cmp	[si].peFileSystem,PTCsm12
	je	init080
	cmp	[si].peFileSystem,PTCsm16
	je	init080
	cmp	[si].peFileSystem,PTCdlg
	je	init080
init070:
	mov	[drives],1
	jmp	init090

; copy the partition table into the second stack block

init080:
	mov	ax,ss
	mov	es,ax
	mov	di,[pt1]
	mov	cx,4*16/2
	cld
	rep	movsw

; process the primary parititon of drive 0

init090:
	mov	[dib_cnt],0		; 0 based counter

; to start writing dib blocks, must skip past the mosheman header
; and the dib_overhead for the bpb pointer array

	mov	[dib_ptr],16+dib_overhead
	mov	si,[pt0]
	mov	bp,ss
	mov	dl,80h
	xor	bx,bx
	xor	cx,cx
	call	process_partition
	ljc	init290

; if a second drive exists,
; process the primary parititon of drive 1

	cmp	[drives],2
	jne	init100
	call	next_dib
	ljc	init250
	mov	si,[pt1]
	mov	bp,ss
	mov	dl,81h
	xor	bx,bx
	xor	cx,cx
	call	process_partition
	ljc	init260

; process any extended partitions on drive 0

init100:
	mov	dl,80h
	mov	si,[pt0]
init110:
	xor	di,di			; init di as a flag
	mov	cx,3
init120:
	add	si,16			; start looking at pte 1
	cmp	ss:[si].peFileSystem,PTCext
	jne	init130
	mov	di,si
	jmp	short init140
init130:
	loop	init120
init140:
	or	di,di			; was an extended partition found?
	ljz	init190

; prepare to track the actual starting sector for each extended partition

	mov	ax,word ptr ss:[di].peStartSector
	mov	word ptr [strtsec],ax
	mov	ax,word ptr ss:[di].peStartSector+2
	mov	word ptr [strtsec+2],ax

; read the next partition table

	mov	cl,ss:[di].peBeginSector
	mov	ch,ss:[di].peBeginCylinder
	mov	dh,ss:[di].peBeginHead
init150:
	mov	ax,0201h		; read 1 sector
	mov	bx,ds
	mov	es,bx
	mov	bx,offset grp:ourbuf
	push	dx
	int	13h
	pop	dx
	ljc	init260

; make ds:si -> the 1st partition table entry within ourbuf and
; ds:di -> the 2nd partition table entry within ourbuf

	mov	si,offset grp:ourbuf+1beh
	mov	di,offset grp:ourbuf+1beh+10h

; must save the data from the second table entry on the stack
; since ourbuf must be reused.

	mov	al,[di].peFileSystem
	mov	cl,[di].peBeginSector
	mov	ch,[di].peBeginCylinder
	mov	dh,[di].peBeginHead	; (dl is still the drive number)
	push	ax
	push	cx
	push	dx

; make sure the extended node points to a 'live' partition
; before calling process_partition

	cmp	[si].peFileSystem,PTCnil
	je	init160
	call	next_dib
	jc	init170

; for extended partitions, a starting sector adjustment factor must
; be given to process_partition in the bx:cx registers.

	mov	cx,word ptr [strtsec]
	mov	bx,word ptr [strtsec+2]

; now, just in case there is another extended partition after this one,
; the adjustment factor must be stepped up by the total number of
; sectors for the current partition.

	mov	ax,word ptr [si].peSectors
	add	word ptr [strtsec],ax
	mov	ax,word ptr [si].peSectors+2
	adc	word ptr [strtsec+2],ax
	mov	ax,word ptr [si].peStartSector
	add	word ptr [strtsec],ax
	mov	ax,word ptr [si].peStartSector+2
	adc	word ptr [strtsec+2],ax

; process the extended partition

	mov	bp,ds
	call	process_partition
	jc	init180

; is there another extended partition table to deal with?

init160:
	pop	dx			; recover head, cyld, sect
	pop	cx			; and ptc data from stack
	pop	ax
	cmp	al,PTCext
	je	init150
	jmp	short init190
init170:
	add	sp,6
	jmp	init250
init180:
	add	sp,6
	jmp	init260

; if a second drive exists, recycle through the above logic to
; process any extended partitions on drive 1

init190:
	cmp	dl,81h			; already been here?
	je	init200
	cmp	[drives],2
	jne	init200
	mov	si,[pt1]
	mov	dl,81h
	jmp	init110

; process any secondary partitions on drive 0

init200:
	mov	dl,80h
	mov	si,[pt0]
init210:
	mov	cx,3
init220:
	add	si,16
	cmp	ss:[si].peFileSystem,PTCsm12
	je	init230
	cmp	ss:[si].peFileSystem,PTCsm16
	je	init230
	cmp	ss:[si].peFileSystem,PTCdlg
	jne	init240
init230:
	call	next_dib
	jc	init250
	push	cx

; if processing a secondary partition on the first drive, update the
; trueboot array.

	cmp	dl,80h
	jne	init235
	mov	bp,3
	sub	bp,cx
	mov	bx,offset trueboot
	add	bx,bp
	mov	cl,[dib_cnt]
	add	cl,2
	mov	[bx],cl
init235:
	mov	bp,ss
	xor	bx,bx
	xor	cx,cx
	call	process_partition
	pop	cx
	jc	init260
init240:
	loop	init220

; if a second drive exists, recycle through the above logic to
; process any secondary partitions on drive 1

	cmp	dl,81h			; already been here?
	je	init270
	cmp	[drives],2
	jne	init270
	mov	si,[pt1]
	mov	dl,81h
	jmp	short init210

; error handler - for when there are more drives than smp

init250:
	mov	dx,offset emsg1
	mov	ah,9
	int	21h
	jmp	short init270

; error handler - for when a disk error occurs

init260:
	mov	dx,offset emsg2
	mov	ah,9
	int	21h
	jmp	short init270

; shrink back the smp allocation for the dib record to what is
; actually needed.

init270:
	mov	al,[dib_cnt]
	inc	al
	cmp	al,[dib_max]
	je	init280
	mov	bl,size dib
	mul	bl			; make ax = total bytes
	add	ax,dib_overhead
	add	ax,15
	shr	ax,1			; convert to paras
	shr	ax,1
	shr	ax,1
	shr	ax,1
	mov	dx,ax
	inc	dx			; quirk of shrink, must account
	mov	es,[dib_seg]		; for the header's paragraph
	mov	ah,2
	call	mosheman
	or	al,al
	jnz	init290

; set up return to caller
; (deallocate partition table stack block)

init280:
	add	sp,2*4*16
	les	bx,dword ptr [hdr]

; report # of units

	mov	al,[dib_cnt]
	inc	al
	mov	es:[bx].irUnits,al

; report ending address

	lea	dx,hendres
	mov	word ptr es:[bx].irEndAddress,dx
	mov	word ptr es:[bx+2].irEndAddress,cs

; init pointer to bpb pointer array

	mov	word ptr es:[bx].irParamAddress,16
	mov	ax,[dib_seg]
	mov	word ptr es:[bx+2].irParamAddress,ax

; set ok status

	mov	ax,0100h
	jmp	short init300

; error processing
; (deallocate partition table stack block)

init290:
	add	sp,2*4*16
	les	bx,dword ptr [hdr]
	mov	es:[bx].irUnits,0	; set no units inited
	mov	ax,810bh		; report read fault error
init300:
	mov	es:[bx].irStatus,ax	; set return status
	popset	ax,bx,cx,dx,si,di,bp,ds,es
	ret
hinitblk endp

	subttl ldiv - perform long division
	page
;======================================================================
;,fs
; ldiv - perform long division
;
; in:	dx:ax contains double word dividend
;	cx contains divisor
;
; out:	dx:ax contains double word quotient of dx:ax / cx
;	bx contains remainder
;
;,fe
;=====================================================================
	assume	ds:nothing,es:nothing,ss:nothing
ldiv proc
	mov	bx,ax			; save low word of dividend
	mov	ax,dx
	xor	dx,dx			; divide 0:high word by cx
	div	cx
	xchg	bx,ax			; high quotient for low of dividend
	div	cx			; divide remainder:ax by cx
	xchg	bx,dx			; return remainder in bx, and
	ret				; restore high word of quotient
ldiv endp

	even

mosseg	ends
	end

