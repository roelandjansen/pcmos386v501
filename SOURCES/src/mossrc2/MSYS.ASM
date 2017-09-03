	include page.inc
	title	MOSSYS - create MOS boot sector

	subttl	MOSSYS Development Specification

;-----------------------------------------------------------------------;
;									;
;		     Development Specification				;
;									;
;									;
; Program Name: MOSSYS.COM		 Assigned to: Jim Bean		;
; Module Name:	MOSSYS			 Assign date: 01/13/86		;
; Entry Points: MOSSYS			 Completed:   01/29/86		;
; Entry From:	DOS command processor					;
; Entry Method: EXEC							;
; Purpose:	Create MOS boot sector					;
; Refer To:	LANLink module LANGENDD.ASM (might help)		;
; Last Update:	01/25/90						;
;									;
; MOSSYS is an independent utility which writes a MOS boot sector	;
; (sector 0) to a previously-formatted diskette.  The sector is 	;
; assumed to be 512 bytes, the first 30 of which are spoken for.	;
; The challenge, then, is to write a sector to the disk which does	;
; the following in 482 bytes of code:					;
;									;
; (1)  Locate the root directory entry for the file named		;
;      $$MOS.COM.  If it's not there, display a message.                ;
;									;
; (2)  Accessing the FAT as required, load the file into memory 	;
;      starting at address 0080:0000.  Allow for either 12-bit or	;
;      16-bit FAT entries.						;
;									;
; (3)  Jump to location 0080:0000.					;
;									;
;-----------------------------------------------------------------------;

	subttl	discussion of MOSSYS as implemented
	page

;-----------------------------------------------------------------------;
; jrb 02/12/86 08:30 added the following discussion (no code change)	;
;									;
; usage: MOSSYS d:							;
;									;
; writes the MOS bootstrap sector to the designated drive		;
; drive must be designated or you'll get a usage, copyright and         ;
; version msg								;
;									;
; 1.  read the disk parameter block of the designated drive and 	;
;     construct a bios parameter block for the drive			;
; 2.  read the boot sector of the designated drive and compare the bios ;
;     parameter block on the boot sector with the constructed bpb	;
; 3.  if they differ only in the total sectors field, and differ	;
;     reasonably in the total sectors field, then use the boot sector	;
;     bpb, else use the constructed bpb 				;
; 4.  if media descriptor is 0f8h then disk is a fixed disk		;
;     a.  read disk parameters (INT 13H, function 08H, drive 80H)	;
;     b.  construct sectors/track and heads fields			;
;     c.  read partition table sector and compute number of hidden	;
;	  sectors							;
; 5.  else disk is a floppy disk, construct sectors/track, heads and	;
;     hidden sectors fields according to DOS TECH REF pgs. 2-24, 25	;
; 6.  move the boot sector bpb into the bootstrap code (segment 	;
;     bootstrap), sectors/track, heads and hidden sectors fields into	;
;     the bootstrap code						;
; 7.  write the bootstrap code to the boot sector of the designated	;
;     drive								;
;									;
;-----------------------------------------------------------------------;
;									;
; jrb 03/06/86								;
;									;
; MOSINIT needs to know which disk it was booted from - in particular	;
; it needs to know all the BIOS parameter block information for the	;
; disk so it can be passed to the standard block device driver for	;
; locating and reading CONFIG.SYS and COMMAND.COM			;
;									;
; therefore -								;
;   through a happy quirk of fate, when the boot sector transfers to	;
;   $$MOS.SYS, the DS register contains the segment address of the	;
;   start of the boot sector.  The BPB for the boot disk begins at	;
;   offset 11 in that segment.	From offset 3 to offset 10 is a string	;
;   which begins 'TSL '.  At offset 28 is the drive number to be	;
;   used in calling the BIOS INT 13H to read or write sectors		;
;   These are the elements of the boot sector code and format upon	;
;   which the $$MOS.SYS code will depend in order that it can access	;
;   the boot disk							;
;									;
;-----------------------------------------------------------------------;
; DAM 12/30/86 Changed boot sector relocation address. (%%%%)		;
;-----------------------------------------------------------------------;
; DAM 1/02/86 MOS load address to 80:0 to avoid DMA conflicts		;
;-----------------------------------------------------------------------;
; RBR 5/12/87 Message corrections.					;
;-----------------------------------------------------------------------;
; BMW 5/18/87 Rem out the check for version call.			;
;-----------------------------------------------------------------------;
; RBR 7/16/87 Support 3.5" 720K and 1.44M formats			;
;-----------------------------------------------------------------------;
; RKG 11/03/88 Flush the disk buffers so boot record actually written	;
;-----------------------------------------------------------------------;
; BWR 11/30/89 Marked messages for foreign language translation		;
;-----------------------------------------------------------------------;
; SAH 01/25/90 Remove unneed code for version check.			;
;-----------------------------------------------------------------------;
	include msys.pub

	subttl	MOSSYS macros, equates, data
	page

