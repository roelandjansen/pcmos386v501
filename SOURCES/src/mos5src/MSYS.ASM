	include page.inc
	title	msys - create mos boot sector
comment ^===============================================================
		    development specification

 program name:	msys.com		assigned to: david morrow
 module name:	msys			assign date: 01/16/86
 entry points:	org 100h		completed:
 entry from:	exec
 entry method:	exec
 calls:		n/a
 purpose:	write a mos pbr
 refer to:	
 last update:	03/12/92

=======================================================================

 msys is an independent utility which writes a mos boot sector
 (sector 0) to a previously-formatted diskette.  the sector is
 assumed to be 512 bytes, the first 30 of which are spoken for.
 the challenge, then, is to write a sector to the disk which does
 the following in 482 bytes of code:

 (1)  locate the root directory entry for the file named
      $$mos.com.  if it's not there, display a message.

 (2)  accessing the fat as required, load the file into memory
      starting at address 0080:0000.  allow for either 12-bit or
      16-bit fat entries.

 (3)  jump to location 0080:0000.

 jrb 02/12/86 08:30 added the following discussion (no code change)

 usage: msys d:

 writes the mos bootstrap sector to the designated drive
 drive must be designated or you'll get a usage, copyright and
 version msg

 1.  read the disk parameter block of the designated drive and
     construct a bios parameter block for the drive
 2.  read the boot sector of the designated drive and compare the bios
     parameter block on the boot sector with the constructed bpb
 3.  if they differ only in the total sectors field, and differ
     reasonably in the total sectors field, then use the boot sector
     bpb, else use the constructed bpb
 4.  if media descriptor is 0f8h then disk is a fixed disk
     a.  read disk parameters (int 13h, function 08h, drive 80h)
     b.  construct sectors/track and heads fields
     c.  read partition table sector and compute number of hidden
	  sectors
 5.  else disk is a floppy disk, construct sectors/track, heads and
     hidden sectors fields according to dos tech ref pgs. 2-24, 25
 6.  move the boot sector bpb into the bootstrap code (segment
     bootstrap), sectors/track, heads and hidden sectors fields into
     the bootstrap code
 7.  write the bootstrap code to the boot sector of the designated
     drive

=======================================================================

jrb 03/06/86	mosinit needs to know which disk it was booted from - in
		particular it needs to know all the bios parameter block
		information for the disk so it can be passed to the
		standard block device driver for locating and reading
		config.sys and command.com
		therefore - through a happy quirk of fate, when the boot
		sector transfers to $$mos.sys, the ds register contains
		the segment address of the start of the boot sector.  the
		bpb for the boot disk begins at offset 11 in that
		segment.	from offset 3 to offset 10 is a string
		which begins 'TSL '.  at offset 28 is the drive number to
		be used in calling the bios int 13h to read or write
		sectors these are the elements of the boot sector code
		and format upon which the $$mos.sys code will depend in
		order that it can access the boot disk

dam 12/30/86	changed boot sector relocation address. (%%%%)

dam 1/02/86	mos load address to 80:0 to avoid dma conflicts

rbr 5/12/87	message corrections.

bmw 5/18/87	rem out the check for version call.

rbr 7/16/87	support 3.5" 720K and 1.44M formats

rkg 11/03/88	flush the disk buffers so boot record actually written

bwr 11/30/89	marked messages for foreign language translation

sah 01/25/90	remove unneed code for version check.

mjs 12/16/91	dlg mods: complete overhaul.  checks the dos and mos version
		numbers and adjusts int25/int26 calling method, using the
		new interface for dos 4.0 and newer.  also adjusts the
		format of the dpb if pre-dos4.0.  will not operate on an
		mlg partition.  builds an extended partition boot record. 
		converted to use of structures within dskstruc.inc.

mjs 03/03/92	added msys/m logic for conversion of mlg to dlg.

sah 03/12/92	check true dos, check network drive, also update version
		# to 5.01 and copyright to 1992.

mjs 03/12/92	correct version number checking logic added by sah
		on 03/12/92.

======================================================================^

	include msys.pub
	include dskstruc.inc
	include macros.inc

	subttl msys macros, equates, data
	page

true	equ	0ffh
false	equ	0

moss	segment para
bgnmoss label	byte
	assume	cs:moss,ds:moss,es:moss,ss:moss

;==== start of lines that must stay together
	org	0100h
start:
	jmp	msys
	db	'MSYS/M'	; hdsetup checks for this signature
;==== end of lines that must stay together

	db	9 dup (8), 3 dup (' '),13

copyright db	'MSYS - Version 5.01',13,10
	  db	'(C) Copyright 1987 - 1992 The Software Link, Incorporated',13,10
	  db	'All Rights Reserved Worldwide',13,10
	  db	'$',8,' ',26

hlpmsg	db	13,10
	db	'enter:    MSYS A: to place a MOS boot sector on the disk in drive A             '  ;@@xlat
	db	13,10,'$'

badmedia db	0dh,0ah,'Unable to recognize disk type in drive            '  ;@@xlat
meddrv	db	'A',0dh,0ah,'$'

bad_mlg	db	13,10,'Old-style MOS large volumes must be converted to DOS               '
	db	13,10,'large volumes before MSYS can be used.               '
	db	13,10,'Use the INSTALL program or HDSETUP utility.             '
	db	0dh,0ah,'$'

error		db	0	; exit code returned to dos
tdrive		db	0	; drive being formatted, 0 = A:, 1 = B:...
dftdrv		db	0	; current drive when we started up
bootloc 	dw	0	; segment location of bootstrap segment
noname		db	'NO NAME    '	; default label string
m_option		db	0	; != 0 if /m switch is used (mlg->dlg)

