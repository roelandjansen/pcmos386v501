comment ^==============================================================

rules for handling tcb variables:		      as of 07/31/89

1.	all tcb variables are initialized to zero when	tcb segment
	is created.
2.	any tcb variable which needs to be initialized at addtask
	time which is non-zero and which is defined to be a constant
	before task is added should be initialized in the inittcb
	routine inside mositask.
3.	any tcb which will be saved over restart, should be save in
	saveblk (inside mosnxtsk.asm)
4.	added new variables into one of following filler areas and
	always decrementing filler counter so that all offsets remain
	constant:
	1.	fillerx area.
	2.	fillerab area.
5.	if fillers areas fill up, please create new variable right
	bellow stack area.
6.	make sure that when new variables are added to the tcb that
	word variables always line up on even address boundaries.
	there are two reasons for this:
	1.	memory fetch of word values on odd addresses require
		twice the overhead.
	2.	the structure template for microsoft c enforces word
		alignment of all word-size variables.  the c template
		of the tcb must match this file's description of the TCB
		exactly, for obvious reasons.

=======================================================================

sah 12/05/89	corrections for windows/286 2.11. tcbpsp must be at
		offset 2deh of the tcb, windows /286 with directly
		read and modified this value, by accessing function
		which must be in the tcb.  offset 2deh will work as
		long as mos support dos version 3.2 or 3.3, if mos
		supports version 4.00 we must change this offset to
		330h.  see stewart for details on windows.

bwr 12/12/89	source cleanup.

bwr 01/22/90	added buffer to support the dos 3.3 "Get Machine Name"
		function and the undocumented "Set Machine Name" function.
		also added "TCB_MALLOC_STRATEGY" for support of dos 
		function 58 (get/set memory allocation strategy).

sah 02/02/90	added tcbversn for task specific version #

SAH 01/09/91	Removed BIt 4 of TCBVRAM

SAH 01/18/91	Add TCBDDJMP1 and TCBDDJMP2 for support undocumented
		DOS device driver list

SAH 01/24/91	Remove TCBSFT nolonger needed, via changes in mosliman

BWR 03/05/91	Exchanged 16 bytes of filler area "fillerab" with
		the variables for the ddclock and the except/only
		list management variables so that the terminal
		device driver record (DDTREC) would have more space
		for changes to terminal drivers.

SAH 03/12/91	Added TCBCON417 for 40:17 management, convert unused
		tcbusrpoll into 16 bytes of filler area

mjs 03/14/91	partially reversed bwr's change of 03/05.  the ddtrec
		area now has only a net increase of 12 bytes.  
		relocating tcbactseg/preseg was too dangerous.

mjs 03/21/91	converted tcbirqmsk to fillerc
		added tcbfwake and tcbpost (for llnetbios)

mjs 03/28/91	added tcbd40f - signals intd4fun0f calling suspend
		added tcbtslnst - task specific tsl nest coutner
		(llnetbios)

SAH 04/01/91	Added TCBDPMI and TCBDPMISel for $DPMI.SYS driver I am
		currently writing, also added reservd area for tcb
		items that need to be patch.

BWR 04/02/91	Added TCB_COM_HOLD for new MOS HOLD COM command to
		allow users to reserve COM ports as they would an
		LPT port.

mjs 04/09/91	converted tcbbbsyt to filler.
		changed the initail values of tcbhold and tcb_com_hold
		to 273	(15 * 18.2)  done at bwr's request.

SAH 05/03/91	Move TCBEGAPAL to end of tcb, extended area to 20 bytes
		so supportt bios like Award's buggy video bios that
		writes 18 bytes instead of 17 bytes on INT 10 function 1009h

mjs 05/08/91	added tcb24nest.  used by flush24 and toint24 to detect
		attempted reentrance.

mjs 12/03/91	add tcbno24.  used by i21f6c to suppress int24 calls.

SAH 12/03/91	added tcbbatnm. use in mositask to store startup batch
		file name

SAH 01/10/92    Added tcb_malloc_mark to correctly implement last fit
		stuff for mcb allocation via function 58h.  I found 
		this problem though Pharlap DPMI/VCPI test suite

SAH 01/14/92	Reserved 17 bytes  for  applications use.  Compucon need
		some space for there applicationns

mjs 03/03/92	added tcbcacer and fillerz

================ 5.01 Kernel Ends Here ====================================

