	include page.inc
	title	monitor - pc-mos system monitor
comment ^===============================================================
			development specification

 program name:	monitor.com		assigned to: stewart hyde
 module name:	monitor 		assign date: 02/25/89 (self)
 entry points:	monitor 		completed:   03/28/89
 entry from:	mos command processor
 entry method:	exec (tsr)
 purpose:
 refer to:
 last update:	08/21/92

this program provides users with an easy to use method of managing
the task on pc-mos system. this program is an tsr which can be pop
and user can select which task he or she wants to modified and press
return to display an option menu. some of the options on the menu will
effect the system globally and some will onely effected the task
which has been selected.  also which main display is up, the screen
will be continously update on changes of task details being displayed.

=======================================================================

mjs 05/03/89	modified the size of the addtask structure to match
		changes made in int38fun22.

sah 05/04/89	corrections for de-installing monitor and cosmetics

sah 07/19/89	corrections for colors on mono-chrome systems

sah 06/28/89	corrections if some one switches vmodes will resident

sah 06/29/89	corrections for switching between vmode of mono and
		other modes when monitor is resident
sah 07/18/89	corrected returning wrong task on remove a task

sah 07/21/89	corrected ports on vna during mos map display
		corrected not setting priority.

sah 08/25/89	added option to disable restart option.

sah 09/05/89	corrections for remove monitor and restart task options

sah 09/19/89	corrections for translations.

sah 09/26/89	more stuff for the germans.

sah 10/31/89	corrections for restart function

bwr 11/27/89	marked messages for foreign language translation

bwr 04/19/90	modified a few messages to improve reliability of
		foreign language translation.

sah 04/30/90	added security control on some uf the functions

sah 12/03/90	corrections for tcbport and emulink 3.0's File Transfer

sah 12/19/90	up to version 4.11 for release

sah 05/03/91	version 4.12, added switch task option [space]

sah 04/07/92	version 5.01, copyright update, corrections for cursor
		problem on terminals during switch task

mjs 04/29/92	clean up module.  modify hotkey logic to check for
		i16f10/11.  this is necessary for this tsr to work
		on an enhanced keyboard where updat501.sys version 0.04
		is used (or on a newer kernel where the corresponding
		mosddcon changes exist).

SAH 08/21/92	Made monitor pop up automatically on execution
		also corrected problem with file count being wrong

=======================================================================^

	.xlist
	include options.inc

service macro  fun
	mov	ah,fun
	pushf
	call	dword ptr cs:[savservice]
	endm

do_restart equ	01

getscb	equ	2
gettask equ	4
remtask equ	5
suspend equ	7
prifun	equ	1ah
addtask equ	22h
chksec	equ	2eh

; the following macro is use during direct video writes for access screen pos

cvidoff macro	where
	call	cviddx
	mov	where,ax
	endm

zeroseg 	segment at 0

		org	16h*4		; bios keyboard i/o
kbint		dw	2 dup (?)
		org	28h*4
org28		dw	2 dup (0)

zeroseg 	ends

	include mostfb.inc
	.list

newscb segment at 0
	.xlist
	assume	cs:newscb
include mosscbdf.inc			; make the scb and tcb data structures available
	assume	cs:nothing
	.list
newscb	ends

tcb segment at 0
	.xlist
include mostcb.inc			; to address tcbspool
	.list
tcb	ends

mainseg  segment para
	assume cs:mainseg,ds:nothing,es:nothing,ss:nothing

	org   80h
operands label byte			; drive:path specified here
	org   100h

start	label near
	jmp	begin
		db	8,8,8,'MONITOR',13,10,26
disval		db	'D'
enval		db	'E'
noval		db	'N'
yesval		db	'Y'
disopt		db	'D'
nodisopt	db	'N'

maincolor	equ	1fh
highcolor	equ	071h
menucolor	equ	0fh
highmono	equ	070h

color		db	maincolor	; white on blue (mono high intens)
hcolor		db	highcolor	; highcolor
mcolor		db	menucolor


hotkey		dw	3920h		; default is ctrl-space
speckeys	db	4		; set control

rt		equ	0
ct		equ	0
rb		equ	24
cb		equ	79
mrt		equ	4
mct		equ	10
mrb		equ	18
mcb		equ	69

ul		equ	0c9h
ur		equ	0bbh
ml		equ	0cch
mr		equ	0b9h
ll		equ	0c8h
lr		equ	0bch
dash		equ	0cdh
bar		equ	0bah

maxtasks	equ	17

rowtop		db	rt		; define upper left corner of window
coltop		db	ct
rowbot		db	rb		; define lower right
colbot		db	cb

okb		dd	?		; original keyboard vector
funtype 	db	0		; keyboard function call


scndata 	db	((cb-ct+1)*(rb-rt+1)+100) dup(0,0)  ; buffer for saved scrn

menudata	db	((mcb-mct+1)*(mrb-mrt+1)+100) dup (0,0)

tcbseg		dw	0		; store tcb segment here

taskpage	dw	0		; taskpage is top

savservice	dd	0		; save services vector
dvarptr 	dd	0		; pointer to dos variables
scbptr		dd	0		; scb pointer
cleanfg 	db	'N'
wordten 	dw	10
curid		dw	0		; current task id
savtimer	dw	0		; save time value
disstatus	db	0		; save keyboard status
lasttry 	db	0		; last max task on screen
curtask 	db	0		; current task position
taskcount	dw	0
doexit		db	'N'		; flag to indicated to return
					; to interupted appication
on300		db	'N'		; on 300 mos
remove		db	'N'		; remove from memory
AutoBoot	db	'N'		; autocome up on boot.

tasksav 	dw	maxtasks dup (0,0),0,0

msgtop		db	0,0,ul,78 dup (dash),ur,'$'
msgm0		db	1,0,bar,78 dup (' '),bar,'$'
msgm1		db	2,0,ml,78 dup (dash),mr,'$'
msgbot		db	24,0,ll,78 dup (dash),lr,'$'

mmsgtop 	db	0,0,ul,58 dup (dash),ur,'$'
mmsgm0		db	1,0,bar,58 dup (' '),bar,'$'
mmsgm1		db	9,0,ml,58 dup (dash),mr,'$'
mmsgbot 	db	mrb-mrt,0,ll,58 dup (dash),lr,'$'

msgmain 	db	1,25,'PC-MOS System Monitor v5.02$'  ;@@xlat
msgcopy 	db	23,2,'      = Select Task, Space = switch, Enter = Commands, Esc = Exit.       $ '  ;@@xlat

msgtask1	db	3,2,'Task Size Video  User   Program'  ;@@xlat
		db	'       Port   Baud  Pri Slice Files  Status$'	;@@xlat
msgmap		db	5,2		;[1] together
maparea 	db	76 dup (' '),'$';[2]

vaddr		dw	0b800h

msgmon		db	'MON'		; mono mode
msgcga		db	'CGA'		; cga color mode 80 column (graphics)
msgc40		db	'C40'		; cga color mode 40 column (graphics)
msghg1		db	'HG1'		; hercules type 1 support (32k)
msghg2		db	'HG2'		; hercules type 2 support (64k)
msge43		db	'E43'		; ega color mode 80 column 43 line
msgega		db	'EGA'		; ega color mode 80 colunm (graphics)
msge40		db	'E40'		; ega color mode 40 column (graphics)
msgvga		db	'VGA'		; vga multitasking support (graphics)
msgv40		db	'V40'		; vga multitasking support (graphics)
active		db    'ACT  '		;@@xlat
waitmsg 	db    'WAIT  '		;@@xlat
hold		db    'HOLD  '		;@@xlat
msgdsfg 	db    'DS'
msgndfg 	db    'ND'
namsg		db    'N\A$'		;@@xlat


menu1		db	2,3, 'F1  - Remove a Task$         '  ;@@xlat
menu2		db	3,3, 'F2  - Restart a Task$        '  ;@@xlat
menu3		db	4,3 ,'F3  - Create a New Task$     '  ;@@xlat
menu4		db	5,3 ,'F4  - Change Priority$       '  ;@@xlat
menu5		db	6,3 ,'F5  - Change Slice$          '  ;@@xlat
menu6		db	2,28,'F6  - Change Keyboard Status$'  ;@@xlat
menu7		db	3,28,'F7  - System Caching ON/OFF$ '  ;@@xlat
menu8		db	4,28,'F8  - Task Switching ON/OFF$ '  ;@@xlat
menu9		db	5,28,'F9  - Change Hotkey$         '  ;@@xlat
menu10		db	6,28,'F10 - Remove Monitor$        '  ;@@xlat
menucr		db	7,3 ,'RET - Return to Monitor$     '  ;@@xlat
menuesc 	db	7,28,'ESC - Exit MOS System Monitor$'  ;@@xlat

