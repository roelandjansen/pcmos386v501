	include PAGE.INC
	title	MOSDEBUG.ASM - Debug information output routine

;-----------------------------------------------------------------------;
;									;
;		Development Specification				;
;									;
;									;
; Program Name: MOS.COM			Assigned to: David Morrow	;
; Module Name:	MOSDEBUG		Assign date: 08/29/86		;
; Entry Points: MOSDEBUG		Completed:           		;
; Entry From:	Anyone and Everyone					;
; Entry Method:	Call							;
; Calls:	No one							;
; Purpose:	To output debug information in specified format		;
; Refer to:	n/a							;
; Last Update:	11/04/86						;
;									;
;   04/20/87   SAH   Added SMP Heap checking option for debugging       ;
;   06/19/87   SAH   Added MCB Checking and optional dumping		;
;   07/11/87   SAH   Added Interupt 38 Support				;
;   10/20/87   SAH   Remove internal debugger for production version    ;
;   01/22/88   SAH   Change SCBSEG and ZERO seg to MGetXXXX macros	;
;-----------------------------------------------------------------------;
; sah\rdr 02/21/88 Move DDT Segment to MO2 Group			;
;-----------------------------------------------------------------------;
; SAH	05/19/88  Change removal of MCB stuff to conditional assembly   ;
;-----------------------------------------------------------------------;
	include GROUP.INC
	include OPTIONS.INC
	.xlist
	subttl	group segments and include block definitions
	page

;-----------------------------------------------------------------------;
; access to partition saved registers					;
;-----------------------------------------------------------------------;
	include	MOSREGS.INC


tcb	segment at 1234h
	include	MOSTCB.INC	; TCB definition
tcb	ends

gdata	segment	word public 'data'
	include	MOSSCBEX.INC	; specify all SCB items as external
gdata	ends

irq	segment	byte public 'data'
irq	ends

poll	segment	byte public 'data'
poll	ends

ddt     segment word public 'code2'
ddt     ends

mosseg	segment	word public 'code1'
	assume	cs:mos,ds:nothing,es:nothing,ss:nothing

	extrn	mosend:byte, sbios:word, scbfree:word
	extrn   ChkHeap:near

;	extrn	MBcheck:near

	public	hex2asc

	if	MDEBUG eq 1
	public mosdebug, dec2asc, mosSIMck, mosSIM, int38p
	endif

;;	include	mosdebug.pub

MTRACE  equ 	0		; true if MCB Trace included
FCBDUMP	equ	0		; do fcbdumps if true

if	MDEBUG eq 1
	.list
	subttl	MOSDebug - Output debug information

	page
;-----------------------------------------------------------------------;
; This routine will output a debug message to one of the following:	;
; the screen, an alternate screen, or a serial port (depending on the	;
; setting of the CONFIG.SYS command DBPORT).  If requested by		;
; the calling routine a full register dump will be performed.  The	;
; calling routine may also request a key press or even an 'Abort or 	;
; Ignore' prompt.							;
;									;
;  On Entry:								;
;	DS:DX -> message to display terminated by a '$'			;
;									;
;	AL = command list (bitwise)					;
;		bit 0 - Display full register dump			;
;		bit 1 - Prompt for 'Abort or Ignore'			;
;		bit 2 - Pause for keypress (ignored if bit 1=1)		;
;		bit 3 - Test for key input, return in AL (0 if none)	;
;		bit 4 - Use Task registers for regdump			;
;		bit 5 - Interupt 38 to be process (0 if not int 38)     ;
;		bit 6 - undefined					;
;		bit 7 - undefined 					;
;									;
;	SP+6 -> original AX (pushed before CALLing MOSDebug)		;
;	SP+4 -> original DS 	"	"	"	"		;
;	SP+2 -> original DX	"	"	"	"		;
;									;
;	The idea here that AX, DS and DX are saved on the stack before	;
;	being pointed to a message to display.				;
;									;
;  On Exit:								;
;	AL = ASCII of key pressed (if bit 2 set on entry)		;
;	CF = 0 for Ignore or 1 for Abort (if bit 1 set on entry)	;
;	DS and DX are cleared from the stack (no need to POP them)	;
;									;
;	No Global data affected						;
;	No Global procedures called					;
;	All registers preserved (AX, DS and DX are restored to pre-Call	;
;	value except where AL is supposed to return a value)		;
;-----------------------------------------------------------------------;
SIMhk	db	'@'		; SIM hotkey
SIMon	db	'On $'
SIMoff	db	'Off$'

SIMmen	db	13,10,'--  System Input Monitor  --',13,10
	db	13,10,'1) Toggle reg dump on funs 0-C  $'
