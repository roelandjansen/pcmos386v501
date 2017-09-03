	include page.inc
        title   SRTERM.ASM - MOS SunRiver EGA Terminal Driver
comment ^=============================================================
               		Development Specification

 Program Name:	SRTERM.ASM		Assigned to: Stewart Hyde
 Module Name:	SRTERM			Assign date: 06/10/87 (03/14/88 ROD)
 Entry Points:				Completed:   05/07/88 (comdex)
 Entry From:
 Entry Method:	CALL DWORD [vector] with AH = function number
 Calls:		I10OLD (boot interrupt 10h)
 Purpose:	MOS interface to SunRiver Fiber Optic EGA Terminal
 Refer to:	Stewart Hyde
 Last Update:	06/28/90

 This is the source module for the SunRiver EGA terminal for our
 PC-MOS/386 Operating System. For detail information on the HardWare
 check the SunRiver EGA Documentation or check with Stewart.
 This driver will automatically detected and allocated space for up to
 SunRiver's theoretical limit of 256 terminals (64 cards).  Pratical
 limit is most likely 2 or 3 cards (8 to 12 terminals).

	CONFIG.SYS Line is as follows:
	DEVICE=SRTERM.SYS [WORKAREA]
	Where:
	        WORKAREA is optional (defaulting to EC000h)
		Start of drivers WorkArea above 640k which must
		be 12K and reserved for drivers used only
		But must be on a 16k boundary

       To invoke terminal do
	ADDTASK MEM,,,,,srterm,PORT
	Where:
		MEM -   Memory size of partition
		PORT -  Port #  1 - maximun # of Ports ( 4 per card)

 Provisions have been made so that a user can dynamical remove and then
 add it back again.

 Local printer support of sunriver's stations Parrallel port, which is
 is in similar designed as printer ports off of pcterm style terminals
 To access these ports, one will use the MOS ROUTE LPTx TO TERM
 command.

 Internal INT 14 Logic has been added but is primary intended to drive
 mouse off of com1 or com2 on the workstation using MOS's Generic
 mouse driver $mouse.sys.

========================================================================

SAH 06/08/89	supported List Base mapping calls for faster mapping

SAH 06/12/89	Corrected problem with handling mult-mice off of
		two stations on same chip (IE 1,2 or 3,4). I
		had make sure that reset chanid register of
		both stations at the same time that I sent
		Acknoledgement to their stations.

SAH 06/21/89	Increase Input Buffer to 32 bytes, Adjusted for
		references to TCBSTATION

SAH 06/28/89	Corrections for keyboard logic

SAH 07/05/89	Corrections for beeps, currently does not beep
		but does not stall system.

SAH 07/17/89	Added function 18 which does mothing on work
		station style stations.

SAH 07/31/89	Corrected Printing.

SAH 08/29/89	Corrections for freemem requirements 12k instead of 48k

SAH 09/25/89	Some Corrections for VGA Support, also	made
		using 12k actually use just 12k

SAH 10/24/89	Corrections for VGA version.

BWR 11/30/89	Marked messages for foreign language translations.

mjs 05/09/90	added the clr_set_irq dummy function.  it is called by
		int14fun11 within int14.inc (only needed by _serial.asm)

SAH 06/20/90	Correction for newer boards, base address other than
	        f0,000.

SAH 06/28/90	Added logic to allow pamswitching between non-ega\vga 
		workstations (IE VNA or Terminals)	

mjs 08/13/90	modified to use vidchk.inc and a boot_prep function.

=======================================================================^
	page
;	Conditional assemble equ below

TRUE		equ	1
FALSE		equ	0

VERSION 	equ	TRUE


        subttl  group segments and include block definitions
        page

;-----------------------------------------------------------------------;
; access to partition saved registers                                   ;
;-----------------------------------------------------------------------;

.xlist
	.286
	include options.inc
	include srterm.pub
        include MOSREGS.INC

tcb     segment at 1234h
        include mostcb.inc
tcb     ends

scbs    segment at 7000h
        assume cs:scbs
        include mosscbdf.inc
scbs    ends

stall	macro	
	local	lstall
	jmp	short lstall
lstall:
	endm

WAITTM	equ	6000h

	include srterm.def 
	include jmpmacro.inc
.list

;       definiitions and equates use 
;       status and control registers

CHANSEL         equ     0f00h
MODEREG         equ     0f01h
CHANID          equ     0f02h
DEVICEREG       equ     0f03h
INTCONTROL      equ     0f04h
IRQSEL          equ     0f05h
INTLATCH        equ     0f06h

;	device indification bits

POWERON		equ	000b		; power on interupt
KEYBOARD	equ	001b		; keyboard interupt
EGACONTROL	equ	010b		; EGA Controller interupt
SERIAL2		equ	011b		; Serial port 2 interupt
SERIAL1		equ	100b		; Serial port 1 interupt
PARRALLEL	equ	101b		; parrallel port interupt
TIMER		equ	110b		; timer interupt


;	switch memory definitions

RESETSYS	equ	0		; reset fiber optic station
BANKSELREG	equ	1		; bank select register
REARMCONTROL	equ	4		; rearm interupt controller
ACTINTRQ	equ	5		; activate station INTRQ pin
RESETINTRQ	equ	6		; reset station INTRQ pin
EGAENABLE	equ	7		; EGA enable\diable

;	keyboard controller definitions

KEYSTATUS	equ	0064h		; keyboard status
KEYOUTPUT	equ	0060h		; keyboard output buffer
KEYDATAINP	equ	0060h		; keyboard data input
KEYCMDINP	equ	0064h		; keyboard command input

;   	parallel port controller definitions

PARDATA		equ	03bch		; parallel port data
PARCONTROL	equ	03beh		; parallel port control
PARSTATUS	equ	03bdh		; parallel port status

;	serial port definitions

COM1TX		equ	03f8h		; com1 txbuffer
COM1RX		equ	03f8h		; com1 rcbuffer
COM1LSB		equ	03f8h		; com1 divisor latch lsb
COM1MSB		equ	03f9h		; com1 divisor latch msb
COM1ENABLE	equ	03f9h		; com1 interupt enable
COM1ID		equ	03fah		; com1 interupt id
COM1LINECTRL	equ	03fbh		; com1 line control
COM1MODCTRL	equ	03fch		; com1 modem control
COM1LINESTAT	equ	03fdh		; com1 line status
COM1MODSTAT	equ	03feh		; com1 modem status

COM2TX          equ     02f8h           ; com2 txbuffer
COM2RX          equ     02f8h           ; com2 rcbuffer
COM2LSB         equ     02f8h           ; com2 divisor latch lsb
COM2MSB         equ     02f9h           ; com2 divisor latch msb
COM2ENABLE      equ     02f9h           ; com2 interupt enable
COM2ID          equ     02fah           ; com2 interupt id
COM2LINECTRL    equ     02fbh           ; com2 line control
COM2MODCTRL     equ     02fch           ; com2 modem control
COM2LINESTAT    equ     02fdh           ; com2 line status
COM2MODSTAT     equ     02feh           ; com2 modem status

;	EGA Port Definitions

FEAT_ADR	equ	03dah		; PEGA features register
HRC_ADR		equ	03bfh		; PEGA Hercules register
ATTR_ADR	equ	03c0h		; PEGA Attribute Controller
MISC_ADR	equ	03c2h		; PEGA Misc register
SEQ_ADR		equ	03c4h		; PEGA Sequencer Controller
GRAPH_ADR	equ	03ceh		; PEGA Graphics Controller
CRT_ADR		equ	03d4h		; PEGA Crt Controller
PAR_ADR		equ	03d8h		; PEGA Paradise Register
PLR_ADR		equ	03ddh		; PEGA Plantronics Register
ATR_ADR		equ	03deh		; PEGA AT&T register
EXT_ADR		equ	03dfh		; PEGA Special Purpose register  

;	VGA related definitions


;	Station Driver Status Definition	

ACTIVE		equ	00000001b	; mark if card is available
ONLINE		equ	00000010b	; mark if card is online

KBSIZE		equ	32		; 32 maximum keys in buffer

MAXISR		equ	32		; max of 32 passes though isr


;************************************************************************
;                                                                      	*
;	Async adapter port and status definitions                      	*
;                                                                      	*
;************************************************************************

TXDAT	equ	0			; data transmitter


RXDAT	equ	0			; data receiver


DIVLL	equ	0			; baud rate divisor latch lsb


DIVLM	equ	1			; baud rate divisor latch msb


IEREG	equ	1			; interupt enable register

enmsi	equ	000001000b		; enable modem status interupts
enlsi	equ	000000100b              ; enable line status interupts
entei	equ	000000010b		; enable transmitter empty inter
endri	equ	000000001b		; enable data ready interupts


IIREG	equ	2			; interupt identification regist

noint	equ	000000001b		; no interupt pending


LCREG	equ	3			; line control register

divla	equ	010000000b		; divisor latch access control
stbrk	equ	001000000b		; set break condition


MCREG	equ	4			; modem control register

stot2	equ	000001000b		; set out 2 (enable interupts)
stot1	equ	000000100b		; set out 1
strts	equ	000000010b              ; set rts
stdtr	equ	000000001b		; set dtr


LSREG	equ	5			; line status register

tsre	equ	001000000b		; transmitter shift reg empty
thre 	equ	000100000b		; transmitter holding reg empty
brki	equ	000010000b		; break indicator
frerr	equ	000001000b		; framing error
paerr	equ	000000100b		; parity error
overr	equ	000000010b		; data overrun error
drdy	equ	000000001b		; data ready


MSREG	equ	6			; modem status register

carst	equ	010000000b		; status of carrier detect (RLSD)
rngst	equ	001000000b		; status of ring indicator (RI)
dsrst	equ	000100000b		; status of data set ready (DSR)
ctsst	equ	000010000b		; status of clear to send (CTS)
carch	equ	000001000b		; change in carrier detect (RLSD)
trlri	equ	000000100b		; trailing end of ring indicator
dsrch	equ	000000010b		; change in data set ready (DSR)
ctsch	equ	000000001b		; change in clear to send (CTS)



	page
code	segment para public 'data'	; To force loading with data
	assume	cs:code,ds:nothing,es:nothing,ss:nothing

MOSDDTSH equ    this byte
        dd      -1              ; filled in with pointer to next driver
        dw      8000h           ; signifying a character device
        dw      strat           ; device strategy entry point
        dw      inter           ; device interrupt entry point
srname  db      '$$SRTERM'      ; device name

request dd      0

fn      dw      ddtinit ; 0 - init
        dw      ddtnull ; 1 - media check
        dw      ddtnull ; 2 - build bpb
        dw      ddtnull ; 3 - ioctl input
        dw      ddtread ; 4 - read
maxfn   equ     ($-fn)/2

strat   proc    far
        mov     word ptr [request],bx
        mov     word ptr [request+2],es
	ret
strat   endp

inter   proc    far
        push    es
        push    ds
        push    si
        push    bx
        push    ax
        mov     bx,cs
        mov     ds,bx

	assume	ds:code

        mov     ax,0100h
        les     bx,[request]
        mov     si,es:[bx+2]
        and     si,0ffh
        cmp     si,maxfn
        jae     inter1
        shl     si,1
        call    fn[si]
