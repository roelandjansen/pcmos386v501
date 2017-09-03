	include page.inc
	title	mouse.asm - pc-mos/386 generic mouse driver interface
;-----------------------------------------------------------------------;
;		development specification				;
;									;
; program name: mouse.asm	assigned to: stewart hyde		;
; module name:	$mouse		assign date: 01/03/89			;
; entry points: 		completed:   02/14/89			;
; entry from:	int 15h - far call entry from mos			;
; entry method: call dword [vector] with ah = function number		;
; calls:								;
; purpose:	pc-mos/386 generic mouse driver interface		;
; refer to:	stewart hyde						;
; last update:	04/26/90						;
;									;
; this program implements ps/2 int 15 function c2h bios for pointing	;
; device. the actual mouse irq logic is generic to this driver and is	;
; interface by internal calls from this driver. the actually far routine;
; is call from within irq handler and its far address is set by function;
; c207h.								;
;									;
; int 15 mouse functions (c2h) provided:				;
;	    00h - enable\disable pointing device			;
;	    01h - reset pointing device 				;
;	    02h - set sample rate					;
;	    03h - set resolution					;
;	    04h - read device type					;
;	    05h - pointing device interface initialization		;
;	    06h - extended commands					;
;		  bh = 00h - return status				;
;		  bh = 01h - set scaling to 1:1 			;
;		  bh = 02h - set scaling to 2:1 			;
;	    07h - device driver far call initialization 		;
;									;
; this program has a mouse function handler (accessable by reading 4	;
; 4 byte pointer from driver) which will handle out side control of	;
; mouse driver.  the functions for this driver are as follows:		;
;	ah = 00 	allocated entry 				;
;	bx = tcb	tcb for mouse driver				;
;	   returns	es:bx = offset of mouse internal data structure ;
;	bx = 0000h	return mouse data structure list		;
;	   returns	es:ax = offset of start of structure		;
;			cx = number of data structure in driver 	;
;									;
; there is also a mouse poll routine which mos will periodiacally call	;
; to poll driver and this routine will handle communications with	;
; mouse via int 14h interface.	this handle uses either microsoft 3 byte;
; protocal or mouse systems 5 byte protocal. note that microsoft's      ;
; protocal requires rts high.						;
;									;
; this program requires that it be loaded after all (atleast ones which ;
; will be associated with this driver) serial drivers including sunriver;
; and ali drivers which have associated serial drivers via int 14h	;
;									;
; for compatibility with mouse drivers which take over int 74h, in	;
; addition of call to [scbcall74] inside of first level int 74 handle.	;
; i place a call to int 74 to do actual calling of user's far routine.  ;
; when int 74 intercept calls original intercept mos will then call	;
; scbcall74 which will then call the users far routine. 		;
;									;
; microsoft 2 button mouse structure:					;
;	byte			bit					;
;		    6	  5	4     3     2	   1	 0		;
;	-----------------------------------------------------		;
;	  0	    1	 left  right  y7    y6	   x7	 x6		;
;	  1	    0	  x5   x4    x3     x2	   x1	 x0		;
;	  2	    0	  y5   y4    y3     y2	   y1	 y0		;
;									;
;  left  = left switch (button) - either 1 (=on) or 0 (= off)		;
;  right = right switch (button) - either 1 (=on) or 0 (= off)		;
;									;
;  x7 - x0 = 8 bit binary count of change in x position 		;
;  y7 - y0 = 8 bit binary count of change in y position 		;
;									;
;  right direction is positive, left direction is negative		;
;  down direction is positive, up direction is negative 		;
;-----------------------------------------------------------------------;
;   sah     05/02/89	added logic to detect if serial driver is	;
;			installed or not.				;
;-----------------------------------------------------------------------;
;   sah     05/24/89	corrected movement problem by not using x and y ;
;			storage areas (word2 and word3) for temporary	;
;			storage during upper bit storing of movements	;
;-----------------------------------------------------------------------;
;   sah     05/31/89	corrected slow movement mouse problem, via	;
;			removing test for 0ffh and changing not to neg	;
;-----------------------------------------------------------------------;
;   sah     06/15/89	corrections for faster performance, via code	;
;			optimization and use of internal buffering with ;
;			fast string input calls, so that system will	;
;			have minimun calls to serial drivers		;
;-----------------------------------------------------------------------;
;   sah     06/23/89	attempts for helping in spiking...via making	;
;			sure that next packet after error detected is	;
;			not sent to application.			;
;-----------------------------------------------------------------------;
;   sah     07/19/89	corrections for co-existence with ps/2 hardware ;
;			mouse.						;
;-----------------------------------------------------------------------;
;   sah     08/10/89	updated doc on mouse packet structures		;
;-----------------------------------------------------------------------;
; mjs 08/12/89	In the process of chasing problem #54, where mouse	;
;		spikes were occuring when two vna workstations were 	;
;		pammed to watch one windows task, I cleaned up this	;
;		module and converted part of it to action chart format.	;
;		the actual problem turned out to be within the vidram	;
;		logic.  this file was produced from _mouse.cht which	;
;		is within \mos.dir\cht.dir on the first server volume.	;
;-----------------------------------------------------------------------;
;   SAH     11/07/89    Corrected possiable problem with call INT 14	;
;			because SI on function 0fh is unknowned. This   ;
;			could cause MOS to wait and this is not needed  ;
;			for this driver. The desired is to get as many  ;
;			bytes as it can from INT 14 buffer into its own ;
;			internal buffer.				;
;-----------------------------------------------------------------------;
;   SAH	    11/09/89	Corrections to polling logic, so that logic will;
;			call INT 74 more than once.			;
;-----------------------------------------------------------------------;
; BWR	11/30/89	Marked messages for foreign language		;
;			translation.					;
;-----------------------------------------------------------------------;
;  SAH	    12/18/89	Corrections to buffer initialization, save 3k   ;
;			of SMP memory, found while working on split-smp ;
;-----------------------------------------------------------------------;
;  SAH	  01/08/90	Change SI for function 0f to 1 for minimal wait ;
;-----------------------------------------------------------------------;
; SAH     04/26/90	Update for better efficencty on ViewPort	;
;-----------------------------------------------------------------------;

