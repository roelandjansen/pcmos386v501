;------------------------------ Revision Log ---------------------------;
; BWR	11/30/89	Marked messages for foreign language 		;
;			translation.					;
;-----------------------------------------------------------------------;
; SAH   01/16/90	Changes for MOSADM HOLD [task] LPTX OFF		;
;-----------------------------------------------------------------------;
; SAH   10/29/90	Move GetMDev to here for MOSADM EMSLIMIT 	;
;			additions.					;
;-----------------------------------------------------------------------;
; BWR   04/19/91        Added new code to implement MOS HOLD COM (and   ;
;                       the MOSADM flavor of the same).  Also fixed     ;
;                       MOSADM HOLD task LPT which never worked right.  ;
;-----------------------------------------------------------------------;
; SAH   08/31/92	corrections for HOLD COMx, assure that defaults	;
;			is 0, when disable.				;
;-----------------------------------------------------------------------;



;--------------------------------- Macros ------------------------------;
store_hold_time         macro

        push    ax
        lea     bx, hld_sec + 3
        xor     dx, dx
        mov     cx, 4
        call    bintodec
        pop     ax

        endm
;-------------------------------------------------------------------------

;	MOS.COM and MOSADM.COM common routines

;	SYS = 1 if MOS.COM
;	ADM = 1 if MOSADM.COM

memman	db    '$$MEMDEV',0

task_ID         dw      0
hld_time_bad    db      'invalid hold time $          ' ;@@XLAT

hld_lpt_num     db      0
hld_lpt_set	db      'LPTx HOLD time set to $         '      ;@@XLAT
hld_lpt_msg	db      'LPTx reserved for $             '      ;@@XLAT
hld_lpt_lis	db      'LPTx is $        '                     ;@@XLAT
invalid_lpt     db      'Can only HOLD for LPT1 - LPT3        ' ;@@XLAT
                db      13, 10, '$'

hld_com_num     db      0
hld_com_set	db      'COM   HOLD time set to $        '      ;@@XLAT
hld_com_msg	db      'COM   reserved for $            '      ;@@XLAT
hld_com_lis	db      'COM   is $       '                     ;@@XLAT
invalid_com     db      'Can only HOLD for COM1 - COM24       ' ;@@XLAT
                db      13, 10, '$'

hldrtsk         db      'currently in use by task '
ht_num          db      '___$'
hld_sec  	db	'   0 seconds.            '             ;@@XLAT
                db      13, 10, '$'
hld_rel_msg     db      'released         '                     ;@@XLAT
                db      13, 10, '$'
unknown_task	db	'Unknown task.        '                 ;@@XLAT
                db      13, 10, '$'
;
;  Process MOS HOLD command.
;
holdfun:
;
;  Obtain access to the TCB for either the current task or the one
;  requested. (In the case of the MOSADM command).
;
	if	SYS
		call	getcurtcb	; address task variables
		ASSUME	es:tcb
	endif

	if	ADM
		call	nextopnd	; get task number
                ljz     erropnd         ; Operand error.
                mov     bx, si
                call    dec2bin
                ljc     erropnd
		mov	bx, ax
		mov	ah, 4
		int	SERVICES	; MOS get TCB call
                jnc     @F
		lea	dx, unknown_task        ; give unknown task error
		jmp	errexit
@@:
		ASSUME	es:tcb
	endif
;
;  Dispatch to either the COM HOLD or the LPT HOLD logic.
;
        mov     ax, tcbid       ; Store the taskid locally.
        mov     task_ID, ax
	call	nextopnd        ; Get next operand.
        ljz     erropnd
        mov     ax, si          ; Save pointer to it.
        lea     di, comtest     ; Is the device COMx ?
        call    testdev
        or      si, si
        ljnz    COM_hold        ; If so, go process it.
        mov     si, ax          ; Get pointer to operand back.
	lea	di, lpttest     ; Is the device LPTx ?
	call	testdev
	or	si, si		; abort if not LPTx
        ljz     erropnd
