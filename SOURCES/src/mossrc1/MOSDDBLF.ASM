	include	page.inc
	title	MOSDDBLF - MOS device driver for fixed disk I/O

;-----------------------------------------------------------------------;
;									;
;		      Development Specification				;
;									;
; Program Name: MOS.COM			Assigned to: Rod Roark		;
; Module Name:	MOSDDBLF		Assign date: 10/29/86		;
; Entry Points: n/a			Completed:   10/29/86		;
; Entry From:	n/a							;
; Entry Method:	n/a							;
; Calls:	n/a							;
; Purpose:	MOS block device driver (fixed disk)			;
; Refer to:	n/a							;
; Last Update:	04/14/87						;
;									;
;-----------------------------------------------------------------------;
; 01/19/87 J. S. Mayo	multiple logical drives, MOXFDISK, & FORMAT	;
;-----------------------------------------------------------------------;
; 02/11/87 J. S. Mayo	large volume support				;
;-----------------------------------------------------------------------;
; 04/14/87 J. S. Mayo	return sector offset from partition table as	;
;			hidden sector count to generic I/O CTL		;
;-----------------------------------------------------------------------;
; 07/05/87 RBR   	Support up to 32 sectors per track.		;
;			Don't abort INIT if errors.			;
;			Use default BPB on init if sector size <> 512.  ;
;-----------------------------------------------------------------------;
; 10/27/87 RBR   	Support up to 35 sectors per track.		;
;-----------------------------------------------------------------------;
; 01/20/88 SAH		Change SCBSEG and ZERO to MGetXXX macros	;
;-----------------------------------------------------------------------;
; 01/26/88 RBR   	Support up to 64 sectors per track.		;
;-----------------------------------------------------------------------;
; 02/21/88 rbr/sah	Move DDT code to MO2 group.        		;
;-----------------------------------------------------------------------;
; 03/01/88 SAH		When initializing hard disks, some hard drives  ;
;			like the 40 meg Model 80 drive required a bios  ;
;			reset on the hard drive.			;
;-----------------------------------------------------------------------;
; 06/03/88 jrb		changed sense of IBM bit - current dos 		;
; jrbv			drivers (including us) are not ibm devices - 	;
;			that is, they don't require the first fat	;
;			sector on a build bpb call			;
;-----------------------------------------------------------------------;
; 12/05/88 rbr    	Since format now checks to see if generic ioctl ;
;			is supported (so we don't try to format a ram-  ;
;			disk), device attribute bit 6 must be on. Also, ;
;			homed the drive head before the reset command.  ;
;-----------------------------------------------------------------------;

	if1
	 %out Pass 1
	else
	 %out Pass 2
	endif

	subttl	group segments and include block definitions

	page
	include	MOSREGS.INC
	include GROUP.INC

tcb	segment at 1234h
tcb	ends

irq	segment	byte public 'data'
irq	ends

poll	segment	byte public 'data'
poll	ends

ddt	segment	word public 'code2'
ddt	ends

	page
gdata	segment	word public 'data'
	extrn ourbuf:byte	; system init disk buffer (mosint13)

;	Bits in the attribute byte in the DIB block

DTMSK	equ	7		; mask for disk types
DTNONE	equ	0		; no disk there
DTNOCHG	equ	1		; drive without change line -- 360K disk (old)
DTCHG	equ	2		; drive with change line -- 1.2M disk drive
DTFIXED	equ	3		; hard disk drive

LOADBPB	equ	8		; set if BPB should be loaded from media
BPBERR	equ	010h		; set if error loading BPB from media
DIRTYBPB equ	020h		; set when we HAVE to load BPB from disk
FIRSTBPB equ	040h		; set first time BPB is loaded

;	Command subcodes for generic I/O control

SETPARMS equ	040h		; set device parameters
GETPARMS equ	060h		; get device parameters
WRTTRACK equ	041h		; write track on logical device
RDTRACK	equ	061h		; read track on logical device
FVTRACK	equ	042h		; format and verify track on logical device
VERTRACK equ	062h		; verify track on logical device

BIOStl	equ	06cH		; BIOS timer low address (seg 40)
BIOSth	equ	06eH		; BIOS timer high address (seg 40)
DISKINT	equ	013h		; BIOS interrupt for disk I/O

LBLSIZ	equ	11		; size of MOS volume label

drvid	equ	80h		; Drive to use 80=C, 81=D

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
DIBspf	db	7		; Sectors per FAT
DIBsehi	db	0		; high byte of total sectors

DIBspt	dw	15		; Sectors/track (15 for 1.2 meg floppy)
DIBhds	dw	2		; number of heads
DIBhdn	dd	0		; hidden sectors

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

