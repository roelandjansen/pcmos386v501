	include page.inc
	title	DEBUGTRA.ASM - MOS DEBUG Tracing Functions
;
;******************************************************************************
;*                                                                            *
;*                        MOS Development Specification                       *
;*                                                                            *
;* Command type: External               Assigned to:        Stewart A. Hyde   *
;* Command name: DEBUG                  Date assigned:      August 20, 1986   *
;*                                      Date completed:                       *
;* Command format: DEBUG d:[path][filename][.ext][parm1][parm2]               *
;* Purpose:  To provide debugging facilities to MOS                           *
;* Refer to: IBM PC-DOS 3.2 DOC and MOSDEBUG.DOC                              *
;* Last Update:                         By:                                   *
;******************************************************************************
;-------------------------------------------------------------------------;
; 	07/24/87 	SAH	maintinance				  ;
;	01/06/88        SAH     remove direct port outs during swap	  ;
;-------------------------------------------------------------------------;
;	09/08/88	RKG	Misc Cleanup and internal name change	  ;
;-------------------------------------------------------------------------;
;       05/16/90        SAH     Cleanup					  ;
;	05/17/90	SAH     Corrections for g=c800:5		  ;
;-------------------------------------------------------------------------;

        page
        include debugtra.pub

extrn   old01:word, old02:word, old03:word, regax:word, regbx:word
extrn   regcx:word, regdx:word, regbp:word, regsi:word, regdi:word
extrn   regcs:word, regds:word, reges:word, regip:word, regflag:word
extrn   regss:word, regsp:word, stkseg:word, stkptr:word, dbaddr:word
extrn   old22:word, old23:word, old24:word, bptab:word, regall:word
extrn   regbak:word, sbufseg:word, scursor:word, scraddr:word, retaddr:word
extrn   retflag:word, retseg:word, retoff:word, old20:word, tcount:word
extrn   cmdss:word, cmdsp:word, cmdes:word, retloc:word, ChildPSP:word
extrn   ptn:byte, goflag:byte, spage:byte, modes:byte, vmode:byte
extrn   Stpflag:byte, smode:byte, bpins:byte, bpflag:byte, brk:byte
extrn   quitprg:byte, usrterm:byte, bflag:byte, redout:byte, maincon:byte
extrn   DumpReg:near, OutMsg:near, qreturn:near, repeat:near, isload:byte

        include debugmac.inc

	if	0 eq 0

SCRSIZE equ     4096
SCREEN  equ     0ffffh
BPSOFT  equ	10		; # of soft break points
BPHARD  equ 	10		; # of hard break points	

	endif

moss    segment word public 'code'
        assume cs:moss;ds:moss


        page
;-------------------------------------------------------------------------;
;       Function: SetTrap                                                 ;
;                 Restores Interupts for debugger, INT 23,INT 24          ;
;       Input:                                                            ;
;       Output:                                                           ;
;-------------------------------------------------------------------------;

SetTrap proc    near
        push    ax
        push    bx
        push    dx
        push    ds
        push    es
;
;       get old interupt 23
;
        mov     ax, 3523h
        int     21h
        mov     cs:[old23], bx
        mov     ax, es
        mov     cs:[old23+2], ax
;
;       get old interupt 24
;
        mov     ax, 3524h
        int     21h
        mov     cs:[old24], bx
        mov     ax, es
        mov     cs:[old24+2], ax
;
;       save new interupt 23
;
        mov     ax, 2523h
        mov     dx, offset CtlBrk
        int     21h
;
;       save new interupt 24
;
        mov     ax, 2524h
        mov     dx, offset Fatal
        int     21h

        pop     es
        pop     ds
        pop     dx
        pop     bx
        pop     ax
        ret
SetTrap endp


        page
;-------------------------------------------------------------------------;
;       Function: SetInt                                                  ;
;                 Setups Interupts for debugger, INT 01, INT 02 & INT 03  ;
;       Input:                                                            ;
;       Output:                                                           ;
;-------------------------------------------------------------------------;

SetInt  proc    near
        push    ax
        push    bx
        push    dx
        push    ds
        push    es

;
;       get old interupt 01
;
        mov     ax, 3501h
        int     21h
        mov     cs:[old01], bx
        mov     ax, es
        mov     cs:[old01+2], ax
;
;       get old interupt 02
;
        mov     ax, 3502h
        int     21h
        mov     cs:[old02], bx
        mov     ax, es
        mov     cs:[old02+2], ax
;
;       get old interupt 03
;
        mov     ax, 3503h
        int     21h
        mov     cs:[old03], bx
        mov     ax, es
        mov     cs:[old03+2], ax
	
	push	cs
	pop	ds