;
;--------------------------------------------------------------------------
;  This section deals with the MOS HOLD LPTx command.
;--------------------------------------------------------------------------
;
;  First validate the LPT port argument.
;
LPT_hold:
        xor     ah, ah
        mov     al, [si]                ;Fill display strings.
        mov     hld_lpt_set[3], al
        mov     hld_lpt_msg[3], al
        mov     hld_lpt_lis[3], al
        sub     al, '1'
        lea     dx, invalid_lpt
        cmp     ax, 0
        ljl     errexit
        cmp     ax, 2
        ljg     errexit
;
;  How long does the user want to hold the LPT port?
;
        mov     hld_lpt_num, al         ;Save LPT port number.
        call    nextopnd                ;Get next command-line operand.
        ljz     lpt_hold_hold           ;If none, display current one.
;
;  Is the user trying to specify MOS HOLD LPTx OFF?
;
        mov     al, [si]
        and     al, 0DFh                ;Convert to upper case.
        cmp     al, 'O'
        ljne    lpt_hold_set            ;Go set a new hold value.
        mov     ax, [si+1]
        and     ax, 0DFDFh              ;Convert to upper case.
        cmp     ax, 'FF'
        ljne    erropnd                 ;O?? is a bad operand.
;
;   The user specified to turn off the hold on the LPT port.
;   First, check to see if it is in use by another task.  If it
;   is, then the hold cannot be removed.
;
lpt_hold_off:
        lea     dx, hld_lpt_lis         ;Write first part of message.
        call    writemsg
;
;   Cancel reservation of LPT port if this task has it.
;
        xor     bh, bh
        mov     bl, hld_lpt_num
        shl     bx, 1
        push    tcbhold[bx]
        mov     tcbhold[bx], 0
        call    Reserve_LPT_port
        pop     tcbhold[bx]
        jnc     lho_OK
;
;   This task doesn't own the port.  Give the user an error.
;
        lea     bx, ht_num+2
        mov     cx, 3
        xor     dx, dx
        call    bintodec
        lea     dx, hldrtsk
        jmp     fundone
;
;  The reservation has been cancelled.
;
lho_OK:
        lea     dx, hld_rel_msg
        jmp     fundone
;
;  The user wants to set the reservation time.
;
lpt_hold_set:
        mov     bx, si
        call    dec2bin
        ljc     erropnd
	cmp	ax, 3600		;Limit to 3600 seconds. (Why?)
        jbe     lhs_000
	lea	dx, hld_time_bad	; give time error message
	jmp	errexit
;
;  Write the new set time into the TCB.
;
lhs_000:
        store_hold_time
        mov     bx, 182                 ;Convert value to ticks for TCB.
        mul     bx
        div     wordten

        xor     bh, bh                  ;Compute index value in BX.
        mov     bl, hld_lpt_num
        shl     bx, 1
        mov     tcbhold[bx], ax         ;Save the value in the TCB.

	lea	dx, hld_lpt_set	        ;Display LPT set.
	call	writemsg
	lea	dx, hld_sec
	jmp	fundone
;
;  The user has specified MOS HOLD LPTx without any arguments.  This
;  means to take the hold time and actually reserve the LPT port
;  for the specified task.
;
lpt_hold_hold:
;
;   Attempt to reserve the LPT port.
;
        call    Reserve_LPT_port
        jnc     lhh_OK
;
;  Sorry.  The port is already in use by someone else.
;
        lea     bx, ht_num+2
        mov     cx, 3
        xor     dx, dx
        call    bintodec
        lea     dx, hld_lpt_lis
        call    writemsg
        lea     dx, hldrtsk
        jmp     fundone
;
;  The reservation was successful.
;
lhh_OK:
        xor     bh, bh
        mov     bl, hld_lpt_num
        shl     bx, 1
        mov     ax, tcbhold[bx]         ;Save the HOLD counter.
        xor     dx, dx
        mul     wordten
        mov     bx, 182
        div     bx
        store_hold_time

        lea     dx, hld_lpt_msg
        call    writemsg
        lea     dx, hld_sec
        jmp fundone