SIMm2	db	13,10,'2) Toggle reg dump on funs D-30 $'
SIMm3	db	13,10,'3) Toggle reg dump on funs 31+  $'
SIMm4	db	13,10,'4) Toggle pause on INT 21 entry $'
SIMm5	db	13,10,'5) Toggle pause on INT 21 exit  $'
SIMm6	db	13,10,'6) Toggle MOS internal INT 21s  $'
SIMm7   db      13,10,'7) Toggle MOS Interupt 38 Calls $'
SIMm8   db      13,10,'8) Toggle MOS SMP heap checking $'
SIMm9   db      13,10,'9) Toggle MOS MCB Checking      $'
SIMmp	db	13,10,13,10,'Choice or <RET> to end?$'
SIMcr	db	13,10,'$'

regmsg	db	13,10,'AX='
regdata	db	'0000  BX=0000  CX=0000  DX=0000  '
	db	'SP=0000  BP=0000  SI=0000  DI=0000',13,10
	db	'DS=0000  ES=0000  SS=0000  CS=0000  '
	db	'IP=0000   '
regf	db	'OV DN EI NG ZR AC PE CY ',13,10,'$'

		;=1 =0
flagdat	db	'OV NV '	; Overflow
	db	'DN UP '	; Direction
	db	'EI DI '	; Interrupt
	db	'NG PL '	; Sign
	db	'ZR NZ '	; Zero
	db	'AC NA '	; Auxiliary carry
	db	'PE PO '	; Parity
	db	'CY NC '	; Carry

flgtst	dw	800H		; Overflow	\
	dw	400H		; Direction	 \
	dw	200H		; Interrupt	  \
	dw	 80H		; Sign		   \ Bit positions
	dw	 40H		; Zero		   /
	dw	 10H		; Aux carry	  /
	dw	  4H		; Parity	 /
	dw	  1H		; Carry		/
	dw	0		; List terminator

regflg	dw	0
saveAX	dw	0		; Save space

	; This byte is local (input only from the debug port)
lstread	db	0		; Last read serial char

smpchk  db	0		; smp heap checking
mcbchk  db      0		; MCB checking
int38p	db      0		; interupt 38 processing

msgAbIg	db	'Abort or Ignore?$'
msgabrt	db	' Abort',13,10,'$'
msgignr	db	' Ignore',13,10,'$'

MCBbad  db      13,10,'MCB Chain is corrupted',13,10,'$'
I38msg  db      13,10,'MOS Extended Interupt 38H Function Calls$'

if	FCBDUMP
msgcr	db	13,10,'$'

msgaddr	db	'xxxx:xxxx  '
msgdta	db	'xx xx xx xx xx xx xx xx-xx xx xx xx xx xx xx xx   '
msgadta	db	'xxxxxxxxxxxxxxxx',13,10,'$'
endif

;-----------------------------------------------------------------------;
MOSDebug proc	near
	
	assume	ds:nothing, es:nothing	; It could be ANYTHING!
	pushf
	pop	[regflg]	; Save flags
	push	si

; Do register dump before anything else
; If Interupt 38 processing is on it will always be dump no matter if
; interupt 21 dumping is turn on or off

	test    al,20h		; Interupt 38H call
	jz      dordump		; no...do reg dump
	cmp     [int38p],0	; interupt 38 processing
	jz      skipdump	; no...skip dump
	lea     si, I38msg	; display Interupt 38 Message
	call    msgout
	jmp     doregdp
dordump:
	test    al,1		; do they want dump
	jz      skipdump
doregdp:
	call	regdump		; Yes

skipdump:
	mov	si,dx
	call	msgout		; Display message at DS:SI

	test    [smpchk], 1     ; ***** do they want heap check
	jz      cmdmcb
	push    ds
	MGetSCB ds
	call    ChkHeap		; ***** check the heap (temporary SAH 4-20-87)
	pop     ds

cmdmcb:


if	MTRACE
	test    [mcbchk], 1	; ***** do they want MCB check
	jz      cmdrest
	
	push	ax
	push    bx
	push    cx
	push    bp

	call	mbtrace

;	xor     bx,bx
;	call    MBcheck		; ***** process MCB checking

	pop	bp
	pop	cx
	pop     bx
	pop	ax
;	jnc     cmdrest	
;	lea     si,MCBbad
;	call    msgout		; disp error message

;cmdrest:
endif


; Do rest of commands here

	test	al,2		; Prompt for 'Abort or Ignore'?
	jz	cmdnext		; No
	call	askAbIg		; Ask for Abort or Ignore
	jmp	cmdnext2	; Skip keypress check
cmdnext:
	test	al,4		; Get keypress?
	jz	$+5		; No
	call	askkey		; Get key
	jmp	dbexit2		; Exit with key in AL
cmdnext2:
	test	al,8		; Test input?
	jz	$+5		; No
	call	dbtchar		; Test for key
cmdnext3:
	; Add any other tests here

	pop	si
	pop	[regflg]	; Get return address
	pop	dx		; Restore original for CALLer
	pop	ds		;	"	"	"
	pop	ax		;	"	"	"
	jmp	[regflg]	; RETurn to calling routine
dbexit2:
	pop	si
	pop	[regflg]	; Get return address
	pop	dx		; Restore original for CALLer
	pop	ds		;	"	"	"
	pop	[saveAX]	; Clear old AX value from stack
	jmp	[regflg]	; RETurn to calling routine


	if MTRACE
	subttl  MBtrace - trace MCB chain and display content
	page
