; The following debugs, when enabled, result in characters being sent
; to the video display memory (NOTE: COLOR VIDEO SEGMENT ADDRESS IS
; ASSUMED!!!).

IFDEF   ISR_DEBUG
debugptr        dw      0,0b800h   ; Start in upper left corner of screen

debout_it proc near
      push   es
      push   bx
      les    bx,dword ptr [debugptr]
      mov    es:[bx],ax            ; Display a debug character/attr
      add    bx,2
      cmp    bx,25*80*2            ; Did we run off the end?
      jb     debout_nowrap         ; NO
      mov    bx, 0                 ; YES: Wrap back to the top of screen
debout_nowrap:
      mov    word ptr [debugptr],bx
      pop    bx
      pop    es
      ret
debout_it endp
ENDIF

; NOTE: The following macro has a null body when ISR debugging is
;       disabled!

DEBOUT macro value,attr
IFDEF  ISR_DEBUG
      push   ax
      mov    al,&value
      mov    ah,&attr
      call   debout_it
      pop    ax
ENDIF
endm


;
;************************************************************************
; RDG 04/20/89	Modified ms20, ms30, te10 and te20 so that remote      	* RG9110
; RG9110	  connections no longer default to using RTS/CTS and   	* RG9110
;		  DTR/DSR flow control.                                	* RG9110
;************************************************************************
;

;**OPT1** Entry conditions for each of these interrupt handling
;**OPT1** routines:
;**OPT1**
;**OPT1**       BX = address of "ports" structure
;**OPT1**       DX = io address of serial port chip
;**OPT1**       DI = address of LL_RECORD for this port
;**OPT1**            (only if USE_LL_RECORD is defined!)
;**OPT1**
;**OPT1** On exit:
;**OPT1**
;**OPT1**       BX and DX must be maintained, DI and CX may be
;**OPT1**       trashed.
;**OPT1**

inttbl	dw	modmstat		; modem status change
	dw	txempty			; transmitter empty
	dw	datardy			; data ready
	dw	linestat		; line status change


	subttl	modmstat - a modem status change has occured
	page

;************************************************************************
; 									*
;	A modem status change has occured. Store the current status    	*
;	and restart output if it was suspended waiting for dsr or cts. 	*
;                                                                      	*
;************************************************************************

modmstat label 	near
	RDMSR				; read the modem status register
	mov	[bx].modmst, al		; store the modem status
	test	[bx].ioprot, 000111100b	; are we monitoring modem status
	jnz	ms10			; jump if we need to check futhe
	ret                             ; return to isr loop

ms10:
	mov	ah, [bx].ioprot		; get our protocols
	test	ah, 020h		; are we terminating lost tasks
	jz	ms20			; skip if no
	test	al, carch		; did carrier change
 	jz	ms20			; jump if no
	test	al, carst		; did we lose carrier
	jnz	ms20			; continue if no
	or	[bx].iopend, 040h	; show carrier has been lost
	mov	[bx].kbeflg, 0ffh       ; set so getkeys will see it

ms20:
	test	al, dsrch		; did data set ready change
	jz	ms30			; jump if no
	test	ah, 000000100b		; are we using dtr/dsr         	; RG9110
	jz	ms30			; jump if no
	test	al, dsrst		; is dsr coming high
	jz	ms25			; jump if dsr dropping
	mov	al, entei		; enable transmitter empty inter
	DISINT				; enable transmitter empty inter
	mov	al, entei		; enable transmitter empty inter
	ENAINT				; enable transmitter empty inter
	ret				; return to isr loop

ms25:
	mov	al, entei		; disable transmitter empty inter
	DISINT				; disable transmitter empty inte
	ret				; return to isr loop

ms30:
	test	al, ctsch		; did clear to send change
	jz	ms40			; jump if no
	test	ah, 000001000b		; are we using rts/cts         ; RG9110
	jz	ms40			; jump if no
	test	al, ctsst		; is cts coming high
	jz	ms35			; jump if dsr dropping
	mov	al, entei		; enable transmitter empty inter
	DISINT				; enable transmitter empty inter
	mov	al, entei		; enable transmitter empty inter
	ENAINT				; enable transmitter empty inter
	ret				; return to isr loop

ms35:
	mov	al, entei		; disable transmitter empty inter
	DISINT				; disable transmitter empty inte

