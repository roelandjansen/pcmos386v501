;option  nokeyword:<addr>
	include page.inc
	title	_serial.asm - mos standard serial port device driver

comment ^==============================================================
		      development specification

 program name:	_serial.asm			assigned to: rod girod
 module name:	$serial.sys			assign date: 01/10/89
 entry points: 	mosint14			completed:   02/13/89
 entry from:   	anywhere
 entry method: 	int 14h
 calls:
 purpose:	provide interupt driven serial i/o for all int 14
		functions.
 refer to:	n/a
 last update:	08/28/92

=======================================================================

 config.sys line is:

  device=$serial.sys /port params /port params ... /port params

      port params are:
	   param=value,...,param=value

  param	      default	acceptable

 ad= port addr   03f8 & 02f8	0 < ad < FFFE 
 ib= input buffer size    64	32 <= ib < 65536
 ob= output buffer size 1024	16 <= ob < 65536
 hs= handshaking	    n	none & dtr & rts & xoff & xpc
     (note: hs=drp is valid and results in dtr, rts and xpc protocols)
 in= interrupt level	3 & 4	0 or 1 or 2 or 3 or 4 or 5 or 6 or 7
 cn= connection	    l   local & remote & terminate remote

 note that all options except port numbers are "sticky".  they apply
 to all subsequent ports on the command line as well as the current
 port.


 ***** notice ***** function numbers in the range 30 thru 39 inclusive
                    are reserved for oem use!

=======================================================================

rdg 02/16/89	modified isr - isr7 so that at bus machines with an edge
	  	  trigger can be told eoi at the beginning of the isr,
		  and	micro channel machines with a level trigger can be
		  told eoi at the end of the isr.
		modified init30 to decrease the minimum input buffer
		  size to 16 bytes for effective mouse operation.

mjs 02/20/89	modified reference to the structure  'port'  to use the
		name  'ports'  instead.  this is necessary for srterm
		and	ddtvna to be able to include both int14.inc and
		mostcb.inc without a conflict on the use of the var
		port (the ddtrec struct in mostcb.inc uses a var named
		port).

sah 02/20/89	convert int 38 calls int int services

mjs 04/16/89	modify to pass back error status when have an error.

mjs 05/03/89	changed date of last update to 05/03/89 since i changed
		int14.inc

cbk 12/06/89	moved code in setup: that was setting up vector addresses
		for calls to default: for emulink

mjs 05/08/90	added the clear_irq function to reset the 8259 mask
		when an int14fun11 call is done.

SAH 10/31/90	Correct passon detection to make sure that INT 14h
RSR	 	function test, al must be greater than 16 to allow 
		passon logic to work. This corrected a problem with
		Emulink on old True Blue IBM XT.

rva 08/30/91    Added optimization to avoid looking at every serial **OPT1**
                for every interrupt that occurs.                    **OPT1**

SAH 10/04/91   Cleanup for Released

SAH 10/29/91   Final version for release on server. including lastest
	       fix in isrsub.inc

RSR 04-06-92   Fix for Boca board to check for FIFO first rather
               than check for the scratch register.  This should
               work with all 16550's.

RSR 07-21-92  Fix for boca problem with Startech 16C554.  This is
              a problem the chip has with the THRE and TSRE.

SAH 08/28/92   Modifiy port address so that firld in ioprot is use instead
	       of high bit...this was done for Progress software Touch
	       screen interface.
======================================================================^

; The following macro is used to insert debugging version info into
; the signon messages and to display it at assembly time

versioncount=0

VERSION_INFO macro

    IFDEF BOBA_VERSION
       DB 13,10,'*BobA Version*'
       IF versioncount eq 0
          %OUT **BobA Version**
       ENDIF
    ENDIF

    IFDEF DOUBLE_BAUD
       DB 13,10,'*Double Baud Enabled*'
       IF versioncount eq 0
          %OUT **Double Baud Enabled**
       ENDIF
    ENDIF

    IFDEF LOG_CALLS
      DB 13,10,'*Log Calls Enabled*'
      IF versioncount eq 0
         %OUT  **Log Calls Enabled**
      ENDIF
    ENDIF

    IFDEF EXE_TESTING
      DB 13,10,'*Testing Version*'
      IF versioncount eq 0
         %OUT  **Testing Version**
      ENDIF
    ENDIF

    IFDEF ISR_DEBUG
      DB 13,10,'*Isr Debugging Enabled*'
      IF versioncount eq 0
         %OUT  **Isr Debugging Enabled**
      ENDIF
    ENDIF

    versioncount = versioncount + 1
ENDM

	if	0 eq 0			; hide from public.com
true	equ	1 eq 1
false	equ	1 eq 0
DUMPIT  equ     true                    ; display config on boot up

	include options.inc
	include	_serial.def		; get the module definitions
	endif

        public   default                ; required  for emulink
;	include _serial.pub

	page

zeroseg segment at 0
	org	08h*4			; starting addr of hardware irqs

virq0	dd	?                ; irq0
virq1   dd      ?                ;**OPT1**
virq2   dd      ?                ;**OPT1**
virq3   dd      ?                ;**OPT1**
virq4   dd      ?                ;**OPT1**
virq5   dd      ?                ;**OPT1**
virq6   dd      ?                ;**OPT1**
virq7   dd      ?                ;**OPT1**

	org	014h*4			; bios int 14h vector

vint14	dw	2 dup(?)

	org	01ah*4			; bios int 1ah vector

vint1a	dw	2 dup(?)    

	org	services*4		; mos int services vector

vint38	dw	2 dup(?)

zeroseg ends

IFDEF EXE_TESTING
        include testing.inc
ENDIF
	page
code	segment para public 'code'
	assume	cs:code, ds:nothing, es:nothing, ss:nothing

begin	equ	this byte
	dd	-1			; for link to next driver
	dw	8000h			; character device
	dw	strat			; device strategy entry point
	dw	inter			; device interrupt entry point
	db	'$$SC    '		; device driver name

irqmask db	0ffh			; initial 8259 irq mask
					; note:  the default prtirq entries
					; in the port table will enable
					; irq's 3 and 4
;microch	db	0		; micro channel operational     ; rg9047
numport dw	2			; default number of ports
tocount dw	182			; default timeout (10 seconds)

maxport	equ	32		; max of 32 async serial ports

	if      emulink
isize   equ     4096			; room for 1 screen of input text
osize	equ	128			; 128 byte keyboard output buffer
deffcr    equ   81h                       ; 8 chars on incoming fifo
defxburst equ   16                        ; Set XBurst to maximum
	else
isize	equ	64			; 64 byte type ahead buffer
osize	equ	1024			; 1024 byte default output buffer
deffcr    equ      0h                     ; Default to FIFO OFF
defxburst equ      0h                     ; Default to no xmit bursts
	endif


ports	struc
		     
addr	dw	0			; physical port address
prtirq	db	4			; default irq line for port
kbeflg	db	0			; keyboard empty flag
modmst	db	0			; current modem status register
linest	db	0			; current line status register
ioprot	db	40h			; i/o protocols enabled
					; 80h - waiting for timer wrap
					; 40h - set if port is disable 
					; 20h - report carrier loss
					; 10h - monitor carrier
					; 08h - rts/cts enabled
					; 04h - dtr/dsr enabled
					; 02h - xmit xon/xoff
					; 01h - rcv xon/xo; novell
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
datovr	db	0			; data overrun flag
bufovr	db	0			; buffer overrun flag
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

; default ports to com1, then com2, then alternate com port address map
; must start at 18h in the code segment

porttbl ports	<03f8h>
	ports	<02f8h,3>
	ports	maxport - 2 dup(<>)
	;ports	maxport - ($-porttbl)/type ports dup(<>)

portoff	dw	offset porttbl	; pointer to the port table

eoi	equ	20h			; 8259 general end of interupt

orig1a	dd	0			; int 1a vector at initialization
orig38	dd	0			; int38 vector at initialization
child	dd	0			; point to next int14 driver

request dd	0			; location of device request

zero	dw	0			; irq/mos data segment

	if	emulink
sername	db	'EMULINK.SYS V4.1 (920901)              '
	else