hkey1		db	10,5,'Press the key(s) you desire for new HotKey.$           '	;@@xlat
hkey2		db	11,5,'Press the key(s) AGAIN to verify your new HotKey.$      '  ;@@xlat
hkeybad 	db	12,5,'Sorry, New Hotkey could not be Verified.$              '	;@@xlat
hkeyok		db	12,5,'New Hotkey has been Verified.$            '  ;@@xlat
presskey	db	13,5,'Press any key to continue.$               '  ;@@xlat
msgret		db	13,5,'Press <ENTER> when finished.$             '  ;@@xlat
msgrtask	db	10,5,'Do you wish to REMOVE task # '  ;@@xlat
rtaskval	db	'   (Y/N).$          '	;@@xlat
msgrestart	db	10,5,'Do you wish to RESTART task # '  ;@@xlat
rstaskval	db	'   (Y/N).$           '  ;@@xlat
msgnot		db	10,5,'Sorry, this service is not available $         '	;@@xlat
msgnotcur	db	10,42,'for current task$      '  ;@@xlat
msgnotzero	db	10,42,'for task 0.$       '  ;@@xlat
msgnotback	db	10,42,'in background.$        '  ;@@xlat
msgnot300	db	10,42,'on PC-MOS 3.00.$       '  ;@@xlat
msgsecur	db	10,5,'Sorry, no security access for this service.$       '  ;@@xlat
msgrdis 	db	10,5,'Sorry, this service has been disabled.$          '  ;@@xlat

msgkmode	db	10,5,'Current Keyboard mode is '  ;@@xlat
kval		db	'------ $'
kdis		db	'  DIS.'
knodis		db	'NODIS.'
msgkey		db	12,5,'Enter new Mode N for NODIS or D for DIS$   '  ;@@xlat

msgcurpri	db	10,5,'Current Priority is '  ;@@xlat
prival		db	'x.$'
msggetpri	db	11,5,'Enter new Priority : '  ;@@xlat
gprival 	db	' $'
msgaccept	db	13,5,'Press <ENTER> to accept or <ESC> to abort.$           '  ;@@xlat
cache_on	db	10,5,'Caching is currently ENABLED. $       '  ;@@xlat
cache_off	db	10,5,'Caching is currently DISABLED.$       '  ;@@xlat
pam_on		db	10,5,'Task switching for this task ENABLED. $      '  ;@@xlat
pam_off 	db	10,5,'Task switching for this task DISABLED.$      '  ;@@xlat
msgcsel 	db	11,5,'Enter E for ENABLE or D for DISABLE$     '  ;@@xlat
msgatask	db	10,5,'Do you wish to add a background task (Y/N)$             '  ;@@xlat
msgasize	db	11,5,'Enter new Task''s memory size : $          '  ;@@xlat
msgaddok	db	12,5,'Task Successfully added$              '  ;@@xlat
msgnomem	db	12,5,'Insufficient Memory to add Task$             '  ;@@xlat
msgnosmp	db	12,5,'Insufficient SMP to add task$                '  ;@@xlat
msgaerror	db	12,5,'General Error in adding task$                '  ;@@xlat
msgsmall	db	12,5,'Memory size to small for Task$               '  ;@@xlat
msgslice	db	10,5,'Enter Task # '  ;@@xlat
valslice	db	'   new Slice value : $       '  ;@@xlat
badslice	db	11,5,'Invalid Slice (1 - 255)$         '  ;@@xlat
okslice 	db	11,5,'Slice successfully changed.                     $'  ;@@xlat
msgkill 	db	10,5,'Do you wish to remove Monitor from memory (Y/N)$        '  ;@@xlat
msgnokill	db	11,5,'Sorry, Unable to remove Monitor from memory.$           '  ;@@xlat

msgnum		db	0		;  y position for display number
numpos		db	0		;  x position for display number
savenum 	db	'   $'
savecursor	dw	?

savcache	db	?		; save cache value
savetask	dw	?		; save taskid for some of the functions
return		db	?		; return to main screen value

taskdata  label byte			; task structure for add a task function
tasksize	dw	0		; task size
taskid		dw	0		; id
taskclass	db	0		; class
taskbat 	dd	0		; batch file
other		db	27 dup (0)

batfile 	db	10 dup (0)

;   the following is a function table use in the pop up menu

functions label word
		dw	offset funf1
		dw	offset funf2
		dw	offset funf3
		dw	offset funf4
		dw	offset funf5
		dw	offset funf6
		dw	offset funf7
		dw	offset funf8
		dw	offset funf9
		dw	offset funf10

	subttl ishot - check for hotkey
	page
;======================================================================
;,fs
; ishot - check for hotkey
;
; in:	
;
; out:	
;
;,fe
;======================================================================
	assume ds:nothing,es:nothing,ss:nothing
ishot proc near
	cmp	ax,word ptr cs:[hotkey] ; do they want ss menu?
	jnz	dontss			; yes
	cmp	[speckeys],00h
	je	dontss
	push	ax
	call	getspec 		; get control keys
	cmp	al,[speckeys]
	pop	ax
dontss:
	ret
ishot endp

	subttl kbentry
	page
;======================================================================
;,fs
; kbentry
;
; this routine is the intercept routine for the bios keyboard interrupt
; (16h).  it will simply check keys comming from the keyboard for the hot-
; key and if found will display a menu and allow the user to select spooler
; parameters.
;
; in:	
;
; out:	
;
;,fe
;======================================================================
	assume ds:nothing,es:nothing,ss:nothing
	db	'SH'			; use for identification
kbentry proc near
	cmp	byte ptr cs:[remove],'Y'
	je	passon 			; remove monitor
	cmp	ah,0
	je	kbget
	cmp	ah,10h
	je	kbget
	cmp	ah,1
	je	kbstat
	cmp	ah,11h
	je	kbstat
passon:
	jmp	[okb]			; continue with regular kb routine

; process status requests

kbstat:
	mov	[funtype],ah		; tell my routine which fun
	pushf				; simulate int
	call	[okb]			; call regular kb routine
	jz	nokeyrdy		; no key available
	pushf				; save state of zf
	call	ishot			; is it hot key
	je	doss
	popf				; get zf back
nokeyrdy:
	retf	2			; return with flags

; process getkey requests

kbget:
	mov	[funtype],ah		; tell my routine which fun
	pushf
	pushf				; simulate int
	call	[okb]			; call regular kb routine
	call	ishot			; is this hotkey
	jz	doss			; yes
	popf
	iret
doss:
	popf
	push	bx
	push	cx
	push	dx
	push	di
	push	si
	push	ds
	push	es
	mov	ax,cs
	mov	ds,ax			; set our data seg
	mov	es,ax

; if the function was 01h or 11h (get status), must now eat the
; hotkey out of the buffer.  if function intercepted was 01h,
; use i16f00.  if function intercepted was 11h, use i16f10h.

	mov	al,[funtype]
	test	al,1
	jz	noclr
	and	al,10h
	mov	ah,al
	pushf
	call	[okb]
noclr:
	mov	ah,0fh
	int	10h
	mov	[hcolor],highmono
	mov	[vaddr],0b000h
	cmp	al,07h
	je	popok
	mov	[hcolor],highcolor
	mov	[vaddr],0b800h
	cmp	al,04h
	jb	popok
	mov	ax,0e07h
	int	10h
	jmp	short skippop
popok:
	call	popup
skippop:
	pop	es
	pop	ds
	pop	si
	pop	di
	pop	dx
	pop	cx
	pop	bx
	mov	ah,cs:funtype		; do the call they asked for
	jmp	kbentry
kbentry endp

