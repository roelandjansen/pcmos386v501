	include PAGE.INC
	title	MOSLIMAN - MOS List Management

;-----------------------------------------------------------------------;
;									;
;		Development Specification				;
;									;
;									;
; Program Name: $$MOS.COM		Assigned to: David Morrow	;
; Module Name:	MOSLIMAN		Assign date: 02/17/86		;
; 					Completed:   02/25/86		;
; Entry Points: MOSLIMAN						;
; Entry From:	MOSxxxxx						;
; Entry Method:	CALL							;
; Calls:	MOSHEMAN						;
; Purpose:	List management						;
; Refer to:	n/a							;
; Last Update:	08/01/86						;
;									;
;	This routine provides for adding and removing memory blocks	;
;	of various types to and from the appropriate heap-resident	;
;	list(s).  Different treatments are performed, depending on the	;
;	type of block.							;
;									;
;	Registers passed are:						;
;		AH - 0=add, 1=remove					;
;		AL - Block type code:					;
;			'T' = TCB					;
;			'F' = TFB					;
;			'G' = GFB					;
;			'C' = CDB					;
;			'B' = BDB					;
;			'R' = RLB					;
;		SS - Owner TCB address (if adding a TFB, CDB, or RLB)	;
;		ES - Owner GFB address (if adding a TFB or RLB); or	;
;		     address of block (if remove)			;
;									;
;	Registers returned are:						;
;		AL - 	0- successful					;
;			1- heap error, AH = MOSHEMAN error code		;
;			2- bad block (add); type mismatch (del)		;
;			3- active TFB pointers (for TCB & GFB deletes)	;
;			4- active RLB pointers (for GFB deletes)	;
;			5- active CDB pointers (for TCB deletes)	;
;			6- bad TCB owner address (for add TFB, CDB,	;
;							or RLB)		;
;			7- bad GFB owner address (for add TFB or RLB)	;
;									;
;		ES - Address of block (if add)				;
;									;
;	The list management routines are grouped into one code module	;
;	because it is expected that some local subroutines can be	;
;	shared, and for consolidation.					;
;									;
;	Other than clearing a new block's data areas to binary zeros,	;
;	no initialization logic is performed beyond memory and pointer	;
;	management (this could possibly change, given a good reason).	;
;									;
;-----------------------------------------------------------------------;
; jrb 07/24/87 - insert/delete tcb from priority list as well as	;
;                tcb list						;
;-----------------------------------------------------------------------;
; jsm 11/18/87 - Maintain bdbdpbpn fields in bdbrtn for both insert	;
;                and delete functions					;
;-----------------------------------------------------------------------;
; SAH 01/20/88 	Change SCBSEG and ZERO seg to MGetXXXX macros		;
;-----------------------------------------------------------------------;
; SAH 02/16/88  Declare\Undeclare TCB's					;
;-----------------------------------------------------------------------;
; sah/rbr 02/20/88 Move DDT Segment to MO2 Group			;
;-----------------------------------------------------------------------;
; rbr 02/29/88  Move noTSL to grp.					;
;-----------------------------------------------------------------------;
; rbr 03/07/88  Fix "declare" bug; can now declare TFB's.		;
;-----------------------------------------------------------------------;
; rbr 03/11/88  Moved declares/undeclares to mosheman.   		;
;-----------------------------------------------------------------------;
; SAH 09/04/88  Added routines to add and delete SFT simulations for    ;
;		MS-Windows.						;
;-----------------------------------------------------------------------;
; SAH 05/11/89	Corrections so that SFT logic for windows, doesn't      ;
;		corrupt INT 4 vector.  Oversite on my part when I solved;
;		windows.						;
;-----------------------------------------------------------------------;
; SAH 06/29/89	Change NoTSL to SCBNOTSL.				;
;-----------------------------------------------------------------------;


	include GROUP.INC
	.xlist
	subttl	group segments and include block definitions
	page

	include MOSREGS.INC

tcb	segment at 1234h
	include	MOSTCB.INC	; TCB definition
tcb	ends

	include	MOSCDB.INC	; etc., etc., etc.
	include	MOSGFB.INC
	include	MOSTFB.INC
	include	MOSRLB.INC
	include	MOSBDB.INC

gdata	segment	word public 'data'
	include	MOSSCBEX.INC	; specify all SCB items as external
gdata	ends
	.list

irq	segment	byte public 'data'
irq	ends

poll	segment	byte public 'data'
poll	ends

ddt     segment word public 'code2'
ddt     ends

	page
mosseg	segment	word public 'code1'
	assume	cs:mos,ds:nothing,es:nothing,ss:nothing
	public	$$$liman
$$$liman label	byte
	extrn	mosend:byte, sbios:word
	public	mosstdin,mosstdout,mosstdnul,mosstdprn,mosstdaux

mosstdin:		;### Temporary home for these routines
mosstdout:		;### Temporary home for these routines
mosstdnul:		;### Temporary home for these routines
mosstdprn:		;### Temporary home for these routines
mosstdaux proc far	;### Temporary home for these routines

	ret

mosstdaux endp		;### Temporary home for these routines

; Return codes

rcsuc	equ	0	; successful
rchperr	equ	1	; heap error
rcmtch	equ	2	; block type codes do not match error
rcTFB	equ	3	; active TFB pointers error
rcRLB	equ	4	; active RLB pointers error
rcCDB	equ	5	; active CDB pointers error
rcTCB	equ	6	; bad TCB owner address
rcGFB	equ	7	; bad GFB owner address

	; extrn's rite cheer

	extrn	mosheman:near, noswitch:near, okswitch:near

	; public's rite cheer

	public	mosliman

;	include	mosliman.pub		; For periscope labels

	subttl	MOSLIMAN - MOS List Management
	page
;-----------------------------------------------------------------------;
;	This is the entry point to MOSLIMAN, it will determine the type	;
;	of block to be operated on and invoke the appropriate routine.	;
;-----------------------------------------------------------------------;
LIfunct	db	'T','F','G','C','B','R'		; Routine codes
funlen	equ	$-LIfunct			; # of them

LIdispt	dw	mos:RtnTCB, mos:RtnTFB, mos:RtnGFB
	dw	mos:RtnCDB, mos:RtnBDB, mos:RtnRLB