ms40:
	ret				; return to isr loop


	subttl	linestat - a line status change has occured
	page

;************************************************************************
; 									*
;	A line status change has occured. Store the current status    	*
;	in the current port structure                                  	*
;                                                                      	*
;************************************************************************

linestat label 	near
	RDLSR				; read the line status register
	and	al, brki+frerr+paerr+overr ; save only the errors
	mov	[bx].linest, al		; store the line status
	test	al, overr               ; did we have a data overrun
	jz	ls10			; exit now if no
	mov	[bx].datovr, 0ffh	; set the data overrun flag

ls10:
	ret				; return to caller


	subttl	txempty - trasnmitter holding register empty
	page

;************************************************************************
; 									*
;	The transmitter holding register is now empty, get the next    	*
;	character in the output buffer and send it to the port.        	*
;                                                                      	*
;************************************************************************


txempty label near
	RDLSR				; read the line status register
	test	al, thre + tsre		; make sure it is ready for data
;	test	al, thre		; make sure it is ready for data
	jnz	te10			; press on if hardware ready
  	  ret				; return to caller (modmstat?)
te10:
        DEBOUT  174,7

;**FBUG** The logic for determining what to send is as follows:
;**FBUG**
;**FBUG**     if we are flow controlled by hardware (RTS or DTR) then
;**FBUG**            we cannot send anything!
;**FBUG**     else if we have a pending Xon or Xoff to send then
;**FBUG**            send it!
;**FBUG**     else if we are flow controlled by Xoff then
;**FBUG**            we cannot send anything
;**FBUG**     else if the buffer is empty then
;**FBUG**            we cannot send anything
;**FBUG**     else
;**FBUG**         if USE_LL_RECORD is defined then
;**FBUG**            send Min(LL_XBURST,obfcnt) chars from buffer
;**FBUG**         else
;**FBUG**            send one character from buffer
;**FBUG**         endif
;**FBUG**     endif
;**FBUG**
;**FBUG** For performance we check the special case of NO flow control at
;**FBUG** all first.

	test	[bx].ioprot, 000001111b	;**FBUG** are we using flow control
	jz	te60			;**FBUG** press onward if no

	mov	ah, [bx].ioprot		;**FBUG** get the flow control config
	test	ah, 000001100b		;**FBUG** any hardware flow control?
	jz	te30			;**FBUG** no, ck for xon/xoff stuff

        mov     al,[bx].modmst          ;**FBUF** get modem status
        test    ah, 00001000b           ;**FBUF** should we check CTS?
        jz      te21                    ;**FBUF** no, we must check DSR

        test    al,ctsst                ;**FBUG** is CTS high?
        ljz      te99                   ;**FBUG** no, we can't send anything

te20:
        test    ah,00000100b            ;**FBUG** should we also check DSR?
        jz      te30                    ;**FBUG** no, check for xon/xoff stuff

te21:
        test    al,dsrst                ;**FBUG** is DSR high?
        jz      te99                    ;**FBUG** no, we can't send anything

;**FBUG** At this point we are sure that we are not hardware flow controlled.
;**FBUG** Our highest priority use of the transmitter should be to send
;**FBUG** any pending Xon/Xoff characters required for receive flow control

te30:
        shr     ah,1                    ;**FBUG** receiver xon/xoff enabled?
        jnc     te40                    ;**FBUG** no, no need to send any

	test	[bx].iopend, 030h       ;**FBUG** xon or xoff pending?
	jz	te40			;**FBUG** no, don't need to send one

        test    [bx].iopend, 020h       ;**FBUG** was it an XON?
        jz      te35                    ;**FBUG** no, must have been XOFF

        DEBOUT  '+',70h

	mov	al, [bx].xonch		;**FBUG** get the xon character
        DISABLE_POGO                    ;**FBUG** suppress JMP $+2
	WRTXD                           ;**FBUG** write it
        ENABLE_POGO                     ;**FBUG**
	and	[bx].iopend, not 020h	;**FBUG** show no need to send it again
	jmp	short te70		;**FBUG** go wrap up the transmit

