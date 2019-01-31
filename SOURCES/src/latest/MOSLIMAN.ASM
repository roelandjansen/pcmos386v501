	include page.inc
	title	mosliman - mos list management
comment ^===============================================================
		    development specification

 program name:	$$mos.com		assigned to: david morrow
 module name:	mosliman		assign date: 02/17/86
 					completed:   02/25/86
 entry points:	mosliman
 entry from:	mosxxxxx
 entry method:	call
 calls:		mosheman
 purpose:	list management
 refer to:	n/a
 last update:	08/18/1992
========================================================================

this routine provides for adding and removing memory blocks of
various types to and from the appropriate heap-resident list(s).
different treatments are performed, depending on the type of block.

registers passed are:
	ah - 0=add, 1=remove
	al - block type code:
		'T' = tcb
		'F' = tfb
		'G' = gfb
		'C' = cdb
		'B' = bdb
		'R' = rlb
	ss - owner tcb address (if adding a tfb, cdb, or rlb)
	es - owner gfb address (if adding a tfb or rlb)  ; or
	     address of block (if remove)

registers returned are:
	al - 	0- successful
		1- heap error, ah = mosheman error code
		2- bad block (add)	; type mismatch (del)
		3- active tfb pointers (for tcb & gfb deletes)
		4- active rlb pointers (for gfb deletes)
		5- active cdb pointers (for tcb deletes)
		6- bad tcb owner address (for add tfb, cdb,
						or	rlb)
		7- bad gfb owner address (for add tfb or rlb)

	es - address of block (if add)

the list management routines are grouped into one code module because
it is expected that some local subroutines can be shared, and for
consolidation.

other than clearing a new block's data areas to binary zeros, no
initialization logic is performed beyond memory and pointer
management (this could possibly change, given a good reason).

=======================================================================

jrb 07/24/87	insert/delete tcb from priority list as well as tcb list

jsm 11/18/87	maintain bdbdpbpn fields in bdbrtn for both insert
		and	delete functions

sah 01/20/88	change scbseg and zero seg to mgetxxxx macros

sah 02/16/88	declare\undeclare tcb's

sah/rbr 02/20/88 move ddt segment to mo2 group

rbr 02/29/88	move notsl to grp.

rbr 03/07/88	fix "declare" bug	; can now declare tfb's.

rbr 03/11/88	moved declares/undeclares to mosheman.

sah 09/04/88	added routines to add and delete sft simulations for
		ms-windows.

sah 05/11/89	corrections so that sft logic for windows, doesn't
		corrupt int 4 vector.  oversite on my part when i solved
		windows.

sah 06/29/89	change notsl to scbnotsl.

sah 01/22/91	changes to sft logic so that file counters are supported

sah 01/22/91	change terminated on sft change to dword -1 instead of
		pointing totcbsft

================ 5.01 kernel ends here ====================================

mjs 08/08/92	moved the call to clrsft to come before the call to
		blkdel.  blkdel clears pointers that clrsft needs.

mjs 08/18/92	clean up segment declarations

=======================================================================^

.xlist
;	include	mosliman.pub
	include group.inc
	include mosregs.inc
	include	moscdb.inc
	include	mosgfb.inc
	include	mostfb.inc
	include	mosrlb.inc
	include	mosbdb.inc
	include macros.inc

tcb	segment at 1234h
	include	mostcb.inc
tcb	ends

gdata	segment
	include	mosscbex.inc
gdata	ends
.list

;======================================================== mos segment
if 0 eq 0
segment_num = 1
endif
mosseg	segment
	assume	cs:mos,ds:nothing,es:nothing,ss:nothing
	public	$$$liman
$$$liman label	byte
	extrn	mosend:byte, sbios:word
	public	mosstdin,mosstdout,mosstdnul,mosstdprn,mosstdaux

mosstdin:		;### temporary home for these routines
mosstdout:		;### temporary home for these routines
mosstdnul:		;### temporary home for these routines
mosstdprn:		;### temporary home for these routines
mosstdaux proc far	;### temporary home for these routines
	ret
mosstdaux endp		;### temporary home for these routines

; return codes

rcsuc		equ	0	   	; successful
rchperr		equ	1		; heap error
rcmtch		equ	2		; block type codes do not match error
rctfb		equ	3		; active tfb pointers error
rcrlb		equ	4		; active rlb pointers error
rccdb		equ	5		; active cdb pointers error
rctcb		equ	6		; bad tcb owner address
rcgfb		equ	7		; bad gfb owner address

; extrn's rite cheer

	extrn	mosheman:near, noswitch:near, okswitch:near

; public's rite cheer

	public	mosliman


lifunct	db	'T','F','G','C','B','R'  ; routine codes
funlen	equ	$-lifunct		; # of them

lidispt	dw	mos:rtntcb, mos:rtntfb, mos:rtngfb
	dw	mos:rtncdb, mos:rtnbdb, mos:rtnrlb

	subttl mosliman - mos list manager, entry point
	page
;======================================================================
;,fs
; mosliman - mos list manager, entry point
;
; in:	
;
; out:	
; 
;,fe
;================================================================
	assume	ds:nothing,es:nothing,ss:tcb
mosliman proc near
	push	bx
	push	cx
	push	dx
	push	si
	push	di
	push	ds
	push	es
	mgetscb ds
	assume	ds:grp
	mov	cx,funlen
	mov	di,cs			; for accessing constant lifunct
	mov	es,di
	lea	di,lifunct
	cld
	repne	scasb			; determine type of block
	pop	es
	jne	errblock		; invalid block type
	mov	di,funlen		; calc dispatcher offset
	sub	di,cx
	dec	di			; zero relative table
	shl	di,1			; word offset into table
	call	noswitch		; set no switch flag
	call	[di+lidispt]		; execute appropriate routine
	call	okswitch