mosliman proc	near

	push	bx
	push	cx
	push	dx
	push	si
	push	di
	push	ds
	push	es
	MGetSCB ds
	assume	ds:grp
	mov	cx,funlen
	mov	di,cs		; for accessing constant LIfunct
	mov	es,di
	lea	di,LIfunct
	cld
	repne	scasb		; Determine type of block
	pop	es
	jne	errblock	; Invalid block type
	mov	di,funlen	; Calc dispatcher offset
	sub	di,cx		;
	dec	di		; Zero relative table
	shl	di,1		; Word offset into table
	call	noswitch	; Set no switch flag
	call	[di+LIdispt]	; Execute appropriate routine
	call	okswitch	;
liexit:
	pop	ds
	pop	di
	pop	si
	pop	dx
	pop	cx
	pop	bx
	ret			; End MOSLIMAN
errblock:
	mov	al,rcmtch	; 'Bad block type' error code
	jmp	liexit

mosliman endp

	subttl	RtnTCB - Add or Delete a TCB
	page
;-----------------------------------------------------------------------;
;	This routine will delete or add a TCB to the list of current	;
;	TCBs.								;
;									;
;	For ADD the TCB will be allocated from the heap, its data area	;
;	cleared to 0s, and the SCB pointers to 1st and last TCB		;
;	(SCBTCBPF, SCBTCBPL) will be updated accordingly.  The new TCB	;
;	will be put on the end of the current TCB list.			;
;									;
;	For DELETE the TCB will be checked for any pointers to active	;
;	TFBs or CDBs and if found will not delete the block but return	;
;	with an error code (the routine deleteing the TCB must delete	;
;	all linked information first).  If no active pointers are	;
;	found then the TCB will be deallocated from the heap and the	;
;	SCB pointers for 1st and last TCB will be updated.		;
;									;
;  On Entry:								;
;	AH = function code: 0- add, 1- delete				;
;	AL = block ID type						;
;	ES = TCB addresss (if del)					;
;									;
;  On Exit:								;
;	AL = error code, AH = error code for MOSHEMAN (if error)	;
;	ES = address of TCB, undefined on exit for delete		;
;									;
;	SCBTCBPF, SCBTCBPL and the heap are the only global data	;
;	affected							;
;	MOSHEMAN is the only global procedure called			;
;									;
;	AX returns info, BX, CX, DX, SI, DI destroyed			;
;-----------------------------------------------------------------------;
	assume	ds:grp,es:nothing,ss:nothing
RtnTCB	proc	near

	push	ax
	or	ah,ah		; Is this an add block?
	jz	$+5		; Yes
	jmp	RtnTCBd		; No, they want delete

	; Add a TCB to the TCB list

	mov	dx,tcblen	; Get length of block in bytes
	call	blkallo		 ; Do heap allocation (ES=address of block)
	assume	es:tcb
	mov	[tcbtype],'T'	; Set block type field
	lea	si,tcbstack	; The SP save word must be set to something
	mov	[tcbsp],si	;  valid in case of IRQs during TSL
	mov	si,[scbtcbpf]	; Get SCB pointer to 1st TCB
	mov	di,[scbtcbpl]	; Get SCB pointer to last TCB
	mov	bx,di		; Put new TCB at end of list
	call	BlkIns		; Insert block into list
	mov	[scbtcbpf],si	; Set SCB pointer to 1st TCB
	mov	[scbtcbpl],di	; Set SCB pointer to last TCB

	mov	ah,[SCBNOTSL]	;jrb
	mov	[SCBNOTSL],'Y'	;jrb
	push	ax		;jrb
	mov     ax,[scbpripf]   ;jrb
	push    ds              ;jrb
RTCB1:                          ;jrb
	mov     ds,ax           ;jrb
	assume  ds:tcb,es:nothing
        mov     ax,[tcbpripn]   ;jrb
        or      ax,ax           ;jrb
        jnz     RTCB1           ;jrb
        mov     [tcbpripn],es   ;jrb
        assume  ds:grp,es:tcb   ;jrb
        pop     ds              ;jrb

	; Clear data area of TCB to 0's

	mov	cx,tcblen	; Get total length of block
	call	clrdata		; Clear data area to 0s
	pop	ax
	mov	[SCBNOTSL],ah
	pop	ax
	mov	al,rcsuc	; Successful return code
	ret			; End of RtnTCB

	page
	; Delete a TCB from the TCB list

	assume	es:tcb
RtnTCBd:
	cmp	al,[tcbtype]	; Correct block type?
	je	TCBcont		; Yes, continue
	pop	ax
	mov	al,rcmtch	; Block type mismatch error
	ret
TCBcont:
	cmp	[tcbtfbpf],0	; Any active TFBs?
	jne	etcbtfb		; Yes, cannot delete block
	cmp	[tcbcdbpf],0	; Any active CDBs?
	jne	etcbcdb		; Yes, cannot delete block
	jmp	delTCBok	; OK to delete
etcbtfb:
	pop	ax		; Restore original AX
	mov	al,rcTFB	; Active TFBs error code
	ret
etcbcdb:
	pop	ax		; Restore original AX
	mov	al,rcCDB	; Active CDBs error code
	ret
delTCBok:
	mov	ah,'Y'		;jrb
	xchg	ah,[SCBNOTSL]	;jrb
	push	ax		;jrb
	mov	di,es		;jrb remember location of one being deleted
	mov	ax,[scbpripf]	;jrb
	cmp	ax,di		;jrb
	jne	delTpri1	;jrb e if it were first in priority list
	mov	ax,[tcbpripn]	;jrb delete from first position in priority list
	mov	[scbpripf],ax	;jrb
	jmp	delTpri3	;jrb