mos_version	dw	?	; normalized to major/minor
dos_version	dw	?	; normalized to major/minor

; this var controls the calling interface used for int25 and int26 calls.
; 0 means use the dos large volume interface, supported by dos 4.00
; and greater and mos versions greater than or equal to 5.01.
; 1 means use the old interface method.  this would work for old
; mos large volumes as well as normal volumes under dos versions 
; before 4.0

; this flag also controls the adjustment of the dpb data returned 
; from i21f32.

call_method	db	0

; parameter buffer for int25 and int26 calls

control_packet	diskio	<>


;======================================================================
; a bios parameter block is constructed within this
; record from the dpb and then moved to the bootstrap code

;==== the following fields must stay together

dpb_bpb	bpb <512,2,1,2,112,720,0fdh,2,0>
ddrive		db	0	; this is the boot drive (normally 00h or 80h)

; this value is the length of the data area to copy into the actual
; boot sector.

bpblen		equ	$-dpb_bpb

; within the cmpbpb function, need the bpb length from bsBytesPerSec 
; through bsHiddenSecs

cmpbpblen 	equ	21

;==== the above fields must stay together


;======================================================================
; a bios parameter block is moved here after being read from
; the target drive.

boot_bpb bpb <512,2,1,2,112,720,0fdh,2,0>
bdrive		db	0	; this is the boot drive (normally 00h or 80h)

gi		dprec	<>	; for i21f44s0Dm60 in diskf8

mediatbl 	dw	diskf0	; f0 is 1.44m 3.5" diskette
		dw	7 dup(0); f1-f7 are invalid media descriptors
		dw	diskf8	; disk is a fixed disk
		dw	diskf9	; disk is a quad-density floppy or 720k
		dw	0	; fa an invalid media descriptor
		dw	0	; fb an invalid media descriptor
		dw	diskfc	; fc is a single-sided, 9-sectored floppy
		dw	diskfd	; fd is a double-sided, 9-sectored floppy
				;  or a double-sided, 26-sectored floppy
		dw	diskfe	; fe is a single-sided, 8-sectored floppy
				;  or a single-sided, 26-sectored floppy
				;  or a double-sided, 8-sectored floppy
		dw	diskff	; ff is a double-sided, 8-sectored floppy


lbl_fcb		db	0ffh		; extended fcb signature
		db	5 dup(0)
		db	8		; attribute for a label
		db	?		; drive number
		db	11 dup('?')	; wild-card for name and ext
		db	25 dup(0)


;======================================================================
; include common code and data for msys/format

	assume	ds:moss,es:nothing,ss:nothing
include fmcommon.inc

;======================================================================
;==== start of code
	assume	ds:moss,es:moss,ss:moss
msys:

; read the mos and dos version numbers

	mov	ax,3000h
	mov	bx,ax
	mov	cx,ax
	mov	dx,ax
	int	21h
	xchg	al,ah			; normalize major/minor
	mov	[mos_version],ax
	mov	ax,30ffh
	int	21h
	xchg	al,ah			; normalize major/minor
	mov	[dos_version],ax
	cmp	ax,[mos_version]	; if running under dos
	jne	msys010
	cmp	ax,0400h		; if dos_version < 4.x
	jnb	msys020
	mov	[call_method],1		; revert to the old method
	jmp	short msys020
msys010:				; else, running under mos
	mov	ax,[mos_version]
	cmp	ax,0501h		; if mos_version < 5.01
	jnb	msys020
	mov	[call_method],1		; revert to the old method
msys020:

; read current default drive

msys030:
	mov	ah,19h
	int	21h
	mov	[dftdrv],al

; derive paragraph offset of bootstrap segment

	mov	bx,cs
	add	bx,(endmoss-bgnmoss+15) shr 4
	mov	[bootloc],bx

; get any and all command line parameters

	call	parse
	ljnz	msys090

; if the /m option was specified (converting mlg->dlg), skip the 
; call to makebpb.  the dpb you would get would not be correct.

	cmp	[m_option],0
	jne	msys035

; construct bpb from target drive dpb

	call	makebpb
	ljnz	msys090

; read boot sector bpb from target drive

msys035:
	call	rd_boot
	ljnz	msys090

; at this point, the scan_partition function will be called for
; two reasons.  the first is to verify that the specified 
; partition is not an mlg partition.  the second reason is to 
; determine if the partition is on the first or second physical
; hard drive.  this information will be needed by the setboot
; function where it must initialize the bsDriveNumber field.

	mov	[drive_num],0
	mov	al,[tdrive]
	sub	al,2
	js	msys050
	call	scan_partitions
	jnc	msys040
	lea	dx,bad_scan
	mov	ah,9
	int	21h
	mov	[error],3
	jmp	msys090
msys040:
	mov	[drive_num],al		; save for the setboot function

; if mlg->dlg, skip logic which tests for an mlg partition.  

	cmp	[m_option],0
	jne	msys055
	or	bx,bx
	jz	msys050
	cmp	word ptr [bx].peSectors+2,0
	jz	msys050
	cmp	[bx].peFileSystem,PTCsm16
	jne	msys050
	mov	dx,offset bad_mlg
	mov	ah,9
	int	21h
	mov	[error],3
	jmp	msys090

; if the /m option was specified (converting mlg->dlg), no need to 
; compare the two bpbs since the dpb_bpb was never read.  just
; copy the data in boot_bpb to dpb_bpb.

msys050:

; compare the two bpb's.  if they are too different (cmpbpb returns ne)
; then the constructed dpb_bpb will be used.  otherwise, the bpb read
; from the boot sector will be used.

	call	cmpbpb
	jne	msys060			
