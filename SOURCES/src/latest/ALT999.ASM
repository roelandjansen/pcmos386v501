        page    90, 132
        title   ALT999.ASM - Provide API control of ALT-999 keyboard state.
comment ^---------------------------------------------------------------
                     development specification

program name:   ALT999.SYS              assigned to: B. W. Roeser
module name:    ALT999.ASM              assign date: 9/5/90
entry points:                           completed: 9/18/90
entry from:     Any application calling INT 38 or D4
entry method:   INT
calls:          int21fun09
purpose:        Provides API support for ALT-999 function.
refer to:       n/a
last update: 
----------------------------------------------------------------------
----------------------------------------------------------------------
^

include         MACROS.INC

rqhin struc                             ; structure for init
in_rhlen        db      ?
in_unit         db      ?
in_command      db      ?
in_status       dw      ?
in_fill1        db      8 dup(?)
in_units        db      ?
in_endres       dd      ?
in_parmbpb      dd      ?
rqhin ends

rqhrw struc                             ; structure for reads and writes
rw_rhlen        db      ?
rw_unit         db      ?
rw_command      db      ?
rw_status       dw      ?
rw_fill1        db      8 dup(?)
rw_media        db      ?
rw_dataptr      dd      ?
rw_datasize     dw      ?
rw_strtsct      dw      ?
rw_volptr       dd      ?
rqhrw ends

setvect macro   p1,p2,p3        ;; p1 is vector #
        xor     ax,ax           ;; p2 is storage for original
        mov     es,ax           ;; p3 is new vector label
        pushf
        cli
        mov     ax,es:[p1*4]
        mov     word ptr [p2],ax
        mov     ax,es:[p1*4+2]
        mov     word ptr [p2+2],ax
        lea     ax,[p3]
        mov     es:[p1*4],ax
        mov     es:[p1*4+2],cs
        popf
        endm

TCB     segment at      1234h
        ORG     117h
tcbalt999       db      ?
TCB     ends

code    segment word public 'code'
        assume  cs:code, ds:nothing, es:nothing, ss:nothing

        org     0h
        dd      -1
        dw      8000h           ;Character device.
        dw      strat
        dw      intr
        db      '$$ALT999'

hdr             dw      0,0
orig38          dd      0
origd4          dd      0
origsf38        dd      0
scbptr          dd      0       ; far pointer to MOS's SCB structure
curtcb          dw      0       ; segment pointer to the current TCB

comment ^========================= strat ===============================
******** input ********
es:bx -> device header

******* process *******
enque the header pointer

******** output *******
header pointer recorded in hdr
=======================================================================^
        assume  cs:code

strat:
        mov     [hdr], bx
        mov     [hdr+2], es
        retf

comment ^========================= intr ================================
******** input ********
data already in device driver header, ptr already in hdr

******* process *******
decode the device driver function call (init only)

******** output *******
from the init function
=======================================================================^
        assume  cs:code, ds:code

intr:
        push    ax
        push    bx
        push    cx
        push    dx
        push    si
        push    di
        push    bp
        push    ds
        push    es
        les     bx,dword ptr [hdr]
        cmp     byte ptr es:[bx+2], 0
        jnz     @F
        call    init
@@:
        pop     es
        pop     ds
        pop     bp
        pop     di
        pop     si
        pop     dx
        pop     cx
        pop     bx
        pop     ax
        retf
 
comment ^========================= intd4 ===============================
******** input ********
intd4 function call parameters

        AH = 30h
        AL = non-zero

******* process *******

        Set the flag, TCBALT999 to requested value.

******** output *******

intd4 function call parameters
=======================================================================^
        assume  cs:code, ds:nothing, es:nothing

int38:
intd4:
        cmp     ah, 30h                 ;User trying to set ALT-999?
        je      @F
        jmp     cs:[origd4]             ;If not, continue with dispatch.
@@:
        cmp     al, 0                   ;If non-zero, force to 0xFF
        je      @F
        mov     al, -1
@@:
;
;       Get the address of the TCB.
;
        push    es
        push    bx
        push    ax
        mov     ah, 4
        mov     bx, -1                  ;Specify current task.
        pushf
        call    cs:[origd4]             ;Get from D4.
        assume  es:TCB
        pop     ax
        pop     bx
        mov     tcbalt999, al
        pop     es
        assume  es:NOTHING
        retf    2

