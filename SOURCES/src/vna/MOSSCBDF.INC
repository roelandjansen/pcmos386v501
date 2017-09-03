comment ^==============================================================

        Module name:		mosscbdf.inc

        Creation date:		sometime in the distant past!

        Revision date:		03/01/91

        Author: 		????

        Description:		System control block definition.


	      (c) Copyright 1990, 1991 The Software Link, Inc.
                        All Rights Reserved.

=======================================================================

bwr 1/30/90	dos version is now 3.30

bwr 2/01/90	temporary reassignment of version level to
		3.20 until problem with windows can be solved.

mjs 05/10/90	added scbirqdxx and cleaned up module

SAH 10/10/90	Added ScbNoRst to control Restarting for Novell

SAH 11/01/90	Added SCBSAVE and SCBRESTORE for saving restoring
		EMS 4.0 Contexts

SAH 01/10/91	Init SCBI15ITA to 1 so mosinit code will not have
		dbs logic active 

SAH 01/16/91	Place 8 bytes of data which Intel's fax scans for
		to get pointer to DOS's critical flag

SAH 01/30/91	Added SCB15TCB for currented TCB inside INT 15
		Disk Busy suspension logic

SAH 03/01/91	Move 8 bytes for Intel's fax to after SCBINMOS

SAH 03/12/91	Added SCBCON417 for DDTMC management of 40:7

mjs 03/21/91	added scbpost for netbios

BWR 3/27/91     Added variables to handle new MOS HOLD for COM
                ports.

SAH 03/27/91	Added SCBKBBIOS flag ('N') means old style, 40:17 is
		not supported

mjs 04/09/91	added scbdrtcb to enable toint24 logic to track the
		task in the todriver gate.

SAH 05/29/91	added scbnoslc for controlling  chkslice routine.
		this is necessary by novell shell for PC-MOS

SAH 09/11/91    Removed SCBOLD?? which is no longer being used, converted
		area into 1 dword SCBI10OLD which contains pointer to
		i10old (dword pointer to orginal INT 10 Vector) and 26
		filler bytes, also added scbldrive for lastdrive support

mjs 10/07/91	fix dbts/prtsc bugs (patch410.118).
		renamed scbi15ita to scbi15off.  this is now a
		general purpose var to temporarily turn off dbts.

mjs 12/16/91	dlg mods: changed scbversn from 3.20 to 5.00.

mjs 03/18/92	added scbvdrflg and scbdopflg to control reentrance
		into suspend when vidram and dopoll are called from
		within suspend.

SAH 03/23/92	Added scbdosver which stores the default dos version

mjs 09/23/92	mosinit overhaul.
		added scbfree, scbgrpend, scbmo2adr

SAH 09/25/92    remove page statement out so printouts will be correct
======================================================================^

scb	label	byte