popup	proc	near
	cld
	xor	bh,bh			; page 0
	mov	ah,3			; read cursor position
	int	10h
	push	dx			; save their position
	mov	[savecursor],dx
	call	savescn 		; save their screen area
	call	doscreen
	call	restrscn		; put their screen area back
	pop	dx
	mov	ah,2			; set cursor position
	xor	bh,bh			; page 0
	int	10h
	ret
popup	endp

	subttl doscreen - 
	page
;======================================================================
;,fs
; doscreen - 
;
; doscreen - this is the main procedure which call from within the
; tsr based interupt routines. it is call once when the hot key is
; detected. it will displayed the new screen and also control the
; main action of the program.
;
; in:	
;
; out:	
;
;,fe
;======================================================================
	assume ds:nothing,es:nothing,ss:nothing
doscreen proc near
	lea	si,msgtop
	call	disp
	mov	byte ptr [msgm0],1
	lea	si,msgm0
	call	disp
	mov	byte ptr [msgm1],2
	lea	si,msgm1
	call	disp
	mov	cx,21
	mov	dh,3
dloop1:
	push	cx
	push	dx
	mov	byte ptr [msgm0],dh
	lea	si,msgm0
	call	disp
	pop	dx
	pop	cx
	inc	dh
	loop	dloop1
	mov	byte ptr [msgm1],maxtasks+5  ; please note that this
	lea	si,msgm1		; position is movable by
	call	disp			; maxtask equate.
	lea	si,msgbot
	call	disp
	lea	si,msgmain
	call	disp
	lea	si,msgtask1
	call	disp
	lea	si,msgcopy
	call	disp
	mov	[doexit],'N'
	mov	[curtask],00h
doloop:
	call	dotasks 		; display task information
	call	getkey			; get a key
	jc	doloop			; carry means time for update
	cmp	al,' '
	jne	skipswitch
	call	switchtask
skipswitch:
	cmp	al,0dh			; return
	jne	notret
	call	domenu
	cmp	[doexit],'Y'
	jne	doloop
	jmp	dodone
notret:
	cmp	ax,5100h		; is it pagedown
	jne	notpgdn
dopgdn:
	add	[taskpage],maxtasks	; adjust top of map
	mov	[curtask],00h
	mov	[lasttry],maxtasks	; force redraw
	jmp	short doloop
notpgdn:
	cmp	ax,4900h		; is it pageup
	jne	notpgup
dopgup:
	cmp	[taskpage],0		; are we at top
	je	doloop
	sub	[taskpage],maxtasks	; adjust top of map
	mov	[curtask],00h
	mov	[lasttry],maxtasks	; force redraw
	jmp	short doloop
notpgup:
	cmp	ax,4800h
	jne	notdown
	cmp	[curtask],00h
	jbe	skipup
	dec	[curtask]
skipup:
	jmp	doloop
notdown:
	cmp	ax,5000h
	jne	notup
	mov	al,[lasttry]
	dec	al
	cmp	[curtask],al
	jae	skipdown
	inc	[curtask]
skipdown:
	jmp	doloop
notup:
dodone:
	ret
doscreen endp

	subttl switchtask - 
	page
;======================================================================
;,fs
; switchtask - 
;
; in:	
;
; out:	
;
;,fe
;======================================================================
	assume ds:nothing,es:nothing,ss:nothing
switchtask proc near
	push	es
	push	bx
	push	dx

; following steps defeat mos logic to not allow duplicated set cursors

	mov	es,[tcbseg]
	assume	es:tcb
	xor	dx,dx
	mov	[tcbcpos],dx
	mov	dx,[savecursor]
	mov	ah,2			; set cursor position
	xor	bh,bh			; page 0
	int	10h
	pop	dx
	pop	bx
	call	gettcb
	assume	es:tcb
	mov	ax,[tcbid]
	mov	es,[tcbseg]
	cmp	[tcbpam],'N'		; sah check to see if pam switching is on
	je	csw4			; sah no...so skip
	mov	[tcbswitch],al		; set switch value
	mov	[tcbswflg],'Y'		; set switch flag
	mov	bx,3			; wait for 1/2 second
	mov	al,2			; wait for timer ticks
	service  suspend
csw4:
	pop	es
	ret
switchtask endp

	subttl domenu - 
	page
;======================================================================
;,fs
; domenu - 
;
; in:	
;
; out:	
;
;,fe
;======================================================================
	assume ds:nothing,es:nothing,ss:nothing
domenu proc near
	push	bx
	push	cx
	push	dx
	push	si
	push	di
	push	ds
	push	es
	mov	ax,cs
	mov	ds,ax
	mov	es,ax
	push	word ptr [color]	; save main screen information
	push	word ptr [rowtop]
	push	word ptr [rowbot]
	mov	al,[mcolor]
	mov	[color],al
	mov	[rowtop],mrt
	mov	[coltop],mct
	mov	[rowbot],mrb
	mov	[colbot],mcb
	call	savemenu
magain:

; display main menu

	lea	si,mmsgtop
	call	disp
	mov	cx,mrb-mrt-1
	mov	byte ptr [mmsgm0],1
mloop:
	lea	si,mmsgm0
	call	disp
	inc	byte ptr [mmsgm0]
	loop	mloop
	lea	si,mmsgm1
	call	disp
	lea	si,mmsgbot
	call	disp
	lea	si,menu1
	call	disp
	lea	si,menu2
	call	disp
	lea	si,menu3
	call	disp
	lea	si,menu4
	call	disp
	lea	si,menu5
	call	disp
	lea	si,menucr
	call	disp
	lea	si,menu6
	call	disp
	lea	si,menu7
	call	disp
	lea	si,menu8
	call	disp
	lea	si,menu9
	call	disp
	lea	si,menu10
	call	disp
	lea	si,menuesc
	call	disp

; this is the main loop within the menu

menuloop:
	mov	ax,cs
	mov	ds,ax
	mov	es,ax
	call	inkey			; get a key
	cmp	al,9

; tab key is use to switch between menu colors

	jne	menuntab
	mov	al,[mcolor]
mtabbad:
	add	al,10h
	cmp	al,10h
	jb	mtabok
	cmp	al,20h
	jb	mtabbad
	cmp	al,80h
	jb	mtabok
	and	al,0fh
mtabok:
	mov	[mcolor],al
	mov	[color],al
	jmp	magain
menuntab:
	cmp	al,27
	jne	menunesc

; esc is use to return to application directly from menu option

	mov	[doexit],'Y'
	jmp	menudone
menunesc:
	cmp	ax,3b00h
	jb	notfkeys
	cmp	ax,4400h
	ja	notfkeys
	mov	bl,ah
	sub	bl,3bh
	xor	bh,bh
	shl	bx,1
	mov	[return],'N'
	call	word ptr [bx+functions]
	cmp	[return],'Y'		; wish to return to main screen
	je	menudone
	jmp	menuloop
notfkeys:
	cmp	al,0dh			; return to main status screen
	jne	menuloop
menudone:
	push	cs			; restore main screen
	pop	es
	call	restrmenu
	pop	word ptr [rowbot]
	pop	word ptr [rowtop]
	pop	word ptr [color]
	pop	es
	pop	ds
	pop	di
	pop	si
	pop	dx
	pop	cx
	pop	bx
	ret
domenu endp

	subttl funf1 - remove a task
	page
;======================================================================
;,fs
; funf1 - remove a task
;
; in:	
;
; out:	
;
;,fe
;======================================================================
	assume ds:nothing,es:nothing,ss:nothing
funf1 proc near
	call	clrmenu
	push	ds
	push	es
	call	gettcb
	or	ax,ax			; don't do it if task zero
	jz	f1zero
	call	chksecurity		; check security access
	jc	edone
	call	chkback 		; check if trying to do a background
	jc	notyes
	assume es:tcb
	mov	ax,es
	cmp	ax,[tcbseg]		; check if current task
	je	f1term
	mov	ax,[tcbid]		; get id for task
	lea	bx,rtaskval+1
	mov	cx,2
	call	bintodec
	lea	si,msgrtask
	call	disp
	call	getyn
	cmp	al,'Y'
	jne	notyes
	push	ax
	push	ds
	push	es
	service remtask 	; call mos to remove the task
	pop	es
	pop	ds
	pop	ax
	mov	[return],'Y'		; return to main screen
	mov	[curtask],0
	jmp	short notyes