liexit:
	pop	ds
	pop	di
	pop	si
	pop	dx
	pop	cx
	pop	bx
	ret				; end mosliman
errblock:
	mov	al,rcmtch		; 'Bad block type' error code
	jmp	liexit
mosliman endp

	subttl rtntcb - add or delete a tcb
	page
;======================================================================
;,fs
; rtntcb - add or delete a tcb
;
; this routine will delete or add a tcb to the list of current tcbs.
;
; for add the tcb will be allocated from the heap, its data area
; cleared to 0s, and the scb pointers to 1st and last tcb
; (scbtcbpf, scbtcbpl) will be updated accordingly.  the new tcb
; will be put on the end of the current tcb list.
;
; for delete the tcb will be checked for any pointers to active
; tfbs or cdbs and if found will not delete the block but return
; with an error code (the routine deleteing the tcb must delete
; all linked information first).  if no active pointers are
; found then the tcb will be deallocated from the heap and the
; scb pointers for 1st and last tcb will be updated.
;
; in:	ah = function code: 0- add, 1- delete
;	al = block id type
;	es = tcb addresss (if del)
;
; out:	al = error code, ah = error code for mosheman (if error)
;	es = address of tcb, undefined on exit for delete
;	bx, cx, dx, si, di destroyed
; 
;,fe
;================================================================
	assume	ds:grp,es:nothing,ss:nothing
rtntcb proc near
	push	ax
	or	ah,ah			; is this an add block?
	jz	$+5			; yes
	jmp	rtntcbd			; no, they want delete

; add a tcb to the tcb list

	mov	dx,tcblen		; get length of block in bytes
	call	blkallo			; do heap allocation (es=address of block)
	assume	es:tcb
	mov	[tcbtype],'T'		; set block type field
	lea	si,tcbstack		; the sp save word must be set to something
	mov	[tcbsp],si		;  valid in case of irqs during tsl
	mov	si,[scbtcbpf]		; get scb pointer to 1st tcb
	mov	di,[scbtcbpl]		; get scb pointer to last tcb
	mov	bx,di			; put new tcb at end of list
	call	blkins			; insert block into list
	mov	[scbtcbpf],si		; set scb pointer to 1st tcb
	mov	[scbtcbpl],di		; set scb pointer to last tcb
	mov	ah,[scbnotsl]
	mov	[scbnotsl],'Y'
	push	ax
	mov	ax,[scbpripf]
	push	ds
rtcb1:
	mov	ds,ax
	assume  ds:tcb,es:nothing
        mov	ax,[tcbpripn]
        or	ax,ax
        jnz	rtcb1
        mov	[tcbpripn],es
        assume  ds:grp,es:tcb
        pop	ds

; clear data area of tcb to 0's

	mov	cx,tcblen		; get total length of block
	call	clrdata			; clear data area to 0s
	pop	ax
	mov	[scbnotsl],ah
	pop	ax
	mov	al,rcsuc		; successful return code
	ret				; end of rtntcb
	assume	es:tcb
rtntcbd:
	cmp	al,[tcbtype]		; correct block type?
	je	tcbcont			; yes, continue
	pop	ax
	mov	al,rcmtch		; block type mismatch error
	ret
tcbcont:
	cmp	[tcbtfbpf],0		; any active tfbs?
	jne	etcbtfb			; yes, cannot delete block
	cmp	[tcbcdbpf],0		; any active cdbs?
	jne	etcbcdb			; yes, cannot delete block
	jmp	deltcbok		; ok to delete
etcbtfb:
	pop	ax			; restore original ax
	mov	al,rctfb		; active tfbs error code
	ret
etcbcdb:
	pop	ax			; restore original ax
	mov	al,rccdb		; active cdbs error code
	ret
deltcbok:
	mov	ah,'Y'			
	xchg	ah,[scbnotsl]		
	push	ax			
	mov	di,es			; remember location of one being deleted
	mov	ax,[scbpripf]		
	cmp	ax,di			
	jne	deltpri1		; e if it were first in priority list
	mov	ax,[tcbpripn]		; delete from first position in priority list
	mov	[scbpripf],ax		
	jmp	deltpri3		
