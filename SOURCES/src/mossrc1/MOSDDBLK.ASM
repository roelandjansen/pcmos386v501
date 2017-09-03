	include	page.inc
	title	MOSDDBLK - MOS device driver for drive I/O

	include mosddblk.pub

;-----------------------------------------------------------------------;
;									;
;		Development Specification				;
;									;
;									;
; Program Name: MOS.COM			Assigned to: David A. Morrow	;
; Module Name:	MOSDDBLK		Assign date: 04/24/86		;
; Entry Points: blkintr, blkstrat	Completed: 02/14/87		;
; Entry From:	todriver						;
; Entry Method:	far call						;
; Calls:	n/a							;
; Purpose:	MOS block device driver (diskette and fixed disk)	;
; Refer to:	n/a							;
; Last Update:	03/09/87						;
;									;
;-----------------------------------------------------------------------;
; JSM 12/22/86	Support 1.2 meg floppies in 1.2 meg drives		;
;-----------------------------------------------------------------------;
; JSM 02/14/87  Change A/B drive support				;
;-----------------------------------------------------------------------;
; JSM 03/09/87  Fix problems in getparms & setparms w/diskcopy		;
;-----------------------------------------------------------------------;
; JSM 05/06/87  Add new disk type, DTOLD, for 360K drives on PC's with	;
;		pre-AT ROM BIOS's.  Change all tests for 360K vs. 1.2M	;
;		drives from comparisons with DTNOCHG (AT 360K drive) to	;
;		comparisons with DTCHG (AT 1.2M drive), so DTOLD &	;
;		DTNOCHG will be treated almost equivalently.  Only	;
;		difference is that format track call won't set disk	;
;		type for DTOLD drives, but will set it for DTNOCHG.	;
;-----------------------------------------------------------------------;
; RBR 07/08/87  Did away with disk types: DTOLD, DTCHG, DTNOCHG, etc.   ;
;		Substituted 3 new flags: DTSMALL indicates 3.5" drive,  ;
;		DTHICAP indicates 1.2M or 1.44M format, and DTCHGLN	;
;		indicates if there is a change line available. Tables   ;
;		and code were added/changed as necessary to support     ;
;		the 3.5" formats. For an AT or PS/2 class machine,      ;
;		we check CMOS for diskette types because BIOS calls	;
;		can't always tell us if there's a 1.44M drive. For      ;
;		the model 30, 720K drives are assumed. Did away with	;
;		the "isat" flag, and added "dprmptr" to point to the	;
;		default diskette parameter table for the system.	;
;-----------------------------------------------------------------------;
; RBR 07/11/87  Removed some redundant code.				;
; RBR 07/13/87  Fixed a NEG that should have been a NOT. My error.	;
; RBR 07/18/87  Fixed inability to write to 1.44M diskettes.      	;
; SAH 01/20/88	Change SCBSEG and ZERO seg to MGetXXXX macros		;
; RBR 02/07/88  Fixed problem with incorrect disk parms when formatting ;
;		the Toshiba T3100 3.5" diskette drive.                  ;
; SAH 02/21/88 	rbr/sah	Move DDT code to MO2 group.        		;
; RBR 03/13/88  See comment near beginning of "isdrive" proc.           ;
;-----------------------------------------------------------------------;
; MJS 4/11/88	Added tests to skip retries if a disk operation fails	;
;		due to a time out error.  This is to speed up the 	;
;		response in the case where the drive door is open	;
;		(e.g. Zenith/navy - took minutes to get a crit err).	;
;		Made similar mods to mosfutil.asm.			;
;-----------------------------------------------------------------------;
; jrb 05/02/88  get/set logical drive corrections			;
; jrbr          add word of 0 in DIB so hidden is a correct dd          ;
;-----------------------------------------------------------------------;
; 06/03/88 jrb		changed sense of IBM bit - current dos 		;
; jrbv			drivers (including us) are not ibm devices - 	;
;			that is, they don't require the first fat	;
;			sector on a build bpb call			;
;-----------------------------------------------------------------------;
; SAH 08/26/88	Made corrections in handling of change line so that if	;
;		bios returns that disk line has change that we actually ;
;		return that it did change.   PTR 120		        ;
; SAH 09/09/88  Corrected problems with format with above addition	;
;-----------------------------------------------------------------------;
; RKG001 10/17/88  Problems with FORMAT tracked to wrong error code	;
;		returned from INT 13.  Expanded table and merged hard	;
;		and floppy code.					;
;-----------------------------------------------------------------------;
; RKG004 12/01/88  Problems with secondary 360s and 3.5" drives caused  ;
;		by inappropriate diskette parameter table.  Format now	;
;		uses the parm table returned by INT 13, Func 18 and 	;
;		initialization code creates a compatible table for all	;
;		diskettes.						;
;-----------------------------------------------------------------------;
; RKG005 12/05/88  Spurious problems caused by not reseting drives after;
;		timeouts.  Changed MJS 4/11/88 to reset before return	;
;-----------------------------------------------------------------------;
; RKG	 12/07/88 Problems with Zenith corrected by format sequence 	;
;		changes.						;
;-----------------------------------------------------------------------;
; RKG	 12/09/88 Problems with Toshiba corrected.  INT 13 function 17	;
;		may not be present but must always set sectors/track	;
;		in the disk parms.  Also reverted to executing Funct 17 ;
;		then 18 for Zenith disk change line			;
;-----------------------------------------------------------------------;
; RKG	 12/12/88 Change handling of Func 17 and 18 for the last time	;
;-----------------------------------------------------------------------;
; BWR	11/28/89	Marked messages for foreign language		;
;			translation.					;
;-----------------------------------------------------------------------;
; BWR	3/1/90	Minor bug fix for Toshiba 5200 High Density floppy	;
;		drive.							;
;-----------------------------------------------------------------------;


	.xlist

	subttl	group segments and include block definitions
	page

	include	MOSREGS.INC
	include GROUP.INC

	.list

tcb	segment at 1234h
tcb	ends

irq	segment	byte public 'data'

	dw	1eH*4		; Diskette parm pointer
	dd	?		; Old pointer saved here (although not needed)
	dw	0		; Do not save any application changes
	dw	grp:diskprm	; Point vector to our disk parms
	dw	0		; No second level

irq	ends

poll	segment	byte public 'data'
poll	ends

ddt	segment	word public 'code2'
ddt	ends

	page
gdata	segment	word public 'data'

	extrn	media13:byte

	public	diskprm

;	Bits in the attribute byte in the DIB block

DTSMALL	equ	01h		; set if 3.5" drive, 0 means 5.25" drive
DTHICAP	equ	02h		; set if high capacity drive (1.2M or 1.44M)
DTCHGLN	equ	04h		; set if change line is available
LOADBPB	equ	08h		; set if BPB should be loaded from media
BPBERR	equ	10h		; set if error loading BPB from media
DIRTYBPB equ	20h		; set when we HAVE to load BPB from disk
DISKSWAP equ	40h		; set if we just did a disk swap
FIRSTBPB equ	80h		; set first time BPB is loaded

;	Command subcodes for generic I/O control

SETPARMS equ	040h		; set device parameters
GETPARMS equ	060h		; get device parameters
WRTTRACK equ	041h		; write track on logical device
RDTRACK	equ	061h		; read track on logical device
FVTRACK	equ	042h		; format and verify track on logical device
VERTRACK equ	062h		; verify track on logical device

BIOStl	equ	06cH		; BIOS timer low address (seg 40)
BIOSth	equ	06eH		; BIOS timer high address (seg 40)
DISKINT	equ	013h		; BIOS interrupt for diskette I/O

LBLSIZ	equ	11		; size of MOS volume label

;----------------------- Device Information block ----------------------;

