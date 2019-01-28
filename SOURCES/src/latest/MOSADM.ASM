	include page.inc
	title	mos adm - mos system administration utility

comment ^===============================================================
		    development specification

 program name:	mosadm.com		assigned to: stewart hyde
 module name:	mosadm			assign date:
 entry points:	100h			completed:
 entry from:	exec
 entry method:	exec
 calls:		n/a
 purpose:	system utility functions
 refer to:	
 last update:	08/31/92

 errorlevels:

   0 - requested operation performed without error
   1 - requested operation not performed
   2 - mos system error
   3 - user error (invalid parameter specified)

=======================================================================

sah 12/23/86	include pc-mos functions time and pri subcommands

sah 01/19/87	include pc-mos functions useirq and freeirq subcommands

sah 02/06/87	include memman information information following map 
		and change time to slice.

sah 02/23/87	invlude pc-mos functions wait and vmode. 
		also video mode on map

sah 03/10/87	fix minor problems related to mos cooking and 
		device driver reading.

sah 02/16/87	conditional assembly of mosadm

sah 03/17/87	cache, serinit and route functions.

sah 03/30/87	resize function

sah 05/04/87	placing equipment flags in bios data segment 
		for mode changes

sah 05/07/87	nodis and dis status in map and ems usaged message 
		following map

rbr 05/12/87	messages cleaned up.

sah 05/13/87	vmode e43 for optional 43 line support on ega's.   
		This is new and different so watch out!

sah 05/15/87	memory allocations on vmode changes

sah 05/16/87	ega info on the map

sah 06/25/87	shrink program memory allocation

sah 07/09/87	add men function

sah 07/12/87	convert int 21h 80+ calls into int 38h 00+ calls.

sah 07/22/87	added cp to mos info (mem)

jrb 07/24/87	use int 38h to set priority, display tcbpri divided by 2

sah 08/27/87	add smp allocation at end of mos map

sah 08/31/87	fix minor assembly problem which i created modifing mos 
		map above for mosadm version

sah 09/04/87	added support for vga multitasking added verification 
		of ega and vga mode settings

sah 09/24/87	corrects on video mode handling because of vtype stuff 
		and jim's Observation

sah 09/28/87	enhange mos vmode ega support to include provisions 
		for multi-tasking ega support. also added hg1
		and hg2 for jims hecules support

sah 10/03/87	added new mosadm function pam to allow turning off 
		the pamming of a partition.

sah 10/05/87	include initialization of the ega state area to 
		the following values.  values were derived on an ibm
		model 80 with vga monitor. pc-mos was setup in ega 
		mode with ega io protection turn on and utility program 
		getvga.com was use to fetch the registers. while ega.com 
		was use to display the contents of the ega registers on 
		the screen. both programs may be found in the utils.dir 
		on the r & d server.

jrb 10/22/87	various changes for hercules support

		offset  name	   values

		  0     seq index     00
		  1     seq values    03 00 03 00 02
		  6     att index     00
		  7     att flipflop  00 		 (internal flag)
		  8     att values    00 01 02 03 04 05 14 07 38 3f
				      3a 3f 3c 3f 3e 3f 0c 00 0f
		 27     graph index   00
		 28     graph values  00 00 00 00 00 10 0e 00 ff

		also added default values for tcbegapal arrays for 
		vmode of ega and vga. the follow is the list of default 
		values used.  these values were derived by using vga mode 
		on a model 80 and doing a pam switch.

		tcbegapal  00 01 02 03 04 05 14 07 38
			   39 3a 3b 3c 3d 3e 3f 00

		made provisions for supporting ibm ega with only 64k. 
		(if system does not have 256k, it is assume to have 
		only 64k --- only 64k is saved.)

sah 10/23/87	if system has vga and user request for ega, system 
		will give you ega because we don't have to worry
		about io protection.  also clean up some problems 
		with ega mode setting.

