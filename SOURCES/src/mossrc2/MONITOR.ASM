	include page.inc
	title	MONITOR - PC-MOS System Monitor

;-----------------------------------------------------------------------;
;									;
;                    Development Specification				;
;									;
;									;
; Program Name: MONITOR.COM		Assigned to: Stewart Hyde	;
; Module Name:	MONITOR 		Assign date: 02/25/89 (Self)	;
; Entry Points: MONITOR 		Completed:   03/28/89		;
; Entry From:	MOS command processor					;
; Entry Method: EXEC (TSR)						;
; Purpose:      							;
; Refer To:     							;
; Last Update:	12/19/90						;
;									;
; This program provides users with an easy to use method of managing	;
; the task on PC-MOS system. This program is an TSR which can be pop	;
; and user can select which task he or she wants to modified and press	;
; return to display an option menu. Some of the options on the menu will;
; effect the system globally and some will onely effected the task	;
; which has been selected.  Also which main display is up, the screen	;
; will be continously update on changes of task details being displayed.;
;-----------------------------------------------------------------------;
; mjs 05/03/89	Modified the size of the addtask structure to match	;
;		changes made in int38fun22.				;
;-----------------------------------------------------------------------;
; SAH 05/04/89	Corrections for de-installing monitor and cosmetics	;
;-----------------------------------------------------------------------;
; SAH 07/19/89	Corrections for colors on mono-chrome systems		;
;-----------------------------------------------------------------------;
; SAH 06/28/89	Corrections if some one switches VMODES will resident	;
; SAH 06/29/89	Corrections for switching between VMODE of MONO and	;
;		other Modes when Monitor is resident			;
; SAH 07/18/89	Corrected Returning wrong task on remove a task 	;
; SAH 07/21/89	Corrected ports on VNA during MOS MAP display		;
;		Corrected not setting Priority. 			;
; SAH 08/25/89	Added option to disable restart option.			;
; SAH 09/05/89  Corrections for remove monitor and restart task options ;
; SAH 09/19/89  Corrections for translations.				;
;     09/26/89  More stuff for the germans.				;
;     10/31/89	Corrections for Restart function			;
;-----------------------------------------------------------------------;
; BWR 11/27/89	Marked messages for foreign language translation	;
;-----------------------------------------------------------------------;
; BWR 04/19/90	Modified a few messages to improve reliability of	;
;		foreign language translation.				;
;-----------------------------------------------------------------------;
; SAH 04/30/90  Added Security control on some uf the functions		;
;-----------------------------------------------------------------------;
; SAH 12/03/90  Corrections for TCBPORT and Emulink 3.0's File Transfer ;
;-----------------------------------------------------------------------;
; SAH 12/19/90	Up to version 4.11 for release				;
;-----------------------------------------------------------------------;
	.xlist
	include options.inc

Service macro  fun
	mov	ah,fun
	pushf
	call	dword ptr cs:[savservice]
	endm


DO_RESTART equ	01

GetSCB	equ	2
GetTASK equ	4
RemTASK equ	5
PriFun	equ	1ah
AddTASK equ	22h
ChkSec	equ	2eh


; The following macro is use during direct video writes for access screen pos

CVidOff macro	where
	call	CVidDX
	mov	where,ax
	endm


zeroseg		segment at 0

		org	16H*4		; bios keyboard i/o
kbint		dw	2 dup (?)	
		org	28h*4
org28		dw	2 dup (0)			

zeroseg		ends

	include mostfb.inc
	.list

newscb segment at 0
	.xlist                                                      
	assume	cs:newscb
Include mosscbdf.Inc	; make the scb and tcb data structures available
	assume	cs:nothing
	.list                                                       
newscb	ends

tcb segment at 0
	.xlist      
include mostcb.Inc	; to address tcbspool 
	.list       
tcb	ends

Mainseg  segment para
	 assume cs:mainseg

         org   80h
operands label byte          ; drive:path specified here
         org   100h

start    label near
         jmp   begin
	 db    8,8,8,'MONITOR',13,10,26
DisVal	 db    'D'
EnVal	 db    'E'
NoVal	 db    'N'	
YesVal	 db    'Y'
DisOpt	 db    'D'
NoDisOpt db    'N'

MAINCOLOR	equ	1fh
HIGHCOLOR	equ	071h
MENUCOLOR	equ	0fh
HIGHMONO	equ	070h

color		db	MAINCOLOR	; white on blue (mono high intens)
hcolor		db	HIGHCOLOR	; highcolor
mcolor		db	MENUCOLOR


hotkey		dw	3920h           ; default is ctrl-space
SpecKeys	db	4		; set control

rt		equ	0
ct		equ	0
rb		equ	24
cb		equ	79
mrt		equ	4
mct		equ	10
mrb		equ	18
mcb		equ	69

UL		equ	0c9h
UR		equ	0bbh
ML		equ	0cch
MR		equ	0b9h
LL		equ	0c8h
LR		equ	0bch
DASH		equ	0cdh
BAR		equ	0bah

MAXTASKS	equ	17

rowtop		db	rt		; define upper left corner of window
coltop		db	ct
rowbot		db	rb		; define lower right
colbot		db	cb

okb		dw	2 dup(0)	; Original keyboard vector
funtype		db	0		; Keyboard function call


scndata 	db	((cb-ct+1)*(rb-rt+1)+100) dup(0,0) ; Buffer for saved scrn

menudata	db	((mcb-mct+1)*(mrb-mrt+1)+100) dup (0,0)

tcbseg		dw	0		; store tcb segment here

taskpage	dw	0		; taskpage is top

savservice	dd	0		; Save services vector
DVarPtr 	dd	0		; Pointer to DOS variables
scbptr		dd	0		; SCB Pointer
cleanfg		db	'N'
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

tasksav 	dw	MAXTASKS dup (0,0),0,0

msgtop		db	0,0,UL,78 dup (DASH),UR,'$'
msgm0		db	1,0,BAR,78 dup (' '),BAR,'$'
msgm1		db	2,0,ML,78 dup (DASH),MR,'$'
msgbot		db	24,0,LL,78 dup (DASH),LR,'$'

