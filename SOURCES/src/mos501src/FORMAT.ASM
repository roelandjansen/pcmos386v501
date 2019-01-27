	include page.inc
	title format.asm - the mos format command
comment ^===============================================================
		     development specification

 program name:	format.com		   assigned to: jsw
 module name:	format			   assign date: 03/31/86
 entry points:	100h			   completed:   11/25/86
 entry from:	command processor
 entry method:	exec
 purpose:	format a disk
 refer to:	n/a
 last update:	06/15/92

 command format: format [d:] [/1] [/8] [/v] [/4]

=======================================================================

jsm 04/23/87	fix booted for large volumes

rbr 05/12/87	message cleanup

jsm 05/19/87	more message cleanup, set scyl correctly

rbr 07/17/87	support 3.5" diskettes

jsw 10/26/87	extended track layout table to support 34 sectors/track
		correction to shrink proc.

rbr 01-27-88	extended track layout table to support 63 sectors/track.

rbr 02-07-88	corrected problem with using incorrect default parameters
		for 720k drives.

sah 03/14/88	corrected formating of 16 bit fats primary for core 260m
		drive. totally rewrote the logic for 16 bit putfat
		routine.  misc cosmetics.

sah 03/22/88	added logic to detect if disk has write protect on it

jrb 05/02/88	call int 38h to flush & invalidate cache drive before
		formatting it

rbr 07/05/88	fix incorrect fat bytes 1-3.

sah 07/20/88	corrected problem with multible formats also cleaned up
		module

rkg 10/20/88	changed key input to flush buffer ptr133

rkg 10/25/88	modified (y/n) for translations

rkg 11/03/88	changed messages for easier translation

rkg 12/05/88	fixed incorrect decrment of bad_sec_cnt caused probs when
		initial sectors bad

rkg 12/08/88	changed error handling for infinite loop
k
sah 02/20/89	converted int 38 into int services

rkg 06/07/89	corrected boot record variables so no msys required and
		general cleanup.

rkg 06/14/89	changed "jmp its_set+12"  ensured es => boot_seg on
		retry.

rkg 07/07/89	hiddenh was not set in boot record

bwr 11/27/89	messages marked for foreign language translation.

sah 03/20/90	corrections for 4.10 formatting.

bwr 07/10/90	added new option '/Y' to allow acu.exe to specify hard
		drive format without being prompted.  this option should
		remain undocumented and for internal use only.

bwr 07/25/90	output messages are now sent through dos function 9 (print
		string) instead of being output a character at a time
		through function 6 (direct console).

mjs 12/16/91	dlg mods: complete overhaul.  removed mos large partition
		support and added support for dos large partitions.  made
		this tool build an extended partition boot record.  must
		see a dos version number of 4.0 or newer.  checks to see if
		it is running under dos or mos to know how to flush the
		disk buffers or cache.  

mjs 03/03/92	made sure errorlevel 0 is returned when there is no error.

SAH 03/09/92	check for true dos version using 3306h

SAH 03/20/92	Corrections for Formatting on 1.4G harddisk

mjs 06/15/92	prevent this util from running under dos.  if someone
		formats a secondary partition under d5 using m5's format,
		the partition table can be overwritten.

======================================================================^

	include options.inc
	include format.pub
	include mboot.pub
	include dskstruc.inc
	include macros.inc

true	equ	0ffffh			; true
false	equ	0

grp	group	moss,bootstrap

moss	segment word public 'code'
	assume	cs:grp,ds:grp,es:grp,ss:grp
	org	2
memtop	dw	?			; last segment we can use
	org	100h
start:
	jmp	begin
	db	3 dup (8), 3 dup (' '),13
	
copyright db	'FORMAT - Version 5.01',13,10
	  db	'(C) Copyright 1987 - 1992 The Software Link, Incorporated',13,10
	  db	'All Rights Reserved Worldwide',13,10
	  db	'$',8,' ',26




	even

;==== global word vars, in alphabetical order

bad_clusters	dw	0	; bad cluster counter
boot_seg 	dw	0	; will contain segment address of bootseg
carry		dw	false	; flags overflow of bad cluster onto new track
cluspt		dw	0	; format loop counter, clusters per track
clustervalue	dw	0	; cluster value for fat
curcn		dw	0	; current cluster number
cylds		dw	80	; # of cylinders (1.2m)
dals		dw	0	; data area logical sector
dir_ofs 	dw	0	; tracks offset for directory building
dir_seg 	dw	0	; tracks segment for directory building
dirent		dw	224	; # of root directory entries
dirsects 	dw	14	; # of sectors for root directory (1.2m)
dos_version	dw	?	; dos version number
fatbuf_seg	dw	0	; seg of buffer where fats are built
heads		dw	02h	; counter for # of heads, for format loop
hiddn		dw	2 dup(0); # of hidden sectors
lsn		dw	0,0	; counter for logical sector number.
mos_version	dw	?	; mos specific version number
ovflow_flag	dw	0	; flags overflow of bad cluster onto new track
retry		dw	5	; retry counter
scyl		dw	0	; starting cylinder for format loop
shead		dw	0	; starting head for format loop
spc		dw	01h	; sectors/cluster (1.2m)
spcshf		dw	?	; right shift factor for sector -> cluster
spt		dw	0fh	; sectors/track (1.2m)
spf		dw	7	; # of sectors per fat (1.2m)
tot_data_sct	dw	?,?	; total sectors used for clusters
w10000		dw	10000	; for bin2dec
w10		dw	10	; for bin2dec
wordtwo 	dw	2	; set to two, to simplify division

;==== global byte vars, in alphabetical order

bad_typ 	db	0	; used to count retrys of using ioctl format code
curdrv		db	'C'	; current drive
drvchar 	db	'A'	; default drive letter
drvnum		db	1	; drive number 1-a, 2-b
fat_lead	db	0,0,0,0	; fat type and length entries
fattype 	db	12	; # of bits per hard disk fat entry
hard		db	0	; set to true for a hard disk
is_mos		db	0	; flags when mos is the host os
opcode		db	42h	; opcode byte for format/verify operation
parmf		db	00h	; flag byte to represent the command line (see below)
wrd_flag	db	0	; indicates whether or not ax has 2 bytes.
write_prot	db	'N'	; disk write protected
				; will cause findparm to locate a second byte.

;===========================================================================
;  the "parmf" byte represents options set on the command line.
;
;	bit 0 = '/1' option issued.
;	bit 1 = '/4' and /7
;	bit 2 = '/8'
;	bit 3 = '/S'
;	bit 4 = '/V'
;	bit 5 = '/Y'	format hard drive, bypass warning. (acu)
;	bit 6-7 	unused.
;
;===========================================================================

; allowable dt values are as follow: 0 - 320/360k 5.25 inch drive
; 1 - 5.25" 1.2m   2 - 3.50" 720k drive   3 - 8" single density
; 4 - 8" double density   5 - fixed disk   6 - tape drive   7 - other
; we will allow only 0 - 2 and 5

;==== ioctl records

;==================== the following declarations must stay together

odevp		dprec	<>		; use the defaults
		dw	64*2 dup(0)	; track table for odevp

ndevp		dprec	<>		; new devp parm block
		dw	64*2 dup(0)	; track table for ndevp

;==================== the above declarations must stay together

fp1		fvblock	<>		; format packet
rwp		rwrec	<>		; read/write packet

;==== messages

nonetdr db	'Cannot FORMAT a network drive!               ',13,10,'$'  ;@@xlat
dnr	db	'Drive not ready!        ',13,10,'$'  ;@@xlat
drf	db	'Drive failed to respond!         ',0dh,0ah,24h  ;@@xlat
err	db	'Format failed!              ',13,10,'$'  ;@@xlat
invldrv db	'Invalid drive specification!',13,10,'$'  ;@@xlat
se	db	'Syntax error! ',13,10,'$'  ;@@xlat
icprm	db	'Incompatible parameters ',13,10,'$'  ;@@xlat
nodrvlt db	'No drive letter specified!    ',13,10,'$'  ;@@xlat
bprms	db	'Invalid parameters for specified drive!      ',13,10,'$'  ;@@xlat
fok	db	'Format complete.',13,10,'$'  ;@@xlat
totsec	db	'              bytes available on disk.                  ',13,10,'$'  ;@@xlat
totbad	db	'              bytes in bad sectors.        ',13,10,'$'  ;@@xlat
totrem	db	'              bytes free.         ',13,10,'$'  ;@@xlat
writerr	db	'Disk write error         ',13,10,'$'  ;@@xlat
nomem	db	'Formatting this disk requires           '  ;@@xlat
memnd	db	'000000 more bytes of free memory.  ',13,10,'$'  ;@@xlat
baddisk db	'The media is invalid or Track 0 is bad! -  '  ;@@xlat
	db	'The disk is unusable!                 ',13,10,'$'  ;@@xlat
protmsg db	'Cannot format a WRITE - PROTECTED disk! -  '  ;@@xlat
	db	'Please check disk and try again.      ',13,10,'$'  ;@@xlat
blanks	db	'                       ',13,'$'
crlf	db	13,10,'$'
percnt	db	'  0 Percent Complete   ',13,'$'  ;@@xlat
prct	db	255			; last percentage value
cntrlc	db	'^C',13,10,'$'
yesmsg	db	'Yes   '		;@@xlat
nomsg	db	'No    '		;@@xlat
weird_type db	'Unknown device type - cannot FORMAT!           ',13,10,'$'  ;@@xlat
too_old	db	13,10,'Improper MOS version!                ',13,10,'$'  ;@@xlat

;==== prompts

instd	db	13,10,'Insert diskette in drive  '  ;@@xlat
vd	db	'?:',13,10, 'Press RETURN to continue.      ',13,10,'$'  ;@@xlat
warng	db	13,10,'***** WARNING *****',13,10  ;@@xlat
	db	'Formatting non-removable drive '  ;@@xlat
whd	db	'?: will erase all of its data!          ',13,10,'$'  ;@@xlat
go	db	'Do you wish to format (Y/N)? $          '  ;@@xlat
more	db	'Try again (Y/N) ? $       '  ;@@xlat
another db	13,10,'Format another (Y/N)? $      '  ;@@xlat
volprompt db	'Enter label (11 character max or ENTER for none): $        '  ;@@xlat

;==== tables

charstb db	'"','+',',','.','/',':',';','<','=','>','[','\',']','|'
tab_len db	$-charstb		; length of table

vol_lbl		db	'           '


