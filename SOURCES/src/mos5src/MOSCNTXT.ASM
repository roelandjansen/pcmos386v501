	include page.inc
	title	moscntxt.asm - context saving and restoring

comment ^===============================================================
		development specification

 program name:	$$mos.com		assigned to: david morrow
 module name:	moscntxt		assign date: 11/01/86
 entry points:	savcntxt,rstcntxt	completed:
		switchif, getvram, getrram, getrramf
 entry from:	all over
 entry method:	call
 calls:		n/a
 purpose:	saving and restoring of memory context
 last update:	08/18/1992
========================================================================

sah 05/15/87	ega support single task

mjs 7/22/87	major cleanup and rework for non memory management
		multitasking support as well as optimizations for
		the memory managed case

sah 07/24/87	added code to handle direct port writes of setting the
		the cursor.  (lotus 123 on terminal does this). the
		int 06 logic was designed to be use with upcoming
		generalize i/o protection logic

jsm 07/29/87	fixed swrealram to unmap vidram at both b000:0 and
		b800:0 if scbvidtype is 0, 1, or 2.  swvidram would
		map this memory in in these cases before, but swrealram
		wouldn't map it out.

jsm 08/05/87	fixed swvidram to unmap vidram from last task if last
		task had more pages of vidram than new task.  also
		changed swvidram so that it would not map rom into the
		logical address space at b800:0. swvidram maps pages
		into b000:0 and b800:0, so we don't need ROM there.

sah 08/08/87	fixed rstcntxt which had incorrect register pointing
		to the tcb at time of ems and 80x87 context restoring
		this appears to be generated because of latest changes
		in context saving and restoring techniques

mjs 8/31/87	extracted context save/restore from switchgp and moved
		to swcntxt.  re-ordered the switching of context and
		task ram to insure that both are switched before
		interrupts are re-enabled.

sah 09/10/87	made changes in video saving so that it does not do the
		video saving if vidram is turn off.  this is a special
		case which vga state-saving does not use mos normal
		video context saving.

sah 09/22/87	when task that is vgavidram is switch in tcbvidram off
		and tcbstate non-zero realram will be call to unmap the
		the normal video areas

sah 09/23/87	during pamming process realram is switch in and in vga
		mode a maximum of 4 banks (16k) is unmap - to unmap the
		the video area use by the prevous task

sah 09/28/87	correct my changes in handing vgavidram because
		addtask was rebooting the computer if only the fg
		was up.

sah 09/28/87	added code for ega io protection. the following ports
		are protected if tcbstate is non-zero and tcbvideo is
		ega mode:

		   state offset    port    bytes    name
		---------------:--------:-------:--------------------
		      0 	:  3c4	 :  1	 : sequencer index
		      1 	:  3c5	 :  5	 : sequencer controller
		      6 	:  3c0	 :  2	 : attrib (+ flipflop)
		      8 	:  3c0	 :  19	 : attrib controller
		      27	:  3ce	 :  1	 : graphics controller
		      28	:  3cf	 :  9	 : graphics controller

		the io protection of these ports were designed for
		future generalization of io protection and are designed
		easy maintability.

sah 10/02/87	added functions 2 and 3 to initioptbl routine to clear
		and set the ega io protections.  also during ega io
		protection, code was added so that ega io protection
		when the value is actual out the port during ega
		simulation.

sah 10/05/87	must have ega simulation of reads for ports 3c0-3cf too
		includes 3c0 support so that tcbegapal array is also
		updated so that ega restore state will function
		correctlly.

sah 10/06/87	applied jims fix for 3x5 handling and communications

sah 10/15/87	added debuging code for int 06 operations.
		corrected simulation of port 61 for sidekick
		following actions are now taking for port 61:
			input:
			    al = tcbprt61 and 03fh  (high bit clear)
				 or bios will think we have a parity
				 error	also bit 6 is also clear or
				 ps/2 might think we have a channal
				 error.
			output:
			    bits 4 & 5 are left alone

sah 10/25/87	added intelligence to io protection setting logic so
		that io protection can be put on hold. also conditional
		assembly of mosdebug routine to display io init info was
		created. 3c0 trapping was corrected.

jrb 10/26/87	if tcbvideo for current partition indicates hg1 or hg2
		then we retain protection on 3b4, 3b5, 3b8, 3ba, 3bf
		but allow master console access to those ports

jrb 10/29/87	changes to support ali card

jrb 11/05/87	use allowhio, denyhio to control access by mos to the
		hercules ports instead of scbhinmc

sah 11/12/87	corrected io protection for word outs to ports, this
		corrected the ega problems with lotus 123 and ms word
		added 3c1 to ega io protection list (which is a mirror
		of 3c0)

sah 11/15/87	added inmos flag for sidekick(+) support to rstcntxt

sah 11/18/87	made corrections to swrealram for ega and autocad
		where it will switch realram of 128k a000-c000h

sah 12/03/87	save and restore tcbinmos from scbinmos during savcntxt
		and rstcntxt.

sah 12/15/87	io protection on port 3d8 for cga tasks is now supported
		autocad cga driver requires mos to trap the value of 3d8
		because it goes into graphics mode by directly outputing
		to the video ports.

jrb 12/17/87	took out two sti's in rstcntxt

mjs 1/17/88	overhauled the int6 logic - it was a mess.
		also, commented out two lines with ";@#@" where the
		bit for port 3d8 was being set in the iop for the sake
		of autocad.  this was cuasing 123 to go into 40 column
		mode.  will need to find a better fix for autocad.

sah 01/21/88	change scbseg and zero seg to mgetxxx macros
		modify rstcntxt and savcntxt to use 40:03fc value  for
		restoring and saving interupt tables