;	conditional assemble equ below

version 	equ	01
debug		equ	0

if1
	%out -----------------------------------------------------------
	%out - $MOUSE.SYS v1.00 PC-MOS Generic Mouse Driver
	%out - (c) Copyright 1989, 1990 The Software Link, Incorporated
	%out -
	%out -		     Updated: 4/26/90
	%out -
	%out - designed and written by Stewart Hyde
	%out -----------------------------------------------------------
	%out
	if	version
		%out  pc-mos version check
	endif
	if	debug
		%out  debugging logic included
	endif
endif

	subttl	group segments and include block definitions
	page
;-----------------------------------------------------------------------;
; access to partition saved registers					;
;-----------------------------------------------------------------------;
.xlist
	include options.inc
	include _mouse.pub
	include mosregs.inc
	include xifmacs.inc

tcb	segment at 1234h
	include mostcb.inc
tcb	ends

scbs	segment at 7000h
	assume cs:scbs
	include mosscbdf.inc
scbs	ends

.list

; definitions and equates use

	page
ddt	segment para public 'data'	; to force loading with data
	assume	cs:ddt,ds:nothing,es:nothing,ss:nothing

mosddtsh equ	this byte
	dd	-1		; filled in with pointer to next driver
	dw	8000h		; signifying a character device
	dw	strat		; device strategy entry point
	dw	inter		; device interrupt entry point
srname	db	'$$MOUSE '	; device name

request dd	0

fn	dw	ddtinit ; 0 - init
	dw	ddtnull ; 1 - media check
	dw	ddtnull ; 2 - build bpb
	dw	ddtnull ; 3 - ioctl input
	dw	ddtread ; 4 - read
maxfn	equ	($-fn)/2

strat:
	mov	word ptr [request],bx
	mov	word ptr [request+2],es
	retf

inter:
	push	es
	push	ds
	push	si
	push	bx
	push	ax
	mov	bx,cs
	mov	ds,bx
	assume	ds:ddt
	mov	ax,0100h
	les	bx,[request]
	mov	si,es:[bx+2]
	and	si,0ffh
	cmp	si,maxfn
	jae	inter1
	shl	si,1
	call	fn[si]
inter1:
	assume	ds:nothing
	les	bx,[request]
	mov	es:[bx+3],ax	; store result status
	pop	ax
	pop	bx
	pop	si
	pop	ds
	pop	es
	retf

; null device driver call does nothing

ddtnull:
	mov	ax,0100h	; return no error, done
	ret

	subttl	ddtread - return the terminal function vector
	page

; read just returns the mouse function vector

ddtread:
	lds	si,es:[bx+14]
	mov	cx,es:[bx+18]
	mov	word ptr es:[bx+18],0	; nothing read if error
	mov	ax,8103h		; error, done, unknown command
	cmp	cx,4
	jne	ddtrd1			; if not reading exactly 4 bytes
	mov	es:[bx+18],cx				; else read 4 bytes
	mov	word ptr ds:[si],offset mousefun  ; and these are them
	mov	ds:[si+2],cs
	mov	ax,0100h		; no error, done
ddtrd1:
	ret

	subttl	local data area - storage area for data and structures
	page

include genmouse.inc

scbadr	label	dword
scboff	dw	0		; offset to scb
scbseg	dw	0		; segment of scb

tcbseg	dw	0		; segment of tcb (caller)
old15	dd	0		; orginal int 15 handler
int14	dd	0		; int 14 handler
maxid	dw	32		; maximun tasks that can be allocated
savebx	dw	0		; bx save value use during int 15 logic
inmouse db	'N'		; inside mouse poll logic

sampval db	10,20,40,60,80,100,200	    ; sample rate values

ps2val	db	00h,00h,0f8h,00h,00h,00h,00h,00h,00h,00h

mfunct	label	word
	dw	offset	    mfun00	; enable\disable ps/2 mouse
	dw	offset	    mfun01	; reset pointing device
	dw	offset	    mfun02	; set sample rate
	dw	offset	    mfun03	; set resolution
	dw	offset	    mfun04	; read device type
	dw	offset	    mfun05	; pointing device initialization
	dw	offset	    mfun06	; extended commands
	dw	offset	    mfun07	; initialize far call

	subttl	mousefun - mouse function vector
	page
;----------------------------------------------------------------------;
; mousefun - mouse function vector				       ;
;								       ;
; this interface allows supported terminal drivers (ie sunriver driver);
; support for interfacing to there irqs instead of drivers internal    ;
; irqs								       ;
;								       ;
; functions provided:						       ;
;								       ;
;	ah = 00h  - initialized mouse entry			       ;
;		    this should be called by terminal register function;
;	bx = tcb    to initialized mouse data area for that task.      ;
;		    this will also return mouse data area in es:bx     ;
;		    also return start of global data area in ax        ;
;		    size of global data area in cx		       ;
;								       ;
;	ah = 01h  - removed mouse entry 			       ;
;		    this should be called by terminal unregister       ;
;	bx = tcb    function to remove mouse data area from driver     ;
;----------------------------------------------------------------------;
mousefun:
	or	ah,ah		; check for function 00h
	jnz	mou01

