	page	80,132

;	Still to Do: Int 2F function 150F.

;--------------------------------------------------------------------;
;          Copyright 1991, 1992, 1993 Rod Roark                      ;
;--------------------------------------------------------------------;
;   8/06/92 Released v1.01: support for L= parameter; fixed failure  ;
;           to properly convert "." and ".." during func 4e & 4f;    ;
;           changed copyright.                                       ;
;   8/23/92 Fixed instability after a critical error causes          ;
;	    dBuffSector to be left invalid.  Changed to v1.02.       ;
;	    Edit out reporting of "." and ".." in a root directory.  ;
;	    Adjust for "." in a path name.			     ;
;   9/01/92 Do stack switch in Executor.  Correct "copyname" proc    ;
;	    to truncate target filename.ext to 8.3 characters.	     ;
;   9/13/92 Add "stofcdname" function to format a name without	     ;
;	    expecting wildcards; fixes problem where change dir-     ;
;	    ectory did not work if first char of name is numeric.    ;
;   9/14/92 Correct "checkvol" proc to treat "don't know if media    ;
;	    has changed" same as "media has changed".  This fixes    ;
;	    a problem with the HITACHIA.SYS driver.		     ;
;   9/15/92 Added "execint21" public dword to accomodate new ver-    ;
;	    sion of executor.  Issue a "media check" call after      ;
;	    any critical error, to clear the change line.  Fix	     ;
;	    critical error handler to correctly handle the situ-     ;
;	    ation where the int23 handler returns to us.	     ;
;   9/17/92 Test for "/" wherever we test for "\".		     ;
;   9/18/92 Released DOS and MOS versions 1.02.			     ;
;   9/19/92 Added statistical counters and logic to maintain them.   ;
;   1/27/93 Updated copyright dates; changed to and released 1.03.   ;
;   3/07/93 Fixed multiple drive support, BPB array just had one     ;
;	    entry! Fixed getdevad to not trash ax. Fixed procdrv     ;
;	    to detect absence of H/W driver. Implemented Enque &     ;
;	    Deque for DOS/Windows systems.  Changed Deque to do a    ;
;	    "dec" instead of a "mov", corrected some mis-pairings.   ;
;   3/08/93 Allow an int24 handler to fail an fcb-style function,    ;
;	    so Windows 3.1 does not hang if a drive door is open.    ;
;	    This involved creation of the "bSwitches" stack item,    ;
;	    and we also moved fInMOS to that item.		     ;
;   5/13/93 Installed serial number validation and demo expiration.  ;
;	    Changed default dLongSize to 16 sectors from 3.	     ;
;   6/14/93 Changed default for wHandOff from 192 to 200, to	     ;
;	    accomodate DOS 6.  Bumped release # to 1.05.	     ;
;   6/21/93 Added logic to confirm that the FCB we are reading       ;
;	    with is one that was created by us; if not, we return    ;
;	    with an eof indication.  This fixes an idiosyncracy      ;
;	    with Xtree Gold.  Also corrected prochand to set	     ;
;	    bThisDrive... it looks like multiple drives would be     ;
;	    problematic.  Bumped to release 1.06.		     ;
;   7/29/93 Return an error condition if someone tries to do an      ;
;	    int25 on a CD-ROM.  Fixes Xtree for Windows.	     ;
;	    Bumped to release 1.07.				     ;
;--------------------------------------------------------------------;

.xlist
	include	cdlink.pub
.list

;----------------------------- Equates ------------------------------;

	include cdlinkeq.inc

EXECCODE	equ	DOSCODE		; if executor to be linked in

SCBFAR21 	equ	027dh		; scb offset to int21 entry pointer
SCBTCBPC 	equ	0013h		; scb offset to current tcb pointer
TCBID	 	equ	0010h		; tcb offset to task id
TCBSTKP		equ	008ch		; tcb offset to stack pointer

		if	-1		; don't generate PUBLICs

bSwitches	equ	byte ptr [bp+00]
wUserAX		equ	word ptr [bp+02]
wUserBX		equ	word ptr [bp+04]
wUserCX		equ	word ptr [bp+06]
wUserDX		equ	word ptr [bp+08]
wUserSI		equ	word ptr [bp+10]
wUserDI		equ	word ptr [bp+12]
wUserBP		equ	word ptr [bp+14]
wUserDS		equ	word ptr [bp+16]
wUserES		equ	word ptr [bp+18]
wUserIP		equ	word ptr [bp+20]
wUserCS		equ	word ptr [bp+22]
wUserFlag 	equ	word ptr [bp+24]

		endif

;----------------------- Drive Table Structure ----------------------;

uVol		struc
wVolBlkSize	dw	2048		; block size
dVolPathExtent	dd	0		; beginning block of path table
dVolPathSize	dd	0		; length in bytes of path table
dVolRootExtent	dd	0		; beginning block of root directory
dVolRootSize	dd	0		; length in bytes of root directory
sVolLabel	db	'VolumeLabel'	; volume label
		db	0		; for alignment
dVolHash	dd	0		; checksum of vtoc sector
wVolFormat	dw	0		; 0000=HSG, FFFF=ISO format
lVolTaskTable	db	0		; beginning of task table
uVol		ends

;-------------- Task Table Structure within Drive Table -------------;

uTask		struc
wTaskID		dw	0		; task ID, -1 if empty
dCurDirExtent 	dd	0		; CD starting block number
sCurDir	 	db	66 dup(0)	; current directory
uTask		ends
TTESIZE		equ	72		; length of this structure

;---------------------- Handle Table Structure ----------------------;

uHTStruc	struc
bHTDrive	db	?		; relative cd-rom drive number
bHTDupCount	db	?		; number of psp handles for this entry
dHTExtent 	dd	?		; starting block of file
dHTSize	 	dd	?		; file size in bytes
dHTPos	 	dd	?		; current read/write pointer
wHTTime	 	dw	?		; creation time
wHTDate	 	dw	?		; creation date
uHTStruc	ends
HTLEN	 	equ	18		; length of the above structure

;------------------------ Cache Index Structure ---------------------;

uCIStruc	struc
dCIVolHash	dd	?		; identifies the cd-rom volume
dCISector	db	3 dup(?)	; cd-rom sector number
bCILocation	db	?		; entry number within this bucket
uCIStruc	ends
CILEN		equ	8		; length of the above structure

	page

cgroup	group	mainseg,initseg
mainseg	segment	word public
	assume	cs:cgroup,ds:cgroup

;--------------------------- Device Header --------------------------;

	dd	-1			; pointer to next driver
	dw	2000h			; block,no-IOCTL,non-IBM,non-removable
	dw	offset Strategy
	dw	offset Interrupt
	db	1			; number of units (ignored by DOS)
	db	7 dup(0)		; unused

;---------------------------- Constants -----------------------------;

lDFTable	label	word		; DRIVER FUNCTION VECTORS
		dw	offset cgroup:init ; initialize
		dw	offset MediaCheck  ; media check
		dw	offset BuildBPB	; build BPB
		dw	offset errndt	; ioctl input       (invalid)
		dw	offset Input 	; input
		dw	offset errdnr	; nondestruct input (invalid)
		dw	offset errdnr	; input status      (invalid)
		dw	offset errdnr	; input flush       (invalid)
		dw	offset errwpv	; output            (not supported)
		dw	offset errwpv	; output w/verify   (not supported)
		dw	offset errdnr	; output status     (invalid)
		dw	offset errdnr	; output flush      (invalid)
		dw	offset errndt	; ioctl output      (invalid)

;	So the OS thinks we're some sort of valid block device, the BPB
;	indicates a fixed disk with 1 boot sector, 1 FAT sector, 1 
;	directory sector, and 1 data sector.

lBootSector	label	byte		; DUMMY BOOT SECTOR
		db	0ebh,0,90h	; faked short jump
		db	'SLCDEX  '	; OEM name
lBPB		label	byte		; DUMMY BIOS PARAMETER BLOCK
		dw	512		; bytes per sector
		db	1		; sectors per cluster
		dw	1		; reserved sectors
		db	1		; number of FATs
		dw	16		; max root directory entries
		dw	4		; number of sectors on drive
		db	0f8h		; media descriptor (fixed disk)
		dw	1		; sectors per FAT
		dw	4		; sectors per track
		dw	1		; number of heads
		dw	0		; number of hidden sectors
BOOTLEN		equ	$-lBootSector

		even
wpBPB		dw	24 dup(offset lBPB) ; this is the BPB array

lFAT		label	byte		; DUMMY FAT
		db	0f8h,0ffh,0ffh,0 ; media type / 2 dummy clusters 
FATLEN		equ	$-lFAT

	page
wZero		dw	0
wTen		dw	10

lDDDTable 	label	word		; DUMMY DRIVE DATA POINTERS/LENGTHS
		dw	offset lBootSector,BOOTLEN ; sector 0 = boot sector
		dw	offset lFAT,FATLEN ; sector 1 = FAT
		dw	offset wZero,2	; sector 2 = directory
		dw	offset wZero,2	; sector 3 = data

lInt21Table 	label	word
		dw	offset Fun0f	 ; 0F open file
		dw	offset Fun10	 ; 10 close file
		dw	offset Fun11	 ; 11 search for first entry
		dw	offset Fun12	 ; 12 search for next entry
		dw	offset Fun13	 ; 13 delete file
		dw	offset Fun14	 ; 14 sequential read
		dw	offset Fun15	 ; 15 sequential write
		dw	offset Fun16	 ; 16 create file 
		dw	offset Fun17	 ; 17 rename file 
		dw	offset Int21Pass ; 18 
		dw	offset Int21Pass ; 19 get current drive
		dw	offset Int21Pass ; 1A set DTA
		dw	offset Fun1b	 ; 1B FAT info 
		dw	offset Fun1c	 ; 1C FAT info for specific device
		dw	offset Int21Pass ; 1D 
		dw	offset Int21Pass ; 1E 
		dw	offset Int21Pass ; 1F get DPB of default drive
		dw	offset Int21Pass ; 20 
		dw	offset Fun21	 ; 21 random read
		dw	offset Fun22	 ; 22 random write
		dw	offset Fun23	 ; 23 file size
		dw	offset Int21Pass ; 24 set rel record field
		dw	offset Int21Pass ; 25 set interrupt vector
		dw	offset Int21Pass ; 26 create new PSP
		dw	offset Fun27	 ; 27 random block read
		dw	offset Fun28	 ; 28 random block write
		dw	offset Int21Pass ; 29 parse filename
		dw	offset Int21Pass ; 2A get date 
		dw	offset Int21Pass ; 2B set date
		dw	offset Int21Pass ; 2C get time
		dw	offset Int21Pass ; 2D set time
		dw	offset Int21Pass ; 2E set/clear verify switch
		dw	offset Int21Pass ; 2F get DTA
		dw	offset Int21Pass ; 30 get dos version
		dw	offset Int21Pass ; 31 terminate and stay resident
		dw	offset Int21Pass ; 32 get DPB
		dw	offset Int21Pass ; 33 ctrl-break check
		dw	offset Int21Pass ; 34 get indos flag address
		dw	offset Int21Pass ; 35 get interrupt vector
		dw	offset Fun36  	 ; 36 get disk free space
		dw	offset Int21Pass ; 37 
		dw	offset Int21Pass ; 38 return country information
		dw	offset Fun39	 ; 39 MKDIR
		dw	offset Fun3a	 ; 3A RMDIR 
		dw	offset Fun3b  	 ; 3B CHDIR
		dw	offset Fun3c	 ; 3C handle create
		dw	offset Fun3d	 ; 3D handle open
		dw	offset Fun3e	 ; 3E handle close
		dw	offset Fun3f	 ; 3F handle read
		dw	offset Fun40	 ; 40 handle write
		dw	offset Fun41	 ; 41 delete a file
		dw	offset Fun42	 ; 42 LSEEK
		dw	offset Fun43	 ; 43 change file mode
		dw	offset Fun44     ; 44 IOCTL
		dw	offset Fun45     ; 45 handle duplicate
		dw	offset Fun46     ; 46 handle force duplicate
		dw	offset Fun47  	 ; 47 get current directory
		dw	offset Int21Pass ; 48 allocate memory
		dw	offset Int21Pass ; 49 free memory
		dw	offset Int21Pass ; 4A modify allocated memory
		dw	offset Fun4b	 ; 4B EXEC
		dw	offset Fun4c     ; 4C terminate
		dw	offset Int21Pass ; 4D get return code
		dw	offset Fun4e  	 ; 4E find first matching file
		dw	offset Fun4f	 ; 4F find next matching file
		dw	offset Int21Pass ; 50 set psp address
		dw	offset Int21Pass ; 51 get psp address
		dw	offset Int21Pass ; 52 
		dw	offset Int21Pass ; 53 
		dw	offset Int21Pass ; 54 get verify setting
		dw	offset Int21Pass ; 55 
		dw	offset Fun56	 ; 56 rename file
		dw	offset Fun57	 ; 57 get/set file date/time
I21TLEN		equ	$-lInt21Table

lInt2fTable 	label	word
		dw	offset F2f00	 ; 00 get number of cd-rom drives
		dw	offset F2f01	 ; 01 get cd-rom drive device list
		dw	offset F2f02	 ; 02 get copyright file name
		dw	offset F2f03	 ; 03 get abstract file name
		dw	offset F2f04	 ; 04 get bibliographic doc file name
		dw	offset F2f05	 ; 05 read vtoc
		dw	offset i2fdone   ; 06 turn debugging on
		dw	offset i2fdone	 ; 07 turn debugging off
		dw	offset F2f08	 ; 08 absolute disk read
		dw	offset i2fdone	 ; 09 absolute disk write
		dw	offset i2fdone	 ; 0A reserved
		dw	offset F2f0b	 ; 0B cd-rom drive check
		dw	offset F2f0c	 ; 0C this driver version
		dw	offset F2f0d	 ; 0D get cd-rom drive letters
		dw	offset F2f0e	 ; 0E get/set volume descriptor pref
		dw	offset F2f0f	 ; 0F get directory entry
		dw	offset F2f10	 ; 10 send device request
		dw	offset F2f11	 ; 11 get statistics (we added this)
I2FTLEN		equ	$-lInt2fTable

		if	DEBUG
sHexTable 	db	'0123456789ABCDEF'
		endif

		page

;------------------------- Global Variables -------------------------;

		even

wMaxDrives	dw	1		; number of CD-ROM drives supported
wMaxTasks	dw	1		; number of MOS tasks supported
wpHTBegin	dw	offset cgroup:initseg ; start address of handle table
wpHTEnd		dw	offset cgroup:initseg+(HTLEN*20)
wHandOff	dw	200		; bias added to handle table entries
wpDriveTable	dw	0		; seg address of drive table
wDTESize	dw	0		; length of each drive table entry
dLongSize	dw	16*2048,0	; min bytes in a noncached read
wStartTime	dw	0		; timer value at driver init time
wDemoDiff	dw	0		; time elapsed as of last check

dpReqHeader	dd	0		; saves request header address
dpOldInt20 	dd	0		; previous int20 vector
dpOldInt21 	dd	0		; previous int21 vector
dpOldSCB21 	dd	0		; previous SCBFAR21 pointer
dpOldInt25 	dd	0		; previous int25 vector
dpOldInt2f 	dd	0		; previous int2f vector
dpMOSSCB	dd	0		; pointer to mos scb
wIndexBuffAddr	dw	0		; index buffer segment address
wDataBuffAddr  	dw	0		; data buffer segment address
dBuffSector	dd	0		; sector number currently buffered
bDriveFirst 	db	0		; our first drive: 0=A,1=B,etc
bDriveLast  	db	0		; our last drive

waDosParamList	dw	0,0803h,0200h,8 dup(0) ; to set extended errors

sDevName	db	'MSCD001 ',0    ; hardware device name
lDevHdrCB 	label	byte		; get-device-header control block
	 	db	0		; command code
dDevAddr	dd	0		; address of device header
dDevStrat 	dd	0		; strategy routine entry
dDevInter 	dd	0		; interrupt routine entry

lReadLong	label	byte		; "READ LONG" REQUEST HEADER
		db	RLLENGTH	; rh length
		db	0		; subunit
		db	128		; command code = read long