sah 01/25/88	replace scbseg reference with mo2seg reference

rbr/sah 02/20/88  move ddt code to mo2 group.

mjs 3/30/88	overhauled the video switching procedures - they were
		getting messy and had to be modified to allow serial
		irq's to be able to switch in video and know how to
		restore it properly.  see the file
		\mos.dir\utils.dir\vidmods.doc on the server for info.

sah 03/31/88	add far routine access to mapvmf and mapvsf routines
		for sunriver support.  added physical remap functions
		to video map routines.	this is necessary because the
		sunriver ega terminals require video mapping from the
		f00,000h region. change swrealram so that it calls
		terminal driver function ffh to switch realram in

mjs 4/24/88	bug fixes to serial irq and video logic.

mjs 5/2/88	various mods to secure the video logic against video
		switching serial irq's.

mjs 5/16/88	added skipswvs to cause switchgp to skip the call to
		swvidsave.  this is used in the serial irq logic.

sah 05/17/88	made jim's correction for swrealram where it would make
		a ffh call if no task was viewing it. sorry about that!
		additional fixes for switchgp for fixing the problem
		with non-mm case and adding a background task

mjs 6/6/88	corrected switching action in switchgp to accomodate
		the new cache logic which uses the video save area to
		map in cache buffers and depends on scbmastv being
		maintained properly.

jrb 6/13/88	added code to swrealram to switch out the last guy
		switched in with the new ddt call 0feh
		added 3c2 trap

sah 06/15/88	correct swvidram for ega context switching.  corrected
		problem with ega graphics dying if another task is up
		and not in vmode of ega or non-mm case

mjs 7/2/88	took out mmparm struc and added 'inlude macros.inc' for
		access to the common mmparm struc.

rdg 07/06/88	gated access to the console device drivers to prevent
		corruption of the serial data stream being sent to a
		terminal by changing the calls to the console device
		driver from a call dword ptr [si] to call ddtcallf

sah 07/12/88	corrected vidram problem with ega and terminal. my
		06/15/88 update did not complete correct the problem.
		also clean up this module since we have pvcs.

sah 07/21/88	added logic so that if invalid instruction occurs and
		periscope is install that periscope will pop up at
		invalid instruction.  thanks to bret salter.

sah 07/29/88	added logic to call scbdump is invalid instruction
		occurs. this will allow us to make a driver to dump
		important information out.  ah = 2

jrb 09/15/88	swvidram wasn't setting the segment to unmap when
		    it determined that the new vidram was smaller
		    or a different segment
		fixed - pamswitch from cga partition into a mono
		    vna partition w/ a vna workstation looking at it,
		    a dir would lock up
		fixed - engineering problem with lock up switching
		    ega into vna partition

mjs 09/23/88	re-worked swealram to match new bank switching method.

sah 09/23/88	port protection on port 21h implemented, currently only
		use when we call int 9 intercept so that the intercept
		will not reenable int 9 like ms-windows.

mjs 09/27/88	corrected problems in the way the swvidram procedure
		was unmapping the video memory area.

jrb 09/28/88	changed mapvma to map/unmap video buffer & alternate
		video buffer if vtype < 3 - also took same logic out
		of swvidram - this fixes the problem of no display
		after adding a task w/ vtype < 3

sah 10/02/88	in mapvma, if vtype = 5 and pages map in <= 4 then do
		alternate map.	this is necessary if cga task is viewing
		mono task. it would be nice to find a way to do mapping
		without worrying about mapping in alternate map

sah 10/10/88	move io protection logic to new module mosint06 so that
		logic can be group together.

sah 10/13/88	added saving and restoring of scbcrit to task tcb

sah 10/21/88	major change to task context logic so that switchgp
		no longer depends on interupts being disable during
		the whole task switch.	also made optimizations to
		rstcntxt for memory-manage case of vectors.
		optimizations on most of this logic has been made.

sah\mjs 10/26/88 correction rstcntxt for bug in assembler.

mjs 11/14/88	added forcevsa variable so new pamswitching logic from
		11/11/88 can force switchgp to call swvidsave.

sah  12/14/88	corrections to mapvma code for sunriver. 09/28/88
		update cause problem with sunriver driver with handling
		alternated video map area.

sah 03/29/89	correction for context saving of npx, also made switch
		more efficient.

mjs 05/17/89	changed the order of testing the skipswvs and forcevsa
		flags in the switchgp procedure.  the skipswvs flag
		must have the highest priority to prevent video
		switching irq's from affecting the video save area.
		this change corrects a video corruption problem when
		a pamswitch is done while irq's are being generated.

sah 06/08/89	added function mapvma function 3 for a list base call
		to memory manage for faster mapping of video on the
		sunriver workstations.

sah 07/07/89	corrected handling of npx (remove extra fwait)

sah 07/18/89	remove partial context flags which appear to be unused
		so that mos does not have to go though the additional
		overhead of managing this flag scbcntfg.

sah 07/26/89	added context switching of scbfar38 so that tsr (ie
		shells could intercept services interupt) nothing uses
		this but forsee needs for this in the future.

mjs 12/19/98	correct mouse droppings problem by insuring that 
		scbtcbvr was always set to -1 when the video state 
		was in transition.

sah 03/05/90	speeded up context switching via 32 moves.

mjs 06/18/90	modified call to list based mapping function to use
		ah = 0dh instead of 0ah.  for sunriver systems, the
		kernel and 386 memdev must match.

SAH 11/01/90	Change EMS Context switching into generitic context
	        switching calls for EMS 4.0 driver

