
comment ^===============================================================
		      development specification

 program name:	biosres.inc			assigned to: Stewart Hyde
 module name:					assign date: 08/29/91
 entry points:					completed:   10/10/91
 entry from:	unterm.sys, vgna.sys and other workstations
 entry method:	call 
 calls: 	
 purpose:	vga bios laoder
 refer to:	stewart hyde, biosload.doc
 last update:	10/10/91

-----------------------------------------------------------------------------	

=======================================================================
======================================================================^


if1
	%out	***************************************************
	%out    *  BIOSRES.INC  Code Included          10/10/91 
	%out	***************************************************
endif

			public	$$BIOSRES_START
$$BIOSRES_START 	label	byte


;-----------------------------------------------------
; BIOSRES.INC specific data areas
;-----------------------------------------------------

;
; define BIOSRES  equate so BIOSLOAD.INC will include portions of
; code that will installed resident portion of bios swapping code
;

BIOSRES		equ	1		
VMAX_PORT	equ	128
;
; if you change the following equate - VMAX_MAP
; then please look at VMapIndex
;
VMAX_MAP	equ	4
SIZEOF_MAP	equ	30

VMAPSEG		equ	0	
VMAPHAND	equ	2
VMAPBANK	equ	4
VMAPINT10	equ	6
VMAPINT1D	equ	10
VMAPINT1F	equ	14
VMAPINT43	equ	18
VMAPINT6D	equ	22
VMAPOFF4A8	equ	26


FARCALL	   	equ  9ah
SAVEPATCH  	equ  8242h
SAVEJMP	   	equ  10ebh
RESTPATCH  	equ  83ceh
RESTJMP	   	equ  14ebh
CHKPATCH   	equ  8255h
CHKVALUE   	equ  67cdh

MapRom		dw	  -1		; map rom
MapBanks	dw	  -1		
OldSave	   	dd	  0		; old context save routine
OldRestore 	dd        0		; old context restore routine													
		public    Int10Vector
Int10Vector 	dd  	  0		; Int 10 Vector to jmp to 
Org10Vector 	dd	  0		; Master console INT 10 vector to jump to
CurrentBios 	db   	 -1		; Current Bios Entry Loaded (-1 if none)
DesiredBios	db	 -1		; desired Bios Entry to load

VPortEntry  	dw	  0		; # of port table entrys - MAX 128
VMapEntry   	dw	  0		; # of mapping table entrys - MAX=4
VPortTable  	db  VMAX_PORT dup (-1)	; Port Table for mapping information
VMapTable   	db  VMAX_MAP*SIZEOF_MAP dup (-1) ; Mapping Table  

VMapIndex	db  0
		db  SIZEOF_MAP
		db  SIZEOF_MAP*2
		db  SIZEOF_MAP*3	; Assumes VMAX_MAP=4 for speed

off1d		dw	0		; original int 1d offset
seg1d		dw	0		; original int 1d segment
off1f		dw	0		; original int 1f offset
seg1f		dw	0		; original int 1f segment
off43		dw	0		; original int 43 offset
seg43		dw	0		; original int 43 segment
off6d		dw	0		; original int 6d offset
seg6d		dw	0		; original int 6d segment
off4a8		dw	0		; bios word at 40:a8h
seg4a8		dw	0		; bios word at 40:aah

;-----------------------------------------------------
; BIOSRES.INC specific code areas
;-----------------------------------------------------
	assume  ds:nothing,es:tcb

;------------------------------------------------------
; GetCurBios - return nonzero if we need to change bios
;------------------------------------------------------

GetCurBios proc	near
	push	ax
	push	bx

	call	GetCurPort
	mov	al,-1
	cmp	bl,VMAX_PORT			; if above table set max	
	ja	GCBMax
	mov	al,cs:[bx+VPortTable]		; get bios port indentifier
GCBMax:
	cmp	[CurrentBios],al		; check bios
	mov	[DesiredBios],al		; save as desired bios
GCBExit2:	

	pop	bx
	pop	ax
	ret
GetCurBios endp

SaveBios proc	near
	push	ax
	mov	ax,word ptr [Org10Vector]
	mov	word ptr [Int10Vector],ax
	mov	ax,word ptr [Org10Vector+2]
	mov	word ptr [Int10Vector+2],ax
	mov	[CurrentBios],-1		; indicate no bios switch in
	cmp	[MapRom],-1
	jne	SBios1
	jmp	SBiosSkip
SBios1:
	push	cx
	push	es
	
	mov	es,[MapRom]
	mov	cx,[MapBanks]
	mov	ah,4
	call	[vMemcall]
	mov	[MapRom],-1

	xor	ax,ax
	mov	es,ax
	cli
	mov	ax,cs:[off1d]
	mov	word ptr es:[1dh*4],ax
	mov	ax,cs:[seg1d]
	mov	word ptr es:[1dh*4+2],ax
	mov	ax,cs:[off1f]
	mov	word ptr es:[1fh*4],ax
	mov	ax,cs:[seg1f]
	mov	word ptr es:[1fh*4+2],ax
	mov	ax,cs:[off43]
	mov	word ptr es:[43h*4],ax
	mov	ax,cs:[seg43]
	mov	word ptr es:[43h*4+2],ax
	mov	ax,cs:[off6d]
	mov	word ptr es:[6dh*4],ax
	mov	ax,cs:[seg6d]
	mov	word ptr es:[6dh*4+2],ax
	mov	ax,cs:[off4a8]
	mov	word ptr es:[04a8h],ax
	mov	ax,cs:[seg4a8]
	mov	word ptr es:[04aah],ax
	sti

	pop	es
	pop	cx