sername db	'$Serial.sys V5.03  (920901)              '
	endif

        subttl   Per Interrupt Level Data Structures and related stuff
        page
        include  pilds.inc
        include  llrec.inc


; The following table contains one record for each possible
; port.  These records are in a one-to-one correspondence
; with the "ports" records above, and are used to maintain
; linked lists of active ports on each interrupt level.
;
;    NOTE: We align the LL_TABLE on a word boundary for
;          performance.  Since each LL_RECORD is an even
;          number of bytes long, they are all aligned.
;
; Each LL_RECORD is initialized as follows:
;
;       LL_NEXT    <-  0
;       LL_PREV    <-  0
;       LL_PORT    <-  near pointer to corresponding "ports" record
;       LL_DAD     <-  0
;       LL_FCR     <-  deffcr (default value symbol defined above)
;       LL_XBURST  <-  defxburst (default value symbol defined above)
;       LL_UTYPE   <-  UT_None

; Now we actually allocate the LL_RECORDs.  Note that this code
; requires the following symbols to be defined before including
; this file:
;
;     porttbl  = the first record in the "ports" table.
;     ports    = the "struc" for each record in "ports".
;     maxport  = the number of records in the "ports" table.
;     deffcr   = the default (initialized) value for LL_FCR.
;     defxburst = the default (initialized) value for LL_XBURST.


          EVEN                       ; align to words
LL_TABOFF   dw	 offset ll_table	
ll_table    label LL_RECORD
port_off = porttbl                   ; address of first port
            rept  maxport            ; how many to generate
 LL_RECORD <0,0,port_off,0,deffcr,defxburst,UT_None> ;
port_off = port_off + type ports     ; point at next "ports" rec
            endm                     ; end of repeat




	subttl	async port register definitions
	page

; miscellaneous symbols and equates

tab	equ	008h			; tab
lf	equ	00ah			; line feed
cr	equ	00dh			; carriage return
space	equ	' '			; space
comma	equ	','			; comma
equal	equ	'='			; equal

; async adapter port and status definitions

txdat	equ	0			; data transmitter

rxdat	equ	0			; data receiver

divll	equ	0			; baud rate divisor latch lsb

divlm	equ	1			; baud rate divisor latch msb

iereg	equ	1			; interupt enable register

enmsi	equ	000001000b		; enable modem status interupts
enlsi	equ	000000100b		; enable line status interupts
entei	equ	000000010b		; enable transmitter empty inter
endri	equ	000000001b		; enable data ready interupts

iireg	equ	2			; interupt identification regist

noint	equ	000000001b		; no interupt pending

fcreg   equ     2                       ;**FIFO** fifo control register
lcreg	equ	3			; line control register

divla	equ	010000000b		; divisor latch access control
stbrk	equ	001000000b		; set break condition

mcreg	equ	4			; modem control register

stot2	equ	000001000b		; set out 2 (enable interupts)
stot1	equ	000000100b		; set out 1
strts	equ	000000010b		; set rts
stdtr	equ	000000001b		; set dtr

lsreg	equ	5			; line status register

tsre	equ	001000000b		; transmitter shift reg empty
thre 	equ	000100000b		; transmitter holding reg empty
brki	equ	000010000b		; break indicator
frerr	equ	000001000b		; framing error
paerr	equ	000000100b		; parity error
overr	equ	000000010b		; data overrun error
drdy	equ	000000001b		; data ready

msreg	equ	6			; modem status register

carst	equ	010000000b		; status of carrier detect (rlsd)
rngst	equ	001000000b		; status of ring indicator (ri)
dsrst	equ	000100000b		; status of data set ready (dsr)
ctsst	equ	000010000b		; status of clear to send (cts)
carch	equ	000001000b		; change in carrier detect (rlsd)
trlri	equ	000000100b		; trailing end of ring indicator
dsrch	equ	000000010b		; change in data set ready (dsr)
ctsch	equ	000000001b		; change in clear to send (cts)

screg   equ     7                       ;**FIFO** scratch register

	include	jmpmacro.inc
	include seriomac.inc


	subttl  device driver entry points
	page

strat	proc	far			; device strategy entry point
	mov	word ptr [request], bx	; save the request header offset
	mov	word ptr [request+2], es; and the request header segment
	ret				; return to caller
strat	endp


inter	proc	far			; device interupt entry point
	push	es			; save application es
	push	bx			; and bx
	les	bx,[request]		; point es:bx to the request hea
	cmp	byte ptr es:[bx+2], 0	; is this an init request
	jne	inter1			; exit with finished status if no
	push	ds			; save the caller's environment
	push	bp
	push	di
	push	si
	push	dx
	push	cx
	push	ax
	lds	si, es:[bx+18]		; point ds:si to command line
	call	init			; initialize the port table
	les	bx, [request]		; point es:bx to the request hea
	mov	es:[bx+14], dx		; tell him were the end of the
	mov	es:[bx+16], ds		;   end of the driver is
	pop	ax			; restore his environment
	pop	cx
	pop	dx
	pop	si
	pop	di
	pop	bp
	pop	ds
	cmp	word ptr es:[bx+3],0200h; if error already set
	je	inter3			; then leave it
inter1:
	mov	word ptr es:[bx+3], 00100h  ; store status (done no err)
inter3:
	pop	bx			; restore bx
	pop	es			; and es
	ret				; return to the caller
inter	endp


	include	int14.inc


	subttl	isr, nisr - interrupt service routine
	page

; interrupt service routine data

intprc	dw	0			; number of interupts found

;**OPT1** Since the routines in isrsub are called with DS=CS, we can
;**OPT1** avoid a lot of redundant CS: prefixes by using the appropriate
;**OPT1** ASSUME.
        assume ds:code

	include	isrsub.inc

	subttl	isr, nisr - interrupt service routine
	page

; interrupt service routine

	assume	cs:code, ds:nothing, es:nothing, ss:nothing

;**OPT1** At entry to "isr" we have the following on the stack:
;**OPT1**
;**OPT1**       (SP)   = address of PILDS for this interrupt
;**OPT1**       (SP+2) = ax value at entry to interrupt
;**OPT1**       (SP+4) = IP saved by interrupt
;**OPT1**       (SP+6) = CS saved by interrupt
;**OPT1**       (SP+8) = flags saved by interrupt

isr	label	near
;**OPT1**	push	ax			; save ax around the eoi

;	cmp	cs:[microch], 0		; is this a micro channel machine
;	jne	isr1			; skip the eoi if micro channel
	mov	al, eoi			; 8259 end of interupt
	out	20h, al			; reset the 8259


isr1:
        pop     ax                      ;**OPT1** get PILDS pointer

	push	es			; save
	push	ds			;  the
	push	si			;   interupted
	push	di			;    environment
	push	dx
	push	cx
	push	bx

        mov     cx, ax                  ;**OPT1** save PILDS pointer

	mov	ax, cs			; move code segment to ax
	mov	ds, ax			; set ds to our segment
	assume	cs:code, ds:code, es:nothing, ss:nothing

	cld				; make sure of direction flag
isr2:
	mov	[intprc], 0		; clear the interrupts processed

;**OPT1**	mov	bx, [portoff]		; point bx to the port table
;**OPT1**	mov	cx, [numport]		; get the number of ports

        mov     di,cx                   ;**OPT1** get ptr to first..
        mov     di,[di].PILDS_FIRST     ;**OPT1** ...LL_RECORD_record on list

;**OPT1** If the linked list is empty we are probably in big trouble
;**OPT1** because we have an interrupt we haven't the slightest notion
;**OPT1** how to clear!  We can only hope the EOI is enough to straighten
;**OPT1** things out.

        cmp     di,cx                   ;**OPT1** Is the list empty?
        jz      isr6A                   ;**OPT1** YES! Oh dear!

isr3:

;**OPT1**       ASSERT:  cx is pointer to PILDS
;**OPT1**       ASSERT:  di is pointer to LL_RECORD to process


        mov     bx, [di].LL_PORT        ; get "ports" structure address
	mov	dx, [bx].addr		; get a port address

isr4:
	rdiir				; read the interupt identification
	test	al, noint		; is he interupting
	jnz	isr5			; jump if not this port
	inc	[intprc]		; show we found one