te35:                                   ;**FBUG** we need an xoff
        DEBOUT  '-',70h
	mov	al, [bx].xoffch		;**FBUG** get the xoff character
        DISABLE_POGO                    ;**FBUG**
	WRTXD                           ;**FBUG** write it
        ENABLE_POGO                     ;**FBUG**
	and	[bx].iopend, not 010h	;**FBUG** show no need to send it again
	or	[bx].iopend, 001h       ;**FBUG** show an xoff sent
	jmp	short te70		;**FBUG** go wrap up the transmit

;**FBUG** At this point we have not sent an Xon/Xoff, and hardware flow
;**FBUG** control is clear.  The only thing that can stop us from sending
;**FBUG** data is software flow control.

te40:
        shr     ah,1                    ;**FBUG** doing xmitter xon/xoff?
        jnc     te60                    ;**FBUG** no, we can send real stuff

	test	[bx].iopend, 002h       ;**FBUG** have we received an xoff
	jnz	te99			;**FBUG** yes, can't send now

;**FBUG** At this point all flow control requirements have been met, and
;**FBUG** we are ready to ship out data from the ring buffer, if there
;**FBUG** is any.  If we are in $SERIAL.SYS/EMULINK.SYS then we compute
;**FBUG** the number of characters to send as:
;**FBUG**
;**FBUG**          Min(ports.obfcnt, LL_RECORD.LL_XBURST)
;**FBUG**
;**FBUG** Otherwise we send just one character.

te60:
     IFDEF USE_LL_RECORD
        mov     cl,[di].LL_XBURST       ;**FBUG** max # to send
        mov     ch, 0                   ;**FBUG** zap hi half

        cmp     cx,[bx].obfcnt          ;**FBUG** do we have that many?
        jbe     te61                    ;**FBUG** yes, we can send 'em

        mov     cx,[bx].obfcnt          ;**FBUG** no, get number really there
        jcxz    te70                    ;**FBUG** nothing to send, turn off

; ASSERT:  cx is # of chars are are going to send

te61:
        sub     [bx].obfcnt,cx          ;**FBUG** remove from pending count

     ELSE
        cmp     [bx].obfcnt, 0          ;**FBUG** anything to send?
        jz      te70                    ;**FBUG** NO
        dec     [bx].obfcnt             ;**FBUG** one less waiting
     ENDIF

        mov     si,[bx].obfget          ;**FBUG** get far pointer ...
        mov     es,[bx].obfseg          ;**FBUG** ...to output buffer
        mov     di, [bx].obfsiz         ;**FBUG** get end-of-buffer offset

; ASSERT:
;        es:si is pointer to character to be sent
;        cx    is number of characters to send (if LL_TABLE defined,
;              otherwise we are sending exactly one character)
;        di    is end-of-buffer offset

te62:                                   ;**FBUG**
	mov	al, es:[si]		;**FBUG** get the character
        DEBOUT  AL,7
        DISABLE_POGO                    ;**FBUG** suppress JMP $+2
	WRTXD                           ;**FBUG** write it
        ENABLE_POGO                     ;**FBUG**
        inc     si                      ;**FBUG** point to next character

        cmp     si,di                   ;**FBUG** time to wrap?
        jae     te68                    ;**FBUG** yes, go do the wrapping

    IFDEF USE_LL_RECORD
        loop    te62                    ;**FBUG** no, process remaining chars
    ENDIF
te63:                                   ;**FBUG**
        mov     [bx].obfget,si          ;**FBUG** save updated pointer
te65:
        DEBOUT  175,7
        cmp     [bx].obfcnt, 0          ;**FBUG** did we empty it out?
        jz      te70                    ;**FBUG** yes, go shut down
te99:
        ret                             ;**FBUG** no, all done!

te68:                                   ;**FBUG**
        mov     si, 0                   ;**FBUG** reset the pointer
    IFDEF USE_LL_RECORD
        loop    te62                    ;**FBUG** process remaining chars
    ENDIF
        jmp     te63                    ;**FBUG** ran out of stuff to do!

te70:                                   ;**FBUG**
	mov	al, entei		;**FBUG** disable transmitter empty interupt
	DISINT				;**FBUG** disable transmitter empty interupt
        ret


	subttl	datardy - Data Ready
	page

;************************************************************************
; 									*
;	A character is ready at the receiver, get it from the 8250     	*
; 	and store it int the input buffer                              	*
;                                                                      	*
;************************************************************************

datardy label near

