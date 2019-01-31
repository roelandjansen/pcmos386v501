	include page.inc
	title	MOSDDCON - MOS device driver for CONsole I/O

;	include mosddcon.pub
;-----------------------------------------------------------------------;
;									;
;		Development Specification				;
;									;
;									;
; Program Name: MOS.COM 		Assigned to: David A. Morrow	;
; Module Name:	MOSDDCON		Assign date: 04/08/86		;
; Entry Points: n/a			Completed:			;
; Entry From:	n/a							;
; Entry Method: n/a							;
; Calls:	n/a							;
; Purpose:	MOS console device driver.				;
; Refer to:	n/a							;
; Last Update:	05/09/91						;
;									;
;-----------------------------------------------------------------------;
;	SAH	07/23/87	Modify NDINPUT to check convert Cntrl-  ;
;				PrtSc into Cntrl-P			;
;-----------------------------------------------------------------------;
;	SAH	12/01/87	Implemented wrap around ANSI Output	;
;				sequence ESC [?7h and ESC [?7l		;
;				Please note remaining setmode and reset ;
;				mode, get status and keyboard 		;
;				reassignment need to be implemented     ;
;-----------------------------------------------------------------------;
;	JSM	12/06/87	Fixed erase to end of line command so	;
;				that it would erase the last character	;
;-----------------------------------------------------------------------;
;	SAH     01/20/88        Change SCBSEG and ZERO seg access to 	;
;				use MGetXXXX macros. Optimize mos10 and ;
;				mos16 macros for code size		;
;-----------------------------------------------------------------------;
;       SAH     02/18/88        Remove mos16 macro and con16 proc which ;
;				are not used				;
;-----------------------------------------------------------------------;
; 02/21/88 rbr/sah	Move DDT code to MO2 group.        		;
;-----------------------------------------------------------------------;
; mjs 6/9/88	Modified sah's new code which calls int16, func 1 and	;
;		issues int28's if there is an int28 intercept for the	;
;		current task.  Because I had to skip around the call	;
;		to tsl in mossaver when scbnoswt != 0, there was no	;
;		way for tsl to get called when an int28 intercept	;
;		was in place.  I added a call to tsl in the int16/int28	;
;		loop here so task switching would not stop.		;
;-----------------------------------------------------------------------;
; RDG 6/20/88	modified instat to do an int16 to determine the actual  ;
; RG8172	status of the keyboard and to set the busy status if no	;
;		character is ready.  (PTR 0050)                      	;
;-----------------------------------------------------------------------;
; SAH 06/21/88  Remove unnessary safe28 calls, added support for ANSI   ;
;		(not DOS ANSI compatible) PTR 064 Clear to end of screen;
;		ESC [0J. Implemented status report PTR 061.		;
;-----------------------------------------------------------------------;
; SAH 08/11/88  Corrected Clear to end of screen. 			;
;		Optimize module slight by removing calls to ckansi 	;
;		which did nothing.					;
;-----------------------------------------------------------------------;
; SAH 09/15/88  Changes so that Norvell execution speed will not be     ;
;		hurt by INT 28 loop logic.  This is done by using INT 38;
;		function to wait for a key or time.  			;
;-----------------------------------------------------------------------;
; SAH 09/23/88  Move Wait above to mosint28 routine.  This is done 	;
;		because Windows loops on INT 28 when Idea and placing   ;
;		wait inside mosint28 can improve performance on both.	;
;-----------------------------------------------------------------------;
; SAH 12/04/88	Corrected RDG's 06/20/88 updated by skiping call to to  ;
;		get keyboard status if scan code is pending. This was	;
;		causing mos to suspend unnecessary in devread if caller ;
;		ask for 1 key at a time and key pressed is extended.	;
;-----------------------------------------------------------------------;
; SAH 03/24/89	Correct INT 28 looping for Novell (or any INT 28 inside ;
;		a device driver - why put int 28 in a device driver in	;
;		multitasking enviroment like MOS) by making sure that	;
;		SCBNOSWT is zero during the loop.			;
;-----------------------------------------------------------------------;
; SAH 08/15/89	Revamp output for ansi processing. Including the	;
;		ability to disable ansi processing with MOS ANSI command;
;-----------------------------------------------------------------------;
; SAH 08/29/89  Corrections to MOS ANSI Scrolling.			;
;-----------------------------------------------------------------------;
; SAH 01/09/90  Implemented Keyboard re-assigment (p). Also remove some ;
; 		unuse code usage and other code optimization.		;
;-----------------------------------------------------------------------;
; SAH 11/16/90  Correction Dino.exe which was directly poking cursor    ;
;		position before int 21 call.				;
;-----------------------------------------------------------------------;
; SAH 01/23/91  Correction for error processing on ansi attribute set	;
;-----------------------------------------------------------------------;
; SAH 04/05/91	Corrections for Chineese character set program ET	;
;		if INT 10 is intercept than call INT 10 to get cursor   ;
;		position instead of grabbing from tcbcpos.		;
;-----------------------------------------------------------------------;
; SAH 05/09/91	Corrections for Color Prompts from my 04/05/91 changes  ;
;-----------------------------------------------------------------------;

	subttl	group segments and include block definitions

	page
	include GROUP.INC

	.xlist

	include MOSREGS.INC

tcb	segment at 1234h
	include MOSTCB.INC	; TCB definition
tcb	ends

gdata	segment word public 'data'
	include mosscbex.inc
gdata	ends

	.list

irq	segment byte public 'data'
irq	ends

poll	segment byte public 'data'
poll	ends

ddt	segment word public 'code2'
ddt	ends

	subttl	mos segment - MOS module code and local data

	page
mosseg	segment word public 'code1'
	assume	cs:mos,ds:grp,es:nothing,ss:tcb

	extrn	sbios:word
	extrn	safe28:near, TestMos28:near, tsl:near, mosint38:near

	public	scbstdcon, doESC, finstr

mos10	macro
	call	con10
	endm

getcrs0 macro
	call	getcrsx
	endm

;----------------------- Device Header ---------------------------------;

	org	0H
scbstdcon label byte
	dd	-1
	dw	1000000000000011B	; Char, STDIN, STDOUT
	dw	mos:constrat
	dw	mos:conintr
	db	'CON     '		; Standard CONsole device

ten	db	10		; Used for MUL

funtbl	dw	init		; 0  Init
	dw	donefun		; 1  Media check
	dw	donefun		; 2  Build BPB
	dw	donefun		; 3  I/O control input
	dw	input		; 4  Input (read)
	dw	ndinput 	; 5  Nondestructive input no wait
	dw	instat		; 6  Input status
	dw	inflsh		; 7  Input flush
	dw	output		; 8  Output (write)
	dw	output		; 9  Output with verify (same as output)
	dw	donefun 	; 10 Output status
	dw	donefun 	; 11 Output flush
	dw	donefun		; 12 I/O control output

	subttl	CONSTRAT - Console strategy routine
	page
;-----------------------------------------------------------------------;
;	This routine is the console drivers strategy routine, it just	;
;	queues the DWORD pointer to the request header. 		;
;									;
;  On Entry:								;
;	ES:BX points to the device request header.			;
;									;
;  On Exit:								;
;	The request header pointer is saved.				;
;									;
;	The pointer tcb$hdr is set in the current tasks TCB.		;
;	No global procedures called					;
;	No registers are changed					;
;-----------------------------------------------------------------------;
constrat proc	far
	assume	cs:mos,ds:nothing,es:nothing,ss:tcb

	mov	[tcb$hdr],bx		; Save pointer in active TCB
	mov	[tcb$hdr+2],es
	ret
constrat endp

	subttl	CONINTR - Console interrupt routine
	page
;-----------------------------------------------------------------------;
;	This is the console device drivers interrupt routine which will ;
;	process MOS's requested function.                               ;
;									;
;	No parms passed 						;
;	Return values							;
;	Global data affected						;
;	Global procedures called					;
;	What registers are changed					;
;-----------------------------------------------------------------------;

conintr proc	far
	push	ax
	push	bx
	push	cx
	push	dx
	push	es
	push	ds

	push	cs
	pop	ds
	assume	ds:mos

	les	bx,dword ptr [tcb$hdr]	; Get Request Header pointer
	mov	al,es:[bx+2]		; Get command code
	cmp	al,12		; Check for invalid call
	ja	err1		; Yes, exit with error
	xor	ah,ah
	mov	bx,offset funtbl
	shl	ax,1
	add	bx,ax
	call	[bx]		; Execute appropriate routine
rexit:
	pop	ds
	pop	es
	pop	dx
	pop	cx
	pop	bx
	pop	ax
	ret
err1:
	les	bx,dword ptr [tcb$hdr]	 ; Get Request Header pointer
	mov	word ptr es:[bx+3],8103H ; Return 'Unknown Command'
	jmp	rexit
conintr endp

	subttl	DONEFUN - DONE Function
	page
;-----------------------------------------------------------------------;
;	This routine processes any functions which are done. 		;
;	It is use for the following functions				;
;		Media Check, Build BPB, I/O Control Input		;
;		I/O Control Output, Output Status, Output Flush		;
;									;	No parms passed 						;
;	Return values are set in the Request Header			;
;	No global data affected 					;
;	No global procedures called					;
;	ES:BX used to point to RH					;
;-----------------------------------------------------------------------;

donefun	proc	near
	les	bx,dword ptr [tcb$hdr]	; Get pointer to RH
	mov	word ptr es:[bx+3],100H ; Return with 'DONE'
	ret
donefun	endp

	subttl	INPUT - Input read
	page
;-----------------------------------------------------------------------;
;	This routine processes the input read call (=4) 		;
;									;
;	No parms passed 						;
;	Return values are set in the Request Header			;
;	No global data affected 					;
;	No global procedures called					;
;	ES:BX used to point to RH					;
;-----------------------------------------------------------------------;
input	proc	near

	les	bx,dword ptr [tcb$hdr]	; Get pointer to RH
	mov	ax,es:[bx+14]		; Get offset transfer addrs
	mov	dx,es:[bx+16]	; Get seg transfer addrs
	mov	cx,es:[bx+18]	; Get byte count
	push	cx		; Save byte count for later return value
	mov	bx,ax		; Set buffer address
	mov	es,dx
	cmp	[tcbkboff],-1	; is in keys in translation buffer
	je	notrans
;
; handle keyboard translations here
;
	push	ds
	mov	si,[tcbkboff]		; get offset of translation
	mov	ds,[tcbkbansi]		; get translation buffer
tranloop:
	mov	al,byte ptr ds:[si]
	or	al,al			; are we done translations
	jz	donetrans
	mov	byte ptr es:[bx],al	; save into buffer
	inc	si
	inc	bx			; increment buffer pointer	
	dec	cx
	jnz	tranloop		; continue looping - count runs out 
;
; we done all we can do this time, save counter and return
;
	mov	[tcbkboff],si
	pop	ds
    	jmp	endin
donetrans:
	pop	ds
	mov	word ptr [tcbkboff],-1   ; should follow onto notrans
;
notrans:
	cmp	[tcb$kp],'Y'	; Is scan code pending read?
	jne	inloop
	mov	al,[tcb$hb]	; Get buffered scan code
	mov	es:[bx],al	; Put code in buffer
	mov	[tcb$kp],'N'	; Clear pending flag
	inc	bx		; Inc buffer pointer
	dec	cx		; Dec char count
	jnz	inloop
	jmp	endin
inloop:

;	SAH	05/24/88	Special code for INT 28 efficiency
;				only do int 28 if handler is install
;				and do special version of INT 16 which
;				waits for before exiting

	call	TestMos28	; test for mosint28 handler
	je	inskip				
;
;	Updated 03/24/89	We must set scbnoswt to zero before calling
;				safe28, so that if someone pamswitches out
;				while we are in this loop, that we allow
;				switching, this corrected a problem with
;				with Novell INT 28 handle which is not
;				designed how real INT 28 should be.
;
	push	ds
	MGetSCB ds
	assume  ds:grp
	mov	al,[scbnoswt]	; get current noswitch flag
	push	ax		; save current switch flag on stack

	public	in28loop
in28loop:
	mov	[scbnoswt],0
	call	safe28		; do int 28 while waiting for character
	mov	ah,1		; when TSR int 28 handler calls our int28
	int	16h		; we will suspend so that performance with
	jz	in28loop	; TSR's will be reasonable.
	pop	ax		; retrieve current switch flag off stack
	mov	[scbnoswt],al	; restore noswitch flag
	pop	ds
	assume	ds:mos
inskip:

;	SAH	05/24/88

	xor	ah,ah
	int	16H		; Get at least one keystroke
	call    KeyTrans	; translate key into sequence
	or	ax,ax		; Ctrl-Break?
	jnz	nobrk
	mov	ax,103H 	; Tell DOS Ctrl-C
nobrk:
	mov	es:[bx],al	; Put char in buffer
	or	al,al		; Extended key?
	jnz	noextn		; No
	mov	[tcb$hb],ah	; Save for later 
	mov	[tcb$kp],'Y'	; Set flag that scan code is buffered
noextn:
	inc	bx
	dec	cx
	jz	endin

	cmp	[tcb$kp],'Y'	; Is scan code pending read?
	jne	inloop
	mov	al,[tcb$hb]	; Get buffered scan code
	mov	es:[bx],al	; Put code in buffer
	mov	[tcb$kp],'N'	; Clear pending flag
	inc	bx		; Inc buffer pointer
	dec	cx		; Dec char count
	jz	endin
	mov	ah,1
	int	16H		; Check for any additional characters
	jnz	inloop		; Yes, get them
	pop	ax		; Original count
	sub	ax,cx		; Calc # read
	push	ax
endin:
	pop	cx			; Get byte count read
	les	bx,dword ptr [tcb$hdr]	; Get pointer to RH
	mov	es:[bx+18],cx		; Set byte count
	mov	word ptr es:[bx+3],100H ; Return 'Done'
	ret
input	endp

	 public  KeyTrans
KeyTrans proc	near
	cmp	byte ptr [tcbansi],0ffh
	jne	KTSkip
	cmp	word ptr [tcbkbansi],0
	je	KTSkip
	push	es
	mov	es,[tcbkbansi]
	cmp	word ptr es:[0],-1
	je	KTSkip2
;
;	 search for key in buffer if so make the translation
;
	push	bx
	push	dx
	push	di
	push	ax		; save current value of AX
	mov	bx,ax
	or	bl,bl		; is this extendend key sequence
	jz	KTHigh
	mov	bh,bl
	mov	bl,-1		; handle single key re-assigment
KTHigh:
	call	FindKeyR	; search for key in key assignment area
	jnc	KTFinish
	add	di,2
	xor	ah,ah
	mov	al,byte ptr es:[di]
	inc	di
	cmp	byte ptr es:[di],0
	je	KTsingle
	mov	[tcbkboff],di
KTSingle:
	pop	bx		; discard old ax
	push	ax		; place new ax on stack
KTFinish:
	pop	ax

	pop	di
	pop	dx
	pop	bx
KTSkip2:
        pop	es
KTSkip:
	 ret
KeyTrans endp


	subttl	NDINPUT - Nondestructive input no wait
	page
;-----------------------------------------------------------------------;
;	This routine processes the nondestructive input no wait call	;
;	(=5)								;
;									;
;	No parms passed 						;
;	Return values are set in the Request Header			;
;	No global data affected 					;
;	No global procedures called					;
;	ES:BX used to point to RH					;
;-----------------------------------------------------------------------;
ndinput proc	near
	les	bx,dword ptr [tcb$hdr]	; Get pointer to RH
	mov	al,[tcb$hb]		; Get buffered scan code
	cmp	[tcb$kp],'Y'	; Is scan code pending read?
	je	nobrk2		; Yes, return that
	mov	ah,1
	int	16H		; Test keyboard
	jz	ndend		; No char, exit
	or	ax,ax		; Break?
	jnz	nobrk2		; No
	mov	al,03		; Return Ctrl-C
nobrk2:
	cmp     ax,7200h	; Ctrl-PrtSc
	jne     noCps
	mov	al,10h		; set it to Cntrl-P
noCps:
	mov	es:[bx+13],al		; Return character
	mov	word ptr es:[bx+3],100H ; Return 'Done'
	ret
ndend:
	mov	word ptr es:[bx+3],300H ; Return 'Done' & 'Busy'
	ret
ndinput endp

	subttl	INSTAT - Input status
	page
;-----------------------------------------------------------------------;
;	This routine processes the Input Status call (=6)		;
;									;
;	No parms passed 						;
;	Return values are set in the Request Header			;
;	No global data affected 					;
;	No global procedures called					;
;	ES:BX used to point to RH					;
;-----------------------------------------------------------------------;

instat	proc	near
	les	bx,dword ptr [tcb$hdr]	; Get pointer to Request Header
	mov	word ptr es:[bx+3],100H ; Return 'Done - Char Ready'
	cmp	[tcb$kp],'Y'		; SAH scan-code pending
	je	instat0 		; if so skip the keyboard test
	push	ax			; save ax                      
	mov	ah, 1			; get keyboard status          
	int	016h			; call the keyboard handler    
	pop	ax			; restore ax                   
	jnz	instat0			; jump if character ready      
	mov	word ptr es:[bx+3],300H	; return 'Done - no Char Ready'
instat0:                                                               
	ret
instat	endp

	subttl	INFLSH - Input Flush
	page
;-----------------------------------------------------------------------;
;	This routine processes the Input Flush call (=7)		;
;									;
;	No parms passed 						;
;	Return values are set in the Request Header			;
;	No global data affected 					;
;	No global procedures called					;
;	ES:BX used to point to RH					;
;-----------------------------------------------------------------------;
inflsh	proc	near
	mov	ah,1		; Read any buffered characters
	int	16H
	jz	endflsh
	xor	ah,ah
	int	16H
	jmp	inflsh
endflsh:
	les	bx,dword ptr [tcb$hdr]	; Get pointer to RH
	mov	word ptr es:[bx+3],100H ; Return 'Done'
	ret
inflsh	endp

	subttl	OUTPUT - Output write
	page
;-----------------------------------------------------------------------;
;	This routine processes the Output write call (=8)		;
;									;
;	No parms passed 						;
;	Return values are set in the Request Header			;
;	No global data affected 					;
;	No global procedures called					;
;	ES:BX used to point to RH					;
;-----------------------------------------------------------------------;

output	proc	near
	public	outansi
outansi label	near

	push	bp		; Used in BIOS string writes
	push	di
	les	bx,dword ptr [tcb$hdr]	; Get pointer to RH
	mov	ax,es:[bx+14]		; Get offset transfer addrs
	mov	dx,es:[bx+16]	; Get seg transfer addrs
	mov	cx,es:[bx+18]	; Get byte count
	mov	bx,ax		; Set buffer address
;
; The following addition corrects problems with educational package
; which was directly poking the cursor position in bios and then
; call INT 21  function for write in graphics mode.  I fix the 
; problem by making sure the TCBCPOS had the current bios position
;
	MGetZero es
	mov	ax,word ptr es:[450h]
	mov	[tcbcpos],ax
;
	mov	es,dx
;
;	we will now test to see if ansi support is enable
;
	cmp	[tcbansi],0ffh
	je	charout
;
;	handle non-ansi processing. This is fast through 1 INT 10 call
;
	getcrs0 		; DX= cursor pos
	mov	bp,bx
	mov	bl,[tcb$ca]
	mov	ax,1301H	; String output with [char,char...] & move cur
	mov	bh,[tcbpage]
	mos10
	jmp	endout
;
;	Handle ansi emulation here.
;
charout:
	cmp	[tcb$ef],'Y'	; ESC sequence pending?
	jne	charout2
	jmp	[tcb$er]	; Yes
charout2:
	; Scan string for any ESC sequences before OUTPUTing
	; If found output up to ESC seq. and then process ESC seq.

	cld
	mov	di,bx
	push	cx		; Save count
	mov	al,27		; Scan for ESC
	repne scasb
	pop	cx		; Count back
	jne	finstr		; No ESCs, finish string output
ESCing:
	mov	[tcb$ef],'Y'	; Set ESC seq pending flag
	push	di		; Save string pointer
	dec	di		; Point to ESC
	sub	di,bx		; Calc # chars til ESC
	sub	cx,di		; Calc count for rest of string
	push	cx		; Save new count
	mov	cx,di		; Calc count before ESC
	or	cx,cx		; Is ESC the 1st char?
	jnz	finstr		; SAH
	jmp	ESConly		; SAH

finstr:
	getcrs0 		; DX= cursor pos
	mov	si,bx

lpwrap:
	push	dx
	mov	ah,2
	mov	bh,[tcbpage]		; set cursor position
	mos10	
	mov	al, byte ptr es:[si]
	cmp	al,13			; test for carriage-return
	je	wrapcr
	cmp	al,10			; test for line-feed
	je	wraplf	
	cmp	al,8  			; test for backspace	
	je	wrapbs
	cmp	al,7			; test for Bell
	je	wrapbell		
	push	cx
	mov	bl,[tcb$ca]
	mov	bh,[tcbpage]
	mov	cx,1			; 1 character at a time
	mov	ah,9			; display char
	mos10				; must use function 9 so attribute is
	pop	cx			; displayed
	pop	dx
;
;	after displaying character, we must test to see if we place character
;	at botton right corner, if so we must scroll screen
;
	inc	dl
	cmp	dl,[tcbcols]		; test to see if end of line
	jb	wpneol
;
	push	dx
	mov	ax,0e0dh
	mov	bl,[tcb$ca]
	mos10
wraplf:
	getcrs0 			; get cursor
	inc	dh
	cmp	dh,[tcbrows]
	jb	setlf
	call	wscroll 		; must scroll the screen, don't do it
	dec	dh
setlf:
	pop	ax			; discard old cursor position
	jmp	short wpneol
wrapbell:
	mov	bl,[tcb$ca]
	mov	ah,0eh			; write TTY
	mos10
wrapcont:
	pop	dx
	getcrs0
	jmp	short wpneol
wrapbs:
	pop	dx
	getcrs0
	or	dl,dl
	jz	wpneol
	dec	dl	    		; handle back space
	jmp	short wpneol	
wrapcr: 				; carriage return
	pop	dx
	xor	dl,dl			; reset to row 0
wpneol:
	inc	si			; point to next char
	dec	cx
	jcxz	wrapdone
	jmp	lpwrap			; wrap till you done
wrapdone:
	mov	ah,2
	mov	bh,[tcbpage]
	mos10				; set cursor pos	
	cmp	[tcb$ef],'Y'	; Is ESC seq pending?
	jne	endout		; No
ESConly:
	pop	cx		; Get size of new string
	pop	bx		; Get string pointer
	dec	cx		; Skip the ESC char itself
	or	cx,cx		; End of string?
	jz	endout		; Yes
	jmp	charout 	; Continue with rest of string
endout:
	les	bx,dword ptr [tcb$hdr]	; Get pointer to RH
	mov	word ptr es:[bx+3],100H ; Return 'Done'
	pop	di
	pop	bp
	ret

;
;   The following procedure is use to scroll the screen if necessary
;

wscroll proc	near
	push	cx
	push	dx
	mov	ax,0601h
	xor	cx,cx
	mov	dh,[tcbrows]
	dec	dh
	mov	dl,4fh
	mov	bh,[tcb$ca]
	push	dx
	mos10
	pop	dx
	mov	cx,dx
	xor	cl,cl
	mov	ax,0600h
	mov	bh,07h
	mos10
	pop	dx
	pop	cx
	ret
wscroll endp

;-----------------------------------------------------------------------;
; Increment current cursor position and wrap line if needed.		;
; BH = page on entry							;
;-----------------------------------------------------------------------;
curinc	proc	near

	push	dx
	getcrs0 		; Read cursor position
	inc	dl
	cmp	dl,80		; End of line?
	jne	lineok		; Not yet
	mov	ah,14
	mov	al,10		; Send LF and let BIOS do scroll if needed
	mov	bl,[tcb$ca]	; Attribute
	mov	bh,[tcbpage]
	mos10
	getcrs0
	xor	dl,dl
lineok:
	mov	ah,2		; Set new cursor position
	mov	bh,[tcbpage]
	mos10
	pop	dx
	ret

curinc	endp

con10	proc	near
        push    ds
        MGetZERO ds
        pushf
        cli
        call    dword ptr ds:[10H*4]
        pop     ds
	ret
con10	endp

;
; The following routine is use to get the current cursor position, for
; maximun performance, if INT 10h intercept points to MOS's kenrel 
; than return value at TCBCPOS
;

	public	getcrsx
getcrsx	proc	near
	push	ds
	push	ax
	push	bx
	push	cx

	MGetZero ds
	mov	ah,3
	mov	bh,[tcbpage]
        pushf
        cli
        call    dword ptr ds:[10H*4]

	pop	cx
	pop	bx
	pop	ax
	pop	ds
	ret
getcrsx	endp

;-----------------------------------------------------------------------;
; The following table is used to check for valid characters in an ESC	;
; sequence.  If any of the characters in the 1st part of the table are	;
; received then the sequence is processed.  If any of the characters	;
; in the 2nd part of the table are received then they are buffered	;
; until a terminator is received.					;
;-----------------------------------------------------------------------;

seqtbl	db	'HABCDfnsuJKmhlp'	; Valid ANSI function terminators
seqrtn	db	'1234567890;=?' 	; Valid characters in ESC sequence
seqlen	equ	$ - mos:seqtbl		; Used to set up scan length

;-----------------------------------------------------------------------;
; This table is used for the address look up of the appropriate routine ;
; to call for each ESC sequence supported by the ANSI standard. 	;
;-----------------------------------------------------------------------;
rtntbl	dw	esCpos		; H  Cursor position
	dw	esCup		; A  "   up
	dw	esCdn		; B  "   down
	dw	esCfwd		; C  "   forward
	dw	esCbak		; D  "   backward
	dw	esChvp		; f  "   horz and vert position
	dw	esstat		; n  device status report
	dw	esCsav		; s  Save cursor position
	dw	esCrst		; u  Restore cursor position
	dw	esCLS		; J  Clear screen (Erase in Display)
	dw	esEOL		; K  Clear to End Of Line
	dw	esSGR		; m  Set Graphics Rendition
	dw	esSM		; h  Set Mode
	dw	esRM		; l  Reset Mode
	dw	esKeyR		; p  Key Reassignment

;-----------------------------------------------------------------------;
doESC:
	mov	al,es:[bx]	; Get 1st char of ESC seq
	inc	bx
	cmp	al,'['		; Check for valid seq
	je	$+5
	jmp	ESCabort	; Invalid sequence, abort
	mov	[tcb$er],offset mos:doESC2
	jmp	ESCexit
doESC2:
	mov	al,es:[bx]
	inc	bx
	push	es
	push	di
	push	cx
	mov	cx,cs		; For SCANing local table
	mov	es,cx
	assume	es:nothing

	cmp	al,'"'		; Double quotes need special consideration
	jne	noQuote
	xor	[tcb$iq],1	; Toggle quote switch
	jmp	dobuffer
noQuote:
	cmp	[tcb$iq],0	; Are we inside a quote?
	jne	dobuffer	; Yes, just buffer what ever it is

	mov	di,offset seqtbl ; Scan for valid character in seq.
	mov	cx,seqlen
	repne	scasb		; Scan while AL NE to any char in string
	je	charok
	jmp	ESC2end 	; Invalid sequence
charok:
	cmp	di,offset mos:seqrtn	; Is this char a sequence terminator?
	ja	dobuffer		; No, just buffer it
	push	di			; Buffer ESC terminator
	mov	di,[tcb$ebp]		; Get current buffer pointer
	xor	ah,ah			; Assure buffer terminated by 0
	push	es
	push	ss
	pop	es			; STOS cannot be overridden
	stosw
	pop	es
	dec	di			; Point to term 0 for next input
	mov	[tcb$ebp],di		; Update new pointer
	pop	di
	dec	di			; Correctly point to char that matched
	sub	di,offset mos:seqtbl	; Calc char offset in table
	shl	di,1
	push	ds
	push	ss
	pop	ds
	assume	ds:tcb
	call	[rtntbl+di]		; Transfer to appropriate routine
	pop	ds
	assume	ds:mos
	mov	[tcb$er],offset mos:doESC
	mov	[tcb$ef],'N'		; No sequence now pending
	jmp	ESC2end
dobuffer:
	mov	di,[tcb$ebp]	; Get current buffer pointer
	xor	ah,ah			; Assure buffer terminated by 0
	push	es
	push	ss
	pop	es			; STOS cannot be overridden
	stosw
	pop	es
	dec	di			; Point to term 0 for next input
	mov	[tcb$ebp],di	; Update new pointer
ESC2end:
	pop	cx
	pop	di
	pop	es
	jmp	ESCexit

;-----------------------------------------------------------------------;
ESCabort:
	mov	[tcb$er],offset mos:doESC
	mov	[tcb$ef],'N'	; No sequence now pending
	mov	ah,14		; TTY output
	push	bx
	mov	bl,[tcb$ca]	; Attribute
	mov	bh,[tcbpage]
	mos10
	pop	bx
ESCexit:
	dec	cx
	jnz	contout
	jmp	endout		; No more to output, end
contout:
	jmp	charout 	; Continue with character output

output	endp

;-----------------------------------------------------------------------;
; This routine will retreive the one or two digit ASCII number pointed	;
; to by DS:SI and translate it to binary then return the result in AL	;
; On entry AL = ESC terminator for this sequence.			;
;-----------------------------------------------------------------------;
	assume	ds:tcb,es:nothing,ss:tcb
dec2bin proc	near

	push	bx
	mov	bh,al		; ESC terminator
	mov	bl,1		; Set default
	mov	al,[si] 	; Get 1st num
	cmp	al,'0'		; Check for valid range
	jb	ckbad
	cmp	al,'9'
	ja	ckbad
	sub	al,'0'		; Calc binary
	mov	bl,al		; Set new default
	inc	si
	mov	al,[si] 	; Get 1st num
	cmp	al,'0'		; Check for valid range
	jb	ckbad
	cmp	al,'9'
	ja	ckbad
	sub	al,'0'		; Calc binary
	xchg	al,bl
	mul	[ten]
	add	al,bl
	inc	si		; Point to next char after numbers
;
;	handle 3 digit numbers
;
	cmp	byte ptr [si],'9'
	ja	digit2
	cmp	byte ptr [si],'0'
	jb	digit2
	mul     [ten]
	add	al,byte ptr [si]
	sub	al,'0'
	inc	si
digit2:
	pop	bx
	ret
ckbad:
	cmp	al,';'		; Delimiter?
	jne	ckseqend	; No, check for sequence end
seqterm:
	mov	al,bl
	pop	bx
	clc			; No errors return flag
	ret
ckseqend:
	cmp	al,bh		; Is this the end of the sequence
	je	seqterm 	; Yes
	stc			; Set error return flag
	pop	bx
	ret

dec2bin endp

;-----------------------------------------------------------------------;
; Process 'Cursor Position'						;
; On entry tcb$eb holds characters between '[' and terminating char	;
;-----------------------------------------------------------------------;
	assume	ds:tcb,es:nothing,ss:tcb
esCpos	proc	near
	push	bx
	push	cx
	push	dx
	push	si

	mov	al,'H'		; ESC terminator  (require for Dec2bin)

	mov	si,offset tcb$eb
	call	dec2bin 	; Get row number in AL
	jnc	esCpos1
	jmp	errCpos
esCpos1:
	or	al,al		; 0 is the same as 1
	jz	esCpos2
	dec	al
esCpos2:
	mov	dh,al
semiskp:
	cmp	byte ptr [si],';'	; Check for ';'
	jne	getcol
	inc	si		; Skip ';'
	jmp	semiskp
getcol:
	mov	al,'H'		; ESC terminator
	call	dec2bin 	; Get col num
	jnc	esCpos3
	jmp	errCpos
esCpos3:
	or	al,al		; 0 is the same as 1
	jz	esCpos4
	dec	al
esCpos4:
	mov	dl,al
	mov	bh,[tcbpage]
	mov	ah,2
	mos10
	pop	si
	pop	dx
	pop	cx
	pop	bx
seqexit:
	push	dx
	mov	dx,offset tcb$eb
	mov	[tcb$ebp],dx	; Reset buffer pointer
	pop	dx
	ret
errCpos:
	pop	si
	pop	dx
	pop	cx
	pop	bx
	jmp	seqexit
esCpos	endp

;-----------------------------------------------------------------------;
; Process 'Cursor Up'							;
; On entry tcb$eb holds characters between '[' and terminating char	;
;-----------------------------------------------------------------------;
	assume	ds:tcb,es:nothing,ss:tcb
esCup	proc	near
	push	bx
	push	cx		; Set in fun 3 of INT 10H
	push	dx
	push	si
	getcrs0
	mov	si,offset tcb$eb
	mov	al,'A'		; ESC terminator
	call	dec2bin 	; Get row number in AL
	jc	errCup
	sub	dh,al
	jnc	doCup
	xor	dh,dh
doCup:
	mov	ah,2
	mov	bh,[tcbpage]
	mos10
errCup:
	pop	si
	pop	dx
	pop	cx
	pop	bx
	jmp	seqexit
esCup	endp

;-----------------------------------------------------------------------;
; Process 'Cursor Down' 						;
; On entry tcb$eb holds characters between '[' and terminating char	;
;-----------------------------------------------------------------------;
	assume	ds:tcb,es:nothing,ss:tcb
esCdn	proc	near
	push	bx
	push	cx		; Set in fun 3 of INT 10H
	push	dx
	push	si
	getcrs0
	mov	si,offset tcb$eb
	mov	al,'B'		; ESC terminator
	call	dec2bin 	; Get row number in AL
	jc	errCdn
	add	dh,al
	cmp	dh,[tcbrows]	; Going off screen?
	jb	doCdn		; No
	mov	dh,[tcbrows]	; Set to last line
	dec     dh
doCdn:
	mov	ah,2
	mov	bh,[tcbpage]
	mos10
errCdn:
	pop	si
	pop	dx
	pop	cx
	pop	bx
	jmp	seqexit
esCdn	endp

;-----------------------------------------------------------------------;
; Process 'Cursor Forward'						;
; On entry tcb$eb holds characters between '[' and terminating char	;
;-----------------------------------------------------------------------;
	assume	ds:tcb,es:nothing,ss:tcb
esCfwd	proc	near
	push	bx
	push	cx		; Set in fun 3 of INT 10H
	push	dx
	push	si
	getcrs0
	mov	si,offset tcb$eb
	mov	al,'C'		; ESC terminator
	call	dec2bin 	; Get row number in AL
	jc	errCfwd
	add	dl,al
	cmp	dl,79
	jbe	doCfwd
	mov	dl,79
doCfwd:
	mov	ah,2
	mov	bh,[tcbpage]
	mos10
errCfwd:
	pop	si			   
	pop	dx
	pop	cx
	pop	bx
	jmp	seqexit
esCfwd	endp

;-----------------------------------------------------------------------;
; Process 'Cursor Back' 						;
; On entry tcb$eb holds characters between '[' and terminating char	;
;-----------------------------------------------------------------------;
	assume	ds:tcb,es:nothing,ss:tcb
esCbak	proc	near
	push	bx
	push	cx		; Set in fun 3 of INT 10H
	push	dx
	push	si
	getcrs0
	mov	si,offset tcb$eb
	mov	al,'D'		; ESC terminator
	call	dec2bin 	; Get row number in AL
	jc	errCbak
	sub	dl,al
	jnc	doCbak
	xor	dl,dl
doCbak:
	mov	ah,2
	mov	bh,[tcbpage]
	mos10
errCbak:
	pop	si
	pop	dx
	pop	cx
	pop	bx
	jmp	seqexit
esCbak	endp

;-----------------------------------------------------------------------;
; Process 'Horizontal and Vertical Position'				;
; On entry tcb$eb holds characters between '[' and terminating char	;
;-----------------------------------------------------------------------;
	assume	ds:tcb,es:nothing,ss:tcb
esChvp	proc	near
	push	di
	mov	di,[tcb$ebp]
	mov	byte ptr [di-1],'H'
	pop	di
	jmp	esCpos		; This does the same thing
esChvp	endp

;-----------------------------------------------------------------------;
; Process 'Device Status Report'					;
; On entry tcb$eb holds characters between '[' and terminating char	;
;-----------------------------------------------------------------------;
	assume	ds:tcb,es:nothing,ss:tcb
esstat	proc	near
; SAH   06/21/88        Implement Status Report

        push    cx
        mov     cx,011bh        ; send an ESC
        call    setbyte
        mov     cl,'['          ; send a bracket
        mov     ch,1ah          ; scan code for bracket
        call    setbyte
        getcrs0         
        mov     al,dh		
        inc     al
        call    covdec		; convert row into decimal
        mov     cl,ah
        call    makescan	; send upper byte to keyboard	
        mov     cl,al
        call    makescan	; send lower byte to keyboard
        mov     cl,';'          ; send a semi-colon     
        mov     ch,27h          ; scan code for semi-colon
        call    setbyte
        mov     al,dl
        inc     al
        call    covdec		; convert column to keyboard
        mov     cl,ah
        call    makescan	; send upper byte to keyboard
        mov     cl,al
        call    makescan	; send lower byte to keyboard
        mov     cl,'R'          ; send a 'R'
        mov     ch,13h          ; scan code for 'R'     
        call    setbyte
        mov     cx,1c0dh        ; send a carriage return
        call    setbyte
        pop     cx

        jmp     seqexit

makescan:		
        mov     ch,0bh		; make scan code for '0' - '9' 
        cmp     cl,'0'
        je      setbyte
        mov     ch,cl
        sub     ch,2fh

setbyte:			; place byte in keyboard
        push    ax
        push    dx
        push    ds

        MGetZERO ds
        
        mov     ah,5
        pushf
        call    dword ptr ds:[16h*4]

        pop     ds
        pop     dx
        pop     ax
        ret

covdec:				; convert al in decimal digit in AX
        xor     ah,ah
covdec1:
        cmp     al,0ah
        jb      covdec2
        sub     al,0ah
        inc     ah
        jmp     short covdec1
covdec2:
        add     ax,3030h
        ret

; SAH   06/21/88        End of status report implementation

esstat	endp

;-----------------------------------------------------------------------;
; Process 'Save Cursor Position'					;
; On entry tcb$eb holds characters between '[' and terminating char	;
;-----------------------------------------------------------------------;
	assume	ds:tcb,es:nothing,ss:tcb
esCsav	proc	near
	push	bx
	push	cx
	push	dx
	getcrs0
	mov	[tcb$tcp],dx	; Save cursor position for later recall
	pop	dx
	pop	cx
	pop	bx
	jmp	seqexit
esCsav	endp

;-----------------------------------------------------------------------;
; Process 'Restore Cursor Position'					;
; On entry tcb$eb holds characters between '[' and terminating char	;
;-----------------------------------------------------------------------;
	assume	ds:tcb,es:nothing,ss:tcb
esCrst	proc	near
	push	bx
	push	dx
	mov	ah,2
	mov	bh,[tcbpage]
	mov	dx,[tcb$tcp]	; Get saved position
	mos10
	pop	dx
	pop	bx
	jmp	seqexit
esCrst	endp

;-----------------------------------------------------------------------;
; Process 'Erase in Display'						;
; On entry tcb$eb holds characters between '[' and terminating char	;
;-----------------------------------------------------------------------;
	assume	ds:tcb,es:nothing,ss:tcb
esCLS	proc	near
        push    bx
        push    cx
        push    si              	; SAH 
        mov     si,offset [tcb$eb]     	; SAH 06/21/88
        mov     ax,0600H        	; Do a 'CLS'
	mov	bh,[tcb$ca]     	; use current attribute to blank lines
        xor     cx,cx
        cmp     byte ptr [si],'0'       ; SAH test for ESC [0J
        jne     esCLS1                  ; SAH
        mov     cx,[tcbcpos]            ; SAH get current cursor pos
	mov	dx,cx
	mov	dl,4fh
	push	ax
	push	bx
	push	cx
	push	dx
	mos10				; clear to end of line
	pop	dx
	pop	cx
	pop	bx
	pop	ax
	inc	ch
	cmp	ch,[tcbcols]		; last column
	jae	esCLS2			; don't clear the window below
	xor	cl,cl			; clear row
esCLS1:                                 ; SAH
        mov     dl,04fh
        mov     dh,[tcbrows]
        dec     dh
        mos10
        cmp     byte ptr [si],'0'       ; SAH   don't home cursor
        je      esCLS2                  ; SAH
        mov     bh,[tcbpage]
        mov     ah,2            	; Home cursor
        xor     dx,dx
        mos10
esCLS2:                                 ; SAH
        pop     si                      ; SAH
        pop     cx
        pop     bx      
        jmp     seqexit
esCLS	endp

;-----------------------------------------------------------------------;
; Process 'Erase in Line'						;
; On entry tcb$eb holds characters between '[' and terminating char	;
;-----------------------------------------------------------------------;
	assume	ds:tcb,es:nothing,ss:tcb
esEOL	proc	near
	push	bx
	push	cx
	push	dx
	getcrs0
	mov	al,[tcbcols]
	sub	al,dl		; Calc # chars to end of line
	mov	cl,al
	xor	ch,ch		; CX = number of spaces to write
	mov	ah,9		; Write char/attr
	mov	bh,[tcbpage]
	mov	al,' '		; Write spaces
	mov	bl,[tcb$ca]	; Write char with active attribute
	mos10
	pop	dx
	pop	cx
	pop	bx
	jmp	seqexit
esEOL	endp

;-----------------------------------------------------------------------;
; Process 'Set Graphics Rendition'					;
; On entry tcb$eb holds characters between '[' and terminating char	;
;-----------------------------------------------------------------------;
	assume	ds:tcb,es:nothing,ss:tcb
esSGR	proc	near
	push	bx
	push	cx
	push	dx
	push	si

	mov	si,offset tcb$eb
attrlp:
	mov	al,'m'		; ESC terminator
	call	dec2bin 	; Get next attr
	jnc	attrsk
	jmp	errSGR
attrsk:
	call	SetAttr 	; Process attribute
	jnc	semskp
	jmp	errSGR		; Invalid selection
semskp:
	cmp	byte ptr [si],';'	; Check for ';'
	jne	getnxt
	inc	si			; Skip ';'
	jmp	semskp
getnxt:
	cmp	byte ptr [si],'m'	; ESC terminator?
	jne	attrlp			; Process as many as specified
errSGR:
	pop	si
	pop	dx
	pop	cx
	pop	bx
	jmp	seqexit

;-----------------------------------------------------------------------;
; Set 'tcb$ca' according to ANSI SGR value passed in AL 		;
;-----------------------------------------------------------------------;
	;FG	30     31     32     33     34	   35	  36	 37
	;FG	black  red    green  yellow blue   magta  cyan	 white

attvals db	0,0f8H,4,0f8H,2,0f8H,6,0f8H,1,0f8H,5,0f8H,3,0f8H,7,0f8H

	;BG	40     41      42      43      44      45      46      47
	;BG	black  red     green   yellow  blue    magta   cyan    white

	db	00,8fH,40H,8fH,20H,8fH,60H,8fH,10H,8fH,50H,8fH,30H,8fH,70H,8fH



	assume	ds:tcb,es:nothing,ss:tcb

SetAttr proc	near
	cmp	al,0		; Normal?
	jne	attr1
	clc
attr0:
	mov	[tcb$ca],7	; Set normal
	ret
attr1:
	cmp	al,1		; Bold?
	jne	attr2
	or	[tcb$ca],8	; Set high intensity bit
	clc
	ret
attr2:
	cmp	al,4		; Underscore?
	jne	attr3
	and	[tcb$ca],0f8H	; Clear low 3 bits
	or	[tcb$ca],01	; Set low bit
	clc
	ret
attr3:
	cmp	al,5		; Blink?
	jne	attr4
	or	[tcb$ca],80H	; Set blink bit
	clc
	ret
attr4:
	cmp	al,7		; Reverse?
	jne	attr5
	and	[tcb$ca],88H	;
	or	[tcb$ca],70H	; Set to inverse
	clc
	ret
attr5:
	cmp	al,8		; Invisible?
	jne	attr6
	mov	[tcb$ca],0	;
	clc
	ret
attr6:
	cmp	al,30		; Validate range
	jb	attinvl 	; Invalid
	cmp	al,37
	jb	attrok
	cmp	al,40
	jb	attinvl
	cmp	al,47
	ja	attinvl
	sub	al,2		; 38 and 39 invalid
attrok:
	sub	al,30		; Calc offset into table
	xor	ah,ah
	push	bx
	mov	bx,ax		; Calc offset into table
	shl	bx,1			 ; Word entries
	mov	ax,word ptr [attvals+bx] ; Get mask and setting
	pop	bx
	and	[tcb$ca],ah	; Clear nibble for attr
	or	[tcb$ca],al	; Set attr
	clc
	ret
attinvl:
	stc
	jmp	short attr0

SetAttr endp

esSGR	endp

;-----------------------------------------------------------------------;
; Process 'Set Mode'							;
; On entry tcb$eb holds characters between '[' and terminating char	;
;-----------------------------------------------------------------------;
	assume	ds:tcb,es:nothing,ss:tcb
esSM	proc	near
	
;	SAH	12/01/87	Start of additions to set wrap EOL mode

	push	si
	mov	si,offset tcb$eb	; access buffer
	cld
	lodsb
	cmp	al,'?'		; check for ? of ?7
	jne	esSM1		; no..skip
	lodsb
	cmp	al,'7'		; check for 7 of ?7
	jne	esSM1		; no..skip
	mov	[tcb$wrap],'Y'	; set EOL wrap mode
esSM1:
	pop	si

;	SAH	12/01/87	end of addtitions

	jmp	seqexit
esSM	endp

;-----------------------------------------------------------------------;
; Process 'Reset Mode'							;
; On entry tcb$eb holds characters between '[' and terminating char	;
;-----------------------------------------------------------------------;
	assume	ds:tcb,es:nothing,ss:tcb
esRM	proc	near

;       SAH     12/01/87        Start of additions to set wrap EOL mode

        push    si
        mov     si,offset tcb$eb       ; access buffer
        cld
        lodsb
        cmp     al,'?'          ; check for ? of ?7
        jne     esRM1           ; no..skip
        lodsb
	cmp	al,'7'          ; check for 7 of ?7
        jne     esRM1           ; no..skip
        mov     [tcb$wrap],'N'  ; reset EOL wrap mode
esRM1:
        pop     si

;       SAH     12/01/87        end of addtitions

	jmp	seqexit

esRM	endp

;-----------------------------------------------------------------------;
; Process 'Keyboard Reassignment'					;
; On entry tcb$eb holds characters between '[' and terminating char	;
;-----------------------------------------------------------------------;
	assume	ds:tcb,es:nothing,ss:tcb
	public  esKeyR
esKeyR	proc	near
	push	bp
	push	di
	push	es

; first we must find end of list

	cld
	mov	es,[tcbkbansi]

; now we need to gather information from ESC command line

	mov	al,'p'		; ESC terminator
	mov	si,offset tcb$eb
	call	dec2bin 	; Get first key value
	jnc	esKR1
	jmp	outky
esKR1:
	mov	[tcbkbanhi],0ffh	; indicate 0ffh for single value
	or	al,al			; if non-zero than value must 
	jnz	esKR2			; single keyboard translation
	mov	[tcbkbanhi],al
esKRs1:
	cmp	byte ptr [si],';'	; Check for ';'
	jne	esKRs2
	inc	si		; Skip ';'
	jmp	short esKRs1
esKRs2:
	call	dec2bin		; Get second key value
	jnc	esKR2
	jmp	outky
esKR2:
      	mov	[tcbkbanlow],al
	push	bx
	mov	bh,al		; note low is store above
	mov	bl,[tcbkbanhi]  ; get high value
	call	FindKeyR	; is keystroke store already
	pop	bx
	jnc     esKRct
;
;	we have found key store in buffer, remove sequence from buffer
;
	push	si
	mov	si,di
	add	si,2		; point past keyboard values
esKRs0:
	cmp	byte ptr es:[si],0	; search for 0 past list
	je	esKRf0
	inc	si
	jmp	short esKRs0
esKRf0:
	inc	si
;
;	now for every non-zero word at es:si, copy to es:di
;
esKRrlp:
	mov	ax,word ptr es:[si]
	mov	word ptr es:[di],ax
	cmp	ax,-1 			; end of replacement
	je	esKRcout
	add	si,2
	add	di,2
	cmp	si,63
	jbe	esKRrlp
esKRcout:
	mov	word ptr es:[di+2],-1	; fore a termination at end
	pop	si
esKRct:
	call	FindEndR	; refind end of keyboard re-assignment list
	mov	bp,di		; save end just in case of error
	cmp	di,62		; check for boandary errors
	ja	errky		; overboard...don't kill the smp
	mov	al,[tcbkbanlow]	; get low value
	stosb
	mov	al,[tcbkbanhi]	; get high value
	stosb

; at this point we will need to process the key statements
; as "string" or DEC ASCII numbers, seperated by ; and terminate with 'p'

esKRloop:	
	lodsb
	cmp	al,';'		; seperator...ignore
	je	esKRloop
	cmp	al,'p'		; have we reach the terminator
	je	contky
	cmp	al,'"'		; is this quate
	je	esKRstr		
	dec	si		; account for the lodsb above
	call	dec2bin		; must be decimal
	jc	errky
	cmp	di,63		; over the limit
	jae	errky
	stosb			; store value in
	jmp	short esKRloop
esKRstr:
	lodsb
	cmp	al,'"'		; end string terminator
	je 	esKRLoop	; yes...then back to main loop
	cmp	di,63		; over the limit
	jae	errky
	stosb			; store value in table
	jmp	short esKRstr	; loop back for next value in string
errky:
	mov	di,bp		; error....so mark start as clear position
	jmp	short outky2
contky:
	cmp	di,61		; make sure that we can't overlap into
	jae	errky		; next smp block
	xor	al,al
	stosb
outky2:
	mov	ax,-1
	stosw			; clear so next search will place here
outky:
      	pop	es
	pop	di
	pop	bp
	jmp	seqexit

esKeyR	endp

;
; The following procedure is use to search for key sequece in the keyboard
; re-assigment list (key to search for is in tcbkbanlow and tcbkbanhi
;

FindKeyR proc	near
	xor	di,di
FKeyLoop:
	cmp	word ptr es:[di],-1	; key-assigment stored
	je	FKeyErr
	cmp	byte ptr es:[di],bh
	jne	FKeyNext	
	cmp	byte ptr es:[di+1],bl
	jne	FKeyNext		
	stc				; we have found, return position
	ret
FKeyNext:
	add	di,2			; point past keys
FKeyNloop:
	cmp	byte ptr es:[di],0	; key-assigment terminate found
	je	FKeyNEnd		
	inc	di
	jmp	short FKeyNloop		; continue scanning for terminator
FKeyNEnd:
	inc	di				
	jmp	short FkeyLoop		; go and search next string
FKeyErr:
	clc
	ret
FindKeyR endp

;
; The following procedure is use to find the end of keyboard re-assignment
; list
;

FindEndR proc	near
	xor	di,di
FEndLoop:
	cmp	word ptr es:[di],-1	; find end of list
	je	FEndEnd
	inc	di
	jmp	short FEndLoop
FEndEnd:
	 ret
FindEndR endp

endres	label	byte

	subttl	INIT - Init driver
	page
;-----------------------------------------------------------------------;
;	This routine will initialize the console device driver. 	;
;									;
;	No Parms passed 						;
;	No Return values						;
;	No Global data affected 					;
;	No Global procedures called					;
;	What registers are changed					;
;-----------------------------------------------------------------------;
	assume	ds:mos,es:nothing,ss:tcb

init	proc	near
	mov	bx,[tcb$hdr]	; Get Request Header pointer
	mov	dx,offset endres
	mov	es:[bx+14],dx	; Set ending address of driver
	mov	es:[bx+16],cs
	mov	word ptr es:[bx+3],100H ; Return with 'DONE'
	ret				; End of INIT
init	endp

mosseg	ends
	end