SAH 03/12/91	Must save 40:17 into TCBKSHF so that master console
                INT 9 can know current state of int 9

================ 5.01 Kernel Ends Here ====================================

mjs 05/22/92	mask off irq6 and irq14 during switchtask to prevent
		crash when dbts is active, disk irq occurs during 
		switchtask and one or more task based i15 intercepts
		exist.  noticed by brooks drugs/comcotec.
		updat501.sys version 0.06

mjs 08/18/92	clean up segment declarations

======================================================================^

.xlist
;	include moscntxt.pub
	include options.inc
	include group.inc
	include mosregs.inc
	include macros.inc

tcb	segment at 1234h
	include mostcb.inc
tcb	ends

gdata	segment
	include mosscbex.inc		; specify all scb items as external
	extrn	skipswvs:byte, forcevsa:byte

altmap	db	'N'			; 'Y' is do alternate map

gdata	ends
.list

;======================================================== mos segment
if 0 eq 0
segment_num = 1
endif
mosseg	segment
	assume	cs:mos,ds:grp,es:nothing,ss:tcb

	extrn	mo2seg:word,scbfree:word,sbios:word
	extrn	nosbuf:far,hex2asc:near
	extrn	isega:near,okswitch:near,noswitch:near
	extrn	ddtcallf:near		; console device driver gating	; rg8188

if	mdebug eq 1
	extrn	mosdebug:near
endif

	public	savcntxt, rstcntxt, savtable

;=================== context switching procedures ======================

;-----------------------------------------------------------------------
; this is the context savtable
;-----------------------------------------------------------------------

public savtable
savtable label word


; updated 10/25/88 sah this table is now only use in mositask
; and mosinit, it is now directly code inline in savcntxt and
; rstcntxt for speed. if you plan to mess with this table, make
; sure you remember to make changes in context routines.

; think you'RE GOING TO MESS WITH THIS PART OF THE TABLE ???
; then see the note below !!!

;		 ofs   seg  size
;		----- ----- ----
	dw	0000h,0040h,015 	; i/o addresses, flags, ram size

; the above two table entries cause the value for 40:13 to
; appear at offset 013h in a compressed context save area.  if this
; position should ever change, must also change the procedure
; upd4013 in the module mositask.asm  (mjs  7/21/87)

	dw	0049h,0040h,015 	; bios video display data area
	dw	0071h,0040h,002 	; bios break bit, ega reset
	dw	0084h,0040h,003 	; ega rows, points, info
	dw	0097h,0040h,001 	; bios keyboard flag
	dw	00a8h,0040h,002 	; ega parameter table pointer
	dw	0200h,0040h,064 	; type ahead buffer
	dw	0000h,0050h,016 	; ega status and for basic
	dw	10 dup(-1,-1,-1)	; end of list marker

	subttl savcntxt - save memory context
	page
;======================================================================
;,fs
; savcntxt - save memory context
;
; this routine will save the contents of memory as specified 
; by the 'SAVTABLE' data area, into the tcb context save area.
; updated 07/18/88 sah for faster execution and no-cli 
; dependency.  this code nolonger depends on interupts being 
; disable and will clear interupts during its critical section. 
; if any additions to this code, make it as fast as possiable. 
; this code and rstcntxt is the bottle neck of the mos kernel 
; and needs to be as fast as possiable.
;
; in:	ax -> tcb
;	ds -> grp
;
; out:	
;
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:nothing
savcntxt:
	push	bx
	push	ds
	push	es
	mov	es,ax			; tcb to save
	assume	es:tcb,ds:grp
	push	es
	pushf
	test	[scbmmfea],10h		;jsm 11/17/87
	jz	savcont
	jmp	savloopx		; if no mm that can handle small blocks
savcont:
	cld				; then copy into smp block, else skip
	xor	di,di
	mov	es,[tcbcntxpt]		; segment of smp context save area
	assume	es:nothing
	mov	cx,512
	cmp	[scbreg32],'Y'
	jne	savcnt286

; handle context saving for 386 base machines here

	shr	cx,1
	mgetzero ds
	assume	ds:nothing
	xor	si,si
	cli
	db	66h
	rep	movsw
	mov	di,512*2
	mov	si,400h
	mov	cx,7			; move 15 words at 40:0
	push	cx
	db	66h
	rep	movsw			; move 7 dwords (32 bit)
	movsw				; = addition word for 15 words
	pop	cx
	mov	si,449h 		; move 15 words at 40:49
	db	66h
	rep	movsw			; move 7 dwords (32 bit)
	movsw				; = addition word for 15 words
	mov	si,471h
	db	66h
	movsw				; move 2 words at 40:71
	mov	si,484h
	movsw
	db	66h
	movsw				; move 3 words at 40:84
	mov	si,497h
	movsw				; move 1 word at 40:97
	mov	si,4a8h
	db	66h
	movsw				; move 2 words at 40:a8
	mov	si,600h
	mov	cx,64/2 		; move 64 words at 40:200
	db	66h
	rep	movsw
	mov	si,500h
	mov	cx,16/2 		; move 16 words at 50:0
	db	66h
	rep	movsw
	jmp	short savloopx
savcnt286:
	mgetzero ds
	assume	ds:nothing
	xor	si,si
	cli
	rep	movsw
	mov	di,512*2
	mov	si,400h
	mov	cx,15			; move 15 words at 40:0
	rep	movsw
	mov	cx,15
	mov	si,449h 		; move 15 words at 40:49
	rep	movsw
	mov	si,471h
	movsw
	movsw				; move 2 words at 40:71
	mov	si,484h
	mov	cx,3
	rep	movsw			; move 3 words at 40:84
	mov	si,497h
	movsw				; move 1 word at 40:97
	mov	si,4a8h
	movsw				; move 2 words at 40:a8
	movsw
	mov	si,600h
	mov	cx,64			; move 64 words at 40:200
	rep	movsw
	mov	si,500h
	mov	cx,16			; move 16 words at 50:0
	rep	movsw
