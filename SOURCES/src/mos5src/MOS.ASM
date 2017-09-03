	include page.inc
	title	mos - system management utility

sys	equ	1		; system management
adm	equ	0		; not administrator

comment ^==============================================================
		    pc-mos/386	 utility program

	   0 - requested operation performed without error
	   1 - requested operation not performed
	   2 - mos system error
	   3 - user error (invalid parameter specified)

sah 11-07-86	for pc-mos/386 mos.com utility utility functions.

sah 12-23-86	to include pc-mos functions time and pri subcommands

sah 01-19-87	to include pc-mos functions useirq and freeirq subcommands

sah 02-06-87	to include memman information information following map and 
		change time to slice.

sah 02-23-87	to invlude pc-mos functions wait and vmode. also video mode 
		on map

sah 03-10-87	fix minor problems related to mos cooking and device 
		driver reading.

sah 03/16/87	for conditional assembly of mosadm

sah 03/17/87	for cache, serinit and route functions.

sah 03/30/87	for resize function

sah 05/04/87	for placing equipment flags in bios data segment for 
		mode changes

sah 05/07/87	for nodis and dis status in map and ems usaged 
		message following map

rbr 5/12/87	messages cleaned up.

sah 05/13/87	for vmode e43 for optional 43 line support on ega's.   This is new and different so watch out!

sah 05/15/87	for memory allocations on vmode changes

sah 05/16/87	for ega info on the map

sah 06/25/87	shrink program memory allocation

sah 07/09/87	add men function

sah 07/12/87	convert int 21h 80+ calls into int 38h 00+ calls.

sah 07/22/87	added cp to mos info (mem)

jrb 07/24/87	use int 38h to set priority, display tcbpri divided by 2

sah 08/27/87	add smp allocation at end of mos map

sah 08/31/87	fix minor assembly problem which i created modifing mos map above for mosadm version

sah 09/04/87	added support for vga multitasking added verification of ega and vga mode settings

sah 09/24/87	corrects on video mode handling because of vtype stuff and jim's Observation

sah 09/28/87	enhange mos vmode ega support to include provisions for 
		multi-tasking ega support. also added hg1 and hg2 for 
		jims hecules support

sah 10/03/87	added new mosadm function pam to allow turning off the 
		pamming of a partition. switch

sah 10/05/87	include initialization of the ega state area to the 
		following values.  values were derived on an ibm
		model 80 with vga monitor. pc-mos was setup in ega mode 
		with ega io protection turn on and utility program 
		getvga.com was use to fetch the registers. while ega.com 
		was use to display the contents of the ega registers on 
		the screen. both programs may be found in the utils.dir 
		on the r & d server.

jrb 10/22/87	various changes for hercules support

    offset  name	   values
    ------  ----------   ------------
      0     seq index	 00
      1     seq values   03 00 03 00 02
      6     att index	 00
      7     att flipflop 00			 (internal flag)
      8     att values   00 01 02 03 04 05 14 07 38 3f
			 3a 3f 3c 3f 3e 3f 0c 00 0f
      27    graph index  00
      28    graph values 00 00 00 00 00 10 0e 00 ff

    also added default values for tcbegapal arrays for vmode of ega
 and vga. the follow is the list of default values used.  these
 values were derived by using vga mode on a model 80 and doing a
 pam switch.

   tcbegapal		   00 01 02 03 04 05 14 07 38
			   39 3a 3b 3c 3d 3e 3f 00

   made provisions for supporting ibm ega with only 64k. (if system
 does not have 256k, it is assume to have only 64k --- only 64k is
 saved.)


sah 10/23/87	if system has vga and user request for ega, system 
		will give you ega because we don't have to worry
		about io protection. also clean up some problems with 
		ega mode setting.

