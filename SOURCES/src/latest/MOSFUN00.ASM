	include page.inc
	title	mosfun00.asm - general function calls
	extrn	bugerror:near		; defined to turn stack overflow on
comment ^==============================================================
		      development specification

 program name:	$$mos.com		assigned to: david morrow
 module name:	mosfun00		assign date: 08/19/86
 entry points:	mosfunxx (see below)	completed:
 entry from:	mosint21
 entry method:	call
 calls:
 purpose:	task management functions.
 last update:	09/18/1992
========================================================================

mjs 11/24/86	added code to exec (4b) and terminate (00) to decrement
		tcbnest.  also, removed change to int 23h vector in exec.

jsm 01/19/87	added switchchar (37) call

jsm 03/03/87	added code to exec (4b) to set the memory size correctly in
		the psp's of new processes, and to return all resources if
		an error occurred before end of exec.

jsm 03/16/87	get disk free space (36) was reporting 2 free clusters too
		many

jsm 03/31/87	added get default dpb (1f) for norton util.  and fixed exec
		subfunction 1 to set top of stack only if .com file > 65534
		bytes long

jsm 04/07/87	allow non-consecutive drives in set drive 0e)

sah 04/16/87	added logic to compute psp function call and segment size
		in psp

sah 04/22/87	change exec to use res4 instead of 2e & 30.  change
		terminated and exec so that the callers ss & sp are
		restored when child returns. ss & sp are stored at offset
		2e and 30 of the psp of the parent. ms fortran 4.0 requires
		this.

sah 04/27/87	change the method of allowing norvell to intercept internal
		21 for resident porgrams without conflicting programs like
		sqz and note-it

sah 04/30/87	remove psp parent setting in function 26 and place code in
		exec (ws correctstar)

jsm 05/15/87	restored full country (38) functionality

sah 06/16/87	corrected loading overlays debug support mcb

sah 06/22/87	mcb problem fixed. 4a on allocated blocks follow by a free
		block

sah 06/24/87	com overlay files don't have PSPs 100h too much. exec
		didn't take this in account

sah 07/14/87	gracefull exit from too small smp to load exe header into
		memory. (no bugerror) insufficent memory error code return

rbr 07/18/87	corrected class/action/locus for error code 18 (no more
		files).  this fixes a problem with ibm/bpi accounting
		package

jsm 07/20/87	exec now opens files in deny write mode, not compatibility
		mode

sah 07/21/87	added special int 24 function ffh if too small smp while
		loading exe header

jsm 07/21/87	parse now stops ignores extra file name characters, instead
		of putting them in the extension.

sah 07/29/87	include get and set psp optimization for speed. macros are
		found in mosregs

sah 08/05/87	corrected 4b01 incase  carry was set before making call to
		mos

mjs 08/18/87	modified exec to set/reset tcbexec3d flag around the call
		to fun3d so openfile will relax its testing of
		sharing/compatiblity mode conflicts

sah 09/08/87	correct error-code reporting on some functions while
		reporting error codes for technical reference manual.
		found:	fun 33h return ffh if al > 2

mjs 10/1/87	modified special call to mocxpcor's int24 handler by
		exec to match changes made to moxcpcor.	 now, pass a
		string to int24 for special case message.  makes this
		pop up message feature available for other uses.
		this was done initially for the mos useirq warning

jsm 10/06/87	call int 38h, function 15h, before terminating a
	 	process

sah 10/20/87	remove reference to mosdebug

sah 10/23/87	inserted reseting of mosint38 vector during terminated
		to avoid conflics with first choice.  problem occur
		because of jsm's addition of INT 38 function 15.  (Well
		this is a better place for it anyway)

sah 11/02/87	added int 38h replacement chain logic to exec and
		terminate.   following new tcb variables have been added
		tcbcnt38 - counter of int 38 replacement on exec
		tcbfar38 - storage area for 5 int 38h vectors