; do function 00 - initial mouse data entry by setting up
; task area for task and call reset function to reset the mouse

	or	 bx,bx		; this is for  internal testing
	jz	 mou00
	mov	 cx,bx		; save called tcb into cx
	call	 findtcb	; find tcb in task data sturcture
	jc	 mou00a
	jmp	 mouerr
mou00a:
	xor	 bx,bx
	call	 findtcb	; search for clean entry
	jnc	 mou00b
	jmp	 mouerr
mou00b:
	mov	 word ptr cs:[bx].tasktcb,cx	    ; save tasktcb
	call	 mfun01 	; reset the mouse

; set tcbupoll to our moupoll routine, and save prevous version

	push	ax
	push	ds
	mov	ds,cx
	assume ds:tcb
	mov	ax,word ptr [tcbupoll]
	mov	word ptr cs:[bx].orgpoll,ax
	mov	ax,word ptr [tcbupoll+2]
	mov	word ptr cs:[bx+2].orgpoll,ax
	mov	word ptr [tcbupoll],offset moupoll
	mov	word ptr [tcbupoll+2],cs
	mov	ax,cs
	cmp	word ptr [tcbunreg+2],ax
	je	mou000
	mov	ax,word ptr [tcbunreg]
	mov	word ptr cs:[bx].unreg,ax
	mov	ax,word ptr [tcbunreg+2]
	mov	word ptr cs:[bx+2].unreg,ax
	mov	word ptr [tcbunreg],offset mouunreg
	mov	word ptr [tcbunreg+2],cs
mou000:
	pop	ds
	assume ds:nothing
	pop	ax
mou00:
	push	 cs
	pop	 es
	lea	 ax,taskdata	; this is undocment but return start of data
	mov	 cx,[maxid]	; this is for debugging purpose or utilities
	clc
	retf
mou01:
	dec	ah		; check for function 01h
	jnz	mouerr

; do function 01 - this is to remove entry - find task structure
; clear all 64 bytes of task data to 0000's - this will clear tasktcb
; all other data items

	push	cx
	mov	cx,bx		; save tcb
	call	findtcb 	; find tcb in task data structure
	jc	mouerr1
	push	es
	push	di

; set tcbupoll back to orginal tcbupoll

	mov	es,cx
	assume	es:tcb
	mov	cx,word ptr cs:[bx].orgpoll
	mov	word ptr [tcbupoll],cx
	mov	cx,word ptr cs:[bx+2].orgpoll
	mov	word ptr [tcbupoll+2],cx

; set tcbunreg back to original tcbunreg

	mov	cx,word ptr cs:[bx].unreg
	mov	word ptr [tcbunreg],cx
	mov	cx,word ptr cs:[bx+2].unreg
	mov	word ptr [tcbunreg+2],cx

; clear out data stucture

	push	cs
	pop	es
	assume	es:nothing
	mov	di,bx
	xor	ax,ax
	mov	cx,mssize/2
	rep	stosw		; clear task structure
	pop	di
	pop	es
	pop	cx
	mov	word ptr cs:[bx].mport,-1	; initialize port -1
	clc
	retf
mouerr1:
	pop	cx
mouerr:
	stc
	retf

	subttl	mouunreg - mouse un register call for remtask
	page
;----------------------------------------------------------------------;
; mouunreg - mouse un register call for remtask. this is use to make   ;
; sure that we clear out the structure before removing the allocation  ;
;								       ;
; ds -> tcb un entry						       ;
;----------------------------------------------------------------------;
	   assume  ds:tcb
mouunreg:
	push	ax
	push	bx
	mov	bx,ds
	mov	ah,1			; deallocate mouse entry
	push	cs
	call	near ptr mousefun
	jc	munreg1
	mov	ax,word ptr [tcbunreg+2]
	or	ax,ax			; end of list, we are done
	jz	munreg1
	mov	bx,cs
	cmp	ax,bx			 ; same as us, well???
	je	munreg1 		 ; this is an error
	call	dword ptr [tcbunreg]
munreg1:
	pop	bx
	pop	ax
	retf

	subttl	mouse15 - mouse driver int 15 handler
	page
;----------------------------------------------------------------------;
; mouse15 - driver's INT 15 function c2h handler                       ;
;								       ;
; this handler handlers int 15 function c2h of the ps/2 bios which     ;
; controls the pointing device (mouse). 			       ;
;								       ;
; general idea: 						       ;
;   if int 15 function is not c2h and subfunction is lest <= 7 and     ;
; that the tcb is not for the master console on a ps/2 system then     ;
; process the function by calling one of the functions in function     ;
; table.							       ;
;								       ;
; grab current tcb and scan structures for tcb, if tcb segment is not  ;
; found than it is assume (currently) that int 15 logic for that tcb   ;
; has not been accessed yet. so then we will attempt to allocate (by   ;
; searching for tcb = 0000h) and if there is available space, set tcb  ;
; field in data structure to current tcb.			       ;
;----------------------------------------------------------------------;
	assume	ds:nothing,es:nothing
	db	'SAH'			; use internal to detect if loaded 2x
