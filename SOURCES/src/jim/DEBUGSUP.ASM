	include page.inc
	title DEBUGSUP.ASM - MOS DEBUG Support Routines
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
;-----------------------------------------------------------------------;
;	07/23/87	SAH 	Misc cleanup and Maintinance		;
;-----------------------------------------------------------------------;
;	08/13/87	SAH     Corrected SIZEMEM for shell		;
;-----------------------------------------------------------------------;
;       08/20/87        SAH     Corrected loading parameters for prgs   ;
;-----------------------------------------------------------------------;
;       09/11/87	SAH	Corrected problem manully loading files ;
;-----------------------------------------------------------------------;
;	10/20/87  	SAH	Corrected problem with loading and 2nd  ;
;				fcb which jsm notice			;
;-----------------------------------------------------------------------;
;	12/10/87	SAH     Corrected problem with comments in asm  ;
;				file					;
;-----------------------------------------------------------------------;
;	01/06/88	SAH	Corrected problem with cmp reg,reg      ;
;				being backwords				;
;-----------------------------------------------------------------------;
;	02/08/88	SAH	Correct problem with ENTER (GetList)    ;
;				Corrected problem with offset between   ;
;				80 and ff (hex)				;
;-----------------------------------------------------------------------;
;	03/02/88	SAH	Corrected load command return to MOS	;
;				Corrected jmp $+5 error in assembly	;
;-----------------------------------------------------------------------;
;	09/08/88	RKG	Misc Cleanup and internal name change	;
;-----------------------------------------------------------------------;
;	12/09/88	SAH	Corrected db 'd' sititusation		;
;				correct some instruction incoding.	;
;-----------------------------------------------------------------------;
;	02/20/89	SAH	Corrections for MASM 5.10		;
;-----------------------------------------------------------------------;
;	08/08/89	SAH	Corrections for MOV instruction 	;
;-----------------------------------------------------------------------;
; 	04/26/90	SAH	Corrections for loading large programs	;
;-----------------------------------------------------------------------;

        if1
		%out   Pass 1	Started.
        else
                %out   Pass 2   Started.
        endif

        page
        include debugsup.pub


        page
extrn   GetMsg:near, OutMsg:near, OutChar:near, GetKey:near
extrn   funct:word, op8283:word, opf6:word
extrn   opf7:word, opfe:word, opff:word, opptr:near, op80:near, op81:near
extrn   opd0d1:near, opd2d3:near, Term:near, SetBrk:near
extrn   valsi:word, valdi:word, regall:word, cmdtab:word, valbx:word
extrn   regcs:word, regip:word, regss:word, regsp:word, regds:word, reges:word
extrn   asmloc:word, uasmloc:word, dumploc:word, allias:word, regtran:word
extrn   SaveOff:word, regflag:word, regbx:word, regcx:word, regax:word
extrn   old22:word, regdb:word, wrloc:word,retflag:word,getsi:word,envseg:word
extrn   lastop:word, map1718:word, map10:word, seabx:word, regdx:word
extrn   regsi:word, regdi:word, regbp:word, map10a:word, childpsp:word
extrn   shrink:word, debugpsp:word, notall:byte
extrn   lenbuff:byte, buff:byte, cdirlen:byte, asmarea:byte, RegType:byte
extrn   current:byte, fnfmsg:byte, flagbuf:byte,  crlf:byte, syntax:byte
extrn   opbuff:byte, path:byte, hextab:byte, nommsg:byte, robal:byte
extrn   ropax:near, ropsreg:byte, ropbx:byte, ropdx:byte, ropbp:byte
extrn   ropsi:byte, ropdi:byte, rop1:byte, rop2:byte, parmblk:byte
extrn   modbyte:byte, modword:byte, modfar:byte, optab:byte, rubout:byte
extrn   opadc:byte, opadd:byte, opand:byte, opcall:byte, opcmp:byte
extrn   opdb:byte, opdiv:byte, opesc:byte, opidiv:byte, opimul:byte
extrn   opin:byte, opinc:byte, opdec:byte, opint:byte, opjmp:byte
extrn   opmov:byte, opmul:byte, opneg:byte, opnot:byte, opor:byte
extrn   opout:byte, oppop:byte, oppush:byte, opret:byte, opretf:byte
extrn   opsbb:byte, opsub:byte, optest:byte, opxchg:byte, opxor:byte
extrn   oprol:byte, opror:byte, oprcl:byte, oprcr:byte, opshl:byte
extrn   opshr:byte, opsar:byte, rmtab:byte, exeflag:byte, maxmem:word
extrn   lasterr:byte, nfile:byte, getbuff:byte, buffbkp:byte
extrn   regmsg:byte, lenbkp:byte, isload:byte, segflag:byte
extrn   intern:byte, badop:byte, rdmsg:byte, AllMem:byte, fullload:byte

        if      0 eq 0
cmdlen  equ       0027H

        page
RAX     equ         10h
RCX     equ         20h
RDX     equ         30h
RBX     equ         40h
RSP     equ         50h
RBP     equ         60h
RSI     equ         70h
RDI     equ         80h
RES     equ         0A0h
RCS     equ         0B0H
RSS     equ         0C0H
RDS     equ         0D0H
RAL     equ         01h
RDL	equ	    03h
RBL     equ         04h
RAH     equ         05h
RCH     equ         06h
RDH     equ         07h
RBH     equ         08h
NOREG   equ         00h
        endif

        page
;-------------------------------------------------------------------------;
;       Macro:    makech                                                  ;
;                 sends char to pointer specify by di and icrements di    ;
;       Input:    char to be stored                                       ;
;       Output:                                                           ;
;-------------------------------------------------------------------------;

makech  macro   value
        mov     byte ptr [di], value
        inc     di
        endm


;-------------------------------------------------------------------------;
;       Macro:    getareg                                                 ;
;                 gets a register value from translation to ax            ;
;-------------------------------------------------------------------------;

getareg macro
        push     bx
        mov      bx, word ptr [bx+regtran]
        mov      ax, word ptr [bx+regall]
        pop      bx
        endm

        page

moss    segment word public 'code'
        assume cs:moss;ds:moss;es:moss

        even
dopfun  label   word
        dw      offset dop00    ; 00  mem/reg, reg
        dw      offset dop01    ; 01  reg, mem/reg
        dw      offset dop02    ; 02  Al, kk
        dw      offset dop03    ; 03  AX, jjkk
        dw      offset dop04    ; 04  stack reg
        dw      offset dop05    ; 05  stack segment reg
        dw      offset dop06    ; 06  16 bit address (constant)
        dw      offset dopret   ; 07  seg:
        dw      offset dop08    ; 08  shift reg,mem, 1
        dw      offset dop09    ; 09  shift reg,mem, cl
        dw      offset dop0a    ; 0A  conditional jump
        dw      offset dop0b    ; 0B  near call or jmp
        dw      offset dop0c    ; 0C  far call or jmp
        dw      offset dopret   ; 0D      
        dw      offset dop0e    ; 0E  mem/reg
        dw      offset dop0f    ; 0F  mem/reg
        dw      offset dop10    ; 10  register operation (byte)
        dw      offset dop11    ; 11  mem/reg, kk
        dw      offset dop12    ; 12  mem/reg, jjkk
        dw      offset dop13    ; 13  register operation (word)
        dw      offset dop14    ; 14  reg, addr
        dw      offset dop15    ; 15  mem/reg, segreg
        dw      offset dop16    ; 16  segreg, mem/reg
        dw      offset dopret   ; 17  reg, reg  (byte)
        dw      offset dop18    ; 18  AL, BYTE PTR [addr]
        dw      offset dop19    ; 19  AX, WORD PTR [addr]
        dw      offset dop1a    ; 1A  BYTE PTR [addr], AL
        dw      offset dop1b    ; 1B  WORD PTR [addr], AX
        dw      offset dop1c    ; 1C  reg,kk    (byte)
        dw      offset dop1d    ; 1D  reg,jjkk  (word)
        dw      offset dop1e    ; 1E  INT  3
        dw      offset dop1f    ; 1F  INT  kk   (DB XX)
        dw      offset dopret   ; 20
        dw      offset dop21    ; 21  AL, KK
        dw      offset dop22    ; 22  AX, KK
        dw      offset dop23    ; 23  KK, AL
        dw      offset dop24    ; 24  KK, AX
        dw      offset dop25    ; 25  AL, DX
        dw      offset dop26    ; 26  AX, DX
        dw      offset dop27    ; 27  DX, AL
        dw      offset dop28    ; 28  DX, AX
        dw      offset dopret   ; 29
        dw      offset dop2a    ; 2A  reg, reg (word)
        dw      offset dop2b    ; 2B  DB XX
        dw      offset dop2c    ; 2C  FAR mem/reg
        dw      offset dopret   ; 2D

        even                                                   ; Author Notes
mopfun  label   word
        dw      offset mop00    ; 00  mem/reg, reg
        dw      offset mop01    ; 01  reg, mem/reg
        dw      offset mop21    ; 02  Al, kk  (same as 21)
        dw      offset mop03r   ; 03  AX, jjkk
        dw      offset mopret   ; 04  stack reg
        dw      offset mopret   ; 05  stack segment reg
        dw      offset mop03    ; 06  16 bit address (constant)
        dw      offset mopret   ; 07  seg:
        dw      offset mop0809  ; 08  shift reg,mem, 1
        dw      offset mop0809  ; 09  shift reg,mem, cl
        dw      offset mop0a    ; 0A  conditional jump
        dw      offset mop0b    ; 0B  near call or jmp
        dw      offset mop0c    ; 0C  far call or jmp
        dw      offset mopret   ; 0D  
        dw      offset mop0e    ; 0E  mem/reg
        dw      offset mop0f    ; 0F  mem/reg
        dw      offset mop10    ; 10  register operation (byte)
        dw      offset mop11    ; 11  mem/reg, kk
        dw      offset mop12    ; 12  mem/reg, jjkk
        dw      offset mopret   ; 13  register operation (word)
        dw      offset mop14    ; 14  reg, addr
        dw      offset mop15    ; 15  mem/reg, segreg
        dw      offset mop16    ; 16  segreg, mem/reg
        dw      offset mopret   ; 17  reg, reg  (byte)
        dw      offset mop18    ; 18  AL, BYTE PTR [addr]
        dw      offset mop18    ; 19  AX, WORD PTR [addr]
        dw      offset mop18    ; 1A  BYTE PTR [addr], AL
        dw      offset mop18    ; 1B  WORD PTR [addr], AX
        dw      offset mop21    ; 1C  reg,kk    (byte)
        dw      offset mop03r   ; 1D  reg,jjkk  (word)
        dw      offset mopret   ; 1E  INT  3
        dw      offset mop1f    ; 1F  INT  kk   (DB XX)
        dw      offset mop20    ; 20  double opcodes 
        dw      offset mop21    ; 21  AL, KK  
        dw      offset mop21    ; 22  AX, KK  (same as 21)
        dw      offset mop1f    ; 23  KK, AL  (same as 1f)
        dw      offset mop1f    ; 24  KK, AX  (same as 1f)
        dw      offset mopret   ; 25  AL, DX
        dw      offset mopret   ; 26  AX, DX
        dw      offset mopret   ; 27  DX, AL
        dw      offset mopret   ; 28  DX, AX
        dw      offset mopret   ; 29
        dw      offset mopret   ; 2A  reg, reg (word)
	dw	offset mop1fa	; 2B  DB XX (same as 1F)
        dw      offset mopea    ; 2C  FAR mem/reg
        dw      offset mopret   ; 2D

        page
findtab label   word
        dw      offset opadc
        dw      offset fd17
        dw      offset opadd
        dw      offset fd17
        dw      offset opand
        dw      offset fd18
        dw      offset opcall
        dw      offset fd2
        dw      offset opcmp
        dw      offset fd17
        dw      offset opdb
        dw      offset fd3
        dw      offset opdiv
        dw      offset fd4
        dw      offset opesc
        dw      offset fd5
        dw      offset opidiv
        dw      offset fd4
        dw      offset opimul
        dw      offset fd4
        dw      offset opin
        dw      offset fd6
        dw      offset opinc
        dw      offset fd7
        dw      offset opdec
        dw      offset fd7
        dw      offset opint
        dw      offset fd8
        dw      offset opjmp
        dw      offset fd9
        dw      offset opmov
        dw      offset fd10
        dw      offset opmul
        dw      offset fd4
        dw      offset opneg
        dw      offset fd4
        dw      offset opnot
        dw      offset fd4
        dw      offset opor
        dw      offset fd18
        dw      offset opout
        dw      offset fd11
        dw      offset oppop
        dw      offset fd13
        dw      offset oppush
        dw      offset fd12
        dw      offset opret
        dw      offset fd14
        dw      offset opretf
        dw      offset fd14
        dw      offset opsbb
        dw      offset fd17
        dw      offset opsub
        dw      offset fd17
        dw      offset optest
        dw      offset fd15
        dw      offset opxchg
        dw      offset fd1
        dw      offset opxor
        dw      offset fd18
        dw      offset oprol
        dw      offset fd16
        dw      offset opror
        dw      offset fd16
        dw      offset oprcl
        dw      offset fd16
        dw      offset oprcr
        dw      offset fd16
        dw      offset opshl
        dw      offset fd16
        dw      offset opshr
        dw      offset fd16
        dw      offset opsar
        dw      offset fd16
        dw      0
        dw      0


        even
tab17   label   word
        dw      offset fd171
        dw      offset fd171
        dw      offset fd172
        dw      offset fd173
        dw      offset fd173
        dw      offset fd174
        dw      offset fd175
        dw      offset fd176
        dw      offset fd80
        dw      offset fd80
        dw      offset fd8183
        dw      offset fd8183

tab18   label   word
        dw      offset fd181
        dw      offset fd181
        dw      offset fd182
        dw      offset fd183
        dw      offset fd183
        dw      offset fd184
        dw      offset fd185
        dw      offset fd186
        dw      offset fd80
        dw      offset fd80
        dw      offset fd81
        dw      offset fd81

tab15   label   word
        dw      offset fd151
        dw      offset fd151
        dw      offset fd15bad
        dw      offset fd153
        dw      offset fd153
        dw      offset fd15bad
        dw      offset fd155
        dw      offset fd156
        dw      offset fd157
        dw      offset fd157
        dw      offset fd158
        dw      offset fd158

tab10   label   word
        dw      offset fd105
        dw      offset fd106

tab10a  label   word
        dw      offset fd1011
        dw      offset fd1011
        dw      offset fd1012
        dw      offset fd1012
        dw      offset fd101
        dw      offset fd102
        dw      offset fd101
        dw      offset fd103
        dw      offset fd104
        dw      offset fd103
        dw      offset fd107            ; uses shorter form
        dw      offset fd109              
        dw      offset fd108            ; uses shorter form
        dw      offset fd1010



        page
;-------------------------------------------------------------------------;
;       MOS Debug Support Routines
;-------------------------------------------------------------------------;

;-------------------------------------------------------------------------;
;       Function: GetCmd                                                  ;
;                 retrive a command from user and places the parameters   ;
;                 into parameter storage buffer and return a unique       ;
;                 function code back to the caller                        ;
;       Input:    none                                                    ;
;       Output:                                                           ;
;                 bl = function                                           ;
;                 bh = error idicate (0 = no errors)                      ;
;-------------------------------------------------------------------------;

GetCmd  proc    near
        push    ax
        push    cx
        push    si
        push    di

        mov     bx, 2020h
        mov     [funct], bx     ; clear function id
        lea     si, buff
        mov     cx, 80
        call    GetMsg
        mov     [lenbuff], cl
        xor     bx, bx
        or      cl, cl
        jz      get2

        mov     [lenbkp], cl            ; make backup for f3
        lea     si, buff
        lea     di, buffbkp
        xor     ch, ch
        push    cx
        push    es
        push    cs
        pop     es
        push    cx
        xor     ax, ax
        mov     cx, 39
        rep     stosw
        pop     cx
        lea     di, buffbkp
        rep     movsb             ; save a backup copy
        pop     es
        pop     cx

        call    FixBuff
        mov     ax, [funct]
        lea     di, cmdtab
        mov     cx, cmdlen
        repnz   scasw
        or      cx, cx
        jnz     get1
        mov     ax, [funct]
        mov     ah, ' '
        lea     di, cmdtab
        mov     cx, cmdlen
        repnz   scasw
        mov     bh, 1
        or      cx, cx
        jz      get2

get1:
        mov     bx, cmdlen-1
        sub     bx, cx
        xor     bh, bh

get2:
        pop     di
        pop     si
        pop     cx
        pop     ax
        ret
GetCmd  endp


        page
;-------------------------------------------------------------------------;
;       Function: GetOp                                                   ;
;                 Places Assemble Code into memory.                       ;
;       Input:                                                            ;
;                   SI = Offset where to store instruction                ;
;                   ES = Segment where to store instruction               ;
;       Output:                                                           ;
;                   BL = (1 = No Code Enter) 0 = code enter               ;
;                   BH = (0 = No errors)  otherwise errors                ;
;                   SI = Offset of next instruction                       ;
;                   ES = Segment of next instruction                      ;
;-------------------------------------------------------------------------;

GetOp   proc       near
        push       cx
        mov        [getsi], si                  ; perserved original offset

;       display    address to user

        push       dx
        push       di
        push       es
        
        mov        bx, si
        lea        di, asmarea
        mov        ax, es
        mov        cl, 1
        push       cs
        pop        es
        call       MakeHex
        inc        di
        mov        ax, bx
        call       MakeHex
        lea        dx, asmarea  ; display address for instrunction
        call       OutMsg
        pop        es
        pop        di
        pop        dx

;       Get Command Line from user

        push       si
        lea        si, buff
        mov        cx, 80       ; get command line
        call       GetMsg
        mov        [lenbuff], cl
        xor        bx, bx

        mov        [lenbkp], cl      ; make backup for F3
        lea        si, buff
        lea        di, buffbkp
        xor        ch, ch
        push       cx
        push       es
        push       cs
        pop        es
        push       cx
        xor        ax, ax
        mov        cx, 39
        rep        stosw
        pop        cx
        lea        di, buffbkp
        rep        movsb             ; save a backup copy
        pop        es
        pop        cx

        call       FixBuff      ; adjust buffer to uppercase
        pop        si
        cmp        byte ptr [lenbuff], 0
        jne        gopdo
        mov        bx, 1                ; no error and exit
        jmp        gopend

gopdo   label      near
        xor        bx, bx
        call       RemSpac      ; rem spaces
	cmp	   byte ptr [bx+buff],';'	; SAH check for comment
	jne	   gopdo1			; SAH no...skip
	xor	   bx,bx			; SAH no errors
	jmp	   gopend			; SAH get out
        
gopdo1  label      near 
        call       ScanMen      ; scan for desired menonic
        or         bx, bx
	jnz	   goperr	

gopsok  label      near
        mov        bx, cx
        cmp        si, offset opdb
	jne	   gopndb
	call	   RemSpac
	cmp	   byte ptr [bx+buff],27h
	je	   gopxdb
        mov        cx, 2
        call       GetHex       ; get byte
        or         bx, bx
        jz         goperr
        mov        di, [getsi]
        stosb
        mov        si, di
        xor        bx, bx
        jmp        short gopend 

gopxdb:
	push	   cx
	push	   si
	push	   es
	mov	   cl,[lenbkp]
	xor	   ch,ch
	lea	   si,buffbkp
	lea	   di,buff
	push	   cs
	pop	   es
	rep	   movsb
	pop	   es
	pop	   si
	pop	   cx
	mov	   di,[getsi]
	mov	   [valbx],bx
	call	   mop1fa	; make the opcodes
	jmp	   gopmok


gopndb  label      near
        mov        [valbx], bx  ; save bx for make op

gopfnd  label      near
        call       FindOp       ; Find Opcode for operation
gopfend label      near

        mov        si, [getsi]
        cmp        bx, 0ffffh
	je	   goperr

gopfok  label      near
        xchg       si, di
        call       MakeOp       ; create memory image of instruction
        or         bx, bx
	jnz	   goperr

gopmok  label      near
        xchg       si, di
        jmp        short gopend

goperr  label      near
        mov        si, [getsi]          ; get original location if error
        mov        bx, 0A00H

gopend  label      near 
        pop        cx
        ret
GetOp   endp

        page
;-------------------------------------------------------------------------;
;       Function: FixBuff                                                 ;
;                 Places Buffer in Upper Case and removes trailing blanks ;
;       Input:                                                            ;
;                 BX - OFFSET int buffer                                  ;
;       Output:                                                           ;
;-------------------------------------------------------------------------;