f1term:
	mov	si,offset msgnotcur	; sorry you can't remove current task
	jmp	short enotyes
f1zero:
	mov	si,offset msgnotzero	; sorry you can't remove task 0
enotyes:
	push	si
	mov	si,offset msgnot
	call	disp
	pop	si
	call	disp
notyes:
	lea	si,presskey
	call	disp
	call	inkey
edone:
	call	clrmenu
	pop	es
	pop	ds
	ret
funf1 endp

	subttl funf2 - restart a task
	page
;======================================================================
;,fs
; funf2  - restart a task
;
; in:	
;
; out:	
;
;,fe
;======================================================================
	assume ds:nothing,es:nothing,ss:nothing
funf2 proc near
	call	clrmenu
	push	es

if	do_restart eq 0
	lea	si,msgnot
else
	cmp	[on300],'Y'		; 3.00 mos
	je	f2zero
	call	gettcb
	or	ax,ax
	jz	f2zero			; don't do if task zero
	call	chksecurity
	jc	f2skip
	call	chkback
	jc	f2done
	assume es:tcb
	lea	si,msgrdis
	cmp	[tcbreboot],00h 	; has reboot been disable
	jne	f2exit
	lea	bx,rstaskval+1
	mov	cx,2
	call	bintodec
	lea	si,msgrestart
	call	disp
	call	getyn
	cmp	al,'Y'
	jne	f2done
	cli
	cmp	[tcbcamon],0ffh
	je	norest
	mov	[tcbcamon],0ffh
	les	bx,cs:[scbptr]
	assume es:newscb
	inc	[bx+scbrstrtc]		; restarted.
norest:
	sti
	jmp	short f2done
f2zero:
	lea	si,msgnotzero
	cmp	[on300],'Y'
	jne	f2not30
	lea	si,msgnot300
f2not30:
endif
f2eexit:
	push	si
	mov	si,offset msgnot
	call	disp
	pop	si
f2exit:
	call	disp
f2done:
	lea	si,presskey
	call	disp
	call	inkey
f2skip:
	pop	es
	call	clrmenu
	ret
funf2 endp

	subttl funf3 - add a background task
	page
;======================================================================
;,fs
; funf3 - add a background task
;
; in:	
;
; out:	
;
;,fe
;======================================================================
	assume ds:nothing,es:nothing,ss:nothing
funf3 proc near
	call	clrmenu
	cmp	[on300],'Y'
	jne	f3not30
	lea	si,msgnot
	call	disp
	lea	si,msgnot300
	call	disp
	jmp	f3done
f3not30:
	lea	si,msgatask
	call	disp
	call	getyn
	cmp	al,'N'
	jne	f3cont
	jmp	f3done
f3cont:
	lea	si,msgasize
	call	disp
	mov	[msgnum],11
	mov	[numpos],36
	call	getval
	lea	si,msgsmall
	cmp	ax,8
	jb	f3done1
	mov	[savetask],ax
	push	di
	push	es

; init task area

	push	cs
	pop	es
	lea	di,taskdata
	mov	cx,10h
	xor	ax,ax
	cld
	rep	stosw
	lea	di,batfile
	mov	cx,5
	rep	stosw
	mov	ax,[savetask]
	mov	[tasksize],ax
	mov	[taskclass],' '
	mov	word ptr [taskbat],offset batfile
	mov	word ptr [taskbat+2],cs
	push	ds
	push	cs
	pop	ds
	lea	si,taskdata
	service addtask
	pop	ds
	pop	es
	pop	di
	mov	[return],'Y'
	lea	si,msgaddok
	jnc	f3done1
	mov	[return],'N'
	lea	si,msgnomem
	cmp	al,8
	je	f3done1
	lea	si,msgnosmp
	cmp	al,18
	je	f3done1
	lea	si,msgaerror
f3done1:
	call	disp
f3done:
	lea	si,presskey
	call	disp
	call	inkey
	call	clrmenu
	ret
funf3 endp

	subttl funf4 - change task's priority
	page
;======================================================================
;,fs
; funf4 - change task's priority
;
; in:	
;
; out:	
;
;,fe
;======================================================================
	assume ds:nothing,es:nothing,ss:nothing
funf4 proc near
	call	clrmenu
	push	bx
	push	es
	call	gettcb
	call	chksecurity
	jc	f4end
	assume	es:tcb
	mov	[savetask],es
	mov	al,[tcbpri]
	shr	al,1
	and	al,0fh
	add	al,'0'
	mov	[prival],al
f4loop:
	mov	[gprival],al
	lea	si,msgcurpri
	call	disp
	lea	si,msgaccept
	call	disp
	lea	si,msggetpri
	call	disp
	call	inkey
	cmp	al,27
	je	f4end
	cmp	al,0dh
	je	f4done
	mov	ah,al
	mov	al,[prival]
	cmp	ah,'0'
	jb	f4loop
	cmp	ah,'7'
	ja	f4loop
	mov	al,ah
	jmp	short f4loop
f4done:
	mov	al,[gprival]
	sub	al,'0'
	shl	al,1
	mov	es,[savetask]
	assume	es:tcb
	mov	[tcbpri],al
f4end:
	pop	es
	assume	es:nothing
	pop	bx
	call	clrmenu
	ret
funf4 endp

	subttl funf5 - change task's slice
	page
;======================================================================
;,fs
; funf5 - change task's slice
;
; in:	
;
; out:	
;
;,fe
;======================================================================
	assume ds:nothing,es:nothing,ss:nothing
funf5 proc near
	call	clrmenu
	push	es
	call	gettcb
	assume es:tcb
	mov	[savetask],es
	pop	es
	call	chksecurity
	jc	f5end
	lea	bx,valslice+1
	mov	cx,2
	call	bintodec
	lea	si,msgslice
	call	disp
	mov	[msgnum],10
	mov	[numpos],40
	call	getval
	or	ax,ax
	jz	f5zero
	or	ah,ah
	jz	f5set
f5zero:
	mov	si,offset badslice
	call	disp
	jmp	short f5done
f5set:
	push	es
	mov	es,[savetask]
	assume	es:tcb
	mov	[tcbslice],al
	pop	es
	mov	si,offset okslice
	call	disp
f5done:
	mov	si,offset presskey
	call	disp
	call	inkey
f5end:
	call	clrmenu
	ret
funf5 endp

	subttl funf6 - change task's keyboard mode
	page
;======================================================================
;,fs
; funf6 - change task's keyboard mode
;
; in:	
;
; out:	
;
;,fe
;======================================================================
	assume ds:nothing,es:nothing,ss:nothing
funf6 proc near
	call	clrmenu
	push	es
	call	gettcb
	call	chksecurity
	jc	f6done
	assume es:tcb
f6loop:
	push	bx
	mov	ax,word ptr [knodis]
	mov	si,word ptr [knodis+2]
	mov	bx,word ptr [knodis+4]
	test	byte ptr [tcbloop],1
	jz	f6a
	mov	ax,word ptr [kdis]
	mov	si,word ptr [kdis+2]
	mov	bx,word ptr [kdis+4]
f6a:
	mov	word ptr [kval],ax
	mov	word ptr [kval+2],si
	mov	word ptr [kval+4],bx
	pop	bx
	lea	si,msgkmode
	call	disp
	lea	si,msgkey
	call	disp
	lea	si,msgret
	call	disp
f6err:
	call	inkey
	cmp	al,0dh
	je	f6done
	and	al,0dfh
	cmp	al,disopt
	je	f6dis
	cmp	al,nodisopt
	jne	f6err
	and	byte ptr [tcbloop], not 1  ; indicate no dis mode
	jmp	f6loop
f6dis:
	or	byte ptr [tcbloop],1	; indicate disable mode
	jmp	f6loop
f6done:
	pop	es
	call	clrmenu
	ret
funf6 endp

	subttl funf7 - change system caching
	page
;======================================================================
;,fs
; funf7 - change system caching
;
; in:	
;
; out:	
;
;,fe
;======================================================================
	assume ds:nothing,es:nothing,ss:nothing
funf7 proc near
	call	clrmenu
	push	bx
	push	es
	les	bx,[scbptr]
	assume	es:newscb
	mov	al,[bx+scbcach]
f7loop:
	mov	[savcache],al
	lea	si, cache_off
	cmp	al, 'Y'
	jne	f7_cont
	lea	si, cache_on
