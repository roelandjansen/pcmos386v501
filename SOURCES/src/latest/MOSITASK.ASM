	include page.inc
	title	mositask - initialize new task
comment ^===============================================================
		    development specification

 program name:	$$mos.com		assigned to: david morrow
 module name:	mositask		assign date: 01/16/86
 entry points:	mositask		completed:
 entry from:	mosinit, mosint38
 entry method:	call
 calls:		n/a
 purpose:	initiate a new mos task
 refer to:	multilink module mlinit.inc
 last update:	08/18/1992
========================================================================

this module is used to start up a new task.  its first use is
by mosinit, to start the foreground task.  the following is
done:

(1) memory space is allocated for the new task.

(2) the command processor is loaded for the new task, and
    appropriate starting register values are put into the
    task's stack.

(3) if the task is not the fg then a cdb is created for each
    bdb that exists.

(4) control is returned to the calling routine.

upon entry to this routine, es points to a tcb which has been
allocated for the new task.  ax is used to indicate the desired
partition size, in paragraphs.

=======================================================================

jsm 12/17/86	changed method of assigning task id's so that
		all tasks have unique task id's (used counter)

mjs 1/26/87 	mod to use ds:si as entry parameter pointer to
		a startup batch file name

mjs 2/24/87	cooking mods - remove initialization of mosmiman variables

sah 5/15/87	heap checking before task is created so that system
		will not have low heap remaining for file io and (exec)
		selfmap only 640k instead of 704k for ega support

rbr 05/18/87	check for maximum number of users
		increase additional smp requirement to 8k.

sah 5/22/87	check to make sure task is not too big before adding it

mjs 7/3/87	error control strategy
		the bp register will be used as an internal error 
		control variable.  when at the end of mositask (at 
		mositend) and the carry flag has been set, bp will 
		indicate what de-allocation is needed.  the bits 
		are defined as follows:

		bit		 cleanup action
		---	 -----------------------------
		 0	 de-allocate context block (must test for mm)
		 1	 de-allocate task ram
		 2	 de-allocate vidram buffer
		 3	 de-allocate video save buffer
		 4	 task context switch in (updated 09/26/88 sah)

mjs 7/21/87	gutted about one third of the code and re-wrote it
		to accomodate non memory managed task switching and
		to optimize memory managed task switching

jrb 7/16/87	add call to insert itask tcb in priority order

sah 7/29/87	correct bug with ems because cl was assumed to be four
		and wasn't because of the latest Memory management
		changes in mos. made sure this didn't happen any where
		else in the task switching logic -- found out that
		same problem would happen with 80x87.

jsm 7/30/87	moved setting of video equipment flags and video mode
		for new task from end of mositask to end of ntrtsk
		routine.  before this change, the equipment flag and
		video mode of the parent task would be changed along
		with the child task, because the int 10 and the flag
		changing happened on the parent task's 40:0 context.

mjs 8/31/87	modified to use scbshell as file name string only when
		starting up the foreground.  when starting a background
		task, search the calling task's environment for a
		comspec= string.
		when new task's ram is switched in (for initialization)
		must also switch context so any irq's are handled
		properly (e.g. mouse driver).
		when the foreground is initialized, the new context
		block wasn't being switched in until a 2nd task was
		started.  corrected this.

mjs 9/2/87	corrected setting of tcbvidw2 to occur at mit130 instead
		of at mit200 so it gets set for non-mm cases too.

sah 09/11/87	made necessary changes so that itask will work with
		vidram off and mm case.  this is special case where the
		task executing the call is using state-pamming (which
		uses a different style of video memory management which
		we call vgavidram - normal vidram is not being use
		this mode)

mjs 9/23/87	after the label initfg, when done using the master
		video save area, un-map it.

sah 11/06/87	add initmcb as public so that mosinit as access to it

mjs 11/16/17	change criteria for type of context switching.	was
		scbmmfea bit 80h.  now changed to use bit 10h.	whereas
		a gizmo or a charge card on an at was compatible with
		the remapping type of context switching, a ps/2 machine
		has conflicts with i/o addresses.

jsm 11/17/17	initialize fake dos variable table in tcb of new task.

sah 12/01/87	initialize tcb$wrap for ansi wrap end of line during
		set mode.

sah 12/03/87	initialize tcbinmos flag to 0, set scbinmos to 0 before
		jumping into new task.

sah 12/09/87	initialize tcbequip on task start up to value at 40:10
		which is original equipment flags of task.

sah 01/19/88	change scbseg and zero seg access to use mgetxxxx macros
sah 01/21/88	changes for using 40:03fc during context switching for
		faster execution on 286 driver.
sah 01/23/88	corrected bug with 386 context switch (modifications on
		01/21/88)

sah/rbr 02/21/88 move ddt segment to mo2 group

rbr 02/29/88	moving notsl to grp.

mjs 3/30/88	added include for mostcb.pub here instead of mosfun00.
		modified points where the vsa (video save area) is used
		to hold the new task's context buffer for initialization
		must use the mapvsa procedure instead of calling the
		mm directly.

mjs 4/11/88	fixed an update to 40:13 that was being done to 40:0d
		because an 'h' was left off.  this caused cadkey to
		hang when the security block device was not connected.

mjs 5/2/88	modified the register call to ddtmc to pass es:bx
		pointing to scbmapvmf.

sah 05/04/88	added  tcbvidset call (which is set by register call, if
		necessary) so that device driver like sunriver driver
		can initialized terminal with task context in place.

sah 05/17/88	if sunriver style video (bit 2 of tcbvram set) vidram
		is not allocated or turn on.	this is because sunriver
		style stations don't need vidram.  Also if back ground
		task make sure that bit is clear

mjs 5/29/88	added skipswt flag for the procedure swtasktm which
		is in mosnxtsk.asm

mjs 6/6/88	corrected resetting of scbmastv just before the label
		fgxx

rdg 07/06/88	gated access to the console device drivers to prevent
		corruption of the serial data stream being sent to a
		terminal by changing the calls to the console device
		driver from a call dword ptr [si] to call ddtcallf

mjs 7/13/88	removed code which initializes chain table management.
		note - leaving temporary code to prevent int9 intercepts
		in device drivers from being inhereited by background
		tasks.	when new pamswitching controls are put in, which
		will enable mos to keep pamswitch control in the
		presence of a total int9 takeover, this temp code can
		be removed.

sah 07/26/88	move initial psp into grp segment for highmem logic
		per mjs, remove obsolete temporary code for int 9

rbr 7/29/88	repaired call to upd4013 so dx is valid on entry.

sah 08/25/88	when initializing dos variables, set sft pointer to
		point to entry where first word is ffffh.  this is use
		temporary to fake out mswindows

mjs 9/1/88	changed the initialization of tcbddpf to ffff:ffff.
		this was done for the task specific device driver mods.

sah 09/03/88	added initialization of fcb sft pointer to ffff for
		windows. change sft pointer to simulated sft in our
		gfbs

sah 09/21/88	corrected adding task with not enough memory left, by
		doing the allocation before we switch task in for mcb
		and dos variables initialization.
sah 09/26/88	added new error cleanup for when new task is switch in
		memory.

jrb 09/28/88	vna task was init'ed with num lock on if fg keyboard
		was enhanced - vna task keyboard is a pc keyboard which
		doesn't allow for setting lights - reset to vna kb was
		(internal to kb) clearing lights so num lock light was
		different from numlock state

sah 09/30/88	added initstation to initial tcbstation which is the
		consoles station type.	also if register call has been
		made kand error occurs, make sure unregister call is made

mjs 10/04/88	initialize scblastff to point the foreground tcb

sah 10/21/88	added switchtask for controlable interface to new
		context switching logic where logic does not depend on
		interupts being disable.

mjs 11/16/88	modified tsl to save and restore 32 bit registers when
		running on a 386 machine.

sah 11/21/88	remove setting of scbtcbps, scbtcbvr, and scbtcbvs
		because setting has been moved to mosinit2 for
		compatibility with novell's IPX driver and new irq logic

sah 12/03/88	correct adding a task from an alias drive. we were
		skip setting tcbidems for that condition.
sah 12/04/88	need to set default to boot drive.

sah 12/13/88	corrected addtasking a task when comspec is pointint to
		a non-global drive. this is when drive is greater then
		scbdrivs. this will happen in the case of novell when
		comskpec is use in their script or it could also happen
		but highly unlikely, if user set it to a alias drive.
		if these condition have been detected, the drive which
		system was booted off of will be use for the compec.

mjs 01/17/89	added code to initialize tcbvideo.  this corrects the
		problem where an ega master console cannot pamswitch
		into a mono mode vna workstation even after doing mos
		vmode mono at the mc.  the vna workstation's tcbvideo
		wasn't set to match its mono mode.

mjs 01/23/89	modified code in ntrtsk to not set scbtcbvr to -1 when
		starting a vna task.  this was causing problems with
		int8 intercept control since that logic tests scbtcbvr.
		once set to -1, scbtcbvr wasn't getting changed because
		the bankin logic decided there was no need to unmap
		since noting had ever been mapped in.

sah 02/03/89	remove my 05/17/88 changes for sunriver style terminals
		it appears that i added these changes to make it stable
		for spring comdex.  this removal should only effect
		sunriver (tcvram bit 4) and is necessarry for
		pamswitching to work correctly in the sunriver style
		enviroment.

sah 02/13/89	made initstation public so that it could be call from
		mosinit2.

mjs 02/16/89	corrected an improper jump in calclim.	this was
		preventing a vtype=5f from filling out the foreground.

mjs 03/13/89	modified ntrtsk so it didn't skip the initialization of
		tcbvideo for the foreground task.  this was making it
		necessary to do a mos vmode mono from a vna master
		console before a serial terminal type of workstation
		could pamswitch into the foreground.

sah 03/13/89	corrected the above update to ntrtsk so that it would
		not turn a none monochrome task into 40 col mode by
		making sure that al has the right mode before calling
		int 10.

mjs 03/15/89	my changes on 03/13 and sah's corrections later that
		day were both not enough.  ntrtsk now only sets the
		mode for a background/workstation task and sets
		tcbvideo properly for foreground or background.

sah 03/16/89	made changes to force tcbvram bit 4, if master console
		tcb has bit 4 of tcbvram set. this is for systems with
		both sunriver and vna stations on it.

sah 03/29/89	added initialization of co-processor for task if 8087 =
		yes is selected.

mjs 05/03/89	changed the error code returned when an addtask is
		attempted with a task id number which is already in use
		this was done to match changes done in int38fun22 and
		addtask.asm.

sah 06/26/89	enhanced initialisation of tcbstation:
		tcbstation	  5 = monochrome ega
				  6 = monochrome vga

sah 06/29/89	converted notsl flag into scbnotsl.

mjs 07/06/89	initialize tcborig8 and orig1c so that tsl can detect
		when a task has a timer intercept

sah 07/11/89	if not task, made sure that keyboard pointers are
		reset to start up position (ie 40:1a,1c,80 and 82)