SBiosSkip:
	pop	ax
	ret
SaveBios endp

;
; Lowlevel Bios restore routine
;

RestoreBios proc	near
	cmp	[DesiredBios],-1
	jne	DoRestoreBios
	call	SaveBios
	ret
DoRestoreBios:
	push	ax
	push	bx
	push	cx
	push	dx
	push	si
	push	ds
	push	es

	
	mov	ax,cs
	mov	ds,ax
	mov	bl,[DesiredBios]
	mov	[CurrentBios],bl
	xor	bh,bh
	mov	bl,[bx+VMapIndex]
	cmp	bl,-1			; is this for map out
	jne	VRestore1
	jmp	VSkipRestore
VRestore1:
	mov	si,offset VMapTable
	add	si,bx
	mov	ax,[si+VMAPSEG]
	mov	[MapRom],ax
	mov	es,ax
	mov	bx,[si+VMAPHAND]
	mov	cl,[si+VMAPBANK]
	xor	ch,ch
	mov	[MapBanks],cx
	mov	ah,3
	call	[vMemcall]
	mov	ax,word ptr [si+VMAPINT10]
	mov	word ptr [Int10Vector],ax
	mov	ax,word ptr [si+VMAPINT10+2]
	mov	word ptr [Int10Vector+2],ax
	
	xor	ax,ax
	mov	es,ax
	cli
	mov	ax,cs:[si+VMAPINT1D]
	mov	word ptr es:[1dh*4],ax
	mov	ax,cs:[si+VMAPINT1D+2]
	mov	word ptr es:[1dh*4+2],ax
	mov	ax,cs:[si+VMAPINT1F]
	mov	word ptr es:[1fh*4],ax
	mov	ax,cs:[si+VMAPINT1F+2]
	mov	word ptr es:[1fh*4+2],ax
	mov	ax,cs:[si+VMAPINT43]
	mov	word ptr es:[43h*4],ax
	mov	ax,cs:[si+VMAPINT43+2]
	mov	word ptr es:[43h*4+2],ax
	mov	ax,cs:[si+VMAPINT6D]
	mov	word ptr es:[6dh*4],ax
	mov	ax,cs:[si+VMAPINT6D+2]
	mov	word ptr es:[6dh*4+2],ax
	mov	ax,cs:[si+VMAPOFF4A8]
	mov	word ptr es:[04a8h],ax
	mov	ax,cs:[si+VMAPOFF4A8+2]
	mov	word ptr es:[04aah],ax
	sti


VSkipRestore:
	pop	es
	pop	ds
	pop	si
	pop	dx
	pop	cx
	pop	bx
	pop	ax
	ret
RestoreBios endp

BiosSave proc	far
;
; Pass on to next context save routine
;
	call	SaveBios				; save Bios 
	cmp	word ptr cs:[OldSave+2],0
	je	PassSave
	call	dword ptr cs:[OldSave]
PassSave:
	ret
BiosSave endp

;
; Context Restore Routine 
;
; ES -> TCB
;


BiosRestore	proc	far
;
;	Pass on	to next context restore routine
;
	cli
	call	GetCurBios 			; get current Bios Pointers
	je	BRestore
	call	RestoreBios
BRestore:
	sti
	cmp	word ptr cs:[OldRestore+2],0
	je	PassRestore
	call	dword ptr cs:[OldRestore]
PassRestore:
	ret
BiosRestore endp


;
; New INT 10 Vector - this is use to pass on to approviate INT 10 vector
; for handlinge multiable bios's
;

NewOrg10:
ifdef	slashb
	cmp	[slashb],'Y'
	je	CallOrg10
endif
;
; handle BIOS switching for all bios function screen enable\disable calls
;
	cmp	ah,12h
	jne	CallOrg10
	cmp	bl,32h
	jne	CallOrg10
	cmp	al,01
	ja	CallOrg10
;
; do bios switching logic here
;
	cli
	push	dx
	mov	dx,46e8h
	or	al,al
	jnz	SwtOut10
	mov	al,0eh
	out	dx,al
	mov	al,01h
	mov	dx,3c3h		; diable master console using 3c3h
	out	dx,al
	pop	dx
	mov	ax,1212h
	iret
SwtOut10:
	mov	al,06h
	out	dx,al
	xor	al,al
	mov	dx,3c3h		; diable master console using 3c3h
	out	dx,al
	pop	dx
	mov	ax,1212h
	iret
	
CallOrg10:
;
; handle remain bios functions by calling orginal bios handler
;
	cli
	call	GetCurBios			; get current Bios
	je	NewOrg10a
	call	SaveBios			; save bios 
	call	RestoreBios
NewOrg10a:
	sti
	pushf	
	call	dword ptr cs:[Int10Vector]
	iret

			public	$$BIOSRES_END
$$BIOSRES_END 	label	byte
