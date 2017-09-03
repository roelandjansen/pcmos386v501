	include page.inc
	title	mosheman - mos heap manager
comment ^===============================================================
		    development specification

 program name:	$$mos.com		assigned to: david morrow
 module name:	mosheman		assign date: 01/20/86
 entry points:	mosheman		completed:   01/29/86
 entry from:	mosxxxxx
 entry method:	call
 calls:		-
 purpose:	heap management
 refer to:	-
 last update:	08/18/1992
========================================================================

this module is used to allocate or deallocate a block of space on the
heap.  in allocation, the logic should search for the smallest block
of available heap space that will satisfy the need.

=======================================================================

dam 02/10/86	added 'SHRINK BLOCK' call - dam

dam 02/24/86	added mos group and other changes for romability

dam 03/04/86	fixed bug of not setting ds to scbseg

dam 08/01/86	updated 'assume' statements and verified segment
		register usage.

dam 08/29/86	added % heap usage call

dam 09/15/86	removed calls to segfill to improve performance

dam 10/15/86	added additional info on heap corrupted message

dam 02/24/87	split heap logic, using split blocks

dam 08/27/87	added storing of scbhpalc for later retrival in mos map
		command. contains allocated heap so far

sah 10/20/87	remove references (unused) to mosdebug

sah 01/19/88	change scbseg and zero seg access to mgetxxx macros
		made sure that smp is always allocated in size of 64
		bytes (include 16 byte header)

sah 01/25/88	corrected problem associated with 286 driver which
		show a bug in 01/19/88 change which we sure mot round
		up value past to init routine

sah 02/12/88	corrected 01/19/88 change for 64 byte smp allocations

sah\rdr 02/20/88 move ddt segment to mo2 group

rbr 03/11/88	added declares/undeclares for 286 driver.

sah 11/26/89	clean up implementation of split heap.

bwr 11/29/89	marked messages for foreign language translation

sah 12/08/89	conditional assemble 286 driver logic out.

sah 12/15/89	implement split smp, into primary and secondary smp's

sah 02/21/90	corrections so that large heap is allocated first

sah 03/22/90	corrections for device drivers in 2 heaps.

================ 5.01 Kernel Ends Here ====================================

mjs 08/18/92	clean up segment declarations

======================================================================^

.xlist
;	include mosheman.pub
	include options.inc
	include group.inc
	include mosregs.inc
	include macros.inc

gdata	segment

extrn	scbhpadr:word			; segment address of start of heap
extrn	scbhpsiz:word			; length of heap in paragraphs
extrn	scbcursz:word			; current block size (during call)
extrn	scbcurad:word			; current block address (during call)
extrn	scbavsiz:word			; current available size (last call)
extrn	scbhpalc:word			; latest heap allocation (total)
extrn	scbmmsub:dword			; memory management routines
extrn	scbmmfea:byte			; memory management feature bits
extrn	scbhp2adr:word			; segment address of start of heap #2
extrn	scbhp2siz:word			; length of heap #2 in paragraphs
extrn	scbsmplow:byte			; allocated down in low smp memory.
extrn	scbhp1alc:word			; latest heap allocation (total for smp 1)

if	code286
extrn	scb286dec:byte			; ok to declare 286 segments
endif

gdata	ends
.list

;======================================================== mos segment
if 0 eq 0
segment_num = 1
endif
mosseg	segment
	assume	cs:mos,ds:nothing,es:nothing,ss:nothing

	extrn	mosend:byte, sbios:word
	extrn	bugerror:near		; critical error reporter routine
	extrn	noswitch:near		; critical flag routines
	extrn	okswitch:near		; "     "	"

	public	mosheman, chkheap

pval	dw	100			; used as constant in hpuse
fillstr db	'Heap'		; string used for init of heap memory

funtabl dw	mos:inith, mos:allocate, mos:deallo, mos:shrink, mos:hpuse
funtlen equ	($-funtabl)/2 - 1

	subttl mosheman - main entry point
	page
