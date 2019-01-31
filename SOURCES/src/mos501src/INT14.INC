comment ^==============================================================

                         !!! CHANGE NOTICE !!!  

                !!! USE OF THE SWPTRON/SWPTROFF MACROS !!!

Martin Stitt  07/02/90

Any additions or modifications to INT14.INC must take into account 
the control philosophy required for the Viewport hardware.  Due to 
the bank switched nature of the Viewport hardware, any access to the
serial port's registers must be surrounded by the swprton and 
swptroff macros.  This is necessary because the bank selection of 
the serial ports is tied directly to the bank selection of the
video hardware.

When this file is used to provide interrupt driven serial support for 
the Viewport hardware, the vptiomac.inc file is used for the serial
port i/o access macros.  Located within this file are the swptron and
swptroff macros.  In the Viewport case, these macros do expand to
code.  At the time of this writing this is the only workstation driver
which does use the swptron/off macros.  All other drivers which use
int14.inc have null macros for swptron/off.

The swprton macro contains code to save the currently banked in 
workstation and bank in the required workstation.  Swprtoff restores
the previously banked in workstation.  Swprton saves the interrupt
flag state and clears interrupts and swprtoff restores the previous 
interrupt flag state.  

Interrupts must not be re-enabled between the invocation of these two
macros.  The stack must also stay in balance between their use.  These
macros should also not be nested.


=======================================================================

rdg 02/17/89	modified nochild so that functions 6 and 18 are allowed
 rg9048 	prior to prtck.  added prtck macro so that srterm can
		determine if a station has been initialized before
		allowing any port activity.

mjs 02/20/89	modified reference to the structure  'port'  to use the
		name  'ports'  instead.  this is necessary for srterm
		and	ddtvna to be able to include both int14.inc and
		mostcb.inc without a conflict on the use of the var
		port (the ddtrec struct in mostcb.inc uses a var named
		port).

rdg 03/30/89	modified do12 so that it would return flow control and
 rg9089 	connection information.

rdg 04/18/89	corrected the defective timeout status return in do2.
 rg9108 	corrected the defective timeout logic in do14.	the
		timeout was originally being applied to the entire
		string write instead of to each character sent.

rdg 04/20/89	modified do1 so that remote connections no longer
 rg9110 	default to using rts/cts and dtr/dsr flow control.

mjs 05/03/89	modified do5 to allow the terminate bit to be set.
		added function 19 to allow just the input buffer or
		just the output buffer to be flushed.
		added function 20 to report the amount of data in the
		output buffer.

mjs 06/27/89	modified do11 (disable port) to test for a return value
		from the call to function 16h of extended services.
		if ax != 0 then an error exists - the irq cannot be
		freed because a reservation is already in place.

rkg 07/20/89	reset 40h in iopend, only return carry from func 8 once
		for carrier loss.

cbk 11/22/89	modified do1 & do2 to not have si as parameter and added
		do21 & do22 to use si as t/o parameter. changed updflc:
		to send xon if xmitter holding reg empty.  fixed calc
		of when to send xon in do15 & do22. fixed updflc to do a
		enaint rather than a wrier for enabling xmit hold empty

cbk  1/29/90	anded off high bit of function higher up in int14 so all
		functions could be invoked with high bit on
cbk  2/23/90	kludged code in function 2 for lanlink and now get rid of it

mjs 03/20/90	added dummy for function 23 - declare ownership.
		this is needed for stargate's cluster controller driver.

sah 04/05/90	added macro calls to swprton and swprtoff for viewport
		system 2000. this is done so that int 14 logic will switch
		the approviate work station in when int 14 is called.

cbk  5/01/90	added anding off hi bit of port address in dx at okport
		so have a valid port addr even if not enable port

mjs 05/09/90	modified do0, do4 and do11 to call clr_set_irq.  for
		$serial.sys, this function exits within _serial.asm.
		dummy versions of this function were put into vgna.asm,
		view.asm, srterm.asm and ddtvna.asm.  the purpose
		of this fix was to allow mos dsport 1 to be used 
		with the phone dialer within skplus

mjs 05/25/90	modified do11 to clear scax.  when this was not done,
		the mos dsport command would be improperly led to
		believe an error occured.

mjs 07/02/90	modify use of the swprton/swptroff macros.  see note
		at top of file.

mjs 08/03/90	clear interrupt enable register before setting it in
		function 0 and 4.  this prevents loss of serial port
		use from a warm boot.

rva 08/30/91    fix "do19" to properly handle the case of AL=0, **FLSH**
                perpetuating the AL=1/AL=2 crossup.  This will  **FLSH**
                require the documentation be changed to match   **FLSH**
                the functionality which previously existed      **FLSH**
                and has been maintained in this update.         **FLSH**

rva 09/24/91    Added logic to use the "PILDS" and "LL_RECORD"  **ENBL**
                structures in $SERIAL.SYS.                      **ENBL**
                Also combined the (nearly identical) code for   **ENBL**
                "do0" and "do4" into one piece of code at       **ENBL**
                "doInit".   Finally, port ENABLE/DISABLE logic  **ENBL**
                is now serialized to eliminate potential race   **ENBL**
                conditions.                                     **ENBL**

SAH 08/28/92	change port disable to bit 6 in ioprot instead of
		high bit in addresss
======================================================================^

	subttl	int 14h bios replacement
	page

fntbl	dw	do0			; initialize the port
	dw	do1			; write a character
	dw	do2			; read a character
	dw	do3			; check status
	dw	do4			; extended port initialize
	dw	do5			; set line protocal
	dw	do6			; identify driver function level
	dw	do7			; break modem connection
	dw	do8			; non-destructive read character
	dw	do9			; flush input and output buffers
	dw	do10			; report waiting input characters
	dw	do11			; relinquish the port for another
	dw	do12			; get current setup parameters
	dw	do13			; register terminal use of port
	dw	do14			; output a string
	dw	do15			; read a string of characters
	dw	do16			; link to another int14 handler
	dw	do17			; manipulate dtr/rts
	dw	do18			; return driver identification
	dw	do19			; selective buffer flush
	dw	do20			; report waiting output chars
	dw	do21			; write a character
	dw	do22			; read a character
	dw	do23			; declare ownership
        dw      do24                    ; return port status info
fnlen	equ	$-fntbl

; user register location on the stack

if	true				; hide from public.com
scax	equ	word ptr [bp]
scbx	equ	word ptr [bp+2]
sccx	equ	word ptr [bp+4]
scdx	equ	word ptr [bp+6]
scsi	equ	word ptr [bp+8]
scdi	equ	word ptr [bp+10]
scbp	equ	word ptr [bp+12]
scds	equ	word ptr [bp+14]
sces	equ	word ptr [bp+16]
scip	equ	word ptr [bp+18]
sccs	equ	word ptr [bp+20]
scfl	equ	word ptr [bp+22]
endif

;======================================================================
;
; .func: int14 - bios replacement
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
;================================================================
	assume	cs:code,ds:nothing,es:nothing,ss:nothing
int14:
	sti				; hardware interupts ok now
	cld				; set desired direction
	push	es			; save
	push	ds			;  the
	push	bp			;   user's
	push	di			;    context
	push	si
	push	dx
	push	cx
	push	bx
	push	ax
	mov	bp,sp			; set bp to index the user's regs
	mov	bx,cs			; code segment to bx
	mov	ds,bx			; set ds to code segment
	mov	es,bx			; and es also
	assume	cs:code,ds:code,es:code,ss:nothing

; If the symbol LOG_CALLS is defined call the routine LogCalls to record
; the call on $SERIAL.SYS in a ring buffer.  This is useful for debugging.

IFDEF LOG_CALLS
        call LogCalls
        ljc   okfn
ENDIF

; Decide if we are to handle this operation ourself, or pass it on
; to a child driver

	and	dx,07fffh		; mask off the function 11 selection
	and	ah,07fh			; get rid of hi bit

; If we have a "register child" function we always process it without
; further ado.

	cmp	ah,16			; is it a register child
	lje	okport			; just go do it if yes

; If we have no child then we have to process all calls

        cmp     word ptr [child+2],0    ; is there another driver?
        jz      nochild                 ; no: we have to handle it

; If the port number is in our range then we need to process this
; call

	cmp	dx,[numport]		; is this for one of our ports
        jb	nochild			; jump if for ours

; There is another driver linked to us, and the port number is higher
; than our highest port number.  Hand the call off to our child.

	pop	ax			; restore
	pop	bx			;  the
	pop	cx			;   user's
	pop	dx			;    registers
	sub	dx,[numport]		; port number relative to driver
	pop	si			; finish
	pop	di			;  the
	pop	bp			;   context
	pop	ds			;    restore
	pop	es
	assume	cs:code,ds:nothing,es:nothing,ss:nothing
	pushf
	call	[child]			; pass the call on to the next driver
	pushf				; save the new flags
	add	dx,[numport]		; restore dx to its original value
	popf				; get the return flags
	retf	2			; retf back to the int 14 caller

; Either we don't have a child, or else the port number is one that
; we know how to handle.

	assume	cs:code,ds:code,es:code,ss:nothing
nochild:

; If the port number is too high then we need to return an error

	cmp	dx,[numport]		; has he asked for a valid port
	jnb	badfn			; error if invalid port

; Before going any further we need to know if the port is active, so
; we need to compute the address of the correct entry in the "ports"
; table.  If the port is active, then any function we have is certain
; to be valid.

	mov	cl,5			; want to mutiply times 32
	shl	dx,cl			; dx = port * 32 = index to table
	mov	bx,[portoff]		; point bx to start of port table
	add	bx,dx			; set bx to the port entry
	mov	dx,[bx].addr		; get the port address in dx

	test	byte ptr [bx].ioprot,40h	; is port active
	jz	okport

; We always return the driver identification values and the port
; information values whether or not the port is initialized

	cmp	ah,6			; is it driver identification?
	je	okport
	cmp	ah,18			; is it driver identification?
	je	okport
        cmp     ah,24                   ; is it get port information?
        je      okport

; Before allowing any of the remaining functions on a port we have
; to make sure the hardware is properly initialized (for srterm!)

	prtck				; is the port available?