;-----------------------------------------------------------------------;
;       MBtrace -  traces MCB chain and displays to debug console       ;
;                  Displays Segment:Parent:Lenght			;
;-----------------------------------------------------------------------;

MTBuff  db      79 dup (' ')
MTcr    db      13,10,'$'

MBtrace proc	near
	push    si
	push    di
	push    ds
	push    es

	push    cs
	pop	ds
	assume  ds:mos

	lea     si,MTcr
	call	msgout

	push    cs
	pop	es
	lea     di,MTbuff
	mov	cx,78/2
	mov     ax, 2020h
	cld
	rep     stosw

	lea     si,MTbuff
	xor     cx,cx		; zero out counter
	MGetSCB es
	assume  es:grp
	mov     es,[scbtcbpc]
	assume  es:tcb
	mov     es,[tcbmbpf]	; get top pointer
	

MTloop  label   near
	push    cx
	mov     ax,es
	mov     dx,si
	call    hex2asc
	mov     byte ptr [si+4],':'
	add     si,5
	mov     ax,es:[1]
	mov     dx,si
	call    Hex2asc
	mov     byte ptr [si+4],':'
	add     si,5
	mov     ax,es:[3]
	mov     dx,si
	call	hex2asc
	add	si,8
	pop     cx
	cmp     cx, 3
	jb	MTnext
	lea     si,MTbuff
	call	msgout
	push    es
	push    cs
	pop	es
	lea     di,MTbuff
	mov	cx,78/2
	mov	ax,2020h
	cld
	rep	stosw
	pop	es
	mov     cx, -1
	lea     si, MTbuff

MTnext  label   near
	cmp     byte ptr es:[0],'M'
	jne     MTdone
	mov     ax,es
	inc     ax
	add     ax,word ptr es:[3]
	mov     es,ax
	inc     cx
	jmp     MTLoop

MTdone  label	near
	cmp     cx, -1
	jz	MTskip
	lea     si,MTbuff
	call	msgout
	push    cs
	pop	es
	lea     di,MTbuff
	mov     cx,78/2
	mov	ax,2020h
	cld
	rep     stosw

MTskip  label	near

	pop	es
	pop	ds
	pop	di
	pop	si
	ret
MBtrace endp
endif

	subttl	regdump - do a register display
	page
;-----------------------------------------------------------------------;
; This subroutine will display a register dump similar to that of the	;
; MS-DOS Debug program.							;
;									;
;  On Entry:								;
;	SP+12-> RETurn address of original call to MOSDEBUG		;
;	SP+10-> AX							;
;	SP+8 -> DS							;
;	SP+6 -> DX							;
;	SP+4 -> Junk							;
;	SP+2 -> SI							;
;	SP+0 -> Junk (RETurn address)					;
;									;
;  On Exit:								;
;	Nothing								;
;									;
;	No Global data affected						;
;	No Global procedures called					;
;	No registers are changed					;
;-----------------------------------------------------------------------;
regdump	proc	near
	assume	ds:nothing, es:nothing

	test	al,10H		; Use Task registers?
	jz	$+5
	jmp	regtask		; Yes

	mov	[saveAX],ax
	mov	ax,sp
	xchg	ax,bp
	push	[bp+10]		; AX
	push	bx		; BX
	push	cx		; CX
	xchg	ax,bp
	mov	bx,bp		; Starting SP value
	mov	bp,ax		; Address stack data
	push	[bp+6]		; DX
	sub	ax,10		; Calc original SP value
	push	ax		; SP
	push	bx		; BP
	push	[bp+2]		; SI
	push	di		; DI
	push	[bp+8]		; DS
	push	es		; ES
	push	ss		; SS
	push	cs		; CS (this only called in MOS segment)
	push	[bp+4]		; IP

	push	ds		; Save for sub
	push	dx		; "	"
	push	cs
	pop	ds
	assume	ds:mos
	lea	si,regdata	; Start here
	mov	cx,13		; Do 13 registers
	sub	bp,2		; Point to AX register 1st
reglp:
	mov	ax,[bp]		; Get next register value
	mov	dx,si
	call	hex2asc
	add	si,9		; Length of each register entry
	sub	bp,2		; Next value
	loop	reglp
	call	doflags		; Set flag values in display message
	lea	si,regmsg	; Now display info
	call	msgout

	pop	dx
	pop	ds		; Entry DS back
	assume	ds:nothing
	pop	ax		; Clear IP
	pop	ax		; Clear CS
	pop	ax		; Clear SS
	pop	es		; ES
	pop	ax		; Clear DS
	pop	di		; DI
	pop	ax		; Clear SI
	pop	bp		; BP
	pop	ax		; Clear SP
	pop	ax		; Clear DX
	pop	cx		; CX
	pop	bx		; BX
	pop	ax		; Clear AX
	mov	ax,[saveAX]
	ret

