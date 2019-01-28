	include page.inc
        title DEBUGCON.ASM - MOS DEBUG Console Drivers
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
;*                                                                            *
;*      External                Values                  Values                *
;*      routines                passed                  returned              *
;* -------------------------------------------------------------------------- *
;* (add as many lines as you need here and above to complete the form.)       *
;* -------------------------------------------------------------------------- *
;* MOS commands will use the same segment grouping as the MOS kernel. This    *
;* file is a template as is MOSSHELL.ASM. Except that its designed for use in *
;* commands, both internal and external, for MOS. See MOSSHELL.ASM for de-    *
;* tails. The commands should not need to go into as much detail as the kernel*
;* does in keeping track of end of segment pointers in the INC files and such.*
;* Our desire is to maintain the same coding standards thruout MOS and to use *
;* code modularity as much as possible. So, use the same group labels in any  *
;* routine to keep the code and data segments in the same segment.            *
;*                                                                            *
;******************************************************************************
;----------------------------------------------------------------------------;
;	07/23/87	SAH	Misc Cleanup - MAINTENANCE		     ;
;----------------------------------------------------------------------------;
;       08/20/87	SAH     fast video output for dumps		     ;
;----------------------------------------------------------------------------;
;	09/08/88	RKG	Misc Cleanup and internal name change	     ;
;----------------------------------------------------------------------------;


        if1
                %out ---------------------------------------------------------
                %out -    PC-MOS/386  Debugger Version 3.20  Release 1.02
                %out -                  Author: Stewart Hyde
                %out -
                %out -                      DEBUGCON.ASM
                %out -
                %out -   (c) Copyright 1986 The Software Link, Incorporated
                %out ---------------------------------------------------------
                %out
                %out
                %out   Pass 1   Started.
        else
                %out   Pass 2   Started.
        endif

        include debugcon.pub


extrn   dbaddr:word, lastval:byte, rubout:byte, crlf:byte, lenbuff:byte
extrn   buffbkp:byte, lenbkp:byte
extrn   blank1:byte, dbport:word


moss    segment word public 'code'
        assume cs:moss;ds:moss;es:moss

	if	0 eq 0

SCREEN  equ    0FFFFH
XOFF    equ    13H

	endif

	subttl	Basic Console in/out functions
        page
;-------------------------------------------------------------------------;
;       Console commands  for debugger                                    ;
;-------------------------------------------------------------------------;
;       Function: GetKey                                                  ;
;                 Gets key from main console or debug console depending   ;
;		  on mode current set, by check debug address		  ;
;       Input:                                                            ;
;       Output:                                                           ;
;            AL = Chararcter return from console                          ;
;-------------------------------------------------------------------------;

GetKey  proc    near
        cmp     [dbaddr], SCREEN  ; Main Console (SWAP MODE)
        jne     getkey1
        mov     ah, 8
        int     21h
        ret

getkey1 label   near
	mov     dx, [dbaddr]
	dec     dx
	mov     ah, 2
	int     14h
	or      ah, ah
	jnz     getkey1
	ret
GetKey  endp



;-------------------------------------------------------------------------;
;       Function: OutChar                                                 ;
;       Input:                                                            ;
;            DL = Chararcter to send to console                           ;
;       Output:                                                           ;
;-------------------------------------------------------------------------;

OutChar proc    near
        push    ax

        cmp     [dbaddr], SCREEN ; Main Console (SWAP MODE)
        jne     outch1
        mov     ah, 2
        int     21h
        jmp     short outcend

outch1  label   near
	call    ComOut

outcend label   near
        pop     ax
        ret
OutChar endp


	subttl	GetMsg - Gets string from console and echos
        page
;-------------------------------------------------------------------------;
;       Function: GetMsg                                                  ;
;            Gets a message terminated by a Carriage Return               ;
;       Input:                                                            ;
;            DS = Segment to place string at                              ;
;            SI = Offset to place string at                               ;
;            CX = Max # of characters to retrieve                         ;
;       Output:                                                           ;
;            CX - # of chararacters retrieve                              ;
;-------------------------------------------------------------------------;

GetMsg  proc    near
        push    dx
        push    si
        push    bp

        mov     bp, cx
        push    ax
        push    di
        push    es

        push    cs
        pop     es
        mov     di, si
        shr     cx, 1           ; words
        xor     ax, ax
        rep     stosw           ; clear buffer

        pop     es
        pop     di
        pop     ax
        xor     cx, cx
	
gmsg1   label   near
        call    GetKey           ; get a key
	or      al, al
	jnz     gmsg1a
	call	GetKey		 ; get extended key
	cmp     [dbaddr], SCREEN
	je      doscr
	cmp     al, 'B'		 ; F3? from console
	je      dof3
	jmp     gmsg1

doscr   label   near
	cmp     al, '='		 ; F3?
	je	dof3
	cmp     al, 75		; cursor left
	jne     doscr1
	mov	al, 8		; backspace
	jmp	gmsg1a		; do character

doscr1  label	near
	cmp	al, 77		; cursor right
	jne     doscr2
	mov	al, ' '		; space
	jmp	gmsg1a

doscr2	label   near