farret	macro
	db	0cbh
	endm

dos	macro	fn
	mov	ah,fn
	int	21h
	endm

	;dos function calls

prnchr	equ	02h	;display dl=char
prnstr	equ	09h	;display ds:dx->string ending in '$'
setdrv	equ	0eh	;set dl=drive current (a=0)
getdrv	equ	19h	;return al=current drive (a=0)
getdpb	equ	32h	;undocumented - return disk parameter block for
			;  dl=drive (default=0)

true	equ	0ffh
false	equ	0	

moss	segment para
bgnmoss label	byte

	assume	cs:moss,ds:moss,es:moss,ss:moss
	org	0100h
start:
	jmp	msys

hlpmsg	db	0dh,0ah,    'MSYS - Version 4.10' ;@@XLAT
	db	0dh,0ah,    '(c) Copyright 1987, 1988, 1989, 1990' ;@@XLAT
	db	' The Software Link, Incorporated' ;@@XLAT
	db	0dh,0ah,0ah,'enter:    MSYS A:' ;@@XLAT
	db	0dh,0ah,0ah,'to place a MOS boot sector on the disk in drive A             ' ;@@XLAT
	db	0dh,0ah,'$'

error	db	0		;exit code returned to dos
tdrive	db	0		;target drive for boot sector
dftdrv	db	0		;current drive when we started up
bootloc dw	0		;segment location of bootstrap segment

	; bios parameter block is constructed here then moved to bootstrap code

dpbbpb	label	byte

dsctsiz dw	512		;sector size in bytes
dausiz	db	2		;sectors per allocation unit
drsrvd	dw	1		;number of reserved sectors (before first FAT)
dnumfat db	2		;number of FAT's
dnumdir dw	112		;number of root directory entries allowed
dtotsct dw	720		;total number of sectors 
dmedia	db	0fdh		;media descriptor
dfatsiz db	2		;number of sectors in each FAT
dtotsch db	0

	; following 7 bytes included also (but not part of bpb)

dscttrk dw	0		;number of sectors per track
dhddrv	dw	0		;number of heads
dhidden dw	0		;number of hidden sectors (partition table)
ddrive	db	0		;this is the boot drive (normally 00h or 80h)
dhddnh	db	0
bpblen	equ	$-dpbbpb

	; boot sector bios parameter block is moved here after being read from
	; the target drive 

bootbpb label	byte

bsctsiz dw	512		;sector size in bytes
bausiz	db	2		;sectors per allocation unit
brsrvd	dw	1		;number of reserved sectors (before first FAT)
bnumfat db	2		;number of FAT's
bnumdir dw	112		;number of root directory entries allowed
btotsct dw	720		;total number of sectors
bmedia	db	0fdh		;media descriptor
bfatsiz db	2		;number of sectors in each FAT
btotsch db	0

	; following 7 bytes included also (but not part of bpb)

bscttrk dw	9		;number of sectors per track
bhddrv	dw	2		;number of heads
bhidden dw	0		;number of hidden sectors (partition table)
bdrive	db	0
bhddnh	db	0

	; This structure used in generic I/O CTL call (440d, 60)

gispf	db	1		; special function - return BPB from load BPB
gidt	db	?		; device type		- set by IOCTL call
gida	dw	?		; device attribute	- so are all the rest
ginc	dw	?		; number of cylinders	-	"
gimt	db	?		; media type		-	"
gibps	dw	?		; bytes per sector
gispc	db	?		; sectors per cluster
girsct	dw	?		; reserved sectors
ginfat	db	?		; number of FATs
girtdir	dw	?		; number of root directory entries
gitsct	dw	?		; low word of total sectors
gimd	db	?		; media descriptor
giscpf	db	?		; sectors per fat
gitschi	db	?		; high byte of total sectors
gispt	dw	?		; sectors per track
gihds	dw	?		; number of heads
gihdn	dd	?		; hidden sectors
girsv1	dd	?		; reserved
girsv2	db	6 dup (?)	; reserved