; Allow these functions only if the hardware is set up

	cmp	ah,0			; is this a port initialized?
	je	okport
	cmp	ah,4			; is it an extended port init?
	je	okport
	cmp	ah,11			; is it disable use of port?
	je	okport
	cmp	ah,12			; is it a get port parameters?
	je	okport
	cmp	ah,13			; is it a register terminal use?
	je	okport
	cmp	ah,23			; is it a declare ownership call?
        jne     badfn

okport:
	mov	cx,ax			; move function/data to cx
	mov	al,ah			; function to al
	xor	ah,ah			; convert the function to a word
	mov	si,ax			; function number to si
	shl	si,1			; convert function to an index
	cmp	si,fnlen		; is it a valid function request
	jae	badfn			; jump if invalid
	call	fntbl[si]		; go do as requested
	jmp	short okfn		; jump to the exit routine
badfn:
	mov	byte ptr [scax+1],0ffh	; set all flags in ah
okfn:
	pop	ax			; restore
	pop	bx			;  the
	pop	cx			;   user's
	pop	dx			;    context
	pop	si
	pop	di
	pop	bp
	pop	ds
	pop	es
	iret				; return to the requestor

	subttl	do0 - int 14h function 00h - initialize the port
	page
;======================================================================
;
; .func: do0 - int 14h function 00h - initialize the port
;
; int	14 entry:
; 	dx = port index (0 - ports-1)
; 	ah = 00h
; 	al = bits 7-5 baud rate (see pc doc)
; 	     bits 4-0 line control (see pc doc)
;
; do0 entry:
; 	dx = port address
; 	bx -> port record
; 	cl = int 14h entry al
;
; returns
; 	ax = status (see pc doc)
;       NOTE:  if the IRQ is not available, or there is no UART for the
;              port, then AH=0FFh
;
; .calls:
; .reads:
; .writes:
;
; .endfn
;================================================================

brate	dw	11520/11		; 0 -  110 bps
	dw	11520/15		; 1 -  150
	dw	1152/3			; 2 -  300
	dw	1152/6			; 3 -  600
	dw	1152/12			; 4 - 1200
	dw	1152/24			; 5 - 2400
	dw	1152/48			; 6 - 4800
	dw	1152/96			; 7 - 9600
	assume	cs:code,ds:code,es:nothing,ss:nothing
do0:
	mov	si,cx			; baud rate selection to si
	and	si,000e0h		; mask all but baud rate selection
	mov	cl,4			; shift it 4 bits to the right
	shr	si,cl			;   to make an offset into brate
	mov	cx,brate[si]		; get the division

;*** NOTE:  do4 merges at the following instruction after setting
;****       CX to the correct baud rate divisor.

doInit:

; ASSERT:  BX - pointer to correct "ports" record
;          CX - baud rate divisor
;          [scax] - Value of AX at entry to INT 14
;          [scdx] - Value of DX at entry to INT 14

IFDEF USE_LL_RECORD

; Find the correct LL_RECORD for this port.  NOTE:  This code assumes
; that an 8x8 -> 16 multiply suffices to index the LL_TABLE.

        mov     al, type LL_RECORD      ;**ENBL** length of each record
        mul     byte ptr [scdx]         ;**ENBL** multiply by port #
        add     ax, [LL_TABOFF]         ;**ENBL** add base address of array
        xchg    ax, si                  ;**ENBL** put LL_RECORD's addr in SI

; ASSERT:  SI is pointer to correct LL_RECORD

        cmp     [si].LL_UTYPE,UT_None   ;**ENBL** Is there a UART?
        jnz     doI_10                  ;**ENBL** YES: Ok!
           mov     byte ptr [scax+1],0FFh  ;**ENBL** Flag missing UART
           ret                             ;**ENBL** All done!
doI_10:

ENDIF

; Before we can manipulate the PILDS and LL_RECORD datastructures we must
; ensure that we are the only task in here.

        call    get_semaphore           ;**ENBL** Serialize ENABLE/DISABLE

; If we are the first port to be initialized on this interrupt level
; then we need to reserve the IRQ and turn on the interrupt in the
; 8259 chip.  This logic only applies if PILDS records exist.

IFDEF  USE_PILDS
        mov     di,[si].LL_DAD          ;**ENBL** Get address of PILDS
        cmp     di,[di].PILDS_FIRST     ;**ENBL** Is the list empty?
        jnz     doI_30                  ;**ENBL** NO!

; Reserve the interrupt and turn it on in the 8259 chip if we are
; compiling $SERIAL.SYS

  IF SERIAL
        push    cx                      ;**ENBL** Hold the divisor
        mov     ax,1601h                ;**ENBL** Request the IRQ
        mov     cl,[bx].prtirq          ;**ENBL** Which IRQ
        mov     ch,0                    ;**ENBL** (extend to 16 bits)
        pushf                           ;**ENBL** Simulate Int38H
        call    [orig38]                ;**ENBL**
        pop     cx                      ;**ENBL** Restore the divisor

        or      ax,ax                   ;**ENBL** Did we succeed?
        jz      doI_20                  ;**ENBL** YES!

; We could not reserve the IRQ.  Return an error.

        mov     byte ptr [scax+1],0FFh  ;**ENBL** Report IRQ busy
        jmp     doI_90                  ;**ENBL** Put semaphore and exit
doI_20:
  ENDIF

; Enable the interrupt in the 8259

        push    cx                      ;**ENBL** Save the divisor
        mov     cl, [di].PILDS_IRQNUM   ;**ENBL** Which one
        mov     ch, 1                   ;**ENBL** Turn on the interrupt
        call    clr_set_irq             ;**ENBL** Activate
        pop     cx                      ;**ENBL** Get back the divisor


; We know that we have the IRQ reserved, and the interrupt enabled in the
; 8259 PIC chip.  Now make sure that the port is included in the linked
; list off the PILDS

; ASSERT:   SI - pointer to LL_RECORD for the port
;           DI - pointer to PILDS for the port
;           BX - pointer to PORTS structure for the port


doI_30:

ENDIF
	

        test    byte ptr [bx].ioprot,40h         ;**ENBL** are we already active?
        jz      doI_40   		         ;**ENBL** YES

        and     byte ptr [bx].ioprot,NOT 40h         ;**ENBL** it will be now!

; The following instructions insert the LL_RECORD (@SI) at the tail of
; the linked list of LL_RECORDS associated with the PILDS (@DI):


IFDEF USE_PILDS
        mov     ax,[di].PILDS_LAST      ;**ENBL** Get address of old tail

        mov     [si].LL_PREV,ax         ;**ENBL** Old tail is new rec's pred
        mov     [si].LL_NEXT,di         ;**ENBL** PILDS is new rec's succ

        xchg    si, ax                  ;**ENBL** ax=new LL, si = old tail

        cli                             ;**ENBL** Cannot allow interrupts!
        mov     [di].PILDS_LAST,ax      ;**ENBL** New rec is now last
        mov     [si].LL_NEXT,ax         ;**ENBL** New rec is old tail's succ
        sti                             ;**ENBL** Interrupts ok now.

        xchg    si, ax                  ;**ENBL** Restore ptr to LL in SI
ENDIF

; Finally we can begin to setup the port itself.  If we get this far
; we know:
;
;    The IRQ has been reserved for the serial handler (if applicable)
;    The port is on the list off the PILDS (if applicable)
;    The 8259 mask has been enabled for the interrupt level
;    The port is not marked disabled (ie: ([bx].addr and 08000h) = 0)
;    We are holding the ENABLE/DISABLE semaphore

doI_40:
        mov     dx,[bx].addr            ;**ENBL** get address of port

; If we have a 16550A uart then we need to set up the FCR if appropriate

IFDEF USE_LL_RECORD
        cmp     [si].LL_UTYPE,UT_16550A ;**ENBL** Can it do FIFO?
        jnz     doI_41                  ;**ENBL** NO

        mov     al,0                    ;**ENBL** First turn off FIFO
        WRFCR                           ;**ENBL**

        mov     al,[si].LL_FCR          ;**ENBL** Then set correct value
        WRFCR                           ;**ENBL**

doI_41:
ENDIF

; Set up the baud rate, line control and modem control registers

        mov     ax, cx                  ;**ENBL** get the divisor
	swprton
	wrdiv				; write the baud rate divisor
	mov	ax,[scax]               ;**ENBL** move the desired config to ax
	and	al,01fh			; strip off baud rate bits
	wrlcr				; write the line control register
	mov	al,stot2+strts+stdtr	; out 2 (int enable), rts, dtr
	wrmcr				; write the modem control regist
	swprtoff
	call	do9			; flush the buffers to start
	swprton
	mov	[bx].datovr,0		; clear the data overrun flag
	mov	[bx].bufovr,0		; clear the buffer overrun flag
	mov	[bx].iopend,0		; reset any pending events
	rdlsr				; read the line status register
	mov	[bx].linest,al		; store the initial line status
	rdmsr				; clear all the change bits
	rdmsr				; read the modem status register
	swprtoff
	mov	[bx].modmst,al		; store the initial modem status

;**ENBL** If we are doing this for Function AL=0, then we want to return
;**ENBL** the current status in AX with the results provided by function
;**ENBL** AL=3.  If this is Function AL=4, then we simply return 0 in AH
;**ENBL** and don't change AL.

        mov     ah,0                    ;**ENBL** Assume 0 return
        xchg    byte ptr [scax+1],ah    ;**ENBL** stash 0, get function
        test    ah,4                    ;**ENBL** is this function 4?
        jnz     do0_was4                ;**ENBL** YES: leave the 0 in AH
	call	do3			;**ENBL** NO: report the 8250 status
do0_was4:

; Set up the interrupt enable register

	swprton
	xor	al,al
	wrier				; reset the interupt enable reg
	rdiir
	mov	al,endri+enlsi+enmsi	; enable all but transmitter empty
	wrier				; write the interupt enable regi
	swprtoff

; We have finally finished setting up the port.  We can now release the
; ENABLE/DISABLE semaphore and return control

doI_90:                                 ;**ENBL**
        call    put_semaphore           ;**ENBL** other tasks can come in
	ret				; return to caller

	subttl	do1 - int 14h function 01h - write a char
	page
;======================================================================
;
; .func: do1 - int 14h function 01h - write a char
;
; int	14 entry:
; 	dx = port index (0 - ports-1)
; 	ah = 01h
; 	al = char to write
;
; do1 entry:
; 	dx = port address
; 	bx -> port record
; 	cl = int 14h entry al
;
; returns
; 	ah = status (see pc doc)
; 	al = char to write
;
; .calls:
; .reads:
; .writes:
;
; .endfn
;================================================================
	assume	cs:code, ds:code,es:nothing,ss:nothing