;**FIFO** xor	ah, ah			; convert interupt type to offset
	mov	si, ax			; move the offset to si
        and     si, 110b                ;**FIFO** extract vector bits
;**OPT1** push	cx			; save count of ports remaining
        push   cx                       ;**OPT1** save PILDS pointer
        push   di                       ;**OPT1** save LL_RECORD pointer
	call	inttbl[si]		; call the interupt processor
;**OPT1** pop	cx			; restore the port count
        pop    di                       ;**OPT1** restore LL_RECORD ptr
        pop    cx                       ;**OPT1** restore PILDS ptr
	jmp	short isr4		; go check it again
isr5:
;**OPT1**	add	bx, type ports		; bump to the next entry
        mov     di,[di].LL_NEXT         ;**OPT1** walk the linked list
        cmp     di,cx                   ;**OPT1** Did we check 'em all?
        jnz     isr3                    ;**OPT1** NO: Check the next port
;**OPT1** loop	isr3			; go check the next port

isr6:
	cmp	[intprc], 0		; did we have a clear pass
	jne	isr2			; do again until clear

isr6A:                                  ;**OPT1**
	pop	bx			; restore
	pop	cx			;  the
	pop	dx			;   interupted
	pop	di			;    environment
	pop	si
	pop	ds
	pop	es
;	cmp	cs:[microch], 0		; is this a micro channel machin
;	je		isr7		; don't do the eoi again if AT b
;	mov	al, eoi			; 8259 end of interupt
;	out	20h, al			; reset the 8259
isr7:
	pop	ax			; restore ax
	iret				; return to the interupted enviro

        subttl isr_for_irqN - individual ISRs (also PILDS!) **OPT1**
        page

;**OPT1**  In order to avoid looking at every single serial port on every
;**OPT1**  interrupt, we keep a list of what ports are on which interrupts.
;**OPT1**  We also need separate entry points for each interrupt handler
;**OPT1**  so that we know which list to follow.

;**OPT1**  Note that we put the PILDS structure for each interrupt
;**OPT1**  level directly after the call to "isr".
;**OPT1**  "isr" will pop this "return address" to get a pointer to
;**OPT1**  the correct PILDS! (pretty sneaky huh?)

;**OPT1**  Define the entry points for each possible interrupt level.
;**OPT1**     Note: The "EVEN" directive before each interrupt entry
;**OPT1**     point ensures that the code is aligned on a word boundary.
;**OPT1**     This should help performance a bit.  Since "push ax" is
;**OPT1**     1 byte and "call isr" is 3, we also align the fields in
;**OPT1**     the PILDS!

IRPC L,<01234567>    ;Generate one PILDS for each possible interrupt

        EVEN
isr_for_irq&L:                         ;**OPT1**
        push    ax                     ;**OPT1** save AX first
        call    isr                    ;**OPT1** call the general handler
PILDS_&L  PILDS  <PILDS_&L,PILDS_&L,&L,0,virq&L,isr_for_irq&L>   ;**OPT1**

ENDM

	subttl clr_set_irq - update the 8259 mask
	page
;======================================================================
; .func: clr_set_irq - update the 8259 mask
;
;
; input:
;	ch = 0 to clear, 1 to set
;	cl = irq number
;
; output:
;
; comments:
;	when int14fun11 is called, must mask disable the irq in the pic
;	when int14fun00/04 is callled, must mask enable the irq
;
; .calls: 
; .reads: 
; .writes: 
;
; .endfn
;======================================================================
;	assume	cs:code,ds:code,es:nothing,ss:nothing
clr_set_irq:
	push	ax
        cli                             ; do it with ints off
	cmp	cl,7                    ; expecting entry cl 0 through 7
	ja	clq1
     	mov	ah,1
	shl	ah,cl			; derive bit mask
	in	al,21h			; get current mask
	or	ch,ch                   ; on or off?
	jnz	clq2
	or	al,ah                   ; turn it off
	jmp	short clq3
clq2:
	not	ah
	and	al,ah                   ; turn it on
clq3:
	out	21h,al			; assert new
clq1:
        sti
	pop	ax

	ret

	subttl	init - $serial.sys initialization
	page
;======================================================================
; .func: init - $serial.sys initialization
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
	assume	cs:code, ds:nothing, es:nothing, ss:nothing
init:
	jmp	setup			; jump over the init data

; initialization messages

	if      emulink
scset   db      'PC-Emulink Serial Communications Driver V4.1 (920901)'
        VERSION_INFO
	db	cr,lf,'$'

not_inst db	'Cannot install PC-Emulink Serial Communications Driver!'
         VERSION_INFO
	db	'          ',cr,lf,'$'
	else
scset	db	'MOS Serial Communications driver v5.03  (920901)'
        VERSION_INFO
	db	13,10,'$'

not_inst db	'Cannot install MOS Serial Communications driver!'
        VERSION_INFO
	db	'            ',cr,lf,'$'
	endif

toomany db	'Too many ports specified!         ',cr,lf,'$'
dup_port db	'Port specifed more than once!            ',cr,lf,'$'

syntax	db	'Syntax error! ',cr,lf,'$'
bad_ad	db	'Invalid port address specified!               ',cr,lf,'$'
bad_ib	db	'Invalid input buffer size specified!          ',cr,lf,'$'
bad_ob	db	'Invalid output buffers size specified!        ',cr,lf,'$'
bad_hs	db	'Invalid handshake specification!              ',cr,lf,'$'
bad_cn	db	'Invalid connection specification              ',cr,lf,'$'
bad_in	db	'Invalid interrupt specified!                  ',cr,lf,'$'
bad_of  db      'Invalid output FIFO size specified!           ',cr,lf,'$' ;**FIFO**
bad_if  db      'Invalid input FIFO size specified!            ',cr,lf,'$' ;**FIFO**

IFDEF DUMPIT
dump_req        db       1     ;**OPT1** Non-zero if parameter dump requested
ENDIF
            	subttl setup - process config parameters
	page
;======================================================================
; .func: setup - process config parameters
;
; input:
;	ds:si -> command line following device=
;
;       param	      	    default	acceptable
;
;	ad= port(com1)	       03f8	0 < ad < FFFE
;		(com2)         02f8
;	ib= input buffer size    64	16 <= ib < 65536
;	ob= output buffer size 1024	16 <= ob < 65536
;	hs= handshaking		  n	(n)one, (d)tr/dsr, dtr/(r)ts,
;					(x)on/xoff, or x(p)c
;	in= interrupt level(com1) 4	0, 1, 2, 3, 4, 5, 6 or 7
;			   (com2) 3
;	cn= connection		  l	(l)ocal - direct connect
;					(r)emote - modem
;
;       fi= fifo rcvr threshhold  0     0, 1, 4, 8, or 14   **FIFO**
;                                                           **FIFO**
;       fo= fifo xmit burst size  0     0 <= fo <= 16       **FIFO**
;                                                           **FIFO**
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
setup:
        cld                             ;**MBUG** make sure of direction flag
	mov	ax, cs			; code segment to ax
	mov	es, ax			; set es to our code segment

	assume	cs:code, ds:nothing, es:code, ss:nothing
init00:
	lodsb				; get a character from the line
	cmp	al, space		; is this the first space
	ja	init00			; look for the first space
	dec	si			; back up one
init02:
	lodsb				; get a character

IFDEF DUMPIT                            ;**DUMP**
        cmp     al, '%'                 ;**DUMP** config dump suppress?
        jnz     init03                  ;**DUMP** NO: Check other choices
        mov     [dump_req],0            ;**DUMP** Remember it
        jmp     init02                  ;**DUMP** On to next character
init03:                                 ;**DUMP**
ENDIF                                   ;**DUMP**

	cmp	al, cr			; should we use the default
	lje	default			; jump if null config line
	cmp	al, lf			; should we use the default
	lje	default			; jump if null config line
	cmp	al, space		; is it a space or less
	jbe	init02			; look for a real character
	cmp	al, '/'			; is he defining a port
	ljne	syntaxer		; syntax error if not port defin