savloopx:
	popf
	pop	es			; save ems page info if ems present
	assume	es:tcb
	mgetscb ds
	assume	ds:grp
	cmp	word ptr [scbsave+2],0	; Context Store Routine Installed
	je	nosvems
	call	[scbsave]		; call context store routine	
nosvems:
	pushf
	cli
	mov	bl,[scbcrit]		; sah save current critical flag
	mov	[tcbcrit],bl
	mov	bl,[scbinmos]		; sah save current inmos into task
	mov	[tcbinmos],bl		; sah space
	mov	bx,word ptr [scbfar38]	; save current scbfar38 into tcbtsk38
	mov	word ptr [tcbtsk38],bx
	mov	bx,word ptr [scbfar38+2]; this is so we can support task
	mov	word ptr [tcbtsk38+2],bx; int d4 intercepts
	MGetZero ds
	assume  ds:nothing
	mov	al,byte ptr ds:[417h]
	mov	[tcbcon417],al
	popf
	pop	es
	pop	ds
	pop	bx
	ret

	subttl rstcntxt - restore memory context
	page
;======================================================================
;,fs
; rstcntxt - restore memory context
;
; this routine will restore the contents of memory as specified 
; by the 'SAVTABLE' data area, from the tcb context save area.
; updated 07/18/88 sah for faster execution and no-cli 
; dependency.  this code nolonger depends on interupts being 
; disable and will clear interupts during its critical section. 
; if any additions to this code, make it as fast as possiable. 
; this code and rstcntxt is the bottle neck of the mos kernel 
; and needs to be as fast as possiable.
;
; in:	ax -> tcb
;	ds -> grp
;
; out:	
;
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:nothing
rstcntxt:
	push	bx
	push	ds
	push	es
	assume	ds:grp
	pushf
	cmp	[scbsw87],'Y'
	jne	skip87
	push	ds
	mov	ds,[scbtcbpc]
	assume	ds:tcb
	mov	ds,[tcb87sav]

	.8087

; we will now restore the 8087 state to state which task we are going
; to left it, we will also turn off interupts here so that we can make
; sure that we don't get interupted between fsave and setting
; scbtcbpc to tcb pass in ax. this is very important since fsave will
; reset the npx state as if finit does and another we must keep to
; save and restore together because they mark critical task change of
; 8087.

	cli
	fsave	ds:[0000h]		; save the npx state for last task
	mov	ds,ax			; ax has tcb segment for next task
	mov	ds,[tcb87sav]		; access save area
	frstor	ds:[0000h]		; restore the npx state for next task
	pop	ds
	assume	ds:grp
skip87:
	cli
	mov	[scbtcbpc],ax
	test	[scbmmfea],10h		; have mm that can handle small blocks ?
	jnz	$+5
	jmp	nommrst 		; if no mm, copy from smp block
	mov	es,ax
	assume	es:tcb
	mov	bx,[tcbcntxpt]
	push	es			; save area
	push	ds
	push	ax
	mov	ax,ds
	mov	es,ax
	mov	ds,[sbios]		; access bios segment
	assume	ds:nothing,es:grp

; please note the use of di in the following, for maximum speed
; since mov instruction is faster than stos on 386/486 cpus

	lea	di,[scbrstcnt]
	cld
	mov	ax,ds:[003eh]		; must transplant current bios timer
	mov	es:[di],ax
	mov	ax,ds:[0040h]		; and disk data
	mov	es:[di+2],ax
	mov	al,ds:[0042h]
	mov	es:[di+4],al
	mov	ax,ds:[006ch]
	mov	es:[di+5],ax
	mov	ax,ds:[006eh]
	mov	es:[di+7],ax
	mov	al,ds:[0070h]
	mov	es:[di+9],al
	add	di,10
	mov	si,0074h
	mov	cx,6			; move 12 bytes
	rep	movsw			; save 40:74 through 40:7f
	mov	si,008bh
	mov	cx,11			; move 22 bytes
	rep		movsw		; save 40:8b through 40:a0
	mov	ax,es
	push	ds
	pop	es
	mov	ds,ax
	assume	ds:grp,es:nothing
	push	es
	mgetzero es
	assume	es:nothing
	mov	ah,3
	mov	cx,1			; map a 4k segment
	call	[scbmmsub]
	pop	es

; please note the use of si in the following, for maximum speed
; since mov instruction is faster than lods on 386/486 cpus

	lea	si,[scbrstcnt]
	mov	ax,ds:[si]
	mov	es:[003eh],ax
	mov	ax,ds:[si+2]
	mov	es:[0040h],ax
	mov	al,ds:[si+4]
	mov	es:[0042h],al
	mov	ax,ds:[si+5]
	mov	es:[006ch],ax
	mov	ax,ds:[si+7]
	mov	es:[006eh],ax
	mov	al,ds:[si+9]
	add	si,10
	mov	es:[0070h],al
	mov	di,074h
	mov	cx,6			; move 12 bytes
	rep	movsw			; save 40:74 through 40:7f
	mov	di,08bh
	mov	cx,11			; move 22 bytes
	rep	movsw			; save 40:8b through 40:a0
	pop	ax
	pop	ds
	pop	es
	assume	es:tcb
	jmp	rstloopx
