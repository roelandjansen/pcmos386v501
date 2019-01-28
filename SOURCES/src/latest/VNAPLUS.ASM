
        title   UNTERM.ASM - EGNA (Enhance Graphics Network Adapter)
comment ^===============================================================
                       Development Specification

 Program Name:  VNAPLUS.ASM                     Assigned to: Stewart Hyde
 Module Name:   UNTERM                          Assign date: 12/04/90
 Entry Points:  EGNATERM                        Completed:   12/04/90
 Entry From:    MOSINT10, MOSINT16, MOSVIDRM
 Entry Method:  Command processor - PC-MOS or  DOS
 Calls:
 Purpose:       KeyBoard Test program for VNAPLUS hardware
 Refer to:      Stewart Hyde, EGNA Doc, VNAPlus Doc
 Last Update:   02/14/91

 Copyright 1990 The Software Link, Inc.

========================================================================^

Disp    macro   msg
        lea     dx,msg
        mov     ah,9
        int     21h
        endm

codeseg SEGMENT

         ORG     0100h
         ASSUME  CS:CODESEG,DS:CODESEG

start:
        jmp      EntryPnt

FName   db      'UNTERM Keyboard Test Program Version 2.03 (910214)',13,10
        db      'Copyright 1990, 1991 The Software Link, Inc.',13,10,10,'$'
FName2  db      'OUR UNTERM Base Address = '
BaseAdr db      'xxxxH.',13,10,10
        db      'Station | Retries | Status',13,10
        db      '--------|---------|---------------------------',13,10,'$'


Fmsg    db      '   '
Fstat   db      'A    |     '
Fretry  db      '0   |  Keyboard $'

MsgOk   db      'Ok.',13,10,'$'
MsgFail db      'Failed.',13,10,'$'
MsgAbort db     'Aborted by User.',13,10,'$'
MsgBoard db     'Board Found at Base Address '
BaseAdr2 db     'xxxxH is $'
MsgVna  db      'VNAPLUS.',13,10,'$'
MsgEgna db      'EGNA.',13,10,'$'
MsgVgna db      'VGNA.',13,10,'$'
Check   db      'Checking Hardware, Please Wait....',13,10,10,'$'
NoBoards db     'No Hardware found!',13,10,'$'

BaseTable label word
        dw      100h,110h,120h,130h,140h,150h,160h,170h
        dw      180h,190h,1a0h,1b0h,1c0h,1d0h,1e0h
        dw      200h,210h,220h,230h,240h,250h,260h
        dw      280h,290h,2a0h,2b0h,2c0h,2d0h,2e0h
        dw      310h,320h,330h,340h,350h,360h
        dw      380h,390h,3a0h,3e0h
        dw      0

Debug   db      'N'

dbmsg   db      'Logic failed in Location '
dbloc   db      '1.',13,10,'$'

BaseVal  dw     240h

BoardFound db   'N'
BoardList db    8 dup (00h)
Selective db    00h


;====================================================================
;  Keboard Initialization Logic
;
; The areas I have changed are denoted by <<<<<<<<<<<< marker


InitKb  proc    near
        xor     bh,bh
        mov     bl,[FStat]
        sub     bl,'A'
        shl     bx,1
        mov     dx,[BaseVal]
        inc     dx
        cmp     bl,8
        jb      InitKBx
        add     dx,1000h
        sub     bl,8
InitKBx:
        add     dx,bx

;
;       Now initialize Keyboard
;
        push    cx
        push    dx
        mov     al,0aah
        call    OutCmd                  ; send 0aah to keyboard
        cmp     ax,-1
        je      ErrorAA
        call    Get55                   ; Get Keyboard Input
        cmp     al,055h
        je      Setup8042
        call    Get55                   ; Get Keyboard Input
        cmp     al,055h
        je      Setup8042
ErrorAA:
        mov     [dbloc],'1'
        jmp     ErrorKB
Setup8042:
;
;       Setup 8042 command byte
;
        mov     al,060h                 ; send 60h
        call    OutCmd
        cmp     ax,-1
        je      ErrorKB
        dec     dx
        mov     al,45h                  ; send 45h
        call    OutData
        cmp     ax,-1
        je      ErrorKB
        inc     dx
	call    GetKey

;<<<<<<<<<<< IF YOU GOT AN 0XFE BACK TRY A KEYBOARD RESET 0XFF COMMAND
;<<<<<<<<<<< TO THE KEYBOARD
	cmp	al,0feh
	jnz	Go_Ahead
send_FF:
        xor     ax,ax   ;<<<<<<<< AX=0X00FF
	not     al	;<<<<<<<<
	dec	dx
	call    OutData
	inc	dx
        cmp     ax,-1
	je      ErrorKB
Go_Ahead:
        dec     dx
        mov     al,0edh                 ; send EDh to check keyboard
        call    OutData
        cmp     ax,-1
        je      ErrorKB
        inc     dx
        mov     cx,4
