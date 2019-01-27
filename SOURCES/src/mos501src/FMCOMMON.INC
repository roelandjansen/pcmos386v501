comment ^==============================================================


 this module contains functions and data common to 
 format.asm and msys.asm

 NOTE: this module contains no assume statements on purpose.
 the include statement should be preceded by an appropriate
 assume statement.  within this module, explicit segment 
 overrides should be used where necessary.


======================================================================

mjs 12/16/91	dlg mods: created this module.

======================================================================^


;==========================================================
; data used by both msys and format

drive_num	db	?	; value for bsDriveNum, from scan_partitions

bad_scan db	13,10,'Error during scan of partitions               '
	db	0dh,0ah,'$'

fattype16	db	'FAT16   '

;==========================================================
; data for scan_partitions

ourbuf	db	512 dup(?)
drives	db	?
pt0	db	4*16 dup(0)
pt1	db	4*16 dup(0)


;==========================================================
; functions

	subttl scan_partitions - determine mlg and hard drive number
	page
;======================================================================
;,fs
; scan_partitions
;
; when a match is found, the return bx register value is either a
; pointer to the partition table entry for the matching partition
; or bx is 0 (when the matching partition happens to be an extended
; partition).
;
; this is done to enable the calling code to check for an mlg partition.
;
; in:	al = 0 based hard drive number to match (0 = c:, 1 = d:, etc.)
;
; out:	nc if no error
;	 al = 80 if entry al corresponds to the first hard drive
;	    = 0 if corresponds to second hard drive
;	 ds:bx -> copy of partition table entry (if primary or secondary)
;	 bx = 0 (if extended)
;	cy if error
;
;,fe
;======================================================================
scan_partitions:
	pushset	cx,dx,si,di,bp,ds,es
	mov	bx,cs
	mov	ds,bx
	mov	es,bx
	xor	ah,ah			; init drive counter
	mov	bp,ax

; see how many drives there are

	mov	ah,8
	mov	dl,80h
	int	13h			; get drive parameters
	cmp	dl,0
	lje	scpx
	cmp	dl,2			; limit to 2
	jna	scpa
	mov	dl,2
scpa:
	mov	[drives],dl

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
	mov	bx,offset ourbuf
	mov	cx,0001h		; c0, s1
	mov	dx,0080h		; h0, drive 80
	int	13h
	ljc	scpx

; validate the sector's signature and partition table

	cmp	word ptr [ourbuf+01feh],0aa55h
	ljne	scpx
	mov	si,offset ourbuf+1beh
	cmp	[si].peBootable,80h
	je	scpc
	cmp	[si].peBootable,0
	ljne	scpx
scpc:
	cmp	[si].peFileSystem,PTCsm12
	je	scpc1
	cmp	[si].peFileSystem,PTCsm16
	je	scpc1
	cmp	[si].peFileSystem,PTCdlg
	ljne	scpx

; copy the partition table into the storage block

scpc1:
	mov	di,offset pt0
	mov	cx,4*16/2
	cld
	rep	movsw

; as soon as it's known that the first hard drive contains a valid
; partition table, we know that there is a drive c:.  therefore,
; if the entry al value is 0, we should return with al = 80 and nc.

	mov	ax,bp
	cmp	ah,al
	jne	scpc3
	mov	al,80h			; volume is on 1st drive
	mov	bx,offset pt0
	jmp	scpy
scpc3:

; if a second drive exists, reset it and then
; read the first sector of drive 1 (h0, s1, c0, the second mbr)

	cmp	[drives],2
	jne	scpf
	mov	ax,0401h		; verify to position to cylinder 0
	mov	cx,0001h		; c0, s1
	mov	dx,0081h		; h0, drive 81
	int	13h
	mov	ah,0			; reset
	mov	dl,81h			; drive 81
	int	13h
	mov	ax,0201h		; read 1 sector
	mov	bx,offset ourbuf
	mov	cx,0001h		; c0, s1
	mov	dx,0081h		; h0, drive 81
	int	13h
	jc	scpd