mmsgtop 	db	0,0,UL,58 dup (DASH),UR,'$'
mmsgm0		db	1,0,BAR,58 dup (' '),BAR,'$'
mmsgm1		db	9,0,ML,58 dup (DASH),MR,'$'
mmsgbot 	db	MRB-MRT,0,LL,58 dup (DASH),LR,'$'

msgmain 	db	1,25,'PC-MOS System Monitor v4.11$' ;@@XLAT
msgcopy 	db	23,2,' Highlight desired task and press ENTER for command window, or ESC to exit.$ ' ;@@XLAT
msgtask1	db	3,2,'Task Size Video  User   Program' ;@@XLAT
		db	'       Port   Baud  Pri Slice Files  Status$' ;@@XLAT
msgmap		db	5,2			;[1] Together
maparea 	db	76 dup (' '),'$'	;[2]

vaddr		dw	0b800h

msgmon	db	'MON'		; mono mode
msgcga	db	'CGA'		; cga color mode 80 column (graphics)
msgc40	db	'C40'		; cga color mode 40 column (graphics)
msghg1	db	'HG1'		; hercules type 1 support (32k)
msghg2	db	'HG2'		; hercules type 2 support (64k)
msge43	db	'E43'		; ega color mode 80 column 43 line
msgega	db	'EGA'		; ega color mode 80 colunm (graphics)
msge40	db	'E40'		; ega color mode 40 column (graphics)
msgvga	db	'VGA'		; vga multitasking support (graphics)
msgv40	db	'V40'		; vga multitasking support (graphics)
active	 db    'ACT  ' ;@@XLAT
waitmsg  db    'WAIT  ' ;@@XLAT
hold	 db    'HOLD  ' ;@@XLAT
msgdsfg  db    'DS'
msgndfg  db    'ND'
namsg	 db    'N\A$' ;@@XLAT


menu1	 db	2,3, 'F1  - Remove a Task$         ' ;@@XLAT
menu2	 db	3,3, 'F2  - Restart a Task$        ' ;@@XLAT
menu3	 db	4,3 ,'F3  - Create a New Task$     ' ;@@XLAT
menu4	 db	5,3 ,'F4  - Change Priority$       ' ;@@XLAT
menu5	 db	6,3 ,'F5  - Change Slice$          ' ;@@XLAT
menu6	 db	2,28,'F6  - Change Keyboard Status$' ;@@XLAT
menu7	 db	3,28,'F7  - System Caching ON/OFF$ ' ;@@XLAT
menu8	 db	4,28,'F8  - Task Switching ON/OFF$ ' ;@@XLAT
menu9	 db	5,28,'F9  - Change Hotkey$         ' ;@@XLAT
menu10	 db	6,28,'F10 - Remove Monitor$        ' ;@@XLAT
menucr	 db	7,3 ,'RET - Return to Monitor$     ' ;@@XLAT
menuesc  db	7,28,'ESC - Exit MOS System Monitor$' ;@@XLAT

hkey1	 db	10,5,'Press the key(s) you desire for new HotKey.$           ' ;@@XLAT
hkey2	 db	11,5,'Press the key(s) AGAIN to verify your new HotKey.$      ' ;@@XLAT
hkeybad  db	12,5,'Sorry, New Hotkey could not be Verified.$              ' ;@@XLAT
hkeyok	 db	12,5,'New Hotkey has been Verified.$            ' ;@@XLAT
presskey db	13,5,'Press any key to continue.$               ' ;@@XLAT
msgret	 db	13,5,'Press <ENTER> when finished.$             ' ;@@XLAT
msgrtask db	10,5,'Do you wish to REMOVE task # ' ;@@XLAT
rtaskval db	'   (Y/N).$          ' ;@@XLAT
msgrestart db	10,5,'Do you wish to RESTART task # ' ;@@XLAT
rstaskval  db	'   (Y/N).$           ' ;@@XLAT
msgnot	   db	10,5,'Sorry, this service is not available $         ' ;@@XLAT
msgnotcur  db	10,42,'for current task$      ' ;@@XLAT
msgnotzero db	10,42,'for task 0.$       ' ;@@XLAT
msgnotback db	10,42,'in background.$        ' ;@@XLAT
msgnot300 db	10,42,'on PC-MOS 3.00.$       ' ;@@XLAT
msgsecur   db	10,5,'Sorry, no security access for this service.$       ' ;@@XLAT
msgrdis    db	10,5,'Sorry, this service has been disabled.$          ' ;@@XLAT

msgkmode db	10,5,'Current Keyboard mode is ' ;@@XLAT
kval	 db	'------ $'
kdis	 db	'  DIS.'
knodis	 db	'NODIS.'
msgkey	 db	12,5,'Enter new Mode N for NODIS or D for DIS$   ' ;@@XLAT

msgcurpri db	10,5,'Current Priority is ' ;@@XLAT
prival	  db	'x.$'
msggetpri db	11,5,'Enter new Priority : ' ;@@XLAT
gprival   db	' $'
msgaccept db	13,5,'Press <ENTER> to accept or <ESC> to abort.$           ' ;@@XLAT
cache_on  db	10,5,'Caching is currently ENABLED. $       ' ;@@XLAT
cache_off db	10,5,'Caching is currently DISABLED.$       ' ;@@XLAT
pam_on	  db	10,5,'Task switching for this task ENABLED. $      ';@@XLAT
pam_off   db	10,5,'Task switching for this task DISABLED.$      ';@@XLAT
msgcsel   db	11,5,'Enter E for ENABLE or D for DISABLE$     ' ;@@XLAT
msgatask  db	10,5,'Do you wish to add a background task (Y/N)$             ' ;@@XLAT
msgasize  db	11,5,'Enter new Task''s memory size : $          ' ;@@XLAT
msgaddok  db	12,5,'Task Successfully added$              ' ;@@XLAT
msgnomem  db	12,5,'Insufficient Memory to add Task$             ' ;@@XLAT
msgnosmp  db	12,5,'Insufficient SMP to add task$                ' ;@@XLAT
msgaerror db	12,5,'General Error in adding task$                ' ;@@XLAT
msgsmall  db	12,5,'Memory size to small for Task$               ' ;@@XLAT
msgslice  db	10,5,'Enter Task # ' ;@@XLAT
valslice  db	'   new Slice value : $       ' ;@@XLAT
badslice  db	11,5,'Invalid Slice (1 - 255)$         ' ;@@XLAT
okslice   db	11,5,'Slice successfully changed.                     $' ;@@XLAT
msgkill   db	10,5,'Do you wish to remove Monitor from memory (Y/N)$        ' ;@@XLAT
msgnokill db	11,5,'Sorry, Unable to remove Monitor from memory.$           ' ;@@XLAT