;---------------------------------------------------------------------------
; Subroutine Reserve_LPT_port
;
;  This routine checks to see if the selected LPT port is presently 
;  reserved by another task.  If not, it is reserved for the selected
;  task.
;
;       Input:  DS:hld_lpt_num          Reference to which LPT port to
;                                       be checked.
;
;       Output: AX                      Task currently holding the port
;                                       if CF set.
;
;       Notes:  ES remains pointing at TCB, DS is moved to the SCB
;               during this routine.
;
;---------------------------------------------------------------------------
Reserve_LPT_port        proc    near

        push    ds
	mov	ah, 26h         ;Use new call (4.1) to services.
	int	SERVICES
        mov     ds, dx          ;Load DS with the selector.
	ASSUME	ds:scbs
        cli                     ;No interrupts while we do this.
;
;   If the owner of the LPT port is still undefined or it belongs to
;   the specified task, then the HOLD can be cleared.
;
        xor     bh, bh          ;Calculate index into SCB LPT table.
        mov     bl, hld_com_num
        mov     ax, bx          ;SCB entries are six bytes long for LPT's.
        shl     bx, 1
        shl     ax, 1
        shl     ax, 1
        add     bx, ax
        cmp     scbhldtask[bx], -1
        je      rlp_OK
        mov     ax, task_ID
        cmp     scbhldtask[bx], ax
        je      rlp_OK
;
;   The port is held by someone else right now.  Has the timer expired yet?
;
        mov     ax, word ptr scbhldtick[bx]
        sub     ax, scbtimer
        mov     ax, word ptr scbhldtock[bx]
        sbb     ax, scbtimerh
        jb      rlp_OK                                  ;Timed out.
;
;   The port has not timed out return an error status indicating that
;   fact.
;
        mov     ax, scbhldtask[bx]
        pop     ds
        stc
        sti                                     ;Interrupts back on.
        ret
;
;   The port is available to be reserved.  Do it.
;
rlp_OK:
        push    bx                      ;Save the SCB index.
        xor     bh, bh
        mov     bl, hld_com_num
        shl     bx, 1
        cmp     tcbhold[bx], 0
        je      rlp_REL
        mov     ax, task_ID
        mov     scbhldtask[bx], ax
        mov     ax, tcbhold[bx]
        pop     bx                      ;Get the SCB index back.
        add     ax, scbtimer
        mov     scbhldtick[bx], ax
        mov     ax, scbtimerh
        adc     ax, 0
        mov     scbhldtock[bx], ax
        jmp short rlp_DONE
;
;   The reservation time was 0, so just release the port.
;
rlp_REL:
        mov     scbhldtask[bx], -1
        pop     bx                      ;Get the SCB index back.
        mov     scbhldtick[bx], 0
        mov     scbhldtock[bx], 0
;
;   The reservation process is complete.
;
        ASSUME  ds:mainseg

rlp_DONE:
        pop     ds
        clc
        sti                             ;Interrupts back on.
        ret

Reserve_LPT_port        endp

;--------------------------------------------------------------------------
;  This section deals with the MOS HOLD COMx command.
;--------------------------------------------------------------------------
;
;  First validate the COM port argument.
;
COM_hold:
        mov     bx, si
        call    dec2bin
        ljc     erropnd                 ;If not a numeric, error out.
        lea     dx, invalid_com
        cmp     ax, 1
        ljl     errexit
        cmp     ax, 24
        ljg     errexit
;
;  Write the COM port name into the display strings.
;
CH_1:
        xor     dx, dx
        cmp     ax, 10
        jb      CH_2
        mov     cx, 2
        lea     bx, hld_com_set+4       ;Double digit COM numbers.
        call    bintodec
        lea     bx, hld_com_msg+4
        call    bintodec
        lea     bx, hld_com_lis+4
        call    bintodec
        jmp short CH_3
CH_2:
        mov     cx, 1
        lea     bx, hld_com_set+3       ;Single digit COM numbers.
        call    bintodec
        lea     bx, hld_com_msg+3
        call    bintodec
        lea     bx, hld_com_lis+3
        call    bintodec
CH_3:
;
;  How long does the user want to hold the COM port?
;
        dec     al                      ;Reference 0-23.        
        mov     hld_com_num, al         ;Save COM port number.
        call    nextopnd                ;Get next command-line operand.
        ljz     com_hold_hold           ;If none, display current one.