regtask:
	push	ax
	push	[TAX]		; AX
	mov	ax,sp		; Get starting pointer
	push	[TBX]		; BX
	push	[TCX]		; CX
	push	[TDX]		; DX
	push	[TSP]		; SP
	push	[TBP]		; BP
	push	[TSI]		; SI
	push	[TDI]		; DI
	push	[TDS]		; DS
	push	[TES]		; ES
	push	[TSS]		; SS
	push	[TCS]		; CS
	push	[TIP]		; IP

	push	ds		; Save for sub
	push	dx		; "	"
	push	cs
	pop	ds
	assume	ds:mos
	lea	si,regdata	; Start here
	mov	cx,13		; Do 13 registers
	push	di
	mov	di,ax		; Stack register pointer
reglpt:
	mov	ax,ss:[di]	; Get next register value
	mov	dx,si		; Put register ASCII value here
	call	hex2asc
	add	si,9		; Length of each register entry
	sub	di,2		; Next value
	loop	reglpt
	pop	di
	push	[regflg]
	mov	ax,[TFLAG]
	mov	[regflg],ax
	call	doflags		; Set flag values in display message
	pop	[regflg]
	lea	si,regmsg	; Now display info
	call	msgout

if	FCBDUMP
	cmp	[TAH],28h	; dump FCB?
	jne	rd10		; if we don't care about the FCB
	mov	dx,[TDX]
	mov	ds,[TDS]	; print the FCB at ds:dx
	call	dumpfcb
rd10:
endif

	pop	dx
	pop	ds		; Entry DS back
	assume	ds:nothing
	mov	ax,sp
	add	ax,13*2		; 13 registers on stack
	mov	sp,ax		; Clear data from stack
	pop	ax		; Entry AX back

	ret

regdump	endp

	subttl	doflags - Set up string of flag names
	page
;-----------------------------------------------------------------------;
; Build the string of flag settings for display.			;
;									;
;  On Entry:								;
;	DS -> MOS							;
;	'regflg' = flags to process					;
;									;
;  On Exit:								;
;	The flags are ASCII formated in the 'regf' data area		;
;									;
;	No Global data affected						;
;	No Global procedures called					;
;	No registers are changed					;
;-----------------------------------------------------------------------;
doflags	proc	near

	assume	ds:mos, es:nothing
	push	ax
	push	bx
	push	cx
	push	es
	push	si
	push	di

	push	cs
	pop	es
	assume	es:nothing

	lea	si,flagdat
	lea	di,regf
	lea	bx,flgtst	; List of flag test values
	mov	ax,[regflg]	; Get CALLers flags
flglp:
	push	si		; Save flag pointer
	cmp	word ptr [bx],0	; End of list?
	je	dofend		; Yes
	test	ax,[bx]		; Test for set flag
	jnz	flgset
	add	si,3		; Point to NOT set string
flgset:
	mov	cx,3
	rep movsb
	pop	si
	add	si,6		; Point to next set of strings
	add	bx,2		; Point to next flag test value
	jmp	flglp
dofend:
	pop	si		; Clear from loop section
	pop	di
	pop	si
	pop	es
	pop	cx
	pop	bx
	pop	ax
	ret

doflags	endp

if	FCBDUMP
	subttl	dumpfcb - print out contents of an FCB
	page
;-----------------------------------------------------------------------;
; Prints out the 64 bytes pointed to by ds:dx on entry.  Prints the	;
; address, two spaces, 8 bytes of stuff, a dash, 8 more bytes of stuff,	;
; a tab, then the ASCII values of the 16 bytes, if they are are in the	;
; range 20h -- 7eh.							;
;									;
;  On Entry:								;
;	ds:dx points to the FCB to print				;
;									;
;  On Exit:								;
;									;
;	No Global data affected						;
;	No Global procedures called					;
;	Only flags register changed 					;
;-----------------------------------------------------------------------;
dumpfcb	proc	near
	push	si
	push	ds
	push	dx
	push	ds
	push	cs
	pop	ds		; temporarily switch to our ds
	lea	si,msgcr
	call	msgout		; print initial CR LF
	pop	ds		; back to fcb ds

	call	dump16
	add	dx,16
	call	dump16
	add	dx,16
	call	dump16
	add	dx,16
	call	dump16
	pop	dx
	pop	ds
	pop	si
	ret
dumpfcb endp

	subttl	dump16 - dump out 16 bytes of memory
	page
;-----------------------------------------------------------------------;
; Prints out the 64 bytes pointed to by ds:dx on entry.  Prints the	;
; address, two spaces, 8 bytes of stuff, a dash, 8 more bytes of stuff,	;
; a tab, then the ASCII values of the 16 bytes, if they are are in the	;
; range 20h -- 7eh.							;
;									;
;  On Entry:								;
;	ds:dx points to the FCB to print				;
;									;
;  On Exit:								;
;									;
;	No Global data affected						;
;	No Global procedures called					;
;	Only flags register changed 					;
;-----------------------------------------------------------------------;
dump16	proc	near
	push	ds
	push	es
	push	si
	push	dx
	push	bx
	push	ax
	mov	bx,dx
	mov	ax,ds
	mov	es,ax		; FCB lives in es now
	push	cs
	pop	ds		; ds now points to our strings
	lea	dx,msgaddr
	call	hex2asc		; print out segment
	mov	ax,bx
	lea	dx,msgaddr+5	; convert offset
	call	hex2asc

	mov	cx,16
	lea	dx,msgdta	; where the numeric version goes
	lea	si,msgadta	; where the ASCII version goes