msgnum	  db	0		;  Y position for display number
numpos	  db	0		;  X position for display number
savenum   db	'   $'

savcache  db	?		; save cache value
savetask  dw	?		; save taskid for some of the functions
return	  db	?		; return to main screen value

taskdata  label byte		; task structure for add a task function
tasksize  dw	0		; task size
taskid	  dw	0		; id
taskclass db	0		; class
taskbat   dd	0		; batch file
other	  db	27 dup (0)

batfile   db	10 dup (0)

;   The following is a function table use in the pop up menu

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

	page
	
;---------------------------------------------------------------------------;
; This routine is the intercept routine for the BIOS keyboard interrupt     ;
; (16H).  It will simply check keys comming from the keyboard for the HOT-  ;
; KEY and if found will display a menu and allow the user to select spooler ;
; parameters.								    ;
;---------------------------------------------------------------------------;
	db	'SH'			; Use for Identification
kbentry		proc	near
	cmp	byte ptr cs:[remove],'Y'
	je	chkpass 		; remove monitor
	cmp	ah,1		; Get key or status?
	ja	chkpass		; No, pass it on
	or	ah,ah		; Get a key?
	jz	kbget			; Yes
	mov	byte ptr cs:funtype,1	; Tell my routine which fun
	pushf				; Simulate INT
	call	cs:dword ptr [okb]	; Call regular kb routine
	jz	nokeyrdy		; No key available
	pushf				; Save state of ZF
	call	ishot			; is it hot key
	je	doss
	popf				; Get ZF back
nokeyrdy:

farret	proc	far
	ret	2			; Return with flags
farret	endp

chkpass:
	jmp	cs:dword ptr [okb]  ; Continue with regular kb routine
kbget:
	mov	byte ptr cs:funtype,0	; Tell my routine which fun
	pushf
	pushf				; Simulate INT
	call	cs:dword ptr [okb]	; Call regular kb routine
	call	ishot			; is this hotkey
	jz	doss			; Yes
	popf
	iret

;
;   ISHOT - routine to determine if HotKey is use which is Cntrl-Space

ishot:
	cmp	ax,word ptr cs:[hotkey] ; Do they want SS menu?
	jnz	dontss			; Yes
	cmp	[SpecKeys],00h
	je	dontss
	push	ax
	call	GetSpec 		; get control keys
	cmp	al,[SpecKeys]
	pop	ax
dontss:
	ret

;------------------ hot key to bring up main window --------------;

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
	mov	ds,ax		; Set our data seg
	mov	es,ax
	cmp	byte ptr funtype,1	; Get status
	jne	noclr			; No, KB buffer OK
	xor	ah,ah			; Clear hotkey from buffer
	pushf
	call	dword ptr [okb]
noclr:
	mov	ah,0fh
	int	10h
	mov	[hcolor],HIGHMONO
	mov	[vaddr],0b000h
	cmp	al,07h
	je	popok
	mov	[hcolor],HIGHCOLOR
	mov	[vaddr],0b800h
	cmp	al,04h
	jb	popok
	mov	ax,0e07h
	int	10h
	jmp	short skippop
popok:
	cld
	xor	bh,bh		; Page 0
	mov	ah,3		; Read cursor position
	int	10H		;
	push	dx		; Save their position
	call	savescn		; Save their screen area
	call	doscreen
	call	restrscn	; Put their screen area back
	pop	dx		; 
	mov	ah,2		; Set cursor position
	xor	bh,bh		; Page 0
	int	10H		;

skippop:
	pop	es
	pop	ds
	pop	si
	pop	di
	pop	dx
	pop	cx
	pop	bx
	mov	ah,cs:funtype	; Do the call they asked for
jmp	kbentry

	page
;-------------------------------------------------------------------;
; DoScreen - This is the main procedure which call from within the  ;
; TSR based interupt routines. it is call once when the hot key is  ;
; detected. It will displayed the new screen and also control the   ;
; main action of the program.					    ;
;-------------------------------------------------------------------;

doscreen proc	near
;
;	 Display main screen
;
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
	 mov	byte ptr [msgm1],MAXTASKS+5	    ; Please note that this
	 lea	si,msgm1			    ; position is movable by
	 call	disp				    ; MAXTASK equate.
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
	 call	dotasks 			; display task information
	 call	getkey				; get a key
	 jc	doloop				; carry means time for update
	 cmp	al,0dh				; return
	 jne	notret
	 call	domenu
	 cmp	[doexit],'Y'
	 jne	doloop
	 jmp	dodone
notret:
	 cmp	ax,5100h			; is it pagedown
	 jne	notpgdn
dopgdn:
	 add	[taskpage],MAXTASKS		; adjust top of map
	 mov	[curtask],00h
	 mov	[lasttry],MAXTASKS		; force redraw
	 jmp	short doloop
notpgdn:
	 cmp	ax,4900h			; is it pageup
	 jne	notpgup
dopgup:
	 cmp	[taskpage],0			; are we at top
	 je	doloop
	 sub	[taskpage],MAXTASKS		; adjust top of map
	 mov	[curtask],00h
	 mov	[lasttry],MAXTASKS		; force redraw
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


;
;   The following for handle of pop up menu
;

domenu	 proc	near
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
	 push	word ptr [color]	    ; save main screen information
	 push	word ptr [rowtop]
	 push	word ptr [rowbot]
	 mov	al,[mcolor]
	 mov	[color],al
	 mov	[rowtop],MRT
	 mov	[coltop],MCT
	 mov	[rowbot],MRB
	 mov	[colbot],MCB
	 call	savemenu
magain:
;
;	display main menu
;
	 lea	si,mmsgtop
	 call	disp
	 mov	cx,MRB-MRT-1
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
;
;	This is the main loop within the menu
;

