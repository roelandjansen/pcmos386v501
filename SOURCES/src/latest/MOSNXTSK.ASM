	include page.inc
	title	mosnxtsk - mos next task (suspend)
extrn bugerror:near
comment ^===============================================================
		      development specification

 program name:	$$mos.sys		assigned to: david morrow
 module name:	mosnxtsk		assign date: 10/30/86
 purpose:	to select the next task to run.
 last update:	08/18/1992
========================================================================

jrb 07/16/87	added priority logic to tsl, rewrote reordlst
		bump priority of task waiting on key, dec it when unblocked

sah 07/30/87	change tsl logic for addtional wait field for vidram

sah 08/03/87	added conditional assembly of task debuging routines
		for evaluating the performace of pc-mos/386
sah/jrb 	corrected problems with ss pointing to tcb and inc.
		and dec. task priority on keyboard loops

sah 08/12/87	made sure that when inside mosint08 that chain table is
		uptated for int 08 just in case some one desided to
		change int 08 vector before chkirq could fixed it. this
		fixes the problem with boland's Turbo BASIC.

mjs 8/16/87	modified code at tsl8 so that getkeys will get called
		when a task is suspended in a situation where pressing
		a key doesn't end the wait condition.  discovered the
		need when found that you couldn't pam switch out of a
		task that was waiting in the pipe driver.

rbr  8/17/87	replaced sah's update (8/12/87) to force origin type 0
		if the application zaps the int8 vector and then passes
		to our int8 handler. this was done because getkeys
		cannot be called with the user's stack in effect.
		now we can run both turbo basic and turbo pascal.

mjs 8/31/87	modified the dotcbirp procedure to use swcntxt so irq's
		cause a context switch along with a task ram switch.

sah 09/09/87	added code for handling of vga state suspention. change
		tcb variable  tcbega which has 3 bits
		bit 0 = 1 if in ega\vga mode
		bit 1 = 0 if ok to state-pam  1 if not ok
		bit 2 = 1 if task should be suspend (state pam)
		0 if should not be suspended
		when getkeys is call during mosint08, state pamming is
		not ok because problems with origin type 2 which we can
		can't suspend the task.  State pamming is ok during tsl
		and if getkeys some how get call outside tsl state pam
		should also be not ok. (if call was made to getkeys
		outside tsl and mosint08 by someone - currently not so)

mjs 10/1/87	rewrote int8, tsl and serial irq handling.  calling of
		int8 intercepts has been moved from tsl to int8.  tsl
		still detects when a suspended task is getting behind
		in its ticks but now passes a signal to int8 rather than
		making the calls directly.  serial irq logic has been
		extended to not require a mos useirq to be done if it is
		not ambiguous as to which task should get the irq.
		when it is ambiguous, a signal is set which tsl detects
		and which causes tsl to pop up a critical error window
		to notify the user than an irq occured which nobody got.
		also, removed call to getkeys in mosint08, origin type 2
		(there are several references to special action because
		this of that call which are now meaningless)

sah 10/06/87	added addtional code to handle turning on and off the
		ega io protection on the 386.	if task supports state
		saving and tcbvideo flag is set then io protection is
		turn on.

mjs 10/12/87	added management of the tcbbpcnt variable which prevents
		a suspended task from losing ticks when it needs those
		ticks to do background printing.
		added management of the pamskip variable which causes
		a bypass in swtasktm if in the middle of pamswitching.

sah 10/20/87	added conditional code for demo version of pc-mos/386

sah 10/26/87	varous addtions for ega state logic