;======================================================================
;,fs
; mosheman - main entry point
;
; this module will allocate or deallocate a block of space in the
; operating system 'heap'.  memory is allocated as a linked list within
; the heap.  each block allocated is a multiple of 16 bytes, and
; includes a control prefix having the following format:
;
;	byte 0	 - 'H' to indicate allocated from the heap
;	byte 1	 - type of block (e.g., 'T' = tcb), 'Z' is reserved
;	byte 2-3 - length of this block in paragraphs
;	byte 4-5 - segment address of next block, 0 if last
;	byte 6-7 - segment address of previous block, 0 if first
;	byte 8-9 - address of next block of same type
;	byte a-b - address of previous block of same type
;	byte c-d - address of associated tcb
;	byte e-f - reserved
;	byte 10+ - data
;
; mosheman will initialize the 'Block of same type' pointers, bytes
; 8h - 0bh, to zero but these pointers must be maintained by the
; routines that use them.  mosheman will not modify them.
;
; in:	ah = request code - 0=allocate, 1=deallocate, 2=shrink block
;		 3= % usage, 0ffh=init, 0feh = init #2
;	dx = size requested, in paragraphs (allocate and shrink)
;	es = address of block (deallocate and shrink)
;	for init, ah = 0ffh, es=heapaddr, dx=heapsize (in paragraphs)
;		  ah = 0feh, es=heapaddr, dx=heapsize (in paragraphs)
;
; out:	al = exit code, 0 = successful
;			1 = requested size not available (allocate only)
;			2 = bad block address (deallocate and shrink)
;			3 = unknown command
;	dx = number of paragraphs allocated (allocate and shrink)
;	     (or # available, 0 if no heap space at all)
;	es = address of block (allocate and shrink), undefined if error
;	for ah = 2 - ax = formated ascii % value al=high digit, ah=low
;		     bx = integer % value (for calculations)
;	the ax, dx and es registers are modified as documented.  in
;	the case of an error es is undefined.  all other
;	registers are preserved.
;
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:nothing
mosheman proc near
	push	bx
	push	cx
	push	si
	push	di
	push	ds
	cmp	ah,0feh 		; init code?
	jae	okfun
	cmp	ah,funtlen		; validate function code
	jb	okfun
	mov	al,3			; unknown command
	jmp	nothin			; they ask for nothing they get it!
okfun:
	mgetscb ds			; assure addressing scb data
	assume	ds:grp
	call	noswitch		; set mos no switch flag
	cmp	ah,0feh
	jne	nothfe			; check if heap # 2 init call
	call	inith2			; init secondary heap
	jmp	short hpskip
nothfe:
	cmp	ah,0ffh 		; is this an init call?
	je	shpchk			; yes, skip heap check
	call	chkheap 		; check for heap corruption
shpchk:
	xor	bh,bh
	mov	bl,ah			; function code
	add	bl,1			; calc routine index
	shl	bx,1			; word index

if	code286
	push	dx
	cmp	ah,0ffh
	je	skipha
	cmp	dx,-1
	je	skipha
	or	dx,7
	inc	dx
skipha:
endif

	call	[bx+funtabl]		; execute routine requested

if	code286
	pop	cx
	cmp	dx,-1
	je	hpskip
	mov	bx,cx
	or	bx,7
	inc	bx
	cmp	dx,bx
	jne	hpskip
	mov	dx,cx
endif

hpskip:
	call	okswitch
nothin:
	pop	ds
	pop	di
	pop	si
	pop	cx
	pop	bx
	ret
mosheman endp

	subttl init - heap initialization
	page
;======================================================================
;,fs
; init - heap initialization
;
; init will initialize the heap by setting up one block the size
; of the heap and mark it as the first and last block and that it
; is free.  the data area will be filled with the string 'Heap'
; for easy reference during debugging.  if a re-init call is made
; then any existing heap entries are preserved and the heap is
; adjusted upward in memory if the space is available.
;
; in:	es=heapaddr, 0 for default to present value if this is a
;			re-init
;	dx=heapsize (in paragraphs)
;	ds -> grp
;
; out:	the memory area starting at segment es and of length dx paras
;	is initialized for heap usage as one block marked as free space
;	all registers are preserved.
;
;,fe
;======================================================================
	assume	ds:grp,es:nothing,ss:nothing
inith proc near
	push	ax
	mov	ax,es			; get heapaddr
	or	ax,ax			; check for re-init
	jz	skipheap
	mov	[scbhpadr],ax		; set heap address
	mov	[scbhpsiz],dx		; set heap size
	call	setheap
	mov	dx,[scbhpsiz]		; return with original dx
	mov	word ptr [scbhpalc],0	; sah initialize to zero
skipheap:
	pop	ax
	ret

; init secondary heap code

inith2:
	push	ax
	mov	ax,es			; get heapaddr
	or	ax,ax			; check for re-init
	jz	skipheap2
	mov	[scbhp2adr],ax		; set heap address
	mov	[scbhp2siz],dx		; set heap size
	call	setheap
	mov	dx,[scbhp2siz]		; return with original dx
skipheap2:
	pop	ax
	ret

; init heap common code

setheap:
	mov	byte ptr es:[0],'H'	; set heap indicator
	mov	byte ptr es:[1],'Z'	; set block type to 'free'
	mov	word ptr es:[2],dx	; set block length, paragraphs
	mov	word ptr es:[4],0	; blank 1st block pointer
	mov	word ptr es:[6],0	; blank last block pointer
	mov	word ptr es:[8],0	; blank address of next same type
	mov	word ptr es:[0ah],0	; blank address of previous same type
	mov	word ptr es:[0ch],0	; blank address of assoc. tcb
	mov	word ptr es:[0eh],0	; blank reserved word
	inc	ax			; point to next paragraph
	dec	dx			; # paragraphs minus block prefix
	add	dx,ax			; calc end segment

; mark rest of block with 'Heap'

	push	es
	push	ds
	mov	cx,cs
	mov	ds,cx			; for accessing constant fillstr
segflp:
	mov	es,ax			; set segment
	xor	di,di
	mov	cx,4			; 4 strings per segment
lp1:
	mov	si,offset fillstr
	movsw
	movsw				; faster method of moving 4 characters
	loop	lp1
	inc	ax			; next seg
	cmp	ax,dx			; end of heap?
	jb	segflp			; not yet
	pop	ds
	pop	es
	ret
inith endp

	subttl hpuse - calculate % heap used
	page
;======================================================================
;,fs
; hpuse - calculate % heap used
;
; hpuse will calculate the percentage of the heap that has been
; allocated.  two values will be passed back, one in integer form
; suitable for making calculations, and the other in ascii for use in
; displays.  the ascii form is returned with the high digit in the low
; byte of the register so that all that needs to be done is
; a mov [msg],ax.
;
; in:	ds -> grp
;
; out:	ax = ascii form of % heap used
;	dx = integer form of % heap used
;	ax and dx return values all other registers are preserved.
;
;,fe
;======================================================================
	assume	ds:grp,es:nothing,ss:nothing
hpuse proc near
	push	es
	push	bx
	mov	bx,[scbhpadr]		; start at beginning of heap
	xor	ax,ax			; ax will hold running count of free blocks
usedlp:
	or	bx,bx			; end of list?
	jz	endlook 		; yes
	mov	es,bx			; address next block
	assume	es:nothing
	cmp	byte ptr es:[1],'Z'	; is this a free block?
	je	lookfre 		; yes, skip counting it
	add	ax,es:[2]		; get block length
lookfre:
	mov	bx,es:[4]		; get pointer to next block
	jmp	short usedlp
endlook:
	mov	[scbhpalc],ax		; sah store heap count
	mov	[scbhp1alc],ax		; save heap #1 count
	mov	bx,[scbhp2adr]
	or	bx,bx			; secondary heap used
	jz	skipuse2
	xor	ax,ax			; ax will hold running count of free blocks
usedlp2:
	or	bx,bx			; end of list?
	jz	endlook2		; yes
	mov	es,bx			; address next block
	assume	es:nothing
	cmp	byte ptr es:[1],'Z'	; is this a free block?
	je	lookfre2		; yes, skip counting it
	add	ax,es:[2]		; get block length
lookfre2:
	mov	bx,es:[4]		; get pointer to next block
	jmp	short usedlp2
endlook2:
	add	[scbhpalc],ax		; add value for second heap
skipuse2:
	mov	ax,[scbhpalc]
	xor	dx,dx
	mul	[pval]			; mul by 100 for %
	mov	bx,[scbhpsiz]		; check for round up from .5%
	add	bx,[scbhp2siz]		; add value for second heap
	div	bx			; calc how much of total heap used
	shr	bx,1
	cmp	dx,bx			; is remainder more than half a %
	jb	nornd			; no
	inc	al
nornd:
	cmp	ax,100			; if 100% then return 99%
	jne	nomax
	dec	ax
nomax:
	mov	dx,ax			; save integer value
	aam				; convert to ascii
	add	ax,3030h		;	"       "
	xchg	al,ah			; make suitable for word store into message
	cmp	al,'0'			; is value less than 10%?
	jne	gtten			; no, greater than 10
	mov	al,' '			; clear off leading zeros
gtten:
	pop	bx
	pop	es
	ret
hpuse endp

	subttl allocate - allocate a block on heap
	page
;======================================================================
;,fs
; allocate - allocate a block on heap
;
; this routine will allocate a block of memory on the heap
; starting at segment es and of size dx paragraphs.  the smallest
; block that satisfies the need will be used.
;
; in:	dx = number of paragraphs needed.
;	ds -> grp
;
; out:	al = 0 if successful, else error code
;	   = 1 if 'Size not available' error
;	es = segment address of block, undefined if error
;	dx = number of paragraphs allocated
;	     (or # available, 0 if no heap space at all)
;	ax,  dx, and es used to return parms, all others unchanged.
;
;,fe
;======================================================================
	assume	ds:grp,es:nothing,ss:nothing
allocate proc near
	push	bx			; save bx register
	mov	[scbcursz],0ffffh	; default current size to giant
	mov	[scbavsiz],0		; init available size to 0
	cmp	[scbhp2siz],0		; if only 1 heap skip, force low test
	jne	do2heaps

; we will scan heap #1 only if heap #2 is not being used

	mov	bx,[scbhpadr]
	jmp	short doscan

; the following logic is added to handle 2 smp's.  First we will
; check to see if ldevice is specified and if so we will force the
; allocation to be allocated in 2nd heap

do2heaps:
	mov	bx,[scbhp2adr]		; access 2 heap
	test	[scbsmplow],1		; is this requested to allocate down low
	jnz	doscan			; yes....for ldevice
	call	findlar 		; largest block is return in bx

; common scan heap scan logic

doscan:
	or	bx,bx			; last block?
	jz	noblks			; yes
	mov	es,bx			; set pointer to next block
	call	findfre 		; find free block (return es pointer, ax size)
	or	ax,ax			; any free blocks left?
	jz	noblks			; nop, no more free blocks
	mov	bx,es:[4]		; get address for next block
	cmp	ax,[scbavsiz]		; is this one larger than others checked?
	jbe	noavail 		; no, smaller
	mov	[scbavsiz],ax		; set new availalble size
noavail:
	cmp	dx,ax			; large enough?
	ja	doscan			; no, try another
	cmp	ax,[scbcursz]		; smaller than previous block?
	jae	doscan			; no, try yet another block
	mov	[scbcursz],ax		; set this block as the one we want
	mov	[scbcurad],es		; set segment pointer to it
	jmp	short doscan		; try for a smaller one still
noblks:
	pop	bx
	cmp	[scbcursz],0ffffh	; any block available?
	je	endavail		; no, return with available size
retheap:
	mov	ax,[scbcursz]		; get the smallest that suits the need
	mov	es,[scbcurad]		; get pointer to that block
	sub	ax,dx			; calc # para's left over
	or	ax,ax			; perfect fit?
	jnz	blkadj			; no, must adjust blocks
	mov	byte ptr es:[1],0	; clear free block type (i.e. 'Z')
	ret				; end of allocation, al=0 return code
endavail:
	mov	dx,[scbavsiz]		; tell what size is available
	mov	al,1			; size not available error code
	ret
blkadj:
	push	ds
	push	ax			; temp save size of adjustment
	mov	ax,es			; address of current block
	push	ax
	add	ax,dx			; calc seg address of next block

if	code286
	test	[scbmmfea],08h
	jz	allno286
	push	ax
	push	bx
	push	cx
	mov	bx,ax
	mov	ah,0ah
	xor	cl,cl
	call	[scbmmsub]
	pop	cx
	pop	bx
	pop	ax
allno286:
endif

	mov	es,ax			; point to next block
	pop	ds			; ds points to current block
	assume	ds:nothing

; update current control prefix

	mov	byte ptr ds:[1],0	; clear free block type (i.e. 'Z')
	mov	ds:[2],dx		; set new 'length' field
	mov	dx,ds:[4]		; get pointer to next block (old one)
	mov	ds:[4],ax		; set seg of 'next block' field

; update old next block

	or	dx,dx			; is this the 1st block?
	jz	nopadj
	push	ds
	mov	ds,dx
	mov	ds:[6],es		; set new 'previous block' field
	pop	ds
nopadj:

; create new control prefix for next block

	mov	byte ptr es:[0],'H'	; indicate allocated from heap
	mov	byte ptr es:[1],'Z'	; indicate as free block
	pop	ax			; restore size adjustment
	mov	es:[2],ax		; set 'length' field
	mov	es:[4],dx		; set 'next block' field
	mov	ax,ds			; get address of previous block
	mov	es:[6],ax		; set 'previous block' field
	xor	ax,ax
	mov	es:[8],ax		; zero out 'type' addresses
	mov	es:[0ah],ax
	mov	es:[0ch],ax		; zero out 'TCB' field
	mov	es:[0eh],ax		; zero out 'Reserved' field
	mov	dx,ds			; address of block just allocated
	pop	ds			; restore original ds
	assume	ds:grp
	mov	es,dx			; set return address to allocated block
	mov	dx,es:[2]		; get length for return
	ret				; end successful allocation
allocate endp

	subttl findlar - find largest heap
	page
;======================================================================
;,fs
; findlar - find largest heap
;
; this routine will return block with largest possiable heap
;
; in:	
;
; out:	bx -> largest heap (either scbhpadr or scbhp2adr)
;
;,fe
;======================================================================
	assume	ds:grp,es:nothing,ss:nothing
findlar proc near
	push	cx
	mov	bx,[scbhpadr]		; scan heap #1 for largest
	call	scanlar
	push	ax			; save largest available
	mov	bx,[scbhp2adr]		; scan heap #2 for largest
	call	scanlar
	pop	cx
	cmp	ax,cx			; is heap #2 > heap #1
	ja	heap2lar		; yes.. return heap #2 address
	mov	bx,[scbhpadr]		; no... return heap #1
heap2lar:
	pop	cx
	ret
findlar endp

	subttl scanlar - scan heap for largest block
	page
;======================================================================
;,fs
; scanlar - scan heap for largest block
;
; in:	bx -> heap to search (either scbhpadr or scbhp2adr)
;
; out:	ax -> largest block found in heap
;
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:nothing
scanlar proc near
	push	bx
	xor	cx,cx			; init to nothing
srchlloop:
	or	bx,bx			; last block?
	jz	lnoblks 		; yes
	mov	es,bx			; set pointer to next block
	call	findfre 		; find free block (return es pointer, ax size)
	or	ax,ax			; any free blocks left?
	jz	lnoblks 		; nop, no more free blocks
	mov	bx,es:[4]		; get address for next block
	cmp	ax,cx			; is this one larger than others checked?
	jbe	srchlloop		; no, smaller
	mov	cx,ax
	jmp	short srchlloop 	; and continue searching
lnoblks:
	mov	ax,cx			; return largest available block
	pop	bx
	ret
scanlar endp

	subttl findfre - return pntr to next available block of heap memory
	page
;======================================================================
;,fs
; findfre - return pntr to next available block of heap memory
;
; in:	es = address of starting block for search
;
; out:	es = address of free block
;	ax = size of free block, 0 if no free blocks availible
;	bx is destroyed
;
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:nothing
findfre proc near
	xor	ax,ax			; assume no free blocks
	mov	bx,es			; starting pointer
ffloop:
	mov	es,bx			; point to next block
	cmp	byte ptr es:[1],'Z'	; is this a free block
	je	endfre			; yes, exit accordingly
	mov	bx,es:[4]		; get seg of next block
	or	bx,bx			; last block?
	jnz	ffloop			; no, not yet - keep on truckn'
	ret				; no free blocks, exit with ax=0
endfre:
	mov	ax,es:[2]		; get # para's for this block
	ret
findfre endp

	subttl deallo - deallocate a block on the heap
	page
;======================================================================
;,fs
; deallo - deallocate a block on the heap
;
; this routine will deallocate a specified block of memory on the
; heap.  if the specified block is adjacent to any other free
; blocks then they will be combined into one common free block.
;
; in:	es = segment address of block to deallocate
;
; out:	al = error code.  0 = successful
;			  2 = bad block address
;	ax, cx, si, and di are destroyed.  all others preserved.
;
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:nothing
deallo proc near
	push	es
	push	ds
	push	ax
	cmp	byte ptr es:[0],'H'	; is this a valid block?
	je	$+5			; yes, continue
	jmp	badadr			; no, bad block address
	mov	byte ptr es:[1],'Z'	; mark block as free
	mov	ax,es
	mov	ds,ax			; point to block to be deallocated
	assume	ds:nothing
	mov	ax,ds:[6]		; get address of previous block
	or	ax,ax			; is this the first block?
	jz	trynext 		; yes, check on the next block
	mov	es,ax			; point to previous block
	cmp	byte ptr es:[1],'Z'	; is this block free?
	jne	trynext 		; no, try the next block
	call	combine 		; combine the blocks es and ds
trynext:
	mov	ax,ds:[4]		; get address of next block
	or	ax,ax			; is this the last block?
	jz	enddeallo		; yes, no need to check for it free
	mov	es,ax			; point to next block
	cmp	byte ptr es:[1],'Z'	; is the next block a free one?
	jne	enddeallo		; no, that's all, exit
	call	combine 		; combine the free blocks at es and ds
enddeallo:
	mov	ax,ds			; get start of fill address
	push	dx
	mov	dx,ax			; calc end of fill address
	add	dx,ds:[2]		; add length of this block
	pop	dx
	pop	ax			; original ax back
	xor	al,al			; deallocation complete
	pop	ds
	assume	ds:grp
	pop	es
	ret				; end deallo

badadr:
	pop	ax			; original ax back
	mov	al,2			; bad block address error code
	pop	ds
	pop	es
	ret				; end deallo
deallo endp

	subttl shrink - shrink specified block to a new size
	page
;======================================================================
;,fs
; shrink - shrink specified block to a new size
;
; this routine will shrink a block in the heap to a smaller size
; than initially allocated.
;
; in:	es = segment address of block to shrink
;	dx = size to shrink to
;
; out:	al = error code.  0 = successful
;			  2 = bad block address
;	dx = size block set to
;	ax and dx are set according to exit parms, all others preserved
;
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:nothing
shrink proc near
	push	es
	push	ds
	push	ax
	cmp	byte ptr es:[0],'H'	; is this a valid block?
	je	$+5			; yes, continue
	jmp	badadr2 		; no, bad block address
	cmp	dx,es:[2]		; is size smaller?
	jb	doshrk			; yes, perform the shrink
	mov	dx,es:[2]		; don't shrink, just give them smaller size
	jmp	endshrk 		; end it
doshrk:
	mov	ax,es:[2]		; get current size
	mov	es:[2],dx		; set new size
	sub	ax,dx			; calc amount left over
	push	ax			; save size for new block
	mov	ax,es			; seg of current block
	add	ax,dx			; calc seg of new block

if	code286
	test	[scbmmfea],08h
	jz	shrno286
	push	ax
	push	bx
	push	cx
	mov	bx,ax
	mov	ah,0ah
	xor	cl,cl
	call	[scbmmsub]
	pop	cx
	pop	bx
	pop	ax
shrno286:
endif

	mov	ds,ax			; address it
	assume	ds:nothing

; set up new block prefix for newly created free block

	mov	byte ptr ds:[0],'H'	; indicate allocated from heap
	mov	byte ptr ds:[1],'Z'	; indicate as free block
	pop	ax			; restore size
	mov	ds:[2],ax		; set 'length' field
	mov	ax,es			; get address of previous block
	mov	ds:[6],ax		; set 'previous block' field
	xor	ax,ax
	mov	ds:[8],ax		; zero out 'type' addresses
	mov	ds:[0ah],ax
	mov	ds:[0ch],ax		; zero out 'TCB' field
	mov	ds:[0eh],ax		; zero out 'Reserved' field
	mov	dx,ds			; get address of new block
	mov	ax,es:[4]		; get address of next block
	mov	ds:[4],ax		; set next block for new block
	mov	es:[4],dx		; set new next block pointer for shrunk block
	mov	dx,es:[2]		; get shrunk size
	or	ax,ax			; is new one the last block?
	jz	endshrk 		; yes, thats all there is to do, so exit
	mov	es,ax			; point to next block (adjacent to shrinking)
	mov	ax,ds			; get pointer to newly created block
	mov	es:[6],ax		; set previous block pointer to new one
	cmp	byte ptr es:[1],'Z'	; is the next block free also?
	jne	endshrk 		; no, skip combining
	call	combine 		; combine newly freed area with next block
	mov	ax,es			; point to block to be filled
	mov	dx,ax
	inc	ax
	add	dx,es:[2]		; fill to end of block
endshrk:
	pop	ax			; original ax back
	xor	al,al			; shrink complete
	pop	ds
	assume	ds:grp
	pop	es
	mov	dx,es:[2]		; get shrunk size
	ret				; end shrink
badadr2:
	pop	ax			; original ax back
	mov	al,2			; bad block address error code
	pop	ds
	pop	es
	ret				; end shrink
shrink endp

	subttl combine - combine 2 free blocks into 1
	page
;======================================================================
;,fs
; combine - combine 2 free blocks into 1
;
; this routine will combine two adjacent free blocks into one
; large free block.
;
; in:	es = seg address of one of the adjacent free blocks
;	ds = seg address of the other adjacent free block
;
; out:	ds = es = address of combined free block (the lower of the 2)
;	the es and ds are the only registers modified
;
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:nothing
combine proc near
	push	ax
	push	bx
	mov	ax,es			; get one block address
	mov	bx,ds			; get other block address
	cmp	ax,bx			; which one is 1st in memory?
	jb	esfirst 		; es is 1st in memory
	mov	es,bx			; swap pointers
	mov	ds,ax
esfirst:
	mov	ax,es:[2]		; get 'length' of first
	add	ax,ds:[2]		; add 'length' of second
	mov	es:[2],ax		; set new 'length' in first
	mov	ax,ds:[4]		; get 'next block' from second
	mov	es:[4],ax		; set as new 'next block' address in first

if	code286
	push	bx
	mov	bx,ds
	mgetscb ds
	assume	ds:grp
	test	[scbmmfea],08h
	jz	comno286
	push	ax
	push	cx
	mov	ah,0ah
	mov	cl,-1
	call	[scbmmsub]
	pop	cx
	pop	ax
comno286:
	pop	bx
	assume	ds:nothing		
endif

	or	ax,ax			; is the second the last block?
	jz	comlast 		; yes
	mov	ds,ax			; point to that next block
	mov	ax,es			; get seg address for first block
	mov	ds:[6],ax		; set the 'previous block' past second
comlast:
	mov	ax,es
	mov	ds,ax			; set up return seg addresses
	pop	bx
	pop	ax
	ret
combine endp

	subttl chkheap - check validity of heap structure
	page
;======================================================================
;,fs
; chkheap - check validity of heap structure
;
; this routine will check the links, pointers and id bytes of the
; blocks on the heap to see if they have been overwritten.  this
; is provided to assist in debugging (your welcome).  if the
; heap has been found to be invalid then the message 'Heap
; corrupted!' is displayed and then a 'soft lock' will be
; instigated.
;
; in:	ds -> grp
;
; out:	no registers or parms
;	all registers preserved.
;
;,fe
;======================================================================
	assume	ds:grp,es:nothing,ss:nothing
chkheap proc near
	push	ax
	push	bx
	push	es
	mov	bx,[scbhpadr]		; starting pointer
	call	checksmp
	mov	bx,[scbhp2adr]
	or	bx,bx
	jz	skipcsmp
	call	checksmp
skipcsmp:
	pop	es
	pop	bx
	pop	ax
	ret

; common routine inside chkheap to verify that heap is
; valid.

checksmp:
	xor	ax,ax			; holds address of previous block
chloop:
	mov	es,bx			; point to next block
	cmp	byte ptr es:[0],'H'	; is this a heap block?
	jne	endch			; no, error in heap!
	cmp	ax,es:[6]		; check 'previous block' address
	jne	endch			; error in heap!
	mov	ax,es
	mov	bx,es:[4]		; get seg of next block
	or	bx,bx			; last block?
	jnz	chloop			; no, not yet - keep on truckn'

	cmp	byte ptr es:[0],'H'	; check the last block also
	jne	endch			; error in heap!
	ret

endch:
	call	bugerror
	db	'02 '			; heap corrupted error
	db	13,10,'System Memory Pool (SMP) Corrupted!          ',0  ;@@xlat

chkheap endp

mosseg	ends
	end

