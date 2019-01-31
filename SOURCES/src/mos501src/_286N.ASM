	include page.inc

	.286c

;--------------------------------------------------------------------;
;	$$MEMDEV driver for the 80286 NON-memory-managed case	     ;
;     (c) Copyright 1985, 1988 The Software Link, Incorporated       ;
;--------------------------------------------------------------------;
;  This driver does two things for the 80286 in the non-memory-man-  ;
;  aged case: (1) Supports the "LIDT" method of interrupt management ;
;  (/I turns it off), and (2) allows addressing of the 64K of RAM at ;
;  the 1MB boundary (/C turns this off).                             ;
;--------------------------------------------------------------------;

;--------------------------------------------------------------------;
;			   MAIN SEGMENT 			     ;
;--------------------------------------------------------------------;

MAINSEG  SEGMENT PARA PUBLIC 'CODE'
	 ASSUME CS:MAINSEG,DS:MAINSEG
BEGIN	 LABEL NEAR

;------------------------- DEVICE HEADER ----------------------------;

DEVHEADR LABEL BYTE
	 DD    -1		     ; POINTER TO NEXT DRIVER
	 DW    8000H		     ; ATTRIBUTE: INDICATE CHARACTER DEVICE
STRATVEC DW    STRATEGY 	     ; PTR TO STRATEGY ROUTINE
INTERVEC DW    INTERUPT 	     ; PTR TO INTERRUPT ROUTINE
DEVNAME  DB    '$$MEMDEV'	     ; DEVICE NAME

ENDHEAD  LABEL	BYTE

;--------------------- MISCELLANEOUS CONSTANTS ----------------------;

ZERO	 DW    0
WORDTEN  DW    10
videoadr dw    0b000h

	 PAGE
;--------------------------------------------------------------------;
;		       DEVICE FUNCTION VECTORS			     ;
;--------------------------------------------------------------------;

	 EVEN
FUNTAB	 LABEL WORD
	 DW    INIT
	 DW    MEDIACHK
	 DW    BUILDBPB
	 DW    IOCTLIN
	 DW    INPUT
	 DW    NDINPUT
	 DW    INSTATUS
	 DW    INFLUSH
	 DW    OUTPUT
	 DW    OUTPUTV
	 DW    OUSTATUS
	 DW    OUFLUSH
	 DW    IOCTLOUT

	 PAGE
;--------------------------------------------------------------------;
;		    STRATEGY AND INTERRUPT ROUTINES		     ;
;--------------------------------------------------------------------;

STRATEGY LABEL NEAR
	 MOV   CS:[RHSEG],ES
	 MOV   CS:[RHOFF],BX
FARRET1  PROC  FAR
	 RET
FARRET1  ENDP

INTERUPT LABEL NEAR
	 PUSH  BP
	 PUSH  ES
	 PUSH  DS
	 PUSH  DI
	 PUSH  SI
	 PUSH  DX
	 PUSH  CX
	 PUSH  BX
	 PUSH  AX

	 PUSH  CS		     ; INIT DS REGISTER
	 POP   DS
	 LES   BX,DWORD PTR [RHOFF]  ; LOAD RH POINTER
	 MOV   AL,ES:[BX+2]	     ; GET COMMAND CODE BYTE
	 MOV   AH,0
	 SHL   AX,1
	 MOV   DI,AX
	 JMP   [DI+FUNTAB]

DONESTAT LABEL NEAR
	 LES   BX,DWORD PTR [RHOFF]
	 OR    WORD PTR ES:[BX+03],0100H   ; "DONE" STATUS

EXIT	 LABEL NEAR
	 CLC
	 POP   AX
	 POP   BX
	 POP   CX
	 POP   DX
	 POP   SI
	 POP   DI
	 POP   DS
	 POP   ES
	 POP   BP
FARRET2  PROC  FAR
	 RET
FARRET2  ENDP
	 PAGE
;--------------------------------------------------------------------;
;			 DEVICE FUNCTIONS			     ;
;--------------------------------------------------------------------;

INPUT	 LABEL NEAR
	 LES   BX,DWORD PTR ES:[BX+14] ; ADDRESS THE BUFFER
	 MOV   WORD PTR ES:[BX],OFFSET PARMS
	 MOV   ES:[BX+2],CS
	 LES   BX,DWORD PTR [RHOFF]
	 MOV   WORD PTR ES:[BX+18],4   ; 4 BYTES TRANSFERRED
	 JMP   DONESTAT

OUTPUT	 LABEL NEAR
OUTPUTV  LABEL NEAR
IOCTLIN  LABEL NEAR
IOCTLOUT LABEL NEAR
	 MOV   WORD PTR ES:[BX+18],0	 ; NO DATA TRANSFERRED