;**FIFO** If we are monitoring carrier status and the carrier is not active
;**FIFO** or we previously lost it then ignore everything that comes in

        DEBOUT  243,0Fh
        test    [bx].ioprot, 00110000b      ;**FIFO** Monitoring carrier?
        jz      dr10                        ;**FIFO** NO: Don't check it
        test    [bx].modmst, carst          ;**FIFO** Is carrier there?
        jz      dr05                        ;**FIFO** NO: Ignore all chars
        test    [bx].iopend, 40h            ;**FIFO** Previously lost it?
        jz      dr10                        ;**FIFO** NO: Keep chars

;**FIFO** We need to ignore everything that comes in because we are
;**FIFO** monitoring the carrier and the carrier is either absent, or
;**FIFO** else was previously lost.

dr05:
        RDLSR                   ;**FIFO** Get line status
        test    al, drdy        ;**FIFO** Any character(s) waiting?
        jz      dr08            ;**FIFO** NO: Ok to exit
        DISABLE_POGO            ;**FIFO** Don't generate "jmp $+2"
        RDRXD                   ;**FIFO** Read and ignore a character
        ENABLE_POGO             ;**FIFO**
        jmp     dr05            ;**FIFO** Flush everything that's there
dr08:
        ret                     ;**FIFO** Back to polling loop

;**FIFO** Either we are not monitoring carrier, or else we have a valid
;**FIFO** carrier.  We really want to process the character(s) received.

dr10:
        mov     si, [bx].ibfsiz         ;**FIFO** Offset just beyond buffer

	mov	cx, si                  ;**FIFO** Compute space left...
        sub     cx, [bx].ibfcnt         ;**FIFO** ...in the buffer

        mov     es, [bx].ibfseg         ;**FIFO** Get full pointer to...
        mov     di, [bx].ibfput         ;**FIFO** ...input buffer

;**FIFO**  At this point:
;**FIFO**          si points just beyond the ring buffer
;**FIFO**          cx is the number of bytes of space available in the buffer
;**FIFO**          es:di points to the insertion point in the buffer

        test    [bx].ioprot,00000010b  ;**FIFO** Do we need to check for Xon/Xoff
        ljnz    dr50                   ;**FIFO** No: Cannot use fastest code

;**FIFO** Since we don't need to check for Xon/Xoff we can just grab
;**FIFO** bytes until the ring buffer is full.

dr20:
        RDLSR                           ;**FIFO** Get line status
        test    al, drdy                ;**FIFO** Any char(s) waiting?
        jnz    rsr02
        jmp    dr40
;        jz     dr40                     ;**FIFO** No: See if time to set flow
                                        ;**FIFO** ...control
rsr02:
        DISABLE_POGO                    ;**FIFO** Suppress "jmp $+2"
        RDRXD                           ;**FIFO** Get the character
        ENABLE_POGO                     ;**FIFO**

        jcxz    dr30                    ;**FIFO** We have a buffer overrun

        stosb                           ;**FIFO** Put it in buffer

        DEBOUT  AL,0Fh

        inc     [bx].ibfcnt             ;**FIFO** One more is there
        mov     [bx].kbeflg, 0ffh       ;**FIFO** Buffer isn't empty
        dec     cx                      ;**FIFO** Room for one less

        cmp     di, si                  ;**FIFO** Is it time to wrap?
        jb      dr20                    ;**FIFO** NO: Get next char, if any
        xor     di,di                   ;**FIFO** Wrap to start of buffer
        jmp     dr20                    ;**FIFO** Get next char, if any

;**FIFO** We have a buffer overrun.  We use the following code whether
;**FIFO** or not we are checking for Xon/Xoff in incoming data because
;**FIFO** we hopefully very seldom use it.  Note that we have already
;**FIFO** read the character that caused the overrun, but there may be
;**FIFO** other characters present in the FIFO to be processed!

dr30:
	or      [bx].linest, overr	;**FIFO** Flag the overrun
	mov	[bx].bufovr, 0ffh	;**FIFO** Flag type of overrun

;**FIFO** Check for a received flow control character if appropriate

dr32:
        test    [bx].ioprot, 00000010b  ;**FIFO** Should we check Xon/Xoff?
        jz      dr35                    ;**FIFO** NO

        cmp     al, [bx].xoffch         ;**FIFO** Is it an XOff?
        jne     dr33                    ;**FIFO** No: Check for Xon