wRLStat		dw	0		; status
		db	8 dup(0)	; reserved
		db	0		; HSG addressing mode
dpRLXfer	dd	0		; transfer address
wRLNoSec 	dw	0		; number of sectors to read
dRLStartSec 	dd	0		; starting sector number
		db	0		; data read mode = cooked
		db	0		; interleave size
		db	0		; interleave skip factor
RLLENGTH 	equ	$-lReadLong

lIOCtlInput	label	byte		; "IOCTL INPUT" REQUEST HEADER
		db	IILENGTH	; rh length
bIIUnit		db	0		; subunit
		db	3		; command code = ioctl input
wIIStat		dw	0		; status
		db	8 dup(0)	; reserved
		db	0		; dummy media descriptor
dpIIXfer	dd	0		; transfer address
wIIBytes 	dw	2		; number of bytes to read
		dw	0		; dummy starting sector number
		dd	0		; ptr to req'd vol id if error 0fh
IILENGTH 	equ	$-lIOCtlInput

lCBMedia	db	9,0		; "media changed" command block

		even
lDirRecord	label	byte		; DIRECTORY RECORD WORK AREA
bDRLength 	db	0		; length of record
	 	db	0		; ext attribute record length
dDRExtent 	dd	0		; location of extent
	 	dd	0		; same in motorola format
dDRFileSize 	dd	0		; data length
	 	dd	0		; same in motorola format
sDRDateTime	db	6 dup(0)	; recording date and time
bDRFlags	db	0		; file flags
	 	db	0		; reserved
	 	db	0		; interleave size
	 	db	0		; interleave skip factor
	 	dw	0		; volume set sequence number
	 	dw	0		; same in motorola format
bDRNameLen	db	0		; length of filename
sDRName	 	db	32 dup(0)	; filename

		even
lPathTableEntry	label	byte		; PATH TABLE ENTRY WORK AREA
dPTExtent 	dd	0
	 	db	0
bPTNameLen	db	0
wPTParent 	dw	0
sPTName	 	db	32 dup(0)

wPathNum1	dw	0		; last-found path table item number
wPathNum2	dw	0		; working path table item number

dRNBlock 	dd	0		; next block number to read
dRNFileSize	dd	0		; length of file being read
dRNPosition	dd	0		; current byte position in file
dRNTarget 	dd	0		; target address for sequential reads
dRNBytesLeft 	dd	0		; bytes left to read for this request
dRNBytesRead	dd	0		; length read so far for this request

wNoRecords	dw	0		; scratch area
wTrash	 	dw	0		; scratch area

wSectorSize	dw	2048		; cd-rom sector size
wThisBlkSize	dw	2048		; blocksize for current volume
wThisFormat	dw	0		; 0=HSG, FFFF=ISO
wThisFCBOffset	dw	0		; 0=normal, 7=extended fcb
bThisAtt	db	0		; attributes for current function
bThisDrive	db	0		; drive for the current function
sWorkDir	db	66 dup(0)	; path/filename for current function

sWSName1	db	11 dup(0)	; work areas for name compares
sWSName2	db	11 dup(0)

wpPathEnd 	dw	0		; end of path portion of ASCIIZ string
waSaveArea 	dw	16 dup(0)	; savearea for critical errors
	 	db	0		; unused 
bEnqCount	db	0		; 1 if this driver is busy

		if	CACHELOGIC

;	Cacheing-related variables follow

		even

dNoLongReads	dw	0,0		; statistical accumulators
dNoShortReads	dw	0,0
dNoCacheHits	dw	0,0
dNoCacheRewrites dw	0,0
wNoCacheOpens	dw	0
wNoCacheErrors	dw	0
sCacheFileName	db	'C:\CDLINKCA.CHE',51 dup(0)

fNewCacheEntry	db	'N'		; if writing new cache entry

		even
lCacheHeader	label	byte
wBucketSectors	dw	20		  ; no of 2k sectors per cache bucket
wBucketBytes	dw	20*(CILEN+2048+8) ; bytes per bucket 
wCacheBuckets	dw	3		  ; no of buckets in the cache file
CACHEHDRLEN	equ	8		  ; length of cache header

		endif

wCacheIxBytes	dw	20*CILEN	  ; length of each cache bucket index

		if	EXECCODE

;------------------------- Executor Stuff ---------------------------;

		even
vrfyproc 	dd	0
		public	vrfyproc
execint21	dd	0		;0992
		public	execint21	;0992

		endif

		page

;---------------------- Driver Entry Routines -----------------------;

Strategy proc	far
	mov	word ptr cs:[dpReqHeader],bx
	mov	word ptr cs:[dpReqHeader+2],es
	ret
Strategy endp

Interrupt proc	far

	call	saveregs
	mov	bp,sp
	push	cs
	pop	ds
	les	bx,[dpReqHeader]

	mov	al,es:[bx+2]		; vector by command code
	cbw
	shl	ax,1
	mov	di,ax
	call	[di+lDFTable]

	call	restregs
	ret

Interrupt endp

;------------------ Assorted Driver Function Exits ------------------;

errwpv	label	near
	or	word ptr es:[bx+3],8000h ; write protect violation
	jmp	short done
errndt	label	near
	mov	word ptr es:[bx+18],0	 ; no data transferred
errdnr	label	near
	or	word ptr es:[bx+3],8002h ; device not ready
done	label	near
	or	word ptr es:[bx+3],0100h ; complete
nearret	proc	near
	ret
nearret	endp

;--------------------------- Media Check ----------------------------;

MediaCheck label near
	mov	byte ptr es:[bx+14],1	; media not changed
	jmp	done

;--------------------------- Build BPB ------------------------------;

BuildBPB label	near
	mov	word ptr es:[bx+18],offset wpBPB
	mov	word ptr es:[bx+20],ds
	jmp	done

;----------------------------- Input --------------------------------;

Input	label	near
	cld
	push	es

	les	di,es:[bx+14]		; clear target buffer
	xor	ax,ax
	mov	cx,256
	rep	stosw

	pop	es
	mov	si,es:[bx+20]		; starting sector number to read
	push	es

	les	di,es:[bx+14]		; target address
	or	si,si			; if sector 0, set signature
	jnz	inskip0
	mov	word ptr es:[di+510],0aa55h
inskip0:
	cmp	si,3			; ensure range is 0-3
	jbe	inskip1
	mov	si,3
inskip1:
	shl	si,1			; compute lDDDTable index
	shl	si,1

	mov	cx,[si+lDDDTable+2]	; length
	mov	si,[si+lDDDTable]	; source address
	rep	movsb

	pop	es

	mov	word ptr es:[bx+18],1	; number of sectors transferred
	jmp	done

	page

;---------------------- Interrupt 20/21 Handler ---------------------;

EntInt20 label	near
	mov	ah,0

EntInt21 label	near
	call	saveregs
	mov	bp,sp
	push	cs
	pop	ds
i21cont:
	sti
	or	[bSwitches],10000000b	; indicate int21 call
	call	getdevad		; ensure we have device address
	or	ah,ah			; check for function 00
	jz	JFun00
	cmp	ah,6ch			; check for function 6c
	je	JFun6c
	sub	ah,0fh			; handle all others with vector table
	jc	Int21Pass
	cmp	ah,I21TLEN/2
	jae	Int21Pass
	mov	bl,ah			; get function code from caller's ah
	mov	bh,0
	shl	bx,1
	jmp	[bx+lInt21Table]
JFun00:
	jmp	Fun00
JFun6c:
	jmp	Fun6c
i21stcx:
	or	byte ptr [wUserFlag],01h ; set caller's carry flag
	xor	ah,ah			; set error code
	mov	[wUserAX],ax
	jmp	short i21sex
i21fcberr:
	mov	byte ptr [wUserAX],0ffh ; return FF in al
	xor	ah,ah
i21sex:
	call	SetError		; set extended error
	jmp	short i21done
i21clcx:
	and	byte ptr [wUserFlag],0feh ; clear caller's carry flag
i21done:
	call	Deque
	mov	sp,bp
	call	restregs
	iret
Int21Deque:
	call	Deque
Int21Pass:
	mov	sp,bp			; can abort to here from anywhere
	test	[bSwitches],00001000b	; check if came from scbfar21
	call	restregs
	cli
	jnz	i21scbx			; yes, skip
	jmp	dword ptr cs:[dpOldInt21]
i21scbx:
	jmp	dword ptr cs:[dpOldSCB21]

entscb21 label	near
	call	saveregs
	mov	bp,sp
	push	cs
	pop	ds
	or	[bSwitches],00001000b	; indicate coming from scbfar21
	jmp	i21cont

SetError proc	near
	mov	[waDosParamList],ax
	mov	ax,5d0ah		; set extended error information
	mov	dx,offset waDosParamList
	call	int21
	ret
SetError endp

	if	DEBUG

tracer	proc	near
	pushf
	push	cx
	push	bx
	push	ax
	mov	al,'D'
	call	dispchar
	mov	bl,byte ptr [wUserAX+1]
	mov	bh,0
	mov	cl,4
	shr	bl,cl
	mov	al,[bx+sHexTable]
	call	dispchar
	mov	bl,byte ptr [wUserAX+1]
	and	bx,000fh
	mov	al,[bx+sHexTable]
	call	dispchar
	mov	bl,byte ptr [wUserAX+0]
	mov	bh,0
	mov	cl,4
	shr	bl,cl
	mov	al,[bx+sHexTable]
	call	dispchar
	mov	bl,byte ptr [wUserAX+0]
	and	bx,000fh
	mov	al,[bx+sHexTable]
	call	dispchar
	mov	al,' '
	call	dispchar
	pop	ax
	pop	bx
	pop	cx
	popf
	ret
tracer	endp

dispchar proc	near
;	mov	ah,0eh
;	mov	bl,07h
;	int	10h

	push	dx
	mov	dx,02e8h		; com4
	mov	bl,al
dcbusyloop:
	add	dx,5
	in	al,dx
	sub	dx,5
	test	al,20h
	jz	dcbusyloop
	mov	al,bl
	out	dx,al
	pop	dx
	ret
dispchar endp

	endif

;-------------------- Interrupt 2F Entry Point ----------------------;

EntInt2f label	near
	cmp	ah,15h			; we handle only if ah=15h
	jne	Int2fFastExit
	call	saveregs
	mov	bp,sp
	push	cs
	pop	ds
	sti
	cmp	al,I2FTLEN/2
	jae	Int2fPass

	if	DEBUG
	push	ax
	mov	al,'M'
	call	dispchar
	pop	ax
	push	ax
	mov	bl,al
	mov	bh,0
	mov	cl,4
	shr	bl,cl
	mov	al,[bx+sHexTable]
	call	dispchar
	pop	ax
	push	ax
	mov	bl,al
	and	bx,000fh
	mov	al,[bx+sHexTable]
	call	dispchar
	mov	al,' '
	call	dispchar
	pop	ax
	endif

	call	getdevad		; ensure we have device address
	cbw
	mov	bx,ax
	shl	bx,1
	jmp	[bx+lInt2fTable]
i2fstcx:
	xor	ah,ah			; set error code
	mov	[wUserAX],ax
	or	byte ptr [wUserFlag],01h ; set caller's carry flag
	jmp	short i2fdone
i2fclcx:
	and	byte ptr [wUserFlag],0feh ; clear caller's carry flag
i2fdone:
	mov	sp,bp
	call	restregs
	iret
Int2fPass:
	mov	sp,bp			; can abort to here from anywhere
	call	restregs
	cli
Int2fFastExit:
	jmp	dword ptr cs:[dpOldInt2f]

	page

;------------------------- Terminate Process ------------------------;

Fun00	label	near
Fun4c	label	near

	if	DEBUG
	call	tracer
	endif

	mov	ah,51h			; address current psp
	call	int21
	mov	es,bx
	mov	cx,es:[32h]		; cx is number of entries in psp
	les	di,es:[34h]		; point to psp handle table
F00Loop:
	mov	al,es:[di]
	cmp	al,0ffh			; skip if unused slot
	je	F00Next
	sub	al,byte ptr [wHandOff]
	jb	F00Next			; skip if not a cd-rom handle
	mov	bl,HTLEN		; compute index into our handle table
	mul	bl
	mov	bx,ax
	add	bx,[wpHTBegin]
	cmp	bx,[wpHTEnd]
	jae	F00Next
	mov	byte ptr es:[di],0ffh	; mark PSP entry as available
	mov	[bx+bHTDrive],0ffh	; also our handle table entry
F00Next:
	inc	di
	loop	F00Loop
	jmp	Int21Pass

	page
;--------------------------- Open FCB -------------------------------;

Fun0f	label	near
	call	funfcbno		; entry logic for unopened-fcb call
	call	getfcbnm		; put filename in sWSName1
	call	ckdevnam		; get out if reserved device name
	call	checkvol		; need volume info now
	call	AddrTask
	mov	ax,word ptr es:[bx+dCurDirExtent] ; scan current directory
	mov	dx,word ptr es:[bx+dCurDirExtent+2]
	call	sdisetup
	call	sdinext
	jc	f0ffnf			; jump if file not found
	mov	es,[wUserDS]
	mov	di,[wUserDX]
	add	di,[wThisFCBOffset]
	cld
	mov	al,[bThisDrive]		; set drive number in fcb
	inc	al
	stosb
	add	di,11
	xor	ax,ax
	stosw				; current block
	mov	al,80h
	stosw				; record size
	mov	si,offset dDRFileSize	; length in bytes of file
	movsw
	movsw
	call	stodatim		; date and time
	mov	si,offset dDRExtent	; beginning sector of file
	movsw
	movsw
	mov	ax,5a5ah		;930621 set our signature
	stosw				;930621
	stosw				;930621
f0fgood:
	mov	byte ptr [wUserAX],0	; open successful
	jmp	i21done
f0ffnf:
	mov	al,2			; file not found
	jmp	i21fcberr

;-------------------------- Close FCB -------------------------------;

Fun10	label	near
	call	funfcbop		; pass the buck if not a cd-rom drive
	jmp	f0fgood			; otherwise just tell 'em it worked

	page

;------------- Find First or Next Directory Entry (FCB) -------------;

Fun11	label	near
Fun12	label	near
	call	funfcbno		; entry logic for unopened-fcb call
	call	getfcbnm		; copy filename to sWSName1

;	Note that DOS does support function 11 on a reserved device
;	name, taking action without accessing the current drive.  We
;	will pass these on to the OS, since we have no desire to deal
;	with that kind of magic.

	call	ckdevnam		; get out if reserved device name
	call	findfcb			; do the find
	jc	f11bad			; jump if not found
	mov	al,[bThisDrive]
	inc	al
	stosb	
	add	di,11
	mov	si,offset dRNBlock
	movsw
	movsw
	mov	si,offset dRNBytesLeft
	movsw
	movsw
	mov	ax,bx
	stosw

	mov	ah,2fh			; get DTA in es:bx
	call	int21
	mov	di,bx
	cld
	cmp	[wThisFCBOffset],0	; normal fcb?
	je	f11skipx		; yes, skip extended stuff
	mov	al,0ffh			; indicate extended fcb
	stosb
	xor	al,al			; 5 zero bytes
	mov	cx,5
	rep	stosb
	mov	al,[bThisAtt]		; attributes and drive
	stosb
f11skipx:
	mov	al,[bThisDrive]
	inc	al
	stosb
	mov	si,offset sDRName
	call	stofcdname		; store formatted name
	call	cnvattr			; store attributes
	stosb
	xor	ax,ax			; now 10 reserved bytes
	mov	cl,5
	rep	stosw
	call	stodatim		; store creation time and date
	xor	ax,ax			; starting cluster
	stosw
	mov	si,offset dDRFileSize	; file size
	movsw
	movsw
f11good:
	jmp	f0fgood
f11bad:
	cmp	byte ptr [wUserAX+1],11h ; "find first" function?
	je	f0ffnf			; yes, indicate file not found
	mov	al,18			; else indicate no more files
	jmp	i21fcberr

getfcbnm proc	near
	lea	si,[bx+1]		; save fcb filename to sWSName1
	mov	di,offset sWSName1
	mov	cx,11
	push	ds
	push	es
	pop	ds
	pop	es
	cld
	rep	movsb
	push	ds
	push	es
	pop	ds
	pop	es
	ret
getfcbnm endp