; DIBBfun	db	0		; Temp holding for next disk function
; DIBfill	db	0		; fill for keeping word alignment
DIBofflo dw	0		; low word of physical disk offset
DIBoffhi dw	0		; high word of physical disk offset
DIBcylct dw	0		; number of cylinders on disk
DIBcylof dw	0		; cylinders from beginning of disk
DIBhdof	dw	0		; head offset from beginning of disk
DIBhdmsk dw	1		; head mask
DIBspc	dw	30		; Sectors/cylinder (#heads * #sectors/track)
; DIBScnt	dw	0		; Total count of sectors for read or write
; DIBSstr	dw	0		; Starting sector for next disk I/O in loop
; DIBblkhdr dw	2 dup(0)	; ##### Temporary header pointer
; DIBfdrv	db	0		; Disk drive to use 0 or 1
DIBatt	db	0		; drive attributes
DIBrdn	db	0		; drive number this drive really should be
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
BPBspf	db	7		; Sectors per FAT
BPBsehi	db	0		; high byte of total sectors
BPBspt	dw	15		; Sectors/track (15 for 1.2 meg floppy)
BPBhds	dw	2		; number of heads
BPBhdn	dd	0		; hidden sectors

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
drqunits db	?		; initialized units
drqendres dd	?		; end of driver code
drqbpba	dd	?		; BPB pointer array
drqbdn	db	?		; starting device number

idevrq	ends

;	extra fields for media check

mdevrq	struc
	db	size devrq dup (?)
drqmd	db	?		; old media descriptor
drqrtcd	db	?		; return code from media check
drqlbl	dd	?		; volume label wanted if changed
mdevrq	ends

;	extra fields for build BPB

bdevrq	struc
	db	size devrq dup (?)
	db	?		; space for media descriptor (use drqmd)
drqta	dd	?		; transfer address for sector to read
drqbpbp	dd	?		; pointer to BPB for unit
bdevrq	ends

;	extra fields for input & output

idevrq	struc
	db	size devrq dup (?)
	db	?		; media descriptr (use drqmd)
	dd	?		; transfer address (use drqta)
drqsect	dw	?		; # sectors to read
drqstrt	dw	?		; starting sector number
drqelbl	dd	?		; volume label needed if illegal disk change
drqsehi	dw	?		; high word of sector number
idevrq	ends

;	extra fields for generic ioctl request

gdevrq	struc
	db	size devrq dup (?)
drqmaj	db	?		; major function code
drqmin	db	?		; minor function code
drqcsi	dw	?		; contents of si
drqcdi	dw	?		; contents of di
drqgirp	dd	?		; pointer to generic I/O request packet
gdevrq	ends

;	extra fields for get/set logical device

ldevrq	struc
	db	size devrq dup (?)
drqluni	db	?		; logical unit number
drqlcom	db	?		; command (get/set)
drqlstat dw	?		; status returned
ldevrq	ends

;------------------- generic IOCTL request packets -----------------;

gigsp	struc			; generic IOCTL get/set parameters packet
gspspe	db	?		; special functions
gspdt	db	?		; device type
gspda	dw	?		; device attributes
gspncy	dw	?		; number of cylinders
gspmt	db	?		; media type
gspbpb	db	size BPB dup (?)	; BPB in request packet
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

	even

Badlayout	dw	0	; non-zero if funny track layout

TrackTable	label word
	dw	17		; 17 entries in the default table
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

MAXTRKTBL equ (($ - TrackTable) / 4)

FormatTable	label	byte
	db	(MAXTRKTBL * 2) dup (?)	; table for format call

;------------------------ miscellaneous data ----------------------------;
	even

wsblfhdr dw	2 dup(0)	; Request header pointer

wshdrv	db	0		; Disk drive to use 0 or 1
BIOSfun	db	0		; Temp holding for next disk function

maxdrv	db	-1		; maximum drive number in use (-1 means none)
mindrv	db	0		; lowest allowable drive number

Sectcnt	dw	0		; Total count of sectors for read or write
Sectstr	dw	0		; Starting sector for next disk I/O in loop
	dw	0		; high word of starting sector (if needed)

nslow	dw	0		; low word in # of sectors in partition
nshigh	dw	0		; high word of # of sectors in partition

giobuf	dd	0		; buffer pointer for doint generic I/O

typrtr	db	0		; retry count for generic I/O
	db	0		; fill to word boundary

	even

;----------------------- BPB data area ---------------------------------;

BPBpntr	dw	BPB1
	dw	BPB2
	dw	BPB3
	dw	BPB4
	dw	BPB5
	dw	BPB6
	dw	BPB7
	dw	BPB8
	
BPB1	DIB	<>		; device info block
BPB2	DIB	<>		; device info block
BPB3	DIB	<>		; device info block
BPB4	DIB	<>		; device info block
BPB5	DIB	<>		; device info block
BPB6	DIB	<>		; device info block
BPB7	DIB	<>		; device info block
BPB8	DIB	<>		; device info block

;	default BPB for unformatted disk.

dftBPB	BPB	<512,4,1,2,512,4080,0F8h,1,17,5,0>

;----------------------- Function table --------------------------------;

	even
hfuntbl	dw	hinitblk	; 0  Init
	dw	hmedck		; 1  Media check
	dw	hbldbpb		; 2  Build BPB
	dw	hioctli		; 3  I/O control input
	dw	hinput		; 4  input (read)
	dw	ndhinput	; 5  Nondestructive input no wait
	dw	hinstat		; 6  input status
	dw	hinflsh		; 7  input flush
	dw	houtput		; 8  Output (write)
	dw	houtver		; 9  Output with verify
	dw	houtstat	; 10 Output status
	dw	houtflsh	; 11 Output flush
	dw	hioctlo		; 12 I/O control output
	dw	hgenioctl	; 19 generic I/O control

gdata	ends

	subttl	mos segment - MOS module code and local data

	page
mosseg	segment	word public 'code1'
	assume	cs:mos,ds:nothing,es:nothing,ss:tcb

	extrn sbios:word

;----------------------- Device Header ---------------------------------;

	public	scbstdhd
scbstdhd label	byte

	dd	-1

;jrbv	dw	0000000000000001b	; IBM, Block, non-removable, 
;jrbv					; supports generic IOCTL
;120588 dw      0010000000000001b       ;jrbv block, non-FAT-ID, non-removeable
;120588                                 ;jrbv   doesn't support generic IOCTL
;120588                                 ;jrbv   (and why bit 0?)

        dw      0010000001000001b       ;120588  Get/set device is supported

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
;	No global procedures called					;
;	No registers are changed					;
;-----------------------------------------------------------------------;

blkstrat proc	far

	push	ds			;rs1
	MGetSCB	ds			;rs1
	assume	ds:grp			;rs1
	mov	[wsblfhdr],bx		; Save pointer
	mov	[wsblfhdr+2],es
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
	push	es
	push	ds

;rs1	push	cs
;rs1	pop	ds
;rs1	assume	ds:mos

	MGetSCB	ds			;rs1
	assume	ds:grp			;rs1

	les	bx,dword ptr [wsblfhdr]	; Get Request Header pointer
	mov	al,es:[bx].drquni	; save unit code for later
	mov	bl,es:[bx].drqcom	; Get command code
	cmp	bl,12		; Check for invalid call
	jbe	rok		; if OK call
	cmp	bl,19		; generic IOCTL call?
	jne	herr1		; No, exit with error
	mov	bl,13		; pretend IOCTL is code 13
rok:
	cmp	al,[maxdrv]	; unit # in proper range?
	ja	herr2		; if too high (yes, I want a ja here!)
	cbw			; make it a word
	shl	ax,1		; now it's a word index
	mov	si,ax
	mov	si,BPBpntr[si]	; get proper DIB for unit
	mov	dl,[si].DIBrdn	; get real drive number for unit
	xor	bh,bh
	shl	bx,1
	call	hfuntbl [bx]	; Execute appropriate routine
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
	les	bx,dword ptr [wsblfhdr]	; Get Request Header pointer
	mov	es:[bx].drqsta,8103H	; Return 'Unknown Command'
	jmp	hrexit

herr2:
	les	bx,dword ptr [wsblfhdr]	; Get Request Header pointer
	mov	es:[bx].drqsta,8101H	; Return 'Bad Unit'
	jmp	hrexit

blkintr	endp

	subttl	HMEDCK - Media Check
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
hmedck	proc	near

	les	bx,dword ptr [wsblfhdr]		; Get pointer to RH
	test	[si].DIBatt,DIRTYBPB		; tell MOS new BPB?
	jz	hmed10				; if BPB needn't be changed
	mov	al,-1				; if BPB should be changed,
						; return "media changed"
	jmp	short hmed20			; exit
hmed10:
	mov	al,1				; "no change"
hmed20:
	and	[si].DIBatt,not DIRTYBPB	; BPB will be clean soon.
	mov	es:[bx].drqrtcd,al		; Media changed or not
	mov	es:[bx].drqsta,0100H		; Return with 'DONE'
	ret

hmedck	endp

	subttl	HBLDBPB - Build BIOS Parm Block
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

hbldbpb	proc	near

	les	bx,dword ptr [wsblfhdr]		; Get pointer to RH
	mov	word ptr es:[bx].drqbpbp,si	; Set BPB pointer offset

;rs1	mov	word ptr es:[bx+2].drqbpbp,cs	; "	"	" segment
	mov	word ptr es:[bx+2].drqbpbp,ds	;rs1

	mov	es:[bx].drqsta,100H		; Return 'Done'
	ret

hbldbpb	endp

	subttl	HIOCTLI - I/O Control input
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

hioctli	proc	near

	les	bx,dword ptr [wsblfhdr]	; Get pointer to RH
	mov	es:[bx].drqsta,8103H		; Return 'Unknown Command'
	ret

hioctli	endp

	subttl	HINPUT - input read
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

hinput	proc	near
	mov	[BIOSfun],2	; BIOS function 2 - Read
outentry:
	push	di

	les	bx,dword ptr [wsblfhdr]	; Get pointer to RH
	mov	ax,es:[bx].drqsect		; Get sector count
	mov	[Sectcnt],ax		; Save total count for IO
	mov	ax,es:[bx].drqstrt	; Starting sector number (logical)
	mov	[Sectstr],ax		; Save for loop with large IO
	xor	ax,ax
	cmp	al,[si].DIBsehi		; big disk?
	je	IOnobig			; if not a big disk
	mov	ax,es:[bx].drqsehi	; high word of start sector
IOnobig:
	mov	[Sectstr+2],ax		; store high word of start sector
	les	bx,es:[bx].drqta	; Get transfer address
	mov	cx,3			; 3 retries
diskIO:
	push	cx		; Save retry count
	mov	ax,[Sectstr]	; Get starting logical sector
	mov	dx,[Sectstr+2]	; high word of starting sector
	push	dx
	push	ax
IO1:
	pop	ax
	pop	dx
	call	CalcAbs		; Calculate absolute disk loc. from logical
	mov	dl,[si].DIBrdn	; Disk drive to use
	push	bx		; Save buffer pointer
	mov	bx,[Sectcnt]	; # sectors IO

	mov	ax,[si].DIBspt
	inc	ax		; Max per IO +1
	push	cx
	and	cl,3fh
	sub	al,cl		; Calc # sectors til end of track (this head)
	pop	cx

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
	loop	diskIO
;	mov	al,1		; Tell error routine who's error	RKG001
	jmp	hdskerr
IOok:
	pop	cx		; Clear retry count from stack
	sub	[Sectcnt],di	; Update amount of IO
	add	[Sectstr],di	; Update new starting sector
	adc	[Sectstr+2],0	; update high word too
	mov	ax,[Sectcnt]
	or	ax,ax		; Have we read all that was requested
	jz	endIO		; Yes, exit

	mov	cx,3		; New retry count
	mov	ax,di		; Get # sectors (read or written)
	xor	dx,dx		;   operation
	mul	[si].DIBbps	; * bytes per sector
	add	bx,ax		; Update new buffer pointer
	jmp	diskIO		; No, read next group
endIO:
	les	bx,dword ptr [wsblfhdr]	; Get pointer to RH
	mov	es:[bx].drqsta,0100H	; Return 'Done'

	pop	di
	ret
	
hinput	endp


;-----------------------------------------------------------------------;
; A Jump is made here if the BIOS returns a disk error during read or	;
; write. The BIOS error is translated.					;
;									;
; Error table and Request Header are given to DISKERR in MOSDDBLK	;
; DISKERR pops DI before returning to caller.
;-----------------------------------------------------------------------;

	extrn	dskerrtbl:byte, diskerr:near
	
hdskerr:
	les	bx,dword ptr [wsblfhdr]	; Get pointer to RH
	mov	di,offset dskerrtbl	; Error translate table
	jmp	diskerr			; translate store and return
	
	
	subttl	CalcAbs - Calculate Absolute sector
	page
;-----------------------------------------------------------------------;
;	This routine will calculate the absolute disk location 		;
;	from the logical sector number. 				;
;									;
;  On Entry:								;
;	DX:AX = logical sector number					;
;									;
;  On Exit:								;
;	DH = head number						;
;	CH = low 8 bits of cylinder number 				;
;	CL = sector number (0-5); high cylinder bits (6-7)		;
;									;
; 	CX & DX used to pass parms, all others unchanged		;
;-----------------------------------------------------------------------;

CalcAbs	proc	near

	push	ax

	add	ax,[si].DIBofflo	; disk partitioning adjustment
	adc	dx,[si].DIBoffhi

	mov	cx,[si].DIBspt
	push	bx		; remainder comes in bx
	mov	cx,[si].DIBspt
	call	ldiv
	mov	cl,bl		; giving remainder = sector number
	pop	bx
	inc	cl 

				; and quotient = relative track
	div	[si].DIBhds	; divide by tracks/cylinder (# heads)
	xchg	dh,dl		; giving remainder = head number

	mov	ch,al		; and quotient = cylinder number
	mov	al,0		; pick up quotient high bits
	shr	ax,1 
	shr	ax,1
	or	cl,al

	pop	ax
	ret

CalcAbs	endp

	subttl	NDHINPUT - Nondestructive input no wait
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
ndhinput	proc	near

	les	bx,dword ptr [wsblfhdr]	; Get pointer to RH
	mov	es:[bx].drqsta,8103H		; Return 'Unknown Command'
	ret

ndhinput	endp

	subttl	HINSTAT - input status
	page
;-----------------------------------------------------------------------;
;	This routine processes the Input Status call (=6)		;
;									;
;	No parms passed							;
;	Return values are set in the Request Header			;
;	No global data affected						;
;	No global procedures called					;
;	ES:BX used to point to RH					;
;-----------------------------------------------------------------------;
hinstat	proc	near

	les	bx,dword ptr [wsblfhdr]	; Get pointer to RH
	mov	es:[bx].drqsta,8103H		; Return 'Unknown Command'
	ret

hinstat	endp

	subttl	HINFLSH - Input Flush
	page
;-----------------------------------------------------------------------;
;	This routine processes the Input Flush call (=7)		;
;									;
;	No parms passed							;
;	Return values are set in the Request Header			;
;	No global data affected						;
;	No global procedures called					;
;	ES:BX used to point to RH					;
;-----------------------------------------------------------------------;
hinflsh	proc	near

	les	bx,dword ptr [wsblfhdr]	; Get pointer to RH
	mov	es:[bx].drqsta,8103H		; Return 'Unknown Command'
	ret

hinflsh	endp

	subttl	HOUTPUT - Output write
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
houtput	proc	near

	mov	[BIOSfun],3	; BIOS function 3 - Write
	jmp	outentry	; Use same routines as 'input' function

houtput	endp

	subttl	HOUTVER - Output with Verify
	page
;-----------------------------------------------------------------------;
;	This routine processes the Output with verify call (=9)		;
;									;
;	No parms passed							;
;	Return values are set in the Request Header			;
;	No global data affected						;
;	No global procedures called					;
;	ES:BX used to point to RH					;
;-----------------------------------------------------------------------;
houtver	proc	near

	mov	[BIOSfun],3	; BIOS function 3 - Write
	jmp	outentry	; Use same routines as 'input' function

houtver	endp

	subttl	HOUTSTAT - Output status
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
houtstat	proc	near

	les	bx,dword ptr [wsblfhdr]	; Get pointer to RH
	mov	es:[bx].drqsta,8103H		; Return 'Unknown Command'
	ret

houtstat	endp

	subttl	HOUTFLSH - Output flush
	page
;-----------------------------------------------------------------------;
;	This routine processes the Output flush call (=11)		;
;									;
;	No parms passed							;
;	Return values are set in the Request Header			;
;	No global data affected						;
;	No global procedures called					;
;	ES:BX used to point to RH					;
;-----------------------------------------------------------------------;
houtflsh	proc	near

	les	bx,dword ptr [wsblfhdr]	; Get pointer to RH
	mov	es:[bx].drqsta,8103H		; Return 'Unknown Command'
	ret

houtflsh	endp

	subttl	HIOCTLO - I/O Control Output
	page
;-----------------------------------------------------------------------;
;	This routine processes the IOCTL Output call (=12)		;
;									;
;	No parms passed							;
;	Return values are set in the Request Header			;
;	No global data affected						;
;	No global procedures called					;
;	ES:BX used to point to RH					;
;-----------------------------------------------------------------------;
hioctlo	proc	near

	les	bx,dword ptr [wsblfhdr]	; Get pointer to RH
	mov	es:[bx].drqsta,8103H		; Return 'Unknown Command'
	ret

hioctlo	endp

	subttl	HGENIOCTL - Generic I/O control
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
hgenioctl proc	near

	les	bx,dword ptr [wsblfhdr]	; Get pointer to RH
	mov	cl,es:[bx].drqmin		; minor function code

	cmp	cl,SETPARMS
	je	hgen10
	cmp	cl,GETPARMS
	je	hgen20
	cmp	cl,WRTTRACK
	je	hgen30
	cmp	cl,RDTRACK
	je	hgen40
	cmp	cl,FVTRACK
	je	hgen50
	cmp	cl,VERTRACK
	je	hgen60
	mov	es:[bx].drqsta,8103H	; Return 'Unknown Command'
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
hgenioctl endp

	subttl	HGSETPARMS - generic I/O CTL set parameters
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

hgsetparms	proc	near

	les	bx,dword ptr [wsblfhdr]	; Get pointer to RH
	push	ds

	push	ds
	lds	bx,es:[bx].drqgirp		; pointer to IOCTL request
	pop	es				; es points to old ds

	push	si				; save si for later

	assume	ds:nothing
	assume	es:grp				;rs1

	mov	cx,[bx].gsptrack		; number of tracks in sector
	cmp	cx,MAXTRKTBL			; more than we can hold?
	ja	hgset50				; if too many
	shl	cx,1				; tracks*2 == words in table
	inc	cx				; plus the track count
	lea	si,[bx].gsptrack		; source for copy
	mov	di,offset TrackTable		; destination for copy
	cld
	rep	movsw				; copy the track table

	pop	si

	call	makeftbl			; construct format table
						; from track table

	test	[bx].gspspe,2			; ignore all but track table?
	jnz	hgset20				; if ignore all else

;	Copy BPB to driver.

	push	si				; save si again
	test	[bx].gspspe,1			; default BPB or real BPB?
	jnz	hgset10				; if set real BPB

;	Copy default BPB into DIB.

	mov	cx,size BPB
	lea	di,[si].DIBdbps			; address of default BPB
	lea	si,[bx].gspbpb			; address of caller's BPB
	rep	movsb				; copy the default BPB

	pop	si
	pop	ds

	assume	ds:grp,es:nothing		;rs1

	or	[si].DIBatt,LOADBPB		; Load BPB from real media

; 	Load the real BPB again (we probably overwrote it)

	xor	ax,ax				; read logical sector 0
	mov	dx,ax
	call	CalcAbs				; dx & cx set up for read
	mov	dl,[si].DIBrdn			; real drive ID

;rs1	push	cs
	push	ds				;rs1
	pop	es

	lea	bx,[ourbuf]			; sector buffer
	mov	ax,0201h			; command code to . . .
	int	DISKINT				; read the sector

	push	si
	mov	di,si				; destination is our BPB
	lea	si,[bx+11]			; source is sector buffer + 11
	mov	cx,size BPB
	repe	movsb
	pop	si

	jmp	short hgset30			; exit function

;	Copy real BPB into DIB

hgset10:
	assume	ds:nothing
	assume	es:grp				;rs1
	mov	cx,size BPB
	mov	di,si				; copy into real BPB
	lea	si,[bx].gspbpb			; caller's BPB
	rep	movsb
	pop	si
	pop	ds
	assume	ds:grp,es:nothing		;rs1

	and	[si].DIBatt,not LOADBPB		; don't load BPB from disk
	or	[si].DIBatt,DIRTYBPB		; make sure we read new BPB
	jmp	short hgset30			; exit function
hgset20:
	assume	ds:nothing		;rs1
	assume	es:grp			;rs1
	pop	ds
	assume	ds:grp,es:nothing	;rs1
hgset30:
;rs1	assume	ds:mos
	mov	ax,0100h		; "Done" status code
hgset40:
	les	bx,dword ptr [wsblfhdr] ; get request header back again
	mov	es:[bx].drqsta,ax	; Return 'Done'
	ret
hgset50:
	assume	ds:nothing		;rs1
	assume	es:grp			;rs1
	pop	si
	pop	ds
	assume	ds:grp,es:nothing	;rs1
	mov	ax,8105h		; return "Error, bad structure length"
	jmp	hgset40			; return to caller
	
hgsetparms	endp

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

makeftbl	proc	near

	push	ds
	push	es
	push	cx
	push	ax
	push	si
	push	di

;rs1	push	cs
;rs1	pop	ds
;rs1	push	cs
;rs1	pop	es

	MGetSCB ds		;rs1
	push	ds		;rs1
	pop	es		;rs1
	assume	ds:grp		;rs1

	mov	si,offset TrackTable
	mov	di,offset FormatTable
	mov	[BadLayout],0	; assume layout is good
	cld

	lodsw
	mov	cx,ax		; number of sectors to set up for
	jcxz	mkft30		; if zero sectors
	xor	ax,ax		; make high byte 0
	stosb			; store bytes backward
mkft10:
	lodsb			; sector number
	add	si,3		; skip high byte of sector & size
	stosw			; good sector, use given number
	loop	mkft10		; do the next sector
	jmp	mkft40		; exit routine
mkft30:
	mov	[BadLayout],1	; bad track layout
mkft40:
	pop	di
	pop	si
	pop	ax
	pop	cx
	pop	es
	pop	ds
	ret
makeftbl	endp

	subttl	HGGETPARMS - generic I/O CTL get parameters
	page
;-----------------------------------------------------------------------;
;	This routine does the generic IOCTL get parameters call (=60h)	;
;									;
;	No parms passed							;
;	Return values are set in the Request Header			;
;	No global data affected						;
;	No global procedures called					;
;	ax, cx, di changed
;	ES:BX used to point to RH					;
;-----------------------------------------------------------------------;
hggetparms	proc	near

	les	bx,es:[bx].drqgirp		; pointer to IOCTL request
	push	si				; we use this later
	test	es:[bx].gspspe,1		; default BPB or real BPB?
	jnz	hgget20				; if real BPB
	lea	si,[si].DIBdbps			; pointer to default BPB
hgget20:
	lea	di,[bx].gspbpb			; where to copy the BPB
	mov	cx,size BPB			; length of it in bytes
	cld
	push	di
	rep	movsb				; copy into caller's buffer
	pop	di				; restore DIB pointer
	pop	si

;	Return right number of hidden sectors.

	push	dx

;	mov	ax,[si].DIBhdof
;	mul	[si].DIBspt			; hidden = offset

	mov	ax,[si].DIBofflo
	mov	dx,[si].DIBoffhi
	mov	word ptr es:[di].BPBhdn,ax
	mov	word ptr es:[di+2].BPBhdn,dx
	pop	dx

;	return parameters for fixed disk drive.

	mov	es:[bx].gspdt,5			; fixed disk drive
	xor	ax,ax
	mov	es:[bx].gspda,ax		; can't remove, no change line
	mov	es:[bx].gspmt,al		; set media type
	mov	ax,[si].DIBcylct		; total cylinders on disk
	mov	es:[bx].gspncy,ax

	les	bx,dword ptr [wsblfhdr]	; regular request header again
	mov	es:[bx].drqsta,0100h		; return "Done"
	ret
hggetparms	endp

	subttl	HGWRTTRACK - generic I/O CTL Write Track
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

hgwrttrack	proc	near

	mov	[BIOSfun],3			; BIOS function 3 - Write
hg_rventry:
	les	bx,dword ptr [wsblfhdr]	; Get pointer to RH
	les	bx,dword ptr es:[bx].drqgirp	; generic I/O request packet
	mov	ax,word ptr es:[bx].girta	; set transfer address
	mov	word ptr [giobuf],ax
	mov	ax,word ptr es:[bx+2].girta
	mov	word ptr [giobuf+2],ax

	push	di				; save di before we munge it

;	Check starting sector.

	mov	ax,es:[bx].girstrt		; starting sector
	mov	[Sectstr],ax			; store for later
	cmp	ax,[TrackTable]			; is start sector too big?
	jb	hgwr10				; if start sector OK
	jmp	hgwrer1				; if start sector too big

;	Check sector count.
hgwr10:
	add	ax,es:[bx].girnsec		; total sector count
	cmp	ax,[TrackTable]
	jbe	hgwr20				; if sector count OK
	jmp	hgwrer1
hgwr20:
	mov	ax,es:[bx].girnsec
	mov	[SectCnt],ax

;	Check head number.

	mov	di,es:[bx].girhead		; check requested head number
	cmp 	di,[si].DIBhds			; head number above max?
	jb	hgwr30				; if head number OK
	jmp	hgwrer2				; if head number too big
hgwr30:
;	add	di,[si].DIBhdof			; add head offset
	cmp	di,[si].DIBhds			; head wrap?
	mov	cx,es:[bx].gircyl		; check requested cylinder
	jb	hgwr40				; if no wrap, continue

	inc	cx				; up cylinder # by one
	sub	di,[si].DIBhds			; unwrap heads
	jmp	short hgwr40			; continue processing

hg_fmtentry:
	push	di				; for stack rebalance
	mov	ax,[TrackTable+2]		; starting sector
	dec	ax				; make it 0-based
	mov	[SectStr],ax			; store for later
	mov	ax,[TrackTable]			; sectors to format

;	Store sector count.

	mov	[SectCnt],ax

;	Check head number.

	mov	di,es:[bx].girhead		; check requested head number
	cmp 	di,[si].DIBhds			; head number above max?
	jae	hgwrer2				; if head number too big

;	Check cylinder number.

	mov	cx,es:[bx].gircyl		; requested cylinder
hgwr40:
	cmp	cx,[si].DIBcylct		; greater than cylinders
						; on device?
	jae	hgwrer3				; if out of range
	add	cx,[si].DIBcylof		; add cylinder offset
						; to get physical cylinder

;	Set up registers for I/O.

	mov	[typrtr],3			; retry count
	and	cx,03ffh			; 10 bits of cylinder
	xchg	ch,cl				; low 8 bits in ch
	ror	cl,1
	ror	cl,1				; high 2 bits in high cl
	or	cl,byte ptr [SectStr]		; starting sector number
	inc	cl				; 1-based sector number
	mov	dh,dl				; save disk number here
	xor	dl,dl				; this will be head number
	or	dx,di				; get head number in dl
	xchg	dh,dl				; dh=head, dl=disk
	les	bx,[giobuf]			; where data lives
	jmp	short hg_IOpart			; do the real I/O

;	Reset disk system & retry I/O.
hg_diskIO:
	xor	ax,ax				; Reset disk
	int	DISKINT
	jnc	hg_IOpart			; No errors continue with IO
;	mov	al,0				; say whose error	RKG001
	jmp	hdskerr				; Guess what . . .

;	Do the disk I/O.
hg_IOpart:	
	mov	al,byte ptr [SectCnt]		; sector count
						; format ignores this
	mov	ah,[BIOSfun]			; function to perform
	int	DISKINT				; do it!
	jnc	hg_IOok				; if no error doing I/O
	dec	[typrtr]			; out of retries?
	jnz	hg_diskIO			; no, try I/O again
;	mov	al,1				; say whose error	RKG001
	jmp	hdskerr				; return user to caller

;	The I/O call succeeded.

hg_IOok:	
	mov	ax,0100h			; return "Done"
hg_IOex:
	les	bx,dword ptr [wsblfhdr]	; Get pointer to RH
	mov	es:[bx].drqsta,ax		; return status code
	pop	di
	ret

;	Error handlers.

hgwrer1:
	mov	ax,08108h			; return "sector not found"
	jmp	hg_IOex
hgwrer2:
hgwrer3:
	mov	ax,08103h			; return "Bad command"
	jmp	hg_IOex

hgwrttrack	endp

	subttl	HGRDTRACK - generic I/O CTL Read Track
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

hgrdtrack	proc	near

	mov	[BIOSfun],2			; BIOS function 2 - Read
	jmp	hg_rventry			; do the I/O

hgrdtrack	endp

	subttl	HGFVTRACK - generic I/O CTL format & verify track
	page
;-----------------------------------------------------------------------;
;	Generic IOCTL format & verify track call (=42h)			;
;									;
;	No parms passed							;
;	Return values are set in the Request Header			;
;	No global data affected						;
;	No global procedures called					;
;	ES:BX used to point to RH					;
;-----------------------------------------------------------------------;

hgfvtrack	proc	near

	les	bx,dword ptr [wsblfhdr]	; Get pointer to RH
	les	bx,dword ptr es:[bx].drqgirp	; generic I/O request packet

	mov	al,byte ptr [BadLayout]
	shl	al,1				; bad bit is bit 1, not 0
	or	al,1				; no funny layouts
	test	es:[bx].girspe,1		; just a status call?
	jnz	hgfv10				; exit if just status call

	test	al,2				; funny track layout?
	jz	hgfv20				; if layout OK
hgfv10:
	mov	es:[bx].girspe,al		; tell if layout OK
	les	bx,dword ptr [wsblfhdr]
	mov	es:[bx].drqsta,0100h		; return "Done"
	ret

;	If this disk partition is the first partition on the disk,
;	don't allow formatting of cylinder 0, head 0.  The criterion
;	for first partition is that its sector offset is not an even
;	number of cylinders.

hgfv20:
	xor	ax,ax				; use for constant 0
	cmp	es:[bx].gircyl,ax		; cylinder 0?
	jne	hgfv40				; if not cylinder 0, normal
	cmp	es:[bx].girhead,ax		; head 0?
	jne	hgfv40				; if not head 0, normal
	push	dx
	mov	ax,[si].DIBofflo		; partition on cylinder bound?
	mov	dx,[si].DIBoffhi
	div	[si].DIBspc			; divide sector offset by
						; sectors by cylinder
	or	dx,dx				; is there a remainder?
	pop	dx
	jz	hgfv40				; if on boundary, continue

;	Don't allow format of track 0

	les	bx,dword ptr [wsblfhdr]	; get request header
	mov	es:[bx].drqsta,0100h		; return "Done"
	ret

hgfv40:
	mov	word ptr [giobuf],offset FormatTable

;rs1	mov	word ptr [giobuf+2],cs		; get format table ready
	mov	word ptr [giobuf+2],ds		;rs1

	mov	[BIOSfun],5			; BIOS function 5 - Format

	call	hg_fmtentry			; format the track

;	If the operation succeeded, the error bit in the driver request
;	block will be reset.  es:bx will be left pointing to the main
;	driver request block at this point, so we can conveniently test
;	for an error.

	test	es:[bx].drqsta,080h		; did an error occur?
	jz	hgfv50				; if no error
	ret					; quit now if error
hgfv50:
	les	bx,dword ptr es:[bx].drqgirp	; generic I/O request packet
	mov	[BIOSfun],4			; BIOS function 4 - Verify
	jmp	hg_fmtentry			; verify the track

hgfvtrack	endp

	subttl	HGVERTRACK - generic I/O CTL verify track
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

hgvertrack	proc	near

	mov	[BIOSfun],4			; BIOS function 4 - Verify
	les	bx,dword ptr [wsblfhdr]	; Get pointer to RH
	les	bx,dword ptr es:[bx].drqgirp	; generic I/O request packet

	cmp	[BadLayout],0			; funny track layout?
	jz	hgve20				; if layout OK
	or	es:[bx].girspe,3
hgve10:
	les	bx,dword ptr [wsblfhdr]
	mov	es:[bx].drqsta,0100h		; return "Done"
	ret
hgve20:
	test	es:[bx].girspe,1		; just a status call?
	jz	hgve30				; if a "really do it" call
	mov	es:[bx].girspe,1		; say layout OK
	jmp	hgve10				; exit routine

;	The contents of giobuf are irrelevant, since verify ignores es:bx.
hgve30:
	jmp	hg_fmtentry			; do the I/O

hgvertrack	endp

hendres	label	byte

	subttl	HINITBLK - Init hard disk driver
	page
;-----------------------------------------------------------------------;
;	This routine will initialize the fixed-disk device driver.	;
;									;
;	It looks through the partition table on each physical disk.	;
;	It assigns a DIB block & a unit number to each partition found	;
;	on each physical drive (a maximum of 8).			;
;									;
;	The initial BPB for each fixed disk contains either a) the	;
;	contents of the boot sector BPB, if that is determined to be	;
;	OK, or b) a bare-bones BPB which contains the correct number	;
;	of heads, sectors per track, and total number of sectors.	;
;-----------------------------------------------------------------------;

