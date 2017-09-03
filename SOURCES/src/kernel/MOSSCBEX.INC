extrn scbtcbpf:word	; pointer to first task control block	
extrn scbtcbpl:word	; pointer to last tcb
extrn scbbdbpf:word	; pointer to first block device block
extrn scbbdbpl:word	; pointer to last bdb
extrn scbgfbpf:word	; pointer to first global file block
extrn scbgfbpl:word	; pointer to last gfb
extrn scbdbbpf:word	; pointer to first disk buffer block
extrn scbdbbpl:word	; pointer to last (and oldest) dbb
extrn scbcntxt:word	; pointer to master memory context
extrn scbslice:byte	; default # of slices/task (0=no slicing)
extrn scbtcbpc:word	; tcb pointer of current (context) task
extrn scbtcbpv:word	; pointer to visible tcb (at console)
extrn scbtcbps:word	; tcb pointer of "SWITCHED-IN" task
extrn scbtcbvr:word	; tcb pointer of video switched in
extrn scbidq2:word	; ids of irq owners
extrn scbidq3:word
extrn scbidq4:word
extrn scbidq5:word
extrn scbidq6:word
extrn scbidq7:word
extrn scbvcuty:word	; cursor type of visible task
extrn scbvcupo:word	; cursor address of visible task
extrn scbauxtm:word	; time after auxoff for xoff valid
extrn scbconsz:word	; nbr paragraphs for context savearea
extrn scbvidad:word	; screen address (b000 or b800)
extrn scbtcbn :word	; number of tasks
extrn scbversn:word	; compatibility version number
extrn scbi10old:dword	; offset to old int 10 vector in IRQ segment
extrn scbmmhan:word	; memman device handle
extrn scbmmptr:dword	; pointer to device data
extrn scbmmfg:byte	; memman used flag
extrn scbmmmod:byte	; memman mode flags
extrn scbmmsub:dword	; memman entry point
extrn scbmmfea:byte	; feature bits
extrn scbmmfe2:byte	; "     "
extrn scbmmgrn:byte	; memman bank granularity
extrn scbmmerr:word	; memman int 6 error code
extrn scbmm6ad:word	; memman int 6 address info
extrn scbmmscb:word	; memman scb pointer (set by mos for memman)
extrn scbaltf1:byte	; keyboard code for alt-f1
extrn scbspltm:byte	; nbr timer ticks before spool close
extrn scblowpr:byte	; lowest selectable priority (0 or 1)
extrn scbvmode:byte	; screen mode of visible task
extrn scbswvq :byte	; if should switch video during irq'S
extrn scbsw87 :byte	; if 8087 or 80287 regs to be saved
extrn scbswali:byte	; "MIR ALI" workstations used
extrn scbswaf9:byte	; was prev keystroke alt-f9
extrn scbinirq:byte
extrn scbin08 :byte	; <>0 if in timer routine
extrn scbhpadr:word	; heap address
extrn scbhpsiz:word	; heap size
extrn scbbufsz:word	; disk buffer size
extrn scb13buf:word	; seg address of int 13 disk buffer
extrn scbshell:byte	; current command proecessor
extrn scbcntry:word	; country
extrn scbcursz:word	; mosheman usage
extrn scbcurad:word	; mosheman usage
extrn scbavsiz:word	; mosheman usage
extrn scbdrivs:byte	; # active drive units
extrn scbnoswt:byte	; mos no switch flag
extrn scbtskfg:byte	; task selection flags
extrn scbdrvr:dword	; -> first device driver in list
extrn scbstdin:dword	; pointers to standard devices
extrn scbstdout:dword
extrn scbstdnul:dword
extrn scbstdclk:dword
extrn scbstdprn:dword
extrn scbstdaux:dword
extrn scbdbblen:word	; the length of a disk buffer block (dbb)
extrn scbdebug:word	; debug options active
extrn scbdbprt:word	; debug output port
extrn scbvrwait:word	; how may ticks to wait between vidram checks
extrn scbmastv:word	; location of master video save area
extrn scbkey:dword	; master key for file encryption/decryption
extrn mos1ad:word
extrn scbmosadr:word	; address of mos and dword call to mos
extrn scbusrf:byte	; user file drive, path and file name
extrn scbhwcl:byte	; interrupt counts for 16 hardware interrupts
extrn scbfar21:dword	; far call to mosint21
extrn scbcurcnt:dword	; storage for the timer tick count at 40:6c,6e
extrn scbcurwrp:byte	; stoarge for the timer wrap falg at 40:70
extrn scbhldss:word	; used to record ss for tsl
extrn scbbuff:word	; words for freemem 10
extrn scbmosend:word	; segment above mos
extrn scbpripf:word	; pointer to first tcb in priority order
extrn scbctxsz:word	; mosheman size for context block
extrn scbscang : dword	; vector to scan code processing routine
extrn scbcin24:dword	; vector to command processors int 24 handler
extrn scbtcbvs:word	; task whose video save area is switched in
extrn scbcpseg:word	; segment where $$shell.sys is located
extrn scbvtype:byte	; set from the vtype statement of config.sys
extrn scbcpsiz:word	; # of paragraphs for command processor
extrn scbfar38:dword	; vector to mos's INT 38 routine
extrn scbhpalc:word	; latest heap allocation (total)
extrn scbvidpg:word	; how many pages to expose in swrealram
extrn scbmastp:word	; maximum pages in video save area swmastv
extrn scbirqpf:word	; table for irq2-7, root pointers to linked
			; lists of tasks which have irq intercepts
