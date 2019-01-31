comment ^===============================================================
		      development specification

 program name:	biosload.inc			assigned to: Stewart Hyde
 module name:					assign date: 08/15/91
 entry points:					completed:   10/10/91
 entry from:	unterm.sys, vgna.sys and other workstations
 entry method:	call 
 calls: 	
 purpose:	vga bios laoder
 refer to:	stewart hyde, biosload.doc
 last update:	10/10/91

The following variables are require to be place in workstation terminal
driver's resident source code area.

vmemcall	dd	0		; memory management handler
scbptr		dd	0		; pointer to scb already initialized

INITVBIOS

Input:  DX - name of file to load
	BX - offset of word for storing bios information
	     offset 0  word -  memory manger handler (INIT to 0ffffh)
	     offset 2  word -  size of video rom in bytes
	SI - Patch Table (For on the fly patching) (-1, means no patch table)
	AL=00  Non-coexistent system  (VGNA+ Only)
	AL=NON 00 - co-exiitent system

Output:  AL - error code if carry is set
	 AL=01  - file could not be found
	 AL=02  - non-memory management system
	 AL=03  - could not allocated extended memory
         AL=04  - error reading file
	 AL=05  - file size is not correct
         AL=06  - requires PC-MOS 4.10 or higher
         AL=07  - driver can't be loaded task specifically
	 AL=ffh - internal error (Patch Table wrong)


Patch Table Layout

Patch table will contain a list of variable size requires

kthe following is structure of record

offset:   size:		description
---------------------------------------------------------
  0	   1		Bank Page #, which 4K it will be (up to 7)
			255 will cause it to abort
  1        2            offset of page for patch
  3        1		no of bytes in patch
  4	   varies	patch values
	



MAPVBIOS 

Input:   AL=00   	Map Bios in
	 AL=NON 00	Map Bios Out



DISPVERR

Input:
	AL=error code
	SI=driver name
	DX=filename
	AL= 01  File could not be found	
	AL= 02  Memory Management not installed
	AL= 03  Not enough Extended memory
        AL= 04  error reading file
	AL= 05  file size is not correct
        AL= 06  requires PC-MOS 4.10 or higher
        AL= 07  driver can't be loaded task specifically
	AL= FF	Internal Error (Patch Table Not Valid)


If ROM- co-existence is desired, then the following routines will 
will also be required



-----------------------------------------------------------------------------	

The following is technique to created device driver to support bios loading
to c000 area.

1.  Device driver data must include the following data items

    vmemcall	dd	0		; memory management handler
    scbptr	dd	0		; pointer to scb already initialized

2.  Before parsing command parameters, us must make a call to GetCurDir
    with DS:SI-> to command line for device driver parsing

