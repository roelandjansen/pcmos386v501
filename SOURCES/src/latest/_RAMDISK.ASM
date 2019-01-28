        include page.inc
        title moxcdisk.sys - virtual ram disk device driver
;
;******************************************************************************
;*                                                                            *
;*                        mos development specification                       *
;*                                                                            *
;* Command type: device driver          Assigned to:      Stewart Hyde        *
;* Command name: moxrdisk.sys           Date assigned:    feb 02, 1987        *
;*                                      Date completed:                       *
;* command format: device=$ramdisk [size] [workaddress]                       *
;* purpose: provide virtual ram disk support for pc-mos/386                   *
;* refer to:                                                                  *
;* last update:                         by:                                   *
;*                                                                            *
;*      external                values                  values                *
;*      routines                passed                  returned              *
;* -------------------------------------------------------------------------- *
;* (add as many lines as you need here and above to complete the form.)       *
;* -------------------------------------------------------------------------- *
;* mos commands will use the same segment grouping as the mos kernel. this    *
;* file is a template as is mosshell.asm. except that its designed for use in *
;* commands, both internal and external, for mos. see mosshell.asm for de-    *
;* tails. the commands should not need to go into as much detail as the kernel*
;* does in keeping track of end of segment pointers in the inc files and such.*
;* our desire is to maintain the same coding standards thruout mos and to use *
;* code modularity as much as possible. so, use the same group labels in any  *
;* routine to keep the code and data segments in the same segment.            *
;*                                                                            *
;******************************************************************************
;
;-----------------------------------------------------------------------
;			ram disk for at gizmo or all card
;		(c) copyright 1987 the software linke, incorporated
;-----------------------------------------------------------------------
; sah	2/17/87		pc-mos o/s mods
; rbr	5/12/87		clean up messages
; rbr	2/10/88		allow easy patching to handle the "PermaRAM"
;			card from node systems.
; jrb	5/2/88		added notes related to caching.
; bwr	11/30/89	marked messages for foreign language
;			translations.
; sah   01/18/90        correction for greater than 4 megs, added
;			statistic messages.
;-----------------------------------------------------------------------


         page
mainseg  segment para
         assume cs:mainseg,ds:mainseg
begin    label near

;------------------------- device header ----------------------------

devheadr label byte
         dd    -1			; pointer to next driver
         dw	0800h			; attribute: ibm format block device
         dw	strategy		; ptr to strategy routine
         dw	interupt		; ptr to interrupt routine
         db	1			; number of logical drives
;jrbr note: the following name must remain the same and at the same (wrong)
;jrbr offset from devheadr or cache won't recognize it as a ram disk and
;jrbr will cache it like any other drive
         db	'$RAMDISK'		; filler

;-------------------------- assorted data ---------------------------

         even
dedram	db	'N'			;rr  patch to y if dedicated ram used
dedkeep	db	'N'		;rr  patch to y if keeping old ramdisk
diskbase dw    0			; starting page number of ramdisk

;  note: patch the physical page number into diskbase if dedram=y.
;        patch dedkeep=y if nonvolatile ramdisk is to be retained.

workaddr dw    0b400h			; segment address of 16k paging area
zero     dw    0			; constant
rhoff    dw    0			; request header pointer
rhseg    dw    0
mroutine dw    2 dup(?)			; address of memory management logic
kbytes   dw    64			; kilobytes disk space requested
secp16k  dw    ?			; sectors per 16k block (16k/128)
pgnumber dw    ?			; page number for block in process
pgoffset dw    ?			; offset of sector in 4-page block
nsectors dw    ?			; nbr sectors left to process
dtaoff   dw    ?			; index into caller'S DTA
dtaseg   dw    ?			; segment address of caller'S DTA
bpbpoint dw    bpb			; for init return




;----------------------- start of boot record -----------------------

bootrec  label byte
         db	3 dup(0)		; no jump if not bootable
         db	'RAMDRIVE'		; bpb must follow this

;---------------------- bios parameter block ------------------------

