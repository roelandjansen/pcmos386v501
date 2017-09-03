PAGE 90, 132
;
;****************************************************************************
;
;       MODULE NAME:    Trap_i2109()
;                       Release_i2109()
;
;       TASK NAME:      ACU.EXE
;
;       PROJECT:        PC-MOS Auto Configuration Utility
;
;       CREATION DATE:  7/24/90
;
;       REVISION DATE:  7/24/90
;
;       AUTHOR:         B. W. Roeser
;
;       DESCRIPTION:    Traps the DOS print-string function and positions
;                       the cursor to a predetermined location on the
;                       screen.  Used, mainly, for status output of
;                       FORMAT.COM.
;
;                       This routine is really only good for single lines
;                       of output, multiple lines will not be handled
;                       unless really needed.
;
;		(C) Copyright 1990, The Software Link Inc.
;			All Rights Reserved
;
;****************************************************************************
;
;       USAGE:          Trap_i2109(int cpos);
;                       Release_i2109();
;
;	PARAMETERS:	
;
; NAME		TYPE	USAGE	DESCRIPTION
; ----		----	-----	-----------
; cpos          int     input   Cursor position at which any output
;                               sent though Int 21 / 09 will be placed.
;
;****************************************************************************
;			>> Revision Log <<
;
; DATE		PROG	DESCRIPTION OF REVISION
; ----		----	-----------------------
;
;****************************************************************************
;
CPOS    equ     [bp+6]          ;Cursor position defined.

_text   segment         word    public  'code'
        assume          cs:_text, ds:nothing
        PUBLIC          _Trap_i2109, _Release_i2109
;
;  Local data storage.
;
i21_address     label   dword
i21_off         dw      0
i21_seg         dw      0

cursor_pos      dw      ?
save_cpos       dw      ?

i21     proc    far

        pushf
        cmp     ah, 9
        je      @F                      ;If F9, then go process.
;
;  Not F9.  Just continue on to the original vector.
;
        popf
        jmp     i21_address             ;Just continue.
;
;   Grab control of the print-string function.  Position the cursor
;  at the specified location and display the string.
;
@@:
        popf                            ;Don't care about flags anymore.

        push    ax
        push    bx
        push    dx
        push    bp
;
;   Get the current cursor position and save it.
;
        mov     ah, 3
        xor     bh, bh
        int     10h
        mov     save_cpos, dx
;
;   Position the cursor, then let DOS display the intended message.
;
        mov     ah, 2           ;Position the cursor.
        xor     bh, bh
        mov     dx, cursor_pos
        int     10h

        pop     bp
        pop     dx
        pop     bx
        pop     ax
;
;    Simulate an Int 21 call to the original vector.
;
        pushf
        call    i21_address
;
;   Once back from the Int 21 function, restore the cursor position
;  to where it was.
;
        push    ax
        push    bx
        push    dx
        push    bp

        mov     ah, 2
        xor     bh, bh
        mov     dx, save_cpos
        int     10h

        pop     bp
        pop     dx
        pop     bx
        pop     ax
;
;   The process is complete.  Return to the caller.
;
        iret

i21     endp

_Trap_i2109     proc    far

        push    bp
        mov     bp, sp
        push    ds
        push    es

        test    i21_seg, -1             ;Already trapped?
        jnz     _Ti2109_exit
;
;  The cursor passed in will be a decimal integer value encoded with
;  the row and column.  To use in BIOS, the row and column must be kept
;  in AH and AL.  In other words, the value 1405 (decimal) must be
;  converted to 0x1405.
;
        mov     ax, CPOS                ;Fetch passed in argument.
        mov     bx, 100                 ;Break into Row/Col coords.
        div     bl                      ;8-bit divide.
        xchg    ah, al                  ;Row in AH, col in AL
        sub     ax, 101h                ;Convert to 0 relative coords.
        mov     cursor_pos, ax          ;Save aside.

        mov     ax, 3521h               ;Get current int 21 vector address.
        int     21h
        mov     i21_off, bx             ;Place the components above.
        mov     i21_seg, es

        mov     ax, _text               ;Get the address of the new routine.
        mov     ds, ax
        lea     dx, i21

        mov     ax, 2521h               ;Replace it.
        int     21h

_Ti2109_exit:                           ;All done.
        pop     es
        pop     ds
        pop     bp
        ret

_Trap_i2109     endp


_Release_i2109  proc    far

        push    bp
        mov     bp, sp
        push    ds

        lds     dx, i21_address         ;Get the original address.
        mov     ax, 2521h               ;Replace it.
        int     21h

        mov     i21_off, 0              ;Indicate no longer replaced.
        mov     i21_seg, 0

        pop     ds                      ;All done.
        pop     bp
        ret

_Release_i2109  endp

_text   ends
        end