;======================================================================
; include common code and data for msys/format

	assume	ds:grp,es:nothing,ss:nothing
include fmcommon.inc


;========================================================
;==== start of code
	assume	ds:grp,es:grp,ss:grp
begin:
	mov	sp,offset grp:stktop

; read the mos and dos version numbers

	mov	ax,3000h
	mov	bx,ax
	mov	cx,ax
	mov	dx,ax
	int	21h
	mov	[mos_version],ax
	mov	ax,30ffh
	int	21h
	mov	[dos_version],ax

; use the dos version number to verify that this tool can run.
; this way, this format.com can run under dos 4.x or newer and
; under any version of mos which represents a dos version number
; of 4.x or newer.

	cmp	al,4
	jnb	main010
;
; if dos version is less than 4.0, we must check true dos version
; using INT 21h function 3306
;
	xor	bx,bx
	mov	ax,3306h
	int	21h
	cmp	bl,5
	jne	main05
	mov	ax,bx	
	jmp	short main010
main05:
;
	mov	dx,offset grp:too_old
	call	print
	mov	ax,4c01h
	int	21h
main010:

; still need to know if we're running under dos or mos -- for the
; sake of the cache flush/disk reset call which must be done.

	cmp	ax,[mos_version]
	je	main020
	mov	[is_mos],true
main020:

; for release, not safe to let m5 format run under dos.  if someone
; tries to format a secondary partition under dos, can trash disk.
; if want to run format under dos for testing purposes, 
; change the following line to "if 0 eq 01".

if 0 eq 0
	cmp	[is_mos],true
	jne	main05
endif

; calculate the segment address of bootstrap

	mov	ax,cs
	mov	bx,offset grp:boot
	mov	cl,4
	shr	bx,cl
	add	ax,bx
	mov	[boot_seg],ax		; address in es

;========================================================
;==== parse the command line

	mov	bx,80h			; address command line to get parms
	xor	ch,ch
	mov	cl,byte ptr [bx]	; get number of chars entered.
	cmp	cx,3
	jge	main030			; >= 3 so process drive id

; if # of chars < 3 error

	mov	dx,offset grp:nodrvlt
	mov	al,1			; undefined exit code by dos
	jmp	done1_print
main030:
	inc	bx			; point bx to 1st parm
	call	findnonblnk		; find the 1st non-blank
	jnc	main040			; no carry see if its a drive id
	mov	dx,offset grp:nodrvlt
	mov	al,1			; undefined exit code by dos
	jmp	done1_print
main040:
	mov	al,[bx]			; get the drive letter
	and	al,0dfh			; make it upper case
	cmp	al,'A'			; see if its really a drive letter
	jb	main050			; nope they forgot to tell me
	cmp	al,'Z'
	ja	main050			; format drives a-z only.
	cmp	byte ptr [bx+1],':'
	je	main060
main050:
	mov	dx,offset grp:invldrv
	mov	al,1			; undefined exit code by dos
	jmp	done1_print
main060:
	mov	[drvchar],al		; save validated device character
	inc	bx
	inc	bx			; put bx past the ':'
	mov	di,bx			; put it in di for findparm call
	mov	si,offset grp:ndevp		; let si address new device parms
	xor	ax,ax			; clear ax also
main070:
	mov	al,'/'			; look for the parms
	call	findparm
	jnc	main080
	cmp	cx,00h			; see if we're at the end of the command line
	lje	main170
	mov	dx,offset grp:se
	mov	al,1
	jmp	done1_print
main080:
	mov	al,byte ptr [di]	; get the parm
	cmp	al,'a'
	jb	main090
	and	al,0dfh			; make it uppercase if a letter
main090:
	cmp	al,'1'			; see if want to format single-sided
	jne	main100
	or	[parmf],01h		; set the parms flag
	jmp	main150
main100:
	cmp	al,'4'			; see if want to format 320/360 in 1.2m
	jne	main110
	or	[parmf],02h		; set the flag
	mov	[spt],9			; this requires 9 sectors/track
	mov	[dirsects],7		; 7 sectors/dir
	mov	[spf],2			; 2 sectors/fat for 9 sectored disks
	mov	[spc],2			; set sectors/cluster
	mov	[dirent],112		; 112 root directory entries
	mov	[bs_bpb].bsMedia,0fdh
	mov	[cylds],40
	or	cs:[si].dpMediaType,01h	; tell device driver its 320/360 media
	jmp	main150
main110:
	cmp	al,'7'			; see if want to format 720k in 1.44m
	jne	main120
	or	[parmf],02h		; set the flag
	mov	[spt],9			; this requires 9 sectors/track
	mov	[dirsects],7		; 7 sectors/dir
	mov	[spf],3			; 3 sectors/fat
	mov	[spc],2			; set sectors/cluster
	mov	[dirent],112		; 112 root directory entries
	mov	[bs_bpb].bsMedia,0f9h
	mov	[cylds],80		; # of cylinders
	or	cs:[si].dpMediaType,01h	; tell device driver its 720k media
	jmp	main150
main120:
	cmp	al,'8'			; see if want to give it 8 spt z
	jne	main130
	or	[parmf],04h
	mov	[bs_bpb].bsMedia,0ffh
	mov	[spt],8			; set sectors/track to 8
	mov	[spf],1			; set sectors/fat
	mov	[spc],2			; set sectors/cluster
	mov	[dirent],112		; set root directory entries
	mov	[cylds],40
	or	[si].dpMediaType,01h	; tell device driver its 320/360 media
	jmp	main150
main130:
	cmp	al,'V'			; see if want to give it a volume
	jne	main140			; /y option?
	or	[parmf],10h		; set the flag
	jmp	short main150
main140:
	cmp	al, 'Y'
	jne	main160
	or	[parmf], 20h		; set flag indicating no warning.
main150:
	jmp	main070			; keep checking the line
main160:
	mov	dx,offset grp:se
	mov	al,1
	jmp	done1_print
main170:

;========================================================
;==== process the parameters

; init master bps variable

	mov	[bs_bpb].bsBytesPerSec,512

; record current drive so it can be restored.

	mov	ax,19ffh
	int	21h
	push	ax

; try to make the specified drive the current one -- to validate it

	mov	ah,0eh
	mov	dl,[drvchar]
	sub	dl,41h
	int	21h
	pop	bx
	cmp	bl,al
	mov	[curdrv],bl
	jbe	main180
	mov	dx,offset grp:invldrv
	mov	al,1
	jmp	done1_print
main180:

; store the drive as a letter in several vars and strings

	add	dl,41h
	mov	[vd],dl
	mov	[whd],dl

; restore the original drive

	mov	dl,bl
	mov	ah,0eh
	int	21h

; check for a network drive

	xor	bx,bx
	mov	bl,[drvchar]
	sub	bl,40h
	mov	[drvnum],bl
	mov	ax,4409h
	int	21h
	test	dx,1000h
	jz	main190
	mov	dx,offset grp:nonetdr
	mov	al,1
	jmp	done_print
main190:

; get the device bpb

	mov	ax,440dh
	mov	bl,[drvnum]
	mov	cx,0860h
	mov	dx,offset grp:odevp
	int	21h

; check for conflicts between the specified parameters and reality

	call	chkparms
	jnz	main200
	mov	dx,offset grp:bprms
	mov	al,1
	jmp	done_print
main200:

; branch to diskette or hard disk processing section

	cmp	[odevp].dpDevType,5
	jne	main210
	jmp	main340

;========================================================
;==== diskette specific processing

main210:
	mov	[hard],false

; tell mos not to issue "Insert diskette" msg

	mov	ax,440fh		
	mov	bl,[drvnum]
	sub	bl,40h
	int	21h
	test	[parmf],01h		; do they want single sided?
	jz	main220			; no, see if by chance its a 3.50 floppy
	mov	[heads],01h		; set counter
	mov	[spc],01h		; indicate 1 sector per cluster
	mov	[bs_bpb].bsMedia,0feh	; set 1st byte of fat to indicate single-sided media
	mov	[dirsects],4		; dir size for any single-sided media
	mov	[dirent],64		; only 64 entries for 1 sided
	mov	[cylds],40
	jmp	main332
main220:
	cmp	[odevp].dpDevType,2	; is it a 3.50 floppy
	je	main230			; yes
	cmp	[odevp].dpDevType,7	; 1.44m drive?
	je	main240
	jmp	main250			; nope
main230:
	mov	[spt],9			; this is a 720k-only drive
	mov	[spc],2			; 2 sectors/cluster
	mov	[bs_bpb].bsMedia,0f9h
	mov	[dirsects],7		; 7 sectors/dir
	mov	[spf],3			; 3 sectors/fat
	mov	[dirent],112		; 112 root directory entries
	mov	[cylds],80		; # of cylinders
	jmp	main332
main240:				; it's a 1.44M drive
	test	[parmf],02h		; check if /7 was requested
	ljnz	main332
	mov	[spt],18		; sectors/track
	mov	[spc],01h		; 1.44 meg is 1 sector/cluster
	mov	[bs_bpb].bsMedia,0f0h
	mov	[dirsects],14		; sectors/dir
	mov	[spf],9			; sectors/fat
	mov	[dirent],224		; root directory entries
	mov	[cylds],80		; # of cylinders
	jmp	main332
main250:
	test	[parmf],02h		; check the parms
	ljnz	main332
	test	[parmf],04h
	ljnz	main332
	test	[parmf],01h		; if they specified a single-sided 1.2m - error
	jz	main260
	mov	dx,offset grp:icprm
	mov	al,2
	jmp	done_print
main260:
	cmp	[odevp].dpDevType,0	; see if this is an at/xt
	jz	main270			; no, go ahead and set chrn and diskbase
	mov	[spc],01h		; 1.2 meg is 1 sector/cluster
	mov	[bs_bpb].bsMedia,0f9h	; indicate 15 sectors/track 2 sides
	jmp	main332
main270:				; this is the default for an xt/pc
	mov	ax,[spt]		; see if the parms have changed this value
	cmp	ax,9
	jbe	main290
	test	[parmf],4
	jnz	main280
	mov	[spt],9			; 9 sectors/track unless its specified
	jmp	main290
main280:
	mov	[spt],8			; 8 sectored disk
main290:
	test	[parmf],4
	jz	main310
	mov	[spf],1			; only 1 sector/fat for 8 sectored disks
	cmp	[heads],1		; is it single-sided?
	jne	main300
	mov	[bs_bpb].bsMedia,0feh	; single sided 8 spt
	jmp	short main330
main300:
	mov	[bs_bpb].bsMedia,0ffh
	jmp	short main330