nommrst:
	cld
	mov	ds,ax			; bug - in non mm or gizmo type context switch,
	mov	es,ax			; would not have tcb segment in es after
	push	es			; this loop
	assume	ds:tcb
	mov	ds,[tcbcntxpt]		; pointer to smp block
	assume	ds:nothing
	mgetscb es
	assume	es:grp
	mov	cx,512
	xor	si,si
	mgetzero es
	assume	es:nothing
	xor	di,di
	rep	movsw
	mov	si,512*2
	mov	di,400h
	mov	cx,15			; move 15 words to 40:00
	rep	movsw
	mov	cx,15
	mov	di,449h
	rep	movsw			; move 15 words to 40:49
	mov	di,471h
	movsw				; move 2 words to 40:71
	movsw
	mov	di,484h
	mov	cx,3			; move 3 words to 40:84
	rep	movsw
	mov	di,497h
	movsw				; move 1 word to 40:97
	mov	di,4a8h
	movsw				; move 2 words to 40:a8h
	movsw
	mov	di,600h
	mov	cx,64			; move 64 words to 40:200
	rep	movsw
	mov	di,500h
	mov	cx,16			; move 16 words to 50:00
	rep	movsw
	pop	es			; mjs 12/4/87
rstloopx:
	assume	es:tcb
	mgetscb ds
	assume	ds:grp
	cmp	word ptr [scbrestore+2],0	; Context Restore Routine installed
	je	norsems 		; no
        call	[scbrestore]		; call Context Restore routine
norsems:
	mov	bl,[tcbcrit]		; sah restore critical flag
	mov	[scbcrit],bl
	mov	bl,[tcbinmos]		; sah restore inmos flag from
	mov	[scbinmos],bl		; sah task space
	mov	bx,word ptr [tcbtsk38]	; save current tcbtsk38 into scbfar38
	mov	word ptr [scbfar38],bx
	mov	bx,word ptr [tcbtsk38+2]
	mov	word ptr [scbfar38+2],bx
	popf				; pop orginal flags off stack
	pop	es
	pop	ds
	pop	bx
	ret

	subttl swcntxt - switch in a task's context
	page
;======================================================================
;,fs
; swcntxt - switch in a task's context
;
; all registers are preserved
; this proc does not clear or set interrupts
; this up to the caller.
;
; in:	bx -> tcb of new task
;	ds -> grp
;
; out:	[scbtcbpc] is updated
;
;,fe
;======================================================================
	assume	ds:grp,es:nothing,ss:nothing
public	swcntxt
swcntxt:
	cmp	bx,[scbtcbpc]		; context already switched in ?
	je	swcn1			; no, skip all this
	push	ax
	push	cx
	push	si
	push	di
	mov	ax,[scbtcbpc]		; save old region context
	call	savcntxt
	mov	ax,bx			; set new "current" tcb
	call	rstcntxt		; restore new context
	pop	di
	pop	si
	pop	cx
	pop	ax
swcn1:
	ret

	subttl swtaskram - swap in task ram
	page
;======================================================================
;,fs
; swtaskram - swap in task ram
;
; all registers are preserved
; this proc does not clear or set interrupts - this up to 
; the caller.  this routine will swap in task ram by using up 
; to 4 contiguous blocks of allocated memory.  speed is important 
; since this routine will be called with interrupts disabled.
;
; in:	es -> tcb
;	ds -> grp
;
; out:	
;
;,fe
;======================================================================
	assume	ds:grp,es:tcb,ss:nothing
public swtaskram
swtaskram:
	push	ax
	push	bx
	push	cx
	push	dx
	push	si
	pushf
	xor	si,si			; starting index
	mov	cx,4			; up to 4 blocks of ram used
	mov	dx,[scbfree]		; initial switching address (logical)
	mov	ax,es			; get tcb pointer
	cmp	[scbmmfg],'Y'		; have mm ?
	jne	swt130
	cli
	cmp	[scbtcbps],ax		; already switched in ?
	je	swt140
	push	ax			; save scbtcbpc value
swt100:
	push	cx
	mov	cx,[tcbmmpgs+si]	; get # pages for this block
	or	cx,cx			; end?
	jnz	swt110
	pop	cx			; yes, no more blocks
	jmp	swt120
swt110:
	mov	bx,[tcbmmhdl+si]	; get handle
	push	es
	mov	es,dx			; start mapping at free segment
	assume	es:nothing
	add	dh,cl			; calc new mapping address for next page
	mov	ah,3			; remap fun
	call	[scbmmsub]
	pop	es
	assume	es:tcb
	add	si,2			; next table entry
	pop	cx
	loop	swt100			; do up to 4 blocks
swt120:
	pop	ax			; get scbtcbps value
swt130: 				; no memory management case
	mov	[scbtcbps],ax
swt140:
	popf
	pop	si
	pop	dx
	pop	cx
	pop	bx
	pop	ax
	ret

	subttl mapvmf - far call access to mapvma
	page