sah 11/09/87	check to make sure console is not a terminal task 
		before going into ega mode. (displaying message
		to tell use that another task is viewing it or 
		trying to run ega on a terminal task.

sah 11/10/87	corrent problem with split video memory lock up and 
		better error messages

sah 11/17/87	made necessary correction for ega's on 286 system

sah 11/23/87	made addtional message if vmode of ega or vga is made 
		in the background.  (which currently do to limititations 
		on designed, can't be down because background task
		has no terminal driver.

sah 12/09/87	made change so that if orginal task does not go 
		into ega or vga if mono chrome task is on system.

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
    01/19/89	update mos mouse to include option off to turn support
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
		time.  also mosadm task hold lptx nnnn so system admin
		can release reservations.

mjs 05/12/89	added mosadm virq on!off command to allow the user to
		control whether irq task switches will switch video or
		not.  for communications use, off is required.	for
		multiple mouse support through patched mouse drivers and
		the port specific irq scheme, off is required.

sah 07/06/89	documentation changes for 3.10 release.

sah 08/31/89	added mosadm reset function to control ctrl-alt-del

bwr 11/28/89	marked messages for foreign language translation.

sah 01/17/90	addition of mosadm hold [task] lptx off command

sah 04/25/90	addition of mosadm time command to disable or enable
		timer chip io protection.

sah 10/23/90	added mosadm emslimit comand to set ems limit.

bwr 04/08/91	added support for new mosadm hold com command

mjs 07/15/91	cleaned up so I could read

SAH 02/21/92	Added MOSADM RETRY function for continously retrying the
		printer.

SAH 04/20/92	Change MOSADM limit to not allow ems if Pageaddress is at
		A000h and user memory fills above 640k boarndary

SAH 04/22/92    change task space to task size in 2nd line of message
		use above.

==================  PC-MOS 5.01 ends here =============================

SAH 08/31/92	Update to 5.02 version for HOLD COMx fix

=======================================================================^
	page

adm	equ	1
sys	equ	0

insmem	 equ   8
invdata  equ   13
general  equ   31
dbbnext  equ   8			; note hard code to offset 8 in dbb header

.xlist
tcb	segment at 07777h
	include mostcb.inc
tcb	 ends

scbs	segment at 08888h
	assume	cs:scbs
	include mosscbdf.inc
scbs	ends

	include mosadm.pub
	include mostfb.inc
	include options.inc
	include genmouse.inc
	include macros.inc
	include mosems.inc
.list
.tfcond

mainseg  segment para
	assume cs:mainseg,ds:mainseg,es:mainseg
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
	db	'PC-MOS MOS Administrator Utility v5.02 (920831)          ',13,10  ;@@xlat
	db	'(C) Copyright 1987-1992 The Software Link, Incorporated  ',13,10  ;@@xlat
	db	'All Rights Reserved, Worldwide                           ',13,10  ;@@xlat
	db	13,10
	db	'Available functions are:     ',13,10  ;@@xlat
	db	'.MOSADM SLICE n {task}         - set partition time slice to n         ',13,10  ;@@xlat
	db	'.MOSADM PRI n {task}           - set partition priority to n           ',13,10  ;@@xlat
	db	'.MOSADM CACHE on這ff           - turns disk cache on and off           ',13,10  ;@@xlat
	db	'.MOSADM SWITCH on這ff {task}   - turns pam switching on and off         ',13,10  ;@@xlat
	db	'.MOSADM TMFACTOR {n}           - set/show system time slice factor          ',13,10  ;@@xlat
	db	'.MOSADM HOLD task LPTx {nnn}   - sets printer reserve time for task    ',13,10  ;@@xlat
	db	'.MOSADM HOLD task LPTx OFF     - release printer reservation for task      ',13,10  ;@@xlat
	db	'.MOSADM HOLD task COMxx {nnn}  - sets COM port reserve time for task   ',13,10  ;@@xlat
	db	'.MOSADM HOLD task COMxx OFF    - release COM port reservation for task     ',13,10  ;@@xlat
        db	'.MOSADM RETRY task LPTx ON     - set printer infinite retry for task           ',13,10  ;@@xlat
        db	'.MOSADM RETRY task LPTx OFF    - turns off printer infinite retry for task     ',13,10  ;@@xlat
	db	'.MOSADM VIRQ  on這ff           - define irq task switching method      ',13,10  ;@@xlat
	db	'.MOSADM RESET on這ff {task}    - controls task reset logic             ',13,10  ;@@xlat
	db	'.MOSADM TIME on這ff            - controls timer chip IO protection     ',13,10  ;@@xlat
	db	'.MOSADM EMSLIMIT size {handle} - controls EMS Size and handles         ',13,10  ;@@xlat
	db	'.MOSADM EMSLIMIT off           - Turns off EMS emulation               ',13,10  ;@@xlat
	db	'$',8,' ',26

sbegin:
	jmp	begin

	even
version:
	include version.inc

badmos	db	13,10,'Incorrect MOS Version ',13,10,'$'  ;@@xlat

funtable label byte
	db	'SLI'
	dw	offset timfun
	db	'PRI'
	dw	offset prifun
	db	'CAC'
	dw	offset cacfun
	db	'SWI'
	dw	offset pamfun
	db	'TMF'
	dw	offset tmffun
	db	'HOL'
	dw	offset holdfun
	db	'VIR'
	dw	offset virqfun
	db	'RES'
	dw	offset resfun
	db	'TIM'
	dw	offset tiofun
	db	'EMS'
	dw	offset emsfun
	db	'RET'
	dw	offset retryfun
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

memptr	dd    0
memcall dd    0
comtest db	'COM'
lpttest db	'LPT'
serdev	db    '$$SC',0
device	db    'EMMXXXX0',0		; ems driver name
minsign db    'N'
datedef db    0
msgfun	db    13,10,'Invalid command   ',13,10,'$'  ;@@xlat
msgopnd db    13,10,'Invalid or missing operand        ',13,10,'$'  ;@@xlat
on	 db    'ON.',13,10,'$'
off	 db    'OFF.',13,10,'$'		;@@xlat
onflag	 db	 255			; 0 = off	1 = on	 255 = status
msgbtask db    13,10,'Invalid task id       ',13,10,'$'  ;@@xlat
msgpri	 db    13,10,'Invalid priority    ',13,10,'$'  ;@@xlat
msgpriok db    13,10,'Priority changed.  ',13,10,'$'  ;@@xlat
msgtimok db    13,10,'Time Slice Set.     ',13,10,'$'  ;@@xlat
msgsure  db    13,10,'Invalid time slice    ',13,10,'$'  ;@@xlat
msgpam	 db    13,10,'PC-MOS Pam Switching is $        '  ;@@xlat
common	 db    13,10,'PC-MOS Cache is $ '  ;@@xlat
msgtmfok db    13,10,'Time slicing factor set       ',13,10,'$'  ;@@xlat
msglgtmf db    13,10,'Invalid time factor (40 maximum)         ',13,10,'$'  ;@@xlat
maxtmf	equ	40			; if change this, change above msg to match
msgrptmf db	13,10,'Time slicing factor = $        '  ;@@xlat
reptmf	db	'   ',13,10,'$'
msgvirq  db    13,10,'IRQ video switching is $        '  ;@@xlat
msgena	 db    'enabled    ',13,10,'$'	;@@xlat
msgdisa  db    'disabled      ',13,10,'$'  ;@@xlat
msgna	db     'not available      ',13,10,'$'  ;@@xlat
msgreset db    13,10,'Task reset is $            '  ;@@xlat
msgtime  db	13,10,'Timer IO Protection is $         '  ;@@xlat
msgfrbad  db	13,10
	  db	'Error: EMS Page address of A000h conflicts with task space             ',13,10     ;@@xlat
	  db	'       Either reduce task size or chance EMS Page Address.             ',13,10,'$' ;@@xlat
msgbadems db	13,10,'Error: PC-MOS EMS 4.0 Driver Not Installed.       ',13,10,'$'  ;@@xlat
msgbadhand db	13,10,'Error: Handle count too large.        ',13,10,'$'
noemsmem  db	13,10,'Error: Not enough extended memory.            ',13,10,'$'  ;@@xlat
msgemsmem  db	13,10,'PC-MOS EMS 4.0 Maximum Expanded Memory is $          '  ;@@xlat
msgemshand db	'PC-MOS EMS 4.0 Maximum Handles is $          '  ;@@xlat
repemsmem  db	'    K.',13,10,'$'
repemshand db	'   .',13,10,'$'
msgcrlf    db	13,10,'$'

retry_lpt_set	db      'LPTx Infinite Retry is $          '      ;@@XLAT
invalid_lptr    db      'Can only set Infinite Retry for LPT1 - LPT3        ' ;@@XLAT
                db      13, 10, '$'


emsmem	  dw	0
emshand   dw	0
emsseg	  dw	0
emsbase   dw	0
emsoffset dw	0
emserror  db	'N'			; no ems error

retry_lpt_num	db	0

	page
;--------------------------------------------------------------------
;			  initialization
;--------------------------------------------------------------------
	assume cs:mainseg,ds:mainseg,es:mainseg
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

; all ok continue with business

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

;======================================================================
;,fs
; prifun - mos priority logic
;
; in:	
;
; out:	
;
;,fe
;======================================================================
	assume cs:mainseg,ds:mainseg,es:mainseg
prifun:
	call	nextopnd		; next operand
	jnz	$+5
	jmp	erropnd
	mov	bx,si
	call	dectobin
	cmp	ax,7
	ja	errpri
	push	ax
	call	nextopnd
	jnz	pritask
	mov	bx,-1			; get current
	jmp	prigtask
pritask:
	mov	bx,si
	call	dectobin
	mov	bx,ax
prigtask:
	mov	ah,04h
	int	services
	jnc	pritok
	assume	es:tcb
	pop	ax
	mov	al,3
	lea	dx,msgbtask
	jmp	errexit
pritok:
	pop	ax
	mov	ah,0eh			; let mos set the priority
	int	services
	jc	errpri
	lea	dx,msgpriok
	jmp	fundone
errpri:
	mov	al,3
	lea	dx,msgpri
	jmp	errexit

;======================================================================
;,fs
; timfun - mos slice logic
;
; in:	
;
; out:	
;
;,fe
;======================================================================
	assume cs:mainseg,ds:mainseg,es:mainseg
timfun:
	call	nextopnd		; next operand
	jnz	$+5
	jmp	erropnd
	mov	bx,si
	call	dectobin
	cmp	ax,255			; over board???
	ja	errtim
	push	ax
	call	nextopnd
	jnz	timtask
	mov	bx,-1			; get current
	jmp	timgtask
timtask:
	mov	bx,si
	call	dectobin
	mov	bx,ax
timgtask:
	mov	ah,04h
	int	services
	jnc	timtok
	assume	es:tcb		;$$$$$$$$$$$
	pop	ax
	mov	al,3
	lea	dx,msgbtask
	jmp	errexit
timtok:
	pop	ax
	mov	es:[tcbslice],al
	lea	dx,msgtimok
	jmp	fundone
errtim:
	mov	al,3
	lea	dx,msgsure
	jmp	errexit

;======================================================================
;,fs
; cacfun - mos cache logic
;
; in:	
;
; out:	
;
;,fe
;======================================================================
	assume cs:mainseg,ds:mainseg,es:mainseg
cacfun:
	call	nextopnd
	jnz	$+5
	jmp	paramok
	call	onoff			; set off on status
paramok:
	mov	ah,2
	int	services
	assume	es:scbs
	cmp	[onflag],1
	je	cacfun1
	cmp	[onflag],0
	jne	cacfun2			; just status

; turn it off

	cmp	es:[bx+scbcach],'Y'
	jne	cacfun2
	mov	es:[bx+scbcach],0	; flush on state change only
	mov	ah,0dh
	int	21h
	jmp	cacfun2

; turn it on

cacfun1:
	mov	es:[bx+scbcach],'Y'
cacfun2:
	cmp	es:[bx+scbcach],'Y'
	je	dispon

; else off

dispoff:
	mov	dx,offset off
	jmp	short dodisp
dispon:
	mov	dx,offset on
dodisp:
	push	dx
	mov	dx,offset common
	call	writemsg
	pop	dx
	jmp	fundone

;======================================================================
;,fs
; pamfun - mos pam logic
;
; in:	
;
; out:	
;
;,fe
;======================================================================
	assume cs:mainseg,ds:mainseg,es:mainseg
pamfun:
	mov	word ptr [curid],-1	; indicate current task
	call	nextopnd
	jz	disppam
	call	onoff
	cmp	[onflag],255
	je	disppam
	call	nextopnd
	jz	disppam
	mov	bx,si
	call	dectobin
	mov	[curid],ax
disppam:
	mov	bx,[curid]
	mov	ah,04h
	int	services
	jnc	dpamok
	assume	es:tcb		;$$$$$$$$$$$
	mov	al,3
	mov	dx,offset msgbtask
	jmp	errexit
dpamok:
	assume	es:tcb
	cmp	[onflag],1
	je	dpamok1
	cmp	[onflag],0
	jne	dpamok2
	mov	[tcbpam],'N'
	jmp	short	dpamok2
dpamok1:
	mov	[tcbpam],'Y'
dpamok2:
	cmp	[tcbpam],'Y'
	je	dpamon
	mov	dx,offset off
	jmp	dpamdisp
dpamon:
	mov	dx,offset on
dpamdisp:
	push	dx
	mov	dx,offset msgpam
	call	writemsg
	pop	dx
	jmp	fundone

;======================================================================
;,fs
; tmffun - mosadm tmfactor logic
;
; in:	
;
; out:	
;
;,fe
;======================================================================
	assume cs:mainseg,ds:mainseg,es:mainseg
tmffun:
	call	nextopnd		; next operand
	jnz	$+5
	jmp	report_tmf
	mov	bx,si
	call	dectobin
	cmp	ax,maxtmf
	ja	errtmf
	mov	cx,ax
	mov	ah,2
	int	services
	assume	es:scbs
	cli				; sensitive process - no irq's
	mov	es:[bx+scbslfact],cl	; set the software divisor reference
	mov	es:[bx+scbslcnt],cl	; and down counter
	xor	ax,ax
	mov	dx,1
	jcxz	skipdiv
	cmp	cx,1
	je	skipdiv
	div	cx			; calculate (10000 / time factor)
skipdiv:
	mov	bx,ax
	mov	al,36h
	out	43h,al
	jmp	$+2			; re-program the timer/counter chip
	mov	al,bl
	out	40h,al
	jmp	$+2
	mov	al,bh
	out	40h,al
	sti
	lea	dx,[msgtmfok]
	jmp	fundone
report_tmf:
	mov	ah,2
	int	services		; when no number is given, report the
	assume	es:scbs			; current value for the time slice factor
	mov	al,es:[bx+scbslfact]
	xor	ah,ah
	xor	dx,dx
	or	al,al
	jnz	rpt1			; show 0 as a 1
	inc	al
rpt1:
	lea	bx,[reptmf+2]
	mov	cx,3
	call	bintodec
	lea	dx, msgrptmf
	call	writemsg
	lea	dx, reptmf
	jmp	fundone
errtmf:
	mov	al,3
	lea	dx,[msglgtmf]		; coordinate test size with error message
	jmp	errexit

;======================================================================
;,fs
; virqfun - mos virq function
;
; in:	
;
; out:	
;
;,fe
;======================================================================
	assume cs:mainseg,ds:mainseg,es:mainseg
virqfun:
	call	nextopnd
	jz	vrqok
	call	onoff
vrqok:
	mov	ah,2
	int	services
	assume	es:scbs
	cmp	[onflag],255		; report status?
	jne	vrqcont
	mov	al,0
	cmp	[bx+scbswvq],'Y'
	jne	vrqnext
	inc	al
vrqnext:
	mov	[onflag],al
	jmp	short vrqcont3
vrqcont:
	mov	al,'Y'
	cmp	[onflag],1
	je	vrqcont2
	mov	al,'N'
vrqcont2:
	mov	[bx+scbswvq],al
vrqcont3:
	lea	dx,msgvirq
	call	writemsg
	lea	dx,msgena
	cmp	[onflag],1
	je	vrqcont4
	lea	dx,msgdisa
vrqcont4:
	jmp	fundone

;======================================================================
;,fs
; resfun - mos reset logic
;
; in:	
;
; out:	
;
;,fe
;======================================================================
	assume cs:mainseg,ds:mainseg,es:mainseg
resfun:
	mov	word ptr [curid],-1	; indicate current task
	call	nextopnd
	jz	dispres
	call	onoff
	cmp	[onflag],255
	je	dispres
	call	nextopnd
	jz	dispres
	mov	bx,si
	call	dectobin
	mov	[curid],ax
dispres:
	mov	bx,[curid]
	mov	ah,04h
	int	services
	jnc	dresok
	assume	es:tcb		
	mov	al,3
	mov	dx,offset msgbtask
	jmp	errexit
dresok:
	assume	es:tcb
	cmp	[onflag],1
	je	dresok1
	cmp	[onflag],0
	jne	dresok2
	mov	[tcbreboot],0ffh
	jmp	short	dresok2
dresok1:
	mov	[tcbreboot],00h
dresok2:
	cmp	[tcbreboot],00h
	je	dreson
	mov	dx,offset off
	jmp	dresdisp
dreson:
	mov	dx,offset on
dresdisp:
	push	dx
	mov	dx,offset msgreset
	call	writemsg
	pop	dx
	jmp	fundone

;======================================================================
;,fs
; tiofun - mosadm time function
;
; in:	
;
; out:	
;
;,fe
;======================================================================
	assume cs:mainseg,ds:mainseg,es:mainseg
tiofun:
	call	nextopnd
	jz	gdisptim
	call	onoff
	cmp	[onflag],255
	je	gdisptim
	mov	ah,2
	int	services
	assume	es:scbs
	test	byte ptr es:[bx+scbmmfea],40h  ; is io protection avaialble
	jz	no386tim		; no then display error
	les	si,[bx+scbmmptr]	; get pointer to memman data
	assume	es:nothing
	les	si,dword ptr es:[si].parmiop
	cmp	[onflag],1
	je	timon

; turn io protection off for ports 40, 42 and 43

	and	byte ptr es:[si+8],not 00001101b  ; clear p40, p42, p43
	jmp	short disptim
timon:

; turn io protection off for ports 40, 42 and 43

	or	byte ptr es:[si+8], 00001101b  ; set p40,p42,p43
	jmp	short disptim

no386tim:
	mov	[onflag],255		; indicate flag to indicate n/a
	jmp	short disptim

gdisptim:
	mov	ah,2
	int	services
	assume	es:scbs
	test	byte ptr es:[bx+scbmmfea],40h  ; is io protection avaialble
	jz	disptim
	les	si,[bx+scbmmptr]	; get pointer to 9memman data
	assume	es:nothing
	les	si,dword ptr es:[si].parmiop
	mov	[onflag],1
	test	byte ptr es:[si+8],1	; test to see if port 40 on
	jnz	disptim
	dec	[onflag]
disptim:
	push	cs
	pop	es
	mov	dx,offset msgena
	cmp	[onflag],1
	je	disptim2
	mov	dx,offset msgdisa
	cmp	[onflag],0
	je	disptim2
	mov	dx,offset msgna
disptim2:
	push	dx
	mov	dx,offset msgtime
	call	writemsg
	pop	dx
	jmp	fundone

;======================================================================
;,fs
; emsfun - mosadm emslimit function
;
; in:	
;
; out:	
;
;,fe
;======================================================================
	assume cs:mainseg,ds:mainseg,es:mainseg
emsfun:
	call	checkems		; check for ems 4.0 support
	jnc	ems1
	mov	al,3
	mov	dx,offset msgbadems
	jmp	errexit
ems1:
	call	checkframe
	jnc	ems1f
	mov	al,3
	mov	dx,offset msgfrbad
	jmp	errexit
ems1f:	
	call	nextopnd
	jz	emsstat

; check for mosadm emslimit off

	mov	al,byte ptr ds:[si]
	and	al,0dfh
	cmp	al,'O'
	jne	ems1a
	mov	ax,word ptr ds:[si+1]
	and	ax,0dfdfh
	cmp	ax,'FF'
	jne	ems1a
	mov	[emsmem],0
	mov	[emshand],0
	jmp	short emsinit
ems1a:
	mov	bx,si
	call	dectobin
	cmp	ax,64			; if lest than 64k, set 64k
	jae	ems2
	mov	ax,64
ems2:
	cmp	ax,8*1024		; 8 meg is max
	jb	ems3
	mov	ax,8*1024		; force it to max
ems3:
	shr	ax,1
	shr	ax,1
	shr	ax,1
	shr	ax,1
	mov	[emsmem],ax
	mov	[emshand],32
	call	nextopnd
	jz	emsinit
	mov	bx,si
	call	dectobin
	or	ax,ax
	jz	emsinit
	cmp	ax,255
	jbe	sethand1
	mov	al,3
	mov	dx,offset msgbadhand
	jmp	errexit
sethand1:
	cmp	ax,16
	ja	sethand2
	mov	ax,16
sethand2:
	mov	[emshand],ax
emsinit:
	call	initems			; init ems 4.0
	cmp	[emserror],'N'
	je	emsstat
	mov	al,3
	mov	dx,offset noemsmem
	jmp	errexit
emsstat:
	mov	dx,offset msgemsmem
	call	writemsg
	mov	ax,[emsmem]
	or	ax,ax
	jnz	emsstat2
	mov	dx,offset msgdisa
	jmp	fundone
emsstat2:
	shl	ax,1
	shl	ax,1
	shl	ax,1
	shl	ax,1
	mov	bx,offset repemsmem+3
	mov	cx,4
	xor	dx,dx
	call	bintodec
	mov	dx,offset repemsmem
	call	cleanspace
	call	writemsg
	mov	dx,offset msgemshand
	call	writemsg
	mov	ax,[emshand]
	mov	bx,offset repemshand+2
	mov	cx,3
	xor	dx,dx
	call	bintodec
	mov	dx,offset repemshand
	call	cleanspace
	jmp	fundone


initems  proc	near
	 push	ax
	 push	bx
	 push	cx
	 push	dx
	 push	si
	 push	di
	 push	es
	 call	getmdev
	 cmp	[emsseg],0		; has segment been allocated
	 je	skipclear

; we will first check to see if size requested is what
; we currently have enstalled

	 mov	es,[emsseg]
	 assume es:ems40seg
	 mov	ax,[emsmem]
	 cmp	ax,[pgsavail]		; is same amount of pages
	 jne	clearit
	 mov	ax,[emshand]
	 cmp	ax,[maxhandles]		; is same amount of handles too!
	 jne	clearit
	 jmp	initdone		; both the same so just init it
clearit:

; we must now clear the ems memory (both extended and smp)

	mov	bx,[addrbase]		; get base addr
	mov	cx,[pgsavail]
	shl	cx,1
	shl	cx,1			; convert 16k pages to 4k pages
	mov	ah,2
	call	[memcall]		; deallocated extended memory
	mov	ax,0a01h
	int	services		; dealloce heap entry
	mov	[emsseg],0		; no segment is defined
skipclear:
	cmp	[emsmem],0		; if no memory specified, skip alloc
	jne	initmem
	jmp	initdone
initmem:

; we must now inited ems memory (both extended and smp)

	mov	cx,[emsmem]
	shl	cx,1
	shl	cx,1			; convert 16k pages to 4k pages
	mov	ah,1
	call	[memcall]		; allocate extended memory
	or	ax,ax
	jz	allocok			; no errors
	mov	[emserror],'Y'
	or	cx,cx
	jz	nofree
	mov	ah,2
	call	[memcall]		; free up extra amount
nofree:
	jmp	short initdone
allocok:
	mov	[emsbase],bx

; now we must calculate heap space
;
; heap needed = offset (database) + ((emsmem)*bmap_len)
; 	      + ((emshand) * hand_len)

	mov	cx,offset database
	xor	dx,dx
	mov	ax,[emshand]
	mov	bx,hand_len
	mul	bx
	add	cx,ax
	mov	[emsoffset],cx
	mov	ax,[emsmem]
	mov	bx,bmap_len
	mul	bx
	add	cx,ax
	add	cx,15
	shr	cx,1
	shr	cx,1
	shr	cx,1
	shr	cx,1
	mov	dx,cx
	mov	ax,0a00h
	int	services
	or	al,al
	jz	smpallocok
	mov	[emserror],'Y'
	jmp	short initdone
smpallocok:
	mov	ax,es
	mov	[emsseg],ax
	assume	es:ems40seg
	mov	ax,[emsmem]
	mov	[pgsavail],ax
	mov	ax,[emshand]
	mov	[maxhandles],ax
	mov	ax,[emsbase]
	mov	[addrbase],ax
	mov	ax,[emsoffset]
	mov	[bitoffset],ax
initdone:
	 mov	ah,4
	 mov	bx,-1
	 int	services
	 assume es:tcb
	 mov	ax,[emsseg]
	 mov	[tcbemsseg],ax
	 or	ax,ax
	 jz	initdone1

; if segment is set, make sure that it is tag, so ems driver will
; init on first access to ems functions.

	 mov	es,ax
	 assume  es:ems40seg
	 mov	byte ptr es:[emstag],'N'

; do a int 67h get version call to make sure that ems logic will
; correctly initialized the data

	mov	ah,46h
	int	67h
initdone1:

	 pop	es
	 pop	di
	 pop	si
	 pop	dx
	 pop	cx
	 pop	bx
	 pop	ax
	 ret
initems  endp

	assume es:nothing

cleanspace proc near
	push	si
	mov	si,dx
csloop:
	cmp	byte ptr ds:[si],' '
	jne	csend
	inc	si
	jmp	short csloop
csend:
	mov	dx,si
	pop	si
	ret
cleanspace endp

checkframe proc	near
	push	ax
	push	bx
	
	mov	ah,41h			; get ems frame 
	int	67h
	or	ah,ah
	jnz	framebad
	cmp	bx,0a000h		; frame at A000h
	jne	frameok
	int	12h
	cmp	ax,280h
	jbe	frameok
framebad:
	stc
	jmp	short frameexit
frameok:
	clc
frameexit:
	pop	bx
	pop	ax
	ret
checkframe endp

checkems proc	near
	push	ax
	push	bx
	push	cx
	push	dx
	mov	ah,3dh
	mov	dx,offset device
	xor	al,al
	int	21h			; open driver ems
	jc	cemsend
	mov	bx,ax			; save handle
	mov	ax,4400h
	int	21h
	jc	cemsend
	test	dx,0080h
	jz	cemsend
	mov	ah,46h
	int	67h
	or	ah,ah
	jnz	cemsend
	cmp	al,40h
	jb	cemsend
	push	es
	mov	ah,4
	mov	bx,-1
	int	services
	assume	es:tcb
	mov	ax,[tcbemsseg]
	mov	[emsseg],ax
	xor	bx,bx
	or	ax,ax			; clear if segment not defined
	jz	setems
	mov	es,ax
	assume	es:ems40seg
	mov	ax,[pgsavail]
	mov	bx,[maxhandles]
setems:
	mov	[emsmem],ax
	mov	[emshand],bx
	pop	es
	clc
	jmp	short cemsskip
cemsend:
	stc
cemsskip:
	pop	dx
	pop	cx
	pop	bx
	pop	ax
	ret
checkems endp


	assume cs:mainseg,ds:mainseg,es:mainseg
	include moxmos.inc		; include common routines


;======================================================================
;,fs
; retryfun - mosadm retry function
;
; in:	
;
; out:	
;
;,fe
;======================================================================
	assume cs:mainseg,ds:mainseg,es:mainseg

retryfun proc	near
	call	nextopnd		; get task number
        ljz     erropnd         	; Operand error.
        mov     bx, si
        call    dec2bin
        ljc     erropnd
	mov	bx, ax
	mov	ah, 4
	int	SERVICES		; MOS get TCB call
        jnc     retry1
	lea	dx, unknown_task        ; give unknown task error
	jmp	errexit
retry1:
	ASSUME	es:tcb
        mov     ax, tcbid       ; Store the taskid locally.
        mov     task_ID, ax
	call	nextopnd        ; Get next operand.
        ljz     erropnd
	lea	di, lpttest     ; Is the device LPTx ?
	call	testdev
	or	si, si		; abort if not LPTx
        ljz     erropnd
        xor     ah, ah
        mov     al, [si]                ;Fill display strings.
	mov	[retry_lpt_set+3],al
        sub     al, '1'
        lea     dx, invalid_lptr
        cmp     ax, 2
        lja     errexit
        mov     retry_lpt_num, al       ;Save LPT port number.
        call    nextopnd                ;Get next command-line operand.
        ljz     lpt_disp_retry          ;If none, display current one.
	call	onoff		
	cmp	[onflag],1
	je	lpt_retry_on
	cmp	[onflag],0
	jne	lpt_disp_retry

;
; Turn Retry Off
;
	mov	al,1
	mov	cl,[retry_lpt_num]
	or	cl,cl
	jz	lpt_off1
	shl	al,cl
lpt_off1:
	not	al
	and	[tcbiretry],al
	jmp	short do_retry_display

lpt_retry_on:

;
; Turn Retry ON
;
	mov	al,1
	mov	cl,[retry_lpt_num]
	or	cl,cl
	jz	lpt_on1
	shl	al,cl
lpt_on1:
	and	[tcbiretry],0f7h
	or	[tcbiretry],al
	jmp	short do_retry_display


lpt_disp_retry:
	mov	al,1
	mov	cl,[retry_lpt_num]
	or	cl,cl
	jz	lpt_disp1
	shl	al,cl
lpt_disp1:
	xor	ah,ah
	test	[tcbiretry],al
	jz	lpt_disp2
	inc	ah
lpt_disp2:
	mov	[onflag],ah

do_retry_display:
	mov	dx,offset retry_lpt_set
	call	writemsg
	mov	dx,offset off
	cmp	[onflag],1
	jne	disp_retry
	mov	dx,offset on
disp_retry:
	jmp	fundone	
			
	ret
retryfun endp


	assume cs:mainseg,ds:mainseg,es:mainseg

;-------------------------------
; error handling logic
;-------------------------------
	assume cs:mainseg,ds:mainseg,es:mainseg
erropnd:
	lea	dx,msgopnd
	mov	al,3			;1 user error exit code
	jmp	errexit
fundone:
	xor	al,al			; no errors
errexit:
	push	ax			; save exit code
	call	writemsg		; write to console
	pop	ax			; restore exit code
	mov	ah,04ch			; terminate process (pass error code al)
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

; struncmp compares (uncased) strings for given length
; enter:	ds:si, ds:di string pointers
; 	cx = length to compare
; exits:	condition code set
; 	si, di, cx updated
; uses:	ax

struncmp:
	lodsb
	call	upcase
	mov	ah, al
	mov	al, [di]
	inc	di
	call	upcase
	cmp	al, ah
	loope	struncmp
	ret

; upcase translates char in al to uppercase

upcase:
	cmp	al, 'a'
	jb	upcsxit
	cmp	al, 'z'
	ja	upcsxit
	sub	al, 'a' - 'A'
upcsxit:
	ret
endofmos:

mainseg  ends
	end   start