badmedia db	0dh,0ah,'Unable to recognize disk type in drive            ' ;@@XLAT
meddrv	db	'A',0dh,0ah,'$'

mediatbl label	word
	dw	diskf0		;Rod  f0 is 1.44M 3.5" diskette
	dw	7 dup(0)	;Rod  f1-f7 are invalid media descriptors
	dw	diskf8		;disk is a fixed disk
	dw	diskf9		;disk is a quad-density floppy or 720K
	dw	0		;fa an invalid media descriptor
	dw	0		;fb an invalid media descriptor
	dw	diskfc		;fc is a single-sided, 9-sectored floppy
	dw	diskfd		;fd is a double-sided, 9-sectored floppy
				;  or a double-sided, 26-sectored floppy
	dw	diskfe		;fe is a single-sided, 8-sectored floppy
				;  or a single-sided, 26-sectored floppy
				;  or a double-sided, 8-sectored floppy
	dw	diskff		;ff is a double-sided, 8-sectored floppy

	subttl	main-line code for msys
	page

msys: 
	dos	getdrv		;read current default drive
	mov	[dftdrv],al
	mov	bx,cs
	add	bx,(endmoss-bgnmoss+15) shr 4	;paragraph offset of bootstrap
	mov	[bootloc],bx
	call	parse		;get any and all command line parameters
	jnz	mossy4
	call	makebpb 	;construct bpb from target drive dbp
	jnz	mossy4
	call	rdbpb		;read boot sector bpb from target drive 
	jnz	mossy4
	call	cmpbpb		;compare the two bpb's
	jne	mossy1		;ne if they're unacceptably different
				;  (take the constructed bpb)
	lea	di,dpbbpb	;else move boot sector bpb to constructed bpb
	lea	si,bootbpb	;  it will be the "real" bpb from now on
	mov	cx,bpblen
	rep movsb
mossy1:
	mov	bl,[dmedia]	;translate f8-ff media byte to 0-7

;Rod	add	bl,8
;Rod	cmp	bl,8
	add	bl,10h		;Rod  convert media descriptor to index
	cmp	bl,10h		;Rod

	jae	mossy2
	xor	bh,bh
	add	bx,bx
	mov	bx,[bx+mediatbl]
	or	bx,bx
	jnz	mossy3
mossy2:
	mov	al,[tdrive]	;couldn't recognize media descriptor byte
	add	al,'A'
	mov	[meddrv],al
	lea	dx,badmedia
	dos	prnstr
	mov	[error],3
	jmp	mossy4
mossy3:
	call	bx
	jnz	mossy4
	mov	[ddrive],al
	call	setboot 	;setup bootstrap data
	call	wrboot		;write the bootstrap code to the boot sector
mossy4:
	mov	ah,4ch		;exit to dos with error code (or 0)
	mov	al,[error]
	int	21h

	subttl	parse - get command-line parameters
	page

; get command-line parameters
; only valid parameter is of the form '     x:      '
; where x is a upper or lower case drive letter recognizeable to dos,
; preceded by any number of chars <= spaces and the colon may be followed by
; any number of chars <= spaces
; reports anything else as an error, along with the copyright and usage msg
;   at the beginning of this code

parse:
	mov	si,80h
	lodsb
	mov	cl,al
	xor	ch,ch
	jcxz	pars2
pars1:				;skip to first non-blank
	lodsb
	cmp	al,' '
	ja	pars3
	loop	pars1
pars2:	mov    al,'?'		;nothing specified is the same as ?
pars3:
	cmp	al,'?'
	jne	pars4
	lea	dx,hlpmsg
	dos	prnstr
	mov	[error],1
	or	al,0ffh
	ret
pars4:
	dec	si		;backup onto drive letter for error reporting
	cmp	cx,1		;drive requires a colon (must be >= 2 left)
	jz	parsx		;z if no more chars on command line (no colon)
	cmp	byte ptr [si+1],':'
	jne	parsx		;whatever it is, it isn't like we want
	call	caps
	sub	al,'A'
	mov	dl,al		;validate drive by setting it current
	dos	setdrv		;then reading the current drive and making
	dos	getdrv		;sure we were successful in setting it
	mov	ah,dl
	push	ax
	mov	dl,[dftdrv]
	dos	setdrv
	pop	ax
	cmp	al,ah		
	jne	parsy		;ne means we couldn't successfully set it
	mov	[tdrive],al
	inc	si		;move to char following colon
	inc	si
	dec	cx
	dec	cx		
	jcxz	pars6

	; make sure there aren't any extra non-blank characters on the
	; command line