f7_cont:
	call	disp
	lea	si,msgcsel
	call	disp
	lea	si,msgaccept
	call	disp
f7next:
	call	inkey
	cmp	al,0dh
	je	f7done
	cmp	al,27
	je	f7esc
	and	al,0dfh
	cmp	al,enval
	jne	notena
	mov	al,'Y'
	jmp	short f7loop
notena:
	cmp	al,disval
	jne	f7next
	mov	al,'N'
	jmp	short f7loop
f7done:
	les	bx,[scbptr]
	mov	al,[savcache]
	mov	[bx+scbcach],al
f7esc:
	pop	es
	pop	bx
	call	clrmenu
	ret
funf7 endp

	subttl funf8 - change pam switching
	page
;======================================================================
;,fs
; funf8 - change pam switching
;
; in:	
;
; out:	
;
;,fe
;======================================================================
	assume ds:nothing,es:nothing,ss:nothing
funf8 proc near
	call	clrmenu
	push	es
	call	gettcb
	call	chksecurity
	jc	f8esc
	assume	es:tcb
	mov	[savetask],es
	mov	al,[tcbpam]
f8loop:
	mov	[savcache],al
	lea	si, pam_off
	cmp	al, 'N'
	je	f8cont
	lea	si, pam_on
f8cont:
	call	disp
	lea	si,msgcsel
	call	disp
	lea	si,msgaccept
	call	disp
f8next:
	call	inkey
	cmp	al,0dh
	je	f8done
	cmp	al,27
	je	f8esc
	and	al,0dfh
	cmp	al,enval
	jne	notena2
	mov	al,'Y'
	jmp	short f8loop
notena2:
	cmp	al,disval
	jne	f8next
	mov	al,'N'
	jmp	short f8loop
f8done:
	mov	es,[savetask]
	mov	al,[savcache]
	mov	[tcbpam],al
f8esc:
	pop	es
	call	clrmenu
	ret
funf8 endp

	subttl funf9 - change hot key
	page
;======================================================================
;,fs
; 
;
; in:	
;
; out:	
;
;,fe
;======================================================================
	assume ds:nothing,es:nothing,ss:nothing
funf9 proc near
	call	clrmenu
	lea	si,hkey1
	call	disp
	call	inkey_enh
	mov	cx,ax
	call	getspec
	mov	[savcache],al
	lea	si,hkey2
	call	disp
	call	inkey_enh
	cmp	ax,cx
	jne	f9bad
	call	getspec
	cmp	al,[savcache]
	je	f9ver
f9bad:
	lea	si,hkeybad
	call	disp
	jmp	short f9end
f9ver:
	mov	word ptr [hotkey],cx
	xor	al,al
	or	ch,ch
	jz	f9zero
	mov	al,[savcache]
f9zero:
	mov	[speckeys],al
	lea	si,hkeyok
	call	disp
f9end:
	lea	si,presskey
	call	disp
	call	inkey
	call	clrmenu
	ret
funf9 endp

	subttl funf10 - remove monitor from memory
	page
;======================================================================
;,fs
; funf10 - remove monitor from memory
;
; in:	
;
; out:	
;
;,fe
;======================================================================
	assume ds:nothing,es:nothing,ss:nothing
	public	funf10
funf10 proc near
	push	ds
	push	es
	call	clrmenu
	lea	si,msgkill
	call	disp
	call	getyn
	cmp	al,'N'
	jne	f10rem
	jmp	f10done
f10rem:

; locate start of tsr memory

	push	es
	les	bx,dvarptr
	mov	ax,word ptr es:[bx-2]
	mov	bx,cs
	mov	es,ax
	xor	si,si
getloop:
	cmp	word ptr es:[1],bx
	jne	getnot
	or	si,si
	jnz	getdone
	mov	si,es
getnot:
	mov	ax,es
	inc	ax
	add	ax,word ptr es:[3]
	mov	es,ax
	jmp	short getloop
getdone:
	mov	di,es
	mov	ax,es
	inc	ax
	add	ax,word ptr es:[3]
	mov	es,ax
	cmp	byte ptr es:[0],'Z'	; next one free
	je	f10ok
	pop	es
	lea	si,msgnokill
	call	disp
	jmp	short f10done
f10ok:
	xor	ax,ax
	mov	es,ax
	mov	ax,word ptr [okb]
	mov	word ptr es:[16h*4],ax
	mov	ax,word ptr [okb+2]
	mov	word ptr es:[16h*4+2],ax
	mov	es,di
	cli
	mov	word ptr es:[1],0	; mark as free
	mov	es,si
	mov	word ptr es:[1],0	; mark as free
	pop	es
	sti
	pop	es
	pop	ds
	mov	[doexit],'Y'
	mov	[return],'Y'
	mov	[remove],'Y'
	ret
f10done:
	lea	si,presskey
	call	disp
	call	inkey
	call	clrmenu
	pop	ds
	pop	es
	ret
funf10 endp

getspec proc near
	push	es
	xor	ax,ax
	mov	es,ax
	mov	al,byte ptr es:[417h]
	and	al,0fh
	pop	es
	ret
getspec endp

	subttl chksecurity - 
	page
;======================================================================
;,fs
; chksecurity - 
;
; check security access, if current task has access or not
;
; in:	ax -> task to perform operation on
;
; out:	nc if task can access
; 	cy if task can't have access and DX has message
;
;,fe
;======================================================================
	assume ds:nothing,es:nothing,ss:nothing
chksecurity proc near
	push	ax
	push	bx
	mov	bx,ax
	service chksec
	pop	bx
	cmp	ax,1			; if invalid function then assume it is ok
	je	csecok			; so that it will work on 4.00
	cmp	ax,5
	je	csecerror		; > 1 then this means error (5)
csecok:
	pop	ax
	clc
	ret
csecerror:
	pop	ax
	mov	si,offset msgsecur
	call	disp
	mov	si,offset presskey
	call	disp
	call	inkey
	stc
	ret
chksecurity endp

	subttl chkback - check if back ground
	page
;======================================================================
;,fs
; chkback - check if back ground
;
; in:	
;
; out:	
;
;,fe
;======================================================================
	assume ds:nothing,es:nothing,ss:nothing
chkback proc near
	push	ax
	assume	es:tcb
	mov	ax,es
	cmp	ax,cs:[tcbseg]		; check if current task
	jne	cbok
	cmp	ax,[tcbscrdd]
	je	cbok
	lea	si,msgnot
	call	disp
	lea	si,msgnotback
	call	disp
	stc
	jmp	short cbdone
cbok:
	clc
cbdone:
	pop	ax
	ret
chkback endp

	subttl gettcb - returns the currently selected tcb
	page
;======================================================================
;,fs
; gettcb - returns the currently selected tcb
;
; in:	
;
; out:	
;
;,fe
;======================================================================
	assume ds:nothing,es:nothing,ss:nothing
gettcb proc near
	mov	bl,[curtask]
	xor	bh,bh
	shl	bx,1
	shl	bx,1
	mov	es,[bx+tasksav] 	; get tcb address from main array
	assume es:tcb
	mov	ax,[tcbid]
	xor	dx,dx
	ret
gettcb endp

	subttl inkey - returns a key from the keyboard
	page
;======================================================================
;,fs
; inkey - returns a key from the keyboard
;
; in:	
;
; out:	
;
;,fe
;======================================================================
	assume ds:nothing,es:nothing,ss:nothing
inkey proc near
	push	cx
	push	es
	mov	es,cs:[tcbseg]
	assume	es:tcb
	mov	cl,[tcbloop]
	push	cx
	or	[tcbloop],1
	xor	ah,ah
	pushf
	call	[okb]			; get the keyboard input
	pop	cx
	mov	[tcbloop],cl
	pop	es
	assume	es:nothing
	pop	cx
	ret
inkey endp

	subttl inkey_enh - returns a key from the keyboard
	page
;======================================================================
;,fs
; inkey_enh - returns a key from the keyboard
;
; this function is sensitive to whether there is an enhanced keyboard
;
; in:	
;
; out:	
;
;,fe
;======================================================================
	assume ds:nothing,es:nothing,ss:nothing