; validate the sector's signature and partition table

	cmp	word ptr [ourbuf+01feh],0aa55h
	jne	scpd
	mov	si,offset ourbuf+1beh
	cmp	[si].peBootable,80h
	je	scpc2
	cmp	[si].peBootable,0
	jne	scpd
scpc2:
	cmp	[si].peFileSystem,PTCsm12
	je	scpe
	cmp	[si].peFileSystem,PTCsm16
	je	scpe
	cmp	[si].peFileSystem,PTCdlg
	je	scpe
scpd:
	mov	[drives],1
	jmp	scpf
scpe:

; copy the partition table into the second stack block

	mov	di,offset pt1
	mov	cx,4*16/2
	cld
	rep	movsw

; as soon as it's known that a second hard drive contains a valid
; partition table, we know that there is a drive d:.  

	mov	ax,bp
	inc	ah
	mov	bp,ax
	cmp	ah,al
	jne	scpf
	xor	al,al			; volume is not on 1st drive
	mov	bx,offset pt1
	jmp	scpy
scpf:

; process any extended partitions on drive 0

	mov	dl,80h
	mov	si,offset pt0
scpg8:
	xor	di,di			; init di as a flag
	mov	cx,3
scpg1:
	add	si,16			; advance to next pte
	cmp	[si].peFileSystem,PTCext
	jne	scpg2
	mov	di,si
	jmp	short scpg3
scpg2:
	loop	scpg1
scpg3:
	or	di,di			; was an extended partition found?
	jz	scpgz

; read the next partition table

	mov	cl,[di].peBeginSector
	mov	ch,[di].peBeginCylinder
	mov	dh,[di].peBeginHead
scpg6:
	mov	ax,0201h		; read 1 sector
	mov	bx,offset ourbuf
	push	dx
	int	13h
	pop	dx
	ljc	scpx

; establish pointers to the first and second partition table entries

	mov	si,offset ourbuf+1beh
	mov	di,offset ourbuf+1beh+10h

; make sure the extended node points to a 'live' partition 

	cmp	cs:[si].peFileSystem,PTCnil
	je	scpg4

; see if this extended partition is the one

	mov	ax,bp
	inc	ah
	mov	bp,ax
	cmp	al,ah
	jne	scpg4
	mov	al,dl
	xor	bx,bx
	jmp	scpy

; if not, is there another extended partition table to deal with?

scpg4:
	cmp	[di].peFileSystem,PTCext
	jne	scpgz
	mov	cl,[di].peBeginSector
	mov	ch,[di].peBeginCylinder
	mov	dh,[di].peBeginHead	; (dl is still the drive number)
	jmp	short scpg6

; if a second drive exists, recycle through the above logic to
; process any extended partitions on drive 1

scpgz:
	cmp	dl,81h			; already been here?
	je	scph
	cmp	[drives],2
	jne	scph
	mov	si,offset pt1
	mov	dl,81h
	jmp	scpg8

; process any secondary partitions on drive 0

scph:
	mov	dl,80h
	mov	si,offset pt0
scph4:
	mov	cx,3
scph1:
	add	si,16
	cmp	[si].peFileSystem,PTCsm12
	je	scph2
	cmp	[si].peFileSystem,PTCsm16
	je	scph2
	cmp	[si].peFileSystem,PTCdlg
	jne	scph3
scph2:

; see if this secondary partition is the one

	mov	ax,bp
	inc	ah
	mov	bp,ax
	cmp	al,ah
	jne	scph3
	mov	al,dl
	mov	bx,si
	jmp	scpy
scph3:
	loop	scph1

; if a second drive exists, recycle through the above logic to
; process any secondary partitions on drive 1

	cmp	dl,81h			; already been here?
	je	scpx
	cmp	[drives],2
	jne	scpx
	mov	si,offset pt1
	mov	dl,81h
	jmp	short scph4

; either a disk error occured or no match was found

scpx:
	stc
	jmp	short scpz

; found a match

scpy:
	cmp	al,80h
	je	scpy1
	xor	al,al
scpy1:
	clc
scpz:
	popset	cx,dx,si,di,bp,ds,es
	ret