;
;  Is the user trying to specify MOS HOLD COMxx OFF?
;
        mov     al, [si]
        and     al, 0DFh                ;Convert to upper case.
        cmp     al, 'O'
        ljne    com_hold_set            ;Go set a new hold value.
        mov     ax, [si+1]
        and     ax, 0DFDFh              ;Convert to upper case.
        cmp     ax, 'FF'
        ljne    erropnd                 ;O?? is a bad operand.
;
;   The user specified to turn off the hold on the COM port.
;   First, check to see if it is in use by another task.  If it
;   is, then the hold cannot be removed.
;
com_hold_off:
        lea     dx, hld_com_lis         ;Write first part of message.
        call    writemsg
;
;   Cancel reservation of COM port if this task has it.
;
        xor     bh, bh
        mov     bl, hld_com_num
        shl     bx, 1
        push    tcb_com_hold[bx]
        mov     tcb_com_hold[bx], 0
        call    Reserve_COM_port
        jnc     cho_OK
;
;   This task doesn't own the port.  Give the user an error.
;
        pop     tcb_com_hold[bx]
        lea     bx, ht_num+2
        mov     cx, 3
        xor     dx, dx
        call    bintodec
        lea     dx, hldrtsk
        jmp     fundone
;
;  The reservation has been cancelled.
;
cho_OK:
	pop	dx
        lea     dx, hld_rel_msg
        jmp     fundone
;
;  The user wants to set the reservation time.
;
com_hold_set:
        mov     bx, si
        call    dec2bin
        ljc     erropnd
	cmp	ax, 3600		;Limit to 3600 seconds. (Why?)
        jbe     chs_000
	lea	dx, hld_time_bad	; give time error message
	jmp	errexit
;
;  Write the new set time into the TCB.
;
chs_000:
        store_hold_time
        mov     bx, 182                 ;Convert value to ticks for TCB.
        mul     bx
        div     wordten

        xor     bh, bh                  ;Compute index value in BX.
        mov     bl, hld_com_num
        shl     bx, 1
        mov     TCB_COM_HOLD[bx], ax    ;Save the value in the TCB.

	lea	dx, hld_com_set	        ;Display COM set.
	call	writemsg
	lea	dx, hld_sec
	jmp	fundone
;
;  The user has specified MOS HOLD COMxx without any arguments.  This
;  means to take the hold time and actually reserve the COM port
;  for the specified task.
;
com_hold_hold:
;
;   Attempt to reserve the COM port.
;
        call    Reserve_COM_port
        jnc     chh_OK
;
;  Sorry.  The port is already in use by someone else.
;
        lea     bx, ht_num+2
        mov     cx, 3
        xor     dx, dx
        call    bintodec
        lea     dx, hld_com_lis
        call    writemsg
        lea     dx, hldrtsk
        jmp     fundone
;
;  The reservation was successful.
;
chh_OK:
        xor     bh, bh
        mov     bl, hld_com_num
        shl     bx, 1
        mov     ax, TCB_COM_HOLD[bx]    ;Save the HOLD counter.
        xor     dx, dx
        mul     wordten
        mov     bx, 182
        div     bx
        store_hold_time

        lea     dx, hld_com_msg
        call    writemsg
        lea     dx, hld_sec
        jmp fundone

;---------------------------------------------------------------------------
; Subroutine Reserve_COM_port
;
;  This routine checks to see if the selected COM port is presently 
;  reserved by another task.
;
;       Input:  DS:hld_com_num          Reference to which COM port to
;                                       be checked.
;
;       Output: AX                      Task currently holding the port
;                                       if CF set.
;
;       Notes:  ES remains pointing at TCB, DS is moved to the SCB
;               during this routine.
;
;---------------------------------------------------------------------------
Reserve_COM_port        proc    near

        push    ds
	mov	ah, 26h         ;Use new call (4.1) to services.
	int	SERVICES
        mov     ds, dx          ;Load DS with the selector.
	ASSUME	ds:scbs
        cli                     ;Shut interrupts off while we do this.