;**FIFO** We have an XOff, shut down the transmitter

        or	[bx].iopend, 002h       ;**FIFO** Yes: show waiting for an xon
	mov	al, entei		;**FIFO** disable transmitter empty...
	DISINT				;**FIFO** ...empty interrupt
        jmp     dr35

;**FIFO** Check for an Xon.  Only turn on the transmitter if we recevied
;**FIFO** an Xon when we were expecting one.

dr33:
	test	[bx].iopend, 002h	;**FIFO** Are we waiting for an Xon?
	jz	dr35			;**FIFO** No: ignore it
	cmp	al, [bx].xonch		;**FIFO** Is it an Xon?
	jne	dr35			;**FIFO** No: ignore it
	and	[bx].iopend, not 002h	;**FIFO** Clear the xoff state
	mov	al, entei		;**FIFO** Enable transmitter...
	DISINT				;**FIFO** ...empty interrupts
	mov	al, entei		;**FIFO** Enable transmitter...
	ENAINT				;**FIFO** ...empty interrupts

dr35:

;**FIFO** Before returning from the overrun we better check for any
;**FIFO** other characters in the receiver FIFO.  Although this is
;**FIFO** required for FIFO operations, it doesn't hurt on a non-FIFO
;**FIFO** chip, and may occasionally help us to save a receive interrupt.

        RDLSR                           ;**FIFO** Get line status
        test    al, drdy                ;**FIFO** Any char(s) waiting?
        jz      dr40                    ;**FIFO** NO: See if we should...
                                        ;**FIFO** ...set flow control

        DISABLE_POGO                    ;**FIFO** Suppress "jmp $+2"
        RDRXD                           ;**FIFO** Get the next inputchar
        ENABLE_POGO                     ;**FIFO**
        jmp     dr32                    ;**FIFO** Check for flow control

;**FIFO** We have emptied out the FIFO.  We may have filled the ring buffer
;**FIFO** past the point where we should adjust the flow control.  If this
;**FIFO** is so, then do so!

dr40:
        mov     [bx].ibfput, di         ;**FIFO** Save updated pointer

;**FIFO** If no flow control protocols are enabled then we can skip
;**FIFO** all the flow control logic.

        mov     cl,[bx].ioprot          ;**FIFO** Get enabled protocols
        and     cl,00001101b            ;**FIFO** Extract perinent bits
;        jz      dr49                    ;**FIFO** No flow control enabled
        jnz     rsr01
        jmp     dr49
rsr01:
        DEBOUT  'A',8Fh
        DEBOUT  CL,87h

;**FIFO** Since we very seldom need to flow control incoming data
;**FIFO** (because task level code is hopefully stripping the ring
;**FIFO** buffer quickly enough that keep the ring buffer mostly
;**FIFO** empty most of the time) we avoid checking the flow control
;**FIFO** details if the ring buffer is less than half full (which
;**FIFO** should be the case almost all of the time).

        mov     di, [bx].ibfsiz         ;**FIFO** Get the buffer size
        shr     di,1                    ;**FIFO** Compute halfway point
        cmp     di, [bx].ibfcnt         ;**FIFO** At halfway point yet?
        ja      dr49                    ;**FIFO** NO: Not time to flow-cntrl

        DEBOUT  'B',8Fh

;**FIFO** If all the flow controls that are enabled are already active
;**FIFO** then we don't need to check any more details.  The enabled
;**FIFO** flow controls are in CL

        mov     ch, [bx].iopend         ;**FIFO** Get active flow controls
        DEBOUT  ch,87h
        not     ch                      ;**FIFO** A 1-bit means inactive
        and     ch, cl                  ;**FIFO** A 1-bit means we need to...
                                        ;**FIFO** ...activate
        jz      dr49                    ;**FIFO** All are already active

        DEBOUT  'C',8Fh
        DEBOUT  ch,87h

;**FIFO** We know that we have at least one currently inactive, but
;**FIFO** enabled, flow control.  If the buffer is less than 3/4 full
;**FIFO** then we still don't want to active flow control.

        shr     di, 1                   ;**FIFO** ibfsiz div 4
        add     di, [bx].ibfcnt         ;**FIFO** Add current count in buffer
        jc      dr42                    ;**FIFO** Since (ibfsiz/4)+ibfcnt
                                        ;**FIFO** > 65536, it MUST be >
                                        ;**FIFO** ibfsiz!
        cmp     di, [bx].ibfsiz         ;**FIFO** Time to flow?
        jbe     dr49                    ;**FIFO** Not yet

        DEBOUT  'D',8Fh