bpb      label byte
bpbbps   dw    128			; bytes per sector
bpbspc   db    1			; sectors per cluster
         dw	1			; 1 reserved (boot) sector
         db	1			; 1 fat
bpbnorde dw    64			; number of root directory entries
bpbnosec dw    1024/128*64		; number of clusters (default = 64k)
bpbmedia db    0feh			; media descriptor
bpbspf   dw    ?			; sectors per fat
bpblen   equ   $-bpb			; length of bpb

;----------------------- end of boot record -------------------------

         dw	1			; sectors per track
         dw	1			; number of heads
         dw	0			; number of hidden sectors
bootlen  equ   $-bootrec

;---------------------- device function vectors ---------------------

funtab   label word
         dw	init
         dw	mediachk
         dw	buildbpb
         dw	ioctlin
         dw	input
         dw	ndinput
         dw	instatus
         dw	inflush
         dw	output
         dw	outputv
         dw	oustatus
         dw	ouflush
         dw	ioctlout
         dw	devopen
         dw	devclose
         dw	removeable
         page
;-------------------- device strategy routine -----------------------

strategy label near
         mov	cs:[rhseg],es
         mov	cs:[rhoff],bx
farret1  proc  far
         ret
farret1  endp

;--------------------- device interrupt entry -----------------------

interupt label near
         push	es
         push	ds
         push	di
         push	si
         push	dx
         push	cx
         push	bx
         push	ax

         push	cs			; init ds register
         pop	ds

         cld				; no backward moves please!

         les	bx,dword ptr [rhoff]	; load rh pointer
         mov	al,es:[bx+2]		; get command code byte
         mov	ah,0
         shl	ax,1
         mov	di,ax
         jmp	[di+funtab]

;--------------------- interrupt routine exits ----------------------

donestat label near
         les	bx,dword ptr [rhoff]
         or	word ptr es:[bx+03],0100h  ; "DONE" status

exit     label near
         clc
         pop	ax
         pop	bx
         pop	cx
         pop	dx
         pop	si
         pop	di
         pop	ds
         pop	es
farret2  proc  far
         ret
farret2  endp
         page
;---------------------- interrupt routines --------------------------

mediachk label near
         mov	byte ptr es:[bx+14],1	; indicate media not changed
         jmp	donestat

buildbpb label near
         mov	word ptr es:[bx+18],offset bpb
         mov	es:[bx+20],cs
         jmp	donestat

ioctlin  label near
ioctlout label near
ndinput  label near
instatus label near
inflush  label near
oustatus label near
ouflush  label near
         or	word ptr es:[bx+03],8003h  ; "INVALID COMMAND" status
devopen  label near
devclose label near
         jmp	donestat

removeable label near
         mov	word ptr es:[bx+4],20h	; indicate media not removeable
         jmp	donestat		; (set done bit)

input    label near
output   label near
outputv  label near

         mov	ax,es:[bx+20]		; starting sector number
         xor	dx,dx
         div   [secp16k]		; divide by sectors per 16k block
         shl	ax,1			; quotient = 16k block number
         shl	ax,1			; convert to 4k page number
         add	ax,[diskbase]		; add in starting page number
         mov	[pgnumber],ax
         mov	ax,dx
         mul	[bpbbps]		; compute offset into block
         mov	[pgoffset],ax
         mov	ax,es:[bx+18]
         mov	[nsectors],ax		; set remaining nbr sectors to process

         mov	ax,es:[bx+14]		; caller'S DTA OFFSET
         mov	dx,ax
         and	dx,000fh		; convert address for minimum offset
         mov	cl,4
         shr	ax,cl
         add	ax,es:[bx+16]		; ax=segment, dx=offset
         mov	[dtaoff],dx
         mov	[dtaseg],ax
inloop1:
         push	es
         mov	ah,3			; remapping function

	cmp	[dedram],'Y'		;rr  physical remap if dedicated ram
	jne	inlskded		;rr
	mov	ah,5			;rr
