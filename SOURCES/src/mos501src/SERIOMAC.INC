	.XLIST
;-----------------------------------------------------------------------;
; Module: SERIOMAC.INC		SerialIO Macros				;
;-----------------------------------------------------------------------;
; RDG 02/17/89	Added PRTCK macro for SRTERM use to determine if a 	;
;		  station has been initialized and is ready to run.    	;
;-----------------------------------------------------------------------;
; SAH 04/05/90  Added SWPRTON and SWPRTOFF macros for ViewPort so that 	;
;		  int 14 logic can switch stations in and out		;
;-----------------------------------------------------------------------;
; RVA 08/30/91  Disable interrupts during access to the baud    **DLAB**;
;                 rate divisor latch to avoid a potential       **DLAB**;
;                 system hang.                                  **DLAB**;
;************************************************************************
;                                                                      	*
;	$SERIAL.SYS/EMULINK.SYS I/O Macros                             	*
;                                                                      	*
;************************************************************************

SWPRTON	macro				; Switch Port ON
	endm				; mothing for Serial.sys

SWPRTOFF macro				; Switch Port OFF
	 endm				; mothing for Serial.sys

PRTCK	macro				; port verification       	
	endm				; nothing for serial.sys        

; ADDED: 24-Sep-1991 by Bob Ammerman
;
; The following macros were added to make the jmp $+2 after port
; access conditional.  The "jmp $+2" can be safely suppressed by
; the user iff the user knows that a "jmp" instruction will always
; occur before the next I/O operation.
;
;    Note:  1: The default state is POGO ENABLED so as not to break
;              any existing code!
;
;           2: If there is more than one I/O operation in a macro
;              then only the jump after the last one is made
;              conditional!
;
;   Typically these macros would be used like this:
;
;       DISABLE_POGO
;       WRTXD
;       ENABLE_POGO
;       jmp     xxx
;

cpuspeed  dw    30

tickwait   proc near
    push   cx
    mov    cx,[cpuspeed]
    loop   $
    pop    cx
    ret
tickwait   endp


ENABLE_POGO macro
    DO_POGOS=true
endm

DISABLE_POGO macro
    DO_POGOS=false
endm

ENABLE_POGO                             ; turn on POGOS be default!

MAYBE_POGO macro
   IF DO_POGOS eq true
;      JMP  $+2

call  tickwait
   ENDIF
endm

WRTXD	macro				; write transmit data
	out	dx, al			; write al to the transmitter
	MAYBE_POGO                      ; wait for the bus to settle
	endm

RDRXD	macro				; read data from the receiver
	in	al, dx			; read al from the receiver
	MAYBE_POGO                      ; wait for the bus to settle
	endm

;**DLAB**  Warning:  The changes made here to WRDIV and RDDIV should
;**DLAB**            *NOT* be copied into versions of this file that
;**DLAB**            define SWPTRON and SWPTROFF to disable and enable
;**DLAB**            interrupts, respectively.  This is because we
;**DLAB**            would re-enable interrupts in WRDIV, before the
;**DLAB**            SWPTROFF macro was encountered!  **VERY BAD NEWS!!**

WRDIV	macro				; write to the baud rate generator
	push	ax			; save the divisor
	add	dx, lcreg		; add the line control offset
	in	al, dx			; read the line control register
	jmp	$+2			; wait for the bus to settle
	or	al, divla		; set the divisor access latch
        cli                             ;**DLAB** no interrupts
	out	dx, al			; turn it on
	jmp	$+2			; wait for the bus to settle
	sub	dx, lcreg               ; set dx back to the base port
	pop	ax			; restore the count
	push	ax			; save it for exit
	out	dx, al			; set the lsb
	jmp	$+2			; wait for the bus to settle
	add	dx, divlm		; add the msb divisor latch add
	mov	al, ah			; move the msb to al
	out	dx, al			; set the msb
	jmp	$+2			; wait for the bus to settle