do1:
	xor	si,si			;set function 1 to use default t/o
	jmp	do21a			; and use func 21


	subttl	do2 - int 14h function 02h - read a char
	page
;======================================================================
;
; .func: do2 - int 14h function 02h - read a char
;
; int	14 entry:
; 	dx = port index (0 - ports-1)
; 	ah = 02h
;
; do2 entry:
; 	dx = port address
; 	bx -> port record
;
; returns
; 	ah = status (see pc doc)
; 	al = char read
;
; .calls:
; .reads:
; .writes:
;
; .endfn
;================================================================
	assume	cs:code,ds:code,es:nothing,ss:nothing
do2:
	xor	si,si			;set function 2 to use default t/o
	jmp	do22a			; and use func 22


	subttl	do3 - int 14h function 03h - check status
	page
;======================================================================
;
; .func: do3 - int 14h function 03h - check status
;
; int	14 entry:
; 	dx = port index (0 - ports-1)
; 	ah = 03h
;
; do3 entry:
; 	dx = port address
; 	bx -> port record
;
; returns
; 	ax = status (see pc doc)
;
; .calls:
; .reads:
; .writes:
;
; .endfn
;================================================================
	assume	cs:code,ds:code,es:nothing,ss:nothing
do3:
	mov	ah,[bx].linest		; get the current line status
	and	ah,01eh			; save only the errors
	cmp	[bx].ibfcnt,0		; any input data waiting
	je	do3a			; jump if no data waiting
	or	ah,drdy			; show data ready
do3a:
	mov	cx,[bx].obfcnt		; get output characters waiting
	cmp	cx,[bx].obfsiz		; is the transmitter full
	jnb	do3b			; jump if output buffer full
	or	ah,tsre+thre		; show transmitter ready
do3b:
	mov	al,[bx].modmst		; get the current modem status
	mov	[scax],ax		; store it for the return
	ret				; return to caller


	subttl	do4 - int 14h function 04h - extended port init
	page
;======================================================================
;
; .func: do4 - int 14h function 04h - extended port init
;
; int	14 entry:
; 	dx = port index (0 - ports-1)
; 	cx:bx = actual baud rate
; 	ah = 04h
; 	al = word size,stop bits, parity
;
; do4 entry:
; 	dx = port address
; 	bx -> port record
; 	cl = int 14h entry al
;
; returns
; 	ah = 0 if no error
; 	   = 0FFh if invalid baud rate
;          = 0FFh if IRQ is not available
;          = 0FFh if there is no UART at the port's address
;
; .calls:   do0 via entry point doInit
; .reads:
; .writes:
;
; .endfn
;================================================================
	assume	cs:code,ds:code,es:nothing,ss:nothing
do4:

; Convert the baud rate in CX:BX into the correct divisor value in
; AX.  This is done by computing:   115200 / CX:BX.  Because we only
; have a 32:16 divide instruction we have to make a special case out
; of the 115200 baud rate

IFDEF DOUBLE_BAUD        ; Double the requested baud rate!!
   shl   [scbx],1
   rcl   [sccx],1
ENDIF
	cmp	[sccx],1		; did we go above 65536
	ja	do4err			; jump if above 131072
	jb	do4a			; jump if below 65536
	cmp	[scbx],49664		; are we at 115200
	jne	do4err			; invalid baud rate if not
	mov	cx,1			; divisor for 115200 baud
	jmp	doInit		        ; use the generic init routine

do4a:
        cmp     [scbx],0                ;**ZDIV** don't allow a baud rate of
        jz      do4err                  ;**ZDIV** ...zero!
	mov	dx,1			; set dx:ax max divisor(115200)
	mov	ax,49664
	div	[scbx]			; calculate the baud rate divisor
        mov     cx,ax                   ; put result in proper place
	or	dx,dx			; did we have a remainder
	ljz	doInit			; no: go init the port

; We have a bogus baud rate.  Report it

do4err:
        mov     byte ptr [scax+1],0FFh  ; set the error code
        ret

	subttl	do5 - int 14h function 05h - set protocol
	page
;======================================================================
;
; .func: do5 - int 14h function 05h - set comm protocol
;
; int	14 entry:
; 	ah = 05h
; 	al = protocol
; 	     xxxx0000 - no protocol
; 	     xxxxxxx1 - enable/disable rcv xon/xoff  \	bh = xof
; 	     xxxxxx1x - enable/disable xmit xon/xoff /	bl = xon
; 	     xxxxx1xx - enable/disable dtr/dsr
; 	     xxxx1xxx - enable/disable rts/cts
; 	     1xxxxxxx - allow modification of carrier detect mon
; 	     1xx1xxxx - enable/disable carrier detect monitoring
; 	     1x1xxxxx - enable/disable terminate on carrier drop
;
; at do5 entry:
; 	cl = al at int 14h entry
; 	dx = port address
; 	bx -> port record
;
; .calls:
; .reads:
; .writes:
;
; .endfn
;================================================================
	assume	cs:code,ds:code,es:nothing,ss:nothing
do5:
	push	cx			; save the protocal flags
	test	[bx].iopend,000011101b	; do we need to update flow control
	jz	do5a			; press on if no
	call	updflc			; update the flow control
do5a:
	pop	cx			; restore cx
	test	cl,080h			; does he want to change carrier
	jz	do5b			; jump if not changing carrier
	mov	ch,cl			; copy config to ch
	and	ch,030h			; save only the carrier data
	test	ch,20h
	jz	do5aa			; if the terminate bit is set,
	or	ch,10h			; insure than the cd bit is too
do5aa:
	mov	[bx].ioprot,ch		; store the new values
do5b:
	and	cl,00fh			; throw away carrier data
	and	[bx].ioprot,0f0h	; clear handshake config
	or	[bx].ioprot,cl		; set the new handshake
	mov	cx,[scbx]		; get the xon/xoff characters
	mov	[bx].xonch,cl		; store the xon character
	mov	[bx].xoffch,ch		; store the xoff character
	ret				; return to caller


	subttl	do6 - int 14h function 06h - report functions available
	page
;======================================================================
;
; .func: do6 - int 14h function 06h - report functions available
;
; int	14 entry:
; 	dx = port number
; 	ah = 06h
;
; do6 entry:
; 	dx = port address
; 	bx -> port record
;
; returns
; 	ah = high bit set
; 	al = highest function the driver supports
;
; .calls:
; .reads:
; .writes:
;
; .endfn
;================================================================
	assume	cs:code,ds:code,es:nothing,ss:nothing
do6:

; We compute the return value at assembly time as:
;
;               fnlen = size of function table
;               fnlen shr 1 = number of functions
;               (fnlen shr 1)-1 = highest valid function
;               8000h+(fnlen shr 1)-1 = valid execution + highest function

	mov	[scax],8000h+(fnlen shr 1)-1 ; store the status for the user
	ret


	subttl	do7 - int 14h function 07h - break modem connection
	page
;======================================================================
;
; .func: do7 - int 14h function 07h - break modem connection
;
; int	14 entry:
; 	dx = port index (0 - ports-1)
; 	bx = number of ticks to hold break
; 	ah = 07h
;
; do7 entry:
; 	dx = port address
; 	bx -> port record
;
; .calls:
; .reads:
; .writes:
;
; .endfn
;================================================================
	assume	cs:code,ds:code,es:nothing,ss:nothing
do7:
	swprton
	rdlcr				; get the line control register
	push	ax			; save the original state
	or	al,stbrk		; turn a break
	wrlcr				; write the break command
	swprtoff
	mov	si,[scbx]		; get the delay count
	inc	si			; make sure its not zero
	call	settime			; set the timers for a wait
do7a:
	call	moswait			; wait a little while
	call	chktime			; have we waited long enuf
	jnc	do7a			; wait some more if no
	pop	ax			; retrieve the original setting
	swprton
	wrlcr				; rewrite the original line contr
	swprtoff
	ret				; return to caller


	subttl	do8 - int 14h function 08h - non-destructive read
	page
;======================================================================
;
; .func: do8 - int 14h function 08h - non-desctructive read
;
; int	14 entry:
; 	dx = port index (0 - ports-1)
; 	ah = 08h
;
; do8 entry:
; 	dx = port address
; 	bx -> port record
;
; return:
; 	zf = 1 if no chars in buffer
; 	cf = 1 if terminal has disconnected (carrier lost)
; 	else zf = 0 and cf = 0	and al = next char in buffer
;
; .calls:
; .reads:
; .writes:
;
; .endfn
;================================================================
	assume	cs:code,ds:code,es:nothing,ss:nothing
do8:
	or	[scfl],040h		; set no data ready flag
	and	[scfl],not 001h		; reset the disconnected flag
	test	[bx].ioprot,020h	; are we terminating lost tasks
	jz	do8a			; skip if no
	test	[bx].iopend,040h	; have we lost carrier
	jz	do8a			; jump if no
	or	[scfl],001h		; set carry (terminal gone)
	and	[bx].iopend,not 040h	; reset carrier lost flag
	mov	[bx].kbeflg,0		; reset the keyboard empty flag
	ret				; return to caller
do8a:
	cmp	[bx].ibfcnt,0		; is there any data ready
	je	do8b			; exit if no data ready
	and	[scfl],not 40h		; show he's getting something
	mov	es,[bx].ibfseg		; and the input buffer segment
	mov	di,[bx].ibfget		; get the extraction pointer
	mov	al,es:[di]		; get the first character
	mov	byte ptr [scax],al	; store the character for the usr
do8b:
	ret				; return to caller


	subttl	do9 - int 14h function 09h - initialize buffers
	page
;======================================================================
;
; .func: do9 - int 14h function 09h - initialize buffers
;
; int	14 entry:
; 	dx = port index (0 - ports-1)
; 	ah = 09h
;
; do9 entry:
; 	dx = port address
; 	bx -> port record
;
; .calls:
; .reads:
; .writes:
;
; .endfn
;================================================================
	assume	cs:code,ds:code,es:nothing,ss:nothing