dmp10:
	mov	al,es:[bx]	; get next byte
	call	byte2asc	; do numeric version
	mov	ah,'.'		; what to print if can't print byte as is
	cmp	al,20h		; printable?
	jb	dmp20
	cmp	al,7eh
	ja	dmp20
	cmp	al,'$'		; can't print these out
	je	dmp20
	mov	ah,al		; we can print the byte as is
dmp20:
	mov	[si],ah		; store the printable version of it
	inc	bx		; next byte
	add	dx,3		; next print location for numerals
	inc	si		; next print location for ASCII
	loop	dmp10

	lea	si,msgaddr
	call	msgout		; send the message

	pop	ax
	pop	bx
	pop	dx
	pop	si
	pop	es
	pop	ds
	ret
dump16	endp

endif

	subttl	askAbIg - Ask for Abort or Ignore
	page
;-----------------------------------------------------------------------;
; Prompt user with 'Abort or Ignore?' and return CF=1 if Abort selected	;
;									;
;  On Entry:								;
;	Nothing								;
;									;
;  On Exit:								;
;	CF=1 if Abort selected or CF=0 if Ignore selected.		;
;									;
;	No Global data affected						;
;	No Global procedures called					;
;	Only flags register changed 					;
;-----------------------------------------------------------------------;
askAbIg	proc	near

	push	ax
	push	ds
	push	cs
	pop	ds
	assume	ds:mos, es:nothing
	lea	si,msgAbIg	; Print 'Abort or Ignore' message
	call	msgout
reinput:
	call	dbgchar		; Get character from debug terminal
	and	al,0dfH		; Uppercase
	cmp	al,'A'		;
	je	carryon
	cmp	al,'I'
	je	carryoff
	jmp	reinput		; Only accept A or I
carryon:
	lea	si,msgabrt	; Display abort for informational purposes
	call	msgout
	stc
	jmp	AIexit
carryoff:
	lea	si,msgignr	; Display abort for informational purposes
	call	msgout
	clc
AIexit:
	pop	ds
	pop	ax
	ret

askAbIg	endp

	subttl	askkey - Ask for Keypress
	page
;-----------------------------------------------------------------------;
; Wait for key press, return in AL.					;
;									;
;  On Entry:								;
;	Nothing								;
;									;
;  On Exit:								;
;	AL = ASCII of key pressed					;
;	 Note: If main console is input device the extended keys are	;
;		not accepted.						;
;									;
;	No Global data affected						;
;	No Global procedures called					;
;	AL returns value, No other registers are changed		;
;-----------------------------------------------------------------------;
askkey	proc	near

	push	ds
	push	cs
	pop	ds
	assume	ds:mos, es:nothing
	call	dbgchar		; Get character from debug terminal
	pop	ds
	ret

askkey	endp

	subttl	msgout - Output message to DBPORT device
	page
;-----------------------------------------------------------------------;
; This routine will output a message to the port, screen, or device	;
; specified by the CONFIG command DBPORT.				;
;									;
;  On Entry:								;
;	DS:SI -> string to output (terminated by a '$')			;
;									;
;  On Exit:								;
;	Nothing								;
;									;
;	No Global data affected						;
;	No Global procedures called					;
;	No registers are changed					;
;-----------------------------------------------------------------------;
msgout	proc	near

	assume	ds:nothing, es:nothing
	push	ax
	push	dx
	push	ds		; Save msg pointer
	MGetSCB ds
	assume	ds:grp
	mov	ax,[scbdbprt]	; Get port to display to (or screen)
	cmp	ax,[scbvidad]	; Should we use the default display?
	pop	ds		; CALLers pointer back
	assume	ds:nothing
	jne	ckother		; Check for alternate display device
conout:
	lodsb
	cmp	al,'$'
	je	msgend
	mov	bx,7
	mov	ah,14
	int	10H		; Display to standard device
	jmp	conout
msgend:
	pop	dx
	pop	ax
	ret
ckother:
	; Check for alternate screen here

	cmp	ax,4		; Check for LPT device
	ja	nxtdev		; No, check for other devices
	call	doprn		; Display to printer
	jmp	msgend
nxtdev:
	call	doport		; Display to serial port
	jmp	msgend

msgout	endp

	subttl	doport - Display to serial port
	page