hinitblk proc	near
	push	si
	push	di

;rs1	push	cs
	push	ds		;rs1
	pop	es		; buffer address

	mov	[maxdrv],-1	; we have found no blocks yet

;------------ Ask BIOS for number of physical drives ----------------;

	mov	ah,8
	mov	dl,80h
	int	DISKINT		; get drive parameters
	or	dl,dl		; are there any of them at all?
	jnz	init10		; if there are some of them
	jmp	initend		; if there are no drives at all
	cmp	dl,2		; are there more than 2 drives?
	jbe	init10		; if 1 or 2 drives
	mov	dl,2		; only use 2 drives

;------------ Read first physical sector from a drive ---------------;

init10:
	mov	[wshdrv],dl	; save drive count
	mov	dl,80h
	lea	di,[BPB1]	; pointer to first BPB
init20:
	push	dx		; save drive number

	push	dx		;120588
	mov	ax,0401h	;120588  Verify to position to cylinder 0
	lea	bx,[ourbuf]	;120588
	mov	cx,0001h	;120588 
	mov	dh,00h		;120588 
	int	DISKINT		;120588
	pop	dx		;120588

	push	dx		;SAH
	xor	ax,ax		;SAH	make sure you reset the hard drive
	int	DISKINT		;SAH
	pop	dx		;SAH

	mov	ah,8		
	int	DISKINT		; get parameters for this drive
	mov	al,dh
	cbw			; make heads into word
	inc	ax		; # heads = max # + 1
	mov	[dftBPB.BPBhds],ax	; number of heads on the drive
	mov	al,cl
	cbw			; make sectors/track a word
	and	ax,3fh		; mask sector number to 6 bits
	mov	[dftBPB.BPBspt],ax

	pop	dx		; restore drive number
	lea	si,[ourbuf+01beh]