pars5:
	cmp	byte ptr [si],' '
	ja	parsz
	inc	si
	loop	pars5
pars6:
	xor	al,al
	ret			;no errors

	; first non-blank encountered wasn't a drive specification (no colon)
parsx:
	call	string
	lea	dx,baddrv
	dos	prnstr
	lea	dx,hlpmsg
	dos	prnstr
	mov	[error],2
	or	al,0ffh
	ret

	; drive specification was invalid
parsy:
	call	string
	lea	dx,invdrv
	dos	prnstr
	lea	dx,hlpmsg
	dos	prnstr
	mov	[error],2
	or	al,0ffh
	ret

	; extra characters following a valid drive specification
parsz:
	call	string
	lea	dx,ignore
	dos	prnstr
	lea	dx,hlpmsg
	dos	prnstr
	mov	[error],2
	or	al,0ffh
	ret

baddrv	db	' is not a drive specification         ',0dh,0ah,'$' ;@@XLAT
invdrv	db	' is an invalid drive        ',0dh,0ah,'$' ;@@XLAT
ignore	db	' is extra ',0dh,0ah,'$' ;@@XLAT

; display the command-line string from the position pointed to by si to the end

string:
	mov	dl,0dh
	dos	prnchr
	mov	dl,0ah
	dos	prnchr
	mov	dl,"'"
	dos	prnchr
strin1:
	lodsb
	mov	dl,al
	dos	prnchr
	loop	strin1
	mov	dl,"'"
	dos	prnchr
	ret

; guess what this one does

caps:
	cmp	al,'a'
	jb	caps1
	cmp	al,'z'
	ja	caps1
	sub	al,'a'-'A'
caps1:
	ret

	subttl	makebpb - construct bpb from dos dbp
	page

; do undocumented dos call to get disk parameter block
; dl = drive (0 = default)
; translate that format to bios parameter block format
;   just because the bios parameter block can be obtained on IBM-formatted
;   disks from the boot sector, and maybe we'll want to use that protocol in
;   dingo, at least it's a documented protocol for device drivers and boot
;   sectors while the dpb format is not
;
; below message shouldn't happen because we've already verified above that
; we could successfully make the drive the current drive

bpberr	db	0dh,0ah,'Error reading disk parameters for drive             ' ;@@XLAT
bpbdrv	db	'A',0dh,0ah,'$'

; this is what dbp looks like - but it's not documented so be careful

dbp	struc
xdrive	db	0	;logical drive
xunit	db	0	;driver unit number
xssize	dw	0	;sector size
xcmask	db	0	;cluster mask
xcshift db	0	;cluster shift count
xfat1	dw	0	;fat 1 start sector
xfnum	db	0	;number fat's
xdnum	dw	0	;number root dir entries
xdata1	dw	0	;cluster 2 start sector
xcnum	dw	0	;number of clusters + 1
xfsize	db	0	;fat size in sectors
xdir1	dw	0	;directory start sector
xdriver dd	0	;address of device driver
xmedia	db	0	;media byte
xfirst	db	0	;first access?
xnext	dd	0	;next dpb
xcd	db	64 dup(0)	;current directory
dbp	ends

makebpb:
	mov	dl,[tdrive]
	inc	dl
	dos	getdpb
	inc	al
	jnz	mkbpb1
	push	cs
	pop	ds
	mov	al,[tdrive]
	add	al,'A'
	mov	[bpbdrv],al
	lea	dx,bpberr
	dos	prnstr
	mov	[error],3
	or	al,0ffh
	ret