mouse15:
	pushf
	push	bx
	push	ds
	lds	bx,[scbadr]
	assume	ds:scbs
	mov	ds,[bx+scbtcbpc]	   ; get tasks tcb
	assume	ds:tcb
	cmp	byte ptr [tcbmouse],'Y'     ; is mouse installed
	pop	ds
	pop	bx
	jne	m15a			    ; no so call original bios
	cmp	ah,0c0h
	jne	m15c2
	push	cs
	pop	es
	lea	bx,ps2val		; use our internal table
	xor	ah,ah			; indicate all ok
	popf
	clc
	retf	2
m15c2:
	cmp	ah,0c2h 		; if function is not c2h
	jne	m15a			; then jump to original bios
	cmp	al,07h			; subfunction is above 07h
	jbe	m15b			; then call original bios
m15a:
	popf
	jmp	dword ptr cs:[old15]

; now is the time to do simulation of ps/2 bios's mouse functions

m15b:
	popf
	push	ax
	push	bx
	push	ax
	pushf
	push	ds
	mov	[savebx],bx
	lds	bx,[scbadr]
	assume	ds:scbs
	mov	bx,[bx+scbtcbpc]	; get current tcb
	pop	ds
	call	findtcb 		; search for tcb
	jc	m15er
	popf
	pop	ax
	push	si
	mov	si,bx
	mov	bl,al			; get subfunction
	xor	bh,bh
	shl	bx,1
	xchg	bx,si
	call	word ptr [si+mfunct]
	pop	si
	pop	bx
	pop	bx			; was ax kill value of old ax
	mov	bx,[savebx]
	retf	2
m15er:
	popf
	pop	 ax
	pop	 bx
	pop	 ax
	mov	 ah,03h 		 ; this is interface error
	stc
	retf	 2

	subttl - mouse function c2h subfunctions
	page
;-----------------------------------------------------------------------;
; mouse subfunction 00h - enable\disable pointing device		;
;									;
; input:								;
;	bh (savebx) = 00h - disable					;
;		    = 01h - enable					;
;-----------------------------------------------------------------------;
mfun00:
	mov	ax,[savebx]
	or	ah,ah
	jnz	mf001

; do bh=00 - disable

	and	byte ptr cs:[bx].sbyte1, not senable
	jmp	short mf00ok
mf001:
	dec	ah
	jnz	mf00bad

; do bh=01 - enable

	mov	ah,5				; indicate no far call
	test	byte ptr cs:[bx].mstatus, farinstall
	jz	mf00err
	or	byte ptr cs:[bx].sbyte1, senable
mf00ok:
	xor	ax,ax				; indicate all ok
	clc
	ret
mf00bad:
	mov	ah,2				; indicate invalid input
mf00err:
	stc
	ret

;-----------------------------------------------------------------------;
; mouse subfunction 01h - reset pointing device 			;
;									;
; output:								;
;	bh (savebx) = 00h						;
;-----------------------------------------------------------------------;
mfun01:
	xor	ax,ax		    ; use reserved value
	call	mreset		    ; lowlevel reset
	xor	ax,ax		    ; indicate ok
	mov	word ptr [savebx],ax
	clc
	ret

	page
;-----------------------------------------------------------------------;
; mouse subfunction 02h - set sample rate				;
;									;
; input:								;
;	bh (savebx) = sample rate value 				;
;		    = 00h = 10	reports per second			;
;		    = 01h = 20	reports per second			;
;		    = 02h = 40	reports per second			;
;		    = 03h = 60	reports per second			;
;		    = 04h = 80	reports per second			;
;		    = 05h = 100 reports per second			;
;		    = 06h = 200 reports per second			;
;-----------------------------------------------------------------------;
mfun02:
	mov	ax,[savebx]
	cmp	ah,6		    ; check for invalid input
	ja	mf02bad
	push	si
	mov	al,ah
	xor	ah,ah
	mov	si,ax
	mov	ah,byte ptr [si+sampval]	; get value from table
	mov	byte ptr cs:[bx].sbyte3,ah	   ; save it in structure
	pop	si
	xor	ah,ah
	clc
	ret
mf02bad:
	mov	ah,2		    ; return invalid input
	stc
	ret

;-----------------------------------------------------------------------;
; mouse subfunction 03h - set resolution				;
;									;
; input:								;
;	bh (savebx) = resolution value					;
;		       00h = 1 count per millimeter			;
;		       01h = 2 counts per millimeter			;
;		       02h = 4 count per millimeter			;
;		       03h = 8 counts per millimeter			;
;-----------------------------------------------------------------------;
mfun03:
	mov	ax,[savebx]
	cmp	ah,3		    ; check for invalid input
	ja	mf03bad
	mov	byte ptr cs:[bx].sbyte2,ah
	xor	ah,ah
	clc
	ret
mf03bad:
	mov	ah,2		    ; return invalid input
	stc
	ret

;-----------------------------------------------------------------------;
; mouse subfunction 04h -  read device type				;
;									;
; output:								;
;	bh (savebx) = device id = 00h					;
;-----------------------------------------------------------------------;
mfun04:
	xor	ax,ax		    ; indicate all ok
	mov	[savebx],ax	    ; device = 00h
	clc
	ret

	page