menuloop:
	 mov	ax,cs
	 mov    ds,ax
	 mov	es,ax	 
	 call	inkey		; get a key
	 cmp	 al,9
;
;	 TAB Key is use to switch between menu colors
;
	 jne	 menuntab
	 mov	 al,[mcolor]
mtabbad:
	 add	 al,10h
	 cmp	 al,10h
	 jb	 mtabok
	 cmp	 al,20h
	 jb	 mtabbad
	 cmp	 al,80h
	 jb	 mtabok
	 and	 al,0fh
mtabok:
	 mov	 [mcolor],al
	 mov	 [color],al
	 jmp	 magain
menuntab:
	 cmp	 al,27
	 jne	 menunesc
;
;	 ESC is use to return to application directly from menu option
;
	 mov	 [doexit],'Y'
	 jmp	 menudone
menunesc:
	 cmp	 ax,3b00h
	 jb	 notfkeys
	 cmp	 ax,4400h
	 ja	 notfkeys
	 mov	 bl,ah
	 sub	 bl,3bh
	 xor	 bh,bh
	 shl	 bx,1
	 mov	 [return],'N'
	 call	 word ptr [bx+functions]
	 cmp	 [return],'Y'		; wish to return to main screen
	 je	 menudone
	 jmp	 menuloop
notfkeys:
	 cmp	 al,0dh 		; return to main status screen
	 jne	 menuloop
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
domenu	 endp

;---------------------------------------------------------------;
; Function F1  - Remove a task					;
;---------------------------------------------------------------;

funf1	 proc	near
	 call	clrmenu
	 push	ds
	 push	es
	 call	gettcb
	 or	ax,ax		    ; don't do it if task zero
	 jz	f1zero
	 call	ChkSecurity	    ; check security access
	 jc	EDone
	 call	chkback 	    ; check if trying to do a background
	 jc	notyes
	 assume es:tcb
	 mov	ax,es
	 cmp	ax,[tcbseg]	    ; check if current task
	 je	f1term
	 mov	ax,[tcbid]	    ; get ID for Task
	 lea	bx,rtaskval+1
	 mov	cx,2
	 call	bintodec
	 lea	si,msgrtask
	 call	disp
	 call	getyn
	 cmp	al,'Y'
	 jne	notyes
	 push	 ax
	 push	 ds
	 push	 es
	 Service RemTASK	    ; call mos to remove the task
	 pop	 es
	 pop	 ds
	 pop	 ax
	 mov	 [return],'Y'	    ; return to main screen
	 mov	 [curtask],0
	 jmp	 short notyes
f1term:
	 mov	si,offset msgnotcur   ; sorry you can't remove current task
	 jmp	short ENotyes 
f1zero:
	 mov	si,offset msgnotzero  ; sorry you can't remove task 0
Enotyes:
	 push	si
	 mov	si,offset msgnot
	 call	disp
	 pop	si
	 call	disp
notyes:
	 lea	si,presskey
	 call	disp
	 call	inkey
EDone:
	 call	clrmenu
	 pop	es
	 pop	ds
	 ret
funf1	 endp

;---------------------------------------------------------------;
; Function F2  - Restart a task 				;
;---------------------------------------------------------------;


funf2	proc	near
	call   clrmenu
	push	es

if	DO_RESTART eq 0
	lea	si,msgnot
else	
	cmp    [on300],'Y'	; 3.00 mos
	je     f2zero
	call   gettcb
	or     ax,ax
 	jz     f2zero		   ; don't do if task zero
	call   ChkSecurity
	jc     F2skip
 	call   chkback
 	jc     f2done
 	assume es:tcb
 	lea    si,msgrdis
 	cmp    [tcbreboot],00h	   ; has reboot been disable	
 	jne    f2exit		
  	lea    bx,rstaskval+1
  	mov    cx,2		  
	call   bintodec
 	lea    si,msgrestart
	call   disp
	call   getyn
	cmp    al,'Y'
	jne    f2done
	cli
	cmp    [tcbcamon],0ffh
	je     NoRest
	mov    [tcbcamon],0ffh
	les    bx,cs:[scbptr]
	assume es:newscb
	inc    [bx+scbrstrtc]			; restarted.
NoRest:
	sti
	jmp    short f2done

f2zero:
	lea    si,msgnotzero
	cmp    [on300],'Y'
	jne    f2not30
	lea    si,msgnot300
f2not30:
endif
F2Eexit:
	push	si
	mov	si,offset msgnot
	call	disp
	pop	si
f2exit:
	call   disp
f2done:
	lea    si,presskey
	call   disp
	call   inkey
F2skip:
	pop    es
	call   clrmenu
	ret
funf2	endp

;---------------------------------------------------------------;
; Function F3  -  Add a background task 			;
;---------------------------------------------------------------;


funf3	proc	near
	call	clrmenu
	cmp    [on300],'Y'
	jne    f3not30
	lea    si,msgnot
	call   disp
	lea    si,msgnot300
	call   disp
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
;
;   Init task area
;
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
	Service AddTASK
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
	lea    si,presskey
	call   disp
	call   inkey
	call   clrmenu
	ret
funf3	endp

;---------------------------------------------------------------;
; Function F4  - change task's priority                         ;
;---------------------------------------------------------------;


funf4	proc	near
	call	clrmenu
	push	bx
	push	es
	call	gettcb
	call	ChkSecurity	
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
funf4	endp

;---------------------------------------------------------------;
; Function F5  -  Change task's slice                           ;
;---------------------------------------------------------------;


funf5	proc	near
	call	clrmenu
	push    es
	call    gettcb
	assume es:tcb
	mov     [savetask],es
	pop     es
	call	ChkSecurity
	jc	f5end	
	lea     bx,valslice+1
	mov     cx,2
	call    bintodec
	lea    	si,msgslice
	call   	disp
	mov    	[msgnum],10
	mov    	[numpos],40
	call   	getval
	or     	ax,ax
	jz     	f5zero
	or     	ah,ah
	jz     	f5set
f5zero:
	mov    	si,offset badslice
	call   	disp
	jmp    	short f5done
f5set:
	push   	es
	mov    	es,[savetask]
	assume 	es:tcb
	mov    	[tcbslice],al
	pop    	es
	mov    	si,offset okslice
	call   	disp