;-----------------------------------------------------------------------;
; Output message at DS:SI ending in '$' to serial port in AX.		;
;									;
;  On Entry:								;
;	AX = Serial port address					;
;	DS:SI -> string to output (terminated by a '$')			;
;									;
;  On Exit:								;
;	Nothing								;
;									;
;	No Global data affected						;
;	No Global procedures called					;
;	AX and DX registers are changed					;
;-----------------------------------------------------------------------;
doport	proc	near
	assume	ds:nothing, es:nothing

	push	si
	mov	dx,ax		; Get port address
	cld
chkxoff:
	add	dx,5		; LSR
	in	al,dx
	sub	dx,5		; Tx & Rx
	test	al,1		; Data Ready?
	jnz	chkx2		; Yes
	xor	al,al		; Flag no char read for 'dbtchar'
	jmp	chkx3
chkx2:
	in	al,dx		; Read port
	and	al,7fH
	cmp	al,13H		; Check for XOFF (CTRL-S)
	je	chkx2		; Loop until something else is there
chkx3:
	mov	[lstread],al	; Save for 'dbtchar'
dopstr:
	lodsb			; Get char to write
	cmp	al,'$'		; End of string?
	jne	$+5
	jmp	dopend
	push	ax		; Save char to write
	add	dx,5		; LSR
waittx:
	in	al,dx
	test	al,20H		; Check for Transmitter empty
	jz	waittx
	sub	dx,5
	pop	ax		; Char to write
	out	dx,al		; Send it to the port
	jmp	dopstr		; Back to top of loop
dopend:
	pop	si
	ret

doport	endp

	subttl	doprn - Display to LPT device
	page
;-----------------------------------------------------------------------;
; Output message at DS:SI ending in '$' to LPT # in AX			;
;									;
;  On Entry:								;
;	AX = LPT number (1 - 4)						;
;	DS:SI -> string to output (terminated by a '$')			;
;									;
;  On Exit:								;
;	Nothing								;
;									;
;	No Global data affected						;
;	No Global procedures called					;
;	AX and DX registers are changed					;
;-----------------------------------------------------------------------;
doprn	proc	near

	assume	ds:nothing, es:nothing
	push	si
	mov	dx,ax		; Set LPT number
	dec	dx		; Make 0 relative
	cld
dolpt:
	lodsb			; Get char to write
	cmp	al,'$'		; End of string?
	jne	$+5
	jmp	dolend
	push	ax		; Save char to write

waitrdy:
	mov	ah,2		; Get printer status
	int	17H		; BIOS printer I/O
	test	ah,80H		; Check for Busy
	jz	waitrdy		; Wait til not Busy
	pop	ax		; Char to write
	mov	ah,0		; Print char in AL
	int	17H
	jmp	dolpt		; Back to top of loop
dolend:
	pop	si
	ret

doprn	endp

	subttl	dbgchar - DEBUG Get character
	page
;-----------------------------------------------------------------------;
; Get character from input device (debug terminal or console) return	;
; in AL.  If device is a printer device then an 'I' or Ignore is 	;
; returned.								;
;									;
;  On Entry:								;
;	Nothing								;
;									;
;  On Exit:								;
;	AL = ASCII character input from device				;
;									;
;	No Global data affected						;
;	No Global procedures called					;
;	What registers are changed					;
;-----------------------------------------------------------------------;
dbgchar	proc	near

	assume	ds:nothing, es:nothing
	push	dx
	push	ds		; Save msg pointer
	MGetSCB ds
	assume	ds:grp
	mov	ax,[scbdbprt]	; Get port to display to (or screen)
	pop	ds		; CALLers pointer back
	cmp	ax,0b000H	; Use console?
	je	getcon		; Yes
	cmp	ax,0b800H	; Use console?
	je	getcon		; Yes
	jmp	getother
getcon:
	xor	ah,ah
	int	16H		; Get key press
	or	al,al		; Extended?
	jz	getcon		; Yes, do not accept extended, ask again
gcharend:
	pop	dx
	ret

getother:
	cmp	ax,4		; Is this an LPT device?
	ja	getport		; No, get from serial port
	mov	al,'I'		; Respond default for LPT
	jmp	gcharend

getport:
	mov	dx,ax		; port address
	in	al,dx		; Clear any current char
	add	dx,5		; Point to LSR
waitkey:
	in	al,dx
	test	al,1		; Check Data Ready
	jz	waitkey
	sub	dx,5		; Point back to TX
	in	al,dx		; Get char
	jmp	gcharend	; Exit routine

dbgchar	endp

	subttl	dbtchar - DEBUG test for character
	page
;-----------------------------------------------------------------------;
; Test for character from input device (debug terminal or console)	;
; return in AL (0 if none).  If device is a printer device then an 'I'	;
; or Ignore is returned.						;
;									;
;  On Entry:								;
;	Nothing								;
;									;
;  On Exit:								;
;	AL = ASCII character input from device (0 if no char)		;
;									;
;	No Global data affected						;
;	No Global procedures called					;
;	What registers are changed					;
;-----------------------------------------------------------------------;
dbtchar	proc	near

	push	ds
	assume	ds:nothing, es:nothing
	push	dx
	MGetSCB ds
	assume	ds:grp
	mov	ax,[scbdbprt]	; Get port to display to (or screen)
	push	cs
	pop	ds		; CALLers pointer back
	assume	ds:mos
	cmp	ax,0b000H	; Use console?
	je	tstcon		; Yes
	cmp	ax,0b800H	; Use console?
	je	tstcon		; Yes
	jmp	tstother
