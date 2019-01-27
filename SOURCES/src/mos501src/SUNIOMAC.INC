	.XLIST
;-----------------------------------------------------------------------;
; Module: SUNIOMAC.INC		SunRiver SerialIO Macros		;
;-----------------------------------------------------------------------;
; SAH 04/05/90  Added SWPRTON and SWPRTOFF macros for ViewPort so that 	;
;		  int 14 logic can switch stations in and out		;
;-----------------------------------------------------------------------;

;************************************************************************
;                                                                      	*
;	SRTERM.SYS (SunRiver EGA Station) Serial IO Macros		*
;                                                                      	*
;************************************************************************

SUNMACRO=true

ENABLE_POGO macro
    DO_POGOS=true
endm

DISABLE_POGO macro
    DO_POGOS=false
endm

ENABLE_POGO                             ; turn on POGOS be default!

MAYBE_POGO macro
   IF DO_POGOS eq true
      JMP  $+2
   ENDIF
endm


SWPRTON	macro				; Switch Port ON
	endm				; mothing for srterm.sys

SWPRTOFF macro				; Switch Port OFF
	 endm				; mothing for srterm.sys

PRTCK	macro				; port verification
	call	sckport 		; call routine to check if port ONLINE
	jz	badfn			; if not online indicate badfn
	endm


SRstart macro
	push	si
	push	es
	mov	es,cs:[WorkMap] 	; access mapping area
	mov	si,dx			; place accessable variable
	endm

SRfinish macro
	pop	es
	pop	si
	endm

SRoutal macro
	mov	byte ptr es:[si],al
	endm

SRinal	macro
	mov	al,byte ptr es:[si]
	endm

WRTXD	macro				; write transmit data
	SRstart
	SRoutal 			; write al to the transmitter
	SRfinish
	endm

RDRXD	macro				; read data from the receiver
	SRstart
	SRinal				; read al from the receiver
	SRfinish
	endm

WRDIV	macro				; write to the baud rate generator
	SRstart
	push	ax			; save the divisor
	add	si, lcreg		; add the line control offset
	SRinal				; read the line control register
	or	al, divla		; set the divisor access latch
	SRoutal 			; turn it on
	sub	si, lcreg		; set dx back to the base port
	pop	ax			; restore the count
	push	ax			; save it for exit
	SRoutal 			; set the lsb
	add	si, divlm		; add the msb divisor latch add
	mov	al, ah			; move the msb to al
	SRoutal 			; set the msb
	sub	si, divlm		; set dx back to the base port
	add	si, lcreg		; add the line control offset
	SRinal				; read the line control register
	and	al, not divla		; turn off the divisor access latch
	SRoutal 			; turn it off
	pop	ax			; restore ax
	SRfinish
	endm

RDDIV	macro				; read the baud rate generator
	SRstart
	add	si, lcreg		; add the line control offset
	SRinal				; read the line control register
	or	al, divla		; set the divisor access latch
	SRoutal 			; turn it on
	sub	si, lcreg		; set dx back to the base port
	SRinal				; read the lsb
	xchg	ah, al			; move the lsb to ah
	add	si, divlm		; add the msb divisor latch add
	SRinal				; read the msb
	xchg	ah, al			; normalize the divisor
	sub	si, divlm		; set dx back to the base port
	push	ax			; save the divisor
	add	si, lcreg		; add the line control offset
	SRinal				; read the line control register
	and	al, not divla		; turn off the divisor access latch
	SRoutal 			; turn it off
	pop	ax			; retrieve the divisor
	SRfinish
	endm

WRIER	macro				; write the interupt enable regi
	SRstart
	add	si, iereg		; add the interupt enable offset
	SRoutal 			; write to the interupt enable re
	sub	si, iereg		; set dx back to the base port
	SRfinish
	endm

ENAINT	macro				; enable an interupt
	SRstart
	add	si, iereg		; add the interupt enable offset
	mov	ah, al			; interupt to enable to ah
	SRinal				; read the current interupt mask
	or	al, ah			; add in the desired interupt
	SRoutal 			; store the new mask
	SRfinish
	endm

DISINT	macro				; disable an interupt
	SRstart
	mov	ah, al			; interupt to disable to ah
	add	si, iereg		; add the interupt enable offset
	SRinal				; read the current interupt mask
	not	ah			; mask of interupts to allow
	and	al, ah			; turn off the specified interupt
	SRoutal 			; set the new interupt mask
	SRfinish
	endm

RDIIR	macro				; read the interupt identification
	SRstart
	add	si, iireg		; and the interupt id offset
	SRinal				; read the iir
	SRfinish
	endm

WRLCR	macro				; write to Line-Control Register
	SRstart
	add	si, lcreg		; add the line control offset
	SRoutal 			; write to the line control reg
	SRfinish
	endm

RDLCR	macro				; read the Line-Control Register
	SRstart
	add	si, lcreg		; add the line control offset
	SRinal				; read the line control register
	SRfinish
	endm

WRMCR	macro				; write the Modem Control Register
	SRstart
	add	si, mcreg		; add the modem control offset
	SRoutal 			; write the modem control register
	SRfinish
	endm

ENAMDM	macro				; turn on a modem signal
	SRstart
	add	si, mcreg		; add the modem control offset
	mov	ah, al			; signal to turn on to ah
	SRinal				; read the current modem signals
	or	al, ah			; add in the desired signal
	SRoutal 			; store the new signals
	SRfinish
	endm

DISMDM	macro				; turn off a modem signal
	SRstart
	mov	ah, al			; signal to disable to ah
	add	si, mcreg		; add the modem control offset
	SRinal				; read the current modem signals
	not	ah			; mask of signals to allow
	and	al, ah			; turn off the specified signal
	SRoutal 			; store the new set of signals
	SRfinish
	endm

RDLSR	macro				; read the line status register
	SRstart
	add	si, lsreg		; add the line status offset
	SRinal				; read the line status
	SRfinish
	endm

RDMSR	macro				; read the modem status register
	SRstart
	add	si, msreg		; add the modem status offset
	SRinal				; read the modem status
	SRfinish
	endm

	.LIST