deltpri1:				
	mov	es,ax			
	mov	ax,[tcbpripn]		
	or	ax,ax			
	jz	deltpri3		; z if not in list (so don't delete it)
	cmp	ax,di			
	jne	deltpri1		
deltpri2:				

; es = tcb prior to one to delete

	push	ds			
	mov	ds,di			; ds -> tcb to be deleted
	assume	ds:tcb,es:nothing
	mov	ax,[tcbpripn]		; delete it from the priority list
	assume	ds:grp,es:tcb		
	mov	[tcbpripn],ax		
	pop	ds			
deltpri3:				
	mov	es,di			
	pop	ax			
	mov	[scbnotsl],ah		
	mov	si,[scbtcbpf]
	mov	di,[scbtcbpl]
	call	blkdel			; remove block from list of tcbs
	mov	[scbtcbpf],si		; set scb pointer to 1st tcb
	mov	[scbtcbpl],di		; set scb pointer to last tcb
	mov	ah,1			; deallocate block call
	call	mosheman
	or	al,al			; any errors
	jz	$+5			; no
	jmp	errheap			; yes, error with the heap
	pop	ax
	mov	al,rcsuc		; successful return code
	ret				; end rtntcb
rtntcb endp

	subttl rtntfb - add or delete a tfb
	page
	page
;======================================================================
;,fs
; rtntfb - add or delete a tfb
;
; this routine will delete or add a tfb to the list of current tfbs.
;
; for add the tfb will be allocated from the heap, its data area
; cleared to 0s, the owner tcb and gfb fields will be set, and
; the links into both the tcb and gfb will be updated accordingly
;
; for delete the links from the tfb back into the tcb and gfb
; will be updated and the tfb will be deallocated from the heap.
;
; in:	ah = function code: 0- add, 1- delete
;	al = block id type
;	ss = owner tcb address (if add)
;	es = owner gfb address (if add) or tfb addresss (if del)
;
; out:	al = error code, ah = error code for mosheman (if error)
;	es = address of tfb (if add) or undefined on exit for delete
;	bx, cx, dx, si, di destroyed
; 
;,fe
;================================================================
	assume	ds:grp,es:nothing,ss:tcb
rtntfb proc near
	push	ax			; save block id
	or	ah,ah			; is this an add block?
	jz	$+5			; yes
	jmp	rtntfbd			; no, they want delete

; check for valid owner tcb and gfb

	cmp	word ptr es:[0],'GH'	; check for valid prefix (heap & gfb)
	je	tfbck1			; ok, check tcb
	pop	ax
	mov	al,rcgfb		; invalid gfb address
	ret
tfbck1:
	cmp	word ptr ss:[0],'TH'	; check for valid prefix (heap & tcb)
	je	tfbck2			; ok, continue
	pop	ax
	mov	al,rctcb		; invalid tcb address
	ret
tfbck2:

; add a tfb to the tfb list, process tcb chain

	mov	dx,tfblen		; get length of block in bytes
	mov	bx,es			; save gfb pointer
	call	blkallo			; do heap allocation
	assume	es:tfb
	mov	[tfbtype],'F'		; set block type field
	mov	[tfbtcb],ss		; set owner tcb field

; clear data area

	mov	cx,tfblen		; get total length of tfb
	call	clrdata			; clear data area to 0s
	mov	[tfbgfb],bx		; set owner gfb field
	mov	si,[tcbtfbpf]		; get pointer to 1st tfb for this tcb

; trace through tfbs to find last one in tcb chain

	xor	di,di			; assume no active tfbs (setup for blkins)
	or	si,si			; are there any active tfbs for this tcb?
	jz	nocurtfb		; no currnet tfbs
	mov	di,si			; there is a minimum of one
	push	es			; save allocated tfb pointer
fltfb:
	mov	es,di			; point to next tfb in tcb chain
	assume	es:tfb
	mov	di,[tfbntcb]		; pointer to next tfb for this tcb
	or	di,di			; last one?
	jnz	fltfb			; no, find last tfb
	mov	di,es			; set last tfb pointer
	pop	es			; restore allocted tfb pointer
	assume	es:tfb
nocurtfb:
	mov	bx,di			; tell where to put in list
	call	blkins			; insert block into list of tfbs
	mov	[tcbtfbpf],si		; set new 1st tfb pointer in tcb

; add a tfb to the tfb list, process gfb chain

	push	es			; save tfb pointer
	mov	es,[tfbgfb]		; get owner gfb from tfb (set above)
	assume	es:gfb
	mov	si,[gfbtfb]		; get pointer to 1st tfb for this gfb
	mov	bx,es			; temp save pointer to gfb
	pop	es			; block tfb back
	assume	es:tfb

; trace through tfbs to find last one in gfb chain
; note: since these pointers are not in the prefix we cannot
; use blkins & blkdel, they must be set manually here.

	or	si,si			; are there any active tfbs for this gfb?
	jnz	curtfb2			; yes, add to list of current tfbs
	mov	si,es			; save new tfb pointer
	mov	es,bx			; no, set this tfb as 1st; point to owner gfb
	assume	es:gfb
	mov	[gfbtfb],si		; set new 1st tfb pointer in gfb
	mov	es,si			; return new tfb pointer to caller
	assume	es:tfb
	jmp	oktfbend		; clear data area and exit
curtfb2:
	push	ds			; save scb pointer
fltfb2:
	mov	ds,si			; point to next tfb
	assume	ds:tfb
	mov	si,ds:[tfbngfb]		; pointer to next tfb for this gfb
	or	si,si			; last one?
	jnz	fltfb2			; no, find last tfb
	mov	ds:[tfbngfb],es		; set new 'next pointer' in old last tfb
	mov	es:[tfbpgfb],ds		; set 'previous pointer' in new tfb
	mov	es:[tfbngfb],0		; set new tfb as last in list
	pop	ds			; restore scb pointer
	assume	ds:grp
oktfbend:
	pop	ax			; original ax back
	mov	al,rcsuc		; successful return code
	ret				; end of rtntfb

; delete a tfb from the tfb list, process tcb chain

rtntfbd:
	cmp	al,es:[1]		; correct block type?
	je	tfbcont			; yes, continue
	pop	ax
	mov	al,rcmtch		; block type mismatch error
	ret
tfbcont:
	push	es			; save block pointer (block to delete)
	mov	es,[tfbtcb]		; get pointer to tcb
	assume	es:tcb
	mov	si,es:[tcbtfbpf]	; get pointer to 1st tfb
	mov	di,si			; assume only tfb (setup for blkins)
fltfb3:
	mov	es,di			; point to next tfb
	assume	es:tfb
	mov	di,[tfbntcb]		; pointer to next tfb for tcb
	or	di,di			; last one?
	jnz	fltfb3			; no, find last tfb
	mov	di,es			; set last tfb pointer
	pop	es			; tfb pointer to delete
	assume	es:tfb
	call	blkdel			; remove block from list of tfbs for tcb
	push	es
	mov	es,[tfbtcb]		; get pointer to tcb
	assume	es:tcb
	mov	es:[tcbtfbpf],si	; update pointer to 1st tfb in tcb
	pop	es			; get pointer to tfb to delete
	assume	es:tfb

; now clear gfb chain (the tuff part!)

	push	es			; save tfb pointer
	mov	bx,[tfbpgfb]		; get pointer to previous tfb in gfb chain
	or	bx,bx			; is this tfb the 1st in the list?
	jz	dotfb1st		; yes, do it 1st
	cmp	[tfbngfb],0		; is this the last tfb for this gfb
	je	tfblast			; yes
	push	ds
	mov	bx,[tfbngfb]		; get pointer to next tfb
	mov	ax,[tfbpgfb]		; get pointer to next tfb
	mov	es,bx			; point to next block
	mov	ds,ax			; point to previous block
	assume	ds:tfb
	mov	ds:[tfbngfb],bx		; set new 'Next' pointer in previous tfb
	mov	es:[tfbpgfb],ax		; set new 'Previous' pointer in next block
	pop	ds
	assume	ds:grp
	jmp	tfbdend
dotfb1st:
	mov	ax,[tfbngfb]		; is this the only tfb for this gfb?
	or	ax,ax
	je	tfbonly			; yes
	mov	es,ax			; point to next tfb
	mov	[tfbpgfb],0		; set 'Previous type' field to none
	mov	es,[tfbgfb]		; get pointer to gfb
	assume	es:gfb
	mov	[gfbtfb],ax		; set new 1st tfb pointer in gfb
	jmp	tfbdend			; end delete
tfbonly:
	assume	es:tfb
	mov	es,[tfbgfb]		; get pointer to gfb
	assume	es:gfb
	mov	[gfbtfb],0		; set 1st tfb pointer to none
	jmp	tfbdend			; end of delete
tfblast:
	mov	es,bx			; point to previous tfb
	assume	es:tfb
	mov	[tfbngfb],0		; set next to none
tfbdend:
	pop	es			; restore tfb address to delete
	mov	[tfbtcb],0		; clear owner tcb field
	mov	ah,1			; deallocate block call
	call	mosheman
	or	al,al			; any errors
	jz	$+5			; no
	jmp	errheap			; yes, error with the heap
	pop	ax
	mov	al,rcsuc		; successful return code
	ret				; end rtntfb
rtntfb endp

	subttl rtngfb - add or delete a gfb
	page
;======================================================================
;,fs
; rtngfb - add or delete a gfb
;
; this routine will delete or add a gfb to the list of current gfbs.
;
; for add the gfb will be allocated from the heap, its data area
; cleared to 0s, and the scb pointers to 1st and last gfb
; (scbgfbpf, scbgfbpl) will be updated accordingly.
;
; for delete the gfb will be check for any pointers to active
; tfbs or rlbs and if found will not delete the block but return
; with an error code (the routine deleteing the gfb must delete
; all linked information first).  if no active pointers are
; found then the gfb will be deallocated from the heap and the
; scb pointers for 1st and last gfb will be updated.
;
; in:	ah = function code: 0- add, 1- delete
;	al = block id type
;	es = gfb addresss (if del)
;
; out:	al = error code, ah = error code for mosheman (if error)
;	es = gfb address (if add); or undefined on exit for delete
;	bx, cx, dx, si, di destroyed
; 
;,fe
;================================================================
	assume	ds:grp,es:nothing,ss:tcb
rtngfb proc near
	push	ax
	or	ah,ah			; is this an add block?
	jz	$+5			; yes
	jmp	rtngfbd			; no, they want delete

; add a gfb to the gfb list

	mov	dx,gfblen		; get length of block in bytes
	call	blkallo			; do heap allocation
	assume	es:gfb
	mov	[gfbtype],'G'		; set block type field
	mov	si,[scbgfbpf]		; get scb pointer to 1st gfb
	mov	di,[scbgfbpl]		; get scb pointer to last gfb
	mov	bx,di			; put new gfb at end of list
	call	blkins			; insert block into list
	mov	[scbgfbpf],si		; set scb pointer to 1st gfb
	mov	[scbgfbpl],di		; set scb pointer to last gfb

; clear data area of gfb to 0's

	mov	cx,gfblen		; get total length of block
	call	clrdata			; clear data area to 0s
	call	setsft			; set sft (uses bx set before blkins)
	pop	ax
	mov	al,rcsuc		; successful return code
	ret				; end of rtngfb

; delete a gfb from the gfb list

rtngfbd:
	cmp	al,es:[1]		; correct block type?
	je	gfbcont			; yes, continue
	pop	ax
	mov	al,rcmtch		; block type mismatch error
	ret
gfbcont:
	cmp	[gfbtfb],0		; any active tfbs?
	jne	egfbtfb			; yes, cannot delete block
	cmp	[gfbrlb],0		; any active rlbs?
	jne	egfbrlb			; yes, cannot delete block
	jmp	delgfbok		; ok to delete
egfbtfb:
	pop	ax			; restore original ax
	mov	al,rctfb		; active tfbs error code
	ret
egfbrlb:
	pop	ax			; restore original ax
	mov	al,rcrlb		; active rlbs error code
	ret
delgfbok:
	call	clrsft			; clear the sft entry
	mov	si,[scbgfbpf]
	mov	di,[scbgfbpl]
	call	blkdel			; remove block from list of gfbs
	mov	[scbgfbpf],si		; set scb pointer to 1st gfb
	mov	[scbgfbpl],di		; set scb pointer to last gfb
	mov	ah,1			; deallocate block call
	call	mosheman
	or	al,al			; any errors
	jz	$+5			; no
	jmp	errheap			; yes, error with the heap
	pop	ax
	mov	al,rcsuc		; successful return code
	ret				; end rtngfb
rtngfb endp

	subttl setsft - maintain links for sft chain 
	page
;======================================================================
;,fs
; setsft - maintain links for sft chain 
;
; the following routine sets the sft link in gfb so that applications
; that use function 52h can trace down sfts (inside our gfbs) to get
; file information.
;
; in:	bx --> gfb at end of list
;
; out:	
; 
;,fe
;================================================================
	assume	ds:grp,es:gfb,ss:tcb
setsft proc near
	push	ax
	mov	ax,[scbgfbpf]
	cmp	ax,[scbgfbpl]
	pop	ax
	je	ss1			; first link?

; in this case we added the entry to end of chain and there for we most
; set prevous entry to us and ourselves to terminates (as in first entry)

	push	ax
	push	es
	mov	ax,es			; save segment of gfb to add
	mov	es,bx			; get prevous gfb
	mov	word ptr [gfbnsft], offset gfbnsft
	mov	word ptr [gfbnsft+2],ax	; set segment to new gfb
	pop	es
	pop	ax

; this is first gfb so we must set sft next entry to terminator

ss1:
	push	ds
	mov	ds,[scbtcbpc]
	assume  ds:tcb
	mov	word ptr [gfbnsft], -1	; set to -1 for proper sft
	mov	word ptr [gfbnsft+2],-1	; tracing - mft.exe
	mov	word ptr [gfbnfile],1
	mov	word ptr [gfbcnt],1
	pop	ds
	assume  ds:grp
	ret
setsft endp

	subttl clrsft - maintain links for sft chain 
	page
;======================================================================
;,fs
; clrsft - maintain links for sft chain 
;
; this routine removes a sft entry from list
;
; in:	
;
; out:	
; 
;,fe
;================================================================
	assume	ds:grp,es:gfb,ss:tcb
clrsft proc near
	push	ax
	mov	ax,es
	cmp	ax,[scbgfbpf]
	pop	ax
	je	cs1			; is it first entry on list?

; must set prevous sft entry to sft entry pointed by one to delete

	push	ax
	push	bx
	push	es
	mov	ax,word ptr [gfbnsft]
	mov	bx,word ptr [gfbnsft+2]
	cmp	word ptr [gfbprev],0	; end of list
	je	csskip			; then don't update sft pointers
	mov	es,[gfbprev]
	mov	word ptr [gfbnsft],ax
	mov	word ptr [gfbnsft+2],bx
csskip:
	pop	es
	pop	bx
	pop	ax
	ret
cs1:

; this is hard part because we nolonger have route gfb (sft) on system
; and must change all tcbsft pointers to next sft on list
; this should not be a problem becuase aux appears to be always the
; first device.  future: scan tcb and change tcbnsft to new sft entry

	ret
clrsft endp

	subttl rtncdb - add or delete a cdb
	page
;======================================================================
;,fs
; rtncdb - add or delete a cdb
;
; this routine will add or delete a 'Current Directory Block'
; (cdb) to a list of cdbs for a specified tcb.
;
; for adds the space for the block will be allocated from the
; heap, the block will be added to the list of cdbs for the
; specified tcb if one exists, else one will be started and the
; the cdb block is appended to the end of the cdb list.
;
; for deletes the space for the block will be deallocated from
; the heap, the block will be deleted from the list of cdbs for
; the specified tcb.
;
; in:	ah = function code: 0- add, 1- delete
;	al = block id type
;	ss = owner tcb address (if add)
;	es = cdb addresss (if del)
;
; out:	al = error code, ah = error code for mosheman (if error)
;	es = address of cdb (if add); or undefined on exit for delete
;	bx, dx, si, di, and ds destroyed
; 
;,fe
;================================================================
	assume	ds:grp,es:nothing,ss:tcb
rtncdb proc near
	push	ax
	or	ah,ah			; is this an add block?
	jz	$+5			; yes
	jmp	rtncdbd			; no, they want delete

; check for valid tcb owner address

	cmp	word ptr ss:[0],'TH'	; check for valid prefix (heap & tcb)
	je	cdbck2			; ok, continue
	pop	ax
	mov	al,rctcb		; invalid tcb address
	ret
cdbck2:

; add a cdb to the cdb list

	mov	dx,cdblen		; get length of block in bytes
	call	blkallo			; do heap allocation
	assume	es:cdb
	mov	[cdbtype],'C'		; set block type field
	mov	[cdbtcb],ss		; set owner tcb field
	mov	si,[tcbcdbpf]		; get tcbs pointer to 1st cdb

; trace through cdbs to find last one

	xor	di,di			; assume no active cdbs (setup for blkins)
	or	si,si			; are there any active cdbs for this tcb?
	jz	nocurcdb		; no currnet cdbs
	mov	di,si			; there is a minimum of one
	push	es			; save
flcdb:
	mov	es,di			; point to next cdb
	assume	es:cdb
	mov	di,[cdbnext]		; pointer to next cdb for tcb
	or	di,di			; last one?
	jnz	flcdb			; no, find last rlb
	mov	di,es			; set last cdb pointer
	pop	es
nocurcdb:
	mov	bx,di			; put new cdb at end of list
	call	blkins			; insert block into list of cdbs
	mov	[tcbcdbpf],si		; set new 1st rlb pointer in gfb
	pop	ax
	mov	al,rcsuc		; successful return code
	mov	cx,cdblen		; clear block
	call	clrdata			; clear data area to 0s
	ret				; end of rtncdb

; delete a cdb from the cdb list

rtncdbd:
	cmp	al,es:[1]		; correct block type?
	je	cdbcont			; yes, continue
	pop	ax
	mov	al,rcmtch		; block type mismatch error
	ret
cdbcont:
	push	es			; save block pointer (block to delete)
	assume	es:cdb
	mov	es,[cdbtcb]		; get pointer to tcb
	assume	es:tcb,ss:nothing
	mov	si,[tcbcdbpf]		; get pointer to 1st cdb
	mov	di,si			; assume only cdb (setup for blkins)
flcdb2:
	mov	es,di			; point to next cdb
	assume	es:cdb
	mov	di,[cdbnext]		; pointer to next cdb for tcb
	or	di,di			; last one?
	jnz	flcdb2			; no, find last cdb
	mov	di,es			; set last cdb pointer
	pop	es			; block pointer back
	push	es
	call	blkdel			; remove block from list of cdbs
	mov	es,[cdbtcb]		; get pointer to tcb
	assume	es:tcb,ss:nothing
	mov	[tcbcdbpf],si		; update new pointer to 1st cdb in tcb
	pop	es			; get pointer to block to deallocate
	assume	es:cdb
	mov	[cdbtcb],0		; clear owner tcb field
	mov	ah,1			; deallocate block call
	call	mosheman
	or	al,al			; any errors
	jz	$+5			; no
	jmp	errheap			; yes, error with the heap
	pop	ax
	mov	al,rcsuc		; successful return code
	ret				; end rtncdb
rtncdb endp

	subttl rtnbdb - add or delete a bdb
	page
;======================================================================
;,fs
; rtnbdb - add or delete a bdb
;
; this routine will add or delete a 'Block Device Block' (bdb)
; the bdb will be allocated or deallocated from the heap and the
; scb pointers to 1st and last bdb (scbbdbpf, scbbdbpl) will be
; updated accordingly.
;
; in:	ah = function code: 0- add, 1- delete
;	al = block id type
;	es = bdb addresss (if del)
;
; out:	al = error code, ah = error code for mosheman (if error)
;	es = bdb address (if add); undefined on exit for delete
;	bx, cx, dx, si, di, and ds destroyed
; 
;,fe
;================================================================
	assume	ds:grp,es:nothing,ss:tcb
rtnbdb proc near
	push	ax
	or	ah,ah			; is this an add block?
	jz	$+5			; yes
	jmp	rtnbdbd			; no, they want delete

; add a bdb to the bdb list

	mov	dx,bdblen		; get length of block in bytes
	call	blkallo			; do heap allocation
	assume	es:bdb
	mov	[bdbtype],'B'		; set block type field
	mov	si,[scbbdbpf]		; get scb pointer to 1st bdb
	mov	di,[scbbdbpl]		; get scb pointer to last bdb
	mov	bx,di			; put new bdb at end of list
	call	blkins			; insert block into list
	mov	[scbbdbpf],si		; set scb pointer to 1st bdb
	mov	[scbbdbpl],di		; set scb pointer to last bdb
	mov	cx,bdblen		; get total length of block
	call	clrdata			; clear data area to 0s

; set dpb next pointer.

	push	ds
	mov	cx,[bdbprev]
	jcxz	bdb10			; if no previous block
	mov	ds,cx
	assume	ds:bdb,es:nothing
	mov	word ptr [bdbdpbpn],offset bdbdpb
	mov	word ptr [bdbdpbpn+2],es; set next pointer for prev
	assume	ds:nothing,es:bdb
bdb10:
	mov	cx,[bdbnext]
	jcxz	bdb20			; if no next block
	mov	word ptr [bdbdpbpn],offset bdbdpb
	mov	word ptr [bdbdpbpn+2],cx; set next pointer for new
	jmp	short bdb30
bdb20:
	mov	ax,-1			; end of chain
	mov	word ptr [bdbdpbpn],ax
	mov	word ptr [bdbdpbpn+2],ax
bdb30:
	pop	ds
	assume	ds:grp
	pop	ax
	mov	al,rcsuc		; successful return code
	ret				; end of rtnrlb

; delete a bdb from the bdb list

rtnbdbd:
	cmp	al,es:[1]		; correct block type?
	je	bdbcont			; yes, continue
	pop	ax
	mov	al,rcmtch		; block type mismatch error
	ret
bdbcont:
	mov	si,[scbbdbpf]		; get current scb pointer to 1st bdb
	mov	di,[scbbdbpl]		; "	"	"	" to last bdb
	call	blkdel			; remove block from list of bdbs
	mov	[scbbdbpf],si		; set scb pointer to 1st bdb
	mov	[scbbdbpl],di		; "	"	" to last BDB

; set dpb next pointer of previous block.

	push	ds
	mov	cx,[bdbprev]
	jcxz	bdb50			; if no previous block
	mov	ds,cx
	mov	cx,[bdbnext]		; pointer to next block
	assume	ds:bdb,es:nothing
	jcxz	bdb40			; if no next block
	mov	word ptr [bdbdpbpn],offset bdbdpb
	mov	word ptr [bdbdpbpn+2],cx; set next pointer for prev
	jmp	short bdb50
bdb40:
	mov	ax,-1			; end of chain
	mov	word ptr [bdbdpbpn],ax
	mov	word ptr [bdbdpbpn+2],ax
bdb50:
	pop	ds
	assume	ds:grp,es:bdb
	mov	ah,1			; deallocate block call
	call	mosheman
	or	al,al			; any errors
	jz	$+5			; no
	jmp	errheap			; yes, error with the heap
	pop	ax
	mov	al,rcsuc		; successful return code
	ret				; end rtnbdb
rtnbdb endp

	subttl rtnrlb - add or delete a rlb
	page
;======================================================================
;,fs
; rtnrlb - add or delete a rlb
;
; this routine will add or delete a 'Record Lock Block' (rlb).
;
; for adds the space for the block will be allocated from the
; heap, the block will be added to the list of rlbs for the
; specified gfb if one exists, else one will be started and the
; gfb data field 'GFBRLB' will be updated.  the rlb block is
; inserted at the beginning of the rlb list.
;
; for deletes the space for the block will be deallocated from
; the heap, the block will be deleted from the list of rlbs for
; the specified gfb , and the gfb data field 'GFBRLB' will be
; updated.
;
; in:	ah = function code: 0- add, 1- delete
;	al = block id type
;	ss = owner tcb address (if add)
;	es = owner gfb address (if add), else block addresss (if del)
;
; out:	al = error code, ah = error code for mosheman (if error)
;	es = rlb address (if add); undefined on exit for delete
;	bx, dx, si, di, and ds destroyed
; 
;,fe
;================================================================
	assume	ds:grp,es:nothing,ss:tcb
rtnrlb proc near
	push	ax
	or	ah,ah			; is this an add block?
	jz	$+5			; yes
	jmp	rtnrlbd			; no, they want delete

; check for valid owner tcb and gfb

	cmp	es:[0],'GH'		; check for valid prefix (heap & gfb)
	je	rlbck1			; ok, check tcb
	pop	ax
	mov	al,rcgfb		; invalid gfb address
	ret
rlbck1:
	cmp	ss:[0],'TH'		; check for valid prefix (heap & tcb)
	je	rlbck2			; ok, continue
	pop	ax
	mov	al,rctcb		; invalid tcb address
	ret
rlbck2:

; add a rlb to the rlb list

	mov	dx,rlblen		; get length of block in bytes
	mov	bx,es			; save gfb pointer
	call	blkallo			; get heap space for block
	assume	es:rlb
	mov	cx,rlblen
	call	clrdata			; clear data area to 0s
	mov	[rlbtype],'R'		; set block type field
	mov	[rlbtcb],ss		; set owner tcb field
	mov	[rlbgfb],bx		; set gfb pointer field
	push	es			; save rlb pointer
	mov	es,bx			; restore gfb pointer
	assume	es:gfb
	mov	si,[gfbrlb]		; get gfbs pointer to 1st rlb

; trace through rlbs to find last one

	xor	di,di			; assume no active rlbs (setup for blkins)
	or	si,si			; are there any active rlbs for this tcb?
	jz	nocurrlb		; no currnet rlbs
	mov	di,si			; there is a minimum of one
flrlb:
	mov	es,di			; point to next rlb
	assume	es:rlb
	mov	di,[rlbngfb]		; pointer to next rlb for gfb
	or	di,di			; last one?
	jnz	flrlb			; no, find last rlb
	mov	di,es			; set last rlb pointer
nocurrlb:
	mov	ax,bx			; save gfb pointer
	pop	es			; restore new rlb pointer
	assume	es:rlb
	xor	bx,bx			; insert 1st ####### may change later
	call	blkins			; insert block into list of rlbs
	mov	bx,es			; save rlb pointer
	mov	es,ax			; address gfb
	assume	es:gfb
	mov	[gfbrlb],si		; set new 1st rlb pointer in gfb
	mov	es,bx			; address new rlb
	assume	es:rlb
	pop	ax
	mov	al,rcsuc		; successful return code
	ret				; end of rtnrlb
	assume	ds:grp

; delete an rlb from the rlb list

rtnrlbd:
	cmp	al,es:[1]		; correct block type?
	je	rlbcont			; yes, continue
	pop	ax
	mov	al,rcmtch		; block type mismatch error
	ret
rlbcont:
	push	es			; save block pointer (block to delete)
	mov	es,[rlbgfb]		; get pointer to gfb
	assume	es:gfb
	mov	si,[gfbrlb]		; get pointer to 1st rlb
	mov	di,si			; assume only rlb (setup for blkins)
flrlb2:
	mov	es,di			; point to next rlb
	assume	es:rlb
	mov	di,[rlbngfb]		; pointer to next rlb for gfb
	or	di,di			; last one?
	jnz	flrlb2			; no, find last rlb
	mov	di,es			; set last rlb pointer
	pop	es			; block pointer back
	push	es
	call	blkdel			; remove block from list of rlbs
	mov	es,[rlbgfb]		; get pointer to gfb
	assume	es:gfb
	mov	[gfbrlb],si		; update new pointer to 1st rlb in gfb
	pop	es			; get pointer to block to deallocate
	assume	es:rlb
	mov	ah,1			; deallocate block call
	mov	[rlbtcb],0		; clear owner tcb field
	call	mosheman
	or	al,al			; any errors
	jz	$+5			; no
	jmp	errheap			; yes, error with the heap
	pop	ax
	mov	al,rcsuc		; successful return code
	ret				; end rtnrlb
errheap:
	pop	bx			; discard original ax
	xchg	al,ah			; put mosheman return code in ah
	mov	al,rchperr		; 'Heap error' code
	ret
rtnrlb endp

	subttl blkallo - block allocation
	page
;======================================================================
;,fs
; blkallo - block allocation
;
; this small routine will calculate the amount of heap size
; needed for a block and call mosheman to allocate it.  if an
; error occurs then the call to this subroutine will be discarded
; and control will be returned to the entry routine through
; 'errheap'.
;
; in:	dx = # bytes of storage needed.
;
; out:	es = address of block on heap
;	dx = # paragraphs allocated
;	ax is destroyed
; 
;,fe
;================================================================
	assume	ds:nothing,es:nothing,ss:tcb
blkallo proc near
	add	dx,0fh			; round up to next segment value
	shr	dx,1			; calc segment size for heap allocation
	shr	dx,1
	shr	dx,1
	shr	dx,1
	xor	ah,ah			; allocate block on heap
	call	mosheman
	or	al,al			; any errors?
	jnz	$+3			; none
	ret				; end sub
	pop	bx			; clear call from stack
	jmp	errheap			; yes, error in heap allocation
blkallo endp

	subttl clrdata
	page
;======================================================================
;,fs
; clrdata
;
; clear area at es:0+10h of length cx (rounded to seg) to 0's
;
; in:	
;
; out:	
; 
;,fe
;================================================================
	assume	ds:nothing,es:nothing,ss:tcb
clrdata proc near
	push	ax
	sub	cx,10h			; not including prefix
	add	cx,0fh			; round up to next seg
	and	cx,0fff0h
	xor	al,al
	cld
	mov	di,10h			; point to start of data area
	rep	stosb
	pop	ax
	ret
clrdata endp

	subttl blkins - block insert routine
	page
;======================================================================
;,fs
; blkins - block insert routine
;
; this routine will insert a specified block into a linked list
; of blocks and update all prefix pointers.  this routine is
; general purpose and is intended to be used for tcbs, bdbs, gfbs
; and all the other bs that are used.
;
; in:	es = segment address of block to insert
;	bx = segment address of present block to insert after, if 0
;	     then make block 1st in list.
;	si = pointer to 1st block in list (i.g. scbtcbpf)
;	di = pointer to last block in list (i.g. scbtcbpl)
;
; out:	si and di may contain updated pointers if the first and/or last
;	blocks where changed.
; 
;,fe
;================================================================
	assume	ds:nothing,es:nothing,ss:tcb
blkins proc near
	push	ds
	push	bx
	push	ax
	or	si,si			; is there a 1st block now?
	jnz	$+5
	jmp	setonly			; no, this is the only block
	or	bx,bx			; should inserted block be first in list?
	jz	bifirst			; yes, put it 1st
	mov	ds,bx			; point to block to insert after
	mov	es:[0ah],bx		; set 'Previous type' in newly inserted block
	mov	bx,ds:[08h]		; get old 'Next type' from before block
	mov	es:[08h],bx		; set in newly inserted block
	mov	ax,es			; pointer to new block
	mov	ds:[08h],ax		; set new 'Next type' in old block
	or	bx,bx			; is the new block the last block?
	jnz	nolast			; no
	mov	di,ax			; set new 'Last Pointer' for return
	jmp	blkexit
nolast:
	mov	ds,bx			; point to next (insert before this)
	mov	ds:[0ah],ax		; set 'Previous type'
	jmp	blkexit
bifirst:
	mov	word ptr es:[0ah],0	; set 'previous type' to none
	mov	es:[08h],si		; set 'next type' to old 1st
	mov	ds,si			; point to old 1st block
	mov	ax,es			; get pointer to new 1st block
	mov	ds:[0ah],ax		; set 'previous type' to new 1st block
	mov	si,es			; set new 'Pointer First' for return
	jmp	blkexit
setonly:
	mov	word ptr es:[08h],0	; set 'next type' to none
	mov	word ptr es:[0ah],0	; set 'previous type' to none
	mov	si,es			; set 'Pointer First'
	mov	di,si			; set 'Pointer Last'
blkexit:
	pop	ax
	pop	bx
	pop	ds
	ret				; end of blkins
blkins endp

	subttl blkdel - block delete routine
	page
;======================================================================
;,fs
; blkdel - block delete routine
;
; this routine will delete a specified block from a linked list
; of blocks and update all necessary pointers.  this routine is
; general purpose and is intended to be used for tcbs, bdbs, gfbs
; and all the other bs that are used.
;
; in:	es = segment address of block to delete
;	si = pointer to 1st block in list (i.g. scbtcbpf)
;	di = pointer to last block in list (i.g. scbtcbpl)
;
; out:	si and di may contain updated pointers if the first and/or last
;	blocks where changed.
; 
;,fe
;================================================================
	assume	ds:nothing,es:nothing,ss:tcb
blkdel proc near
	push	ax
	push	bx
	push	ds
	push	es
	mov	bx,es			; pointer to block to delete
	cmp	bx,si			; is it first block of this type
	je	delfrst			; yes
	cmp	bx,di			; is it last block of this type
	je	dellast			; yes
	mov	bx,es:[08h]		; get 'Next' pointer
	mov	ax,es:[0ah]		; get 'Previous' pointer
	mov	es,bx			; point to next block
	mov	ds,ax			; point to previous block
	mov	ds:[08h],bx		; set new 'Next' pointer in previous block
	mov	es:[0ah],ax		; set new 'Previous' pointer in next block
delend:
	pop	es			; restore segment of deleted block
	mov	word ptr es:[08h],0	; clear 'Next' pointer field
	mov	word ptr es:[0ah],0	; clear 'Previous' pointer field
	pop	ds
	pop	bx
	pop	ax
	ret
delfrst:
	cmp	bx,di			; is this the only block?
	je	delonly			; yes
	mov	ax,es:[08h]		; get pointer to next block
	mov	es,ax			; point to it
	mov	word ptr es:[0ah],0	; set 'Previous type' field to none
	mov	si,ax			; set new 'First Pointer' for return
	jmp	delend
delonly:
	xor	si,si			; set as no 1st or last
	xor	di,di
	jmp	delend
dellast:
	mov	ax,es:[0ah]		; get pointer to previous block
	mov	es,ax			; point to that block
	mov	word ptr es:[08h],0	; set 'Next type' field to none
	mov	di,ax			; set new 'Last Pointer' for return
	jmp	delend

blkdel endp

mosseg	ends
	end

