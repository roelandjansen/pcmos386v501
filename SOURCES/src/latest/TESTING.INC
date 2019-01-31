IFDEF EXE_TESTING
aaaa    segment para public 'code'

; This file is included in a device driver just before the device
; driver's header.  It is used to simulate invocation of the initialization
; entry point of the device driver.

        assume cs:aaaa,ds:nothing,es:nothing,ss:nothing

        mov   cs:[cmdseg],ds       ;setup command line ptr in packet

        push  cs
        pop   es
        mov   bx, offset aaaa:packet

        call  far ptr strat
        call  far ptr inter

; Now lets initialize the port

        mov   ah, 4             ;extended init
        mov   cx, 1             ;baud rate MSBits
        mov   bx, 49664         ;baud rate LSBits
;         mov   cx, 0
;         mov   bx, 9600
        mov   al, 00000111b     ;no parity, 1 stop, 8 data
        mov   dx, 0
        int   14h

; Raise the modem control signals

        mov   ah, 17            ;set modem control'
        mov   al, 00001011b     ;turn on DTR/RTS
        mov   dx, 0
        int   14h

; Try sending a string out

        mov   cx, 3

bloop:
        push cx

        mov   ah, 14
        mov   cx, msgend-msgstart
        mov   dx, 0
        mov   bx, cs
        mov   es, bx
        mov   bx, offset aaaa:msgstart
        mov   si, 10
        int   14h

; Read characters until buffer is empty and display them on the screen

IFDEF  TEST_RCV
xloop:
        mov   ah, 10    ;Input queue check
        mov   dx, 0
        int   14h       ;How many are there?

        xchg  cx, ax    ;Put count in cx
        jcxz  bdone

gloop:
        push  cx

        mov   ah, 22    ;Read char
        mov   dx, 0
        mov   si, 2     ;1/9 second
        int   14h

        les   bx,dword ptr cs:[testptr]
        mov   es:[bx], al
        add   bx,2
        mov   word ptr cs:[testptr],bx

        pop   cx
        loop  gloop
        jmp   xloop
bdone:
ENDIF
        pop   cx
        loop  bloop

; Read characters 1-by-1 until we get a timeout and display them on
; the screen

IFDEF  TEST_RCV
floop:
        mov   ah,22     ;read char w/timeout
        mov   dx,0
        mov   si,10
        int   14h

        test  ah,80h
        jnz   fdone

        les   bx,dword ptr cs:[testptr]
        mov   es:[bx], al
        add   bx,2
        mov   word ptr cs:[testptr],bx

        jmp   floop


fdone:
ELSE
        mov   ax,0              ;open the other port
        mov   dx,1
        int   14h

        mov   ah,22             ;read w/timeout
        mov   dx,1              ;other port
        mov   si,54             ;about 3 seconds
        int   14h

        mov   ah, 11            ;shut it back down
        mov   dx, 1
        int   14h

ENDIF

; drop the modem control signals

        mov   ah, 17            ;set modem control
        mov   al, 00001000b     ;turn off DTR/RTS
        mov   dx, 0
        int   14h

        mov   ah,11     ;shut down the port
        mov   dx, 0
        int   14h

; ALL DONE!

        mov   ax,4C00h
        int   021h

testptr dw    0,0b800h

packet  db    18 dup (0)
        dw    81h
cmdseg  dw    0
        db    30 dup (0)

msgstart      db  'The quick brown fox jumps over the lazy dog'
msgend        label byte

aaaa    ends

bbbb    segment para stack 'stack'

        dw      100 dup (0)

bbbb    ends
ENDIF