init30:
	mov	ax,0201h	; read 1 sector
	lea	bx,[ourbuf]
	mov	cx,0001h	; cylinder 0, sector 1
	mov	dh,00h		; head 0, drive C or D
	int	DISKINT
	jnc	$+5
	jmp	initplp		; i/o error, check for second drive

;------------------- Locate partition table entry -------------------;

	cmp	word ptr [ourbuf+01feh],0aa55h
	je	$+5
	jmp	initplp		; skip if no partition-table boot record
lpteloop:
	cmp	byte ptr [si],80h
	je	lptechk
	cmp	byte ptr [si],00h
	je	lptechk
	jmp	initplp		; end of partition table
lptechk:
	cmp	byte ptr [si+4],1	; DOS partition w/12-bit FAT?
	je	lpteok			; yes, add to disk list
	cmp	byte ptr [si+4],4	; DOS partition w/16-bit fat?
	je	lpteok			; yes, add to disk list
lptenxt:
	add	si,16			; next partition table entry
	jmp	lpteloop
lpteok:
        mov	ax,[si+8]	; save relative sector offset
	mov	[di].DIBofflo,ax
	mov	ax,[si+10]
	mov	[di].DIBoffhi,ax
	mov	al,[si+1]	; save head offset
	cbw
	mov	[di].DIBhdof,ax

	mov	ax,[si+12]	; number of sectors on current partition
	mov	[nslow],ax
	mov	[dftBPB.BPBsect],ax	; remember total sectors
	mov	ax,[si+14]
	mov	[nshigh],ax
	mov	[dftBPB.BPBsehi],al	; high byte of total

