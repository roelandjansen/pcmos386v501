	include page.inc
	title	mosrtask.asm - remove running task
comment ^===============================================================
		development specification

 program name:	$$mos.com		assigned to: jeffrey s. mayo
 module name:	mosrtask		assign date: 12/10/86
 entry points:	mosrtask		completed: 3/20/87
 entry from:	mosfun80
 entry method:	call
 calls:		see extrn statements
 purpose:	remove a running task from the system.
 refer to:	mositask, mosfun80
 last update:	08/18/1992
========================================================================

jsm 05/18/87	can't remove a task which is watching another task.

mjs 08/18/87	added code to remove a task when there is no memory manager.  
		noticed that 8087 save area was not tested for - corrected

jrb 12/02/87	fixed various non-mm case conditions and deallocate 
		tcbstate if needed

sah 01/06/88	corrected jrb deallocation of tcbstate area which points 
		to actual area (as return in int 38 call 0a) and not 
		the prefix.

sah 01/20/88	change scbseg and zero seg access to mgetxxx macros.

sah\rbr 02/21/88 move ddt segment to mo2 group

rbr 02/29/88	moving lagtcb & irqwflag to grp

sah 04/01/88	added call to tcbunreg (if inuse) for un-registering a 
		terminal driver.

jrb 05/02/88	flush all changed cache buffers so there aren't any 
		hanging around which are owned by the task being removed

mjs 5/12/88	added code after the label msrt40 to delete any entries
		there might be in the port specific irq reservation
		table for the task being removed.

sah 09/08/88	if alias are use on the task in question, data
		structures use by alias of the task to be remove are
		deallocated.  also clean it up.

sah 01/27/89	corrected leak hole - should use tcb address not id.

bwr 11/29/89	marked messages for foreign language translation.

mjs 03/31/90	added code to deallocate the smp block for the ansi
		keyboard buffer.

SAH 04/10/90	Added code to deallocate the smp block for INT 24 logic
		if one exists. Also move calling UnRegister Handler 
		down into closetask (previously closetfb), while will
		switch in task. Also deallocated INT d4h fun 07 wait
		information in TCBWINFO.

SAH 04/18/90    Save important register when calling unregister handlers

mjs 04/25/90	modify closetask to not check tcbtfbpf at the start and
		to save/clear/restore scbnotsl to prevent a task switch
		during the userpoll and closeall processes.

mjs 05/17/90	modify logic which clears irq reservations to attend
		to the scbirqdxx table.

SAH 06/22/90	Corrections for MSetPSP macros		    

SAH 11/01/90	Remove References to old EMS techniques
			