inter1:
        assume  ds:nothing

        les     bx,[request]
        mov     es:[bx+3],ax    ; store result status
        pop     ax
        pop     bx
        pop     si
        pop     ds
        pop     es
        ret
inter   endp

; null device driver call does nothing
ddtnull proc    near
        mov     ax,0100h        ; return no error, done
        ret
ddtnull endp

        subttl  ddtread - return the terminal function vector
        page

; read just returns the terminal function vector
ddtread proc    near
        lds     si,es:[bx+14]
        mov     cx,es:[bx+18]
        mov     word ptr es:[bx+18],0   ; nothing read if error
        mov     ax,8103h                ; error, done, unknown command
        cmp     cx,4
        jne     ddtrd1                  ; if not reading exactly 4 bytes
        mov     es:[bx+18],cx                           ; else read 4 bytes
        mov     word ptr ds:[si],offset SRTERM  ; and these are them
        mov     ds:[si+2],cs
        mov     ax,0100h                ; no error, done
ddtrd1:
        ret
ddtread endp

        subttl  local data area - storage area for data
        page

MAXID	equ	64		; temporary set up for 64

scbptr	label	dword
scboff  dw      0               ; offset to SCB
scbseg	dw	0		; segment of SCB

memman  dd      0               ; memmory manager caller
mapvma  dd	0		; video memory area mapper
tcbseg	dw	0		; segment of TCB (caller)
ddtoff	dw	0		; offset (DS:SI)

maxterm dw      0               ; Max SunRiver terminals on system
workarea dw     0               ; MENMAN work area for driver
workio  dw      0               ; current WORKAREA io handle
baseaddr dw	0		; base address
curega	db	0		; current ega port
temp	db	0		;
mcdriver dd	0		; master console driver
mctcb	dw	0		; master console tcb
irq	db	0		; selected irq
rearm	dw	0		; re-arm port
irqmask db	0		; irq mask
oldirq	dd	0		; old irq
actvid	db	255		; activid
ofs10	dw	0		; Original INT 10 offset
seg10	dw	0		; Original INT 10 segment


orges	dw	0		; orginal ES values
workswt dw	0		; switch work area
workmap	dw	0		; mapping register work area
saveid	db	0		; save id during IRQ logic
endofdata dw	0		; segment of end of data area, end of keep
				; code and data
station dw	0		; station interupted pointed used in irq
vgabios db	'N'		; Y indicates that system has VGA bios
savlast dw	0		; saved lastff value during bankin
DoCHVal db	0ffh		; channel value use to manage DoChan

moudriver   db	'$$MOUSE',0	; mouse driver

isrcount  db	 0		; isr count for serial logic
once	db	'N'		; gone through irq once already

ListSR	label	word
	dw	5		; this is for physical remap call
	dw	0b800h		; map into text display memory
ASR1	dw	00f28h		; use physical bank 0f28h
	dw	4		; map 4 banks for 16k
	dw	0
	dw	0		; no second page
	dw	5		; this is for physical remap call
	dw	0a000h		; map into graphics display memory
ASR2	dw	00f10h		; use physical bank 0f10h
	dw	16		; map 16 banks for 64k
	dw	0
	dw	0		; no second page

ListMC	label	word
	dw	4		; this is for unmap call
	dw	0b800h		; map into text display memory
	dw	0		; unmap
	dw	4		; unmap 4 banks for 16k
	dw	0
	dw	0		; no second page
	dw	4		; this is for unmap call
	dw	0a000h		; map into graphics display memory
	dw	0		; use physical bank 0f10h
	dw	16		; map 16 banks for 64k
	dw	0
	dw	0		; no second page
;
;   The following is data for serial (INT 14 needs)
;

sportseg    dw	    0		 ; segment location of start of port area
portoff     dw	    0		 ; offset of port table from start of code
child	    dd	    0		 ; segment and offset of Child INT 14 handler
numport     dw	    0		 ; # of com ports on system
tocount     dw	    182 	 ; default timeout count (10 seconds)

orig38	    dd	    0		 ; Original INT 38 vector
orig1a	    dd	    0		 ; Original INT 1A vector

sername     db	    'SunRiver Serial Ports v2.00 (900628)    ' ;@@XLAT
							     
;-----------------------------------------------------------------------;
;  IRQTAB - The following table defines the four possiable IRQ which the;
;           the SunRiver Board can used.  The table has the following   ;
;	    fields.							;
;									;
;	    INTERUPT	BYTE	Interupt which IRQ uses			;
;	    GLOBAL	WORD	Global Reset Port (SunRiver)		;
;	    DISPLAY     WORD    Display value used.			;
;-----------------------------------------------------------------------;

irqtab	label	word		; constants pg 3-10 (sunriver doc)
	db	0dh
	dw	02f5h		; IRQ 5 
	dw	'5 '
	db	11011111b
	db	0fh
	dw	02f7h		; IRQ 7
	dw	'7 '
	db	01111111b
	db	74h
	dw	06f4h		; IRQ 12
	dw	'21'
	db	11101111b
	db	77h
	dw	06f7h		; IRQ 15
	dw	'51'
	db	01111111b

;-----------------------------------------------------------------------;
; IRQFUN - IRQ function table						;
;-----------------------------------------------------------------------;

irqfun	label	word
	dw	offset	power		; Power ON interupt
	dw	offset	keybd		; Keyboard Handling
	dw	offset	egasys		; EGA Vertical Scan Interupt
	dw	offset  ser2		; Serial Port 2 Handling
	dw	offset	ser1		; Serial Port 1 Handling
	dw	offset	par		; Parallel Port Handling
	dw	offset	time		; Timer Interupt

;-----------------------------------------------------------------------;
;  SUN Structure - the following is use in a dynamic task table which   ;
;  		   is created at init time when the driver check to see ;
;		   how many active cards are on the system.		;
;									;
; PLEASE NOTE: Changing the lenght of structure here requires INIT code,;
;	       FindPtr and TaskPtr routines to be alter.		;
;-----------------------------------------------------------------------;     

sun     struc
termid  db      ?			; terminal id (0 - MAXTERM-1)
status  db      ?			; status byte
taskid  dw      ?			; TCB of task allocated for console
kbget	dw	?
kbput	dw	?
kbready	db	?
kbbuff	db	32	dup (0)
unreg	dd	0			; prevous unregister call
kbstat	db	0			; Keyboard LED status bits
reserve db	2 dup (0)
sun     ends

;------------------------------------------------------------------------;
;   PORT Structure - This structure defines necessary information for	 ;
;		     COM port INT 14 logic. Currently it is 32 bytes	 ;
;		     in size and there are 2 entry for each station on	 ;
;		     the system.					 ;
;------------------------------------------------------------------------;


isize	equ	32			; 64 byte default input buffer
osize	equ	16			; 16 byte default output buffer


ports	struc
addr	dw	0			; physical port address
prtirq	db	4			; default IRQ line for port
kbeflg	db	0			; keyboard empty flag
modmst	db	0			; current modem status register
linest	db	0			; current line status register
ioprot	db	0			; i/o protocols enabled
					; 80h - waiting for timer wrap
					; 40h - not used
					; 20h - report carrier loss
					; 10h - monitor carrier
					; 08h - rts/cts enabled
					; 04h - dtr/dsr enabled
					; 02h - xmit xon/xoff
					; 01h - rcv xon/xo; Novell
iopend	db	0			; protocol state bits
					; 80h - carrier drop reported
					; 40h - carrier drop has occured
					; 20h - xon to be sent
					; 10h - xoff to be sent
					; 08h - rts off
					; 04h - dtr off
					; 02h - xoff rcvd
					; 01h - xoff sent
xoffch	db	0			; xoff character
xonch	db	0			; xon character
datovr	db	0			; flag to indicate data overrun
bufovr	db	0			; flag to indicate buffer overrun
ibfsiz	dw	isize			; input buffer size (bytes)
obfsiz	dw	osize			; output buffer size (bytes)

ibfseg	dw	0			; input buffer segment
ibfcnt	dw	0			; count of bytes in buffer
ibfget	dw	0			; next byte from buffer
ibfput	dw	0			; next empty buffer location

obfseg	dw	0			; output buffer segment
obfcnt	dw	0			; count of bytes in buffer
obfget	dw	0			; next byte from buffer
obfput	dw	0			; next empty buffer location
ports	ends


        subttl  termfn - all the terminal and keyboard functions for mos
        page

tfn     dw      register
	dw	inkbdata
        dw      outkbctl
bgnvid  equ     ($-tfn)/2
        dw      0
        dw      0
        dw      0
        dw      0
        dw      0
        dw      0
        dw      0
        dw      0
        dw      0
        dw      0
        dw      0
        dw      0
        dw      0
endvid  equ     ($-tfn)/2
        dw      prch
        dw      prstr
endtfn  equ     ($-tfn)/2


	subttl SRTERM Terminal Function Handler
	page
;------------------------------------------------------------------------;
; The following is the drivers terminal function vector routine.  It has ;
; the function ffh (for the swrealram call) and necessary terminal calls ;
; It is designed similar to VNAs handler.   The 3 bytes before handler   ;
; (SAH) are use for detection of driver.				 ;
;------------------------------------------------------------------------;
        assume  ds:tcb,es:nothing,ss:nothing
	db	'SAH'		; Author ID for detection of driver
SRTERM	proc	far
	cmp	ah,0feh 	; check if FE function
	jne	sht0
	pushf
	cli
	push	word ptr [tcbseg]
	push	word ptr [ddtoff]
	push	word ptr [orges]
	mov	[tcbseg],ds
	mov	[ddtoff],si
	mov	[orges],es
	push	ds
	push	es
	mov	es,[workarea]
	push	cs
	pop	ds
	assume	ds:code
	push	ax
	xor	ax,ax		; switch all sunriver stations out
	mov	[curega],al
	call	switchega
	pop	ax
	pop	es
	pop	ds
	assume	ds:tcb
;
;	we must now call the feh handle for the master console to switch
;	out the EGA for co-existence with VNA
;
	push	bx
	push	ds
	lds	bx,[scbptr]
	assume	ds:scbs
	cmp	[bx+scbvnasys],'Y'
	jne	skipfe
	mov	ds,[bx+scbtcbpf]
	call	dword ptr [mcdriver]
skipfe:
	pop	ds
	pop	bx
shtfe2:
	jmp	short srtout
sht0:
	cmp	ah,0ffh 	; is this switch real ram call
	jne	sht1

	pushf
	cli
	assume	ds:nothing
	push	word ptr [tcbseg]
	push	word ptr [ddtoff]
	push	word ptr [orges]
	mov	[tcbseg],ds
	mov	[ddtoff],si
	mov	[orges],es
	push	ds
	push	es
	mov	es,[workarea]