mkbpb1:
		assume	ds:nothing	
	mov	ax,[bx].xssize	;sector size
	mov	[dsctsiz],ax
	mov	al,[bx].xcmask	;mask is sectors/cluster-1
				;  (must be why sectors/cluster a power of 2)
	inc	al
	mov	[dausiz],al
	mov	ax,[bx].xfat1	;number of reserved sectors same as start
	mov	[drsrvd],ax	;  sector for first fat
	mov	al,[bx].xfnum	;number of fat's
	mov	[dnumfat],al
	mov	ax,[bx].xdnum	;number of root directory entries
	mov	[dnumdir],ax
	mov	ax,[bx].xcnum	;number of clusters + 1
	dec	ax
	mov	cl,[dausiz]
	xor	ch,ch
	mul	cx		;converting clusters to sectors
	add	ax,[bx].xdata1	;address of start of data clusters (cluster 2) 
	adc	dl,0
	mov	[dtotsct],ax
	mov	[dtotsch],dl
	mov	al,[bx].xmedia	;media desriptor byte
	mov	[dmedia],al
	mov	al,[bx].xfsize	;file allocation table size in sectors
	mov	[dfatsiz],al
	push	cs
	pop	ds

	assume	ds:moss

	xor	al,al
	ret

	subttl	rdbpb - read boot sector bpb from target drive
	page

rderr	db	0dh,0ah,'Error reading boot sector from drive           ' ;@@XLAT
rddrv	db	'A',0dh,0ah,'$'

	; sector read past bootstrap segment, then bpb copied into
	; bootbpb
rdbpb:
	mov	al,[tdrive]
	push	ds
	mov	ds,[bootloc]	;segment location of bootstrap

	assume	ds:nothing

	lea	bx,bootbuf
	mov	cx,1		;reading 1 sector
	mov	dx,0		;starting at logical sector 0

	push	di		; save out value used for int 25h call
	push	si		;  "    "    "    "    "   "   "   "
	mov	si,0		; high word of sector
	mov	di,0fffch	; flag set to show int 25h that it is to use
				; si as the high wrd of sector
	int	25h		; call it
	pop	si		; restore the saved values
	pop	di

	pop	cx		;throw away flags
	jnc	rdbpb1
	pop	ds		;some error reading boot sector
	mov	cl,[tdrive]
	add	cl,'A'
	mov	[rddrv],cl
	lea	dx,rderr
	dos	prnstr
	mov	[error],3
	or	al,0ffh
	ret
rdbpb1: 
	lea	si,bootbuf+11	;all we really wanted was the bpb
	lea	di,bootbpb
	mov	cx,bpblen
	rep movsb
	pop	ds

	assume	ds:moss

	xor	al,al
	ret

	subttl	cmpbpb - compare boot sector bpb with constructed bpb
	page

	; if no difference, or
	;   the only difference is the total sectors, and the boot total
	;   sectors is less than the constructed total sectors + the cluster
	;   size, then return z (zero flag set)
	; else return nz

cmpbpb:
	push	dx
	mov	ax,[btotsct]
	mov	dl,[btotsch]
	mov	cx,[dtotsct]
	mov	dh,[dtotsch]
	mov	[btotsct],cx	;force total sector match and check everything
	mov	[btotsch],dh
	lea	si,bootbpb	;  else
	lea	di,dpbbpb
	mov	cx,bpblen-8	;not concerned with sectors/track, etc.
	repe cmpsb
	mov	[btotsct],ax	;restore boot sector total sectors
	mov	[btotsch],dl
	jne	cpbpb1		;if ne, we know the answer now (wrong)

	; else make sure total sectors agree within the rounding
	; of one allocation unit
	; constructed total <= boot total < constructed total + au size

	mov	dl,[dtotsch]
	cmp	dl,[btotsch]
	jne	cpbpb1		;constructed can't be > boot and can't be
				;  64K < boot
	mov	ax,[dtotsct]
	cmp	ax,[btotsct]
	jae	cpbpb1		;e if they agree exactly, else wrong if above
	mov	dh,[dausiz]
	dec	dh
	add	al,dh
	adc	ah,0
	adc	dl,0
	cmp	dl,[btotsch]
	jne	cpbpb1
	cmp	ax,[btotsct]
	jb	cpbpb1		;constructed + (ausiz - 1) < boot is wrong
	xor	al,al		;else they agree enough (set Z)
cpbpb1:
	pop	dx
	ret

	subttl	wrboot - write MOS bootstrap sector to target drive
	page

wrerr	db	0dh,0ah,'Error writing boot sector to drive                 ' ;@@XLAT
wrdrv	db	'A',0dh,0ah,'$'