;**FIFO** We have to set one or more types of flow control as outlined
;**FIFO** by the value in AH.  Indicate that they have been set in the
;**FIFO** "iopend" byte, then actually issue them.

dr42:
        DEBOUT  ch, 87h
        or      [bx].iopend, ch         ;**FIFO** Flag 'em as done

        test    ch, 00000001b           ;**FIFO** Send an XOff?
        jz      dr44                    ;**FIFO** NO
           DEBOUT 'E',8Fh
	   or	[bx].iopend, 010h	;**FIFO** Show we want to send an xoff
	   mov	al, entei               ;**FIFO** Enable transmitter...
	   DISINT			;**FIFO** ...empty interrupt
	   mov	al, entei               ;**FIFO** Enable transmitter...
	   ENAINT			;**FIFO** ...empty interrupt
dr44:

        test    ch, 00000100b           ;**FIFO** Turn off DTR?
        jz      dr45                    ;**FIFO** NO
  	  mov	al, stdtr		;**FIFO** We want to turn off DTR
	  DISMDM			;**FIFO**
dr45:

        test    ch, 00001000b           ;**FIFO** Turn off RTS?
        jz      dr46                    ;**FIFO** NO
          mov   al, strts               ;**FIFO** We want to turn off RTS
          DISMDM
dr46:

;**FIFO** All flow control operations are complete. We can return to the
;**FIFO** ISR loop.

dr49:
        DEBOUT   242,0Fh
        ret                             ;**FIFO**

;**FIFO** The following code is VERY SIMILAR to the code at "dr20" above.
;**FIFO** It is coded as a seperate case to optimize the case of no input
;**FIFO** flow control checking at "dr20".  This code does have to check
;**FIFO** for Xon/Xoff in the incoming data stream.

dr50:
        RDLSR                           ;**FIFO** Get line status
        test    al, drdy                ;**FIFO** Any char(s) waiting?
        ljz     dr40                    ;**FIFO** No: See if time to set flow
                                        ;**FIFO** ...control

        RDRXD                           ;**FIFO** Get the character

	cmp	al, [bx].xoffch		;**FIFO** Is it an Xoff?
	jne	dr53			;**FIFO** NO
	or	[bx].iopend, 002h       ;**FIFO** Show waiting for an Xon
        DEBOUT  '|',70h
	mov	al, entei		;**FIFO** Disable transmitter...
	DISINT				;**FIFO** ...empty interrupt
	jmp     dr50                    ;**FIFO** Look for more characters

dr53:
	test	[bx].iopend, 002h	;**FIFO** Are we waiting for an Xon
	jz	dr55			;**FIFO** NO: Stuff this char...
                                        ;**FIFO** ...even if its an xon

	cmp	al, [bx].xonch		;**FIFO** Is it an Xon?
	jne	dr55			;**FIFO** NO: Go store the character
	and	[bx].iopend, not 002h	;**FIFO** Clear the xoff state

        DEBOUT  '*',70h
	mov	al, entei		;**FIFO** Enable transmitter...
	DISINT				;**FIFO** ...empty interupts
	mov	al, entei		;**FIFO** Enable transmitter...
	ENAINT				;**FIFO** ...empty interupts
	jmp     dr50                    ;**FIFO** Look for more characters

dr30pogo:				;**FIFO** "jcxz" below cannot ...
	jmp	dr30			;**FIFO** the "dr30" label

dr55:
        jcxz    dr30pogo                ;**FIFO** We have a buffer overrun

        stosb                           ;**FIFO** Put it in buffer

        DEBOUT  AL,0Fh
        inc     [bx].ibfcnt             ;**FIFO** One more is there
        mov     [bx].kbeflg, 0ffh       ;**FIFO** Buffer isn't empty
        dec     cx                      ;**FIFO** Room for one less

        cmp     di, si                  ;**FIFO** Is it time to wrap?
	jb	dr50
        xor     di,di                   ;**FIFO** Wrap to start of buffer
        jmp     dr50                    ;**FIFO** Get next char, if any