3.  The following is recommended code for loading bios off of disk and
    loading it into extended memory and displaying approviate error message

	mov	dx  <-- [offset to ascii string of rom's file name]
	mov	si, <-- [offset of patch table, or -1 if no patches]
	mov	bx, <-- [offset to drivers bios infomation table]

	xor	al,al			; indicate VGNA+ master console
	cmp	[ws0ismc],'Y'
	je	doinitv
	dec	al			; indicate coexistence system
doinitv:
	call	initvbios		; init VBIOS	
	jnc	skipbios
;
; display approviate driver specific error message
;
	mov	si, <-- [offset to ascii string for drivers name]
	call	dispverr		; display error message

	jmp     --> [to driver error handler]
skipbios:


3.      If ROM- co-existence is desired, then the following steps will 
        will also be required

	1.   include biosres.inc in your drivers resident portion. 
	     This will include resident code to switch bios's on the fly

	2.   make a call to InstallContext after everything has been
	     initialized

	3.   if desired to optionally turn off Biosres interception of
	     int 10h, bl=32h bios emulation of turning on and off the
 	     vga define a [slashb] byte in main terminal driver. Set
	     [slashb] to 'Y' to skip
	
-----------------------------------------------------------------------------	

=======================================================================
======================================================================^

if1
	%out	***************************************************
    ifdef BIOSRES
	%out	*  BIOSLOAD.INC (RES) Code Included    10/10/91
    else
	%out    *  BIOSLOAD.INC  Code Included         10/10/91 
    endif
	%out	***************************************************
endif

			public	$$BIOSLOAD_START
$$BIOSLOAD_START 	label	byte

;-----------------------------------------------------
; BIOSLOAD .INC specific data areas
;-----------------------------------------------------

NOVFILE		equ	01h
NOVMEMMAN	equ	02h
NOVMEM		equ	03h
VINITFERR	equ	04h
NOVSIZE		equ	05h
VNOTMOS		equ	06h
VNOTGLOB	equ	07h
VLASTERRNO	equ	VNOTGLOB
VINITINT	equ	0ffh

MappingArea	dw	0b400h		; mapping area
RomArea		dw	0c000h		; ROM area
vfilesize	dw	0		; file size calcuated 
					; by CheckVFile
VInitInfo	dw	0		; use store information about
					; bios
VPatchInfo	dw	-1		; patch list,
					;    (-1, means no patch table)
VMemHandle	dw	-1		; MM Handle  (-1 means not allocated)
VNoMMPages	dw	0		; No of memory mangement pages
VPatchErr	db	'N'		; patch error happen
Mos_Version	dw	-1		; MOS Version
BiosLoad	db	00h		; bios not loaded

LoadDir	db	65 dup (0)
LoadPath db	65 dup (0)

msgverr	db	' Virtual Bios Manager Error: $       '		; @@XLAT
msgvcrlf db	13,10,'$'
msgvfile db	' could not be found.            $'		; @@XLAT
msgvmm	db	' Memory Management is required.        $'	; @@XLAT
msgvmem db	' Not enough Extended Memory.          $'	; @@XLAT
msgvint	db	' Internal Error        $'			; @@XLAT
msgvferr db	' Error Reading $             '			; @@XLAT
msgvfsiz db	' file size is not correct.         $'		; @@XLAT
msgvmos	 db	' PC-MOS 4.10 or higher required.        $'	; @@XLAT
msgvglob db	' Driver must be loaded globally.        $'	; @@XLAT


;-----------------------------------------------------
; BIOSLOAD .INC specific code areas
;-----------------------------------------------------


;------------------------------------------------------
;
; MAPVBIOS 
;
; Input:   AL=00   	Map Bios in
;          AL=NON 00	Map Bios Out
;
;------------------------------------------------------

MAPVBIOS	proc	near
	or	al,al
	jnz	MapOut
	mov	ah,3
	push	es
	mov	bx,[VMemHandle]
	mov	cx,[VNoMMPages]
	mov	es,[RomArea]
	call	[vMemcall]
	pop	es
	ret
MapOut:
	push	es
	mov	ah,4
	mov	cx,[VNoMMPages]
	mov	es,[RomArea]
	call	[vMemcall]
	pop	es
	ret
MAPVBIOS	endp

;------------------------------------------------------
; CHECKVMEMMAN
;
; return carry set if memory management is not available
;------------------------------------------------------

CheckVMemMan	proc	near
	push	si
	push	ds
	lds	si,[scbptr]		
	assume	ds:gdata
	cmp	[si+scbmmfg],'Y'
	jne	NoMemdev
	mov	ax,word ptr [si+scbmmsub]
	mov	word ptr cs:[vmemcall],ax
	mov	ax,word ptr [si+scbmmsub+2]
	mov	word ptr cs:[vmemcall+2],ax
	pop	ds
	assume	ds:nothing
	pop	si
	clc
	ret
NoMemDev:
	pop	ds
	pop	si
	stc
	ret
CheckVMemMan	endp


;------------------------------------------------------
; MOVEIT
;
; This is an internal procedure for processing file names
; to create path for ROM files
;
;------------------------------------------------------

moveit	proc	near
	lodsb
	or	al,al
	jz	moveexit
	stosb
	jmp	short moveit
moveexit:
	ret
moveit	endp

;------------------------------------------------------
; VerVFile
;
; Verify that file in [LoadPath] exist and if so, get
; size of file using function 42h
;
;------------------------------------------------------

VerVFile proc	near
	push	dx
	mov	dx,offset LoadPath
	mov	ax,3d00h
	int	21h
	jc	VFExit
	mov	bx,ax
	mov	ax,4202h
	xor	cx,cx
	xor	dx,dx
	int	21h
	jc	CloseIt
	mov	[VFileSize],ax
	or	dx,dx
	jz	CloseOK
	mov	[VFileSize],-1		; mark it has error
CloseOk:
	clc
CloseIt:	       	
	pushf
	mov	ah,3eh
	int	21h
	popf
VFExit:
	pop	dx
	ret
VerVFile endp

;------------------------------------------------------
; CHECKVFILE
;
; Check to see if rom file is on disk, 1st check to see
; if loaded in drivers directory, then if not found 
; check boot drives root directory.
;
;------------------------------------------------------

CheckVfile	proc	near
	push	si
	push	di
	push	es

	push	cs
	pop	es
;
; First check device drivers path to check for file
;
	mov	di,offset LoadPath
	mov	si,offset LoadDir
	call	moveit
	mov	si,dx
	call	moveit
	xor	al,al
	stosb
	call	VerVFile
	jnc	CheckVexit
;
; Not found in drivers directory, so check current directory
;
	mov	di,offset LoadPath
	mov	si,dx
	call	moveit
	xor	al,al
	stosb
	call	VerVFile
CheckVexit:
	pop	es
	pop	di
	pop	si
	ret
CheckVFile	endp

;------------------------------------------------------
; CHECKVMEMORY
;
; For calcuating remaining no of pages in memory, allocated 
; [VNoMMPages] from memory manager.
;------------------------------------------------------

CheckVMemory	proc	near
	mov	ah,1
	mov	cx,[VNoMMPages]
	call	[vMemcall]
	or	ax,ax
	jnz	CMMFailed
	cmp	cx,[VNoMMPages]
	jne	CMMFailed
	mov	[VMemHandle],bx
	push	si
	mov	si,[VInitInfo]
	mov	word ptr cs:[si],bx
	pop	si
	clc
	ret
CMMFailed:
	or	cx,cx
	jz	CMMZero
	mov	ah,2
	call	[vMemcall]
CMMZero:
	stc
	ret
CheckVMemory	endp

;------------------------------------------------------
; VPATCHBIOS
;
; [VPatchInfo] is a pointer to the following structure
; AL= Bank# in memory
;
; offset:   size:		description
; --------------------------------------------------------
;   0	     1		Bank Page #, which 4K it will be (up to 7)
;			255 will cause it to abort
;   1        2          offset of page for patch
;   3        1		no of bytes in patch
;   4	   varies	patch values
;	
;------------------------------------------------------

VPatchBios	proc	near
		push	ax
		cmp	[VPatchInfo],-1		; is patch list loaded
		je	VPBSkip
		push	cx												
		push	si
		push	di
		push	es
		mov	si,[VPatchInfo]
VPBLoop:
		cmp	byte ptr cs:[si],-1
		je	VPBExit
		mov	cl,byte ptr cs:[si]
		xor	ch,ch
		cmp	cx,[VNoMMPages]		; if invalid patch list 
		jae	VPBError		; --> then error
		cmp	al,cl			; same page???
		jne	VPBNext
		push	si
		mov	di,word ptr cs:[si+1]
		cmp	di,4096	 		; area to big
		jae	VPBSizErr
		mov	cl,byte ptr cs:[si+3]	; get size of patch
		or	cl,cl
		jz	VPBSizErr		; if no byte than error
		add     di,cx		
		cmp	di,4096			; area too big
		jae	VPBSizErr
		sub	di,cx
		add	si,4			; point to patch error
		push	ds
		push	cs
		pop	ds
		cld
		rep	movsb
		pop	ds
		pop	si
VPBNext:
;
; Point to next idem on patch list
;
		add	si,3
		mov	cl,byte ptr cs:[si]
		xor	ch,ch
		inc	si
		add	si,cx
		jmp	short VPBLoop		
VPBExit:		  	
		pop	es
		pop	di
		pop	si
		pop	cx
VPBSkip:
		pop	ax
		clc
		ret
VPBSizErr:
		pop	si
VPBError:
		mov	[VPatchErr],'Y'
		pop	es
		pop	di
		pop	si
		pop	cx
		pop	ax
		stc
		ret
VPatchBios	endp

;------------------------------------------------------
; LOADVBIOS
;
; This procedure will load bios 4K chunks at the time
; into [MappingArea - currently located at b400h] and
; for each 4k chunk it will check patch list to see if 
; it needs to patch the area.
;
;------------------------------------------------------

LoadVBios	proc	near
	push	ax
	push	dx
	mov	dx,offset LoadPath
	mov	ax,3d00h
	int	21h
	jc	LVExit
	mov	bx,ax
	mov	cx,[VNoMMPages]		; get number of memory management pages
	xor	ax,ax			; start with first page
LVLoop:
	push	ax
	push	cx
;
; Map in Page to b400h
;
	push	bx
	mov	es,[MappingArea]
	mov	cx,1
	mov	bx,[VMemHandle]
	add	bx,ax
	push	ax
	mov	ah,3
	call	[vMemcall]
	pop	ax
	pop	bx
;
; Load page of memory off disk
;
	push	ax
	mov	ah,3fh
	mov	cx,4096
	xor	dx,dx
	push	ds
	mov	ds,[MappingArea]
	int	21h
	pop	ds
	pop	ax
	jc	SkipPatch		; if error, don't patch
	call	VPatchBios		; patch bios if necessary		
SkipPatch:


	pop	cx	
	pop	ax
	pushf
	inc	ax
	popf
	jc	LVSkip
	loop	LVLoop	
LVSkip:
	pushf
;
; UnMap page at 0b400h
;
	push	bx
	push	es
	mov	es,[MappingArea]
	mov	cx,1
	mov	ah,4
	call	[vMemcall]
	pop	es
	pop	bx
;
; Close file 
;
	mov	ah,3eh
	int	21h
	popf
LVExit:
	pop	dx
	pop	ax
	ret
LoadVBios	endp

;------------------------------------------------------
;
; CALCMMPAGES
;
; Calculate no of pages for Memory Mangement
;------------------------------------------------------

CalcMMPages	proc	near
	push	ax
	mov	ax,[VFileSize]
	mov	al,ah
	xor	ah,ah	     		; pages = filesize / 4096
	shr	ax,4
	mov	[VNoMMPages],ax	
	pop	ax
	ret
CalcMMPages	endp

;------------------------------------------------------
;
; INITVBIOS
;
; Input:  DX - name of file to load
;  	  BX - offset of word for storing bios information
;	       offset 0  word -  memory manger handler (INIT to 0ffffh)
;	       offset 2  word -  size of video rom in bytes
;	  SI - Patch Table (For on the fly patching)
;	       (-1, means no patch table)
;	  AL=00  Non-coexistent system  (VGNA+ Only)
;	  AL=NON 00 - co-existent system
;
; Output:  AL - error code if carry is set
;          AL=01  - file could not be found
;   	   AL=02  - non-memory management system
;	   AL=03  - could not allocated extended memory
;	   AL=04  - error reading file
;     	   AL=05  - file size is not correct
;	   AL=06  - requires PC-MOS 4.10 or higher
;	   AL=07  - driver can't be loaded task specifically
;	   AL=ffh - internal error (Patch Table wrong)
;
;-------------------------------------------------------

INITVBIOS	proc	near
	mov	[VInitInfo],bx		; save for later checks
	mov	[VPatchInfo],si		; ""
;
;	we will first need to check if we are on MOS or user
;	attempted to loaded device driver task specifically
;
	call	VCheckMOS	
	jnc	InitV0
	ret
InitV0:
;
;	we will first check to see we are running on memory mangement
;
	call	CheckVMemMan		; check for memory management
	jnc	InitV1
	mov	al,NOVMEMMAN
	ret
InitV1:
;
; 	now we must check to see if file is on disk
;
	call	CheckVFile
	jnc	InitV2
	mov	al,NOVFILE
	ret
InitV2:
;
;	check to see if file size is correct
;
	push	si
	push	ax
	mov	si,[VInitInfo]
	mov	al,VINITINT
	cmp	word ptr cs:[si],0ffffh
	jne	InitV2e
	mov	ax,word ptr cs:[si+2]
	cmp	ax,[VFileSize]
	je	InitV2a
	mov	al,NOVSIZE
InitV2e:
	pop	si
	pop	si
	stc
	ret
InitV2a:
	pop	ax
	pop	si
;
;	now we must check to see if we have available memory
;       if we do have available memory we will need to allocated memory
;	for storing bios into extended memory
;
	call	CalcMMPages	; calcuate Memory Management Pages
	call	CheckVMemory	
	jnc	InitV3
	mov	al,NOVMEM
	ret
InitV3:
;
;	Everything appears to be ok, so we must load video off of disk
;
	call	LoadVBios		; Load VBios off of disk
	jc	InitVExit		; if error exit
	or	al,al
	jnz	InitVOk
	call	MapVBios		; map video Bios in
InitVOk:
	clc
	ret
InitVExit:
	mov	al,VINITINT
	cmp	[VPatchErr],'Y'
	je	InitVExit2
	mov	al,VINITFERR
InitVExit2:
	stc
	ret
INITVBIOS 	endp

;-------------------------------------------------------
;
; DISPVERR
;
; Input:
;	AL=error code
;  	BX=  offset of bios information
;	       offset 0  word -  memory manger handler (INIT to 0ffffh)
;	       offset 2  word -  size of video rom in bytes
;	SI=driver name
;	DX=filename
;	AL= 01  File could not be found	
;	AL= 02  Memory Management not installed
;	AL= 03  Not enough Extended memory
;	AL= 04  error reading file
;	AL= 05  file size is not correct
;	AL= 06  requires PC-MOS 4.10 or higher
;	AL= 07  driver can't be loaded task specifically
;	AL= FF	Internal Error (Patch Table Not Valid)
;	
;-------------------------------------------------------

DISPVERR	proc	near
	push	dx
	push	si

	push	ax
	push	dx

	cmp	[VMemHandle],-1
	je	skipfreehand
	push	bx
	push	cx
	mov	bx,[VMemHandle]
	mov	cx,[VNoMMPages]
	mov	ah,2
	call	[vMemcall]
	pop	cx
	pop	bx
skipfreehand:	

	cld
dverrdv:
	lodsb
	or	al,al
	jz	dverrdve
	mov	dl,al
	mov	ah,2
	int	21h
	jmp	short dverrdv
dverrdve:
	mov	dx,offset msgverr
	mov	ah,9
	int	21h
	pop	dx
	pop	ax

	mov	si,dx	
	cmp	al,NOVSIZE
	je	dverrst
	cmp	al,NOVFILE
	jne	dverr1
dverrst:
	push	ax
dverrlp:
	lodsb
	or	al,al
	jz	dverrex
	mov	dl,al
	mov	ah,2
	int	21h
	jmp	short dverrlp
dverrex:
	pop	ax
	mov	dx,offset msgvfile
	cmp	al,NOVFILE
	je	dverrend
	mov	dx,offset msgvfsiz
	cmp	al,NOVSIZE
	je	dverrend
dverr1:
	mov	dx,offset msgvmm
	cmp	al,NOVMEMMAN
	je	dverrend
	mov	dx,offset msgvmem
	cmp	al,NOVMEM
	je	dverrend
	mov	dx,offset msgvferr
	cmp	al,VINITFERR
	je	dverrend
	mov	dx,offset msgvmos
	cmp	al,VNOTMOS
	je	dverrend
	mov	dx,offset msgvglob
	cmp	al,VNOTGLOB
	je	dverrend
	mov	dx,offset msgvint
dverrend:
	push	ax
	mov	ah,9
	int	21h
	pop	ax
	cmp	al,VINITFERR
	jne	dvnotferr
dverrlp2:
	lodsb
	or	al,al
	jz	dvnotferr
	mov	dl,al
	mov	ah,2
	int	21h
	jmp	short dverrlp2
dvnotferr:
	mov	dx,offset msgvcrlf
	mov	ah,9
	int	21h

	pop	dx
	pop	si	
	ret
DISPVERR	endp

;-------------------------------------------------------
; GETCURDIR 
;
; Retrieves directory where device driver is loaded
;-------------------------------------------------------

GetCurDir proc	near
	push	es
	push	bx
	push	si

	push	cs
	pop	es
	cld
	mov	di,offset LoadDir
	mov	bx,di
GCDLoop:
	lodsb
	cmp	al,'$'
	je	GCDExit
	cmp	al,' '
	je	GCDexit
	cmp   	al,13
	je	GCDexit
	stosb
	cmp	al,':'
	je	GCDSetBX
	cmp	al,'\'
	jne	GCDLoop
GCDSetBX:
	mov	bx,di
	jmp	short GCDloop
GCDExit:
	mov	di,bx
	xor	al,al
	stosb

	pop	si
	pop	bx
	pop	es
	ret
GetCurDir endp

;-------------------------------------------------------
; VCheckMOS
;
; Check for PC-MOS, saves version for lator
;-------------------------------------------------------


VCheckMOS proc	near
	 push	bx
	 push	cx
	 push	dx
	
	 mov	ax,3000h
	 mov	bx,ax
	 mov	cx,ax
	 mov	dx,ax
	 int	21h
	 push	ax
	 mov	ax,30ffh
	 int	21h
	 pop	bx
	 cmp	ax,bx
	 je	BadMos
	 xchg	bl,bh		
	 cmp	bx,040ah
	 jb	BadMos
	 mov	[Mos_Version],bx
	 mov	dx,cs
	 mov	ah,25h
	 int	0d4h
	 or	ax,ax
	 jz	BadSmp
	 clc
	 pop	dx
	 pop	cx
	 pop	bx		 
	 ret
BadSmp:
	 pop	dx
	 pop	cx
	 pop	bx		 
	 mov	ax,VNOTGLOB
	 stc
	 ret
BadMos:
	 pop	dx
	 pop	cx
	 pop	bx		 
	 mov	ax,VNOTMOS
	 stc
	 ret	 
VCheckMOS endp


;
; The following section of code is contionally assemble in if BIOSRES.INC
; was include in source prior to including biosload.inc
;


ifdef	BIOSRES

			public	$$BIOSLOAD_RES
$$BIOSLOAD_RES 	label	byte

;-----------------------------------------------------
; BIOSLOAD .INC (RES) specific data areas
;-----------------------------------------------------


I10OLD_OFFSET   equ	01EE0h

MosOrg10Vect	dd	0	; Pointer to MOS's orginal data location
				; where we store a pointer to Bios's original
				; INT 10h vector

;-----------------------------------------------------
; BIOSLOAD .INC (RES) specific code areas
;-----------------------------------------------------

;-------------------------------------------------------
;
; INSTALLCONTEXT
;
; This procedure installs Kernel hooks for context 
; switching of Video BIOS's
;-------------------------------------------------------

InstallContext proc	near
	cmp	[BiosLoad],00h		; is this NON-Co-existence
	jne	DoInsCnt
	ret
DoInsCnt:
       push	es	
       push	ds
       push	si


       call	MapInitBiosOut		; map bios out
       call	SaveBios		; initialize bios pointers	
  
;
; Set Vector to InitVidINT10
;
	mov	cx,cs
	mov	dx,offset NewOrg10
	call	SetVidVector
;
	       	
       lds	si,[ScbPtr]
       cmp	cs:[Mos_Version],040ah
       jne	DoNewKernel		
       mov	ax,ds:[si+SCBMOSADR]
       mov	es,ax
       cmp	word ptr es:[CHKPATCH],CHKVALUE
       jne	DoNewKernel
;
; Handle shiping 410 code here
;
	push	di
 	cld
	mov	di,SAVEPATCH
	mov	al,FARCALL
	cli
	stosb			
	mov	ax,offset BiosSave
	stosw
	mov	ax,cs
	stosw
	mov	ax,SAVEJMP
	stosw					
	mov	di,RESTPATCH
	mov	al,FARCALL
	stosb			
	mov	ax,offset BiosRestore
	stosw
	mov	ax,cs
	stosw
	mov	ax,RESTJMP
	stosw					
	sti
	pop	di
	jmp	short InstallDone
;
; Handle code later than shipping kernel here, or code that already
; dynkamcally patch.  I.E. EMS 4.0 driver
;

DoNewKernel:
       mov	ax,word ptr ds:[si+SCBSAVE]
       mov	word ptr cs:[OldSave],ax						
       mov	ax,word ptr ds:[si+SCBSAVE+2]
       mov	word ptr cs:[OldSave+2],ax						
       mov	ax,word ptr ds:[si+SCBRESTORE]
       mov	word ptr cs:[OldRestore],ax						
       mov	ax,word ptr ds:[si+SCBRESTORE+2]
       mov	word ptr cs:[OldRestore+2],ax						
       cli
       mov	word ptr ds:[si+SCBSAVE],offset BiosSave
       mov	word ptr ds:[si+SCBSAVE+2],cs
       mov	word ptr ds:[si+SCBRESTORE],offset BiosRestore
       mov	word ptr ds:[si+SCBRESTORE+2],cs				
       sti	
InstallDone:
       pop	si
       pop	ds
       pop	es			
       ret	
InstallContext endp

;-------------------------------------------------------
;
; INITCONTEXT
;
; Input:
; 	DS:SI-> Pointer to user definable port table for
;	        handing initializing of context areas
;
; 	Port Table Structure  is for each work station which 
;	       is loaded on system		
;		
;	CX   -> Number of entries in port table	   (MAX 128)
;	DS:DI-> Pointer to user definable mapping table
;
;       Mapping Table Structure
;
;		MapSegment	dw	(Mapping Area)
;		MemHandle	dw	(Memory Mangement Handle)
;		MapBanks	db	(# of Mapping Banks)
;		MapReserve      db      (reserved)
;		MapINT10	dd	(Mapping INT 10 Vector)
;
;	BX    -> Number of Mapping Entries avaiable (MAX 4)
;	
;-------------------------------------------------------

InitContext proc 	near
	mov	[BiosLoad],-1
	push	bx
	push	cx
	push	es

	push	ds
	pop	es

	cmp	cx,VMAX_PORT
	jbe	ICont1
	mov	cx,VMAX_PORT
ICont1:
	mov	[VPortEntry],cx
	cmp	bx,VMAX_MAP
	jbe	ICont2
	mov	bx,VMAX_MAP
ICont2:
;
;	move Port Table
;
	push	di
	mov	di,offset VPortTable
	rep	movsb
	pop	si
;
;	move Map Table
;    
	mov	di,offset VMapTable
	mov	cx,bx
IContLp:
	push	cx
	mov	cx,SIZEOF_MAP/2		; each entry is 30 bytes (15 words)
	rep	movsw
	pop	cx
	loop	IContLp
;
; for each mapping table entry Write protected memory location
;
	mov	cx,bx
	mov	di,offset VMapTable
IContlp2:
	push	cx
	mov	bx,word ptr cs:[di+VMAPHAND]
	add	bx,110h
	mov	cl,byte ptr cs:[di+VMAPBANK]
	xor	ch,ch
	mov	ah,06h
	call	[vMemCall]
	pop	cx
	add	di,SIZEOF_MAP
	loop	IContlp2

	pop	es
	pop	cx
	pop	bx
	ret
InitContext endp


;-------------------------------------------------------
;
; SETVIDVECTOR
;
; Input:
;      cs:dx -> segment:offset to INT 10 redirector
;	
;-------------------------------------------------------


SetVidVector proc	near
	push	ds
	push	si
	push	di

	cmp	word ptr [MosOrg10Vect],0
	jne	SVVect1
        lds	si,[ScbPtr]
        cmp	cs:[Mos_Version],040ah
        je	SV410
	lds	si,ds:[si+scbi10old]
	jmp	short SVNew
SV410:
	mov	di,I10OLD_OFFSET
	add	si,di
SVNew:
	mov	word ptr cs:[MosOrg10Vect],si		
	mov	ax,ds
	mov	word ptr cs:[MosOrg10Vect+2],ax		
	mov	ax,word ptr [si]
	mov	word ptr cs:[Org10Vector],ax
	mov	ax,word ptr [si+2]
	mov	word ptr cs:[Org10Vector+2],ax
SVVect1:
	lds	si,cs:[MosOrg10Vect]
	mov	word ptr [si],dx
	mov	word ptr [si+2],cx

	pop	di
	pop	si	
	pop	ds
	ret
SetVidVector endp
	


;-------------------------------------------------------
;
; INITVIDINT10
;
; Init time, INT 10 vector use to passon to workstations
; INT 10h Bios when dealling with the co-existence case
;	
;-------------------------------------------------------

InitVidINT10:
	jmp	cs:[Int10Vector]


;-------------------------------------------------------
;
; MAPINITBIOSIN
;
; This procedure is use at INIT time to map in 
; workstations bios during initialization of BIOS's 
; video.
;
; DS:DI -> Pointer to BIOS's Mapping Table Structure
;
;         Mapping Table Structure
;
;		MapSegment	dw	(Mapping Area)
;		MemHandle	dw	(Memory Mangement Handle)
;		MapBanks	db	(# of Mapping Banks)
;		MapReserve      db      (reserved)
;		MapINT10	dd	(Mapping INT 10 Vector)
;		MapINT1D	dd	(Mapping INT 1D Vector)
;		MapINT1F	dd	(Mapping INT 1F Vector)
;		MapINT43	dd	(Mapping INT 43 Vector)
;		MapINT6D	dd	(Mapping INT 6D Vector)
;		MapBios4a8	dd	(Mapping Bios location 40:a8)
;
;	
;-------------------------------------------------------

MapInitBiosIn proc	near
	cmp	[BiosLoad],00h		; is this NON-Co-existence
	jne	DoMapIn
	ret
DoMapIn:
	push	ax
	push	cx
	push	dx
;
;	map segment in
;
	cli
	mov	ax,[di+VMAPSEG]
	mov	cs:[RomArea],ax
	mov	ax,[di+VMAPHAND]
	mov	cs:[VMemHandle],ax
	mov	al,[di+VMAPBANK]
	xor	ah,ah
	mov	cs:[VNoMMPages],ax
	xor	ax,ax			  	; Map Bios IN
	call	MapVBios
	mov	ax,word ptr [di+VMAPINT10]
	mov	word ptr cs:[Int10Vector],ax
	mov	ax,word ptr [di+VMAPINT10+2]
	mov	word ptr cs:[Int10Vector+2],ax
;
; Set Vector to InitVidINT10
;
	mov	cx,cs
	mov	dx,offset InitVidINT10
	call	SetVidVector
	sti

	pop	dx
	pop	cx
	pop	ax
	ret
MapInitBiosIn endp

;-------------------------------------------------------
;
; MAPINITBIOSOUT
;
; This procedure is use at INIT time to map out 
; workstations bios during initialization of BIOS's 
; video.  Bios pointers will return to Machines host
; Bios
;
;-------------------------------------------------------

MapInitBiosOut proc	near
	cmp	[BiosLoad],00h		; is this NON-Co-existence
	jne	DoMapOut
	ret
DoMapOut:
	push	ax
	push	cx
	push	dx
;
;       Map Bios out
;
	cli
	mov	al,0ffh			; Map Bios Out
	call	MapVBIOS
;
; Set Vector to Orginal INT 10h Bios
;
	mov	cx,word ptr cs:[Org10Vector+2]
	mov	dx,word ptr cs:[Org10Vector]
	call	SetVidVector
	sti

	pop	dx
	pop	cx
	pop	ax
	ret
MapInitBiosOut endp

endif

			public	$$BIOSLOAD_END
$$BIOSLOAD_END 		label	byte