;**OPT1** Initialize pointers to "porttbl" and "LL_TABLE" by setting up registers
;**OPT1** to point one record before the start of the table

        mov     bx, offset porttbl-type ports      ;**OPT1**
        mov     bp, offset LL_TABLE-type LL_RECORD ;**OPT1** start 1 b4 table

	mov	[numport], 0		; initialize the port count

;**OPT1** This is where we start to process a port.  At this point,
;**OPT1** DI:SI should be pointing to the 'AD=' for the new port.

init10:
        lodsw                           ;**OPT1** get the two chars
        xchg    ah,al                   ;**OPT1** ...in correct order
	and	ax, 0dfdfh		; convert it to uppercase
	cmp	ax, 'AD'		; is it an address definition
	ljne	syntaxer		; syntax error if no
	lodsb				; get the next character
	cmp	al, '='			; it should be an =
	ljne	syntaxer		; syntax error if its not

;**OPT1** Complain if we have already defined all the ports we are allowed to
	lea	dx, toomany		; too many ports
	cmp	[numport], maxport	; is he doing too many
	ljae	abort			; abort if too many ports

;**OPT1** Advance the pointers to point to the next "ports" and "LL_RECORD"
;**OPT1** record to be filled in.

        add     bp,type LL_RECORD       ;**OPT1** point at next LL_RECORD
        add     bx,type ports           ;**OPT1** point at next "ports" rec

;**OPT1** At this point we clone the prior record to the record we
;**OPT1** are about to define in both the "LL_TABLE" and "porttbl"
;**OPT1** data structures.  However, if we are defining the first
;**OPT1** port we need to suppress the copy. (since there is nothing to
;**OPT1** copy!)
;**OPT1**
;**OPT1**       Assert:  ds:si points to our current position in cmd line
;**OPT1**                es:bp points to LL_RECORD to fill in
;**OPT1**                es:bx points to "ports" rec to fill in

        cmp     [numport],0             ;**OPT1** is this the first one?
        jz      init12                  ;**OPT1** YES: Skip the copying

	push	ds			; save the config line segment
	push	si			; and our current offset
	mov	cx, cs			; get the code segment
	mov	ds, cx			; set ds to our code segment
	assume	cs:code, ds:code, es:code, ss:nothing

        mov     di, bx                  ;**OPT1** point to new entry
        lea     si,[di-type ports]      ;**OPT1** point to old entry

        mov	cx, type ports		; number of bytes to copy
        rep	movsb			; initialize the new port entry

        mov     di, bp                  ;**OPT1** point to new entry
        lea     si,[di-type LL_RECORD]  ;**OPT1** point to old entry

        mov     al,[si].LL_XBURST       ;**OPT1** copy the transmit...
        mov     [di].LL_XBURST,al       ;**OPT1** ...burst size

        mov     al,[si].LL_FCR          ;**OPT1** copy the fifo...
        mov     [di].LL_FCR,al          ;**OPT1** ...control register value

        pop     si                      ;**OPT1** restore cmd line offset...
        pop     ds                      ;**OPT1** ...and segment

init12:
	assume	cs:code, ds:nothing, es:code, ss:nothing
	call	hextobin		; get the port address
	lea	dx, bad_ad		; prime dx for a bad address
	ljc	abort			; abort if data was bad
	mov	es:[bx].addr, ax	; store the port address
	or	byte ptr es:[bx].ioprot,40h	; disable port by default
	inc	[numport]		; bump the count of ports

;**OPT1** We come to this point to start processing each parameter
;**OPT1** specified for the current port.

init20:
	lodsb				; get the next character
	cmp	al, '/'			; is it a port delimiter
	je	init10			; go process a new port if yes
	cmp	al, comma		; is it an option delimiter
	je	init25			; jump if yes
	cmp	al, space		; is it an option delimiter
	je	init25			; jump if yes
	cmp	al, tab			; is it an option delimiter
	je	init25			; jump if yes
	cmp	al, cr			; is he finished
	lje	init80			; jump if we got enuf info
	cmp	al, lf			; is he finished
	lje	init80			; jump if we got enuf info
	jmp	syntaxer		; syntax error
init25:
	lodsb				; get another character
	cmp	al, space		; is it an extra space
	je	init25			; skip extra spaces
	cmp	al, '/'			; is it a port delimiter
	lje	init10			; go process a new port if yes
	mov	ah, al			; move the character to ah
	lodsb				; get the second character
	and	ax, 0dfdfh		; convert the option to uppercase
	cmp	byte ptr [si], '='	; is it a valid option selection
	je	init30			; check it out if valid
	jmp	syntaxer		; syntax error if no xx=
init30:
	inc	si			; bump past the =
	cmp	ax, 'IB'		; is it input buffer size
	jne	init40			; jump if not input buffer
	call	dectobin		; get the input buffer size
;**PBUG** or	dx, dx			; is it too big
	lea	dx, bad_ib		; prime dx for a bad size
;**PBUG** ljnz	abort			; abort if the buffer is too big
        ljc     abort                   ;**PBUG** abort if invalid value
	cmp	ax, 16			; is it too small
	ljb 	abort			; abort if the buffer is too small
	mov	cs:[bx].ibfsiz, ax	; store the input buffer size
	jmp	short init20		; go check for another parameter
init40:
	cmp	ax, 'OB'		; is it the output buffer
	jne	init50			; jump if not output buffer size
	call	dectobin		; get the output buffer size
;**PBUG** or	dx, dx			; is it too big
	lea	dx, bad_ob		; prime dx for a bad size
;**PBUG** ljnz	abort			; abort if the buffer is too big
        ljc     abort                   ;**PBUG** abort if value is bogus
	cmp	ax, 16			; is it too small
	ljb 	abort			; abort if the buffer is too small
	mov	cs:[bx].obfsiz, ax	; store the output buffer size
	jmp	short init20		; go check for another parameter
init50:
	cmp	ax, 'HS'		; is it flow control
	jne	init60			; jump if not flow control
        mov     ah, 0                   ;**MBUG** start with no flow control
        dec     si                      ;**MBUG** Predecrement
init51:                                 ;**MBUG**
        inc     si                      ;**MBUG** do the next characer
        mov     al,[si]                 ;**MBUG** get a flow control char
	and	al, 0dfh		;**MBUG** convert it to uppercase

        cmp     al, 'N'                 ;**MBUG** turn off flow control?
        jnz     init52                  ;**MBUG** NO
          mov   ah,0                    ;**MBUG** Clear all flow control
          jmp   init51                  ;**MBUG** Done with this char

init52:                                 ;**MBUG**
        cmp     al, 'R'                 ;**MBUG** rts/cts flow control?
        jnz     init53                  ;**MBUG** NO
          or    ah,00001000b            ;**MBUG** Turn it on
          jmp   init51                  ;**MBUG** Done with this char

init53:                                 ;**MBUG**
        cmp     al, 'D'                 ;**MBUG** dtr/dsr flow control?
        jnz     init54                  ;**MBUG** NO
          or    ah,00000100b            ;**MBUG** Turn it on
          jmp init51                    ;**MBUG** Done with this char

init54:                                 ;**MBUG**
        cmp     al, 'X'                 ;**MBUG** xon/xof flow control?
        jnz     init55                  ;**MBUG** NO
          or    ah,00000011b            ;**MBUG** Turn it on
          mov   cs:[bx].xonch,011h      ;**MBUG** Set proper xon/xoff chars
          mov   cs:[bx].xoffch,013h     ;**MBUG**
          jmp init51                    ;**MBUG** Done with this char

init55:                                 ;**MBUG**
        cmp     al, 'P'                 ;**MBUG** Xpc flow control?
        jnz     init56                  ;**MBUG** NO
          or    ah,00000011b            ;**MBUG** Turn it on
          mov   cs:[bx].xonch,065h      ;**MBUG** Set proper xon/xoff chars
          mov   cs:[bx].xoffch,067h     ;**MBUG**
          jmp init51                    ;**MBUG** Done with this char

init56:                                 ;**MBUG** At a non-flow character
        and     cs:[bx].ioprot,0F0h     ;**MBUG** Turn off existing stuff
        or      cs:[bx].ioprot,ah       ;**MBUG** Turn on the new ones
        jmp     init20                  ;**MBUG** Go check for another param