;-----------------------------------------------------------------------;
; mouse subfunction 05h - pointing device initialization		;
;									;
; input:								;
;	bh (savebx) =	data package size				;
;			00h = reserved					;
;			01h = 1 byte					;
;			02h = 2 bytes					;
;			03h = 3 bytes					;
;			04h = 4 bytes					;
;			05h = 5 bytes					;
;			06h = 6 bytes					;
;			07h = 7 bytes					;
;			08h = 8 bytes					;
;-----------------------------------------------------------------------;
mfun05:
	mov	ax,[savebx]
	or	ah,ah		    ; 00 = reserved = bad input
	jz	mf05bad
	cmp	ah,8		    ; > 8 = bad input
	ja	mf05bad
	call	mreset
	xor	ax,ax
	clc
	ret
mf05bad:
	mov	ah,2		    ; indicate bad input
	stc
	ret

;-----------------------------------------------------------------------;
; mouse subfunction 06h - extended commands				;
;									;
; bh (savebx) = 00h = return status					;
;									;
; output:								;
;   bl = status byte 1							;
;	bit 7 = 0 - reserved						;
;	bit 6 = 0 - stream mode 					;
;	      = 1 - remote mode 					;
;	bit 5 = 0 - disable						;
;	      = 1 - enable						;
;	bit 4 = 0 - 1:1 scaling 					;
;	      = 1 - 2:1 scaling 					;
;	bit 3 = 0 - reserved						;
;	bit 2 = 1 - left button pressed 				;
;	bit 1 = 0 - reserved						;
;	bit 0 = 1 - right button pressed				;
;									;
;   cl = status byte 2							;
;	00h = 1 count per millimeter					;
;	01h = 2 counts per millimeter					;
;	02h = 4 count per millimeter					;
;	03h = 8 counts per millimeter					;
;									;
;   dl = status byte 3							;
;	0ah = 10  reports per second					;
;	14h = 20  reports per second					;
;	28h = 40  reports per second					;
;	3ch = 60  reports per second					;
;	50h = 80  reports per second					;
;	64h = 100 reports per second					;
;	c8h = 200 reports per second					;
;									;
; bh (savebx) = 01h = set scaling to 1:1				;
;									;
; bh (savebx) = 02h = set scaling to 2:1				;
;-----------------------------------------------------------------------;
mfun06:
	mov	ax,[savebx]
	cmp	ah,2		    ; check for invalid input
	ja	mf06bad
	or	ah,ah		    ; subfunction 00
	jnz	mf061

; do bh = 00 return status

	mov	al,byte ptr cs:[bx].sbyte1	; get status byte 1 (in al)
	mov	cl,byte ptr cs:[bx].sbyte2	; get status byte 2
	mov	dl,byte ptr cs:[bx].sbyte3	; get status byte 3
	mov	[savebx],ax			; set bx value for later use
	jmp	short mf06ok
mf061:
	dec	ah		    ; check for subfunction 01
	jnz	mf062

; do bh = 01 set 1:1 scaling

	and	byte ptr cs:[bx].sbyte1, not sscale    ; set 1:1 scaling
	jmp	short	mf06ok

; do bh = 02 set 2:1 scaling

mf062:
	or	byte ptr cs:[bx].sbyte1, sscale        ; set 2:1 scaling
mf06ok:
	xor	ah,ah		    ; all ok
	clc
	ret
mf06bad:
	mov	ah,2		    ; indicate invalid input
	stc
	ret

	page
;-----------------------------------------------------------------------;
; mouse subfunction 07h - set far call routine address			;
;									;
; input:								;
;	es = segment							;
;	bx = offset							;
;-----------------------------------------------------------------------;
mfun07:
	or	byte ptr cs:[bx].mstatus, farinstall
	mov	word ptr cs:[bx+2].farcall,es
	mov	ax,[savebx]
	mov	word ptr cs:[bx].farcall,ax
	xor	ax,ax
	clc
	ret

; the following is a lowlevel routine which will be use to
; reset the status of system

mreset:
	or	ah,ah		; is this reserve call
	jz	mres1		; yes skip setting packet size
	mov	byte ptr cs:[bx].packet,ah
mres1:
	and	byte ptr cs:[bx].sbyte1, (sleft+sright)
	mov	byte ptr cs:[bx].sbyte2, 02h		   ; 4 counts / mm
	mov	byte ptr cs:[bx].sbyte3, 100		   ; 100 reports / sec
	ret

	subttl moupoll	- mouse user poll routine
	page
;----------------------------------------------------------------------;
; moupoll - this routine is call to test and if necessary call mouse's ;
; poll routine set by function 07.				       ;
;								       ;
; input:							       ;
;	ds -> tcb						       ;
;----------------------------------------------------------------------;
	assume ds:tcb,es:nothing,ss:nothing
moupoll:
	lxif [tcbmouse] != 'Y' then moup070  ; is mouse active?
	lxif [inmouse] == 'Y' then moup070  ; already inside mouse polling?
	mov	cs:[inmouse],'Y'	; indicate that we are inside
	push	ax			; mouse polling logic
	push	bx
	push	cx
	mov	bx,ds
	call	findtcb			; get pointer to mouse's data structure
	lxif flags == cy then moup060
moup000:
	push	ds
	push	cs
	pop	ds
	assume	ds:ddt
