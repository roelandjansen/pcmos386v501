;******************************************************************************
;*									      *
;*			   Master Disk Boot Record			      *
;*									      *
;* Boot Logic - when the MBR receives control from the BIOS boot logic, it    *
;* checks to see if a valid boot record signature is at the end of the parti- *
;* tion table. If not, the "Partition Table Invalid" message is displayed and *
;* the system enters an enabled loop. If the boot signature is valid, mbr be- *
;* gins scanning the partition table and counts the number of MOS partitions  *
;* that are marked as bootable. If none are, a "No operating system" message  *
;* is displayed and the system goes into an enabled loop. If there is more    *
;* than one partition marked as bootable, the system will prompt for a parti- *
;* tion number to boot. If only one is bootable, that partition is booted.    *
;* The mbr logic will continue with the prompt until it gets a valid partition*
;* number to boot. It will beep if there is an invalid response to the prompt.*
;* Once the partition to boot has been determined, that sector is loaded from *
;* the disk and control is xfered to 0:7c00 which is where the boot logic is  *
;* loaded. If an error occurs during the read of the boot logic for the parti-*
;* tion, the message "Cannot load operating system" will be displayed and the *
;* system will enter an enabled loop.					      *
;*									      *
;*	The MBR logic will set SS:SP to 0:7c00 and relocate itself 600h bytes *
;* above that. This allows me to have disk buffer space between 0:7c00 and the*
;* beginning of my code.						      *
;*									      *
;*			  Written by: Jeffrey S. Weyrich		      *
;*				   12/01/86				      *
;*									      *
;******************************************************************************
;									      ;
; RKG	09/23/88	Set Partition byte always so MOS knows where to find  ;
;			system files.  Rewritten since position dependent code;
;			was rampant.					      ;
;-----------------------------------------------------------------------------;
; RKG	10/10/88	Changed Message handling			      ;
;-----------------------------------------------------------------------------;
; SAH	07/10/89	Correct boot up logic from 09/23/88 which was	      ;
;			incorrect in handling DOS partitions. We must have    ;
;			DS:SI -> partition record. Also made code better by   ;
;			making sure that we clear keyboard buffer, so that we ;
;			don't have those annoying beeps and video improvements;
;-----------------------------------------------------------------------------;
; BWR	11/30/89	Marked messages for foreign language translation.     ;
;-----------------------------------------------------------------------------;
; SAH   04/25/90	Correction for Compaq Monochrome monitors	      ;
;-----------------------------------------------------------------------------;

;	Boot is called and calls with CS=0000


PartStr	struc		; Partition structure
PBootFlg db	0	; = 00h non-bootable Partition
			; = 80h bootable Partition
			; = 81h boot from secondary disk
PHeadB	db	0	
PSectB	db	0	; Beginning Head/Sector/Cylinder
PCylB	db	0
PSysFlg db	0	; System Indicator
			; = 0  Unknown
			; = 1  12bit FATs
			; = 4  16bit FATs
PHeadE	db	0
PSectE	db	0	; Ending Head/Sector/Cylinder
PCylE	db	0
PSecRel	dd	0	; Doubleword Relative Sector of Beginning
PSecLen	dd	0	; Doubleword Sector Length of Partition
PartStr ends

BOOTABLE equ	80h	; Bootable bit in BootFlg
PARTCNT	equ	4	; Partitions in BOOTSTR
BOOTSIGN equ	0AA55h	; Signature of valid Boot record

BOOTPRG	equ	1BEh	; Length of Boot Program
BOOTLEN	equ	200h	; Length of Boot Record

BLODADR	equ	7C00h	; Segment Boot Loaded
BEXEADR	equ	7E00h	; Segment Boot Executes


BiosDisp equ	10h
BiosDisk equ	13h
BiosKey	 equ	16h
BiosMem	 equ	12h


bootseg	segment para public 'bootseg'
	assume	cs:bootseg

MBRbeg:
	jmp	short boot1
	
BootId:				; leave this here!!!! The routine 'ReadMBR'
	db	'TSL'		; 
	
boot1:
	mov	ax,BLODADR SHR 4
	mov	ds,ax
	assume	ds:bootseg
	
	cli			; no interrupts while setting stack
	xor	ax,ax
	mov	ss,ax		; Set stack to 0:7C00
	mov	sp,BLODADR	; below where we loaded
	sti			; restore interrupt flag

	; Relocate program so boot sector loads at 0:7C00

	mov	ax,BEXEADR SHR 4
	mov	es,ax		; Set Segregs for relocate
	
	; Check MBR is valid
	mov	si,offset BadSignMsg
	cmp	[Signatr],BOOTSIGN	; Test Signature is valid
	jne	booterr			; Bad Signature

	mov	cx,BOOTLEN/2
	xor	si,si
	mov	di,si		; Zero src/dst index
	cld
	rep movsw
	
	mov	ax,es		; Set DS to new segment
	mov	ds,ax
	assume	ds:bootseg,es:bootseg

	; now jump to relocated code
		
	jmp	boot4 + BEXEADR - BLODADR
boot4:
	
	; Scan Partitions for Bootable
	mov	si,offset Part4	; SI = Pointer to PARTSTR
	mov	cx,PARTCNT	; CX = Partition #
	xor	bx,bx		; BX = Number Bootable Partitions
				; AX = Last Bootable Partition #

boottst:
	test	[si].PBootFlg,BOOTABLE
	jz	bootnxt
	mov	ax,cx
	inc	bx
	