findfcb	proc	near
	test	[bThisAtt],08h		; looking for volume label?
	jnz	ffcbad			; yes, indicate none there
	cmp	byte ptr [wUserAX+1],12h
	je	f12setup
	call	checkvol
	call	AddrTask
	mov	ax,word ptr es:[bx+dCurDirExtent] ; init for fun 11 or 23
	mov	dx,word ptr es:[bx+dCurDirExtent+2]
	call	sdisetup
	jmp	short f11cont
f12setup:
	push	ds			; initialize for function 12
	pop	es
	mov	ds,[wUserDS]
	lea	si,[bx+12]		; current sector number
	mov	di,offset dRNBlock
	cld
	lodsw
	stosw
	mov	dx,ax			; dx:ax will hold it
	lodsw
	stosw
	xchg	dx,ax
	mov	di,offset dRNBytesLeft	; remaining directory length
	movsw
	movsw
	mov	bx,ds:[si]		; current sector offset
	push	es
	pop	ds
	call	ReadBlock		; dx:ax used here
f11cont:
	call	sdinext
	jc	ffcbad
	mov	es,[wUserDS]		; save state info in caller's fcb
	mov	di,[wUserDX]
	add	di,[wThisFCBOffset]
	cld
	clc
	ret
ffcbad:
	stc
	ret
findfcb	endp

;-------------------- FCB Delete, Create, Rename --------------------;

Fun13	label	near			; Delete
Fun16	label	near			; Create
Fun17	label	near			; Rename
	call	funfcbno		; entry logic for unopened-fcb call
	mov	al,19			; indicate write protect violation
	jmp	i21fcberr

;---------------------- Sequential Read (FCB) -----------------------;

Fun14	label	near
	call	funfcbop		; entry logic for open FCB
	mov	[wNoRecords],1		; number of records to read
f14stuff:
	cmp	word ptr es:[bx+30],5a5ah ;930621 check if we opened it
	je	f14ours			  ;930621 yes, jump
	mov	al,1			  ;930621 no, return eof
	jmp	f14done			  ;930621 to accomodate Xtree Gold
f14ours:
	push	es			; point ds to fcb
	pop	ds
	assume	ds:nothing

	mov	di,bx
	push	[di+26]			; beginning sector
	push	[di+24]
	push	[di+18]			; file size
	push	[di+16]
	mov	ax,[di+12]		; compute curblk*recsize*128
	mul	word ptr [di+14]
	mov	ch,dl
	mov	cl,ah
	mov	bh,al
	mov	bl,0
	shr	cx,1
	rcr	bx,1
	mov	al,[di+32]		; add currec*recsize to get position
	cbw
	mul	word ptr [di+14]
	add	ax,bx
	adc	dx,cx
	push	dx
	push	ax
	mov	ax,[di+14]		; compute number of bytes to read

	push	cs
	pop	ds
	assume	ds:mainseg

	mul	[wNoRecords]
	push	dx
	push	ax
	mov	ah,2fh			; get DTA in es:bx
	call	int21
	push	es			; target
	push	bx

	call	readfile

	mov	al,1
	mov	dx,word ptr [dRNBytesRead]
	or	dx,word ptr [dRNBytesRead+2]
	jz	f14done
	mov	di,[wUserDX]
	add	di,[wThisFCBOffset]
	mov	ds,[wUserDS]
	assume	ds:nothing
	add	byte ptr [di+32],1
	jnl	f14skip1
	mov	byte ptr [di+32],0
	inc	word ptr [di+12]
f14skip1:
	mov	ax,[di+14]		; requested read length
	push	cs
	pop	ds
	assume	ds:mainseg
	mul	[wNoRecords]
	sub	ax,word ptr [dRNBytesRead]
	mov	cx,ax
	mov	al,0
	jz	f14done
	les	di,[dRNTarget]
	cld
	rep	stosb
	mov	al,3
f14done:
	mov	byte ptr [wUserAX],al
	jmp	i21done

;---------------------- Sequential Write (FCB) ----------------------;

Fun15	label	near			; sequential write
Fun22	label	near			; random write
Fun28	label	near			; random block write
	call	funfcbop		; entry logic for open FCB
	mov	byte ptr [wUserAX],01h	; indicate full disk
	jmp	i21done

;------------------- Allocation Table Information -------------------;

Fun1b	label	near
	call	GetCurDrive		; current drive in al
f1bent1c:
	call	CheckDrive		; test drive in al
	mov	byte ptr [wUserAX],1	; sectors per cluster
	mov	[wUserBX],offset lFAT	; pointer to media descriptor byte
	mov	[wUserDS],ds
	mov	[wUserCX],2048		; bytes/sector
	mov	[wUserDX],0ffffh	; clusters/drive
	jmp	i21done
Fun1c:					; function 1C enters here
	mov	al,byte ptr [wUserDX]
	sub	al,1
	jnc	f1bent1c
	jmp	Fun1b

;------------------------ Random Read (FCB) -------------------------;

Fun21	label	near
	mov	ax,1			; number of records to read
f21stuff:
	push	ax
	call	funfcbop		; entry logic for open FCB
	pop	ax
	mov	[wNoRecords],ax
	mov	ax,es:[bx+33]
	mov	dl,es:[bx+35]
	mov	cl,al
	shl	ax,1			; ranrec#/128 = current block
	rcl	dx,1
	mov	al,ah
	mov	ah,dl
	mov	es:[bx+12],ax
	and	cl,7fh			; current record is low 7 bits
	mov	es:[bx+32],cl
	mov	ax,1			; number of records to read
	mov	ax,[wNoRecords]
	add	word ptr es:[bx+33],ax	; increment random record number
	adc	word ptr es:[bx+35],0
	jmp	f14stuff		; func 14 will do the rest
Fun27:
	mov	ax,[wUserCX]
	jmp	f21stuff

;-------------------- Determine File Size (FCB) ---------------------;

Fun23	label	near
	call	funfcbno		; entry logic for unopened-fcb call
	call	getfcbnm		; copy filename to sWSName1
	call	findfcb			; do the find
	jc	f23bad			; jump if not found
	mov	ax,word ptr [dDRFileSize]
	mov	dx,word ptr [dDRFileSize+2]
	mov	cx,es:[di+14]
	call	longdiv
	mov	es:[di+33],ax
	mov	es:[di+35],dx
	jmp	f0fgood			; indicate successful find
f23bad:
	jmp	f0ffnf			; no match

longdiv	proc	near
	jcxz	ldiexit			; can't divide by zero
	push	ax
	mov	ax,dx
	xor	dx,dx
	div	cx
	mov	si,ax			; si=hhhh/cx, remainder in dx
	pop	ax
	div	cx
	xchg	dx,si
ldiexit:
	ret
longdiv	endp

;----------------------- Get Disk Free Space ------------------------;

Fun36	label	near
	mov	al,byte ptr [wUserDX]
	sub	al,1
	jnc	f36gotdr
	call	GetCurDrive		; current drive in al
f36gotdr:
	call	CheckDrive
	mov	[wUserAX],1		; sectors per cluster
	mov	[wUserBX],0		; indicate no available clusters
	mov	[wUserCX],2048		; bytes/sector
	mov	[wUserDX],0ffffh	; clusters/drive
	jmp	i21done

;---------------------- Some Invalid Functions ----------------------;

Fun39	label	near			; MKDIR
Fun3a	label	near			; RMDIR
	mov	si,[wUserDX]		; offset to asciiz string
	call	getusend
	call	procpath		; digest the supplied path
	jmp	short F39accden
Fun3c	label	near			; Create File
Fun41	label	near			; Delete File
Fun56	label	near			; Rename File
	xor	ax,ax			; attributes for file search
	mov	si,[wUserDX]		; offset to asciiz string
	call	f3dfront
F39accden:
	mov	al,05h			; error: access denied
	jmp	i21stcx			; return with carry set

;---------------------- Set Current Directory -----------------------;

Fun3b	label	near
	mov	si,[wUserDX]		; offset to asciiz string
	call	getusend		; locate end of caller's path
	call	procpath		; digest the supplied path
	jc	f3bbad
	call	AddrTask
	mov	si,offset sWorkDir	; success - set new current directory
	lea	di,[bx+sCurDir]
	mov	cx,66/2
	cld
	rep	movsw
	mov	si,2
	and	si,[wThisFormat]	; si=2 if ISO, 0 if HSG
	add	si,offset dPTExtent	; set location of current directory
	lea	di,[bx+dCurDirExtent]
	movsw
	movsw
	mov	[wUserAX],0		; DOS does this
	jmp	i21clcx
f3bbad:
	mov	al,03h			; error: path not found
	jmp	i21stcx			; return with carry set

;------------------------ Open a File Handle ------------------------;

Fun3d	label	near
	mov	si,[wUserDX]		; offset to asciiz string
F3dMain:
	mov	al,07h			; include readonly/hidden/system files
	call	f3dfront		; front-end stuff - locate the file
	call	getfhand		; find a free handle table entry
	jc	f3dnhl			; error if no handles left
	mov	[wUserAX],ax		; the handle to return
	push	ds
	pop	es
	mov	di,bx
	cld
	mov	al,[bThisDrive]		; drive number
	mov	ah,1			; number of psp handles for this entry
	stosw
	mov	si,offset dDRExtent	; beginning sector of file
	movsw
	movsw
	mov	si,offset dDRFileSize	; length in bytes of file
	movsw
	movsw
	xor	ax,ax
	stosw				; current position in file
	stosw
	call	stodatim		; creation time & date
	jmp	i21clcx
f3dpnf:
	mov	al,03h			; error: path not found
	jmp	i21stcx
f3dfnf:
	mov	al,18			; if find first/next, indicate no more
	cmp	byte ptr [wUserAX+1],4eh
	je	f3dgoterr
	cmp	byte ptr [wUserAX+1],4fh
	je	f3dgoterr
	mov	al,02h			; error: file not found
f3dgoterr:
	jmp	i21stcx
f3dnhl:
	mov	al,04h			; error: no handles left
	jmp	i21stcx
f3dpass:
	jmp	Int21Pass

;----------------------- Extended Open/Create -----------------------;

Fun6c	label	near
	mov	si,[wUserSI]		; offset to asciiz string
	jmp	F3dMain			; otherwise treat as normal open

	page
;------------ Common Code for ASCIIZ Filename processing ------------;

f3dfront proc	near
	or	[bSwitches],01000000b	; indicate handle-style int21 call
	push	ax
	call	getusend		; locate end of caller's path
	cmp	di,si			; empty string?
	je	f3dpass			; yes, exit without deque
	call	getupend
	call	procpath		; digest the supplied path
	pop	ax
	jc	f3dpnf
	mov	[bThisAtt],al		; set search attributes
	push	ds			; put filename in sWSName1
	pop	es
	mov	si,[wpPathEnd]
	mov	ds,[wUserDS]
	cld
	lodsb
	call	ifslash			;0992
	je	f3dskp1
	cmp	al,':'
	je	f3dskp1
	dec	si
f3dskp1:
	mov	di,offset sWSName1
	call	stofname
	push	es
	pop	ds
	call	ckdevnam		; get out if device driver name
	mov	si,2
	and	si,[wThisFormat]	; si=2 if ISO, 0 if HSG
	mov	ax,word ptr [dPTExtent+si] ; scan directory for filename
	mov	dx,word ptr [dPTExtent+2+si]
	call	sdisetup
	call	sdinext
	jc	f3dfnf
	ret
f3dfront endp

;------------------- Get a free handle table entry ------------------;

getfhand proc	near
	call	getpsph			; find a free psp slot, handle in ax
	jc	gfhbad			; error if no more
	mov	bx,[wpHTBegin]
	mov	dx,[wHandOff]
gfhloop:
	cmp	[bx+bHTDrive],0ffh
	je	gfhgood
	inc	dx
	add	bx,HTLEN
	cmp	bx,[wpHTEnd]
	jb	gfhloop
gfhbad:
	stc
	ret
gfhgood:
	mov	es:[di],dl		; store index in PSP handle table
	clc				; the new handle is returned in ax
	ret
getfhand endp

getpsph proc	near
	mov	ah,51h			; get psp address
	call	int21
	mov	es,bx
	mov	cx,es:[32h]		; length of handle table
	les	di,es:[34h]		; address handle table
	mov	dx,di
	mov	al,-1			; look for an empty slot
	cld
	repne	scasb
	jne	gphbad			; error if no more
	dec	di
	mov	ax,di			; compute new file handle
	sub	ax,dx
	clc
	ret
gphbad:
	stc
	ret
getpsph endp

;-------------- Check if filename is a character device -------------;

ckdevnam proc	near
	push	bx
	cld
	les	bx,ds:[0]

	if	DOSCODE
	cmp	word ptr [sWSName1],'UN'	; NUL device check, required
	jne	cdnloop				; because this one is always
	cmp	word ptr [sWSName1+2],' L'	; first in the DOS chain
	je	cdnmatch
	endif

cdnloop:
	lea	di,[bx+10]
	mov	si,offset sWSName1
	mov	cx,4
	repe	cmpsw
	je	cdnmatch
	les	bx,es:[bx]
	cmp	bx,-1
	jne	cdnloop
	pop	bx
	ret
cdnmatch:
	jmp	Int21Deque
ckdevnam endp

	page

;----------------------- Close a File Handle ------------------------;

Fun3e	label	near
	call	prochand
	mov	byte ptr es:[di],0ffh	; mark PSP entry as available
	dec	[bx+bHTDupCount]	; decrement handle count
	jnz	F3eDone
	mov	[bx+bHTDrive],0ffh	; remove handle table entry if 0
F3eDone:
	jmp	i21clcx

prochand proc	near
	or	[bSwitches],01000000b	; indicate handle-style int21 call
	mov	ah,51h			; address the psp
	call	int21
	mov	es,bx
	les	di,es:[34h]
	add	di,[wUserBX]
	mov	bl,es:[di]		; get index into our handle table
	mov	bh,0
	sub	bx,[wHandOff]
	jb	prhpass
	mov	al,HTLEN
	mul	bl
	mov	bx,ax
	add	bx,[wpHTBegin]
	jc	prhpass
	cmp	bx,[wpHTEnd]
	jae	prhpass

	if	DEBUG
	call	tracer
	endif

	call	Enque			; serialize cd-rom logic

	mov	al,[bx+bHTDrive]	;930621  oops, we forgot this
	mov	[bThisDrive],al		;930621

	ret
prhpass:
	jmp	Int21Pass
prochand endp

;-------------------- Sequential Read (Handle) ----------------------;

Fun3f	label	near
	call	prochand
	push	bx
	push	word ptr [bx+dHTExtent+2] ; file starting sector
	push	word ptr [bx+dHTExtent]
	push	word ptr [bx+dHTSize+2]	; file size
	push	word ptr [bx+dHTSize]
	push	word ptr [bx+dHTPos+2]	; current position
	push	word ptr [bx+dHTPos]
	xor	ax,ax			; dword length to read
	push	ax
	push	[wUserCX]
	push	[wUserDS]		; target address
	push	[wUserDX]
	call	readfile
	pop	bx
	mov	ax,word ptr [dRNPosition]	; update position in handle table
	mov	word ptr [bx+dHTPos],ax
	mov	ax,word ptr [dRNPosition+2]
	mov	word ptr [bx+dHTPos+2],ax
	mov	ax,word ptr [dRNBytesRead]	; return length read
	mov	[wUserAX],ax
	jmp	i21clcx

readfile proc	near
	pop	[wTrash]
	pop	word ptr [dRNTarget]
	pop	word ptr [dRNTarget+2]
	pop	word ptr [dRNBytesLeft]
	pop	word ptr [dRNBytesLeft+2]
	pop	word ptr [dRNPosition]
	pop	word ptr [dRNPosition+2]
	pop	word ptr [dRNFileSize]
	pop	word ptr [dRNFileSize+2]
	pop	word ptr [dRNBlock]
	pop	word ptr [dRNBlock+2]
	push	[wTrash]

	mov	ax,word ptr [dRNPosition]   ; compute relative block number
	mov	dx,word ptr [dRNPosition+2] ;  from byte offset
	mov	cx,[wThisBlkSize]
	call	longdiv			    ; dx:ax=quotient, si=remainder

	add	word ptr [dRNBlock],ax	    ; dRNBlock tracks it in main loop
	adc	word ptr [dRNBlock+2],dx
	mov	cx,word ptr [dRNBytesLeft]  ; set bx:cx = bytes left this call
	mov	bx,word ptr [dRNBytesLeft+2]
	mov	ax,word ptr [dRNFileSize]   ; set dx:ax = bytes to end of file
	mov	dx,word ptr [dRNFileSize+2]
	sub	ax,word ptr [dRNPosition]
	sbb	dx,word ptr [dRNPosition+2]
	jb	rfieof			; if negative, indicate end-of-file
	cmp	dx,bx			; bytes to read > bytes left in file?
	ja	rfigotl
	jb	rfichgl
	cmp	ax,cx
	jae	rfigotl			; no, skip
