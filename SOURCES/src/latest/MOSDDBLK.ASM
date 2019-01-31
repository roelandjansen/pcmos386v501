	include page.inc
	title	mosddblk - mos device driver for drive i/o
comment ^==============================================================
		development specification

 program name:	mos.com			assigned to: david a. morrow
 module name:	mosddblk		assign date: 04/24/86
 entry points:	blkintr, blkstrat	completed: 02/14/87
 entry from:	todriver
 entry method:	far call
 calls:	n/a
 purpose:	mos block device driver (diskette and fixed disk)
 refer to:	n/a
 last update:	08/18/1992
========================================================================

jsm 12/22/86	support 1.2 meg floppies in 1.2 meg drives

jsm 02/14/87	change a/b drive support

jsm 03/09/87	fix problems in getparms & setparms w/diskcopy

jsm 05/06/87	add new disk type, dtold, for 360k drives on pc's with
		pre-at rom bios's.  Change all tests for 360K vs. 1.2M
		drives from comparisons with dtnochg (at 360k drive) to
		comparisons with dtchg (at 1.2m drive), so dtold &
		dtnochg will be treated almost equivalently.  only
		difference is that format track call won't set disk
		type for dtold drives, but will set it for dtnochg.

rbr 07/08/87	did away with disk types: dtold, dtchg, dtnochg, etc.
		substituted 3 new flags: dtsmall indicates 3.5" drive,
		dthicap indicates 1.2m or 1.44m format, and dtchgln
		indicates if there is a change line available. tables
		and code were added/changed as necessary to support
		the 3.5" formats. For an AT or PS/2 class machine,
		we check cmos for diskette types because bios calls
		can't always tell us if there's a 1.44m drive. for
		the model 30, 720k drives are assumed. did away with
		the "isat" flag, and added "dprmptr" to point to the
		default diskette parameter table for the system.

rbr 07/11/87	removed some redundant code.

rbr 07/13/87	fixed a neg that should have been a not. my error.

rbr 07/18/87	fixed inability to write to 1.44m diskettes.

sah 01/20/88	change scbseg and zero seg to mgetxxxx macros

rbr 02/07/88	fixed problem with incorrect disk parms when formatting
		the toshiba t3100 3.5" diskette drive.

sah 02/21/88	rbr/sah move ddt code to mo2 group.

rbr 03/13/88	see comment near beginning of "isdrive" proc.

mjs 4/11/88	added tests to skip retries if a disk operation fails
		due to a time out error.  this is to speed up the
		response in the case where the drive door is open
		(e.g. zenith/navy - took minutes to get a crit err).
		made similar mods to mosfutil.asm.

jrb 05/02/88	get/set logical drive corrections.  add word of 0 in
		dib so hidden is a correct dd

jrb 06/03/88	changed sense of ibm bit - current dos drivers
		(including us) are not ibm devices - that is, they
		don't require the first fat sector on a build bpb call

sah 08/26/88	made corrections in handling of change line so that if
		bios returns that disk line has change that we actually
		return that it did change.   ptr 120
sah 09/09/88	corrected problems with format with above addition

rkg 10/17/88	problems with format tracked to wrong error code
		returned from int 13.  expanded table and merged hard
		and floppy code.

rkg 12/01/88	problems with secondary 360s and 3.5" drives caused
		by inappropriate diskette parameter table.  format now
		uses the parm table returned by int 13, func 18 and
		initialization code creates a compatible table for all
		diskettes.

rkg 12/05/88	spurious problems caused by not reseting drives after
		timeouts.  changed mjs 4/11/88 to reset before return

rkg 12/07/88	problems with zenith corrected by format sequence
		changes.

rkg 12/09/88	problems with toshiba corrected.  int 13 function 17
		may not be present but must always set sectors/track
		in the disk parms.  also reverted to executing funct 17
		then 18 for zenith disk change line

rkg 12/12/88	change handling of func 17 and 18 for the last time

bwr 11/28/89	marked messages for foreign language translation.

bwr 03/01/90	minor bug fix for toshiba 5200 high density floppy
		drive.

mjs 12/16/91	dlg mods: added support for i21f44s0ds0846,
		i21f44s0ds0866 and i21f44s11.  converted to use of 
		structures within dskstruc.inc.

================ 5.01 Kernel Ends Here ====================================

mjs 08/18/92	clean up segment declarations

======================================================================^

.xlist
	include mosddblk.pub
	include mosregs.inc
	include group.inc
	include dskstruc.inc
	include macros.inc
.list

irq	segment
	dw	1eh*4			; diskette parm pointer
	dd	?			; old pointer saved here (although not needed)
	dw	0			; do not save any application changes
	dw	grp:diskprm		; point vector to our disk parms
	dw	0			; no second level
irq	ends

	page
gdata	segment

	extrn	media13:byte

	public	diskprm

; bits in the attribute byte in the dib block

dtsmall		equ	01h	; set if 3.5" drive, 0 means 5.25" drive
dthicap		equ	02h	; set if high capacity drive (1.2m or 1.44m)
dtchgln		equ	04h	; set if change line is available
loadbpb		equ	08h	; set if bpb should be loaded from media
bpberr		equ	10h	; set if error loading bpb from media
dirtybpb	equ	20h	; set when we have to load bpb from disk
diskswap	equ	40h	; set if we just did a disk swap
firstbpb	equ	80h	; set first time bpb is loaded

; command subcodes for generic i/o control

setparms	equ	040h	; set device parameters
getparms	equ	060h	; get device parameters
wrttrack	equ	041h	; write track on logical device
rdtrack		equ	061h	; read track on logical device
fvtrack		equ	042h	; format and verify track on logical device
vertrack	equ	062h	; verify track on logical device
setmedid	equ	046h	; set media id
getmedid	equ	066h	; get media id

lblsiz		equ	11	; size of mos volume label

;==== device information block

dbpb_size	equ	25	; bytes for 1 bpb section of the dib

dib struc

; real bpb for unit

dibBytesPerSec	dw	512	; bytes per sector
dibSecPerClust	db	1	; sectors per cluster
dibResSectors	dw	1	; # of reserved sectors
dibFATs		db	2	; # of FAT tables
dibRootDirEnts	dw	224	; # of root directory entries
dibSectors	dw	2400	; total # of sectors
dibMedia	db	0f9h	; media descriptor
dibFATsecs	dw	7	; # of sectors per FAT
dibSecPerTrack	dw	15	; # of sectors per track
dibHeads	dw	2	; # of heads
dibHiddenSecs	dd	0	; # of hidden sectors
dibHugeSectors	dd	0	; # of sectors when dibSectors == 0

; default bpb for unit

dibdBytesPerSec dw	512	; bytes per sector
dibdSecPerClust db	1	; sectors per cluster
dibdResSectors	dw	1	; # of reserved sectors
dibdFATs	db	2	; # of FAT tables
dibdRootDirEnts dw	224	; # of root directory entries
dibdSectors	dw	2400	; total # of sectors
dibdMedia	db	0f9h	; media descriptor
dibdFATsecs	dw	7	; # of sectors per FAT
dibdSecPerTrack dw	15	; # of sectors per track
dibdHeads	dw	2	; # of heads
dibdHiddenSecs	dd	0	; # of hidden sectors
dibdHugeSectors dd	0	; # of sectors when dibdSectors == 0

; other dib data

dibHeadMask 	dw	1	; head mask
dibSectsPerCyl	dw	30	; sectors/cylinder (30 for 1.2 meg floppy)
dibTimerLo 	dw	0	; last holding timer value
dibTimerHi 	dw	0	; "	"	"
dibLabel	db	12 dup (0) ; disk label
dibAttributes	db	0	; drive attributes
dibRealDrive	db	0	; drive number this drive really should be
dibLastDriveNum	db	0	; last drive number used for this drive
dibRealDIB	dw	0	; pointer to real dib for this drive
dib ends

;==== bpb data area

bpbpntr dw	bpb1		; for 1st unit
	dw	bpb2		; for 2nd unit

bpb1	dib	<>		; use default values
bpb2	dib	<>

fatarr	db	0f9h, 0fch, 0fdh, 0feh, 0ffh
falen	equ	$ - fatarr

bpbarr	label	byte

bpb12	bpb	<512,1,1,2,224,2400,0f9h,7,15,2,0,0>  ; first 5 match fatarr
bpb180	bpb	<512,1,1,2,112, 360,0fch,2, 9,1,0,0>
bpb360	bpb	<512,2,1,2,112, 720,0fdh,2, 9,2,0,0>
bpb160	bpb	<512,1,1,2, 64, 320,0feh,1, 8,1,0,0>
bpb320	bpb	<512,2,1,2,112, 640,0ffh,1, 8,2,0,0>

bpb720	bpb	<512,2,1,2,112,1440,0f9h,3, 9,2,0,0>  ; 3.5" BPB's
bpb14	bpb	<512,1,1,2,224,2880,0f0h,9,18,2,0,0>

;==== track layout table

	even

badlayout	dw	0		; non-zero if funny track layout

tracktable	label word
	dw	15			; 15 entries in the default table
	dw	1
sec1size dw	512			; sector 1, 512 bytes long
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

; extra space for funny user tables

	dw	16,512
	dw	17,512
	dw	18,512
	dw	19,512
	dw	20,512

maxtrktbl equ (($ - tracktable) / 4)

formattable	label	byte
	db	(maxtrktbl * 4) dup (?) ; table for format call

;==== miscellaneous data
	even
hdr		dw	0,0	; header pointer
drvnum		db	0	; disk drive to use 0 or 1
biosfun		db	0	; temp holding for next disk function
dircnt		dw	?	; max directory entries in root dir
maxdrv		db	-1	; maximum drive number in use (-1 means none)
typrtr		db	3	; retry count for drive type
sectcnt		dw	0	; total count of sectors for read or write
sectstr		dw	0	; starting sector for next disk i/o in loop
giobuf		dd	0	; buffer pointer for doint generic i/o
fghead		db	0	; head for generic read/write/format/verify
fgtrack		db	0	; track for generic read/write/format/verify
startd		db	0	; starting absolute drive number (1=a)
t3100		db	'N'	; y if toshiba t3100

;==== rom bios disk parameter block