sah 07/13/89	force ega\vga stations to cga, and monochrome ega\vga
		to mono if fill memory vtype is used. this is to protect
		user memory from enhance grpahics memory at a000.

sah 07/14/89	corrections to initstation for terminals on ega\vga
		master consoles

sah 07/26/89	added inittcb procedure which will be use to initialize
		tcb constant variables for new task.

sah 07/31/89	move tcb data from restart and function 22 into inittcb

sah 08/04/89	corrections to inittcb so that tcbalt999 is not set if
		creating forground.

sah 08/14/89	corrections for adding a task with compec not at root.

mjs 08/15/89	added code to initialize tcbwatch.  this var is used
		by getkeys/pamswitch to detect when pamswitch has
		re-ordered the list of watchers so that continuing the
		original watcher list in getkeys would be invalid.

sah 08/22/89	initialized tcbansi to on status, so that it is same as
		3.00

bwr 11/29/89	marked messages for foreign language translation.

sah 12/08/89	conditional assemble 286 driver logic out.

sah 01/08/90	initialization of keyboard-redifinition area - ansi.sys

sah 01/11/90	changes for new serialization scheme.

sah 01/22/90	converted reg32 to scb variable

sah 01/24/90	added code to transfer scbbufsz into to tcbsecsiz
		this is done so that correct value will be place in
		dos variable area when ontracks disk manager boots up

sah 02/02/90	initialize tcbversn from scbversn

cbk 02-14-90	fixed cga bugs in initstation - tcbstation set wrong

cbk 02/15/89	fixed init of tcbequip for video mode

sah 02/20/90	made calclim public for mosint38

sah 02/21/90	corrections for vertask for split smp

sah 03/30/90	corrections for 40:63 setting

sah 04/10/90	made vertask more precise, no need for smp header

mjs 04/17/90	insure tcbprgnm is blanked out so mos map doesn't
		display garbage when a new task is suspended before
		command.com is entered.

mjs 04/19/90	use tcbpam to disallow pamswitching to a new task
		until the end of the ntrtsk sequence is reached.  this
		is to prevent someone from pam'ing to a cluster
		controller (stargate) task before a virtual connection
		is made.  if this were not done, the pam'er would 
		be unable to pam back out until a connection was made.
		(which could be hours or years)

sah 04/25/90    set scbi15tsl to n during mositask so that disk io
		switching is disable during addtask time.

sah 05/01/90	corrections so restart logic will go to correct drive

mjs 06/08/90	set tcbrstok in ntrtsk.  this signals the restart
		logic that its ok for this task to run a task restart
		operation for another task.

sah 06/22/90	corrections for psp and lanlink	(msetpsp)	

mjs 07/17/90	initialize tcbkbrate from scbkbrate for each new task

mjs 08/15/90	added the set_conly functions and made ntrtsk call it.
		pamswitch also uses this function.  its purpose is to
		manage the tcbconly flag.  this flag gives set_trap a
		quick picture of a task's watcher state.  tcbconly is
		only set when a task's only watcher is a con-only type
		workstation.

mjs 08/29/90	make allocation of vid save buffer pre-test for large
		enough vid save area first.

mjs 09/21/90	instead of saving and clearing the scbi15tsl flag to
		prevent disk busy tasks switching during an itask, change
		to using a seperate flag.  this prevents lockups during
		concurrent disk activity and addtasks.  this new flag
		is named scbi15ita.

SAH 11/01/90	Remove Reference to old EMS techniques, New EMS 4.0 
		driver uses new technique.

mjs 01/09/91	corrected fetching of dcbios within the initstation 
		function.  if [tcbcondd] != 0 then we need to use the
		dcbios value of the new task (es->tcb).  otherwise, we
		need to use the dcbios value of the current task 
		(ss->tcb).

SAH 01/09/91	Remove TCBVRAM Bit 2 usages, nolonger need with IOprotection
		changes

SAH 01/22/91	Corrections for Device driver will be supported by
		undocumented DOS techniques.  Also added support for
		lastdrive field

mjs 01/23/91	fixed invisible cursor problem when a viewport 
		workstation task is started up.  the call to 
		the set_conly function had to be moved from
		ntrtsk to the end of mositask so that tcbconly 
		would be initialized when tsl called settrap 
		just before entering ntrtsk.

SAH 01/24/91	Remove initialization, no longer needed because of
		changes in mosliman

SAH 03/08/91	Initialized TCBCON417 to -1 so that first call to
		getkeys will initialized leds

mjs 03/28/91	init tcbtslnst to 1 since all new tasks start from
		within tsl without entering tsl.  the foreground
  		task is an execption to this.  mosinit compensates
		by resetting tcbtslnst to 0 after it calls mositask.

BWR 04/08/91    Added initialization for new MOS HOLD COM variables
                in the TCB.  Also, changed the amount of time for
                the hold from (18*15) to 273, which is more accurately
                15 seconds.

SAH 06/25/91	Increased size of ANSI Buffer to size in options.inc
		(Procol.exe problem)

SAH 07/25/91    Change CGA test in initstation to test for 60h instead of
		40h for Cheryl's Wyse 370 terminal driver.

SAH 09/11/91    Added support for config.sys lastdrive command

mjs 10/07/91	fix dbts/prtsc bugs (patch410.118).
		rename scbi15ita to i15off.  modify logic to use this
		flag in an increment/decrement manner.

SAH 12/03/91    Converted usage of tcbprgnm (for startup batch file) to
		tcbbatnm. This finally corrected the problem with mos map
		and addtasks

SAH 03/16/92	Change Calclim so that it check SCB4013 and if its not
		a multible of 64k then use SCB4013 as the limit for the
		task.

SAH 03/23/92	Change SCBVERSN to SCBDOSVER for dosver= support.

================ 5.01 Kernel Ends Here ====================================

mjs 07/23/92	changed moved the shareticks and shareretry equates
		to mostcb.inc. (tick count was also changed from 19
		to 3 to make mos more like dos).

mjs 08/18/92	clean up segment declarations

mjs 09/18/92	removed code that inited tcb_com_hold (per sah).

=======================================================================^

.xlist
;	include mositask.pub
	include options.inc
	include mosregs.inc
	include group.inc
	include moscdb.inc
	include mosbdb.inc
	include mospsp.inc
	include mosgfb.inc
	include macros.inc

tcb	segment at 9999h
	include mostcb.pub
	include mostcb.inc
tcb	ends

gdata	segment
	include mosscbex.inc
gdata	ends
.list

gdata	segment
	extrn scbmosadr:word
	extrn skipswt:byte

	public	initpsp
	db	16 dup (0)		; dummy mcb
initpsp db	256 dup (0)		; this for initial psp

gdata	ends

; memory block definition

if	0 eq 0				; so no publics
mbseg	segment at 1111h
mbtype	db	?			; m for memory block, z for last block
mbowner dw	?			; owner psp address
mbsize	dw	?			; size of block
mbseg	ends
endif

; error codes used

if	0 eq 0				; so no publics
insfm	equ	8			; insufficient memory
invfmt	equ	11			; invalid format (of data for port init)
lowsmp	equ	18			; low heap error
invprm	equ	87			; invalid parameter (task id in use)
endif

;======================================================== mos segment
if 0 eq 0
segment_num = 1
endif
mosseg	segment
	assume	cs:mos,ds:nothing,es:nothing,ss:nothing
$$$itask label	byte

	extrn	mosend:byte, sbios:word, bugerror:near, mosheman:near
	extrn	mcterm:near, mosliman:near, noswitch:near, skipsw:byte
	extrn	okswitch:near, scbfree:word, switchtask:near, swcntxt:near
	extrn	doesc:near, switchif:near, savtable:byte, swvidsave:near
	extrn	reordlst:near, mapvsa:near,ddtcallf:near,mo2seg:word
	extrn	scbnul:word

	public	mositask
	public	mmret			; needed by mosinit
	public	initmcb 		; sah needed by mosinit
	public	inidvars		; jsm called by mosinit
	public	initstation		; sah use in mosinit2
	public	calclim 		; sah use in mosint38
	public	set_conly		; used by pamswitch logic

env1	db	'COMSPEC='
envlen1 equ	$-env1

env2	db	'STARTBAT='
envlen2 equ	$-env2

cmd1	db	3,' /p',13

cmdcom	db	':\COMMAND.COM',0
ccomlen equ	$-cmdcom

; data for exec of command processor

pblk	dw	0			; environment segment
	dw	mos:cmd1		; command line
cmdseg	dw	0			; seg address of command line
	dd	0			; fcb1
	dd	0			; fcb2
pgm1	dw	0,0			; ss:sp for program (passed back from exec)
	dw	0,0			; cs:ip for program   "         "	"

stdcon1 db	'CON',0 		; for open of std devices
stdaux1 db	'AUX',0
stdprn1 db	'PRN',0

mmret	label	near
	retf

	subttl	mositask - initialize new task
	page