mjs 07/23/92	modified tcbntry and tcbttry to use the equated
		values shareretry and shareticks.  changed the
		tick count from 18 to 3 to make mos act more like
		dos.

SAH 08/31/92	Default com hold times change to 0 for default

SAH 10/23/92	Added tcblag and tcbhastimer for task specific 
		management of timer chip lagging
======================================================================^

shareretry equ	3			; retries for sharing violation
shareticks equ	3			; timer ticks between retries


;==== tcb prefix

tcbstart   label byte
		db	0	; reserved
tcbtype		db	0	; 'T' indicates a tcb
		db	6 dup(0) ; reserved
tcbtcbpn	dw	0	; pointer to next tcb
tcbtcbpp	dw	0	; pointer to previous tcb
		db	4 dup(0) ; reserved

;==== general task data

; the offset within the tcb of tcbid and tcbcnadr is hard coded into
; the file moxmem.asm so any changes to this file which would affect
; these offsets must include a corresponding change in moxmem.asm

tcbid		dw	0	; task id
tcbncadr	dw	0	; native context save address
tcbbegad	dw	0	; partition start address
tcbendad	dw	0	; partition end address
tcbpri		db	2	; task priority
tcbslice	db	1	; time slice (in ticks) for partition
tcbwait		db	0	; partition wait flags.
				; bit 0 = set if in wait state
				; bit 1 = set when wait has been resolved
				; bit 2 = set indicates to call poller.
				; bit 3 = 1
				; bits 4 - 7 currently undefined.
tcbstat		db	0	; indicates what task is waiting on.
tcbpoll		dd	0	; address of polling routine to resolve wait.

;  note:  the polling routine returns a status in the al register
;	  as outlined below.
;
;		al = 0	wait condition was resolved.
;		al = 1	waiting on keyboard input.
;		al = 2	waiting on serial input.
;		al = 3	waiting for timer.
;		al = 4	waiting to access a file.
;		al = 5	waiting to lock a record.
;		al = 6	for key status looper.
;		al = 7	to print a character.

tcberrcod	db	0	; error code returned from last mos function
tcbprgnm	db	11 dup(0) ; program name

;note:	tcbprgnm is also used by mositask to hold the entry parameter's
;	ds:si which points to the startup batch file string.

;=== keyboard data

tcbibase	dw	200h	; base address of keyboard buffer
tcbibsiz	dw	128	; keyboard buffer size (in bytes)
tcbloop		db	0	; bit 0 set indicates dis mode
tcbkshft	db	0	; current state of keyboard shifts & toggles
tcbkshf2	db	0	; auxilliary keyboard shift state
		db	0	; preserve offsets of other vars.

;=== video data

tcbmode		db	?	; current video mode
tcbpage		db	?	; current video page
tcbcols		db	?	; number of text columns per screen
tcbrows		db	?	; number of text rows per screen
tcbscln		dw	?	; length of video buffer
tcbpgln		dw	?	; page length
tcbpgst		dw	?	; page start address
tcbcpos		dw	4 dup(?) ; cursor positions for the 4 pages
		dw	4 dup (?) ; unused
tcbctyp		dw	?	; current cursor type
tcbpal		db	?	; current palette setting
tcbomode	db	0	; video mode originally assigned to partition
tcbwinpo	db	0	; top crt row number (0 or 1)
tcbvram		db	?	; video ram state bits
				; bit 0 = set if vidram is active
				; bit 1 ** reserved **
				; bit 2 ** reserved ** (> 4.10)
				; bit 3 = set if ali (sunriver) ff calls
				; bit 4 = set if herc. mode supported
				; bit 5 = set if color supported
				; bit 6 = cga graphics supported
				; bit 7 = tcbcondd is the master console
tcbvidh1	dw	0	; handle of video save area
tcbvidp1	dw	0	; page count of video save area
tcbvidw2	dw	0	; address of video work area 2 (vidram)

;==== file i/o data

tcbtfbpf	dw	0	; pointer to 1st task file block (tfb)
tcbcdbpf	dw	0	; pointer to 1st current directory block (cdb)
tcbcdbpc	dw	0	; pointer to cdb for current drive
tcbndriv	db	0	; number of drives
tcbcdriv	db	0	; current drive. (0=a, 1=b ... )
tcbdta		dw	2 dup(0) ; dta address
tcboldpsp	dw	0	; psp of current process for task
tcboldmbpf	dw	0	; pointer to 1st memory block prefix
tcbvflg		db	0	; nz if verify is set to on for this task
tcbbrk		db	0	; nz if break is set to on for this task
tcbntry		dw	shareretry ; # of retries to attempt for share/lock vio.
tcbttry		dw	shareticks ; tick interval between retries.