wrboot:
	mov	al,[tdrive]
	push	ds
		assume	ds:nothing	
	mov	ds,[bootloc]	;segment location of bootstrap
	mov	bx,0		;offset of bootstrap code
	mov	cx,1		;writing 1 sector
	mov	dx,0		;starting at logical sector 0

	push	di		; save out value used for int 26h call
	push	si		;  "    "    "    "    "   "   "   "
	mov	si,0		; high word of sector
	mov	di,0fffch	; flag set to show int 26h that it is to use
				; si as the high wrd of sector
	int	26h		; call it
	pop	si		; restore the saved values
	pop	di

	pop	cx		;throw away flags
	pop	ds
	jc	wrbpb1

	mov	ah,0Dh		; flush disk buffers
	int	21h
	xor	al,al
	ret
	
wrbpb1:
	mov	cl,[tdrive]	;some error writing boot sector
	add	cl,'A'
	mov	[wrdrv],cl
	lea	dx,wrerr
	dos	prnstr
	mov	[error],3
	or	al,0ffh
	ret

	subttl	determine sector/track, etc. from disk media type
	page

fixeder db	0dh,0ah,'Error reading fixed disk parameters       ',0dh,0ah,'$' ;@@XLAT

	; this is a fixed disk, get information from generic I/O CTL
diskf8:
	mov	ax,440dh	; generic IOCTL call
	mov	bl,[tdrive]	; target drive
	inc	bl		; (0 means default drivve to IOCTL)
	mov	cx,0860h	; get device parameters
	lea	dx,gispf	; parameter block for call
	int	21h
	jc	diskf8x		; if can't get parameters
	mov	dx,[gihds]	; number of heads
	mov	[dhddrv],dx
	mov	cx,[gispt]	; sectors per track
	mov	[dscttrk],cx

	mov	ax,word ptr [gihdn]
	mov	cx,word ptr [gihdn+2]	; hidden sectors
	cmp	ch,0
	jne	diskf8x 	;too many hidden sectors
	mov	[dhidden],ax
	mov	[dhddnh],cl

	mov	al,80h		;drive 80h (can only boot first fixed disk)
	cmp	al,al		;no error
	ret
diskf8x:
	lea	dx,fixeder
	dos	prnstr
	or	al,0ffh 	;can't get disk information from int 13
	ret

	;Rod  this is a double-sided, 18-sectored 3.5" floppy
diskf0: 			;Rod
	mov	[dhidden],0	;Rod  with no hidden sectors
	mov	[dhddnh],0	;Rod
	mov	[dhddrv],2	;Rod  2 heads
	mov	[dscttrk],18	;Rod  18 sectors/track
	xor	al,al		;Rod  drive 0 and no error
	ret

	; this is a double-sided, quad-density 5 1/4" floppy
	;Rod  OR a 720K 3.5" diskette

diskf9:
	mov	[dhidden],0	;no hidden sectors on a floppy
	mov	[dhddnh],0
	mov	[dhddrv],2	;two heads (double-sided)
	mov	[dscttrk],15	;15 sectors/track 

	mov	ax,0201h	;Rod  read 1 sector
	mov	dl,[tdrive]	;Rod  drive is target drive
	mov	dh,0		;Rod  head 0
	mov	ch,0		;Rod  track 0
	mov	cl,14		;Rod  sector 14 
	lea	bx,bootbuf	;Rod
	push	es		;Rod
	mov	es,[bootloc]	;Rod
	int	13h		;Rod
	pop	es		;Rod
	jnc	dskf91		;Rod  if we can't read sector 14, 
	mov	[dscttrk],9	;Rod    assume 9 sectors per track
dskf91:				;Rod

	xor	al,al		;drive 0 and no error 
	ret

	; this is a single-sided, 9-sectored 5 1/4" floppy
diskfc:
	mov	[dhidden],0	;no hidden sectors on a floppy
	mov	[dhddnh],0 
	mov	[dhddrv],1	;one head (single-sided)
	mov	[dscttrk],9	;9 sectors/track
	xor	al,al		;drive 0 and no error
	ret

	; this is a double-sided, 9-sectored 5 1/4" floppy
	; or it is a double-sided 26-sectored 8" floppy
diskfd:
	mov	[dhidden],0	;either way it has no hidden sectors
	mov	[dhddnh],0
	mov	[dhddrv],2	;and is double-sided
	mov	[dscttrk],9	;but there may be 26 sectors/track
	mov	ax,0201h	;read 1 sector
	mov	dl,[tdrive]	;drive is target drive
	mov	dh,0		;head 0
	mov	ch,0		;track 0
	mov	cl,25		;sector 25 (maybe it starts with 0)
	lea	bx,bootbuf
	push	es
	mov	es,[bootloc]
	int	13h
	pop	es
	jc	dskfd1
	mov	[dscttrk],26	;since we can read sector 25, we assume 26
				;  sectors per track
