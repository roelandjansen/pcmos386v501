comment ^==============================================================
		    development specification

 program name:	mboot.inc		assigned to: 
 module name:	mboot.inc		assign date: 01/16/86
 entry points:	n/a			completed:
 entry from:	bootstrap logic in mbr
 entry method:	jmp
 calls:		n/a
 purpose:	locate, load and enter $$mos.sys 
 refer to:	
 last update:	08/01/91

 the boot sector is loaded by the bios at 0000:7c00h, following
  which it:
 1.  relocates itself to a high memory position configured into msys
 2.  reads the root directory looking for $$mos.sys
 3.  reads $$mos.sys into memory starting at 0080:0000 using fat to
     locate $$mos.sys data
 4.  transfers to $$mos.sys at 0080:0000

=======================================================================

bwr 11/30/89	marked messages for foreign language
		translation.

sah 08/16/90	corrections for 650meg hard drive

mjs 12/16/91	dlg mods:  converted to use of structures within
		dskstruc.inc. whatever module includes this file must also
		have an include for dskstruc.inc.  shorted boot error
		message to accomodate extended bpb information.  updated
		version number to 5.01.

======================================================================^

	assume	cs:bootstrap,ds:nothing,es:nothing,ss:nothing

bootadr equ	07c0h			; segment bootstrap is loaded
loadadr equ	0080h			; segment mos is loaded
minmem	equ	160*(1024/16)		; segments required by mos
boot:
	jmp	near ptr boot0
	db	'TSL 5.01'


;==== the following fields must stay together

bs_bpb		bpb	<>
drive		db	0	; the boot drive (normally 00h or 80h)

;==== the above fields must stay together


read		equ	this dword
		dw	rdsect	; dword vector to read sector
locboot 	dw	?	; segment address to which boot sector is relocated
dirsct		dw	?	; sector address of first dir sector
cdata		dw	?	; sector address of cluster 0
sctshft 	db	?	; shift cnt for byte2sector conversion and back

; bigfat, fatbuf used by fat traversal code (see mosfront.asm)

fatbuf		dw	?	; fat sector in buffer
bigfat		db	?	; nz if it's a 16-bit FAT
endbf2		dw	?	; end of second sector buffer
endboot 	dw	?	; endbf2 + 256 (end of stack)
ldbios		dw	loadadr ; address to load bios

parms		db	0dfh,02h,25h,02h
pmaxsct 	db	09h
		db	2ah,0ffh,50h,0f6h,0fh,02h

	subttl boot0 - start of bootstrap code
	page
;======================================================================
;,fs
; boot0 - start of bootstrap code
;
; in:	
;
; out:	
;
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:nothing
boot0:
	cli
	cld
	mov	ax,bootadr
	mov	ds,ax
	assume	ds:bootstrap

; 256 byte stack above this code + 2 sector buffers

	mov	ss,[locboot]
	assume	ss:bootstrap
	mov	sp,[endboot]
	sti
	push	ss
	pop	es
	assume	es:bootstrap
	xor	si,si
	xor	di,di
	mov	cx,512/2
	rep	movsw

; following four lines take advantage of the fact that cs = 0
; but really relate to changing the disk parameter table for
; int 13h below

	lds	si,dword ptr cs:[1eh*4]
	mov	di,offset parms
	mov	word ptr cs:[1eh*4],di
	mov	word ptr cs:[1eh*4+2],es
	push	es
	mov	ax,offset bootx
	push	ax
	retf
bootx:

; it turns out we have to change the disk parameter table and reset
; the drive in order for this to work from a power-on boot

	mov	cl,11			; ch already 0
	rep	movsb
	push	cs
	pop	es
	push	es
	pop	ds
	mov	pmaxsct,26		; (all we really needed to do was change the
					;   max sector - this works on at also)
	int	13h			; reset fdc with new parameters
	jc	hang

; look for $$mos.sys directory entry

	mov	bp,[dirsct]		; start sector for root directory
	mov	bx,[bs_bpb.bsRootDirEnts] ; number of root directory entries
boot1:
	mov	ax,bp
	xor	dx,dx			; dword sector address
	mov	cx,2			; reading 2 dir sectors at a time
	add	bp,cx			; to next sector
	push	es
	mov	di,es
	add	di,512/16
	mov	es,di			; es = segment address of bootbuf
	call	[read]
	pop	es
	mov	di,offset bootbuf
boot2:
	mov	si,offset fnm
	mov	cx,11			; size of a filename
	cmp	ch,es:[di]		; ch = 0 (end of dir)
	je	hang			; couldn't find $$MOS.SYS
	repe	cmpsb
	je	boot3
	dec	bx
	jz	hang			; couldn't find $$MOS.SYS
	add	di,cx
	add	di,32-11		; start of next directory entry
	cmp	di,[endbf2]		; past end of buffer?
	jb	boot2
	jmp	boot1			; next sector

; so now read the first cluster of the file

boot3:
	mov	dx,[di-11+26]		; starting cluster for file
	mov	bx,dx			; pass starting cluster to rest of bootstrap
	mov	al,[bs_bpb.bsSecPerClust]
	xor	ah,ah
	mov	cx,ax			; cx to read entire cluster
	dec	dx
	dec	dx
	mul	dx
	add	ax,[cdata]		; ax = next sector to load
	adc	dx,0
	mov	es,[ldbios]
	push	es
	mov	di,3
	push	di

; rdsect returns to beginning of loaded $$mos.sys

	jmp	rdsect

; display error message and reboot on a key

hang:
	mov	si,offset nonsystem