do9:
	cli				; no interuptions while reseting
	mov	[bx].ibfget,0		; reset
	mov	[bx].ibfput,0		;  all
	mov	[bx].ibfcnt,0		;   of
	mov	[bx].obfget,0		;    the
	mov	[bx].obfput,0		;     buffer
	mov	[bx].obfcnt,0		;      pointers
	mov	[bx].kbeflg,0		; reset keyboard empty flag
	test	[bx].iopend,000011101b	; do we need to update it
	jz	do9a			; continue on if all ok
	call	updflc			; update the flow control
do9a:
	sti				; open the flood gates
	ret


	subttl	do10 - int 14h function 0ah - report number in input buffer
	page
;======================================================================
;
; .func: do10 - int 14h function 0ah - report number in input buffer
;
; int	14 entry:
; 	dx = port index (0 - ports-1)
; 	ah = 0ah
;
; do10 entry:
; 	dx = port address
; 	bx -> port record
;
; .calls:
; .reads:
; .writes:
;
; .endfn
;================================================================
	assume	cs:code,ds:code,es:nothing,ss:nothing
do10:
	mov	ax,[bx].ibfcnt		; get count of characters waitin
	mov	[scax],ax		; store the count
	ret


	subttl	do11 - int 14h function 0bh - disable sc use of port
	page
;======================================================================
;
; .func: do11 - int 14h function 0bh - disable sc use of port
;
; int	14 entry:
; 	dx = port index (0 - ports-1)
; 	     dh high bit = 0 disables the port
; 	     dh high bit = 1 disable the port if a unique irq
; 	ah = 0bh
;
; do11 entry:
; 	dx = port address
; 	bx -> port record
;
; returns
; 	al = 0 if irq is unique and port was disabled
; 	al = 1 if irq not unique (port not disabled)
; 	al = 2 if irq already reserved
;
; .calls:
; .reads:
; .writes:
;
; .endfn
;================================================================
	assume	cs:code,ds:code,es:nothing,ss:nothing
do11:
	mov	byte ptr [scax],0	; clear the return code

        call    get_semaphore           ;**ENBL** Serialize ENABLE/DISABLE
        test    byte ptr [bx].ioprot,40h;**ENBL** is it already disabled?
        jz      do11_10                 ;**ENBL** NO: Better disable it

; The port is already disabled.  We want to return a status of 1 if
; the interrupt is still in use by another port and the user wants
; extended return status.

IFDEF USE_PILDS
        mov     al,type LL_RECORD       ;**ENBL** Find the correct LL_RECORD
        mul     byte ptr [scdx]         ;**ENBL**
        add     ax,[LL_TABOFF]		;**ENBL**
        xchg    ax,si                   ;**ENBL** SI = ptr to LL_RECORD

        mov     di,[si].LL_DAD          ;**ENBL** DI = ptr to PILDS
        cmp     di,[di].PILDS_FIRST     ;**ENBL** Is list empty?
        jnz      rsr110
        jmp      do11_15
;        jz      do11_15                 ;**ENBL** Yes: make sure we
                                        ;**ENBL** ...free the IRQ and
                                        ;**ENBL** then return 0 status
rsr110:
        test    [scdx],8000h            ;**ENBL** Extended return requested?
        ljz     do11_90                 ;**ENBL** NO: Return success

        mov     byte ptr [scax+1],1     ;**ENBL** Indicate port is free
                                        ;**ENBL** ...but interrupt isn't
        jmp     do11_90                 ;**ENBL** put sem and exit
ELSE
        jmp     do11_90                 ;**ENBL** put sem and exit w/zero
ENDIF

; Before we manipulate any of the higher level data structures lets
; bring down the port itself.

do11_10:
	call	do9			; flush all of the buffers
	mov	al,0			; turn off all interupts
	swprton
	wrier				; reset the interupt enable reg
	rdiir				; clear the interupt id register
        mov   cx,16                     ;**FIFO** make sure we clean out FIFO
do11_11:                                ;**FIFO**
	rdrxd				; clear any outstanding receive data
        loop  do11_11                   ;**FIFO**
	rdlsr				; clear the line status register
	rdmsr				; clear the modem status register
	swprtoff

; We need to remove the port from the linked list of active ports at
; this interrupt level

IFDEF USE_LL_RECORD
        mov    al,type LL_RECORD       ;**ENBL** size of each LL_RECORD
        mul    byte ptr [scdx]         ;**ENBL** compute offset into table
        add    ax, [LL_TABOFF]         ;**ENBL** convert to pointer
        xchg   si, ax                  ;**ENBL** point si at LL_RECORD

        test   [si].LL_FCR,1           ;**FIFO** is FIFO enabled?
        jz     do11_12                 ;**FIFO** NO
        mov    al,00h                  ;**FIFO** YES: Turn it off
        WRFCR                          ;**FIFO**
do11_12:                               ;**FIFO**

   IFDEF USE_PILDS
        mov    di,[si].LL_PREV         ;**ENBL** my pred
        mov    ax,[si].LL_NEXT         ;**ENBL** my succ

        cli                            ;**ENBL** no ints while tweaking list
        mov    [di].LL_NEXT,ax         ;**ENBL** point my pred at my succ
        xchg   ax,di                   ;**ENBL** ax=pred, di=succ
        mov    [di].LL_PREV,ax         ;**ENBL** point my succ at my pred
        sti                            ;**ENBL** ints ok again
   ENDIF
ENDIF

; We can now mark the port as disabled in the "ports" record

        or     byte ptr [bx].ioprot,40h         ;**ENBL** It's disabled

; If we just emptied out the PILDS chain, then we have to disable the
; interrupt in the 8259 PIC and free the interrupt for application use

IFDEF USE_PILDS
        mov    di,[si].LL_DAD           ;**ENBL** Get pointer to PILDS
        cmp    di,[di].PILDS_FIRST      ;**ENBL** Is it empty now?
        jnz    do11_20                  ;**ENBL** NO!

        push   cx                       ;**ENBL** Preserve this register
        mov    cl,[di].PILDS_IRQNUM     ;**ENBL** Which IRQ
        mov    ch, 0                    ;**ENBL** Turn it off
        call   clr_set_irq              ;**ENBL**
        pop    cx                       ;**ENBL** Get back the reg
ENDIF

; Release the IRQ to MOS
; NOTE: We merge at this location if the port is already disabled and
;       the linked list is empty.  This will ensure that we free up
;       the IRQ on a DSPORT, even of a port that was not previously
;       enabled.  This accounts for the crocky situation where MOS
;       marks a device driver as reserving all IRQs that it sets up.

do11_15:

  IF SERIAL
        mov    ax,1600h                 ;**ENBL** Release IRQ
        mov    cl,[bx].prtirq           ;**ENBL** Interrupt level
        mov    ch,0                     ;**ENBL** Extend to 16 bits
        pushf                           ;**ENBL** Simulate INT 38
        call   [orig38]                 ;**ENBL**
  ENDIF

; Since we just released the IRQ we know that we are all done and the
; both the port and the IRQ are available for others.

        jmp    short do11_90            ;**ENBL** Release sem and exit

; We get here if we have just shut down the port, but the linked list
; isn't empty.  If the user has requested extended results then return
; a 1 to indicate that the IRQ is NOT available.

IFDEF USE_PILDS
do11_20:
        test   [scdx],8000h             ;**ENBL** Extended results?
        jz     do11_90                  ;**ENBL** NO: put sem and exit

        mov    byte ptr [scax],1        ;**ENBL** Indicate IRQ still in use
ENDIF

do11_90:
        call   put_semaphore            ;**ENBL** Let other tasks in
        ret

	subttl	do12 - int 14h function 0ch - get serial parameters
	page
;======================================================================
;
; .func: do12 - int 14h function 0ch - get current serial parameters
;
; int	14 entry:
; 	dx = port index (0 - ports-1)
; 	ah = 0ch
;
; do12 entry:
; 	dx = port address
; 	bx -> port record
;
; return:
; 	al = line control register config
; 	ah = flow control config/connection information
; 	cx:bx = baud rate
; 	dl = xoff character (zero if not using xon/xoff)
; 	dh = xon character (zero if not using xon/xoff)
;
; .calls:
; .reads:
; .writes:
;
; .endfn
;================================================================
	assume	cs:code,ds:code,es:nothing,ss:nothing
do12:
	swprton
	rddiv				; read the baud rate divisor
IFDEF DOUBLE_BAUD
     shl ax,1           ; double the divisor so we report half the rate
ENDIF
	mov	cx,ax			; move it to cx
	push	dx			; save the port address
	mov	dx,1			; set dx:ax to the max baud rate
	mov	ax,49664		;   (115200)
	cmp	cx,1			; is it 115200
	jbe	do12a			; cx:bx right if 115200
	div	cx			; divide it by the divisor
	mov	dx,0			; dx:ax must be less than 65636
do12a:
	mov	[scbx],ax		; store the baud rate ls
	mov	[sccx],dx		; store the baud rate ms
	mov	ax,0			; not using xon/xoff
	test	[bx].ioprot,003h	; are we using xon/xoff
	jz	do12b			; not xon/xoff characters if no
	mov	al,[bx].xoffch		; get the xoff character
	mov	ah,[bx].xonch		; and the xon character
do12b:
	mov	[scdx],ax		; store the xon/xoff characters
	pop	dx			; restore the port address
	rdlcr				; read the line control register
	swprtoff
	and	al,01fh			; save the config info
	mov	ah,[bx].ioprot		; get flow control/connection in
	and	ah,03fh			; mask the other junk
	mov	[scax],ax		; return config info to the user
	ret				; return to caller


	subttl	do13 - int 14h function 0dh - register terminal use of port
	page
;======================================================================
;
; .func: do13 - int 14h function 0dh - register terminal use of port
;
; int	14 entry:
; 	dx = port index (0 - ports-1)
; 	ah = 0dh
;
; do13 entry:
; 	dx = port address
; 	bx -> port record
;
; return
; 	es:bx -> key ready flag (<> 0 when scan codes are buffe)
; 	ah = 0 if valid port
; 	   = ff if invalid port
;
; .calls:
; .reads:
; .writes:
;
; .endfn
;================================================================
	assume	cs:code,ds:code,es:nothing,ss:nothing