;	do swrealram processing - switch in channel or master console
;	depending of value in port record (0 is master console

	call	bankin
	assume	 ds:nothing
	pop	es
	pop	ds
srtout:
	pop	word ptr [orges]
	pop	word ptr [ddtoff]
	pop	word ptr [tcbseg]
	popf
	ret
sht1:
	mov	[tcbseg],ds
	mov	[ddtoff],si
	mov	[orges],es	; save necessary state for restoration
	push	ds
	push	es
	mov	es,[workarea]
;
;	following is use for normal terminal function
;
	assume	ds:tcb

	cmp	byte ptr [si].port,0	; if on master console, use master
	je	sht3
	or	ah,ah			; is this register call
	jnz	sht4a
	call	bankin			; for a bankin
	jmp	short sht5
sht4a:
	cmp	ah,endtfn		; if not a srterm function, use master
	jae	sht2			; This should take account of FE fun
	cmp	ah,bgnvid		; if function is video function
	jb	sht5			; use the master console
	cmp	ah,endvid
	jae	sht5
sht4:
	cmp	ah,4			; for set cursor type or set cursor
	je	sht2
	cmp	ah,5
	jne	sht3
sht2:
	call	bankin			; bank task in
sht3:
	cmp	byte ptr [si].port,0
	je	sht6
	cmp	ax,0a07h
	je	termfn1
sht6:
	push	cs
	pop	ds
	assume	ds:code
	call	master			; call the master console driver
	mov	cs:[orges],es
	jmp	short termfn1

sht5:
	assume	ds:nothing
	push	bp
	push	ds
	mov	ds,[tcbseg]
	assume	ds:tcb
        mov     bp,bx
        mov     bl,ah
        xor     bh,bh
        shl     bx,1
	xchg	bx,bp
	push	si
	call	tfn[bp] 		; call driver function
	pop	si
	pop	ds
	assume	ds:code
	pop	bp
termfn1:
	pop	es
	mov	es,cs:[orges]
	pop	ds
	ret
SRTERM  endp


        subttl  register - register port address, receive key buffer flag
        page
;-----------------------------------------------------------------------;
;                                                                       ;
; register - register port address, receive key buffer flag             ;
;                                                                       ;
;   AH = 00H                                                            ;
;     DX = port address                                                 ;
;     DS:SI -> tcbddt for this terminal for this partition              ;
;                                                                       ;
;   returns:                                                            ;
;     ES:BX -> key buffer flag                                          ;
;       key buffer flag is <> 0 while scan codes are buffered           ;
;     AL = 80H if master console                                        ;
;          00H if not master console                                    ;
;     AH = 0 if no error                                                ;
;        = 1 if bad port number                                         ;
;        = 2 if bad baud rate                                           ;
;-----------------------------------------------------------------------;
        assume  ds:tcb,es:nothing,ss:nothing
register:
	push	ds
	mov	bl,byte ptr [si].port	; get port
	xor	bh,bh			; 
	or	bx,bx
	jnz	reg1
regabort:
	pop	ds			; got a bad port....sorry
	mov	ah,1
	ret
reg1:
	dec	bx			
	mov	ax,ds
	push	cs
	pop	ds
	assume	ds:code
        call    TaskPtr                 ; get pointer to task
	jnz	reg2
	jmp     regabort
reg2:
	cmp	word ptr [bx].TaskId,0ffffh	; test if already allocated
	jne	regabort
	push	word ptr [curega]

;	the following logical will cause the Host Adapter to generated a
;	poweron interupt for the terminal desired. This has been added so
;	that when task is added that we are assured that a physical terminal
;	is actually on the station

	push	ax
	push	bx
	push	dx
	mov	dx,[rearm]
	out	dx,al
	mov	al,[bx].TermID
	inc	ax
	pushf
	cli
	mov	[curega],al
	call	switchega
	stall
	stall
	or	byte ptr es:[MODEREG],04h	; turn switch on
	push	es
	mov	es,[workswt]
	mov	byte ptr es:[RESETSYS],al	; reset the terminal
	pop	es
	and	byte ptr es:[MODEREG],NOT 04h	; turn switch off
	popf

	push	cx
	xor	cx,cx				; stall awhile...give it time
	loop	$
	pop	cx

	pop	dx
	pop	bx
	pop	ax

	test	[bx].status, ACTIVE	; is status card available
	jnz	reg3
	jmp	regbad
reg3:

	test	[bx].status, ONLINE	; is stations on line
	jnz	reg4
	jmp	regbad
reg4:
        mov     [bx].TaskId,ax          ; allocated
	pop	ax			; pop	word ptr [curega]
	pop	ds
	push	ds
	push	ax			; push	word ptr [curega]
	assume  ds:tcb

	; initialize master console DDT record

        mov     [si].dcpherc,'N'
        mov     [si].dcmode,3
        mov     [si].dcvmode,3
        mov     [si].dcpcrs,25*256
        mov     [si].dcpcol,80
        mov     [si].dcaddr,03d4h
        mov     [si].dcpscr,0b800h
        mov     [si].dcpscrl,80*25*2
        mov     [si].dcbios,1
        mov     [si].dcsnow,0

;	call old unregister call into local storage...this allows for chaining

	push	cx
	push	si
	push	di
	push	es
	push	cs
	pop	es
	lea	si,[tcbunreg]
	lea	di,[bx].unreg
	mov	cx,2
	cld
	rep	movsw
	pop	es
	pop	di
	pop	si
	pop	cx


;	set keyboard ready flag

	lea	bx,[bx].kbready		; setup keyboard ready flag
	mov	[orges],cs

;	set unregister call

	mov	word ptr [tcbunreg], offset unregister	
	mov	word ptr [tcbunreg+2],cs

;	set video initialization routine

	mov	word ptr [tcbvidset], offset VidInit
	mov	word ptr [tcbvidset+2],cs
	mov	ax,00ech		; MC, graphics, ali, no VIDEO IO
	jmp	short	regend
regbad:
        mov     ah,1            ; bad port
regend:
	pop	word ptr [curega]
	push	ax
	push	cs
	pop	ds
	assume	ds:code
	mov	al,[curega]
	call	switchega
	pop	ax
	pop	ds
	assume  ds:tcb
        mov     cx,0b800h       ; physical buffer address for srterm
				;   (stuffed into tcbvidad)
        ret

        subttl  inkbdata - input keyboard scan code
        page
;-----------------------------------------------------------------------;
;                                                                       ;
; inkbdata - input keyboard scan code                                   ;
;                                                                       ;
;   AH = 01H                                                            ;
;     DS:SI -> tcbddt                                                   ;
;                                                                       ;
;   returns:                                                            ;
;     AL = bit  7   - key break if 1, key make or key repeat if 0       ;
;          bits 6-0 - key scan code 01H - 07DH                          ;
;     key scan code is read non-destructively				;
;                                                                       ;
;-----------------------------------------------------------------------;
        assume  ds:tcb,es:nothing,ss:nothing

inkbdata:
        mov     bx,ds
	push	ds
	push	cs
	pop	ds
	assume	ds:code
        call    FindPtr         ; get task structure 
	jnz	insklp
	xor	al,al
	pop	ds
	ret
insklp:
	mov	al,byte ptr cs:[bx].kbready
	or	al,al
	jz	notinsk 	; any keys ready
	push	si
	mov	si,word ptr cs:[bx].kbget
	mov	al,byte ptr cs:[bx+si].kbbuff
	pop	si
notinsk:
	pop	ds
        ret


        subttl  outkbctl - clear current scan code from terminal driver
        page
;-----------------------------------------------------------------------;
;                                                                       ;
; outkbctl - clear current scan code from terminal driver               ;
;                                                                       ;
;   AH = 02H                                                            ;
;     AL = bit  7   - clear buffered scan code if 1, ignored if 0       ;
;          bits 6-0 - ignored                                           ;
;     DS:SI -> tcbddt                                                   ;
;                                                                       ;
;-----------------------------------------------------------------------;
        assume  ds:tcb,es:nothing,ss:nothing

outkbctl:
        test    al,80h
        jz      outend
	push	ds
	mov	bx,ds
	push	cs
	pop	ds
	assume	ds:code

        call    FindPtr         ; point by TCB
	jz	outsk
	push	si
	pushf
	cli

	mov	al,byte ptr cs:[bx].kbready
	or	al,al
	je	gk2
	mov	si,word ptr cs:[bx].kbget
	inc	si
	cmp	si,KBSIZE	; buffer above max
	jb	gk1
	xor	si,si		; set it to beginning
gk1:
	mov	word ptr cs:[bx].kbget,si
	cmp	si,word ptr cs:[bx].kbput	; any keys ready
	jne	gk2
	mov	byte ptr cs:[bx].kbready,00h	; indicate that no keys are
gk2:
	popf
	pop	si
	pop	ds
        ret
outsk:
        xor     ax,ax
	pop	ds
outend:
        ret

        subttl  prch - print a character on the terminal's local printer
        page
;-----------------------------------------------------------------------;
;                                                                       ;
; prch - print a character on the terminal's local printer              ;
;                                                                       ;
;   AH = 10H                                                            ;
;     AL = char to print                                                ;
;     DS:SI -> tcbddt                                                   ;
;                                                                       ;
;   returns AH as in INT 17H call                                       ;
;                                                                       ;
;-----------------------------------------------------------------------;
	assume  ds:tcb,es:nothing,ss:nothing
prch:
	call	prchar			; call lowlevel routine
        ret

        subttl  prstr - print a string on the terminal's local printer
        page
;-----------------------------------------------------------------------;
;                                                                       ;
; prstr - print a string on the terminal's local printer                ;
;                                                                       ;
;   AH = 11H                                                            ;
;   ES:DI -> string to print                                            ;
;   CX = length (bytes) to print                                        ;
;   DS:SI -> tcbddt                                                     ;
;                                                                       ;
;   returns AH as in INT 17H call if all of string can't be printed     ;
;     and DI -> first char not printed, CX = number not printed         ;
;-----------------------------------------------------------------------;
        assume  ds:tcb,es:nothing,ss:nothing
prstr:
	push	si
	push	di
	push	ds

	mov	ds,[orges]
	mov	si,di
	push	cx
prstrlp:
        lodsb
	call	prchar
	test	ah,1h
	jnz	prserr
	loop	prstrlp
	pop	di		;dis-regraud saved cx
	pop	ds
	pop	di
	pop	si
        ret
prserr:
	pop	di		; get old cx in di
	push	ax
	mov	ax,di
	sub	ax,cx		; calculate # printer so far
	dec	si
	mov	di,si
	pop	ax
	pop	ds
	pop	si		; old di value
	pop	si
	ret


        subttl unregister - un-register task with driver
        page
;-----------------------------------------------------------------------;
;                                                                       ;
;   Unregister - unregister current tasik with driver                   ;   
;                                                                       ;
;   Call by a far call to TCBUNREG                                      ;
;   DS ---> TCB when called						;
;                                                                       ;
;   returns:                                                            ;
;-----------------------------------------------------------------------;

        assume  ds:tcb,es:nothing,ss:nothing
unregister proc far
	push	ax
	push	bx
	push	si
	push	ds
;
;	now do unregister of sunriver driver variable
;
	mov	bx,ds
	push	cs
	pop	ds
	assume	ds:code
        call    FindPtr
	jz	unr2
	mov	al,byte ptr [bx].status ; get status
	and	al,ACTIVE		; set only active
	mov	si,word ptr [bx].termid  
	call	InitCVars		; initialize termianl variables	
unr1:
;
;	do the unregister chaining by calling next call on the
;	list if not zero
;
	pop	ds
	pop	si
	cmp	word ptr cs:[bx+2].unreg,0	
	je	unr2
	call	dword ptr cs:[bx].unreg
unr2:
	pop	bx
	pop	ax
	ret
unregister endp


        page
;-----------------------------------------------------------------------;
;                                                                       ;
;   Bankin - this is use switch the desired station in			;
;                                                                       ;
;   DS ---> TCB when called						;
;                                                                       ;
;   returns:                                                            ;
;-----------------------------------------------------------------------;

	assume	ds:tcb,es:nothing
bankin	proc	near
	pushf
	cli
	push	ax
	push	bx
	push	ds
	lds	bx,cs:[scbptr]
	assume	ds:scbs
	mov	ax,[bx+scblastff]	     ; check scblastff
	or	ax,ax
	jz	bankcont		     ; skip feh call if noone in
	mov	bx,ds
	cmp	ax,bx
	jne	bankstart
	pop	ds			     ; optimize if same bank
	pop	bx
	pop	ax
	popf
	ret
bankstart:
	pop	ds
	push	ds
	assume	ds:tcb
	push	ax
	push	es
	mov	es,ax
	assume	ds:nothing,es:tcb
	mov	ax,word ptr [tcbcondd]	    ; if last terminal driver is not
	mov	bx,word ptr [tcbcondd+2]    ; as same as us than we will need
	assume	ds:tcb,es:nothing	    ; to call their feh handle
	cmp	ax,word ptr [tcbcondd]
	jne	bankdiff
	cmp	bx,word ptr [tcbcondd+2]
bankdiff:
	pop	es
	pop	ax
	je	bankcont
	mov	ds,ax
	assume	ds:tcb
	lea	si,[tcbcondd]
	mov	ah,0feh 		    ; bank out last station
	call	dword ptr [si]
bankcont:
	pop	ds
	mov	cs:[savlast],ds
	pop	bx
	mov	al,byte ptr [si].port
	cmp	word ptr [tcbcondd],offset srterm
	je	banknvna
;
;	This is special case handle for co-existence with VNA style
;	workstations, when VNA calls what it believes is the master
;	console but actually it will be pointing to srterm.sys handler
;
	push	cs
	pop	ds
	assume	ds:code
	xor	al,al
	mov	[curega],al	; bank all sunrivers out
	call	bankswitch
	push	bx
	push	cx
	push	dx
	push	si
	push	di
	push	ds
	lds	bx,[scbptr]			; unmap all area use by
	assume	ds:scbs 			; sunriver
	cmp	byte ptr [bx+scbvnasys],'Y'
	jne	skipvna
	mov	word ptr [bx+scbtcbvr],0
	mov	word ptr [bx+scbtcbvs],0
	pop	ds
	assume	ds:code
	mov	dx,0a000h
	mov	cx,32				; unmap all of memory
	xor	al,al
	call	dword ptr [mapvma]
skipvna:
	pop	di
	pop	si
	pop	dx
	pop	cx
	mov	ah,0feh
	call	master
	jmp	short bankout
banknvna:
	push	cs
	pop	ds
	assume	ds:code
	mov	[curega],al
	call	switchega		; do the actual switch
	push	bx
bankout:
	push	ds
	lds	bx,scbptr
	assume	ds:scbs
	mov	ax,[savlast]
	mov	[bx+scblastff],ax	; set lastff to tcb
	pop	ds
	pop	bx
	pop	ax
	popf
	ret
bankin	endp

	subttl	bankswitch - low-level context switcher for SunRiver
	page
;-----------------------------------------------------------------------;
; BankSwitch:								;
; Input:								;
;	AL = Port Address						;
;	ES = Points to host adapter's status and control registers	;
;									;
; This routine switch the host adapter to desired station, master 	;
; console if port is 0 or greater than maximun terminals on system.	;
;									;
; Derives the desired channel values (for stations, 1 less than the	;
; port), ffh for master console 					;
;-----------------------------------------------------------------------;

	assume	ds:code
bankswitch proc near
	pushf
	cli
	xor	ah,ah
	cmp	ax,[maxterm]
	ja	swega0
	or	al,al
	jnz	swega1
swega0:
	mov	ax,256			; diable all channels
swega1:
	dec	ax
swega2:
	call	getchan
	call	DoChan				; set channel
	cmp	al,0ffh
	je	swega2a
	and	byte ptr es:[MODEREG],NOT 04h	; turn offswitching
swega2a:
	popf
	ret
bankswitch endp



	subttl	SWITCHEGA - actual context switcher for SunRiver Host Adapter
	page
;-----------------------------------------------------------------------;
; SWITCHEGA:								;
; Input:								;
;	AL = Port Address						;
;	ES = Points to host adapter's status and control registers	;
;									;
; This routine switch the host adapter to desired station, master 	;
; console if port is 0 or greater than maximun terminals on system.	;
; This routine does the following steps:				;
;	1. call low-level routine Bankswitch to switch station in	;
;	2. switch in the video						;
;	3. if master console, call mosddtmc's ffh routine		;
;									;
; NOTE: This is where special case handling of VGA cards will be handle ;
;-----------------------------------------------------------------------; 

	assume	ds:code
switchega proc	near
	push	ax
	call	bankswitch

	call	MapVid			; map in video
	cmp	ax,-1
	jne	swega3
	pop	ax
	jmp	short swega4a
swega3:
	cmp	al,0ffh 		; was this a master console call
	pop	ax
	jne	swega5
swega4:
	push	ax
	mov	ah,0ffh 		; call mosddtmc ff routine
	call	master
	pop	ax
	mov	es,[workarea]
swega4a:
;
;	this is being done on the master console
;
	cmp	byte ptr [vgabios],'Y'	; VGA Bios used
	jne	swega7
 	push	ax			; this logic for enable the VGA
	mov	al,0eh			; Enable host VGA
	jmp	short swega6	
swega5:
;
;	this is being done on sunriver station
;
	cmp	byte ptr [vgabios],'Y'
	jne	swega7
        push    ax		    ; this code is use to disable the VGA
	mov	al,06h		    ; Disable host VGA
swega6:
;
;	do out 46e8h depend on station
;
        push    dx      	    ; this is the way SunRiver\Paradise	
 	mov	dx,46e8h    	; the special cable
	out	dx,al
        pop     dx
	pop	ax
swega7:
	ret
switchega endp

	subttl MAPVID - map in desired video
	page
;-----------------------------------------------------------------------;
; MAPVID: 								;
; INPUT:								;
;	AL = channel to map in (0 - MAXTERM - 1 or FFH for master       ;
;									;
; This routine is use to map in 128k between A000h and C000h, it use    ;
; the special scbmapvma calls which are designed so that drivers like   ;
; the sunriver driver can map it physical memory management needs and	;
; still have multible MOUSE support.					;
;-----------------------------------------------------------------------;

	assume	ds:code,es:nothing
MapVid	proc	near
	push	bx
	push	es
	les	bx,cs:[scbptr]
	assume	es:scbs
	cmp	byte ptr [bx+scbbankin],'N'
	je      MVExit

	mov	word ptr [bx+scbtcbvr],0
	mov	word ptr [bx+scbtcbvs],0

	push	ax
	push	cx
	push	dx

	mov	cx,2			    ; to record in list base
	mov	bx,cs

	mov	[actvid],al
	cmp	ax,[maxterm]
	jae	MVmc	

;	
;	map in the physical memory at f10,000h into the region
;	between a0000h and c0000h

	and	byte ptr es:[MODEREG], NOT 04h

	mov	al,3			  ; make list base call
	lea	dx,ListSR		  ; point to list
	call	dword ptr [mapvma]
	jmp	short MVExit1
MVmc:
	mov	al,3			  ; make list base call
	lea	dx,ListMC		  ; point to list
	call	dword ptr [mapvma]
MVExit1:
	pop	dx
	pop	cx
	pop	ax
MVExit:
	pop	es
	pop	bx
	ret
MapVid	endp

;=======================================================================;

	subttl IRQHND - SunRiver IRQ handle
	page
;-----------------------------------------------------------------------;
; IRQHND:								;
;									;
; The following is sunriver driver IRQ handler.   It is use to control  ;
; the following functions for the Terminal.				;
;	1. Power on interupt -- Terminal will send one of these when    ;
;	   some turns on the stations or when the host driver request   ;
;	   one.  The register command uses this feature to reconized    ;
;	   if terminal is actually there.				;
;	2. Keyboard Interupt -- this is use when a user presseds a key  ;
;	   on the stations keyboard.					;
;	3. Video Interupt - this is use for EGA vertical scan interupt  ;
;	4. Serial port interupts - these are use to control the serial  ;
;	   ports on the terminal.					;
;	5. parallel port interupt -- these are use control printers off ;
;	   the back of the terminal					;
; 	6. Timer interupt -- for the speaker on terminal		;
;									;
; The basical functionality of the handler is to find out which station ;
; and type of interupt cause the interupt and service it.		;
;-----------------------------------------------------------------------;


irqhnd	proc	far
	cli
	pusha
	push	ds
	push	es
	mov	bx,cs
	mov	ds,bx
	assume	ds:code
	mov	es,[workarea]

	push	word ptr [curega]
	xor	si,si
	inc	si
	mov	ax,si
	call	bankswitch
	mov	es,[workarea]
	dec	si
irqloop:
	mov	ax,si
	call	DoChan				; set channel
	test	byte ptr es:[INTCONTROL],04h	; check if bit 2 is low
	jz	irqtest
irqnext:
	inc	si
	inc	si
	cmp	si,[maxterm]
	jbe	irqloop
irqiret:
	jmp	irqfin

irqtest:
	mov	byte ptr es:[INTLATCH],al	; send any data to irq latch
	mov	al,byte ptr es:[CHANID]		; get channel ID
	mov	byte ptr [saveid],al
	call	calcmask
	shl	bx,1				; point to time out
	test	al,bl				
	jnz	irqfound
	jmp	short irqtmout
irqnxt:
	inc	si
	call	calcmask			
	shl	bx,1
	test	al,bl				; test for timeout
	jz	irqtmout2			; is this a timeout
	shr	bx,1
	test	al,bl				; test for irq
	jz	irqcont 			; has channel have an  irq
	dec	si
	jmp	irqnext
irqtmout2:
	dec	si
irqtmout:
	mov	bl,[saveid]
	not	bl
	call	clearbit			; clear timeout bit
	jmp	irqfin
irqfound:
	shr	bx,1				; point irq flag
	test	al,bl
	jnz	irqnxt
irqcont:
	mov	bx,si
	push	bx
	push	di
	mov	al,bl
	call	DoChan				; set channel
	mov	[station],bx			 ; save station pointer
	and	byte ptr es:[MODEREG], NOT 04h
	mov	[station],bx			 ; save station pointer
	call	TaskPtr 		; get task pointer
	jz	irqnot
	mov	di,bx			; save it in di for calls
	mov	bl,byte ptr es:[DEVICEREG]
	xor	bh,bh
	shl	bx,1
	call	[irqfun+bx]
	or	byte ptr es:[MODEREG],04h
	push	es
	mov	es,[workswt]
	mov	al,byte ptr es:[RESETINTRQ]		; reset interupt
	pop	es
	and	byte ptr es:[MODEREG],NOT 04h
irqnot:
	pop	di
	pop	bx
	call	calcmask
	mov	al,bl
	not	al
	cmp	al,[saveid]		    ; dual-interupt sitiution
	jne	irqcskip
	pushf				    ; not dual-interupt, so we
	cli				    ; we need so set Chanid and
	and	byte ptr es:[CHANID],al     ; continue on
	jmp	short irqexit1
irqcskip:
;
;	if we come here, we have 2 stations off of a single chip interupting
;	concurrently, this means that we must handle both interupts
;
	cmp	[once],'Y'		    ; has it came through once already
	je	irqonce 		    ; yes...on second port of chip
;
;	At this point we are done with one of the 2 ports on chip, and must do
;	it now for the other port
;
	mov	[once],'Y'
	mov	si,[station]		    ; get current station
	xor	si,01h			    ; toggle low bit for other station
	jmp	irqcont 		    ; continue
irqonce:
;
;	At this point we done with both stations on dual-interupt system
;	and must not set channel ID and acknoledge the stations
;	Notice: It is very important that both stations are acknolodge at
;	the time when channel ID is reset
;
	mov	[once],'N'
	pushf
	mov	al,[saveid]
	mov	byte ptr es:[CHANID],al     ; reset channel id register
	call	AckTerm 		    ; acknolodge current station
	mov	si,[station]
	xor	si,01h			    ; toggle to other station
	mov	ax,si
	call	DoChan			    ; Activate other station
irqexit1:
;
;	We will now acknologe station, we can come here via 2 methods
;	    1.	by a single port being interupted (from jump above irqcskip)
;	    2.	by other port on dual-interupt condition (see above)
;
	call	AckTerm
	popf
irqfin:
	pop	word ptr [curega]
	mov	al,[curega]
	xor	ah,ah
	call	bankswitch
;
;	Rearm SunRiver controller
;
	cli
	mov	dx,[rearm]
	out	dx,al			; set global re-arm
	call	ResetSR
	pop	es
	pop	ds
	assume	ds:nothing
	popa
	iret					
irqhnd	endp

	subttl - IRQ support functions
	page
;---------------------------------------------------------------;
;	Input: 	SI = channel					;
;	Output:	BX = bit mask					;
;---------------------------------------------------------------;

calcmask:
	mov	bx,0001h
	test	si,0001h
	jz	cmdone
	shl	bx,1
	shl	bx,1
cmdone:
	ret

;-----------------------------------------------------------------------;
;	Clears the bit in channel id register				;
;	Input:	bl	bit to mask out					;
;-----------------------------------------------------------------------;

clearbit proc	near
	push	ax
	mov	al,bl
	not	al
	and	byte ptr es:[CHANID],al
	pop	ax
	ret
clearbit endp

;--------------------------------------------------------------------;
;  ResetSR - reset the master and slave interupt controllers	     ;
;--------------------------------------------------------------------;

ResetSR proc near
        mov     dx,0020h                                
        mov     al,dl
        cmp     byte ptr [irq],0fh
        jbe     irqlow
        mov     dx,00a0h
        out     dx,al                   ; re-arm slave
        stall
        stall
        mov     dl,al
irqlow:
        out     dx,al
        stall
	ret
ResetSR endp

	subttl IRQ handle functions
	page
;-----------------------------------------------------------------------;
;		INTERUPT Handler Functions				;
;-----------------------------------------------------------------------;
; please note for all routines di points to station specific task info  ;
; table and that ES points to the control registers.			;
;-----------------------------------------------------------------------;

;-----------------------------------------------------------------------;
; Power ON interupt - the following is use when station does a power on ;
; interupt - status ONLINE (driver specific) is turn on by this routine ;
; and task can not be added onless this bit is on.			;
;-----------------------------------------------------------------------;

power	label	near
	or	byte ptr [di].status, ONLINE	; indicate station is on
	push	es
	mov	es,[WorkMap]
	mov	byte ptr es:[PARCONTROL],08h	; init printer
	push	cx
	mov	cx,8000h			; stall a little bit
	loop	$
	pop	cx
	mov	byte ptr es:[PARCONTROL],0ch
	pop	es
	or	byte ptr es:[MODEREG],04h	; turn switch on
	push	es
	mov	es,[workswt]
	mov	byte ptr es:[RESETINTRQ],00h
	mov	byte ptr es:[BANKSELREG],08h
	mov	byte ptr es:[BANKSELREG],00h
	pop	es
	and	byte ptr es:[MODEREG],NOT 04h	; turn switch off
	ret

;------------------------------------------------------------------;
; KEYBD - this is the stations keyboard handler, it will put the   ;
; the key scan codes into the driver 32 byte keyboard buffer in    ;
; task information table.					   ;
;------------------------------------------------------------------;

keybd	label	near
	push	ax
	push	cx
	push	si
	push	es
	mov	es,[workmap]
	call	KBWout
	mov	byte ptr es:[KEYCMDINP],0adh     ; disable keyboard
	xor	cx,cx
	pushf
	cli
kbd1:
	mov	ah,byte ptr es:[KEYSTATUS]
	test	ah,1				; outfull full
	loopz	kbd1
	mov	al,byte ptr es:[KEYDATAINP]	; get data
	cmp	al,0feh				; resend
	je	kbd2
	cmp	al,0fah				; achnolodge
	jne	kbd3		
;	
;	do keyboard achnolodge
;
	jmp	kbover
kbd2:
;
;	do keyboard resend 
;	
	jmp	kbover
kbd3:
	cmp	al,0ffh				; overrun.....
	je	kbover
	cmp	byte ptr [di].kbready,00h	; any characters
	je	kbempty
	push	si
	mov	si,word ptr [di].kbget
	cmp	si,word ptr [di].kbput		; overflow in buffer
	pop	si
	je	kbover
kbempty:
	mov	byte ptr [di].kbready,0ffh	; flag keyboard ready flag
	mov	si,word ptr [di].kbput		; get point to que
	push	di
	add	di,si
	mov	byte ptr [di].kbbuff,al
	pop	di
	call	DoLEDS				; handle LEDS on station
	inc	si
	cmp	si,KBSIZE			; test to see if over limit
	jb	kbset
	xor	si,si
kbset:
	mov	word ptr [di].kbput,si		; save new pointer	
kbover:
	call	KBWout
	mov	byte ptr es:[KEYCMDINP],0aeh	; enable keyboard	
	popf
	pop	es
	pop	si
	pop	cx
	pop	ax
	ret

;-----------------------------------------------------------------------;
; DoLEDS - This routine is use to set the keyboard status LEDS on the	;
; keyboard.  This is do by checking the 40:17 status save in the TCB as ;
; TCBKSHFT (This is necessary because keyboard IRQ could and will get	;
; get call when another task is switch into memory).  If status is	;
; is different that prevous saved status, then the routine will access	;
; memory map area to change the leds.					;
;-----------------------------------------------------------------------;

DoLEDS	proc	near
	push	ax
	push	es
	mov	es,word ptr [di].taskid 	; get TCB for station
	assume	es:tcb
	mov	al,tcbkshft			; get keyboard status
	pop	es
	assume	es:nothing
	shr	al,4				; format it for the output
	and	al,7				; to keyboard
	cmp	al,byte ptr [di].kbstat 	; same as saved?
	jne	dleds
	pop	ax				; yes...then no need to do it
	ret
 dleds:
;
;	we must now change the keyboard LEDS
;
	mov	byte ptr [di].kbstat,al
	mov	byte ptr es:[KEYDATAINP],0edh
	call	KBWout
	call	KeyACK				     ; wait for ACK
	mov	al,byte ptr [di].kbstat
	mov	byte ptr es:[KEYDATAINP],al	     ; set byte to keyboard
	call	KeyACK				     ; wait for ACK
	call	KBWout
skipled:
	pop	ax
	ret
DoLEDS	endp

;
;	This routine is use by DoLEDS to check for ACk from keyboard
;

KeyACK	proc	near
	push	cx
	mov	cx,8000h
kaloop:
	mov	al,byte ptr es:[KEYDATAINP]	; get data
	cmp	al,0fah 			; is it ACK
	loopnz	kaloop				; loop if not
	pop	cx
	ret
KeyACK	endp


;
;   The following routines are for serial ports and call common handler
;

ser1	label	near
	push	dx
	xor	dx,dx		    ; point to first port
	jmp	short sercom

ser2	label	near
	push	dx
	mov	dx,1		    ; point to second port
sercom:
	call	doisr		    ; call ISR routine
	pop	dx
	ret

par	label	near
time	label	near
egasys	label	near
	ret				
	
	subttl InitKB - initialize keyboard controller
	page
;-----------------------------------------------------------------------;
; INITKB:								;
; this procedure is use to initial the stations keyboard controller     ;
; that it will send scan codes to host adapter which will generate      ;
; IRQ so that driver can place the scan code into the keyboard buffer   ;
;-----------------------------------------------------------------------;

InitKB	proc	near
	push	ax
	push	cx
	push	es
	
	mov	es,[workmap]
	call	KBWout
	mov	byte ptr es:[KEYCMDINP],0aah	; reset keyboard controller
	call	KBWout
	mov	byte ptr es:[KEYCMDINP],060h
	call	KBWout
	mov	byte ptr es:[KEYDATAINP],049h	; setup keyboard controller
	call	KBWout
	mov	byte ptr es:[KEYCMDINP],0aeh	; enable keyboard controller
ikbend:

	pop	es
	pop	cx
	pop	ax
	ret
InitKB	endp

;
;	Following procedure waits for output buffer is empty
;
KBWout	proc	near	
	xor	cx,cx
kbwl:
	mov	ah,byte ptr es:[KEYSTATUS]
	test	ah,2
	loopnz	kbwl
	ret
KBWout	endp

;
; EnableEGA, DisableEGA - VGA Only for enabling and disable VGA
; EnableEGA means to disable VGA, DisableEGA means to Enable VGA
;
EnableEGA proc	near
	 mov	al,1
	 jmp	short EnableIt
DisableEGA:
	 xor	al,al
EnableIt:
	 push	ds
	 or	byte ptr es:[MODEREG], 04h
	 mov	ds,cs:[WorkSwt]
	 mov	byte ptr ds:[EGAENABLE],al
	 and	byte ptr es:[MODEREG], NOT 04h
	 pop	ds
	 ret
EnableEGA endp



	subttl VidInit - video initialization routine
	page
;-----------------------------------------------------------------------;
; VIDINIT:								;
; This routine is pointed by TCBVIDSET and is use to set up the terminal;
; when the task's context is finally inplace.				;
;-----------------------------------------------------------------------;

VidInit proc	far
	pusha
	push	ds
	push	es

	assume  ds:nothing,es:nothing,ss:nothing	
	push	cs
	pop	ds

	push	word ptr [curega]
	mov	bx,es
	call	FindPtr
	jne	vicont
	jmp	viskip	
vicont:
	inc	ax
	mov	[curega],al
	mov	es,[workarea]
	call	switchega
	call	InitKB
;
;	the following code is to enable VGA display on VGA stations
;	this is necessary because the folks at SunRiver disable the
;	display when display is first power up.
;
	cmp	byte ptr [vgabios],'Y'
	je	vivga
	jmp	viega
vivga:
	push	dx
	push	es
	pushf
	push	ds

	mov	cx,-1
	loop	$

	mov	ds,[workmap]
	call	EnableEGA
	mov	byte ptr ds:[03c2h],00h
	call	DisableEGA
	mov	es,cs:[workswt]
	mov	bx,cs:[baseaddr]
	add	bx,4		; point to 5 bank
	mov	cx,1
	mov	ah,5
	call 	dword ptr cs:[memman]
	mov	byte ptr es:[46e8h-4000h],10h
	mov	byte ptr ds:[102h],01h
	mov	byte ptr es:[46e8h-4000h],08h
        mov	bx,cs:[baseaddr]
	add	bx,10h
	mov	cx,1
	mov	ah,5
	call 	dword ptr cs:[memman]	  

	mov	es,[workarea]
	mov	al,byte ptr ds:[3ceh]
	mov	al,byte ptr ds:[3ceh]
	mov	byte ptr ds:[3ceh],0fh
	mov	byte ptr ds:[3cfh],05h
	mov	byte ptr ds:[3ceh],0eh
	mov	byte ptr ds:[3cfh],00h
	mov	byte ptr ds:[3ceh],0dh
	mov	byte ptr ds:[3cfh],00h
	mov	byte ptr ds:[3ceh],0ch
	mov	byte ptr ds:[3cfh],00h
	call	EnableEGA
	mov	byte ptr ds:[3c2h],00h
	call	DisableEGA
	mov	al,byte ptr ds:[3dah]	
	mov	al,byte ptr ds:[3bah]	
	mov	byte ptr ds:[3c0h],20h

	pop	ds
	popf
	pop	es
	pop	dx
viega:
	call	Enable

	mov	ax,0303h
	call	master
	mov	es,[workarea]

	pop	word ptr [curega]
	mov	al,[curega]
	call	switchega

viskip:
	pop	es
	pop	ds
	popa
	ret
VidInit endp

;-----------------------------------------------------------------------;
; MASTER:								;
; This routine is use to call MOSDDTMC master console routines if       ;
; if necessary by driver. Notice that ES will change during this 	;
; this call and must be handle correctly				;
;-----------------------------------------------------------------------;


master	proc	near
	push	si
	push	ds
	mov	es,[orges]		; get original ES value
	mov	ds,[tcbseg]		; get ds:si
	mov	si,[ddtoff]
	push	ds
	push	si
	assume  ds:tcb
	call	dword ptr cs:[mcdriver] ; call mosddtmc
	pop	word ptr [ddtoff]
	pop	word ptr [tcbseg]
	pop	ds
	pop	si
	ret
master	endp


;=======================================================================;

assume	cs:code,ds:code
AckTerm	proc	near
	pushf
	cli
	or	byte ptr es:[MODEREG],04h	; turn switch on
	push	es
	mov	es,[workswt]
        mov     byte ptr es:[REARMCONTROL], al  ; rearm control
	pop	es
	and	byte ptr es:[MODEREG],NOT 04h	; turn switch off
	popf
	ret
AckTerm endp

;=======================================================================;
;-----------------------------------------------------------------------;
; TaskPtr - return task pointer to internal table                       ;
; Input:                                                                ;
;       BX = task ID = 0 - MAX - 1                                      ;
; OutPut                                                                ;
;       BX = FFFFh (if error)                                           ;
;       BX = offset into table                                          ;
; Note: Assumes that task structure is 16 bytes                         ;
;-----------------------------------------------------------------------;

	assume	ds:code
TaskPtr proc    near
        cmp     bx,[maxterm]    
        jae     tperr
	push	ax
	shl	bx,4		;  offset = srtab + (id)*48
	mov	ax,bx		;
	shl	ax,1		;
	add	bx,ax
	pop	ax
        add     bx, offset srtab
        cmp     bx,-1           ; clear zero flag
        ret
tperr:
        mov     bx,-1           ; indicated error
        cmp     bx,-1           ; set zero flag
        ret
TaskPtr endp

;-----------------------------------------------------------------------;
; FindPtr - find task pointer in drivers data structures                ;
; Input:                                                                ;
;       BX = Tcb of task (TaskID)                                       ;
; Output:                                                               ;
;       AX = terminal id                                                ;
;       BX = task id (or ffffh if not found)                            ;
;-----------------------------------------------------------------------;

	assume	ds:code
FindPtr proc    near
        push    cx
        push    si
	mov	si,offset srtab
        mov     cx,[maxterm]
fploop:
        cmp     cs:[si].TaskId,bx  ; is this the task
        je      fpfound
        add     si,30h          ; assume that structure if 48 bytes
        loop    fploop
        mov     bx,-1           ; not found - indicate error
	jmp	short fpdone

fpfound:
	xor	bh,bh
        mov     bl,cs:[si].termid
	mov	ax,bx		; place termid in ax
	mov	cx,bx
	shl	bx,1
	add	bx,cx		; bx=termid*3
	shl	bx,4		; bx = bx * 16 (termid*48)
	add	bx,offset srtab
	
fpdone:
        pop     si
        pop     cx
        cmp     bx,-1           ; if not found - set zero flag
        ret
FindPtr endp

;-----------------------------------------------------------------------;
; prchar - print a character to local printer                           ;
;       AL = character to print                                         ;
;-----------------------------------------------------------------------;

	assume	ds:nothing,es:nothing,ss:nothing
prchar	proc	near
	push	cx
	push	es
	mov	es,[WorkMap]
	mov	byte ptr es:[PARDATA],al	; write byte to port
	mov	cx,14h
pcloop1:
	push	cx
	xor	cx,cx
pcloop2:
;
;	test to see if port is busy
;
	test	byte ptr es:[PARSTATUS],80h
	jnz	pcok
	loop	pcloop2
	pop	cx
	loop	pcloop1
	mov	al,byte ptr es:[PARSTATUS]	; get printer status
	mov	ah,al
	and	ah,0f8h 		; clear unused bits
	or	ah,1			; set error
	jmp	short pcdone
pcok:
;
;	printer is not busy and character printed
;
	pop	cx
	mov	byte ptr es:[PARCONTROL],0dh	; strobe high
	jmp	short $+2
	jmp	short $+2
	mov	byte ptr es:[PARCONTROL],0ch	; strobe low
	mov	al,byte ptr es:[PARSTATUS]	; get printer status
	mov	ah,al
	and	ah,0f8h
pcdone:
	xor	ah,48h				; invert signals
	pop	es
	pop	cx
	ret
prchar	endp

;-----------------------------------------------------------------------;
; DoChan - set channel, wait until channel is not busy			;
;	AL = channel to set AH=0					;
;	ES = segment fo work area					;
;-----------------------------------------------------------------------;

	assume	ds:code

DoChan	proc	near
	cmp	[DoChVal],0ffh 		
	je	DoChan3
	push	cx
	mov	cx,-1
DoChan1:
	test	byte ptr es:[IRQSEL],4
	jz	DoChan2
	loop	DoChan1
DoChan2:
	pop	cx
DoChan3:
	mov	[DoChVal],al
	mov	byte ptr es:[CHANSEL],al
	ret
DoChan	endp

;---------------------------------------------------------------;
; GETCHAN:							;
; Get current channel from curega				;
;---------------------------------------------------------------;

getchan proc	near
	mov	al,[curega]
	or	al,al
	jz	gcmc
	xor	ah,ah
	cmp	ax,[maxterm]
	ja	gcmc
	dec	ax
	ret
gcmc:
	mov	ax,255
	ret
getchan endp


;-----------------------------------------------------------------------;
; ENABLE:								;
; 	turns on the stations EGA IO mappings so that outs to EGA    	;
;	register will go to station physical memory at base		;
;-----------------------------------------------------------------------;

Enable	proc	near
	cmp	[vgabios],'Y'
	jne	DoEnable
	ret
DoEnable:
	pushf
	push	ax
	push	es
	cli
	or	byte ptr es:[MODEREG],04h	; turn switch memory on
	mov	es,[workswt]
	or	byte ptr es:[EGAENABLE],01h
	mov	al,byte ptr es:[ACTINTRQ]
	pop	es     
	and	byte ptr es:[MODEREG],NOT 04h	; turn switch memory off
	pop	ax
	popf
	ret
Enable  endp

;-----------------------------------------------------------------------;
; CHANTEST:								;
; This routine is use to test to see if channel is present during INIT  ;
; time - notice that I said channel and not station.  Station presince  ;
; is taking place during the register call when a reset to station is   ;
; done.									;
;-----------------------------------------------------------------------;


	assume	ds:code
ChanTest proc   near
         push   ax
         mov    ax,si
	 mov	byte ptr es:[CHANSEL],al	  ; set channel
         mov    byte ptr es:[MODEREG],0fch        ; set mode to fch
         cmp    byte ptr es:[MODEREG],04h         ; if not 04h - channel fail
         jne    ctfail
	 mov	byte ptr es:[MODEREG],01h	  ; set to mode 1
         clc                                      ; success
         jmp    ctdone
ctfail:
         stc                                     ; failed        
ctdone:
         pop    ax
         ret
ChanTest endp

;-----------------------------------------------------------------------;
; INITCVARS:							      	;
; INPUT:								;
;     AL = status to set channel to					;
;     BX = pointer to task information table				;
;     SI = Terminal ID							;
; Initialize the channel specific variables			      	;
;-----------------------------------------------------------------------;

	assume	ds:code
InitCVars proc	near
        mov     word ptr [bx].termid,si
        or      byte ptr [bx].status,al
        mov     word ptr [bx].taskid,-1		; no task is added yet
	xor	ax,ax				; clear ax value below
        mov     byte ptr [bx].kbready,al
	mov	word ptr [bx].kbput,ax
	mov	word ptr [bx].kbget,ax
	ret
InitCVars endp


	include	vidchk.inc


	subttl boot_prep - prepare the video state for a reboot
	page
;======================================================================
; .func: boot_prep - prepare the video state for a reboot
;
; input:
;	
; output:
;
; comments:
;
; .calls: 
; .reads: 
; .writes: 
;
; .endfn
;======================================================================
	assume	cs:code,ds:nothing,es:nothing,ss:nothing
boot_prep:
	mov	es,[workarea]
	xor	ax,ax
	mov	[curega],al		; make sure master console is switchin
	call	switchega
	ret


FarPatch proc	far
	 cmp	cx,8
	 ja	farskip
	 mov	es,dx
	 call	dword ptr cs:[memman]
farskip:
	 ret
FarPatch endp

;
;   The following include statement are for installing of MOS
;   generalize INT 14 code, suniomac.inc is definitions of macros
;   which is use in the sunriver case
;
	include suniomac.inc
	include int14.inc
	include isrsub.inc

	subttl clr_set_irq - dummy (only needed by _serial.asm)
	page
;======================================================================
; .func: clr_set_irq - dummy (only needed by _serial.asm)
;
; input:
;	ch = 0 to clear, 1 to set
;	cl = irq number
;
; .calls: 
; .reads: 
; .writes: 
;
; .endfn
;======================================================================
clr_set_irq:
	ret


;   The following routine is use by INT 14 main logic to verify is port
;   actually exist on the sunriver work station
;   Returns zero if not online
;
sckport proc	near
	push	ax
	push	bx

	mov	bx,[SCDX]	; get port
	shr	bx,1		;
	shl	bx,4		;  offset = srtab + (port/2)*48
	mov	ax,bx		;
	shl	ax,1		;
	add	bx,ax
	test	byte ptr cs:[bx+srtab].status, ONLINE

	pop	bx
	pop	ax
	ret
sckport endp
;
;	The following routine is the common ISR routine call be COM1 and COM2
;	communications ISR routines for accessing com ports
;
	assume	ds:nothing
doisr	proc	near
	pusha
	push	ds
	push	es
	pushf

	cld				; make sure direction flag is clear
	cli
	push	cs
	pop	ds
	assume	ds:code
	mov	bx,[station]		; get station
	shl	bx,1			; 2 ports per station
	add	bx,dx			; take account of which port
	mov	cl,5
	shl	bx,cl			; each port structure is 32 bytes
	add	bx,[portoff]
	mov	dx,[bx].addr
	or	dx,dx
	jle	disisr			; is port disable
	mov	[isrcount],MAXISR
isrloop:
	dec	[isrcount]
	push	dx
	RDIIR
	test	al,noint		; is it interupting
	jnz	noisr
	mov	[isrcount],0
	and	ax,0fh			; keep only lower 4 bits
	mov	si,ax
	call	inttbl[si]		; call interupt routine
	pop	dx
	jmp	short	disisr
noisr:
	pop	dx
	cmp	[isrcount],0
	jne	isrloop
disisr:
	popf
	pop	es
	pop	ds
	popa
	ret
doisr	endp

;=======================================================================
        subttl  ddtinit - mos device driver init
        page
;-----------------------------------------------------------------------;
; initialization - set driver length and exit                           ;
;-----------------------------------------------------------------------;
	assume	cs:code,ds:code,es:nothing
ddtinit proc	near
	push	bx
	push	es
	call	initddt
	jnc	okmos
	jmp	derror
okmos:
	assume	es:scbs
;
;       test for memory managemnet
;
        cmp     [bx+SCBMMFG],'Y'        ; Memory management use
	je	mmok
	mov	dx, offset nomm
	jmp	derror
mmok:
	call	CLineTest		; Command line test
	jc	derror1
	call	MasterTest		; test for master console driver
	jc	derror1
	call	EgaTest 		; test for EGA
	jnc	okega			; EGA Bios!
derror1:
	jmp	derror
okega:
	call	setmmptr		; setup MM pointer
;
;       detect if sunriver host adapter is on system
;
	mov	es,[workarea]
        call    InitSun
        cmp     [maxterm],0
        jne	okhost
	mov	dx, offset nohost
	jmp	derror
okhost:
	call	install14		; install int 14 handler
;
;       initial host adapter and data area
;
	mov	ax,[maxterm]		;\
        mov     ah,al                   ; \
        shl     ah,1                    ;  [maxterm * 3]
        add     al,ah                   ; /
        xor     ah,ah                   ;/
        shl     ax,1
        shl     ax,1
        shl     ax,1                    ;   [maxterm * 3]*16
        shl     ax,1                    ;       + srtab
	mov	[srsize],ax
	push	cs
	pop	es
	mov	cx,ax
	shr	cx,1
	xor	ax,ax			; initialize table to zeros
	mov	di, offset srtab
	rep	stosw
;
;	Initialize Serial Int 14 data area
;

	lea	ax,srtab+15
	add	ax,[srsize]
	mov	cl,4			; calculate startsegment of
	shr	ax,cl			; serial data area
	mov	cx,cs
	add	ax,cx
	mov	[sportseg],ax		; save it
	mov	es,ax
;
;	calculate start of buffer area
;	IE startseg = sportseg + [maxterm] * 2

	mov	ax,[maxterm]
	shl	ax,1
	add	ax,[sportseg]
	mov	si,ax
;
;	now loop through all of data structures, initializing necessary
;	bytes and all of the rest to zero
;
	mov	dx,03f8h			; first port is com1
	xor	di,di
	mov	cx,[maxterm]
	shl	cx,1				; remember 2 ports
iploop:
	push	cx
	push	di
	xor	ax,ax
	mov	cx,16
	rep	stosw
	pop	di
	mov	word ptr es:[di].addr,dx	; save port
	or	word ptr es:[di].addr,8000h	; disable port
	dec	dh
	cmp	dh,1h				; toggle bettween port
	ja	ipport				; 03f8 and 02f8h
	mov	dh,3h
ipport:
	mov	word ptr es:[di].ibfseg,si
	mov	word ptr es:[di].ibfsiz,isize
	add	si,(isize/16)
	mov	word ptr es:[di].obfseg,si
	mov	word ptr es:[di].obfsiz,osize
	add	si,(osize/16)
	pop	cx
	add	di,32
	loop	iploop
	mov	[endofdata],si
;
;	initialize serial related data
;
	mov	cx,cs
	mov	ax,[sportseg]
	sub	ax,cx
	shl	ax,1
	shl	ax,1
	shl	ax,1				; convert segment to offset
	shl	ax,1
	mov	[portoff],ax			; save port offset
	mov	ax,[maxterm]
	shl	ax,1				; 2 com ports per station
	mov	[numport],ax
;
; Setup ListSR (list base memory) table for baseaddress other that 0f0,0000
;
	cmp	[baseaddr],0f00h
	je	SListSR
	mov	bx,[baseaddr]
	sub	bx,0f00h
	add	[ASR1],bx
	add	[ASR2],bx
SListSR:
;
;	Initialize SunRiver hardware now
;
	mov	es,[workarea]
	call	MapIO
	xor	al,al
	mov	byte ptr es:[CHANSEL],al
        mov     bl,byte ptr es:[IRQSEL]
        and     bl,03h
        shl     bl,1
	mov     bh,bl
        shl     bh,1
        add     bl,bh
        xor     bh,bh                           ; mult by 6 to get table entry
        mov     al,byte ptr [irqtab+bx]         ; get irq
        mov     [irq],al                        
        mov     ax,word ptr [irqtab+bx+1]       ; get re-arm port address
        mov     [rearm],ax
        mov     ax,word ptr [irqtab+bx+3]       ; get ascii irq value
        mov     word ptr [irqst],ax
	mov     al,byte ptr [irqtab+bx+5]	; get irq mask
	mov     [irqmask],al

	mov	bx,[maxterm]
insloop:
	mov	si,bx
        push    bx
	dec	si
	dec	bx
        call    TaskPtr         ; get offset to task structure
	jz	insskip
	call	ChanTest
	jc	insfail
	mov	al,ACTIVE	; mark it as active
	pushf
	cli
	call	Enable
	popf
insfail:
	call	InitCVars
insskip:
	pop	bx
        dec     bx
        jnz     insloop

	jmp	ddtinok

derror	label	near
	push	dx
	mov	dx, offset ninsmsg
        mov     ah, 9
        int     21h
        pop     dx
        int     21h             ; display approviated message
        mov	dx, [errout]
	mov	ah,9
        int     21h
	pop	es
	pop	bx
	mov	word ptr [srname],'\\'		; can't be opened
	mov	word ptr es:[bx+14], offset request
	mov	es:[bx+16],cs
	ret

ddtinok label	near
	mov	dx, offset insmsg
        mov     ah, 9
	int	21h
	mov	dx, offset warea
	mov	ah,9
	int	21h
        mov     ax,[maxterm]
        xor     dx,dx
        div     [wordten]
        or      ax,ax
        jnz     ddtin1
        mov     al,' '
        jmp     ddtin2
ddtin1:
        add     al,'0'
ddtin2:
        mov     ah,dl
        add     ah,'0'
        mov     word ptr [statmsg],ax           
	mov	dx, offset statmsg
        cmp     byte ptr [statmsg],' '
        jne     ddtdisp
        inc     dx
ddtdisp:
	cmp	[vgabios],'Y'
	je	dovga
	mov	byte ptr [vgamsg],'E'
dovga:
	push	dx
	mov	dx, offset vermsg
	mov	ah,9
	int	21h
	mov	dx, offset vgamsg
	mov	ah,9
	int	21h
	pop	dx	
        mov     ah,9
        int     21h
	mov	dx, offset irqmsg
	mov	ah,9
	int	21h

alldone label   near
;
;       Activate Selected IRQ
;
        xor     ax,ax
        mov     es,ax
        mov     bl,[irq]
        xor     bh,bh
        shl     bx,1
        shl     bx,1
        mov     ax,word ptr es:[bx]
        mov     word ptr [oldirq],ax
        mov     ax,word ptr es:[bx+2]
        mov     word ptr [oldirq+2],ax
        lea     ax,irqhnd
        cli
        mov     word ptr es:[bx],ax
        mov     word ptr es:[bx+2],cs
        sti

	cmp	byte ptr [irq],0fh
	ja	highirq
	cli
	in	al,21h
	stall
	and     al,[irqmask]
	out	21h,al
	jmp	endirq
highirq:
	cli
	in	al,0a1h
	stall
	and     al,[irqmask]
	out	0a1h,al
endirq:		
	sti
;
;	set vidcheck routine for pam switching and reboot
;
	push	bx
	mov	ah,2
	int	SERVICES
	assume  es:scbs
	mov	word ptr es:[bx+scbvidchk],offset vidchk
	mov	word ptr es:[bx+scbvidchk+2],cs
	pop	bx

;
;       set master console to us and arm controler
;
        mov     es,[mctcb]
        assume  es:tcb
	or	[tcbvram],0ch		; Set sunriver interface
        mov     word ptr [tcbcondd.port],0
	mov	word ptr [tcbcondd], offset srterm
	mov	word ptr [tcbcondd+2], cs
        push    dx
        mov     dx,[rearm]
        out     dx,al
        pop     dx
	pop	es
	pop	bx
	push	bx
	mov	ax,[endofdata]
	mov	bx,cs
	sub	ax,bx
	shl	ax,1
	shl	ax,1
	shl	ax,1
	shl	ax,1
	pop	bx
	mov	word ptr es:[bx+14],ax
        mov     es:[bx+16],cs
	mov	ax,0100h
	ret
ddtinit endp


	subttl MAPIO - map in the stations IO
	page
;-----------------------------------------------------------------------;
; MAPIO:								;
; This routine does the following mapping:				;
; 	1. Maps control register at base + f000h to workarea		;
;	2. Maps switch memory at base + 10000h to workarea + 400h	;
;	3. Maps registers at base to work area + 800h			;
;-----------------------------------------------------------------------;
	assume	ds:code
MapIO   proc    near
        push    ax
        push    bx
        push    cx

	mov	bx,[baseaddr]
        add     bx,00fh
        mov     cx,1
	mov	ah,5
	call	dword ptr [memman]
	push	es
	mov     bx,[baseaddr]
        mov     es,[workswt]                                
        add     bx,010h
        mov     cx,1
        mov     ah,5
        call    dword ptr [memman]
	mov	es,[workmap]
        mov     bx,[baseaddr]
        mov     cx,1
        mov     ah,5
        call    dword ptr [memman]
	pop	es

	call	getchan
	call	DoChan				; set channel
	cmp	al,0ffh
	je	MapIO1
	and	byte ptr es:[MODEREG],NOT 04h	; turn offswitching
MapIO1:

        pop     cx
        pop     bx
        pop     ax
        ret
MapIO   endp


statmsg db	' 0 SunRiver Stations detected on system.         ',13,10,'$' ;@@XLAT
insmsg	db	'installed with work area at $       ' ;@@XLAT
warea   db      'nnnn0H.',13,10,'$'
ninsmsg db	'not installed.      ',13,10,'$' ;@@XLAT
nohost	db	'SunRiver Host Adapter$        ' ;@@XLAT
errmsg	db	' is required for SRTERM to function correctly.        ',13,10,'$' ;@@XLAT
crlf    db      13,10,'$'
irqmsg	db	'IRQ '
irqst	db	' 0 Selected for station interupt control            ',13,10,'$' ;@@XLAT
vgamsg	db	'VGA System Detected.',13,10,'$' ;@@XLAT
vermsg	db	'Version 2.00 (900628) - $' ;@@XLAT

errout 	dw	offset errmsg
wordten dw      10
srsize	dw	0

	subttl - Init Code which is removed from driver at run time
	page
;
;	The following label SRTAB must be the last byte in the object code
;	This is where driver places the dynamic task structure.  Init
;	code could be place down here to reduce total size of drivers
;	code in the SMP.
;
srtab	label	byte
;	
;	the following messages are overlay with SRTAB data
;
nomm	db	'Memory Mangement Driver$      ' ;@@XLAT
noega	db	'EGA Bios$       ' ;@@XLAT
nowork	db	'Correct Work Area address$      ' ;@@XLAT
badmos	db	'PC-MOS Rel 4.00 or greater$        ' ;@@XLAT
ddtmsg	db	13,10,'SunRiver EGA terminal device driver $        ' ;@@XLAT
twice	db	'SRTERM should not be loaded twice!$        ' ;@@XLAT
nmouse	db	'SRTERM must be loaded before PC-MOS MOUSE driver$               ' ;@@XLAT
;
; 	the following procedures are overlayed with dynamic task 
;	structure of return to SMP space
;
CLineTest proc	near

;
;        test command line for work space address
;
;	 Return carry set if entry is bad
;
         les   bx,dword ptr [request]
         les   bx,dword ptr es:[bx + 18]  ; get parameter pointer

scan1:
         inc   bx
         mov   al,es:[bx]            ; scan for blank
         cmp   al, 0dh
         jne   scan1a
         jmp   scandone              ; return terminates

scan1a:
         cmp   al, 20h               ;
         jne   scan1                 ; repeat until blank

scan2:
         inc   bx                   ; scan for non-blank
         cmp   byte ptr es:[bx], ' '    
         je    scan2
         cmp   byte ptr es:[bx],'0'
         je    scan2
         cmp   byte ptr es:[bx],0ah     
         jne   scan2a
         jmp   scandone
scan2a:
         xor   dx, dx               ; zero work address
         xor   cx, cx
         xor   ah, ah
         lea   di, warea

scan3:
         mov   al, byte ptr es:[bx]  ; get hex value
         inc   bx
         cmp   al, '0'
         jb    scanchk
         cmp   al, '9'
         ja    scanhex
         sub   al,'0'
         jmp   scannext

scanhex:
         cmp   al,'a'
         jb    scanhex2
         cmp   al,'f'
         ja    scanchk
         sub   al,'a'-10
         jmp   scannext
         
scanhex2:
         cmp   al,'A'
         jb    scanchk
         cmp   al,'F'
         ja    scanchk
         sub   al,'A'-10

scannext:                                ; adjust value
         shl   dx, 1
         shl   dx, 1
         shl   dx, 1
         shl   dx, 1
         add   dx, ax
         cmp   al, 10
         jb    scanlow
         add   al, 'A'-10
         jmp   scanout

scanlow:
         add   al, '0'   

scanout:
         mov   cs:[di], al
         inc   di
         inc   cx
         cmp   cx, 4
         jb    scan3

scanchk:
         cmp   cx, 4                    ; for bytes
         jne   scanbad
	 cmp   dx,0c000h		; can't be lest than c000h
	 jb    scanbad
         mov   ax, dx                   ; check for 4k bondary
         and   ax, 0ff00h
         cmp   ax, dx
         je    scangood
scanbad:
	stc
	mov	dx, offset nowork
	ret

scandone:
        mov     dx,0ec00h               ; default to ec000h
        mov     word ptr cs:[warea],'CE'
        mov     word ptr cs:[warea+2],'00'

scangood:
        mov     [workarea],dx           ; save work area
	add	dx,0100h
	mov	[workswt],dx		; set switch memory
	add	dx,0100h
	mov	[workmap],dx		; set map memory
	clc
	ret
CLIneTest endp

MasterTest proc	near
;
;       get master console driver       
;

	lds	bx,cs:[scbptr]		   ; point to scb
	assume	ds:scbs
        push    bx
        push    ds

	mov	ds,[mctcb]
	assume	ds:tcb
        lds     bx,[tcbcondd]
        cmp     word ptr [bx-3],'AS'    ; chech if loaded twice
        jne     not2x 
        cmp     byte ptr [bx-1],'H'
	jne	not2x
        mov     word ptr [errout],offset crlf
	mov	dx, offset twice
	stc
	jmp	short mtexit
not2x:
        mov     word ptr [mcdriver],bx
        mov     word ptr [mcdriver+2],ds
	clc
mtexit:
	pop	ds
        pop     bx
	push 	cs
	pop	ds
	assume	ds:nothing
	ret
MasterTest endp

EgaTest	proc	near
;
;       detect if EGA is on system
;
	push	ds
	mov	ds,cs:[mctcb]
	assume	ds:tcb
	mov	al,[tcbstation]     ; Get Station of Master console TCB
	pop	ds
	cmp	al,5		    ; OK if Monochrome EGA (5)
	je	etok
	cmp	al,2		    ; Error is below EGA (2)
	jb	etbad
	je	etok		    ; OK if equal to EGA
	cmp	al,6		    ; OK if MonoChrome VGA (6)
	je	etvga
	cmp	al,3		    ; Error if above VGA (3)
	ja	etbad
etvga:
	mov	cs:[vgabios],'Y'    ; set flag to indicate that we have VGA
etok:
	clc
	ret
etbad:
	stc
	mov	dx, offset noega    ; return error message address
	ret
EgaTest endp


setmmptr proc	near
;
;       setup memory manager pointer
;
	push	cs
	pop	es
	lds	bx,cs:[scbptr]
	assume	ds:scbs
	lea	si,[bx+scbmmsub]
        lea     di,memman
        mov     cx,2
        rep     movsw
	lea	si,[bx+scbmapvmf]
	lea	di,mapvma
	mov	cx,2
	rep	movsw
        push    cs
        pop     ds
	assume	ds:code
	ret
setmmptr endp

        assume  ds:nothing
InitSun  proc   near
;
;	Init Sun River hardware
;
         push   bx
         push   si
         mov    bx,0f00h
IsunLP:
         call   Isun1
         add    bx,0040h
         cmp    bx,0fc0h
         jb     IsunLP
         pop    si
         pop    bx
         ret
Isun1:
         push   ax
         push   bx
	 push	word ptr [baseaddr]
	 mov	[baseaddr],bx
         call   MapIO
	 pop	word ptr [baseaddr]
         xor    si,si
	 mov	byte ptr es:[CHANSEL],00h
Isun2:
         call   ChanTest
         jc     Isun3
         mov    [baseaddr],bx                   ; save base address
         inc    [maxterm]
         inc    [maxterm]

         mov    byte ptr es:[MODEREG],01        ; set mode to 1
         mov    byte ptr es:[INTLATCH],al       ; write data to latch
         mov    al,byte ptr es:[CHANID]
         mov    byte ptr es:[CHANID],00h        ; set channel reg to 00
         mov    byte ptr es:[INTCONTROL],01     ; set int cntrl reg to 1
         jmp    Isun4
Isun3:
Isun4:
         inc    si
         inc    si
         cmp    si,MAXID
         jb     Isun2

         pop    bx
         pop    ax
         ret
InitSun  endp


initddt	proc	near
;
;	done for run-time space optimizization
;
        push    cs
        pop     ds

	call	PatchMOS	; patch mos
	jc	initexit
	call	ChkMouse	; check for mouse  driver
	jc	NoMouse
	mov	word ptr [errout], offset crlf
	lea	dx,nmouse	; display mouse error
	stc
	jmp	initexit
NoMouse:
        mov     ah,02h
	int	SERVICES
        assume   es:scbs
        mov     [scbseg],es
	mov	[scboff],bx
	mov	dx,[bx+scbtcbpf]	; get foreground tcb
	mov	[mctcb],dx		; save it for later
	clc
initexit:
	pushf
	push	dx
	lea	dx, ddtmsg
        mov     ah, 9
	int	21h
	pop	dx
	popf
	ret
initddt endp

;------------------------------------------------------------------;
; PatchMOS - Check and Patches MOS if necessary.		   ;
;								   ;
; Steps:							   ;
;     1. Return error message if not atleast PC-MOS/386 rel 4.00   ;
;------------------------------------------------------------------;

PatchMOS proc	 near
	 mov	ah,30h
	 int	21h		    ; get DOS version
	 push	ax
	 mov	ah,30h
	 mov	bx,ax
	 mov	cx,ax
	 mov	dx,cx
	 int	21h		    ; get MOS version
	 pop	cx
	 cmp	ax,cx
	 je	PatchBad
	 cmp	al,04h
	 jb	PatchBad
	 clc
	 ret

PatchBad:
	 if	VERSION
	 stc
	 mov	dx,offset badmos	
	 else
	 clc
	 endif
  		
	 ret
PatchMOS endp
ChkMouse proc	near
	 push	ds
	 push	cs
	 pop	ds
	 lea	dx,[moudriver]
	 mov	ax,3d00h
	 int	21h
	 pop	ds
	 ret
ChkMouse endp


Install14 proc	near
	mov	ah,6		; check to see if INT 14 handler, already
	xor	dx,dx
	int	14h		; is install, if not then install our handler
	test	ah,80h		; test high bit to see if installed
	jz	setint14
;
;	if we come here this means that we must link our driver in as child
;
	push	es
	push	cs
	pop	es
	lea	bx,int14	  ; register child with serial driver
	mov	ah,10h
	int	14h
	pop	es
	jmp	short donein14
;
;	This is were we would install our INT 14 handler
;
setint14:
	push	ds
	push	cs
	pop	ds
	lea	dx,int14	    ; install our int 14 handler
	mov	ax,2514h
	int	21h
	pop	ds
donein14:
	push	es
	push	bx
	mov	ax,3500h+SERVICES
	int	21h			    ; save 38 vector for serial logic
	mov	word ptr cs:[orig38],bx
	mov	word ptr cs:[orig38+2],es
	mov	ax,351ah
	int	21h			     ; save 1a vector for serial logic
	mov	word ptr cs:[orig1a],bx
	mov	word ptr cs:[orig1a+2],es
	pop	bx
	pop	es
	ret
Install14   endp

if1
	%out - Pass 1 Completed.
else  
        %out - Pass 2 Completed.
endif

code	ends
        end