inlskded:				;rr

         mov	es,word ptr [workaddr]
         mov	bx,[pgnumber]
         mov	cx,4			; map in 4 4k pages
         add	[pgnumber],cx
         call	dword ptr [mroutine]	; call memory management routine
         pop	es
inloop2:
         call	iomove			; move data to/from ramdisk
         mov	ax,[bpbbps]		; bump pointers
         add	[dtaoff],ax
         add	[pgoffset],ax
         dec	[nsectors]
         jz	iodone			; exit when done
         cmp	[pgoffset],16*1024	; check for end of block
         jb	inloop2
         mov	[pgoffset],0
         jmp	inloop1
iodone:
         push	es
         mov	ah,4			; self-mapping function
         mov	es,word ptr [workaddr]
         mov	cx,4			; map in 4 4k pages
         call	dword ptr [mroutine]	; call memory management routine
         pop	es
         jmp	donestat

;--------------------- data moving subroutine -----------------------

iomove   proc  near
         mov	cx,[bpbbps]		; length
         shr	cx,1

         les	bx,dword ptr [rhoff]	; address command code
         cmp	byte ptr es:[bx+2],4	; input?
         jne	iomovout		; no, jump

         les	di,dword ptr [dtaoff]	; target
         mov	si,[pgoffset]		; source
         mov	ds,[workaddr]
         jmp	short iomoveit
iomovout:
         mov	es,[workaddr]		; target
         mov	di,[pgoffset]
         lds	si,dword ptr [dtaoff]	; source
iomoveit:

         rep	movsw

         push	cs			; restore ds
         pop	ds
         ret
iomove   endp

progend  label byte			; end of retained code
         page
;------------------ data used by initialization code ----------------

message  label byte
         db	'MOS Ramdisk driver v2.00 with work area at  '  ;@@xlat
work     db    'B4000H',13,10,'$'

nomem    db    'Memory management is required for Ramdisk driver!    ',13,10,'$'  ;@@xlat

badaddr  db    'Invalid work area specified!        ',13,10,'$'  ;@@xlat

memdev   db    '$$MEMDEV',0

msgval	db	'     $'

msgrsize db	'K Ramdisk Created with: ',13,10
	 db	'   $'
msgnsize db	' Sectors of $'
msgssize db	' Bytes.',13,10
	 db	'   $'
msgcsize db	' Sectors per Cluster.',13,10
	 db	'   $'
msgfsize db	' Sectors per Fat.',13,10
	 db	'   $'

         even
memptr   dd     0

         even
dptable  label word
         dw	00255,128,064,1		; kbytes,bps,norde,spc
         dw	00510,128,128,1
         dw	01020,256,256,1
         dw	02040,512,512,1
         dw	04080,512,512,2
         dw	06120,512,512,4
         dw	08160,512,512,4
         dw	10200,512,512,8
         dw	10370,512,512,8		; 20740 sectors is max for 12-bit fat
         dw	16384,512,512,1		; 16-bit fat is implied here
         dw	0ffffh

;-------------------------- volume label ----------------------------

vollabel label byte
         db	'MOS RAMDISK'		; volume name
         db	28h			; attribute
         db	10 dup(0)		; reserved
         dw	6000h			; time - 12:00
         dw	0b81h			; date - 12/01/85
vllength equ   $-vollabel		; length
         page
;--------------------------------------------------------------------
;             initialization code - discarded later
;--------------------------------------------------------------------

init     label near
         mov	byte ptr es:[bx+13],1	; number of units
         mov	word ptr es:[bx+14],offset progend  ; end of driver
         mov	word ptr es:[bx+16],cs

;-------------------- get ramdisk size parameter --------------------

         les	bx,dword ptr es:[bx+18]	; get parameter pointer
ddsloop1:
         inc	bx
         mov	al,es:[bx]		; scan for a blank
         cmp	al,0dh
         jne	ddspace
         jmp	ddsdone			; c/r terminates the string

ddspace:
         cmp	al,20h
         jne	ddsloop1
