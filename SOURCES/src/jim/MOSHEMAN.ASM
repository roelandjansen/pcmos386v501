	include PAGE.INC
	title	MOSHEMAN - MOS Heap Manager

;-----------------------------------------------------------------------;
;									;
;		Development Specification				;
;									;
;									;
; Program Name: $$MOS.COM		Assigned to: David Morrow	;
; Module Name:	MOSHEMAN		Assign date: 01/20/86		;
; Entry Points: MOSHEMAN		Completed:   01/29/86		;
; Entry From:	MOSxxxxx						;
; Entry Method:	CALL							;
; Calls:	-							;
; Purpose:	Heap Management						;
; Refer to:	-							;
; Last Update:	03/22/90						;
;									;
;	This module is used to allocate or deallocate a block of space	;
;	on the heap.  In allocation, the logic should search for the	;
;	smallest block of available heap space that will satisfy the	;
;	need.								;
;									;
; Update History:							;
;	02/10/86 Added 'SHRINK BLOCK' call - DAM			;
;	02/24/86 Added mos group and other changes for ROMability	;
;	03/04/86 Fixed bug of not setting DS to SCBSEG			;
;	08/01/86 Updated 'assume' statements and verified segment	;
;		 register usage.					;
;	08/29/86 Added % heap usage call				;
;	09/15/86 Removed calls to SEGFILL to improve performance	;
;	10/15/86 Added additional info on heap corrupted message	;
;	02/24/87 Split heap logic, using split blocks			;
;									;
;-----------------------------------------------------------------------;
;	08/27/87 Added storing of SCBHPALC for later retrival in MOS MAP;
;		 command. Contains allocated heap so far		;
;-----------------------------------------------------------------------;
; SAH	10/20/87 remove references (unused) to mosdebug			;
;-----------------------------------------------------------------------;
; SAH   01/19/88 change SCBSEG and ZERO seg access to MGetXXX macros	;
;		 made sure that SMP is always allocated in size of 64	;
;		 bytes (include 16 byte header)				;
; SAH   01/25/88 Corrected problem associated with 286 driver which     ;
;		 show a bug in 01/19/88 change which we sure mot round  ;
;		 up value past to INIT routine				;
;-----------------------------------------------------------------------;
; SAH   02/12/88 Corrected 01/19/88 Change for 64 byte SMP allocations  ;
;-----------------------------------------------------------------------;
; sah\rdr 02/20/88 Move DDT Segment to MO2 Group			;
;-----------------------------------------------------------------------;
; RBR   03/11/88 Added declares/undeclares for 286 driver.              ;
;-----------------------------------------------------------------------;
; SAH 	11/26/89 Clean up implementation of split heap.			;
;-----------------------------------------------------------------------;
; BWR	11/29/89 Marked messages for foreign language translation	;
;-----------------------------------------------------------------------;
; SAH   12/08/89 Conditional Assemble 286 Driver Logic Out.		;
;-----------------------------------------------------------------------;
; SAH   12/15/89 Implement split smp, into primary and secondary SMP's	;
;-----------------------------------------------------------------------;
; SAH   02/21/90 Corrections so that large heap is allocated first	;
;-----------------------------------------------------------------------;
; SAH   03/22/90 Corrections for device drivers in 2 heaps.		;
;-----------------------------------------------------------------------;

	include OPTIONS.INC
	include GROUP.INC
	.xlist
	include mosregs.inc

tcb	segment at 1234h
tcb	ends

gdata	segment	word public 'data'

extrn	SCBHPADR:word		; Segment address of start of Heap
extrn	SCBHPSIZ:word		; Length of Heap in paragraphs
extrn	SCBCURSZ:word		; Current block size (during call)
extrn	SCBCURAD:word		; Current block address (during call)
extrn	SCBAVSIZ:word		; Current available size (last call)
extrn   SCBHPALC:word		; Latest heap allocation (total)
extrn   SCBMMSUB:dword		; Memory management routines
extrn   SCBMMFEA:byte		; Memory management feature bits
extrn	SCBHP2ADR:word		; Segment address of start of Heap #2
extrn	SCBHP2SIZ:word		; Length of Heap #2 in paragraphs
extrn	SCBSMPLOW:byte		; allocated down in low SMP memory.
extrn   SCBHP1ALC:word		; Latest heap allocation (total for SMP 1)


if	CODE286
extrn	SCB286DEC:byte		; OK to declare 286 segments
endif

gdata	ends

irq	segment	byte public 'data'
irq	ends