init60:
	cmp	ax, 'IN'		; is it the device irq
	jne	init70			; jump if not device irq
	lea	dx, bad_in		; prime dx for bad interupt
	lodsb				; get the interupt number
	cmp	al, '0'			; is it a digit
	ljb 	abort			; go abort if not a digit
	cmp	al, '7'			; is it 7 or less
	lja	abort			; go abort if greater than 7
	sub	al, '0'			; convert it to binary
	mov	cs:[bx].prtirq, al	; store irq level for port
	jmp	init20			; go check for another parameter
init70:
	cmp	ax, 'CN'		; is it the device connection
;**FIFO** ljne	syntaxer		; unrecognized option id
        jne     initF10                 ;**FIFO** check fifo control stuff
	lodsb				; get the connection type
	and	al, 0dfh		; convert it to uppercase
	cmp	al, 'L'			; is it local (direct connected)
	jne	init72			; jump if not direct connected
	and	cs:[bx].ioprot, not 030h; turn off all carrier monitoring
	jmp	init20			; go check for another parameter
init72:
	cmp	al, 'R'			; is it remote (modem connected)
	jne	init74			; jump if not remote
	or	cs:[bx].ioprot, 010h	; set for carrier monitoring
	jmp	init20			; go check for another parameter
init74:
	lea	dx, bad_cn		; prime dx for bad connection
	cmp	al, 'T'			; is it task restart
	ljne	abort			; abort if invalid connection type
	or	cs:[bx].ioprot, 030h	; set for carrier task restart
	jmp	init20			; go check for another parameter

;**FIFO** The following code was added to support the FIFO control
;**FIFO** values that may appear on the command line, as well as a
;**FIFO** to display the resulting configuration during boot.
;**FIFO**
;**FIFO**     /OF=<transmit burst>         (default = 0)
;**FIFO**     /IF=<receive threshhold>     (default = 0)
;**FIFO**

initF10:                                ;**FIFO**
        cmp     ax, 'OF'                ;**FIFO** transmit burst size?
        jne     initF20                 ;**FIFO** NO: try other params
	call	dectobin		;**FIFO** Get the burst size
	lea	dx, bad_of		;**FIFO** prime dx for a bad size
	ljc	abort			;**FIFO** abort if bogus
        cmp     ax,16                   ;**FIFO** is it too big?
        lja     abort                   ;**FIFO** YES!
        mov     cs:[bp].LL_XBURST,al    ;**FIFO** save burst length
        jmp     init20                  ;**FIFO go check another parameter

initF20:                                ;**FIFO**
        cmp     ax, 'IF'                ;**FIFO** receiver threshhold?
        ljne    syntaxer                ;**FIFO** NO: out of choices
        call    dectobin                ;**FIFO** get the threshhold
        lea     dx, bad_if              ;**FIFO** prime dx for a bad size
        ljc     abort                   ;**FIFO** abort if bogus
        mov     dl,11000001b            ;**FIFO** thresh=16 control bits
        cmp     ax,14                   ;**FIFO** is it ok?
        jz      initF30                 ;**FIFO** YES!
        mov     dl,10000001b            ;**FIFO** thresh=8 control bits
        cmp     ax,8                    ;**FIFO** another choice
        jz      initF30                 ;**FIFO**
        mov     dl,01000001b            ;**FIFO** thresh=4 control bits
        cmp     ax,4                    ;**FIFO** one more valid value
        jz      initF30                 ;**FIFO**
        mov     dl,00000001b            ;**FIFO** thresh=1 control bits
        cmp     ax,1                    ;**FIFO** last active value
        jz      initF30                 ;**FIFO**
        mov     dl,0                    ;**FIFO** FIFO inactive control bits
        cmp     ax,0                    ;**FIFO** special FIFO off value
        je      initF30                 ;**FIFO**
        mov     dx, offset bad_if       ;**FIFO** error msg
        jmp     abort                   ;**FIFO** report it

initF30:                                ;**FIFO**
        mov     cs:[bp].LL_FCR,dl       ;**FIFO** save FCR value
        jmp     init20                  ;**FIFO**

init80:
        nop
default:				;entry point from emulink

        assume  cs:code,ds:nothing,es:nothing,ss:nothing  ;**FIFO**
	mov	ax, cs                  ;**FIFO**
        mov     ds, ax                  ;**FIFO**
        assume  ds:code                 ;**FIFO**


        call    near ptr CheckUarts     ;**FIFO** determine uart types
                                        ;**FIFO** ...as required
                                        ;**OPT1** also fills in LL_DAD
                                        ;**OPT1** pointers and sets
                                        ;**OPT1** up PILDS_COUNT

	mov	es, [zero]		;**FIFO** set es to zeroseg
        assume  es:zeroseg              ;**FIFO**

; Get the values of certain vectors so that we can use "Push/Call dword []"
; instead of "INT xxH" to get to them.

	mov	ax, word ptr vint1a	; get the original int 1a offset
	mov	word ptr [orig1a], ax	; set up for calls versus int
	mov	ax, word ptr vint1a+2	; get the original int 1a segment
	mov	word ptr [orig1a+2], ax	; set up for calls versus int
	mov	ax, word ptr vint38	; get the original int 38 offset
	mov	word ptr [orig38], ax	; set up for calls versus int
	mov	ax, word ptr vint38+2	; get the original int 38 segment
	mov	word ptr [orig38+2], ax	; set up for calls versus int

	mov	ax, cs			; code segment to ax
	mov	es, ax			; set es to our code segment
	assume	cs:code, ds:nothing, es:code, ss:nothing
;	mov	cs:[microch], 0		; set for an at bus
;	mov	ah, 0c0h		; ask for the system configurati
;	int	015h			; ask for system services
;	jc	init81			; jump if not micro channel

; The test in the following instruction was changed from 020h to 002h.
; This was a simple typo!.
;	test	byte ptr es:[bx+5], 020h; is it a micro channel machine
;        test    byte ptr es:[bx+5], 002h; is it a micro channel machine
;	jz	init81			; jump if not micro channel
;	mov	cs:[microch], 0ffh	; show this is micro channel
init81:

; Determine the first available segment for storing buffers

	mov	ax, cs			; move the code segment to ax
	mov	ds, ax			; set ds to the code segment
	mov	es, ax			; set es to the code segment
	assume	cs:code, ds:code, es:code, ss:nothing

	lea	di, init+15		; point 1 paragraph beyond init
	mov	cl, 4			; convert byte offset to paragraph
	shr	di, cl			; init+15 offset in paragraphs
	add	di, ax			; segment of 1st available buffer

; Prepare to scan the LL_TABLE.  On this pass through the data structure
; we:
;    1: Allocate the input and output buffers
;    2: Check for duplicate UART addresses

        mov     si, offset LL_TABLE     ;**OPT1** point to first LL_RECORD
	mov	cx, [numport]		; and get the number of ports to do

init82:

; ASSERT:  [si] is address of current LL_RECORD
;          di is first available memory segment for buffers
;
        cmp     [si].LL_UTYPE,UT_None   ;**OPT1** If there is no UART
        jz      init89                  ;**OPT1** Don't check dups and...
                                        ;**OPT1** ...don't allocate buffers

; Scan prior entries to see if this is a duplicate.  NOTE: At this point
; in the code the hi order bit is on in ALL the addresses, so we do our
; compares with that bit on!

        mov     bx,[si].LL_PORT         ;**OPT1** Get "ports" address
        mov     ax,[bx].addr            ;**OPT1** Get actual I/O address

        mov     dx,si                   ;**OPT1** Remember where we were
                                        ;**OPT1** ...in the LL_TABLE

	mov	si, offset LL_TABLE     ;**OPT1** Start over at beginning

init84:
	cmp	si, dx                  ;**OPT1** Have we checked all prior
                                        ;**OPT1** entries?

        jz      init86                  ;**OPT1** YES: This is not a duplicate

        cmp     [si].LL_UTYPE,UT_None   ;**OPT1** If this entry has no chip...
        jz      init85                  ;**OPT1** ...it can't be a duplicate

        mov     bx,[si].LL_PORT         ;**OPT1** Get "ports" address
        cmp     [bx].addr,ax            ;**OPT1** Same physical address?
        jnz     init85                  ;**OPT1** NO: This is not a duplicate

	lea	dx, dup_port		;**OPT1** YES: Report the duplicate
	jmp	abort