do13:
	mov	[sces],cs		; store the structure segment
	lea	ax,[bx].kbeflg		; point to the keyboard empty flag
	mov	[scbx],ax		; store the counter offset
	mov	byte ptr [scax+1],0	; show a successful register
	ret


	subttl	do14 - int 14h function 0eh - string output
	page
;======================================================================
;
; .func: do14 - int 14h function 0eh - output string
;
; int	14 entry:
; 	ah = 14  (8eh)
; 	es:bx -> pointer to string
; 	cx = length of string
; 	dx = port number
; 	si = # of ticks for timeout
;
; do14 entry:
; 	bx = port number as a structure address
; 	sces:scbx -> pointer to string
; 	sccx = length of string
; 	scsi = # of ticks for timeout
; 	es,ds -> code segment
; 	cx = scax   (can ignore here)
; 	dx = port address
;
; do14 exit:
; 	scax = number of characters transferred
; 	scfl = zr if time out (else nz)
;
; int14 exit:
; 	ax = number of characters transferred
; 	zf = 1 if timeout (else zf = 0)
;
; .calls:
; .reads:
; .writes:
;
; .endfn
;================================================================
	assume	cs:code,ds:code,es:nothing,ss:nothing
do14:
	mov	[scax],0		; show nothing sent
	and	[scfl],not 40h		; set zf=0 (all completed ok)
	cmp	[sccx],0		; is there anything to send
	jne	do14a			; press on if yes
	ret				; all done if nothing to send
do14a:
	mov	si,[scsi]		; get the timeout value
	cmp	si,0			; does he want to use the default
	jne	do14b			; jump if timeout ok
	mov	si,tocount		; get the default
do14b:
	call	settime			; go set the timeout values
do14c:
	mov	cx,[bx].obfsiz		; get the buffer size
	cmp	cx,[bx].obfcnt		; is the buffer still full
	ja	do14e			; send a few characters if not full
	call	chktime			; go check for a timeout
	jnc	do14d			; jump if there is still time left
	or	[scfl],040h		; show we timed out
	ret				; return to caller
do14d:
	call	moswait			; lets wait a little while
	jmp	short do14c		; go check again
do14e:
	push	dx			; save the port address
	push	es			; save es
	mov	dx,[sccx]		; get the count to send
	sub	dx,[scax]		; minus the count already sent
	mov	cx,[bx].obfsiz		; get the buffer size
	sub	cx,[bx].obfcnt		; calculate how much room we have
	cmp	dx,cx			; is the buffer big enuf
	jbe	do14f			; jump if yes
	mov	dx,cx			; set dx to the available space
do14f:
	mov	es,[bx].obfseg		; get the buffer segment
	mov	di,[bx].obfput		; get the insertion pointer
	mov	cx,[bx].obfsiz		; set cx to the end of the buffer
	sub	cx,di			; how much room to the end
	cmp	cx,dx			; will it all fit here
	jb	do14g			; jump if no
	mov	cx,dx			; set cx to send it all
do14g:
	push	ds			; save the data segment
	push	cx			; save the amount moved here
	mov	ds,[sces]		; get the data segment
	assume	cs:code,ds:nothing,es:nothing,ss:nothing
	mov	si,[scbx]		; get the original pointer
	add	si,[scax]		; and the amount already sent
	rep	movsb			; move it to the buffer
	pop	ax			; get the count already sent
	mov	cx,dx			; set cx to the total
	sub	cx,ax			; calculate the count remaining
	jcxz	do14h			; skip the next move if no more
	mov	di,0			; wrap around the ring buffer
	rep	movsb			; move the rest
do14h:
	pop	ds			; restore ds
	assume	cs:code,ds:code,es:nothing,ss:nothing
	add	[scax],dx		; add the count sent
	add	[bx].obfcnt,dx		; add the count inserted
	mov	[bx].obfput,di		; update insertion pointer
	pop	es			; restore es
	pop	dx			; restore the port address

        
        mov	al,entei		; transmitter empty interups
        swprton
	enaint				; enable them when output buffered
	swprtoff
	mov	cx,[sccx]		; get the count to send
	cmp	[scax],cx		; have we sent it all
	jne	do14i			; keep trying if no
	ret				; return to caller
do14i:
	jmp	do14a			; try again if more to do


	subttl	do15 - int 14h function 0fh - string input
	page
;======================================================================
;
; .func: do15 - int 14h function 0fh - string input
;
; int	14 entry:
; 	ah = 15  (8fh)
; 	es:bx -> pointer to user's buffer
; 	cx = maximum number of charactors to be read
; 	dx = port number
; 	si = # of ticks for timeout
;
; do15 entry:
; 	bx = port number as a structure address
; 	sces:scbx -> pointer to user's buffer
; 	sccx = maximum number of charactors to be read
; 	scsi = # of ticks for timeout
; 	es,ds -> code segment
; 	cx = scax   (can ignore here)
; 	dx = port address
;
; do15 exit:
; 	scax = number of characters transferred
; 	scfl = zr if time out (else nz)
;
; int14 exit:
; 	ax = number of characters transferred
; 	zr if time out (else nz)
;
; .calls:
; .reads:
; .writes:
;
; .endfn
;================================================================
	assume	cs:code,ds:code,es:nothing,ss:nothing
do15:
	and	[scfl],not 040h		; intialize the timeout flag
	mov	si,[scsi]		; get the requested timeout
	cmp	si,0			; should we use the default
	jne	do15a			; jump if not default
	mov	si,[tocount]		; get the default timeout
do15a:
	call	settime			; set the timeout counters
do15b:
	cmp	[bx].ibfcnt,0		; anything there yet
	jne	do15d			; go get it if yes
	call	chktime			; have we run out of time
	jnc	do15c			; jump if still time
	or	[scfl],040h		; show we timed out waiting
	mov	[scax],0		; show nothing read
	ret				; return to caller
do15c:
	call	moswait			; wait and see if anything comes
	jmp	short do15b		; go check again
do15d:
	mov	es,[sces]		; get the users buffer segment
	mov	di,[scbx]		; and its offset
	mov	cx,[sccx]		; get his max count
	cmp	cx,[bx].ibfcnt		; do we have enuf for him
	jb	do15e			; jump if plenty ready
	mov	cx,[bx].ibfcnt		; can only give as many as we got
do15e:
	mov	[scax],cx		; store the count to be returned
	mov	dx,cx			; save for later calculations
	mov	si,[bx].ibfget		; get the extraction pointer
	mov	cx,[bx].ibfsiz		; end of first string
	sub	cx,si			; how many before end of buffer
	cmp	cx,dx			; is it all here
	jbe	do15f			; jump if in two strings
	mov	cx,dx			; less than to end of buffer
do15f:
	sub	dx,cx			; subtract the count to move
	push	ds			; save the data segment
	mov	ds,[bx].ibfseg		; get the data segment
        rep	movsb			; move the first string
	mov	cx,dx			; move remainder count to cx
	jcxz	do15g			; jump if nothing in the 2nd segment
	mov	si,0			; reset si to start of buffer
	rep	movsb			; move the rest to the buffer
do15g:
	pop	ds			; restore ds
	mov	[bx].ibfget,si		; store the new extraction pointer
	mov	ax,[scax]		; get the count taken
	sub	[bx].ibfcnt,ax		; adjust count in the buffer
	cmp	[bx].ibfcnt,0		; did we empty the buffer
	jne	do15h			; skip keyboard flag reset if no
	mov	[bx].kbeflg,0		; reset the keyboard empty flag
do15h:
	test	[bx].ioprot,000001111b	; are we using flow control
	jz	do15i			; continue if no flow control
	mov	ax,[bx].ibfsiz		; get the buffer do1:
	mov	cx,ax
	shr	ax,1			; divide by 2
	shr	ax,1			; open the gates when below max\4
	sub	cx,[bx].ibfcnt		;bufsize-bufcnt=room avail
	cmp	cx,ax			; is it empty enuf
	jb	do15i			; don't open it up yet
	test	[bx].iopend,000011101b	; do we need to update it
	jz	do15i			; continue if still ok
	call	updflc			; update the flow control
do15i:
	ret				; return to caller


	subttl	do16 - int 14h function 10h - link another serial driver
	page
;======================================================================
;
; .func:	do16 - int 14h funciton 10h - link another serial driver
;
; int	14 entry:
; 	ah = 10h
; 	es:bx cs:ip of child's int 14 entry point
;
; do16 entry:
; 	[sces]:[scbx] cs:ip of child's int 14 entry point
;
; .calls:
; .reads:
; .writes:
;
; .endfn
;================================================================
	assume	cs:code,ds:code,es:nothing,ss:nothing
do16:
	mov	es,[sces]		; get segment of the child
	mov	bx,[scbx]		; get offset of the child
	mov	ax,word ptr [child]	; get our child offset
	or	ax,word ptr [child+2]	; or in our child segment
	jnz	do16a			; jump if we already have a child
	mov	word ptr [child],bx	; else store the child offset
	mov	word ptr [child+2],es	; and the child segment
	ret				; and then return to the caller
do16a:
	mov	ax,[scax]		; make sure the function is here
	pushf				; store the flag like an int
	call	[child]			; tell our child to handle this one
	ret				; return to caller


	subttl	do17 - int 14h function 11h - manipulate dtr/rts
	page
;======================================================================
;
; .func: do17 - int 14h function 11h - manipulate dtr/rts
;
; int	14 entry:
; 	ah = 17 (91h)
; 	al = value for 8250 mcr (base+4)
; 	dx = port number
;
; do17 entry:
; 	[scax] = as above
; 	dx = port number
;
; .calls:
; .reads:
; .writes:
;
; .endfn
;================================================================
	assume	ds:code,es:nothing,ss:nothing
do17:
	mov	ax,[scax]		; get modem control register data
	or	al,008h			; out 2 must remain set
	swprton
	wrmcr				; set the modem control register
	swprtoff
	ret				; return to caller


	subttl	do18 - int 14h function 12h - return driver description
	page
;======================================================================
;
; .func: do18 - int 14h function 12h - return driver description
;
; int	14 entry
; 	ah = 12h
; 	dx = port
;
; returns:
; 	ax = 0
; 	ds:bx -> 40 byte description of driver
;
; .calls:
; .reads:
; .writes:
;
; .endfn
;================================================================
	assume	cs:code,ds:code,es:nothing,ss:nothing