NDINPUT  LABEL NEAR
INSTATUS LABEL NEAR
INFLUSH  LABEL NEAR
OUSTATUS LABEL NEAR
OUFLUSH  LABEL NEAR
MEDIACHK LABEL NEAR
BUILDBPB LABEL NEAR
	 OR    WORD PTR ES:[BX+03],8102H ; INDICATE DEVICE NOT READY
	 JMP   DONESTAT

	org	0100h			; leave 7f:0-f clear

	 PAGE
;--------------------------------------------------------------------;
;			  REQUEST HANDLER			     ;
;--------------------------------------------------------------------;

RHENTRY  LABEL NEAR
	 PUSH  DS
	 PUSH  SI

	 MOV   SI,CS
	 MOV   DS,SI

	 MOV   AL,AH
	 CMP   AL,RHTABLEN/2		; INVALID FUNCTION CODES ARE IGNORED
	 JAE   RHEXIT
	 XOR   AH,AH
	 SHL   AX,1
	 MOV   SI,AX
	 CALL  [RHTABLE+SI]

RHEXIT	 LABEL NEAR
	 POP   SI
	 POP   DS
VMFARRET PROC  FAR
	 RET
VMFARRET ENDP

	 EVEN

RHTABLE  LABEL WORD
	 DW    VREBOOT
	 DW    VALLOC
	 DW    VRELEASE
	 DW    VREMAP
	 DW    VUNMAP
	 DW    VPHYMAP
RHTABLEN EQU   $-RHTABLE

	 PAGE
;--------------------------------------------------------------------;
;	       REQUEST HANDLER FUNCTION 00H (REBOOT)		     ;
;--------------------------------------------------------------------;
;   No parameters are required. 				     ;
;--------------------------------------------------------------------;

VREBOOT  LABEL NEAR
	 CLI

	db	0fh,01h,0eh		; SIDT instruction
	dw	offset idtr
	xor	ax,ax			; reset idt location to 0
	mov	[idtr+2],ax
	mov	byte ptr [idtr+4],al
	db	0fh,01h,1eh		; LIDT instruction
	dw	offset idtr

	 DB    0EAH		; DIRECT INTERSEGMENT JUMP
	 DW    0000H,0FFFFH	;   INTO BIOS RESET CODE

	 PAGE

valloc	 label near
vrelease label near
vremap   label near
vunmap   label near
vphymap  label near
	 mov   ax,-1
	 ret

;--------------------------------------------------------------------;
;             Interrupt Vector Table and related items               ;
;--------------------------------------------------------------------;

;	The IDT may be located anywhere in real or extended memory.

	org	($-mainseg+15)/16*16	; align for ease of debugging
ivtable	dw	256 dup(0,0)

idtr	dw	0,0,0			; used by SIDT and LIDT instructions

; 	Jump table entries are entered via the new IDT. CS will have a
;	value equal to the offset into the interrupt table divided by 16;
;	e.g., for interrupt 21h CS will be 0008 and entry will be to the
;	second jmp in the table (which goes to dword ptr cs:[4]). The     
;	reason, of course, for using different CS values is so that we
;	don't waste 1280 bytes just for a jump table. Note that the jump
;	table must reside within the first 64K of RAM.

jtable	label	word
	jmp	dword ptr cs:[00]
	jmp	dword ptr cs:[04]
	jmp	dword ptr cs:[08]
	jmp	dword ptr cs:[12]

	 PAGE
;--------------------------------------------------------------------;
;		    PARAMETERS AVAILABLE TO USER		     ;
;--------------------------------------------------------------------;

	 EVEN
PARMS	 LABEL WORD
PARMRHAD DW    2 DUP(0) 	; ADDRESS OF REQUEST HANDLER
PARMFEAT DW    0600H		; SPECIAL FEATURES:
				;   8000H = ALL MEMORY IS MANAGED
				;   4000H = I/O TRAPPING SUPPORTED
				;   2000H = WRITE PROTECTION SUPPORTED
				;   1000H = USE MEMORY MAPPING FOR CXT SWITCH
				;   0800H = "DECLARE" SUPPORTED ($286.SYS)
				;   0400H = IVTABLE support
				;   0200H = Upper 60k supported (FFF8:1080)

         DW    4096,0		; GRANULARITY IS 4K PER PAGE
         DW    0,0		; TOTAL EXTENDED MEMORY (PAGES)
         DW    0,0		; USED	EXTENDED MEMORY (PAGES)
         DW    0		; ERROR CODE FOR INT 6
         DW    0,0		; ADDRESS OR I/O INSTRUCTION FOR INT 6
PARMSCB  DW    01FCH,0		; SCB ADDRESS - FILLED IN BY MOS
	dw	0,0
parmaiv dw	offset ivtable
       	dw	0