public scbtcbpf, scbtcbpl, scbbdbpf, scbbdbpl, scbgfbpf, scbgfbpl
public scbdbbpf, scbdbbpl,scbcntxt, scbctxsz, scbslice, scbnotsl, scbnoslc
public scbtcbpc, scbtcbpv, scbtcbps, scbtcbvr, scbmouss, scbmousp
public scbidq2, scbidq3, scbidq4, scbidq5, scbidq6, scbidq7, scborg38
public scbvcuty, scbvcupo, scbauxtm, scbconsz, scbvidad, scbtcbn, scbversn
public scbmmhan, scbmmptr, scbmmsub, scbmmfea, scbmmfe2, scbhp2siz
public scbmmgrn, scbmmmod, scbmmerr, scbmm6ad, scbmmscb, scb15tcb, scbi10old
public scbmmfg, scbaltf1, scbspltm, scblowpr, scbvmode, scbhp2adr
public scbswvq, scbsw87, scbswali, scbswaf9, scbhpadr, scbhpsiz, scbbufsz
public scbshell, scbcntry, scbcursz, scbcurad, scbavsiz, scbdrivs, scbnoswt
public scbinirq, scbin08, scb13buf, scbtskfg, scbdrvr, scbsmplow, scbldrive
public scbstdin, scbstdout, scbstdnul, scbstdclk, scbstdprn, scbstdaux
public scbdbblen, scbdebug, scbdbprt, scbvrwait, scbmastv, scbkey, scbmosend
public scbmosadr, mos1ad, scbusrf, scbhwcl, scblen, scbfar21, scbreg32
public scbcurcnt, scbcurwrp, scbhldss, scbbuff, scbdemo, scbsdemo, scbinsave
public scbpripf, scbctxsz, scbscang, scbcin24, scbtcbvs, scbcpseg, scbvtype
public scbcpsiz, scbfar38, scbvidpg, scbmastp, scbhp1alc, scbdemo2
public scbhpalc, scbirqpf, scbinmos, scbtimer, scbtimerh, scbkbbios
public scbboot, scbmsgseg, scbttrap1, scbttrap2, scb286dec, scbidqp
public scbvsahdl, scbvsacnt, scbvmahdl, scbvmacnt, scbvmaseg, scb4013
public scbmapvmf, scbmapvsf, scbvmaal, scbvsaal, scbcwrl, scbcwl
public scbcuob, scbcbk, scbcnum, scbck, scbcsysk, scbcwrf, scbcwf
public scbcupf, scbchdl, scbclst, scbccur, scbcmtr, scbcd, scbcele
public scbcach, scbflush, scbcsave, scbcnxt, scbcseg, scbcsegp,scbioptr
public scbcwsys, scbcwmax, scbcwnum, scbcbits, scbcbmsz, scbcbmap
public scblastff, scbmo2end, scbdump, scbcntflg, scbinswgp, scbbootdrv
public scbvidchk, scbvnasys, scbpktio, scbcrit, scbrstcnt, scbmuser
public scbcclr, scbcbdb, scbmoutcb, scbmouse, scbmouval, scbin74
public scbrstrtp, scbrstrtc, scbcall74, scbbankin, scbslfact, scbslcnt
public scbhold, scbhldtick, scbhldtock, scbhldtask, scbhldlen, SCBRESTORE
public scbclbx, scbclcx, scbclbdb, scbclsct, scbclseg, scbsmsg, scbupoll
public scbdrbsy, scbi15tsl, scb13bsy, scb13sk1, scb13eoc, scb15post
public scb15act, scbflonce, scbbdbbsy, scbbsytcb, scbtfix1, scbtfix2
public scblastw1, scblastw2, scbrdriv, scbirqd0a, scbirqd0b, scbirqd0c
public scbirqd0d, scbirqd0e, scbirqd0f, scbinit, scbirqbnk, SCBSAVE, scbcon417
public scbkbrate, scbout60, scbin60, scbmconly, scbi15off, scbnorst
public scbpost, SCB_COM_owner, SCB_COM_timeout, scbdrtcb, scbnoi5
public scbvdrflg, scbdopflg, scbdosver, scbfree, scbmo2adr, scbgrpend

scbtcbpf	dw	0	;* pointer to first task control block
scbtcbpl	dw	0	;* pointer to last tcb
scbbdbpf	dw	0	;* pointer to first block device block
scbbdbpl	dw	0	;* pointer to last bdb
scbgfbpf	dw	0	;* pointer to first global file block
scbgfbpl	dw	0	;* pointer to last gfb
scbdbbpf	dw	0	;* pointer to first disk buffer block
scbdbbpl	dw	0	;* pointer to last (and oldest) dbb
scbcntxt	dw	0	;* pointer to master memory context
scbslice	db	0	;* default # of time slices for each task
scbtcbpc	dw	0	;* tcb pointer of current (context) task
scbtcbpv	dw	0	;* pointer to visible tcb (at console)
scbtcbps	dw	0	;* tcb pointer of "SWITCHED-IN" task
scbtcbvr	dw	0	;* tcb pointer of "SWITHCED-IN" video (0 if none)
scbidq2		dw	0	; id of task that gets irq2s \
scbidq3		dw	0	; id of task that gets irq3s  \
scbidq4		dw	0	; id of task that gets irq4s   \  -1 if device
scbidq5		dw	0	; id of task that gets irq5s   /
scbidq6		dw	0	; id of task that gets irq6s  /
scbidq7		dw	0	; id of task that gets irq7s /
scbvcuty	dw	0	;* cursor type of visible task
scbvcupo	dw	0	;* cursor address of visible task
scbauxtm	dw	40	;* time after auxoff for xoff valid
scbconsz	dw	0	;* nbr paragraphs for context savearea
scbvidad	dw	0b800h	;* screen address (b000 or b800)
scbtcbn		dw	0	;* number of tasks

; please note: if scbversn is change from dos 3.20, please contact
; Stewart concerning windows/286. make sure that you test out
; windows 286 version 2.11 before changing this # for release.
;
; Update 06/09/90 SAH Windows 3.00 does not crash if DOS 3.30 is return