ddsloop2:
         inc	bx
         cmp	byte ptr es:[bx],20h	; scan for non-blank
         je	ddsloop2

         push	bx
         call	dectobin		; get the number in ax
         cmp	ax,1			; range must be reasonable
         jb	ddsnochg
         cmp	ax,16*1024
         jae	ddsnochg
         mov	[kbytes],ax		; store desired allocation in kilobytes
ddsnochg:
         pop	bx

ddsloop3:
         inc	bx			; scan for first blank after size param
         mov	al, byte ptr es:[bx]	; stops on first ','
         cmp	al, 0dh
         je	ddsdone
         cmp	al, ','
         je	ddsloop4
         cmp	al, ' '
         jne	ddsloop3

ddsloop4:
         inc	bx			; scan for non-blank
         cmp	byte ptr es:[bx], ' '
         je	ddsloop4
         xor	dx, dx			; zero work address
         xor	cx, cx
         xor	ah, ah
         lea	di, work

ddsloop5:
         mov	al, byte ptr es:[bx]	; get hex value
         inc	bx
         cmp	al, '0'
         jb	ddschk
         cmp	al, '9'
         ja	ddshex
         sub	al,'0'
         jmp	short ddsnext

ddshex:
         cmp	al,'a'
         jb	ddshex2
         cmp	al,'f'
         ja	ddschk
         sub	al,'a'-10
         jmp	short ddsnext

ddshex2:
         cmp	al,'A'
         jb	ddschk
         cmp	al,'F'
         ja	ddschk
         sub	al,'A'-10

ddsnext:				; adjust value
         shl	dx, 1
         shl	dx, 1
         shl	dx, 1
         shl	dx, 1
         add	dx, ax
         cmp	al, 10
         jb	ddslow
         add	al, 'A'-10
         jmp	short ddsout

ddslow:
         add	al, '0'

ddsout:
         mov	[di], al
         inc	di
         inc	cx
         cmp	cx, 4
         jb	ddsloop5

ddschk:
         cmp	cl, 4			; for bytes
         jne	ddsbad
         mov	[workaddr], dx		; save value
         jmp	short ddsdone

ddsbad:
         mov	word ptr [work], '4B'	; b400 is default
         mov	word ptr [work+2], '00'

ddsdone:
         mov	dx, [workaddr]
         mov	ax, dx
         and	ax, 0fc00h		; check to see if on 4k boundary
         cmp	ax, dx
         je	ddsgood
         lea	dx, [message]
         mov	ah, 9
         int	21h
         lea	dx, [badaddr]
         int	21h

         jmp	donestat

ddsgood:
;-------------------- locate memory device driver -------------------

         lea	dx, memdev
         mov	ax,3d02h
         int	21h
         jnc	lmem1
         lea	dx,nomem
         mov	ah, 9
         int	21h
         jmp	donestat

lmem1:
         mov	bx,ax
         mov	ax, 4400h
         int	21h
         xor	dh, dh
         or	dl, 20h			; binary mode
         mov	ax, 4401h
         int	21h
         mov	ax, 3f00h
         mov	cx, 4
         lea	dx,memptr
         int	21h
         mov	ah, 3eh
         int	21h
         push	es
         les	bx,memptr
         mov	ax, es:[bx+2]
         mov	word ptr [mroutine+2], ax
         mov	ax, es:[bx]
         mov	word ptr [mroutine], ax
         pop	es

;----------------------- allocate disk space ------------------------

         mov	cx,[kbytes]
         add	cx,3
         shr	cx,1			; convert kbytes to 4k pages
         shr	cx,1

;        code for eems and jram alteration here

	mov	bx,[diskbase]		;rr
	cmp	[dedram],'Y'		;rr  already got dedicated ram?
	je	adsskip			;rr  yes, skip

         mov	ah,1			; allocation function
         call	dword ptr [mroutine]	; call memory management routine
adsskip:
         mov	[diskbase],bx		; store starting page number

         shl	cx,1			; recompute kbytes in case of
         shl	cx,1			;   reduced allocation
         mov	[kbytes],cx