GKeyLp1:
        call    GetFA                   ; check for FAh from keyboard
        je      GKeyOk1
        loop    GKeyLp1
        mov     [dbloc],'2'
        jmp     short ErrorKB
GKeyOk1:
	dec     dx
	xor	al,al
	call	OutData
	cmp	ax,-1
	je	ErrorKB
	inc	dx
	mov	cx,4
GKeyLp2:
        call    GetFA                   ; check for FAh from keyboard
	cmp     al,0fah;
        je      InitKBa
        loop    GKeyLp2
        mov     [dbloc],'3'
ErrorKB:
        pop     dx
        pop     cx
        stc
        ret
InitKBa:
        pop     dx
        pop     cx
        clc
        ret
InitKB  endp

;
; The following routine is use by InitKB to output commands to keyboard
; controller during initialization of Keyboard.
;

OutCmd  proc    near
        push    cx
        mov     cx,1000h
        mov     ah,al
OCLoop:
        in      al,dx
        test    al,2
        loopnz  OCLoop
        or      cx,cx
        jz      OCExit
        mov     al,ah
        out     dx,al
        mov     cx,1000h
OCLoop2:
        in      al,dx
        test    al,2
        loopnz  OCLoop2
        pop     cx
        ret
OCExit:
        mov     ax,-1
        pop     cx
        ret
OutCmd  endp

OutData proc    near
        push    cx
        inc     dx
        mov     cx,1000h
        mov     ah,al
ODLoop:
        in      al,dx
        test    al,2
        loopnz  ODLoop
        or      cx,cx
        jz      ODExit
        dec     dx
        mov     al,ah
        out     dx,al
        pop     cx
        xor     ah,ah	;<<<<<<<<<< MAKE SURE AH=0 IF SUCCESSFUL
        ret
ODExit:
        mov     ax,-1	;<<<<<<<<<< ERROR
        pop     cx
        ret
OutData endp

GetKey  proc    near
        push    cx
        mov     cx,100h
GKLoop:
        in      al,dx
        test    al,1
        loopz   GKLoop
        mov     ax,-1
        or      cx,cx
        jz      GKexit
        xor     ah,ah
        dec     dx
        in      al,dx
        inc     dx
GKexit:
        pop     cx
        ret
GetKey  endp

GetCH   proc    near
        push    ds
        push    bx
        xor     ax,ax
        mov     ds,ax
        mov     bx,word ptr ds:[46ch]
GKLoop2:
        in      al,dx
        test    al,1
        jnz     GKFound
GKLoop3:
        mov     ax,word ptr  ds:[46ch]
        sub     ax,bx
        cmp     ax,14           ; wait abort 3/4 second
        jb      GKLoop2
        mov     ax,-1
        cmp     al,cl
        jmp     short GKOut
GKFound:
        dec     dx
        in      al,dx
        inc     dx
        cmp     al,cl
        jne     GKLoop3
GKout:
        pop     bx
        pop     ds
        ret
GetCh   endp

;
; wait for 55h from keyboard, timed
;

GetFA   proc    near
        push    cx
        mov     cl,0fah
        call    GetCH
        pop     cx
        ret
GetFA   endp

;
; wait for 55h from keyboard, timed
;

Get55   proc    near
        push    cx
        mov     cl,055h
        call    GetCh
        pop     cx
        ret
Get55   endp


;=======================================================================

CheckBase proc  near
          pushf
          push  cx
          push  si
        push    ax
        lea     bx,BaseAdr2+3
        call    bintohex
        pop     ax

        mov     dx,ax
;
;       Read Keyboard and find out type of Card on system
;       Set PAGE 7 of EGNA doc
;
        inc     dx
        mov     al,0aah
        call    OutCmd
        dec     dx
        mov     cx,-1
        loop    $
        mov     cx,-1
        loop    $
        in      al,dx                   ; get responce
        cmp     al,55h                  ; all ok
        jne     SBadCard
        inc     dx
        mov     al,0c0h                 ; read input command
        call    OutCmd
        dec     dx
        mov     cx,-1
        loop    $
        mov     cx,-1
        loop    $
        in      al,dx
        test    al,80h                  ; High Bit Must always be set
        jz      SBadCard
;
;       At this point AL has Station Identification register
;       Format as follows
;
;       Bit             7 6 5 4 3 2 1 0
;       Definition      1 V V V V R R R
;
;       where  RRR is revision Code 3 Bit 0-7
;       where  VVVV is Video Type
;       where  BIT 7 is always 1
;
;       Video Type definition is as follows
;
;               0 - Hercules MonoChrome
;               1 - Color EGA
;               2 - Color VGA
;               3-15 - Reserved
;
        mov     bl,al
        shr     bx,1
        shr     bx,1
        shr     bx,1
        and     bx,0fh
        cmp     bl,2            ; only support Video Type 0 - 2 now
        ja      SBadCard
        and     al,07h          ; mask out revison
        mov     dx,offset msgvna
        or      al,al
        jz      DispBoard
        dec     al
        mov     dx,offset msgegna
        or      al,al
        jz      DispBoard
        dec     al
        mov     dx,offset msgvgna
        or      al,al
        jnz     SBadCard