comment ^========================= sf38 ===============================
******** input ********
scbfar38 function call parameters

******* process *******

******** output *******
sf38 function call parameters 
=======================================================================^
        assume  cs:code, ds:nothing, es:nothing

sf38:
        pushf
        call    cs:[origsf38]
        retf 2


$$end_resident_code     label   byte

;==================== device driver initialization =====================

initmsg db      'ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿       ',13,10
        db      '³ ALT999.SYS device driver installed. ³       ',13,10
        db      'ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ       ',13,10,'$'

err1    db      'ALT999.SYS not installed - improper MOS version     ',13,10,'$' ;@@XLAT

i21call macro
        pushf           ;; call int21h services
        cli             ;; using the local vector
        call [i21vect]
        endm

extcall macro
        pushf           ;; call MOS's extended services
        cli             ;; using the local vector
        call [extvect]
        endm


extvect dd      0       ; ptr for extended svcs handler


;- IS_MOS ---------------------------------------------------------------;
; entry parms:  none                                                    ;
; exit parms:   nz flag if the OS is MOS                                ;
;               zr flag if not                                          ;
;               AX containing the MOS version.                          ;
;                                                                       ;
; NOTES: Verify that this program is running under the PC-MOS           ;
; operating system before MOS specific system calls are made.           ;
;-----------------------------------------------------------------------;

is_MOS:
        push    ax
        push    bx
        push    cx
        push    dx
        mov     ax,3000h
        mov     bx,ax                   ; set ax == bx == cx == dx 
        mov     cx,ax                   ; to read the MOS version #
        mov     dx,ax
        int     21h
        push    ax
        mov     ax,3099h                ; now insure ax is different 
        int     21h                     ; to read the DOS version #
        pop     bx
        cmp     bx,ax                   ; if bx != ax then MOS
        pop     dx                      ; if bx == ax then not
        pop     cx
        pop     bx
        pop     ax
        ret


comment ^========================= init ================================
******** input ********
es:bx -> header

******* process *******
initialize driver 
verify mos 4.00
set 3 intercepts
set ending offset
return

******** output *******
ending address is set within device header
=======================================================================^
        assume  cs:code, ds:nothing, es:nothing, ss:nothing

init:
        call    is_MOS                  ;Are we running under MOS?
        ljz     not_MOS
        mov     ax, 3000h               ;If so, is it the right version?
        mov     bx, ax
        mov     cx, ax
        mov     dx, ax
        int     21h
        cmp     al, 4                   ;Correct version? (4.xx)
        ljne    not_MOS

        mov     ah,34h                  ;Get SCBINMOS flag.
        int     21h

        les     bx,es:[bx-18h]          ;Load ptr to SCBINT38
        mov     word ptr [extvect], bx
        mov     word ptr [extvect+2], es

        mov     ah,2                    ; make es:bx point to 
        extcall                         ; the base of the SCB.
        mov     word ptr [scbptr],bx
        mov     word ptr [scbptr+2],es
        mov     ah,34h                  ; hook scbfar38
        int     21h
        cli
        sub     bx,18h
        mov     ax,es:[bx]
        mov     word ptr [origsf38],ax
        mov     ax,es:[bx+2]
        mov     word ptr [origsf38+2],ax
        mov     word ptr es:[bx],offset sf38
        mov     word ptr es:[bx+2],cs
        setvect 38h,orig38,int38        ; hook int38
        setvect 0d4h,origd4,intd4       ; hook intd4
        sti

        mov     ah,9
        lea     dx, initmsg             ;All is well.
        int     21h

        lea     ax, $$end_resident_code
        les     bx,dword ptr cs:[hdr]   ;Tell MOS where this guy ends.
        mov     word ptr es:[bx+14], ax
        mov     es:[bx+16],cs
        mov     word ptr es:[bx+3],10h  ; return with 'DONE'
        ret                             ; end of init
;
;  Not running under MOS.  Terminate installation.
;
not_MOS:
        mov     ah, 9
        lea     dx, err1
        int     21h
        les     bx, dword ptr [hdr]
        mov     word ptr es:[bx+14], 0
        mov     es:[bx+16], cs
        mov     word ptr es:[bx+3], 10h         ;Done.
        ret

code    ends
        end