inkey_enh proc near
	push	cx
	push	es
	mov	ax,40h
	mov	es,ax
	mov	ah,es:[96h]
	and	ah,10h
	mov	es,cs:[tcbseg]
	assume	es:tcb
	mov	cl,[tcbloop]
	push	cx
	or	[tcbloop],1
	pushf
	call	[okb]			; get the keyboard input
	pop	cx
	mov	[tcbloop],cl
	pop	es
	assume	es:nothing
	pop	cx
	ret
inkey_enh endp

	subttl getval - return 3 digit number from user
	page
;======================================================================
;,fs
; getval - return 3 digit number from user
;
; in:	
;
; out:	
;
;,fe
;======================================================================
	assume ds:nothing,es:nothing,ss:nothing
getval proc near
	push	ds
	push	si
	push	bx
	push	cx
	push	cs
	pop	ds
	mov	word ptr [savenum],2020h
	mov	byte ptr [savenum+2],' '
	xor	si,si
gvloop:
	call	dispnum
	call	inkey
	cmp	al,8
	jne	notbsp
	or	si,si
	jz	gvloop
	dec	si
	mov	byte ptr [savenum+si],' '
	jmp	short gvloop
notbsp:
	cmp	al,0dh
	je	gvdone
	cmp	si,2
	ja	gvloop
	cmp	al,'0'
	jb	gvloop
	cmp	al,'9'
	ja	gvloop
	mov	[savenum+si],al
	inc	si
	jmp	short gvloop
gvdone:
	xor	bx,bx
	mov	cx,3
	lea	si,savenum
gvdlp:
	lodsb
	cmp	al,' '
	je	gvdldone
	push	ax
	shl	bx,1
	mov	ax,bx
	shl	ax,1
	add	bx,ax
	add	bx,ax
	pop	ax
	xor	ah,ah
	sub	al,'0'
	add	bx,ax
	loop	gvdlp
gvdldone:
	mov	ax,bx
	pop	cx
	pop	bx
	pop	si
	pop	ds
	ret
getval endp

	subttl dispnum - 
	page
;======================================================================
;,fs
; dispnum - 
;
; in:	
;
; out:	
;
;,fe
;======================================================================
	assume ds:nothing,es:nothing,ss:nothing
dispnum proc near
	push	si
	lea	si,msgnum
	call	disp
	pop	si
	ret
dispnum endp

	subttl getyn - return either an y or n
	page
;======================================================================
;,fs
; getyn - return either an y or n
;
; in:	
;
; out:	
;
;,fe
;======================================================================
	assume ds:nothing,es:nothing,ss:nothing
getyn proc near
	call	inkey
	mov	ah,'Y'
	and	al,0dfh
	cmp	al,yesval
	je	getynok
	mov	ah,'N'
	cmp	al,noval
	jne	getyn
getynok:
	mov	al,ah
	ret
getyn endp

	subttl clrmenu - clears the menu options area of the screen
	page
;======================================================================
;,fs
; 
;
; in:	
;
; out:	
;
;,fe
;======================================================================
	assume ds:nothing,es:nothing,ss:nothing
clrmenu proc near
	mov	cx,4
	mov	byte ptr [mmsgm0],10
clrloop:
	lea	si,mmsgm0
	call	disp
	inc	byte ptr [mmsgm0]
	loop	clrloop
	ret
clrmenu  endp

	subttl dotasks - displays mos map style display on the screen
	page
;======================================================================
;,fs
; dotasks - displays mos map style display on the screen
;
; in:	
;
; out:	
;
;,fe
;======================================================================
	assume ds:nothing,es:nothing,ss:nothing
dotasks proc near

; clear out task save pointers

	push	cs
	pop	es
	cli
	lea	di,tasksav
	mov	cx,10
	xor	ax,ax
	rep	stosw

; setup for main loop

	les	bx,[scbptr]
	assume es:newscb
	call	getstart		; get start task
	assume es:tcb
	xor	cx,cx
	xor	si,si
	mov	dh,5
dtloop:
	cmp	byte ptr [tcbtype],'T'	; is this a valid tcb task
	jne	dtend
	mov	byte ptr [msgmap],dh
	mov	word ptr [si+tasksav],es; save tcb into task save pointer
	push	si
	push	dx
	push	cx
	push	word ptr [color]
	cmp	cl,[curtask]
	jne	dtskip
	mov	al,[hcolor]
	mov	[color],al
dtskip:
	call	maketask		; fill out task entries
	lea	si,msgmap		; display information
	call	disp
	pop	word ptr [color]
	pop	cx
	pop	dx
	pop	si
	add	si,4
	inc	dh
	inc	cx
	cmp	cl,maxtasks		; have we hit max displayed tasks yet
	jae	dtend
	mov	ax,es
	or	ax,ax
	jnz	dtloop

; all done, now clear out any possiabable remaining entries from
; last displays

dtend:
	cmp	cl,maxtasks		; already display max, then skip
	ja	dtend4
	cmp	cl,[lasttry]		; above or equal to last time, skio
	jae	dtend3

; we must fill out remaining entries with blanks

	push	cx
dtend2:
	cmp	cl,[lasttry]		; done yet
	je	dtend2a
	mov	byte ptr [msgm0],dh
	lea	si,msgm0
	push	cx
	push	dx
	call	disp
	pop	dx
	pop	cx
	inc	dh
	inc	cx
	jmp	short dtend2
dtend2a:
	pop	cx
dtend3:
	mov	[lasttry],cl		; save count for next time
dtend4:
	ret
dotasks  endp

	subttl getstart - get starting tcb 
	page
;======================================================================
;,fs
; getstart - get starting tcb 
;
; get starting tcb base on user request of page up and
; page downs. it takes account of removed tasks and make sure it
; its only valid for tasks that are on the system.
;
; in:	
;
; out:	
;
;,fe
;======================================================================
	assume ds:nothing,es:nothing,ss:nothing
getstart proc near
	call	chkstart		; request task start within limits
	jnc	getok			; ok continue
	sub	[taskpage],maxtasks	; no, adjust count downward until ok
	jmp	short getstart
getok:
	mov	es,ax
	ret
getstart endp

	subttl chkstart - 
	page
;======================================================================
;,fs
; chkstart - 
;
; count up tasks until 1 of the following
;  1. found requested task at [taskpage] counts
;  2. end of list return error with carry set
;
; in:	
;
; out:	
;
;,fe
;======================================================================
	assume ds:nothing,es:newscb,ss:nothing
chkstart proc near
	push	es
	mov	es,[bx+scbtcbpf]	; get first task on system
	push	cx
	xor	cx,cx
	mov	ax,es
	assume es:tcb
chkloop:
	cmp	byte ptr [tcbtype],'T'	; valid task
	jne	chkbad
	cmp	cx,[taskpage]		; found our task yet
	je	chkok
	inc	cx			; bump counter
	mov	ax,[tcbtcbpn]
	or	ax,ax			; end of list
	jz	chkbad
	mov	es,ax
	jmp	short chkloop
chkbad:
	stc
	jmp	short chkdone
chkok:
	clc
chkdone:
	pop	cx
	pop	es
	ret
chkstart endp

	page
;-------------------------------------------------------------------
;	es -> tcb
;-------------------------------------------------------------------
	subttl maketask - make task information for display
	page
;======================================================================
;,fs
; maketask - make task information for display
;
; in:	
;
; out:	
;
;,fe
;======================================================================
	assume ds:nothing,es:tcb,ss:nothing
maketask proc near
	push	es
	mov	ax,2020h
	mov	cx,76/2
	push	cs
	pop	es
	assume	es:nothing
	lea	di,maparea
	rep	stosw
	pop	es
	assume es:tcb
	mov	ax,es:[tcbid]		; tcb id #
	xor	dx,dx
	mov	cx,2
	mov	bx,offset maparea+1
	cmp	ax,[curid]
	jne	notcurid
	mov	byte ptr [bx+1],'*'
notcurid:
	call	bintodec
	mov	ax,es:[tcbendad]	; tcb size
	sub	ax,es:[tcbbegad]
	mov	cx,6
	shr	ax,cl
	xor	dx,dx
	mov	cx,3
	mov	bx,offset maparea+7
	push	bx
	call	bintodec
	pop	bx
	mov	byte ptr [bx+1],'K'
	mov	cx,3
	mov	di,offset maparea+11
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
	jmp	short mapv0
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
	mov	di,offset maparea+18
	mov	cx,4
	push	es
	pop	ds
	call	movelong
	pop	ds