diskparm struc
dpsb1		db	0dfh	; specify byte 1 (step-rate time, head-unload)
dpsb2		db	002h	; specify byte 2 (head-load time, dma mode)
dpmwait 	db	025h	; wait time until motor turned off
dpbps		db	002h	; bytes per sector (2==512)
dpeot		db	00fh	; last sector number in a track
dprwgap 	db	01bh	; gap length between sectors for read/write
dpdatln 	db	0ffh	; data length if no sector length
dpfmgap 	db	054h	; gap length between sectors for formatting
dpfmval 	db	0f6h	; data value stored in formatted sectors
dphdstl 	db	001h	; head settle time
dpmstrt 	db	008h	; motor start-up time
		db	0	; spare for alignment
diskparm ends


;==== disk parameter blocks

; int 1e points to diskprm

int1e		equ	(1eh * 4)
	even

diskprm diskparm <0dfh, 2, 25h, 2, 15, 1bh, 0ffh, 50h, 0f6h, 15, 2>
atdprm	diskparm <0dfh, 2, 25h, 2, 15, 1bh, 0ffh, 54h, 0f6h, 2,	 8>
pcdprm	diskparm <0dfh, 2, 25h, 2,  9, 2ah, 0ffh, 50h, 0f6h, 15, 2>
psdprm	diskparm <0afh, 2, 25h, 2, 18, 1bh, 0ffh, 6ch, 0f6h, 15, 4>

	even
ftypes		db	1,1	;  disk type codes drives a and b

;==== pointer to buffer for bpb read

	even
secbuf		dw	2 dup (?)  ; pointer to buffer for reading in disk info
lblbuf		db	12 dup (?) ; buffer for disk label

;==== prompt for disk swap message

switchmsg db	0ah, 0dh, 0ah, 0dh, "   Put in diskette for disk drive  "  ;@@xlat
drvn	db	"A and press any key     ", 0ah, 0dh, 0ah, 0dh, 0  ;@@xlat


;==== function table

	even
ffuntbl dw	finitblk	; 0  init
	dw	fmedck		; 1  media check
	dw	fbldbpb		; 2  build bpb
	dw	0		; 3  i/o control input
	dw	finput		; 4  input (read)
	dw	0		; 5  nondestructive input no wait
	dw	0		; 6  input status
	dw	0		; 7  input flush
	dw	foutput		; 8  output (write)
	dw	foutput		; 9  output with verify
	dw	0		; 10 output status
	dw	0		; 11 output flush
	dw	0		; 12 i/o control output
	dw	fdevopen	; 13 device open
	dw	fdevclose	; 14 device close
	dw	fremove		; 15 removable media
	dw	0		; 16 illegal
	dw	0		; 17 illegal
	dw	0		; 18 illegal
	dw	fgenioctl	; 19 generic ioctl
	dw	0		; 20 illegal
	dw	0		; 21 illegal
	dw	0		; 22 illegal
	dw	fgetlog		; 23 get logical device
	dw	fsetlog		; 24 set logical device
	dw	fioquery	; 25 query ioctl

fmax_func equ (($-ffuntbl)/2)-1

gdata	ends

;======================================================== mos segment
if 0 eq 0
segment_num = 1
endif
mosseg	segment
	assume	cs:mos,ds:nothing,es:nothing,ss:nothing

	extrn mosheman:near, sbios:word
	extrn bugerror:near

;==== device header

	public	scbstdblk
scbstdblk label byte
	dd	-1

; block, non-fat-id, removeable,
; get/set logical & generic ioctl
; (and why bit 0?)

	dw	0010100001000001b
	dw	mos:blkstrat
	dw	mos:blkintr
	db	8 dup (0)		; # devices passed at init

	subttl blkstrat - block strategy routine
	page
;======================================================================
;,fs
; blkstrat - block strategy routine
;
; this routine is the block drivers strategy routine, it just
; queues the dword pointer to the request header.
;
; in:	es:bx -> request header
;
; out:	the request header pointer is saved.
;
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:nothing
blkstrat proc far
	push	ds
	mgetscb ds
	assume	ds:grp
	mov	[hdr],bx
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
; this is the block device drivers interrupt routine which will
; process mos's requested function.
;
; in:
;
; out:
;
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:nothing
blkintr proc far
	pushf
	push	ax
	push	bx
	push	cx
	push	dx
	push	si
	push	di
	push	es
	push	ds
	mgetscb ds
	assume	ds:grp
	les	bx,dword ptr [hdr]
	mov	al,es:[bx].rhUnit	; get unit code
	mov	[drvnum],al		; set disk to use
	cmp	al,[maxdrv]		; good unit code?
	ja	err2			; if unit code bad
	xor	ah,ah
	shl	ax,1			; convert unit code to table offset
	mov	si,ax
	mov	si,[si].bpbpntr		; pointer to dib structure
	mov	bl,es:[bx].rhFunction	; get command code
	cmp	bl,fmax_func		; check for invalid call
	ja	ferr1			; if bad command code
	mov	dl,[drvnum]		; keep drive number in dl
	xor	bh,bh
	shl	bx,1
	mov	bx,[bx+ffuntbl]		; get address of appropriate routine
	or	bx,bx			; legal code?
	jz	ferr1			; if illegal code
	call	bx			; call the function
frexit:
	pop	ds
	pop	es
	pop	di
	pop	si
	pop	dx
	pop	cx
	pop	bx
	pop	ax
	popf
	ret
ferr1:
	les	bx,dword ptr [hdr]
	mov	es:[bx].rhStatus,8103h	; return 'Unknown Command'
	jmp	frexit
err2:
	les	bx,dword ptr [hdr]
	mov	es:[bx].rhStatus,8101h	; return 'Unknown Unit'
	jmp	frexit
blkintr endp

	subttl logtrans - do logical drive reassignment
	page
;======================================================================
;,fs
; logtrans - do logical drive reassignment
;
; this routine checks for drive redirection.  if the dibRealDrive field
; in the dib is non-zero, moves the new drive number into dl.
; it decrements the number to produce the real drive number,
; puts the real drive number in drvnum, and points si to the real
; dib structure.
;
; if the unit is directed to a "different" drive, calls the
; rom bios to print a switch disk message, then waits for a key
; to be pressed.	loads a new bpb if the command code was neither
; media check nor build bpb.
;
; in:	ax == unit # * 2
;	bx == address of subfunction code
;	dl == drive number given to driver by caller
;	si -> dib for drive
;	ds -> grp
;
; out:	return values are set in the request header
;
;,fe
;======================================================================
	assume	ds:grp,es:nothing,ss:nothing
logtrans proc near
	mov	ah,[si].dibRealDrive	; check for redirection
	or	ah,ah			; is it redirected?
	jnz	log10			; if redirected
	ret				; if not redirected

; translate input drive number into real drive number

log10:
	mov	dl,ah
	dec	dl			; 1 means drive 0, 2 means drive 1, etc.
	mov	[drvnum],dl		; dl has real drive number
	mov	si,[si].dibRealDIB	; get real dib pointer
	shr	al,1			; get original unit number back
	cmp	al,[si].dibLastDriveNum
	jne	log20			; if using different drive number
	ret

; prompt user to put right disk in drive

log20:
	mov	[si].dibLastDriveNum,al	; set new "current" drive
	or	[si].dibAttributes,diskswap ; make sure we load a new bpb
	mov	ah,[drvn]
	and	ah,0f0h			; change drive number for message
	add	ah,al			; to the one in al
	inc	ah			; add 1 for 0/1 bias
	mov	[drvn],ah		; new drive number for message
	mov	ax,offset switchmsg
	call	prtstr			; print the switch message
	xor	ax,ax			; zero ah
	int	16h			; wait for the key press
					; don't return until one found
	cmp	bx,offset fbldbpb	; is this media check or bldbpb?
	jbe	log30			; if no reason for settype call
	call	settype			; get the disk type
log30:
	ret
logtrans endp

	subttl prtstr -- print string on user's console
	page
;======================================================================
;,fs
; prtstr -- print string on user's console
;
; print a string on user's console.  Uses ROM BIOS call 0eh to print
; the string one character at a time.  the string must be terminated
; by a null (0) byte.  the character will be printed white on a black
; background on color systems, normal attributes on monochrome.
;
; in:	ds:ax points to the string to print.
;	ds -> grp
;
; out:	string printed
;
;,fe
;======================================================================
	assume	ds:grp,es:nothing,ss:nothing
prtstr proc near
	push	ax
	push	bx
	push	si
	cld
	mov	si,ax
	mov	bl,07h			; white foreground, black background
prt10:
	lodsb
	or	al,al			; last character?
	jz	prt20			; if end of string
	mov	ah,0eh			; function 0eh, write tty to current page
	int	010h			; write the character
	jmp	prt10			; do it again
prt20:
	pop	si
	pop	bx
	pop	ax
	ret
prtstr endp

	subttl medck - media check
	page
;======================================================================
;,fs
; medck - media check
;
; this routine processes the media check call (=1)
;
; in:
;	ds -> grp
;
; out:
;
;,fe
;======================================================================
	assume	ds:grp,es:nothing,ss:nothing
fmedck proc near
	call	logtrans		; do drive reassignment
	les	bx,dword ptr [hdr]
	test	[si].dibAttributes,dirtybpb
	jnz	med20			; if we must load new bpb
	test	[si].dibAttributes,diskswap
	jnz	med35			; if we should return "maybe"
	call	timetest		; return al = 0 or 1
	les	bx,dword ptr [hdr]
	or	al,al			; disk change?
	jnz	med40			; if < 2 seconds after success
	test	[si].dibAttributes,dtchgln ; change line available?
	jz	med40			; no, jump
	mov	ah,16h
	mov	dl,[drvnum]		; get drive number back
	int	13h			; ask bios about change line
	cmp	ah,0
	jz	med05			; if change line in-active
	push	bx
	mov	bl,[drvnum]
	xor	bh,bh
	mov	byte ptr [media13+bx],'N'
	pop	bx
	jmp	med10
med05:
	mov	al,1			; return "no change"
	push	bx
	mov	bl,[drvnum]
	xor	bh,bh
	cmp	byte ptr [media13+bx],'Y'  ; test to see if int 13 detect
	jne	med06
	mov	al,0			; return "maybe"
	mov	byte ptr [media13+bx],'N'  ; reset int 13 detection
med06:
	pop	bx
	jmp	short med40		; exit