;------------------------ Read boot sector --------------------------;

	mov	cx,[si+2]	; load starting sector/cylinder
	mov	dh,[si+1]	; head
	mov	ax,0201h	; read 1 sector
	lea	bx,[ourbuf]
	int	DISKINT
	jnc	$+5
	jmp	initllp		; handle i/o error

;-------- Retrieve BPB contents and track and cylinder sizes --------;

	push	si

;	Determine if BPB is good.

	cmp	word ptr [bx+11],0200h	;Rod  512 bytes per sector?
	jne	initdbpb		;Rod  no, use default BPB

	cmp	byte ptr [bx],0EBh	; start with short or long jumps
	je	init40			; if good boot sector
	cmp	byte ptr [bx],0E9h
	je	init40			; if good boot sector

initdbpb:				;Rod

	lea	si,[dftBPB]		; if no good, use default BPB
	jmp	short init50
init40:
	lea	si,[ourbuf+11] 	; they're all in the boot sector
				; except number of sectors
	mov	cx,[nslow]
	mov	[si].BPBsect,cx	; set sectors from partition table
	mov	cl,byte ptr [nshigh]
	mov	[si].BPBsehi,cl
init50:
	push	di		; save BPB pointer
	push	si		; and pointer to BPB
	mov	cx,size BPB
	cld
	rep	movsb
	pop	si
	pop	di