main310:
	mov	[spf],2			; 2 sectors/fat for 9 sectored disks
	test	[parmf],1
	jnz	main320
	mov	[heads],2		; set the default
	mov	[dirsects],7		; 7 sectors/dir
	mov	[spc],2			; set sectors/cluster
	mov	[dirent],112		; 112 root directory entries
	mov	[bs_bpb].bsMedia,0fdh	; tell mos its 9 sectored
	jmp	short main330
main320:
	mov	[bs_bpb].bsMedia,0fch	; single-sided 9 sectors/trak
main330:
	mov	[cylds],40
	or	[si].dpMediaType,01h	; tell device driver its 320/360 media
main332:

; derive the value for tot_data_sct
;
; tsct = heads * cylds * spt		(tsct is total sectors) 
; tosct = (dirsects + 2*spf + 1)  	(tosct is total overhead sectors)
; total data sectors = ((tsct - tosct) / spc) * spc

	mov	ax,[heads]
	mul	[spt]
	mul	[cylds]
	mov	cx,ax
	mov	bx,dx
	xor	dx,dx
	mov	ax,[spf]
	add	ax,[spf]
	add	ax,[dirsects]
	add	ax,1
	adc	dx,0
	sub	cx,ax
	sbb	bx,dx
	mov	ax,cx
	mov	dx,bx
	div	[spc]
	mul	[spc]
	mov	[tot_data_sct],ax
	mov	[tot_data_sct+2],dx
	jmp	setupbpb

;========================================================
;==== hard disk specific processing

main340:
	mov	[hard],true

; xfer the odevp hidden sectors value to the global var [hiddn].

	mov	ax,word ptr [odevp].dpHiddenSecs  
	mov	[hiddn],ax		
	mov	ax,word ptr [odevp].dpHiddenSecs+2
	mov	[hiddn+2],ax

; xfer the odevp sectors per track value to the global var [spt].

	mov	ax,word ptr [odevp].dpSecPerTrack
	mov	[spt],ax

; make dx:ax = total sectors.

	xor	dx,dx
	mov	ax,[odevp].dpSectors
	or	ax,ax
	jnz	main400
	mov	ax,word ptr [odevp].dpHugeSectors
	mov	dx,word ptr [odevp].dpHugeSectors+2
main400:

; tracks = total sectors / spt
; cylinders = tracs / heads

	div	[spt]
	mov	cx,[odevp].dpHeads
	xor	dx,dx
	div	cx

; if a remainder, bump up the count to the next cylinder.

	or	dx,dx
	jz	main410
	inc	ax
main410:
	mov	[cylds],ax

; use the number of hidden sectors to derive the
; starting head value.
; if # of hidden sectors <= [spt], then [shead] = 1
; else [shead] = 0

	mov	[shead],0
	mov	dx,[hiddn+2]
	mov	ax,[hiddn]
	or	dx,dx
	jnz	main420
	cmp	ax,[spt]
	ja	main420
	mov	[shead],1
main420:

; always start at cylinder 0

	mov	[scyl],0

; calculate the number of sectors/fat and sectors for root directory.
; start by presuming a 12 bit fat and seeing if more than (4096-10)
; clusters will result.

	mov	[spc],8
	mov	[fattype],12

; get the total sector count in dx:ax

	xor	dx,dx
	mov	ax,[odevp].dpSectors
	or	ax,ax
	jnz	havesects3
	mov	ax,word ptr [odevp].dpHugeSectors
	mov	dx,word ptr [odevp].dpHugeSectors+2
havesects3:

; make dx:ax = total sectors - 1  (to account for the boot sector)

	sub	ax,1
	sbb	dx,0
	push	ax			; save it temporarily
	push	dx

; set number of root directory entries for a hard disk.
; then, calc the number of directory sectors.

	xor	dx,dx
	mov	ax,512
	mov	[dirent],ax
	mov	cx,32			; number of bytes/directory entry
	mul	cx
	div	[bs_bpb].bsBytesPerSec
	add	dx,-1			; increment quotient if remainder not 0
	adc	ax,0
	mov	[dirsects],ax
	mov	cx,ax

; make ax = (total - reserved - directory) / spc
; ax will then be the ballpark number of clusters

	pop	dx
	pop	ax			
	sub	ax,cx
	sbb	dx,0
	mov	si,ax			; save intermediate value
	mov	di,dx
;
; the following fix prevents the check spc calculation from getting
; divide overflow on extremly large drives 1.4G in our case
;
	cmp	dx,8
	jb	useolder
	mov	[fattype],16
	mov	ax,16
bigloop:
	cmp	dx,ax
	jb	bigexit
	shl	ax,1
	jmp	short bigloop
bigexit:
	mov	[spc],ax
	jmp	main390
;	  
useolder:
	div	[spc]			

; if there are more clusters than will fit within a 12 bit fat, 
; switch to the 16 bit version and recalc.

	cmp	ax,(4096-10)
	jna	main395
	mov	[spc],4
	mov	[fattype],16
	xor	dx,dx
	mov	ax,[odevp].dpSectors
	or	ax,ax
	jnz	havesects3a
	mov	ax,word ptr [odevp].dpHugeSectors
	mov	dx,word ptr [odevp].dpHugeSectors+2
havesects3a:

; if more than 256M (8,0000h sectors), use 16 spc

	cmp	dx,8
	jb	main370
	mov	[spc],16
	jmp	short main390

; else, if more than 32M (ffffh sectors), use 8 spc

main370:
	cmp	dx,0
	je	main390
	mov	[spc],8
main390:

; recover intermediate sector count and re-calc the ballpark
; count of total clusters.

	mov	ax,si
	mov	dx,di
	div	[spc]			
main395:

; convert the cluster count (in ax) to a number of fat bytes

	xor	dx,dx			
	cmp	[fattype],16		; 16-bit fat?
	je	cspfj2			; yes, jump
	mov	cx,ax
	add	ax,cx			; multiply ax by 3, giving dx:ax
	adc	dx,0
	add	ax,cx
	adc	dx,0
	inc	ax
	adc	dx,0
	shr	dx,1			; now divide by 2 to get # fat bytes
	rcr	ax,1
	jmp	short cspfj3
cspfj2:
	add	ax,ax			; 16-bit fat: just multiply by 2
	adc	dx,0
cspfj3:

; divide total fat bytes by bps to get total fat sectors.
; store in spf

	div	[bs_bpb].bsBytesPerSec
	add	dx,-1			; bump if remainder
	adc	ax,0
	mov	[spf],ax