;**DLAB** sub	dx, divlm               ; set dx back to the base port
;**DLAB** add	dx, lcreg		; add the line control offset
        add     dx, lcreg-divlm         ;**DLAB** move from "divlm" to "lcreg"
	in	al, dx			; read the line control register
	jmp	$+2			; wait for the bus to settle
	and	al, not divla		; turn off the divisor access latch
	out	dx, al			; turn it off
        sti                             ;**DLAB** interrupts are ok now
	MAYBE_POGO			; wait for the bus to settle
	sub	dx, lcreg               ; set dx back to the base port
	pop	ax			; restore ax
	endm

RDDIV	macro				; read the baud rate generator
	add	dx, lcreg		; add the line control offset
	in	al, dx			; read the line control register
	jmp	$+2			; wait for the bus to settle
        cli                             ;**DLAB** no interrupts
	or	al, divla		; set the divisor access latch
	out	dx, al			; turn it on
	jmp	$+2			; wait for the bus to settle
	sub	dx, lcreg               ; set dx back to the base port
	in	al, dx			; read the lsb
	jmp	$+2			; wait for the bus to settle
	xchg	ah, al			; move the lsb to ah
	add	dx, divlm		; add the msb divisor latch add
	in 	al, dx			; read the msb
	jmp	$+2			; wait for the bus to settle
	xchg	ah, al			; normalize the divisor
;**DLAB** sub	dx, divlm               ; set dx back to the base port
	push	ax			; save the divisor
;**DLAB** add	dx, lcreg		; add the line control offset
        add     dx, lcreg-divlm         ;**DLAB** move from "divlm" to "lcreg"
	in	al, dx			; read the line control register
	jmp	$+2			; wait for the bus to settle
	and	al, not divla		; turn off the divisor access latch
	out	dx, al			; turn it off
        sti                             ;**DLAB** interrupts ok now
	MAYBE_POGO			; wait for the bus to settle
	sub	dx, lcreg               ; set dx back to the base port
	pop	ax			; retrieve the divisor
	endm

WRIER	macro				; write the interupt enable regi
	add	dx, iereg		; add the interupt enable offset
	out	dx, al			; write to the interupt enable re
	MAYBE_POGO			; wait for the bus to settle
	sub	dx, iereg		; set dx back to the base port
	endm

ENAINT	macro				; enable an interupt
	add	dx, iereg		; add the interupt enable offset
	mov	ah, al			; interupt to enable to ah
	in	al, dx			; read the current interupt mask
	jmp	$+2			; wait for the bus to settle
	or	al, ah			; add in the desired interupt
	out	dx, al			; store the new mask
	MAYBE_POGO                      ; wait for the bus to settle
	sub	dx, iereg               ; set dx back to the base port
	endm

DISINT	macro				; disable an interupt
	mov	ah, al			; interupt to disable to ah
	add	dx, iereg               ; add the interupt enable offset
	in	al, dx			; read the current interupt mask
	jmp     $+2			; wait for the bus to settle
	not	ah			; mask of interupts to allow
	and	al, ah			; turn off the specified interupt
	out	dx, al			; set the new interupt mask
	MAYBE_POGO			; wait for the bus to settle
	sub	dx, iereg               ; set dx back to the base port
	endm

RDIIR	macro				; read the interupt identification
	add	dx, iireg		; and the interupt id offset
	in	al, dx			; read the iir
	MAYBE_POGO			; wait for the bus to settle
	sub	dx, iireg		; set dx back to the base port
	endm

WRLCR	macro				; write to Line-Control Register
	add	dx, lcreg               ; add the line control offset
	out	dx, al			; write to the line control reg
	MAYBE_POGO			; wait for the bus to settle
	sub	dx, lcreg		; set dx back to the base port
	endm