moup010:
	xif <[bx].mstatus> test1 dataready then moup040
	xif [bx].bcount == 0 else moup020  ; anything currently in buffer
	push	es
	push	di
	les	di,[bx].mready		; get pointer to input ready
	cmp	byte ptr es:[di],0	; any characters ready
	pop	di
	pop	es
	xif flags == e then moup040
	push	dx
	push	bx
	push	si
	push	es
	mov	dx,cs
	mov	es,dx			; make es:bx -> mouse buffer
	mov	dx,word ptr [bx].mport
	lea	bx,[bx].buffer
	mov	cx, maxbuff
	mov	si,1			; wait - minimal amount of time
	mov	ah,0fh
	call	doint14
	pop	es
	pop	si
	pop	bx
	xoif flags == z || ax == 0 then moup030
	mov	[bx].bcount,al
	mov	[bx].bpos,0
	pop	dx
moup020:
	push	si
	xor	ax,ax
	mov	al,[bx].bpos
	mov	si,ax
	mov	al,byte ptr [bx+si].buffer
	inc	byte ptr [bx].bpos
	dec	byte ptr [bx].bcount
	pop	si
	call	domouse			; do mouse stage logic
	jmp	short moup010
moup030:
	pop	dx
moup040:
	pop	ds
	assume	ds:tcb

; if the mouse is enabled and a far install has been done
; and if mstatus shows data ready then
; call the users far routine using the ps/2 bios convention

	xaif cs:[bx].sbyte1 test1 senable && cs:[bx].mstatus test1 farinstall else moup050
	xif cs:[bx].mstatus test0 dataready then moup050
	push	es
	push	bx
	les	bx,cs:[scbadr]
	assume	es:scbs
	mov	ax,[bx+scbtimer]
	mov	[tcbmtimer],ax
	mov	byte ptr [bx+scbin74],'Y'  ; tell mos that we want $mouse

; simulate int 74 which will in turn call scbcall74 (mint74) 
; which will call users far routine

	int	74h
	mov	byte ptr [bx+scbin74],'N'  ; ok we are done for now
	pop	bx
	pop	es
	assume	es:nothing
	jmp	moup000			   ; jump back for more input

; if there is an original tcbupoll routine, chain to it

moup050:
	xif <word ptr cs:[bx+2].orgpoll> != 0 else moup060
	call	dword ptr cs:[bx].orgpoll
moup060:
	pop	cx
	pop	bx
	pop	ax			; indicate that we are nolonger
	mov	cs:[inmouse],'N'	; inside mouse polling logic
moup070:
	retf

	subttl domouse - do mouse stage
	page
;----------------------------------------------------------------------;
; domouse - do mouse stage					       ;
;								       ;
; if dataready then setup for proper data return values as follows     ;
;								       ;
;								       ;
; input:							       ;
;	ds -> code seg						       ;
;	al -> character stage					       ;
;	bx -> mouse structure					       ;
;----------------------------------------------------------------------;
	assume ds:ddt,es:nothing,ss:nothing
domouse:
	push	cx
	mov	ah,[bx].mstage

;$$$$$ mouse system code was here - moved to end of file

; this is where microsoft mouse format is handle

	xif ah == 0 else dom040		; stage 0? (sync)
	xif al test0 40h else dom010	; valid sync byte?
	mov	[bx].merror,'Y'		; no, indicate mouse error
	jmp	dom150
dom010:
	mov	[bx].mstage,00h		; for reset
	mov	[bx].word1,08h		; reset word 1
	xor	ah,ah			; clear status bytes
	xif al test1 20h else dom020	; if left press
	or	ah,4h			; indicate that left is press
	or	[bx].word1,1h		; also in word1
dom020:
	xif al test1 10h else dom030	; if right press
	or	ah,1h			; indicate that right is press
	or	[bx].word1,2h		; also in word1
dom030:
	or	[bx].sbyte1,ah
	push	ax			; save upper 2 bits of x and y
	and	ax,0011b		; max out x7 and x6
	mov	cl,6
	shl	ax,cl			; place data in bit 7 and bit 6
	mov	[bx].save2,ax		; save in data structure for later
	pop	ax
	and	ax,1100b		; max out y7 and y6
	shl	ax,1
	shl	ax,1
	shl	ax,1
	shl	ax,1
	mov	[bx].save3,ax		; place data in structure for later
	mov	ah,1			; goto to next stage
	jmp	short dom140
dom040:
	dec	ah
	xif flags == zr else dom060
	xif al test1 40h else dom050	; if a sync byte
	mov	[bx].merror,'Y'		; indicate mouse error
	jmp	short dom130
dom050:
	and	ax,111111b		; mask out upper 2 bits
	or	[bx].save2,ax		; place it in save data area
	mov	ah,2			; goto to stage 2 next
	jmp	short dom140
dom060:					; do stage 2 for y byte
	xif al test1 40h else dom070	; if a sync character
	mov	[bx].merror,'Y'		; indicate mouse error
	jmp	short dom130
dom070:
	and	ax,111111b		; mask out upper 2 bits
	or	[bx].save3,ax		; place it in save data area

; now that we are done with stage 2 and have all data
; translate data recieved into data passed to far call.
; the following code is help out in error control, if we have detected
; that we are out of sync - some case we might be so unfortunated that
; byte out of sync (via data loss from buffer) happen to co-responded
; to a packet then we could not detect that condition. but if we do
; detect it out of sync, throw away to next packet and continue on

	xif [bx].merror == 'Y' else dom080
	mov	[bx].merror,'N'
	jmp	short dom130
dom080:
	mov	cx,[bx].save2
	and	cx,0ffh
	xif cl test1 80h else dom090	; is high bit set
	or	[bx].word1,10h		; indicated negative
	jmp	short dom100
dom090:
	and	cx,7fh			; only 7 bits