rfichgl:
	mov	cx,ax			; yes, read only remaining length
	mov	bx,dx
	or	ax,dx
	jz	rfieof			; skip I/O if it's zero
rfigotl:
	mov	word ptr [dRNBytesLeft],cx ; remainder this call
	mov	word ptr [dRNBytesLeft+2],bx
	mov	word ptr [dRNBytesRead],cx ; indicate length caller will get
	mov	word ptr [dRNBytesRead+2],bx
	add	word ptr [dRNPosition],cx  ; update position
	adc	word ptr [dRNPosition+2],0
	jmp	short rfirloop
rfieof:
	xor	ax,ax
	mov	word ptr [dRNBytesRead],ax
	mov	word ptr [dRNBytesRead+2],ax
	ret
rfirloop:

	if	NOT DMA

	or	si,si			; determine if multi-sector read
	jnz	rfione

;;	go to rfione if not starting on a sector boundary

	mov	ax,word ptr [dRNBlock]
	mov	dx,word ptr [dRNBlock+2]
	mov	cx,[wThisBlkSize]
rfiloop2:
	cmp	cx,[wSectorSize]
	je	rfiout2
	shl	cx,1
	shr	dx,1
	rcr	ax,1
	jnc	rfiloop2
	jmp	short rfione
rfiout2:

;;	ok, dx:ax is now the sector we're starting on

	mov	cx,word ptr [dLongSize+2] ; do multi if enough sectors
	cmp	word ptr [dRNBytesLeft+2],cx
	ja	rfimult
	jb	rfione
	mov	cx,word ptr [dLongSize]
	cmp	word ptr [dRNBytesLeft],cx
	jae	rfimult
rfione:

	endif

	mov	ax,word ptr [dRNBlock]
	mov	dx,word ptr [dRNBlock+2]
	call	ReadBlock
	mov	cx,word ptr [dRNBytesLeft]
	add	cx,si			; compute offset+length to read
	jc	rfiskip1
	cmp	word ptr [dRNBytesLeft+2],0
	jne	rfiskip1
	cmp	cx,[wThisBlkSize]	; exceeds block size?
	jbe	rfiskip2		; no, skip
rfiskip1:
	mov	cx,[wThisBlkSize]	; yes, compute length to end of sector
rfiskip2:
	sub	cx,si
	sub	word ptr [dRNBytesLeft],cx
	sbb	word ptr [dRNBytesLeft+2],0
	push	ds
	push	es
	les	di,[dRNTarget]
	add	word ptr [dRNTarget],cx
	pop	ds
	cld
	shr	cx,1
	rep	movsw
	rcl	cx,1
	rep	movsb
	pop	ds
	add	word ptr [dRNBlock],1
	adc	word ptr [dRNBlock+2],0
rfiskip3:
	xor	si,si			; offset into next block
	mov	ax,word ptr [dRNBytesLeft]
	or	ax,word ptr [dRNBytesLeft+2]
	jz	rfiret
	jmp	rfirloop
rfiret:
	ret

	if	NOT DMA

rfimult:
	push	dx			; dx:ax is the starting sector number
	push	ax

	les	di,[dRNTarget]		; reading multiple whole sectors
	mov	ax,word ptr [dRNBytesLeft]
	mov	dx,word ptr [dRNBytesLeft+2]
	and	ax,0f800h
	sub	word ptr [dRNBytesLeft],ax ; update remaining bytes 
	sbb	word ptr [dRNBytesLeft+2],dx

	mov	bl,byte ptr [dRNTarget+3] ; update target segment:offset
	mov	cl,4
	ror	bx,cl
	add	word ptr [dRNTarget],ax
	adc	bl,dl
	rol	bx,cl
	mov	byte ptr [dRNTarget+3],bl

	push	dx			; update block number for next time
	push	ax
	div	[wThisBlkSize]
	add	word ptr [dRNBlock],ax
	adc	word ptr [dRNBlock+2],0
	pop	ax
	pop	dx

	div	[wSectorSize]		; compute number of sectors
	mov	cx,ax

	pop	ax			; retrieve starting sector number
	pop	dx

	call	ReadSectors
	jmp	rfiskip3

	endif

readfile endp

;-------------------- Sequential Write (Handle) ---------------------;

Fun40	label	near
	call	prochand
	mov	al,05h			; error: access denied
	jmp	i21stcx

;------------------------------ LSEEK -------------------------------;

Fun42	label	near
	call	prochand
	mov	ax,[wUserDX]
	mov	dx,[wUserCX]
	cmp	byte ptr [wUserAX],01h
	jb	f42got			; AL=0
	ja	f42eof
	add	ax,word ptr [bx+dHTPos]	; AL=1
	adc	dx,word ptr [bx+dHTPos+2]
	jmp	short f42got
f42eof:
	add	ax,word ptr [bx+dHTSize]	; AL=2
	adc	dx,word ptr [bx+dHTSize+2]
f42got:
	mov	word ptr [bx+dHTPos],ax
	mov	word ptr [bx+dHTPos+2],dx
	mov	[wUserAX],ax
	mov	[wUserDX],dx
	jmp	i21clcx

;-------------------- Get or Change File Mode -----------------------;

Fun43	label	near
	mov	al,17h			; include dir,rdonly,sys,hidden files
	mov	si,[wUserDX]		; offset to asciiz string
	call	f3dfront		; same startup as open
	cmp	byte ptr [wUserAX],0	; just getting the attribute?
	jne	f43bad			; no, error
	call	cnvattr			; convert attribute flags
	mov	[wUserCX],ax
	mov	[wUserAX],ax		; DOS does this!
	jmp	i21clcx
f43bad:
	mov	al,05h			; error: access denied
	jmp	i21stcx

;--------------------------- I/O Control ----------------------------;

Fun44	label	near
	cmp	byte ptr [wUserAX],0	; AL=0?
	je	F44Fun0			; yes, jump
	jmp	Int21Pass		; no, pass the buck
F44Fun0:
	call	prochand		; exit if not us
	mov	al,[bThisDrive]		; return drive number in dx bits 0-5
	cbw
	mov	[wUserDX],ax
	jmp	i21clcx

;---------------------- Duplicate File Handle -----------------------;

Fun45	label	near
	call	prochand		; exit if not us
	push	word ptr es:[di]	; save handle table entry
	push	bx			; save our HT pointer
	call	getpsph			; get a vacant psp slot
	mov	[wUserAX],ax		; return corresponding handle
	pop	bx
	pop	ax
	jc	F45Error		; jump if no more handles
	inc	[bx+bHTDupCount]	; increment dup count
	stosb				; plug index into psp slot
	jmp	i21clcx
F45Error:
	jmp	f3dnhl			; error - no more handles

;------------------- Force Duplicate File Handle --------------------;

;  Missing from this logic is the closing of the CX file handle, if it
;  is an open file.  This was ignored in the interests of simplicity
;  and code size and because it seemed unlikely to ever matter.

Fun46	label	near
	call	prochand		; exit if not us
	inc	[bx+bHTDupCount]	; increment dup count
	push	word ptr es:[di]	; save handle table entry
	mov	ah,51h			; address the psp
	call	int21
	mov	es,bx
	les	di,es:[34h]
	add	di,[wUserCX]		; address entry for 2nd handle
	pop	ax
	cld
	stosb				; plug index into psp slot
	jmp	i21clcx

;---------------------- Get Current Directory -----------------------;

Fun47	label	near
	mov	al,dl
	sub	al,1			; make drive zero-relative
	jnc	f47skip1
	call	GetCurDrive		; current drive in al
f47skip1:
	call	CheckDrive		; exit if not our drive
	call	AddrTask
	push	ds
	push	es
	mov	es,[wUserDS]		; address caller's buffer
	mov	di,[wUserSI]
	lea	si,[bx+sCurDir]
	pop	ds
	cld
f47loop:
	lodsb				; copy to caller's area
	stosb
	or	al,al
	jnz	f47loop
	pop	ds
	mov	[wUserAX],0100h		; trying to imitate DOS
	jmp	i21clcx

	if	EXECCODE

;------------------------- EXEC via Executor ------------------------;

;	For this version of CD-Link, we link in executor.obj.
;	This adds about 2K to the driver.  Note that our init code
;	(initseg) is a separate segment so it can link at the end.

Fun4b	label	near
	mov	es,[wUserDS]		; address asciiz string
	mov	si,[wUserDX]
	call	CheckPath		; go away if ds:dx not a cd-rom path
	mov	sp,bp			; restore registers as at EntInt21

	call	Deque			; this because CheckPath did an Enque
	call	restregs
	sti				; executor does not enable interrupts

	if	NOT DOSCODE
	sub	sp,8			; executor requires this if mos
	endif

	push	es			; executor requires es & ds on stack
	push	ds
	extrn	executor:near
	jmp	executor

	else

;--------------------- EXEC via PC-MOS SCBFAR21 ---------------------;