med10:
	mov	ah,es:[bx].mrMediaID	; old media descriptor
	cmp	ah,[si].dibMedia		; same as current one?
	je	med30			; if still same
med20:
	lea	ax,[si].dibLabel
	mov	word ptr es:[bx].mrVolumeID,ax  ; offset of volume id expected
	mov	word ptr es:[bx+2].mrVolumeID,ds
	mov	al,-1			; we think media changed
	jmp	short med40		; return "changed"
med30:
	mov	di,offset grp:lblbuf
	call	getlabel		; get current label
	jnc	med32			; if no error
	push	di			; balance stack
	jmp	fdskerr			; return error code
med32:
	push	si
	push	es
	push	ds
	pop	es
	lea	si,[si].dibLabel	; old label address
	mov	cx,lblsiz
repe	cmpsb				; look for match
	pop	es
	pop	si
	jnz	med20			; if different labels
med35:
	mov	al,0			; if same labels, not sure
med40:
	and	[si].dibAttributes,not (dirtybpb or diskswap)

; taken care of dirty bpb & disk swap

	mov	es:[bx].mrReturn,al	; 1=not changed, 0=not sure
	mov	es:[bx].mrStatus,0100h	; return with 'DONE'
	ret
fmedck endp

	subttl timeset - record 0040:006c
	page
;======================================================================
;,fs
; timeset - record 0040:006c
;
; in:
;
; out:
;
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:nothing
timeset proc near
	push	es
	push	ax
	mov	ax,0040h		; access bios
	mov	es,ax
	mov	ax,es:[006ch]
	mov	[si].dibTimerLo,ax
	mov	ax,es:[006eh]
	mov	[si].dibTimerHi,ax
	pop	ax
	pop	es
	ret
timeset endp

	subttl timetest - check elapsed time
	page
;======================================================================
;,fs
; timetest - check elapsed time
;
; in:	si-> dib structure
;	ds -> grp
;
; out:	al = 1 if diskette could not have been changed
;	al = 0 if it could have been
;
;,fe
;======================================================================
	assume	ds:grp,es:nothing,ss:nothing
timetest proc near
	mov	ax,0040h		; sah access bios
	mov	es,ax
	mov	ax,es:[006ch]
	mov	dx,es:[006eh]
	sub	ax,[si].dibTimerLo	; compute elapsed timer ticks
	sbb	dx,[si].dibTimerHi
	jnz	ttover
	cmp	ax,36			; jump if more than 2 seconds
	ja	ttover
	mov	al,1			; diskette cannot have been changed
	ret
ttover:
	mov	al,0			; diskette could have been changed
	ret
timetest endp

	subttl getlabel -- get label from current disk
	page
;======================================================================
;,fs
; getlabel -- get label from current disk
;
; reads label from disk in specified drive.  calculates directory
; sector number from information in dib.  reads directory in one sector
; at a time until it finds the drive label entry.  if the label is
; found, it is read into the buffer pointed to by di.
;
; in:	dl contains disk number
;	si->dib for drive
;	di->buffer for label
;	ds -> grp
;
; out:	cy clear if no error searching for label
;	cy set if error searching for label
;	if cy set, ah contains error code from rom bios
;
;,fe
;======================================================================
	assume	ds:grp,es:nothing,ss:nothing
getlabel proc near
	push	bx
	push	cx
	push	dx
	push	es
	mov	[drvnum],dl		; save drive number

; how many entries in directory?

	mov	cx,[si].dibRootDirEnts	; max root directory entries allowed
	mov	[dircnt],cx

; where does directory start?

getl10:
	mov	al,[si].dibFATs		; number of file allocation tables
	cbw
	mul	[si].dibFATsecs		; sectors of fat
	add	ax,[si].dibResSectors	; reserved sectors

; ax contains the first directory sector number.
; search the directory for the disk label.

	push	si			; save dib pointer
getl20:
	call	getsec			; get the indicated sector (in ax)
	jc	getl30			; if we couldn't read the sector
	call	srchsec			; search the sector for the disk label
	jc	getl40			; if label found (or we have given up)
	inc	ax			; try next sector
	jmp	getl20

; label search failed, return lblsiz null bytes for label.

getl30:
	call	zlbl			; zero out lblsiz bytes of sector buffer
	stc				; indicate error
	jmp	short getl50		; leave without clearing carry
getl40:
	or	ax,ax			; clear carry flag
getl50:
	pop	si			; restore dib pointer
	pop	es
	pop	dx
	pop	cx
	pop	bx
	ret
getlabel endp

	subttl getsec -- get sector from disk
	page
;======================================================================
;,fs
; getsec -- get sector from disk
;
; get a sector from the disk into secbuf.  the logical sector number to
; read is in ax.  if an error occurs while reading, sets the carry flag.
;
; in:	ax contains logical sector number.
;	ds -> grp
;
; out:	cy clear if sector read ok.
;	cy set if sector could not be read.
;	if error, ah contains error code from bios
;
;,fe
;======================================================================
	assume	ds:grp,es:nothing,ss:nothing
getsec proc near
	push	bx
	push	cx
	push	dx
	push	di
	push	es
	les	bx,dword ptr [secbuf]	; read into sector buffer
	call	calcabs			; get absolute disk location
	mov	dl,[drvnum]		; and drive number
	mov	[typrtr],3		; 3 retries
gets10:
	mov	ax,0201h		; read 1 sector
	int	13h
	jnc	gets40			; if successfully read sector
	push	ax
	xor	ah,ah			; reset drive on timeout
	int	13h
	pop	ax
	test	ah,80h			; no retires if time out
	jnz	gets20
	dec	[typrtr]		; through retries?
	jnz	gets10			; no try to read one more sector
gets20:					; return with error after all retries
	stc
gets40:
	pop	es
	pop	di
	pop	dx
	pop	cx
	pop	bx
	ret
getsec endp

	subttl srchsec -- search a directory sector for label
	page
;======================================================================
;,fs
; srchsec -- search a directory sector for label
;
; search directory sector for volume label.  directory entries are 32
; bytes long.  the 12th byte (offset 11) in the entry is the attribute
; byte.	 if bit 3 of the attribute is set, the entry is a volume label.
; the routine will terminate on finding the volume label with the
; label in the first lblsiz bytes of the sector buffer.
;
; if the label is not found & directory entry starting in 0 is found,
; the routine will copy zeroes to the beginning of the sector buffer &
; act as if it had found a label (terminating search).
;
; in:	if bx contains 1, secbuf -> sector to search for volume label.
;	if bx is not 1, es:bx -> sector to search for volume label
;	si -> dib for disk
;	di -> buffer for label (assumed to be in ds).
;	es same as cs & ds
;	ds -> grp
;
; out:	if cy clear, no label found.
;	if cy set, label found & in first lblsiz bytes of secbuf.
;
;,fe
;======================================================================
	assume	ds:grp,es:nothing,ss:nothing
srchsec proc near
	push	ax
	push	bx
	push	cx
	push	di
	push	si
	push	es
	les	bx,dword ptr [secbuf]	; point es:bx at sector
	mov	ax,[si].dibBytesPerSec	; bytes per sector
	mov	cl,5
	shr	ax,cl			; directory entries per sector = bps/32
	mov	cx,ax			; cx is loop count
	jcxz	srch30			; if no entries in sector
srch10:
	test	byte ptr es:[bx+11],08h ; is this the volume label?
	jnz	srch20			; if really the label
	cmp	byte ptr es:[bx],0	; is first byte a null?
	jz	srch30			; pretend we found entry
	add	bx,32			; next directory entry
	dec	[dircnt]		; take one out of total count
	loopnz	srch10
	cmp	[dircnt],0		; end of search?
	jz	srch30			; if end, return 0 label
	clc
	jmp	short srch50		; no label found, exit
srch20:
	mov	cx,lblsiz		; copy lblsiz bytes to wherever
	mov	si,bx			; now si points to the label
	push	ds
	push	es
	pop	ds
	pop	es
	cld
	rep	movsb			; copy label into ds:di
	push	es
	pop	ds
	jmp	short srch40		; exit & say label found
srch30:
	call	zlbl			; return with no label
srch40:
	stc
srch50:
	pop	es
	pop	si
	pop	di
	pop	cx
	pop	bx
	pop	ax
	ret
srchsec endp

	subttl zlbl -- zero out first lblsiz bytes of label
	page
;======================================================================
;,fs
; zlbl -- zero out first lblsiz bytes of label
;
; zeroes out first lblsiz bytes of label buffer pointed to by di.
; called by getlabel function.
;
; in:	di->buffer containing label to zero.
;	ds -> grp
;
; out:
;
;,fe
;======================================================================
	assume	ds:grp,es:nothing,ss:nothing
zlbl proc near
	push	ax
	push	di
	push	ds
	pop	es
	xor	ax,ax
	cld
	mov	cx,lblsiz
	rep	stosb
	pop	di
	pop	ax
	ret
zlbl endp
	assume	es:nothing

	subttl bldbpb - build bios parm block
	page
;======================================================================
;,fs
; bldbpb - build bios parm block
;
; this routine processes the build bios parameter block call (=2)
;
; in:
;	ds -> grp
;
; out:
;
;,fe
;======================================================================
	assume	ds:grp,es:nothing,ss:nothing
fbldbpb proc near
	call	logtrans		; do drive reassignment
	push	di
	les	bx,dword ptr [hdr]
	test	[si].dibAttributes,loadbpb  ; load bpb from disk?
	jz	bld05			; if just use bpb in dib
	call	settype			; get type for this disk
bld05:
	lea	di,[si].dibLabel
	jc	bld07			; if settype called & set cf
	and	[si].dibAttributes,not firstbpb  ; clear first time flag
	call	getlabel		; get disk label
	jmp	short bld08
bld07:
	call	zlbl			; if can't get label
ifdef	returnbad
	jmp	short bld10		; if bad media
endif

; bpb pointer is in si.

bld08:
	les	bx,dword ptr [hdr]
	mov	word ptr es:[bx].bbrBPBAddress,si
	mov	word ptr es:[bx+2].bbrBPBAddress,ds
	mov	es:[bx].bbrStatus,100h	; return 'Done'
ifdef	returnbad
	jmp	short bld20