;======================================================================
;,fs
; mapvmf - far call access to mapvma
;
; this routine is accessed by the scb var scbmapvmf.  it 
; provides external video drivers, like sunriver, with memory
; management services.
;
; in:	same as mapvma (except that ds doesn't matter)
;
; out:	same as mapvma (except ds is preserved)
;
;,fe
;======================================================================
public mapvmf
mapvmf:
	push	ds
	mgetscb ds
	call	mapvma
	pop	ds
	retf

	subttl mapvsf - far call access to mapvsa
	page
;======================================================================
;,fs
; mapvsf - far call access to mapvsa
;
; this routine is accessed by the scb var scbmapvsf.  it 
; provides external video drivers, like sunriver, with memory
; management services.
;
; in:	same as mapvsa (except that ds doesn't matter)
;
; out:	same as mapvsa (except ds is preserved)
;
;,fe
;======================================================================
public	mapvsf
mapvsf:
	push	ds
	mgetscb ds
	call	mapvsa
	pop	ds
	retf

	subttl mapvma - low level proc to map into video memory area
	page
;======================================================================
;,fs
; mapvma - low level proc to map into video memory area
;
; all registers are preserved
;
; this is a simple, low level mapping function for the vma
; (video memory area).  use swvidram and swrealram as the high
; level interface.  (e.g. do all special case testing there -
; not here!!) for mapping (al = 1) use di = 0 if no second block
; and [scbvmacnt+2] will be set to 0.  for physical mapping (al
; = 2), parms are the same as mapping except physical handle is
; calculate from physical segment.  e.g. segment f00,000h =
; 0f00h (this is example use by sunriver driver)
; 
; updated 10/25/88 sah move jrb's changes for alternate video map
; area work inside routine for lest overhead. future additions
; could include list base call so that one call could be made to
; memory manager instead of two.
; 
; this proc does not clear or set interrupts - that's up to the
; caller.
; 
; updated 06/08/89 sah to include list base mapping access for
; faster access for sunriver work stations. sunriver driver use
; this call to map video.
;
; input for unmap:
;	al = 0 to unmap
;	dx = segment to start unmapping from
;	cx = unmapping page count
;	ds -> grp
;
; input for map:
;	al = 1 to map
;	dx = segment to start mapping to
;	bx = 1st handle, cx = 1st page count
;	si = 2nd handle, di = 2nd page count
;	ds -> grp
;
; input for physical remap
;	al = 2 for physical remap
;	dx = segment to start mapping to
;	bx = 1st physical handle, cx = 1st page count
;	si = 2nd physical handle, di = 2nd page count
;	ds -> grp
;
; input for list base mapping
;	al = 3 for list base mapping
;	cx = number of list base records
;	bx = segment of structure to get list
;	dx = offset of structure to get list
;	ds -> grp
;
; out:	
;
;,fe
;======================================================================
	assume	ds:grp,es:nothing,ss:nothing
public mapvma
mapvma:
	push	ax
	push	bx
	push	cx
	push	dx
	push	es
	pushf
	cmp	al,3
	jne	notmlist

; handle the case of list base mapping calls

	mov	[scbvmaal],ax
	mov	ah,0dh			; use list base mapping call
	mov	es,bx
	push	di
	mov	di,dx			; es:di -> list structure
	cli
	call	[scbmmsub]
	pop	di
	jmp	short mapvm2
notmlist:

; set aternate map flag

	push	ax
	mov	ah,'N'
	mov	al,[scbvtype]
	and	al,7fh
	cmp	al,5			; is this vtype of 5
	jne	mapvm0
	cmp	cx,4			; page greater than 4
	ja	mapvm0b 		; don't do alternate mapping
	jmp	short mapvm0a
mapvm0:
	cmp	al,3			; is this vtype above 3
	ja	mapvm0b
mapvm0a:
	mov	ah,'Y'
mapvm0b:
	cli
	mov	[altmap],ah		; store flag
	pop	ax
	mov	[scbvmaseg],dx
	mov	[scbvmaal],ax
	or	al,al
	jnz	mapvm1
	mov	word ptr [scbvmacnt],cx ; record pages unmapped
	mov	ah,4			; unmap real ram
	call	tempmap
	jmp	short mapvm2
mapvm1:
	mov	ah,3
	cmp	al,1			; sah is that a map call
	je	mapvm1a 		; sah yes
	mov	ah,5
	cmp	al,2			; sah is this a physical remap
	je	mapvm1a 		; sah no...
	jmp	mapvm2			; sah caller made an error...do nothing
mapvm1a:
	push	ax			; sah save map type
	call	tempmap
	pop	ax			; sah get mapping type
	mov	[scbvmahdl],bx
	mov	[scbvmacnt],cx
	mov	[scbvmacnt+2],di
	or	di,di			; is there a second bank?
	jz	mapvm2
	mov	[scbvmahdl+2],si
	add	dh,cl			; calc new mapping address
	mov	bx,si
	mov	cx,di
	call	tempmap
mapvm2:
	popf
	pop	es
	pop	dx
	pop	cx
	pop	bx
	pop	ax
	ret

	subttl tempmap - temporary helper for mapvma
	page
;======================================================================
;,fs
; tempmap - temporary helper for mapvma
;
; this routine is only tempory until we can have a list based
; call to make it faster.
;
; in:	al = function number
;	cx = bank count
;
; out:	
;
;,fe
;======================================================================
tempmap:
	cmp	[altmap],'Y'		; do we wish to do alternate map
	jne	tempmap1
	cmp	al,1			; is this function 00 or 01h
	ja	tempmap1
	cmp	cx,8			; is size > 32k then don't do alternate map
	ja	tempmap1		; or you be mapping onto code
	push	ax
	push	bx
	push	cx
	push	dx
	push	es
	xor	dx,0800h
	mov	es,dx
	call	[scbmmsub]		; map in alternate
	pop	es
	pop	dx
	pop	cx
	pop	bx
	pop	ax
tempmap1:
	mov	es,dx
	call	[scbmmsub]		; map in requested
	ret

	subttl mapvsa - low level proc to map into video save area
	page
;======================================================================
;,fs
; mapvsa - low level proc to map into video save area
;
; all registers are preserved
;
; this is a simple, low level mapping function for the vsa
; (video save area).  use swvidsave as the high level interface.
; (e.g. do all special case testing there - not here!!) for
; mapping (al = 1) use di = 0 if no second block and
; [scbvsacnt+2] will be set to 0.  for physical mapping (al =
; 2), parms are the same as mapping except physical handle is
; calculate from physical segment.  e.g. segment f00,000h =
; 0f00h (this is example use by sunriver driver)
; 
; this proc does not clear or set interrupts - this up to the
; caller.
;
; input for unmap:
;	al = 0 to unmap
;	cx = unmapping page count
;	ds -> grp
;
; input for map:
;	al = 1 to map
;	bx = 1st handle, cx = 1st page count
;	si = 2nd handle, di = 2nd page count
;	ds -> grp
;
; input for physical remap
;	al = 2 for physical remap
;	bx = 1st physical handle, cx = 1st page count
;	si = 2nd physical handle, di = 2nd page count
;	ds -> grp
;
; out:	
;
;,fe
;======================================================================
	assume	ds:grp,es:nothing,ss:nothing
public mapvsa
mapvsa:
	push	ax
	push	bx
	push	cx
	push	dx
	push	es
	pushf
	cli
	mov	dx,[scbmastv]
	mov	es,dx
	mov	[scbvsaal],ax
	or	al,al
	jnz	mapvs1
	mov	word ptr [scbvsacnt],cx ; record pages unmapped
	mov	ah,4			; unmap real ram
	call	[scbmmsub]
	jmp	mapvs2
mapvs1:
	mov	ah,3			; map into video save area
	cmp	al,1
	je	mapvs1a 		; sah test for remap call
	mov	ah,5
	cmp	al,2
	je	mapvs1a 		; sah test for physical remap call
	jmp	mapvs2			; sah caller made an error...do nothing
mapvs1a:
	push	ax			; sah save function
	call	[scbmmsub]
	pop	ax			; sah get function
	mov	[scbvsahdl],bx
	mov	[scbvsacnt],cx
	mov	[scbvsacnt+2],di
	or	di,di			; is there a second bank?
	jz	mapvs2
	mov	[scbvsahdl+2],si
	add	dh,cl
	mov	es,dx			; calc new mapping address
	mov	bx,si
	mov	cx,di
	call	[scbmmsub]		; map second bank
mapvs2:
	popf
	pop	es
	pop	dx
	pop	cx
	pop	bx
	pop	ax
	ret

	subttl swrealram - make 'Real' video ram addressable
	page
;======================================================================
;,fs
; swrealram - make 'Real' video ram addressable
;
; in:	ax -> tcb for bank switch test
;
; out:	
;
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:nothing
public	swrealram
swrealram:
	push	ax
	push	ds
	mov	ds,ax
	assume	ds:tcb
	mov	ax,[tcbscrdd]
	or	ax,ax
	jz	swr010			; skip if nobody viewing the task
	mov	ds,ax
	mov	ah,0ffh
	push	si
	lea	si,[tcbcondd]		; then call the ddt to bank it in
	pushf
	cli
	call	ddtcallf		; check if busy and then call	; rg8188
	popf
	pop	si
swr010:
	pop	ds
	pop	ax
	ret

	subttl swvidram - switch in vidram
	page
;======================================================================
;,fs
; swvidram - switch in vidram
;
; all registers are preserved
;
; this routine will swap in task video ram by using up to 
; 2 contiguous blocks of allocated memory.
; speed is important since this routine will be called 
; with interrupts disabled.
; this proc does not clear or set interrupts.
; this up to the caller.
;
; in:	es -> tcb
;	ds -> grp
;
; out:	
;
;,fe
;======================================================================
	assume	ds:grp,es:tcb,ss:nothing
public	swvidram
swvidram:
	push	ax
	push	bx
	push	cx
	push	dx
	push	si
	push	di
	pushf
	test	[scbmmmod],80h		; if no mm, got no business in here
	jz	swd120c 		; sah
	test	[tcbvram],1		; if using vidram skip the tcbstate test
	jnz	swd150
	cmp	[tcbstate],0
	je	swd120			; exit if vgavidram
	mov	ax,es
	call	swrealram		; switch in real video memory
swd120c:				; sah
	jmp	swd120
swd150:
	mov	ax,es
	cli
	cmp	[scbtcbvr],ax		; skip all this if already switched in
	je	swd120
	cmp	[scbvmaseg],0		; if something has been mapped in then
	je	swd90
	mov	dx,[scbvmaseg]
	mov	si,[tcbvmpgs]
	add	si,[tcbvmpgs+2] 	; calc # of pages to be mapped in
	mov	cx,[scbvmacnt]
	add	cx,[scbvmacnt+2]	; and # of pages presently mapped in
	cmp	cx,si
	ja	swd80			; if presently have more pages mapped in
	cmp	dx,[tcbvidw2]		; or mapped into a different starting seg
	je	swd90
swd80:
	push	ax
	xor	al,al
	call	mapvma			; then unmap the vma first to 'clean up'
	pop	ax
swd90:
	mov	[scbtcbvr],ax		; record last 'normal' vidram mapping
	mov	bx,[tcbvmhdl]
	mov	cx,[tcbvmpgs]
	mov	si,[tcbvmhdl+2]
	mov	di,[tcbvmpgs+2]
	mov	dx,[tcbvidw2]
	mov	al,1
	call	mapvma			; map in vidram
swd120:
	popf
	pop	di
	pop	si
	pop	dx
	pop	cx
	pop	bx
	pop	ax
	ret

	subttl swvidsave - map in the video save area
	page
;======================================================================
;,fs
; swvidsave - map in the video save area
;
; this proc does not clear or set interrupts.
; this up to the caller.
;
; in:	es -> tcb
;	ds -> grp
;
; out:	
;
;,fe
;======================================================================
	assume	ds:grp,es:tcb,ss:nothing
public swvidsave
swvidsave:
	push	ax
	push	bx
	push	cx
	push	dx
	push	di
	push	es
	test	[scbmmfea],80h		; if no mm, just do [scbmastv] update
	jz	swv100
	mov	ax,es
	test	[tcbvram],1		; exit if have mm but vidram is not active
	jz	swv110
	cmp	[scbtcbvs],ax		; exit if already switched in
	je	swv110
	pushf
	cli
	mov	[scbtcbvs],ax		; record last 'normal' video save mapping
	mov	bx,[tcbvidh1]
	mov	cx,[tcbvidp1]
	cmp	cx,[scbmastp]
	jbe	swv90
	mov	cx,[scbmastp]		; limit to actual size
swv90:
	mov	dx,[scbmastv]
	xor	di,di
	mov	al,1
	call	mapvsa			; map in the video save area
	popf
	jmp	swv110
swv100:
	mov	ax,[tcbbegad]		; for non mm case, the video save area is
	mov	[scbmastv],ax		; at the start of the task ram space.
	mov	[scbtcbvs],ax
swv110:
	pop	es
	pop	di
	pop	dx
	pop	cx
	pop	bx
	pop	ax
	ret

	subttl switchif - switch context to task if needed
	page
;======================================================================
;,fs
; switchif - switch context to task if needed
;
; this proc does not clear or set interrupts.
; this up to the caller.
;
; in:	ss -> tcb
;
; out:	
;
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:tcb

public	skipsw
skipsw	db	'N'			; used by mositask

public	switchif
switchif:
	cmp	[skipsw],'Y'
	je	swfout
	push	ax
	mov	ax,ss			; tell switchgp what we want
	call	switchgp		; and transfer to switchgp code
	pop	ax
swfout:
	ret

	subttl switchtask - switch task space and context
	page
;======================================================================
;,fs
; switchtask - switch task space and context
;
; this routine was added so that code outside the moscntxt
; (outside the lowlevel kernel) can call a standard controlable
; routine to switch both the task space and context in.
;
; in:	ds -> grp
;	es -> tcb to switch in.
;
; out:	ax = entry es (needed by switchgp)
;
;,fe
;======================================================================
	assume	ds:grp,es:tcb,ss:nothing
public	switchtask
switchtask:

; irq6 and irq14 must be masked off during task ram and context 
; switching to prevent a crash when dbts is active and the disk
; irq causes an i15f91 and one or more tasks have a task based
; i15 intercept.

	in	al,021h			
	push	ax
	or	al,40h			; mask off irq6
	out	021h,al
	in	al,0a1h			
	push	ax
	or	al,40h			; mask off irq14
	out	0a1h,al
	mov	ax,es
	call	swtaskram
	mov	bx,ax
	call	swcntxt
	pop	ax
	out	0a1h,al			; restore irq14
	pop	ax
	out	021h,al			; restore irq6
	mov	ax,es
	ret

	subttl switchgp - switch context to task (general purpose)
	page
;======================================================================
;,fs
; switchgp - switch context to task (general purpose)
;
; this routine will switch the memory context of a tcb into
; memory if it is not already there.  this context will also
; include the tcb's ram and video areas as well.
; 
; modified 10/21/88 sah this routine nolonger depends on
; interupts being disable during this routine.
;
; in:	ax -> tcb of task to switch in
;
; out:	
;
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:nothing
public	switchgp
switchgp:
	push	ax
	push	bx
	push	ds
	push	es
	mgetscb ds
	assume	ds:grp
	inc	byte ptr [scbinswgp]
	mov	[scbtcbvs],-1		; keep userpoll from causing trouble
	mov	es,ax
	assume	es:tcb
	pushf
	call	switchtask
	test	[tcbvram],1		; if vidram inactive, expose real ram
	jz	swg110a 		; sah do vidsave too...

; note: pamswitching uses the forcevsa flag to manage the case where updating
; a watcher could result in a call to suspend.	this can happen when the
; workstation doing the switch is a serial terminal running at a slow baud
; rate.  the skipswvs flag is used by the swcall procedure (mosnxtsk) to
; make its call to switchgp not result in a video save are mapping change.
; the test below must jump to swg100 so that the skipswvs flag has the
; last word.  the skipswvs flag must be the higher priority decision.

	cmp	[forcevsa],'Y'
	je	swg100
	test	[tcbpamfg],1		; if pamswitching's override flag is set
	jnz	swg100			; then enable vidram (for serial irq's)
	push	ds
	mov	ds,ax
	push	cs
	call	near ptr nosbuf 	; check for con only
	pop	ds
	jz	swg110a 		; sah do vidsave too
swg100:
	cli
	cmp	[skipswvs],'Y'		; see note above
	je	swg100a
swg101:
	call	swvidsave		; else enable vidram
swg100a:
	cli
	call	swvidram
	jmp	swg120
swg110a:
	test	[scbmmfea],80h		; if no mm then need to update
	jnz	swg110			; scbmastv for cacheing logic
	mov	bx,[tcbbegad]
	mov	[scbmastv],bx
	mov	[scbtcbvs],bx		; update these to indicate end of
	mov	[scbtcbvr],bx		; 'dirty' state
	jmp	swg120
swg110:
	call	swrealram
	mov	[scbtcbvs],0		; udpate this to end the 'dirty' state
swg120:
	popf
	dec	byte ptr [scbinswgp]
	pop	es
	pop	ds
	pop	bx
	pop	ax
	ret

mosseg	ends
	end