init85:
	add	si, type LL_RECORD	; bump si to the next LL_RECORD
	jmp	short init84		; go check this one

; We have scanned all prior ports without finding a duplicate address

init86:
        mov     si,dx                   ;**OPT1** Restore LL_TABLE pointer
        mov     bx,[si].LL_PORT         ;**OPT1** Get address of "ports" rec

; Set up the segment address of the input buffer, and advance DI past the
; input buffer

	mov	[bx].ibfseg, di		; input buffer at next avail seg
	mov	ax, [bx].ibfsiz		; get the input buffer size
	add	ax, 15			; plus 16 for paragraph boundary
	rcr	ax, 1			; bring in the carry if full 64k
	shr	ax, 1			; convert buffer
	shr	ax, 1			;  size to number
	shr	ax, 1			;   of paragraphs
	add	di, ax			; calculate next available segment

; Setup of the segment address of the output buffer, and advance DI past
; the output buffer

	mov	[bx].obfseg, di		; output buffer at next avail seg
	mov	ax, [bx].obfsiz		; get the output buffer size
	add	ax, 15			; plus 15 for paragraph boundary
	rcr	ax, 1			; bring in the carry if full 64k
	shr	ax, 1			; convert buffer
	shr	ax, 1			;  size to number
	shr	ax, 1			;   of paragraphs
	add	di, ax			; calculate next available segment

; Move on to the next port to be processed

init89:
        add     si, type LL_RECORD      ;**OPT1** bump to next port
	loop	init82			; go do the next port

; At this point:
;    DI contains the segment address of the first paragraph beyond the
;    last port's buffer.
;
;    We have made all our error checks.  If we get to this point we are
;    definitely going to install, so it is safe to grab vectors now.

init90:

; We start by setting up each hardware vector that is used by this driver to
; point to the correct isr entry point:

        push    di                      ;**OPT1** Save first free segment
        mov     bx, offset PILDS_TABLE  ;**OPT1** Get pointer to table
                                        ;**OPT1**...containing addresses...
                                        ;**OPT1**of PILDS.
        mov     cx,8                    ;**OPT1** # of levels to check
	mov	es, [zero]		;**OPT1** Use ES to get at vectors
        assume  es:zeroseg              ;**OPT1**

init91:
        mov     si,[bx]                 ;**OPT1** Get address of a PILDS
        cmp     [si].PILDS_COUNT,0      ;**OPT1** If there are no ports...
        jz      init92                  ;**OPT1** ...don't set up vector

        mov     di,[si].PILDS_VECOFF    ;**OPT1** Get pointer to vector
        mov     ax,[si].PILDS_ISR       ;**OPT1** Get offset of ISR

	cli				;**OPT1** no interuptions here
        mov	word ptr es:[di], ax	;**OPT1** set the isr offset
	mov	word ptr es:[di+2],cs	;**OPT1**...and the isr segment
	sti				;**OPT1** the world may continue now

init92:
        add     bx,2                    ;**OPT1** Index thru PILDS_TABLE
        loop    init91                  ;**OPT1** Do other interrupt levels

; We have pointed all the interrupt vectors at ourself.  Note that we have
; **NOT** enabled the interrupts in either the 8250 or the 8259.  This will
; not be done until the port is initialized!

; We now have to either grab the INT 14h vector, or else chain to a prior
; driver.

	mov	ah, 6			; who are you
	xor	dx, dx			; handling port 0
	int	14h			; see if anyone else is home
	test	ah, 080h		; is another mos driver already here
	jz	init96			; go set int 14 if not already taken
	cmp	al,16			; if function is below 16 then
	jb	init96			; driver is not correct 		

; Another serial driver has already been installed.  We need to register
; as his child.

	mov	ax, cs			; move the code segment to ax
	mov	es, ax			; set es to the code segment
        assume  es:code                 ;**OPT1**
	mov	bx, offset int14	;**OPT1** point to our int 14
	mov	ah, 10h			; register us as his child
	int	14h			; call that other serial driver
	jmp	short init98		; go wrap it all up

; There is no prior serial driver present.  We need to grab the physical
; INT 14h vector.

init96:
	assume	es:zeroseg
	cli				; no interuptions here
	lea	dx, int14		; point to our int 14
	mov	word ptr vint14, dx	; set our int 14 offset
	mov	word ptr vint14+2, cs	; set our int 14 segment
	sti				; open up the gates

; We have either chained to another driver, or else we have grabbed
; the vector.  We are all set!

        assume  es:nothing
init98:
	mov	ah, 9			; print string
	lea	dx, scset		; point to our installed message
	int	021h			; call mos

IFDEF DUMPIT
        cmp     [dump_req],0            ;**DUMP** should we dump it?
        jz      init99                  ;**DUMP** NO
        call    dump_it                 ;**DUMP**
init99:
ENDIF

	pop	ds			; set ds:dx to the
	xor	dx, dx			;  end of our memory allocation
	ret				; return to the caller
syntaxer:
	lea	dx, syntax		; show a syntax error
abort:
	mov	ax, cs			; set ax to code segment
	mov	ds, ax			; set ds to the code segment
	assume	cs:code, ds:code, es:code, ss:nothing
	mov	ah, 9			; print string
	int	021h			; call mos
	lea	dx, not_inst		; tell him were not installed
	mov	ah, 9			; print string
	int	021h			; call mos
	xor	dx, dx			; set ds:dx to release entire module
	les	bx, [request]
	mov	es:[bx+3],0200h		; set error status
	ret				; return with no memory allocated



                 	 page




include cpuspeed.inc

;    You can then divide the resulting dx:ax by something to get a reasonable
;    loop counter for I/O delays.  This should provide some degree of
;    independence from CPU speed.


        subttl  CheckUarts - determine the UART types
        page
;======================================================================
; .func:    CheckUarts - determines the types of UARTs present
;
; input:    -none-
;
; output:   -none-
;
; comments: adjusts the values of LL_FCR and LL_XBURST as necessary.
;           Also sets LL_DAD to point to correct PILDS and increments
;           PILDS_Count as needed.

; The following table defines pointers to the PILDS
; for each of the possible interrupt levels.  It is used
; to find the correct PILDS for an interrupt level so we
; can set the correct value for LL_DAD for each port.

PILDS_TABLE    DW       PILDS_0, PILDS_1, PILDS_2, PILDS_3
               DW       PILDS_4, PILDS_5, PILDS_6, PILDS_7


CheckUarts proc near

        assume  cs:code, ds:code, es:nothing, ss:nothing

        call    checkspeed                  ;setup delay is 486

        mov     si,offset LL_TABLE      ; Start with first port
        mov     cx, [numport]           ; Number of ports to do

af_loop:
        push    cx

        mov     bx, [si].LL_PORT        ; Get address of "ports" structure
        mov     dx, [bx].addr           ; Get physical address of chip

        mov     ch,UT_None              ; Assume no port is there

; If there are any one bits in register positions that are always
; supposed to be zero, then we must not have a valid UART!

        RDIER                           ; Get interrupt enable register
        mov     cl, al                  ; (save a copy for later)
        and     al, 0F0h                ; These bits should be zero!
        mov     ah, al                  ; Save it

        RDIIR                           ; Get interrupt ID register
        and     al, 030h                ; These bits should be zero!
        or      ah, al                  ; Combine with prior value

        RDMCR                           ; Get modem control register
        and     al, 0E0h                ; These bits should be zero!
        or      ah, al                  ; Combine with prior value

        ljnz     af_gotit               ; There is nobody home at this address

; If we can't force the IER to be all zero then we don't have a valid UART

        mov     al, 0                   ; Try to zero the IER
        WRIER

        RDIER
        or      al, al                  ; Did it work?
        jz      sercont
        jmp      af_gotit
;        jnz     af_gotit                ; NO: Must not be a UART
sercont:
; We don't restore the value of the IER because we don't want a
; stray interrupt to bring us crashing down before the port is
; enabled!
;        mov     al, cl                  ; Put back the original value
;        WRIER