;	Some explanation is in order here.  This routine hooks
;	into the MOS "SCBFAR21" pointer which allows us to get
;	control when MOS's EXEC logic preforms file I/O.  We do
;	the hooking here because it doesn't work to do it at driver
;	init time (I'm not sure why).

Fun4b	label	near

	if	DEBUG
	call	tracer
	endif

	les	bx,[dpMOSSCB]		; if mos, redirect SCBFAR21 pointer
	or	bx,bx
	jz	f4bpass
	cmp	word ptr [dpOldSCB21+2],0
	jne	f4bpass
	mov	ax,offset entscb21
	xchg	ax,es:[bx+SCBFAR21]
	mov	word ptr [dpOldSCB21],ax
	mov	ax,cs
	xchg	ax,es:[bx+SCBFAR21+2]
	mov	word ptr [dpOldSCB21+2],ax
f4bpass:
	jmp	Int21Pass

	endif

;---------------------- Find First Matching File --------------------;

Fun4e	label	near
	mov	ax,[wUserCX]		; set search attributes
	mov	si,[wUserDX]		; offset to asciiz string
	call	f3dfront		; finds first file
f4ewrap:
	push	bx			; save directory sector offset
	mov	ah,2fh			; get dta address
	call	int21
	mov	di,bx
	mov	al,[bThisDrive]		; drive
	inc	al
	stosb
	mov	si,offset sWSName1	; search name
	mov	cx,11
	rep	movsb
	mov	si,offset dRNBlock	; current directory sector (3 bytes)
	movsw
	movsb
	mov	si,offset dRNBytesLeft	; remaining directory length
	movsb
	movsw
	pop	ax			; directory sector offset
	stosw
	mov	al,[bThisAtt]		; attribute flags for search
	stosb
	call	cnvattr			; attribute flags for this file
	stosb
	call	stodatim		; creation time and date
	mov	si,offset dDRFileSize	; file size
	movsw
	movsw
	mov	si,offset sDRName	; filename, asciiz format
	call	copyname
	mov	[wUserAX],0		; DOS does this!
	jmp	i21clcx

copyname proc	near
	mov	cx,0408h		;0992 target length limits
cpnloop:
	lodsb
	or	al,al
	jz	cpnend
	cmp	al,';'
	je	cpnend

	cmp	al,'.'			;0992 check if .ext reached
	jne	cpncklen		;0992 no, skip
	mov	cl,ch			;0992 yes, set max ramaining length
	xor	ch,ch			;0992
cpncklen:				;0992
	or	cl,cl			;0992 exceeded max length?
	jz	cpnloop			;0992 yes, skip this character
	dec	cl			;0992 no, count & continue

	cmp	al,0feh			; '.' and '..' conversion
	jne	cpnstore
	mov	al,'.'
cpnstore:
	stosb
	jmp	cpnloop
cpnend:
	xor	al,al
	stosb
	ret
copyname endp

;---------------------- Find Next Matching File ---------------------;

Fun4f	label	near
	or	[bSwitches],01000000b	; indicate handle-style int21 call
	mov	ah,2fh			; get dta address
	call	int21
	mov	al,es:[bx]		; drive id
	dec	al
	call	CheckDrive
	push	es
	push	ds
	pop	es
	pop	ds
	cld
	lea	si,[bx+1]		; name searching for
	mov	di,offset sWSName1
	mov	cx,11
	rep	movsb
	mov	di,offset dRNBlock	; current block number
	lodsw
	stosw
	push	ax			; push low word of current block
	lodsb
	mov	ah,0
	stosw
	mov	dx,ax			; dx is high word of current block
	mov	di,offset dRNBytesLeft	; remaining directory length
	movsw
	movsb
	mov	al,0
	stosb
	lodsw				; current offset within block
	mov	bx,ax
	lodsb				; attribute flags for search
	push	es
	pop	ds
	mov	[bThisAtt],al
	pop	ax			; dx:ax is now current block
	call	ReadBlock
	call	sdinext
	jc	f4fbad
	jmp	f4ewrap
f4fbad:
	mov	al,18			; no more files
	jmp	i21stcx

;---------------------- Get/Set File Date/Time ----------------------;

Fun57	label	near
	call	prochand
	cmp	byte ptr [wUserAX],00h
	ja	f57set			; AL=0 to get, 1 to set
	mov	ax,[bx+wHTTime]
	mov	[wUserCX],ax
	mov	ax,[bx+wHTDate]
	mov	[wUserDX],ax
	jmp	i21clcx
f57set:
	mov	ax,[wUserCX]
	mov	[bx+wHTTime],ax
	mov	ax,[wUserDX]
	mov	[bx+wHTDate],ax
	jmp	i21clcx

	page

;----------------- Get Number of CD-ROM Drive Letters -----------------;

F2f00	label	near
	mov	ch,0			; return cx = first drive
	mov	cl,[bDriveFirst]
	mov	bh,0			; and bx = number of drives
	mov	bl,[bDriveLast]
	sub	bl,cl
	inc	bx
	mov	[wUserBX],bx
	mov	[wUserCX],cx
	jmp	i2fclcx

;--------------------- Get CD-ROM Drive Device List --------------------;

F2f01	label	near
	mov	es,[wUserES]
	mov	di,[wUserBX]
	xor	ax,ax
	mov	ch,0
	mov	cl,[bDriveLast]
	sub	cl,[bDriveFirst]
	inc	cx
	cld
F2f01Loop:
	stosb
	mov	si,offset dDevAddr
	movsw
	movsw
	inc	ax
	loop	F2f01Loop
	jmp	i2fclcx

;--------------------- Get Copyright File Name ----------------------;

F2f02	label	near
	mov	si,726
	mov	ax,726-702
F2f02Cont:
	push	si
	push	ax
	mov	ax,[wUserCX]
	call	procdrv
	jc	F2f02Error
	call	checkvol
	mov	ax,0010h
	xor	dx,dx
	call	readasec
	pop	ax
	pop	si
	and	ax,[wThisFormat]
	sub	si,ax
	mov	di,[wUserBX]
	push	ds			; save ds
	push	es
	mov	es,[wUserES]		; es:di -> user transfer area
	pop	ds			; ds -> vtoc sector
	mov	cx,32/2
	cld
	rep	movsw
	pop	ds			; restore ds
I2fDeque:
	call	Deque
	jmp	i2fclcx
F2f02Error:
	mov	al,15			; invalid-drive error
	jmp	i2fstcx

;--------------------- Get Abstract File Name -----------------------;

F2f03	label	near
	mov	si,758
	mov	ax,758-739
	jmp	F2f02Cont

;------------ Get Bibliographic Documentation File Name -------------;

F2f04	label	near
	mov	si,2000			; no such thing for HSG
	mov	ax,2000-776
	jmp	F2f02Cont

;---------------------------- Read VTOC -----------------------------;

F2f05	label	near
	mov	ax,[wUserCX]		; init for specified drive
	call	procdrv
	jc	F2f02Error		; error if not a cd-rom drive
	call	checkvol		; check if new or unmounted volume
	mov	ax,0010h		; first vol descriptor is 00010h
	xor	dx,dx
	add	ax,[wUserDX]		; adjust by caller's sector index
	call	readasec

	mov	si,8			; compute offset to vol descrip type
	mov	ax,8-0
	and	ax,[wThisFormat]
	sub	si,ax
	mov	al,es:[si]		; compute ax value to return to caller
	cmp	al,1			; 1 = standard/primary
	je	F2f05SetAX
	cmp	al,0ffh			; 255 = terminator
	je	F2f05SetAX
	mov	al,0			; 0 = anything else
F2f05SetAX:
	mov	[wUserAX],ax

	xor	si,si
	mov	di,[wUserBX]
	push	ds			; save ds
	push	es
	mov	es,[wUserES]		; es:di -> user transfer area
	pop	ds			; ds -> vtoc sector
	mov	cx,2048/2		; move 2048 bytes
	cld
	rep	movsw
	pop	ds			; restore ds
	jmp	I2fDeque

;----------------------- Absolute Disk Read -------------------------;

F2f08	label	near
	mov	ax,[wUserCX]		; init for specified drive
	call	procdrv
	jc	F2f02Error		; error if not a cd-rom drive
	call	checkvol		; check if new or unmounted volume
	mov	ax,[wUserDX]		; dx is number of sectors
	mov	[wRLNoSec],ax
	mov	ax,[wUserDI]		; si:di is starting sector
	mov	word ptr [dRLStartSec],ax
	mov	ax,[wUserSI]
	mov	word ptr [dRLStartSec+2],ax
	mov	ax,[wUserBX]		; caller's es:bx is xfer address
	mov	word ptr [dpRLXfer],ax
	mov	ax,[wUserES]
	mov	word ptr [dpRLXfer+2],ax
	mov	bx,offset lReadLong	; call the device driver
	call	calldev
	test	[wRLStat],8000h		; check if it worked
	jnz	F2f08NotReady
	jmp	I2fDeque
F2f08NotReady:
	mov	al,21			; not-ready error
I2fErrDeque:
	call	Deque
	jmp	i2fstcx

;----------------------- CD-ROM Drive Check -------------------------;

F2f0b	label	near
	mov	[wUserBX],0adadh	; indicate extensions are installed
	mov	ax,[wUserCX]		; init for specified drive
	call	procdrv
	mov	ax,0			; 0 means not a cd-rom drive
	jc	F2f0bSkip
	dec	ax			; nonzero means it is
	mov	[wUserAX],ax
	jmp	I2fDeque
F2f0bSkip:
	mov	[wUserAX],ax		; if not cd-rom then we're not enqued
	jmp	I2fclcx

;--------------------- Extensions Version Check ---------------------;

F2f0c	label	near
	mov	[wUserBX],020ah		; indicate version 2.10
	jmp	i2fclcx

;--------------------- Get CD-ROM Drive Letters ---------------------;

F2f0d	label	near
	mov	es,[wUserES]
	mov	di,[wUserBX]
	mov	al,[bDriveFirst]
	cld
F2f0dLoop:
	stosb
	inc	al
	cmp	al,[bDriveLast]
	jna	F2f0dLoop
	jmp	i2fclcx

;--------------- Get/Set Volume Descriptor Preference ---------------;

F2f0e	label	near
	jmp	i2fclcx			; kanji not supported

;----------------------- Get Directory Entry ------------------------;

F2f0f	label	near
	mov	al,18			; not supported - let 'em 
	jmp	i2fstcx			;  think there are no more files

;--------------------- Send Device Driver Request -------------------;

F2f10	label	near
	mov	ax,[wUserCX]		; init for specified drive
	call	procdrv
	jc	F2f10Error		; error if not a cd-rom drive
	mov	bx,[wUserBX]
	mov	es,[wUserES]
	mov	al,[bThisDrive]		; set subunit
	sub	al,[bDriveFirst]
	mov	es:[bx+1],al
	mov	word ptr es:[bx+3],0	; clear return status
	call	dword ptr [dDevStrat]
	call	dword ptr [dDevInter]
	jmp	I2fDeque
F2f10Error:
	jmp	F2f02Error

;---------------------- Get CD-Link Statistics ----------------------;

F2f11	label	near
	mov	es,[wUserES]
	mov	di,[wUserBX]
	mov	si,offset dNoLongReads
	mov	cx,(20+64)/2
	cld
	rep	movsw
	jmp	i2fclcx

	page

;------------------------ Interrupt 25 Handler ----------------------;

EntInt25 label	near
	sti
	call	saveregs
	mov	bp,sp
	push	cs
	pop	ds

	call	procdrv			; check if the drive is ours
	jc	i25notus		; no, exit

	call	Deque

	call	restregs
	mov 	ax,0201h		; int25 not allowed on a cd-rom
	stc

farret	proc	far
	ret
farret	endp

i25notus:
	call	restregs
	cli
	jmp	dword ptr cs:[dpOldInt25]

	page

;	Subroutine: Entry logic for FCB function calls.

funfcbno proc	near
	call	procfcb
	push	ax			; save attribute in ah
	jnc	ffgotdr
	call	GetCurDrive		; current drive in al
ffgotdr:
	call	CheckDrive
	pop	ax
	mov	[bThisAtt],ah
	mov	[wThisFCBOffset],dx
	ret
funfcbop:				; enter here if opened FCB!
	call	procfcb
	jnc	ffgotal
	mov	al,0
ffgotal:
	push	ax
	jmp	ffgotdr
funfcbno endp

procfcb	proc	near
	mov	bx,[wUserDX]
	mov	es,[wUserDS]
	xor	ax,ax			; return al=drive,ah=attribute
	xor	dx,dx			; return dx=offset
	cmp	byte ptr es:[bx],0ffh
	jne	pfcskip1
	mov	ah,byte ptr es:[bx+6]	; save the attribute
	mov	dl,7
pfcskip1:
	add	bx,dx
	mov	al,es:[bx]
	sub	al,1
	ret
procfcb	endp

;	Subroutine: Store cdrom directory date/time to es:di

stodatim proc	near
	mov	ax,word ptr [sDRDateTime+3]	; translate time of day
	xchg	al,ah
	shl	al,1
	shl	al,1
	mov	cl,3
	shl	ax,cl
	mov	dl,[sDRDateTime+5]
	and	dl,03fh
	shr	dl,1
	or	al,dl
	stosw
	mov	ax,word ptr [sDRDateTime]	; translate date
	xchg	al,ah
	sub	ah,80
	mov	cl,4
	shl	al,cl
	shl	ax,1
	or	al,[sDRDateTime+2]
	stosw
	ret
stodatim endp

;	Subroutine: Convert CDROM directory flags to DOS attributes.

cnvattr	proc	near
	mov	si,1
	and	si,[wThisFormat]	; si=1 if ISO, else 0
	mov	al,[bDRFlags+si]
	mov	ah,al
	and	ax,0201h
	shl	ax,1
	shl	ah,1
	shl	ah,1
	or	al,ah
        or	al,01h			;0192 mark all files read-only
	cmp	[sDRName],0feh		;0192
	jne	cnvaskip		;0192
	or	al,10h			;0192 ensure '.' and '..' are dir
cnvaskip:
	cbw
	ret
cnvattr	endp

;	Subroutine: Store formatted filename/extension from ds:si to es:di.
;	DS need not point to this program's segment!

stofname proc	near
	mov	ah,-1			; indicate wildcards allowed
	jmp	short sfnmain
stofcdname:
	mov	ah,0			; indicate no wildcards
sfnmain:
	mov	dx,di
	mov	cx,11
	or	ah,ah			;0992
	jz	sfnskip1		;0992 if name may contain wildcards,
	cmp	ds:[si],ch		;   check for null name
	je	sfnnull			;   yes, go zap to ?'s
sfnskip1:				;0992
	mov	al,20h			; blank out name field
	rep	stosb
	mov	di,dx
	mov	cl,8
sfnloop:
	lodsb
	cmp	al,01h
	jbe	sfnexit
	cmp	al,';'
	je	sfnexit
	call	ifslash			;0992
	je	sfnexit
	cmp	al,'.'
	je	sfnext
	jcxz	sfnloop
	or	ah,ah			;0992
	jz	sfnskip2		;0992 
	cmp	al,'*'
	je	sfnstar
sfnskip2:				;0992
	call	UpperCase
	stosb
	dec	cx
	jmp	sfnloop
sfnstar:
	mov	al,'?'
	rep	stosb
	jmp	sfnloop
sfnext:
	mov	di,dx
	add	di,8
	mov	cl,3
	jmp	sfnloop
sfnnull:
	mov	al,'?'			; null name translates to all ?'s
	rep	stosb
sfnexit:
	mov	di,dx
	cmp	byte ptr es:[di],0feh
	jne	sfnex2
	mov	byte ptr es:[di],'.'
	cmp	byte ptr es:[di+1],0feh
	jne	sfnex2
	mov	byte ptr es:[di+1],'.'
sfnex2:
	add	di,11
	ret
stofname endp

;	Subroutine: Determine end of ASCIIZ string passed by caller.
;	This is a prerequisite to calling procpath.  SI is input as 
;	the offset portion of the path pointer.  ES:DI are returned.

getusend proc	near
	mov	es,[wUserDS]		; address caller's area
	mov	di,si
	mov	cx,65
	mov	al,0
	cld
	repne	scasb
	dec	di
	ret
getusend endp

;	The following, if called, should be called right after getusend.
;	It is used if the path is expected to end with a filename, and scans
;	backwards to determine the filename start position.  DI is returned.

getupend proc	near
	cmp	di,si
	jbe	getupex
	dec	di
	mov	al,es:[di]
	call	ifslash			;0992
	je	getupex
	cmp	al,':'
	jne	getupend
getupex:
	ret
getupend endp

;	Subroutine: Process the path pointed to by the caller's ds:dx.
;	This consists of checking to see if the relevant drive belongs
;	to us, and if it does then building the complete new path in
;	"sWorkDir", setting "bThisDrive" to the drive number, and checking
;	to see if the path is valid for the current cd-rom.

procpath proc	near
	call	CheckPath		; go away if not cd-rom path

;	The drive for this function call is ours! 
;	Build a tentative new current directory in "sWorkDir".

	mov	[wpPathEnd],di		; save end-of-path pointer
	push	es
	call	AddrTask
	mov	di,offset sWorkDir-1	; copy sCurDir to sWorkDir
	lea	bx,[bx+sCurDir-1]
prploop1:
	inc	di
	inc	bx
	mov	al,es:[bx]
	mov	ds:[di],al
	or	al,al
	jnz	prploop1
	pop	es

	mov	al,es:[si]		;0992
	call	ifslash			;0992 starting at the root?
	je	prproot			; yes, jump
	cmp	si,[wpPathEnd]		; skip if no user path
	jae	prpskip2
	mov	al,'\'			; insert a backslash
	cmp	di,offset sWorkDir	;  IF sCurDir is not empty...
	ja	prpent2
	jmp	short prploop2		; otherwise resume copy right here
prproot:
	inc	si			; reset regs for copy
	mov	di,offset sWorkDir
prploop2:
	mov	al,es:[si]
	inc	si
prpent2:
	call	prpckdd			; check for "\.." or "\."
	cmp	di,offset sWorkDir+64	; put new path in sWorkDir
	jae	prpskip2
	mov	ds:[di],al
	inc	di
	cmp	si,[wpPathEnd]		; check if end of caller's path
	jbe	prploop2
	mov	byte ptr ds:[di-1],0	; ensure terminating null
prpskip2:

;	Workdir is built. Now we need to see if all the names exist 
;	in the path table in the specified heirarchical order.

	call	checkvol		; need volume info now
	call	AddrDrive		; ensure valid return if root
	mov	si,2
	and	si,[wThisFormat]	; si=2 if ISO, 0 if HSG
	mov	ax,word ptr es:[bx+dVolRootExtent]
	mov	word ptr [dPTExtent+si],ax
	mov	ax,word ptr es:[bx+dVolRootExtent+2]
	mov	word ptr [dPTExtent+2+si],ax
	call	spasetup		; prepare to scan path table
	mov	si,offset sWorkDir	; ds:si points to next sWorkDir name
	mov	[wPathNum1],1		; init sWorkDir pt item number
	mov	al,ds:[si]
prploop3:				; next sWorkDir name starts here
	or	al,al			; end of sWorkDir?
	jz	prpgood			; yes, jump
	call	spanext			; scan  for a match
	jc	prpbad			; jump if none
	mov	ax,[wPathNum2]		; update parent sequence id
	mov	[wPathNum1],ax
	cld
	lodsb				; save the separator for test of al
	jmp	prploop3		; and go do next name
prpbad:
	stc
	jmp	short prpexit
prpgood:
	clc
prpexit:
	ret
procpath endp

CheckPath proc	near			; es:si are input to this proc
	call	GetCurDrive		; current drive in al
	cmp	byte ptr es:[si+1],':'	; drive letter specified?
	jne	ckptest			; no, jump
	mov	al,es:[si]
	and	al,1fh			; convert to 0-relative drive nbr
	dec	al
	add	si,2			; point past colon
ckptest:
	call	CheckDrive
	ret
CheckPath endp

;	Subroutine: Check and adjust for "\.." or '\\' in the new path.
;	Also converts AL to upper case.

prpckdd	proc	near
	call	ifslash			;0992 check for start of new name
	jne	prpddex			;0992
	cmp	byte ptr es:[si],al	; check for double slash
	jne	prpddnods
	inc	si
	jmp	prpckdd
prpddnods:
	cmp	word ptr es:[si],'..'	; check for double dots
	jne	prpddndd		; if not, check for single dot
	mov	al,es:[si+2]
	add	si,3
prpddlp:
	cmp	di,offset sWorkDir	; back up over last directory name
	je	prpddbeg
	dec	di
	push	ax
	mov	al,ds:[di]
	call	ifslash
	pop	ax
	jne	prpddlp
	jmp	prpckdd
prpddndd:
	cmp	byte ptr es:[si],'.'	; handle stuff like "cd ."
	jne	prpddex
	mov	al,es:[si+1]
	add	si,2
	jmp	prpckdd
prpddbeg:
	call	ifslash			;0992
	jne	prpddex
	mov	al,es:[si]
	inc	si
prpddex:
	call	UpperCase
	ret
prpckdd	endp

UpperCase proc	near
	cmp	al,'a'			; make sure al is upper case
	jb	ucplug
	cmp	al,'z'
	ja	ucplug
	sub	al,'a'-'A'
ucplug:
	ret
UpperCase endp

;	Subroutine: Compare filenames; ?'s allowed in ds:si name

compname proc	near
	cld
	mov	cx,11
cnaloop:
	lodsb
	cmp	al,'?'
	je	cnaqmark
	cmp	es:[di],al
	jne	cnaexit
cnaqmark:
	inc	di
	loop	cnaloop
	cmp	al,al
cnaexit:
	ret
compname endp

;	Subroutine: Initialize for calls to spanext.

spasetup proc	near
	call	AddrDrive		; address current drive table entry
	mov	ax,word ptr es:[bx+dVolPathExtent]
	mov	dx,word ptr es:[bx+dVolPathExtent+2]
	mov	cx,word ptr es:[bx+dVolPathSize]
	mov	bx,word ptr es:[bx+dVolPathSize+2]
	call	readinit
	mov	bx,[wThisBlkSize]	; es:bx points to next PT entry
	mov	[wPathNum2],0		; init current pt item number
	ret
spasetup endp

;	Subroutine: Search the path table for the entry that matches
;	the name addressed by ds:si and the parent matching wPathNum1.

spanext	proc	near
	push	bx
spaloop:
	pop	bx
	call	spanpte			; get next path table entry
	push	bx
	push	si
	mov	si,-5
	and	si,[wThisFormat]	; si=-5 if ISO, 0 if HSG
	cmp	[bPTNameLen+si],0	; end of path table?
	pop	si
	je	spabad			; yes, error exit
	inc	[wPathNum2]		; increment current pt item number
	mov	ax,[wPTParent]		; get pt number of this guy's parent
	cmp	ax,[wPathNum1]
	ja	spabad
	jne	spaloop

	push	es			; es,di,si must be preserved
	push	di
	push	si			; si will be updated if we match
	push	ds
	pop	es			; es -> our segment
	mov	di,offset sWSName1
	call	stofcdname		; format name from caller
	lea	bx,[si-1]		; bx saves updated si if match
	mov	si,offset sPTName
	mov	di,offset sWSName2
	call	stofcdname		; format name from path table
	mov	si,offset sWSName1
	mov	di,offset sWSName2
	mov	cx,11
	repe	cmpsb
	pop	si
	pop	di
	pop	es			; es -> i/o buffer

	ja	spaloop			; note: match updates si
	jb	spabad
	mov	si,bx			; match returns updated si
	clc
	jmp	short spaexit
spabad:
	stc
spaexit:
	pop	bx
	ret
spanext	endp

;	Subroutine: Retrieve next path table entry to "lPathTableEntry",
;	reading sectors as required.

spanpte	proc	near
	push	si
	push	ds
	push	es
	pop	ds
	pop	es
	mov	si,bx
	cld
	mov	ax,es:[wThisBlkSize]
	mov	di,offset lPathTableEntry
	mov	cx,4
	call	spnmove
	jc	spnend
	push	si
	mov	si,-5
	and	si,es:[wThisFormat]	; si=-5 if ISO, 0 if HSG
	mov	cl,es:[bPTNameLen+si]
	pop	si
	inc	cx
	shr	cx,1
	cmp	cx,16
	ja	spnfixl
	jcxz	spnend
spnokl:
	call	spnmove
	jc	spnend
	jmp	short spndone
spnfixl:
	mov	cl,16
	jmp	spnokl
spnend:
	mov	bx,-5
	and	bx,es:[wThisFormat]	; si=-5 if ISO, 0 if HSG
	mov	es:[bPTNameLen+bx],0	; signify end of path table
spndone:
	push	ds
	push	es
	pop	ds
	pop	es
	mov	bx,si
	mov	byte ptr ds:[di],0
	pop	si
	ret
spanpte endp

;	Subroutine: Get next CX words of path table, reading
;	sectors as required.
;
;	input:     es,ds,si,di,ax,cx,flags
;	output:    si,di,flags
;	destroyed: cx

spnmove proc	near
	cmp	si,ax			; end of block?
	jae	spnmnews		; yes, jump
	movsw				; move and repeat until done
	loop	spnmove
	clc
spnmret:
	ret
spnmnews:
	push	es			; read next path table sector
	pop	ds
	push	ax
	call	readnext
	pop	ax
	push	ds
	push	es
	pop	ds
	pop	es
	jc	spnmret			; exit with carry if end of table
	xor	si,si
	cld
	jmp	spnmove
spnmove endp

;	Subroutine: Set up to scan a directory.

sdisetup proc	near
	xor	cx,cx			; start with a large dummy length
	mov	bx,1000h
	call	readinit
	call	readnext		; get the first directory sector
	xor	bx,bx			; es:bx points to next record
	mov	ax,es:[bx+10]		; now plug the real remaining length
	mov	dx,es:[bx+12]
	sub	ax,[wThisBlkSize]
	sbb	dx,0
	mov	word ptr [dRNBytesLeft],ax
	mov	word ptr [dRNBytesLeft+2],dx
	ret
sdisetup endp

;	Subroutine: Search a directory for the entry that matches
;	the name in sWSName1.  "Directory" attribute may also affect
;	the outcome.

sdinext	proc	near
sdiloop:
	call	sdindr			; get next directory record
	jc	sdibad
	cmp	[bDRLength],0		; end of this directory?
	je	sdibad			; yes, error exit
	mov	si,1
	and	si,[wThisFormat]	; si=0 if HSG, 1 if ISO
	mov	al,[bDRFlags+si]
	mov	ah,[bThisAtt]
	test	al,02h			; is this for a directory?
	jz	sdiskip1		; no, jump
	test	ah,10h			; does caller want directories?
	jz	sdiloop			; no, jump

;	Here we must solve a yucky problem.  A "." or ".." directory
;	entry must be ignored, but only if it occurs in the root
;	directory.  Testing to see if we're in the root takes some
;	code, because all we have to work with is the directory extent 
;	that is being searched.  Fortunately it is sufficient to test
;	if we are in the first sector of the root directory.

	cmp	byte ptr [sDRName],0feh	; "." or ".." entry?
	jne	sdiskip1		; no, skip
	push	es
	push	bx
	push	ax
	call	AddrDrive
	mov	ax,word ptr es:[bx+dVolRootExtent]
	cmp	ax,word ptr [dRNBlock]
	jne	sdiskip0
	mov	ax,word ptr es:[bx+dVolRootExtent+2]
	cmp	ax,word ptr [dRNBlock+2]
sdiskip0:
	pop	ax
	pop	bx
	pop	es
	je	sdiloop

;	End of yucky code to test if we're in the root directory.

sdiskip1:
	test	al,01h			; is this a hidden file?
	jz	sdiskip2		; no, jump
	test	ah,02h			; does caller want hidden files?
	jz	sdiloop			; no, jump
sdiskip2:
	push	es			; es must be preserved
	push	ds
	pop	es			; es -> our segment
	mov	si,offset sDRName
	mov	di,offset sWSName2
	call	stofcdname		; format name from cdrom directory
	mov	si,offset sWSName1
	mov	di,offset sWSName2
	call	compname
	pop	es			; es -> i/o buffer

	jne	sdiloop			; can't stop early on a high compare,
	clc				;  because of possible wildcards
	jmp	short sdiexit
sdibad:
	stc
sdiexit:
	ret
sdinext	endp

;	Subroutine: Retrieve next directory record to "lDirRecord", reading
;	blocks as required.

sdindr	proc	near
	mov	[bDRLength],0
	push	si
sdinback:
	push	ds
	push	es
	pop	ds
	pop	es
	cld
	mov	si,bx
	cmp	si,es:[wThisBlkSize]	; check for end of this block
	jae	sdinread
	cmp	byte ptr ds:[si],0	; check for unused area
	je	sdinread
	mov	di,offset lDirRecord
	mov	cx,33
	rep	movsb
	mov	cl,ds:[si-1]
	jcxz	sdinread
	cmp	byte ptr ds:[si],01h
	ja	sdinmove
	mov	al,0feh			; special "dot" avoids '.' confusion
	stosb
	jb	sdinw0
	stosb
	jmp	short sdinw0
sdinmove:
	cmp	cx,31			; don't allow long name to trash us
	jna	sdincxok
	mov	cl,31
sdincxok:
	rep	movsb
sdinw0:
	mov	al,0
	stosb
	mov	si,bx			; update pointer
	mov	bl,ds:[si]
	mov	bh,0
	add	si,bx
	push	ds
	push	es
	pop	ds
	pop	es
	clc
sdinout:
	mov	bx,si
	pop	si
	ret
sdinread:
	push	es			; read next path table sector
	pop	ds
	call	readnext
	jc	sdinout			; exit with carry if end of table
	xor	bx,bx
	jmp	sdinback
sdindr	endp

;	Subroutine: Read first or next block of an extent.

readinit proc	near
	sub	ax,1			; store starting block - 1
	sbb	dx,0
	mov	word ptr [dRNBlock],ax
	mov	word ptr [dRNBlock+2],dx
	mov	word ptr [dRNBytesLeft],cx
	mov	word ptr [dRNBytesLeft+2],bx
	ret
readinit endp

readnext proc	near
	cmp	word ptr [dRNBytesLeft+2],0
	jl	readnend
	jg	readngo
	cmp	word ptr [dRNBytesLeft],0
	jz	readnend
readngo:
	add	word ptr [dRNBlock],1
	adc	word ptr [dRNBlock+2],0
	mov	ax,word ptr [dRNBlock]
	mov	dx,word ptr [dRNBlock+2]
	call	ReadBlock
	mov	ax,[wThisBlkSize]
	sub	word ptr [dRNBytesLeft],ax
	sbb	word ptr [dRNBytesLeft+2],0
	clc
	ret
readnend:
	stc				; failed - no more to read
	ret
readnext endp

CheckDrive proc	near
	call	procdrv
	jc	cdrpass

	if	DEBUG
	call	tracer
	endif

	ret
cdrpass:
	jmp	Int21Pass
CheckDrive endp

procdrv proc	near
	cmp	al,[bDriveFirst]	; see if it's a cd-rom drive
	jb	pdrerror
	cmp	al,[bDriveLast]
	ja	pdrerror
	cmp	word ptr [dDevAddr+2],0	; make sure there's a h/w driver
	je	pdrerror

	call	Enque			; serialize access to cd-rom logic

	mov	[bThisDrive],al
	push	es
	push	bx
	push	ax
	call	AddrDrive
	mov	ax,es:[bx+wVolBlkSize]
	or	ax,ax
	jz	pdrret
	mov	[wThisBlkSize],ax
	mov	ax,es:[bx+wVolFormat]
	mov	[wThisFormat],ax
pdrret:
	pop	ax
	pop	bx
	pop	es
	clc
	ret
pdrerror:
	stc
	ret
procdrv endp

AddrTask proc	near
	push	dx
	call	GetTaskID
	inc	ax			; use 1-relative task IDs
	mov	dx,ax
	call	AddrDrive
	add	bx,offset lVolTaskTable-TTESIZE
ATLoop:
	add	bx,TTESIZE
	mov	ax,es:[bx+wTaskID]
	cmp	ax,dx
	je	ATGotit
	or	ax,ax
	jnz	ATLoop
	mov	es:[bx+wTaskID],dx
ATGotit:
	pop	dx
	ret
AddrTask endp

AddrDrive proc	near
	push	dx
	mov	al,[bThisDrive]
	sub	al,[bDriveFirst]
	cbw
	mul	[wDTESize]
	mov	bx,ax
	mov	es,[wpDriveTable]
	pop	dx
	ret
AddrDrive endp

;	Subroutine: Init driver access if required.
;	BX,CX,DX are destroyed.

getdevad proc	near
	cmp	word ptr [dDevAddr+2],0	; fast exit if already got it
	je	getdev0
	clc
	ret
getdev0:
	push	ax
	mov	ax,3d00h		; open device-specific driver
	mov	dx,offset sDevName
	call	int21
	jc	getdevex
	mov	bx,ax
	mov	ax,4402h		; do ioctl input to get dev header
	mov	cx,5
	mov	dx,offset lDevHdrCB
	call	int21
	jc	getdevex
	mov	ah,3eh			; close the handle
	call	int21
	push	es
	les	si,[dDevAddr]		; get strategy/interrupt entries
	mov	ax,es:[si+6]
	mov	word ptr [dDevStrat],ax
	mov 	word ptr [dDevStrat+2],es
	mov	ax,es:[si+8]
	mov	word ptr [dDevInter],ax
	mov 	word ptr [dDevInter+2],es
	pop	es
	clc
getdevex:
	pop	ax
	ret
getdevad endp

;	Subroutine: Get volume information if required.

checkvol proc	near

;	Note that we do the "media check" call even if we otherwise
;       know that we must read the VTOC. This is to make sure that the 
;       "media changed" status gets cleared so we don't unnecessarily
;	read the VTOC a second time.

	call	MedCheck		;0992
	call	AddrDrive		; point es:bx to drive table entry
	mov	ax,word ptr es:[bx+dVolPathExtent] ; got path table location?
	or	ax,word ptr es:[bx+dVolPathExtent+2]
	jz	cvread			; no, go read vtoc
	cmp	[lCBMedia+1],0		; media changed?
;0992	jl	$+5
	jle	$+5			;0992 -1=yes, 0=dunno, 1=no
	jmp	cvmedok			; no, skip
	call	flush			; flush buffered drive info
cvread:
	mov	ax,0010h		; read VTOC sector
	xor	dx,dx
	call	readasec

	push	ds

	push	es
	call	AddrDrive
	pop	ds
	cld

	mov	dx,0ffffh		; determine if ISO or HSG
	cmp	word ptr ds:[1],'DC'	; 'CD001' in positions 2-6?
	je	CVSetFormat		; -1 means ISO 9660 format
	xor	dx,dx			; 0 means HSG format
CVSetFormat:
	mov	es:[bx+wVolFormat],dx

	push	dx
	call	HashVTOC		; VTOC checksum
	lea	di,[bx+dVolHash]
	stosw
	mov	ax,dx
	stosw
	pop	dx

	mov	si,136			; logical block size
	mov	ax,136-128
	and	ax,dx
	sub	si,ax
	lea	di,[bx+wVolBlkSize]
	movsw

	mov	si,148			; path table location
	sub	si,ax
	lea	di,[bx+dVolPathExtent]
	movsw
	movsw

	mov	si,140			; path table size
	sub	si,ax
	movsw
	movsw

	mov	si,182			; root directory location
	mov	ax,182-158
	and	ax,dx
	sub	si,ax
	lea	di,[bx+dVolRootExtent]
	movsw
	movsw

	mov	si,190			; root directory length
	sub	si,ax
	movsw
	movsw

	mov	si,48			; volume identifier
	mov	ax,48-40
	and	ax,dx
	sub	si,ax
	lea	di,[bx+sVolLabel]
	mov	cx,11
	rep	movsb

	mov	cx,ds
	pop	ds
	call	AddrTask
	mov	es:[bx+sCurDir],0	; reset current directory to root
	push	ds
	mov	ds,cx

	mov	si,182			; root directory location
	mov	ax,182-158
	and	ax,dx
	sub	si,ax
	lea	di,[bx+dCurDirExtent]
	movsw
	movsw

	pop	ds
	mov	[wThisFormat],dx
cvmedok:
	ret

checkvol endp

MedCheck proc	near
	mov	word ptr [dpIIXfer],offset lCBMedia ; "media check" call
	mov	word ptr [dpIIXfer+2],ds
	mov	[bIIUnit],0
	mov	[wIIBytes],2
	mov	bx,offset lIOCtlInput
	call	calldev			; do the call
	ret
MedCheck endp

;-------------- Compute 32-bit Checksum of VTOC Sector --------------;

HashVTOC proc	near
	mov	cx,221			; get it from first 884 bytes
	xor	ax,ax
	xor	dx,dx
	xor	si,si
HVLoop:
	rcl	ax,1			; this is a 33-bit rotate
	rcl	dx,1
	pushf
	xor	ax,ds:[si]
	xor	dx,ds:[si+2]
	add	si,4
	popf
	loop	HVLoop
	ret
HashVTOC endp

;---------------------- Read a Logical Block ------------------------;

ReadBlock proc	near
	push	si
	push	cx
	mov	cx,[wThisBlkSize]	; dx:ax will be sector number
	xor	si,si			; si will be offset within sector
	jcxz	rbout1
rbloop1:
	cmp	cx,[wSectorSize]	; Note that blksize is required to
	je	rbout1			;  be some power of 2 less than or
	shr	dx,1			;  equal to sectorsize.
	rcr	ax,1
	jnc	rbskip1
	add	si,cx
rbskip1:
	add	cx,cx
	jmp	rbloop1
rbout1:
	call	readasec		; read the sector
	mov	cl,4			; now recompute es to point to block
	shr	si,cl
	mov	ax,es
	add	ax,si
	mov	es,ax
	pop	cx
	pop	si
	ret
ReadBlock endp

;------------------- Physical Drive I/O Routines --------------------;

readasec proc	near
	if	CACHELOGIC
	mov	[fNewCacheEntry],'N'	; default = not writing to cache
	endif

	push	di
	push	si
	push	cx
	push	bx

	call	DemoCheck		; check for demo expiration
	jc	$-3

	cmp	word ptr [dBuffSector],ax
	jne	rasgo
	cmp	word ptr [dBuffSector+2],dx
	jne	rasgo
	jmp	rasexit
rasgo:
	add	[dNoShortReads],1
	adc	[dNoShortReads+2],0
	mov	word ptr [dRLStartSec],ax ; starting sector
	mov	word ptr [dRLStartSec+2],dx

	if	CACHELOGIC

; - - - - - - - - - -  Cache logic starts here - - - - - - - - - - - ;

	call	GetHandle		; get cachefile handle
	jc	jrascaerr		; skip cacheing if it fails
	or	dx,dx			; don't use cache if VTOC sector
	jnz	rascache
	cmp	ax,16
	jne	rascache
	jmp	rascdrom
jrascaerr:
	jmp	rascaerror
rascache:
	xor	dx,dx
	div	[wCacheBuckets]		; hash sector nbr to bucket nbr
	mov	ax,[wBucketBytes]	; compute offset into file
	mul	dx
	add	ax,CACHEHDRLEN
	adc	dx,0

	mov	cx,dx			; lseek to index for this bucket
	mov	dx,ax
	mov	ax,4200h
	call	rcacheio

	mov	ah,3fh			; read the index
	xor	dx,dx
	mov	cx,[wCacheIXBytes]
	mov	es,[wIndexBuffAddr]
	call	rcacheio

	push	bx			; save file handle

	call	getsectorid		; loads ax,dx,cx,bx
	xor	di,di
rasciloop:
	cmp	ax,word ptr es:[di+dCISector] ; scan index for a match
	jne	rascinext
	cmp	dl,byte ptr es:[di+dCISector+2]
	jne	rascinext
	cmp	cx,word ptr es:[di+dCIVolHash]
	jne	rascinext
	cmp	bx,word ptr es:[di+dCIVolHash+2]
	je	rascigotit
rascinext:
	add	di,CILEN		; try next entry
	cmp	di,[wCacheIXBytes]
	jb	rasciloop
	mov	[fNewCacheEntry],'Y'	; no match; create new cache entry
	sub	di,CILEN
rascigotit:
	mov	dh,byte ptr es:[di+dCISector+3]
	xor	si,si
rasxchgloop:
	xchg	cx,word ptr es:[si+dCIVolHash]
	xchg	bx,word ptr es:[si+dCIVolHash+2]
	xchg	ax,word ptr es:[si+dCISector]
	xchg	dx,word ptr es:[si+dCISector+2]
	add	si,CILEN
	cmp	si,di
	jbe	rasxchgloop

	pop	bx			; restore file handle

	cmp	[fNewCacheEntry],'Y'	; creating new cache entry?
	je	rascdrom		; yes, skip

	add	[dNoCacheHits],1	; count number of cache hits
	adc	[dNoCacheHits+2],0

	add	di,di			; skip write if entry was in 1st half
	cmp	di,[wCacheIXBytes]
	jbe	rasskiprw
	call	writeindex		; rewrite index we just read

	add	[dNoCacheRewrites],1	; count number of cache rewrites
	adc	[dNoCacheRewrites+2],0
rasskiprw:
	call	poscachedata		; position to the data sector

	mov	ah,3fh			; read 2056 bytes of cache data
	mov	di,[wSectorSize]
	lea	cx,[di+8]
	xor	dx,dx
	mov	es,[wDataBuffAddr]
	call	rcacheio

	call	getsectorid		; make sure data matches the index
	cmp	ax,es:[di+4]
	jne	rascaerror
	cmp	dx,es:[di+6]
	jne	rascaerror
	cmp	cx,es:[di+0]
	jne	rascaerror
	cmp	bx,es:[di+2]
	jne	rascaerror
	call	RestorePSP		; all done, release the file handle
	jmp	short rasexit

rcacheio proc	near			; do cacheio but abort to rascaerror
	call	cacheio			;  if there's a problem
	jc	$+3
	ret
	pop	ax			; error - discard return address
rcacheio endp

rascaerror:
	inc	[wNoCacheErrors]	; count number of cache errors
rascdrom:
	call	RestorePSP

; - - - - - - - - - -  End of Cache Read Logic - - - - - - - - - - - ;

	endif

	mov	word ptr [dBuffSector+2],-1 ; invalidate whatever's buffered
	mov	[wRLNoSec],1		; number of sectors
	mov	word ptr [dpRLXfer],0	; transfer address
	mov	ax,[wDataBuffAddr]
	mov	word ptr [dpRLXfer+2],ax
rasretry:
	mov	bx,offset lReadLong	; call the device driver
	call	calldev
	test	byte ptr [wRLStat+1],80h ; error?
	jz	rasexit			; no, exit
	call	criterr			; yes, execute critical error logic
	call	MedCheck		;0992 reset media-changed condition
	jmp	rasretry
rasexit:
	mov	es,[wDataBuffAddr]

	if	CACHELOGIC

; - - - - - - - - - - -  Cache Write Logic - - - - - - - - - - - - - ;

	cmp	[fNewCacheEntry],'Y'	; creating new cache entry?
	jne	rasdone			; no, skip

	call	getsectorid		; to write sector id info
	mov	di,[wSectorSize]
	mov	es:[di+0],cx
	mov	es:[di+2],bx
	mov	es:[di+4],ax
	mov	es:[di+6],dx

	call	GetHandle		; no way this will fail...
	jc	rascwerror
	call	writeindex		; rewrite index we just read
	jc	rascwerror

	call	poscachedata		; position to data sector
	jc	rascwerror
	lea	cx,[di+8]		; write 2056 bytes
	xor	dx,dx
	mov	ah,40h
	mov	es,[wDataBuffAddr]
	call	cacheio
	jnc	rascwdone
rascwerror:
	inc	[wNoCacheErrors]	; count cache errors
rascwdone:
	call	RestorePSP
rasdone:

; - - - - - - - - - - - End of Cache Write Logic - - - - - - - - - - ;

	endif

	mov	ax,word ptr [dRLStartSec]	; identify what's buffered
	mov	word ptr [dBuffSector],ax
	mov	ax,word ptr [dRLStartSec+2]
	mov	word ptr [dBuffSector+2],ax

	pop	bx
	pop	cx
	pop	si
	pop	di
	ret
readasec endp

	if	CACHELOGIC

writeindex proc	near
	mov	es,[wIndexBuffAddr]
	mov	ax,4201h		; reposition to index we just read
	xor	dx,dx
	sub	dx,[wCacheIXBytes]
	mov	cx,-1
	call	cacheio
	jc	wrinret
	mov	ah,40h			; write updated index
	xor	dx,dx
	mov	cx,[wCacheIXBytes]
	call	cacheio
wrinret:
	ret
writeindex endp

poscachedata proc near			; position to this bucket data sector
	mov	ah,0
	mov	al,es:[bCILocation]
	dec	ax
	mov	dx,[wSectorSize]
	add	dx,8
	mul	dx
	mov	cx,dx
	mov	dx,ax
	mov	ax,4201h
	call	cacheio
	ret
poscachedata endp

cacheio proc	near
	push	ds
	push	es
	pop	ds
	call	int21
	pop	ds
	ret
cacheio endp

getsectorid proc near
	push	es
	call	AddrDrive		; load hashcount and sector number
	mov	cx,word ptr es:[bx+dVolHash]
	mov	bx,word ptr es:[bx+dVolHash+2]
	mov	ax,word ptr [dRLStartSec]	;0992 was from dBuffSector
	mov	dx,word ptr [dRLStartSec+2]	;0992
	pop	es
	ret
getsectorid endp

	endif

ReadSectors proc near
	call	DemoCheck		; check for demo expiration
	jc	$-3
	add	[dNoLongReads],1	; count number of long reads
	adc	[dNoLongReads+2],0
	mov	[wRLNoSec],cx		; number of sectors
	mov	word ptr [dRLStartSec],ax ; starting sector
	mov	word ptr [dRLStartSec+2],dx
	mov	word ptr [dpRLXfer],di	; transfer address
	mov	word ptr [dpRLXfer+2],es
rseretry:
	mov	bx,offset lReadLong	; call the device driver
	call	calldev
	test	byte ptr [wRLStat+1],80h ; error?
	jz	rseexit			; no, exit
	call	criterr			; yes, execute critical error logic
	call	MedCheck		;0992 reset media-changed condition
	jmp	rseretry
rseexit:
	ret
ReadSectors endp

flush	proc	near
	mov	ax,-1
	mov	word ptr [dBuffSector],ax
	mov	word ptr [dBuffSector+2],ax
	ret
flush	endp

ifslash	proc	near			;0992
	cmp	al,'/'			;0992
	je	ifslashx		;0992
	cmp	al,'\'			;0992
ifslashx:				;0992
	ret				;0992
ifslash	endp				;0992

;	Subroutine:  Issue a Critical Error and Process the Result

criterr	proc	near
	mov	ax,21			; indicate drive not ready
	call	SetError		; set ext error code for int24 handler
	mov	bx,offset waSaveArea	; savearea for stuff on the stack
	mov	ds:[bx],sp		; save sp for calculation below
	mov	al,[bThisDrive]		; the failing drive
	mov	ah,00010000b		; disk error, retry allowed, dos area
	test	[bSwitches],01000000b	; handle-style int21 function?
	jz	crepop			; no, skip
	or	ah,00001000b		; yes, also allow "fail" response
crepop:
	add	bx,2			; pop regs until sp=bp
	pop	ds:[bx]
	cmp	sp,bp
	jb	crepop
	mov	bp,ds			; ss:sp are now as at entry to int21
	xor	si,si			; bp:si -> device header
	mov	di,0002h		; drive not ready
	int	24h			; note we are still enqued here
	mov	bp,sp
	mov	bx,sp			; compute address of 1st word to push
	sub	bx,[waSaveArea]		; = current sp - original sp
	add	bx,offset waSaveArea	; + savearea address 
crepush:
	push	ds:[bx]			; pushed saved stuff back onto stack
	sub	bx,2
	cmp	bx,offset waSaveArea
	ja	crepush
	cmp	al,2			; abort or fail?
	jb	creback			; no, skip
	je	critabrt		; jump if abort
	test	[bSwitches],01000000b	; make sure fail is allowed
	jz	critabrt		; no, change to abort
	mov	al,83			; error code = fail on int24
	jmp	i21stcx
critabrt:
	call	Deque

	clc				;0992
	int	23h			; yes, do ctrl-break type abort
	mov	sp,[waSaveArea]		;0992 sp is a little ambiguous here
	jc	creabort		;0992 carry will normally be set
	
	call	Enque
creback:
	ret
creabort:				;0992
	mov	ax,4c00h		;0992 terminate current process
	call	int21			;0992
	jmp	$			;0992
criterr	endp

;---------------------- Call the Device Driver ----------------------;

calldev	proc	near
	push	es

	push	si
	if	NOT DOSCODE
	les	si,[dpMOSSCB]
	mov	ax,ss
	cmp	ax,es:[si+SCBTCBPC]
	jne	cdSkip1
	push	ss:[TCBSTKP]
	mov	ax,sp
	sub	ax,64
	mov	word ptr ss:[TCBSTKP],ax
cdSkip1:
	endif

	mov	al,[bThisDrive]		; set subunit
	sub	al,[bDriveFirst]
	mov	[bx+1],al

	mov	word ptr [bx+3],0	; clear return status
	push	ds			; es:bx points to request hdr
	pop	es
	call	dword ptr [dDevStrat]
	call	dword ptr [dDevInter]

	if	NOT DOSCODE
	les	si,[dpMOSSCB]
	mov	ax,ss
	cmp	ax,es:[si+SCBTCBPC]
	jne	cdSkip2
	pop	ss:[TCBSTKP]
cdSkip2:
	endif
	pop	si

	pop	es
	ret
calldev	endp

;------------------- Check for Demo Expiration ----------------------;

DemoCheck proc	near
	push	es
	push	ax
	mov	es,[wZero]		; check for demo expiration
	mov	ax,es:[046ch]
	sub	ax,[wStartTime]
	cmp	[wDemoDiff],ax		; check if diff is smaller than before
	ja	DemoJump
	mov	[wDemoDiff],ax
	cmp	ax,32760		; 18.2*30*60
DemoJump:				; nop this instruction if not demo
	jae	DemoExpired
	clc
DemoReturn:
	pop	ax
	pop	es
	ret
DemoExpired:
	call	criterr
	stc
	jmp	DemoReturn
DemoCheck endp

;------------------ Calling the Operating System --------------------;

GetCurDrive proc near
	mov	ah,19h
	call	int21
	ret
GetCurDrive endp

int21	proc	near
	pushf
	cli
	call	dword ptr cs:[dpOldInt21]
	ret
int21	endp

	page

;------------------------ Register Save/Restore ---------------------;

saveregs proc	near
	pop	cs:[wTrash]
	push	es		; [bp+18]
	push	ds		; [bp+16]
	push	bp		; [bp+14]
	push	di		; [bp+12]
	push	si		; [bp+10]
	push	dx		; [bp+08]
	push	cx		; [bp+06]
	push	bx		; [bp+04]
	push	ax		; [bp+02]
	push	cs:[wZero]	; [bp+00]
	jmp	word ptr cs:[wTrash]
saveregs endp

restregs proc	near
	pop	[wTrash]
	pop	ax
	pop	ax
	pop	bx
	pop	cx
	pop	dx
	pop	si
	pop	di
	pop	bp
	pop	ds
	pop	es
	jmp	word ptr cs:[wTrash]
restregs endp

;------------------------ Get Current Task ID -----------------------;

GetTaskID	proc	near
	xor	ax,ax
	cmp	word ptr [dpMOSSCB+2],ax
	je	gtaret
	push	es
	push	bx
	les	bx,[dpMOSSCB]
	mov	es,es:[bx+SCBTCBPC]
	mov	ax,es:[TCBID]
	pop	bx
	pop	es
gtaret:
	ret
GetTaskID	endp

	if	CACHELOGIC

;--------------------- Initialize Cache File I/O --------------------;

GetHandle proc	near
	push	es
	push	dx
	push	ax
	mov	ah,51h			; get current psp
	call	int21
	mov	es,bx
	mov	al,es:[53h]		; get sft id
	mov	ah,0
	or	ax,ax
	jz	GHOpenFile		; no sft yet, go open the file
	push	es
	mov	dx,es:[32h]		; size of JFT
	les	bx,es:[34h]		; address of JFT
GHScanHandles:
	inc	bx			; look for free handle
	dec	dx
	jz	GHFull
	cmp	es:[bx],al		; check if our SFT was reappropriated
	je	GHSurprise		; yes, open again!
	cmp	byte ptr es:[bx],-1
	jne	GHScanHandles
	mov	es:[bx],al		; plug in cachefile SFT index
	pop	es
	sub	bx,es:[34h]		; bx is the returned handle
	mov	ax,4201h		; dummy lseek to see if handle valid
	xor	cx,cx
	xor	dx,dx
	call	int21
	jnc	GHGotit
	add	bx,es:[34h]		; oops, handle does not work!
	push	es
	mov	es,es:[36h]
	mov	byte ptr es:[bx],-1
	jmp	short GHSurprise
GHFull:
	pop	es			; error - JFT is full
	stc
	jmp	short GHReturn
GHSurprise:
	pop	es
GHOpenFile:
	mov	ax,3dc2h		; private, deny none, read/write
	mov	dx,offset sCacheFileName ; open cache file for this task
	call	int21
	jc	GHReturn		; if error, return with carry set
	push	es
	les	bx,es:[34h]		; address handle table
	add	bx,ax
	mov	dl,es:[bx]		; sft id
	pop	es
	mov	es:[53h],dl		; save sft id to unused psp area
	mov	bx,ax			; return handle in bx
	inc	[wNoCacheOpens]		; count number of cache file opens
GHGotIt:
	clc
GHReturn:
	pop	ax
	pop	dx
	pop	es
	ret
GetHandle endp

RestorePSP proc	near
	push	es
	mov	ah,51h
	call	int21
	mov	es,bx
	mov	al,es:[53h]
	or	al,al
	jz	RPSPSkip2
	mov	cx,es:[32h]
	les	bx,es:[34h]
RPSPLoop:
	cmp	es:[bx],al
	je	RPSPGotIt
	inc	bx
	loop	RPSPLoop
	jmp	short RPSPSkip2
RPSPGotIt:
	mov	byte ptr es:[bx],-1
RPSPSkip2:
	pop	es
	ret
RestorePSP endp

	endif

;----------------------- Enque/Deque Procedures ---------------------;

Enque	proc	near
	inc	[bEnqCount]
	cmp	[bEnqCount],1
	jne	EnqWait
	ret
EnqWait:
	dec	[bEnqCount]

	if	DOSCODE			; begin DOS/Windows enque wait

	push	dx
	push	cx
	push	ax
	mov	ah,2ch			; get time - innocuous DOS call
	call	int21
	pop	ax
	pop	cx
	pop	dx

	else				; begin PC-MOS enque wait

	push	bx
	push	ax
	mov	ax,0702h		; wait for time interval
	mov	bx,2			; number of timer ticks
	int	0d4h			; MOS extended services interrupt
	pop	ax
	pop	bx

	endif				; end PC_MOS enque wait

	jmp	Enque
Enque	endp

Deque	proc	near
	cmp	[bEnqCount],0		; should never be zero
	je	DeqOops
	dec	[bEnqCount]
DeqOops:
	ret
Deque	endp

	if	EXECCODE

;--------------- Verify Drives Procedure for Executor ---------------;

vrfydrvs proc	far			; proc for executor
	ret
vrfydrvs endp

	endif

	page

;------------------------- Initialization ---------------------------;

initfin	label	near			; this is here so buffer clearing
	rep	stosw			;   does not zap this code!

	mov	es,[wpDriveTable]	; clear drive table area to zeros
	mov	ax,[wDTESize]
	mul	[wMaxDrives]
	shr	ax,1
	mov	cx,ax
	xor	di,di
	xor	ax,ax
	rep	stosw

	pop	es
	jmp	done

mainseg	ends

initseg	segment	para

notice		db	13,10,'CD-Link v1.07 for '
		if	DOSCODE
		db	'DOS '
		else
		db	'PC-MOS(tm) '
		endif
sSerial		db	' 30-MINUTE DEMO',13,10
		db	'Copyright 1991-1993 Rod Roark',13,10
		db	' ',13,10,'$'
sMsgSyntax 	db	'CDL03 Device command line syntax error!',13,10,'$'
sMsgDrives	db	'CDL07 Invalid number of CD-ROM drives!',13,10,'$'
sMsgTasks	db	'CDL08 Invalid maximum tasks!',13,10,'$'
sMsgHandles	db	'CDL09 Invalid maximum handles!',13,10,'$'
sMsgOffset	db	'CDL10 Invalid handle offset!',13,10,'$'
sMsgLong	db	'CDL11 L must be greater than 1!',13,10,'$'
sMsgSerial	db	'CDL12 Invalid serial number!',13,10,'$'

		if	CACHELOGIC

sMsgFound	db	'CDL01 Using existing cache file.',13,10,'$'
sMsgCreating	db	'CDL02 Creating new cache file...',13,10,'$'
sMsgBadName	db	'CDL04 Incomplete cache filename!',13,10,'$'
sMsgCacheInit	db	'CDL05 Error initializing cache file!',13,10,'$'
sMsgTooSmall	db	'CDL06 Cache Size too small!',13,10,'$'

lCacheIndexData	label	byte
		db	7 dup(0),20
		db	7 dup(0),19 
		db	7 dup(0),18 
		db	7 dup(0),17 
		db	7 dup(0),16 
		db	7 dup(0),15 
		db	7 dup(0),14 
		db	7 dup(0),13 
		db	7 dup(0),12 
		db	7 dup(0),11 
		db	7 dup(0),10
		db	7 dup(0),9 
		db	7 dup(0),8 
		db	7 dup(0),7 
		db	7 dup(0),6 
		db	7 dup(0),5 
		db	7 dup(0),4 
		db	7 dup(0),3 
		db	7 dup(0),2 
		db	7 dup(0),1 

		endif

	even
wPrimes	dw	719,739,853,881,967,983	; for serial number check logic

	page
;---------------------- Initialization Entry ------------------------;

init	label	near

	mov	al,es:[bx+22]		; save drive number
	mov	[bDriveFirst],al
	mov	[bDriveLast],al

	push	es
	push	bx

	if	EXECCODE
	mov	word ptr [vrfyproc],offset vrfydrvs
	mov	word ptr [vrfyproc+2],cs
	mov	word ptr [execint21],offset EntInt21	;0992
	mov	word ptr [execint21+2],cs		;0992
	endif

	mov	dx,offset cgroup:notice	; display copyright notice
	call	DisplayMessage

	call	getos			; get scb address if mos

;---------------------- Parse the Command Line ----------------------;

	les	si,es:[bx+18]		; get pointer to parameters
ParseLoop:
	call	FindDelimeter
	cmp	al,20h
	jb	ToParseDone
	call	FindNonBlank
	cmp	al,20h
	jb	ToParseDone
	cmp	byte ptr es:[si+1],'='
	jne	ParseError
	add	si,2
	call	UpperCase

	if	CACHELOGIC
	cmp	al,'C'
	je	ParseCache
	cmp	al,'K'
	je	ParseKBytes
	endif

	cmp	al,'D'
	je	ParseDevice
	cmp	al,'N'
	je	ParseDrives
	cmp	al,'T'
	je	ParseTasks
	cmp	al,'H'
	jne	$+5
	jmp	ParseHandles
	cmp	al,'L'
	jne	$+5
	jmp	ParseLong
	cmp	al,'O'
	jne	ParseError
	jmp	ParseOffset

	if	CACHELOGIC

ParseCache:
	mov	cx,66
	mov	di,offset sCacheFileName
	mov	ah,0
	call	ParseCopy
	jmp	ParseLoop
ParseKBytes:
	call	DecToBin		; cache file size in kbytes
	mov	dx,1024			; convert to bytes
	mul	dx
	sub	ax,8+64			; subtract header and trailer lengths
	sbb	dx,0
	jl	ParseErrMsg		;0192 don't crash if K=0!
	div	[wBucketBytes]		; compute number of buckets
	or	ax,ax
	mov	dx,offset cgroup:sMsgTooSmall
	jz	ParseErrMsg
	mov	[wCacheBuckets],ax
	jmp	ParseLoop

	endif

ParseError:
	mov	dx,offset cgroup:sMsgSyntax
ParseErrMsg:
	call	DisplayMessage
ToParseDone:
	jmp	ParseDone

ParseDevice:
	mov	cx,8
	mov	di,offset sDevName
	mov	ah,20h
	call	ParseCopy
	jmp	ParseLoop
ParseDrives:
	call	DecToBin
	mov	dx,offset cgroup:sMsgDrives
	or	ax,ax
	jz	ParseErrMsg
	cmp	ax,24
	ja	ParseErrMsg
	mov	[wMaxDrives],ax
	dec	al
	add	[bDriveLast],al
	jmp	ParseLoop
ParseTasks:
	call	DecToBin
	mov	dx,offset cgroup:sMsgTasks
	or	ax,ax
	jz	ParseErrMsg
	cmp	ax,100
	ja	ParseErrMsg
	mov	[wMaxTasks],ax
	jmp	ParseLoop
ParseHandles:
	call	DecToBin		; Number of cd-rom handles allowed
	mov	dx,offset cgroup:sMsgHandles
	cmp	ax,5			; H= must be 5-235, default is 20
	jb	ParseErrMsg
	cmp	ax,235
	ja	ParseErrMsg
	mov	dl,HTLEN
	mul	dl
	add	ax,[wpHTBegin]
	mov	[wpHTEnd],ax
	jmp	ParseLoop
ParseOffset:
	call	DecToBin
	mov	dx,offset cgroup:sMsgOffset
	cmp	ax,20			; O= must be 20-250, default is 192
	jb	ParseErrMsg
	cmp	ax,250
	ja	ParseErrMsg
	mov	[wHandOff],ax
	jmp	ParseLoop
ParseLong:
	call	DecToBin		; min sectors in a noncached read
	mov	dx,offset cgroup:sMsgLong
	cmp	ax,2			; cannot be less than 2
	jae	$+5
	jmp	ParseErrMsg
	mov	dx,2048
	mul	dx
	mov	word ptr [dLongSize],ax
	mov	word ptr [dLongSize+2],dx
	jmp	ParseLoop

ParseDone:

	if	CACHELOGIC

;----------------------- Initialize Cache File -----------------------;

	cmp	word ptr [sCacheFileName+1],'\:'
	jne	ICBadName		; name must be fully qualified

	mov	ax,3d00h		; see if file is already there
	mov	dx,offset sCacheFileName
	int	21h
	jnc	ICGotFile		; yes, get header info
	cmp	ax,2			; verify file-not-found error
	jne	ICFailed

	mov	dx,offset cgroup:sMsgCreating
	call	DisplayMessage
	mov	ah,3ch			; create the file
	xor	cx,cx
	mov	dx,offset sCacheFileName
	int	21h
	jc	ICFailed
	mov	bx,ax

	mov	ah,40h			; write cache header
	mov	cx,CACHEHDRLEN
	mov	dx,offset lCacheHeader
	int	21h
	jc	ICFailed

	mov	si,[wCacheBuckets]	; init the loop
ICWriteLoop:
	mov	ah,40h			; write index for next bucket
	mov	cx,[wCacheIxBytes]
	mov	dx,offset cgroup:lCacheIndexData
	int	21h
	jc	ICFailed
	mov	ax,2048+8		; reposition after bucket data
	mul	[wBucketSectors]
	mov	cx,dx
	mov	dx,ax
	mov	ax,4201h
	int	21h
	jc	ICFailed
	dec	si
	jnz	ICWriteLoop
	mov	ah,40h			; write some trash at the end
	mov	cx,64
	mov	dx,offset sCacheFileName
	int	21h
	jc	ICFailed
	jmp	short ICClose
ICGotFile:
	mov	bx,ax			; file handle
	mov	ah,3fh			; read cache header
	mov	cx,CACHEHDRLEN
	mov	dx,offset lCacheHeader
	int	21h
	jc	ICFailed
	mov	dx,offset cgroup:sMsgFound
	call	DisplayMessage
ICClose:
	mov	ah,3eh			; close the file
	int	21h
	jmp	ICDone
ICBadName:
	mov	dx,offset cgroup:sMsgBadName
	jmp	short ICFailMsg
ICFailed:
	mov	dx,offset cgroup:sMsgCacheInit
ICFailMsg:
	call	DisplayMessage
ICDone:

	endif

;--------------------- Plug Interrupt Vectors -----------------------;

	mov	ax,3520h		; save/set int20 vector
	int	21h
	mov	word ptr [dpOldInt20],bx
	mov	word ptr [dpOldInt20+2],es
	mov	ax,2520h
	mov	dx,offset entint20
	int	21h

	mov	ax,3525h		; save/set int25 vector
	int	21h
	mov	word ptr [dpOldInt25],bx
	mov	word ptr [dpOldInt25+2],es
	mov	ax,2525h
	mov	dx,offset entint25
	int	21h

	mov	ax,352fh		; save/set int2f vector
	int	21h
	mov	word ptr [dpOldInt2f],bx
	mov	word ptr [dpOldInt2f+2],es
	mov	ax,252fh
	mov	dx,offset entint2f
	int	21h

	mov	ax,3521h		; save/set int21 vector
	int	21h
	mov	word ptr [dpOldInt21],bx
	mov	word ptr [dpOldInt21+2],es
	mov	ax,2521h
	mov	dx,offset EntInt21
	int	21h

	mov	dx,ds			; compute index buffer seg address
	mov	ax,[wpHTEnd]
	add	ax,15
	mov	cl,4
	shr	ax,cl
	add	ax,dx
	mov	[wIndexBuffAddr],ax

	mov	dx,[wCacheIXBytes]	; compute data buffer seg address
	add	dx,15
	shr	dx,cl
	add	ax,dx
	mov	[wDataBuffAddr],ax

	mov	dx,[wSectorSize]	; compute drive table seg address
	add	dx,16
	shr	dx,cl
	add	ax,dx
	mov	[wpDriveTable],ax

	mov	ax,TTESIZE		; compute drive table entry length
	mul	[wMaxTasks]
	add	ax,offset lVolTaskTable
	mov	[wDTESize],ax

	mul	[wMaxDrives]		; compute end of drive table
	add	ax,15
	mov	cl,4
	shr	ax,cl
	add	ax,[wpDriveTable]

	pop	bx
	pop	es

	mov	word ptr es:[bx+14],0	; driver ends after drive table
	mov	word ptr es:[bx+16],ax
	mov	word ptr es:[bx+18],offset wpBPB ; pointer to BPB array
	mov	word ptr es:[bx+20],ds
	mov	ax,[wMaxDrives]		; number of units
	mov	byte ptr es:[bx+13],al

;------ Check Serial Number -----------------------------------------;

	cmp	word ptr [sSerial+4],'IM' ; check if " 30-MINUTE DEMO..."
	je	WrapUp			; if so, no message
	cmp	byte ptr [sSerial],'5'	; MOS versions must start >= 5

	if	DOSCODE
	jae	SerialError
	else
	jb	SerialError
	endif

	xor	si,si
	xor	di,di
	lea	bx,[wPrimes]
SerLoop1:
	xor	ax,ax
	mov	al,[sSerial+si]
	and	al,0fh
	inc	si
	add	ax,si
	mul	word ptr ds:[bx]
	add	di,ax
	add	bx,2
	cmp	si,6
	jb	SerLoop1

	mov	ax,di

	mov	cl,ah			; some extra scrambling
	xor	cl,al
	and	cl,7
	ror	ah,cl
	xor	al,ah

	mov	bx,10
SerLoop2:
	xor	dx,dx
	div	bx
	add	dl,'0'
	cmp	[sSerial+si],dl
	jne	SerialError
	inc	si
	cmp	si,9
	jb	SerLoop2

	lea	di,[DemoJump]		; turn off demo expiration
	mov	word ptr ds:[di],9090h

	jmp	short WrapUp
SerialError:
	mov	dx,offset cgroup:sMsgSerial
	call	DisplayMessage

;------ Wrap Up -----------------------------------------------------;

WrapUp	label	near
	push	es
	push	ds			; clear file handle table

	mov	es,[wZero]		; set demo start time
	mov	ax,es:[046ch]
	mov	[wStartTime],ax

	pop	es
	mov	di,[wpHTBegin]
	mov	cx,[wpHTEnd]
	sub	cx,di
	shr	cx,1
	mov	ax,0ffffh
	cld
	jmp	initfin

;---------------------- Get SCB Address if MOS ----------------------;

getos	proc	near
	push	es
	push	bx
	mov	ah,30h			; get dos version
	int	21h
	push	ax
	mov	ah,30h			; get mos version
	mov	bx,ax
	mov	cx,ax
	mov	dx,ax
	int	21h
	pop	dx
	cmp	ax,dx			; if they're the same, it's dos
	je	gosdone
	mov	ah,02h			; get mos scb address
	int	38h
	mov	word ptr [dpMOSSCB],bx
	mov	word ptr [dpMOSSCB+2],es
	mov	[wMaxTasks],3		; default number of tasks supported
gosdone:
	pop	bx
	pop	es
	ret
getos	endp

;------------------------ Parsing Subroutines -----------------------;

FindDelimeter proc near
	mov	al,es:[si]
	cmp	al,20h
	jbe	FDRet
	inc	si
	jmp	FindDelimeter
FDRet:
	ret
FindDelimeter endp

FindNonBlank proc near
	mov	al,es:[si]
	cmp	al,20h
	jne	FNRet
	inc	si
	jmp	FindNonBlank
FNRet:
	ret
FindNonBlank endp

ParseCopy proc	near
	push	ds
	push	es
	pop	ds
	pop	es
	cld
PCLoop:
	lodsb
	cmp	al,20h
	jbe	PCWrap
	call	UpperCase
	stosb
	loop	PCLoop
	jmp	short PCRet
PCWrap:
	dec	si
	mov	al,ah
	rep	stosb
PCRet:
	push	ds
	push	es
	pop	ds
	pop	es
	ret
ParseCopy endp

DisplayMessage proc near
	mov	ah,9
	int	21h
	ret
DisplayMessage endp

;--------------------- Decimal-to-Binary Routine --------------------;

DecToBin proc	near
	xor	ax,ax
dtbloop:
	mov	dl,es:[si]
	cmp	dl,'0'
	jb	dtbdone
	cmp	dl,'9'
	ja	dtbdone
	push	dx
	mul	[wTen]
	pop	dx
	and	dx,000fh
	add	ax,dx
	inc	si
	jmp	dtbloop
dtbdone:
	ret
DecToBin endp

initseg	ends
	end