extrn scbcrit:byte	; dos critical flag (function 5d06)
extrn scbinmos:byte	; new inmos flag for sidekick(+)
extrn scbtimer:word	; tick counter for timeparm routine
extrn scbtimerh:word	; most significant word of tick counter
extrn scbboot:word	; boot segment of mos
extrn scbmsgseg:word	; message segment for mos
extrn scbttrap1:byte	; int6 logic counter/flag for port 40h
extrn scbttrap2:byte	; int6 logic counter/flag for port 42h
extrn scb286dec:byte	; ok to declare 286 segments
extrn scbidqp:word	; segment of port specific irq table in smp
extrn scbvsahdl:word	; handle of block mapped into video save area
extrn scbvsacnt:word	; # of pages of block mapped into video save area
extrn scbvmahdl:word	; handle of block mapped into video save area
extrn scbvmacnt:word	; # of pages of block mapped into video save area
extrn scbvmaseg:word	; segment referred to by scbvmahdl/cnt
extrn scbmapvmf:dword	; video memory area map routine
extrn scbmapvsf:dword	; video save area map routine
extrn scbvidchk:dword	; special video check routine
extrn scbvmaal:word	; function selector for mapvma call
extrn scbvsaal:word	; function selector for mapvsa call
extrn scbcuob:word	; para's in each cache buffer
extrn scbcbk:word	; config.sys k in each cache buffer (uob)
extrn scbcnum:word	; # of cache buffers
extrn scbck:word	; config.sys total k for cache buffers
extrn scbcsysk:word	; k specified w/ device=$cache.sys
extrn scbcwrf:word	; ticks from first write to flush (0 disable)
extrn scbcwf:word	; config.sys ticks between writes
extrn scbcwrl:word	; ticks from last write to flush (0 disable)
extrn scbcwl:word	; config.sys ticks between writes
extrn scbcupf:word	; head of usage list
extrn scbchdl:word	; memman handle for cache or start segment
extrn scbclst:word	; segment of start of cache list
extrn scbccur:word	; cache descriptor offset for current element
			;   (the one mapped in to scbmastv, 0 for none)
extrn scbcele:word	; segment address of start of scbccur element
extrn scbcmtr:byte	; <> 0 while floppy motor not to be turned off
			;   (there are unflushed floppy writes)
extrn scbcd:byte	; 1 bit for each of drives 'A'-'Z'
extrn scbcach:byte	; <> 'Y' while cache disabled
extrn scbflush:byte	; 'Y' while cache being flushed by poller
extrn scbcsave:byte	; save init'ed uob descriptor
extrn scbcnxt:word	; next cache descriptor to check during
			;   rdcache/wrcache
extrn scbcwsys:word	; % cache available for write cache
extrn scbcwmax:word	; # cache buffers available for write cache
extrn scbcwnum:word	; # cache buffers dirty
extrn scbcbits:word	; k to use for cache bit map
extrn scbcbmsz:word	; paras to use for cache bit map
extrn scbcbmap:word	; paragraphs to use for cache bit map
extrn scbcclr:word	; count # uob's discarded to cache new data
extrn scbcbdb:word	; bdb for head of usage list
extrn scbcseg:word	; where to map the cache uob
extrn scbcsegp:word	; and size of mapping space in pages
extrn scblastff:word	; tcb of last ddt to get an ff call
extrn scbmo2end:word	; end of mo2 segment (for mos info)
extrn scbdump:dword	; special dump routine at invalid conditions
extrn scbvnasys:byte	; flag to indicate if vna board is installed
extrn scbpktio:byte	; flag to indicate that irq's need to be
			; re-enabled in the swcall procedure (for packet/pc)
extrn scbcntflg:byte	; context flags during hardware irqs
extrn scbinswgp:byte	; dirty flag for irqs
extrn scbrstcnt:byte	; 64 byte bios context save area during rstcntxt
			; memory management only which map page 0