; now, derive the total number of fat sectors (presumes two fats)
; and retrieve the intermediate total data sector count in
; bx:cx.  subtracting total fat sectors from this will produce
; the total amount of sectors from which clusters could be
; made.  dividing this by [spc] will produce the actual number
; of data clusters (where any remiander is disregarded -- extra
; clusters -- who need's em?).  multiplying again by [spc] will
; produce the actual number of sectors used for data clusters.
; this value is saved for the final display at the end
; of the format operation.

	mul	[wordtwo]
	mov	bx,di			; retrieve intermediate
	mov	cx,si			; value from above
	sub	cx,ax
	sbb	bx,dx
	mov	ax,cx
	mov	dx,bx
	div	[spc]
	mul	[spc]
	mov	[tot_data_sct],ax
	mov	[tot_data_sct+2],dx

; xfer the odevp heads value to the global var [spt].

	mov	ax,[odevp].dpHeads
	mov	[heads],ax

; indicate a fixed disk in fat id byte

	mov	[bs_bpb].bsMedia,0f8h	

; format only uses the verify function for fixed disks

	mov	[opcode],62h		

; at this point, the scan_partition function will be called to
; determine if the partition is on the first or second physical
; hard drive.  this information will be needed by the setboot
; function where it must initialize the bsDriveNumber field.

	mov	al,[drvnum]
	sub	al,3
	mov	[drive_num],0
	call	scan_partitions
	jnc	main430
	lea	dx,bad_scan
	mov	al,1
	jmp	done_print
main430:
	mov	[drive_num],al		; save for the setboot function

;========================================================
;==== common processing for diskettes and hard disks

setupbpb:

;  calc logical sector # for data area  (set [dals]).

	call	calc_lsda

; derive spcshf, the sectors per cluster shift factor.

; if spc == 02, spcshf == 1
; if spc == 04, spcshf == 2
; if spc == 08, spcshf == 3
; if spc == 16, spcshf == 4

	push	ax
	push	cx
	mov	ax,[spc]
	mov	cx,7			; max spc is 128
main440:
	cmp	ax,1
	je	main450
	shr	ax,1
	dec	cx
	jmp	short main440		; find when it's 1
main450:
	neg	cx
	add	cx,7			; shift = 7 - # shifts
	mov	[spcshf],cx		; store shift factor
	pop	cx
	pop	ax

; setup fatbuf_seg and check for enough memory for the fat
; buffer (both copies) and the buffer where the root directory
; is built.

	call	grow
	jz	main470

; error - insufficient memory.
; convert from paragraphs to bytes.

	xor	dx,dx
	mov	cx,4
main460:
	shl	ax,1			
	rcl	dx,1
	loop	main460
	mov	bx,offset grp:memnd+5
	mov	cx,6
	call	bin2dec
	mov	dx,offset grp:nomem
	call	print
	mov	dx,offset grp:err
	mov	al,1
	jmp	done_print
main470:

; setup the fat_lead buffer with the contents for the first
; two fat entries.

	mov	al,[bs_bpb].bsMedia
	mov	[fat_lead],al
	mov	ax,0ffffh
	mov	[fat_lead+1],al
	mov	[fat_lead+2],al
	cmp	[fattype],16
	je	main480
	inc	ax
main480:
	mov	[fat_lead+3],al

; build ndevp from odevp and global vars

	call	genbpb

; init the track table

	call	settl

; xfer the following fields from odevp to ndevp:
;  dpDevType
;  dpDevAttr
;  dpCylinders

	mov	si,offset grp:odevp+1
	mov	di,offset grp:ndevp+1
	mov	ax,ds
	mov	es,ax
	mov	cx,5
	rep	movsb

; regarding the special functions byte, dpSpecFunc:
; set b0 to cause the device bpb to be used for all subsequent
;  build bpb requests.
; clear b1 to cause both the device block and the track table 
;  to be set into the driver
; set b2 to specify that all sectors in the track are of the
;  same size.

	mov	[ndevp].dpSpecFunc,5

; call ioctl to set the device parameters from [ndevp].

	mov	ax,440dh
	mov	bl,[drvnum]
	mov	cx,0840h
	mov	dx,offset grp:ndevp
	int	21h
	jnc	its_set
	mov	dx,offset grp:bprms
	mov	al,1
	jmp	done_print
its_set:
	mov	[retry],3

; if formatting a hard disk, skip prompt

	cmp	[hard],true
	jne	main530

; if the /y option was on the command line, don't even bother with
; the warning.	this is an undocumented option for use by acu.exe

	test	[parmf],20h
	jnz	main560

; ask for confirmation to format a fixed disk.

	mov	dx,offset grp:warng
	call	print
	mov	dx,offset grp:go
	call	print
main500:
	call	get_yes_no
	cmp	al,3
	lje	done_cntrlc
	cmp	al,'Y'
	je	main560
	jmp	done_ok			; must be no

; prompt the user to insert the diskette to be formated

main530:
	mov	dx,offset grp:instd
	call	print
main540:				

; get input where the input buffer is flushed first.
; abort if control-c is pressed.

	mov	ax,0c07h		
	int	21h
	cmp	al,03h			
	lje	done_cntrlc
	cmp	al,0dh
	jnz	main540

; a confirmation was received, proceed with the format operation.
; setup boot sector's bpb and other vars.
; then, zero out memory for the first fat copy.

main560:
	call	setboot
	call	zero_fat1

; if running under mos, call iD4f18 to flush and invalidate the cache.
; if running under dos, call i21f0D, reset disk.

	mov	[write_prot],'N'
	cmp	[is_mos],true
	je	main570
	mov	ah,0dh
	int	21h
	jmp	short main580
main570:
	mov	dl,[drvnum]		; 1-based drive
	mov	ah,18h
	int	services
main580:

; finally time to call the format function.

	call	format
	cmp	ax,0
	je	main585
	cmp	ax,1
	lje	setupbpb
	cmp	ax,2
	lje	done
	cmp	ax,4
	lje	its_set
	mov	al,1			; ax must be 3
	jmp	done1
main585:

; the first fat was marked with any bad clusters found during the
; format process.  now it is time to copy this first fat to the
; buffer position for the second fat.

	call	dupfat

; zero-fill the root directory buffer

	call	makedir

; blank out the percent formatted message.

	mov	dx,offset grp:blanks
	call	print

; if the /v switch was specified, prompt for a volume label.

	test	[parmf],10h
	jz	main590
	call	getvolume
main590:

; write boot sector, fat and root directory

	call	todisk
	jnc	main600
	mov	dx,offset grp:writerr
	mov	al,1
	jmp	done1_print
main600:

;========================================================
;==== display information about disk formatted.

; don't display the final size report if running from acu. (/y option)

	test	[parmf],20h
	jz	main610
	jmp	done_ok
main610:
	mov	dx,offset grp:fok
	call	print

; calculate and display disk information

	call	calc_di			

; if formatting a hard disk, skip prompt about formatting another

	cmp	[hard],true
	je	done_ok
kbi:
	mov	dx,offset grp:another
	call	print
	call	get_yes_no
	cmp	al,3
	je	done_cntrlc
	cmp	al,'Y'
	jne	main650

; clear percentage formatted

	mov	di,offset grp:percnt
	mov	cx,3
main640:
	mov	byte ptr [di],' '
	loop	main640			
	jmp	its_set
main650:
	mov	dx,offset grp:crlf
	xor	al,al
	jmp	short done_print

;==================================================
;==== termination processing

done_ok:
	xor	al,al
	jmp	short done
done_cntrlc:
	mov	dx,offset grp:cntrlc
	call	print
	mov	ax,01
	jmp	short done
done_print:
	push	ax
	call	print
	pop	ax
	jmp	short done
done1_print:
	push	ax
	call	print
	pop	ax
	jmp	short done1
done:
	push	ax
	mov	dx,offset grp:ndevp		; reset the disk parms
	mov	bx,dx
	mov	[bx].dpSpecFunc,04h
	mov	bl,[drvnum]
	mov	ax,440dh
	mov	cx,0840h
	int	21h
	pop	ax
done1:
	push	ax
	mov	dl,[curdrv]		; restore the current drive
	mov	ah,0eh
	int	21h
	pop	ax
	mov	ah,4ch
	int	21h			; terminate with return code

	subttl findnonblnk - find the 1st non-blank
	page
;======================================================================
;,fs
; findnonblnk - find the 1st non-blank
;
; in:	ds:bx -> string to parse
;	cx = length of command line.
;	ds -> grp
;
; out:	nc if found a non-blank
;	 ds:bx -> non-blank char
;	 cx reduced by characters passed
;	cy if found end of buffer first
;	 cx = 0
;	crashes al
;
;,fe
;======================================================================
	assume ds:grp,es:nothing,ss:nothing
findnonblnk proc near
	mov	al,[bx]
	cmp	al,20h
	jnbe	fn1
	inc	bx
	dec	cx			; adjust the cx register
	jmp	findnonblnk
fn1:
	jcxz	nf
	clc				; clear the carry to indicate found
	ret
nf:
	stc
	ret				; indicate not found & return
findnonblnk endp

	subttl findparm - parsing logic
	page
;======================================================================
;,fs
; findparm - parsing logic
;
; scan command line to locate a 1 or 2 byte string and then 
; remove that string from the command line.
;
; in:	ax = byte(s) to find
;	ah = 0, al = byte (if one byte to find)
;	cx = length of command line.
;	di = ptr into cmnd line
;	ds -> grp
;
; out:	nc if found, cy if not
;	di points to 1st byte past string.	
;
;,fe
;======================================================================
	assume ds:grp,es:nothing,ss:nothing
findparm proc near
	push	es			; save es register.
	push	cs
	pop	es			; set es=cs.
	assume	es:grp
	cmp	ah,0			; see if 1 byte scan.
	jnz	do_2			; must scan for 2 bytes.
	or	al,al			; sets the zero flag for following scan
scan:
	repne	scasb
	jcxz	not_found		; if didn't find byte, cy and return
	cmp	byte ptr [di-1],05ch	; check to see if its a `\`. if so, don't
	jz	chk_2			; blank it out.
	mov	byte ptr cs:[di-1],20h	; blank out delimeter
chk_2:
	cmp	grp:[wrd_flag],1	; see if we must check a second byte
	jnz	ncy			; no - clear carry and return
	cmp	[di],ah			; see if next byte = ah. as it should
	jnz	not_found		; not there
	inc	di			; adjust di & return
	mov	[wrd_flag],0		; reset word flag
ncy:
	clc				; clear the carry flag
dun:
	pop	es
	ret
do_2:
	mov	[wrd_flag],1
	or	al,al			; clear zero flag
	jmp	scan
not_found:
	stc				; set the carry & return
	jmp	dun
findparm endp

	subttl chkparms - check for conflicting switches
	page
;======================================================================
;,fs
; chkparms - check for conflicting switches
;
; if an unrecognized device type is found, this function will balance
; the stack, branch directly to the done_print termination handling
; logic.
;
; in:	[odevp] must contain meaningful data
;	[parmf] must have bits set from switches found
;	ds -> grp
;
; out:	nz if no conflict
;	zr if a conflict
;	crashes al
;
;,fe
;======================================================================
	assume ds:grp,es:nothing,ss:nothing
chkparms proc near
	mov	bx,offset grp:odevp		; get the old bpb and check type
	cmp	[odevp].dpDevType,2	; see if its a 3.50 floppy
	je	chk_hard		; yes
	jmp	chk_flpy		; no
chk_hard:
	cmp	[odevp].dpDevType,5	; see if its a 3.50 floppy
	jne	chk_flpy
	mov	al,[parmf]		; get the parms and check bits 0 - 2. if any
	and	al,07h			; are set, its an error
	cmp	al,07h
	ja	chk_pret
	jmp	seterr			; and return
chk_flpy:
	cmp	[odevp].dpDevType,4	; is it 8 inch?
	jne	chkfl3
	jmp	seterr
chkfl3:
	cmp	[odevp].dpDevType,3	; check for 8 inch again
	je	cant_format
	mov	al,[parmf]		; get the parm flag
	and	al,07h			; check 3 low order bits
	cmp	al,07h
	jb	chk_ok			; it its < 7 its ok
	jmp	seterr
chk_ok:
	mov	al,1
	or	al,al			; clear the zero flag
	jmp	chk_pret
seterr:
	xor	al,al
	or	al,al
chk_pret:
	ret
cant_format:
	pop	ax			; get return address off stack
	mov	dx,offset grp:weird_type
	mov	al,3
	jmp	done_print
chkparms endp

	subttl calc_lsda - calc logical sector # for data area
	page
;======================================================================
;,fs
; calc_lsda - calc logical sector # for data area
;
; in:	[spf] = # of sectors per fat
;	[dirsects] = # of sectors for root directory
;	[heads] = # of heads
;	[spt] = # of sectors per track
;	[cylds] = # of cylinders
;	ds -> grp
;
; out:	[dals] = data area logical sector
;	crashes ax, dx
;
;,fe
;======================================================================
	assume ds:grp,es:nothing,ss:nothing
calc_lsda proc near

; double the sectors per fat (presuming 2 fats)

	mov	ax,[spf]
	shl	ax,1

; add in the number of sectors for the root directory.
; increment to take into account logical sector 0.
; store this intermediate value in [dals] as the logical sector
; of the start of the data area.

	add	ax,[dirsects]
	inc	ax
	mov	[dals],ax		
	ret
calc_lsda endp

	subttl grow - setup fatbuf_seg and check for enough memory
	page
;======================================================================
;,fs
; grow - setup fatbuf_seg and check for enough memory
;
; verify that enough memory exists for the fat buffer
;
; in:	[bs_bpb].bsBytesPerSec = bytes per sector
;	[boot_seg] = segment of boot sector buffer
;	[dals] = data area logical sector
;	[spt] = # of sectors per track
;	[memtop] = highest segment address (from psp:2)
;	ds -> grp
;
; out:	[fatbuf_seg] = seg of buffer where fats are built
;
;,fe
;======================================================================
	assume ds:grp,es:nothing,ss:nothing
grow proc near

; calculate the # of paragraphs for the boot sector buffer
; to find the segment which follows.
; record this next segment for use in fat building.

	mov	ax,[bs_bpb].bsBytesPerSec
	mov	cl,4
	shr	ax,cl
	mov	bx,[boot_seg]
	add	bx,ax
	mov	[fatbuf_seg],bx

; this next bit takes the # of paragraphs per sector (ax) times the
; logical sector number of the start of the data area.  the result
; will be the # of paragraphs required for the buffer where the fats 
; and root directory are built.

	mul	[dals]
	add	bx,ax
	cmp	bx,[memtop]
	ja	growerr
	xor	ax,ax			; set zr flagging allocation was ok
growerr:
	ret
grow endp

	subttl bin2dec - binary to decimal conversion
	page
;======================================================================
;,fs
; bin2dec - binary to decimal conversion
;
; in:	dx:ax = value to convert
;	ds:bx -> end of buffer for results
;	cx = # of digits to allow for
;
; out:	results written in buffer
;	crashes ax, bx, cx, dx
;
;,fe
;======================================================================
	assume ds:nothing,es:nothing,ss:nothing
bin2dec proc  near
	push	si
	push	di
	push	bx
	push	cx
	xor	di,di
	mov	si,cx
	cmp	si,4			; is it real long?
	jle	btdloop1		; no, skip
	cmp	si,10
	jne	btsmall
	cmp	dx,2700h
	jbe	btsmall
	mov	word ptr [bx-9],'00'
btbigloop:
	cmp	dx,05f5h
	ja	btbig1
	jb	btbigok
	cmp	ax,0e100h
	jb	btbigok
btbig1:
	cmp	byte ptr [bx-8],'9'
	jne	btbig2
	inc	byte ptr [bx-9]
	mov	byte ptr [bx-8],'0'
	jmp	short btbig3
btbig2:
	inc	byte ptr [bx-8]
btbig3:	
	sub	ax,0e100h
	sbb	dx,5f5h
	jmp	short btbigloop
btbigok:
	mov	si,8
btsmall:
	div	cs:[w10000]		; yes, do it piecemeal
	mov	cx,4
	mov	di,ax
	mov	ax,dx
	xor	dx,dx
btdloop1:
	div	cs:[w10]
	add	dl,'0'
	mov	[bx],dl
	dec	bx
	xor	dx,dx
	loop	btdloop1
	mov	ax,di
	xchg	cx,si
	sub	cx,4
	jg	btdloop1
	pop	cx
	pop	bx
btdloop2:
	sub	bx,cx
btdloop3:
	cmp	byte ptr [bx],' '
	je	btnext
	cmp	byte ptr [bx],'0'
	jne	btdret
	mov	byte ptr [bx],' '
btnext:
	inc	bx
	jnz	btdloop3
btdret:
	pop	di
	pop	si
	ret
bin2dec endp

	subttl print - display ds:dx string with i21f09
	page
;======================================================================
;,fs
; print - display ds:dx string with i21f09
;
; in:	ds:dx -> ascii string to be displayed, terminated with a '$'
;
; out:	string is displayed to stdout
;	crashes ax
;
;,fe
;======================================================================
	assume ds:nothing,es:nothing,ss:nothing
print proc near
	mov	ah, 9
	int	21h
	ret
print endp

	subttl genbpb - build ndevp from odevp and global vars
	page
;======================================================================
;,fs
; genbpb - build ndevp from odevp and global vars
;
; in:	[odevp] = the old bdb structure
;	[shead] = starting cylinder for format loop
;	[spt] = sectors per track
;	[spc] = sectors per cluster
;	[reservd] = # of reserved sectors
;	[dirent] = # of root directory entries
;	[heads] = counter for # of heads, for format loop
;	[cylds] = # of cylinders
;	[bs_bpb].bsMedia = media byte
;	[spf] = # of sectors per fat
;	[hiddn] = # of hidden sectors
;	[dals] = data area logical sector
;	[dirsects] = # of sectors for root directory
;	ds -> grp
;
; out:	[ndevp] = the old bdb structure
;	[bs_bpb].bsBytesPerSec
;	[oddhid] = # of odd hidden sectors
;	[sctshft] = shift cnt for byte2sector conversion and back (mboot.inc)
;	[cdata] = sector address of cluster 0 (mboot.inc)
;	[fattype] = # of bits per hard disk fat entry
;	[bigfat] = nz if it's a 16-bit FAT (mboot.inc)
;	[bs_bpb].bsSecPerTrack
;	[dirsct] = sector address of first dir sector
;	crashes ax, cx, dx, si, di
;
;,fe
;======================================================================
	assume ds:grp,es:nothing
genbpb proc near

; make sure head adjustment is 0

	mov	ax,[shead]
	mul	[spt]
	push	ax

; bit 2 must be set in the special functions byte to indicate
; that all sectors are of the same size.

	or	[ndevp].dpSpecFunc,04h 

; bring in the bytes per sector value from the old parameter block/bpb

	mov	ax,[odevp].dpBytesPerSec
	mov	[ndevp].dpBytesPerSec,ax
	mov	[bs_bpb].bsBytesPerSec,ax

; set the sectors per cluster, the reserved sectors and the # of
; root directory entries from the global variables.
; the number of fats is fixed at 2.

	mov	ax,[spc]
	mov	[ndevp].dpSecPerClust,al
	mov	[ndevp].dpResSectors,1
	mov	ax,[dirent]
	mov	[ndevp].dpRootDirEnts,ax
	mov	ax,2
	mov	[ndevp].dpFATs,al

; calc total sectors:  dx:ax = heads * spt * cylds
; then take away the # of odd hidden sectors.

	mov	ax,[heads]
	mul	[spt]
	mul	[cylds]
	pop	cx			; pushed as ax
	sub	ax,cx
	sbb	dx,0

; now it's time to store this total sector count in the 
; new parameter block/bpb.

	or	dx,dx
	jnz	dobigsects
	mov	[ndevp].dpSectors,ax
	mov	word ptr [ndevp].dpHugeSectors,0
	mov	word ptr [ndevp].dpHugeSectors+2,0
	jmp	short dobig2
dobigsects:
	mov	word ptr [ndevp].dpHugeSectors,ax
	mov	word ptr [ndevp].dpHugeSectors+2,dx
	mov	[ndevp].dpSectors,0
dobig2:

; the media descriptor byte has been kept in the boot sector bpb

	mov	al,[bs_bpb].bsMedia
	mov	[ndevp].dpMedia,al

; setting more parameter block/bpb fields from global variables.

	mov	ax,[spf]
	mov	[ndevp].dpFATsecs,ax
	mov	ax,[spt]
	mov	[ndevp].dpSecPerTrack,ax
	mov	ax,[heads]
	mov	[ndevp].dpHeads,ax
	mov	ax,[hiddn]
	mov	word ptr [ndevp].dpHiddenSecs,ax
	mov	ax,[hiddn+2]
	mov	word ptr [ndevp].dpHiddenSecs+2,ax

; calculate the sector shift factor and store it in the [sctshft]
; field within the boot record (mboot.inc).

	xor	ax,ax			; ax will contain sector shift count
	push	cx
	mov	cx,[bs_bpb].bsBytesPerSec
sctl:
	inc	ax
	shr	cx,1
	jnz	sctl
sctd:
	dec	ax			; 1 returns 0, 2 returns 1, ...
	pop	cx
	mov	[sctshft],al

; within the boot sector (mboot.inc) the [cdata] field must hold
; the starting sector of the data area (the first cluster).
; by subtracting the # of root directory sectors from this value,
; the sector number of the first directory sector is derived
; and set into the [dirsct] field within the boot sector (mboot.inc).

	mov	ax,[dals]
	mov	[cdata],ax
	mov	cx,[dirsects]
	sub	ax,cx
	mov	[dirsct],ax

; use the [fattype] field to determine the value for the [bigfat]
; flag.  this flag is located within the boot sector (mboot.inc).

	cmp	[fattype],16
	jne	not_bgfat
	mov	[bigfat],0ffh
not_bgfat:

; set the sectors per track field withn boot sector's bpb from the
; global variable [spt].

	mov	ax,[spt]
	mov	[bs_bpb].bsSecPerTrack,ax
	ret
genbpb endp

	subttl settl - setup the track table within ndevp
	page
;======================================================================
;,fs
; settl - setup the track table within ndevp
;
; in:	[spt] = sectors/track
;	[bs_bpb].bsBytesPerSec
;	ds -> grp
;
; out:	table at [ndev].dpTracks is initialized
;	crashes ax
;
;,fe
;======================================================================
	assume ds:grp,es:nothing
settl proc near
	push	di
	push	cx
	push	dx
	mov	cx,[spt]
	mov	di,offset grp:[ndevp].dpTracks ; begin addressing track table
	mov	[di],cx
	add	di,2
	mov	dx,[bs_bpb].bsBytesPerSec  ; sector size in bytes
	mov	ax,1			; beginning sector number
tl1:
	mov	[di],ax			; put in sector number
	mov	[di+2],dx		;  "   "    "   size
	inc	ax
	add	di,4
	loop	tl1
	mov	word ptr [di],0		; zero out end of track
	mov	word ptr [di+2],0
	pop	dx
	pop	cx
	pop	di
	ret
settl endp

	subttl setboot - setup boot sector's bpb and other vars
	page
;======================================================================
;,fs
; setboot - setup boot sector's bpb and other vars
;
; in:	[ndevp] holds bpb data
;	[spf] = # of sectors per fat
;	[spc] = sectors per cluster
;	minmem = a constant from mboot.inc
;	[drive_num] = value for bsDriveNum
;	ds -> grp
;
; out:	[dirsct] = sector address of first dir sector
;	[bigfat] = nz if it's a 16-bit FAT (mboot.inc)
;	[cdata] = sector address of cluster 0 (mboot.inc)
;	[drive] = the boot drive (normally 00h or 80h)
;	[endbf2] = end of second sector buffer
;	[endboot] = endbf2 + 256 (end of stack)
;	[locboot] = segment address to which boot sector is relocated
;	[sctshft] = shift cnt for byte2sector conversion and back
;	the following boot record fields are set:
;	  [bs_bpb].bsDriveNumber	
;	  [bs_bpb].bsReserved1		
;	  [bs_bpb].bsBootSignature	
;	  [bs_bpb].bsVolumeID		
;	  [bs_bpb].bsFileSysType
;	  [bs_bpb].bsVolumeLabel	(initialized to blanks)
;	crashes ax, cx, dx, si, di, es
;
;,fe
;======================================================================
	assume	ds:grp,es:nothing,ss:nothing
setboot proc near

; copy the bpb from within the ndevp parameter block/bpb to the
; bpb within the boot sector.

	mov	ax,ds
	mov	es,ax
	mov	di,offset grp:bs_bpb
	mov	si,offset grp:ndevp.dpBytesPerSec
	mov	cx,size bpb
	rep	movsb

; set the [drive] field within the boot sector
; to 80 for a hard disk, 0 for a diskette.

setbt1:

; if formatting a hard disk, set [drive] = 80h

	mov	[drive],0
	cmp	[hard],true
	jne	setbt1a
	mov	[drive],80h
setbt1a:

; derive the values for the [endbf2] and [endboot] fields within the
; boot sector.

	mov	ax,[bs_bpb].bsBytesPerSec
	add	ax,[bs_bpb].bsBytesPerSec
	add	ax,[bs_bpb].bsBytesPerSec
	mov	[endbf2],ax
	add	ax,256			; plus a 256 byte stack
	mov	[endboot],ax
	mov	cl,4
	shr	ax,cl
	neg	ax
	add	ax,minmem
	mov	[locboot],ax		; location to relocate bootstrap

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

; init the bsFileSysType field

	mov	si,offset grp:fattype16
	mov	di,offset grp:bs_bpb.bsFileSysType
	mov	cx,8/2
	cld
	rep	movsw
	cmp	[fattype],12
	jne	setbt2
	mov	byte ptr [bs_bpb].bsFileSysType+4,'2'
setbt2:

; blank the label field, just in case getvolume isn't called

	mov	al,' '
	mov	cx,8+3
	mov	di,offset grp:bs_bpb.bsVolumeLabel
	rep	stosb

	ret
setboot endp

	subttl zero_fat1 - zero out memory for the first fat copy
	page
;======================================================================
;,fs
; zero_fat1 - zero out memory for the first fat copy
;
; in:	[fatbuf_seg] = seg of buffer where fats are built
;	ds -> grp
;	[bs_bpb].bsBytesPerSec
;	[spf] = # of sectors per fat
;	[fat_lead] = first two fat entries
;
; out:	[dir_seg] = segment of location for second fat
;	[dir_ofs] = offset grp:of location for second fat
;	crashes si, di, es
;
;,fe
;======================================================================
	assume ds:grp,es:nothing,ss:nothing
zero_fat1 proc near
	push	ax
	push	bx
	push	cx
	push	dx

; copy the leading fat bytes to the fat buffer.

	mov	cx,4
	mov	si,offset grp:fat_lead
	mov	es,[fatbuf_seg]
	mov	di,0
	cld
	rep	movsb

; zero-fill the first fat sector, starting out with 4 fewer bytes
; due to the fat_lead data.

	mov	cx,[bs_bpb].bsBytesPerSec
	sub	cx,4
	mov	si,[spf]
	xor	ax,ax
	cld
	rep	stosb
	dec	si
	jz	zero_fat1x

; now, zero-fill the remaining fat sectors.

	mov	cx,[bs_bpb].bsBytesPerSec
save_cnt:
	push	cx
	rep	stosb
	pop	cx
	cmp	di,0
	jne	bd_cont
	push	ax
	mov	ax,es
	add	ax,1000h
	mov	es,ax
	pop	ax
bd_cont:
	dec	si
	jnz	save_cnt
zero_fat1x:

; save the location of the next point after the last fat
; sector.  it will be required when the dupfat function
; copies the first fat into the second fat buffer.

	mov	[dir_seg],es
	mov	[dir_ofs],di
	pop	dx
	pop	cx
	pop	bx
	pop	ax
	ret
zero_fat1 endp

	subttl format - the actual format routine
	page
;======================================================================
;,fs
; format - the actual format routine
;
; in:	[spt] = # of sectors per track
;	[spc] = sectors per cluster
;	[hard] = true for a hard disk, false for diskette
;	[scyl] = starting cylinder for format loop
;	[shead] = starting head for format loop
;	[drvnum] = drive number 1-a, 2-b
;	[opcode] = i21f44s0D operation
;	[dals] = data area logical sector
;	[spcshf] = right shift factor for sector -> cluster
;	[heads] = # of heads
;
; out:	ax = return code
;		0 = normal exit
;		1 = branch to setupbpb
;		2 = branch to done
;		3 = branch to done1 (with al = 1)
;		4 = branch to its_set
;		5 = branch to done_cntrlc
;	[bad_clusters] = bad cluster counter
;
; internal use:
;	[cluspt] = format loop counter, clusters per track
;	[fp1] = format packet
;	[carry] = flags overflow of bad cluster onto new track
;	[clustervalue] = cluster value for fat
;	[curcn] = current cluster number
;	[lsn] = counter for logical sector number.
;	[ovflow_flag] = flags overflow of bad cluster onto new track
;	[bad_typ] = used to count retrys of using ioctl format code
;	[write_prot] = disk write protected
;
;,fe
;======================================================================
	assume ds:grp,es:nothing,ss:nothing
format proc near

; init retry counter and emit crlf to display

	mov	[bad_typ],2
	mov	dx,offset grp:crlf
	call	print

; derive value for [cluspt], clusters per track.  this is used
; as a loop counter in the formatting process.  bump up to the
; next whole value if there's a remainder (e.g. for 17 spt,
; a value of 5 would result).

	mov	ax,[spt]
	xor	dx,dx
	div	[spc]
	cmp	dx,0
	je	fmt010
	inc	ax
fmt010:
	mov	[cluspt],ax

; set the special functions byte to zero.  documented this way.

	mov	[fp1].fvSpecFunc,00h

; assume diskette and set fvHead/fvCylinder for that case.
; then, if actually doing a hard disk, use [scyl] and [shead].

	mov	[fp1].fvHead,00h
	mov	[fp1].fvCylinder,00h
	cmp	[hard],true
	jne	fmt020
	mov	ax,[scyl]
	mov	[fp1].fvCylinder,ax
	mov	ax,[shead]
	mov	[fp1].fvHead,ax
fmt020:

; do ioctl call to format/verify (diskette case) or to just
; verify a track (hard disk case).

	mov	ax,440dh		; generic i/o request call
	mov	bl,[drvnum]		; get drive number
	mov	dx,offset grp:fp1		; force it just to be certain
	mov	ch,08h			; set minor function number
	mov	cl,[opcode]		; get the operation code
	int	21h
	ljc	fmt180

; update the status line which reports the percent completed.

	call	show_percent
	mov	word ptr [carry],false
fmt030:

; if [lsn] < [dals], then formatting below the start of the data
; area, skip the next section which updates the fat.

; note: this section can be entered from the error handling logic.
; this is the only way this section will be entered where [carry]
; is true so bad cluster markers will be written.

	mov	dx,[lsn+2]
	mov	ax,[lsn]
	cmp	dx,0
	jne	fmt040
	cmp	ax,[dals]
	ljb	fmt160
fmt040:

; ([lsn] - [dals]) is the sector number relative to the data area.
; if this is greater than [spt], then goto the second section of
; adjustment logic instead of the first.

	sub	ax,[dals]
	sbb	dx,0
	cmp	dx,0
	jne	fmt090
	cmp	ax,[spt]		; if result is < spt we need to start building fat
	jae	fmt090			; no need to adjust

; first section of adjustment logic
; enter here when formatting within the first track of the data area.

; make cx = (([lsn] - [dals]) / spc)  (the cluster number).
; then add in clusters per track and bump up if the division left
; a remainder.

	div	[spc]
	mov	cx,ax
	add	cx,[cluspt]
	cmp	dx,0
	je	fmt050
	inc	cx
fmt050:

; start with the first cluster number (cluster #2).

	mov	dx,2
	cmp	[carry],true
	jne	fmt060
	mov	ax,0fff7h		; bad cluster value
	dec	[bad_clusters]
	jmp	short fmt070
fmt060:
	xor	ax,ax			; good cluster value
fmt070:
	mov	[clustervalue],ax
fmt080:
	call	putfat
	inc	dx			; do the next cluster
	mov	ax,[clustervalue]
	loop	fmt080

; save current cluster for later

	mov	[curcn],dx
	jmp	fmt160			; do the next head/track

; second section of adjustment logic
; enter here when formatting beyond the first track of the data area.

fmt090:
	mov	dx,[lsn+2]		; get high word of logical sector #
	mov	ax,[lsn]		; get the logical sector number and
	call	ls2cn			; convert it to a cluster number
	mov	dx,ax			; put the cluster number in dx
	xor	ax,ax			; good cluster
	cmp	word ptr [carry],false
	je	fmt100			; no carry - good cluster
	mov	ax,0fff7h		; carry is bad cluster
fmt100:
	mov	[clustervalue],ax
	mov	cx,[cluspt]
fmt110:
	cmp	[ovflow_flag],true
	jne	fmt120
	mov	ax,0fff7h
fmt120:
	call	putfat
	inc	dx
	mov	ax,[clustervalue]
	mov	[ovflow_flag],false
	loop	fmt110

; if exit loop with ax = fff7 (bad cluster value),
; then must check for a track overflow.
; first, convert the cluster number to a logical sector number.

	cmp	ax,0fff7h
	jne	fmt150
	push	ax
	push	dx
	mov	ax,dx
	sub	ax,2
	xor	dx,dx
	push	cx
	mov	cx,[spcshf]
fmt130:
	shl	ax,1
	rcl	dx,1
	loop	fmt130
	pop	cx
	add	ax,[dals]
	adc	dx,0

; this logical sector number is then by [spt] to see what remainder
; is generated.  this remainder will be the number of sectors left
; after all whole track amounts of sectors have been divided out.
; if adding the number of sectors in one cluster to this remainder
; makes it larger than a track's worth of sectors then the remianing
; amount was closer to a whole track than a cluster.  
; this is marked as an overflow.

	div	[spt]
	add	dx,[spc]
	mov	[ovflow_flag],false
	cmp	dx,[spt]
	jb	fmt140
	mov	[ovflow_flag],true
fmt140:
	pop	dx
	pop	ax
fmt150:
	mov	[curcn],dx

; advance the head number.  when run out of heads, zero the head
; and advance the cylinder number.

fmt160:
	inc	[fp1].rwHead
	mov	ax,[heads]
	cmp	[fp1].rwHead,ax
	jb	fmt170
	mov	[fp1].rwHead,0
	inc	[fp1].rwCylinder
	mov	ax,[cylds]
	cmp	[fp1].rwCylinder,ax
	jb	fmt170
	xor	ax,ax			; normal exit, return code = 0
	jmp	fmt290
fmt170:

; advance the logical sector number by a track's worth of sectors
; and recycle back to the ioctl call.

	mov	ax,[spt]
	add	[lsn],ax
	adc	[lsn+2],0
	jmp	fmt020

; error processing

fmt180:
	mov	word ptr [carry],true

; if cylinder 0, and the retry counter hasn't zeroed yet, retry
; the ioctl call.

	cmp	[fp1].rwCylinder,0
	jne	fmt200
	dec	[bad_typ]
	ljnz	fmt020
fmt200:
	clc
	push	es
	push	di
	mov	ah,59h
	xor	bx,bx
	int	21h			; get extended error
	pop	di
	pop	es
	cmp	al,15h			; drive not ready
	jne	fmt230
	mov	dx,offset grp:dnr
	call	print

; see if they want to try again

	mov	dx,offset grp:more
	mov	bx,offset grp:percnt
	mov	byte ptr [bx],' '
	mov	byte ptr [bx+1],' '
	mov	byte ptr [bx+2],' '
	call	print
fmt220:
	call	get_yes_no
	cmp	al,3
	jne	fmt221
	mov	ax,5			; indicate branch to done_cntrlc
	jmp	fmt290
fmt221:
	cmp	al,'Y'
	jne	fmt222
	mov	ax,1			; indicate branch to setupbpb
	jmp	fmt290
fmt222:
	mov	ax,2			; indicate branch to done
	jmp	fmt290			; (al must have been 'N')

; check for a general failure error

fmt230:
	cmp	al,31h
	jne	fmt240
	mov	dx,offset grp:drf
	call	print
	mov	ax,3
	jmp	fmt290
fmt240:
	cmp	al,13h
	jne	fmt245
	mov	dx,offset grp:protmsg
	jmp	short fmt250
fmt245:
	cmp	[fp1].rwCylinder,0	; check if error on track 0
	ljne	fmt030			; not 0
	mov	dx,offset grp:baddisk	; print error message
fmt250:
	call	print
	mov	dx,offset grp:err
	call	print
	mov	dx,offset grp:another
	call	print
fmt260:
	call	get_yes_no
	cmp	al,3
	jne	fmt261
	mov	ax,5			; indicate branch to done_cntrlc
	jmp	fmt290
fmt261:
	cmp	al,'Y'
	jne	fmt262
	mov	ax,4			; indicate branch to its_set
	jmp	fmt290
fmt262:

; al must be 'N'

	mov	ax,2			; indicate branch to done
fmt290:
	ret
format endp

	subttl show_percent - report percentage complete
	page
;======================================================================
;,fs
; show_percent - report percentage complete
;
; in:	[fp1].rwCylinder = cylinder number
;	[cylds] = # of cylinders
;	[prct] = last percentage value
;	ds -> grp
;
; out:	[prct] = last percentage value
;
;,fe
;======================================================================
	assume	ds:grp,es:nothing,ss:nothing
show_percent proc near
	push	ax
	push	dx
	mov	ax,[fp1].rwCylinder	; get cylinder number
	inc	ax
	xor	dx,dx
	push	bx
	mov	bx,100
	mul	bx
	pop	bx
	div	word ptr [cylds]
	cmp	[prct],al
	je	shp040
	mov	[prct],al

; adjust percentage

	push	ax
	push	bx
	push	cx
	push	dx			; save all the general registers
	cmp	[prct],9
	ja	shp010
	mov	cx,1
	jmp	short shp030
shp010:
	cmp	[prct],99
	ja	shp020
	mov	cx,2
	jmp	short shp030
shp020:
	mov	cx,3
shp030:
	mov	bx,offset grp:percnt+2	; get to end of string
	mov	al,byte ptr [prct]
	mov	dx,0
	call	bin2dec
	pop	dx
	pop	cx
	pop	bx
	pop	ax

; display percentage

	mov	dx,offset grp:percnt
	call	print
shp040:
	pop	dx
	pop	ax
	ret
show_percent endp

	subttl putfat - writes bad cluster marks in the fat
	page
;======================================================================
;,fs
; putfat - writes bad cluster marks in the fat
;
; in:	dx = cluster number
;	ax = value to write (fff7 or 0)
;	[bad_clusters] = bad cluster counter
;	[fatbuf_seg] = seg of buffer where fats are built
;	[fattype] = # of bits per hard disk fat entry
;	[wordtwo] = set to two, to simplify division
;
; out:	cluster is set to the entry ax value
;	crashes es
;
;,fe
;======================================================================
	assume ds:grp,es:nothing,ss:nothing
putfat proc near
	or	ax,ax			; if no error
	jnz	pf			; just return
	ret
pf:
	push	dx
	push	cx
	push	bx
	push	ax			; save value to set

; count up a bad cluster

	inc	[bad_clusters]
	mov	es,[fatbuf_seg]
	mov	ax,dx
	cmp	[fattype],16
	jne	putfat1

; 16-bit fat

	mov	dx,ax			; temporarily save out cluster number
	xor	al,al			; calcualte sgement adjustment
	shr	ax,1
	shr	ax,1			; divide by 8 (cluster * 2 / 512) para
	shr	ax,1
	mov	bx,es
	add	bx,ax
	mov	es,bx
	mov	bx,dx			; calculate offset
	xor	bh,bh
	shl	bx,1
	pop	ax			; restore cluster value
	mov	word ptr es:[bx],ax	; put it in table
	jmp	putfatx			; say goodbye

; 12-bit fat

putfat1:
	add	ax,ax			; offset grp:= (cluster * 3) / 2
	add	ax,dx
	xor	dx,dx			; clear dx
	div	[wordtwo]
	mov	bx,ax			; bx = byte offset grp:in fat of entry
	pop	ax			; get it back
	test	dx,1
	jz	not_odd
	and	ax,0fffh		; (make sure value fits)
	mov	dx,0fff0h
	mov	cl,4
	shl	ax,cl
	jmp	setfat
not_odd:
	and	ax,0fffh
	mov	dx,0fffh
setfat:
	not	dx
	and	word ptr es:[bx],dx
	not	dx
	and	ax,dx
	or	word ptr es:[bx],ax
putfatx:
	pop	bx
	pop	cx
	pop	dx
	ret
putfat endp

	subttl ls2cn - convert logical sector # to cluster #
	page
;======================================================================
;,fs
; ls2cn - convert logical sector # to cluster #
;
; in:	dx:ax = logical sector number to convert
;	[dals] = data area logical sector
;	[spcshf] = right shift factor for sector -> cluster
;	ds -> grp
;
; out:	ax = corresponding cluster number
;	crashes dx
;
;,fe
;======================================================================
	assume ds:grp,es:nothing,ss:nothing
ls2cn proc near
	push	cx
	sub	ax,[dals]
	sbb	dx,0
	mov	cx,[spcshf]
ls210:
	shr	dx,1
	rcr	ax,1
	loop	ls210
	add	ax,2
	pop	cx
	ret
ls2cn endp

	subttl dupfat - copy fat built during format to second fat.
	page
;======================================================================
;,fs
; dupfat - copy fat built during format to second fat.
;
; in:	[bs_bpb].bsBytesPerSec
;	[spf] = # of sectors per fat
;	[fatbuf_seg] = seg of buffer where fats are built
;	[dir_seg] = segment of location for second fat
;	[dir_ofs] = offset grp:of location for second fat
;	ds -> grp
;
; out:	[dir_seg] = segment of location for root directory
;	[dir_ofs] = offset grp:of location for root directory
;
;,fe
;======================================================================
	assume ds:grp,es:nothing,ss:nothing
dupfat proc near
	pushset	ax,bx,cx,dx,si,di,ds,es

; initialize loop counters

	mov	cx,[bs_bpb].bsBytesPerSec
	push	cx
	mov	bx,[spf]

; make ds:si point to the start of the first fat copy.

	mov	ds,[fatbuf_seg]
	mov	si,0

; make es:di point to the point just following the first fat,
; where the second copy is to go.

	mov	es,cs:[dir_seg]
	mov	di,cs:[dir_ofs]

; copy the sectors

	cld
dup_loop:
	rep	movsb
	pop	cx
	push	cx
	cmp	di,0
	jne	dup_cont
	push	ax
	mov	ax,es
	add	ax,1000h
	mov	es,ax
	pop	ax
dup_cont:
	cmp	si,0
	jne	dup_cntr
	push	ax
	mov	ax,ds
	add	ax,1000h
	mov	ds,ax
	pop	ax
dup_cntr:
	dec	bx
	jnz	dup_loop

; record the point just after the end of the second fat. 
; this is where the root directory will be built.

	mov	cs:[dir_seg],es
	mov	cs:[dir_ofs],di
	pop	cx
	popset	ax,bx,cx,dx,si,di,ds,es
	ret
dupfat endp

	subttl makedir - zero-fill the root directory buffer
	page
;======================================================================
;,fs
; makedir - zero-fill the root directory buffer
;
; in:	[dir_seg] = segment of location for root directory
;	[dir_ofs] = offset grp:of location for root directory
;	[dirent] = # of root directory entries
;	ds -> grp
;
; out:	directory buffer is zero-filled
;	crashes ax, bx, cx, di, es
;
;,fe
;======================================================================
	assume ds:grp,es:nothing,ss:nothing
makedir proc near

; make es:di point to the buffer where the root directory is built

	mov	es,[dir_seg]
	mov	di,[dir_ofs]

; setup bx as loop coutner

	mov	bx,[dirent]
	cld
md0:
	xor	al,al
	mov	cx,32			; bytes per directory entry
	rep	stosb
	cmp	di,0
	jne	no_dir_ovfl
	mov	ax,es
	add	ax,1000h
	mov	es,ax
no_dir_ovfl:
	dec	bx
	jnz	md0
	ret
makedir endp

	subttl todisk - write boot sector, fat and root directory
	page
;======================================================================
;,fs
; todisk - write boot sector, fat and root directory
;
; in:	[dals] = data area logical sector
;	[shead] = starting head for format loop
;	[scyl] = starting cylinder for format loop
;	[spt] = # of sectors per track
;	[boot_seg] = segment of boot sector buffer
;	[drvnum] = drive number 1-a, 2-b
;	[retry] = retry counter
;	[heads] = counter for # of heads, for format loop
;	[bs_bpb].bsBytesPerSec
;	ds -> grp
;
; out:	sectors written to disk
;	crashes ax, bx, cx, dx, 
;
;,fe
;======================================================================
	assume ds:grp,es:nothing,ss:nothing
todisk proc near
	push	si

; using the logical sector # for the start of the data area as
; the major loop counter.  this will account for the boot sector,
; all fat sectors and all sectors within the root directory.

	mov	cx,[dals]
	push	cx

; initialize the rwp block.  note that i21f44s0Ds41 uses 0 based 
; sector numbering rather than the 1 based sector numbering that 
; int13 uses.

	mov	[rwp].rwSpecFunc,0
	mov	ax,[shead]
	mov	[rwp].rwHead,ax
	mov	ax,[scyl]
	mov	[rwp].rwCylinder,ax
	mov	[rwp].rwFirstSector,0
	mov	ax,[spt]
	mov	[rwp].rwSectors,ax
	mov	word ptr [rwp].rwBuffer,0
	mov	ax,[boot_seg]
	mov	word ptr [rwp].rwBuffer+2,ax
write12:

; use ioctl call to write a track.

	mov	ax,440dh
	mov	bl,[drvnum]
	xor	bh,bh
	mov	cx,0841h
	mov	dx,offset grp:rwp
	int	21h
	jnc	write22
	dec	[retry]
	jnz	write12
	stc
	jmp	short todiskx
write22:

; see if done yet.

	pop	cx
	sub	cx,[spt]
	cmp	cx,0
	jle	moswrit2en

; prepare for next iteration.

	push	cx
	inc	[rwp].rwHead
	mov	ax,[heads]
	cmp	[rwp].rwHead,ax
	jl	norwphad2
	inc	[rwp].rwCylinder
	mov	[rwp].rwHead,0
norwphad2:
	mov	ax,[bs_bpb].bsBytesPerSec
	mul	[spt]
	shr	ax,1
	shr	ax,1
	shr	ax,1
	shr	ax,1
	add	word ptr [rwp].rwBuffer+2,ax
	mov	ax,[spt]
	mov	[rwp].rwSectors,ax
	cmp	cx,ax
	jnl	write12
	mov	[rwp].rwSectors,cx
	jmp	short write12
moswrit2en:
	clc
todiskx:
	pop	si
	ret
todisk endp

	subttl getvolume - prompt for a volume label
	page
;======================================================================
;,fs
; getvolume - prompt for a volume label
;
; in:	ds -> grp
;
; out:	bs_bpb.bsVolumeLabel is set
;	the first directory entry is built
;
;,fe
;======================================================================
	assume ds:grp,es:nothing,ss:nothing
getvolume proc near
	pushset	ax,cx,dx,si,di,es
	mov	dx,offset grp:volprompt
	call	print
	mov	cx,1
	mov	di,offset grp:vol_lbl
gv1:

; get a character

	mov	ah,07
	int	21h

; if from an extended key, eat the next code

	cmp	al,0
	jne	gv2
	mov	ah,7
	int	21h
	jmp	short gv1
gv2:

; if a carriage return, done -- get out of loop

	cmp	al,13
	je	gvx

; when in column 12, accept only backspace (and carriage return)

	cmp	cx,12
	jne	gv3
	cmp	al,8
	jne	gv1
gv3:

; handle backspace  (ignore if in column 1)

	cmp	al,8
	jne	gv4
	cmp	cx,1
	je	gv1
	mov	dl,8
	mov	ah,2
	int	21h
	dec	di
	dec	cx
	jmp	short gv1
gv4:

; ignore invalid characters

	call	chk_char
	jc	gv1

; convert to uppercase

	cmp	al,'a'
	jb	gv5
	cmp	al,'z'
	ja	gv5
	sub	al,32
gv5:
	mov	[di],al
	inc	di
	inc	cx
	mov	dl,al
	mov	ah,2
	int	21h
	jmp	short gv1
gvx:
	mov	dx,offset grp:crlf
	call	print
	mov	dx,offset grp:crlf
	call	print

; set the bsVolumeLabel field

	mov	si,ds
	mov	es,si
	mov	si,offset grp:vol_lbl
	mov	di,offset grp:bs_bpb.bsVolumeLabel
	mov	cx,8+3
	cld
	rep	movsb

; find the start of the root directory and build the first entry, 
; using a volume attribute.

	mov	si,offset grp:vol_lbl
	mov	es,[dir_seg]
	mov	di,[dir_ofs]
	mov	cx,8+3
	push	di
	rep	movsb
	pop	di
	mov	es:[di].deAttributes,8
	popset	ax,cx,dx,si,di,es
	ret
getvolume endp

	subttl chk_char - see if the char in al is a valid char for a filename.
	page
;======================================================================
;,fs
; chk_char - see if the char in al is a valid char for a filename.
;
; in:	al=char to test
;	ds -> grp
;
; out:	cy if char not valid
;	else nc when char is ok
;
;,fe
;======================================================================
	assume ds:grp,es:nothing,ss:nothing
chk_char proc near
	push	bx
	push	cx
	cmp	al,20h
	jb	no_good
	mov	bx,offset grp:charstb	; begin loop to check table.
	mov	cl,[tab_len]		; cx is counter
	xor	ch,ch
chk_l:
	cmp	al,[bx]
	jz	no_good			; carry is set, return
	inc	bx			; get next char
	loop	chk_l
	clc				; just in case
	jmp	short chkx
no_good:
	stc
chkx:
	pop	cx
	pop	bx
	ret
chk_char endp

	subttl calc_di - calculate and display disk information
	page
;======================================================================
;,fs
; calc_di - calculate disk information
;
; in:	[ndevp].dpSectors/dpHugeSectors
;	[dals] = data area logical sector
;	[spc] = sectors per cluster
;	[bs_bpb].bsBytesPerSec
;	[bad_clusters] = # of bad clusters
;	ds -> grp
;
; out:	[bad_clusters] is set to 0
;
;,fe
;======================================================================
	assume ds:grp,es:nothing,ss:nothing
calc_di proc near

; make dx:ax = total data sectors * bps   (total data bytes)

	mov	ax,[tot_data_sct]
	mov	dx,[tot_data_sct+2]
	mov	cx,[bs_bpb].bsBytesPerSec
	call	lmul
	push	ax
	push	dx
	mov	bx,offset grp:totsec+12
	mov	cx,10
	call	bin2dec			; convert it to ascii
	mov	ax,[bad_clusters]
	or	ax,ax
	jz	nobadsectors

; total bad bytes = bad clusters * spc * bps

	mov	ax,[bad_clusters]
	xor	dx,dx
	mov	cx,[spc]
	call	lmul
	mov	cx,[bs_bpb].bsBytesPerSec
	call	lmul
	push	dx
	push	ax
	mov	bx,offset grp:totbad+12	; address the message
	mov	cx,8
	call	bin2dec
	pop	bx			; pushed as ax
	pop	cx			; pushed as dx
nobadsectors:
	pop	dx
	pop	ax

; dx:ax = total bytes

	cmp	[bad_clusters],0
	je	nbs1
	sub	ax,bx			

; remaining bytes = total bytes - bytes in bad sectors

	sbb	dx,cx
nbs1:
	mov	bx,offset grp:totrem+12
	mov	cx,10
	call	bin2dec
	mov	dx,offset grp:crlf
	call	print
	mov	dx,offset grp:totsec
	call	print
	cmp	[bad_clusters],0
	je	nobadout
	mov	dx,offset grp:totbad
	call	print
nobadout:
	mov	dx,offset grp:totrem
	call	print
	mov	[bad_clusters],0
	ret
calc_di endp

	subttl get_yes_no - prompt for yes, no or cntrl-c
	page
;======================================================================
;,fs
; get_yes_no - prompt for yes, no or cntrl-c
;
; the first character of the yesmsg and nomsg strings are used
; to make this function adapt for foreign languages.
;
; in:	ds -> grp
;
; out:	al = 'Y' for affirmative
;	   = 'N' for negative
;	   = 3 for cntrl-c
;	crashes ah
;
;,fe
;======================================================================
	assume ds:grp,es:nothing,ss:nothing
get_yes_no proc near

	pushset	bx,cx,dx

; setup bh as a column counter/state indicator.  when either the
; affirmative or negative response letter is entered, set bh to
; 1.  if bh == 1, respond to a carriage return by returning 
; (where cl holds the return character) and respond to the
; backspace key by blanking the displayed letter and resetting
; bh (to prevent multiple backspaces).

gc010:
	xor	bh,bh
gc012:
	mov	ax,0c07h		
	int	21h
	and	al,0dfh			; make it upper case
	cmp	al,[nomsg]
	jne	gc020
	mov	dl,'N'
	jmp	short gc025
gc020:
	cmp	al,[yesmsg]
	jne	gc030
	mov	dl,'Y'
gc025:

; if bh already 1, backup and overwrite previous char

	cmp	bh,1
	jne	gc027
	push	dx
	mov	dl,8
	mov	ah,2
	int	21h
	pop	dx
gc027:
	mov	cl,dl
	mov	ah,2
	int	21h
	mov	bh,1
	jmp	short gc012
gc030:
	cmp	al,13
	jne	gc040

; if a carriage return, and a 'Y' or 'N' (usa case) has been entered
; and displayed, return the dl character in al

	cmp	bh,1
	jne	gc010
	mov	al,cl
	jmp	gc060
gc040:
	cmp	al,8
	jne	gc050

; if a backspace, and a 'Y' or 'N' (usa case) has been entered
; and displayed, blank out that previous letter and reset bh.

	cmp	bh,1
	jne	gc010
	mov	dl,8
	mov	ah,2
	int	21h
	mov	dl,' '
	mov	ah,2
	int	21h
	mov	dl,8
	mov	ah,2
	int	21h
	jmp	short gc010
gc050:
	cmp	al,03h
	jne	gc012
gc060:
	popset	bx,cx,dx
	ret
get_yes_no endp

	subttl lmul - perform long multiplication
	page
;======================================================================
;,fs
; lmul - perform long multiplication
;
; in:	dx:ax contains double word to be multiplied
;	cx    contains multiplier
;
; out:	dx:ax contains double word product of dx:ax * cx
;	all other registers unchanged
;
;,fe
;======================================================================
	assume ds:nothing,es:nothing,ss:nothing
lmul proc near
	push	bx			; save bx because we use it as a temp
	push	ax			; save low word
	mov	ax,dx			; move high to low word
	mul	cx			; multiply high word
	mov	bx,ax			; save out product of high word value
	pop	ax			; restore low word value
	mul	cx			; multiply low word
	add	dx,bx			; add high word of product to previous product
	pop	bx			; restore bx
	ret
lmul endp


	dw	100h dup (0)		; allocate room for stack
stktop	label	word

moss	ends

	subttl	boot sector
	page
bootstrap segment	para
	include mboot.inc
bootstrap ends

	end	start

