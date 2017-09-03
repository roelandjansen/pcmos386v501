;---------------------------------------------------------------------------;
; Generic Mouse Driver - Definitions File				    ;
;									    ;
; (c) Copyright 1989 The Software Link, Incorporated.			    ;
;---------------------------------------------------------------------------;

;	driver status equates

FARINSTALL  equ     01h 		; indicates if far call is installed
DATAREADY   equ     02h 		; indicates if IRQ has data ready to
					; be passed to farcall routine
MSCPROTO    equ     04h 		; indicates if MSC protocal instead
					; of Microsofts protocal
MAXBUFF     equ     20			; Maximun of 20 bytes internal buffer
					; size
MSSIZE	    equ     64			; Structure Size is 64 bytes


;	status byte 1 equates

SMODE	    equ     40h 		; 0 = stream mode, 1 = remote mode
SENABLE     equ     20h 		; 0 = Disable, 1 = Enable
SSCALE	    equ     10h 		; 0 = 1:1 scale, 1 = 2:1 scale
SLEFT	    equ     04h 		; 1 = Left butten pushed
SRIGHT	    equ     01h 		; 1 = Right butten pushed


; The following is the Mouse Task Data Structure return by driver function 00h

mtask	struc
tasktcb dw	 0		; task TCB id
mstatus db	 0		; status byte
farcall dd	 0		; task far call routine
packet	db	 0		; packet size
sbyte1	db	 0		; status byte 1
sbyte2	db	 0		; status byte 2
sbyte3	db	 0		; status byte 3
word1	dw	 0		; far call word 1
word2	dw	 0		; far call word 2
word3	dw	 0		; far call word 3
word4	dw	 0		; far call word 4
orgpoll dd	 0		; Orginal TCBUPOLL routine
mport	dw	 0		; Port for Mouse
mbaud	dw	 0		; baud rate for Mouse Port
mstage	db	 0		; staging for mouse protocal
mready	dd	 0		; pointer to mouse input ready flag
unreg	dd	 0		; Prevous TCBUNREG for this entry
save2	dw	 0		; save call word 2
save3	dw	 0		; save call word 3
bcount	db	 0		; Mouse Buffer count
bpos	db	 0		; Mouse Buffer position
buffer	db	 20 dup (0)	; Mouse input buffer
	db	 0
merror	db	 0		; Mouse Error occur
mtask	ends

