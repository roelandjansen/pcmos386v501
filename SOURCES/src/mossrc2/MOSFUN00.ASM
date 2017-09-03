	include page.inc
	title	MOSFUN00.ASM - General function calls
	extrn	bugerror:near		; Defined to turn stack overflow on
;-----------------------------------------------------------------------;
;		Development Specification				;
;									;
; Program Name: $$MOS.COM		Assigned to: David Morrow	;
; Module Name:	MOSFUN00		Assign date: 08/19/86		;
; Entry Points: MOSFUNxx (see below)	Completed:			;
; Entry From:	MOSINT21						;
; Entry Method: CALL							;
; Calls:								;
; Purpose:	Task management functions.				;
; Last Update:	07/25/90						;
;									;
; This module handles the following function calls:			;
;									;
; 00, 0D, 0E, 19, 1B, 1C, 25, 26, 29, 2A, 2B, 2C, 2D, 2E, 30, 31,	;
; 32, 33, 35, 36, 37, 38, 48, 49, 4A, 4B, 4C, 4D, 54, 58, 59, 65,	;
; 66, 67, 68								;
;									;
;	11/24/86  M Stitt   added code to EXEC (4B) and terminate (00)	;
;			    to decrement TCBNEST.			;
;			    Also, removed change to Int 23h vector	;
;			    in EXEC.					;
;									;
;	01/19/87  J. Mayo   added SWITCHCHAR (37) call			;
;									;
;	03/03/87  J. Mayo   added code to EXEC (4B) to set the memory	;
;			    size correctly in the PSP's of new          ;
;			    processes, and to return all resources if	;
;			    an error occurred before end of EXEC.	;
;									;
;	03/16/87  J. Mayo   Get Disk Free Space (36) was reporting 2	;
;			    free clusters too many			;
;	03/31/87  J. Mayo   Added Get Default DPB (1f) for Norton Util. ;
;			    and fixed EXEC subfunction 1 to set top of	;
;			    stack only if .COM file > 65534 bytes long	;
;	04/07/87  J. Mayo   allow non-consecutive drives in Set Drive	;
;			    (0E)					;
;									;
;	04/16/87  S. Hyde   Added logic to compute PSP function call	;
;			    and segment size in PSP			;
;									;
;	04/22/87  S. Hyde   change EXEC to use res4 instead of 2e & 30	;
;			    change terminated and exec so that the	;
;			    callers SS & SP are restored when child	;
;			    returns. SS & SP are stored at offset 2e	;
;			    and 30 of the PSP of the parent. MS Fortran ;
;			    4.0 requires this.				;
;									;
;	04/27/87  S. Hyde   Change the method of allowing Norvell to	;
;			    intercept internal 21 for resident porgrams ;
;			    without conflicting programs like SQZ and	;
;			    NOTE-IT					;
;									;
;	04/30/87  S. Hyde   Remove PSP Parent setting in Function 26	;
;			    and place code in EXEC (WS CorrectStar)	;
;									;
;	05/15/87  J. Mayo   Restored full COUNTRY (38) functionality	;
;									;
;	06/16/87  S. Hyde   corrected loading overlays debug support MCB;
;									;
;	06/22/87  S. Hyde   MCB Problem Fixed. 4A on allocated blocks	;
;			    follow by a free block			;
;									;
;	06/24/87  S. Hyde   COM Overlay files don't have PSPs 100h      ;
;			    too much. Exec didn't take this in account  ;
;									;
;	07/14/87  S. Hyde   Gracefull Exit from too small SMP to load	;
;			    EXE header into memory. (NO BUGERROR)	;
;			    Insufficent memory error code return	;
;									;
;	07/18/87  RBR	    Corrected class/action/locus for error code ;
;			    18 (no more files); this fixes a problem	;
;			    with IBM/BPI accounting package		;
;									;
;	07/20/87  J. Mayo   EXEC now opens files in Deny write mode, not;
;			    compatibility mode				;
;									;
;	07/21/87  S. Hyde   added special INT 24 function ffh if too	;
;			    small SMP while loading EXE header		;
;									;
;	07/21/87  J. Mayo   PARSE now stops ignores extra file name	;
;			    characters, instead of putting them in the	;
;			    extension.					;
;									;
;	07/29/87  S. Hyde   Include Get and Set PSP optimization for	;
;			    speed. Macros are found in MOSREGS		;
;									;
;	08/05/87  S. Hyde   Corrected 4b01 incase  carry was set before ;
;			    making call to mos				;
;									;
;	08/18/87  MJS	    Modified EXEC to set/reset tcbexec3d flag	;
;			    around the call to fun3d so openfile will	;
;			    relax its testing of sharing/compatiblity	;
;			    mode conflicts				;
;									;
;	09/08/87  S. Hyde   Correct error-code reporting on some	;
;			    functions while reporting error codes for	;
;			    technical reference manual. Found:		;
;				Fun 33h return ffh if al > 2		;
;									;
;-----------------------------------------------------------------------;
;  MJS 10/1/87	Modified special call to mocxpcor's int24 handler by    ;
;		EXEC to match changes made to moxcpcor.  Now, pass a	;
;		string to int24 for special case message.  Makes this	;
;		pop up message feature available for other uses.	;
;		This was done initially for the MOS USEIRQ warning	;
;-----------------------------------------------------------------------;
;  JSM 10/06/87 Call int 38h, function 15h, before terminating a	;
;		process 						;
;-----------------------------------------------------------------------;
;  SAH 10/20/87 Remove reference to mosdebug				;
;-----------------------------------------------------------------------;
;  SAH 10/23/87 Inserted reseting of MOSINT38 vector during terminated	;
;		to avoid conflics with First Choice.  Problem occur	;
;		because of JSM's addition of INT 38 function 15.  (Well ;
;		this is a better place for it anyway)			;
;-----------------------------------------------------------------------;
;  SAH 11/02/87 Added INT 38h replacement chain logic to EXEC and	;
;		TERMINATE.   Following new TCB Variables have been added;
;			TCBCNT38 - counter of Int 38 replacement on EXEC;
;			TCBFAR38 - Storage area for 5 INT 38H vectors	;
;									;
;  SAH 11/03/87 Correct problem in Vector Chain Mangament when app	;
;		would use function 35 the return the vector which it	;
;		set early (which we set back to chain table and falsely ;
;		assume when vector was reinserted that it was reinsert- ;
;		the orginally vector (pointing to mos) but was not.	;
;		Function 35 now return the most recent vector in the	;
;		chain table if there is a chain table and application	;
;		vector is in chain table.  If application grabs a vector;
;		from segment 0, the only way we can correct this	;
;		problem is use the 386's memory protection.             ;
;-----------------------------------------------------------------------;
;  SJC 11/13/87 Fixed problem where execute-only file did not execute.	;
;		Determined that the return address for execopen (tested ;
;		in mosfun3d) was incorrectly placed into INT21's        ;
;		IRET return address in SIM21.  It placed the address of ;
;		the end of the SIM21 routine, not execopen.  Modified	;
;		SIM21 to place the proper offset into the return address;
;		Modified mosfun4b to use different label than execopen. ;
;		(which is now inside SIM21, which therefore, can't move);
;		See SIM21 and mosfun4b (;execopen) for changes. 	;
;-----------------------------------------------------------------------;
;  SAH 12/01/87 Remove my additions for function 35 nolonger needed	;
;-----------------------------------------------------------------------;
;  SAH 12/03/87 Remove calls to UptINMOS, set scbinmos to 0 when task	;
;		terminates						;
;-----------------------------------------------------------------------;
; MJS 12/8/87	Add code to fun00 and fun4b to decrement scbinmos since ;
;		this is a time when a mossaver entry is made with no	;
;		immeadiately corresponding mosrestore.			;
; JSM/MJS	implanted code in fun31 from JSM to correct problem with;
;		TSR's getting their PSP updated properly.               ;
;-----------------------------------------------------------------------;
;  JSM 12/09/87 Fixed problem in fun4a which caused function to return	;
;		incorrect block sizes in some cases.			;
;-----------------------------------------------------------------------;
; MJS 12/20/87	Reset tcbstkp in fun00 to handle sidekick's un-install  ;
;-----------------------------------------------------------------------;
;  SAH 01/12/88 Corrected mosfun31 so that it handles applications	;
;		which allocate memory blocks using function 48 and go	;
;		resident including the allocated blocks.  Verify under	;
;		DOS that function 31 is where this action should be	;
;		taken place and not during function 4ah which cause the ;
;		the original problem.					;
;-----------------------------------------------------------------------;
;  SAH 01/20/88 Change SCBSEG and ZERO seg access to MGetXXXX macros	;
;		Optimize routines to decrement ment SCBINMOS flag by	;
;		placing code in single routine and corrected some	;
;		conditions where it might be possiable that SCBINMOS	;
;		flag is decrement when it has a value of ZERO.		;
;-----------------------------------------------------------------------;
;  SAH 01/27/88 Correct problems with Borland's Quattro (uses PLINK 86) ;
;		which had problems when more and one copy was running	;
;		and memory problems (SMP and MAIN) cause exec to bomb	;
;		out of one of the task.  Found problem to be that exec	;
;		was not closing the files and this left system info in	;
;		the heap which cause the program not to be able to load ;
;		up again.  There is still a problem if 2 task try to	;
;		exec (EXE's) and not enough SMP, the second task will   ;
;		get a SMP header critical error, but should be able to	;
;		reexecute the program after pressing a key to get out	;
;		the window.						;
;-----------------------------------------------------------------------;
;  SJC 2/5/88	Fix tcbstkp before and after JSM's INT 38 to allow all  ;
;		applications to see a process termination while also	;
;		allowing stack re-entrancy in MOS!			;
;-----------------------------------------------------------------------;
; MJS 2/10/88	Modified fun4a to support an undocumented return	;
;		parameter that QuickBasic ver 4.0 counts on to work	;
;		properly.  When fun4a is called, es points to the memory;
;		block to be modified.  On return, if no error, both es	;
;		and ax need to hold this memory block's segment.        ;
;-----------------------------------------------------------------------;
; sah/rbr 02/20/88 Move DDT Segment to MO2 Group			;
;-----------------------------------------------------------------------;
; SAH 02/29/88	Correct problems with INT 38 vector and EXEC		;
;		    1.	Replace INT 38 with simulated call to		;
;			SCBFAR38					;
;		    2.	Corrected bug in SET38 where it was trashing	;
;			INT 39 vector.					;
;-----------------------------------------------------------------------;
; SAH 03/03/88 Corrected function 38 which was clobbering the stack with;
;		SideKick Plus because we were copying 36 bytes when we	;
;		should have only copy 32 bytes which SK+ allocated on	;
;		the stack.						;
;-----------------------------------------------------------------------;
; SAH 03/06/88	Made changes for SK(+) "Thanks to some insight from ROD ;
;		and techinical information which I have"   Change       ;
;		how SCBINMOS works (should have 2 values only	0 = NOT ;
;		BUSY,	1 = BUSY.					;
;-----------------------------------------------------------------------;
; RBR 03/07/88	Don't round memory allocations if declare call is not   ;
;		supported.						;
;-----------------------------------------------------------------------;
; RBR 03/11/88	Do declares/undeclares during memory management.	;
;-----------------------------------------------------------------------;
; SAH 03/15/88	Corrected function 36 reporting which was incorrect	;
;		because it was not starting from cluster 2 on the fat	;
;-----------------------------------------------------------------------;
; SAH 03/16/88	Corrected problems with overlays and SMP increasing	;
;		because code for deallocating work space was below the	;
;		test for overlay code (and load but not execute)	;
;-----------------------------------------------------------------------;
; RBR 03/28/88	Support the 286 "clear auto declarations" function.	;
;-----------------------------------------------------------------------;
; SAH 04/13/88	Corrected class, action, locus for extended error code	;
;		32.							;
;-----------------------------------------------------------------------;
; RDG 04/28/88	Moved function 38 country code data to 'gdata' and	;
;		corrected set/get to use scbcntry rather than country.	;
;-----------------------------------------------------------------------;
; jrb 05/02/88	replaced read of fat with pointer to bdbmedia in fun1b	;
; jrbr		(why read it if you don't have to)                      ;
;-----------------------------------------------------------------------;
; SAH 05/13/88	Following corrections are made in EXEC			;
;		1. If loading overlay, memory is allocated to max	;
;		   this corrected problems with latest ALPHA code with	;
;		    Borland's Quattro                                   ;
;		2. after overlay was load carry was not being clear	;
;-----------------------------------------------------------------------;
; RBR 05/16/88	Some code size optimizations; saved 672 bytes.		;
;-----------------------------------------------------------------------;
; SAH 05/18/88	Corrected function 49h which should not combine the	;
;		deleted memory blocks.	This corrected a problem with	;
;		Quick-Basic chaining.  Also terminate should do the	;
;		Actual combine of freed memory blocks.	Also exec (not	;
;		overlays)  should combine the blocks - main reason I see;
;		need for this because our command processor allocates	;
;		memory and this cause problems under new but more	;
;		compatible techniques) this should only be done with exe;
;-----------------------------------------------------------------------;
; SAH 05/20/88	My 03/06/88 was incorrect. After running a test program ;
;		on dos, INDOS flag is actual increment and decrement.	;
;		to give a consistent and easy changable interface to	;
;		to SCBINMOS I implement the following routines		;
;			DECINMOS - decrements inmos flag is not zero	;
;			INCINMOS - increments inmos flag		;
;			RSTINMOS - resets inmos flag			;
;-----------------------------------------------------------------------;
; SAH 06/14/88	Corrected a strange and interesting problem with my	;
;		5/18/88 update.  DS need to be pointed to grp inside	;
;		inside combmcb procedure.				;
;-----------------------------------------------------------------------;
; mjs 7/2/88	Added noswitch/okswitch calls to mosfun0d, mosfun1b,	;
;		mosfun32, and mosfun36. 				;
;-----------------------------------------------------------------------;
; mjs 7/13/88	Removed call to updcht (chain table management) from	;
;		mosfun25.  Added a call to grab_back for int8.		;
;-----------------------------------------------------------------------;
; mjs 7/22/88	Added logic to support regrab of int9.			;
;-----------------------------------------------------------------------;
; SAH 08/01/88	Added detection and memory allocation to solve problem	;
;		with EXEPACK files.  Cleanup module and corrections for ;
;		OPTASM							;
;-----------------------------------------------------------------------;
; SAH 08/25/88	Corrections to exec so that it uses values in EXE header;
;		for calculating file size.  Also improve handling of the;
;		case where file is loaded up high (MS-WINDOWS)		;
;		Also remove tempendency of PSP reserved field when	;
;		executing to an EXEFILE 				;
;-----------------------------------------------------------------------;
; SAH 08/29/88	Corrected function 26 which was inserting setment of psp;
;		but wasn't correctly handling the offset                ;
;-----------------------------------------------------------------------;
; SAH 09/13/88	Made mosfun48 combine MCB's, this corrected a problem   ;
;		with UniSys application.				;
;-----------------------------------------------------------------------;
; SAH 10/13/88	Correct MCB handling during function 31 for IRMACOM	;
;-----------------------------------------------------------------------;
; mjs 11/01/88	Modified exec to accomodate PFW:Write's sloppiness.     ;
;		When pw.com exec's pw.prg, the filename string passed to;
; ptr 162	exec happens to be located in the unallocated memory	;
;		into which the exec will happen.  When our exec code	;
;		builds a new environement block and psp in this free	;
;		memory, the filename string gets overwritten.  Under DOS;
;		they must just be lucking out.				;
;		Modified exec to copy the ds:dx filespec into local	;
;		storage.  Also moved the file open call to the front	;
;		of exec since pw.com doesn't protect its error message  ;
;		string either.						;
;-----------------------------------------------------------------------;
; SAH 11/16/88	Corrections to problems created with MJS's 11/01/88 by  ;
;		moving the file open call in front of exec. This cause	;
;		an additional unwanted filehandle to be created for new ;
;		child psp.  This problem was one of the main reasons	;
;		why I was having problem with Tecmar tape drive for the ;
;		PS/2's.                                                 ;
;-----------------------------------------------------------------------;
; RKG 11/18/88	PTR176 function 0E set drive returns incorrect maximum	;
;		drive.	It did not include aliases.  Now returns max of ;
;		actual devices and aliases.				;
;-----------------------------------------------------------------------;
; jrb 11/17/88	rodney, today's the 17th - 4b function 3 was clearing   ;
;		the low bit of the return address offset instead of	;
;		clearing the carry flag - if the calling int 21h	;
;		was on a odd byte, it would return to the 21h doing	;
;		just about anything					;
;-----------------------------------------------------------------------;
; rbr 12/06/88	Memory chain destruction was causing a crash instead	;
;		of an error message.					;
;-----------------------------------------------------------------------;
; SAH 01/27/89	Modifications to retf macro for MASM 5.10		;
;-----------------------------------------------------------------------;
; SAH 02/21/89	Made exec restore MOS SERVICES interupt to SCBFAR38	;
;		value to make sure it is always set when program is	;
;		executed. Please note that this is only done if 	;
;		SERVICES <> 38h 					;
;-----------------------------------------------------------------------;
; SAH 03/22/89	Corrected Function 4A which should also combine MCB	;
;		before making it's check to grow or not. This is        ;
;		necessary becuase some appication could do a function	;
;		49h which does not combine the MCB's, and therefor      ;
;		function 4Ah would not know about the free MCB. 	;
;-----------------------------------------------------------------------;
; mjs 04/20/89	Modified how mosfun4b determines the size of an EXE	;
;		file.  The directory size must be used rather than the	;
;		size as recorded in the EXE header.  This is what dos	;
;		does and it fixes a problem with an application done	;
;		in QuickBasic 3.0 which uses chaining.			;
;-----------------------------------------------------------------------;
; RKG 04/20/89	Close spool files via INT 17 Func FFh			;
;-----------------------------------------------------------------------;
; SAH 05/25/89	 Remove mosfun50, 51 and 62				;
;-----------------------------------------------------------------------;
; RKG 05/30/89	MJS's modification of 4/20 broke ACCPAC's PLUS2.  The	;
;		program was very large but had a small sector count.	;
;		The program size must also be used for allocating memory;
;-----------------------------------------------------------------------;
; SAH 05/31/89	Correct RKGs 05/30/89 update which cause MS-Windows not ;
;		to load because windows requires that if exe header size;
;		is larger than file size, then we must use exe header	;
;		size. What I did, was to use the larger of exe header	;
;		size and directory size to make sure that both Windows	;
;		and AccPac's PLUS2 is compatible                        ;
;-----------------------------------------------------------------------;
; RKG 06/26/89	DOS allows freeing a free memory block if the block is	;
;		intact. 						;
;-----------------------------------------------------------------------;
; mjs 06/28/89	Corrected setting of the default dta segment in the	;
;		exe case.  it was being set to the stack segment rather ;
;		than the psp segment.					;
;-----------------------------------------------------------------------;
; SAH 07/06/89	Made sure that exec (4b) allocates all of memory instead;
;		of allocating 120h bytes for loading PSP in.  This	;
;		Corrected a problem with a RealWorld 5.0 accounting	;
;		package which had a LOADWIN.COM which exec a WINDOWS.EXE;
;		tsr.							;
; SAH 07/13/89	Corrections to above fixed, so that size is correctly	;
;		passed on.						;
;-----------------------------------------------------------------------;
; SAH 07/26/89	Remove Set38, Get38, and SetServices.			;
;-----------------------------------------------------------------------;
; mjs 08/03/89	Rework how fun31 handles the case where a tsr allocates ;
;		one or more blocks with fun48 before terminating.	;
;		The previous method was conflicting with the case where ;
;		a tsr (btree.com of the sybiz package) was shrinking	;
;		back and then using a larger size for dx of fun31.	;
;		Generated from mosfun00.cht (\mos.dir\cht.dir on server);
;-----------------------------------------------------------------------;
; mjs 10/18/89	modified how exec calculates the size of an exe load
;		module (hopefully for the last time!).  I found that
;		while the word at offset 2 within the header is documented
;		as being the bytes in the last page, it is not actually
;		used when calclating the load module's size.  Only the
;		number of whole 512 byte pages should be used.
;-----------------------------------------------------------------------;
; BWR 01/23/90	Added support for DOS function 58. (Get/Set Memory	;
;		Allocation Strategy).  This function must, at least,	;
;		store the strategy specified by the caller and recall	;
;		it if it needs to be checked.  At present the routine	;
;		simply returns with the function code still in AX.	;
;-----------------------------------------------------------------------;
; BWR 01/25/90	Function 38 (Get Country Info) changed to return a 34	;
;		byte table instead of a 32-byte table. (DOS 3.30)	;
;-----------------------------------------------------------------------;
; BWR 01/29/90	Added DOS functions through 68h for DOS 3.30 compat.	;
;		Function 65: Get Extended Country Info			;
;		Function 66: Get/Set Gloabl Code page. (Not supported)	;
;		Function 67: Set Handle Count				;
;		Function 68: Commit File				;
;									;
; Note:  Functions 65 and 66 are not yet supported.  MOS does not yet	;
;	 have code page support.  This should be initiated as a		;
;	 separate project.						;
;-----------------------------------------------------------------------;
; SAH 02/05/90	Corrections to function 4ah setblock so that it even if ;
;		it returns an error in size, MOS will combine block, 	;
;		this also means that it will combine block before the   ;
;		the free block with the block that is free. Also 	;
;		conditionally assemble out instructions 286 Declare 	;
;		calls. Changes to exec so that AX contains drive	;
;		specifiers. 00h if parmerter drive is ok, otherwise 0ffh;
;		Parm 1 is in al, and parm 2 is ah. Change function 30h  ;
;		so that it returns task specific DOS version #		;
;-----------------------------------------------------------------------;
; BWR 02/15/90	Cleaned up references to Memory Control Block chain in	;
;		all functions dealing with memory allocation.  The	;
;		memory addressing construct used DI as a dummy variable ;
;		to calculate the offset address of the various MCB 	;
;		pieces which is not necessary.  (DI was always 0)	;
;		Also cleaned up some segment register moves through	;
;		the stack to use a register instead. I.E.		;
;			push	ds					;
;			pop	es	;SLOW method			;
;									;
;			mov	ax, ds					;
;			mov	es, ax	;FAST method			;
;									;
;-----------------------------------------------------------------------;
; SAH 02/22/90 Corrections for SKPLUS, must only send 32 bytes to	;
;	       requester if DOS Version is 3.20, else we can send 34    ;
;	       bytes to requested if DOS Version 3.30 for function 38h  ;
;	       Corrections for WordPerfect 5.10, Save BX,CX,DX,SI,DI,BP ;
;	       DS, and ES on User's stack during exec and terminate 	;
;	       will restore these values on exit. Use unused protion of ;
;	       callers stack thus can mot be use on internal 4bh calls  ;
;	       which are on the TCB stack.				;
; 	       made maxdays public for mostemp				;
;-----------------------------------------------------------------------;				
; SAH 03/01/90 PSPsp is 4 is adjusted by exec				;
;-----------------------------------------------------------------------;
; SAH 06/22/90 Correction for MSetPSP for lanlink			;
;-----------------------------------------------------------------------;
; SAH 07/17/90 Corrections so that EXEC will use only 512 bytes of SMP  ;
;	       when doing EXE header Relocations. This was done so that ;
;	       it would reduce the extra SMP requirements on the system ;
;-----------------------------------------------------------------------;		
; SAH 07/25/90 Corrected SMP allocations, should allocated 33 paragraphs;
; 	       instead of 513 paragraphs.				;
;-----------------------------------------------------------------------;	

	include OPTIONS.INC
	include GROUP.INC
	.xlist
	page
;-----------------------------------------------------------------------;
;  Include Error code definitions.					;
;-----------------------------------------------------------------------;
	if	0 eq 0		;Defeat PUBLIC.COM
include ERRCODES.INC
	endif
;-----------------------------------------------------------------------;
; access to partition saved registers					;
;-----------------------------------------------------------------------;
	include MOSREGS.INC

tcb	segment at 9999h
	include MOSTCB.INC	; TCB definition
tcb	ends

	include MOSCDB.INC	; etc., etc., etc.
	include MOSTFB.INC
	include MOSGFB.INC
	include MOSBDB.INC
	include XIFMACS.INC

gdata	segment word public 'data'
	include MOSSCBEX.INC	; specify all SCB items as external
	.list

	; USA table

USAinfo dw	1		; country code
	db	'$',0,0,0	; Currency symbol
	db	',.-:,' 	; Thousands,decimal,date,time,DL separators
	db	00100000b	; Time,digits,currency,date formats

USAlen	equ	$-USAinfo

	dw	2		; country code for Canadian-French
	db	'$',0,0,0	; Currency symbol
	db	' ,-:;' 	; Thousands,decimal,date,time,DL separators
	db	01101110b	; Time,digits,currency,date formats

	dw	31		; country code for Netherlands
	db	9fh,0,0,0	; Currency symbol
	db	'.,-:;' 	; Thousands,decimal,date,time,DL separators
	db	01100001b	; Time,digits,currency,date formats

	dw	32		; country code for Belgium
	db	'F',0,0,0	; Currency symbol
	db	' ,/:;' 	; Thousands,decimal,date,time,DL separators
	db	01101101b	; Time,digits,currency,date formats

	dw	33		; country code for France
	db	'F',0,0,0	; Currency symbol
	db	' ,/:;' 	; Thousands,decimal,date,time,DL separators
	db	01101101b	; Time,digits,currency,date formats

	dw	34		; country code for Spain
	db	9eh,0,0,0	; Currency symbol
	db	'.,/:;' 	; Thousands,decimal,date,time,DL separators
	db	01101101b	; Time,digits,currency,date formats

	dw	39		; country code
	db	'Lit.'		; Currency symbol
	db	'.,/:;' 	; Thousands,decimal,date,time,DL separators
	db	01000101b	; Time,digits,currency,date formats

	dw	41		; country code for Switzerland
	db	'Fr',0,0	; Currency symbol
	db	',...,' 	; Thousands,decimal,date,time,DL separators
	db	01101001b	; Time,digits,currency,date formats

	dw	44		; country code for United Kingdom (England)
	db	9ch,0,0,0	; Currency symbol
	db	',.-:,' 	; Thousands,decimal,date,time,DL separators
	db	01100001b	; Time,digits,currency,date formats

	dw	45		; country code for Denmark
	db	'DKR',0 	; Currency symbol
	db	'.,/.;' 	; Thousands,decimal,date,time,DL separators
	db	01101101b	; Time,digits,currency,date formats

	dw	46		; country code for Sweden
	db	'SEK',0 	; Currency symbol
	db	'.,-.;' 	; Thousands,decimal,date,time,DL separators
	db	01101010b	; Time,digits,currency,date formats

	dw	47		; country code for Norway
	db	'KR',0,0	; Currency symbol
	db	'.,/.;' 	; Thousands,decimal,date,time,DL separators
	db	01101001b	; Time,digits,currency,date formats

	dw	49		; country code for Germany
	db	'DM',0,0	; Currency symbol
	db	'.,..;' 	; Thousands,decimal,date,time,DL separators
	db	01100001b	; Time,digits,currency,date formats

	dw	61		; country code for Australia
	db	'$',0,0,0	; Currency symbol
	db	',.-:,' 	; Thousands,decimal,date,time,DL separators
	db	01100001b	; Time,digits,currency,date formats

	dw	351		; country code for Portugal
	db	'$',0,0,0	; Currency symbol
	db	'.,/:;' 	; Thousands,decimal,date,time,DL separators
	db	01101101b	; Time,digits,currency(s/b 4),date formats

	dw	358		; country code for Finland
	db	'MK',0,0	; Currency symbol
	db	' ,-:;' 	; Thousands,decimal,date,time,DL separators
	db	01101101b	; Time,digits,currency,date formats

	dw	785		; country code for the Middle East
	db	'$',0,0,0	; Currency symbol
	db	'.,/:;' 	; Thousands,decimal,date,time,DL separators
	db	00111101b	; Time,digits,currency,date formats

	dw	972		; country code for Israel
	db	99h,0,0,0	; Currency symbol
	db	',./:,' 	; Thousands,decimal,date,time,DL separators
	db	01101001b	; Time,digits,currency,date formats

endtab	dw	0		; this word of 0 must come immediately
				; after last country information block
gdata	ends

irq	segment byte public 'data'
	extrn	irqstart:byte
irq	ends

poll	segment byte public 'data'
poll	ends

;-----------------------------------------------------------------------;
; Memory block definition						;
;-----------------------------------------------------------------------;
mbseg	segment at 1111H

mbtype	db	?		; M for Memory block, Z for last block
mbowner dw	?		; Owner PSP address
mbsize	dw	?		; Size of block

mbseg	ends

	page
	include mospsp.inc

;-----------------------------------------------------------------------;
; FCB definition and structure						;
;-----------------------------------------------------------------------;
fcbstru struc

fcbdrv	db	?		;0 Drive
fcbfile db	8 dup(?)	;1 Filename
fcbext	db	3 dup(?)	;9 File extension
fcbcb	dw	?		;12 Current block number
fcbrec	dw	?		;14 Logical record size
fcbsiz	dw	2 dup(?)	;16 File size in bytes
fcbdate dw	?		;20 Date of last update
fcbres	db	10 dup(?)	;21 Reserved
fcbcr	db	?		;32 Current relative record
fcbrr	db	4 dup(?)	;33 Relative record number

fcbstru ends

domos	macro
	pushf			; Simulate an INT 21H
	push	cs
	call	mosint21
	endm

Ljz	MACRO	jmpdest
	LOCAL	ppp1
	jnz	ppp1
	jmp	jmpdest
ppp1:
	ENDM

Lja	MACRO	jmpdest
	LOCAL	ppp1
	jna	ppp1
	jmp	jmpdest
ppp1:
	ENDM

Ljb	MACRO	jmpdest
	LOCAL	ppp1
	jnb	ppp1
	jmp	jmpdest
ppp1:
	ENDM

ddt	segment word public 'code2'
	extrn	closeall:near, flush:near, devchk:near, invbdb:near
	extrn	findbdb:near, finddrv:near, todriver:near, setphdl:near
	extrn	setfree:near, rdfat:near, moserror:near
	extrn	mediachk:near, flushdata:near
ddt	ends

	page
mosseg	segment word public 'code1'
	assume	cs:mos,ds:grp,es:nothing,ss:tcb

	extrn	mosend:byte, scbfree:word, sbios:word, mosint21:near
	extrn	caps:near, mosheman:near, gettime:near, regrab8_data:byte
	extrn	getdate:near, grab_back:near
	extrn	mosoldfn:near, decinmos:near, incinmos:near, regrab9_data:near
	extrn	rstinmos:near, noswitch:near, okswitch:near, closspls:near

	public	fun00a, mosfun1b
	include mosfun00.pub


	subttl	mosfun00 - Program terminate
	page
;-----------------------------------------------------------------------;
; Terminate the execution of a program. 				;
; The terminate, CTRL-Break, and critical error exit addresses are	;
; restored to the values they had on entry to the terminating program	;
; from the values saved in the PSP.  All file buffers are flushed and	;
; all handle files are closed.	Any files that have changed in length	;
; and not closed are not properly recorded in the directory.  Control	;
; transfers to the terminate address.  This call performs the same	;
; function as INT 20H.							;
; Any memory blocks that are associated with this process are		;
; deallocated.								;
;									;
;  On Entry:								;
;	TCS -> Points to PSP						;
;									;
;  On Exit:								;
;	Nothing 							;
;									;
;	Global data affected						;
;	Global procedures called					;
;	What registers are changed					;
;-----------------------------------------------------------------------;
	public	mosfun00
	assume	cs:mos,ds:grp,ss:tcb,es:nothing
mosfun00:
	xor	ax,ax
	mov	[tcbretc],ax	; Set error code to normal termination

; Free memory allocated to process

	mov	es,[TCS]	; Get PSP pointer
	MSetPSP	es
fun00a: 			;** Entry point for MOSFUN4C
				;** Entry point for terminate
	mov	ax,sp		; put bias on stack to allow reentry
	sub	ax,98
	xchg	[tcbstkp],ax
	push	ax
	mov	ah,15h			;JSM 10/06/87
	pushf				;SAH simulate interupt call to
	cli				;SAH to INT 38 since a vector could
	call	dword ptr [scbfar38]	;SAH have been takin by app.
	pop	[tcbstkp]
	mov	ax,offset [tcbstack]
	mov	[tcbstkp],ax	; reset the stack

; Deallocate all memory blocks for this PSP
; But not if PSP = Parent PSP (PSPprnt)

	push	ds
	assume	es:nothing
	push	es
	call	closspls	; close all spool files
	callmos2 closeall	; Close any open files
	pop	es
	pop	ds
	mov	bx,es		; Deallo any blocks for this guy
	assume	es:pspseg
	cmp	bx,[PSPprnt]	; Is this the special case? (command.com)
	jne	$+5
	jmp	fun00b		; Do not deallo MBs
	assume	es:pspseg
	mov	ax,[tcbmbpf]	; Search through entire MB chain
	mov	cx,ax		; Set initial 'previous pointer'
fun00c1:
	mov	es,cx		; Address next block
	assume	es:mbseg
	inc	cx
	add	cx,[mbsize]	; Calc pointer to next block
	cmp	[mbowner],bx	; Deallocate this one?
	jne	fun00c2
	mov	ax,es
	inc	ax		; Use function call Addressing
	push	es
	mov	es,ax
	mov	ah,49H		; Free memory block owned by this PSP
	domos
	pop	es
	jc	fun00c3
	cmp	[mbtype],'Z'	; Is this the last block?
	jne	$+5		; No
	jmp	fun00b		; Yes, end search
	mov	cx,es
	jmp	fun00c1 	;  block may invalidate its address)
fun00c3:
	mov	ax,'00'
	jmp	funerr
fun00c2:
	cmp	[mbtype],'Z'	; Is this the last block?
	jne	fun00c1 	; No

;** Entry point for MOSFUN31
;** Entry point for TERMINATE

fun00b:
	call	combmcb 	; SAH combine adjacent MCB's
	assume es:nothing,ss:tcb
	mov	es,[tcbpsp]
	assume	es:pspseg
	push	word ptr [PSPtrmv+2]	; Set up for RETF exit to terminate
	push	word ptr [PSPtrmv]	;   address.
	MGetZERO es
	assume	es:nothing
	push	ds
	mov	ds,[tcbpsp]	; Get PSP address
	assume	ds:pspseg

; Reset current PSP to parent

	mov	ax,[PSPprnt]		; Save area for parent PSP
	MSetPSP	ax
	cld				; Restore int 22, 23 and 24h from PSP
	mov	di,22H*4		; Offset to start of vectors
	mov	si,offset PSPtrmv	; Save space for vectors in PSP
	mov	cx,3*2			; Move 3 vectors
	rep movsw
	mov	ax,[tcbsav24]		; is a heap block left over from a non-return
	or	ax,ax			; from toint24 ?
	jz	SkipFreeHeap
	mov	word ptr [tcbsav24],0	; reset the pointer
	push	es
	mov	es,ax
	mov	ah,1
	call	mosheman	; free the heap block
	pop	es
	or	al,al
	jz	SkipFreeHeap
	call	BUGERROR
	db	'80 '
	db	'SMP free error',00h ;@@XLAT
SkipFreeHeap:
	call	RstINMOS		; SAH 05/20/88 reset INMOS
	cmp	byte ptr [tcbnest],0
	je	SkipDecNest
	dec	[tcbnest]	; decrement counter for nest control
				; since entered mosint21 but didn't leave
	mov	[tcbspskp],'N'	; reset spooler control flag in case a
				; critical error abort left it set
SkipDecNest:
	pop	ds		; get ds
	pop	ax		; get saved PSPtrmv
	pop	bx		; get saved PSPtrmv+2
	push	ds
	mov	ds,[tcbpsp]
	push	di
	push	es
	les	di,dword ptr [PSPsp]	; address stack
	cld
	stosw
	mov	ax, bx
	stosw
	pop	es
	pop	di
	pop	ax		; get ds into ax
	cli
	mov	ss, [PSPss]
	mov	sp, [PSPsp]
	sti
	mov	ds, ax
	assume	ds:grp
	mov	[scbnoswt], 0
;
; The following addtions are added to correct problem with 
; WordPerfect 5.10 by restoring registers from users stack
;
	mov	ax,ss
	cmp	ax,[scbtcbpc]
	je	skipreset
	mov	bp,sp
	sub	bp,12
	mov	bx,word ptr ss:[bp-2]
	mov	cx,word ptr ss:[bp-4]
	mov	dx,word ptr ss:[bp-6]
	mov	si,word ptr ss:[bp-8]
	mov	di,word ptr ss:[bp-10]
	mov	ds,word ptr ss:[bp-14]
	mov	es,word ptr ss:[bp-16]
	mov	bp,word ptr ss:[bp-12]
skipreset:
;
	retf			; Exit to terminate address


	subttl	mosfun0d - Disk Reset
	page
;-----------------------------------------------------------------------;
; Flushes all file buffers						;
; Files changed in size but not closed are not properly recorded in the ;
; disk directory.							;
;									;
;  On Entry:								;
;	Nothing 							;
;									;
;  On Exit:								;
;	Nothing 							;
;									;
;	No Global data affected 					;
;	Global procedures called: flush 				;
;	What registers are changed					;
;-----------------------------------------------------------------------;
	public	mosfun0d
	assume	cs:mos,ds:grp,ss:tcb,es:nothing
mosfun0d:
	push	ds
	call	noswitch
	callmos2 flush		; Let Jim do it!

; invalidate bdb for each floppy drive

	mov	cx,[scbbdbpf]
mosf0d1:
	jcxz	mosf0d3
	push	cx
	mov	ds,cx
	assume	ds:bdb
	mov	ds,[bdbreal]

; determine if media is removeable

	mov	dl,[bdbunit]	; dl = unit within block device driver
	mov	dh,[bdbid]	; dh = drive number
	lds	si,[bdbdrvr]
	assume	ds:nothing
	test	word ptr [si+4],0800h ; not removeable if
	jz	mosf0d2 	; device doesn't support this call
	mov	al,15
	mov	ah,00h		; bit 7 clear for block device
	callmos2 devchk
	test	ah,02h
	jnz	mosf0d2 	; return status indicates not removeable
	pop	ds		; recover bdb segment
	assume	ds:bdb
	push	ds
	callmos2 invbdb 	; else invalidate all buffers for this bdb

; note a possible c error return here is ignored
;    it occurs if somebody else hasn't dealt with a critical error while
;    flushing to this volume, and this user chose fail or ignore from
;    the critical error box

mosf0d2:
	pop	ds
	mov	cx,[bdbnext]
	jmp	mosf0d1        
mosf0d3:
	call	okswitch
	pop	ds
	ret

	subttl	mosfun0e - Select Disk
	page
;-----------------------------------------------------------------------;
; Select the specified drive.						;
; The total number of drives (diskette and fixed) is returned in AL.	;
;									;
;  On Entry:								;
;	TDL = Drive number (0=A, 1=B, etc.)				;
;									;
;  On Exit:								;
;	TAL = Total number of drives					;
;									;
;	Global data affected: tcbcdriv, tcbcdbpc			;
;	No Global procedures called					;
;-----------------------------------------------------------------------;
	public	mosfun0e
	assume	cs:mos,ds:grp,ss:tcb,es:nothing
mosfun0e:
	push	ds
	push	dx
	call	maxdrive	; get maximum drive			PTR176
	mov	[TAL],al	; Set # of drives
	mov	al,[TDL]	; Get drive
	callmos2 findbdb	; find the BDB for the drive
	jc	mosf0eb 	; if none found
	mov	ds,cx		; returns cdb pointer in cx
	assume	ds:cdb
	mov	al,[TDL]	; get drive again
	mov	byte ptr [tcbcdriv],al	; update current drive
	mov	[tcbcdbpc],ds		; Also update pointer to default CDB
mosf0eb:
	pop	dx
	pop	ds
	ret

; MAXDRIV returns maximum drive for task
; returns SVBDRIVS or max(ALIASES)

	assume	ds:grp
maxdrive:	; Return maximum drive in AL				PTR176
	mov	al,[scbdrivs]	; initialize max drive			|
	mov	dx,ss		; to test for OUR alias
	mov	cx,[scbbdbpf]	; first bdb
maxdrvlp:
	jcxz	maxdrvxit	; test end of device chain
	mov	ds,cx
	assume	ds:bdb
	mov	cx,[bdbnext]	
	cmp	[bdbalias],0	; is it an alias
	je	maxdrvlp
	cmp	dx,[bdbtask]	; is it ours
	jne	maxdrvlp
	cmp	al,[bdbid]	; greater than current?
	ja	maxdrvlp
	mov	al,[bdbid]	; yes so get the id
	inc	al		; and bump to count
	jmp	maxdrvlp
maxdrvxit:
	ret			;					PTR176

	subttl	mosfun19 - Current Disk
	page
;-----------------------------------------------------------------------;
; Determine the current default drive.					;
;									;
;  On Entry:								;
;	Nothing 							;
;									;
;  On Exit:								;
;	TAL = Current default drive (0=A, 1=B, etc.)			;
;									;
;	No Global data affected 					;
;	No Global procedures called					;
;-----------------------------------------------------------------------;
	public	mosfun19
	assume	cs:mos,ds:grp,ss:tcb,es:nothing
mosfun19:
	mov	al,[tcbcdriv]	; Get current drive for this task
	mov	[TAL],al	; Return drive to user
	ret

	subttl	mosfun1B - Allocation Table Info
	page
;-----------------------------------------------------------------------;
; Return information about the allocation table for the default drive.	;
;									;
;  On Entry:								;
;	Nothing 							;
;									;
;  On Exit:								;
;	TDS:TBX -> Media descriptor byte for the default drive		;
;	TDX = Number of allocation units				;
;	TAL = Number of sectors/allocation unit 			;
;	TCX = Size of physical sector					;
;									;
;	No Global data affected 					;
;	Global procedures called					;
;-----------------------------------------------------------------------;
	assume	cs:mos,ds:grp,ss:tcb,es:nothing
mosfun1B:
	mov	al,[tcbcdriv]
fun1B1:
	call	noswitch
	mov	[TAL],0ffh
	callmos2 finddrv
	jc	mosf1cb
	assume	ds:bdb
	mov	al,[bdbcsiz]	; sectors / cluster
	mov	[TAL],al
	mov	cx,[bdbssiz]	; bytes / sector
	mov	[TCX],cx
	mov	dx,[bdbcnum]
	sub	dx,2
	mov	[TDX],dx	; number of clusters on disk
	mov	[TDS],ds		;jrbr
	mov	[TBX],offset bdbmdia	;jrbr
	xor	al,al
mosf1cb:
	mov	[tcberrcod],al	; no extended error
	call	okswitch
	ret

	subttl	mosfun1C - Allocation info for drive
	page
;-----------------------------------------------------------------------;
; Return information about the allocation table for the default drive.	;
;									;
;  On Entry:								;
;	TDL = Driver number (0=A, 1=B, etc.)				;
;									;
;  On Exit:								;
;	TDS:TBX -> Media descriptor byte for drive in DL		;
;	TDX = Number of allocation units				;
;	TAL = Number of sectors/allocation unit 			;
;	TCX = Size of physical sector					;
;									;
;	Global data affected						;
;	Global procedures called					;
;	What registers are changed					;
;-----------------------------------------------------------------------;
	public	mosfun1C
	assume	cs:mos,ds:grp,ss:tcb,es:nothing
mosfun1C:
	mov	al,[TDL]
	dec	al
	jns	fun1C1
	jmp	mosfun1B	; Return info for default drive
fun1C1:
	jmp	fun1B1		; Return allocaion info for this drive

	subttl	mosfun1f - Get DPB for default drive
	page
;-----------------------------------------------------------------------;
; Get DPB for default drive						;
;									;
;  On Entry:								;
;									;
;  On Exit:								;
;	TDS:TBX points to DPB for default drive 			;
;									;
;	No global data affected 					;
;	Jumps into mosfun32						;
;	Changes al							;
;-----------------------------------------------------------------------;
	public	mosfun1f
	assume	cs:mos,ds:grp,ss:tcb,es:nothing
mosfun1f proc
	mov	[TAL],0FFh	; preset TAL for error
	mov	al,[tcbcdriv]	; get current drive number
	jmp	entry1f 	; in mosfun32
mosfun1f endp

	subttl	mosfun25 - Set interrupt vector
	page
;-----------------------------------------------------------------------;
; Sets the interrupt vector table for the interrupt number		;
;									;
;  On Entry:								;
;	TDS:TDX -> Interrupt handling routine				;
;	TAL = interrupt number						;
;									;
;  On Exit:								;
;	Nothing, vector set (regrab table updated for int8,9)		;
;									;
;	No Global data affected 					;
;	Global procedures called					;
;-----------------------------------------------------------------------;
	public	mosfun25
	assume	cs:mos,ds:grp,ss:tcb,es:nothing
mosfun25:
	mov	bl,[TAL]	; Get interrupt number
	xor	bh,bh
	shl	bx,1		; Calc offset for vector ( *4)
	shl	bx,1
	push	ds
	MGetZERO ds
	mov	ax,[TDX]	; Get users offset
	cli
	mov	[bx],ax 	; Set offset for vector
	mov	ax,[TDS]	; Get users segment
	mov	[bx+2],ax	; Set segment for vector
	pop	ds
	assume	ds:grp
	test	[scbmmfea],04h	; is ivtable supported?
	jnz	fun25c
	cmp	bx,8*4
	jne	fun25b
	mov	bx,offset [regrab8_data]  ; when the lidt scheme is not supported
	jmp	short fun25a		          ; then must call the re-grab logic to
fun25b: 			          ; maintain control
	cmp	bx,9*4
	jne	fun25c
	mov	bx,offset [regrab9_data]
fun25a:
	call	grab_back
fun25c:
	sti
	ret

	subttl	mosfun26 - Create new Program Segment
	page
;-----------------------------------------------------------------------;
; Creates new program segment						;
; The entire 100H area at location 0 in the current PSP is copied into	;
; location 0 in the new PSP.  The memory size info at location 6 in the ;
; new PSP is updated and the current termination, CTRL-Break exit and	;
; critical error addresses from interrupt vector table entries for	;
; interrupts 22H, 23H, and 24H are saved in the new PSP starting at	;
; 0aH.	They are restored from this area when the program terminates.	;
; The PSP handle table pointer is also updated to reflect the segment	;
; of the new PSP.							;
;									;
;  On Entry:								;
;	TDX = Segment number for new PSP				;
;									;
;  On Exit:								;
;	Nothing, new PSP created.					;
;									;
;	No Global data affected 					;
;	No Global procedures called					;
;	What registers are changed					;
;-----------------------------------------------------------------------;
	public	mosfun26
	assume	cs:mos,ds:grp,ss:tcb,es:nothing
mosfun26:

; Copy from current PSP to new PSP

	mov	es,[TDX]	; Get new PSP address
	assume	es:pspseg
	push	ds
	mov	ds,[tcbpsp]	; Get current PSP address
	xor	si,si
	xor	di,di
	mov	cx,100h/2
	rep movsw
	pop	ds

; Put in far call to MOS function dispatcher.

	mov	[PSPcall],09ah			; op code for far call
	mov	word ptr [PSPcall+3], 0f01dh
	mov	word ptr [PSPcall+1], 0fef0h	; far call to 0:C0 (default)

; Now update the memory size info.

	mov	ax,[TDX]		; Calc address difference
	mov	word ptr [PSPpntr+2],ax ; Set PSP handle table pointer
	mov	word ptr [PSPpntr],18h	; Make sure you also set offset

; Save INTs 22H, 23H and 24H in PSP starting at 0AH

	push	ds
	cld
	MGetZERO ds
	mov	si,22H*4		; Offset to start of vectors
	mov	di,offset PSPtrmv	; Save space for vectors in PSP
	mov	cx,3*2			; Move 3 vectors
	rep movsw
	pop	ds
	ret

	subttl	mosfun29 - Parse filename
	page
;-----------------------------------------------------------------------;
; Parses the specifed filename						;
;									;
;  On Entry:								;
;	TDS:TSI -> command line to parse				;
;	TES:TDI -> area to put unopened FCB				;
;	TAL = bit value to control parsing				;
;		bit 0=1 leading separators are scanned off		;
;		bit 1=1 set drive FCB only if drive ID found		;
;		bit 2=1 FCB filename only set if filename found 	;
;		bit 3=1 FCB file extension only set if one found	;
;									;
;  On Exit:								;
;	TAL = 00H If no global filename chars found			;
;	    = 01H If global filename chars used 			;
;	    = FFH If drive specifier is invalid 			;
;	TDS:TSI -> 1st character after the file name			;
;	TES:TDI -> 1st byte of formatted FCB				;
;									;
;	Global data affected						;
;	Global procedures called					;
;	What registers are changed					;
;-----------------------------------------------------------------------;
filesep db	32,09,':;,=+'	; Filename separators
seplen	equ	$-filesep
	db	'.<>|/"[]\',0	; Filename terminators (backslash added DAM)
				; Null added, JSM
termlen equ	$-filesep

	public	mosfun29
	assume	cs:mos,ds:grp,ss:tcb,es:nothing
mosfun29:
	push	ds
	mov	ax, cs
	mov	es, ax
	assume	ds:nothing, es:mos

; Init FCB info (clear filename and ext to blanks and set drive to
;	use default)

	cld
	mov	ds,[TES]	; Get pointer to FCB
	mov	si,[TDI]	; "     "	"
	xor	ax,ax
	mov	[si+fcbcb],ax	; Clear Current block field
	mov	[si+fcbrec],ax	; Clear Current block field
	test	[TAL],2 	; Init drive ID?
	jnz	fun29a1 	; No
	mov	[si+fcbdrv],0	; Init drive ID
fun29a1:
	xor	cx,cx
	lea	di,[si+fcbext]	; Start fill at extension
	test	[TAL],4 	; Init filename?
	jnz	fun29a2 	; No
	lea	di,[si+fcbfile] ; Start fill at file
	mov	cx,8
fun29a2:
	test	[TAL],8 	; Init extension?
	jnz	fun29a3 	; No
	add	cx,3		; Include extension to fill with blanks
fun29a3:
	jcxz	fun29a4 	; Do not clear either
	mov	al,20H		; Clear filename to blanks
	push	es
	mov	es,[TES]	; Get FCB pointer
	rep stosb		; Clear to blanks
	pop	es

; Scan off leading separators if needed and specified

fun29a4:
	mov	si,[TSI]	; Get users string pointer
	mov	ds,[TDS]	; "     "	"
	dec	si		; Set up for loop
fun29a:
	test	[TAL],1 	; Scan off leading separators?
	jz	fun29b		; No, just spaces and tabs (1st 2 in table)
	mov	cx,seplen	; Yes, scan off all separators
	mov	al,[si+1]	; MJS is the current char a separator ?
	mov	di,offset filesep	; MJS
	repne	scasb		; MJS
	jne	fun29b		; MJS if not, proceed as before
	inc	si		; MJS if yes, skip to next char
fun29b:
	mov	cx,2		; MJS
	inc	si		; Next char
	mov	al,[si] 	; Get next char from string
	mov	di,offset filesep	; Valid separator table
	repne scasb		; Check for separator
	je	fun29b		; MJS

; Non-separator found, assume start of drive, file, or extension

	mov	[TAL],0 	; Set default of no global characters
	call	f29drv		; Parse out drive ID
	call	f29file 	; Parse out filename
	call	f29ext		; Parse out extension
fun29c:
	mov	al,[si] 	; Get next char
	call	chkend		; Check for end separator
	jz	fun29e		; Separator found
	inc	si		; Search for separator
	jmp	fun29c
fun29e:
	mov	[TSI],si	; Return pointer
	pop	ds
	ret			; End MOSFUN29

	page
;-----------------------------------------------------------------------;
; On entry DS:SI -> current string location				;
;-----------------------------------------------------------------------;
f29drv	proc	near
	cmp	byte ptr [si+1],':'	; Check for drive
	jne	f29drve 		; No, exit
	lodsb			; Get drive letter
	inc	si		; Skip ':'
	call	caps		; Uppercase
	sub	al,'A'		; Calc drive number (A=1, B=2 ...)

; Determine if drive ID is valid

	push	ds
	push	cx
	push	dx
	push	ax
	callmos2 findbdb	; find bdb for this disk
	pop	ax
	pop	dx
	pop	cx
	pop	ds
	jnc	f29a		; if drive found
	mov	[TAL],0ffH	; No, tell user invalid drive
f29a:
	push	es
	mov	es,[TES]		; Get users pointer to FCB
	mov	bx,[TDI]		; "     "	"
	inc	al
	mov	es:[bx+fcbdrv],al	; Set drive in FCB
	pop	es
f29drve:
	ret

f29drv	endp

	page
;-----------------------------------------------------------------------;
; Parse filename from string and put in FCB file space as uppercase	;
; On entry DS:SI -> current string location				;
;-----------------------------------------------------------------------;
f29file proc	near
	mov	cx,8		; Char counter
	mov	es,[TES]	; TCB pointer
	mov	di,[TDI]
	lea	di,[di+fcbfile] ; Set pointer to filename field
f29file2:
	mov	al,[si]
	call	chkend		; Check for terminating character
	jz	f29file1	; Found one
	cmp	al,'?'
	jne	f29f1
	or	[TAL],1 	; Flag user that globals are being used
	jmp	f29f3		; Skip uppercase convert
f29f1:
	cmp	al,'*'
	jne	f29f2
	or	[TAL],1 	; Flag user that globals are being used
	mov	al,'?'
	inc	si		; Update string pointer
	rep stosb		; Fill rest of filename with '?'
	jmp	f29file3	; Thats it
f29f2:
	call	caps
f29f3:
	stosb
	inc	si
	loop	f29file2
f29file1:
	mov	al,[si] 	;JSM
	call	chkend		;JSM is this a terminator character?
	jz	f29file4	;JSM if it's really the end
	inc	si		;JSM
	jmp	f29file1	;JSM if it isn't a terminator, find terminator
f29file4:			;JSM
	jcxz	f29file3	; 8 char filename found exit
	cmp	cx,8		; Any filename found?
	je	f29file3
	mov	al,20H		; Pad rest of string with spaces
	rep stosb
f29file3:
	ret

f29file endp

	page
;-----------------------------------------------------------------------;
; Parse extension from string and put in FCB file space as uppercase	;
; On entry DS:SI -> current string location				;
;-----------------------------------------------------------------------;
f29ext	proc	near
	mov	al,[si] 	; Get next char
	call	chkend		; Check for end separator
	jz	f29ext1 	; Separator found check for '.'
	inc	si		; Search for separator
	jmp	f29ext
f29ext1:
	cmp	al,'.'		; Is this the start of an extension?
	jne	f29exte 	; No, must be the end of the string
	inc	si		; Skip '.'
	mov	cx,3		; Char counter
	mov	es,[TES]	; TCB pointer
	mov	di,[TDI]
	lea	di,[di+fcbext]	; Set pointer to extension field
f29ext3:
	mov	al,[si]
	call	chkend		; Check for terminating character
	jz	f29ext2 	; Found one
	cmp	al,'?'
	jne	f29e1
	or	[TAL],1 	; Flag user that globals are being used
	jmp	f29e3		; Skip uppercase convert
f29e1:
	cmp	al,'*'
	jne	f29e2
	or	[TAL],1 	; Flag user that globals are being used
	mov	al,'?'
	inc	si		; Update string pointer
	rep stosb		; Fill rest of extension with '?'
	jmp	f29exte 	; Thats it
f29e2:
	call	caps
f29e3:
	stosb
	inc	si
	loop	f29ext3
f29ext2:
	jcxz	f29exte 	; 3 char filename found exit
	cmp	cx,3		; Any filename found?
	jne	f29e4
	cmp	byte ptr [si-1],'.' ; If ending in '.' then blank ext.
	jne	f29exte
f29e4:
	mov	al,20H		; Pad rest of string with spaces
	rep stosb
f29exte:
	ret
f29ext	endp

	page
;-----------------------------------------------------------------------;
; Check char in AL for terminating separator.  On exit ZF=1 if the	;
; character is Arnold Schwartzenegger.					;
;-----------------------------------------------------------------------;
chkend	proc	near
	push	cx
	push	di
	push	es
	mov	cx, cs
	mov	es, cx
	cmp	al,26		; Check for control characters
	ja	chk1
	xor	cx,cx		; Set ZF=1
	jmp	chk2
chk1:
	mov	di,offset filesep	; Valid separator table
	mov	cx,termlen
	repne scasb		; Check for separator
chk2:
	pop	es
	pop	di
	pop	cx
	ret
chkend	endp

	subttl	mosfun2A - Get Date
	page
;-----------------------------------------------------------------------;
; Returns the day of the week, year, month, and day.  If the time-of-	;
; day clock rolls over to the next day, the date is adjusted		;
; accordingly, taking into account the number of days in each month and ;
; leap years.								;
;									;
;  On Entry:								;
;	Nothing 							;
;									;
;  On Exit:								;
;	TAL = Day of week (0=Sun - 6=Sat)				;
;	TCX = Year (1980 - 2099)					;
;	TDH = Month (1-12)						;
;	TDL = Day (1-31)						;
;									;
;	Global data affected						;
;	Global procedures called					;
;	What registers are changed					;
;-----------------------------------------------------------------------;
	public	mosfun2A
	assume	cs:mos,ds:grp,ss:tcb,es:nothing
mosfun2A:
	call	getdate
	mov	[TAL],al
	mov	[TCX],cx
	mov	[TDX],dx
	ret

	subttl	mosfun2B - Set Date
	page
;-----------------------------------------------------------------------;
; Sets the date.							;
;									;
;  On Entry:								;
;	TCX = Year (1980 - 2099)					;
;	TDH = Month (1-12)						;
;	TDL = Day (1-31)						;
;									;
;  On Exit:								;
;	TAL = 00H If the date is valid, FFH If the date is invalid	;
;									;
;	Global data affected						;
;	Global procedures called					;
;	What registers are changed					;
;-----------------------------------------------------------------------;
	public	mosfun2B
	assume	cs:mos,ds:grp,ss:tcb,es:nothing

	public  maxdays
maxdays db	31,28,31,30,31,30,31,31,30,31,30,31

lproc	mosfun2b
lstring reqhead,26
lstring datebuffer,6
lbyte leap
	mov	bx,bp
	mov	bp,[bp] 	; Address Task registers
	mov	byte ptr [TAL],0
	mov	ax,[TCX]	; get year
	mov	bp,bx
	cmp	ax,1980
	jb	jDca1
	cmp	ax,2099
	ja	jDca1
	sub	ax,1980
	xor	dx,dx
	mov	bx,4
	div	bx
	mov	di,ax
	mov	BYTE PTR [leap],0
	or	dx,dx
	jnz	Dca2
	mov	BYTE PTR [leap],1
Dca2:
	mov	bx,bp
	mov	bp,[bp]
	mov	al,[TDH]	; get month
	mov	bp,bx
	cmp	al,12
	ja	jDca1
	or	al,al
	jnz	Dca25
jDca1:
	jmp	Dca1
Dca25:
	xor	ah,ah
	mov	si,ax
	dec	si
	mov	bx,offset [maxdays]
	mov	cl,mos:[bx+si]	; get max number of days for month
	cmp	al,2		; is it february?
	jne	Dca3
	add	cl,[leap]	; if feb, add the leap year factor (0 or 1)
Dca3:
	mov	bx,bp
	mov	bp,[bp] 	; Address Task registers
	mov	al,[TDL]	; get days
	mov	bp,bx
	cmp	al,cl
	ja	jDca1
	or	al,al
	jz	jDca1
	push	dx
	mov	ax,di
	xor	dx,dx
	mov	bx,1461
	mul	bx
	pop	dx
	or	dx,dx
	jz	Dca4
	add	ax,366
	dec	dx
	mov	si,ax
	mov	ax,dx
	xor	dx,dx
	mov	bx,365
	mul	bx
	add	ax,si
Dca4:
	mov	bx,bp
	mov	bp,[bp] 	; Address Task registers
	cmp	BYTE PTR [TDH],1
	mov	bp,bx
	je	Dca7
	mov	cx,1
Dca5:	
	mov	si,cx
	dec	si
	mov	bx,offset [maxdays]
	mov	bl,mos:[bx+si]	; get max number of days for month
	cmp	cl,2		; is it february?
	jne	Dca6
	add	bl,[leap]	; if feb, add the leap year factor (0 or 1)
Dca6:
	xor	bh,bh
	add	ax,bx
	inc	cx
	mov	bx,bp
	mov	bp,[bp] 	; Address Task registers
	cmp	cl,[TDH]
	mov	bp,bx
	jne	Dca5
Dca7:
	mov	bx,bp
	mov	bp,[bp] 	; Address Task registers
	mov	cl,[TDL]	; get days
	mov	bp,bx
	xor	ch,ch
	dec	cx
	add	ax,cx		; ax is now day count
	push	ax
	mov	byte ptr [reqhead],26	; set rh length
	mov	byte ptr [reqhead+2],4	; input read from mosddclk
	lea	bx,[datebuffer]
	mov	word ptr [reqhead+14],bx	; set transfer address
	mov	ax,ss
	mov	word ptr [reqhead+16],ax
	call	callclk
	pop	ax
	mov	word ptr [datebuffer],ax
	mov	byte ptr [reqhead+2],8		; write to mosddclk
	call	callclk
	jmp	Dca9

callclk proc	near
	push	ds
	lds	si,[scbstdclk]
	mov	bx, ss		; ES=SS
	mov	es, bx
	lea	bx,[reqhead]
	mov	ah,80h
	xor	cx,cx
	callmos2 todriver	; call the clock driver
	pop	ds
	ret
callclk endp

Dca1:
	mov	bx,bp
	mov	bp,[bp] 	; Address Task registers
	mov	byte ptr [TAL],0ffh	; invalid date
	mov	bp,bx
Dca9:

lundef reqhead
lundef datebuffer
lundef leap
lendp	mosfun2b

	subttl	mosfun2C - Get Time
	page
;-----------------------------------------------------------------------;
; Returns the time - hours, minutes, seconds and hundredths of a second ;
;									;
;  On Entry:								;
;	Nothing 							;
;									;
;  On Exit:								;
;	TCH = Hours (0-23)						;
;	TCL = Minutes (0-59)						;
;	TDH = Seconds (0-59)						;
;	TDL = Hundredths (0-99) 					;
;									;
;	Global data affected						;
;	Global procedures called					;
;	What registers are changed					;
;-----------------------------------------------------------------------;
	public	mosfun2C
	assume	cs:mos,ds:grp,ss:tcb,es:nothing
mosfun2C:
	call	gettime
	mov	[TCX],cx
	mov	[TDX],dx
	ret

	subttl	mosfun2D - Set Time
	page
;-----------------------------------------------------------------------;
; Set the time								;
;									;
;  On Entry:								;
;	TCH = Hours (0-23)						;
;	TCL = Minutes (0-59)						;
;	TDH = Seconds (0-59)						;
;	TDL = Hundredths (0-99) 					;
;									;
;  On Exit:								;
;	TAL = 00H If the time is valid, FFH If the time is invalid	;
;									;
;	Global data affected						;
;	Global procedures called					;
;	What registers are changed					;
;-----------------------------------------------------------------------;
	public	mosfun2D
	assume	cs:mos,ds:grp,ss:tcb,es:nothing

lproc	mosfun2D
lstring reqhead,26
lstring datebuffer,6
	mov	bx,bp
	mov	bp,[bp] 	; Address Task registers
	mov	byte ptr [TAL],0
	cmp	byte ptr [TCH],23
	ja	Tc1
	cmp	byte ptr [TCL],59
	ja	Tc1
	cmp	byte ptr [TDH],59
	ja	Tc1
	cmp	byte ptr [TDL],99
	jna	Tc2
Tc1:
	mov	byte ptr [TAL],0ffh
	mov	bp,bx
	jmp	Tc3
Tc2:
	mov	bp,bx
	mov	byte ptr [reqhead],26	; set rh length
	mov	byte ptr [reqhead+2],4	; input read from mosddclk
	lea	bx,[datebuffer]
	mov	word ptr [reqhead+14],bx	; set transfer address
	mov	ax,ss
	mov	word ptr [reqhead+16],ax
	call	callclk
	push	bp
	mov	bp,[bp]
	mov	ax,word ptr [TCL]
	mov	bx,word ptr [TDL]
	pop	bp
	mov	word ptr [datebuffer+2],ax
	mov	word ptr [datebuffer+4],bx
	mov	byte ptr [reqhead+2],8		; write to mosddclk
	call	callclk
Tc3:

lundef reqhead
lundef datebuffer
lendp	mosfun2D

	subttl	mosfun2E - Set/Reset Verify switch
	page
;-----------------------------------------------------------------------;
; Sets the verify switch.						;
;									;
;  On Entry:								;
;	TAL = 00H to set verify off, 01H to set verify on		;
;									;
;  On Exit:								;
;	Nothing 							;
;									;
;	Global data affected: tcbvflg					;
;	No Global procedures called					;
;	What registers are changed					;
;-----------------------------------------------------------------------;
	public	mosfun2E
	assume	cs:mos,ds:grp,ss:tcb,es:nothing
mosfun2E:
	mov	al,[TAL]
	mov	[tcbvflg],al	; Tasks verify flag
	ret

	subttl	mosfun30 - Get DOS version Number
	page
;-----------------------------------------------------------------------;
; Returns the DOS version number (for compatibility)			;
;									;
;  On Entry:								;
;	If TAX=TBX=TCX=TDX then return MOS version else return DOS ver. ;
;									;
;  On Exit:								;
;	TAL = Major version number					;
;	TAH = Minor version number					;
;	TBX = 0000H (who the hell knows why, IBM)	NOT done by MOS ;
;	TCX = 0000H "   "	"       "		"       "	;
;									;
;	If MOS version returned BX = type code (beta or special or etc) ;
;									;
;	No Global data affected 					;
;	No Global procedures called					;
;-----------------------------------------------------------------------;
	public	mosfun30, mosfunxx
	assume	cs:mos,ds:grp,ss:tcb,es:nothing
mosfun30:
	mov	ax,[TAX]	; Check which version wanted
	cmp	ax,[TBX]
	jne	mosf30a
	cmp	ax,[TDX]
	jne	mosf30a
	cmp	ax,[TCX]
	jne	mosf30a
	mov	ax,[scbversn+2] ; Get MOS version
	mov	bx,[scbversn+4] ; Get type code
	mov	[TBX],bx	; Return to user
	jmp	mosf30b
mosf30a:
	mov	ax,[tcbversn]	; Get DOS (not MOS) version
mosf30b:
	mov	[TAX],ax	; Return to user
mosfunxx:
	ret

	subttl	mosfun31 - Terminate Process and Remain Resident
	page
;-----------------------------------------------------------------------;
; Terminates the current process and shrinks the current memory block	;
; down to the specified size.						;
; Files opened by the process are not closed.				;
;									;
;  On Entry:								;
;	TAL = Return code						;
;	TDX = Memory size in paragraphs 				;
;									;
;  On Exit:								;
;	Nothing 							;
;									;
;	Global data affected						;
;	Global procedures called					;
;	What registers are changed					;
;-----------------------------------------------------------------------;
	public	mosfun31
	assume	cs:mos,ds:grp,ss:tcb,es:nothing
mosfun31:
	mov	bx,[TDX]		; get requested resident module size
	mov	[TCX],bx		; Pass back address to EXEC caller
	mov	cx,[tcbpsp]		; get current psp
	mov	si,cx			; save for later
	dec	cx
	mov	es,cx			; back up to address mcb header
	assume	es:mbseg
	mov	di,[mbsize]
	xif di b bx else fun31a		; if available >= request then
	add	cx,di			; skip on to the 4a call - all is well
	inc	cx			; else, check next mcb
	mov	es,cx
	xif si == [mbowner] else fun31a	; if owned by the module now
	mov	bx,di			; terminating, modify their request
						  ; else, let the 4a call error out
fun31a:
	mov	es,si
	mov	ah,4aH			; Shrink allocation down
	domos
	xif flags == cy else fun31b
	mov	ax,'13'
	jmp	funerr
fun31b:
	mov	ax,es
	dec	ax			; MCB for the PSP
	mov	es,ax
	assume	es:mbseg
	mov	bx,[mbowner]		; owner of MCB (PSP address)
	add	bx,[mbsize]		; length of the block in paragraphs
	inc	ax			; back to PSP
	mov	es,ax
	assume	es:PSPseg
	mov	[PSPmem],bx		; set the end of allocation field
	mov	al,[TAL]
	mov	ah,3			; Fun31 termination code for WAIT
	mov	[tcbretc],ax
	jmp	fun00b			; Continue with normal termination 

	subttl	mosfun32 - Get DPB
	page
;-----------------------------------------------------------------------;
; Get DPB for a drive.							;
; Has entry point for function 1f, get DPB for default drive.		;
;									;
;  On Entry:								;
;	TDL contains disk drive number ( 0 for default, 1 for A, etc.)	;
;  On Exit:								;
;	TAL 0FFh if an error						;
;	if no error,							;
;	TAL is 0							;
;	TDS:TBX -> DPB for drive					;
;									;
;	No Global data affected 					;
;	Calls finddrv							;
;	Changes al							;
;-----------------------------------------------------------------------;
	public	mosfun32
	assume	cs:mos,ds:grp,ss:tcb,es:nothing
mosfun32:
	mov	[TAL],0ffh		; preset error
	mov	al,[TDL]
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
	mov	[TDS],ds		; pointing to dpb portion of bdb
	mov	[TBX],offset bdbdpb
	mov	[TAL],0
	mov	[tcberrcod],0
mosf32b:
	call	okswitch
	ret

	subttl	mosfun33 - CTRL-Break check
	page
;-----------------------------------------------------------------------;
; Set or get the state of the BREAK (CTRL-Break checking)		;
;									;
;  On Entry:								;
;	TAL = 00H To request current state, 01H to set current state	;
;		(Note: DOS also has a fun 2)				;
;	TDL = 00H To set BREAK off, 01H to set BREAK on 		;
;									;
;  On Exit:								;
;	TDL = 00H if BREAK off, 01H if BREAK on 			;
;									;
;	Global data affected: tcbbrk					;
;	No Global procedures called					;
;-----------------------------------------------------------------------;
	public	mosfun33
	assume	cs:mos,ds:grp,ss:tcb,es:nothing
mosfun33:
	mov	al,[TAL]	; Get request command
	or	al,al		; Get Break state?
	jnz	fun33a
	mov	al,[tcbbrk]	; Get break flag
	mov	[TDL],al
	jmp	fun33end

; Set break state

fun33a:
	cmp	al,2		; SAH if function is < 2 skip error
	jbe	fun33b
	mov	[TAL],0ffh	; SAH return error has ffh
	ret
fun33b:
	mov	al,[TDL]	; Get setting
	and	al,1		; Only except 0 or 1
	mov	[tcbbrk],al
fun33end:
	ret

	subttl	mosfun35 - Get interrupt vector
	page
;-----------------------------------------------------------------------;
; Gets the interrupt vector table for the interrupt number		;
;									;
;  On Entry:								;
;	TAL = interrupt number						;
;									;
;  On Exit:								;
;	TES:TBX -> Interrupt handling routine				;
;									;
;	No Global data affected 					;
;	No Global procedures called					;
;-----------------------------------------------------------------------;
	public	mosfun35
	assume	cs:mos,ds:grp,ss:tcb,es:nothing
mosfun35:
	mov	bl,[TAL]	; Get interrupt number
	xor	bh,bh
	shl	bx,1		; Calc offset for vector ( *4)
	shl	bx,1
	push	ds
	MGetZERO ds
mfun35ex:
	cli
	mov	ax,[bx] 	; Get offset for vector
	mov	[TBX],ax	; Return to user
	mov	ax,[bx+2]	; Get segment for vector
	mov	[TES],ax	; Return to user
	sti
	pop	ds
	ret

	subttl	mosfun36 - Get disk free space
	page
;-----------------------------------------------------------------------;
; Returns the disk free space (available clusters, clusters/drive,	;
; bytes/sector								;
;									;
;  On Entry:								;
;	TDL = Drive (0=Default, 1=A, etc.)				;
;									;
;  On Exit:								;
;	TBX = Available clusters					;
;	TDX = Clusters/drive						;
;	TCX = Bytes/sector						;
;	TAX = FFFFH if drive invalid or Sector/cluster			;
;									;
;	Global data affected						;
;	Global procedures called					;
;	What registers are changed					;
;-----------------------------------------------------------------------;
	public	mosfun36
	assume	cs:mos,ds:grp,ss:tcb,es:nothing
mosfun36:
	mov	[TAX],0ffffh	; preset error
	mov	al,[TDL]
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
	jmp	mosf36x 	; ne if # free clusters is valid
	xor	dx,dx		; number of unused clusters so far
	xor	bx,bx		; current fat sector
	mov	cx,[bdbcnum]
	sub	cx,2		; JSM 03/16/87
	cmp	cx,4096-10-2	; JSM 03/16/87
	jbe	mosf36e 	; a if 16-bit fat entries (too big for 12-bit)
mosf36b:
	call	mosf36rf
	assume	es:dbb
	mov	si,[bdbssiz]	; size of sector
	lea	di,[dbbbuf]	; current offset in fat sector buffer
	xor	ax,ax
	or	bx,bx		; SAH
	jnz	mosf36c 	; SAH if first fat sector add 4 to 
	add	di,4		; SAH to offset
	sub	si,4		; SAH
mosf36c:
	jcxz	mosf36xx	; SAH
	scasw
	jne	mosf36d
	inc	dx		; 1 more unused if 0 in fat entry
mosf36d:
	dec	si
	dec	si
	loopnz	mosf36c
	jnz	mosf36x 	; nz if cx = 0 and finished
	inc	bx		; else finished with this sector, get next
	jmp	mosf36b
mosf36xx:			; SAH
	jmp	mosf36x 	; SAH

; fat contains 12-bit entries

mosf36e:
	call	mosf36rf
	assume	es:dbb
	xor	di,di

; this is for the low-order 12-bits of a 24-bit fat entry pair

mosf36f:
	mov	al,es:[dbbbuf+di]
	inc	di
	cmp	di,[bdbssiz]
	jb	mosf36g 	; b if don't need to read next fat sector
	inc	bx		; next sector
	mov	di,ax		; save low 8-bits of entry
	call	mosf36rf
	mov	ax,di
	xor	di,di
mosf36g:
	mov	ah,es:[dbbbuf+di]
	test	ax,0fffh
	jnz	mosf36h 	; nz if entry is used
	inc	dx		; else one more unused
mosf36h:
	dec	cx		; and one more checked
	jz	mosf36x 	; z if all checked
	mov	al,ah		; preparing for next 12-bits of 24-bit pair
	inc	di
	cmp	di,[bdbssiz]
	jb	mosf36i 	; b if don't need next sector
	inc	bx
	mov	di,ax
	call	mosf36rf
	mov	ax,di
	xor	di,di
mosf36i:
	mov	ah,es:[dbbbuf+di] ; high 8-bits of second 12-bits of pair
	test	ax,0fff0h
	jnz	mosf36j 	; nz if used
	inc	dx		; else one more unused
mosf36j:
	dec	cx		; and one more checked
	jz	mosf36x 	; z if all checked
	inc	di		; bump to next 24-bit pair
	cmp	di,[bdbssiz]
	jb	mosf36f 	; read next fat sector if needed
	inc	bx
	mov	di,ax
	call	mosf36rf
	mov	ax,di
	xor	di,di
	jmp	mosf36f
mosf36x:
	mov	al,[bdbcsiz]	; number of sectors per cluster
	xor	ah,ah
	mov	[TAX],ax
	mov	cx,dx
	callmos2 setfree	; set free clusters on disk
	mov	[bdbcfree],dx	; number of free clusters is valid now
	mov	[TBX],dx	; number of free clusters
	mov	cx,[bdbssiz]
	mov	[TCX],cx	; sector size in bytes
	mov	dx,[bdbcnum]
	sub	dx,2
	mov	[TDX],dx	; total clusters on disk
	xor	al,al		; no extended error
mosf36y:
	mov	[tcberrcod],al
	call	okswitch
	ret

mosf36rf proc	near
	callmos2 rdfat
	jc	$+3
	ret
	pop	dx
	jmp	mosf36y
mosf36rf endp

	subttl	mosfun37 - Get/set switch character
	page

;-----------------------------------------------------------------------;
; Gets and sets the command line switch character.  MS-DOS allows two	;
; different command line switches: slash (/) and dash (-).  The slash	;
; was the original command line parameter separator character in DOS 1. ;
; When they tried to make DOS into UNIX, they decided that they liked	;
; slashes between file specs, and dashes as parameter separators, so	;
; this undocumented call was added to switch between old DOS (/ on	;
; command line, \ between file names), and UNIX (- on command line, /	;
; between file names).							;
;									;
; This call only supports Get Switch character function, and it always	;
; returns / as the command line separator character.			;
;									;
;  On Entry:								;
;	TAL = 0 if this is a Get Switchchar call			;
;	TAL = 1 if this is a Set Switchchar call			;
;	TDL = '-' (2Dh) or						;
;	      '/' (2Fh) if this is a Set Switchchar call		;
;									;
;  On Exit:								;
;	TDL = New Switch Character					;
;									;
;	No global data affected 					;
;	No global procedures called					;
;	ax changed							;
;-----------------------------------------------------------------------;
	public	mosfun37
	assume	cs:mos,ds:grp,ss:tcb,es:nothing
mosfun37:
	mov	al,[TAL]		; get function code
	or	al,al			; only allow subfunction 0
	jz	mosfun37a		; if no error in calling
	mov	ax, INVALID_FUNCTION
	jmp	short mosfun37e
mosfun37a:
	mov	[TDL],'/'	; say "SWITCHCHAR is /"
mosfun37e:
	cbw			; make al into a word
	callmos2 moserror	; set error codes appropriately
	ret

	subttl	mosfun38 - Get/Set country info
	page
;-----------------------------------------------------------------------;
; Gets and sets country dependent information				;
;									;
;  On Entry:								;
;	TDS:TDX -> buffer where info will be returned			;
;	TAL = 00H To get current country info				;
;									;
;	SEE MANUAL FOR THIS CRAP!!!					;
;									;
;  On Exit:								;
;									;
;	Global data affected						;
;	Global procedures called					;
;	What registers are changed					;
;-----------------------------------------------------------------------;
	; Case conversion routine
	; AL= char to convert to uppercase

casecon proc	far
	call	caps
	ret
casecon endp

	public	mosfun38
	assume	cs:mos,ds:grp,ss:tcb,es:nothing
mosfun38:
	xor	ah,ah		; word sized country code
	mov	al,[TAL]	; requested country code
	cmp	al,0FFh 	; code in bx?
	jb	mf3820		; if already have code
	mov	ax,[TBX]	; word sized country code
mf3820:
	cmp	[TDX],0FFFFh	; get or set?
	je	mf38100 	; if set

; get country information

	or	ax,ax			; get info for current code?
	jnz	mf3830			; if for specified code
	mov	ax,[scbcntry]		; get current code		      ; 042888
	or	ax,ax			; is current code 0?
	jne	mf3830			; if not 0
	mov	si,offset USAinfo	; if 0, return US info
	jmp	short mf3860
mf3830:
	call	fndccode
	jc	mf38115
mf3860:
	mov	[TBX],ax		; country code requested
	mov	[TAX],ax		; to ax also (just like DOS)	      ; 042888
	inc	si
	inc	si			; start one word further
	cld
	mov	es,[TDS]
	mov	di,[TDX]
	mov	bl,[si+9]		; get format bits
	call	mf38x2			; extract date format
	stosb				; 2nd byte of date format
	movsw				; currency symbols
	movsw
	stosb
	movsb				; Thousands separator
	stosb
	movsb				; Decimal separator
	stosb
	movsb				; Date separator
	stosb
	movsb				; Time separator
	stosb
	call	mf38x2			; Currency format
	call	mf38x2			; Currency significant digits
	call	mf38x2			; Time format
	mov	ax,offset mos:casecon
	stosw
	mov	ax,cs
	stosw
	movsb				; Data list separator
	xor	ax,ax
;
; Following changes are necessary for SKPLUS, SKPLUS places this information
; on its stack and requires that the lenght to exactly match, Under DOS 3.2
; we can only fill out 32 bytes, if planning to change the following lines of
; code, please run SKPLUS to make sure that its requirements are still in
; effect
;
; Update Feb 22, 1990 by SAH
;
	mov	cx,9			; fill out to 32 bytes
	cmp	word ptr [TCBVERSN],1403h	; is this for DOS 3.20
	je	NotDOS33
	add	cx,2			; make it 34 bytes for DOS 3.30 support
NotDOS33:
;
	rep	stosb



; End of replacement 05/16/88

	xor	ax,ax			; success return code
	jmp	short mf38x		; return to caller

; Set country code

mf38100:
	or	ax,ax			; did they want to set country 0?
	jz	mf38120 		; yes, jump
	call	fndccode
	jnc	mf38120
mf38115:
	mov	ax, FILE_NOT_FOUND
	jmp	short mf38x
mf38120:
	mov	[scbcntry],ax		; set new country code		      ; 042888
	xor	ax,ax
mf38x:
	callmos2 moserror
	ret

mf38x2	proc	near
	mov	al,bl
	and	al,3
	stosb
	shr	bl,1
	shr	bl,1
	xor	ax,ax
	ret
mf38x2	endp

;-----------------------------------------------------------------------;
;	Find country code in ax.  Changes si and di.			;
;	Returns CY set if code not found, CY clear if code found.	;
;	If CY clear, returns pointer to country info in si.		;
;-----------------------------------------------------------------------;

fndccode proc
	mov	si,offset [USAinfo]	; first country in table
findc10:
	mov	di,[si] 		; get next country code
	or	di,di			; last code?
	jz	findc20 		; if end of the table
	cmp	ax,di			; is this the right country code?
	je	findc30 		; yes, return "OK"
	add	si,USAlen		; no, check next country
	jmp	findc10
findc20:
	stc
findc30:
	ret
fndccode endp

	subttl	mosfun48 - Allocate Memory
	page
;-----------------------------------------------------------------------;
; Allocates the requested number of paragraphs of memory.		;
;									;
;  On Entry:								;
;	TBX = Number of paragraphs					;
;									;
;  On Exit:								;
;	TAX:0 -> Allocated block or error code if CY			;
;	TBX = size of largest block available if fail			;
;									;
;  Errors:								;
;	MEM_BLOCK_DESTROYED						;
;	INSUFFICIENT_MEMORY						;
;									;
;	No Global data affected 					;
;	No Global procedures called					;
;	No registers are changed					;
;-----------------------------------------------------------------------;
	public	mosfun48
	assume	cs:mos,ds:grp,ss:tcb,es:nothing
mosfun48:

; AX will hold the block size needed
; BX will hold the segment address of the current block
; CX will hold the largest available block size

	xor	bx,bx		; No MB address to check
	call	mmsetup 	; Validate MB chain
	assume	es:grp,ds:nothing
	jnc	fun48f
	callmos2 moserror	; Error in block chain
	jmp	fun48end
fun48f:
	call	blkmrch 	;120588
	xor	cx,cx		; Start with 0 block size available
	mov	ax,[TBX]	; Get # para's needed

if	CODE286
	test	[scbmmfea],08h	;030788 declare calls supported?
	jz	fun48dc1	;030788 no, skip
	or	al,7		;022688 make (size+1) a multiple of 8
fun48dc1:			;030788
endif
	
	mov	bx,[tcbmbpf]	; Get pointer to 1st memory block in task

; Search for large enough free block

fun48a:
	mov	ds,bx		; Address current MB prefix
	assume	ds:mbseg
	cmp	word ptr [mbowner] ,0	; Is this block free?
	jne	fun48b		; No, try next block

; Check for larger available block size, update if found

	cmp	cx,[mbsize]	; Check for larger size available
	ja	fun48c		; No this is smaller than the last one checked
	mov	cx,[mbsize]	; Yes, update largest available
fun48c:
	cmp	ax,[mbsize]	; Is this block large enough for request?
	ja	fun48b		; No, try next block

; Suitable block found, mark it as used by this caller

	mov	bx,[tcbpsp]	; Get callers PSP address
	mov	[mbowner],bx	; Set current PSP as owner of this MB
	mov	bx,[mbsize]	; Get current size
	mov	[mbsize],ax	; Set new size
	sub	bx,ax		; Calc size left over
	or	bx,bx		; Is this a perfect fit (exact block size)
	jz	fun48e		; Yes, exit
	
; Split off excess size into free block

	dec	bx		; Do not include prefix in size
	mov	cx,ds		; Pointer to current MB prefix
	inc	cx		; Point past current MB prefix
	add	cx,ax		; Point to new block address

if	CODE286
	test	[scbmmfea],08h	;031188  Declare supported?
	jz	fun48nd1	;031188  No, skip
	push	ax		;031188  Do declares
	push	bx		;031188
	push	cx		;031188
	mov	bx,cx		;031188  Declare memory block prefix and data
	mov	cl,0		;031188
	call	dodecl		;031188
	mov	ah,0ch		;032888  Reset "auto" declarations
	call	[scbmmsub]	;032888
	pop	cx		;031188
	pop	bx		;031188
	pop	ax		;031188
fun48nd1:			;031188
endif

	mov	al,[mbtype]	; Get type of current block
	push	ds
	mov	ds,cx		; Address new MB prefix
	mov	[mbtype],al	; Set as type of new block
	mov	[mbsize],bx
	mov	word ptr [mbowner],0	; Set as free block
	pop	ds
	mov	byte ptr [mbtype],'M' ; Set current as NOT last block
	jmp	short fun48e	; All done, exit

; Point to next block if not the last one

fun48b:
	cmp	byte ptr [mbtype],'Z' ; Is this the last block?
	je	fun48d		; Yes, exit with largest available
	inc	bx		; Point past MB itself
	add	bx,[mbsize]	; Point to next block
	jmp	fun48a		; Check next block

; Set exit registers

fun48e:
	mov	ax,ds
	inc	ax		; Point past MB prefix
	mov	[TAX],ax		; Tell user address of block
	and	[TFLAG],NOT CARRY	; Make sure carry cleared
	jmp	short fun48end		; That's it
fun48d:
	mov	[TBX],cx	; Return largest available
	mov	[TAX], INSUFFICIENT_MEMORY
	or	[TFLAG],CARRY	; Set users carry
fun48end:
	push	es		; restore standard segregs
	pop	ds
	assume	ds:grp,es:nothing
	ret

	subttl	mosfun49 - Free Allocated Memory
	page
;-----------------------------------------------------------------------;
; Frees the specified allocted memory					;
;									;
;  On Entry:								;
;	TES = Segment of the block to be returned			;
;									;
;  On Exit:								;
;	TAX = Error code if CY						;
;									;
;  Errors:								;
;	MEM_BLOCK_DESTROYED						;
;	INVALID_MEM_ADDRESS						;
;									;
;	Global data affected						;
;	Global procedures called					;
;	What registers are changed					;
;-----------------------------------------------------------------------;
	public	mosfun49
	assume	cs:mos,ds:grp,ss:tcb,es:nothing
mosfun49:
	xor	bx, bx		; check all memory blocks		890626
	call	mmsetup 	; Validate MB chain
	assume	es:grp,ds:nothing
	jc	fun49end

; DOS doesn't error if freeing a free memory block
				;					|
	mov	bx,[TES]	; Get address of block to free		|
	dec	bx		; Point to prefix			|
	mov	ds,bx		;					|
	assume	ds:mbseg	;					|
	cmp	byte ptr [mbtype],'M'	; Check for valid prefix	|
	je	fun49ok 		; Ok, check next block	|
	cmp	byte ptr [mbtype],'Z'	; If not regular block then must be last
	je	fun49ok
	mov	ax, INVALID_MEM_ADDRESS
	stc
	jmp	fun49end
fun49ok:
	mov	word ptr [mbowner],0	; Set block as free

if	CODE286
	test	[scbmmfea],08h	;032888  Declare supported?
	jz	fun49nd1	;032888  No, skip
	mov	ah,0ch		;032888  Reset "auto" declarations
	call	[scbmmsub]	;032888
fun49nd1:			;032888
endif

	mov	ax,[TES]	; get segment of memory block
	dec	ax
	mov	[TAX],ax	; place it in ax
	xor	ax,ax		; no...errors
fun49end:
	push	es
	pop	ds
	assume	ds:grp
	callmos2 moserror	; Set return code
	ret

	subttl	mosfun4A - Modify Allocated Memory (SETBLOCK)
	page
;-----------------------------------------------------------------------;
; Modifies allocated memory blocks to contain the new specified block	;
; size. 								;
;									;
;  On Entry:								;
;	TES = segment of block						;
;	TBX = New size in paragraphs					;
;									;
;  On Exit:								;
;	TAX = error code if CY						;
;	TBX = maximum possible size if error				;
;									;
;  Errors:								;
;	MEM_BLOCK_DESTROYED						;
;	INVALID_MEM_ADDRESS						;
;	INSUFFICIENT_MEMORY						;
;									;
;	Global data affected						;
;	Global procedures called					;
;	What registers are changed					;
;-----------------------------------------------------------------------;
	public	mosfun4A
	assume	cs:mos,ds:grp,ss:tcb,es:nothing
mosfun4A:
	mov	bx,[TES]			; Get MB address
	call	mmsetup 			; Validate MB chain
	assume	es:grp,ds:nothing
	jnc	fun4a00
	jmp	fun4aend			; Set error code and exit
fun4a00:
	dec	bx				; Point to prefix
	mov	ds,bx
	assume	ds:mbseg
	mov	bx,[TBX]			; Get requested size

if	CODE286
	test	[scbmmfea],08h			;030788 declare calls supported?
	jz	fun4adc1			;030788 no, skip
	or	bl,7				;022688 make (size+1) a multiple of 8
fun4adc1:					;030788
endif

	call	blkmrch 			; Combine any adjacent free blocks
	cmp	bx,[mbsize]			; Is this a shrink or grow?
	ja	fun4agw 			; Grow
	jne	fun4a01
	jmp	fun4aend			; Same size, exit
fun4a01:

; Do block shrink and create free block from excess

	mov	ax,[mbsize]
	mov	[mbsize],bx		; Set new block size
	sub	ax,bx			; Calc left over amount
	dec	ax			; Size not to include prefix of block
	mov	bx,ds			; Address block
	inc	bx			; Point past prefix
	add	bx,[mbsize]		; Point to address for new next block

if	CODE286
	push	cx				;031188  Declare block prefix and data
	push	bx				;031188
	mov	cl,0				;031188
	call	dodecl				;031188
	pop	bx				;031188
	pop	cx				;031188
endif

	mov	cl,[mbtype]		; Get type of current block
	mov	byte ptr [mbtype],'M'	; Set as NOT last block
	mov	ds,bx  			; Address newly freed block
	mov	[mbtype],cl		; Set type to same of current
	mov	word ptr [mbowner],0	; Set block as free
	mov	[mbsize],ax		; Set size
	call	blkmrch 			; Combine any adjacent free blocks
	xor	ax,ax				; Set no errors
	jmp	fun4aend			; Set error code and exit

; Attempt a block grow into above free block (if one exists)

fun4agw:
	cmp	byte ptr [mbtype],'Z' 	; Is this the last block?
	jne	fun4a02	    		; No
	jmp	fun4a1	    		; Yes, cannot grow
fun4a02:
	mov	cx,[mbsize]		; Get size of current block
	mov	ax,ds	    		; Get pointer to current block
	mov	dx,ax	    		; save current block for later
	inc	ax	    		; Point past prefix
	add	ax,[mbsize]		; Point to next block
	mov	ds,ax		 	; Address next block
	cmp	word ptr [mbowner],0	; Is this block free
	jne	jfun4a2   		; Above block not free, can't grow
	inc	cx	  		; include_ header length in block size
	add	cx,[mbsize]		; Calc total size of both blocks
	cmp	bx,cx	  		; Large enough?
	jna	skjfun4a2 		;031188
;
;	The following code is necessary, to be compatible with DOS
;	and applications like SPSS. Dos will combine a block with next
;	free block even if an error occurs
;
	push	ax				
	push	ds		     		
	mov	al,[mbtype]	 	; get free block type
	mov	ds,dx		 	; access previous block
	mov	[mbtype],al		; set previos block type
	mov	[mbsize],cx		; set previos block size
	pop	ds				
	pop	ax  
jfun4a2:					;031188
	jmp	fun4a2				;031188
skjfun4a2:

; Expand current block into above free block

	mov	cx,[mbsize]		; Get size of above free block
	inc	cx	  		; plus header
	mov	dl,[mbtype]		; Save block type 
	mov	ax,[TES]			; Get pointer to growing MB
	dec	ax				; Point to prefix

if	CODE286
	push	bx				;031188  Undeclare block prefix and data
	push	cx				;031188
	mov	bx,ds				;031188
	mov	cl,-1				;031188
	call	dodecl				;031188
	pop	cx				;031188
	pop	bx				;031188
endif

	mov	ds,ax				; Address growing block
	mov	ax,[mbsize]			; Save current size
	mov	[mbsize],bx			; Set new size (as requested)
	sub	bx,ax				; Calc amount of free block used
	sub	cx,bx				; Calc new size of free block
	or	cx,cx				; Any of the block left over?
	jnz	fun4a3				; Yes, adjust left-overs
	push	ds				; Save address of current block
	mov	bx,ds				; Save address of current block
	inc	bx				; Point past prefix
	add	bx,ax				; Point to old next block prefix
	mov	ds,bx				; Address old next block
	mov	dl,[mbtype]			; Get type
	pop	ds				; Address newly grown block
	mov	[mbtype],dl			; Use same type as old block
	jmp	fun4a0				; All of next block used up
fun4a3:
	mov	bx,ds				; Get growing block address
	inc	bx				; Point past prefix
	add	bx,[mbsize]			; Point to new address for free block

if	CODE286
	push	cx				;031188  Declare block prefix and data
	push	bx				;031188
	mov	cl,0				;031188
	call	dodecl				;031188
	pop	bx				;031188
	pop	cx				;031188
endif

	mov	ds,bx			; Address new free block address
	mov	[mbtype],dl		; Set same type as before
	dec	cx			; less header of new free block
	mov	[mbsize],cx		; New smaller size (less growth of other blk)
	mov	word ptr [mbowner],0	; Still free
fun4a0:
	xor	ax,ax			; No errors
	jmp	short fun4aend
fun4a2:
	mov	[TBX],cx		; Return max size above current size
	mov	ax, INSUFFICIENT_MEMORY
	jmp	short fun4aend
fun4a1:
	mov	bx,[mbsize]		; Max size is current size of block
	mov	[TBX],bx			; Return to caller
	mov	ax, INSUFFICIENT_MEMORY
fun4aend:
	or	ax,ax
	jnz	fun4amjs1			; if no error, return segment in ax
	mov	bx,[TES]
	mov	[TAX],bx
fun4amjs1:
	push	es				; restore standard segregs
	pop	ds
	assume	ds:grp,es:nothing
	callmos2 moserror	; Set error code
	ret

	subttl	MMSETUP - Validate MB pointer and MB chain
	page
;-----------------------------------------------------------------------;
; This routine is called by the Memory allocation routines (48,49,4A,58);
; to verify a Memory Block pointer and the MB chain.			;
;									;
;  On Entry:								;
;	BX = Address of MB to check (0 if only check chain)		;
;									;
;  On Exit:								;
;	ES -> grp							;
;	AX = error code if CY						;
;									;
;  Errors:								;
;	MEM_BLOCK_DESTROYED						;
;	INVALID_MEM_ADDRESS						;
;									;
;	No Global data affected 					;
;	No Global procedures called					;
;	AX register changed						;
;-----------------------------------------------------------------------;
	assume	ds:grp,ss:tcb,es:nothing
mmsetup proc	near
	mov	ax, ds		; Free DS by letting ES address GRP.
	mov	es, ax
	assume	es:grp,ds:nothing
	push	bx
	push	ds
	mov	ax,[tcbmbpf]	; Start check at 1st pointer
MBchklp:
	inc	ax		; Point to MB
	cmp	ax,bx		; Is this a valid MB address
	jne	MBchk2
	xor	bx,bx		; Flag that address is valid
MBchk2:
	dec	ax		; Point to prefix
	mov	ds,ax
	assume	ds:mbseg
	cmp	byte ptr [mbtype],'M' ; Check for valid prefix
	je	MBchk3		; Ok, check next block
	cmp	byte ptr [mbtype],'Z' ; If not regular block then must be last
	je	MBchk4
	mov	ax, MEM_BLOCK_DESTROYED		;Chain destroyed
	stc
	jmp	MBchkend
MBchk3:
	inc	ax		; Point past prefix (to block)
	add	ax,[mbsize]	; Point to next block
	jmp	MBchklp
MBchk4:
	xor	ax,ax		; Set 'no error' code
	or	bx,bx		; Specified MB address found?
	jz	MBchkend	; Yes
	mov	ax, INVALID_MEM_ADDRESS
	stc
MBchkend:
	pop	ds
	pop	bx
	ret

	subttl	combmcb - Combine MCB - High Level for terminate and exec
	page
;-----------------------------------------------------------------------;
; This routine is use by terminate and exec for combining free blocks.	;
; This routine was created because DOS does not combine blocks when	;
; doing function 49 (as of QBasic 4.0)					;
;-----------------------------------------------------------------------;
	assume	ds:nothing,es:nothing,ss:tcb
combmcb proc	near
	push	bx
	push	di
	push	ds		; SAH 06/14/88
	push	es
	MGetSCB ds		; SAH 06/14/88
	assume	ds:grp		
	xor	bx,bx		; SAH check memory control blocks
	call	mmsetup 	; SAH
	call	blkmrch 	; SAH combine any free adjacent memory blocks
	pop	es
	pop	ds		; SAH 06/14/88
	pop	di
	pop	bx
	ret
combmcb endp

	subttl	blkmrch - Block Merge (combine free blocks)
	page
;-----------------------------------------------------------------------;
; This routine is called by the Memory allocation routines (49 and 4A)	;
; to combine any adjacent free blocks in the chain.			;
;									;
;  On Entry:								;
;	ES register set-up by MMSETUP to point to GRP.			;
;									;
;  On Exit:								;
;	SS -> TCB							;
;									;
;  Errors:								;
;	None								;
;									;
;	No Global data affected 					;
;	No Global procedures called					;
;-----------------------------------------------------------------------;
	assume	ds:nothing, es:grp, ss:tcb
blkmrch proc	near
	pushf
	push	ax
	push	bx
	push	cx
	push	ds
	mov	ax,[tcbmbpf]			; Start check at 1st pointer
	mov	bx,ax
	inc	bx
	mov	ds,ax				; Address 1st block
	assume	ds:mbseg
	add	bx,[mbsize]			; Point to next block
blklp:
	cmp	byte ptr [mbtype],'Z' 		; Is this the last block?
	je	blkmend 	; Yes
	cmp	word ptr [mbowner],0		; Is this block free
	je	blkm1
	mov	ds,bx				; Point to next MB
blkm0:
	inc	bx				; Point past MB itself
	add	bx,[mbsize]			; Point to next MB
	jmp	blklp

; ds -> free block here

blkm1:
	mov	ax,ds				; Save address of free block
	mov	ds,bx				; Address next block
	cmp	word ptr [mbowner],0		; Is this one free also?
	jne	blkm0				; no..don't combine the blocks

; Adjacent block free now combine

blkm2:
	mov	bx,[mbsize]			; Get size of next block
	mov	cl,[mbtype]			; Use this type (may be last block)

if	CODE286
	push	bx		;031188  Undeclare block prefix and data
	push	cx		;031188
	mov	bx,ds		;031188
	mov	cl,-1		;031188
	call	dodecl		;031188
	pop	cx		;031188
	pop	bx		;031188
endif

	mov	ds,ax		; Address lower MB
	inc	bx		; Upper MB prefix is also free space
	mov	[mbtype],cl	; Use block type of higher block
	add	[mbsize],bx	; Combine the 2 blocks into 1 larger block
	mov	bx,ds		; Current block
	add	bx,[mbsize]	; Point to next block
	inc	bx		; "     "	"
	jmp	blklp		; Continue on with loop
blkmend:
	pop	ds
	pop	cx
	pop	bx
	pop	ax
	popf
	ret
blkmrch endp


if	CODE286
dodecl	proc	near		;060588
	test	[scbmmfea],08h	;060588  Declare supported?
	jz	dodeclx 	;060588  No, skip
	push	ax		;060588
	push	bx		;060588
	push	cx		;060588
	mov	ah,0ah		;060588  Declare or undeclare block prefix
	call	[scbmmsub]	;060588
	pop	cx		;060588
	pop	bx		;060588
	inc	bx		;060588
	mov	ah,0ah		;060588  Declare or undeclare data portion
	call	[scbmmsub]	;060588
	pop	ax		;060588
dodeclx:			;060588
	ret			;060588
dodecl	endp			;060588
endif

	assume	ds:nothing,es:nothing

mmsetup endp

	subttl	mosfun4B - Load or Execute program (EXEC)
	page
;-----------------------------------------------------------------------;
; Allows a program to load into memory and optionally begins execution	;
; of it.								;
;									;
;  On Entry:								;
;	TDS:TDX -> ASCIIZ string with drive, path, and filename 	;
;	TES:TBX -> Parameter block ---------|				;
;	TAL = function value		    |				;
;					    |				;
;				0 dw - segment address of environment	;
;				2 dd -> command line			;
;	Parameter block --->	6 dd -> FCB at 5C in PSP		;
;				A dd -> FCB at 6C in PSP		;
;				E dd - SS:SP for fun 0			;
;				12 dd - CS:IP for fun 0 		;
;									;
;  On Exit:								;
;	TAX = Error code if CY						;
;									;
;  Errors:								;
;	INVALID_FUNCTION						;
;	FILE_NOT_FOUND							;
;	INSUFFICIENT_MEMORY						;
;	INVALID_ENVIRONMENT						;
;									;
;	Global data affected						;
;	Global procedures called					;
;	What registers are changed					;
;									;
;	(1) Determine size of and allocate block for environment	;
;	(2) Allocate block for program (as large as possible)		;
;	(3) If function 0 or 1 create PSP				;
;	(4) Load program with handle calls				;
;	(5) If function 1 set parameter block CS:IP and SS:SP and exit	;
;	(6) Set terminate vector to callers CS:IP			;
;	(7) Turn control over to loaded program 			;
;-----------------------------------------------------------------------;
	assume	cs:mos,ds:grp,ss:tcb,es:nothing

RS_PGM	equ	1		; set if program segment allocated
RS_ENV	equ	2		; set if environment allocated
RS_TRM	equ	4		; set if terminate vector changed
RS_MMB	equ	8		; set if MOSHEMAN block allocated
RS_OPEN equ	16		; SAH set if filename is open

	public	mosfun4b
lproc	mosfun4B
ldword	prmblk			; Pointer to passed parameter block
lstring pathstr,65		; copy of the ds:dx string
lword	workadr 		; Pointer to heap work address
lword	envseg			; Segment address of environment block
lword	pgmseg			; Segment address of program block
lword	psize			; paragraph length of load module (com or exe)
ldword	bsize			; byte length of load module (com or exe)
ldword	lsz			; current size to be loaded
lword	lofs			; current load offset
lword	lseg			; current load segment
lword	flhdl			; File handle save space
lbyte	funnum			; Function number
lbyte	rsflags 		; resources which must be returned
lword	reloc			; Relocation factor for func 3
lword	adjust			; Load location adjustment factor
ldword	ldsize			; actual load size from directory
lword	mempara 		; size of memory in paragraphs
lword   ReturnAX		; value return in AX back to application
lword	CurrentRelo		; Current top of relocation buffer offset
lword	ReloAdjust		; relocation buffer position adjustment

	mov	dx,bp
	mov	bp,[bp] 	; Address CALLers registers

; The following code is used to set offset of 2e and 30 in the
; PSP to callers SS:SP - adjusted for retf in Terminate

	mov	ax,[TAX]	; get function
	cmp	al, 1		; only done for function 0 and 1
	ja	nopspstk	; sorry not today charlie...
	mov	es,[tcbpsp]	; get parent PSP segment
	assume	es:pspseg
	mov	ax,[TSS]	; get Stack Segment of caller
	mov	[PSPss], ax	; save it in PSP (allows for nested calles)
	mov	ax,[TSP]	; get Stack Pointer of caller
	sub	ax,4		; adjust PSP for retf to parent
	mov	[PSPsp], ax	; save in PSP 
				; 

; The following code is added to save the registers onto the stack of the
; process which exec the sub process, Terminate code will pull this 
; from calls stack and pass it back to caller from exec
;
; This was added to correct problem with WordPerfect 5.10 shelling
; on Feb 21, 1990 by SAH

	
       	mov	ax,[TSS]	; get stack segment
	cmp	ax,[scbtcbpc]
	je	skipexec
	mov	es,ax
       	mov	di,[TSP]
       	sub	di,16		; adjust from values push by MOSSAVER
	mov	ax,[TBX]
	mov	word ptr es:[di-2],ax
	mov	ax,[TCX]
	mov	word ptr es:[di-4],ax
	mov	ax,[TDX]
	mov	word ptr es:[di-6],ax
	mov	ax,[TSI]
	mov	word ptr es:[di-8],ax
	mov	ax,[TDI]
	mov	word ptr es:[di-10],ax
	mov	ax,[TBP]
	mov	word ptr es:[di-12],ax
	mov	ax,[TDS]
	mov	word ptr es:[di-14],ax
	mov	ax,[TES]
	mov	word ptr es:[di-16],ax
skipexec:
;



	assume	es:nothing
nopspstk:
	mov	es,[TDS]	; make es:di point the the caller's path string
	mov	di,[TDX]
	mov	cx,65
	xor	al,al
	mov	bx,di		; do a precheck to make sure an extra long
	cld			; filespec doesn't crash our stack
	repne	scasb
	jz	pathok
	jmp	fun4Berr	; too long
pathok:
	sub	di,bx
	mov	cx,di
	mov	ds,[TDS]	; place the filespec on the stack
	mov	si,[TDX]
	mov	bx, ss		; ES=SS
	mov	es, bx
	mov	bp,dx
	lea	di,[pathstr]
	rep	movsb
	mov	bp,[bp] 	; Address CALLers registers again
	mov	es,[TES]	; Get pointer to parameter block
	mov	bx,[TBX]	; "     "	"
	mov	ax,[TAX]	; Get function number
	mov	bp,dx			; Address local variables
	mov	word ptr [prmblk],bx
	mov	word ptr [prmblk+2],es
	mov	[funnum],al
	mov	[rsflags],0	; clear resource flags

; open file first - to accomodate pfs:write

	push	ds
	mov	dx, ss		;DS = SS
	mov	ds, dx
	lea	dx,[pathstr]	; Get pointer to users ASCIIZ string
	mov	ax,3d20H	; Open file for read, deny write sharing mode
	cmp	al,al		; set zero flag - SJC
	mov	[tcbexec3d],1	; flag tells openfile to allow exec to open 
	call	sim21		; the file to be exec'ed with a sharing mode
f4bret:
	mov	[tcbexec3d],0	; even if it is already open in compatibility
	pop	ds
	jnc	$+5
	jmp	f4berrok	; Opening error
	or	[rsflags],RS_OPEN	; SAH indicate that file is open
	mov	[flhdl],ax	; Store handle
	call	combmcb 	; combine memory blocks on all functions

; is it func 3, load overlay?

	cmp	byte ptr [funnum],3
	jne	fun4bx3d	
	les	bx,[prmblk]	; if yes, skip around environment and psp setup        
	mov	ax,es:[bx]
	mov	[pgmseg],ax	
	mov	ax,es:[bx+2]
	mov	[reloc],ax
	jmp	fun4bx3a	
SetMCBS:
	mov	ax,[envseg]	; Point to MB
	dec	ax		; Point to MB prefix
	mov	es,ax		; Address prefix
	assume	es:mbseg
	mov	[mbowner],dx	; Set owner PSP address in env. MB
	mov	ax,[pgmseg]
	dec	ax
	mov	es,ax
	mov	[mbowner],dx	; Set owner PSP address in PSP MB
	ret

; Determine environment size

fun4bx3d:				
	cld
	les	bx,[prmblk]	; Get parameter block pointer
	mov	bx,es:[bx]	; Get pointer to environment
	or	bx,bx		; Should they inherit the parent's?
	jnz	fun4B1		; No
	mov	es,[tcbpsp]	; Get parent PSP
	assume	es:pspseg
	mov	bx,es:[PSPenv]	; Get parent environment segment
fun4B1:
	mov	es,bx		; Point to env.
	assume	es:nothing
	xor	di,di		; Scan env. from start for end marker (00)
	xor	al,al
	mov	cx,8000H	; Scan up to 32K
fun4B1a:
	repne scasb		; Scan for 0
	je	fun4b2a 	; Found end of this string
	mov	ax, INVALID_ENVIRONMENT
	jmp	fun4bend
fun4B2a:
	scasb			; Is this a word of 0? (end of env.)
	jne	fun4B1a 	; Only single 0, continue scan
	add	di,2		; Point past additional string counter
	mov	si,di		; Save length of passed env.

; Now add 'load path string' size to env. size

	mov	bx,di		; Save size of env. in bytes
	push	es		; Save env. pointer
	mov	cx, ss		; ES=SS
	mov	es, cx
	lea	di,[pathstr]	; Get pointer to ASCIIZ
	mov	dx,di
	xor	al,al
	mov	cx,100		; Go over max. for the hell of it (max=64)
	repne scasb		; Find end of string
	pop	es		; Get env. pointer back
	sub	di,dx		; Calc length of load path
	add	bx,di		; BX= total env. size in bytes

; Allocate space for environment

	add	bx,0fH		; Round up to next seg
	shr	bx,1		; Calc # para's needed
	shr	bx,1
	shr	bx,1
	shr	bx,1
	mov	ah,48H
	call	sim21		;** For Novell
	jnc	fun4B3
	jmp	fun4Berr	; maybe not enough space here

; Now Copy environment to newly allocated block

fun4B3:
	or	[rsflags],RS_ENV	; Environment allocated OK
	push	ds
	mov	cx, es		; DS=ES
	mov	ds, cx
	assume	ds:nothing
	mov	es,ax		; Point to env. block
	push	di		; Save size of 'load path string'
	mov	cx,si		; Get size of env.
	xor	si,si
	xor	di,di
	rep movsb		; Move env.
	mov	cx, ss		; DS=SS
	mov	ds, cx
	lea	si,[pathstr]
	pop	cx			; Get size of string
	mov	word ptr es:[di-2],1	; Set additional string count
	rep movsb			; Move 'load path string'
	pop	ds
	assume	ds:grp
	mov	[envseg],es	; Save pointer to env. block

; Allocate initial working space for program and create PSP

	mov	ah,48h		; we are going to try to allocate all memory
	mov	bx,-1
	call	sim21		;** for Novell
	cmp	bx,12h
	jb	fun4bw1e
	mov	ah,48H		; Allocate space
	call	sim21		;** For Novell
	jnc	fun4bw1
fun4bw1e:
	mov	al, INSUFFICIENT_MEMORY
	jmp	fun4berr	; Error

; Set Terminate vector to CALLers CS:IP

fun4bw1:
	mov	[mempara],bx		; save memory size
	or	[rsflags],RS_PGM	; program block allocated
	push	ds
	push	ax
	mov	bx,bp
	mov	bp,[bp] 	; Address CALLers registers
	mov	ds,[TCS]	; Get pointer to users next instruction
	mov	dx,[TIP]	;  after INT 21H
	mov	bp,bx
	mov	ax,2522H	; Set terminate
	call	sim21		;** For Novell
	pop	ax
	pop	ds
	or	[rsflags],RS_TRM	; terminate vector changed
	mov	[pgmseg],ax	; Save block pointer for program
	mov	dx,ax		; Create new PSP here
	mov	ah,26H
	call	sim21		;** For Novell
;
;	SAH 11/16/88 Since opening of the file has been above create PSP
;	call we must remove the file handle use in exec out of child PSP
;
	push	[tcbpsp]
	MSetPSP  dx		; segment of newly created PSP	
	mov	bx,[flhdl]
	mov	ax,-1		; set to ffh
	callmos2 setphdl	
	pop	[tcbpsp]
	mov	ax, [tcbpsp]	; set psp to parent psp 04/30/87
	mov	[tcboldpsp],ax	; update PSP for lanlink
;
	push	es
	mov	es, [pgmseg]
	assume	es:pspseg
	mov	[PSPprnt], ax	
	pop	es
	assume	es:nothing

; Set owner fields in MB prefix for env. block and program block
	
	call	SetMCBs
fun4bx3a:			; MJS skip to here for func #3
	mov	bx,[flhdl]
	push	ds
	mov	ds,[pgmseg]	; Get pointer to memory block
	mov	dx,100H 	; Load just after MB prefix
	cmp	[funnum],3	; MJS use offset 0 for func 3
	jne	fun4bx3g
	xor	dx,dx
fun4bx3g:
	mov	cx,2		; Read 1st word to check for EXE
	mov	ah,3fH		; Read file
	push	dx
	call	sim21		;** For Novell
	pop	dx
	jnc	fun4br1
	pop	ds
	jmp	fun4berr
fun4br1:
	xchg	dx,bx
	cmp	word ptr ds:[bx],5a4dH	; Is this an EXE file?
	xchg	dx,bx
	pop	ds
	jne	$+5
	jmp	fun4bEXE	; Do EXE processing

; Now processing a COM file

	mov	si,[mempara]	; get size of memory in paragraphs
	mov	ax,4202H	; Determine file size for load
	xor	cx,cx
	xor	dx,dx
	call	sim21		;** For Novell
	jnc	$+5
jf4bcrt1:
	jmp	fun4bcrt	; Unforeseen error during EXEC call
	mov	word ptr [bsize],ax
	mov	word ptr [bsize+2],dx	; byte length of file
	mov	cx,4
fun4b1c:
	shr	dx,1
	rcr	ax,1
	loop	fun4b1c
	mov	[psize],ax	; paragraph length of file
	mov	ax,4200H	; Reset file pointer to beginning
	xor	cx,cx
	xor	dx,dx
	call	sim21		;** For Novell
	mov	ax,[psize]
	cmp	[funnum], 3	; SAH skip if OVERLAY
	je	fun4b2		;SAH 05/13/88 skip memory check too
	add	ax,10h
fun4b1d:
	cmp	ax,si		; Is this file too large for this block?
	jbe	fun4b2		; No, its ok for loading
	mov	ax, INSUFFICIENT_MEMORY
	jmp	fun4berr	; Too large
fun4b2:

; Read in COM file at PSP:100H

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
	mov	cx,-512 	; at most 64K - 512 bytes at a time
	cmp	word ptr [lsz+2],0
	jne	f4bclb		; ne if > 64K left to read
	cmp	cx,word ptr [lsz]
	jbe	f4bclb		; be if 64K - 1 to 64K - 512 left read
	mov	cx,word ptr [lsz]	; else read what's there
f4bclb:
	push	cx
	mov	ah,3fH
	call	sim21		;** For Novell
	pop	dx		; dx = amount supposed to have been read
	pop	ds
	jc	f4bclc
	jcxz	f4bclc		; unforeseen error during EXEC if 0 read
	cmp	dx,cx
	je	f4bcld		; unforeseen error if not all requested read
f4bclc:
	jmp	fun4bcrt	; Unforeseen error during EXEC call
f4bcld:
	sub	word ptr [lsz],cx	; new length to be loaded according
	sbb	word ptr [lsz+2],0	;   to amount actually read
	add	word ptr [lofs],cx	; carry not possible
	mov	ax,word ptr [lsz]
	or	ax,word ptr [lsz+2]
	jnz	f4bcla
	and	[rsflags],NOT RS_OPEN	; SAH clear open flag
	mov	ah,3eH		; Close file
	call	sim21		;** For Novell
	jnc	$+5
	jmp	fun4berr
	cmp	[funnum],3	; MJS  load overlay?
	jne	$+5		; MJS  if yes, done - get out	
	jmp	fun4bx3b
	push	si
	call	fun4bPSP	; Init values in PSP
	pop	si
	cmp	[funnum],1	; Is this a load and setup only?
	jne	$+5		; No, run program
	jmp	fun4B4

; Set registers and enter loaded program
; BX:CX with file size

	mov	bx,word ptr [bsize+2]
	mov	cx,word ptr [bsize]
	mov	ax,[pgmseg]	; Get pointer to PSP
	mov	dx,[ReturnAX]	; get return value for valid drive specifiers
	xor	di,di
	xor	bp,bp
	mov	es,ax
	MSetPSP	ax		; Set new current PSP
	mov	word ptr [tcbdta],80h	; MJS
	mov	word ptr [tcbdta+2],ax	; MJS
	dec	[tcbnest]	; decrement counter for nest control
				; since mosint21 was entered but not exited
	call	RstINMOS	; SAH 05/20/88 Reset INMOS	
	push	ax
	mov	ax,[tcbpreseg]	; activate any +except/+only lists which
	mov	[tcbactseg],ax	; may exist
	pop	ax
	mov	ds,ax		
	cmp	si,1000H	; Is MB <64k?
	jae	f4bsk0
	shl	si,1
	shl	si,1
	shl	si,1
	shl	si,1
	cli
	mov	sp,si
	xor	si,si		; Init for task
	jmp	f4bsk1
f4bsk0:
	cli
	mov	sp,0
f4bsk1:
	mov	ss,ax
	sti
	push	bp		; Set RETurn to INT 20H in top of stack
	push	ax		; New CS
	mov	ax,100H
	push	ax		; New IP
	mov	ax,dx		; set return value for valid drive
	xor	dx,dx		; specifiers
	retf			; Enter loaded COM file
fun4B4:
	assume	es:nothing
	les	di,[prmblk]	; Get pointer to parameter block
	add	di,0eH		; Point to storage for SS:SP and CS:IP
	xor	ax,ax		; SP
	cmp	si,1000H	; Is MB <64k?
	jae	f4bskok
	shl	si,1
	shl	si,1
	shl	si,1
	shl	si,1
	mov	ax,si
f4bskok:
	xor	si,si		; Init for task
	dec	ax
	dec	ax
	push	ax
	stosw
	mov	ax,[pgmseg]	; SS
	stosw
	mov	ax,100H 	; IP
	stosw
	mov	ax,[pgmseg]	; CS
	stosw
	mov	es,[pgmseg]
	pop	di
	cmp	word ptr [bsize+2],0	; is file > 65534 bytes?
	ja	fun4b4a 	; if bigger
	cmp	word ptr [bsize],0FFFEh
	ja	fun4b4a 	; if bigger
	xor	ax,ax
	stosw			; Set 0 RETurn address in stack
fun4b4a:
	mov	es,[pgmseg]	; return psp address in ax
	assume	es:pspseg
	mov	ax,[tcbpsp]
	mov	[PSPprnt],ax
	mov	word ptr [tcbdta],80h
	mov	word ptr [tcbdta+2],es
	mov	bx,bp
	mov	bp,[bp]
	mov	[TAX],es
	and	[TFLAG], NOT CARRY	; SAH indicate no errors
	MSetPSP	es
	mov	bp,bx
	jmp	fun4Bend
;-----------------------------------------------------------------------;
; Process EXE files here
;-----------------------------------------------------------------------;
	assume	ds:nothing, es:nothing
fun4bEXE:
	xor	ah,ah
	mov	dx,3H
	call	mosheman	; Allocate some temp working space
	or	al,al
	jz	fun4bne1
	jmp	fun4blsmp
fun4bne1:
	mov	ax,es		; Work area
	inc	ax		; Skip heap prefix block
	mov	[workadr],ax	; save for recovery
	or	[rsflags],RS_MMB	; allocated block from mosheman OK
	push	ds
	mov	ds,ax		; Address work area
	mov	dx,02H		; Read in more of the EXE header
	mov	cx,1eH
	mov	ah,3fH		; Read file
	call	sim21		;** For Novell
	pop	ds
	jnc	$+5
	jmp	fun4berr

; Determine header size and read it into work space

	mov	ax,4200H	; Reset pointer to start of file
	xor	dx,dx		; 
	xor	cx,cx
	call	sim21		;** For Novell
	jc	jf4bcrt2
;
;	The following logic is use to make sure that 
;	next entry will fall on 4 byte boundary. This is done by 
;	adjusting the first read so that lenght will make sure
;	that next read is on 4 byte bondary
;
	xor	dx,dx		; No Adjustment on size
	mov	cx,512		; default to 512
	mov	ax,es:[28h]	; get start location  (18h + 10h)
	mov	dx,ax
	and	ax,0fffch	; mask out for multible of 4
	sub	dx,ax
	sub	cx,dx
;
	mov	dx,33		; use a 512 byte buffer + header
	mov	ah,1		; Deallocate current work area
	call	mosheman
	or	al,al
	jz	fun4bhal
jf4bcrt2:
	jmp	fun4bcrt
fun4bhal:
	and	[rsflags],not RS_MMB	; gave mosheman block back
	xor	ah,ah
	call	mosheman	; Allocate work area for 512 bytes
	or	al,al
	jz	fun4bne2
fun4blsmp:
	push	es
	MGetSCB es
	assume	es:grp
	cmp	WORD PTR [SCBCIN24+2],0 ; special handler installed!
	jz	fun4bs24
	mov	ah,0ffh
	mov	bx,cs		; make bx:si point to error string
	mov	dx,offset [ipmsg10]
	pushf
	call	[SCBCIN24]	; call command processor
fun4bs24:
	pop	es
	mov	ax, INSUFFICIENT_MEMORY
	jmp	fun4berr

IpMsg10 db	'SMP too small for EXEC.$' ;@@XLAT

fun4bne2:
	or	[rsflags],RS_MMB	; another mosheman block
	mov	[CurrentRelo],cx 	; set current relocation to 512 or 500
	mov	[ReloAdjust],0		; set relocation adjustment to 0
	mov	ax,es			; Work area
	inc	ax			; Skip heap prefix block
	mov	[workadr],ax		; Address of work area
	mov	es,ax
	push	ds
	mov	ds,ax			; Address work area
	xor	dx,dx			; Load into start of work area
	mov	ah,3fH			; Read file
	call	sim21			;** For Novell
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
	mov	ax,[psize]	; get program paragraphs
	cmp	[funnum],3	; MJS load overlay?
	jne	$+5
	jmp	fun4bx3c
	mov	dx,es:[0ch]	; MaxAlloc
	cmp	dx,es:[0ah]	; MinAlloc
	ja	f4bmma		; MaxAlloc > MinAlloc (as it should be)
	mov	dx,es:[0ah]
	mov	es:[0ch],dx
	jne	f4bmma		; MaxAlloc < MinAlloc (? replace w/ MinAlloc)
	or	dx,dx
	jz	f4bmmc		; MaxAlloc = MinAlloc = 0 allocate all
f4bmma:
	add	ax,dx		; Include MaxAlloc value
	jc	f4bmmc
f4bmmb:
	add	ax,10h		; add in room for PSP
	jnc	f4bmmd
f4bmmc:
	mov	ax,-1
f4bmmd:

; check to see if we should allocate space just in 
; case file is an EXEPack File
	
	push	es
	cmp	word ptr [pgmseg],0fffh 	; check if start seg < 1000h
	jae	f4bepdn 			; skip the 1 block case
	mov	es,[workadr]
	cmp	word ptr es:[6],0		; check if # reloc  entries
	jne	f4bepdn 			; skip if not zero
	cmp	word ptr es:[16h],0		; check CS
	jne	f4bx0				; always do it if non-zero
	cmp	word ptr es:[14h],0		; check IP
	je	f4bepdn 			; skip if zero
f4bx0:

; allocate space so that we don't get pack file corrupt message

	push	ax
	mov	es,[pgmseg]
	mov	ah,49h
	call	sim21			; free old program space
	and	[rsflags],NOT RS_PGM	; program block not allocated
	call	combmcb
	mov	bx,0fffh		
	sub	bx,[envseg]
	mov	es,[envseg]
	mov	ah,4ah
	call	sim21			; force enviroment to be bigger
	jnc	f4bx1
	mov	ax, INSUFFICIENT_MEMORY
	jmp	fun4berr	
f4bx1:
	mov	bx,12h
	mov	ah,48h
	call	sim21			; allocate new program space
	jnc	f4bx2
	mov	ax, INSUFFICIENT_MEMORY
	jmp	fun4berr
f4bx2:
	or	[rsflags],RS_PGM	; program block allocated	
	push	cx
	push	si
	push	di
	push	ds
	mov	ds,[pgmseg]
	mov	es,ax
	mov	cx,90h
	xor	si,si
	xor	di,di
	rep	movsw
	pop	ds
	pop	di
	pop	si
	pop	cx
	mov	[pgmseg],ax
	mov	dx,ax
	call	SetMCBS 		; setup the MCB's
	pop	ax
f4bepdn:	
	pop	es

; Continue with Exec

	push	es		; Save work area pointer
	mov	es,[pgmseg]	; PSP MB address
	mov	bx,ax		; Expand MB to max
	mov	ah,4aH		; SetBlock to maximum size (returns error)
	push	bx
	call	sim21		;** For Novell
	jnc	f4bexemx	; Maximum value OK
	pop	ax		; throw away max request
	pop	es		; Address work area
	push	es
	mov	ax,cx		; Now try load size+MinAlloc
	add	ax,es:[0aH]	; MinAlloc
	jc	f4bmme
	add	ax,10h
	jnc	f4bmmf
f4bmme:
	mov	ax,-1
f4bmmf:
	cmp	bx,ax		; Is block large enough for minimum memory
	jae	f4bexemn	; Yes
	pop	ax		; Clear work area segment from stack
	mov	ax, INSUFFICIENT_MEMORY
	jmp	fun4berr
f4bexemn:
	mov	es,[pgmseg]
	mov	ah,4aH		; Allocate largest block available
	push	bx
	call	sim21		;** For Novell
f4bexemx:
	pop	bx
	pop	es		; Work area address

; compute start paragraph to load file

	mov	ax,[pgmseg]
	mov	[adjust],0010h	; load is directly after psp
	add	ax,10h		; load = pspseg + psp length if MaxAlloc <> 0
	cmp	word ptr es:[0ch],0	; MaxAlloc = 0 ?
	jne	f4baa
	cmp	word ptr es:[0ah],0	; MinAlloc = 0 ?
	jne	f4baa
	mov	ax,[pgmseg]	; else load at top of allocated region
	add	ax,bx
	sub	ax,[psize]

; calculate adjustment factor for load
; in this case load is up high and psp is down low 

	mov	bx,ax
	sub	bx,[pgmseg]
	mov	[adjust],bx
	jmp	f4baa
fun4bx3c:
	mov	ax,[pgmseg]	; MJS entry for func 3
	jmp	short f4baa
f4baa:
	mov	[lseg],ax
	mov	[lofs],0	; always start at offset 0
	mov	ax,word ptr [bsize]	; load size of file in bytes
	mov	word ptr [lsz],ax
	mov	ax,word ptr [bsize+2]
	mov	word ptr [lsz+2],ax
	mov	dx,es:[8]	; Get header size
	mov	cl,4
	shl	dx,cl		; Calc # bytes
	mov	bx,[flhdl]	; File handle (I already told you that!)
	mov	ax,4200H	; Position file pointer to load module
	xor	cx,cx		;   (past header portion of file)
	call	sim21		;** For Novell
	jc	f4blc
f4bla:
	push	ds		; load the file up to 64K-512 bytes at a time
	mov	dx,[lofs]
	mov	ax,dx
	and	dx,0fh
	mov	cl,4
	shr	ax,cl
	add	ax,[lseg]
	mov	[lofs],dx	;RR store normalized lseg:lofs
	mov	[lseg],ax	;RR
	mov	ds,ax
	mov	cx,-512 	; at most 64K - 512 bytes at a time
	cmp	word ptr [lsz+2],0
	jne	f4blb		; ne if > 64K left to read
	cmp	cx,word ptr [lsz]
	jbe	f4blb		; be if 64K - 1 to 64K - 512 left read
	mov	cx,word ptr [lsz]	; else read what's there
f4blb:
	push	cx
	mov	ah,3fH
	call	sim21		;** For Novell
	pop	dx		; dx = amount supposed to have been read
	pop	ds
	jc	f4blc
	mov	cx,ax		;RR actual length was returned in ax
	jcxz	f4blc		; unforeseen error during EXEC if 0 read
	cmp	dx,cx
	je	f4bld		; unforeseen error if not all requested read
	jmp	short f4bldone	; SAH well header is wrong (is this best way)
f4blc:
	jmp	fun4bcrt	; Unforeseen error during EXEC call
f4bld:
	sub	word ptr [lsz],cx	; new length to be loaded according
	sbb	word ptr [lsz+2],0	;   to amount actually read
	add	word ptr [lofs],cx	; carry not possible
	mov	ax,word ptr [lsz]
	or	ax,word ptr [lsz+2]
	jnz	f4bla
f4bldone:

; Perform file relocation

	mov	dx,[pgmseg]
	add	dx,[adjust]	; Point past PSP address (DX=start segment)
				; or up in high memory if exe file desires
	cmp	[funnum],3
	jne	fun4bx3f
	mov	dx,[reloc]	; MJS func #3 - use relocation factor
fun4bx3f:
	push	ds
	mov	cx, es		; DS=ES
	mov	ds, cx
	assume	ds:nothing
	mov	si,ds:[18H]	; Get pointer to 1st relocation item
	mov	cx,ds:[6]	; Get # of relocation table entries
	jcxz	f4brelx


; Relocation loop

f4brel:
	cmp	si,[CurrentRelo]	  ; cmp to top of buffer 
	jb	f4brel3
;
;	we have determined that Current EXE header entry is nolonger inside
;	currently allcoated SMP 512 byte block we must now read in the 
;	next 512 byte section of EXE header and continue processing
;
	push	bx
	push	cx
	push	dx

	cmp	si,512			; is this the first time throug
	ja	f4brel0			; no...continue
;
;	if this is the first time, we must set file position to next available
;	location to read in exeheader. CurrentRelo should contain this offset
;
	mov	dx,[CurrentRelo]
	xor	cx,cx
	mov	ax,4200h
	call	Sim21
	jc	f4brelerr
f4brel0:
;

	xor	dx,dx
	mov	cx,512			; we will always use a 512 byte space
	mov	ah,3fH			; Read file
	call	sim21			;** For Novell

f4brelerr:
	pop	dx
	pop	cx
	pop	bx
	jnc	f4brel1
	jmp	fun4berr

;
;	Adjust Relocation position counters

f4brel1:
	mov	ax,512 			   	; use 512 byte for defaults
	cmp	si,512				; is this first time and
	jae	f4brel2				; size is not 512
	mov	ax,[CurrentRelo]		; if not add size
f4brel2:
	add	[ReloAdjust],ax
	add	[CurrentRelo],512
;
;	Adjust Relocation entry
;
f4brel3:
	push	si
	sub	si,[ReloAdjust]
	mov	ax,[si+2]	; Get segment value
	mov	di,[si] 	; Get offset value
	add	ax,dx		; Calc file offset
	mov	es,ax
	assume	es:nothing
	add	es:[di],dx	; Make relocation adjustment
	pop	si
	add	si,4		; Point to next entry
	loop	f4brel		; Continue through all entries

;	End of Relocation Loop

f4brelx:
;
;	Now locate file position at begining
;
	push	dx
	xor	dx,dx
	xor	cx,cx
	mov	ax,4200h
	call	Sim21
	jc	f4brelxer
;
;	Now  Reread the first 512 bytes so that remainder of code can
;	propertly handle header information
;
	xor	dx,dx
	mov	cx,512			; we will always use a 512 byte space
	mov	ah,3fH			; Read file
	call	sim21			;** For Novell
f4brelxer:
	pop	dx
	jnc	f4brelxok
	jmp	fun4berr
f4brelxok:	
	mov	ax,[workadr]
	dec	ax		; Address block prefix
	mov	es,ax
	mov	ah,1		; Deallocate block
	call	mosheman
	or	al,al
	jz	$+5
	jmp	fun4bcrt

	and	[rsflags],NOT RS_OPEN	; SAH clear open flags
	mov	ah,3eH		; Close file
	call	sim21		;** For Novell
	jnc	$+5
	jmp	fun4berr


	cmp	[funnum],3
	jne	fun4bx3h
	pop	ds
	jmp	fun4bx3b	; MJS if func #3 - done, get out
fun4bx3h:
	push	dx		; Save 'Start Segment' value
	call	fun4bPSP	; Init values in PSP
	pop	dx
	cmp	[funnum],1	; Is this a load and setup only?
	jne	fun4bya 	; No, run program
	les	di,[prmblk]	; Get pointer to parameter block
	add	di,0eH		; Point to storage for SS:SP and CS:IP
	mov	ax,ds:[10H]	; Get SP value
	sub	ax,2		;????
	stosw			; SP
	mov	ax,ds:[0eh]	; get SS
	add	ax,dx		; relocation adjustment to SS
	stosw			; SS
	mov	ax,ds:[14H]	; Get IP
	stosw			; IP
	mov	ax,ds:[16H]	; Get CS
	add	ax,dx		; Make adjustment
	stosw			; CS
	mov	es,[pgmseg]
	assume	es:pspseg
	mov	ax,[tcbpsp]
	mov	[PSPprnt],ax
	mov	word ptr [tcbdta],80h
	mov	word ptr [tcbdta+2],es
	mov	bx,bp
	mov	bp,[bp]
	mov	[TAX],es
	and	[TFLAG], NOT CARRY	; SAH indicated no errors
	MSetPSP	es
	mov	bp,bx
	pop	ds
	jmp	fun4Bend
fun4bya:

; Init registers and enter the application
; Clear work area from heap

	mov	ax,ds:[0eH]	; Get SS value
	add	ax,dx		; Make relocation adjustment
	mov	bx,ds:[10H]	; Get SP value
	mov	cx,[pgmseg]	; Get PSP address
	mov	es,cx
	push	ax
	MSetPSP es		; Set new current PSP
	mov	word ptr [tcbdta],80h	; MJS set default dta to ofs 80 in PSP
	mov	word ptr [tcbdta+2],es
	dec	[tcbnest]	; decrement counter for nest control
				; since mosint21 was entered but not exited
	call	RstINMOS	; SAH 05/20/88 Reset INMOS flag
	push	ax
	mov	ax,[tcbpreseg]	; activate any +except/+only lists which
	mov	[tcbactseg],ax	; may exist
	pop	ax
	mov	ax,[ReturnAX]	; get return ax
	cli			; By convention
	pop	ss		; Yes, this is correct! (trust ME!)
	mov	sp,bx
	sti
	mov	bx,ds:[16H]	; Get CS
	add	bx,dx		; Make adjustment
	mov	es,cx		; Point to PSP
	mov	cx,ds:[14H]	; Get IP
	xchg	ax,cx
	mov	dx,es		; Point to PSP
	mov	ds,dx		; appears that DOS has dx as PSP value!

; Found method to solve possible compatibility problems
; by pushing the segment and offset and doing a retf
; nolonger need to use reserve area of PSP  

	assume	ds:nothing, es:pspseg
	push	bx			; User App's segment
	push	ax			; User App's offset
	mov	ax,cx			; SAH not that cx will contain			
	mov	bx,cx			; return value for valid drives	
	xor	cx,cx			
	retf
fun4bx3b:			; MJS done with func #3 - return
	mov	bx,bp
	mov	bp,[bp]
	and	[TFLAG],NOT CARRY	; SAH 05/13/88 Carry should be clear
	mov	bp,bx
	jmp	fun4bend	
;-----------------------------------------------------------------------;
; This routine will load the PSP with the correct values		;
;-----------------------------------------------------------------------;
fun4bPSP proc	near
	assume	ds:nothing, es:nothing, ss:tcb
	push	ds
	lds	si,[prmblk]	; Get pointer to passed parms
	lds	si,[si+2]	; Get pointer to command line
	mov	es,[pgmseg]
	assume	es:PSPseg

; Init command line at 80H

	mov	di,offset PSPseg:PSPcnt 	; 80h
	mov	cx,128/2
	rep movsw

; Set memory size.	JSM 03/02/87

	mov	si,es
	dec	si
	mov	ds,si		; pointer to memory block
	mov	si,ds:[3]	; size of block for program
	add	si,[pgmseg]	; start of program block
	mov	[PSPmem],si	; end of allocation field in PSP (offset 2)

; compute if needed new PSP function call to 0:C0

	mov	ax, ds:[3]	; size of memory block in paragraphs
	cmp	ax, 0fffh	
	jae	f4bskip
	sub	ax, 10h 	; remove 10h paragraphs for PSP
	push	ax
	mov	cl, 4
	shl	ax, cl		; save offset in bytes
	mov	word ptr [PSPcall+1], ax 
	pop	ax
	neg	ax
	add	ax, 0ch 	; segment + 16*offset = 0:c0
	mov	word ptr [PSPcall+3], ax
f4bskip:
	pop	ds

; Set FCBs in PSP

	push	ds
	lds	si,[prmblk]	; Get pointer to passed parms
	lds	si,[si+6]	; Get pointer to 1st FCB
	mov	di,offset PSPseg:PSPfcb1	; 5Ch
	mov	cx,6
	rep movsw
	lds	si,[prmblk]	; Get pointer to passed parms
	lds	si,[si+0aH]	; Get pointer to 2nd FCB
	mov	di,offset PSPseg:PSPfcb2	; 6Ch
	mov	cx,6
	rep movsw
	pop	ds
	mov	ax,[envseg]	; Set env. pointer in PSP
	mov	[PSPenv],ax	; 2Ch
;
; Validate FCB to make sure that drive specifies of FCB #1 and FCB #2
; are valid. Return value to exec is as follows, Return in ax
;
;	AL=ffh if the first parameter contained an invalid drive
;	       specifier (otherwise AL=00h)
;	AH=ffh if the second parameter contained an invalid drive
;	       specifier (otherwise AH=00h)
;	
; Above information was taken from IBM DOS 4.0 tech reference on page
; 6-6 and can be also found in other IBM DOS references
;
; This value is save in ReturnAX variable and will be set in ax and bx
; when MOS jumps to application, BX is use to transfer value to AX
; easiler and also it appears that DOS does the same.
; Update 01/31/90 Stewart Hyde
;
	push	dx
	xor	cx,cx
	mov	al,byte ptr es:[PSPfcb1]
	or	al,al				; current drive
	jnz	FcbCur1
	mov	al,[tcbcdriv]
FcbCur1:
	push	ds
	push	cx
	callmos2 findbdb			; find bdb for this disk
	pop	cx
	pop	ds
	jnc	SkipFcb1
	mov	cl,0ffh				; indicate error
SkipFcb1:
	mov	al,byte ptr es:[PSPfcb2]
	or	al,al	      		       	; current drive
	jnz	FcbCur2
	mov	al,[tcbcdriv]
FcbCur2:
	push	ds
	push	cx
	callmos2 findbdb	; find bdb for this disk
	pop	cx
	pop	ds
	jnc	SkipFcb2
	mov	ch,0ffh		; indicate error
SkipFcb2:
	mov	[ReturnAX],cx	; save return value
	pop	dx
	ret
fun4bPSP endp

;--------------------- error handler  ----------------------

	assume	ds:nothing, es:nothing, ss:tcb
fun4berr:
	cmp	al, FILE_NOT_FOUND	; Is this file not found?
	je	f4berrok
	cmp	al, INSUFFICIENT_MEMORY
	je	f4berrok
	jmp	fun4bcrt	; Unknown error
f4berrok:
	mov	bx,bp
	mov	bp,[bp]
	callmos2 moserror
	mov	bp,bx
	test	[rsflags],RS_MMB	; mosheman block still here?
	jz	f4berr2 	; no mosheman block
	mov	ax,[workadr]	; block's address
	dec	ax		; back over header
	mov	es,ax
	mov	ah,1
	call	mosheman	; return mosheman block
	cmp	al,al
	jnz	fun4bcrt	; if error, crash
f4berr2:
	test	[rsflags],RS_ENV	; environment returned?
	jz	f4berr3
	mov	es,[envseg]	; give back environment block
	mov	ah,49h
	call	sim21		;** For Novell
	jc	fun4bcrt	; if error, crash
f4berr3:
	test	[rsflags],RS_TRM
	jz	f4berr4 	; if no program block
	mov	es,[pgmseg]	; Get program block pointer
	assume	es:pspseg
	push	ds
	lds	dx,[PSPtrmv]	; old terminate vector
	mov	ax,2522h	; restore the old vector
	call	sim21		;** For Novell
	pop	ds
	jc	fun4bcrt	; if error, crash
	assume	es:nothing
f4berr4:
	test	[rsflags],RS_PGM ; was a program block allocated?
	jz	f4berr16	; if terminate vector unchanged
	mov	es,[pgmseg]	; Get program block pointer
	mov	ah,49H		; Free block before return
	call	sim21		;** For Novell
	jc	fun4bcrt	; if error abort 
f4berr16:
	test	[rsflags],RS_OPEN ; was program file open
	jz	fun4bend
	mov	bx,[flhdl]	; get handle	
	mov	ah,3eh
	call	sim21		; close file
	jnc	fun4bend	
fun4bcrt:
	mov	ax,'B4' 	; unexpected error
	jmp	funerr
fun4bend:

lundef	ReloAdjust
lundef	CurrentRelo
lundef	ReturnAX
lundef	mempara
lundef	ldsize
lundef	prmblk
lundef	pathstr
lundef	workadr
lundef	envseg
lundef	pgmseg			; Segment address of program block
lundef	psize			; paragraph length of load module (com or exe)
lundef	bsize			; byte length of load module (com or exe)
lundef	lsz			; length remaining to load
lundef	lofs			; current load offset
lundef	lseg			; current load segment
lundef	flhdl
lundef	funnum
lundef	rsflags
lundef	reloc
lundef	adjust
lendp	mosfun4B

	subttl	mosfun4C - Terninate a process (EXIT)
	page
;-----------------------------------------------------------------------;
; Terminates the current process and transfers control to the involking ;
; process.								;
;									;
;  On Entry:								;
;	TAL = return code						;
;									;
;  On Exit:								;
;	Nothing 							;
;									;
;	Global data affected						;
;	Global procedures called					;
;	What registers are changed					;
;-----------------------------------------------------------------------;
	public	mosfun4C
	assume	cs:mos,ds:grp,ss:tcb,es:nothing
mosfun4C:
	mov	al,[TAL]	; Get return code
	xor	ah,ah		; Normal termination
	mov	[tcbretc],ax
	mov	es,[tcbpsp]	; Terminate this process
	jmp	fun00a		; Continue with normal termination steps

	subttl	mosfun4D - Get Return Code of a Subprocess
	page
;-----------------------------------------------------------------------;
; Gets the return code specified by another process either through	;
; function call 4C or 31.  It returns the Exit code only once.		;
; The low byte of the exit code contains the code sent by the exiting	;
; routine.  The high byte of the exit code can contain: 		;
;									;
;	00H - for normal termination					;
;	01H - for termination by CTRL-Break				;
;	02H - for termination as a result of a critical device error	;
;	03H - for termination by call 31H				;
;									;
;  On Entry:								;
;	Nothing 							;
;									;
;  On Exit:								;
;	TAX = Return code						;
;									;
;	No Global data affected 					;
;	No Global procedures called					;
;-----------------------------------------------------------------------;
	public	mosfun4D
	assume	cs:mos,ds:grp,ss:tcb,es:nothing
mosfun4D:
	mov	ax,[tcbretc]	; Get return code for task
	mov	[TAX],ax		; Return to user
	and	[TFLAG],NOT CARRY	; Make sure carry cleared
	ret

	subttl	mosfun54 - Get Verify Setting
	page
;-----------------------------------------------------------------------;
; Returns the value of the verify flag. 				;
;									;
;  On Entry:								;
;	Nothing 							;
;									;
;  On Exit:								;
;	TAL = 00H if verify is off, 01H if verify is on 		;
;									;
;	No Global data affected 					;
;	No Global procedures called					;
;-----------------------------------------------------------------------;
	public	mosfun54
	assume	cs:mos,ds:grp,ss:tcb,es:nothing
mosfun54:
	mov	al,[tcbvflg]	; Get current setting
	mov	[TAL],al		; Return it to user
	ret

	subttl	mosfun58 - Get/Set Allocation Strategy
	page
;-----------------------------------------------------------------------;
; Get/Set memory allocation strategy.					;
;									;
;  This function, although not implemented by MOS, must appear to the	;
; application that it does.  This routine merely stores the allocation	;
; strategy requested by the application (on Set) so that same number	;
; can be recalled if an application needs to find out what the strategy ;
; is.									;
;									;
;  GET Allocation Strategy						;
;  -----------------------						;
;  Input:								;
;	AX = 5800h							;
;  Output:								;
;	AX = Memory Allocation Strategy					;
;		or Error code if Carry Set				;
;									;
;  SET Allocation Strategy						;
;  -----------------------						;
;  Input:								;
;	AX = 5801h							;
;	BX = Allocation Strategy					;
;  Output:								;
;	AX = Error code if carry set					;
;									;
;  Notes:								;
;									;
;  1) Allocation Strategy values can be 0 for "first fit", 1 for	;
;     "best fit" and 2 for "last fit".					;
;									;
;  2) Presently, nothing is changed in MOS based on the value of the	;
;     Allocation Strategy variable.  This function stores the value	;
;     for the sake of applications that may wish to test on the value	;
;     once it's set.							;
;-----------------------------------------------------------------------;
	public	mosfun58
	assume	cs:mos,ds:grp,ss:tcb,es:nothing

mosfun58	proc	near
	mov	ax, [TAX]
	cmp	al, 1
	jb	f58_0
	je	f58_1
;
;   Return Bad function error code.
;
	mov	ax, INVALID_FUNCTION
	jmp short f58_exit
;
;   Get Allocation Strategy.
;
f58_0:
	mov	ax, TCB_malloc_strategy		;Get from TCB.
	mov	[TAX], ax
	xor	ax, ax
	jmp short f58_exit
;
;   Set Allocation Strategy.
;
f58_1:
	mov	bx, [TBX]
	mov	TCB_malloc_strategy, bx		;Place in TCB.
	xor	ax, ax

f58_exit:
	callmos2  moserror
	ret

mosfun58	endp

	subttl	mosfun59 - Get Extended Error
	page
;-----------------------------------------------------------------------;
; This is the extended error code table 				;
; See MOS manual for types of Class, Action and Locus			;
;-----------------------------------------------------------------------;
fun59tbl label	byte

;*********    Class   Action  Locus  Error code    *********;

	db	0,	0,	1	;0
	db	7,	4,	1	;1 
	db	8,	3,	2	;2 
	db	8,	3,	2	;3 
	db	1,	4,	1	;4 
	db	3,	4,	1	;5 
	db	7,	4,	1	;6 
	db	7,	4,	5	;7 
	db	1,	4,	5	;8 
	db	7,	4,	5	;9 

	db	9,	4,	1	;10
	db	9,	4,	1	;11
	db	7,	4,	1	;12
	db	9,	4,	1	;13
	db	13,	6,	1	;14 * RESERVED
	db	8,	3,	2	;15
	db	3,	3,	2	;16
	db	9,	3,	2	;17
	db	8,	3,	2	;18 RBR (SAH 7-20)
	db	3,	7,	2	;19

	db	13,	3,	1	;20
	db	11,	1,	2	;21
	db	7,	4,	1	;22
	db	11,	5,	2	;23
	db	9,	4,	1	;24
	db	11,	5,	2	;25
	db	11,	7,	2	;26
	db	11,	7,	2	;27
	db	1,	7,	4	;28
	db	11,	1,	1	;29

	db	11,	1,	1	;30
	db	5,	1,	1	;31
	db	10,	2,	2	;32 SAH (04/13/88)
	db	10,	2,	1	;33
	db	11,	7,	2	;34
	db	1,	4,	2	;35
	db	1,	4,	1	;36
	db	13,	6,	1	;37 *
	db	13,	6,	1	;38 * RESERVED
	db	13,	6,	1	;39 *

	page

	db	13,	6,	1	;40 *
	db	13,	6,	1	;41 *
	db	13,	6,	1	;42 *
	db	13,	6,	1	;43 *
	db	13,	6,	1	;44 *
	db	13,	6,	1	;45 * RESERVED
	db	13,	6,	1	;46 *
	db	13,	6,	1	;47 *
	db	13,	6,	1	;48 *
	db	13,	6,	1	;49 *

	db	7,	4,	3	;50
	db	3,	2,	3	;51
	db	13,	3,	3	;52
	db	8,	3,	3	;53
	db	2,	2,	3	;54
	db	1,	3,	3	;55
	db	1,	4,	3	;56
	db	5,	5,	3	;57
	db	13,	5,	3	;58
	db	4,	2,	3	;59

	db	13,	5,	3	;60
	db	1,	2,	1	;61
	db	1,	2,	1	;62
	db	8,	3,	1	;63
	db	8,	3,	3	;64
	db	3,	3,	3	;65
	db	13,	4,	3	;66
	db	3,	3,	3	;67
	db	9,	3,	3	;68
	db	1,	2,	3	;69

	db	2,	2,	3	;70
	db	13,	2,	3	;71
	db	2,	2,	3	;72
	db	13,	6,	1	;73 *
	db	13,	6,	1	;74 *
	db	13,	6,	1	;75 *
	db	13,	6,	1	;76 * RESERVED
	db	13,	6,	1	;77 *
	db	13,	6,	1	;78 *
	db	13,	6,	1	;79 *

	db	12,	2,	2	;80
	db	13,	6,	1	;81 * RESERVED
	db	13,	3,	2	;82
	db	13,	5,	1	;83
	db	1,	4,	3	;84
	db	12,	6,	3	;85
	db	3,	3,	3	;86
	db	9,	3,	3	;87
	db	5,	4,	3	;88
	db	12h,	21h,	99h	;89 TEST

	page
;-----------------------------------------------------------------------;
; Returns additional error information, such as the error class, locus, ;
; and recommended action.						;
;									;
;  On Entry:								;
;	TBX = version (should always be 0)				;
;									;
;  On Exit:								;
;	TAX = Extended error						;
;	TBH = Error class						;
;	TBL = Suggested action						;
;	TCH = Locus							;
;	TES:TDI -> Disk volume label					;
;									;
;	No Global data affected 					;
;	No Global procedures called					;
;-----------------------------------------------------------------------;
	public	mosfun59
	assume	cs:mos,ds:grp,ss:tcb,es:nothing
mosfun59:
	mov	al,[tcberrcod]	; Novell may plug in invalid # here to 
				;  flag their error codes
	mov	[TAL],al	; Return to user
	xor	ah,ah
	mov	[TAH],ah	; Clear AH
	mov	bx,ax
	shl	bx,1			; BX *2
	add	bx,ax			; BX = code * 3
	mov	al,[fun59tbl+bx+0]	; Get Class
	mov	[TBH],al		; Return to user
	mov	al,[fun59tbl+bx+1]	; Get Action
	mov	[TBL],al		; Return to user
	mov	al,[fun59tbl+bx+2]	; Get Locus
	mov	[TCH],al		; Return to user
	les	di,[tcberrvol]		; Get pointer to volume label
	mov	[TES],es		; Return to user
	mov	[TDI],di		; "     "
	and	[TFLAG],NOT CARRY	; Make sure carry cleared
	ret
;---------------------------------------------------------------------------
;  Functions 65 and 66 currently deal with Code Pages for International
;  Support.  MOS does not currently implement code pages, so these
;  two functions are presently unsupported.
;---------------------------------------------------------------------------
	public	mosfun65, mosfun66
	assume	cs:mos,ds:grp,ss:tcb,es:nothing
mosfun65:
mosfun66:
	mov	[TAX], INVALID_FUNCTION
	or	[TFLAG], CARRY
	ret
;----------------------------------------------------------------------------
;  Function 67: Set Handle Count.
;
;    This function allows for the extension of the PSP's handle table
;   allowing more than 20 file handles to be open at one time.  MOS already
;   supports more than 20 open file handles through the mechanism of the
;   TFB (Task File Block) chain which is only limited by the amount of heap
;   memory currently available.  This function is provided solely for 
;   compatibility reasons.
;
;	Input:
;		AH = 67h
;		BX = New maximum PSP handle count. (256 maximum)
;	Output:
;		AX = Error code if CARRY bit is set.  Otherwise, no output.
;
;	Notes:
;
;     The extension of the PSP's handle table is accomplished by allocating
;   a block of memory equal to the number of handles requested in bytes and
;   copying the PSP's handle table up to the new location.  The pointer to
;   the handle table in the PSP is then modified with this new address.
;----------------------------------------------------------------------------
	public	mosfun67
	assume	cs:mos,ds:grp,ss:tcb,es:nothing

mosfun67	proc	near

	cmp	word ptr [TBX], 20	;Assigning < 20?
	ja	f67_get_block
	and	[TFLAG], NOT CARRY
	jmp short f67_exit

f67_get_block:
	mov	ah, 48h			;Allocate memory function.
	mov	bx, [TBX]		;Get new size requested.
	mov	cl, 4
	shr	bx, cl			;Convert bytes to paragraphs.
	inc	bx			;Round up to nearest whole paragraph.
	call	sim21			;Internal call to MOS.
	jnc	f67_copy_table		;If no error, go copy the table.
	or	[TFLAG], CARRY
	mov	[TAX], INSUFFICIENT_MEMORY
	jmp short f67_exit

f67_copy_table:
	mov	ds, [TCBPSP]
	mov	si, offset PSPhtbl	;PSP handle table in DS:SI
	assume	ds:PSPseg		;To access PSP variables.
	mov	es, ax			;AX got memory address from fn 48.
	xor	di, di			;Allocated block in ES:DI.
	mov	word ptr [PSPpntr], di	;Pointer moved.
	mov	word ptr [PSPpntr + 2], es
	mov	cx, [TBX]
	mov	[PSPhdls], cx		;Max handle count.
;
;	Clear the new block of memory before putting anything in it.
;
	push	di
	mov	al, 0FFh		;Free handle.
	rep	stosb			;Clear the memory. (CX already loaded)
	pop	di
;
;	Copy the old handle table from the PSP to the new location.
;
	mov	cx, 20/2		;Copy the whole PSP table.
	rep	movsw			;Copy complete.
;
;	Operation is complete.
;
	and	[TFLAG], NOT CARRY

f67_exit:
	ret

mosfun67	endp

;----------------------------------------------------------------------------
;  Function 68: Commit File
;
;   This function flushes a currently open file to disk.
;
;	Input:
;		AH = 68h
;		BX = Handle of file to commit to disk.
;	Output:
;		AX = Error code if CARRY bit is set.  (Otherwise no output)
;
;----------------------------------------------------------------------------
		public	mosfun68
		assume	cs:mos, ss:tcb, ds:nothing, es:nothing
mosfun68	proc	near

	mov	ax, INVALID_HANDLE
	cmp	[TCBTFBPF], 0		;Is there a TFB?
	je	f68_error
;
;  Trace the TFB chain until the correct one is found for the specified
;  file handle.
;
	mov	ax, INVALID_HANDLE	;Hold error code in AX.
	mov	bx, [TBX]		;Get the handle.
	mov	ds, [TCBTFBPF]		;First TFB for this TCB.
	assume	ds:tfb
f68_tfb_search:
	cmp	[TFBHDL], bx		;Match of handle yet?
	je	f68_flush_file
	cmp	[TFBNTCB], 0		;At end of chain?
	je	f68_error
	mov	ds, [TFBNTCB]		;Get next TFB for this TCB.
	jmp short f68_tfb_search
;
;   A match was found on the supplied handle.  Now, get the GFB for this
;   file and in-turn get the BDB pointed at by the GFB.
;
f68_flush_file:
	mov	ds, [TFBGFB]		;Get TFB address.
	assume	ds:gfb
	mov	ds, [GFBBDB]		;Finally, get the BDB for the file.
	assume	ds:bdb
	callmos2  mediachk		;Anyone remove the disk?
	mov	ax, WRONG_DISK
	jc	f68_error
	callmos2  flushdata		;Flush the file to disk.
	jc	f68_error		;AX will have error code if CY set.
;
;   The file flush completed successfully.
;
	and	[TFLAG], NOT CARRY
	ret

f68_error:
	or	[TFLAG], CARRY
	mov	[TAX], ax
	ret

mosfun68	endp

;-----------------------------------------------------------------------;
; Calls SCB Dword Ptr SCBFAR21 with mos segment 			;
; Simulates an INT 21 call						;
;-----------------------------------------------------------------------;
	public	sim21
	assume	cs:mos, ds:nothing
sim21	proc	near
	pushf			; save flags for simulated int 21 call
	push	cs		; save cs of return
	sub	sp, 6		; allocate space for 3 word
	push	bp		
	mov	bp, sp	
	push	ax		; save ax
	push	ds		; save dx
	pushf					; don't want to mess w/flags
	cmp	word ptr [bp+0ch],offset f4bret ; coming from open?
	jnz	userip
	mov	word ptr [bp+6],offset execopen ; put execopen as retaddr if so
	jmp	short arorip
userip:
	mov	word ptr [bp+6],offset sim21r	; else put end of routine
arorip: 			; TIP now set properly on stack for MOS
	popf			; restore modifications
	MGetSCB ds
	assume	ds:grp
	mov	ax, word ptr [scbfar21+2]	; get segment
	mov	[bp+4], ax
	mov	ax, word ptr [scbfar21] 	; get offset
	mov	[bp+2], ax
	pop	ds
	assume	ds:nothing	
	pop	ax
	pop	bp
	retf
sim21r: ret

	public	execopen
execopen:
	ret		; the file open logic uses the execopen return address
			; to detect when an exec file open call is being done.
sim21	endp

;-----------------------------------------------------------------------;
; Temporary unexpected error handler

funerr	label	near
	mov	cs:[ferrno],ax
	call	bugerror
	db	'0 Unexpected error during function #' ;@@XLAT
ferrno	dw	0,0

;-----------------------------------------------------------------------;
mosseg	ends
	end