bld10:
	test	[si].dibAttributes,firstbpb ; if first time, don't return
					; error
	jnz	bld08
	les	bx,dword ptr [hdr]
	mov	es:[bx].bbrStatus,8007h	; return 'bad media'
bld20:
endif
	pop	di
	ret
fbldbpb endp

	subttl settype -- determine disk type
	page
;======================================================================
;,fs
; settype -- determine disk type
;
; determines disk type for a given disk.  first tries to read track 0,
; sector 0, which contains a bpb for the disk.	if that fails, calls
; determine floppy type function in the rom bios (int 13h, function 15h)
; to figure out floppy type.
;
; in:	dl contains disk drive number to use
;	si -> dib for drive
;	[maxdrv] contains the max disk number for the system
;	ds -> grp
;
; out:	cy clear if type determined ok
;	cy set if type could not be determined
;
;,fe
;======================================================================
	assume	ds:grp,es:nothing,ss:nothing
settype proc
	push	ax
	push	bx
	push	cx
	push	dx
	push	si
	push	di
	push	es

; assume no error reading bpb

	and	[si].dibAttributes,not bpberr ; no error reading bpb

; first try to read boot sector.

	xor	ax,ax			; read logical sector 0
	call	getsec			; get sector 0 (boot sector)
	jnc	set20			; if no error
	jmp	set60			; if read error, use defaulb bpb & say error

; if dos 2.0+, bpb is in boot sector.

set20:
	les	bx,dword ptr [secbuf]
	mov	ax,word ptr es:[bx+11]
	or	ax,ax			; see if bytes/sector is 0 or f6
	je	set30			; if bps == 0, no bpb table
	cmp	ax,0f6h
	je	set30
	mov	al,byte ptr es:[bx]
	cmp	al,0ebh			; 3.0+ boot sectors start w/short jump
	je	set40			; if formatted on dos 3.0+
	cmp	al,0e9h			; 2.0 & 2.1 start w/long jump
	je	set40

; dos 1.x format (aack!).  read first byte of fat.

set30:
	mov	ax,1			; fat starts in logical sector 1.
	call	getsec
	jc	set60			; if read error, quit this foolishness.

; determine disk type from first byte in fat.

	mov	al,es:[bx]		; get media id byte from fat
	push	ds
	pop	es
	mov	cx,falen		; scan fatarr table for fat id we want
	mov	di,offset fatarr
	repne	scasb			; cx will be decremented for each byte examined
	jnz	set60			; if no match, use default, return error

; determine bpb to use based on # bytes examined.

	neg	cx
	add	cx,falen		; falen - bytes examined
	dec	cx			; want range of 0-falen-1, not 1-falen
	mov	ax,size bpb
	push	dx			; save dx around multiply
	mul	cx			; make search count into bpb offset
	pop	dx
	mov	si,offset bpbarr
	add	si,ax			; es:si points to the right bpb
	push	ds			; copy code wants a ds on the stack
	jmp	short set50		; copy new bpb into dib

; copy the bpb to the disk's BPB.

set40:
	push	ds
	push	ds
	push	es
	pop	ds			; ds & es point to right stuff
	pop	es
	assume	ds:nothing,es:grp
	lea	si,[bx+11]		; copy sector to local stuff & skip 11 bytes
set50:
	xor	dh,dh			; make disk number a word
	mov	di,dx
	mov	ax,size dib
	mul	di			; get offset in dib array
	mov	di,ax
	add	di,offset bpb1
	push	di			; save for after move
	mov	cx,dbpb_size		; length of bpb region within dib
	rep	movsb			; copy the bpb
	pop	si
	pop	ds
	assume	ds:grp,es:nothing
	mov	ax,[si].dibSecPerTrack	; get sectors per track
	mov	cx,[si].dibHeads	; number of heads
	cmp	cx,1			; how many heads?
	jne	set53			; if not 1 side, set up for double sided

; set up for single sided disk.
; sectors/cylinder == sectors/track, & use head mask which always
; decides to use head 0.

	xor	cx,cx			; head mask for the dib
	jmp	short set55

; set up for double sided disk.

set53:
	add	ax,ax			; sectors/cylinder = 2 * sectors/track
	mov	cx,1			; use low bit of remainder for head mask
set55:
	mov	[si].dibSectsPerCyl,ax	; sectors/cylinder = hds * sectors/track
	mov	[si].dibHeadMask,cx	; store head mask
	test	[si].dibAttributes,bpberr ; error reading the bpb?
	jnz	set95			; if there really was a problem
	clc				; type set ok
	jmp	short set100		; exit ok
set60:

; use default bpb from dib.

	push	ds
	push	ds
	pop	es			; point es at our ds
	or	[si].dibAttributes,bpberr ; error reading bpb
	lea	si,[si].dibdBytesPerSec	; default bpb address
	jmp	set50			; copy into proper dib structure
set95:
	stc
set100:
	pop	es
	pop	di
	pop	si
	pop	dx
	pop	cx
	pop	bx
	pop	ax
	ret
settype endp

	subttl input - input read
	page
;======================================================================
;,fs
; input - input read
;
; this routine processes the input read call (=4)
;
; in:
;	ds -> grp
;
; out:
;
;,fe
;======================================================================
	assume	ds:grp,es:nothing,ss:nothing
finput proc near
	mov	[biosfun],2		; bios function 2 - read
outentry:
	call	logtrans		; logical drive translation
	push	di
	les	bx,dword ptr [hdr]
	lea	ax,[si].dibLabel
	mov	word ptr es:[bx].rwrVolumeID,ax  ; volume id expected
	mov	word ptr es:[bx+2].rwrVolumeID,ds
	mov	ax,es:[bx].rwrBytesSec	; get sector count
	mov	[sectcnt],ax		; save total count for io
	mov	ax,es:[bx].rwrStartSec	; starting sector number (logical)
	mov	[sectstr],ax		; save for loop with large io
	les	bx,es:[bx].bbrFATSector	; get transfer address
iocont:
	mov	cx,3			; 3 retries
disk_io:
	push	cx			; save retry count
	mov	ax,[sectstr]		; get starting logical sector
	call	calcabs			; calculate absolute disk loc. from logical
	mov	dl,[drvnum]		; disk drive to use
	push	bx			; save buffer pointer
	mov	bx,[sectcnt]		; # sectors io
	xor	ah,ah
	mov	al,byte ptr [si].dibSecPerTrack ; max per io +1
	inc	al
	sub	al,cl			; calc # sectors til end of track (this head)
	cmp	ax,bx			; enough?
	jb	iopart			; no, must do some more io later
	mov	ax,bx			; yes, just what is needed
iopart:
	mov	di,ax			; save io count
	pop	bx			; restore buffer pointer
	mov	ah,[biosfun]		; bios disk function
	int	13h
	jnc	iook
	pop	cx
	push	ax			; save error in case abort
	xor	ah,ah			; reset drive before return
	int	13h
	pop	ax			; restore err code
	test	ah,80h			; no retries if timeout
	jnz	xxx1
	loop	disk_io			; for all retries
xxx1:
	jmp	fdskerr			; timeout or retries exhausted
iook:
	pop	cx			; clear retry count from stack
	call	timeset			; save timer value at last i/o
	add	[sectstr],di		; update new starting sector
	sub	[sectcnt],di		; update amount of io
	jz	endio			; yes, exit
	mov	ax,[si].dibBytesPerSec	; bytes per sector
	mul	di			; times sectors read/writ
	add	bx,ax			; update new buffer pointer
	jmp	iocont			; read next group
endio:
	les	bx,dword ptr [hdr]
	mov	es:[bx].rwrStatus,100h	; return 'Done'
	pop	di
	ret
finput endp

	subttl diskerr - xlates bios error code
	page
;======================================================================
;,fs
; diskerr - xlates bios error code
;
; ***** do not call,  with 1 parm on stack - jmp fdskerr  *****
;
; a jump is made here if the bios returns a disk error during read or
; write.  the following are the error codes returned by the bios :
;
; 1h  - bad command (never happen)
; 2h  - address mark not found
; 3h  - write protect disk
; 4h  - sector not found
; 6h  - media change (at only)
; 8h  - dma overrun
; 9h  - dma across 64k boundary
; 10h - bad crc on disk read
; 20h - bad nec controller
; 40h - seek operation failed
; 80h - time out
;
; the following error codes may be returned by the device driver:
;
; 0h  - write protect violation
; 1h  - unknown unit
; 2h  - device not ready
; 3h  - unknown command
; 4h  - crc error
; 5h  - bad drive request structure length
; 6h  - seek error
; 7h  - unknown media
; 8h  - sector not found
; 9h  - printer out of paper
; 0ah - write fault
; 0bh - read fault
; 0ch - general failure
; 0dh - reserved
; 0eh - reserved
; 0fh - invalid disk change
;
; errtbl moved into gdata by mjs 4/11/88
; dskerrtb expanded to handle bios err 0ah
; same table for hard and floppy disk
;
; in:	ah = bios int 13 error code
; 	es:bx -> request header
; 	cs:di = addr of translation table
; 	[sp] = parmeter to pop before return
;	ds -> grp
;
; out:	driver error code stored in request header status
; 	sector count optionally store in rh
;
;,fe
;======================================================================
	assume	ds:grp,es:nothing,ss:nothing

public	dskerrtbl
dskerrtbl label byte
	;	  x   1	  2   3	  4   x	  6   x
	db	0ch,0ch,0ch,00h,08h,0ch,0fh,0ch
	;	  8   9	  a   x	  c   x	  x   f
	db	0ch,0ch,0ch,08h,0ch,0ch,0ch,0ch
	;	 \/  10	 20   x	 40   x	  x   x
	db	    04h,0ch,0ch,06h,0ch,0ch,0ch
	;	 80  90	 a0  b0	 c0  d0	 e0  f0
	db	02h,0ch,0ch,0ch,0ch,0ch,0ch,0ch

public	diskerr
fdskerr:				; floppy disk error routine
	les	bx,dword ptr [hdr]
diskerr:
	mov	di,offset dskerrtbl	; get table to use
	mov	al,ah
	xor	ah,ah			; bios err in ax
	cmp	al,10h
	jbe	err3
	shr	al,1			; calc offset into error table
	shr	al,1
	shr	al,1			; use upper 4 bits as index
	shr	al,1
	add	al,0fh			; note at least 1 in al after shift