; Now we know that we have a UART with a scratch register.  We have to
; find out which one.  We do this by trying to turn on FIFO mode and
; checking the results.

        mov     al, 0C1h                ; Try to turn on the FIFO
        WRFCR

        RDIIR                           ; See whether FIFO turned on
        mov     ah, al                  ; Save it for later

        mov     al, 001h                ; Make sure we leave FIFO off
        WRFCR
        mov     al, 000h
        WRFCR

        mov     ch,UT_8250A             ; Assume 8250A/16450
        shl     ah,1                    ; Is bit 7 set?
;        jnc     af_gotit                ; NO

        jnc     test8250b

        mov     ch,UT_16550             ; Assume 16550
        shl     ah,1                    ; Is bit 6 set?
        jnc     af_gotit                ; NO

        mov     ch,UT_16550A            ; We got a real 16550A ! !
        jmp     af_gotit
; We now know the UART type.  Store it and adjust the FIFO control
; values as needed

; Well, we know we have a UART.  The next question is: Which type?
; If there is no SCRatch register, then it must be a 8250B
test8250b:
        mov     ch,UT_8250B             ; Assume an 8250B

        RDSCR                           ; Read the scratch reg
        mov     ah, al                  ; Save it for a bit

        mov     al, 0F0h                ; Test value
        WRSCR                           ; Write scratch reg
        RDSCR                           ; ...and read it back

        cmp     al, 0F0h                ; Is it an 8250B?
        jnz     af_gotit                ; YES

        mov     al, ah                  ; Put back the original value
        WRSCR

        mov     al, 0C1h                ; Try to turn on the FIFO
        WRFCR

        RDIIR                           ; See whether FIFO turned on
        mov     ah, al                  ; Save it for later

        mov     al, 001h                ; Make sure we leave FIFO off
        WRFCR
        mov     al, 000h
        WRFCR

        mov     ch,UT_8250A             ; Assume 8250A/16450
        mov     al,ah
af_gotit:
        mov     al, ch                  ; Extend to 16 bit value
        xor     ah, ah
        mov     [si].LL_UTYPE,ax        ; Remember UART type

; If there is a UART here then setup LL_DAD and PILDS_COUNT

        cmp     ch,UT_None              ; Is there a UART?
        jz      af_noonethere           ; NO: Don't touch LL_DAD ...
                                        ; ...or PILDS_COUNT

        mov     al,[bx].prtirq          ; Get interrupt level
        xor     ah,ah                   ; Extend to 16 bits
        xchg    ax,di                   ; Put into index register
        shl     di,1                    ; Convert to word offset
        mov     di,PILDS_TABLE[di]      ; Get pointer to PILDS

        mov     [si].LL_DAD,di          ; Save pointer to correct PILDS
        inc     [di].PILDS_COUNT        ; One more port defined here

; Only allow the FIFO to be enabled if we have a 16550A

af_noonethere:
        cmp     ch,UT_16550A            ; Is it a 16550A?
        jnz     af_not550A              ; NO: We can't use FIFO

; We have a 16550A.  Since input FIFO cannot be enabled without output
; FIFO and vice-versa we have to make sure the values are consistent.

        mov     al,[si].LL_FCR          ; Get requested input FIFO control
        mov     ah,[si].LL_XBURST       ; Get requested output FIFO control

        cmp     ax, 0                   ; Are they both zero?
        jz      af_not550A              ; YES: Treat like a non-550A

        test    al, 1                   ; Has FIFO been turned on?
        jz      af_forceon              ; NO: We may have to force it on

; The FIFO is on, if the XBURST is zero then force it to 1, otherwise
; use the user supplied value

        or      ah,ah                   ; Was it zero?
        jnz     af_next                 ; NO, use it
        mov     [si].LL_XBURST, 1       ; Turn a zero into a one...
        jmp     short af_next           ; ...and merge with other cases
			   
; The FIFO is not on, if the XBURST is > 1 then we have to force the
; FIFO on with a 1 byte threshhold.

af_forceon:
        cmp     ah,1                    ; Is XBURST > 1?
        jbe     af_not550A              ; NO: Use FCR=0, XBURST=1
        mov     [si].LL_FCR, 001h       ; YES: Use FCR=1, XBURST=whatever
        jmp     short af_next

; We don't have a 550A (or we have one, but we want to disable the FIFO)

af_not550A:
        mov     [si].LL_FCR,0           ; Force FIFO off
        mov     [si].LL_XBURST,1        ; Send one character at a time

; Move on to the next FIFO port

af_next:
        add     si, type LL_RECORD      ; Advance to the next record

        pop     cx
        dec     cx
        ljnz    af_loop                 ; Loop through all the ports

        ret

CheckUarts endp

	subttl  dump_it - display configuration information **DUMP**
	page
        IFDEF   DUMPIT
;======================================================================
; .func:    dump_it   (this function added for **DUMP**)
;
; input:    -none-
;
; output:   configuration displayed on screen
;
; comments: activated when DUMPIT is defined and no "%" at beginning of
;           command line.
;
; .calls:
; .reads:
; .writes:
;
; .endfn
;======================================================================
dump_it	proc near       ; This function added for **DUMP**

        mov     ax,cs
        mov     ds,ax
        mov     es,ax

        assume  cs:code,ds:code,es:code,ss:nothing

; Display the header

        lea     dx, d_hdr
        mov     ah, 9
        int     021h

        mov     bx,offset porttbl
        mov     si,offset LL_TABLE
        mov     dx,1

dumpit10:

; At this point:  DS:BX points to the PORTS structure
;                 DS:SI points to the LL_RECORD
;                 DX is port number

; Blank out the portion of the detail line that needs it each time

        mov     di,offset d_bstart
        mov     cx,(offset d_bend-offset d_bstart)
        mov     al,space
        rep     stosb

; Put out a 1 or 2 digit port number followed by a colon

        mov     al,dl
        cmp     al,9                     ;Is it one digit?
        jbe     dumpit15                 ;YES

        aam                              ;NO: Split the digits
        xchg    ah,al                    ;Put LSDigit in AH, MSDigit in AL
        add     ax,'00'                  ;Convert to ASCII

        mov     [word ptr d_pnum_1],ax   ;Store two digits
        mov     [d_pnum_3],':'           ;Trailing colon
        jmp     short dumpit20           ;Done with port number

dumpit15:                                ;1-digit port number
        add     al,'0'                   ;Convert to ascii
        mov     [d_pnum_1],al
        mov     [d_pnum_2],':'

; port address, input and output buffer sizes

dumpit20:
        mov     di,offset d_ad+3         ;Point to last digit of address
        mov     ax,[bx].addr             ;Get port address
        call    bintohex                 ;Convert to printable hex

        mov     di,offset d_ib+4         ;Point at last digit
        mov     ax,[bx].ibfsiz
        call    format_dec               ;Make it printable

        mov     di,offset d_ob+4         ;Point at last digit
        mov     ax,[bx].obfsiz
        call    format_dec               ;Make it printable

; Handshaking

        mov     di,offset d_hs           ;Point to handshake field
        mov     al,[bx].ioprot           ;Get flow control field

        mov     byte ptr [di],'N'        ;Assume no handshake
        test    al,0001111b              ;Any handshaking?
        jz      dumpit40                 ;NO: We guessed right

        test    al,0001000b              ;RTS protocol enabled?
        jz      dumpit31                 ;NO
          mov   byte ptr [di],'R'
          inc   di
dumpit31:

        test    al,00000100b             ;DTR protocol turned on?
        jz      dumpit32                 ;NO
          mov   byte ptr [di],'D'
          inc   di
dumpit32:

        test    al,00000010b             ;Xon/Xoff protocol turned on?
        jz      dumpit40                 ;NO

        mov     byte ptr [di],'X'        ;Assume normal Xon/Xoff
        cmp     [bx].xoffch,13h          ;Did we guess right?
        jz      dumpit40                 ;YES
        mov     byte ptr [di],'P'        ;NO: Must be XPC stuff

; Interrupt level

dumpit40:
        mov     al,[bx].prtirq           ;IRQ level
        add     al,'0'                   ;ASCII-ize
        mov     [d_in],al                ;Stash in message