;	Set default BPB for drive.

	push	di		; save BPB pointer
	lea	di,[di].DIBdbps	; address of default BPB
	mov	cx,size BPB
	rep	movsb
	pop	di
	pop	si

;	Calculate cylinders on disk by formula
;	cylinders = (total sectors / sectors per track) / # heads.

	push	dx
	mov	ax,[nslow]			; total sectors
	xor	dx,dx
	mov	dl,byte ptr [nshigh]
	mov	cx,[di].DIBspt
	call	ldiv
	div	[di].DIBhds			; max tracks/heads = cylinders
	or	dx,dx				; remainder?
	jz	init60				; if even division
	inc	ax				; if partial cylinder
init60:
	mov	[di].DIBcylct,ax		; total cylinders on disk

;	Calculate cylinder offset for generic I/O control.
;	Formula is (offset sectors / sectors per track) / # heads.

	mov	ax,[di].DIBofflo
	mov	dx,[di].DIBoffhi
	mov	cx,[di].DIBspt
	call	ldiv
	div	[di].DIBhds
	mov	[di].DIBcylof,ax	; store cylinder offset

	pop	dx

	mov	[di].DIBrdn,dl	; remember real drive number
	or	[di].DIBatt,LOADBPB	; load BPB from disk
	inc	[maxdrv]	; we have found one more drive
	add	di,size DIB	; next descriptor
