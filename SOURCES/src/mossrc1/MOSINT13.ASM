	include page.inc
	title	mosint13 - disk dma management
comment ^---------------------------------------------------------------
		development specification

 program name:	mos.com 		assigned to: david morrow
 module name:	mosint13		assign date: 08/12/86
 entry points:	mosint13		completed: 08/16/86
 entry from:	disk drivers (or who ever)
 entry method:	int 13
 calls:	n/a
 purpose:	to prevent dma conflicts before they cause a disk error
 refer to:	n/a
 last update:	01/25/90
-----------------------------------------------------------------------
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

-----------------------------------------------------------------------^
	subttl	group segments and include block definitions
	page

	include group.inc
	.xlist
	include mosregs.inc
	include	macros.inc
	.list

gdata	segment word public 'data'

	.xlist
	include mosscbex.inc		; specify all scb items as external
	.list

	public	int13in

int13in db	'N'		; in int 13 routine flag
dmascnt db	0		; sector counter
dma13ax dw	0		;\
dma13bx dw	0		; \
dma13cx dw	0		;  > save space
dma13dx dw	0		; /
dma13es dw	0		;/
dma13bf dw	0		; segment address of disk buffer to use
dmaofst dw	0		; offset in callers buffer of conflict

	public	media13
media13  db	4 dup ('N')	; flags to indicate if media as change

	public	ourbuf		; the hard disk driver uses this in init
ourbuf	db	512 dup(0)	; buffer space for disk sector (temporary)

gdata	ends

tcb	segment at 1234h
	.xlist
	include mostcb.inc	; tcb definition
	.list
tcb	ends

irq	segment byte public 'data'
	extrn	irqstart:byte, irqend:byte

	dw	13h*4			; offset for int 13
oint13	dd	?			; save old one here
	dw	0			; leave any changes
	dw	mos:regr13pri		; inital value (only entry point)
	dw	0			; no secondary entry point

irq	ends

poll	segment byte public 'data'
poll	ends

ddt	segment word public 'code2'

	extrn	cmap:near

ddt	ends

	subttl	mos segment - mos module code and local data
	page
mosseg	segment word public 'code1'
	assume	cs:mos,ds:grp,es:nothing,ss:tcb
	extrn	mosend:byte, scbfree:word, sbios:word

	extrn	wordmove:near, suspend:near

biosseg  dw	0040h		; constant for access bios data segment

	public	mosint13


	subttl	mosint13 - interrupt 13h handler
	page
comment ^==============================================================

.func: mosint13 - interrupt 13h handler

entry:	int13 entry parms

exit:	int13 exit parms

this routine will resolve any int 13h dma conflicts by loading the
conflicting sector into a temporary sector and then moving the
information to the 'real' buffer.

.calls: 
.reads: 
.writes: 

.endfn================================================================^
	assume	ds:nothing,es:nothing
mosint13:
	sti				; who cares
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
	xor	bh,bh			; bwr 11/17/89 - was xor bx,bx!
	mov	byte ptr [media13+bx],'Y'
	pop	bx
int13msk:
	cmp	[int13in],'Y'		; are we already in mosint13?
	jne	int13ok
	jmp	fastout
int13ok:
	mov	[dma13ax],ax		; save function and sector count
	mov	[dma13cx],cx		; save track and sector #
	mov	[dma13dx],dx		; save drive and head
	mov	[dma13bx],bx		; save buffer address
	mov	[dma13es],es		; "     "	"
	mov	[dmaofst],0		; init offset pointer to 1st sector
	mov	[dmascnt],0		; init sector counter
	cmp	byte ptr [dma13ax+1],1	; check for reset call or status call
	jbe	dmax			; yes, skip all the bs
	cmp	byte ptr [dma13ax+1],3	; check for regular disk call
	ja	dmax			; if not regular disk call
	mov	ax,es			; get buffer segment
	and	ax,0fffh		; clear off 64k page #
	shl	ax,1			; calc offset from segment
	shl	ax,1
	shl	ax,1
	shl	ax,1
	add	ax,bx			; ax=buffer address
	mov	cx,[dma13ax]		; get sector count
	xor	ch,ch			; clear fun code
dma13lp:
	add	ax,512			; # bytes needed for sector
	jc	xyes			; crossed 64k boundary
	add	[dmaofst],512/16	; keep offset to conflict in callers buffer
	loop	dma13lp 		; no, try next sector

; no conflicts just proceed with original disk call

	mov	cx,[dma13cx]
	mov	dx,[dma13dx]
	mov	bx,[dma13bx]
	mov	es,[dma13es]