;
;   If the owner of the COM port is still undefined or it belongs to
;   the specified task, then the HOLD can be cleared.
;
        xor     bh, bh          ;Calculate index into SCB COM table.
        mov     bl, hld_com_num
        shl     bx, 1
        cmp     scb_com_owner[bx], -1
        je      rcp_OK
        mov     ax, task_ID
        cmp     scb_com_owner[bx], ax
        je      rcp_OK
;
;   The port is held by someone else right now.  Has the timer expired yet?
;
        shl     bx, 1                                   ;Address DWORD list.
        mov     ax, word ptr scb_com_timeout[bx]
        sub     ax, scbtimer
        mov     ax, word ptr scb_com_timeout[bx+2]
        sbb     ax, scbtimerh
        jb      rcp_OK                                  ;Timed out.
;
;   The port has not timed out return an error status indicating that
;   fact.
;
        shr     bx, 1                                   ;Back to word list.
        mov     ax, scb_com_owner[bx]
        pop     ds
        stc
        sti                                             ;Interrupts back on.
        ret
;
;   The port is available to be reserved.  Do it.
;
rcp_OK:
        xor     bh, bh
        mov     bl, hld_com_num
        shl     bx, 1
        cmp     tcb_com_hold[bx], 0
        je      rcp_REL
        mov     ax, task_ID
        mov     scb_com_owner[bx], ax
        mov     ax, tcb_com_hold[bx]
        shl     bx, 1
        add     ax, scbtimer
        mov     word ptr scb_com_timeout[bx], ax
        mov     ax, scbtimerh
        adc     ax, 0
        mov     word ptr scb_com_timeout[bx+2], ax
        jmp short rcp_DONE
;
;   The reservation time was 0, so just release the port.
;
rcp_REL:
        mov     scb_com_owner[bx], -1
        shl     bx, 1
        mov     word ptr scb_com_timeout[bx], 0
        mov     word ptr scb_com_timeout[bx+2], 0
;
;   The reservation process is complete.
;
rcp_DONE:
        pop     ds
        clc
        sti                             ;Interrupts back on.
        ret

        ASSUME  ds:mainseg

Reserve_COM_port        endp

onoff	proc
	push	ax
	push	si
	lodsb
	cmp	al,'o'			; lower case o
	je	onoff1
	cmp	al,'O'			; upper case o
	jne	onoff4
onoff1:
	lodsb
	cmp	al,'n'			; lower case n
	je	onoff3
	cmp	al,'N'			; upper case n
	je	onoff3
	cmp	al,'f'			; lower case f
	je	onoff2
	cmp	al,'F'			; upper case f
	jne	onoff4

onoff2:
	mov	[onflag],0
	jmp	short onoff4
onoff3:
	mov	[onflag],1
onoff4:
	pop	si
	pop	ax
	ret
onoff	endp

;-------------------------------------------------------------------------
;  Subroutine "testdev" tests a character string.
;
;       Input:  SI => Character string to be compared.
;               DI => Character device name to compare to.
;                     (Always in upper case).
;
;       Output: ZF set if names match.  DI points after the name.
;               ZF clear if names different, DI left alone.
;               SI and DI modified.
;               All other registers preserved.
;        
;-------------------------------------------------------------------------
testdev:
        push    ax
	push	cx
	mov	cx,3

testloop:
	lodsb
	cmp	al, 'a'
        jb      @F
	sub	al, 'a'
	add	al, 'A'
@@:
	cmp	al, [di]
	jne	testbad
	inc	di
	loop	testloop

	pop	cx
        pop     ax
	ret

testbad:
	pop	cx
        pop     ax
	xor	si,si
	ret




;--------------------- binary-to-decimal routine --------------------
;
;       INPUT:  DX:AX   Integer to be converted to ASCII decimal
;               DS:[BX] Target to place the ASCII decimal string.
;                       (End of string .. routine works leftward)
;               CX      Length of target string to write.
;
;
;--------------------------------------------------------------------
bintodec        proc    near

        push    ax
	push    cx      ;Push twice:  1 will be used, other for saving value.
        push    bp
        mov     bp, sp