public nouser
nouser:
	push	ds			; tcb program name
	lea	si,es:[tcbprgnm]
	lea	di,maparea+23
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
	and	ax,07fffh		; mask off high bit for elterm
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
	mov	di,offset maparea+38
	mov	cx,3
	call	movelong
vna_baud:
	call	na_baud
	jmp	short portdone
portcont:
	call	cnvt_port
	test	word ptr es:[tcbvram],8 ; for vna, use n/a for baud
	jnz	vna_baud
	mov	bx,offset maparea+47	; tcb baud rate
	mov	cx,6
	mov	ax,word ptr es:[tcbbaud]
	mov	dx,word ptr es:[tcbbaud+2]
	call	bintodec
portdone:
	mov	bx,offset maparea+51	; tcb priority
	mov	al,es:[tcbpri]
	shr	al,1			;tcb priority = priority * 2
	and	ax,000fh
	mov	cx,2
	xor	dx,dx
	call	bintodec
	mov	bx,offset maparea+56	; tcb time slice
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
	mov	bx,offset maparea+62
	xor	dx,dx
	mov	ax,cx
	mov	cx,5
	call	bintodec
	pop	es
	assume	es:tcb
	mov	di,offset maparea+66	; tcb wait status
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
	mov	di,offset maparea+71
	mov	si,offset msgndfg
	test	es:[tcbloop],1
	jz	mapdisp2
	mov	si,offset msgdsfg
mapdisp2:
	call	movelong
	mov	ax,es:[tcbtcbpn]
	mov	es,ax
	ret

na_baud:
	mov	si,offset namsg
	mov	di,offset maparea+45
	mov	cx,3
	call	movelong
	ret

cnvt_port:
	inc	ax
	xor	dx,dx
	mov	cx,2
	mov	bx,offset maparea+40
	call	bintodec
	ret
maketask endp

	subttl movelong - 
	page
;======================================================================
;,fs
; movelong - 
;
; in:	
;
; out:	
;
;,fe
;======================================================================
	assume ds:nothing,es:nothing,ss:nothing
movelong proc
	push	es
	cld
	push	cs
	pop	es
	rep	movsb
	pop	es
	ret
movelong endp

	subttl getkey - 
	page
;======================================================================
;,fs
; getkey - 
;
; getkey - inteligent input routine which allows for occasion
; interuptions because we have detected a change in the tcbs.
;
; in:	
;
; out:	
;
;,fe
;======================================================================
	assume ds:nothing,es:nothing,ss:nothing
getkey proc near

; setup for main routine

	push	bx
	push	es
	les	bx,[scbptr]
	assume	es:newscb
	mov	ax,[bx+scbtimer]
	mov	[savtimer],ax		; save current timer value
	mov	es,[tcbseg]
	assume	es:tcb
	mov	al,[tcbloop]
	mov	[disstatus],al		; save current keyboard mode
	or	[tcbloop],1		; set in disable mode
	pop	es
	assume	es:nothing
	pop	bx
	call	dosums			; compute checksums of tcbs
getkey0:
	mov	ah,1
	pushf
	call	[okb]			; check if key is ready
	pushf
	call	chktasks		; check if task is ready for update
	jc	getkey1
	popf
	jz	getkey0
	xor	ah,ah
	pushf
	call	[okb]			; get the keyboard input
	clc
	jmp	short getkey2
getkey1:
	popf
	stc
getkey2:

; place keyboard mode back as normal

	pushf
	push	ax
	push	es
	mov	es,[tcbseg]
	assume	es:tcb
	mov	al,[disstatus]
	mov	[tcbloop],al
	pop	es
	pop	ax
	popf
	ret
getkey endp

	subttl dosums - computes checksum of displayed tcbs
	page
;======================================================================
;,fs
; dosums - computes checksum of displayed tcbs
;
; in:	
;
; out:	
;
;,fe
;======================================================================
	assume ds:nothing,es:nothing,ss:nothing
dosums proc near
	lea	si,tasksav
dsloop:
	lodsw
	or	ax,ax
	jz	dsend
	mov	es,ax
	call	getsum
	mov	word ptr [si],ax
	inc	si
	inc	si
	jmp	short dsloop
dsend:
	ret
dosums endp

	subttl cksums -
	page
;======================================================================
;,fs
; cksums -
;
; check checksums of display tcbs and return carry set if
; any of them are different
;
; in:	
;
; out:	
;
;,fe
;======================================================================
	assume ds:nothing,es:nothing,ss:nothing
cksums proc near
	push	bx
	push	es
	xor	ax,ax
	les	bx,[scbptr]
	assume	es:newscb
	mov	es,[bx+scbtcbpf]
	assume	es:tcb
cktcb:
	cmp	byte ptr [tcbtype],'T'
	jne	cktcbdone
	inc	ax
	mov	es,[tcbtcbpn]
	jmp	short cktcb
cktcbdone:
	pop	es
	pop	bx
	cmp	ax,[taskcount]
	je	ckcont
	mov	[taskcount],ax
	jmp	ckdiff
ckcont:
	lea	si,tasksav
ckloop:
	lodsw
	or	ax,ax
	jz	ckend
	mov	es,ax
	call	getsum
	cmp	word ptr [si],ax
	jne	ckdiff
	inc	si
	inc	si
	jmp	short	ckloop
ckend:
	clc
	ret
ckdiff:
	stc
	ret
cksums endp

	subttl getsum - compute checksum of particular tcb
	page
;======================================================================
;,fs
; getsum - compute checksum of particular tcb
;
; in:	
;
; out:	
;
;,fe
;======================================================================
	assume ds:nothing,es:tcb,ss:nothing
getsum proc near
	push	bx
	mov	ax,[tcbendad]
	mov	bl,[tcbvideo]
	mov	bh,[tcbloop]
	add	ax,bx
	add	ax,word ptr [tcbuser]
	add	ax,word ptr [tcbuser+2]
	add	ax,word ptr [tcbprgnm]
	add	ax,word ptr [tcbprgnm+2]
	add	ax,word ptr [tcbprgnm+4]
	add	ax,word ptr [tcbprgnm+6]
	add	ax,[tcbport]
	mov	bl,[tcbslice]
	mov	bh,[tcbpri]
	add	ax,bx
	pop	bx
	ret
getsum endp

	subttl chktasks - check to see if task should be awaken for update
	page
;======================================================================
;,fs
; chktasks - check to see if task should be awaken for update
;
; in:	
;
; out:	
;
;,fe
;======================================================================
	assume ds:nothing,es:nothing,ss:nothing
chktasks proc near
	push	bx
	push	es
	les	bx,[scbptr]
	assume es:newscb
	mov	ax,[bx+scbtimer]
	sub	ax,[savtimer]
	pop	es
	assume es:nothing
	pop	bx
	cmp	ax,18
	ja	chkt2
	clc
	ret
chkt2:
	call	cksums
	ret
chktasks endp

	subttl writchar -
	page
;======================================================================
;,fs
; writchar -
;
; in:	
;
; out:	
;
;,fe
;======================================================================
	assume ds:nothing,es:nothing,ss:nothing
writchar proc near
	xor	bh,bh			;page 0
	mov	bl,[color]
	mov	ah,9			;write char/attr
	mov	cx,1			;one char
	int	10h
	inc	dl			;next col
	mov	ah,2
	xor	bh,bh
	int	10h			;set new position
	ret
writchar endp

	subttl savemenu - save the screen area defined by dx and cx
	page
;======================================================================
;,fs
; savemenu - save the screen area defined by dx and cx
;
; in:	
;
; out:	
;
;,fe
;======================================================================
	assume ds:nothing,es:nothing,ss:nothing
savemenu proc near
	lea	di,menudata
	jmp	short saveentry
savescn:
	lea	di,scndata		; put their screen here
saveentry:
	mov	dh,rowtop		; row upper right
	mov	dl,coltop		; col
	cld
	push	si
	push	ds
	mov	ds,cs:[vaddr]
	assume	ds:nothing
	cvidoff si