extrn scbbootdrv:byte	; orginal boot drive
extrn scbmoutcb:word	; ps/2 style mouse tcb
extrn scbmouse:dword	; ps/2 style mouse handle
extrn scbmouval:word	; ps/2 style mouse values (4)
extrn scbrstrtc:byte	; number of tasks waiting restar; rg9004
extrn scbrstrtp:word	; tcb of task to be restarted	; rg9004
extrn scbcall74:dword	; far call routine use by $mouse.sys int 74h
extrn scbbankin:byte	; 'Y' means switch in video memory during ffh call
extrn scbslfact:byte	; from the tfactor= statement in config.sys
extrn scbslcnt:byte	; the master slice counter - used to determine when
extrn scbhold:word	; port reservation structure indexed by lpt number
extrn scbhldtask:word	; task holding reservation
extrn scbhldtick:word	; time counter when reservation ends
extrn scbhldtock:word	; msb of time counter (overflows in ten days)
extrn scbhldlen:abs	; length of hold structure
extrn scbmouss:word	; ss save value during int 15 function 90 mouse polling
extrn scbmousp:word	; sp save value during int 15 function 90 mouse polling
extrn scbnotsl:byte	; flag to indicated not to call task selection logic
extrn scbin74:byte	; flag to tell mos that $mouse is using int 74
extrn scborg38:dword	; original scbfar38 value (use for context handling
			; of int d4 vector)
extrn scbclbx:word	; last handle mapped for cache
extrn scbclcx:word	; last page count mapped for cache
extrn scbclbdb:word	; last bdb buffered by rdsector
extrn scbclsct:word	; last sector number buffered by rdsector
extrn scbclseg:word	; last buffer segment derived by rdsector
extrn scbsmsg:byte	; copy of serial # implanted in init code
extrn scbhp2adr:word	; segment of heap #2
extrn scbhp2siz:word	; size of heap #2
extrn scbsmplow:byte	; non-zero if to allocate smp allocation low
extrn scbhp1alc:word	; amount smp allocate for smp #1
extrn scbmuser:byte	; max users value #1 (use in calculation of # of users)
extrn scbdemo:word	; demo count use demo version of code
extrn scbdemo2:word	; second demo counter
extrn scbsdemo:word	; save demo count use demo version of code
extrn scbinsave:byte	; in demo version critical error code
extrn scbreg32:byte	; indicates that we have 32 reg support (386/486)
extrn scbdrbsy:byte	; todriver re-entrance ctrl flg (int15 task switching)
extrn scbi15tsl:byte	; int15 task switching on/off flag
extrn scb13bsy:byte	; int13 layer busy flag
extrn scb13sk1:byte	; flag to accomodate recursion by mosint13
extrn scb13eoc:byte	; flag to indicate end of int13 chain processing
extrn scb15post:byte	; disk operation complete flag
extrn scb15act:byte	; gate activation flag for the bdb level
extrn scbflonce:byte	; re-entracnce control flag for flshpoll
extrn scbbdbbsy:byte	; bdb busy flag
extrn scbbsytcb:word	; owner of bdb busy flag
extrn scbtfix1:byte	; holds trapping state for ports 40, 42, 43
extrn scbtfix2:byte	; holds trapping state for port 61
extrn scblastw1:word	; tcb of last write - stage 1
extrn scblastw2:word	; tcb of last write - stage 2
extrn scbrdriv:byte	; current drive of task being restarted
extrn scbirqd0a:word	; distribution index for int0a (irq2)
extrn scbirqd0b:word	; distribution index for int0a (irq3)
extrn scbirqd0c:word	; distribution index for int0a (irq4)
extrn scbirqd0d:word	; distribution index for int0a (irq5)
extrn scbirqd0e:word	; distribution index for int0a (irq6)
extrn scbirqd0f:word	; distribution index for int0a (irq7)
extrn scbinit:byte	; != 0 indicates through with init process
extrn scbirqbnk:dword	; pointer to irqbank handler
extrn scbkbrate:byte	; kybd repeat rate to use for new tasks
extrn scbout60:byte	; != 0 means pass thru on output to port 60
extrn scbin60:byte	; != 0 means pass thru on input from port 60
extrn scbmconly:byte	; != 0 when the mc is the only watcher
extrn scbi15off:byte	; use to to temorarily turn off dbts 
extrn scbnorst:byte	; != 0 means that we can't restart any task
extrn SCBSAVE:dword   ; SCB routine to Save EMS 4.0 Context
extrn SCBRESTORE:dword   ; SCB routine to Restore EMS 4.0 Context
extrn scbupoll:dword	; user polling routine
extrn SCB15TCB:word	; current TCB inside INT 15 Disk Busy Suspension
extrn SCBCON417:byte	; DDTMC management of 40:17
extrn SCBIOPTR:dword	; IO Protection pointer
extrn scbpost:word	; tcb of task switched in enough for post
extrn SCB_COM_owner:word        ;Owner of COM ports.
extrn SCB_COM_timeout:dword     ;Chronograph value of ownership timeout.
extrn SCBKBBIOS:byte	; 'Y'= include 40:17 support
extrn scbdrtcb:word	; tcb of holder of scbdrbsy
extrn SCBNOSLC:byte	; if chkslice diable?
extrn SCBLDRIVE:byte    ; last drive
extrn scbnoi5:byte	; != 0 when int5 call must be deferred
extrn SCB4013:word	; 40:13 value after memdev is loaded
extrn scbvdrflg:byte	; vidram reentrance control flag
extrn scbdopflg:byte	; dopoll reentrance control flag
extrn scbdosver:word	; default dos version
