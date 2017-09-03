PAGE 90, 132
;
;****************************************************************************
;
;       MODULE NAME:    CPU_type
;
;       TASK NAME:      none
;
;       PROJECT:        Configuration Utility
;
;       CREATION DATE:  4-May-90
;
;       REVISION DATE:  4-May-90
;
;       AUTHOR:         Stewart A. Hyde
;
;       DESCRIPTION:    Determines type of CPU. (Intel)
;
;
;               (C) Copyright 1990, The Software Link Inc.
;                       All Rights Reserved
;
;****************************************************************************
;
;       USAGE:          type = CPU_type();
;
;       PARAMETERS:     
;
; NAME          TYPE    USAGE   DESCRIPTION
; ----          ----    -----   -----------
; type          int     output  Type of CPU.
;
;                               0 = 8086
;                               1 = 80186
;                               2 = ipx286
;                               3 = ipx386
;                               4 = ipx486
;
;****************************************************************************
;                       >> Revision Log <<
;
; DATE          PROG    DESCRIPTION OF REVISION
; ----          ----    -----------------------
;
;****************************************************************************
;
CPU_TYPE_text   segment word    'code'
                assume  cs:CPU_TYPE_text, ds:nothing

                public  _CPU_type

_CPU_type       proc    far

        pushf
        xor     ax, ax
        push    ax
        popf                    ; try to put zero in flags
        pushf
        pop     ax
        and     ax, 0F000H
        xor     bl, bl          ; indicate 808X series
        cmp     ax, 0F000H
        je      begin5

        mov     bl, 3           ; indicate 80386 series
        mov     ax, 0F000H      ; try to but 1's in high bits
        push    ax
        popf
        pushf
        pop     ax
        and     ax, 0F000H
        jne     cpuver

        dec     bl              ; indicate 80286 series
        push    sp
        pop     ax
        cmp     ax, sp          ; test for prefetch
        je      cpuver
        xor     bl, bl
begin5:
        mov     cx, 33
        mov     al, 0ffh
        shl     al, cl
        jz      cpuver          ; must be an 808X series
        mov     bl, 1           ; indicate 8018X series
cpuver:
        popf
        cmp     bl,3    
        jne     not386
;
;       now we will test for 486
;
        .386
        mov     edx,esp
        and     esp,not 3
        pushfd
        pop     eax
        mov     ecx,eax
        xor     eax,40000h
        push    eax
        popfd
        pushfd  
        pop     eax
        xor     eax,40000h              ; Intel Manual is incorrect
        shr     eax,18
        and     eax,1
        push    ecx
        popfd
        mov     esp,edx
        .286
        or      al,al
        jnz     not386
        inc     bl

not386:
        xor     ah, ah
        mov     al, bl
        ret

_CPU_type       endp

CPU_type_text   ends
                end