msys055:
	lea	di,dpb_bpb
	lea	si,boot_bpb
	mov	cx,bpblen
	rep	movsb


; if the /m option was specified (converting mlg->dlg), skip the
; processing of the media id byte.

msys060:
	cmp	[m_option],0
	jne	msys085

; translate f0-ff media byte to 0-f and then convert that value
; into a call table index.

	mov	bl,[dpb_bpb.bsMedia]
	add	bl,10h
	cmp	bl,10h
	jae	msys070
	xor	bh,bh
	add	bx,bx
	mov	bx,[bx+mediatbl]
	or	bx,bx
	jnz	msys080

; error, couldn't recognize media descriptor byte

msys070:
	mov	al,[tdrive]
	add	al,'A'
	mov	[meddrv],al
	lea	dx,badmedia
	mov	ah,9
	int	21h
	mov	[error],3
	jmp	msys090

; call media specific bpb processing function

msys080:
	call	bx
	jnz	msys090
	mov	[ddrive],al
	jmp	short msys086
msys085:
	mov	[ddrive],80h		; for the msys/m case

; setup the data within the boot sector and then
; write the bootstrap code to the boot sector

msys086:
	call	setboot
	call	wr_boot

; exit to dos with error code (or 0)

msys090:
	mov	ah,4ch
	mov	al,[error]
	int	21h

	subttl parse - get command-line parameters
	page
;======================================================================
;,fs
; parse - get command-line parameters
;
; get command-line parameters
; only valid parameter is of the form '     x:      '
; where x is a upper or lower case drive letter recognizeable to dos,
; preceded by any number of chars <= spaces and the colon may be followed by
; any number of chars <= spaces
; reports anything else as an error, along with the copyright and usage msg
;   at the beginning of this code
;
; in:	ds -> moss segment (psp)
;
; out:	zr if ok
;	 [tdrive] holds drive number (0 based)
;	nz if error
;
;,fe
;======================================================================
	assume	ds:moss,es:moss,ss:moss
parse:
	mov	si,80h
	lodsb
	mov	cl,al
	xor	ch,ch
	jcxz	pars2
pars1:					; skip to first non-blank
	lodsb
	cmp	al,' '
	ja	pars3
	loop	pars1
pars2:	
	mov    al,'?'			; nothing specified is the same as ?
pars3:
	cmp	al,'?'
	jne	pars4
	lea	dx,hlpmsg
	mov	ah,9
	int	21h
	mov	[error],1
	or	al,0ffh
	ret
pars4:
	dec	si			; backup onto drive letter for error reporting
	cmp	cx,1			; drive requires a colon (must be >= 2 left)
	jz	parsx			; z if no more chars on command line (no colon)
	cmp	byte ptr [si+1],':'
	jne	parsx			; whatever it is, it isn't like we want
	call	caps
	sub	al,'A'
	mov	dl,al			; validate drive by setting it current
	mov	ah,0eh			; then reading the current drive and making
	int	21h
	mov	ah,19h			; sure we were successful in setting it
	int	21h
	mov	ah,dl
	push	ax
	mov	dl,[dftdrv]
	mov	ah,0eh
	int	21h
	pop	ax
	cmp	al,ah
	jne	parsy			; ne means we couldn't successfully set it
	mov	[tdrive],al
	inc	si			; move to char following colon
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
	call	checknet		; check to see if network drive
	jc	parsn
	xor	al,al
	ret				; no errors

; first non-blank encountered wasn't a drive specification (no colon)

parsx:
	call	string
	lea	dx,baddrv
	mov	ah,9
	int	21h
	lea	dx,hlpmsg
	mov	ah,9
	int	21h
	mov	[error],2
	or	al,0ffh
	ret

; drive specification was invalid

parsy:
	call	string
	lea	dx,invdrv
	mov	ah,9
	int	21h
	lea	dx,hlpmsg
	mov	ah,9
	int	21h
	mov	[error],2
	or	al,0ffh
	ret

; extra characters following a valid drive specification

parsz:
	cmp	byte ptr [si],'/'
	jne	parsz1
	cmp	byte ptr [si+1],'m'
	je	parsz2
	cmp	byte ptr [si+1],'M'
	jne	parsz1
parsz2:
	mov	[m_option],1
	add	si,2
	sub	cx,2
	jcxz	pars6
parsz3:
	cmp	byte ptr [si],' '
	ja	parsz1
	inc	si
	loop	parsz3
	jmp	short pars6
parsz1:
	call	string
	lea	dx,ignore
	mov	ah,9
	int	21h
	lea	dx,hlpmsg
	mov	ah,9
	int	21h
	mov	[error],2
	or	al,0ffh
	ret

; error out if network drive

parsn:
	mov	dl,0dh
	mov	ah,2
	int	21h
	mov	dl,0ah
	mov	ah,2
	int	21h
	mov	dl,"'"
	mov	ah,2
	int	21h
	mov	dl,[tdrive]
	add	dl,'A'
	mov	ah,2
	int	21h
	mov	dl,':'
	mov	ah,2
	int	21h
	mov	dl,"'"
	mov	ah,2
	int	21h
	lea	dx,inetdrv
	mov	ah,9
	int	21h
	lea	dx,hlpmsg
	mov	ah,9
	int	21h
	mov	[error],2
	or	al,0ffh
	ret

	subttl checknet - returns carry if network drive
	page
;======================================================================
;,fs
; checknet - returns carry if network drive
;
; in:	[tdrive] = drive number
;
; out:	cy if network drive
;
;,fe
;======================================================================
	assume	ds:moss,es:moss,ss:moss
