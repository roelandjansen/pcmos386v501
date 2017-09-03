	include page.inc
	title	mosint13 - disk dma management
comment ^===============================================================
		development specification

 program name:	mos.com 		assigned to: david morrow
 module name:	mosint13		assign date: 08/12/86
 entry points:	mosint13		completed: 08/16/86
 entry from:	disk drivers (or who ever)
 entry method:	int 13
 calls:	n/a
 purpose:	to prevent dma conflicts before they cause a disk error
 refer to:	n/a
 last update:	08/18/1992
========================================================================

dam 10/21/86	fixed bug involved with gizdrive staging

rbr 08/05/87	also assume fixed disks use dma

rbr 08/15/87	fixed bug with errors not returning carry set

sah 01/20/88	change scbseg and zero access to mgetxxxx macros

sah 01/22/88 	remove references to scbseg

rbr/sah 02/20/88 move ddt code to mo2 group.

sah - 07/19/88	made int13in public so it can be access else where

sah - 08/29/88	maintain status of chainline so that our internal
		media check routine  can know status correctly.

bwr 11/17/89	proc mosint13 incorrectly clearing bx register instead
		of bh register when forming table index.  result was
		forcing index to beginning of table regardless of
		index.

sah 01/25/90	added calls to wordmove for faster dma transfers on
		i386\i486.