f5done:
	mov    	si,offset presskey
	call   	disp
	call   	inkey
f5end:
	call   	clrmenu
	ret
funf5	endp

;---------------------------------------------------------------;
; Function F6  -  Change task's keyboard mode                   ;
;---------------------------------------------------------------;


funf6	proc	near
	call	clrmenu
	push	es
	call	gettcb
	call	ChkSecurity	
	jc	f6done		
	assume es:tcb
f6loop:
	push   bx
	mov    ax,word ptr [knodis]
	mov    si,word ptr [knodis+2]
	mov    bx,word ptr [knodis+4]
	test   byte ptr [tcbloop],1
	jz     f6a
	mov    ax,word ptr [kdis]
	mov    si,word ptr [kdis+2]
	mov    bx,word ptr [kdis+4]
f6a:
	mov    word ptr [kval],ax
	mov    word ptr [kval+2],si
	mov    word ptr [kval+4],bx	
	pop    bx
	lea    si,msgkmode
	call   disp
	lea    si,msgkey
	call   disp
	lea    si,msgret
	call   disp
f6err:
	call   inkey
	cmp    al,0dh
	je     f6done
	and    al,0dfh
	cmp    al,DisOpt
	je     f6dis
	cmp    al,NoDisOpt
	jne    f6err
	and    byte ptr [tcbloop], NOT 1	; indicate no dis mode
	jmp    f6loop
f6dis:
	or    byte ptr [tcbloop],1		; indicate disable mode
	jmp   f6loop
f6done:
	pop    es
	call   clrmenu
	ret
funf6	endp

;---------------------------------------------------------------;
; Function F7  - Change system caching				;
;---------------------------------------------------------------;


funf7	proc	near
	call	clrmenu
	push	bx
	push	es
	les	bx,[scbptr]
	assume  es:newscb
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
	cmp	al,EnVal
	jne	notena
	mov	al,'Y'
	jmp	short f7loop
notena:
	cmp	al,DisVal
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
funf7	endp

;---------------------------------------------------------------;
; Function F8  - Change pam switching				;
;---------------------------------------------------------------;


funf8	proc	near
	call	clrmenu
	push	es
	call	GetTCB
	call	ChkSecurity	
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
	cmp	al,EnVal
	jne	notena2
	mov	al,'Y'
	jmp	short f8loop
notena2:
	cmp	al,DisVal
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
funf8	endp

;---------------------------------------------------------------;
; Function F9  - Change hot key 				;
;---------------------------------------------------------------;


funf9	 proc	near
	 call	clrmenu
	 lea	si,hkey1
	 call	disp
	 call	inkey
	 mov	cx,ax
	 call	GetSpec
	 mov	[savcache],al
	 lea	si,hkey2
	 call	disp
	 call	inkey
	 cmp	ax,cx
	 jne	f9bad
	 call	GetSpec
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
	 mov	[SpecKeys],al
	 lea	si,hkeyok
	 call	disp
f9end:
	 lea	si,presskey
	 call	disp
	 call	inkey
	 call	clrmenu
	 ret
funf9	 endp

;---------------------------------------------------------------;
; Function F10 - Remove monitor from Memory			;
;---------------------------------------------------------------;

	public	funf10
funf10	proc	near
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
;
;	Locate start of TSR memory
;
	push	es
	les	bx,DVarPTR
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
	mov	ax,word ptr cs:[okb]
	mov	word ptr es:[16h*4],ax
	mov	ax,word ptr cs:[okb+2]
	mov	word ptr es:[16h*4+2],ax
	mov	es,di
	cli
	mov	word ptr es:[1],0	; Mark as free
	mov	es,si
	mov	word ptr es:[1],0	; Mark as free
	pop	es
	sti
	pop	es
	pop	ds
	mov	[doexit],'Y'
	mov	[return],'Y'
	mov	[remove],'Y'
	ret
f10done:
	lea    si,presskey
	call   disp
	call   inkey
	call   clrmenu
	pop    ds
	pop    es
	ret
funf10	endp

GetSpec proc	near
	push	es
	xor	ax,ax
	mov	es,ax
	mov	al,byte ptr es:[417h]
	and	al,0fh
	pop	es
	ret
GetSpec endp

;
; Check Security Access, if current task has access or not
; Entry:
;	AX -> task to perform operation on
; Returns:
;	NO CARRY if task can access
; or	CARRY if task can't have access and DX has message
;
ChkSecurity proc	near
	push	ax
	push	bx
	mov	bx,ax
	Service ChkSec
	pop	bx
	cmp	ax,1	 	; if invalid function then assume it is ok
	je	CSecOk		; so that it will work on 4.00
	cmp	ax,5
	je	CSecError 	; > 1 then this means error (5)
CSecOk:
	pop	ax
	clc
	ret
CSecError:
	pop	ax
	mov	si,offset msgsecur
	call	disp
	mov     si,offset presskey
	call    disp
	call    inkey
	stc	
	ret		
ChkSecurity endp

;
;	ChkBack - check if back ground
;
ChkBack proc	near
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
ChkBack endp


;
; GetTCB this routine returns the currently selected TCB
;

gettcb	proc	near
	mov    bl,[curtask]
	xor    bh,bh
	shl    bx,1
	shl    bx,1
	mov    es,[bx+tasksav]	    ; get tcb address from main array
	assume es:tcb
	mov    ax,[tcbid]
	xor    dx,dx
	ret
gettcb	endp

;
;	This routine returns a key from the keyboard
;

inkey	 proc	near
	 push	 cx
	 push	 es
	 mov	 es,cs:[tcbseg]
	 assume  es:tcb
	 mov	 cl,[tcbloop]
	 push	 cx
	 or	 [tcbloop],1

	 xor	 ah,ah
	 pushf
	 call	 dword ptr cs:[okb]	 ; get the keyboard input

	 pop	 cx
	 mov	 [tcbloop],cl

	 pop	 es
	 assume  es:nothing
	 pop	 cx
	 ret
inkey	 endp

;
;	Return 3 digit number from user
;
GetVal	proc	near
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
GetVal	endp

dispnum proc	near
	push	si
	lea	si,msgnum
	call	disp
	pop	si
	ret
dispnum endp

;
;	This routine return either an Y or N
;