; Connection type

        mov     di,offset d_cn           ;Point to connect field
        mov     al,[bx].ioprot           ;Get protocol field
        mov     byte ptr [di],'L'        ;Assume local
        test    al,30h                   ;Did we guess right?
        jz      dumpit50                 ;YES
        mov     byte ptr [di],'R'        ;Maybe its remote?
        test    al,20h                   ;Did we guess right this time?
        jz      dumpit50                 ;YES
        mov     byte ptr [di],'T'        ;Must be terminal mode

; Fifo receive threshold value

dumpit50:
        mov     di,offset d_if           ;Point to fifo-in field
        mov     al,[si].LL_FCR           ;Get FIFO control register

        test    al,00000001b             ;Is FIFO on?
        jnz      dumpit51                ;YES
        mov      word ptr [di],'on'      ; Prints as "no"!
        mov      word ptr [d_of],'on'
        jmp      dumpit60

dumpit51:
        and     al,11000000b             ;Extract fifo limit value
        mov     word ptr [di],'1 '       ;Assume limit is 1 byte
        cmp     al,00000000b             ;At 1-byte limit?
        jz      dumpit55                 ;YES

        mov     word ptr [di],'4 '       ;Guess it's 4 bytes
        cmp     al,01000000b             ;Is it?
        jz      dumpit55                 ;YES

        mov     word ptr [di],'8 '       ;Maybe it's 8
        cmp     al,10000000b             ;Are we right?
        jz      dumpit55                 ;YES

        mov     word ptr [di],'41'       ;Must be 14 bytes

dumpit55:
        mov     di,offset d_of+1         ;Point to fifo-out field
        mov     al,[si].LL_XBURST        ;Get transmit burst size
        xor     ah,ah                    ;Zap high half
        call    format_dec               ;Format it

; Print the line

dumpit60:
        push    dx

        mov     dx, offset d_detail
        mov     ah, 9
        int     021h

        mov     di, [si].LL_UTYPE        ;UART type
        mov     dx, d_types[di]           ;Convert to address of dt_xxxx
        mov     ah, 9
        int     021h

        mov     dx, offset d_tail
        mov     ah, 9
        int     021h

        pop     dx

; Advance to the next port to process

        add     bx,type ports
        add     si,type LL_RECORD
        inc     dx

        cmp     dx,[numport]            ;are we done?
        ljbe    dumpit10                ;NO: Process some more

; All done

        mov     dx, offset d_tail       ;extra blank line
        mov     ah, 9
        int     021h

        ret

; Define data areas:

d_hdr    db   ' PORT       AD      IB      OB    '
         db   'HS    IN  CN    IF   OF    UART TYPE'
         db   cr,lf,'$'

d_detail  db  ' COM'

d_bstart  label byte            ;where to start blanking

d_pnum_1  db  '?'               ;port number first (or only) digit
d_pnum_2  db  '?'               ; port number second digit (or colon)
d_pnum_3  db  '?'               ; blank (or colon)
          db  '   '
d_ad      db  '????'            ; port address (in hex)
          db  '   '
d_ib      db  '?????'           ; input buffer size
          db  '   '
d_ob      db  '?????'           ; output buffer size
          db  '    '
d_hs      db  '???'             ; handshaking info
          db  '    '
d_in      db  '?'               ; interrupt level
          db  '   '
d_cn      db  '?'               ; connection type
          db  '    '
d_if      db  '??'              ; receive fifo threshhold
          db  '   '
d_of      db  '??'              ; transmit fifo burst size
          db  '    '

d_bend    label byte            ; end of area to be blanked out
          db  '$'

d_tail    db  cr,lf,'$'         ; end-of-line marker

d_types   dw  dt_none, dt_8250B, dt_8250A, dt_16550, dt_16550A

dt_none   db  '**NO UART**$'
dt_8250B  db  '8250B$'
dt_8250A  db  '8250A/16450$'
dt_16550  db  '16550$'
dt_16550A db  '16550A$'

dump_it  endp
        ENDIF

format_dec  proc near
         push dx                ; save work regs
         push bx
         mov  bx,10             ; divisor

format_dec1:
         xor  dx,dx             ; zap the high half
         div  bx                ; extract lowest digit into dx
         add  dl,'0'            ; ascii-ize
         mov  [di],dl           ; store it
         dec  di                ; point to prior char
         cmp  ax,0              ; any more digits?
         jnz  format_dec1          ; yes: process them

         pop  bx                ; restore regs
         pop  dx
         ret

format_dec endp

bintohex proc near
         push dx                ; save work regs
         push bx
         mov  bx,16             ; divisor

bintohex1:
         xor  dx,dx             ; zap the high half
         div  bx                ; extract lowest digit into dx
         add  dl,'0'            ; ascii-ize
         cmp  dl,'9'            ; should it be a letter?
         jbe  bintohex2         ; NO
            add dl,'A'-('0'+10) ; YES: Convert it to one
bintohex2:
         mov  [di],dl           ; store it
         dec  di                ; point to prior char
         cmp  ax,0              ; any more digits?
         jnz  bintohex1         ; yes: process them

         pop  bx                ; restore regs
         pop  dx
         ret

bintohex endp

	page

;======================================================================
; .func:
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
dectobin proc	near
	xor	ax, ax			; clear ax
	mov	ch, ah			; initialize ch to 0
	mov	cl, [si]		; get the first character
	cmp	cl, '0'			; is it a digit
	jb	dtbx			; set carry and exit if no
	cmp	cl, '9'			; is it a digit
	ja	dtbx			; set carry and exit if no
dtbloop:
	mov	cl, [si]		; get the next character
	cmp	cl, '0'			; is it another digit
	jb	dtbwrap			; exit if all done
	cmp	cl, '9'			; is it another digit
	ja	dtbwrap			; exit if all done
	mov	dx, 10			; each position has 10
	mul	dx			;  times more significance
	or	dx, dx			; have we overflowed ax
	jnz	dtbx			; set carry and exit if to big
	sub	cl, '0'			; convert the new char to binary
	add	ax, cx			; add it to the others
	inc	si			; bump to get the next character
	jmp	short dtbloop		; go get the next character
dtbwrap:
	clc				; clear the carry flag (no error)
	ret				; return to caller
dtbx:
	stc				; set the carry flag (error)
	ret				; return to caller
dectobin endp



	subttl hextobin - conversion
	page
;======================================================================
; .func: hextobin - conversion
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
hextobin proc	near
	xor	ax, ax			; clear ax
	mov	ch, ah			; clear ch also
	mov	cl, [si]		; get the first character
	cmp	cl, '0'			; is it a digit
	jb	htbx			; set carry and return if no
	cmp	cl, '9'			; is it a digit
	jbe	htbloop			; go process it if yes
	and	cl, 0dfh		; convert alpha to uppercase
	cmp	cl, 'A'			; is it between a and f
	jb	htbx			; set carry and return if no
	cmp	cl, 'F'			; is it between a and f
	ja	htbx			; set carry and return if no
htbloop:
	mov	cl, [si]		; get the next character
	cmp	cl, '0'			; is it a digit
	jb	htbwrap			; exit if all done
	cmp	cl, '9'			; is it a digit
	jbe	htb1			; go process it if yes
	and	cl, 0dfh		; convert alpha to uppercase
	cmp	cl, 'A'			; is it between a and f
	jb	htbwrap			; exit if all done
	cmp	cl, 'F'			; is it between a and f
	ja	htbwrap			; exit if all done
	sub	cl, 7			; convert alpha to hex equivalent
htb1:
	sub	cl, '0'			; convert character to binary
	mov	dx, 16			; each position has 16
	mul	dx			; times more significance
	or	dx, dx			; have we overflowed ax
	jnz	htbx			; set carry and exit if yes
	add	ax, cx			; add it to the others
	inc	si			; bump to get the next character
	jmp	short htbloop		; go check the next character
htbwrap:
	clc				; clear the carry flag (no error)
	ret				; return to caller
htbx:
	stc				; set the carry flag (error)
	ret				; return to caller
hextobin endp


last	db	0

code	ends
	end