err3:
	add	di,ax
	mov	al,cs:[di]		; get driver error code for return
	mov	ah,81h			; error and done bits
	mov	es:[bx].rhStatus,ax	; return error type
	cmp	es:[bx].rhFunction,19	; a generic ioctl call?
	je	err4			; if generic ioctl, no sector count
	cmp	es:[bx].rhFunction,1	; a media check call?
	je	err4			; if media check, no sector count
	mov	ax,es:[bx].rwrBytesSec	; get sector count
	sub	ax,[sectcnt]		; calc amount done
	mov	es:[bx].rwrBytesSec,ax	; set sector count
err4:
	pop	di			; restore original value		from beg
	ret

	subttl calcabs - calculate absolute sector
	page
;======================================================================
;,fs
; calcabs - calculate absolute sector
;
; this routine will calculate the absolute disk location from the
; logical sector number.
;
; the following formulas are used:
;
; 	sector = (logical mod [dibSecPerTrack])+1
; 	track  = int (logical/[dibSectsPerCyl])
; 	head   = (int (logical / [dibSecPerTrack])) mod dibHeadMask
;
; in:	ax = logical sector number
;	si -> dib for drive
;	ds -> grp
;
; out:	dh = head number
;	ch = track number
;	cl = sector number
;
;,fe
;======================================================================
	assume	ds:grp,es:nothing,ss:nothing
calcabs proc near
	push	ax
	push	ax			; save starting sector
	xor	dx,dx
	div	[si].dibSectsPerCyl	; divide by sectors/cylinder
	mov	ch,al			; set track #
	pop	ax			; get starting sector
	xor	dx,dx
	div	[si].dibSecPerTrack	; divide by sectors/track
	mov	cl,dl			; set sector #
	inc	cl			; make it 1 relative
	and	ax,[si].dibHeadMask	; ax mod hdmsk
	mov	dh,al			; set head #
	pop	ax
	ret
calcabs endp

	subttl foutput - output write
	page
;======================================================================
;,fs
; foutput - output write
;
; this routine processes the output write call (=8)
;
; in:
;	ds -> grp
;
; out:
;
;,fe
;======================================================================
	assume	ds:grp,es:nothing,ss:nothing
foutput proc near
	mov	[biosfun],3		; bios function 3 - write
	jmp	outentry		; use same routines as 'Input' function
foutput endp

	subttl fdevopen - open device
	page
;======================================================================
;,fs
; fdevopen - open device
;
; this routine processes the device open call (=13)
;
; in:
;	ds -> grp
;
; out:
;
;,fe
;======================================================================
	assume	ds:grp,es:nothing,ss:nothing
fdevopen proc near
	call	logtrans		; do drive reassignment
	les	bx,dword ptr [hdr]
	mov	es:[bx].ocrStatus,0100h
	ret
fdevopen endp

	subttl fdevclose - close device
	page
;======================================================================
;,fs
; fdevclose - close device
;
; this routine processes the device close call (=14)
;
; in:
;	ds -> grp
;
; out:
;
;,fe
;======================================================================
	assume	ds:grp,es:nothing,ss:nothing
fdevclose proc near
	les	bx,dword ptr [hdr]
	mov	es:[bx].ocrStatus,0100h
	ret
fdevclose endp

	subttl fremove - removable media check
	page
;======================================================================
;,fs
; fremove - removable media check
;
; this routine processes the removable media (=15)
;
; in:
;	ds -> grp
;
; out:
;
;,fe
;======================================================================
	assume	ds:grp,es:nothing,ss:nothing
fremove proc near
	les	bx,dword ptr [hdr]
	mov	es:[bx].rmrStatus,0100h
	ret
fremove endp

	subttl fgenioctl - generic i/o control
	page
;======================================================================
;,fs
; fgenioctl - generic i/o control
;
; this routine processes the generic ioctl call (=19)
;
; it has 6 subfunctions:
;
; sub 40h - set device parameters
; sub 60h - get device parameters
; sub 41h - write track on logical device
; sub 61h - read track on logical device
; sub 42h - format and verify track on logical device
; sub 62h - verify track on logical device
; sub 66h - get media id
;
; in:	si -> dib structure for drive
;	ds -> grp
;
; out:
;
;,fe
;======================================================================
	assume	ds:grp,es:nothing,ss:nothing
fgenioctl proc near
	les	bx,dword ptr [hdr]
	mov	cl,es:[bx].giMinorCode	; minor function code
	or	[si].dibAttributes,dirtybpb  ; insure mediachk returns "changed"
	cmp	cl,setparms
	je	fgen10
	cmp	cl,getparms
	je	fgen20
	cmp	cl,wrttrack
	je	fgen30
	cmp	cl,rdtrack
	je	fgen40
	cmp	cl,fvtrack
	je	fgen50
	cmp	cl,vertrack
	je	fgen60
	cmp	cl,getmedid
	je	fgen70
	cmp	cl,setmedid
	je	fgen80
	mov	es:[bx].giStatus,8103h
	ret
fgen10:
	jmp	fgsetparms
fgen20:
	jmp	fggetparms
fgen30:
	call	logtrans		; do drive reassignment
	jmp	fgwrttrack
fgen40:
	call	logtrans		; do drive reassignment
	jmp	fgrdtrack
fgen50:
	call	logtrans		; do drive reassignment
	jmp	fgfvtrack
fgen60:
	call	logtrans		; do drive reassignment
	jmp	fgvertrack
fgen70:
	jmp	fgetmedid
fgen80:
	jmp	fsetmedid
fgenioctl endp

	subttl fgsetparms - generic i/o ctl set parameters
	page
;======================================================================
;,fs
; fgsetparms - generic i/o ctl set parameters
;
; this routine does the generic ioctl set parameters call (=40h)
;
; in:	si -> dib structure for drive
;	ds -> grp
;
; out:
;
;,fe
;======================================================================
	assume	ds:grp,es:nothing,ss:nothing
fgsetparms proc near
	les	bx,dword ptr [hdr]
	push	ds
	push	ds
	lds	bx,es:[bx].giIOCTLData	; pointer to ioctl request
	pop	es			; es points to old ds
	push	si			; save si for later
	assume	ds:nothing
	assume	es:grp
	mov	cx,[bx].dpTracks	; number of tracks in sector
	cmp	cx,maxtrktbl		; more than we can hold?
	ja	fgset50			; if too many
	jcxz	fgset05			; if none
	shl	cx,1			; tracks*2 == words in table
	inc	cx			; plus the track count
	lea	si,[bx].dpTracks	; source for copy
	mov	di,offset tracktable	; destination for copy
	cld
	rep	movsw			; copy the track table
fgset05:
	pop	si
	call	makeftbl		; construct format table
					; from track table
	test	[bx].dpSpecFunc,2	; ignore all but track table?
	jnz	fgset20			; if ignore all else

; copy bpb to driver.

	push	si			; save si again
	test	[bx].dpSpecFunc,1	; default bpb or real bpb?
	jnz	fgset10			; if set real bpb

; copy default bpb into dib.

	mov	cx,dbpb_size
	lea	di,[si].dibdBytesPerSec	; address of default bpb
	lea	si,[bx].dpBytesPerSec 	; address of caller's BPB
	rep	movsb			; copy the default bpb
	pop	si
	pop	ds
	assume	ds:grp,es:nothing
	or	[si].dibAttributes,loadbpb ; load bpb from real media
	jmp	short fgset30		; exit function

; copy real bpb into dib

fgset10:
	assume	ds:nothing,es:grp
	mov	cx,dbpb_size
	mov	di,si			; copy into real bpb
	lea	si,[bx].dpBytesPerSec 	; address of caller's BPB
	rep	movsb
	pop	si
	pop	ds
	and	[si].dibAttributes,not loadbpb ; don't load BPB from disk
	jmp	short fgset30		; exit function
fgset20:
	pop	ds
fgset30:
	assume	ds:grp,es:nothing
	mov	ax,0100h		; "Done" status code
fgset40:
	les	bx,dword ptr [hdr]
	mov	es:[bx].giStatus,ax
	ret
fgset50:
	assume	ds:nothing,es:grp
	pop	si
	pop	ds
	assume	ds:grp,es:nothing
	mov	ax,8105h		; return "Error, bad structure length"
	jmp	fgset40			; return to caller
fgsetparms endp

	subttl makeftbl - construct format table from track table
	page
;======================================================================
;,fs
; makeftbl - construct format table from track table
;
; this routine constructs the format buffer needed by the format
; call to format a track.  it constructs this table from the
; tracktable.  if the track layout table is a format supported
; by this routine, the badlayout flag will be cleared.  if the
; layout is not supported, the badlayout is not supported.
;
; in:
;	ds -> grp
;
; out:
;
;,fe
;======================================================================
	assume	ds:grp,es:nothing,ss:nothing
makeftbl proc near
	push	ds
	push	cx
	push	bx
	push	ax
	push	si
	push	di
	mgetscb ds
	mov	si,offset tracktable
	mov	di,offset formattable+2 ; only set second 2 bytes
	mov	[badlayout],0		; assume layout is good
	cld
	lodsw
	mov	cx,ax			; number of sectors to set up for
	jcxz	mkft30			; if zero sectors
mkft10:
	lodsw				; sector number
	mov	bl,al			; will be low byte we store
	lodsw				; sector size
	mov	bh,2			; size code for 512 bytes/sector
	cmp	ax,512
	je	mkft20			; if good sector size
	mov	bh,0			; size code for 128 bytes/sector
	cmp	ax,128
	je	mkft20			; if good sector size
	mov	bh,1			; size code for 256 bytes/sector
	cmp	ax,256
	je	mkft20			; if good sector size
	mov	bh,3			; size code for 1024 bytes/sector
	cmp	ax,1024
	je	mkft20			; if good sector size

; bad sector size.

	mov	[badlayout],1		; set bad layout flag
	mov	bh,2			; default sector size

; good sector size.

mkft20:
	mov	[di],bx			; set only sector number and size
	add	di,4			; skip to next location
	loop	mkft10			; do the next sector
	jmp	mkft40			; exit routine
mkft30:
	mov	[badlayout],1		; bad track layout
mkft40:
	pop	di
	pop	si
	pop	ax
	pop	bx
	pop	cx
	pop	ds
	ret