sah 11/09/87	check to make sure console is not a terminal task before 
		going into ega mode. (displaying message to tell use 
		that another task is viewing it or trying to run ega
		on a terminal task.

sah 11/10/87	corrent problem with split video memory lock up and 
		better error messages

sah 11/17/87	made necessary correction for ega's on 286 system

sah 11/23/87	made addtional message if vmode of ega or vga is made 
		in the background.  (which currently do to limititations 
		on designed, can't be down because background task
		has no terminal driver.

sah 12/09/87	made change so that if orginal task does not go into 
		ega or vga if mono chrome task is on system.
		
sah 12/10/87	disable vmode of e43 if vga

mjs 1/13/88	added dsport subcommand to allow a port to be
		disabled from serial.sys's control so a modem connected
		to it could be used with a communications program.

sah 02/15/88	change mos info so that it works with new grp (mos 2)
		segment aliagnment

mjs 3/3/88	add port specific reservation options for mos useirq
		and mos freeirq.  add to display of mos irq command.

mjs 5/19/88	general clean up of this file - so i could find things!
		reworked parts of vmode logic to do proper video mapping
		and be secure against serial irq's that switch video.

sah 07/14/88	modified mos info command to display mos 2 kernel
		segments

sah 07/29/88	update for lidt only version of memman

sah 08/01/88	update mos info display for nonmem case
		correct mos map display of smp usage
sah 08/02/88	corrected setting of tcbvidp1 for hercules modes

mjs 09/05/88	corrected bug in 'mosadm switch on|off'  (when no task
		number is specified).  the procedure onoff was
		clobbering the si register so when this command form
		was used in a background task, the foreground ended up
		being affected.  there were also two jnc's in pamfun
		that needed to be jnz's.

sah 09/24/88	not allow hercules modes on consoles which don't support
		hercules i.e ega and terminals.

sah 09/28/88	added undocument mos tsr command to enable\disable int
		28 waiting, primary done for skplus.

sah 10/03/88	added check for non-supported console watchers

rkg 11/03/88	changed to facilitate foreign language translation

rkg 11/15/88	change mos wait to key available instead of any press

sah 12/01/88	corrected vmode of e43 (it was allocating tcbstate stuff
		and also ibm ega doc was incorrect on setting 43 line
		mode)

sah 12/03/88	added mos limit command which limits the # of open files
		to # of entries in the psp table.  this corrected a
		problem with enable 3.0 install program.

sah 12/05/88	change mos limit to mos files command (name only)

sah 12/10/88	added mos share command while turns off share support
		(interupt 2fh level - for apps which check to see if
		share is installed)  this was need because of the
		sloppiness of dbase iv installation program.  also
		corrections for e43 command if vga.

rkg 12/12/88	added mos keyboard to define type of keyboard per task

rkg 12/28/88	modified flags in kbctl for compatibility

sah 01/10/89	added mos mouse for generic mouse support.

mjs 01/17/89	corrected mos map display to put n/a for baud of vna
		workstations and to show the first vna port properly in
		a co-resident system.  also added a check to prevent a
		mos vmode cga or c40 from being done from a vna
		workstation.

sah 01/18/89	enhance mos info command to include listing the com
		ports and their associated driver descriptions. this is
		usefull in helping user find out which port is where.
sah 01/19/89	update mos mouse to include option off to turn support
		off.

sah 01/26/89	updated mos mouse to set \ reset (non-ps/2) bit 4 of the
		equipment flags at 40:10h.  also set tcbmport for int 28
		windows efficiency when mouse is active. see mosint28

sah 02/10/89	change displaying of serial description to not required
		$ at end of line.

sah 02/14/89	update mos mouse command to use keyboard input for
		efficiency. also fix from rkg for mos route command.

mjs 02/16/89	added 'mosadm tmfactor' command to change mos's slicing
		rate by re-programming the 8253 timer/counter chip
		and setting up a software divider in the kernel's
		int8 logic.

mjs 02/17/89	modified time slice speed up to work when lidt support
		doesn't exist.

sah 02/20/89	changes to mos mouse command to check if port is
		not accessable (i.e accessed to a sunriver com port
		whose station is not present or active) also made
		changes so that new options.inc equate services can be
		use to indicate which port exists. also corrected
		assembly problem with mjs's latest addition.
sah 02/22/89	changes for change in genmouse.inc structure

sah 02/24/89	made mos keyboard actually change the status bit at
		40:96 to indicate if station has a enhanced keyboard
		or not. this is necessary in a condition where mask
		console has normal keyboard and station (ie sunriver)
		has an enhances keyboard and user at station needs to
		use the enhanced cursor keys in an app like ms word.

mjs 03/13/89	set the limit for mosadm tmf to 50

sah 03/16/89	corrected serial portion of mos info display (had an
		extra on display)

sah 03/21/89	change pc-mos/386 to pc-mos.

mjs 04/06/89	lower max tmf value to 40.  i was able to get mos to
		croak at 45 when heavy vidram activity was going on.

rkg 04/11/89	include mos hold lptx nnnn setting parallel port reserve
		time.  included moxmos for debugging.

mjs 05/12/89	added mos keyb sb!lb  to allow the user to make the type
		ahead buffer to be the same as dos's (sb).  This is
		required for compatibility with stupid programs such
		as microsoft's QuickBasic 4.5

sah 06/07/89	corrections for vga mono chrome systems.
		also corrections for mos mouse off, not propertly
		deallocating mouse structures.

sah 06/13/89	change setting of scbtcbvr from -1, to 0 during vmode
		logic, -1 was causing lidt int 8 logic to skip calling
		users int 8 which cause help.com (turbo pascal) to halt
		because its int 8 never got called.

sah 06/15/89	change access to mouse structure lenght to access
		genmouse.inc equate

sah 06/22/89	update for new tcbmcount which points to $mouse.sys
		internal buffer counter, also tcbmready for mouse
		serial buffer ready flag.

mjs 06/27/89	modified mos dsport to test for an new error return code
		from the int14fun0b call.  if al == 2, then an irq
		reservation is already in place for this port so it
		cannot be disabled again.

sah 07/05/89	corrections for doc, made mos share undocumented.
		plus addition changes necesary for documentation
sah 07/11/89	added mos tsr command to doc

sah 07/14/89	corrected mos vmode e43 on invalid work stations
		also cursor in e43 mode.
sah 07/21/89	corrected ports in mos map display on vna system.

sah 08/16/89	added mos ansi command for enabling\disabling ansi.sys

bwr 11/28/89	marked messages for foreign language translation.

bwr 12/11/89	mos map function incorrectly counts the number of open
		files.	the mos map report always shows one fewer file
		open than actually is.	counter was being incremented
		at wrong point in loop.

sah 12/15/89	corrections for split-smp for mos map and mos info.

sah 01/09/90	corrections for mos ansi and keyboard re-assigments

sah 01/17/90	added mos hold lptx off

sah 02/21/90	added mos resize max option

sah 03/26/90	added mos dosver command.

mjs 05/17/90	modified mos useirq and freeirq commands to work 
		with lidt logic for irq2 through 7

SAH 08/08/90    Change syntax help for mos hold lptx off

SAH 10/29/90	Move GetMDev to here for MOSADM EMSLIMIT additions.					

SAH 11/08/90	Corrections for Serinit above 9600 baud and also had
	 	handshaking to serial Init

SAH 11/28/90	Corrections for Serializing a terminal with Serinit command
		and also mask out high bit on port for emulink

SAH 06/25/91    Increased ANSI Keyboard assigment buffer size.

mjs 12/16/91	dlg mods: removed the dosver command.  fixed two branches in
		secwait for proper stack balancing (per sah).

SAH 03/09/92	Put back MOS DOS command for MOS 5.01 release. Change
		version to 5.01 and included 1992 in copyright.

SAH 03/26/92	Update MOS DOS to techniques use in mosinit2.asm

SAH 04/17/92	Cosmetic correction for mos info

SAH 04/20/92	Corrections for MOS Resize so that updates 40:13
		when it changes task sized.

==================  PC-MOS 5.01 ends here =============================

SAH 08/31/92	Update to 5.02 version for HOLD COMx fix
======================================================================^

	page

insmem	 equ   8
invdata  equ   13
general  equ   31

dbbnext  equ   8			; note hard code to offset 8 in dbb header

	.xlist
	include	macros.inc

tcb	segment at 07777h
	include mostcb.inc
tcb	 ends

scbs	segment at 0FACEh
        ASSUME  cs:scbs
	include mosscbdf.inc
scbs	ends

	include mos.pub
	include mostfb.inc
	include options.inc
	include genmouse.inc
	.list
	.tfcond

mainseg  segment para
	assume cs:mainseg,ds:mainseg,es:tcb
	org	80h
operands label byte			; drive:path specified here
	org	100h

start:
	jmp	sbegin
	db	3 dup (8), 3 dup (' ')

	page
;--------------------------------------------------------------------
;			    data areas
;--------------------------------------------------------------------
msghelp db    13,10

        db      'PC-MOS MOS Utility v5.02 (920831)     ',13,10           ;@@XLAT
        db      '(C) Copyright 1987-1992 The Software Link, Inc.',13,10 ;@@XLAT
        db      'All Rights Reserved, worldwide',13,10                  ;@@XLAT
        db      'Usage:     ',13,10     ;@@XLAT
	db	'.MOS MAP                    - display partition map                 ',13,10  ;@@XLAT
	db	'.MOS DIS術ODIS              - disable [enable] keyboard ready looping         ',13,10	;@@XLAT
	db	'.MOS USEIRQ n [hhhh]        - reserve irq n for application         ',13,10  ;@@XLAT
	db	'.MOS FREEIRQ n [hhhh]       - free irq n reserved by application    ',13,10  ;@@XLAT
	db	'.MOS IRQ                    - list irqs reserved on system          ',13,10  ;@@XLAT
	db	'.MOS WAIT event             - wait for event before continuing      ',13,10  ;@@XLAT
	db	'.MOS VMODE  mode            - set video mode                        ',13,10  ;@@XLAT
	db	'.MOS SERINIT n,r,p,b,s,h    - initialize a serial port              ',13,10  ;@@XLAT
	db	'.MOS RESIZE nnnK            - adjust partition size                 ',13,10  ;@@XLAT
	db	'.MOS INFO                   - displays system information           ',13,10  ;@@XLAT
	db	'.MOS DSPORT                 - disables a port from serial.sys       ',13,10  ;@@XLAT
	db	'.MOS FILES on這ff           - limit number of open files            ',13,10  ;@@XLAT
	db	'.MOS TSR on這ff             - turn on這ff enhanced TSR support      ',13,10  ;@@XLAT
	db	'.MOS KEYB at逍c貫n連b趺b    - define keyboard type & buffer type    ',13,10  ;@@XLAT
	db	'.MOS MOUSE n [,r] [,s]      - initialialize mouse for task          ',13,10  ;@@XLAT
	db	'.MOS MOUSE off              - turn mouse support off                ',13,10  ;@@XLAT
	db	'.MOS HOLD LPTn {nnnn}       - sets printer reservation time         ',13,10  ;@@XLAT
	db	'.MOS HOLD LPTx OFF          - release printer reservation for task      ',13,10  ;@@XLAT
        db      '.MOS HOLD COMx {nnnn}       - sets COM port reservation time        ',13,10  ;@@XLAT
        db      '.MOS HOLD COMx OFF          - release COM port reservation for task     ',13,10  ;@@XLAT
	db	'.MOS ROUTE LPTn COMn蚯PTn袍ERM術OTERM                               ',13,10  ;@@XLAT
	db	'                            - redirect printer I/O to another device',13,10  ;@@XLAT
        db      '.MOS ANSI on這ff            - turn on這ff ANSI.SYS support             ',13,10 ;@@XLAT
	db	'.MOS DOSVER 3.0 - 5.0       - set DOS version level.                ',13,10  ;@@XLAT
	db	'$',8,' ',26

sbegin:
	jmp	begin

	even
version:
	include version.inc

badmos	db	13,10,'Incorrect MOS Version ',13,10,'$'  ;@@XLAT

funtable label byte
	db	'MAP'
	dw	offset mapfun
	db	'DIS'
	dw	offset disfun
	db	'NOD'
	dw	offset nodfun
	db	'USE'
	dw	offset usefun
	db	'FRE'
	dw	offset frefun
	db	'IRQ'
	dw	offset irqfun
	db	'WAI'
	dw	offset waifun
	db	'VMO'
	dw	offset vmofun
	db	'SER'
	dw	offset serfun
	db	'ROU'
	dw	offset roufun
	db	'RES'
	dw	offset resfun
	db	'INF'
	dw	offset memfun
	db	'DSP'
	dw	offset dspfun
	db	'FIL'
	dw	offset limfun
	db	'SHA'
	dw	offset shafun
	db	'TSR'
	dw	offset tsrfun
	db	'KEY'
	dw	offset keyfun
	db	'MOU'
	dw	offset moufun
	db	'HOL'
	dw	offset holdfun
	db	'ANS'
	dw	offset ansifun
	db	'DOS'
	dw	offset dosfun
	db	5 dup(0ffh)

	even
wordten  dw    10
word16	 dw    16
hundred  dw    100
word3600 dw    3600
zero	 dw    0
curid	 dw    0
wtyear	 dw    0
wtdate	 dw    0
wttime	 dw    0
wtsecond dw    0
hours	 dw    0			; hours
seconds  dw    0			; seconds
cyear	 dw    0

cleanfg  db	'N'			; clean up 0's in front of bintohex
msgtype  dw    offset msgsupp		; sah 11/09/87 default secondary error message
is386mm  db	'N'			; indicates if 386 memory available
vgaflag  db	'N'			; indicates if vga is on system
mmflag	 db	'N'			; indicates that we have memory management
val1	 db	0
val2	 db	0
val3	 db	0
val4	db	0
lpttest  db	'LPT'
comtest  db	'COM'
tertest  db	'TER'
nottest  db	'NOT'
tmask	 db	1,2,4
ntmask	 db	254,253,251
baudhi	 dw	0
baudlo	 dw	0
bios	 dw	040h			; consent segment of bios
ismouse db	'N'			; indicates if mouse.sys is installed or not
mousefun dd	0			; offset to mosfunction driver
mouport dw	0			; port use for mouse
mouoffset dw	0			; mouse structure
moutcb	dw	0			; mouse tcb address
mouseg	dw	0			; mouse structure segment
mousoff dw	0			; offset to start of mouse structure
moumax	dw	0			; maximin mouse structures
baudtab  label	word
	dw	110			; bios compatible baudrates
	dw	150
	dw	300
	dw	600
	dw	1200
	dw	2400
	dw	4800
	dw	9600
	dw	0			; end of table
vmodes	 label	byte
msgmon	db	'MON'			; mono mode
	dw	offset tmono
msgcga	db	'CGA'			; cga color mode 80 column (graphics)
	dw	offset tcga
msgc40	db	'C40'			; cga color mode 40 column (graphics)
	dw	offset tc40
msghg1	db	'HG1'			; hercules type 1 support (32k)
	dw	offset thg1
msghg2	db	'HG2'			; hercules type 2 support (64k)
	dw	offset thg2
msge43	db	'E43'			; ega color mode 80 column 43 line
	dw	offset te43
msgega	db	'EGA'			; ega color mode 80 colunm (graphics)
	dw	offset tega
msge40	db	'E40'			; ega color mode 40 column (graphics)
	dw	offset te40
msgvga	db	'VGA'			; vga multitasking support (graphics)
	dw	offset tvga
msgv40	db	'V40'			; vga multitasking support (graphics)
	dw	offset tv40
	db	5 dup(0ffh)		; terminator

; the follow table is use to generate # of hours since janary 1st of that year

months	label word
	dw	0*24			; january
	dw	31*24			; february
	dw	59*24			; march
	dw	90*24			; april
	dw	120*24			; may
	dw	151*24			; june
	dw	181*24			; july
	dw	212*24			; august
	dw	243*24			; september
	dw	273*24			; october
	dw	304*24			; novenber
	dw	334*24			; december
	dw	365*24			; used in year overflow conditions

	assume es:scbs
irqtab	label word
irq2	dw    scbidq2
irq3	dw    scbidq3
irq4	dw    scbidq4
irq5	dw    scbidq5
irq6	dw    scbidq6
irq7	dw    scbidq7
	assume es:tcb

irqndx	dw	0			; save 0 based word index from getirq
tblbas	dw	0			; save base of port specific table
device	db    'EMMXXXX0',0		; ems driver name
memptr	dd    0
memcall dd    0
serdev	db    '$$SC',0
mdriver db    '$$MOUSE',0
minsign db    'N'
datedef db    0
msgfun	db    13,10,'Invalid option.                            ',13,10,'$'  ;@@XLAT
msgopnd db    13,10,'Invalid or missing operand.                ',13,10,'$'  ;@@XLAT
on	 db    'ON.',13,10,'$'
off	 db    'OFF.',13,10,'$' 	;@@XLAT
onflag	 db	 255			; 0 = off	1 = on	 255 = status
msgdisok db    13,10,'Disable keyboard mode set.                 ',13,10,'$'  ;@@XLAT
msgnodok db    13,10,'Normal keyboard mode set.               ',13,10,'$'  ;@@XLAT
msgbadtm db    13,10,'Invalid terminal mode.    ',13,10,'$'  ;@@XLAT
msgwatch db    'Another workstation is current viewing this task.                     '  ;@@XLAT
	 db	13,10,'$'
msgback  db    'Terminal mode requires to be executed only in the foreground.           '  ;@@XLAT
	 db	13,10,'$'
msgsupp  db    'Workstation does not support terminal mode.  '	;@@XLAT
	 db	13,10,'$'
msgmreq  db    'Memory Management required to make video change.      '  ;@@XLAT
	 db	13,10,'$'
;sah	 db    13,10		; for below
msgmemna db    'Not enough memory for mode change             ',13,10,'$'  ;@@XLAT
msgnost  db    13,10,'Not enough memory to allocate video state area               '  ;@@XLAT
	 db	13,10,'$'
modelst  db    'Available terminal mode are:        ',13,10,13,10  ;@@XLAT
	 db	'MONO -  Monochrome          ',13,10  ;@@XLAT
	 db	'CGA  -  CGA Color Graphics 80 Column           ',13,10  ;@@XLAT
	 db	'C40  -  CGA Color Graphics 40 Column           ',13,10  ;@@XLAT
	 db	'HG1  -  32k Hercules type 1 support            ',13,10  ;@@XLAT
	 db	'HG2  -  64k Hercules type 2 support            ',13,10  ;@@XLAT
	 db	'E43  -  43 Line EGA Main Console               ',13,10  ;@@XLAT
	 db	'EGA  -  Multitasking EGA Graphics 80 Column           ',13,10	;@@XLAT
	 db	'E40  -  Multitasking EGA Graphics 40 Column           ' ,13,10  ;@@XLAT
	 db	'VGA  -  Multitasking VGA Graphics 80 Column           ',13,10	;@@XLAT
	 db	'V40  -  Multitasking VGA Graphics 40 Column           ',13,10	;@@XLAT
	 db	'$'
msgterm  db    13,10,'Terminal Mode set to $            '  ;@@XLAT
msgbadwt db    13,10,'Invalid wait time   ',13,10,'$'  ;@@XLAT
msgwait  db    13,10,'Wait active...Press any key to abort                  ',13,10,'$'  ;@@XLAT
msgabort db    'Wait aborted by user.                  ',13,10,'$'  ;@@XLAT
msgirq	 db    13,10,'IRQ'
irqval	 db    'n: $'
irqset	 db    'n: $'
msgna	 db    'already in use by $         '  ;@@XLAT
msgdev	 db    'device driver.      ',13,10,'$'  ;@@XLAT
msgtask  db    'another task.',13,10,'$';@@XLAT
msgresv  db    'now reserved for application use.  ',13,10,'$'	;@@XLAT
msgfree  db    'now freed from application use.            ',13,10,'$'	;@@XLAT
msgnofr  db    'cannot be freed because it is reserved by $           '  ;@@XLAT
msgnoap  db    'cannot be freed because it is not reserved by any application.      ',13,10,'$'  ;@@XLAT
msgbirq  db    13,10,'Invalid IRQ specified    ',13,10,'$'  ;@@XLAT
msgbport db    13,10,'Invalid I/O port specified                     ',13,10,'$'  ;@@XLAT
msgbrate db    13,10,'Invalid baud rate specified  ',13,10,'$'	;@@XLAT
msgbpar  db    13,10,'Invaild parity (O, E, or N)    ',13,10,'$'  ;@@XLAT
msgbdata db    13,10,'Invalid number of data bits (7 or 8)      ',13,10,'$'  ;@@XLAT
msgbstop db    13,10,'Invalid number of stop bits (1 or 2)      ',13,10,'$'  ;@@XLAT
msgbhand db    13,10,'Invalid Hand Shaking (N,D,X,P, or R)          ',13,10,'$'   ;@@XLAT
msghand	db      'Handshaking set to $          ',13,10,'$'     	;@@XLAT
msgdtr	db	'DTR.         ',13,10,'$'		;@@XLAT
msgxoff db	'XON/XOFF.       ',13,10,'$'		;@@XLAT
msgxpc  db	'XPC.           ',13,10,'$'		;@@XLAT
msgrts	db	'RTS.          ',13,10,'$'		;@@XLAT
SerMsgTab label word
	dw	offset msgdtr
	dw	offset msgxoff
	dw	offset msgxpc
	dw	offset msgrts
SerProt label	byte
	db	04h			; DTR
	db	03h			; XON\XOFF
	db	03h			; XPC
	db	08h			; DTR, XPC and RTS
SerXOFF	label	word 	
	dw	0
	dw	1311h			; XON\XOFF
	dw	6765h			; XPC
	dw	0
msgmem	 label byte
availval db    '     K of '		;@@XLAT
totalval db    '     K Memory Available$'  ;@@XLAT
msglen	 equ   $-msgmem-1
msgemem  label byte
emsavail db    '     K of '		;@@XLAT
emstotal db    '     K Expanded Memory Available$'  ;@@XLAT
msgelen  equ   $-msgemem-1
crlf	 db    13,10,'$'
msgroute db    13,10,'Routing ' 	;@@XLAT
dev1	 db    'LPT1 TO '		;@@XLAT
dev2	 db    'COM1     ',13,10,'$'
msgser	 db    13,10,'COM1  port set to '  ;@@XLAT
baudval  db    6 dup (' '),','
msgserpa db    'N,8,1',13,10,'$'
msgsize  db    13,10,'Partition size change to    '  ;@@XLAT
sizeval  db    4 dup (' '),'K.',13,10,'$'
msginsmem db   13,10,'Insufficent memory to resize task                  ',13,10,'$'  ;@@XLAT
msgmsmall db   13,10,'Task must have at least 32k free memory         ',13,10,'$'  ;@@XLAT
msgfrag  db    13,10,'Memory fragmented     ',13,10,'$'  ;@@XLAT
msgintn  db    13,10,'Internal error occurred while resizing memory ',13,10,'$'  ;@@XLAT
msgmmsg  db    13,10
	 db	'PC-MOS System Information         Start     End ',13,10,13,10	;@@XLAT
	 db	'$'
msgmalc  db    13,10
	 db	'MOS Kernel Segment #1             '  ;@@XLAT
msgkern  db    4 dup (' '),'0    '
msgkend  db    4 dup (' '),'0',13,10
	 db	'MOS Kernel Segment #2             '  ;@@XLAT
msgkern2 db    4 dup (' '),'0    '
msgkend2 db    4 dup (' '),'0',13,10
	 db	'System Memory Pool (SMP) #1       '  ;@@XLAT
msgsmp1  db    4 dup (' '),'0    '
msgsmp2  db    4 dup (' '),'0',13,10
	 db	'$'
msghp2	 db    'System Memory Pool (SMP) #2       '  ;@@XLAT
msgsmp1a db    4 dup (' '),'0    '
msgsmp2a db    4 dup (' '),'0',13,10
	 db	'$'
msgrest  db	'Disk Cache Descriptors            '  ;@@XLAT
msgdsk1  db    4 dup (' '),'0    '
msgdsk2  db    4 dup (' '),'0',13,10
	 db	'Disk Cache                        '  ;@@XLAT
msgcach1 db	4 dup(' '),'0    '
msgcach2 db	4 dup(' '),'0',13,10
	 db	'Command Processor                 '  ;@@XLAT
msgcp1	 db    4 dup (' '),'0    '
msgcp2	 db    4 dup (' '),'0',13,10
killme	 db     'Master Video Context Area         '  ;@@XLAT
msgmtv1  db    4 dup (' '),'0    '
msgmtv2  db    4 dup (' '),'0',13,10
	 db	'$'
msgfmem  db    'Freemem =                         '  ;@@XLAT
msgfbeg  db    4 dup (' '),'0    '
msgfend  db    4 dup (' '),'0',13,10,'$'
msgfno	 db    'Freemem =                         NO <NOT RELOCATED>     ',13,10,'$'  ;@@XLAT
msgsalc  db    5 dup (' '),'K of '	;@@XLAT
msgsmax  db    5 dup (' '),'K SMP Allocated '  ;@@XLAT
	 db	13,10,'$'
maphead  db    13,10
	 db	25 dup (' ')
	 db	'PC-MOS USER TASK STATISTICS     ',13,10,13,10	;@@XLAT
	 db	'Task Start Size Video  User    Program     Port   Baud   Pri Slice Files  Status',13,10,'$'  ;@@XLAT
maparea  db    79 dup (' '),13,10,'$'
active	 db    'ACT  '			;@@XLAT
waitmsg  db    'WAIT  ' 		;@@XLAT
hold	 db    'HOLD  ' 		;@@XLAT
msgdsfg  db    'DS'
msgndfg  db    'ND'
txtcrlf  db    13,10,'$'
namsg	 db    'N/A$'			;@@XLAT
msgdsp1 db	13,10,'Port cannot be disabled, in use by task                 ',13,10,13,10,'$'  ;@@XLAT
msgdsp2 db	13,10,'Port cannot be disabled, irq is shared           ',13,10,13,10,'$'  ;@@XLAT
msgdsp3 db	13,10,'Port disabled successfully',13,10,13,10,'$'  ;@@XLAT
msgdsp4 db	13,10,'Port cannot be disabled, $SERIAL.SYS not found               ',13,10,13,10,'$'  ;@@XLAT
msgdsp5 db	13,10,'Port cannot be disabled, reservation in place               ',13,10,13,10,'$'  ;@@XLAT
upmsg1	db	13,10
upmsg1a db	'Duplicate entry in IRQ reservation        ',13,10,13,10,'$'  ;@@XLAT
upmsg2	db	13,10,'Invalid port address           ',13,10,13,10,'$'  ;@@XLAT
upmsg3	db	13,10,'The table for this irq is full  ',13,10,13,10,'$'  ;@@XLAT
upmsg4	db	13,10,'Port address not found in table                    ',13,10,13,10,'$'  ;@@XLAT
upmsg5	db	13,10,'Port specific IRQ reservation $         '  ;@@XLAT
upmsg6	db	'registered ',13,10,13,10,'$'  ;@@XLAT
upmsg7	db	'removed ',13,10,13,10,'$'  ;@@XLAT
irqmsg1 db	'--      '
irqmsg2 db	' --    ($'
irqmsg3 db	'reserved by device driver)   ',13,10,'$'  ;@@XLAT
irqmsg4 db	'non port specific reservation)            ',13,10,'$'	;@@XLAT
sixspace db	'      $'
irqheader db	13,10,13,10,'IRQ    TASK     PORT',13,10  ;@@XLAT
	db	'---   ------   ------',13,10,'$'  ;@@XLAT
msgtsron db	13,10,'Enable.   ',13,10,'$'  ;@@XLAT
msgtsroff db	13,10,'Disable.   ',13,10,'$'  ;@@XLAT
msgansi  db    13,10,'ANSI.SYS Emulation is $'	;@@XLAT
msgfile  db    13,10,'Number of open files is $        '  ;@@XLAT
msgunlim db    'unlimited    ',13,10,'$';@@XLAT
msglim	 db    'limited      ',13,10,'$';@@XLAT
msgshare db    13,10,'Share support is $        '  ;@@XLAT
msgkeyb db	13,10,'Keyboard handling set to $     '  ;@@XLAT
msgkpc	db	'PC',13,10,'$'
msgkat	db	'AT',13,10,'$'
msgken	db	'Enhanced AT   ',13,10,'$'  ;@@XLAT
msgkbl	db	13,10,'Keyboard buffer set to $     '  ;@@XLAT
msgksb	db	'small    ',13,10,'$'	;@@XLAT
msgklb	db	'large    ',13,10,'$'	;@@XLAT
msgnomou db	13,10,'Mouse driver is not installed on system.       ',13,10,'$'  ;@@XLAT
msgmouse db	13,10,'Mouse installed on Port $      '  ;@@XLAT
msgmport db	' x at '		;@@XLAT
msgmbaud db	'    x Baud.     ',13,10,'$'  ;@@XLAT
msgmnins db	13,10,'Mouse is currently not installed for this task.       ',13,10,'$'  ;@@XLAT
msgmsupp db	13,10,'Generic Mouse support is $          '  ;@@XLAT
msgcom	 db	13,10,'Communications Driver Description          |  '	;@@XLAT
	 db	'First    |  Last  ',13,10  ;@@XLAT
	 db	      '-------------------------------------------|--'
	 db	'---------|--------',13,10,'$'
msgcom1  db	'   |  COM '
vcom1	 db	'nn   |  COM '
vcom2	 db	'nn',13,10,'$'
msgnocom db	'Non-Specified Serial Ports              '  ;@@XLAT

msgdos	db	13,10, 'DOS Version Level is $        '  ;@@XLAT
baddos	db	13,10, 'Invalid DOS Version Level (3.0 - 5.0 Only)      ',13,10,'$'  ;@@XLAT
msgdosver  db	'5.00.',13,10,'$'


egatab	 label	byte
	db	00h			; sequencer index
	db	03h,00h,03h,00h,02h	; sequencer values
	db	00h			; attribute index
	db	00h			; attribute flip-flop
	db	00h,01h,02h,03h,04h,05h,14h,07h,38h,3fh  ; attribute values
	db	3ah,3fh,3ch,3fh,3eh,3fh,0ch,00h,0fh
	db	00h			; graphics index
	db	00h,00h,00h,00h,00h,10h,0eh,00h,0ffh  ; graphics values
egalen	equ	$-egatab
paltab	label	byte
	db	00h,01h,02h,03h,04h,05h,14h,07h,38h  ; default ega pals
	db	39h,3ah,3bh,3ch,3dh,3eh,3fh,00h
pallen	equ	$-paltab
	even
savecx	dw	0

	page
;--------------------------------------------------------------------
;			  initialization
;--------------------------------------------------------------------
begin:

; routine to check mos version

	mov	ah,30h
	mov	bx,ax
	mov	cx,ax
	mov	dx,ax
	int	21h
	cmp	ax,word ptr [version]
	je	mosok
	mov	dx, offset badmos
	mov	ah,9
	int	21h
	mov	ax,4c01h
	int	21h
mosok:
	push	cs
	pop	es
	mov	bx,offset endofmos+15
	mov	cl,4
	shr	bx,cl
	mov	ah,4ah
	int	21h
	mov	si,offset operands+1	; si scans command line

; identify requested function

	call	nextopnd		; locate first operand
	jz	nofun
	mov	bx,offset funtable
	mov	ax,[si]
	mov	dl,[si+2]
	and	ax,0dfdfh		; convert to upper case
	and	dl,0dfh
scanftab:
	cmp	ax,[bx]
	jne	scanfcon
	cmp	dl,[bx+2]
	jne	scanfcon
	jmp	word ptr [bx+3]
scanfcon:
	add	bx,5
	cmp	byte ptr [bx],0ffh
	jne	scanftab
errfun:
	mov	dx,offset msgfun
	jmp	errexit
nofun:
	mov	dx,offset msghelp
	jmp	fundone

;-------------------------------
; 'mos dis' logic
;-------------------------------
disfun:
	call	getcurtcb
	or	byte ptr es:[tcbloop],1 ; set dis bit
	mov	dx,offset msgdisok
	jmp	fundone

;-------------------------------
; 'mos nodis' logic
;-------------------------------
nodfun:
	call	getcurtcb
	and	byte ptr es:[tcbloop],0feh  ; clear dis bit
	mov	dx,offset msgnodok
	jmp	fundone

;-------------------------------
; 'mos map' logic
;-------------------------------
mapfun:
	mov	dx,offset maphead
	call	writemsg
	call	getcurtcb
	mov	ah,02h
	int	services
	mov	ax,es:[bx]
	mov	es,ax
maploop:
	cmp	byte ptr es:[tcbtype],'T'
	jne	mapdone
	call	mapdisp
	mov	es,ax
	or	ax,ax
	jnz	short maploop
mapdone:
	mov	dx,offset txtcrlf
	call	writemsg
	call	getmdev 		; get memory device
	cmp	word ptr [memptr],0
	jne	mapdon1 		; skip if not found
	jmp	mapend1
mapdon1:
	push	es
	les	si,[memptr]		; cloned from mosinit.asm
	mov	cx,5
	mov	ax,es:[si+10]
	sub	ax,es:[si+14]
	shl	ax,1
	shl	ax,1
	mov	bx,offset availval+4
	xor	dx,dx
	call	bintodec
	mov	cx,5
	mov	ax,es:[si+10]
	shl	ax,1
	shl	ax,1
	mov	bx,offset totalval+4
	call	bintodec
	mov	dx,offset msgmem
	call	writemsg
	pop	es
mapcont:
	mov	ah,3dh
	mov	dx,offset device
	xor	al,al
	int	21h			; open driver ems
	jc	mapend
	mov	bx,ax			; save handle
	mov	ax,4400h
	int	21h
	jc	mapend
	test	dx,0080h
	jz	mapend
	mov	dx,offset maparea
	mov	ax,4407h
	xor	cx,cx
	int	21h
	jc	mapend
	push	ax
	mov	ah,3eh
	int	21h
	pop	ax
	cmp	al,0ffh
	jne	mapend
	mov	ah,42h
	int	67h
	test	ah,ah
	jnz	mapend
	push	dx
	mov	ax,bx
	mov	cl,4
	shl	ax,cl
	mov	bx,offset emsavail+4
	xor	dx,dx
	call	bintodec
	pop	dx
	mov	ax,dx
	mov	cl,4
	shl	ax,cl
	mov	bx,offset emstotal+4
	xor	dx,dx
	call	bintodec
	mov	cx,79
	sub	cx,msgelen
	sub	cx,msglen
msgspac:
	mov	dl,' '
	mov	ah,2
	int	21h
	loop	msgspac
	mov	dx,offset msgemem
	call	writemsg
mapend:
	mov	dx,offset txtcrlf
	call	writemsg
mapend1:
	call	smpuse
	mov	ax,4c00h		; terminate with no error
	int	21h

;-------------------------------
; subroutines for map logic
;-------------------------------

na_baud:
	mov	si,offset namsg
	mov	di,offset maparea+51
	mov	cx,3
	call	movelong
	ret
cnvt_port:
	inc	ax
	mov	cx,2
	mov	bx,offset maparea+46
	xor	dx,dx
	call	bintodec
	ret

;-------------------------------
; module: mapdisp
; input:
;	  es = segment of tcb
; output:
;	  es = segment of tcb
;-------------------------------
mapdisp   proc  near
	push	es
	push	cs
	pop	es
	mov	di,offset maparea
	mov	ax,2020h
	mov	cx,39
	rep	stosw
	pop	es
	assume	es:tcb
	mov	ax,es:[tcbid]		; tcb id #
	mov	cx,2
	mov	bx,offset maparea+1
	cmp	ax,[curid]
	jne	notcurid
	mov	byte ptr [bx+1],'*'
notcurid:
	xor	dx,dx
	call	bintodec
	mov	ax,es:[tcbbegad]	; tcb starting address
	mov	bx,offset maparea+8
	call	bintohex
	mov	byte ptr [maparea+9],'0'
	mov	ax,es:[tcbendad]	; tcb size
	sub	ax,es:[tcbbegad]
	mov	cx,6
	shr	ax,cl
	mov	cx,3
	mov	bx,offset maparea+13
	push	bx
	xor	dx,dx
	call	bintodec
	pop	bx
	mov	byte ptr [bx+1],'K'
	mov	cx,3
	mov	di,offset maparea+17
	mov	byte ptr cs:[di+3],' '
	mov	si,offset msgcga
	test	[tcbvideo],16		; hg1 on system
	jnz	mapv01
	test	[tcbvideo],32		; hg2 on system
	jnz	mapv02
	test	[tcbvideo],4		; ega on system
	jnz	mapv00
	test	[tcbvideo],8		; vga on system
	jz	mapv0
	mov	si,offset msgvga	; idicate vga
	jmp	short mapvend
mapv00:
	mov	si,offset msgega
	jmp	short mapv0
mapv01:
	mov	si,offset msghg1
	jmp	mapvend
mapv02:
	mov	si,offset msghg2
	jmp	mapvend
mapv0:
	mov	cx,3
	mov	al,es:[tcbmode]
	cmp	al,7
	jne	mapv1
	mov	byte ptr cs:[di+3],'O'	; o for mon(o)
	mov	si,offset msgmon
	jmp	short mapvend
mapv1:
	cmp	es:[tcbrows],25
	jbe	mapv11
	mov	si,offset msge43
	jmp	short mapvend
mapv11:
	cmp	al,1
	ja	mapvend
	cmp	si,offset msgvga
	je	mapv2v
	cmp	si,offset msgega
	je	mapv2
	mov	si,offset msgc40
	jmp	short mapvend
mapv2v:
	mov	si,offset msgv40
	jmp	short mapvend
mapv2:
	mov	si,offset msge40
mapvend:
	call	movelong
	cmp	byte ptr es:[tcbuser],0
	je	nouser
	push	ds
	lea	si,es:[tcbuser] 	; tcb user id
	mov	di,offset maparea+24
	mov	cx,4
	push	es
	pop	ds
	call	movelong
	pop	ds
public nouser
nouser:
	push	ds			; tcb program name
	lea	si,es:[tcbprgnm]
	lea	di,maparea+29
	mov	cx,8
	push	es
	pop	ds
	call	movelong
	mov	byte ptr cs:[di],'.'
	inc	di
	mov	cx,3
	push	es
	pop	ds
	call	movelong
	pop	ds
	mov	ax,es:[tcbport] 	; tcb port #
	cmp	ax,-1
	je	portchk
	and	ax,07fffh		; mask out high bit for Emulink
	or	ax,ax
	jz	portchka
	test	es:[tcbvram],8
	jz	portcont
	push	ax
	push	bx
	push	es
	mov	ah,4
	xor	bx,bx
	int	services
	mov	al,es:[tcbvram]
	test	al,4			; for sunriver, must counteract increment
	jnz	skvna
	test	al,8			; for vna, must counteract increment
skvna:
	pop	es
	pop	bx
	pop	ax
	jz	portcont
	dec	ax
	jmp	portcont

; when tcbport == 0
;  if this is a vna task and the foreground is not vna
;   then this is the task at vna port 1 in a co-resident system
;    so --> portcont

portchka:
	test	es:[tcbvram],8
	jz	portchk
	push	es
	push	ax
	push	bx
	xor	bx,bx			; get first tcb
	mov	ah,4
	int	services
	test	es:[tcbvram],8
	pop	bx
	pop	ax
	pop	es
	jnz	portchk
	call	cnvt_port		; convert the port number
	call	na_baud 		; and write n/a for buad
	jmp	portdone
portchk:
	cmp	word ptr es:[tcbbaud],0
	jne	portcont
	cmp	word ptr es:[tcbbaud+2],0
	jne	portcont
	mov	si,offset namsg
	mov	di,offset maparea+44
	mov	cx,3
	call	movelong
vna_baud:
	call	na_baud
	jmp	short portdone
portcont:
	call	cnvt_port
	test	word ptr es:[tcbvram],8 ; for vna, use n/a for baud
	jnz	vna_baud
	mov	bx,offset maparea+53	; tcb baud rate
	mov	cx,6
	mov	ax,word ptr es:[tcbbaud]
	mov	dx,word ptr es:[tcbbaud+2]
	call	bintodec
portdone:
	mov	bx,offset maparea+57	; tcb priority
	mov	al,es:[tcbpri]
	shr	al,1			;tcb priority = priority * 2
	and	ax,000fh
	mov	cx,2
	xor	dx,dx
	call	bintodec
	mov	bx,offset maparea+62	; tcb time slice
	mov	al,es:[tcbslice]
	and	ax,00ffh
	mov	cx,3
	xor	dx,dx
	call	bintodec
	xor	cx,cx			; tcb open files
	push	es
	mov	ax,es:[tcbtfbpf]
	assume	es:tfb
	mov	es,ax
fileloop:
	cmp	es:[tfbtype],'F'
	jne	filedone
	inc	cx
	mov	ax,[tfbntcb]
	or	ax,ax
	jz	filedone
	mov	es,ax
	jmp	short fileloop
filedone:
	mov	bx,offset maparea+68
	mov	ax,cx
	mov	cx,5
	xor	dx,dx
	call	bintodec
	pop	es
	assume	es:tcb
	mov	di,offset maparea+72	; tcb wait status
	mov	si,offset hold
	mov	cx,4
	test	es:[tcbega],4		; test for state-pam hold
	jnz	mapdisp1
	mov	al,es:[tcbwait]
	mov	si,offset active
	or	al,al
	jz	mapdisp1
	mov	si,offset waitmsg
mapdisp1:
	call	movelong
	mov	cx,2
	mov	di,offset maparea+77
	mov	si,offset msgndfg
	test	es:[tcbloop],1
	jz	mapdisp2
	mov	si,offset msgdsfg
mapdisp2:
	call	movelong
	mov	dx,offset maparea
	call	writemsg
	mov	ax,es:[tcbtcbpn]
	mov	es,ax
	ret
mapdisp   endp

;-------------------------------
; module: smpuse
; input:
; output:
;-------------------------------
smpuse	proc
	push	es
	mov	ax,0a03h		; call mosheman for % heap
	int	services
	mov	ah,02h
	int	services
	assume	es:scbs
	mov	ax,es:[bx+scbhpalc]
	push	bx
	lea	bx,msgsalc+4
	call	smpadj
;TEMPS
        xor     dx, dx
;TEMPE
	call	bintodec
	pop	bx
	mov	ax,es:[bx+scbhpsiz]
	add	ax,es:[bx+scbhp2siz]
	lea	bx,msgsmax+4
	call	smpadj
;TEMPS
        xor     dx, dx
;TEMPE
	call	bintodec
	lea	dx,msgsalc
	call	writemsg
	pop	es
	ret
smpadj:
	mov	cx,6
	shr	ax,cl
	mov	cx,4
	xor	dx,dx
	ret
smpuse	endp

;-------------------------------
; 'mos info' logic
;-------------------------------
memfun:
	mov	[cleanfg],'Y'		; indicate to clean up bintohex
	mov	dx,offset msgmmsg
	call	writemsg
	mov	ah,02h
	int	services
	assume	es:scbs
	mov	ax,es			; get scb address
	mov	cx,4
	xor	dx,dx
	push	bx
	lea	bx,msgkern+3
	call	bintohex
	pop	bx
	mov	ax,[bx+scbmo2end]
	push	bx
	lea	bx,msgkend+3
	call	bintohex
	pop	bx
	mov	ax,[bx+scbmosadr]	; get mos segment
	cmp	ax,0ff00h		; is it high memory
	jb	nohigh
	mov	[cleanfg],'N'		; no zero clean up
	mov	[msgkern2-1],'1'	; make it in high memory
	mov	[msgkend2-1],'1'	; and end too...
nohigh:
	add	ax,0108h		; adjust for the fact that
	mov	cx,4			; we adjust the segment by 1080h
	push	bx
	lea	bx,msgkern2+3
	call	bintohex
	pop	bx
	mov	ax,[bx+scbmosend]
	push	bx
	lea	bx,msgkend2+3
	call	bintohex
	pop	bx
mfcont:
	mov	[cleanfg],'Y'
	cmp	byte ptr [bx+scbmmfg],'Y'
	je	mfmemman
	mov	byte ptr [killme],'$'	; terminate message
	jmp	short mfnonmem
mfmemman:
	mov	ax,[bx+scbmastv]
	push	ax
	push	bx
	lea	bx,msgmtv1+3
	call	bintohex
	pop	bx
	pop	ax
	add	ah,byte ptr [bx+scbmastp]  ;#jrb actual size reserved
memmono:
	push	bx
	lea	bx,msgmtv2+3
	call	bintohex
	pop	bx
mfnonmem:
	mov	ax,[bx+scbhpadr]	; get start of heap
	push	bx
	lea	bx,msgsmp1+3
	push	ax
	call	bintohex
	pop	ax
	pop	bx
	add	ax,[bx+scbhpsiz]	; end of heap=start of heap + size of heap
	push	bx
	lea	bx,msgsmp2+3
	call	bintohex
	pop	bx
	cmp	[bx+scbhp2siz],0
	je	no2ndhp
	mov	ax,[bx+scbhp2adr]	; get start of heap
	push	bx
	lea	bx,msgsmp1a+3
	push	ax
	call	bintohex
	pop	ax
	pop	bx
	add	ax,[bx+scbhp2siz]	; end of heap=start of heap + size of heap
	push	bx
	lea	bx,msgsmp2a+3
	call	bintohex
	pop	bx
no2ndhp:
	mov	ax,[bx+scbcpseg]
	push	bx
	push	ax
	lea	bx,msgcp1+3
	call	bintohex
	pop	ax
	pop	bx
	push	bx
	add	ax,[bx+scbcpsiz]	; get size of command processor
	lea	bx,msgcp2+3
	call	bintohex
	pop	bx
	mov	ax,[bx+scbclst] 	; cache descriptor list start
	push	bx
	lea	bx,msgdsk1+3
	call	bintohex
	pop	bx
	mov	ax,[bx+scbcnum] 	; cache descriptor list end
	add	ax,[bx+scbclst]
	push	bx
	lea	bx,msgdsk2+3
	call	bintohex
	pop	bx
	test	[bx+scbmmfea],80h	;jrbw
	jnz	memj1			;jrbw
	mov	ax,[bx+scbchdl] 	; cache start if no mm
	push	bx
	lea	bx,msgcach1+3
	call	bintohex
	pop	bx
	mov	ax,[bx+scbcnum] 	; compute cache end if no mm
	mul	[bx+scbcuob]
	add	ax,[bx+scbchdl]
	push	bx
	lea	bx,msgcach2+3
	call	bintohex
	pop	bx
	jmp	memj2			;jrbw
memj1:
	mov	ax,[bx+scbcseg] 	; cache mapping area start
	push	bx
	lea	bx,msgcach1+3
	call	bintohex
	pop	bx
	mov	ax,[bx+scbcseg]
	add	ah,byte ptr [bx+scbcsegp]  ; cache mapping area end
	push	bx
	lea	bx,msgcach2+3
	call	bintohex
	pop	bx
memj2:
	xor	si,si			; zero out pointer
	cmp	word ptr es:[bx+scbbuff],0
	jne	memdo
	lea	dx,msgfno		; not relocated
	jmp	memdisp
memdo:
	cmp	si,20			; end of list
	jae	memdone
	xor	dx,dx
	mov	ax,[bx+si+scbbuff]
	or	ax,ax
	jz	memdone
	push	bx
	lea	bx,msgfbeg+3
	call	bintohex
	pop	bx
	mov	ax,[bx+si+scbbuff+2]
	push	bx
	lea	bx,msgfend+3
	call	bintohex
	pop	bx
	add	si,4
	lea	dx,msgfmem
	call	writemsg
	jmp	memdo
memdisp:
	call	writemsg
memdone:
	mov	[cleanfg],'N'
	lea	dx,msgmalc
	call	writemsg
	cmp	[bx+scbhp2siz],0
	je	nohp2msg
	lea	dx,msghp2
	call	writemsg
nohp2msg:
	lea	dx,msgrest
	call	writemsg

; the following is use to display information about com drivers on
; the system. it uses a new int 14h function 12h which will pull out
; a 40 byte description of driver.
; handle comport information here

	push	ds
	push	es
	xor	si,si
comloop:
	mov	di,si
	mov	dx,si
	mov	ah,6
	int	14h			; does serial driver exist
	test	ah,80h
	jnz	comfirst
	jmp	comdone 		; no serial driver so just exits
comfirst:
	push	cs
	pop	ds
	push	dx
	lea	dx,crlf
	call	writemsg
	lea	dx,msgcom		; display header message
	call	writemsg
	pop	dx
	mov	ah,12h
	int	14h			; get description from driver
	mov	dx,bx
	or	ax,ax			; check to see if driver supported
	jz	comok			; getting message from driver
	push	cs
	pop	ds
	lea	dx,msgnocom		; use default message
comok:
	push	ds
	pop	es			; save segment in es for later
	call	dumpcmsg		; dump com msg

; the following is main loop checking ports

comloop2:
	inc	si
	mov	dx,si
	mov	ah,6
	int	14h			; test to see if port exist
	cmp	ah,0ffh 		; this means that it is invalid port
	jz	comdone1
	test	ah,80h			; driver might do it this way
	jz	comdone1
	lea	bx,msgnocom
	push	cs			; set defaults for non-supported
	pop	ds
	mov	ah,12h			; get driver description
	int	14h
	mov	dx,bx
	mov	ax,ds
	mov	bx,es
	cmp	ax,bx			; same driver
	je	comloop2
comptest:
	dec	si
	call	dispcomp
	inc	si
	push	ds
	pop	es
	call	dumpcmsg
	mov	di,si
	jmp	comloop2

; the following routine is use to set and display the first and
; last comport range for specific driver.
; di = first comport - 1
; si = last comport - 1

dispcomp:
	push	ds
	push	dx
	mov	cx,di
	call	adjcomp
	mov	word ptr cs:[vcom1],bx
	mov	cx,si
	call	adjcomp
	mov	word ptr cs:[vcom2],bx
	push	cs
	pop	ds
	lea	dx,msgcom1
	call	writemsg
	pop	dx
	pop	ds
	ret

; the following routine is use by dispcomp to convert bin number
; into displayable value ie com1 ,,, com12
;
; cx = binary - 1
;
; returns
; bx = asci value

adjcomp:
	mov	bh,' '
	inc	cx
	cmp	cl,9
	ja	adjhigh
	mov	bl,cl
	add	bl,'0'
	ret
adjhigh:
	mov	bl,'0'
adjloop:
	sub	cl,10
	inc	bl
	cmp	cl,9
	ja	adjloop
	mov	bh,cl
	add	bh,'0'
	ret


; routine to dump com message pointed by ds:dx
; 40 bytes


dumpcmsg:
	push	cx
	push	dx
	push	si
	mov	si,dx
	mov	cx,40			; dump 40 bytes of message
	cld
comdump:
	lodsb
	mov	dl,al			; dump it one byte at a time
	mov	ah,2
	int	21h
	loop	comdump
	pop	si
	pop	dx
	pop	cx
	ret
comdone1:
	dec	si
	call	dispcomp
comdone:
	pop	es
	pop	ds
	lea	dx,crlf
	jmp	fundone

;-------------------------------
; 'mos useirq n' logic
;-------------------------------

; the following equate must match with the values used in the irq logic
; within mosnxtsk.asm and mosint38.asm (extfun16).

fpiq	equ	16			; fields per irq in data table

usefun:
	call	check_port		; bp = 0 means no second parm, else bp -> parm
	call	getirq			; get irq from command line
	cmp	al,3			; bad operand
	jne	use1
	jmp	erropnd
use1:
	or	al,al
	jz	use2
	lea	dx,msgbirq		; invalid irq
	jmp	errexit
use2:
	mov	[irqndx],bx		; save 0 based word index
	mov	ah,02h
	int	services
	or	bp,bp			; is there a port address parameter??
	jnz	useprt0
	assume es:scbs
	push	bx
	push	es
	mov	es,[bx+scbidqp]		; check for port specific irq reservation
	mov	al,[irqval]		; and report conflict if find.
	sub	al,'2'			; recover irq number
	xor	ah,ah
	mov	bx,fpiq
	push	dx
	mul	bx
	pop	dx
	mov	bx,ax			; bx = irq_num * fpiq * 4   to calc the start
	shl	bx,1			; of the table region for the irq
	shl	bx,1
	cmp	word ptr es:[bx],0
	pop	es
	pop	bx
	je	use2a
	lea	dx,[upmsg1a]
	jmp	useerr2
use2a:
	cmp	word ptr es:[bx+si],-1
	jne	use3
	lea	dx,msgdev
	jmp	useerr
use3:
	mov	ax,es:[bx+si]		; if already reserved by current
	cmp	ax,es:[bx+scbtcbpc]	; task, let go through without error
	je	use4
	or	ax,ax
	je	use4
	lea	dx,msgtask		; already reserved
	mov	al,1
	jmp	useerr
useerr:
	push	dx
	lea	dx,msgna
	call	writemsg
	pop	dx
	mov	al,1
	jmp	errexit
use4:
	mov	ax,es:[bx+scbtcbpc]
	mov	word ptr es:[bx+si],ax
	mov	di,[irqndx]		; register the reservation
	add	di,offset scbirqd0a
	mov	word ptr es:[bx+di],irq_nps_res
	lea	dx,msgresv
	jmp	fundone

;-------------------------------
; 'mos useirq n hhhh' logic
;-------------------------------
useprt0:
	assume	es:scbs
	cmp	word ptr es:[bx+si],0
	je	upa
	lea	dx,[upmsg1]		; error: dup non port specific resv
	jmp	useerr2
upa:
	mov	si,bp
	call	hparm2int
	jnc	upb
	lea	dx,[upmsg2]		; invalid port address
	jmp	useerr2
upb:
	mov	bp,es:[bx+scbtcbpc]	; save current tcb segment in bp
	mov	es,[bx+scbidqp]
	assume	es:nothing
	xor	bx,bx			; pointer
	xor	si,si			; irq counter
	xor	di,di			; field # counter
upc:
	cmp	di,fpiq
	jne	upd
	cmp	si,5			; irq counter goes 0 through 5
	je	upf
	inc	si
	xor	di,di
upd:
	cmp	es:[bx],dx
	jne	upe
	mov	al,[irqval]
	sub	al,'2'			; recover irq number
	xor	ah,ah
	cmp	si,ax			; match irq number??
	jne	upda
	cmp	es:[bx+2],bp		; match current tcb??
	je	upi
upda:
	lea	dx,[upmsg1]		; duplicate entry
	jmp	useerr2
upe:
	add	bx,4
	inc	di
	jmp	upc
upf:
	mov	al,[irqval]
	sub	al,'2'			; recover irq number
	xor	ah,ah
	mov	bx,fpiq
	push	dx
	mul	bx
	pop	dx
	mov	bx,ax			; bx = irq_num * fpiq * 4   to calc the start
	shl	bx,1			; of the table region for the irq
	shl	bx,1
	mov	cx,fpiq
upg:
	cmp	word ptr es:[bx],0	; search for empty field
	jne	uph
	mov	es:[bx],dx		; assign port address
	mov	es:[bx+2],bp		; and current tcb segment
	mov	ah,02h
	int	services
	mov	di,[irqndx]		; register the reservation
	add	di,offset scbirqd0a
	mov	word ptr es:[bx+di],irq_ps_res
	jmp	upi
uph:
	add	bx,4
	loop	upg
	lea	dx,[upmsg3]		; table for this irq is full
	jmp	useerr2
upi:
	lea	dx,[upmsg5]
	call	writemsg
	lea	dx,[upmsg6]
	jmp	fundone
useerr2:
	mov	al,1
	jmp	errexit

;-------------------------------
; 'mos freeirq n' logic
;-------------------------------
frefun:
	call	check_port		; bp = 0 means no second parm, else bp -> parm
	call	getirq			; get irq from command line
	cmp	al,3			; bad operand
	jne	fre1
	jmp	erropnd
fre1:
	or	al,al
	jz	fre2
	lea	dx,msgbirq		; invalid irq
	jmp	errexit
	assume	es:tcb
fre2:
	mov	[irqndx],bx		; save 0 based word index
	mov	ah,02h
	int	services
	or	bp,bp			; is there a port address parameter??
	jnz	freprt0
	assume es:scbs
	cmp	word ptr es:[bx+si],-1
	jne	fre3
	lea	dx,msgdev
	jmp	freerr
fre3:
	mov	ax,es:[bx+si]
	cmp	ax,es:[bx+scbtcbpc]
	je	fre5
	or	ax,ax			; irq not reversed by any application
	jnz	fre4
	lea	dx,msgnoap
	jmp	useerr2
fre4:
	lea	dx,msgtask
freerr:
	push	dx
	lea	dx,msgnofr
	call	writemsg
	pop	dx
	mov	al,1
	jmp	errexit
fre5:
	mov	word ptr es:[bx+si],0
	mov	di,[irqndx]		; cancel the reservation
	add	di,offset scbirqd0a
	mov	word ptr es:[bx+di],irq_no_res
	lea	dx,msgfree
	jmp	fundone
	assume es:tcb

;-------------------------------
; 'mos freeirq n hhhh' logic
;-------------------------------
freprt0:
	assume es:scbs
	mov	di,es			; save scb segment
	mov	es,[bx+scbidqp]
	assume	es:nothing
	mov	si,bp
	mov	bp,bx			; save scb offset
	call	hparm2int
	jnc	fpa
	lea	dx,[upmsg2]		; invalid port address
	jmp	useerr2
fpa:
	mov	al,[irqval]
	sub	al,'2'			; recover irq number
	xor	ah,ah
	mov	bx,fpiq
	push	dx
	mul	bx
	pop	dx
	mov	bx,ax			; bx = irq_num * fpiq * 4   to calc the start
	shl	bx,1			; of the table region for the irq
	shl	bx,1
	mov	[tblbas],bx		; save base of list for this irq
	mov	cx,fpiq
fp1:
	cmp	es:[bx],dx		; find match for port address
	jne	fp2
	mov	ax,es:[bx+2]		; when find a match, get the task segment
	push	bx
	push	es
	mov	bx,bp			; can only remove from same task
	mov	es,di
	cmp	ax,es:[bx+scbtcbpc]
	pop	es
	pop	bx
	jne	fp7
	mov	word ptr es:[bx],0	; zap the entry
	jmp	fp3
fp2:
	add	bx,4
	loop	fp1
	lea	dx,[upmsg4]		; entry not found
	jmp	useerr2
fp3:
	mov	si,bx			; save pointer to entry just zapped
	dec	cx
	jcxz	fp6
fp4:
	add	bx,4
	cmp	word ptr es:[bx],0
	jne	fp5
	mov	ax,es:[bx-4]
	mov	es:[si],ax
	mov	ax,es:[bx-2]
	mov	es:[si+2],ax
	mov	word ptr es:[bx - 4],0
	jmp	fp6
fp5:
	loop	fp4
	mov	ax,es:[bx]
	mov	es:[si],ax
	mov	ax,es:[bx+2]
	mov	es:[si+2],ax
	mov	word ptr es:[bx],0
fp6:
	mov	bx,[tblbas]
	cmp	word ptr es:[bx],0	; is list empty for this irq?
	jnz	fp8
	mov	ah,02h
	int	services
	mov	di,[irqndx]		; cancel the reservation
	add	di,offset scbirqd0a
	mov	word ptr es:[bx+di],irq_no_res
fp8:
	lea	dx,[upmsg5]
	call	writemsg
	lea	dx,[upmsg7]
	jmp	fundone
fp7:
	lea	dx,[msgirq]
	call	writemsg
	lea	dx,msgnofr
	call	writemsg
	lea	dx,msgtask
	jmp	useerr2

;-------------------------------
; 'mos irq' logic
;-------------------------------
irqfun:
	call	getcurtcb
	xor	dx,dx			; reset header flag
	mov	ah,02h
	int	services
	assume	es:scbs
	mov	bp,bx			; save scb starting offset
	xor	cx,cx			; irq counter	0 through 5
mq1:
	lea	si,[scbidq2]
	add	si,bp
	mov	ax,cx
	shl	ax,1
	add	si,ax			; find scbidq table entry for irq
	cmp	es:[si],0ffffh
	jne	mq2
	call	disp_prep		; display line for device driver
	lea	dx,[irqmsg1]
	call	writemsg
	lea	dx,[irqmsg3]
	call	writemsg
	jmp	mq6
mq2:
	cmp	word ptr es:[si],0
	jz	mq3
	call	disp_prep		; display line for task (no port)
	push	es
	mov	es,es:[si]
	call	disp_taskid
	pop	es
	lea	dx,[irqmsg2]
	call	writemsg
	lea	dx,[irqmsg4]
	call	writemsg
	jmp	mq6
mq3:
	mov	ax,fpiq
	push	dx
	mul	cx
	pop	dx
	shl	ax,1
	shl	ax,1
	mov	di,ax			; di = fpiq * irq_num * 4
	push	es
	mov	bx,bp
	mov	es,[bx+scbidqp]
	assume	es:nothing
	xor	bx,bx
mq4:
	cmp	word ptr es:[di],0
	je	mq5
	call	disp_prep
	push	es
	mov	es,es:[di+2]
	call	disp_taskid
	pop	es
	mov	ax,es:[di]		; get port number from table
	lea	bx,[maparea+3]
	push	cx
	call	bintohex		; convert and display the port number
	lea	dx,[maparea]
	mov	cx,4
	xor	bx,bx
	mov	ah,40h
	int	21h
	lea	dx,[crlf]
	call	writemsg
	pop	cx
	add	di,4
	inc	bx
	cmp	bx,fpiq
	jne	mq4
mq5:
	pop	es
mq6:
	inc	cx
	cmp	cx,6
	je	mq7
	jmp	mq1
mq7:
	lea	dx,[crlf]
	jmp	fundone

;-------------------------------
; subroutines for irq logic
;-------------------------------
disp_prep:
	or	dx,dx
	jnz	mdsp1			; if not already up, put up the header
	lea	dx,[irqheader]
	call	writemsg
mdsp1:
	mov	dl,' '
	mov	ah,2			; display 1 space, the irq $, then 6 spaces
	int	21h
	mov	dl,cl
	add	dl,'2'
	mov	ah,2
	int	21h
	lea	dx,[sixspace]		; putting offset in dx sets the header flag
	call	writemsg
	ret

; entry parms:
;	es -> tcb
; exit parms:
;	task id displayed
;	dx != 0

disp_taskid:
	assume	es:tcb
	mov	ax,es:[tcbid]		; tcb id #
	push	cx
	mov	cx,2
	lea	bx,[maparea+1]
	mov	byte ptr [bx+1],' '
	cmp	ax,[curid]
	jne	mq2a
	mov	byte ptr [bx+1],'*'
mq2a:
	xor	dx,dx
	call	bintodec
	lea	dx,[maparea]
	mov	cx,3
	mov	bx,0			; display task id #
	mov	ah,40h
	int	21h
	pop	cx
	lea	dx,[sixspace+1]
	call	writemsg
	ret

; -------------------------- passdelims -----------------
; entry parms:
;	ds:si pointing to string
; exit parms:
;	al = non delim char
;	ds:si -> position in string of non delim char

passdelims:
	cld
psd1:
	lodsb
	cmp	al,' '
	je	psd1
	cmp	al,','
	je	psd1
	dec	si
	ret

; -------------------------- finddelim -----------------
; entry parms:
;	ds:si pointing to string
; exit parms:
;	al = delim char
;	ds:si -> position in string of delim char

finddelim:
	cld
fd1:
	lodsb
	cmp	al,' '
	je	fd2
	cmp	al,','
	je	fd2
	cmp	al,13
	je	fd2
	jmp	fd1
fd2:
	dec	si
	ret

;------------------------- check_port ---------------------
; entry parms:
;	ds:si pointing to parameter string
; exit parms:
;	ds:si restored to entry value
;	bp = 0 if no second parm
;	else ds:bp pointing to second parm

check_port:
	xor	bp,bp
	push	si
	call	passdelims		; find start of the "useirq" keyword
	cmp	al,13
	je	usem2
	call	finddelim
	cmp	al,13
	je	usem2
	call	passdelims		; find the start of irq number
	cmp	al,13
	je	usem2
	call	finddelim
	cmp	al,13
	je	usem2
	call	passdelims		; find the start of the port address
	cmp	al,13
	je	usem2
	mov	bp,si			; record start of port address
usem2:
	pop	si
	ret

;------------------------------ hparm2int ------------------
; entry parms:
;	ds:si -> port address parameter
; exit parms:
;	if nc - no error
;		port address in dx
;	if cy - invalid port address parameter

hparm2int:
	push	ax
	push	cx
	mov	al,byte ptr [si+4]	; make sure the hhhh parm is
	cmp	al,' '			; just 4 characters
	je	hp1a
	cmp	al,13
	jne	hp2
hp1a:
	xor	dx,dx
	mov	cx,12
hp1:
	lodsb
	mov	ah,48			; adjustment factor if al in '0'-'9'
	cmp	al,'0'
	jb	hp2
	cmp	al,'9'
	jna	hp3
	mov	ah,55			; adjustment factor if al in 'A'-'F'
	cmp	al,'A'
	jb	hp2
	cmp	al,'F'
	jna	hp3
	mov	ah,87			; adjustment factor if al in 'a'-'f'
	cmp	al,'a'
	jb	hp2
	cmp	al,'f'
	jna	hp3
hp2:
	stc				; invalid port address parameter
	jmp	hp4
hp3:
	sub	al,ah
	xor	ah,ah
	push	cx
	shl	ax,cl			; raise up based on place value
	add	dx,ax
	pop	cx
	sub	cx,4
	js	hp3a
	jmp	hp1
hp3a:
	clc
hp4:
	pop	cx
	pop	ax
	ret

;-----------------------------------------------------------------------
; module: getirq
; input:
; output:
;	al = error code  0 = ok ,1 = bad irq, 3 = bad operand
;	ah = irq	(display as irqn:)
;	si = offset into irq table (internal to mos.com)
;	bp = 0 if no port parm, else bp = port address
;	bx = 0 based word index
;-----------------------------------------------------------------------
getirq	proc
	call	nextopnd		; get next operand
	jnz	girq1
	mov	al,3			; bad operand
	ret
girq1:
	mov	bx,si
	call	dectobin
	cmp	ax,2			; 2 <= irq => 7
	jb	girq2
	cmp	ax,7
	ja	girq2
	mov	ah,al			; save irq
	xor	al,al
	mov	dl,'0'
	add	dl,ah
	mov	[irqval],dl
	or	bp,bp			; mjs 3/3/88
	jnz	girqm			; mjs 3/3/88
	lea	dx,msgirq
	call	writemsg
girqm:					; mjs 3/3/88
	mov	bl,ah
	xor	bh,bh
	dec	bx			; (irq - 2) * 2 + irqtab
	dec	bx
	shl	bx,1
	mov	si,[bx+irqtab]
	ret
girq2:
	mov	al,1			; 3/3/88
	ret
getirq	endp

;-------------------------------
; 'mos wait' logic
;-------------------------------
waifun:
	call	nextopnd
	jnz	wait1
	jmp	waitbad
wait1:
	mov	bx,si
	call	dectobin
	cmp	byte ptr [bx],'-'
	je	waitdate
	cmp	byte ptr [bx],':'
	je	waittime
	lea	dx,msgwait
	call	writemsg
	call	secwait 		; wait for ax seconds
	lea	dx,crlf
	jmp	fundone
waitdate:
	or	ax,ax
	jz	waitbad
	cmp	ax,12
	ja	waitbad
	inc	bx
	mov	dh,al
        push	dx
	call	dectobin
	pop	dx
	cmp	byte ptr [bx],'-'
	jne	waitbad
	or	ax,ax
	jz	waitbad
	cmp	ax,31
	ja	waitbad
	inc	bx
        mov     dl,al                   ;DH has month, DL has day.
	mov	[wtdate],dx
	call	dectobin
	cmp	ax,1980
	ja	waityear
	cmp	ax,99
	ja	waitbad
	cmp	ax,80			; > 1980
	ja	waitadj
	add	ax,100			; force to 2000-2079
waitadj:
	add	ax,1900 		; add 1900 for value

waityear:
	mov	[wtyear],ax
skipblk:
	cmp	byte ptr [bx],' '
	jne	waitcont
        inc     bx
	jmp	short skipblk		; loop until
waitbad:
	lea	dx,msgbadwt
	jmp	errexit
waittime:
	push	ax
	push	bx
	mov	ah,2ah			; get current date
	int	21h
	mov	[wtyear],cx
	mov	[wtdate],dx
	mov	[datedef],1		; using default data
	pop	bx
	pop	ax
	jmp	short waitchk
waitcont:
	call	dectobin
waitchk:
	cmp	ax,24
	jae	waitbad
	mov	dh,al
	cmp	byte ptr [bx],':'
	jne	waitbad
	inc	bx
	push	dx
	call	dectobin
	pop	dx
	cmp	ax,59
	ja	waitbad
	mov	dl,al
	mov	[wttime],dx
	cmp	byte ptr [bx],':'
	jne	waitok
	inc	bx
	call	dectobin
	cmp	ax,59
	ja	waitbad
	xchg	ah,al
	mov	[wtsecond],ax
waitok:

;  calculate time to wait

	mov	ah,2ah
	int	21h			; get date in cx & dx
	push	cx
	push	dx
	mov	ah,2ch
	int	21h			; get time
	mov	bx,dx
	mov	ax,cx
	pop	dx
	pop	cx
	mov	[cyear],cx		; save year for next date & time analysis
	call	timecalc		; do time caculations  bx=hours ax=seconds
	mov	[hours],bx
	mov	[seconds],ax
	mov	cx,[wtyear]
	cmp	cx,[cyear]
	jae	waitok1
	jmp	waitsick		; last year
waitok1:
	dec	cx
	cmp	cx,[cyear]
	jbe	waitok2
	jmp	waitsick		; crazy!
waitok2:
	inc	cx
	mov	dx,[wtdate]
	mov	bx,[wtsecond]
	mov	ax,[wttime]
	call	timecalc		; do time caculations	bx=hours ax=second
	cmp	ax,[seconds]
	jae	wait2
	add	ax,3600
	inc	[hours]
wait2:
	sub	ax,[seconds]
wait2lp:
	cmp	byte ptr [datedef],0
	jne	wait2y
	cmp	cx,[cyear]
	je	wait2y
	add	bx,word ptr [months+24]
	test	word ptr [cyear],3	; leap year???
	jnz	wait2y
	add	bx,24			; add for leap year
wait2y:
	cmp	bx,[hours]
	jae	wait3
	cmp	byte ptr [datedef],0
	je	wait2bad
	add	bx,24			; add 24 hours (a day)
	mov	byte ptr [datedef],0
	jmp	wait2lp
wait2bad:
	lea	dx,msgbadwt
	jmp	errexit
wait3:
	sub	bx,[hours]
	lea	dx,msgwait
	call	writemsg
waitloop:
	mov	cx,18			; default to 18 hours
	cmp	bx,cx
	ja	wloop1
	mov	cx,bx
wloop1:
	sub	bx,cx
	push	bx
	cmp	cx,18
	jne	wloop2
	xor	ax,ax
wloop2:
	push	ax
	xchg	ax,cx
	mul	[word3600]		; mult by 3600
	add	ax,cx
	call	secwait
	pop	ax
	pop	bx
	sub	ax,cx			; subject second before
	or	bx,bx
	jnz	waitloop
	or	ax,ax
	jnz	waitloop
	lea	dx,crlf
	jmp	fundone
waitsick:
	lea	dx,msgbadwt
	jmp	errexit

;-------------------------------
; subroutines for wait logic
;-------------------------------
;EDIT MARKER
;--------------------------------------------------------------------
; module timecalc - calculator hours since january 1st of that year
;	 plus remaining seconds
; input:
;	 ax = hours * 256 + minutes
;	 bx = seconds * 256 + hundreds (ignored)
;	 cx = year
;	 dx = month * 256 + day
; output:
;	 ax = hours since january 1st of year
;	 bx = seconds
;--------------------------------------------------------------------
timecalc proc
	push	cx
	push	dx
	push	ax
	xchg	bl,bh			; set seconds in lower half
	xor	bh,bh
	push	bx
	xor	ah,ah
	shl	ax,1
	shl	ax,1			; min*4
	mov	bx,ax
	shl	ax,1
	shl	ax,1			; min*16
	add	bx,ax
	mov	ax,bx			; min*20
	add	ax,bx
	add	ax,bx			; min*60
	pop	bx
	add	ax,bx			; min*60+seconds
	cmp	dh,2
	jb	tcalc1
	test	cx,3			; leap year
	jnz	tcalc1
	mov	cx,24			; addition 24 hours for leap year
	jmp	short tcalc2
tcalc1:
	xor	cx,cx
tcalc2:
	mov	bl,dh			; get month
	xor	bh,bh
	dec	bx
	shl	bx,1
	mov	bx,word ptr [bx+months]
	xor	dh,dh
	shl	dx,1
	shl	dx,1
	shl	dx,1			;  day *8
	add	bx,dx
	shl	dx,1			;  day*16
	add	bx,dx			;  + (day*24)
	add	bx,cx			;  add adjustment for leap year
	pop	cx			;  get ax save above (for hours)
	xchg	ch,cl
	xor	ch,ch
	add	bx,cx
	pop	dx
	pop	cx
	ret
timecalc endp

;---------------------------------------------------------------
; module secwait - waits for ax seconds
; input:
;	  ax = # of seconds to wait for (max = 65535 seconds)
;
;	checks key available on wake up from key
;	uses [tick_low] if resleep from null key
;---------------------------------------------------------------
secwait proc
	mov	bx,3600
	cmp	ax,bx			; test wait > 1 hour
	jbe	swait1hr

	sub	ax,bx
	push	ax			; save remaining seconds
	mov	ax,bx			; get 3600 seconds of wait
	call	swait1hr
	pop	ax
	test	ax,ax			; test any wait remaining
	jnz	secwait
	ret

tick_low equ	6ch			; low tick counter in bios data area

swait1hr:				; ax = seconds to wait
	push	cx
	push	dx
	push	es
	mov	bx,581
	mul	bx			; multiply secs by ticks/sec
	mov	bx,32			; 1,190,000 / 65536 = 581/32
	div	bx
	mov	bx,ax
swaitwat:
	mov	ax,bios 		; get current ticks
	mov	es,ax			; needed if null key awakes us
	mov	ax,es:[tick_low]
	push	ax			; save current tick and ticks to wait
	push	bx
	mov	ax,0703h		; mos wait key or time
	int	services
	test	al,1			; key stroke pressed
	jz	swaitok 		; no timer elapsed
	mov	ah,1			; test key available
	int	16h
	jnz	swaitabt		; yes abort exit
	pop	ax			; ticks to wait
	pop	bx			; tick at start
	add	bx,ax			; wait (secs*18.2 - newticks + oldticks)
	sub	bx,es:[tick_low]
	jz	swaitok2
	cmp	ax,bx			; test overwait
	jb	swaitok2
	jmp	swaitwat		; less than started, wait remainder
swaitabt:				; key pressed abort wait
	lea	dx,msgabort
	push	cs
	pop	ds
	call	writemsg
	mov	ax,4c01h
	int	21h
swaitok:
	pop	bx
	pop	ax
swaitok2:
	pop	es
	pop	dx
	pop	cx
	ret
secwait endp

;-------------------------------
; 'mos vmode ???' logic
;-------------------------------
vmofun:
	mov	[val2],'N'		; sah set ega card to have 64k
	call	is386			; set byte to indicate if 386 on system
	cmp	[mmflag],'Y'		; sah is memory management on system
	je	vminst			; sah
	mov	[msgtype],offset msgmreq; sah
	jmp	vmbadtrm		; sah		use double message system
vminst: 				; sah
	call	nextopnd
	jz	vmobad			; sah display available terminal types
vmofun0:
	lodsb
	cmp	al,'9'
	jbe	vmofun1
	and	al,0dfh
vmofun1:
	mov	dl,al
	lodsw
	cmp	al,'9'
	jbe	vmofun2
	and	al,0dfh
vmofun2:
	cmp	ah,'9'
	jbe	vmofun3
	and	ah,0dfh
vmofun3:
	mov	cx,ax
	lea	si,vmodes
vmoloop:
	lodsb
	cmp	al,0ffh
	je	vmobad
	cmp	al,dl			; first character
	jne	vmoskip
	lodsw
	cmp	ax,cx			; is this it
	jne	vmoskip2
	lodsw
	push	ax
	call	getcurtcb
	pop	ax
	assume es:tcb
	mov	byte ptr [val1],0	; sah indicate no special mode
	or	[tcbvram],1		; sah turn on video ram
	mov	cx,si
	sub	cx,5
	call	vermode 		; verify mode
	or	cx,cx
	jnz	vmover
vmbadtrm:				; sah display bad term message
	lea	dx,msgbadtm
	call	writemsg
	mov	dx,[msgtype]
	jmp	errexit
vmover:
	cmp	cx,-1
	jne	vmover1
	lea	dx,msgnost
	jmp	errexit
vmover1:
	mov	bx,ax
	push	si
	push	bx
	call	bx			; do action
	pop	bx
	pop	si
	jc	vmona
	jmp	vmoend
vmona:
	mov	[msgtype],offset msgmemna  ;sah no memory
	jmp	vmbadtrm		;sah bad terminal type
vmoskip:
	lodsw				; remove second param
vmoskip2:
	lodsw				; remove function
	jmp	short vmoloop
vmobad:
	mov	[msgtype],offset modelst; sah bad terminal operand
	jmp	vmbadtrm		; sah display list
vmoend:
	lea	dx,msgterm
	call	writemsg
	sub	si,5
	mov	dl,byte ptr [si]
	cmp	[vgaflag],'Y'		; sah convert to vga
	jne	vmoend1 		; sah
	mov	dl,'V'			; sah
vmoend1:				; sah
	mov	ah,2
	int	21h
	mov	dl,byte ptr [si+1]
	int	21h
	mov	dl,byte ptr [si+2]
	int	21h
	cmp	bx,offset tmono
	jne	vmoend2
	mov	dl,'O'
	int	21h
vmoend2:
	lea	dx,crlf
	jmp	fundone

;-------------------------------
; 'mos vmode mono' logic
;-------------------------------
tmono:
	or	[val1],1		; set mono
	push	[tcbvidp1]		;#jrb allocate new video save area also
	mov	al,1			;#jrb
	call	getvsv			;#jrb
	jc	tm1			;#jrb
	mov	al,1
	call	getvid
	pop	ax			;#jrb saved tcbvidp1
	jnc	tmokx			;#jrba
	push	ax			;#jrb
	call	getvsv			;#jrb restore prior tcbvidp1
	stc
tm1:					;#jrb
	pop	ax			;#jrb throw away tcbvidp1
	ret
tmokx:
	mov	[tcbcrtio],'N'		;#jrba no more hercules support
tmok:
	mov	[tcbscln],4096		;#jrb
	mov	[tcbpgln],4096		;#jrb
	mov	[tcbvidw2],0b000h	;#jrb
	push	es
	mov	es,[bios]
	or	word ptr es:[10h],30h	; set mono mode
	pop	es
	mov	al,7			; set mono mode
	jmp	modeset

;-------------------------------
; 'mos vmode vga' logic
;-------------------------------
tvga:					; vga
	or	[val1],8		; indicate vga
	jmp	short tvega

;-------------------------------
; 'mos vmode ega' logic
;-------------------------------
tega:					; sah 09/24 ega points to cga
	call	isvga			; sah 10/23 is this a vga
	jz	tvga			; sah do vga it'S FASTER
	or	[val1],4		; indicate ega
	mov	al,8			; 8 banks (32k - non 386 case)
	cmp	[is386mm],'Y'		; do we have 386 mm
	jne	txga			; no set vgavidram stuff
tvega:
	and	[tcbvram],0feh		; turn off vidram
	mov	al,64			; requesting 256k (64 banks)
	cmp	[val2],'Y'		; sah does system have full 256k ega
	je	txga			; sah yes
	mov	al,16			; sah reguesting 64k
	or	[tcbega],8		; sah tell mos about it
	jmp	short txga

;-------------------------------
; 'mos vmode cga' logic
;-------------------------------
tcga:					; sah 09/24
	mov	al,4			; 4 banks 16k buffer
	or	[val1],2		; set cga
	push	[tcbvidp1]		;#jrb allocate new video save area also
	call	getvsv			;#jrb
	jc	tc1			;#jrb
	mov	al,4			;#jrb
	call	getvid			;#jrb
	pop	ax			;#jrb saved tcbvidp1
	jnc	tgok			;#jrb
	push	ax			;#jrb
	call	getvsv			;#jrb restore prior tcbvidp1
	stc
tc1:					;#jrb
	pop	ax			;#jrb throw away tcbvidp1
	ret
txga:
	call	getvid			; get video
	jnc	tgok
	pushf				; sah
	or	[tcbvram],1		; sah make sure vram is on
	popf				; sah
	ret
tgok:
	call	initega 		; ega initialization (if so)
	mov	[tcbcrtio],'N'		;#jrba no more hercules support
	mov	al,[tcbequip]		; vga on mono system
	and	al,30h
	cmp	al,30h
	je	monosys
	mov	[tcbscln],16384 	;#jrb
	mov	[tcbpgln],4096		;#jrb
	mov	[tcbvidw2],0b800h	;#jrb
	push	es
	mov	es,[bios]
	and	word ptr es:[10h],not 30h  ; clear it out
	or	word ptr es:[10h],20h	; set 80 col
	pop	es
	mov	al,3			; set color mode
	jmp	modeset
monosys:
	mov	al,7			; set in mono mode
	jmp	modeset


;-------------------------------
; 'mos vmode v40' logic
;-------------------------------
tv40:
	or	[val1],8		; indicate vga
	jmp	short  tve40

;-------------------------------
; 'mos vmode e40' logic
;-------------------------------
te40:
	call	isvga			; sah 10/23/87
	jz	tv40			; sah set vga mode
	or	[val1],4		; indicate ega
	mov	al,8			; 8 banks (32k no 386 mm case)
	cmp	[is386mm],'Y'		; do we have 386 mm
	jne	tx40			; no don't do vgavidram stuff
tve40:	and	[tcbvram],0feh		; turn off vidram
	mov	al,64			; requesting 256k (64 banks)
	cmp	[val2],'Y'		; sah is this full system
	je	tx40			; sah yes
	mov	al,16			; sah requesting 64k
	or	[tcbega],8		; sah tell mos about it
	jmp	short tx40

;-------------------------------
; 'mos vmode c40' logic
;-------------------------------
tc40:
	mov	al,4			; 4 banks 16k
	or	[val1],2		; set cga
	push	[tcbvidp1]		;#jrb allocate new video save area also
	call	getvsv			;#jrb
	jc	tx1			;#jrb
	mov	al,4			;#jrb
	call	getvid			;#jrb
	pop	ax			;#jrb saved tcbvidp1
	jnc	txok			;#jrb
	push	ax			;#jrb
	call	getvsv			;#jrb restore prior tcbvidp1
	stc
tx1:					;#jrb
	pop	ax			;#jrb throw away tcbvidp1
	ret
tx40:
	call	getvid			; get video
	jnc	txok
	pushf				; sah
	or	[tcbvram],1		; turn on vidram
	popf				; sah
	ret
txok:
	call	initega 		; ega initialization (if so)
	mov	[tcbcrtio],'N'		;#jrba no more hercules support
	mov	[tcbscln],16384 	;#jrb
	mov	[tcbpgln],2048		;#jrb
	mov	[tcbvidw2],0b800h	;#jrb
	push	es
	mov	es,[bios]
	and	word ptr es:[10h],not 30h  ; clear it out
	or	word ptr es:[10h],10h	; set 40 col
	pop	es
	mov	al,3
	call	modeset 		; clear it out first
	mov	al,1			; set 40 column color mode

modeset:
	push	bx
	xor	ah,ah
	xor	bh,bh
	int	10h
	mov	bl,[val1]		; sah get video mode to set
	mov	[tcbvideo],bl		; sah save mode in tcbvideo
	pop	bx
	ret

;-------------------------------
; 'mos vmode e43' logic
;-------------------------------
te43:					; 43 line mode (stand back)
	call	tcga
	mov	[tcbcrtio],'N'		;#jrba no more hercules support
	push	bx
	mov	ax,2			; goto into mono mode
	xor	bh,bh
	int	10h
	mov	ax,1112h		; set up font for 43 line
	xor	bx,bx
	int	10h
	mov	ax,1200h		; set up alternate print-scrn
	mov	bl,20h
	int	10h
	mov	ah,1			; we must provide some type of cursor
	mov	cx,0405h
	int	10h
	pop	bx
	ret

;-------------------------------
; 'mos vmode hg1' logic
;-------------------------------
thg1:
	or	[val1],16		; set hg1
	mov	al,8			; 32k of memory allocated
	jmp	short	thgset

;-------------------------------
; 'mos vmode hg2' logic
;-------------------------------
thg2:
	or	[val1],32		; set hg2
	mov	al,16			; 64k of memory allocated
thgset:
	push	[tcbvidp1]		;#jrb allocate new video save area also
	push	ax			;#jrb remember vidram size
	mov	al,8			;#jrb video save always only 32k
	call	getvsv			;#jrb
	pop	ax			;#jrb size for vidram
	jc	thgs1			;#jrb
	call	getvid			;#jrb
	pop	ax			;#jrb saved tcbvidp1
	jnc	thginit 		;#jrb
	push	ax			;#jrb
	call	getvsv			;#jrb restore prior tcbvidp1
	stc
thgs1:					;#jrb
	pop	ax			;#jrb throw away tcbvidp1
	ret
thginit:				; teporary go to mono
	mov	[tcb03bf],00h		;#jrba
	mov	[tcb03b8],08h		;#jrba
	mov	[tcbcrtio],'Y'		;#jrba
	jmp	tmok

;-------------------------------
; subroutines for video logic
;-------------------------------
	assume	es:tcb
initega proc
	push	bx
	mov	bx,[tcbstate]
	or	bx,bx			; ega\vga vidram
	jz	iegadon
	push	cx
	push	si
	push	di
	push	es
	test	[val1],4+8		; test for ega and vga cases
	je	iegafin
	lea	si,paltab		; get source table offset
	lea	di,tcbegapal		; get destination in tcb
	mov	cx,pallen		; get lenght
	cld
	rep	movsb			; move it
	test	[val1],4		; test for ega case
	je	iegafin
egaio:
	mov	es,bx			; get destination
	xor	di,di			; offset of 00h
	lea	si,egatab		; get source table offset
	mov	cx,egalen		; get lenght
	cld
	rep	movsb			; move it!
iegafin:
	pop	es
	pop	di
	pop	si
	pop	cx
iegadon:
	pop	bx
	ret
initega endp

	public vermode
	assume	es:tcb
vermode proc
	push	bx

; check to see if we have memory management

	cmp	[mmflag],'Y'		; sah check for memory management
	je	me43			; sah
	mov	[msgtype],offset msgmreq
	jmp	vmbad			; sah bad mode

; check if vmode e43

me43:
	cmp	cx, offset [msge43]
	jne	mmonsys
	mov	bl,[tcbstation]
	cmp	bl,2
	jb	me43bad
	cmp	bl,4
	jne	mmonsys
me43bad:
	jmp	vmbad


; check to see if trying to set cga mode on vna

mmonsys:
	cmp	cx,offset [msgcga]
	je	vcga
	cmp	cx,offset [msgc40]
	jne	vcgay
vcga:
	cmp	[tcbstation],1		; must be withinthe 1-3 range
	jb	badcga
	cmp	[tcbstation],3
	jna	vcgay
badcga:
	jmp	vmbad

; check to see if reqest mode is hg1 or hg2 and terminal doesn't support
; these modes

vcgay:
	cmp	cx,offset msghg1
	je	vherc
	cmp	cx,offset msghg2
	jne	skherc
vherc:
	test	[tcbvram],10h		; is hercules supported
	jz	badherc
	push	es
	mov	bx,[tcbscrdd]
lpherc:
	or	bx,bx			; no non-herc, all ok
	jz	okherc
	mov	es,bx
	cmp	[tcbstation],4		; is it hercules compatible
	jne	bwatch			; error do watch message
	mov	bx,[tcbnxtdd]		; get next screen driver
	jmp	short lpherc		; loop for next one
badherc:
	jmp	vmbad
okherc:
	pop	es
skherc:

; check to see if work station allows for this type of video

	cmp	cx,offset msgega	; test for ega or vga
	jb	notxga			; skip following check if not
	cmp	cx,offset msgv40
	ja	notxga
	test	[tcbvram],10h		; test for hercules
	jnz	nohercega
	test	[tcbvram],80h		; test for master console
	jnz	mconsl
nohercega:
	jmp	vmbad
mconsl:

; don't allow ega\vga in mono video display

	push	ax
	mov	al,[tcbequip]		; is it mono
	and	al,30h
	cmp	al,30h
	pop	ax
	jne	notmono 		; no then skip mono vga test
	cmp	cx,offset msgv40	; is it v40 sorry mono vga
	je	notv40			; can't do V40
	cmp	cx,offset msge40	; is it e40 sorry mono vga\ega
	jne	notmono 		; is not so..then mono vga
notv40:
	jmp	vmbad
notmono:
	push	es
	mov	es,[tcbscrdd]		; access screen tcb
	cmp	word ptr [tcbnxtdd],0
	je	notxga1
	cmp	word ptr [tcbcondd],0	; sah
	je	inbg			; sah
bwatch:
	mov	[msgtype],offset msgwatch
	jmp	short vmmbad		; sah
inbg:
	mov	[msgtype],offset msgback; sah
vmmbad:
	pop	es			; sah
	jmp	vmbad			; sah
notxga1:
	pop	es			; sah
notxga:

; if tcbstate is allocate free it up

	push	ax
	push	cx
	cmp	[tcbstate],0
	je	vnostat
	xor	ax,ax
	xchg	ax,[tcbstate]
	push	es
	mov	es,ax
	mov	ax,0a01h
	int	services		;call mosheman to dealloc heap
	pop	es
vnostat:
	pop	cx
	pop	ax

; verify vga by testing function 1c

	cmp	cx,offset msgega
	jb	thisnotega
	mov	[vgaflag],'Y'		; sah indicate using vga
	mov	[val2],'Y'		; sah full 256k system
	push	ax
	push	cx
	mov	ax,1c00h
	mov	cx,7			; hardware and color stuff
	int	10h
	cmp	al,1ch			; al = 1ch if vga
	pop	cx
	pop	ax
	je	thisisvga		; sah 10/23/87
thisnotega:
	mov	[vgaflag],'N'		; sah indicate no vga
	mov	[val2],'N'
thisisvga:

; verify if ega or vga

	cmp	cx,offset msgega	; position depended!
	jb	nostate
	cmp	cx,offset msgv40
	jbe	dostate
nostate:
	jmp	vmend
dostate:
	cmp	[vgaflag],'Y'
	je	vmalloc0
	cmp	cx,offset msgvga	; position depended!
	jb	vmega
	jmp	vmbad

; if state information not allocate,allocate it

vmalloc0:
	push	ax
	push	cx
vmalloc:
	push	dx
	mov	dx,bx
	shl	dx,1
	shl	dx,1
	mov	ax,0a00h
	push	es
	int	services		; call moheman to allocate
	mov	bx,es			; save segment
	pop	es
	pop	dx
	or	al,al
	jz	vmalcok
	pop	cx
	pop	ax
	pop	bx
	mov	cx,-1
	ret
vmalcok:
	push	bx
	push	es
	mov	ah,02h
	int	services
	assume	es:scbs
	cmp	[bx+scbmmfg],'Y'
	pop	es
	assume	es:tcb
	pop	bx
	jne	vmnomm
	mov	[tcbstate],bx
vmnomm:
	pop	cx
	pop	ax
	jmp	vmend
vmega:
	push	ax
	push	cx
	mov	ax,1200h
	mov	bl,10h
	int	10h
	pop	cx
	pop	ax
	cmp	bl,10h
	je	vmbad

; test to see if 386 memory management install

	cmp	[is386mm],'Y'
	jne	vmend

; test for 64k ega card

	cmp	bl,03h			; is this a 256k base systen
	jne	vmfull			; no skip
	mov	[val2],'Y'		; indicate that system has full 256k
vmfull:

; allocate egastate area in heap

	mov	bx,48/4 		; setup for 48 bytes of storage
	push	ax
	push	cx
	jmp	vmalloc
vmbad:
	xor	cx,cx
vmend:
	pop	bx
	ret
vermode endp

isvga	proc
	push	ax
	push	cx
	mov	ax,1c00h
	mov	cx,7
	int	10h
	cmp	al,1ch
	pop	cx
	pop	ax
	ret
isvga	endp

is386	proc
	push	ax
	push	bx
	push	es
	assume	es:scbs
	mov	ah,02h
	int	services
	cmp	byte ptr es:[bx+scbmmfg],'Y'  ; test for memory management
	jne	is386no
	mov	[mmflag],'Y'		; sah say we have mm
	test	byte ptr es:[bx+scbmmfea],40h  ; test for io-protection
	jz	is386no
	mov	[is386mm],'Y'
is386no:
	pop	es
	pop	bx
	pop	ax
	ret
is386	endp

;-----------------------------------------------------------------------
; module: getvid	check video and adjust for requirement
; input:
;	 al = # of 4k banks for video
; output:
;	 carry clear - all ok
;
; mjs 5/19/88 reworked this procedure so it made sense and so it could
;	      be secured against serial irq's that switch video.
;-----------------------------------------------------------------------
	public	getvid
getvid:
	push	ax
	push	bx
	push	cx
	push	dx
	push	di
	push	bp
	push	es
	xor	ah,ah
	mov	di,ax			; save bank request
	call	getmdev 		; get memory management driver
	cmp	word ptr [memptr],0	; if no memory manager, return cy
	je	gvbad
	call	getcurtcb
	assume	es:tcb
	mov	bp,[tcbvmpgs]		; record total banks currently allocated
	add	bp,[tcbvmpgs+2]
	cli				; don't allow irq's until video is 'normal'
	push	es
	mov	ah,2			; can't allow task switch until video is
	int	services		; 'normal' again either
	assume	es:scbs
	inc	byte ptr es:[bx+scbnoswt]
	pop	es
	assume	es:tcb
	mov	cx,[tcbvmpgs+2]
	jcxz	gvr1
	mov	bx,[tcbvmhdl+2]
	mov	ah,2			; release 2nd block of vidram
	call	dword ptr [memcall]	; if one is allocated
gvr1:
	mov	cx,[tcbvmpgs]
	mov	bx,[tcbvmhdl]
	mov	ah,2			; release 1st vidram block
	call	dword ptr [memcall]
	mov	cx,di
	call	allocvram
	jnc	gvx1
	mov	cx,bp			; if error, recover initial allocation
	call	allocvram		; (presumes we can recover without error)
	stc
gvx1:
	pushf
	mov	ah,2
	int	services
	assume	es:scbs
	dec	byte ptr es:[bx+scbnoswt]
	mov	es:[bx+scbtcbvr],0	; set it to zero, so swvidram logic
	sti				; will re-initialize video correctly
	popf
	jmp	gvx2
gvbad:
	stc
gvx2:
	pop	es
	pop	bp
	pop	di
	pop	dx
	pop	cx
	pop	bx
	pop	ax
	ret

; allocvram - allocate a new vidram buffer
; entry parms:
;	cx = # of 4k banks to allocate
;	es -> tcb

	assume	es:tcb
allocvram:
	mov	dx,cx
	mov	ah,1
	call	dword ptr [memcall]	; attempt to allocate new buffer
	mov	[tcbvmhdl],bx
	mov	[tcbvmpgs],cx
	mov	[tcbvmpgs+2],0
	cmp	dx,cx			; did we get all we needed?
	je	allv2
	sub	dx,cx			; calc remaining blocks to be allocated
	mov	cx,dx
	mov	ah,1			; and try again
	call	dword ptr [memcall]
	mov	[tcbvmhdl+2],bx
	mov	[tcbvmpgs+2],cx
	cmp	dx,cx			; did we get the second block?
	je	allv2
	jcxz	allv1			; no - nothing for this call
	mov	ah,2
	call	dword ptr [memcall]	; free up 2nd block
	mov	cx,[tcbvmpgs+2]
allv1:
	mov	bx,[tcbvmhdl]		; free up 1st block
	mov	cx,[tcbvmpgs]
	mov	ah,2
	call	dword ptr [memcall]	; note: freeing blocks but not
	stc				; zeroing out [tcbvmpgs], etc.
	ret				; that's left up to the caller
allv2:
	clc
	ret

;-----------------------------------------------------------------------
; module: getvsv	get new video save area allocation
; input:
;	 al = # of 4k banks for video
; output:
;	 carry clear - all ok
;-----------------------------------------------------------------------
	public	getvsv
getvsv	proc
	push	si
	push	es
	push	ax
	push	ax
	mov	ah,02h
	int	services
	assume es:scbs
	push	es:[bx+scbmastv]
	push	es:[bx+scbmastp]
	call	getcurtcb
	pop	cx			; max size of video save area
	pop	bx
	assume	es:tcb
	pop	ax
	xor	ah,ah
	cmp	ax,cx
	ja	gvsvbad 		; not enough room for mode
	push	ax
	push	bx
	call	getmdev 		; get memory management driver
	pop	ax			; bx goes to ax
	pop	cx			; ax goes to cx
	cmp	word ptr [memptr],0
	je	gvsvbad

; cx = number of pages desired
; ax = segment address to map to

	push	ax
	push	cx
	mov	bx,[tcbvidh1]		; (old) handle
	mov	cx,[tcbvidp1]		; (old) pages
	mov	ah,02h			; release
	call	dword ptr [memcall]
	pop	cx			; # pages to allocate
	mov	ah,01h			; allocate
	call	dword ptr [memcall]
	mov	[tcbvidh1],bx		; (new) handle to map
	mov	[tcbvidp1],cx		; (new) pages to map
	pop	es			; segment to map to (scbmastv)
	mov	ah,03h			; remap
	call	dword ptr [memcall]
gvsvok:
	clc
	pop	ax
	pop	es
	pop	si
	ret
gvsvbad:
	stc
	pop	ax
	pop	es
	pop	si
	ret
getvsv	endp

;-------------------------------
; 'mos serinit' logic
;-------------------------------
serfun:
	mov	byte ptr [val3],0	; defualt to NO handshaking
	mov	byte ptr [val2], 3	; set default to n,8,1
	call	nextopnd
	jnz	$+5
	jmp	erropnd
	mov	bx,si
	call	dectobin
	dec	ax
	cmp	ax,24
	jb	ser1
	lea	dx,msgbport
	jmp	errexit
ser1:
	inc	al
	mov	[val1],al
	inc	si
	call	nextopnd
	jnz	$+5
	jmp	erropnd
	mov	bx,si
	xor	dx,dx
	call	dectobin
	mov	[baudlo],ax
	mov	[baudhi],dx
	call	nextopnd
	jnz	$+5
	jmp	serset
	lodsb
	cmp	al,','
	je	ser2
	cmp	al,'O'
	je	serodd
	cmp	al,'o'
	je	serodd
	cmp	al,'E'
	je	sereven
	cmp	al,'e'
	je	sereven
	cmp	al,'N'
	je	sernone
	cmp	al,'n'
	je	sernone
	lea	dx,msgbpar
	jmp	errexit
serodd:
	mov	al,'O'
	or	byte ptr [val2],08h	; set odd parity
	jmp	short serpar
sereven:
	mov	al,'E'
	or	byte ptr [val2],18h	; set even parity
	jmp	short serpar
sernone:
	mov	al,'N'
serpar:
	mov	[msgserpa],al
ser2:
	call	nextopnd
	jz	serset
	lodsb
	cmp	al,','
	je	serdata
	cmp	al,'8'
	je	serdset
	cmp	al,'7'
	je	serdset
	lea	dx,msgbdata
	jmp	errexit
serdset:
	mov	[msgserpa+2],al
	cmp	al,'8'
	je	serdata
	and	byte ptr [val2],0feh
serdata:
	call	nextopnd
	jz	serhand
	lodsb
	cmp	al,'1'
	je	sersset
	cmp	al,'2'
	je	sersset
	lea	dx,msgbstop
	jmp	errexit
sersset:
	mov	[msgserpa+4],al
	cmp	al,'1'
	je	serhand
	or	byte ptr [val2],04h
serhand:
	call	nextopnd
	jz	serset
	lodsb
	and	al,0dfh
	xor	cx,cx
	cmp	al,'N'
	je	serset
	inc	cx
	cmp	al,'D'
	je	setshand
	inc	cx
	cmp	al,'X'
	je	setshand
	inc	cx
	cmp	al,'P'
	je	setshand
	inc	cx
	cmp	al,'R'
	je	setshand
	lea	dx,msgbhand
	jmp	errexit
setshand:
	mov	byte ptr [val3],cl
serset:
	mov	al,[val1]
	mov	ah,'0'
	cmp	al,9
	ja	sers1
	add	al,'0'
	mov	[msgser+5],al
	jmp	serdisp

sers1:
	cmp	al,10
	jb	sers2
	inc	ah
	sub	al,10
	jmp	short sers1
sers2:
	add	al,'0'
	xchg	al,ah
	mov	word ptr [msgser+5],ax
serdisp:
	mov	dl,[val1]
	xor	dh,dh
	dec	dx
	cmp	[baudhi],0
	jne	serreq			; serial.sys interface required
	xor	cx,cx
	xor	bx,bx
serbloop:
	mov	ax,word ptr [bx+baudtab]
	or	ax,ax			; end of table - serial sys required
	jz	serreq
	cmp	ax,[baudlo]
	je	sernreq 		; serial.sys not required
	inc	bx
	inc	bx
	jmp	short serbloop
sernreq:
	mov	al,[val2]
	shl	bx,1
	shl	bx,1
	shl	bx,1
	shl	bx,1
	or	al,bl
	xor	ah,ah			; function 0
	int	14h
	jmp	serdone
serreq:

; test for serial.sys

	lea	dx,serdev
	mov	ax,3d02h
	int	21h
	pushf
	jc	serreq1
	mov	bx,ax
	mov	ah,3eh
	int	21h
serreq1:
	popf
	jnc	sersys
	lea	dx,[msgbrate]		; invalid baudrate
	jmp	errexit
sersys:
	mov	bx,[baudlo]
	mov	cx,[baudhi]
	mov	dl,[val1]
	xor	dh,dh
	dec	dx
	mov	al,[val2]
	mov	ah,4
	int	14h
serdone:
	lea	bx,baudval+5
	mov	ax,[baudlo]
	mov	dx,[baudhi]
	mov	cx,6
	call	bintodec
	mov	[val4],00h		; set defualt to none
	mov	dl,[val1]
	xor	dh,dh
	dec	dx
	mov	ah,12
	int	14h
	or	ah,ah
	jz	serokparm
	and	ah,0f0h			; mask out lower pararms
	mov	[val4],ah		; save parms
serokparm:
	lea	dx,msgser
	cmp	byte ptr cs:[val3],0
	jne	dohand
	push	dx
	mov	al,[val4]
	mov	ah,5
	xor	bx,bx
	mov	dl,[val1]
	xor	dh,dh
	dec	dx
	int	14h			; set no handshaking
	pop	dx
	jmp	short skipser
dohand:
	call	writemsg
;
;	do serial IO hear
;
	mov	bl,byte ptr cs:[val3]
	dec	bl
	xor	bh,bh
	mov	al,cs:[val4]
	or	al,byte ptr SerProt[bx]
	shl	bx,1
	mov	bx,word ptr SerXoff[bx]
	mov	ah,5
	mov	dl,[val1]
	xor	dh,dh
	dec	dx
	int	14h

	lea	dx,msghand
	call	writemsg
	mov	bl,byte ptr cs:[val3]
	dec	bl
	xor	bh,bh
	shl	bx,1
	mov	dx,word ptr SerMsgTab[bx]
skipser:
	jmp	fundone

;-------------------------------
; 'mos dsport' logic
;-------------------------------
public	dspfun
dspfun:
	call	nextopnd
	jnz	$+5
	jmp	erropnd
	mov	bx,si			; save copy of orginal parameter pointer
	cld
dsp11:
	lodsb
	cmp	al,'0'
	jae	$+5
	jmp	dsp1			; see if parameter is only numeric
	cmp	al,'9'
	jbe	dsp11
dsp1:
	cmp	al,13
	je	dsp2
	cmp	al,' '
	je	dsp2
	jmp	erropnd
dsp2:
	call	dectobin		; pointer already in bx
	or	ax,ax
	jnz	$+5
	jmp	erropnd
	dec	ax
	mov	cx,ax
	mov	dx,ax
	mov	ah,6
	int	14h
	test	ah,80h
	jnz	dsp10
	mov	dx,offset [msgdsp4]	; error - didn't find serial.sys
	jmp	dsp8
dsp10:
	mov	ax,cx
	push	ax
	mov	ah,2
	int	services
	pop	ax
	assume	es:scbs
	mov	bx,[bx+scbtcbpf]
	mov	es,bx
	assume	es:tcb
dsp4:
	mov	cx,word ptr [tcbbaud]
	add	cx,word ptr [tcbbaud+2]
	jcxz	dsp12
	cmp	ax,[tcbport]		; check all tcb's for port usage
	je	dsp3
dsp12:
	mov	bx,[tcbtcbpn]
	mov	es,bx
	or	bx,bx
	je	dsp3
	jmp	dsp4
dsp3:
	or	bx,bx
	jz	dsp5
	lea	dx,msgdsp1		; error port is in use by a task
	jmp	dsp8
dsp5:
	mov	dx,ax
	or	dx,8000h
	mov	ah,0bh
	int	14h			; call serial.sys to disable the port
	or	al,al
	jz	dsp7
	cmp	al,1
	jne	dsp6
	mov	dx,offset [msgdsp2]	; error irq is shared by more than 1 port
	jmp	dsp8
dsp6:
	cmp	al,2
	je	$+5
	jmp	erropnd
	mov	dx,offset [msgdsp5]
	jmp	dsp8
dsp7:
	lea	dx,[msgdsp3]		; successful completion message
	jmp	fundone
dsp8:
	mov	al,3			; error handler
	jmp	errexit

;-------------------------------
; 'mos route' logic
;-------------------------------
roufun:
	call	nextopnd
	jnz	$+5
	jmp	erropnd
	lea	di,lpttest
	call	testdev
	or	si,si
	jnz	$+5
	jmp	erropnd

; decode operand

	mov	bx,si
	call	dectobin
	dec	al
	cmp	al,3
	jb	rou1ok
	lea	dx,msgbport
	jmp	errexit
rou1ok:
	inc	al
	mov	[val1],al
	add	al,'0'
	mov	[dev1+3],al
	xor	cx,cx			; zero loop
rouloop:
	cmp	cl,1			; more than two trys
	jbe	$+5
	jmp	erropnd
	call	nextopnd
	jnz	$+5
	jmp	erropnd
	mov	dx,si			; save position
	lea	di,tertest
	call	testdev
	or	si,si
	jz	rounter
	mov	word ptr [dev2],'ET'
	mov	word ptr [dev2+2],'MR'
	call	getcurtcb
	assume	es:tcb
	mov	bl,[val1]
	xor	bh,bh
	dec	bl
	mov	al,es:[tcbauxbt]
	or	al,[bx+tmask]
	mov	es:[tcbauxbt],al
	lea	dx,msgroute
	jmp	fundone
rounter:
	mov	si,dx
	lea	di,nottest
	call	testdev
	or	si,si
	jz	rounnot
	mov	word ptr [dev2],'ON'
	mov	word ptr [dev2+2],'ET'
	mov	word ptr [dev2+4],'MR'
	call	getcurtcb
	mov	bl,[val1]
	xor	bh,bh
	dec	bl
	mov	al,es:[tcbauxbt]
	and	al,[bx+ntmask]
	mov	es:[tcbauxbt],al
	lea	dx,msgroute
	jmp	fundone
rounnot:
	mov	si,dx
	lea	di,lpttest
	call	testdev
	or	si,si
	jz	rounlpt
	mov	bx,si
	call	dectobin
	dec	al
	cmp	al,3
	jb	rou2ok
	lea	dx,msgbport
	jmp	errexit
rou2ok:
	inc	al
	mov	[val2],al
	mov	word ptr [dev2],'PL'
	mov	byte ptr [dev2+2],'T'
	add	al,'0'
	mov	[dev2+3],al
	mov	cl,80h
	jmp	short roufound
rounlpt:
	mov	si,dx
	lea	di,comtest
	call	testdev
	or	si,si
	jnz	roucom
	mov	si,dx
	inc	cl
	jmp	rouloop
roucom:
	mov	bx,si
	call	dectobin
	dec	al
	cmp	al,24
	jb	rou3ok
	lea	dx,msgbport
	jmp	errexit
rou3ok:
	inc	al
	mov	[val2],al
	cmp	al,9
	ja	rou3a
	add	al,'0'
	mov	[dev2+3],al
	jmp	rou3done
rou3a:
	mov	ah,'0'
rou3lp:
	cmp	al,10
	jb	rou3b
	inc	ah
	sub	al,10
	jmp	short rou3lp
rou3b:
	add	al,'0'
	xchg	al,ah
	mov	word ptr [dev2+3],ax
rou3done:
	xor	cl,cl
roufound:
	call	getcurtcb
	mov	bl,[val1]
	xor	bh,bh
	mov	al,[val2]
	cmp	al,bl
	jne	rouf1
	or	cl,cl
	jz	rouf1
	push	bx
	cmp	bl,3
	jb	roufnt
	inc	bl
roufnt:
	not	bl			; was xor bl,bl - fix from rkg
	and	[tcbauxbt],bl		; clear redirection to term port
	pop	bx
	xor	cl,cl
	xor	ax,ax			; clear the flag
rouf1:
	add	al,cl

; set the flag in the tcb

	dec	bx
	mov	es:[bx+tcblptxl],al
	lea	dx,msgroute
	jmp	fundone
;-------------------------------
; 'mos resize' logic
;-------------------------------
resfun:
	call	nextopnd
	jnz	$+5
	jmp	erropnd
	mov	ax,word ptr [si]
	and	ax,0dfdfh
	cmp	ax,'AM' 		; is this max
	jne	notmax
	mov	al,byte ptr [si+2]
	and	al,0dfh
	cmp	al,'X'
	jne	notmax
	mov	ah,2dh			; get max task size
	int	services
	mov	ax,dx
	mov	cl,6
	shr	ax,cl
	jmp	short contmax
notmax:
	mov	bx,si
	call	dectobin
contmax:
	push	ax			; save ax
	lea	bx,sizeval+3
	mov	cx,3
	xor	dx,dx
	call	bintodec
	pop	ax			; get ax
	mov	bx,ax
	mov	ah,0ch
	int	services
	jnc	resdone
	lea	dx,msginsmem
	cmp	al,insmem
	je	reserror
	lea	dx,msgmsmall
	cmp	al,invdata
	je	reserror
	lea	dx,msgfrag
	cmp	al,general
	je	reserror
	lea	dx,msgintn
reserror:
	jmp	errexit
resdone:			    
; 
; change 40:13 for desired task.
;
	call	getcurtcb
	assume  es:tcb
	mov	ax,[tcbendad]
	mov	cl,6
	shr	ax,cl
	mov	cx,40h
	mov	es,cx
	assume  es:nothing
	mov	word ptr es:[13h],ax
	lea	dx,msgsize
	jmp	fundone

;-------------------------------
; 'mos files' function
;-------------------------------
limfun:
	call	nextopnd
	jz	limok
	call	onoff
limok:
	call	getcurtcb
	assume	es:tcb
	cmp	[onflag],255
	jne	limcont
	mov	al,0
	cmp	[tcbflimit],'Y'
	jne	limnext
	inc	al
limnext:
	mov	[onflag],al
	jmp	short limcont3
limcont:
	mov	al,'Y'
	cmp	[onflag],1
	je	limcont2
	mov	al,'N'
limcont2:
	mov	[tcbflimit],al
limcont3:
	lea	dx,msgfile
	call	writemsg
	lea	dx,msglim
	cmp	[onflag],1
	je	limcont4
	lea	dx,msgunlim
limcont4:
	jmp	fundone

;-------------------------------
; 'mos share' function
;-------------------------------

shafun:
	call	nextopnd
	jz	shaok
	call	onoff
shaok:
	call	getcurtcb
	assume	es:tcb
	cmp	[onflag],255
	jne	shacont
	mov	al,1
	cmp	[tcbshare],'N'		; default is yes
	jne	shanext
	dec	al
shanext:
	mov	[onflag],al
	jmp	short shacont3
shacont:
	mov	al,'Y'
	cmp	[onflag],1
	je	shacont2
	mov	al,'N'
shacont2:
	mov	[tcbshare],al
shacont3:
	lea	dx,msgshare
	call	writemsg
	lea	dx,on
	cmp	[onflag],1
	je	shacont4
	lea	dx,off
shacont4:
	jmp	fundone


;-------------------------------
; 'mos ansi' function
;-------------------------------

ansifun:
	call	nextopnd
	jz	ansok
	call	onoff
ansok:
	call	getcurtcb
	assume	es:tcb
	cmp	[onflag],255
	jne	anscont
	mov	al,0
	cmp	[tcbansi],0ffh
	jne	ansnext
	inc	al
ansnext:
	mov	[onflag],al
	jmp	short anscont3
anscont:
	cmp	[onflag],1
	je	anscont2

; turning ansi mode off - must remove keyboard assigment buffer

	mov	[tcbansi],0
	cmp	word ptr [tcbkbansi],0	; buffer not installed
	je	anscont3
	push	es
	mov	es,[tcbkbansi]
	mov	ax,0a01h
	int	services		; call mosheman
	pop	es
	mov	word ptr [tcbkbansi],0	; clear buffer
	jmp	short anscont3
anscont2:

; turning ansi mode on - must create keyboard assigment buffer

	mov	[tcbansi],0ffh
	cmp	word ptr [tcbkbansi],0	; buffer already installed
	jne	anscont3
	push	es
	mov	ax,0a00h
	mov	dx,PARAKANSI		; allocate size from options.inc
	int	services		; call mosheman
	xor	di,di
	mov	cx,32
	mov	ax,-1
	cld
	rep	stosw			; initialize buffer to nothing
	mov	ax,es			; save segment
	pop	es
	mov	word ptr [tcbkbansi],ax ; save address of block
anscont3:
	mov	dx,offset msgansi
	call	writemsg
	mov	dx,offset on
	cmp	[onflag],1
	je	anscont4
	mov	dx,offset off
anscont4:
	jmp	fundone


;-------------------------------
; 'mos tsr' function
;-------------------------------

tsrfun:
	call	nextopnd
	jz	tsrok
	call	onoff
tsrok:
	call	getcurtcb
	assume	es:tcb
	cmp	[onflag],255
	jne	tsrcont
	mov	al,0
	cmp	[tcbtsrflg],'Y'
	jne	tsrnext
	inc	al
tsrnext:
	mov	[onflag],al
	jmp	short tsrcont3
tsrcont:
	mov	al,'Y'
	cmp	[onflag],1
	je	tsrcont2
	mov	al,'N'
tsrcont2:
	mov	[tcbtsrflg],al
tsrcont3:
	lea	dx,msgtsron
	cmp	[onflag],1
	je	tsrcont4
	lea	dx,msgtsroff
tsrcont4:
	jmp	fundone

;-------------------------------
; 'mos keyb' function
;-------------------------------
keyfun:
	call	nextopnd		; get pointer to argument
	jz	keyferr
	call	getcurtcb		; get addressability of keyboard data
	assume	es:tcb
	mov	ax,[si] 		; get keyboard type
	and	ax,5f5fh		; to uppercase
	mov	dx,offset msgksb
	cmp	ax,'BS' 		; small buffer?
	je	keysb
	mov	dx,offset msgklb
	cmp	ax,'BL' 		; large buffer?
	je	keylb
	mov	bl,40h			; and pc keyboard type code
	mov	dx,offset msgkpc
	cmp	ax,'CP' 		; test pc type
	jne	$+5
	jmp	keyfset
	mov	bl,80h			; at type code
	mov	dx,offset msgkat
	cmp	ax,'TA'
	je	keyfset
	mov	bl,0d0h 		; enhanced at keyboard code
	mov	dx,offset msgken
	cmp	ax,'NE'
	jz	keyfset
keyferr:
	jmp	erropnd 		; no arguments or invalid type
keysb:
	cli
	mov	[tcbibsiz],20h
	mov	[tcbibase],1eh
	mov	ax,40h
	push	es
	mov	es,ax
	assume	es:nothing
	mov	word ptr es:[1ah],1eh
	mov	word ptr es:[1ch],1eh
	mov	word ptr es:[80h],1eh
	mov	word ptr es:[82h],3eh
	pop	es
	assume	es:tcb
	sti
	jmp	short keyfix2
keylb:
	cli
	mov	[tcbibsiz],128
	mov	[tcbibase],200h
	mov	ax,40h
	push	es
	mov	es,ax
	assume	es:nothing
	mov	word ptr es:[1ah],200h
	mov	word ptr es:[1ch],200h
	mov	word ptr es:[80h],200h
	mov	word ptr es:[82h],280h
	pop	es
	assume	es:tcb
	sti
	jmp	short keyfix2
keyfset:
	and	[tcbkbctl],2fh		; clear off previous setting
	or	[tcbkbctl],bl		; add keyboard type

; the following logic was added to alter the bios data area to
; indicated if an enhanced keyboard is installed or not

	xor	ax,ax
	mov	es,ax
	cmp	bl,0d0h 		; is this for enhanced keyboard
	je	keyfens
	and	byte ptr es:[496h], not 10h  ; indicated normal keyboard
	jmp	short keyfix
keyfens:
	or	byte ptr es:[496h], 10h ; indicated enhanced keyboard
keyfix:
	push	dx
	mov	dx,offset msgkeyb
	call	writemsg		; output message
	pop	dx			; and message argument
	jmp	fundone
keyfix2:
	push	dx
	mov	dx,offset msgkbl
	call	writemsg		; output message
	pop	dx			; and message argument
	jmp	fundone

;-------------------------------
; 'mos hold lptx nnnn' function
;-------------------------------

; mos hold lptx nnnn	- sets printer hold time for task
; mos hold lptx 	- asserts reservation by status call
;			  displays printer status if not ready
; mos hold lptx 0	- clears printer reservation of task

;-------------------------------
; 'mos mouse' function
;-------------------------------
moufun:
	call	chkmouse
	cmp	byte ptr [ismouse],'Y'
	je	mou1
	lea	dx,msgnomou
	jmp	errexit
mou1:
	call	initmouse
	call	nextopnd
	jnz	mou10
	call	getcurtcb
	assume	es:tcb
	cmp	[tcbmouse],'Y'		; is mouse install
	je	mou1a
	jmp	mounins
mou1a:
	jmp	moudisp
mou10:
	mov	ax,word ptr cs:[si]
	and	ax,0dfdfh
	cmp	ax,'FO' 		; is it off
	jne	mou12
	call	getcurtcb
	assume	es:tcb
	mov	[tcbmouse],'N'
mou10l:
	mov	ax,0c206h
	xor	bh,bh
	int	15h			; test to see if ps/2 bios is installed
	jnc	mou10s
	cmp	ah,4			; resend loop until ok
	je	mou10l
	cmp	ah,5			; no-far call....continue
	je	mou10s
	push	es
	xor	ax,ax
	mov	es,ax
	and	byte ptr es:[410h], not 4h  ; turn off pointer device bit
	pop	es
mou10s:
	mov	bx,es
	mov	ah,1			; deallocate mouse structure
	call	dword ptr cs:[mousefun]
	lea	dx,msgmsupp
	call	writemsg
	lea	dx,off
	jmp	fundone
mou12:
	mov	[baudlo],1200		; set default at 1200b
	mov	[val1],4
	mov	bx,si
	call	dectobin
	dec	ax
	mov	[mouport],ax		; save request port
	call	nextopnd
	jz	mouset
	mov	bx,si
	call	dectobin
	mov	dx,ax
	push	si
	lea	si,baudtab
	xor	cx,cx
mou2:
	lodsw
	cmp	ax,dx			; check to see if port is in table
	je	mou3
	inc	cx
	or	ax,ax			; end of table
	jnz	mou2
	pop	si
	lea	dx,msgbrate		; indicate bad baud rate
	jmp	errexit
mou3:
	pop	si
	mov	[val1],cl		; save baud rate
	mov	[baudlo],dx		; save baud rate
mouset:

; initialized baud

	mov	es,[mouseg]
	mov	bx,[mouoffset]
	cmp	[ismouse],'X'		; check if mouse is already installed
	jne	mouset1
	mov	bx,[moutcb]
	xor	ah,ah			; allocated mouse entry
	call	dword ptr cs:[mousefun]
mouset1:

; scan done list and check if mouse is installed already in another
; task for the same port

	push	bx
	mov	bx,[mousoff]		; get start offset
	mov	cx,[moumax]		; get max structure count
	mov	dx,[moutcb]		; get tcb
	mov	ax,[mouport]		; get request port
mousloop:
	cmp	dx,word ptr es:[bx].tasktcb
	je	moussame		; skip same tcb
	cmp	ax,word ptr es:[bx].mport
	je	mousbad 		; different tcb, same port? err
moussame:
	add	bx,mssize
	loop	mousloop
	pop	bx
	jmp	mouscont		; continue
mousbad:
	pop	bx
	lea	dx,msgbport		; display invalid port
	jmp	mouserr 		; got and error
mouscont:

; place port into table

	mov	ax,[mouport]
	mov	word ptr es:[bx].mport,ax  ; set port in data structure
	mov	ax,[baudlo]
	mov	word ptr es:[bx].mbaud,ax  ; set baud in data structure
	mov	[mousoff],bx		; save current mouse offset

; now test to see if port is installed

	mov	dx,[mouport]		; get port
	mov	al,[val1]		; set up baudrate for fun 00
	mov	cl,5
	shl	al,cl
	or	al,3			; n,8,1
	xor	ah,ah
	int	14h			; initialize mouse
	cmp	ah,0ffh 		; invaild port
	je	mouinvl 		; yes...don't continue
	test	ah,60h
	jnz	mouok
mouinvl:
	lea	dx,msgbport
mouserr:
	push	dx
	mov	bx,[moutcb]
	mov	ah,1			; clear entry
	call	dword ptr cs:[mousefun]
	pop	dx
	jmp	errexit
mouok:
	push	es
	mov	ah,13			; get input ready flag
	mov	dx,[mouport]
	int	14h
	mov	dx,es
	mov	ax,bx
	mov	es,[mouseg]		; get segment of mouse data
	push	di
	mov	bx,[mousoff]		; get offset of mouse data
	lea	di,[bx].mready		; set destination to input
	cld				; ready flag pointer
	stosw				; store offset
	push	ax			; save value for later store
	mov	ax,dx			; in tcb
	stosw				; store segment
	push	dx			; just in case
	call	getcurtcb
	pop	dx			; just in case
	assume	es:tcb
	lea	di,[tcbmcount]
	mov	ax,[mousoff]
	add	ax,offset bcount
	stosw
	mov	ax,[mouseg]
	stosw
	lea	di,[tcbmready]
	pop	ax			; retrieve offset of ready flag
	stosw
	mov	ax,dx			; save
	stosw
	pop	di
	mov	ax,[mouport]		; place mouse port in tcb
	mov	[tcbmport],ax		; so that it can be use by os
	mov	[tcbmouse],'Y'
	xor	ax,ax
	mov	es,ax
	or	byte ptr es:[410h], 4h	; turn on pointer device bit
	pop	es
	mov	[ismouse],'Y'		; all ok
moudisp:
	cmp	[ismouse],'X'		; no mouse found in task
	jne	moud1
mounins:
	lea	dx,msgmnins
	jmp	errexit
moud1:

; set up values for display

	lea	bx,msgmport+1
	mov	cx,2
	mov	ax,[mouport]
	inc	ax
	xor	dx,dx
	call	bintodec
	lea	bx,msgmbaud+4
	mov	cx,5
	mov	ax,[baudlo]
	xor	dx,dx
	call	bintodec
	lea	dx,msgmouse
	call	writemsg
	lea	dx,msgmport
	jmp	fundone

; this procedure is use to find if task has already allocated
; a data structure inside the data area of mouse driver


initmouse proc	near
	push	es
	mov	[ismouse],'X'		; indicate that data structure
	xor	ah,ah			; was not found
	xor	bx,bx
	call	dword ptr cs:[mousefun] ; get mouse data structures
	mov	bx,ax
	push	es
	call	getcurtcb
	mov	dx,es
	mov	[moutcb],dx
	pop	es
	mov	[mouseg],es
	mov	[mousoff],bx		; save start offset for later
	mov	[moumax],cx		; save count
initmlp:
	cmp	word ptr es:[bx].tasktcb,dx  ; is task in there
	je	initmfd
	add	bx,mssize		; add structure size
	loop	initmlp
	jmp	short initmdn
initmfd:
	mov	ax,word ptr es:[bx].mport  ; get port
	mov	[mouport],ax
	mov	ax,word ptr es:[bx].mbaud  ; get baud rate
	mov	[baudlo],ax
	mov	[ismouse],'Y'
	mov	[mouoffset],bx		; save offset to structure
initmdn:
	pop	es
	ret
initmouse endp

; this procedure is use to verify if mouse driver is installed.

chkmouse proc	near
	 push	ds
	 push	cs
	 pop	ds
	 lea	dx,[mdriver]		; try to load $$mouse
	 mov	ax,3d00h
	 int	21h
	 jc	chkmdone
	 mov	bx,ax
	 mov	ax,4400h
	 int	21h
	 jc	chkmdone
	 and	dx,00ffh
	 or	dx,20h
	 mov	ax,4401h		; set to raw mode
	 int	21h
	 jc	chkmdone
	 lea	dx,[mousefun]
	 mov	cx,4
	 mov	ah,3fh
	 int	21h			; read in mouse function handler
	 jc	chkmdone
	 mov	[ismouse],'Y'
	 mov	ah,3eh
	 int	21h			; close her up
chkmdone:
	 pop	ds
	 ret
chkmouse endp



;-------------------------------
; mos dosver function
;-------------------------------

dosfun:
	push	es
	call	getcurtcb
	call	nextopnd		; get pointer to argument
	jnz	getdos
	mov	ax,[tcbversn]		; get current version
	jmp	short dispver
getdos:
	xor	bx,bx
	mov	al,cs:[si]
	cmp	al,'3'
	jb	doserr
	cmp	al,'5'
	ja	doserr
	sub	al,'0'
	mov	bl,al
	cmp	byte ptr cs:[si+1],'.'
	jne	doserr
	mov	al,cs:[si+2]
	cmp	al,'0'
	jb	doserr
	cmp	al,'9'
	ja	doserr
	sub	al,'0'
	xor	ah,ah
	mul	[wordten]
	mov	bh,al
	mov	al, cs:[si+3]
	cmp	al,'0'
	jb	setver
	cmp	al,'9'
	je	setver
	sub	al,'0'
	add	bh,al
setver:
	mov	ax,bx
	push	es
	push	ax
	mov	ah,2
	int	SERVICES
	pop	ax
	assume  es:scbs
	cmp	ax,[bx+scbversn+2]
	pop	es
	assume	es:tcb
	je	doserr
	mov	[tcbversn],ax
dispver:
	mov	dx,offset msgdos
	call	writemsg
	mov	ax,[tcbversn]
	add	al,'0'
	mov	byte ptr [msgdosver],al
	mov	al,ah
	xor	ah,ah
	xor	dx,dx
	div	[wordten]
	add	al,'0'
	mov	byte ptr [msgdosver+2],al
	add	dl,'0'
	mov	byte ptr [msgdosver+3],dl
	mov	dx,offset msgdosver
	pop	es
	jmp	fundone
doserr:
	mov	dx,offset baddos
	jmp	errexit


	include moxmos.inc		; include common code for system and admin

;-------------------------------
; error handling logic
;-------------------------------
erropnd:
	lea	dx,msgopnd
errexit:
	mov	al,3			;1 user error exit code
	jmp	exitwmsg
fundone:
	xor	al,al			; no errors
exitwmsg:
	push	ax			; save exit code
	call	writemsg		; write to console
	pop	ax			; restore exit code
exit:
	mov	ah,04ch 		; terminate process (pass error code al)
	int	21h

writemsg proc
	push	ax
	mov	ah,9
	int	21h
	pop	ax
	ret
writemsg endp

;-------------------------------
; miscellaneous subroutines
;-------------------------------

;-----------------------------------------------------------------------
; module: getcurtcb
; input:
; output:
;	 ax = id of current tcb
;	 es = segment of tcb
;-----------------------------------------------------------------------
getcurtcb proc
	push	bx
	mov	ah,04h
	mov	bx,-1
	int	services
	assume es:tcb
	mov	ax,es:[tcbid]
	mov	[curid],ax
	pop	bx
	ret
getcurtcb endp

;------------------- binary-to-hexadecimal routine ------------------
bintohex proc
	push	si
	mov	dl,4
bthloop1:
	mov	si,ax
	and	si,000fh
	mov	cl,[hextable+si]
	mov	[bx],cl
	mov	cl,4
	shr	ax,cl
	dec	bx
	dec	dl
	jg	bthloop1
	pop	si
	cmp	[cleanfg],'Y'
	je	clean
	ret
clean:
	mov	cx,4
	push	bx
cleanlp:
	inc	bx
	cmp	byte ptr [bx],'0'
	jne	cleandn
	mov	byte ptr [bx],' '
	loop	cleanlp
cleandn:
	pop	bx
	ret
hextable db    '0123456789ABCDEF'
bintohex endp


;---------------------hexadecimal-to-binary routine --------------------
hextobin proc
	xor	ax,ax			; ax will contain the result
hexloop:
	mov	dl,[bx]
	cmp	dl,'0'
	jb	hexwrap
	cmp	dl,'9'
	jbe	noltr
	and	dl,0dfh 		; insure uppercase
	cmp	dl,'A'
	jb	hexwrap
	cmp	dl,'F'
	ja	hexwrap
	sub	dl,'A'
	inc	dl
	add	dl,'9'
noltr:
	push	dx
	mul	[word16]
	pop	dx
	xor	dh,dh
	sub	dl,'0'
	add	ax,dx
	inc	bx
	jmp	hexloop
hexwrap:
	ret
hextobin endp

;------------------------- move routine -----------------------------
movelong proc
	push	es
	cld
	push	cs
	pop	es
	rep	movsb
	pop	es
	ret
movelong endp

endofmos:

mainseg  ends
	end   start