tstcon:
	mov	ah,1
	int	16H		; Check for key
	jnz	tstcon2		; Yes, key available
	xor	al,al		; Return no char available code
	jmp	tcharend
tstcon2:
	xor	ah,ah
	int	16H		; Clear key
	or	al,al		; Extended?
	jz	tstcon		; Yes, do not accept extended, ask again
	jmp	tcharend

tstother:
	cmp	ax,4		; Is this an LPT device?
	ja	tstport		; No, get from serial port
	mov	al,'I'		; Respond default for LPT
	jmp	tcharend

tstport:
	mov	dx,ax		; port address
	add	dx,5		; Point to LSR
	in	al,dx
	test	al,1		; Check Data Ready
	jnz	tstport2	; Yes
	mov	al,[lstread]	; Return last read one if any
	jmp	tcharend	; End
tstport2:
	sub	dx,5		; Point back to TX
	in	al,dx		; Get char
tcharend:
	pop	dx
	pop	ds
	ret

dbtchar	endp

	subttl	mosSIMck - Check for SIM hotkey
	page
;-----------------------------------------------------------------------;
; This routine will check for the SIM hotkey and if found envoke the	;
; SIM menu.								;
;									;
;  On Entry:								;
;	Nothing								;
;									;
;  On Exit:								;
;	Nothing								;
;									;
;	Global data affected: scbdebug					;
;	No Global procedures called					;
;	No registers are changed					;
;-----------------------------------------------------------------------;
mosSIMck proc	near
	assume	ds:nothing, es:nothing

	push	ax
	call	dbtchar		; Check for any pressed key
	or	al,al
	jnz	$+5
	jmp	mosSIMe

	cmp	al,[SIMhk]	; Is this a SIM request?
	je	$+5		; Yes
	jmp	mosSIMe		; No, exit
	pop	ax

	; Display menu and get any input
mosSIM:						; Entry from MOSINT21
	push	ax
	push	ds
	push	cs
	pop	ds
	assume	ds:mos
mosSIM0:
	call	doSIMm		; Display menu
mosSIM1:
	call	dbgchar		; Get users input
	cmp	al,13
	je	mosSIMx		; Exit
	cmp     al,'7'		; Interupt 38 Processing
	je      mosSIM38	
	cmp     al,'8'		; ***** heap checking
	je      mosSIMh
	cmp     al,'9'		; ***** MCB checking
	je      mosSIMm
	cmp	al,'1'		; Validate range
	jb	mosSIM1		; Not in range
	cmp	al,'6'
	ja	mosSIM1		; Not in range
	mov	cl,al
	sub	cl,'0'		; ASCII to binary
	mov	ax,1
	shl	ax,cl		; Set desired bit
	push	es
	MGetSCB es
	assume	es:grp
	xor	[scbdebug],ax
	pop	es
	jmp	mosSIM0
mosSIM38:
	xor     [int38p], 1	; toggle interupt 38 processing
	jmp	mosSIM0
mosSIMh:
	xor     [smpchk], 1     ; ***** toggle heap checking
	jmp     mosSIM0
mosSIMm:
	xor     [mcbchk], 1	; ***** toggle MCB checking
	jmp     mosSIM0
mosSIMx:
	lea	si,SIMcr	; CR, LF
	call	msgout
	pop	ds
mosSIMe:
	pop	ax
	ret

mosSIMck endp

	subttl	doSIMm - Display SIM menu
	page
;-----------------------------------------------------------------------;
; Display the SIM menu and the current values.				;
;									;
;  On Entry:								;
;	DS -> mos							;
;									;
;  On Exit:								;
;	Nothing								;
;									;
;	No Global data affected						;
;	No Global procedures called					;
;	No registers are changed					;
;-----------------------------------------------------------------------;
doSIMm	proc	near

	assume	ds:mos, es:nothing
	push	ax
	push	si
	push	es
	MGetSCB es
	assume	es:grp

	lea	si,SIMmen	; Menu header
	call	msgout
	mov	ax,2		; Fun 0-C bit
	call	dispset		; Display On/Off

	lea	si,SIMm2
	call	msgout
	mov	ax,4		; Fun D-30 bit
	call	dispset

	lea	si,SIMm3
	call	msgout
	mov	ax,8		; Fun 31+ bit
	call	dispset

	lea	si,SIMm4
	call	msgout
	mov	ax,10H		; Pause on entry bit
	call	dispset

	lea	si,SIMm5
	call	msgout
	mov	ax,20H		; Pause on exit bit
	call	dispset

	lea	si,SIMm6
	call	msgout
	mov	ax,40H		; Internal INT 21s bit
	call	dispset

	lea     si,SIMm7
	call    msgout
	lea     si,SIMon
	test    [int38p], 1	; interupt 38 processing
	jnz     DoSIM38
	lea     si,SIMoff