;
;       save new interupt 02
;
        mov     ax, 2502h
        mov     dx, offset Break2
        int     21h
;
;       save new interupt 03
;
        mov     ax, 2503h
        mov     dx, offset Break3
        int     21h

	mov     bx, [regcs]
	cmp	bx, [ChildPSP]
	jne	SkipSInt
	mov     ah, 50h
	int     21h
SkipSInt:

        pop     es
        pop     ds
        pop     dx
        pop     bx
        pop     ax
        ret
SetInt  endp

        page
;-------------------------------------------------------------------------;
;       Function: RestInt                                                 ;
;                 Restores Interupts for debugger, INT 01,INT 02 & INT 03 ;
;       Input:                                                            ;
;       Output:                                                           ;
;-------------------------------------------------------------------------;

RestInt proc    near
        push    ax
        push    dx
        push    ds
;
;       save old interupt 02
;
        mov     ax, 2502h
        mov     dx, [old02+2]
        mov     ds, dx
        mov     dx, [old02]
        int     21h
;
;       save old interupt 03
;
        mov     ax, 2503h
        mov     dx, [old03+2]
        mov     ds, dx
        mov     dx, [old03]
        int     21h

	mov     bx, cs
	mov	ah, 50h
	int     21h

        pop     ds
        pop     dx
        pop     ax
        ret
RestInt endp

        page
;-------------------------------------------------------------------------;
;       Function: SetSS                                                   ;
;                 Setups Single Step Interupt for debugger, INT 01        ;
;       Input:                                                            ;
;       Output:                                                           ;
;-------------------------------------------------------------------------;

SetSS   proc    near
        push    ax
        push    bx
        push    dx
        push    ds
        push    es

;
;       get old interupt 01
;
        mov     ax, 3501h
        int     21h
        mov     cs:[old01], bx
        mov     ax, es
        mov     cs:[old01+2], ax
;
;       save new interupt 01
;
        push    cs
        pop     ds
        mov     ax, 2501h
        mov     dx, offset SStep
        int     21h

        pop     es
        pop     ds
        pop     dx
        pop     bx
        pop     ax
        ret
SetSS   endp

        page
;-------------------------------------------------------------------------;
;       Function: RestSS                                                  ;
;                 Restores Single Step Interupts for debugger, INT 01     ;
;       Input:                                                            ;
;       Output:                                                           ;
;-------------------------------------------------------------------------;

RestSS  proc    near
        push    ax
        push    dx
        push    ds
;
;       save old interupt 01
;
        mov     ax, 2501h
        mov     dx, [old01+2]
        mov     ds, dx
        mov     dx, [old01]
        int     21h

        pop     ds
        pop     dx
        pop     ax
        ret
RestSS  endp

        page
;-------------------------------------------------------------------------;
;       Function: SStep                                                   ;
;       Input:                                                            ;
;       Output:                                                           ;
;-------------------------------------------------------------------------;

SStep   proc    near
	pushf

ss1:
        cmp     cs:[tcount], 0
        je      ss2
        dec     cs:[tcount]
	popf
        iret

ss2:
	popf
        InitReg
        DoIret
SStep   endp

        page
;-------------------------------------------------------------------------;
;       Function: Break2                                                  ;
;       Input:                                                            ;
;       Output:                                                           ;
;-------------------------------------------------------------------------;

Break2  proc    near
        InitReg
        dec     cs:[regip]
        dec     cs:[regip]
        mov     cs:[brk], '1'
        DoIret
Break2  endp

        page
;-------------------------------------------------------------------------;
;       Function: Break3                                                  ;
;       Input:                                                            ;
;       Output:                                                           ;
;-------------------------------------------------------------------------;

Break3  proc    near
        InitReg
        dec     cs:[regip]
        mov     cs:[brk], '1'
        DoIret
Break3  endp

        page
;-------------------------------------------------------------------------;
;       Function: Term                                                    ;
;       Input:                                                            ;
;       Output:                                                           ;
;-------------------------------------------------------------------------;

Term    proc    near

        mov     dx, cs
        mov     ds, dx
        mov     es, dx


	mov     [isload], 0		; no longer in memory
        cmp     [quitprg], 1
        je      term1
        mov     [usrterm], 1
        mov     cx, 14
        lea     si, regbak
        lea     di, regall
        cld
        rep     movsw
        jmp     short term2 

term1:
        mov     dx, [retloc]
        mov     [retoff], dx
        mov     ax, cs
        mov     [retseg], ax