;==== printer data

tcbauxbt	db	10h	; flags for remote printer as outlined below:
				; bit 0 - lpt1 to remote
				; bit 1 - lpt2 to remote
				; bit 2 - lpt3 to remote
				; bit 3 - <esc> to printer is pending.
				; bit 4 - xon/xof protocol. (1 is default)
				; bit 5 - etx/ack protocol.
				; bit 6 - waiting for ack or xon
				; bit 7 - transparent print mode active.
tcbauxct	db	64	; dynamic count for etx/ack
tcbspltm	dw	0	; timer value for spooler close
tcbspool	dw	0	; segment address of spooler data buffer
tcblptxl	db	3 dup (0) ; printer redirection flags
				; 0	   = no redirection
				; 1-24	   = com port to redirect to
				; 81-83	   = printer port to redirect to
		db	0	; for address alignment.

;==== non-publicized task stuff

tcbclass	db	0	; task class
tcbuser		db	4 dup(0) ; user id for this task
tcbcdft		db	0	; default file creation class

;   the class permission map is a bit map with 2-bits mapped for each
;  of the 26 classes. (a - z).	the values are assigned as follows:
;
;  value		  partition		dir & file
;  -----		  ---------		----------
;    0 - access denied	  no access		no access
;    1 - execute only	  view only		execute only
;    2 - read		  view only		execute + read
;    3 - write		  view + supply keys	all file operations

tcbcmap		db	7 dup(0aah) ; class permission map for task.
				; (26*2 + 7)/8 dup(0aah)
even
tcbctxp		dw	0	; pointer to context save area.
				; (zero if memory management available)
tcbsp		dw	tcb:tcbstack ; save stack pointer here
tcbstkp		dw	tcbstack ; top of current stack
tcbsvsp		dw	0	; mos's SP placed here on switch to user stack
				; during interrupt handling.
tcblagcnt	dd	0	; last timer count when an application
				; handler intercepts int8 or int 1c.
tcbmmhdl	dw	4 dup (0) ; memman handles
tcbmmpgs	dw	4 dup (0) ; # of pages for above handles
tcbvmhdl	dw	2 dup (0) ; memman handle for video space
tcbvmpgs	dw	2 dup (0) ; # of pages for above handles
tcbems		dw	0	; ems save area address (if present)
tcb87sav	dw	0	; 8087 save area
tcbpritm	dw	0	; low order word of timer containing the
				; time when this task was last selected.
tcbmcount	dd	0	; generic mouse buffer pointer
tcbwtax		dw	0	; save space for timed wait logic timer check
tcbwtcx		dw	0
tcbwinfo	dw	0	; pointer to wait information block
tcbwtflg	db	0	; timer wrap around flag for various routines.
				; bit 0 = task selection logic
				; bit 1 = spooler logic (has own save space)
				; bit 2 = timed wait logic
				; bit 3 = general wait logic
				; bit 4 = dis mode time out in mosi16 fun 01
				; bit 5 = int 15 disk busy task switching
				; bit 6 = chk_bdbgate/bdbpoll