FixBuff proc    near
        push    ax
        push    bx
        push    cx
        or      cx, cx
        jz      fix4
        push    bx
        add     bx, cx
        dec     bx

fxloop:
        cmp     byte ptr [bx+buff], ' '
        jne     fxdone
        dec     bx
        dec     cx
        or      cx, cx
        jnz     fxloop

fxdone:
        mov     [lenbuff], cl
        pop     bx
        or      cx, cx
        jz      fix4

fixloop:
        mov     al, [bx+buff]
        cmp     al, 13
        je      fix0
        cmp     al, 10
        jne     fix1

fix0:
        mov     al, ' '
        jmp     fix2

fix1:
        cmp     al, 'a'
        jb      fix3
        cmp     al, 'z'
        ja      fix3
        sub     al, 'a'-'A'

fix2:
        mov     [bx+buff], al

fix3:
        inc     bx
        loop    fixloop

fix4:

        pop     cx
        pop     bx
        pop     ax
        ret
FixBuff endp

        page
;-------------------------------------------------------------------------;
;       Function: ScanMen                                                 ;
;       Input:                                                            ;
;                 BX = Position in Buffer to start                        ;
;       Output:                                                           ;
;                 BX = error Position (0 if None Available)               ;
;                 CX = Offset in buffer for operands                      ;
;                 SI = Offset to Instruction Menonic Structure            ;
;-------------------------------------------------------------------------;

ScanMen proc      near
        push      ax
        push      dx
        push      bp
        push      di
        push      es

        call      RemSpac
        mov       bp, bx
        xor       cx, cx

smchk   label     near
        mov       al, byte ptr [bx+buff]
        cmp       al, ' '
        je        sminit
        or        al, al
        jz        sminit
        cmp       cl, 10
        ja        smenend
        inc       bx
        inc       cx
        jmp       short smchk

sminit  label     near
        or        cx, cx
        jz        smenend
        mov       [valbx], bx
        mov       bx, bp
        mov       di, bp
        add       di, offset buff
        lea       si, optab
        mov       dx, cx
        push      cs
        pop       es

smloop  label     near
        mov       bp, si
        xor       ax, ax
        lodsb
        or        al, al
        jz        smenend
        cmp       al, cl
        jne       smlp1
        push      si
        push      di
        inc       cx
        repe      cmpsb
        pop       di
        pop       si

smlp1   label     near
        add       si, ax
        or        cx, cx
        jz        smfound
        mov       cx, dx
        jmp       short smloop

smfound label     near
        push      si
        lea       si, allias    ; search for allias items

smfnd1  label     near
        lodsw
        or        ax, ax        ; end of list
        jz        smfnd3
        cmp       ax, bp
        je        smfnd2
        lodsw
        jmp       short smfnd1

smfnd2  label     near
        lodsw                   ; alias found
        mov       bp, ax

smfnd3  label     near
        pop       si
        mov       si, bp
        xor       bp, bp

smenend label     near
        mov       bx, bp
        mov       cx, [valbx]

        pop       es
        pop       di
        pop       bp
        pop       dx
        pop       ax
        ret
ScanMen endp

        page
;-------------------------------------------------------------------------;
;       Function: ValType                                                 ;
;                 determines input value type after comma                 ;
;       Input:                                                            ;
;                 BX = Offset of input line                               ;
;       Output:                                                           ;
;                 BX = 0 = error                                          ;
;                 CX = 0 = byte value (under 256) or 1 = word value       ;
;-------------------------------------------------------------------------;

ValType proc    near
        push    ax

        call    ScanCom                 ; scan for comma
        or      bx, bx
        jz      vtend                   ; no comma (too bad)
        mov     cx, 4
        call    GetHex                  ; get value
        or      bx, bx
        jz      vtend                   ; no value (too bad)
        xor     cx, cx                  ; indicate byte
        or      ah, ah                  ; word value??
        jz      vtend                   ; no...
        inc     cx                      ; indicate word

vtend:
        pop     ax
        ret
ValType endp

        page
;-------------------------------------------------------------------------;
;       Function: FindMap                                                 ;
;                 scans map table terminated by 0 to map associated with  ;
;                 text enter.                                             ;
;                      0 = AL            Detected                         ;
;                      1 = AX            Detected                         ;
;                      2 = BYTE REG      Detected                         ;
;                      3 = WORD REG      Detected                         ;
;                      4 = SEG  REG      Detected                         ;
;                      5 = BYTE PTR []   Detected                         ;
;                      6 = WORD PTR []   Detected                         ;
;                      7 = []            Detected                         ;
;       Input:                                                            ;
;                 AX = map to find                                        ;
;                 BX = Offset of map table                                ;
;       Output:                                                           ;
;                 BX = Offset of entry (*2 for jump table)(ffff if errors);
;-------------------------------------------------------------------------;

FindMap proc    near
        push    ax
        push    cx
        push    dx
        push    si

        mov     dx, ax          ; place map in work register
        mov     si, bx
        xor     cx, cx          ; zero counter

fmloop:
        lodsw
        or      ax, ax          ; end of table (too bad)
        jz      fmerr
        mov     bx, dx
        and     bx, ax
        cmp     bx, ax          ; is this a match
        je      fmfound
        inc     cx              ; nop... increment counter
        jmp     short fmloop

fmerr:
        mov     bx, -1
        jmp     short fmdone

fmfound:
        mov     bx, cx
        shl     bx, 1

fmdone:
        pop     si
        pop     dx
        pop     cx
        pop     ax
        ret
FindMap endp

        page
;-------------------------------------------------------------------------;
;       Function: Map                                                     ;
;                 scans assembly text and generates the following bitmap  ;
;                      0 = AL            Detected                         ;
;                      1 = AX            Detected                         ;
;                      2 = BYTE REG      Detected                         ;
;                      3 = WORD REG      Detected                         ;
;                      4 = SEG  REG      Detected                         ;
;                      5 = BYTE PTR []   Detected                         ;
;                      6 = WORD PTR []   Detected                         ;
;                      7 = []            Detected                         ;
;       Input:                                                            ;
;                 BX = Offset of buffer                                   ;
;       Output:                                                           ;
;                 AL = Map generated for operand2 (right most)(see above) ;
;                 AH = Map generated for operand1 (left  most)(see above) ;
;                 BX = Offset of Table Entry  (0 is ERRORS)               ;
;-------------------------------------------------------------------------;

Map     proc      near
        push      dx

        xor       dx, dx
        call      MapScan       ; generate first map
        or        bx, bx
        jz        mapdone
        mov       dh, al        ; save map
        call      ScanCom
        or        bx, bx
        jz        mapdone
        call      MapScan       ; generate second map
        or        bx, bx
        jz        mapdone
        mov       dl, al

mapdone label     near
        mov       ax, dx
        pop       dx
        ret
Map     endp

        page
;-------------------------------------------------------------------------;
;       Function: MapScan                                                 ;
;                 scans assembly text and generates the following bitmap  ;
;                      0 = AL            Detected                         ;
;                      1 = AX            Detected                         ;
;                      2 = BYTE REG      Detected                         ;
;                      3 = WORD REG      Detected                         ;
;                      4 = SEG  REG      Detected                         ;
;                      5 = BYTE PTR []   Detected                         ;
;                      6 = WORD PTR []   Detected                         ;
;                      7 = []            Detected                         ;
;       Input:                                                            ;
;                 BX = Offset of buffer                                   ;
;       Output:                                                           ;
;                 AL = Map generated    (see above)                       ;
;                 BX = Offset of Table Entry  (0 is ERRORS)               ;
;-------------------------------------------------------------------------;

MapScan proc    near
        call    RemSpac
        or      bx, bx
        jnz     ms0
        ret

ms0:
        mov     ax, word ptr [bx+buff]  ; get first byte
        cmp     ax, 'YB'
        jne     ms1
        mov     al, 0a0h        ; indicate bits  5 & 7  (BYTE PTR [])
        ret

ms1:
        cmp     ax, 'OW'
        jne     ms2
        mov     al, 0c0h        ; indicate bits  6 & 7  (WORD PTR [])
        ret

ms2:
        cmp     al, '['
        jne     ms3
        mov     al, 080h        ; indicates bits  7     ([])
        ret

ms3:
        call    GetReg          ; test for register
        or      bx, bx
        jz      msbad           ;  not a register
        cmp     al, RAL
        jne     ms4
        mov     al, 5           ; indicates bits  0 & 2  (REG AL)
        ret

ms4:
        cmp     al, RAX
        jne     ms5
        mov     al, 0ah         ; indicate bits  1 & 3 (REG AX)
        ret

ms5:
        cmp     al, RES
        jb      ms6
        cmp     al, RDS
        ja      msbad
        mov     al, 10h         ; indicate bit 4    (SEG REG)
        ret

ms6:
        cmp     al, RAX
        jb      ms7
        cmp     al, RDI
        ja      msbad
        mov     al, 08          ; indicate bit 3    (WORD REG)
        ret

ms7:
        cmp     al, RAL
        jb      msbad
        cmp     al, RBH
        ja      msbad
        mov     al, 4           ; indicate bit 2    (BYTE REG)
        ret

msbad:
        or      bx, bx
        ret
MapScan endp

        page
;-------------------------------------------------------------------------;
;       Function: FindOp                                                  ;
;       Input:                                                            ;
;                 BX = Offset of buffer                                   ;
;                 SI = Offset to Instruction Menonic Structure            ;
;       Output:                                                           ;
;                 BX = Offset of Table Entry  (ffffh is ERRORS)           ;
;                 DX = Opcode   (error position if ERRORS)                ;
;-------------------------------------------------------------------------;

FindOp  proc    near
        push    ax
        push    cx
        push    si
        push    di
        push    bp

;	SAH 	check for errors
	
	push	bx
foplp:
	cmp	byte ptr [bx+buff],'$'
	je	foperr
	inc	bl
	cmp	bl,[lenbuff]
	jbe	foplp
	pop	bx
	jmp	fopcont
foperr:
	pop	bx
	jmp	fnd6
fopcont:

;	end of additions

        
        push    si
        mov     dx, si
        xor     cx, cx
        lea     si, opptr

fop1:
        lodsw
        lodsw
        cmp     ax, -1
        je      fop2
        cmp     ax, dx          ; is this the right one
        je      fop2
        inc     cx
        jmp     short fop1

fop2:
        mov     [lastop], cx
        pop     si
        
        xor     cx, cx
        mov     dx, bx
        xchg    si, di
        mov     bp, 0ffffh
        lea     si, findtab

fnd1:
        lodsw
        or      ax, ax          ; end of table
        jz      fnd3
        cmp     ax, di          ; same instruction
        je      fnd2
        inc     si
        inc     si
        jmp     short fnd1

fnd2:
        mov     bp, si

fnd3:
        lea     si, opptr

fnd4:
        lodsw
        lodsw
        mov     [SaveOff], ax   ; save offset pointer
        cmp     ax, 0ffffh      ; end of table
        je      fnd6
        cmp     ax, di          ; entry found
        jne     fnd4
        cmp     bp, 0ffffh
        je      fnd5
        push    bp                 ; save find call offset for next call
        mov     bx, si  
        sub     bx, offset opptr   ; calculate opcode (table offset / 4)
        shr     bx, 1
        dec     bx                 ; adjust for position        
        shr     bx, 1                           
        xchg    bx, bp             ; bp as opcode and bx has start position
        xor     ax, ax
        mov     [lastop], bp       ; save last opcode

fndcall:
        call    word ptr [bx]
fndret:

        pop     bp                 ; get find call offset
        or      ax, ax
        jnz     fnd4