checknet proc	near
	mov	bl,[tdrive]
	mov	ax,4409h
	int	21h
	test	dx,1000h
	jz	cnetok
	stc
	ret
cnetok:
	clc
	ret
checknet endp


baddrv	db	' is not a drive specification         ',0dh,0ah,'$'  ;@@xlat
invdrv	db	' is an invalid drive        ',0dh,0ah,'$'  ;@@xlat
inetdrv db	' is an network drive        ',13,10,'$'	;@@XLAT
ignore	db	' is extra ',0dh,0ah,'$';@@xlat

; display the command-line string from the position pointed to by si to the end

	subttl string - display string in quotes
	page
;======================================================================
;,fs
; string - display string in quotes
;
; in:	ds:si -> string
;	cx = number of bytes in string
;
; out:	
;
;,fe
;======================================================================
	assume	ds:moss,es:moss,ss:moss
string:
	mov	dl,0dh
	mov	ah,2
	int	21h
	mov	dl,0ah
	mov	ah,2
	int	21h
	mov	dl,"'"
	mov	ah,2
	int	21h
strin1:
	lodsb
	mov	dl,al
	mov	ah,2
	int	21h
	loop	strin1
	mov	dl,"'"
	mov	ah,2
	int	21h
	ret

	subttl caps - convert al to uppercase
	page
;======================================================================
;,fs
; caps - convert al to uppercase
;
; in:	al = char to convert
;
; out:	al = converted char
;
;,fe
;======================================================================
	assume	ds:moss,es:moss,ss:moss
caps:
	cmp	al,'a'
	jb	caps1
	cmp	al,'z'
	ja	caps1
	sub	al,'a'-'A'
caps1:
	ret

	subttl makebpb - construct bpb from dos dpb
	page
;======================================================================
;,fs
; makebpb - construct bpb from dos dpb
;
; do undocumented dos call to get disk parameter block
; translate that format to bios parameter block format
;   just because the bios parameter block can be obtained on ibm-formatted
;   disks from the boot sector, and maybe we'll want to use that protocol in
;   dingo, at least it's a documented protocol for device drivers and boot
;   sectors while the dpb format is not
;
; in:	dl = drive (0 = default)
;
; out:	
;
;,fe
;======================================================================
	assume	ds:moss,es:moss,ss:moss

bpberr	db	0dh,0ah,'Error reading disk parameters for drive             '	;@@xlat
bpbdrv	db	'A',0dh,0ah,'$'

; this dpb is for for DOS 4.x and newer and MOS 4.11 and newer.
; when an older OS is present, the data must be adjusted to match 
; this structure.  since mos 4.11 and newer will never report a dos version
; number before 4.0, testing the dos version number will be sufficient.

dpb_data dpbrec <>

makebpb:
	mov	dl,[tdrive]
	inc	dl
	mov	ah,32h
	int	21h
	assume	ds:nothing
	inc	al
	jnz	mkbpb1
	push	cs
	pop	ds
	mov	al,[tdrive]
	add	al,'A'
	mov	[bpbdrv],al
	lea	dx,bpberr
	mov	ah,9
	int	21h
	mov	[error],3
	or	al,0ffh
	ret
mkbpb1:

; copy the dpb data into a local buffer where it can be adjusted if
; necessary.

	assume	ds:nothing
	mov	cx,size dpbrec
	cld
	mov	si,bx
	mov	di,offset dpb_data
	mov	ax,cs
	mov	es,ax
	rep	movsb
	mov	ds,ax
	assume	ds:moss

; when [call_method] == 0, then we're either running on dos 4.00 or newer
; or mos 5.01 or newer.  therefore, if [call_method] == 1, we need
; to adjust the dpb data to match the newer structure definition.

	cmp	[call_method],0
	je	matched

; need to adjust

	mov	si,offset dpb_data.dpbFreeCnt
	mov	di,offset dpb_data.dpbFreeCnt+1
	std
	mov	cx,16
	rep	movsb
	cld
	mov	byte ptr [dpb_data.dpbFATSize+1],0
matched:

; sector size

	mov	ax,[dpb_data.dpbSectorSize]
	mov	[dpb_bpb.bsBytesPerSec],ax

; mask is sectors/cluster-1 (must be why sectors/cluster a power of 2)

	mov	al,[dpb_data.dpbClusterMask]
	inc	al
	mov	[dpb_bpb.bsSecPerClust],al

; number of reserved sectors same as start sector for first fat

	mov	ax,[dpb_data.dpbFirstFAT]
	mov	[dpb_bpb.bsResSectors],ax

; number of fat's

	mov	al,[dpb_data.dpbFATCount]
	mov	[dpb_bpb.bsFATs],al

; number of root directory entries

	mov	ax,[dpb_data.dpbRootEntries]
	mov	[dpb_bpb.bsRootDirEnts],ax

; convert clusters to sectors

	mov	ax,[dpb_data.dpbMaxCluster]
	dec	ax
	mov	cl,[dpb_bpb.bsSecPerClust]
	xor	ch,ch
	mul	cx
	add	ax,[dpb_data.dpbFirstSector]
	adc	dx,0
	jz	not_huge
	mov	[dpb_bpb.bsSectors],0
	mov	word ptr [dpb_bpb.bsHugeSectors],ax
	mov	word ptr [dpb_bpb.bsHugeSectors+2],dx
	jmp	short mkb1
not_huge:
	mov	[dpb_bpb.bsSectors],ax
	mov	word ptr [dpb_bpb.bsHugeSectors],0
	mov	word ptr [dpb_bpb.bsHugeSectors+2],0

; media desriptor byte