mjs 03/07/90	incorporated regrab logic for the int13 vector.  we
		always need to get control first for the disk busy
		task switching feature to be stable.  this is necessary
		so we can prevent anyone's int13 replacement from being
		re-entered (providing they issue int15's).

mjs 03/22/90	modified the int13 regrab logic so its inactive 
		when disksw=n is used.
		fixed bug in regrab pass-on logic.

mjs 03/27/90	mod to save, clear and restore trapping for p40, p42,
		p43 and p61 around call to original bios.

mjs 09/16/90	modify to preserve ds register when calling the 
		original int13 bios.  passport needed this.

SAH 10/11/90	modified to clear and restore trapping for p60 and p64
		around call to original bios.

mjs 10/29/90	change bio13 so it doesn't use a pop sp, not compatible
		with 8088 machines.
		add normalize function to correct int13 dma conflict
		resolution when a large # of sectors is being read
		or written in one call (passport).

mjs 11/05/90	corrections to normalize logic

mjs 12/11/90	further corrections to normalize logic.  int13fun08 is
		not supported for diskettes on all machines.  for
		diskette operations, normalize now presumes that just
		adding the # of sectors just read or written to the
		starting sector number will be ok (e.g. no advancement
		of the head or cyl # will be required).

mjs 12/26/90	complete re-write of the mosint13 main logic.  cleared
		up problems dealing with es:bx normalization and 
		converted address calculations for eventual operation
		in 16 bit protected mode.

SAH 02/08/91	Move call INT 13 func 08, to aboved calling calc_pieces
		this is prevent the divide by 0 error because first read off
		of hard disk will causing it to skip logic to set  maxhead
		and maxsect causing advance_sect to cause a divide by
		zero error because maxhead and maxsect are not set.   Shipping
		4.10 will not experience the problems found.

SAH 03/20/91	Use SCBIOPTR for accessing IO protection table 

mjs 12/19/91	corrected problems in dma staging logic
		can't defer staging to memdev just because a remapping
		memdev exists.  dmabank might not be set below its
		initial value of a0.  also, made the processing of the
		middle section of a read or write use an int13 call
		so the memdev could do its remapping adjustments.

================ 5.01 Kernel Ends Here ====================================

mjs 08/18/92	clean up segment declarations

mjs 08/26/92	delete reference to scbfree

=======================================================================^

.xlist
;	public	mosint13	; need one or the other of these lines
	include	mosint13.pub	; need one or the other of these lines
	include group.inc
	include mosregs.inc
	include	macros.inc

tcb	segment at 1234h
	include mostcb.inc
tcb	ends

gdata	segment
	include mosscbex.inc
gdata	ends
.list

gdata	segment

dma13ax dw	0		;\
dma13bx dw	0		; \
dma13cx dw	0		;  > save space
dma13dx dw	0		; /
dma13es dw	0		;/
maxhead	db	0
maxsect	db	0
bps	dw	512
p1	dd	0
p2	dd	0
p3	dd	0
pc	dd	0
b1	dw	0
b2	dw	0
b3	dw	0

	public	media13
media13  db	4 dup ('N')	; flags to indicate if media as change

	public	ourbuf		; the hard disk driver uses this in init
ourbuf	db	512 dup(0)	; buffer space for disk sector (temporary)

gdata	ends

irq	segment
	extrn	irqstart:byte, irqend:byte

	dw	13h*4			; offset for int 13
oint13	dd	?			; save old one here
	dw	0			; leave any changes
	dw	mos:regr13pri		; inital value (only entry point)
	dw	0			; no secondary entry point

irq	ends

;======================================================== ddt segment
if 0 eq 0
segment_num = 2
endif
ddt	segment
	extrn	cmap:near
ddt	ends

;======================================================== mos segment
if 0 eq 0
segment_num = 1
endif
mosseg	segment
	assume	cs:mos,ds:grp,es:nothing,ss:tcb
	extrn	mosend:byte, sbios:word

	extrn	wordmove:near, suspend:near

biosseg  dw	0040h		; constant for access bios data segment

comment ^

pseudo code for mosint13 processing 
produced 12/26/90

ÚÄ mosint13
³ÚÄ if(remapping_memdev || ah < 2 || ah > 3)
³³ pass on to previous vector
³ÃÄ else
³³ save entry regs to memory vars
³³ call chk_bound to determine if a dma boundary crossing will occur
³³ÚÄ if(high word of [pc] == 0)
³³³ pass on to previous vector
³³ÃÄ else
³³³ call calc_pieces to derive addresses and data block sizes
³³³ÚÄ if([b1] != 0)			; process 1st section
³³³³ es:bx = entry es:bx
³³³³ set al from b1
³³³³ set ah, cx and dx from memory vars  
³³³³ call int13 for [b1] sectors
³³³³ÚÄ if(carry flag)
³³³³³ save ax in mem var
³³³³³ exit
³³³³ÀÄ  
³³³³ÚÄ if(dl > 80h)
³³³³³ call int13fun08
³³³³³ mov [maxhead],dh
³³³³³ mov bl,cl
³³³³³ and bl,03fh			; max sct # in bl (1 based)
³³³³³ mov [maxsect],bl
³³³³³ mov bh,dh
³³³³³ set al, cx and dx from memory vars
³³³³³ call advance_sect
³³³³³ update memory vars for cx and dx
³³³³ÃÄ else
³³³³³ sect += [b1]
³³³³ÀÄ  
³³³ÀÄ 
³³³ÚÄ if([b2] != 0)			; process 2nd section
³³³³ es:bx = abs2nso of [p2]
³³³³ push bx
³³³³ push es
³³³³ÚÄ if(a write operation)
³³³³³ copy entry es:bx data to local buffer
³³³³ÀÄ  
³³³³ make es:bx -> local buffer
³³³³ set al from b2
³³³³ set ah, cx and dx from memory vars  
³³³³ call int13 for [b2] sectors
³³³³ pop es
³³³³ pop bx
³³³³ÚÄ if(carry flag)
³³³³³ call del_desc for es
³³³³³ save ax in mem var
³³³³³ exit
³³³³ÀÄ  
³³³³ÚÄ if(a read operation)
³³³³³ copy local buffer data to entry es:bx
³³³³ÀÄ  
³³³³ÚÄ if(dl > 80h)
³³³³³ mov bl,[maxsect]
³³³³³ mov bh,[maxhead]
³³³³³ set al, cx and dx from memory vars
³³³³³ call advance_sect
³³³³³ update memory vars for cx and dx
³³³³ÃÄ else
³³³³³ sect += [b2]
³³³³ÀÄ  
³³³³ call del_desc for es
³³³ÀÄ 
³³³ÚÄ if([b3] != 0)			; process 3rd section
³³³³ es:bx = abs2nso of [p3]
³³³³ set al from b3
³³³³ set ah, cx and dx from memory vars  
³³³³ call int13 for [b3] sectors
³³³³ pushf
³³³³ call del_desc for es
³³³³ popf
³³³³ÚÄ if(carry flag)
³³³³³ exit
³³³³ÀÄ  
³³³ÀÄ 
³³ÀÄ 
³ÀÄ 
³ {exit point}
³ set exit regs from memory vars
³ ret
ÀÄ 

^


	subttl	mosint13 - interrupt 13h handler
	page
;======================================================================
;.fs
; mosint13 - interrupt 13h handler
; 
; this routine will resolve any int 13h dma conflicts by loading the
; conflicting sector into a temporary sector and then moving the
; information to the 'real' buffer.
; 
; in:	int13 entry parms
; 
; out:	int13 exit parms
; 
;.fe
;====================================================================
	assume	ds:nothing,es:nothing
mosint13:
	sti
	push	ds
	mov	ds,[biosseg]		; access bios
	cmp	byte ptr ds:[0041h],06h
	mgetscb ds
	assume	ds:grp
	jne	int13msk
	cmp	dl,03h			; higher than what we handle
	ja	int13msk
	push	bx
	mov	bl,dl
	xor	bh,bh
	mov	byte ptr [media13+bx],'Y'
	pop	bx
int13msk:
	cmp	[scb13sk1],0
	jne	i13pass
	cmp	ah,2
	je	i13nopass		; pass-on all calls except 2 & 3
	cmp	ah,3
	je	i13nopass
i13pass:
	pop	ds
	assume	ds:nothing		; passport needs entry ds passed
	call	orig13			; on to rom bios int13
	ret
i13nopass:
	assume	ds:grp
	mov	[dma13ax],ax		; save function and sector count
	mov	[dma13cx],cx		; save track and sector #
	mov	[dma13dx],dx		; save drive and head
	mov	[dma13bx],bx		; save buffer address
	mov	[dma13es],es		; "     "	"
	call	chk_bound
	cmp	word ptr [pc+2],0
	je	i13pass
	call	calc_pieces		; determine startin points and
	cmp	byte ptr [dma13dx],80h
	jb	i13skip8
	push	bx
	push	cx
	push	dx
	mov	ah,8
	pushf
	call	[oint13]		; get max head and spt for fixed disk
	inc	dh
	mov	[maxhead],dh
	and	cl,03fh			; max sct # in cl (1 based)
	mov	[maxsect],cl
	pop	dx
	pop	cx
	pop	bx
i13skip8:
	mov	ax,[b1]			; lengths of the pieces
	or	ax,ax
	jz	i13b1x			; is there a 1st section?

; process 1st section - for any sectors before the point of conflict

	mov	ah,byte ptr [dma13ax+1]	; fetch command byte
	call	orig13
	jc	i13b1b
	cmp	byte ptr [dma13dx],80h
	jb	i13b1a
	mov	bl,[maxsect]
	mov	bh,[maxhead]
	mov	al,byte ptr [b1]
	mov	cx,[dma13cx]
	mov	dx,[dma13dx]		; calc new cyl, head and starting
	call	advance_sect		; sector for a fixed disk
	mov	[dma13cx],cx
	mov	[dma13dx],dx
	jmp	short i13b1x
i13b1b:
	mov	[dma13ax],ax		; prep for error exit
	jmp	i13x
i13b1a:
	mov	al,byte ptr [b1]	; simple sector advance for
	add	byte ptr [dma13cx],al	; diskettes
i13b1x:
	mov	ax,[b2]
	or	ax,ax
	ljz	i13b2x			; is there a 2nd section?
	
; process 2nd section - for a sector which will incur a dma
; boundary somewhere within its buffer

	push	ax
	mov	ax,word ptr [p2]
	mov	dx,word ptr [p2+2]
	call	abs2nso			; create a normalized seg/sel:ofs
	pop	ax			; in es:bx from [p2]
	push	bx
	push	es
	mov	ah,byte ptr [dma13ax+1]	; fetch command byte
	cmp	ah,3
	jne	i13b2a

; for a write operation, copy the sector at es:bx to local buffer 

	pushset	si,di
	mov	cx,ds
	mov	di,es
	mov	es,cx
	mov	ds,di
	assume	ds:nothing,es:grp
	mov	di,offset grp:ourbuf	; buffer for staging
	mov	si,bx
	mov	cx,[bps]
	shr	cx,1
	cld
	call	wordmove		; faster tranfer on i386\i486
	mov	cx,ds
	mov	di,es
	mov	es,cx
	mov	ds,di
	assume	ds:grp,es:nothing
	popset	si,di
i13b2a:
	mov	bx,ds
	mov	es,bx
	mov	bx,offset grp:ourbuf
	mov	cx,[dma13cx]
	mov	dx,[dma13dx]
	mov	[scb13sk1],1
	call	orig13
	mov	[scb13sk1],0
	pop	es
	pop	bx
	jc	i13b2b
	mov	ah,byte ptr [dma13ax+1]	; fetch command byte
	cmp	ah,2
	jne	i13b2c

; for a read operation, copy sector in local buffer to es:bx

	pushset	si,di
	mov	si,offset grp:ourbuf	; buffer for staging
	mov	di,bx
	mov	cx,[bps]
	shr	cx,1
	cld
	call	wordmove		; faster tranfer on i386\i486
	popset	si,di
i13b2c:
	cmp	byte ptr [dma13dx],80h
	jb	i13b2d
	mov	bl,[maxsect]
	mov	bh,[maxhead]
	mov	al,byte ptr [b2]
	mov	cx,[dma13cx]
	mov	dx,[dma13dx]		; calc new cyl, head and starting
	call	advance_sect		; sector for a fixed disk
	mov	[dma13cx],cx
	mov	[dma13dx],dx
	jmp	short i13b2w
i13b2b:
	call	del_desc
	mov	[dma13ax],ax		; prep for error exit
	stc
	jmp	i13x
i13b2d:
	mov	al,byte ptr [b2]	; simple sector advance for
	add	byte ptr [dma13cx],al	; diskettes
i13b2w:
	call	del_desc
i13b2x:
	mov	ax,[b3]
	or	ax,ax
	jnz	i13b3a			; is there a 3rd section?
	mov	[dma13ax],ax
	jmp	short i13x
i13b3a:
	
; process 3rd section - for any sectors after the point of conflict

	push	ax
	mov	ax,word ptr [p3]
	mov	dx,word ptr [p3+2]
	call	abs2nso
	pop	ax
	mov	ah,byte ptr [dma13ax+1]	; fetch command code
	mov	cx,[dma13cx]
	mov	dx,[dma13dx]
	call	orig13
	mov	[dma13ax],ax
	pushf
	call	del_desc
	popf
i13x:

; at this point, need flags set for exit and status in ah of [dma13ax]
	
	mov	ax,[dma13ax]
	mov	bx,[dma13bx]
	mov	cx,[dma13cx]
	mov	dx,[dma13dx]
	mov	es,[dma13es]
	pop	ds
	assume	ds:nothing
	ret				; return with current flags

	subttl chk_bound - check for a dma boundary crossing
	page
;======================================================================
;.fs
; chk_bound - check for a dma boundary crossing
;
; check for a dma boundary crossing given a buffer address, the
; number of sectors to transfer and the bytes per sector.
; 
;          ÚÄ 			        Ä¿
; al    -> ³ dx:ax = so2abs of es:bx     ³ -> [p1]
; es:bx -> ³ [p1] = dx:ax                ³ -> [pc]
;          ³ di = dx                     ³
;          ³ dx:ax += ((al * [bps]) - 1) ³
;          ³ cx = 0		         ³
;          ³ ÚÄ if(dx != di)             ³
;          ³ ³ cx = dx                   ³
;          ³ ÀÄ 		         ³
; [bps] -> ³ [pc] = cx:0	         ³
;          ÀÄ 			        ÄÙ
;
; (x is an internal scratch dword)
;
; in:	es:bx = int13 entry pointer
;	al = int13 entry al value (# of sectors)
;	[bps] = bytes per sector
;	ds -> grp
;
; out:	[p1] = starting phyaddr (from original request)
;	[pc] = phyaddr of boundary crossed
;	 (hi word == 0 if no boundary is crossed)
;
;.fe
;=====================================================================
	assume	ds:grp,es:nothing,ss:nothing
chk_bound:
	pushset ax,cx,dx,si,di
	mov	cl,al
	xor	ch,ch
	call	so2abs
	mov	word ptr [p1],ax	; save phyaddr to p1
	mov	word ptr [p1+2],dx
	mov	si,ax
	mov	di,dx
	mov	ax,cx			; retrieve # of sectors
	mul	[bps]
	sub	ax,1
	sbb	dx,0
	add	ax,si
	adc	dx,di
	xor	cx,cx			; presume hi word match
	cmp	dx,di
	je	chb1
	mov	cx,dx			; if hi word !=, then dma conflict
chb1:
	mov	word ptr [pc],0		; save phyaddr to pc
	mov	word ptr [pc+2],cx
	popset	ax,cx,dx,si,di
	ret


	subttl calc_pieces - determine addresses and block sizes
	page
;======================================================================
;.fs
; calc_pieces - determine addresses and block sizes
;
; calculate the starting physical addresses and block sizes for the 
; pieces of the disk operation.
;
;         ÚÄ                              Ä¿
; al   -> ³  q1/r1 = ([pc] - [p1]) / [bps] ³ -> [p2]
; [p1] -> ³  [b1] = q1		           ³ -> [p3]
; [pc] -> ³  [b2] = 0		           ³ -> [b1]
;         ³ ÚÄ if(r1 != 0) 	           ³ -> [b2]
;         ³ ³ [b2] = 1		           ³ -> [b3]
; [bps]-> ³ ÀÄ 			           ³
;         ³  [b3] = al - [b1] - [b2]       ³
;      	  ³  [p2] = [p1] + ([b1] * [bps])  ³
;      	  ³  [p3] = [p2] + ([b2] * [bps])  ³
;      	  ÀÄ 			          ÄÙ
;
; in:	al = int13 entry al value - # of sectors
;	[p1] = phyaddr of 1st block (and original request)
;	[pc] = phyaddr of boundary crossed
;	[bps] = bytes per sector
;	ds -> grp
;	
; out:	[p2] = physical starting address of 2nd block
;	[p3] = physical starting address of 3rd block
;	[b1] = # of sectors in 1st block
;	[b2] = # of sectors in 2nd block
;	[b3] = # of sectors in 3rd block
;
;.fe
;=====================================================================
	assume	ds:grp,es:nothing,ss:nothing
calc_pieces:
	pushset ax,cx,dx
	mov	cl,al
	xor	ch,ch
	mov	ax,word ptr [pc]
	mov	dx,word ptr [pc+2]
	sub	ax,word ptr [p1]
	sbb	dx,word ptr [p1+2]
	div	[bps]
	mov	[b1],ax
	mov	[b2],0
	or	dx,dx
	jz	cpc1
	mov	[b2],1
cpc1:
	sub	cx,[b1]
	sub	cx,[b2]
	mov	[b3],cx
	mul	[bps]			; [b1] still in ax
	add	ax,word ptr [p1]
	adc	dx,word ptr [p1+2]
	mov	word ptr [p2],ax
	mov	word ptr [p2+2],dx
	mov	ax,[b2]
	mul	[bps]
	add	ax,word ptr [p2]
	adc	dx,word ptr [p2+2]
	mov	word ptr [p3],ax
	mov	word ptr [p3+2],dx
	popset	ax,cx,dx
	ret


	subttl so2abs - convert a seg/sel:ofs address to a phyaddr
	page
;======================================================================
;.fs
; so2abs - convert a seg/sel:ofs address to a phyaddr
;
; in:	es:bx = the seg/sel:ofs type address to convert
;
; out:	dx:ax = the corresponding physical address
;	es:bx preserved
;
;.fe
;=====================================================================
	assume ds:nothing,es:nothing,ss:nothing
so2abs:

;$$$$ if(protected mode) call memdev

soa1:					; non-protected mode logic
	push	cx
	xor	dx,dx
	mov	ax,es
	mov	cx,4
soa2:
	shl	ax,1
	rcl	dx,1
	loop 	soa2
	add	ax,bx
	adc	dx,0
	pop	cx
	ret


	subttl abs2nso - convert phyaddr to normalized seg/sel:ofs
	page
;======================================================================
;.fs
; abs2nso - convert phyaddr to normalized seg/sel:ofs
;
; if(dx:ax > 10ffef) then no seg/sel:ofs type address can be derived.
;
; if(dx:ax >= 10000 && dx:ax <= 10ffef) then full normalization
;  cannot be done.  an address with seg = ffff will be returned
;  (or the appropriate selector for the protected mode case).
;
; in the protected mode case, this function will result in the creation
; of a new gdt selector.  it should be deleted when no longer needed.
;
; in:	dx:ax = the phyaddr to convert
;
; out:	cy if error
;	 entry address above 10ffef  
;	 es:bx undefined
;	else
;	 es:bx = normalized seg/sel:ofs address
;
;.fe
;=====================================================================
	assume	ds:nothing,es:nothing,ss:nothing
abs2nso:

;$$$$ if(protected mode) call memdev

abn1:					; non-protected mode logic
	pushset ax,cx,dx
	cmp	dx,0fh
	jna	abn3
	sub	ax,0fff0h
	sbb	dx,0
	cmp	dx,0fh
	jna	abn4
	stc
	jmp	short abn5
abn4:
	mov	bx,ax
	mov	ax,0ffffh
	mov	es,ax
	clc
	jmp	short abn5
abn3:
	mov	bx,ax
	and	bx,0fh
	mov	cx,4
abn7:
	shr	dx,1
	rcr	ax,1
	loop 	abn7
	mov	es,ax
	clc
abn5:
	popset ax,cx,dx
	ret


	subttl abs2bso - convert a physical address to a seg/sel:ofs
	page
;======================================================================
;.fs
; abs2bso - convert a physical address to a based seg/sel:ofs
;
; if(dx:ax > 10ffef) then no seg:ofs type address can be derived.
;
; in:	dx:ax = the phyaddr to convert
;	es = seg/sel on which to base the result
;
; out:	cy if error
;	 entry address above 10ffef  
;	 or the entry seg/sel is out of range for the phyaddr
;	 bx undefined
;	else
;	 bx = based ofs address (with respect to es)
;	dx:ax preserved
;
;.fe
;=====================================================================
	assume	ds:nothing,es:nothing,ss:nothing
abs2bso:

;$$$$ if(protected mode) call memdev

abb1:					; non-protected mode logic
	pushset ax,dx,si,di
	mov	si,dx
	mov	di,ax
	xor	bx,bx
	call	so2abs
	sub	di,ax
	sbb	si,dx
	cmp	si,0
	jz	abb3
	stc
	jmp	short abb4
abb3:
	mov	bx,di
	clc
abb4:
	popset ax,dx,si,di
	ret


	subttl del_desc - delete a gdt descriptor for a given selector
	page
;======================================================================
;.fs
; del_desc - delete a gdt descriptor for a given selector
;
; this function does nothing when protected mode is not active
;
; in:	es = the selector of the descriptor to delete
;
; out:	es = 0 - the null selector
;	(es unchanged in non-protected mode)
;
;.fe
;=====================================================================
	assume	ds:nothing,es:nothing,ss:nothing
del_desc:

;$$$$ if(protected mode) call memdev

	ret


	subttl advance_sect - calc new cyl, head, sect for +sect
	page
;======================================================================
;.fs
; advance_sect - calc new cyl, head, sect for +sect
;
; accepts cylinder, head and sector information in int13 call format
; and derives the new cylinder, head and sector values for advancing
; a certain number of sectors.
; 
;             ÚÄ 			             Ä¿
;  	      ³  q1/r1 = (cur_sect + add_sect) / spt  ³ 
; cur_cyl  -> ³  ÚÄ if(r1 == 0)		              ³ -> new_cyl
; cur_head -> ³  ³ r1 = spt			      ³ -> new_head
; cur_sect -> ³  ³ q1--			              ³ -> new_sect
; add_sect -> ³  ÀÄ 				      ³ 
; heads	   -> ³  cur_sect = r1			      ³ 
; spt	   -> ³  q2/r2 = (cur_head + q1) / heads      ³ 
; 	      ³  cur_head = r2			      ³ 
; 	      ³  cur_cyl += q2			      ³ 
; 	      ÀÄ				     ÄÙ
; 
; in:	al = # of sectors to advance (add_sect)
;	ch = cylinder # (high 2 bits in cl) (cur_cyl)
;	cl = sector # (plus high bits of cylinder #) (cur_sect)
;	dh = head # (cur_head)
;	bh = total # of heads (heads)
;	bl = sectors per track (spt)
;	ds -> grp
;
; out:	ch = cylinder # (high 2 bits in cl) (new_cyl)
;	cl = sector # (plus high bits of cylinder #) (new_sect)
;	dh = head # (new_head)
;	dl preserved
;	
;.fe
;=====================================================================
	assume	ds:grp,es:nothing,ss:nothing
advance_sect:
	pushset ax,bx,si,di
	xor	ah,ah			; ax = add_sect
	mov	si,cx
	and	si,3fh			; si = cur_sect 
	rol	cl,1
	rol	cl,1
	and	cl,3
	xchg	ch,cl			; cx = cur_cyl
	add	ax,si			; ax = (cur_sect + add_sect)
	mov	si,bx
	and	si,0ffh			; si = spt
	mov	di,dx
	xor	dx,dx
	div	si
	or	dx,dx
	jnz	ads1			; if (rem == 0)
	mov	dx,si			; r1 = spt
	dec	ax			; q1--
ads1:
	xchg	di,dx			; di = cur_sect
	xchg	dh,dl
	mov	si,dx
	xchg	dh,dl
	and	si,0ffh			; si = cur_head
	add	ax,si			; ax = (cur_head + q1)
	mov	bl,bh
	xor	bh,bh			; bx = heads
	mov	si,dx
	xor	dx,dx
	div	bx
	mov	bl,dl			; new_head = r2
	mov	dx,si
	mov	dh,bl			; dh = new_head, dl preserved
	add	cx,ax			; cx = new_cyl = cur_cyl + q2
	xchg	ch,cl
	ror	cl,1
	ror	cl,1			; hi 2 bits of cyl # to cl hi bits
	mov	ax,di
	or	cl,al			; cl (b0 - b5) = new_sect
	popset ax,bx,si,di
	ret

	subttl bio13 - call the bios int13 handler
	page
;======================================================================
;.fs
; bio13 - call the bios int13 handler
;
; had to preserve the ds register for the sake of the passport hard
; disk.
;
; in:	original caller's registers
;
; out:	return from int13 call
;
;.fe
;=====================================================================
	assume	ds:nothing,es:nothing,ss:nothing
bio13:
	push	ds
	mgetscb ds
	assume	ds:grp
	cmp	[scb13sk1],0
	pop	ds
	assume	ds:nothing
	je	bio13a
	int	13h
	ret
bio13a:					; alternate entry point
	pushf
	cli
	push	cs
	sub	sp,6
	push	ax
	push	ds
	push	bp
	mov	bp,sp
	mov	[bp+0ah],offset bioret
	mgetscb ds
	assume	ds:grp
	mov	ax,word ptr [oint13]
	mov	[bp+6],ax
	mov	ax,word ptr [oint13+2]
	mov	[bp+8],ax
	pop	bp
	pop	ds
	pop	ax
	assume	ds:nothing
	retf
bioret:
	ret

	subttl	orig13 - call the bios
	page
;======================================================================
;.fs
; orig13 - call the bios
; 
; we don't want the int13 bios to be affected by i/o trapping on ports
; 40, 42, 43, 60, 61 and 64.
; 
; save the current trapping state for ports 40, 42, 43, 60, 61 and 64
; clear their trapping state
; call the original int13 handler
; restore the previous trapping state
; 
; the int15 disk busy task switching logic accesses scbtfix1 and 2 in
; order to re-instate this trapping before calling suspend.
; 
; the saved trapping state is kept in scbtrpfx.  since this is a static
; save, recursion into this routine must not occur.  if we ever find an
; int13 rom bios implementation which recurses, we'll cuss. then we'll
; need to change the int13 gating to associate an owner tcb and not
; block the gate's owner from re-entrance.  we will also need to only
; manipulate the trapping state on the original calling layer.
; 
; in:	int13 entry parameters
; 
; out:	int13 exit parameters
; 
;.fe
;====================================================================
	assume	ds:nothing,es:nothing,ss:nothing
orig13:
	push	ds
	mgetscb	ds
	assume	ds:grp
	test	[scbmmfea],40h		; io protection supported?
	jz	orig13a
	pushset	ax,si,es
	les	si,[scbioptr]		; get pointer to memman data
	mov	al,es:[si+8]
	and	al,00001101b		; only save bits for 40, 42, 43
	mov	[scbtfix1],al
	and	byte ptr es:[si+8],not 00001101b  ; clear p40, p42, p43
	mov	al,es:[si+12]
	and	al,00010011b		; only save bit for p60, p61, p64
	mov	[scbtfix2],al
	and	byte ptr es:[si+12],not 00010011b  ; clear p60, p61, p64
	popset	ax,si,es
	pop	ds
	assume	ds:nothing
	call	bio13
	push	ds
	mgetscb	ds
	assume	ds:grp
	pushf
	pushset	ax,si,es
	les	si,[scbioptr]		; get pointer to memman data
	mov	al,[scbtfix1]
	or	byte ptr es:[si+8],al
	mov	al,[scbtfix2]
	or	byte ptr es:[si+12],al
	popset	ax,si,es
	popf
	pop	ds
	assume	ds:nothing
	jmp	short orig13x
orig13a:
	pop	ds
	assume	ds:nothing
	call	bio13
orig13x:
	ret


	subttl	regr13pri - manage regrab of int13
	page
;======================================================================
;.fs
; regr13pri - manage regrab of int13
; 
; this is the primary int13 handler for the regrab case.  enter here on
; each int13 when there are no intercepts.  also, when there is one or
; more int13 intercept, will initially enter regrab13 but will enter
; here when the last int13 intercept in the chain places a call to what
; it knows as the previous int13 vector holder (what it thinks is the
; bios).
; 
; the main idea is to gate int13 calls so the int15fun90 task switching
; feature does not permit an int13 re-entrance.
; 
; in:	int13 entry parameters
;
; out:	int13 exit parameters
; 
;.fe
;====================================================================
	assume	ds:nothing,es:nothing,ss:nothing
	public regr13pri
regr13pri:
	push	es
	mgetscb	es
	assume	es:grp
	cmp	[scb13sk1],0		; special recursion call?
	je	reg13a
	pop	es
	assume	ds:nothing
	call	bio13a
	retf	2
reg13a:
	assume	es:grp
	cmp	[scb13eoc],'Y'		; entering due to end of chain?
	jne	reg13b
	pop	es
	assume	es:nothing
	call	mosint13
	retf	2
reg13b:					; no, original call, do the gating
	assume	es:grp
	call	chk_13gate
	pop	es
	assume	es:nothing
	call	mosint13
	pushf
	push	es
	mgetscb	es
	assume	es:grp
	dec	[scb13bsy]		; open the gate for other tasks
	pop	es
	assume	es:nothing
	popf
	retf	2


	subttl regrab13 - manages regrab of int13
	page
;======================================================================
;.fs
; regrab13 - manages regrab of int13
; 
; regrab13 is entered when 1 or more int13 intercepts exists.  it will
; be entered from the original call when bl == [tcbnest13].  otherwise,
; its being entered due to a pass through when 2 or more intercepts
; exist.
; 
; in:	int13 entry parms
; 
; out:	int13 exit parms
; 
;.fe
;====================================================================
	assume	ds:nothing,es:nothing,ss:nothing
public	regrab13_data
regrab13_data:
	dw	13h*4			; +0 offset of vector relative to seg 0
	dw	regr13pri		; +2 offset of primary handler
	dw	regrab13a		; +4 offset of first regrab handler
	dw	tcb:tcbnest13		; +6 offset of nest flag
	dw	tcb:tcbchn13		; +8 offset of table for user's vectors

regrab13a:
	push	bx			; these are the int8 handlers which mos
	mov	bl,1			; will re-assert to stay in control
	jmp	short regrab13
	push	bx
	mov	bl,2			; note - each of these entry points
	jmp	short regrab13		; consists of 5 bytes of code.
	push	bx			; the procedure calc_next is
	mov	bl,3			; dependant on this code size.
	jmp	short regrab13
	push	bx
	mov	bl,4
	jmp	short regrab13
	push	bx
	mov	bl,5
	jmp	short regrab13
regrab13:
	push	es			; original bx saved on the stack
	mgetscb es			; current bx value indicates nest level
	assume	es:grp
	push	es
	mov	es,[scbtcbpc]
	assume	es:tcb
	mov	bh,[tcbnest13]
	cmp	bl,bh
	ljne	i13rg100		; bl == the nest level?
	pop	es
	assume	es:grp
	cmp	[scb13sk1],0		; special recursion call?
	je	regr13a
	mov	[scb13eoc],'Y'		; let regr13pri know how to act
	push	ax
	push	bp
	mov	bp,sp
	pushf
	push	cs
	mov	ax,offset mos:reg13iret2
	jmp	regr13b
regr13a:
	call	chk_13gate		; gate original entry
	mov	[scb13eoc],'Y'		; let regr13pri know how to act
	push	ax
	push	bp
	mov	bp,sp

; at this point, bp is at [bp], ax at [bp+2], es at [bp+4], bx at [bp+6]

	pushf
	push	cs			; setup for iret from chain call
	mov	ax,offset mos:reg13iret
regr13b:
	push	ax
	mov	es,[scbtcbpc]
	assume	es:tcb
	mov	bl,bh
	xor	bh,bh
	dec	bx
	shl	bx,1
	shl	bx,1
	push	word ptr [tcbchn13+bx+2]  ; setup to enter the chain
	push	word ptr [tcbchn13+bx]
	mov	bx,[bp+6]
	mov	es,[bp+4]
	mov	ax,[bp+2]
	mov	bp,[bp]
	retf				; call the intercept chain

; after the entire chain has been processed, will return here.  must
; preserve the flags but clear the old bx,es,ax and bp from the stack

reg13iret:
	push	bp
	mov	bp,sp
	push	ax
	pushf
	pop	ax
	mov	[bp+8],ax
	pop	ax
	pop	bp
	add	sp,6
	push	es
	mgetscb	es
	assume	es:grp
	mov	[scb13eoc],'N'
	dec	[scb13bsy]
	pop	es
	popf
	retf	2

reg13iret2:
	push	bp
	mov	bp,sp
	push	ax
	pushf
	pop	ax
	mov	[bp+8],ax
	pop	ax
	pop	bp
	add	sp,6
	push	es
	mgetscb	es
	assume	es:grp
	mov	[scb13eoc],'N'
	pop	es
	popf
	retf	2

; this code is used when regrab13 is entered where bl != the nest level.  
; this means that our int13 handling logic has been re-entered in 
; the middle of a chain process.  need to pass control on to the 
; next intercept routine in the chain.

; at this point, the saved copy of es which is on top of the stack is
; not needed.  however, we need 2 words of room on the top so only
; need to sub sp,2

i13rg100:
	assume	es:tcb
	xor	bh,bh
	dec	bx
	shl	bx,1
	shl	bx,1
	sub	sp,2			; make room for total of 2 words
	push	bp
	mov	bp,sp
	push	ax
	mov	ax,[bp+6]		; relocate es (already pushed)
	mov	[bp+2],ax
	mov	ax,[bp+8]		; relocate bx
	mov	[bp+4],ax
	mov	ax,word ptr [tcbchn13+bx]
	mov	[bp+6],ax		; put address of next int13
	mov	ax,word ptr [tcbchn13+bx+2]  ; intercept on stack
	mov	[bp+8],ax
	pop	ax
	pop	bp
	pop	es
	assume	es:nothing
	pop	bx
	retf				; transfer to next intercept


	subttl chk_13gate - int13 gating layer
	page
;======================================================================
;.fs
; chk_13gate - int13 gating layer
; 
; if another task is already within the int13 layer, suspend until
; clear
; 
; in:	es -> grp
; 
; out:	none
; 
;.fe
;====================================================================
	assume	ds:nothing,es:grp,ss:nothing
chk_13gate:
	push	di
	push	bp
	push	ds
	cmp	[scb13bsy],0		; is the gate blocked?
	lje	ch13a

; yes, switch to mos's stack

	mov	bp,sp			; save current sp
	mov	di,ss			; save current ss
	cmp	di,[scbtcbpc]		; already on mos's stack?
	je	chk13b
	cli
	mov	ss,[scbtcbpc]		; new stack
	assume	ss:tcb
	mov	sp,[tcbstkp]
	sti
chk13b:

; save cache context

	push	ax
	push	cx
	push	si
	push	di
	push	es
	mov	cx,es
	mov	ds,cx
	assume	ds:grp,es:nothing
	push	[scbccur]
	push	[scbcnxt]
	sub	sp,16
	mov	di,sp
	mov	si,offset scbcsave
	mov	cx,ss			; need es -> stack
	mov	es,cx
	mov	cx,16/2
	rep	movsw

; suspend until scb13bsy is clear

	mov	word ptr [tcbpoll],offset mos:i13poll
	mov	word ptr [tcbpoll+2],cs
	and 	[tcbwait],not 2		; clear b1
	or 	[tcbwait],5		; set b0 and b2
	call	suspend			; call in mos segment

; restore cache context

	mov	cx,ds
	mov	es,cx
	assume	ds:nothing,es:grp
	mov	cx,sp
	push	ds
	mov	si,cx
	mov	di,offset scbcsave
	mov	cx,ss
	mov	ds,cx
	mov	cx,16/2
	rep	movsw
	pop	ds
	assume	ds:grp,es:nothing
	add	sp,16
	pop	[scbcnxt]
	pop	di
	mov	es,[scbclst]
	assume	es:nothing
	callmos2 cmap			; setting [scbcele] & [scbccur] also

; ax and es now destroyed by cmap

	pop	es
	assume	ds:nothing,es:grp
	pop	di
	pop	si
	pop	cx
	pop	ax

; switch back to caller's stack

	cli
	mov	ss,di
	assume	ss:nothing
	mov	sp,bp
	sti
ch13a:
	inc	[scb13bsy]
	pop	ds
	pop	bp
	pop	di
	ret


	subttl i13poll - tcbpoll function for int13 gate block
	page
;======================================================================
;.fs
; i13poll - tcbpoll function for int13 gate block
; 
; determine if a task can wake up and enter the int13 layer
; 
; in:	ss -> tcb
; 	ds -> grp
; 
; out:	al == 0 if can awake, al == 1 if still need to suspend
; 
;.fe
;====================================================================
	assume	ds:grp,es:nothing,ss:tcb
i13poll:
	mov	al,1			; preset return status for al
	cmp	[scb13bsy],0		; if block cleared
	jne	i13a
	xor	al,al			; signal wakeup
i13a:
	retf

mosseg	ends
	end

