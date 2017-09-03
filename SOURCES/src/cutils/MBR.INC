comment ^===============================================================

master disk boot record

boot logic - when the mbr receives control from the bios boot logic,
it checks to see if a valid boot record signature is at the end of
the partition table. if not, the "partition table invalid" message is
displayed and the system enters an enabled loop.  if the boot
signature is valid, mbr begins scanning the partition table and
counts the number of mos partitions that are marked as bootable. if
none are, a "no operating system" message is displayed and the system
goes into an enabled loop.

if there is more than one partition marked as bootable, the system
will prompt for a partition number to boot.  if only one is bootable,
that partition is booted.  the mbr logic will continue with the
prompt until it gets a valid partition number to boot. it will beep
if there is an invalid response to the prompt.

once the partition to boot has been determined, that sector is loaded
from the disk and control is xfered to 0:7c00 which is where the boot
logic is loaded. if an error occurs during the read of the boot logic
for the partition, the message "cannot load operating system" will be
displayed and the system will enter an enabled loop.

the mbr logic will set ss:sp to 0:7c00 and relocate itself 600h bytes
above that. this allows me to have disk buffer space between 0:7c00
and	the beginning of my code.

========================================================================

rkg 09/23/88	set partition byte always so mos knows where to find
		system files.  rewritten since position dependent code
		was rampant.

rkg 10/10/88	changed message handling

sah 07/10/89	correct boot up logic from 09/23/88 which was
		incorrect in handling dos partitions. we must have
		ds:si -> partition record. also made code better by
		making sure that we clear keyboard buffer, so that we
		don't have those annoying beeps and video improvements

bwr 11/30/89	marked messages for foreign language translation.

sah 04/25/90	correction for compaq monochrome monitors

mjs 08/19/92	clean up and add documentation - no net code change.

amjs 09/23/92	mosinit overhaul.
		cleaned up source - no code change.

=======================================================================^

; boot is called and calls with cs=0000

partstr	struc
pbootflg	db	0		; = 00h non-bootable partition
					; = 80h bootable partition
					; = 81h boot from secondary disk
pheadb		db	0
psectb		db	0		; beginning head/sector/cylinder
pcylb		db	0
psysflg		db	0		; system indicator
					; = 0  unknown
					; = 1  12bit fats
					; = 4  16bit fats
pheade		db	0
psecte		db	0		; ending head/sector/cylinder
pcyle		db	0
psecrel		dd	0		; doubleword relative sector of beginning
pseclen		dd	0		; doubleword sector length of partition
partstr ends

bootable 	equ	80h		; bootable bit in bootflg
partcnt		equ	4		; partitions in bootstr
bootsign 	equ	0aa55h		; signature of valid boot record

bootprg		equ	1beh		; length of boot program
bootlen		equ	200h		; length of boot record

blodadr		equ	7c00h		; segment boot loaded
bexeadr		equ	7e00h		; segment boot executes

biosdisp 	equ	10h
biosdisk 	equ	13h
bioskey	 	equ	16h
biosmem	 	equ	12h

bootseg	segment para public 'bootseg'
	assume	cs:bootseg
mbrbeg:
	jmp	short boot1
bootid:
	db	'TSL'
boot1:
	mov	ax,blodadr shr 4
	mov	ds,ax
	assume	ds:bootseg
	cli				; no interrupts while setting stack
	xor	ax,ax
	mov	ss,ax			; set stack to 0:7c00
	mov	sp,blodadr		; below where we loaded
	sti				; restore interrupt flag

; relocate program so boot sector loads at 0:7c00

	mov	ax,bexeadr shr 4
	mov	es,ax			; set segregs for relocate

; check mbr is valid

	mov	si,offset badsignmsg
	cmp	[signatr],bootsign	; test signature is valid
	jne	booterr			; bad signature
	mov	cx,bootlen/2
	xor	si,si
	mov	di,si			; zero src/dst index
	cld
	rep	movsw
	mov	ax,es			; set ds to new segment
	mov	ds,ax
	assume	ds:bootseg,es:bootseg

; now jump to relocated code

	jmp	boot4 + bexeadr - blodadr
boot4:

; scan partitions for bootable

	mov	si,offset part4
	mov	cx,partcnt
	xor	bx,bx

; at this point:
; si = pointer to partstr
; cx = partition #
; bx = number bootable partitions
; ax = last bootable partition #

boottst:
	test	[si].pbootflg,bootable
	jz	bootnxt
	mov	ax,cx
	inc	bx
bootnxt:
	sub	si,size partstr
	loop	boottst
	dec	ax			; zero base partition #
	cmp	bx,1			; how many bootable partitions ?
	jg	bootask			; several ask which to boot
	je	bootpart		; just one
	mov	si,offset nopartmsg
booterr:
	jmp	short bootabt		; no partitions bootable