mkb1:
	mov	al,[dpb_data.dpbMedia]
	mov	[dpb_bpb.bsMedia],al

; file allocation table size in sectors

	mov	ax,[dpb_data.dpbFATSize]
	mov	[dpb_bpb.bsFATsecs],ax

; all done

	xor	al,al
	ret

	subttl rd_boot - read boot sector bpb from target drive
	page
;======================================================================
;,fs
; rd_boot - read boot sector bpb from target drive
;
; in:
;
; out:	zr if no error, else nz
;
;,fe
;======================================================================
	assume	ds:moss,es:moss,ss:moss

rderr	db	0dh,0ah,'Error reading boot sector from drive           '  ;@@xlat
rddrv	db	'A',0dh,0ah,'$'

; sector read past bootstrap segment, then bpb copied into boot_bpb

rd_boot:
	mov	al,[tdrive]
	push	ds

; if the call_method flag == 0, use the control packet calling method.
; this is for post 4.10 mos and dos 4.0 and greater.

	cmp	[call_method],0
	je	i25dlg
	mov	ds,[bootloc]		; segment location of bootstrap
	assume	ds:nothing
	lea	bx,bootbuf
	mov	cx,1			; reading 1 sector
	mov	dx,0			; starting at logical sector 0
	push	di			; save out value used for int 25h call
	push	si			;  "    "    "    "    "   "   "   "
	mov	si,0			; high word of sector
	mov	di,0fffch		; flag set to show int 25h that it is to use
					; si as the high wrd of sector
	int	25h			; call it
	pop	cx			; throw away flags
	pop	si			; restore the saved values
	pop	di
	jmp	short i25x
i25dlg:
	assume	ds:moss
	mov	bx,offset control_packet
	mov	word ptr [bx].diStartSector,0
	mov	word ptr [bx].diStartSector+2,0
	mov	word ptr [bx].diSectors,1	; 
	mov	word ptr [bx].diBuffer,offset bootbuf
	mov	cx,[bootloc]
	mov	word ptr [bx].diBuffer+2,cx
	mov	cx,-1
	int	25h
	pop	cx			; throw away flags
i25x:
	jnc	rdbpb1

; error handling

	pop	ds			; some error reading boot sector
	mov	cl,[tdrive]
	add	cl,'A'
	mov	[rddrv],cl
	lea	dx,rderr
	mov	ah,9
	int	21h
	mov	[error],3
	or	al,0ffh
	ret
rdbpb1:
	mov	ds,[bootloc]		; segment location of bootstrap
	assume	ds:nothing
	lea	si,bootbuf+11		; all we really wanted was the bpb
	lea	di,boot_bpb
	mov	cx,bpblen
	rep	movsb
	pop	ds
	assume	ds:moss
	xor	al,al
	ret

	subttl cmpbpb - compare boot sector bpb with constructed bpb
	page
;======================================================================
;,fs
; cmpbpb - compare boot sector bpb with constructed bpb
;
; if no difference, or
;   the only difference is the total sectors, and the boot total
;   sectors is less than the constructed total sectors + the cluster
;   size, then return z (zero flag set)
; else return nz
;
; in:	
;
; out:	zr if no significant difference, else nz
;
;,fe
;======================================================================
	assume	ds:moss,es:moss,ss:moss
cmpbpb:
	push	[boot_bpb.bsSectors]
	mov	ax,[dpb_bpb.bsSectors]
	mov	[boot_bpb.bsSectors],ax
	mov	si,offset boot_bpb
	mov	di,offset dpb_bpb
	mov	cx,cmpbpblen
	repe	cmpsb
	pop	[boot_bpb.bsSectors]
	ret

	subttl diskf8 - determine sector/track, etc. for media f8 (hard disk)
	page
;======================================================================
;,fs
; diskf8 - determine sector/track, etc. for media f8 (hard disk)
;
; this is a fixed disk, get information from generic i/o ctl
;
; in:	
;
; out:	zr if no error
;	 al = value for [ddrive]
;	nz if error
;
;,fe
;======================================================================
	assume	ds:moss,es:moss,ss:moss

fixeder db	0dh,0ah,'Error reading fixed disk parameters       ',0dh,0ah,'$'  ;@@xlat

diskf8:
	mov	ax,440dh		; generic ioctl call
	mov	bl,[tdrive]		; target drive
	inc	bl			; (0 means default drivve to ioctl)
	mov	cx,0860h		; get device parameters
	lea	dx,gi.dpSpecFunc	; parameter block for call
	int	21h
	jc	diskf8x 		; if can't get parameters
	mov	dx,[gi.dpHeads]		; number of heads
	mov	[dpb_bpb.bsHeads],dx
	mov	cx,[gi.dpSecPerTrack]	; sectors per track
	mov	[dpb_bpb.bsSecPerTrack],cx
	mov	ax,word ptr [gi.dpHiddenSecs]
	mov	cx,word ptr [gi.dpHiddenSecs+2] ; hidden sectors
	mov	word ptr [dpb_bpb.bsHiddenSecs],ax
	mov	word ptr [dpb_bpb.bsHiddenSecs+2],cx

; update the sector counts.  makebpb already set these based on a
; derivation with total clusters, spc and sector # of first data cluster,
; but this isn't always accurate on a hard disk.

	mov	ax,[gi.dpSectors]
	mov	[dpb_bpb.bsSectors],ax
	mov	ax,word ptr [gi.dpHugeSectors]
	mov	word ptr [dpb_bpb.bsHugeSectors],ax
	mov	ax,word ptr [gi.dpHugeSectors+2]
	mov	word ptr [dpb_bpb.bsHugeSectors+2],ax
	mov	al,80h			; drive 80h (can only boot first fixed disk)
	cmp	al,al			; no error
	ret