sah 11/03/87	correct problem in vector chain mangament when app
		would use function 35 the return the vector which it
		set early (which we set back to chain table and falsely
		assume when vector was reinserted that it was reinsert-
		the orginally vector (pointing to mos) but was not.
		function 35 now return the most recent vector in the
		chain table if there is a chain table and application
		vector is in chain table.  if application grabs a vector
		from segment 0, the only way we can correct this
		problem is use the 386's memory protection.

sjc 11/13/87	fixed problem where execute-only file did not execute.
		determined that the return address for execopen (tested
		in mosfun3d) was incorrectly placed into int21's
		iret return address in sim21.  it placed the address of
		the end of the sim21 routine, not execopen.  modified
		sim21 to place the proper offset into the return address
		modified mosfun4b to use different label than execopen.
		(which is now inside sim21, which therefore, can't move)
		see sim21 and mosfun4b (;execopen) for changes.

sah 12/01/87	remove my additions for function 35 nolonger needed

sah 12/03/87	remove calls to uptinmos, set scbinmos to 0 when task
		terminates

mjs 12/8/87	add code to fun00 and fun4b to decrement scbinmos since
		this is a time when a mossaver entry is made with no
		immeadiately corresponding mosrestore.

jsm/mjs 12/09/87 implanted code in fun31 from jsm to correct problem with
		tsr's getting their PSP updated properly.

jsm 12/09/87	fixed problem in fun4a which caused function to return
		incorrect block sizes in some cases.

mjs 12/20/87	reset tcbstkp in fun00 to handle sidekick's un-install

sah 01/12/88	corrected mosfun31 so that it handles applications
		which allocate memory blocks using function 48 and go
		resident including the allocated blocks.  verify under
		dos that function 31 is where this action should be
		taken place and not during function 4ah which cause the
		the original problem.

sah 01/20/88	change scbseg and zero seg access to mgetxxxx macros
		optimize routines to decrement ment scbinmos flag by
		placing code in single routine and corrected some
		conditions where it might be possiable that scbinmos
		flag is decrement when it has a value of zero.

sah 01/27/88	correct problems with borland's Quattro (uses PLINK 86)
		which had problems when more and one copy was running
		and memory problems (smp and main) cause exec to bomb
		out of one of the task.  found problem to be that exec
		was not closing the files and this left system info in
		the heap which cause the program not to be able to load
		up again.  there is still a problem if 2 task try to
		exec (exe's) and not enough SMP, the second task will
		get a smp header critical error, but should be able to
		reexecute the program after pressing a key to get out
		the window.

sjc 2/5/88	fix tcbstkp before and after jsm's INT 38 to allow all
		applications to see a process termination while also
		allowing stack re-entrancy in mos!

mjs 2/10/88	modified fun4a to support an undocumented return
		parameter that quickbasic ver 4.0 counts on to work
		properly.  when fun4a is called, es points to the memory
		block to be modified.  on return, if no error, both es
		and ax need to hold this memory block's segment.

sah/rbr 02/20/88 move ddt segment to mo2 group

sah 02/29/88	correct problems with int 38 vector and exec
		    1.	replace int 38 with simulated call to
			scbfar38
		    2.	corrected bug in set38 where it was trashing
			int	39 vector.

sah 03/03/88	corrected function 38 which was clobbering the stack with
		sidekick plus because we were copying 36 bytes when we
		should have only copy 32 bytes which sk+ allocated on
		the stack.

sah 03/06/88	made changes for sk(+) "Thanks to some insight from ROD
		and techinical information which i have"   Change
		how scbinmos works (should have 2 values only	0 = not
		busy,	1 = busy.

rbr 03/07/88	don't round memory allocations if declare call is not
		supported.

rbr 03/11/88	do declares/undeclares during memory management.

sah 03/15/88	corrected function 36 reporting which was incorrect
		because it was not starting from cluster 2 on the fat

sah 03/16/88	corrected problems with overlays and smp increasing
		because code for deallocating work space was below the
		test for overlay code (and load but not execute)

rbr 03/28/88	support the 286 "clear auto declarations" function.

sah 04/13/88	corrected class, action, locus for extended error code 32.

rdg 04/28/88	moved function 38 country code data to 'gdata' and
		corrected set/get to use scbcntry rather than country.

jrb 05/02/88	replaced read of fat with pointer to bdbmedia in fun1b
		(why read it if you don't have to)

sah 05/13/88	following corrections are made in exec
		1. if loading overlay, memory is allocated to max
		   this corrected problems with latest alpha code with
		    borland's Quattro
		2. after overlay was load carry was not being clear

rbr 05/16/88	some code size optimizations  ; saved 672 bytes.

sah 05/18/88	corrected function 49h which should not combine the
		deleted memory blocks.	this corrected a problem with
		quick-basic chaining.  also terminate should do the
		actual combine of freed memory blocks.	also exec (not
		overlays)  should combine the blocks - main reason i see
		need for this because our command processor allocates
		memory and this cause problems under new but more
		compatible techniques) this should only be done with exe

sah 05/20/88	my 03/06/88 was incorrect. after running a test program
		on dos, indos flag is actual increment and decrement.
		to give a consistent and easy changable interface to
		to scbinmos i implement the following routines
		decinmos - decrements inmos flag is not zero
		incinmos - increments inmos flag
		rstinmos - resets inmos flag

sah 06/14/88	corrected a strange and interesting problem with my
		5/18/88 update.	 ds need to be pointed to grp inside
		inside combmcb procedure.

mjs 7/2/88	added noswitch/okswitch calls to mosfun0d, mosfun1b,
		mosfun32, and mosfun36.

mjs 7/13/88	removed call to updcht (chain table management) from
		mosfun25.  added a call to grab_back for int8.

mjs 7/22/88	added logic to support regrab of int9.

sah 08/01/88	added detection and memory allocation to solve problem
		with exepack files.  cleanup module and corrections for
		optasm

sah 08/25/88	corrections to exec so that it uses values in exe header
		for calculating file size.  also improve handling of the
		case where file is loaded up high (ms-windows)
		also remove tempendency of psp reserved field when
		executing to an exefile

sah 08/29/88	corrected function 26 which was inserting setment of psp
		but wasn't correctly handling the offset

sah 09/13/88	made mosfun48 combine mcb's, this corrected a problem
		with unisys application.

sah 10/13/88	correct mcb handling during function 31 for irmacom

mjs 11/01/88	modified exec to accomodate pfw:write's sloppiness.
		when pw.com exec's pw.prg, the filename string passed to
		exec happens to be located in the unallocated memory
		into which the exec will happen.  when our exec code
		builds a new environement block and psp in this free
		memory, the filename string gets overwritten.  under dos
		they must just be lucking out.
		modified exec to copy the ds:dx filespec into local
		storage.  also moved the file open call to the front
		of exec since pw.com doesn't protect its error message
		string either.

sah 11/16/88	corrections to problems created with mjs's 11/01/88 by
		moving the file open call in front of exec. this cause
		an additional unwanted filehandle to be created for new
		child psp.  this problem was one of the main reasons
		why i was having problem with tecmar tape drive for the
		ps/2's.

rkg 11/18/88	ptr176 function 0e set drive returns incorrect maximum
		drive.	it did not include aliases.  now returns max of
		actual devices and aliases.

jrb 11/17/88	rodney, today's the 17th - 4b function 3 was clearing
		the low bit of the return address offset instead of
		clearing the carry flag - if the calling int 21h
		was on a odd byte, it would return to the 21h doing
		just about anything

rbr 12/06/88	memory chain destruction was causing a crash instead
		of an error message.

sah 01/27/89	modifications to retf macro for masm 5.10

sah 02/21/89	made exec restore mos services interupt to scbfar38
		value to make sure it is always set when program is
		executed. please note that this is only done if
		services <> 38h

sah 03/22/89	corrected function 4a which should also combine mcb
		before making it's check to grow or not. This is
		necessary becuase some appication could do a function
		49h which does not combine the mcb's, and therefor
		function 4ah would not know about the free mcb.

mjs 04/20/89	modified how mosfun4b determines the size of an exe
		file.  the directory size must be used rather than the
		size as recorded in the exe header.  this is what dos
		does and it fixes a problem with an application done
		in quickbasic 3.0 which uses chaining.

rkg 04/20/89	close spool files via int 17 func ffh

sah 05/25/89	remove mosfun50, 51 and 62

rkg 05/30/89	mjs's modification of 4/20 broke ACCPAC's plus2.  the
		program was very large but had a small sector count.
		the program size must also be used for allocating memory

sah 05/31/89	correct rkgs 05/30/89 update which cause ms-windows not
		to load because windows requires that if exe header size
		is larger than file size, then we must use exe header
		size. what i did, was to use the larger of exe header
		size and directory size to make sure that both windows
		and accpac's PLUS2 is compatible

rkg 06/26/89	dos allows freeing a free memory block if the block is
		intact.

mjs 06/28/89	corrected setting of the default dta segment in the
		exe case.  it was being set to the stack segment rather
		than the psp segment.

sah 07/06/89	made sure that exec (4b) allocates all of memory instead
		of allocating 120h bytes for loading psp in.  this
		corrected a problem with a realworld 5.0 accounting
		package which had a loadwin.com which exec a windows.exe
		tsr.
sah 07/13/89	corrections to above fixed, so that size is correctly
		passed on.

sah 07/26/89	remove set38, get38, and setservices.

mjs 08/03/89	rework how fun31 handles the case where a tsr allocates
		one or more blocks with fun48 before terminating.
		the previous method was conflicting with the case where
		a tsr (btree.com of the sybiz package) was shrinking
		back and then using a larger size for dx of fun31.
		generated from mosfun00.cht (\mos.dir\cht.dir on server)

mjs 10/18/89	modified how exec calculates the size of an exe load
		module (hopefully for the last time!).	i found that
		while the word at offset 2 within the header is documented
		as being the bytes in the last page, it is not actually
		used when calclating the load module's size.  Only the
		number of whole 512 byte pages should be used.

bwr 01/23/90	added support for dos function 58. (get/set memory
		allocation strategy).  this function must, at least,
		store the strategy specified by the caller and recall
		it if it needs to be checked.  at present the routine
		simply returns with the function code still in ax.

bwr 01/25/90	function 38 (get country info) changed to return a 34
		byte table instead of a 32-byte table. (dos 3.30)

bwr 01/29/90	added dos functions through 68h for dos 3.30 compat.
		function 65: get extended country info
		function 66: get/set gloabl code page. (not supported)
		function 67: set handle count
		function 68: commit file

note:  functions 65 and 66 are not yet supported.  mos does not yet
	 have code page support.  this should be initiated as a
	 separate project.

sah 02/05/90	corrections to function 4ah setblock so that it even if
		it returns an error in size, mos will combine block,
		this also means that it will combine block before the
		the free block with the block that is free. also
		conditionally assemble out instructions 286 declare
		calls. changes to exec so that ax contains drive
		specifiers. 00h if parmerter drive is ok, otherwise 0ffh
		parm 1 is in al, and parm 2 is ah. change function 30h
		so that it returns task specific dos version #

bwr 02/15/90	cleaned up references to memory control block chain in
		all functions dealing with memory allocation.  the
		memory addressing construct used di as a dummy variable
		to calculate the offset address of the various mcb
		pieces which is not necessary.	(di was always 0)
		also cleaned up some segment register moves through
		the stack to use a register instead. i.e.
			push	ds
			pop	es	; slow method

			mov	ax, ds
			mov	es, ax	; fast method


sah 02/22/90	corrections for skplus, must only send 32 bytes to
		requester if dos version is 3.20, else we can send 34
		bytes to requested if dos version 3.30 for function 38h
		corrections for wordperfect 5.10, save bx,cx,dx,si,di,bp
		ds, and es on user's stack during exec and terminate
		will restore these values on exit. use unused protion of
		which are on the tcb stack.  made maxdays public for mostemp

sah 03/01/90	pspsp is 4 is adjusted by exec

sah 06/22/90	correction for msetpsp for lanlink

sah 07/17/90	corrections so that exec will use only 512 bytes of smp
		when doing exe header relocations. this was done so that
		it would reduce the extra smp requirements on the system

sah 07/25/90	corrected smp allocations, should allocated 33 paragraphs
		instead of 513 paragraphs.

mjs 09/21/90	modified fun4bpsp to check for user supplied fcb
		pointers set to ffff:ffff.  this fixes pfs pro write,
		real world accounting and others.

sah 10/17/90	corrected oversights in implementation of function 67
		we must correctly handle deallocation of memory block
		if psp correctly has handle table allocated to another
		section of memory. also if dos 3.2 report invalid function

sah 11/14/90	corrections for osmose problem, must close file and make
		sure that no calls to mosint21 or scbfar21 are done after
		deallocation of smp for header.	 corrected problem by
		switch close call a mosheman call.

sah 11/19/90	made sure that function 4b return invalid function if
		subfunction is > 3

sah 03/25/91	use function 55h inside of exec instead of function 26h
		so that files with inherit bit will be inherited.

mjs 05/10/91	modified mosfun0d to call invbdb when cacheing is off
		for the drive or for all drives.  this was necessary
		to prevent improper "critical block" errors.

sah 08/29/91	correction in way mos puts registers onto stack for
cbk		workperfect 5.1 shelling. this was done for lanlink
		professional's exec logic

sah 10/23/91	correction for "MetLif" problem with our exec logic
		make sure handle the case with trailing spaces on
		filename.

mjs 12/16/91	dlg mods:  corrected calculation of disk free space by fun36
		in 12 bit fat case.  added i21f5802 and i21f5803.
		added i21f33s05 and i21f33s07.  transferred the following 
		functions from mosfun00 to mosfun39: mosfun58, 59, 65, 
		66, 67 and 68.

mjs 01/10/92	mod i21f3306 to return scbversn rather than tcbversn.
		mod i21f30 to recognize entry parm in al register.


SAH 01/10/92	Corrections for Pharlap's DPMI/VCPI test suite.  Correctly
		implemented function 58h so that MCB allocation actually
		do it the way 58 termines to do it.  Remove all 286
		driver conditional assemblies (CODE286)

SAH 03/18/92	Corrections for LanLink Professional EXEC logic. Implement
		stack biasing for sim21 procedure.

mjs 03/23/92	corrected a number of problems in the exec logic that
		deals with packed exe files.  first, the previous method
		of releasing the psp block, enlarging the environment
		block, allocating a new psp block and then copying the
		old data to the new block wasn't workable.  for cases
		where the original psp was near the 1000h segment boundary,
		an overlapping copy would occur, resulting in a mangled
		psp.  corrected by copying the old psp to a heap block.
	
		also corrected in this section: stack imbalance
		when jump to error handler, the address comparison
		method left a dead spot, the segment portion of the psp
		pointer must be adjusted when the psp is moved.


================ 5.01 Kernel Ends Here ====================================

SAH 04/16/92	Additional corrections for exec logic handling of packed
		EXE files.  I found that enlarging the enviroment is not
		always possiable (IE MS MOUSE.COM frees the enviroment
		before going TSR).  So what it does instead is allocated
		an additional piece of memory so that EXEPACK programs 
		will not conflict with 1st 4k of memory.
		(Corrected in UPDAT501.SYS Version 0.05)

mjs 08/18/92	clean up segment declarations

SAH 08/25/92	Change INT 21h function 31h so that if DX < 6 then force
		it to 6.  This was done for PC-Support package
		(Corrected in UPDAT501.SYS Version 1.10)

mjs 08/26/92	delete reference to scbfree


SAH 09/18/92    Change function 4ah so that it some one trys to resize
		a freed mcb...it will put the owner as current psp
		(Corrected in UPDAT501.SYS Version 1.13)
		
=======================================================================^

.xlist
;	include mosfun00.pub
	include options.inc
	include group.inc
	include errcodes.inc
	include mosregs.inc
	include moscdb.inc
	include mostfb.inc
	include mosgfb.inc
	include mosbdb.inc
	include macros.inc
	include mospsp.inc

tcb	segment at 9999h
	include mostcb.inc
tcb	ends

gdata	segment
	include mosscbex.inc
gdata	ends
.list

gdata	segment

; usa table

usainfo dw	1			; country code
	db	'$',0,0,0		; currency symbol
	db	',.-:,'			; thousands,decimal,date,time,dl separators
	db	00100000b		; time,digits,currency,date formats

usalen	equ	$-usainfo

	dw	2			; country code for canadian-french
	db	'$',0,0,0		; currency symbol
	db	' ,-:;'			; thousands,decimal,date,time,dl separators
	db	01101110b		; time,digits,currency,date formats

	dw	31			; country code for netherlands
	db	9fh,0,0,0		; currency symbol
	db	'.,-:;'			; thousands,decimal,date,time,dl separators
	db	01100001b		; time,digits,currency,date formats

	dw	32			; country code for belgium
	db	'F',0,0,0		; currency symbol
	db	' ,/:;'			; thousands,decimal,date,time,dl separators
	db	01101101b		; time,digits,currency,date formats

	dw	33			; country code for france
	db	'F',0,0,0		; currency symbol
	db	' ,/:;'			; thousands,decimal,date,time,dl separators
	db	01101101b		; time,digits,currency,date formats

	dw	34			; country code for spain
	db	9eh,0,0,0		; currency symbol
	db	'.,/:;'			; thousands,decimal,date,time,dl separators
	db	01101101b		; time,digits,currency,date formats

	dw	39			; country code
	db	'Lit.'			; currency symbol
	db	'.,/:;'			; thousands,decimal,date,time,dl separators
	db	01000101b		; time,digits,currency,date formats

	dw	41			; country code for switzerland
	db	'Fr',0,0		; currency symbol
	db	',...,'			; thousands,decimal,date,time,dl separators
	db	01101001b		; time,digits,currency,date formats

	dw	44			; country code for united kingdom (england)
	db	9ch,0,0,0		; currency symbol
	db	',.-:,'			; thousands,decimal,date,time,dl separators
	db	01100001b		; time,digits,currency,date formats

	dw	45			; country code for denmark
	db	'DKR',0			; currency symbol
	db	'.,/.;'			; thousands,decimal,date,time,dl separators
	db	01101101b		; time,digits,currency,date formats

	dw	46			; country code for sweden
	db	'SEK',0			; currency symbol
	db	'.,-.;'			; thousands,decimal,date,time,dl separators
	db	01101010b		; time,digits,currency,date formats

	dw	47			; country code for norway
	db	'KR',0,0		; currency symbol
	db	'.,/.;'			; thousands,decimal,date,time,dl separators
	db	01101001b		; time,digits,currency,date formats

	dw	49			; country code for germany
	db	'DM',0,0		; currency symbol
	db	'.,..;'			; thousands,decimal,date,time,dl separators
	db	01100001b		; time,digits,currency,date formats

	dw	61			; country code for australia
	db	'$',0,0,0		; currency symbol
	db	',.-:,'			; thousands,decimal,date,time,dl separators
	db	01100001b		; time,digits,currency,date formats

	dw	351			; country code for portugal
	db	'$',0,0,0		; currency symbol
	db	'.,/:;'			; thousands,decimal,date,time,dl separators
	db	01101101b		; time,digits,currency(s/b 4),date formats

	dw	358			; country code for finland
	db	'MK',0,0		; currency symbol
	db	' ,-:;'			; thousands,decimal,date,time,dl separators
	db	01101101b		; time,digits,currency,date formats

	dw	785			; country code for the middle east
	db	'$',0,0,0		; currency symbol
	db	'.,/:;'			; thousands,decimal,date,time,dl separators
	db	00111101b		; time,digits,currency,date formats

	dw	972			; country code for israel
	db	99h,0,0,0		; currency symbol
	db	',./:,'			; thousands,decimal,date,time,dl separators
	db	01101001b		; time,digits,currency,date formats

endtab	dw	0			; this word of 0 must come immediately
					; after last country information block
gdata	ends

irq	segment
	extrn	irqstart:byte
irq	ends

;======================================================================
; memory block definition

mbseg	segment at 1111h

mbtype	db	?			; m for memory block, z for last block
mbowner dw	?			; owner psp address
mbsize	dw	?			; size of block

mbseg	ends

;======================================================================
; fcb definition and structure

fcbstru struc

fcbdrv	db	?			; 0 drive
fcbfile db	8 dup(?)		; 1 filename
fcbext	db	3 dup(?)		; 9 file extension
fcbcb	dw	?			; 12 current block number
fcbrec	dw	?			; 14 logical record size
fcbsiz	dw	2 dup(?)		; 16 file size in bytes
fcbdate dw	?			; 20 date of last update
fcbres	db	10 dup(?)		; 21 reserved
fcbcr	db	?			; 32 current relative record
fcbrr	db	4 dup(?)		; 33 relative record number

fcbstru ends

domos	macro
	pushf				; simulate an int 21h
	push	cs
	call	mosint21
	endm

ljz	macro	jmpdest
	local	ppp1
	jnz	ppp1
	jmp	jmpdest
ppp1:
	endm

lja	macro	jmpdest
	local	ppp1
	jna	ppp1
	jmp	jmpdest
ppp1:
	endm

ljb	macro	jmpdest
	local	ppp1
	jnb	ppp1
	jmp	jmpdest
ppp1:
	endm

;======================================================== ddt segment
if 0 eq 0
segment_num = 2
endif
ddt	segment
	extrn	closeall:near, flush:near, devchk:near, invbdb:near
	extrn	findbdb:near, finddrv:near, todriver:near, setphdl:near
	extrn	setfree:near, rdfat:near, moserror:near
	extrn	mediachk:near, flushdata:near
ddt	ends

;======================================================== mos segment
if 0 eq 0
segment_num = 1
endif
mosseg	segment
	assume	cs:mos,ds:grp,es:nothing,ss:tcb

	extrn	mosend:byte, sbios:word, mosint21:near
	extrn	caps:near, mosheman:near, gettime:near, regrab8_data:byte
	extrn	getdate:near, grab_back:near
	extrn	mosoldfn:near, decinmos:near, incinmos:near, regrab9_data:near
	extrn	rstinmos:near, noswitch:near, okswitch:near, closspls:near

	public	fun00a, mosfun1b

	subttl mosfun00 - program terminate
	page
;======================================================================
;,fs
; mosfun00 - program terminate
;
; terminate the execution of a program.
; the terminate, ctrl-break, and critical error exit addresses are
; restored to the values they had on entry to the terminating program
; from the values saved in the psp.  all file buffers are flushed and
; all handle files are closed.	any files that have changed in length
; and not closed are not properly recorded in the directory.  control
; transfers to the terminate address.  this call performs the same
; function as int 20h.
; any memory blocks that are associated with this process are
; deallocated.
;
; in:	tcs -> points to psp
;
; out:	
;
;,fe
;======================================================================
	assume	ds:grp,ss:tcb,es:nothing
public	mosfun00
mosfun00:
	xor	ax,ax
	mov	[tcbretc],ax		; set error code to normal termination

; free memory allocated to process

	mov	es,[tcs]		; get psp pointer
	msetpsp es
fun00a:					; ** entry point for mosfun4c
					; ** entry point for terminate
	mov	ax,sp			; put bias on stack to allow reentry
	sub	ax,98
	xchg	[tcbstkp],ax
	push	ax
	mov	ah,15h		
	pushf				; simulate interupt call to
	cli				; to int 38 since a vector could
	call	dword ptr [scbfar38]	; have been takin by app.
	pop	[tcbstkp]
	mov	ax,offset [tcbstack]
	mov	[tcbstkp],ax		; reset the stack

; deallocate all memory blocks for this psp
; but not if psp = parent psp (pspprnt)

	push	ds
	assume	es:nothing
	push	es
	call	closspls		; close all spool files
	callmos2 closeall		; close any open files
	pop	es
	pop	ds
	mov	bx,es			; deallo any blocks for this guy
	assume	es:pspseg
	cmp	bx,[pspprnt]		; is this the special case? (command.com)
	jne	$+5
	jmp	fun00b			; do not deallo mbs
	assume	es:pspseg
	mov	ax,[tcbmbpf]		; search through entire mb chain
	mov	cx,ax			; set initial 'previous pointer'
fun00c1:
	mov	es,cx			; address next block
	assume	es:mbseg
	inc	cx
	add	cx,[mbsize]		; calc pointer to next block
	cmp	[mbowner],bx		; deallocate this one?
	jne	fun00c2
	mov	ax,es
	inc	ax			; use function call addressing
	push	es
	mov	es,ax
	mov	ah,49h			; free memory block owned by this psp
	domos
	pop	es
	jc	fun00c3
	cmp	[mbtype],'Z'		; is this the last block?
	jne	$+5			; no
	jmp	fun00b			; yes, end search
	mov	cx,es
	jmp	fun00c1			; block may invalidate its address)
fun00c3:
	mov	ax,'00'
	jmp	funerr
fun00c2:
	cmp	[mbtype],'Z'		; is this the last block?
	jne	fun00c1			; no

; ** entry point for mosfun31
; ** entry point for terminate

fun00b:
	call	combmcb			; combine adjacent mcb's
	assume es:nothing,ss:tcb
	mov	es,[tcbpsp]
	assume	es:pspseg
	push	word ptr [psptrmv+2]	; set up for retf exit to terminate
	push	word ptr [psptrmv]	; address.
	mgetzero es
	assume	es:nothing
	push	ds
	mov	ds,[tcbpsp]		; get psp address
	assume	ds:pspseg

; reset current psp to parent

	mov	ax,[pspprnt]		; save area for parent psp
	msetpsp ax
	cld				; restore int 22, 23 and 24h from psp
	mov	di,22h*4		; offset to start of vectors
	mov	si,offset psptrmv	; save space for vectors in psp
	mov	cx,3*2			; move 3 vectors
	rep	movsw
	mov	ax,[tcbsav24]		; is a heap block left over from a non-return
	or	ax,ax			; from toint24 ?
	jz	skipfreeheap
	mov	word ptr [tcbsav24],0	; reset the pointer
	push	es
	mov	es,ax
	mov	ah,1
	call	mosheman		; free the heap block
	pop	es
	or	al,al
	jz	skipfreeheap
	call	bugerror
	db	'80 '
	db	'SMP free error',00h	;@@xlat
skipfreeheap:
	call	rstinmos		; reset inmos
	cmp	byte ptr [tcbnest],0
	je	skipdecnest
	dec	[tcbnest]		; decrement counter for nest control
					; since entered mosint21 but didn't leave
	mov	[tcbspskp],'N'		; reset spooler control flag in case a
					; critical error abort left it set
skipdecnest:
	pop	ds			; get ds
	pop	ax			; get saved psptrmv
	pop	bx			; get saved psptrmv+2
	push	ds
	mov	ds,[tcbpsp]
	push	di
	push	es
	les	di,dword ptr [pspsp]	; address stack
	cld
	stosw
	mov	ax, bx
	stosw
	pop	es
	pop	di
	pop	ax			; get ds into ax
	cli
	mov	ss, [pspss]
	mov	sp, [pspsp]
	sti
	mov	ds, ax
	assume	ds:grp
	mov	[scbnoswt], 0

; the following addtions are added to correct problem with
; wordperfect 5.10 by restoring registers from users stack

	mov	ax,ss
	cmp	ax,[scbtcbpc]
	je	skipreset
	mov	bp,sp
	sub	bp,12
	mov	ax,word ptr ss:[bp-16]
	mov	bx,word ptr ss:[bp-14]
	mov	cx,word ptr ss:[bp-12]
	mov	dx,word ptr ss:[bp-10]
	mov	si,word ptr ss:[bp-8]
	mov	di,word ptr ss:[bp-6]
	mov	ds,word ptr ss:[bp-2]
	mov	es,word ptr ss:[bp]
	mov	bp,word ptr ss:[bp-4]
skipreset:
	retf				; exit to terminate address

	subttl mosfun0d - disk reset
	page
;======================================================================
;,fs
; mosfun0d - disk reset
;
; flushes all file buffers
; files changed in size but not closed are not properly recorded in the
; disk directory.
;
; in:	
;
; out:	
;
;,fe
;======================================================================
	assume	ds:grp,ss:tcb,es:nothing
public	mosfun0d
mosfun0d:
	push	ds
	call	noswitch
	callmos2 flush

; invalidate bdb for each drive where [bdbcach] != 'Y' and for
; each removable drive.	 do it for all drives if [scbcach] != 'Y'

	mov	cx,[scbbdbpf]
mosf0d1:
	jcxz	mosf0d3
	push	cx
	mov	ds,cx
	assume	ds:bdb
	mov	ds,[bdbreal]
	cmp	[bdbcach],'Y'
	jne	mosf0d4
	push	es
	mgetscb es
	assume	es:grp
	cmp	[scbcach],'Y'
	pop	es
	assume	es:nothing
	jne	mosf0d4

; determine if media is removeable

	mov	dl,[bdbunit]		; dl = unit within block device driver
	mov	dh,[bdbid]		; dh = drive number
	lds	si,[bdbdrvr]
	assume	ds:nothing
	test	word ptr [si+4],0800h	; not removeable if
	jz	mosf0d2			; device doesn't support this call
	mov	al,15
	mov	ah,00h			; bit 7 clear for block device
	callmos2 devchk
	test	ah,02h
	jnz	mosf0d2			; return status indicates not removeable
mosf0d4:
	pop	ds			; recover bdb segment
	assume	ds:bdb
	push	ds
	callmos2 invbdb			; else invalidate all buffers for this bdb

; note a possible c error return here is ignored
; it occurs if somebody else hasn't dealt with a critical error while
; flushing to this volume, and this user chose fail or ignore from
; the critical error box

mosf0d2:
	pop	ds
	mov	cx,[bdbnext]
	jmp	mosf0d1
mosf0d3:
	call	okswitch
	pop	ds
	ret

	subttl mosfun0e - select disk
	page
;======================================================================
;,fs
; mosfun0e - select disk
;
; select the specified drive.
; the total number of drives (diskette and fixed) is returned in al.
;
; in:	tdl = drive number (0=a, 1=b, etc.)
;
; out:	tal = total number of drives
;
;,fe
;======================================================================
	assume	ds:grp,ss:tcb,es:nothing
public	mosfun0e
mosfun0e:
	push	ds
	push	dx
	call	maxdrive		; get maximum drive
	mov	[tal],al		; set # of drives
	mov	al,[tdl]		; get drive
	callmos2 findbdb		; find the bdb for the drive
	jc	mosf0eb			; if none found
	mov	ds,cx			; returns cdb pointer in cx
	assume	ds:cdb
	mov	al,[tdl]		; get drive again
	mov	byte ptr [tcbcdriv],al	; update current drive
	mov	[tcbcdbpc],ds		; also update pointer to default cdb
mosf0eb:
	pop	dx
	pop	ds
	ret

; maxdriv returns maximum drive for task
; returns svbdrivs or max(aliases)

	assume	ds:grp
maxdrive:				; return maximum drive in al
	mov	al,[scbdrivs]		; initialize max drive
	mov	dx,ss			; to test for our alias
	mov	cx,[scbbdbpf]		; first bdb
maxdrvlp:
	jcxz	maxdrvxit		; test end of device chain
	mov	ds,cx
	assume	ds:bdb
	mov	cx,[bdbnext]
	cmp	[bdbalias],0		; is it an alias
	je	maxdrvlp
	cmp	dx,[bdbtask]		; is it ours
	jne	maxdrvlp
	cmp	al,[bdbid]		; greater than current?
	ja	maxdrvlp
	mov	al,[bdbid]		; yes so get the id
	inc	al			; and bump to count
	jmp	maxdrvlp
maxdrvxit:
	ret

	subttl mosfun19 - current disk
	page
;======================================================================
;,fs
; mosfun19 - current disk
;
; determine the current default drive.
;
; in:	
;
; out:	tal = current default drive (0=a, 1=b, etc.)
;
;,fe
;======================================================================
	assume	ds:grp,ss:tcb,es:nothing
public	mosfun19
mosfun19:
	mov	al,[tcbcdriv]		; get current drive for this task
	mov	[tal],al		; return drive to user
	ret

	subttl mosfun1b - allocation table info
	page
;======================================================================
;,fs
; mosfun1b - allocation table info
;
; return information about the allocation table for the default drive.
;
; in:	
;
; out:	tds:tbx -> media descriptor byte for the default drive
;	tdx = number of allocation units
;	tal = number of sectors/allocation unit
;	tcx = size of physical sector
;
;,fe
;======================================================================
	assume	ds:grp,ss:tcb,es:nothing
mosfun1b:
	mov	al,[tcbcdriv]
fun1b1:
	call	noswitch
	mov	[tal],0ffh
	callmos2 finddrv
	jc	mosf1cb
	assume	ds:bdb
	mov	al,[bdbcsiz]		; sectors / cluster
	mov	[tal],al
	mov	cx,[bdbssiz]		; bytes / sector
	mov	[tcx],cx
	mov	dx,[bdbcnum]
	sub	dx,2
	mov	[tdx],dx		; number of clusters on disk
	mov	[tds],ds
	mov	[tbx],offset bdbmdia
	xor	al,al
mosf1cb:
	mov	[tcberrcod],al		; no extended error
	call	okswitch
	ret

	subttl mosfun1c - allocation info for drive
	page
;======================================================================
;,fs
; mosfun1c - allocation info for drive
;
; in:	tdl = driver number (0=a, 1=b, etc.)
;
; out:	tds:tbx -> media descriptor byte for drive in dl
;	tdx = number of allocation units
;	tal = number of sectors/allocation unit
;	tcx = size of physical sector
;
;,fe
;======================================================================
	assume	ds:grp,ss:tcb,es:nothing
public	mosfun1c
mosfun1c:
	mov	al,[tdl]
	dec	al
	jns	fun1c1
	jmp	mosfun1b		; return info for default drive
fun1c1:
	jmp	fun1b1			; return allocaion info for this drive

	subttl mosfun1f - get dpb for default drive
	page
;======================================================================
;,fs
; mosfun1f - get dpb for default drive
;
; get dpb for default drive
;
; in:	
;
; out:	tds:tbx points to dpb for default drive
;
;,fe
;======================================================================
	assume	ds:grp,ss:tcb,es:nothing
public	mosfun1f
mosfun1f proc
	mov	[tal],0ffh		; preset tal for error
	mov	al,[tcbcdriv]		; get current drive number
	jmp	entry1f			; in mosfun32
mosfun1f endp

	subttl mosfun25 - set interrupt vector
	page
;======================================================================
;,fs
; mosfun25 - set interrupt vector
;
; sets the interrupt vector table for the interrupt number
;
; in:	tds:tdx -> interrupt handling routine
;	tal = interrupt number
;
; out:	nothing, vector set (regrab table updated for int8,9)
;
;,fe
;======================================================================
	assume	ds:grp,ss:tcb,es:nothing
public	mosfun25
mosfun25:
	mov	bl,[tal]		; get interrupt number
	xor	bh,bh
	shl	bx,1			; calc offset for vector ( *4)
	shl	bx,1
	push	ds
	mgetzero ds
	mov	ax,[tdx]		; get users offset
	cli
	mov	[bx],ax			; set offset for vector
	mov	ax,[tds]		; get users segment
	mov	[bx+2],ax		; set segment for vector
	pop	ds
	assume	ds:grp
	test	[scbmmfea],04h		; is ivtable supported?
	jnz	fun25c
	cmp	bx,8*4
	jne	fun25b
	mov	bx,offset [regrab8_data]; when the lidt scheme is not supported
	jmp	short fun25a		; then must call the re-grab logic to
fun25b:					; maintain control
	cmp	bx,9*4
	jne	fun25c
	mov	bx,offset [regrab9_data]
fun25a:
	call	grab_back
fun25c:
	sti
	ret

	subttl mosfun26 - create new program segment
	page
;======================================================================
;,fs
; mosfun26 - create new program segment
;
; creates new program segment
; the entire 100h area at location 0 in the current psp is copied into
; location 0 in the new psp.  the memory size info at location 6 in the
; new psp is updated and the current termination, ctrl-break exit and
; critical error addresses from interrupt vector table entries for
; interrupts 22h, 23h, and 24h are saved in the new psp starting at
; 0ah.	they are restored from this area when the program terminates.
; the psp handle table pointer is also updated to reflect the segment
; of the new psp.
;
; in:	tdx = segment number for new psp
;
; out:	nothing, new psp created.
;
;,fe
;======================================================================
	assume	ds:grp,ss:tcb,es:nothing
public	mosfun26
mosfun26:

; copy from current psp to new psp

	mov	es,[tdx]		; get new psp address
	assume	es:pspseg
	push	ds
	mov	ds,[tcbpsp]		; get current psp address
	xor	si,si
	xor	di,di
	mov	cx,100h/2
	rep	movsw
	pop	ds

; put in far call to mos function dispatcher.

	mov	[pspcall],09ah		; op code for far call
	mov	word ptr [pspcall+3], 0f01dh
	mov	word ptr [pspcall+1], 0fef0h  ; far call to 0:c0 (default)

; now update the memory size info.

	mov	ax,[tdx]		; calc address difference
	mov	word ptr [psppntr+2],ax ; set psp handle table pointer
	mov	word ptr [psppntr],18h	; make sure you also set offset

; save ints 22h, 23h and 24h in psp starting at 0ah

	push	ds
	cld
	mgetzero ds
	mov	si,22h*4		; offset to start of vectors
	mov	di,offset psptrmv	; save space for vectors in psp
	mov	cx,3*2			; move 3 vectors
	rep	movsw
	pop	ds
	ret

	subttl mosfun29 - parse filename
	page
;======================================================================
;,fs
; mosfun29 - parse filename
;
; parses the specifed filename
; 
; in:	tds:tsi -> command line to parse
;	tes:tdi -> area to put unopened fcb
;	tal = bit value to control parsing
;		bit 0=1 leading separators are scanned off
;		bit 1=1 set drive fcb only if drive id found
;		bit 2=1 fcb filename only set if filename found
;		bit 3=1 fcb file extension only set if one found
;
; out:	tal = 00h if no global filename chars found
;	    = 01h if global filename chars used
;	    = ffh if drive specifier is invalid
;	tds:tsi -> 1st character after the file name
;	tes:tdi -> 1st byte of formatted fcb
;
;,fe
;======================================================================
	assume	ds:grp,ss:tcb,es:nothing

filesep db	32,09,':;,=+'		; filename separators
seplen	equ	$-filesep
	db	'.<>|/"[]\',0		; filename terminators

termlen equ	$-filesep

public	mosfun29
mosfun29:
	push	ds
	mov	ax, cs
	mov	es, ax
	assume	ds:nothing, es:mos

; init fcb info (clear filename and ext to blanks and set drive to
; use default)

	cld
	mov	ds,[tes]		; get pointer to fcb
	mov	si,[tdi]		; "     "	"
	xor	ax,ax
	mov	[si+fcbcb],ax		; clear current block field
	mov	[si+fcbrec],ax		; clear current block field
	test	[tal],2			; init drive id?
	jnz	fun29a1			; no
	mov	[si+fcbdrv],0		; init drive id
fun29a1:
	xor	cx,cx
	lea	di,[si+fcbext]		; start fill at extension
	test	[tal],4			; init filename?
	jnz	fun29a2			; no
	lea	di,[si+fcbfile]		; start fill at file
	mov	cx,8
fun29a2:
	test	[tal],8			; init extension?
	jnz	fun29a3			; no
	add	cx,3			; include extension to fill with blanks
fun29a3:
	jcxz	fun29a4			; do not clear either
	mov	al,20h			; clear filename to blanks
	push	es
	mov	es,[tes]		; get fcb pointer
	rep	stosb			; clear to blanks
	pop	es

; scan off leading separators if needed and specified

fun29a4:
	mov	si,[tsi]		; get users string pointer
	mov	ds,[tds]		; "     "	"
	dec	si			; set up for loop
fun29a:
	test	[tal],1			; scan off leading separators?
	jz	fun29b			; no, just spaces and tabs (1st 2 in table)
	mov	cx,seplen		; yes, scan off all separators
	mov	al,[si+1]		; is the current char a separator ?
	mov	di,offset filesep
	repne	scasb		
	jne	fun29b			; if not, proceed as before
	inc	si			; if yes, skip to next char
fun29b:
	mov	cx,2		
	inc	si			; next char
	mov	al,[si]			; get next char from string
	mov	di,offset filesep	; valid separator table
	repne scasb			; check for separator
	je	fun29b		

; non-separator found, assume start of drive, file, or extension

	mov	[tal],0			; set default of no global characters
	call	f29drv			; parse out drive id
	call	f29file			; parse out filename
	call	f29ext			; parse out extension
fun29c:
	mov	al,[si]			; get next char
	call	chkend			; check for end separator
	jz	fun29e			; separator found
	inc	si			; search for separator
	jmp	fun29c
fun29e:
	mov	[tsi],si		; return pointer
	pop	ds
	ret				; end mosfun29

	subttl f29drv - fun29 helper
	page
;======================================================================
;,fs
; f29drv - fun29 helper
;
; in:	ds:si -> current string location
;
; out:	
;
;,fe
;======================================================================
f29drv proc near
	cmp	byte ptr [si+1],':'	; check for drive
	jne	f29drve			; no, exit
	lodsb				; get drive letter
	inc	si			; skip ':'
	call	caps			; uppercase
	sub	al,'A'			; calc drive number (a=1, b=2 ...)

; determine if drive id is valid

	push	ds
	push	cx
	push	dx
	push	ax
	callmos2 findbdb		; find bdb for this disk
	pop	ax
	pop	dx
	pop	cx
	pop	ds
	jnc	f29a			; if drive found
	mov	[tal],0ffh		; no, tell user invalid drive
f29a:
	push	es
	mov	es,[tes]		; get users pointer to fcb
	mov	bx,[tdi]		; "     "	"
	inc	al
	mov	es:[bx+fcbdrv],al	; set drive in fcb
	pop	es
f29drve:
	ret

f29drv endp
	subttl f29file - fun29 helper
	page
;======================================================================
;,fs
; f29file - fun29 helper
;
; parse filename from string and put in fcb file space as uppercase
; on entry ds:si -> current string location
;
; in:	
;
; out:	
;
;,fe
;======================================================================
f29file proc near
	mov	cx,8			; char counter
	mov	es,[tes]		; tcb pointer
	mov	di,[tdi]
	lea	di,[di+fcbfile]		; set pointer to filename field
f29file2:
	mov	al,[si]
	call	chkend			; check for terminating character
	jz	f29file1		; found one
	cmp	al,'?'
	jne	f29f1
	or	[tal],1			; flag user that globals are being used
	jmp	f29f3			; skip uppercase convert
f29f1:
	cmp	al,'*'
	jne	f29f2
	or	[tal],1			; flag user that globals are being used
	mov	al,'?'
	inc	si			; update string pointer
	rep	stosb			; fill rest of filename with '?'
	jmp	f29file3		; thats it
f29f2:
	call	caps
f29f3:
	stosb
	inc	si
	loop	f29file2
f29file1:
	mov	al,[si]
	call	chkend			; is this a terminator character?
	jz	f29file4		; if it's really the end
	inc	si		
	jmp	f29file1		; if it isn't a terminator, find terminator
f29file4:
	jcxz	f29file3		; 8 char filename found exit
	cmp	cx,8			; any filename found?
	je	f29file3
	mov	al,20h			; pad rest of string with spaces
	rep	stosb
f29file3:
	ret

f29file endp

	subttl f29ext - fun29 helper
	page
;======================================================================
;,fs
; f29ext - fun29 helper
;
; parse extension from string and put in fcb file space as uppercase
; on entry ds:si -> current string location
;
; in:	
;
; out:	
;
;,fe
;======================================================================
f29ext proc near
	mov	al,[si]			; get next char
	call	chkend			; check for end separator
	jz	f29ext1			; separator found check for '.'
	inc	si			; search for separator
	jmp	f29ext
f29ext1:
	cmp	al,'.'			; is this the start of an extension?
	jne	f29exte			; no, must be the end of the string
	inc	si			; skip '.'
	mov	cx,3			; char counter
	mov	es,[tes]		; tcb pointer
	mov	di,[tdi]
	lea	di,[di+fcbext]		; set pointer to extension field
f29ext3:
	mov	al,[si]
	call	chkend			; check for terminating character
	jz	f29ext2			; found one
	cmp	al,'?'
	jne	f29e1
	or	[tal],1			; flag user that globals are being used
	jmp	f29e3			; skip uppercase convert
f29e1:
	cmp	al,'*'
	jne	f29e2
	or	[tal],1			; flag user that globals are being used
	mov	al,'?'
	inc	si			; update string pointer
	rep	stosb			; fill rest of extension with '?'
	jmp	f29exte			; thats it
f29e2:
	call	caps
f29e3:
	stosb
	inc	si
	loop	f29ext3
f29ext2:
	jcxz	f29exte			; 3 char filename found exit
	cmp	cx,3			; any filename found?
	jne	f29e4
	cmp	byte ptr [si-1],'.'	; if ending in '.' then blank ext.
	jne	f29exte
f29e4:
	mov	al,20h			; pad rest of string with spaces
	rep	stosb
f29exte:
	ret
f29ext endp

	subttl chkend - check for separator
	page
;======================================================================
;,fs
; chkend - check for separator
;
; check char in al for terminating separator.  on exit zf=1 if the
; character is arnold schwartzenegger.
;
; in:	
;
; out:	
;
;,fe
;======================================================================
chkend proc near
	push	cx
	push	di
	push	es
	mov	cx, cs
	mov	es, cx
	cmp	al,26			; check for control characters
	ja	chk1
	xor	cx,cx			; set zf=1
	jmp	chk2
chk1:
	mov	di,offset filesep	; valid separator table
	mov	cx,termlen
	repne	scasb			; check for separator
chk2:
	pop	es
	pop	di
	pop	cx
	ret
chkend endp

	subttl mosfun2a - get date
	page
;======================================================================
;,fs
; mosfun2a - get date
;
; returns the day of the week, year, month, and day.  if the time-of-
; day clock rolls over to the next day, the date is adjusted
; accordingly, taking into account the number of days in each month and
; leap years.
;
; in:	
;
; out:	tal = day of week (0=sun - 6=sat)
;	tcx = year (1980 - 2099)
;	tdh = month (1-12)
;	tdl = day (1-31)
;
;,fe
;======================================================================
	assume	ds:grp,ss:tcb,es:nothing
public	mosfun2a
mosfun2a:
	call	getdate
	mov	[tal],al
	mov	[tcx],cx
	mov	[tdx],dx
	ret

	subttl mosfun2b - set date
	page
;======================================================================
;,fs
; mosfun2b - set date
;
; sets the date.
;
; in:	tcx = year (1980 - 2099)
;	tdh = month (1-12)
;	tdl = day (1-31)
;
; out:	tal = 00h if the date is valid, ffh if the date is invalid
;
;,fe
;======================================================================
	assume	ds:grp,ss:tcb,es:nothing
	public	maxdays

maxdays db	31,28,31,30,31,30,31,31,30,31,30,31

public	mosfun2b
lproc mosfun2b
lstring reqhead,26
lstring datebuffer,6
lbyte leap
	mov	bx,bp
	mov	bp,[bp]			; address task registers
	mov	byte ptr [tal],0
	mov	ax,[tcx]		; get year
	mov	bp,bx
	cmp	ax,1980
	jb	jdca1
	cmp	ax,2099
	ja	jdca1
	sub	ax,1980
	xor	dx,dx
	mov	bx,4
	div	bx
	mov	di,ax
	mov	byte ptr [leap],0
	or	dx,dx
	jnz	dca2
	mov	byte ptr [leap],1
dca2:
	mov	bx,bp
	mov	bp,[bp]
	mov	al,[tdh]		; get month
	mov	bp,bx
	cmp	al,12
	ja	jdca1
	or	al,al
	jnz	dca25
jdca1:
	jmp	dca1
dca25:
	xor	ah,ah
	mov	si,ax
	dec	si
	mov	bx,offset [maxdays]
	mov	cl,mos:[bx+si]		; get max number of days for month
	cmp	al,2			; is it february?
	jne	dca3
	add	cl,[leap]		; if feb, add the leap year factor (0 or 1)
dca3:
	mov	bx,bp
	mov	bp,[bp]			; address task registers
	mov	al,[tdl]		; get days
	mov	bp,bx
	cmp	al,cl
	ja	jdca1
	or	al,al
	jz	jdca1
	push	dx
	mov	ax,di
	xor	dx,dx
	mov	bx,1461
	mul	bx
	pop	dx
	or	dx,dx
	jz	dca4
	add	ax,366
	dec	dx
	mov	si,ax
	mov	ax,dx
	xor	dx,dx
	mov	bx,365
	mul	bx
	add	ax,si
dca4:
	mov	bx,bp
	mov	bp,[bp]			; address task registers
	cmp	byte ptr [tdh],1
	mov	bp,bx
	je	dca7
	mov	cx,1
dca5:
	mov	si,cx
	dec	si
	mov	bx,offset [maxdays]
	mov	bl,mos:[bx+si]		; get max number of days for month
	cmp	cl,2			; is it february?
	jne	dca6
	add	bl,[leap]		; if feb, add the leap year factor (0 or 1)
dca6:
	xor	bh,bh
	add	ax,bx
	inc	cx
	mov	bx,bp
	mov	bp,[bp]			; address task registers
	cmp	cl,[tdh]
	mov	bp,bx
	jne	dca5
dca7:
	mov	bx,bp
	mov	bp,[bp]			; address task registers
	mov	cl,[tdl]		; get days
	mov	bp,bx
	xor	ch,ch
	dec	cx
	add	ax,cx			; ax is now day count
	push	ax
	mov	byte ptr [reqhead],26	; set rh length
	mov	byte ptr [reqhead+2],4	; input read from mosddclk
	lea	bx,[datebuffer]
	mov	word ptr [reqhead+14],bx; set transfer address
	mov	ax,ss
	mov	word ptr [reqhead+16],ax
	call	callclk
	pop	ax
	mov	word ptr [datebuffer],ax
	mov	byte ptr [reqhead+2],8	; write to mosddclk
	call	callclk
	jmp	dca9

	subttl callclk - call the clock driver
	page
;======================================================================
;,fs
; callclk - call the clock driver
;
; in:	
;
; out:	
;
;,fe
;======================================================================
callclk proc near
	push	ds
	lds	si,[scbstdclk]
	mov	bx, ss			; es=ss
	mov	es, bx
	lea	bx,[reqhead]
	mov	ah,80h
	xor	cx,cx
	callmos2 todriver		; call the clock driver
	pop	ds
	ret
callclk endp

dca1:
	mov	bx,bp
	mov	bp,[bp]			; address task registers
	mov	byte ptr [tal],0ffh	; invalid date
	mov	bp,bx
dca9:

lundef reqhead
lundef datebuffer
lundef leap
lendp	mosfun2b

	subttl mosfun2c - get time
	page
;======================================================================
;,fs
; mosfun2c - get time
;
; returns the time - hours, minutes, seconds and hundredths of a second
;
; in:	
;
; out:	tch = hours (0-23)
;	tcl = minutes (0-59)
;	tdh = seconds (0-59)
;	tdl = hundredths (0-99)
;
;,fe
;======================================================================
	assume	ds:grp,ss:tcb,es:nothing
public	mosfun2c
mosfun2c:
	call	gettime
	mov	[tcx],cx
	mov	[tdx],dx
	ret

	subttl mosfun2d - set time
	page
;======================================================================
;,fs
; mosfun2d - set time
;
; set the time
;
; in:	tch = hours (0-23)
;	tcl = minutes (0-59)
;	tdh = seconds (0-59)
;	tdl = hundredths (0-99)
;
; out:	tal = 00h if the time is valid, ffh if the time is invalid
;
;,fe
;======================================================================
	assume	ds:grp,ss:tcb,es:nothing
public	mosfun2d
lproc mosfun2d
lstring reqhead,26
lstring datebuffer,6
	mov	bx,bp
	mov	bp,[bp]			; address task registers
	mov	byte ptr [tal],0
	cmp	byte ptr [tch],23
	ja	tc1
	cmp	byte ptr [tcl],59
	ja	tc1
	cmp	byte ptr [tdh],59
	ja	tc1
	cmp	byte ptr [tdl],99
	jna	tc2
tc1:
	mov	byte ptr [tal],0ffh
	mov	bp,bx
	jmp	tc3
tc2:
	mov	bp,bx
	mov	byte ptr [reqhead],26	; set rh length
	mov	byte ptr [reqhead+2],4	; input read from mosddclk
	lea	bx,[datebuffer]
	mov	word ptr [reqhead+14],bx ; set transfer address
	mov	ax,ss
	mov	word ptr [reqhead+16],ax
	call	callclk
	push	bp
	mov	bp,[bp]
	mov	ax,word ptr [tcl]
	mov	bx,word ptr [tdl]
	pop	bp
	mov	word ptr [datebuffer+2],ax
	mov	word ptr [datebuffer+4],bx
	mov	byte ptr [reqhead+2],8	; write to mosddclk
	call	callclk
tc3:

lundef reqhead
lundef datebuffer
lendp	mosfun2d

	subttl mosfun2e - set/reset verify switch
	page
;======================================================================
;,fs
; mosfun2e - set/reset verify switch
;
; sets the verify switch.
;
; in:	tal = 00h to set verify off, 01h to set verify on
;
; out:	
;
;,fe
;======================================================================
	assume	ds:grp,ss:tcb,es:nothing
public	mosfun2e
mosfun2e:
	mov	al,[tal]
	mov	[tcbvflg],al		; tasks verify flag
	ret

	subttl mosfun30 - get dos version number
	page
;======================================================================
;,fs
; mosfun30 - get dos version number
;
; in:	if tax=tbx=tcx=tdx then return mos version else return dos ver.
;
; out:	tal = major version number
;	tah = minor version number
;	tbx = 0000h (who the hell knows why, ibm)	not done by mos
;	tcx = 0000h "   "	"       "		"       "
;	if mos version returned bx = type code (beta or special or etc)
;
;,fe
;======================================================================
	assume	ds:grp,ss:tcb,es:nothing
public	mosfun30, mosfunxx
mosfun30:
	mov	ax,[tax]		; check which version wanted
	cmp	ax,[tbx]
	jne	mosf30a
	cmp	ax,[tdx]
	jne	mosf30a
	cmp	ax,[tcx]
	jne	mosf30a
	mov	ax,[scbversn+2]		; get mos version
	mov	bx,[scbversn+4]		; get type code
	mov	[tbx],bx		; return to user
	jmp	mosf30b
mosf30a:

; if tal == 1, bx = cx = 0000, else, bx = ff00, cx = 0000

	mov	[tbx],0
	mov	[tcx],0
	or	al,al
	jnz	mosf30c
	mov	[tbx],0ff00h
mosf30c:
	mov	ax,[tcbversn]		; get dos (not mos) version
mosf30b:
	mov	[tax],ax		; return to user
mosfunxx:
	ret

	subttl mosfun31 - terminate process and remain resident
	page
;======================================================================
;,fs
; mosfun31 - terminate process and remain resident
;
; terminates the current process and shrinks the current memory block
; down to the specified size.
; files opened by the process are not closed.
;
; in:	tal = return code
;	tdx = memory size in paragraphs
;
; out:	
;
;,fe
;======================================================================
	assume	ds:grp,ss:tcb,es:nothing
public	mosfun31
mosfun31:
	mov	bx,[tdx]		; get requested resident module size
	cmp	bx,6			
	jae	mf31g6			; if less than 6 para's
	mov	bl,6			; than set it to 6
mf31g6:					
	mov	[tcx],bx		; pass back address to exec caller
	mov	cx,[tcbpsp]		; get current psp
	mov	si,cx			; save for later
	dec	cx
	mov	es,cx			; back up to address mcb header
	assume	es:mbseg
	mov	di,[mbsize]

; if available >= request then skip on to the 4a call - all is well
; else, check next mcb

	cmp	di,bx
	jnb	fun31a
	add	cx,di			
	inc	cx			
	mov	es,cx

; if owned by the module now terminating, modify their request	
; else, let the 4a call error out	
	
	cmp	si,[mbowner]
	jne	fun31a
	mov	bx,di			
fun31a:
	mov	es,si
	mov	ah,4ah			; shrink allocation down
	domos
	jnc	fun31b
	mov	ax,'13'
	jmp	funerr
fun31b:
	mov	ax,es
	dec	ax			; mcb for the psp
	mov	es,ax
	assume	es:mbseg
	mov	bx,[mbowner]		; owner of mcb (psp address)
	add	bx,[mbsize]		; length of the block in paragraphs
	inc	ax			; back to psp
	mov	es,ax
	assume	es:pspseg
	mov	[pspmem],bx		; set the end of allocation field
	mov	al,[tal]
	mov	ah,3			; fun31 termination code for wait
	mov	[tcbretc],ax
	jmp	fun00b			; continue with normal termination

	subttl mosfun32 - get dpb
	page
;======================================================================
;,fs
; mosfun32 - get dpb
;
; get dpb for a drive.
; has entry point for function 1f, get dpb for default drive.
;
; in:	tdl contains disk drive number ( 0 for default, 1 for a, etc.)
;
; out:	tal 0ffh if an error
;	if no error,
;	tal is 0
;	tds:tbx -> dpb for drive
;
;,fe
;======================================================================
	assume	ds:grp,ss:tcb,es:nothing
public	mosfun32
mosfun32:
	mov	[tal],0ffh		; preset error
	mov	al,[tdl]
	dec	al
	jns	mosf32a
	mov	al,[tcbcdriv]
entry1f:
mosf32a:
	call	noswitch
	callmos2 finddrv
	mov	[tcberrcod],al
	jc	mosf32b
	assume	ds:bdb
	mov	[tds],ds		; pointing to dpb portion of bdb
	mov	[tbx],offset bdbdpb
	mov	[tal],0
	mov	[tcberrcod],0
mosf32b:
	call	okswitch
	ret

	subttl mosfun33 - ctrl-break check, + misc svcs
	page
;======================================================================
;,fs
; mosfun33 - ctrl-break check, + misc svcs
;
; get cntrl-c flag state
; ======================
; in:	tal = 0
;
; out:	tdl = 00h if break os off
;	      01h if break is on
;
; set cntrl-c flag state
; ======================
; in:	tal = 1
;
; out:	none
;
; get boot drive
; ==============
; in:	tal = 5
;
; out:	tdl = startup drive number (1 for A:, 2 for B:, etc.)
;
; get true dos version
; ====================
; in:	tal = 6
;
; out:	tbl = major version number
;	tbh = minor version number
;	tdl = the low three bits of the revision number (0)
;	tdh = flag bits:
;		b3 is set if running in rom (0 for now)
;		b4 is set if dos is in the hma (0 for now)
;
;,fe
;======================================================================
	assume	ds:grp,ss:tcb,es:nothing
public	mosfun33
mosfun33:
	mov	al,[tal]		; get request command
	cmp	al,0
	je	fun33_0
	cmp	al,1
	je	fun33_1
	cmp	al,5
	je	fun33_5
	cmp	al,6
	je	fun33_6
	mov	[tal],0ffh		; return error has ffh
	jmp	short fun33end

; entry al = 0, get break flag state

fun33_0:
	mov	al,[tcbbrk]
	mov	[tdl],al
	jmp	short fun33end

; entry al = 1, set break flag state

fun33_1:
	mov	al,[tdl]
	and	al,1			; only accept 0 or 1
	mov	[tcbbrk],al
	jmp	short fun33end

; entry al = 5, get boot drive

fun33_5:
	mov	al,[scbbootdrv]
	inc	al
	mov	[tdl],al
	jmp	short fun33end

; entry al = 0, get true dos version

fun33_6:
	mov	ax,[scbversn]		; get dos (not mos) version
	mov	[tbx],ax
	mov	[tdx],0
fun33end:
	ret

	subttl mosfun35 - get interrupt vector
	page
;======================================================================
;,fs
; mosfun35 - get interrupt vector
;
; gets the interrupt vector table for the interrupt number
;
; in:	tal = interrupt number
;
; out:	tes:tbx -> interrupt handling routine
;
;,fe
;======================================================================
	assume	ds:grp,ss:tcb,es:nothing
public	mosfun35
mosfun35:
	mov	bl,[tal]		; get interrupt number
	xor	bh,bh
	shl	bx,1			; calc offset for vector ( *4)
	shl	bx,1
	push	ds
	mgetzero ds
mfun35ex:
	cli
	mov	ax,[bx]			; get offset for vector
	mov	[tbx],ax		; return to user
	mov	ax,[bx+2]		; get segment for vector
	mov	[tes],ax		; return to user
	sti
	pop	ds
	ret

	subttl mosfun36 - get disk free space
	page
;======================================================================
;,fs
; mosfun36 - get disk free space
;
; returns the disk free space (available clusters, clusters/drive,
; bytes/sector
;
; in:	tdl = drive (0=default, 1=a, etc.)
;
; out:	tbx = available clusters
;	tdx = clusters/drive
;	tcx = bytes/sector
;	tax = ffffh if drive invalid or sector/cluster
;
;,fe
;======================================================================
	assume	ds:grp,ss:tcb,es:nothing
public	mosfun36
mosfun36:
	mov	[tax],0ffffh		; preset error
	mov	al,[tdl]
	dec	al
	jns	mosf36a
	mov	al,[tcbcdriv]
mosf36a:
	call	noswitch
	callmos2 finddrv
	jnc	$+5
	jmp	mosf36y
	assume	ds:bdb

; compute the number of available clusters

	mov	dx,[bdbcfree]
	cmp	dx,-1
	je	$+5
	jmp	mosf36x			; ne if # free clusters is valid
	xor	dx,dx			; number of unused clusters so far
	xor	bx,bx			; current fat sector
	mov	cx,[bdbcnum]
	sub	cx,2
	cmp	cx,4096-10-2
	jbe	mosf36e			; a if 16-bit fat entries (too big for 12-bit)
mosf36b:
	call	mosf36rf
	assume	es:dbb
	mov	si,[bdbssiz]		; size of sector
	lea	di,[dbbbuf]		; current offset in fat sector buffer
	xor	ax,ax
	or	bx,bx		
	jnz	mosf36c			; if first fat sector add 4 to
	add	di,4			; to offset
	sub	si,4		
mosf36c:
	jcxz	mosf36xx	
	scasw
	jne	mosf36d
	inc	dx			; 1 more unused if 0 in fat entry
mosf36d:
	dec	si
	dec	si
	loopnz	mosf36c
	jnz	mosf36x			; nz if cx = 0 and finished
	inc	bx			; else finished with this sector, get next
	jmp	mosf36b
mosf36xx:			
	jmp	mosf36x		

; fat contains 12-bit entries

mosf36e:
	call	mosf36rf
	assume	es:dbb
	mov	di,3

; this is for the low-order 12-bits of a 24-bit fat entry pair

mosf36f:
	mov	al,es:[dbbbuf+di]
	inc	di
	cmp	di,[bdbssiz]
	jb	mosf36g			; b if don't need to read next fat sector
	inc	bx			; next sector
	mov	di,ax			; save low 8-bits of entry
	call	mosf36rf
	mov	ax,di
	xor	di,di
mosf36g:
	mov	ah,es:[dbbbuf+di]
	test	ax,0fffh
	jnz	mosf36h			; nz if entry is used
	inc	dx			; else one more unused
mosf36h:
	dec	cx			; and one more checked
	jz	mosf36x			; z if all checked
	mov	al,ah			; preparing for next 12-bits of 24-bit pair
	inc	di
	cmp	di,[bdbssiz]
	jb	mosf36i			; b if don't need next sector
	inc	bx
	mov	di,ax
	call	mosf36rf
	mov	ax,di
	xor	di,di
mosf36i:
	mov	ah,es:[dbbbuf+di]	; high 8-bits of second 12-bits of pair
	test	ax,0fff0h
	jnz	mosf36j			; nz if used
	inc	dx			; else one more unused
mosf36j:
	dec	cx			; and one more checked
	jz	mosf36x			; z if all checked
	inc	di			; bump to next 24-bit pair
	cmp	di,[bdbssiz]
	jb	mosf36f			; read next fat sector if needed
	inc	bx
	mov	di,ax
	call	mosf36rf
	mov	ax,di
	xor	di,di
	jmp	mosf36f
mosf36x:
	mov	al,[bdbcsiz]		; number of sectors per cluster
	xor	ah,ah
	mov	[tax],ax
	mov	cx,dx
	callmos2 setfree		; set free clusters on disk
	mov	[bdbcfree],dx		; number of free clusters is valid now
	mov	[tbx],dx		; number of free clusters
	mov	cx,[bdbssiz]
	mov	[tcx],cx		; sector size in bytes
	mov	dx,[bdbcnum]
	sub	dx,2
	mov	[tdx],dx		; total clusters on disk
	xor	al,al			; no extended error
mosf36y:
	mov	[tcberrcod],al
	call	okswitch
	ret

	subttl mosf36rf - helper for fun36
	page
;======================================================================
;,fs
; mosf36rf - helper for fun36
;
; in:	
;
; out:	
;
;,fe
;======================================================================
mosf36rf proc near
	callmos2 rdfat
	jc	$+3
	ret
	pop	dx
	jmp	mosf36y
mosf36rf endp

	subttl mosfun37 - get/set switch character
	page
;======================================================================
;,fs
; mosfun37 - get/set switch character
;
; gets and sets the command line switch character.  ms-dos allows two
; different command line switches: slash (/) and dash (-).  the slash
; was the original command line parameter separator character in dos 1.
; when they tried to make dos into unix, they decided that they liked
; slashes between file specs, and dashes as parameter separators, so
; this undocumented call was added to switch between old dos (/ on
; command line, \ between file names), and unix (- on command line, /
; between file names).
;
; this call only supports get switch character function, and it always
; returns / as the command line separator character.
;
; in:	tal = 0 if this is a get switchchar call
;	tal = 1 if this is a set switchchar call
;	tdl = '-' (2dh) or
;	      '/' (2fh) if this is a set switchchar call
;
; out:	tdl = new switch character
;
;,fe
;======================================================================
	assume	ds:grp,ss:tcb,es:nothing
public	mosfun37
mosfun37:
	mov	al,[tal]		; get function code
	or	al,al			; only allow subfunction 0
	jz	mosfun37a		; if no error in calling
	mov	ax,error_invalid_function
	jmp	short mosfun37e
mosfun37a:
	mov	[tdl],'/'		; say "SWITCHCHAR is /"
mosfun37e:
	cbw				; make al into a word
	callmos2 moserror		; set error codes appropriately
	ret

	subttl casecon - case conversion routine
	page
;======================================================================
;,fs
; casecon - case conversion routine
;
; in:	al= char to convert to uppercase
;
; out:	
;
;,fe
;======================================================================
casecon proc far
	call	caps
	ret
casecon endp

	subttl mosfun38 - get/set country info
	page
;======================================================================
;,fs
; mosfun38 - get/set country info
;
; gets and sets country dependent information
;
; in:	tds:tdx -> buffer where info will be returned
;	tal = 00h to get current country info
;	see manual for this crap!!!
;
; out:	
;
;,fe
;======================================================================
	assume	ds:grp,ss:tcb,es:nothing
public	mosfun38
mosfun38:
	xor	ah,ah			; word sized country code
	mov	al,[tal]		; requested country code
	cmp	al,0ffh			; code in bx?
	jb	mf3820			; if already have code
	mov	ax,[tbx]		; word sized country code
mf3820:
	cmp	[tdx],0ffffh		; get or set?
	je	mf38100			; if set

; get country information

	or	ax,ax			; get info for current code?
	jnz	mf3830			; if for specified code
	mov	ax,[scbcntry]		; get current code
	or	ax,ax			; is current code 0?
	jne	mf3830			; if not 0
	mov	si,offset usainfo	; if 0, return us info
	jmp	short mf3860
mf3830:
	call	fndccode
	jc	mf38115
mf3860:
	mov	[tbx],ax		; country code requested
	mov	[tax],ax		; to ax also (just like dos)
	inc	si
	inc	si			; start one word further
	cld
	mov	es,[tds]
	mov	di,[tdx]
	mov	bl,[si+9]		; get format bits
	call	mf38x2			; extract date format
	stosb				; 2nd byte of date format
	movsw				; currency symbols
	movsw
	stosb
	movsb				; thousands separator
	stosb
	movsb				; decimal separator
	stosb
	movsb				; date separator
	stosb
	movsb				; time separator
	stosb
	call	mf38x2			; currency format
	call	mf38x2			; currency significant digits
	call	mf38x2			; time format
	mov	ax,offset mos:casecon
	stosw
	mov	ax,cs
	stosw
	movsb				; data list separator
	xor	ax,ax

; following changes are necessary for skplus, skplus places this information
; on its stack and requires that the lenght to exactly match, under dos 3.2
; we can only fill out 32 bytes, if planning to change the following lines of
; code, please run skplus to make sure that its requirements are still in
; effect

	mov	cx,9			; fill out to 32 bytes
	cmp	word ptr [tcbversn],1403h  ; is this for dos 3.20
	je	notdos33
	add	cx,2			; make it 34 bytes for dos 3.30 support
notdos33:
	rep	stosb
	xor	ax,ax			; success return code
	jmp	short mf38x		; return to caller

; set country code

mf38100:
	or	ax,ax			; did they want to set country 0?
	jz	mf38120			; yes, jump
	call	fndccode
	jnc	mf38120
mf38115:
	mov	ax,error_file_not_found
	jmp	short mf38x
mf38120:
	mov	[scbcntry],ax		; set new country code
	xor	ax,ax
mf38x:
	callmos2 moserror
	ret

	subttl mf38x2 - helper for fun38
	page
;======================================================================
;,fs
; mf38x2 - helper for fun38
;
; in:	
;
; out:	
;
;,fe
;======================================================================
mf38x2 proc near
	mov	al,bl
	and	al,3
	stosb
	shr	bl,1
	shr	bl,1
	xor	ax,ax
	ret
mf38x2 endp

	subttl fndccode - helper for fun38
	page
;======================================================================
;,fs
; fndccode - helper for fun38
;
; find country code in ax.  changes si and di.
; returns cy set if code not found, cy clear if code found.
; if cy clear, returns pointer to country info in si.
;
; in:	
;
; out:	
;
;,fe
;======================================================================
fndccode proc
	mov	si,offset [usainfo]	; first country in table
findc10:
	mov	di,[si]			; get next country code
	or	di,di			; last code?
	jz	findc20			; if end of the table
	cmp	ax,di			; is this the right country code?
	je	findc30			; yes, return "OK"
	add	si,usalen		; no, check next country
	jmp	findc10
findc20:
	stc
findc30:
	ret
fndccode endp

	subttl mosfun48 - allocate memory
	page
;======================================================================
;,fs
; mosfun48 - allocate memory
;
; allocates the requested number of paragraphs of memory.
;
; in:	tbx = number of paragraphs
;
; out:	tax:0 -> allocated block or error code if cy
;	tbx = size of largest block available if fail
;
; errors:
;	error_arena_trashed
;	error_not_enough_memory
;
;,fe
;======================================================================
	assume	ds:grp,ss:tcb,es:nothing
public	mosfun48
mosfun48 proc near

; ax will hold the block size needed
; bx will hold the segment address of the current block
; cx will hold the largest available block size

	xor	bx,bx			; no mb address to check
	call	mmsetup			; validate mb chain
	assume	es:grp,ds:nothing
	jnc	fun48f
	callmos2 moserror		; error in block chain
	jmp	fun48end
fun48f:
	call	blkmrch
	xor	cx,cx			; start with 0 block size available
	mov	ax,[tbx]		; get # para's needed
	mov	bx,[tcbmbpf]		; get pointer to 1st memory block in task
	mov	[tcb_malloc_mark],0	; invalidate block


; search for large enough free block

fun48a:
	mov	ds,bx			; address current mb prefix
	assume	ds:mbseg
	cmp	word ptr [mbowner] ,0	; is this block free?
	je	fun48a1			; no, try next block
	jmp	fun48b
fun48a1:

; check for larger available block size, update if found

	cmp	cx,[mbsize]		; check for larger size available
	ja	fun48c			; no this is smaller than the last one checked
	mov	cx,[mbsize]		; yes, update largest available
fun48c:
	cmp	ax,[mbsize]		; is this block large enough for request?
	jbe	fun48c1
	jmp	fun48b			; no, try next block
fun48c1:	
	cmp	[tcb_malloc_strategy],2
	jne	fun48mark
	mov	[tcb_malloc_mark],bx	; save mark block
	jmp	short fun48b	


fun48mark:
; suitable block found, mark it as used by this caller

	mov	bx,[tcbpsp]		; get callers psp address
	mov	[mbowner],bx		; set current psp as owner of this mb
	mov	bx,[mbsize]		; get current size
	sub	bx,ax			; calc size left over
	or	bx,bx			; is this a perfect fit (exact block size)
	jz	fun48e			; yes, exit

; split off excess size into free block

	dec	bx			; do not include prefix in size
	mov	cx,ds			; pointer to current mb prefix
	inc	cx			; point past current mb prefix


	cmp	[tcb_malloc_strategy],2	; is this this last fit
	jne	fun48setlow
;
;	this is special case of trying  to load a memory block high
;
	mov	word ptr [mbowner],0	; set as free block
	sub	[mbsize],ax
	dec	[mbsize]
	add	cx,[mbsize]
	mov	bl,[mbtype]		; get type of current block
	mov	byte ptr [mbtype],'M'	; set current as not last block
	mov	ds,cx
	mov	[mbtype],bl		; set as type of new block
	mov	[mbsize],ax
	mov	bx,[tcbpsp]
	mov	[mbowner],bx
	jmp	short fun48e

fun48setlow:
	mov	[mbsize],ax		; set new size 
	add	cx,ax			; point to new block address
	mov	al,[mbtype]		; get type of current block
	push	ds
	mov	ds,cx			; address new mb prefix
	mov	[mbtype],al		; set as type of new block
	mov	[mbsize],bx
	mov	word ptr [mbowner],0	; set as free block
	pop	ds
	mov	byte ptr [mbtype],'M'	; set current as not last block
	jmp	short fun48e		; all done, exit

; point to next block if not the last one

fun48b:
	cmp	byte ptr [mbtype],'Z'	; is this the last block?
	je	fun48d			; yes, exit with largest available
	inc	bx			; point past mb itself
	add	bx,[mbsize]		; point to next block
	jmp	fun48a			; check next block

; set exit registers

fun48e:
	mov	ax,ds
	inc	ax			; point past mb prefix
	mov	[tax],ax		; tell user address of block
	and	[tflag],not carry	; make sure carry cleared
	jmp	short fun48end		; that's it
fun48d:
	cmp	[tcb_malloc_mark],0	; did we mark a block
	je	fun48d1
	mov	ds,[tcb_malloc_mark]
	jmp	fun48mark
fun48d1:	
	mov	[tbx],cx		; return largest available
	mov	[tax],error_not_enough_memory
	or	[tflag],carry		; set users carry
fun48end:
	push	es			; restore standard segregs
	pop	ds
	assume	ds:grp,es:nothing
	ret
mosfun48 endp

	subttl mosfun49 - free allocated memory
	page
;======================================================================
;,fs
; mosfun49 - free allocated memory
;
; frees the specified allocted memory
;
; in:	tes = segment of the block to be returned
;
; out:	tax = error code if cy
;
; errors:
;	error_arena_trashed
;	error_invalid_block
;
;,fe
;======================================================================
	assume	ds:grp,ss:tcb,es:nothing
public	mosfun49
mosfun49 proc	near
	xor	bx, bx			; check all memory blocks
	call	mmsetup			; validate mb chain
	assume	es:grp,ds:nothing
	jc	fun49end

; dos doesn't error if freeing a free memory block
				
	mov	bx,[tes]		; get address of block to free
	dec	bx			; point to prefix
	mov	ds,bx
	assume	ds:mbseg
	cmp	byte ptr [mbtype],'M'	; check for valid prefix
	je	fun49ok			; ok, check next block
	cmp	byte ptr [mbtype],'Z'	; if not regular block then must be last
	je	fun49ok
	mov	ax,error_invalid_block
	stc
	jmp	fun49end
fun49ok:
	mov	word ptr [mbowner],0	; set block as free
	mov	ax,[tes]		; get segment of memory block
	dec	ax
	mov	[tax],ax		; place it in ax
	xor	ax,ax			; no...errors
fun49end:
	push	es
	pop	ds
	assume	ds:grp
	callmos2 moserror		; set return code
	ret
mosfun49 endp

	subttl mosfun4a - modify allocated memory (setblock)
	page
;======================================================================
;,fs
; mosfun4a - modify allocated memory (setblock)
;
; modifies allocated memory blocks to contain the new specified block
; size.
;
; in:	tes = segment of block
;	tbx = new size in paragraphs
;
; out:	tax = error code if cy
;	tbx = maximum possible size if error
;
; errors:
;	error_arena_trashed
;	error_invalid_block
;	error_not_enough_memory
;
;,fe
;======================================================================
	assume	ds:grp,ss:tcb,es:nothing
public	mosfun4a
mosfun4a proc	near
	mov	bx,[tes]		; get mb address
	call	mmsetup			; validate mb chain
	assume	es:grp,ds:nothing
	jnc	fun4a00
	jmp	fun4aend		; set error code and exit
fun4a00:
	dec	bx			; point to prefix
	mov	ds,bx
	assume	ds:mbseg
	mov	bx,[tbx]		; get requested size
	cmp	[mbowner],0		; if requested block is free
	jne	fun4askip		; no...
	push	ax
	mov	ax,[tcbpsp]		; we must set owner of request
	mov	[mbowner],ax		; block to current psp
	pop	ax
fun4askip:
	call	blkmrch			; combine any adjacent free blocks
	cmp	bx,[mbsize]		; is this a shrink or grow?
	ja	fun4agw			; grow
	jne	fun4a01
	jmp	fun4aend		; same size, exit
fun4a01:

; do block shrink and create free block from excess

	mov	ax,[mbsize]
	mov	[mbsize],bx		; set new block size
	sub	ax,bx			; calc left over amount
	dec	ax			; size not to include prefix of block
	mov	bx,ds			; address block
	inc	bx			; point past prefix
	add	bx,[mbsize]		; point to address for new next block
	mov	cl,[mbtype]		; get type of current block
	mov	byte ptr [mbtype],'M'	; set as not last block
	mov	ds,bx			; address newly freed block
	mov	[mbtype],cl		; set type to same of current
	mov	word ptr [mbowner],0	; set block as free
	mov	[mbsize],ax		; set size
	call	blkmrch			; combine any adjacent free blocks
	xor	ax,ax			; set no errors
	jmp	fun4aend		; set error code and exit

; attempt a block grow into above free block (if one exists)

fun4agw:
	cmp	byte ptr [mbtype],'Z'	; is this the last block?
	jne	fun4a02			; no
	jmp	fun4a1			; yes, cannot grow
fun4a02:
	mov	cx,[mbsize]		; get size of current block
	mov	ax,ds			; get pointer to current block
	mov	dx,ax			; save current block for later
	inc	ax			; point past prefix
	add	ax,[mbsize]		; point to next block
	mov	ds,ax			; address next block
	cmp	word ptr [mbowner],0	; is this block free
	jne	jfun4a2			; above block not free, can't grow
	inc	cx			; include_ header length in block size
	add	cx,[mbsize]		; calc total size of both blocks
	cmp	bx,cx			; large enough?
	jna	skjfun4a2	

; the following code is necessary, to be compatible with dos
; and applications like spss. dos will combine a block with next
; free block even if an error occurs

	push	ax
	push	ds
	mov	al,[mbtype]		; get free block type
	mov	ds,dx			; access previous block
	mov	[mbtype],al		; set previos block type
	mov	[mbsize],cx		; set previos block size
	pop	ds
	pop	ax
jfun4a2:			
	jmp	fun4a2		
skjfun4a2:

; expand current block into above free block

	mov	cx,[mbsize]		; get size of above free block
	inc	cx			; plus header
	mov	dl,[mbtype]		; save block type
	mov	ax,[tes]		; get pointer to growing mb
	dec	ax			; point to prefix
	mov	ds,ax			; address growing block
	mov	ax,[mbsize]		; save current size
	mov	[mbsize],bx		; set new size (as requested)
	sub	bx,ax			; calc amount of free block used
	sub	cx,bx			; calc new size of free block
	or	cx,cx			; any of the block left over?
	jnz	fun4a3			; yes, adjust left-overs
	push	ds			; save address of current block
	mov	bx,ds			; save address of current block
	inc	bx			; point past prefix
	add	bx,ax			; point to old next block prefix
	mov	ds,bx			; address old next block
	mov	dl,[mbtype]		; get type
	pop	ds			; address newly grown block
	mov	[mbtype],dl		; use same type as old block
	jmp	fun4a0			; all of next block used up
fun4a3:
	mov	bx,ds			; get growing block address
	inc	bx			; point past prefix
	add	bx,[mbsize]		; point to new address for free block
	mov	ds,bx			; address new free block address
	mov	[mbtype],dl		; set same type as before
	dec	cx			; less header of new free block
	mov	[mbsize],cx		; new smaller size (less growth of other blk)
	mov	word ptr [mbowner],0	; still free
fun4a0:
	xor	ax,ax			; no errors
	jmp	short fun4aend
fun4a2:
	mov	[tbx],cx		; return max size above current size
	mov	ax,error_not_enough_memory
	jmp	short fun4aend
fun4a1:
	mov	bx,[mbsize]		; max size is current size of block
	mov	[tbx],bx		; return to caller
	mov	ax,error_not_enough_memory
fun4aend:
	or	ax,ax
	jnz	fun4amjs1		; if no error, return segment in ax
	mov	bx,[tes]
	mov	[tax],bx
fun4amjs1:
	push	es			; restore standard segregs
	pop	ds
	assume	ds:grp,es:nothing
	callmos2 moserror		; set error code
	ret
mosfun4a endp

	subttl mmsetup - validate mb pointer and mb chain
	page
;======================================================================
;,fs
; mmsetup - validate mb pointer and mb chain
;
; this routine is called by the memory allocation routines (48,49,4a,58)
; to verify a memory block pointer and the mb chain.
;
; in:	bx = address of mb to check (0 if only check chain)
;
; out:	es -> gr0p
;	ax = error code if cy
;
; errors:
;	error_arena_trashed
;	error_invalid_block
;
;,fe
;======================================================================
	assume	ds:grp,ss:tcb,es:nothing
mmsetup proc near
	mov	ax, ds			; free ds by letting es address grp.
	mov	es, ax
	assume	es:grp,ds:nothing
	push	bx
	push	ds
	mov	ax,[tcbmbpf]		; start check at 1st pointer
mbchklp:
	inc	ax			; point to mb
	cmp	ax,bx			; is this a valid mb address
	jne	mbchk2
	xor	bx,bx			; flag that address is valid
mbchk2:
	dec	ax			; point to prefix
	mov	ds,ax
	assume	ds:mbseg
	cmp	byte ptr [mbtype],'M'	; check for valid prefix
	je	mbchk3			; ok, check next block
	cmp	byte ptr [mbtype],'Z'	; if not regular block then must be last
	je	mbchk4
	mov	ax,error_arena_trashed	; chain destroyed
	stc
	jmp	mbchkend
mbchk3:
	inc	ax			; point past prefix (to block)
	add	ax,[mbsize]		; point to next block
	jmp	mbchklp
mbchk4:
	xor	ax,ax			; set 'no error' code
	or	bx,bx			; specified mb address found?
	jz	mbchkend		; yes
	mov	ax,error_invalid_block
	stc
mbchkend:
	pop	ds
	pop	bx
	ret
mmsetup endp

	subttl combmcb - combine mcb - high level for terminate and exec
	page
;======================================================================
;,fs
; combmcb - combine mcb - high level for terminate and exec
;
; this routine is use by terminate and exec for combining free blocks.
; this routine was created because dos does not combine blocks when
; doing function 49 (as of qbasic 4.0)
;
; in:	
;
; out:	
;
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:tcb
combmcb proc near
	push	bx
	push	di
	push	ds		
	push	es
	mgetscb ds		
	assume	ds:grp
	xor	bx,bx			; check memory control blocks
	call	mmsetup		
	call	blkmrch			; combine any free adjacent memory blocks
	pop	es
	pop	ds		
	pop	di
	pop	bx
	ret
combmcb endp

	subttl blkmrch - block merge (combine free blocks)
	page
;======================================================================
;,fs
; blkmrch - block merge (combine free blocks)
;
; this routine is called by the memory allocation routines (49 and 4a)
; to combine any adjacent free blocks in the chain.
;
; in:	es register set-up by mmsetup to point to grp.
;
; out:	ss -> tcb
;
;,fe
;======================================================================
	assume	ds:nothing, es:grp, ss:tcb
blkmrch proc near
	pushf
	push	ax
	push	bx
	push	cx
	push	ds
	mov	ax,[tcbmbpf]		; start check at 1st pointer
	mov	bx,ax
	inc	bx
	mov	ds,ax			; address 1st block
	assume	ds:mbseg
	add	bx,[mbsize]		; point to next block
blklp:
	cmp	byte ptr [mbtype],'Z'	; is this the last block?
	je	blkmend			; yes
	cmp	word ptr [mbowner],0	; is this block free
	je	blkm1
	mov	ds,bx			; point to next mb
blkm0:
	inc	bx			; point past mb itself
	add	bx,[mbsize]		; point to next mb
	jmp	blklp

; ds -> free block here

blkm1:
	mov	ax,ds			; save address of free block
	mov	ds,bx			; address next block
	cmp	word ptr [mbowner],0	; is this one free also?
	jne	blkm0			; no..don't combine the blocks

; adjacent block free now combine

blkm2:
	mov	bx,[mbsize]		; get size of next block
	mov	cl,[mbtype]		; use this type (may be last block)
	mov	ds,ax			; address lower mb
	inc	bx			; upper mb prefix is also free space
	mov	[mbtype],cl		; use block type of higher block
	add	[mbsize],bx		; combine the 2 blocks into 1 larger block
	mov	bx,ds			; current block
	add	bx,[mbsize]		; point to next block
	inc	bx			; "     "	"
	jmp	blklp			; continue on with loop
blkmend:
	pop	ds
	pop	cx
	pop	bx
	pop	ax
	popf
	ret
blkmrch endp

	assume	ds:nothing,es:nothing



	subttl mosfun4b - load or execute program (exec)
	page
;======================================================================
;,fs
; mosfun4b - load or execute program (exec)
;
; allows a program to load into memory and optionally begins execution
; of it.
;
; (1) determine size of and allocate block for environment
; (2) allocate block for program (as large as possible)
; (3) if function 0 or 1 create psp
; (4) load program with handle calls
; (5) if function 1 set parameter block cs:ip and ss:sp and exit
; (6) set terminate vector to callers cs:ip
; (7) turn control over to loaded program
;
; in:	tds:tdx -> asciiz string with drive, path, and filename
;	tes:tbx -> parameter block ---------|
;	tal = function value		    |
;					    |
;				0 dw - segment address of environment
;				2 dd -> command line
;	parameter block --->	6 dd -> fcb at 5c in psp
;				a dd -> fcb at 6c in psp
;				e dd - ss:sp for fun 0
;				12 dd - cs:ip for fun 0
;
; out:	tax = error code if cy
;
; errors:
;	error_invalid_function
;	error_file_not_found
;	error_not_enough_memory
;	error_bad_environment
;
;,fe
;======================================================================
	assume	ds:grp,ss:tcb,es:nothing

rs_pgm	equ	1			; set if program segment allocated
rs_env	equ	2			; set if environment allocated
rs_trm	equ	4			; set if terminate vector changed
rs_mmb	equ	8			; set if mosheman block allocated
rs_open equ	16			; set if filename is open
rs_mmb2	equ	32			; set if 2nd mosheman block allocated

public	mosfun4b
lproc mosfun4b
ldword	prmblk				; pointer to passed parameter block
lstring pathstr,65			; copy of the ds:dx string
lword	workadr				; pointer to heap work address
lword	workadr2			; pointer to 2nd heap work block
lword	envseg				; segment address of environment block
lword	pgmseg				; segment address of program block
lword	psize				; paragraph length of load module (com or exe)
ldword	bsize				; byte length of load module (com or exe)
ldword	lsz				; current size to be loaded
lword	lofs				; current load offset
lword	lseg				; current load segment
lword	flhdl				; file handle save space
lbyte	funnum				; function number
lbyte	rsflags				; resources which must be returned
lword	reloc				; relocation factor for func 3
lword	adjust				; load location adjustment factor
ldword	ldsize				; actual load size from directory
lword	mempara				; size of memory in paragraphs
lword	returnax			; value return in ax back to application
lword	currentrelo			; current top of relocation buffer offset
lword	reloadjust			; relocation buffer position adjustment

	mov	[rsflags],0		; clear resource flags
	mov	dx,bp
	mov	bp,[bp]			; address callers registers

; the following code is used to set offset of 2e and 30 in the
; psp to callers ss:sp - adjusted for retf in terminate

	mov	ax,[tax]		; get function
	cmp	al, 3			; check if subfunction is 0 - 3
	jbe	cont4b			; yes...continue
	mov	ax,error_invalid_function
	callmos2 moserror
	jmp	fun4bend		; no...invalid function
cont4b:
	cmp	al, 1			; only done for function 0 and 1
	ja	nopspstk		; sorry not today charlie...
	mov	es,[tcbpsp]		; get parent psp segment
	assume	es:pspseg
	mov	ax,[tss]		; get stack segment of caller
	mov	[pspss], ax		; save it in psp (allows for nested calles)
	mov	ax,[tsp]		; get stack pointer of caller
	sub	ax,4			; adjust psp for retf to parent
	mov	[pspsp], ax		; save in psp

; the following code is added to save the registers onto the stack of the
; process which exec the sub process, terminate code will pull this
; from calls stack and pass it back to caller from exec
; this was added to correct problem with wordperfect 5.10 shelling

	mov	ax,[tss]		; get stack segment
	cmp	ax,[scbtcbpc]
	je	skipexec
	mov	es,ax
	mov	di,[tsp]
	sub	di,16			; adjust from values push by mossaver
	mov	ax,[tax]
	mov	word ptr es:[di-16],ax
	mov	ax,[tbx]
	mov	word ptr es:[di-14],ax
	mov	ax,[tcx]
	mov	word ptr es:[di-12],ax
	mov	ax,[tdx]
	mov	word ptr es:[di-10],ax
	mov	ax,[tsi]
	mov	word ptr es:[di-8],ax
	mov	ax,[tdi]
	mov	word ptr es:[di-6],ax
	mov	ax,[tbp]
	mov	word ptr es:[di-4],ax
	mov	ax,[tds]
	mov	word ptr es:[di-2],ax
	mov	ax,[tes]
	mov	word ptr es:[di],ax
skipexec:

	assume	es:nothing
nopspstk:
	mov	es,[tds]		; make es:di point the the caller's path string
	mov	di,[tdx]
	mov	cx,65
	xor	al,al
	mov	bx,di			; do a precheck to make sure an extra long
	cld				; filespec doesn't crash our stack
	repne	scasb
	jz	pathok

; sah 10/23/91 correction for metlif

	cmp	byte ptr es:[di-1],' '	; is last character check a ' '
	jne	doerror
pathslp:
	dec	di			; remove space
	cmp	byte ptr es:[di-1],' '
	je	pathslp
	jmp	short pathok
doerror:
	jmp	fun4berr		; too long
pathok:
	sub	di,bx
	mov	cx,di
	mov	ds,[tds]		; place the filespec on the stack
	mov	si,[tdx]
	mov	bx, ss			; es=ss
	mov	es, bx
	mov	bp,dx
	lea	di,[pathstr]
	rep	movsb
	xor	al,al
	stosb
	mov	bp,[bp]			; address callers registers again
	mov	es,[tes]		; get pointer to parameter block
	mov	bx,[tbx]		; "     "	"
	mov	ax,[tax]		; get function number
	mov	bp,dx			; address local variables
	mov	word ptr [prmblk],bx
	mov	word ptr [prmblk+2],es
	mov	[funnum],al

; open file first - to accomodate pfs:write

	push	ds
	mov	dx,ss			; ds = ss
	mov	ds,dx
	lea	dx,[pathstr]		; get pointer to users asciiz string
	mov	ax,3d20h		; open file for read, deny write sharing mode
	cmp	al,al			; set zero flag - sjc
	mov	[tcbexec3d],1		; flag tells openfile to allow exec to open
	call	sim21			; the file to be exec'ed with a sharing mode
f4bret:
	mov	[tcbexec3d],0		; even if it is already open in compatibility
	pop	ds
	jnc	$+5
	jmp	f4berrok		; opening error
	or	[rsflags],rs_open	; indicate that file is open
	mov	[flhdl],ax		; store handle
	call	combmcb			; combine memory blocks on all functions

; is it func 3, load overlay?

	cmp	byte ptr [funnum],3
	jne	fun4bx3d
	les	bx,[prmblk]		; if yes, skip around environment and psp setup
	mov	ax,es:[bx]
	mov	[pgmseg],ax
	mov	ax,es:[bx+2]
	mov	[reloc],ax
	jmp	fun4bx3a
setmcbs:
	mov	ax,[envseg]		; point to mb
	dec	ax			; point to mb prefix
	mov	es,ax			; address prefix
	assume	es:mbseg
	mov	[mbowner],dx		; set owner psp address in env. mb
	mov	ax,[pgmseg]
	dec	ax
	mov	es,ax
	mov	[mbowner],dx		; set owner psp address in psp mb
	ret

; determine environment size

fun4bx3d:
	cld
	les	bx,[prmblk]		; get parameter block pointer
	mov	bx,es:[bx]		; get pointer to environment
	or	bx,bx			; should they inherit the parent's?
	jnz	fun4b1			; no
	mov	es,[tcbpsp]		; get parent psp
	assume	es:pspseg
	mov	bx,es:[pspenv]		; get parent environment segment
fun4b1:
	mov	es,bx			; point to env.
	assume	es:nothing
	xor	di,di			; scan env. from start for end marker (00)
	xor	al,al
	mov	cx,8000h		; scan up to 32k
fun4b1a:
	repne	scasb			; scan for 0
	je	fun4b2a			; found end of this string
	mov	ax,error_bad_environment
	jmp	fun4bend
fun4b2a:
	scasb				; is this a word of 0? (end of env.)
	jne	fun4b1a			; only single 0, continue scan
	add	di,2			; point past additional string counter
	mov	si,di			; save length of passed env.

; now add 'load path string' size to env. size

	mov	bx,di			; save size of env. in bytes
	push	es			; save env. pointer
	mov	cx, ss			; es=ss
	mov	es, cx
	lea	di,[pathstr]		; get pointer to asciiz
	mov	dx,di
	xor	al,al
	mov	cx,100			; go over max. for the hell of it (max=64)
	repne	scasb			; find end of string
	pop	es			; get env. pointer back
	sub	di,dx			; calc length of load path
	add	bx,di			; bx= total env. size in bytes

; allocate space for environment

	add	bx,0fh			; round up to next seg
	shr	bx,1			; calc # para's needed
	shr	bx,1
	shr	bx,1
	shr	bx,1
	mov	ah,48h
	call	sim21			;** for novell
	jnc	fun4b3
	jmp	fun4berr		; maybe not enough space here

; now copy environment to newly allocated block

fun4b3:
	or	[rsflags],rs_env	; environment allocated ok
	push	ds
	mov	cx, es			; ds=es
	mov	ds, cx
	assume	ds:nothing
	mov	es,ax			; point to env. block
	push	di			; save size of 'load path string'
	mov	cx,si			; get size of env.
	xor	si,si
	xor	di,di
	rep	movsb			; move env.
	mov	cx, ss			; ds=ss
	mov	ds, cx
	lea	si,[pathstr]
	pop	cx			; get size of string
	mov	word ptr es:[di-2],1	; set additional string count
	rep	movsb			; move 'load path string'
	pop	ds
	assume	ds:grp
	mov	[envseg],es		; save pointer to env. block

; allocate initial working space for program and create psp

	mov	ah,48h			; we are going to try to allocate all memory
	mov	bx,-1
	call	sim21			;** for novell
	cmp	bx,12h
	jb	fun4bw1e
	mov	ah,48h			; allocate space
	call	sim21			;** for novell
	jnc	fun4bw1
fun4bw1e:
	mov	al,error_not_enough_memory
	jmp	fun4berr		; error

; set terminate vector to callers cs:ip

fun4bw1:
	mov	[mempara],bx		; save memory size
	or	[rsflags],rs_pgm	; program block allocated
	push	ds
	push	ax
	mov	bx,bp
	mov	bp,[bp]			; address callers registers
	mov	ds,[tcs]		; get pointer to users next instruction
	mov	dx,[tip]		;  after int 21h
	mov	bp,bx
	mov	ax,2522h		; set terminate
	call	sim21			;** for novell
	pop	ax
	pop	ds
	or	[rsflags],rs_trm	; terminate vector changed
	mov	[pgmseg],ax		; save block pointer for program
	mov	dx,ax			; create new psp here

; make sure that we use function 55h inside of exec.

	push	[tcbpsp]
	mov	ah,55h
	call	sim21			;** for novell

; since opening of the file has been above create psp
; call we must remove the file handle use in exec out of child psp

	msetpsp	 dx			; segment of newly created psp
	mov	bx,[flhdl]
	mov	ax,-1			; set to ffh
	callmos2 setphdl
	pop	[tcbpsp]
	mov	ax, [tcbpsp]		; set psp to parent psp 04/30/87
	mov	[tcboldpsp],ax		; update psp for lanlink
	push	es
	mov	es, [pgmseg]
	assume	es:pspseg
	mov	[pspprnt], ax
	pop	es
	assume	es:nothing

; set owner fields in mb prefix for env. block and program block

	call	setmcbs
fun4bx3a:				; skip to here for func #3
	mov	bx,[flhdl]
	push	ds
	mov	ds,[pgmseg]		; get pointer to memory block
	mov	dx,100h			; load just after mb prefix
	cmp	[funnum],3		; use offset 0 for func 3
	jne	fun4bx3g
	xor	dx,dx
fun4bx3g:
	mov	cx,2			; read 1st word to check for exe
	mov	ah,3fh			; read file
	push	dx
	call	sim21			;** for novell
	pop	dx
	jnc	fun4br1
	pop	ds
	jmp	fun4berr
fun4br1:
	xchg	dx,bx
	cmp	word ptr ds:[bx],5a4dh	; is this an exe file?
	xchg	dx,bx
	pop	ds
	jne	$+5
	jmp	fun4bexe		; do exe processing

; now processing a com file

	mov	si,[mempara]		; get size of memory in paragraphs
	mov	ax,4202h		; determine file size for load
	xor	cx,cx
	xor	dx,dx
	call	sim21			;** for novell
	jnc	$+5
jf4bcrt1:
	jmp	fun4bcrt		; unforeseen error during exec call
	mov	word ptr [bsize],ax
	mov	word ptr [bsize+2],dx	; byte length of file
	mov	cx,4
fun4b1c:
	shr	dx,1
	rcr	ax,1
	loop	fun4b1c
	mov	[psize],ax		; paragraph length of file
	mov	ax,4200h		; reset file pointer to beginning
	xor	cx,cx
	xor	dx,dx
	call	sim21			;** for novell
	mov	ax,[psize]
	cmp	[funnum], 3		; skip if overlay
	je	fun4b2			; skip memory check too
	add	ax,10h
fun4b1d:
	cmp	ax,si			; is this file too large for this block?
	jbe	fun4b2			; no, its ok for loading
	mov	ax,error_not_enough_memory
	jmp	fun4berr		; too large
fun4b2:

; read in com file at psp:100h

	mov	ax,[pgmseg]
	mov	[lseg],ax
	mov	[lofs],100h
	cmp	[funnum], 3
	jne	fun4b2x
	mov	[lofs], 0
fun4b2x:
	mov	ax,word ptr [bsize]
	mov	word ptr [lsz],ax
	mov	ax,word ptr [bsize+2]
	mov	word ptr [lsz+2],ax
f4bcla:
	push	ds
	mov	dx,[lofs]
	mov	ax,dx
	and	dx,0fh
	mov	cl,4
	shr	ax,cl
	add	ax,[lseg]
	mov	ds,ax
	mov	cx,-512			; at most 64k - 512 bytes at a time
	cmp	word ptr [lsz+2],0
	jne	f4bclb			; ne if > 64k left to read
	cmp	cx,word ptr [lsz]
	jbe	f4bclb			; be if 64k - 1 to 64k - 512 left read
	mov	cx,word ptr [lsz]	; else read what's there
f4bclb:
	push	cx
	mov	ah,3fh
	call	sim21			;** for novell
	pop	dx			; dx = amount supposed to have been read
	pop	ds
	jc	f4bclc
	jcxz	f4bclc			; unforeseen error during exec if 0 read
	cmp	dx,cx
	je	f4bcld			; unforeseen error if not all requested read
f4bclc:
	jmp	fun4bcrt		; unforeseen error during exec call
f4bcld:
	sub	word ptr [lsz],cx	; new length to be loaded according
	sbb	word ptr [lsz+2],0	;   to amount actually read
	add	word ptr [lofs],cx	; carry not possible
	mov	ax,word ptr [lsz]
	or	ax,word ptr [lsz+2]
	jnz	f4bcla
	and	[rsflags],not rs_open	; clear open flag
	mov	ah,3eh			; close file
	call	sim21			;** for novell
	jnc	$+5
	jmp	fun4berr
	cmp	[funnum],3		; load overlay?
	jne	$+5			; if yes, done - get out
	jmp	fun4bx3b
	push	si
	call	fun4bpsp		; init values in psp
	pop	si
	cmp	[funnum],1		; is this a load and setup only?
	jne	$+5			; no, run program
	jmp	fun4b4

; set registers and enter loaded program
; bx:cx with file size

	mov	bx,word ptr [bsize+2]
	mov	cx,word ptr [bsize]
	mov	ax,[pgmseg]		; get pointer to psp
	mov	dx,[returnax]		; get return value for valid drive specifiers
	xor	di,di
	xor	bp,bp
	mov	es,ax
	msetpsp ax			; set new current psp
	mov	word ptr [tcbdta],80h
	mov	word ptr [tcbdta+2],ax
	dec	[tcbnest]		; decrement counter for nest control
					; since mosint21 was entered but not exited
	call	rstinmos		; reset inmos
	push	ax
	mov	ax,[tcbpreseg]		; activate any +except/+only lists which
	mov	[tcbactseg],ax		; may exist
	pop	ax
	mov	ds,ax
	cmp	si,1000h		; is mb <64k?
	jae	f4bsk0
	shl	si,1
	shl	si,1
	shl	si,1
	shl	si,1
	cli
	mov	sp,si
	xor	si,si			; init for task
	jmp	f4bsk1
f4bsk0:
	cli
	mov	sp,0
f4bsk1:
	mov	ss,ax
	sti
	push	bp			; set return to int 20h in top of stack
	push	ax			; new cs
	mov	ax,100h
	push	ax			; new ip
	mov	ax,dx			; set return value for valid drive
	xor	dx,dx			; specifiers
	retf				; enter loaded com file
fun4b4:
	assume	es:nothing
	les	di,[prmblk]		; get pointer to parameter block
	add	di,0eh			; point to storage for ss:sp and cs:ip
	xor	ax,ax			; sp
	cmp	si,1000h		; is mb <64k?
	jae	f4bskok
	shl	si,1
	shl	si,1
	shl	si,1
	shl	si,1
	mov	ax,si
f4bskok:
	xor	si,si			; init for task
	dec	ax
	dec	ax
	push	ax
	stosw
	mov	ax,[pgmseg]		; ss
	stosw
	mov	ax,100h			; ip
	stosw
	mov	ax,[pgmseg]		; cs
	stosw
	mov	es,[pgmseg]
	pop	di
	cmp	word ptr [bsize+2],0	; is file > 65534 bytes?
	ja	fun4b4a			; if bigger
	cmp	word ptr [bsize],0fffeh
	ja	fun4b4a			; if bigger
	xor	ax,ax
	stosw				; set 0 return address in stack
fun4b4a:
	mov	es,[pgmseg]		; return psp address in ax
	assume	es:pspseg
	mov	ax,[tcbpsp]
	mov	[pspprnt],ax
	mov	word ptr [tcbdta],80h
	mov	word ptr [tcbdta+2],es
	mov	bx,bp
	mov	bp,[bp]
	mov	[tax],es
	and	[tflag], not carry	; indicate no errors
	msetpsp es
	mov	bp,bx
	jmp	fun4bend
;-----------------------------------------------------------------------
; process exe files here
;-----------------------------------------------------------------------
	assume	ds:nothing, es:nothing
fun4bexe:
	xor	ah,ah
	mov	dx,3h
	call	mosheman		; allocate some temp working space
	or	al,al
	jz	fun4bne1
	jmp	fun4blsmp
fun4bne1:
	mov	ax,es			; work area
	inc	ax			; skip heap prefix block
	mov	[workadr],ax		; save for recovery
	or	[rsflags],rs_mmb	; allocated block from mosheman ok
	push	ds
	mov	ds,ax			; address work area
	mov	dx,02h			; read in more of the exe header
	mov	cx,1eh
	mov	ah,3fh			; read file
	call	sim21			;** for novell
	pop	ds
	jnc	$+5
	jmp	fun4berr

; determine header size and read it into work space

	mov	ax,4200h		; reset pointer to start of file
	xor	dx,dx
	xor	cx,cx
	call	sim21			;** for novell
	jc	jf4bcrt2

; the following logic is use to make sure that
; next entry will fall on 4 byte boundary. this is done by
; adjusting the first read so that lenght will make sure
; that next read is on 4 byte bondary

	xor	dx,dx			; no adjustment on size
	mov	cx,512			; default to 512
	mov	ax,es:[28h]		; get start location  (18h + 10h)
	mov	dx,ax
	and	ax,0fffch		; mask out for multible of 4
	sub	dx,ax
	sub	cx,dx
	mov	dx,33			; use a 512 byte buffer + header
	mov	ah,1			; deallocate current work area
	call	mosheman
	or	al,al
	jz	fun4bhal
jf4bcrt2:
	jmp	fun4bcrt
fun4bhal:
	and	[rsflags],not rs_mmb	; gave mosheman block back
	xor	ah,ah
	call	mosheman		; allocate work area for 512 bytes
	or	al,al
	jz	fun4bne2
fun4blsmp:
	push	es
	mgetscb es
	assume	es:grp
	cmp	word ptr [scbcin24+2],0 ; special handler installed!
	jz	fun4bs24
	mov	ah,0ffh
	mov	bx,cs			; make bx:si point to error string
	mov	dx,offset [ipmsg10]
	pushf
	call	[scbcin24]		; call command processor
fun4bs24:
	pop	es
	mov	ax,error_not_enough_memory
	jmp	fun4berr

ipmsg10 db	'SMP too small for EXEC.$'  ;@@xlat

fun4bne2:
	or	[rsflags],rs_mmb	; another mosheman block
	mov	[currentrelo],cx	; set current relocation to 512 or 500
	mov	[reloadjust],0		; set relocation adjustment to 0
	mov	ax,es			; work area
	inc	ax			; skip heap prefix block
	mov	[workadr],ax		; address of work area
	mov	es,ax
	push	ds
	mov	ds,ax			; address work area
	xor	dx,dx			; load into start of work area
	mov	ah,3fh			; read file
	call	sim21			;** for novell
	pop	ds
	jnc	$+5
	jmp	fun4berr

; now calculate size base on exe header

	mov	ax,word ptr es:[04h]	; get size of the file in 512 page
	mov	cl,5			; including exe header
	shl	ax,cl			; adjust it so that it is paragraphs
	sub	ax,word ptr es:[08h]	; subtract header size
	mov	[psize],ax
	mov	cx,4
	xor	dx,dx
m4xx:					; convert to bytes
	shl	ax,1
	rcl	dx,1
	loop	m4xx
	mov	word ptr [bsize],ax	; store for later file loading
	mov	word ptr [bsize+2],dx
m4bnhead:
	mov	ax,[psize]		; get program paragraphs
	cmp	[funnum],3		; load overlay?
	jne	$+5
	jmp	fun4bx3c
	mov	dx,es:[0ch]		; maxalloc
	cmp	dx,es:[0ah]		; minalloc
	ja	f4bmma			; maxalloc > minalloc (as it should be)
	mov	dx,es:[0ah]
	mov	es:[0ch],dx
	jne	f4bmma			; maxalloc < minalloc (? replace w/ minalloc)
	or	dx,dx
	jz	f4bmmc			; maxalloc = minalloc = 0 allocate all
f4bmma:
	add	ax,dx			; include maxalloc value
	jc	f4bmmc
f4bmmb:
	add	ax,10h			; add in room for psp
	jnc	f4bmmd
f4bmmc:
	mov	ax,-1
f4bmmd:

; check for the exepack problem.  if the current load point ([pgmseg])
; is below 1000h and there are no relocation entries and the header
; cs value is either non-zero or it is zero but the ip is non-zero,
; then need to enlarge the environment block to make the next load
; point be 1000h.

	push	ax
	push	es
	cmp	word ptr [pgmseg],1000h ; check current load point
	jae	f4bx00
	mov	es,[workadr]
	cmp	word ptr es:[6],0	; check # of reloc entries
	jne	f4bx00
	cmp	word ptr es:[16h],0	; check header cs
	jne	f4bx0
	cmp	word ptr es:[14h],0	; check header ip
	jne	f4bx0
f4bx00:
	jmp	f4bepdn
f4bx0:

; allocate a heap block containing paras for 256 bytes + 1 para for
; the header.  this block will be used to hold the psp while the
; environment block is being enlarged.

	xor	ah,ah
	mov	dx,(256/16)+1
	call	mosheman
	or	al,al
	jz	f4bx3
	add	sp,4			; counteract initial two pushes
	jmp	fun4blsmp
f4bx3:
	or	[rsflags],rs_mmb2
	mov	ax,es
	inc	ax			; skip heap prefix block
	mov	[workadr2],ax
	mov	es,ax

; copy the current psp into the heap block

	push	ds
	mov	ds,[pgmseg]
	mov	cx,256/2
	xor	si,si
	xor	di,di
	cld
	rep	movsw
	pop	ds

; delete the memory block that holds the psp 

	mov	es,[pgmseg]
	mov	ah,49h
	call	sim21			; free old program space
	and	[rsflags],not rs_pgm	; program block not allocated
	call	combmcb

; allocate some memory so that starting program address will
; be 1000h

	mov	bx,0fffh
	sub	bx,[pgmseg]
	mov	ah,48h
	call	sim21			; force enviroment to be bigger
	jc	f4berr1

; allocate a new block for the psp.  this block will evenutally
; be enlarged to hold the program's code and data

	mov	bx,12h
	mov	ah,48h
	call	sim21
	jc	f4berr1
	or	[rsflags],rs_pgm	; program block allocated
	mov	[pgmseg],ax

; restore the psp data

	push	ds
	mov	ds,[workadr2]
	mov	es,ax
	mov	cx,256/2
	xor	si,si
	xor	di,di
	cld
	rep	movsw
	pop	ds
	mov	es:[36h],es		; fix the psp table pointer

; deallocate the 2nd heap block

	push	ax
	mov	ax,[workadr2]
	dec	ax			; address block prefix
	mov	es,ax
	mov	ah,1
	call	mosheman
	or	al,al
	ljnz	fun4bcrt		; ignoring stack imbalance
	pop	ax
	and	[rsflags],not rs_mmb2	; gave mosheman block back

; setup the mcbs

	mov	dx,ax
	call	setmcbs
	jmp	short f4bepdn

; error handler for above section

f4berr1:
	mov	ax,error_not_enough_memory
	add	sp,4			; counteract initial two pushes
	jmp	fun4berr

f4bepdn:
	pop	es
	pop	ax

; continue with exec

	push	es			; save work area pointer
	mov	es,[pgmseg]		; psp mb address
	mov	bx,ax			; expand mb to max
	mov	ah,4ah			; setblock to maximum size (returns error)
	push	bx
	call	sim21			;** for novell
	jnc	f4bexemx		; maximum value ok
	pop	ax			; throw away max request
	pop	es			; address work area
	push	es
	mov	ax,[psize]		; now try load size+minalloc
	add	ax,es:[0ah]		; minalloc
	jc	f4bmme
	add	ax,10h
	jnc	f4bmmf
f4bmme:
	mov	ax,-1
f4bmmf:
	cmp	bx,ax			; is block large enough for minimum memory
	jae	f4bexemn		; yes
	pop	ax			; clear work area segment from stack
	mov	ax,error_not_enough_memory
	jmp	fun4berr
f4bexemn:
	mov	es,[pgmseg]
	mov	ah,4ah			; allocate largest block available
	push	bx
	call	sim21			;** for novell
f4bexemx:
	pop	bx
	pop	es			; work area address

; compute start paragraph to load file

	mov	ax,[pgmseg]
	mov	[adjust],0010h		; load is directly after psp
	add	ax,10h			; load = pspseg + psp length if maxalloc <> 0
	cmp	word ptr es:[0ch],0	; maxalloc = 0 ?
	jne	f4baa
	cmp	word ptr es:[0ah],0	; minalloc = 0 ?
	jne	f4baa
	mov	ax,[pgmseg]		; else load at top of allocated region
	add	ax,bx
	sub	ax,[psize]

; calculate adjustment factor for load
; in this case load is up high and psp is down low

	mov	bx,ax
	sub	bx,[pgmseg]
	mov	[adjust],bx
	jmp	f4baa
fun4bx3c:
	mov	ax,[pgmseg]		; entry for func 3
	jmp	short f4baa
f4baa:
	mov	[lseg],ax
	mov	[lofs],0		; always start at offset 0
	mov	ax,word ptr [bsize]	; load size of file in bytes
	mov	word ptr [lsz],ax
	mov	ax,word ptr [bsize+2]
	mov	word ptr [lsz+2],ax
	mov	dx,es:[8]		; get header size
	mov	cl,4
	shl	dx,cl			; calc # bytes
	mov	bx,[flhdl]		; file handle (i already told you that!)
	mov	ax,4200h		; position file pointer to load module
	xor	cx,cx			;   (past header portion of file)
	call	sim21			;** for novell
	jc	f4blc
f4bla:
	push	ds			; load the file up to 64k-512 bytes at a time
	mov	dx,[lofs]
	mov	ax,dx
	and	dx,0fh
	mov	cl,4
	shr	ax,cl
	add	ax,[lseg]
	mov	[lofs],dx		; store normalized lseg:lofs
	mov	[lseg],ax
	mov	ds,ax
	mov	cx,-512			; at most 64k - 512 bytes at a time
	cmp	word ptr [lsz+2],0
	jne	f4blb			; ne if > 64k left to read
	cmp	cx,word ptr [lsz]
	jbe	f4blb			; be if 64k - 1 to 64k - 512 left read
	mov	cx,word ptr [lsz]	; else read what's there
f4blb:
	push	cx
	mov	ah,3fh
	call	sim21			;** for novell
	pop	dx			; dx = amount supposed to have been read
	pop	ds
	jc	f4blc
	mov	cx,ax			; actual length was returned in ax
	jcxz	f4blc			; unforeseen error during exec if 0 read
	cmp	dx,cx
	je	f4bld			; unforeseen error if not all requested read
	jmp	short f4bldone		; well header is wrong (is this best way)
f4blc:
	jmp	fun4bcrt		; unforeseen error during exec call
f4bld:
	sub	word ptr [lsz],cx	; new length to be loaded according
	sbb	word ptr [lsz+2],0	;   to amount actually read
	add	word ptr [lofs],cx	; carry not possible
	mov	ax,word ptr [lsz]
	or	ax,word ptr [lsz+2]
	jnz	f4bla
f4bldone:

; perform file relocation

	mov	dx,[pgmseg]
	add	dx,[adjust]		; point past psp address (dx=start segment)
					; or up in high memory if exe file desires
	cmp	[funnum],3
	jne	fun4bx3f
	mov	dx,[reloc]		; func #3 - use relocation factor
fun4bx3f:
	push	ds
	mov	cx, es			; ds=es
	mov	ds, cx
	assume	ds:nothing
	mov	si,ds:[18h]		; get pointer to 1st relocation item
	mov	cx,ds:[6]		; get # of relocation table entries
	jcxz	f4brelx

; relocation loop

f4brel:
	cmp	si,[currentrelo]	; cmp to top of buffer
	jb	f4brel3

; we have determined that current exe header entry is nolonger inside
; currently allcoated smp 512 byte block we must now read in the
; next 512 byte section of exe header and continue processing

	push	bx
	push	cx
	push	dx

	cmp	si,512			; is this the first time throug
	ja	f4brel0			; no...continue

; if this is the first time, we must set file position to next available
; location to read in exeheader. currentrelo should contain this offset

	mov	dx,[currentrelo]
	xor	cx,cx
	mov	ax,4200h
	call	sim21
	jc	f4brelerr
f4brel0:
	xor	dx,dx
	mov	cx,512			; we will always use a 512 byte space
	mov	ah,3fh			; read file
	call	sim21			;** for novell
f4brelerr:
	pop	dx
	pop	cx
	pop	bx
	jnc	f4brel1
	jmp	fun4berr

; adjust relocation position counters

f4brel1:
	mov	ax,512			; use 512 byte for defaults
	cmp	si,512			; is this first time and
	jae	f4brel2			; size is not 512
	mov	ax,[currentrelo]	; if not add size
f4brel2:
	add	[reloadjust],ax
	add	[currentrelo],512

; adjust relocation entry

f4brel3:
	push	si
	sub	si,[reloadjust]
	mov	ax,[si+2]		; get segment value
	mov	di,[si]			; get offset value
	add	ax,dx			; calc file offset
	mov	es,ax
	assume	es:nothing
	add	es:[di],dx		; make relocation adjustment
	pop	si
	add	si,4			; point to next entry
	loop	f4brel			; continue through all entries

; end of relocation loop

f4brelx:

; now locate file position at begining

	push	dx
	xor	dx,dx
	xor	cx,cx
	mov	ax,4200h
	call	sim21
	jc	f4brelxer

; now  reread the first 512 bytes so that remainder of code can
; propertly handle header information

	xor	dx,dx
	mov	cx,512			; we will always use a 512 byte space
	mov	ah,3fh			; read file
	call	sim21			;** for novell
f4brelxer:
	pop	dx
	jnc	f4brelxok
	jmp	fun4berr
f4brelxok:

; update sah 11/14/90 osmose - must close file and make abolutely sure
; that no more sim21 calls are call after deallocating heap.  this must
; be done because sim21 will call mosint21, which will eventually call
; tsl which could switch tasks, which the other task could allocate data
; on smp which will use space use by exec variables.

	and	[rsflags],not rs_open	; clear open flags
	mov	ah,3eh			; close file
	call	sim21			;** for novell
	jnc	$+5
	jmp	fun4berr
	mov	ax,[workadr]
	dec	ax			; address block prefix
	mov	es,ax
	mov	ah,1			; deallocate block
	call	mosheman
	or	al,al
	jz	$+5
	jmp	fun4bcrt
	cmp	[funnum],3
	jne	fun4bx3h
	pop	ds
	jmp	fun4bx3b		; if func #3 - done, get out
fun4bx3h:
	push	dx			; save 'Start Segment' value
	call	fun4bpsp		; init values in psp
	pop	dx
	cmp	[funnum],1		; is this a load and setup only?
	jne	fun4bya			; no, run program
	les	di,[prmblk]		; get pointer to parameter block
	add	di,0eh			; point to storage for ss:sp and cs:ip
	mov	ax,ds:[10h]		; get sp value
	sub	ax,2			;????
	stosw				; sp
	mov	ax,ds:[0eh]		; get ss
	add	ax,dx			; relocation adjustment to ss
	stosw				; ss
	mov	ax,ds:[14h]		; get ip
	stosw				; ip
	mov	ax,ds:[16h]		; get cs
	add	ax,dx			; make adjustment
	stosw				; cs
	mov	es,[pgmseg]
	assume	es:pspseg
	mov	ax,[tcbpsp]
	mov	[pspprnt],ax
	mov	word ptr [tcbdta],80h
	mov	word ptr [tcbdta+2],es
	mov	bx,bp
	mov	bp,[bp]
	mov	[tax],es
	and	[tflag], not carry	; indicated no errors
	msetpsp es
	mov	bp,bx
	pop	ds
	jmp	fun4bend
fun4bya:

; init registers and enter the application
; clear work area from heap

	mov	ax,ds:[0eh]		; get ss value
	add	ax,dx			; make relocation adjustment
	mov	bx,ds:[10h]		; get sp value
	mov	cx,[pgmseg]		; get psp address
	mov	es,cx
	push	ax
	msetpsp es			; set new current psp
	mov	word ptr [tcbdta],80h	; set default dta to ofs 80 in psp
	mov	word ptr [tcbdta+2],es
	dec	[tcbnest]		; decrement counter for nest control
					; since mosint21 was entered but not exited
	call	rstinmos		; reset inmos flag
	push	ax
	mov	ax,[tcbpreseg]		; activate any +except/+only lists which
	mov	[tcbactseg],ax		; may exist
	pop	ax
	mov	ax,[returnax]		; get return ax
	cli				; by convention
	pop	ss			; yes, this is correct! (trust me!)
	mov	sp,bx
	sti
	mov	bx,ds:[16h]		; get cs
	add	bx,dx			; make adjustment
	mov	es,cx			; point to psp
	mov	cx,ds:[14h]		; get ip
	xchg	ax,cx
	mov	dx,es			; point to psp
	mov	ds,dx			; appears that dos has dx as psp value!

; found method to solve possible compatibility problems
; by pushing the segment and offset and doing a retf
; nolonger need to use reserve area of psp

	assume	ds:nothing, es:pspseg
	push	bx			; user app's segment
	push	ax			; user app's offset
	mov	ax,cx			; not that cx will contain
	mov	bx,cx			; return value for valid drives
	xor	cx,cx
	retf
fun4bx3b:				; done with func #3 - return
	mov	bx,bp
	mov	bp,[bp]
	and	[tflag],not carry	; carry should be clear
	mov	bp,bx
	jmp	fun4bend

; if ds == ffff and si == ffff, return zr

ff_chk:
	push	ax
	push	bx
	mov	ax,ds
	mov	bx,si
	add	bx,1
	adc	ax,0
	or	ax,bx
	pop	bx
	pop	ax
	ret

	subttl fun4bpsp - init a psp
	page
;======================================================================
;,fs
; fun4bpsp - init a psp
;
; this routine will load the psp with the correct values
;
; in:	
;
; out:	
;
;,fe
;======================================================================
fun4bpsp proc near
	assume	ds:nothing, es:nothing, ss:tcb
	push	ds
	lds	si,[prmblk]		; get pointer to passed parms
	lds	si,[si+2]		; get pointer to command line
	mov	es,[pgmseg]
	assume	es:pspseg

; init command line at 80h

	mov	di,offset pspseg:pspcnt ; 80h
	mov	cx,128/2
	rep	movsw

; set memory size.

	mov	si,es
	dec	si
	mov	ds,si			; pointer to memory block
	mov	si,ds:[3]		; size of block for program
	add	si,[pgmseg]		; start of program block
	mov	[pspmem],si		; end of allocation field in psp (offset 2)

; compute if needed new psp function call to 0:c0

	mov	ax, ds:[3]		; size of memory block in paragraphs
	cmp	ax, 0fffh
	jae	f4bskip
	sub	ax, 10h			; remove 10h paragraphs for psp
	push	ax
	mov	cl, 4
	shl	ax, cl			; save offset in bytes
	mov	word ptr [pspcall+1], ax
	pop	ax
	neg	ax
	add	ax, 0ch			; segment + 16*offset = 0:c0
	mov	word ptr [pspcall+3], ax
f4bskip:
	pop	ds

; set fcbs in psp

	push	ds
	lds	si,[prmblk]		; get pointer to passed parms
	lds	si,[si+6]		; get pointer to 1st fcb

; if ds == ffff and si == ffff, skip

	call	ff_chk
	jz	f4bskip2
	mov	di,offset pspseg:pspfcb1; 5ch
	mov	cx,6
	rep	movsw
f4bskip2:
	lds	si,[prmblk]		; get pointer to passed parms
	lds	si,[si+0ah]		; get pointer to 2nd fcb

; if ds == ffff and si == ffff, skip

	call	ff_chk
	jz	f4bskip3
	mov	di,offset pspseg:pspfcb2; 6ch
	mov	cx,6
	rep	movsw
f4bskip3:
	pop	ds
	mov	ax,[envseg]		; set env. pointer in psp
	mov	[pspenv],ax		; 2ch

; validate fcb to make sure that drive specifies of fcb #1 and fcb #2
; are valid. return value to exec is as follows, return in ax
;
;	al=ffh if the first parameter contained an invalid drive
;	       specifier (otherwise al=00h)
;	ah=ffh if the second parameter contained an invalid drive
;	       specifier (otherwise ah=00h)
;
; above information was taken from ibm dos 4.0 tech reference on page
; 6-6 and can be also found in other ibm dos references
;
; this value is save in returnax variable and will be set in ax and bx
; when mos jumps to application, bx is use to transfer value to ax
; easiler and also it appears that dos does the same.
; update 01/31/90 stewart hyde

	push	dx
	xor	cx,cx
	mov	al,byte ptr es:[pspfcb1]
	or	al,al			; current drive
	jnz	fcbcur1
	mov	al,[tcbcdriv]
fcbcur1:
	push	ds
	push	cx
	callmos2 findbdb		; find bdb for this disk
	pop	cx
	pop	ds
	jnc	skipfcb1
	mov	cl,0ffh			; indicate error
skipfcb1:
	mov	al,byte ptr es:[pspfcb2]
	or	al,al			; current drive
	jnz	fcbcur2
	mov	al,[tcbcdriv]
fcbcur2:
	push	ds
	push	cx
	callmos2 findbdb		; find bdb for this disk
	pop	cx
	pop	ds
	jnc	skipfcb2
	mov	ch,0ffh			; indicate error
skipfcb2:
	mov	[returnax],cx		; save return value
	pop	dx
	ret
fun4bpsp endp

;--------------------- error handler  ----------------------

	assume	ds:nothing, es:nothing, ss:tcb
fun4berr:
	cmp	al,error_file_not_found	; is this file not found?
	je	f4berrok
	cmp	al,error_not_enough_memory
	je	f4berrok
	jmp	fun4bcrt		; unknown error
f4berrok:
	mov	bx,bp
	mov	bp,[bp]
	callmos2 moserror
	mov	bp,bx
	test	[rsflags],rs_mmb	; mosheman block still here?
	jz	f4berr2			; no mosheman block
	mov	ax,[workadr]		; block's address
	dec	ax			; back over header
	mov	es,ax
	mov	ah,1
	call	mosheman		; return mosheman block
	cmp	al,al
	jnz	fun4bcrt		; if error, crash
f4berr2:
	test	[rsflags],rs_mmb2	; mosheman block still here?
	jz	f4berr2a		; no mosheman block
	mov	ax,[workadr2]		; block's address
	dec	ax			; back over header
	mov	es,ax
	mov	ah,1
	call	mosheman		; return mosheman block
	cmp	al,al
	jnz	fun4bcrt		; if error, crash
f4berr2a:
	test	[rsflags],rs_env	; environment returned?
	jz	f4berr3
	mov	es,[envseg]		; give back environment block
	mov	ah,49h
	call	sim21			;** for novell
	jc	fun4bcrt		; if error, crash
f4berr3:
	test	[rsflags],rs_trm
	jz	f4berr4			; if no program block
	mov	es,[pgmseg]		; get program block pointer
	assume	es:pspseg
	push	ds
	lds	dx,[psptrmv]		; old terminate vector
	mov	ax,2522h		; restore the old vector
	call	sim21			;** for novell
	pop	ds
	jc	fun4bcrt		; if error, crash
	assume	es:nothing
f4berr4:
	test	[rsflags],rs_pgm	; was a program block allocated?
	jz	f4berr16		; if terminate vector unchanged
	mov	es,[pgmseg]		; get program block pointer
	mov	ah,49h			; free block before return
	call	sim21			;** for novell
	jc	fun4bcrt		; if error abort
f4berr16:
	test	[rsflags],rs_open	; was program file open
	jz	fun4bend
	mov	bx,[flhdl]		; get handle
	mov	ah,3eh
	call	sim21			; close file
	jnc	fun4bend
fun4bcrt:
	mov	ax,'B4'			; unexpected error
	jmp	funerr
fun4bend:

lundef	reloadjust
lundef	currentrelo
lundef	returnax
lundef	mempara
lundef	ldsize
lundef	prmblk
lundef	pathstr
lundef	workadr
lundef	workadr2
lundef	envseg
lundef	pgmseg				; segment address of program block
lundef	psize				; paragraph length of load module (com or exe)
lundef	bsize				; byte length of load module (com or exe)
lundef	lsz				; length remaining to load
lundef	lofs				; current load offset
lundef	lseg				; current load segment
lundef	flhdl
lundef	funnum
lundef	rsflags
lundef	reloc
lundef	adjust
lendp	mosfun4b

	subttl mosfun4c - terninate a process (exit)
	page
;======================================================================
;,fs
; mosfun4c - terninate a process (exit)
;
; terminates the current process and transfers control to the involking
; process.
;
; in:	tal = return code
;
; out:	
;
;,fe
;======================================================================
	assume	ds:grp,ss:tcb,es:nothing
public	mosfun4c
mosfun4c:
	mov	al,[tal]		; get return code
	xor	ah,ah			; normal termination
	mov	[tcbretc],ax
	mov	es,[tcbpsp]		; terminate this process
	jmp	fun00a			; continue with normal termination steps

	subttl mosfun4d - get return code of a subprocess
	page
;======================================================================
;,fs
; mosfun4d - get return code of a subprocess
;
; gets the return code specified by another process either through
; function call 4c or 31.  it returns the exit code only once.
; the low byte of the exit code contains the code sent by the exiting
; routine.  the high byte of the exit code can contain:
;
;	00h - for normal termination
;	01h - for termination by ctrl-break
;	02h - for termination as a result of a critical device error
;	03h - for termination by call 31h
;
; in:	
;
; out:	tax = return code
;
;,fe
;======================================================================
	assume	ds:grp,ss:tcb,es:nothing
public	mosfun4d
mosfun4d:
	mov	ax,[tcbretc]		; get return code for task
	mov	[tax],ax		; return to user
	and	[tflag],not carry	; make sure carry cleared
	ret

	subttl mosfun54 - get verify setting
	page
;======================================================================
;,fs
; mosfun54 - get verify setting
;
; returns the value of the verify flag.
;
; in:	
;
; out:	tal = 00h if verify is off, 01h if verify is on
;
;,fe
;======================================================================
	assume	ds:grp,ss:tcb,es:nothing
public	mosfun54
mosfun54:
	mov	al,[tcbvflg]		; get current setting
	mov	[tal],al		; return it to user
	ret

	subttl sim21 - calls scbfar21
	page
;======================================================================
;,fs
; sim21 - calls scbfar21
;
; calls scb dword ptr scbfar21 with mos segment
; simulates an int 21 call
;
; in:	
;
; out:	
;
;,fe
;======================================================================
	assume	ds:nothing,ss:tcb
public	sim21

sim21   proc	near
	push	word ptr [tcbstkp]
	mov	word ptr [tcbstkp],sp
	sub	word ptr [tcbstkp],128
	call	dosim21
	pop	word ptr [tcbstkp]
	ret
sim21   endp

dosim21 proc near
	pushf				; save flags for simulated int 21 call
	push	cs			; save cs of return
	sub	sp,6			; allocate space for 3 word
	push	bp
	mov	bp,sp
	push	ax			; save ax
	push	ds			; save dx
	pushf				; don't want to mess w/flags
	cmp	word ptr [bp+10h],offset f4bret	 ; coming from open?
	jnz	userip
	mov	word ptr [bp+6],offset execopen	 ; put execopen as retaddr if so
	jmp	short arorip
userip:
	mov	word ptr [bp+6],offset sim21r  ; else put end of routine
arorip:					; tip now set properly on stack for mos
	popf				; restore modifications
	mgetscb ds
	assume	ds:grp
	mov	ax,word ptr [scbfar21+2]  ; get segment
	mov	[bp+4],ax
	mov	ax,word ptr [scbfar21] ; get offset
	mov	[bp+2],ax
	pop	ds
	assume	ds:nothing
	pop	ax
	pop	bp
	retf
sim21r: ret

; the file open logic uses the execopen return address
; to detect when an exec file open call is being done.

	public	execopen
execopen:
	ret				
dosim21 endp

;-----------------------------------------------------------------------
; temporary unexpected error handler

funerr	label	near
	mov	cs:[ferrno],ax
	call	bugerror
	db	'0 Unexpected error during function #'	;@@xlat
ferrno	dw	0,0

;-----------------------------------------------------------------------
mosseg	ends
	end