initllp:
	add	si,16		; next partition in table
	jmp	init30		; next partition, reload partition table
initplp:
	cmp	dl,081h		; did we initialize second drive?
	je	initend		; if second physical drive initialized, quit
	cmp	[wshdrv],2	; how many drives?
	jb	initend		; if only one drive to initialize
	mov	dl,081h
	jmp	init20		; initialize second drive
initend:

;-------------------- Set up return to caller -----------------------;

	les	bx,dword ptr [wsblfhdr]	; Get Request Header pointer
	mov	al,[maxdrv]			; how many drives did we find?

;Rod	or	al,al
;Rod	jl	ioerror				; if found no drives

	inc	al				; convert to # of drives
	mov	es:[bx].drqunits,al		; Set # of units
	lea	dx,hendres
	mov	word ptr es:[bx].drqendres,dx	; Set ending address of driver
	mov	word ptr es:[bx+2].drqendres,cs	;
	lea	dx,BPBpntr
	mov	word ptr es:[bx].drqbpbp,dx	; Pointer to BPB pointer array

;rs1	mov	word ptr es:[bx+2].drqbpbp,cs	;
	mov	word ptr es:[bx+2].drqbpbp,ds	;rs1

	mov	al,es:[bx].drqbdn		; Get DOS drive number
	mov	ax,0100h			; status OK
	jmp	short initret
ioerror:
	mov	al,0
	mov	es:[bx].drqunits,al	; Set no units inited
	mov	ax,810bH		; Report read fault error
initret:
	mov	es:[bx].drqsta,ax 	; set return status
	pop	di
	pop	si
	ret			; End of HINITBLK

hinitblk endp

;-----------------------------------------------------------------------;
;	ldiv -- perform long division					;
;									;
;	Entry:								;
;	DX:AX contains double word dividend				;
;	CX    contains divisor						;
;	Exit:								;
;	DX:AX contains double word quotient of dx:ax / cx		;
;	BX contains remainder						;
;	All other registers unchanged					;
;-----------------------------------------------------------------------;

ldiv	proc

	mov	bx,ax		; save low word of dividend
	mov	ax,dx
	xor	dx,dx		; divide 0:high word by cx
	div	cx
	xchg	bx,ax		; high quotient for low of dividend
	div	cx		; divide remainder:ax by cx
	xchg	bx,dx		; return remainder in bx, and
				; restore high word of quotient
	ret
ldiv	endp

	even

mosseg	ends
	end