;======================================================================
;,fs
; mositask - initialize new task
;
; initialize a new task with passed tcb information.  note that the new
; task is not given a time slice.  that field must be set by the
; calling routine.
;
; in:	ds:si -> points to startup batch file string
;	es -> tcb allocated from the heap, cleared to 0, and linked
;		into the tcb chain.  (as per function 80h)
;	tcbendad (of the new tcb) holds the task size in paragraphs
;
; out:	nc then buffers allocated, task registered with terminal
;	driver (if specified), command processor loaded into task
;	memory space, and all registers setup for task.
;
;	cy then ax has error code.  nothing allocated, nothing loaded.
;	if al=11 (invalid format) then ah has terminal registration
;		error codes (1=bad port #, 2 bad baud)
;	al=87 if task id is in use.
; 
;,fe
;================================================================
	assume	es:tcb,ds:nothing,ss:nothing
mositask proc	near
	call	inittcb 		; initialize tcb contants
	push	bp
	xor	bp,bp			; init error control code
	mov	word ptr [tcbbatnm],si	; save pointer to startup
	mov	word ptr [tcbbatnm+2],ds; batch file string for later
	mgetscb ds
	assume	ds:grp
	mov	al,[scbkbrate]
	mov	[tcbkbrate],al
	inc	[scbi15off]		; disable disk io switching

; see if command processor can be opened now, later it will be
; difficult to report error and clean up.

	push	ds
	lea	dx,[scbshell]
	mov	ax,[scbtcbpf]		; creating fg task (task 0)?
	cmp	ax,[scbtcbpl]
	jnz	foundxx
	mov	[scblastff],ax
	mov	al,[scbldrive]
	mov	ah,[scbdrivs]
	cmp	al,-1			; no last drive in config.sys
	je	setldrive
	cmp	al,ah	 		; if lastdrive is below physic
	jb	setldrive		; ...set physical
	mov	ah,al			; use lastdrive as value
setldrive:
	mov	[scbldrive],ah	
	jmp	short foundcom
foundxx:
	call	findcomspec		; if bg, search for comspec= string in
	assume	ds:nothing		; findcomspec will change ds
	jz	foundcom		; caller's environment
	pop	ds
	assume	ds:grp
	mov	al,2
	stc
	jmp	mositend
foundcom:
	mov	ax,3d00h		; see if we can open it for read
	int	21h
	pop	ds
	assume	ds:grp
	jnc	mitcont 		; ok, got it now close it
	jmp	mositend		; exit with al error code
mitcont:
	mov	bx,ax			; handle
	mov	ah,3eh
	int	21h			; close, just checking

; register task with terminal driver

	mov	[tcbscrdd],es		; looking at own screen
	mov	[tcbwatch],es		; record the task this wks is viewing
	cmp	word ptr [tcbcondd+2],0 ; is this a non-terminal task?
	jne	mosit3a 		; no
	mov	[tcbscrdd],0		; no one looking at this screen
	mov	[tcbwatch],0		; no workstation to look at anything
mosit3a:
	mov	[tcbnxtdd],0		; no one else looking at screen
	push	es			; save tcb
	mov	ax,es
	mov	ds,ax
	assume	ds:tcb
	xor	ax,ax
	mov	si,offset tcbcondd
	cmp	word ptr [si+2],0	; driver have seg? (terminal specified?)
	jne	mosit3b
	assume	es:nothing,ds:nothing,ss:tcb  ; use callers info here
	mov	al,[tcbvram]		; use video info of task starting this
mosit3a1:
	jmp	noterm1 		;  one.
	assume	ss:nothing
mosit3b:

; count number of users for limit check

	push	ds
	xor	ax,ax
	mgetscb ds
	assume	ds:grp
	mov	cx,[scbtcbpf]
mosiuc0:
	jcxz	mosiuc2
	mov	ds,cx
	assume	ds:tcb
	cmp	word ptr [tcbcondd+2],0
	je	mosiuc1
	inc	al
mosiuc1:
	mov	cx,[tcbtcbpn]
	jmp	mosiuc0
mosiuc2:

; the following is done so that it would make it hard for some hacker
; to figure out how to change max # users on mos. scbmuser and scbmuser+1
; are derived at init time. the low byte of the sum of these 2 values
; equals the maximun # of users on system

	mgetscb ds
	assume	ds:grp
	push	bx
	push	si
	mov	si,offset scbmuser+47h	; done to make it hard to
	xor	cx,cx			; find
	xor	bx,bx
	sub	si,47h
	mov	cl,byte ptr ds:[si]	; get first byte
	mov	bl,byte ptr ds:[si+1]	; get second
	add	cx,bx			; add together
	pop	si
	pop	bx
	cmp	al,cl			; limit exceeded
	pop	ds
	jna	mosiuc3 		; no, skip

; error - trying to exceed maximum number of users

	mgetscb ds			; needed by 'tskMMin'
	assume	ds:grp
	mov	ax,0300h+invfmt 	; too many users
	pop	bx			; clear tcb address from stack (pushed es)
	stc
	jmp	mositend		; exit with error

; call the ddt's register function

mosiuc3:
	mgetscb es
	assume	es:grp
	mov	ah,0
	mov	bx,offset [scbmapvmf]
	call	ddtcallf		; see if ddt busy and call	; rg8188
	assume	es:nothing
	or	ah,ah			; any errors?
	jz	noterm			; no, register and port init ok

; error during register of port

	mgetscb ds			; needed by 'tskMMin'
	assume	ds:grp
	mov	ax,invfmt		; invalid format of port data
					; ah = reason (bad baud, or port #)
	pop	bx			; clear tcb address from stack (pushed es)
	stc
	jmp	mositend		; exit with error
noterm:
	or	bp,32			; indicate that register call been called
	assume	es:nothing,ds:tcb
	mov	word ptr [tcbkeyrdy],bx
	mov	word ptr [tcbkeyrdy+2],es
	test	al,80h			; set physical display address
	jz	noterm1 		;   if master console
	mov	[tcbvidad],cx
noterm1:
	or	[tcbvram],al		; set if master console
	mov	[tcbscln],4096		; 4096 bytes for screen unless graphics
	test	al,40h			; graphics?
	jz	nogrphx 		; no
	mov	[tcbscln],16384 	; 16k video buffer
nogrphx:
	pop	es			; tcb back
	assume	es:tcb
	mgetscb ds
	assume	ds:grp
	call	vertask 		; verify task requirements
	jnc	tsmpok
	mov	ax, lowsmp		; sorry too low for stability
	jmp	mositend
tsmpok:
	call	initstation		; initialize station type

; allocate and init context save area

	or	bp,1			; update error control status
	test	[scbmmfea],10h		; mjs 11/16/87 bit 10 signals what type of
					; context switching to use. (for ps gizmo)
	jne	initcblk		; (can't just have a JRAM type MM)
	jmp	nommcntx
initcblk:
	mov	cx,1			; need 1 4k block for context
	mov	ah,1			; allocate function
	call	[scbmmsub]		; order memman to do my bidding!
	mov	[tcbcntxpt],bx
	or	ax,ax			; did we get the size asked for?
	jz	initcntx		; yes, (or maybe more)
	mov	ax,insfm		; insufficient memory
	stc
	jmp	mositend		; exit with error
initcntx:
	call	noswitch		; map the context block into the video
	xor	di,di			; save area so it can be initialized
	mov	cx,1
	mov	al,1
	cli
	mov	[scbtcbvs],-1		; mark as dirty
	call	mapvsa
	sti
	push	es
	mov	es,[scbmastv]
	assume	es:nothing
	mgetzero ds
	assume	ds:nothing
	xor	di,di
	xor	si,si
	cld				; copy the first 4k of ram into the
	mov	cx,2048 		; context save area since this switching
	rep	movsw			; scheme will swap the mm's code
	mgetscb ds
	assume	ds:grp
	pop	es
	assume	es:tcb
	mov	ax,[scbtcbpf]		; creating fg task (task 0)?
	cmp	ax,[scbtcbpl]
	je	initfg

; init the new block from master context using the save table
; to un-compress the data

	push	es
	mov	bx,offset savtable	; bx scans table
	mov	dx,[scbmastv]
	mov	ds,[scbcntxt]		; pointer to master context
	assume	ds:nothing
	xor	si,si
	cli				; disable interrupts for first 3
	mov	es,dx			; place at start of scbmastv
	xor	di,di
	mov	cx,512
	rep	movsw
	jmp	short lp1
lp2:
	mov	ax,es
	add	ax,dx			; adjust by segment of the master save area
	mov	es,ax
	rep	movsw			; fast move
	add	bx,6			; next table entry
lp1:
	les	di,dword ptr cs:[bx]
	mov	cx,cs:[bx+4]		; number of words to move
	or	di,di			; check for end of table
	jnl	lp2
	sti
	and	di,7fffh
	cmp	di,7fffh		; resume if sti break
	jne	lp2
	pop	es
	assume	es:tcb
	mgetscb ds
	assume	ds:grp
	call	upd4013 		; modify 40:13 in the new task's context
	jmp	cntxnofg
initfg:
	mov	bx,[tcbcntxpt]
	push	es
	mgetzero es			; map the new context area into 0:0
	mov	cx,1
	cli
	mov	ah,3
	call	[scbmmsub]
	mov	cx,1
	mov	al,0
	call	mapvsa			; and un-map it from the video save area
	sti				; ([scbtcbvs] still set to -1 for dirty)
	pop	es
cntxnofg:
	mov	ax,[scbtcbpf]		; creating fg task (task 0)?
	cmp	ax,[scbtcbpl]
	je	toipam
	push	es
	push	ss
	pop	es
	cli
	mov	[scbtcbvs],0		; to insure a switch
	call	swvidsave		; restore video save area for current task
	sti
	pop	es
toipam:
	call	okswitch
	jmp	initpam
nommcntx:
	mov	dx,[scbctxsz]		; setup context save area for no mm case
	xor	ah,ah			; allocate block from smp
	push	es
	call	mosheman
	assume	es:nothing
	mov	bx,es
	inc	bx			; increment past the header
	pop	es
	assume	es:tcb
	mov	[tcbcntxpt],bx
	or	al,al
	jz	initcntx1
	mov	ax,insfm		; insufficient memory
	stc
	jmp	mositend		; exit with error
initcntx1:
	assume	es:tcb
	push	es
	mov	es,[tcbcntxpt]
	assume	es:nothing
	mov	cx,[scbctxsz]
	dec	cx
	shl	cx,1
	shl	cx,1			; convert paragraphs to bytes
	shl	cx,1
	shl	cx,1
	mov	ds,[scbcntxt]		; get pointer to master context
	assume	ds:nothing
	xor	si,si
	xor	di,di			; init smp block with context
	cld
	rep	movsb
	pop	es
	assume	es:tcb
	mgetscb ds
	assume	ds:grp
	mov	ax,[scbtcbpf]		; creating fg task (task 0)?
	cmp	ax,[scbtcbpl]
	je	initpam
	mov	dx,[tcbcntxpt]		;072988  marty left this out....
	call	upd4013 		; modify 40:13 in the new task's context
initpam:

; if this is the second task (1st bg) then turn on alt pam keys

	push	es
	mov	es,[scbtcbpf]
	assume	es:tcb
	cmp	[tcbtcbpn],0		; is this the only task?
	je	nopamdft		; yes, skip this stuff
	mov	es,[tcbtcbpn]		; get pointer to next
	cmp	[tcbtcbpn],0		; is the second task the last one?
	jne	nopamdft		; no, skip this stuff
	mov	es,[scbtcbpf]
	mov	[tcbalt999],0ffh	; set pam on
	mov	es,[tcbtcbpn]
	mov	[tcbalt999],0ffh	; for both tasks
nopamdft:
	pop	es
	assume	es:tcb

; determine id # of starting task

	xor	bx,bx			; fg always 0
	mov	ax,[scbtcbpf]		; creating fg task (task 0)?
	cmp	ax,[scbtcbpl]
	je	tcball			; if creating task 0
	mov	bx,[tcbid]		; was task id given?
	mov	[tcbid],0		; clear it for our checks
	or	bx,bx
	jz	getidnxt		; no, find lowest available

; see if id given is used

chkid:
	or	ax,ax			; last tcb?
	jz	tcball
	push	es
	mov	es,ax
	assume	es:tcb
	mov	ax,[tcbtcbpn]		; pointer to next tcb
	cmp	bx,[tcbid]
	pop	es
	jne	chkid

; id # is in use, exit with error code

	mov	ax,85			; already assigned
	stc				; error flag
	jmp	mositend

; find lowest available id #

getidnxt:
	push	es			; bx=0 on entry
getid2:
	inc	bx			; try next #
	mov	ax,[scbtcbpf]		; start at top of list
idnlp:
	mov	es,ax
	assume	es:tcb
	mov	ax,[tcbtcbpn]		; get pointer to next
	cmp	bx,[tcbid]		; is this # used here?
	je	getid2			; yes, try next # (from top of list)
	or	ax,ax			; is this the last task?
	jnz	idnlp			; no, check the others
	pop	es			; original tcb back

; ok, found free id

tcball:
	mov	[tcbid],bx		; set task id #

; allocate task ram and video save area (mm case)
; set initial "state of switch" variables

	mov	ax,[scbtcbpf]
	cmp	ax,[scbtcbpl]		; if setting up the foreground task
	je	mit101
mit100: 				; creating a background task
	call	noswitch		; no async task switch here
	mov	[scbnotsl],'Y'		; no task switching allowed (bank switching)
	mov	[skipsw],'Y'		; skip any direct switchif calls too
	mov	ax,[scbtcbpf]		; creating fg task (task 0)?
	cmp	ax,[scbtcbpl]
	je	mit101
	push	ds
	push	es
	call	findcomspec		; now that task switching is off, need to get
	mov		di,cs		; a local copy of the calling task's comspec
	mov	es,di			; string before caller's ram is switched out
	mov	di,offset [comspec]
	mov	si,dx
	cld
mit100a:
	lodsb
	stosb
	or	al,al
	jnz	mit100a

; the following is necessary for novell, if user has comspec set to a
; a network drive and then does a addtask.com.	since that drive is
; is not available to the new task, i have force the drive to go to
; boot drive

	mov	al,byte ptr cs:[comspec]
	and	al,0dfh 		; convert comspec drive to uppercase
	sub	al,'A'
	mgetscb ds
	assume	ds:grp
	cmp	al,[scbdrivs]		; is this a global drive (i.e local or
	jb	mit100b 		; drive like lansat use it)
	mov	al,[scbbootdrv]
	add	al,'A'			; no...then make it come from the drive
	mov	di,offset [comspec]	; that system was booted from
	stosb
	mov	ax,cs
	mov	ds,ax
	mov	si,offset cmdcom	; make sure it command.com that is at
	mov	cx,ccomlen
	rep	movsb			; transfer bytes
mit100b:
	pop	es
	pop	ds
mit101:
	cmp	[scbmmfg],'Y'		; if have a memory manager
	je	mit102
	jmp	mit130
mit102:
	mov	cx,[tcbendad]		; get # of paras for the task
	add	cx,000ffh
	and	cx,0ff00h
	mov	cl,ch
	xor	ch,ch			; convert paras to 4k blocks (rounding up)
	mov	ax,[scbtcbpf]
	cmp	ax,[scbtcbpl]
	jne	mit103
	jmp	mit120
mit103:
	mov	bx,[scbfree]		; if setting up the background task
	add	bx,[tcbendad]
	call	calclim 		; is the task too large?
	cmp	bx,ax
	jna	mit140
	mov	ax,insfm		; insufficient memory
	stc
	jmp	mositend		; exit with error
mit140:
	or	bp,2			; update error control code
	mov	ah,1
	call	[scbmmsub]		; allocate task ram (block count in cx)
	mov	[tcbmmhdl],bx		; save returned handle
	mov	[tcbmmpgs],cx		; "     "	count
	or	ax,ax			; did we get the size asked for?
	jz	mit150			; yes, (or maybe more)
	mov	ax,insfm		; insufficient memory
	stc
	jmp	mositend		; exit with error
mit150:

; allocate video save area

	mov	cx,[tcbscln]		; allocate for video save area and map in
	mov	cl,ch			; divide by 256
	xor	ch,ch
	shr	cx,1
	shr	cx,1
	shr	cx,1			; divide by 4k overall - to convert bytes
	shr	cx,1			; to 4k pages
	or	bp,8			; update error control code
	cmp	cx,[scbmastp]
	ja	mit150a
	mov	ah,1
	call	[scbmmsub]		; allocate cx pages
	mov	[tcbvidh1],bx
	mov	[tcbvidp1],cx
	or	ax,ax			; any banks allocated?
	jz	mit151
mit150a:
	mov	ax,insfm		; insufficient memory
	stc
	jmp	mositend		; exit with error
mit151:
	or	bp,16			; indicate task switch in
	call	setbegend
	call	switchtask		; switch in new task
	mov	ax,[tcbbegad]

if	code286
	or	al,3			;022688  for 286 driver
endif

	call	initmcb 		; initialize its mcb chain

; call terminal video initialition routine

	cmp	word ptr [tcbvidset+2],0
	je	mit150s
	call	dword ptr [tcbvidset]
mit150s:
	jmp	mit130
mit120:

; starting foreground task with mm

	mov	ax,[scbfree]
	add	ax,000ffh
	and	ax,0ff00h		; round up to next 4k boundry
	push	es
	mov	[scbfree],ax
	mov	es,[scbmosadr]		; set in relocated mos also
	assume	cs:nothing,es:mos
	mov	es:[scbfree],ax
	pop	es
	assume	cs:mos,ds:grp,es:tcb
	mov	al,ah
	xor	ah,ah			; convert to a mm handle number
	mov	[tcbmmhdl],ax		; record handle number
	sub	cx,ax			; compensate for the fact that mosinit will
					; pass in a number of paras based on 40:13
	mov	[tcbmmpgs],cx		; record number of pages
	test	byte ptr [scbvtype],80h
	jnz	mit121
	jmp	mit160			; was the 'F' option used with vtype ?
mit121:
	mov	ax,[tcbendad]		; yes, so fill out the foreground
	mov	dx,ax
	call	calclim
	push	es
	push	ax
	shr	ax,1
	shr	ax,1
	shr	ax,1
	shr	ax,1
	shr	ax,1
	shr	ax,1
	mov	bx,40h
	mov	es,bx
	assume	es:nothing
	mov	es:[13h],ax		; update bios memory size word
	pop	ax
	pop	es
	assume	es:tcb
	sub	ax,dx			; calc # of paras to fill out
	mov	si,ax
	mov	cx,ax
	mov	cl,ch
	xor	ch,ch			; convert to number of 4k blocks (truncating)
	mov	ah,1
	call	[scbmmsub]		; allocate 4k blocks to fill out
	or	ax,ax			; any banks allocated?
	jnz	mit122			; yes, no errors
	jmp	mit170
mit122:
	mov	ax,insfm		; insufficient memory
	stc
	jmp	mositend		; exit with error
mit170:
	mov	word ptr [tcbmmhdl+2],bx; should be only case where
	mov	word ptr [tcbmmpgs+2],cx; fg is fragmented
	push	es
	mov	es,dx			; saved from above calcs
	mov	ah,3
	call	[scbmmsub]		; map in the new memory
	pop	es
	add	[tcbendad],si
mit160:
	mov	ax,[scbfree]
	mov	[tcbbegad],ax		; mosinit will have set tcbendad

if	code286
	or	al,3			;022688  for 286 driver
endif

	call	initmcb

; allocate video save area

	mov	cx,[tcbscln]		; allocate for video save area and map in
	mov	cl,ch			; divide by 256
	xor	ch,ch
	shr	cx,1
	shr	cx,1
	shr	cx,1			; divide by 4k overall - to convert bytes
	shr	cx,1			; to 4k pages
	mov	[tcbvidp1],cx
	mov	ax,[scbmastv]
	cmp	ax,0a000h		; did the video save area relocate up high?
	jae	mit180
	mov	al,ah			; no, so use the physical memory
	xor	ah,ah			; convert to page handle
	mov	[tcbvidh1],ax
	jmp	mit130
mit180:
	or	bp,8			; update error control code
	mov	ah,1
	call	[scbmmsub]		; allocate cx pages
	mov	[tcbvidh1],bx
	or	ax,ax			; any banks allocated?
	jnz	$+5
	jmp	mit185			; yes, no errors
	mov	ax,insfm		; insufficient memory
	stc
	jmp	mositend		; exit with error
mit185:
	push	di
	xor	di,di
	mov	al,1
	call	mapvsa			; map in the video save area
	pop	di
mit130:

; allocate vidram

	mov	cx,[scbvidad]		; mjs 9/2/87
	mov	[tcbvidw2],cx		; mjs 9/2/87
	test	[scbmmmod],80h		; is video management active?
	jnz	mit131
	jmp	mit110			; no, do not make allocation call
mit131:
	cmp	word ptr [tcbcondd],0	; use mode according to terminal, if
	jne	mit190			;   applicable
	assume	ss:tcb,es:nothing
	mov	al,[tcbomode]		; use original mode of originator
	jmp	mit200
	assume	es:tcb,ss:nothing
mit190:
	mov	al,7			; monochrome mode (4k video buffer)
	test	[tcbvram],60h
	jz	mit200			; z if neither color nor graphics
	mov	al,3			; color (16k video buffer)
mit200:
	mov	cx,1			;%%%% 1 4k block (mono mode)
	cmp	al,7
	je	mit210
	mov	cx,4			;%%%% 16k buffer (color/graphics)
mit210:
	or	bp,4			; update error control code
	mov	ah,1			; allocate function
	call	[scbmmsub]		; order memman to do my bidding!
	mov	[tcbvmhdl],bx		; save info for switching in video ram
	mov	[tcbvmpgs],cx
	or	ax,ax			; did we get the size asked for?
	jz	mit220			; yes, (or maybe more)
	mov	ax,insfm		; insufficient memory
	stc
	jmp	mositend		; exit with error
mit220:
	mov	[tcbvrtim],1		; init vidram timer
	or	[tcbvram],01		; turn vidram on
mit220a:
	jmp	mit270

mit110:

;allocate task ram and video save area (non-mm case)

	mov	ax,[scbtcbpf]
	cmp	ax,[scbtcbpl]		; if setting up the background task
	jne	mit110a
	jmp	mit240
mit110a:

; find last mcb of calling routine (ss ->tcb)

	push	es
	assume	ss:tcb,es:nothing
	mov	ax,[tcbmbpf]		; get first mcb of calling task
	assume	es:tcb,ss:nothing
mit111:
	mov	es,ax
	assume	es:nothing
	mov	cx,es:[3]		; get size
	cmp	byte ptr es:[0],'Z'	; is this last block ?
	je	mit112
	inc	ax
	add	ax,cx			; position to next prefix
	jmp	short mit111
mit112:
	mov	ax,es			; record seg of last mcb in ax
	pop	es			; cx is size
	assume	es:tcb
	mov	bx,[tcbendad]		; is new task size request too large ?
	cmp	bx,cx
	jna	mit113
	mov	ax,insfm		; insufficient memory
	stc
	jmp	mositend		; exit with error
mit113:
	call	noswitch
	push	es
	assume	es:nothing
	mov	es,ax
	sub	cx,bx			; calc new size for caller's MCB
	mov	es:[3],cx

; reduce size in psp:2 (of calling task)

	assume	ss:tcb,es:nothing
	mov	bx,[tcbpsp]		; get callers current psp
	pop	es
	push	es
	assume	es:tcb,ss:nothing
	mov	cx,[tcbendad]		; get new task's paragraph count
mit114:
	mov	es,bx
	mov	ax,bx
	sub	es:[2h],cx
	mov	bx,es:[16h]		; get parent
	cmp	bx,ax
	jne	mit114
	pop	es
	assume	es:tcb
	mov	cx,[tcbendad]		; set cx = new task's tcbendad
	assume	es:nothing,ss:tcb
	mov	ax,[tcbendad]		; set ax = caller's tcbendad
	assume	es:tcb,ss:nothing
	mov	[tcbendad],ax		; set new task's tcbendad = ax
	sub	ax,cx
	assume	es:nothing,ss:tcb
	mov	[tcbendad],ax		; set caller's tcbendad = ax
	assume	es:tcb,ss:nothing
	mov	[tcbbegad],ax		; set new task's tcbbegad = ax
	shr	ax,1
	shr	ax,1
	shr	ax,1
	shr	ax,1
	shr	ax,1
	shr	ax,1			; calc and reset memory size at 40:13
	mov	bx,40h			; (for the caller)
	push	es
	mov	es,bx
	mov	es:[13h],ax
	pop	es
	or	bp,16			; indicate task switch in
	mov	[scbtcbps],es		; record new task as being switched in
	mov	bx,es
	call	swcntxt
	call	okswitch
	jmp	short mit250
mit240:
	mov	ax,[scbfree]		; if setting up the foreground task
	mov	[tcbbegad],ax
mit250:
	mov	ax,[tcbbegad]		; reserve a space for the video save area
	mov	[scbmastv],ax
	add	ah,byte ptr [scbmastp]	;#jrb pages * 256 = paras
mit260:
	call	initmcb
mit270:

; initialize cdb'S

	mov	ax,[scbbdbpf]
	mov	cx,es			; our tcb address for mosliman and exit
allocdb:
	mov	es,ax
	assume	es:bdb
	cmp	[bdbalias],0		; alias drive?
	jnz	cdba3			; don't allocate CDB for alias drive.
	mov	bl,[bdbid]		; get drive id
	call	noswitch		; do not switch, ss will not be correct
	push	es			; save bdb pointer
	mov	si,ss			; save current stack
	mov	dx,sp			; "
	cli
	mov	ss,cx			; ss must point to tcb for 'mosliman'
	lea	sp,tcbstack		; use tcb stack space (no harm done)
	sti
	xor	ah,ah			; allocate
	mov	al,'C'			; cdb
	call	mosliman		; allocate a cdb, returns es -> cdb
	cli
	mov	ss,si			; restore our stack
	mov	sp,dx
	sti
	call	okswitch		; ok to switch, stack is back
	or	al,al			; any errors on allocation?
	jz	cdba1			; no, continue
	jmp	miterr
cdba1:
	assume	es:cdb
	mov	[cdbdrive],bl		; set drive cdb associated with
	cmp	[scbbootdrv],bl
	jne	cdba2
	mov	ax,es
	mov	es,cx
	assume	es:tcb
	mov	[tcbcdriv],bl		; set default drive and cdb
	mov	[tcbcdbpc],ax
cdba2:
	pop	es			; restore current bdb pointer
	assume	es:bdb
cdba3:
	mov	ax,[bdbnext]		; get pointer to next bdb
	or	ax,ax			; any more?
	jz	cdbaend
	jmp	allocdb
cdbaend:
	mov	es,cx			; original tcb pointer
	assume	es:tcb

; set default drive to current default drive

	push	ds

; if not during, restart, we need to use the current drive for
; calling task, other wise we will need to set drive preserved by 
; restart logic

	mov	al,ss:[tcbcdriv]	; get current drive of calling task
	cmp	[scbrstrtp],-1		; are we inside restart logic
	jne	setdrvr
	mov	al,[scbrdriv]		; get drive save by restart logic
setdrvr:
;	
	cmp	al,[scbdrivs]
	jae	setdrve
	mov	cx,[tcbcdbpf]		; get pointer to 1st cdb
setdrv:
	jcxz	setdrve 		; exit if no more cdbs
	mov	ds,cx
	assume	ds:cdb
	mov	cx,[cdbnext]		; get pointer to next cdb
	cmp	al,[cdbdrive]		; is this the cdb for the drive?
	jne	setdrv			; no, try next one
	mov	byte ptr [tcbcdriv],al	; yes, update current drive
	mov	[tcbcdbpc],ds		; also update pointer to default cdb
setdrve:

; Now we must save current drive into TCBODRIV so that
; restart logic will know what drive to use to restart the task with

	mov	al,[tcbcdriv]
	mov	[tcbodriv],al
	pop	ds
	assume	ds:grp

; allocate miscellaneous save areas

mosit2:
	push	ds
	push	es
	mov	ax,40h			; get pointer to bios
	mov	es,ax
	mov	ax,[scbtcbpf]		; creating fg task (task 0)?
	cmp	ax,[scbtcbpl]
	je	skipkeyb		; yes than skip keyboard pointers
	mov	word ptr es:[1ah],200h	; initialize keybord pointers
	mov	word ptr es:[1ch],200h	; so that forground keys
	mov	word ptr es:[80h],200h	; don't bleed over at init
	mov	word ptr es:[82h],280h	; time.
skipkeyb:
	assume	ds:grp
	mov	ds,[scbtcbpc]
	assume	ds:tcb			; get tcb
	mov	al,es:[10h]		; get equiptment flag
	mov	[tcbequip],al
	pop	es
	pop	ds
	assume	ds:grp
	call	inidvars

; allocate save area for 8087 if present

	cmp	[scbsw87],'Y'
	jne	notsk87 		; no
	mov	dx,7			; space for 94 bytes and heap prefix
	xor	ah,ah
	push	es			; save tcb address
	call	mosheman
	or	al,al
	jz	$+5
	jmp	miterr
	mov	ax,es
	pop	es			; tcb back
	assume	es:tcb
	inc	ax			; skip heap prefix
	mov	[tcb87sav],ax		; 80x87 save area address

; we must initialize the state of co-processor, because we don't
; know what the state of the coprocessor was before executing
; addtask call.

	.8087
	fninit				; init co-processor
	fwait
notsk87:

; allocated 64 byte storage area for ansi keyboard redifinitions
; this is done only if ansi.sys is enable

	cmp	[tcbansi],0ffh		; is ansi support...
	jne	noansi
	push	es
	mov	dx,PARAKANSI+1		; allocate size from options.inc (plus header)
	xor	ah,ah
	call	mosheman		; allocate from heap
	mov	ax,es
	inc	ax			; skip heap
	mov	es,ax
	push	ax			; save segment start for lator
	xor	di,di
	mov	cx,PARAKANSI*8
	mov	ax,-1			; make at all 0ff's
	cld
	rep	stosw			; clear out 64 byte buffer
	pop	ax
	pop	es
	mov	[tcbkbansi],ax		; save segment of keyboard area in tcb
noansi:

; initialize command processor
; set starting current psp address
; initpsp has been move to grp segment since mos segment
; can now be located in higmemory

	push	es
	mgetscb es
	lea	ax,initpsp
	mov	cl,4
	shr	ax,cl
	mov	cx,es
	add	ax,cx			; add grp segment address
	pop	es
	MSetPSP ax			; set system psp address
	push	es			; save tcb address
	push	cs
	pop	ds
	assume	ds:mos
	mov	ax,cs
	mov	[cmdseg],ax		; set segment of command line pointer

; allocate heap space for env. to pass a comspec= string
; and possibly a startbat= string

	mgetscb es
	assume	es:grp
	mov	di,offset scbshell	; command processor path
	xor	al,al			; terminator (asciiz)
	mov	cx,70			; long path possible
	cld
	repne scasb			; find end
	mov	ax,offset scbshell
	sub	di,ax			; calc length of command string
	mov	bx,di			; temp save length
	add	di,envlen1		; calc total len for env string
	mov	dx,di
	inc	dx			; room for terminating 0
	pop	es
	push	es
	assume	es:tcb
	les	di,dword ptr [tcbbatnm] ; this area used to store pointer to
	assume	es:nothing		; startup batch file string from addtask
	mov	si,di
	cmp	byte ptr es:[di],0
	je	nostbstr		; test for null string
	xor	al,al
	mov	cx,70
	cld
	repne	scasb			; measure it's length
	sub	di,si
	mov	si,di			; save length of string for later
	add	di,envlen2		; calc total length for environment
	add	dx,di
	jmp	short donestb
nostbstr:
	xor	si,si
donestb:
	add	dx,0fh			; calc # para's needed
	shr	dx,1
	shr	dx,1
	shr	dx,1
	shr	dx,1
	inc	dx			; room for prefix
	mov	ah,0			; allocate block
	call	mosheman
	assume	es:nothing		; points to heap block
	or	al,al
	jz	$+5
	jmp	miterr
	push	si
	mov	di,10h			; do not write over prefix
	mov	si,offset env1
	mov	cx,envlen1
	cld
	rep	movsb			; put env on segment boundary
	mov	ax,es
	inc	ax
	mov	[pblk],ax		; set env segment
	mgetscb ds
	assume	ds:grp
	lea	si,scbshell		; move command processor name to env
	mov	cx,bx			; get len to move
	cld
	rep	movsb
	pop	si
	or	si,si			; does a startbat string exist ?
	jz	donestb2
	push	si
	mov	si,offset [env2]
	mov	cx,cs
	mov	ds,cx
	mov	cx,envlen2
	assume	ds:mos
	cld
	rep	movsb
	pop	cx			; regain si, length of file name string
	pop	ds
	push	ds
	assume	ds:tcb
	lds	si,dword ptr [tcbbatnm]
	cld
	rep	movsb
	mgetscb ds
	assume	ds:grp
donestb2:
	xor	al,al
	stosb				; add terminating 0

; now load command processor

	pop	cx			; tcb address
	push	cx
	call	noswitch		; do not switch, ss will not be correct
	mov	si,ss			; save current stack
	mov	di,sp			; "
	cli
	mov	ss,cx			; ss must point to tcb for exec call
	assume	ss:tcb
	lea	sp,tcbstack-200h	; use tcb stack space (no harm done)
	sti
	mov	es,cx
	assume	es:tcb
	mgetscb ds
	assume	ds:grp
	push	si
	mov	[scbtcbpc],ss
	mov	dx,offset [scbshell]
	mov	ax,[scbtcbpf]		; creating fg task (task 0)?
	cmp	ax,[scbtcbpl]
	je	skipmjs2
	mov	dx,offset [comspec]
	mov	bx,cs
	mov	ds,bx
skipmjs2:
	mov	bx,cs
	mov	es,bx			; address parameter block
	assume	es:nothing
	mov	bx,offset pblk		; parameter block passed to exec
	clc
	mov	ax,4b01h		; create psp and load command processor
	int	21h			;  (do not execute it yet)
	jnc	$+5
	jmp	miterr			; error loading command processor
	assume	ds:nothing,ss:nothing
	mgetscb ds
	assume	ds:grp
	mov	cx,[scbtcbpf]
	cmp	cx,[scbtcbpl]		; fg?
	jne	$+5
	jmp	fgnostd 		; yes, already has std handles

; open std handles for task

	mov	es,[scbtcbpc]		; tcb starting
	assume	es:tcb
	push	ds
	push	cs
	pop	ds
	assume	ds:mos
	push	[tcboldpsp]
	push	[tcbpsp]		; save current (system)
	mov	ax,[pgm1+2]		; get psp address of load
	MSetPSP ax			; set to our psp (command processors)
	push	es
	mov	es,ax
	mov	ax,-1
	assume	es:pspseg
	push	di			; di being used to save sp
	les	di,[psppntr]		; get pointer to handle table
	mov	es:[di+0],ax		; clear any handle table
	mov	es:[di+2],ax
	mov	es:[di+4],ax
	mov	es:[di+6],ax
	mov	es:[di+8],ax
	pop	di
	pop	es
	assume	es:tcb
	mov	dx,offset stdaux1	; name for stdaux (handle 3, system 0)
	mov	ax,3d01h		; open for write
	push	[tcboldpsp]
	push	[tcbpsp]
	MSetPSP	0
	int	21h			; call mos
	jnc	tskdv1
	pop	[tcbpsp]
	pop	[tcboldpsp]
	jmp	miterr			; yes, driver init error
tskdv1:
	mov	dx,offset stdcon1	; name for stdcon (handles 0,1,2, system 1)
	mov	ax,3d02h		; open for read and write
	int	21h			; call mos
	jnc	tskdv2
	pop	[tcbpsp]
	pop	[tcboldpsp]
	jmp	miterr			; yes, driver init error
tskdv2:
	mov	dx,offset stdprn1	; name for stdprn (handle 4, system 2)
	mov	ax,3d01h		; open for write
	int	21h			; call mos
	pop	[tcbpsp]
	pop	[tcboldpsp]
	jnc	tskdv3
	jmp	miterr			; yes, driver init error
tskdv3:
	push	es
	mov	es,[tcbpsp]		; address system psp
	assume	es:pspseg
	push	di			; di being used to save sp
	les	di,[psppntr]		; get pointer to handle table
	mov	byte ptr es:[di+0],01	; set handle for stdin
	mov	byte ptr es:[di+1],01	; set handle for stdout
	mov	byte ptr es:[di+2],01	; set handle for stderr
	mov	byte ptr es:[di+3],00	; set handle for stdaux
	mov	byte ptr es:[di+4],02	; set handle for stdprn
	pop	di
	pop	es
	assume	es:tcb
	pop	[tcbpsp]		; get real current back
	pop	[tcboldpsp]
	pop	ds
	assume	ds:grp
	pop	ax			; retrieve segment of originator's tcb
	push	ax
	push	ds
	mov	ds,[scbtcbpc]		; segment of new tcb
	assume	ds:tcb,es:nothing

; initialize printer reservation time

        mov     dx, 273                 ; 18.2 * 15 = 273 ticks = 15 seconds.
	mov	[tcbhold], dx
	mov	[tcbhold+2], dx 	; for 3 physical printers
	mov	[tcbhold+4], dx
	cmp	word ptr [tcbcondd],0	; use mode according to terminal, if
	jne	tskv1			;   applicable
	push	ds
	mov	ds,ax
	mov	al,[tcbomode]		; else use original mode of originator
	pop	ds			; and restore ds to new tcb
	jmp	tskv2
tskv1:
	mov	al,7			; monochrome mode
	test	[tcbvram],60h
	jz	tskv2			; z if neither color nor graphics
	mov	al,3			; color 80x25 alpah mode
tskv2:
	mov	[tcbomode],al		; original mode for new one
	pop	ds
	assume	ds:grp,es:tcb
fgnostd:
	cli
	pop	ss
	mov	sp,di
	sti
	call	swcaller		; switch caller in
	mov	ax,[scbtcbpf]
	cmp	ax,[scbtcbpl]		; if setting up the background task
	je	fgxx
	cmp	[scbmmfg],'Y'		; and no mm
	je	fgxx
	assume	ss:tcb
	mov	ax,[tcbbegad]
	mov	[scbmastv],ax		; restore video pointer
fgxx:
	call	okswitch		; ok to switch, stack is back
	mov	ax,[pblk]
	dec	ax
	mov	es,ax			; address heap block to deallocate
	mov	ah,1
	call	mosheman		; deallocate block
	or	al,al
	jz	$+5
	jmp	miterr

; set up tasks dta

	pop	es
	assume	es:tcb
	mov	ds,[pgm1+2]		; get starting seg for task
	assume	ds:nothing
	mov	dx,80h			; set up default dta
	mov	[tcbdta],dx
	mov	[tcbdta+2],ds

; set registers up in tcb stack for task selection time

	mov	ax,es			; entry es, tcb address to init
	mov	ds,ax
	call	set_conly		; init tcbconly
	mov	bx,sp			; temp save
	mov	cx,ss			; "     "
	cli
	mov	ss,ax
	lea	sp,tcbstack
	sti
	assume	ss:tcb
	mov	[tcbstkp],sp		; entry stack used with mossaver
	lea	ax,ntrtsk		; routine for initial task entry
	push	ax			;  entered from mosnxtsk's exiting RET
	mov	ax,[pgm1+2]		; get psp address of command processor
	MSetPSP	ax
	mgetscb ds
	assume	ds:grp
	push	ax			; ds
	push	ax			; es
	cmp	[scbreg32],'Y'
	je	stk386
	xor	ax,ax
	push	ax			; bp
	push	ax			; di
	push	ax			; si
	push	ax			; dx
	push	ax			; cx
	push	ax			; bx
	push	ax			; ax
	pushf				; starting flags
	jmp	stkprepx
stk386:
	db	66h
	push	sp			; esp
	push	ax			; gs
	push	ax			; fs
	xor	ax,ax
	db	66h
	push	ax			; ebp
	db	66h
	push	ax			; edi
	db	66h
	push	ax			; esi
	db	66h
	push	ax			; edx
	db	66h
	push	ax			; ecx
	db	66h
	push	ax			; ebx
	db	66h
	push	ax			; eax
	db	66h
	pushf				; eflags
stkprepx:
	push	ax			; start saved value for scbnoswt (0, see tsl)
	mov	[tcbsp],sp		; set up for mosnxtsk
	mgetscb ds
	assume	ds:grp
	mov	al,2*2			; reorder to last for priority 2
	push	si
	push	dx
	push	cx			; (es -> tcb, al = priority*2)
	push	bx
	call	reordlst
	pop	bx
	pop	cx
	pop	dx
	pop	si
	xor	ax,ax
	cli
	mov	ss,cx			; restore callers stack
	mov	sp,bx
	sti
	assume	es:tcb,ss:nothing
	mov	bx,[scbtcbpf]
	cmp	bx,[scbtcbpl]		; is this the fg?
	je	mosoend1		; no, clear switching flags
	call	okswitch
	mov	[scbnotsl],'N'		; ok to task switch now (bank switch)
	mov	[skipsw],'N'		; ok to go through switchif
	jmp	mosoend
mosoend1:
	mov	byte ptr [skipswt],'N'	; reset flag for int8 logic (swtasktm)
mosoend:
	clc				; no errors
mositend:
	pushf				; save flags and error code
	push	ax
	jc	$+5
	jmp	mositxx
	call	okswitch
	mov	[scbnotsl],'N'		; ok to task switch now (bank switch)
	mov	[skipsw],'N'		; ok to go through switchif

; if cy, do error cleanup based on value in bp

	test	bp,32			; task has been register
	jz	mositnrg
	cmp	word ptr [tcbunreg+2],0 ; is there an unregister
	je	mositnrg		; handler
	push	ds
	push	es
	pop	ds			; make sure ds has tcb
	call	dword ptr [tcbunreg]	; if so call it
	pop	ds
mositnrg:
	test	bp,16			; context switch in????
	jz	mositxsw
	call	swcaller		; switch caller back in
mositxsw:
	test	bp,1			; bit 0 - context block
	jz	mositxa
	mgetscb ds
	assume	ds:grp
	cmp	[scbmmfg],'Y'		; using mm ?
	jne	mositxa1
	mov	bx,[tcbcntxpt]		; yes
	mov	cx,1
	mov	ah,2
	call	[scbmmsub]		; de-allocate from extended memory
	jmp	mositxa
mositxa1:
	mov	es,[tcbcntxpt]		; de-allocate from smp
	mov	ah,1
	call	mosheman
mositxa:
	test	bp,2			; bit 1 - task ram block
	jz	mositxb
	mov	ah,2
	mov	bx,[tcbmmhdl]
	mov	cx,[tcbmmpgs]
	call	[scbmmsub]		; de-allocate task memory
mositxb:
	test	bp,4			; bit 2 - vidram block
	jz	mositxc
	mov	bx,[tcbvmhdl]
	mov	cx,[tcbvmpgs]
	mov	ah,2
	call	[scbmmsub]		; de-allocate vidram memory
mositxc:
	test	bp,8			; bit 3 - video save block
	jz	mositxx
	mov	bx,[tcbvidh1]
	mov	cx,[tcbvidp1]
	mov	ah,2
	call	[scbmmsub]		; de-allocate video save memory
mositxx:
	pop	ax			; recover error code
	popf

; the following logic was done so that disk io switching is restore
; when addtask is completed

	mov	bp,ax
	dec	[scbi15off]		; re-enable disk busy switching
	mov	ax,bp
	pop	bp
	ret				; end mositask
miterr:
	call	bugerror
	db	'  '
	db	'Cannot start task - MOSITASK error       ',0  ;@@xlat

	subttl swcaller - switches caller into memory
	page
;======================================================================
;,fs
; swcaller - switches caller into memory
; 
; in:
; 
; out: 
; 
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:nothing
swcaller:
	push	es
	push	ss
	pop	es			; restore original task ram
	call	switchtask
	and	bp,not 16		; indicate task not switch in
	pop	es
	ret

	subttl	inidvars - initialize a task's fake DOS variable table.
	page
;======================================================================
;,fs
; inidvars - initialize a task's fake DOS variable table.
;  
; updated 08/25/88 sah to add pointer to sft for ms-windows
; Updated 01/22/91 SAH added supported for dos device driver list
;		       lastdrive and made sure that CDS (Current 
;		       directory structure) is not installed
;
; in:	es points to tcb to initialize
;  
; out:  
;  
;,fe
;======================================================================
	assume	ds:nothing,es:tcb,ss:nothing
inidvars:
	push	ds
	mgetscb ds
	assume	ds:grp
	mov	ax,[scbdosver]
	mov	[tcbversn],ax		; set tcb dos vers #
	mov	ax,[scbbufsz]
	mov	[tcbsecsiz],ax		; fake dos sector size
	mov	word ptr [tcbdpbpf],offset [bdbdpb]  ; offset of dpb
	mov	ax,[scbbdbpf]		; segment for first dpb
	mov	word ptr [tcbdpbpf+2],ax
	mov	word ptr [tcbdpbpo],offset tcbdinfo    ; CDS is not supported
	mov	word ptr [tcbdpbpo+2],es
	mov	word ptr [tcbsftptr], offset gfbnsft
	mov	ax,[scbgfbpf]
	mov	word ptr [tcbsftptr+2],ax
	mov	word ptr [tcbfcbptr], -1
	mov	word ptr [tcbfcbptr+2],-1
	mov	word ptr [tcbdinfo],-1
	mov	word ptr [tcbdinfo+2],-1
	mov	al,[scbldrive]
	mov	[tcblastdrv],al			; set lastdrv
	cmp	word ptr [scbdrvr],offset scbnul
	jne	skipdvar

; The  following code is  to set up NUL device header in DOS variable
; table, please notice that we must also set up far jump table for
; stradegy and interrupt routines in TCB.  

	push	si
	push	di
 	lds	si,[scbdrvr]
	mov	di,offset tcbddpf
	mov	word ptr es:[di],si
	mov	word ptr es:[di+2],ds
	mov	ax,word ptr [si+4]
	mov	word ptr es:[di+4],ax
	mov	word ptr es:[di+6],offset tcbddjmp1
	mov	word ptr es:[di+8],offset tcbddjmp2
	add	si,10
	add	di,10
	movsw
	movsw
	movsw
	movsw
	sub	si,10

; initialized far jump to stradegy routine

	mov	di,offset tcbddjmp1
	mov	al,0eah
	stosb
	mov	ax,word ptr [si+6]
	stosw
	mov	ax,cs
	stosw		

; initialized far jump to interrupt routine

	mov	di,offset tcbddjmp2
	mov	al,0eah
	stosb
	mov	ax,word ptr [si+8]
	stosw
	mov	ax,cs
	stosw		
	pop	di
	pop	si
skipdvar:
	pop	ds
	ret

	subttl findcomspec - search calling task's env for COMSPEC=
	page
;======================================================================
;,fs
; findcomspec - search calling task's env for COMSPEC=
; 
; in:
; 
; out: 	zr means found a match, ds:dx -> comspec string
; 	nz no match, ds:dx undefined
; 
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:tcb

comspec db	80 dup(0)		; storage for the comspec string

findcomspec:
	push	ax
	push	cx
	push	si
	push	di
	push	es
	mov	es,[tcbpsp]
	mov	es,es:[2ch]		; get environment segment
	xor	di,di
	push	cs
	pop	ds
	assume	ds:mos
envu:
	cmp	byte ptr es:[di],0
	je	enve			; found end of environment
	mov	si,offset [env1]
	mov	cx,8
	rep	cmpsb
	je	envy			; found match
	dec	di
envw:
	inc	di
	cmp	byte ptr es:[di],0
	jne	envw
	inc	di			; find end of string
	jmp	envu
envy:
	mov	dx,di
	push	es
	pop	ds			; point to string with ds:dx
	cmp	al,al			; set zr
	jmp	envx
enve:
	mov	al,ah
	inc	al
	cmp	al,ah			; set nz
envx:
	pop	es
	pop	di
	pop	si
	pop	cx
	pop	ax
	ret

	subttl	upd4013 - update 40:13 in context save area
	page
;======================================================================
;,fs
; upd4013 - update 40:13 in context save area
; 
; this routine relies on the position of the 40:13 data as it
; presently (7/22/87) appears in a compressed context save area
; if you change the savtable in moscntxt, update this proc
; 
; in:	es -> new task's tcb,
; 	dx -> context save area
; 
; out: 
; 
;,fe
;======================================================================
 	assume	ds:nothing,es:tcb,ss:nothing
upd4013:
	push	ax
	push	ds
	mov	ax,[scbfree]
	add	ax,[tcbendad]
	shr	ax,1
	shr	ax,1
	shr	ax,1			; predict 40:13 setting for the new task
	shr	ax,1
	shr	ax,1
	shr	ax,1
	mov	ds,dx
	assume	ds:nothing
	mov	ds:[0413h],ax		; modify 40:13 in the new task's context
	pop	ds
	pop	ax
	ret

	subttl	setbegend - set tcbbegad and tcbendad
	page
;======================================================================
;,fs
; setbegend - set tcbbegad and tcbendad
; 
; assign the current value in scbfree to tcbbegad.  use the paragraph
; count in tcbendad to calculate the actual value for tcbendad
; 
; in:	es -> new task's tcb
; 	ds -> grp
; 
; out: 
; 
;,fe
;======================================================================
 	assume	ds:grp,es:tcb,ss:nothing
setbegend:
	push	ax
	push	bx
	mov	ax,[scbfree]
	mov	[tcbbegad],ax
	mov	bx,[tcbendad]
	add	ax,bx
	mov	[tcbendad],ax
	pop	bx
	pop	ax
	ret

	subttl	initmcb - initialize the header info for the first mcb
	page
;======================================================================
;,fs
; initmcb - initialize the header info for the first mcb
; 
; in:	ax -> segment address to locate the mcb
; 	es -> tcb of new task
; 
; out:
; 
;,fe
;======================================================================
 	assume	ds:nothing,es:tcb,ss:nothing
initmcb:
	push	bx
	push	es
	mov	[tcbmbpf],ax		; record start of mcb chain in tcb
	mov	bx,[tcbendad]
	sub	bx,ax			; calc size

if	code286
	and	bl,11111000b		;022688  enforce proper multiple for 286
endif

	dec	bx			; don't include preifx
	mov	es,ax
	assume	es:nothing
	mov	byte ptr es:[0],'Z'	; mark as last block
	mov	word ptr es:[1],0	; mark as free
	mov	es:[3],bx		; record size
	pop	es
	assume	es:tcb
	pop	bx
	ret

	subttl	initstation - initialize station type
	page
;======================================================================
;,fs
; initstation - initialize station type
; 
; initializes tcb station type for task being added.  
; sets up tcbstation as the following:
; 
; in:	es -> tcb of new task
;	ss -> tcb of current task (the one doing the addtask)
;
; out:	00 - mono
; 	01 - cga
; 	02 - ega
; 	03 - vga
; 	04 - herc
; 	05 - monochrome ega
; 	06 - monochrome vga
; 
;,fe
;======================================================================
 	assume	ds:nothing,es:tcb,ss:nothing
initstation:
	push	ax
	push	si
	mov	si,offset [tcbcondd]
	mov	al,4			; this is hercules
	test	[tcbvram],10h		; hercules
	jnz	isdone

; don't  do EGA\VGA testing if console is not a master consoe

	mov	al,1			; indicate cga
	test	[tcbvram],80h
	jz	ismterm
	mov	al,3			; indicate vga

; if [tcbcondd] != 0 then we need to use the dcbios value of the 
; new task (es->tcb).  
; otherwise, we need to use the dcbios value of the current 
; task (ss->tcb).

	mov	ah,es:[si].dcbios
	cmp	word ptr [tcbcondd+2],0
	jne	is1
	mov	ah,ss:[si].dcbios
is1:
	test	ah,2			; vga bios
	jnz	ismchk
	dec	al
	test	ah,1			; ega bios
	jnz	ismchk
	dec	al			; make it cga
ismterm:
	test	[tcbvram],60h		; cga graphics or color supported
	jnz	isdone			; cga bios
	xor	al,al			; monochrome bios
	jmp	short	isdone
ismchk:
	test	[tcbvram],40h		; cga graphics supported
	jnz	isdone			; make it ega or vga
	add	al,3			; make it monoega or monovga
isdone:

; the following logic is use just incase user desides to fill memory
; above 640k with vtype, so we must indicate that station does not
; support enhance graphics.
;   all color ega\vga are converted to cga tasks
;   all monochrome ega\vga are converted to mono tasks

	cmp	al,2			; mono or cga
	jb	isset			; no need for this test
	cmp	al,4			; hercules
	je	isset			; no need for this test
	push	ds
	mgetscb ds
	assume	ds:grp
	test	[scbvtype],80h		; did user request to fill memory
	pop	ds
	assume	ds:nothing
	jz	isset			; no...continue

; user wish to fill memory with vtype=xf
; we must convert and protect tasks

	mov	ah,1			; force to cga
	cmp	al,4			; for ega and vga convert to cga
	jb	istrans
	xor	ah,ah			; set mono for monochrome ega\vga
istrans:
	mov	al,ah			; set up for storing tcbstation
isset:
	mov	[tcbstation],al

	pop	si
	pop	ax
	ret

	subttl inittcb - initialized constant tcb variables
	page
;======================================================================
;,fs
; inittcb - initialized constant tcb variables
; 
; initializes tcb variable for new task.  all non-zero tcb variables
; should be put here.
;
; in:
; 
; out:	
; 
;,fe
;======================================================================
 	assume	ds:nothing,es:tcb,ss:nothing
inittcb:
	push	ax
	push	ds
	mgetscb ds
	assume	ds:grp
	mov	ax,word ptr [scborg38]	; set task copy of int 38\d4
	mov	word ptr [tcbtsk38],ax	; vector to original vector
	mov	ax,word ptr [scborg38+2]; save at init time
	mov	word ptr [tcbtsk38+2],ax
	mov	ax,[scbtcbpf]		; creating fg task (task 0)?
	cmp	ax,[scbtcbpl]
	je	initt1
	mov	[tcbalt999], 0ffh	; initialize pam switch flag
initt1:
	mov	word ptr [tcbprgnm],2020h
	mov	word ptr [tcbprgnm+2],2020h
	mov	word ptr [tcbprgnm+4],2020h
	mov	word ptr [tcbprgnm+6],2020h
	mov	word ptr [tcbprgnm+8],2020h
	mov	byte ptr [tcbprgnm+10],20h
	mov	[tcbkboff],-1		; initialize key assignment pointer
	mov	[tcbansi],0ffh		; initialize ansi support to on
	mov	[tcbbegad], 0		; initialize beginning address
	mov	[tcbibsiz], 128 	; initialize input buffer size
	mov	[tcbauxbt], 20h 	; initialize aux port to etx/ack
	mov	[tcbauxct], 64		; initialize etx/ack count
	mov	[tcbspskp], 'N' 	; initialize the spooler flag
	mov	[tcbpri], 4		; initialize the task priority
	mov	[tcbkbfst], 5		; initialize fast int16 count
	mov	[tcbkbmax], 8		; initialize max keyboard count
	mov	[tcbkbtck], 18		; initialize int16 time out coun
	mov	[tcbfsavr], 'N' 	; initialize the mossaver flag
	mov	[tcbibase], 200h	; initialize keyboard buffer poi
	mov	[tcbntry], shareretry	; initialize sharing/lock values
	mov	[tcbttry], shareticks	; initialize sharing/lock values
	mov	[tcb$ca],7		; set attribute to normal
	mov	[tcb$asi],'Y'		; set ansi mode on
	mov	[tcb$kp],'N'		; no extended keys pending
	lea	ax,doesc		; routine in console driver
	mov	[tcb$er],ax		; esc routine to 1st one
	mov	[tcb$ef],'N'		; no esc seq pending
	lea	ax,tcb$eb		; esc buffer
	mov	[tcb$ebp],ax		; buffer pointer to start of buffer
	mov	[tcb$wrap],'Y'		; sah wrap eol is on
	mov	[tcbconfg],1bh		; init tcb miman data
	mov	[tcbpam],'N'		; start out with no pam'ing allowed
	mov	[tcbcon417],-1		; for keykeys to set value
	mov	[tcbtslnst],1		; task specific tsl nest counter
	pop	ds
	assume	ds:nothing
	pop	ax
	ret

	subttl calclim - return upper task memory limit to be used
	page
;======================================================================
;,fs
; calclim - return upper task memory limit to be used
;
; determine upper task memory limit to be used based on scbvtype
; 
; in:	ds ->grp
; 
; out:	ax = upper segment limit
; 
;,fe
;======================================================================
 	assume	ds:grp,es:nothing,ss:nothing
calclim:
	push	bx

; check SCB4013 to be multiable of 64k

	mov	ax,[scb4013]
	mov	bx,ax
	and	bx,0fc0h
	cmp	ax,bx
	je	cc0
	shr	ax,1
	shr	ax,1
	mov	ah,al
	xor	al,al
	jmp	short cc1  			; not a multiable of 64k
cc0:
	mov	ax,0a000h		; default limit -- assumes ega needs a000
	mov	bh,[scbvtype]
	and	bh,7fh			; mask off high bit
	cmp	bh,0
	je	cc1
	cmp	bh,1
	jne	cc2
	mov	ax,0b000h		; vtype=1 means no ega, limit at b000
	jmp	cc1			; could have mono and/or cga tasks
cc2:
	cmp	bh,2
	jne	cc3
	mov	ax,0b000h		; vtype=2 means only mono, limit at b000
	jmp	cc1			; only use 4k for video save area
cc3:
	cmp	bh,3
	jne	cc4			; vtype=3 means only cga, limit at b400
	mov	ax,0b400h		; allow b400 to be used by cache driver
	jmp	cc1			; no mono tasks
cc4:
	mov	ax,0b800h		; vtype=4 means only cga, limit at b800
	cmp	bh,4
	je	cc1
	mov	ax,0b000h		; assuming vtype=5 for hercules

; the following was added so that you can't add a large task on
; co-resident ega or vga

	push	es
	mov	es,[scbtcbpf]		; get first tcb
	assume	es:tcb
	mov	bl,[tcbstation] 	; get station type
	pop	es
	assume	es:nothing
	cmp	bl,2			; ok if mono-chrone or cga
	jb	cc1
	cmp	bl,4			; ok if hercules
	jae	cc1
	mov	ax,0a000h		; make limit be a000 to ega\vga will not crash
cc1:
	pop	bx
	ret

	subttl set_conly - set tcbconly based on the watchers
	page
;======================================================================
;,fs
; set_conly - set tcbconly based on the watchers
;
; in:	ds -> tcb to check
;
; out:	ds:[tcbconly] updated
;
;,fe
;======================================================================
	assume	ds:tcb,es:nothing,ss:nothing
set_conly:
	push	es
	mov	[tcbconly],0		; init to not con-only
	cmp	[tcbscrdd],0		; if no watchers, keep tcbconly == 0
	je	stcn1
	mov	es,[tcbscrdd]		; reference the watcher's tcb
	assume	ds:nothing,es:tcb
	cmp	[tcbnxtdd],0		; if there is another watcher
	jne	stcn1			; keep tcbconly == 0
	test	[tcbvram],80h		; if this one watcher's 
	jz	stcn1			; vram & 80 == 0, keep tcbconly == 0
	assume	ds:tcb,es:nothing
	mov	[tcbconly],1		; mark this task as having one and
stcn1:					; and only one con-only type watcher
	pop	es
	ret

	subttl ntrtsk - enter new task
	page
;======================================================================
;,fs
; ntrtsk - enter new task
; 
; this routine passes control on to a new task when it has been
; selected by the mos task selection logic.
; 
; in:	tasks registers are all set except for ss:sp and cs:ip
; 
; out:
; 
;,fe
;======================================================================
 	assume	ds:nothing,es:nothing,ss:nothing
ntrtsk:
	push	ds
	mgetscb ds
	assume	ds:grp
	mov	ds,[scbtcbpc]
	assume	ds:tcb

; check for task <64k

	mov	ax,[tcbendad]
	mov	bx,es			; psp address
	sub	ax,bx
	xor	bx,bx			; assume >64k, start stack at 64k (com file)
	cmp	ax,1000h
	ja	tskszok

; task size <64k, set stack to top of task memory

	shl	ax,1			; calc offset from # para's
	shl	ax,1
	shl	ax,1
	shl	ax,1
	mov	bx,ax			; offset for sp when task < 64k
tskszok:
	pop	ds
	assume	ds:nothing
	mov	ax,es			; tasks psp address
	cli
	mov	ss,ax
	mov	sp,bx			; set to top of task if task<64k else 64k
	sti
	xor	bx,bx
	push	bx			; 0 to top of stack
	push	ax			; cs
	mov	ax,100h
	push	ax			; ip

; set proper video mode & equipment flags.

	push	es
	mgetscb es
	assume	es:grp
	mov	es,[scbtcbpc]
	assume	es:tcb

; make sure that we update TCBKBSHFT to value at 40:17 so
; that INT 9 logic will have correct shift state

	push	ds
	mov	ds,[sbios]
	mov	al,byte ptr  ds:[0017h]
	mov	[tcbkshft],al
	pop	ds
	cmp	[tcbid],0		; foreground task?
	jne	tskv2a
	jmp	tskv5			; if foreground, leave modes & flags alone
tskv2a:

; vna currently uses pc keyboards which don't allow for
; changing lights - reset to keyboard w/ lights emulating pc
; keyboard appears to clear lights, so we clear toggles here

	mov	dx,es			; remember tcb
	mov	al,[tcbomode]
	test	[tcbvram],08h		; is it a vna task?
	jz	tskv2b
	mov	[tcbkshft],0		; start vna task w/ no toggles
	mov	es,bx			; bx will be zero here
	assume	es:nothing
	mov	byte ptr es:[417h],0	; bios ram no toggles also
tskv2b:
	mov	es,bx			; bx will be zero here
	cmp	al,7			; set task's new video capability
	je	tskv3			; if monochrom mode, set mono adapter
	mov	cx,0b800h		; tcbvidw2
	and	byte ptr es:[410h],not 30h  ; say color adapter
	or	byte ptr es:[410h],20h
	mov	word ptr es:[463h],3d4h ; set crt base to color
	jmp	tskv4
tskv3:
	mov	cx,0b000h		; tcbvidw2
	or	byte ptr es:[410h],30h	; it's a monochrome
	mov	word ptr es:[463h],3b4h ; set crt base to mono
tskv4:
	mov	ah,es:[410h]
	push	ds
	mov	ds,dx			; back to the tcb
	assume	ds:tcb
	mov	[tcbequip],ah		; reflect current video state
	pop	ds
	assume	ds:nothing
	mgetscb es			; make sure new vidram address gets
	assume	es:grp			; switched in when needed

; mjs 3/24/88 not worried about mismatch between machine state and scbtcbvr
; cuased by this assignment becuase the task is just starting - so the
; chances of it getting an irq before swvidram gets called should be slim

	mov	[scbtcbvr],0
	push	es
	mov	es,dx
	assume	es:tcb
	test	[tcbvram],08h		; if its a vna task, skip the setting
	pop	es
	assume	es:grp
	jnz	tskv4a
	mov	[scbtcbvr],-1
tskv4a:
	mov	es,dx			; set vidram address as appropriate
	assume	es:tcb
	mov	[tcbvidw2],cx

; set the mode - mode should still be in al from above

	xor	ah,ah
	int	10h			; set new video mode

; set tcbvideo based on the video mode

tskv5:
	mov	ah,1
	cmp	[tcbomode],7
	je	tskv6
	mov	ah,2
tskv6:
	mov	[tcbvideo],ah

; initialize tcborig8 and orig1c so that tsl can detect when a task
; has a timer intercept

	push	ds
	mgetzero ds
	assume	ds:nothing
	mov	ax,ds:[8*4]
	mov	[tcborig8],ax
	mov	ax,ds:[8*4+2]
	mov	[tcborig8+2],ax
	mov	ax,ds:[1ch*4]
	mov	[tcborig1c],ax
	mov	ax,ds:[1ch*4+2]
	mov	[tcborig1c+2],ax
	pop	ds
	assume	ds:nothing
	mov	[tcbcon417],-1		; force Led Lights on
	mov	[tcbpam],'Y'		; allow pamswitching now
	mov	[tcbrstok],1		; allow task restart to run on this task
	mgetscb es
	assume	es:grp
	mov	[scbinmos],0		; set inmos flag to 0 for new task
	pop	es
	xor	ax,ax
	retf				; enter new task

	subttl vertask  - verify task smp requirements
	page
;======================================================================
;,fs
; vertask  - verify task smp requirements
; 
; heap storage calucations and assumptions
; 8087/80287	96 + 16 bytes if available
; minimun smp	8k after task is created
; 
; in:	es -> tcb
; 	ds -> grp
; 
; out:	no carry -  everything checks out, go ahead
; 	carry	 -  smp requirements are too large  (don't Continue)
; 
;,fe
;======================================================================
 	 assume ds:grp,es:tcb,ss:nothing
vertask:
	push	ax
	push	bx
	push	cx
	assume ds:grp,es:tcb,ss:nothing
	call	noswitch		; no switch or results could be wrong
	mov	ax, [scbtcbpf]		; is this foreground
	cmp	ax, [scbtcbpl]
	clc
	je	vtaskend		; skip assume to be good
	mov	ax,(8*1024/16)		; paragraphs for 8k minimun
	cmp	[scbsw87], 'Y'		; 8087/80287??
	jne	vtask2
	add	ax, 7			; 7 paragraphs (need 94 bytes and header)
vtask2:

; at this point we calculated number of estimated smp for task
; and operating system to work correctly together.  check whats
; available and make sure it fits our needs.  # of paragraphs
; need are in ax.

	push	ax
	push	es
	mov	bx, [scbhpadr]
	xor	ax, ax
	call	sumheap
	mov	bx, [scbhp2adr]
	call	sumheap
	mov	bx, ax			; place size in ax
	pop	es
	pop	ax
	cmp	bx, ax
	ja	vtaskend
vtaskend:
	call	okswitch		; ok to switch
	pop	cx
	pop	bx
	pop	ax
	ret

	subttl sumheap - calculate total smp paragraphs
	page
;======================================================================
;,fs
; sumheap - calculate total smp paragraphs
; 
; in: 
; 
; out:	
; 
;,fe
;======================================================================
sumheap:
vtask3:
	 or	bx, bx			; last block
	 jz	vtask5
	 mov	es, bx
	 cmp	byte ptr es:[1], 'Z'	; free
	 jne	vtask4			; no..skip..it
	 add	ax, es:[2]		; add size
vtask4:
	 mov	bx, es:[4]		; get next block
	 jmp	short vtask3
vtask5:
	 ret

mositask endp

mosseg	ends
	end

