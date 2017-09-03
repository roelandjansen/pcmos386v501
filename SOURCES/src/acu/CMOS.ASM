PAGE 90, 132
;
;****************************************************************************
;
;       MODULE NAME:    CMOS_base_memsize();
;                       CMOS_ext_memsize();
;
;       TASK NAME:      ACU.EXE
;
;       PROJECT:        PC-MOS Configuration Utility
;
;       CREATION DATE:  15-May-90
;
;       REVISION DATE:  15-May-90
;
;       AUTHOR:         B. W. Roeser
;
;       DESCRIPTION:    Obtains the memory size information stored
;                       in the CMOS RAM.  (Will only work on a 286
;                       or 386 system).
;
;
;               (C) Copyright 1990, The Software Link Inc.
;                       All Rights Reserved
;
;****************************************************************************
;
;       USAGE:          size = CMOS_base_memsize();
;                       size = CMOS_ext_memsize();
;
;       PARAMETERS:     
;
; NAME          TYPE    USAGE   DESCRIPTION
; ----          ----    -----   -----------
; size          uns     output  Memory size in KB.
;
;****************************************************************************
;                       >> Revision Log <<
;
; DATE          PROG    DESCRIPTION OF REVISION
; ----          ----    -----------------------
;
;****************************************************************************
;
        PUBLIC  _CMOS_base_memsize
        PUBLIC  _CMOS_ext_memsize


CMOS_text       segment         word    'code'
                assume          cs:CMOS_text, ds:nothing


_CMOS_base_memsize      proc    far

        pushf
        cli                     ;No interrupts while we do this.  CMOS must
                                ;be accessed FAST.
        mov     al, 015h
        out     070h, al        ;Select address.
        jmp short @F            ;Let the bus settle.
@@:
        in      al, 071h        ;Get the lower byte.
        mov     dl, al          ;Save in DL.

        mov     al, 16h
        out     070h, al        ;Select address.
        jmp short @F            ;Let the bus settle.
@@:
        in      al, 071h        ;Get the high byte.
        xchg    ah, al          ;Put in high byte of AX.
        mov     al, dl          ;Get low byte back.

        popf
        ret

_CMOS_base_memsize      endp


_CMOS_ext_memsize      proc    far

        pushf
        cli                     ;No interrupts while we do this.  CMOS must
                                ;be accessed FAST.
        mov     al, 017h
        out     070h, al        ;Select address.
        jmp short @F            ;Let the bus settle.
@@:
        in      al, 071h        ;Get the lower byte.
        mov     dl, al          ;Save in DL.

        mov     al, 18h
        out     070h, al        ;Select address.
        jmp short @F            ;Let the bus settle.
@@:
        in      al, 071h        ;Get the high byte.
        xchg    ah, al          ;Put in high byte of AX.
        mov     al, dl          ;Get low byte back.

        popf
        ret

_CMOS_ext_memsize      endp

CMOS_text       ends
                end