diskf8x:

; error handler

	lea	dx,fixeder
	mov	ah,9
	int	21h
	or	al,0ffh 		; can't get disk information from int 13
	ret

	subttl diskf0 - determine sector/track, etc. for media f0
	page
;======================================================================
;,fs
; diskf0 - determine sector/track, etc. for media f0
;
; this is a double-sided, 18-sectored 3.5" floppy
;
; in:	
;
; out:	zr if no error
;	 al = value for [ddrive]
;	nz if error
;
;,fe
;======================================================================
	assume	ds:moss,es:moss,ss:moss
diskf0:
	mov	[dpb_bpb.bsHeads],2
	mov	[dpb_bpb.bsSecPerTrack],18
	mov	word ptr [dpb_bpb.bsHiddenSecs],0
	mov	word ptr [dpb_bpb.bsHiddenSecs+2],0
	xor	al,al			; drive 0 and no error
	ret

	subttl diskf9 - determine sector/track, etc. for media f9
	page
;======================================================================
;,fs
; diskf9 - determine sector/track, etc. for media f9
;
; this is a double-sided, quad-density 5 1/4" floppy
;  or a 720k 3.5" diskette
;
; in:	
;
; out:	zr if no error
;	 al = value for [ddrive]
;	nz if error
;
;,fe
;======================================================================
	assume	ds:moss,es:moss,ss:moss
diskf9:

	mov	[dpb_bpb.bsHeads],2
	mov	[dpb_bpb.bsSecPerTrack],15
	mov	word ptr [dpb_bpb.bsHiddenSecs],0
	mov	word ptr [dpb_bpb.bsHiddenSecs+2],0
	mov	ax,0201h		; read 1 sector
	mov	dl,[tdrive]		; drive is target drive
	mov	dh,0			; head 0
	mov	ch,0			; track 0
	mov	cl,14			; sector 14
	lea	bx,bootbuf
	push	es
	mov	es,[bootloc]
	int	13h
	pop	es
	jnc	dskf91			

; if we can't read sector 14, assume 9 sectors per track

	mov	[dpb_bpb.bsSecPerTrack],9
dskf91:
	xor	al,al			; drive 0 and no error
	ret

	subttl diskfc - determine sector/track, etc. for media fc
	page
;======================================================================
;,fs
; diskfc - determine sector/track, etc. for media fc
;
; this is a single-sided, 9-sectored 5 1/4" floppy
;
; in:	
;
; out:	zr if no error
;	 al = value for [ddrive]
;	nz if error
;
;,fe
;======================================================================
	assume	ds:moss,es:moss,ss:moss
diskfc:
	mov	[dpb_bpb.bsHeads],1
	mov	[dpb_bpb.bsSecPerTrack],9
	mov	word ptr [dpb_bpb.bsHiddenSecs],0
	mov	word ptr [dpb_bpb.bsHiddenSecs+2],0
	xor	al,al			; drive 0 and no error
	ret

	subttl diskfd - determine sector/track, etc. for media fd
	page
;======================================================================
;,fs
; diskfd - determine sector/track, etc. for media fd
;
; this is a double-sided, 9-sectored 5 1/4" floppy
; or it is a double-sided 26-sectored 8" floppy
;
; in:	
;
; out:	zr if no error
;	 al = value for [ddrive]
;	nz if error
;
;,fe
;======================================================================
	assume	ds:moss,es:moss,ss:moss
diskfd:
	mov	[dpb_bpb.bsHeads],2
	mov	[dpb_bpb.bsSecPerTrack],9
	mov	word ptr [dpb_bpb.bsHiddenSecs],0
	mov	word ptr [dpb_bpb.bsHiddenSecs+2],0
	mov	ax,0201h		; read 1 sector
	mov	dl,[tdrive]		; drive is target drive
	mov	dh,0			; head 0
	mov	ch,0			; track 0
	mov	cl,25			; sector 25 (maybe it starts with 0)
	lea	bx,bootbuf
	push	es
	mov	es,[bootloc]
	int	13h
	pop	es
	jc	dskfd1

; since we can read sector 25, assume 26 sectors per track

	mov	[dpb_bpb.bsSecPerTrack],26
dskfd1:
	xor	al,al			; drive 0 and no error
	ret

	subttl diskfe - determine sector/track, etc. for media fe
	page
;======================================================================
;,fs
; diskfe - determine sector/track, etc. for media fe
;
; this is a single-sided, 8-sectored 5 1/4" floppy
; or it is a single-sided, 26-sectored 8" floppy
; or it is a double-sided, 8-sectored 8" floppy
;
; in:	
;
; out:	zr if no error
;	 al = value for [ddrive]
;	nz if error
;
;,fe
;======================================================================
	assume	ds:moss,es:moss,ss:moss
diskfe:
	mov	[dpb_bpb.bsHeads],1
	mov	[dpb_bpb.bsSecPerTrack],26
	mov	word ptr [dpb_bpb.bsHiddenSecs],0
	mov	word ptr [dpb_bpb.bsHiddenSecs+2],0

; try reading sector 25

	mov	ax,0201h		; read 1 sector
	mov	dl,[tdrive]		; drive is target drive
	mov	dh,0			; head 0
	mov	ch,0			; track 0
	mov	cl,25			; sector 25 (maybe it starts with 0)
	lea	bx,bootbuf
	push	es
	mov	es,[bootloc]
	int	13h
	pop	es
	jnc	dskfe1