makeftbl endp

	subttl fggetparms - generic i/o ctl get parameters
	page
;======================================================================
;,fs
; fggetparms - generic i/o ctl get parameters
;
; this routine does the generic ioctl get parameters call (=60h)
;
; in: 	es:bx -> request header
;	si -> dib structure for drive
;	ds -> grp
;
; out:
;
;,fe
;======================================================================
	assume	ds:grp,es:nothing,ss:nothing
fggetparms proc near
	les	bx,es:[bx].giIOCTLData	; pointer to ioctl request
	push	si			; we use this later
	test	es:[bx].dpSpecFunc,1	; default bpb or real bpb?
	jz	fgget10			; if default bpb
	test	[si].dibAttributes,loadbpb ; should we load the bpb?
	jnz	fgget20			; if we don't need to load
					; the real bpb
	push	bx
	mov	bx,offset fggetparms	; set up registers for logtrans
	call	logtrans		; do drive reassignment
	pop	bx
	call	settype			; disk number is in dl
	jmp	short fgget20
fgget10:
	lea	si,[si].dibdBytesPerSec	; pointer to default bpb
	jmp	short fgget22		; don't load BPB
fgget20:
	call	settype			; load bpb from disk
fgget22:
	lea	di,[bx].dpBytesPerSec 	; where to copy the bpb
	mov	cx,dbpb_size		; length of it in bytes
	cld
	rep	movsb			; copy into caller's buffer
	pop	si			; restore dib pointer
	mov	al,[si].dibAttributes	; get device attributes
	test	al,dtsmall		; 3.5" drive?
	jnz	fgget50			; yes, jump
	test	al,dthicap		; 1.2 meg drive?
	jz	fgget30			; no, do 360k stuff

; return parameters for 1.2 meg drive

	mov	es:[bx].dpDevAttr,2	; removable, has change line
	mov	es:[bx].dpDevType,1	; 1.2 meg floppy
	xor	al,al			; assume default media
	cmp	[si].dibMedia,0f9h	; current media 1.2 meg?
	je	fgget25			; if normal media
	inc	al			; if 360k floppy
fgget25:
	mov	es:[bx].dpCylinders,80	; 80 cylinders on 1.2m floppy
fgget27:
	mov	es:[bx].dpMediaType,al	; set media type
	jmp	short fgget40

; return parameters for 360k drive

fgget30:
	xor	ax,ax			; will write lots of zeroes
	mov	es:[bx].dpDevType,al	; device type 0 (360k disk)
	mov	es:[bx].dpMediaType,al	; media type is default
	mov	es:[bx].dpCylinders,40	; 40 cylinders on 360k drive
fgget40:
	xor	ax,ax			; set device attributes field
	test	[si].dibAttributes,dtchgln ; change line available?
	jz	fgget41			; no, skip
	or	al,02h			; yes, turn on bit 1
fgget41:
	mov	es:[bx].dpDevAttr,ax	; bit 0 always indicates removable
	les	bx,dword ptr [hdr]
	mov	es:[bx].giStatus,0100h
	ret

; code to handle 3.5" diskette drives added by Rod:

fgget50 label	near
	test	al,dthicap		; 1.44m drive?
	jnz	fgget55			; yes, jump

; 720k drive

	mov	es:[bx].dpDevType,2	; 720k drive
	mov	es:[bx].dpCylinders,80	; 80 cylinders
	mov	es:[bx].dpMediaType,0	; default media type
	jmp	fgget40

; 1.44 meg drive

fgget55 label	near
	mov	es:[bx].dpDevType,7	; 1.44m drive
	mov	es:[bx].dpCylinders,80	; 80 cylinders
	mov	es:[bx].dpMediaType,0	; default media type
	jmp	fgget40

; end of rod's 3.5" diskette code

fggetparms endp

	subttl fgwrttrack - generic i/o ctl write track
	page
;======================================================================
;,fs
; fgwrttrack - generic i/o ctl write track
;
; this routine does the generic ioctl write track call (=41h)
;
; in:	si -> dib structure for drive
;	ds -> grp
;
; out:
;
;,fe
;======================================================================
	assume	ds:grp,es:nothing,ss:nothing
fgwrttrack proc near
	mov	[biosfun],3		; bios function 3 - write
	les	bx,dword ptr [hdr]
	les	bx,dword ptr es:[bx].giIOCTLData  ; generic i/o request packet
	mov	ax,word ptr es:[bx].rwBuffer  ; set transfer address
	mov	word ptr [giobuf],ax
	mov	ax,word ptr es:[bx+2].rwBuffer
	mov	word ptr [giobuf+2],ax
g_rventry:
	push	di			; save di before we munge it

; check starting sector.

	mov	ax,es:[bx].rwFirstSector ; starting sector
	mov	[sectstr],ax		; store for later
	cmp	ax,[tracktable]		; is start sector too big?
	jb	fgwr10			; if start sector ok
	jmp	fgwrer1			; if start sector too big

; check sector count.

fgwr10:
	add	ax,es:[bx].rwSectors	; total sector count
	cmp	ax,[tracktable]
	jbe	fgwr20			; if sector count ok
	jmp	fgwrer1
fgwr20:
	mov	ax,es:[bx].rwSectors
	jmp	short fgwr30		; continue checking arguments
g_fmtentry:
	push	di			; for stack rebalance
	mov	ax,[tracktable+2]	; starting sector
	dec	ax			; make it 0-based
	mov	[sectstr],ax		; store for later
	mov	ax,[tracktable]		; sectors to format

; store sector count.

fgwr30:
	mov	[sectcnt],ax

; check head number.

	push	dx
	mov	di,es:[bx].rwHead	; check requested head number
	cmp	di,[si].dibHeads	; head number above max?
	jae	fgwrer2			; if head number too big

; check cylinder number.

	mov	ax,[si].dibSectors	; total sectors
	xor	dx,dx
	mov	cx,[si].dibSecPerTrack	; sectors/track
	cmp	[si].dibHeads,1		; 1 or 2 sided
	je	fgwrer35		; if 1 sided
	shl	cx,1			; * 2 for sectors/cylinder
fgwrer35:
	div	cx			; get total cylinders
	pop	dx			; restore disk number
	mov	cx,es:[bx].rwCylinder
	cmp	cx,ax			; cylinder too big?
	jae	fgwrer3			; if cylinder number too big

; set up registers for i/o.

	mov	[typrtr],3		; retry count
	mov	ch,cl			; "track" (cylinder) number
	mov	cl,byte ptr [sectstr]	; starting sector number
	inc	cl			; 1-based sector number
	mov	ah,dl			; save disk number here
	mov	dx,di			; get head number in dl
	mov	dh,dl			; dh=head, dl=disk
	mov	dl,ah
	les	bx,[giobuf]		; where data lives
g_diskio:
	mov	al,byte ptr [sectcnt]	; sector count
					  ; format ignores this
	mov	ah,[biosfun]		; function to perform
	int	13h			; do it!
	jnc	g_iook			; if no error doing i/o

; reset drives and retry

	push	ax			; save error code
	xor	ah,ah			; reset drives after err
	int	13h
	pop	ax
	test	ah,80h			; test timeout err
	jnz	g_io_err		; if timeout exit with retry
	dec	[typrtr]		; out of retries?
	jnz	g_diskio		; no, try i/o again
g_io_err:
	jmp	fdskerr			; return error to caller

; the i/o call succeeded.

g_iook:
	call	timeset			; set last successful op time
	mov	ax,0100h		; return "Done"
g_ioex:
	les	bx,dword ptr [hdr]
	mov	es:[bx].giStatus,ax
	pop	di
	ret

; error handlers.

fgwrer1:
	mov	ax,08108h		; return "sector not found"
	jmp	g_ioex
fgwrer2:
	pop	dx			; restore dx from push
fgwrer3:
	mov	ax,08103h		; return "Bad command"
	jmp	g_ioex
fgwrttrack endp

	subttl fgrdtrack - generic i/o ctl read track
	page
;======================================================================
;,fs
; fgrdtrack - generic i/o ctl read track
;
; this routine does the generic ioctl read track call (=61h)
;
; in:	si -> dib structure for drive
;	ds -> grp
;
; out:
;
;,fe
;======================================================================
	assume	ds:grp,es:nothing,ss:nothing
fgrdtrack proc near
	mov	[biosfun],2		; bios function 2 - read
	les	bx,dword ptr [hdr]
	les	bx,dword ptr es:[bx].giIOCTLData  ; generic i/o request packet
	mov	ax,word ptr es:[bx].rwBuffer  ; set transfer address
	mov	word ptr [giobuf],ax
	mov	ax,word ptr es:[bx+2].rwBuffer
	mov	word ptr [giobuf+2],ax
	jmp	g_rventry		; do the i/o
fgrdtrack endp

	subttl fgfvtrack - generic i/o ctl format & verify track
	page
;======================================================================
;,fs
; fgfvtrack - generic i/o ctl format & verify track
;
; generic ioctl format & verify track call (=42h)
;
; in:	si -> dib structure for drive
;	ds -> grp
;
; out:
;
;,fe
;======================================================================
	assume	ds:grp,es:nothing,ss:nothing
fgfvtrack proc near
	les	bx,dword ptr [hdr]
	les	bx,es:[bx].giIOCTLData  ; now generic i/o request packet
	mov	al,byte ptr [badlayout]
	shl	al,1			; bad bit is bit 1, not 0
	or	al,1			; no funny layouts
	test	es:[bx].rwSpecFunc,1	; just a status call?
	jnz	fgfv10			; exit if just status call
	test	al,2			; funny track layout?
	jz	fgfv11			; if layout ok
fgfv10:
	mov	es:[bx].rwSpecFunc,al	; tell if layout ok
	les	bx,dword ptr [hdr]
	mov	es:[bx].giStatus,0100h
	ret
fgfv11:

; set format type for rom bios.

	xor	dh,dh			; this will be format type
	mov	ah,[si].dibAttributes
	test	ah,dtsmall		; 3.5" drive?
	jnz	fgfv350			; yes go to it