bootnxt:
	sub	si,SIZE PARTSTR
	loop	boottst
	dec	ax		; zero base partition #
	
	cmp	bx,1		; How many bootable partitions ?
	jg	bootask		; several ask which to boot
	je	bootpart	; just one
	
	mov	si,offset NoPartMsg
booterr:
	jmp	short bootabt		; No Partitions Bootable
	

bootpart:	; Boot Partition given in AL
	push	ax
	call	bootadr		; get addr of PARTSTR
	mov	ax,BLODADR SHR 4
	mov	es,ax		; Address to Load
	xor	bx,bx
	mov	ax,201h		; Command to Read 1 Sector
	mov	dl,[si].PBootFlg
	and	dl,81h		; get disk to boot from
	mov	dh,[si].PHeadB	; Get Cyl/Head/Sect of System
	mov	cl,[si].PSectB
	mov	ch,[si].PCylB
	int	BiosDisk	; Read Boot Sector
	jnc	bootok
	mov	si,offset LoadErrMsg
	jmp	short bootabt	      ; Error reading sector
bootok:
	cmp	es:[Signatr],BOOTSIGN
	je	bootit
	mov	si,offset BadSignMsg
	jmp	short bootabt
bootit:

	; Tell MOS what partition was Booted
	; Last byte of planar memory has partition number
	
	int	BiosMem		; Returns Planar Mem Size in K
	mov	cl,6		; 2^6 = 64
	shl	ax,cl		; Now segment of end of memory
	dec	ax
	mov	es,ax
	pop	ax		; restore Partition #
	mov	es:[0fh],al
	
;	Make sure the ds:si --> to partion record for drive
;	This is very important since DOS boot record check this location
;	upon boot up.

	add	si,7c00h+200h	; set ds:si -> boot partition record
	xor	ax,ax
	mov	ds,ax

;	jump to Partition system boot record

	jmp	MBRbeg + (BLODADR - BEXEADR)
	
	
	subttl	Select Partition 
	page


;	Abort - display message, and wait for reboot
;	Enter	BP = Null-terminated String to display
;	Never returns

bootabt:
	call	bootclr
	call	bootdsp
	jmp	short $
	
	

bootbad:
	mov	si,offset BadPartMsg
	call	bootdsp
	jmp	short bootask0	
	

	;	Ask for the Partition to Boot / Check BootFlg to validate

bootask:
	call 	bootclr
	mov	dx,ax		; save first bootable part
bootask0:
	mov	ah,1		; clear keyboard so that we don't have
	int	BiosKey 	; all those annoying beeps
	jz	bootask1
	xor	ah,ah
	int	BiosKey
	jmp	short bootask0
bootask1:
	mov	si,offset BootPartMsg
	call	bootdsp		; Display partition query
	
bootkey:	; Get a key, verify and load selected partition
	xor	ah,ah		; get a key
	int	BiosKey
	mov	[PartDsp],al	; and echo it
	mov	si,offset PartDsp
	call	bootdsp
	cmp	al,'4'		; Partition 1-4 valid
	ja	bootbad
	sub	al,'1'
	jb	bootbad

	call	bootadr		; get addr of PARTSTR
	test	[si].PBootFlg,BOOTABLE
	jz	bootbad
	jmp	bootpart	; Boot selected Partition
		
	
;	bootadr returns pointer to partition structure
	
;	Enter 	AL = Partition Number
;	Returns	SI = PARTSTR adr
;	Saves All 
bootadr:
	push	ax
	mov	si,offset Part1		; Partitions start 
	mov	ah,SIZE PARTSTR
	mul	ah			; Partition * length
	add	si,ax		
	pop	ax
	ret
		

;	BOOTCLR clears the screen by get/set mode

bootclr:
	push	ax
	push	bx
	xor	bh,bh
	mov	ah,15		; get screen mode
	int	BiosDisp
	and	al,7		; make mode 15 = 7
	cmp	al,7
	je	bootclr1	; is this Mono
	mov	al,3
bootclr1:
	xor	ah,ah		; set same mode / clears screen
	int	BiosDisp
	pop	bx
	pop	ax
	ret
	

;	BOOTDSP - display a null (0) terminated string on the CRT
;	Enter SI = string to display
;	Destroys: SI

bootdsp:
	push	ax
	push	bx		; Save some registers

bootdspc:
	mov	bx,0fh		; Screen Attribute - bright white
	mov	ah,14		; Write TTY char
	lodsb
	test	al,al		; Test end of string
	jz	bootdspx
	int	BiosDisp	; Display character
	jmp	short bootdspc	; loop for all chars

bootdspx:
	pop	bx
	pop	ax
	ret

			; Note the BELLS are included in the strings
	
PartDsp		db	0, 13, 10, 13, 10, 0
NoPartMsg	db	'No MOS partitions', 7, 0 ;@@XLAT
BadPartMsg	db	' Not a Bootable Partition!?', 13, 10 ;@@XLAT
BootPartMsg	db	'Boot Partition? ',7, 0 ;@@XLAT
BadSignMsg	db	'Invalid boot signature', 7, 0 ;@@XLAT
LoadErrMsg	db	'Cannot load MOS', 7, 0 ;@@XLAT

MBRend	label	byte

filllen	= (BOOTPRG - (MBRend - MBRbeg))

if filllen LE 0
	%out	boot segment too long!
endif

filler	db	filllen dup(0)	; fill to partition structures

Part1	PartStr	<>
Part2	PartStr	<>
Part3	PartStr	<>
Part4	PartStr	<>

Signatr	dw	BOOTSIGN	; boot signature

MBRlen	=	($ - MBRbeg)

if MBRlen ne BOOTLEN
	%out	Boot segment wrong size
endif

bootseg	ends