do18	label	near
	mov	word ptr [scds],cs	; return message area in ds:bx
	mov	word ptr [scbx],offset sername  ; point to the message
	mov	word ptr [scax],0	; show a valid return
	ret				; return to caller


	subttl	do19 - int 14h function 13h - selective buffer flush
	page
;======================================================================
;
; .func: do19 - int 14h function 13h - selective buffer flush
;
; int	14 entry
; 	ah = 13h
;       al = 0 to do nothing                    **FLSH**
; 	al = 1 to flush output buffer           **FLSH**
; 	al = 2 to flush input buffer            **FLSH**
; 	al = 3 to flush both
; 	dx = port
;
; .calls:
; .reads:
; .writes:
;
; .endfn
;================================================================
	assume	cs:code,ds:code,es:nothing,ss:nothing
do19:
	mov	ax,[scax]

	test	ax,1            ;**FLSH** flush output buffer?
	je	do19a           ;**FLSH** NO: go check input buffer

	cli                     ;**FLSH** Don't allow interrupts

	mov	[bx].obfget,0   ;**FLSH** Zap the ring buffer vars
	mov	[bx].obfput,0   ;**FLSH**
	mov	[bx].obfcnt,0   ;**FLSH**

do19a:

	test	ax,2            ;**FLSH** flush input buffer?
        je      do19b           ;**FLSH** NO: all done

	cli			;**FLSH** Don't allow interrupts

	mov	[bx].ibfget,0   ;**FLSH** Zap the ring buffer vars
	mov	[bx].ibfput,0   ;**FLSH**
	mov	[bx].ibfcnt,0   ;**FLSH**

	mov	[bx].kbeflg,0	;**FLSH** Indicate no chars in buffer

do19b:                          ;**FLSH** Now check for updating flow

	test	[bx].iopend,000011101b	; do we need to update it
	jz	do19e			; continue on if all ok
	call	updflc			; update the flow control
do19e:
	sti				; open the flood gates
	ret


	subttl	do20 - int 14h function 14h - report output buffer status
	page
;======================================================================
;
; .func: do20 - int 14h function 14h - report output buffer status
;
; int	14 entry
; 	ah = 14h
; 	dx = port
;
; .calls:
; .reads:
; .writes:
;
; .endfn
;================================================================
	assume	cs:code,ds:code,es:nothing,ss:nothing
do20:
	mov	ax,[bx].obfcnt		; get count of characters waitin
	mov	[scax],ax		; store the count
	ret


	subttl	do21 - int 14h function 15h - write a char
	page
