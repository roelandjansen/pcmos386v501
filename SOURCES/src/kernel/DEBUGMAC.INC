        page
;-------------------------------------------------------------------------;
;       Macro:   PushAll                                                  ;
;       Input:                                                            ;
;       Output:                                                           ;
;-------------------------------------------------------------------------;

PushAll macro
        push    ax
        push    bx
        push    cx
        push    dx
        push    si
        push    di
        push    bp
        push    ds
        push    es
        endm

;-------------------------------------------------------------------------;
;       Macro:   PushAll                                                  ;
;       Input:                                                            ;
;       Output:                                                           ;
;-------------------------------------------------------------------------;

PopAll  macro
        pop     es
        pop     ds
        pop     bp
        pop     di
        pop     si
        pop     dx
        pop     cx
        pop     bx
        pop     ax
        endm


        page
;-------------------------------------------------------------------------;
;       Macro:   PrgStk                                                   ;
;                saves users stacks and set program stack (debug)         ;
;       Input:                                                            ;
;       Output:                                                           ;
;-------------------------------------------------------------------------;

PrgStk  macro
        cli
        mov     cs:[regss], ss
        mov     cs:[regsp], sp
        mov     sp, cs:[stkptr]
        mov     ss, cs:[stkseg]
        sti
        endm

;-------------------------------------------------------------------------;
;       Macro:   UserStk                                                  ;
;                saves program stack (debug) and sets user stack          ;
;       Input:                                                            ;
;       Output:                                                           ;
;-------------------------------------------------------------------------;

UserStk macro
        cli
        mov     cs:[stkseg], ss
        mov     cs:[stkptr], sp
        mov     ss, cs:[regss]
        mov     sp, cs:[regsp]
        sti
        endm

        page
;-------------------------------------------------------------------------;
;       Macro:   InitReg                                                  ;
;       Input:                                                            ;
;       Output:                                                           ;
;-------------------------------------------------------------------------;

InitReg macro
        push     bp
        mov      bp, sp
        mov      cs:[regax], ax
        mov      ax, ss:[bp+2]
        mov      cs:[regip], ax
        mov      ax, ss:[bp+4]
        mov      cs:[regcs], ax
        mov      ax, ss:[bp+6]
        pop      bp
        pushf
        pop      ax
        and      ah, 0feh
        mov      cs:[regflag], ax
	mov	 cs:[retflag], ax
        call     SaveReg
        endm

;-------------------------------------------------------------------------;
;       Macro:   DoIret                                                   ;
;       Input:                                                            ;
;       Output:                                                           ;
;-------------------------------------------------------------------------;

DoIret  macro
	add     sp, 6
	pushf
;;      push    cs:[retflag]
        push    cs:[retseg]
        push    cs:[retoff]
        iret
        endm

;-------------------------------------------------------------------------;
;       Macro:   SetTFlg                                                  ;
;       Input:                                                            ;
;       Output:                                                           ;
;-------------------------------------------------------------------------;

SetTFlg macro
        mov     [stpflag], 1
        pushf
        push    bp
        mov     bp, sp
        or      word ptr ss:[bp+2], 0100h
        pop     bp
        popf
        endm