fnd5:
;
;       no errors
;
        mov     dx, [lastop]   ; get last opcode (not intel's)  
        sub     si, 4          ; point to current block
        mov     bx, si
        mov     di, si
        sub     di, offset opptr
        shr     di, 1
        shr     di, 1
        jmp     short fnd7

fnd6:
;
;       errors
;
        mov     bx, 0ffffh

fnd7:

        pop     bp
        pop     di
        pop     si
        pop     cx
        pop     ax
        ret

        page
fd1:
        push    cx
        mov     bx, dx
        call    RegSize
        or      bx, bx
        jnz     fd1aa
        jmp     fd1e

fd1aa:
        cmp     ah, RAX         ; XCHG AX,...???
        jne     fd1b
        call    ScanCom         ; scan for comma
        or      bx, bx
        jnz     fd1ab
        jmp     fd1bad

fd1ab:
        call    RegSize
        or      bx, bx
        jz      fd1a
        cmp     al, 1           ; word register????
        jne     fd1a
        xchg    al, ah
        mov     cl, 4
        shr     al, cl
        dec     al
        and     al, 7
        add     al, 90h
        jmp     fd1cmp

fd1a:
        mov     al, 87h
        jmp     fd1cmp

        page
fd1b:
        cmp     al, 1           ; word register????
        jne     fd1d
        mov     [RegType], ah
        call    ScanCom
        or      bx, bx
        jz      fd1c
        call    GetReg
        or      bx, bx
        jz      fd1c
        cmp     al, RAX         ; mov WREG, AX????
        jne     fd1c
        mov     al, [RegType]
        mov     cl, 4
        shr     al, cl
        dec     al
        and     al, 7
        add     al, 90h
        jmp     fd1cmp

fd1c:
        mov     al, 87h
        jmp     fd1cmp

fd1d:
        or      al, al          ; byte register????
        jnz     fd1e
        mov     al, 86h
        jmp     fd1cmp

        page
fd1e:
        mov     bx, dx
        call    RemSpac         ; remove spaces
        or      bx, bx
        jz      fd1bad
        cmp     word ptr [bx+buff], 'YB'
        jne     fd1f
        mov     al, 86h
        jmp     fd1cmp

fd1f:
        cmp     byte ptr [bx+buff], 'W'
        jne     fd1g
        mov     al, 87h
        jmp     short fd1cmp

fd1g:
        cmp     byte ptr [bx+buff], '['
        jne     fd1bad
        call    ScanCom         ; scan for comma
        or      bx, bx
        jz      fd1bad
        call    RegSize         ; al is return 0  if byte, 1 if word
        or      bx, bx
        jz      fd1bad
        add     al, 86h

        page
fd1cmp:
        xor     ah,ah
        cmp     ax, bp
        jne     fd1bad
        xor     ax, ax
        jmp     short fd1done

fd1bad:
        mov     ax, 1

fd1done:
        pop     cx
        ret

        page
fd2:
        mov     bx, dx
        call    RemSpac         ; remove spaces
        or      bx, bx
        jz      fd2bad
        mov     ax, word ptr [bx+buff]
        cmp     ax, 'AF'
        jne     fd2nfar
        cmp     byte ptr [bx+buff+2], 'R'
        je      fd2far
        
fd2nfar:
        cmp     al, 'S'
        je      fd2bad
        cmp     al, 'N'
        je      fd2nr
        push    cx
        mov     cx, 4
        call    GetHex          ; get hex word (or byte)
        pop     cx
        or      bx, bx
        jz      fd2ea           ; must be effective address
        call    RemSpac         ; remove spaces
        or      bx, bx
        jz      fd2nr0           ; must be near call
        cmp     byte ptr [bx+buff], ':'
        jne     fd2nr0
        jmp     fd2far

fd2far:
        call    ScanSea
        or      bx, bx
        jnz     fd2far1

fd2far0:
        mov     ax, 09ah        ; CALL FAR
        jmp     fd2cmp

fd2far1:
        mov     ax, 0143h
        jmp     fd2cmp

fd2nr:
        call    ScanSea
        or      bx, bx
        jnz     fd2nr1

fd2nr0:
        mov     ax, 0e8h        ; CALL NEAR
        jmp     fd2cmp

fd2nr1:
        mov     ax, 142h
        jmp     fd2cmp

fd2ea:
        mov     ax, 0142h     ; CALL [...]

fd2cmp:
        cmp     ax, bp
        jne     fd2bad

fd2ok:
        xor     ax, ax
        ret

fd2bad:
        mov     ax, 1
        ret

        page
fd3:
        mov     bx, dx
        call    RemSpac
        or      bx, bx          ; end of buffer
        jz      fd3bad
        push    cx
        mov     cx, 2
        call    GetHex          ; get byte
        pop     cx
        or      bx, bx
        jz      fd3bad
        mov     bx, ax
        xor     bh, bh          ; zero out high byte
        xor     ax, ax          ; indicate ok
        cmp     bp, bx          ; test opcode DB XX
        je      fd3ok

fd3bad:
        mov     ax, 1           ; indicate error

fd3ok:
        ret

        page
fd4:
        mov     bx, dx
        call    GetReg
        cmp     al, NOREG
        je      fd4ea
        cmp     al, RDS         ; test for byte registers
        ja      fd4bad 
        cmp     al, RES         ; test for word registers
        jae     fd4bad
        cmp     al, RAX
        jb      fd4regb

fd4regw:            ; test for word registers
        xor     ax, ax
        cmp     bp, 0132h
        jb      fd4bad
        cmp     bp, 0137h
        ja      fd4bad
        jmp     short fd4ok

fd4regb:            ; test for byte register
        xor     ax, ax
        cmp     bp, 012Ah
        jb      fd4bad
        cmp     bp, 012FH
        ja      fd4bad
        jmp     short fd4ok

fd4bad:
        mov     ax, 1

fd4ok:
        ret

fd4ea:
        mov     bx, dx
        call    RemSpac         ; remove spaces
        or      bx, bx
        jz      fd4bad          ; error....
        mov     ax, word ptr [bx+buff]
        cmp     ax, 'YB'        ; test for BYTE PTR []
        je      fd4regb
        cmp     ax, 'OW'        ; test for WORD PTR []
        je      fd4regw
        jmp     short fd4bad


fd5:
        ret

        page
fd6:
        mov     bx, dx
        push    cx
        mov     cx, 00e4h       ; IN opcode series
        mov     bx, dx          ; get buffer position
        call    GetReg          ; get register
        cmp     al, RAX         ; is it [in ax,...]
        je      fd6ax
        cmp     al, RAL         ; is it [in al,...]
        je      fd6al
        jmp     short fd6err    ; error...

fd6ax:
        inc     cx              ; add 1 to indicate ax series

fd6al:
        call    RemSpac
        or      bx, bx
        jz      fd6err
        cmp     byte ptr [bx+buff], ','
        jne     fd6err
        inc     bx
        call    RemSpac
        or      bx, bx
        jz      fd6err
        push    bx
        call    GetReg          ; test for in ...,dx series
        pop     bx
        cmp     al, RDX
        je      fd6dx
        cmp     al, NOREG       ; not a register
        jne     fd6err          ; no..must be a shntax error
        push    cx
        mov     cx, 2           ; get a byte
        call    GetHex
        pop     cx
        or      bx, bx
        jnz     fd6ok           ; got it ok

fd6err:
        mov     bl, 1
        mov     ax, bx
        jmp     short fd6done

fd6dx:
        add     cl, 8           ; indicate in ...,dx series

fd6ok:
        mov     ax, 1
        xor     ch, ch
        cmp     cx, bp          ; is this the correct opcode
        jne     fd6done
        xor     ax, ax          ; indicate found

fd6done:
        pop     cx
        ret

        page
fd7:
        mov     bx, dx          ; get position
        call    GetReg
        cmp     al, NOREG
        je      fd7a
        mov     ah, al
        cmp     al, RAX
        jb      fd7bp
        and     al, 0f0h
        cmp     al, RDI
        ja      fd7err
        xor     ah, ah          ; clear high byte for compare
        push    cx
        mov     cl, 4
        shr     al, cl
        pop     cx
        dec     al
        or      ax, 0040h
        cmp     ax, bp
        je      fd7ok
        add     al, 8
        cmp     ax, bp
        je      fd7ok
        jmp     short fd7err

fd7a:
        mov     bx, dx
        call    RemSpac
        or      bx, bx
        jz      fd7err
        cmp     word ptr [bx+buff], 'OW'
        je      fd7wp
        cmp     word ptr [bx+buff], 'YB'
        jne     fd7err

fd7bp:
        mov     ax, 0138h               ; INC BYTE PTR [..]
        cmp     ax, bp
        je      fd7ok
        inc     ax                      ; DEC BYTE PTR [..]
        cmp     ax, bp
        je      fd7ok
        jmp     short fd7err

fd7wp:
        mov     ax, 0140h               ; INC WORD PTR [..]
        cmp     ax, bp
        je      fd7ok
        inc     ax                      ; DEC WORD PTR [..]
        cmp     ax, bp
        jne     fd7err

fd7ok:
        xor     ax, ax
        ret

fd7err:
        mov     al, 1
        ret

        page
fd8:
        push    cx
        mov     bx, dx
        mov     cl, 2
        call    GetHex          ; get byte of hex
        or      bx, bx
        jz      fd8err
        mov     ah, 1           ; indicate not found
        cmp     al, 3           ; INT 3???
        je      fd8int3
        cmp     bp, 0CDH        ; INT XX
        je      fd8ok
        jmp     short fd8done   ; not found

fd8int3:
        cmp     bp, 0CCH        ; int 3
        jne     fd8done         ; not found

fd8ok:
        xor     ax, ax          ; tag as ok
        jmp     short fd8done   ; found it

fd8err:
        mov     ax, 1

fd8done:
        pop     cx
        ret

        page
fd9:
        xor     ax, ax
        mov     bx, dx
        call    RemSpac         ; remove spaces
        or      bx, bx
        jz      fd9bad
        mov     ax, word ptr [bx+buff]
        cmp     al, 'S'         ; JMP SHORT
        je      fd9sh
        cmp     al, 'N'         ; JMP NEAR
        je      fd9nr
        cmp     ax, 'AF'         ; JMP FAR
        jne     fd9v
        cmp     byte ptr [bx+buff+2], 'R'
        je      fd9far

fd9v:
        push    cx
        mov     cx, 4
        call    GetHex          ; get word (byte)
        pop     cx
        or      bx, bx
        jz      fd9nea
        push    bx
        cmp     byte ptr [bx+buff], ':'
        je      fd9tfar
        mov     bx, ax
        sub     bx, 007fh
        cmp     [getsi], bx     ; test for lower than short limit
        jb      fd9tfar
        add     ax, 80h
        cmp     [getsi], ax     ; test for higher than short limit
        ja      fd9tfar
        pop     bx
        jmp     short fd9sh

fd9bad:
        mov     ax, 1
        ret

fd9tfar:
        pop     bx
        call    RemSpac         ; remove spaces
        or      bx, bx
        jz      fd9nr           ; must be JMP NEAR (no: )
        cmp     byte ptr [bx+buff], ':'
        je      fd9far

fd9nr:
        call    ScanSea         ; scan for [..]
        or      bx, bx
        jnz     fd9nea
        mov     bl, 0e9h        ; opcode for JMP NEAR
        jmp     short fd9cmp

fd9sh:
        mov     bl, 0ebh        ; opcode for JMP SHORT
        jmp     short fd9cmp

fd9far:
        call    ScanSea         ; scan for [...]
        or      bx, bx
        jnz     fd9ea
        mov     bl, 0eah        ; opcode for JMP FAR
        jmp     short fd9cmp

fd9nea:
        mov     bx, 0144h       ; opcode for JMP ....
        jmp     short fd9ecmp

fd9ea:
        mov     bx, 0145h       ; opcode for JMP FAR ....
        jmp     short fd9ecmp

fd9cmp:
        xor     bh, bh

fd9ecmp:
        xor     ax, ax
        cmp     bx, bp
        je      fd9done
        inc     ax

fd9done:
        ret

        page
fd10:
        mov     bx, dx
        call    Map             ; create map for test enter
        lea     bx, map10
        call    FindMap         ; map ok...
        cmp     bx, -1
        jz      fd10bad

comment |
        or      bx, bx
        jne     fd10x1
        call    vdirect         ; verify direct address
        or      ax, ax
        jz      fd10x2
        mov     bx, 10          ; indicate reg8 <- mem8
        jmp     fd10x2

fd10x1:
        cmp     bx, 2
        jne     fd10x2
        call    vdirect         ; verify direct address
        or      ax, ax
        jz      fd10x2
        mov     bx, 14          ; indicate reg16 <- mem16

fd10x2:
        |

        call    word ptr [bx+tab10]      ; call desired action from table
        or      al, al
        jnz     fd10nxt
        ret


fd10nxt:
        mov     bx, dx
        call    Map
        lea     bx, map10a
        call    FindMap
        cmp     bx, -1
        je      fd10bad
        call    word ptr [bx+tab10a]
        ret

fd10bad:
        mov     al, 1
        ret

fd101:
        mov     al, 88h
        jmp     fd10cmp

fd102:
        mov     al, 8ah
        jmp     fd10cmp

fd103:
        mov     al, 89h
        jmp     fd10cmp

fd104:
        mov     al, 8bh
        jmp     fd10cmp

fd105:
        call    vdirect
        or      al, al
        jnz     fd10bad
        mov     al, 0a0h
        jmp     fd10cmp

fd106:
        call    vdirect
        or      al, al
        jnz     fd10bad
        mov     al, 0a1h
        jmp     fd10cmp

fd107:
        mov     bx, dx
        call    GetReg
        cmp     al, RAL
        jb      fd10bd
        cmp     al, RBH
        ja      fd10bd
        add     al, 0afh        ; byte reg, xx
        xor     ah, ah  
        cmp     ax, bp
        jne     fd10bd
        xor     ax, ax
        ret

fd10bd:
        mov     al, 1
        ret

fd108:
        mov     bx, dx
        call    GetReg
        cmp     al, RAX
        jb      fd10bd
        cmp     al, RDI
        ja      fd10bd
        shr     al, 1
        shr     al, 1
        shr     al, 1
        shr     al, 1
        add     al, 0b7h        ; word reg, xxxx
        xor     ah, ah
        cmp     ax, bp
        jne     fd10bd
        xor     ax, ax
        ret

fd109:
        mov     al, 0c6h
        jmp     fd10cmp

fd1010:
        mov     al, 0c7h
        jmp     fd10cmp

fd1011:
        mov     al, 8ch
        jmp     fd10cmp

fd1012:
        mov     al, 8eh
        jmp     fd10cmp

fd10cmp:
        xor     ah, ah
        cmp     ax, bp
        je      fd10ok
        mov     al, 1
        ret

fd10ok:
        xor     al, al
        ret

vdirect:            ; verify that mov ax/al, [...]
        push    bx              ; is direct addressing
        push    dx
        mov     bx, [valbx]
        call    ScanSea
        dec     bx
        call    ScanEA
        xor     ax, ax
        cmp     dl, 10h
        je      vdir1
        inc     ax
        
vdir1:
        pop     dx
        pop     bx
        ret

        page
fd11:
        push    cx
        mov     bx, dx
        mov     cx, 00eeh       ; indicate out dx, al
        call    GetReg          ; test for out dx,... series
        cmp     al, RDX
        je      fd11dx
        cmp     al, NOREG       ; not a register
        jne     fd11err         ; no..must be a syntax error
        mov     bx, dx
        push    cx
        mov     cx, 2           ; get a byte
        call    GetHex
        pop     cx
        or      bx, bx
        jz      fd11err
        sub     cl, 8           ; out xx,.... series

fd11dx:
        call    RemSpac
        or      bx, bx
        jz      fd11err
        cmp     byte ptr [bx+buff], ','
        jne     fd11err
        inc     bx
        call    RemSpac
        or      bx, bx
        jz      fd11err
        call    GetReg          ; get register
        cmp     al, RAX         ; is it [out ...,ax]
        je      fd11ax
        cmp     al, RAL         ; is it [out ...,al]
        je      fd11al
        jmp     short fd11err   ; error...

fd11ax:
        inc     cx              ; add 1 to indicate ax series

fd11al:
        jmp     short fd11ok

fd11err:
        mov     bl, 1
        mov     ax, bx
        jmp     short fd11don

fd11ok:
        mov     ax, 1
        xor     ch, ch
        cmp     cx, bp          ; is this the correct opcode
        jne     fd11don
        xor     ax, ax          ; indicate found

fd11don:
        pop     cx
        ret

        page
fd12:
        push    cx
        xor     cx, cx
        mov     bx, dx
        call    GetReg
        cmp     al, NOREG
        je      fd12nr
        xor     ah, ah          ; indicate push
        cmp     al, RCS
        jne     fd13ss
        mov     al, 0eh
        jmp     fd13cmp

fd12nr:
        pop     cx
        xor     ax, ax
        cmp     bp, 0146h
        je      fd12nrd
        inc     al

fd12nrd:
        ret

fd13:
        push    cx
        xor     cx, cx
        mov     bx, dx
        call    GetReg
        mov     ah, 01h
        cmp     al, NOREG
        je      fd13nr

fd13ss:
        cmp     al, RSS
        jne     fd13ds
        mov     al, 16h
        add     al, ah          ; modify for POP SS 17h
        jmp     short fd13cmp

fd13ds:
        cmp     al, RDS
        jne     fd13es
        mov     al, 1Eh
        add     al, ah          ; modify for POP DS 1fh 
        jmp     short fd13cmp

fd13es:
        cmp     al, RES
        jne     fd13reg
        mov     al, 06h
        add     al, ah          ; modify for POP ES 07h
        jmp     short fd13cmp

fd13reg:
        cmp     al, RAX
        jb      fd13bad
        cmp     al, RDI
        ja      fd13bad
        push    cx
        mov     cl, 4
        shr     al, cl
        pop     cx
        dec     al
        add     al, 50h         ; 50 + reg (push)
        or      ah, ah          ; push
        jz      fd13rg
        add     al, 8           ; 58 + reg (pop)

fd13rg:
        shl     cl, 1
        shl     cl, 1
        shl     cl, 1

fd13cmp:
        add     cl, al
        xor     ax, ax
        xor     ch, ch
        cmp     cx, bp
        je      fd13don

fd13bad:
        mov     ax, 1

fd13don:
        pop     cx
        ret

fd13nr:
        pop     cx
        xor     ax, ax
        cmp     bp, 008fh
        je      fd13nrd
        inc     al

fd13nrd:
        ret

        page
fd14:            ; ret or retf case
        mov     bx, dx
        call    RemSpac
        or      bx, bx
        jz      fd14a
        push    cx
        mov     cx, 4
        call    getHex          ; test for RET xxxx or RETF xxxx
        pop     cx
        or      bx, bx
        jz      fd14a
        mov     ax, bp
        cmp     al, 0cah        ; test for RETF xxxx
        je      fd14ok
        cmp     al, 0c2h        ; test for RET  xxxx
        je      fd14ok
        ret

fd14a:
        mov     ax, bp
        cmp     al, 0cbh        ; test for RETF
        je      fd14ok
        cmp     al, 0c3h        ; test for RET
        je      fd14ok
        ret

fd14ok:
        xor     ax, ax
        ret
        
        page
fd15:
        mov     bx, dx
        call    Map             ; create map for test enter
        lea     bx, map1718
        call    FindMap         ; map ok...
        cmp     bx, -1
        jz      fd15bad
        call    word ptr [bx+tab15]      ; call desired action from table
        ret

fd15bad:
        mov     al, 1
        ret

fd151:    ;  reg8 <- case
        mov     al, 84h
        jmp     fd15cmp

fd153:    ;  reg16 <- case
        mov     al, 85h
        jmp     fd15cmp

fd155:    ;  al, xx
        mov     al, 0a8h
        jmp     fd15cmp

fd156:    ;  ax, xxyy
        mov     al, 0a9h
        jmp     fd15cmp

fd157:    ;  reg/mem, xx
        mov     ax, 0128h
        jmp     fd15cp1

fd158:    ;  reg/mem, xxyy
        mov     ax, 0130h
        jmp     fd15cp1

fd15cmp:
        xor     ah, ah

fd15cp1:
        cmp     ax, bp
        jne     fd15bad
        xor     ax, ax
        ret

        page
fd16:
        push    cx
        mov     bx, dx
        call    RegSize         ; get register size
        or      bx, bx
        jnz     fd16a
        mov     bx, dx
        call    RemSpac
        or      bx, bx
        jz      fd16bad
        xor     ax, ax
        cmp     word ptr [bx+buff], 'YB'
        je      fd16a
        cmp     word ptr [bx+buff], 'OW'
        jne     fd16bad

fd16a:
        mov     cx, ax
        call    ScanCom         ; scan for comma
        or      bx, bx
        jz      fd16bad
        call    RemSpac
        or      bx, bx
        jz      fd16bad
        push    bx
        call    GetReg
        cmp     al, NOREG
        je      fd161
        pop     bx
	cmp	al, 2
        jne     fd16bad
        cmp     bp, 0120h
        jb      fd16bad
        cmp     bp, 0127h
        ja      fd16bad
        xor     ax, ax
        pop     cx
        ret


fd161:
        pop     bx
        cmp     bp, 0108h
        jbe     fd16bad
        cmp     bp, 011fh
        ja      fd16bad
        xor     ax, ax
        pop     cx
        ret

fd16bad:
        mov     al, 1
        pop     cx
        ret

        page
fd17:
        push    cx
        mov     bx, dx
        call    Map             ; create map for test enter
        lea     bx, map1718
        call    FindMap         ; map ok...
        cmp     bx, -1
        jz      fd17bad
        cmp     bx, 12
        jb      fd17b
        push    bx
        mov     bx, dx
        call    ValType         ; determine if constant is byte or word
        or      bx, bx
        jnz     fd17a
        pop     bx
        jmp     fd17bad

fd17a:
        pop     bx

fd17b:
        call    word ptr [bx+tab17]      ; call desired action from table
        pop     cx
        ret

fd17bad:
        mov     al, 1
        pop     cx
        ret

fd171:    ;  reg8 <- case
        cmp     bp, 0012h
        je      fd17ok
        cmp     bp, 0002h
        je      fd17ok
        cmp     bp, 0038h
        je      fd17ok
        cmp     bp, 001ah
        je      fd17ok
        cmp     bp, 002ah
        je      fd17ok
        mov     al, 1
        ret

fd172:    ;  mem8 <- case
        cmp     bp, 0010h
        je      fd17ok
        cmp     bp, 0000h
        je      fd17ok
        cmp     bp, 003ah
        je      fd17ok
        cmp     bp, 0018h
        je      fd17ok
        cmp     bp, 0028h
        je      fd17ok
        mov     al, 1
        ret

fd173:    ;  reg16 <- case
        cmp     bp, 0013h
        je      fd17ok
        cmp     bp, 0003h
        je      fd17ok
        cmp     bp, 0039h
        je      fd17ok
        cmp     bp, 001bh
        je      fd17ok
        cmp     bp, 002bh
        je      fd17ok
        mov     al, 1
        ret

fd17ok:
        xor     ax, ax
        ret

fd174:    ;  mem16 <- case
        cmp     bp, 0011h
        je      fd17ok
        cmp     bp, 0001h
        je      fd17ok
        cmp     bp, 003bh
        je      fd17ok
        cmp     bp, 0019h
        je      fd17ok
        cmp     bp, 0029h
        je      fd17ok
        mov     al, 1
        ret

fd175:    ;  al, xx
        cmp     bp, 0014h
        je      fd17ok
        cmp     bp, 0004h
        je      fd17ok
        cmp     bp, 003ch
        je      fd17ok
        cmp     bp, 001ch
        je      fd17ok
        cmp     bp, 002ch
        je      fd17ok
        mov     al, 1
        ret

fd176:    ;  ax, xxyy
        cmp     bp, 0015h
        je      fd17ok
        cmp     bp, 0005h
        je      fd17ok
        cmp     bp, 003dh
        je      fd17ok
        cmp     bp, 001dh
        je      fd17ok
        cmp     bp, 002dh
        je      fd17ok
        mov     al, 1
        ret

fd8183:
        or      cx, cx
        jz      fd8183a
        jmp     fd81

fd8183a:
        jmp     fd83

        page
fd18:
        mov     bx, dx
        call    Map             ; create map for test enter
        lea     bx, map1718
        call    FindMap         ; map ok...
        cmp     bx, -1
        jz      fd18bad
        call    word ptr [bx+tab18]      ; call desired action from table
        ret

fd18bad:
        mov     al, 1
        ret

fd181:    ;  reg8 <- case
        cmp     bp, 0022h
        je      fd18ok
        cmp     bp, 000ah
        je      fd18ok
        cmp     bp, 0032h
        je      fd18ok
        mov     al, 1
        ret

fd182:    ;  mem8 <- case
        cmp     bp, 0020h
        je      fd18ok
        cmp     bp, 0008h
        je      fd18ok
        cmp     bp, 0030h
        je      fd18ok
        mov     al, 1
        ret

fd183:    ;  reg16 <- case
        cmp     bp, 0023h
        je      fd18ok
        cmp     bp, 000bh
        je      fd18ok
        cmp     bp, 0033h
        je      fd18ok
        mov     al, 1
        ret

fd18ok:
        xor     ax, ax
        ret

fd184:    ;  mem16 <- case
        cmp     bp, 0021h
        je      fd18ok
        cmp     bp, 0009h
        je      fd18ok
        cmp     bp, 0031h
        je      fd18ok
        mov     al, 1
        ret

fd185:    ;  al, xx
        cmp     bp, 0024h
        je      fd18ok
        cmp     bp, 000ch
        je      fd18ok
        cmp     bp, 0034h
        je      fd18ok
        mov     al, 1
        ret

fd186:    ;  ax, xxyy
        cmp     bp, 0025h
        je      fd18ok
        cmp     bp, 000dh
        je      fd18ok
        cmp     bp, 0035h
        je      fd18ok
        mov     al, 1
        ret

fd80:
        cmp     bp, 0100h
        jb      fdxxbad
        cmp     bp, 0107h
        ja      fdxxbad
        xor     ax, ax
        ret

fd81:
        cmp     bp, 0108h
        jb      fdxxbad
        cmp     bp, 010fh
        ja      fdxxbad
        xor     ax, ax
        ret

fd83:
        cmp     bp, 0110h
        jb      fdxxbad
        cmp     bp, 0117h
        ja      fdxxbad
        xor     ax, ax
        ret

fdxxbad:
        mov     al, 1
        ret
FindOp  endp

        page
;-------------------------------------------------------------------------;
;       Function: MakeRM                                                  ;
;       Input:                                                            ;
;                 AX = OFFSET                                             ;
;                 BX = EA Bit Map from Scan Sea                           ;
;                 DL = RM Field So Far                                    ;
;                 DH = offset size   1 or 2                               ;
;       Output:                                                           ;
;                 AL = RM Field Generated (0) bad                         ;
;-------------------------------------------------------------------------;

MakeRM  proc    near
        push    bx
        push    cx
        push    dx
        push    si

        xor     cx, cx
        lea     si, rmtab
        push    ax

rmloop:
        cmp     cx, 9
        jae     rmbad
        lodsb
        mov     ah, bl  
        and     ax, 0f0fh       ; mask value bit
        cmp     al, ah
        je      rmset
        inc     cx
        jmp     short rmloop

rmset:
        mov     al, dl
        or      al, cl  
        test    bl, 10h
        jnz     rmset1
        stosb
        pop     ax 
        jmp     short rmdone
        
rmset1:
        cmp     cx, 8
        je      rmset3
	cmp     dh, 1
	je      rmset2
        pop     cx              ; is this a byte value
        push    cx
;SAH	or      ch, ch
;SAH    jz      rmset2
	cmp	cx,0080h	; SAH	0 - 127 only
	jb	rmset2		; SAH
        or      al, 80h
        stosb
        pop     ax
        stosw
        jmp     short rmdone

rmset2:
        or      al, 40h
        stosb
        pop     ax
        stosb
        jmp     short rmdone

rmset3:
        or      dl, 6           ; set rm = 110 and mod = 0
        mov     al, dl
        stosb
        pop     ax
        stosw
        jmp     short rmdone
        
rmbad:
        pop     ax
        xor     ax, ax
        jmp     short rmfin
        
rmdone:
        mov     ax, 1

rmfin:
        pop     si
        pop     dx
        pop     cx
        pop     bx
        ret
MakeRM  endp

        page
;-------------------------------------------------------------------------;
;       Function: MakeOp                                                  ;
;       Input:                                                            ;
;                 BX = Offset of Table Entry                              ;
;                 DX = Opcode                                             ;
;                 SI = Offset to Instruction Menonic Structure            ;
;                 DI = Offset where to store instruction                  ;
;                 ES = Segment where to store instruction                 ;
;       Output:                                                           ;
;                 BX = (0 if NO ERRORS)                                   ;
;                 DI = Offset of next instruction                         ;
;                 ES = Segment of next instruction                        ;
;-------------------------------------------------------------------------;

MakeOp  proc    near
        push    ax
        push    cx
        push    bp

        mov     [lastop], dx
;
;       save opcode in memory
;
        or      dh, dh                  ; special case
        jnz     mop1
        jmp     mop2

;       handle  special cases

mop1:
        xor     dh, dh
        shr     dl, 1
        shr     dl, 1
        shr     dl, 1
        cmp     dl, 8
        jbe     mop1a
        lea     dx, intern              ; display internal error message
        call    OutMsg
        lea     dx, badop
        call    OutMsg
        mov     bx, 1
        jmp     mopdone

mop1a:
        cmp     dl, 2
        ja      mop1c
        jne     mop1b
        add     dl, 81h
        jmp     mop2
        
;       handle  special case of op82 and op83 - must determing operand size

mop1b:
        add     dl, 80h         ; adjust for 80 and 81 codes
        jmp     mop2

mop1c:
        cmp     dl, 4
        ja      mop1d

;       handle  special case of d0 - d3 shifts

        sub     dl, 3
        shl     dl, 1           ; multiply by 2
        add     dl, 0d0h
        push    ax
        push    bx
        
        mov     bx, [valbx]
        call    RemSpac
        cmp     word ptr [bx+buff], 'YB'
        je      mop1cb
        cmp     word ptr [bx+buff], 'OW'
        jne     mop1ca
        inc     dl
        jmp     short mop1cb
        
mop1ca:
        call    RegSize
        and     al, 1
        add     dl, al

mop1cb:
        pop     bx
        pop     ax
        jmp     mop2

mop1d:
        cmp     dl, 6
        ja      mop1e
        
;       handle  opf6 and f7

        add     dl, 0f1h
        jmp     mop2


mop1e:
        add     dl,  0f7h
        
;       store opcode in memory

mop2:
        mov     al, dl
        stosb

;
;       do each of the specific cases
;
        mov     dx, word ptr [bx+2]
        xchg    dx, bx
        mov     cl, byte ptr [bx]
        xor     ch, ch
        add     bx, cx
        xchg    dx, bx
        mov     cl, 4
        mov     bx, word ptr [bx]
        xor     bh, bh
        shl     bx, 1

mopcall:
        call    word ptr [bx + mopfun]
mopcret: 

        jmp     mopdone

mop00:            ; reg/mem, reg case
        push    cx
        push    dx

        mov     cx, [lastop]
        and     cx, 1
        mov     bx, [valbx]
        call    GetReg          ; get register
        or      bx, bx
        jz      mop00nr
        or      al, al
        jz      mop00bd
        cmp     al, RBH
        jbe     mop00br
        cmp     al, RDI
        ja      mop00bd
        shr     al, 1
        shr     al, 1
        shr     al, 1
        shr     al, 1
;;      jmp     short mop00rg

mop00br:


mop00rg:
        dec     al              ; minus 1 to get register value
        mov     [valbx], bx     ; save line position
        mov     bl, al
        mov     al, 0c0h        ; set use r/m field as register
        or      al, bl          ; mask in register
        call    mop00sc
        cmp     dx, 0ffffh      ; error
        je      mop00bd
        or      al, dl
        stosb                   ; store it
        xor     bx, bx
        pop     dx
        pop     cx
        ret

mop00bd:
        mov     bx, 1
        pop     dx
        pop     cx
        ret


mop00nr:
        mov     bx, [valbx]
        call    ScanSea         ; scan for effective address
        or      bx, bx
        jz      mop00bd
        dec     bx              ; start at '['  
        call    ScanEA
        or      bx, bx
        jnz     mop00c
        jmp     mop00bd
        
mop00c:
        mov     [valbx], bx
        mov     bx, dx
        call    mop00sc
        cmp     dx, 0ffffh
        je      mop00bd
        mov     dh, 2
        call    MakeRM
        or      al, al
        jz      mop00bd
        xor     bx, bx
        pop     dx
        pop     cx
        ret
        
mop00sc:
        push    ax
        push    bx

        mov     bx, [valbx]     ; scan for comma and places reg xxx pos 
        call    ScanCom
        or      bx, bx
        jz      mop00sb
        call    GetReg
        or      bx, bx
        jz      mop00sb
        cmp     al, RAL
        jb      mop00sb
        cmp     al, RBH
        jbe     mop00s1
        cmp     al, RDI
        ja      mop00sb
        shr     al, 1
        shr     al, 1
        shr     al, 1
        shr     al, 1
;;      jmp     short mop00ss

mop00s1:

mop00ss:
        dec     al
        shl     al, 1
        shl     al, 1
        shl     al, 1
        mov     dl, al          ; set xxx pos of dl
        jmp     short mop00sr

mop00sb:
        mov     dx, 0ffffh

mop00sr:
        pop     bx
        pop     ax
        ret


mop01:            ; reg, reg/mem case     
        push    cx
        push    dx

        mov     cx, [lastop]
        and     cx, 1
        mov     bx, [valbx]
        call    GetReg          ; get register
        or      bx, bx
        jz      mop01bd
        or      al, al
        jz      mop01bd
        cmp     al, RBH
        jbe     mop01ns
        cmp     al, RDI
        ja      mop01bd
        shr     al, 1
        shr     al, 1
        shr     al, 1
        shr     al, 1

mop01ns:            ; set register xxx position
        dec     al
	shl     al, 1
	shl     al, 1
	shl     al, 1
        mov     ch, al

mop01np:
        call    ScanCom
        or      bx, bx
        jz      mop01bd
        mov     [valbx], bx
        call    GetReg          ; get register
        or      bx, bx
        jz      mop01nr
        or      al, al
        jz      mop01bd
        cmp     al, RBH
        jbe     mop01br
        cmp     al, RDI
        ja      mop01bd
        shr     al, 1
        shr     al, 1
        shr     al, 1
        shr     al, 1
        jmp     short mop01rg

mop01br:

mop01rg:
	dec	al		; minus 1 to get register value
	shl	al,1		; SAH
	shl	al,1		; SAH
	shl	al,1		; SAH
	xchg	al,ch		; SAH
	shr	al,1		; SAH
	shr	al,1		; SAH
	shr	al,1		; SAH
        mov     [valbx], bx     ; save line position
        mov     bl, al
        mov     al, 0c0h        ; set use r/m field as register
        or      al, bl          ; mask in register
        or      al, ch          ; mask in register
        stosb                   ; store it
        xor     bx, bx
        pop     dx
        pop     cx
        ret

mop01bd:
        mov     bx, 1
        pop     dx
        pop     cx
        ret


mop01nr:
        mov     bx, [valbx]
        call    ScanSea         ; scan for effective address
        or      bx, bx
        jz      mop01bd
        dec     bx              ; start at '['  
        call    ScanEA
        or      bx, bx
        jnz     mop01c
        jmp     mop01bd
        
mop01c:
        mov     [valbx], bx
        mov     bx, dx
        mov     dl, ch
        mov     dh, 2
        call    MakeRM
        or      al, al
        jz      mop01bd
        xor     bx, bx
        pop     dx
        pop     cx
        ret

mop03r:
        mov     bx, [valbx]
        call    ScanCom
        jmp     short mop03c

mop03:
        mov     bx, [valbx]

mop03c:
        mov     cx, 4
        call    GetHex
        or      bx, bx
        jz      mop03e
        stosw
        xor     bx, bx
        ret

mop03e:
        mov     bx, [valbx]
        ret

        page
mop0809:
        push    dx
        mov     dx, [lastop]
        and     dl, 7
        shl     dl, 1
        shl     dl, 1
        shl     dl, 1
        mov     bx, [valbx]
        call    GetReg
        cmp     al, NOREG
        je      mop89b
        or      dl, 0c0h        ; set r/m as 'reg' field
        cmp     al, RDS
        ja      mop89bd
        cmp     al, RES
        jae     mop89bd
        cmp     al, RAX
        jae     mop89a
        
;       byte register case
        
        dec     al
        or      dl, al          ; set register field
        jmp     short mop89rg

;       word register case

mop89a:
        shr     al, 1
        shr     al, 1
        shr     al, 1
        shr     al, 1
        dec     al
        or      dl, al
        
mop89rg:
        mov     al, dl
        stosb
        xor     bx, bx
        pop     dx
        ret

mop89b:
        mov     bx, [valbx]
        call    ScanSea         ; scan for effective address
        or      bx, bx
        jz      mop89bd
        push    dx
        dec     bx              ; start at '['  
        call    ScanEA
        or      bx, bx
        jnz     mop89c
        pop     dx
        jmp     mop89bd
        
mop89c:
        mov     bx, dx
        pop     dx
        mov     dh, 2
        call    MakeRM
        or      al, al
        jz      mop89bd
        xor     bx, bx
        pop     dx
        ret

mop89bd:
        mov     bx, 1
        pop     dx
        ret

mop0a:
        mov     bx, [valbx]
        mov     cl, 4
        call    GetHex
        or      bx, bx
        jz      mop0ae
        mov     bp, ax
        mov     ax, di
        sub     ax, 7fh
        cmp     ax, bp
        ja      mop0ab
        mov     ax, di
        add     ax, 80h
        cmp     ax, bp
        jb      mop0ab
        mov     ax, bp
        sub     ax, di
        dec     ax
        stosb
        xor     bx, bx
        ret

mop0ae:
        mov     bx, [valbx]
        ret

mop0ab:
        mov     bx, 1
        ret

mop0b:
        mov     bx, [valbx]

mop0ba:
        mov     cx, 4
        call    GetHex
        or      bx, bx
        jz      mop0bb
        sub     ax, di
        dec     ax
        dec     ax
        stosw
        xor     bx, bx
        ret

mop0bb:
        mov     bx, [valbx]
        call    RemSpac
        or      bx, bx
        jz      mop0be
        cmp     byte ptr [bx+buff], 'N'         ; is this a near call or jmp
        jne     mop0be
        inc     bx

mop0bc:                            ; scan for next space
        cmp     byte ptr [bx+buff], ' '
        je      mop0bd
        inc     bx
        jmp     short mop0bc

mop0bd:
        jmp     mop0ba

mop0be:
mop0ce:
        mov     bx, dx
        ret

mop0cf:                    ; handle jmp FAR case 
        mov     bx, [valbx]
        call    RemSpac
        or      bx, bx
        jz      mop0ce
        cmp     word ptr [bx+buff], 'AF'
        jne     mop0ce
        inc     bx
        inc     bx      
        cmp     byte ptr [bx+buff], 'R'
        jne     mop0ce
        inc     bx
        mov     [valbx], bx

mop0c:
        mov     bx, [valbx]

mop0cv:
        mov     cx, 4
        call    GetHex
        or      bx, bx
        jz      mop0cf
        mov     bp, ax
        call    RemSpac
        or      bx, bx
        jz      mop0ca
        cmp     byte ptr [bx+buff], ':'
        jne     mop0ca
        inc     bx
        call    RemSpac
        or      bx, bx
        jz      mop0ce
        call    GetHex
        or      bx, bx
        jz      mop0ce
        stosw
        jmp     short mop0cb

mop0ca:
        mov     bp, [regcs]
        stosw

mop0cb:
        xchg    bp, ax
        stosw
        xor     bx, bx
        ret

mop0e:            ; byte mem/reg
        mov     bx, [valbx]
        call    GetReg          ; get register
        or      bx, bx
        jz      mop0enr
        or      al, al
        jz      mop0ebd
        cmp     al, 8
        ja      mop0ebd
        dec     al              ; minus 1 to get register value
        mov     bl, al
        mov     ax, [lastop]
        and     al, 7           ; mask upper five bits
        shl     al, 1
        shl     al, 1
        shl     al, 1
        or      al, 0c0h        ; set use r/m field as register
        or      al, bl          ; mask in register
        stosb                   ; store it
        xor     bx, bx
        ret

mop0ebd:
        mov     bx, 1
        ret

mop0enr:
        push    dx
        mov     bx, [valbx]
        call    ScanSea         ; scan for effective address
        or      bx, bx
        jz      mop0ebd
        push    dx
        dec     bx              ; start at '['  
        call    ScanEA
        or      bx, bx
        jnz     mop0ec
        pop     dx
        jmp     mop0ebd
        
mop0ec:
        mov     bx, dx
        pop     dx
        mov     dx, [lastop]
        and     dl, 7
        shl     dl, 1
        shl     dl, 1
        shl     dl, 1
        mov     dh, 2
        call    MakeRM
        or      al, al
        jz      mop0ebd
        xor     bx, bx
        pop     dx
        ret


mop0f:            ; word mem/reg
        mov     bx, [valbx]
        call    GetReg          ; get register
        or      bx, bx
        jz      mop0fnr
        cmp     al, RAX
        jb      mop0fbd
        cmp     al, RDI
        ja      mop0fbd
        shr     al, 1
        shr     al, 1
        shr     al, 1
        shr     al, 1
        dec     al              ; minus 1 to get register value
        mov     bl, al
        mov     ax, [lastop]
        and     al, 7           ; mask upper five bits
        shl     al, 1
        shl     al, 1
        shl     al, 1
        or      al, 0c0h        ; set use r/m field as register
        or      al, bl          ; mask in register
        stosb                   ; store it
        xor     bx, bx
        ret

mop0fbd:
        mov     bx, 1
        ret

mop0fnr:
        push    dx
        mov     bx, [valbx]
        call    ScanSea         ; scan for effective address
        or      bx, bx
        jz      mop0fbd
        push    dx
        dec     bx              ; start at '['  
        call    ScanEA
        or      bx, bx
        jnz     mop0fc
        pop     dx
        jmp     mop0fbd
        
mop0fc:
        mov     bx, dx
        pop     dx
        mov     dx, [lastop]
        and     dl, 7
        shl     dl, 1
        shl     dl, 1
        shl     dl, 1
        mov     dh, 2
        call    MakeRM
        or      al, al
        jz      mop0fbd
        xor     bx, bx
        pop     dx
        ret


mop10:
        dec     al
        and     al, 007h
        or      al, 0c0h
        stosb
        xor     bx, bx
        ret


mop11:
        push    cx
        
        call    mop11r
        or      bx, bx
        jnz     mp11bad
        mov     bx, [valbx]
        call    ScanCom
        or      bx, bx
        jz      mp11bad
        mov     cl, 2
        call    GetHex          ; get 2 byte hex
        or      bx, bx
        jz      mp11bad
        stosb
        xor     bx, bx
        
        pop     cx
        ret

mp11bad:
        mov     bl, 1
        pop     cx
        ret

mop12:
        push    cx
        
        call    mop11r
        or      bx, bx
        jnz     mp11bad
        mov     bx, [valbx]
        call    ScanCom
        or      bx, bx
        jz      mp11bad
        mov     cl, 4
        call    GetHex          ; get 2 byte hex
        or      bx, bx
        jz      mp11bad
        stosw
        xor     bx, bx
        
        pop     cx
        ret

mop11r:            ; reg/mem, reg case
        push    dx

        mov     cx, [lastop]
        and     cx, 1
        mov     bx, [valbx]
        call    GetReg          ; get register
        or      bx, bx
        jz      mop11nr
        or      al, al
        jz      mop11bd
        cmp     al, RBH
        jbe     mop11br
        cmp     al, RDI
        ja      mop11bd
        shr     al, 1
        shr     al, 1
        shr     al, 1
        shr     al, 1
        jmp     short mop11rg

mop11br:

mop11rg:
        dec     al              ; minus 1 to get register value
        mov     [valbx], bx     ; save line position
        mov     bl, al
        mov     dx, [lastop]    ; set up function name
        and     dl, 7
        shl     dl, 1
        shl     dl, 1
        shl     dl, 1
        mov     al, 0c0h        ; set use r/m field as register
        or      al, dl          ; mask in function
        or      al, bl          ; mask in register
        stosb                   ; store value
        xor     bx, bx          ; indicate ok
        pop     dx
        ret

mop11bd:
        mov     bx, 1           ; indicate bad
        pop     dx
        ret


mop11nr:
        mov     bx, [valbx]
        call    ScanSea         ; scan for effective address
        or      bx, bx
        jz      mop11bd
        dec     bx              ; start at '['  
        call    ScanEA
        or      bx, bx
        jnz     mop11c
        jmp     mop11bd
        
mop11c:
        mov     [valbx], bx
        mov     bx, dx
	mov	dx, [lastop]
	push	dx
	and	dl,0feh 	; check for mov instructions
	cmp	dl,0c6h
	pop	dx
	jne	mop11c1
	xor	dl,dl
mop11c1:
        and     dl, 7
        shl     dl, 1
        shl     dl, 1
        shl     dl, 1
        mov     dh, 2
        call    MakeRM
        or      al, al
        jz      mop11bd
        xor     bx, bx          ; indicate ok
        pop     dx
        ret

mop14:            ; reg, reg/mem case     
        push    cx
        push    dx

        mov     bx, [valbx]
        call    GetReg          ; get register
        or      bx, bx
        jz      mop14bd
        cmp     al, RBH
        jbe     mop14bd
        cmp     al, RDI
        ja      mop14bd
        shr     al, 1
        shr     al, 1
        shr     al, 1
        shr     al, 1
        dec     al
        shl     al, 1
        shl     al, 1
        shl     al, 1
        mov     ch, al

mop14np:
        call    ScanCom
        or      bx, bx
        jz      mop14bd
        mov     [valbx], bx
        call    GetReg          ; get register
        or      bx, bx
        jz      mop14nr         ; can't be a register

mop14bd:
        mov     bx, 1
        pop     dx
        pop     cx
        ret


mop14nr:
        mov     bx, [valbx]
        call    ScanSea         ; scan for effective address
        or      bx, bx
        jz      mop14bd
        dec     bx              ; start at '['  
        call    ScanEA
        or      bx, bx
        jnz     mop14c
        jmp     mop14bd
        
mop14c:
        mov     [valbx], bx
        mov     bx, dx
        mov     dl, ch
        mov     dh, 2
        call    MakeRM
        or      al, al
        jz      mop14bd
        xor     bx, bx
        pop     dx
        pop     cx
        ret

mop15:            ; mem/reg <- sreg
        push    cx
        push    dx
        xor     dx, dx
        mov     bx, [valbx]
        call    ScanSea
        or      bx, bx
        jz      mop15r
        call    mop156e
        cmp     ax, -1
        je      mop156b
        mov     dl, al
        jmp     mop15c

mop15r:
        mov     bx, [valbx]
        call    GetReg
        or      bx, bx
        jz      mop156b
        cmp     al, RAX         ; must be a word register
        jb      mop156b
        cmp     al, RDI
        ja      mop156b
        shr     al, 1
        shr     al, 1
        shr     al, 1
        shr     al, 1
        dec     al
        and     al, 7
        or      al, 0c0h        ; indicate mod 11 (use r/m as register)
        mov     dl, al          ; save it
        
mop15c:
        mov     bx, [valbx]
        call    ScanCom
        or      bx, bx
        jz      mop156b
        call    GetReg
        cmp     al, RES
        jb      mop156b
        cmp     al, RDS
        ja      mop156b
        sub     al, RES
        shr     al, 1
        and     al, 18h
        or      al, dl          ; mask in ea calculate above

mop156s:
        stosb
        or      dh, dh          ; dh has offset size 0 , 1 or 2 bytes
        jz      mop156d         ; 0 skip
        cmp     dh, 1           ; 1 byte
        jne     mop156w
        mov     al, cl          ; cl has byte
        stosb
        jmp     mop156d

mop156w:
        mov     ax, cx
        stosw
        
mop156d:
        xor     bx, bx
        pop     dx
        pop     cx
        ret

mop156b:
        mov     bl, 1
        pop     dx
        pop     cx
        ret

mop16:            ; sreg <- mem/reg
        push    cx
        push    dx
        xor     dx, dx
        mov     bx, [valbx]
        call    GetReg
        or      bx, bx
        jz      mop156b
        cmp     al, RES
        jb      mop156b
        cmp     al, RDS
        ja      mop156b
        sub     al, RES
        shr     al, 1
        and     al, 18h
        mov     dl, al
        mov     [valbx], bx
        call    ScanSea
        or      bx, bx
        jz      mop16rg
        call    mop156e
        cmp     ax, -1
        je      mop156b
        or      al, dl
        jmp     mop156s

mop16rg:
        mov     bx, [valbx]
        call    ScanCom         ; scan for comma
        or      bx, bx
        jz      mop156b
        call    GetReg
        or      bx, bx
        jz      mop156b
        cmp     al, RAX
        jb      mop156b
        cmp     al, RDI
        ja      mop156b
        shr     al, 1
        shr     al, 1
        shr     al, 1
        shr     al, 1
        dec     al
        and     al, 7
        or      al, 0c0h        ; indicate mod 11 (use r/m as reg)
        or      al, dl
        jmp     mop156s
        

mop156e:            ; routine to caluate eff addr - cx = offset
        push    bx
        push    si
        push    dx

	dec	bx
	call	ScanEA		; scan effective address
        or      bx, bx
        jnz     m156ok
        mov     ax, -1          ; error
        jmp     m156don
        
m156ok:
        push    ax              ; push offset as for cx return
        lea     si, rmtab
        xor     cx, cx

m156l:
        cmp     cx, 9           ; bad
        jae     m156bad
        lodsb
        mov     ah, dl
        and     ax, 0f0fh
        cmp     al, ah
        je      m156s
        inc     cx
        jmp     short   m156l

m156s:
        mov     ax, cx
        test    dl, 10h         ; no offset given
	jz	m156sd
	mov	ah,dl
	mov	al,06h
	jmp	short m156sd

m156bad:
        mov     ax, -1          ; indicate error
        
m156sd:
        pop     cx

m156don:
        pop     dx
        mov     dh, ah
        pop     si
        pop     bx
        ret

mop18:
        mov     bx, [valbx]
        call    ScanSea
        or      bx, bx
        jz      mop18bd
        mov     cx, 4
        call    GetHex
        or      bx, bx
        jz      mop18bd
        stosb
        xchg    al, ah
        stosb
        xor     bx, bx
        ret

mop18bd:
        mov     bl, 1
        ret

mop1fa:
	mov	bx,[valbx]
	cmp	byte ptr [bx+buff],27h	    ; check to see if it is '
	jne	mopbyte
	inc	bx
mos1fal:
	mov	al,byte ptr [bx+buff]
	or	al,al			    ; NULL = all done
	jz	mopxend
	cmp	al,27h			    ; ' = all done
	je	mopxend
	cmp	al,0dh			    ; 0dh = all done
	je	mopxend
	cmp	al,0ah			    ; 0ah = all done
	je	mopxend
	stosb
	inc	bx
	jmp	short mos1fal		    ; next character

mop1f:
        mov     bx, [valbx]

mopbyte:
        mov     cx, 2
        call    GetHex
        or      bx, bx
        jz      moperr
	stosb
mopxend:
        xor     bx, bx
        ret

mop20:
        mov     al, 0ah
        stosb
        xor     bx, bx
        ret

mop21:
        mov     bx, [valbx]
        call    ScanCom
        or      bx, bx
        jnz     mopbyte
        jmp     moperr

mopea:
        xor     bx, bx
        ret

moperr:
        mov     bl, 1
        ret

mopret:
        xor     bx, bx
        ret

mopdone:
        pop     bp
        pop     cx
        pop     ax
        ret
MakeOp  endp


        page
;-------------------------------------------------------------------------;
;       Function: ScanEA                                                  ;
;       Input:                                                            ;
;                 BX = Start of Buffer                                    ;
;       Output:                                                           ;
;                 AX = Absolute Location (0 if errors)                    ;
;                 BX = New Buffer Location  (error pos if AX = 0)         ;
;                 DX = EA  Bit Map                                        ;
;-------------------------------------------------------------------------;


ScanEa  proc    near
        push    cx
        push    bp

        xor     bp, bp
        xor     dx, dx
        mov     cx, 4           ; 4 byte hex
        call    RemSpac
        or      bx, bx
        jz      sea0
        cmp     byte ptr [bx+buff], '['
        je      sea1

sea0:
        jmp     seaerr

sea1:
        inc     bx              ; next..
        mov     [seabx], bx
        call    GetReg
        cmp     al, RBP         ; bp??
        je      sea3bp
        cmp     al, RBX         ; bx??
        je      sea3bx
        cmp     al, RSI         ; si??
        je      sea9si
        cmp     al, RDI         ; di??
        je      sea9di
;
;       Get Absolute offset
;

sea1a:
        mov     bx, [seabx]
        push    bx
        call    GetHex
        or      bx, bx
        jne     sea1b
        pop     bx
        jmp     seaerr

sea1b:
        pop     bp
        mov     bp, ax
        or      dx, 16          ; set absolute location
        jmp     sea13

sea9si:
        or      dx, 4           ; mark si bit
        jmp     sea9

sea9di:
        or      dx, 8           ; mark di bit
        jmp     sea9

sea3bp:
        or      dx, 1           ; mark bp bit
        jmp     short sea3

sea3bx:
        or      dx, 2           ; mark bx bit

        page
sea3:
        call    RemSpac
        or      bx, bx
        jz      sea4
        cmp     byte ptr [bx+buff],'+'
        je      sea5
        cmp     byte ptr [bx+buff], ']'
        jne     sea4
        jmp     seadone         ; done

sea4:
        jmp     seaerr          ; error

sea5:
        inc     bx              ; next...
        mov     [seabx], bx
        call    GetReg
        or      bx, bx
        cmp     al, RSI         ; si??
        je      sea6si
        cmp     al, RDI         ; di??
        je      sea6di
        cmp     al, NOREG       ; not a register
        jne     sea4
;
;       Get Absolute offset
;
        mov     bx, [seabx]
        push    bx
        call    GetHex
        or      bx, bx
        jne     sea5b
        pop     bx
        jmp     seaerr

sea5b:
        pop     bp
        mov     bp, ax
        or      dx, 16          ; set absolute location
        jmp     sea6

sea6si:
        or      dx, 4           ; mark si bit
        jmp     short sea6

sea6di:
        or      dx, 8           ; mark di bit

sea6:
        call    RemSpac
        or      bx, bx
        jz      sea7
        cmp     byte ptr [bx+buff],'+'
        je      sea8
        cmp     byte ptr [bx+buff], ']'
        jne     sea7
        jmp     seadone         ; done

sea7:
        jmp     seaerr

sea8:
;
;       Get Absolute offset
;
        inc     bx
        push    bx
        call    GetHex
        or      bx, bx
        jne     sea8b
        pop     bx
        jmp     seaerr

sea8b:
        pop     bp
        mov     bp, ax
        or      dx, 16          ; set absolute location
        call    RemSpac
        or      bx, bx
        jz      sea7
        cmp     byte ptr [bx+buff],']'
        jne     sea7            ; error
        jmp     seadone

        page
sea9:
        call    RemSpac
        or      bx, bx
        jz      sea10
        cmp     byte ptr [bx+buff],'+'
        je      sea11
        cmp     byte ptr [bx+buff], ']'
        jne     sea10
        jmp     seadone         ; done

sea10:
        jmp     seaerr

sea11:
        inc     bx              ; next...
        mov     [seabx], bx
        call    GetReg
        cmp     al, RBP         ; bp??
        je      sea12bp
        cmp     al, RBX         ; bx??
        je      sea12bx
        cmp     al, NOREG       ; not a register
        jne     sea10
;
;       Get Absolute offset
;
        mov     bx, [seabx]
        push    bx
        call    GetHex
        or      bx, bx
        jne     sea11b
        pop     bx
        jmp     seaerr

sea11b:
        pop     bp
        mov     bp, ax
        or      dx, 16          ; set absolute location
        jmp     sea9

sea12bp:
        or      dx, 1           ; mark bp bit
        jmp     sea9

sea12bx:
        or      dx, 2           ; mark bx bit
        jmp     sea9

sea13:
        call    RemSpac
        or      bx, bx
        jz      sea14
        cmp     byte ptr [bx+buff],'+'
        je      sea15
        cmp     byte ptr [bx+buff], ']'
        jne     sea14
        jmp     seadone         ; done

sea14:
        jmp     seaerr

        page
sea15:
        inc     bx              ; next...
        mov     [seabx], bx
        call    GetReg
        cmp     al, RBP         ; bp??
        je      sea16bp
        cmp     al, RBX         ; bx??
        je      sea16bx
        cmp     al, RSI         ; si??
        je      sea20si
        cmp     al, RDI         ; di??
        je      sea20di
        jmp     seaerr

sea20si:
        or      dx, 4           ; mark si bit
        jmp     sea20

sea20di:
        or      dx, 8           ; mark di bit
        jmp     sea20

sea16bp:
        or      dx, 1           ; mark bp bit
        jmp     short sea16

sea16bx:
        or      dx, 2           ; mark bx bit

sea16:
        call    RemSpac
        or      bx, bx
        jz      sea17
        cmp     byte ptr [bx+buff],'+'
        je      sea18
        cmp     byte ptr [bx+buff], ']'
        jne     sea17
        jmp     seadone         ; done

sea17:
        jmp     seaerr

sea18:
        inc     bx              ; next...
        mov     [seabx], bx
        call    GetReg
        cmp     al, RSI         ; si??
        je      sea19si
        cmp     al, RDI         ; di??
        je      sea19di
        jmp     seaerr

sea19si:
        or      dx, 4           ; mark si bit
        jmp     short sea19

sea19di:
        or      dx, 8           ; mark di bit

sea19:
        call    RemSpac
        or      bx, bx
        jz      seaerr
        cmp     byte ptr [bx+buff],']'
        jne     seaerr           ; error
        jmp     short seadone

sea20:
        call    RemSpac
        or      bx, bx
        jz      seaerr
        cmp     byte ptr [bx+buff],'+'
        je      sea21
        cmp     byte ptr [bx+buff], ']'
        jne     seaerr          ; error
        jmp     short seadone   ; done

        page
sea21:
        inc     bx              ; next...
        mov     [seabx], bx
        call    GetReg
        cmp     al, RBP         ; bp??
        je      sea22bp
        cmp     al, RBX         ; bx??
        je      sea22bx
        jmp     short seaerr

sea22bp:
        or      dx, 1           ; mark bp bit
        jmp     short sea22

sea22bx:
        or      dx, 2           ; mark bx bit

sea22:
        call    RemSpac
        or      bx, bx
        jz      seaerr
        cmp     byte ptr [bx+buff],']'
        jne     seaerr          ; error
        jmp     short seadone

seaerr:            ; error
        mov     bp, bx          ; place location in bp (to become ax)
        xor     bx, bx          ; zero out bx to indicate error

seadone:            ; done
        mov     ax, bp          ; place absolute locate (in bp) in ax

        pop     bp
        pop     cx
        ret
ScanEa  endp

        page
;-------------------------------------------------------------------------;
;       Function: RegSize                                                 ;
;                 Return Register and Register size                       ;
;       Input:                                                            ;
;                 BX = Position in Buffer to start                        ;
;       Output:                                                           ;
;                 AH = Register ID                                        ;
;                 AL = Register Size (0 if Byte, 1 if Word)               ;
;                 BX = next Position (0 if None Available, or Segment Reg);
;-------------------------------------------------------------------------;

RegSize proc    near
        call    GetReg          ; like it says....
        or      bx, bx
        jz      rsdone          ; error...
        xchg    al, ah
        xor     al, al          ; indicate byte
        cmp     ah, NOREG
        je      rsbad
        cmp     ah, RBH         ; test for byte register
        jbe     rsdone
        cmp     ah, RDI         ; test for word register
        jbe     rsword

rsbad:
        xor     bx, bx
        jmp     short rsdone

rsword:
        inc     al              ; add 1 to zero set above to indicate word

rsdone:
        ret
RegSize endp

        page
;-------------------------------------------------------------------------;
;       Function: GetReg                                                  ;
;                 Retrives Register name from buffer                      ;
;       Input:                                                            ;
;                 BX = Position in Buffer to start                        ;
;       Output:                                                           ;
;                 AX = Register ID #                                      ;
;                 BX = next Position (0 if None Available)                ;
;-------------------------------------------------------------------------;

GetReg  proc      near
        push      cx

greg1   label     near
        cmp       [bx+buff], ' '
        jne       greg2
        inc       bx
        cmp       bl, [lenbuff]
        jb        greg1
        jmp       greg7

greg2   label     near
        mov       ax, word ptr [bx+buff]
        inc       bx
        inc       bx
        xor       cx, cx
        push      di
        lea       di, rop2

greg3   label     near
        cmp       byte ptr [di], 0
        je        greg5
        inc       di
        cmp       word ptr [di], ax
        je        greg4
        inc       di
        inc       di
        inc       cx
        jmp       short greg3

greg4   label     near
        inc       cx
        jmp       short greg6

greg5   label     near
        xor       cx, cx

greg6   label     near
        pop       di
        or        cx, cx
        jz        greg7
        mov       ax, cx
        jmp       greg8

greg7   label     near
        xor       al, al
        xor       bx, bx
        jmp       short greg11

greg8   label     near
        mov       cl, 4         ; for shift
        mov       ah, al        ; place id in ah
        cmp       al, 14
        ja        greg9
        shl       al, cl
        cmp       al, 80h
        jbe       greg11
        cmp       al, 0c0h
        ja        greg10
        add       al, 10h
        jmp       short greg11

greg9   label     near
        sub       al, 14
        cmp       al, 9
        jb        greg11

greg10  label     near
        xor       al, al

greg11  label     near
        pop       cx
        ret
GetReg  endp


        page
;-------------------------------------------------------------------------;
;       Function: GetRang                                                 ;
;                 Retrives Hexadecimal Range from input buffer            ;
;       Input:                                                            ;
;                 SI = Segment Default                                    ;
;                 DI = offset  Default                                    ;
;                 BX = Position in Buffer to start                        ;
;                 CX = Range Default Byte Lenght                          ;
;       Output:                                                           ;
;                 AX = 0 if segment is not available (FFFF if both N/A)   ;
;                 SI = Segment                                            ;
;                 DI = offset                                             ;
;                 BX = next Position (0 if None Available)                ;
;                 BP = Last Byte offset                                   ;
;-------------------------------------------------------------------------;

GetRang proc    near
        call    GetAddr
        mov     bp, di
        add     bp, cx
        dec     bp
        or      bx, bx
        je      grang1
        call    RemSpac
        or      bx, bx
        je      grang1
        call    GetLen

grang1:
        mov     cx, di
        and     cx, 000FH
        ret
GetRang endp

        page
;-------------------------------------------------------------------------;
;       Function: GetLen                                                  ;
;                 Retrives Hexadecimal Lenght from input buffer           ;
;       Input:                                                            ;
;                 SI = Segment                                            ;
;                 DI = Offset                                             ;
;                 BX = Position in Buffer to start                        ;
;                 CX = Range Default Byte Lenght                          ;
;       Output:                                                           ;
;                 BX = next Position (0 if None Available)                ;
;                 BP = Last Byte offset                                   ;
;-------------------------------------------------------------------------;

GetLen  proc    near
        push    ax
        push    cx
        push    bx

        call    RemSpac
        cmp     byte ptr [bx+buff], ','
        jne     getlen0
        inc     bx

getlen0:
        mov     bp, di
        add     bp, cx
        mov     cx, 4
        call    GetHex
        or      bx, bx
        jz      GetLen1
        pop     cx
        cmp     di, ax
        ja      GetLen5
        mov     bp, ax
        jmp     GetLen5

getlen1:
        pop     bx

getlen2:
        mov     al, byte ptr [bx+buff]
        cmp     al, ' '
        je      getlen3
        cmp     al, 'L'
        je      getlen4
        xor     bx, bx
        jmp     short getlen5

getlen3:
        inc     bx
        cmp     [lenbuff], bl
        jae     getlen2
        xor     bx, bx
        jmp     short getlen5

getlen4:
        inc     bx
        call    GetHex
        or      bx, bx
        je      getlen5
        mov     bp, di
        add     bp, ax
        dec     bp
        cmp     bp, di
        ja      getlen5
        mov     bp, 0ffffh

getlen5:
        pop     cx
        pop     ax
        ret
GetLen  endp

        page
;-------------------------------------------------------------------------;
;       Function: GetList                                                 ;
;                 Retrives a List of bytes from the input buffer          ;
;       Input:                                                            ;
;                 BX = Position in Buffer to start                        ;
;       Output:                                                           ;
;                 BX = next Position (0 if None Available)                ;
;                 CX = # of bytes retrieved                               ;
;-------------------------------------------------------------------------;

GetList proc      near
        push      ax
        push      di
        push      es

        push      cs
        pop       es
        push      si
        mov       cx, 78
        lea       si, buffbkp
        lea       di, buff
        rep       movsb
        pop       si
        xor       cx, cx
        lea       di, getbuff

glist1  label     near
        call      RemSpac
        or        bx, bx
        jz        glist4
        cmp       byte ptr [bx+buff], 27h
        je        glist2
	cmp	  byte ptr [bx+buff],'"'
	je        glist2
        push      cx
        mov       cx, 2
        call      GetHex
        pop       cx
        or        bx, bx
        jz        glist4
        inc       cx            ; increment counter
        stosb
        jmp       glist1

glist2  label     near
        inc       bx
        mov       al, byte ptr [bx+buff]
	cmp	  al, '"'
	je        glist2a
        cmp       al, 27h
        jne       glist3

glist2a	label	  near
        inc       bx
        jmp       short glist1

glist3  label     near
        inc       cx            ; increment counter
        stosb
        cmp       bl, [lenbuff]
        jb        glist2

glist4  label     near
        pop       es
        pop       di
        pop       ax
        ret
GetList endp

        page
;-------------------------------------------------------------------------;
;       Function: GetRVal                                                 ;
;                 Retrives Hexadecimal value or value of register         ;
;       Input:                                                            ;
;                 AX = default value                                      ;
;                 BX = Position in Buffer to start                        ;
;       Output:                                                           ;
;                 AX = value                                              ;
;                 BX = next Position (0 if None Available)                ;
;-------------------------------------------------------------------------;

GetRVal proc    near
        push    cx
        push    dx
        push    bp

        or      bx, bx
        jz      grv0
        call    RemSpac
        or      bx, bx
        jz      grv2

grv0:
        mov     bp, bx          ; save for lator
        mov     dx, ax          ; this too
        call    GetReg          ; test for a register
        or      bx, bx
        jz      grv1
        xchg    al, ah
        or      al, al
        jz      grv1
        cmp     al, 13
        ja      grv1
        push    bx
        mov     bx, ax
        xor     bh, bh
        dec     bx
        shl     bx, 1           ; (regid - 1)*2
        mov     ax, [bx+regall] ; get value
        pop     bx
;;      inc     bx
;;      inc     bx
        jmp     short grv2

grv1:
        mov     bx, bp          ; restore pointer
        mov     ax, dx          ; restore default value
        mov     cx, 4
        call    GetHex

grv2:
        pop     bp
        pop     dx
        pop     cx
        ret
GetRVal endp

        page
;-------------------------------------------------------------------------;
;       Function: GetAddr                                                 ;
;                 Retrives Hexadecimal Address from input buffer          ;
;       Input:                                                            ;
;                 SI = Segment Default                                    ;
;                 DI = offset  Default                                    ;
;                 BX = Position in Buffer to start                        ;
;       Output:                                                           ;
;                 SI = Segment                                            ;
;                 DI = offset                                             ;
;                 BX = next Position (0 if None Available)                ;
;-------------------------------------------------------------------------;

GetAddr proc    near
        push    ax
        push    cx

        mov     ax, di
        call    GetRVal         ; get register value
        or      bx, bx
        jz      gaddr2
        mov     di, ax
        cmp     byte ptr [bx+buff],':'
        je      gaddr1
        jmp     gaddr2

gaddr1:
        inc     bx
        mov     ax, di
        call    GetRVal         ; get register value    
        or      bx, bx
        jz      gaddr2
        xchg    si, di
        mov     di, ax

gaddr2:
        pop     cx
        pop     ax
        ret
GetAddr endp

        page
;-------------------------------------------------------------------------;
;       Function: UserHex                                                 ;
;                 Retrives Hexadecimal # for User Directly                ;
;       Input:                                                            ;
;       Output:                                                           ;
;-------------------------------------------------------------------------;

UserHex proc    near
        push    bx
        push    dx
        push    bp
        push    si

        xor     bx, bx
        xor     si, si
        mov     bp, ax

uhloop:
        call    GetKey
        cmp     al, 0dh         ; carriage return
        je      uhdone
        cmp     al, ' '         ; space for next item
        je      uhnext
        cmp     al, 8
        jne     uh1
        or      si, si
        jz      uhloop
        lea     dx, rubout
        call    OutMsg
        dec     si
        jmp     short uhloop

uh1:
        cmp     si, 1
        ja      uhloop
        cmp     al, '0'
        jb      uhloop
        cmp     al, '9'
        ja      uh2
        mov     dl, al          ; save character for output
        sub     al, '0'
        jmp     short uhset

uh2:
        cmp     al, 'A'
        jb      uhloop
        cmp     al, 'F'
        ja      uh3
        mov     dl, al          ; save character for output
        sub     al, 'A'
        add     al, 10
        jmp     short uhset

uh3:
        cmp     al, 'a'
        jb      uhloop
        cmp     al, 'f'
        ja      uhloop
        mov     dl, al          ; save character for output
        sub     al, 'a'
        add     al, 10

uhset:
        call    OutChar
        mov     bh, 0f0h
        or      si, si
        jnz     uh4
        mov     cl, 4
        shl     al, cl
        shr     bh, cl

uh4:
        and     bl, bh
        or      bl, al
        inc     si
        jmp     short uhloop

uhdone:
        xor     cx, cx
        jmp     short uhchk

uhnext:
        mov     cx, 0ffffh

uhchk:
        or      si, si
        jnz     uh5
        mov     ax, bp
        jmp     short udinit

uh5:
        mov     ax, bp
        mov     al, bl
        cmp     si, 1
        jnz     udinit
        push    cx
        mov     cl, 4
        shr     al, cl
        pop     cx
        and     al, 0fh

udinit:
        cmp     si, 2
        jae     uhend
        push    cx
        mov     cx, 2
        sub     cx, si

udisp:
        mov     dl, ' '
        call    OutChar
        loop    udisp

        pop     cx

uhend:
        pop     si
        pop     bp
        pop     dx
        pop     bx
        ret
UserHex endp

        page
;-------------------------------------------------------------------------;
;       Function: GetHex                                                  ;
;                 Retrives Hexadecimal # for Input Buffer                 ;
;       Input:                                                            ;
;                 CX = Lenght to retrieve 1-4 Not Value Check (MAX)       ;
;                 BX = Position in Buffer to start                        ;
;       Output:                                                           ;
;                 AX = number Retrive                                     ;
;                 BX = next Position (0 if None Available)                ;
;-------------------------------------------------------------------------;


GetHex  proc    near
        push    cx
        push    dx
        push    bp

        xor     bp, bp
        xor     ax, ax
        mov     dh, 255
        or      bx, bx
        jz      ghex1
        call    RemSpac
        or      bx, bx
        jz      ghex7

ghex1:
        mov     dl, byte ptr [bx+buff]
        cmp     dl, ' '
        je      ghex4
        cmp     dl, '0'
        jb      ghex2
        cmp     dl, '9'
        ja      ghex2
        sub     dl, '0'
        jmp     ghex3

ghex2:
        and     dl, 0dfh
        cmp     dl, 'A'
        jb      ghex4
        cmp     dl, 'F'
        ja      ghex4
        sub     dl, 'A'-10

ghex3:
        inc     bp
        xor     dh, dh
        push    cx
        mov     cx, 4
        shl     ax, cl
        pop     cx
        add     ax, dx
        inc     bx
        dec     cx
        or      cx, cx
        jz      ghex4
        jmp     ghex1

ghex4:
        mov     dl, byte ptr [bx+buff]  ; is next character valid
        cmp     dl, ' '
        je      ghex6
        or      dl, dl
        jz      ghex6
        cmp     dl, 0dh
        je      ghex6
        cmp     dl, 0ah
        je      ghex6
        cmp     dl, '+'         ; next char a '+'
        je      ghex6
        cmp     dl, ']'
        je      ghex6
        cmp     dl, ':'
        je      ghex6
        cmp     dl, ','
        je      ghex6
        xor     bx, bx          ; must be error
        jmp     short ghex7

ghex6:
        cmp     dh, 255
        jne     ghex7
        xor     bx, bx          ; error because of no valid input

ghex7:
        pop     bp
        pop     dx
        pop     cx
        ret
GetHex  endp

        page
;-------------------------------------------------------------------------;
;       Function: RemSpac                                                 ;
;                 Removes spaces from command line                        ;
;       Input:                                                            ;
;                 BX   - pointer to parameters                            ;
;       Output:                                                           ;
;                 BX   - pointer to parameters  (0 if End of List)        ;
;-------------------------------------------------------------------------;

RemSpac proc      near
        push      ax

rem1    label     near
        mov       al, [bx+buff]
        or        al, al
        jz        rem2
        cmp       al, ' '
        jne       rem3
        inc       bx
        cmp       bl, [lenbuff]
        jbe       rem1

rem2    label     near
        xor       bx, bx        ; error end of buffer

rem3    label     near
        pop       ax
        ret
RemSpac endp

        page
;-------------------------------------------------------------------------;
;       Function: ScanCom                                                 ;
;                 Scans buffer for first comma                            ;
;       Input:                                                            ;
;                 BX   - pointer to parameters                            ;
;       Output:                                                           ;
;                 BX   - pointer to parameters  (0 if End of List)        ;
;                        first non-space after comma                      ;
;-------------------------------------------------------------------------;

ScanCom proc    near
        push    ax
        mov     al, ','
        call    ScByte          ; scan for ','
        pop     ax
        ret
ScanCom endp


        page
;-------------------------------------------------------------------------;
;       Function: ScanSea                                                 ;
;                 Scans buffer for first '['                              ;
;       Input:                                                            ;
;                 BX   - pointer to parameters                            ;
;       Output:                                                           ;
;                 BX   - pointer to parameters  (0 if End of List)        ;
;                        first non-space after comma                      ;
;-------------------------------------------------------------------------;

ScanSea proc    near
        push    ax
        mov     al, '['
        call    ScByte          ; scan for '['
        pop     ax
        ret
ScanSea endp

        page
;-------------------------------------------------------------------------;
;       Function: ScByte                                                  ;
;                 Scans buffer for first byte in al                       ;
;       Input:                                                            ;
;                 AL   - byte to scan for                                 ;
;                 BX   - pointer to parameters                            ;
;       Output:                                                           ;
;                 BX   - pointer to parameters  (0 if End of List)        ;
;                        first non-space after comma                      ;
;-------------------------------------------------------------------------;

ScByte  proc      near
        push      cx
        mov       cl, al

scbyte1 label     near
        mov       al, [bx+buff]
        inc       bx
        or        al, al
        jz        scbyte2
        cmp       al, cl
        je        scbyte3
        cmp       bl, [lenbuff]
        jbe       scbyte1

scbyte2 label     near
        xor       bx, bx        ; error end of buffer
        jmp       short scbyte4

scbyte3 label     near
        call      RemSpac

scbyte4 label     near
        pop       cx
        ret
ScByte  endp

        page
;-------------------------------------------------------------------------;
;       Function: MakeFcb                                                 ;
;                 Creates FCB entry for name command                      ;
;       Input:                                                            ;
;                 DS:SI - input line buffer                               ;
;                 ES:DI - fcb buffer location 16 bytes                    ;
;       Output:                                                           ;
;                 FCB at ES:DI                                            ;
;-------------------------------------------------------------------------;

MakeFcb proc    near
        push    ax
        push    bx
        push    cx
        push    di

        push    di              ; init FCB to 0, 11 dup (' '), 4 dup (0)
        xor     al, al
        stosb
        mov     cx, 11
        mov     al, ' '
        rep     stosb
        xor     al, al
        mov     cl, 5
        rep     stosb
        pop     di

        inc     di
        mov     bx, di          ; save di for extension
        xor     cl, cl
        mov     ch, 8           ; set for filename

mf1:
        lodsb
        cmp     al, ' '
        je      mf1
        jmp     short mf3

mf2:
        lodsb

mf3:
        or      al, al
        jz      mfdone
        cmp     al, 0dh
        je      mfdone
        cmp     al, '.'
        je      mf4
        cmp     al, ' '
        je      mfdone
        stosb
        inc     cl
        cmp     cl, ch
        jbe     mf2

mferror:
        xor     si, si          ; indicate error
        jmp     short mfdone

mf4:
        mov     di, bx
        add     di, 8
        xor     cl, cl          
        mov     ch, 3           ; set for extension
        jmp     short mf1       

mfdone:
        pop     di
        pop     cx
        pop     bx
        pop     ax
        ret
MakeFcb endp

        page
;-------------------------------------------------------------------------;
;       Function: MkPath                                                  ;
;                 Creates Path from filename and current directory        ;
;       Input:                                                            ;
;                 CX   - len of file name                                 ;
;                 SI   - offset of file name                              ;
;       Output:                                                           ;
;                 Path created in Path                                    ;
;-------------------------------------------------------------------------;

MkPath  proc      near
        push      cx
        push      si
        push      di
        push      es

        push      cs
        pop       es
        lea       di, path
        cmp       byte ptr [si], '\'    ; skip \path
        je        mpatha
        cmp       byte ptr [si+1], ':'  ; skip d:path 
        je        mpatha
        push      cx
        push      si
        mov       cl, [cdirlen]
        xor       ch, ch
        add       cl, 3
        lea       si, current
        rep       movsb
        dec       di
        cmp       byte ptr [di], '\'
        je        mpaths
        inc       di
        mov       byte ptr [di], '\'

mpaths  label     near
        inc       di
        pop       si
        pop       cx

mpatha  label     near
        lodsb    
        cmp       al, ' '
        je        mpatha

mpathb  label     near
        dec       si

mpathc  label     near
        push      si

mpath1  label     near
        lodsb
        or        al, al
        jz        mpath2
        cmp       al, ' '
        je        mpath2
        cmp       al, 0dh
        je        mpath2
        stosb
        jmp       short mpath1

mpath2  label     near
        mov       byte ptr [di], 0

        pop       si

        pop       es
        pop       di
        pop       si
        pop       cx
        ret
MkPath  endp


        page
;-------------------------------------------------------------------------;
;       Function: LoadPrg                                                 ;
;                 Loads Program in at cs:100 of the debugger which is     ;
;                 Actually at the end of debug.com (Paragraph).  This     ;
;                 routine actually loads program at specified param block ;
;       Input:                                                            ;
;                 BX   - offset to parameter block                        ;
;                 CX   - len of file name                                 ;
;                 SI   - offset of file name                              ;
;       Output:                                                           ;
;                 None - displays information to screen                   ;
;-------------------------------------------------------------------------;

LoadPrg proc      near
        push      cx
        push      dx
        push      si
        push      di

        push      si
	mov	  [fullload], 1		; indicated that we have a full load
        mov       [exeflag], 0          ; not an exe or comfile

loadexe label     near
        lodsb
        cmp       al, '.'
        jne       loadexe
        lodsb
        and       al, 0DFH
        cmp       al, 'E'
        jne       lcomtst
        lodsw
        and       ax, 0dfdfh
        cmp       ax, 'EX'
        jne       lexedon
        mov       [exeflag], 1          ; exe found
        jmp       lexefin

lcomtst label     near
        cmp       al, 'C'
        jne       lexedon
        lodsw
        and       ax, 0dfdfh
        cmp       ax, 'MO'
        je        lexefin       

lexedon label     near
        mov       [exeflag], 0ffh       ; not exe or com 

lexefin label     near
        pop       si
        

        call      MkPath                ; create path
        push      bx
        push      cx
        push      si
        xor       dx, dx
        lea       si, path
        
chkloop label     near
        mov       dh, al                ; save last char
        lodsb           
        or        al, al                ; end of line   
        jz        chkdone
        cmp       al, '\'
        jne       chkloop
        cmp       dh, '\'
        jne       chkloop
        mov       dl, 2                 ; can't find file - invalid path

chkdone label     near
        pop       si
        or        dl, dl
        jz        chkok
        mov       [lasterr], dl
        pop       cx
        pop       bx
        jmp       loadend
        
chkok   label     near
        mov       ax, 3d00h
        lea       dx, path
        int       21h
        jc        lprg1
        mov       bx, ax
        mov       ax, 4202h
        xor       cx, cx
        xor       dx, dx
        int       21h
        mov       [regcx], ax
        mov       [regbx], dx
        mov       ah, 3eh
        int       21h

lprg1   label     near
        pop       cx
        pop       bx


        cmp       [exeflag], 0ffh       ; exe or com use 4B01   
        je        lprgfil
        jmp       lprg4b

lprgfil label     near
        mov       dx, [regcs]
        mov       [childpsp], dx
        mov       ah, 26h               ; create psp for child  
        int       21h
        mov       bx, [debugpsp]
        mov       ah, 50h
        int       21h

        mov       ax, 3d00h
        lea       dx, path
        int       21h

        push      bx
        push      si
        push      di
        push      ds

        mov       bx, ax        
        mov       ax, [regcs]
        add       ax, 10h               ; add 100h for psp
        mov       si, [regbx]           ; get higher count
        mov       di, [regcx]           ; get lower count
        mov       ds, ax
        xor       dx, dx

manlp1  label     near
        mov       cx, 0ff00h            ; read max in
	call	  chksize		; verify size
        or        di, di                ; nothing more to read
        jz        mandone

manlp2  label     near
        mov       ah, 3fh
        int       21h
        jc        manerr
        jcxz      manerr
        cmp       ax, cx
        jnz       manerr
	cmp	  cs:[fullload],0
	je	  mandone
        sub       di, ax
        sbb       si, 0
        mov       dx, ax
        and       dx, 000fh             
        mov       cx, ds
        shr       ax, 1
        shr       ax, 1
        shr       ax, 1
        shr       ax, 1
        add       ax, cx
        mov       ds, ax
        jmp       manlp1


manerr  label     near
        mov       cs:[lasterr], 30
        mov       cs:[isload], 0
        jmp       mancls

mandone label     near
        mov       cs:[nfile], 1

mancls  label     near
        mov       ah, 3eh
        int       21h

manfin  label     near
        pop       ds
        pop       di
        pop       si    
        pop       bx    
        
        mov       ah, 3eh               ; close file
        int       21h   

        lea       dx, Term
        mov       ax, 2522h
        int       21h
        jmp       loadtrm               ; continue

lprg4b  label     near
        lea       dx, path
        mov       ax, [envseg]
        mov       word ptr [bx], ax
        mov       word ptr [bx+4], cs

lpinit1 label     near                  ; skip over first parameter
        lodsb   
        or        al, al
        je        lpinit3
        cmp       al, 0dh
        je        lpinit3
        cmp       al, ' '
        je        lpinit1
                
lpinit2 label     near
         lodsb   
         or        al, al
         jz        lpinit3
         cmp       al, 0dh
         je        lpinit3
         cmp       al, ' '
         jne       lpinit2

lpinit3 label     near
        dec       si
        push      si
        xor       cx, cx
        
lpline1 label     near
        lodsb
        or        al, al
        jz        lpline2
        cmp       al, 0dh
        je        lpline2
        inc       cl
        jmp       short lpline1

lpline2 label     near
        pop       si
        or        cl, cl
        jnz       lprg2
        mov       byte ptr [si], 0dh

lprg2   label     near
        dec       si
        mov       byte ptr [si], cl
        mov       word ptr [bx+2], si
        mov       ax, [regcs]
        mov       word ptr [bx+08h], ax
        mov       word ptr [bx+0ch], ax		;SAH 10/20/87 was 0bh
        mov       ax, 4b01h
        push      bx

        push      ax
        call      SizeMin       ; shrink to min size
        or        ax, ax
        jz        lprg2ok
        pop       ax
        mov       ax, 8         ; indicated insuffient memory
        jmp       lperror

lprg2ok label     near
        pop       ax

lpbegin label     near
        int       21h
lpend   label     near


        jc        lperror
        xor       al, al
        mov       cs:[isload], 1           ; indicate that file has been load

lperror label     near
        mov       cs:[lasterr], al
        or        al, al
        jz        loadreg
        pop       bx
        jmp       loadend


loadreg label     near

;       set Int 22 to point to DEBUG's terminate routine


        push      dx

        lea       dx, Term
        mov       ax, 2522h
        int       21h

        pop       dx


        pop       bx

        mov       ax, word ptr [bx+0eh]
        inc       ax
        inc       ax
        mov       [regsp], ax
        mov       ax, word ptr [bx+10h]
        mov       [regss], ax
        mov       ax, word ptr [bx+12h]
        mov       [regip], ax
        mov       [asmloc+2], ax
        mov       [uasmloc+2], ax
        mov       ax, word ptr [bx+14h]
        mov       [regcs], ax
        mov       [regds], ax
        mov       [reges], ax
        mov       [regcs], ax
        mov       [asmloc], ax
        mov       [uasmloc], ax
        mov       [dumploc], ax

        push      bx
        mov       ah, 51h
        int       21h
        mov       ax, bx
        pop       bx

        mov       [childpsp], ax

;       check for EXE if so set ds and es to psp


        cmp       [exeflag], 0          ; skip if com
        je        loadtrm
        mov       [regds], ax
        mov       [reges], ax
        mov       [dumploc], ax
        cmp       [exeflag], 1          ; skip if exe
        je        loadtrm
        mov       [regcs], ax
        mov       [asmloc], ax
        mov       [uasmloc], ax

loadtrm label     near

;--------------------------------------------------------------------------;
;       Modified terminate offset in childs psp, 4b01 set terminate to     ;
;       to instruction after MOS call which is LABEL LPEND                 ;
;--------------------------------------------------------------------------; 

        push      es
        mov       es, [childpsp]
        mov       word ptr es:[0ah], offset Term
        mov       word ptr es:[0ch], cs
        pop       es

        mov       ax, 100h
        mov       [wrloc], ax

loadend label     near
	mov	  cs:[nfile], 1		; Indicate that file is name
        pop       di
        pop       si
        pop       dx
        pop       cx
        ret
LoadPrg endp

ChkSize proc	near
	push	ax
	push	bx
        or      si, si                ; no high value
        jnz     CS2
        or      di, di                ; nothing more to read
        jz      CSend
        cmp     di, cx
        ja      CS2
        mov     cx, di                ; load only low value
CS2:
	mov	ax,cx
	add	ax,15
	shr	ax,1
	shr	ax,1
	shr	ax,1
	shr	ax,1
	mov	bx,ds
	add	ax,bx
	cmp	ax,cs:[maxmem]
	jbe	CSend	
	mov	cs:[fullload],0		; indicate that we could not load
	cmp	bx,cs:[maxmem]
	jae	CSend
	mov	ax,cs:[maxmem]
	sub	ax,bx
	mov	cl,4
	shl	ax,cl
	mov	cx,ax
CSend:
	pop	bx
	pop	ax
	ret
ChkSize endp	


        page
;-------------------------------------------------------------------------;
;       Function: SynErr                                                  ;
;                 Display Syntax Error Message                            ;
;       Input:                                                            ;
;                 BH = # of spaces to tab over                            ;
;       Output:                                                           ;
;                 None - displays information to screen                   ;
;-------------------------------------------------------------------------;

SynErr  proc    near
        push    cx              ; display error message
        push    dx
        mov     cl, bh
        xor     ch, ch
        mov     dl, ' '

serr:
        call    OutChar
        loop    serr
        lea     dx, syntax
        call    OutMsg

        pop     dx
        pop     cx
        ret
SynErr  endp

        page
;-------------------------------------------------------------------------;
;       Function: ErrMsg                                                  ;
;                 Display Approriate Error Message                        ;
;       Input:                                                            ;
;                 AX = Error ID #  (from MOS)                             ;
;       Output:                                                           ;
;                 None - displays information to screen                   ;
;-------------------------------------------------------------------------;

ErrMsg  proc     near
        push     ax
        push     dx

	mov	 dx,offset notall
	cmp	 [fullload],0
	je	 errdisp
        mov      al, cs:[lasterr]
        or       al, al
        jz       errdone
        cmp      ax, 2
        ja       errmsg1
        lea      dx, fnfmsg
        jmp      short  errdisp

errmsg1 label    near
        cmp      ax, 8
        jne      errmsg2
        lea      dx, nommsg
        jmp      short errdisp

errmsg2 label    near
        cmp      ax, 30
        jne      errgen
        lea      dx, rdmsg
        jmp      short errdisp

errgen  label    near
        lea      dx, rdmsg

errdisp label    near
        push    ds
        push    cs
        pop     ds
        call    OutMsg
        lea     dx, crlf
        call    OutMsg
        pop     ds

errdone label    near
        pop      dx
        pop      ax
        ret
ErrMsg  endp

        page
;-------------------------------------------------------------------------;
;       Function: ToFlag                                                  ;
;                 converts internal flag format to actual flags           ;
;       Input:                                                            ;
;                 AX - Internal format of flags                           ;
;       Output:                                                           ;
;-------------------------------------------------------------------------;

ToFlag  proc    near
        push    ax
        push    bx
        push    cx
        push    dx

        mov     bx, ax          ; save a copy
        xor     dx, dx          ; clear mask
        mov     cl, 4
        shl     ax, cl
        and     ah, 0eh
        mov     dh, ah          ; sets bits 5-7
        mov     al, bl          ; get a copy
        mov     cl, 3
        shl     al, cl
        and     al, 0c0h
        mov     dl, al          ; sets bits 3-4
        mov     al, bl          ; get a copy
        shl     al, 1
        shl     al, 1
        and     al, 10h
        or      dl, al          ; sets bit 2
        mov     al, bl          ; get a copy
        shl     al, 1
        and     al, 04h
        or      dl, al          ; sets bit 1
        and     bl, 1
        or      dl, bl          ; sets bit 0
        mov     ax, cs:[regflag]   ; get flags
        and     ax, 0f12ah      ; mask out flag bits
        or      ax, dx          ; or in bits
        mov     cs:[regflag], ax   ; save flags

        pop     dx
        pop     cx
        pop     bx
        pop     ax
        ret
ToFlag  endp

        page
;-------------------------------------------------------------------------;
;       Function: FrFlag                                                  ;
;                 converts actualflags to internal flag format            ;
;       Input:                                                            ;
;       Output:                                                           ;
;                 AX - Internal format of flags                           ;
;-------------------------------------------------------------------------;

FrFlag  proc    near
        push    bx
        push    cx
        push    dx

        mov     ax, word ptr cs:[regflag]   ; get flags
        mov     bx, ax          ; save a copy
        xor     dx, dx          ; zero mask
        mov     cl, 4
        shr     ax, cl
        and     al, 0e0h
        mov     dl, al          ; sets bits 5-7
        mov     al, bl          ; get a copy
        mov     cl, 3
        shr     al, cl
        and     al, 18h
        or      dl, al          ; sets bits 3-4
        mov     al, bl          ; get a copy
        shr     al, 1
        shr     al, 1
        and     al, 04h
        or      dl, al          ; set bit 2
        mov     al, bl          ; get a copy
        shr     al, 1
        and     al, 02h
        or      dl, al          ; set bit 1
        and     bl, 1
        or      dl, bl          ; set bit 0
        mov     ax, dx          ; return mask

        pop     dx
        pop     cx
        pop     bx
        ret
FrFlag  endp

        page
;-------------------------------------------------------------------------;
;       Function: DispFg                                                  ;
;                 Display Flags in Debug style format at current location ;
;       Input:                                                            ;
;                 None - get flags from location regflag                  ;
;       Output:                                                           ;
;                 None - displays information to screen                   ;
;-------------------------------------------------------------------------;

DispFg  proc    near
        push    ax
        push    bx
        push    cx
        push    dx
        push    di

        mov     cx, 8
        xor     di, di
        call    FrFlag          ; get flags format
        mov     bx, ax

dispfg1:            ;  set flags to off (display) or on
        shl     bx, 1
        mov     al, '0'         ; default to off
        test    bh, 1
        jz      dispfg2
        inc     al              ; set on

dispfg2:
        mov     byte ptr [di+flagbuf], al       
        inc     di              ;  point to next position in buffer
        loop    dispfg1

        lea     dx, flagbuf
        call    OutMsg

        pop     di
        pop     dx
        pop     cx
        pop     bx
        pop     ax
        ret
DispFg  endp

        page
;-------------------------------------------------------------------------;
;       Function: DispOp                                                  ;
;                 Diplays Current Location and Instruct to screen         ;
;       Input:                                                            ;
;                 DS = Code Segment of Instruction                        ;
;                 BX = Code Offset of Instruction                         ;
;       Output:                                                           ;
;                 None Displays Information to screen                     ;
;-------------------------------------------------------------------------;

DispOp  proc    near
        push    ax
        push    cx
        push    dx
        push    si
        push    di
        push    bp
        push    ds
        push    es


        mov     si, ds
        push    cs
        pop     ds
        push    cs
        pop     es
        lea     di, opbuff
        mov     ax, 2020h
        mov     cx, 39
        rep     stosw           ; clear buffer
        mov     es, si
        mov     ax, es
        lea     di, opbuff
        mov     cl, 1           ; use full word
        call    MakeHex         ; set code segment
        makech  ':'
        mov     ax, bx
        mov     bp, bx
        call    MakeHex         ; set code instruction pointer
        inc     di
        mov     al, byte ptr es:[bx]
        xor     cl, cl          ; single byte
        call    MakeHex
        xor     ah, ah
        cmp     al, 82h
        je      is8283
        cmp     al, 83h
        jne     not_83

is8283:
        lea     dx, op8283
        jmp     setextr

not_83:
        cmp     al, 0f6h
        jne     not_f6
        lea     dx, opf6
        jmp     setextr

not_f6:
        cmp     al, 0f7h
        jne     not_f7
        lea     dx, opf7
        jmp     setextr

not_f7:
        cmp     al, 0feh
        jne     not_fe
        lea     dx, opfe
        jmp     setextr

not_fe:
        cmp     al, 0ffh
        jne     not_ff
        lea     dx, opff
        jmp     setextr

not_ff:
        cmp     al, 080h
        jne     not_80
        lea     dx, op80
        jmp     setextr

not_80:
        cmp     al, 081h
        jne     not_81
        lea     dx, op81
        jmp     setextr

not_81:
        cmp     al, 0D0H
        je      isd0d1
        cmp     al, 0D1H
        jne     notd0d1

isd0d1:
        lea     dx, opd0d1
        jmp     setextr

notd0d1:
        cmp     al, 0D2H
        je      isd2d3
        cmp     al, 0D3H
        jne     notd2d3

isd2d3:
        lea     dx, opd2d3

setextr:
        sub     dx, offset opptr
        shr     dx, 1
        shr     dx, 1
        mov     al, byte ptr es:[bx+1]
        shr     al, 1
        shr     al, 1
        shr     al, 1
        and     ax, 7
        add     ax, dx

notd2d3:
        mov     si, ax
        shl     si, 1
        shl     si, 1
        mov     dx, word ptr [si+opptr]
        mov     cl, dh
        inc     bx
        or      cl, cl
        jz      dispop2
        test    cl, 80h
        jz      dispop1
        and     cl, 0FH
        mov     al, byte ptr es:[bx]
        push    cx
        mov     cl, 6
        shr     al, cl
        pop     cx
        cmp     al, 2
        ja      dispop1
        or      al, al
        jnz     not_ffa
        mov     al, byte ptr es:[bx]
        and     al, 7
        cmp     al, 6
        jne     dispop1
        mov     al, 2

not_ffa:
        add     cl, al

dispop1:
        mov     al, byte ptr es:[bx]
        push    cx
        xor     cl, cl          ; single byte
        call    MakeHex
        inc     bx
        pop     cx
        loop    dispop1

dispop2:
        mov     si, word ptr [si+2+opptr]
        mov     cl, byte ptr [si]
        or      cl, cl
        jz      dispop4
        lea     di, opbuff
        add     di, 24
        xor     ch, ch

dispop3:
        inc     si
        mov     al, byte ptr [si]
        mov     byte ptr [di], al
        inc     di
        loop    dispop3

dispop4:
        lea     di, opbuff

dispop5:
        mov     al, 32

dispop6:
        xor     ah, ah
        add     di, ax
        push    bx
        mov     bx, dx
        cmp     bl, 2Dh
        jbe     dispop7
        pop     bx
        jmp     dispop8         ; invalid condition

dispop7:
        xor     bh, bh
        mov     [valbx], bx
        shl     bx, 1
        call    word ptr [bx+dopfun]

;	TEMPORARY  For Debugging

;;      lea     di, opbuff
;;      add     di, 70  
;;      mov     ax, [valbx]
;;      xor     cx, cx
;;      call    MakeHex

;       TEMPORARY  For Debugging

        pop     bx
        jmp     dispop8

dopret:
        ret

        page
dop00:
        mov     bx, bp
        mov     ah, byte ptr es:[bx+1]
        mov     dh, ah
        and     dh, 7
        mov     dl, ah
        mov     cl, 6
        shr     dl, cl
        cmp     dl, 3
        je      dop002
        cmp     dl, 1
        je      dop001
        mov     ax, word ptr es:[bx+2]
        jmp     short dop002
dop001:
        mov     al, byte ptr es:[bx+2]
dop002:
        mov     cl, byte ptr es:[bx]
        and     cx, 1
        cmp     dl, 3
        je      dop003
        mov     cx, 1
        cmp     dl, 1
        jne     dop003
        xor     cl, cl
dop003:
        call    MakeEA
        makech  ','
        mov     bx, bp
        mov     al, byte ptr es:[bx+1]
        shr     al, 1
        shr     al, 1
        shr     al, 1
        and     ax, 7
        mov     cl, byte ptr es:[bx]
        lea     bx, rop1
        test    cl, 1
        jz      dop004
        lea     bx, rop2
dop004:
        xor     ah, ah
        add     bx, ax
        shl     ax, 1           ; assumes table entry is 3 bytes
        add     bx, ax
        call    MakeReg
        ret

dop01:
        mov     bx, bp
        mov     al, byte ptr es:[bx+1]
	mov	ah,al
        mov     cl, byte ptr es:[bx]
        lea     bx, rop1
        test    cl, 1
        jz      dop011
        lea     bx, rop2
dop011:
	and	ah,0c0h
	cmp	ah,0c0h
	jne	dop01i
	and	ax,7
	push	ax
	push	bx
	push	bx
	mov	bx, bp
	mov	al, byte ptr es:[bx+1]
	pop	bx
	shr	al,1
	shr	al,1
	shr	al,1
	and	ax,7
	add	bx, ax
        shl     ax, 1           ; assumes table entry is 3 bytes
        add     bx, ax
        call    MakeReg
	mov	bx, bp
        makech  ','
	pop	bx
	pop	ax
	xor	ah, ah
        add     bx, ax
        shl     ax, 1           ; assumes table entry is 3 bytes
        add     bx, ax
        call    MakeReg
	ret

dop01i:
	shr     al, 1
	shr     al, 1
	shr     al, 1
	and	ax, 7
	xor	ah, ah
        add     bx, ax
        shl     ax, 1           ; assumes table entry is 3 bytes
        add     bx, ax
        call    MakeReg
	makech	','
	mov	bx, bp
	mov	ah, byte ptr es:[bx+1]
	mov	dh, ah
        and     dh, 7
        mov     dl, ah
        mov     cl, 6
        shr     dl, cl
        cmp     dl, 3
        je      dop013
        cmp     dl, 1
        je      dop012
        mov     ax, word ptr es:[bx+2]
        jmp     short dop013a
dop012:
        mov     al, byte ptr es:[bx+2]
	jmp	short	dop013a
dop013:
	mov	dh,byte ptr es:[bx+1]
	shr	dh,1
	shr	dh,1
	shr	dh,1
	and	dh,7
dop013a:
        mov     cl, byte ptr es:[bx]
        and     cx, 1
        cmp     dl, 3
        je      dop014
        mov     cx, 1
        cmp     dl, 1
        jne     dop014
        xor     cl, cl
dop014:
        call    MakeEA
        ret

dop02:
        lea     bx, robal
        call    MakeReg
        mov     bx, bp
        makech  ','
        mov     bx, bp
        mov     al, byte ptr es:[bx+1]
        xor     ah, ah
        xor     cl, cl
        call    makehex
        ret

dop03:
        lea     bx, ropax
        call    MakeReg
        makech  ','
        mov     bx, bp
        mov     ax, word ptr es:[bx+1]
        mov     cl, 1
        call    makehex
        ret

dop04:
        mov     bx, bp
        mov     bl, byte ptr es:[bx]
        and     bx, 7
        mov     ax, bx
        shl     ax, 1
        add     bx, ax
        add     bx, offset rop2
        call    MakeReg
        ret

dop05:
        mov     bx, bp
        mov     bl, byte ptr es:[bx]
        and     bl, 00011000B
        shr     bl, 1
        shr     bl, 1
        shr     bl, 1
        xor     bh, bh
        mov     ax, bx
        shl     ax, 1
        add     bx, ax
        add     bx, offset ropsreg
        call    MakeReg
        ret

dop06:
        mov     bx, bp
        mov     ax, word ptr es:[bx+1]
        mov     cl, 1
        call    MakeHex
        ret

dop08:                            ; shift [], 1 case
        mov     bx, bp
        mov     ah, byte ptr es:[bx+1]
        mov     dh, ah
        and     dh, 7
        mov     dl, ah
        mov     cl, 6
        shr     dl, cl
        mov     cl, byte ptr es:[bx]
        and     cx, 1
        cmp     dl, 3
        je      dop082
        cmp     dl, 1
        je      dop081
        mov     ax, word ptr es:[bx+2]
        mov     cl, 1                   ; set word lenght
        jmp     short dop082
dop081:
        mov     al, byte ptr es:[bx+2]
        xor     cl, cl                  ; set byte lenght
dop082:
        call    MakeEA
        makech  ','
        makech  '1'
        ret

dop09:                            ; shift [], cl case
        mov     bx, bp
        mov     ah, byte ptr es:[bx+1]
        mov     dh, ah
        and     dh, 7
        mov     dl, ah
        mov     cl, 6
        shr     dl, cl
        mov     cl, byte ptr es:[bx]
        and     cx, 1
        cmp     dl, 3
        je      dop092
        cmp     dl, 1
        je      dop091
        mov     ax, word ptr es:[bx+2]
        mov     cl, 1                           ; set word lenght
        jmp     short dop092
dop091:
        mov     al, byte ptr es:[bx+2]
        xor     cl, cl                          ; set byte lenght
dop092:
        call    MakeEA
        makech  ','
        makech  'C'
        makech  'L'
        ret

dop0a:
        mov     bx, bp
        mov     al, byte ptr es:[bx+1]
        xor     ah, ah
        test    al, 80h
        jz      dop0a1
        add     ax, bx
        dec     ah
        inc     ax
        inc     ax
        jmp     dop0a2
dop0a1:
        add     ax, bx
        inc     ax
        inc     ax
dop0a2:
        mov     cl, 1
        call    MakeHex
        ret

dop0b:
        mov     bx, bp
        mov     ax, word ptr es:[bx+1]
        add     ax, bx
        add     ax, 0003h
        mov     cl, 1
        call    MakeHex
        ret

dop0c:
        mov     bx, bp
        mov     ax, word ptr es:[bx+3]
        mov     cl, 1
        call    MakeHex
        makech  ':'
        mov     ax, word ptr es:[bx+1]
        call    MakeHex
        ret

dop0e:
        mov     bx, bp
        mov     ah, byte ptr es:[bx+1]
        mov     dh, ah
        and     dh, 7
        mov     dl, ah
        mov     cl, 6
        shr     dl, cl
        mov     ax, word ptr es:[bx+2]
        xor     cl, cl
        call    MakeEA
        ret

dop0f:
        mov     bx, bp
        mov     ah, byte ptr es:[bx+1]
        mov     dh, ah
        and     dh, 7
        mov     dl, ah
        mov     cl, 6
        shr     dl, cl
        mov     ax, word ptr es:[bx+2]
        mov     cl, 1
        call    MakeEA
        ret

dop10:
        mov     bx, bp
        mov     bl, byte ptr es:[bx]
        and     bx, 7
        mov     ax, bx
        shl     ax, 1
        add     bx, ax
        add     bx, offset rop1
        call    MakeReg
        ret

dop11:
        mov     bx, bp
        mov     ah, byte ptr es:[bx+1]
        mov     dh, ah
        and     dh, 7
        mov     dl, ah
        mov     cl, 6
        shr     dl, cl
        xor     cx, cx
        cmp     dl, 3
        je      dop11b
        mov     ah, byte ptr es:[bx]
        lea     bx, modword
        test    ah, 1
        jnz     dop11a
        lea     bx, modbyte
dop11a:
        call    MakeReg
        inc     di
dop11b:
        mov     bx, bp
        mov     ax, word ptr es:[bx+2]
        mov     cl, byte ptr es:[bx]
        and     cx, 1
        cmp     dl, 3
        je      dop11c
        mov     cx, 1
        cmp     dl, 1
        jne     dop11c
        xor     cx, cx
        mov     al, byte ptr es:[bx+2]
        xor     ah, ah
dop11c:
        call    MakeEA
        makech  ','
        mov     bx, bp
        or      dl, dl          ; special case mod=00 r/m=110
        jnz     dop11d
        cmp     dh, 6
        jne     dop11d
        mov     dl, 2
dop11d:
        cmp     dl, 3
        je      dop11e
        xor     dh, dh
        add     bx, dx          ; adjust for word size
dop11e:
        xor     cl, cl
        mov     al, byte ptr es:[bx+2]
        call    MakeHex
        ret

dop12:
        mov     bx, bp
        mov     ah, byte ptr es:[bx+1]
        mov     dh, ah
        and     dh, 7
        mov     dl, ah
        mov     cl, 6
        shr     dl, cl
        cmp     dl, 3
        je      dop12a
        lea     bx, modword
        call    MakeReg
        inc     di
dop12a:
        mov     bx, bp
        mov     ax, word ptr es:[bx+2]
        mov     cl, 1
        call    MakeEA
        makech  ','
        or      dl, dl          ; special case mod=00 r/m=110
        jnz     dop12b
        cmp     dh, 6
        jne     dop12b
        mov     dl, 2
dop12b:
        cmp     dl, 3
        je      dop12c
        xor     dh, dh
        add     bx, dx          ; adjust for word size
dop12c:
        mov     ax, word ptr es:[bx+2]
        call    MakeHex
        ret

dop13:
        mov     bx, bp
        mov     bl, byte ptr es:[bx]
        and     bx, 7
        mov     ax, bx
        shl     ax, 1
        add     bx, ax
        add     bx, offset rop2
        call    MakeReg
        ret

dop14:
        mov     bx, bp
        mov     bl, byte ptr es:[bx+1]
        shr     bl, 1
        shr     bl, 1
        shr     bl, 1
        and     bx, 7
        mov     ax, bx
        shl     ax, 1
        add     bx, ax
        add     bx, offset rop2
        call    MakeReg
        makech  ','
        mov     bx, bp
        mov     ah, byte ptr es:[bx+1]
        mov     dh, ah
        and     dh, 7
        mov     dl, ah
        mov     cl, 6
        shr     dl, cl
        xor     cx, cx
        cmp     dl, 1
        je      dop14a
        mov     ax, word ptr es:[bx+2]
        inc     cx
        jmp     dop14b

dop14a:
        mov     al, byte ptr es:[bx+2]
        xor     ah, ah

dop14b:
        call    MakeEA
        ret

dop15:
        mov     bx, bp
        mov     ah, byte ptr es:[bx+1]
        mov     dh, ah
        and     dh, 7
        mov     dl, ah
        mov     cl, 6
        shr     dl, cl
        mov     ax, word ptr es:[bx+2]
        mov     cx, 1
        call    MakeEA
        makech  ','
        mov     bx, bp
        mov     al, byte ptr es:[bx+1]
        shr     al, 1
        shr     al, 1
        shr     al, 1
        and     al, 3
        xor     ah, ah
        lea     bx, ropsreg
        add     bx, ax
        shl     ax, 1
        add     bx, ax
        call    MakeReg
        ret


dop16:
        mov     bx, bp
        mov     al, byte ptr es:[bx+1]
        shr     al, 1
        shr     al, 1
        shr     al, 1
        and     al, 3
        xor     ah, ah
        lea     bx, ropsreg
        add     bx, ax
        shl     ax, 1
        add     bx, ax
        call    MakeReg
        makech  ','
        mov     bx, bp
        mov     ah, byte ptr es:[bx+1]
        mov     dh, ah
        and     dh, 7
        mov     dl, ah
        mov     cl, 6
        shr     dl, cl
        mov     ax, word ptr es:[bx+2]
        mov     cx, 1
        call    MakeEA
        ret

dop17:
        lea     bx, robal
        call    MakeReg
        makech  ','
        mov     bx, bp
        mov     al, byte ptr es:[bx]
        and     al, 7
        mov     bx, ax
        shl     ax, 1
        add     bx, ax
        add     bx, offset rop1
        call    MakeReg
        ret

dop18:
        lea     bx, robal
        call    MakeReg
        makech  ','
        makech  '['
        mov     bx, bp
        mov     ax, word ptr es:[bx+1]
        mov     cl, 1
        call    makehex
        makech  ']'
        ret

dop19:
        lea     bx, ropax
        call    MakeReg
        makech  ','
        makech  '['
        mov     bx, bp
        mov     ax, word ptr es:[bx+1]
        mov     cl, 1
        call    makehex
        makech  ']'
        ret

dop1a:
        makech  '['
        mov     bx, bp
        mov     ax, word ptr es:[bx+1]
        mov     cl, 1
        call    makehex
        makech  ']'
        makech  ','
        lea     bx, robal
        call    MakeReg
        ret

dop1b:
        makech  '['
        mov     bx, bp
        mov     ax, word ptr es:[bx+1]
        mov     cl, 1
        call    makehex
        makech  ']'
        makech  ','
        lea     bx, ropax
        call    MakeReg
        ret

dop1c:
        mov     bx, bp
        mov     al, byte ptr es:[bx]
        and     al, 7
        mov     bx, ax
        shl     ax, 1
        add     bx, ax
        add     bx, offset rop1
        call    MakeReg
        makech  ','
        mov     bx, bp
        mov     al, byte ptr es:[bx+1]
        xor     cl, cl
        call    MakeHex
        ret

dop1d:
        mov     bx, bp
        mov     al, byte ptr es:[bx]
        and     al, 7
        mov     bx, ax
        shl     ax, 1
        add     bx, ax
        add     bx, offset rop2
        call    MakeReg
        makech  ','
        mov     bx, bp
        mov     ax, word ptr es:[bx+1]
        mov     cl, 1
        call    MakeHex
        ret


dop1e:
        makech  '3'
        ret

dop1f:
        mov     bx, bp
        mov     al, byte ptr es:[bx+1]
        xor     cl, cl
        call    MakeHex
        ret

dop21:
        lea     bx, robal

dop21a:
        call    MakeReg
        makech  ','
        mov     bx, bp
        mov     ax, word ptr es:[bx+1]
        xor     cl, cl
        call    makehex
        ret

dop22:
        lea     bx, ropax
        jmp     short dop21a

dop23:
        mov     bx, bp
        mov     al, byte ptr es:[bx+1]
        xor     cl, cl
        call    makehex
        makech  ','
        lea     bx, robal
        call    MakeReg
        ret

dop24:
        mov     bx, bp
        mov     al, byte ptr es:[bx+1]
        xor     cl, cl
        call    makehex
        makech  ','
        lea     bx, ropax
        call    MakeReg
        ret

dop25:
        lea     bx, robal
        call    MakeReg
        makech  ','
        lea     bx, ropdx
        call    MakeReg
        ret

dop26:
        lea     bx, ropax
        call    MakeReg
        makech  ','
        lea     bx, ropdx
        call    MakeReg
        ret

dop27:
        lea     bx, ropdx
        call    MakeReg
        makech  ','
        lea     bx, robal
        call    MakeReg
        ret

dop28:
        lea     bx, ropdx
        call    MakeReg
        makech  ','
        lea     bx, ropax
        call    MakeReg
        ret

dop2a:
        lea     bx, ropax
        call    MakeReg
        makech  ','
        mov     bx, bp
        mov     al, byte ptr es:[bx]
        and     al, 7
        mov     bx, ax
        shl     ax, 1
        add     bx, ax
        add     bx, offset rop2
        call    MakeReg
        ret

dop2b:
        mov     bx, bp
        mov     al, byte ptr es:[bx]
        xor     cx, cx
        call    MakeHex
        ret

dop2c:
        lea     bx, modfar
        call    MakeReg
        inc     di
        mov     bx, bp
        mov     ah, byte ptr es:[bx+1]
        mov     dh, ah
        and     dh, 7
        mov     dl, ah
        mov     cl, 6
        shr     dl, cl
        mov     ax, word ptr es:[bx+2]
        mov     cl, 1
        call    MakeEA
        ret

dispop8:
        lea     dx, opbuff
        call    OutMsg

        pop     es
        pop     ds
        pop     bp
        pop     di
        pop     si
        pop     dx
        pop     cx
        pop     ax
        ret
DispOp  endp

        page
;-------------------------------------------------------------------------;
;       Function: MakeEA                                                  ;
;                 Calculates Effective Address and place operands in      ;
;                 buffer.                                                 ;
;       Input:                                                            ;
;                 AX = Displacement                                       ;
;                 CX = Byte/Word   (0 = Byte, 1 = word)                   ;
;                 DL = mod                                                ;
;                 DH = r/m                                                ;
;                 DI = Buffer Location                                    ;
;       Output:                                                           ;
;                 DI = Next Buffer Location (0 if none)                   ;
;-------------------------------------------------------------------------;

MakeEA  proc      near
        push      ax
        push      bx
        push      cx
        push      dx
        push      bp

        mov       bp, ax
        cmp       dl, 3
        jnz       mea2
        mov       al, dh
        xor       ah, ah
        mov       bx, ax
        shl       ax, 1
        add       ax, bx
        lea       bx, rop1
        test      cx, 1
        jz        mea1
        lea       bx, rop2

mea1    label     near
        add       bx, ax
        call      MakeReg
        jmp       mea10

mea2    label     near
        makech    '['
        or        dl, dl
        jnz       mea2a
        cmp       dh, 6
        jne       mea2a
        mov       cl, 1         ; use word value
        jmp       mea8

mea2a   label     near
        cmp       dh, 3
        ja        mea6
        lea       bx, ropbx
        test      dh, 2
        jz        mea3
        lea       bx, ropbp

mea3    label     near
        call      MakeReg
        makech    '+'

mea4    label     near
        lea       bx, ropsi
        test      dh, 1
        jz        mea5
        lea       bx, ropdi

mea5    label     near
        call      MakeReg
        or        dl, dl
        jz        mea9
        makech    '+'
        jmp       mea7a

mea6    label     near
        test      dh, 2
        jz        mea4
        lea       bx, ropbp
        test      dh, 1
        jz        mea7
        lea       bx, ropbx

mea7    label     near
        call      MakeReg
        or        dl, dl
        jz        mea9
        makech    '+'

mea7a   label     near
        mov       cl, dl
        dec       cl
        and       cx, 1

mea8    label     near
        mov       ax, bp
        call      MakeHex

mea9    label     near
        makech    ']'

mea10   label     near
        pop       bp
        pop       dx
        pop       cx
        pop       bx
        pop       ax
        ret
MakeEA  endp

        page
;-------------------------------------------------------------------------;
;       Function: MakeReg                                                 ;
;                 Puts register name in output buffer                     ;
;       Input:                                                            ;
;                 BX - Address of register name                           ;
;       Output:                                                           ;
;                 None Displays Information to screen                     ;
;-------------------------------------------------------------------------;

MakeReg proc    near
        push    ax
        push    bx
        push    cx

        mov     cl, byte ptr [bx]
        xor     ch, ch
        inc     bx

make1:
        mov     al, byte ptr [bx]
        inc     bx
        mov     byte ptr [di], al
        inc     di
        loop    make1

        pop     cx
        pop     bx
        pop     ax
        ret
MakeReg endp

        page
;-------------------------------------------------------------------------;
;       Function: MakeHex                                                 ;
;                 Set AX as Hex Ascii At Location DS:DI                   ;
;                     cx = 0  means single byte in al                     ;
;       Input:                                                            ;
;                 AX - Hex Value to be display                            ;
;                 CX - Indicates format                                   ;
;                 DI - Location to store value                            ;
;       Output:                                                           ;
;                 None Displays Information to screen                     ;
;-------------------------------------------------------------------------;

MakeHex proc    near
        or      cx, cx
        jz      make
        xchg    ah, al
        call    make
        xchg    ah, al
make:
        push    ax
        push    bx
        push    cx

        xor     bh, bh
        mov     bl, al
        and     bl, 0fh
        mov     bl, byte ptr [bx+hextab]
        mov     byte ptr [di+1], bl
        mov     cl, 4
        shr     al, cl
        mov     bl, al
        mov     bl, byte ptr [bx+hextab]
        mov     byte ptr [di], bl
        inc     di
        inc     di

        pop     cx
        pop     bx
        pop     ax
        ret
MakeHex endp

        page
;-------------------------------------------------------------------------;
;       Function: GetEnv                                                  ;
;                 Gets Enviroment pointed by DS:SI in EnvSeg              ;
;                 Places Result into DS:DI                                ;
;       Input:                                                            ;
;                 SI - Offset of Enviroment Name to Locate.               ;
;                 DI - Offset of storage for value                        ;
;                 CX - Lenght of word to search for                       ;
;       Output:                                                           ;
;                 None Displays Information to screen                     ;
;-------------------------------------------------------------------------;

GetEnv  proc    near
        push    bx
        push    cx
        push    dx
        push    si
        push    di
        push    bp
        push    ds
        push    es

        mov     [valsi], si
        mov     ah, 62h         ; get PSP
        int     21h
        mov     es, bx
        mov     bx, WORD PTR es:[02CH]   ; get env seg
        mov     [envseg], bx
        mov     es, bx
        mov     bp, si
        xor     si, si          ; clear loop counter
        xor     dx, dx

geloop:
        mov     al, BYTE PTR  es:[si] ; get byte
        inc     si
        inc     dx
        or      al, al
        je      gefin
        cmp     al, '='
        jne     geloop
        mov     bx, dx
        jmp     geloop


gefin:
        dec     bx
        or      bx, bx
        je      gedone
        cmp     bx, cx
        je      gecomp
        xor     dx, dx
        jmp     geloop

;       Compare the values

gecomp:
        push    si
        push    di
        push    cx

        mov     di, si
        sub     di, dx
        mov     si, cs:[valsi]
        repe    cmpsb
        or      cx, cx

        pop     cx
        pop     di
        pop     si
        je      geval
        xor     dx, dx
        jmp     geloop

;       Get enviroment value

geval:
        sub     si, dx
        add     si, cx
        inc     si
        sub     dx, cx
        dec     dx
        mov     cx, dx
        push    ax
        mov     ax, es
        mov     ds, ax
        mov     ax, cs
        mov     es, ax
        pop     ax
        mov     ax, cx
        rep     movsb

gedone:
        pop     es
        pop     ds
        pop     bp
        pop     di
        pop     si
        pop     dx
        pop     cx
        pop     bx
        ret
GetEnv  endp

        page
;-------------------------------------------------------------------------;
;       Function: GetKBD                                                  ;
;                 Gets key from keyboard through BIOS                     ;
;       Input:                                                            ;
;       Output:                                                           ;
;                 AL = Character recieve from keyboard                    ;
;-------------------------------------------------------------------------;

GetKBD  proc    near
        xor     ax, ax
        int     16h
        ret
GetKBD  endp

        page
;-------------------------------------------------------------------------;
;       Function: DumpReg                                                 ;
;                 Dumps the registers on the display                      ;
;       Input:                                                            ;
;       Output:                                                           ;
;-------------------------------------------------------------------------;

DumpReg proc    near
        push    ax
        push    bx
        push    cx
        push    dx
        push    si
        push    di
        push    ds
        push    es

        mov     ax, cs
        mov     ds, ax
        mov     es, ax
        lea     dx, regmsg
        call    OutMsg
        lea     di, opbuff
        mov     cx, 38
        xor     ax, ax
        rep     stosw
        lea     di, opbuff
        mov     cx, 1
        mov     ax, [regax]
        call    MakeHex
        makech  ' '
        mov     ax, [regbx]
        call    MakeHex
        makech  ' '
        mov     ax, [regcx]
        call    MakeHex
        makech  ' '
        mov     ax, [regdx]
        call    MakeHex
        makech  ' '
        mov     ax, [regsi]
        call    MakeHex
        makech  ' '
        mov     ax, [regdi]
        call    MakeHex
        makech  ' '
        mov     ax, [regbp]
        call    Makehex
        makech  ' '
        mov     ax, [regds]
        call    MakeHex
        makech  ' '
        mov     ax, [reges]
        call    MakeHex
        makech  ' '
        mov     ax, [regss]
        call    MakeHex
        makech  ' '
        mov     ax, [regsp]
        call    MakeHex                 
;;      makech  ' '                     ; use for testing flags
;;      mov     ax, [regflag]           ;       
;;      call    MakeHex                 ; use for testing flags
        mov     ax, 2020h
        stosw
        mov     al, '$'
        stosb
        lea     dx, opbuff
        call    OutMsg
        call    DispFg          ; disp flags
        lea     dx, crlf
        call    OutMsg
        mov     bx, [regip]
        mov     ds, [regcs]
        call    DispOp          ; display instruction line
        mov     bx, cs:[regip]  ; check if prevous is REP
        mov     al, byte ptr ds:[bx]
        cmp     al, 0f2h        ; REP
        je      dreg3
        cmp     al, 0f3h        ; REP
        je      dreg3
        cmp     al, 26h         ; ES:
        je      dreg3
        cmp     al, 2eh         ; CS:
        je      dreg3
        cmp     al, 36h         ; SS:
        je      dreg3
        cmp     al, 3eh         ; DS:
        jne     dreg4

dreg3:
        inc     bx
        call    DispOp          ; display next instruction

dreg4:

        pop     es
        pop     ds
        pop     di
        pop     si
        pop     dx
        pop     cx
        pop     bx
        pop     ax
        ret
DumpReg endp

        page
;-------------------------------------------------------------------------;
;       Function: SetDReg                                                 ;
;                 Sets values use internally by debugger                  ;
;       Input:                                                            ;
;       Output:                                                           ;
;-------------------------------------------------------------------------;

SetDReg proc    near
        push    ax
        
        mov     ax, [regcs]
        mov     [uasmloc], ax
        mov     ax, [regip]
        mov     [uasmloc+2], ax

        pop     ax
        ret
SetDReg endp

        page
;-------------------------------------------------------------------------;
;       Function: SaveAll                                                 ;
;                 Saves all regs  internally by debugger                  ;
;       Input:                                                            ;
;       Output:                                                           ;
;-------------------------------------------------------------------------;

SaveAll proc    near
        mov     cs:[regdb+16], ds
        push    cs
        pop     ds
        mov     [regdb],    ax
        mov     [regdb+2],  bx
        mov     [regdb+4],  cx
        mov     [regdb+6],  dx
        mov     [regdb+8],  si
        mov     [regdb+10], di
        mov     [regdb+12], bp
        mov     [regdb+14], es
        ret
SaveAll endp

        page
;-------------------------------------------------------------------------;
;       Function: GetAll                                                  ;
;                 Gets  all regs  internally by debugger                  ;
;       Input:                                                            ;
;       Output:                                                           ;
;-------------------------------------------------------------------------;

GetAll  proc    near
        push    cs
        pop     ds
        mov     ax,    [regdb]
        mov     bx,  [regdb+2]
        mov     cx,  [regdb+4]
        mov     dx,  [regdb+6]
        mov     si,  [regdb+8]
        mov     di, [regdb+10]
        mov     bp, [regdb+12]
        mov     es, [regdb+14]
        mov     ds, [regdb+16]
        ret
GetAll endp

        page
;-------------------------------------------------------------------------;
;       Function: SkipIns                                                 ;
;                 Skips calls, ints, and rep strings                      ;
;                 by setting break point after necessary instructions     ;
;       Input:                                                            ;
;       Output:                                                           ;
;                AL = return contition  (0 = No Skip   Non 0 - skip)      ;
;                                        CCH if INT 3                     ;
;-------------------------------------------------------------------------;

SkipIns proc    near
        push    bx
        push    es

        mov     bx, [regip]
        mov     es, [regcs]
        mov     al, byte ptr es:[bx]
        cmp     al, 0e8h                ; call
        jne     Si1
        add     bx, 3
        jmp     SiSet

Si1:
        cmp     al, 09ah                ; call  
        jne     Si2
        add     bx, 5
        jmp     SiSet

Si2:
        cmp     al, 0e0h                ; loop
        jb      Si3
        cmp     al, 0e2h                ; loop
        ja      Si3
        add     bx, 2
        jmp     SiSet

Si3:
        cmp     al, 0f2h                ; rep
        jne     Si4
        add     bx, 2
        jmp     SiSet

Si4:
        cmp     al, 0f3h                ; rep
        jne     Si5
        add     bx, 2
        jmp     SiSet

Si5:
        cmp     al,  0cch               ; int 3
        jne     Si6
        inc     [regip]                 ; special case
        jmp     SiBrk
        
Si6:
        cmp     al, 0cdh                ; int xx
        jne     Si7
        add     bx, 2
        jmp     SiSet

Si7:
        cmp     al, 0ceh                ; into
        jne     si8
        inc     bx
        jmp     SiSet

Si8:
        cmp     al, 0ffh                ; possiable call ???
        jne     SiTrace
        mov     al, byte ptr es:[bx+1]  ; get next byte
        mov     ah, al
        and     al, 20h
        cmp     al, 20h
        jne     SiTrace
        and     ah, 0c0h
        or      ah, ah
        jz      Si9                     ; call (0 disp)
        cmp     ah, 0c0h                ; call reg
        jne     Si10

Si9:
        add     bx, 2
        jmp     SiSet
        
Si10:
        cmp     ah, 080h                ; call short
        jne     Si11
        add     bx, 3
        jmp     SiSet
        
Si11:
        add     bx, 4                   ; call  near
        
SiSet:
        push    dx
        push    es
        
        mov     dx, bx                  ; offset
        mov     di, es                  ; segment
        xor     al, al
        call    SetBrk                  ; set break point
        
        pop     di
        pop     dx
        mov     al, 1                   ; indicate break
        jmp     SiBrk

SiTrace: 
        xor     al, al
        
SiBrk:
        pop     es
        pop     bx
        ret
SkipIns endp

        page
;-------------------------------------------------------------------------;
;       Function: SetSegs                                                 ;
;                 Set default segment register values for lists           ;
;       Input:                                                            ;
;       Output:                                                           ;
;-------------------------------------------------------------------------;


SetSegs proc    near
        push    ax

        cmp     byte ptr [segflag], 0
        je      ssegend
        mov     ax, [regcs]
        mov     [asmloc], ax            ; set default to code seg
        mov     [uasmloc], ax
        mov     ax, [regds]
        mov     [dumploc], ax           ; set default to data seg
        mov     byte ptr [segflag], 0

ssegend:
        
        pop     ax
        ret
SetSegs endp    

        page
;-------------------------------------------------------------------------;
;       Function: SizeMax                                                 ;
;                 Set Memory Size to Max available by allocating all of it;
;       Input:                                                            ;
;       Output:                                                           ;
;-------------------------------------------------------------------------;


SizeMax proc    near
        cmp     [AllMem], 0
        jne     smaxend
        mov     [AllMem], 1
        push    ax
        push    bx
        push    es

        mov     es, [regcs]
        mov     bx, 0ffffh
        mov     ah, 4ah
        int     21h
        jnc     smaxskp
        cmp     bx, 100h
        jb      smaxskp
        sub     bx, 100h
        mov     ah, 4ah
        int     21h

smaxskp:
        pop     es
        pop     bx
        pop     ax

smaxend:
        ret
SizeMax endp

        page
;-------------------------------------------------------------------------;
;       Function: SizeMin                                                 ;
;                 Set Memory Size to Min available by deallocating it     ;
;       Input:                                                            ;
;       Output:                                                           ;
;                 AX <> 0   Can't shrink down                             ;
;-------------------------------------------------------------------------;

SizeMin proc    near
	xor     ax,ax
        cmp     [AllMem], 0
        je      sminend
        mov     [AllMem], 0
        
        push    bx
        push    es

        mov     es, [regcs]
        mov     bx, [shrink]
        mov     ah, 4ah
        int     21h
	xor     ax,ax
        jnc     sminok
        inc     ax
        
sminok:
        pop     es
        pop     bx

sminend:
        ret
SizeMin endp

        page
;-------------------------------------------------------------------------;
;       Function: ValidOP                                                 ;
;                 Validates operands to make sure no extra garbage        ;
;       Input:                                                            ;
;                 BX offset of buffer                                     ;
;       Output:                                                           ;
;                 Carry if not valid                                      ;
;-------------------------------------------------------------------------;

ValidOP proc    near
        push    bx
        or      bx,bx		; end of the line
        jz      vopgood
        call    RemSpac		; skip over spaces on the end
        or      bx, bx
        jz      vopgood		
        pop     bx		; we got some trash from the user
        stc			; flag it!
        ret

vopgood:
        pop     bx
        clc
        ret
ValidOP endp

;-------------------------------------------------------------------------;
moss    ends

        if1
                %out   Pass 1   Completed.
        else
                %out   Pass 2   Completed.
        endif


        end