scbversn	dw	0005h	;* dos version, 5.00

include version.inc		;* just 2 dws (used by all utilites)

scbi10old	dd	0	; segment:offset to old int 10 vector in IRQ segment
scbldrive	db	-1	; lastdrive (-1 means that init did not setup)
scb4013		dw	0	; 40:13 value after loading memdev
scbdosver	dw	?	; default dos version for tasks
scbfiller1	db	18 dup (0)	; filler area
scbnoi5		db	0	; != 0 when int5 call must be deferred
scbmmhan	dw	0	; memman device handle
scbmmptr	dd	0	; pointer to device data
scbmmmod	dd	0	; memman modes	bit 7 - video management on
				;		bit 6 thru 0 undefined

; note: the order of the following areas must be maintained as is
; 14 words total

scbmmsub	dd	0	;1 pointer to memman entry point
scbmmfe2	db	0	;2 more feature flags (all undefined)
scbmmfea	db	0	;3 feature flags: bit
				; 8000h = all memory is managed
				; 4000h = i/o trapping supported
				; 2000h = write protection supported
				; 1000h = use memory mapping for cxt switch
				; 0800h = "DECLARE" supported ($286.sys only)
				; 0400h = ivtable support
				; 0200h = upper 60k supported (fff8:1080)

scbmmgrn	db	4 dup (0)	;4 page granularity (usually 4k, others are 16k & 64k)
	  	db	8 dup (0)	;5 reserved (actually invalid memory specs)
scbmmerr	dw	0	;6 int 6 error codes
scbmm6ad	dw	0,0	;7 int 6 address info
scbmmscb	dw	0,0	;8 scb address set by mos for memman driver
scbcon417	db 	-1	; DDTMC management of 40:17
scbioptr	dd	0	; IO protection table pointer
scbmmfg		db	'N'	; memman used flag
scbaltf1	db	104	; keyboard code for alt-f1
scbspltm	db	180	; nbr timer ticks before spool close
scblowpr	db	0	; lowest selectable priority (0 or 1)
scbvmode	db	0	; screen mode of visible task
scbswvq		db	'N'	; if should switch video during irq'S
scbsw87		db	'N'	; if 8087 or 80287 regs to be saved
scbswali	db	'N'	; "MIR ALI" workstations used
scbswaf9	db	'N'	; was prev keystroke alt-f9
scbinirq	db	0	; <>0 if user irq routine active
scbin08		db	0	; <>0 if within a timer (irq 0) call
scbhpadr	dw	0	; heap segment address
scbhpsiz	dw	1000h	; heap size in paragraphs (default 64k)
scbbufsz	dw	512	; disk buffer size
scb13buf	dw	0	; address of int 13 disk buffer

;* default is boot:\command.com leaving room for a 64-byte
; path (including the null) + drive:\ + trailing \ + 12-char file name

scbshell	db	'A:\COMMAND.COM',0		
		db	(scbshell+64+3+1+12)-$ dup(0)  	
scbcntry	dw	001	; country type
scbcursz	dw	0ffffh	; used in mosheman
scbcurad	dw	0	; used in mosheman
scbavsiz	dw	0	; used in mosheman
scbdrivs	db	0	; # active drive units
scbnoswt	db	0,0	; mos no switch flag (like dos critical flag)
				; to be set if no task switch is to occur
				; a 0 byte follows since some apps check the word
scbtskfg	db	0	; task selection flags
				;  bit 0=1 if no higher priority task needs service
				;  bit 1 thru 7 unused
scbdrvr		dd	-1	; -> to first device driver in list
scbstdin	dd	0
scbstdout	dd	0
scbstdnul	dd	0
scbstdclk	dd	0
scbstdprn	dd	0
scbstdaux	dd	0
scbdbblen	dw	?	; the length of a disk buffer block (dbb)
scbdebug	dw	0	; debug options active
scbdbprt	dw	0	; debug serial port
scbvrwait	dw	4	; how many ticks to wait between vidram checks
scbmastv	dw	0	; location of master video save area
scbkey		dd	0	; master decryption key
mos1ad		dw	0	; used as dword to call mos from mosfutil & co
scbmosadr	dw	0	; segment address of mos kernel

;* boot:\$$user.sys is the default leaving room for a 64-byte
; path (including the null) + drive:\ + trailing \ + 12-char file name

