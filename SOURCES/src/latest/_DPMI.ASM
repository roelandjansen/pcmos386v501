 
	include page.inc
	title	_DPMI.ASM - Dos Protected Mode Inteface
;-----------------------------------------------------------------------;
;		development specification				;
;									;
; program name: _DPMI.ASM	assigned to: Stewart Hyde (Self)	;
; module name:	$DPMI.SYS	assign date: 05/17/90			;
; entry points: 		completed:       			;
; entry from:	int 2fh - far call entry from Windows 3.10 or DPMI app  ;
; entry method: call dword [vector] with ah = function number		;
; calls:								;
; purpose:	PC-MOS DPMI Driver (Dos Protected Mode Interface)       ;
; refer to:	Stewart Hyde, Intel's DPMI doc, VCPIDPMI.DOC, and	;
;		VCPIDPMI.002 (Design Spefication)			;
; last update:	04/30/91						;
;-----------------------------------------------------------------------;

                .286

include _dpmi.inc

scbs		segment	at	0beach
		assume  cs:scbs
		include mosscbdf.inc
scbs		ends

dseg		segment at 	0aceh
		include dpmiseg.inc
dseg		ends

tcb		segment	at	0babeh
		include mostcb.inc
tcb		ends		

;- DDT -----------------------------------------------------------------;

ddt	group	code16,code32,init16,init32


code16		segment para public 'CODE'
		assume	cs:ddt,ds:nothing,es:nothing,ss:nothing

mosddtsh 	equ	this byte
		dd	-1		; filled in with pointer to next driver
		dw	8000h		; signifying a character device
		dw	strat		; device strategy entry point
		dw	inter		; device interrupt entry point
		db	'DPMI     '	; device name

request 	dd	0

strat:
		mov	word ptr [request],bx
		mov	word ptr [request+2],es
		retf

inter:
		push	ds
		push	es
		push	bx
		push	ax
		mov	ax,0100h
		les	bx,cs:[request]
		mov	bx,es:[bx+2]
		or	bl,bl
		jne	inter1
		call	InstallDriver
inter1:
		assume	ds:nothing
		les	bx,cs:[request]
		mov	es:[bx+3],ax	; store result status
		pop	ax
		pop	bx
 		pop	es
		pop	ds
		retf


;-- REAL MODE DATA AREA ------------------------------------------------;

scbadr		label	dword
scboff		dw	0		; offset to scb
scbseg		dw	0		; segment of scb
scbsel		dw	0		; Selector for SCB
scboffset	dd	0		; protected mode offset
Version_DPMI	dw	DPMIVersion	; 

tcbseg		dw	0		; segment of tcb (caller)
old2f		dd	0		; orginal int 2fh handler
memman		dd	0		; memory manger function handler
MicroProcessor	db	-1		; 3 = 386, 4 = 486
ExtendMem  	dw	0		; 0	if extended memory allocated failed
ExtendHand 	dw	0		; extend memory handle
RUnreg		dd	0		; Real Mode Unregister handler
OUnreg		dd	0		; Orginal Unregister handle (RUnreg)

OrgIP           dw      0
OrgCS           dw      0

RealInt		dd	0		; using in calling interupts

;
; The following are constants
;

Zero		dw	0		; Segment 0

;--- INT 2F HANDLER ----------------------------------------------------;

;
; INT 2fH handler. 
;
; This Handler is use so that DPMI applications can detect if DPMI is 
; installed. 
;

dpmi2f		proc	far
		cmp	ax,1680h
		jne	Not1680
;
; Handle DPMI specific Release Current Virtual Machine Time Slice
;
		jmp	short callold2f
Not1680:
		cmp	ax,1686h	
		jne	Not1686
		mov	ax,-1
		iret
Not1686:
		cmp	ax,1687h
		jne	callold2f
		xor	ax,ax			; indicate OK
                mov     bx,AccessBits          	; 32 bit supported
                mov     cl,[MicroProcessor]
                mov     dx,[Version_DPMI]
                mov     si,5
                push    cs
                pop     es
                mov     di,offset GoProtect
		iret

callold2f:
		jmp	dword ptr cs:[Old2f]
dpmi2f		endp


GoProtect       proc    far
                pop     cs:[OrgIP]
                pop     cs:[OrgCS]
                push    ax
                push    bx
                push    cx
                push    dx

                .386
                push    fs
                mov     ax,cs:[OrgCS]
                mov     fs,ax
                .286

                
                mov     dx,es
                push    dx
                mov     ah,62h
                int     21h
                pop     dx
                mov     es,bx
                mov     cx,5*16
                
                mov     ax,1001h
                int     0d4h                	;protect mode
             
                .386
                mov     ax,gs
                mov     cs:[OrgCS],ax
                pop     fs
                pushf
                xor     ax,ax
                mov     gs,ax
                mov     fs,ax
                popf
                .286

                pop     dx
                pop     cx
                pop     bx
                pop     ax

                push    cs:[OrgCS]
                push    cs:[OrgIP]
                ret
GoProtect       endp

UnRegister	proc	far
		assume  es:tcb
		push	ax
		push	ds
		mov	ds,[TCBDPMI]
		assume 	ds:dseg
		mov	ax,word ptr [OrgUnRegister]		
		mov	word ptr [OUnreg],ax	
		mov	ax,word ptr [OrgUnRegister+2]		
		mov	word ptr [OUnreg+2],ax	
		pop	ds
		assume  ds:nothing
		pop	ax
		jmp	dword ptr cs:[OUnreg]
UnRegister 	endp

;---------------------------------------------------------------------
;
; RealSaveRest	- Real Mode Save\Restore routine
;
;---------------------------------------------------------------------

RealSaveRest	proc	far
		ret
RealSaveRest	endp