SAH 01/09/91	Call swrealram inside closetask, so that VNA+ style
		workstations will be switch out and Master console 
		(46e8) register will be switch in even through task has 
		vidram on.  (Note: This call could be made inside 
		switchgp, but making call here for this rare case
		will slow MOS's context switch  logic down.

mjs 07/01/91	added logic below clst10 to handle the case where
		lanserve owns the unreg function.  netbios needs to
		see [scbpost] == ss

mjs 08/07/91	added call to dopost just before the call to the
		unreg handler.  this was needed for lansat.

SAH 08/14/91	Added stack biasing around calling unreg handler, this
		solved Cheryl's LanLink Netbios stack crashing problem.

================ 5.01 Kernel Ends Here ====================================

mjs 08/18/92	clean up segment declarations

mjs 08/26/92	delete reference to scbfree

=======================================================================^

.xlist
	include mosrtask.pub
	include group.inc
	include mosregs.inc
	include mosbdb.inc
	include moscdb.inc
	include mosgfb.inc
	include mostfb.inc
	include mosrlb.inc
	include macros.inc

tcb	segment at 1234h
	include mostcb.inc
tcb	ends

gdata	segment
	include mosscbex.inc
gdata	ends
.list

gdata	segment
	extrn	lagtcb:word,irqwflag:byte
gdata	ends

;======================================================== mos segment
if 0 eq 0
segment_num = 1
endif
mosseg	segment
	assume	cs:mos,ds:grp,es:nothing,ss:tcb
$$$rtask label	byte

	extrn	mosend:byte, sbios:word
	extrn	bugerror:near,okswitch:near,noswitch:near,mosliman:near
	extrn	mosheman:near,suspend:near,classbits:near,switchif:near
	extrn	closeall:near, flush:near, swrealram:near, dopost:near

	subttl	mosrtask -- remove running task from system
	page
;======================================================================
;,fs
; mosrtask -- remove running task from system
; 
; remove running task from system.  disable the task from switching,
; then return all of the resources it owns.  special handling is used
; if the requested task is the current task -- the caller never regains
; control in this case.
; 
; task 0 cannot be removed with this call.  also, the caller must have
; write privilege to the class of the deleted task.
; 
; in:	es points to the tcb to delete
; 	ss points to the tcb of the running task (not necessarily same)
; 
; out:	ax 0 if task removal succeeded
; 	ax 5 if task id 0 or no write access to task's class
; 	ax 31 if unknown screw-up
; 
;,fe
;================================================================
 	assume	ds:grp,es:nothing,ss:tcb
	public	mosrtask
mosrtask proc near
	push	cx
	push	ds			; we put the tcb pointer into ds
	push	es
	pop	ds
	mgetscb es
	assume	ds:tcb,es:grp,ss:nothing
	call	noswitch		; don't joggle my elbow
	mov	ax,ds			; make sure that it not foreground
	cmp	ax,[scbtcbpf]		; it is better to compare actual tcb's
	jne	msrt5
	jmp	msrt300 		; caller wants to delete task 0, refuse
msrt5:

; check for access to the task's class

	mov	al,[tcbclass]		; class for task in question
	push	ds
	mov	ds,[scbtcbpc]		; switch ds to current task's TCB
	callmos2 classbits		; do we have permissions for this task?
	pop	ds
	and	al,3			; must have read/write permission
	cmp	al,3
	je	msrt10			; if caller has permission
	jmp	msrt300 		; if no permission

; check for someone else looking at this task's terminal.
; eventually, mos will dissociate tasks & terminals.

msrt10:
	mov	ax,ds
	mov	cx,[tcbscrdd]		; first task looking at this task
	jcxz	msrt13			; if no task looking at this one
	cmp	ax,cx			; only ok task is task itself
	je	msrt12			; if scrdd is task itself
	jmp	msrt300 		; if other task watching, return "no access"
msrt12:
	mov	cx,[tcbnxtdd]		; other tasks looking at this task
	jcxz	msrt13			; no other task watching, next test
	jmp	msrt300 		; if other task watching, return "no access"

; check to see if task watching someone else.

msrt13:
	push	ds
	mov	cx,[scbtcbpf]
msrt14:
	jcxz	msrt15			; finished searching list, all ok
	mov	ds,cx
	cmp	ax,cx			; is this the task to remove?
	je	msrt14a 		; if it is, we've already considered it
	cmp	ax,[tcbscrdd]
	je	msrt14b 		; if task watching someone else, no access
	cmp	ax,[tcbnxtdd]
	je	msrt14b 		; ditto
msrt14a:
	mov	cx,[tcbtcbpn]		; next tcb to consider
	jmp	msrt14

; the task is watching someone else, can't remove it.

msrt14b:
	pop	ds			; restore pointer to tcb to remove
	jmp	msrt300 		; no access error message
msrt15:

; check for removal of current task.

	pop	ds			; back to current tcb
	cmp	[scbtcbpc],ax		; delete current task?
	jne	msrt17			; if not the current task
	jmp	msrt200 		; the current task, do special processing

; shut down task to remove

msrt17:
	call	rlsnetbios		;jrb release all netbios resources, if any
	callmos2 flush			;jrbr make sure there are no dirty buffers
					;jrbr owned by this tcb
	mov	[tcbslice],0		; task gets no processor time

; now we can give back the memory, stack, etc. safely.
; the deleted task can't run anymore.

; note: msrt20 is an entry point from rempoll00

; free all cdb's for task

msrt20:
	mov	ax,[tcbcdbpf]		; check for cdb's to free
	or	ax,ax
	jz	msrt30			; if no cdb's for task
	push	es			;022988
	mov	es,ax
	assume	es:nothing
	mov	ax,(1 shl 8) or 'C'	; free first cdb for task
	call	mosliman
	pop	es			;022988
	assume	es:grp			;022988
	or	al,al			; returned ok?
	jz	msrt20			; if no error from returning block
	jmp	msrterr 		; display error message & halt

; must test to see if the task to be removed is recorded in lagtcb or
; the scbirqpf/tcbirqpn linked list

msrt30:
	cli
	push	ds
	mov	ax,ds			; get the tcb to be removed
	cmp	ax,word ptr [lagtcb]	; same as lagtcb?
	jne	msrt31
	mov	word ptr [lagtcb],0	; don't let int8 call this
msrt31: 				; task's intercept
	xor	bx,bx
msrt32:
	cmp	[scbidq2+bx],ax 	; check for an irq reservation for
	jne	msrt33			; this task and remove if find one
	mov	word ptr [scbidq2+bx],0
	mov	word ptr [scbirqd0a+bx],irq_no_res  ; clear reservation
msrt33:
	cmp	word ptr [scbirqpf+bx],0; any irq's intercepts in the
	je	msrt36			; linked list ?
	mov	ds,[scbirqpf+bx]
	cmp	[scbirqpf+bx],ax	; is this task first in the chain?
	jne	msrt34
	mov	cx,[tcbirqpn+bx]	; yes, unlink first tcb in chain
	mov	[scbirqpf+bx],cx
	or	cx,cx
	jnz	msrt33a
	mov	word ptr [scbirqd0a+bx],irq_no_res  ; clear only if empty
msrt33a:
	call	fixirqwfg
	jmp	msrt36
msrt34: 				; not at first of list, must trace
	cmp	word ptr [tcbirqpn+bx],0; end of list?
	je	msrt36
	cmp	word ptr [tcbirqpn+bx],ax  ; find this task ?
	jne	msrt35
	push	ds
	mov	ds,[tcbirqpn+bx]
	mov	cx,[tcbirqpn+bx]	; unlink in the middle of the chain
	pop	ds
	mov	[tcbirqpn+bx],cx
	call	fixirqwfg
msrt35:
	mov	ds,[tcbirqpn+bx]	; advance to next tcb in the chain
msrt36:
	add	bx,2
	cmp	bx,12
	jne	msrt32
	pop	ds
	sti
	jmp	msrt40
fixirqwfg:
	push	bx
	push	cx
	shr	bx,1
	mov	cl,bl
	mov	bl,1
	shl	bl,cl
	or	byte ptr [irqwflag],bl
	pop	cx
	pop	bx
	ret
msrt40:

; remove any port specific irq reservations
; entry parms:	ds -> tcb of task to remove
;		es -> grp
;
; iptr is the irq pointer for irq's 2 through 7
; rptr is the record pointer for records 0 through 15

	push	ds
	mov	ax,ds			; reftcb
	mov	ds,[scbidqp]
	assume	ds:nothing
	xor	cx,cx			; clear the hit flag
	xor	bx,bx			; iptr = 0
	xor	si,si			; rptr = 0
m40a:
	cmp	word ptr [bx+si],0	; if iptr.rptr.port = 0 --> m40c
	jz	m40c
	cmp	word ptr [bx+si+2],ax	; if iptr.rptr.tcb != reftcb -> m40b
	jne	m40b
	cmp	si,4*15 		; if rptr = ofs of last record position
	je	m40d			; then --> m40d to delete last record
	mov	di,4*15 		; init a back scan pointer
m40e:
	cmp	word ptr [bx+di],0	; find last record with a non-zero port
	jne	m40f
	sub	di,4
	jmp	m40e
m40f:
	cmp	di,si			; is record to be deleted the same
	je	m40d			; as the last record used?
	mov	ax,[bx+di]		; no, so fetch last record and copy
	mov	[bx+si],ax		; it over the record to be deleted
	mov	ax,[bx+di+2]
	mov	[bx+si+2],ax
	mov	word ptr [bx+di],0	; and delete the last record
	mov	cx,1			; mark the hit
	jmp	m40b
m40d:
	mov	word ptr [bx+si],0	; delete the record
	mov	cx,1
	jmp	m40c
m40b:
	add	si,4			; rptr +=4
	cmp	si,4*16 		; if rptr != 4*16 --> m40a
	jne	m40a
m40c:
	jcxz	m40g			; if no hit, skip around
	cmp	word ptr [bx],0		; else, is the list now empty?
	jne	m40g
	push	bx			; if yes, clear the reservation
	mov	cl,5
	shr	bx,cl
	mov	word ptr [scbirqd0a+bx],0
	pop	bx
m40g:
	xor	si,si			; rptr = 0
	add	bx,64			; iptr += 64
	cmp	bx,6*64 		; if iptr != 6*64 --> m40a
	jne	m40a
	pop	ds
	assume	ds:tcb

; free all tfb's for task

	call	remalias		; sah  remove alias drives
	call	closetask		; close tfbs and do unregister

; free miscellaneous resources

msrt50:
	mgetscb es			; point es at scb again
	assume	es:grp
	cmp	[scbmmfg],'Y'		; if no mm, skip de-allocation of
	je	$+5			; video save area
	jmp	msrt60

; removed de-allocation of video save area from heap and added 
; de-allocation from extended memory
			
	mov	bx,[tcbvidh1]		; video save area handle
	mov	cx,[tcbvidp1]		; page count of video save area
	mov	ah,2			; return memory
	call	[scbmmsub]
	or	ax,ax
	jz	msrt60
	jmp	msrterr
msrt60:
	cmp	[scbsw87],'Y'		; is there an 8087 save space?
	jne	msrt80			; no, (then we can't deallocate it, can we...)
	mov	ax,[tcb87sav]
	dec	ax
	mov	es,ax			; now es points to header, not data
	mov	ah,1
	call	mosheman		; free 8087 save area
	or	al,al			; returned ok?
	jz	msrt80			; if no error from returning block
	jmp	msrterr 		; display error message & halt

; deallocate the ansi buffer

msrt80:
	cmp	[tcbansi],0		; ANSI support?
	je	msrt81 
	mov	ax,[tcbkbansi]
	dec	ax
	mov	es,ax			; now es points to header, not data
	mov	ah,1
	call	mosheman		; deallocate from heap
msrt81:

; deallocate INT 24 save block if necessary

	cmp	[tcbsav24],0		; is INT 24 save block allocated
	je	shno24			; no...then skip the following
	mov	es,[tcbsav24]
	mov	ah,1
	call	mosheman		; deallocate from heap
shno24:

; deallocate INT d4h function wait information if necessary
	
	cmp	[tcbwinfo],0		; is Wait Information allocated
	je	shnowait
	mov	ax,[tcbwinfo]
	dec	ax
	mov	es,ax			; now es points to header, not data
	mov	ah,1
	call	mosheman		; deallocate from heap
shnowait:

; return ega/vga state to smp if needed

	cmp	[tcbstate],0
	je	msrt85
	mov	ax,[tcbstate]		; sah change es to ax
	dec	ax			; sah point to prefix
	mov	es,ax			; sah
	assume	es:nothing

	mov	ah,1
	call	mosheman
	or	al,al
	jz	msrt85
	jmp	msrterr

; return task's RAM to memory pool.

msrt85:
	mgetscb es			; point es at scb again
	assume	es:grp
	cmp	[scbmmfg],'Y'		; using memory management?
	jne	msrt130a		; if no management
	push	si
	push	di
	mov	cx,4
	xor	si,si			; memory space handle & page index
	mov	di,si
msrt90:
	mov	bx,[tcbmmhdl+si]	; handle for memory
	xchg	cx,[tcbmmpgs+di]	; # of pages (& save loop count)
	or	cx,cx			; set flags & check for zero count
	jz	msrt100 		; if zero count, quit returning memory
	mov	ah,2			; return memory
	call	[scbmmsub]
	mov	cx,[tcbmmpgs+di]	; restore loop count
	add	si,2			; advance indexes
	add	di,2
	or	ax,ax			; memory returned ok?
	loopz	msrt90			; z if it's OK
msrt100:
	pop	di
	pop	si
	jz	$+5
	jmp	msrterr 		; if error returning task ram
	push	si
	push	di
	mov	cx,2
	xor	si,si			; video memory handles & pages index
	mov	di,si
msrt110:
	mov	bx,[tcbvmhdl+si]	; video handle
	xchg	cx,[tcbvmpgs+di]	; get video pages & save loop ctr
	or	cx,cx			; set flags & check for zero count
	jz	msrt120 		; if zero count, quit returning memory
	mov	ah,2			; return memory
	call	[scbmmsub]
	mov	cx,[tcbvmpgs+di]	; restore loop count
	add	si,2			; advance pointers
	add	di,2
	or	ax,ax			; memory returned ok?
	loopz	msrt110 		; z if it's OK
msrt120:
	pop	di
	pop	si
	jz	$+5
	jmp	msrterr 		; if error returning video ram
	jmp	msrt130

; free task's TCB

; enter here only for non mm case
; locate the task immediately preceding this one in memory

msrt130a:				
	mov	dx,[tcbbegad]		; beginning address of task being removed
	mgetscb es
	assume	es:grp
	mov	ax,[scbtcbpf]
msrt135a:
	or	ax,ax
	jz	msrt130 		; this can't happen, so throw up our hands
	mov	es,ax
	assume	ds:nothing,es:tcb,ss:nothing
	mov	ax,[tcbtcbpn]
	cmp	dx,[tcbendad]
	jne	msrt135a
	assume	ds:tcb,es:nothing
	sub	dx,[tcbendad]
	assume	ds:nothing,es:tcb
	neg	dx			; dx = tcbendad - tcbbegad for removed task
	push	ds
	mov	ax,[tcbmbpf]		; get first mcb of calling task
msrt130b:
	mov	ds,ax
	cmp	byte ptr ds:[0],'Z'	; is this last block ?
	je	msrt130c
	inc	ax
	add	ax,ds:[3]		; position to next prefix
	jmp	msrt130b
msrt130c:
	add	ds:[3],dx		; increase size in last mcb of caller
	mov	bx,[tcbpsp]		; get callers current psp
msrt130d:
	mov	ds,bx
	mov	ax,bx			; increase size in all caller's PSP's
	add	ds:[2h],dx
	mov	bx,ds:[16h]		; get parent
	cmp	bx,ax
	jne	msrt130d
	pop	ds
	add	[tcbendad],dx		; increase the caller's ending address
	mov	ax,[tcbendad]
	shr	ax,1
	shr	ax,1
	shr	ax,1			; predict 40:13 setting for the new task
	shr	ax,1
	shr	ax,1
	shr	ax,1
	mov	es,[tcbcntxpt]
	assume	es:nothing
	mov	es:[413h],ax
	assume	ds:tcb,ss:nothing

msrt130:

; added de-allocation of context save area. if have mm, de-allocate 
; from extended memory else smp

	mgetscb es			; point es at scb again
	assume	es:grp
	test	[scbmmfea],10h		; new method of detecting type of context
	jz	msrt145 		; switching to be used
	mov	bx,[tcbcntxpt]		; yes
	mov	cx,1
	mov	ah,2
	call	[scbmmsub]		; de-allocate from extended memory
	jmp	msrt150
msrt145:
	mov	ax,[tcbcntxpt]
	dec	ax
	mov	es,ax
	mov	ah,1
	call	mosheman
msrt150:
	or	al,al
	jz	msrt151
	jmp	msrterr
msrt151:

; if scblastff is Task being remove, make sure that we zero out scblastff

	MgetSCB es
	mov	ax,ds
	cmp	ax,[scblastff]		; is tcb = scblastff
	jne	msrt152
	mov	[scblastff],0		; no lastff
msrt152:

; de-allocate tcb now that everything else is done

	push	ds
	pop	es			; tcb address in es
	assume	es:tcb
	mov	ax,(1 shl 8) or 'T'	; free tcb for task
	call	mosliman
	or	al,al			; returned ok?
	jz	msrt140 		; if no error from returning block
	jmp	msrterr 		; display error message & halt
msrt140:
	xor	ax,ax			; successfully removed task
	jmp	short msrt500		; leave

; prepare to remove current task

msrt200:
	mov	[tcbslice],1		; make sure task gets considered for time
	and	[tcbwait],not 6
	or	tcbwait,1		; set the wait bit and clear all others

; wait until current task <> task to delete

	mov	word ptr [tcbpoll],offset mos:rempoll00
	mov	word ptr [tcbpoll+2],cs
	call	okswitch		; allow task switching
	call	suspend 		; give up processor & never get it back

; illegal attempt to remove a task

msrt300:
	mov	ax,5			; no access
	jmp	short msrt500		; leave
msrt400:
	mov	ax,31			; general foul-up
msrt500:
	call	okswitch		; allow switching now that we're finished
	push	ds
	pop	es			; restore tcb pointer
	pop	ds			; restore old ds
	pop	cx
	ret

; handle system type error in returning resources

msrterr:
	call	bugerror
	db	'   '
	db	'Error returning task resources - MOSRTASK error             ',0  ;@@xlat

mosrtask endp

	subttl	rlsnetbios - release all netbios resources for task
	page
;======================================================================
;,fs
; rlsnetbios - release all netbios resources for task
; 
; release task and adapter netbios resources if any
; called with ds = tcb of task to release
;
; in:
;
; out:
; 
;,fe
;======================================================================

mosid	db	'NETBIOS'		;could be mosnetbios or llnetbios
idlen	equ	$-mosid

; network command block (ncb - pc net tech ref pgs 2-15, 16

ncb	struc
ncbcmd	db	0			;ncb_command
ncbret	db	0			;ncb_retcode
ncblsn	db	0			;ncb_lsn
ncbnum	db	0			;ncb_num
ncbbuf	dd	0			;ncb_buffer@
ncblen	dw	0			;ncb_length
ncbcnam db	16 dup(0)		;ncb_callname
ncbnam	db	16 dup(0)		;ncb_name
ncbrto	db	0			;ncb_rto
ncbsto	db	0			;ncb_sto
ncbpost dd	0			;ncb_post@
ncblana db	0			;ncb_lana_num
ncbcplt db	0			;ncb_cmd_cplt
ncb_rsv db	14 dup(0)		;ncb_reserve
ncb	ends

rlsnetbios:
	push	es
	push	ds
	push	di
	push	si
	push	cx
	push	bx
	push	ax
	mov	bx,ds			;remember tcb of task to release
	mgetzero ds
	lds	si,dword ptr ds:[5ch*4]
	mov	cx,ds
	or	cx,si
	jz	rnbx			;mosnetbi not loaded
	mov	di,cs
	mov	es,di
	mov	di,offset mosid
	mov	cx,idlen
	sub	si,cx
	repe	cmpsb
	jne	rnbx			;mosnetbi not loaded
	sub	sp,type ncb		;give ourselves an ncb
	mov	di,ss
	mov	es,di
	mov	di,sp
	xor	al,al
	mov	cx,type ncb
	cld
	rep	stosb
	mov	ax,bx			;tcb of task to remove
	mov	bx,sp
	mov	es:[bx].ncbcmd,0f0h
	mov	es:[bx].ncblen,ax
	int	5ch
	add	sp,type ncb
rnbx:
	pop	ax
	pop	bx
	pop	cx
	pop	si
	pop	di
	pop	ds
	pop	es
	ret

	subttl	closetask -- close all tfb's for a task, and unregister
	page
;======================================================================
;,fs
; closetask -- close all tfb's for a task, and do unregister
; 
; close all tfb's for a task.  If task has open TFB's, switch to its
; ram and switch to its stack (note the task to be removed will never
; be the current task).  while tfb's remain to be closed, set [tcbpsp]
; to psp of first tfb, and call closeall.  switch back to local task's
; stack.
; 
; This routine is also used to call the unregister handler, this allows 
; the unregister handler to be located in task memory (IE a tsr) This is done
; so that MOSNET can setup an unregister handler so that Sockets can
; be removed for the task.
; 
; in:	ds->tcb of task which owns files to close.
; 
; out:	all tfb's owned by the task will be closed & deleted.
; 
;,fe
;=====================================================================
	assume	ds:tcb,es:nothing,ss:nothing
closetask proc near
	push	ax
	push	bx
	push	cx

; switch stacks & contexts.

	mov	cx,sp			; old stack segment & pointer
	mov	ax,ss
	mov	bx,ds
	cmp	bx,ax			; only switch if stacks are different
	je	clst10			; if stack segment is what we want
	pushf
	pop	bx			; old flags
	push	ds			; new ss
	cli
	pop	ss			; switch to new task stack & tcb
	mov	sp,[tcbsp]		; new task stack pointer
	push	bx			; restore flags
	popf
clst10:
	push	ax
	push	cx			; save old stack pointer
	call	switchif		; switch to task's RAM

; the following is done for the case where lanserve owns the unreg
; function.  this function will call netbios to cancel all outstanding
; netbios commands.  netbios will call intd4fun14 to post.  when dopost
; is then called, it needs to see scbpost == the tcb of the task
; to which the post belongs (the task being removed -- which is the
; pseudo-current task thanks to the above switchif call).

	mgetscb es
	assume	es:grp
	mov	[scbpost],ss		; tell netbios post, ss == cur task

; must save and clear scbnotsl to prevent a task switch from the
; actions of the tcbunreg handler and from an int15 task switch
; which could occur during closeall.

	mov	al,'Y'
	xchg	al,[scbnotsl]
	push	ax
	push	[tcbpsp]		;#jrbi save current psp

; while the task is switched in, call the post chain to process
; anything that might be waiting.

	mov	ax,word ptr [tcbpost]
	or	ax,word ptr [tcbpost+2]
	jz	clst15
	mov	ax,ss
	mov	es,ax
	assume	es:nothing
	call	dopost
clst15:

; Updated 04/10/90 Stewart Hyde
; Move calling UNREGISTER call down to here, so that task will
; be switch in when UnRegister call is maded.
; This is done so that the Novell Shell (MOSNET) can have a 
; UnRegister Call to close its sockets

	cmp	word ptr [tcbunreg+2],0	; is unregister implemented
	je	clst20

	push	[tcbstkp]		; Bias stack for re-entrency
	sub	word ptr [tcbstkp],128	

	push	dx
	push	bp
	push	si			; save important registers
	push	di			; note ax,bx,cx,es...not save
	push	ds			; because they will be used below
	call	dword ptr [tcbunreg]	; call unregister handler
	pop	ds
	pop	di
	pop	si
	pop	bp
	pop	dx
	pop	[tcbstkp]		
clst20:
	mov	cx,[tcbtfbpf]
	jcxz	clst30			; if no more task file blocks
	mov	es,cx
	assume	es:tfb
	mov	ax,[tfbpsp]		; set current psp to file's PSP
	MSetPSP	ax
	push	cx
	push	ds			; closeall may change these
	callmos2 closeall		; close all files for this psp
	pop	ds
	pop	cx
	jmp	clst20			; next batch of files to close

; restore old stack and ram context.

clst30:
	pop	[tcbpsp]		;#jrbi restore current psp
	mov	ax,[tcbpsp]
	mov	[tcboldpsp],ax
	mgetscb es
	assume	es:grp
	pop	ax
	mov	[scbnotsl],al
	pop	cx			; old stack pointer
	pop	ax			; old stack segment
	mov	bx,ss
	cmp	ax,bx			; do we switch stacks
	je	clst40			; if they are the same, don't switch
	pushf
	pop	bx			; save flags (can't push them)
	cli
	mov	ss,ax
	mov	sp,cx			; switch to old stack
	push	bx
	popf
clst40:
	mov	ax,ss
	call	swrealram		; make sure task being remove is switch out
					; and that caller is switch in					
	call	switchif		; switch back to original task's context
clstx:
	pop	cx
	pop	bx
	pop	ax
	ret
closetask endp

	subttl remalias - removes alias drive from task if any
	page
;======================================================================
;,fs
; remalias - removes alias drive from task if any
; 
; remove the alias memory structures from system space.
; for each alias drive for task
; de-allocated alias heap sturcture
; de-allocated cdb and bdb for drive
;
; in:	ds --> tcb of task to remove
; 
; out:
;
;,fe
;=====================================================================
	assume	ds:tcb
remalias proc	near
	push	ax
	push	bx
	push	cx
	push	dx
	push	ds
	push	es
	push	ds
	pop	es
	mgetscb ds
	assume	ds:grp,es:tcb
	mov	cx,[scbbdbpf]		; get point to first bdb
remal1:
	jcxz	remal4
	mov	ds,cx
	assume	ds:bdb
	mov	cx,[bdbnext]
	cmp	[bdbalias],0		; is this an alias drive
	je	remal1
	mov	bx,es
	cmp	bx,[bdbtask]		; is this from the task to be remove
	jne	remal1

; alias found so free up its space

	push	es
	mov	es,[bdbalias]
	mov	ah,1
	call	mosheman
	pop	es
	mov	word ptr [bdbalias],0

; check for drive and remove it from cdb's

	mov	dl,[bdbid]		; get drive
	push	cx			; save next
	push	es
	push	ds
	mov	cx,[tcbcdbpf]
remal2:
	jcxz	remal3
	mov	ds,cx
	assume	ds:cdb
	mov	cx,[cdbnext]
	cmp	dl,[cdbdrive]		; is drive the one we want?
	jne	remal2
	push	ds
	pop	es
	mgetscb ds
	mov	ax,1*256 or 'C' 	; de-allocated cdb
	call	mosliman
	jmp	remal2
remal3:
	pop	es			; this was ds (but i planned to put it in es
	push	es
	mgetscb ds
	mov	ax,1*256 or 'B' 	; deallocated bdb
	call	mosliman
	pop	ds
	pop	es
	pop	cx
	jmp	remal1
remal4:
	pop	es
	pop	ds
	pop	dx
	pop	cx
	pop	bx
	pop	ax
	ret
remalias endp

	subttl	rempoll00 -- delete task which wanted to delete itself
	page
;======================================================================
;,fs
; rempoll00 -- delete task which wanted to delete itself
; 
; if scbtcbpc != ss, the task pointed to by ss will be deleted.
; used when the user requests that mos remove the current task.  the
; task is put on hold, and this function polled to find out when the
; task is ready to run again.  this function waits for the following
; condition: current task != task we want to delete.  once this is true,
; this function calls the task removal logic, which removes the task.
; this function then tells the mos next task loop that once again (and
; for the last time), the task we want to delete can't run.  The task
; will then be forgotten (and deleted) completely.
; jumps into the innards of mosrtask.
; 
; in:	ss->tcb of task we wish to delete.
; 
; out:	ah == 1 (task we want to delete can't run).
; 
;,fe
;=====================================================================
rempoll00 proc	far
	assume	ds:nothing,es:nothing,ss:tcb
	push	es
	push	ds
	push	ax
	mgetscb es
	mov	ax,ss			; address of tcb to delete
	cmp	ax,es:[scbtcbpc]
	jz	remp20			; if task to delete still running
	mov	ax,offset mos:remp10	; return address goes on first
	push	ax
	push	cx			; put cx on stack for mosrtask
	push	ds			; old ds register for mosrtask
	push	ss
	pop	ds			; point ds at the tcb too
	assume	ds:tcb,es:grp,ss:tcb
	call	rlsnetbios		; release all netbios resources, if any
	mov	[tcbslice],0		; task gets no time at all
	jmp	msrt20			; blow the task in question away
					; this call pops the return address, dx, &
					; cx register values saved above,
remp10: 				; thus leaving the stack balanced!
remp20:
	pop	ax			; restore old ah
	mov	al,1			; never activate this task again
	pop	ds
	pop	es
	ret
rempoll00 endp

mosseg	ends
	end