term2:
        jmp     dword ptr cs:[retaddr]
Term    endp

        page
;-------------------------------------------------------------------------;
;       Function: CtlBrk                                                  ;
;       Input:                                                            ;
;       Output:                                                           ;
;-------------------------------------------------------------------------;

CtlBrk  proc    near
	sti
	push    ax
	mov     cs:[bflag], 1
        pushf
        cmp     cs:[goflag], 1
        je      cb1
        pop     ax
	push    bx
	push    cs
	pop     ds
	mov     [retflag], ax
	mov     ax, [cmdss]
	mov     bx, [cmdsp]
	cli
	mov     ss, ax
	mov	sp, bx
	sti
	mov     es, [cmdes]
	mov     word ptr[retoff], offset repeat
	mov	[retseg], cs
	pop	bx
	pop	ax
	DoIret

cb1:
        popf
	pop	ax
        InitReg
        dec     cs:[regip]
        mov     cs:[brk], '1'
        DoIret
CtlBrk  endp

        page
;-------------------------------------------------------------------------;
;       Function: Fatal                                                   ;
;       Input:                                                            ;
;       Output:                                                           ;
;-------------------------------------------------------------------------;

Fatal   proc    near
	sti
        call    dword ptr cs:[old24]
        pushf
        cmp     [goflag], 1
        je      ft1
        popf
	push    ax
        mov     al, 20h
        out     20h, al
	pop     ax
        iret

ft1:
	popf
        InitReg
        dec     cs:[regip]
        mov     cs:[brk], '1'
        DoIret

Fatal   endp

        page
;-------------------------------------------------------------------------;
;       Function: SetBrk                                                  ;
;       Input:                                                            ;
;                 AL = Break Point #  (0 - 9 GO, 10 - 19 BP)              ;
;                 DX = Break Point Offset                                 ;
;                 DI = Break Point Segment                                ;
;       Output:                                                           ;
;-------------------------------------------------------------------------;

SetBrk  proc    near
        push    bx

        mov     bl, al
        xor     bh, bh
        shl     bx, 1
	shl     bx, 1
        mov     [bx+bptab], di
        mov     [bx+bptab+2], dx

        pop     bx
        ret
SetBrk  endp

        page
;-------------------------------------------------------------------------;
;       Function: ClrBrk                                                  ;
;       Input:                                                            ;
;                 AL = Break Point #  (0  - 9 = GO, 10 - 19 BP)           ;
;       Output:                                                           ;
;-------------------------------------------------------------------------;

ClrBrk  proc    near
        push    ax
        push    bx

        mov     bl, al
        xor     bh, bh
        shl     bx, 1
	shl     bx, 1
        xor     ax, ax
        mov     [bx+bptab],   ax
        mov     [bx+bptab+2], ax

        pop     bx
        pop     ax
        ret
ClrBrk  endp

        page
;-------------------------------------------------------------------------;
;       Function: InsBrk                                                  ;
;       Input:                                                            ;
;       Output:                                                           ;
;-------------------------------------------------------------------------;

InsBrk  proc    near
        push    ax
        push    bx
        push    cx
        push    si
        push    es

        push    cs
        pop     ds
        xor     bx, bx
        cmp     [bpflag], 0
        je      ib0 
        mov     cx, BPSOFT+BPHARD
        jmp     short ib1

ib0:
        mov     cx,  BPSOFT  

ib1:
        xor     ax, ax
        cmp     [bx+bptab], ax
        jne     ib2
        cmp     [bx+bptab+2], ax
        je      ibend

ib2:

;       Insert  Break Point Here

        
        mov     ax, [bx+bptab]
        mov     es, ax
        mov     di, [bx+bptab+2]

ib3:
        mov     al, es:[di]
        shr     bx, 1
        mov     [bx+bpins], al
        shl     bx, 1
        mov     al, 0cch        ; code for INT 3
        stosb

ibend:
        add     bx, 4
        loop    ib1

        pop     es
        pop     di
        pop     cx
        pop     bx
        pop     ax
        ret
InsBrk  endp

        page
;-------------------------------------------------------------------------;
;       Function: RemBrk                                                  ;
;       Input:                                                            ;
;       Output:                                                           ;
;-------------------------------------------------------------------------;

RemBrk  proc    near
        push    ax
        push    bx
        push    cx
        push    di
        push    es

        push    cs
        pop     ds
        xor     bx, bx
        cmp     [bpflag], 0
        je      rb0
        mov     cx, BPSOFT+BPHARD
        jmp     short rb1

rb0:
        mov     cx, BPSOFT