scbusrf		db	'A:\$$USER.SYS',0		
		db	(scbusrf+64+3+1+12)-$ dup(0)  	
						
scbhwcl		db	16 dup (0)	; occurrence counts for all 16 interrupts
scbdemo		dw	0	; demo count use in demo version
scbdemo2	dw	0	; second demo counter
scbsdemo	dw	0	; save demo count use in demo version
scbinsave	db	'N'	; indicate in demo critical code section

; flags and vars for the int15 task switching logic

scbdrbsy	db	0	; todriver re-entrance ctrl flg (int15 task switching)
scbi15tsl	db	'Y'	; int15 task switching on/off flag
scb15post	db	0	; disk operation complete flag
scb15act	db	0	; gate activation flag for the bdb level
scb13bsy	db	0	; int13 layer busy flag
scb13sk1	db	0	; flag to accomodate recursion by mosint13
scb13eoc	db	'N'	; flag to indicate end of int13 chain processing
scbflonce	db	0	; re-entracnce control flag for flshpoll
scbbdbbsy	db	0	; bdb busy flag
scbbsytcb	dw	0	; owner of bdb busy flag
scbtfix1	db	0	; holds trapping state for ports 40, 42, 43
scbtfix2	db	0	; holds trapping state for port 61
scblastw1	dw	0	; tcb of last write - stage 1
scblastw2	dw	0	; tcb of last write - stage 2
scbrdriv	db	0	; current drive of task being restarted

; this set of vars must remain in this order

scbirqd0a	dw	0	; distribution index for int0a (irq2)
scbirqd0b	dw	0	; distribution index for int0a (irq3)
scbirqd0c	dw	0	; distribution index for int0a (irq4)
scbirqd0d	dw	0	; distribution index for int0a (irq5)
scbirqd0e	dw	0	; distribution index for int0a (irq6)
scbirqd0f	dw	0	; distribution index for int0a (irq7)
scbinit		db	0	; != 0 indicates through with init process
scbirqbnk	dd	0	; pointer to irqbank handler
scbkbrate	db	01001100b	; kybd repeat rate to use for new tasks
				; default to 500ms delay, 10 chars/sec
				;  ff means revert to no rate control
scbout60	db	1	; != 0 means pass thru on output to port 60
scbin60		db	1	; != 0 means pass thru on input from port 60
scbmconly	db	1	; != 0 when the mc is the only watcher
				; (scbtcbpv tells which task the mc is watching)
scbi15off	db	0	; use to to temorarily turn off dbts 
				; this is an increment/decrement flag
scbnorst	db	0	; != 0 means that we can't restart any task
SCBSAVE		dd   0		; SCB routine to Save EMS Context
SCBRESTORE	dd   0		; SCB routine to Restore EMS Context
SCBUPOLL	dd	0     	; Lanlink Netbios Poll Routine
scbpost		dw	0	; tcb of task switched in enough for post
SCBKBBIOS	db	'Y'	; 'Y'= include 40:17 support
sfillerx	db	5 dup (0)
scb15tcb	dw	0	; TCB currently inside TCB
;
;  The following variables are used by MOSINT17 in dealing with
;  reservations of COM1 - COM24.  Previously this was an attribute
;  of only parallel ports.
;
SCB_COM_owner	dw	24 dup (-1)	; Present owner of COM port.
SCB_COM_timeout	dd	24 dup (0)	; Timer value at which the COM port
                                        ; will be released.

scbdrtcb	dw	0	; tcb of holder of scbdrbsy
scbvdrflg	db	0	; vidram reentrance control flag
scbdopflg	db	0	; dopoll reentrance control flag
sfiller0	db	21 dup (0)	; Remainder of sfiller0.
scbsmsg		db	'00-xxxxxxxx EVAL$'	; copy of serial # implanted in init code
scbfar21	dd	0	; far call to mosint21 (novell)
scbcurcnt	dd	0	; storage for the timer tick count at 40:6c,6e
scbcurwrp	db	0	; stoarge for the timer wrap falg at 40:70
scbsmplow	db	2	; bit 0 allocate smp allocation low
				; bit 1 processing init code
scbhp2adr	dw	0	; smp heap #2 segment
scbhp2siz	dw	0	; smp heap #2 size
scbhldss	dw	0	; used to record ss in tsl
scbbuff		dw	5 dup (0,0)	; used to save freemem information
scbmosend	dw	0	; end segment above mos kernel