btdloop1:
	div     wordten                 ;DX:AX is source integer.
	add     dl, '0'                 ;Remainder in DX will be 0-9.
                                        ;Convert to '0'-'9'
	mov     [bx], dl                ;Store.
	dec     bx                      ;Next decimal position.
	xor     dx,dx
	loop    btdloop1
        mov     cx, [bp+2]
;
;  The number has been written.  Now, go back through it and convert
;  any leading zeros to blanks.
;
btdloop2:
	inc     bx
	dec     cx
	jz      btdret
	cmp     byte ptr [bx],'0'
	jne     btdret
	mov     byte ptr [bx],' '
	jmp     btdloop2

btdret:
        pop     bp
        pop     cx
        pop     ax
	ret

bintodec endp
;------------- decimal-to-binary routine with error control------------; 

dec2bin	        proc	near

        cmp     byte ptr [bx], '0'
        jb      dec2err
        cmp     byte ptr [bx], '9'
        ja      dec2err
        call    dectobin
        clc
        ret

dec2err:
	xor	ax,ax
	stc
	ret

dec2bin	        endp	


;--------------------- decimal-to-binary routine --------------------;
dectobin        proc    near

	push  bp
	xor   bp, bp
	xor   ax, ax		    ; ax will contain the result
	mov   [minsign], 'N'
	cmp   byte ptr [bx], '-'    ; check for minus sign
	jne   dtbloop
	mov   [minsign], 'Y'
	inc   bx
dtbloop:			    ; bx is source address
	mov   dl, [bx]
	cmp   dl, '0'
	jb    dtbwrap
	cmp   dl, '9'
	ja    dtbwrap
	push  dx
	xor   dx, dx
	mul   wordten
	or    dx, dx
	jz    dtbskip
	inc   bp
dtbskip:
	pop   dx
	and   dx, 000fh
	add   ax, dx
	inc   bx
	jmp   dtbloop
dtbwrap:
	cmp   [minsign], 'Y'
	jne   dtbret
	neg   ax
dtbret:
	mov   dx, bp
	pop   bp
	ret

dectobin        endp

;------------------------ locate next operand -----------------------;
nextopnd proc
	cmp   byte ptr [si],0dh     ; check for end
	je    nextoprt
	cmp   byte ptr [si],','     ; skip comma'S
	je    nextopl2
	cmp   byte ptr [si],20h     ; scan for space
	je    nextopl2
	inc   si
	jmp   nextopnd
nextopl2:
	inc   si
	cmp   byte ptr [si],0dh
	je    nextoprt
	cmp   byte ptr [si],20h     ; scan for non-space
	je    nextopl2
nextoprt:
	ret			    ; zf=1 means end of operands
nextopnd endp

;-----------------------------------------------------------------------
; module: getmdev
; input:
; output:
;	 memptr has memory management pointer to routine
; crashes ax, bx, cx, dx
;-----------------------------------------------------------------------
getmdev proc
	push	es
	mov	ah,2
	int	services
	ASSUME	es:scbs
	cmp	[bx+scbmmfg],'N'
	je	mdevcont
	lea	dx,memman
	mov	ax,3d02h		; open driver
	int	21h
	jnc	mdevopen
mdevcont:
	xor	ax,ax
	mov	word ptr [memptr],ax
	mov	word ptr [memptr+2],ax
	pop	es
        ASSUME  es:tcb
	ret

mdevopen:
	mov	bx,ax
	mov	ax,4400h
	int	21h
	xor	dh,dh
	or	dl,20h			; binary mode
	mov	ax,4401h
	int	21h
	mov	ah,3fh			; read first for bytes
	mov	cx,4
	lea	dx,memptr
	int	21h
	pushf
	push	es
	les	bx,memptr
	mov	ax,es:[bx+2]
	mov	word ptr [memcall+2],ax
	mov	ax,es:[bx]
	mov	word ptr [memcall],ax
	pop	es
	popf
	jnc	mdevmsg
	mov	ah,3eh			; close handle
	int	21h
	jmp	mdevcont		; error....
mdevmsg:
	mov	ah,3eh
	int	21h
	pop	es
	ret
getmdev  endp