poll	segment	byte public 'data'
poll	ends

ddt     segment word public 'code2'
ddt     ends

	page
mosseg	segment	word public 'code1'
	assume	cs:mos, ds:grp, es:nothing, ss:tcb

	extrn	mosend:byte, sbios:word
	extrn	bugerror:near		; Critical error reporter routine
	extrn	noswitch:near		; Critical flag routines
	extrn	okswitch:near		; "	"	"

	public	mosheman, ChkHeap

	.list
	; Local data

pval	dw	100		; Used as constant in HPuse
FillStr	db	'Heap'		; String used for init of heap memory

FunTabl	dw	mos:Inith, mos:Allocate, mos:Deallo, mos:Shrink, mos:HPuse
funtlen	equ	($-FunTabl)/2 - 1

	subttl	MOSHEMAN - Main entry point

	page
;-----------------------------------------------------------------------;
;	This module will allocate or deallocate a block of space in the	;
; operating system 'heap'.  Memory is allocated as a linked list within	;
; the heap.  Each block allocated is a multiple of 16 bytes, and	;
; includes a control prefix having the following format:		;
;									;
;	Byte 0   - 'H' to indicate allocated from the heap		;
;	Byte 1   - Type of block (e.g., 'T' = TCB), 'Z' is reserved	;
;	Byte 2-3 - Length of this block in paragraphs			;
;	Byte 4-5 - Segment address of next block, 0 if last		;
;	Byte 6-7 - Segment address of previous block, 0 if first	;
;	Byte 8-9 - Address of next block of same type			;
;	Byte A-B - Address of previous block of same type		;
;	Byte C-D - Address of associated TCB				;
;	Byte E-F - RESERVED						;
;	Byte 10+ - Data							;
;									;
; MOSHEMAN will initialize the 'Block of same type' pointers, bytes	;
; 8H - 0BH, to zero but these pointers must be maintained by the	;
; routines that use them.  MOSHEMAN will not modify them.		;
;									;
;  On Entry:								;
;	AH = Request code - 0=allocate, 1=deallocate, 2=shrink block	;
;		 3= % usage, 0ffH=init, 0FEh = INIT #2			;
;	DX = Size requested, in paragraphs (allocate and shrink)	;
;	ES = Address of block (deallocate and shrink)			;
;									;
;	For INIT, AH = 0FFH, ES=HEAPADDR, DX=HEAPSIZE (in paragraphs)	;
;		  AH = 0FEH, ES=HEAPADDR, DX=HEAPSIZE (in paragraphs)	;
;									;
;  On Exit:								;
;	AL = Exit code, 0 = successful					;
;			1 = requested size not available (allocate only);
;			2 = bad block address (deallocate and shrink)	;
;			3 = unknown command				;
;									;
;	DX = number of paragraphs allocated (allocate and shrink)	;
;	     (or # available, 0 if no heap space at all)		;
;									;
;	ES = Address of block (allocate and shrink), undefined if error	;
;									;
;	For AH = 2 - AX = Formated ASCII % value AL=high digit, AH=low	;
;		     BX = Integer % value (for calculations)		;
;									;
;	The heap is the only global data affected			;
;	No global procedures called					;
;									;
;	The AX, DX and ES registers are modified as documented.  In	;
;	the case of an error ES is undefined.  All other		;
;	registers are preserved.					;
;									;
;	Updated: 01/19/88 Each block is force to be multibles of 64     ;
;	bytes including 16 byte header.					;
;-----------------------------------------------------------------------;
	 page
mosheman proc	near
	assume	ds:nothing, es:nothing

	push	bx
	push	cx
	push	si
	push	di
	push	ds
	cmp	ah,0feH		; Init code?
	jae	okfun
	cmp	ah,funtlen	; Validate function code
	jb	okfun
	mov	al,3		; Unknown command
	jmp	nothin		; They ask for nothing they get it!
okfun:
	MGetSCB ds		; Assure addressing SCB data
	assume	ds:grp
	call	noswitch	; Set MOS no switch flag
	cmp	ah,0feh
	jne	NotHfe		; check if Heap # 2 init call
	call	inith2		; init secondary heap
	jmp	short HPskip
NotHfe:
	cmp	ah,0ffH		; Is this an init call?
	je	Shpchk		; Yes, skip heap check
	call	ChkHeap		; Check for heap corruption
Shpchk:
	xor	bh,bh		;
	mov	bl,ah		; Function code
	add	bl,1		; Calc routine index
	shl	bx,1		; Word index

if	CODE286
	;	SAH 01/19/88	Make sure SMP is alocate in mult 64 (inc head)
	push	dx
	cmp	ah,0ffh
	je	skipha
	cmp	dx,-1		; SAH 02/16/88
	je	skipha		; SAH 02/16/88
	or	dx,7		;031188
	inc	dx		; SAH 02/16/88
skipha:
endif

	call	[bx+FunTabl]	; Execute routine requested

	;	SAH 01/19/88
if	CODE286
	pop	cx
	cmp	dx,-1		; SAH 02/16/88
	je	HPskip		; SAH 02/16/88
	mov	bx,cx
	or	bx,7		;031188
	inc	bx		; SAH 02/16/88
	cmp	dx,bx
	jne	HPskip
	mov	dx,cx
endif

HPskip:
	call	okswitch	;
nothin:
	pop	ds
	pop	di
	pop	si
	pop	cx
	pop	bx
	ret			; End MOSHEMAN

	subttl	Init - Heap initialization

	page
;-----------------------------------------------------------------------;
;	Init will initialize the heap by setting up one block the size	;
;	of the heap and mark it as the first and last block and that it	;
;	is free.  The data area will be filled with the string 'Heap'	;
;	for easy reference during debugging.  If a re-init call is made	;
;	then any existing heap entries are preserved and the heap is	;
;	adjusted upward in memory if the space is available.		;
;									;
;   On Entry:								;
;	ES=HEAPADDR, 0 for default to present value if this is a	;
;			re-init						;
;	DX=HEAPSIZE (in paragraphs)					;
;									;
;   On Exit:								;
;	The memory area starting at segment ES and of length DX paras	;
;	is initialized for heap usage as one block marked as free space	;
;									;
;	The Heap is the only global data affected			;
;	No global procedures called					;
;									;
;	All registers are preserved.					;
;-----------------------------------------------------------------------;

Inith	proc	near
	push	ax
	mov	ax,es		; Get HEAPADDR
	or	ax,ax		; Check for re-init
	jz	SkipHeap
	mov	[SCBHPADR],ax	; Set Heap Address
	mov	[SCBHPSIZ],dx	    ; Set Heap size
	call	SetHeap
	mov	dx,[SCBHPSIZ]	; Return with original DX
	mov	word ptr [SCBHPALC],0	; SAH initialize to zero
SkipHeap:
	pop	ax
	ret
;
;	Init secondary heap code
;
Inith2:
	push	ax
	mov	ax,es		; Get HEAPADDR
	or	ax,ax		; Check for re-init
	jz	SkipHeap2
	mov	[SCBHP2ADR],ax	; Set Heap Address
	mov	[SCBHP2SIZ],dx	    ; Set Heap size
	call	SetHeap
	mov	dx,[SCBHP2SIZ]	; Return with original DX
SkipHeap2:
	pop	ax
	ret
;
;      Init heap common code 
;		
SetHeap:
	mov	byte ptr es:[0],'H' ; Set Heap indicator
	mov	byte ptr es:[1],'Z' ; Set block type to 'free'
	mov	word ptr es:[2],dx  ; Set block length, paragraphs
	mov	word ptr es:[4],0   ; Blank 1st block pointer
	mov	word ptr es:[6],0   ; Blank last block pointer
	mov	word ptr es:[8],0   ; Blank address of next same type
	mov	word ptr es:[0aH],0 ; Blank address of previous same type
	mov	word ptr es:[0cH],0 ; Blank address of assoc. TCB
	mov	word ptr es:[0eH],0 ; Blank reserved word
	inc	ax		    ; Point to next paragraph
	dec	dx		; # paragraphs minus block prefix
	add	dx,ax		; Calc end segment
;
;	Mark rest of block with 'Heap'
;
	push	es
	push	ds
	mov	cx,cs
	mov	ds,cx		; for accessing constant FillStr
SegFlp:
	mov	es,ax		; Set segment
	xor	di,di		;
	mov	cx,4		; 4 strings per segment
lp1:
	mov	si,offset FillStr	;
	movsw
	movsw			; faster method of moving 4 characters
	loop	lp1		;
	inc	ax		; Next seg
	cmp	ax,dx		; End of heap?
	jb	SegFlp		; Not yet
	pop	ds
	pop	es
	ret
Inith	endp

	subttl	HPuse - Calculate % Heap Used

	page
;-----------------------------------------------------------------------;
; HPuse will calculate the percentage of the heap that has been		;
; allocated.  Two values will be passed back, one in integer form	;
; suitable for making calculations, and the other in ASCII for use in	;
; displays.  The ASCII form is returned with the high digit in the low	;
; byte of the register so that all that needs to be done is		;
; a MOV [MSG],AX.							;
;									;
;   On Entry:								;
;	DS -> grp							;
;									;
;   On Exit:								;
;	AX = ASCII form of % heap used					;
;	DX = Integer form of % heap used				;
;									;
;	No global data affected						;
;	No global procedures called					;
;									;
;	AX and DX return values all other registers are preserved.	;
;-----------------------------------------------------------------------;
HPuse	proc	near
	assume	ds:grp
	push	es
	push	bx
	mov	bx,[SCBHPADR]	; Start at beginning of heap
	xor	ax,ax		; AX will hold running count of free blocks
usedlp:
	or	bx,bx		; End of list?
	jz	endlook		; Yes
	mov	es,bx		; Address next block
	assume	es:nothing
	cmp	byte ptr es:[1],'Z'	; Is this a free block?
	je	lookfre			; Yes, skip counting it
	add	ax,es:[2]	; Get block length
lookfre:
	mov	bx,es:[4]	; Get pointer to next block
	jmp	short usedlp
endlook:
	mov	[SCBHPALC],ax	; SAH store heap count
	mov	[SCBHP1ALC],ax	; Save Heap #1 count
	mov	bx,[scbhp2adr]
	or	bx,bx		; Secondary heap used
	jz	skipuse2
	xor	ax,ax		; AX will hold running count of free blocks
usedlp2:
	or	bx,bx		; End of list?
	jz	endlook2	; Yes
	mov	es,bx		; Address next block
	assume	es:nothing
	cmp	byte ptr es:[1],'Z'	; Is this a free block?
	je	lookfre2		; Yes, skip counting it
	add	ax,es:[2]	; Get block length
lookfre2:
	mov	bx,es:[4]	; Get pointer to next block
	jmp	short usedlp2
endlook2:
	add	[scbhpalc],ax	; add value for second heap
skipuse2:
	mov	ax,[scbhpalc]	
	xor	dx,dx
	mul	[pval]		; MUL by 100 for %
	mov	bx,[SCBHPSIZ]	; Check for round up from .5%
	add	bx,[scbhp2siz]	; add value for second heap
	div	bx		; Calc how much of total heap used
	shr	bx,1
	cmp	dx,bx		; Is remainder more than half a %
	jb	nornd		; No
	inc	al
nornd:
	cmp	ax,100		; If 100% then return 99%
	jne	nomax
	dec	ax
nomax:
	mov	dx,ax		; Save integer value
	aam			; Convert to ASCII
	add	ax,3030H	;	"	"
	xchg	al,ah		; Make suitable for word store into message
	cmp	al,'0'		; Is value less than 10%?
	jne	gtten		; No, greater than 10
	mov	al,' '		; Clear off leading zeros
gtten:
	pop	bx
	pop	es
	ret
HPuse	endp

	subttl	Allocate - Allocate a block on Heap


	page
;-----------------------------------------------------------------------;
;	This routine will allocate a block of memory on the Heap 	;
;	starting at segment ES and of size DX paragraphs.  The smallest	;
;	block that satisfies the need will be used.			;
;									;
;  On Entry:								;
;	DX = number of paragraphs needed.				;
;									;
;  On Exit:								;
;	AL = 0 if successful, else error code				;
;	   = 1 if 'Size not available' error				;
;	ES = segment address of block, undefined if error		;
;	DX = number of paragraphs allocated				;
;	     (or # available, 0 if no heap space at all)		;
;									;
;	The Heap is the only global data affected			;
;	No global procedures called					;
;									;
;	AX,  DX, and ES used to return parms, all others unchanged.	;
;-----------------------------------------------------------------------;

Allocate proc	near
	assume  ds:grp
	push	bx		  ; save bx register
	mov	[SCBCURSZ],0ffffH ; Default current size to GIANT
	mov	[SCBAVSIZ],0	  ; Init available size to 0
	cmp	[SCBHP2SIZ],0	  ; if only 1 heap skip, force low test	
	jne	Do2Heaps
;
;
;	We will Scan Heap #1 Only If Heap #2 is not being used
;
	mov	bx,[SCBHPADR]
	jmp	short DoScan
;
; 	The following logic is added to handle 2 SMP's.  First we will
;	check to see if ldevice is specified and if so we will force the
;	allocation to be allocated in 2nd heap
;	
Do2heaps:	
	mov	bx,[SCBHP2ADR]	  ; access 2 heap
	test	[SCBSMPLOW],1	  ; is this requested to allocate down low	
	jnz	DoScan		  ; yes....for LDEVICE	
	call	FindLar		  ; Largest Block is return in BX
;
;	Common  Scan Heap Scan Logic
;
DoScan:
	or	bx,bx		; Last block?
	jz	NoBlks		; Yes
	mov	es,bx		; Set pointer to next block
	call	FindFre		; Find free block (return ES pointer, AX size)
	or	ax,ax		; Any free blocks left?
	jz	NoBlks		; Nop, no more free blocks
	mov	bx,es:[4]	; Get address for next block
	cmp	ax,[SCBAVSIZ]	; Is this one larger than others checked?
	jbe	noavail		; No, smaller
	mov	[SCBAVSIZ],ax	; Set new availalble size
noavail:
	cmp	dx,ax		; Large enough?
	ja	DoScan		; No, try another
	cmp	ax,[SCBCURSZ]	; Smaller than previous block?
	jae	DoScan		; No, try yet another block
	mov	[SCBCURSZ],ax	; Set this block as the one we want
	mov	[SCBCURAD],es	; Set segment pointer to it
	jmp	short DoScan	; Try for a smaller one still
NoBlks:
	pop	bx
	cmp	[SCBCURSZ],0ffffH ; Any block available?
	je	endavail	  ; No, return with available size
RetHeap:
	mov	ax,[SCBCURSZ]	; Get the smallest that suits the need
	mov	es,[SCBCURAD]	; Get pointer to that block
	sub	ax,dx		; Calc # para's left over
	or	ax,ax		; Perfect fit?
	jnz	BlkAdj		  ; No, must adjust blocks
	mov	byte ptr es:[1],0 ; Clear Free block type (i.e. 'Z')
	ret			  ; End of Allocation, AL=0 return code

	page
endavail:
	mov	dx,[SCBAVSIZ]	; Tell what size is available
	mov	al,1		; Size not available error code
	ret
BlkAdj:
	push	ds
	push	ax		; Temp save size of adjustment
	mov	ax,es		; Address of current block

	push	ax		;031188

	add	ax,dx		; Calc seg address of next block

if	CODE286
	test	[scbmmfea],08h	;031188  286 driver?
	jz	allno286	;031188  no, skip
	push	ax		;031188
	push	bx		;031188
	push	cx		;031188
	mov	bx,ax		;031188
	mov	ah,0ah		;031188
	xor	cl,cl		;031188
	call	[scbmmsub]	;031188
	pop	cx		;031188
	pop	bx		;031188
	pop	ax		;031188
allno286:			;031188
endif

	mov	es,ax		; Point to next block
	pop	ds		;031188  ds points to current block
	assume	ds:nothing	;031188

; Update current control prefix

	mov	byte ptr ds:[1],0 ; Clear Free block type (i.e. 'Z')
	mov	ds:[2],dx	  ; Set new 'length' field
	mov	dx,ds:[4]	; Get pointer to next block (old one)
	mov	ds:[4],ax	; Set seg of 'next block' field

; Update old next block

	or	dx,dx		; Is this the 1st block?
	jz	nopadj
	push	ds
	mov	ds,dx
	mov	ds:[6],es	; Set new 'previous block' field
	pop	ds
nopadj:

; Create new control prefix for next block

	mov	byte ptr es:[0],'H' ; Indicate allocated from heap
	mov	byte ptr es:[1],'Z' ; Indicate as free block
	pop	ax		    ; Restore size adjustment
	mov	es:[2],ax	; Set 'length' field
	mov	es:[4],dx	; Set 'next block' field
	mov	ax,ds		; Get address of previous block
	mov	es:[6],ax	; Set 'previous block' field
	xor	ax,ax		;
	mov	es:[8],ax	; Zero out 'type' addresses
	mov	es:[0aH],ax	;
	mov	es:[0cH],ax	; Zero out 'TCB' field
	mov	es:[0eH],ax	; Zero out 'Reserved' field
	mov	dx,ds		; Address of block just allocated
	pop	ds		; Restore original DS
	assume	ds:grp
	mov	es,dx		; Set return address to allocated block
	mov	dx,es:[2]	; Get length for return
	ret			; End successful allocation
Allocate endp

;-----------------------------------------------------------------------;
; FindLar - Find Largest Heap					      	;
;								      	;
; This routine will return Block with Largest possiable Heap	      	;
;								      	;
; Entry:								;
; Exit:   BX -> Largest heap (either SCBHPADR or SCBHP2ADR)		;
;-----------------------------------------------------------------------;

FindLar	proc	near
       	push	cx
       	mov	bx,[SCBHPADR]		; scan Heap #1 for largest
       	call	ScanLar		
       	push	ax			; save largest available
	mov	bx,[SCBHP2ADR]		; scan Heap #2 for largest
	call	ScanLar
	pop	cx
	cmp	ax,cx	   		; is heap #2 > Heap #1
	ja	Heap2Lar     		; yes.. return heap #2 address
	mov	bx,[SCBHPADR]		; no... return heap #1
Heap2Lar:
	pop	cx
	ret
FindLar	endp		

;-----------------------------------------------------------------------;
; ScanLar - Scan Heap for Largest Block				  	;
;									;
; Entry: BX -> heap to search (Either SCBHPADR or SCBHP2ADR)		;
; Exit:  AX -> Largest Block found in heap				;
;-----------------------------------------------------------------------;

ScanLar	proc	near
       	push	bx
       	xor	cx,cx		; init to nothing
SrchLLoop:
	or	bx,bx		; Last block?
	jz	LNoBlks		; Yes
	mov	es,bx		; Set pointer to next block
	call	FindFre		; Find free block (return ES pointer, AX size)
	or	ax,ax		; Any free blocks left?
	jz	LNoBlks		; Nop, no more free blocks
	mov	bx,es:[4]	; Get address for next block
	cmp	ax,cx		; Is this one larger than others checked?
	jbe	SrchLLoop	; No, smaller
	mov	cx,ax		
	jmp	short SrchLLoop	; and continue searching
LNoBlks:
	mov	ax,cx		; return largest available block
	pop	bx
	ret
ScanLar	endp		

;-----------------------------------------------------------------------;
;	This routine will point to the next available block of memory	;
;	on the heap.							;
;									;
;  On Entry:								;
;	ES = address of starting block for search			;
;									;
;  On Exit:								;
;	ES = address of free block					;
;	AX = size of free block, 0 if no free blocks availible		;
;									;
;	No global data affected						;
;	No global procedures called					;
;	AX and ES are changed accordingly, BX register is destoryed.	;
;-----------------------------------------------------------------------;

FindFre	proc	near
	xor	ax,ax			; Assume no free blocks
	mov	bx,es			; Starting pointer
FFloop:
	mov	es,bx		    	; Point to next block
	cmp	byte ptr es:[1],'Z' 	; Is this a free block
	je	endfre		    	; Yes, exit accordingly
	mov	bx,es:[4]		; Get seg of next block
	or	bx,bx			; Last block?
	jnz	FFloop			; No, not yet - keep on truckn'
	ret				; No free blocks, exit with AX=0
endfre:
	mov	ax,es:[2]		; Get # para's for this block
	ret
FindFre	endp


	subttl	Deallo - Deallocate a block on the Heap

	page
;-----------------------------------------------------------------------;
;	This routine will deallocate a specified block of memory on the	;
;	heap.  If the specified block is adjacent to any other free	;
;	blocks then they will be combined into one common free block.	;
;									;
;  On Entry:								;
;	ES = segment address of block to deallocate			;
;									;
;  On Exit:								;
;	AL = error code.  0 = successful				;
;			  2 = bad block address				;
;									;
;	The heap is the only global data affected			;
;	No global procedures called					;
;									;
;	AX, CX, SI, and DI are destroyed.  All others preserved.	;
;-----------------------------------------------------------------------;

Deallo	proc	near
	push	es
	push	ds
	push	ax
	cmp	byte ptr es:[0],'H' ; Is this a valid block?
	je	$+5		    ; Yes, continue
	jmp	BadAdr		    ; No, bad block address
	mov	byte ptr es:[1],'Z' ; Mark block as free
	mov	ax,es		    ;
	mov	ds,ax		; Point to block to be deallocated
	assume	ds:nothing
	mov	ax,ds:[6]	; Get address of previous block
	or	ax,ax		; Is this the first block?
	jz	TryNext		; Yes, check on the next block
	mov	es,ax		    ; Point to previous block
	cmp	byte ptr es:[1],'Z' ; Is this block free?
	jne	TryNext		    ; No, try the next block
	call	Combine		; Combine the blocks ES and DS
TryNext:
	mov	ax,ds:[4]	; Get address of next block
	or	ax,ax		; Is this the last block?
	jz	EndDeallo	; Yes, no need to check for it free
	mov	es,ax		    ; Point to next block
	cmp	byte ptr es:[1],'Z' ; Is the next block a free one?
	jne	EndDeallo	    ; No, that's all, exit
	call	Combine		; Combine the free blocks at ES and DS
EndDeallo:
	mov	ax,ds		; Get start of fill address
	push	dx
	mov	dx,ax		; Calc end of fill address
	add	dx,ds:[2]	; Add length of this block
	pop	dx
	pop	ax		; Original AX back
	xor	al,al		; Deallocation complete
	pop	ds
	assume	ds:grp
	pop	es
	ret			; End Deallo

	page
BadAdr:
	pop	ax		; Original AX back
	mov	al,2		; Bad block address error code
	pop	ds
	pop	es
	ret			; End Deallo
Deallo	endp

	subttl	Shrink - Shrink specified block to a new size
	page
;-----------------------------------------------------------------------;
;	This routine will shrink a block in the heap to a smaller size	;
;	than initially allocated.					;
;									;
;  On Entry:								;
;	ES = segment address of block to shrink				;
;	DX = size to shrink to						;
;									;
;  On Exit:								;
;	AL = error code.  0 = successful				;
;			  2 = bad block address				;
;	DX = size block set to						;
;									;
;	The heap is the only global data affected			;
;	No global procedures called					;
;									;
;	AX and DX are set according to exit parms, all others preserved.;
;-----------------------------------------------------------------------;
Shrink	proc	near
	push	es
	push	ds
	push	ax
	cmp	byte ptr es:[0],'H' ; Is this a valid block?
	je	$+5		    ; Yes, continue
	jmp	BadAdr2		; No, bad block address
	cmp	dx,es:[2]	; Is size smaller?
	jb	doshrk		; Yes, perform the shrink
	mov	dx,es:[2]	; Don't shrink, just give them smaller size
	jmp	endshrk		; End it
doshrk:
	mov	ax,es:[2]	; Get current size
	mov	es:[2],dx	; Set new size
	sub	ax,dx		; Calc amount left over
	push	ax		; Save size for new block
	mov	ax,es		; Seg of current block
	add	ax,dx		; Calc seg of new block

if	CODE286
	test	[scbmmfea],08h	;031188  286 driver?
	jz	shrno286	;031188  no, skip
	push	ax		;031188
	push	bx		;031188
	push	cx		;031188
	mov	bx,ax		;031188
	mov	ah,0ah		;031188
	xor	cl,cl		;031188
	call	[scbmmsub]	;031188
	pop	cx		;031188
	pop	bx		;031188
	pop	ax		;031188
shrno286:			;031188
endif

	mov	ds,ax		; Address it
	assume	ds:nothing

	; Set up new block prefix for newly created free block

	mov	byte ptr ds:[0],'H' ; Indicate allocated from heap
	mov	byte ptr ds:[1],'Z' ; Indicate as free block
	pop	ax		    ; Restore size
	mov	ds:[2],ax	; Set 'length' field
	mov	ax,es		; Get address of previous block
	mov	ds:[6],ax	; Set 'previous block' field
	xor	ax,ax		;
	mov	ds:[8],ax	; Zero out 'type' addresses
	mov	ds:[0aH],ax	;
	mov	ds:[0cH],ax	; Zero out 'TCB' field
	mov	ds:[0eH],ax	; Zero out 'Reserved' field
	mov	dx,ds		; Get address of new block
	mov	ax,es:[4]	; Get address of next block
	mov	ds:[4],ax	; Set next block for new block
	mov	es:[4],dx	; Set new next block pointer for shrunk block
	mov	dx,es:[2]	; Get shrunk size
	or	ax,ax		; Is new one the last block?
	jz	endshrk		; Yes, thats all there is to do, so exit
	mov	es,ax		; Point to next block (adjacent to shrinking)
	mov	ax,ds		; Get pointer to newly created block
	mov	es:[6],ax	    ; Set previous block pointer to new one
	cmp	byte ptr es:[1],'Z' ; Is the next block free also?
	jne	endshrk		    ; No, skip combining
	call	combine		; Combine newly freed area with next block
	mov	ax,es		; Point to block to be filled
	mov	dx,ax		;
	inc	ax
	add	dx,es:[2]	; Fill to end of block
endshrk:
	pop	ax		; Original AX back
	xor	al,al		; Shrink complete
	pop	ds
	assume	ds:grp
	pop	es
	mov	dx,es:[2]	; Get shrunk size
	ret			; End Shrink
BadAdr2:
	pop	ax		; Original AX back
	mov	al,2		; Bad block address error code
	pop	ds
	pop	es
	ret			; End Shrink
Shrink	endp

	subttl	Combine - Combine 2 free blocks into 1

	page
;-----------------------------------------------------------------------;
;	This routine will combine two adjacent free blocks into one	;
;	large free block.						;
;									;
;  On Entry:								;
;	ES = seg address of one of the adjacent free blocks		;
;	DS = seg address of the other adjacent free block		;
;									;
;  On Exit:								;
;	DS = ES = address of combined free block (the lower of the 2)	;
;									;
;	Global data affected						;
;	No global procedures called					;
;									;
;	The ES and DS are the only registers modified.			;
;-----------------------------------------------------------------------;
Combine	proc	near
	push	ax
	push	bx
	mov	ax,es		; Get one block address
	mov	bx,ds		; Get other block address
	cmp	ax,bx		; Which one is 1st in memory?
	jb	ESfirst		; ES is 1st in memory
	mov	es,bx		; Swap pointers
	mov	ds,ax		;
ESfirst:
	mov	ax,es:[2]	; Get 'length' of first
	add	ax,ds:[2]	; Add 'length' of second
	mov	es:[2],ax	; Set new 'length' in first
	mov	ax,ds:[4]	; Get 'next block' from second
	mov	es:[4],ax	; Set as new 'next block' address in first

if	CODE286
	push	bx		;031188  Undeclare the second block if 286
	mov	bx,ds		;031188
	MGetSCB	ds		;031188
	assume	ds:grp		;031188
	test	[scbmmfea],08h	;031188  286 driver?
	jz	comno286	;031188  no, skip
	push	ax		;031188
	push	cx		;031188
	mov	ah,0ah		;031188
	mov	cl,-1		;031188
	call	[scbmmsub]	;031188
	pop	cx		;031188
	pop	ax		;031188
comno286:			;031188
	pop	bx		;031188
	assume	ds:nothing	;031188
endif

	or	ax,ax		; Is the second the last block?
	jz	ComLast		; Yes
	mov	ds,ax		; Point to that next block
	mov	ax,es		; Get seg address for first block
	mov	ds:[6],ax	; Set the 'previous block' past second
ComLast:
	mov	ax,es
	mov	ds,ax		; Set up return seg addresses
	pop	bx
	pop	ax
	ret
Combine	endp

	subttl	ChkHeap - Check validity of heap structure

	page
;-----------------------------------------------------------------------;
;	This routine will check the links, pointers and ID bytes of the	;
;	blocks on the heap to see if they have been overwritten.  This	;
;	is provided to assist in debugging (your welcome).  If the	;
;	heap has been found to be invalid then the message 'Heap	;
;	Corrupted!' is displayed and then a 'soft lock' will be 	;
;	instigated.							;
;									;
;  On Entry:								;
;	No registers or parms						;
;									;
;  On Exit:								;
;	No registers or parms						;
;									;
;	No global data affected						;
;	No global procedures called					;
;	All registers are preserved.					;
;-----------------------------------------------------------------------;

ChkHeap	proc	near
	assume	ds:grp, es:nothing

	push	ax
	push	bx
	push	es
	mov	bx,[SCBHPADR]	; Starting pointer
	call	CheckSmp
	mov	bx,[SCBHP2ADR]
	or	bx,bx
	jz	SkipCSmp
	call	CheckSmp
SkipCSmp:
	pop	es
	pop	bx
	pop	ax
	ret

;
;	common routine inside ChkHeap to verify that heap is
;	valid.
;

CheckSmp:
	xor	ax,ax		; Holds address of previous block
CHloop:
	mov	es,bx		    ; Point to next block
	cmp	byte ptr es:[0],'H' ; Is this a heap block?
	jne	endch		    ; No, error in heap!
	cmp	ax,es:[6]	; Check 'previous block' address
	jne	endch		; Error in heap!
	mov	ax,es		;
	mov	bx,es:[4]	; Get seg of next block
	or	bx,bx		; Last block?
	jnz	CHloop		; No, not yet - keep on truckn'

	cmp	byte ptr es:[0],'H' ; Check the last block also
	jne	endch		    ; Error in heap!
	ret

endch:
	call	bugerror	;
	db	'02 '		; Heap corrupted error
	db	13,10,'System Memory Pool (SMP) Corrupted!          ',0 ;@@XLAT

ChkHeap	endp

;-----------------------------------------------------------------------;
mosheman endp

mosseg	ends
	end