; following is a fake code fragment to convince sidekick that
;   this is a dos version it understands
; since we now use scbinmos and new indos flag emulation along
; with function 5d06h support for the critical flag, the fake24flg
; is nolonger need anymore. it is now represented by scbcrit which
; is task context related (as in scbinmos) and is increment before
; int 24 is call and decrement when return from int 24.

fake24flg	label	byte			;*
	db	0
	cmp	[scbcrit],0
	jnz	$+5
	int	28h

; sah don't remove this line or utilities that use the scb following 
; this code will not function correctly

	even				

;======== note: all new entries must be made after this point ==========

scbpripf	dw	0	; pointer to first tcb in priority order
scbctxsz	dw	0	; mosheman size for context block
scbscang	dd	0	;* vector for keyboard processing routine
scbcin24	dd	0	; vector to point to command processors int 24 handler
scbtcbvs	dw	0	; task whose video save area is switched in
scbcpseg	dw	0	; segment where $$shell.sys is located
scbvtype	db	0	; set from the vtype statement of config.sys
scbcpsiz	dw	0	; # of paragraphs for command processor
scbfar38	dd	0	; vector to mos's INT 38 routine

; pc-mos/386 version 1.02 in production 08/24/87

scbhpalc	dw	0	; latest heap allocation (total)
scbvidpg	dw	0	; how many pages to expose in swrealram
scbmastp	dw	0	; the maximum pages in the video save area scbmastv
scbirqpf	dw	6 dup(0) ; table for irq2-7, root pointers to linked
				; lists of tasks which have irq intercepts
scbnoslc	db	0	; is chkslice disable?  (Use by Novell)
scbcrit		db	0	; dos critical error flag (function 5d06)
scbinmos	db	0,0	; new inmos flag for sidekick support

; pc-mos/386 version 2.10 went into production

scbtimer	dw	0	; tick counter for timeparm routine

; following items are items which were inside mos's codes segment and
; are now inside of the scb for future 286 version

scbboot		dw	0	; boot segment
scbmsgseg	dw	0	; message segment
scbttrap1	db	0	; int6 logic counter/flag for port 40h
scbttrap2	db	0	; int6 logic counter/flag for port 42h
scb286dec	db	'N'	; ok to declare 286 segments
scbidqp		dw	0	; segment of port specific irq table in smp
scbvsahdl	dw	0	; handle of 1st blk mapped into the vsa (video save area)
		dw	0	; handle of 2nd blk mapped into the vsa
scbvsacnt	dw	0	; # of pages of 1st blk mapped into the vsa
		dw	0	; # of pages of 2nd blk mapped into the vsa
scbvmahdl	dw	0	; handle of 1st blk mapped into vma (video memory area)
		dw	0	; handle of 2nd blk mapped into vma
scbvmacnt	dw	0	; # of pages of 1st blk mapped into vma
		dw	0	; # of pages of 2nd blk mapped into vma
scbvmaseg	dw	0	; segment referred to by scbvmahdl/cnt
scbmapvmf	dd	0	; video memory area map routine
scbmapvsf	dd	0	; video save area map routine
scbhp1alc	dw	0	; amount smp allocate for smp #1
scbmuser	db	0,0	; max users value #1 (use in calculations of # users)
scbvidchk	dd	0	; special video check routine
scbvmaal	dw	0	; function selector for mapvma call
scbvsaal	dw	0	; function selector for mapvsa call
scbcuob		dw	0	; para's in each cache buffer
scbcbk		dw	0	; config.sys k in each cache buffer (uob)
scbcnum		dw	0	; # of cache buffers
scbck		dw	0	; config.sys total k for cache buffers
scbcsysk	dw	0	; k specified w/ device=$cache.sys
scbcwrf		dw	0	; ticks from first write to flush (0 disable)
scbcwf		dw	0	; config.sys ticks between writes
scbcwrl		dw	0	; ticks from last write to flush (0 disable)
scbcwl		dw	0	; config.sys ticks between writes
scbcupf		dw	0	; head of usage list
scbchdl		dw	0	; memman handle for cache or start segment
scbclst		dw	0	; segment of start of cache list
scbccur		dw	0	; cache descriptor offset for current element
				;   (the one mapped in to scbmastv, 0 for none)
scbcele		dw	0	; segment address of start of scbccur element
scbcmtr		db	0	; <> 0 while floppy motor not to be turned off
				;   (there are unflushed floppy writes)