dmax:
	mov	ax,[dma13ax]		; restore entry values
fastout:
	call	orig13
	pop	ds			; restore original ds
	assume	ds:nothing
	ret
xyes:
	assume	ds:grp
	mov	ax,[dma13ax]		; restore entry values
	cmp	al,cl			; is the 1st sector a conflict?
	je	do1st			; yes, nothing to be read before it
	sub	al,cl			; calc # before reaching a conflict
	push	cx			; save sector count til conflict
	mov	cx,[dma13cx]
	mov	dx,[dma13dx]
	mov	bx,[dma13bx]
	mov	es,[dma13es]
	push	ax			; save count (televideo bios bug)
	call	orig13
	pop	ax			; sectore count back
	pop	cx			; restore
	jnc	$+5
	jmp	i13err			; disk error
	sub	byte ptr [dma13ax],al	; sub sectors read from total count
	add	byte ptr [dma13cx],al	; add sectors read to sector number
	add	[dmascnt],al		; keep total count of read sectors
do1st:
	mov	ax,[dma13ax]		; get original ax
	cmp	ah,2			; read or write?
	je	doread			; if a read operation, no pre-processing

; move from the caller's buffer to our temp buffer.

	push	si
	push	di
	push	ds
	push	ds
	pop	es
	mov	di,[dma13es]		; get address to callers buffer
	add	di,[dmaofst]		; calc offset into buffer for this load
	add	[dmaofst],512/16	; update pointer to include this sector offset
	mov	si,[dma13bx]		; point si at caller's buffer
	mov	ds,di			;   "   ds  "	 "      "
	assume	ds:nothing
	lea	di,[ourbuf]		; buffer for staging
	cld
	mov	cx,512/2
	call	wordmove		; faster tranfer on i386\i486
	pop	ds
	assume	ds:grp
	mov	bx,di			; offset for rest of disk call (if any)
	pop	di
	pop	si
doread:
	mov	al,1			; read the one sector that was a conflict
	mov	cx,[dma13cx]
	mov	dx,[dma13dx]
	push	ds
	pop	es
	lea	bx,ourbuf		; temp buffer address

; the following flag and int 13 will insure that the conflicting
; sector is staged if need by going through all int 13 routines in
; the chain. (386drive and gizdrive do staging)

	mov	[int13in],'Y'		; set 'in' mosint13 flag
	mov	[scb13sk1],1
	push	ax			; save count (televideo bios bug)
	int	13h
	pop	ax
	mov	[int13in],'N'		; clear 'in' flag
	jnc	nor13err
	jmp	i13err			; disk error during read
nor13err:
	sub	byte ptr [dma13ax],al	; sub sectors read from total count
	add	byte ptr [dma13cx],al	; add sectors read to sector number
	add	[dmascnt],al		; keep total count of read sectors
	cmp	byte ptr [dma13ax+1],2	; read or write call?
	jne	doleft			; if write, don't do copy

; now move from our temp buffer to the callers buffer

	push	si
	push	di
	mov	di,[dma13es]		; get address to callers buffer
	add	di,[dmaofst]		; calc offset into buffer for this load
	add	[dmaofst],512/16	; update pointer to include this sector offset
	mov	es,di
	assume	es:nothing
	mov	di,[dma13bx]
	lea	si,ourbuf
	cld
	mov	cx,512/2
	call	wordmove		; faster tranfer on i386\i486
	mov	bx,di			; offset for rest of disk call (if any)
	pop	di
	pop	si

; now load any remaining sectors into the rest of the buffer

doleft:
	mov	ax,[dma13es]		; get buffer segment
	add	ax,[dmaofst]		; calc new address for end load
	mov	es,ax
	assume	es:nothing
	mov	ax,[dma13ax]
	mov	bx,[dma13bx]		; use their offset (segment has changed)
	mov	cx,[dma13cx]
	mov	dx,[dma13dx]
	or	al,al			; last sector already read?
	jz	dmalast 		; yes, skip read
	push	ax			; save count (televideo bios bug)
	call	orig13
	pop	ax
	jnc	$+5
	jmp	i13err			; disk error during read
dmalast:
	add	al,[dmascnt]		; calc total sector count
	sub	cl,[dmascnt]		; calc original starting sector
	mov	es,[dma13es]
	pop	ds
	jmp	i13ret			; return to caller with our flags
i13err:
	mov	cx,[dma13cx]		; return with ax having status
	mov	dx,[dma13dx]
	mov	bx,[dma13bx]
	mov	es,[dma13es]
	pushf				; preserve carry flag
	add	al,[dmascnt]		; calc total sector count
	popf
	pop	ds
	assume	ds:nothing