dom100:
	mov	[bx].word2,cx
	mov	cx,[bx].save3
	and	cx,0ffh
	xif cl != 0 else dom120		; if value is zero, just
	xif cl test0 80h else dom110	; is high bit set
	or	[bx].word1,20h		; indicated negative
	and	cl,7fh
dom110:
	neg cl
dom120:
	mov	[bx].word3,cx		; only 7 bits
	or	[bx].mstatus, dataready	; indicated data ready
dom130:
	xor	ah,ah			; goto to stage 0 next
dom140:
	mov	[bx].mstage,ah
dom150:
	pop	cx
	ret

	subttl	mint74 - mouse int 74h handler (via scbcall74)
	page
;----------------------------------------------------------------------;
; mint74 - mouse int 74 handler. this routine is our int 74h handler to;
;	   simulate what ps/2 int 74h usage via directly doing the     ;
;	   interupt inside mouse poll routine. this routine is called  ;
;	   mos's first level INT 74 handle. This is done so that we    ;
;	   can acurated simulated the actions of ps/2 int 74 usage.    ;
;	   please note that we do not simulated the ps/2's INT 74 use  ;
;	   of keyboard. but i (stewart) have notice that all int 74    ;
;	   intercepts (microsoft mouse, ibm mouse, mouse system mouse, ;
;	   and ms windows mouse.drv just call the old int 74, to get   ;
;	   necessary input and handle calling the user's far call out  ;
;	   side the bios.					       ;
;----------------------------------------------------------------------;
	assume	ds:nothing,es:tcb,ss:nothing
mint74:
	cmp	byte ptr cs:[inmouse],'Y'   ; re-entrycy control
	je	m74main
	retf
m74main:
	push	ax
	push	bx
	mov	bx,es
	call	findtcb 		    ; access task related information
	jc	m74done
	push	word ptr cs:[bx].word1
	push	word ptr cs:[bx].word2
	push	word ptr cs:[bx].word3
	push	word ptr cs:[bx].word4
	call	dword ptr cs:[bx].farcall    ; call far routine
	pop	ax
	pop	ax
	pop	ax			; pop push values off stack
	pop	ax
	and	byte ptr cs:[bx].mstatus, not dataready ; clear data ready
m74done:
	pop	bx
	pop	ax
	retf

	subttl	utility routines
	page
;----------------------------------------------------------------------;
; findtcb - this routine search through task structure for stucture    ;
;	    whose tasktcb is same as tcb passed.		       ;
;								       ;
; input:							       ;
;	bx = tcb segment (0 if looking for next free one)	       ;
;								       ;
; output:							       ;
;	bx = task pointer (if no carry) 			       ;
;----------------------------------------------------------------------;
	assume ds:nothing,es:nothing,ss:nothing
findtcb:
	push	cx
	push	si
	lea	si,taskdata
	mov	cx,cs:[maxid]		; get limit
ftcb1:
	cmp	word ptr cs:[si].tasktcb,bx
	je	ftcb2
	add	si,mssize		    ; assume 64 bytes each
	dec	cx
	jnz	ftcb1
	pop	si
	pop	cx
	stc				    ; indicate error
	ret
ftcb2:
	mov	bx,si			    ; save pointer for return status
	pop	si
	pop	cx
	clc
	ret

doint14:
	pushf
	cli
	call	dword ptr cs:[int14]
	ret

	subttl	ddtinit - mos device driver init
	page
;-----------------------------------------------------------------------;
; initialization - set driver length and exit				;
;-----------------------------------------------------------------------;
	assume	cs:ddt,ds:ddt,es:nothing

; this code is here because it is use to initialize drivers internal
; data structures and rewrites of main code if necessary

fininit:
	mov	bx,[maxid]
	mov	cl,6			; note that this assume that task
	shl	bx,cl			; structures is 64 bytes each (mssize)
	mov	cx,bx
	push	cx
	xor	ax,ax
	push	cs
	pop	es
	lea	di,taskdata
	cld
	shr	cx,1
	rep	stosw			; zap all data area to 0's

; initialized port values to -1

	mov	cx,[maxid]
	lea	bx,taskdata
idatalp:
	mov	word ptr cs:[bx].mport,-1
	add	bx,mssize
	loop	idatalp
	pop	cx

; adjust return parameter for driver size to include task space

	mov	ax,offset taskdata
	add	ax,cx
	pop	es
	pop	bx
	mov	word ptr es:[bx+14],ax
	mov	es:[bx+16],cs
	mov	ax,0100h
	ret

; this label use to store start of task area
; all code following this label will be either overlaid with
; task data or discarded.

taskdata label	byte

ddtinit:
	push	bx
	push	es
	lea	dx,ddtmsg
	mov	ah,9
	int	21h
if	version
	call	patchmos
	jc	derror
endif


; check if serial driver install on system

ddtcont:
	mov	ah,6
	int	14h
	test	ah,80h
	jnz	serins
	mov	[errout], offset eserial
	jmp	short derror

; save int 14 handler

serins:
	mov	ax,3514h
	int	21h
	mov	word ptr [int14],bx
	mov	word ptr [int14+2],es

; check to see if driver has been loaded twice

	mov	ax,3515h
	int	21h
	mov	word ptr [old15],bx
	mov	word ptr [old15+2],es	    ; save old int 15 handler
	cmp	word ptr es:[bx-3],'AS' 	; check if loaded twice
	jne	ddtinok
	cmp	byte ptr es:[bx-1],'H'
	jne	ddtinok

; user has attempted load driver twice, now is time should
; how smart we are

	mov	word ptr [errout], offset etwice
derror:
	lea	dx, ninsmsg
	mov	ah, 9
	int	21h
	mov	dx, [errout]
	mov	ah,9
	int	21h
	pop	es
	pop	bx
	mov	word ptr [srname],'\\'		; can't be opened
	mov	word ptr es:[bx+14], offset request
	mov	es:[bx+16],cs
	ret
ddtinok:
	mov	ah,2
	int	services
	mov	[scbseg],es
	mov	[scboff],bx
	call	install 		; install driver specific needs
	lea	dx, insmsg
	mov	ah, 9
	int	21h
	jmp	fininit

insmsg	db	'installed.     ',13,10,'$' ;@@XLAT
ninsmsg db	'not installed.     ',13,10,'$' ;@@XLAT
ddtmsg	db	13,10
	db	'PC-MOS Generic Mouse Driver (900426) $        ' ;@@XLAT
etwice	db	'This driver can not be loaded twice!         ',13,10,'$' ;@@XLAT
eserial db	'This driver requires a serial driver!        ',13,10,'$' ;@@XLAT

if	version
bmosmsg db	'This driver requires atleast PC-MOS rel 4.00          ',13,10,'$' ;@@XLAT
errout	dw	offset	bmosmsg
else
errout	dw	0
endif

;------------------------------------------------------------------;
; install - installs driver specific needs			   ;
;								   ;
; currently does the following: 				   ;
;	1. sets up scbcall74 handler for int 74h		   ;
;	2. sets new int 15 handler				   ;
;------------------------------------------------------------------;
	assume	es:scbs,ds:nothing,ss:nothing
install:
	push	ds
	mov	word ptr [bx+scbcall74+2],cs
	mov	word ptr [bx+scbcall74], offset mint74
	push	cs
	pop	ds
	lea	dx,mouse15
	mov	ax,2515h		    ; set our int 15 handler
	int	21h
	pop	ds
	ret

;------------------------------------------------------------------;
; patchmos - check and patches mos if necessary.		   ;
;								   ;
; steps:							   ;
;     1. return error message if not atleast pc-mos/386 rel 4.00   ;
;------------------------------------------------------------------;
if	version
patchmos:
	mov	ah,30h
	int	21h		    ; get dos version
	push	ax
	mov	ah,30h
	mov	bx,ax
	mov	cx,ax
	mov	dx,cx
	int	21h		    ; get mos version
	pop	cx
	cmp	ax,cx
	je	patchbad	    ; error out if dos
	cmp	al,04h
	jb	patchbad	    ; error out if before mos 4.00
	clc
	ret

patchbad:
	stc
	ret
endif

if1
	%out - pass 1 completed.
else
	%out - pass 2 completed.
endif

ddt	ends
	end


comment |


this code was relocated from above - search for $$$

	test	byte ptr [bx].mstatus,mscproto
	jnz	dom00
	jmp	dom1

; this is where mouse systems format is handle

dom00:
	or	 ah,ah			    ; is this for stage 0 (sync)
	jnz	 dom01			    ; no...continue on
	mov	 ch,al
	and	 ch,not 7		    ; mask out lower three bits
	cmp	 ch,80h 		    ; is this sync byte
	je	 dom001 		    ; yes handle sync byte
	jmp	 dom1skip		    ; get out of here

; handle stage 0 handling for buttons, please note that we
; ignore the middle button because ps/2 logic does not have
; facilities for the middle button

dom001:
	mov	byte ptr [bx].mstage,00h    ; for reset
	mov	word ptr [bx].word1,08h     ; reset word 1
	xor	ah,ah			    ; clear status bytes
	test	al,4h			    ; if left press
	jnz	dom002
	or	ah,4h			    ; indicate that left is press
	or	word ptr [bx].word1,1h	    ; also in word1
dom002:
	test	al,1h			    ; if right press
	jnz	dom003
	or	ah,1h			    ; indicate that right is press
	or	word ptr [bx].word1,2h	    ; also in word1
dom003:
	or	byte ptr [bx].sbyte1,ah
	mov	ah,1			    ; go to stage 1
	jmp	dom1done
dom01:
	dec	ah
	jz	domx			   ; is this stage 1
	dec	ah
	jz	domy			   ; is this stage 2
	dec	ah
	jnz	domy			   ; is this stage 3

; do handling for x values, this is for stages 1 and 3

domx:
	mov	cl,al
	and	cx,7fh
	mov	word ptr [bx].word2,cx
	test	al,80h				    ; negative
	jz	domx1
	or	word ptr [bx].word1,10h 	    ; indicate negative
domx1:
	jmp	short domcomm		   ; jump to common logic

; do handling for y values, this is for stage 2 and 4
; note that user interupt handler will be call after this call

domy:
	mov	cl,al
	and	cx,7fh				    ; mask out un-necessary
	mov	word ptr [bx].word3,cx		    ; bits
	test	al,80h				    ; negative
	jz	domy1
	or	word ptr [bx].word1,20h 	    ; indicate negative
domy1:
	mov	word ptr [bx].word4,0		    ; zero out word 4
	or	byte ptr [bx].mstatus, dataready    ; indicated data ready
domcomm:
	mov	ah,byte ptr [bx].mstage
	inc	ah				    ; add a stage
	cmp	ah,5				    ; are we done
	jb	domcok
	xor	ah,ah				    ; goto to stage 0
domcok:
	jmp	dom1done			    ; done with this stage
|