dskfd1:
	xor	al,al		;drive 0 and no error
	ret

	; this is a single-sided, 8-sectored 5 1/4" floppy
	; or it is a single-sided, 26-sectored 8" floppy
	; or it is a double-sided, 8-sectored 8" floppy
diskfe:
	mov	[dhidden],0	;it has no hidden sectors
	mov	[dhddnh],0
	mov	[dhddrv],1	;it may have one or two heads
	mov	[dscttrk],26	;it may have 8 or 26 sectors/track

	; try reading sector 25

	mov	ax,0201h	;read 1 sector
	mov	dl,[tdrive]	;drive is target drive
	mov	dh,0		;head 0
	mov	ch,0		;track 0
	mov	cl,25		;sector 25 (maybe it starts with 0)
	lea	bx,bootbuf
	push	es
	mov	es,[bootloc]
	int	13h
	pop	es
	jnc	dskfe1

	; is 8-sectored, try reading second head

	mov	[dscttrk],8
	mov	ax,0201h
	mov	dl,[tdrive]
	mov	dh,1		;head 1
	mov	ch,0		;track 0
	mov	cl,1		;sector 1
	lea	bx,bootbuf
	push	es
	mov	es,[bootloc]
	int	13h
	pop	es
	jc	dskfe1
	mov	[dhddrv],2
dskfe1:
	xor	al,al		;drive 0 and no error
	ret

	; this is a double-sided, 8-sectored 5 1/4" floppy
diskff: 
	mov	[dhidden],0	;with no hidden sectors
	mov	[dhddnh],0
	mov	[dhddrv],2	;2 heads
	mov	[dscttrk],8	;8 sectors/track
	xor	al,al		;drive 0 and no error
	ret

	subttl	setboot - set-up for bootstrap data
	page

setboot:
	mov	es,[bootloc]	;put bpb, etc into bootstrap sector

	assume	es:bootstrap

	lea	di,bsbpb	;bootstrap bpb location
	lea	si,dpbbpb
	mov	cx,bpblen
	rep movsb
	push	es
	pop	ds

	assume	ds:bootstrap

	mov	al,[numfat]
	mul	[fatsiz]
	add	ax,[rsrvd]	;ax = sector address of root directory
	mov	[dirsct],ax
	mov	ax,[numdir]	;computing sector address of start of data
	mov	cx,32		;each directory entry is 32 bytes long
	mul	cx		;dx:ax = length in bytes of directory
	mov	cx,[sctsiz]
	dec	cx
	add	ax,cx		;+ sctsiz - 1
	adc	dx,0
	div	[sctsiz]	;ax = number of sectors in root directory
	add	ax,[dirsct]	;add to sector address of dir start
				;  gives sector address of data cluster 2
				;  (by definition)
	mov	[cdata],ax	;  clusters >= 2)
	mov	ax,[totsct]	;see if it's a 16-bit or 12-bit fat
	sub	ax,[cdata]
	xor	dx,dx
	mov	dl,[totscth]	; high byte of total sectors
	mov	cl,[ausiz]
	xor	ch,ch
	div	cx
	mov	[bigfat],true
	cmp	ax,4096-10	;0-fff excluding 0,1,ff8-fff
	ja	setbt1
	mov	[bigfat],false	;note, if 16-bit not necessary, then we
				;  assume it's 12-bit
setbt1:
	mov	ax,512		; bootstrap is 512-bytes long
	add	ax,[sctsiz]
	add	ax,[sctsiz]
	mov	[endbf2],ax
	add	ax,256
	mov	[endboot],ax
	mov	cl,4
	shr	ax,cl
	neg	ax
	add	ax,MINMEM
	mov	[locboot],ax	;location to relocate bootstrap
	mov	cl,-1
	mov	ax,[sctsiz]
setbt2: inc	cl
	shr	ax,1
	jnz	setbt2
	mov	[sctshft],cl
	mov	ax,[sctsiz]
	mov	cl,4
	shr	ax,cl		; Calc # segments
	mov	[secpara],ax	; Set in boot code for file load use
	push	cs
	pop	ds
	push	cs
	pop	es
	ret




endmoss label	byte

moss	ends

	subttl	boot sector
	page

bootstrap segment	para
	include	mboot.inc
bootstrap ends
	end	start