saveline:
	movsw
	inc	dl			; next column position
	cmp	dl,colbot		; end of line yet?
	jna	saveline		; do the whole line
	mov	dl,coltop		; reset to start of next line
	inc	dh			; next row
	cvidoff si
	cmp	dh,rowbot		; last row yet?
	jna	saveline		; do all rows
	pop	ds
	pop	si
	ret				; that's it all saved, back to you...
savemenu endp

	subttl restrmenu -
	page
;======================================================================
;,fs
; restrmenu -
;
; in:	
;
; out:	
;
;,fe
;======================================================================
	assume ds:nothing,es:nothing,ss:nothing
restrmenu proc near
	lea	si,menudata
	jmp	short restrentry
restrscn:
	lea	si,scndata		; get their screen from here
restrentry:
	push	cs
	pop	ds
	mov	dh,rowtop		; row upper right
	mov	dl,coltop		; col
	cld
	push	di
	push	es
	mov	es,[vaddr]
	cvidoff di
restline:
	movsw				; get char/attr from save area
	inc	dl			; next column position
	cmp	dl,colbot		; end of line yet?
	jna	restline		; do the whole line
	mov	dl,coltop		; reset to start of next line
	inc	dh			; next row
	cvidoff di
	cmp	dh,rowbot		; last row yet?
	jna	restline		; do all rows
	pop	es
	pop	di
	ret				; that's it all saved, back to you...
restrmenu endp

	subttl cviddx - 
	page
;======================================================================
;,fs
; cviddx - 
;
; in:	
;
; out:	
;
;,fe
;======================================================================
	assume ds:nothing,es:nothing,ss:nothing
cviddx proc near
	push	bx
	mov	al,dh
	xor	ah,ah
	shl	ax,1
	shl	ax,1
	shl	ax,1
	shl	ax,1
	mov	bx,ax
	shl	bx,1
	shl	bx,1
	add	ax,bx
	mov	bl,dl
	xor	bh,bh
	add	ax,bx
	shl	ax,1
	pop	bx
	ret
cviddx endp

	subttl disp -
	page
;======================================================================
;,fs
; disp -
;
; in:	
;
; out:	
;
;,fe
;======================================================================
	assume ds:nothing,es:nothing,ss:nothing
disp proc near
	cld
	mov	dh,rowtop		; start at top left of screen
	add	dh,[si] 		; calc starting point (row)
	inc	si			; point to col
	mov	dl,coltop
	add	dl,[si] 		; calc starting point (col)
	push	es
	push	di
	cvidoff di
	mov	es,[vaddr]
	inc	si			; point to start of string
	xor	bh,bh
	mov	bl,[color]		; color
displp:
	lodsb
	cmp	al,'$'			; end of string?
	je	dispend
	mov	ah,bl
	stosw
	inc	dl			; next column
	jmp	displp			; do the whole string
dispend:
	inc	dl			; next column
	mov	ah,2			; set cursor pos.
	int	10h
	pop	di
	pop	es
	ret
disp endp

	subttl bintodec -
	page
;======================================================================
;,fs
; bintodec -
;
; in:	
;
; out:	
;
;,fe
;======================================================================
	assume ds:nothing,es:nothing,ss:nothing
bintodec proc
	push	cx
btdloop1:
	div   cs:[wordten]		; dx:ax is source integer
	add	dl,'0'			; cx is length of target
	mov	[bx],dl 		; bx is end of target
	dec	bx
	xor	dx,dx
	loop	btdloop1
	pop	cx
btdloop2:
	inc	bx
	dec	cx
	jz	btdret
	cmp	byte ptr [bx],'0'
	jne	btdret
	mov	byte ptr [bx],' '
	jmp	btdloop2
btdret:
	ret
bintodec endp

	subttl bintohex -
	page
;======================================================================
;,fs
; bintohex -
;
; in:	
;
; out:	
;
;,fe
;======================================================================
	assume ds:mainseg,es:nothing,ss:nothing
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

endres2 label	byte			; end of resident routines

	subttl	initilization - not retained in memory
	page
;--------------------------------------------------------------------
;			 user interface logic
;--------------------------------------------------------------------

msginstall db	13,10,'PC-MOS System Monitor v5.02 Installed.        ',13,10,'$'  ;@@xlat
msgactive  db	'To Activate Monitor Press Ctrl-Space             ',13,10,'$'  ;@@xlat
msgalready db	13,10,'PC-MOS System Monitor v5.02 already Installed.       '  ;@@xlat
	  db	13,10,'$'
msgtsl	  db	'(c) Copyright 1989 - 1992 The Software Link, Incorporated.',13,10,'$'	;@@xlat

CheckParms proc	near
	mov	si,81h
NextParm:
	lodsb
	cmp	al,13
	je	ParmsDone
	cmp	al,'/'
	je	doparm
	cmp	al,'\'
	je	doparm
	cmp	al,'-'
	jne	NextParm
doparm:
	lodsb
	and	al,0dfh
	cmp	al,'U'
	jne	NextParm
	mov	AutoBoot,'Y'
	jmp	short NextParm
ParmsDone:
	ret
CheckParms endp

	even
version label	near
	include version.inc

badmos	db	13,10, 'This program requires atleast PC-MOS/386 3.00'	;@@xlat
	db	13,10,'$'

	assume ds:nothing,es:nothing,ss:nothing
begin	label near

; routine to check mos version

	mov	ah, 30h
	int	21h
	push	ax
	mov	ah, 30h
	mov	bx, ax
	mov	cx, ax
	mov	dx, ax
	int	21h
	pop	bx
	cmp	ax,bx
	je	mosbad
	cmp	ax, 03h
	ja	mosok
	jne	mosbad
	mov	[on300],'Y'
	jmp	short mosok
mosbad:
	lea	dx, badmos
	mov	ah, 9
	int	21h
	mov	ax, 4c01h
	int	21h

mosok	label	near
	call	CheckParms

; get video address

	mov	ah,15
	int	10h
	cmp	al,7
	jne	notmono
	mov	[vaddr],0b000h
	mov	[hcolor],highmono
notmono:

; test to see if monitor is already installed

	mov	ax,3516h
	int	21h
	cmp	word ptr es:[bx-2],'HS'
	jne	doinstall
	lea	dx,msgalready
	mov	ah,9
	int	21h
	lea	dx,msgtsl
	mov	ah,9
	int	21h
	lea	dx,msgactive
	mov	ah,9
	int	21h
	mov	ax,4c01h
	int	21h
doinstall:
	mov	ah,52h
	int	21h
	mov	word ptr [dvarptr],bx
	mov	word ptr [dvarptr+2],es

; save pointer to scb and current tasks tcb and tcbid for current task

	mov	ah,34h
	int	21h
	assume	es:newscb
	sub	bx,offset [scbinmos]
	mov	word ptr [scbptr],bx
	mov	word ptr [scbptr+2],es
	assume	es:newscb
	mov	ax,[bx+scbtcbpc]
	mov	[tcbseg],ax
	mov	es,ax
	assume	es:tcb
	mov	ax,[tcbid]
	mov	[curid],ax

; set the bios keyboard interrupt vector and exit with routines resident

	xor	ax,ax
	mov	es,ax
	assume	es:nothing
	mov	ax,es:[services*4]
	mov	bx,es:[services*4+2]
	cmp	[on300],'Y'
	jne	not38ser
	mov	ax,es:[38h*4]
	mov	bx,es:[38h*4+2]
not38ser:
	mov	word ptr [savservice],ax
	mov	word ptr [savservice+2],bx
	mov	ax,es:[kbint]		; get offset
	mov	word ptr [okb],ax
	mov	ax,es:[kbint+2] 	; get seg
	mov	word ptr [okb+2],ax
	cli
	mov	es:[kbint],offset kbentry
	mov	es:[kbint+2],cs 	; new seg
	sti
	cmp	AutoBoot,'Y'
	jne	skipauto
	push	ds
	push	es
	mov	ax,cs
	mov	ds,ax			; set our data seg
	mov	es,ax
	call	popup
	pop	es
	pop	ds
skipauto:
	lea	dx,msginstall
	mov	ah,9
	int	21h
	lea	dx,msgtsl
	mov	ah,9
	int	21h
	lea	dx,msgactive
	mov	ah,9
	int	21h
	lea	dx,endres2		; terminate & stay resident
	int	27h

mainseg ends
	end start