donull  label   near
	jmp	gmsg1

dof3    label   near
	cmp     cl, [lenbkp]     ; greater than lenght of prevous buffer
	jae     gmsg1
	push    dx
	push    di
	push    es
	push    cs
	pop     es
	xchg    si, di
	lea     si, buffbkp	; get offset of backup
	add     si, cx		; point to next position
		
dof3lp  label   near
	lodsb			; transfer byte
	mov     dl, al
	call    OutChar		; display character
	stosb
	inc     cx
	cmp     cl, [lenbkp]    ; compare lenght
	jb      dof3lp
	xchg    si, di
	pop     es
	pop     di
	pop     dx
	jmp     short gmsg1

gmsg1a  label   near
	cmp     al, 09h		 ; tab
	jne     gmsg1b
	mov	al, ' '
	
gmsg1b  label   near
	cmp     al, 0AH          ; line feed
	je      gmsg1
        cmp     al, 0DH          ; carriage return
        je      gmsgend          ; exit
        cmp     al, 8            ; backspace
        jne     gmsg2            ; no...next
        or      cx, cx           ; begining of buffer
        je      gmsg1            ; next...char
        dec     cx
        dec     si               ; decrement counters
        mov     byte ptr [si], 0
        lea     dx, rubout
        call    OutMsg
        jmp     short gmsg1      ; next...char

gmsg2   label   near	
        cmp     cx, bp           ; endof buffer
	jb      gmsg3
        jmp     gmsg1

gmsg3   label	near
        mov     byte ptr [si], al
        mov     dl, al
        call    OutChar          ; output character
        inc     cx
        inc     si               ; increment counter
        jmp     gmsg1            ; next...char

gmsgend label   near
        pop     bp
        pop     si
        add     si, cx
        mov     byte ptr [si], 0
        sub     si, cx
        lea     dx, crlf
        call    OutMsg          ; Output a carriage return linefeed
        pop     dx
        ret
GetMsg  endp

	subttl	OUTTEXT - Output debug info 
        page
;-----------------------------------------------------------------;
;	Function: OUTTEXT					  ;
;	Input:							  ;
;		dx: string to send				  ;
;-----------------------------------------------------------------;
OutText proc	near
	cmp	[dbaddr],SCREEN	; main console
	je      OutMC
	jmp	OutTerm
OutMC:
	push    bx
	push    cx
	push    dx
	push    si
	push    bp
	push    es

	mov	si,dx
	xor     cx,cx
Outtlp1:
	lodsb
	or      al,al
	jz      Outtend1
	inc     cx
	jmp	short Outtlp1
Outtend1:
	or      cx,cx
	jz      Outtskip
	mov	bp,dx
	push    cx
	push    bp
	mov	ah,03
	xor     bh,bh
	int     10h
	pop	bp
	pop	cx
	push    ds
	pop	es
	mov	ax,1300h		; fast screen write
	mov     bx,7			; normal attribute
	int     10h			; write string for speed
Outtskip:
	pop	es
	pop	bp
	pop	si
	pop	dx
	pop	cx
	pop	bx
	ret
OutTerm:
	push    dx
	push    si
	mov	si,dx
OutLP:
	lodsb
	or      al,al
	jz      OutEND
	mov	dl,al
	call	OutChar
	jmp     short OutLP
OutEND:
	pop	si
	pop	dx
	ret
OutText endp

	subttl	OutMsg outputs $ ended message
        page
;-------------------------------------------------------------------------;
;       Function: OutMsg                                                  ;
;             Sends a Message Out to console terminated by a $            ;
;       Input:                                                            ;
;            DS = Segment to where string is                              ;
;            DX = Offset to where string is                               ;
;       Output:                                                           ;
;-------------------------------------------------------------------------;

OutMsg  proc    near
        push    ax

        cmp     [dbaddr], SCREEN ; Main Console (SWAP MODE)
        jne     outmg1
        mov     ah, 9
        int     21h
        jmp     outmend

outmg1  label   near

;       output string across comport

        push    si
        push    dx
        mov     si, dx
        assume  ds:moss

outmg2  label   near
        lodsb
        cmp     al, '$'
        je      outmg7
	mov     dx, [dbaddr]
	dec     dx
	mov     ah, 1
	int     14h
	jmp     short outmg2
	
outmg7  label   near
        pop     dx
        pop     si

outmend label   near
        pop     ax
        ret
OutMsg  endp

        page
;-------------------------------------------------------------------------;
;       Function: ComOut                                                  ;
;       Input:                                                            ;
;            DL = Chararcter to send to port                              ;
;       Output:                                                           ;
;-------------------------------------------------------------------------;

ComOut  proc    near
        push    dx
        push    ds
        push    si

        push    cs
        pop     ds
        mov     byte ptr [blank1], dl
        lea     dx, blank1       ; output as characte and $ string
        call    OutMsg
        mov     byte ptr [blank1], ' '

        pop     si
        pop     ds
        pop     dx
        ret
ComOut  endp

;-------------------------------------------------------------------------;
moss    ends

        if1
                %out   Pass 1   Completed.
        else
                %out   Pass 2   Completed.
        endif


        end