hang1:
	lodsb
	or	al,al
	jz	hang2
	mov	bx,7
	mov	ah,14
	int	10h
	jmp	hang1
hang2:
	xor	ah,ah
	int	16h
	int	19h
	jmp	hang

	subttl rdsect - read a bunch from the disk
	page
;======================================================================
;,fs
; rdsect - read a bunch from the disk
;
; read cx sectors starting with logical sector dx:ax
; into buffer at seg es
; distance from es first 64k boundary must be divisible by sctsiz
;
; in:	cx = # of sectors
;	dx:ax = logical sector number
;	es -> buffer
;
; out:	es adjusted past read
;	bx preserved
;	ax, cx, dx, di, si trashed
;
;,fe
;======================================================================
	assume	ds:bootstrap,es:bootstrap,ss:bootstrap
rdsect	proc	far
	push	bx
	mov	di,cx
	mov	bx,dx
	mov	si,ax

; until not reading across a 64k boundary, read up to 64k boundary

rdsct1:
	mov	ax,es
	or	ah,0f0h
	neg	ax			; bx = number of paragraphs to 64k boundary
	mov	cl,[sctshft]
	sub	cl,4
	shr	ax,cl			; ax = number of sectors within 64k boundary
	sub	di,ax
	jbe	rdsct2

; have to read up to 64k boundary

	push	di
	call	rdsx			; read doesn't conflict with 64K boundary
	pop	di
	jmp	rdsct1
rdsct2:
	add	ax,di			; same result as add di,ax
	call	rdsx
	pop	bx
	ret
rdsect	endp

	subttl rdsx - helper for rdsect
	page
;======================================================================
;,fs
; rdsx - helper for rdsect
;
; read ax sectors starting with logical sector bx:si into
; buffer at seg es
; read will not cross a 64k boundary
;
; in:	ax = # of sectors
;	bx:si = logical sector
;	es -> buffer
;
; out:	es, si, bx adjusted past read
;	di, ax, dx, cx, crashed
;
;,fe
;======================================================================
	assume	ds:bootstrap,es:bootstrap,ss:bootstrap
rdsx:
	push	si
	push	bx
	push	ax
	mov	cx,ax
	mov	ax,si
	mov	dx,bx
	
; add # of sectors preceding partition

	add	ax,word ptr [bs_bpb.bsHiddenSecs]
	adc	dx,word ptr [bs_bpb.bsHiddenSecs+2]
	div	[bs_bpb.bsSecPerTrack]	; assumes hidden / scttrk < 65536 else overflow
	mov	bx,dx			; bx = sector offset within track
	xor	dx,dx
	div	[bs_bpb.bsHeads]

; ax = track (0-1023 according to bios)
; dx = head (0-15 according to bios)
; bx = sector offset (0-scttrk)

rdsx1:
	mov	si,[bs_bpb.bsSecPerTrack]
	sub	si,bx
	sub	cx,si
	jbe	rdsx2
	push	cx
	mov	cx,si
	call	rdsy
	pop	cx
	jmp	rdsx1
rdsx2:
	add	cx,si
	call	rdsy
	pop	ax
	pop	bx
	pop	si
	add	si,ax
	adc	bx,0
	ret

	subttl rdsx - helper for rdsx
	page
;======================================================================
;,fs
; rdsx - helper for rdsx
;
; read cx sectors starting at ax track, dx head, bx sector offset into
;   es buffer
; read will not cross track boundary
;
; in:	cx = # of sectors
;	ax = track
;	dx = head
;	bx = sector offset
;	es -> buffer
;
; out:	ax, bx, dx, es adjusted past read
;	cx, si, di trashed
;
;,fe
;======================================================================
	assume	ds:bootstrap,es:bootstrap,ss:bootstrap
rdsy:
	mov	di,3			; up to 3 retries
rdsy1:
	push	dx
	push	cx
	push	bx
	push	ax
	mov	si,cx
	mov	cl,bl			; sector is 1-based
	inc	cl
	ror	ah,1
	ror	ah,1
	and	ah,0c0h
	or	cl,ah			; high 2 bits of track
	mov	ch,al			; low 8 bits of track
	mov	dh,dl			; head number
	mov	dl,[drive]		; drive
	mov	ax,si
	mov	ah,02h
	xor	bx,bx
	int	13h
	pop	ax
	pop	bx
	pop	cx
	pop	dx
	jnc	rdsy2
	dec	di
	jnz	rdsy1
	jmp	hang			; hang on some disk error
rdsy2:
	add	bx,cx
	cmp	bx,[bs_bpb.bsSecPerTrack]
	jb	rdsy3
	xor	bx,bx
	inc	dx
	cmp	dx,[bs_bpb.bsHeads]
	jb	rdsy3
	xor	dx,dx
	inc	ax
rdsy3:
	mov	si,cx			; adjust segment past read
	mov	cl,[sctshft]
	sub	cl,4
	shl	si,cl
	mov	cx,es
	add	cx,si
	mov	es,cx
	ret

	subttl	end of boot sector
	page

nonsystem	db	'Boot error  ',0dh,0ah ,0 ;@@xlat


; this is the file name we're looking for in the directory

fnm	db	'$$MOS   SYS'

if $ lt boot+510
	db	boot+510-$ dup(0)
endif

; boot sector signature

	db	55h,0aah

if $ ne boot+512
if2
	%out	bootstrap longer than 512 bytes
endif
endif

; disk buffer consists of 512 bytes following boot code
; (the 512 bytes is implicitly allocated above

bootbuf label	byte