fgfv525:
	mov	cx,2709h		; get tracks, sectors/track
	inc	dh			; drive type 1 = 360k
	mov	di,offset pcdprm	; get 360k drive params
	test	ah,dthicap		; 1.2 meg drive?
	jz	fgfvdasd		; no finished with 360k
	mov	di,offset atdprm	; change to 1.2m disk params
	inc	dh			; 1.2m drive
	mov	[di].dpfmgap,50h	; format gap for 360k in 1.2m drive
	cmp	byte ptr [si].dibMedia,0f9h ; 1.2 meg floppy?
	jne	fgfvdasd		; no 360 in 1.2m done
	inc	dh			; 1.2 floppy in 1.2 drive
	mov	cx,4f0fh		; 80 cylinders, 15 sectors/track
	mov	[di].dpfmgap,54h	; gap length
	jmp	short fgfvdasd

; prepare to format a 3.5" diskette track

fgfv350:
	mov	dh,4			; 720k format type
	mov	cx,4f09h		; cylinders and sectors/track
	mov	di,offset psdprm	; get default disk parms
	test	ah,dthicap		; 720k drive?
	jz	fgfvdasd
	cmp	byte ptr [si].dibMedia,0f9h ; 720k media?
	jz	fgfvdasd
	mov	cl,18			; 1.44 drive and media
	jmp	short fgfvmedia

; *** zenith does't reset disk change line on Function 18
; *** it does reset line on function 17.	function 17 is
; *** executed and then 18.  both may return errors
; ch,cl = cylinders, sectors
; ah = drive type
; di = diskette parameters
; dh = media type
; dl = drive
; es:bx = request header
; si = dib

fgfvdasd:
	mov	[di].dpeot,cl		; set sectors/track in disk parms
	mov	al,dh			; save disk type in dh
	mov	ah,17h
	int	13h			; set dasd type for format
					; error or not continue
fgfvmedia:				; set media types (esp. 1.44) get bios diskette parms
	push	es			; save rh segment on stack
	mov	byte ptr [tracktable],cl ; set for table construction
	mov	ax,ds
	mov	es,ax			; get seg of diskprms in es
					; es:di = disk parameters
	mov	ah,18h			; set media for format
	int	13h			; returns disk parameters
	jnc	fgfvparm		; got diskette parms
	test	dh,dh			; is function 18 necessary ie. 1.44
	jnz	fgfvparm		; no use our disk parms
	mov	ah,0			; reset drives and try again
	int	13h
	mov	ah,18h
	int	13h
	jnc	fgfvparm		; succeeded
	jmp	fdskerr			; 1.44 meg errored on bios call
fgfvparm:				; es:di => diskette parms for format!!
					; save int 1e vector and place our parm ptr there
	mov	cx,es
	xor	ax,ax			; get vector segment
	mov	es,ax
	xchg	di,es:[int1e]		; set format diskette parameters
	xchg	cx,es:[int1e+2]
	pop	es			; pop rh segment before pushes
	push	cx			; and save old parm pointer
	push	di
	mov	al,byte ptr es:[bx].rwCylinder  ; get cylinder number
	mov	ah,byte ptr es:[bx].rwHead  ; and head number
	call	setftbl			; set up format table for
	mov	word ptr [giobuf],offset formattable
	mov	word ptr [giobuf+2],ds	; pointer to data - format descripts
	mov	[biosfun],5		; bios function 5 - format
	call	g_fmtentry		; format the track

; if the operation succeeded, the error bit in the driver request
; block will be reset.  es:bx will be left pointing to the main
; driver request block at this point, so we can conveniently test
; for an error.

	test	es:[bx].giStatus,8000h	; did an error occur?
	jnz	fgfvxit			; if error restore parms/exit
	les	bx,dword ptr es:[bx].giIOCTLData  ; generic i/o request packet
	mov	[biosfun],4		; bios function 4 - verify
	call	g_fmtentry		; verify the track
fgfvxit:				; restore default disk parms
	xor	ax,ax
	mov	es,ax			; restore diskette parameters
	pop	es:[int1e]
	pop	es:[int1e+2]
	ret
fgfvtrack endp

	subttl setftbl - construct format table from track table
	page
;======================================================================
;,fs
; setftbl - construct format table from track table
;
; this routine constructs the format buffer needed by the format
; call to format a track.	 it constructs this table from the
; tracktable.  if the track layout table is a format supported
; by this routine, the badlayout flag will be cleared.  if the
; layout is not supported, the badlayout is not supported.
;
; in:	al contains cylinder number to format
;	ah contains head number for track to format
;	ds -> grp
;
; out:	format table changed
;
;,fe
;======================================================================
	assume	ds:grp,es:nothing,ss:nothing
setftbl proc near
	push	es
	push	cx
	push	di
	push	ds
	pop	es
	mov	di,offset formattable
	cld
	mov	cx,[tracktable]		; number of sectors to set up for
	jcxz	stft20			; if zero sectors
stft10:
	stosw				; set cylinder number and head number
	add	di,2			; skip second two bytes
	loop	stft10			; next entry
stft20:
	pop	di
	pop	cx
	pop	es
	ret
setftbl endp

	subttl fgvertrack - generic i/o ctl verify track
	page
;======================================================================
;,fs
; fgvertrack - generic i/o ctl verify track
;
; this routine does the generic ioctl verify track call (=62h)
;
; in:	si -> dib structure for drive
;	ds -> grp
;
; out:
;
;,fe
;======================================================================
	assume	ds:grp,es:nothing,ss:nothing
fgvertrack proc near
	mov	[biosfun],4		; bios function 4 - verify
	les	bx,dword ptr [hdr]
	les	bx,dword ptr es:[bx].giIOCTLData  ; generic i/o request packet
	cmp	[badlayout],0		; funny track layout?
	jz	fgve20			; if layout ok
	or	es:[bx].rwSpecFunc,3
fgve10:
	les	bx,dword ptr [hdr]
	mov	es:[bx].giStatus,0100h
	ret
fgve20:
	test	es:[bx].rwSpecFunc,1	; just a status call?
	mov	es:[bx].rwSpecFunc,1	; say layout ok
	jnz	fgve10			; exit routine

; the contents of giobuf are irrelevant, since verify ignores es:bx.

	jmp	g_fmtentry		; do the i/o
fgvertrack endp

	subttl fsetmedid - set media id
	page
;======================================================================
;,fs
; fsetmedid - set media id
;
; this routine processes the set media id call, i21f440ds46
;
; in:	si -> dib structure for drive
;	ds -> grp
;
; out:
;
;,fe
;======================================================================
	assume	ds:grp,es:nothing,ss:nothing
fsetmedid proc near
	push	ax
	push	bx
	push	cx
	push	si
	push	di
	push	bp
	push	ds
	push	es
	mov	bp,si
	
; attempt to read partition boot sector

	xor	ax,ax
	call	getsec
	jc	stmx
	les	di,dword ptr [secbuf]

; must be an extended partition

	cmp	es:[di].btBootSignature,29h
	jne	stmx
	lds	si,dword ptr [hdr]
	lds	si,[si].giIOCTLData

; xfer the info

	mov	ax,word ptr [si].midSerialNum
	mov	word ptr es:[di].btVolumeID,ax
	mov	ax,word ptr [si].midSerialNum+2
	mov	word ptr es:[di].btVolumeID+2,ax
	cld
	mov	cx,11
	push	si
	push	di
	lea	si,[si].midVolLabel
	lea	di,[di].btVolumeLabel
	rep	movsb
	pop	di
	pop	si
	mov	cx,8
	lea	si,[si].midFileSysType
	lea	di,[di].btFileSysType
	rep	movsb

; write the modified buffer back to disk

	mgetscb ds
	assume	ds:grp
	les	bx,dword ptr [secbuf]
	xor	ax,ax			; logical sector number for pbr
	mov	si,bp
	call	calcabs			; get absolute disk location
	mov	dl,[drvnum]		; and drive number
	mov	[typrtr],3
sets10:
	mov	ax,0301h
	int	13h
	jnc	sets40			; if successful
	push	ax
	xor	ah,ah			; reset drive on timeout
	int	13h
	pop	ax
	test	ah,80h			; no retires if time out
	jnz	stmx
	dec	[typrtr]
	jnz	sets10
	jmp	short stmx
sets40:
	les	bx,dword ptr [hdr]
	mov	es:[bx].giStatus,0100h
	jmp	short stmz
stmx:
	mgetscb ds
	assume	ds:grp
	les	bx,dword ptr [hdr]
	mov	es:[bx].giStatus,8103h
stmz:
	pop	es
	pop	ds
	pop	bp
	pop	di
	pop	si
	pop	cx
	pop	bx
	pop	ax
	ret
fsetmedid endp

	subttl fgetmedid - get media id
	page
;======================================================================
;,fs
; fgetmedid - get media id
;
; this routine processes the get media id call, i21f440ds66
;
; in:	si -> dib structure for drive
;	ds -> grp
;
; out:
;
;,fe
;======================================================================
	assume	ds:grp,es:nothing,ss:nothing
fgetmedid proc near
	push	ax
	push	bx
	push	cx
	push	si
	push	di
	push	ds
	push	es

; attempt to read partition boot sector

	xor	ax,ax
	call	getsec
	jc	gtmx
	les	di,dword ptr [hdr]
	les	di,es:[di].giIOCTLData
	lds	si,dword ptr [secbuf]

; must be an extended partition

	cmp	[si].btBootSignature,29h
	jne	gtmx

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
	mgetscb ds
	assume	ds:grp
	les	bx,dword ptr [hdr]
	mov	es:[bx].giStatus,0100h
	jmp	short gtmz
gtmx:
	mgetscb ds
	assume	ds:grp
	les	bx,dword ptr [hdr]
	mov	es:[bx].giStatus,8103h
gtmz:
	pop	es
	pop	ds
	pop	di
	pop	si
	pop	cx
	pop	bx
	pop	ax
	ret
fgetmedid endp

	subttl fgetlog - get logical device
	page
;======================================================================
;,fs
; fgetlog - get logical device
;
; this routine processes the get logical device call (=23)
;
; in:
;	ds -> grp
;
; out:
;
;,fe
;======================================================================
	assume	ds:grp,es:nothing,ss:nothing
fgetlog proc near
	les	bx,dword ptr [hdr]
	mov	si,[si+dibRealDIB]	; get dib for real drive
	mov	al,[si+dibLastDriveNum]	; last logical number used
	add	al,[startd]		; (+ starting drive)
	mov	es:[bx].rhUnit,al
	mov	es:[bx].ldrStatus,100h	; return 'Done'
	ret