;----------------------- assign disk parameters ---------------------

         mov	ax,[kbytes]
         mov	bx,-8			; table index
dptloop:
         add	bx,8
         cmp	ax,[dptable+bx]		; find table entry for this size range
         ja	dptloop
         mov	ax,[dptable+2+bx]	; bytes per sector
         mov	[bpbbps],ax
         mov	ax,[dptable+4+bx]	; nbr root directory entries
         mov	[bpbnorde],ax
         mov	ax,[dptable+6+bx]	; sectors per cluster
         mov	[bpbspc],al

;-------------------- compute number of sectors ---------------------

         mov	ax,[kbytes]
         shl	ax,1
         shl	ax,1			; convert from kbytes to multiple of 256
         mov	dh,0			; compute number of bytes in dx,ax
         mov	dl,ah
         mov	ah,al
         mov	al,0
         div   [bpbbps]			; compute number of sectors
         mov	[bpbnosec],ax

;-------------- compute number of fat sectors required --------------

         mov	ax,[bpbnosec]
         mov	bl,[bpbspc]		; compute number of clusters
         xor	bh,bh			; = sectors/(sectors per cluster)
         xor	dx,dx
         div   bx

         mov	bx,ax			; compute ax = clusters * 1.5
         cmp	[bpbnosec],20740	;   unless more than 20740 sectors,
         ja	cfatsksh		;   in which case ax = clusters * 2
         shr	ax,1
cfatsksh:
         add	ax,bx			;   giving number of fat bytes

         add	ax,[bpbbps]		; ensure fractions rounded up
         dec	ax
         xor	dx,dx			; divide by bytes per sector
         div   [bpbbps]

         mov	[bpbspf],ax		; giving sectors per fat

;------------------ miscellaneous computations ----------------------

         mov	ax,16*1024		; compute sectors per 16k block
         xor	dx,dx
         div   [bpbbps]
         mov	[secp16k],ax
;------------------------- write boot sector ------------------------

	cmp	[dedkeep],'Y'		;rr  keeping existing ramdisk?
	jne	dobwrite		;rr
	jmp	endofit			;rr  yes, skip these writes
dobwrite:
        xor	ax,ax
        call	misector		; map it in
        mov	si,offset bootrec
        cld

	mov	cx,(bootlen+1)/2	;rr  node systems peculiarity here
	rep	movsw			;rr

;-------------------- write file allocation table -------------------

         mov	dx,[bpbspf]		; number of fat sectors
ifatloop:
         mov	ax,dx
         call	misector
         xor	ax,ax
         mov	cx,[bpbbps]		; sector length
         shr	cx,1
         cld
         push	di
         rep	stosw			; fill it with zeros
         pop	di
         dec	dx
	 jnz	ifatloop		; when done, first fat sector mapped in

        mov	al,[bpbmedia]		; zap in first 3 fat bytes


	mov	ah,0ffh			;rr  node systems peculiarity
	stosw				;rr
	mov	ax,00ffh		;rr

         cmp	[bpbnosec],20740	; zap in another if 16-bit fat entries
         jna	ifatskp1

	mov	ah,al			;rr

ifatskp1:
	stosw				;rr

;----------------------- write root directory -----------------------

         mov	ax,[bpbnorde]		; nbr root dir entries
         mov	cl,5			; times 32
         shl	ax,cl
         dec	ax
         add	ax,[bpbbps]
         xor	dx,dx
         div   [bpbbps]			; compute number of directory sectors
         add	ax,[bpbspf]		; add number of fat sectors
         mov	dx,ax
idirloop:
         mov	ax,dx
         call	misector
         xor	ax,ax
         mov	cx,[bpbbps]		; sector length
         shr	cx,1
         cld
         push	di
         rep	stosw			; fill it with zeros
         pop	di
         dec	dx
         cmp	dx,[bpbspf]
         ja	idirloop		; when done, first dir sector mapped in

;------------------------ write volume label ------------------------

         mov	si,offset vollabel

	mov	cx,(vllength+1)/2	;rr  node systems peculiarity
	rep	movsw			;rr