; is 8-sectored, try reading second head

	mov	[dpb_bpb.bsSecPerTrack],8
	mov	ax,0201h
	mov	dl,[tdrive]
	mov	dh,1			; head 1
	mov	ch,0			; track 0
	mov	cl,1			; sector 1
	lea	bx,bootbuf
	push	es
	mov	es,[bootloc]
	int	13h
	pop	es
	jc	dskfe1
	mov	[dpb_bpb.bsHeads],2
dskfe1:
	xor	al,al			;drive 0 and no error
	ret

	subttl diskff - determine sector/track, etc. for media ff
	page
;======================================================================
;,fs
; diskff - determine sector/track, etc. for media ff
;
; this is a double-sided, 8-sectored 5 1/4" floppy
;
; in:	
;
; out:	zr if no error
;	 al = value for [ddrive]
;	nz if error
;
;,fe
;======================================================================
	assume	ds:moss,es:moss,ss:moss
diskff:
	mov	[dpb_bpb.bsHeads],2
	mov	[dpb_bpb.bsSecPerTrack],8
	mov	word ptr [dpb_bpb.bsHiddenSecs],0
	mov	word ptr [dpb_bpb.bsHiddenSecs+2],0
	xor	al,al			;drive 0 and no error
	ret

	subttl setboot - set-up for bootstrap data
	page
;======================================================================
;,fs
; getvollbl - see if a drive has a volume label
;
; expects the dta to still be set to the default area within the psp
;
; int24 is temporarily changed since msys will often be used on
; unformatted partitions.
;
; in:	dl = drive number (0=a, 1=b ...)
;
; out:	ds:si -> label name buffer (8+3 bytes long)
;		(buffer is filled with 'NO NAME   ' if no label exists)
;
;,fe
;======================================================================
	assume	ds:moss,es:moss,ss:moss

fail24:
	mov	al,3
	iret


getvollbl:
	cmp	[m_option],0
	je	gtv2
	mov	si,offset noname
	push	cs
	pop	ds
	ret
gtv2:
	pushset	ax,bx,cx,dx,di,es
	mov	ax,cs
	mov	ds,ax
	mov	es,ax
	mov	di,offset lbl_fcb
	cld
	inc	dl
	mov	es:[di].extDriveID,dl
	mov	ax,3300h		; get current break flag
	int	21h
	push	dx
	mov	ax,3301h		; insure break checking is off
	mov	dl,0
	int	21h
	mov	ax,3524h		; save current int24 handler
	int	21h
	push	bx
	push	es
	mov	ax,2524h		; set fail handler
	mov	dx,offset fail24
	int	21h
	mov	ax,cs
	mov	es,ax
	mov	dx,offset lbl_fcb
	mov	ah,11h			; old search for first call
	int	21h
	push	ax
	mov	ah,2fh			; find the current dta
	int	21h
	mov	di,bx
	add	di,8			; point to start of name field
	pop	ax
	or	al,al
	jz	gtv1

; if an error from i21f11, copy in 'NO NAME   '

	push	di
	mov	si,offset noname
	mov	cx,8+3
	rep	movsb
	pop	di
gtv1:
	pop	ds			; pushed as es:bx
	pop	dx
	mov	ax,2524h		; restore int24 vector
	int	21h
	mov	ax,3301h		; restore break checking state
	pop	dx
	int	21h
	mov	si,di			; return with ds:si pointing
	mov	ax,es			; to the label name within the
	mov	ds,ax			; dta
	popset	ax,bx,cx,dx,di,es
	ret

	subttl setboot - set-up for bootstrap data
	page
;======================================================================
;,fs
; setboot - set-up for bootstrap data
;
; in:	
;
; out:	
;
;,fe
;======================================================================
	assume	ds:moss,es:moss,ss:moss
setboot:
	mov	es,[bootloc]		; put bpb, etc into bootstrap sector
	assume	es:bootstrap
	mov	di,offset bs_bpb	; bootstrap bpb location
	mov	si,offset dpb_bpb
	mov	cx,bpblen
	rep	movsb
	push	es
	pop	ds
	assume	ds:bootstrap

; if mlg->dlg, read the old data using the mlgrec structure
; and write the new data back to the same buffer using 
; the bpb structure

	cmp	[m_option],0
	je	sbt5
	mov	ax,[bs_bpb].mlSectors
	mov	dl,[bs_bpb].mlSectorsHi
	xor	dh,dh
	push	ax
	push	dx
	mov	al,[bs_bpb].mlFATsecs
	xor	ah,ah
	push	ax
	mov	ax,[bs_bpb].mlHiddenSecs
	mov	dl,[bs_bpb].mlHiddenHi
	xor	dh,dh
	mov	word ptr [bs_bpb].bsHiddenSecs,ax
	mov	word ptr [bs_bpb].bsHiddenSecs+2,dx
	pop	ax
	mov	[bs_bpb].bsFATsecs,ax
	pop	dx
	pop	ax
	mov	word ptr [bs_bpb].bsHugeSectors,ax
	mov	word ptr [bs_bpb].bsHugeSectors+2,dx
	mov	word ptr [bs_bpb].bsSectors,0
sbt5:
	mov	al,[bs_bpb].bsFATs
	xor	ah,ah
	mul	[bs_bpb].bsFATsecs
	add	ax,[bs_bpb].bsResSectors ; ax = sector address of root directory

; dx should be 0 at this point

	mov	[dirsct],ax
	mov	ax,[bs_bpb].bsRootDirEnts ; computing sector address of start of data
	mov	cx,32			; each directory entry is 32 bytes long
	mul	cx			; dx:ax = length in bytes of directory
	mov	cx,[bs_bpb].bsBytesPerSec
	dec	cx
	add	ax,cx			; + sctsiz - 1
	adc	dx,0