DoSIM38:
	call    msgout

	lea     si,SIMm8	; ***** heap checking 
	call    msgout
	lea     si,SIMon
	test    [smpchk], 1     ; ***** heap check on or off
	jnz     DoSIMhp
	lea     si,SIMoff
DoSIMhp:
	call    msgout

	lea     si,SIMm9	; ***** MCB checking
	call    msgout
	lea     si,SIMon
	test    [mcbchk], 1     ; MCB checking on or off
	jnz     DoSIMmcb
	lea     si,SIMoff
DoSIMmcb:
	call	msgout
	
	lea	si,SIMmp	; Prompt
	call	msgout
	pop	es
	pop	si
	pop	ax
	ret			; End doSIMm

dispset	proc	near
	lea	si,SIMon
	test	[scbdebug],ax	; Is bit on?
	jnz	dsp1
	lea	si,SIMoff
dsp1:
	call	msgout		; Display at end of last line
	ret
dispset	endp

doSIMm	endp

endif


	subttl	hex2asc - Hex 2 ASCII conversion
	page
;-----------------------------------------------------------------------;
; Hex to ASCII convertion routine.					;
;									;
;  On Entry:								;
;	AX = 16-bit binary value					;
;	DS:DX -> 4 byte area to store ASCII result			;
;									;
;  On Exit:								;
;	DS:DX -> ASCII string						;
;									;
;	No Global data affected						;
;	No Global procedures called					;
;	No registers are changed					;
;-----------------------------------------------------------------------;
hextbl	db	'0123456789ABCDEF'

	assume	ds:nothing, es:nothing, ss:nothing
hex2asc	proc	near

	push	ax
	push	bx
	push	cx
	push	dx
	push	si
	pushf

	mov	si,dx
	mov	cl,4
	lea	bx,hextbl
	mov	ch,al		; Save lsbyte
	call	hexcal
	mov	ah,ch		; Do lsbyte
	call	hexcal

	popf
	pop	si
	pop	dx
	pop	cx
	pop	bx
	pop	ax
	ret
hexcal:
	xor	al,al
	shr	ax,cl
	shr	al,cl
	xlat	hextbl
	xchg	al,ah
	xlat	hextbl
	mov	[si],ax
	add	si,2
	ret

hex2asc	endp

if	MDEBUG eq 1

if	FCBDUMP
	subttl	byte2asc - Byte 2 ASCII conversion
	page
;-----------------------------------------------------------------------;
; Hex to ASCII conversion routine.					;
;									;
;  On Entry:								;
;	AL = 8-bit binary value						;
;	DS:DX -> 2 byte area to store ASCII result			;
;									;
;  On Exit:								;
;	DS:DX -> ASCII string						;
;									;
;	No Global data affected						;
;	No Global procedures called					;
;	No registers are changed					;
;-----------------------------------------------------------------------;

	assume	ds:nothing, es:nothing, ss:nothing
byte2asc	proc	near

	push	ax
	push	bx
	push	cx
	push	dx
	push	si
	pushf

	mov	si,dx
	mov	cl,4
	lea	bx,hextbl
	mov	ah,al		; Print lsbyte
	call	hexcal

	popf
	pop	si
	pop	dx
	pop	cx
	pop	bx
	pop	ax
	ret
byte2asc	endp

endif

	subttl	dec2asc - Decimal 2 ASCII conversion
	page
;-----------------------------------------------------------------------;
; Decimal to ASCII convertion routine.					;
; Buffer must be 5 bytes long as it is cleared to blanks.		;
;									;
;  On Entry:								;
;	AX = 16-bit value						;
;	DS:DX -> 5 byte area to store ASCII string result		;
;									;
;  On Exit:								;
;	DS:DX -> ASCII string						;
;									;
;	No Global data affected						;
;	No Global procedures called					;
;	No registers are changed					;
;-----------------------------------------------------------------------;
dec10	dw	10		; Constant

	assume	ds:nothing, es:nothing, ss:nothing
dec2asc	proc	near

	push	ax
	push	dx
	push	si
	mov	si,dx
	mov	byte ptr [si],' '	; Clear buffer
	mov	word ptr [si+1],'  '	; "	"
	mov	word ptr [si+3],'  '	; "	"
	pushf
	add	si,4			; Point to end of buffer
dec2lp:
	xor	dx,dx
	div	[dec10]		; Isolate next digit
	add	dl,'0'		; Convert to ASCII
	mov	[si],dl		; Store in buffer
	dec	si		; Next digit position
	or	ax,ax		; Is that all?
	jnz	dec2lp		; No
	popf
	pop	si
	pop	dx
	pop	ax
	ret

dec2asc	endp

;-----------------------------------------------------------------------;
MOSDebug endp

endif
	
mosseg	ends
	end