RDLCR	macro				; read the Line-Control Register
	add	dx, lcreg               ; add the line control offset
	in	al, dx			; read the line control register
	MAYBE_POGO			; wait for the bus to settle
	sub	dx, lcreg		; set dx back to the base port
	endm

WRMCR	macro				; write the Modem Control Register
	add	dx, mcreg       	; add the modem control offset
	out	dx, al			; write the modem control register
	MAYBE_POGO			; wait for the bus to settle
	sub	dx, mcreg		; set dx back to the base port
	endm

ENAMDM	macro				; turn on a modem signal
	add	dx, mcreg		; add the modem control offset
	mov	ah, al			; signal to turn on to ah
	in	al, dx			; read the current modem signals
	jmp     $+2			; wait for the bus to settle
	or	al, ah			; add in the desired signal
	out	dx, al			; store the new signals
	MAYBE_POGO			; wait for the bus to settle
	sub	dx, mcreg               ; set dx back to the base port
	endm

DISMDM	macro				; turn off a modem signal
	mov	ah, al			; signal to disable to ah
	add	dx, mcreg               ; add the modem control offset
	in	al, dx			; read the current modem signals
	jmp	$+2			; wait for the bus to settle
	not	ah			; mask of signals to allow
	and	al, ah			; turn off the specified signal
	out	dx, al			; store the new set of signals
	MAYBE_POGO			; wait for the bus to settle
	sub	dx, mcreg               ; set dx back to the base port
	endm

RDLSR	macro				; read the line status register
	add	dx, lsreg		; add the line status offset
	in	al, dx			; read the line status
	MAYBE_POGO			; wait for the bus to settle
	sub	dx, lsreg		; set dx back to the base port
	endm

RDMSR	macro				; read the modem status register
	add	dx, msreg		; add the modem status offset
	in	al, dx			; read the modem status
	MAYBE_POGO			; wait for the bus to settle
	sub	dx, msreg		; set dx back to the base port
	endm

;**FOLLOWING MACROS ADDED Sep91 by RVA to SUPPORT **OPT1**/**FIFO**

RDIER   macro                           ; read the interrupt enable reg
        add     dx,iereg
        in      al,dx
        MAYBE_POGO
        sub     dx,iereg
        endm

RDMCR   macro                           ; read the modem control reg
        add     dx,mcreg
        in      al,dx
        MAYBE_POGO
        sub     dx,mcreg
        endm

RDSCR   macro                           ; read the scratch pad register
        add     dx,screg
        in      al,dx
        MAYBE_POGO
        sub     dx,screg
        endm

WRSCR   macro                           ; write the scratch pad register
        add     dx,screg
        out     dx,al
        MAYBE_POGO
        sub     dx,screg
        endm

WRFCR   macro                           ; write the FIFO control register
        add     dx,fcreg
        out     dx,al
        MAYBE_POGO
        sub     dx,fcreg
        endm

;** The following macro isn't used inside of $SERIAL.SYS, and also
;** appears to be broken.  If anybody is using this they are probably
;** in trouble!  (RVA Sep91)

chk16550 macro				;scratch pad register
		
	add	dx,screg		;add scratch pad offset
	mov	al,test450		;set up for a 7fh
	out	dx,al			;send it to the scratch register
	in	al,dx			;then read it back
	sub	dx,screg		;set dx base to base
	cmp	al,test450		;same thing
	jne	tst16550		;if so, it's not an 8250
	mov	ok8250,'Y'		;else it is
	jmp	chk16550d   

tst16550:
	add	dx,iireg		;set for read/write on a 16550
	mov 	al,en14			;set for 14 byte irq
	out	dx,al			;send it out
	in 	al,dx			;get status
	and	al,01100000b
	cmp	al,01100000b		;high bits set?
	je	is16550			;if so, it's a 16550
	mov	ok16450,'Y'		;else it's on a 16450
	jmp	chk16550d
is16550:
	mov	ok16550,'Y'	        ;16550 with buffering set
chk16550d:
	endm

		
	.LIST