tcbcamon	db	0	; bit 0 = carrier monitor switch
tcbbaseg	dw	0	; basic segment from 0:510
tcberrvol	dd	0	; volume id if appropriate to mos error
tcbretc		dw	0	; return code functions 4c, 31, and 4d
tcbapv0a	dw	2 dup(0) ; application int0a (irq2)
				; (on at's, int 71 -> int A)
tcbapv0b	dw	2 dup(0) ; application int0b (irq3)
tcbapv0c	dw	2 dup(0) ; application int0c (irq4)
tcbapv0d	dw	2 dup(0) ; application int0d (irq5)
tcbapv0e	dw	2 dup(0) ; application int0e (irq6)
tcbapv0f	dw	2 dup(0) ; application int0f (irq7)
tcbapv70	dw	2 dup(0) ; application int70 (irq8)
tcbapv71	dw	2 dup(0) ; application int71 (irq9)
				; (on at's, int 71 -> int A)
tcbapv72	dw	2 dup(0) ; application int72 (irq10)
tcbapv73	dw	2 dup(0) ; application int73 (irq11)
tcbapv74	dw	2 dup(0) ; application int74 (irq12)
tcbapv75	dw	2 dup(0) ; application int75 (irq13)
tcbapv76	dw	2 dup(0) ; application int76 (irq14)
tcbapv77	dw	2 dup(0) ; application int77 (irq15)

;==== non-publicized keyboard stuff

tcbkbcnt	db	0	; to optimize test-keyboard logic
tcbkbfst	db	5	; max fast int 16 calls in a row
tcbkbfct	db	0	; number of fast calls already
tcbkbmax	db	8	; max count for tcbkbcnt
tcbkbax		dw	0	; ax value for mosi16 function 1 time out
tcbkbcx		dw	0	; cx value for mosi16 function 1 time out
tcbkbtck	dw	18	; timer ticks for mosi16 function 1 time out
tcbkeyrdy	dd	0	; keys in buffer flag for this console
tcbnxtdd	dw	0	; next partition looking at pam screen
tcbscrdd	dw	0	; first partition also looking at this screen
tcbaltnum	db	0,0	; current accumulation of alt-num pad keys
tcbktggl	db	0	; current shift state of toggle keys
tcbkbctl	db	0	; type of keyboard and foreign/us handling
tcblastky	dw	0	; for accent shift code in mosint16
tcblscan	db	0	; remember last scan code
				; (for key seq prefixes)
tcbalt999	db	0	; set if in pam mode on numeric pad
tcbi9seg	dw	0	; visual tcb for mosint09's call to DECODESCAN
tcbi9flg	db	0	; upon entry to the routine decodescan
				; this flag causes the call to keyclasschk
				; to be skipped.  getddkeys uses this flag
				; to indicate that moskey should be called.
tcbmoskey	db	0	; used to pass the pam # from decodescan to
				; moskeys
tcbtrapcd	db	0	; code to be used when 386 driver traps an
				; "IN AL,60" instruction.
tcbprt61	db	20h	; used in mosint06 to simulate i/o with
				; port 61h
tcbfsavr	db	'N'	; short pass-through flag for mossaver
tcbnoget	db	0	; flag to cause getkeys to be skipped.
				; (quickbasic/hospec)

;==== non-publicized video stuff

tcbvrtim	dw	0	; timer value for vidram logic.
tcbptmr		dw	?	; slice of last timer polling for this tcb
tcbcmode	db	?	; current mode for terminal
tcbega		db	0	; ega/vga video state control
				; bit 0 - set if in ega or vga mode.
				; bit 1 - set if not ok to pam during getkeys.
				; bit 2 - set to suspend because of state pam
				; bit 3 - set if ega has < 256k memory

;==== non-publicized printer stuff

tcbspskp	db	'N'	; prevents recursion in spooler logic
tcbprndx	db	0	; printer index 0-2 for int 17
tcbprprt	dw	0	; printer port in int 17 logic
tcbtoax		dw	0	; save ax for int17 timeout testing
tcbtocx		dw	0	; save cx for int17 timeout testing
tcbauxtm	dw	0	; timer at last auxoff or 0 if inactive
tcbspltp	dw	40	; timer for spooler close poll routine
tcbspltc	dw	40	; tick count for poll routine recycle

;==== miscellaneous non-publicized stuff

tcbllser	dw	0	; lanlink satellite serial number

; the following data area is used by the console device driver.	 all
; of the labels start with tcb$.  this information is initialized in
; mositask.

tcb$hdr		dw	2 dup(0) ; pointer to device header
tcb$ca		db	7	; current attribute
tcb$asi		db	'Y'	; ansi mode of operation (or not)
tcb$iq		db	0	; used to evaluate quotations
tcb$ef		db	'N'	; flags pending esc seqence
tcb$tcp		dw	0	; temporary cursor position
tcb$kp		db	'N'	; flaging extended key pressed
tcb$hb		db	0	; holding buffer for extended key
tcb$er		dw	0	; next routine to process esc sequence
tcb$ebp		dw	0	; buffer pointer for esc sequences
tcb$eb		db	60 dup(0) ; esc sequence buffer

; the following data area is used by the mosdevs device driver

tcbdevhdr	dw	2 dup(0) ; temporary header pointer
tcbdnum		db	0	; device number
tcbpcnt		db	0	; number of printers installed

; the following data area is used by the mosmiman cooking module
; all of the labels start with tcb.

tcbconfg	db	1bh	; init for func 3f cooked mode

; bit	 meaning (if = 1)
; ---	-------------------
;  0	echo and expand tabs
;  1	wait for a charactor
;  2	return when requested bytes have been entered
;	and return extended function key codes
;  3	use 128 bytes as minimum buffer size
;  4	act on control keys ^c, ^p, ^s

tcb%ebuf	db	255 dup(0) ; edit buffer. (use for both 0a and 3f)
tcb%ecol	dw	0	; edit column 1-128
tcb%blen	dw	0	; buffer length 0-127
tcbtsk38	dd	0	; task specific copy of scbfar38
tcbparm2e	db	14 dup (0) ; area used for int 2e parameters
tcborig8	dw	0,0	; original int8 vector when this task
				; was started
tcborig1c	dw	0,0	; original int1c vector when this task
				; was started
tcbmready	dd	0	; pointer to mouse input ready flag
tcbcrit24	db	0	; flags int24 is critical or cosmetic
tcbhold		dw	3 dup (273) ; lpt port hold ticks, indexed by
				; printer number.
tcbpscan	db	0	; scan code previous to tcblscan
tcblocker	db	0	; numlock errors calculated on extended cursor keys
tcbslcnt	db	0	; this is each task's slice counter
tcb_machine_name db	15 dup (' '), 0
tcb_machine_id	dw	?
tcb_malloc_strategy dw	0	; memory allocation strategy.
				; 0 = first fit.
				; 1 = best fit.
				; 2 = last fit.
tcbversn	dw	0	; task specific dos version #
tcb15ax		dw	0	; ax value for timchk in i15suspend
tcb15cx		dw	0	; cx value for timchk in i15suspend
tcbbbsy		db	0	; original scbbdbbsy when enter toint24
tcbdbsy		db	0	; original scbdrbsy when enter toint24
tcbiretry	db	0	; bit map of infinate retry printer ports
				; bit 0 : 1 means infinate retry for LPT1
				; bit 1 : 1 means infinate retry for LPT2
				; bit 2 : 1 means infinate retry for LPT3
filler		db	0
tcbin10		db	0	; flag to indicate that we are currently
				; inside int 10 bios, for re-entrency
tcb13once	db	0	; once flag for int13 regrab in mossaver
tcboclass	db	0	; original start up class for task
tcbodriv	db	0	; original boot drive for task
tcbrstok	db	0	; ok to process a restart on this task
tcbkbrate	db	0	; task specific kybd repeat rate
tcbkbcmd	db	0	; last command written to port 60
tcbkbstg	db	0	; maintains sync for two step kybd commands

tcb15supr	db	0	; enables writeguts to suppress int15 tsl
tcbconly	db	1	; != 0 if the only watcher is a con-only wks
tcbtctst	db	0	; holds trapped value for cursor type
tcbtctnd	db	0	; holds trapped value for cursor type

tcbpspoff = ($-tcbstart)

if tcbpspoff ne 2deh
	.err
	%out	tcb must be at offset 2deh for windows/286 2.11
endif


tcbpsp		dw	0	; psp of task, must be at offset 2deh of tcb
				; this will apply to version 3.00-3.30 of dos
tcbtext2e	db	129 dup (0) ; area used for int 2e command processing
tcbnest13	db	0	; nest level for int13 regrab logic
tcbchn13	dd	5 dup(0) ; storage for 5 levels of int13 intercepts
tcbbdbwf	db	0	; != 0 means task waiting on bdb too long
tcbdbwax	dw	0	; for timchk in bdbpoll
tcbdbwcx	dw	0	; for timchk in bdbpoll
tcbcon417	db	0	; task specifc 40:17 management
tcbd40f		db	0	; signal from intd40f to tsl (llnetbios)
tcbtslnst	db	0	; task specific tsl nest counter (llnetbios)
tcb24nest	db	0	; detects attempted int24 reentrance 

; following data used by mosddclk

tcbchdr		dw	2 dup(0) ; pointer to device header.
tcbcday		dw	0	; day counter
tcbsav24	dw	0	; pointer to heap block where stack
				; is copied during an int24h call.
tcbhdl24	dw	0	; store first 2 handles here during int24h
tcbtpfrm	dw	0	; mossaver puts bp here

tcbpost		dd	0	; netbios post vector

; note: the following data must stay in this order.

tcb%sb0a	db	512 dup(0) ; save buffer area for func. 0a
topsb0a		label	byte
		db	?	; for periscope

tcb%rs0a	dw	0	; root size for 0a
tcb%rp0a	dw	0	; root pointer for 0a
tcb%cp0a	dw	0	; current pointer for 0a
tcb%rs3f	dw	0	; root size for 3f
tcb%rp3f	dw	0	; root pointer for 3f
tcb%cp3f	dw	0	; current pointer for 3f

; note: the above data must stay in the present order.

tcb%dbuf	db	8 dup(0) ; buffer for dispchar
tcb%cbot	db	0	; bottom line of cusor (12 mono, 7 cga)
tcb%stcl	db	0	; starting column
tcb%nstln	db	0	; starting line
tcb%lref	db	0	; highest line for updstln
tcb%maxc	db	0	; highest column
tcb%maxl	db	0	; highest line
tcb%dlen	dw	0	; length of display line
tcb%ltc		dw	0	; last tab expansion count
tcb%ttc		dw	0	; total tab count
tcb%nmxb	dw	0	; max buffer length
tcb%stgc	dw	0	; staging counter for wrap detection calcs
tcb%insf	db	0	; insert flag 0ffh = insert mode active
tcb%flgs	db	0	; miscellaneous flags
				; bit 0 - last command = up
				; bit 1 = last command = down
				; bit 2 = echo to printer.
				; bit 3 = call delupd
				; bit 4 = add line feed code
				; bit 5 = ignore bit 2 (printer echo)

; end mosmiman data



; the following data area is used by mosint21 to manage control-c.

tcbbrkfg	db	0	; bit 0 - ctrl-c detected.
				; bit 1 - ignore any ctrl-c's detected.
				; bit 2 - getkeys used to manage pam key 0.
				;	 (ctrl-break)
				; bit 3 - already in getkeys procedure.
				; bit 4 - process ctrl-numlock
				; bit 5 - spool error reported once.
				; bit 6 - getddkeys should skip alt-num
				;	 monitor.
				; bit 7 - process shift-print-screen
tcbnest		db	0	; counter to manage control-c when re-entrant
tcborgsp	dw	0	; save area for sp just before int 23
tcbsreg		dw	11 dup(0) ; save area for original users registers.
				; will need them if get an iret from int23

; end mosint21 data (for control-c)

; -> below until endddcon is passed to ddt'S
;    the first 5 words must remain the same, the length must remain
;    at least xx bytes

tcbcondd	dd	0	; console terminal for this partition
tcbdlofs	dw	0	; offset of logical screen
tcbdlseg	dw	0	; segment of logical screen
tcbdcofs	dw	0	; cursor offset within page
tcbdcol		db	0	; screen cols/row passed to ddt
tcbport		dw	0	; asynch port #
tcbbaud		dd	0	; baud rate
		db	31 dup(0) ; space used by ddt's

; note: the order of the above table must remain as-is.
;
;

; data for +except/+only list management

tcbpreseg	dw	0	; first stage pointer for +except/+only
tcbactseg	dw	0	; second stage pointer for +except/+only

tcb%sb3f	db	258 dup(0) ; save buffer area for fun 3f
topsb3f		label	byte
tcbmport	dw	 0	; generic mouse port
tcbmtimer	dw	 0	; generic mouse efficient timer for windows
tcbmouse	db	'N'	; 'Y' to indicate generic mouse support
tcbupoll	dd	0	; user poll routine address.
				; (to be called at task switch)
tcbparnt	dw	0	; tcb of parent(originating) task
tcbautoe	db	72 dup (?) ; startup file. (autoexec.bat)
tcbshare	db	'Y'	; indicate share. (int 2f)
tcbflimit	db	'N'	; limit files to psp maximum?
tcblock		db	0	; temp variable used by findrlb
tcbdpmi		dw	0	; dpmi control segment	($dpmi.sys)
tcbdpmisel	dw	0	; dpmi control selector ($dpmi.sys)
TCBBATNM	dd	0	; Start up Batch file location
tcb_malloc_mark dw	0	; use by function 48
tcbcacer	db	0	; singals moxcpcor's i24 handler of cache error
tcblag		db	0	; non-zero if task int 8 is lagging
tcbhastimer	db	0	; non-zero means task has task specific timer
fillerx		db	3 dup (0) ; filler area
tcbirqcnt	db	0	; non-zero if to use short form of irq's
tcbcrit		db	0	; dos critical flag for function 5d06h
				; (sidekick plus)
tcbstation	db	0	;  console type for station
				; 0 = monochrome only
				; 1 = cga
				; 2 = ega
				; 3 = vga
				; 4 = hercules
				; 5 = monochrome ega
				; 6 = monochrome vga
tcbtsrflg	db	0	; tsr flag (if 'Y' skip int28 waiting)
tcbvidad	dw	0	; if terminal is master console, this holds
				; the display buffer address
tcbaltac	db	0	; accumulator used for shadow altnum pad
				; monitoring. (when there is a total int9
				; takeover)
tcbaltacf	db	0	; 'Accumlator in use' flag for shadow num pad
				; scheme
tcbaltdn	db	0	; flag to signal the alt key is down.
				; (shadow scheme)
tcbnest9	db	0	; nest level for int9 regrab logic
tcbchn9		dd	5 dup(0) ; storage for 5 levels of int9 intercepts
tcbnest8	db	0	; nest level for int8 regrab logic
tcbchn8		dd	5 dup(0) ; storage for 5 levels of int8 intercepts
tcbfwake	db	0	; force awake flag (netbios)
tcbsiorb	db	0	; task waiting on serial i/o to complete
tcbsafe28	db	'N'	; flag if it safe to to int28, only do this
				; during function 01 to 0ch
tcbvidset	dd	0	; far pointer to video setup routine
				; for initialization of video on terminal
tcbunreg	dd	0	; far pointer to un-register routine for
				; removing a task with a terminal driver.
				; note:	 tcbl43 must follow this tcbunreg
				; this is because #9 depends on this offset.
tcbl43		db	0	; last command code trapped to port 43
tcbl40		dw	0	; last data word trapped to port 40 (twice)
tcbpamfg	db	0	; flags for pamswitching:
				; bit 0 set = force vidram in switchgp
				; bit 1 used internally in pamswitching.
even

;==== all new additions must be made after this point

tcbpripn	dw	0	; link to next task in priority order
tcbcntxpt	dw	0	; page # of context block. (mm)
				; when no mm, stores segment of
				; smp context block.
tcbt3x4		db	0	; trapped crt controler index 3b4 or 3d4
tcbtchigh	db	0	; trapped crt controler high pos 3b5 index 0e
tcbtclow	db	0	; trapped crt controler low pos 3b5 index 0f
tcbcount	dw	0	; access counter # of times switch in
tcbexec3d	db	0	; flag, set/reset by exec, causes openfile to
				; adjust to the current sharing/compatibility
				; mode rather than failing.

;==== following changes are made after mos 1.02 release

tcbopen60	dd	0	; last open call ds:dx used by function 3dh
				; this call is used by function 60h rm-cobol
tcbstate	dw	0	; vga (possibility of ega state area segment)
				; 0 means that state logic is not being used.
tcbuserarea	db	17 dup(0) ; *** RESERVED for user's application
tcbvideo	db	 0	; video installed on system
				; bit 0 - monochrome
				; bit 1 - cga
				; bit 2 - ega
				; bit 3 - vga
				; bit 4 - hg1
				; bit 5 - hg2
				; bit 6-7 reserved
tcbattend	dd	0	; timer value when suspended task was last
				; attended.
tcbirqpn	dw	6 dup(0) ; table for irq2-7, next pointers in linked
				; lists of tasks which have an irq intercept
tcbirqsec	db	0	; bit flags for irq2-7, when set, the corres-
				; ponding vector points to the 2nd handler
tcbwpend	db	0	; bit flags for irq2-7, means to pop
				; up window reporting an ambiguous irq.
tcbpam		db	'N'	; flag to indicate if paming is ok.
tcbcrtio	db	'Y'	; crt control i/o trapping
				; 'Y' enabled
				; 'N' disable - output al to port dx
tcb03b8		db	08h	; last output to port 03b8
tcb03bf		db	00h	; last output to port 03bf
tcbtccnt	db	00h	; count of outs to 6845 cursor position regs
tcbswflg	db	'N'	; switch flag for getkeys
tcbswitch	db	00h	; switch value for getkeys
tcbbpcnt	db	0	; counter for managing tasks which need
				; background printing.
tcblsttl	dw	0	; lsb of timer for reference in int17
tcbkbansi	dw	0	; ansi.sys emulation pointer to 64 byte buffer
tcbkbanlow	db	0	; ansi.sys low temporary ansi value
tcbkbanhi	db	0	; ansi.sys high temporary ansi value
tcbkboff	dw	-1	; ansi.sys keyboard offset to key re-assigment
tcbemsseg	dw	0	; $EMS 4.0 Task Specific Data Segment
tcbddjmp1	db	5 dup (0) ; Far JMP for NUL stradegy routine
tcbddjmp2	db	5 dup (0) ; Far JMP for NUL interrupt routine

; post pc-mos 4.00 variables start here

tcbreboot	db	0	; non-zero to disable reboot.

; pc-mos 4.00 variable start here

tcbwatch	dw	0	; tcb the wks is watching (for getkeys)
tcbansi		db	0	; non-zero means that task supports ansi
tcbdidkey	db	0	; bit map of last 8 slices (each bit 1 if
				; int 16h get key called or if kb suspended)
tcb$wrap	db	'Y'	; indicates if wrapping is using ansi
tcbinmos	db	0,0	; task specific inmos flag for resident progs
tcb28cnt	dw	0	; int 28 staging counter, use for setting
				; correct value of inmos flag
tcb28timer	db	0	; efficiency counter, use in mosint28
tcbequip	db	0	; equipment flags on task boot up.

tcbflush	db	0	; 'Y' if error for uob owned by this tcb
				; during a polled flush
tcb3c2		db	0	; last output value to 3c2 while this task
				; was scbtcbpc

;------------------- dos variable area ------------------------------
; this area contains variables which correspond, more or
; less exactly, with the variable table to which dos
; int 21h function 52h returns a pointer.  these variables
; are needed specifically by code to support the irma
; software and the mountain bernoulli device driver.
;
; this area added 11/17/87 by jsm
; update 08/24/88 sah with pointers to clk and con device
; for ms windows (not actually known to be used) also added
; pointer to system file table which windows actually uses.
; Update 01/22/91 SAH, lastdrive field was added
;--------------------------------------------------------------------


tcbmbpf		dw	0	; tb - 2 pointer to 1st memory block prefix
tcbdpbpf	dd	-1	; tb + 0  base of dpb chain
tcbsftptr	dd	0	; tb + 4  pointer to system file table
tcbclkdev	dd	0	; tb + 08 pointer to clock device
tcbcondev	dd	0	; tb + 0c pointer to std console device
tcbsecsiz	dw	512	; tb + 10h sector size for disk i/o
tcbdpbpo	dd	?	; tb + 12h another dpb pointer?
tcbdinfo	dd	?	; tb + 16h drive information
tcbfcbptr	dd	?	; tb + 1ah fcb sft pointer
		db	3 dup (?) ; tb + 1eh - tb + 20h unknown
tcblastdrv	db	?	; tb + 21h Last Drive
tcbddpf		dd	-1	; tb + 22h pointer to first device driver
		db	1ch dup (?) ; tb + 26h - tb + 35h (Nul Device)
		db	0ch dup (?) ; tb + 36h - tb + 3fh unknown

;----------------- New Items go here ---------------------------------;

tcb_com_hold	dw	24 dup (0) ; hold times for com ports.
tcbegapal	db	20 dup(0) ; storage area for ega/vga palletes
tcbno24		db	0	; suppress i24 for i21f6c

fillerz		db	16 dup (0) ; filler area

;----------------------------- stack --------------------------------
;	stack must always be the last item in the tcb, this is
;	to allow for variable size stacks.
;--------------------------------------------------------------------

stksiz		equ	1500
tcbminstk	db	stksiz dup(0)
tcbstack	label	word	 ; * end of stack

;==== end of tcb

tcblen		 equ   $-tcbstart

ddtrec struc
		dd	?
logscr		dd	?
crsofs		dw	?
cols		db	?
port		dw	?
baud		dd	?
dcpherc		db	?	; no hercules graphics (must be @ mcvars)
dcmode		db	?	; current physical mode
dcvmode		db	?	; what was last set by mos
dcpcrs		dw	?
dcpcol		db	?
dcaddr		dw	?
dcpscr		dw	?
dcpscrl		dw	?
dcbios		db	?
dcsnow		db	?
ddtrec ends