getyn	proc	near
	call	inkey
	mov	ah,'Y'
	and	al,0dfh
	cmp	al,YesVal
	je	getynok
	mov	ah,'N'	
	cmp	al,NoVal
	jne	getyn
getynok:
	mov	al,ah
	ret
getyn	endp

;
;	This routine clears the menu options area of the screen
;

clrmenu  proc	near
	 mov	cx,4
	 mov	byte ptr [mmsgm0],10
clrloop:
	 lea	si,mmsgm0
	 call	disp
	 inc	byte ptr [mmsgm0]
	 loop	clrloop
	 ret
clrmenu  endp

;-------------------------------------------------------------------;
; DoTasks - This procedure handles the job of displaying the MOS MAP;
; style display on the screen					    ;
;-------------------------------------------------------------------;

dotasks  proc	near
;
;	 Clear out task save pointers
;
	 push	cs
	 pop	es
	 cli
	 lea	di,tasksav
	 mov	cx,10
	 xor	ax,ax
	 rep	stosw
;
;	 setup for main loop
;
	 les	bx,[scbptr]
	 assume es:newscb
	 call	getstart		    ; get start task
	 assume es:tcb
	 xor	cx,cx
	 xor	si,si
	 mov	dh,5
dtloop:
	 cmp	byte ptr [tcbtype],'T'	 ; is this a valid tcb task
	 jne	dtend
	 mov	byte ptr [msgmap],dh
	 mov	word ptr [si+tasksav],es ; save tcb into task save pointer
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
	 cmp	cl,MAXTASKS		; have we hit max displayed tasks yet
	 jae	dtend
	 mov	ax,es
	 or	ax,ax
	 jnz	dtloop
;
;	all done, now clear out any possiabable remaining entries from
;	last displays
;
dtend:
	 cmp	cl,MAXTASKS		; already display max, then skip
	 ja	dtend4
	 cmp	cl,[lasttry]		; above or equal to last time, skio
	 jae	dtend3
;
;	we must fill out remaining entries with blanks
;
	 push	cx
dtend2:
	 cmp	cl,[lasttry]		 ; done yet
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
	 mov	[lasttry],cl		    ; save count for next time
dtend4:
	 ret
dotasks  endp

	page
;-------------------------------------------------------------------;
; GetStart - get starting TCB base on user request of page up and   ;
; page downs. It takes account of removed tasks and make sure it    ;
; its only valid for tasks that are on the system.		    ;
;-------------------------------------------------------------------;


getstart proc	near
	 call	chkstart		; request task start within limits
	 jnc	getok			; ok continue
	 sub	[taskpage],MAXTASKS	; no, adjust count downward until ok
	 jmp	short getstart
getok:
	 mov	es,ax
	 ret
;
;	count up tasks until 1 of the following
;	    1.	found requested task at [taskpage] counts
;	    2.	end of list return error with carry set
;
chkstart:
	 assume es:newscb
	 push	es
	 mov	es,[bx+scbtcbpf]	; get first task on system
	 push	cx
	 xor	cx,cx
	 mov	ax,es
	 assume es:tcb
chkloop:
	 cmp	byte ptr [tcbtype],'T'	 ; valid task
	 jne	chkbad
	 cmp	cx,[taskpage]		 ; found our task yet
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
getstart endp

	page
;-------------------------------------------------------------------;
; MakeTask - make task information for display			    ;
;	ES -> TCB						    ;
;-------------------------------------------------------------------;

maketask proc	near
	push   es
	mov    ax,2020h
	mov    cx,76/2
	push   cs
	pop    es
	lea    di,maparea
	rep    stosw
	pop    es
	assume es:tcb
	mov    ax,es:[tcbid]	       ; tcb id #
	xor	dx,dx
	mov	cx,2
	mov	bx,OFFSET maparea+1
	cmp	ax,[curid]
	jne	notcurid
	mov	byte ptr [bx+1],'*'
notcurid:
	call	bintodec
	mov	ax,es:[tcbendad]		; tcb size
	sub	ax,es:[tcbbegad]
	mov	cx,6
	shr	ax,cl
	xor	dx,dx
	mov	cx,3
	mov	bx,OFFSET maparea+7
	push	bx
	call	bintodec
	pop	bx
	mov	byte ptr [bx+1],'K'
	mov	cx,3
	mov	di,OFFSET maparea+11
	mov	byte ptr cs:[di+3],' '
	mov	si,OFFSET msgcga
	test	[tcbvideo],16	; hg1 on system
	jnz	mapv01
	test	[tcbvideo],32	; hg2 on system
	jnz	mapv02
	test	[tcbvideo],4		; ega on system
	jnz	mapv00
	test	[tcbvideo],8		; vga on system
	jz	mapv0
	mov	si,OFFSET msgvga	; idicate vga
	jmp	short mapv0
mapv00:
	mov	si,OFFSET msgega
	jmp	short mapv0
mapv01:
	mov	si,OFFSET msghg1
	jmp	mapvend
mapv02:
	mov	si,OFFSET msghg2
	jmp	mapvend
mapv0:
	mov	cx,3
	mov	al,es:[tcbmode]
	cmp	al,7
	jne	mapv1
	mov	byte ptr cs:[di+3],'O'		; o for mon(o)
	mov	si,OFFSET msgmon
	jmp	short mapvend
mapv1:
	cmp	es:[tcbrows],25
	jbe	mapv11
	mov	si,OFFSET msge43
	jmp	short mapvend
mapv11:
	cmp	al,1
	ja	mapvend
	cmp	si,offset msgvga
	je	mapv2v
	cmp	si,offset msgega
	je	mapv2
	mov	si,OFFSET msgc40
	jmp	short mapvend
mapv2v:
	mov	si,OFFSET msgv40
	jmp	short mapvend
mapv2:
	mov	si,OFFSET msge40
mapvend:
	call	movelong

	cmp	byte ptr es:[tcbuser],0
	je	nouser
	push	ds
	lea	si,es:[tcbuser] 	; tcb user id
	mov	di,OFFSET maparea+18
	mov	cx,4
	push	es
	pop	ds
	call	movelong
	pop	ds