scbcd		db	4 dup(0); 1 bit for each of drives 'A'-'Z'
scbcach		db	'Y'	; <> 'Y' while cache disabled
scbflush	db	0	; 'Y' while cache being flushed by poller
scbcsave	db	16 dup(0) ; save init'ed uob descriptor
				;   this must be the same size as size cache
				;   defined in mosbdb
scbcnxt		dw	0	; next cache descriptor to check during
				;   rdcache/wrcache
scbcwsys	dw	0	; % cache available for write cache
scbcwmax	dw	0	; # cache buffers available for write cache
scbcwnum	dw	0	; # cache buffers dirty
scbcbits	dw	0	; k to use for cache bit map
scbcbmsz	dw	0	; paras to use for cache bit map
scbcbmap	dw	0	; start seg of cache bit map
scbcclr		dw	0	; count # uob's discarded to cache new data
scbcbdb		dw	0	; bdb for head of usage list
scbcseg		dw	0	; where to map the cache uob
scbcsegp	dw	0	; and size of mapping space in pages
scblastff	dw	0	; tcb of last ddt to get an ff call
scbmo2end	dw	0	; end of mo2 segment (for mos info)
scbdump		dd	0	; special dump routine at invalid conditions
scbvnasys	db	'N'	; flag to indicated that vna board is install
scbpktio	db	'N'	; flag to indicate that irq's need to be
				; re-enabled in the swcall procedure (for packet/pc)
filler2		db	?
scbcntflg	db	00	; bit map for optimizing context switching
				; bit 0 = 1 if tcbrstcnt is set for mos useirq
				; bit 1 = 1 if inside switch call
scbinswgp	db	00	; 0 if not non in a dirty state for irqs
				; non-zero if in dirty state for irqs

	even

scbrstcnt	db	64 dup (0)	; bios context area save during rstcntxt (mm only)
scbbootdrv	db	00	; original boot driver
scbmoutcb	dw	0	; ps/2 style mouse tcb
scbmouse	dd	0	; ps/2 style mouse far handler
scbmouval	dw	4 dup(0); ps/2 style mouse value save area
scbrstrtc	db	0	; number of tasks waiting restar; rg9006
scbrstrtp	dw	0	; tcb of task to be restarted	; rg9006
scbcall74	dd	0	; far call routine use by $mouse int 74h
scbbankin	db	'Y'	; 'Y' - switch memory in during ff call
scbslfact	db	0	; from the tfactor= statement in config.sys
scbslcnt	db	0	; the master slice counter - used to determine when
				; 1/18th of a second has passed when using fast slicing

; port reservation data (indexed by lpt number)

scbhold		label	word
scbhldtask	dw	-1	; task holding reservation
scbhldtick	dw	0	; time counter when reservation ends
scbhldtock	dw	0	; significant word of time counter
		dw	-1, 0, 0 ; hold values for lpt2
		dw	-1, 0, 0 ; hold values for lpt3
scbhldlen	equ	6	; length of hold structure
scbtimerh	dw	0	; most significant word of tick counter
scbmouss	dw	0	; ss save value during int 15 function 90 mouse polling
scbmousp	dw	0	; sp save value during int 15 function 90 mouse polling
scbnotsl	db	'N'	; no tsl flag to indicate not to do task selection
scbin74		db	'N'	; flag to indicate $mouse.sys is using int 74
scborg38	dd	 0	; original scbfar38 value (use for context handling
				; of int d4 vector)
scbclbx		dw	0	; last handle mapped for cache
scbclcx		dw	0	; last page count mapped for cache
scbclbdb	dw	0	; last bdb buffered by rdsector
scbclsct	dw	0,0	; last sector number buffered by rdsector
scbclseg	dw	0	; last buffer segment derived by rdsector
scbreg32	db	0	; flag to indicate 32 register support, 386/486


; The following 8 bytes is referenced by Intel SatiFaxtion FaxPop TSR
; to access DOS Critical Flag.  This code must be in same segment as
; pointer to Indos (Ah=34h) is pointing to.

		dw	03e80h
		dw	offset scbinmos-1
		dw	7500h
		dw	0bc31h

scbfill		db	29 dup(0)	; carve new variables from this allocated space
scbfree		dw	?		; segment address of first free memory
scbgrpend	dw	?		; end of grp segment (for mos info)
scbmo2adr	dw	?		; start of mo2 segment (for mos info)
scblen		equ	$-scb		;*