;---------------------------------------------------------------------
;
; RawRealSwitch	- Raw Mode Switch (Virtual to Protected Mode
;
;---------------------------------------------------------------------

RawRealSwitch	proc	far
		ret
RawRealSwitch	endp

;---------------------------------------------------------------------
;
; RealInterupt	- call	Real Mode Interupt
;
;---------------------------------------------------------------------


RealInterupt	proc	far
		push	ax
		push	bx
		push	ds
		lds	bx,[scbadr]
		assume  ds:scbs
		mov	ds,[bx+scbtcbpc]
		assume	ds:tcb
		mov	ds,[tcbdpmi]
		assume	ds:dseg
		mov	bl,[RealIntNo]
		xor	bh,bh
		shl	bx,4
		assume	ds:nothing
		mov	ds,[Zero]
		mov	ax,word ptr ds:[bx]
		cli
		mov	word ptr [RealInt],ax		
		mov	ax,word ptr ds:[bx+2]
		mov	word ptr [RealInt+2],ax		
		pop	ds
		pop	bx
		pop	ax
		pushf
		call	dword ptr [RealInt]
		ret
RealInterupt	endp


EndOfDPMI	label	byte

code16		ends

;---------- START OF PROTECTED MODE CODE ------------------------------;

		.386p
code32	segment para public 'CODE' use32
assume	cs:ddt,ds:nothing,es:nothing,ss:nothing,fs:nothing,gs:nothing

BeginProtect	label	byte

Function	dd	0		; Use in Main Interupt 31h handler
DataSel		dw	0		; Data Selector 
OrgProt21	dd	0		; Orginal Protected Mode INT 21h
OrgProt2F	dd	0		; Orginal Protected Mode INT 2fh
DriverRealCS	dw	0		; Driver's real mode code segment
Selector	dw	0		; temporary storage for selector
SmallestBank	dd	0		; smallest bank use in scans
DPMI_Version	dw	DPMIVersion	; DPMI Version
HostMajor	db	MOS_HOST_MAJOR	; major host version
HostMinor	db	MOS_HOST_MINOR	; minor host version
DPMICap		dw	00h		; DPMI Capabilities
;
;		    	Bit 0 = 0 PAGE ACCESS/DIRTY	not supported
;		    	Bit 1 = 0 EXCEPTIONS RESTARTABILITY not supported
;		    	Bit 2 = 0 DEVICE MAPPING not supported
;		    	Bit 3 = 0 CONVENTIONAL MEMORY MAPPING not supported
;		    	Bit 4 = 0 DEMAND ZERO-FILL not supported
;		    	Bit 5 = 0 WRITE-PROTECT CLIENT not supported
;		    	Bit 6 = 0 WRITE-PROTECT HOST not supported
;
MemMan_Sel	dw	0		; selector for Memory manager
MemMan_Offset	dd	0		; offset to DPMI support infomation

DPMIName	db	'PC-MOS DPMI 1.0'
DPMINameLen	equ	($-DPMIName)


HostInfo	db    	'PC-MOS DPMI 1.0 HOST (910430)',0dh,0ah
		db    	'(c) Copyright 1991 The Software Link, Inc',00h
HostInfoLen	equ	($-HostInfo)

;----------- Protected Mode INT 21h Handler --------------------------;

Interupt21	proc	near
		cmp	ah,4ch
		jne	short JumpOld21
		push	eax
;
;	Handler Protected Mode Termination
;
		pop	eax
JumpOld21:
		jmp	cs:[OrgProt21]
Interupt21	endp

;----------- Protected Mode INT 2fh Handler --------------------------;


Interupt2F	proc	near
		cmp	ax,168ah
		jne	short Not168a
		push	ax
		call	GetPCMOSApi
		pop	ax
		jc	short Exit8a
		xor	al,al
Exit8a:
		iret
Not168a:
		cmp	ax,1686h
		jne	short JumpOld2f
		xor	ax,ax
		iret
JumpOld2f:
		jmp	cs:[OrgProt2f]
Interupt2f	endp
		

;---------- INT 31 Vector Table and Interupt handler -----------------;

Intr31Tab	label	dword
		vector  0000h,AllocateLdt
		vector	0001h,FreeLdt
		vector	0002h,SegToDisc
		vector	0003h,NextSegInc
		vector	0004h,Reserved
		vector	0005h,Reserved
		vector	0006h,GetSegBase
		vector	0007h,SetSegBase
		vector	0008h,SetSegLimit
		vector	0009h,SetSegAccess
		vector	000Ah,CreateAlias
		vector	000Bh,GetDescriptor
		vector	000Ch,SetDescriptor
		vector	000Dh,AllocSpecLDT
		vector	0100h,AllocDOSBlock
		vector	0101h,FreeDOSBlock
		vector	0102h,ResizeDOSBlock
		vector	0200h,GetRealIntVect
		vector	0201h,SetRealIntVect
		vector	0202h,GetProcExcept
		vector	0203h,SetProcExcept
		vector	0204h,GetProtIntVect
		vector	0205h,SetProtIntVect
		vector	0300h,SimRealInterupt
		vector	0301h,CallRealFarRet
		vector	0302h,CallRealIRET
		vector	0303h,AllocCallBack
		vector	0304h,FreeCallBack
		vector	0305h,GetSaveRestore
		vector	0306h,GetRawSwitch
		vector	0400h,GetDPMIVer
		vector	0500h,GetFreeInfo
		vector	0501h,AllocBlock
		vector	0502h,FreeBlock
		vector	0503h,ResizeBlock
		vector	0600h,VirtualMem
		vector	0601h,VirtualMem
		vector	0602h,VirtualMem
		vector	0603h,VirtualMem
		vector	0604h,VirtualMem
		vector	0700h,Reserved
		vector	0701h,Reserved
		vector	0702h,VirtualMem
		vector	0703h,VirtualMem
		vector	0800h,PhysAddrMap
		vector  0900h,GetDisVInt
		vector	0901h,GetEnaVInt
		vector  0902h,GetVIntState
		vector	0A00h,GetPCMOSApi
		vector  0B00h,SetDebugWatch	
		vector  0B01h,ClearDebugWatch
		vector  0B02h,GetDebugState
		vector  0B03h,ResetDebugWatch	
;
; The following are added for DPMI 1.0 support
;
 		vector  000Eh,GetMultDesc
		vector	000Fh,SetMultDesc
		vector	0210h,GetPExtExp
		vector  0211h,GetRExtExp
		vector	0212h,SetPExtExp
		vector  0213h,SetRExtExp
		vector  0401h,GetDPMICap
		vector  0504h,AllocLinear
		vector  0505h,ResizeLinear
		vector  0506h,GetPageAttr
		vector	0507h,SetPageAttr
		vector  0508h,MapDevMem
		vector  0509h,MapConvMem
		vector  050Ah,GetMemBase
		vector  050Bh,GetMemInfo
		vector  0801h,FreePhyMapping
		vector  0C00h,InstallRes
		vector	0C01h,DPMI_TSR
		vector  0D00h,AllocShared
		vector  0D01h,FreeShared
		vector  0D02h,SerialShared
		vector  0D03h,FreeSerial
		vector  0E00h,GetMPUStatus
		vector  0E01h,SetMPUEmu
;
		endvector	
	
	
		ALIGN	16
Interupt31	proc	near
		push	ebx
		push	esi
		push	ds

		mov	ebx,eax		; place orginal ax into bx for function
		mov	ax,cs
		mov	ds,ax
		assume  ds:ddt	
		call	GetDataSelector		; get selector
		jc	short ErrorFun31
		lea	esi,Intr31Tab
		cld
MainLoop31:
		lodsw				; load word from table
		cmp	ax,bx
		je	short DoFun31
;
;	Table entry not found
;
		add	esi,4
		cmp	ax,-1
		jne	short MainLoop31
		sub	esi,4
		lodsd
		cmp	eax,-1
		jne	short MainLoop31
ErrorFun31:
		pop	ds
		pop	esi
		pop	ebx
		stc	
		retf		
DoFun31:
;
; At this point function is what we want
;
		lodsd
		cmp	eax,-1
		je	short ErrorFun31
		mov	[Function],eax
		mov	eax,ebx
		pop	ds
		pop	esi
		pop	ebx
		call	[Function]
		retf	2
Interupt31	endp

;--------------- Interupt 31h Subfunctions ------------------------;

;------------------------------------------------------------------
;    AX=0000h	Allocate LDT Decriptors
;    -----------------------------------
;
;	To Call:
;		AX= 0000h
;		CX= Number of descripters to allocate
;
;	Returns:
;		if function was sucessful:
;			AX= Base selector
;			Carry Flag Clear
;		if function was not sucessful:
;			AX=DESCRIPTOR_UNAVAILABLE
;			Carry Flag set
;	
;	PseudoCode for function:
;
;		call	memory management to allocate CX descripters
;
;------------------------------------------------------------------

AllocateLdt     proc	near
		push	ebx
		mov	ax,MEM_DESCRIPTOR
		mov	bx,ALLOCATE_DESCRIPTOR
		int	6fh 
		jnc	short ALdt1
		mov	ax,DESCRIPTOR_UNAVAILABLE
ALdt1:		
		pop	ebx
		ret
AllocateLdt	endp

;------------------------------------------------------------------
;
;    AX=0001h	Free LDT Decriptor  
;    ------------------------------
;
;	To Call:
;		AX= 0001h
;		BX= Selector to free
;
;	Returns:
;		if function was sucessful:
;			Carry Flag Clear
;		if function was not sucessful:
;			AX=DESCRIPTOR_UNAVAILABLE
;			Carry Flag set
;	
;	PseudoCode for function:
;
;		call memory management to delete descripter
;
;------------------------------------------------------------------


FreeLdt		proc	near
		push	ebx
		push	ecx
		mov	cx,bx			; place descriptor in BX
		mov	ax,MEM_DESCRIPTOR
		mov	bx,FREE_DESCRIPTOR
		int	6fh 
		jnc	short ALdt1
		mov	ax,INVALID_SELECTOR
FLdt1:		
		pop	ecx
		pop	ebx
		ret
FreeLdt		endp

;------------------------------------------------------------------
;
;    AX=0002h	Segment to Decriptor
;    --------------------------------
;
;	To Call:
;		AX= 0002h
;		BX= real mode segment address		
;
;	Returns:
;		if function was sucessful:
;			AX= selector mapped to real mode segment
;			Carry Flag Clear
;		if function was not sucessful:
;			AX=DESCRIPTOR_UNAVAILABLE
;			Carry Flag set
;	
;	PseudoCode for function:
;
;		call	memory mangement function to convert real mode
;			segment into a selector
;		
;------------------------------------------------------------------


SegToDisc	proc	near
		mov	ax,bx		; get segment into ax
		call	SegToSel	; call lowlevel routine
		ret
SegToDisc	endp

;------------------------------------------------------------------
;		
;    AX=0003h	Get Next Selector Increment Value
;    ---------------------------------------------
;
;	To Call:
;		AX= 0003h
;
;	Returns:
;		if function was sucessful:
;			AX= value to add to get next selector 
;			Carry Flag Clear
;	
;	PseudoCode for function:
;
;		Get Next selector increment value from memory manager
;		return it in AX
;		return carry clear
;
;------------------------------------------------------------------

NextSegInc	proc	near
		push	ebx
		mov	ax,MEM_DESCRIPTOR
		mov	bx,DESCRIPTOR_INC
		int	6fh 
		pop	ebx
		clc			; always ok
		ret
NextSegInc	endp

;------------------------------------------------------------------
;
;    AX=0006h 	Get segment base address
;    ------------------------------------
;
;	To Call:
;		AX= 0006h
;		BX= Selector
;
;	Returns:
;		if function was sucessful:
;			CX:DX= 32-bit linear base address of segment
;			Carry Flag Clear
;		if function was not sucessful:
;			AX=INVALID_SELECTOR
;			Carry Flag set
;	
;	PseudoCode for function:
;
;		call	memory manager to return descripter
;		return CX:DX with segment base address
;
;------------------------------------------------------------------

GetSegBase	proc	near
		push	edi
		push	es
		mov	es,[DataSel]
		assume	es:dseg
		lea	edi,InternalSelector
		call	GetDescriptor			; call lowlevel
		jc	short GSBaseExit
		mov	dh,byte ptr [InternalBase4]
		mov	dl,byte ptr [InternalBase3]
		mov	cx,word ptr [InternalBase21]
GSBaseExit:
		pop	es
		pop	edi
		ret
GetSegBase	endp

;------------------------------------------------------------------
;
;    AX=0007h	Set segment base address
;    ------------------------------------
;
;	To Call:
;		AX= 0007h
;		BX= Selector
;		CX:DX= 32-bit linear base address of segment
;	
;	Returns:
;		if function was sucessful:
;			Carry Flag Clear
;		if function was not sucessful:
;			AX=INVALID_SELECTOR
;			AX=INVALID_LINEAR_ADDRESS
;			Carry Flag set
;	
;	PseudoCode for function:
;
;		call memory manager to return descripter
;		if no error then
;			put CX:DX into descripter for segment base address
;			call memory manager to replace descripter
;			return carry clear
;		else
;			return carry set
;
;------------------------------------------------------------------

SetSegBase	proc	near
		push	edi
		push	es
		mov	es,[DataSel]
		assume	es:dseg
		lea	edi,InternalSelector
		call	GetDescriptor			; call lowlevel
		jc	short SSBaseExit
		call	CheckBase
		jc	short SSBaseExit
		mov	byte ptr [InternalBase4],dh
		mov	byte ptr [InternalBase3],dl
		mov	word ptr [InternalBase21],cx
		call	SetDescriptor
SSBaseExit:
		pop	es
		pop	edi
		ret
SetSegBase	endp

;------------------------------------------------------------------
;
;    AX=0008h	Set segment limit
;    -----------------------------
;
;	To Call:
;		AX= 0008h
;		BX= Selector
;		CX:DX= 32 bit segment limit
;
;	Returns:
;		if function was sucessful:
;			Carry Flag Clear
;		if function was not sucessful:
;			AX=INVALID_VALUE
;			AX=INVALID_SELECTOR
;			AX=INVALID_LINEAR_ADDRESS
;			Carry Flag set
;	
;	PseudoCode for function:
;
;		call memory manager to return descripter
;		if no error then
;			put CX:DX into descripter for segment limit
;			call memory manager to replace descripter
;			return carry clear
;		else
;			return carry set
;
;------------------------------------------------------------------

SetSegLimit	proc	near
		push	edi
		push	es
		mov	es,[DataSel]
		assume	es:dseg
		lea	edi,InternalSelector
		call	GetDescriptor			; call lowlevel
		jc	short SSLimitExit
		call	CheckLimit
		jc	short SSLimitExit
		mov	word ptr [InternalSegLimit],dx
		mov	word ptr [InternalSegLimit+2],cx
		call	SetDescriptor
SSLimitExit:
		pop	es
		pop	edi
		ret
SetSegLimit	endp

;------------------------------------------------------------------
;
;    AX=0009h	Set Descriptor access rights
;    ----------------------------------------
;
;	To Call:
;		AX= 0009h
;		BX= Selector
;		CL= Access rights/type byte
;		CH= 80386 extended access rights/type byyte
;
;	Returns:
;		if function was sucessful:
;			Carry Flag Clear
;		if function was not sucessful:
;			AX=INVALID_VALUE
;			AX=INVALID_SELECTOR
;			AX=INVALID_LINEAR_ADDRESS
;			Carry Flag set
;	
;	PseudoCode for function:
;
;		call memory manager to return descripter
;		if no error then
;			put CL and CH  for selector access rights
;			call memory manager to replace descripter
;			return carry clear
;		else
;			return carry set
;
;------------------------------------------------------------------

SetSegAccess	proc	near
		push	edi
		push	es
		mov	es,[DataSel]
		assume	es:dseg
		lea	edi,InternalSelector
		call	GetDescriptor			; call lowlevel
		jc	short SSAccessExit
		call	CheckAccess
		jc	short SSAccessExit
		mov	byte ptr [InternalHighAccess],ch
		mov	byte ptr [InternalLowAccess+2],cl
		call	SetDescriptor
SSAccessExit:
		pop	es
		pop	edi
		ret
SetSegAccess	endp

;------------------------------------------------------------------
;
;    AX=000Ah	Create Code segment alias descriptor
;    ------------------------------------------------
;
;	To Call:       
;		AX= 000Ah
;		BX= Code segment selector
;
;	Returns:
;		if function was sucessful:
;			AX= New data selector
;			Carry Flag Clear
;		if function was not sucessful:
;			AX=DESCRIPTOR_UNAVAILABLE
;			AX=INVALID_SELECTOR
;			Carry Flag set
;	
;	PseudoCode for function:
;
;------------------------------------------------------------------

CreateAlias	proc	near
		push	ebx
		mov	ax,CREATE_ALIAS
		int	6Fh
		jc	short CAlias
		mov	ax,bx		; place new alias into ax
CAlias:
		pop	ebx		
		ret
CreateAlias	endp

;------------------------------------------------------------------
;
;   AX=000Bh	Get Descriptor
;   --------------------------
;
;	To Call:
;		AX= 000Bh
;		BX= Selector
;		ES:(E)DI= Pointer to an 8 byte buffer for descripter
;
;	Returns:
;		if function was sucessful:
;			ES:(E)DI= Pointer to an 8 byte buffer for descripter
;			Carry Flag Clear
;		if function was not sucessful:
;			AX=INVALID_SELECTOR
;			Carry Flag set
;	
;	PseudoCode for function:
;
;		call memory manager to return descripter
;
;------------------------------------------------------------------

GetDescriptor	proc	near
		push	ax
		mov	ax,MEM_GET_DESC
		int	6fh
		pop	ax
		jnc	short GDesc
		mov	ax,INVALID_SELECTOR
GDesc:
		ret
GetDescriptor	endp

;------------------------------------------------------------------
;
;    AX=000Ch	Set Descriptor
;    --------------------------
;
;	To Call:
;		AX= 000Ch
;		BX= Selector
;		ES:(E)DI= Pointer to an 8 byte buffer for descripter
;
;	Returns:
;		if function was sucessful:
;			Carry Flag Clear
;		if function was not sucessful:
;			AX=INVALID_VALUE
;			AX=INVALID_SELECTOR
;			AX=INVALID_LINEAR_ADDRESS
;			Carry Flag set
;	
;	PseudoCode for function:
;
;		call memory manager to set descripter
;
;------------------------------------------------------------------

SetDescriptor	proc	near
;
; Check to make sure that access rights are valid
;

;
; check to set if invalid linear address are specified
;

		push	ax
		mov	ax,MEM_SET_DESC
		int	6fh
		pop	ax
		jnc	short SDesc
		mov	ax,INVALID_SELECTOR
SDesc:
		ret
SetDescriptor	endp

;------------------------------------------------------------------
;
;    AX=000Dh	Allocate specific LDT descriptor
;    --------------------------------------------
;
;	To Call:
;		AX= 000Dh
;		BX= Selector
;
;	Returns:
;		if function was sucessful:
;			Carry Flag Clear
;		if function was not sucessful:
;			AX=DESCRIPTOR_UNAVAILABLE
;			AX=INVALID_SELECTOR
;			Carry Flag set
;	
;	PseudoCode for function:
;
;		call	memory manager too allocate specific selector
;
;------------------------------------------------------------------

AllocSpecLDT	proc	near
		mov	ax,ALLOC_SPEC_SELECTOR
		int	6fh
		ret
AllocSpecLDT	endp

;------------------------------------------------------------------
;
;    AX=000Eh 	Get Multiple Descriptors 
;    --------------------------------------------
;
;	To Call:
;		AX= 000Eh
;		CX= Number of descriptors to copy
;		ES:(E)DI =selector offset of buffer in following format
;		
;		Offset		Lenght		Contents
;		------		------		--------
;		00h		2		Selector #1
;		02h		8		descriptor #1
;		0Ah		2		Selector #2
;		0Ch		8		descriptor #2
;		....
;
;	Returns:
;		if function was sucessful:
;			Carry Flag Clear
;		if function was not sucessful:
;			AX=INVALID_SELECTOR
;			CX= Number of selectors sucessfully copy
;			Carry Flag set
;	
;	PseudoCode for function:
;
;
;------------------------------------------------------------------

GetMultDesc	proc	near
		or	cx,cx			; request was 0		
		jnz	GMD1
		clc
		ret
GMD1:
		push	edi
		push	dx
		xor	dx,dx			; no descripter yet
GMD2:
		mov	bx,word ptr es:[edi]
		inc	edi
		inc	edi
		call	GetDescriptor		
		jc	GMD3
		inc	dx	
		add	edi,8
		loop	GMD2			; loop for next one
		clc		
GMD3:
		mov	cx,dx			; return sucess count

		pop	edi
		pop	dx
		ret
GetMultDesc	endp

;------------------------------------------------------------------
;
;    AX=000F	Set Multiple Descriptors 
;    --------------------------------------------
;
;	To Call:
;		AX= 000Fh
;		CX= Number of descriptors to copy
;		ES:(E)DI =selector offset of buffer in following format
;		
;		Offset		Lenght		Contents
;		------		------		--------
;		00h		2		Selector #1
;		02h		8		descriptor #1
;		0Ah		2		Selector #2
;		0Ch		8		descriptor #2
;		....
;
;	Returns:
;		if function was sucessful:
;			Carry Flag Clear
;		if function was not sucessful:
;			AX=INVALID_VALUE
;			AX=INVALID_SELECTOR
;			AX=INVALID_LINEAR_ADDRESS
;			CX= Number of selectors sucessfully copy
;			Carry Flag set
;	
;	PseudoCode for function:
;
;
;------------------------------------------------------------------

SetMultDesc	proc	near
		or	cx,cx			; request was 0		
		jnz	SMD1
		clc
		ret
SMD1:
		push	edi
		push	dx
		xor	dx,dx			; no descripter yet
SMD2:
		mov	bx,word ptr es:[edi]
		inc	edi
		inc	edi
		call	SetDescriptor		
		jc	SMD3
		inc	dx	
		add	edi,8
		loop	SMD2			; loop for next one
		clc		
SMD3:
		mov	cx,dx			; return sucess count

		pop	edi
		pop	dx
		ret
SetMultDesc	endp


;------------------------------------------------------------------
;    AX=0100h	Allocate DOS Memory Block
;    -------------------------------------
;
;	To Call:
;		AX= 0100h
;		BX= Number of paragraphs (16 byte blocks) desired
;	Returns:
;		if function was sucusssful:
;		    Carry Flag Clear
;		    AX= inital real mode segment of allocated block
;		    DX= selector for allocated block
;		if function was not sucessful:
;		    Carry Flag Set
;		    AX= DOS error code:
;			07h	memory control blocks damaged
;			08h	insufficient memory available to allocate
;				as requested
;		    AX=DESCRIPTOR_UNAVAILABLE
;		    BX= size of largest available block in paragraphs	
;
;	PseudoCode for function:
;		
;		call real mode int 21h and executed DOS call
;		if function was sucessful then
;			convert real mode segment into selector
;-------------------------------------------------------------------------

AllocDOSBlock	proc	near
		push	es
		mov	es,[DataSel]
		assume  es:dseg	   
		mov	ah,48h
		mov	[RealAX],ax
		call	CallRealInt
		jnc	short AllocDosOk
		mov	ax,[RealAX]
		mov	bx,[RealBX]
		jmp	short AllocDosExit
AllocDosOk:
		mov	ax,[RealES]
		call	SegToSel
		mov	dx,ax
AllocDosExit:
		pop	es
		ret
AllocDOSBlock	endp
    
;-------------------------------------------------------------------------
;
;    AX=0101h	Free DOS Memory Block
;    ---------------------------------
;
;	To Call:
;		AX= 0101h
;		BX= Number of paragraphs 
;		DX= selector of block to free
;
;	Returns:
;		if function was sucusssful:
;		    Carry Flag Clear
;		if function was not sucessful:
;		    Carry Flag Set
;		    AX= DOS error code:
;			07h	memory control blocks damaged
;			09h	incorect memory segment specified
;		    AX=INVALID_SELECTOR
;
;	PseudoCode for function:
;
;		convert selector DX into real mode segment
;		call real mode int 21h and executed DOS call
;		if function was sucessful then
;			free selector
;
;-----------------------------------------------------------------------

FreeDOSBlock	proc	near
		push	es
		mov	es,[DataSel]
		assume  es:dseg	   
		mov	ah,49h
		mov	[RealAX],ax
		mov	[RealBX],bx
		mov	ax,dx
		call	SeltoSeg
		mov	[RealES],ax
		call	CallRealInt
		jnc	short FreeDosExit
		mov	ax,[RealAX]
FreeDosExit:
		pop	es
		ret
FreeDOSBlock	endp

;-----------------------------------------------------------------------
;
;    AX=0102h	Resize DOS Memory Block
;    -----------------------------------
;
;	To Call:
;		AX= 0102h
;		BX= Number of paragraphs 
;		DX= selector of block to modify
;
;	Returns:
;		if function was sucusssful:
;		    Carry Flag Clear
;		if function was not sucessful:
;		    Carry Flag Set
;		    AX= DOS error code:
;			07h	memory control blocks damaged
;			08h	insufficient memory available to allocate
;				as requested
;			09h	incorect memory segment specified
;		    AX=DESCRIPTOR_UNAVAILABLE
;		    AX=INVALID_SELECTOR
;		    BX= size of largest available block in paragraphs	
;
;	PseudoCode for function:
;
;		convert selector DX into real mode segment
;		call real mode int 21h and executed DOS call
;
;----------------------------------------------------------------------

ResizeDOSBlock	proc	near
		push	es
		mov	es,[DataSel]
		assume  es:dseg	   
		mov	ah,4ah
		mov	[RealAX],ax
		mov	[RealBX],bx
		mov	ax,dx
		call	SeltoSeg
		mov	[RealES],ax
		call	CallRealInt
		jnc	short ResDosExit
		mov	ax,[RealAX]
		mov	bx,[RealBX]
ResDosExit:
		pop	es
		ret
ResizeDOSBlock	endp


;----------------------------------------------------------------------
;
;    AX=0200h	Get Real Mode Interrupt Vector
;    ------------------------------------------
;
;	To Call:
;		AX= 0200h
;		BL= interrupt number
;
;	Returns:
;
;		Carry Flag Clear
;		CX:DX= Segment:offset of real mode interupt hander
;	
;	PseudoCode for function:
;
;		Setup to call real mode INT 21h function 35h
;		call real mode int 21h and executed DOS call
;		Set ES:BX into CX:DX for return to application
;
;-----------------------------------------------------------------------


GetRealIntVect	proc	near
		push	es
		mov	es,[DataSel]
		assume  es:dseg	   
		mov	ah,35h
		mov	[RealAX],ax
		mov	al,bl
		call	CallRealInt
		mov	cx,[RealDS]
		mov	dx,[RealDX]
		pop	es
		ret
GetRealIntVect	endp

;-----------------------------------------------------------------------
;
;    AX=0201h	Set Real Mode Interrupt Vector
;    ------------------------------------------
;
;	To Call:
;		AX= 0201h
;		BL= interrupt number
;		CX:DX= Segment:offset of real mode interupt hander
;
;	Returns:
;
;		if function is sucessful:
;			Carry Flag Clear
;		
;		if function is not sucessful:
;			Carry Flag Set
;		
;	PseudoCode for function:
;
;		Set CX:DX into DS:DX for call to OS
;		Setup to call real mode INT 21h function 25h
;		call real mode int 21h and executed DOS call
;
;--------------------------------------------------------------------

SetRealIntVect	proc	near
		push	es
		mov	es,[DataSel]
		assume  es:dseg	   
		mov	ah,25h
		mov	[RealAX],ax
		mov	al,bl
		mov	[RealDS],cx
		mov	[RealDX],dx		
		call	CallRealInt
		pop	es
		ret
SetRealIntVect	endp

;------------------------------------------------------------------
;
;    AX=0202h	Get Processor Exception Handler Vector
;    --------------------------------------------------
;
;	To Call:
;		AX= 0202h
;		BL= Exception/faylt number (00h - 1fh)
;
;	Returns:
;		if function was sucessful:
;			CX:(E)DX Selector:Offset of exception handler				
;			Carry Flag Clear
;		if function was not sucessful:
;			AX=INVALID_VALUE
;			Carry Flag set
;	
;	PseudoCode for function:
;
;		call Memory to get protection handler
;
;------------------------------------------------------------------

GetProcExcept	proc	near
		ret
GetProcExcept	endp

;------------------------------------------------------------------
;
;    AX=0203h	Set Processor Exception Handler Vector
;    --------------------------------------------------
;
;	To Call:
;		AX= 0203h
;		BL= Exception/faylt number (00h - 1fh)
;		CX:(E)DX Selector:Offset of exception handler				
;
;	Returns:
;		if function was sucessful:
;			Carry Flag Clear
;		if function was not sucessful:
;			AX=INVALID_VALUE
;			AX=INVALID_SELECTOR
;			Carry Flag set
;	
;	PseudoCode for function:
;
;		call Memory to set protection handler
;
;------------------------------------------------------------------

SetProcExcept	proc	near
		ret
SetProcExcept	endp


;------------------------------------------------------------------
;
;    AX=0204h	Get Protected Mode Interrupt Vector
;    -----------------------------------------------
;
;	To Call:
;		AX= 0204h
;		BL= Interupt Number
;
;	Returns:
;		if function was sucessful:
;			CX:(E)DX Selector:Offset of Interupt Vector
;			Carry Flag Clear
;		if function was not sucessful:
;			Carry Flag set
;	
;	PseudoCode for function:
;
;		call Memory to set protected mode interupt
;
;------------------------------------------------------------------

GetProtIntVect	proc	near
		ret
GetProtIntVect	endp


;------------------------------------------------------------------
;
;    AX=0205h	Set Protected Mode Interrupt Vector
;    -----------------------------------------------
;
;	To Call:
;		AX= 0205h
;		BL= Interupt Number
;		CX:(E)DX Selector:Offset of Interupt Vector
;
;	Returns:
;		if function was sucessful:
;			Carry Flag Clear
;		if function was not sucessful:
;			AX=INVALID_SELECTOR
;			Carry Flag set
;	
;	PseudoCode for function:
;
;		call Memory to set protected mode interupt
;
;------------------------------------------------------------------

SetProtIntVect	proc	near
		ret
SetProtIntVect	endp

;------------------------------------------------------------------
;								1.0
;    AX=0210	Get Extended Processor Exception Handler Vector
;    ----------------------------------------------------------
;		(Protected Mode)
;
;	To Call:
;		AX=0210h
;		BL= exception number (00h-1fh)
;
;	Returns:
;		if function was sucessful:
;			CX:(E)DX= selector:offset of exception handle
;			Carry Flag Clear
;		if function was not sucessful:
;			AX=INVALID VALUE
;			Carry Flag set
;	
;	PseudoCode for function:
;
;
;------------------------------------------------------------------


GetPExtExp	proc	near
		mov	ax,GET_PROT_EXCEPTION
		int	6fh
		ret
GetPExtExp	endp

;------------------------------------------------------------------
;								1.0
;    AX=0211	Get Extended Processor Exception Handler Vector
;    ----------------------------------------------------------
;		(Real Mode)
;
;	To Call:
;		AX=0211h
;		BL= exception number (00h-1fh)
;
;	Returns:
;		if function was sucessful:
;			CX:(E)DX= selector:offset of exception handle
;			Carry Flag Clear
;		if function was not sucessful:
;			AX=INVALID_VALUE
;			Carry Flag set
;	
;	PseudoCode for function:
;
;
;------------------------------------------------------------------

GetRExtExp	proc	near
		mov	ax,GET_REAL_EXCEPTION
		int	6fh
		ret
GetRExtExp	endp

;------------------------------------------------------------------
;								1.0
;    AX=0212	Set Extended Processor Exception Handler Vector
;    ----------------------------------------------------------
;		(Protected Mode)
;
;	To Call:
;		AX=0212h
;		BL= exception number (00h-1fh)
;		CX:(E)DX= selector:offset of exception handle
;
;	Returns:
;		if function was sucessful:
;			Carry Flag Clear
;		if function was not sucessful:
;			AX=INVALID VALUE
;			AX=INVALID_SELECTOR
;			Carry Flag set
;	
;	PseudoCode for function:
;
;
;------------------------------------------------------------------

SetPExtExp	proc	near
		mov	ax,SET_PROT_EXCEPTION
		int	6fh
		ret
SetPExtExp	endp

;------------------------------------------------------------------
;								1.0
;    AX=0213	Set Extended Processor Exception Handler Vector
;    ----------------------------------------------------------
;		(Real Mode)
;
;	To Call:
;		AX=0213h
;		BL= exception number (00h-1fh)
;		CX:(E)DX= selector:offset of exception handle
;
;	Returns:
;		if function was sucessful:
;			Carry Flag Clear
;		if function was not sucessful:
;			AX=INVALID VALUE
;			AX=INVALID_SELECTOR
;			Carry Flag set
;	
;	PseudoCode for function:
;
;
;------------------------------------------------------------------

SetRExtExp	proc	near
		mov	ax,SET_REAL_EXCEPTION
		int	6fh
		ret
SetRExtExp	endp

;------------------------------------------------------------------
;
;    AX=0300h	Simulate Real Mode Interrupt
;    ----------------------------------------
;
;	To Call:
;		AX= 0300h
;		BL= Interupt Number
;		BH= flags
;		    Bit 0= 1 resets the interupt controller and A20 line
;		CX= Number of words to copy from protected mode stack to
;		    real mode stack
;		ES:(E)DI= Selctor:offset of real mode call structure
;
;	Returns:
;		if function was sucessful:
;			ES:(E)DI= Selctor:offset of real mode call structure
;			Carry Flag Clear
;		if function was not sucessful:
;			AX=LINEAR_MEM_UNAVAILABLE
;			AX=PHYS_MEM_UNAVAILABLE
;			AX=BACK_STORE_UNAVAILABLE
;			AX=INVALID_VALUE
;			Carry Flag set
;	
;	PseudoCode for function:
;
;		setup for executing interupt		
;		call low level routine to execute Interupt
;
;------------------------------------------------------------------

SimRealInterupt proc	near
		ret
SimRealInterupt	endp

;------------------------------------------------------------------
;
;    AX=0301h	Call Real Mode Procedure with Far Return Frame
;    ----------------------------------------------------------
;
;	To Call:
;		AX= 0301h
;		BH= flags
;		    Bit 0= 1 resets the interupt controller and A20 line
;		CX= Number of words to copy from protected mode stack to
;		    real mode stack
;		ES:(E)DI= Selctor:offset of real mode call structure
;
;	Returns:
;		if function was sucessful:
;			ES:(E)DI= Selctor:offset of real mode call structure
;			Carry Flag Clear
;		if function was not sucessful:
;			AX=LINEAR_MEM_UNAVAILABLE
;			AX=PHYS_MEM_UNAVAILABLE
;			AX=BACK_STORE_UNAVAILABLE
;			AX=INVALID_VALUE
;			Carry Flag set
;	
;	PseudoCode for function:
;
;		setup for executing far routine
;		call low level routine to execute far routine
;
;------------------------------------------------------------------

CallRealFarRet	proc	near
		ret
CallRealFarRet	endp

;------------------------------------------------------------------
;
;    AX=0302h	Call Real Mode Procedure with IRET frame
;    ----------------------------------------------------
;
;	To Call:
;		AX= 0302h
;		BH= flags
;		    Bit 0= 1 resets the interupt controller and A20 line
;		CX= Number of words to copy from protected mode stack to
;		    real mode stack
;		ES:(E)DI= Selctor:offset of real mode call structure
;
;	Returns:
;		if function was sucessful:
;			ES:(E)DI= Selctor:offset of real mode call structure
;			Carry Flag Clear
;		if function was not sucessful:
;			AX=LINEAR_MEM_UNAVAILABLE
;			AX=PHYS_MEM_UNAVAILABLE
;			AX=BACK_STORE_UNAVAILABLE
;			AX=INVALID_VALUE
;			Carry Flag set
;	
;	PseudoCode for function:
;
;		setup for calling far routine with IRET
;		call low level routine to call far routine
;
;------------------------------------------------------------------

CallRealIRET	proc	near
		ret
CallRealIRET	endp

;------------------------------------------------------------------
;
;    AX=0303h	Allocated Real Mode Call-Back Address
;    -------------------------------------------------
;
;	To Call:
;		AX= 0303h
;		DS:(E)SI= Selector offset of proocedure to call
;		ES:(E)DI= Selector offset of real mode call structure
;	Returns:
;		if function was sucessful:
;			CX:DX= Segment:offset of real mode call structure
;			Carry Flag Clear
;		if function was not sucessful:
;			AX=CALLBACK_UNAVAILABLE	
;			Carry Flag set
;	
;	PseudoCode for function:
;
;------------------------------------------------------------------

AllocCallBack	proc	near
		ret
AllocCallBack	endp

;------------------------------------------------------------------
;
;    AX=0304h	Free Real Mode Call Back Address
;    --------------------------------------------
;
;	To Call:
;		AX= 0304h
;		CX:DX= real mode call-back address to free
;	Returns:
;		if function was sucessful:
;			Carry Flag Clear
;		if function was not sucessful:
;			AX=INVALID_CALLBACK
;			Carry Flag set
;	
;	PseudoCode for function:
;
;------------------------------------------------------------------

FreeCallBack	proc	near
		ret
FreeCallBack	endp


;------------------------------------------------------------------
;
;    AX=0305h	Get State Save\Restore Addresses
;    --------------------------------------------
;
;	To Call:
;		AX= 0305h
;
;	Returns:
;		if function was sucessful:
;			AX= size of buffer in bytes require to save state
;			BX:CX= Real mode address used to save/restore state
;			SI:(E)DI= Protected mode address used to save\
;				restore state
;		if function was not sucessful:
;			Carry Flag set
;	
;	PseudoCode for function:
;
;------------------------------------------------------------------

GetSaveRestore	proc	near
		xor	ax,ax		; currently nothing saved
		mov	si,cs		; si = current code seg
		lea	edi,ProtSaveRest
		mov	bx,[DriverRealCS]
		lea	cx,RealSaveRest		
		clc
		ret
GetSaveRestore	endp

;------------------------------------------------------------------
;
;    AX=0306h	Get Raw Mode switch addresses
;    -----------------------------------------
;
;	To Call:
;		AX= 0306h
;
;	Returns:
;		if function was sucessful:
;			BX:CX=  Real -> Protected mode switch address
;			SI:(E)DI= Protected -> Real mode switch address
;			Carry Flag Clear
;		if function was not sucessful:
;			Carry Flag set
;	
;	PseudoCode for function:
;
;------------------------------------------------------------------

GetRawSwitch	proc	near
		mov	bx,[DriverRealCS]
		lea	cx,RawRealSwitch
		push	cs
		pop	si		; place current CS selector in SI
		lea	edi,RawProtSwitch
		clc
		ret
GetRawSwitch	endp

;------------------------------------------------------------------------
;
;   AX=0400h	Get Version
;   -----------------------
;
;	Returns:
;
;		AH= Major Version
;		AL= Minor Version
;		BX= Flags
;		    Bit 0= 1 if running under 80386 DPMI implementation
;		    Bit 1= 1 if processor is return to real mode instead
;			   of Virtual 8086 mode
;		    Bit 2= 1 if virtual memory is supported
;		    Bit 3= Reserved for Historic purposes
;		    Bit 4-15  Reserved for lator use
;		CL= Processor type
;		    02= 80286
;		    03= 80386
;		    04= 80486
;         	DH= Current value of Virtual master PIC base Interupt
;		DL= Current Value of Virtual slace PIC base interupt
;
;------------------------------------------------------------------------

GetDPMIVer	proc	near
		push	es
		mov	es,[DataSel]
		assume  es:dseg		
		mov	ax,[DPMI_Version]
		mov	bx,AccessBits
		mov	cl,[CpuType]
		mov	dx,[CurrentPICBase]
		pop	es
		assume	es:nothing
		clc
		ret
GetDPMIVer	endp

;------------------------------------------------------------------
;								1.0
;    AX=0401h	Get DPMI Capibilities
;    --------------------------------
;
;	To Call:
;		AX=0401h
;		ES:(E)DI= selector offset to 128 byte buffer
;
;	Returns:
;		AX= capabilities flags
;		    Bit 0 = 0 PAGE ACCESS/DIRTY	not supported
;			    1 PAGE ACCESS/DIRTY supported
;		    Bit 1 = 0 EXCEPTIONS RESTARTABILITY not supported
;			    1 EXCEPTIONS RESTARTABILITY supported
;		    Bit 2 = 0 DEVICE MAPPING not supported
;			    1 DEVICE MAPPING supported
;		    Bit 3 = 0 CONVENTIONAL MEMORY MAPPING not supported
;			    1 CONVENTIONAL MEMORY MAPPING supported
;		    Bit 4 = 0 DEMAND ZERO-FILL not supported
;		            1 DEMAND ZERO-FILL supported
;		    Bit 5 = 0 WRITE-PROTECT CLIENT not supported
;			    1 WRITE-PROTECT CLIENT supported
;		    Bit 6 = 0 WRITE-PROTECT HOST not supported
;			    1 WRITE-PROTECT HOST supported
;		CX= reserved, must be 0
;		DX= reserved, must be 0
;		ES:(E)DI= selector:offset of 128 buffer filed with host 
;
;		    Offset	Lenght		Contents
;		    ------------------------------------
;		    0		1  		Host Major version (00h)
;		    1		1		Host Minor version (00h)
;		    2		1-126		ASCIIZ (Null terminated) str
;
;		    "PC-MOS DPMI 1.0 HOST (910430)",0dh,0ah
;		    "(c) Copyright 1991 The Software Link, Inc",00h
;
;		Carry Flag Clear
;	
;	PseudoCode for function:
;
;
;------------------------------------------------------------------

GetDPMICap	proc	near
		push	esi
		push	edi
		push	ds

		push	cs
		pop	ds
		mov	al,[HostMajor]
		stosb
		mov	al,[HostMinor]
		stosb
		mov	ecx,HostInfoLen
		lea	esi,HostInfo
		rep	movsb
		mov	ax,[DPMICap]
		xor	cx,cx
		xor	dx,dx
		clc

		pop	ds
		pop	edi
		pop	esi
		ret
GetDPMICap	endp


;------------------------------------------------------------------------
;
;    AX=0500h	Get Free Memory Information
;    ---------------------------------------
;
;	To call:
;
;		AX= 0500h
;		ES:(E)DI= Selector:offset of 30h byte buffer
;		
;	Returns:
;		if function was sucessful:
;		carry flag is clear
;		ES:(E)DI= Selector:offset of 30h byte buffer containing:
;
;		Offset	Size		Meaning
;    		------------------------------------
;      		00	DWORD		Largest available free block
;      		04	DWORD		Maximum unlock page allocation
;      		08	DWORD		Maximun lock page allocation      
;      		0C	DWORD		Linear addr space size in pages
;      		10	DWORD		Total number of unlocked pages
;      		14	DWORD		Number of free pages
;      		18	DWORD		Total number of Physical Pages
;      		1C	DWORD		Free linear address space in pages
;      		20	DWORD		Size of paging file/partition in pages
;      		24	12h Bytes	Reserved	
;
;	PseudoCode for function:
;		
;		if ES:DI does not has write access for caller for
;			30h bytes at ES:DI then return error
;		else
;			copy 30h bytes from data DPMI memory information
;			area to ES:DI	
;
;--------------------------------------------------------------------------


GetFreeInfo	proc	near
;
; Verify that task has write access to ES:DI
;
		push	es
		pop	[Selector]
		verw	[Selector]
		jz	short DoFreeInfo
		stc
		ret
DoFreeInfo:
;
; task has write access to copy 30h bytes to ES:DI
;
		push	ecx
		push	esi
		push	edi
		push	ds

		mov	ds,[DataSel]
		lea	esi,DPMIMemoryInfo
		mov	ecx,30h/4
		rep	movsd
	
		pop	ds
		pop	edi
		pop	esi
		pop	esi
		clc
		ret
GetFreeInfo	endp


;--------------------------------------------------------------------------
;
;    AX=0501h	Allocate Memory Block
;    ---------------------------------
;
;	To call:
;
;		AX= 0501h
;		BX:CX = Size of memory blocks in bytes
;
;	Returns:
;
;		if function is sucessful:
;			BX:CX = Linear of allocated memory block
;			SI:DI = Memory Block Handle
;			Carry Flag Clear
;		
;		if function is not sucessful:
;			AX=LINEAR_MEM_UNAVAILABLE
;			AX=PHYS_MEM_UNAVAILABLE
;			AX=BACK_STORE_UNAVAILABLE
;			AX=HANDLE_UNAVAILABLE
;			AX=INVALID_VALUE
;			Carry Flag Set
;		
;	PseudoCode for function:
;		
;		if BX:CX = 0 then
;			return carry set
;		calcuate rounded up number of 4K blocks for size
;		scan internal table for free 4K concectived blocks 
;			calcuate aboved
;		if block can't be found then 
;			return carry set
;		else
;			place BX:CX is linear address for start of block
;			return handle for internel table in SI;DI
;			return carry clear
;	Notes on internal table orgainization:
;		
;		One goal in designing extended memory allocations is
;		minimizing addition overhead for allocated blocks. 
;		information for organizing extended memory allocations will
;		be compacted and stored in extended memory.
;
;--------------------------------------------------------------------------

AllocBlock	proc	near
;
;	if BX:CX = 0 then return carry set
;
		or	bx,bx
		jnz	short AB1
		or	cx,cx
		jnz	short AB1
		mov	ax,INVALID_VALUE
		stc
		ret
AB1:
		push	eax
		push	dx
		push	es
		mov	es,[DataSel]
		assume  es:dseg
		call	NumOfBanks 		; ECX (# of banks) = BX:CX/4k
		call	ScanBanks
		jc	short ABexit
		xor	eax,eax
		mov	ax,di
		xor	edi,edi
		mov	di,[BankTabOffset]
		add	edi,eax			; 2 byte for each one
		add	edi,eax			; 
		inc	ax			; store 1 plus = handle
		rep	stosw
		mov	di,ax
		xor	si,si
		mov	cx,dx
		clc
ABexit:
		pop	es
		assume  es:nothing
		pop	dx
		pop	eax
		ret
AllocBlock	endp


;---------------------------------------------------------------------------
;
;    AX=0502h	Free Memory Block
;    -----------------------------
;
;	To call:
;
;		AX= 0502h
;		SI:DI = Memory Block Handle
;	
;	Returns:
;
;		if function is sucessful:
;			Carry Flag Clear
;		
;		if function is not sucessful:
;			AX=INVALID_HANDLE
;			Carry Flag Set
;		
;	PseudoCode for function:
;
;		scan table for handle in SI:DI
;		if handle found in internal table then
;			mark all 4K pages for handle free		
;			return carry flag clear
;		else
;			return carry flag set
;
;---------------------------------------------------------------------

FreeBlock	proc	near
		push	eax
		push	es
		mov	es,[DataSel]
		assume	es:dseg
		or	si,si
		jnz	short	FreeError
		cmp	di,[SizeBank]
		ja	short   FreeError
		xor	eax,eax
		mov	ax,[BankTabOffset]
		add	ax,di
		dec	ax
		push	esi
		xor	esi,esi
		mov	si,ax
		cmp	es:[esi],di
		pop	esi
		je	short FreeIt
;
; we have detected an error, return carry
;
FreeError:
		mov	ax,INVALID_HANDLE
		stc
		jmp	short FreeExit
FreeIt:
		push	esi
		mov	si,ax
		xor	ax,ax
FreeLoop:
		cmp	es:[esi],di
		jne	short FreeSkip
		mov	es:[esi],ax
		inc	esi
		jmp	short FreeLoop
FreeSkip:
		pop	esi
		clc
FreeExit:		
		pop	es
		assume  es:nothing
		pop	eax
		ret
FreeBlock	endp

;---------------------------------------------------------------------
;
;    AX=0503h	Resize Memory Block
;    -------------------------------
;
;	To call:
;
;		AX= 0502h
;		BX:CX = Size of memory blocks in bytes
;		SI:DI = Memory Block Handle
;	
;	Returns:
;
;		if function is sucessful:
;			BX:CX = Linear of allocated memory block
;			SI:DI = Memory Block Handle
;			Carry Flag Clear
;		
;		if function is not sucessful:
;			AX=LINEAR_MEM_UNAVAILABLE
;			AX=PHYS_MEM_UNAVAILABLE
;			AX=BACK_STORE_UNAVAILABLE
;			AX=HANDLE_UNAVAILABLE
;			AX=INVALID_HANDLE
;			AX=INVALID_VALUE
;			Carry Flag Set
;		
;	PseudoCode for function:
;
;		if BX:CX = 0 then
;			return carry flag set
;		scan table for handle in SI:DI
;		if handle found in internal table then
;			save position and size of for orginal handle
;			mark all 4K pages for handle free		
;			calcuate rounded up number of 4K blocks for size
;			scan internal table for free 4K concectived blocks 
;				calcuate aboved
;			if block can't be found then 
;				mark orginal handle set
;				return carry flag set		
;			else
;				place BX:CX is linear address for start
;					 of block
;				return handle for internel table in SI;DI
;				return carry flag clear
;		else
;			return carry flag set
;
;-------------------------------------------------------------------------


ResizeBlock	proc	near
		push	ebx
		push	ecx
		call	FreeBlock		; call freeblock
		pop	ecx
		pop	ebx
		jc	short ResizeExit
		call	AllocBlock
ResizeExit:
		ret
ResizeBlock	endp	

;------------------------------------------------------------------
;								1.0
;    AX=0504h	Allocate Linear Memory Block
;    ---------------------------------------
;
;	To Call:
;		AX=0504h
;		EBX= desired oage-aligned linear address of memory block
;		     or zero if linear address unsecified
;		ECX= size of block, must be nonzero
;		EDX= flags
;		     Bit	Significance
;		     ---	------------
;		     0		0 = create uncommitted pages
;				1 = create committed pages
;		     1-31	reserved, must be zero
;
;	Returns:
;		if function was sucessful:
;			EBX= linear address of memory block
;			ESI= handle for memory block
;			Carry Flag Clear
;		if function was not sucessful:
;			AX=LINEAR_MEM_UNAVAILABLE
;			AX=PHYS_MEM_UNAVAILABLE
;			AX=BACK_STORE_UNAVAILABLE
;			AX=HANDLE_UNAVAILABLE
;			AX=INVALID_VALUE
;			AX=INVALID_LINEAR_ADDRESS
;			Carry Flag set
;	
;	PseudoCode for function:
;
;
;------------------------------------------------------------------

AllocLinear	proc	near
		ret
AllocLinear	endp

;------------------------------------------------------------------
;								1.0
;    AX=0505h	Resize linear memory block
;    -------------------------------------
;
;	To Call:
;		AX=0505h
;		ESI= memory block handle
;		ECX= new block size (bytes, must be nonzero)
;		EDX= Flags
;		     Bit	Significance
;		     ---	------------
;		     0		0 = create uncommitted pages
;				1 = create committed pages
;		     1		0 = do not update segment descriptors
;				1 = segmemt descriptors update required
;		     2-31	reserved, must be zero
;
;	if bit 1 of EDX is set to 1
;			
;		     ES:EBX= selector:offset buffer containing array of
;			     selectors, 1ord per selector
;		     EDI=    count of selectors in array	
;
;	Returns:
;		if function was sucessful:
;			EBX= linear address of memory block
;			ESI= handle for memory block
;			Carry Flag Clear
;		if function was not sucessful:
;			AX=LINEAR_MEM_UNAVAILABLE
;			AX=PHYS_MEM_UNAVAILABLE
;			AX=BACK_STORE_UNAVAILABLE
;			AX=HANDLE_UNAVAILABLE
;			AX=INVALID_VALUE
;			AX=INVALID_HANDLE
;			Carry Flag set
;	
;	PseudoCode for function:
;
;
;------------------------------------------------------------------

ResizeLinear	proc	near
		ret
ResizeLinear	endp

;------------------------------------------------------------------
;								1.0
;    AX=0506h   Get Page Attributes
;    ------------------------------
;
;	To Call:
;		AX=0506h
;		ESI= memory block handle
;		EBX= base offset in memory block of page (or of first
;		     page, if requesting multiable pages)
;		ECX= number of pages
;		ES:EDX= selector:offset of buffer to recieve page attributes
;			(1 word per page, in following format)
;
;		     Bit	Significance
;		     ---	------------
;		     0-2	page type (0-7)
;				Value		Meaning
;				-----		-------
;				0		uncommitted page
;				1		committed page
;				2		mapped page
;				3-7		currently unused
;		     3		0 = page is read-only
;				1 = page is read-write
;		     4		0 = accessed/dirty bits not available for page
;				1 = accessed/dirty bits are supplied for this
;				    page in bits 5-6
;		     5		0 = page has not been accessed (if bit 4=1)
;				1 = page has been accessed (if bit 4=1)
;		     6		0 = page has not been modified (if bit 4=1)
;				1 = page has been modified (if bit 4=1)
;		     7-15	reserved, currently zero
;
;
;	Returns:
;		if function was sucessful:
;			Carry Flag Clear
;		if function was not sucessful:
;			AX=INVALID_HANDLE
;			AX=INVALID_LINEAR_ADDRESS
;			Carry Flag set
;	
;	PseudoCode for function:
;
;
;------------------------------------------------------------------

GetPageAttr	proc	near
		ret
GetPageAttr	endp

;------------------------------------------------------------------
;								1.0
;    AX=0507h	Set Page Attributes
;    ------------------------------
;
;	To Call:
;		AX=0507h
;		ESI= memory block handle
;		EBX= base offset in memory block of page (or of first
;		     page, if requesting multiable pages)
;		ECX= number of pages
;		ES:EDX= selector:offset of buffer to recieve page attributes
;			(1 word per page, in following format)
;
;		     Bit	Significance
;		     ---	------------
;		     0-2	page type (0-7)
;				Value		Meaning
;				-----		-------
;				0		uncommitted page
;				1		committed page
;				2		mapped page
;				3-7		currently unused
;		     3		0 = page is read-only
;				1 = page is read-write
;		     4		0 = accessed/dirty bits not available for page
;				1 = accessed/dirty bits are supplied for this
;				    page in bits 5-6
;		     5		0 = page has not been accessed (if bit 4=1)
;				1 = page has been accessed (if bit 4=1)
;		     6		0 = page has not been modified (if bit 4=1)
;				1 = page has been modified (if bit 4=1)
;		     7-15	reserved, currently zero
;
;	Returns:
;		if function was sucessful:
;			Carry Flag Clear
;		if function was not sucessful:
;			AX=LINEAR_MEM_UNAVAILABLE
;			AX=PHYS_MEM_UNAVAILABLE
;			AX=BACK_STORE_UNAVAILABLE
;			AX=INVALID_VALUE
;			AX=INVALID_HANDLE
;			AX=INVALID_LINEAR_ADDRESS
;			CX= number of pages that have been set
;			Carry Flag set
;	
;	PseudoCode for function:
;
;
;------------------------------------------------------------------

SetPageAttr	proc	near
		ret
SetPageAttr	endp

;------------------------------------------------------------------
;								1.0
;    AX=0508h	Map Device in Memory Block
;    -------------------------------------
;
;	To Call:
;		AX= 0508h
;		ESI= Memory Block Handle
;		EBX= offset within memory block of page(s) to be
;		     mapped (must be page-aligned)
;		ECX= number of pages to map
;		EDX= physical address of device (must be page aligned)
;
;	Returns:
;		if function was sucessful:
;			Carry Flag Clear
;		if function was not sucessful:
;			AX=UNSUPPORTED_FUN
;			AX=SYSTEM_INTEGRITY
;			AX=INVALID_HANDLE
;			AX=INVALID_LINEAR_ADDRESS
;			Carry Flag set
;	
;	PseudoCode for function:
;
;
;------------------------------------------------------------------

MapDevMem	proc	near
		ret
MapDevMem	endp

;------------------------------------------------------------------
;								1.0
;    AX=0509h	Map Conventual Memory in Memory Block
;    ------------------------------------------------
;
;	To Call:
;		AX= 0509h
;		ESI= Memory Block Handle
;		EBX= offset within memory block of page(s) to be
;		     mapped (must be page-aligned)
;		ECX= number of pages to map
;		EDX= physical address of conventual memory
;		     (must be page aligned)
;
;	Returns:
;		if function was sucessful:
;			Carry Flag Clear
;		if function was not sucessful:
;			AX=UNSUPPORTED_FUN
;			AX=SYSTEM_INTEGRITY
;			AX=INVALID_HANDLE
;			AX=INVALID_LINEAR_ADDRESS
;			Carry Flag set
;	
;	PseudoCode for function:
;
;
;------------------------------------------------------------------

MapConvMem	proc	near
		ret
MapConvMem	endp

;------------------------------------------------------------------
;								1.0
;    AX=050Ah	Get Memory Block Size and Base
;    -----------------------------------------
;
;	To Call:
;		AX-050Ah
;		SI:DI = memory block handle
;
;	Returns:
;		if function was sucessful:
;			SI:DI = size of memory block (bytes)
;			BX:CX = base address of memory block
;			Carry Flag Clear
;		if function was not sucessful:
;			AX=INVALID_HANDLE
;			Carry Flag set
;	
;	PseudoCode for function:
;
;
;------------------------------------------------------------------

GetMemBase	proc	near
		ret
GetMemBase	endp

;------------------------------------------------------------------
;								1.0
;    AX=050Bh	Get Memory Information
;    ---------------------------------
;
;	To Call:
;		AX= 050Bh
;		ES:(E)DI selector offset of 128 byte buffer
;	
;
;	Returns:
;		 Carry Flag Clear
;
;		128 buffer contains the following structure
;
;		Offset	Lenght	Contents
;		------	------	--------
;		00h	4	Total allocated bytes of physical memory 
;				control by DPMI	Host
;		04h	4	Total allocated bytes of virtual memory 
;				control by DPMI host
;		08h	4	Total available bytes of virtual memory 
;				control by DPMI host
;		0Ch	4	Total allocated bytes of virtual memory 
;				control by this virtual machine
;		10h	4	Total available bytes of virtual memory 
;				control by this virtual machine
;		14h	4	Total allocated bytes of virtual memory 
;				control by this client
;		18h	4	Total available bytes of virtual memory 
;				control by this client
;		1Ch	4	Total locked bytes of memoryy for this client
;		20h	4	Maximum locked bytes of memory for this client
;		24h	4	Highest linear address available for this
;				client
;		28h	4	Size in bytes of largest available free
;				memory block
;		2Ch	4	Size of minimun allocation units in bytes
;		30h	4	Size of allocation aligment unit in bytes
;		34h	4ch	Reserved, currently zero
;	
;	PseudoCode for function:
;
;
;------------------------------------------------------------------

GetMemInfo	proc	near
		ret
GetMemInfo	endp


;------------------------------------------------------------------------
;
;    AX=0800h	Physical Address Mapping
;    ------------------------------------
;	To Call:
;		AX= 0800h
;		BX:CX= physical address if nemory
;		SI:DI= size of region to map (bytes)
;
;	Returns:
;		if function was sucessful:
;			BX:CX= linear address use to access memory
;			Carry Flag Clear
;		if function was not sucessful:
;			AX=SYSTEM_INTEGRITY
;			AX=INVALID_VALUE
;			Carry Flag set
;	
;	PseudoCode for function:
;
;
;
;------------------------------------------------------------------------

PhysAddrMap	proc	near
		mov	AX,SYSTEM_INTEGRITY
		stc			; Alway return carry
		ret	
PhysAddrMap	endp

;------------------------------------------------------------------
;								1.0
;    AX=0801h	Free Physical Address Mapping
;    ----------------------------------------
;
;	To Call:
;		AX= 0801h
;		BX:CX= linear address from function 0800h
;
;	Returns:
;		if function was sucessful:
;			Carry Flag Clear
;		if function was not sucessful:
;			AX=INVALID_LINEAR_ADDRESS
;			Carry Flag set
;	
;	PseudoCode for function:
;
;
;------------------------------------------------------------------

FreePhyMapping	proc	near
		ret
FreePhyMapping	endp

;------------------------------------------------------------------
;
;    AX=0900h	Get and Disable Virtual Interrupt State
;    ---------------------------------------------------
;
;    	To Call:
;
;		AX= 0900h
;	
;    	Returns:
;		Virtual Interupts are disable
;		AL= 0 if virtual interupts were previously disable
;		AL= 1 if virtual interupts were previously enable
;		Carry Flag Clear
;
;	PseudoCode for function:
;    
;		
;		get virtual interupt flag from memory manager
;		call memdev  to disable virtual interupts
;		return Carry Flag clear
;	
;------------------------------------------------------------------

GetDisVInt	proc	near
		call	GetVintState
		push	ax
		push	bx
		mov	bx,VIRTUAL_DISABLE
		mov	ax,MEM_VIRTUAL
		int	6fh
		pop	bx
		pop	ax
		clc
		ret
GetDisVInt	endp


;------------------------------------------------------------------
;	
;    AX=0901h	Get and Enable Virtual Interrupt State
;    --------------------------------------------------
;
;    	To Call:
;
;		AX= 0901h
;	
;    	Returns:
;		Virtual Interupts are enable
;		AL= 0 if virtual interupts were previously disable
;		AL= 1 if virtual interupts were previously enable
;		Carry Flag Clear
;
;	PseudoCode for function:
;    
;		
;		get virtual interupt flag from memory manager
;		call memdev  to enable virtual interupts
;		return Carry Flag clear
;
;------------------------------------------------------------------

GetEnaVInt	proc	near
		call	GetVintState
		push	ax
		push	bx
		mov	bx,VIRTUAL_ENABLE
		mov	ax,MEM_VIRTUAL
		int	6fh
		pop	bx
		pop	ax
		clc
		ret
GetEnaVInt	endp


;------------------------------------------------------------------
;	
;    AX=0902h	Get Virtual Interrupt State
;    ---------------------------------------
;
;    	To Call:
;
;		AX= 0902h
;	
;    	Returns:
;		AL= 0 if virtual interupts were previously disable
;		AL= 1 if virtual interupts were previously enable
;		Carry Flag Clear
;
;	PseudoCode for function:
;    
;		
;		get virtual interupt flag from memory manager
;		return Carry Flag clear
;
;------------------------------------------------------------------

GetVIntState	proc	near
		push	ebx
		cmp	[MemMan_Sel],0
		jne	GVint
		push	eax
		push	es
		mov	ax,MEM_VIRTUAL
		mov	bx,VIRTUAL_TABLE
		int	6fh
		mov	[MemMan_Sel],es
		mov	[MemMan_Offset],ebx
		pop	es
		pop	eax
GVint:
		push	ds
		mov	ds,[MemMan_Sel]
		mov	ebx,[MemMan_Offset]
		mov	al,byte ptr ds:[ebx]
		and	al,1
		pop	ds
		pop	ebx
		clc
		ret
GetVIntState	endp


;-----------------------------------------------------------------------
;
;    AX=0A00h	Get Vendor API Specific API entry Point
;    ---------------------------------------------------
;
;    To Call:
;
;	AX= 0A00h
;	DS:(E)SI = Pointer to null terminated string
;
;    Returns:
;	if function was successful:
;		Carry Flag is clear
;		ES:(E)DI= Extender API entry point
;	if function was unsuccessful:
;		Carry Flag is Clear
;	
;	PseudoCode for function:
;
;		compare string at DS:(E)SI to internal string
;			"PC-MOS DPMI 1.0",0
;		if string is not our string
;			AX=UNSUPPORTED_FUN
;			return carry flag set
;		else
;			return ES:(E)DI points to PC-MOS Specific DPMI handler
;			carry flag is clear
;
;		Note:	Currently Our routine is has only a FAR return.
;			This is so that we or other could notice that
;			it is our PC-MOS specific version of DPMI
;
;---------------------------------------------------------------------------

GetPCMOSApi	proc	near
;
; Compare string in ds:(E)SI to "PC-MOS DPMI 1.0"
;
		push	ecx
		push	esi
		push	edi
		
		push	es
		lea	edi,DPMIName
		mov	ecx,DPMINameLen
		rep	cmpsb
		pop	es

		pop	edi
		pop	esi
		pop	ecx		
		je	short PCMOSOurs
;
; This is not for us, so return error
;
		mov	ax,UNSUPPORTED_FUN
		stc
		ret
;
; Ok, This is for us, so return address to our routine
;
PCMOSOurs:
		push	cs
		pop	es		; place current CS into ES
		lea	edi,PCMOSApiRoutine
		clc
		ret
GetPCMOSApi	endp


;---------------------------------------------------------------------------
;
;    AX=0B00h    Set Debug WatchPoint
;    --------------------------------
;
;	To call:
;	    AX = 0B00h 
;	    BX:CX = Linear Address of watchpoint
;	    DL = Size of watch point (1,2 or 4)
;	    DH = Type of watch point
;		  0 = execute
;		  1 = write 
;		  2 = Read/Write
;
;	Returns:
;	    if function is sucessful:
;		Carry flag is clear
;		BX = Debug Watch Point handler
;	    if function is not sucessful: 
;		AX=HANDLE_UNAVAILABLE		
;		AX=INVALID_VALUE		
;		AX=INVALID_LINEAR_ADDRESS		
;		Carry flag is set
;
;	PseudoCode for function:
;	
;
;	call Memory manger to read debug registers
;	translate debug registers into internal structures
;	Scan internal table of 4 debug registers and check for first 
;	    allocated handle
;	If table entry not available then
;	    return Carry clear set
;	else
;	    insert new settings and debug address into table 
;	    translate internal structures to debug register
;	    call memory manager to write debug registers
;	    set BX to (0-3) depending of which debug register is used
;	    return Carry flag clear
;
;-------------------------------------------------------------------------

SetDebugWatch	proc	near
		call	ReadDebugRegs
		push	esi
		push	es
		mov	es,[DataSel]
		assume	es:dseg		
;
;		Scan Debug register table for available slot for debug
;		registers
;
		lea	esi,DebugSetting1
		push	cx
		mov	cx,4
SDBLoop:
		cmp	byte ptr es:[esi+DEBUGACCESS],0ffh
		je	short SDBFound
		add	esi,DBStrucSize
		loop	short SDBLoop
		mov	AX,HANDLE_UNAVAILABLE		
		stc		
		jmp	short SetDBExit
SDBFound:
		pop	cx
;
;		ESI Now has pointer to debug register structure
;		Now Insert changes into table 
;
		mov	byte ptr es:[esi+DEBUGSTATUS],0
		mov	word ptr es:[esi+DEBUGLOC],cx
		mov	word ptr es:[esi+DEBUGLOC+1],bx
		and	dx,0f0fh
		mov	al,dh
		shl	al,4
		or	al,dl
		mov	byte ptr es:[esi+DEBUGACCESS],al		
		call	WriteDebugRegs		
		sub	esi,offset DebugSetting1
		mov	bx,si
		clc
SetDBExit:
		pop	es
		pop	esi		
		ret
SetDebugWatch	endp

;-------------------------------------------------------------------------
;
;    AX=0B01h    Clear Debug WatchPoint
;    ----------------------------------
;
;	To call:
;	    AX = 0B01h 
;	    BX = debug handle
;
;	Returns:
;	    if function is sucessful:
;		Carry flag is clear
;	    if function is not sucessful:		
;		AX=INVALID_HANDLE
;		Carry flag is set
;
;
;	PseudoCode for function:
;	
;	if BX is greater than 3 then
;	    return Carry Flag set
;	else
;	    call Memory manager to read debug registers
;	    clear registers for requested handle in BX
;	    call Memory manager to write debug registers
;	    return Carry flag clear
;
;-------------------------------------------------------------------------

ClearDebugWatch	proc	near
		cmp	bx,3*DBStrucSize
		jbe	short ClrDebug
		mov	ax,INVALID_HANDLE
		stc
		ret
ClrDebug:
		call	ReadDebugRegs
		push	es
		push	esi
		call	BXtoESI
		mov	byte ptr es:[esi+DEBUGACCESS],0ffh
		mov	byte ptr es:[esi+DEBUGSTATUS],0
		pop	esi
		pop	es
		call	WriteDebugRegs
		ret
ClearDebugWatch	endp

;-------------------------------------------------------------------------
;
;
;    AX=0B02h    Get State of Debug WatchPoint
;    -----------------------------------------
;
;	To call:
;	    AX = 0B02h 
;	    BX = debug handle
;
;	Returns:
;	    if function is sucessful:
;	        AX = status
;		   Bit 0 = 1 if watch point is executed
;		Carry flag is clear
;	    if function is not sucessful:		
;		AX=INVALID_HANDLE
;		Carry flag is set
;
;	PseudoCode for function:
;	
;	if BX is greater than 3 then
;	    return Carry Flag set
;	else
;	    call Memory manager to read debug registers
;	    translate debug registers into internal structures
;	    set AX to return status (Bit 0=1 if watchpoint executed)	    
;	    return Carry flag clear
;
;-------------------------------------------------------------------------

GetDebugState	proc	near
		cmp	bx,3*DBStrucSize
		jbe	short GetDebug
		mov	ax,INVALID_HANDLE
		stc
		ret
GetDebug:
		call	ReadDebugRegs
		push	es
		push	esi
		call	BXtoESI
		mov	al,byte ptr es:[esi+DEBUGSTATUS]
		xor	ah,ah
		pop	esi
		pop	es
		ret
GetDebugState	endp

;-------------------------------------------------------------------------
;
;    AX=0B03h    Reset Debug WatchPoint
;    ----------------------------------
;
;	To call:
;	    AX = 0B03h 
;	    BX = debug handle
;
;	Returns:
;	    if function is sucessful:
;		Carry flag is clear
;	    if function is not sucessful:		
;		AX=INVALID_HANDLE
;		Carry flag is set
;
;	PseudoCode for function:
;	
;	if BX is greater than 3 then
;	    return Carry Flag set
;	else
;	    call Memory manager to read debug registers
;	    reset debug register for handle in BX
;	    call Memory manager to write debug registers
;	    return Carry flag clear
;
;
;-------------------------------------------------------------------------

ResetDebugWatch	proc	near
		cmp	bx,3*DBStrucSize
		jbe	short ResetDebug
		mov	ax,INVALID_HANDLE
		stc
		ret
ResetDebug:
		call	ReadDebugRegs
		push	es
		push	esi
		call	BXtoESI
		mov	byte ptr es:[esi+DEBUGSTATUS],0
		pop	esi
		pop	es
		call	WriteDebugRegs
		ret
ResetDebugWatch	endp

;------------------------------------------------------------------
;								1.0
;    AX=0C00h 	Install Resident Service Provider CallBack
;    -----------------------------------------------------
;
;	To Call:
;		AX=0C00h
;		ES:(E)DI= selector:offset of 40 byte buffer with
;			  with following structure
;
;			Offset	Lenght	Contents
;			------	------	--------
;			00h	8	descriptor for 16-bit data segment
;			08h	8	descriptor for 16-bit code segment
;			10h	2	offset of 16 bit callback procedure
;			12h	2	reserved
;			14h	8	descriptor for 32-bit data segment
;			1Ch	8	descriptor for 32-bit code segment
;			24h	4	offset of 32 bit callback procedure
;
;	Returns:
;		if function was sucessful:
;			Carry Flag Clear
;		if function was not sucessful:
;			AX=INVALID_VALUE
;			AX=INVALID_LINEAR_ADDRESS
;			AX=INVALID_CALLBACK
;			Carry Flag set
;	
;	PseudoCode for function:
;
;
;------------------------------------------------------------------

InstallRes	proc	near
		ret
InstallRes	endp

;------------------------------------------------------------------
;								1.0
;    AX=0C01h	Terminate and Stay Resident
;    --------------------------------------
;
;	To Call:
;		AX=0C01h
;		BL= return code
;		DX= number of paragraphs of MOS memory to reserve
;
;	Returns:
;		Nothing, does not return
;	
;	PseudoCode for function:
;
;
;------------------------------------------------------------------

DPMI_TSR	proc	near
		ret
DPMI_TSR	endp

;------------------------------------------------------------------
;								1.0
;    AX=0D00h	Allocate Shared Memory
;    ---------------------------------
;
;	To Call:
;		AX=0D00h
;		ES:(E)DI= selector:offset of shared memory allocation
;			  request structure as following:
;
;			Offset	Lenght	Contents
;			------	------	--------
;			00h	4	Request lenght of shared memory
;					block (set by client, may be 0)
;			04h	4	Lenght actually allocated 
;					(set by host)
;			08h	4	Shared Memory Handle (set by host)
;			0Ch	4	Linear address of shared memory
;					block (set by host)
;			10h	6	offset32:selector of ASCIIZ (Null
;					terminated ASCII name for shared
;					memory block (set by client)
;			16h	2	reserved
;			18h	4	Reserved, must be zero
;
;	Returns:
;		if function was sucessful:
;			Carry Flag Clear
;		if function was not sucessful:
;			AX=LINEAR_MEM_UNAVAILABLE
;			AX=PHYS_MEM_UNAVAILABLE
;			AX=BACK_STORE_UNAVAILABLE
;			AX=HANDLE_UNAVAILABLE
;			AX=INVALID_VALUE
;			Carry Flag set
;	
;	PseudoCode for function:
;
;
;------------------------------------------------------------------

AllocShared	proc	near
		ret
AllocShared	endp

;------------------------------------------------------------------
;								1.0
;    AX=0D01h	Free Shared Memory
;    -----------------------------
;
;	To Call:
;		AX=0D01h
;		SI:DI = handle for shared memory block
;
;	Returns:
;		if function was sucessful:
;			Carry Flag Clear
;		if function was not sucessful:
;			AX=INVALID_HANDLE
;			Carry Flag set
;	
;	PseudoCode for function:
;
;
;------------------------------------------------------------------

FreeShared	proc	near
		ret
FreeShared	endp

;------------------------------------------------------------------
;								1.0
;    AX=0D02h	Serialize on Shared Memory
;    -------------------------------------
;
;	To Call:
;		AX=0D02h
;		SI:DI = handle for shared memory block
;		DX= option flags
;		    Bit		Significance
;		    ---		------------
;		    0		0 = suspend client until serialization
;				    available
;				1 = return immediately with error if
;				    serialization is not available
;		    1	   	0 = exclusive serialization requested
;				1 = shared serialization requested
;		    2-15	reserved, must be zero
;
;	Returns:
;		if function was sucessful:
;			Carry Flag Clear
;		if function was not sucessful:
;			AX=DEADLOCK
;			AX=REQUEST_CANCELL
;			AX=LOCK_COUNT_EXCEEDED
;			AX=RESOURCE_OWN_EXCLUSIVE
;			AX=RESOURCE_OWN_SHARED
;			AX=INVALID_HANDLE
;			Carry Flag set
;	
;	PseudoCode for function:
;
;
;------------------------------------------------------------------

SerialShared	proc	near
		ret
SerialShared	endp

;------------------------------------------------------------------
;								1.0
;    AX=0D03h	Free Serialization on Shared Memory
;    ----------------------------------------------
;
;	To Call:
;		AX=0D03h
;		SI:DI = handle for shared memory block
;		DX= option flags
;		    Bit		Significance
;		    ---		------------
;		    0		0 = release exclusive serialization
;				1 = release shared serialization
;		    1	   	0 = don't free pending serialization
;				1 = free pending serialization
;		    2-15	reserved, must be zero
;
;	Returns:
;		if function was sucessful:
;			Carry Flag Clear
;		if function was not sucessful:
;			AX=INVALID_STATE
;			AX=INVALID_HANDLE
;			Carry Flag set
;	
;	PseudoCode for function:
;
;
;------------------------------------------------------------------

FreeSerial	proc	near
		ret
FreeSerial	endp

;------------------------------------------------------------------
;								1.0
;    AX=0E00h	Get Coprocessor Status
;    ---------------------------------
;
;	To Call:
;		AX=0E00h
;
;	Returns:
;		AX= coprocessor status
;		    Bit		Significance
;		    ---		------------
;		    0		MPv (MP bit in the virtual MSW/CR0)
;				0 = coprocessor disable for this client
;				1 = coprocessor enable for this client
;		    1		EMv (MP bit in the virtual MSW/CR0)
;				0 = client is not emulating coprocessor
;				1 = client is emulating coprocessor
;		    2		MPr (MP bit in the actual MSW/CR0)
;				0 = coprocessor disable for this client
;				1 = coprocessor enable for this client
;		    3		EMr (MP bit in the actual MSW/CR0)
;				0 = client is not emulating coprocessor
;				1 = client is emulating coprocessor
;		    4-7		Coprocesor type
;				00h = no coprocessor
;				02h = 80287
;				03h = 80387
;				04h = 80486 with numeric coprocessor
;				05h-0fh reserved for future numeric coprocs
;		    8-15	not applicable
;		Carry Flag Clear
;	
;	PseudoCode for function:
;
;
;------------------------------------------------------------------

GetMPUStatus	proc	near
		ret
GetMPUStatus	endp

;------------------------------------------------------------------
;								1.0
;    AX=0E01h	Set Coprocessor Emulation
;    --------------------------------------------
;
;	To Call:
;		AX=0E01h
;		BX= coprocessor status
;		    Bit		Significance
;		    ---		------------
;		    0		new value of MPv bit for client's virtual CR0
;				0 = coprocessor disable for this client
;				1 = coprocessor enable for this client
;		    1		new value of EMv bit for client's virtual CR0
;				0 = client is not emulating coprocessor
;				1 = client is emulating coprocessor
;		    2-15	not applicable
;
;	Returns:
;		if function was sucessful:
;			Carry Flag Clear
;		if function was not sucessful:
;			AX=INVALID_REQUEST	
;			Carry Flag set
;	
;	PseudoCode for function:
;
;
;------------------------------------------------------------------

SetMPUEmu	proc	near
		ret
SetMPUEmu	endp


;========================================================================;

;-------------------------------------------------------------------------
; Protected Mode PC-MOS API Routine
; Currently only returns
;-------------------------------------------------------------------------

PCMOSApiRoutine	proc	far
		ret
PCMOSApiRoutine endp

;---------------------------------------------------------------------
;
; ProtSaveRest	- Protected Mode Save\Restore routine
;
;---------------------------------------------------------------------

ProtSaveRest	proc	far
		ret
ProtSaveRest	endp

;---------------------------------------------------------------------
;
; RawProtSwitch	- Raw Mode Switch (Protected Mode to Virtual Mode)
;
;---------------------------------------------------------------------

RawProtSwitch	proc	far
		ret
RawProtSwitch	endp




;---------------------------------------------------------------;
; Reserved Function, Set carry and Return			;
;---------------------------------------------------------------;

Reserved	proc	near
		stc
		ret
Reserved	endp


;---------------------------------------------------------------;
; VirtualMem - Virtual Memory Functions				;
;								;
; Virtual Memory is not currently supported, and this function  ;
; returns carry clear per DPMI 0.9 doc				;
;---------------------------------------------------------------;


VirtualMem	proc	near
		clc
		ret
VirtualMem	endp

;-------------- Protected Mode Subfunctions ---------------------------;
 

;-----------------------------------------------------------------------;
; GetDataSelector - Get Data Selector for task				;
; 									;
; Returns Carry clear if DPMI segment is allocated for task, Selector 	;
;	  for task SMP area is store in DataSel				;
;-----------------------------------------------------------------------;

GetDataSelector	proc	near
		push	es
		push	esi

		mov	es,[scbsel]		; get SCB selector
		mov	esi,[scboffset]
		assume  es:scbs
		mov	ax,[esi+SCBTCBPC]	; get current tcb
		call	SegToSel
		mov	es,ax			
		assume  es:tcb
		mov	ax,[TCBDPMI]		; get DPMI selector
		or	ax,ax
		jnz	SelFound
		stc				; No Memory so force fail
		jmp	SelExit
SelFound:
		call	SegToSel
		mov	[DataSel],ax
		mov	ds,ax
		assume	ds:dseg		
		cmp	[Initialized],'Y'
		je	SelOk
;
; Selector must be initialized
;
		
		push	ax
		push	bx
		push	cx
		push	dx
		mov	[TCBDPMISel],ax

		mov	cx,ax
		mov	ax,word ptr [tcbunreg]
		mov	bx,word ptr [tcbunreg+2]	
		push	es
		mov	dx,es			; save tcb into dx
		mov	es,cx
		assume  es:dseg
		mov	word ptr [OrgUnRegister],ax
		mov	word ptr [OrgUnRegister+2],bx
		mov	[TCBSelector],dx
		pop	es
		assume  es:tcb
		mov	ax,word ptr [RUnreg]
		mov	word ptr [tcbunreg],ax
		mov	ax,word ptr [RUnreg+2]
		mov	word ptr [tcbunreg+2],ax		
				       
		mov	[Initialized],'Y'	
		mov	[DebugSetting1],0ffh
		mov	[DebugSetting2],0ffh
		mov	[DebugSetting3],0ffh
		mov	[DebugSetting4],0ffh
		call	WriteDebugRegs
		
		pop	dx	     
		pop	cx	
		pop	bx
		pop	ax
SelOk:
		pop	ds
		assume  ds:nothing
		clc
SelExit:
		pop	esi
		pop	es
		ret
GetDataSelector	endp
		

;-----------------------------------------------------------------------;
; SegToSel -  Converts Segment to Selector				;
;									;
; Input:								;
;	AX = Segment (Virtual Mode)					;
; Output:								;
;	AX = Selector for Segment					;
;-----------------------------------------------------------------------;

SegToSel	proc	near
		push	ebx
		mov	bx,ax
		mov	ax,SEGMENT_SELECTOR
		int	6fh		
		jc	short SegSel1
		mov	ax,bx		
SegSel1:
		pop	ebx
		ret
SegToSel	endp


;-----------------------------------------------------------------------;
; SelToSeg -  Converts Selector	to Segment				;
;									;
; Input:								;
;	AX = Selector for Segment					;
; Output:								;
;	AX = Segment (Virtual Mode)					;
;-----------------------------------------------------------------------;

SelToSeg	proc	near
		push	ebx
		mov	bx,ax
		mov	ax,SELECTOR_SEGMENT
		int	6fh		
		jc	short SelSeg1
		mov	ax,bx
SelSeg1:
		pop	ebx
		ret
SelToSeg	endp


;-----------------------------------------------------------------------;
; ReadDebugRegs - read current debug register into memory by calling    ;
; memory manager and than translates them into internal structures	;
;-----------------------------------------------------------------------;

ReadDebugRegs	proc	near
		push	eax
		push	ebx
		push	ecx
		push	es

		mov	es,[DataSel]
		assume  es:dseg
		lea	ebx,DebugRegisters
		mov	ax,WRITE_DEBUG
		int	6fh
;
;	Translate debug registers into internal structure
;	First transfer debug reg 8 dwords into Debug Address's 
;
		mov	ax,word ptr [DebugRegisters] 		; DR0
		mov	word ptr [DebugAddress1],ax
		mov	ax,word ptr [DebugRegisters+2] 		
		mov	word ptr [DebugAddress1+2],ax
		mov	ax,word ptr [DebugRegisters+4] 		; DR1
		mov	word ptr [DebugAddress2],ax
		mov	ax,word ptr [DebugRegisters+6] 		
		mov	word ptr [DebugAddress2+2],ax
		mov	ax,word ptr [DebugRegisters+8] 		; DR2
		mov	word ptr [DebugAddress3],ax
		mov	ax,word ptr [DebugRegisters+0ah] 		
		mov	word ptr [DebugAddress3+2],ax
		mov	ax,word ptr [DebugRegisters+0ch] 	; DR3
		mov	word ptr [DebugAddress4],ax
		mov	ax,word ptr [DebugRegisters+0eh] 		
		mov	word ptr [DebugAddress4+2],ax
;
;	Now scan DR6 and DR7 and derive debug register settings
;
		mov	cx,4
		lea	ebx,[DebugSetting1]
		xor	si,si		   
RDebugLoop:
		push	cx
		mov	ax,1
		or	si,si
		jz	short RDebug1
		mov	cx,si
		shl	cx,1
		dec	cx
		shl	ax,cl
RDebug1:
		test	word ptr [DebugRegisters+1ch],ax
		jnz	short RDebug2
;
;		we have found that this register in not set
;
		mov	byte ptr es:[ebx],0ffh		; make as unused
		mov	byte ptr es:[ebx+1],0		; clear status	
		jmp	short RDebugSkip
;
;		read R/W and LEN
;
		mov	ax,word ptr [DebugRegisters+1eh]
		or	si,si
		jz	short RDebug2
		mov	cx,si
		dec	cx
		shl	cx,4
		shr	ax,cl
RDebug2:
		and	ax,0fh
		mov	ah,al
		and	al,3h
		inc	al
		shl	ah,2
		and	ah,0f0h
		cmp	ah,030h
		jne	short RDebug3
		mov	ah,020h
RDebug3:		
		or	al,ah
		mov	byte ptr es:[ebx],al				
;
;		Now test status bit
;
		mov	ax,1
		or	si,si
		jz	short RDebug4
		mov	cx,si
		shl	cx,1
		dec	cx
		shl	ax,cl
RDebug4:
		xor	cx,cx		; indicate status not set
		test	word ptr [DebugRegisters+1ch],ax
		jz	RDebug5
		inc	cx		; indicate status set
RDebug5:
		mov	byte ptr es:[ebx],cl
RDebugSkip:
		pop	cx
		inc	si
		add	ebx,6
		dec	cx
		or	cx,cx
		jz	short RDebugExit
		jmp	RDebugLoop
RDebugExit:

		pop	es
		assume  es:nothing
		pop	ecx
		pop	ebx
		pop	eax
		clc
		ret
ReadDebugRegs	endp

;-----------------------------------------------------------------------;
; WriteDebugRegs - translates internal structures to memory manager     ;
; format and than calls memory manager to write set current debug regs  ;
;-----------------------------------------------------------------------;

WriteDebugRegs	proc	near
		push	eax
		push	ebx
		push	ecx
		push	es
		mov	es,[DataSel]
		assume  es:dseg
;
;	Translate internal structure into debug registers
;	First transfer Debug Address's into debug reg 8 dwords
;
		mov	ax,word ptr [DebugAddress1]
		mov	word ptr [DebugRegisters],ax 		; DR0
		mov	ax,word ptr [DebugAddress1+2]
		mov	word ptr [DebugRegisters+2],ax
		mov	ax,word ptr [DebugAddress2+2]
		mov	word ptr [DebugRegisters+4h],ax		; DR1
		mov	ax,word ptr [DebugAddress2+2]
		mov	word ptr [DebugRegisters+6h],ax
		mov	ax,word ptr [DebugAddress3]
		mov	word ptr [DebugRegisters+8h],ax		; DR2
		mov	ax,word ptr [DebugAddress3+2]
		mov	word ptr [DebugRegisters+0ah],ax
		mov	ax,word ptr [DebugAddress4]
		mov	word ptr [DebugRegisters+0ch],ax	; DR3
		mov	ax,word ptr [DebugAddress4+2]
		mov	word ptr [DebugRegisters+0eh],ax
;
;	Clear out DR6 and DR7, we will set them individually
;
		xor	eax,eax
		mov	[DebugRegisters+18h],eax		; DR6
		mov	[DebugRegisters+1Ch],eax		; DR7
;		
;	Now for each debug register set, set DR6 and DR7
;		
		mov	cx,4
		lea	ebx,[DebugSetting1]
		xor	si,si		   
WDebugLoop:
		cmp	byte ptr es:[ebx],0ffh
		je	short WDebugSkip
		push	cx
;
;		Mark it as Local
;
		mov	ax,1
		or	si,si
		jz	short WDebug1
		mov	cx,si
		shl	cx,1
		dec	cx
		shl	ax,cl
WDebug1:
 		or	ax,10h				; Mark GL 
		or	word ptr [DebugRegisters+1ch],ax
;		
;		Set R/W x and LEN x
;		First we must build the 4 bits
;
		mov	ah,byte ptr es:[ebx]		
		mov	al,ah
		and	ah,0fh
		dec	ah		
		and	al,0f0h
		cmp	al,020h
		jne	short WDebug2
		mov	al,030h
WDebug2:
		shr	al,2
		or	al,ah
		xor	ah,ah
;
;		Now we can mask bits into DR7 register
;
		or	si,si
		jz	short WDebug3
		mov	cx,si
		dec	cx
		shl	cx,4
		shl	ax,cl
WDebug3:
		or	word ptr [DebugRegisters+1eh],ax
;		
		pop	cx
WDebugSkip:		
		inc	si
		add	ebx,6			; point to next structure
		loop	WDebugLoop

;
		lea	bx,DebugRegisters
		mov	ax,READ_DEBUG
		int	6fh
;
		pop	es
		pop	ecx
		pop	ebx
		pop	eax
		clc
		ret
WriteDebugRegs	endp

;-----------------------------------------------------------------------;
; BXtoESI - Convert BX into ESI (Internal Pointer to structure)		;
;-----------------------------------------------------------------------;

BXtoESI		proc	near
		push	bx
		lea	esi,DebugSetting1
BXtoESILoop:
		or	bx,bx
		jz	short BXtoESIExit
		add	si,DBStrucSize
		dec	bx
		jmp	short BXtoESILoop
BXtoESIExit:
		pop	bx
		ret
BXtoESI		endp

;-----------------------------------------------------------------------;
; NumOfBanks - Calculate # of banks from BX:CX				;
; Input:								;
;	BX:CX = lenght of memory					;
; Output:								;
;	ECX = No of banks						;
;-----------------------------------------------------------------------;


NumOfBanks	proc	near
		add	cx,4095
		adc	bx,0
		xchg	bx,cx
		shl	ecx,8
		or	cx,bx		
		ret
NumOfBanks	endp

;-----------------------------------------------------------------------;
; ScanBanks - Scan Banks for available memory				;
; Input:								;
;      ECX = No of banks						;
; Output:								;
;	BX:DX = Physical Memory						;
;	SI = offset into memory table					;
;-----------------------------------------------------------------------;
		assume  es:dseg

ScanBanks	proc	near
		push	eax
		push	edi

		mov	[SmallestBank],0
		mov	si,[BankTabOffset]
		xor	edi,edi
ScanLoop:
		call	NextBank		; find next bank
		jc	short ScanDone
		cmp	eax,ecx
		je	short ScanFound		
		jb	short ScanNext
		cmp	eax,[SmallestBank]
		jae	short ScanNext
		mov	edi,esi			; store offset
		mov	[SmallestBank],eax	; store size
ScanNext:
		add	esi,eax
		jmp	short ScanLoop		
ScanDone:
		or	edi,edi
		jnz	short ScanOk
		stc	
		jmp	short ScanExit  
ScanFound:
		mov	edi,esi		
ScanOk:
		sub	di,[BankTabOffset]
		call	CalcPhyMemory
		clc		
ScanExit:
		pop	edi
		pop	eax
		ret
ScanBanks	endp


;-----------------------------------------------------------------------;
; NextBank - Next Bank in available memory				;
; Input:								;
;	SI = Next Position in physical memory table			;
; Output:								;
;	SI = Position in table						;
;	AX = size of memory block					;
;-----------------------------------------------------------------------;
		assume  es:dseg

NextBank	proc	near
		push	ecx
		push	edx
		push	edi
		mov	di,[SizeBank]
		shl	di,1
		add	di,[BankTabOffset]
		xor	cx,cx
NBFindClear:
		cmp	si,di
		jae	short NBError
		lodsw
		or	ax,ax
		jnz	short NBFindClear
		inc	cx
		mov	dx,si
		dec	dx
		dec	dx
NBLen:
		cmp	si,di
		jae	short NBend
		inc	cx
		lodsw	
		jz	short NBLen
		dec	cx
NBend:
		mov	ax,cx
		mov	si,dx				
		clc	
		jmp	short NBexit
NBError:
		stc				
NBExit:
		pop	edi
		pop	edi
		pop	ecx
		ret
NextBank	endp

;-----------------------------------------------------------------------;
; CalcPhyMemory - Calculate Physical Memory				;
; Input:								;
;	DI = Start Bank in allocated table				;
; Output:								;
;	BX:DX = Physical Memory						;
;-----------------------------------------------------------------------;
		assume  es:dseg

CalcPhyMemory	proc	near
		mov	bx,[StartBank]
		add	bx,di
		mov	dx,bx
		shl	dx,12
		shr	bx,4		
		ret
CalcPhyMemory	endp


;-----------------------------------------------------------------------;
; CheckBase - Check Base for against task memory			;
; Input:								;
;		CX:DX= 32-bit linear base address of segment		;
;	 								;
; Output:								;
;-----------------------------------------------------------------------;
		assume  es:dseg

CheckBase	proc	near
		ret
CheckBase	endp

;-----------------------------------------------------------------------;
; CheckLimit - Check Base for against task memory			;
; Input:								;
;		CX:DX= 32 bit segment limit				;
;	 								;
; Output:								;
;-----------------------------------------------------------------------;
		assume  es:dseg

CheckLimit 	proc	near
		ret
CheckLimit	endp



;-----------------------------------------------------------------------;
; CheckAccess - Check access writes for Selector			;
; Input:								;
;	CL = Low Access							;
;	CH = High Access						;
; Output:								;
;-----------------------------------------------------------------------;
		assume  es:dseg

CheckAccess	proc	near
		ret
CheckAccess	endp

;-----------------------------------------------------------------------;
; CallRealInt	- Call Real mode int					;					;
; Input:								;
;	[RealRegisters] = register to call routine			;
;	Interupt No;							;
; Output:								;
;-----------------------------------------------------------------------;
		assume  es:dseg
CallRealInt	proc	near
		mov	[RealIntNo],al		; store interupt #
		ret
CallRealInt	endp

EndProtect	label	byte

		assume  ds:nothing

code32		ends
		

;------------ END OF PROTECTED MODE CODE -------------------------------;

		.286c
init16		segment para public 'CODE'
		assume cs:ddt,ds:nothing,es:nothing,ss:nothing

;--- INITIALIZATION CODE -----------------------------------------------;

		subttl	ddtinit - mos device driver init
		page

;-----------------------------------------------------------------------;
; initialization - set driver length and exit				;
;-----------------------------------------------------------------------;
		assume	cs:ddt,ds:ddt,es:nothing

;
; Installation: Message and Data area
;

Copyright db	'PC-MOS DPMI Driver Version 1.00 (910430)',13,10
	  db	'(C) Copyright 1991, The Software Link, Incorporated.'
	  db	13,10,10
	  db	'Dos Protected Mode Insterface $'

MsgNotIns db	'Not '					;[1]	Must  be
MsgIns	  db	'Installed.',13,10,'$'			;[2]    Together

MsgMem	  db	'0000000K of Extended Memory Available.',13,10,'$'

No386	  db	'Intel i386 or i486 Microprocessor required.',13,10,'$'
No386sys  db	'386 Memory Manager required.',13,10,'$'
NoMem	  db	'Not Enought Extended Memory Installed for DPMI Used.',13,10,'$'
No32	  db	'Protected Code Initialization failed.',13,10,'$'
Already	  db	'DPMI Driver Already Installed.',13,10,'$'
NoMOS400  db    'This driver requires PC-MOS 4.10 or Higher.',13,10,'$'

Bit32Ok	  db	'N'				; Y means 32 Bit protected 
						; mode inited ok

;
; Installation: Main installation routine and subroutines
;


InstallDriver	proc	near
		mov	ax,cs
		mov	ds,ax
		mov	dx,offset Copyright
		mov	ah,9
		int	21h
;
; Check to See if On PC-MOS 4.00 or Higher
;
		call	CheckMOS
		jc	ErrorHandler
;
; Check To See is DPMI is already Installed
;
		call	CheckDPMI   		
		jc	ErrorHandler
;
; Check to see if ON 386 or 486
;
		call	CheckMicroProcessor
		jc	ErrorHandler
;
; Check For Memory Managment 
;
		call	CheckFor386SYS
		jc	ErrorHandler
;
; Allocate extended memory for Protected Mode code
;
		call	AllocateExtend
		jc	ErrorHandler
;
; At This Point We will Install driver
;
		call	InstallIt
		jc	ErrorHandler
		push	ax
		mov	dx,offset MsgIns
		mov	ah,9
		int	21h
		mov	dx,offset MsgMem
		mov	ah,9
		int	21h
		pop	ax
		ret
;
; This is where we will process an error
;
ErrorHandler:
		call	FreeExtend			; Free Extended memory
		push	dx
		mov	dx,offset MsgNotIns
		mov	ah,9
		int	21h
		pop	dx
		mov	ah,9 			; display error message
		int	21h
		xor	ax,ax			; driver not installed
		ret
InstallDriver   endp


;--------------------------------------------------------------------;
; CheckMOS - The following Procedure which see if PC-MOS is Installed;
; If so it will check if Version is 4.00 or higher, if so it will    ;
; scbseg and tcbseg to SCB and TCB segments			     ;
;--------------------------------------------------------------------;

CheckMOS	proc	near
		mov	bx,-1
		mov	ah,30h
		int	21h
		push	ax
		mov	ah,30h
		mov	bx,ax
		mov	cx,ax
		mov	dx,ax
		int	21h
		pop	bx
		cmp	ax,bx
		jne	NotMos
		cmp	al,04h
		jb	NotMos
		jne	Not400
		or	ah,ah
		jz	NotMos
Not400:
		mov	ah,2
		int	0d4h
		mov	[scboff],bx
		mov	[scbseg],es
		clc
		ret		
NotMos:
		mov	dx, offset NoMOS400
;		stc
		clc
		ret
CheckMOS	endp


;--------------------------------------------------------------------;
; CheckDPMI - The following procedure is use to check to see if DPMI ;
; is already installed by doing an INT 2f function 1689h.	     ;
;--------------------------------------------------------------------;

CheckDPMI	proc	near
		mov	ax,1689h		; check for DPMI
		int	2fh
		or	ax,ax
		jne	NoDPMI
		mov	dx,offset Already
		stc
		ret
NoDPMI:
		clc				; this means that we can load
		ret
CheckDPMI	endp


;--------------------------------------------------------------------;
; CheckMicroProcessor - The following procedure which check CPU for  ;
; A i386 (or 386 SX) or 486 MicroProcessor.  If so it will set 	     ;
; MicroProcessor Variable to type of CPU found on system.	     ;
;--------------------------------------------------------------------;	

CheckMicroProcessor proc	near
		push	ax
		push	bx
		push	cx
		push	dx

		pushf
		xor	ax, ax
		push	ax
		popf			; try to put zero in flags
		pushf
		pop	ax
		and	ax, 0F000H
		mov	bl, I86		; indicate 808X series
		cmp	ax, 0F000H
		je	begin5

		mov	bl, I386	; indicate 80386 series
		mov	ax, 0F000H	; try to but 1's in high bits
		push	ax
		popf
		pushf
		pop	ax
		and	ax, 0F000H
		jne	cpuver
	
		dec	bl		; indicate 80286 series
		push	sp
		pop	ax
		cmp	ax, sp		; test for prefetch
		je	cpuver
		mov	bl,I86
	
begin5:
		mov	cx, 33
		mov	al, 0ffh
		shl	al, cl
		jz	cpuver		; must be an 808X series
		mov	bl, I186	; indicate 8018X series
	

cpuver:
		popf
		cmp	bl,I386	
		jne	not386
;
;	now we will test for 486
;
		.386
		mov	edx,esp
		and	esp,not 3
		pushfd
		pop     eax
		mov	ecx,eax
		xor	eax,40000h
		push	eax
		popfd
		pushfd	
		pop	eax
		xor	eax,40000h	; Intel Manual is incorrect
		shr	eax,18
		and	eax,1
		push	ecx
		popfd
		mov	esp,edx
		.286
		or	al,al
		jnz	not386
		inc	bl
	
not386:
		mov	[Microprocessor],bl
		cmp	bl,I386
		ja	CpuOk
		mov	dx,offset No386
 		stc
		jmp	short CpuExit
CpuOk:
		clc
CpuExit:

		pop	dx
		pop	cx
		pop	bx
		pop	ax
		ret
CheckMicroProcessor endp


;--------------------------------------------------------------------;
; CheckFor386SYS - The following procedure will check to see if 386  ;
; driver is installed for MOS and Driver has correct features to     ;
; support DPMI.							     ;
;--------------------------------------------------------------------;

CheckFor386SYS	proc	near
		push	ds
		lds	si,[scbadr]		
		assume	ds:scbs
		cmp	[si+scbmmfg],'Y'
		jne	NoMemdev
		test	[si+scbmmfea],40h		; io protection enable
		jz	NoMemdev
		mov	ax,word ptr [si+scbmmsub]
		mov	word ptr cs:[memman],ax
		mov	ax,word ptr [si+scbmmsub+2]
		mov	word ptr cs:[memman+2],ax
		pop	ds
		clc
		ret
NoMemdev:
		pop	ds
		mov	dx,offset No386Sys
		stc
		ret
CheckFor386SYS  endp

;---------------------------------------------------------------------;
; AllocateExtend - allocated extended memory for protected mode code  ;
;---------------------------------------------------------------------;

AllocateExtend	proc	near
		lea	cx,EndProtect+4095	; round up 4k
		lea	ax,BeginProtect
		sub	cx,ax		
		shr	cx,12
		push	cx
		mov	ah,1
		call	cs:[memman]
		or	ax,ax
		jnz	ErrMem
		or	cx,cx
		jz	ErrMem
		pop	ax
		cmp	cx,ax
		jb	ErrMem1
		mov	[ExtendMem],cx
		mov	[ExtendHand],bx
		clc
		ret
ErrMem:
		pop	cx
ErrMem1:
		mov	dx,offset NoMem
		stc
		ret
AllocateExtend  endp

;---------------------------------------------------------------------;
; FreeExtend - free extended memory for protected mode code  	      ;
;---------------------------------------------------------------------;

FreeExtend	proc	near
		cmp	[ExtendMem],0
		je	SkipFree
		push	dx
		mov	bx,[ExtendHand]
		mov	cx,[ExtendMem]
		mov	ah,2
		call	cs:[memman]
		pop	dx
SkipFree:
		ret

FreeExtend	endp


;---------------------------------------------------------------------;
; Init32Code - Setup Use32 code and call native mode initialization   ;
; code.								      ;
;---------------------------------------------------------------------;	

Init32Code 	proc	near
		mov	ax,cs
		mov	[DriverRealCS],ax
		mov	ax,offset Unregister
		mov	word ptr [RUnreg],ax
		mov	ax,cs
		mov	word ptr [RUnreg+2],ax
		goprot				; go to protected mode
		.386
		lea	ecx,ddt:EndProtect+3
		lea	eax,ddt:BeginProtect
		sub	ecx,eax
		.286
		call32	InitProtect
		goreal				; go back to vm386
		cmp	[Bit32Ok],'Y'
		jne	Init32Err
		clc
		ret
Init32Err:
		mov	dx,offset No32
		stc
		ret
Init32Code	endp

;---------------------------------------------------------------------;
; InstallIt - This Procedure is Use to Installed the Driver once      ;
; Every Thing as check out.					      ;
;---------------------------------------------------------------------;	

InstallIt	proc	near
		call	Init32Code
		jc	InstallBad
		call	SetVectors
		mov	ax,offset EndOfDPMI
		les	bx,[Request]
		mov	word ptr es:[bx+14],ax
		mov	es:[bx+16],cs
		mov	ax,0100h
		clc
InstallBad:
		ret
InstallIt	endp


SetVectors	proc	near
		push	ds
		push	es

		mov	ax,352fh
		int	21h
		mov	word ptr [Old2f],BX
		mov	word ptr [Old2f+2],es
		
		mov	ax,252fh
		mov	dx,offset Dpmi2f
		int	21h


		pop	es
		pop	ds
		ret
SetVectors	endp

init16		ends

	.386p
init32	segment para public 'CODE' use32
	assume	cs:ddt

;-------------------------------------------------------------------;
; InitProtect - Initial Protected mode memory, copy Use32 resident  ;
; code to extended memory allocated earlier, do all Protected mode  ;
; initializations.						    ;
;	DS-> Selector for Device Drivers VM386 Mode Code Segment    ;
;	ES-> Selector for Extended Memory to place code		    ;
;	ECX -> Size of Memory to Tranfer			    ;
;-------------------------------------------------------------------;

InitProtect 	proc	near
		mov	ax,[scbseg]		; segment for SCB
		call	SegtoSel
		mov	[scbsel],ax		; place segment back
		xor	eax,eax
		mov	ax,[scboff]
		mov	[scboffset],eax		
		shr	ecx,2
		cld
		rep	movsd
		mov	[Bit32Ok],'Y'
		clc
		ret
InitProtect	endp

init32	ends

		end