;======================================================================
;
; .func: do21 - int 14h function 15h - write a char
;
; int	14 entry:
; 	dx = port index (0 - ports-1)
; 	ah = 15h
; 	al = char to write
; 	si = t/o value (0=default,else # of ticks)
;
; do1 entry:
; 	dx = port address
; 	bx -> port record
; 	cl = int 14h entry al
;
; returns
; 	ah = status (see pc doc)
; 	al = char to write
;
; note: function 1 enters this code at do21a with si set for default t/o
; this routine is "assuming" that si will not be destroyed between do21a
; and	do1f.
;
; .calls:
; .reads:
; .writes:
;
; .endfn
;================================================================
	assume	cs:code,ds:code,es:nothing,ss:nothing
do21:
	mov	si,[scsi]		; get the requested time out
do21a:					;entry point for func 1
	cmp	[bx].obfcnt,0		; are we buffering output
	ljne	do1f			; jump if data buffered up
	mov	ah,[bx].ioprot		; get the protocol config
	mov	ch,0			; use ch for a counter
do1a:
	test	ah,000001111b		; are we using flow control
	jz	do1d			; send the character if no
	test	ah,000001000b		; are we using rts/cts
	jz	do1b			; jump if not using rts/cts
	test	[bx].modmst,ctsst	; is cts high
	ljz	do1f			; buffer it if cts is low
do1b:
	test	ah,000000100b		; are we using dtr/dsr
	jz	do1c			; jump if not using dtr/dsr
	test	[bx].modmst,dsrst	; is dsr high
	jz	do1f			; buffer it if dsr is low
do1c:
	test	ah,000000011b		; are we using xon/xoff
	jz	do1d			; jump if not using xon/xoff
	test	[bx].iopend,000000010b	; have we been told xoff
	jnz	do1f			; buffer it if we received xoff
do1d:
	swprton
	rdlsr				; read the line status register
	swprtoff
	test	al,thre			; is the transmitter ready for one
	jnz	do1e			; send it if ready
	inc	ch			; bump the count of attempts
	test	ch,020h			; have we tried for awhile
	jz	do1a			; try again if not long enuf
	jmp	short do1f		; do a buffered write if not yet
do1e:
	mov	al,cl			; retrieve the character
	swprton
	wrtxd				; send the character
	swprtoff
	push	ax			; save the character
	call	do3			; get the current status
	pop	ax			; retrieve the original char
	mov	byte ptr [scax],al	; restore the original character
	ret				; return to caller
do1f:
	cmp	si,0			; does he want the default
	jne	do1g			; jump if it's a good one
	mov	si,[tocount]		; get the timeout value
do1g:
	call	settime			; go set the timeout values
do1h:
	mov	ax,[bx].obfcnt		; get the count in the buffer
	cmp	ax,[bx].obfsiz		; is the buffer still full
	jb	do1j			; jump if there is now room
	call	chktime			; have we waited long enuf
	jnc	do1i			; jump if time has run out
	push	cx			; save the character
	call	do3			; go get the current status
	or	ah,080h			; show we timed out
	pop	cx			; retrieve the character
	mov	al,cl			; move the original char back to al
	mov	[scax],ax		; store the orginal character
	ret				; return to the caller
do1i:
	call	moswait			; wait a little while
	jmp	short do1h		; go look again
do1j:
	mov	es,[bx].obfseg		; get the output buffer segment
	mov	di,[bx].obfput		; get the insertion pointer
	mov	al,cl			; move the character to al
	stosb				; store the character
	cmp	di,[bx].obfsiz		; have we wrapped the buffer
	jb	do1k			; jump if no wrap
	mov	di,0			; reset the pointer
do1k:
	mov	[bx].obfput,di		; store the new pointer
	inc	[bx].obfcnt		; bump the count
	cmp	[bx].obfcnt,1		; is this the first character
	jne	do1l			; jump if already running buffer
	mov	al,entei		; enable transmitter empty inter
	swprton
	enaint				; enable transmitter empty inter
	swprtoff
do1l:
	push	cx			; save the original character
	call	do3			; update the status
	pop	ax			; retrieve the character
	mov	byte ptr [scax],al	; store the original character
	ret				; return to caller


	subttl	do22 - int 14h function 16h - read a char
	page
;======================================================================
;
; .func: do22 - int 14h function 16h - read a char
;
; int	14 entry:
; 	dx = port index (0 - ports-1)
; 	ah = 16h
; 	si = t/o value (0=default,else # of ticks)
;
; do2 entry:
; 	dx = port address
; 	bx -> port record
;
; returns
; 	ah = status (see pc doc)
; 	al = char read
;
; note: function 2 enters this code at do22a with si set for default t/o
;
; .calls:
; .reads:
; .writes:
;
; .endfn
;================================================================
	assume	cs:code,ds:code,es:nothing,ss:nothing
do22:
	mov	si,[scsi]		; get the requested timeout
do22a:					;entry point from function 2
        cli                             ;**RENT** Don't let others in
	cmp	[bx].ibfcnt,0		; is there anything in the buffer
	jne	do2c			; if yes go get him one
        sti                             ;**RENT** Ok to let others in
	cmp	si,0			; does he want the default
	jne	do2a			; jump if his timeout is ok
	mov	si,[tocount]		; get the timeout value
do2a:
	call	settime			; go set the timers
do2b:
	call	moswait			; wait a while
        cli                             ;**RENT** Don't let others in
	cmp	[bx].ibfcnt,0		; is there anything yet
	jne	do2c			; get him one if yes
        sti                             ;**RENT** Ok to let others in
	call	chktime			; check the time
	jnc	do2b			; wait some more if time
	push	cx			; save the original ax
	call	do3			; get the current status
	or	ah,080h			; add the timeout bit
	pop	bx			; retrieve the original characte
	mov	al,bl			; restore the character to al
	mov	[scax],ax		; return the status/original cha
	ret				; return to caller

;**RENT** NOTE: When we get here interrupts are always disabled, and we
;**RENT**       are CERTAIN that [bx].ibfcnt > 0, thus we can safely
;**RENT**       extract a character from the ring buffer before letting
;**RENT**       other tasks in.

do2c:
	mov	es,[bx].ibfseg		; get the input buffer segment
	mov	si,[bx].ibfget		; get the extraction pointer
	mov	al,es:[si]		; get a character
	inc	si			; bump the pointer
	cmp	si,[bx].ibfsiz		; have we wrapped the buffer
	jb	do2d			; jump if pointer ok
	mov	si,0			; reset to the beginning
do2d:
	mov	[bx].ibfget,si		; update the extraction pointer
	dec	[bx].ibfcnt		; and the count

	cmp	[bx].ibfcnt,0		; have we cleared the buffer
	jne	do2e			; skip keyboard flag reset if no
	mov	[bx].kbeflg,0		; reset the keyboard empty flag
do2e:
        sti                             ;**RENT** Ok to let others in

	push	ax			; save the character
	test	[bx].ioprot,000001111b	; are we using flow control
	jz	do2f			; continue if no flow control
	mov	ax,[bx].ibfsiz		; get the buffer size
	mov	cx,ax
	shr	ax,1			; divide by 2
	shr	ax,1			; open the gates when below max\4
	sub	cx,[bx].ibfcnt		;ibfsize-ibfcnt=room avail
	cmp	cx,ax			; is it empty enuf
	jb	do2f			; don't open it up yet
	test	[bx].iopend,000011101b	; do we need to update it
	jz	do2f			; continue if still ok
	call	updflc			; update the flow control
do2f:
	call	do3			; update the status
	pop	ax			; retrieve the character
	mov	byte ptr [scax],al	; store the original al
	ret				; return to caller


	subttl	do23 - int 14h function 17h - declare ownership
	page
;======================================================================
;
; .func: do23 - int 14h function 17h - declare ownership
;
; int	14 entry:
; 	dx = port index (0 - ports-1)
; 	ah = 17h
; 	bx = tcb of owner task
;
; returns: none
;
; this function was implemented for the sake of stargate's cluster
; controller driver.  $serial.sys,vna.sys and vgna.sys have no use
; for it - but must implement this dummy to handle the call.  the
; ddt is who makes a call to this function.
;
; .calls:
; .reads:
; .writes:
;
; .endfn
;================================================================
	assume	cs:code,ds:code,es:nothing,ss:nothing
do23:
	ret

	subttl	do24 - int 14h function 18h - get port information
	page
;======================================================================
;
; .func: do24 - int 14h function 18h - get port information
;
; int	14 entry:
; 	dx = port index (0 - ports-1)
;       es:bx = address of port information record
;       cx = max number of bytes to return in port information record
; 	ah = 18h
;
; returns: cx = actual number of bytes returned
;          @[es:bx] = filled in port information record as follows:
;
;
;      WORD     "AD=" value.  If the port is currently disabled the
;               high bit (8000h) of this word will be set.  If this
;               value is not applicable a driver can return 7FFFh
;               for an enabled port and 0FFFFh for a disabled port.
;
;      WORD     "IB=" value.  Input buffer size in bytes.
;      WORD     "OB=" value.  Output buffer size in bytes.
;
;
;      BYTE     "IN=" value.  IRQ level.  The interrupt used by this port.
;               If this value is not applicable a driver can return
;               0FFh.
;
;      BYTE     "CN=" value.  Connection type.  Valid values are:
;                      'L' - Local connection
;                      'R' - Remote connection
;                      'T' - Restart task on loss of connection
;                If this value is not applicable a driver can return
;                0FFh.
;
;       BYTE     "HS=" value.  Handshaking information.  Each bit in
;                this byte has a specified value as follows:
;                     80h - reserved
;                     40h - reserved
;
;                     20h - transmitter CTS flow control.  This port
;                         only transmit when the CTS line is active.
;
;                     10h - transmitter DSR flow control.  This port
;                         only transmit when the DSR line is active.
;
;                     08h - receiver RTS flow control.  This port will
;                         drop RTS when the input buffer is 3/4 full,
;                         and will raise RTS when the buffer is 1/4
;                         full.
;
;                     04h - receiver DTR flow control.  This port will
;                         drop DTR when the input buffer is 3/4 full,
;                         and will raise DTR when the buffer is 1/4
;                         full.
;
;                     02h - transmitter XON/XOFF.  This port will pay
;                         kattention to received XON/XOFF characters.
;
;                     01h - receiver XON/XOFF (or XPC) enabled.  This
;                         port will send Xoff when input buffer is 3/4
;                         full, and will send Xon when the buffer is
;                         1/4 full.
;
;                If this value is not applicable a driver can return
;                0FFh.  NOTE: With the current implementation of
;                $SERIAL.SYS certain pairs of bits are always the same
;                because you cannot seperately specify transmit and
;                receive hardware flow control.
;
;       BYTE     Transmit XON character.
;       BYTE     Receive XON character.
;       BYTE     Transmit XOFF character.
;       BYTE     Receive XOFF character.
;
;                NOTE: With the current implementation of $SERIAL.SYS
;                the receive and transmit Xon characters are always
;                equal, as are the receive and transmit Xoff characters.
;
;       BYTE     "IF=" value.  The input FIFO threshold for the port.
;                0 means the FIFO is disabled.
;
;       BYTE     "OF=" value.  The output FIFO transmit burst size.
;                0 means the FIFO is disabled.
;
;       BYTE     UART type code.   A code indicating the type of UART
;                detected for this port.  Values are:
;                   0 - No UART
;                   1 - 8250B
;                   2 - 8250A or 16450
;                   3 - 16550
;                   4 - 16550A  ( required to use FIFOs )
;                 255 - Not applicable (can be used by other drivers)
;                 Other values may be added in the future.
;
; .calls:
; .reads:
; .writes:
;
; .endfn
;================================================================
	assume	cs:code,ds:code,es:nothing,ss:nothing

pirec struc

pirec_ad    dw  ?
pirec_ib    dw  ?
pirec_ob    dw  ?
pirec_in    db  ?
pirec_cn    db  ?
pirec_hs    db  ?
pirec_xxon  db  ?
pirec_rxon  db  ?
pirec_xxoff db  ?
pirec_rxoff db  ?
pirec_if    db  ?
pirec_of    db  ?
pirec_uart  db  ?

pirec ends


do24:

; If the specified length is more than we can possibly return then
; adjust it downward

       mov     cx,[sccx]                ;User requested length
       cmp     cx,type pirec            ;Is it too much?
       jbe     do24LenOk
       mov     cx,type pirec
       jmp     short do24LenOk

; If the user gave us an odd length in the middle of a WORD value we come
; here to adjust it downward by one byte and try again

do24Sub1:
       dec     cx

; ASSERT:  CX is a value in the range 0..type pirec.  Compute the
; correct address to jump to and push that address on the stack

do24LenOk:
       mov     bx, cx                 ;Put in an index register
       shl     bx, 1                  ;Convert to word index
       push    do24VecTab[bx]         ;Push correct address onto stack

IFDEF USE_LL_RECORD
       mov     al,byte ptr [scdx]     ;Get port number
       mov     ah,type LL_RECORD      ;Compute address of proper LL
       mul     ah
       add     ax, [LL_TABOFF]
       xchg    ax, si                 ;Put LL address is SI
       mov     bx,[si].LL_PORT        ;Get pointer to "ports" record
ELSE
       mov     al,byte ptr [scdx]     ;Get port number
       mov     ah,type ports          ;Compute address of proper Ports rec
       mul     ah
       add     ax, [portoff]          ;Add base address of table
       xchg    ax, bx                 ;Put "ports" pointer in BX
ENDIF

       mov     di,[scbx]              ;Get pointer to return area
       mov     es,[sces]

; The following "ret" instruction is really a "jmp" to the value we
; pushed onto the top of the stack

       ret

; Vector table used to get to the correct code based on the length
; in bytes supplied by the user.

do24Vectab label word
       dw      do24Null,do24Sub1        ;0 or 1 bytes
       dw      do24AD,do24Sub1          ;2 or 3 bytes
       dw      do24IB,do24Sub1          ;4 or 5 bytes
       dw      do24OB                   ;6 bytes
       dw      do24IN,do24CN,do24HS     ;7, 8, or 9 bytes
       dw      do24XXon,do24RXon        ;10 or 11 bytes
       dw      do24XXoff,do24RXoff      ;12 or 13 bytes
       dw      do24IF,do24OF,do24Uart   ;14, 15 or 16 bytes

; The following code stores the requested values in reverse order
; so that we can jump into the correct portion of the code based on
; the length value supplied by the caller.

; Uart type

do24Uart:
IFDEF USE_LL_RECORD
       mov     ax,[si].LL_UTYPE
       shr     ax,1
       mov     es:[di].pirec_uart,al
ELSE
       mov     es:[di].pirec_uart,0FFh
ENDIF


; FIFO stuff

do24OF:
IFDEF USE_LL_RECORD
       mov     al,[si].LL_XBURST
       mov     es:[di].pirec_of,al
ELSE
       mov     es:[di].pirec_of,0
ENDIF

do24IF:
IFDEF USE_LL_RECORD
       mov     al,[si].LL_FCR
       mov     ah,0             ;Assume no fifo
       cmp     al,0             ;Are we right?
       jz      do24IFOk         ;YES
       mov     ah,1             ;Assume IF=1
       cmp     al,1             ;Are we right?
       jz      do24IFOk         ;YES
       mov     ah,4             ;Assume IF=4
       cmp     al,41h           ;Are we right?
       jz      do24IFOk         ;YES
       mov     ah,8             ;Assume IF=8
       cmp     al,81h           ;Are we right?
       jz      do24IFOk         ;YES
       mov     al,14            ;Assume IF=14
       cmp     al,0C1h          ;Are we right?
       jz      do24IFOk         ;YES
       mov     ah,0FFh          ;Return bogosity
do24IFOk:
       mov     es:[di].pirec_if,ah
ELSE
       mov     es:[di].pirec_if,0
ENDIF

; Software flow control characters

do24RXoff:
        mov    al,[bx].xoffch
        mov    es:[di].pirec_rxoff,al
do24XXoff:
        mov    al,[bx].xoffch
        mov    es:[di].pirec_xxoff,al
do24RXon:
        mov    al,[bx].xonch
        mov    es:[di].pirec_rxon,al
do24XXon:
        mov    al,[bx].xonch
        mov    es:[di].pirec_xxon,al

; Handshaking information (NOTE: We return the two hardware flow
; control bits twice each so that we don't have to make any changes
; if and when we support separate control of receive and transmit
; flow control)

do24HS:
        mov     al,[bx].ioprot  ; get the protocol byte
        mov     ah, al          ; make a copy   (ax = xxxxRDXX xxxxRDXX)
        shl     ah, 1
        shl     ah, 1           ; ax = xxRDXXxx xxxxRDXX
        and     ax, 300Fh       ; ax = 00RD0000 0000RDXX
        or      al, ah          ; al = 00RDRDXX
        mov     es:[di].pirec_hs,al

; Connection type (L/R/T)

do24CN:
        mov     al,[bx].ioprot
        mov     ah,'L'          ; assume local connect
        and     al, 00110000b   ; extract correct bits
        jz      do24CN_Ok       ; it is local!
        mov     ah,'R'          ; maybe it's remote?
        test    al, 00100000b   ; did we guess right?
        jz      do24CN_Ok       ; yes
        mov     ah,'T'          ; must be terminal mode
do24CN_Ok:
        mov     es:[di].pirec_cn,ah     ; store the result

; Interrupt level

do24IN:
        mov     al,[bx].prtirq
        mov     es:[di].pirec_in,al

; Output buffer size

do24OB:
        mov     ax,[bx].obfsiz
        mov     es:[di].pirec_ob,ax

; Input buffer size

do24IB:
        mov     ax,[bx].ibfsiz
        mov     es:[di].pirec_ib,ax

; Address

do24AD:
        mov     ax,[bx].addr
        mov     es:[di].pirec_ad,ax

; All done

do24Null:
        mov     [sccx], cx              ;Return adjusted value
	ret

	subttl	$serial.sys subroutines
	page
;======================================================================
;
; .func: updflc - update any flow control in use
;
; input:
;	bx -> port table entry
;
; .calls:
; .reads:
; .writes:
;
; .endfn
;================================================================
	assume	cs:code,ds:code,es:nothing,ss:nothing
updflc:
	swprton
	test	[bx].ioprot,003h	; are we using xon/xoff
	jz	updfl2			; jump if no
	cli				; no interuptions
	test	[bx].iopend,001h	; have we sent an xoff
	jz	updfl1			; jump if xoff not yet sent
	and	[bx].iopend,not 001h	; clear the xoff sent
	or	[bx].iopend,020h	; set to send an xon
	mov	dx,[bx].addr		; load port address
	rdlsr				; read the line status register
	test	al,thre
	jz	updflc0
	mov	al,[bx].xonch
	wrtxd
	and	[bx].iopend,not 020h	; show no need to send it again
	jmp	short updfl4
updflc0:
	mov	al,entei		; enable transmitter empty interupts
	enaint				; enable transmitter empty interupts
	jmp	short updfl4
updfl1:
	test	[bx].iopend,010h	; are we waiting to send an xoff
	jz	updfl2			; press onward if no
	and	[bx].iopend,not 010h	; just clear it if not sent
	jmp	short updfl4
updfl2:
	test	[bx].iopend,008h	; is rts off
	jz	updfl3			; jump if no
	mov	al,strts		; set rts
	enamdm				; turn rts back on
	jmp	short updfl4
updfl3:
	test	[bx].iopend,004h	; is dtr off
	jz	updfl4			; exit if no
	mov	al,stdtr		; set dtr
	enamdm				; turn dtr back on
updfl4:
	swprtoff
	sti				; renable interupts
	ret				; return to caller

        subttl get_semaphore - shut out other tasks
        page
;======================================================================
;
; .func: get_semaphore
;
; .calls:
; .reads:
; .writes:
;
; .endfn
;================================================================
	assume	cs:code,ds:code

  IF MOS
sem  db 0                       ; semaphore
  ENDIF

get_semaphore proc near
  IF MOS
gs_10:
       cli                      ; no ints whilst checking
       cmp  [sem],0             ; is semaphore busy?
       mov  [sem],1             ; in any case, set it!
       sti
       jz   gs_99               ; it wasn't busy.  We now own it

       call moswait             ; it was busy.  wait and ...
       jmp  gs_10               ; ... try again

gs_99:
  ENDIF
       ret

get_semaphore  endp

        subttl put_semaphore - allow other tasks to run
        page
;======================================================================
;
; .func: put_semaphore
;
; .calls:
; .reads:
; .writes:
;
; .endfn
;================================================================
	assume	cs:code,ds:code

put_semaphore proc near
  IF MOS
       mov  [sem],0             ; unlock the semaphore
  ENDIF
       ret
put_semaphore endp

               subttl moswait - give up the cpu
               page
;======================================================================
;
; .func: moswait - give up the cpu
;
;
; .calls:
; .reads:
; .writes:
;
; .endfn
;================================================================
	assume	cs:code,ds:nothing,es:nothing,ss:nothing
moswait proc	near
	if	mos			; no int 38's under DOS
	push	ax			; save ax
	push	bx			; save bx
	mov	ah,007h			; mos wait
	mov	al,002h			; wait for timer ticks
	mov	bx,2			; wait for 2 timer ticks
	pushf				; simulate an int
	call	[orig38]		; call int 38
	pop	bx			; restore bx
	pop	ax			; restore ax
	endif
	ret				; return to caller
moswait endp

;======================================================================
;
; .func: settime
;
; get the current time and set si,di and ioprot 080h
; for subsequent time out checks
;
; input	si = timer ticks to wait
;
; .calls:
; .reads:
; .writes:
;
; .endfn
;================================================================
	assume	cs:code,ds:nothing,es:nothing,ss:nothing
settime proc	near
	and	[bx].ioprot,not 080h	; clear waiting rollover flag
	push	ax			; save ax
	push	cx			; and cx
	push	dx			; and dx
	mov	di,0			; initialize timer high
	mov	ah,0			; read the current time
	pushf				; simulate an int
	call	[orig1a]		; get the current time
	add	si,dx			; add ticks to wait to timer low
	adc	di,cx			; add the timer high to timeh
	cmp	di,00018h		; should we wait for a rollover
	jb	st10			; exit if no
	cmp	si,000b0h		; is it beyond date rollover
	jb	st10			; exit if no
	sub	di,00018h		; subtract the rollover
	sub	si,000b0h		; subtract the rollover
	or	[bx].ioprot,080h	; show waiting for a rollover
st10:
	pop	dx			; restore dx
	pop	cx			; and cx
	pop	ax			; and ax
	ret				; return to caller
settime endp

;======================================================================
;
; .func: chktime - check current time against timeout value
;
; cf=1 if time expired
;
; .calls:
; .reads:
; .writes:
;
; .endfn
;================================================================
	assume	cs:code,ds:nothing,es:nothing,ss:nothing
chktime proc	near
	push	ax			; save ax
	push	cx			; and cx
	push	dx			; and dx
	mov	ah,0			; get current time
	pushf				; simulate an int
	call	orig1a			; call the 1a handler
	test	[bx].ioprot,080h	; is a rollover required
	jz	ct10			; jump if no
	cmp	al,0			; did a rollover occur
	je	ct30			; exit if not yet
	and	[bx].ioprot,not 080h	; reset rollover required flag
ct10:
	cmp	cx,di			; check timer high
	jb	ct30			; exit if not time yet
	ja	ct20			; don't check low if greater than
	cmp	dx,si			; check timer low
	jb	ct30			; exit if not time yet
ct20:
	pop	dx			; restore dx
	pop	cx			; and cx
	pop	ax			; and ax
	stc				; show the time has elapsed
	ret				; return to caller
ct30:
	pop	dx			; restore dx
	pop	cx			; and cx
	pop	ax			; and ax
	clc				; show still waiting
	ret				; return to caller
chktime endp


IFDEF   LOG_CALLS
        subttl  LogCalls
        page
;======================================================================
;
; .func: LogCalls - Maintain ring buffer of calls/arguments
;
;       LogCalls entry:     [sc??] is user's registers
;
;               if [scax] = 'DBxx' then
;                   set [scex:scbx] to point to
;                   "log calls control structure" defined below.
;                   return with carry set
;               else
;                   { this is a normal user call that might need to be
;                     logged
;                   }
;                   if we are logging the specified port "[scdx]" and ...
;                           function "[scah]" then
;                       place it in the ring buffer
;                   endif
;                   return with carry clear
;               endif
; .calls:
; .reads:
; .writes:
;
; .endfn
;================================================================
	assume	cs:code,ds:code,es:code,ss:nothing

; The "log calls control structure" consists of the following data items

LC_signature     DB 'LogCalls'
LC_functbl       DB 24 DUP (0)          ; Per-function control flags
LC_porttbl       DB 32 DUP (0)          ; Per-port control flags
LC_insptr        DW LC_buffer           ; Insertion pointer
LC_delptr        DW LC_buffer           ; Deletion pointer
LC_bufptr        DW LC_buffer           ; Top pointer
LC_endptr        DW LC_bufend           ; End-of-buffer pointer
LC_buffer        DW 24*100 DUP (0)      ; Ring buffer itself
LC_bufend label byte                    ; End-of-buffer marker

LogCalls proc	near

        push    ax                      ; Save caller's register

        mov     ax, [scax]               ; Get the function code
        cmp     ah, 0DBh                 ; Is this a LogCalls function?
        jnz     LC_normal                ; NO: See if we should log it

; Return a pointer to the log calls control structure so that task
; code can manipulate it as needed.

        mov     ax, cs
        mov     [sces], ax                      ; segment half
        mov     [scbx], offset LC_signature     ; offset half

; Return with carry set to suppress normal execution of this call

        stc
        pop     ax
        ret

; Handle a normal user function.  Decide whether to log this call and
; if requested then log it.

LC_Normal:
        push    bx                       ; Another reg we'll need

; We have a non-log calls function.  See if this call should be logged

        and     ah, 07Fh                 ; Kill high bit
        cmp     ah, 24                   ; Is it a valid function?
        ja      LC_chkport               ; NO: Log ALL invalid functions!

        mov     bl, ah                   ; Set up to index table
        xor     bh, bh
        cmp     LC_functbl[bx], 0        ; Are we logging this function?
        jz      LC_skipit                ; NO: Don't log it!

LC_chkport:
        mov     bx, [scdx]               ; Get the port #
        and     bx, 07FFFh               ; Zap hi bit
        cmp     bx, [numport]            ; Is it one we know?
        jae     LC_skipit                ; NO: Don't log it!

        cmp     LC_porttbl[bx], 0        ; Are we logging this port?
        jz      LC_skipit                ; NO: Don't log it!

; We are supposed to log this entry.  Do so.

        push    si
        push    di
        push    cx

        lea     si, [scax]               ; First byte to clone
        mov     cx, 12                   ; # of regs to clone
        cld                              ; Work upward

        cli                              ; One at a time please!
        mov     di, [LC_insptr]          ; Get insertion pointer
        lea     ax, [di+24]              ; Point at new location
        cmp     ax, offset LC_bufend     ; Are we off the end?
        jb      LC_notoffend             ; NO
        mov     ax, offset LC_buffer     ; YES: Wrap
LC_notoffend:
        cmp     ax, [LC_delptr]          ; Would we overrun?
        jz      LC_overrun               ; YES!

; ASSERT:   ES:DI -> destination
;           SI    -> [scax]
;           CX    = 12

       mov      [LC_insptr], ax          ; Save updated pointer
       mov      ax,ds                    ; Remember segment value
       push     ss                       ; Source is on stack!
       pop      ds                       ;
       rep      movsw                    ; Stash the entry
       sti                               ; Interrupts are ok now!

       mov      ds,ax                    ; Fix segment register

LC_restore:
       pop      cx
       pop      di
       pop      si

; We are done logging the entry. (or skipped doing so!)

LC_skipit:
        pop     bx
        pop     ax
        clc                             ; Flag it to be processed
        ret

; We had an overun.

LC_overrun:
        mov     [bx],0FFFFh             ; Flag the overrun
        sti                             ; Allow interrupts
        jmp     LC_restore              ; Restore regs and return

LogCalls EndP

ENDIF