fgetlog endp

	subttl fsetlog - set logical device
	page
;======================================================================
;,fs
; fsetlog - set logical device
;
; this routine processes the set logical device call (=23)
;
; in:
;	ds -> grp
;
; out:
;
;,fe
;======================================================================
	assume	ds:grp,es:nothing,ss:nothing
fsetlog proc near
	mov	si,offset bpb1		; set next logical device used
	les	bx,dword ptr [hdr]
	mov	al,es:[bx].rhUnit
	xchg	[si+dibLastDriveNum],al	; set next drive number used
	add	al,[startd]		; (+ starting drive)
	mov	es:[bx].rhUnit,al
	mov	es:[bx].ldrStatus,100h
	ret
fsetlog endp

	subttl fioquery - ioctl query
	page
;======================================================================
;,fs
; fioquery - ioctl query
;
; in:	si -> dib structure for drive
;	ds -> grp
;
; out:
;
;,fe
;=====================================================================
	assume	ds:grp,es:nothing,ss:nothing
fioquery proc near
	les	bx,dword ptr [hdr]
	mov	es:[bx].giStatus,8103h	; prep for 'unknown command'
	cmp	es:[bx].giCategory,8
	jne	fiqz
	mov	cl,es:[bx].giMinorCode	; minor function code
	cmp	cl,40h
	je	fiqx
	cmp	cl,41h
	je	fiqx
	cmp	cl,42h
	je	fiqx
	cmp	cl,46h
	je	fiqx
	cmp	cl,60h
	je	fiqx
	cmp	cl,61h
	je	fiqx
	cmp	cl,62h
	je	fiqx
	cmp	cl,66h
	je	fiqx
	cmp	cl,68h
	je	fiqx
	jmp	short fiqz
fiqx:
	mov	es:[bx].giStatus,0100h	; return 'Done'
fiqz:
	ret
fioquery endp


fendres label	byte

	subttl initblk - init driver
	page
;======================================================================
;,fs
; initblk - init driver
;
; this routine will initialize the block device driver.
;
; in:
;	ds -> grp
;
; out:
;
;,fe
;======================================================================
	assume	ds:grp,es:nothing,ss:nothing
finitblk proc near
	mov	ah,0
	mov	dx,32+1			; want 32 paragraphs allocated+prefix
	push	es
	call	mosheman
	mov	ax,es
	inc	ax			; don't wax the heap prefix
	mov	[secbuf+2],ax		; store sector buffer segment address
	xor	ax,ax
	mov	[secbuf],ax		; store sector buffer offset
	call	isdrive			; count disk drives
	pop	es
	mov	al,[maxdrv]
	or	al,al			; cmp al,0
	jnz	fini10			; if no drives or > 1 drive

; 1 drive on system, prepare for drive redirection.
; al contains 0.

	mov	si,offset bpb1		; parameters for "A" drive
	mov	di,offset bpb2		; parameters for "B" drive
	mov	[si+dibRealDIB],si	; dib to use for both drives
	mov	[bpbpntr+2],si		; change bpb pointer for b to point
					; to a
	mov	[di+dibRealDIB],si
	mov	[si+dibLastDriveNum],al	; 0 => last drive number used was a
	inc	al
	mov	[si+dibRealDrive],al	; set redirected drive number to a
	mov	[di+dibRealDrive],al
	mov	[maxdrv],al		; 1 == highest allowable unit code
fini10:
	mov	bx,[hdr]
	inc	al			; maximum drive number --> # of units
	mov	es:[bx].irUnits,al	; set # of units
	mov	al,es:[bx].irDriveNumber ; starting drive number
	inc	al
	mov	[startd],al
	lea	dx,fendres
	mov	word ptr es:[bx].irEndAddress,dx  ; set ending address of driver
	mov	word ptr es:[bx+2].irEndAddress,cs
	lea	dx,bpbpntr
	mov	word ptr es:[bx].irParamAddress,dx  ; set pointer to bpb pointer array
	mov	word ptr es:[bx+2].irParamAddress,ds
	mov	es:[bx].irStatus,100h
	ret				; end of initblk
finitblk endp

	subttl isdrive - count & type drives on system
	page
;======================================================================
;,fs
; isdrive - count & type drives on system
;
; determines number and types of diskettes on system.  gets equipment
; information from rom bios on drive count.
; determines drive types by cmos or bios search
;
; problems with differing drives on a system where caused by the
; diskette parameter table.  the following code sets the table
; for the first drive and then merges subsequent parameter tables.
;
; in:
;	ds -> grp
;
; out:
;
;,fe
;======================================================================
	assume	ds:grp,es:nothing,ss:nothing
isdrive proc
	push	bx
	mov	ax,0101h		; starting assumption is 360k's
	mov	dx,0f000h		; get ready to look at rom
	mov	es,dx

; note that we first read the place that we know has valid rom
; the televideo 286 seems to act weird if we read the nonexistent
; memory at f000:17 first... i have no idea why.

	mov	dl,es:[0fffeh]		; id byte
	mov	cx,es:[17h]		; check if toshiba laptop
	and	ch,0fch			; looking for "Tn" in rom
	cmp	cx,'0T'
	je	isdt3100		; yes, go treat as model 30
	cmp	dl,0fch			; 286 machine (or 386 at clone)?
	je	isdcmos			; yes, go check cmos
	cmp	dl,0f8h			; model 80?
	je	isdcmos			; yes, go check cmos
	cmp	dl,0fah			; model 30 or pc convertible?
	ja	isdftyp			; no, assume 360k floppies
isdt3100:
	mov	ax,0303h		; yes, assume 720k diskettes
	mov	[t3100],'Y'		; remember this
	jmp	short isdftyp
isdcmos:
	mov	al,10h			; get diskette info from cmos,
	out	70h,al			; because this method covers
	jmp	$+2			; the most cases
	in	al,71h
	mov	ah,al
	mov	cl,4
	shr	al,cl			; al is drive a, ah is drive b
	and	ah,0fh
isdftyp:
	mov	word ptr [ftypes],ax	; set ftypes
	mov	ax,ds			; restore segment in es
	mov	es,ax
	int	11h			; get equipment information
	test	al,1			; any diskettes?
	jnz	isdrives		; yes count them
	jmp	isdxit			; none just exit
isdrives:
	and	ax,00c0h		; maximum diskette drive number
	rol	al,1			; make it an integer
	rol	al,1
	mov	[maxdrv],al
	mov	si,offset grp:bpb1	; first dib structure
	xor	bx,bx			; start with drive 0

; bx = drive #
; si => dib structure

isdloop:
	push	si			; save dib
	mov	al,ftypes[bx]		; get diskette type code
	cmp	al,3
	jg	isd104
	je	isd103
	cmp	al,1			; vector to approp
	jg	isd102
	je	isd101
	jmp	isd40
isd104:
	mov	si,offset psdprm	; 1.44m drive
	mov	di,offset bpb14
	mov	ah,dthicap+dtsmall+dtchgln
	jmp	short isdset
isd103:
	mov	si,offset psdprm
	mov	di,offset bpb720	; 720k drive
	mov	ah,dtsmall+dtchgln
	cmp	[t3100],'Y'		; toshiba t3100?
	jne	isdset			; no, go
	mov	si,offset pcdprm	; yes, use same as 360k diskparms
	jmp	short isdset
isd102:
	mov	si,offset atdprm	; 1.2m drive
	mov	di,offset bpb12
	mov	ah,dthicap+dtchgln
	jmp	short isdset
isd101:
	mov	si,offset pcdprm	; 360k drive
	mov	di,offset bpb360
	mov	ah,0
isdset:					; set diskprm with drive's parameters
	push	di			; save device bpb
	mov	di,offset diskprm
	test	bx,bx			; first drive ?
	jnz	isdmerg
	mov	cx,size diskprm
	cld
	rep	movsb			; first drive set diskprm
	jmp	short isdbpb
isdmerg:				; merge second drive's parms with first's
	push	ax			; save drive flags
	push	bx			; bx used as parm offset
	mov	bl,dpsb1
	call	maxparm			; max time/step
	mov	bl,dpeot
	call	maxparm			; maximum sector/track
	mov	bl,dprwgap
	mov	al,[si].dprwgap
	cmp	al,[di].dprwgap		; use minimum read/write gap
	jge	isdmhds
	mov	[di].dprwgap,al
isdmhds:
	mov	bl,dphdstl
	call	maxparm			; maximum head settle time
	mov	bl,dpmstrt
	call	maxparm			; maximum startup delay
	pop	bx
	pop	ax			; restore drive flags
isdbpb:
	pop	di			; restore bpb
	pop	si			; restore dib index
	or	ah,loadbpb or firstbpb or dirtybpb
	mov	[si].dibAttributes,ah	; store disk type

; copy default bpb.

	push	si			; save dib pointer across copy
	push	si			; save for second copy
	push	di			; save source across copy too
	lea	si,[si].dibdBytesPerSec	; default bpb address
	xchg	si,di
	mov	cx,dbpb_size		; copy the default bpb
	rep	movsb
	pop	si			; source for copy (standard bpb)
	pop	di			; dib pointer
	mov	cx,dbpb_size		; length to copy
	rep	movsb			; copy default bpb into main bpb
isd40:
	pop	si			; restore dib pointer
	add	si,size dib		; advance to next structure in array
	inc	bx			; next drive to check
	cmp	bl,[maxdrv]
	jg	isdxit
	jmp	isdloop			; check all drives
isdxit:
	pop	bx
	ret
isdrive endp

	subttl maxparm - sets diskette parameter to max/min of two tables
	page
;======================================================================
;,fs
; maxparm - sets diskette parameter to max/min of two tables
;
; in:	ds:si => source parameter table
; 	ds:di => destination parameter table
; 	bx = index to byte manipulated
;	ds -> grp
;
; out:	ds:[di+bx] set to max of ds:[bx+si] ds:[bx+di]
;
;,fe
;======================================================================
	assume	ds:grp,es:nothing,ss:nothing
maxparm proc near
	mov	al,[si+bx]
	cmp	al,[di+bx]
	jle	maxparmx
	mov	[di+bx],al
maxparmx:
	ret
maxparm endp

mosseg	ends
	end