i13ret:
	ret				; return with flags set


	subttl	orig13 - call the bios
	page
comment ^==============================================================

.func: orig13 - call the bios

entry:	int13 entry parameters
	ds ->grp

exit:	int13 exit parameters
	ds -> grp

we don't want the int13 bios to be affected by i/o trapping on ports
40, 42, 43 and 61.

save the current trapping state for ports 40, 42, 43 and 61
clear their trapping state
call the original int13 handler
restore the previous trapping state

the int15 disk busy task switching logic accesses scbtfix1 and 2 in order
to re-instate this trapping before calling suspend.

the saved trapping state is kept in scbtrpfx.  since this is a static
save, recursion into this routine must not occur.  if we ever find an
int13 rom bios implementation which recurses, we'll cuss.
then we'll need to change the int13 gating to associate an owner tcb and
not block the gate's owner from re-entrance.  we will also need to
only manipulate the trapping state on the original calling layer.

.calls: 
.reads: 
.writes: 

.endfn================================================================^
	assume	ds:grp,es:nothing,ss:nothing
orig13:
	test	[scbmmfea],40h		; io protection supported?
	jz	orig13a
	pushset	ax,si,es
	les	si,[scbmmptr]		; get pointer to memman data
	les	si,dword ptr es:[si].parmiop
	mov	al,es:[si+8]
	and	al,00001101b		; only save bits for 40, 42, 43
	mov	[scbtfix1],al
	and	byte ptr es:[si+8],not 00001101b  ; clear p40, p42, p43
	mov	al,es:[si+12]
	and	al,00000010b		; only save bit for p61
	mov	[scbtfix2],al
	and	byte ptr es:[si+12],not 00000010b  ; clear p61
	popset	ax,si,es
	pushf				; simulate an int 13
	cli
	call	dword ptr [oint13]
	pushf
	pushset	ax,si,es
	les	si,[scbmmptr]		; get pointer to memman data
	les	si,dword ptr es:[si].parmiop
	mov	al,[scbtfix1]
	or	byte ptr es:[si+8],al
	mov	al,[scbtfix2]
	or	byte ptr es:[si+12],al
	popset	ax,si,es
	popf
	jmp	short orig13x
orig13a:
	pushf				; simulate an int 13
	cli
	call	dword ptr [oint13]
orig13x:
	ret


	subttl	regr13pri - manage regrab of int13
	page
comment ^==============================================================

.func: regr13pri - manage regrab of int13

entry:	int13 entry parameters
exit:	int13 exit parameters

this is the primary int13 handler for the regrab case.  enter here on 
each int13 when there are no intercepts.  also, when there is one 
or more int13 intercept, will initially enter regrab13 but will 
enter here when the last int13 intercept in the chain places a 
call to what it knows as the previous int13 vector holder (what 
it thinks is the bios).

the main idea is to gate int13 calls so the int15fun90 task switching
feature does not permit an int13 re-entrance.

.calls: 
.reads: 
.writes: 

.endfn================================================================^
	assume	ds:nothing,es:nothing,ss:nothing
	public regr13pri
regr13pri:
	push	es
	mgetscb	es
	assume	es:grp
	cmp	[scbi15tsl],'Y'		; if disksw=n in config.sys
	jne	reg13c
	cmp	[scb13eoc],'Y'		; entering due to end of chain?
	je	reg13c
	cmp	[scb13sk1],0		; special recursion call?
	je	reg13b
	mov	[scb13sk1],0		; yes, clear flag and do simple call
reg13c:
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
comment ^==============================================================

.func: regrab13 - manages regrab of int13

entry:	int13 entry parms

exit:	int13 exit parms

regrab13 is entered when 1 or more int13 intercepts exists.  it will 
be entered from the original call when bl == [tcbnest13].  otherwise,
its being entered due to a pass through when 2 or more intercepts
exist.

.calls: 
.reads: 
.writes: 

.endfn================================================================^
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
	mov	[scb13sk1],0		; yes, clear flag and do simple call
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
comment ^==============================================================

.func: chk_13gate - int13 gating layer

entry:	es -> grp

exit:	none

if another task is already within the int13 layer, suspend until clear

.calls: 
.reads: 
.writes: 

.endfn================================================================^
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
comment ^==============================================================

.func: i13poll - tcbpoll function for int13 gate block

entry:	ss -> tcb
	ds -> grp

exit:	al == 0 if can awake, al == 1 if still need to suspend

determine if a task can wake up and enter the int13 layer

.calls: 
.reads: 
.writes: 

.endfn================================================================^
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