DIB	struc
; real BPB for unit
DIBbps	dw	512		; Bytes/Sector
DIBspal	db	1		; Sectors/Cluster
DIBrsc	dw	1		; Reserved sectors
DIBnfat	db	2		; Number of FATs
DIBdent	dw	224		; Number of root directory entries
DIBsect	dw	1200		; Total allocation (# of sectors)
DIBmb	db	0f9H		; Media descriptor (1.2 meg)
DIBspf	dw	7		; Sectors per FAT

DIBspt	dw	15		; Sectors/track (15 for 1.2 meg floppy)
DIBhds	dw	2		; number of heads
DIBhdn	dw	0		; hidden sectors
        dw      0               ;jrbr

; default BPB for unit
DIBdbps	dw	512		; Bytes/Sector
DIBdspal db	1		; Sectors/Cluster
DIBdrsc	dw	1		; Reserved sectors
DIBdnfat db	2		; Number of FATs
DIBddent dw	224		; Number of root directory entries
DIBdsect dw	1200		; Total allocation (# of sectors)
DIBdmb	db	0f9H		; Media descriptor (1.2 meg)
DIBdspf	dw	7		; Sectors per FAT
DIBdspt	dw	15		; Sectors/track (15 for 1.2 meg floppy)
DIBdhds	dw	2		; number of heads
DIBdhdn	dw	0		; hidden sectors
DIBdrs0	dw	0		; rest of hidden sectors
DIBdrs1	dd	0		; reserved section 1
DIBdrs2	db	6 dup (0)	; reserved section 2

DIBBfun	db	0		; Temp holding for next disk function
DIBfill	db	0		; fill for keeping word alignment
DIBhdmsk dw	1		; head mask
DIBspc	dw	30		; Sectors/cylinder (30 for 1.2 meg floppy)
DIBScnt	dw	0		; Total count of sectors for read or write
DIBSstr	dw	0		; Starting sector for next disk I/O in loop
DIBtiml	dw	0		; Last holding timer value
DIBtimh	dw	0		; "	"	"
DIBblkhdr dw	2 dup(0)	; ##### Temporary header pointer
DIBlbl	db	12 dup (0)	; disk label
DIBfdrv	db	0		; Disk drive to use 0 or 1
DIBatt	db	0		; drive attributes
DIBrdn	db	0		; drive number this drive really should be
DIBldn	db	0		; last drive number used for this drive
DIBrdb	dw	0		; pointer to real DIB for this drive
DIB	ends

;-------------------- BIOS Parameter Block -------------------;

BPB	struc

BPBbps	dw	512		; Bytes/Sector
BPBspal	db	1		; Sectors/Cluster
BPBrsc	dw	1		; Reserved sectors
BPBnfat	db	2		; Number of FATs
BPBdent	dw	224		; Number of root directory entries
BPBsect	dw	1200		; Total allocation (# of sectors)
BPBmb	db	0f9H		; Media descriptor (1.2 meg)
BPBspf	dw	7		; Sectors per FAT
BPBspt	dw	15		; Sectors/track (15 for 1.2 meg floppy)
BPBhds	dw	2		; number of heads
BPBhdn	dw	0		; hidden sectors

BPB	ends

;---------------------- Device driver request block ----------------------;

devrq	struc

drqlen	db	?		; length of entire request
drquni	db	?		; unit number for request
drqcom	db	?		; command for request
drqsta	dw	?		; status from call
drqres	db	8 dup (?)	; DOS reserved

devrq	ends

;	extra fields for init

idevrq	struc
	db	size devrq dup (?)
drqunits db	?
drqendres dd	?
drqbpba	dd	?
drqdn	db	?

idevrq	ends

;	extra fields for media check

mdevrq	struc
	db	size devrq dup (?)
drqmd	db	?
drqrtcd	db	?
drqlbl	dd	?
mdevrq	ends

;	extra fields for build BPB

bdevrq	struc
	db	size devrq dup (?)
	db	?		; space for media descriptor (use drqmd)
drqta	dd	?
drqbpbp	dd	?
bdevrq	ends

;	extra fields for input & output

idevrq	struc
	db	size devrq dup (?)
	db	?		; media descriptr (use drqmd)
	dd	?		; transfer address (use drqta)
drqsect	dw	?
drqstrt	dw	?
drqelbl	dd	?
idevrq	ends

;	extra fields for generic ioctl request

gdevrq	struc
	db	size devrq dup (?)
drqmaj	db	?
drqmin	db	?
drqcsi	dw	?
drqcdi	dw	?
drqgirp	dd	?
gdevrq	ends


;------------------- generic IOCTL request packets -----------------;

gigsp	struc			; generic IOCTL get/set parameters packet
gspspe	db	?		; special functions
gspdt	db	?		; device type
gspda	dw	?		; device attributes
gspncy	dw	?		; number of cylinders
gspmt	db	?		; media type
gspbpb	db	size BPB dup (?)	; BPB in request packet
gsprs0	dw	0		; rest of hidden sectors
gsprs1	dd	0		; reserved section 1
gsprs2	db	6 dup (0)	; reserved section 2
gsptrack dw	?		; track layout table
gigsp	ends

girwfvp	struc			; generic IOCTL read/write/format/verify 
				; packet
girspe	db	?		; special functions
girhead	dw	?		; head to use
gircyl	dw	?		; cylinder to use
girstrt	dw	?		; starting sector number (1 based)
girnsec	dw	?		; number of cylinders to write
girta	dd	?		; transfer address
girwfvp	ends

;----------------------- BPB data area ---------------------------------;

BPBpntr	dw	BPB1		; For 1st unit
	dw	BPB2		; For 2nd unit

BPB1	DIB	<>		; use default values
BPB2	DIB	<>
		 
FATarr	db	0F9h, 0FCh, 0FDH, 0FEh, 0FFh
FAlen	equ	$ - FATarr

BPBarr	label	byte

BPB12	BPB	<512,1,1,2,224,2400,0F9h,7,15,2,0>	; First 5 match FATarr
BPB180  BPB	<512,1,1,2,112, 360,0FCh,2, 9,1,0>
BPB360	BPB	<512,2,1,2,112, 720,0FDh,2, 9,2,0>
BPB160  BPB	<512,1,1,2, 64, 320,0FEh,1, 8,1,0>
BPB320  BPB	<512,2,1,2,112, 640,0FFh,1, 8,2,0>

BPB720	BPB	<512,2,1,2,112,1440,0F9h,3, 9,2,0> 	;Rod  3.5" BPB's
BPB14 	BPB	<512,1,1,2,224,2880,0F0h,9,18,2,0>	;Rod

;------------------------ Track layout table ----------------------------;

	even

Badlayout	dw	0	; non-zero if funny track layout

TrackTable	label word
	dw	15		; 15 entries in the default table
	dw	1
Sec1Size dw	512		; sector 1, 512 bytes long
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

;	Extra space for funny user tables

	dw	16,512
	dw	17,512
	dw	18,512
	dw	19,512
	dw	20,512

MAXTRKTBL equ (($ - TrackTable) / 4)

FormatTable	label	byte
	db	(MAXTRKTBL * 4) dup (?)	; table for format call

;------------------------ miscellaneous data ----------------------------;
	even
wsblkhdr dw	2 dup(0)	; ##### Temporary header pointer
tcbfdrv	db	0		; Disk drive to use 0 or 1
BIOSfun	db	0		; Temp holding for next disk function

dircnt	dw	?		; max directory entries in root dir

maxdrv	db	-1		; maximum drive number in use (-1 means none)
typrtr	db	3		; retry count for drive type

Sectcnt	dw	0		; Total count of sectors for read or write
Sectstr	dw	0		; Starting sector for next disk I/O in loop

giobuf	dd	0		; buffer pointer for doint generic I/O

fghead	db	0		; head for generic read/write/format/verify
fgtrack	db	0		; track for generic read/write/format/verify

startd  db      0               ;jrbr starting absolute drive number (1=A)

t3100	db	'N'		;rr  Y if Toshiba T3100

;------------------- ROM BIOS disk parameter block ----------------;

diskparm struc

dpsb1	db	0dfh		; specify byte 1 (step-rate time, head-unload)
dpsb2	db	002h		; specify byte 2 (head-load time, DMA mode)
dpmwait	db	025h		; wait time until motor turned off
dpbps	db	002h		; bytes per sector (2==512)
dpeot	db	00fh		; last sector number in a track
dprwgap	db	01bh		; gap length between sectors for read/write
dpdatln	db	0ffh		; data length if no sector length
dpfmgap	db	054h		; gap length between sectors for formatting
dpfmval	db	0f6h		; data value stored in formatted sectors
dphdstl	db	001h		; head settle time
dpmstrt	db	008h		; motor start-up time
	db	0		; spare for alignment
diskparm ends


;----------------- Disk parameter blocks ----------------;
; INT 1E points to diskprm
INT1E	equ	(1Eh * 4)
	even

diskprm	diskparm <0dfh, 2, 25h, 2, 15, 1bh, 0ffh, 50h, 0f6h, 15, 2>

atdprm	diskparm <0dfh, 2, 25h, 2, 15, 1bh, 0ffh, 54h, 0f6h, 2,  8>
pcdprm	diskparm <0dfh, 2, 25h, 2,  9, 2ah, 0ffh, 50h, 0f6h, 15, 2>
psdprm	diskparm <0afh, 2, 25h, 2, 18, 1bh, 0ffh, 6ch, 0f6h, 15, 4> ;Rod

	even			;Rod
;dprmptr dw	0,0		;deleted default diskette parm ptr RKG
ftypes	db	1,1		;Rod  Disk type codes drives A and B

;-------------- Pointer to buffer for BPB read ----------------;

	even
secbuf	dw	2 dup (?)	; pointer to buffer for reading in disk info
lblbuf	db	12 dup (?)	; buffer for disk label

;--------------- Prompt for disk swap message ------------------;

switchmsg db	0ah, 0dh, 0ah, 0dh, "   Put in diskette for disk drive  " ;@@XLAT
drvn	db	"A and press any key     ", 0ah, 0dh, 0ah, 0dh, 0 ;@@XLAT


;----------------------- Function table --------------------------------;

	even
ffuntbl	dw	finitblk	; 0  Init
	dw	fmedck		; 1  Media check
	dw	fbldbpb		; 2  Build BPB
	dw	fioctli		; 3  I/O control input
	dw	finput		; 4  Input (read)
	dw	fndinput	; 5  Nondestructive input no wait
	dw	finstat		; 6  Input status
	dw	finflsh		; 7  Input flush
	dw	foutput		; 8  Output (write)
	dw	foutver		; 9  Output with verify
	dw	foutstat	; 10 Output status
	dw	foutflsh	; 11 Output flush
	dw	fioctlo		; 12 I/O control output
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

gdata	ends

	subttl	mos segment - MOS module code and local data

	page
mosseg	segment	word public 'code1'
	assume	cs:mos,ds:nothing,es:nothing,ss:tcb

	extrn mosheman:near, sbios:word
	extrn bugerror:near

;----------------------- Device Header ---------------------------------;

	public	scbstdblk
scbstdblk label	byte
	dd	-1
        dw      0010100001000001b       ;jrbv Block, non-FAT-ID, removeable,
                                        ;jrbv get/set logical & generic IOCTL
                                        ;jrbv (and why bit 0?)
	dw	mos:blkstrat
	dw	mos:blkintr
	db	8 dup (0)		; # devices passed at INIT

	subttl	BLKSTRAT - Block strategy routine
	page
;-----------------------------------------------------------------------;
;	This routine is the block drivers strategy routine, it just	;
;	queues the DWORD pointer to the request header.			;
;									;
;  On Entry:								;
;	ES:BX points to the device request header.			;
;									;
;  On Exit:								;
;	The request header pointer is saved.				;
;									;
;	The pointer TCBBLKHDR is set in the current tasks TCB.		;
;	No global procedures called					;
;	No registers are changed					;
;-----------------------------------------------------------------------;

blkstrat proc	far

	push	ds			;rs1
	MGetSCB	ds			;rs1
	assume	ds:grp			;rs1
	mov	[wsblkhdr],bx		; Save pointer in active TCB
	mov	[wsblkhdr+2],es
	pop	ds			;rs1
	assume	ds:nothing		;rs1
	ret

blkstrat endp

	subttl	BLKINTR - Block interrupt routine

	page
;-----------------------------------------------------------------------;
;	This is the block device drivers interrupt routine which will	;
;	process MOS's requested function.				;
;									;
;	No parms passed							;
;	Return values							;
;	Global data affected						;
;	Global procedures called					;
;	What registers are changed					;
;-----------------------------------------------------------------------;

blkintr	proc	far

	pushf
	push	ax
	push	bx
	push	cx
	push	dx
	push	si
	push	di
	push	es
	push	ds

	MGetSCB	ds			;rs1
	assume	ds:grp			;rs1

	les	bx,dword ptr [wsblkhdr] ; Get Request Header pointer
	mov	al,es:[bx].drquni	 ; Get unit code
	mov	[tcbfdrv],al	; Set disk to use
	cmp	al,[maxdrv]	; good unit code?
	ja	err2		; if unit code bad
	xor	ah,ah

	shl	ax,1		; convert unit code to table offset
	mov	si,ax
	mov	si,[si].bpbpntr	; pointer to DIB structure

	mov	bl,es:[bx].drqcom	; Get command code
	cmp	bl,24		; Check for invalid call
	ja	ferr1		; If bad command code
frtest:
	mov	dl,[tcbfdrv]	; keep drive number in dl
	xor	bh,bh
	shl	bx,1
	mov	bx,[bx + ffuntbl]	; Get address of appropriate routine
	or	bx,bx		; legal code?
	jz	ferr1		; if illegal code
	call	bx		; call the function
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
	les	bx,dword ptr [wsblkhdr]	; Get Request Header pointer
	mov	es:[bx].drqsta,8103H		; Return 'Unknown Command'
	jmp	frexit

err2:
	les	bx,dword ptr [wsblkhdr]	; Get Request Header pointer
	mov	es:[bx].drqsta,8101H		; Return 'Unknown Unit'
	jmp	frexit

blkintr	endp

	subttl	LOGTRANS - do logical drive reassignment

	page
;-----------------------------------------------------------------------;
;	logtrans							;
;									;
;	This routine checks for drive redirection.  If the DIBrdn field	;
;	in the DIB is non-zero, moves the new drive number into dl.	;
;	It decrements the number to produce the real drive number,	;
;	puts the real drive number in tcbfdrv, and points si to the real;
;	DIB structure.							;
;									;
;	If the unit is directed to a "different" drive, calls the	;
;	ROM BIOS to print a switch disk message, then waits for a key	;
;	to be pressed.  Loads a new BPB if the command code was neither	;
;	media check nor build bpb.					;
;									;
;	ax == unit # * 2						;
;	bx == address of subfunction code				;
;	dl == drive number given to driver by caller			;
;	si -> DIB for drive						;
;	Return values are set in the Request Header			;
;	No global data affected						;
;	No global procedures called					;
;	dl, ax, si changed						;
;-----------------------------------------------------------------------;

logtrans	proc	near

	mov	ah,[si].DIBrdn	; check for redirection
	or	ah,ah		; is it redirected?
	jnz	log10		; if redirected
	ret			; if not redirected

;	Translate input drive number into real drive number

log10:
	mov	dl,ah
	dec	dl		; 1 means drive 0, 2 means drive 1, etc.
	mov	[tcbfdrv],dl	; dl has real drive number
	mov	si,[si].DIBrdb	; get real DIB pointer
	shr	al,1		; get original unit number back
	cmp	al,[si].DIBldn
	jne	log20		; if using different drive number
	ret

;	Prompt user to put right disk in drive

log20:
	mov	[si].DIBldn,al		; set new "current" drive
	or	[si].DIBatt,DISKSWAP	; make sure we load a new BPB
	mov	ah,[drvn]
	and	ah,0f0h			; change drive number for message
	add	ah,al			; to the one in al
	inc	ah			; add 1 for 0/1 bias
	mov	[drvn],ah		; new drive number for message
	mov	ax,offset switchmsg
	call	prtstr			; print the switch message
	
	xor	ax,ax			; zero ah
	int	016h			; wait for the key press
					; don't return until one found
	cmp	bx,offset fbldbpb	; is this media check or bldbpb?
	jbe	log30			; if no reason for settype call
	call	settype			; get the disk type
log30:
	ret
logtrans	endp

	subttl	prtstr -- print string on user's console

	page
;-----------------------------------------------------------------------;
; prtstr								;
;									;
; Print a string on user's console.  Uses ROM BIOS call 0eh to print	;
; the string one character at a time.  The string must be terminated	;
; by a null (0) byte.  The character will be printed white on a black	;
; background on color systems, normal attributes on monochrome.		;
;									;
;  On Entry:								;
;	ds:ax points to the string to print.				;
;  On Exit:								;
;	string printed							;
;									;
;  Global data affected: none						;
;  Global procedures called: none					;
;  No registers are changed						;
;-----------------------------------------------------------------------;

prtstr proc	near
	push	ax
	push	bx
	push	si
	cld
	mov	si,ax
	mov	bl,07h		; white foreground, black background
prt10:
	lodsb
	or	al,al		; last character?
	jz	prt20		; if end of string
	mov	ah,0eh		; function 0eh, write TTY to current page
	int	010h		; write the character
	jmp	prt10		; do it again
prt20:
	pop	si
	pop	bx
	pop	ax
	ret
prtstr endp

	subttl	MEDCK - Media Check

	page
;-----------------------------------------------------------------------;
;	This routine processes the Media Check call (=1)		;
;									;
;	No parms passed							;
;	Return values are set in the Request Header			;
;	No global data affected						;
;	No global procedures called					;
;	ES:BX used to point to RH					;
;-----------------------------------------------------------------------;

fmedck	proc	near

	call	logtrans			; do drive reassignment
	les	bx,dword ptr [wsblkhdr]	; Get pointer to RH
	test	[si].DIBatt,DIRTYBPB
	jnz	med20				; if we must load new BPB
	test	[si].DIBatt,DISKSWAP
	jnz	med35				; if we should return "maybe"
	call	timetest			; return al = 0 or 1 
	les	bx,dword ptr [wsblkhdr]	; Get pointer to RH
	or	al,al				; disk change?
	jnz	med40				; if < 2 seconds after success

	test	[si].DIBatt,DTCHGLN		;Rod  Change line available?
	jz	med40				;Rod  No, jump

	mov	ah,16h
	mov	dl,[tcbfdrv]			; get drive number back
	int	DISKINT				; ask BIOS about change line
	cmp	ah,0
	jz	med05				; if change line in-active
	push	bx
	mov	bl,[tcbfdrv]
	xor	bh,bh
	mov	byte ptr [media13+bx],'N'
	pop	bx
	jmp	med10
med05:
	mov	al,1				; return "no change"
	push	bx
	mov	bl,[tcbfdrv]
	xor	bh,bh
	cmp	byte ptr [media13+bx],'Y'	; test to see if INT 13 detect
	jne	med06
	mov	al,0				; return "maybe"
	mov	byte ptr [media13+bx],'N'	; reset INT 13 detection
med06:	
	pop	bx
	jmp	short med40			; exit 
med10:
	mov	ah,es:[bx].drqmd		; old media descriptor
	cmp	ah,[si].DIBmb			; same as current one?
	je	med30				; if still same
med20:
	lea	ax,[si].DIBlbl
	mov	word ptr es:[bx].drqlbl,ax	; offset of volume ID expected
	mov	word ptr es:[bx+2].drqlbl,ds	;rs1 
	mov	al,-1				; we think media changed
	jmp	short med40			; return "changed"
med30:
	mov	di,offset grp:lblbuf
	call	getlabel			; get current label
	jnc	med32				; if no error
	push	di				; balance stack
	jmp	fdskerr				; return error code
med32:
	push	si
	push	es
	push	ds
	pop	es
	lea	si,[si].DIBlbl			; old label address
	mov	cx,LBLSIZ
repe	cmpsb					; look for match
	pop	es
	pop	si
	jnz	med20				; if different labels
med35:
	mov	al,0				; if same labels, not sure
med40:
	and	[si].DIBatt,not (DIRTYBPB or DISKSWAP)
						; taken care of dirty BPB &
						; disk swap
	mov	es:[bx].drqrtcd,al		; 1=not changed, 0=not sure
	mov	es:[bx].drqsta,0100H		; Return with 'DONE'
	ret

fmedck	endp

	page
timeset proc	near
	push	es
	push	ax
	mov	ax,0040h			; SAH access bios
	mov	es,ax
	mov	ax,es:[006ch]
	mov	[si].DIBtiml,ax
	mov	ax,es:[006eh]
	mov	[si].DIBtimh,ax
	pop	ax
	pop	es
	ret
timeset endp

timetest proc	near
	mov	ax,0040h			; SAH access bios
	mov	es,ax
	mov	ax,es:[006ch]
	mov	dx,es:[006eh]
	sub	ax,[si].DIBtiml		; compute elapsed timer ticks
	sbb	dx,[si].DIBtimh
	jnz	ttover
	cmp	ax,36			; jump if more than 2 seconds
	ja	ttover
	mov	al,1			; diskette cannot have been changed
	ret
ttover:
	mov	al,0			; diskette could have been changed
	ret
timetest endp

	subttl	getlabel -- get label from current disk

	page
;-----------------------------------------------------------------------;
; getlabel								;
;									;
; Reads label from disk in specified drive.  Calculates directory	;
; sector number from information in DIB.  Reads directory in one sector	;
; at a time until it finds the drive label entry.  If the label is	;
; found, it is read into the buffer pointed to by di.			;
;									;
;  On Entry:								;
;	dl contains disk number						;
;	si->DIB for drive						;
;	di->buffer for label						;
;  On Exit:								;
;	CY clear if no error searching for label			;
;	CY set if error searching for label				;
;	if CY set, ah contains error code from ROM BIOS			;
;									;
;  Global data affected: none						;
;  Global procedures called: none					;
;  ax changed								;
;-----------------------------------------------------------------------;

getlabel proc	near
	push	bx
	push	cx
	push	dx
	push	es

	mov	[tcbfdrv],dl	; save drive number

;	How many entries in directory?

	mov	cx,[si].DIBdent	; max root directory entries allowed
	mov	[dircnt],cx

;	Where does directory start?
getl10:
	mov	al,[si].DIBnfat	; number of file allocation tables
	cbw
	mul	[si].DIBspf	; sectors of FAT
	add	ax,[si].DIBrsc	; reserved sectors

;	ax contains the first directory sector number.
;	Search the directory for the disk label.

	push	si		; save DIB pointer
getl20:
	call	getsec		; get the indicated sector (in ax)
	jc	getl30		; if we couldn't read the sector
	call	srchsec		; search the sector for the disk label
	jc	getl40		; if label found (or we have given up)
	inc	ax		; try next sector
	jmp	getl20

;	Label search failed, return LBLSIZ NULL bytes for label.

getl30:
	call	zlbl		; zero out LBLSIZ bytes of sector buffer
	stc			; indicate error
	jmp	short getl50	; leave without clearing carry
getl40:
	or	ax,ax		; clear carry flag
getl50:
	pop	si		; restore DIB pointer

	pop	es
	pop	dx
	pop	cx
	pop	bx
	ret
getlabel endp

	subttl	getsec -- get sector from disk

	page
;-----------------------------------------------------------------------;
; getsec								;
;									;
; Get a sector from the disk into secbuf.  The logical sector number to	;
; read is in ax.  If an error occurs while reading, sets the carry flag.;
;									;
;  On Entry:								;
;	ax contains logical sector number.				;
;	bx equal to 1 if buffer address should be loaded from secbuf	;
;	else es:bx points to disk buffer				;
;	es points to disk buffer					;
;  On Exit:								;
;	CY clear if sector read OK.					;
;	CY set if sector could not be read.				;
;	if error, ah contains error code from BIOS			;
;									;
;  Global data affected: none						;
;  Global procedures called: none					;
;  ax changed								;
;-----------------------------------------------------------------------;

getsec 	proc	near
	push	bx
	push	cx
	push	dx
	push	di
	push	es

	les	bx,dword ptr [secbuf]	; read into sector buffer
	call	CalcAbs		; get absolute disk location
	mov	dl,[tcbfdrv]	; and drive number
	mov	[typrtr],3	; 3 retries
gets10:
	mov	ax,0201h	; read 1 sector
	int	DISKINT
	jnc	gets40		; if successfully read sector
	push	ax
	xor	ah,ah		; reset drive on timeout
	int	DISKINT
	pop	ax
	test	ah,80h		; no retires if time out
	jnz	gets20
	dec	[typrtr]	; through retries?
	jnz	gets10		; no try to read one more sector
	
gets20:		; return with error after all retries
	stc
gets40:
	pop	es
	pop	di
	pop	dx
	pop	cx
	pop	bx
	ret
getsec endp

	subttl	srchsec -- search a directory sector for label

	page
;-----------------------------------------------------------------------;
; srchsec								;
;									;
; Search directory sector for volume label.  Directory entries are 32	;
; bytes long.  The 12th byte (offset 11) in the entry is the attribute  ;
; byte.  If bit	3 of the attribute is set, the entry is a volume label.	;
; The routine will terminate on finding the volume label with the	;
; label in the first LBLSIZ bytes of the sector buffer.			;
;									;
; If the label is not found & directory entry starting in 0 is found,	;
; the routine will copy zeroes to the beginning of the sector buffer &	;
; act as if it had found a label (terminating search).			;
;									;
;  On Entry:								;
;	if bx contains 1, secbuf -> sector to search for volume label.	;
;	if bx is not 1, es:bx -> sector to search for volume label	;
;	si -> DIB for disk						;
;	di -> buffer for label (assumed to be in ds).			;
;	es same as cs & ds						;
;  On Exit:								;
;	if CY clear, no label found.					;
;	if CY set, label found & in first LBLSIZ bytes of secbuf.	;
;									;
;  Global data affected: secbuf						;
;  Global procedures called: none					;
;  No registers are changed						;
;-----------------------------------------------------------------------;

srchsec proc	near
	push	ax
	push	bx
	push	cx
	push	di
	push	si
	push	es

	les	bx,dword ptr [secbuf]	; point es:bx at sector
	mov	ax,[si].DIBbps	; bytes per sector
	mov	cl,5
	shr	ax,cl		; directory entries per sector = bps/32
	mov	cx,ax		; cx is loop count
	jcxz	srch30		; if no entries in sector
srch10:
	test	byte ptr es:[bx+11],08h	; is this the volume label?
	jnz	srch20		; if really the label
	cmp	byte ptr es:[bx],0	; is first byte a null?
	jz	srch30		; pretend we found entry
	add	bx,32		; next directory entry
	dec	[dircnt]	; take one out of total count
	loopnz	srch10
	cmp	[dircnt],0	; end of search?
	jz	srch30		; if end, return 0 label
	clc
	jmp	short srch50	; no label found, exit
srch20:
	mov	cx,LBLSIZ	; copy LBLSIZ bytes to wherever
	mov	si,bx		; now si points to the label
	push	ds
	push	es
	pop	ds
	pop	es
	cld
	rep	movsb		; copy label into ds:di
	push	es
	pop	ds
	jmp	short srch40	; exit & say label found
srch30:
	call	zlbl		; return with no label
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

	subttl	zlbl -- zero out first LBLSIZ bytes of label

	page
;-----------------------------------------------------------------------;
; zlbl									;
;									;
; Zeroes out first LBLSIZ bytes of label buffer pointed to by di.	;
; Called by getlabel function.						;
;									;
;  On Entry:								;
;	di->buffer containing label to zero.				;
;  On Exit:								;
;	nothing:							;
;									;
;  Global data affected: data pointed to by es:di			;
;  Global procedures called: none					;
;  No registers are changed						;
;-----------------------------------------------------------------------;

zlbl proc	near
	push	ax
	push	di

	push	ds		;rs1
	pop	es

	xor	ax,ax
	cld
	mov	cx,LBLSIZ
	rep	stosb

	pop	di
	pop	ax
	ret
zlbl endp

	assume	es:nothing

	subttl	BLDBPB - Build BIOS Parm Block

	page
;-----------------------------------------------------------------------;
;	This routine processes the Build BIOS Parameter Block call (=2)	;
;									;
;	No parms passed							;
;	Return values are set in the Request Header			;
;	No global data affected						;
;	No global procedures called					;
;	ES:BX used to point to RH					;
;-----------------------------------------------------------------------;

fbldbpb	proc	near

	call	logtrans			; do drive reassignment
	push	di

	les	bx,dword ptr [wsblkhdr]	; Get pointer to RH
	test	[si].DIBatt,LOADBPB		; load BPB from disk?
	jz	bld05				; if just use BPB in DIB
	call	settype				; get type for this disk
bld05:
	lea	di,[si].DIBlbl
	jc	bld07				; if settype called & set CF
	and	[si].DIBatt, not FIRSTBPB	; clear first time flag
	call	getlabel			; get disk label
	jmp	short bld08
bld07:
	call	zlbl				; if can't get label
ifdef	RETURNBAD
	jmp	short bld10			; if bad media
endif

;	BPB pointer is in si.
bld08:
	les	bx,dword ptr [wsblkhdr]	; Get pointer to RH
	mov	word ptr es:[bx].drqbpbp,si	; Set BPB pointer offset (si)
	mov	word ptr es:[bx+2].drqbpbp,ds	;rs1 
	mov	es:[bx].drqsta,100H		; Return 'Done'

ifdef	RETURNBAD
	jmp	short bld20
bld10:
	test	[si].DIBatt,FIRSTBPB		; if first time, don't return
						; error
	jnz	bld08
	les	bx,dword ptr [wsblkhdr]	; Get pointer to RH
	mov	es:[bx].drqsta,8007H		; Return 'bad media'
bld20:
endif

	pop	di
	ret

fbldbpb	endp

	subttl	settype -- determine disk type

	page
;-----------------------------------------------------------------------;
; settype								;
;									;
; Determines disk type for a given disk.  First tries to read track 0,	;
; sector 0, which contains a BPB for the disk.  If that fails, calls	;
; determine floppy type function in the ROM BIOS (int 13h, function 15h);
; to figure out floppy type.						;
;									;
;  On Entry:								;
;	dl contains disk drive number to use				;
;	[maxdrv] contains the max disk number for the system		;
;  On Exit:								;
;	CY clear if type determined OK					;
;	CY set if type could not be determined				;
;									;
;  Global data affected: if drive type determined OK,			;
;	BPB1, BPB2, BPB3, or BPB4 will be changed.			;
;  Global procedures called: none					;
;  no registers changed							;
;-----------------------------------------------------------------------;

settype	proc
	push	ax
	push	bx
	push	cx
	push	dx
	push	si
	push	di
	push	es

;	Assume no error reading BPB

	and	[si].DIBatt,not BPBERR	; no error reading BPB

;	First try to read boot sector.

	xor	ax,ax		; read logical sector 0
	call	getsec		; get sector 0 (boot sector)
	jnc	set20		; if no error
	jmp	set60		; if read error, use defaulb BPB & say error

;	If DOS 2.0+, BPB is in boot sector.

set20:
	les	bx,dword ptr [secbuf]
	mov	ax,word ptr es:[bx+11]
	or	ax,ax			; see if bytes/sector is 0 or F6
	je	set30			; if bps == 0, no BPB table
	cmp	ax,0F6h
	je	set30
	mov	al,byte ptr es:[bx]
	cmp	al,0EBh		; 3.0+ boot sectors start w/short jump
	je	set40		; if formatted on DOS 3.0+
	cmp	al,0E9h		; 2.0 & 2.1 start w/long jump
	je	set40

;	DOS 1.x format (AACK!).  Read first byte of FAT.

set30:
	mov	ax,1		; FAT starts in logical sector 1.
	call	getsec
	jc	set60		; if read error, quit this foolishness.

;	Determine disk type from first byte in FAT.

	mov	al,es:[bx]	; get media ID byte from FAT

	push	ds		;rs1
	pop	es

	mov	cx,FAlen	; scan FATarr table for FAT ID we want
	mov	di,offset FATarr
	repne	scasb		; cx will be decremented for each byte EXAMINED
	jnz	set60		; if no match, use default, return error

;	Determine BPB to use based on # bytes examined.

	neg	cx
	add	cx,FAlen	; FAlen - bytes examined
	dec	cx		; want range of 0-FAlen-1, not 1-FAlen
	mov	ax,size BPB

	push	dx		; save dx around multiply
	mul	cx		; make search count into BPB offset
	pop	dx

	mov	si,offset BPBarr
	add	si,ax		; es:si points to the right BPB
	push	ds		; copy code wants a ds on the stack
	jmp	short set50	; copy new BPB into DIB
	
;	copy the BPB to the disk's BPB.

set40:
	push	ds
	push	ds
	push	es
	pop	ds		; ds & es point to right stuff
	pop	es
	
	assume	ds:nothing,es:grp	;rs1

	lea	si,[bx+11]	; copy sector to local stuff & skip 11 bytes
set50:
	xor	dh,dh		; make disk number a word
	mov	di,dx
	mov	ax,size DIB
	mul	di		; get offset in DIB array
	mov	di,ax
	add	di,offset BPB1
	push	di		; save for after move
	mov	cx,offset DIBdbps	; length of BPB region
	rep	movsb		; copy the BPB
	pop	si
	pop	ds

	assume	ds:grp,es:nothing	;rs1

	mov	ax,[si].DIBspt	; get sectors per track
	mov	cx,[si].DIBhds	; number of heads
	cmp	cx,1		; how many heads?
	jne	set53		; if not 1 side, set up for double sided

;	Set up for single sided disk.
;	Sectors/cylinder == sectors/track, & use head mask which always
;	decides to use head 0.

	xor	cx,cx		; head mask for the DIB
	jmp	short set55

;	Set up for double sided disk.

set53:
	add	ax,ax		; sectors/cylinder = 2 * sectors/track
	mov	cx,1		; use low bit of remainder for head mask
set55:
	mov	[si].DIBspc,ax	; sectors/cylinder = hds * sectors/track
	mov	[si].DIBhdmsk,cx	; store head mask
	test	[si].DIBatt,BPBERR	; error reading the BPB?
	jnz	set95			; if there really was a problem
	clc			; type set OK
	jmp	short set100	; exit OK
set60:

;	Use default BPB from DIB.

	push	ds
	push	ds
	pop	es			; point es at our ds
	or	[si].DIBatt,BPBERR	; error reading BPB
	lea	si,[si].DIBdbps	; default BPB address
	jmp	set50		; copy into proper DIB structure

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
settype	endp

	subttl	IOCTLI - I/O Control Input

	page
;-----------------------------------------------------------------------;
;	This routine processes the IOCTL Input call (=3)		;
;									;
;	No parms passed							;
;	Return values are set in the Request Header			;
;	No global data affected						;
;	No global procedures called					;
;	ES:BX used to point to RH					;
;-----------------------------------------------------------------------;

fioctli	proc	near

	les	bx,dword ptr [wsblkhdr]	; Get pointer to RH
	mov	es:[bx].drqsta,8103H		; Return 'Unknown Command'
	ret

fioctli	endp

	subttl	INPUT - Input read

	page
;-----------------------------------------------------------------------;
;	This routine processes the input read call (=4)			;
;									;
;	No parms passed							;
;	Return values are set in the Request Header			;
;	No global data affected						;
;	No global procedures called					;
;	ES:BX used to point to RH					;
;-----------------------------------------------------------------------;

finput	proc	near
	mov	[BIOSfun],2	; BIOS function 2 - Read
outentry:
	call	logtrans		; logical drive translation
	push	di
	les	bx,dword ptr [wsblkhdr]	; Get pointer to RH
	lea	ax,[si].DIBlbl
	mov	word ptr es:[bx].drqelbl,ax	; volume ID expected
	mov	word ptr es:[bx+2].drqelbl,ds	;rs1 
	mov	ax,es:[bx].drqsect		; Get sector count
	mov	[Sectcnt],ax			; Save total count for IO
	mov	ax,es:[bx].drqstrt	; Starting sector number (logical)
	mov	[Sectstr],ax		; Save for loop with large IO
	les	bx,es:[bx].drqta	; Get transfer address
IOCont:
	mov	cx,3			; 3 retries
DiskIO:
	push	cx		; save retry count
	mov	ax,[Sectstr]	; Get starting logical sector
	call	CalcAbs		; Calculate absolute disk loc. from logical
	mov	dl,[tcbfdrv]	; Disk drive to use
	push	bx		; Save buffer pointer
	mov	bx,[Sectcnt]	; # sectors IO
	xor	ah,ah
	mov	al,byte ptr [si].DIBspt		; Max per IO +1
	inc	al
	sub	al,cl		; Calc # sectors til end of track (this head)
	cmp	ax,bx		; Enough?
	jb	IOpart		; No, must do some more IO later
	mov	ax,bx		; Yes, just what is needed
IOpart:
	mov	di,ax		; Save IO count
	pop	bx		; Restore buffer pointer
	mov	ah,[BIOSfun]	; BIOS disk function
	int	DISKINT
	jnc	IOok
	
	pop	cx
	push	ax		; save error in case abort
	xor	ah,ah		; reset drive before return		RKG005
	int	DISKINT
	pop	ax		; restore err code
	test	ah,80h		; no retries if timeout
	jnz	xxx1
	loop	diskIO		; for all retries
xxx1:
	jmp	fdskerr		; timeout or retries exhausted

IOok:
	pop	cx		; Clear retry count from stack
	call	timeset		; Save timer value at last I/O
	add	[Sectstr],di	; Update new starting sector
	sub	[Sectcnt],di	; Update amount of IO
	jz	endIO		; Yes, exit

	mov	ax,[si].DIBbps	; bytes per sector
	mul	di		; times sectors read/writ
	add	bx,ax		; Update new buffer pointer
	jmp	IOcont		; read next group
	
endIO:
	les	bx,dword ptr [wsblkhdr]	; Get pointer to RH
	mov	es:[bx].drqsta,100H		; Return 'Done'
	pop	di
	ret

finput	endp

	subttl	Disk Error Routine - Xlates BIOS error code
	page


;-----------------------------------------------------------------------;
; A Jump is made here if the BIOS returns a disk error during read or	;
; write.  The following are the error codes returned by the BIOS :	;
;									;
;	1H  - Bad command (never happen)				;
;	2H  - Address mark not found					;
;	3H  - Write protect disk					;
;	4H  - Sector not found						;
;	6H  - Media change (AT only)					;
;	8H  - DMA overrun						;
;	9H  - DMA across 64k boundary					;
;	10H - Bad CRC on disk read					;
;	20H - Bad NEC controller					;
;	40H - Seek operation failed					;
;	80H - Time out							;
;									;
; The following error codes may be returned by the device driver:	;
;									;
;	0H  - Write protect violation					;
;	1H  - Unknown unit						;
;	2H  - Device not ready						;
;	3H  - Unknown command						;
;	4H  - CRC error							;
;	5H  - Bad drive request structure length			;
;	6H  - Seek error						;
;	7H  - Unknown media						;
;	8H  - Sector not found						;
;	9H  - Printer out of paper					;
;	0AH - Write fault						;
;	0BH - Read fault						;
;	0CH - General failure						;
;	0DH - Reserved							;
;	0EH - Reserved							;
;	0FH - Invalid disk change					;
;-----------------------------------------------------------------------;
	
	; errtbl moved into gdata by MJS 4/11/88
	; dskerrtb expanded to handle BIOS err 0Ah 			RKG001
	; same table for hard and floppy disk				to end
	
	public	dskerrtbl
	
dskerrtbl label byte
	;	  x   1   2   3   4   x   6   x
	db	0Ch,0Ch,0Ch,00H,08H,0Ch,0FH,0Ch
	;	  8   9   A   x   C   x   x   F
	db	0Ch,0Ch,0Ch,08H,0Ch,0Ch,0Ch,0Ch
	;	 \/  10  20   x  40   x   x   x
	db	    04H,0Ch,0Ch,06H,0Ch,0Ch,0Ch
	;	 80  90  A0  B0  C0  D0  E0  F0
	db	02h,0Ch,0Ch,0Ch,0Ch,0Ch,0Ch,0Ch
	
	public	diskerr		; Merged disk error routine		RKG001

fdskerr:			; Floppy disk error routine
	les	bx,dword ptr [wsblkhdr]	; Get pointer to RH
	; fall into diskerr

;	Enter	AH = BIOS INT 13 error code
;		ES:BX = address of request header
;		CS:DI = addr of translation table
;		[SP] = parmeter to pop before return
;	Exits	Driver Error code stored in Request header Status
;		Sector count optionally store in RH

;	******	DO NOT CALL   -   WITH 1 PARM ON STACK  -   JMP   FDSKERR  *****

diskerr:
	mov	di,offset dskerrtbl	; get table to use
	mov	al,ah
	xor	ah,ah		; BIOS err in ax
	cmp	al,10h
	jbe	err3
	
	shr	al,1		; Calc offset into error table
	shr	al,1
	shr	al,1		; Use upper 4 bits as index
	shr	al,1
	add	al,0Fh		; Note at least 1 in AL after shift
err3:
	add	di,ax
	mov	al,cs:[di]		; Get driver error code for return
	mov	ah,81H			; Error and Done bits
	
	mov	es:[bx].drqsta,ax	; Return error type
	cmp	es:[bx].drqcom,19	; a generic IOCTL call?
	je	err4			; if generic IOCTL, no sector count
	cmp	es:[bx].drqcom,1	; a media check call?
	je	err4			; if media check, no sector count
	mov	ax,es:[bx].drqsect	; Get sector count
	sub	ax,[Sectcnt]		; Calc amount done
	mov	es:[bx].drqsect,ax	; Set sector count
err4:
	pop	di		; Restore original value		from beg
	ret			;					RKG001
	
	subttl	CalcAbs - Calculate Absolute sector

	page
;-----------------------------------------------------------------------;
;	This routine will calculate the absolute disk location from the	;
;	logical sector number.  The following formulas are used:	;
;									;
;		Sector = (logical MOD [DIBspt]) + 1			;
;		Track  = INT (logical/[DIBspc])				;
;		Head   = (INT (logical / [DIBspt])) MOD DIBhdmsk	;
;									;
;  On Entry:								;
;	AX = logical sector number					;
;									;
;  On Exit:								;
;	DH = head number						;
;	CH = track number						;
;	CL = sector number						;
;									;
;	No global data affected						;
;	No global procedures called					;
;									;
; 	CX & DX used to pass parms, all others unchanged		;
;-----------------------------------------------------------------------;

CalcAbs	proc	near
	push	ax

	push	ax		; Save starting sector
	xor	dx,dx
	div	[si].DIBspc	; Divide by sectors/cylinder
	mov	ch,al		; Set track #
	pop	ax		; Get starting sector
	xor	dx,dx
	div	[si].DIBspt	; Divide by sectors/track
	mov	cl,dl		; Set sector #
	inc	cl		; make it 1 relative
	and	ax,[si].DIBhdmsk		; AX MOD hdmsk
	mov	dh,al		; Set head #

	pop	ax
	ret

CalcAbs	endp

	subttl	NDINPUT - Nondestructive input no wait

	page
;-----------------------------------------------------------------------;
;	This routine processes the nondestructive input no wait call	;
;	(=5)								;
;									;
;	No parms passed							;
;	Return values are set in the Request Header			;
;	No global data affected						;
;	No global procedures called					;
;	ES:BX used to point to RH					;
;-----------------------------------------------------------------------;

fndinput equ	fioctli			;Rod

;-----------------------------------------------------------------------;
;	This routine processes the Input Status call (=6)		;
;									;
;	No parms passed							;
;	Return values are set in the Request Header			;
;	No global data affected						;
;	No global procedures called					;
;	ES:BX used to point to RH					;
;-----------------------------------------------------------------------;

finstat	equ	fioctli			;Rod

;-----------------------------------------------------------------------;
;	This routine processes the Input Flush call (=7)		;
;									;
;	No parms passed							;
;	Return values are set in the Request Header			;
;	No global data affected						;
;	No global procedures called					;
;	ES:BX used to point to RH					;
;-----------------------------------------------------------------------;

finflsh	equ	fioctli			;Rod

	subttl	OUTPUT - Output write

	page
;-----------------------------------------------------------------------;
;	This routine processes the Output write call (=8)		;
;									;
;	No parms passed							;
;	Return values are set in the Request Header			;
;	No global data affected						;
;	No global procedures called					;
;	ES:BX used to point to RH					;
;-----------------------------------------------------------------------;

foutput	proc	near

	mov	[BIOSfun],3	; BIOS function 3 - Write
	jmp	outentry	; Use same routines as 'Input' function

foutput	endp

;-----------------------------------------------------------------------;
;	This routine processes the Output with verify call (=9)		;
;									;
;	No parms passed							;
;	Return values are set in the Request Header			;
;	No global data affected						;
;	No global procedures called					;
;	ES:BX used to point to RH					;
;-----------------------------------------------------------------------;

foutver	equ	foutput			;Rod

	subttl	OUTSTAT - Output status

	page
;-----------------------------------------------------------------------;
;	This routine processes the Output status call (=10)		;
;									;
;	No parms passed							;
;	Return values are set in the Request Header			;
;	No global data affected						;
;	No global procedures called					;
;	ES:BX used to point to RH					;
;-----------------------------------------------------------------------;

foutstat equ 	fioctli			;Rod

;-----------------------------------------------------------------------;
;	This routine processes the Output flush call (=11)		;
;									;
;	No parms passed							;
;	Return values are set in the Request Header			;
;	No global data affected						;
;	No global procedures called					;
;	ES:BX used to point to RH					;
;-----------------------------------------------------------------------;

foutflsh equ	fioctli			;Rod

;-----------------------------------------------------------------------;
;	This routine processes the IOCTL Output call (=12)		;
;									;
;	No parms passed							;
;	Return values are set in the Request Header			;
;	No global data affected						;
;	No global procedures called					;
;	ES:BX used to point to RH					;
;-----------------------------------------------------------------------;

fioctlo	equ	fioctli			;Rod

	subttl	FDEVOPEN - Open Device

	page
;-----------------------------------------------------------------------;
;	This routine processes the Device Open call (=13)		;
;									;
;	No parms passed							;
;	Return values are set in the Request Header			;
;	No global data affected						;
;	No global procedures called					;
;	ES:BX used to point to RH					;
;-----------------------------------------------------------------------;

fdevopen proc	near

	call	logtrans			; do drive reassignment
	les	bx,dword ptr [wsblkhdr]	; Get pointer to RH
	mov	es:[bx].drqsta,0100H	; Return 'Done'
	ret

fdevopen endp

	subttl	FDEVCLOSE - Close Device

	page
;-----------------------------------------------------------------------;
;	This routine processes the Device Close call (=14)		;
;									;
;	No parms passed							;
;	Return values are set in the Request Header			;
;	No global data affected						;
;	No global procedures called					;
;	ES:BX used to point to RH					;
;-----------------------------------------------------------------------;

fdevclose proc	near

	les	bx,dword ptr [wsblkhdr]	; Get pointer to RH
	mov	es:[bx].drqsta,0100H	; Return 'Done'
	ret

fdevclose endp

	subttl	FREMOVE - Removable Media check

	page
;-----------------------------------------------------------------------;
;	This routine processes the Removable Media (=15)		;
;									;
;	No parms passed							;
;	Return values are set in the Request Header			;
;	No global data affected						;
;	No global procedures called					;
;	ES:BX used to point to RH					;
;-----------------------------------------------------------------------;

fremove	proc	near

	les	bx,dword ptr [wsblkhdr]	; Get pointer to RH
	mov	es:[bx].drqsta,0100H	; Return 'Done, Removable'
	ret

fremove	endp

	subttl	GENIOCTL - Generic I/O control

	page
;-----------------------------------------------------------------------;
;	This routine processes the generic IOCTL call (=19)		;
;                                                                       ;
;	It has 6 subfunctions:                                          ;
;                                                                       ;
;	sub 40h - Set Device Parameters                                 ;
;	sub 60h	- Get Device Parameters                                 ;
;	sub 41h - Write Track on Logical Device                         ;
;	sub 61h - Read Track on Logical Device                          ;
;	sub 42h - Format and Verify Track on Logical Device             ;
;	sub 62h - Verify Track on Logical Device                        ;
;									;
;	No parms passed							;
;	Return values are set in the Request Header			;
;	No global data affected						;
;	No global procedures called					;
;	ES:BX used to point to RH					;
;-----------------------------------------------------------------------;

fgenioctl proc	near

	les	bx,dword ptr [wsblkhdr]	; Get pointer to RH
	mov	cl,es:[bx].drqmin		; minor function code
	or	[si].DIBatt,DIRTYBPB		; make SURE media check
						; returns "changed"

	cmp	cl,SETPARMS
	je	fgen10
	cmp	cl,GETPARMS
	je	fgen20
	cmp	cl,WRTTRACK
	je	fgen30
	cmp	cl,RDTRACK
	je	fgen40
	cmp	cl,FVTRACK
	je	fgen50
	cmp	cl,VERTRACK
	je	fgen60
	mov	es:[bx].drqsta,8103H	; Return 'Unknown Command'
	ret

fgen10:
	jmp	fgsetparms
fgen20:
	jmp	fggetparms
fgen30:
	call	logtrans			; do drive reassignment
	jmp	fgwrttrack
fgen40:
	call	logtrans			; do drive reassignment
	jmp	fgrdtrack
fgen50:
	call	logtrans			; do drive reassignment
	jmp	fgfvtrack
fgen60:
	call	logtrans			; do drive reassignment
	jmp	fgvertrack
fgenioctl endp

	subttl	FGSETPARMS - generic I/O CTL set parameters

	page
;-----------------------------------------------------------------------;
;	This routine does the generic IOCTL set parameters call (=40h)	;
;									;
;	No parms passed							;
;	Return values are set in the Request Header			;
;	No global data affected						;
;	No global procedures called					;
;	cx, di changed							;
;	ES:BX used to point to RH					;
;-----------------------------------------------------------------------;

fgsetparms	proc	near

	les	bx,dword ptr [wsblkhdr]	; Get pointer to RH
	push	ds
	push	ds
	lds	bx,es:[bx].drqgirp		; pointer to IOCTL request
	pop	es				; es points to old ds
	push	si				; save si for later

	assume	ds:nothing
	assume	es:grp				;rs1

	mov	cx,[bx].gsptrack		; number of tracks in sector
	cmp	cx,MAXTRKTBL			; more than we can hold?
	ja	fgset50				; if too many
	jcxz	fgset05				; if none
	shl	cx,1				; tracks*2 == words in table
	inc	cx				; plus the track count
	lea	si,[bx].gsptrack		; source for copy
	mov	di,offset TrackTable		; destination for copy
	cld
	rep	movsw				; copy the track table

fgset05:
	pop	si

	call	makeftbl			; construct format table
						; from track table

	test	[bx].gspspe,2			; ignore all but track table?
	jnz	fgset20				; if ignore all else

;	Copy BPB to driver.

	push	si				; save si again
	test	[bx].gspspe,1			; default BPB or real BPB?
	jnz	fgset10				; if set real BPB

;	Copy default BPB into DIB.

	mov	cx,size BPB
	lea	di,[si].DIBdbps			; address of default BPB
	lea	si,[bx].gspbpb			; address of caller's BPB
	rep	movsb				; copy the default BPB
	pop	si
	pop	ds

	assume	ds:grp,es:nothing		;rs1

	or	[si].DIBatt,LOADBPB		; Load BPB from real media
	jmp	short fgset30			; exit function

;	Copy real BPB into DIB
fgset10:
	assume	ds:nothing,es:grp		;rs1

	mov	cx,size BPB
	mov	di,si				; copy into real BPB
	lea	si,[bx].gspbpb			; caller's BPB
	rep	movsb
	pop	si
	pop	ds
	and	[si].DIBatt,not LOADBPB		; don't load BPB from disk
	jmp	short fgset30			; exit function
fgset20:
	pop	ds
fgset30:
	assume	ds:grp,es:nothing	;rs1
	mov	ax,0100h		; "Done" status code
fgset40:
	les	bx,dword ptr [wsblkhdr] ; get request header back again
	mov	es:[bx].drqsta,ax	; Return 'Done'
	ret
fgset50:
	assume	ds:nothing,es:grp	;rs1
	pop	si
	pop	ds
	assume	ds:grp,es:nothing	;rs1
	mov	ax,8105h		; return "Error, bad structure length"
	jmp	fgset40			; return to caller
	
fgsetparms	endp

	subttl	MAKEFTBL - construct format table from track table

	page
;-----------------------------------------------------------------------;
;	This routine constructs the format buffer needed by the format	;
;	call to format a track.  It constructs this table from the	;
;	TrackTable.  If the track layout table is a format supported	;
;	by this routine, the BadLayout flag will be cleared.  If the	;
;	layout is not supported, the BadLayout is not supported.	;
;									;
;	No parms passed							;
;	Return values are set in the Request Header			;
;	BadLayout and FormatTable changed				;
;	No global procedures called					;
;	No registers changed						;
;	ES:BX used to point to RH					;
;-----------------------------------------------------------------------;

makeftbl proc	near

	push	ds
	push	cx
	push	bx
	push	ax
	push	si
	push	di

	MGetSCB ds		;rs1

	mov	si,offset TrackTable
	mov	di,offset FormatTable + 2	; only set second 2 bytes
	mov	[BadLayout],0	; assume layout is good
	cld

	lodsw
	mov	cx,ax		; number of sectors to set up for
	jcxz	mkft30		; if zero sectors
mkft10:
	lodsw			; sector number
	mov	bl,al		; will be low byte we store
	lodsw			; sector size

	mov	bh,2		; size code for 512 bytes/sector
	cmp	ax,512
	je	mkft20		; if good sector size

	mov	bh,0		; size code for 128 bytes/sector
	cmp	ax,128
	je	mkft20		; if good sector size

	mov	bh,1		; size code for 256 bytes/sector
	cmp	ax,256
	je	mkft20		; if good sector size

	mov	bh,3		; size code for 1024 bytes/sector
	cmp	ax,1024
	je	mkft20		; if good sector size

;	Bad sector size.

	mov	[BadLayout],1	; set bad layout flag
	mov	bh,2		; default sector size

;	Good sector size.
mkft20:
	mov	[di],bx		; set only sector number and size
	add	di,4		; skip to next location
	loop	mkft10		; do the next sector
	jmp	mkft40		; exit routine
mkft30:
	mov	[BadLayout],1	; bad track layout
mkft40:
	pop	di
	pop	si
	pop	ax
	pop	bx
	pop	cx
	pop	ds
	ret
makeftbl endp

	subttl	FGGETPARMS - generic I/O CTL get parameters

	page
;-----------------------------------------------------------------------;
;	This routine does the generic IOCTL get parameters call (=60h)	;
;									;
;	No parms passed							;
;	Return values are set in the Request Header			;
;	No global data affected						;
;	No global procedures called					;
;	ax, cx, di changed						;
;	ES:BX used to point to RH					;
;-----------------------------------------------------------------------;

fggetparms	proc	near

	les	bx,es:[bx].drqgirp		; pointer to IOCTL request
	push	si				; we use this later
	test	es:[bx].gspspe,1		; default BPB or real BPB?
	jz	fgget10				; if default BPB
	test	[si].DIBatt,LOADBPB		; should we load the BPB?
	jnz	fgget20				; if we don't need to load
						; the real BPB
	push	bx
	mov	bx,offset fggetparms		; set up registers for logtrans
	call	logtrans			; do drive reassignment
	pop	bx
	call	settype				; disk number is in dl
	jmp	short fgget20
fgget10:
	lea	si,[si].DIBdbps			; pointer to default BPB
	jmp	short fgget22			; don't load BPB
fgget20:
	call	settype				; load BPB from disk
fgget22:
	lea	di,[bx].gspbpb			; where to copy the BPB
	mov	cx,size BPB			; length of it in bytes
	cld
	rep	movsb				; copy into caller's buffer
	pop	si				; restore DIB pointer

	mov	al,[si].DIBatt			; get device attributes
	test	al,DTSMALL			;Rod  3.5" drive?
	jnz	fgget50				;Rod  Yes, jump
	test	al,DTHICAP			;Rod  1.2 Meg drive?
	jz	fgget30				;Rod  No, do 360K stuff

;	Return parameters for 1.2 meg drive

	mov	es:[bx].gspda,2			; removable, has change line
	mov	es:[bx].gspdt,1			; 1.2 meg floppy
	xor	al,al				; assume default media
	cmp	[si].DIBmb,0F9h			; current media 1.2 meg?
	je	fgget25				; if normal media
	inc	al				; if 360K floppy
fgget25:
	mov	es:[bx].gspncy,80		; 80 cylinders on 1.2M floppy
fgget27:
	mov	es:[bx].gspmt,al		; set media type
	jmp	short fgget40

;	Return parameters for 360K drive

fgget30:
	xor	ax,ax				; will write lots of zeroes
	mov	es:[bx].gspdt,al		; device type 0 (360K disk)
	mov	es:[bx].gspmt,al		; media type is default
	mov	es:[bx].gspncy,40		; 40 cylinders on 360K drive
fgget40:
	xor	ax,ax			;Rod  Set device attributes field
	test	[si].DIBatt,DTCHGLN	;Rod  Change line available?
	jz	fgget41			;Rod  No, skip
	or	al,02h			;Rod  Yes, turn on bit 1
fgget41:				;Rod
	mov	es:[bx].gspda,ax	;Rod  Bit 0 always indicates removable

	les	bx,dword ptr [wsblkhdr]	; regular request header again
	mov	es:[bx].drqsta,0100h		; return "Done"
	ret

;	Code to handle 3.5" diskette drives added by Rod:

fgget50	label	near 
	test	al,DTHICAP		; 1.44M drive?
	jnz	fgget55			; Yes, jump

;	720K Drive

	mov	es:[bx].gspdt,2		; 720k drive
	mov	es:[bx].gspncy,80	; 80 cylinders 
	mov	es:[bx].gspmt,0		; default media type
	jmp	fgget40

;	1.44 Meg Drive

fgget55	label	near
	mov	es:[bx].gspdt,7		; 1.44M drive
	mov	es:[bx].gspncy,80	; 80 cylinders 
	mov	es:[bx].gspmt,0		; default media type
	jmp	fgget40

;	End of Rod's 3.5" diskette code

fggetparms	endp

	subttl	FGWRTTRACK - generic I/O CTL Write Track

	page
;-----------------------------------------------------------------------;
;	This routine does the generic IOCTL Write Track call (=41h)	;
;									;
;	No parms passed							;
;	Return values are set in the Request Header			;
;	No global data affected						;
;	No global procedures called					;
;	ES:BX used to point to RH					;
;-----------------------------------------------------------------------;

fgwrttrack	proc	near

	mov	[BIOSfun],3			; BIOS function 3 - Write
	les	bx,dword ptr [wsblkhdr]	; Get pointer to RH
	les	bx,dword ptr es:[bx].drqgirp	; generic I/O request packet
	mov	ax,word ptr es:[bx].girta	; set transfer address
	mov	word ptr [giobuf],ax
	mov	ax,word ptr es:[bx+2].girta
	mov	word ptr [giobuf+2],ax

g_rventry:
	push	di				; save di before we munge it

;	Check starting sector.

	mov	ax,es:[bx].girstrt		; starting sector
	mov	[Sectstr],ax			; store for later
	cmp	ax,[TrackTable]			; is start sector too big?
	jb	fgwr10				; if start sector OK
	jmp	fgwrer1				; if start sector too big

;	Check sector count.
fgwr10:
	add	ax,es:[bx].girnsec		; total sector count
	cmp	ax,[TrackTable]
	jbe	fgwr20				; if sector count OK
	jmp	fgwrer1
fgwr20:
	mov	ax,es:[bx].girnsec
	jmp	short fgwr30			; continue checking arguments

g_fmtentry:
	push	di				; for stack rebalance
	mov	ax,[TrackTable+2]		; starting sector
	dec	ax				; make it 0-based
	mov	[SectStr],ax			; store for later
	mov	ax,[TrackTable]			; sectors to format

;	Store sector count.
fgwr30:
	mov	[SectCnt],ax

;	Check head number.

	push	dx
	mov	di,es:[bx].girhead		; check requested head number
	cmp 	di,[si].DIBhds			; head number above max?
	jae	fgwrer2				; if head number too big

;	Check cylinder number.

	mov	ax,[si].DIBsect			; total sectors
	xor	dx,dx
	mov	cx,[si].DIBspt			; sectors/track
	cmp	[si].DIBhds,1			; 1 or 2 sided
	je	fgwrer35			; if 1 sided
	shl	cx,1				; * 2 for sectors/cylinder
fgwrer35:
	div	cx				; get total cylinders
	pop	dx				; restore disk number
	mov	cx,es:[bx].gircyl
	cmp	cx,ax				; cylinder too big?
	jae	fgwrer3				; if cylinder number too big

;	Set up registers for I/O.

	mov	[typrtr],3			; retry count
	mov	ch,cl				; "track" (cylinder) number
	mov	cl,byte ptr [SectStr]		; starting sector number
	inc	cl				; 1-based sector number
	mov	ah,dl				; save disk number here
	mov	dx,di				; get head number in dl
	mov	dh,dl				; dh=head, dl=disk
	mov	dl,ah
	les	bx,[giobuf]			; where data lives

g_diskIO:
	mov	al,byte ptr [SectCnt]		; sector count
						; format ignores this
	mov	ah,[BIOSfun]			; function to perform
	int	DISKINT				; do it!
	jnc	g_IOok				; if no error doing I/O

;	reset drives and retry 	
	push	ax				; save error code	RKG005
	xor	ah,ah				; reset drives after err
	int	DISKINT				; 			RKG005
	pop	ax
	test	ah,80h				; test timeout err
	jnz	g_IO_err			; if timeout exit with retry
	
	dec	[typrtr]			; out of retries?
	jnz	g_diskIO			; no, try I/O again
g_IO_err:
	jmp	fdskerr				; return error to caller

;	The I/O call succeeded.

g_IOok:	
	call	timeset				; set last successful op time
	mov	ax,0100h			; return "Done"
g_IOex:
	les	bx,dword ptr [wsblkhdr]	; Get pointer to RH
	mov	es:[bx].drqsta,ax		; return status code
	pop	di
	ret

;	Error handlers.

fgwrer1:
	mov	ax,08108h			; return "sector not found"
	jmp	g_IOex
fgwrer2:
	pop	dx				; restore dx from push
fgwrer3:
	mov	ax,08103h			; return "Bad command"
	jmp	g_IOex

fgwrttrack	endp

	subttl	FGRDTRACK - generic I/O CTL Read Track

	page
;-----------------------------------------------------------------------;
;	This routine does the generic IOCTL read track call (=61h)	;
;									;
;	No parms passed							;
;	Return values are set in the Request Header			;
;	No global data affected						;
;	No global procedures called					;
;	ES:BX used to point to RH					;
;-----------------------------------------------------------------------;

fgrdtrack	proc	near

	mov	[BIOSfun],2			; BIOS function 2 - Read
	les	bx,dword ptr [wsblkhdr]	; Get pointer to RH
	les	bx,dword ptr es:[bx].drqgirp	; generic I/O request packet
	mov	ax,word ptr es:[bx].girta	; set transfer address
	mov	word ptr [giobuf],ax
	mov	ax,word ptr es:[bx+2].girta
	mov	word ptr [giobuf+2],ax
	jmp	g_rventry			; do the I/O

fgrdtrack	endp

	subttl	FGFVTRACK - generic I/O CTL format & verify track

	page
;-----------------------------------------------------------------------;
;	Generic IOCTL format & verify track call (=42h)			;
;									;
;	Return values are set in the Request Header			;
;	No global data affected						;
;	No global procedures called					;
;	ES:BX used to point to RH					;
;	Enter:	DS:SI => DIB struct					;
;		DX = drive?						;
;-----------------------------------------------------------------------;

fgfvtrack	proc	near
	les	bx,dword ptr [wsblkhdr]		; get pointer to Req Header
	les	bx,dword ptr es:[bx].drqgirp	; now generic I/O request packet

	mov	al,byte ptr [BadLayout]
	shl	al,1				; bad bit is bit 1, not 0
	or	al,1				; no funny layouts
	test	es:[bx].girspe,1		; just a status call?
	jnz	fgfv10				; exit if just status call

	test	al,2				; funny track layout?
	jz	fgfv11				; if layout OK
fgfv10:
	mov	es:[bx].girspe,al		; tell if layout OK
	les	bx,dword ptr [wsblkhdr]
	mov	es:[bx].drqsta,0100h		; return "Done"
	ret
fgfv11:

;	Set format type for ROM BIOS.

	xor	dh,dh			; this will be format type
	mov	ah,[si].DIBatt
	test	ah,DTSMALL		; 3.5" drive?
	jnz	fgfv350			; yes go to it

fgfv525:
	mov	cx,2709h		; get tracks, sectors/track
	inc	dh			; drive type 1 = 360K
	mov	di,offset pcdprm	; get 360K drive params
	test	ah,DTHICAP		; 1.2 Meg drive?
	jz	fgfvdasd		; no finished with 360K

	mov	di,offset atdprm	; change to 1.2M disk params
	inc	dh			; 1.2M drive
	mov	[di].dpfmgap,50h	; format gap for 360K in 1.2M drive
	cmp	byte ptr [si].DIBmb,0F9h; 1.2 meg floppy?
	jne	fgfvdasd		; no 360 in 1.2M done

	inc	dh			; 1.2 floppy in 1.2 drive
	mov	cx,4f0fh		; 80 cylinders, 15 sectors/track
	mov	[di].dpfmgap,54h	; gap length
	jmp	short fgfvdasd


;	Prepare to format a 3.5" diskette track

fgfv350:
	mov	dh,4			; 720K format type
	mov	cx,4F09h		; cylinders and sectors/track
	mov	di,offset psdprm	; get default disk parms
	test	ah,DTHICAP		; 720K drive?
	jz	fgfvdasd
	cmp	byte ptr [si].DIBmb,0F9h; 720K media?
	jz	fgfvdasd
	mov	cl,18			; 1.44 drive and media
	jmp	short fgfvmedia

;	*** Zenith does't reset disk change line on Function 18
;	*** It does reset line on Function 17.  Function 17 is
;	*** executed and then 18.  Both may return errors
	
;	CH,CL = cylinders, sectors
;	AH = drive type
;	DI = diskette parameters
;	DH = media type
;	DL = drive
;	ES:BX = Request header
;	SI = DIB

fgfvdasd:
	mov	[di].dpeot,cl		; set sectors/track in disk parms
	mov	al,dh			; save disk type in dh
	mov	ah,17h
	int	DISKINT			; set DASD type for format
					; Error or not continue
					
fgfvmedia:	; set media types (esp. 1.44) get BIOS diskette parms
	push	es			; save RH segment on stack
	mov	byte ptr [TrackTable],cl; set for table construction
	mov	ax,ds
	mov	es,ax			; get seg of diskprms in ES
	; ES:DI = disk parameters
	mov	ah,18h			; set Media for Format
	int	DISKINT			; returns Disk Parameters
	jnc	fgfvparm		; got diskette parms
	
	test	dh,dh			; is function 18 necessary ie. 1.44
	jnz	fgfvparm		; no use our disk parms
	mov	ah,0			; reset drives and try again
	int	DISKINT
	mov	ah,18h
	int	DISKINT
	jnc	fgfvparm		; succeeded
	jmp	fdskerr			; 1.44 meg errored on BIOS call
	
fgfvparm:	; ES:DI => Diskette parms for format!!
	; save INT 1E vector and place our parm ptr there
	mov	cx,es
	xor	ax,ax			; get vector segment
	mov	es,ax
	xchg	di,es:[INT1E]		; set format diskette parameters
	xchg	cx,es:[INT1E+2]
	pop	es			; pop RH segment before pushes
	push	cx			; and save old parm pointer
	push	di
		
	mov	al,byte ptr es:[bx].gircyl	; get cylinder number
	mov	ah,byte ptr es:[bx].girhead	; and head number
	call	setftbl			; set up format table for 
	
	mov	word ptr [giobuf],offset FormatTable
	mov	word ptr [giobuf+2],ds	; pointer to data - format descripts
	mov	[BIOSfun],5		; BIOS function 5 - Format

	call	g_fmtentry		; format the track

;	If the operation succeeded, the error bit in the driver request
;	block will be reset.  es:bx will be left pointing to the main
;	driver request block at this point, so we can conveniently test
;	for an error.

	test	es:[bx].drqsta,8000h	; did an error occur?
	jnz	fgfvxit			; if error restore parms/exit
	les	bx,dword ptr es:[bx].drqgirp	; generic I/O request packet
	mov	[BIOSfun],4		; BIOS function 4 - Verify
	call	g_fmtentry		; verify the track

fgfvxit:				; restore default disk parms
	xor	ax,ax
	mov	es,ax			; restore diskette parameters
	pop	es:[INT1E]
	pop	es:[INT1E+2]
	ret
	
fgfvtrack	endp

	subttl	setftbl - construct format table from track table

	page
;-----------------------------------------------------------------------;
;	This routine constructs the format buffer needed by the format	;
;	call to format a track.  It constructs this table from the	;
;	TrackTable.  If the track layout table is a format supported	;
;	by this routine, the BadLayout flag will be cleared.  If the	;
;	layout is not supported, the BadLayout is not supported.	;
;									;
;	al contains cylinder number to format				;
;	ah contains head number for track to format			;
;	FormatTable changed						;
;	No global procedures called					;
;	No registers changed						;
;	ES:BX used to point to RH					;
;-----------------------------------------------------------------------;

setftbl	proc	near

	push	es
	push	cx
	push	di

	push	ds		;rs1
	pop	es

	mov	di,offset FormatTable
	cld

	mov	cx,[TrackTable]	; number of sectors to set up for
	jcxz	stft20		; if zero sectors
stft10:
	stosw			; set cylinder number and head number
	add	di,2		; skip second two bytes
	loop	stft10		; next entry
stft20:
	pop	di
	pop	cx
	pop	es
	ret
setftbl	endp

	subttl	FGVERTRACK - generic I/O CTL verify track

	page
;-----------------------------------------------------------------------;
;	This routine does the generic IOCTL verify track call (=62h)	;
;									;
;	No parms passed							;
;	Return values are set in the Request Header			;
;	No global data affected						;
;	No global procedures called					;
;	ES:BX used to point to RH					;
;-----------------------------------------------------------------------;

fgvertrack	proc	near

	mov	[BIOSfun],4			; BIOS function 4 - Verify
	les	bx,dword ptr [wsblkhdr]	; Get pointer to RH
	les	bx,dword ptr es:[bx].drqgirp	; generic I/O request packet

	cmp	[BadLayout],0			; funny track layout?
	jz	fgve20				; if layout OK
	or	es:[bx].girspe,3
fgve10:
	les	bx,dword ptr [wsblkhdr]
	mov	es:[bx].drqsta,0100h		; return "Done"
	ret
fgve20:
	test	es:[bx].girspe,1		; just a status call?
	mov	es:[bx].girspe,1		; say layout OK
	jnz	fgve10				; exit routine

;	The contents of giobuf are irrelevant, since verify ignores es:bx.

	jmp	g_fmtentry			; do the I/O

fgvertrack	endp

	subttl	GETLOG - Get Logical Device

	page
;-----------------------------------------------------------------------;
;	This routine processes the Get Logical Device call (=23)	;
;									;
;	No parms passed							;
;	Return values are set in the Request Header			;
;	No global data affected						;
;	No global procedures called					;
;	ES:BX used to point to RH					;
;-----------------------------------------------------------------------;

fgetlog	proc	near

	les	bx,dword ptr [wsblkhdr]	; Get pointer to RH
	mov	si,[si + DIBrdb]		; get DIB for real drive
	mov	al,[si + DIBldn]		; last logical number used
        add     al,[startd]                     ;jrbr (+ starting drive)
        mov     es:[bx].drquni,al               ;jrbr
	mov	es:[bx].drqsta,100H		; Return 'Done'
	ret

fgetlog	endp

	subttl	SETLOG - Set Logical Device

	page
;-----------------------------------------------------------------------;
;	This routine processes the Set Logical Device call (=23)	;
;									;
;	No parms passed							;
;	Return values are set in the Request Header			;
;	No global data affected						;
;	No global procedures called					;
;	ES:BX used to point to RH					;
;-----------------------------------------------------------------------;

fsetlog	proc	near

	mov	si,offset BPB1			; set next logical device used
	les	bx,dword ptr [wsblkhdr]	; Get pointer to RH
	mov	al,es:[bx].drquni
	xchg	[si + DIBldn],al		; set next drive number used
        add     al,[startd]                     ;jrbr (+ starting drive)
        mov     es:[bx].drquni,al               ;jrbr
	mov	es:[bx].drqsta,100H		; Return 'Done'
	ret

fsetlog	endp

fendres	label	byte

	subttl	INITBLK - Init driver

	page
;-----------------------------------------------------------------------;
;	This routine will initialize the block device driver.		;
;									;
;	Parms passed							;
;	Return values							;
;	Global data affected						;
;	Global procedures called					;
;	What registers are changed					;
;-----------------------------------------------------------------------;

finitblk	proc	near

	mov	ah,0
	mov	dx,32 + 1	; want 32 paragraphs allocated + prefix
	push	es
	call	mosheman
	mov	ax,es
	inc	ax		; don't wax the heap prefix
	mov	[secbuf+2],ax	; store sector buffer segment address
	xor	ax,ax
	mov	[secbuf],ax	; store sector buffer offset
	call	isdrive		; count disk drives
	pop	es

	mov	al,[maxdrv]
	or	al,al		; cmp al,0
	jnz	fini10		; if no drives or > 1 drive

;	1 drive on system, prepare for drive redirection.
;	al contains 0.

	mov	si,offset BPB1	; parameters for "A" drive
	mov	di,offset BPB2	; parameters for "B" drive
	mov	[si + DIBrdb],si	; DIB to use for both drives
	mov	[bpbpntr + 2],si	; change BPB pointer for B to point
					; to A
	mov	[di + DIBrdb],si
	mov	[si + DIBldn],al	; 0 => last drive number used was A
	inc	al
	mov	[si + DIBrdn],al	; set redirected drive number to A
	mov	[di + DIBrdn],al
	mov	[maxdrv],al		; 1 == highest allowable unit code
fini10:
	mov	bx,[wsblkhdr]		; Get Request Header pointer
	inc	al			; maximum drive number --> # of units
	mov	es:[bx].drqunits,al	; Set # of units
        mov     al,es:[bx].drqdn        ;jrbr starting drive number
        inc     al                      ;jrbr
        mov     [startd],al             ;jrbr
	lea	dx,fendres
	mov	word ptr es:[bx].drqendres,dx	; Set ending address of driver
	mov	word ptr es:[bx+2].drqendres,cs
	lea	dx,BPBpntr
	mov	word ptr es:[bx].drqbpba,dx	; Set pointer to BPB pointer array
	mov	word ptr es:[bx+2].drqbpba,ds	;rs1
	mov	es:[bx].drqsta,100H	; Return with 'DONE'
	ret				; End of INITBLK
finitblk	endp

	subttl	isdrive -- count & type drives on system

	page
;-----------------------------------------------------------------------;
; isdrive								;
;									;
; Determines number and types of diskettes on system.  Gets equipment	;
; information from ROM BIOS on drive count.  				;
; Determines drive types by CMOS or BIOS search
;									;
;  On Entry:								;
;	Nothing assumed.						;
;  On Exit:								;
;	nothing:							;
;									;
;  Global data affected: maxdrv set					;
;  Global procedures called: int 11h to determine equipment info.	;
;  ax, bx, cx, dx, si, di changed					;
;-----------------------------------------------------------------------;

;	Problems with differing drives on a system where caused by the
;	diskette parameter table.  The following code sets the table
;	for the first drive and then merges subsequent parameter tables.

isdrive	proc
	push	bx
	mov	ax,0101h		;Rod  Starting assumption is 360K's
	mov	dx,0f000h		;Rod  Get ready to look at ROM
	mov	es,dx			;Rod

;	Note that we first read the place that we know has valid ROM;
;	The Televideo 286 seems to act weird if we read the nonexistent
;	memory at f000:17 first... I have no idea why.         ;031388

	mov	dl,es:[0fffeh]		;Rod  ID byte
	mov	cx,es:[17h]		;Rod  Check if Toshiba laptop
	and	ch,0FCh			;BWR - Looking for "Tn" in ROM
	cmp	cx,'0T'			;Rod 
	je	isdt3100		;Rod  Yes, go treat as Model 30
	cmp	dl,0fch			;Rod  286 machine (or 386 AT clone)?
	je	isdcmos			;Rod  Yes, go check CMOS
	cmp	dl,0f8h			;Rod  Model 80?
	je	isdcmos			;Rod  Yes, go check CMOS 
	cmp	dl,0fah			;Rod  Model 30 or PC Convertible?
	ja 	isdftyp			;Rod  No, assume 360K floppies
isdt3100:				;Rod
	mov	ax,0303h		;Rod  Yes, assume 720K diskettes
	mov	[t3100],'Y'		;rr   Remember this
	jmp	short isdftyp		;Rod
isdcmos:				;Rod
	mov	al,10h			;Rod  Get diskette info from CMOS,
	out	70h,al			;Rod    because this method covers
	jmp	$+2			;Rod    the most cases
	in	al,71h			;Rod
	mov	ah,al			;Rod
	mov	cl,4			;Rod
	shr	al,cl			;Rod  AL is drive A, AH is drive B
	and	ah,0fh			;Rod 

isdftyp:				;Rod
	mov	word ptr [ftypes],ax	; set ftypes
	mov	ax,ds			; restore segment in ES
	mov	es,ax
	
	int	11h			; get equipment information
	test	al,1			; any diskettes?
	jnz	isdrives		; yes count them
	jmp	isdxit			; none just exit

isdrives:
	and	ax,00C0h		; maximum diskette drive number
	rol	al,1			; make it an integer
	rol	al,1
	mov	[maxdrv],al
	
	mov	si,offset grp:BPB1	; first DIB structure
	xor	bx,bx			; start with drive 0
	
;	BX = drive #
;	SI => DIB structure
isdloop:
	push	si			;Rod save DIB
	mov	al,ftypes[bx]		;Rod  Get diskette type code
	cmp	al,3			;Rod
	jg	isd104
	je	isd103
	cmp	al,1			; vector to approp 
	jg	isd102
	je	isd101
	jmp	isd40
	
isd104:
	mov	si,offset psdprm	;Rod  1.44M drive
	mov	di,offset BPB14		;Rod
	mov	ah,DTHICAP+DTSMALL+DTCHGLN ;Rod
	jmp	short isdset		;Rod
isd103:					;Rod
	mov	si,offset psdprm	;Rod
	mov	di,offset BPB720	;Rod  720K drive
	mov	ah,DTSMALL+DTCHGLN	;Rod
	cmp	[t3100],'Y'		;rr  Toshiba T3100?
	jne	isdset			;rr  No, go
	mov	si,offset pcdprm	;rr  Yes, use same as 360K diskparms
	jmp	short isdset		;Rod
isd102:					;Rod
	mov	si,offset atdprm	;Rod  1.2M drive
	mov	di,offset BPB12		;Rod
	mov	ah,DTHICAP+DTCHGLN	;Rod
	jmp	short isdset		;Rod
isd101:					;Rod
	mov	si,offset pcdprm	;Rod  360K drive
	mov	di,offset BPB360	;Rod
	mov	ah,0 			;Rod

isdset:		; set diskprm with drive's parameters
	
	push	di			; save device BPB
	mov	di,offset diskprm
	test	bx,bx			; first drive ?
	jnz	isdmerg
	mov	cx,SIZE diskprm
	cld
	rep movsb			; first drive set diskprm
	jmp	short isdbpb
	
isdmerg:	; merge second drive's parms with first's
	push	ax			; save drive flags
	push	bx			; BX used as parm offset
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
	pop	di			; restore BPB
	pop	si			;Rod  Restore DIB index
	or	ah,LOADBPB or FIRSTBPB or DIRTYBPB
	mov	[si].DIBatt,ah		; store disk type

;	Copy default BPB.

isd35:
	push	si		; save DIB pointer across copy
	push	si		; save for second copy
	push	di		; save source across copy too

	lea	si,[si].DIBdbps	; default BPB address
	xchg	si,di
	mov	cx,size BPB	; copy the default BPB
	rep	movsb

	pop	si		; source for copy (standard BPB)
	pop	di		; DIB pointer
	mov	cx,size BPB	; length to copy
	rep	movsb		; copy default BPB into main BPB

isd40:
	pop	si		; restore DIB pointer
	add	si,size DIB	; advance to next structure in array
	inc	bx		; next drive to check
	cmp	bl,[maxdrv]
	jg	isdxit
	jmp	isdloop		; check all drives
isdxit:
	pop	bx
	ret
	
isdrive	endp

	subttl		Diskette Drive Initialization Routines
	page

;	maxparm   -  sets diskette parameter to max/min of two tables

;	Enter:	DS:SI => source parameter table
;		DS:DI => destination parameter table
;		BX = index to byte manipulated
;	Exits:	DS:[DI+BX] set to max of DS:[BX+Si] DS:[BX+DI]
;	Uses:	AL

maxparm:
	mov	al,[si+bx]
	cmp	al,[di+bx]
	jle	maxparmx
	mov	[di+bx],al
maxparmx:
	ret


mosseg	ends
	end