delTpri1:			;jrb
	mov	es,ax	        ;jrb
	mov	ax,[tcbpripn]	;jrb
	or	ax,ax		;jrb
	jz	delTpri3	;jrb z if not in list (so don't delete it)
	cmp	ax,di		;jrb
	jne	delTpri1	;jrb
delTpri2:			;jrb
; es = tcb prior to one to delete
	push	ds		;jrb
	mov	ds,di		;jrb ds -> tcb to be deleted
	assume	ds:tcb,es:nothing
	mov	ax,[tcbpripn]	;jrb delete it from the priority list
	assume	ds:grp,es:tcb	;jrb
	mov	[tcbpripn],ax	;jrb
	pop	ds	        ;jrb
delTpri3:			;jrb
	mov	es,di		;jrb
	pop	ax		;jrb
	mov	[SCBNOTSL],ah	;jrb

	mov	si,[scbtcbpf]	;
	mov	di,[scbtcbpl]	;
	call	BlkDel		; Remove block from list of TCBs

	mov	[scbtcbpf],si	; Set SCB pointer to 1st TCB
	mov	[scbtcbpl],di	; Set SCB pointer to last TCB

	mov	ah,1		; Deallocate block call
	call	mosheman	;
	or	al,al		; Any errors
	jz	$+5		; No
	jmp	errheap		; Yes, error with the heap
	pop	ax
	mov	al,rcsuc	; Successful return code
	ret			; End RtnTCB

RtnTCB	endp

	subttl	RtnTFB - Add or Delete a TFB
	page
;-----------------------------------------------------------------------;
;	This routine will delete or add a TFB to the list of current	;
;	TFBs.								;
;									;
;	For ADD the TFB will be allocated from the heap, its data area	;
;	cleared to 0s, the owner TCB and GFB fields will be set, and	;
;	the links into both the TCB and GFB will be updated accordingly	;
;									;
;	For DELETE the links from the TFB back into the TCB and GFB 	;
;	will be updated and the TFB will be deallocated from the heap.	;
;									;
;  On Entry:								;
;	AH = function code: 0- add, 1- delete				;
;	AL = block ID type						;
;	SS = owner TCB address (if add)					;
;	ES = owner GFB address (if add) or TFB addresss (if del)	;
;									;
;  On Exit:								;
;	AL = error code, AH = error code for MOSHEMAN (if error)	;
;	ES = address of TFB (if add) or undefined on exit for delete	;
;									;
;	MOSHEMAN is the only global procedure called			;
;									;
;	AX returns info, BX, CX, DX, SI, DI destroyed			;
;-----------------------------------------------------------------------;
RtnTFB	proc	near

	assume	ds:grp,ss:tcb,es:gfb
	push	ax		; Save block ID
	or	ah,ah		; Is this an add block?
	jz	$+5		; Yes
	jmp	RtnTFBd		; No, they want delete

	; Check for valid owner TCB and GFB

	cmp	word ptr es:[0],'GH'	; Check for valid prefix (heap & GFB)
	je	TFBck1			; Ok, check TCB
	pop	ax
	mov	al,rcGFB	; Invalid GFB address
	ret
TFBck1:
	cmp	word ptr ss:[0],'TH'	; Check for valid prefix (heap & TCB)
	je	TFBck2			; Ok, continue
	pop	ax
	mov	al,rcTCB	; Invalid TCB address
	ret
TFBck2:
	; Add a TFB to the TFB list, process TCB chain

	mov	dx,tfblen	; Get length of block in bytes
	mov	bx,es		; Save GFB pointer
	call	blkallo		; Do heap allocation
	assume	es:tfb
	mov	[tfbtype],'F'	; Set block type field
	mov	[tfbtcb],ss	; Set Owner TCB field

	; Clear data area

	mov	cx,tfblen	; Get total length of TFB
	call	clrdata		; Clear data area to 0s

	mov	[tfbgfb],bx	; Set Owner GFB field
	mov	si,[tcbtfbpf]	; Get pointer to 1st TFB for this TCB

	; Trace through TFBs to find last one in TCB chain

	xor	di,di		; Assume no active TFBs (setup for BlkIns)
	or	si,si		; Are there any active TFBs for this TCB?
	jz	nocurtfb	; No currnet TFBs
	mov	di,si		; There is a minimum of one
	push	es		; Save allocated TFB pointer
fltfb:
	mov	es,di		; Point to next TFB in TCB chain
	assume	es:tfb
	mov	di,[tfbntcb]	; Pointer to next TFB for this TCB
	or	di,di		; Last one?
	jnz	fltfb		; No, find last TFB
	mov	di,es		; Set last TFB pointer
	pop	es		; Restore allocted TFB pointer
	assume	es:tfb
nocurtfb:
	mov	bx,di		; Tell where to put in list
	call	BlkIns		; Insert block into list of TFBs
	mov	[tcbtfbpf],si	; Set new 1st TFB pointer in TCB

	page
	; Add a TFB to the TFB list, process GFB chain

	push	es		; Save TFB pointer
	mov	es,[tfbgfb]	; Get Owner GFB from TFB (set above)
	assume	es:gfb
	mov	si,[gfbtfb]	; Get pointer to 1st TFB for this GFB
	mov	bx,es		; Temp save pointer to GFB
	pop	es		; Block TFB back
	assume	es:tfb

	; Trace through TFBs to find last one in GFB chain
	; Note: since these pointers are not in the prefix we cannot
	; 	use BlkIns & BlkDel, they must be set manually here.

	or	si,si		; Are there any active TFBs for this GFB?
	jnz	curtfb2		; Yes, add to list of current TFBs
	mov	si,es		; Save new TFB pointer
	mov	es,bx		; No, set this TFB as 1st; point to owner GFB
	assume	es:gfb
	mov	[gfbtfb],si	; Set new 1st TFB pointer in GFB
	mov	es,si		; Return new TFB pointer to caller
	assume	es:tfb
	jmp	oktfbend	; Clear data area and exit
curtfb2:
	push	ds		; Save SCB pointer
fltfb2:
	mov	ds,si		; Point to next TFB
	assume	ds:tfb
	mov	si,ds:[tfbngfb]	; Pointer to next TFB for this GFB
	or	si,si		; Last one?
	jnz	fltfb2		; No, find last TFB
	mov	ds:[tfbngfb],es	; Set new 'next pointer' in old last TFB
	mov	es:[tfbpgfb],ds	; Set 'previous pointer' in new TFB
	mov	es:[tfbngfb],0	; Set new TFB as last in list
	pop	ds		; Restore SCB pointer
	assume	ds:grp
oktfbend:
	pop	ax		; Original AX back
	mov	al,rcsuc	; Successful return code
	ret			; End of RtnTFB

	page
	; Delete a TFB from the TFB list, process TCB chain

RtnTFBd:
	cmp	al,es:[1]	; Correct block type?
	je	TFBcont		; Yes, continue
	pop	ax
	mov	al,rcmtch	; Block type mismatch error
	ret
TFBcont:
	push	es		; Save block pointer (block to delete)
	mov	es,[tfbtcb]	; Get pointer to TCB
	assume	es:tcb
	mov	si,es:[tcbtfbpf] ; Get pointer to 1st TFB
	mov	di,si		 ; Assume only TFB (setup for BlkIns)
fltfb3:
	mov	es,di		; Point to next TFB
	assume	es:tfb
	mov	di,[tfbntcb]	; Pointer to next TFB for TCB
	or	di,di		; Last one?
	jnz	fltfb3		; No, find last TFB

	mov	di,es		; Set last TFB pointer
	pop	es		; TFB pointer to delete
	assume	es:tfb
	call	BlkDel		; Remove block from list of TFBs for TCB
	push	es		;
	mov	es,[tfbtcb]	; Get pointer to TCB
	assume	es:tcb
	mov	es:[tcbtfbpf],si ; Update pointer to 1st TFB in TCB
	pop	es		 ; Get pointer to TFB to delete
	assume	es:tfb

	; Now clear GFB chain (the tuff part!)

	push	es		; Save TFB pointer
	mov	bx,[tfbpgfb]	; Get pointer to previous TFB in GFB chain
	or	bx,bx		; Is this TFB the 1st in the list?
	jz	dotfb1st	; Yes, do it 1st
	cmp	[tfbngfb],0	; Is this the last TFB for this GFB
	je	tfblast		; Yes

	push	ds
	mov	bx,[tfbngfb]	; Get pointer to next TFB
	mov	ax,[tfbpgfb]	; Get pointer to next TFB
	mov	es,bx		; Point to next block
	mov	ds,ax		; Point to previous block
	assume	ds:tfb
	mov	ds:[tfbngfb],bx	; Set new 'Next' pointer in previous TFB
	mov	es:[tfbpgfb],ax	; Set new 'Previous' pointer in next block
	pop	ds
	assume	ds:grp
	jmp	tfbdend
dotfb1st:
	mov	ax,[tfbngfb]	; Is this the only TFB for this GFB?
	or	ax,ax		;
	je	tfbonly		; Yes
	mov	es,ax		; Point to next TFB
	mov	[tfbpgfb],0	; Set 'Previous type' field to none
	mov	es,[tfbgfb]	; Get pointer to GFB
	assume	es:gfb
	mov	[gfbtfb],ax	; Set new 1st TFB pointer in GFB
	jmp	tfbdend		; End delete
tfbonly:
	assume	es:tfb
	mov	es,[tfbgfb]	; Get pointer to GFB
	assume	es:gfb
	mov	[gfbtfb],0	; Set 1st TFB pointer to none
	jmp	tfbdend		; End of delete
tfblast:
	mov	es,bx		; Point to previous TFB
	assume	es:tfb
	mov	[tfbngfb],0	; Set next to none
tfbdend:
	pop	es		; Restore TFB address to delete
	mov	[tfbtcb],0	; Clear Owner TCB field
	mov	ah,1		; Deallocate block call
	call	mosheman	;
	or	al,al		; Any errors
	jz	$+5		; No
	jmp	errheap		; Yes, error with the heap
	pop	ax
	mov	al,rcsuc	; Successful return code
	ret			; End RtnTFB

RtnTFB	endp

	subttl	RtnGFB - Add or Delete a GFB
	page
;-----------------------------------------------------------------------;
;	This routine will delete or add a GFB to the list of current	;
;	GFBs.								;
;									;
;	For ADD the GFB will be allocated from the heap, its data area	;
;	cleared to 0s, and the SCB pointers to 1st and last GFB		;
;	(SCBGFBPF, SCBGFBPL) will be updated accordingly.		;
;									;
;	For DELETE the GFB will be check for any pointers to active	;
;	TFBs or RLBs and if found will not delete the block but return	;
;	with an error code (the routine deleteing the GFB must delete	;
;	all linked information first).  If no active pointers are	;
;	found then the GFB will be deallocated from the heap and the	;
;	SCB pointers for 1st and last GFB will be updated.		;
;									;
;  On Entry:								;
;	AH = function code: 0- add, 1- delete				;
;	AL = block ID type						;
;	ES = GFB addresss (if del)					;
;									;
;  On Exit:								;
;	AL = error code, AH = error code for MOSHEMAN (if error)	;
;	ES = GFB address (if add); or undefined on exit for delete	;
;									;
;	SCBGFBPF, SCBGFBPL and the heap are the only global data	;
;	affected							;
;	MOSHEMAN is the only global procedure called			;
;									;
;	AX returns info, BX, CX, DX, SI, DI destroyed			;
;									;
; Update 09/04/88 SAH to handle simulations of DOS SFT's via function   ;
; 52h.  MS-Windows uses this structure for handling of Files.		;
;-----------------------------------------------------------------------;
RtnGFB	proc	near

	push	ax
	or	ah,ah		; Is this an add block?
	jz	$+5		; Yes
	jmp	RtnGFBd		; No, they want delete

	; Add a GFB to the GFB list

	mov	dx,gfblen	; Get length of block in bytes
	call	blkallo		; Do heap allocation
	assume	es:gfb
	mov	[gfbtype],'G'	; Set block type field
	mov	si,[scbgfbpf]	; Get SCB pointer to 1st GFB
	mov	di,[scbgfbpl]	; Get SCB pointer to last GFB
	mov	bx,di		; Put new GFB at end of list
	call	BlkIns		; Insert block into list
	mov	[scbgfbpf],si	; Set SCB pointer to 1st GFB
	mov	[scbgfbpl],di	; Set SCB pointer to last GFB

	; Clear data area of GFB to 0's

	mov	cx,gfblen	; Get total length of block
	call	clrdata		; Clear data area to 0s
	call	SetSFT		; Set SFT (uses bx set before BlkIns)
	pop	ax
	mov	al,rcsuc	; Successful return code
	ret			; End of RtnGFB

	page
	; Delete a GFB from the GFB list

RtnGFBd:
	cmp	al,es:[1]	; Correct block type?
	je	GFBcont		; Yes, continue
	pop	ax
	mov	al,rcmtch	; Block type mismatch error
	ret
GFBcont:
	cmp	[gfbtfb],0	; Any active TFBs?
	jne	egfbtfb		; Yes, cannot delete block
	cmp	[gfbrlb],0	; Any active RLBs?
	jne	egfbrlb		; Yes, cannot delete block
	jmp	delGFBok	; OK to delete
egfbtfb:
	pop	ax		; Restore original AX
	mov	al,rcTFB	; Active TFBs error code
	ret
egfbrlb:
	pop	ax		; Restore original AX
	mov	al,rcRLB	; Active RLBs error code
	ret
delGFBok:
	mov	si,[scbgfbpf]	;
	mov	di,[scbgfbpl]	;
	call	BlkDel		; Remove block from list of GFBs
	mov	[scbgfbpf],si	; Set SCB pointer to 1st GFB
	mov	[scbgfbpl],di	; Set SCB pointer to last GFB
	call	ClrSFT		; Clear the SFT entry

	mov	ah,1		; Deallocate block call
	call	mosheman	;
	or	al,al		; Any errors
	jz	$+5		; No
	jmp	errheap		; Yes, error with the heap
	pop	ax
	mov	al,rcsuc	; Successful return code
	ret			; End RtnGFB

;
; The following routine sets the SFT link in GFB so that applications
; that use function 52h can trace down SFTs (inside our GFBs) to get
; file information.		BX --> gfb at end of list

	public	SetSFT
SetSFT:
	push	ax
	mov	ax,[scbgfbpf]
	cmp	ax,[scbgfbpl]
	pop	ax
	je	SS1		; first link?

;
; In this case we added the entry to end of chain and there for we most
; set prevous entry to us and ourselves to terminates (as in first entry)
;

	push	ax
	push	es
	mov	ax,es			; save segment of gfb to add
	mov	es,bx			; get prevous GFB 
	mov	word ptr [gfbnsft], offset gfbnsft
	mov	word ptr [gfbnsft+2],ax	; set segment to new gfb	
	pop	es
	pop	ax

;	
; This is first GFB so we must set SFT Next entry to terminator
;
ss1:
	push	ds
	mov	ds,[scbtcbpc]
	assume  ds:tcb
	mov	word ptr [gfbnsft], offset tcbsft
	mov	word ptr [gfbnsft+2],ds
	pop	ds
	assume  ds:grp
	ret

;
; This routine removes a sft entry from list
;
ClrSFT:
	push	ax
	mov	ax,es
	cmp	ax,[scbgfbpf]
	pop	ax
	je	cs1		; is it first entry on list?
;
; must set prevous SFT entry to SFT entry pointed by one to delete
;
	push	ax
	push	bx
	push	es
	mov	ax,word ptr [gfbnsft]
	mov	bx,word ptr [gfbnsft+2]
	cmp	word ptr [gfbprev],0	    ; end of list
	je	CSSkip			    ; then don't update sft pointers
	mov	es,[gfbprev]
	mov	word ptr [gfbnsft],ax
	mov	word ptr [gfbnsft+2],bx
CSSkip:
	pop	es
	pop	bx
	pop	ax
	ret
cs1:
;
; this is hard part because we nolonger have route GFB (SFT) on system
; and must change all tcbsft pointers to next SFT on list
; This should not be a problem becuase AUX appears to be always the
; first device.  FUTURE: scan TCB and change TCBNSFT to new SFT entry
;
	ret


RtnGFB	endp

	subttl	RtnCDB - Add or Delete a CDB
	page
;-----------------------------------------------------------------------;
;	This routine will add or delete a 'Current Directory Block'	;
;	(CDB) to a list of CDBs for a specified TCB.			;
;									;
;	For ADDs the space for the block will be allocated from the	;
;	heap, the block will be added to the list of CDBs for the	;
;	specified TCB if one exists, else one will be started and the	;
;	The CDB block is appended to the end of the CDB list.		;
;									;
;	For DELETEs the space for the block will be deallocated from	;
;	the heap, the block will be deleted from the list of CDBs for	;
;	the specified TCB.						;
;									;
;  On Entry:								;
;	AH = function code: 0- add, 1- delete				;
;	AL = block ID type						;
;	SS = owner TCB address (if add)					;
;	ES = CDB addresss (if del)					;
;									;
;  On Exit:								;
;	AL = error code, AH = error code for MOSHEMAN (if error)	;
;	ES = address of CDB (if add); or undefined on exit for delete	;
;									;
;	The heap, the CDB list are the global data affected		;
;	MOSHEMAN is the only global procedure called			;
;									;
;	AX returns info, BX, DX, SI, DI, and DS destroyed		;
;-----------------------------------------------------------------------;
RtnCDB	proc	near

	assume	ss:tcb
	push	ax
	or	ah,ah		; Is this an add block?
	jz	$+5		; Yes
	jmp	RtnCDBd		; No, they want delete

	; Check for valid TCB owner address

	cmp	word ptr ss:[0],'TH'	; Check for valid prefix (heap & TCB)
	je	CDBck2			; Ok, continue
	pop	ax
	mov	al,rcTCB	; Invalid TCB address
	ret
CDBck2:
	; Add a CDB to the CDB list

	mov	dx,cdblen	; Get length of block in bytes
	call	blkallo		; Do heap allocation
	assume	es:cdb
	mov	[cdbtype],'C'	; Set block type field
	mov	[cdbtcb],ss	; Set Owner TCB field
	mov	si,[tcbcdbpf]	; Get TCBs pointer to 1st CDB

	; Trace through CDBs to find last one

	xor	di,di		; Assume no active CDBs (setup for BlkIns)
	or	si,si		; Are there any active CDBs for this TCB?
	jz	nocurcdb	; No currnet CDBs
	mov	di,si		; There is a minimum of one
	push	es		; Save
flcdb:
	mov	es,di		; Point to next CDB
	assume	es:cdb
	mov	di,[cdbnext]	; Pointer to next CDB for TCB
	or	di,di		; Last one?
	jnz	flcdb		; No, find last rlb
	mov	di,es		; Set last CDB pointer
	pop	es		;
nocurcdb:
	mov	bx,di		; Put new CDB at end of list
	call	BlkIns		; Insert block into list of CDBs
	mov	[tcbcdbpf],si	; Set new 1st RLB pointer in GFB
	pop	ax
	mov	al,rcsuc	; Successful return code

	mov	cx,cdblen	; Clear block
	call	clrdata		; Clear data area to 0s

	ret			; End of RtnCDB

	page
	; Delete a CDB from the CDB list

RtnCDBd:
	cmp	al,es:[1]	; Correct block type?
	je	CDBcont		; Yes, continue
	pop	ax
	mov	al,rcmtch	; Block type mismatch error
	ret
CDBcont:
	push	es		; Save block pointer (block to delete)
	assume	es:cdb
	mov	es,[cdbtcb]	; Get pointer to TCB
	assume	es:tcb,ss:nothing
	mov	si,[tcbcdbpf]	; Get pointer to 1st CDB
	mov	di,si		; Assume only CDB (setup for BlkIns)
flcdb2:
	mov	es,di		; Point to next CDB
	assume	es:cdb
	mov	di,[cdbnext]	; Pointer to next CDB for TCB
	or	di,di		; Last one?
	jnz	flcdb2		; No, find last CDB

	mov	di,es		; Set last CDB pointer
	pop	es		; Block pointer back
	push	es		;
	call	BlkDel		; Remove block from list of CDBs
	mov	es,[cdbtcb]	; Get pointer to TCB
	assume	es:tcb,ss:nothing
	mov	[tcbcdbpf],si	; Update new pointer to 1st CDB in TCB
	pop	es		; Get pointer to block to deallocate
	assume	es:cdb
	mov	[cdbtcb],0	; Clear Owner TCB field
	mov	ah,1		; Deallocate block call
	call	mosheman	;
	or	al,al		; Any errors
	jz	$+5		; No
	jmp	errheap		; Yes, error with the heap
	pop	ax
	mov	al,rcsuc	; Successful return code
	ret			; End RtnCDB

RtnCDB	endp

	subttl	RtnBDB - Add or Delete a BDB
	page
;-----------------------------------------------------------------------;
;	This routine will add or delete a 'Block Device Block' (BDB)	;
;	The BDB will be allocated or deallocated from the heap and the	;
;	SCB pointers to 1st and last BDB (SCBBDBPF, SCBBDBPL) will be	;
;	updated accordingly.						;
;									;
;  On Entry:								;
;	AH = function code: 0- add, 1- delete				;
;	AL = block ID type						;
;	ES = BDB addresss (if del)					;
;									;
;  On Exit:								;
;	AL = error code, AH = error code for MOSHEMAN (if error)	;
;	ES = BDB address (if add); undefined on exit for delete		;
;									;
;	The heap, the BDB list, and the SCB BDB pointers are modified.	;
;	MOSHEMAN is the only global procedure called			;
;									;
;	AX returns info, BX, CX, DX, SI, DI, and DS destroyed		;
;-----------------------------------------------------------------------;
RtnBDB	proc	near

	assume	ds:grp
	push	ax
	or	ah,ah		; Is this an add block?
	jz	$+5		; Yes
	jmp	RtnBDBd		; No, they want delete

	; Add a BDB to the BDB list

	mov	dx,bdblen	; Get length of block in bytes
	call	blkallo		; Do heap allocation
	assume	es:bdb
	mov	[bdbtype],'B'	; Set block type field
	mov	si,[scbbdbpf]	; Get SCB pointer to 1st BDB
	mov	di,[scbbdbpl]	; Get SCB pointer to last BDB
	mov	bx,di		; Put new BDB at end of list
	call	BlkIns		; Insert block into list
	mov	[scbbdbpf],si	; Set SCB pointer to 1st BDB
	mov	[scbbdbpl],di	; Set SCB pointer to last BDB

	mov	cx,bdblen	; Get total length of block
	call	clrdata		; Clear data area to 0s

;JSM 11/18/87 set DPB next pointer.

	push	ds
	mov	cx,[bdbprev]
	jcxz	bdb10		; if no previous block
	mov	ds,cx

	assume	ds:bdb,es:nothing

	mov	word ptr [bdbdpbpn],offset bdbdpb
	mov	word ptr [bdbdpbpn+2],es	; set next pointer for prev

	assume	ds:nothing,es:bdb
bdb10:
	mov	cx,[bdbnext]
	jcxz	bdb20				; if no next block
	mov	word ptr [bdbdpbpn],offset bdbdpb
	mov	word ptr [bdbdpbpn+2],cx	; set next pointer for new
	jmp	short bdb30
bdb20:
	mov	ax,-1				; end of chain
	mov	word ptr [bdbdpbpn],ax
	mov	word ptr [bdbdpbpn+2],ax
bdb30:
	pop	ds
	assume	ds:grp

;JSM 11/18/87 end changes

	pop	ax
	mov	al,rcsuc	; Successful return code
	ret			; End of RtnRLB

	page
	; Delete a BDB from the BDB list

RtnBDBd:
	cmp	al,es:[1]	; Correct block type?
	je	BDBcont		; Yes, continue
	pop	ax
	mov	al,rcmtch	; Block type mismatch error
	ret
BDBcont:
	mov	si,[scbbdbpf]	; Get current SCB pointer to 1st BDB
	mov	di,[scbbdbpl]	; "	"	"	" to last BDB
	call	BlkDel		; Remove block from list of BDBs
	mov	[scbbdbpf],si	; Set SCB pointer to 1st BDB
	mov	[scbbdbpl],di	; "	"	" to last BDB

;JSM 11/18/87 set DPB next pointer of previous block.

	push	ds
	mov	cx,[bdbprev]
	jcxz	bdb50		; if no previous block
	mov	ds,cx
	mov	cx,[bdbnext]	; pointer to next block

	assume	ds:bdb,es:nothing

	jcxz	bdb40		; if no next block
	mov	word ptr [bdbdpbpn],offset bdbdpb
	mov	word ptr [bdbdpbpn+2],cx	; set next pointer for prev
	jmp	short bdb50
bdb40:
	mov	ax,-1				; end of chain
	mov	word ptr [bdbdpbpn],ax
	mov	word ptr [bdbdpbpn+2],ax
bdb50:
	pop	ds
	assume	ds:grp,es:bdb

;JSM 11/18/87 end changes

	mov	ah,1		; Deallocate block call
	call	mosheman	;
	or	al,al		; Any errors
	jz	$+5		; No
	jmp	errheap		; Yes, error with the heap
	pop	ax
	mov	al,rcsuc	; Successful return code
	ret			; End RtnBDB

RtnBDB	endp

	subttl	RtnRLB - Add or Delete a RLB
	page
;-----------------------------------------------------------------------;
;	This routine will add or delete a 'Record Lock Block' (RLB).	;
;									;
;	For ADDs the space for the block will be allocated from the	;
;	heap, the block will be added to the list of RLBs for the	;
;	specified GFB if one exists, else one will be started and the	;
;	GFB data field 'GFBRLB' will be updated.  The RLB block is	;
;	inserted at the beginning of the RLB list.			;
;									;
;	For DELETEs the space for the block will be deallocated from	;
;	the heap, the block will be deleted from the list of RLBs for	;
;	the specified GFB , and the GFB data field 'GFBRLB' will be	;
;	updated.							;
;									;
;  On Entry:								;
;	AH = function code: 0- add, 1- delete				;
;	AL = block ID type						;
;	SS = owner TCB address (if add)					;
;	ES = owner GFB address (if add), else block addresss (if del)	;
;									;
;  On Exit:								;
;	AL = error code, AH = error code for MOSHEMAN (if error)	;
;	ES = RLB address (if add); undefined on exit for delete		;
;									;
;	The heap, the RLB list, and GFBRLB are the global data affected	;
;	MOSHEMAN is the only global procedure called			;
;									;
;	AX returns info, BX, DX, SI, DI, and DS destroyed		;
;-----------------------------------------------------------------------;
RtnRLB	proc	near

	assume	ss:tcb,es:gfb
	push	ax
	or	ah,ah		; Is this an add block?
	jz	$+5		; Yes
	jmp	RtnRLBd		; No, they want delete

	; Check for valid owner TCB and GFB

	cmp	es:[0],'GH'	; Check for valid prefix (heap & GFB)
	je	RLBck1		; Ok, check TCB
	pop	ax
	mov	al,rcGFB	; Invalid GFB address
	ret
RLBck1:
	cmp	ss:[0],'TH'	; Check for valid prefix (heap & TCB)
	je	RLBck2		; Ok, continue
	pop	ax
	mov	al,rcTCB	; Invalid TCB address
	ret
RLBck2:
	; Add a RLB to the RLB list

	mov	dx,rlblen	; Get length of block in bytes
	mov	bx,es		; Save GFB pointer
	call	blkallo		; Get heap space for block
	assume	es:rlb
	mov	cx,rlblen	;
	call	clrdata		; Clear data area to 0s

	mov	[rlbtype],'R'	; Set block type field
	mov	[rlbtcb],ss	; Set Owner TCB field
	mov	[rlbgfb],bx	; Set GFB pointer field

	push	es		; Save RLB pointer
	mov	es,bx		; Restore GFB pointer
	assume	es:gfb
	mov	si,[gfbrlb]	; Get GFBs pointer to 1st RLB

	; Trace through RLBs to find last one

	xor	di,di		; Assume no active RLBs (setup for Blkins)
	or	si,si		; Are there any active RLBs for this TCB?
	jz	nocurrlb	; No currnet RLBs
	mov	di,si		; There is a minimum of one
flrlb:
	mov	es,di		; Point to next RLB
	assume	es:rlb
	mov	di,[rlbngfb]	; Pointer to next RLB for GFB
	or	di,di		; Last one?
	jnz	flrlb		; No, find last rlb
	mov	di,es		; Set last RLB pointer
nocurrlb:
	mov	ax,bx		; Save GFB pointer
	pop	es		; Restore new RLB pointer
	assume	es:rlb
	xor	bx,bx		; Insert 1st ####### May change later
	call	BlkIns		; Insert block into list of RLBs
	mov	bx,es		; Save RLB pointer
	mov	es,ax		; Address GFB
	assume	es:gfb
	mov	[gfbrlb],si	; Set new 1st RLB pointer in GFB
	mov	es,bx		; Address new RLB
	assume	es:rlb

	pop	ax
	mov	al,rcsuc	; Successful return code
	ret			; End of RtnRLB

	assume	ds:grp

	page
	; Delete an RLB from the RLB list

RtnRLBd:
	cmp	al,es:[1]	; Correct block type?
	je	RLBcont		; Yes, continue
	pop	ax
	mov	al,rcmtch	; Block type mismatch error
	ret
RLBcont:
	push	es		; Save block pointer (block to delete)
	mov	es,[rlbgfb]	; Get pointer to GFB
	assume	es:gfb
	mov	si,[gfbrlb]	; Get pointer to 1st RLB
	mov	di,si		; Assume only RLB (setup for BlkIns)
flrlb2:
	mov	es,di		; Point to next RLB
	assume	es:rlb
	mov	di,[rlbngfb]	; Pointer to next RLB for GFB
	or	di,di		; Last one?
	jnz	flrlb2		; No, find last rlb

	mov	di,es		; Set last RLB pointer
	pop	es		; Block pointer back
	push	es		;
	call	BlkDel		; Remove block from list of RLBs
	mov	es,[rlbgfb]	; Get pointer to GFB
	assume	es:gfb
	mov	[gfbrlb],si	; Update new pointer to 1st RLB in GFB
	pop	es		; Get pointer to block to deallocate
	assume	es:rlb
	mov	ah,1		; Deallocate block call
	mov	[rlbtcb],0	; Clear Owner TCB field
	call	mosheman	;
	or	al,al		; Any errors
	jz	$+5		; No
	jmp	errheap		; Yes, error with the heap
	pop	ax
	mov	al,rcsuc	; Successful return code
	ret			; End RtnRLB
errheap:
	pop	bx		; Discard original AX
	xchg	al,ah		; Put MOSHEMAN return code in AH
	mov	al,rchperr	; 'Heap error' code
	ret

RtnRLB	endp

	subttl	BLKALLO - Block allocation
	page
;-----------------------------------------------------------------------;
;	This small routine will calculate the amount of heap size	;
;	needed for a block and call MOSHEMAN to allocate it.  If an	;
;	error occurs then the call to this subroutine will be discarded	;
;	and control will be returned to the entry routine through	;
;	'errheap'.							;
;									;
;  On Entry:								;
;	DX = # bytes of storage needed.					;
;									;
;  On Exit:								;
;	ES = address of block on heap					;
;	DX = # paragraphs allocated					;
;									;
;	Global data affected						;
;	Global procedures called					;
;	AX is destroyed, ES and DX return info, others preserved.	;
;-----------------------------------------------------------------------;

blkallo	proc	near

	add	dx,0fH		; Round up to next segment value
	shr	dx,1		; Calc segment size for heap allocation
	shr	dx,1
	shr	dx,1
	shr	dx,1

	xor	ah,ah		; Allocate block on heap
	call	mosheman	;
	or	al,al		; Any errors?
	jnz	$+3		; None
	ret			; End sub
	pop	bx		; Clear call from stack
	jmp	errheap		; Yes, error in heap allocation

blkallo	endp

;-----------------------------------------------------------------------;
; Clear area at ES:0+10H of length CX (rounded to seg) to 0's		;
;-----------------------------------------------------------------------;
clrdata	proc	near

	push	ax
	sub	cx,10H		; Not including prefix
	add	cx,0fH		; Round up to next seg
	and	cx,0fff0H	;
	xor	al,al
	cld
	mov	di,10H		; Point to start of data area
	rep	stosb
	pop	ax
	ret

clrdata	endp


	subttl	BLKINS - Block insert routine
	page
;-----------------------------------------------------------------------;
;	This routine will insert a specified block into a linked list	;
;	of blocks and update all prefix pointers.  This routine is	;
;	general purpose and is intended to be used for TCBs, BDBs, GFBs	;
;	and all the other Bs that are used.				;
;									;
;  On Entry:								;
;	ES = segment address of block to insert				;
;	BX = segment address of present block to insert after, if 0	;
;	     then make block 1st in list.				;
;	SI = Pointer to 1st block in list (i.g. SCBTCBPF)		;
;	DI = Pointer to last block in list (i.g. SCBTCBPL)		;
;									;
;  On Exit:								;
;	SI and DI may contain updated pointers if the first and/or last	;
;	blocks where changed.						;
;									;
;	No global data affected						;
;	No global procedures called					;
;	SI and DI modified as needed, all other registers are unchanged	;
;-----------------------------------------------------------------------;
BlkIns	proc	near

	push	ds
	push	bx
	push	ax
	or	si,si		; Is there a 1st block now?
	jnz	$+5
	jmp	setonly		; No, this is the only block
	or	bx,bx		; Should inserted block be first in list?
	jz	BIfirst		; Yes, put it 1st
	mov	ds,bx		; Point to block to insert after
	mov	es:[0aH],bx	; Set 'Previous type' in newly inserted block
	mov	bx,ds:[08H]	; Get old 'Next type' from before block
	mov	es:[08H],bx	; Set in newly inserted block
	mov	ax,es		; Pointer to new block
	mov	ds:[08H],ax	; Set new 'Next type' in old block
	or	bx,bx		; Is the new block the last block?
	jnz	nolast		; No
	mov	di,ax		; Set new 'Last Pointer' for return
	jmp	Blkexit
nolast:
	mov	ds,bx		; Point to next (insert before this)
	mov	ds:[0aH],ax	; Set 'Previous type'
	jmp	Blkexit
BIfirst:
	mov	word ptr es:[0aH],0 ; Set 'previous type' to none
	mov	es:[08H],si	    ; Set 'next type' to old 1st
	mov	ds,si		; Point to old 1st block
	mov	ax,es		; Get pointer to new 1st block
	mov	ds:[0aH],ax	; Set 'previous type' to new 1st block
	mov	si,es		; Set new 'Pointer First' for return
	jmp	Blkexit
setonly:
	mov	word ptr es:[08H],0 ; Set 'next type' to none
	mov	word ptr es:[0aH],0 ; Set 'previous type' to none
	mov	si,es		    ; Set 'Pointer First'
	mov	di,si		; Set 'Pointer Last'
Blkexit:
	pop	ax
	pop	bx
	pop	ds
	ret			; End of BlkIns

BlkIns	endp


	subttl	BLKDEL - Block delete routine
	page
;-----------------------------------------------------------------------;
;	This routine will delete a specified block from a linked list	;
;	of blocks and update all necessary pointers.  This routine is	;
;	general purpose and is intended to be used for TCBs, BDBs, GFBs	;
;	and all the other Bs that are used.				;
;									;
;  On Entry:								;
;	ES = segment address of block to delete				;
;	SI = Pointer to 1st block in list (i.g. SCBTCBPF)		;
;	DI = Pointer to last block in list (i.g. SCBTCBPL)		;
;									;
;  On Exit:								;
;	SI and DI may contain updated pointers if the first and/or last	;
;	blocks where changed.						;
;									;
;	No global data affected						;
;	No global procedures called					;
;	SI and DI modified as needed, all other registers are unchanged	;
;-----------------------------------------------------------------------;
BlkDel	proc	near

	push	ax
	push	bx
	push	ds
	push	es
	mov	bx,es		; Pointer to block to delete
	cmp	bx,si		; Is it first block of this type
	je	DelFrst		; Yes
	cmp	bx,di		; Is it last block of this type
	je	DelLast		; Yes
	mov	bx,es:[08H]	; Get 'Next' pointer
	mov	ax,es:[0aH]	; Get 'Previous' pointer
	mov	es,bx		; Point to next block
	mov	ds,ax		; Point to previous block
	mov	ds:[08H],bx	; Set new 'Next' pointer in previous block
	mov	es:[0aH],ax	; Set new 'Previous' pointer in next block
DelEnd:
	pop	es		    ; Restore segment of deleted block
	mov	word ptr es:[08H],0 ; Clear 'Next' pointer field
	mov	word ptr es:[0aH],0 ; Clear 'Previous' pointer field
	pop	ds
	pop	bx
	pop	ax
	ret
DelFrst:
	cmp	bx,di		; Is this the only block?
	je	delonly		; Yes
	mov	ax,es:[08H]	; Get pointer to next block
	mov	es,ax		    ; Point to it
	mov	word ptr es:[0aH],0 ; Set 'Previous type' field to none
	mov	si,ax		    ; Set new 'First Pointer' for return
	jmp	DelEnd
delonly:
	xor	si,si		; Set as no 1st or last
	xor	di,di		;
	jmp	DelEnd
DelLast:
	mov	ax,es:[0aH]	; Get pointer to previous block
	mov	es,ax		    ; Point to that block
	mov	word ptr es:[08H],0 ; Set 'Next type' field to none
	mov	di,ax		    ; Set new 'Last Pointer' for return
	jmp	DelEnd

BlkDel	endp

	subttl	Subroutine - This is a subroutine
	page
;-----------------------------------------------------------------------;
;	Functional description of procedural block			;
;									;
;	Parms passed							;
;	Return values							;
;	Global data affected						;
;	Global procedures called					;
;	What registers are changed					;
;-----------------------------------------------------------------------;

mosseg	ends
	end

