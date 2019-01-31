	include page.inc
	title	mosint16 - bios keyboard software interrupt
extrn bugerror:near
comment ^===============================================================
		development specification

 program name:	mos.com 		assigned to: jim bean
 module name:	mosint16		assign date: 09/30/86
 entry points:	mosint16		completed:   11/01/86
 entry from:	anywhere
 entry method:	int 16h
 calls: 	mosddtxx
 purpose:	handle any application calls for keyboard input in
		terms of the mosddtxx terminal drivers
 refer to:	mosddtxx
 last update:	08/18/1992
========================================================================

sah 05-22-87	disable pam switching if ega

sah 07-22-87	added extended int 16h calls to support compaq and
		ps/2 bios's
		function 10 - 12 converted into 00 - 02
		function 05 is now implemeted (keyboard write)
		all function except 00-02,05,10-12 pass to bios

jrb 07/16/87	add wkey bit to tcbstat if waiting for key

jsm 08/03/87	fix sah's logic to pass control to BIOS

jsm 08/04/87	fix pam switching from master console so that the
		master console's vidram is unmapped after refresh

jsm 08/10/87	fix pam switching into ega master console task so
		that only 16k of vidram are mapped into the video
		save area for copy.

sah 08/17/87	fix pam cursor type into cga/ega master console
		because setcursor consoler driver depends on the
		bios 40:049 for current mode. so current bios mode
		is saved during the set cursor type function and
		bios mode is set the screen to view.

mjs 9/2/87	fixed pamswitching to work from cga hires to mono when
		there is no memory manager.

mjs 9/4/87	pamswitching would sometimes cause a terminal to get
		extra video updates.  corrected by insuring that the
		proper video save and vidram areas were restored when
		pamswitching was exited.  also, added a flag to allow
		pamswitching to turn of vidram updates at selected times

sah 09/09/87	implemented vga state saving. uses special int 10h
		function 1ch to save and restore the state of the
		vga also will save and restore up to four planes
		(depending on video mode) of the vga.  vga tasks
		that are not view are suspended until waken up when
		some one else views it

sah 09/24/87	added support for saving and restoring the pallatte
		register during vgastate. new tcb var tcbegapal
		which is 17 byte array containing pallatte regs

sah 09/25/87	working version completed new procedures implemented
			vgastate - main code to switch video states
			vgamsrem - routine to unmap master video area
			vgamsmap - routine to map memory into master
				   video area
			vgamscpy - routine to copy video to/from
				   master video area
			testvid  - routine to test to see if we can pam
			doswitch - routine to switch in context without
				   video - necessary when working with
				   vga pallettes
			doi10  - routine to call vga bios

sah 09/25/87	support for sidekick is now supported. the secret to
		to achieving sk under mos was handling of the int 28
		interupt (if al is 0 and push on stack is sent to
		int 28, then sidekick and similar programs are ok to
		come up)  int 28 call was place in int 16 function 1
		because it seem to give best results.  finetunning
		the int 28h is most likely needed, but the concept
		should be same.  i use the status of tcbnest to
		indicate if sk can come up or not. please check
		mosint21 for addition information concerning of
		handling function 0ah and sidekick under mos
		special note: the additions for sidekick provide
		allow for better resident program support. i have
		found out that filefinder is now more compatible
		because of this changes

sah 09/29/87	multitasking ega support has been added. in this
		phase of the project mos now can use suspended
		ega multitasking support similar to vga but requires
		a 386 base machine and the overhead of io protection
		new procedures created:
		restoreega - to restore the state of the ega

mjs 10/01/87	modified int16, func 0 to call getkeys if suspend can
		not be re-entered due to intsl <> 0.   this should
		only happend when some idiot calls int 16, func 0
		from within an int8 intercept.
		also, modified the procedure tracechain to not rely
		on ss as an entry parameter. ds:si already points to
		the chain table which is in the tcb.   this was to
		allow tracechain to be called from mosint08 where ss
		can't be relied on.

sah 10/02/87	applied martin's changes to current source involving
		ega support.  also set bit 3 of tcbega before calling
		calling getkeys to indicated that ega\vga pamming is
		not ok.

sah 10/05/87	added code to testvid to test tcbpam for the mosadm
		switch command to disable pam switching.  this is for
		the needs of #9 video board plus security situations
		can also benifit.

sah 10/06/87	added generalize way of detecting ega or vga special
		vidram case added procedures: isega is currently added

sah 10/19/87	completed ega state saving for initial testing.
		provisions for 64k ega system (ibm ega)

jrb 10/22/87	various changes for hercules support (particularly
		hercules pages)

sah 10/25/87	ever continuing updates for ega multi-tasking support
		restoreega is critical routine so be carefull

sah 10/28/87	turn off io protection during pamswitching logic

sah 10/29/87	temporary additions to disable 43 line mode switching

jrb 10/29/87	changes for ali card

sah 11/09/87	changes to disable terminals from switching into ega
		tasks.	ega task will only be allow to run in the
		foreground (future enhancement will be necessary for
		ega tasks on terminal i.e. sunriver)

sah 11/10/87	allways restore ega pallettes after pamswitch routine
		this corrent the pallette problem on the ega when not
		not in vmode of ega.   non-vmode of ega pallettes are
		set during function 00 of int 10.

sah 11/17/87	correction for switch command so that it switches
		all view tasks

jrb 11/20/87	set low bit of [tcbdidkey] whenever int 16 function
		0 is called to flag keyboard activity for priority bumping

sah 11/20/87	corrections to setegapal for non-master console tasks
		with ega on master console

mjs 11/24/87	irma support.  at the entry to mosint16, where int28
		is being issued, must test for ss pointing to a tcb
		before modifying tcbstkp.  in getkeys logic, tcbmoskey
		is reset to zero just before calling tracechain for the
		int9 intercept.  tcbmoskey is used as a signal to show
		that irma's driver wants to register a pam switch.
		added code at getddka to handle this pam switching case
		and to update our internal shift state from 40:17.  in
		the tracechain procedure, must test for ss pointing to a
		tcb before modifying tcbstkp.  also, removed the setting
		of the flag at [si-1].	this was added last spring when
		i was trying to get sidekick up.  sidekick doesn't seem
		to need it and having it in place doesn't let irma nest
		into int8 as they need to do.

mjs 12/8/87	added logic after suspend call in fun 0 to determine if
		returned from suspend because an int28 needs to be
		issued.  if yes, call safe28 to gaurd mos's stack.
		added push/pop bx to decodescan - jsm found that
		mosint09 was crashing bx.

sah 12/09/87	corrected int 28 handling by pushing scbinmos value
		before	the int 28h call and poping scbinmos value after
		the call.