rb1:
        xor     ax, ax
        cmp     [bx+bptab], ax
        jne     rb2
        cmp     [bx+bptab+2], ax
        je      rbend

rb2:

;       Remove  Break Point Here

        mov     ax, [bx+bptab]
        mov     es, ax
        mov     di, [bx+bptab+2]
        cmp     di, [regip]
        jne     rb3
        cmp     ax, [regcs]
        jne     rb3
        cmp     byte ptr [bx+bpins], 0cch
        je      rbend

rb3:
        shr     bx, 1
        mov     al, [bx+bpins]  ; get for byte at breakpoint
        shl     bx, 1
        stosb

rbend:
        add     bx, 4
        loop    rb1

        pop     es
        pop     di
        pop     cx
        pop     bx
        pop     ax
        ret
RemBrk  endp

        page
;-------------------------------------------------------------------------;
;       Function: SaveReg                                                 ;
;       Input:                                                            ;
;       Output:                                                           ;
;-------------------------------------------------------------------------;

SaveReg proc    near
        mov     ax, ds
        mov     cs:[regds], ax
        mov     ax, es
        mov     cs:[reges], ax
        mov     ax, cs
        mov     ds, ax
        mov     es, ax
        assume  ds:moss; es:moss
	mov     [regbx], bx
        mov     [regcx], cx
        mov     [regdx], dx
        mov     [regbp], bp
        mov     [regsi], si
        mov     [regdi], di
        ret
SaveReg endp

        page
;-------------------------------------------------------------------------;
;       Function: RestReg                                                 ;
;       Input:                                                            ;
;       Output:                                                           ;
;-------------------------------------------------------------------------;

RestReg proc    near
        mov     bx, [regbx]
        mov     cx, [regcx]
        mov     dx, [regdx]
        mov     bp, [regbp]
        mov     si, [regsi]
        mov     di, [regdi]
        mov     ax, [reges]
        mov     es, ax
        mov     ax, [regds]
        mov     ds, ax
        mov     ax, cs:[regax]
        ret
RestReg endp

        page
;-------------------------------------------------------------------------;
;       Function: DoSwap                                                  ;
;       Input:                                                            ;
;       Output:                                                           ;
;-------------------------------------------------------------------------;

DoSwap  proc    near            
        cmp     [dbaddr], SCREEN
        jne     dsend
        call    SwapScr         ; swap screen

dsend:
        ret
DoSwap  endp

        page
;-------------------------------------------------------------------------;
;       Function: SwapScr                                                 ;
;       Input:                                                            ;
;       Output:                                                           ;
;-------------------------------------------------------------------------;

SwapScr proc    near
        push    ax
        push    bx
        push    cx
        push    dx
        push    si
        push    di
        push    ds
        push    es

	push    cs
        pop     ds
	cld
	cmp     [redout], 1
	jne	ssstart
	jmp	ssdone

ssstart:
	mov     ah, 15
	int     10h		; get active page
        mov     ah, 3
        int     10h             ; read cursor position
        xchg    bl, [spage]     ; exchange pages
        xchg    dx, [scursor]   ; exchange cursors
        mov     ah, 2
        int     10h             ; set cursor position

        mov     ax, [sbufseg]   ; get screen buffer segment
        mov     es, ax
        mov     ax, [scraddr]   ; get screen segment b800 or b000
        mov     ds, ax
        xor     si, si
        xor     di, di
        mov     cx, SCRSIZE/2   ; get lenght

ssloop:
        mov     ax, es:[di]     ; get word from buffer
        xchg    ax, [si]        ; exchange it with screen
        stosw                   ; put screen in buffer
        inc     si              ; why didn't Intel Think of
        inc     si              ; of SWAPSW
        loop    ssloop
ssdone:
        pop     es
        pop     ds
        pop     di
        pop     si
        pop     dx
        pop     cx
        pop     bx
        pop     ax
        ret
SwapScr endp

        page
;-------------------------------------------------------------------------;
;       Function: ClrSBuf                                                 ;
;       Input:                                                            ;
;       Output:                                                           ;
;-------------------------------------------------------------------------;

ClrSBuf proc    near
        push    ax
        push    cx
        push    di
        push    es

        mov     ax, [sbufseg]
        mov     es, ax
        mov     ax, 0720h               ; space & attribute of seven default
        mov     cx, SCRSIZE/2
        xor     di, di
        rep     stosw

        pop     es
        pop     di
        pop     cx
        pop     ax
        ret
ClrSBuf endp


;-------------------------------------------------------------------------;
moss    ends
        end