; ax = number of sectors in root directory
; add to sector address of dir start
;  gives sector address of data cluster 2
;  (by definition, clusters >= 2)

	div	[bs_bpb].bsBytesPerSec
	add	ax,[dirsct]
	mov	[cdata],ax

; get total sectors in dx:ax

	xor	dx,dx
	mov	ax,[bs_bpb].bsSectors
	or	ax,ax
	jnz	sbt1
	mov	ax,word ptr [bs_bpb].bsHugeSectors
	mov	dx,word ptr [bs_bpb].bsHugeSectors+2
sbt1:

; subtract sector address of cluster 0 to derive the total number 
; of data sectors

	sub	ax,[cdata]
	sbb	dx,0

; divide total data clusters by sectors per cluster to get 
; total data clusters

	mov	cl,[bs_bpb].bsSecPerClust
	xor	ch,ch
	div	cx
	mov	[bigfat],true
	cmp	ax,4096-10		; 0-fff excluding 0,1,ff8-fff
	ja	sbt2
	mov	[bigfat],false		; note, if 16-bit not necessary, then we
					;  assume it's 12-bit
sbt2:
	mov	ax,512			; bootstrap is 512-bytes long
	add	ax,[bs_bpb].bsBytesPerSec
	add	ax,[bs_bpb].bsBytesPerSec
	mov	[endbf2],ax
	add	ax,256
	mov	[endboot],ax
	mov	cl,4
	shr	ax,cl
	neg	ax
	add	ax,minmem
	mov	[locboot],ax		; location to relocate bootstrap
	mov	cl,-1
	mov	ax,[bs_bpb].bsBytesPerSec
sbt3: 
	inc	cl
	shr	ax,1
	jnz	sbt3
	mov	[sctshft],cl

; set the bsDriveNumber field.  the drive_num variable, declared
; within this file, is set by the scan_partitions function.

	mov	al,[drive_num]
	mov	[bs_bpb].bsDriveNumber,al

; set next two fields

	mov	[bs_bpb].bsReserved1,0
	mov	[bs_bpb].bsBootSignature,29h

; use time and date values to set bsVolumID

	mov	ah,2ah
	int	21h
	push	dx
	mov	ah,2ch
	int	21h
	pop	ax
	mov	word ptr [bs_bpb].bsVolumeID,ax
	mov	word ptr [bs_bpb].bsVolumeID+2,dx

; set the bsVolumeLabel field

	mov	dl,[tdrive]
	push	ds
	call	getvollbl
	assume	ds:nothing
	mov	di,offset bs_bpb.bsVolumeLabel
	mov	cx,8+3
	cld
	rep	movsb

; init the bsFileSysType field

	mov	ax,cs
	mov	ds,ax
	mov	si,offset fattype16
	mov	di,offset bs_bpb.bsFileSysType
	mov	cx,8/2
	rep	movsw
	pop	ds
	assume	ds:bootstrap
	mov	ax,[bs_bpb].bsSectors
	or	ax,ax			; must be 16 bit fat
	jz	sbt4			; when bsHugeSectors is used
	cmp	ax,20740
	ja	sbt4
	mov	byte ptr [bs_bpb].bsFileSysType+4,'2'
sbt4:
	mov	ax,cs
	mov	ds,ax
	mov	es,ax
	ret

	subttl wr_boot - write mos bootstrap sector to target drive
	page
;======================================================================
;,fs
; 
;
; in:	
;
; out:	zr if no error, else nz
;
;,fe
;======================================================================
	assume	ds:moss,es:moss,ss:moss

wrerr	db	0dh,0ah,'Error writing boot sector to drive                 '  ;@@xlat
wrdrv	db	'A',0dh,0ah,'$'

wr_boot:
	mov	al,[tdrive]

; if the call_method flag == 0, use the control packet calling method.
; this is for post 4.10 mos and dos 4.0 and greater.

	cmp	[call_method],0
	je	i26dlg
	push	ds
	assume	ds:nothing
	mov	ds,[bootloc]		; segment location of bootstrap
	mov	bx,0			; offset of bootstrap code
	mov	cx,1			; writing 1 sector
	mov	dx,0			; starting at logical sector 0
	push	di			; save out value used for int 26h call
	push	si			;  "    "    "    "    "   "   "   "
	mov	si,0			; high word of sector
	mov	di,0fffch		; flag set to show int 26h that it is to use
					; si as the high wrd of sector
	int	26h			; call it
	pop	cx			; throw away flags
	pop	si			; restore the saved values
	pop	di
	pop	ds
	assume	ds:moss
	jmp	i26x
i26dlg:
	mov	bx,offset control_packet
	mov	word ptr [bx].diStartSector,0
	mov	word ptr [bx].diStartSector+2,0
	mov	word ptr [bx].diSectors,1	; 
	mov	word ptr [bx].diBuffer,0
	mov	cx,[bootloc]
	mov	word ptr [bx].diBuffer+2,cx
	mov	cx,-1
	int	26h
	pop	cx			; throw away flags
i26x:
	jc	wrbpb1
	mov	ah,0dh			; flush disk buffers
	int	21h
	xor	al,al
	ret
wrbpb1:
	mov	cl,[tdrive]		; some error writing boot sector
	add	cl,'A'
	mov	[wrdrv],cl
	lea	dx,wrerr
	mov	ah,9
	int	21h
	mov	[error],3
	or	al,0ffh
	ret


endmoss label	byte

moss	ends

	subttl boot sector
	page

bootstrap segment para
	include mboot.inc
bootstrap ends

	end	start