sah 12/09/87	corrections to setting ega pallettes if system has mono
		ega on the system (in this case don't set ega pallettes)

sah 12/18/87	added martins changes for passing int 16 to bios
		if unsupported function

sah 01/19/88	move references of scbseg and zero seg to macro and
		include group.inc
sah 01/25/88	replace scbseg reference with mo2seg reference

jrb 02/11/88	no vidram check unless at least on person is looking

mjs 2/16/88	remove int05 and int1b from chain table management
		scheme.  this was initiated as a means of gaining
		compatibility with mfcobol.

rbr/sah 02/20/88 move ddt code to mo2 group.

rbr 02/29/88	moving intsl, pamskip to grp.

sah 03/06/88	made changes for sk(+) "thanks to some insight from rod
		and techinical information which i have"   change
		how scbinmos works (should have 2 values only	0 = not
		busy,	1 = busy.

mjs 3/30/88	reworked pamswitching to allow serial irq's to occur
		during a pamswitch where the mosserirq will do a switch
		of video along with switching the task and context.
		this involved much cleanup, re-organization and updating
		of documentation.  there are still some holes - points
		in pamswitching where a video switching irq will not
		be handled properly - will get back to fixing these
		asap  (have to release the file for now).

sah 03/31/88	corrected change in ega handling (03/30/88) which cause
		mos to croke if vmode ega is used.

sah 04/06/88	updated ega\vga state switching for new video switching
		techniques (mjs 03/30/88)

sah 04/14/88	added vidcheck which is used to call external driver
		routine which so that driver will know when user wants
		to do a pam-switch.   this routine should return one of
		the following codes
			al = 0	 -   all ok continue with switch
			al = 1	 -   not now - try later
			al = 2	 -   can't do switching. don't try it.
		for more information on vidcheck routine see
		vidcheck.doc on the mosutils.dir on the r&d server.

mjs 5/2/88	corrected page count limit calcs in the proc mapvd2vs.
		fixed numerous spot in pamswitching relating to securing
		from irq's that switch video and vna pamswitching.

sah 05/20/88	change safe28 so that it does do a int 28 call unless
		tcbsafe28 is 'Y'.   see mosint21 for details on this
		remove 12/08/88 changes and place safe28 calls in
		mosddcon driver because resident applications will check
		if in int 16 (bios) by setting a internal flag and then
		when int 28 is call that flag will be set and app will
		not be able to come up.   inc and dec tcb28cnt (defined
		by 12/08/88 changes) during safe28 (do28) for control
		over the int 28 nesting levels.
		for detail information on the current resident support
		for mos see resident.doc in the utils.dir on the server

mjs 6/6/88	updated documentation in header of the scanguts proc
		so could send an extract of this code to peter avery.

mjs 7/2/88	took out mmparm struc and added 'inlude macros.inc' for
		access to the common mmparm struc.  added code just
		before the int28 is issued, in do28, to save scbnoswt
		and set it to 0.  scbnoswt is restored to its previous
		value upon return from the int28.

rdg 07/06/88	gated access to the console device drivers to prevent
		corruption of the serial data stream being sent to a
		terminal by changing the calls to the console device
		driver from a call dword ptr [si] to call ddtcallf

mjs 7/14/88	overhauled getkeys to work with new lidt control method
		for int9 intercepts.  also, cleaned out dead code.

sah 07/14/88	corrected ega and irma during a pamswitch. another case
		of where we should bias the stack. this was necessory
		because pamswitching logic sets the ega pallet in the
		the task which is not currently in memory.

mjs 7/22/88	corrected pamswitching problem introduced in the lidt
		int9 conversion process.

mjs 7/25/88	added regrab logic for int9 to the getddkeys procedure.

mjs 7/27/88	added logic so we can maintain pamswitching control
		even when there is a total int9 takeover.

mjs 8/1/88	changed preparation for calling an int9 intercept in
		getddkeys (callintr9) so that only int9's are masked
		off at the 8259 - not int8's.  Packet/PC counts on
		getting int8's while within their int9 handler.

mjs 8/9/88	corrected new pamswitching logic in getddkeys to test
		for an empty condition before eating the key out of
		the type ahead buffer.
		added inc/dec of scbinmos flag in the getkeys procedure
		to keep a tsr's int8 handler from popping up while
		the getkeys procedure is executing.

mjs 8/11/88	fixed oversight bug in last changes to getkeys.  there
		was an imbalance in calls to no/okswitch in some cases.

sah 09/23/88	turn on port 21h io protection while calling int 9
		intercept.  this corrected keyboard problem with
		ms-windows and keyboard excellerate on wordperfect 5.0
		mask out all interupts except int 28 during int 9 call

sah 09/24/88	change tcb28 variables
		tcb28cnt is int 28 nesting counter so that inmos flag
		will be set correctly
		tcb28timer is a efficiency timers, which counts 8 int
		28's before suspending for 6 ticks or keystroke.
		move int 28 efficiency logic inside mosint28 for windows

sah 09/28/88	if tcbtsrflg is 'Y', don't wait, this is an temporary
		solution for skplus using an undocument mos tsr command

sah 09/29/88	corrected oversight in pamswitching overhaul changes so
		certain critical sections of pamswitching code is skip
		is skip if in ega-state mode. remember that ega state
		does not have vidram like other modes.

sah 09/29/88	correct a condition where trying to switching to a
		a suspended task where it would let you.

sah 09/30/88	added checkvid procedure which will verify switch of
		consoles is compatible.  see comment at procedure.

sah 10/01/88	corrections for switch command lockups.

mjs 10/02/88	corrected bugs with bank selection logic and the end
		of pamswitching.  the task being pamm'ed away from
		wasn't always getting bank selected when it should have
		been.

sah 10/03/88	change checkvid to allowed mono hercules tasks

mjs 10/04/88	modify pamswitching to save the original bank selection
		state upon entry.  upon exit, if the ss->tcb is now in
		a con-only state then the original bank selection state
		is thrown away.  otherwise, the bank selection state
		is restored to what it was at the start of the
		pamswitch procedure.

sah 10/05/88	move int 28 handling into new module mosint28

sah 10/06/88	remove .pub dependency. remove mclook procedure which is
		not needed now.

sah 10/25/88	additional changes for new context and irq logic.  needs
		work in minimizing areas during pamswitching where
		interupts are disable

rdg 10/31/88	modifyied getddkeys to set tcbcamon when tcbcondd has
		reported that the terminal has disconnected.
		modified scanguts to return dx = 3 when a ctrl-alt-del
		is sent from the terminal
		added prs3 to prsscan to set tcbcamon when scanguts has
		detected a ctrl-alt-del (dx=3)

mjs 11/03/88	modify call to bias_stack to accomodate register dh as
		a new entry parameter.

mjs 11/11/88	fixed pamswitching in case where a serial terminal is
		being switched to watch a new task and the serial.sys
		output buffer fills before the video update can be
		completed.  put in logic to manipulate the video vars
		in the tcb so the non-standard mapping state of
		pamswitching will be restored.

mjs 11/14/88	added forcevsa variable so new pamswitching logic from
		11/11/88 can force switchgp to call swvidsave.

sah 11/18/88	corrections for ega pallettes which switching to
		terminals. also found a segment mishap from the days of
		doing ega pamswitching.

sah 11/21/88	corrections to setegapal if terminal is on system. also
		fix possiable problem with wrong registers being popped
		in moskey.
sah 11/22/88	corrections to above correction. must use terminals tcb
		not tcb of task going to.

mjs 11/30/88	modified moskey to ingore a pamswitching request when
		the current task's tcbsiorb flag is non-zero.  This
		prevents a pamswitch from occuring where the screen
		update would not be able to go through.

sah 12/03/88	corrections so that terminals can not switch into vmode
		of ega tasks.  i improved it by allowing checkvid to
		return false if task switch to is ega mode and station
		is not ega.

mjs 01/13/89	fixed a crash of the al register that resulted from my
		mods of 11/11/88.  the logic that was manipulating the
		video vars was crashing al when ddt, function 0ch
		needed it.  this was causing a blank screen when a vna
		workstation pam'ed into another in graphics mode.

sah 01/31/89	correction to disable logic if no console is viewing the
		task to only skip the actual testing of keyboard.

sah 02/03/89	converted use of scbvmaal = 0 to use scbbankin instead
		for compatibility with sunriver workstation driver
sah 02/06/89	corrections to checkvid to allow switching to a bg task
		which is in vmode of ega\vga and forground is not.

mjs 02/23/89	corrected a register trashing problem with the moskey
		subroutine.  this was causing a system crash when a
		certain combination of pamswitching was done.
		patches 300pfx25.pat, 300pfx05.pat and 300pfxev.pat
		were created to apply this change to release 3.00

sah 02/24/89	corrected handing of int 16 functions 10 - 12, in which
		al is e0 from return of function 10h and 00h if fun 00h
		for enhanced keyboards additional cursor keys. also it
		appears that ms word needs function 12 to return al=00
		for function 12 if key is enhanced.

mjs 03/03/89	corrected prsscan to use an ss override for the
		stack biasing operations done around the int5 and int1b
		calls.	this was causing a print screen to blow up
		when a background task had its lpt device redirected
		through lanlink.

sah 03/03/89	updated my 02/24/89 for compatibility with advanced
		revelation and also made corrections to vidcheck routine
		while working with sunriver\vna compatibilty.

rkg 03/09/89	handle int 15 func 4f, keyboard intercepts.  ptr 201
		call function before int 9 intercepts.

rdg 03/13/89	modified getddkeys so that it will record the fact that
		a terminal has disconnected when the terminal driver
		returns a carry from the inkbdata call.
		modified getdd3 so that when a task requires termination
		all watchers will be returned to their home task.
		modified prs3 to insure that a terminal user can reboot
		only his terminal task.
		modified mosky8t2 so that no console can pam switch to
		a task that is attempting to terminate.

mjs 05/12/89	modified pamswitching to only turn off interrupts for
		long periods if the flag scbswvq == 'Y'

mjs 05/16/89	the putkbf procedure was using the di register but not
		push/popping it.  this was causing the int9 intercept
		in qb.exe (ver 4.5) to crash.  ptr214.

mjs 05/17/89	modified the code in getddkeys which issues the int15
		function 4f call to skip the vector check and insure
		that the carry flag is set before the int15 call is
		issued.

rkg 05/24/89	corrected enhanced keyboard functions (10-12).	cleaned
		function code.	replaced scanguts from foreign driver
		code, implementing f11 & f12.

rkg 05/31/89	correct '|' and '@' for us keyboard. correct dis mode
		n.b. cannot call a far routine without pusing cs  n.b.

sah 06/02/89	improvements to ega\vga pamswitching for monochrome vga
		also incorporated mjs's CLICHK into EGA\VGA logic for
		mosadm virq command.

sah  06/08/89	skip mapvma calls if detected with sunriver task since
		sunriver is incharge of handle master console memory

mjs 06/19/89	add code to pamswitch to set the ega palettes if the
		tcbpalfg or tcbovsfg flags are set.  the data is kept
		in tcbegapal and is put there by mosint10

sah 06/26/89	corrections for tcbstation (monochrome ega\vga) which
		include rewrite - greatly simplified version of checkvid

sah 06/27/89	corrections for vmode of ega and vga on monochrome cards

sah\mjs  06/28/89 corrections for hercules

mjs 06/28/89	remove code added on 06/19/89 for setting the ega
		palettes.  the associated code added in mosint10 is
		still needed (to save data from int10fun10 calls in
		the tcbegapal table) but the setegapal procedure
		is already present in pamswitching to make the set
		palette call.

sah 06/29/89	it appears that monochrome vga and mjs's latest update
		doesnot work property with vmode of mono, investigating
		i found that mono chrome ega\vga does not have pallettes
		and unlike sitituation which mjs resolved above we don't
		need to worry about this sititution.
		corrected mos vmode mono vga (including cursor problem)
		when 1ch call is made we must switch in task so that
		bios data can ne update correctly.  also change all
		references to notsl to scbnotsl.

rkg 07/12/89	synchronize numlock on terminals.  synclock detects
		numlock errors when extended cursor keys are pressed
		add a terminal driver function to set/get terminal's
		keyboard status.

mjs 07/14/89	added the i10fun10 procedure.  when i/o trapping is
		available, this proc sets up trapping on port 03da
		and sets the palovr flag for the trapping logic to see.
		this is done to prevent a set palette call from keeping
		interrupts disabled so long that irq's are lost.
		also, backed out rkg's changes of 07/12/89 - they need
		more testing/debugging.
		also, changed the assume in the keyclasschk procedure
		per sah's findings (ds:tcb instead of ss).

mjs 07/28/89	added a test of the tcbnoget flag at the start of
		getkeys - for the hospec/quickbasic problem.

mjs 08/08/89	rewrite the prsscan, synclock and scanguts procedures.
		the existing synclock procedure didn't work and didn't
		even make logical sense.
		note: these changes were made in action chart format
		within mosint16.cht and then filtered to produce
		mosint16.asm.  mosint16.cht is on the first server
		volume in \mos.dir\cht.dir

mjs 08/14/89	modified the treatment of e0 prefix codes within
		int16fun00 so that a cntrl-c is not generated from
		keying alt-224	(which should generate a greek alpha)

mjs 08/15/89	fixed problem where two pcterm wks's are pamming a lot
		and system locks.  was due to design of getkeys loop.
		could end up tracing the wrong list of watchers since
		a pamswitch changes the list order.  added tcbwatch to
		enable getkeys to detect such a change in the list.

sah 09/01/89	added the capibility to disable reboot feature for a
		task using the mosadm reset command.

mjs 09/08/89	modified prsscan where it issues the int 5 for a shift
		print screen.  made this code temporarily reset the
		getkeys re-entrance control flag so that the spooler
		logic can pop up a spool error window and wait for a
		key without hanging in deadlock.

sah 09/25/89	corrections for 43 line pamswitching test, check tcbrows
		instead of bios, other test is not reliable and was
		cause problems with vga cards.

mjs 11/10/89	made the getddkeys routine test the key ready flag
		rather than polling the ddt unnecessarily.  this came
		up from a problem stargate was having in developing
		their new acl driver.

bwr 11/29/89	marked messages for foreign language translation.

sah 01/15/90	corrections for handle of non-numlock 5 keypad keys, f11
		and f12 keys.

sah 01/19/90	corrections for shift-print-screen and basic (eds). move
		code to call int 5 from prsscan to bottom of getkeys.
		with this fix, mjs correction on 09/08/89 is nolonger
		necessary since getkeys will never be re-entred.

sah 01/22/90	added calls to wordmove instead of rep movsw for faster
		speed on 386\486 cpu's

sah 03/09/90	corrections for moskey and vga graphics modes 11 and 12
		corrections for write protecting 40:17 additions

sah 03/15/90	corrections for pamming out of 43 line mode.

sah 03/20/90	replace code remove 3/09 for 40:17, needs more invest.

sah 03/30/90	corrections to setegapal for 40:63 being correctly set

bwr 04/16/90	correction for right-alt return to partition 0 problem.
		"Action chart" macros (xif) also removed from source.

mjs 04/17/90	added test to moskey to prevent pamswitching to a task
		suspended in extfun07 with no keyboard input active

mjs 04/19/90	had to remove moskey test (04/17/90).  was causing side
		effect where couldn't always pamswitch into a lanserve
		partition.

mjs 07/11/90	move isega and egaon/off to mosint06.  prepare for
		use of new set_trap routine.

mjs 07/17/90	modified the callintr9 function to work with the new
		keyboard rate control logic.

mjs 08/02/90	convert kbrate control to use set_kbrate.  this function
		calls the bios int16fun0305 instead of doing the i/o
		directly.  ami 33 mhz machines required this (or much
		more detailed direct i/o).

mjs 08/10/90	correct jump in synclock.  this was done just after the
		4.10 pre-release so a patch was made.

mjs 08/15/90	added calls to set_conly to pamswitch

mjs 09/16/90	modified scan code tables to prevent any
		keycodes from cntrl/grey -, cntrl/grey +, cntrl-5,
		alt-enter, alt/grey - and alt/grey +

bwr 09/17/90	tcbalt999 is now referenced in the task specific tcb
		instead of the workstation specific tcb in order that
		a running task may now manipulate this variable.  this
		also creates the desireable side-effect of setting the
		keyboards of any watchers to the task in and out of
		the alt-999 mode.

bwr 09/18/90	fixed erroneous assume statement.  was not causing any
		trouble ... yet.  the op-codes were being overidden
		correctly, but any references later on could be confused.

mjs 10/15/90	corrected scancode translation to properly support
		enhanced keyboards.  eds was finding that they could
		lock up a system by pressing certain keystrokes when
		a compiled basic program was running.
		made the fix16410.sys device driver to dynamically
		patch these fixes into the kernel.

sah 01/02/91	corrected and simplied setting of scbmconly, for correction
		for co-existence vna+, maxstation cursor problems....

mjs 01/07/91	added further qualification to the tests done within
		synclock.  when two arrow keys would be pressed togehter
		on an enhanced keyboard, an off pattern would be falsely
		detected.  ptr474.

sah 01/30/91	corrections so that if task is in disk busy suspension,
		user can not ega\vga pamswitch, because this will place
		mos into a state where disk logic will be block out
		until users switches back to the suspended task.

mjs 02/21/91	gutted and rewrote moskey and testvid to correct
		stalling and disk corruption problems which occured
		when mos vmo vga/ega is used while pamming between
		tasks doing disk i/o when dbts is being used.
		patch 33 provides this fix for 4.10 users.

		modified moskey to defer a pamswitch in many cases
		where it was dropping the keys in the bit bucket.

sah 03/08/91	correcttions for 40:17 logic, all read from 40:17
		come from actual bios location instead of tcb. also
		terminal function 1, now has a new feature of updating
		leds if cx=dx={40:17} this is only done if actually value at 
		40:17 is different from value in tcbcon417.  pamswitching
		also resets tcbcon417 to -1 so next time in getkeys, leds
		will be reset.
		
sah 03/28/91	corrections for kbbios=no, return mos gllobal to hanndling
		40:17 asm 4.10 handles it.  also made keyboard drivers 
		work with new 40:17 logic with out the need of changing
		the code in drivers.  this is done by making sure that
		tcbkshft has value at 40:17 loaded before calling keyboard
		driver.

sah 04/02/91	to gain furthor compatibility with existing terminal 
		drivers for 40:17 support, i set tcbkshft to value located
		at 40:17 when calling ddt function 1 in getddkeys

mjs 04/24/91	corrections to keyclasschk.  when a secured task's
		workstation pammed to an unsigned on task, they couldn't
		type!

sah 05/14/91	corrections for foxpro cursor problem (not actually 40:17
		problem after all).  made corrections so that scanguts 
		logic will skip shift states if e0 was last scan code.
		(patch410.sys has this correction).  also new for 4.11
		i corrected a potential problem with correctly reporting
		state of 40:96.		

sah 05/21/91	made improvements on my 06/14/91 fix for  foxpro so that
		it only skips shift handling if last scan was an e0 and
		we shift is call testing for left shift key.

mjs 05/24/91	corrected logic at the end of getkeys where the int5
		call is issued.  made it truly allow getkeys reentry
		by resetting the getkeys reentrance control flag before
		the int5 call is issued.  also made sure the int5
		flag is reset before the call is issued so reentrance
		doesn't bother recalling int5.

SAH 08/08/91	Not Allow EGA\VGA Pamswitching if mode is greater than
		mode 13h.  No real standards for these mode and we
		don't have enough EGA\VGA VIDRAM for switch.

mjs 10/07/91	fix dbts/prtsc bugs (patch410.118).
		modify the logic which issues the an int5 for a 
		shift-prtsc.  defer if the scbnoi5 flag is set.  this
		flag is set when the second call to getkeys is made
		from within tsl.  also, defer an int5 when the current
		task is within the bdb layer.

STARDATE 12/06/91 (SAH) Corrections for compucon's problem with
		pamswitching and alt 999, don't allow other task
		to switch into a task that does a alt 999.

mjs 01/22/92	modify scanguts handling of e0/e1 codes.  it was possible
		for a dx != 0 return value to occur when it shouldn't.
		this was causing a reboot on workstations when 
		<del><2> was keyed with a certain timing.

================ 5.01 Kernel Ends Here ====================================

mjs 05/22/92	modified the prtscr function and modified the scancode
		37h entry within the basetbl table to call prtscr
		just as in the shift-prtscrn case.  this solves the
		problems on the enhanced keyboard with pressing
		printscrn by itself (without a shift key).
		updat501.sys version 0.02

SAH 05/22/92    Corrections for Peter Horwood request to allow a workstation
		to pamswitch to itself so that it would refresh the screen
		on a serial terminal. remove the tcbid = task check.
		(Corrected in UPDAT501.SYS Version 1.01)

mjs 08/18/92	clean up segment declarations

mjs 08/26/92	delete reference to scbfree

=======================================================================^

.xlist
;	include mosint16.pub
	include mosregs.inc
	include group.inc
	include macros.inc

tcb	segment at 1234h
	include mostcb.inc
tcb	ends

gdata	segment
	include mosscbex.inc
gdata	ends
.list

gdata	segment

	extrn	cursynch:far, endchn9:byte, chain9:byte
	extrn	intsl:byte,pamskip:byte
	extrn	vdrskip:byte

public forcevsa
forcevsa db	'N'			; flag to allow pamswitching to force switchgp
					; to call swvidsave
public palovr
palovr	db	0			; flag to tell trapping code to set b3 on 3da reads

inmoskey db	0			; flag to control moskey re-entrance

gdata	ends

;-----------------------------------------------------------------------
; bits in al on wait (fn 87) call
;-----------------------------------------------------------------------

if	0 eq 0				;rod  fake out periscope
wkey	equ	1			; wait for keystroke
wtime	equ	2			; wait for timer ticks
wint	equ	4			; wait for hardware interrupt
wport	equ	8			; wait for char or status change on port(s)
wupoll	equ	80h			; wait, call user poll routine

f1	equ	59*256
f8	equ	66*256
f9	equ	67*256
f10	equ	68*256
fshift	equ	(84-59)*256
fctrl	equ	(94-59)*256
falt	equ	(104-59)*256

vstate	equ	7			; vgastate mask int 10h fun 1ch
					; hardware and color

numpad_lo equ	71			; lowest keycode from numeric pad
numpad_hi equ	83			; highest keycode from numeric pad

k_f1	equ	59			; function key 1
k_f2	equ	60			; function key 2

kbs_rshf equ	01h			; right shift pressed
kbs_lshf equ	02h			; left shift pressed
kbs_shf  equ	03h			; any shift key pressed
kbs_ctl  equ	04h			; ctrl key pressed
kbs_alt  equ	08h			; alt key pressed
kbs_scrl equ	10h			; scroll locked
kbs_num  equ	20h			; numpad locked
kbs_cap  equ	40h			; caps locked
kbs_ins  equ	80h			; insert state

kbc_e1	 equ	01h			; e1 prefix last
kbc_e0	 equ	02h			; e0 prefix last
kbc_rctl equ	04h			; right control key pressed
kbc_ralt equ	08h			; right alt key pressed
kbc_101  equ	10h			; 101/102 keyboard installed
kbc_us	 equ	20h			; us driver wanted
kbc_keyb equ   0c0h			; type of keyboard installed
					; 00 = default - extended
					; 40 = pc
					; 80 = at
					; c0 = extended
endif

	page
	subttl	irq segment - sepcify a system interrupt handler for mossaver
irq	segment
	extrn	i10old:dword

	dw	16h*4			; offset for this interrupt
public	i16old
i16old	dd	?			; save prior value
i16sav	dw	0			; we don't save changes, we leave them alone
i16new	dw	mos:mosint16		; initial value is here
i16new2 dw	0			; don't change back if application changes it

irq	ends

bios	segment at 40h			; define bios variables

	org	17h
ikbstat db	?			; keyboard status byte
	org	1ah
ikbhead dw	?			; keyboard queue head pointer
ikbtail dw	?			; 40:1c tail pointer
ikbbuff dw	10 dup (?)
	org	49h
crtmode db	?			; crt display mode
	org	65h
crtregs label	word
crt3x8	db	?			; current value of 3x8 register
crt3x9	db	?
	org	84h
crtrows db	?			; number of lines on display
bios	ends

;======================================================== mos segment
if 0 eq 0
segment_num = 1
endif
mosseg	segment
	assume	cs:mos,ds:grp,es:nothing,ss:tcb
$$$int16 label	byte

	extrn	mosend:byte, mo2seg:word, sbios:word
	extrn	mossaver:near, mosrestore:near, vidram1a:near, set_trap:near
	extrn	timparm:near, timchk:near, swrealram:near, egaoff:near
	extrn	suspend:near, classbits:near, swvidram:near, nosbuf:far
	extrn	noswitch:near, okswitch:near, swvidsave:near, bias_stack:near
	extrn	initioptbl:near, mapvsa:near, ddtcallf:near, switchtask:near
	extrn	lidtstub9:near, mosint09:near, mapvma:near, wordmove:near
	extrn	set_conly:near

	public	mosint16, getkeys, decodescan, kbpoll00, kbpoll01, scanguts
	public csynch,ctrltbl,alttbl,set_kbrate,i10fun10,setegapal

	assume	ds:nothing,es:nothing,ss:nothing

	subttl
	page
;======================================================================
;,fs
; csynch
;
; far call to mosint10 in mo2 in order to synchronize all
; terminal cursors with the partition's logical cursor
;
; in:
;
; out:
;
;,fe
;======================================================================
csynch proc far
	push	[mo2seg]
	mov	ax,offset mo2:cursynch
	push	ax
	retf
csynch endp

	subttl m16quik - attempt quick status call if no key
	page
;======================================================================
;,fs
; m16quik - attempt quick status call if no key
;
; in:	
;
; out:	
;
;,fe
;======================================================================
	assume	ds:tcb, es:grp
m16quik proc far
	test	[tcbloop],1		; is disable mode set ?
	jnz	m16_slow		; if yes, can't handle with fast code
	mov	dx,bios
	mov	es,dx
	assume	es:bios
	mov	bx,[ikbhead]		; any keys ready that are already buffered?
	cmp	bx,[ikbtail]
	jne	m16_slow		; yes, must return key
	inc	[tcbkbfct]		; incr fast status counter
	mov	dl,[tcbkbfct]		; get fast func 1 counter
	cmp	dl,[tcbkbfst]		; time to do a slow int 16?
	jae	m16slooow		; it's time to check vidram, etc. slooowww
	mov	dx,[tcbscrdd]		; get first watcher in chain
	jmp	short m16quikent
m16quiklup:
	or	dx,dx			; if no watcher, return with zr flag
	jz	m16quikxit
	mov	es,dx			; any chars from watching task?
	assume	es:tcb,ds:nothing
	mov	dx, [tcbnxtdd]		; get next in chain
m16quikent:
	les	bx,[tcbkeyrdy]
	assume	es:nothing
	test	byte ptr es:[bx], 0ffh
	jz	m16quiklup		; loop for all watching tasks
m16_slow:
	jmp	m16slow
m16quikxit:
	pop	ds			; zr flag set by
	pop	es
	pop	bx
	pop	dx
	retf	2			; return using these flags
m16quik endp

	subttl	mosint16 - emulate pc bios keyboard functions
	page
;======================================================================
;,fs
; mosint16 - emulate pc bios keyboard functions
;
; in:	per bios spec
;
; out:	per bios spec
;
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:nothing
mosint16 proc far
	sti
	push	dx
	push	bx
	push	es
	push	ds
	mgetscb es
	assume	es:grp
	mov	ds,[scbtcbpc]
	assume	ds:tcb
	cmp	ah, 1			; if function 1, attempt to speed function
	jmpe	m16quik
	cmp	ah,11h
	jmpe	m16quik
m16slow:
	mov	[tcbfsavr],'Y'		; set the short form flag for mossaver
m16slooow:				; here for the long form of mossaver
	mov	[tcbkbfct], 0		; clear fast status function counter
	mgetscb es
	assume	es:grp			; regain scb
	cmp	ah, 2			; check to see valid function
	jbe	m16save
	cmp	ah, 5
	je	m16save
	cmp	ah,10h
	jb	m16bios 		; otherwise let bios handle it
	cmp	ah,12h
	jb	m16save

; not a standard int 16h function - pass to bios

m16bios:
	push	bp
	mov	bp,sp			; pointer to stuff in stack

; [bp]	 = bp
; [bp+2] = ds
; [bp+4] = es
; [bp+6] = bx
; [bp+8] = dx

	mov	bx,word ptr [i16old]	; offset to receive control
	mov	dx,word ptr [i16old+2]	; segment to receive control
	xchg	bx,[bp+6]		; swap segment w/saved bx
	xchg	dx,[bp+8]		; swap offset w/saved ax
	pop	bp
	pop	ds
	pop	es
	retf				; return to bios which returns to user
m16save:
	pop	ds
	pop	es			; restore registers for mossaver
	pop	bx
	pop	dx
	call	mossaver
	mov	ax, ss
	mov	ds, ax
	assume	ds:tcb,es:nothing,ss:tcb
	mov	[tcbfsavr],'N'		; reset short form flag for mossaver
	mov	ah,[tah]
	and	ah, 7			; strip to function type
	cmp	ah, 1
	jb	m16f0
	jmpe	m16f1			; dispatch to correct routine
	cmp	ah,5			; function 5 write keyboard
	jmpe	m16f5
	jmp	m16f2
m16exit:
	call	mosrestore
	iret
mosint16 endp

	subttl m16f0 - return next key in ax
	page
;=======================================================================
;,fs
; m16f0 - return next key in ax
;
; wait for key pressed, suspending task each time there isn't
; a key ready
;
; in:
;
; out:
;
;,fe
;======================================================================
m16f0s proc near
	call	suspend 		; wait for key

; call getkeys here to improve key to display response. this was made 
; necessary when tsl was modified so that getkeys was called just
; before a task is to be switched out rather than just after
; (02/91, mjs, patch33)

	or	[tcbega],2		; sah indicate ega\vga not ok
	call	getkeys
m16f0:
	mov	ax, bios
	mov	es, ax
	assume	es:bios
	or	[tcbdidkey],01h 	;#jrbg flag get key called this slice
	mov	si,[ikbhead]		; if head = tail, then there's no key yet
	cmp	si,[ikbtail]
	jne	m16f0k			; jump if key available
	mov	word ptr [tcbpoll],offset mos:kbpoll00	; key input wait
	mov	word ptr [tcbpoll+2],cs
	and	[tcbwait],not 06h	; clear bits 2,1
	or	[tcbwait],01h		; set bit 0
	or	[tcbstat],wkey		;jrb signal waiting for key
	push	ds
	mgetscb ds
	assume	ds:grp
	cmp	[intsl],0
	pop	ds
	assume	ds:tcb
	je	m16f0s			; not in task selection - wait for a key
	push	cs
	call	near ptr csynch 	; physical cursor synch on each terminal
	or	[tcbega],2		; sah indicated ega\vga not ok
	call	getkeys
	jmp	m16f0			; loop until a key appears in buffer??
m16f0k:
	mov	[tcbkbcnt],0		; put off dis mode when get a key
	mov	dx,[tcbibase]
	add	dx,[tcbibsiz]
	dec	dx
	mov	si,[ikbhead]		; if head = tail, then there's no key yet
	lods	ikbbuff
	cmp	si,dx
	jb	m16f0ta 		; wrap to begining on overflow
	mov	si,[tcbibase]
m16f0ta:
	mov	[ikbhead],si
	cmp	[tah],10h
	jne	m16f0tb
	cmp	al,0f0h
	jne	m16f0tx
	xor	al,al
	jmp	short m16f0tx
m16f0tb:
	call	do_exceptns
	jnz	m16f0tx
	cmp	ah,84h
	lja	m16f0
	cmp	al,0f0h
	lje	m16f0
	cmp	ax,1c00h		; discard alt-enter (non-numpad enter)
	lje	m16f0
	cmp	al,0e0h
	jne	m16f0tx
	xor	al,al
m16f0tx:
	mov	[tax],ax
	jmp	m16exit
m16f0s endp

	subttl do_exceptns - process enhanced kybd exception cases
	page
;======================================================================
;,fs
; do_exceptns - process enhanced kybd exception cases
;
; test for and handle scancode/keycode translation cases such
; as pad-slash and pad-enter.  do the translation required
; when int16fun00 or 01 is used with an enhanced keyboard.
;
; in:	ax = scancode/keycode
;
; out:	zr flag
;	  ax = unprocessed scancode/keycode
;	nz flag
;	  ax = processed scancode/keycode
;
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:nothing
do_exceptns proc near
	cmp	ax,00e0h
	je	doex4
	cmp	ax,00f0h
	je	doex4
	cmp	ax,0e00dh
	jne	doex1
	mov	ax,1c0dh
	jmp	short doex4
doex1:
	cmp	ax,0e00ah
	jne	doex2
	mov	ax,1c0ah
	jmp	short doex4
doex2:
	cmp	ax,0e02fh
	jne	doex3
	mov	ax,352fh
	jmp	short doex4
doex3:
	cmp	ax,ax			; set zr flag - ax not processed
	jmp	short doex5
doex4:
	push	ax
	xor	ax,ax
	cmp	ax,1			; set nz flag - ax processed
	pop	ax
doex5:
	ret
do_exceptns endp

	subttl m16f1 - return key status in z flag
	page
;======================================================================
;,fs
; m16f1 - return key status in z flag
;
; if nz, non-destructively return key in ax.
; wordstar rel 4 requires that the interrupt flag be set in a fun 01.
;
; restore interrupts on return and default no key ready
;
; in:
;
; out:
;
;,fe
;======================================================================
	assume	ds:tcb,es:nothing,ss:nothing
m16f1 proc near
	or	[tflag],interrupt or zero
	mov	ax, bios
	mov	es,ax
	assume	es:bios
	mov	si,[ikbhead]		; any keys ready?
	cmp	si,[ikbtail]
	jne	m16f1s			; yes, so return key and ready status
	push	cs
	call	near ptr csynch 	; physical cursor sync on each terminal
	test	[tcbloop],1		; is disable mode set ?
	ljz	m16f1x			; no, its not so just exit
	inc	[tcbkbcnt]		; advance disable counter
	mov	al,[tcbkbmax]
	cmp	al,[tcbkbcnt]		; maxed out yet?
	ja	m16f1x			; not yet so exit normally
	mov	ax,ss			; get tcb for timparm
	mov	es,ax
	mov	cl,4			; bit position in tcbwtflg for wrap flag
	mov	ax,[tcbkbtck]
	call	timparm 		; setup time out data
	mov	[tcbkbax],ax
	mov	[tcbkbcx],cx
	mov	word ptr [tcbpoll],offset mos:kbpoll01	; looper wait
	mov	word ptr [tcbpoll+2],cs
	and	[tcbwait],not 06h	; clear bits 2,1
	or	[tcbwait],01h		; set bit 0
	or	[tcbstat],wkey		;jrb signal waiting for key
	call	suspend
	jmp	m16f1

; character is ready return status and key codes

m16f1s:
	lods	ikbbuff
	cmp	[tah],1
	je	m16f1a
	cmp	al,0f0h
	jne	m16f1w
	xor	al,al
	jmp	short m16f1w
m16f1a:
	call	do_exceptns
	jnz	m16f1w
	cmp	ax,1c00h		; discard alt-enter (non-numpad enter)
	je	m16f1b
	cmp	ah,84h
	ja	m16f1b
	cmp	al,0f0h
	jne	m16f1c
m16f1b:
	mov	dx,[tcbibase]
	add	dx,[tcbibsiz]
	dec	dx
	cmp	si,dx
	jb	m16f1d			; wrap to begining on overflow
	mov	si,[tcbibase]
m16f1d:
	mov	[ikbhead],si
	jmp	m16f1
m16f1c:
	cmp	al,0e0h
	jne	m16f1w
	xor	al,al
m16f1w:
	mov	[tax],ax		; store keycodes for restore to pop
	and	[tflag],not zero	; setup return status
m16f1x:
	jmp	m16exit
m16f1 endp

	subttl m16f2 - return shift status in al
	page
;======================================================================
;,fs
; m16f2 - return shift status in al
;
; in:
;
; out:
;
;,fe
;======================================================================
	assume	ds:tcb,es:nothing,ss:tcb
m16f2 proc near
	mov	ax,bios
	mov	es,ax			; rom bios ram
	assume	es:bios
	mov	al,[ikbstat]		; to return partition's toggle state
	xor	ah, ah
	test	[tah], 10h		; extended function call
	jz	m16f2x
	mov	ah, [tcbktggl]		; get toggle states
m16f2x:
	mov	[tax],ax
	jmp	m16exit
m16f2 endp

	subttl m16f5 - keyboard write
	page
;======================================================================
;,fs
; m16f5 - keyboard write
;
; in:
;
; out:
;
;,fe
;======================================================================
	assume	ds:tcb,es:nothing,ss:tcb
m16f5 proc near
	mov	ax, ss
	mov	ds, ax			; get tcb everywhere
	mov	es, ax
	assume	ds:nothing,es:tcb,ss:nothing
	mov	al,[tcbi9flg]
	push	ax
	mov	[tcbi9flg], 0ffh	; not from int 09
	mov	ax,[tcx]
	call	putkbf			; place key in buffer
	pop	ax
	mov	[tcbi9flg],al
	mov	al, 0			; default to key inserted status
	jne	m16f5x
	mov	al,1			; indicate buffer full
m16f5x:
	mov	[tal], al
	jmp	m16exit
m16f5 endp

	subttl	kbpoll00 - keyboard poller for mos task selection logic
	page
;======================================================================
;,fs
; kbpoll00 - keyboard poller for mos task selection logic
;
; poll all the keyboards for this partition
; the object is for the unsucessful case to be executed
; as quickly as possible
;
; in:
;
; out:
;
;,fe
;======================================================================
	assume	ds:grp,es:nothing,ss:tcb; from dopoll
kbpoll00 proc	far
kbpoll00n label near
	mov	cx, [tcbscrdd]		; tcb of first watcher
	mov	dx, ds			; save seg
kbpoll0l:
	jcxz	kbpoll0x		; exit if no watcher
	mov	ds, cx
	assume	ds:tcb			; get tcb of watcher
	mov	cx, [tcbnxtdd]		; segment of next watcher
	lds	di, [tcbkeyrdy] 	; pointer to keys waiting
	cmp	byte ptr [di], 0
	jz	kbpoll0l		; loop until no watcher or key found
kbpoll0w:				; wake up task
	mov	ds, dx			; restore seg
	assume	ds:grp
	and	[tcbwait],not 07h
	xor	ax, ax			; some key ready - flag runnable
	mov	word ptr [tcbpoll], ax
	mov	word ptr [tcbpoll+2], ax
	ret
kbpoll0x:
	mov	ds, dx			; restore seg
	mov	al, 1			; exit still waiting
	ret
kbpoll00 endp

	subttl	kbpoll01 - keyboard poller for mos task selection logic
	page
;======================================================================
;,fs
; kbpoll01 - keyboard poller for mos task selection logic
;
; see if any keys are ready for this task - or if a time out occurs
; we want to give this task another bit of time
;
; in:
;
; out:
;
;,fe
;======================================================================
	assume	ds:grp,es:nothing,ss:tcb; from dopoll
kbpoll01 proc	far
	push	cs
	call	kbpoll00n		; check any keys waiting
	or	al, al			; test key ready
	jz	kbpoll1x		; key ready exit
kbpoll1t:				; no key ready test timeout
	mov	ax, ss			; get tcb into es for timchk
	mov	es, ax
	mov	ax,[tcbkbax]		; check for time out
	mov	cx,[tcbkbcx]
	call	timchk
	mov	al, 6			; get status if still waiting
	jnz	kbpoll1x		; jmp if not timed out yet
	mov	[tcbkbcnt],0		; reset counter
	jmp	kbpoll0w		; wake up task
kbpoll1x:
	ret
kbpoll01 endp

	subttl getmastv - get the address of the master video save area
	page
;======================================================================
;,fs
; getmastv - get the address of the master video save area
;
; in:
;
; out:
;
;,fe
;======================================================================
getmastv proc near
	push	ds
	mgetscb ds
	assume	ds:grp
	mov	ax,[scbmastv]
	pop	ds
	assume	ds:nothing
	ret
getmastv endp

	subttl	getkeys - get keys from any terminals looking at partition
	page
;======================================================================
;,fs
; getkeys - get keys from any terminals looking at partition
;
; read all scan codes from all partitions whose
; terminals are looking at this application, storing them
; as key values in this application's input buffer
;
; in:
;
; out:
;
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:tcb
getkeys proc near

; this flag, tcbnoget, is usually always 0.  when the qbfix.com tsr is
; used to make up for sloppy programming within quickbasic, this flag
; is set by the tsr to defer the processing of int9 intercepts during
; a critical period.  this problem was found in conjunction with the
; hospec package.  martin stitt 07/28/89

	cmp	[tcbnoget],0
	je	getx
	ret
getx:
	push	ax
	push	bx
	push	cx
	push	dx
	push	si
	push	di
	push	ds
	push	es
	push	bp
	mgetscb ds
	assume	ds:grp			; prevent a tsr's int8 intercept from popping
	inc	[scbinmos]		; up while getkeys is executing
	cli
	test	[tcbbrkfg],8		; getkeys could be called from more than one
	jnz	getoutx 		; place per task, but can only allow one entry
	or	[tcbbrkfg],8		; at a time (per task).
	sti
getk0a:
	mov	ax,ss
	mov	ds,ax
	assume	ds:tcb,ss:nothing,es:nothing
	mov	ax,[tcbscrdd]
getky1:
	or	ax,ax
	jz	getky2			; e if no other terminals looking at ap
	mov	ds,ax			; else get the keys from the first
	call	getddkeys

; if the wks is not still watching the ss task, a pamswitch has
; re-ordered the watcher list so start over.

	cmp	[tcbwatch],0		; this test is to keep from stalling when
	je	getk0b			; getkeys is called before the foreground
	mov	ax,ss			; goes through mositask (where tcbwatch is set)
	cmp	ax,[tcbwatch]
	jne	getk0a
getk0b:
	mov	ax,[tcbnxtdd]
	jmp	getky1
getky2:

; move passing to int 5 to end of getkeys, because i found a problem
; with ibm basic compiler 2.00 application which ended up calling
; performing int 5 inside of int 9 intercepted which cause app to
; lock up on a 386 with io protection.
; stewart hyde 01/19/90

	assume	ds:nothing,ss:tcb
	and	[tcbbrkfg],not 8	; clear getkeys re-entrance flag
	mgetscb ds
	assume	ds:grp

; when getkeys is called on the way out of tsl, must defer any int5
; calls because spooler file i/o could cause re-entrance into the
; disk logic.

	cmp	[scbnoi5],0
	jne	getoutx

; whenever the current task is inside the bdb gate, must defer any
; int5 calls to prevent re-entrance.

	cmp	[scbbdbbsy],0
	je	gt1
	mov	ax,ss
	cmp	ax,[scbbsytcb]
	je	getoutx
gt1:

; finally, see if an int5 is pending

	test	[tcbbrkfg],80h
	jz	getoutx
	and	[tcbbrkfg],not 80h
	push	[tcbstkp]
	mov	[tcbstkp],sp
	sub	[tcbstkp],128
	int	5
	pop	[tcbstkp]
getoutx:
	sti
	mgetscb ds
	assume	ds:grp
	dec	[scbinmos]
	pop	bp
	pop	es
	pop	ds
	pop	di
	pop	si
	pop	dx
	pop	cx
	pop	bx
	pop	ax
	ret
getkeys endp

	subttl getddkeys - get all scan codes from one partition
	page
;======================================================================
;,fs
; getddkeys - get all scan codes from one partition
;
; get all scan codes from one partition, call any int9
; intercepts and process pamswitching codes
; most regs crashed
;
; in:	ds -> tcb of console being processed
;
; out:
;
;,fe
;======================================================================
	assume	cs:mos, ds:tcb, es:nothing, ss:nothing
getddkeys proc near
	push	dx
	push	es			; let's be smart and check the
	push	bx
	MGetSCB es
	assume  es:grp
	cmp	[scbkbbios],'N'		; is KBBIOS=NO
	jne	contgetdd

; if kbbios=no, then make use valuse tcbkbshft

	les	bx,[tcbkeyrdy]		; ddt has any scan codes available.
	assume	es:nothing
	cmp	byte ptr es:[bx],0
	mov	dl,[tcbkshft]
	jmp	short contgetdd2
contgetdd:
	les	bx,[tcbkeyrdy]		; ddt has any scan codes available.
	cmp	byte ptr es:[bx],0
	mov	bx,bios
	mov	es,bx
	assume  es:bios
	mov	dl,byte ptr es:[ikbstat]
	mov	[tcbkshft],dl
contgetdd2:
	assume	es:nothing
	pop	bx
	pushf
	and	dl,070h
	popf
	jnz	getdd0a

; Now we must check to see if stations copy of 40:17 is the same as
; what currently located in BIOS, if value at 40:17 is the same as
; value of TCBCON417 then we will skip the calls to terminal driver

	cmp	dl,[tcbcon417]
	jne	getdd0a
	pop	es
	pop	dx
	jmp	short getdd1 
getdd0a:
	mov	[tcbcon417],dl
	pop	es
	mov	ah,1			; get a keyboard char (inkbdata)
	mov	si,offset [tcbcondd]	; get the console driver address
	push	cx
	mov	dh,-1			; always force this to 0ffh
	mov	cx,dx			; cx must equal dx
	call	ddtcallf		; use the driver gate mechanism
	pop	cx
	pop	dx			
	jnc	getdd0			; jump if terminal connected
	cmp	[tcbreboot],0ffh	; have we request to disable reboot
	je	getdd0			; if so skip the handling of reboot
	cmp	[tcbcamon],0		; have we reported the disconnec
	jne	getdd0			; jump if already reported
	mov	[tcbcamon],0ffh	; set the task for a restart
	push	es			; save the callers es
	mgetscb es			; get the scb pointer
	assume	ds:tcb,es:grp,ss:nothing
	inc	[scbrstrtc]		; bump the count waiting restart
	pop	es			; restore es
	assume	ds:tcb,es:nothing,ss:nothing
getdd0:
	or	al,al
	jnz	getdd4			; z if no more

; when all done gathering scan codes, test for a switch command

getdd1:
	assume	ds:nothing,ss:tcb
	cmp	[tcbswflg],'Y'		; is switch flag set
	jne	getdd3
	push	ds
	cmp	[tcbscrdd],0		; is screen being view
	je	getdd2			; no..all done
	mov	ds,[tcbscrdd]
	mov	al,[tcbswitch]
	call	moskey			; do the pam-switch
getdd2:
	pop	ds

; at this point, if the terminal is not veiwing its home task and the
; tcbcamon flag is set in either the current task or the terminal's
; task, call moskey to switch this console home.  this is done in
; preparation for a task restart.

getdd3:
	mov	ax,ds
	mov	bx,ss
	cmp	ax,bx
	je	getdd3a
	mov	al,[tcbcamon]
	or	al,ds:[tcbcamon]
	jz	getdd3a
	mov	ax,ds:[tcbid]
	call	moskey
getdd3a:
	jmp	getddx

; see if the scan code is a window repaint command (ttterm, etc.)

getdd4:
	assume	ds:tcb,ss:nothing
	cmp	al,0feh
	jb	getdd5
	not	al
	mov	[tcbwinpo],al
	mov	ah,0ch			; set-window call to re-display window
	mov	si,offset [tcbcondd]
	assume	ds:nothing,ss:tcb
	mov	[si+4],ax		; save window position and ddt function code
	mov	ax,[tcbvidw2]
	mov	[si+6],ax		; screen buffer
	xor	ax,ax
	mov	word ptr [si+8],ax	; offset 0 in page
	mov	ah,[tcbcols]		; cols/row
	mov	[si+10],ah
	mov	cx,[tcbpgln]
	shr	cx,1
	mov	ax,[tcbpgst]		; offset of active page
	xchg	ax,[si+4]		; also restoring saved ax
	push	es
	call	ddtcallf		; check if busy and then call	; rg8188
	pop	es
	jmp	getdd12

; see if there are any int9 intercepts.  if there are, will need to
; give them a call with this scan code made available via trapping.

getdd5:
	stc				; must start out with cy
	mov	ah,4fh 			; execute int 15 keyboard intercept
	int	15h
	jmpnc	getdd12 		; ignore if absorbed
	mov	[tcbtrapcd],al		; store scan code in the task's TCB
	mov	ax,ss
	mov	es,ax
	call	keyclasschk		; for mosint09 and the call to moskey
	jb	getdd9
	mgetscb es
	assume	es:grp
	test	[scbmmfea],04h		; is the lidt scheme supported?
	jz	getdd7
	mgetzero es
	assume	es:nothing
	cli
	cmp	word ptr es:[9*4],offset lidtstub9
	jne	getdd8
	mov	ax,cs
	cmp	ax,es:[9*4+2]		; in the lidt case, if the 0:9*4 vector
	jne	getdd8			; isn't pointing to lidtstub9 then
	sti				; one or more intercepts exist
	jmp	getdd9
getdd7:
	cmp	[tcbnest9],0		; for regrab case, check the nest count
	je	getdd9
getdd8:
	sti
	mgetscb es
	assume	es:grp
	call	noswitch
	mov	byte ptr [endchn9],0	; reset end of chain flag
	call	callintr9		; give the intercept a call

; if the intercept is a total int9 takeover, endchn9 will not be 1.  in
; this case, we cannot test [tcbi9flg] for a return value since the
; call to decodescan (in mosint09's end of chain handler) was never made.

	cmp	byte ptr [endchn9],1
	pushf				; leave switching disabled until after the
	call	okswitch		; flag test since its a global flag
	popf
	jne	getdd11
	cmp	[tcbi9flg],0		; when decodescan was called from mosint09,
	je	helpdd12		; was a pamswitch signal reported?
	jmp	getdd10

; when there are no int9 intercepts, enter here to decode the scan code.

getdd9:
	mov	al,[tcbtrapcd]		; recover the scan code
	push	es
	push	ss
	pop	es			; decodescan must see the task's tcb in es
	call	decodescan		; (done to accommodate the int9 handler)
	pop	es
	or	al,al
	jz	helpdd12

; pamswitching via alt-num pad entries is handled here.

getdd10:
	assume	ds:tcb,ss:nothing
	mov	al,[tcbmoskey]		; recover the scan code
getdd10a:
	call	moskey
	mov	ax,0280h		; else clear it out of driver buffer
	mov	si,offset [tcbcondd]	; and get out (ss is no longer the
	call	ddtcallf		; check if busy and then call	; rg8188
	jmp	getddx

helpdd12:
	jmp	getdd12

; in the case of a total int9 takeover, we must maintain our internal shift
; state variable and check for pamswitching scan codes

; note: packet/pc quirks
;
; when packet is loaded with the line pkt3270 /ry /sd these fine folks have
; installed an int9 handler that sometimes calls the previous int9 vector
; and sometimes doesn't.  For most normal keystrokes, they're calling the
; previous vector; for the shift keys (cntrl, shift, alt) they're just
; updating 40:17 and not calling the previous int9 handler.  this means that
; the logic in scanguts will assemble an alt-num pad entry but will never
; use it since the logic below is the only place where the break scan code
; of the alt key is detected.  to support pamswitching in this case, i've
; added a special purpose test of the alt-num pad accumulator that the
; scanguts logic uses.

getdd11:
	mov	ax,bios
	mov	es,ax
	assume	ds:nothing,es:bios,ss:tcb
	mov	al,[tcbtrapcd]		; recover the scan code
	cmp	al,38h			; is it a make of the alt key?
	jne	getdd11a
	assume	ds:tcb,ss:nothing
	mov	[tcbaltdn],1		; if yes, set a private shift flag
	mov	word ptr [tcbaltnum],0	; packet/pc quirks  (see notes above)
	jmp	getdd12
getdd11a:
	cmp	al,0b8h 		; is it a break of the alt key?
	jne	getdd11b
	mov	[tcbaltdn],0
	cmp	[tcbaltacf],1		; is anything accumlated?
	je	getdd11h
	cmp	word ptr [tcbaltnum],0	; packet/pc quirks  (see notes above)
	jz	helpdd12
	mov	al,[tcbaltnum]
	mov	word ptr [tcbaltnum],0
	jmp	getdd11g
getdd11h:
	mov	al,[tcbaltac]		; if yes, setup for call to moskey
	mov	[tcbaltac],0
	mov	[tcbaltacf],0
getdd11g:
	assume	ds:nothing,ss:tcb
	cmp	[tcbalt999],0
	assume	ds:tcb,ss:nothing
	je	getdd12 		; skip moskey call when alt999 toggled off

; if the app's int9 handler has responded to the alt-num pad entry by
; generating a code, we must eat it out, or we'll end up with extra happy
; faces in the partition we're pamming away from

	push	ax
	push	bx
	mov	ax,[ikbhead]		; if head == tail, then there's no key yet
	cmp	ax,[ikbtail]
	je	getdd11e
	mov	ax,[tcbibase]		; if tail pointer is at the base, the must
	cmp	[ikbtail],ax		; do a backwards wrap to check last code
	je	getdd11d
	mov	bx,[ikbtail]
	sub	bx,2			; else just backup one word
getdd11f:
	mov	ax,es:[bx]
	or	ah,ah			; from numpad?
	jnz	getdd11e
	mov	[ikbtail],bx		; yes, modify the tail pointer to delete
	jmp	getdd11e
getdd11d:
	add	ax,[tcbibsiz]
	dec	ax			; do the backwards wrap
	mov	bx,ax
	jmp	getdd11f
getdd11e:
	pop	bx
	pop	ax
	jmp	getdd10a		; use above logic to finish up

; when the alt key is down and a numpad key is pressed, multiply the
; current accumulator (tcbaltac, not the ax register) contents by 10
; and add in the new value

getdd11b:
	cmp	[tcbaltdn],1
	jne	getdd12
	call	chknumset		; test for al in numpad set
	jne	getdd12 		; if zr, al is new value for accumulator
	mov	ah,[tcbaltac]
	cmp	ax,99*256+9		; alt 999 ?
	je	getdd11c
	push	bx
	mov	bl,ah
	add	ah,ah
	add	ah,ah
	add	ah,bl			; accumulator *= 10
	pop	bx
	add	ah,ah
	add	al,ah			; accumulator += new number
	mov	[tcbaltac],al		; remember till alt key released
	mov	[tcbaltacf],1		; set accum flag - to show we've got something
	jmp	getdd12
getdd11c:
	assume	ds:nothing,ss:tcb
	xor	[tcbalt999],0ffh	; toggle alt999 flag
	assume	ds:tcb,ss:nothing
	mov	[tcbaltac],0
	mov	[tcbaltacf],0

; clear the scan code out of the driver's buffer

getdd12:
	mov	ax,0280h
	mov	si,offset [tcbcondd]
	call	ddtcallf		; check if busy and then call	; rg8188
	jmp	getddkeys
getddx:
	ret
getddkeys endp

numpadset db	82,79,80,81,75,76,77,71,72,73

	subttl chknumset - determine if a scan code is from the num pad
	page
;======================================================================
;,fs
; chknumset - determine if a scan code is from the num pad
;
; chknumset - determine if a scan code is from the num pad.
; if it is, return a zr and the corresponding value, 0-9,
; in al; else return nz.
;
; in:	al = scan code
;
; out:	if num pad key, al = num pad key value and zr
;	else nz
;
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:nothing
chknumset proc near
	push	cx
	push	di
	push	es
	mov	di,offset [numpadset]
	mov	cx,cs
	mov	es,cx
	cld
	mov	cx,10
	repne	scasb
	jne	chkn1
	mov	al,9
	sub	al,cl
	cmp	al,al
chkn1:
	pop	es
	pop	di
	pop	cx
	ret
chknumset endp

	subttl callintr9 - calls an int9 intercept
	page
;======================================================================
;,fs
; callintr9 - calls an int9 intercept
;
; calls an int9 intercept.  when available, i/o trapping is
; used to present the scan code when the intercept's code does an
; 'in al,60'.  when i/o trapping is not available, int9 intercepts
; must be patched to insure reliable operation.
; ax, and si are crashed
;
; in:	scan code in [tcbtrapcd]
;	ss -> tcb of current task
;	ds -> tcb of console being processed
;	es -> grp
;
; out:
;
;,fe
;======================================================================
	assume	ds:nothing,es:grp,ss:tcb
callintr9 proc near
	in	al,21h
	push	ax
	or	al,0feh 		; disable all but irq0's
	out	21h,al
	mov	[tcbi9flg],0ffh 	; signal decodescan when called in mosint09
	mov	[tcbi9seg],ds		; record visual tcb for mosint09
	test	[scbmmfea],40h		; is i/o protection supported?
	jz	call9a			; no, skip

; set scbin60 to 0 to cause the trapping logic to provide data from
; tcbtrapcd rather than pass the operation on to the actual hardware.
; even if [scbkbrate] == ff, ok to go ahead and set the trapping bit
; for port 60 (it will already be on anyway).

	mov	[scbin60],0
	push	ds
	lds	si,[scbioptr]		; get ptr to memman data
	or	byte ptr [si+12],1	; port 60h protection
	or	byte ptr [si+4],2	; port 21h protection
	pop	ds

; in the lidt case, we can just make a call to the current 0:9*4 vector.
; in the non-lidt case, we must call the vector that is stored in the
; tcbchn9 table at the highest nest level (the last intercept made).

call9a:
	push	ax
	push	bx
	push	cx
	push	dx			; save registers that will be blown by
	push	ds			; the bias_stack procedure
	push	es
	mov	ax,es
	mov	ds,ax
	xor	dh, dh			; use normal biasing		; mjs
	call	bias_stack		; set up stack protection
	test	[scbmmfea],04h		; lidt or regrab?
	jnz	call9b
	mov	cl,[tcbnest9]		; calculate location of most recent
	dec	cl			; int9 intercept vector.  intercept
	shl	cl,1			; vectors are stored in the table
	shl	cl,1			; tcbchn9
	xor	ch,ch
	mov	si,offset [tcbchn9]
	add	si,cx
	mov	[chain9],1		; mosint09 needs to know it's being
	pushf				; entered from an intercept chain call
	call	dword ptr ss:[si]
	mov	[chain9],0
	jmp	call9c
call9b:
	mgetzero es
	assume	es:nothing
	pushf				; in the lidt case, simply call the
	call	dword ptr es:[9*4]	; vector at 0:9*4
call9c:
	assume	ds:tcb,ss:nothing
	pop	[tcbstkp]		; the bias_stack procedure puts
	pop	es			; tcbstkp on the stack
	pop	ds
	assume	ds:nothing,es:grp,ss:tcb
	pop	dx
	pop	cx
	pop	bx
	pop	ax

; restore the machine state

	test	[scbmmfea],40h		; i/o protection supported?
	jz	call9d			; no, skip

; reset scbin60 so the port 60 trapping logic will pass on to the hardware.
; note that the port 60 trapping bit is not reset if scbkbrate == ff

	mov	[scbin60],1		; singal trapping logic to pass on
	mov	al,[scbkbrate]
	push	ds
	lds	si,[scbioptr]		; get ptr to memman data
	cmp	al,0ffh
	je	call9e
	and	byte ptr [si+12],not 1	; port 60h protection
call9e:
	and	byte ptr [si+4],not 2	; port 21h protection
	pop	ds
call9d:
	pop	ax
	out	21h,al
	ret
callintr9 endp

	subttl	decodescan - converts a scan code and buffers keycodes
	page
;======================================================================
;,fs
; decodescan - converts a scan code and buffers keycodes
;
; converts a scan code into a scan/keycode pair and
; and buffers them (if appropriate).
; called by getddkeys and mosint09
;
; in:	al = scan code
;	ds -> visual tcb
;	es -> task tcb (for putkbf)
;
; out:	returns al <> 0 if a pam key
;
;,fe
;======================================================================
	assume	ds:tcb,es:nothing,ss:nothing
decodescan proc near
	push	bx			; mjs 12/8/87  mosint09 needs this
	and	[tcbbrkfg],not 4	; clear cntrl-brk flag
	call	prsscan 		; convert scan code to key code
	cmp	bx,-1
	je	decsn4
	push	ax
  	mov	ax,bx			; if bx != -1, buffer bx
	call	putkbf
	pop	ax
decsn4:
	cmp	ax,-1
	je	decsn1			; if ax == -1, scancode didn't result in keycode
	test	[tcbbrkfg],4		; test cntrl-brk flag
	jnz	decsn2
	cmp	ax,0ff00h
	je	decsn3
	or	ah,ah			; ah = 0 if code from alt+numeric pad
	jnz	decsn2
decsn3:
	assume	ss:tcb, ds:nothing	;BWR 9/17/90
	cmp	[tcbalt999],0
	assume	ds:tcb, ss:nothing	;BWR 9/17/90
	je	decsn2			; e if tcbalt999 not in pam mode
	mov	[tcbmoskey],al		; save the pam # for later
	mov	al,-1			; signal a moskey call
	jmp	decsnx
decsn2:
	and	[tcbbrkfg],not 4	; reset the cntrl-brk flag
	call	putkbf			; buffer ax
decsn1:
	xor	al,al			; signal no moskey call
decsnx:
	pop	bx			; mosint09 needs this
	ret
decodescan endp

	subttl keyclasschk - security clearance for kybd input
	page
;======================================================================
;,fs
; keyclasschk - security clearance for kybd input
;
; fetch the task's class in al using es->tcb
; classbits will fetch the access level of the visual (ds) tcb
; for that class.  
; will take a jb after this call if access is not ok.
;
; in:	es -> task tcb
;	ds -> visual tcb
;
; out:
;
;,fe
;======================================================================
	assume	ds:nothing,es:tcb,ss:nothing
keyclasschk proc near
	push	ax
	mov	al,[tcbclass]
	callmos2 classbits
	cmp	al,3
	pop	ax
	ret
keyclasschk endp

	subttl putkbf - put ax in type ahead buffer
	page
;======================================================================
;,fs
; putkbf - put ax in type ahead buffer
;
; note that zero flag set means could not insert into buffer
;
; in:	es -> task tcb
;	ds -> visual tcb
;
; out:
;
;,fe
;======================================================================
	assume	ds:nothing,ss:nothing,es:tcb  ; used to be ss:tcb
putkbf proc near
	push	cx
	push	dx
	push	si
	push	di
	push	ds
	cmp	[tcbi9flg],0		; from mosint09 origin type 2
	jne	putkbf4
	call	keyclasschk		; checking ds:tcb
	jb	putkbf2 		; b if can't write in partition
putkbf4:
	cli
	mov	cx,bios
	mov	ds,cx
	assume	ds:bios
	mov	dx,[tcbibsiz]
	mov	cx,[tcbibase]
	add	dx,cx
	dec	dx			; calc upper limit for range verification
	cmp	[ikbtail],dx		; if an application stuffs a wrong value in
	ja	kbfix			; here, re-init
	cmp	[ikbhead],dx
	ja	kbfix
	cmp	[ikbtail],cx
	jb	kbfix
	cmp	[ikbhead],cx
	jnb	putkbf3
kbfix:
	mov	[ikbtail],cx
	mov	[ikbhead],cx
putkbf3:
	mov	si,[ikbtail]
	mov	di,si
	add	si,2
	cmp	si,dx			; time to wrap around ?
	jb	putkbf1
	mov	si,[tcbibase]
putkbf1:
	cmp	si,[ikbhead]
	je	putkbf2 		; e if full buffer, throw this key away
	mov	[di],ax 		; store it in the input buffer
	mov	[ikbtail],si
putkbf2:
	sti
	pop	ds
	pop	di
	pop	si
	pop	dx
	pop	cx
	ret
putkbf endp

	subttl	prsscan - parse a keyboard scan code into a key code
	page
;======================================================================
;,fs
; prsscan - parse a keyboard scan code into a key code
;
; in:	al = scan code
;	ds -> tcb
;
; out:	ax = -1 don't do anything
;	  (scan code processed as needed already)
;	ax <> -1 and bx = -1, buffer ax = key code
;	  (normal case)
;	ax <> -1 and bx <> -1, buffer bx = key code, then ax = key code
;	  (some accent shift failed)
;
;,fe
;======================================================================
	assume	ds:tcb,es:nothing,ss:nothing
prsscan proc near
	push	dx
	push	si
	push	es
	push	ds
	push	ax
	mov	bx,ax
	MGetSCB es
	assume  es:grp
	cmp	[scbkbbios],'N'		; did user to KBBIOS=NO
	mov	es,[sbios]
	assume	es:bios
	jne	prs0
	mov	al,[tcbkshft]		; update 40:17 from TCBKSHFT
	mov	[ikbstat],al
	jmp	short prs0a
prs0:
	and	byte ptr es:[96h],0fch
	cmp	bl,0e0h
	jne	prse0
	or	byte ptr es:[96h],2
prse0:
	cmp	bl,0e1h
	jne	prse1
	or	byte ptr es:[96h],1
prse1:
	mov	al,[ikbstat]		; update TCBKSHFT from 40:17
	mov	[tcbkshft],al
prs0a:
	call	synclock		; synchronize numlock on terminals
	pop	ax			; restore scan code
	mgetscb es
	assume	es:grp
	push	ds			; call the scan code processing logic
	call	dword ptr [scbscang]	; note: when a foreign keyboard driver
	pop	ds			; is used, it will have changed
	or	dx,dx			; scbscang to point to itself
	cmp	dx, 0
	jne	prs1
	jmp	prsx
prs1:
	cmp	dx, 1
	jne	prs2
	assume	ds:nothing,ss:tcb
	or	[tcbbrkfg],80h		; set flag to indicate that int 5 is
	mov	ax,-1			; is to be issue
	jmp	short prsx
prs2:
	cmp	dx, 2
	jne	prs3
	push	[tcbstkp]
	mov	[tcbstkp],sp
	sub	[tcbstkp],64
	int	1bh
	pop	[tcbstkp]
	assume	ds:tcb,ss:nothing
	or	[tcbbrkfg],4		; set cntrl-brk flag
	mov	ax,bios
	mov	es,ax
	assume	es:bios
	mov	ax,[tcbibase]
	mov	[ikbtail],ax
	mov	[ikbhead],ax
	xor	ax,ax
	jmp	short prsx
prs3:
	cmp	dx, 3
	jne	prsx
	push	ax
	push	bx
	mov	ax,ds			; console tcb to ax
	mov	bx,ss			; task tcb to bx
	cmp	ax,bx			; did he ctrl-alt-del his own task?
	pop	bx
	pop	ax
	jnz	prsx
	cmp	[tcbreboot], 0
	jne	prsx
	cmp	[tcbcamon], 0
	jne	prsx
	mov	[tcbcamon], 0ffh	; ask for restart of the task
	push	es
	mgetscb es
	assume	cs:mos, ds:tcb, es:grp, ss:nothing
	inc	[scbrstrtc]		; bump the count waiting restart
	pop	es
	assume	cs:mos, ds:tcb, es:nothing, ss:nothing
prsx:
	pop	ds
	pop	es
	pop	si
	pop	dx
	ret
prsscan endp

	subttl	synclock - attempt to synchronize numlock on terminals
	page
;======================================================================
;,fs
; synclock - attempt to synchronize numlock on terminals
;
; extended cursor keys are misinterpreted when the e0 prefix is
; overrun and the terminals numlock does not match the task's
; numlock.  unfortunately, there is no method to set the terminal's
; numlock, and the keyboard status query does not work on most/any
; terminals.
;
; extended cursor keys send  <e0><num><e0><~num> if numlock is off on
; the terminal.  if numlock is on, the cursor keys send
; <e0><2a><e0><num><e0><~num><e0><aa>.	if the key is held down,
; <e0><num> will be repeated in the above sequences.
;
; following routine examines the previous characters, to determine
; the terminal's NUMLOCK. is different than 40:17, if so then
; TCBCON417 is -1 to force next call through getkeys to update the leds
;
; in:	ds -> tcb
;	es -> bios
;	bl = current scan code
;	[tcblscan] = last scan code
;	[tcbpscan] = previous to last scan code
;	[tcblocker] = previous numlock errors
;
;,fe
;======================================================================
	assume	ds:tcb, es:bios, ss:nothing
synclock proc near
	push	cx			; used by onpatrn and offpatrn
	push	dx			; going to use dx for internal flags
	cmp	[tcbid],0		; if console, forget this mess
	lje	synl050
	mov	al,[tcblscan]		; get last key
	mov	ah,al
	xchg	al,[tcbpscan]		; get/set second previous char
	xor	dx,dx			; init dl and dh as flags

; at this point:
; bl = current scan code	ah = last scan code
; al = previous to last dl flags a pattern match
; dh flags a mismatch between a detected pattern and the numlock state

	cmp	bl,numpad_lo
	jae	synl002
	jmp	synl050
synl002:
	cmp	bl,numpad_hi
	jbe	synl004
	jmp	synl050
synl004:

; if a workstation's numlock appears to be on but its num-lock shift
; state is off, set the flags in dx to have the shift state toggled.

	call	onpatrn
	jnz	synl020
	mov	dl,1
	test	[tcbkshft], kbs_num
	jnz	synl010
	mov	dh,1
synl010:
	jmp	short synl040
synl020:

; if a workstation's numlock appears to be off but its num-lock shift
; state is on, set the flags in dx to have the shift state toggled.

	call	offpatrn
	jnz	synl040
	mov	dl,1
	test	[tcbkshft], kbs_num
	jz	synl040

; must do this test to prevent false detection of an off pattern when
; two arrow keys on the dedic ated keypad are pressed together.

	test	[tcbkshft],kbs_lshf
	jnz	synl040
	mov	dh,1
synl040:

; this code requires only one pattern mismatch before the numlock state
; is changed based on detected patterns

	cmp	dx,0101h		; when detect a mismatch
	jne	synl050
	mov	[tcbcon417],-1		; for update on leds
	push	ds
	MGetSCB ds
	assume  ds:grp
	cmp	[scbkbbios],'N'
	pop	ds
	assume  ds:tcb
	jne	synl050
	mov	al,[tcbkshft]
	mov	[ikbstat],al
synl050:
	pop	dx
	pop	cx
	ret
synclock endp

	subttl onpatrn - test for an "on" pattern
	page
;======================================================================
;,fs
; onpatrn - test for an "on" pattern
;
; in:	ah = last scan code
;	al = previous to last scan code
;
; out:	zr if detect an on pattern
;
;,fe
;======================================================================
onpatrn proc near
	xor	cx,cx
	cmp	al, 0e0h
	jne	onp002
	cmp	ah, 2ah
	je	onp010
onp002:
	cmp	al, 0e0h
	jne	onp004
	cmp	ah, 0e0h
	je	onp010
onp004:
	cmp	al, 2ah
	jne	onp006
	cmp	ah, 0e0h
	je	onp010
onp006:
	inc	cx
onp010:
	or	cx,cx			; cx will still be 0 if a match
	ret
onpatrn endp

	subttl offpatrn - test for an "off" pattern
	page
;======================================================================
;,fs
; offpatrn
;
; if last == e0 and previous to last is not
; e0, 2a or the current scancode then signal an off pattern.
; checking al == bl is to accomodate the case where numlock
; is on and an extended cursor key is being held down to repeat
;
; in:	ah = last scan code
;	al = previous to last scan code
;
; out:	zr if detect an off pattern
;
;,fe
;======================================================================
offpatrn proc near
	mov	cx,1
	cmp	al,0e0h
	je	ofp010
	cmp	al,2ah
	je	ofp010
	cmp	al,bl
	je	ofp010
	cmp	ah,0e0h
	jne	ofp010
	dec	cx
ofp010:
	or	cx,cx			; cx will be 0 if a match
	ret
offpatrn endp

	subttl	scanguts - parse a keyboard scan code into a key code
	page
;======================================================================
;,fs
; scanguts - parse a keyboard scan code into a key code
;
; in:	al = scan code
;	ds -> tcb
;	es -> grp
;
; out:	dx = function
;	if dx = 0
;	  ax = -1
;	    ignore scan code
;	  ax <> -1 and bx = -1
;	    buffer ax = key code  (normal case)
;	  ax <> -1 and bx <> -1
;	    buffer bx, then ax (accent shift failed)
;	else dx <> 0
;	  dx = 1 process a shift prtsc
;	  dx = 2 process a cntrl-break
;	  dx = 3 process a ctrl-alt-del
;
; destroys ax, bx, cx, dx, si, es, ds
;
;,fe
;======================================================================
	assume	cs:mos, ds:tcb
scanguts proc far
	mov	cl,al			; cl retains scan code
	mov	ch,[tcbkshft]
	mov	bx,ds
	mov	es,bx			; tcb goes to es, code in ds
	mov	bx,cs
	mov	ds,bx
	assume	ds:mos,es:tcb
	mov	si,offset basetbl	; presume base table
	xor	dl,dl			; use for extended numpad flag
	test	ch,kbs_alt		; alt key highest priority.
	jz	scg020
	mov	si,offset alttbl
	jmp	short scg045
scg020:
	test	ch,kbs_ctl
	jz	scg030
	mov	si,offset ctrltbl
	jmp	short scg045
scg030:

; if the scancode is from a numeric key (or extended cursor key)
;  if extended cursor key, exit (keep base table)
;  else if numlock and shift both down or both up, exit (keep base table)
;  else use shift table

	cmp	al,numpad_lo
	jnae	scg040
	cmp	al,numpad_hi
	jnbe	scg040
	cmp	[tcblscan],0e0h
	je	scg045
	test	ch,kbs_num
	jz	scg032
	test	ch,kbs_shf
	jnz	scg045
scg032:
	test	ch,kbs_num
	jnz	scg034
	test	ch,kbs_shf
	jz	scg045
scg034:
	mov	si,offset shfttbl
	jmp	short scg045
scg040:
	test	ch,kbs_shf
	jz	scg045
	mov	si,offset shfttbl
scg045:

; si -> correct key table
; al, cl = scan code
; ch = shift state

	mov	dl,[tcblscan]
	mov	[tcblscan],cl
	mov	bx,-1			; initialize auxiliary return
	cmp	al,0e0h
	je	scg078
	cmp	al,0e1h
	je	scg078
	and	al,7fh
	add	al,al			; get index into table
	xor	ah,ah
	add	si,ax			; table + 2 * scan
	mov	ax,[si] 		; get translated code from table
	mov	bx,ax			; setup for special function here
	cmp	dl,0e0h
	jne	scg045d 		; if last scancode == e0
	cmp	ax,35f0h		; and if alt-slash (alt-pad-/)
	jne	scg045e
	mov	ax,0a400h		; xlate to a400
	jmp	short scg045a
scg045e:
	cmp	ax,1c0dh
	je	scg045c 		; if pad-enter, or
	cmp	ax,1c0ah
	je	scg045c 		; if pad-cntrl-enter, or
	cmp	ax,352fh
	jne	scg045b 		; if pad-slash
scg045c:
	mov	ah,0e0h 		; set high byte to e0
	jmp	short scg045a
scg045b:
	cmp	ax,0a600h
	je	scg045a 		; else, if not alt-pad-enter
	cmp	ax,9500h		; and not cntrl-numpad-slash
	je	scg045a
	mov	al,0e0h 		; set low byte to e0
	jmp	short scg045a
scg045d:
	cmp	ax,0a600h		; if e0 wasn't last scancode
	jne	scg045a 		; and table word is a600 (alt-enter)
	mov	ax,1c00h		; convert to non-pad version
scg045a:
	mov	[tcblscan],cl
	xor	dx,dx			; initialize function return
	cmp	ah,0
	jne	scg060
	add	bx,bx			; use data from table before e0 mod
	call	cs:[keyvct+bx]		; call special function
scg060:

; dx = function code from special routine
; ax = key code from table or special routine
;	= -1  for nulls
;	al = 0	 for function keys
;	ah > 128 for accent shift
;	cl = scan code (special routine may have manipulated)

	mov	bx,-1			; initialize auxiliary return
	test	cl,80h
	jnz	scg080			; if break of a key
	cmp	ax,-1
	je	scg110
	cmp	al,0
	jne	scg070
	jmp	short scg110
scg070:
	test	ch,kbs_cap
	jz	scg075
	call	caseshft		; toggle case of character
scg075:
	jmp	short scg110
scg078:
	xor	dx,dx
scg080:
	and	[tcbkbctl],not (kbc_e0 or kbc_e1)
	cmp	cl,0e0h
	jne	scg090
	or	[tcbkbctl],kbc_e0	; set prefix flag
	jmp	short scg100
scg090:
	cmp	cl,0e1h
	jne	scg100
	or	[tcbkbctl],kbc_e1	; set prefix flag
scg100:
	mov	ax,-1			; return without a key
	jmp	short scg120
scg110:
	and	[tcbkbctl],not (kbc_e0 or kbc_e1)
scg120:
	retf
scanguts endp

; in: 	al = char to case shift
;
; out:	if zr al = case shifted character
;	if nz lookup failed
;
; caseshft if capslock is enabled, alphabetic chars must
; be case shifted.  ascii chars are xored and foreign chars
; are found in the table.

caseshft:
	cmp	al,'z'			; test al is ascii
	ja	cashftxit
	cmp	al,'A'
	jb	cashftxit		; not ascii and not shiftable
	cmp	al,'Z'
	jbe	cashftasc		; ascii case shift
	cmp	al,'a'
	jb	cashftxit		; not ascii and not shiftable
cashftasc:
	xor	al,'a'-'A'		; case shift ascii chars
cashftxit:
	ret


@caps:
	mov	al,kbs_cap
	jmp	toggle
@num:
	mov	al,kbs_num
	jmp	toggle
@scroll:
	mov	al,kbs_scrl

; toggle handles toggle states (scroll, numlock, caplock)
; sets/resets tggl bit.  if first make toggles shft bit.
;
; enter: al = bit to set / reset

toggle:
	or	cl,cl			; test break / make
	js	togglclr
	test	[tcbktggl],al		; test first make
	jnz	togglxit		; no just exit
	or	[tcbktggl],al
	xor	[tcbkshft],al
	push	ds
	mov	ds,[sbios]
	assume	ds:bios
	mov	al,[tcbkshft]
	mov	[ikbstat],al
	pop	ds
	assume	ds:mos
	jmp	short togglxit
togglclr:
	not	al			; clear toggle bit
	and	[tcbktggl],al
togglxit:
	mov	ax,-1			; no key to return
	ret

; alt shift with alt num-pad capability

@alt:
	mov	al,kbs_alt
	test	[tcbkbctl],kbc_e0	; test right alt key
	jz	@altleft
	mov	al,kbc_ralt		; fake out for alt-gr
	call	control
@altleft:
	mov	al,kbs_alt
	call	shift
	or	cl,cl
	jns	@altxit 		; finished if make of alt
	cmp	byte ptr [tcbaltnum+1],0
	je	@altxit 		; test numbered entered during alt
	xor	ax,ax			; clear / get altnum
	xchg	ax,word ptr [tcbaltnum]
	xor	ah,ah			; flag key came from alt-numpad
	and	cl, 07fh		; reset key-break flag, so this looks normal
@altxit:
	ret

@ctrl:
	test	[tcbkbctl],kbc_e0	; test right alt key
	jz	@ctrlleft
	mov	al,kbc_rctl		; flag right control
	call	control
@ctrlleft:
	mov	al,kbs_ctl
	jmp	short shift
@lshift:
	mov	al,kbs_lshf
	jmp	short shift
@rshift:
	mov	al,kbs_rshf

; shift sets / clears bits in tcbkshft
; enter: al = bits to set on make / reset on break of key

shift:
	cmp	al,kbs_lshf		; is this for left switch
	jne	shftcont		; no than this is not it
	test	[tcbkbctl],kbc_e0	; test for enhance cursor pad keys
	jnz	shftdone
shftcont:
	or	[tcbkshft],al
	or	cl,cl			; test make / break of key
	jns	shftxit
	not	al			; key break - clear bits
	and	[tcbkshft],al
shftxit:
	push	ds
	mov	ds,[sbios]
	assume	ds:bios
	mov	al,[tcbkshft]
	mov	[ikbstat],al
	pop	ds
	assume	ds:mos	
shftdone:
	mov	ax,-1
	ret

; control sets / clears bits in tcbkbctl
; enter: al = bits to set on make / reset on break of key

control:
	or	[tcbkbctl],al
	or	cl,cl			; test make / break of key
	jns	ctrlxit
	not	al			; key break - clear bits
	and	[tcbkbctl],al
ctrlxit:
	ret

@insert:
	push	ax			; save al (could be e0)
	mov	al,kbs_ins		; toggle insert flag
	call	toggle
	pop	ax			; restore al
	cmp	al,0e0h
	je	@ins1
	xor	al,al
@ins1:
	mov	ah,52h			; setup ah
	push	cx
	and	cl,80h
	or	ah,cl			; preserve make/break state
	pop	cx
	ret

; shift prtsc key

@prtscr:
	or	cl,cl
	js	@prtsc1 		; skip if releasing the key

; if last code was e0, always do print screen
; else, only do if a shift key is down
; else, return a '*' (must have gotten here from the base case)

	test	[tcbkbctl],kbc_e0
	jnz	@prtsc0
	test	[tcbkshft],(kbs_lshf + kbs_rshf)
	jnz	@prtsc0
	mov	ax,372ah
	ret	
@prtsc0:
	mov	dx,1
@prtsc1:
	mov	ax,-1
	ret

; ignore pause key

@pause:
	or	[tcbbrkfg],10h
	mov	ax,-1
	ret

; ctrl scroll-lock

@break: or	cl,cl
	js	@break1 		; skip if releasing the key
	mov	dx,2
@break1:
	mov	ax,-1
	ret

; handle alt-numpad character entry
; accumulate number in tcbaltnum, if 999 entered toggle flag

@altnum:
	or	cl,cl			; key make?
	js	@altnxit
	mov	bl,cl			; lookup ascii value
	add	bl,bl			; word index
	xor	bh,bh
	mov	bl,byte ptr [shfttbl+bx]
	and	bl,15			; bx = key's value
	mov	al,10
	mul	[tcbaltnum]		; multiply old number by 10
	add	ax,bx			; add new digit
	cmp	ax,999			; alt 999 ?
	je	@altn999
	or	ah,80h			; flag alt-number seen
	mov	word ptr [tcbaltnum],ax
@altnxit:
	mov	ax,-1			; no key to return
	ret

@altn999:				; toggle alt999 and init altnum
	mov	word ptr [tcbaltnum],0
        assume  ss:tcb, ds:nothing      ;BWR 9/17/90
	xor	[tcbalt999],0ffh
        assume  ds:mos, ss:nothing      ;BWR 9/17/90
	jmp	@altnxit

; ctrl-alt-f1 reverts to us keyboard
; ctrl-alt-f2 reverts to foreign keyboard

@uskeyb:
	or	[tcbkbctl],kbc_us
	mov	ax,-1			; revert to us keyboard
	ret

; ctrl-alt-del return reboot function

@reboot:
	mov	ax, 0a300h		; get alt-del code
	test	ch, kbs_ctl
	jz	@rebtxit
	mov	ax,-1			; else return ctrl-alt-del function
	mov	dx,3			; return reboot function
@rebtxit:
	ret




;======================================================================

; vectors into subroutines for keys which require special handling

keyvct	label	word
	dw	@caps			; 00
	dw	@num			; 01
	dw	@scroll 		; 02
	dw	@alt			; 03
	dw	@ctrl			; 04
	dw	@lshift 		; 05
	dw	@rshift 		; 06
	dw	@insert 		; 07
	dw	@prtscr 		; 08
	dw	@pause			; 09
	dw	@break			; 0A
	dw	@altnum 		; 0B
	dw	@reboot 		; 0C
	dw	?			; 0D
	dw	?			; 0E
	dw	?			; 0F
	dw	?			; 10

comment ^==============================================================

		       format of table entries
		       =======================

normal entries
==============

the first byte is the keycode, second is the scan code to be returned
by int16fun00:

	db	074h,014h		; 14 t


extended keys have 0 as their first byte:

	db	000h,03Bh		; 3B f1


special cases
=============

this entry defines a scancode which doesn't return any keycode:

	db	0FFh,0FFh		; 00


special function keys have 0 as their second byte.  the first byte is
the function number (using the keyvct table):

	db	002h,000h		; 46 scrollock


keys which were first introduced on the 101 keyboard use either a
scan code > 84h (such as f11) or have F0 as their first byte (such as
numeric pad 5).  int16fun10 and fun11 must be used to read these
scancodes.

	db	0F0h,04ch		; 4C n5

	db	000h,085h		; 57 f11


======================================================================^

basetbl label	word
					;scan code
					;=========
	db	0FFh,0FFh		; 00
	db	01Bh,001h		; 01 escape
	db	031h,002h		; 02 1
	db	032h,003h		; 03 2
	db	033h,004h		; 04 3
	db	034h,005h		; 05 4
	db	035h,006h		; 06 5
	db	036h,007h		; 07 6
	db	037h,008h		; 08 7
	db	038h,009h		; 09 8
	db	039h,00Ah		; 0A 9
	db	030h,00Bh		; 0B 0
	db	02Dh,00Ch		; 0C -
	db	03Dh,00Dh		; 0D =
	db	008h,00Eh		; 0E backspace
	db	009h,00Fh		; 0F tab
	db	071h,010h		; 10 q
	db	077h,011h		; 11 w
	db	065h,012h		; 12 e
	db	072h,013h		; 13 r
	db	074h,014h		; 14 t
	db	079h,015h		; 15 y
	db	075h,016h		; 16 u
	db	069h,017h		; 17 i
	db	06Fh,018h		; 18 o
	db	070h,019h		; 19 p
	db	05Bh,01Ah		; 1A [
	db	05Dh,01Bh		; 1B ]
	db	00Dh,01Ch		; 1C new-line
	db	004h,000h		; 1D lctrl
	db	061h,01Eh		; 1E a
	db	073h,01Fh		; 1F s
	db	064h,020h		; 20 d
	db	066h,021h		; 21 f
	db	067h,022h		; 22 g
	db	068h,023h		; 23 h
	db	06Ah,024h		; 24 j
	db	06Bh,025h		; 25 k
	db	06Ch,026h		; 26 l
	db	03Bh,027h		; 27 ;
	db	027h,028h		; 28 '
	db	060h,029h		; 29 `
	db	005h,000h		; 2A lshift
	db	05Ch,02Bh		; 2B \
	db	07Ah,02Ch		; 2C z
	db	078h,02Dh		; 2D x
	db	063h,02Eh		; 2E c
	db	076h,02Fh		; 2F v
	db	062h,030h		; 30 b
	db	06Eh,031h		; 31 n
	db	06Dh,032h		; 32 m
	db	02Ch,033h		; 33 ,
	db	02Eh,034h		; 34 .
	db	02Fh,035h		; 35 /
	db	006h,000h		; 36 rshift
	db	008h,000h		; 37 prtsc
	db	003h,000h		; 38 alt
	db	020h,039h		; 39 spacebar
	db	000h,000h		; 3A capslock
	db	000h,03Bh		; 3B f1
	db	000h,03Ch		; 3C f2
	db	000h,03Dh		; 3D f3
	db	000h,03Eh		; 3E f4
	db	000h,03Fh		; 3F f5
	db	000h,040h		; 40 f6
	db	000h,041h		; 41 f7
	db	000h,042h		; 42 f8
	db	000h,043h		; 43 f9
	db	000h,044h		; 44 f10
	db	001h,000h		; 45 numlock
	db	002h,000h		; 46 scrollock
	db	000h,047h		; 47 n7 home
	db	000h,048h		; 48 n8 uparrow
	db	000h,049h		; 49 n9 pgup
	db	02Dh,04Ah		; 4A gray -
	db	000h,04Bh		; 4B n4 larrow
	db	0F0h,04ch		; 4C n5
	db	000h,04Dh		; 4D n6 rarrow
	db	02Bh,04Eh		; 4E gray +
	db	000h,04Fh		; 4F n1 end
	db	000h,050h		; 50 n2 darrow
	db	000h,051h		; 51 n3 pgdn
	db	007h,000h		; 52 n0 insert
	db	000h,053h		; 53 n. delete
	db	0FFh,0FFh		; 54 sysreq
	db	0FFh,0FFh		; 55
	db	0FFh,0FFh		; 56
	db	000h,085h		; 57 f11
	db	000h,086h		; 58 f12

; for citoh 7102

	db	0FFh,0FFh		; 59
	db	0FFh,0FFh		; 5A
	db	0FFh,0FFh		; 5B
	db	0FFh,0FFh		; 5C
	db	000h,051h		; 5D pgdn
	db	007h,000h		; 5E
	db	000h,053h		; 5F
	db	00Dh,060h		; 60 return
	db	000h,047h		; 61 home
	db	000h,048h		; 62
	db	000h,049h		; 63 pgup
	db	000h,04Bh		; 64 left
	db	000h,04Dh		; 65 right
	db	000h,04Fh		; 66 end
	db	000h,050h		; 67
	db	0A0h,07Fh		; 68 pf1 - pf24
	db	0A1h,07Fh		; 69
	db	0A2h,07Fh		; 6A
	db	0A3h,07Fh		; 6B
	db	0A4h,07Fh		; 6C
	db	0A5h,07Fh		; 6D
	db	0A6h,07Fh		; 6E
	db	0A7h,07Fh		; 6F
	db	0A8h,07Fh		; 70
	db	0A9h,07Fh		; 71
	db	0AAh,07Fh		; 72
	db	0ABh,07Fh		; 73
	db	0ACh,07Fh		; 74
	db	0ADh,07Fh		; 75
	db	0AEh,07Fh		; 76
	db	0AFh,07Fh		; 77
	db	0B0h,07Fh		; 78
	db	0B1h,07Fh		; 79
	db	0B2h,07Fh		; 7A
	db	0B3h,07Fh		; 7B
	db	0B4h,07Fh		; 7C
	db	0B5h,07Fh		; 7D
	db	0B6h,07Fh		; 7E
	db	0B7h,07Fh		; 7F

;======================================================================

	subttl	shift case keyboard scan code translation table
	page

shfttbl label	word
					;scan code
					;=========
	db	0FFh,0FFh		; 00
	db	01Bh,001h		; 01 escape
	db	021h,002h		; 02 1
	db	040h,003h		; 03 2
	db	023h,004h		; 04 3
	db	024h,005h		; 05 4
	db	025h,006h		; 06 5
	db	05Eh,007h		; 07 6
	db	026h,008h		; 08 7
	db	02Ah,009h		; 09 8
	db	028h,00Ah		; 0A 9
	db	029h,00Bh		; 0B 0
	db	05Fh,00Ch		; 0C -
	db	02Bh,00Dh		; 0D =
	db	008h,00Eh		; 0E backspace
	db	000h,00Fh		; 0F tab
	db	051h,010h		; 10 q
	db	057h,011h		; 11 w
	db	045h,012h		; 12 e
	db	052h,013h		; 13 r
	db	054h,014h		; 14 t
	db	059h,015h		; 15 y
	db	055h,016h		; 16 u
	db	049h,017h		; 17 i
	db	04Fh,018h		; 18 o
	db	050h,019h		; 19 p
	db	07Bh,01Ah		; 1A [
	db	07Dh,01Bh		; 1B ]
	db	00Dh,01Ch		; 1C new-line
	db	004h,000h		; 1D lctrl
	db	041h,01Eh		; 1E a
	db	053h,01Fh		; 1F s
	db	044h,020h		; 20 d
	db	046h,021h		; 21 f
	db	047h,022h		; 22 g
	db	048h,023h		; 23 h
	db	04Ah,024h		; 24 j
	db	04Bh,025h		; 25 k
	db	04Ch,026h		; 26 l
	db	03Ah,027h		; 27 ;
	db	022h,028h		; 28 '
	db	07Eh,029h		; 29 `
	db	005h,000h		; 2A lshift
	db	07Ch,02Bh		; 2B \
	db	05Ah,02Ch		; 2C z
	db	058h,02Dh		; 2D x
	db	043h,02Eh		; 2E c
	db	056h,02Fh		; 2F v
	db	042h,030h		; 30 b
	db	04Eh,031h		; 31 n
	db	04Dh,032h		; 32 m
	db	03Ch,033h		; 33 ,
	db	03Eh,034h		; 34 .
	db	03Fh,035h		; 35 /
	db	006h,000h		; 36 rshift
	db	008h,000h		; 37 prtsc
	db	003h,000h		; 38 alt
	db	020h,039h		; 39 spacebar
	db	000h,000h		; 3A capslock
	db	000h,054h		; 3B f1
	db	000h,055h		; 3C f2
	db	000h,056h		; 3D f3
	db	000h,057h		; 3E f4
	db	000h,058h		; 3F f5
	db	000h,059h		; 40 f6
	db	000h,05Ah		; 41 f7
	db	000h,05Bh		; 42 f8
	db	000h,05Ch		; 43 f9
	db	000h,05Dh		; 44 f10
	db	001h,000h		; 45 numlock
	db	0FFh,0FFh		; 46 scrollock
	db	037h,047h		; 47 n7 home
	db	038h,048h		; 48 n8 uparrow
	db	039h,049h		; 49 n9 pgup
	db	02Dh,04Ah		; 4A gray -
	db	034h,04Bh		; 4B n4 larrow
	db	035h,04Ch		; 4C n5
	db	036h,04Dh		; 4D n6 rarrow
	db	02Bh,04Eh		; 4E gray +
	db	031h,04Fh		; 4F n1 end
	db	032h,050h		; 50 n2 darrow
	db	033h,051h		; 51 n3 pgdn
	db	030h,052h		; 52 n0 insert
	db	02Eh,053h		; 53 n. delete
	db	0FFh,0FFh		; 54 sysreq
	db	0FFh,0FFh		; 55
	db	0FFh,0FFh		; 56
	db	000h,087h		; 57 f11
	db	000h,088h		; 58 f12

; for citoh 7102

	db	0FFh,0FFh		; 59
	db	0FFh,0FFh		; 5A
	db	0FFh,0FFh		; 5B
	db	0FFh,0FFh		; 5C
	db	000h,051h		; 5D pgdn
	db	007h,000h		; 5E
	db	000h,053h		; 5F
	db	00Dh,060h		; 60 return
	db	000h,047h		; 61 home
	db	000h,048h		; 62
	db	000h,049h		; 63 pgup
	db	000h,04Bh		; 64 left
	db	000h,04Dh		; 65 right
	db	000h,04Fh		; 66 end
	db	000h,050h		; 67
	db	0A0h,07Fh		; 68 pf1 - pf24
	db	0A1h,07Fh		; 69
	db	0A2h,07Fh		; 6A
	db	0A3h,07Fh		; 6B
	db	0A4h,07Fh		; 6C
	db	0A5h,07Fh		; 6D
	db	0A6h,07Fh		; 6E
	db	0A7h,07Fh		; 6F
	db	0A8h,07Fh		; 70
	db	0A9h,07Fh		; 71
	db	0AAh,07Fh		; 72
	db	0ABh,07Fh		; 73
	db	0ACh,07Fh		; 74
	db	0ADh,07Fh		; 75
	db	0AEh,07Fh		; 76
	db	0AFh,07Fh		; 77
	db	0B0h,07Fh		; 78
	db	0B1h,07Fh		; 79
	db	0B2h,07Fh		; 7A
	db	0B3h,07Fh		; 7B
	db	0B4h,07Fh		; 7C
	db	0B5h,07Fh		; 7D
	db	0B6h,07Fh		; 7E
	db	0B7h,07Fh		; 7F

;======================================================================

	subttl	ctrl case of keyboard scan code translation table
	page

ctrltbl label	word
	scan = 0
					;scan code
					;=========
	db	0FFh,0FFh		; 00
	db	01Bh,001h		; 01 escape
	db	0FFh,0FFh		; 02 1
	db	000h,003h		; 03 2
	db	0FFh,0FFh		; 04 3
	db	0FFh,0FFh		; 05 4
	db	0FFh,0FFh		; 06 5
	db	01Eh,007h		; 07 6
	db	0FFh,0FFh		; 08 7
	db	0FFh,0FFh		; 09 8
	db	0FFh,0FFh		; 0A 9
	db	0FFh,0FFh		; 0B 0
	db	01Fh,00Ch		; 0C -
	db	0FFh,0FFh		; 0D =
	db	07Fh,00Eh		; 0E backspace
	db	000h,094h		; 0F tab
	db	011h,010h		; 10 q
	db	017h,011h		; 11 w
	db	005h,012h		; 12 e
	db	012h,013h		; 13 r
	db	014h,014h		; 14 t
	db	019h,015h		; 15 y
	db	015h,016h		; 16 u
	db	009h,017h		; 17 i
	db	00Fh,018h		; 18 o
	db	010h,019h		; 19 p
	db	01Bh,01Ah		; 1A [
	db	01Dh,01Bh		; 1B ]
	db	00Ah,01Ch		; 1C new-line
	db	004h,000h		; 1D lctrl
	db	001h,01Eh		; 1E a
	db	013h,01Fh		; 1F s
	db	004h,020h		; 20 d
	db	006h,021h		; 21 f
	db	007h,022h		; 22 g
	db	008h,023h		; 23 h
	db	00Ah,024h		; 24 j
	db	00Bh,025h		; 25 k
	db	00Ch,026h		; 26 l
	db	0FFh,0FFh		; 27 ;
	db	0FFh,0FFh		; 28 '
	db	0FFh,0FFh		; 29 `
	db	005h,000h		; 2A lshift
	db	01Ch,02Bh		; 2B \
	db	01Ah,02Ch		; 2C z
	db	018h,02Dh		; 2D x
	db	003h,02Eh		; 2E c
	db	016h,02Fh		; 2F v
	db	002h,030h		; 30 b
	db	00Eh,031h		; 31 n
	db	00Dh,032h		; 32 m
	db	0FFh,0FFh		; 33 ,
	db	0FFh,0FFh		; 34 .
	db	000h,095h		; 35 /
	db	006h,000h		; 36 rshift
	db	000h,096h		; 37 prtsc
	db	003h,000h		; 38 alt
	db	020h,039h		; 39 spacebar
	db	000h,000h		; 3A capslock
	db	000h,05Eh		; 3B f1
	db	000h,05Fh		; 3C f2
	db	000h,060h		; 3D f3
	db	000h,061h		; 3E f4
	db	000h,062h		; 3F f5
	db	000h,063h		; 40 f6
	db	000h,064h		; 41 f7
	db	000h,065h		; 42 f8
	db	000h,066h		; 43 f9
	db	000h,067h		; 44 f10
	db	009h,000h		; 45 numlock
	db	00Ah,000h		; 46 scrollock
	db	000h,077h		; 47 n7 home
	db	000h,08Dh		; 48 n8 uparrow
	db	000h,084h		; 49 n9 pgup
	db	000h,08eh		; 4A gray -
	db	000h,073h		; 4B n4 larrow
	db	000h,08fh		; 4C n5
	db	000h,074h		; 4D n6 rarrow
	db	000h,090h		; 4E gray +
	db	000h,075h		; 4F n1 end
	db	000h,091h		; 50 n2 darrow
	db	000h,076h		; 51 n3 pgdn
	db	000h,092h		; 52 n0 insert
	db	000h,093h		; 53 n. delete
	db	0FFh,0FFh		; 54 sysreq
	db	0FFh,0FFh		; 55
	db	0FFh,0FFh		; 56
	db	000h,089h		; 57 f11
	db	000h,08Ah		; 58 f12

; for citoh 7102

	db	0FFh,0FFh		; 59
	db	0FFh,0FFh		; 5A
	db	0FFh,0FFh		; 5B
	db	0FFh,0FFh		; 5C
	db	000h,076h		; 5D pgdn
	db	0FFh,0FFh		; 5E
	db	0FFh,0FFh		; 5F
	db	00Ah,060h		; 60 return
	db	000h,077h		; 61 home
	db	0FFh,0FFh		; 62
	db	000h,084h		; 63 pgup
	db	000h,073h		; 64 left
	db	000h,074h		; 65 right
	db	000h,075h		; 66 end
	db	0FFh,0FFh		; 67
	db	0D0h,07Fh		; 68 pf1 - pf24
	db	0D1h,07Fh		; 69
	db	0D2h,07Fh		; 6A
	db	0D3h,07Fh		; 6B
	db	0D4h,07Fh		; 6C
	db	0D5h,07Fh		; 6D
	db	0D6h,07Fh		; 6E
	db	0D7h,07Fh		; 6F
	db	0D8h,07Fh		; 70
	db	0D9h,07Fh		; 71
	db	0DAh,07Fh		; 72
	db	0DBh,07Fh		; 73
	db	0DCh,07Fh		; 74
	db	0DDh,07Fh		; 75
	db	0DEh,07Fh		; 76
	db	0DFh,07Fh		; 77
	db	0E0h,07Fh		; 78
	db	0E1h,07Fh		; 79
	db	0E2h,07Fh		; 7A
	db	0E3h,07Fh		; 7B
	db	0E4h,07Fh		; 7C
	db	0E5h,07Fh		; 7D
	db	0E6h,07Fh		; 7E
	db	0E7h,07Fh		; 7F


;======================================================================

	subttl	alt case of keyboard scan code translation table
	page

alttbl	label	word
	scan = 0
					;scan code
					;=========
	db	0FFh,0FFh		; 00
	db	0F0h,001h		; 01 escape
	db	000h,078h		; 02 1
	db	000h,079h		; 03 2
	db	000h,07Ah		; 04 3
	db	000h,07Bh		; 05 4
	db	000h,07Ch		; 06 5
	db	000h,07Dh		; 07 6
	db	000h,07Eh		; 08 7
	db	000h,07Fh		; 09 8
	db	000h,080h		; 0A 9
	db	000h,081h		; 0B 0
	db	000h,082h		; 0C -
	db	000h,083h		; 0D =
	db	0F0h,00Eh		; 0E backspace
	db	000h,0A5h		; 0F tab
	db	000h,010h		; 10 q
	db	000h,011h		; 11 w
	db	000h,012h		; 12 e
	db	000h,013h		; 13 r
	db	000h,014h		; 14 t
	db	000h,015h		; 15 y
	db	000h,016h		; 16 u
	db	000h,017h		; 17 i
	db	000h,018h		; 18 o
	db	000h,019h		; 19 p
	db	0F0h,01Ah		; 1A [
	db	0F0h,01Bh		; 1B ]
	db	000h,0A6h		; 1C new-line
	db	004h,000h		; 1D lctrl
	db	000h,01Eh		; 1E a
	db	000h,01Fh		; 1F s
	db	000h,020h		; 20 d
	db	000h,021h		; 21 f
	db	000h,022h		; 22 g
	db	000h,023h		; 23 h
	db	000h,024h		; 24 j
	db	000h,025h		; 25 k
	db	000h,026h		; 26 l
	db	0F0h,027h		; 27 ;
	db	0F0h,028h		; 28 '
	db	0F0h,029h		; 29 `
	db	005h,000h		; 2A lshift
	db	0F0h,02Bh		; 2B \
	db	000h,02Ch		; 2C z
	db	000h,02Dh		; 2D x
	db	000h,02Eh		; 2E c
	db	000h,02Fh		; 2F v
	db	000h,030h		; 30 b
	db	000h,031h		; 31 n
	db	000h,032h		; 32 m
	db	0F0h,033h		; 33 ,
	db	0F0h,034h		; 34 .
	db	0F0h,035h		; 35 /
	db	006h,000h		; 36 rshift
	db	0F0h,037h		; 37 prtsc
	db	003h,000h		; 38 alt
	db	020h,039h		; 39 spacebar
	db	000h,000h		; 3A capslock
	db	000h,068h		; 3B f1
	db	000h,069h		; 3C f2
	db	000h,06Ah		; 3D f3
	db	000h,06Bh		; 3E f4
	db	000h,06Ch		; 3F f5
	db	000h,06Dh		; 40 f6
	db	000h,06Eh		; 41 f7
	db	000h,06Fh		; 42 f8
	db	000h,070h		; 43 f9
	db	000h,071h		; 44 f10
	db	009h,000h		; 45 numlock
	db	00Ah,000h		; 46 scrollock
	db	00Bh,000h		; 47 n7 home
	db	00Bh,000h		; 48 n8 uparrow
	db	00Bh,000h		; 49 n9 pgup
	db	0F0h,04Ah		; 4A gray -
	db	00Bh,000h		; 4B n4 larrow
	db	00Bh,000h		; 4C n5
	db	00Bh,000h		; 4D n6 rarrow
	db	0F0h,04Eh		; 4E gray +
	db	00Bh,000h		; 4F n1 end
	db	00Bh,000h		; 50 n2 darrow
	db	00Bh,000h		; 51 n3 pgdn
	db	00Bh,000h		; 52 n0 insert
	db	00Ch,000h		; 53 n. delete
	db	0FFh,0FFh		; 54 sysreq
	db	0FFh,0FFh		; 55
	db	0FFh,0FFh		; 56
	db	000h,08Bh		; 57 f11
	db	000h,08Ch		; 58 f12

; for citoh 7102

	db	0FFh,0FFh		; 59
	db	0FFh,0FFh		; 5A
	db	0FFh,0FFh		; 5B
	db	0FFh,0FFh		; 5C
	db	000h,076h		; 5D pgdn
	db	0FFh,0FFh		; 5E
	db	0FFh,0FFh		; 5F
	db	00Ah,060h		; 60 return
	db	000h,077h		; 61 home
	db	0FFh,0FFh		; 62
	db	000h,084h		; 63 pgup
	db	000h,073h		; 64 left
	db	000h,074h		; 65 right
	db	000h,075h		; 66 end
	db	0FFh,0FFh		; 67
	db	0E8h,07Fh		; 68 pf1 - pf24
	db	0E9h,07Fh		; 69
	db	0EAh,07Fh		; 6A
	db	0EBh,07Fh		; 6B
	db	0ECh,07Fh		; 6C
	db	0EDh,07Fh		; 6D
	db	0EEh,07Fh		; 6E
	db	0EFh,07Fh		; 6F
	db	0F0h,07Fh		; 70
	db	0F1h,07Fh		; 71
	db	0F2h,07Fh		; 72
	db	0F3h,07Fh		; 73
	db	0F4h,07Fh		; 74
	db	0F5h,07Fh		; 75
	db	0F6h,07Fh		; 76
	db	0F7h,07Fh		; 77
	db	0F8h,07Fh		; 78
	db	0F9h,07Fh		; 79
	db	0FAh,07Fh		; 7A
	db	0FBh,07Fh		; 7B
	db	0FCh,07Fh		; 7C
	db	0FDh,07Fh		; 7D
	db	0FEh,07Fh		; 7E
	db	0FFh,07Fh		; 7F

;======================================================================

	subttl	moskey - hotkeys to switch between partitions
	page
;======================================================================
;,fs
; moskey - hotkeys to switch between partitions
;
; switching to partition number ax (0=foreground)
;
; in:	ds -> tcb for terminal to switch
;	ss -> tcb of screen terminal is viewing
;	ax = key code
;
; out:	none
;
;,fe
;======================================================================
	assume ds:nothing,es:nothing,ss:tcb
moskey proc near
	pushset ax,bx,cx,dx,di,ds,es
	xor	ah,ah
	mov	di,ds			; save terminal tcb
	mgetscb ds
	assume	ds:grp
	cmp	[inmoskey],0		; disallow reentrance
	je	mk4
mk5:
	jmp	mk_exit
mk4:
	mov	[inmoskey],1
	mov	[tcbswitch],al		; prepare to defer
	push	ss
	pop	es
	call	testvid 		; check ss task with testvid
	cmp	cl,1
	je	mk_defer
	ja	mk_drop
	cmp	[scb15act],0		; don't pam during i15suspend
	je	mk0
	mov	cx,ss
	cmp	[scb15tcb],cx
	je	mk_defer
mk0:
	cmp	[tcbstate],0		; if vmo vga/ega, only pam
	je	mk1
	cmp	[tcbmode],13h		; SAH don't allow pamswitch
	ja	mk_drop			; SAH if superVGA extended mode.	
	test	[tcbega],2		; when getkeys is called from tsl
	jnz	mk_defer
mk1:
	cmp	[tcbsiorb],0		; no pam when roadblock set
	jne	mk_defer
	mov	cx,[scbtcbpf]		; find the task to pam to
mk2:
	jcxz	mk_drop
	mov	es,cx
	assume	es:tcb,ss:nothing
	mov	cx,[tcbtcbpn]
	cmp	[tcbid],ax
	jne	mk2
	mov	cx,es
	cmp	[tcbcamon],0		; if task is terminating, only
	je	mk3			; allow pam home
	cmp	di,cx
	jne	mk_drop
mk3:
	cmp	[tcbslice],0		; don't pam to a dead task
	je	mk_drop
	mov	ds,di
	assume	ds:nothing
	call	checkvid		; cross station check
	jnz	mk_drop
	call	testvid 		; check es task with testvid
	cmp	cl,1
	je	mk_defer
	ja	mk_drop
	call	vidcheck		; check for special video cards
	cmp	al,1
	je	mk_defer
	ja	mk_drop
	call	mk_pam			; do the pamswitch
	jmp	short mk_drop
mk_defer:
	mov	[tcbswflg],'Y'		; setup for a retry
mk_drop:
	mgetscb ds
	assume	ds:grp
	mov	[inmoskey],0
mk_exit:
	popset	ax,bx,cx,dx,di,ds,es
	ret
moskey endp

	subttl mk_pam - helper for moskey
	page
;======================================================================
;,fs
; mk_pam - helper for moskey
;
; switching to partition number ax (0=foreground)
;
; in:	es -> tcb of new task to watch
;	ds -> tcb for terminal to switch
;	ss -> tcb of screen terminal is viewing
;
; out:	ax and dx crashed
;
;,fe
;======================================================================
	assume ds:nothing,es:tcb,ss:nothing
mk_pam proc near
	xor	ax,ax
	call	initioptbl		; clear all i/o protection
	push	es
	push	ss
	pop	es
	mov	al,1
	call	vgastate
	pop	es
	mov	dx,es
	pushset ds,es
	call	pamswitch		; do the pam
	popset	ds,es
	mov	al,2
	call	vgastate
	call	setegapal
	mov	ah,1
	call	vidcheck		; switch in special video
	mgetscb ds
	assume	ds:grp
	call	set_trap		; establish trapping state
	assume  es:tcb,ss:nothing
	mov	[tcbcon417],-1		; reset flag to force led change
	assume  ds:nothing,ss:tcb
	mov	[tcbswflg],'N'		; clear, just in case
	ret
mk_pam endp

	subttl	clichk - disables interrupts based on scbswvq
	page
;======================================================================
;,fs
; clichk - disables interrupts based on scbswvq
;
; disables interrupts based on scbswvq
;
; in:
;
; out:
;
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:nothing
clichk proc near
	push	ds
	mgetscb ds
	assume	ds:grp
	cmp	[scbswvq],'N'
	je	clichk1
	cli
clichk1:
	pop	ds
	assume	ds:nothing
	ret
clichk endp

	subttl	vidcheck - check for special video cards
	page
;======================================================================
;,fs
; vidcheck - check for special video cards
;
; this routine is added so that special video cards like the #9 card
; can know and verify when mos is going to switch video screens.
;
; in:	ah = function to call	(00 = switch out, 01 - switch in)
;	ss = tcb of current screen being viewed
;	es = tcb of task to attempt to switch to
;	ds = tcb of terminal screen viewing task
;
; out:	al = 00 all ok	to switch screens
;	al = 01 don't Switch, try later
;	al = 02 don't Switch, because driver can't do it
;
;,fe
;======================================================================
	assume ds:nothing,es:nothing,ss:nothing
vidcheck proc	near
	push	bx
	push	cx
	push	dx
	push	si
	push	di
	push	bp
	push	ds
	push	es
	mov	dx,ds			; sah do it before mgetscb
	mgetscb ds
	assume	ds:grp
	cmp	word ptr [scbvidchk+2],0; is driver installed
	je	vcskip
	mov	bx,ss
	mov	cx,es
	call	dword ptr [scbvidchk]	; call driver
	jmp	short	vcend
vcskip:
	xor	ax,ax
vcend:
	pop	es
	pop	ds
	pop	bp
	pop	di
	pop	si
	pop	dx
	pop	cx
	pop	bx
	ret
vidcheck endp

	subttl mapvd2vs - map es->tcb's vidram into the video save area
	page
;======================================================================
;,fs
; mapvd2vs - map es->tcb's vidram into the video save area
;
; in:	es->tcb of task for which vidram is to be mapped in
;
; out:
;
;,fe
;======================================================================
	assume	ds:nothing,es:tcb,ss:nothing
mapvd2vs proc near
	push	ax
	push	bx
	push	cx
	push	si
	push	di
	push	ds
	mgetscb ds
	assume	ds:grp
	xor	di,di

; this code checks for an attempt to map more pages into the vsa
; than there is room for.  it is needed becuase a pamswitch into or out
; of an ega/vga mode can end up executing through here.  hercules can
; also need page limiting calculations.

	mov	ax,[scbmastp]		; get max pages in vsa
	mov	bx,[tcbvmhdl]
	mov	si,[tcbvmhdl+2] 	; get handles and page counts
	mov	cx,[tcbvmpgs]
	mov	di,[tcbvmpgs+2]
	test	[tcbmode],80h		; if in herc mode
	jz	mapv1
	test	[tcb03b8],80h		; and using herc page 2
	jz	mapv1
	test	[tcb03bf],02h
	jz	mapv1

; enter here if need to map the second 32k of herc vidram into the 32k
; video save area.  must account for a split allocation of vidram.

	or	di,di			; simple case of one block?
	jz	mapv3			; yes
	cmp	di,8			; no, must handle two block case
	jae	mapv4
	add	bx,8			; use part of first block and all of second
	sub	cx,8
	jmp	mapv5
mapv3:
	mov	cx,ax			; presuming cx = 16 and ax = 8
	add	bx,8
	jmp	mapv5
mapv4:
	mov	bx,di			; bx = si + (di - 8)
	sub	bx,8			; the 2nd 32k lies totally in the second block
	add	bx,si			; so calc the portion of it to map
	xor	di,di
	jmp	mapv5

; enter here if mapping in a non-herc case, or herc from 1st 32k.
; must simply limit pages mapped to what is available.

mapv1:
	cmp	cx,ax			; enough room?
	jae	mapv2
	sub	ax,cx			; reduce available pages
	cmp	di,ax
	jna	mapv5
	mov	di,ax			; limit second block
	jmp	mapv5
mapv2:
	mov	cx,ax			; only first block will fit
	xor	di,di			; (or must be truncated)
mapv5:
	pushf
	call	clichk			; do a cli if scbswvq == 'Y'
	mov	al,1
	call	mapvsa			; do the map
	mov	[scbtcbvs],-1		; mark as dirty
	popf
	pop	ds
	pop	di
	pop	si
	pop	cx
	pop	bx
	pop	ax
	ret
mapvd2vs endp

	subttl updvdram - update vidram buffers for a master console task
	page
;======================================================================
;,fs
; updvdram - update vidram buffers for a master console task
;
; updvdram takes a task which has been running under a "con only"
; (vidram disabled) status, with a "master console" type of
; workstation, and enables vidram for that task.
;
; this routine was implemented by mjs on 3/15/88 in order to
; clean up pamswitching and secure it with regards to irq's which now
; switch video memory to support multiple mice.
; update 09/29/88 sah corrected for ega pamswitching
;
; in:	es -> task tcb
;	ds -> tcb of workstation
;
; out:
;
;,fe
;======================================================================
	assume	ds:nothing,es:tcb,ss:nothing
updvdram proc near
	cmp	[tcbstate],0		; sah no need to update
	je	updvd1
	ret
updvd1:
	call	clichk			; do a cli if scbswvq == 'Y'
	push	ax
	push	bx
	push	cx
	push	si
	push	di
	push	ds
	push	es
	call	noswitch
	push	ds
	mgetscb ds
	assume	ds:grp
	mov	[scbtcbvs],0
	call	swvidsave
	pop	ds
	assume	ds:nothing
	call	ddtsetup		; do common setup for a ddt call
	test	[tcbmode],80h		;jrbzz select appropriate hercules page
	jz	envd1			;jrbzz	 if needed
	mov	al,0			;jrbzz
	test	[tcb03b8],80h		;jrbzz
	jz	envd1			;jrbzz
	test	[tcb03bf],02h
	jz	envd1
	inc	al			;jrbzz
envd1:
	assume	ds:tcb,es:nothing
	mov	ah,0fh
	push	dx
	push	es
	call	ddtcallf		; check if busy and then call	; rg8188
	pop	es			; the video save buffer
	pop	dx
	assume	ds:nothing,es:tcb
	test	[tcbvram],01h		; if no vidram, all done
	jmpz	envd5
	test	[tcbmode],80h		;jrbzz
	jz	envd2			;jrbzz
	push	ds			;jrbzz
	push	es			;jrbzz
	pop	ds			;jrbzz
	call	hgctovr 		;jrbzz copy herc screen to vidram
	pop	ds			;jrbzz
	jmp	envd5			;jrbzz
envd2:
	push	ds
	mgetscb ds
	assume	ds:grp
	mov	[scbtcbvr],0
	call	swvidram		; map in vidram and update it from the
	pop	ds			; video save buffer
	assume	ds:nothing
	push	es
	mov	cx,[tcbpgln]
	shr	cx,1
	push	ax
	call	getmastv
	mov	ds,ax
	pop	ax
	xor	si,si
	mov	di,si
	mov	bx,[tcbvidw2]
	cmp	[tcbmode],4		; do a graphics mode copy or text mode??
	jmpb	envd4
	cmp	[tcbmode],7
	jmpe	envd4
	push	bp
	push	dx
	push	es
	mov	es,bx
	assume	es:nothing
	mov	ax,200/4
	mov	dx,40
	mov	bx,-2000h
	mov	bp,bx
envd3:
	mov	cx,dx			; copy graphics mode data from video save
	call	wordmove		; use fast word move (386/486)
	mov	cx,dx
	sub	di,cx
	sub	di,cx
	add	di,2000h
	call	wordmove		; use fast word move (386/486)
	mov	cx,dx
	add	di,bx
	rep	movsw
	mov	cx,dx
	sub	di,cx
	sub	di,cx
	add	di,2000h
	call	wordmove		; use fast word move (386/486)
	mov	cx,dx
	add	di,bp
	dec	ax
	jnz	envd3
	pop	es
	assume	es:tcb
	pop	dx
	pop	bp
	pop	es
	jmp	envd5
envd4:
	mov	es,bx
	call	wordmove		; use fast word move (386/486)
	pop	es			; buffer to vidram buffer
envd5:
	call	okswitch
	pop	es
	pop	ds
	pop	di
	pop	si
	pop	cx
	pop	bx
	pop	ax
	sti
	ret
updvdram endp

	subttl ddtsetup - do common setup for a ddt call
	page
;======================================================================
;,fs
; ddtsetup - do common setup for a ddt call
;
; in:	es->tcb of task
;	ds->tcb of terminal
;
; out:
;
;,fe
;======================================================================
	assume	ds:nothing,es:tcb,ss:nothing
ddtsetup proc near
	mov	si,offset [tcbcondd]
	call	getmastv
	mov	[si+6],ax
	mov	cx,[tcbpgln]
	shr	cx,1
	mov	ax,[tcbpgst]		; offset into screen of active page
	mov	[si+4],ax
	mov	word ptr [si+8],0
	mov	ah,[tcbcols]		; cols / line on screen
	mov	[si+10],ah
	ret
ddtsetup endp

	subttl vramtosave - update video save buffer from vidram
	page
;======================================================================
;,fs
; vramtosave - update video save buffer from vidram
;
; call a special entry point to force a vidram update.
;
; in:	ds->tcb to test for hercules
;
; out:
;
;,fe
;======================================================================
	assume	ds:tcb,es:nothing,ss:nothing
vramtosave proc near
	test	[tcbmode],80h		;jrbzz
	jz	pamsw3a 		;jrbzz
	push	ds			;jrbzz
	push	ss			;jrbzz
	pop	ds			;jrbzz
	call	vrtohgc 		;jrbzz copy vidram to hercules
	pop	ds			;jrbzz
	jmp	vrm2sv			;jrbzz	 graphics screen
pamsw3a:
	push	ax
	push	bx
	push	cx
	push	dx
	push	si
	push	di
	push	ds
	push	es
	call	vidram1a		; use special entry since this task will
	pop	es			; look like cononly
	pop	ds
	pop	di
	pop	si
	pop	dx
	pop	cx
	pop	bx
	pop	ax
vrm2sv:
	push	ax
	mov	ax,ds
	call	swrealram
	pop	ax
	ret
vramtosave endp

	subttl vrtohgc - copy vidram to hercules display
	page
;======================================================================
;,fs
; vrtohgc - copy vidram to hercules display
;
; display is in hercules graphics mode
; display is becoming cononly
; copy full hercules buffer if allocated,
; set physical display page number
; map first 32k of vidram to screen save area and copy to screen
; if vidram is 64k, map second 32k to screen save area
; and copy to screen
;
; in:	ds -> tcb for vidram
;	ds->tcbscrdd -> tcb for display
;
; out:
;
;,fe
;======================================================================
	assume	ds:tcb,es:nothing,ss:nothing
vrtohgc proc near
	push	es
	push	di
	push	si
	push	dx
	push	cx
	push	bx
	call	hgctoram
	mov	bx,0			; first 8 pages
	call	vidtovs
	mov	es,[tcbvidw2]
	push	ds
	call	getmastv
	mov	ds,ax
	call	cpyhgc
	pop	ds
	test	[tcbvideo],20h		; hg2?
	jz	vrtohgx
	mov	bx,8			; second 8 pages
	call	vidtovs
	mov	bx,[tcbvidw2]
	or	bh,08h
	mov	es,bx
	push	ds
	call	getmastv
	mov	ds,ax
	call	cpyhgc
	pop	ds
vrtohgx:
	mov	al,80h			; set current display page
	test	[tcb03b8],80h
	jz	vrtohgy
	test	[tcb03bf],02h
	jz	vrtohgy
	mov	al,0c0h
vrtohgy:
	mov	ah,03h
	push	ds
	mov	ds,[tcbscrdd]
	mov	si,offset [tcbcondd]
	call	ddtcallf		; check if busy and then call	; rg8188
	pop	ds
	pop	bx
	pop	cx
	pop	dx
	pop	si
	pop	di
	pop	es
	ret
vrtohgc endp

	subttl hgctovr - copy hercules display to vidram
	page
;======================================================================
;,fs
; hgctovr - copy hercules display to vidram
;
; display is in hercules graphics mode
; display will no longer be cononly
; copy full hercules buffer if allocated
; set physical display page number
; map first 32k of vidram to screen save area and copy from screen
; if vidram is 64k map second 32k to screen save area
; and copy from screen
;
; in:	ds -> tcb for vidram
;	ds->tcbscrdd -> tcb for display
;
; out:
;
;,fe
;======================================================================
	assume	ds:tcb,es:nothing,ss:nothing
hgctovr proc near
	push	es
	push	di
	push	si
	push	dx
	push	cx
	push	bx
	call	hgctoram
	mov	bx,0			; first 8 pages
	call	vidtovs
	call	getmastv
	mov	es,ax
	push	ds
	mov	ds,[tcbvidw2]
	call	cpyhgc
	pop	ds
	test	[tcbvideo],20h		; hg2?
	jz	hgtovr1
	mov	bx,8			; second 8 pages
	call	vidtovs
	call	getmastv
	mov	es,ax
	mov	bx,[tcbvidw2]
	or	bh,08h
	push	ds
	mov	ds,bx
	call	cpyhgc
	pop	ds
hgtovr1:
	test	[tcb03b8],80h
	jz	hgtovr2
	test	[tcb03bf],02h
	jz	hgtovr2
	push	es
	push	ds
	mov	ax,[tcbvidw2]
	mov	es,ax
	or	ah,08h
	mov	ds,ax
	call	cpyhgc
	pop	ds
	pop	es
hgtovr2:
	mov	al,80h			; set current display page to 0
	mov	ah,3
	push	ds
	mov	ds,[tcbscrdd]
	mov	si,offset [tcbcondd]
	call	ddtcallf		; check if busy and then call	; rg8188
	pop	ds
	pop	bx
	pop	cx
	pop	dx
	pop	si
	pop	di
	pop	es
	ret
hgctovr endp

	subttl hgctoram - expose physical display
	page
;======================================================================
;,fs
; hgctoram - expose physical display
;
; in:
;
; out:
;
;,fe
;======================================================================
hgctoram proc near
	assume	ds:tcb,es:nothing,ss:nothing
	push	ax
	mov	ax,ds
	call	swrealram
	pop	ax
	ret
hgctoram endp

	subttl vidtovs - map vidram to video save area
	page
;======================================================================
;,fs
; vidtovs - map vidram to video save area
;
; map vidram starting at page offset bx video save area
;
; in:
;
; out:
;
;,fe
;======================================================================
	assume	ds:tcb,es:nothing,ss:nothing
vidtovs proc near
	push	ax
	push	dx
	push	di
	push	ds
	add	bx,[tcbvmhdl]
	mgetscb ds
	assume	ds:grp
	pushf
	call	clichk			; do a cli if scbswvq == 'Y'
	mov	[scbtcbvs],-1		; mark vsa as dirty
	mov	cx,8
	xor	di,di
	mov	al,1
	call	mapvsa
	popf
	pop	ds
	pop	di
	pop	dx
	pop	ax
	ret
vidtovs endp

	subttl cpyhgc - copy between hgc and vidram buffers
	page
;======================================================================
;,fs
; cpyhgc - copy between hgc and vidram buffers
;
; in:
;
; out:
;
;,fe
;======================================================================
cpyhgc proc near
	xor	di,di
	xor	si,si
	mov	cx,348/4*90/2
	call	wordmove		; use fast word move (386/486)
	add	di,2000h-348/4*90
	mov	si,di
	mov	cx,348/4*90/2
	call	wordmove		; use fast word move (386/486)
	add	di,2000h-348/4*90
	mov	si,di
	mov	cx,348/4*90/2
	call	wordmove		; use fast word move (386/486)
	add	di,2000h-348/4*90
	mov	si,di
	mov	cx,348/4*90/2
	call	wordmove		; use fast word move (386/486)
	ret
cpyhgc endp

	subttl ifgr - test for graphics mode
	page
;======================================================================
;,fs
; ifgr - test for graphics mode
;
; in:	ds -> tcb
;
; out:	return z if ddt supports graphics or isn't in graphics mode
;	return nz if ddt in graphics mode and doesn't support graphics
;
;,fe
;======================================================================
	assume	ds:tcb,es:nothing,ss:nothing
ifgr proc near
	test	[tcbvram],10h		;#jrba no display unless ddt supports it
	jnz	ifgr2			;#jrba
	cmp	[tcbstation],05h	; monochrome ega or vga station
	jae	ifgr2
	test	[tcbvram],40h		;#jrba
	jz	ifgr1			;#jrba
	cmp	[tcbcmode],80h		;#jrba
	jne	ifgr2			;#jrba
ifgr1:					;#jrba
	cmp	[tcbcmode],4
	jb	ifgr2
	cmp	[tcbcmode],7
	je	ifgr2
	cmp	[tcbtype],0		; set nz for can't
	ret
ifgr2:
	cmp	al,al			; set z for can
	ret
ifgr endp

	subttl	pamswitch - allow terminals to view different partitions
	page
;======================================================================
;,fs
; pamswitch - allow terminals to view different partitions
;
; in:	ss -> tcb terminal is currently viewing
;	ds -> tcb for this terminal
;	dx -> new tcb for terminal to view
;
; out:	none
;	ds + others are crashed
;
;,fe
;======================================================================
	assume	ds:tcb,es:nothing,ss:nothing
pamswitch proc near

; make sure this terminal can look at this partition.

	mov	es,dx
	assume	ds:nothing,es:tcb
	mov	al,[tcbclass]		; task partition default class
	assume	ds:tcb,es:nothing
	callmos2 classbits		; class permissions for terminal
	or	al,al
	jnz	pamsw010		; z if access denied
	ret
pamsw010:
	mgetscb es
	assume	es:grp
	push	[scblastff]		; save the current bank selection status

; start by determining the link position of the ds->tcb terminal
; within the tcbscrdd/tcbnxtdd chain of the ss->tcb task that the
; ds-tcb terminal is now watching.

	mov	byte ptr [pamskip],1	; set flag for int8 handling logic
	mov	[vdrskip],'Y'		; don't do vidram updates while
	mov	cx,ds			; everything is in a state of flux
	push	ss
	pop	es
	assume	ds:nothing,es:tcb
	cmp	cx,[tcbscrdd]		; if ds->tcb == ss:[tcbscrdd] then the
	mov	es,[tcbscrdd]		; terminal is linked as the first one to
	jne	pamsw030		; the ss-> tcb task.

; the ds->tcb terminal is the first one linked to the ss->tcb task.

	cmp	[tcbnxtdd],0
	jne	pamsw020

; this terminal is the only one linked.

	push	ds
	push	ss
	pop	ds
	push	cs
	call	near ptr nosbuf
	pop	ds
	jnz	pamsw020		; nz if not master console only

; when the ss->tcb task that the ds->tcb terminal is currently
; watching is master console only, the unlinking process will cause
; this task to go from a vidram disabled state to a vidram enabled one.
; in this case, call updvdram to enable vidram for the ss-> tcb task.

	assume	ds:nothing,es:nothing,ss:tcb
	push	ss
	pop	es
	call	updvdram

; time to unlink the terminal from the task is has been watching.
; either the ds->tcb terminal is first in link order (and if its
; master console only it has already been taken care of), or there are
; other terminals so it doesn't matter if it's the master console.

pamsw020:
	assume	ds:tcb,es:nothing,ss:nothing
	mov	ax,[tcbnxtdd]		; unlink the ds->tcb terminal from the
	assume	ds:nothing,ss:tcb	; ss->tcb task it has been watching
	mov	[tcbscrdd],ax
	jmp	pamsw050

; this terminal isn't the first in the list so look through list of
; terminals for this screen to find this one (note it can't be the only
; terminal or the test above would catch it so it doesn't matter if
; it's the master console).

pamsw030:
	assume	ds:nothing,es:tcb,ss:nothing
	mov	ax,[tcbnxtdd]
	cmp	cx,ax
	je	pamsw040
	or	ax,ax
	mov	es,ax
	jnz	pamsw030

; internal error, couldn't find it in the list

	call	bugerror
	db	'e0 - terminal not in list       ',0  ;@@xlat

; time to unlink the terminal from the task is has been watching.
; es -> prior tcb in list

pamsw040:
	assume	ds:tcb,es:nothing,ss:nothing
	mov	ax,[tcbnxtdd]		; the tcb following the terminal is
	assume	ds:nothing,es:tcb	; now linked to the preceding tcb
	mov	[tcbnxtdd],ax

; if vidram is active and the unlinking of the ds->tcb terminal from
; ss->tcb task has resulted in the ss->tcb task now being in a master
; console only state, one last vidram check must be done just in case
; any direct video writes went into the vidram buffer since the last
; vidram check via dopoll.  then, real ram must be exposed for the
; ss->tcb task.  if this were not done, display data could be lost
; during pamswitching's transitions.

pamsw050:
	assume	ds:nothing,es:nothing,ss:tcb
	test	[tcbvram],01h
	push	ds			; if vidram is active
	push	ss			; and ss->tcb task now master console only
	pop	ds			; force a vidram check and expose real ram
	jz	pamsw060
	push	cs
	call	near ptr nosbuf
	jnz	pamsw060
	call	vramtosave

; the unlinking process is now complete.  the ds->tcb terminal is not
; viewing any task and the ss->tcb task has been placed in a stable
; state.  now finished with ss, ds still points to the terminal tcb,
; dx still points to the tcb of task which is to be viewed by the
; ds->tcb terminal.

pamsw060:
	pop	ds
	mov	es,dx
	assume	ds:nothing,es:tcb,ss:nothing

; from now on, es points to the tcb of the new task to be viewed by the
; ds->tcb terminal.
;
; if a master console only workstation is presently the only watcher
; for the es->tcb task, this es->tcb task will be going from a vidram
; disabled state to a vidram enabled one when the ds->tcb task terminal
; is linked in.  to prepare for this transition, call updvdram to
; update the vidram and video save buffers for the es->tcb task.

	push	ds
	mov	ds,dx
	push	cs
	call	near ptr nosbuf
	jmpnz	pamsw070
	mov	ds,[tcbscrdd]
	call	updvdram

; now prepared to insert the ds->tcb terminal into the
; tcbscrdd/tcbnxtdd list for the es->tcb task.

pamsw070:
	pop	ds
	assume	ds:nothing,es:tcb,ss:nothing
	mov	ax,[tcbscrdd]
	mov	[tcbscrdd],ds
	assume	ds:tcb,es:nothing
	mov	[tcbnxtdd],ax		; so now it's inserted
	mov	[tcbwatch],es		; record task this wks is watching
	assume	ds:nothing,es:tcb
	or	ax,ax			; if nobody has been looking, set a flag
	jnz	pamsw080		; to force a vidram update just before
	test	[tcbvram],1		; copying vidram data to the display
	jz	pamsw080
	or	[tcbpamfg],1		; set force vidram flag for switchgp

; set the terminal to the new screen's mode but be bright about whether
; it actually needs to physically change since clearing isn't really
; necessary if that's all to do.

pamsw080:
	assume	ds:tcb,es:nothing
	mov	cl,[tcbcmode]
	assume	ds:nothing,es:tcb
	cmp	cl,[tcbmode]
	jne	$+5			; if terminal's mode == task's mode, skip
	jmp	pamsw140		; all this stuff
	mov	al,[tcbmode]
	assume	ds:tcb,es:nothing
	cmp	[tcbcondd.dcpherc],'Y'	; if the terminal isn't herc
	je	pamsw090		; and trying to put it in a herc
	cmp	al,80h			; mode then skip the ddt call
	jne	pamsw090		; to set the mode
	jmp	pamsw140
pamsw090:
	mov	[tcbcmode],al		; go ahead and record task's mode in
	assume	ds:nothing,es:tcb	; the terminal's tcb
	cmp	al,7
	je	pamsw100
	xchg	cl,al
	cmp	al,7
	jne	pamsw110
pamsw100:				; new mode is 7, terminal mode isn't 7
	and	cl,not 01h
	cmp	cl,2
	jne	pamsw120
	jmp	pamsw140
pamsw110:				; neither new mode nor terminal mode is 7
	xor	al,cl
	and	al,not 01h		; some highly optimzed bit flipping no doubt!
	je	pamsw140
pamsw120:
	push	es
	call	ddtsetup		; do common setup for a ddt call
	mov	al,[tcbmode]
	assume	ds:tcb,es:nothing
	mov	ah,03h			; set mode
	push	bx
	push	es
	mov	bx,bios
	mov	es,bx
	assume	es:bios
	push	[crtregs]		; save 3x8, 3x9 setting and pallette
	push	es
	call	ddtcallf		; check if busy and then call	; rg8188
	pop	es
	pop	[crtregs]
	pop	es
	pop	bx
	pop	es			; restore tcb switched to

; set the terminal's cursor to the new screen's cursor type.

pamsw140:
	assume	ds:nothing,es:tcb
	test	[tcbmode],80h		; no palette or cursor type if in hercules
	jmpnz	pamsw150		;   graphics mode
	push	es
	call	ddtsetup		; do common setup for a ddt call
	mov	bl,[tcbpage]
	xor	bh,bh
	shl	bx,1
	mov	dx,[tcbcpos+bx]
	mov	cx,[tcbctyp]
	mov	al,[tcbmode]		;sah look below - it depends on this
	assume	ds:tcb,es:nothing
	push	bx			; sah point 40:49 to mode of screen
	mov	bx,bios 		; sah point bios seg
	mov	es,bx
	assume	es:bios
	pop	bx
	push	word ptr [crtmode]	; sah save current bios mode
	mov	[crtmode],al		; sah set new mode for call
	mov	ah,04h
	call	ddtcallf		; check if busy and then call	; rg8188
	pop	word ptr [crtmode]	; sah get old bios mode
	pop	es			; restore tcb switched to
	assume	ds:nothing,es:tcb

; set the terminal palette and background to the new screen's.

	push	es
	call	ddtsetup		; do common setup for a ddt call
	mov	bl,[tcbpal]
	assume	ds:tcb,es:nothing
	mov	ah,09h
	call	ddtcallf		; check if busy and then call	; rg8188
	pop	es			; restore tcb switched to
	assume	ds:nothing,es:tcb

; if the es->tcb task is becoming master console only and is in
; hercules graphics mode, call vrtohgc to copy from vidram to real ram.

pamsw150:
	push	ds
	push	es
	pop	ds
	push	cs
	call	near ptr nosbuf
	pop	ds
	jnz	pamsw160		; nz is not mc only
	test	[tcbmode],80h
	jz	pamsw160
	push	ds			; in herc graphics mode
	push	es
	pop	ds
	call	vrtohgc 		; map in vidram and copy to hercules display
	pop	ds
	jmp	pamsw240

; now we want to map the es->tcb task's vidram into the video save
; area so we will have access to the most up to date image for the
; es->tcb task.  for the non-vidram case (usually non-mm), call
; swvidsave to update the scbmastv pointer.

pamsw160:
	test	[tcbvram],1
	jz	pamsw170
	call	mapvd2vs		; map es->tcb's vidram into video save area
	jmp	pamsw180
pamsw170:
	push	ds
	mgetscb ds
	call	swvidsave
	pop	ds

; vidram now mapped into the video save area, now set up parms for the
; call to the ddt to do the copy.

pamsw180:
	call	ddtsetup		; do common setup for a ddt call
	mov	al,0
	test	[tcbmode],80h
	jnz	pamsw190
	assume	ds:tcb,es:nothing
	mov	al,[tcbwinpo]		; row into screen buffer to start
pamsw190:
	call	ifgr			; nz if screen in graphics mode
	jmpnz	pamsw240		; and ddt doesn't support graphics
	push	ds
	mgetscb ds
	assume	ds:grp
	test	[scbmmfea],80h
	pop	ds
	assume	ds:tcb
	jnz	pamsw200
	cmp	[tcbcmode],4
	jb	pamsw200
	cmp	[tcbcmode],7
	ljne	pamsw220
pamsw200:
	assume	ds:nothing,es:tcb
	cmp	[tcbstate],0		;sah skip the following call if
	ljne	pamsw240		;sah if under ega state logic

; the following manipulations of the video mapping variables are necessary
; to handle the case where the new watcher (ds->tcb) is a serial terminal
; and the serial.sys output buffer is small enough that it will fill before
; the update can complete.  when this happens, serial.sys calls suspend to
; allow other tasks some execution time while the serial buffer empties.
; since pamswitching has setup non-standard video mapping conditions at this
; point, some extra manipulations must be done to insure that these special
; conditions will be restored when the ss->tcb task gets switched back in.
; by temporarily changing the values in tcbvidh1 and tcbvidp1, the tsl logic
; can be made to restore the vsa as required.  unmapping the vma is done
; by explicit code.  tcbslice of the es->tcb task, the task to be viewed, is
; set to 0 to prevent this task from changing its video until it can be fully
; updated to the new watcher.

; note: all of this kludgey code will be unnecessary when the list based
; call logic is put in

	mov	dl,al
	mov	al,[tcbslice]
	push	ax
	mov	ax,es
	mov	bx,ss
	cmp	ax,bx
	je	pamsw200e
	mov	byte ptr [tcbslice],0
pamsw200e:
	push	es
	mgetscb es
	assume	ds:nothing,es:grp,ss:tcb
	mov	[forcevsa],'Y'
	push	[tcbvidh1]
	push	[tcbvidp1]
	cli
	push	[scbvsahdl]
	pop	[tcbvidh1]
	push	[scbvsacnt]
	pop	[tcbvidp1]
	sti
	push	[scbtcbvs]
	push	[scbtcbvr]
	push	[scbvmaal]		; save mapping state
	push	[scbvmahdl]
	push	[scbvmacnt]
	push	[scbvmahdl+2]
	push	[scbvmacnt+2]
	push	[scbvmaseg]
	mov	al,dl
	push	es
	mov	ah,0ch
	call	ddtcallf		; check if busy and then call	; rg8188
	pop	es

; if a task switch was done from within serial.sys, the vsa mapping will have
; already been restored due to the manipulation of tcbvidh1 and tcbvidp1.
; now its time to restore the vma mapping state (which should be unmapped).
; if last action, before the ddtcall was an unmap then must unmap now but use
; the segment and page count currently in scbvmaseg and scbvmacnt (and cnt+2)
; else if the current mapping (from the switchgp above) was at a different
; segment or had a greater page count than the original mapping then the
; current mapping must be unmapped before restoring the previous mapping

; future  be able to access the memory manager's page table directly and just
; save the chunk of it that pertains to the entire video memory area.  then,
; when need to restore the mapping, can just make one list based call.

; common code with swcall - when convert to list based, make one subroutine.

	call	clichk			; do a cli if scbswvq == 'Y'
	pop	dx
	pop	di
	pop	si			; pop saved mapping vars
	pop	cx
	pop	bx
	pop	ax
	push	ds
	mgetscb ds
	assume	ds:grp,es:nothing
	or	dx,dx			; check for no video mapping case
	jz	pamsw200d
	or	al,al			; originally in an unmapped state?
	jz	pamsw200a
	cmp	al,2			; is this physical remap call
	je	pamsw200a
	cmp	al,3			; is this list map for sunriver
	je	pamsw200d
	cmp	dx,[scbvmaseg]		; different segment?
	jne	pamsw200a
	push	ax
	push	cx
	mov	ax,[scbvmacnt]
	add	ax,[scbvmacnt+2]
	add	cx,di
	cmp	ax,cx			; more pages in now than originally?
	pop	cx
	pop	ax
	ja	pamsw200b		; if same seg and not more pages then can
	jmp	pamsw200c		; simply map original over current
pamsw200a:
	mov	dx,[scbvmaseg]		; when orignally unmapped, must now unmap
	mov	cx,[scbvmacnt]		; what the task switch put in the vma
	add	cx,[scbvmacnt+2]
	jmp	pamsw200c
pamsw200b:
	push	ax			; if different segment or more pages at same
	push	cx			; segment then must unmap current before
	push	dx			; restoring previous mapping
	xor	al,al
	mov	dx,[scbvmaseg]
	mov	cx,[scbvmacnt]
	add	cx,[scbvmacnt+2]
	call	mapvma
	pop	dx
	pop	cx
	pop	ax
pamsw200c:
	call	mapvma			; restore the vma
pamsw200d:
	pop	ds
	assume	ds:nothing,es:grp
	pop	[scbtcbvr]
	pop	[scbtcbvs]
	pop	[tcbvidp1]
	pop	[tcbvidh1]
	mov	[forcevsa],'N'
	pop	es
	assume	es:tcb,ss:nothing
	pop	ax
	mov	[tcbslice],al		; allow the es->tcb to run again
	sti
	jmp	pamsw240

; this section handles displaying a graphics screen in the non mm case.
; in order to reach this point, the call to the ifgr proc (above)
; must return zr (to say that the screen is in a graphics mode and
; the ddt must support graphics) and must not have memory management
; and tcbcmode must be >= 4 but not 7.

pamsw220:
	push	ds
	push	es
	push	bp
	assume	ds:nothing,es:tcb
	mov	ds,[tcbbegad]		; ds:si -> video save area
	xor	si,si
	mov	es,[tcbvidw2]		; es:di -> video memory
	assume	es:nothing
	xor	di,di
	mov	ax,200/4
	mov	dx,40
	mov	bx,-2000h
	mov	bp,bx
pamsw230:
	mov	cx,dx
	call	wordmove		; use fast word move (386/486)
	mov	cx,dx
	sub	di,cx
	sub	di,cx
	add	di,2000h
	call	wordmove		; use fast word move (386/486)
	mov	cx,dx
	add	di,bx
	call	wordmove		; use fast word move (386/486)
	mov	cx,dx
	sub	di,cx
	sub	di,cx
	add	di,2000h
	call	wordmove		; use fast word move (386/486)
	mov	cx,dx
	add	di,bp
	dec	ax
	jnz	pamsw230
	pop	bp
	pop	es
	pop	ds

; set the terminal cursor to the new screen's cursor position.

pamsw240:
	assume	ds:nothing,es:tcb,ss:nothing
	test	[tcbmode],80h		; don't bother with cursor if
	jnz	pamsw250		;   hercules graphics mode
	mov	si,offset [tcbcondd]
	call	getmastv
	mov	[si+6],ax
	mov	cx,[tcbpgln]
	shr	cx,1
	mov	bl,[tcbpage]
	xor	bh,bh
	shl	bx,1
	mov	al,[tcbcols]
	mov	dx,[tcbcpos+bx]
	mul	dh
	xor	dh,dh
	add	ax,dx
	shl	ax,1
	mov	[si+8],ax		; offset into page of cursor
	add	ax,[tcbpgst]		; offset into screen of cursor
	mov	[si+4],ax		; offset into screen of cursor
	mov	ah,[tcbcols]		; cols / line on screen
	mov	[si+10],ah
	mov	bl,[tcbpage]
	xor	bh,bh
	shl	bx,1
	mov	dx,[tcbcpos+bx]
	assume	ds:tcb,es:nothing
	mov	ah,05h
	call	ddtcallf		; check if busy and then call  ; rg8188
pamsw250:
	mov	dx,ds
	mgetscb ds
	assume	ds:grp,es:tcb
;
; is the workstation being switched the master console?
; updated 01/02/90 SAH
;
	push	es
	mov	es,[scbtcbpf]
	mov	es,[tcbwatch]
	mov	[scbmconly],0		; indicated not master cononly
	mov	bx,[tcbscrdd]
	or	bx,bx
	jz	pamsw250a		; no one viewing mc, not mc-only
	mov	es,bx
	cmp	[tcbnxtdd],0
	jne	pamsw250a		; more than just master console is
					; viewing
;
	inc	[scbmconly]		; if and only if master console is
					; is viewing a single task
pamsw250a:
	pop	es
;
; update keyboard repeat rate to match new task being viewed
; only if on master console is viewing it
;
	cmp	dx,[scbtcbpf]
	jne	pamsw260
	test	[scbmmfea],40h
	jz	pamsw260
	cmp	[scbkbrate],0ffh
	je	pamsw260
	lds	si,[scbioptr]
	assume	ds:nothing
	cli
	mov	bl,[si+12]
	and	byte ptr [si+12],not 00001011b
	push	bx
	mov	bl,[tcbkbrate]
	call	set_kbrate
	pop	bx
	mov	[si+12],bl
	sti
pamsw260:

; at this point:
; es -> tcb new task to be viewed
; dx -> tcb of workstation being switched
; ss -> tcb of old task viewed

; update the tcbconly flag in each of the two affected tasks

	mov	ax,ss
	mov	ds,ax
	call	set_conly
	mov	ax,es
	mov	ds,ax
	call	set_conly

; the es->tcb task's screen has been displayed to the ds->tcb terminal.
; now, if the ss->tcb task is now master console only, insure it is
; left in the proper state by exposing real ram.  if not master console
; only, insure that its video save buffer is mapped into the video save
; area and that its vidram buffer is mapped in.

	mov	ds,dx
	assume	ds:nothing,es:tcb
	and	[tcbpamfg],not 1	; insure flags are reset
	assume	ds:nothing,es:nothing,ss:tcb
	test	[tcbvram],1
	jnz	pamsw265		; does the ss->tcb task have vidram support?
	pop	ax
	jmp	pamsw280		; if not, must get original scblastff off of
pamsw265:				; the stack before exiting
	push	ss
	pop	ds			; is the ss->tcb task now mc only?
	push	cs
	call	near ptr nosbuf
	jnz	pamsw270		; if not mc only, make sure vidram/video save
	mov	ax,ss			; is back in place
	call	swrealram		; else expose real ram
	pop	ax			; throw away original scblastff value
	jmp	pamsw280
pamsw270:
	mgetscb ds
	assume	ds:grp
	push	ss
	pop	es			; put vidram and video save back in place
	call	clichk			; do a cli if scbswvq == 'Y'
	mov	[scbtcbvr],0
	call	swvidram
	mov	[scbtcbvs],0
	call	swvidsave
	sti
	push	ds
	pop	es
	assume	es:grp,ds:nothing
	pop	ds			; recover original scblastff to restore

; now do a special version of ffh call which will switch workstation
; in but will not alter the video memory.  this is done by setting
; scbbankin to 'N' and calling ffh handler.  workstation drivers which
; do their own video mapping (ie srterm.sys) need to check scbbankin
; inside there ffh handler.

	mov	si,offset [tcbcondd]	; the bank selection state
	mov	ah,0ffh
	call	clichk			; do a cli if scbswvq == 'Y'
	mov	[scbbankin],'N' 	; do this to prevent an unmap in ddtmc
	call	dword ptr [si]		; don't need to use ddtcall here
	mov	[scbbankin],'Y' 	; restore banking to normal
	sti
pamsw280:
	mgetscb es
	mov	byte ptr [pamskip],0
	mov	[vdrskip],'N'		; allow vidram updating
	ret
pamswitch endp

	subttl set_kbrate - set the keyboard repeat rate
	page
;======================================================================
;,fs
; set_kbrate - set the keyboard repeat rate
;
; in:	bl = the repeat rate in 8042 command format
;
; out:	bx crashed
;
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:nothing
set_kbrate proc near
	push	cx
	push	ds
	mgetscb ds
	assume	ds:grp
	mov	ax,0305h
	mov	bh,bl
	and	bx,601fh
	mov	cl,5
	shr	bh,cl
	pushf
	call	dword ptr [i16old]
	pop	ds
	assume	ds:nothing
	pop	cx
	ret
set_kbrate endp

	subttl doswitch - do context switch with no video
	page
;======================================================================
;,fs
; doswitch - do context switch with no video
;
; switch task context but no video - for use during pamming
; this is necessary because vga pallettes in bios need to be access
;
; in:	ax -> tcb
;
; out:
;
;,fe
;======================================================================
doswitch proc near
	push	bx
	push	ds
	push	es
	mgetscb ds
	mov	es,ax
	call	switchtask		; switch task
	pop	es
	pop	ds
	pop	bx
	ret
doswitch endp

	subttl doi10 - call original int10 bios
	page
;======================================================================
;,fs
; doi10 - call original int10 bios
;
; in:	int10 parms
;
; out:	int10 parms
;
;,fe
;======================================================================
	assume	ds:grp
doi10 proc	near
	push	ds
	mgetscb ds
	pushf
	call	i10old			; sah call original vga bios
	pop	ds
	ret
doi10 endp

	subttl i10fun10 - controlled int10fun10 call
	page
;======================================================================
;,fs
; i10fun10 - controlled int10fun10 call
;
; this code presumes that the bios int10 function 10 call will not
; need nor change the ds, si and bp registers
;
; in:	ds -> grp
;
; out:
;
;,fe
;======================================================================
	assume	ds:grp,es:nothing,ss:nothing
i10fun10 proc near
	test	[scbmmfea],40h		; is i/o protection supported?
	jnz	se1
	call	doi10
	jmp	short se2
se1:
	mov	[palovr],1		; set flag for the int6 logic
	push	bp
	sub	sp,2			; reserve storage at [bp]
	mov	bp,sp
	push	si
	push	ds
	lds	si,[scbioptr]		; get pointer to memman data
	push	bx
	mov	bl,[si+123]
	mov	[bp],bl 		; save original trapping state
	pop	bx
	or	byte ptr [si+123],00000100b  ; turn on port 3da protection
	push	bp
	call	doi10
	pop	bp
	push	bx
	mov	bl,[bp]
	mov	[si+123],bl		; restore trapping state
	pop	bx
	pop	ds
	pop	si
	add	sp,2
	pop	bp
	mov	[palovr],0
se2:
	ret
i10fun10 endp

	subttl setegapal - set ega pallettes for new task.
	page
;======================================================================
;,fs
; setegapal - set ega pallettes for new task.
;
; sets the ega pallettes of new tcb being switch to if station
; supports ega or vga.	note: if so, tcb was be switch into
; memory because ega bios depends on memory being in memory for
; that task.
;
; in:	ds -> tcb of station in use
;	es -> tcb of task to switch to.
;
; out:
;
;,fe
;======================================================================
	assume	ds:tcb,es:nothing,ss:nothing
setegapal proc near
	cmp	[tcbstation],02 	; skip call if station is not ega or vga
	je	notskip
	cmp	[tcbstation],03
	je	notskip
	jmp	sepskip
notskip:
	assume	ds:nothing,es:tcb
	push	ds
	push	ax
	push	dx
	call	noswitch		;sah
	mov	ax,es			;sah switch view task ram in
	mgetscb ds
	assume	ds:grp
	mov	dl,'Y'			;indicated no tsl logic
	xchg	[scbnotsl],dl
	push	dx			;saved current status of notsl flag
	push	[scbtcbvr]
	mov	[scbtcbvr],-1
	call	doswitch		;sah
	push	[tcbstkp]		;\  we know that ss <> scbtcbpc here
	mov	dx,[tcbsp]		; \ bias stack during int 10 call
	mov	[tcbstkp],dx		; / since bias could call itsself
	sub	[tcbstkp],128		;/
	mov	dx,offset [tcbegapal]	; reset ega palettes

; the following logic was added so that 40:63 could be properly
; set for each task, and that when pamswitching to another task
; 40:63 will be the same as the current task when resetting the
; ega pallettes

	push	ds
	xor	ax,ax
	mov	ds,ax
	assume	ds:nothing
	push	word ptr ds:[463h]	; save current crt reg
	mov	word ptr ds:[463h],03d4h; place color in crt
	push	ds
	mgetscb ds
	assume	ds:grp
	mov	ax,1002h
	call	i10fun10
	pop	ds
	assume	ds:nothing
	pop	word ptr ds:[463h]	; restore previous crt reg
	pop	ds
	assume	ds:grp
	pop	[tcbstkp]		;restore stack pointer
	mov	ax,ss			;sah
	call	doswitch		;sah switch active task ram in
	pop	[scbtcbvr]
	pop	dx			;restore notsl flag
	mov	[scbnotsl],dl
	call	okswitch		;sah
	pop	dx
	pop	ax
	pop	ds
sepskip:
	ret
setegapal endp

	subttl vgastate - vga state switching
	page
;======================================================================
;,fs
; vgastate - vga state switching
;
; saves or restores the state of the vga ( possiabilty of ega)
;
; in:	al = function	    1 = saved	2 = restored
;	es = tcb segment
;
; out:
;
;,fe
;======================================================================
	assume ds:nothing,es:tcb,ss:nothing
vgastate proc near
	mov	bx,[tcbstate]
	or	bx,bx
	jnz	vga1
	ret
vga1:
	push	ax
	mov	ax,es
	call	egaoff			; make sure ega io protection is off
	pop	ax
	cmp	al,1
	jne	vga2

; do necessary processing for suspention of task during save-state

	or	[tcbega],4		; suspend task
	jmp	short vga3
vga2:

; do necessary processing for releasing of task during restore-state

	and	[tcbega],0f9h		; release task
vga3:
	push	es
	push	ds
	mgetscb ds
	assume ds:grp
	push	[scbtcbvr]		; save current video ptr
	test	[tcbvideo],8		; is this a vga state
	jz	ega1
	push	dx
	push	ax
	push	es
	cmp	al,1			; is this save state
	jne	vga3a
	push	ax
	push	bx
	mov	dx,offset [tcbegapal]	; access pallette buffer
	mov	ax,1009h		; get pallatte register
	call	doi10 		; simulate int 10h call
	pop	bx
	pop	ax
vga3a:

; please not that for the vga case, we must switch in the task
; when call the bios to do the function 1ch.  this is need
; because this function will modified data that is in bios and
; could concievably modified values in task space

	mov	dl,'Y'			;indicated no tsl logic
	xchg	[scbnotsl],dl
	push	dx			;saved current status of notsl flag
	push	ax
	mov	ax,es
	call	doswitch
	pop	ax
	mov	ah,1ch			; do save\restore state
	mov	cx,vstate		; do hard ware and color stuff
	mov	es,bx
	xor	bx,bx			; buffer at es:bx
	call	doi10 		; simulate int 10h call
	mov	ax,ss
	call	doswitch
	pop	dx
	mov	[scbnotsl],dl		; set tsl flag
	pop	es
	pop	ax
	pop	dx
	jmp	vgamem
ega1:
	test	[tcbvideo],4		; is this an ega state
	jz	vgamem
	cmp	al,1			; is this a save state
	je	vgamem			; yes...no saving io protection does it
	call	restoreega		; restore the ega

; handle saving or restoring of vga memory

vgamem:
	push	bx
	push	cx
	push	dx
	push	es
	push	ax
	mov	ax,es			; sah this code regird es
	call	swrealram		; switch real ram into memory
	pop	ax
	mov	bx,[tcbvidw2]
	cmp	bx,0b000h
	jne	vga4
	mov	cx,1			; mono chrome so map in 4k
	jmp	short vga5
vga4:
	cmp	bx,0b800h
	jne	vga6
	mov	cx,4			; color so map in 16k
vga5:

; map memory into context area

	xor	bx,bx			; start at beginning
	call	vgamsmap		; do the mapping

; copy video memory to or from context

	mov	bx,[tcbvidw2]
	call	vgamscpy		; start coping
	jmp	egaback
;----------------------------------------------------------------------------
;	vga\ega memory handling
;		for each 64k plane on system
;		   select plane to read or write
;		    for each 16k section of video memory (64k)
;			    switch 16k of extended memory into context area
;			    copy video memory to\from master context area
;----------------------------------------------------------------------------
vga6:
	mov	cx,4
	test	[tcbega],8		; is this 64k system
	jz	vga6full		; no...use 4 banks
	mov	cx,1			; yes..use 1 bank
vga6full:
	xor	bx,bx
	push	ax

; select plane to read or write

	mov	dx,03ceh
	mov	al,5			; select graphic controler mode
	out	dx,al
	inc	dx
	xor	al,al			; write\read mode 0
	out	dx,al
	dec	dx
	mov	al,3			; select data rotate register
	out	dx,al
	inc	dx
	xor	al,al			; source data unmodified
	out	dx,al
	dec	dx
	mov	al,8			; graphic controler bit mask
	out	dx,al
	inc	dx
	mov	al,0ffh 		; set all to cpu
	out	dx,al
	dec	dx
	mov	al,1
	out	dx,al			; disable set/reset for all planes
	inc	dx
	dec	al
	out	dx,al
	pop	ax
	push	ax
vga7:
	push	cx
	push	ax
	dec	cx
	cmp	al,1			; are we saving the state
	je	vga7r

; setup for writing information to video memory

	mov	dx,3c4h
	mov	al,2			; map register
	out	dx,al
	inc	dx
	mov	al,1
	shl	al,cl			; set bit map
	out	dx,al
	jmp	short vga7ex
vga7r:

; setup for reading information from video memory

	mov	dx,03ceh
	mov	al,4
	out	dx,al
	mov	al,cl
	inc	dx
	out	dx,al
vga7ex:
	pop	ax
	mov	cx,4
	xor	dx,dx
vga8:
	push	cx
	push	bx
	mov	cx,4
	call	vgamsmap		; map memory in master video context area
	mov	bx,[tcbvidw2]
	add	bx,dx
	call	vgamscpy
	pop	bx
	add	dx,0400h		; next 16k of 64k
	add	bx,4			; next 4-4k memory
	pop	cx
	loop	vga8
	pop	cx
	loop	vga7
	mov	dx,03c4h
	mov	al,2			; map register
	out	dx,al
	inc	dx
	mov	al,0fh			; enable all planes
	out	dx,al
	pop	ax
	cmp	al,1			; if restoring the state restore it again
	je	vgaexit
egaback:
	call	noswitch		; turn off switch
	mov	ax,es			; switch to viewed task
	call	doswitch		; switch in task memory
	test	[tcbvideo],8		; is this a vga
	jz	ega2			; no...skip
	push	es
	mov	es,[tcbstate]
	mov	ax,1c02h
	mov	cx,vstate
	xor	bx,bx
	call	doi10 		; simulate int 10h call
	pop	es
	jmp	ega3
ega2:
	test	[tcbvideo],4		; is this ega
	jz	ega3
	call	restoreega		; restore the ega
ega3:
ega4:
	mov	ax,ss			; switch back to active task
	call	doswitch		; switch in task memory
	call	okswitch		; turn on swithing
vgaexit:
	call	vgamsrem
	mgetscb ds
	pop	es
	pop	dx
	pop	cx
	pop	bx
	pop	es			; get save video (push as scbtcbvr)
	mov	word ptr [scbtcbvr],0
	call	swvidsave		; restore its state
	pop	ds
	pop	es
	ret
vgastate endp

	subttl restoreega - restores the state of the ega
	page
;======================================================================
;,fs
; restoreega - restores the state of the ega
;
; in:
;
; out:
;
;,fe
;======================================================================
	assume ds:nothing,es:tcb
restoreega proc near
	cmp	[tcbvidw2],0a000h
	je	regacont
	ret
regacont:
	push	ax
	push	dx
	push	si
	push	ds
	mov	dx,03dah
rlp1:
	in	al,dx
	test	al,8
	jnz	rlp1
	cli
rlp2:
	in	al,dx
	test	al,8
	jz	rlp2
	mov	ds,[tcbstate]
	cld

;****** attribute controller **********
; attribute controller mode control

	mov	si,8+16
	mov	dx,03c0h
	mov	al,10h
	out	dx,al			; out index
	lodsb
	out	dx,al			; out value

; attribute color plane enable

	inc	si
	mov	al,12h
	out	dx,al			; out index
	lodsb
	out	dx,al			; out value
	mov	al,20h
	out	dx,al			;sah enable controller
	sti

;****** sequencer controller **********
; set sequencer controller write bit mask

	mov	si,1+2
	mov	dx,03c4h		; access sequencer controller
	mov	al,2			; access write bit mask
	call	setport 		; set the port

; set sequencer controller character font select

	mov	al,3			; font select
	call	setport 		; set the port

; set sequencer controller memory mode
;****** graphics controller ***********
; set graphics controller enable set/reset

	mov	si,28+1
	mov	dx,03ceh		; access graphics controller
	mov	al,1			; enable set/reset
	call	setport 		; set the port (si++ dx same)

; set graphics controller color compare register

	mov	al,2			; color compare
	call	setport 		; set the port

; set graphics controller data rotate

	mov	al,3			; data rotate
	call	setport 		; set the port (si++ dx same)

; set graphics controller read map select

	mov	al,4			; read map select
	call	setport 		; set the port (si++ dx same)

; set graphics controller mode

	mov	al,5			; graphic mode select
	call	setport 		; set the port (si++ dx same)

; set graphics controller color don't care

	inc	si
	mov	al,7			; color don't compare
	call	setport 		; set the port

; set graphics controller bit mask

	mov	al,8			; bit mask
	call	setport 		; set the port (si++ dx same)

; set graphics controller data set\reset

	mov	si,28
	xor	al,al			; set\reset
	call	setport 		; set the port
	pop	ds
	pop	si
	pop	dx
	pop	ax
	ret
restoreega endp

	subttl setport - helper for restoreega
	page
;======================================================================
;,fs
; setport - helper for restoreega
;
; in:	ds:si offset of value to set
;	dx port to set
;	al index to set
;
; out:
;
;,fe
;======================================================================
setport proc near
	out	dx,al
	jmp	short $+2
	inc	dx
	lodsb				; si is incremented here
	out	dx,al
	dec	dx			; notice that dx remains the same
	ret
setport endp

	subttl	vgamsrem - remove mapping of context area
	page
;======================================================================
;,fs
; vgamsrem - remove mapping of context area
;
; in:
;
; out:
;
;,fe
;======================================================================
	assume	ds:grp
vgamsrem proc	near
	push	ax
	push	cx
	push	dx
	mov	dx,[scbmastv]
	xor	ax,ax
	mov	cx,4
	call	mapvsa
	pop	dx
	pop	cx
	pop	ax
	ret
vgamsrem endp

	subttl	vgamsmap - map in video area into master video context area
	page
;======================================================================
;,fs
; vgamsmap - map in video area into master video context area
;
; in:	cx = # of 4k pages to map
;	bx = start handle counter
;
; out:
;
;,fe
;======================================================================
vgamsmap proc near
	push	ax
	push	bx
	push	cx
	push	dx
	push	si
	push	di
	assume	es:tcb
	mov	dx,bx
	cmp	dx,[tcbvmpgs]
	ja	vmapr			; must be in second handle
	add	dx,cx
	dec	dx
	cmp	dx,[tcbvmpgs]
	jb	vmapl			; sah
	mov	di,cx
	mov	dx,[tcbvmpgs]
	sub	dx,bx
	sub	cx,dx
	add	bx,[tcbvmhdl]
	mov	si,[tcbvmhdl+2]
	sub	di,cx
	jmp	short vmapin
vmapr:					; handle right case
	sub	dx,[tcbvmpgs]
	mov	bx,[tcbvmhdl+2]
	add	bx,dx
	jmp	short vmapdn		;sah 04/06/88
vmapl:					; handle left case
	add	bx,[tcbvmhdl]
vmapdn:
	xor	si,si			;sah 04/06/88
	xor	di,di			;sah 04/06/88
vmapin:
	mov	dx,[scbmastv]
	mov	al,1
	call	mapvsa			; call mapper
	pop	di
	pop	si
	pop	dx
	pop	cx
	pop	bx
	pop	ax
	ret
vgamsmap endp

	subttl	vgamscpy - copy memory from video to or from master
	page
;======================================================================
;,fs
; vgamscpy - copy memory from video to or from master
;
; in:	bx = address of video area
;	cx = size of block to copy in 4k banks
;	al = save/restore function al = 1 save	  al = 2 restore
;
; out:
;
;,fe
;======================================================================
	assume	ds:grp,es:tcb
vgamscpy proc near
	push	ds
	push	es
	mov	si,[scbmastv]
	cmp	al,1			; are we saving the state
	je	vcpysv
	mov	es,bx			; destination is video
	mov	ds,si			; source is master context
	jmp	short vcpy
vcpysv:
	mov	ds,bx			; source is video
	mov	es,si			; destination is master context
vcpy:
	xor	si,si			; do the copy
	xor	di,di
	xchg	ch,cl			; convert cx (4k banks) to words
	shl	cx,1
	shl	cx,1
	shl	cx,1
	cld
	call	clichk			; cli base on scbswvq == 'Y'
	call	wordmove		; use fast word move (386/486)
	sti
	pop	es
	pop	ds
	ret
vgamscpy endp

	subttl	testvid - test video status
	page
;======================================================================
;,fs
; testvid - test video status
;
; ÚÄ
; ³ if([tcbmode] be 7 && [tcbrows] a 25) return(drop) ; if 43/50 line
; ³ if([tcbpam] == 'N') return(drop)		      ; if pam disabled
; ³ if([tcbstate == 0 && [tcbega] & 1) return(drop)   ; if !vmo v/ega && gr
; ³ return(allow)
; ÀÄ
;
; moskey calls this function twice; first with es pointing to the
; tcb of the current task (ss) and then with es pointing to the tcb
; of the task to be pammed to.
; the only tests that should be put in here are those needed for
; both tasks.
;
; in:	es -> tcb of task to check
;
; out:	cl = 0 for allow
;	   = 1 for defer
;	   = 2 for drop
;
;,fe
;======================================================================
	assume ds:nothing,es:tcb,ss:nothing
testvid proc near
	mov	cl,2			; setup for the drop case

; if in vga or ega graphics mode and > 25 rows, drop

	cmp	[tcbmode],7
	ja	tv0
	cmp	[tcbrows],19h
	ja	tvx

; if pamming is disabled, drop

tv0:
	cmp	[tcbpam],'N'
	je	tvx

; if task did a alt 999 don't allow pamswitching...

	cmp	[tcbalt999],0ffh	
	jne	tvx			

; if not in vmo vga/ega but are in a vga/ega graphics mode, drop
; else, allow

	cmp	[tcbstate],0
	jne	tvw
	test	[tcbega],1
	jnz	tvx
tvw:
	xor	cl,cl			; pamming is allowed
tvx:
	ret
testvid endp

	subttl checkvid - verify consoles are compatible
	page
;======================================================================
;,fs
; checkvid - verify consoles are compatible
;
; added 09/30/88 sah for verification workstation can be
; compatible with switch to new screen.  the following matrix
; is used in the decision process.
;
;     n e w   s c r e e n ' s   C o n s o l e
;  console  mono  cga  ega  vga  herc
; ------------------------------------
;   mono    yes   yes  yes  yes   no
;   cga     yes   yes  yes  yes   no
;   ega     yes   yes  yes  yes   no
;   vga     yes   yes  yes  yes   no
;   herc    yes   #1   #1   #1	  yes
;
; notes on above:
; #1   not ok to switch unless cga\ega\vga task does a mos vmode of mono
;
; in:	ds -> console tcb
;	es -> task to switch to tcb
;	  tcbstation contains station type
;	    00 = mono
;	    01 = cga
;	    02 = ega
;	    03 = vga
;	    04 = hercules
;	    05 = monochrome ega
;	    06 = monochrome vga
;
; out:	return non-zero flag if stations are incompatible
;
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:tcb
checkvid proc near
	push	bx
	push	cx
	assume	ds:tcb,ss:nothing
	mov	bl,[tcbstation] 	; get type of console
	mov	cl,[tcbvideo]
	assume	ds:nothing,es:tcb
	mov	bh,[tcbstation]
	mov	ch,[tcbvideo]

; first we will analize hercules stations
; they are allow to switch into other hercules or mono systems
; or  stations with vmode of mono

	cmp	bl,4			; is this hercules
	jne	cvnherc
	cmp	ch,1			; vmode of mono
	je	cvok
	cmp	bh,4			; hercules
	je	cvok
	jmp	short cvnotok		; sorry not this time
cvnherc:

; now we will check other types of station

	cmp	bh,4			; is switch in station hercules
	jne	cvok
	cmp	cl,1			; is both vmode mono
	jne	cvnotok
	cmp	ch,1
	je	cvok
cvnotok:
	inc	bl
	or	bl,bl			; indicate non-zero
	jmp	short	cvdone
cvok:
	cmp	bl,bl
cvdone:
	pop	cx
	pop	bx
	ret
checkvid endp


mosseg	ends
	end

