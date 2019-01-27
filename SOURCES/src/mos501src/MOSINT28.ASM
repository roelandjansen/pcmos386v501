	include page.inc
	title	MOSINT28 - INT 28 and InDos routines (TSR Support)

;-----------------------------------------------------------------------;
;									;
;		      Development Specification 			;
;									;
;									;
; Program Name: $$MOS.COM		 Assigned to: Stewart Hyde	;
; Module Name:	MOSINT28		 Assign Date: 10/05/88		;
; Entry Points: MOSINT28		 Completed:   10/05/88		;
; Entry From:	MOSDDCON for INT 28 and approptiate InMOS locations	;
; Entry Method: CALL							;
; Purpose:	Provides PC-MOS/386 TSR usage routines			;
; Refer To:								;
; Last Update:	01/26/89						;
;									;
; This module is intended to be MOS source which provides support for	;
; TSR usaged under PC-MOS/386.	The following is a brief discription of ;
; the current understanding of how dos handlers TSR's                   ;
;									;
; INT 28 Handler:							;
; --------------------------------------------------------------------- ;
;	The INT 28 handler is call when system is waiting for Input,	;
; this indicates that the OS is not busy. Also under my current under-	;
; standing of INT 28 handling, INT 28 will only be issue for during	;
; Input calls of functions <= Function 0Ch.  This is becuase DOS uses	;
; a different stack on lower level functions.				;
;									;
; The following is sample code for which most INT 28 handlers would look;
; like: 								;
;									;
;	INT28:								;
;		pushf							;
;		call	dword ptr cs:[old28]				;
;	;								;
;	;	handler application's INT 28 handling.                  ;
;	;								;
;		iret							;
;									;
; InDOS Flag handling							;
; --------------------------------------------------------------------- ;
; InDOS flag is use to indicated that OS is busy or not.  The InDOS flag;
; is increment when inside the OS and when OS exits back to application ;
; the InDOS flag is then decrement.  This flag can be access by function;
; 34.									;
;-----------------------------------------------------------------------;
; SAH 10/13/88	If SCBCRIT is non-zero (I.E inside critical error) don't;
;		Issue INT 28						;
;-----------------------------------------------------------------------;
; SAH 01/26/89	Added necessary efficiencys to MOSINT28 when apps that	;
;		intercept INT 28 and use new generic mouse interface	;
;		($MOUSE.SYS) are installed on system.			;
;-----------------------------------------------------------------------;
; mjs 04/06/89	modified mosfun34 to not clear AX upon return.		;
; ptr 174	QuickBasic's printer error handler was counting on the  ;
;		exit AH being the same as the entry AH. 		;
;-----------------------------------------------------------------------;
; SAH 05/01/89	Corrected MOSINT28 for conditions where mouse driver is ;
;		not installed and INT 28 is issue (IE Novell, in this	;
;		case) This was cause invalid serial ports to be polled	;
;		and was corrected by not polling serial ports unless	;
;		mouse driver is being used.				;
;-----------------------------------------------------------------------;
; SAH 06/15/89	Remove call to userpoll, which is not need since	;
;		mossaver call will perform a userpoll.			;
;-----------------------------------------------------------------------;
; SAH 06/22/89	Improve mice efficency and coded for new mouse buffers	;
;-----------------------------------------------------------------------;
.xlist

	include GROUP.INC
	include options.inc
	include MOSREGS.INC

tcb	segment at 1234h
	include MOSTCB.INC	; TCB definition
tcb	ends

gdata	segment word public 'data'
	include MOSSCBEX.INC	; specify all SCB items as external
	extrn	inTSL:byte,irqwflag:byte

gdata	ends
.list

irq	segment byte public 'data'
	extrn	irqstart:byte, irqend:byte

	dw	28h*4		; offset for this interupt
public	i28old
i28old	dd	?		; save prior value
	dw	0		; we don't save changes, we leave them alone
	dw	mos:mosint28	; initial value here
	dw	0		; don't change back if application changes it