public nouser
nouser:
	push	ds				; tcb program name
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
	mov	ax,es:[tcbport]      ; tcb port #
	cmp	ax,-1
	je	portchk
	and	ax,07fffh		; mask off high bit for ELTERM
	or	ax,ax
	jz	portchka
	test	es:[tcbvram],8
	jz	portcont
	push	ax
	push	bx
	push	es
	mov	ah,4
	xor	bx,bx
	int	SERVICES
	mov	al,es:[tcbvram]
	test	al,4		       ; for SunRiver, must counteract increment
	jnz	skvna
	test	al,8		       ; for vna, must counteract increment
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
	xor	bx,bx		; get first tcb
	mov	ah,4
	int	SERVICES
	test	es:[tcbvram],8
	pop	bx
	pop	ax
	pop	es
	jnz	portchk
	call	cnvt_port		; convert the port number
	call	na_baud			; and write n/a for buad
	jmp	portdone
portchk:
	cmp	word ptr es:[tcbbaud],0
	jne	portcont
	cmp	word ptr es:[tcbbaud+2],0
	jne	portcont
	mov	si,OFFSET namsg
	mov	di,OFFSET maparea+38
	mov	cx,3
	call	movelong
vna_baud:
	call	na_baud
	jmp	short portdone
portcont:
	call	cnvt_port
	test	word ptr es:[tcbvram],8		; for vna, use n/a for baud
	jnz	vna_baud
	mov	bx,OFFSET maparea+47	   ; tcb baud rate
	mov	cx,6
	mov	ax,word ptr es:[tcbbaud]
	mov	dx,word ptr es:[tcbbaud+2]
	call	bintodec
portdone:
	mov	bx,OFFSET maparea+51	    ; tcb priority
	mov	al,es:[tcbpri]
	shr	al,1			;tcb priority = priority * 2
	and	ax,000fh
	mov	cx,2
	xor	dx,dx
	call	bintodec
	mov	bx,OFFSET maparea+56	    ; tcb time slice
	mov	al,es:[tcbslice]
	and	ax,00ffh
	mov	cx,3
	xor	dx,dx
	call	bintodec
	xor	cx,cx		    ; tcb open files
	push	es
	mov	ax,es:[tcbtfbpf]
	assume	es:tfb
	mov	es,ax
fileloop:
	cmp	es:[tfbtype],'F'
	jne	filedone
	mov	ax,[tfbntcb]
	or	ax,ax
	jz	filedone
	inc	cx
	mov	es,ax
	jmp	short fileloop
filedone:
	mov	bx,OFFSET maparea+62
	xor	dx,dx
	mov	ax,cx
	mov	cx,5
	call	bintodec
	pop	es
	assume	es:tcb
	mov	di,OFFSET maparea+66	    ; tcb wait status
	mov	si,OFFSET hold
	mov	cx,4
	test	es:[tcbega],4	     ; test for state-pam hold
	jnz	mapdisp1
	mov	al,es:[tcbwait]
	mov	si,OFFSET active
	or	al,al
	jz	mapdisp1
	mov	si,OFFSET waitmsg
mapdisp1:
	call	movelong
	mov	cx,2
	mov	di,OFFSET maparea+71
	mov	si,OFFSET msgndfg
	test	es:[tcbloop],1
	jz	mapdisp2
	mov	si,OFFSET msgdsfg
mapdisp2:
	call	movelong
	mov	ax,es:[tcbtcbpn]
	mov	es,ax
	ret

na_baud:
	mov	si,OFFSET namsg
	mov	di,OFFSET maparea+45
	mov	cx,3
	call	movelong
	ret

cnvt_port:
	inc	ax
	xor	dx,dx
	mov	cx,2
	mov	bx,OFFSET maparea+40
	call	bintodec
	ret
maketask endp

;------------------------- move routine -----------------------------;
movelong proc
	push  es
	cld
	push  cs
	pop   es
	rep   movsb
	pop   es
	ret
movelong endp

	page
;-------------------------------------------------------------------;
; GetKey - Inteligent Input routine which allows for occasion	    ;
; interuptions because we have detected a change in the tcbs.	    ;
;-------------------------------------------------------------------;


getkey	proc	near
;
;	setup for main routine
;
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
;
	call	dosums			; compute checksums of tcbs
getkey0:
	mov	ah,1
	pushf
	call	dword ptr cs:[okb]	; check if key is ready
	pushf
	call	chktasks		; check if task is ready for update
	jc	getkey1
	popf
	jz	getkey0
	xor	ah,ah
	pushf
	call	dword ptr cs:[okb]	; get the keyboard input
	clc
	jmp	short getkey2
getkey1:
	popf
	stc
getkey2:
;
;	place keyboard mode back as normal
;
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
getkey	endp

	page
;-------------------------------------------------------------------;
; DoSums - computes checksum of displayed TCBS			    ;
;-------------------------------------------------------------------;

dosums	proc	near
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
	jmp	short	dsloop
dsend:
	ret
dosums	endp

;-------------------------------------------------------------------;
; CkSums - check checksums of display tcbs  and return carry set if ;
; any of them are different					    ;
;-------------------------------------------------------------------;


cksums	proc	near
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
cksums	endp

;-------------------------------------------------------------------;
; GetSum - Compute checksum of particular TCB			    ;
;-------------------------------------------------------------------;

	assume	es:tcb
getsum	proc	near
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
getsum	endp

;-------------------------------------------------------------------;
; ChkTasks - check to see if task should be awaken for update	    ;
;-------------------------------------------------------------------;

chktasks proc	near
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

;-------------------------------------------------------------------;
;-------------------------------------------------------------------;

writchar proc	near
	xor	bh,bh		;Page 0
	mov	bl,[color]
	mov	ah,9		;Write char/attr
	mov	cx,1		;One char
	int	10H
	inc	dl		;Next col
	mov	ah,2
	xor	bh,bh
	int	10H		;Set new position
	ret
writchar endp

kbentry	 endp

;---------------------------------------------------------------------------;
; This subroutine will save the screen area defined by DX and CX            ;
;---------------------------------------------------------------------------;
savemenu proc	near
	lea	di,menudata
	jmp	short saveentry
savescn:
	lea	di,scndata	; Put their screen here
saveentry:
	mov	dh,rowtop	; Row upper right
	mov	dl,coltop	; Col
	cld
	push	si
	push	ds
	mov	ds,cs:[vaddr]
	assume	ds:nothing
	CVidOff si