bootpart:				; boot partition given in al
	push	ax
	call	bootadr			; get addr of partstr
	mov	ax,blodadr shr 4
	mov	es,ax			; address to load
	xor	bx,bx
	mov	ax,201h			; command to read 1 sector
	mov	dl,[si].pbootflg
	and	dl,81h			; get disk to boot from
	mov	dh,[si].pheadb		; get cyl/head/sect of system
	mov	cl,[si].psectb
	mov	ch,[si].pcylb
	int	biosdisk		; read boot sector
	jnc	bootok
	mov	si,offset loaderrmsg
	jmp	short bootabt		; error reading sector
bootok:
	cmp	es:[signatr],bootsign
	je	bootit
	mov	si,offset badsignmsg
	jmp	short bootabt
bootit:

; tell mos what partition was booted
; last byte of planar memory has partition number

	int	biosmem			; returns planar mem size in k
	mov	cl,6			; 2^6 = 64
	shl	ax,cl			; now segment of end of memory
	dec	ax
	mov	es,ax
	pop	ax			; restore partition #
	mov	es:[0fh],al

; make sure the ds:si --> to partion record for drive
; this is very important since dos boot record check this location
; upon boot up.

	add	si,7c00h+200h		; set ds:si -> boot partition record
	xor	ax,ax
	mov	ds,ax

; jump to partition system boot record

	jmp	mbrbeg + (blodadr - bexeadr)

; abort - display message, and wait for reboot
; enter	bp = null-terminated string to display
; never returns

bootabt:
	call	bootclr
	call	bootdsp
	jmp	short $
bootbad:
	mov	si,offset badpartmsg
	call	bootdsp
	jmp	short bootask0

; ask for the partition to boot / check bootflg to validate

bootask:
	call	bootclr
	mov	dx,ax			; save first bootable part
bootask0:
	mov	ah,1			; clear keyboard so that we don't have
	int	bioskey			; all those annoying beeps
	jz	bootask1
	xor	ah,ah
	int	bioskey
	jmp	short bootask0
bootask1:
	mov	si,offset bootpartmsg
	call	bootdsp			; display partition query
bootkey:				; get a key, verify and load selected partition
	xor	ah,ah			; get a key
	int	bioskey
	mov	[partdsp],al		; and echo it
	mov	si,offset partdsp
	call	bootdsp
	cmp	al,'4'			; partition 1-4 valid
	ja	bootbad
	sub	al,'1'
	jb	bootbad
	call	bootadr			; get addr of partstr
	test	[si].pbootflg,bootable
	jz	bootbad
	jmp	bootpart		; boot selected partition

;======================================================================
;,fs
; bootadr - returns pointer to partition structure
;
; in:	al = partition number
;
; out:	si = partstr adr
;
;,fe
;======================================================================
bootadr proc near
	push	ax
	mov	si,offset part1		; partitions start
	mov	ah,size partstr
	mul	ah			; partition * length
	add	si,ax
	pop	ax
	ret
bootadr endp

;======================================================================
;,fs
; bootclr - clears the screen by get/set mode
;
; in:	
;
; out:	
;
;,fe
;======================================================================
bootclr proc near
	push	ax
	push	bx
	xor	bh,bh
	mov	ah,15			; get screen mode
	int	biosdisp
	and	al,7			; make mode 15 = 7
	cmp	al,7
	je	bootclr1		; is this mono
	mov	al,3
bootclr1:
	xor	ah,ah			; set same mode / clears screen
	int	biosdisp
	pop	bx
	pop	ax
	ret
bootclr endp

;======================================================================
;,fs
; bootdsp - display a null (0) terminated string on the crt
;
; in:	si = string to display
;
; out:	destroys si
;
;,fe
;======================================================================
bootdsp proc near
	push	ax
	push	bx			; save some registers
bootdspc:
	mov	bx,0fh			; screen attribute - bright white
	mov	ah,14			; write tty char
	lodsb
	test	al,al			; test end of string
	jz	bootdspx
	int	biosdisp		; display character
	jmp	short bootdspc		; loop for all chars
bootdspx:
	pop	bx
	pop	ax
	ret
bootdsp endp

; note the bells are included in the strings

partdsp		db	0, 13, 10, 13, 10, 0
nopartmsg	db	'No MOS partitions', 7, 0  ;@@xlat
badpartmsg	db	' Not a Bootable Partition!?', 13, 10  ;@@xlat
bootpartmsg	db	'Boot Partition? ',7, 0  ;@@xlat
badsignmsg	db	'Invalid boot signature', 7, 0  ;@@xlat
loaderrmsg	db	'Cannot load MOS', 7, 0  ;@@xlat

mbrend	label	byte

filllen	= (bootprg - (mbrend - mbrbeg))

if filllen le 0
	%out	boot segment too long!
endif

filler	db	filllen dup(0)		; fill to partition structures

part1	partstr	<>
part2	partstr	<>
part3	partstr	<>
part4	partstr	<>

signatr	dw	bootsign	; boot signature

mbrlen = ($ - mbrbeg)

if mbrlen ne bootlen
	%out	boot segment wrong size
endif

bootseg	ends