irq	ends

poll	segment byte public 'data'
	extrn	pollstart:byte, pollend:byte
poll	ends

ddt	segment word public 'code2'
ddt	ends

	page
mosseg	segment word public 'code1'
	assume	cs:mos,ds:grp,es:nothing,ss:tcb
	public	$$$MOS28
$$$MOS28 label	byte

	extrn	mosend:byte, sbios:word
	extrn	suspend:near, tsl:near, switchif:near
	extrn	egaon:near, egaoff:near, regrab9_data:near
	extrn	getkeys:near, regrab8_data:byte, grab_back:near
	extrn	mossaver:near, mosrestore:near

	public	DecINMOS, IncINMOS, RstINMOS, mosint28, testmos28
	public	mosfun34

	subttl	INT 28 Handling procedure
	page
;-----------------------------------------------------------------------;
; The following are procedures for handling of MOS INT 28 handling.	;
; INT 28 should only be call from console INPUT routine when MOS is	;
; waiting for a key. This is currently place in MOSDDCON routine before ;
; INT 16h function 00, There is a test for an Application INT 28 handler;
; if there is one, loop of Safe28 (our method of calling the application;
; INT 28 handler follow by INT 16 function 1 looping if no key was press;
;									;
; Also inside our INT 28 handler, which by word of the trade the	;
; application should call original INT 28 handler inside their int 28	;
; handler, is special efficency handling of INT 28 so that TSR or others;
; (I.E. Windows and Norvell).						;
;									;
; When applications INT 28 handler is called, We need to be prepare for ;
; the TSR application to reenter MOS.					;
;									;
; Procedures Define for INT 28 handling are:				;
;	MOSINT28	-	Our INT 28 routine			;
;	TestMOS28	-	Test to see if MOSINT28 handler is	;
;				INT 28 handler for task 		;
;	Do28		-	Issue the INT 28 call			;
;	Safe28		-	Determine if it is safe to call INT 28	;
;				if so, call INT 28			;
;									;
; TCBSAFE28 - indicates if INT 28 call should be made, IE for function	;
;		<= 0C.							;
; TCBTSRFLG - indicates if efficiency waiting inside mosint28 should be ;
;		done.							;
; TCB28TIMER - is a counter of INT 28 issue before INT 28 application	;
;		should be suspended.					;
; TCB28CNT - this is a nesting counter for handling of InMOS flag.	;
; TCBMTIMER - this is a timer which is use to improve the efficency of	;
;	      applications which intercept INT 28 and use generic mouse ;
;	      interface. It indicate time sence has mouse activity.	;
; TCBMPORT - this is the port which generic mouse interface uses.	;
;-----------------------------------------------------------------------;
	page
	subttl	mosint28 - default INT 28 handler 
;-----------------------------------------------------------------------;
; MOSINT28 - Default INT 28 handler - used only for detection		;
;									;
; Updated: 09/24/88 SAH to improve overall efficency if windows is	;
;	   sitting idea on system.					;
; Updated: 01/26/89 SAH to improve mouse and overall system efficency if;
;	   with apps like windows with Generic Mouse Interface being	;
;	   Used (I.E $mouse.sys)					;
; Updated: 05/01/89 SAH correct for condition with Novell.		;
; Updated: 06/22/89 SAH to improve mouse efficency and work correctly	;
;	   with new buffer techniques which were created earlier.	;
;-----------------------------------------------------------------------;
	extrn	mosint38:near

MOSINT28:
	call	mossaver
	assume	ds:grp,ss:tcb
	cmp	byte ptr [tcbtsrflg],'Y'	; has TSR flag been set
	je	mint28c 			; yes skip wait
	inc	byte ptr [tcb28timer]		; increment efficiency
	cmp	byte ptr [tcb28timer],3 	; if lest than 3 call
	jb	mint28c 			; skip wait
	mov	word ptr [tcb28timer],0 	; reset efficiency
;
;	The following is code which is include to improved the
;	efficiency of MS-Windows (and Novell, TSR's) when mouse
;	support has been include.
;
	mov	al,03h				; set for keys and time
	cmp	byte ptr [tcbmouse],'Y' 	; generic mouse installed
	jne	mint28b
	mov	ax,[scbtimer]
	sub	ax,[tcbmtimer]
	cmp	ax,18*3 			; check time lapse since
	jbe	mint28c 			; last mouse activity
	push	es
	les	bx,[tcbmready]
	cmp	byte ptr es:[bx],0	       ; any characters in serial.sys
	pop	es
	jne	mint28c 		       ; yes...dont suspend
	push	es
	les	bx,[tcbmcount]
	cmp	byte ptr es:[bx],0	       ; any characters in mouse buffer
	pop	es
	jne	mint28c 		       ; yes...don't supend
mint28a:
	mov	dx,[tcbmport]		       ; set port
	mov	dh,1			       ; set for 1 port to wait
	mov	al,0bh			       ; ser for keys, com, and time
mint28b:
;
;	Now that we desided to wait to improve overall efficiency of system
;	we can wake under following 3 conditions while suspended
;	    1. if user presses the keyboard
;	    2. if we get any mouse actively (only if mouse is installed)
;	    3. if 6 cycles expired.
;
	mov	ah,07h
	mov	bx,6			       ; set for 6 cycles
	pushf
	push	cs
	call	mosint38			; wait for 6 ticks or key
mint28c:
	call	mosrestore
	iret

;-----------------------------------------------------------------------;
; TestMos28 - test for MOS's INT 28 handler                             ;
;	Return Z if MOS's INT 28 handler                                ;
;-----------------------------------------------------------------------;

	assume	ds:nothing,es:nothing
TestMos28 proc	near
	push	ax
	push	bx
	push	ds
	MGetZERO ds
	mov	bx,28h*4
	mov	ax,cs
	cmp	ax,word ptr [bx+2]
	jne	t28out
	lea	ax,MOSINT28
	cmp	ax,word ptr [bx]
t28out:
	pop	ds
	pop	bx
	pop	ax
	ret
TestMos28 endp	

	page
	subttl	safe28 - set up for and issue an int28
;-----------------------------------------------------------------------;
; safe28 - set up for and issue an int28				;
;									;
; entry parms: none							;
;									;
; exit	parms: none							;
;									;
;	global data affected: none					;
;	global procedures called: none					;
;	registers changed: none 					;
;									;
; Special Notice: Don't do INT 28 if tcbsafe28 is not set to 'Y'        ;
;-----------------------------------------------------------------------;
	assume	ds:nothing,es:nothing,ss:nothing
public	safe28
safe28	proc near
	push	ax
	push	ds
	mgetscb ds
	assume	ds:grp
	push	es
	mov	es,[scbtcbpc]
	assume	es:tcb
	cmp	[tcbsafe28],'Y'
	jne	x28c
	cmp	[scbcrit],0		; If inside INT 24 handler don't
	je	x28a			; do the int 28 call.
	pushf
	push	cs			; Call mosint28 handler so that
	call	mosint28		; task switching can be occur
	jmp	short x28c		; while we are in a critical error
x28a:	
	inc	[tcb28cnt]		; SAH 05/26/88 Increment 28 staging 
	mov	ax,ss
	cmp	ax,[scbtcbpc]
	je	x28b
	call	do28
	jmp	x28c
x28b:
	assume	ss:tcb
	cli
	push	[tcbstkp]
	mov	[tcbstkp],sp
	sub	[tcbstkp],256
	sti
	call	do28
	pop	[tcbstkp]
x28c:
	pop	es			;SAH
	pop	ds
	pop	ax
	ret
safe28	endp

	page
	subttl	DO28	- issue INT 28 call
;-----------------------------------------------------------------------;
; do28 - issue int28 call						;
;									;
; entry parms: none							;
;									;
; exit	parms: none							;
;									;
;	global data affected: none					;
;	global procedures called: none					;
;	registers changed: none 					;
;-----------------------------------------------------------------------;
	assume	ds:nothing,es:nothing,ss:nothing
do28 proc near
	push	ax
	push	bx		; never know what those tsr's will do
	push	cx
	push	dx
	push	si
	push	di
	push	bp
	push	ds
	push	es
	mgetscb es			; sah point to scb seg
	assume	es:grp			; sah
	push	word ptr [scbinmos]	; sah make sure you push scbinmos
	mov	al,[scbnoswt]
	push	ax
	mov	[scbnoswt],0
	int	28h
	pop	ax
	mov	[scbnoswt],al
	pop	word ptr [scbinmos]	; sah and restore the value
	mov	es,[scbtcbpc]		; SAH
	assume	es:tcb			; SAH
	mov	[tcbsafe28],'Y' 	; SAH
	dec	[tcb28cnt]		; SAH Decrement counter
	pop	es
	pop	ds
	pop	bp
	pop	di
	pop	si
	pop	dx
	pop	cx
	pop	bx
	pop	ax
	ret
do28 endp

	subttl	mosfun34 - Get Pointer to InDOS flag
	page
;-----------------------------------------------------------------------;
; This return a pointer to MOS equivilent to DOS's InDOS flag which     ;
; Indicated that MOS is busy or not for a TSR or Application which uses ;
; InDOS flag can re-enter MOS or NOT.					;
;									;
;  On Entry:								;
;	Nothing.							;
;									;
;  On Exit:								;
;	TES:TBX -> SCBINMOS						;
;									;
;-----------------------------------------------------------------------;
	assume	ds:grp,ss:tcb,es:nothing
mosfun34 proc	near
	MGetSCB es		; SCB segment address
	lea	bx,[scbinmos]	; SAH our INMOS flag
	mov	[TES],es
	mov	[TBX],bx
	ret
mosfun34 endp

	subttl	INMOS handling procedures
	page
;-----------------------------------------------------------------------;
; The following procedures are use for MOS interpertation of DOS indos	;
; flag.  They are kept here so that we always have a single placement	;
; of actual implementation.						;
;									;
; On entry:								;
;									;
;  DecINMOS - if INMOS is non-zero, decrement it			;
;  IncINMOS - increment INMOS						;
;  RstINMOS - resets INMOS to initial state (currently 0)		;
;  TestINMOS - test to see if we can do INMOS modification		;
;-----------------------------------------------------------------------;

	assume	ds:nothing,es:nothing,ss:nothing
DecINMOS proc	near
	push	ds
	MGetSCB ds
	assume	ds:grp
	call	TestINMOS		; test to make sure not internal call
	ja	DIMskip
	cmp	byte ptr [SCBINMOS],0	; just for safety
	je	DIMskip
	dec	byte ptr [SCBINMOS]
DIMskip:
	pop	ds
	ret
DecINMOS endp

	assume ds:nothing,es:nothing,ss:nothing
IncINMOS proc	near
	push	ds
	MGetSCB ds
	assume	ds:grp
	call	TestINMOS		; test to make sure not internal call
	ja	IIM
	inc	byte ptr [SCBINMOS]
IIM:
	pop	ds
	ret
IncINMOS endp

	assume ds:nothing,es:nothing,ss:nothing
RstINMOS proc	near
	push	ds
	MGetSCB ds
	assume ds:grp
	mov	byte ptr [SCBINMOS],0
	pop	ds
	ret
RstINMOS endp

	assume	ds:grp
TestINMOS proc	near
	push	ax
	push	ds
	mov	ds,[SCBTCBPC]
	assume	ds:tcb
	mov	ax,[tcb28cnt]		; this is number of INT 28's nest
	cmp	[tcbnest],al		; this is int 21 nested
	pop	ds
	pop	ax
	ret
TestINMOS endp


mosseg	ends
	end