saveline:
	movsw
	inc	dl		; Next column position
	cmp	dl,colbot	; End of line yet?
	jna	saveline	; Do the whole line
	mov	dl,coltop	; Reset to start of next line
	inc	dh		; Next row
	CVidOff si
	cmp	dh,rowbot	; Last row yet?
	jna	saveline	; Do all rows
	pop	ds
	pop	si
	ret			; That's it all saved, back to you...

savemenu endp

;---------------------------------------------------------------------------;
restrmenu proc	 near
	lea	si,menudata
	jmp	short restrentry
restrscn:
	lea	si,scndata	; Get their screen from here
restrentry:
	push	cs
	pop	ds
	mov	dh,rowtop	; Row upper right
	mov	dl,coltop	; Col
	cld
	push	di
	push	es
	mov	es,[vaddr]
	CVidOff di
restline:
	movsw			; Get char/attr from save area
	inc	dl		; Next column position
	cmp	dl,colbot	; End of line yet?
	jna	restline	; Do the whole line
	mov	dl,coltop	; Reset to start of next line
	inc	dh		; Next row
	CVidOff di
	cmp	dh,rowbot	; Last row yet?
	jna	restline	; Do all rows
	pop	es
	pop	di
	ret			; That's it all saved, back to you...

restrmenu endp


CvidDX	proc	near
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
CVidDX	endp



;---------------------------------------------------------------------------;
disp	proc	near
 	cld
	mov	dh,rowtop	; Start at top left of screen
	add	dh,[si]		; Calc starting point (row)
	inc	si		; Point to col
	mov	dl,coltop	;
	add	dl,[si] 	; Calc starting point (col)
	push	es
	push	di
	CVidOff di
	mov	es,[vaddr]
	inc	si		; Point to start of string
	xor	bh,bh
	mov	bl,[color]	; Color
displp:
	lodsb
	cmp	al,'$'		; End of string?
	je	dispend 	;
	mov	ah,bl
	stosw
	inc	dl		; Next column
	jmp	displp		; Do the whole string
dispend:
	inc	dl		; Next column
	mov	ah,2		; Set cursor pos.
	int	10H		;
	pop	di
	pop	es
	ret
disp	endp

;--------------------- binary-to-decimal routine --------------------;
bintodec proc
	push  cx
btdloop1:
	div   cs:[wordten]          ; dx:ax is source integer
	add   dl,'0'		    ; cx is length of target
	mov   [bx],dl		    ; bx is end of target
	dec   bx
	xor   dx,dx
	loop  btdloop1
	pop   cx
btdloop2:
	inc   bx
	dec   cx
	jz    btdret
	cmp   byte ptr [bx],'0'
	jne   btdret
	mov   byte ptr [bx],' '
	jmp   btdloop2
btdret:
	ret
bintodec endp


	assume ds:mainseg
;------------------- binary-to-hexadecimal routine ------------------;
bintohex proc
	push  si
	mov   dl,4
bthloop1:
	mov   si,ax
	and   si,000fh
	mov   cl,[hextable+si]
	mov   [bx],cl
	mov   cl,4
	shr   ax,cl
	dec   bx
	dec   dl
	jg    bthloop1
	pop   si
	cmp   [cleanfg],'Y'
	je    clean
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

endres2	label	byte		 ; End of resident routines

;----------------------- TEMPORARY WORK SPACE -----------------------;


	subttl	Initilization - not retained in memory
        page

;--------------------------------------------------------------------;
;                         USER INTERFACE LOGIC                       ;
;--------------------------------------------------------------------;

msginstall db	13,10,'PC-MOS System Monitor v4.11 Installed.        ',13,10,'$' ;@@XLAT
msgactive  db	'To Activate Monitor Press Ctrl-Space             ',13,10,'$' ;@@XLAT
msgalready db	13,10,'PC-MOS System Monitor v4.11 already Installed.       ' ;@@XLAT
	   db	13,10,'$'
msgtsl	   db	'(c) Copyright 1989, 1990 The Software Link, Incorporated.',13,10,'$' ;@@XLAT

	even
version label   near
        include version.inc

badmos	db	13,10, 'This program requires atleast PC-MOS/386 3.00' ;@@XLAT
	db	13,10,'$'



	 assume ds:nothing
begin	label near
;
;       Routine to check mos version
;
	mov	ah, 30h
	int	21h
	push	ax
        mov     ah, 30h
        mov     bx, ax
        mov     cx, ax
        mov     dx, ax
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
        lea     dx, badmos
        mov     ah, 9
        int     21h
        mov     ax, 4c01h
        int     21h

mosok   label   near
;
;	Get Video address
;
	mov	ah,15
	int	10h
	cmp	al,7
	jne	notmono
	mov	[vaddr],0b000h
	mov	[hcolor],HIGHMONO
notmono:
;
;	test to see if monitor is already installed
;
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
	mov	word ptr [DVarPtr],bx
	mov	word ptr [DVarPtr+2],es

;
;	Save pointer to SCB and current tasks TCB and TCBID for current task
;
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
;
; Set the BIOS keyboard interrupt vector and exit with routines resident  
;	
	xor	ax,ax
	mov	es,ax
	assume	es:nothing

	mov	ax,es:[SERVICES*4]
	mov	bx,es:[SERVICES*4+2]
	cmp	[on300],'Y'
	jne	not38ser
	mov	ax,es:[38h*4]
	mov	bx,es:[38h*4+2]
not38ser:
	mov	word ptr [savservice],ax
	mov	word ptr [savservice+2],bx

	mov	ax,es:[kbint]	; Get offset
	mov	okb,ax		; Save
	mov	ax,es:[kbint+2]	; Get seg
	mov	okb+2,ax	; Save
	
	cli
	mov	es:[kbint],offset kbentry
	mov	es:[kbint+2],cs	; New seg
	sti

	lea   dx,msginstall
	mov   ah,9
	int   21h
	lea   dx,msgtsl
	mov   ah,9
	int   21h
	lea   dx,msgactive
	mov   ah,9
	int   21h
	lea   dx,endres2	; terminate & stay resident
        int   27h

mainseg  ends
         end   start