DispBoard:
        mov     [BoardFound],'Y'
        push    dx
        mov     dx,offset MsgBoard
        mov     ah,9
        int     21h
        pop     dx
        mov     ah,9
        int     21h

SBadCard:
          pop   si
          pop   cx
          popf
          ret
CheckBase endp

;=======================================================================


GetDebug proc   near
         mov    si,81h
         cld
GDLoop:
         lodsb
         cmp    al,0dh
         je     GDExit
         or     al,al
         jz     GDexit
         cmp    al,'/'
         je     GDCmd
         cmp    al,'\'
         je     GDcmd
         cmp    al,'-'
         jne    GDLoop
GDCmd:
         lodsb
         and    al,0dfh
         cmp    al,'D'
         jne    GDloop
         mov    [Debug],'Y'
         mov    word ptr ds:[si-2],2020h
GDexit:
         ret
GetDebug endp

GetBase proc    near
        xor     cx,cx
        mov     si,81h
        cld
GBLoop:
        lodsb
        cmp     al,' '
        je      GBloop
        jmp     short GBLoop1a
GBLoop1:
        lodsb
GBLoop1a:
        cmp     al,'0'
        jb      testaz
        cmp     al,'9'
        ja      testaz
        sub     al,'0'
        jmp     short donext
testaz:
        and     al,0dfh
        cmp     al,'A'
        jb      GBDone
        cmp     al,'Z'
        ja      GBDone
        sub     al,'A'
        add     al,10
donext:
        shl     cx,1
        shl     cx,1
        shl     cx,1
        shl     cx,1
        xor     ah,ah
        add     cx,ax
        jmp     short GBloop1

GBDone:
        mov     [BaseVal],cx
        mov     ax,cx
        lea     bx,BaseAdr+3
        call    bintohex
        dec     si
GBLoop2:
        lodsb
        cmp     al,' '
        je      GBLoop2
        dec     si
DriveLoop:
        lodsb
        and     al,0dfh
        cmp     al,'A'
        jb      GBDone2
        cmp     al,'H'
        ja      GBDone2
        mov     bl,al
        sub     bl,'A'
        xor     bh,bh
        mov     byte ptr BoardList[bx],0ffh
        mov     [Selective],0ffh
        jmp     short DriveLoop
GBDone2:
        ret
GetBase endp

EntryPnt:
        call    GetDebug
        call    GetBase
        Disp    FName
        cmp     [BaseVal],0
        jne     MainStart
        Disp    Check
        cld
        mov     si,offset BaseTable
ListLoop:
        lodsw
        or      ax,ax
        jz      ListDone
        call    CheckBase
        jmp     short ListLoop
ListDone:
         cmp    [BoardFound],'Y'
         je     ListDone2
         disp   NoBoards
ListDone2:
        jmp     ExitProg
MainStart:
        Disp    FName2
        mov     cx,8                    ; up to 8 maximun boards
        xor     si,si
MainLoop:
        push    si
        push    cx
        cmp     Selective,0ffh
        jne     MainCont
        cmp     BoardList[si],00h
        je      NextEntry
MainCont:
        mov     cx,8
        mov     [Fretry],'0'
RetryLoop:
        push    cx
        call    InitKB
        pop     cx
        jnc     BoardOk
        cmp     [Debug],'N'
        je      SkipDebug
        disp    dbmsg
SkipDebug:
        inc     [Fretry]
        mov     ah,1
        int     16h
        jz      SkipKey
SKeyLoop:
        xor     ah,ah
        int     16h
        mov     ah,1
        int     16h
        jnz     SKeyLoop
        disp    fmsg
        disp    MsgAbort
        jmp     NextEntry
SkipKey:
        loop    RetryLoop
        disp    Fmsg
        disp    MsgFail
        jmp     NextEntry
BoardOk:
        disp    Fmsg
        disp    MsgOk
NextEntry:
        inc     [Fstat]
        pop     cx
        pop     si
        inc     si
        dec     cx
        or      cx,cx
        jz      ExitProg
        jmp     MainLoop
ExitProg:
         mov    ax,4c00h
         int    21h

;------------------- binary-to-hexadecimal routine ------------------;
bintohex proc
        push  si
        mov   dl,4
bthloop1:
        mov   si,ax
        and   si,000fh
        mov   cl,[hextable+si]
        mov   [bx],cl
        mov   cl,4
        shr   ax,cl
        dec   bx
        dec   dl
        jg    bthloop1
        pop   si
        ret
hextable db    '0123456789ABCDEF'
bintohex endp

EndOfProg LABEL BYTE

codeseg ENDS

         END     start