;------------------------ terminate mapping -------------------------

endofit	label	near		;rr

         mov	ah,4			; self-mapping function
         mov	es,word ptr [workaddr]
         mov	cx,4			; map in 4 4k pages
         call	dword ptr [mroutine]	; call memory management routine

;-------------- set bpb array pointer in request header -------------

         les	bx,dword ptr [rhoff]
         mov	word ptr es:[bx+18],offset bpbpoint
         mov	word ptr es:[bx+20],cs

;----------------------- write copyright notice ---------------------

         mov	ah,9
         lea	dx,[message]
         int	21h

	 mov	ax,[kbytes]
	 mov	dx,offset msgrsize
	 call	dispstat
	 mov	ax,[bpbnosec]
	 mov	dx,offset msgnsize
	 call	dispstat
	 mov	ax,[bpbbps]
	 mov	dx,offset msgssize
	 call	dispstat
	 mov	al,[bpbspc]
	 xor	ah,ah
	 mov	dx,offset msgcsize
	 call	dispstat
	 mov	ax,[bpbspf]
	 mov	dx,offset msgfsize
	 call	dispstat

         jmp	donestat

;----------------- map in a sector for initialization ---------------

misector proc  near
         push	dx
         push	cx
         push	bx
         push	ax

         xor	dx,dx
         div   [secp16k]		; divide by sectors per 16k block
         shl	ax,1			; quotient = 16k block number
         shl	ax,1			; convert to 4k page number
         add	ax,[diskbase]		; add in starting page number
         mov	[pgnumber],ax
         mov	ax,dx
         mul	[bpbbps]		; compute offset into block
         mov	[pgoffset],ax

         mov	ah,3			; remapping function

	cmp	[dedram],'Y'		;rr  physical remap if dedicated ram
	jne	miskded			;rr
	mov	ah,5			;rr
miskded:				;rr

         mov	es,word ptr [workaddr]
         mov	bx,[pgnumber]
         mov	cx,4			; map in 4 4k pages
         call	dword ptr [mroutine]	; call memory management routine

         mov	es,[workaddr]
         mov	di,[pgoffset]

         pop	ax
         pop	bx
         pop	cx
         pop	dx
         ret
misector endp

;--------------------- decimal-to-binary routine --------------------

wordten  dw    10
dectobin proc  near
         xor	ax,ax			; ax will contain the result
dtbloop:				; es:bx is source address
         mov	dl,es:[bx]
         cmp	dl,'0'
         jb	dtbwrap
         cmp	dl,'9'
         ja	dtbwrap
         push	dx
         mul	[wordten]
         pop	dx
         and	dx,000fh
         add	ax,dx
         inc	bx
         jmp	dtbloop
dtbwrap:
         ret
dectobin endp

;--------------------- binary-to-decimal routine --------------------
bintodec proc
	push	cx
btdloop1:
	div   [wordten]			; dx:ax is source integer
	add	dl,'0'			; cx is length of target
	mov	[bx],dl			; bx is end of target
	dec	bx
	xor	dx,dx
	loop	btdloop1
	pop	cx
btdloop2:
	inc	bx
	dec	cx
	jz	btdret
	cmp	byte ptr [bx],'0'
	jne	btdret
	mov	byte ptr [bx],' '
	jmp	btdloop2
btdret:
	ret
bintodec endp


dispstat proc	near
	 push	dx
	 xor	dx,dx
	 mov	word ptr [msgval],'00'
	 mov	word ptr [msgval+2],'00'
	 mov	byte ptr [msgval+4],'0'
	 mov	bx,offset msgval+4
	 mov	cx,5
	 call	bintodec
	 mov	bx,offset msgval
dstatlp:
	cmp	byte ptr ds:[bx],' '
	jne	dstatdn
	inc	bx
	jmp	short dstatlp
dstatdn:
	mov	dx,bx
	mov	ah,9
	int	21h
	pop	dx
	mov	ah,9
	int	21h
	ret
dispstat endp

mainseg  ends
         end   begin