;--------------------------- ASSORTED DATA --------------------------;

RHOFF	 DW    0		; REQUEST HEADER POINTER
RHSEG	 DW    0		; THIS MUST IMMEDIATELY FOLLOW RHOFF!

	 EVEN
PROGEND  LABEL BYTE		     ; END OF RETAINED CODE

	 PAGE
;--------------------------------------------------------------------;
;	      INITIALIZATION CODE - DISCARDED LATER		     ;
;--------------------------------------------------------------------;

INIT	 LABEL NEAR

;------------------------ INIT SOME POINTERS ------------------------;

	 MOV   [PARMRHAD+0],OFFSET RHENTRY
	 MOV   [PARMRHAD+2],CS

;------------------ SET END ADDRESS OF THIS DRIVER ------------------;

	 MOV   WORD PTR ES:[BX+14],offset progend
	 MOV   WORD PTR ES:[BX+16],CS

;---------------------- parse device command line -------------------;

	les   bx,dword ptr es:[bx+18] ; get parameter pointer
	dec   bx
ddsloop3:
	inc   bx
	mov   al,es:[bx]               ; scan for a slash
	cmp   al,0dh
	je    ddsdone                  ; c/r terminates the string
	cmp   al,'/'
	jne   ddsloop3
ddsslash:
	mov   al,es:[bx+1]
	and   al,0dfh                  ; upper-case conversion

	cmp   al,'I'                   ; /I for "simple" interrupt management
	jne   ddsendi
	and   byte ptr [parmfeat+1],not 04h
	jmp   short ddsnext
ddsendi:
	cmp   al,'C'			; /C for "conventional" memory
	jne   ddsendc
	and   byte ptr [parmfeat+1],not 02h
	jmp   short ddsnext
ddsendc:
ddsnext:
	jmp	ddsloop3
ddsdone:

;-------------------- Enable use of FFF8:80-FFFF --------------------;

	test	byte ptr [parmfeat+1],02h ; requires feature bit
	jz	u60end
	call	bit20on			; enable address line 20
	push	ds
	push	es
	xor	si,si			; move 4K from 0:0 to fff8:80
	mov	ds,si
	mov	ax,0fff8h
	mov	es,ax
	mov	di,80h
	mov	word ptr es:[di],0aaaah	; make sure we have extended memory
	mov	word ptr es:[di+2],5555h
	cmp	word ptr es:[di+1],55aah
	je	u60ok
	and	byte ptr [parmfeat+1],not 02h ; sorry, no extended memory
	jmp	short u60out
u60ok:
	mov	cx,2048
	cld
	rep	movsw
u60out:
	pop	es
	pop	ds
	sti
u60end:

;-------------- Replace Interrupt Vector Table if 80286 -------------;

	test	byte ptr [parmfeat+1],04h ; requires feature bit
	jz	bidend

	db	0fh,01h,0eh		; SIDT instruction
	dw	offset idtr

	mov	ax,cs			; compute new idtr contents
	mov	bl,ah
	shl	ax,4
	shr	bl,4
	add	ax,offset ivtable
	adc	bl,0
	mov	[idtr+2],ax
	mov	byte ptr [idtr+4],bl

	xor	si,si			; si indexes the idt
	mov	ax,cs			; get absolute address of jtable in ax
	shl	ax,4
	add	ax,offset jtable
	xor	dx,dx			; dx is code segment value
bidloop1:
	mov	cx,4			; cx is number of times
bidloop2:
	mov	[ivtable+si],ax		; plug offset into idt entry
	mov	[ivtable+2+si],dx	; segment portion
	add	ax,5
	add	si,4
	loop	bidloop2
	inc	dx
	sub	ax,5*4+10h
	cmp	si,256*4
	jb	bidloop1

	db	0fh,01h,1eh		; LIDT instruction
	dw	offset idtr
bidend:
	jmp	donestat

	 PAGE
;--------------------------------------------------------------------;
;		     TURN ON ADDRESS BIT 20 GATE		     ;
;--------------------------------------------------------------------;

BIT20ON  PROC  NEAR
	 PUSH  AX
	 CLI
	 CALL  CLR8042
	 MOV   AL,0D1H
	 OUT   64H,AL
	 CALL  CLR8042
	 MOV   AL,0DFH
	 OUT   60H,AL
	 CALL  CLR8042
SKIP8042:
	 POP   AX
	 RET
BIT20ON  ENDP

CLR8042  PROC  NEAR
	 push  cx
	 xor   cx,cx
CLR8042L:
	 IN    AL,064H		     ; READ STATUS PORT
	 AND   AL,02H		     ; LOOP UNTIL BUFFER EMPTY
	 loopnz CLR8042L
	 pop   cx
	 RET
CLR8042  ENDP

mainseg	ends
	end	begin