sjc 11/20/87	found hardware interrupts occurring in middle of swcall
		also hw irq's were not completely masked.
		masked the irq's and deleted an unneeded STI, added it
		in the proper place (after hw irq's were enabled again)

mjs 11/24/87	irma needs to be allowed to nest one level deep in their
		int8 isr so i removed the setting of the re-entrance
		control flag "in08".  this basically means anyone who
		sets up the possiblity of nesting within int8 must have
		their own re-entrance control.	that's not asking too
		much, is it???

mjs 11/30/87	removed int8 and int1c from chain table managment.
		reworked most of mosint08 and the part of tsl which
		detected if a suspended task has an timer isr.

jrb 12/01/87	fixed problem of key repeat in one partiton locking
		up looper partitions

mjs 12/8/87	add logic to suspend to detect when mos is looping in
		kbpoll00 from mosint16, function 0.  when this is
		detected, periodically force a return from suspend.
		when back in mosint16, will test for this special return
		and issue an int28  then return to suspend.  done this
		way because can't issue an int28 from suspend or crazy
		things would happen.

jrb 12/22/87	mask only timer and keyboard ints during handling of
		serial irq for intercepter comm task

mjs 1/1/88	changed tsl to use scbtimer because an independent
		timer is needed.  an application which changes the
		40:6c timer can upset task selection if 40:6c is used
		for period measuring (e.g. maxthink).  increment
		scbtimer in chkwrap.

sah  01/19/88	change scbseg and zero seg access to use mgetxxx macros

mjs 2/8/88	add test to mosint08 so a task switch doesn't occur if
		scbttrap != 0.	this indicates that i/o has been done
		to the timer/counter chip that put it in a non-standard
		mode or the i/o sequence is still in progress.
		also added logic to re-program the timer/counter chip
		to match the new task if not the same as the last task.

sah/rbr 02/21/88 move ddt segment to mo2 group

rbr 02/29/88	moving notsl,intsl,lagtcb,pamskip,irqwflag to grp.

mjs 3/30/88	put in an int2f handler which will provide an indication
		that the share tsr is installed.  this is for the sake
		of applications like rm/cobol which test for share.
		also, added port specific reservation logic to the
		serial irq handler and made the swcall routine switch
		video as well as task ram and context.	see the file
		\mos.dir\utils.dir\vidmods.doc on the server for info.

mjs 4/24/88	bug fixes to serial irq and video logic.

mjs 5/2/88	various mods to secure the video logic against video
		switching serial irq's.  Added calls to the ddtlw proc.
		added code to process port specific serial irq's.

jrb 5/02/88	add testflush like testirqw to check periodically for
		polled flush errors can be handled w/ an int 24h
		now that the responsible task is switched in

mjs 5/16/88	add skipswvs to make switchg skip the call to swvidsave.
		this is for the case where swcall will call switchgp and
		the video save area doesn't need to be mapped in for a
		serial irq.
		transferred jrbu changes from server copy: mosnxtsk.mjs

sah 05/17/88	if sunriver style video, (bit 2 of tcbvram set), don't
		turn on io protection.
sah 05/23/88	remove mjs's 12/08/88 additions for INT 28 support,
		since it has be revamp so that works like dos.	see
		resident.doc on the utils.dir on the server

mjs 5/29/88	rewrote the procedure swtasktm to be secure against
		serial irq's which switch video.

mjs 6/6/88	corrected buggy changes in swtasktm.

mjs 6/22/88	modified int8 logic to work with new lidt based
		interrupt management scheme.  still need to fix int1c
		handling.  also removed scbnoswt test from chkslice
		to prevent keyboard lockup when packet/pc is popped up.

sah 06/29/88	if mos is on our stack during serial irq handling, made
		sure tcbstkp was bias around calls to application's IRQ
		handler.  also after talking with mjs, improved int 8
		stack biassing.  this help in correcting irq crashing of
		packet/pc.  made sure that scbinirq was set during
		entire serial irq.  during the actual call to isr, 8259
		mask is return to original mask.

mjs 7/2/88	took out mmparm struc and added 'inlude macros.inc' for
		access to the common mmparm struc.

mjs 7/7/88	modified stack biasing technique used in lidtint08 and
		the serial irq handling logic to account for the case
		where the irq occurs while mos is on a tcb stack which
		is different from the scbtcbpc stack.
		also, trimmed out old, unused code - can always see it
		again using pvcs.

sah 07/08/88	update my 06/29 for new tcb variable tcbirqmsk

mjs 7/13/88	implemented re-grab logic for int8.  this is similar
		to the chain table management scheme but simpler.
		it allows us to retain control of int8 when an app
		or driver changes it.

mjs 7/14/88	corrected a couple of segment assignments to use the
		mgetzero macro.

sah 08/04/88	before calling cursysch, make sure that the tcbcpos has
		the value that bios data area has.  this is necessary
		because of the unisys 386 printscreen set cursor
		directly in bios data area.

mjs 8/10/88	re-worked int8 handling logic and modified tsl to
		correct problems with tsr's that pop up on an int8
		intercept.  these changes manipulate the inmos flag to
		only allow a tsr to pop up under controlled conditions.
		the procedure swtasktm has been removed - with its
		functionality replaced by a smaller, simpler logic
		(370 bytes smaller!).

sah 08/11/88	if int 8 is mask out during tsl, do not switch to
		another task.  this is necessary because basic compiler
		with turn off int 8's and then call function 25 to
		reset vector 1ch back to original when exiting
		also slightly improve tsl by turning off ega io
		protection only if we deside to actually enter tsl main

sah 09/26/88	added suspend2 which allows tsl to be re-enter by
		calling savecrit and restorcrit.  this is currently
		use by mosint17.

mjs 09/27/88	modified the swcall procedure of the serial irq logic
		to use scblastff to save and restore the bank selection
		state rather than use the ddtlw scheme.
		made the callisr procedure test the vdrirq flag.  the
		vidram checking logic sets this flag when it would
		appear that vidram is normally in place but real ram
		is really exposed since the vidram logic is making ddt
		calls to update the physical display memory of the
		watchers.

jrb 09/28/88	mapvma now maps b000 and b800 for vtypes 0, 1, 2 so
		swcall didn't need to anymore

sah 09/28/88	corrected ega pamswitching problem with latest code.
		somehow through re-arangement of tsl logic, suspended
		ega task was getting waken up when it should have.

sah 09/29/88	corrected oversight in suspend2 logic where call from
		outside tsl.

mjs 09/30/88	modified the swcall procedure to only re-enable irq's
		when the scbpktio flag has been set to 'Y'.  a seperate
		system utility program will be used to set and clear
		this flag.  this feature must normally be off to support
		multiple mice.

mjs 10/03/88	bug fix to bank selection restoration logic in swcall

mjs 10/04/88	corrected the swcall logic to restore the mapping state
		properly in all cases.

rkg 10/06/88	public tsl8stat, delete include .pub

sah 10/21/88	changes so that interupts don't have to be disable
		during switchgp and associated context switching routine
		modifications to irq logic to handle the case where
		scbtcbpc <> scbtcbps.

mjs 10/27/88	modify video umapping logic in swcall to accomodate
		sah's recent changes.

mjs 11/02/88	corrected the calculation of the index into the scbhwcl
		table.	ptr 128

mjs 11/03/88	problem: when run packet/pc with another task active
		the system would crash.  found that while the procedure
		bias_stack was handling most cases properly, the set of
		circumstances posed by swcall was unique and required
		special attention.  i added register dh as an entry
		parameter to bias_stack to signal this special case.
		in a nutshell, when swcall calls bias_stack, you can
		the case where ss != scbtcbpc and intsl == 0 but you
		still need to bias tcbstkp with tcbsp's value.
		also, removed the label sirq2a and following code - this
		was not needed as was producing a crash when the
		automatic irq reservation scheme was in use.

mjs 11/16/88	modified tsl to save and restore 32 bit registers when
		running on a 386 machine.

sah 11/30/88	when suspend calls vidram make sure that cx is scbtimer
		which is necessary because dopoll depends on it.

sah 12/05/88	added new routines (moucall and ps2call) for ps/2 mouse
		support. ps/2 mouses are not irq driving and bios will
		call user routine when mouse send information. so i made
		special flag (ps2mouse) and call swcall to switch in the
		task who set the ps/2 routine.

sah 12/06/88	added protected int 8 bios call where int 1ch is
		pointing to mosint1c instead of user int 1ch intercept
		this is done because user's INT 1ch intercept could have
		got call with scbtcbpc <> scbtcbps (i.e my 10/21/88
		changes) and this would cause to the user intercept to
		be in a state which it should not be in.  this was
		found with rbr's 286.sys driver. I also made code
		changes in such a way that if we detected any other type
		of invalid condition that apps int 8 handler will not be
		call that also the int 1ch will not be call in those
		conditions.

sah 12/08/88	correction to lidt int 8 logic, where we were testing
		to see if vector in vector table is pointing to lidtstub
		before we tested to see if scbtcbpc <> scbtcbps

sah 12/09/88	move mosint2f to mostemp. see mostemp for corrections
		for dbase iv.

sah 12/16/88	change sunriver style i/o protection to call function 4
		of initioptbl.	this will do all non-video i/o
		protection since the sunriver's hardware will take
		control of the rest.

sah 01/09/89	added userpoll routine which is called when task is
		switch into memory.  this was added so that generic
		mouse driver interface could designed in such a fashion
		that it could be implemented so that servicing the user
		irq routine will not require switching task in and out
		of memory.

sah 01/13/89	improvement of polling calling. this is not totally
		acceptable until we include higher resolution timer.

sah 01/24/89	change int 74h handler to call scbcall74 if installed
		and tcbmouse is active.

sah 02/03/89	converted scbvmaal = 0 test to test for scbbankin
		instead so that it will be compatible with sunriver

mjs 02/16/89	added logic to the lidt int8 handler to so a software
		division of irq0's.  This keeps int8 calls at the
		normal 1/18th second rate when mosadm tmfactor n is
		used to re-program the 8253 system timer to a faster
		irq0 rate.

mjs 02/17/89	extended the time slice speed up feature to work in the
		non-lidt case by re-working the int8 re-grab logic.

sah 02/20/89	corrected sunriver style io protection activication
		and cleaned up this code for compactness and efficency
		this corrected the lockup problem with srterm.sys and
		wp 5.0.

rdg 03/10/89	added task restart logic.  saveblk segment was added to
		preserve task information during the restart.  chkrstrt
		is responsible for insuring that the task is ready for
		restart (i.e. it has no additional watchers).  restart
		is responsible for actually saving all task specific
		information, terminating and then restarting the task.
		the main task selection loop was modified at tsl180
		to check and see if any tasks require a restart and
		call restart when a task has been determined to be ready

rdg 03/14/89	deleted the check of scbtcbvr and scbtcbvs by the task
		restart logic to allow a restart of vna and sunriver
		tasks.
		modified chkrstrt so that a background task could also
		be selected for restart once all watchers had been pam
		switched home.

rkg 05/08/89	unnecessary to initialize spooling timer tick

mjs 05/12/89	modified swcall to test scbswvq.  when this flag == 'N'
		then video is not switched - only task ram and context

sah 05/18/89	made sure that device driver irq call while scbinirq is
		incremented instead of being passing on. we don't want
		device driver irq to be sliced.

sah 05/31/89	updated userpoll so that it slightly faster if not using
		poll routine. speeded up polling via poll calls during
		irq 0's. also remove skippoll variable.

sah 06/05/89	made changes for novell, made sure that chkslice does
		not do time slices calls tsl if scbinmos is non-zero
		also with our dicussion between marty, rod and i, i
		remove the change i made 05/18/89 and optimized device
		driver irq calls so that they are passed on asap.

sah 06/08/89	made corrections irq logic for addition of mapvma fun 3
		for sunriver.

sah 06/15/89	made mosint74, lest dependent on mouse by removing
		tcbmouse check, since 1- this interface could be use
		else where, 2- mouse int 74 handler will check tcbmouse

sah 06/29/89	corrections for better optimization during tsl and
		converted notsl into scbnotsl for access from scb

mjs 07/06/89	corrected the logic within tsl which periodically
		forces a suspended task to be awakened so that its
		timer isr can get called.  the method of detecting when
		a timer isr existed had to be improved to differentiate
		between a task specific timer intercept and a device
		driver based intercept.  using tcborig8 and tcborig1c
		to record the original vectors.

sah 07/13/89	made corrections to suspend2 to correct problems with
		new print logic, shift print screen with out printer
		would call suspend2 but tcbwait would get clear and
		poll routine would never get called.

sah 07/18/89	remove partial context flags which appear to be unused
		so that mos does not have to go though the additional
		overhead of managing the flag scbcntflg and scbpktio
sah 07/19/89	corrections for ps/2 mouse, must also in addition of
		switching in the int 15 ps/2 mouse handler, must also
		switch in the int 74 handler. co-exitence with our
		$mouse.sys was also corrected.

mjs 07/27/89	modify userpoll procedure.  it was testing scblastff to
		see if the poll routine should be called.  this was
		causing a mouse to go dead when a vna workstation was
		not watching its home task.  modified so that bit 2
		of tcbega was tested instead.  this will only make the
		mouse go dead when a vmode ega task is unwatched.

sah 07/31/89	re-vamp restart logic so that it use function 22h, move
		tcb initialization code into inittcb in mositask

sah 08/02/89	corrections for restart change above.

sah 08/03/89	corrections for restrat while task are busy

mjs 08/12/89	make the userpoll procedure test the invidram flag.
		this flag is set by the vidram logic to prevent calls
		to the user poll routine when an int8 occurs during
		a vidram update.  this is to prevent mouse droppings.

mjs 09/14/89	modified the task selection logic to prevent stack
		corruption when an irq occurs while a new task is just
		being started.	(problem showed up with stargate's
		cluster controller)

SAH 10/31/89	Correct Restart Logic inside Monitor.com, also gave
		restart logic better protection about be restarted
		while a task restart is being use. Note use of -1
		for scbrstrtp variable.

mjs 11/10/89	make suspend test scbnotsl.  corrected code which
		fetches tcbpripn to use the es segment.  corrected
		test of tcborig8/1c to make sure the task hasn't been
		suspended within itask - before tcborig8/1c have been
		initialized.  these changes came up from stargate's new
		acl driver.

bwr 11/29/89	marked messages for foreign language translation.

sah 12/06/89	corrections for vgna and pamswitching. if any watcher has
		tcbvram bit 2 set, must use initioptbl function 4 instead
		of function 1.

sah 01/10/90	made demo code always be include and patch it out if demo
		version version is not intended to be use. see mosinit2

sah 01/22/90	converted reg32 variable into scb variable.

sah 02/05/90	remove mice logic and place mosint74

mjs 03/07/90	modifications for int15 the disk busy task switching
		feature.  modified chkslice's entry and exit parameters.
		changed position of reset of tcbslcnt within suspend/tsl.
		made an explicit int76 handler.  modified serirq to
		manage scbq6cs.

sah 04/26/90	corrected serial logic so it does not lock up on
		mos irq 6 in one task and directory on drive a: on
		another task.

sah 04/30/90	correction for restart logic and security.

sah 05/01/90	corrections so restart logic will go to correct drive

sah 05/02/90	added a safety value for restart logic by setting
		scbnotsl to 'y' during restart logic, so task could
		not be switch out

mjs 05/10/90	reworked sah's correction of 04/26/90.  corrected the
		case where a mos useirq 6 done in one task causes a
		lockup when floppy drive access is attempted from another
		task.

mjs 05/17/90	overhaul handling of irq2 through 7 for lidt support
		made one logic which handles the regrab case (non-lidt)
		and the lidt case.  streamlined the flow by using a
		jump table instead of discrete tests.

mjs 05/22/90	added call to chkirq at the end of tsl.  for procomm to
		work with auto reservation, must call chkirq more often

mjs 05/25/90	added irqbank routine to support bank selectable serial
		port hardware (e.g. viewport)

mjs 06/08/90	made the restart logic test tcbrstok first.  this was
		necessary to prevent a task which is not fully
		initialized from running a restart operation for
		another task.

mjs 06/16/90	modified the restart logic to not run a restart operation
		when tsl was called by int15fun90.  this prevents a crash
		when one task is doing disk i/o while another is
		restarting.
		modified the restart logic to make direct calls to
		remove and re-add the task rather than going through
		the intd4 handler.

mjs 07/04/90	modified the int8 force-awake logic within tsl to use
		a longer time-out count.  wordperfect version 5.1 was
		causing unacceptable degredation when run in several
		tasks (in dis mode) because this version has an int8
		intercept.  by making the int8 force-awake time-out
		count longer than the dis mode force-awake time-out
		count, this degredation was eliminated.

mjs 07/11/90	make tsl call set_trap to establish the trapping
		state for a task.

mjs 07/23/90	test for a scb15act in the restart function.  must
		not run a task restart during a tsl called from int15.

mjs 07/31/90	remove temporary clearing of scbnotsl within the
		restart function.  this was leftover from the time
		when restart issued intd4 calls rather than calling
		the remtask and addtask logic directly.  setting
		scbnotsl during a restart prevented an intd4fun07
		from working when called by a serial driver during
		a restart.
		also, corrected a stack imbalance in an error handler
		in the restart function.

mjs 09/18/90	modify chkslice to make sure tcbbegad has been
		initialized before using it to qualify the point of
		interrupt.  jrb's llnetbios driver was making int21 calls
		from an int8 intercept during device driver init.  going
		into mossaver at this time was crashing the stack.

SAH 10/10/90	Added logic so that ScbNoRst flag will allow restart logic
		to be globally skip, This is necessary for Novell, so
		that Novell UnRegister handle will not be executed during
		the Time when another task is executing MOSNET initialization
		code.

SAH 11/28/90	Change restart logic for so high bit of TCBPORT is mask off.
		This was done to handle ELTERM's use of TCBPORT for file
		transfer

cbk 01/16/91	Added logic to userpoll to call a user defined polling rtn
		that is not tied to a task. (Done initially for LL Netbios)

SAH 02/05/91	Added DOC for LanSatPoll, remove insidelpoll variable

mjs 02/21/91	moved the call tsl makes to getkeys to be before rather
		than after the task switch.  once a tcbpoll function
		signals that a task should be awakened, an unwatched
		ega suspension must not be premitted to prevent a prompt
		exit from tsl.	by calling getkeys just before switching
		a task out, any unwatched ega suspension conditions will
		not interfere with task activation due to the signal from
		a tcbpoll routine.
		patch 33 implements this fix for 4.10 users.

mjs 03/06/91	reinstated the getkeys call in the exit portion of tsl
		in order to improve keyboard response time.
		to prevent the pamswitching problem, made this call
		defer any pamswitch keystrokes.  the call to getkeys
		just before switching a task out is still the only
		place where pamswitching can be processed.

mjs 03/11/91	corrected oversight mistake made in last change.  after
		testing tcbega for b2 high in tsl's innermost loop,
		there was no jnz to tsl100.  as a result, unwatched ega
		tasks were not being suspended.

mjs 03/21/91	modified tsl logic by splitting maintenance logic off
		into tsl_maint.  added logic to manage the deferred 
		calling of a netbios post function.
  		
SAH 03/27/91	Corrections for 40:17 work, if tcbcon417 is -1, make sure
		getkeys is called.

mjs 03/28/91	manage tcbtslnst - a task specific nest counter
		manage tcbd40f - signals when suspend is called by
		intd4fun0f.  lanserve uses this version of the intd4fun07
		suspend logic for its netbios support (the force awake flag).

SAH 04/09/91	Removed bugerror E3 - unable to restart task.. if error
		try to created task don't bugerror just continue.

mjs 05/09/91	modified testflush to skip its operations if scb15act
		is set.  this prevents a deadlock due to reentrance
		into the flush function.

SAH 05/29/91	change chkslice so it use scbnoslc instead scbinmos.  This
		is to correct a comflict WordPerfect Office and Novell shell

SAH 07/11/91    Remove 05/29/91 change, not necessary with INT 1ah TSL
		calls

mjs 10/07/91	fix dbts/prtsc/spool bugs (patch410.118).
		rewrote suspend2 to not use savecrit and restorcrit.
		surrounded the first getkeys call within tsl with calls
		to savecrit and restorcrit.  changed the intsl flag to
		be incremented upon entry to tsl and decrmented upon
		exit.  set the scbnoi5 flag when getkeys is called
		from the second position within tsl.

SAH 10/24/91	Skip calling cursync if inside int 10 logic. This correct
		a strang pcterm\elterm video scroll problem.

mjs 03/18/92	modified the calls to dopoll and vidram that are made
		within suspend.  surrounded these calls with calls to 
		savecrit and restorcrit to accomodate the reentrance
		into suspend which can occur if vidram causes int14 output
		and the serial driver calls suspend because of a full
		output buffer.  also added reentrance control flags
		for dopoll (scbdopflg) and vidram (scbvdrflg) where
		they are called from within suspend.

================ 5.01 Kernel Ends Here ====================================

SAH 04/27/92	Channges to suppend2 so that intsl is save, set to 0,
		and then restored. This is done for serial problem with
		Gallop Printing.  
		(Corrected in UPDAT501.SYS Version 0.07)

SAH 05/28/92    Corrections for Compusource and other disappearing 
	 	terminals. corrected a oversite that MJS made on 03/18/92
		in making changes so that vidram calls are surrounded by
		savecrit and restorecrit. since savecrit destroys cx and
		vidram depended on cx register for timer, we ended up with
		a fixed cx value each time which made vidram logic work for
		30 minutes of each hour and than not work.
		(Corrected in UPDAT501.SYS Version 1.02)

mjs 08/18/92	clean up segment declarations

mjs 08/26/92	delete reference to scbfree.
		add launch_point label for overhaul of mosinit code.

=========================================================================^

.xlist
;	include mosnxtsk.pub
	include group.inc
	include options.inc
	include mosregs.inc
	include macros.inc

tcb	segment at 1234h
	include mostcb.inc
tcb	ends

gdata	segment
	include mosscbex.inc
gdata	ends
.list

gdata	segment
	extrn	vdrirq:byte, invidram:byte

;-----------------------------------------------------------------------
; bits in al on wait (fn 87) call
;-----------------------------------------------------------------------

	if	0 eq 0			; fake out periscope
wkey	equ	1			; wait for keystroke
wtime	equ	2			; wait for timer ticks
wint	equ	4			; wait for hardware interrupt
wport	equ	8			; wait for char or status change on port(s)
wupoll	equ	80h			; wait, call user poll routine
	endif

	public	intsl
intsl	db	0
	public	lagtcb
lagtcb	dw	0			; signal within tsl to update a suspended
					; tasks's timer intercept
public	pamskip
pamskip db	0			; set to 1 if should skip this process since
					; pamswitching uses the video save area for special
					; purposes
irqwarn db	'IRQ '
irqw1	db	'  occurred without MOS USEIRQ     ' ;@@XLAT
irqw2	db	' $'
irqwlen equ	$-irqwarn

public	irqwflag
irqwflag db	0			; 5 bit flags to control int24 message

public	skipswvs
					; swcall, in the serial irq logic, sets this flag
skipswvs db	'N'			; before calling switchgp - to avoid switching
					; the video save area.
public	skipswt
skipswt db	'Y'			; skip flag for swtasktm, set to 'N' after foreground
					; is init'ed in mositask
public	tsl8stat
tsl8stat dw	0			; flag used by tsl to tell the int8 logic when its
					; ok to lower the scbinmos flag

	public	ps2mouse
ps2mouse db	'N'			; flag use by swcall and ps2 mouse routines to indicate
					; that swcall was susposed to be special version for
					; ps/2 mouses
i8eoc	db	'N'			; flags entry into primary int8 regrab handler due to
					; end of chain processing

insidelupoll	db	'N'		; flag use for SCBUPOLL re-entrency

gdata	ends

	subttl	irq segment - specify a system interrupt handler for mossaver
	page
;-----------------------------------------------------------------------
; the irq segment is used (if needed) within a mos module for defining
; a mos interrupt handler
;-----------------------------------------------------------------------
irq	segment
	extrn	irqstart:byte, irqend:byte

hwatch	macro	num
	dw	num&h*4 		;; interrupt number
oint&num dd	?			;; old interrupt vector
	dw	tcbapv&num		;; where to save application values
public	mosint&num
	dw	mos:mosint&num		;; initial value for vector
public	mos2nd&num
	dw	mos:mos2nd&num		;; vector after application takes interrupt
	endm

	irp	in,<70,71,72,73,75,76,77>
	hwatch	in
	endm

serint	macro	num
	dw	num&h*4 		;; interrupt number
oint&num dd	?			;; old interrupt vector
	dw	tcbapv&num		;; where to save application values
	dw	mos:lidt&num		;; initial value for vector
	dw	mos:regrsec&num 	;; vector after application takes interrupt
	endm

	irp	in,<0a,0b,0c,0d,0e,0f>
	serint	in
	endm

	dw	08h*4			; offset for this interrupt
oint08	dd	?			; save prior value
	dw	0			; we don't save changes, we leave them alone
	dw	regr8pri		; offset of handler
	dw	0			; don't change back if application changes it

	dw	1ch*4			; offset for this interrupt
	dd	?			; save prior value
	dw	0			; we don't save changes, we leave them alone
	dw	mosint1c		; offset of handler
	dw	0			; don't change back if application changes it

irq	ends

saveblk segment at 8888 		; segment for saved tcb paramete

atask	equ	22h			; initialize task request
remtsk	equ	5			; remove task request

	org	00010h			; skip the blocks prefix

; data format for function 22h

param22 label	byte
memsize dw	?			; task memory size
taskid	dw	?			; task id
tclass	db	?			; task class
tbatch	dd	?			; task start batch file
condrvr dd	?			; task console driver address
portnum dw	?			; task terminal port number
baudrate dd	?			; task terminal baud rate
	db	17 dup (?)		; return values and reserved area
slice	db	?			; task slice info
startbat db	80 dup (?)		; task autoexec.bat file
saveblk ends

;======================================================== mos segment
if 0 eq 0
segment_num = 1
endif
mosseg	segment
	assume	cs:mos,ds:grp,es:nothing,ss:tcb
$$$nxtsk label	byte
	public	$$$nxtsk

	extrn	mosend:byte, sbios:word
	extrn	switchif:near, chkirq:near, dopoll:near, mosint21:near
	extrn	vidram:near, swtaskram:near, hex2asc:near, swrealram:near
	extrn	csynch:near, getkeys:near, set_trap:near
	extrn	mossaver:near, mosrestore:near, nosbuf:near
	extrn	swcntxt:near, switchgp:near, isega:near
	extrn	egaoff:near, egaon:near, kbpoll00:near, mapvma:near
	extrn	mapvsa:near, ps2call:near, mosheman:near, mosint38:near
	extrn	flush:near, mosrtask:near, start_task:near

	public	timparm,timchk,suspend,tsl,reordlst,bias_stack
	public	suspend2,mosintxx,mos2ndxx,irqbank,swcall
	public	grab_back,chkslice,lidtstub8,lidtint08,regrab8_data
	public	patdemo1,mosdemo1,mosdemo,userpoll,lidtst_af,launch_point

stk_bias equ	128

mosint1c proc near			; only need this for reference - so can detect when 
	iret				; a task has an intercept for this vector
mosint1c endp 

	subttl calc_next - determine interrupt handler offset
	page
;======================================================================
;,fs
; calc_vect - determine interrupt handler offset associated with a
; nest level value.
;
; in:	bx = offset (within mos segment) of regrab data structure
;		(regrab8_data or regrab9_data)
;	al = bias factor for the nest count (0 or -1)
;	ss -> tcb
;
; out:	si = offset of interrupt handler (within mos segment)
;	ax is crashed, bx is preserved
;
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:tcb
calc_vect proc near 
	mov	si,cs:[bx+6]		; get offset of nest counter
	add	al,ss:[si]		; get nest counter value
	jnz	cnx1			; and apply bias
	mov	si,cs:[bx+2]		; when nest level = 0 return offset of
	jmp	cnx2			; primary handler
cnx1:
	xor	ah,ah			; when nest level > 0, turn it into an
	dec	al			; index
	mov	si,ax
	shl	ax,1
	shl	ax,1
	add	si,ax
	add	si,cs:[bx+4]		; si = (nest level + bias - 1) * 5 + offset
cnx2:					; of first regrab handler
	ret
calc_vect endp 

	subttl grab_back - maintain control over int8 and int9 (no mm case)
	page
;======================================================================
;,fs
; grab_back - maintain control over int8 and int9 (no mm case)
;
; this procedure turns off interrupts.	it is up to the caller
; to re-enable them when ready.
;
; in:	bx = offset (within mos segment) of regrab data structure
;		(regrab8_data or regrab9_data)
;	ss -> tcb
;
; out:	none
;
;,fe
;=====================================================================
	assume	ds:nothing,es:nothing,ss:tcb
grab_back proc near 
	cli
	pushset ax,cx,si,di,es
	mgetzero es
	mov	cx,cs
	mov	di,cs:[bx]		; di = offset of vector
	xor	al,al
	call	calc_vect		; al = 0 from above
	cmp	es:[di],si		; do offsets match?
	jne	gb1
	cmp	es:[di+2],cx		; yes, so how about the segments?
	jne	gb1
	jmp	gb2			; get out, vector matches our handler
gb1:					; based on the current nest level
	mov	si,cs:[bx+6]
	cmp	byte ptr ss:[si],0	; can't back up if at nest level 0
	je	gb3
	mov	al,-1
	call	calc_vect		; check for a repeal to the previous
	cmp	es:[di],si		; level
	jne	gb3
	cmp	es:[di+2],cx		; -> gb3 when need to add another level
	je	gb4			; -> gb4 when need to back out a level
gb3:
	mov	si,cs:[bx+6]		; get offset of nest counter in tcb
	inc	byte ptr ss:[si]
	mov	al,ss:[si]		; increment the nest level and check
	cmp	al,5			; for a full table
	jna	gb5
	call	bugerror
	db	'ee - re-grab overflow        ',0 ;@@XLAT
gb5:
	mov	si,cs:[bx+8]
	xor	ah,ah
	dec	ax			; calc next free place in tcb vector
	shl	ax,1			; save table and store current
	shl	ax,1			; vector there
	add	si,ax
	mov	ax,es:[di]
	mov	ss:[si],ax
	mov	ax,es:[di+2]
	mov	ss:[si+2],ax
	xor	al,al
	call	calc_vect		; then update the vector with the next
	mov	es:[di],si		; re-grab handler of ours
	mov	es:[di+2],cx
	jmp	short gb2
gb4:
	mov	si,cs:[bx+6]		; get offset of nest counter in tcb
	dec	byte ptr ss:[si]	; and decrement to back out a level
	xor	al,al
	call	calc_vect
	mov	es:[di],si
	mov	es:[di+2],cx
gb2:
	popset	ax,cx,si,di,es
	ret
grab_back endp 

	subttl	bias_stack - prepare to call an irq intercept
	page
;======================================================================
;,fs
; bias_stack - prepare to call an irq intercept
;
; if ss == scbtcbpc then put sp in tcbstkp and bias that value else,
; if within tsl then must be on some other tcb stack so use tcbsp of
; the scbtcbpc task for tcbstkp and bias that value.  otherwise, if not
; on a tcb stack, [tcbstkp] is pushed for consistency.
;
; in:	dh = 0 for normal operation, dh != 0 for swcall's special case
;	ds -> grp
;
; out:	ds -> tcb  (from scbtcbpc)
;	ds:[tcbstkp] pushed on the stack
;	ax, bx, cx, dx and ds are changed
;
;,fe
;=====================================================================
	assume	ds:grp,es:nothing,ss:nothing
bias_stack proc near 
	pop	bx
	mov	dl,[intsl]		; get intsl while ds -> grp
	mov	ax,ss
	mov	cx,[scbtcbpc]
	mov	ds,cx
	assume	ds:tcb
	push	word ptr [tcbstkp]	; always need to save current state
	cmp	ax,cx			; if ss == scbtcbpc then use sp
	mov	ax,sp			; for the new tcbstkp value
	je	bstk1			; else, if within tsl, use
	or	dx,dx			; scbtcbpc:tcbsp
	je	bstk2
	mov	ax,[tcbsp]
bstk1:
	mov	word ptr [tcbstkp],ax
	sub	word ptr [tcbstkp],stk_bias
bstk2:
	jmp	bx
bias_stack endp 

	subttl call_intr8 - set up for and call the int8 intercept(s)
	page
;======================================================================
;,fs
; call_intr8 - set up for and call the int8 intercept(s).
;
; this proc deals with both the lidt and the regrab case and prepares
; for re-entrancy by biasing the stack and managing with data save and
; restore for the case where a tsr needs to pop up on an int8 during
; the tsl procedure.
;
; update 05/30/89 sah to call mouse user poll routine, if appliable
;
; in:	 none
;
; out:	 none
;
;,fe
;=====================================================================
	assume	ds:nothing,es:nothing,ss:nothing
call_intr8 proc near 
	pushset ax,bx,cx,dx,bp,ds,es
	mgetscb ds
	assume	ds:grp
	push	ds
	pop	es
	mov	bp,[tsl8stat]
	cmp	bp,1
	jne	call8a
	call	savecrit
	push	word ptr [scbinmos]	; prepare for possible
	push	ds			; re-entry into tsl (by a tsr)
	mov	word ptr [scbinmos],0
call8a:
	xor	dh,dh
	call	bias_stack		; setup [tcbstkp]
	assume	ds:tcb,es:grp
	cmp	bp,1
	jne	call8b
	and	[tcbwait],0f0h		; clear wait info
call8b:
	test	[scbmmfea],04h		; lidt support available?
	jz	call8c
	xor	ax,ax
	mov	es,ax
	assume	es:nothing
	pushf
	call	dword ptr es:[20h]	; yes, call 0:8*4 vector
	jmp	call8d
call8c:
	mov	bl,[tcbnest8]
	xor	bh,bh
	dec	bx			; no, call vector stored
	shl	bx,1			; in regrab table
	shl	bx,1
	pushf
	call	dword ptr [tcbchn8+bx]
call8d:
	pop	word ptr [tcbstkp]	; push'ed by the bias_stack proc
	cmp	bp,1
	jne	call8e
	pop	ds
	assume	ds:grp
	pop	word ptr [scbinmos]
	call	restorcrit
call8e:
	popset	ax,bx,cx,dx,bp,ds,es
	ret
call_intr8 endp 

	subttl bios_int8 - call the int8 handler in the rom bios
	page
;======================================================================
;,fs
; bios_int8 - call the int8 handler in the rom bios
;
; in:	 none
;
; out:	 none
;
;,fe
;=====================================================================
	assume	ds:nothing,es:nothing,ss:nothing
bios_int8 proc near 
	push	ds
	mgetscb ds
	assume	ds:grp
	push	ax
	mov	ax,[scbtcbpc]		; check to see if scbtcbpc <> scbtcbps
	cmp	ax,[scbtcbps]
	pop	ax
	je	bios8			; allow int 1ch handlers to be call
	pop	ds
	jmp	short prot_bios8	; call protect version

; the following is entry point where prot_bios will use it to
; call normal bios's INT 8 handler.

norm_bios8:
	push	ds
	mgetscb ds
	assume	ds:grp
bios8:					; this is the entry point from
	pushf				; from bios_int8
	call	dword ptr [oint08]
	pop	ds
	ret
bios_int8 endp 

	subttl prot_bios8 - call the rom int8 with protected 1ch
	page
;======================================================================
;,fs
; prot_bios8  - call the rom int8 with protected 1ch
;
; call bios_int8 (done this way so that we don't have to make duplicate
; changes) which int 1ch pointing to mosint1c instead of users int 1ch
; this is because the users int 1ch could get call with scbtcbpc <>
; scbtcbps. also video state could also be out of wack.
;
; in:	 none
;
; out:	 none
;
;,fe
;=====================================================================
	assume	ds:nothing,es:nothing,ss:nothing
prot_bios8 proc near 
	push	ds
	mgetzero ds
	cli
	push	word ptr ds:[1ch*4]	; save current int 1ch handler
	push	word ptr ds:[1ch*4+2]
	mov	word ptr ds:[1ch*4],offset mosint1c
	mov	word ptr ds:[1ch*4+2],cs
	sti
	call	norm_bios8		; call bios int 8
	mgetzero ds
	cli
	pop	word ptr ds:[1ch*4+2]
	pop	word ptr ds:[1ch*4]	; restore current int 1ch handler
	sti
	pop	ds
	ret
prot_bios8 endp 

	subttl i8maint - misc maintenance functions
	page
;======================================================================
;,fs
; i8maint - misc maintenance functions
;
; update misc counters. this proc should only be called once
; every 1/18 second.
;
; in:	es->tcb of current task
;	ds->grp
;
; out:	none
;
;,fe
;======================================================================
	assume	ds:grp,es:tcb,ss:nothing
i8maint proc near 
	push	ds
	push	es
	inc	byte ptr [scbhwcl]	; update indicators for any
	mov	[lagtcb],0		; processes waiting on this irq0
	cli				; increment the internal counter
	inc	[scbtimer]		; and manage wraps
	jne	chkw1			; zr if a wrap around
	mov	ax,[scbtcbpf]		; start with top of tcb list
	inc	[scbtimerh]		; bump most significant word of counter
chkw2:
	or	ax,ax
	jz	chkw1
	mov	es,ax
	assume	es:tcb
	mov	[tcbwtflg],0ffh 	; set wrap flag for all tcb's
	mov	ax,[tcbtcbpn]
	jmp	chkw2
chkw1:
	sti
	mgetzero ds			; update the lag counter from
	assume	ds:nothing		; the current timer value
	cli
	pop	es			; recover pointer to current tcb
	mov	ax,ds:[6ch]
	mov	word ptr [tcblagcnt],ax
	mov	ax,ds:[6eh]
	mov	word ptr [tcblagcnt+2],ax
	sti
	xor	[tcbprt61],10h		; toggle refresh bit for sidekick
	pop	ds
	ret
i8maint endp 

	subttl chkslice - call task selection logic
	page
;======================================================================
;,fs
; chkslice - call task selection logic
;
; if tests are passed, the task selection logic is called.
;
; in:	ax holds the cs of interrupted process
;	ds -> grp
;	es -> tcb of current task
;
; out:	al = 0 if mossaver was called, else != 0
;
;,fe
;
; Updated 05/29/91 SAH please note that I change scbinmos test to scbnoslc
; test, also note that inside mos test is also check by checking CS range.
; This is done to correct stalling of WordPerfect Office.  This will also
; correct Packet PC stalling.
;======================================================================
	assume	ds:grp,es:tcb,ss:nothing
chkslice proc near 
	push	bx
	mov	bx,1
	cmp	[tcbbegad],0		; has tcbbegad been initialized?
	je	mosi8x
	cmp	ax,[tcbbegad]		; cs below task ram?
	jb	mosi8x
	inc	bx
	cmp	ax,[tcbendad]		; cs above task ram?
	jae	mosi8x
	inc	bx
	mov	al,[scbinmos]		; are we inside novell shell
	or	al,[scbinirq]		; any serial irqs currently executing?
	or	al,[scbttrap1]		; are we in a non-interruptable i/o
	or	al,[scbttrap2]		; sequence to the timer/counter chip?
	jne	mosi8x
	inc	bx
	mov	ax,ss			; stack in mos?
	cmp	ax,[scbtcbpc]
	je	mosi8x
	mov	al,[tcbfsavr]
	mov	[tcbfsavr],'Y'
	call	mossaver		; this will call tsl for time slicing
	call	mosrestore
	mov	[tcbfsavr],al
	xor	bx,bx
mosi8x:
	mov	ax,bx
	pop	bx
	ret
chkslice endp 

	subttl	lidtstub8
	page
;======================================================================
;,fs
; lidtstub8
;
; the lidtstub8 handler is what is presented in the int8 vector
; in the 0:0 table.
;
; in:	none
;
; out:	none
;	all registers preserved
;
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:nothing
lidtstub8 proc far 
	call	bios_int8
	iret
lidtstub8 endp 

  	subttl	lidtint08 and lidtstub8
	page
;======================================================================
;,fs
; lidtint08 and lidtstub8
;
; this is the int8 entry point when a memory manager which
; supports an actual interrupt vector table is used.  in this situation
; lidtint08 will always receive control from an irq0, regardless of any
; int8 intercepts since the interrupt vector table at 0:0 is just a
; dummy.  
;
; enter here on each irq0.  note that this could be more often than
; 18.2 times a second if a slice multiplier is being used.
;
; in:	none
;
; out:	none
;	all registers preserved
;
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:nothing
lidtint08 proc far 
	sti
	push	bp
	mov	bp,sp			; need [bp+4] to be the cs of the code
	push	di			; that was interrupted
	push	ax
	push	ds
	push	es
	mgetzero es
	assume	es:nothing
	mgetscb ds
	assume	ds:grp
	xor	di,di
	cmp	byte ptr [scbslcnt],0	; scbslcnt will be 0 if we are
	jz	li8c			; working with normal 18.2 slices
	dec	[scbslcnt]
	jz	li8d

; di flags that this irq0 doesn't call the bios when scbslcnt is still > 0,
; don't call the int8 vector holder but just go directly to check for a
; task switch (chkslice).
; when count down to 0, time to reset the counter and call any int8
; intercepts.  if no intercepts, then just call the bios

	mov	di,1
	mov	al,20h
	out	20h,al
	jmp	short li8e
li8d:
	mov	al,[scbslfact]
	mov	[scbslcnt],al
li8c:
	cli
	mov	ax,[scbtcbpc]		; check to see if we are in the
	cmp	ax,[scbtcbps]		; middle of context logic, if so
	sti
	jne	li8b			; it's too messy to call intercept
	cmp	word ptr [scbtcbvs],-1	; if the either of the video areas
	je	li8b			; is not 'normal', don't call the
	cmp	word ptr [scbtcbvr],-1	; intercept - too messy to deal with
	je	li8b
	cmp	es:[20h],offset lidtstub8
	jne	li8a
	mov	ax,cs			; is the int8 vector in the 0:0
	cmp	es:[22h],ax		; table still pointing to our stub?
	jne	li8a
	pushf
	call	dword ptr es:[20h]	; yes, call the stub (to call the bios)
	jmp	li8x
li8a:
	call	call_intr8		; else, use the protected calling code
	jmp	li8x
li8b:
	call	prot_bios8		; call protected bios int 8
li8x:
	mov	es,[scbtcbpc]
	assume	es:tcb
	call	i8maint

; enter here on every irq0 - could be more often than 18.2 times a second

li8e:
	mov	es,[scbtcbpc]
	assume	es:tcb
	cmp	byte ptr [tcbslcnt],0
	je	li8f
	dec	[tcbslcnt]		; tcbslcnt is each task's slice counter.
	jnz	li8g
li8f:
	mov	ax,[bp+4]		; no need to call checkslice if this
	call	chkslice		; task still has more slices left.
li8g:					; checkslice will reset tcbslcnt
	call	userpoll		; int 8 version of userpoll
	pop	es
	pop	ds
	pop	ax
	or	di,di
	jnz	li8h
	pop	di
	pop	bp
	jmp	i8iret
li8h:					; when di != 0, don't jump to i8iret
	pop	di			; or the demo version will have a
	pop	bp			; shorter life
	iret
lidtint08 endp 

	subttl regrab8a - int8 handler for non-lidt memory management
	page
;======================================================================
;,fs
; regrab8a - int8 handler for non-lidt memory management
;
; int8 management for cases when no memory management driver
; is used or the cpu is an 8088 - basically, whenever the lidt scheme
; is not available.
;
; in:	none
;
; out:	none
;	all registers preserved
;
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:nothing

regrab8_data:
	dw	8*4			; +0 offset of vector relative to seg 0
	dw	regr8pri		; +2 offset of primary handler
	dw	regrab8a		; +4 offset of first regrab handler
	dw	tcb:tcbnest8		; +6 offset of nest flag
	dw	tcb:tcbchn8		; +8 offset of table for user's vectors

regrab8a proc far 
	push	bx			; these are the int8 handlers which mos
	mov	bl,1			; will re-assert to stay in control
	jmp	short	regrab08
	push	bx
	mov	bl,2			; note - each of these entry points
	jmp	short	regrab08	; consists of 5 bytes of code.
	push	bx			; the procedure calc_next is
	mov	bl,3			; dependant on this code size.
	jmp	short	regrab08
	push	bx
	mov	bl,4
	jmp	short	regrab08
	push	bx
	mov	bl,5
	jmp	short	regrab08

; this is the primary int8 handler for the regrab case.  enter here on each
; irq0 when there are no int8 intercepts.  when there is one or more int8
; intercept, will enter regrab08 on the irq0 but will enter here when the
; last int8 intercept in the chain places a call to what it knows as the
; previous int8 vector holder (what it thinks is the bios).

regr8pri:
	push	bx			; must stick bx on stack since
	push	di			; i8common expects it
	push	ds
	mgetscb ds
	assume	ds:grp
	cmp	[i8eoc],'Y'		; if i8eoc == 'N' then irq0 entry
	je	i8rg030 		; else re-entering from end of chain.
	push	ax
	mov	di,1			; di = 1 means bios was called
	cmp	byte ptr [scbslcnt],0	; scbslcnt will be 0 if we are
	jz	i8rg020 		; working with normal 18.2 slices
	dec	[scbslcnt]
	jz	i8rg010
	xor	di,di			; flag that bios call was skipped.

; when scbslcnt is still > 0, don't call the int8 vector holder but just
; go directly to check for a task switch (chkslice)

	mov	al,20h
	out	20h,al
	pop	ax
	pop	ds
	jmp	i8common		; di = 0 means only call chkslice
i8rg010:
	mov	al,[scbslfact]
	mov	[scbslcnt],al		; reset counter to top value
i8rg020:
	pop	ax
	pop	ds
	call	bios_int8
	jmp	i8common

; when enter regr8pri and i8eoc == 'Y'	(end of chain)	then all other
; decisions have already been made.  just call the bios.

i8rg030:
	pop	ds
	pop	di
	pop	bx
	call	bios_int8
	iret

; regrab08 is entered for 1 of 2 reasons - when an irq0 occurs and one
; or more int8 intercepts exist or when processing the intercept chain and
; 2 or more intercepts exist.

; when enter at highest recorded nest level then its time to bias the
; stack and call the chain of intercepts.  if enter at another nest
; level then must be due to an intercept calling the previous vector
; holder.  in this case, pass control onto the next application vector
; stored in the table.

; *** stack note ***  when chkslice is called, the cs of the interrupted
; process must be at [bp+8]

regrab08:
	push	di
	push	ds			; original bx saved on the stack
	mgetscb ds			; current bx value indicates nest level
	assume	ds:grp
	cli
	mov	ds,[scbtcbpc]
	assume	ds:tcb
	cmp	bl,[tcbnest8]
	jmpne	i8rg100 		; when bl == the nest level, entering
	mgetscb ds			; regrab08 due to an irq0
	assume	ds:grp
	mov	di,1			; di = 1 means bios was called
	cmp	byte ptr [scbslcnt],0	; scbslcnt will be 0 if we are
	jz	i8rg050 		; working with normal 18.2 slices
	push	ax
	dec	[scbslcnt]
	jz	i8rg040

; flag that bios call was skipped.  when scbslcnt is still > 0, don't
; call the int8 vector holder but just go directly to check for a task
; switch (di = 0 means only call chkslice)

	xor	di,di
	mov	al,20h
	out	20h,al
	pop	ax
	pop	ds
	jmp	i8common
i8rg040:
	mov	al,[scbslfact]
	mov	[scbslcnt],al		; reset counter to top value
	pop	ax
i8rg050:
	cmp	word ptr [scbtcbvs],-1	; if the either of the video areas
	je	i8rg060 		; is not 'normal', don't call the
	cmp	word ptr [scbtcbvr],-1	; intercept - too messy to deal with
	je	i8rg060
	mov	[i8eoc],'Y'
	call	call_intr8		; else, use the protected calling code
	mov	[i8eoc],'N'
	pop	ds
	jmp	i8common
i8rg060:
	pop	ds
	call	prot_bios8		; call protected bios int 8

; at this point, bx and di are on the stack.  the current value in the di
; register flags if this irq is the 1/18 second irq.  if di == 0, the
; bios called was skipped to the following code should only call chkslice.

i8common:
	push	bp
	mov	bp,sp			; make interrupted cs be at [bp+8]
	push	ax
	push	ds
	push	es
	mgetscb ds
	assume	ds:grp
	mov	es,[scbtcbpc]
	assume	es:tcb
	or	di,di
	jz	i8rg070
	call	i8maint 		; only call this if the bios got called
i8rg070:
	cmp	byte ptr [tcbslcnt],0
	je	i8rg080
	dec	[tcbslcnt]		; tcbslcnt is each task's slice counter.
	jnz	i8rg090
i8rg080:
	mov	ax,[bp+8]		; no need to call checkslice if this
	call	chkslice		; task still has more slices left.
i8rg090:				; checkslice will reset tcbslcnt
	call	userpoll		; int 8 version of userpoll
	pop	es
	pop	ds
	pop	ax
	pop	bp
	or	di,di
patdemo1 label	near			; this code out
	jz	i8rg093
	pop	di
	pop	bx
	iret
i8rg093:
	pop	di			; only jump to i8iret if the bios got
	pop	bx			; called or the demo version will have
	jmp	i8iret			; a short life.

; this code is used when regrab08 is entered where bl != the nest level.  this
; means that our int8 handling logic has been re-entered in the middle of
; a chain process.  need to pass control on to the next intercept routine
; in the chain.

i8rg100:
	assume	ds:tcb
	xor	bh,bh
	dec	bx
	shl	bx,1
	shl	bx,1
	push	ax
	push	ax			; make some room on the stack
	push	bp
	mov	bp,sp
	push	ax
	mov	ax,[bp+6]		; relocate ds (already pushed)
	mov	[bp+2],ax
	mov	ax,[bp+8]		; relocate di
	mov	[bp+4],ax
	mov	ax,[bp+0ah]		; relocate bx
	mov	[bp+6],ax
	mov	ax,word ptr [tcbchn8+bx]
	mov	[bp+8],ax		; put address of next int8
	mov	ax,word ptr [tcbchn8+bx+2]  ; intercept on stack
	mov	[bp+0ah],ax
	pop	ax
	pop	bp
	pop	ds
	assume	ds:nothing
	pop	di
	pop	bx
	retf				; transfer to next intercept

i8iret:
mosdemo1 label	byte			; iret will be place here for
	push	ds			; faster execution if demo is
	MGetSCB ds			; not being use
	assume	ds:grp
mosdemo label	byte
	inc	word ptr [scbdemo]	; use value in SCB, so that once
	jnc	notlimit
	mov	word ptr [scbdemo2],-1	; invalidate second demo word
notlimit:
	pop	ds			; we move to protected mode, this
	iret				; does not have to change
regrab8a endp 

	subttl calctime - calc # of ticks since timer value was recorded
	page
;======================================================================
;,fs
; calctime - calc # of ticks since timer value was recorded
;
; in:	bx:dx = recorded timer value
;	es = 40h
;
; out:	ax:cx = # of ticks since timer was at recorded value
;	registers changed: ax, cx
;
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:nothing
calctime proc near 
	cli
	push	es
	mov	ax,40h
	mov	es,ax
	mov	ax,es:[6eh]		; if the saved count is greater
	cmp	bx,ax			; than 40:6c,6e must be around
	ja	ct1			; midnight so --> ct1
	jb	ct2
	mov	cx,es:[6ch]		; high words equal so check low
	cmp	dx,cx
	ja	ct1
ct2:
	sub	cx,dx			; subtract saved count from
	sbb	ax,bx			; current to find count of
	jmp	ct3			; missing ticks to make up
ct1:
	mov	cx,0b0h 		; ---- wrap-around case -----
	sub	cx,dx			; subtract the saved count from
	mov	ax,18h			; max+1  (0018:00b0) and then
	sbb	ax,bx			; add in the current count
	add	cx,es:[6ch]		; value to find count of
	adc	ax,es:[6eh]		; missing ticks
ct3:
	pop	es
	sti
	ret
calctime endp 

	subttl	updattend - update the timing var tcbattend
	page
;======================================================================
;,fs
; updattend - update the timing var tcbattend from 40:6c,6e
;
; in:	ss -> tcb
;
; out:	none
;	all registers preserved
;
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:tcb
updattend proc near 
	push	ax
	push	es
	mov	ax,40h
	mov	es,ax
	assume	es:nothing
	cli
	mov	ax,es:[6ch]
	mov	word ptr [tcbattend],ax
	mov	ax,es:[6eh]
	mov	word ptr [tcbattend+2],ax
	sti
	pop	es
	pop	ax
	ret
updattend endp 

	subttl savecrit - put critical tsl data on stack
	page
;======================================================================
;,fs
; savecrit - put critical tsl data on stack
;
; in:	ss -> tcb
;
; out:	none
;	ax and cx crashed
;
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:tcb
savecrit proc near 
	pop	ax			; get the return address in ax
	mov	cl,[tcbwait]		; save all sensitive data in prep
	mov	ch,[tcbstat]		; for the possiblity that tsl will
	push	cx			; be re-entered due to the actions
	xor	cl,cl			; of an int8 intercept routine
	mov	[tcbwait],cl		; clear tcbwait so if we were waiting,
	push	ds			; whatever re-activates the task
	mgetscb ds			; won't be suspended by tsl
	assume	ds:grp
	xchg	[intsl],cl
	pop	ds
	assume	ds:nothing
	push	cx
	push	[tcbsp]
	push	word ptr [tcbpoll]
	push	word ptr [tcbpoll+2]
	push	ax			; use return address saved in ax
	ret
savecrit endp 

	subttl	restorcrit - restore critical tsl data from stack
	page
;======================================================================
;,fs
; restorcrit - restore critical tsl data put on the stack with savecrit
;
; in:	ss -> tcb
;
; out:	none
;	ax and cx crashed
;
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:tcb
restorcrit proc near 
	pop	ax			; get the return address in ax
	pop	word ptr [tcbpoll+2]
	pop	word ptr [tcbpoll]
	pop	[tcbsp]
	pop	cx			; put it all back like it was
	push	ds
	mgetscb ds
	assume	ds:grp
	mov	[intsl],cl
	pop	ds
	assume	ds:nothing
	pop	cx
	mov	[tcbwait],cl
	mov	[tcbstat],ch
	push	ax
	ret
restorcrit endp 

	subttl	testirqw - test for an irq warning
	page
;======================================================================
;,fs
; testirqw - test for an irq warning
;
; if the logic in mosserirq detected an ambiguous situation with an irq
; (where a mos useirq was not issued and more than one task currently
; has an intercept registered for the irq's vector) pop up an error
; message window using moxcpcor's int 24 handler.
;
; uses a special entry to moxcpcor's int24 handler
;
; in:	ss -> tcb of the currently switched in task
;
; out:	none
;	all registers preserved
;
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:tcb
testirqw proc near 
	cmp	[tcbwpend],0		; check for an irq error
	jne	$+5
	jmp	tw3
	push	ax
	push	cx
	call	savecrit
	push	bx
	push	dx
	push	si
	push	di
	push	ds
	push	es
	cli
	mov	al,[tcbwpend]
	mov	bl,'2'			; find the first non-zero bit
	mov	ah,1			; in tcbwpend and derive the
irqwa1: 				; corresponding irq number
	test	al,ah
	jnz	irqwa2
	inc	bl
	shl	ah,1
	jmp	irqwa1
irqwa2:
	mgetscb ds
	assume	ds:grp
	not	ah			; clear the bit so only one window
	and	[tcbwpend],ah
	mov	[irqw1],bl		; set up the message string
	mov	[irqw2],bl
	mov	cx,irqwlen		; convert string length to stack space
	mov	ax,cx
	and	ax,1
	add	cx,ax			; if odd, add 1
	add	cx,2
	sub	sp,cx			; make room on the stack for the string
	sub	cx,2
	push	di
	mov	di,sp
	add	di,4
	mov	dx,di			; save a pointer to the start
	push	es			; of the string
	push	ss
	pop	es
	mov	si,offset [irqwarn]
	push	cx
	rep	movsb			; copy the string to the stack
	sti
	mov	bx,ss			; make bx:dx -> string
	mov	ah,0ffh
	pushf
	call	[scbcin24]		; call command processor's int 24
	pop	cx			; handler to put up warning message
	add	cx,2
	pop	es
	pop	di
	add	sp,cx			; remove string space from the stack
	pop	es
	pop	ds
	pop	di
	pop	si
	pop	dx
	pop	bx
	call	restorcrit
	pop	cx
	pop	ax
tw3:
	ret
testirqw endp 

	subttl testflush - test for a polled flush error
	page
;======================================================================
;,fs
; testflush - test for a polled flush error
;
; if an error occurred flushing a uob owned by this task, use moxcpcor's
; int 24h handler to tell the task about it
;
; in:	ss -> tcb of the currently switched in task
;
; out:	none
;	registers changed: none
;
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:tcb
testflush proc	near 
	push	es
	mgetscb es
	assume	es:grp
	cmp	[scb15act],0		; skip if on a disk busy task switch
	jne	tfx
	cmp	[tcbflush],'Y'		; check for a flush error
	jne	tfx
	push	ds
	mov	ax,ss
	mov	es,ax
	mov	al,[tcbpri]		; drop priority back down
	and	al,0fh
	call	reordlst
	mov	ax,ss
	mov	ds,ax
	push	word ptr [tcberrvol+2]
	push	word ptr [tcberrvol]
	push	word ptr [tcberrcod]
	call	savecrit
tf1:
	mov	[tcbflush],'N'
	callmos2 flush			; try again (int 24's will be
	cmp	[tcbflush],'N'		; dealt with).	ne if a new error
	jne	tf1			; while we dealt with old
	call	restorcrit		; now since we're scbtcbpc)
	pop	ax
	mov	[tcberrcod],al
	pop	word ptr [tcberrvol]
	pop	word ptr [tcberrvol+2]
	pop	ds
	mov	[tcbflush],0
tfx:
	pop	es
	assume	es:nothing
	ret
testflush endp 

	subttl timparm - setup time parameters for interval measuring
	page
;======================================================================
;,fs
; timparm - setup time parameters for interval measuring
;
; ax and cx should be saved and used when calling the timchk routine
;
; in:	ax = interval to wait
;	cl = bit position of wrap flag in tcbwtflg
;	es -> tcb
;
; out:	ax = time value for checking
;	cl = test value for wrap flag
;	ch = need wrap flag (1), 0 if wrap to terminate interval
;	ax and cx crashed
;
;,fe
;======================================================================
	assume	es:tcb,ds:nothing,ss:nothing
timparm proc	near 
	push	bx
	push	es
	mgetscb es
	assume	es:grp
	mov	bx,[scbtimer]		; use an independent tick counter
	pop	es
	assume	es:tcb
	add	ax,bx
	xor	ch,ch			; assume no wrap required
	cmp	ax,bx			; ax < bx if timer will wrap before end
	ja	nowrp
	mov	ch,1			; wrap needed flag
nowrp:
	not	cl
	and	[tcbwtflg],cl		; clear wrap flag for this bit
	not	cl
	pop	bx
	ret
timparm endp 

	subttl timchk - check for expiration of time interval
	page
;======================================================================
;,fs
; timchk - check for expiration of time interval
;
; in:	ax = time check value
;	cl = wrap flag test value
;	ch = need wrap flag
;	es -> tcb
;
; out:	zf=1 if interval expired
;	all registers preserved
;
;,fe
;======================================================================
	assume	es:tcb,ds:nothing,ss:nothing
timchk	proc	near 
	test	[tcbwtflg],cl		; has a wrap occured?
	jnz	gotwrp			; yes, sure has
	or	ch,ch			; is wrap required
	jnz	timend			; yes, not aquired yet, get out
	jmp	timrchk 		; not required, just check if expired
gotwrp:
	or	ch,ch			; is a wrap needed?
	jz	timend			; no, interval has been passed
timrchk:
	push	bx
	push	es
	mgetscb es
	assume	es:grp
	cmp	[scbtimer],ax		; use an independent tick counter
	jae	timexp
	or	bx,0ffh 		; clear zf
	jmp	timex
timexp:
	xor	bx,bx			; set zf
timex:
	pop	es
	pop	bx
timend:
	ret
timchk	endp 

	subttl chkrstrt - check for any tasks needing a restart
	page
;======================================================================
;,fs
; chkrstrt - check for any tasks needing a restart
;
; in:
;
; out:
;
;,fe
;======================================================================
	assume	ds:nothing, es:nothing, ss:nothing
chkrstrt proc near 
	push	ax
	push	ds
	push	es
	mgetscb ds			; get the pointer to the scb
	assume	ds:grp, es:nothing, ss:nothing
	cmp	[scbnorst],0		; skip if restart disable
	jne	chkrx
	cmp	[scb15act],0		; skip if on a disk busy task switch
	jne	chkrx
	cmp	[scbrstrtp], 0		; skip if a task is already waiting
	jne	chkrx
	mov	ax,[scbtcbpf]		; get pointer to the first tcb
chkr2:
	mov	es, ax			; move the tcb location to es
	assume	ds:grp, es:tcb, ss:nothing
	mov	ax, [tcbtcbpn]		; get pointer to the next tcb
	cmp	[tcbid],0		; bug...can't do this for task 0
	je	chkr1
	cmp	[tcbcamon], 0		; should this task be terminated
	je	chkr1			; go check the next task if no
	cmp	word ptr [tcbcondd], 0	; is this a background task
	jne	chkr3			; only one watcher if foreground
	mov	word ptr [tcbcondd+2], 0; is this a background task
	jne	chkr3			; only one watcher if foreground
	cmp	[tcbscrdd], 0		; is it ready for restart
	jne	chkr1			; go check the next one if not
	jmp	short chkr4		; go set him for termination
chkr3:
	push	bx			; save bx
	mov	bx, es			; task tcb to bx
	cmp	bx, [tcbscrdd]		; is it the right console
	pop	bx			; restore bx
	jne	chkr1			; not ready yet if not first watcher
	cmp	[tcbnxtdd], 0		; is there more than 1 watcher
	jne	chkr1			; not ready yet if more than 1 watcher
chkr4:
	mov	[scbrstrtp], es 	; show task ready to terminate
	mov	[tcbpri], 0		; drop his priority too
	dec	[scbrstrtc]		; one less to find
chkr1:
	or	ax,ax			; if not at end of list
	jnz	chkr2			; go to top of loop
chkrx:
	pop	es			; restore es
	pop	ds			; and ds
	pop	ax			; and ax
	ret				; return to caller
chkrstrt endp 

	subttl restart - restart a terminal task
	page
;======================================================================
;,fs
; restart - restart a terminal task
;
; in:
;
; out:
;
;,fe
;======================================================================
	assume	ds:grp, es:nothing, ss:tcb
restart proc near 
	pushset ax,bx,cx,dx,bp,di,si,ds,es
	pushf
	cli
	cmp	[scbnorst],0		; skip if restart disable
	jne	restrtx
	cmp	[scb15act],0		; skip if on a disk busy task switch
	jne	restrtx
	mov	ax, ss			; current stack to ax
	mov	cx, [scbrstrtp] 	; get the task to terminate
	cmp	ax, cx			; are we on his stack
	je	restrtx 		; press onward if no
	cmp	ax, [scbtcbpc]		; do we have a valid context
	jne	restrtx 		; exit if no
	cmp	ax, [scbtcbps]		; do we have valid memory
	jne	restrtx 		; exit if no
	test	[scbmmfea], 080h	; are we using memory management
	jnz	termtask		; terminate the task if yes
	push	es
	mov	es, cx			; move tcb to terminate to es
	cmp	ax, es:[tcbparnt]	; are we using the parent task
	pop	es
	je	termtask		; terminate the task if from parent
restrtx:
	popf				; restore the interupt flag
	jmp	restrtz
termtask:
	cmp	cx,-1			; are we trying to reenter
	je	restrtx 		; exit if reentry
	mov	[scbrstrtp], -1 	; mark inside restart
	push	cx			; save the tcb to terminate
	xor	ah, ah			; allocate a heap block
	mov	dx, 10			; get me 160 bytes
	call	mosheman		; go get it
	or	al, al			; did we get the memory
	pop	ds			;  set ds to the tcb
	jnz	restrtx 		; just do it...maybe it will resolved
	popf
	assume	ds:tcb, es:saveblk, ss:nothing
	push	es
	mov	al,[tcbodriv]		; get original drive for task
	MGetSCB es
	assume	es:grp
	mov	[scbrdriv],al		; save it in SCB so that it will
	pop	es			; be set by mositask
	assume	es:saveblk
	mov	ax, word ptr [tcbcondd] ; get the console driver offset
	mov	word ptr [condrvr], ax	; save it
	mov	ax, word ptr [tcbcondd+2]  ; get the console driver segment
	mov	word ptr [condrvr+2], ax
	mov	al,[tcboclass]
	mov	[tclass], al		; set class to 0
	xor	al,al
	mov	[tcbclass],al		; clear out class information
	mov	[tcbcdft],al		; to prevent lockup
	mov	ax, [tcbid]		; get the task id
	mov	[taskid], ax
	mov	ax, word ptr [tcbbaud]	; get the first word of baud rate
	mov	word ptr [baudrate], ax
	mov	ax, word ptr [tcbbaud+2]; get the second word of baud rate
	mov	word ptr [baudrate+2], ax
	mov	ax, [tcbport]		; get the serial port number
	and	ax, 07fffh		; mask out High Bit for Emulink
	mov	[portnum], ax		; save it
	mov	ax, [tcbendad]		; get the ending segment
	sub	ax, [tcbbegad]		; minus the starting segment
	shr	ax,1
	shr	ax,1
	shr	ax,1
	shr	ax,1			; convert size in paragraphs
	shr	ax,1			; to size in k
	shr	ax,1
	mov	[memsize], ax		; save task size in paragraphs
	mov	al, [tcbslice]		; get the slice info
	mov	[slice], al
	mov	si, offset [tcbautoe]	; point to the start batch file
	mov	di, offset [startbat]	; point to the save area
	mov	cx, 72/2
	cld
	rep	movsw			; do it by word moves
	push	es			; save pointer to our memory block
	mov	ax,ds			; push the tcb address
	mov	es,ax			; set es to the tcb to dump
	assume	ds:nothing, es:tcb, ss:nothing
	call	mosrtask
	or	al,al
	jz	starttask
	call	bugerror		; shouldn't be here either
	db	'E1  '
	db	'unable to remove task',0 ;@@XLAT
starttask:
	pop	ds			; retrieve pointer to storage block
	assume	ds:saveblk
	mov	word ptr [tbatch],offset [startbat] ; store start batch file
	mov	ax,ds
	mov	word ptr [tbatch+2],ax
	mov	si, offset [param22]		; point to the batch file name
	pushset bx,cx,dx,si,di,bp,ds,es
	call	start_task
	popset	bx,cx,dx,si,di,bp,ds,es
	or	ax,ax
	jz	strttsk2		; jump if restarted ok
	mov	al, [slice]		; get the time slice
	mov	[tcbslice], al		; start the task
strttsk2:
	mov	ax, ds			; move the saveblk pointer to ax
	mov	es, ax			; set es to the unneeded block
	mov	ah, 1			; release the block
	call	mosheman		; call the heap manager
	or	al, al			; did it go ok
	jz	strttsk3		; press onward if all ok
	call	bugerror		; bomb if cann't give back heap
	db	'E2  '
	db	'Unable to return heap space      ',0 ;@@XLAT
strttsk3:
	MGetSCB ds
	assume	ds:grp
	mov	[scbrstrtp], 0		; clear restart required flag
restrtz:
	popset	ax,bx,cx,dx,bp,di,si,ds,es
	ret
restart endp 

	subttl reordlst - reorder tcb list
	page
;======================================================================
;,fs
; reordlst - reorder tcb list
;
; this routine will adjust the current position of the current tcb
; by placing the tcb at the last position of the priority group that
; it belongs to.
;
; in:	es -> tcb whose priority to change
;	al -> priority
;
; out:	none
;	ds, es, bp, di unchanged
;
;,fe
;======================================================================
	assume	ds:nothing,ss:nothing,es:tcb
reordlst proc near 
	push	ds
	mgetscb ds
	assume	ds:grp
	mov	ah,'Y'
	xchg	ah,[scbnotsl]
	push	ax
	mov	[tcbpri],al		; set the priority
	mov	cl,al
	mov	bx,es			; remember our tcb
	mov	es,[scbpripf]		; start w/ first in priority chain
	cmp	[tcbpripn],0
	jne	reord1
	mov	bx,es			; fast out if only one in chain
	pop	ax
	mov	[scbnotsl],ah
	pop	ds
	ret
reord1:
	mov	ax,es
	cmp	ax,bx
	jne	reordn1
	jmp	reordf1

; here if our tcb is not first in the list
; find first of new and old positions

reordn1:
	mov	ax,[tcbpripn]
	cmp	ax,bx
	je	reordn5
	mov	dx,es
	mov	es,ax
	cmp	cl,[tcbpri]
	jbe	reordn1

; not first
; new position for tcb precedes the old position
;   (only for new task or changed priority, can't occur during tsl)

	mov	ds,bx
	assume	ds:tcb,es:nothing
	cmp	ax,[tcbpripn]
	jne	reordn2
	mov	es,bx			; fast out if position unchanged
reordout:
	mgetscb ds
	assume	ds:grp
	pop	ax
	mov	[scbnotsl],ah
	pop	ds
	assume	ds:nothing
	ret
reordn2:

; not first
; new position precedes old
; first insert tcb in new position

	mov	ds,dx
	assume	ds:tcb,es:nothing

; ds = new prior tcb
; es = new next tcb
; bx = this tcb

	mov	[tcbpripn],bx
	mov	ds,bx
	mov	si,[tcbpripn]		; remember old next in list for our tcb
	mov	[tcbpripn],es

; not first
; new position precedes old
; inserted at new position
; find the old position

	assume	ds:nothing,es:tcb
reordn3:
	mov	ax,[tcbpripn]
	or	ax,ax
	jz	reordn4a		; tcb not in priority list until now
	cmp	ax,bx
	je	reordn4
	mov	es,ax
	jmp	reordn3

; not first
; new position precedes old
; inserted at new position
; old position found
; delete it

reordn4:
	mov	[tcbpripn],si
reordn4a:
	mov	es,bx
	jmp	reordout

; not first
; new position follows old
;   ( occurs in tsl if higher priority tasks are blocked)
; delete from old position

reordn5:
	mov	ds,bx
	assume	ds:tcb,es:nothing
	mov	ds,[tcbpripn]
	cmp	cl,[tcbpri]
	jbe	reordn6
	mov	es,bx			; fast out for no change
	jmp	reordout
reordn6:
	assume	ds:nothing,es:tcb
	mov	[tcbpripn],ds
	jmp	reordx1

; tcb first in list

	assume	ds:grp,es:tcb
reordf1:
	mov	es,[tcbpripn]
	cmp	cl,[tcbpri]
	jbe	reordf2
	mov	es,bx
	jmp	reordout

; tcb first in list
; some other has a higher priority
;   ( only occurs if priority has been changed )
; delete from list

reordf2:
	mov	[scbpripf],es		; delete from list (bx is ours)

; tcb first in list
; some other has a higher priority
; deleted from list
; find new position

reordx1:
	mov	ax,[tcbpripn]
	or	ax,ax
	jz	reordx2
	mov	dx,es
	mov	es,ax
	cmp	cl,[tcbpri]
	jbe	reordx1

; tcb first in list
; some other has a higher priority
; deleted from list
; new position found
; insert at new position

	mov	ds,dx
	assume	ds:tcb,es:nothing

; ds = new prior tcb
; es = new next tcb
; bx = this tcb

	mov	[tcbpripn],bx
	mov	ds,bx
	mov	[tcbpripn],es
	mov	es,bx
	jmp	reordout

; tcb first in list
; some other has a higher priority
; deleted from list
; find new position
; insert at last position

	assume	ds:nothing,es:tcb
reordx2:
	mov	[tcbpripn],bx
	mov	es,bx
	mov	[tcbpripn],0
	jmp	reordout
reordlst endp 

	subttl lansatpoll - this routine is designed for lanlink netbios
	page
;======================================================================
;,fs
; lansatpoll - this routine is designed for lanlink netbios
;
; this routine is designed so that LanLink Netbios can
; get polled more offen then the normal timer (INT 8) logic.  The
; device driver will hook its far routine into SCBUPOLL and make sure
; after it finishes its poll needs, that it chains to the previous hander
; on the SCBUPOLL chain unless it is 0.
;
; This logic has been designed so that it will not re-enter itself.
;
; in:
;
; out:
;
;,fe
;======================================================================
	assume	ds:grp,es:nothing
LanSatPoll proc near 
	cmp	word ptr [scbupoll+2],0
	je	skipLanSat
	push	bx
	push	cx
	push	dx
	push	si
	push	di
	push	es
	push	ds
	xor	dh,dh
	call	bias_stack		; bias stack because poll routine is
	assume ds:tcb			; likely to re-entry mos
	MGetSCB es
	assume	es:grp
	pushf
	cli
	cmp	[insidelupoll],'Y'
	je	skipinside
	mov	[insidelupoll],'Y'
	popf
	push	ds
	call	dword ptr [scbupoll]	; call poll routine
	pop	ds
	mov	[insidelupoll],'N'
	pushf
skipinside:
	popf
	pop	word ptr [tcbstkp]
	pop	ds
	pop	es
	pop	di
	pop	si
	pop	dx
	pop	cx
	pop	bx
SkipLanSat:
	ret
LanSatPoll endp 

	subttl userpoll - calls the user poll routine
	page
;======================================================================
;,fs
; userpoll - calls the user poll routine
;
; this routine should be call when evertask is switch into
; memory and needs servicing by a user defined poll routine (tcbupoll)
;
; this routine is originally designed so that the generic mouse irqs
; can be designed in such a fashion that the task does not need to be
; switch in everytime we call the mouse user routine (in fact, there is
; actually no unnecessary switching in and out using this technique.
;
; user intercept of tcbupoll should save prevous version of tcbupoll
; and call it if not 0.  this is to allow for possiable chaining of
; user poll routines.
;
; update userpoll case so that it is faster if not using poll routine
; also made sure that full context is when calling poll routine
;
; in:
;
; out:
;
;,fe
;======================================================================
	assume ds:nothing,es:nothing,ss:nothing
userpoll proc near 
	push	ds
	mgetscb ds
	assume ds:grp
	call	LanSatPoll
	mov	ds,[scbtcbpc]
	assume ds:tcb
	cmp	word ptr [tcbupoll+2],0 ; is poll routine installed?
	je	upskip

; poll routine is installed, so we must now make sure that context is
; is fully switch in.  this is necessary because poll routine can call
; user interupt routine in task space (ie - $mouse.sys)

	test	[tcbega],4		; skip if an unwatched ega task
	jnz	upskip			; has been suspended
	push	ax
	mgetscb ds
	assume	ds:grp
	cmp	[invidram],'Y'
	je	skpoll
	mov	ax,[scbtcbpc]
	cmp	ax,[scbtcbps]
	jne	skpoll			; skip if full context is not in
	cmp	[scbtcbvs],-1
	je	skpoll
	cmp	[scbtcbvr],-1		; skip if video is dirty
	je	skpoll
	push	bx
	push	cx
	push	dx
	push	es
	xor	dh,dh
	call	bias_stack		; bias stack because poll routine is
	assume ds:tcb			; likely to re-entry mos
	call	dword ptr [tcbupoll]	; call poll routine
	pop	word ptr [tcbstkp]
	pop	es
	pop	dx
	pop	cx
	pop	bx
skpoll:
	pop	ax
upskip:
	pop	ds
	assume ds:nothing
	ret
userpoll endp 

	subttl dopost - call and clear the tcbpost vector
	page
;======================================================================
;,fs
; dopost - call and clear the tcbpost vector
;
; the post function is called with interrupts disabled.
; this function does not enable interrupts if they weren't already.
;
; in:	es -> sleeping tcb
;
; out:	none
;
;,fe
;=====================================================================
	assume	ds:nothing,es:tcb,ss:nothing
public	dopost
dopost	proc	near
	pushset ax,bx,cx,dx,si,di,ds,es
	pushf
	cli
	push	word ptr [tcbpost+2]
	push	word ptr [tcbpost]
	push	bp
	mov	bp,sp
	mov	word ptr [tcbpost],0
	mov	word ptr [tcbpost+2],0
	call	dword ptr [bp+2]
	pop	bp
	add	sp,4
	popf				; restore original flags
	popset ax,bx,cx,dx,si,di,ds,es
	ret
dopost	endp	


	subttl gated_dopoll - calls dopoll with reentrance control
	page
;======================================================================
;,fs
; gated_dopoll - calls dopoll with reentrance control
;
; in:	ss -> tcb
;	ds -> grp
;
; out:	
;
;,fe
;=====================================================================
	assume	ds:grp,es:nothing,ss:tcb
gated_dopoll proc near
	cli
	cmp	[scbdopflg],0
	jne	gdp1
	mov	[scbdopflg],1
	sti
	call	savecrit
	call	dopoll			; give their poll routines a call
	call	restorcrit
	mov	[scbdopflg],0
gdp1:
	sti
	ret
gated_dopoll endp

	subttl tsl_maint - maintenance for sleeping tasks
	page
;======================================================================
;,fs
; tsl_maint - maintenance for sleeping tasks
;
; in:	ss -> sleeping tcb
;	ds -> grp
;
; out:	crashes ax,bx,cx,dx,bp,ds,es
;
;,fe
;=====================================================================
	assume	ds:grp,es:nothing,ss:tcb
tsl_maint proc near

; if the task has been suspended for more than a certain number of
; ticks then we yank it out of bed and do some maintenance on it.
; if it has a timer intercept, it must be held awake until it
; experiences an irq0.  while this isn't the most efficient method 
; in the world but its the best I've found so far.
; this "certain number" is tied to tcbkbtck to prevent extra time waste
; when a task will already be forced awake from being in dis mode too
; long.  by using a larger count here, the dis mode force awake usually
; satisfies the need.

	mov	dx,word ptr [tcbattend]
	mov	bx,word ptr [tcbattend+2]
	call	calctime
	or	ax,ax
	jnz	tsl120
	mov	ax,[tcbkbtck]
	add	ax,4
	cmp	cx,ax
	ja	tsl120

; if the task's post vector is non-zero, it must be yanked awake
; right now.

	mov	ax,word ptr [tcbpost]
	or	ax,word ptr [tcbpost+2]
	jnz	tsl120
	jmp	tsl180			; let the poor thing snooze
tsl120:
	mov	[tsl8stat],0		; not ok for int8's to drop scbinmos
	call	switchif
	call	testirqw		; test for an irq error
	call	testflush		; test for a polled flush error
	mgetscb ds
	assume	ds:grp			; if waiting on a key, skip call to
	cmp	[tcbcon417],-1		; if pamswitch flag to update leds
	je	tsl125			; then force call to getkeys
	test	[tcbstat],wkey		; getkeys here
	jnz	tsl130
tsl125:
	and	[tcbega],not 2		; indicate that state-pamming ok
	call	getkeys
tsl130:
	call	gated_dopoll


	call	updattend		; register that they've had attention
	mov	[tsl8stat],1		; ok for int8's to drop scbinmos
	call	userpoll		; call user poll routine

; at this point, process the post vector.  when done, set bp=1 to
; recycle back to the main tsl loop and recheck this same task again.
; the a function in the post chain might have cleared the way for
; this task to wake up.

	mov	ax,word ptr [tcbpost]
	or	ax,word ptr [tcbpost+2]
	jz	tsl133
	push	es
	mov	ax,ss
	mov	es,ax
	call	dopost
	pop	es
	mov	bp,1
	jmp	tsl185
tsl133:

; if either the int8 or int1c vector has changed since the task
; was started, set lagtcb to force the task out of suspension 
; until their timer isr gets called.

	mov	ax,[tcborig8]		; only test if have gotten through
	or	ax,[tcborig8+2] 	; ntrtsk and initialized the
	jz	tsl180			; reference variables.
	mgetzero es
	assume	es:nothing
	mov	ax,es:[8*4]
	cmp	ax,[tcborig8]
	jne	tsl160
	mov	ax,es:[8*4+2]
	cmp	ax,[tcborig8+2]
	jne	tsl160
	mov	ax,es:[1ch*4]
	cmp	ax,[tcborig1c]
	jne	tsl160
	mov	ax,es:[1ch*4+2]
	cmp	ax,[tcborig1c+2]
	je	tsl180
tsl160:
	cmp	[pamskip],1		; skip if in the middle of pamswitching
	je	tsl180
	test	[tcbega],4		; test for ega task being suspended
	jnz	tsl180
	mov	dx,word ptr [tcblagcnt] ; and haven't called them for
	mov	bx,word ptr [tcblagcnt+2]  ; 10 ticks then make sure they
	call	calctime		; get called by setting lagtcb
	or	ax,ax			; for the int8 logic to see
	jnz	tsl170
	cmp	cx,10
	jna	tsl180
tsl170:
	mov	[lagtcb],ss
	mov	bp,1			; signal to recycle with same ss
	jmp	short tsl185
tsl180:

; see if any restarts are pending

	cmp	[tcbrstok],0		; can restart run on this task?
	je	tsl184
	cmp	[scbrstrtc], 0		; any tasks to restart
	je	tsl182			; press on if no restarts required
	call	chkrstrt		; see if any tasks to restart
tsl182:
	cmp	[scbrstrtp], 0		; is a task ready to restart
	je	tsl184			; press on if not yet
	call	restart 		; go restart this task
tsl184:
	push	ss			; must use es-> tcb when get
	pop	es			; the next task from tcbpripn.
	xor	bp,bp			; signal to recycle with new ss
tsl185:
	ret
tsl_maint endp

	subttl tsl - task selection logic
	page
;======================================================================
;,fs
; tsl - task selection logic
;
; this routine will select the next task to run.  selection will be
; based on the tasks priority and the last time that the task was
; selected.
;
; any time you modifiy tsl you must consider what effect your mods may
; have on the data saving and restoring process that is done savecrit
; and restorcrit procedures (above).  this saving and restoring of
; critical tsl data is used in the procedure testirqw.	the intent of
; this saving and restoring is to allow tsl to be re-entered again
; within the same task and be able to recover when un-wind back to a
; previous existance within tsl. have fun
;
; added suspend2 call which allow tsl to be re-enter
; by saving critical section of tsl, and call old suspend, then
; restoring critical section.  this is done in mosint17 and mosint38
; wait function.
;
; corrected suspend2, made sure that tcbwait is
; propertly handle. shift print screen (new print logic) was suspending
; but poll routine was never getting called.
;
; corrected suspend2, by making sure that intsl is saved and restored
; and set to 0 when calling main suspend logic of suspendx
;
; in:	ss -> current tcb
;
; out:	ss -> newly selected tcb (may still be the same)
;	all registers preserved
;
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:tcb
suspend2 proc near 
	push	ds
	mgetscb ds
	assume	ds:grp
	push	[tcbsp]
	mov	al,[intsl]
	push	ax
	mov	[intsl],0
	call	suspendx
	pop	ax
	mov	[intsl],al
	pop	[tcbsp]
	pop	ds
	assume	ds:nothing
	ret
suspend2 endp 

suspend proc near 
	push	ds
	mgetscb ds
	assume	ds:grp
	cmp	byte ptr [intsl],0
	jne	sus1
	call	suspendx
sus1:
	pop	ds
	assume	ds:nothing
	ret
suspend endp 

	assume	ds:grp,es:nothing,ss:tcb
suspendx proc near
	push	ds
	push	ax
	cli
	mov	ax,[scbtcbpc]		; if we are in the middle of
	cmp	ax,[scbtcbps]		; context switching logic, it is
	sti
	pop	ax			; too messy to suspend. this needs
	jne	tsl020			; to be look into.
	cmp	[scbnotsl],'Y'		; locked out?
	je	tsl020
	cli
	inc	[scbinmos]
	inc	[intsl]
	sti
	push	es
	cmp	[scbreg32],'Y'
	je	tsl386a
	pushset bp,di,si,dx,cx,bx,ax
	pushf
	jmp	tsl386b
tsl386a:
	db	66h			; esp
	push	sp
	db	0fh,0a8h		; push gs
	db	0fh,0a0h		; push fs
	db	66h
	push	bp
	db	66h
	push	di
	db	66h
	push	si
	db	66h
	push	dx
	db	66h
	push	cx
	db	66h
	push	bx
	db	66h
	push	ax
	db	66h
	pushf
tsl386b:
	test	[tcbstat],wkey
	jz	tsl010
	or	[tcbdidkey],01h
tsl010:
	cli
	cmp	[scbvdrflg],0
	jne	tsl012
	mov	[scbvdrflg],1
	sti
	call	savecrit		; savecrit crashes cx
	mov	cx,[scbtimer]		; must be call after savecrit
	call	vidram
	call	restorcrit
	mov	[scbvdrflg],0
tsl012:
	sti
	mov	al,[scbnoswt]		; save suspended value of scbnoswt
	push	ax
	mov	[scbnoswt],0		; clear any no switching calls
	jmp	short tsl040		; rejoin tsl already in progress
tsl020:
	pop	ds
	ret
	assume	ds:nothing,es:nothing,ss:tcb
tsl:
	push	ds
	mgetscb ds
	assume	ds:grp
	push	ax
	cli
	mov	ax,[scbtcbps]
	cmp	ax,[scbtcbpc]
	sti
	pop	ax
	jne	tsl020
	cmp	byte ptr [scbnotsl],'Y'
	je	tsl020
	cmp	byte ptr [intsl],0
	jne	tsl020
	cli
	inc	[scbinmos]
	inc	[intsl]
	sti
	push	es
	cmp	[scbreg32],'Y'
	je	tsl386c
	pushset bp,di,si,dx,cx,bx,ax
	pushf
	jmp	tsl386d
tsl386c:
	db	66h			; esp
	push	sp
	db	0fh,0a8h		; push gs
	db	0fh,0a0h		; push fs
	db	66h
	push	bp
	db	66h
	push	di
	db	66h
	push	si
	db	66h
	push	dx
	db	66h
	push	cx
	db	66h
	push	bx
	db	66h
	push	ax
	db	66h
	pushf
tsl386d:
	mov	al,[scbnoswt]		; save current scbnoswt (0 to switch)
	push	ax
tsl040:
	inc	[tcbtslnst]		; task specific tsl nest counter

; the following test to see if application has mask out irq 0's
; and called a function which will enventualy call tsl which will
; switch task and because irq 0 is disable we will no be able to
; get control and thus we will be stuck in the other task.  if
; application does this we can logically assume that this app
; should not spend much time in this state.

	in	al,21h
	test	al,1			; check irq 0
	jnz	tsl041
	test	[tcbwait],1		; is this task to be suspended?
	jnz	tsl050			; yes, activate someone else
	cmp	byte ptr [tcbslcnt],0
	je	tsl050			; slice counter reached 0? (from int8)
tsl041:
	jmp	tsl280			; else, task still has time to run
tsl050:
	mov	[scbpost],0		; tell netbios post - no task now

; need to call getkeys frequently for each task and during a time
; when the task is fully switched in.  this call used to be made on
; the way out of tsl.  this caused a problem when an unwatched ega
; condition could cause a secondary suspension.  to prevent such
; problems, the call is made here, just before a task is switched out.

	and	[tcbega], not 2 	; state-pamming ok
	pushset	ax,cx
	call	savecrit
	call	getkeys 		; give the task a chance to be heard
	call	restorcrit
	popset	ax,cx
	mov	[tsl8stat],0		; not ok for int8's to drop scbinmos

; set tcbcpos to value located in bios data area.  just in case
; someone sets it directly.

	cmp	[tcbin10],0		; if inside mosint10 logic
	jne	tsl055			; no need to synce cursors

	push	es
	mgetzero es
	mov	bl,[tcbpage]
	xor	bh,bh
	mov	ax,word ptr es:[bx+0450h]
	mov	[tcbcpos+bx],ax
	pop	es
	push	cs
	call	csynch			; sync all terminal cursors for task
tsl055:
	mov	ax,ss
	call	egaoff			; turn off ega io protection
	mov	[tcbsp],sp		; save state of old task
	mov	ah,[tcbdidkey]		; if didkey in either of last 2 slices
	and	ah,01h
	mov	al,ah
	xor	al,[tcbpri]
	test	al,01h			; has priority really been changed?
	jz	tsl060			; z if not
	mov	al,[tcbpri]		; else change it
	and	al,0feh
	or	al,ah
	mov	[tcbpri],al
	push	ss
	pop	es
	call	reordlst
tsl060:
	mov	bx,[scbpripf]		; start at the top
	jmp	short tsl080
tsl065: 				; recycle point
	assume	es:tcb,ss:nothing
	mov	bx,[tcbpripn]		; prepare to check next tcb
	or	bx,bx			; check for end of list
	jnz	tsl080
	mov	bx,[scbpripf]		; back to top of priority list
tsl080:
	mov	es,bx
	assume	es:tcb,ss:nothing	; don't switch to the next stack
	cmp	[tcbsp],0		; until we're sure tcbsp != 0
	je	tsl065			; and tcbslice != 0
	cmp	[tcbslice],0
	je	tsl065
	assume	es:nothing,ss:tcb
	cli
	mov	ss,bx
	mov	sp,[tcbsp]		; get state of new task
	mov	[tsl8stat],1		; ok for int8's to drop scbinmos
	mov	ax,ss
	cmp	ax,[scbtcbpc]
	je	tsl090
	mov	[tsl8stat],0		; wait until ss == [scbtcbpc]
tsl090:
	test	[tcbega], 4		; waiting on state-pamming
	jnz	tsl100
tsl093:

; if not nested within tsl and called by intd4fun0f and the force 
; awake flag is set, clear the force flag and wake up directly.  

	cmp	[tcbtslnst],1
	jne	tsl094
	cmp	[tcbd40f],1
	jne	tsl094
	cmp	[tcbfwake],0
	je	tsl094
	mov	[tcbfwake],0
	and	[tcbwait],not 1
	jmp	tsl190
tsl094:
	test	[tcbwait],1		; if task not waiting --> tsl190
	jnz	tsl095
	jmp	tsl190
tsl095:
	sti
	push	ss
	pop	es			; es -> tcb for the suspend call
	call	[tcbpoll]		; see if wait condition resolved
	mov	[tcbstat],al		; save waiting status
	or	al,al
	jnz	tsl100
	and	[tcbwait],0f0h		; clear wait info
	jmp	tsl190

; enter here when a task is still suspended

tsl100:
	sti
	cmp	[lagtcb],0		; if this task needs an int8,
	jne	tsl095			; do a short loop until they get one
	call	tsl_maint
	or	bp,bp			; bp == 0 means recycle with new ss
	jnz	tsl093			; bp != 0 means recycle with same ss
	jmp	tsl065

; enter here when find a task to switch to

tsl190:
	sti
	mov	[tsl8stat],0		; not ok for int8's to drop scbinmos
	call	switchif
	call	testirqw		; test for an irq error
	call	testflush		; test for a polled flush error
	mov	al,[tcbslice]		; reset it when down to 0
	mov	[tcbslcnt],al

; if this task is keyboard intensive,
;   check all other tasks of the same (unenhanced) priority
;   if any has a key ready, bump its priority
; if this task isn't keyboard intensive,
;   check any other tasks of the same priority which were keyboard-intensive
;     within their last 8 ticks
; note that the tasks we are checking aren't keyboard suspended, so there's
;   no conflict calling kbpoll00

	mov	bl,[tcbpri]
	mov	bh,bl
	and	bl,not 01h
	mov	ax,ss
	mov	es,ax
	assume	es:tcb,ss:nothing
tsl200:
	mov	ax,[tcbpripn]
	or	ax,ax
	jz	tsl220			; end of tcb list
	mov	es,ax
	cmp	bl,[tcbpri]
	jb	tsl200			; b if also kb intensive
	ja	tsl220			; a if lower true priority
	test	bh,01h			; check all with this (true) priority
	jnz	tsl210			; if this guy is kb-intensive
	test	[tcbdidkey],0ffh	; else just check the ones who
	jz	tsl200			; have been kb-intensive recently
tsl210:
	push	cs			; (for kbpoll00's retf)
	call	kbpoll00
	or	al,al
	jnz	tsl200			; nz if no keys available
	or	[tcbpri],01h		; else bump the priority
	mov	al,[tcbpri]
	push	bx
	call	reordlst
	pop	bx
	jmp	tsl200
tsl220:
	assume	es:nothing,ss:tcb
	mov	ax,ss
	mov	es,ax
	mov	al,[tcbpri]
	call	reordlst		; put tcb last for its priority
	shl	[tcbdidkey],1
	mov	al,[tcbslice]
	xor	ah,ah
	mov	cx,1			; task selection uses bit 0
	push	ss
	pop	es

; need to call getkeys when switching a task in to give a good
; keyboard response, but, can't allow pamswitching at this point.

	or	[tcbega],2		; indicate ega\vga not ok

; set flag to cause int5 to be deferred.  if the spooler is loaded,
; having disk i/o result at this time can cause disk layer re-entrance.

	mgetscb ds
	assume	ds:grp
	mov	[scbnoi5],1
	call	getkeys 		; give the task a chance to be heard
	mov	[scbnoi5],0
	call	gated_dopoll
	call	chkirq			; need to check vectors often

; the following logic was added so that restart can be done while task
; are busy on system

	cmp	[tcbrstok],0		; can restart run on this task?
	je	tsl194
	cmp	[scbrstrtc], 0		; any tasks to restart
	je	tsl192			; press on if no restarts required
	call	chkrstrt		; see if any tasks to restart
tsl192:
	cmp	[scbrstrtp], 0		; is a task ready to restart
	je	tsl194			; press on if not yet
	call	restart 		; go restart this task
tsl194:
	call	updattend		; register that they've had attention
	call	userpoll		; call user polll routine
	call	set_trap		; set i/o trapping level for task

; if post != 0, call the chain now
  
	cli
	mov	[scbpost],ss		; tell netbios post, ss == cur task
	mov	ax,word ptr [tcbpost]
	or	ax,word ptr [tcbpost+2]
	jz	tsl280
	mov	ax,ss
	mov	es,ax
	call	dopost
tsl280:
	sti
	pop	ax			; restore saved scbnoswt
	mov	[scbnoswt],al
	cli
	dec	[intsl]
	dec	[scbinmos]
	sti

; if not nested in tsl, clear the tcbd40f flag.  only need to do this when
; suspend is called from intd4fun0f but its faster to just clear it
; at all times.

	cmp	[tcbtslnst],1
	jne	tsl285
	mov	[tcbd40f],0
tsl285:
	dec	[tcbtslnst]		; task specific tsl nest counter

; the launch_point label is used by the code in mosinit2

launch_point:
	cmp	[scbreg32],'Y'
	je	tsl386m
	popf
	popset	bp,di,si,dx,cx,bx,ax
	jmp	tsl386n
tsl386m:
	db	66h
	popf
	db	66h
	pop	ax
	db	66h
	pop	bx
	db	66h
	pop	cx
	db	66h
	pop	dx
	db	66h
	pop	si
	db	66h
	pop	di
	db	66h
	pop	bp
	db	0fh,0a1h		; pop	fs
	db	0fh,0a9h		; pop	gs
	db	66h
	pop	sp			; esp
tsl386n:
	pop	es
	pop	ds
	ret
suspendx endp 

	subttl	mosintxx - hardware interrupt intercept routines
	page

hwint	macro	num
mosint&num label near
	push	si
	push	bx
	mov	si,offset grp:[oint&num]
	mov	bx,offset grp:[scbhwcl] + num&h - 68h  ;; scbhwcl + irq #
	jmp	mosintxx
	endm

hw2int	macro	num
mos2nd&num label near
	push	si
	push	bx
	mov	si,offset tcb:[tcbapv&num]
	mov	bx,offset grp:[scbhwcl] + num&h - 68h  ;; scbhwcl + irq #
	jmp	mos2ndxx
	endm

irp	num,<70, 71, 72, 73, 75, 76, 77>
	hwint	num
	hw2int	num
	endm

	subttl mosintxx - general hardware intercept logic
	page
;======================================================================
;,fs
; mosintxx - general hardware intercept logic
;
; this routine will get control from a hardware interrupt and increment
; the corresponding interrupt counter in the scb.  it will then jump
; to the old interrupt service routine pointed to by si.
;
; in:	values of si, bx at interrupt time pushed on stack
;	grp:bx -> hardware interrupt count byte to increment in scb
;	grp:si -> old contents of interrupt vector
;
; out:	one byte in [scbhwcl] will be incremented.
;	all registers preserved
;
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:nothing
mosintxx proc near 
	push	bp
	mov	bp,sp
	push	ds
	mgetscb ds
	assume	ds:grp
	inc	byte ptr [bx]		; increment hardware int count
mixx10:
	mov	bx,word ptr [si]	; get original int xx offset
	xchg	[bp+2],bx		; set up for retf (& get bx back)
	mov	si,word ptr [si+2]	; seg
	xchg	[bp+4],si		; restore old si value
	pop	ds
	assume	ds:nothing
	pop	bp
	retf				; on to original int xx
mosintxx endp 

	subttl mos2ndxx - general hardware intercept logic
	page
;======================================================================
;,fs
; mos2ndxx - general hardware intercept logic
;
; this routine will get control from a hardware interrupt.  it is called
; if a user program has taken over the interrupt vector.  this routine
; gets control first, increments its counter, then transfers control
; to the logic in mosintxx for jumping to the next isr in the chain
;
; in:	values of si, bx at interrupt time pushed on stack
;	grp:bx -> hardware interrupt count byte to increment in scb
;	tcb:si -> old contents of interrupt vector
;
; out:	one byte in [scbhwcl] will be incremented.
;	all registers preserved
;
;,fe
;======================================================================
mos2ndxx proc near 
	push	bp
	mov	bp,sp			; pointer to saved registers on stack
	push	ds
	mgetscb ds
	assume	ds:grp
	inc	byte ptr [bx]		; increment hardware int counter
	mov	ds,[scbtcbpc]		; current task's info
	jmp	mixx10			; jump to task's interrupt handler
mos2ndxx endp 

;----------- intercept logic for irq'S 2 THROUGH 7 ----------------

; this table is used with the index value from scbirqdxx to
; distribute control flow to the appropriate irq handling code.
; equate values for the index to this table are declared within
; the macros.inc file.

irq_distr label word
	dw	no_res
	dw	nps_res
	dw	ps_res
	dw	auto_res

; one irqdataxx data table for each of irq2 through 7

iqd_def macro	vnum
irqdata&vnum label byte
	dw	vnum&h - 0ah		;; 0 based byte index
	dw	vnum&h*4		;; offset of vector in 0:0 table
	dw	grp:oint&vnum		;; offset of orig vector in irq seg
	dw	tcbapv&vnum		;; offset of tcb vector
	endm

; structure used to access the irqdataxx data table

irqdstc struc
iqd_bndx	dw	?		; 0 based byte index
iqd_0ofs	dw	?		; offset of vector in 0:0 table
iqd_iofs	dw	?		; offset of orig vector in irq seg
iqd_tofs	dw	?		; offset of tcb vector
irqdstc ends

; one set of irq entry handlers for each of irq2 through 7

iqe_def macro	vnum
public	lidt&vnum
lidt&vnum&:
	push	ax
	mov	al,1
	jmp	short cmn&vnum
public	regrsec&vnum
regrsec&vnum:
	push	ax
	mov	al,2
cmn&vnum&:
	push	bx
	push	si
	mov	si,offset irqdata&vnum
	mov	bx,offset scbirqd&vnum
	jmp	irqcommon
	endm

; instantiate the data tables and entry handling code

	irp	in,<0a,0b,0c,0d,0e,0f>
	iqd_def in
	iqe_def in
	endm

; default handling stub for lidt case

lidtst_af proc far 
	push	ax
	mov	al,20h
	out	20h,al
	pop	ax
	iret
lidtst_af endp 
 

; build index list for the irqbank logic

iqd_ndx macro	vnum
	dw	irqdata&vnum
	endm

irqd_index label word
	irp	in,<0a,0b,0c,0d,0e,0f>
	iqd_ndx in
	endm

	subttl irqbank - logic used by device drivers for bank select ports
	page
;======================================================================
;,fs
; irqbank - logic used by device drivers for bank select ports
;
; this routine is provided for use by device drivers which
; manage bank switched serial ports (e.g. viewport technology
; products).
;
; in:	cx = tcb of task to receive the irq
;	bx = 0 based word index (e.g. 0 for irq2, 2 for irq3, etc.)
;
; out:
;
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:nothing
irqbank proc far 
	pushset ax,bx,si,ds,es
	mgetscb ds
	assume	ds:grp
	mov	si,cs:[irqd_index+bx]	; setup si for swcall/callisr
	test	[scbmmfea],4
	jnz	iqb1
	mov	es,cx
	mov	bx,cs:[si].iqd_tofs	; if not lidt
	mov	ax,es:[bx]		; make sure tcbapvxx != 0
	or	ax,es:[bx+2]
	jz	iqb4			; if it is 0, nullify the irq
iqb1:
	cmp	cx,[scbtcbpc]		; if not full match, use swcall
	jne	iqb2
	cmp	cx,[scbtcbps]
	jne	iqb2
	call	callisr 		; else call the isr
	jmp	short iqb3
iqb2:
	call	swcall
	jmp	short iqb3
iqb4:
	mov	al,20h			; nullify the irq
	out	20h,al
iqb3:
	popset	ax,bx,si,ds,es
	retf
irqbank endp 

	subttl irqcommon - common entry point for irq2-7 handlers
	page
;======================================================================
; .func: irqcommon - common entry point for irq2-7 handlers
;
; input:
;	al = 1 for primary level entry, 2 for secondary
;	 (for lidt case, al = 1 but this is yet to be validated)
;	cs:si -> data structure for irq
;	bx = offset of destination table index within scb
;
; output:
;	al = 1 for primary, 2 for secondary level entry
;	  (only valid for non-lidt case)
;	bx = 0 based word index
;	cs:si -> data structure for irq
;	ds -> grp
;	[bp] -> entry bp		[bp+2] -> entry si
;	[bp+4] -> entry bx		[bp+6] -> entry ax
;	[bp+8] -> interrupted ip	[bp+10] -> interrupted cs
;
; comments:
;	this piece of code isn't a complete/normal function.  it is
;	entered by each of the irq2-7 front end pieces of code and
;	exits by jumping to the appropriate finish-up handler
;
; .calls:
; .reads:
; .writes:
;
; .endfn
;======================================================================
irqcommon proc near 
	push	bp
	mov	bp,sp
	push	cx
	push	dx
	push	di
	push	ds
	push	es
	mgetscb ds
	assume	ds:grp
	mov	di,cs:[si].iqd_bndx	; fetch 0 based byte index
	mov	dx,di
	shl	dx,1			; form word index
	add	di,2			; adjust for irq0 and 1
	inc	byte ptr [scbhwcl+di]	; inc irq counter for int38fun07
	mov	di,[bx] 		; fetch destination index
	mov	bx,dx			; word index in bx
	jmp	cs:[di].irq_distr	; jmp to destination address

	subttl no_res - handler for the "no irq resevation" case
	page
;======================================================================
; .func: no_res - handler for the "no irq resevation" case
;
; input:
;	cs:si -> data structure for irq
;	[bp+4] -> entry bx
;	[bp+6] -> entry ax
;	ds -> grp
;
; output:
;
; comments:
;	exchange the stack positions of entry ax and bx with the far
;	pointer from the irq segement entry.  this restores the ax
;	and bx registers and sets up for entry to the device driver's
;	interrupt service routine.
;	note: this code is used for the device driver case as well
;	as the default.
;
; .calls:
; .reads:
; .writes:
;
; .endfn
;======================================================================
	assume	ds:grp,es:nothing,ss:nothing
no_res:
	mov	di,cs:[si].iqd_iofs
	mov	bx,word ptr [di]	; get original int xx offset
	xchg	[bp+4],bx		; set up up for retf
	mov	ax,word ptr [di+2]
	xchg	[bp+6],ax
	pop	es
	pop	ds
	pop	di
	pop	dx
	pop	cx
	pop	bp
	pop	si
	assume	ds:nothing
	retf

	subttl nps_res - handler for the "non-port specific reservation" case
	page
;======================================================================
; .func: nps_res - handler for the "non-port specific reservation" case
;
; input:
;	al = 1 for primary, 2 for secondary level entry
;	  (only valid for non-lidt case)
;	bx = 0 based word index
;	cs:si -> data structure for irq
;	ds -> grp
;	[bp+4] -> entry bx
;	[bp+6] -> entry ax
;
; output:
;
; comments:
;	an explicit, non port specific, irq reservation was done.  if the
;	task which made the reservation isn't currently switched in (based
;	on scbtcbpc) then use swcall.  if the context matches but the task
;	ram doesn't then also must use swcall.  If both match, and there
;	is currently an intercept for this irq, then use callisr.
;
; .calls:
; .reads:
; .writes:
;
; .endfn
;======================================================================
	assume	ds:grp,es:nothing,ss:nothing
nps_res:
	inc	[scbinirq]		; not ok to do slicing
	call	fix_entlvl		; need to know the real entry level
	mov	cx,[scbidq2+bx] 	; get reservation status
	mov	es,cx
	cmp	cx,[scbtcbpc]		; if not full match, use swcall
	jne	npr1
	cmp	cx,[scbtcbps]
	jne	npr1
	cmp	al,1			; current task has reservation.  if
	lje	irqpasson		; at primary level, pass on to bios
	call	callisr 		; else call the isr
	jmp	irq_done

; must be a useirq from another task so switch it in and call its isr
; first, make sure some idiot didn't do a mos use irq 6 in one task
; and attempt floppy disk access from another.

npr1:
	test	[scbmmfea],4		; skip for lidt
	jnz	npr2
	mov	bx,cs:[si].iqd_tofs
	mov	ax,es:[bx]		; make sure tcbapvxx != 0
	or	ax,es:[bx+2]
	ljz	irqpasson
npr2:
	call	swcall
	jmp	irq_done

	subttl ps_res - handler for the "port specific reservation" case
	page
;======================================================================
; .func: ps_res - handler for the "port specific reservation" case
;
; input:
;	bx = 0 based word index
;	cs:si -> data structure for irq
;	ds -> grp
;	[bp+4] -> entry bx
;	[bp+6] -> entry ax
;
; output:
;
; comments:
;
; .calls:
; .reads:
; .writes:
;
; .endfn
;======================================================================
	assume	ds:grp,es:nothing,ss:nothing
ps_res:
	inc	[scbinirq]		; not ok to do slicing
	push	bp
	xor	bp,bp			; init match flag

; assuming scbidqp holds a good vector since scbirqdxx
; was set for ps_res

	mov	es,[scbidqp]
	mov	cl,5
	shl	bx,cl			; bx *= 32 to index idqp table
	cmp	word ptr es:[bx],0	; any ports registered in table??
	je	psr5
	mov	di,bx			; save base of table section
	mov	ax,16			; max number of table entries
psr1:
	mov	dx,es:[bx]		; get port address from table
	add	dx,5
	push	ax
	in	al,dx			; see if this port cuased the irq
	test	al,1
	pop	ax
	jz	psr4
	mov	cx,es:[bx+2]		; yes, it did so get the tcb for
	cmp	cx,[scbtcbps]		; the port and if both task ram
	jne	psr2			; and context are equal to the tcb
	cmp	cx,[scbtcbpc]		; for the port
	jne	psr2
	call	callisr 		; if current task than call isr
	jmp	short psr3
psr2:
	call	swcall			; irq is not in current task
psr3:
	sti
	mov	bp,1			; set match flag
	mov	bx,di			; start over at beginning of table
	jmp	short psr1
psr4:
	dec	ax
	jz	psr5
	add	bx,4
	cmp	word ptr es:[bx],0	; any more ports in table?
	jne	psr1
psr5:
	or	bp,bp
	pop	bp
	ljz	irqpasson
	jmp	irq_done

	subttl auto_res - handler for the "automatic reservation" case
	page
;======================================================================
; .func: auto_res - handler for the "automatic reservation" case
;
; input:
;	al = 1 for primary, 2 for secondary level entry
;	  (only valid for non-lidt case)
;	bx = 0 based word index
;	cs:si -> data structure for irq
;	ds -> grp
;
; output:
;
; comments:
;	process port specific irq reservations.  note that for speed,
;	this code is setup to expect 16 port/tcb table entries per
;	irq rather than use an equate variable and multiply to calc
;	the table index.  the code in mos.asm to manage the port
;	specific irq reservation table must match.  it has an equate
;	named fpiq for the # of table entries.
;
; .calls:
; .reads:
; .writes:
;
; .endfn
;======================================================================
	assume	ds:grp,es:nothing,ss:nothing
auto_res:
	inc	[scbinirq]		; not ok to do slicing
	call	fix_entlvl		; need to know the real entry level
	mov	es,word ptr [scbirqpf+bx]
	assume	es:tcb			  ; if only 1 task with an intercept
	cmp	word ptr [tcbirqpn+bx],0  ; not ambiguous
	je	atr1
	mov	es,[scbtcbpf]
	assume	es:tcb			; else, its ambiguous so
atr0:
	cmp	[tcbid],0		; find task 0
	je	atr3
	mov	es,[tcbtcbpn]
	jmp	short atr0
atr3:
	call	setirqflags		; and set flags for popup window
	mov	al,20h
	out	20h,al
	jmp	short irq_done
	assume	es:nothing
atr1:
	cmp	al,1			; if at primary level
	jne	atr4
	mov	cx,[scbirqpf+bx]	; get last task to set an intercept
	call	swcall			; switch it in and call its isr
	jmp	short irq_done

; running in automatic irq reservation mode - no explicit reservation.
; al != 1 so the entry is from the secondary level.
; the task which owns the current context is the only one with an
; intercept so there is no ambiguity.  now, must make sure that the
; currently switched in task ram matches the context.  if not, will
; need to call swcall instead of callisr.

atr4:
	mov	cx,[scbtcbpc]
	cmp	cx,[scbtcbps]
	jne	atr5
	call	callisr
	jmp	short irq_done
atr5:
	call	swcall
irq_done:
	dec	[scbinirq]		; ok to do slicing
	pop	es
	pop	ds
	pop	di
	pop	dx
	pop	cx
	pop	bp
	pop	si
	pop	bx
	pop	ax
	assume	ds:nothing
	iret

	assume	ds:grp,es:nothing,ss:nothing
irqpasson:
	dec	[scbinirq]		; ok to do slicing
	jmp	no_res
irqcommon endp 

	subttl swcall - switch in task and call isr
	page
;======================================================================
;,fs
; swcall - switch in task and call isr
;
; switch in the task which is to get the irq and call its isr.	then
; switch the previous task back in.
;
; support ps/2 mouse which is not irq driver but
; call from bios of the ps/2.  if flag ps2mouse is 'Y' then this routine
; will call ps2call intead trap vector in si.
;
; in:	cx -> tcb to switch in
;	[scbtcbps] -> current tcb
;	ds -> grp
;	cs:si -> data structure for irq
;
; out:	none
;	all registers preserved
;
;,fe
;======================================================================
	assume	ds:grp,es:nothing,ss:nothing
swcall proc near 
	pushset ax,bx,cx,dx,si,di,es,bp
	mov	es,cx			; es is new tcb address
	assume	es:tcb
	mov	[tcb28timer],0		; reset 28 timer
	cli
	in	al,21h			; hold irq number)
	push	ax
	or	al,0ffh
	out	21h,al			; mask out all irq's (both controllers)
	sti
	mov	ax,[scbtcbps]		; ax saves orig switched-in task id

; must test to see if a stack switch is necessary.  if the task to be
; switched to is the same as the currently switched in task then skip
; the stack switch test altogether.  swcall can be entered where
; [scbtcbps] == entry cx for the case where the state of the vma or vsa
; is dirty.  if a stack switch is done, bp = 0 to signal that a stack
; restore needs to be done.

	mov	bp,ss
	mov	di,es
	cmp	ax,di			; if switching to current task,
	je	swcla			; leave stack alone
	cmp	bp,[tcbendad]
	ja	swcla			; current stack in region of memory
	cmp	bp,[tcbbegad]		; going to be switched??
	jb	swcla
	mov	di,sp			; yes, so switch to the tcb stack of
	mov	ss,cx			; the task being switched in
	mov	sp,[tcbsp]
	push	bp			; push orig ss & sp onto new stack
	push	di
	xor	bp,bp			; bp is 0 if we switched stacks
swcla:
	cmp	[scbswvq],'N'		; if no video switching during irq's
	je	swclv1			; then skip the saving of video data
	push	[scbtcbvr]
	push	[scbvmaal]		; save mapping state
	push	[scbvmahdl]
	push	[scbvmacnt]
	push	[scbvmahdl+2]
	push	[scbvmacnt+2]
	push	[scbvmaseg]
	push	[scblastff]		; save bank selection state
swclv1:
	push	[scbtcbpc]		; save scbtcbpc point (split)
	push	ax			; save original task
	cli
	cmp	[scbswvq],'N'		; if no video switching during irq's
	je	swclv2			; then skip the switchgp call
	mov	[skipswvs],'Y'
	mov	ax,es
	call	switchgp		; get the task with the isr
	mov	[skipswvs],'N'
	jmp	swclv3
swclv2:
	call	swtaskram		; needs es -> tcb
	mov	bx,es
	call	swcntxt
swclv3:

; ax,bx and dx will be crashed by this next section of code

	push	cx
	push	ds
	cmp	[ps2mouse],'Y'
	jne	swcalp1
	mov	dh,1			; could have ss != scbtcbpc
	call	bias_stack		; and intsl == 0 but still need to use
	push	es
	mgetscb es
	assume	ds:tcb,es:grp
	call	ps2call 		; call ps/2 mouse routine here
	pop	es
	pop	word ptr [tcbstkp]
	jmp	short swcalp2
swcalp1:
	assume	ds:grp
	test	[scbmmfea],04		; if using lidt
	jz	swcalp1a
	mov	si,cs:[si].iqd_0ofs	; point si to vector in 0:0 table
	xor	ax,ax
	mov	es,ax
	jmp	short swcalp1b
swcalp1a:
	mov	si,cs:[si].iqd_tofs	; else point si to tcbapvxx
swcalp1b:
	mov	dh,1			; could have ss != scbtcbpc
	call	bias_stack		; and intsl == 0 but still need to use
	assume	ds:tcb
	pushf
	call	dword ptr es:[si]
	pop	word ptr [tcbstkp]
swcalp2:
	pop	ds
	assume	ds:grp
	pop	cx
	pop	ax
	mov	es,ax
	call	swtaskram		; restore the task ram
	pop	bx			; pop off [scbtcbpc] saved
	call	swcntxt 		; restore the context

; recover scblastff - the record of the last bank selection.  if there has
; been no net change then there is no need for a restorative action.
; otherwise, make an ff call to the ddt that was last banked in before the
; above call to switchgp.

	cmp	[scbswvq],'N'		; if no video switching during irq's
	jmpe	swclv4			; then skip the video restoration
	pop	ax
	cmp	ax,[scblastff]
	je	swclc
	mov	[scbbankin],'N' 	; prevents the ff handler in mosddtmc
	push	ds			; from bothering to unmap the vma
	mov	ds,ax
	mov	si,offset [tcbcondd]
	mov	ah,0ffh
	call	dword ptr [si]
	pop	ds
	mov	[scbbankin],'Y' 	; restore ff handling unmapping state
swclc:
	pop	dx
	pop	di
	pop	si			; pop saved mapping vars
	pop	cx
	pop	bx
	pop	ax

; if last action, before the irq, was an unmap then must unmap now but use
; the segment and page count currently in scbvmaseg and scbvmacnt (and cnt+2)
; else if the current mapping (from the switchgp above) was at a different
; segment or had a greater page count than the original mapping then the
; current mapping must be unmapped before restoring the previous mapping
; future  be able to access the memory manager's page table directly and just
; save the chunk of it that pertains to the entire video memory area.  then,
; when need to restore the mapping, can just make one list based call.

	or	dx,dx			; check for no video mapping case
	jz	swclc4
	or	al,al			; originally in an unmapped state?
	jz	swclc1
	cmp	al,3			; is this special mapping for sunriver
	je	swclc4			; is so skip vma mapping (ff handler
	cmp	dx,[scbvmaseg]		; will do it) different segment?
	jne	swclc3
	push	ax
	push	cx
	mov	ax,[scbvmacnt]
	add	ax,[scbvmacnt+2]
	add	cx,di
	cmp	ax,cx			; more pages in now than originally?
	pop	cx
	pop	ax
	ja	swclc3			; if same seg and not more pages, can
	jmp	swclc2			; simply map original over current
swclc1:
	mov	dx,[scbvmaseg]		; when orignally unmapped, must
	mov	cx,[scbvmacnt]		; now unmap what the above switchgp
	add	cx,[scbvmacnt+2]	; call put in the vma
	jmp	swclc2
swclc3:
	push	ax			; if different segment or more pages
	push	cx			; at same segment then must unmap
	push	dx			; current before restoring previous
	xor	al,al			; mapping
	mov	dx,[scbvmaseg]
	mov	cx,[scbvmacnt]
	add	cx,[scbvmacnt+2]
	call	mapvma
	pop	dx
	pop	cx
	pop	ax
swclc2:
	call	mapvma			; restore the vma
swclc4:
	pop	[scbtcbvr]
swclv4:
	or	bp,bp			; was the stack switched?
	jnz	swclf
	pop	di			; yes, unswitch it
	pop	bp
	mov	ss,bp
	mov	sp,di
swclf:
	pop	ax			; reenable hardware interrupts
	out	21h,al
	popset	ax,bx,cx,dx,si,di,es,bp ; interrupts should be off
	ret
swcall endp 

	subttl setirqflags - set a pair of control flags
	page
;======================================================================
;,fs
; setirqflags - set a pair of control flags
;
; set flag bits corresponding to this irq in two bytes.  flag in
; irqwflag indicates that the error has been detected so further irqs
; don't cause more responses.  Flag in tcbwpend indicates that a mesage
; window should be popped up.
;
; in:	bx = 0 based word index
;	es -> tcb which should get window msg
;	ds -> grp
;
; out:	none
;	all registers preserved
;
;,fe
;======================================================================
	assume	ds:grp,es:tcb,ss:nothing
setirqflags proc near 
	push	cx
	mov	ch,1			; derive a bit position for the irq
	mov	cl,bl			; and set the once flag
	shr	cl,1
	shl	ch,cl
	test	ch,byte ptr [irqwflag]	; is flag already set?
	jnz	setq1
	or	byte ptr [irqwflag],ch	; no, so set it and set
	or	[tcbwpend],ch		; the window flag too
setq1:
	pop	cx
	ret
setirqflags endp 

	subttl callisr - call the isr direclty or use swcall
	page
;======================================================================
;,fs
; callisr - call the isr directly or use swcall.
;
; this procedure is to be used when the irq is for the currently
; switched in task.  in this case, it must still be determined whether
; the state of the machine with regards to what's mapped into the vma
; (video memory area) or vsa (video save area) is standard or not.  if
; not standard, use swcall to get the proper video switched in.
;
; in:	ds -> grp
;	cs:si -> data structure for irq
;	cx -> tcb for irq
;
; out:	none
;	no registers changed
;
;,fe
;======================================================================
	assume	ds:grp,es:nothing,ss:nothing
callisr proc near 
	cmp	[scbinswgp],0		; if in switching logic use swcall
	jne	calli1
	cmp	[vdrirq],'Y'		; if vidram has video exposed when it
	je	calli1			; should be vidram then use swcall
	cmp	[scbtcbvr],-1		; if vma or vsa is dirty, use swcall
	je	calli1
	cmp	[scbtcbvs],-1
	jne	calli2
calli1:
	call	swcall
	ret
calli2:
	pushset ax,bx,cx,dx,si,ds,es
	mov	es,cx
	test	[scbmmfea],04		; if using lidt
	jz	calli3
	mov	si,cs:[si].iqd_0ofs	; point si to vector in 0:0 table
	xor	ax,ax
	mov	es,ax
	jmp	short calli4
calli3:
	mov	si,cs:[si].iqd_tofs	; else point si to tcbapvxx
calli4:
	xor	dh,dh
	call	bias_stack
	assume	ds:tcb
	mov	[tcb28timer],0		; reset 28 timer to 0
	pushf				; call the isr (es:si -> tcbapvxx)
	call	dword ptr es:[si]
	pop	word ptr [tcbstkp]
	popset	ax,bx,cx,dx,si,ds,es
	ret
callisr endp 

	subttl fix_entlvl - fix the entry level for the lidt case
	page
;======================================================================
;,fs
; fix_entlvl - fix the entry level for the lidt case
;
; determines the entry level for the lidt case
;
; in:	al = 1
;
; out:	al = 1 for primary entry, al = 2 for secondary
;	crashes dx, es, di
;
;,fe
;======================================================================
	assume	ds:grp,es:nothing,ss:nothing
fix_entlvl proc near 
	xor	dx,dx
	mov	es,dx
	assume	es:nothing

; for lidt case, must determine the entry level by checking the
; 0:0 vector table entry against the default value

	test	[scbmmfea],04		; if using lidt
	jz	icm1
	mov	di,cs:[si].iqd_0ofs	; fetch 0:0 vector offset
	cmp	es:[di],offset lidtst_af  ; does 0:0 vector match stub?
	jne	icm0			; leave al = 2 if mismatch
	mov	dx,cs
	cmp	es:[di+2],dx		; check the segment
	je	icm1
icm0:
	inc	al			; set al = 2 to signal secondary entry
icm1:
	ret
fix_entlvl endp 

mosseg	ends
	end

